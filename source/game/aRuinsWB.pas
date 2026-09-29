unit aRuinsWB;
// Unit bracket (inferred): CODE 0x0051F1AC..0x005207FF; inclusive evidence, not full bounds.
// Station service class; native parent TRuins, no added fields.
interface
uses aRuins, aShip, aGalaxy;
type
  TWB = class(TRuins) // @size $238
  public
    function GetName: WideString; override; // @addr $51F8B4
    function GetFullName(const Separator: WideString): WideString; override; // @addr $51F8C8
    function GetTypeNameKey: WideString; override; // @addr $51F958
    procedure NextDay; override; // @addr $51F870
    procedure Init(Star: TStar); override; // @addr $51F294 @slot $94
    procedure RefreshEquipmentShopInventory; // @addr $51FD80
    function CalculateEquipmentShopTargetCount: Integer; // @addr $520654
    procedure UpdateGoodsMarketState; // @addr $51F978
    function GetRepairCost(Ship: TShip): Integer; // @addr $5206B4
    procedure RepairShip(Ship: TShip); // @addr $520750
  end;
implementation

// @unit-initialization $5207F8
// @unit-finalization $5207C8

uses aItem, aConst, aMyFunction, aPlanet, aGalaxy, aPlayer, GlobalsV, Globals, Math, Classes, SysUtils, EC_Struct, SE_Space;

{ @routine $51F294 TWB_Init }
procedure TWB.Init(Star: TStar);
var Index, I, J, K, LastIndex, FirstIndex: Integer; Duplicate: Boolean;
  Planet: TPlanet; Ship: TShip; Polar: TPolarPoint; Weapon: TWeapon; Good: TGoodsIndex;
begin
  inherited Init(Star);
  StationFlags := [0..3];
  ShipType := t_MilitaryBase;
  if NextRandomUnitFloat(RandomState) < 0.5 then OwnerId := oiMaloc else OwnerId := oiPeleng;
  CurrentStar := Star;
  CurrentStar.Ships.Add(Self);
  HomePlanet := nil;
  CurrentPlanet := nil;
  repeat
    Planet := CurrentStar.Planets[SeededRandomIntRange(0, CurrentStar.Planets.Count - 2, RandomState)];
    Polar.Radius := Planet.Radius + Planet.Orbit.Radius + 100 + SeededRandomIntRange(0, 50, RandomState);
    Polar.AngleDegrees := NextRandomIntRange(0, 359, RandomState);
    Position := PolarToPoint(Polar);
  until DistanceToNearestShipByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) > 600;
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('RuinName').GetBlock('WB').GetParamCount - 1;
  Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
  for I := FirstIndex to LastIndex do
  begin
    Name := LanguageDataConfig.GetBlock('RuinName').GetBlock('WB').GetParamValue(Index);
    Duplicate := False;
    for J := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := Galaxy.Stars[J];
      for K := 0 to Star.Ships.Count - 1 do
      begin
        Ship := Star.Ships[K];
        if (Ship is TWB) and (Ship.Name = Name) and (Ship <> Self) then
        begin
          Duplicate := True;
          Break;
        end;
      end;
      if Duplicate then Break;
    end;
    if not Duplicate then Break;
    IncrementWrapped(Index, FirstIndex, LastIndex);
    if I = LastIndex then
    begin
      Name := Name + '-' + IntToStr(NextRandomIntRange(10, 99, RandomState));
      RaiseWideMessage('Даем имя военной базе');
    end;
  end;
  Graphic := CreateSpaceObjectByName('Ruins', 'Ruins.WB', Classes.Point(0, 0));
  Graphic.SetPosition(MakePointF(0, 0));
  CollisionRadius := 0;
  CreateAndEquipHull(True, NextRandomIntRange(1000, 1500, RandomState), NextRandomIntRange(1, 3, RandomState), OwnerId);
  CreateAndEquipFuelTanks(True, 1, 1, OwnerId);
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[3]), 3, OwnerId);
  CreateAndEquipDefGenerator(True, Round(40 * ItemSizeFactors[4]), NextRandomIntRange(1, 4, RandomState), OwnerId);
  CreateAndEquipRepairRobot(True, Round(40 * ItemSizeFactors[5]), NextRandomIntRange(1, 3, RandomState), OwnerId);
  Weapon := CreateAndEquipWeapon(t_ZipGun, True, Round(WeaponInfo[t_ZipGun].Weight * ItemSizeFactors[3]), 5, OwnerId);
  Weapon.Range := 600;
  Weapon.MinDamage := NextRandomIntRange(1, 5, RandomState);
  Weapon.MaxDamage := NextRandomIntRange(6, 20, RandomState);
  if GetCargoFreeSpace < 0 then Inc(Hull.Weight, Abs(GetCargoFreeSpace));
  RefreshDerivedStats;
  RefreshEquipmentShopInventory;
  for Good := t_Food to t_Narcotics do
  begin
    Goods[Good].Count := Round(MilitaryBaseGoodsFactors[Good].StockFactor * GoodsMarket[Good].BaseStock);
    Goods[Good].PriceState := GoodsMarket[Good].BasePrice;
    Goods[Good].PurchasePrice := Round(Goods[Good].PriceState);
    Goods[Good].BaseSalePrice := Round(0.98 * Goods[Good].PriceState - 1);
  end;
end;
{ @end $51F294 }

{ @routine $51F870 TWB_NextDay }
procedure TWB.NextDay;
begin
  inherited NextDay;
  if ScriptShip <> nil then
  begin
    ScriptNextDay;
    if ScriptShip <> nil then Exit;
  end;
  RefreshEquipmentShopInventory;
  UpdateGoodsMarketState;
  if (CurrentPlanet = nil) and InNormalSpace then Exit;
end;
{ @end $51F870 }

{ @routine $51F8B4 TWB_GetName }
function TWB.GetName: WideString;
begin
  Result := Name;
end;
{ @end $51F8B4 }

{ @routine $51F8C8 TWB_GetFullName }
function TWB.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.TypeName.WB') + Separator + Name;
end;
{ @end $51F8C8 }

{ @routine $51F958 TWB_GetTypeNameKey }
function TWB.GetTypeNameKey: WideString;
begin
  Result := 'WB';
end;
{ @end $51F958 }

{ @routine $51F978 TWB_UpdateGoodsMarketState }
procedure TWB.UpdateGoodsMarketState;
var Good: TGoodsIndex; TargetPrice, PriceStep: Single; TargetCount, CountStep: Integer;
begin
  for Good := t_Food to t_Narcotics do
  begin
    TargetCount := Round(GoodsMarket[Good].BaseStock * PlanetRaceMarket[OwnerToRace(OwnerId)].Goods[Good].StockFactor * MilitaryBaseGoodsFactors[Good].StockFactor);
    TargetPrice := GoodsMarket[Good].BasePrice * PlanetRaceMarket[OwnerToRace(OwnerId)].Goods[Good].PriceFactor * MilitaryBaseGoodsFactors[Good].PriceFactor /
      RemapClamped(Goods[Good].Count, TargetCount * 0.3, TargetCount * 2, 0.9, 1.1);
    if GoodsMarket[Good].MinPrice < TargetPrice then TargetPrice := Min(TargetPrice, GoodsMarket[Good].MaxPrice + 1)
    else TargetPrice := Max(TargetPrice, GoodsMarket[Good].MinPrice - 1);
    if Goods[Good].PriceState - TargetPrice >= 0 then PriceStep := TargetPrice * NextRandomFloatRange(0.0035, 0.006, RandomState)
    else PriceStep := -TargetPrice * NextRandomFloatRange(0.0035, 0.006, RandomState);
    case NextRandomIntRange(1, 100, RandomState) of
      1..70: Goods[Good].PriceState := Goods[Good].PriceState - PriceStep;
      71..90: ;
    else Goods[Good].PriceState := Goods[Good].PriceState + PriceStep;
    end;
    if GoodsMarket[Good].MinPrice div 2 > Goods[Good].PriceState then Goods[Good].PriceState := GoodsMarket[Good].MinPrice div 2
    else if GoodsMarket[Good].MaxPrice * 2 < Goods[Good].PriceState then Goods[Good].PriceState := GoodsMarket[Good].MaxPrice * 2;
    Goods[Good].PurchasePrice := Max(2, Round(Goods[Good].PriceState));
    Goods[Good].BaseSalePrice := Max(Goods[Good].PurchasePrice div 2 + 1,
      Round(Goods[Good].PriceState * RemapClampedAlternate(Goods[Good].Count, TargetCount, TargetCount * 2, 0.9, 0.7) - 1));
    if Goods[Good].Count - TargetCount >= 0 then
      CountStep := Round(TargetCount * NextRandomFloatRange(0.0025, 0.005, RandomState) + NextRandomUnitFloat(RandomState))
    else CountStep := Round(-TargetCount * NextRandomFloatRange(0.0025, 0.005, RandomState) - NextRandomUnitFloat(RandomState));
    case NextRandomIntRange(1, 100, RandomState) of
      1..20: Dec(Goods[Good].Count, CountStep);
      21..95: ;
    else Inc(Goods[Good].Count, CountStep);
    end;
    if Goods[Good].Count < 0 then Goods[Good].Count := 0;
  end;
end;
{ @end $51F978 }

{ @routine $51FD80 TWB_RefreshEquipmentShopInventory }
procedure TWB.RefreshEquipmentShopInventory;
var Index, Attempts, Generated, MinimumHull, MaximumHull, WeaponKind: Integer;
  Item: TEquipment; ItemType, WeaponType: TItemType; Planet: TPlanet;
begin
  if (Galaxy.CurrentTurn <= CreationTurn + 1) or ((Galaxy.CurrentTurn + Integer(Seed)) mod 7 = 0) then
  begin
    if (CalculateEquipmentShopTargetCount <= EquipmentShop.Count) and (SeededRandomUnitFloat(Galaxy.CurrentTurn) < 0.5) then
    begin
      Index := SeededRandomIntRange(0, EquipmentShop.Count - 1, Galaxy.CurrentTurn * Seed);
      Item := EquipmentShop[Index];
      if Item.ScriptItem = nil then
      begin
        EquipmentShop.Delete(Index);
        Item.Free;
      end;
    end;
    Generated := 0;
    Planet := FindCoalitionPlanetForStation;
    while (EquipmentShop.Count <= CalculateEquipmentShopTargetCount * 0.7) or
      ((CalculateEquipmentShopTargetCount >= EquipmentShop.Count) and (SeededRandomUnitFloat(Galaxy.CurrentTurn) < 0.5)) do
    begin
      Inc(Generated);
      if Generated > 10 then Break;
      Attempts := 0;
      repeat
        Inc(Attempts);
        ItemType := TItemType(SeededRandomIntRange(Ord(t_Hull), Ord(WeaponCategoryItemType), Galaxy.CurrentTurn * Seed * 175 + Attempts));
      until (Attempts > 20) or (CountEquipmentShopItems(ItemType) < MilitaryBaseEquipmentQuotas[ItemType]);
      case ItemType of
        t_Hull: begin
          if Player <> nil then begin
            MinimumHull := Player.Hull.Weight - 100;
            MaximumHull := Player.Hull.Weight + 100;
          end else begin
            MinimumHull := 250;
            MaximumHull := 300;
          end;
          Item := THull.Create;
          EquipmentShop.Add(Item);
          (Item as THull).Init(False,
            NextRandomIntRange(Max(MinimumHull, Round(500 * ItemSizeFactors[5])),
              Min(MaximumHull, Round(ItemSizeFactors[Galaxy.ScaleByTechLevel(4, 1)] * 500)), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invHull] div 2), Min(8, Planet.InventionLevels[invHull] + 1), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_FuelTanks: begin
          Item := TFuelTanks.Create;
          EquipmentShop.Add(Item);
          (Item as TFuelTanks).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invFuelTanks] div 2), Min(8, Planet.InventionLevels[invFuelTanks]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_Engine: begin
          Item := TEngine.Create;
          EquipmentShop.Add(Item);
          (Item as TEngine).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invEngineSpeed] div 2), Min(8, Planet.InventionLevels[invEngineSpeed]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_Radar: begin
          Item := TRadar.Create;
          EquipmentShop.Add(Item);
          (Item as TRadar).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invRadarRange] div 2), Min(8, Planet.InventionLevels[invRadarRange]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_Scaner: begin
          Item := TScaner.Create;
          EquipmentShop.Add(Item);
          (Item as TScaner).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invScanner] div 2), Min(8, Planet.InventionLevels[invScanner]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_RepairRobot: begin
          Item := TRepairRobot.Create;
          EquipmentShop.Add(Item);
          (Item as TRepairRobot).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invRepairRobot] div 2), Min(8, Planet.InventionLevels[invRepairRobot]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_CargoHook: begin
          Item := TCargoHook.Create;
          EquipmentShop.Add(Item);
          (Item as TCargoHook).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invCargoHook] div 2), Min(8, Planet.InventionLevels[invCargoHook]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        t_DefGenerator: begin
          Item := TDefGenerator.Create;
          EquipmentShop.Add(Item);
          (Item as TDefGenerator).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invTechLevel] div 2), Min(8, Planet.InventionLevels[invTechLevel]), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
        WeaponCategoryItemType: begin
          Item := TWeapon.Create;
          EquipmentShop.Add(Item);
          repeat
            WeaponKind := NextRandomIntRange(0, 14, RandomState) + Ord(t_PhotonGun);
            WriteByteValue(WeaponKind, WeaponType);
          until (WeaponInfo[WeaponType].RequiredTechLevel <= Planet.InventionLevels[invTechLevel]) and not (WeaponType in HeavyWeaponTypes);
          (Item as TWeapon).Init(WeaponType, False,
            NextRandomIntRange(Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[5]), Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, Planet.InventionLevels[invTechLevel] div 2), Min(8, Planet.InventionLevels[invTechLevel] + 2), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
      else Item := nil;
      end;
      if Item <> nil then
      begin
        Item.ConditionPercent := SeededRandomFloatRange(Item.Id, 60, 100);
        RemoveSimilarShopItem(Item);
        case NextRandomIntRange(0, 100, RandomState) of
          0..20: Item.Improve(ikMinor);
          21..30: Item.Improve(ikMedium);
          31..33: Item.Improve(ikMajor);
        end;
      end;
    end;
  end;
end;
{ @end $51FD80 }

{ @routine $520654 TWB_CalculateEquipmentShopTargetCount }
function TWB.CalculateEquipmentShopTargetCount: Integer;
var Count: Integer; Kind: TItemType;
begin
  Count := 0;
  for Kind := t_Hull to WeaponCategoryItemType do Inc(Count, MilitaryBaseEquipmentQuotas[Kind]);
  Result := Round(Count + NextRandomIntRange(-2, 2, RandomState));
  Result := Max(10, Min(Result, 20));
end;
{ @end $520654 }

{ @routine $5206B4 TWB_GetRepairCost }
function TWB.GetRepairCost(Ship: TShip): Integer;
var I: Integer; Item: TEquipment;
begin
  Result := 0;
  for I := 0 to Ship.Inventory.Count - 1 do
  begin
    Item := Ship.Inventory[I];
    if (Item.ItemType = t_Hull) or (Item.EquippedFlag and (Item.ConditionPercent < 90)) then
      Inc(Result, Round(Item.CalculateRepairCost * 0.9 * 0.7));
  end;
end;
{ @end $5206B4 }

{ @routine $520750 TWB_RepairShip }
procedure TWB.RepairShip(Ship: TShip);
var I: Integer; Item: TEquipment;
begin
  if GetRepairCost(Ship) <= Ship.Money then
  begin
    Ship.SetMoney(Ship.Money - GetRepairCost(Ship));
    for I := 0 to Ship.Inventory.Count - 1 do
    begin
      Item := Ship.Inventory[I];
      if (Item.ItemType = t_Hull) or (Item.EquippedFlag and (Item.ConditionPercent < 90)) then Item.Repair;
    end;
  end;
end;
{ @end $520750 }

end.

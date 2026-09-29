unit aRuinsSB;
// Unit bracket (inferred): CODE 0x00520800..0x00521EDF; inclusive evidence, not full bounds.
// Station service class; native parent TRuins, no added fields.
interface
uses aRuins, aShip, aGalaxy;
type
  TSB = class(TRuins) // @size $238
  public
    function GetName: WideString; override; // @addr $520F04
    function GetFullName(const Separator: WideString): WideString; override; // @addr $520F18
    function GetTypeNameKey: WideString; override; // @addr $520FA8
    procedure NextDay; override; // @addr $520EC0
    procedure Init(Star: TStar); override; // @addr $5208E8 @slot $94
    procedure RefreshEquipmentShopInventory; // @addr $5213D0
    function CalculateEquipmentShopTargetCount: Integer; // @addr $521C88
    procedure UpdateGoodsMarketState; // @addr $520FC8
    function GetRepairCost(Ship: TShip): Integer; // @addr $521CE8
    procedure RepairShip(Ship: TShip); // @addr $521DEC
  end;
implementation

// @unit-initialization $521ED8
// @unit-finalization $521EA8

uses aItem, aConst, aMyFunction, aPlanet, aGalaxy, aPlayer, GlobalsV, Globals, Math, Classes, SysUtils, EC_Struct, SE_Space;

{ @routine $5208E8 TSB_Init }
procedure TSB.Init(Star: TStar);
var Index, I, J, K, LastIndex, FirstIndex: Integer; Duplicate: Boolean;
  Planet: TPlanet; Ship: TShip; Polar: TPolarPoint; Weapon: TWeapon; Good: TGoodsIndex;
begin
  inherited Init(Star);
  StationFlags := [0..3];
  ShipType := t_ScientificBase;
  if NextRandomUnitFloat(RandomState) < 0.5 then OwnerId := oiFei else OwnerId := oiGaal;
  CurrentStar := Star;
  CurrentStar.Ships.Add(Self);
  HomePlanet := nil;
  CurrentPlanet := nil;
  repeat
    Planet := CurrentStar.Planets[NextRandomIntRange(0, CurrentStar.Planets.Count - 1, RandomState)];
    Polar.Radius := Planet.Radius + Planet.Orbit.Radius + 100 + NextRandomIntRange(0, 50, RandomState);
    Polar.AngleDegrees := NextRandomIntRange(0, 359, RandomState);
    Position := PolarToPoint(Polar);
  until DistanceToNearestShipByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) > 700;
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('RuinName').GetBlock('SB').GetParamCount - 1;
  Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
  for I := FirstIndex to LastIndex do
  begin
    Name := LanguageDataConfig.GetBlock('RuinName').GetBlock('SB').GetParamValue(Index);
    Duplicate := False;
    for J := 0 to Galaxy.Stars.Count - 1 do
    begin
      Star := Galaxy.Stars[J];
      for K := 0 to Star.Ships.Count - 1 do
      begin
        Ship := Star.Ships[K];
        if (Ship is TSB) and (Ship.Name = Name) and (Ship <> Self) then
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
      RaiseWideMessage('Даем имя научной базе');
    end;
  end;
  Graphic := CreateSpaceObjectByName('Ruins', 'Ruins.SB', Classes.Point(0, 0));
  Graphic.SetPosition(MakePointF(0, 0));
  CollisionRadius := 0;
  CreateAndEquipHull(True, NextRandomIntRange(800, 1200, RandomState), NextRandomIntRange(2, 3, RandomState), OwnerId);
  CreateAndEquipFuelTanks(True, 1, 1, OwnerId);
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[3]), 3, OwnerId);
  CreateAndEquipDefGenerator(True, Round(40 * ItemSizeFactors[4]), NextRandomIntRange(1, 2, RandomState), OwnerId);
  CreateAndEquipRepairRobot(True, Round(40 * ItemSizeFactors[5]), NextRandomIntRange(1, 3, RandomState), OwnerId);
  Weapon := CreateAndEquipWeapon(t_GravitonBeamer, True, Round(WeaponInfo[t_GravitonBeamer].Weight * ItemSizeFactors[3]), 5, OwnerId);
  Weapon.Range := 400;
  Weapon.MinDamage := NextRandomIntRange(1, 5, RandomState);
  Weapon.MaxDamage := NextRandomIntRange(6, 20, RandomState);
  if GetCargoFreeSpace < 0 then Inc(Hull.Weight, Abs(GetCargoFreeSpace));
  RefreshDerivedStats;
  RefreshEquipmentShopInventory;
  for Good := t_Food to t_Narcotics do
  begin
    Goods[Good].Count := Round(ScienceBaseGoodsFactors[Good].StockFactor * GoodsMarket[Good].BaseStock);
    Goods[Good].PriceState := GoodsMarket[Good].BasePrice;
    Goods[Good].PurchasePrice := Round(Goods[Good].PriceState);
    Goods[Good].BaseSalePrice := Round(0.98 * Goods[Good].PriceState - 1);
  end;
end;
{ @end $5208E8 }

{ @routine $520EC0 TSB_NextDay }
procedure TSB.NextDay;
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
{ @end $520EC0 }

{ @routine $520F04 TSB_GetName }
function TSB.GetName: WideString;
begin
  Result := Name;
end;
{ @end $520F04 }

{ @routine $520F18 TSB_GetFullName }
function TSB.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.TypeName.SB') + Separator + Name;
end;
{ @end $520F18 }

{ @routine $520FA8 TSB_GetTypeNameKey }
function TSB.GetTypeNameKey: WideString;
begin
  Result := 'SB';
end;
{ @end $520FA8 }

{ @routine $520FC8 TSB_UpdateGoodsMarketState }
procedure TSB.UpdateGoodsMarketState;
var Good: TGoodsIndex; TargetPrice, PriceStep: Single; TargetCount, CountStep: Integer;
begin
  for Good := t_Food to t_Narcotics do
  begin
    TargetCount := Round(GoodsMarket[Good].BaseStock * PlanetRaceMarket[OwnerToRace(OwnerId)].Goods[Good].StockFactor * ScienceBaseGoodsFactors[Good].StockFactor);
    TargetPrice := GoodsMarket[Good].BasePrice * PlanetRaceMarket[OwnerToRace(OwnerId)].Goods[Good].PriceFactor * ScienceBaseGoodsFactors[Good].PriceFactor /
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
{ @end $520FC8 }

{ @routine $5213D0 TSB_RefreshEquipmentShopInventory }
procedure TSB.RefreshEquipmentShopInventory;
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
      until (Attempts > 20) or (CountEquipmentShopItems(ItemType) < ScienceBaseEquipmentQuotas[ItemType]);
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
            NextRandomIntRange(Max(1, Planet.InventionLevels[invHull] div 2), Min(8, Planet.InventionLevels[invHull]), RandomState), PickRandomEquipmentOwner(RandomState));
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
            NextRandomIntRange(Max(1, Planet.InventionLevels[invScanner] div 2), Min(8, Planet.InventionLevels[invScanner] + 1), RandomState), PickRandomEquipmentOwner(RandomState));
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
            NextRandomIntRange(Max(1, Planet.InventionLevels[invCargoHook] div 2), Min(8, Planet.InventionLevels[invCargoHook] + 1), RandomState), PickRandomEquipmentOwner(RandomState));
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
            NextRandomIntRange(Max(1, Planet.InventionLevels[invTechLevel] div 2), Min(8, Planet.InventionLevels[invTechLevel] + 1), RandomState), PickRandomEquipmentOwner(RandomState));
        end;
      else Item := nil;
      end;
      if Item <> nil then
      begin
        RemoveSimilarShopItem(Item);
        case NextRandomIntRange(0, 100, RandomState) of
          0..70: Item.Improve(ikMinor);
          71..90: Item.Improve(ikMedium);
          91..100: Item.Improve(ikMajor);
        end;
      end;
    end;
  end;
end;
{ @end $5213D0 }

{ @routine $521C88 TSB_CalculateEquipmentShopTargetCount }
function TSB.CalculateEquipmentShopTargetCount: Integer;
var Count: Integer; Kind: TItemType;
begin
  Count := 0;
  for Kind := t_Hull to WeaponCategoryItemType do Inc(Count, ScienceBaseEquipmentQuotas[Kind]);
  Result := Round(Count + NextRandomIntRange(-2, 2, RandomState));
  Result := Max(10, Min(Result, 20));
end;
{ @end $521C88 }

{ @routine $521CE8 TSB_GetRepairCost }
function TSB.GetRepairCost(Ship: TShip): Integer;
var I: Integer; Item: TEquipment;
begin
  Result := 0;
  for I := 0 to Ship.Inventory.Count - 1 do
  begin
    Item := Ship.Inventory[I];
    if (Item.ItemType = t_Hull) or (Item.EquippedFlag and (Item.ConditionPercent < 90)) then
      Inc(Result, Round(Item.CalculateRepairCost * 1.4 * 0.7));
  end;
  for I := 0 to Ship.Artefacts.Count - 1 do
  begin
    Item := Ship.Artefacts[I];
    if Item.EquippedFlag and (Item.ConditionPercent < 90) then
      Inc(Result, Round(Item.CalculateRepairCost * 1.2 * 0.7));
  end;
end;
{ @end $521CE8 }

{ @routine $521DEC TSB_RepairShip }
procedure TSB.RepairShip(Ship: TShip);
var
  I: Integer;
  Item: TEquipment;
begin
  if GetRepairCost(Ship) > Ship.Money then Exit;
  begin
    Ship.SetMoney(Ship.Money - GetRepairCost(Ship));
    for I := 0 to Ship.Inventory.Count - 1 do
    begin
      Item := Ship.Inventory[I];
      if (Item.ItemType = t_Hull) or (Item.EquippedFlag and (Item.ConditionPercent < 90)) then
      begin
        Item.Repair;
      end;
    end;
    for I := 0 to Ship.Artefacts.Count - 1 do
    begin
      Item := Ship.Artefacts[I];
      if Item.EquippedFlag and (Item.ConditionPercent < 90) then Item.Repair;
    end;
  end;
end;
{ @end $521DEC }

end.

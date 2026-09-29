unit aRuins;
// Unit bracket (inferred): CODE 0x00592DA8..0x00593BBF; inclusive evidence, not full bounds.
// Base for ranger centers and military, science and pirate stations.
interface
uses aShip, aPlanet, aGalaxy, aItem, aMyFunction, EC_Buf;
type
  TStationServiceFlags = set of 0..7; // @size $01
  TRuins = class(TShip) // @size $238 @methodorder source
  public
    StationFlags: TStationServiceFlags; // @offset $1B0 Bits 1/2/3 enable equipment/goods/info controls; bit 0 remains unresolved. Serialized as one byte.
    EquipmentShop: TObjectList; // @offset $1B4 Owned shop items, distinct from installed inventory.
    Goods: array[TGoodsIndex] of TPlanetGoodsEntry; // @offset $1B8

    constructor Create; // @addr $592E94
    destructor Destroy; override; // @addr $592EEC
    procedure Init(Star: TStar); virtual; // @addr $592F64 @slot $94 Initializes ranger relations; base body does not use Star.
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $592FC0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $59307C
    procedure ResolveLoadedReferences; override; // @addr $593178
    procedure NextDay; override; // @addr $5931B4
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $593200
    function GetDominantCareer: TRangerCareer; override; // @addr $593204
    function GetHomeStar: TStar; override; // @addr $593208
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $59320C
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $593210
    procedure RefuelAtLocation; override; // @addr $593214
    procedure BuyInitialEquipment; override; // @addr $593224
    procedure UpgradeEquipmentAtLocation; override; // @addr $593228
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $59322C
    function CountEquipmentShopItems(ItemType: TItemType): Integer; // @addr $59327C
    function RemoveSimilarShopItem(Item: TEquipment): Boolean; // @addr $5932D8
    procedure BuildReachablePlanetQueue; override; // @addr $593568
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $59356C
    procedure SelectEnemyShipInStar; override; // @addr $593570
    procedure EngageEnemyShip; override; // @addr $59357C
    procedure AssignWeaponTargetsInStar; // @addr $593580
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $5937D0
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $593884
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $5938C8
    procedure ReactToAttack(Attacker: TShip); override; // @addr $5939A0
    function RecomputeFearState: Boolean; override; // @addr $5939C0
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $5939C4
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $5939C8
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $5939CC
    procedure ProcessCombatDialogue; override; // @addr $5939D0
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $5939D4
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $5939D8
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $593A24
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $593A68
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $593AB4
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $593B00
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $593B44
  end;
implementation

// @unit-initialization $593BB8
// @unit-finalization $593B88

uses aConst, aRanger, aTranclucator, aAsteroid, GlobalsV, SysUtils, Math;

{ @routine $592E94 TRuins_Create }
constructor TRuins.Create;
begin
  inherited Create;
  EquipmentShop := TObjectList.Create;
  StationFlags := [];
end;
{ @end $592E94 }

{ @routine $592EEC TRuins_Destroy }
destructor TRuins.Destroy;
var I: Integer; Ranger: TRanger;
begin
  for I := 0 to Galaxy.Rangers.Count - 1 do
  begin
    Ranger := Galaxy.Rangers[I];
    if Ranger.LastDockedNonPlanetLocation = Self then Ranger.LastDockedNonPlanetLocation := nil;
  end;
  EquipmentShop.Free;
  EquipmentShop := nil;
  inherited Destroy;
end;
{ @end $592EEC }

{ @routine $592F64 TRuins_Init }
procedure TRuins.Init(Star: TStar);
var I: Integer; Ranger: TRanger;
begin
  for I := 0 to Galaxy.Rangers.Count - 1 do
  begin
    Ranger := Galaxy.Rangers[I];
    RangerRelations.Add(Pointer(OwnerRelations[OwnerId, Ranger.OwnerId]));
  end;
end;
{ @end $592F64 }

{ @routine $592FC0 TRuins_SaveToBuffer }
procedure TRuins.SaveToBuffer(Buffer: TBufEC);
var I, Count: Integer; Kind: TGoodsIndex; Item: TItem;
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddByte(Byte(StationFlags));
  Count := EquipmentShop.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Item := EquipmentShop[I];
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  for Kind := t_Food to t_Narcotics do
  begin
    Buffer.AddIntegerValue(Goods[Kind].Count);
    Buffer.AddSingle(Goods[Kind].PriceState);
    Buffer.AddIntegerValue(Goods[Kind].PurchasePrice);
    Buffer.AddIntegerValue(Goods[Kind].BaseSalePrice);
  end;
end;
{ @end $592FC0 }

{ @routine $59307C TRuins_LoadFromBuffer }
procedure TRuins.LoadFromBuffer(Buffer: TBufEC);
var I, Count: Integer; Kind: TItemType; Item: TItem;
begin
  inherited LoadFromBuffer(Buffer);
  WriteByteValue(Buffer.GetByte, StationFlags);
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do
  begin
    WriteByteValue(Buffer.GetByte, Kind);
    Item := CreateItemByType(Kind);
    EquipmentShop.Add(Item);
    Item.LoadFromBuffer(Buffer);
  end;
  for Kind := t_Food to t_Narcotics do
  begin
    Goods[Kind].Count := Buffer.GetInt32;
    Goods[Kind].PriceState := Buffer.GetSingle;
    Goods[Kind].PurchasePrice := Buffer.GetInt32;
    Goods[Kind].BaseSalePrice := Buffer.GetInt32;
  end;
end;
{ @end $59307C }

{ @routine $593178 TRuins_ResolveLoadedReferences }
procedure TRuins.ResolveLoadedReferences;
var I, Count: Integer; Item: TItem;
begin
  inherited ResolveLoadedReferences;
  Count := EquipmentShop.Count;
  for I := 0 to Count - 1 do
  begin
    Item := EquipmentShop[I];
    Item.ClearReferences;
  end;
end;
{ @end $593178 }

{ @routine $5931B4 TRuins_NextDay }
procedure TRuins.NextDay;
begin
  inherited NextDay;
  if NextRandomIntRange(1, 60, RandomState) = 1 then RepairBrokenEquipmentAtLocation;
  AssignWeaponTargetsInStar;
  if ScriptShip <> nil then
  begin
    ScriptNextDay;
    if ScriptShip <> nil then Exit;
  end;
end;
{ @end $5931B4 }

{ @routine $593200 TRuins_GetGreetingShipCategory }
function TRuins.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscTransport;
end;
{ @end $593200 }

{ @routine $593204 TRuins_GetDominantCareer }
function TRuins.GetDominantCareer: TRangerCareer;
begin
  Result := rcTrader;
end;
{ @end $593204 }

{ @routine $593208 TRuins_GetHomeStar }
function TRuins.GetHomeStar: TStar;
begin
  Result := nil;
end;
{ @end $593208 }

{ @routine $59320C TRuins_GetStrengthScaledPirateStatus }
function TRuins.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 0;
end;
{ @end $59320C }

{ @routine $593210 TRuins_GetDesiredCargoFreeSpace }
function TRuins.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
end;
{ @end $593210 }

{ @routine $593214 TRuins_RefuelAtLocation }
procedure TRuins.RefuelAtLocation;
begin
  FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $593214 }

{ @routine $593224 TRuins_BuyInitialEquipment }
procedure TRuins.BuyInitialEquipment;
begin
end;
{ @end $593224 }

{ @routine $593228 TRuins_UpgradeEquipmentAtLocation }
procedure TRuins.UpgradeEquipmentAtLocation;
begin
end;
{ @end $593228 }

{ @routine $59322C TRuins_RepairBrokenEquipmentAtLocation }
procedure TRuins.RepairBrokenEquipmentAtLocation;
var I: Integer; Item: TEquipment;
begin
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := Inventory[I];
    if Item.BrokenFlag or (Item.ConditionPercent < 1) then Item.Repair;
  end;
end;
{ @end $59322C }

{ @routine $59327C TRuins_CountEquipmentShopItems }
function TRuins.CountEquipmentShopItems(ItemType: TItemType): Integer;
var I: Integer; Item: TItem;
begin
  Result := 0;
  for I := 0 to EquipmentShop.Count - 1 do
  begin
    Item := EquipmentShop[I];
    if (ItemType = Item.ItemType) or ((Item.ItemType in WeaponItemTypes) and (ItemType = WeaponCategoryItemType)) then Inc(Result);
  end;
end;
{ @end $59327C }

{ @routine $5932D8 TRuins_RemoveSimilarShopItem }
function TRuins.RemoveSimilarShopItem(Item: TEquipment): Boolean;
var
  I: Integer;
  Existing: TEquipment;
begin
  Result := False;
  for I := 0 to EquipmentShop.Count - 1 do
  begin
    Existing := EquipmentShop[I];

    if (Existing.ItemType <> Item.ItemType) or (Existing = Item) or (Existing.ScriptItem <> nil) then Continue;
    case Existing.ItemType of
      t_Hull: if (Existing as THull).TechLevel = (Item as THull).TechLevel then Result := True;
      t_FuelTanks: if (Existing as TFuelTanks).TechLevel = (Item as TFuelTanks).TechLevel then Result := True;
      t_Engine: if (Existing as TEngine).TechLevel = (Item as TEngine).TechLevel then Result := True;
      t_Radar: if (Existing as TRadar).TechLevel = (Item as TRadar).TechLevel then Result := True;
      t_Scaner: if (Existing as TScaner).TechLevel = (Item as TScaner).TechLevel then Result := True;
      t_RepairRobot: if (Existing as TRepairRobot).TechLevel = (Item as TRepairRobot).TechLevel then Result := True;
      t_CargoHook: if (Existing as TCargoHook).TechLevel = (Item as TCargoHook).TechLevel then Result := True;
      t_DefGenerator: if (Existing as TDefGenerator).TechLevel = (Item as TDefGenerator).TechLevel then Result := True;
      t_PhotonGun..t_EyesOfMachpella: if (Existing as TWeapon).TechLevel = (Item as TWeapon).TechLevel then Result := True;
    end;
    if Result then
    begin
      EquipmentShop.Delete(I);
      Existing.Free;
      Break;
    end;
  end;
end;
{ @end $5932D8 }

{ @routine $593568 TRuins_BuildReachablePlanetQueue }
procedure TRuins.BuildReachablePlanetQueue;
begin
end;
{ @end $593568 }

{ @routine $59356C TRuins_CanQueueReachablePlanet }
function TRuins.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := False;
end;
{ @end $59356C }

{ @routine $593570 TRuins_SelectEnemyShipInStar }
procedure TRuins.SelectEnemyShipInStar;
begin
  EnemyShip := nil;
end;
{ @end $593570 }

{ @routine $59357C TRuins_EngageEnemyShip }
procedure TRuins.EngageEnemyShip;
begin
end;
{ @end $59357C }

{ @routine $593580 TRuins_AssignWeaponTargetsInStar }
procedure TRuins.AssignWeaponTargetsInStar;
var I, J, Assigned: Integer; Ship: TShip; Weapon: TWeapon;
  Asteroid: TAsteroid; Distance: Single;
begin
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  Assigned := 0;
  if (Player.CurrentStar = CurrentStar) and (NextRandomUnitFloat(RandomState) > 0.8) then
    if CurrentStar.Battle then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := CurrentStar.Ships[I];
      if not ((Ship.OwnerId = oiKling) and Ship.InNormalSpace) then Continue;
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        if (Weapon.Target = nil) and not Weapon.BrokenFlag and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position)) then
        begin
          Weapon.Target := Ship;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
        end;
      end;
    end;
  if (CurrentStar.Items.Count < 6) and (CurrentStar = Player.CurrentStar) then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do
    begin
      Asteroid := CurrentStar.Asteroids[I];
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance <= AsteroidTargetRangeSquared then
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J - 1];
          // Native asteroid fire can replace an existing target.
          if (NextRandomUnitFloat(RandomState) <= 0.4) and not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag and
            (Weapon.Range * Weapon.Range >= Distance) then
          begin
            Weapon.Target := Asteroid;
            Inc(Assigned);
            if Assigned = WeaponCount then Exit;
            Break;
          end;
        end;
    end;
end;
{ @end $593580 }

{ @routine $5937D0 TRuins_RelationToNonRanger }
function TRuins.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if (EnemyShip = Ship) or (Ship.EnemyShip = Self) then
    Result := 0
  else
    case Ship.ShipType of
      t_Ranger: Result := RelationToRanger(Ship);
      t_Transport: Result := 100;
      t_Pirate: Result := 100;
      t_Warrior: Result := 100;
      t_Kling: Result := 0;
      t_Tranclucator:
        if (Ship as TTranclucator).OwnerShip <> nil then
          Result := RelationToNonRanger((Ship as TTranclucator).OwnerShip)
        else Result := 100;
      t_RangerCenter..t_ScientificBase: Result := 100;
    else Result := 50;
    end;
end;
{ @end $5937D0 }

{ @routine $593884 TRuins_RelationToRanger }
function TRuins.RelationToRanger(Ranger: TObject): Byte;
begin
  Result := Max(50, TPercent(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]));
end;
{ @end $593884 }

{ @routine $5938C8 TRuins_ChangeRelationToRanger }
procedure TRuins.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
var Relation: Byte; NewRelation: Integer;
begin
  Relation := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  if TShip(Ranger).BaseSkills[skCharm] > 0 then Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.2));
  NewRelation := Relation + Amount;
  if NewRelation < 0 then Relation := 0
  else if NewRelation > 100 then Relation := 100
  else Relation := NewRelation;
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then EnemyShip := TShip(Ranger);
  RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $5938C8 }

{ @routine $5939A0 TRuins_ReactToAttack }
procedure TRuins.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.ShipType = t_Ranger then ChangeRelationToRanger(Attacker, -10);
end;
{ @end $5939A0 }

{ @routine $5939C0 TRuins_RecomputeFearState }
function TRuins.RecomputeFearState: Boolean;
begin
  Result := False;
end;
{ @end $5939C0 }

{ @routine $5939C4 TRuins_AcceptsRansomDemandFrom }
function TRuins.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := False;
end;
{ @end $5939C4 }

{ @routine $5939C8 TRuins_TrustsAttackRequester }
function TRuins.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := True;
end;
{ @end $5939C8 }

{ @routine $5939CC TRuins_EvaluateAllyRelationAndStrength }
function TRuins.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := False;
end;
{ @end $5939CC }

{ @routine $5939D0 TRuins_ProcessCombatDialogue }
procedure TRuins.ProcessCombatDialogue;
begin
end;
{ @end $5939D0 }

{ @routine $5939D4 TRuins_ReactToExtortionDemand }
procedure TRuins.ReactToExtortionDemand(Ranger: TObject);
begin
end;
{ @end $5939D4 }

{ @routine $5939D8 TRuins_BuildMoneyExtortionResponse }
function TRuins.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $5939D8 }

{ @routine $593A24 TRuins_BuildCargoExtortionResponse }
function TRuins.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $593A24 }

{ @routine $593A68 TRuins_BuildTrucePaymentResponse }
function TRuins.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $593A68 }

{ @routine $593AB4 TRuins_BuildAttackRequestResponse }
function TRuins.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $593AB4 }

{ @routine $593B00 TRuins_AcceptPartnershipOffer }
function TRuins.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $593B00 }

{ @routine $593B44 TRuins_BuildPartnershipOfferResponse }
function TRuins.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $593B44 }

end.

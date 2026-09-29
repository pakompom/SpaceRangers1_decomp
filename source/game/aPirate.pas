unit aPirate;
// Unit bracket (inferred): CODE 0x0058F2E4..0x00592DA7; inclusive evidence, not full bounds.
// Pirate ship; native VMT $58F330.
interface
uses aNormalShip, aShip, aPlanet, aGalaxy, EC_Buf;
type
  TPirate = class(TNormalShip) // @size $1D4 @methodorder source
  public
    PrisonTermRemaining: Byte; // @offset $1D0 Days, saved as one byte; ProcessImprisonment $59101C.

    destructor Destroy; override; // @addr $58F3D0
    procedure InitGenerated(Planet: TPlanet; InitialMoney: Integer); // @addr $58F408
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $58F910
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $58F930
    procedure NextDay; override; // @addr $58F950
    function NavigateToServicePlanet(Absolute: Boolean): Boolean; // @addr $58FC0C
    function SelectServicePlanet: TPlanet; // @addr $58FC4C
    procedure BuildReachablePlanetQueue; override; // @addr $58FCEC
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $58FDD8
    procedure TryJumpToNearbyBattle(UnusedMode: Byte); // @addr $58FDE4
    procedure SellAllCargoGoods; // @addr $58FE9C
    procedure BuyInitialEquipment; override; // @addr $58FEC4
    procedure UpgradeEquipmentAtLocation; override; // @addr $58FF64
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $5900A4
    function GetHomeStar: TStar; override; // @addr $590110
    function GetName: WideString; override; // @addr $590118
    function GetFullName(const Separator: WideString): WideString; override; // @addr $59012C
    function GetTypeNameKey: WideString; override; // @addr $5901E8
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $590210
    function GetDominantCareer: TRangerCareer; override; // @addr $590214
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $590218
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $59021C
    function GetEquipmentMoneyReserve: Integer; // @addr $590278
    procedure RefuelAtLocation; override; // @addr $590288
    procedure ProcessUnseenProgression; // @addr $59029C
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $5904C8
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $590608
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $59063C
    procedure ReactToAttack(Attacker: TShip); override; // @addr $590744
    function RecomputeFearState: Boolean; override; // @addr $590764
    procedure TryOfferRansomToPursuer; // @addr $590998
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $590BFC
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $590C7C
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $590C94
    function ProcessImprisonment: Boolean; // @addr $59101C
    procedure AssignWeaponTargetsInStar; // @addr $5910F4
    procedure SelectEnemyShipInStar; override; // @addr $59161C
    procedure EngageEnemyShip; override; // @addr $5919DC
    procedure ProcessCombatDialogue; override; // @addr $591AD0
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $591B8C
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $591C64
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $592158
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $5924A0
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $5927B8
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $592B20
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $592B64
    procedure TrainSkillsAutomatically; override; // @addr $592BA8
  end;
implementation

// @unit-initialization $592DA0
// @unit-finalization $592D70

uses Classes, SysUtils, Math, aConst, aMyFunction, aItem, aRanger, Globals, GR_Main, SE_Ship2, aTranclucator, aGroup, aAsteroid, aPlayer;

{ @routine $58F3D0 TPirate_Destroy }
destructor TPirate.Destroy;
begin
  Dec(HomePlanet.HomePirateCount);
  Dec(Galaxy.PirateCount);
  inherited Destroy;
end;
{ @end $58F3D0 }

{ @routine $58F408 TPirate_InitGenerated }
procedure TPirate.InitGenerated(Planet: TPlanet; InitialMoney: Integer);
var Star: TStar; Ship: TShip; Ranger: TRanger; OwnerName: WideString;
  Duplicate: Boolean; Index, Attempt, I, J, LastIndex, FirstIndex: Integer;
begin
  if (PlayerHomeRanger = nil) and False then PlayerHomeRanger := Self;
  Inc(Galaxy.PirateCount);
  HomePlanet := Planet;
  CurrentPlanet := HomePlanet;
  CurrentStar := CurrentPlanet.CurrentStar;
  CurrentStar.Ships.Add(Self);
  OwnerId := HomePlanet.OwnerId;
  SetMoney(InitialMoney);
  ShipType := t_Pirate;
  OwnerName := OwnerToSys(OwnerId);
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('ShipName').GetBlock('Pirate').GetBlock(OwnerName).GetParamCount - 1;
  Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
  for Attempt := FirstIndex to LastIndex do begin
    Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Pirate').GetBlock(OwnerName).GetParamValue(Index);
    Duplicate := False;
    for I := 0 to Galaxy.Stars.Count - 1 do begin
      Star := Galaxy.Stars[I];
      for J := 0 to Star.Ships.Count - 1 do begin
        Ship := Star.Ships[J];
        if (Ship <> Self) and (Ship.ShipType = t_Pirate) and ((Ship as TPirate).Name = Name) then begin
          Duplicate := True;
          Break;
        end;
      end;
    end;
    if not Duplicate then Break;
    IncrementWrapped(Index, FirstIndex, LastIndex);
    if Attempt = LastIndex then Name := Name + ' 2';
  end;
  if Player <> nil then begin
    Rank := TCoalitionRank(NextRandomIntRange(0, Ord(Player.Rank), RandomState));
    if Rank > crWingman then Rank := crWingman;
    AddRankPoints(NextRandomIntRange(0, CoalitionRankPointThresholds[Rank] div 2, RandomState));
    GainExperience(Round(RemapClamped(Ord(Rank), 0, 3, 1575, 6300)));
  end;
  Graphic := TShip2SE.CreateEmpty;
  ShipRenderTemplates[Planet.OwnerId, 2].SpaceObject.CopyTo(Graphic);
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(0);
  CollisionRadius := 32;
  CreateAndEquipHull(True, Round(500 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipEngine(True, Round(ItemSizeFactors[NextRandomIntRange(1, 2, RandomState)] * 40), NextRandomIntRange(1, 2, RandomState), OwnerId);
  CreateAndEquipCargoHook(True, 40, NextRandomIntRange(1, 2, RandomState), OwnerId);
  CreateAndEquipWeapon(t_PhotonGun, True, WeaponInfo[t_PhotonGun].Weight, 1, OwnerId);
  CreateAndEquipRadar(True, Round(ItemSizeFactors[NextRandomIntRange(2, 4, RandomState)] * 30), 1, OwnerId);
  RefreshDerivedStats;
  BuyInitialEquipment;
  for Index := 0 to Galaxy.Rangers.Count - 1 do begin
    Ranger := Galaxy.Rangers[Index];
    RangerRelations.Add(Pointer(Min(50, OwnerRelations[OwnerId, Ranger.OwnerId] - 20)));
  end;
  PrisonTermRemaining := 0;
end;
{ @end $58F408 }

{ @routine $58F910 TPirate_SaveToBuffer }
procedure TPirate.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(PrisonTermRemaining));
end;
{ @end $58F910 }

{ @routine $58F930 TPirate_LoadFromBuffer }
procedure TPirate.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  PrisonTermRemaining := Buffer.GetByte;
end;
{ @end $58F930 }

{ @routine $58F950 TPirate_NextDay }
procedure TPirate.NextDay;
begin
  inherited NextDay;
  if ScriptShip <> nil then begin ScriptNextDay; if ScriptShip <> nil then Exit; end;
  if CurrentPlanet <> nil then begin
    if not ProcessImprisonment then begin
      LastDockedPlanet := CurrentPlanet;
      RepairBrokenEquipmentAtLocation;
      OptimizeInventory;
      SellAllCargoGoods;
      RefuelAtLocation;
      if not RepairHullAtLocation then begin
        UpgradeEquipmentAtLocation;
        ProcessUnseenProgression;
        TrainSkillsAutomatically;
        OrderTakeoff;
      end;
    end;
  end else if InNormalSpace then begin
    BuildReachablePlanetQueue;
    if RecomputeFearState then TryOfferRansomToPursuer;
    ProcessCombatDialogue;
    AssignWeaponTargetsInStar;
    if InFear then begin
      if (Order <> soLanding) and (Order <> soJump) then begin
        if NextRandomUnitFloat(RandomState) > 0.5 then NavigateToEscapePlanet(True)
        else NavigateToQueuedPlanet(True);
      end;
      if (Order in [soLanding,soJump]) and (EstimateOrderTravelTurns > 4) and (EnemyShip <> nil) and
        (EnemyShip.OrderTarget = Self) and (EnemyShip.ShipType in [t_Ranger,t_Pirate]) and
        (EnemyShip.EstimateOrderTravelTurns < 3) and (NextRandomUnitFloat(RandomState) < 0.2) and
        (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 2 = 0) then
        if JettisonCargoGoodsTowardTargetValue(Max(200, Galaxy.ComputeScaledMiniMoney(OwnerId))) then NotifyFearCargoDrop(EnemyShip);
    end else begin
      if not TryCollectBestFloatingItem(50) and (GetDesiredCargoFreeSpace > CargoFreeSpace) then NavigateToQueuedPlanet(True);
      if (EnemyShip <> nil) and (EnemyShip = OrderTarget) and (EnemyShip.CurrentPlanet <> nil) and
        (NextRandomUnitFloat(RandomState) < 0.2) then OrderNone;
      if not OrderAbsolute then begin
        SelectEnemyShipInStar;
        EngageEnemyShip;
        if (Order = soNone) and not InFear then TryJumpToNearbyBattle(0);
        if Order = soNone then NavigateToServicePlanet(False);
      end;
      if Order = soNone then OrderRandomFreeFlightMove;
    end;
  end;
end;
{ @end $58F950 }

{ @routine $58FC0C TPirate_NavigateToServicePlanet }
function TPirate.NavigateToServicePlanet(Absolute: Boolean): Boolean;
var Planet: TPlanet;
begin
  Result := False;
  Planet := SelectServicePlanet;
  if Planet <> nil then begin
    if Planet.CurrentStar = CurrentStar then OrderLanding(Planet, Absolute)
    else OrderJump(Planet.CurrentStar, Absolute);
    Result := True;
  end;
end;
{ @end $58FC0C }

{ @routine $58FC4C TPirate_SelectServicePlanet }
function TPirate.SelectServicePlanet: TPlanet;

  function PlanetPoints(Planet: TPlanet): Double;
  begin
    Result := NextRandomIntRange(0, 29, RandomState) + Planet.CurrentStar.TrafficLevel /
      PlanetRaceMarket[Planet.RaceId].PirateRelationFactor;
  end;

begin
  if PlanetQueue.Count > 0 then begin
    Result := PlanetQueue[0];
    if (FuelTanks.Fuel < FuelTanks.Capacity) or HasHullDamageOrBrokenEquippedItems or
      (NextRandomUnitFloat(RandomState) < 0.1) then Exit;
    Result := PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)];
  end else Result := nil;
end;
{ @end $58FC4C }

{ @routine $58FCEC TPirate_BuildReachablePlanetQueue }
procedure TPirate.BuildReachablePlanetQueue;
var I, J: Integer; Planet: TPlanet; Star: TStar;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if Speed <> 0 then
    for I := 0 to Galaxy.Stars.Count - 1 do begin
      Star := CurrentStar.StarDistances[I].Star as TStar;
      if (I > 0) and (CurrentStar.StarDistances[I].Distance > JumpRange) then Break;
      for J := 0 to Star.Planets.Count - 1 do begin
        Planet := Star.Planets[J];
        if Planet.IsCoalitionOwned and CanQueueReachablePlanet(Planet) then PlanetQueue.Add(Planet);
      end;
    end;
end;
{ @end $58FCEC }

{ @routine $58FDD8 TPirate_CanQueueReachablePlanet }
function TPirate.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId <> oiKling;
end;
{ @end $58FDD8 }

{ @routine $58FDE4 TPirate_TryJumpToNearbyBattle }
procedure TPirate.TryJumpToNearbyBattle(UnusedMode: Byte);
var Good: TGoodsIndex; I: Integer; Star: TStar;
begin
  for Good := t_Food to t_Narcotics do if CargoGoods[Good].Count > 0 then Exit;
  // The original tests this mode but discards the condition.
  if UnusedMode = 0 then ;
  for I := 1 to Galaxy.Stars.Count - 1 do begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if CurrentStar.StarDistances[I].Distance > JumpRange then Break;
    if Star.Battle and ((Star.ControlFaction = sfCoalition) or (CurrentStar.StarDistances[I].Distance < FuelTanks.Fuel div 2)) and
      (Star.Ships.Count - 3 >= Star.ShipTypeCounts[t_Kling]) and (Star.Ships.Count < 13) then begin
      OrderJump(Star, False);
      Exit;
    end;
  end;
end;
{ @end $58FDE4 }

{ @routine $58FE9C TPirate_SellAllCargoGoods }
procedure TPirate.SellAllCargoGoods;
var Good: TGoodsIndex;
begin
  for Good := t_Food to t_Narcotics do
    if CargoGoods[Good].Count > 0 then SellGoodsToLocation(Good, CargoGoods[Good].Count);
end;
{ @end $58FE9C }

{ @routine $58FEC4 TPirate_BuyInitialEquipment }
procedure TPirate.BuyInitialEquipment;
var Reserve: Integer;
begin
  Reserve := GetEquipmentMoneyReserve;
  if Money < Reserve then Exit;
  SetMoney(Money - Reserve);
  BuyHullUpgrade(scSmall);
  BuyCargoHookUpgrade(scSmall);
  BuyWeaponUpgrade(scSmall);
  if WeaponCount < 2 then BuyWeaponUpgrade(scZero);
  if WeaponCount < 1 then begin
    BuyWeaponUpgrade(scZero);
    if WeaponCount < 2 then begin BuyHullUpgrade(scAverage); BuyWeaponUpgrade(scZero); end;
  end;
  BuyEngineUpgrade(scBig);
  BuyRadarUpgrade(scSmall);
  SetMoney(Money + Reserve);
end;
{ @end $58FEC4 }

{ @routine $58FF64 TPirate_UpgradeEquipmentAtLocation }
procedure TPirate.UpgradeEquipmentAtLocation;
var Reserve: Integer;
begin
  Reserve := GetEquipmentMoneyReserve;
  if Money < Reserve then Exit;
  SetMoney(Money - Reserve);
  if WeaponCount = 0 then BuyWeaponUpgrade(scZero);
  if (WeaponCount > 0) and (CargoHook = nil) then BuyCargoHookUpgrade(scZero);
  if (WeaponCount > 1) and (NextRandomUnitFloat(RandomState) < 0.3) then BuyCargoHookUpgrade(scZero);
  if WeaponCount > 1 then BuyEngineUpgrade(scBig);
  if NextRandomUnitFloat(RandomState) < 0.5 then BuyWeaponUpgrade(scSmall);
  if WeaponCount > 1 then BuyRepairRobotUpgrade(scSmall);
  if WeaponCount > 0 then BuyHullUpgrade(scZero);
  if WeaponCount > 1 then BuyDefGeneratorUpgrade(scSmall);
  if WeaponCount > 2 then BuyFuelTanksUpgrade(scSmall);
  if WeaponCount > 1 then BuyRadarUpgrade(scSmall);
  if (WeaponCount > 2) and (Radar <> nil) then BuyScannerUpgrade(scSmall);
  SetMoney(Money + Reserve);
end;
{ @end $58FF64 }

{ @routine $5900A4 TPirate_RepairBrokenEquipmentAtLocation }
procedure TPirate.RepairBrokenEquipmentAtLocation;
var I, Cost: Integer; Equipment: TEquipment;
begin
  for I := Inventory.Count - 1 downto 0 do begin
    Equipment := Inventory[I];
    if (Equipment.BrokenFlag or (Equipment.ConditionPercent < 50)) and Equipment.EquippedFlag then begin
      Cost := Equipment.CalculateRepairCost;
      if Cost < Money then SetMoney(Money - Cost);
      Equipment.Repair;
    end;
  end;
end;
{ @end $5900A4 }

{ @routine $590110 TPirate_GetHomeStar }
function TPirate.GetHomeStar: TStar;
begin
  Result := HomePlanet.CurrentStar;
end;
{ @end $590110 }

{ @routine $590118 TPirate_GetName }
function TPirate.GetName: WideString;
begin
  Result := Name;
end;
{ @end $590118 }

{ @routine $59012C TPirate_GetFullName }
function TPirate.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.' + OwnerToSys(OwnerId) + '.' + GetTypeNameKey) + Separator + Name;
end;
{ @end $59012C }

{ @routine $5901E8 TPirate_GetTypeNameKey }
function TPirate.GetTypeNameKey: WideString;
begin
  Result := 'Pirate';
end;
{ @end $5901E8 }

{ @routine $590210 TPirate_GetGreetingShipCategory }
function TPirate.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscPirate;
end;
{ @end $590210 }

{ @routine $590214 TPirate_GetDominantCareer }
function TPirate.GetDominantCareer: TRangerCareer;
begin
  Result := rcPirate;
end;
{ @end $590214 }

{ @routine $590218 TPirate_GetStrengthScaledPirateStatus }
function TPirate.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 50;
end;
{ @end $590218 }

{ @routine $59021C TPirate_GetDesiredCargoFreeSpace }
function TPirate.GetDesiredCargoFreeSpace: Integer;
begin
  Result := Trunc(RemapClamped(Hull.Weight, ItemSizeFactors[5] * 500, ItemSizeFactors[1] * 500, 30, 150));
end;
{ @end $59021C }

{ @routine $590278 TPirate_GetEquipmentMoneyReserve }
function TPirate.GetEquipmentMoneyReserve: Integer;
begin
  Result := Wealth div 10;
end;
{ @end $590278 }

{ @routine $590288 TPirate_RefuelAtLocation }
procedure TPirate.RefuelAtLocation;
begin
  if FuelTanks <> nil then FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $590288 }

{ @routine $59029C TPirate_ProcessUnseenProgression }
procedure TPirate.ProcessUnseenProgression;
var StoredAward: PByte; Award: Byte;
begin
  if (DaysSincePlayerSeen >= 60) and (Player <> nil) then begin
    if (NextRandomUnitFloat(RandomState) < 0.2) and ((StrengthInBestRanger < 0.7) or (NextRandomUnitFloat(RandomState) < 0.3)) then begin
      if (NextRandomFloatRange(0, 0.7, RandomState) > WealthInBestRanger) and (Money < 25000) then
        SetMoney(Money + Galaxy.ComputeScaledBigMoney(oiPeople))
      else ImproveMostValuableEquipment;
    end;
    if NextRandomUnitFloat(RandomState) < 0.2 then GainExperience(NextRandomIntRange(50, 100, RandomState));
    if (Player.Rank > Rank) and (NextRandomUnitFloat(RandomState) < 0.1) and (Rank < crLeader) then begin
      AddRankPoints(NextRandomIntRange(10, 20, RandomState));
      TryPromoteRank;
    end;
    if NextRandomUnitFloat(RandomState) < 0.03 then begin
      Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment,atForSecretMission,atForCowardice,atForPerfidy]);
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      New(StoredAward);

      AwardIds.Add(StoredAward);
      StoredAward^ := Award;
    end;
  end;
end;
{ @end $59029C }

{ @routine $5904C8 TPirate_RelationToNonRanger }
function TPirate.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if (Ship = EnemyShip) or (Self = Ship.EnemyShip) then Result := 0
  else
    case Ship.ShipType of
      t_Ranger: Result := RelationToRanger(Ship);
      t_Transport: Result := Max(20, OwnerRelations[OwnerId, Ship.OwnerId] - 20);
      t_Pirate: Result := Max(60, OwnerRelations[OwnerId, Ship.OwnerId]);
      t_Warrior: Result := OwnerRelations[OwnerId, Ship.OwnerId] - 30;
      t_Kling: Result := 0;
      t_Tranclucator: if (Ship as TTranclucator).OwnerShip <> nil then Result := RelationToNonRanger((Ship as TTranclucator).OwnerShip)
        else Result := OwnerRelations[OwnerId, Ship.OwnerId];
      t_RangerCenter..t_ScientificBase: Result := 100;
    else Result := 50;
    end;
end;
{ @end $5904C8 }

{ @routine $590608 TPirate_RelationToRanger }
function TPirate.RelationToRanger(Ranger: TObject): Byte;
begin
  Result := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
end;
{ @end $590608 }

{ @routine $59063C TPirate_ChangeRelationToRanger }
procedure TPirate.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
var Relation: Byte; Value: Integer;
begin
  Relation := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  // Charisma increases negative changes too.
  if TShip(Ranger).BaseSkills[skCharm] > 0 then begin
    if Amount > 0 then Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.2))
    else Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.1));
  end;
  Value := Amount + Relation;
  if Value < 0 then Relation := 0
  else if Value > 100 then Relation := 100
  else Relation := Value;
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then
    EnemyShip := TShip(Ranger);
  RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $59063C }

{ @routine $590744 TPirate_ReactToAttack }
procedure TPirate.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.ShipType = t_Ranger then ChangeRelationToRanger(Attacker, -10);
end;
{ @end $590744 }

{ @routine $590764 TPirate_RecomputeFearState }
function TPirate.RecomputeFearState: Boolean;
var Ship: TShip; I, EnemyCount: Integer; Tolerance, Threat: Double;
begin
  Result := (Hull.HullPoints < Hull.Weight * 0.2) or ((EnemyShip <> nil) and
    ((EnemyShip.OrderTarget = Self) or (Player = EnemyShip)) and AcceptsRansomDemandFrom(EnemyShip));
  if not Result then begin
    Threat := 0;
    EnemyCount := 0;
    Tolerance := RemapClamped(Hull.HullPoints, 50, Hull.Weight, 0, 3);
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if Ship.InNormalSpace and (Ship <> Self) then begin
        if Ship = EnemyShip then begin
          Threat := Ship.ChanceToWin(Self) + Threat;
          Inc(EnemyCount);
        end else if ((Ship.EnemyShip = Self) and (Ship.OrderTarget = Self)) or
          ((Ship.RelationToNonRanger(Self) < 10) and (PointDistanceSquared(Position, Ship.Position) < 250000)) then begin
          Inc(EnemyCount);
          Threat := Ship.ChanceToWin(Self) + Threat;
          if (EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar) or EnemyShip.IsOutsideStarSpace then EnemyShip := Ship
          else if (EnemyShip <> Ship) and (OrderTarget <> EnemyShip) then
            if PointDistanceSquared(EnemyShip.Position, Position) > PointDistanceSquared(Ship.Position, Position) then EnemyShip := Ship;
        end;
      end;
    end;
    if (EnemyCount - 1) * Threat * 0.33 + Threat > Tolerance then Result := True;
  end;
  InFear := Result;
end;
{ @end $590764 }

{ @routine $590998 TPirate_TryOfferRansomToPursuer }
procedure TPirate.TryOfferRansomToPursuer;
var Response: WideString; Amount: Integer; LowOffer, HighOffer: Single;
  Accepted: Boolean; Ship: TShip;
begin
  if InNormalSpace and (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and (EnemyShip.TruceShip <> Self) and
    (Money > 100) and not CanEscapePursuer(EnemyShip) and not (EnemyShip.ShipType in NonNegotiatingShipTypes) and
    (EnemyShip.GetMaxWeaponRange * EnemyShip.GetMaxWeaponRange >= PointDistanceSquared(Position, EnemyShip.Position)) and
    (((Galaxy.CurrentTurn * Integer(EnemyShip.Id) mod 3 = 0) and (NextRandomUnitFloat(RandomState) > 0.2)) or (GetHullIntegrityPercent < 20)) then begin
    LowOffer := Min(Money, GetWealthScaledAmount(scMini));
    HighOffer := Min(Money, (GetWealthScaledAmount(scAverage) + EnemyShip.GetWealthScaledAmount(scBig)) * 0.5);
    Amount := Round(Max(100, RemapClampedAlternate(Hull.HullPoints, 0, Hull.Weight, HighOffer, LowOffer)));
    Ship := EnemyShip;
    Accepted := Ship.BuildTrucePaymentResponse(Self, Response, Amount);
    if (Ship <> Player) and (Player.CurrentStar = CurrentStar) then NotifyTruceOffer(Ship, Response, Amount);
    if Accepted and RecomputeFearState then TryOfferRansomToPursuer;
  end;
end;
{ @end $590998 }

{ @routine $590BFC TPirate_AcceptsRansomDemandFrom }
function TPirate.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := (Hull.HullPoints < Hull.Weight * 0.6 * OwnerInfo[OwnerId].FearThresholdScale) and
    (ChanceToWin(Ship) - OwnerInfo[OwnerId].FearThresholdScale / 2 < 0);
end;
{ @end $590BFC }

{ @routine $590C7C TPirate_TrustsAttackRequester }
function TPirate.TrustsAttackRequester(Ship: TShip): Boolean;
begin
 Result := RelationToNonRanger(Ship) >= 30;
end;
{ @end $590C7C }

{ @routine $590C94 TPirate_EvaluateAllyRelationAndStrength }
function TPirate.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := (RelationToNonRanger(Ship)) +
    RemapClamped(Ship.Strength, 0.9 * Strength, Strength * 3, 0, 100) > 130;
end;
{ @end $590C94 }

{ @routine $59101C TPirate_ProcessImprisonment }
function TPirate.ProcessImprisonment: Boolean;
var I: Integer; Ship: TShip;
  // @nested $590D1C Imprison
  procedure Imprison; // @addr $590D1C
  var I: Integer; Ship: TShip; Text: WideString;
  begin
    PrisonTermRemaining := NextRandomIntRange(61, 140, RandomState);
    Result := True;
    for I := 0 to CurrentPlanet.Warriors.Count - 1 do begin
      Ship := CurrentPlanet.Warriors[I];
      if Ship.EnemyShip = Self then Ship.EnemyShip := nil;
    end;
    Text := PickLocalizedTextVariant('GalaxyNews.GoToPrison.' + GetTypeNameKey, Seed + Cardinal(Galaxy.CurrentTurn div 10));
    ReplaceTextToken(Text, '<Star>', CurrentStar.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<Planet>', CurrentPlanet.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<Month>', IntToStr(PrisonTermRemaining div 30), HighlightColorTag);
    ReplaceTextToken(Text, '<Name>', GetName, HighlightColorTag);
    ReplaceTextToken(Text, '<FullName>', GetFullName(' '), HighlightColorTag);
    if (Player.CurrentStar = CurrentStar) and Player.InNormalSpace then Galaxy.AddPlanetNewsWithPlayerBubble(Text)
    else Galaxy.AddPlanetNews(gnGeneral, Text);
  end;
begin
  Result := False;
  if CurrentPlanet = nil then Exit;
  if PrisonTermRemaining > 0 then begin
    if CurrentStar.Battle then begin PrisonTermRemaining := 0; Result := False; Exit; end;
    Dec(PrisonTermRemaining);
    if PrisonTermRemaining = 0 then Result := False else Result := True;
  end else begin
    for I := 0 to CurrentPlanet.Warriors.Count - 1 do begin
      Ship := CurrentPlanet.Warriors[I];
      if Ship.EnemyShip = Self then begin Imprison; Exit; end;
    end;
    if NextRandomUnitFloat(RandomState) < 0.01 then Imprison;
  end;
end;
{ @end $59101C }

{ @routine $5910F4 TPirate_AssignWeaponTargetsInStar }
procedure TPirate.AssignWeaponTargetsInStar;
var
  I, J, Assigned: Integer;
  Ship: TShip;
  Item: TItem;
  Asteroid: TAsteroid;
  Distance: Single;
  Weapon: TWeapon;
begin
  for I := 1 to WeaponCount do begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  Assigned := 0;

  if CurrentStar.Battle then
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if (Ship.OwnerId = oiKling) and Ship.InNormalSpace then
        for J := 1 to WeaponCount do begin
          Weapon := Weapons[J - 1];
          if not (((Weapon.Target = nil) and not Weapon.BrokenFlag and
            (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position)))) then Continue;
          Weapon.Target := Ship;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
        end;
    end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    for J := 1 to WeaponCount do begin
      Weapon := Weapons[J - 1];
      if not (((Weapon.Target = nil) and not Weapon.BrokenFlag and
        (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, EnemyShip.Position)))) then Continue;
      Weapon.Target := EnemyShip;
      Inc(Assigned);
      if Assigned = WeaponCount then Exit;
    end;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.InNormalSpace and (Self <> Ship) and
      ((RelationToNonRanger(Ship) < 10) or (Ship = EnemyShip) or (Self = Ship.EnemyShip)) and (TruceShip <> Ship) then
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not ((not Weapon.BrokenFlag and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position)))) then Continue;
        // The original may overwrite a previously assigned target.
        Weapon.Target := Ship;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
      end;
  end;
  if (CargoHook <> nil) and not CargoHook.BrokenFlag and not OrderAbsolute then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do begin
      Asteroid := CurrentStar.Asteroids[I];
      if Asteroid.MineralCount > CargoFreeSpace then Continue;
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance > AsteroidTargetRangeSquared then Continue;
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not ((not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag and
          (Weapon.Range * Weapon.Range >= Distance))) then Continue;
        Weapon.Target := Asteroid;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
        Break;
      end;
    end;
  if CurrentStar.Items.Count > 7 then
    for I := 0 to CurrentStar.Items.Count - 1 do begin
      Item := CurrentStar.Items[I];
      if not ((Item.ItemType = t_Minerals) or not (Item.ItemType in [t_Food..t_Narcotics])) then Continue;
      if not ((Item.ScriptItem = nil) and not CanHookItem(Item)) then Continue;
      if not ((Player.CurrentStar <> CurrentStar) or (GetRelationLevelToShip(Player) <= rlBad) or
        (PointDistance(Player.Position, Item.Position) >= 600) or
        ((NextRandomUnitFloat(RandomState) <= 0.2) and (PointDistance(Player.Position, Item.Position) >= 200))) then Continue;
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not ((not Weapon.HasSpecialDamageMode and (Weapon.Target = nil) and not Weapon.BrokenFlag and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Item.Position)))) then Continue;
        Weapon.Target := Item;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
        Break;
      end;
    end;
end;
{ @end $5910F4 }

{ @routine $59161C TPirate_SelectEnemyShipInStar }
procedure TPirate.SelectEnemyShipInStar;
var I: Integer; Ship, OldEnemy: TShip; Chance, BestChance: Double;
begin
  if CargoHook = nil then Exit;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then Exit;
  if UsableWeaponCount = 0 then Exit;
  if (Player.QuestTargetDefendShip <> nil) and (Player.QuestTargetDefendShip.CurrentStar = CurrentStar) and
    (Player.QuestTargetDefendShip <> Self) and Player.QuestTargetDefendShip.InNormalSpace and
    (Player.QuestTargetDefendShip <> TruceShip) and (Player.QuestTargetDefendShip.ScriptShip = nil) then begin
    EnemyShip := Player.QuestTargetDefendShip;
    AssignWeaponTargetsInStar;
    Exit;
  end;
  OldEnemy := EnemyShip;
  EnemyShip := nil;
  BestChance := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if (Ship.ScriptShip <> nil) or (Ship = Self) or not Ship.InNormalSpace or (Ship = TruceShip) or
      ((Ship.LiberationGroup <> nil) and ((Ship.LiberationGroup as TGroup).GroupKind = 0)) or
      (Ship = Player.QuestTargetKillShip) then Continue;
    if CurrentStar.ControlFaction <> sfCoalition then begin
      if Ship.OwnerId = oiKling then begin
        if ChanceToWin(Ship) > 0.5 then begin EnemyShip := Ship; Exit; end;
        EnemyShip := Ship;
      end;
    end else begin
      if RelationToNonRanger(Ship) > NextRandomIntRange(0, 30, RandomState) + 60 then Continue;
      Chance := ChanceToWin(Ship);
      if Ship = Player then begin
        if (Galaxy.CurrentTurn < 100 / DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor + 200) or
          (NextRandomIntRange(0, 100, RandomState) * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor < 40) then Continue;
        Chance := Chance * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor;
      end;
      if (Chance < 0.3) and (StrengthInAverageRanger < 0.7) then Continue;
      if (Ship.ShipType = t_Ranger) and (Chance < 1.5) and ((Ship <> Player) or (Player.GetDominantCareer <> rcPirate)) then Continue;
      if (Ship.ShipType = t_Pirate) and (Chance < 3.5) then Continue;
      if not IsTargetStillPursuable(Ship) and (Ship <> Player) then Continue;
      if Chance > BestChance then begin
        EnemyShip := Ship;
        BestChance := Chance;
        if EnemyShip = Player then Break;
      end;
    end;
  end;
  if EnemyShip <> nil then
    if not IsOutsideExtortionRange(EnemyShip) then begin AssignWeaponTargetsInStar; Exit; end
    else if not TryExtortShip(EnemyShip) then begin AssignWeaponTargetsInStar; Exit; end;
  EnemyShip := OldEnemy;
end;
{ @end $59161C }

{ @routine $5919DC TPirate_EngageEnemyShip }
procedure TPirate.EngageEnemyShip;
begin
  if Order = soFollowShip then OrderNone;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then begin
    if EnemyShip.InNormalSpace then begin
      OrderFollowShip(EnemyShip, fmMinWeaponRange, False);
      if ChanceToWin(EnemyShip) < 0.8 then RequestAlliesAttackShip(EnemyShip);
    end else if (ChanceToWin(EnemyShip) > 2) and (GetHullIntegrityPercent > 70) and (EnemyShip.GetHullIntegrityPercent > 70) then begin
      if EnemyShip.CurrentPlanet <> nil then OrderMove(EnemyShip.CurrentPlanet.GetPosition, False)
      else if EnemyShip.DockedTo <> nil then OrderMove(EnemyShip.DockedTo.Position, False);
    end;
  end;
end;
{ @end $5919DC }

{ @routine $591AD0 TPirate_ProcessCombatDialogue }
procedure TPirate.ProcessCombatDialogue;
begin
  if (EnemyShip <> nil) and (EnemyShip = OrderTarget) and (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 5 = 0) and
    not AcceptsRansomDemandFrom(EnemyShip) then TryExtortShip(EnemyShip);
  if (EnemyShip <> nil) and (EnemyShip = OrderTarget) and (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 4 = 0) and
    (ChanceToWin(EnemyShip) < 1.1) and (GetHullIntegrityPercent > 30) then RequestAlliesAttackShip(EnemyShip);
end;
{ @end $591AD0 }

{ @routine $591B8C TPirate_ReactToExtortionDemand }
procedure TPirate.ReactToExtortionDemand(Ranger: TObject);
begin
  if (Player = Ranger) or (NextRandomUnitFloat(RandomState) < 0.05) then begin
    ChangeRelationToRanger(Ranger, -15);
    HomePlanet.ChangeRelationToRanger(Ranger, -1);
    (Ranger as TRanger).AddPirateCareerActivity(1);
  end;
end;
{ @end $591B8C }

{ @routine $591C64 TPirate_BuildMoneyExtortionResponse }
function TPirate.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
  // @nested $591BF4 PayDemand
  procedure PayDemand; // @addr $591BF4
  begin
    OtherShip.SetMoney(OtherShip.Money + DemandedAmount);
    SetMoney(Money - DemandedAmount);
    OtherShip.TruceWithShip(Self);
    if OtherShip = Player then LastPlayerExtortionTurn := Galaxy.CurrentTurn;
  end;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if (Player <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if (OtherShip.TruceShip = Self) or ((Player = OtherShip) and (LastPlayerExtortionTurn + 30 > Galaxy.CurrentTurn)) then Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'LongDistance')
  else if DemandedAmount > RemapClampedAlternate(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scBig), GetWealthScaledAmount(scSmall)) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'SumIsVeryBig')
  else if Money < DemandedAmount then Response := LookupVisibleTalkText('Talk.Money.AnswerNotMoney')
  else begin
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'Ok');
    PayDemand;
    Result := True;
  end;
end;
{ @end $591C64 }

{ @routine $592158 TPirate_BuildCargoExtortionResponse }
function TPirate.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
  // @nested $592008 DropDemand
  procedure DropDemand; // @addr $592008
  var Good: TGoodsIndex; Pass, Count, TotalValue, LowValue, HighValue: Integer; Enough: Boolean; Divisor: Single;
  begin
    TotalValue := 0;
    Enough := False;
    LowValue := GetWealthScaledAmount(scSmall);
    HighValue := GetWealthScaledAmount(scBig);
    for Pass := 1 to 3 do begin
      for Good := t_Food to t_Narcotics do
        if CargoGoods[Good].Count > 0 then begin
          Divisor := RemapClamped(CargoGoods[Good].Count * GoodsMarket[Good].BasePrice, LowValue, HighValue, 2, 8);
          Count := Max(1, Round(CargoGoods[Good].Count / Divisor));
          Inc(TotalValue, Count * GoodsMarket[Good].BasePrice);
          DropGoodsIntoSpace(Good, Count);
          if TotalValue > HighValue then begin Enough := True; Break; end;
        end;
      if Enough then Break;
    end;
    OtherShip.TruceWithShip(Self);
    if OtherShip = Player then LastPlayerExtortionTurn := Galaxy.CurrentTurn;
    OtherShip.OrderMove(Position, True);
  end;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if (Player <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if (OtherShip.TruceShip = Self) or ((Player = OtherShip) and (LastPlayerExtortionTurn + 30 > Galaxy.CurrentTurn)) then Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'LongDistance')
  else if not HasCargoGoods then Response := LookupVisibleTalkText('Talk.Goods.AnswerNotGoods')
  else begin
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'Ok');
    DropDemand;
    Result := True;
  end;
end;
{ @end $592158 }

{ @routine $5924A0 TPirate_BuildTrucePaymentResponse }
function TPirate.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
  // @nested $592428 AcceptPayment
  procedure AcceptPayment; // @addr $592428
  begin
    if OtherShip is TRanger then (OtherShip as TRanger).AddTraderCareerActivity(1);
    OtherShip.SetMoney(OtherShip.Money - OfferedAmount);
    SetMoney(Money + OfferedAmount);
    TruceWithShip(OtherShip);
  end;
begin
  Result := False;
  if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact')
  else if RecomputeFearState or ((ChanceToWin(OtherShip) < 1) and (GetHullIntegrityPercent < 40)) or (ChanceToWin(OtherShip) < 0.2) or
    (OfferedAmount > RemapClamped(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scMini), GetWealthScaledAmount(scHuge))) then begin
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'Ok');
    AcceptPayment;
    Result := True;
  end else Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'No');
end;
{ @end $5924A0 }

{ @routine $5927B8 TPirate_BuildAttackRequestResponse }
function TPirate.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
  // @nested $5926E8 AcceptRequest
  procedure AcceptRequest; // @addr $5926E8
  begin
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Ok');
    SetJointAttackTarget(Requester, Target);
    Result := True;
  end;
begin
  Result := False;
  if Requester is TRanger then begin
    if Target.ShipType in [t_Ranger..t_Pirate] then Target.ChangeRelationToRanger(Requester, -20);
    if (Target.OwnerId = oiKling) or (Target.ShipType = t_Pirate) then
      (Requester as TRanger).AddWarriorCareerActivity(1)
    else (Requester as TRanger).AddPirateCareerActivity(1);
  end;
  if (OrderTarget = Target) and (GetRelationLevelToShip(Target) = rlHostile) then AcceptRequest
  else if TruceShip = Target then
    Response := ReplaceColoredToken(LookupVisibleTalkText('Talk.Attack.WeAlreadyHavePact'), '<Target>', Target.GetName, '')
  else if RelationToNonRanger(Target) >= 60 then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriends')
  else if AcceptsRansomDemandFrom(Target) or InFear then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Fear')
  else if not TrustsAttackRequester(Requester) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Suspect')
  else if HasLockedOrFollowOrder then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'HaveBusiness')
  else AcceptRequest;
end;
{ @end $5927B8 }

{ @routine $592B20 TPirate_AcceptPartnershipOffer }
function TPirate.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $592B20 }

{ @routine $592B64 TPirate_BuildPartnershipOfferResponse }
function TPirate.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $592B64 }

{ @routine $592BA8 TPirate_TrainSkillsAutomatically }
procedure TPirate.TrainSkillsAutomatically;
begin
  if FreeExperience < 50 then Exit;
  if NextRandomUnitFloat(RandomState) < 0.1 then TrainSkill(skCharm);
  if NextRandomUnitFloat(RandomState) < 0.3 then TrainSkill(skAccuracy);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skMobility);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skMobility);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skAccuracy);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skTechnical);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skTechnical);
  if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skTrader);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skTrader);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skAccuracy);
  if NextRandomUnitFloat(RandomState) < 0.2 then TrainSkill(skLeadership);
  if NextRandomUnitFloat(RandomState) < 0.5 then TrainSkill(skCharm);
end;
{ @end $592BA8 }

end.

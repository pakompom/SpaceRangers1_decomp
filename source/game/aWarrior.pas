unit aWarrior;
// Unit bracket (inferred): CODE 0x004E1844..0x004E3E7B; inclusive evidence, not full bounds.
// Military ship; native VMT $4E1890.
interface
uses aNormalShip, aShip, aPlanet, aGalaxy, EC_Buf;
type
  TWarrior = class(TNormalShip) // @size $1D0
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $4E1EBC
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $4E1EC4
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $4E36EC
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $4E3960
    procedure NextDay; override; // @addr $4E1ECC
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $4E26CC
    procedure SelectEnemyShipInStar; override; // @addr $4E3098
    procedure EngageEnemyShip; override; // @addr $4E31FC
    procedure AssignWeaponTargetsInStar; // @addr $4E2B48
    procedure InitGenerated(Planet: TPlanet; InitialMoney: Integer); // @addr $4E1A64
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $4E32DC
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $4E3338
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $4E3430
    destructor Destroy; override; // @addr $4E1934
    procedure BuildReachablePlanetQueue; override; // @addr $4E20BC
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $4E2120
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $4E23D0
    function GetHomeStar: TStar; override; // @addr $4E2420
    function GetName: WideString; override; // @addr $4E2428
    function GetFullName(const Separator: WideString): WideString; override; // @addr $4E243C
    function GetTypeNameKey: WideString; override; // @addr $4E24F8
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $4E2520
    function GetDominantCareer: TRangerCareer; override; // @addr $4E2524
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $4E2528
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $4E252C
    procedure RefuelAtLocation; override; // @addr $4E2530
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $4E2AA8
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $4E3CFC
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $4E3D40
    procedure ProcessCombatDialogue; override; // @addr $4E32D8
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $4E2854
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $4E2810
    procedure ReactToAttack(Attacker: TShip); override; // @addr $4E2934
    function NavigateToHomePlanet: Boolean; // @addr $4E2004
    procedure MoveToRandomPatrolPoint; // @addr $4E212C
    procedure BuyInitialEquipment; override; // @addr $4E2188
    procedure UpgradeEquipmentAtLocation; override; // @addr $4E22CC
    procedure ProcessUnseenProgression; // @addr $4E2544
    function RecomputeFearState: Boolean; override; // @addr $4E2950
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $4E2A28
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $4E2AC0
    procedure TrainSkillsAutomatically; override; // @addr $4E3D84
  end;
implementation

// @unit-initialization $4E3E74
// @unit-finalization $4E3E44

uses Classes, SysUtils, Math, aConst, aMyFunction, aItem, aRanger, Globals, GR_Main, SE_Ship2, aTranclucator, aGroup, aAsteroid;

{ @routine $4E1934 TWarrior_Destroy }
destructor TWarrior.Destroy;
var Index: Integer;
begin
  Dec(HomePlanet.HomeWarriorCount);
  Index := HomePlanet.Warriors.IndexOf(Self);
  if Index >= 0 then HomePlanet.Warriors.Delete(Index);
  inherited Destroy;
end;
{ @end $4E1934 }

{ @routine $4E1A64 TWarrior_InitGenerated }
procedure TWarrior.InitGenerated(Planet: TPlanet; InitialMoney: Integer);
var LastIndex, FirstIndex: Integer; Ranger: TRanger; TechLevel: Byte;

  // @nested $4E1988 RandomSize
  function RandomSize(Value: Single): Integer; // @addr $4E1988
  begin
    Result := NextRandomIntRange(Round(Value * 0.5), Round(Value * 1.4), RandomState);
  end;

  // @nested $4E19D0 RandomLevel
  function RandomLevel(LowLevel, HighLevel: Integer): Integer; // @addr $4E19D0
  begin
    Result := Round(RemapClamped(Galaxy.TechLevel, 1, 8, LowLevel, HighLevel));
    Result := Max(Min(Result + NextRandomIntRange(-2, 2, RandomState), HighLevel), LowLevel);
  end;

begin
  if (PlayerHomeRanger = nil) and False then PlayerHomeRanger := Self;
  HomePlanet := Planet;
  CurrentPlanet := HomePlanet;
  CurrentPlanet.Warriors.Add(Self);
  CurrentStar := CurrentPlanet.CurrentStar;
  OwnerId := HomePlanet.OwnerId;
  SetMoney(InitialMoney);
  ShipType := t_Warrior;
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('ShipName').GetBlock('Warrior').GetBlock(OwnerToSys(OwnerId)).GetParamCount - 1;
  Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Warrior').GetBlock(OwnerToSys(OwnerId)).GetParamValue(
    NextRandomIntRange(FirstIndex, LastIndex, RandomState)) + ' ' + '-' + IntToStr(Id mod 100 + 1) + '-';
  if Player <> nil then begin
    Rank := TCoalitionRank(NextRandomIntRange(0, Min(5, Ord(Player.Rank) + 2), RandomState));
    if Rank > crAce then Rank := crAce;
    AddRankPoints(NextRandomIntRange(0, CoalitionRankPointThresholds[Rank] div 2, RandomState));
    GainExperience(Round(RemapClamped(Ord(Rank), 0, 1000, 2100, 6300)));
  end;
  Graphic := TShip2SE.CreateEmpty;
  ShipRenderTemplates[Planet.OwnerId, 1].SpaceObject.CopyTo(Graphic);
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(0);
  CollisionRadius := 32;
  Ranger := Galaxy.StrongestRanger as TRanger;
  if Ranger = nil then TechLevel := 4 else TechLevel := Ranger.Hull.TechLevel;
  CreateAndEquipHull(True, RandomSize(400), Min(TechLevel, RandomLevel(1, 6)), OwnerId);
  CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
  CreateAndEquipWeapon(t_PhotonGun, True, WeaponInfo[t_PhotonGun].Weight, 1, OwnerId);
  CreateAndEquipWeapon(t_ZipGun, True, WeaponInfo[t_ZipGun].Weight, 1, OwnerId);
  CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[NextRandomIntRange(2, 4, RandomState)]), 1, OwnerId);
  RefreshDerivedStats;
  BuyInitialEquipment;
end;
{ @end $4E1A64 }

{ @routine $4E1EBC TWarrior_SaveToBuffer }
procedure TWarrior.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $4E1EBC }

{ @routine $4E1EC4 TWarrior_LoadFromBuffer }
procedure TWarrior.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $4E1EC4 }

{ @routine $4E1ECC TWarrior_NextDay }
procedure TWarrior.NextDay;
var Planet: TPlanet;
begin
  inherited NextDay;
  if ScriptShip <> nil then begin ScriptNextDay; if ScriptShip <> nil then Exit; end;
  if CurrentPlanet <> nil then begin
    RepairBrokenEquipmentAtLocation;
    OptimizeInventory;
    RefuelAtLocation;
    ProcessUnseenProgression;
    TrainSkillsAutomatically;
    if not RepairHullAtLocation then begin
      if LiberationGroup <> nil then ProcessLiberationGroupRoute;
      if (CurrentPlanet <> HomePlanet) or (LiberationGroup <> nil) then OrderTakeoff;
    end;
  end else if InNormalSpace then begin
    RecomputeFearState;
    AssignWeaponTargetsInStar;
    if InFear then begin
      if Order <> soLanding then begin
        BuildReachablePlanetQueue;
        Planet := SelectNearestQueuedPlanet;
        if (Planet <> nil) and (Planet.CurrentStar = CurrentStar) then OrderLanding(Planet, True)
        else begin SelectEnemyShipInStar; EngageEnemyShip; end;
      end;
    end else begin SelectEnemyShipInStar; EngageEnemyShip; end;
    if LiberationGroup <> nil then ProcessLiberationGroupRoute
    else if (Order = soNone) and not NavigateToHomePlanet then MoveToRandomPatrolPoint;
  end;
end;
{ @end $4E1ECC }

{ @routine $4E2004 TWarrior_NavigateToHomePlanet }
function TWarrior.NavigateToHomePlanet: Boolean;
begin
  if HomePlanet.CurrentStar = CurrentStar then begin
    OrderLanding(HomePlanet, False);
    Result := True;
  end else if (FuelTanks.Fuel = FuelTanks.Capacity) or
    (JumpRange * JumpRange >= PointDistanceSquared(HomePlanet.CurrentStar.Position, CurrentStar.Position)) then begin
    OrderJump(HomePlanet.CurrentStar, False);
    Result := True;
  end else begin
    BuildReachablePlanetQueue;
    if PlanetQueue.Count > 0 then begin
      OrderLanding(PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)], False);
      Result := True;
    end else Result := False;
  end;
end;
{ @end $4E2004 }

{ @routine $4E20BC TWarrior_BuildReachablePlanetQueue }
procedure TWarrior.BuildReachablePlanetQueue;
var I: Integer; Planet: TPlanet;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if Speed <> 0 then
    for I := 0 to CurrentStar.Planets.Count - 1 do begin
      Planet := CurrentStar.Planets[I];
      if Planet.IsCoalitionOwned then PlanetQueue.Add(Planet);
    end;
end;
{ @end $4E20BC }

{ @routine $4E2120 TWarrior_CanQueueReachablePlanet }
function TWarrior.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId <> oiKling;
end;
{ @end $4E2120 }

{ @routine $4E212C TWarrior_MoveToRandomPatrolPoint }
procedure TWarrior.MoveToRandomPatrolPoint;
var Point: TPointF;
begin
  Point.X := NextRandomIntRange(-2000, 2000, RandomState);
  Point.Y := NextRandomIntRange(-2000, 2000, RandomState);
  OrderMove(Point, False);
end;
{ @end $4E212C }

{ @routine $4E2188 TWarrior_BuyInitialEquipment }
procedure TWarrior.BuyInitialEquipment;
begin
  if Money > 0 then begin
    BuyHullUpgrade(scSmall);
    BuyWeaponUpgrade(scBig);
    if StrengthInAverageRanger < RemapClampedAlternate(Galaxy.WarDeltaWin, -5, 5, 2, 0.5) then BuyWeaponUpgrade(scZero);
    if StrengthInAverageRanger < RemapClampedAlternate(Galaxy.WarDeltaWin, -5, 5, 2, 0.5) then BuyWeaponUpgrade(scZero);
    if (WeaponCount < 3) and (StrengthInAverageRanger < 0.7) then BuyWeaponUpgrade(scZero);
    if WeaponCount = 0 then BuyWeaponUpgrade(scZero);
    BuyEngineUpgrade(scSmall);
    BuyDefGeneratorUpgrade(scBig);
    BuyFuelTanksUpgrade(scSmall);
    BuyRadarUpgrade(scZero);
    BuyScannerUpgrade(scZero);
    BuyRepairRobotUpgrade(scZero);
    if StrengthInAverageRanger < 0.7 then BuyWeaponUpgrade(scZero);
  end;
end;
{ @end $4E2188 }

{ @routine $4E22CC TWarrior_UpgradeEquipmentAtLocation }
procedure TWarrior.UpgradeEquipmentAtLocation;
begin
  if StrengthInAverageRanger < RemapClampedAlternate(Galaxy.WarDeltaWin, -5, 5, 2, 0.5) then BuyWeaponUpgrade(scZero);
  if WeaponCount > 0 then BuyEngineUpgrade(scSmall);
  if WeaponCount > 0 then BuyRepairRobotUpgrade(scZero);
  if WeaponCount > 0 then BuyHullUpgrade(scZero);
  if (StrengthInAverageRanger < 0.9) and (WeaponCount > 1) then BuyDefGeneratorUpgrade(scZero);
  if WeaponCount > 0 then BuyFuelTanksUpgrade(scZero);
  if WeaponCount > 2 then BuyRadarUpgrade(scZero);
  if (WeaponCount > 2) and (Radar <> nil) then BuyScannerUpgrade(scZero);
  if WeaponCount > 0 then BuyCargoHookUpgrade(scZero);
end;
{ @end $4E22CC }

{ @routine $4E23D0 TWarrior_RepairBrokenEquipmentAtLocation }
procedure TWarrior.RepairBrokenEquipmentAtLocation;
var I: Integer; Equipment: TEquipment;
begin
  for I := 1 to Inventory.Count - 1 do begin
    Equipment := Inventory[I];
    if Equipment.BrokenFlag or (Equipment.ConditionPercent < 30) then Equipment.Repair;
  end;
end;
{ @end $4E23D0 }

{ @routine $4E2420 TWarrior_GetHomeStar }
function TWarrior.GetHomeStar: TStar;
begin
  Result := HomePlanet.CurrentStar;
end;
{ @end $4E2420 }

{ @routine $4E2428 TWarrior_GetName }
function TWarrior.GetName: WideString;
begin
  Result := Name;
end;
{ @end $4E2428 }

{ @routine $4E243C TWarrior_GetFullName }
function TWarrior.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.' + OwnerToSys(OwnerId) + '.' + GetTypeNameKey) + Separator + Name;
end;
{ @end $4E243C }

{ @routine $4E24F8 TWarrior_GetTypeNameKey }
function TWarrior.GetTypeNameKey: WideString;
begin
  Result := 'Warrior';
end;
{ @end $4E24F8 }

{ @routine $4E2520 TWarrior_GetGreetingShipCategory }
function TWarrior.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscWarrior;
end;
{ @end $4E2520 }

{ @routine $4E2524 TWarrior_GetDominantCareer }
function TWarrior.GetDominantCareer: TRangerCareer;
begin
  Result := rcWarrior;
end;
{ @end $4E2524 }

{ @routine $4E2528 TWarrior_GetStrengthScaledPirateStatus }
function TWarrior.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 0;
end;
{ @end $4E2528 }

{ @routine $4E252C TWarrior_GetDesiredCargoFreeSpace }
function TWarrior.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
end;
{ @end $4E252C }

{ @routine $4E2530 TWarrior_RefuelAtLocation }
procedure TWarrior.RefuelAtLocation;
begin
  if FuelTanks <> nil then FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $4E2530 }

{ @routine $4E2544 TWarrior_ProcessUnseenProgression }
procedure TWarrior.ProcessUnseenProgression;
var StoredAward: PByte; Award: Byte;
begin
  if (DaysSincePlayerSeen >= 60) and (Player <> nil) then begin
    if NextRandomUnitFloat(RandomState) < 0.05 then GainExperience(SeededRandomIntRange(25, 70, RandomState));
    if (Player.Rank > Rank) and (NextRandomUnitFloat(RandomState) < 0.01) and (Rank < crLeader) then begin
      AddRankPoints(NextRandomIntRange(10, 20, RandomState));
      TryPromoteRank;
    end;
    if NextRandomUnitFloat(RandomState) < 0.02 then begin
      Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment,atForSecretMission]);
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      New(StoredAward);

      AwardIds.Add(StoredAward);
      StoredAward^ := Award;
    end;
  end;
end;
{ @end $4E2544 }

{ @routine $4E26CC TWarrior_RelationToNonRanger }
function TWarrior.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if (Ship = EnemyShip) or (Self = Ship.EnemyShip) then begin Result := 0; Exit; end;
  case Ship.ShipType of
    t_Ranger: Result := HomePlanet.GetRangerRelationByIndex(Galaxy.Rangers.IndexOf(Ship as TRanger));
    t_Transport: Result := 100;
    t_Pirate: Result := Round(Min(20.0, PlanetRaceMarket[OwnerToRace(OwnerId)].PirateRelationFactor * 50 * OwnerRelations[OwnerId, Ship.OwnerId]));
    t_Warrior: Result := 100;
    t_Kling: Result := 0;
    t_Tranclucator: if (Ship as TTranclucator).OwnerShip <> nil then Result := RelationToNonRanger((Ship as TTranclucator).OwnerShip)
      else Result := 100;
    t_RangerCenter..t_ScientificBase: Result := 100;
  else Result := 0;
  end;
end;
{ @end $4E26CC }

{ @routine $4E2810 TWarrior_RelationToRanger }
function TWarrior.RelationToRanger(Ranger: TObject): Byte;
begin
  if Ranger = EnemyShip then Result := 0
  else Result := Byte(HomePlanet.RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
end;
{ @end $4E2810 }

{ @routine $4E2854 TWarrior_ChangeRelationToRanger }
procedure TWarrior.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
var Relation: Byte; Value: Integer;
begin
  Relation := Byte(HomePlanet.RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  // Charisma increases negative changes too.
  if TShip(Ranger).BaseSkills[skCharm] > 0 then
    Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.2));
  Value := Amount + Relation;
  if Value < 0 then Relation := 0
  else if Value > 100 then Relation := 100
  else Relation := Value;
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then
    EnemyShip := TShip(Ranger);
  HomePlanet.RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $4E2854 }

{ @routine $4E2934 TWarrior_ReactToAttack }
procedure TWarrior.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.ShipType = t_Ranger then HomePlanet.ChangeRelationToRanger(Attacker, -3);
end;
{ @end $4E2934 }

{ @routine $4E2950 TWarrior_RecomputeFearState }
function TWarrior.RecomputeFearState: Boolean;
begin
  Result := ((Hull.HullPoints < Hull.Weight * 0.2) and (Hull.HullPoints < 100)) or
    ((Hull.HullPoints < Hull.Weight * 0.4 * OwnerInfo[OwnerId].FearThresholdScale) and
    (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and
    (ChanceToWin(EnemyShip) - OwnerInfo[OwnerId].FearThresholdScale / 2 < 0));
  InFear := Result;
end;
{ @end $4E2950 }

{ @routine $4E2A28 TWarrior_AcceptsRansomDemandFrom }
function TWarrior.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := (Hull.HullPoints < Hull.Weight * 0.4 * OwnerInfo[OwnerId].FearThresholdScale) and
    (ChanceToWin(Ship) - OwnerInfo[OwnerId].FearThresholdScale / 2 < 0);
end;
{ @end $4E2A28 }

{ @routine $4E2AA8 TWarrior_TrustsAttackRequester }
function TWarrior.TrustsAttackRequester(Ship: TShip): Boolean;
begin
 Result := RelationToNonRanger(Ship) >= 30;
end;
{ @end $4E2AA8 }

{ @routine $4E2AC0 TWarrior_EvaluateAllyRelationAndStrength }
function TWarrior.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := (RelationToNonRanger(Ship)) +
    RemapClamped(Ship.Strength, 0.9 * Strength, Strength * 3, 0, 100) > 160;
end;
{ @end $4E2AC0 }

{ @routine $4E2B48 TWarrior_AssignWeaponTargetsInStar }
procedure TWarrior.AssignWeaponTargetsInStar;
var
  I, J, Assigned: Integer;
  Ship: TShip;
  Weapon: TWeapon;
  Distance: Single;
  Item: TItem;
  Asteroid: TAsteroid;
begin
  for I := 1 to WeaponCount do begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  Assigned := 0;
  if CurrentStar.Battle then
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if (Ship.OwnerId = oiKling) and Ship.InNormalSpace then begin
        Distance := PointDistance(Position, Ship.Position);
        for J := 1 to WeaponCount do begin
          Weapon := Weapons[J - 1];
          if not (((Weapon.Target = nil) and not Weapon.BrokenFlag and (Weapon.Range >= Distance))) then Continue;
          Weapon.Target := Ship;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
        end;
      end;
    end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then begin
    if (EnemyShip.ShipType = t_Ranger) and (EnemyShip.OrderTarget = HomePlanet) and not EnemyShip.HasWeaponTarget(Self) then
      ClearWeaponTargets(EnemyShip)
    else
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, EnemyShip.Position))) then Continue;
        Weapon.Target := EnemyShip;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
      end;
  end;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.InNormalSpace and (Self <> Ship) and (Ship <> EnemyShip) and
      ((RelationToNonRanger(Ship) < 10) or (Ship = EnemyShip) or (Self = Ship.EnemyShip)) and
      (TruceShip <> Ship) and ((LiberationGroup = nil) or ((LiberationGroup as TGroup).GroupKind <> 0)) then
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        // Native code allows these enemies to replace an earlier target.
        if not ((not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position))) then Continue;
        Weapon.Target := Ship;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
      end;
  end;
  if Player.CurrentStar = CurrentStar then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do begin
      Asteroid := CurrentStar.Asteroids[I];
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance > AsteroidTargetRangeSquared then Continue;
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not ((not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag and
          (Distance <= Weapon.Range * Weapon.Range))) then Continue;
        Weapon.Target := Asteroid;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
        Break;
      end;
    end;
  if CurrentStar.Items.Count > 10 then
    for I := 0 to CurrentStar.Items.Count - 1 do begin
      Item := CurrentStar.Items[I];
      if not (((Item.ItemType = t_Minerals) or (Item.OwnerId = oiKling)) and (Item.ScriptItem = nil)) then Continue;
      if not ((Player.CurrentStar <> CurrentStar) or (GetRelationLevelToShip(Player) <= rlBad) or
        (PointDistance(Player.Position, Item.Position) >= 800) or
        ((NextRandomUnitFloat(RandomState) <= 0.1) and (PointDistance(Player.Position, Item.Position) >= 200))) then Continue;
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Item.Position))) then Continue;
        Weapon.Target := Item;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
        Break;
      end;
    end;
end;
{ @end $4E2B48 }

{ @routine $4E3098 TWarrior_SelectEnemyShipInStar }
procedure TWarrior.SelectEnemyShipInStar;
var I: Integer; Ship: TShip; Chance, BestChance, Time, BestTime: Double;
begin
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then Exit;
  if UsableWeaponCount = 0 then Exit;
  BestChance := -1;
  BestTime := 1;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.InNormalSpace and (RelationToNonRanger(Ship) < 10) and (Ship <> TruceShip) then begin
      if CurrentStar.ShipTypeCounts[t_Kling] > 0 then begin
        if Ship.OwnerId = oiKling then begin
          if ChanceToWin(Ship) > 1 then begin EnemyShip := Ship; Exit; end;
          EnemyShip := Ship;
        end;
      end else if LiberationGroup = nil then begin
        Chance := ChanceToWin(Ship);
        Time := PointDistance(Position, Ship.Position) / Speed + 0.1;
        if Chance / Time > BestChance / BestTime then begin
          EnemyShip := Ship;
          BestChance := Chance;
          BestTime := Time;
        end;
      end;
    end;
  end;
end;
{ @end $4E3098 }

{ @routine $4E31FC TWarrior_EngageEnemyShip }
procedure TWarrior.EngageEnemyShip;
begin
  if Order = soFollowShip then OrderNone;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then begin
    if EnemyShip.InNormalSpace then begin
      OrderFollowShip(EnemyShip, fmMinWeaponRange, False);
      if ChanceToWin(EnemyShip) < 0.8 then RequestAlliesAttackShip(EnemyShip);
    end else if ChanceToWin(EnemyShip) > 0.5 then begin
      if EnemyShip.CurrentPlanet <> nil then OrderMove(EnemyShip.CurrentPlanet.GetPosition, False)
      else if EnemyShip.DockedTo <> nil then OrderMove(EnemyShip.DockedTo.Position, False);
    end;
  end;
end;
{ @end $4E31FC }

{ @routine $4E32D8 TWarrior_ProcessCombatDialogue }
procedure TWarrior.ProcessCombatDialogue;
begin

end;
{ @end $4E32D8 }

{ @routine $4E32DC TWarrior_ReactToExtortionDemand }
procedure TWarrior.ReactToExtortionDemand(Ranger: TObject);
begin
  if (Ranger = Player) or (NextRandomUnitFloat(RandomState) < 0.05) then begin
    HomePlanet.ChangeRelationToRanger(Ranger, -5);
    (Ranger as TRanger).AddPirateCareerActivity(4);
  end;
end;
{ @end $4E32DC }

{ @routine $4E3338 TWarrior_BuildMoneyExtortionResponse }
function TWarrior.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if (OtherShip <> Player) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then EnemyShip := OtherShip;
  Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'No');
end;
{ @end $4E3338 }

{ @routine $4E3430 TWarrior_BuildCargoExtortionResponse }
function TWarrior.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if (OtherShip <> Player) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then EnemyShip := OtherShip;
  Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'No');
end;
{ @end $4E3430 }

{ @routine $4E36EC TWarrior_BuildTrucePaymentResponse }
function TWarrior.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
  // @nested $4E3524 AcceptPayment
  procedure AcceptPayment; // @addr $4E3524
  var I, J: Integer; Ship: TShip; Weapon: TWeapon; Planet: TPlanet;
  begin
    OtherShip.SetMoney(OtherShip.Money - OfferedAmount);
    SetMoney(Money + OfferedAmount);
    TruceWithShip(OtherShip);
    if OtherShip is TRanger then begin
      (OtherShip as TRanger).AddTraderCareerActivity(1);
      Planet := HomePlanet;
      for I := 0 to CurrentStar.Ships.Count - 1 do begin
        Ship := CurrentStar.Ships[I];
        if (Ship is TWarrior) and ((Ship as TWarrior).HomePlanet = Planet) and (Ship <> Self) then begin
          if Ship.EnemyShip = OtherShip then Ship.EnemyShip := nil;
          for J := 1 to Ship.WeaponCount do begin
            Weapon := Ship.Weapons[J - 1];
            if Weapon.Target = OtherShip then Weapon.Target := nil;
          end;
          // The native implementation repeats this clear after the weapon loop.
          if Ship.EnemyShip = OtherShip then Ship.EnemyShip := nil;
          if OtherShip.EnemyShip = Ship then OtherShip.EnemyShip := nil;
          Ship.ChangeRelationToRanger(OtherShip, 30);
          if (Ship.Order = soFollowShip) and ((Ship.OrderTarget as TShip) = OtherShip) then begin
            Ship.OrderNone;
            Ship.NextDay;
          end;
        end;
      end;
    end;
  end;
begin
  Result := False;
  if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact')
  else if Wealth * 0.05 < OfferedAmount then begin
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'Ok');
    AcceptPayment;
    Result := True;
  end else Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'No');
end;
{ @end $4E36EC }

{ @routine $4E3960 TWarrior_BuildAttackRequestResponse }
function TWarrior.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
  // @nested $4E3890 AcceptRequest
  procedure AcceptRequest; // @addr $4E3890
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
    else (Requester as TRanger).AddPirateCareerActivity(8);
  end;
  if (OrderTarget = Target) and (GetRelationLevelToShip(Target) = rlHostile) then AcceptRequest
  else if TruceShip = Target then
    Response := ReplaceColoredToken(LookupVisibleTalkText('Talk.Attack.WeAlreadyHavePact'), '<Target>', Target.GetName, '')
  else if RelationToNonRanger(Target) >= 30 then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriends')
  else if AcceptsRansomDemandFrom(Target) or RecomputeFearState then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Fear')
  else if not TrustsAttackRequester(Requester) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Suspect')
  else if HasLockedOrFollowOrder and (Requester is TNormalShip) and ((Requester as TNormalShip).Rank < Rank) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'HaveBusiness')
  else AcceptRequest;
end;
{ @end $4E3960 }

{ @routine $4E3CFC TWarrior_AcceptPartnershipOffer }
function TWarrior.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $4E3CFC }

{ @routine $4E3D40 TWarrior_BuildPartnershipOfferResponse }
function TWarrior.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $4E3D40 }

{ @routine $4E3D84 TWarrior_TrainSkillsAutomatically }
procedure TWarrior.TrainSkillsAutomatically;
var Attempts: Integer;
begin
  if FreeExperience = 0 then Exit;
  Attempts := 0;
  repeat
    case NextRandomIntRange(0, 100, RandomState) of
      0..19: if TrainSkill(skMobility) then Continue;
      20..39: if TrainSkill(skAccuracy) then Continue;
      40..59: if TrainSkill(skLeadership) then Continue;
      60..89: if TrainSkill(skTechnical) then Continue;
      90..94: if TrainSkill(skTrader) then Continue;
      95..100: if TrainSkill(skCharm) then Continue;
    end;
    Inc(Attempts);
    if FreeExperience < 100 then Break;
  until Attempts >= 40;
end;
{ @end $4E3D84 }

end.

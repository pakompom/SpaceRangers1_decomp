unit ab_ShipAI;
// Unit bracket (inferred): CODE 0x004F7440..0x004F9557; inclusive evidence, not full bounds.

interface

uses GI_Tail, ab_Global, ab_Object, ab_Ship, ab_Zone, ab_Item;

const
  // Native DecideActions ($4F7F50) selects and dispatches these maneuvers.
  amUnselected = -1;
  amApproach = 0;
  amCloseEvasion = 1;
  amFlank = 2;
  amReverseTurn = 3;
  amFollowReverse = 4;

type
  TabShipAI = class(TabShip) // @size $340
  public
    CurrentZone: PabZone; // @offset $298
    InsideCurrentZone: Boolean; // @offset $29C
    CurrentZoneBearing: Double; // @offset $2A0
    CurrentZoneAngularRadius: Double; // @offset $2A8
    HeadingInsideCurrentZone: Boolean; // @offset $2B0
    TargetShip: TabShip; // @offset $2B4
    TargetBearing: TSphericalBearingDistance; // @offset $2B8
    ReverseTargetBearing: TSphericalBearingDistance; // @offset $2C8
    TargetPathClear: Boolean; // @offset $2D8
    RouteZone: PabZone; // @offset $2DC
    RouteBearing: Double; // @offset $2E0
    RouteAngularRadius: Double; // @offset $2E8
    HeadingInsideRoute: Boolean; // @offset $2F0
    DirectPathClear: Boolean; // @offset $2F1
    DirectBearing: TSphericalBearingDistance; // @offset $2F8
    DirectTargetLongitude: Double; // @offset $308
    DirectTargetPolarAngle: Double; // @offset $310
    Intent: Integer; // @offset $318 Native numeric intent; used by scripted/campaign steering.
    CombatManeuver: Integer; // @offset $31C am* selector; negative values request a new choice.
    ManeuverUntilTick: Integer; // @offset $320
    TargetBonus: TabItem; // @offset $324
    BonusRouteZone: PabZone; // @offset $328
    AvoidanceZone: PabZone; // @offset $32C
    DamagingZone: PabZone; // @offset $330
    LastDamageTick: Integer; // @offset $334
    RecentHitCount: Integer; // @offset $338
    IncomingThreat: Boolean; // @offset $33C
    RetreatRequested: Boolean; // @offset $33D
    constructor Create; // @addr $4F74AC
    destructor Destroy; override; // @addr $4F74EC
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override; // @addr $4F752C
    procedure UpdateState; override; // @addr $4F7BE8
    procedure Advance; override; // @addr $4F7C58
    procedure ResetIntent; // @addr $4F7F10
    procedure DecideActions; // @addr $4F7F50
    procedure SetDirectDestination(Longitude, PolarAngle: Single); // @addr $4F8804
    procedure FollowDirectDestination; // @addr $4F88C8
    procedure AvoidImmediateObstacle; // @addr $4F8938
    procedure SetRoute(Target: PabZone); // @addr $4F89AC
    procedure FollowRoute; // @addr $4F89F8
    function TryMoveToDestination(Zone: PabZone; Longitude, PolarAngle: Double): Boolean; // @addr $4F9130
    procedure SetAndFollowRoute(Target: PabZone); // @addr $4F9224
    procedure FollowDestinationRoute; // @addr $4F9284
    procedure ApproachTarget; // @addr $4F8C94
    function ScoreApproach: Integer; // @addr $4F8D48
    procedure EvadeCloseTarget; // @addr $4F8D68
    procedure FlankTarget; // @addr $4F8E18
    function ScoreFlanking: Integer; // @addr $4F8EB4
    procedure ReverseTowardTarget; // @addr $4F8FC0
    function ScoreReverseTurn: Integer; // @addr $4F8FEC
    procedure MatchReversingTarget; // @addr $4F908C
    function ScoreReverseFollowing: Integer; // @addr $4F9094
    procedure NoticeCollision; // @addr $4F7EB8
    procedure NoticeDamagingZone(Zone: PabZone); // @addr $4F7EF0
    procedure ClearRoute; // @addr $4F899C
    function ScoreCloseEvasion: Integer; // @addr $4F8DC0
  end;

procedure AddArcadeRewardToList(Item: TObject); // @addr $4F7514

implementation

// @unit-initialization $4F9550
// @unit-finalization $4F9520

uses Classes, aItem, aShip, aPlayer, aGalaxy, aConst, ab_MainForm, Math, aMyFunction, ab_StopLine, GlobalsV, Globals, ab_Space;

{ @routine $4F74AC TabShipAI_Create }
constructor TabShipAI.Create;
begin
  inherited Create;
  CombatManeuver := amUnselected;
end;
{ @end $4F74AC }

{ @routine $4F74EC TabShipAI_Destroy }
destructor TabShipAI.Destroy;
begin
  inherited Destroy;
end;
{ @end $4F74EC }

{ @routine $4F7514 AddArcadeRewardToList }
procedure AddArcadeRewardToList(Item: TObject);
begin
  ArcadeBattleScreen.ListedObjects.Add(Item);
end;
{ @end $4F7514 }

{ @routine $4F752C TabShipAI_ApplyDamage }
procedure TabShipAI.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
var
  Index: Integer;
  Item: TEquipment;
  Types: TItemTypeMask;
  LivingEnemies: Integer;
  RewardScale: Single;
  MaximumLevel: Integer;
begin
  if Health > 0 then
  begin
    inherited ApplyDamage(Amount, Source, Disrupt);
    LastDamageTick := ArcadeTickCount;
    Inc(RecentHitCount);
    if (Player <> nil) and (Health <= 0) and (PlayerArcadeShip <> nil) and (Enemies.IndexOf(PlayerArcadeShip) >= 0) then
    begin
      LivingEnemies := 0;
      for Index := 0 to PlayerArcadeShip.Enemies.Count - 1 do
        if (TObject(PlayerArcadeShip.Enemies[Index]) is TabShip) and (TabShip(PlayerArcadeShip.Enemies[Index]).Health > 0) then Inc(LivingEnemies);
      RandomState := InitialRandomSeed;
      if Player.Order = soEnterBlackHole then Inc(Player.BlackHoleKillCount)
      else
      begin
        Inc(Player.HyperspaceKillCount);
        Inc(Player.ScriptStatistics[ssShipsKilled]);
        Inc(Player.ScriptStatistics[ssPiratesKilled]);
        Player.AddRankPoints(2);
      end;
      // Drops an artefact after the last hole enemy, then relaxes duplicate/weight limits after retries.
      if (Player.Order = soEnterBlackHole) and (LivingEnemies = 0) and ((Player.BlackHoleKillCount < 20) or (RandomRange(0, 100) > 30)) then
      begin
        Item := nil;
        Index := 0;
        while Item = nil do
        begin
          Inc(Index);
          Item := CreateRandomArtefact(AdvanceRandomSeed(RandomState), oiNone) as TEquipment;
          if Player.HasArtefact(Item.ItemType) and (Index < 100) then
          begin
            Item.Free;
            Item := nil;
            Continue;
          end;
          if (Player.GetBaseCargoHookPower > 0) and (Player.GetBaseCargoHookPower < Item.Weight) and
            (Player.BlackHoleKillCount < 5) and (Index < 1000) then
          begin
            Item.Free;
            Item := nil;
          end
          else Break;
        end;
        ab_Item_Drop(Self, Item, 0, 20);
        AddArcadeRewardToList(Item);
      end
      else if (LivingEnemies = 0) or ((LivingEnemies = 1) and (RandomRange(0, 100) > 50)) or
        ((LivingEnemies >= 2) and (RandomRange(0, 100) > 60)) then
      begin
        Index := 0;
        Types := RewardEquipmentTypes;
        Types := Types + Galaxy.SelectRandomWeaponTypes(RandomRange(Max(1, Galaxy.TechLevel - 2), Galaxy.TechLevel), 4, False, AdvanceRandomSeed(RandomState));
        RewardScale := 1;
        RewardScale := RemapClampedAlternate(LivingEnemies, 0, 5, 1.2, 0.2) * RewardScale;
        if Player.Order = soEnterBlackHole then
        begin
          if LivingEnemies = 0 then RewardScale := RewardScale * 3
          else RewardScale := 1.2 * RewardScale;
        end
        else RewardScale := RemapClamped(CurrentArcadeSpace.Danger + CurrentArcadeSpace.ApproachDanger, 50, 250, 0.7, 2) * RewardScale;
        RewardScale := RewardScale * DifficultyModifiers[Galaxy.Difficulty].StartingMoneyFactor;
        MaximumLevel := Round(RemapClamped(Galaxy.TechLevel, 3, 8, 3, 5));
        while True do
        begin
          Item := Player.CreateRandomEquipment(Types, False, TStandardCount(RandomRange(2, MaximumLevel)), RandomRange(1, MaximumLevel), oiNone, RandomRange(1, 100000));
          Item.ConditionPercent := SeededRandomFloatRange(Item.Id, 10, 100);
          // Generation inserts into the hold; remove it before creating the arcade drop.
          Player.Inventory.Delete(Player.Inventory.IndexOf(Item));
          Player.RefreshDerivedStats;
          Inc(Index);
          if Index > 10000 then
          begin
            ab_Item_Drop(Self, Item, 0, 20);
            AddArcadeRewardToList(Item);
            Break;
          end;
          if (Player.GetBaseCargoHookPower > 0) and (Player.GetBaseCargoHookPower < Item.Weight) and
            (Player.BlackHoleKillCount + Player.HyperspaceKillCount < 17) then
          begin
            Item.Free;
            Continue;
          end;
          if (Item.GetConditionAdjustedCost < Max(800, Player.Wealth * RemapClamped(Index, 0, 500, 0.01 * RewardScale, 0.03 * RewardScale))) and
            ((Item.GetConditionAdjustedCost > Player.Wealth * 0.008 * RewardScale) or (Index > 500)) and
            (Item.GetConditionAdjustedCost < 10000 * RewardScale) then
          begin
            ab_Item_Drop(Self, Item, 0, 20);
            AddArcadeRewardToList(Item);
            Break;
          end;
          Item.Free;
        end;
      end;
    end
    else if Source <> nil then
      if (Source <> TargetShip) and (Source is TabShip) and (Enemies.IndexOf(Source) >= 0) then
        if (TargetShip = nil) or (DistanceTo(TargetShip) > MaximumWeaponRange) then TargetShip := Source as TabShip;
  end;
end;
{ @end $4F752C }

{ @routine $4F7BE8 TabShipAI_UpdateState }
procedure TabShipAI.UpdateState;
begin
  inherited UpdateState;
  InsideCurrentZone := ab_Zone_FindContainingOrNearest(State.LongitudeDegrees, State.PolarAngleDegrees, CurrentZone);
  HeadingInsideCurrentZone := False;
  CurrentZoneBearing := 0;
  if CurrentZone <> nil then
    if not InsideCurrentZone then
      HeadingInsideCurrentZone := ab_Zone_IsHeadingInside(State, CurrentZone, CurrentZoneBearing, CurrentZoneAngularRadius);
end;
{ @end $4F7BE8 }

{ @routine $4F7C58 TabShipAI_Advance }
procedure TabShipAI.Advance;
var
  ForwardDistance, BackwardDistance: Double;
  Attempt, Index: Integer;
begin
  inherited Advance;
  if Health > 0 then
  begin
    if (ArcadeTickCount and 31) = 0 then RecentHitCount := 0;
    if (PlayerArcadeShip <> Self) or ArcadeAutopilotEnabled then
    begin
      if (WeaponCount > 1) and ((ArcadeTickCount and 31) = 0) and
        (Weapons[PrimaryWeapon].Ammo < Weapons[PrimaryWeapon].MaxAmmo / 4) then
        for Attempt := 0 to WeaponCount - 2 do
        begin
          Index := RandomRange(0, WeaponCount - 1);
          if (Weapons[Index].Ammo > Weapons[Index].MaxAmmo * 0.9) or
            (((Weapons[Index].Kind = 13) or (Weapons[Index].Kind = 14)) and
            (Weapons[Index].Ammo > Weapons[Index].MaxAmmo * 0.7)) then
          begin
            SelectWeapon(Index);
            Break;
          end;
        end;
      if (TargetShip <> nil) and (Enemies.IndexOf(TargetShip) < 0) then TargetShip := nil;
      if (TargetShip <> nil) and (TargetShip.Health <= 0) then TargetShip := nil;
      if (TargetShip <> nil) and (TargetShip.BonusTicks[abkInvisibility] > 0) and (TargetShip.RevealTicks <= 0) then TargetShip := nil;
      if TargetShip = nil then TargetShip := FindNearestEnemy(Self);
      if TargetShip <> nil then
      begin
        TargetBearing := BearingAndDistanceTo(TargetShip);
        ReverseTargetBearing := TargetShip.BearingAndDistanceTo(Self);
      end;
      TargetPathClear := False;
      if TargetShip <> nil then
      begin
        ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees,
          WrapHeadingDegrees(State.BearingDegrees + TargetBearing.BearingDeltaDegrees)), ForwardDistance, BackwardDistance);
        TargetPathClear := TargetBearing.Distance < ForwardDistance;
      end;
      DecideActions;
    end;
  end;
end;
{ @end $4F7C58 }

{ @routine $4F7EB8 TabShipAI_NoticeCollision }
procedure TabShipAI.NoticeCollision;
begin
  if (PlayerArcadeShip = Self) or (CurrentZone = nil) then
  begin
    AvoidanceZone := nil;
    Exit;
  end;
  AvoidanceZone := ab_Zone_RandomRoute(CurrentZone, 2);
end;
{ @end $4F7EB8 }

{ @routine $4F7EF0 TabShipAI_NoticeDamagingZone }
procedure TabShipAI.NoticeDamagingZone(Zone: PabZone);
begin
  if RandomIntRange(0, 10) = 0 then DamagingZone := Zone;
end;
{ @end $4F7EF0 }

{ @routine $4F7F10 TabShipAI_ResetIntent }
procedure TabShipAI.ResetIntent;
begin
  Intent := 0;
  TargetShip := nil;
  TargetBonus := nil;
  BonusRouteZone := nil;
  AvoidanceZone := nil;
  DamagingZone := nil;
  LastDamageTick := 0;
  RetreatRequested := False;
end;
{ @end $4F7F10 }

{ @routine $4F7F50 TabShipAI_DecideActions }
procedure TabShipAI.DecideActions;
var
  Index, Score, BestScore: Integer;
  Enemy: TabObject;
  Bonus: TabItem;
  Zone: PabZone;
  Obj: TabObject;
  NearestDistance: Double;
  Info, ZoneInfo: TSphericalBearingDistance;
begin
  DirectPathClear := False;
  IncomingThreat := False;
  if PlayerArcadeShip = Self then
  begin
    NearestDistance := 1E30;
    for Index := 0 to Enemies.Count - 1 do
    begin
      Enemy := TabObject(Enemies[Index]);
      Info := Enemy.BearingAndDistanceTo(Self);
      with Info do
      begin
        NearestDistance := Min(NearestDistance, Distance);
        if (Enemy <> TargetShip) and (Abs(BearingDeltaDegrees) < 5) and (Distance < 400) then IncomingThreat := True;
      end;
    end;
  end;
  ClearRoute;
  if TargetShip <> nil then SetRoute((TargetShip as TabShipAI).CurrentZone);
  FollowDirectDestination;
  if TargetPathClear then
  begin
    if ArcadeTickCount > ManeuverUntilTick then CombatManeuver := amUnselected;
    if (CombatManeuver = amApproach) and (ScoreApproach < 0) then CombatManeuver := amUnselected;
    if (CombatManeuver = amCloseEvasion) and (ScoreCloseEvasion < 0) then CombatManeuver := amUnselected;
    if (CombatManeuver = amFlank) and (ScoreFlanking < 0) then CombatManeuver := amUnselected;
    if (CombatManeuver = amReverseTurn) and (ScoreReverseTurn < 0) then CombatManeuver := amUnselected;
    if (CombatManeuver = amFollowReverse) and (ScoreReverseFollowing < 0) then CombatManeuver := amUnselected;
    if CombatManeuver < 0 then
    begin
      BestScore := 0;
      Score := ScoreApproach;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amApproach;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreCloseEvasion;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amCloseEvasion;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreFlanking;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amFlank;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreReverseTurn;
      if Score > BestScore then
      begin
        BestScore := Score;
        CombatManeuver := amReverseTurn;
        ManeuverUntilTick := ArcadeTickCount + 100;
      end;
      Score := ScoreReverseFollowing;
      if Score > BestScore then
      begin
        CombatManeuver := amFollowReverse;
        ManeuverUntilTick := ArcadeTickCount + 500;
      end;
    end;
    if CombatManeuver = amApproach then ApproachTarget
    else if CombatManeuver = amCloseEvasion then EvadeCloseTarget
    else if CombatManeuver = amFlank then FlankTarget
    else if CombatManeuver = amReverseTurn then ReverseTowardTarget
    else if CombatManeuver = amFollowReverse then MatchReversingTarget;
  end
  else
  begin
    CombatManeuver := amUnselected;
    ManeuverUntilTick := 0;
    FollowRoute;
  end;
  if (AvoidanceZone = nil) and (ArcadeTickCount - LastDamageTick < 100) and
    ((RandomIntRange(0, 120) = 0) or
     ((BonusTicks[abkWeaponLock] > 0) and (RandomIntRange(0, 20) = 0)) or
     ((TargetShip = nil) and (RandomIntRange(0, 20) = 0)) or
     ((PlayerArcadeShip = Self) and (Health < MaxHealth * 0.3) and (RandomIntRange(0, 20) = 0))) then
    AvoidanceZone := ab_Zone_RandomRoute(CurrentZone, 2);
  if (AvoidanceZone <> nil) and
    ((AvoidanceZone = CurrentZone) or IncomingThreat or (RandomIntRange(0, 100) = 0) or (RecentHitCount >= 3) or
     not TryMoveToDestination(AvoidanceZone, AvoidanceZone.Longitude, AvoidanceZone.PolarAngle)) then AvoidanceZone := nil;
  if RetreatRequested and (RandomIntRange(0, 50) = 0) then
  begin
    repeat
      Zone := ab_Zone_RandomRoute(CurrentZone, RandomIntRange(3, 4));
    until Zone <> AvoidanceZone;
    AvoidanceZone := Zone;
  end;
  if (TargetBonus = nil) and not RetreatRequested and
    (((TargetShip = nil) and (RandomIntRange(0, 20) = 0)) or
     ((BonusTicks[abkWeaponLock] > 0) and (RandomIntRange(0, 20) = 0)) or
     ((PlayerArcadeShip <> Self) and (RandomIntRange(0, 500) = 0)) or
     ((Health < MaxHealth * 0.4) and (RandomIntRange(0, 80) = 0))) then
  begin
    if PlayerArcadeShip = Self then
    begin
      TargetBonus := ab_Item_FindRepairRoute(CurrentZone, BonusRouteZone);
      if TargetBonus = nil then TargetBonus := ab_Item_FindBonusRoute(CurrentZone, BonusRouteZone);
    end
    else
    begin
      TargetBonus := ab_Item_FindBonusRoute(CurrentZone, BonusRouteZone);
      if TargetBonus <> nil then
      begin
        Obj := FirstArcadeObject;
        while Obj <> nil do
        begin
          if (Obj <> Self) and (Obj is TabShipAI) and (TabShipAI(Obj).TargetBonus = TargetBonus) then
          begin
            TargetBonus := nil;
            Break;
          end;
          Obj := Obj.Next;
        end;
      end;
    end;
  end;
  if (TargetBonus <> nil) and
    ((RecentHitCount >= 3) or (IncomingThreat and (RandomIntRange(0, 50) = 0)) or
     not TryMoveToDestination(BonusRouteZone, TargetBonus.State.LongitudeDegrees, TargetBonus.State.PolarAngleDegrees)) then TargetBonus := nil;
  if RouteZone <> nil then
  begin
    Bonus := ab_Item_FindNearestBonus(RouteZone);
    if Bonus <> nil then
      with BearingAndDistanceTo(Bonus) do
        if Abs(BearingDeltaDegrees) < 75 then
        begin
          SetDirectDestination(Bonus.State.LongitudeDegrees, Bonus.State.PolarAngleDegrees);
          FollowDirectDestination;
        end;
  end;
  if DamagingZone <> nil then
  begin
    ComputeSphericalBearingAndDistance(State.LongitudeDegrees, State.PolarAngleDegrees,
      State.BearingDegrees, DamagingZone.Longitude, DamagingZone.PolarAngle, SphereRadius, ZoneInfo.BearingDeltaDegrees, ZoneInfo.Distance);
    if Abs(ZoneInfo.BearingDeltaDegrees) < 90 then StopThrust else StartThrust;
    if ZoneInfo.Distance > (DamagingZone.Radius + ZoneRadius) * 1.4 then DamagingZone := nil
    else SetTurnInput(-ZoneInfo.BearingDeltaDegrees);
  end;
  AvoidImmediateObstacle;
  for Index := 0 to Enemies.Count - 1 do
  begin
    Enemy := TabObject(Enemies[Index]);
    Info := BearingAndDistanceTo(Enemy);
    with Info do
    begin
      if PrimaryWeapon >= 0 then
      begin
        if Weapons[PrimaryWeapon].Kind = 13 then FirePrimary
        else if Weapons[PrimaryWeapon].Kind = 14 then FirePrimaryAt(Enemy)
        else if Weapons[PrimaryWeapon].Kind = 12 then FirePrimaryAt(Enemy)
        else if Abs(BearingDeltaDegrees) < 5 then
          if not (Weapons[PrimaryWeapon].Kind in [1, 2, 6, 8]) or (Thrust <= 1.25) or (Abs(TurnInput) >= 0.01) then FirePrimaryAt(Enemy);
      end;
      if SecondaryWeapon >= 0 then
      begin
        if Weapons[SecondaryWeapon].Kind = 13 then FireSecondary
        else if Weapons[SecondaryWeapon].Kind = 14 then FireSecondaryAt(Enemy)
        else if Weapons[SecondaryWeapon].Kind = 12 then FireSecondaryAt(Enemy)
        else if Abs(BearingDeltaDegrees) < 5 then
          if not (Weapons[SecondaryWeapon].Kind in [1, 2, 6, 8]) or (Thrust <= 1.25) or (Abs(TurnInput) >= 0.01) then FireSecondaryAt(Enemy);
      end;
    end;
  end;
end;
{ @end $4F7F50 }

{ @routine $4F8804 TabShipAI_SetDirectDestination }
procedure TabShipAI.SetDirectDestination(Longitude, PolarAngle: Single);
var
  ForwardDistance, BackwardDistance: Double;
begin
  DirectTargetLongitude := Longitude;
  DirectTargetPolarAngle := PolarAngle;
  DirectPathClear := False;
  ComputeSphericalBearingAndDistance(State.LongitudeDegrees, State.PolarAngleDegrees, State.BearingDegrees,
    DirectTargetLongitude, DirectTargetPolarAngle, SphereRadius, DirectBearing.BearingDeltaDegrees, DirectBearing.Distance);
  ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees,
    WrapHeadingDegrees(State.BearingDegrees + DirectBearing.BearingDeltaDegrees)), ForwardDistance, BackwardDistance);
  DirectPathClear := DirectBearing.Distance < ForwardDistance;
end;
{ @end $4F8804 }

{ @routine $4F88C8 TabShipAI_FollowDirectDestination }
procedure TabShipAI.FollowDirectDestination;
begin
  if DirectPathClear then
  begin
    SetTurnInput(DirectBearing.BearingDeltaDegrees);
    if Abs(DirectBearing.BearingDeltaDegrees) < 45 then
      Thrust := RemapClampedAlternate(Abs(DirectBearing.BearingDeltaDegrees), 0, 45, 2.5, 0)
    else StopThrust;
  end;
end;
{ @end $4F88C8 }

{ @routine $4F8938 TabShipAI_AvoidImmediateObstacle }
procedure TabShipAI.AvoidImmediateObstacle;
begin
  if (Thrust > 0) and ((ObstacleLevels[0] >= 3) or (ObstacleLevels[1] >= 3) or (ObstacleLevels[7] >= 3)) then
  begin
    if ObstacleLevels[1] < ObstacleLevels[7] then SetTurnInput(100)
    else if ObstacleLevels[7] < ObstacleLevels[1] then SetTurnInput(-100);
  end;
end;
{ @end $4F8938 }

{ @routine $4F899C TabShipAI_ClearRoute }
procedure TabShipAI.ClearRoute;
begin
  RouteZone := nil;
  HeadingInsideRoute := False;
end;
{ @end $4F899C }

{ @routine $4F89AC TabShipAI_SetRoute }
procedure TabShipAI.SetRoute(Target: PabZone);
begin
  RouteZone := ab_Zone_GetRoute(CurrentZone, Target);
  HeadingInsideRoute := False;
  if RouteZone <> nil then
    HeadingInsideRoute := ab_Zone_IsHeadingInside(State, RouteZone, RouteBearing, RouteAngularRadius);
end;
{ @end $4F89AC }

{ @routine $4F89F8 TabShipAI_FollowRoute }
procedure TabShipAI.FollowRoute;
begin
  if RouteZone <> nil then
  begin
    if HeadingInsideRoute and (RouteZone <> nil) then
    begin
      StartThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then SetTurnInput(0)
      else if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if (RouteZone <> nil) and not ab_StopLine_IsBlocked(State.LongitudeDegrees,
      State.PolarAngleDegrees, RouteZone.Longitude, RouteZone.PolarAngle) then
    begin
      if RouteBearing < 45 then StartThrust else StopThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then SetTurnInput(0)
      else if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if not InsideCurrentZone then
    begin
      if HeadingInsideCurrentZone then
      begin
        StartThrust;
        if Abs(CurrentZoneBearing) < CurrentZoneAngularRadius / 2 then SetTurnInput(0)
        else if CurrentZoneBearing < 0 then SetTurnInput(-100)
        else if CurrentZoneBearing > 0 then SetTurnInput(100);
        Exit;
      end;
      if CurrentZoneBearing < 0 then SetTurnInput(-100)
      else if CurrentZoneBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if RouteZone <> nil then
    begin
      if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
    end;
  end;
end;
{ @end $4F89F8 }

{ @routine $4F8C94 TabShipAI_ApproachTarget }
procedure TabShipAI.ApproachTarget;
begin
  CombatManeuver := amApproach;
  SetTurnInput(TargetBearing.BearingDeltaDegrees);
  if MinimumWeaponRange * 0.8 < TargetBearing.Distance then
  begin
    Thrust := RemapClampedAlternate(Abs(TargetBearing.BearingDeltaDegrees), 0, 180, 2.5, 0);
    Thrust := RemapClamped(TargetBearing.Distance, 100, 1000, 0.5, 1) * Thrust;
    Exit;
  end;
  StartReverseThrust;
end;
{ @end $4F8C94 }

{ @routine $4F8D48 TabShipAI_ScoreApproach }
function TabShipAI.ScoreApproach: Integer;
begin
  Result := 1;
  Inc(Result, RandomRange(-1, 1));
end;
{ @end $4F8D48 }

{ @routine $4F8D68 TabShipAI_EvadeCloseTarget }
procedure TabShipAI.EvadeCloseTarget;
begin
  CombatManeuver := amCloseEvasion;
  if Abs(ReverseTargetBearing.BearingDeltaDegrees) < 20 then SetTurnInput(-TargetBearing.BearingDeltaDegrees)
  else SetTurnInput(TargetBearing.BearingDeltaDegrees);
  StartReverseThrust;
end;
{ @end $4F8D68 }

{ @routine $4F8DC0 TabShipAI_ScoreCloseEvasion }
function TabShipAI.ScoreCloseEvasion: Integer;
begin
  Result := 0;
  if (TargetBearing.Distance < 200) and (Abs(TargetBearing.BearingDeltaDegrees) < 40) then
  begin
    Inc(Result);
    Inc(Result);
  end
  else if Abs(TargetBearing.BearingDeltaDegrees) > 90 then Result := -1;
end;
{ @end $4F8DC0 }

{ @routine $4F8E18 TabShipAI_FlankTarget }
procedure TabShipAI.FlankTarget;
begin
  CombatManeuver := amFlank;
  if TargetBearing.BearingDeltaDegrees > 0 then SetTurnInput(TargetBearing.BearingDeltaDegrees - 65)
  else SetTurnInput(TargetBearing.BearingDeltaDegrees + 65);
  StartThrust;
  Thrust := RemapClamped(TargetBearing.Distance, 100, 1000, 0.5, 1) * Thrust;
end;
{ @end $4F8E18 }

{ @routine $4F8EB4 TabShipAI_ScoreFlanking }
function TabShipAI.ScoreFlanking: Integer;
begin
  Result := RandomRange(0, 2);
  if (Abs(ReverseTargetBearing.BearingDeltaDegrees) < 30) and (TargetBearing.Distance < 500) then
  begin
    Inc(Result);
    if Abs(TargetBearing.BearingDeltaDegrees) > Abs(ReverseTargetBearing.BearingDeltaDegrees) then Inc(Result);
    if (PlayerArcadeShip = Self) and (Health < Round(MaxHealth * 0.4)) then Inc(Result);
    if IncomingThreat then Inc(Result);
    Inc(Result, RandomRange(-1, 1));
  end;
  if TargetBearing.Distance > 500 then Dec(Result);
  if Health > MaxHealth * 0.7 then Dec(Result, 2);
end;
{ @end $4F8EB4 }

{ @routine $4F8FC0 TabShipAI_ReverseTowardTarget }
procedure TabShipAI.ReverseTowardTarget;
begin
  CombatManeuver := amReverseTurn;
  SetTurnInput(TargetBearing.BearingDeltaDegrees);
  StartReverseThrust;
end;
{ @end $4F8FC0 }

{ @routine $4F8FEC TabShipAI_ScoreReverseTurn }
function TabShipAI.ScoreReverseTurn: Integer;
begin
  Result := 0;
  if (Abs(TargetBearing.BearingDeltaDegrees) > 120) and
    ((ObstacleLevels[3] = 0) or (ObstacleLevels[4] = 0) or (ObstacleLevels[5] = 0)) then
  begin
    Inc(Result, 3);
    if (PlayerArcadeShip = Self) and (Health < Round(MaxHealth * 0.4)) then Inc(Result);
    Inc(Result, RandomRange(-2, 2));
  end
  else Result := -1;
end;
{ @end $4F8FEC }

{ @routine $4F908C TabShipAI_MatchReversingTarget }
procedure TabShipAI.MatchReversingTarget;
begin
  StartReverseThrust;
end;
{ @end $4F908C }

{ @routine $4F9094 TabShipAI_ScoreReverseFollowing }
function TabShipAI.ScoreReverseFollowing: Integer;
begin
  Result := 0;
  if (Abs(TargetBearing.BearingDeltaDegrees) < 20) and (Abs(ReverseTargetBearing.BearingDeltaDegrees) < 30)
    and (ObstacleLevels[4] <= 1) and (TargetShip.Thrust < 0) then
  begin
    Inc(Result, 2);
    if MaximumWeaponRange * 0.7 < TargetBearing.Distance then Inc(Result, 2);
    Inc(Result, RandomRange(-1, 1));
  end
  else Result := -1;
end;
{ @end $4F9094 }

{ @routine $4F9130 TabShipAI_TryMoveToDestination }
function TabShipAI.TryMoveToDestination(Zone: PabZone; Longitude, PolarAngle: Double): Boolean;
var
  ForwardDistance, BackwardDistance, Distance, Bearing: Double;
begin
  SetAndFollowRoute(Zone);
  ComputeSphericalBearingAndDistance(State.LongitudeDegrees,
    State.PolarAngleDegrees, State.BearingDegrees, Longitude, PolarAngle, SphereRadius, Bearing, Distance);
  ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees,
    WrapHeadingDegrees(State.BearingDegrees + Bearing)), ForwardDistance, BackwardDistance);
  if Distance >= ForwardDistance then Result := RouteZone <> nil
  else
  begin
    SetTurnInput(Bearing);
    if Abs(Bearing) < 45 then Thrust := RemapClampedAlternate(Abs(Bearing), 0, 45, 2.5, 0)
    else StopThrust;
    Result := True;
  end;
end;
{ @end $4F9130 }

{ @routine $4F9224 TabShipAI_SetAndFollowRoute }
procedure TabShipAI.SetAndFollowRoute(Target: PabZone);
begin
  if Target = nil then RouteZone := nil
  else RouteZone := ab_Zone_GetRoute(CurrentZone, Target);
  HeadingInsideRoute := False;
  if RouteZone <> nil then
    HeadingInsideRoute := ab_Zone_IsHeadingInside(State, RouteZone, RouteBearing, RouteAngularRadius);
  FollowDestinationRoute;
end;
{ @end $4F9224 }

{ @routine $4F9284 TabShipAI_FollowDestinationRoute }
procedure TabShipAI.FollowDestinationRoute;
begin
  if RouteZone <> nil then
  begin
    if HeadingInsideRoute and (RouteZone <> nil) then
    begin
      StartThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then SetTurnInput(0)
      else if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if (RouteZone <> nil) and not ab_StopLine_IsBlocked(State.LongitudeDegrees,
      State.PolarAngleDegrees, RouteZone.Longitude, RouteZone.PolarAngle) then
    begin
      if RouteBearing < 45 then StartThrust else StopThrust;
      if Abs(RouteBearing) < RouteAngularRadius / 2 then SetTurnInput(0)
      else if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if not InsideCurrentZone then
    begin
      if HeadingInsideCurrentZone then
      begin
        StartThrust;
        if Abs(CurrentZoneBearing) < CurrentZoneAngularRadius / 2 then SetTurnInput(0)
        else if CurrentZoneBearing < 0 then SetTurnInput(-100)
        else if CurrentZoneBearing > 0 then SetTurnInput(100);
        Exit;
      end;
      if CurrentZoneBearing < 0 then SetTurnInput(-100)
      else if CurrentZoneBearing > 0 then SetTurnInput(100);
      Exit;
    end;
    if RouteZone <> nil then
    begin
      if RouteBearing < 0 then SetTurnInput(-100)
      else if RouteBearing > 0 then SetTurnInput(100);
    end;
  end;
end;
{ @end $4F9284 }

end.

unit ab_Ship;
// Unit bracket (inferred): CODE 0x004F9CDC..0x004FBA83; inclusive evidence, not full bounds.

interface

uses Classes, GI_MessageLoop, GI_Tail, ab_Global, SE_Space, SE_Ship2, ab_Object, ab_Hit, ab_W;

type
  TabShip = class(TabHit) // @size $294
  public
    Visual: TShip2SE; // @offset $B0
    VisualDiameter: Integer; // @offset $B4
    OffscreenMarker: TObjectSE; // @offset $B8
    OffscreenLabel: TObjectGI; // @offset $BC
    Enemies: TList; // @offset $C0
    InitialEnemies: TList; // @offset $C4
    TurnSpeed: Double; // @offset $C8
    TurnInput: Double; // @offset $D0
    WeaponCount: Integer; // @offset $D8
    Weapons: array[0..4] of TabWeapon; // @offset $E0
    PrimaryWeapon: Integer; // @offset $1D0
    SecondaryWeapon: Integer; // @offset $1D4
    LastPrimaryWeapon: Integer; // @offset $1D8
    LastPrimaryFireTick: Integer; // @offset $1DC
    LastSecondaryWeapon: Integer; // @offset $1E0
    LastSecondaryFireTick: Integer; // @offset $1E4
    BonusTicks: array[0..7] of Integer; // @offset $1E8  Repair, speed, slow, weapon lock, damage, recharge, shield, invisibility.
    RevealTicks: Integer; // @offset $208
    OuterAvoidanceDistance: Double; // @offset $210
    MiddleAvoidanceDistance: Double; // @offset $218
    InnerAvoidanceDistance: Double; // @offset $220
    NextObstacleScanTick: Integer; // @offset $228
    ObstacleDistances: array[0..7] of Double; // @offset $230
    ObstacleLevels: array[0..7] of Integer; // @offset $270
    EncounterTag: Integer; // @offset $290
    constructor Create; // @addr $4F9D44
    destructor Destroy; override; // @addr $4F9DD8
    procedure CreateShipVisual(const GraphKey: WideString; Diameter: Integer); // @addr $4FA020
    procedure DetachVisual; // @addr $4FA13C
    procedure AttachVisual; // @addr $4FA11C
    function FindNearestEnemy(Origin: TabObject): TabShip; // @addr $4FA1A8
    function FindNearestEnemyWithBearing(Origin: TabObject; var Bearing: TSphericalBearingDistance): TabShip; // @addr $4FA248
    procedure SetTurnInput(Value: Double); // @addr $4FA358
    procedure StartThrust; // @addr $4FA374
    procedure StopThrust; // @addr $4FA384
    procedure StartReverseThrust; // @addr $4FA390
    function PrimaryWeaponSwitchReady(Index: Integer): Boolean; // @addr $4FA3B0
    function SecondaryWeaponSwitchReady(Index: Integer): Boolean; // @addr $4FA3E8
    procedure SelectWeapon(Index: Integer); // @addr $4FA83C
    procedure AddWeapon(Kind: Integer); // @addr $4FA994
    procedure UpdateAvoidanceDistances; // @addr $4FB5D8
    procedure UpdateObstacleSensors; // @addr $4FB6C0
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override; // @addr $4FA2FC
    procedure UpdateState; override; // @addr $4FA9C0
    procedure Advance; override; // @addr $4FAB70
    procedure UpdateVisuals; override; // @addr $4FAC5C
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $4FA150
    function MinimumWeaponRange: Double; // @addr $4FA8E8
    function MaximumWeaponRange: Double; // @addr $4FA940
    function CanFireWeapon(Index: Integer): Boolean; // @addr $4FA898
    procedure Brake; // @addr $4FA3A0
    procedure FirePrimary; // @addr $4FA420
    procedure FireSecondary; // @addr $4FA5E0
    procedure FirePrimaryAt(Target: TabObject); // @addr $4FA7AC
    procedure FireSecondaryAt(Target: TabObject); // @addr $4FA7F4
  end;

procedure ab_Ship_RepelOverlaps; // @addr $4FB86C

var
  PlayerArcadeShip: TabShip = nil; // @addr $6186DC
  BossArcadeShip: TabShip = nil; // @addr $6186E0
  AlliedArcadeFlagship: TabShip = nil; // @addr $6186E4

var
  ArcadeRoutePlaying: Boolean; // @addr $61CF10
  ArcadeTransitionShiftHeld: Boolean; // @addr $61CF11

implementation

// @unit-initialization $4FBA7C
// @unit-finalization $4FBA4C

uses abWall, ab_ShipAI, Math, EC_Struct, aMyFunction, GR_Main, GlobalsV, SE_Process, Globals, ab_StopLine, ab_Zone, Types, ab_MainForm;

{ @routine $4F9D44 TabShip_Create }
constructor TabShip.Create;
begin
  inherited Create;
  TurnSpeedScale := 1;
  DisruptUntilTick := 0;
  Health := 200;
  MaxHealth := 200;
  TurnSpeed := 2;
  WallCollisionEnabled := True;
  GravityEnabled := True;
  ZoneDamageEnabled := True;
  Enemies := TList.Create;
end;
{ @end $4F9D44 }

{ @routine $4F9DD8 TabShip_Destroy }
destructor TabShip.Destroy;
var
  Obj: TabObject;
  Ship: TabShip;
  Index, Count: Integer;
begin
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj is TabShip then
    begin
      Ship := Obj as TabShip;
      if Ship.Enemies <> nil then
      begin
        while True do
        begin
          Index := Ship.Enemies.IndexOf(Self);
          if Index < 0 then Break;
          Ship.Enemies.Delete(Index);
        end;
      end;
      if (Ship is TabShipAI) and ((Ship as TabShipAI).TargetShip = Self) then
        (Ship as TabShipAI).TargetShip := nil;
    end;
    Obj := Obj.Next;
  end;
  if Self = PlayerArcadeShip then PlayerArcadeShip := nil;
  if Self = BossArcadeShip then BossArcadeShip := nil;
  if Self = AlliedArcadeFlagship then AlliedArcadeFlagship := nil;
  if PlayerArcadeShip <> nil then
  begin
    Index := 0;
    Count := PlayerArcadeShip.Enemies.Count;
    while Index < Count do
    begin
      if TObject(PlayerArcadeShip.Enemies[Index]) is TabShipAI then Break;
      Inc(Index);
    end;
    if Index >= Count then
    begin
      PlayerArcadeShip.StopThrust;
      PlayerArcadeShip.SetTurnInput(0);
      ArcadeAutopilotEnabled := False;
      ArcadeBattleScreen.AutoButton.SetDown(ArcadeAutopilotEnabled);
      ArcadeEnemiesDefeated := True;
      Obj := FirstArcadeObject;
      while Obj <> nil do
      begin
        if (Obj is TabWall) and (TabWall(Obj).Health > 0) then
          TabWall(Obj).Health := Min(20, TabWall(Obj).Health);
        Obj := Obj.Next;
      end;
      if not ArcadeFinalEncounter then ArcadeBattleScreen.ShowVictory;
    end;
  end;
  if Visual <> nil then
  begin
    Visual.Free;
    Visual := nil;
  end;
  if OffscreenMarker <> nil then
  begin
    OffscreenMarker.Free;
    OffscreenMarker := nil;
  end;
  if OffscreenLabel <> nil then
  begin
    OffscreenLabel.Free;
    OffscreenLabel := nil;
  end;
  if Enemies <> nil then
  begin
    Enemies.Free;
    Enemies := nil;
  end;
  inherited Destroy;
end;
{ @end $4F9DD8 }

{ @routine $4FA020 TabShip_CreateShipVisual }
procedure TabShip.CreateShipVisual(const GraphKey: WideString; Diameter: Integer);
begin
  Visual := CreateSpaceObjectByName('Ship2', GraphKey, Classes.Point(0, 0)) as TShip2SE;
  Visual.TailEmitIntervalMs := 10;
  Visual.SetAlpha(255);
  Visual.SetTailsActive((Self = PlayerArcadeShip) and (ShipTail <> 0));
  VisualDiameter := Diameter;
  EffectOriginSpread := GiScalePixels(VisualDiameter);
  Mass := 10;
  State.PolarAngleDegrees := 0;
  State.BearingDegrees := 0;
  CollisionRadius := Diameter / 2 * 1.1;
  ZoneRadius := 0.9 * CollisionRadius;
end;
{ @end $4FA020 }

{ @routine $4FA11C TabShip_AttachVisual }
procedure TabShip.AttachVisual;
begin
  if Visual <> nil then Visual.AttachToSpace(ArcadeSpaceProcess.Space);
end;
{ @end $4FA11C }

{ @routine $4FA13C TabShip_DetachVisual }
procedure TabShip.DetachVisual;
begin
  if Visual <> nil then Visual.DetachFromSpace;
end;
{ @end $4FA13C }

{ @routine $4FA150 TabShip_QueueImageLoad }
procedure TabShip.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Index: Integer;
begin
  if Visual <> nil then Visual.QueueImageLoad(PendingLoads, Owner);
  for Index := 0 to WeaponCount - 1 do
    ab_Weapon_QueueImageLoad(@Weapons[Index], PendingLoads, Owner);
end;
{ @end $4FA150 }

{ @routine $4FA1A8 TabShip_FindNearestEnemy }
function TabShip.FindNearestEnemy(Origin: TabObject): TabShip;
var
  Index: Integer;
  Ship: TabShip;
  BestDistance, Distance: Double;
begin
  Result := nil;
  BestDistance := 1e20;
  for Index := 0 to Enemies.Count - 1 do
  begin
    Ship := Enemies[Index];
    if (Ship.Health >= 1) and ((Ship.BonusTicks[abkInvisibility] <= 0) or (Ship.RevealTicks > 0)) then
    begin
      Distance := Origin.DistanceTo(Ship);
      if Distance < BestDistance then
      begin
        BestDistance := Distance;
        Result := Ship;
      end;
    end;
  end;
end;
{ @end $4FA1A8 }

{ @routine $4FA248 TabShip_FindNearestEnemyWithBearing }
function TabShip.FindNearestEnemyWithBearing(Origin: TabObject; var Bearing: TSphericalBearingDistance): TabShip;
var
  Index: Integer;
  Ship: TabShip;
  BestDistance: Double;
  CandidateBearing: TSphericalBearingDistance;
begin
  Result := nil;
  BestDistance := 1e20;
  for Index := 0 to Enemies.Count - 1 do
  begin
    Ship := Enemies[Index];
    if (Ship.Health >= 1) and ((Ship.BonusTicks[abkInvisibility] <= 0) or (Ship.RevealTicks > 0)) then
    begin
      CandidateBearing := Origin.BearingAndDistanceTo(Ship);
      if CandidateBearing.Distance < BestDistance then
      begin
        BestDistance := CandidateBearing.Distance;
        Bearing := CandidateBearing;
        Result := Ship;
      end;
    end;
  end;
end;
{ @end $4FA248 }

{ @routine $4FA2FC TabShip_ApplyDamage }
procedure TabShip.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
begin
  if Health > 0 then
    if BonusTicks[abkShield] > 0 then
      inherited ApplyDamage(Round(Amount * ShieldDamageScale), Source, Disrupt)
    else
      inherited ApplyDamage(Amount, Source, Disrupt);
end;
{ @end $4FA2FC }

{ @routine $4FA358 TabShip_SetTurnInput }
procedure TabShip.SetTurnInput(Value: Double);
begin
  TurnInput := Value;
end;
{ @end $4FA358 }

{ @routine $4FA374 TabShip_StartThrust }
procedure TabShip.StartThrust;
begin
  Thrust := 2.5;
end;
{ @end $4FA374 }

{ @routine $4FA384 TabShip_StopThrust }
procedure TabShip.StopThrust;
begin
  Thrust := 0;
end;
{ @end $4FA384 }

{ @routine $4FA390 TabShip_StartReverseThrust }
procedure TabShip.StartReverseThrust;
begin
  Thrust := -1.8;
end;
{ @end $4FA390 }

{ @routine $4FA3A0 TabShip_Brake }
procedure TabShip.Brake;
begin
  ChangeSpeed(-1);
end;
{ @end $4FA3A0 }

{ @routine $4FA3B0 TabShip_PrimaryWeaponSwitchReady }
function TabShip.PrimaryWeaponSwitchReady(Index: Integer): Boolean;
begin
  Result := (Index = LastPrimaryWeapon) or (WeaponSwitchDelayMs div 20 <= ArcadeTickCount - LastPrimaryFireTick);
end;
{ @end $4FA3B0 }

{ @routine $4FA3E8 TabShip_SecondaryWeaponSwitchReady }
function TabShip.SecondaryWeaponSwitchReady(Index: Integer): Boolean;
begin
  Result := (Index = LastSecondaryWeapon) or (WeaponSwitchDelayMs div 20 <= ArcadeTickCount - LastSecondaryFireTick);
end;
{ @end $4FA3E8 }

{ @routine $4FA420 TabShip_FirePrimary }
procedure TabShip.FirePrimary;
var
  Score, BestScore, Index, Candidate, BestWeapon: Integer;
begin
  if (Health > 0) and (WeaponCount > 0) and (BonusTicks[abkWeaponLock] <= 0) then
    if (Self <> PlayerArcadeShip) or (LastPrimaryWeapon = PrimaryWeapon) or
      (WeaponSwitchDelayMs div 20 <= ArcadeTickCount - LastPrimaryFireTick) then
      if CanFireWeapon(PrimaryWeapon) then
      begin
        if BonusTicks[abkInvisibility] > 0 then RevealTicks := RevealAfterFiringMs div 20;
        LastPrimaryWeapon := PrimaryWeapon;
        LastPrimaryFireTick := ArcadeTickCount;
        Weapons[PrimaryWeapon].LastFireTick := ArcadeTickCount;
          Dec(Weapons[PrimaryWeapon].Ammo, Weapons[PrimaryWeapon].AmmoCost);
        ab_Weapon_Fire(@Weapons[PrimaryWeapon], Self, BonusTicks[abkDamage] > 0);
        if Weapons[PrimaryWeapon].Ammo < Weapons[PrimaryWeapon].AmmoCost then
          begin
            BestScore := -1;
            BestWeapon := -1;
            Candidate := PrimaryWeapon;
            for Index := 0 to WeaponCount - 1 do
            begin
              if Weapons[Candidate].SlotData and $80 = 0 then
              begin
                Score := Round(Weapons[Candidate].Ammo / Weapons[Candidate].MaxAmmo * 100);
                if CanFireWeapon(Candidate) then Inc(Score, 100);
                if Score > BestScore then
                begin
                  BestScore := Score;
                  BestWeapon := Candidate;
                end;
              end;
              Inc(Candidate);
              if Candidate >= WeaponCount then Candidate := 0;
            end;
            if BestWeapon >= 0 then PrimaryWeapon := BestWeapon;
          end;
      end;
end;
{ @end $4FA420 }

{ @routine $4FA5E0 TabShip_FireSecondary }
procedure TabShip.FireSecondary;
var
  Score, BestScore, Index, Candidate, BestWeapon: Integer;
begin
  if (Health > 0) and (WeaponCount > 0) and (BonusTicks[abkWeaponLock] <= 0) then
    if (Self <> PlayerArcadeShip) or (LastSecondaryWeapon = SecondaryWeapon) or
      (WeaponSwitchDelayMs div 20 <= ArcadeTickCount - LastSecondaryFireTick) then
      if CanFireWeapon(SecondaryWeapon) then
      begin
        if BonusTicks[abkInvisibility] > 0 then RevealTicks := RevealAfterFiringMs div 20;
        LastSecondaryWeapon := SecondaryWeapon;
        LastSecondaryFireTick := ArcadeTickCount;
        Weapons[SecondaryWeapon].LastFireTick := ArcadeTickCount;
          Dec(Weapons[SecondaryWeapon].Ammo, Weapons[SecondaryWeapon].AmmoCost);
        ab_Weapon_Fire(@Weapons[SecondaryWeapon], Self, BonusTicks[abkDamage] > 0);
        if Self = PlayerArcadeShip then
          if Weapons[SecondaryWeapon].Ammo < Weapons[SecondaryWeapon].AmmoCost then
        begin
          BestScore := -1;
          BestWeapon := -1;
          Candidate := SecondaryWeapon;
          for Index := 0 to WeaponCount - 1 do
          begin
            if Weapons[Candidate].SlotData and $80 <> 0 then
            begin
              Score := Round(Weapons[Candidate].Ammo / Weapons[Candidate].MaxAmmo * 100);
              if CanFireWeapon(Candidate) then Inc(Score, 100);
              if Score > BestScore then
              begin
                BestScore := Score;
                BestWeapon := Candidate;
              end;
            end;
            Inc(Candidate);
            if Candidate >= WeaponCount then Candidate := 0;
          end;
          if BestWeapon >= 0 then SecondaryWeapon := BestWeapon;
        end;
      end;
end;
{ @end $4FA5E0 }

{ @routine $4FA7AC TabShip_FirePrimaryAt }
procedure TabShip.FirePrimaryAt(Target: TabObject);
var
  Distance: Double;
begin
  if (Health > 0) and (BonusTicks[abkWeaponLock] <= 0) then
  begin
    Distance := DistanceTo(Target);
    if Distance <= Weapons[PrimaryWeapon].Range then FirePrimary;
  end;
end;
{ @end $4FA7AC }

{ @routine $4FA7F4 TabShip_FireSecondaryAt }
procedure TabShip.FireSecondaryAt(Target: TabObject);
var
  Distance: Double;
begin
  if (Health > 0) and (BonusTicks[abkWeaponLock] <= 0) then
  begin
    Distance := DistanceTo(Target);
    if Distance <= Weapons[SecondaryWeapon].Range then FireSecondary;
  end;
end;
{ @end $4FA7F4 }

{ @routine $4FA83C TabShip_SelectWeapon }
procedure TabShip.SelectWeapon(Index: Integer);
begin
  if Self = PlayerArcadeShip then
  begin
    if Index < 0 then
    begin
      PrimaryWeapon := -1;
      SecondaryWeapon := -1;
      Exit;
    end;
    if Index < WeaponCount then
    begin
      if Weapons[Index].SlotData and $80 = 0 then PrimaryWeapon := Index
      else SecondaryWeapon := Index;
    end;
  end
  else if PrimaryWeapon <> Index then PrimaryWeapon := Index;
end;
{ @end $4FA83C }

{ @routine $4FA898 TabShip_CanFireWeapon }
function TabShip.CanFireWeapon(Index: Integer): Boolean;
begin
  Result := False;
  if BonusTicks[abkWeaponLock] > 0 then Exit;
  if Index < 0 then Exit;
  if Index >= WeaponCount then Exit;
  if Weapons[Index].AmmoCost > Weapons[Index].Ammo then Exit;
  Result := ArcadeTickCount - Weapons[Index].LastFireTick >= Weapons[Index].FireIntervalTicks;
end;
{ @end $4FA898 }

{ @routine $4FA8E8 TabShip_MinimumWeaponRange }
function TabShip.MinimumWeaponRange: Double;
var
  Index: Integer;
begin
  Result := 1e20;
  for Index := 0 to WeaponCount - 1 do Result := Min(Result, Weapons[Index].Range);
end;
{ @end $4FA8E8 }

{ @routine $4FA940 TabShip_MaximumWeaponRange }
function TabShip.MaximumWeaponRange: Double;
var
  Index: Integer;
begin
  Result := 0;
  for Index := 0 to WeaponCount - 1 do Result := Max(Result, Weapons[Index].Range);
end;
{ @end $4FA940 }

{ @routine $4FA994 TabShip_AddWeapon }
procedure TabShip.AddWeapon(Kind: Integer);
begin
  if WeaponCount < 5 then
  begin
    ab_Weapon_Initialize(@Weapons[WeaponCount], TItemType(Kind + Ord(t_PhotonGun)));
    Inc(WeaponCount);
  end;
end;
{ @end $4FA994 }

{ @routine $4FA9C0 TabShip_UpdateState }
procedure TabShip.UpdateState;
var
  Turn: Double;
  Index: Integer;
begin
  if BonusTicks[abkRecharge] > 0 then
  begin
    for Index := 0 to WeaponCount - 1 do
      Weapons[Index].Ammo := Min(Weapons[Index].Ammo + Round(Weapons[Index].RechargePerTick * AmmoRechargeBonusScale), Weapons[Index].MaxAmmo);
  end
  else
  begin
    for Index := 0 to WeaponCount - 1 do
      Weapons[Index].Ammo := Min(Weapons[Index].Ammo + Weapons[Index].RechargePerTick, Weapons[Index].MaxAmmo);
  end;
  if TurnInput <> 0 then
  begin
    Turn := TurnInput;
    if -TurnSpeed * TurnSpeedScale > Turn then Turn := -TurnSpeed * TurnSpeedScale
    else if TurnSpeed * TurnSpeedScale < Turn then Turn := TurnSpeed * TurnSpeedScale;
    State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Turn);
  end;
  inherited UpdateState;
  if BonusTicks[abkSpeed] > 0 then SpeedScale := SpeedScale * SpeedBonusScale;
  if BonusTicks[abkSlow] > 0 then SpeedScale := SpeedScale * SpeedPenaltyScale;
  if BonusTicks[abkSpeed] > 0 then TurnSpeedScale := TurnSpeedScale * SpeedBonusScale;
  if BonusTicks[abkSlow] > 0 then TurnSpeedScale := TurnSpeedScale * SpeedPenaltyScale;
end;
{ @end $4FA9C0 }

{ @routine $4FAB70 TabShip_Advance }
procedure TabShip.Advance;
var
  Index: Integer;
  Zone: PabZone;
begin
  inherited Advance;
  if Health = 0 then
  begin
    Velocity := MakePointF(0, 0);
    Thrust := 0;
  end
  else
  begin
    for Index := Low(BonusTicks) to High(BonusTicks) do
      if BonusTicks[Index] > 0 then Dec(BonusTicks[Index]);
    if BonusTicks[abkRegeneration] > 0 then Health := Min(MaxHealth, Health + RegenerationHealthPerTick);
    if (BonusTicks[abkInvisibility] > 0) and (RevealTicks > 0) then Dec(RevealTicks);
  end;
  UpdateObstacleSensors;
  if ArcadeTickCount and $40 = 0 then
    if ab_Zone_IsInsideKind10(State.LongitudeDegrees, State.PolarAngleDegrees) then
      begin
        Zone := ab_Zone_FindNearestOutside(State.LongitudeDegrees, State.PolarAngleDegrees);
        if Zone <> nil then
        begin
          State.LongitudeDegrees := Zone.Longitude;
          State.PolarAngleDegrees := Zone.PolarAngle;
        end;
      end;
end;
{ @end $4FAB70 }

{ @routine $4FAC5C TabShip_UpdateVisuals }
procedure TabShip.UpdateVisuals;
var
  ViewSize: TPoint;
  HorizonAlpha: Double;
  Alpha: Integer;
  InvisibilityAlpha: Single;
  Position: TVector3D;
  Bearing: TSphericalBearingDistance;
  VisualObject: TObjectSE;
begin
  inherited UpdateVisuals;
  Position := GetWorldPosition;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
  VisualObject := Visual;
  if (VisualObject <> nil) and VisualObject.IsAttachedToSpace then
  begin
    if (Position.Z <= SphereHorizonDepth) and (Position.Z > SphereFarHorizonDepth) then
      HorizonAlpha := (SphereHorizonDepth - Position.Z) / (SphereHorizonDepth - SphereFarHorizonDepth)
    else if (Position.Z > SphereHorizonDepth) and (Position.Z < SphereNearHorizonDepth) then
      HorizonAlpha := (SphereHorizonDepth - Position.Z) / (SphereHorizonDepth - SphereNearHorizonDepth)
    else HorizonAlpha := 1;
    Visual.SetPosition(MakePointF(Position.X, Position.Y));
    if Health > 0 then
    begin
      if (BonusTicks[abkInvisibility] > 0) and (RevealTicks <= 0) then
      begin
        if Self <> PlayerArcadeShip then InvisibilityAlpha := OtherInvisibleAlpha
        else InvisibilityAlpha := PlayerInvisibleAlpha;
      end
      else InvisibilityAlpha := 1;
      if not IsDepthBeforeSphereHorizon(Position.Z) then
      begin
        Alpha := Round(128 * InvisibilityAlpha * HorizonAlpha);
        if Visual.Size.X <> EffectOriginSpread div 2 then
        begin
          Visual.DetachFromSpace;
          Visual.SetSize(Classes.Point(EffectOriginSpread div 2, EffectOriginSpread div 2));
          Visual.AttachToSpace(ArcadeSpaceProcess.Space);
        end;
        Visual.SetDepth(ShipBackDepth);
      end
      else
      begin
        Alpha := Round(255 * InvisibilityAlpha * HorizonAlpha);
        if Visual.Size.X <> EffectOriginSpread then
        begin
          Visual.DetachFromSpace;
          Visual.SetSize(Classes.Point(EffectOriginSpread, EffectOriginSpread));
          Visual.AttachToSpace(ArcadeSpaceProcess.Space);
        end;
        Visual.SetDepth(ShipFrontDepth);
      end;
    end
    else
    begin
        Alpha := Max(0, Visual.GetAlpha - 10);
        if Visual.GetAlpha < 10 then Visual.DetachFromSpace;
    end;
    if (ArcadeViewMode = avmToMap) or (ArcadeViewMode = avmToSpace) then
      Alpha := Round(RemapClamped(SphereCameraDistance, SphereRadius + SphereNearCameraOffset,
        (SphereRadius + SphereFarCameraOffset) / 3, Alpha, 0));
    Visual.SetAlpha(Alpha);
  end;
  begin
    Visual.SetAngle(HeadingDegreesToByte(GetProjectedHeading(Position)));
    Visual.OffsetTailsAlongHeading(RandomIntRange(0, 1) * 0.3 + 2);
    Visual.SetTailsEmitting(Thrust <> 0);
    if (Visual.GetAngle >= 254) or (Visual.GetAngle <= 2) then Visual.SetAngle(0);
  end;
  if PlayerArcadeShip <> nil then
    if OffscreenMarker <> nil then
    begin
      Position := PlayerArcadeShip.GetWorldPosition;
      Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
      Bearing := PlayerArcadeShip.BearingAndDistanceTo(Self);
      Bearing.BearingDeltaDegrees := WrapHeadingDegrees(PlayerArcadeShip.GetProjectedHeading(Position) + Bearing.BearingDeltaDegrees);
      if Bearing.BearingDeltaDegrees > 180 then Bearing.BearingDeltaDegrees := Bearing.BearingDeltaDegrees - 360;
      ViewSize := ArcadeBattleScreen.WorldPanel.ClientSize;
      if (Bearing.BearingDeltaDegrees >= 0) and (Bearing.BearingDeltaDegrees <= 45) then
        OffscreenMarker.SetPosition(MakePointF((ViewSize.X / 2 - 30) * (Bearing.BearingDeltaDegrees / 45), -(ViewSize.Y div 2) + 30))
      else if (Bearing.BearingDeltaDegrees >= -45) and (Bearing.BearingDeltaDegrees < 0) then
        OffscreenMarker.SetPosition(MakePointF((ViewSize.X / 2 - 30) * (Bearing.BearingDeltaDegrees / 45), -(ViewSize.Y div 2) + 30))
      else if Bearing.BearingDeltaDegrees >= 135 then
        OffscreenMarker.SetPosition(MakePointF((180 - Bearing.BearingDeltaDegrees) / 45 * (ViewSize.X / 2 - 30), ViewSize.Y div 2 - 30))
      else if Bearing.BearingDeltaDegrees <= -135 then
        OffscreenMarker.SetPosition(MakePointF(-(180 + Bearing.BearingDeltaDegrees) / 45 * (ViewSize.X / 2 - 30), ViewSize.Y div 2 - 30))
      else if (Bearing.BearingDeltaDegrees >= 45) and (Bearing.BearingDeltaDegrees <= 90) then
        OffscreenMarker.SetPosition(MakePointF(ViewSize.X div 2 - 30, (ViewSize.Y / 2 - 30) * ((Bearing.BearingDeltaDegrees - 90) / 45)))
      else if (Bearing.BearingDeltaDegrees >= 90) and (Bearing.BearingDeltaDegrees <= 135) then
        OffscreenMarker.SetPosition(MakePointF(ViewSize.X div 2 - 30, (ViewSize.Y / 2 - 30) * ((Bearing.BearingDeltaDegrees - 90) / 45)))
      else if (Bearing.BearingDeltaDegrees <= -45) and (Bearing.BearingDeltaDegrees >= -90) then
        OffscreenMarker.SetPosition(MakePointF(-(ViewSize.X div 2) + 30, (-Bearing.BearingDeltaDegrees - 45 + -45) / 45 * (ViewSize.Y / 2 - 30)))
      else if (Bearing.BearingDeltaDegrees <= -90) and (Bearing.BearingDeltaDegrees >= -135) then
        OffscreenMarker.SetPosition(MakePointF(-(ViewSize.X div 2) + 30, (ViewSize.Y / 2 - 30) * ((-Bearing.BearingDeltaDegrees - 90) / 45)))
      else OffscreenMarker.SetPosition(MakePointF(100, 100));
      OffscreenLabel.SetPosition(TruncatePointF(OffscreenMarker.Position));
      Bearing := BearingAndDistanceTo(PlayerArcadeShip);
      if PointDistanceSquared(OffscreenMarker.Position, Visual.Position) < 0.001 then OffscreenMarker.SetAngle(0)
      else OffscreenMarker.SetAngle(HeadingDegreesToByte(WrapHeadingDegrees(PointBearingDegrees(OffscreenMarker.Position, Visual.Position) - Bearing.BearingDeltaDegrees)));
    end;
end;
{ @end $4FAC5C }

{ @routine $4FB5D8 TabShip_UpdateAvoidanceDistances }
procedure TabShip.UpdateAvoidanceDistances;
begin
  if TurnSpeed = 0 then
  begin
    OuterAvoidanceDistance := 30;
    MiddleAvoidanceDistance := 30;
    InnerAvoidanceDistance := 30;
    Exit;
  end;
  OuterAvoidanceDistance := 180 / (TurnSpeed * TurnSpeedScale) * (5 * MaxSpeed) / Pi * 2;
  MiddleAvoidanceDistance := 180 / (TurnSpeed * TurnSpeedScale) * (5 * MaxSpeed / 4) / Pi * 2;
  InnerAvoidanceDistance := 60;
end;
{ @end $4FB5D8 }

{ @routine $4FB6C0 TabShip_UpdateObstacleSensors }
procedure TabShip.UpdateObstacleSensors;
var
  Index: Integer;
begin
  if ArcadeTickCount >= NextObstacleScanTick then
  begin
    NextObstacleScanTick := ArcadeTickCount + 4;
    UpdateAvoidanceDistances;
    ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, State.BearingDegrees), ObstacleDistances[0], ObstacleDistances[4]);
    ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, WrapHeadingDegrees(State.BearingDegrees + 45)), ObstacleDistances[1], ObstacleDistances[5]);
    ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, WrapHeadingDegrees(State.BearingDegrees + 90)), ObstacleDistances[2], ObstacleDistances[6]);
    ab_StopLine_GetDistances(MakeSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, WrapHeadingDegrees(State.BearingDegrees + 90 + 45)), ObstacleDistances[3], ObstacleDistances[7]);
    for Index := 0 to 7 do
      if ObstacleDistances[Index] > OuterAvoidanceDistance then ObstacleLevels[Index] := 0
      else if ObstacleDistances[Index] > MiddleAvoidanceDistance then ObstacleLevels[Index] := 1
      else if ObstacleDistances[Index] > InnerAvoidanceDistance then ObstacleLevels[Index] := 2
      else ObstacleLevels[Index] := 3;
  end;
end;
{ @end $4FB6C0 }

{ @routine $4FB86C ab_Ship_RepelOverlaps }
procedure ab_Ship_RepelOverlaps;
var
  Obj, Other: TabObject;
  Bearing, Distance, Speed: Double;
begin
  if (ArcadeTickCount and 1) <> 0 then Exit;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if (Obj is TabHit) and (TabHit(Obj).Health > 0) and not (Obj is TabWall) then
    begin
      Other := FirstArcadeObject;
      while Other <> nil do
      begin
        if (Obj <> Other) and (Other is TabHit) and (TabHit(Other).Health > 0)
          and ((not (Other is TabWall)) or (Other.ZoneRadius > 1)) then
        begin
          ComputeSphericalBearingAndDistance(Obj.State.LongitudeDegrees, Obj.State.PolarAngleDegrees, 0,
            Other.State.LongitudeDegrees, Other.State.PolarAngleDegrees, SphereRadius, Bearing, Distance);
          if (Obj.ZoneRadius + Other.ZoneRadius > Distance) and (Distance > 0) then
          begin
            Speed := Max(1, Sqrt(Sqr(Obj.Velocity.X) + Sqr(Obj.Velocity.Y)) / 2);
            Bearing := HeadingDegreesToRadians(WrapHeadingDegrees(Bearing + 180));
            Obj.Velocity.X := Sin(Bearing) * Speed;
            Obj.Velocity.Y := -Cos(Bearing) * Speed;
            if Obj is TabShipAI then (Obj as TabShipAI).NoticeCollision;
          end;
        end;
        Other := Other.Next;
      end;
    end;
    Obj := Obj.Next;
  end;
end;
{ @end $4FB86C }

end.

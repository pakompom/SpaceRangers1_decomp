unit ab_Hit;
// Unit bracket (inferred): CODE 0x0050A17C..0x0050AB5F; inclusive evidence, not full bounds.

interface

uses Classes, GI_MessageLoop, ab_Object;

type
  TabHit = class(TabObject) // @size $AC
  public
    Health: Integer; // @offset $90
    MaxHealth: Integer; // @offset $94
    DisruptUntilTick: Integer; // @offset $98
    EffectOriginSpread: Integer; // @offset $9C
    TurnSpeedScale: Double; // @offset $A0
    Effects: TList; // @offset $A8

    constructor Create; // @addr $50A1E4
    destructor Destroy; override; // @addr $50A248
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override; // @addr $50A2B0
    procedure UpdateState; override; // @addr $50A98C
    procedure Advance; override; // @addr $50AA10
    procedure UpdateVisuals; override; // @addr $50AA4C
    procedure ExplosionComplete(Sender: TObjectGI); // @addr $50AAE4
  end;

implementation

// @unit-initialization $50AB58
// @unit-finalization $50AB28

uses SysUtils, abWall, ab_MainForm, aPlayer, aMyFunction, Globals, GR_Main, Math, EC_Struct, ab_Global, ab_Ship, GlobalsV, GI_GAI;

{ @routine $50A1E4 TabHit_Create }
constructor TabHit.Create;
begin
  inherited Create;
  DisruptUntilTick := 0;
  Health := 200;
  MaxHealth := 200;
  Effects := TList.Create;
end;
{ @end $50A1E4 }

{ @routine $50A248 TabHit_Destroy }
destructor TabHit.Destroy;
var
  Index: Integer;
  Effect: TObject;
begin
  if Effects <> nil then
  begin
    for Index := 0 to Effects.Count - 1 do
    begin
      Effect := Effects[Index];
      Effect.Free;
    end;
    Effects.Free;
    Effects := nil;
  end;
  inherited Destroy;
end;
{ @end $50A248 }

{ @routine $50A2B0 TabHit_ApplyDamage }
procedure TabHit.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
var
  Effect: TgaiGI;
begin
  if Health > 0 then
  begin
    if (AlliedArcadeFlagship <> nil) and (BossArcadeShip = Self) then
    begin
      Amount := Amount div 4;
      if Health < MaxHealth div 5 then Amount := 0;
    end;
    if (BossArcadeShip = Self) and ((PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0)) then Amount := 0;
    if (PlayerArcadeShip = Self) and (Player <> nil) then
    begin
      if ArcadeAutopilotEnabled then Amount := Round(Amount * 0.7);
      if AlliedArcadeFlagship <> nil then
        Amount := Round(RemapClamped(Player.BlackHoleKillCount + Player.HyperspaceKillCount, 20, 150, 0.1, 1) * Amount)
      else if BossArcadeShip <> nil then
        Amount := Round(RemapClamped(Player.BlackHoleKillCount + Player.HyperspaceKillCount, 20, 100, 0.3, 1) * Amount);
    end;
    if Disrupt then
    begin
      if ArcadeTickCount < DisruptUntilTick then
      begin
        Inc(DisruptUntilTick, Amount);
        if (PlayerArcadeShip = Self) and (DisruptUntilTick - ArcadeTickCount > 350) then
          DisruptUntilTick := ArcadeTickCount + 350;
      end
      else DisruptUntilTick := ArcadeTickCount + Amount;
      Health := Max(0, Health - 2);
    end
    else Health := Max(0, Health - Amount);
    if (AlliedArcadeFlagship <> nil) and (BossArcadeShip = Self) and (Health <= 0) then Health := 100;
    if Health <= 0 then
    begin
      if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
      begin
        Effect := TgaiGI.Create(ArcadeBattleScreen.WorldPanel);
        Effects.Add(Effect);
        if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
        begin
          if (BossArcadeShip = Self) or (AlliedArcadeFlagship = Self) then
            Effect.SetImagePath('Bm.Weapon.ExplM')
          else Effect.SetImagePath('Bm.Weapon.Expl' + IntToStr(RandomIntRange(0, 1)));
          Effect.SetDepth(ExplosionFrontDepth);
        end
        else
        begin
          Effect.SetImagePath('Bm.AB.expl0_s');
          Effect.SetDepth(ExplosionBackDepth);
        end;
        Effect.SequenceIndex := 0;
        Effect.UpdateAutoGeometry;
        Effect.SetSize(Effect.GetContentSize);
        Effect.SetOrigin(HalfPoint(Effect.ClientSize));
        Effect.CycleCompleteCallback := ExplosionComplete;
        Effect.RestartPlayback;
        Effect.SetActive(True);
        if Self is TabWall then
        begin
          if RandomIntRange(0, 1) = 0 then SoundManager.PlaySound('Sound.ab_Expl0')
          else SoundManager.PlaySound('Sound.ab_Expl1');
        end
        else SoundManager.PlaySound(ArcadeExplosionSounds[RandomIntRange(0, High(ArcadeExplosionSounds))]);
      end
      else DeletionPending := True;
    end
    else
    begin
      if ((Source <> nil) and (Effects.Count < 5)) or (Effects.Count < 1) then
      begin
        Effect := TgaiGI.Create(ArcadeBattleScreen.WorldPanel);
        Effects.Add(Effect);
        if IsDepthBeforeSphereHorizon(GetProjectedPosition.Z) then
        begin
          Effect.SetImagePath('Bm.AB.hit00_f');
          Effect.SetDepth(HitFrontDepth);
        end
        else
        begin
          Effect.SetImagePath('Bm.AB.hit00_s');
          Effect.SetDepth(HitBackDepth);
        end;
        Effect.SequenceIndex := 0;
        Effect.UpdateAutoGeometry;
        Effect.SetSize(Effect.GetContentSize);
        Effect.SetOrigin(Classes.Point(Effect.ClientSize.X div 2 + RandomIntRange(-EffectOriginSpread div 4, EffectOriginSpread div 4),
          Effect.ClientSize.Y div 2 + RandomIntRange(-EffectOriginSpread div 4, EffectOriginSpread div 4)));
        Effect.CycleCompleteCallback := ExplosionComplete;
        Effect.RestartPlayback;
        Effect.SetActive(True);
        if PlayerArcadeShip = Self then SoundManager.PlaySound(ArcadeHitSounds[RandomIntRange(0, High(ArcadeHitSounds))]);
      end;
    end;
  end;
end;
{ @end $50A2B0 }

{ @routine $50A98C TabHit_UpdateState }
procedure TabHit.UpdateState;
begin
  if ArcadeTickCount < DisruptUntilTick then
  begin
    if PlayerArcadeShip = Self then
    begin
      SpeedScale := 0.7;
      TurnSpeedScale := 0.6;
    end
    else
    begin
      SpeedScale := 0.5;
      TurnSpeedScale := 0.4;
    end;
  end
  else
  begin
    SpeedScale := 1;
    TurnSpeedScale := 1;
  end;
  inherited UpdateState;
end;
{ @end $50A98C }

{ @routine $50AA10 TabHit_Advance }
procedure TabHit.Advance;
begin
  inherited Advance;
  if Health = 0 then
  begin
    Velocity := MakePointF(0, 0);
    Thrust := 0;
  end;
end;
{ @end $50AA10 }

{ @routine $50AA4C TabHit_UpdateVisuals }
procedure TabHit.UpdateVisuals;
var
  Effect: TObjectGI;
  Index: Integer;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  Position := GetWorldPosition;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
  for Index := 0 to Effects.Count - 1 do
  begin
    Effect := Effects[Index];
    Effect.SetPosition(Classes.Point(Round(Position.X), Round(Position.Y)));
  end;
end;
{ @end $50AA4C }

{ @routine $50AAE4 TabHit_ExplosionComplete }
procedure TabHit.ExplosionComplete(Sender: TObjectGI);
begin
  Effects.Delete(Effects.IndexOf(Sender));
  Sender.Free;
  if Effects.Count <= 0 then
    if Health <= 0 then DeletionPending := True;
end;
{ @end $50AAE4 }

end.

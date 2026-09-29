unit SE_Weapon;
// Unit bracket (inferred): CODE 0x00561A70..0x0056434B; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, EC_Struct, GI_GAI, GI_Label, GI_MessageLoop, GI_PSWeapon, SE_Space, Types;

type
  PWeaponEffectItem = ^TWeaponEffectItem;
  TWeaponEffectItem = record // @size $2C
    Next: PWeaponEffectItem; // @offset $00
    Prev: PWeaponEffectItem; // @offset $04
    Image: TgaiGI; // @offset $08
    Position: TPointF; // @offset $0C  Y is the evolving radial distance; X starts at zero.
    Angle: Single; // @offset $14
    Lifetime: Integer; // @offset $18
    Speed: Single; // @offset $1C
    Acceleration: Single; // @offset $20
    AtTarget: Boolean; // @offset $24
    AutoAnimation: Boolean; // @offset $25
    LoopAnimation: Boolean; // @offset $26
    SkipTime: Integer; // @offset $28
  end;

  TWeaponEffect = class(TObject) // @size $40
  public
    Owner: TObjectGI; // @offset $04
    FirstItem: PWeaponEffectItem; // @offset $08
    LastItem: PWeaponEffectItem; // @offset $0C
    EffectIndex: Integer; // @offset $10
    DepthExpression: WideString; // @offset $14
    SourcePoint: TPointF; // @offset $18
    TargetPoint: TPointF; // @offset $20
    Started: Boolean; // @offset $28
    LeftTime: Integer; // @offset $2C
    Direction: Single; // @offset $30
    AnimationInterval: Integer; // @offset $34
    AnimationCountdown: Integer; // @offset $38
    BeforeEnd: Boolean; // @offset $3C

    constructor Create(AEffectIndex: Integer; AOwner: TObjectGI); // @addr $56347C
    destructor Destroy; override; // @addr $5635FC
    procedure Clear; // @addr $56361C
    function AddItem: PWeaponEffectItem; // @addr $563634
    procedure RemoveItem(Item: PWeaponEffectItem); // @addr $5636A0
    procedure AddTargetEffect(Index: Integer); // @addr $5636F8
    procedure AddSourceEffect(Index: Integer); // @addr $563B0C
    procedure Start; // @addr $563F20
    procedure Advance; // @addr $56406C
    procedure AnimationComplete(Sender: TObjectGI); // @addr $5641A4
    function IsFinished: Boolean; // @addr $5641B0
    procedure SetSourcePoint(Point: TPointF); // @addr $5641BC
    procedure SetTargetPoint(Point: TPointF); // @addr $564268
  end;

  TWeaponSE = class(TObjectSE) // @size $BC
  public
    ShotSoundPath: WideString; // @offset $48
    HitSoundPath: WideString; // @offset $4C
    PlayShotSound: Boolean; // @offset $50
    SourceObject: TObjectSE; // @offset $54
    TargetObject: TObjectSE; // @offset $58
    HitDamage: Integer; // @offset $5C
    TargetDestroyed: Boolean; // @offset $60
    DestructionEffect: Integer; // @offset $64
    DestructionFrameInterval: Integer; // @offset $68
    DestructionDetachStep: Integer; // @offset $6C
    HitColor: Integer; // @offset $70
    SourceAnimation: TgaiGI; // @offset $74
    SourceAnimationInterval: Integer; // @offset $78
    TargetAnimation: TgaiGI; // @offset $7C
    TargetAnimationInterval: Integer; // @offset $80
    HitEffect: TWeaponEffect; // @offset $84
    HitVariant: Integer; // @offset $88
    Projectile: TPSWeaponGI; // @offset $94
    DestructionAnimation: TgaiGI; // @offset $98
    DamageLabel: TLabelGI; // @offset $9C
    ImmediateDestruction: Boolean; // @offset $A0
    DestructionAlpha: Single; // @offset $A4
    DestructionAlphaStep: Single; // @offset $A8
    DamageLabelPoint: TPointF; // @offset $AC
    ProjectileFinished: Boolean; // @offset $B5
    StepIndex: Integer; // @offset $B8
    destructor Destroy; override; // @addr $561BA8
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $561BD0
    procedure DetachFromSpace; override; // @addr $562C90
    procedure SetHit(Color, Damage: Integer; Destroyed, PlaySound: Boolean); // @addr $562D38
    procedure SetEndpoints(Source, Target: TObjectSE); // @addr $562D54
    function GetTargetPoint: TPointF; // @addr $562D5C
    function GetSourcePoint: TPointF; // @addr $562DD4
    procedure Advance; override; // @addr $562DF8
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $5633AC
  end;

implementation

// @unit-initialization $564344
// @unit-finalization $564314

uses Classes, Math, SysUtils, EC_Str, aMyFunction, GI_Main, GR_Main, GlobalsV, Globals, GR_Sound, SE_Ship2, SE_Ruins, GI_avi, GI_PSRay, GI_PSRay2, GI_PSRocket, GI_PSLaser, GI_HeavyLaser, GI_LaserCannonRay, GI_Lightning, GI_PSEyes, GI_PSWind, GI_PSSubmesonicCannon, GI_PSDefibrillator, GI_PSPhaser, GI_PSWeapon01, GI_PSWeapon02, GI_PSWeapon06, GI_PSWeapon08, GI_PSWeapon09, GI_PSWeapon13;

{ @routine $561BA8 TWeaponSE_Destroy }
destructor TWeaponSE.Destroy;
begin
  inherited Destroy;
end;
{ @end $561BA8 }

{ @routine $561BD0 TWeaponSE_AttachToSpace }
procedure TWeaponSE.AttachToSpace(ASpace: TSpaceSE);
var HasDestruction: Boolean;
    WeaponConfig: TBlockParEC;
    I: Integer;
begin
  inherited AttachToSpace(ASpace);
  HasDestruction := False;
  ImmediateDestruction := False;
  ProjectileFinished := False;
  WeaponConfig := GameDataConfig.GetBlock('Weapon');
  HitVariant := Random(ExtractDigitsToIntW(WeaponConfig.GetParam('HitCount'))) + 1;
  I := ExtractDigitsToIntW(GraphKey);
  if GraphKey = 'Weapon.Star' then Projectile := nil
  else if GraphKey = 'Weapon.NoGraph' then Projectile := nil
  else if GraphKey = 'Weapon.Asteroid' then
  begin
    Projectile := nil;
    SourceAnimation := TgaiGI.Create(Space.MapPanel);
    SourceAnimation.SetImagePath('Bm.Asteroid.Des');
    SourceAnimation.SetSize(SourceAnimation.GetContentSize);
    SourceAnimation.SetOrigin(HalfPoint(SourceAnimation.ClientSize));
    SourceAnimation.SetDepthByName('Weapon');
    SourceAnimation.SetPositionModeW(True);
    SourceAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(SourceAnimation.GetMainImageFrameCount - 1) + ']');
    SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
    SourceAnimation.StopAutoPlayback;
    SourceAnimationInterval := 3;
    ImmediateDestruction := True;
    HasDestruction := True;
  end
  else if GraphKey = 'Weapon.Nine' then
  begin
    Projectile := TPSWeapon09BranchGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 0 then
  begin
    Projectile := TPSWeapon01GI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 1 then
  begin
    Projectile := TPSWeapon02GI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 2 then
  begin
    Projectile := TPSRocketGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 3 then
  begin
    Projectile := TPSWindGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 4 then
  begin
    Projectile := TPSPhaserGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 5 then
  begin
    Projectile := TPSWeapon06GI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 6 then
  begin
    Projectile := TPSHeavyLaserGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 7 then
  begin
    Projectile := TPSWeapon08GI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 8 then
  begin
    Projectile := TPSWeapon09GI.Create(Space.MapPanel);
  end
  else if I = 9 then
  begin
    Projectile := TPSPhaserGI.Create(Space.MapPanel);
    TargetAnimation := TgaiGI.Create(Space.MapPanel);
    TargetAnimation.SetImagePath('Bm.Weapon.W10');
    TargetAnimation.SetSize(TargetAnimation.GetContentSize);
    TargetAnimation.SetOrigin(HalfPoint(TargetAnimation.ClientSize));
    TargetAnimation.SetDepthByName('Weapon');
    TargetAnimation.SetPositionModeW(True);
    TargetAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(TargetAnimation.GetMainImageFrameCount - 1) + ']');
    TargetAnimation.StopAutoPlayback;
    TargetAnimationInterval := 2;
  end
  else if I = 10 then
  begin
    Projectile := TPSLaserCannonRayGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 11 then
  begin
    Projectile := TPSRailRayGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 12 then
  begin
    Projectile := TPSWeapon13GI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end
  else if I = 13 then
  begin
    Projectile := nil;
    SourceAnimation := TgaiGI.Create(Space.MapPanel);
    SourceAnimation.SetImagePath('Bm.Weapon.W14');
    SourceAnimation.SetSize(SourceAnimation.GetContentSize);
    SourceAnimation.SetOrigin(HalfPoint(SourceAnimation.ClientSize));
    SourceAnimation.SetDepthByName('Weapon');
    SourceAnimation.SetPositionModeW(True);
    SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
    SourceAnimation.SequenceIndex := 0;
    SourceAnimation.UpdateAutoGeometry;
    SourceAnimation.StopAutoPlayback;
    SourceAnimationInterval := 1;
  end
  else
  begin
    Projectile := TPSEyesGI.Create(Space.MapPanel);
    HitEffect := TWeaponEffect.Create(HitVariant, Space.MapPanel);
  end;
  if Projectile <> nil then
  begin
    Projectile.SetDepthByName('Weapon');
    Projectile.SetPosition(TruncatePointF(GetSourcePoint));
    Projectile.SetTargetPoint(TruncatePointF(GetTargetPoint));
    Projectile.SetPositionModeW(True);
  end;
  DamageLabelPoint := GetTargetPoint;
  DamageLabelPoint.X := DamageLabelPoint.X - 30.0;
  DamageLabelPoint.Y := DamageLabelPoint.Y - 30.0;
  if HitColor <> 0 then
  begin
    DamageLabel := TLabelGI.Create(Space.MapPanel);
    DamageLabel.SetFontName(HitPointFontName);
    DamageLabel.SetDepthByName('HitPoint');
    DamageLabel.SetPosition(TruncatePointF(DamageLabelPoint));
    DamageLabel.SetText(IntToStr(HitDamage));
    DamageLabel.SetWordWrapEnabled(False);
    DamageLabel.SetTextAlignX(taxAuto);
    DamageLabel.SetTextAlignY(tayAuto);
    DamageLabel.SetPositionModeW(True);
    DamageLabel.SetMouseViewUpdates(True);
    DamageLabel.SetTextColor(HitColor);
  end;
  if TargetDestroyed then
  begin
    if DestructionEffect = 0 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      if TargetObject is TRuinsSE then DestructionAnimation.SetImagePath('Bm.Weapon.Expl0')
      else DestructionAnimation.SetImagePath('Bm.Weapon.Expl' + IntToStr(RandomIntRange(0, 1)));
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']');
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 2;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
      if TargetObject <> nil then
      begin
        DestructionAlpha := TargetObject.GetAlpha;
        DestructionAlphaStep := (0.0 - DestructionAlpha) / (DestructionAnimation.GetMainImageFrameCount div 2 - 1);
      end
      else
      begin
        DestructionAlpha := 255;
        DestructionAlphaStep := 0;
      end;
    end
    else if DestructionEffect = 1 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Weapon.Bomb');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']');
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 1;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
    end
    else if DestructionEffect = 2 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Asteroid.Des');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']');
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 4;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 3;
    end
    else if DestructionEffect = 3 then
    begin
      DestructionAnimation := TgaiGI.Create(Space.MapPanel);
      DestructionAnimation.SetActive(False);
      DestructionAnimation.SetImagePath('Bm.Asteroid.Des');
      DestructionAnimation.SetSize(DestructionAnimation.GetContentSize);
      DestructionAnimation.SetOrigin(HalfPoint(DestructionAnimation.ClientSize));
      DestructionAnimation.SetDepthByName('Weapon');
      DestructionAnimation.SetPositionModeW(True);
      DestructionAnimation.LoadFrameSequenceFromText('[50,0-' + IntToStr(DestructionAnimation.GetMainImageFrameCount - 1) + ']');
      DestructionAnimation.StopAutoPlayback;
      DestructionFrameInterval := 4;
      DestructionDetachStep := DestructionAnimation.SequenceFrameCount div 5;
    end;
    HasDestruction := True;
    if ImmediateDestruction then DestructionAnimation.SetActive(True);
  end;
  if HasDestruction then
    if ImmediateDestruction then
      if FilmSoundEffectsEnabled then
        if SoundInSpaceEnabled then
          if Space.ContainsMapPoint(GetTargetPoint) then SoundManager.PlaySound(HitSoundPath);
  if PlayShotSound and FilmSoundEffectsEnabled and SoundInSpaceEnabled then
  begin
    if Projectile <> nil then
    begin
      if Space.ContainsMapPoint(PointToPointF(Projectile.LocalPosition)) then SoundManager.PlaySound(ShotSoundPath);
    end
    else if SourceAnimation <> nil then
      if Space.ContainsMapPoint(PointToPointF(SourceAnimation.LocalPosition)) then SoundManager.PlaySound(ShotSoundPath);
  end;
  if HitEffect <> nil then
  begin
    HitEffect.Owner := Space.MapPanel;
    HitEffect.SetSourcePoint(GetSourcePoint);
    HitEffect.SetTargetPoint(GetTargetPoint);
    HitEffect.DepthExpression := 'Weapon';
    HitEffect.Started := False;
  end;
  StepIndex := 0;
end;
{ @end $561BD0 }

{ @routine $562C90 TWeaponSE_DetachFromSpace }
procedure TWeaponSE.DetachFromSpace;
begin
  if HitEffect <> nil then
  begin
    HitEffect.Free;
    HitEffect := nil;
  end;
  if SourceAnimation <> nil then
  begin
    SourceAnimation.Free;
    SourceAnimation := nil;
  end;
  if TargetAnimation <> nil then
  begin
    TargetAnimation.Free;
    TargetAnimation := nil;
  end;
  if Projectile <> nil then
  begin
    Projectile.Invalidate;
    Projectile.Free;
    Projectile := nil;
  end;
  if DamageLabel <> nil then
  begin
    DamageLabel.Invalidate;
    DamageLabel.Free;
    DamageLabel := nil;
  end;
  if DestructionAnimation <> nil then
  begin
    DestructionAnimation.Free;
    DestructionAnimation := nil;
  end;
  inherited DetachFromSpace;
end;
{ @end $562C90 }

{ @routine $562D38 TWeaponSE_SetHit }
procedure TWeaponSE.SetHit(Color, Damage: Integer; Destroyed, PlaySound: Boolean);
begin
  HitColor := Color;
  HitDamage := Damage;
  TargetDestroyed := Destroyed;
  PlayShotSound := PlaySound;
end;
{ @end $562D38 }

{ @routine $562D54 TWeaponSE_SetEndpoints }
procedure TWeaponSE.SetEndpoints(Source, Target: TObjectSE);
begin
  SourceObject := Source;
  TargetObject := Target;
end;
{ @end $562D54 }

{ @routine $562D5C TWeaponSE_GetTargetPoint }
function TWeaponSE.GetTargetPoint: TPointF;
begin
  if TargetObject = nil then Result := Position
  else if TargetObject is TShip2SE then
    Result := (TargetObject as TShip2SE).GetTargetPoint((TargetObject as TShip2SE).GetAngle,
      (Cardinal(TargetObject) + Cardinal(SourceObject) + Cardinal(Self)) shr 2)
  else Result := TargetObject.Position;
end;
{ @end $562D5C }

{ @routine $562DD4 TWeaponSE_GetSourcePoint }
function TWeaponSE.GetSourcePoint: TPointF;
begin
  if SourceObject = nil then Result := Position else Result := SourceObject.Position;
end;
{ @end $562DD4 }

{ @routine $562DF8 TWeaponSE_Advance }
procedure TWeaponSE.Advance;
begin
  if not IsAttachedToSpace then Exit;
  if (HitEffect <> nil) and (Projectile <> nil) then
  begin
    if not HitEffect.Started then
    begin
      if not ProjectileFinished and (HitEffect.LeftTime >= Projectile.RemainingTicks) and HitEffect.BeforeEnd then
      begin
        HitEffect.Started := True;
        HitEffect.Start;
      end
      else if not ProjectileFinished and not HitEffect.BeforeEnd and (Projectile.GetElapsedTicks >= HitEffect.LeftTime) then
      begin
        HitEffect.Started := True;
        HitEffect.Start;
      end;
    end
    else
    begin
      HitEffect.SetSourcePoint(GetSourcePoint);
      HitEffect.SetTargetPoint(GetTargetPoint);
      if HitEffect.IsFinished then
      begin
        if DestructionAnimation = nil then
        begin
          DetachFromSpace;
          Exit;
        end;
      end
      else HitEffect.Advance;
    end;
  end;
  if Projectile <> nil then
  begin
    if not ProjectileFinished then Projectile.Advance(0, 0);
    if not ProjectileFinished and Projectile.IsFinished then
    begin
      ProjectileFinished := True;
      if Projectile <> nil then Projectile.SetActive(False);
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          if FilmSoundEffectsEnabled then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if HitEffect = nil then DetachFromSpace;
    end;
  end
  else if SourceAnimation = nil then
  begin
    if (StepIndex >= 50) and not ProjectileFinished then
    begin
      ProjectileFinished := True;
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          if FilmSoundEffectsEnabled then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if HitEffect = nil then DetachFromSpace;
    end;
  end
  else if SourceAnimation <> nil then
  begin
    if SourceAnimation.SequenceFrame = SourceAnimation.SequenceFrameCount - 1 then
    begin
      SourceAnimation.Free;
      SourceAnimation := nil;
      ProjectileFinished := True;
      if DestructionAnimation <> nil then
      begin
        if not DestructionAnimation.Active then
        begin
          DestructionAnimation.SetActive(True);
          if FilmSoundEffectsEnabled then
            if SoundInSpaceEnabled then
              if Space.ContainsMapPoint(GetTargetPoint) then SoundManager.PlaySound(HitSoundPath);
        end;
      end
      else if HitEffect = nil then DetachFromSpace;
    end
    else
    begin
      if StepIndex mod SourceAnimationInterval = 0 then
      begin
        SourceAnimation.SetSequenceFrame(SourceAnimation.SequenceFrame + 1);
        SourceAnimation.SetPosition(TruncatePointF(GetSourcePoint));
      end;
    end;
  end;
  if TargetAnimation <> nil then
  begin
    if TargetAnimation.SequenceFrame = TargetAnimation.SequenceFrameCount - 1 then
    begin
      TargetAnimation.Free;
      TargetAnimation := nil;
      if DestructionAnimation = nil then DetachFromSpace;
    end
    else
    begin
      if StepIndex mod TargetAnimationInterval = 0 then
        TargetAnimation.SetSequenceFrame(TargetAnimation.SequenceFrame + 1);
      TargetAnimation.SetPosition(TruncatePointF(GetTargetPoint));
    end;
  end;
  if (DestructionAnimation <> nil) and (DestructionAnimation.Active = True) then
  begin
    if DestructionAnimation.SequenceFrame = DestructionAnimation.SequenceFrameCount - 1 then
    begin
      DestructionAnimation.Free;
      DestructionAnimation := nil;
      if (TargetAnimation = nil) and ProjectileFinished then DetachFromSpace;
    end
    else
    begin
      if StepIndex mod DestructionFrameInterval = 0 then
      begin
        DestructionAnimation.SetSequenceFrame(DestructionAnimation.SequenceFrame + 1);
        if DestructionAnimation.SequenceFrame = DestructionDetachStep then
          if TargetObject <> nil then TargetObject.DetachFromSpace;
      end;
      DestructionAnimation.SetPosition(TruncatePointF(GetTargetPoint));
      if DestructionAlphaStep <> 0 then
      begin
        DestructionAlpha := DestructionAlpha + DestructionAlphaStep;
        if DestructionAlpha < 0 then DestructionAlpha := 0
        else if DestructionAlpha > 255 then DestructionAlpha := 255;
        TargetObject.SetAlpha(Round(DestructionAlpha));
      end;
    end;
  end;
  if Projectile <> nil then
  begin
    Projectile.SetPosition(TruncatePointF(GetSourcePoint));
    Projectile.SetTargetPoint(TruncatePointF(GetTargetPoint));
  end;
  if DamageLabel <> nil then
  begin
    DamageLabelPoint.X := DamageLabelPoint.X - 1.0;
    DamageLabelPoint.Y := DamageLabelPoint.Y - 1.0;
    DamageLabel.SetPosition(RoundPointF(DamageLabelPoint));
  end;
  Inc(StepIndex);
end;
{ @end $562DF8 }

{ @routine $5633AC TWeaponSE_LoadTemplate }
procedure TWeaponSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  if Block.CountParams('SoundShot') > 0 then ShotSoundPath := Block.GetParam('SoundShot');
  if Block.CountParams('SoundExpl') > 0 then HitSoundPath := Block.GetParam('SoundExpl');
end;
{ @end $5633AC }

{ @routine $56347C TWeaponEffect_Create }
constructor TWeaponEffect.Create(AEffectIndex: Integer; AOwner: TObjectGI);
var
  Block: TBlockParEC;
begin
  Started := True;
  EffectIndex := AEffectIndex;
  Owner := AOwner;
  Direction := 0;
  AnimationInterval := 1;
  AnimationCountdown := 0;
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex));
  if Block.CountParams('LeftTime') > 0 then
    LeftTime := ExtractDigitsToIntW(Block.GetParam('LeftTime'))
  else LeftTime := 10;
  if Block.CountParams('BeforeEnd') > 0 then
    BeforeEnd := ParseEnabledNameGI(Block.GetParam('BeforeEnd'))
  else BeforeEnd := True;
end;
{ @end $56347C }

{ @routine $5635FC TWeaponEffect_Destroy }
destructor TWeaponEffect.Destroy;
begin
  Clear;
end;
{ @end $5635FC }

{ @routine $56361C TWeaponEffect_Clear }
procedure TWeaponEffect.Clear;
begin
  while FirstItem <> nil do RemoveItem(FirstItem);
end;
{ @end $56361C }

{ @routine $563634 TWeaponEffect_AddItem }
function TWeaponEffect.AddItem: PWeaponEffectItem;
var
  Item: PWeaponEffectItem;
begin
  New(Item);
  Item.Next := nil;
  Item.Prev := LastItem;
  if FirstItem = nil then FirstItem := Item
  else LastItem.Next := Item;
  LastItem := Item;
  Item.Image := nil;
  Item.Position := MakePointF(0, 0);
  Item.Angle := 0;
  Item.Lifetime := 1;
  Item.Speed := 0;
  Item.Acceleration := 0;
  Result := Item;
end;
{ @end $563634 }

{ @routine $5636A0 TWeaponEffect_RemoveItem }
procedure TWeaponEffect.RemoveItem(Item: PWeaponEffectItem);
begin
  if Item = nil then Exit;
  if Item.Image <> nil then
  begin
    Item.Image.Free;
    Item.Image := nil;
  end;
  if Item.Next <> nil then Item.Next.Prev := Item.Prev;
  if Item.Prev <> nil then Item.Prev.Next := Item.Next;
  if LastItem = Item then LastItem := Item.Prev;
  if FirstItem = Item then FirstItem := Item.Next;
  Dispose(Item);
end;
{ @end $5636A0 }

{ @routine $5636F8 TWeaponEffect_AddTargetEffect }
procedure TWeaponEffect.AddTargetEffect(Index: Integer);
var
  Item: PWeaponEffectItem;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex) + '.D:' + IntToStr(Index));
  Item := AddItem;
  Item.AtTarget := True;
  Item.Position := MakePointF(0, ExtractDecimalToSingleW(Block.GetParam('StartPos')));
  Item.Angle := ExtractDigitsToIntW(Block.GetParam('Angle')) / 180.0 * Pi;
  Item.Speed := ExtractDecimalToSingleW(Block.GetParam('Speed'));
  Item.Acceleration := ExtractDecimalToSingleW(Block.GetParam('Accel'));
  if Block.CountParams('AutoAnim') > 0 then
    Item.AutoAnimation := ParseEnabledNameGI(Block.GetParam('AutoAnim'))
  else Item.AutoAnimation := True;
  if Block.CountParams('LoopAnim') > 0 then
    Item.LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'))
  else Item.LoopAnimation := True;
  if Block.CountParams('SkipTime') > 0 then
    Item.SkipTime := ExtractDigitsToIntW(Block.GetParam('SkipTime'))
  else Item.SkipTime := 0;
  Item.Image := TgaiGI.Create(Owner);
  Item.Image.SetImagePath(Block.GetParam('Image'));
  Item.Image.SequenceIndex := 0;
  Item.Image.UpdateAutoGeometry;
  Item.Image.SetSize(Item.Image.GetContentSize);
  Item.Image.SetOrigin(HalfPoint(Item.Image.ClientSize));
  Item.Image.SetDepthByName(DepthExpression);
  Item.Image.SetPosition(TruncatePointF(OffsetPointByRadiusAngle(TargetPoint, Item.Position.Y, Item.Angle)));
  Item.Image.SetPositionModeW(True);
  Item.Image.SetSequenceFrame(0);
  if Item.SkipTime = 0 then Item.Image.RestartPlayback
  else Item.Image.SetActive(False);
  if Block.CountParams('LifeTime') > 0 then
    Item.Lifetime := ExtractDigitsToIntW(Block.GetParam('LifeTime'))
  else Item.Lifetime := Item.Image.SequenceFrameCount * AnimationInterval;
  Item.Image.UserValue := Integer(Item);
  if Item.AutoAnimation and not Item.LoopAnimation then
    Item.Image.CycleCompleteCallback := AnimationComplete;
end;
{ @end $5636F8 }

{ @routine $563B0C TWeaponEffect_AddSourceEffect }
procedure TWeaponEffect.AddSourceEffect(Index: Integer);
var
  Item: PWeaponEffectItem;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex) + '.S:' + IntToStr(Index));
  Item := AddItem;
  Item.AtTarget := False;
  Item.Position := MakePointF(0, ExtractDecimalToSingleW(Block.GetParam('StartPos')));
  Item.Angle := ExtractDigitsToIntW(Block.GetParam('Angle')) / 180.0 * Pi;
  Item.Speed := ExtractDecimalToSingleW(Block.GetParam('Speed'));
  Item.Acceleration := ExtractDecimalToSingleW(Block.GetParam('Accel'));
  if Block.CountParams('AutoAnim') > 0 then
    Item.AutoAnimation := ParseEnabledNameGI(Block.GetParam('AutoAnim'))
  else Item.AutoAnimation := True;
  if Block.CountParams('LoopAnim') > 0 then
    Item.LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'))
  else Item.LoopAnimation := True;
  if Block.CountParams('SkipTime') > 0 then
    Item.SkipTime := ExtractDigitsToIntW(Block.GetParam('SkipTime'))
  else Item.SkipTime := 0;
  Item.Image := TgaiGI.Create(Owner);
  Item.Image.SetImagePath(Block.GetParam('Image'));
  Item.Image.SequenceIndex := 0;
  Item.Image.UpdateAutoGeometry;
  Item.Image.SetSize(Item.Image.GetContentSize);
  Item.Image.SetOrigin(HalfPoint(Item.Image.ClientSize));
  Item.Image.SetDepthByName(DepthExpression);
  Item.Image.SetPosition(TruncatePointF(OffsetPointByRadiusAngle(SourcePoint, Item.Position.Y, Item.Angle)));
  Item.Image.SetPositionModeW(True);
  Item.Image.SetSequenceFrame(0);
  if Item.SkipTime = 0 then Item.Image.RestartPlayback
  else Item.Image.SetActive(False);
  if Block.CountParams('LifeTime') > 0 then
    Item.Lifetime := ExtractDigitsToIntW(Block.GetParam('LifeTime'))
  else Item.Lifetime := Item.Image.SequenceFrameCount * AnimationInterval;
  Item.Image.UserValue := Integer(Item);
  if Item.AutoAnimation and not Item.LoopAnimation then
    Item.Image.CycleCompleteCallback := AnimationComplete;
end;
{ @end $563B0C }

{ @routine $563F20 TWeaponEffect_Start }
procedure TWeaponEffect.Start;
var
  Index, Count: Integer;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Weapon.' + IntToStr(EffectIndex));
  if Block.CountParams('AnimTakt') > 0 then
    AnimationInterval := ExtractDigitsToIntW(Block.GetParam('AnimTakt'))
  else AnimationInterval := 1;
  AnimationCountdown := AnimationInterval;
  Count := Block.CountBlocks('D');
  for Index := 0 to Count - 1 do AddTargetEffect(Index);
  Count := Block.CountBlocks('S');
  for Index := 0 to Count - 1 do AddSourceEffect(Index);
end;
{ @end $563F20 }

{ @routine $56406C TWeaponEffect_Advance }
procedure TWeaponEffect.Advance;
var
  Previous, Item: PWeaponEffectItem;
begin
  Item := FirstItem;
  while Item <> nil do
  begin
    if Item.SkipTime = 0 then
    begin
      Dec(Item.Lifetime);
      Item.Position.Y := Item.Position.Y + Item.Speed;
      Item.Speed := Item.Speed + Item.Acceleration;
    end;
    if Item.Image <> nil then
    begin
      if Item.AtTarget then
        Item.Image.SetPosition(TruncatePointF(OffsetPointByRadiusAngle(TargetPoint, Item.Position.Y, Item.Angle - 90.0)))
      else
        Item.Image.SetPosition(TruncatePointF(OffsetPointByRadiusAngle(SourcePoint, Item.Position.Y, Item.Angle - 90.0)));
      if Item.SkipTime = 0 then
      begin
        Dec(AnimationCountdown);
        if AnimationCountdown = 0 then
        begin
          if not Item.AutoAnimation then
          begin
            if Item.Image.SequenceFrame = Item.Image.SequenceFrameCount - 1 then
            begin
              if Item.LoopAnimation then Item.Image.SetSequenceFrame(0)
              else Item.Lifetime := 0;
            end
            else Item.Image.SetSequenceFrame(Item.Image.SequenceFrame + 1);
          end;
          AnimationCountdown := AnimationInterval;
        end;
      end
      else
      begin
        Dec(Item.SkipTime);
        if Item.SkipTime = 0 then
        begin
          Item.Image.SetActive(True);
          Item.Image.RestartPlayback;
        end;
      end;
    end;
    Previous := Item;
    Item := Item.Next;
    if Previous.Lifetime = 0 then RemoveItem(Previous);
  end;
end;
{ @end $56406C }

{ @routine $5641A4 TWeaponEffect_AnimationComplete }
procedure TWeaponEffect.AnimationComplete(Sender: TObjectGI);
var
  Item: PWeaponEffectItem;
begin
  Item := PWeaponEffectItem(Sender.UserValue);
  RemoveItem(Item);
end;
{ @end $5641A4 }

{ @routine $5641B0 TWeaponEffect_IsFinished }
function TWeaponEffect.IsFinished: Boolean;
begin
  if FirstItem = nil then Result := True
  else Result := False;
end;
{ @end $5641B0 }

{ @routine $5641BC TWeaponEffect_SetSourcePoint }
procedure TWeaponEffect.SetSourcePoint(Point: TPointF);
var
  X, Y: Single;
begin
  SourcePoint := Point;
  X := TargetPoint.X - SourcePoint.X;
  Y := TargetPoint.Y - SourcePoint.Y;
  if Abs(X) < 1.0 then Direction := ArcTan2(Y, 1.0) + 2 * Pi
  else Direction := ArcTan2(Y, X) + 2 * Pi;
end;
{ @end $5641BC }

{ @routine $564268 TWeaponEffect_SetTargetPoint }
procedure TWeaponEffect.SetTargetPoint(Point: TPointF);
var
  X, Y: Single;
begin
  TargetPoint := Point;
  X := TargetPoint.X - SourcePoint.X;
  Y := TargetPoint.Y - SourcePoint.Y;
  if Abs(X) < 1.0 then Direction := ArcTan2(Y, 1.0) + 2 * Pi
  else Direction := ArcTan2(Y, X) + 2 * Pi;
end;
{ @end $564268 }

end.

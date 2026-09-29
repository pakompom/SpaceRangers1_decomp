unit GI_PSWeapon09;
// Unit bracket (inferred): CODE 0x004C73AC..0x004C8BDB; inclusive evidence, not full bounds.
interface
uses GI_GAI, GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon09Particle = ^TWeapon09Particle;
  TWeapon09Particle = record // @size $28
    Kind: Integer; // @offset $0
    Position: TPointF; // @offset $4
    ByteOffset: Integer; // @offset $C
    PreviousByteOffset: Integer; // @offset $10
    Color: Word; // @offset $14
    SavedPixel: Word; // @offset $16
    Alpha: Byte; // @offset $18
  end;
  PWeapon09BranchParticle = ^TWeapon09BranchParticle;
  TWeapon09BranchParticle = record // @size $28
    Kind: Integer; // @offset $0
    Position: TPointF; // @offset $4
    ByteOffset: Integer; // @offset $C
    PreviousByteOffset: Integer; // @offset $10
    Color: Word; // @offset $14
    SavedPixel: Word; // @offset $16
    Alpha: Byte; // @offset $18
    Velocity: TPointF; // @offset $1C
    DelayTicks: Byte; // @offset $24
    MovementDelay: Byte; // @offset $25
    Unknown26: Byte; // @offset $26
    Unknown27: Byte; // @offset $27
  end;
  TPSWeapon09GI = class(TPSWeaponGI) // @size $13C
  public
    Unknown110: Integer; // @offset $110
    Particles: PWeapon09Particle; // @offset $114
    ParticleCount: Integer; // @offset $118
    ParticleCapacity: Integer; // @offset $11C
    OriginalLength: Single; // @offset $120
    Animation: TgaiGI; // @offset $124
    AnimationPosition: TPointF; // @offset $128
    AnimationVelocity: TPointF; // @offset $130
    Unknown138: Byte; // @offset $138

    constructor Create(Owner: TObjectGI); // @addr $4C80F0
    destructor Destroy; override; // @addr $4C819C
    procedure Invalidate; override; // @addr $4C81E8
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4C81EC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4C8218
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4C8234
    procedure SetPosition(Position: TPoint); override; // @addr $4C8238
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4C8264
    procedure UpdateHitTestBounds; override; // @addr $4C82A0
    procedure SetActive(Enabled: Boolean); override; // @addr $4C82C4
    procedure ClearSavedBackground; // @addr $4C82E4
    procedure ClearParticles; // @addr $4C837C
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4C83A8
    procedure ErasePreviousFrame; override; // @addr $4C87E8
    procedure PrepareFrameDraw; override; // @addr $4C8888
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4C8A54
    procedure Draw(ClipRect: TRect); override; // @addr $4C8A8C
    procedure CommitFrameDraw; override; // @addr $4C8AEC
    function IsFinished: Boolean; override; // @addr $4C8B98
  end;

  TPSWeapon09BranchGI = class(TPSWeaponGI) // @size $128
  public
    Unknown110: Integer; // @offset $110
    Particles: PWeapon09BranchParticle; // @offset $114
    ParticleCount: Integer; // @offset $118
    ParticleCapacity: Integer; // @offset $11C
    OriginalLength: Single; // @offset $120
    Unknown124: Byte; // @offset $124

    constructor Create(Owner: TObjectGI); // @addr $4C75F8
    destructor Destroy; override; // @addr $4C7648
    procedure Invalidate; override; // @addr $4C767C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4C7680
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4C76AC
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4C76C8
    procedure SetPosition(Position: TPoint); override; // @addr $4C76CC
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4C76F8
    procedure UpdateHitTestBounds; override; // @addr $4C7734
    procedure SetActive(Enabled: Boolean); override; // @addr $4C7758
    procedure ClearSavedBackground; // @addr $4C7778
    procedure ClearParticles; // @addr $4C7810
    procedure GrowParticles; // @addr $4C783C
    function AddParticle: PWeapon09BranchParticle; // @addr $4C7868
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4C78A4
    procedure ErasePreviousFrame; override; // @addr $4C7D0C
    procedure PrepareFrameDraw; override; // @addr $4C7DAC
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4C7FA0
    procedure Draw(ClipRect: TRect); override; // @addr $4C7FD8
    procedure CommitFrameDraw; override; // @addr $4C8038
    function IsFinished: Boolean; override; // @addr $4C80E4
  end;

implementation

// @unit-initialization $4C8BD4
// @unit-finalization $4C8BA4

uses aMyFunction, Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4C75F8 TPSWeapon09BranchGI_Create }
constructor TPSWeapon09BranchGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RemainingTicks := 90;
  Unknown110 := 0;
  Unknown124 := 20;
end;
{ @end $4C75F8 }

{ @routine $4C7648 TPSWeapon09BranchGI_Destroy }
destructor TPSWeapon09BranchGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4C7648 }

{ @routine $4C767C TPSWeapon09BranchGI_Invalidate }
procedure TPSWeapon09BranchGI.Invalidate;
begin

end;
{ @end $4C767C }

{ @routine $4C7680 TPSWeapon09BranchGI_LoadFromConfigPath }
procedure TPSWeapon09BranchGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4C7680 }

{ @routine $4C76AC TPSWeapon09BranchGI_LoadFromBlock }
procedure TPSWeapon09BranchGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4C76AC }

{ @routine $4C76C8 TPSWeapon09BranchGI_LoadEffectProperties }
procedure TPSWeapon09BranchGI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4C76C8 }

{ @routine $4C76CC TPSWeapon09BranchGI_SetPosition }
procedure TPSWeapon09BranchGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4C76CC }

{ @routine $4C76F8 TPSWeapon09BranchGI_SetTargetPoint }
procedure TPSWeapon09BranchGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4C76F8 }

{ @routine $4C7734 TPSWeapon09BranchGI_UpdateHitTestBounds }
procedure TPSWeapon09BranchGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4C7734 }

{ @routine $4C7758 TPSWeapon09BranchGI_SetActive }
procedure TPSWeapon09BranchGI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4C7758 }

{ @routine $4C7778 TPSWeapon09BranchGI_ClearSavedBackground }
procedure TPSWeapon09BranchGI.ClearSavedBackground;
var Particle: PWeapon09BranchParticle; I: Integer;
begin
  Particle := Particles;
  I := ParticleCount;
  if not BGImage then begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, Particle.SavedPixel);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
      Dec(I);
    end;
  end;
end;
{ @end $4C7778 }

{ @routine $4C7810 TPSWeapon09BranchGI_ClearParticles }
procedure TPSWeapon09BranchGI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4C7810 }

{ @routine $4C783C TPSWeapon09BranchGI_GrowParticles }
procedure TPSWeapon09BranchGI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon09BranchParticle));
end;
{ @end $4C783C }

{ @routine $4C7868 TPSWeapon09BranchGI_AddParticle }
function TPSWeapon09BranchGI.AddParticle: PWeapon09BranchParticle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon09BranchParticle));
  Inc(ParticleCount);
end;
{ @end $4C7868 }

{ @routine $4C78A4 TPSWeapon09BranchGI_Advance }
procedure TPSWeapon09BranchGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Particle: PWeapon09BranchParticle;
  J, I, K: Integer;
  Delay: Integer;
  PY, PX, Speed, Angle: Single;
begin
  if RemainingTicks = 60 then
  begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    if OriginalLength < 1.0 then OriginalLength := 1;
    for I := 1 to 5 do
    begin
      PX := RandomIntRange(-16, 16);
      PY := RandomIntRange(-16, 16);
      Delay := RandomIntRange(5, 6);
      for J := 0 to 2 do
        for K := 0 to 7 do
        begin
          Particle := AddParticle;
          Particle.Kind := 1;
          case K of
            0: begin Particle.Position.X := J + PX; Particle.Position.Y := J + PY; end;
            1: begin Particle.Position.X := J + PX; Particle.Position.Y := PY - J; end;
            2: begin Particle.Position.X := PX - J; Particle.Position.Y := J + PY; end;
            3: begin Particle.Position.X := PX - J; Particle.Position.Y := PY - J; end;
            4: begin Particle.Position.X := J + PX + 1.0; Particle.Position.Y := J + PY; end;
            5: begin Particle.Position.X := J + PX + 1.0; Particle.Position.Y := PY - J; end;
            6: begin Particle.Position.X := PX - J + 1.0; Particle.Position.Y := J + PY; end;
            7: begin Particle.Position.X := PX - J + 1.0; Particle.Position.Y := PY - J; end;
          end;
          Particle.ByteOffset := -1;
          Particle.PreviousByteOffset := -1;
          Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.0, 0.9, 1.0);
          Particle.Alpha := 0;
          Particle.MovementDelay := 6;
          Particle.DelayTicks := Delay;
          Particle.Unknown26 := 0;
          Particle.Unknown27 := 1;
        end;
    end;
  end;
  Particle := Particles;
  J := ParticleCount;
  I := 0;
  if 90 - RemainingTicks > 30 then
    while J > 0 do
    begin
      if Particle.Kind = 1 then
      begin
        Dec(Particle.DelayTicks);
        if Particle.DelayTicks < 5 then Inc(Particle.Alpha, 50);
        Dec(Particle.MovementDelay);
        if Particle.MovementDelay = 0 then
        begin
          Particle.Kind := 2;
          Particle.Velocity.X := -Particle.Position.X / 50.0;
          Particle.Velocity.Y := (OriginalLength - 24.0) / 30.0;
        end;
      end
      else if Particle.Kind = 2 then
      begin
        Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
        Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
        if OriginalLength - 12.0 < Particle.Position.Y then
        begin
          Speed := RandomIntRange(6, 24) / 10.0;
          Angle := RandomIntRange(0, 360) / 180.0 * Pi;
          Particle.Velocity.X := Cos(Angle) * Speed;
          Particle.Velocity.Y := Sin(Angle) * Speed;
          Particle.Kind := 3;
          Particle.DelayTicks := 6;
        end;
      end
      else if Particle.Kind = 3 then
      begin
        Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
        Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
        Particle.Velocity.X := 0.99 * Particle.Velocity.X;
        Particle.Velocity.Y := 0.99 * Particle.Velocity.Y;
        if Particle.DelayTicks > 0 then Dec(Particle.DelayTicks)
        else if Particle.Alpha > 11 then Dec(Particle.Alpha, 10);
      end;
      Inc(I);
      Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon09BranchParticle));
      Dec(J);
    end;
  Dec(RemainingTicks);
end;
{ @end $4C78A4 }

{ @routine $4C7D0C TPSWeapon09BranchGI_ErasePreviousFrame }
procedure TPSWeapon09BranchGI.ErasePreviousFrame;
var Particle: PWeapon09BranchParticle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  Particle := Particles;
  I := ParticleCount;
  if not BGImage then begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4C7D0C }

{ @routine $4C7DAC TPSWeapon09BranchGI_PrepareFrameDraw }
procedure TPSWeapon09BranchGI.PrepareFrameDraw;
var Buffer: Pointer; PX, PY, Sine, Cosine, Angle: Single;
  Pitch: Integer; Scale: Single;
  Particle: PWeapon09BranchParticle; Count, X, Y, Offset: Integer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  if OriginalLength = 0 then OriginalLength := OriginalLength + 1;
  Scale := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y)) / OriginalLength;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := Particles;
  Count := ParticleCount;
  while Count > 0 do begin
    Particle.ByteOffset := -1;
    if Particle.Kind >= 1 then begin
      PX := Particle.Position.X;
      PY := Particle.Position.Y * Scale;
      X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
      Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
      Offset := X * 2 + Y * Pitch;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset := Offset;
    end;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
      Dec(Count);
    end;
  end;
end;
{ @end $4C7DAC }

{ @routine $4C7FA0 TPSWeapon09BranchGI_DrawUpdateRects }
procedure TPSWeapon09BranchGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4C7FA0 }

{ @routine $4C7FD8 TPSWeapon09BranchGI_Draw }
procedure TPSWeapon09BranchGI.Draw(ClipRect: TRect);
var Particle: PWeapon09BranchParticle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
    Dec(I);
  end;
end;
{ @end $4C7FD8 }

{ @routine $4C8038 TPSWeapon09BranchGI_CommitFrameDraw }
procedure TPSWeapon09BranchGI.CommitFrameDraw;
var Particle: PWeapon09BranchParticle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09BranchParticle));
    Dec(I);
  end;
end;
{ @end $4C8038 }

{ @routine $4C80E4 TPSWeapon09BranchGI_IsFinished }
function TPSWeapon09BranchGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4C80E4 }

{ @routine $4C80F0 TPSWeapon09GI_Create }
constructor TPSWeapon09GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RemainingTicks := 90;
  Unknown110 := 0;
  Animation := nil;
  AnimationPosition := MakePointF(LocalPosition.X, LocalPosition.Y);
  AnimationVelocity := MakePointF(0, 0);
  Unknown138 := 20;
end;
{ @end $4C80F0 }

{ @routine $4C819C TPSWeapon09GI_Destroy }
destructor TPSWeapon09GI.Destroy;
begin
  if Animation <> nil then begin Animation.Free; Animation := nil; end;
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4C819C }

{ @routine $4C81E8 TPSWeapon09GI_Invalidate }
procedure TPSWeapon09GI.Invalidate;
begin

end;
{ @end $4C81E8 }

{ @routine $4C81EC TPSWeapon09GI_LoadFromConfigPath }
procedure TPSWeapon09GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4C81EC }

{ @routine $4C8218 TPSWeapon09GI_LoadFromBlock }
procedure TPSWeapon09GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4C8218 }

{ @routine $4C8234 TPSWeapon09GI_LoadEffectProperties }
procedure TPSWeapon09GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4C8234 }

{ @routine $4C8238 TPSWeapon09GI_SetPosition }
procedure TPSWeapon09GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4C8238 }

{ @routine $4C8264 TPSWeapon09GI_SetTargetPoint }
procedure TPSWeapon09GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4C8264 }

{ @routine $4C82A0 TPSWeapon09GI_UpdateHitTestBounds }
procedure TPSWeapon09GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4C82A0 }

{ @routine $4C82C4 TPSWeapon09GI_SetActive }
procedure TPSWeapon09GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4C82C4 }

{ @routine $4C82E4 TPSWeapon09GI_ClearSavedBackground }
procedure TPSWeapon09GI.ClearSavedBackground;
var Particle: PWeapon09Particle; I: Integer;
begin
  Particle := Particles;
  I := ParticleCount;
  if not BGImage then begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, Particle.SavedPixel);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4C82E4 }

{ @routine $4C837C TPSWeapon09GI_ClearParticles }
procedure TPSWeapon09GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4C837C }

{ @routine $4C83A8 TPSWeapon09GI_Advance }
procedure TPSWeapon09GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Particle: PWeapon09Particle;
  Count, I: Integer;
  Angle, PX, PY, Sine, Cosine, Scale: Single;
begin
  if RemainingTicks = 90 then
  begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    if OriginalLength < 1.0 then OriginalLength := 1;
    if Animation <> nil then Animation.Free;
    Animation := TgaiGI.Create(Parent);
    Animation.SetImagePath('Bm.Weapon.W09');
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetDepthByName('Weapon');
    Animation.SetPosition(TargetPoint);
    Animation.SetPositionModeW(True);
    Animation.LoadFrameSequenceFromText('[20000,0-' + IntToStr(Animation.GetMainImageFrameCount - 1) + ']');
    Animation.SetSequenceFrame(1);
    Animation.StopAutoPlayback;
    AnimationVelocity := MakePointF(0, (OriginalLength - 24.0) / 30.0);
    AnimationPosition := MakePointF(0, 24.0 - AnimationVelocity.Y);
  end;
  Particle := Particles;
  Count := ParticleCount;
  I := 0;
  while Count > 0 do
  begin
    if Particle.Kind = 1 then begin end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon09Particle));
    Dec(Count);
  end;
  if Animation <> nil then
  begin
    if AnimationPosition.Y < OriginalLength then
    begin
      AnimationPosition.Y := AnimationPosition.Y + AnimationVelocity.Y;
      AnimationPosition.X := AnimationPosition.X + AnimationVelocity.X;
      Scale := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y)) / OriginalLength;
      PY := -(TargetPoint.Y - LocalPosition.Y);
      if PY = 0 then PY := 1;
      Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
      Sine := Sin(Angle);
      Cosine := Cos(Angle);
      PX := AnimationPosition.X;
      PY := AnimationPosition.Y * Scale;
      Animation.SetPosition(Classes.Point(Round(PX * Cosine + PY * Sine) + LocalPosition.X,
        Round(PX * Sine - PY * Cosine) + LocalPosition.Y));
    end
    else
    begin
      if Animation.SequenceFrame = Animation.SequenceFrameCount - 1 then
      begin
        Animation.Free;
        Animation := nil;
      end
      else
      begin
        Animation.SetSequenceFrame(Animation.SequenceFrame + 1);
        Animation.SetPosition(TargetPoint);
      end;
    end;
  end;
  if RemainingTicks > 0 then Dec(RemainingTicks);
  if (RemainingTicks = 0) and (Animation <> nil) then
  begin
    Animation.Free;
    Animation := nil;
  end;
end;
{ @end $4C83A8 }

{ @routine $4C87E8 TPSWeapon09GI_ErasePreviousFrame }
procedure TPSWeapon09GI.ErasePreviousFrame;
var Particle: PWeapon09Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  Particle := Particles;
  I := ParticleCount;
  if not BGImage then begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4C87E8 }

{ @routine $4C8888 TPSWeapon09GI_PrepareFrameDraw }
procedure TPSWeapon09GI.PrepareFrameDraw;
var Buffer: Pointer; PX, PY, Sine, Cosine, Angle: Single;
  Pitch: Integer; Scale: Single;
  Particle: PWeapon09Particle; Count, X, Y, Offset: Integer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Scale := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y)) / OriginalLength;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := Particles;
  Count := ParticleCount;
  while Count > 0 do begin
    Particle.ByteOffset := -1;
    if Particle.Kind >= 1 then begin
      PX := Particle.Position.X;
      PY := Particle.Position.Y * Scale;
      X := Round(PX * Cosine + PY * Sine) + AbsolutePosition.X;
      Y := Round(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
      Offset := X * 2 + Y * Pitch;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset := Offset;
    end;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4C8888 }

{ @routine $4C8A54 TPSWeapon09GI_DrawUpdateRects }
procedure TPSWeapon09GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4C8A54 }

{ @routine $4C8A8C TPSWeapon09GI_Draw }
procedure TPSWeapon09GI.Draw(ClipRect: TRect);
var Particle: PWeapon09Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
    Dec(I);
  end;
end;
{ @end $4C8A8C }

{ @routine $4C8AEC TPSWeapon09GI_CommitFrameDraw }
procedure TPSWeapon09GI.CommitFrameDraw;
var Particle: PWeapon09Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon09Particle));
    Dec(I);
  end;
end;
{ @end $4C8AEC }

{ @routine $4C8B98 TPSWeapon09GI_IsFinished }
function TPSWeapon09GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4C8B98 }

end.

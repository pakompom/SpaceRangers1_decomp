unit GI_PSWeapon02;
// Unit bracket (inferred): CODE 0x004CA178..0x004CAC67; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon02Particle = ^TWeapon02Particle;
  TWeapon02Particle = record // @size $34
    Kind: Integer; // @offset $0
    Position: TPointF; // @offset $4
    ByteOffset: Integer; // @offset $C
    PreviousByteOffset: Integer; // @offset $10
    Color: Word; // @offset $14
    SavedPixel: Word; // @offset $16
    Alpha: Byte; // @offset $18
    Velocity: TPointF; // @offset $1C
    DelayTicks: Byte; // @offset $24
    InitialDelayTicks: Byte; // @offset $25
    UpperNeighborOffset: Integer; // @offset $28
    LowerNeighborOffset: Integer; // @offset $2C
    ForwardNeighborOffset: Integer; // @offset $30
  end;
  TPSWeapon02GI = class(TPSWeaponGI) // @size $124
  public
    Particles: PWeapon02Particle; // @offset $110
    ParticleCount: Integer; // @offset $114
    ParticleCapacity: Integer; // @offset $118
    OriginalLength: Single; // @offset $11C
    SourceAlphaLimit: Word; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $4CA29C
    destructor Destroy; override; // @addr $4CA2E8
    procedure Invalidate; override; // @addr $4CA31C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4CA320
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4CA34C
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4CA368
    procedure SetPosition(Position: TPoint); override; // @addr $4CA36C
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4CA398
    procedure UpdateHitTestBounds; override; // @addr $4CA3D4
    procedure SetActive(Enabled: Boolean); override; // @addr $4CA3F8
    procedure ClearSavedBackground; // @addr $4CA418
    procedure ClearParticles; // @addr $4CA4C0
    procedure GrowParticles; // @addr $4CA4EC
    function AddParticle: PWeapon02Particle; // @addr $4CA510
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4CA548
    procedure ErasePreviousFrame; override; // @addr $4CA864
    procedure PrepareFrameDraw; override; // @addr $4CA914
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4CAAE0
    procedure Draw(ClipRect: TRect); override; // @addr $4CAB18
    procedure CommitFrameDraw; override; // @addr $4CAB78
    function IsFinished: Boolean; override; // @addr $4CAC24
  end;

implementation

// @unit-initialization $4CAC60
// @unit-finalization $4CAC30

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4CA29C TPSWeapon02GI_Create }
constructor TPSWeapon02GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RemainingTicks := 40;
  LifetimeTicks := 40;
end;
{ @end $4CA29C }

{ @routine $4CA2E8 TPSWeapon02GI_Destroy }
destructor TPSWeapon02GI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4CA2E8 }

{ @routine $4CA31C TPSWeapon02GI_Invalidate }
procedure TPSWeapon02GI.Invalidate;
begin

end;
{ @end $4CA31C }

{ @routine $4CA320 TPSWeapon02GI_LoadFromConfigPath }
procedure TPSWeapon02GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4CA320 }

{ @routine $4CA34C TPSWeapon02GI_LoadFromBlock }
procedure TPSWeapon02GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4CA34C }

{ @routine $4CA368 TPSWeapon02GI_LoadEffectProperties }
procedure TPSWeapon02GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4CA368 }

{ @routine $4CA36C TPSWeapon02GI_SetPosition }
procedure TPSWeapon02GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4CA36C }

{ @routine $4CA398 TPSWeapon02GI_SetTargetPoint }
procedure TPSWeapon02GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4CA398 }

{ @routine $4CA3D4 TPSWeapon02GI_UpdateHitTestBounds }
procedure TPSWeapon02GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4CA3D4 }

{ @routine $4CA3F8 TPSWeapon02GI_SetActive }
procedure TPSWeapon02GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4CA3F8 }

{ @routine $4CA418 TPSWeapon02GI_ClearSavedBackground }
procedure TPSWeapon02GI.ClearSavedBackground;
var Particle: PWeapon02Particle; I: Integer;
begin
  if BGImage then begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, Particle.SavedPixel);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
      Dec(I);
    end;
  end else begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4CA418 }

{ @routine $4CA4C0 TPSWeapon02GI_ClearParticles }
procedure TPSWeapon02GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4CA4C0 }

{ @routine $4CA4EC TPSWeapon02GI_GrowParticles }
procedure TPSWeapon02GI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon02Particle));
end;
{ @end $4CA4EC }

{ @routine $4CA510 TPSWeapon02GI_AddParticle }
function TPSWeapon02GI.AddParticle: PWeapon02Particle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon02Particle));
  Inc(ParticleCount);
end;
{ @end $4CA510 }

{ @routine $4CA548 TPSWeapon02GI_Advance }
procedure TPSWeapon02GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Width, I, J: Integer; Y: Single;
  ForwardAlpha, UpperAlpha, LowerAlpha: Byte; UpdateAlpha: Boolean;
  Particle: PWeapon02Particle;
begin
  if RemainingTicks = 40 then begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    Y := 0;
    while Y < OriginalLength do begin
      Width := Trunc(Y / OriginalLength * 7.0) + 1;
      for I := Width - 1 downto 0 do
        for J := 0 to 1 do begin
          Particle := AddParticle;
          Particle.Position.X := I - 1;
          if J = 1 then Particle.Position.X := -Particle.Position.X;
          Particle.Position.Y := Y;
          if I = 0 then Particle.Kind := 1 else Particle.Kind := 2;
          Particle.ByteOffset := -1;
          Particle.PreviousByteOffset := -1;
          if I = 0 then Particle.Alpha := Random(256) else Particle.Alpha := 0;
          Particle.InitialDelayTicks := RemainingTicks;
          Particle.DelayTicks := Particle.InitialDelayTicks;
          Particle.Velocity.X := 0;
          Particle.Velocity.Y := 0;
          case J of
            0: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.2, 0.5, 1.0);
            1: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.3, 0.75, 1.0);
          end;
          Particle.UpperNeighborOffset := (Width - 1) * -104;
          Particle.LowerNeighborOffset := (Width + 1) * 104;
          Particle.ForwardNeighborOffset := 104;
        end;
      Y := Y + 1.0;
    end;
    SourceAlphaLimit := 256;
  end;
  I := 0;
  Particle := Particles;
  J := ParticleCount - 14;
  UpdateAlpha := (40 - RemainingTicks) mod 2 = 0;
  while J > 0 do begin
    if (Particle.Kind = 2) and (UpdateAlpha) then begin
      ForwardAlpha := PWeapon02Particle(AddPointerOffset(Particle, Particle.ForwardNeighborOffset)).Alpha;
      UpperAlpha := PWeapon02Particle(AddPointerOffset(Particle, Particle.UpperNeighborOffset)).Alpha;
      LowerAlpha := PWeapon02Particle(AddPointerOffset(Particle, Particle.LowerNeighborOffset)).Alpha;
      Particle.Alpha := (ForwardAlpha + UpperAlpha + LowerAlpha + ForwardAlpha) shr 2;
      if Particle.Alpha > 9 then Dec(Particle.Alpha, 9) else Particle.Alpha := 0;
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
    end else if (Particle.Kind = 1) and (UpdateAlpha) then begin
      Particle.Alpha := Random(SourceAlphaLimit);
      if Particle.Position.Y < 32.0 then Particle.Alpha := Trunc(Particle.Alpha * Particle.Position.Y) shr 5;
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
    end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon02Particle));
    Dec(J);
  end;
  if RemainingTicks < 20 then begin
    if SourceAlphaLimit > 6 then Dec(SourceAlphaLimit, 6) else SourceAlphaLimit := 0;
  end;
  if RemainingTicks > 0 then Dec(RemainingTicks);
end;
{ @end $4CA548 }

{ @routine $4CA864 TPSWeapon02GI_ErasePreviousFrame }
procedure TPSWeapon02GI.ErasePreviousFrame;
var Particle: PWeapon02Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  if BGImage then begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
      Dec(I);
    end;
  end else begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4CA864 }

{ @routine $4CA914 TPSWeapon02GI_PrepareFrameDraw }
procedure TPSWeapon02GI.PrepareFrameDraw;
var Buffer: Pointer; Pitch: Integer; PX, PY, Sine, Cosine, Angle, Scale: Single;
  Particle: PWeapon02Particle; Count, X, Y: Integer;
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
    if Particle.Kind >= 2 then begin
      PX := Particle.Position.X;
      PY := Particle.Position.Y * Scale;
      X := Trunc(PX * Cosine + PY * Sine) + AbsolutePosition.X;
      Y := Trunc(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset := X * 2 + Y * Pitch;
    end;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4CA914 }

{ @routine $4CAAE0 TPSWeapon02GI_DrawUpdateRects }
procedure TPSWeapon02GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4CAAE0 }

{ @routine $4CAB18 TPSWeapon02GI_Draw }
procedure TPSWeapon02GI.Draw(ClipRect: TRect);
var Particle: PWeapon02Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
    Dec(I);
  end;
end;
{ @end $4CAB18 }

{ @routine $4CAB78 TPSWeapon02GI_CommitFrameDraw }
procedure TPSWeapon02GI.CommitFrameDraw;
var Particle: PWeapon02Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon02Particle));
    Dec(I);
  end;
end;
{ @end $4CAB78 }

{ @routine $4CAC24 TPSWeapon02GI_IsFinished }
function TPSWeapon02GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4CAC24 }

end.

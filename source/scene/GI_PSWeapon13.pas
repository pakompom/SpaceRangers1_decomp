unit GI_PSWeapon13;
// Unit bracket (inferred): CODE 0x004C8BDC..0x004C96A3; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon13Particle = ^TWeapon13Particle;
  TWeapon13Particle = record // @size $28
    Kind: Integer; // @offset $0
    Position: TPointF; // @offset $4
    ByteOffset: Integer; // @offset $C
    PreviousByteOffset: Integer; // @offset $10
    Color: Word; // @offset $14
    SavedPixel: Word; // @offset $16
    Alpha: Byte; // @offset $18
    Velocity: TPointF; // @offset $1C
    Unknown26: Byte; // @offset $26
  end;
  TPSWeapon13GI = class(TPSWeaponGI) // @size $130
  public
    Particles: PWeapon13Particle; // @offset $110
    ParticleCount: Integer; // @offset $114
    ParticleCapacity: Integer; // @offset $118
    OriginalLength: Single; // @offset $11C
    Colors: array[0..7] of Word; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $4C8D00
    destructor Destroy; override; // @addr $4C8DCC
    procedure Invalidate; override; // @addr $4C8E00
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4C8E04
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4C8E30
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4C8E4C
    procedure SetPosition(Position: TPoint); override; // @addr $4C8E50
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4C8E7C
    procedure UpdateHitTestBounds; override; // @addr $4C8EB8
    procedure SetActive(Enabled: Boolean); override; // @addr $4C8EDC
    procedure ClearSavedBackground; // @addr $4C8EFC
    procedure ClearParticles; // @addr $4C8FA4
    procedure GrowParticles; // @addr $4C8FD0
    function AddParticle: PWeapon13Particle; // @addr $4C8FFC
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4C9038
    procedure ErasePreviousFrame; override; // @addr $4C9280
    procedure PrepareFrameDraw; override; // @addr $4C9330
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4C9518
    procedure Draw(ClipRect: TRect); override; // @addr $4C9550
    procedure CommitFrameDraw; override; // @addr $4C95B4
    function IsFinished: Boolean; override; // @addr $4C9660
  end;

implementation

// @unit-initialization $4C969C
// @unit-finalization $4C966C

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4C8D00 TPSWeapon13GI_Create }
constructor TPSWeapon13GI.Create(Owner: TObjectGI);
var I: Integer;
begin
  inherited Create(Owner);
  RemainingTicks := 55;
  LifetimeTicks := 55;
  for I := 0 to 7 do
    Colors[I] := CurrentPixelFormat.PackNormalizedRgb((15 - I) / 15.0, (15 - I) / 30.0, (15 - I) / 45.0);
end;
{ @end $4C8D00 }

{ @routine $4C8DCC TPSWeapon13GI_Destroy }
destructor TPSWeapon13GI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4C8DCC }

{ @routine $4C8E00 TPSWeapon13GI_Invalidate }
procedure TPSWeapon13GI.Invalidate;
begin

end;
{ @end $4C8E00 }

{ @routine $4C8E04 TPSWeapon13GI_LoadFromConfigPath }
procedure TPSWeapon13GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4C8E04 }

{ @routine $4C8E30 TPSWeapon13GI_LoadFromBlock }
procedure TPSWeapon13GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4C8E30 }

{ @routine $4C8E4C TPSWeapon13GI_LoadEffectProperties }
procedure TPSWeapon13GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4C8E4C }

{ @routine $4C8E50 TPSWeapon13GI_SetPosition }
procedure TPSWeapon13GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4C8E50 }

{ @routine $4C8E7C TPSWeapon13GI_SetTargetPoint }
procedure TPSWeapon13GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4C8E7C }

{ @routine $4C8EB8 TPSWeapon13GI_UpdateHitTestBounds }
procedure TPSWeapon13GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4C8EB8 }

{ @routine $4C8EDC TPSWeapon13GI_SetActive }
procedure TPSWeapon13GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4C8EDC }

{ @routine $4C8EFC TPSWeapon13GI_ClearSavedBackground }
procedure TPSWeapon13GI.ClearSavedBackground;
var Particle: PWeapon13Particle; I: Integer;
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4C8EFC }

{ @routine $4C8FA4 TPSWeapon13GI_ClearParticles }
procedure TPSWeapon13GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4C8FA4 }

{ @routine $4C8FD0 TPSWeapon13GI_GrowParticles }
procedure TPSWeapon13GI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon13Particle));
end;
{ @end $4C8FD0 }

{ @routine $4C8FFC TPSWeapon13GI_AddParticle }
function TPSWeapon13GI.AddParticle: PWeapon13Particle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon13Particle));
  Inc(ParticleCount);
end;
{ @end $4C8FFC }

{ @routine $4C9038 TPSWeapon13GI_Advance }
procedure TPSWeapon13GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var I, J, K: Integer; Particle: PWeapon13Particle; Speed: Single;
begin
  if RemainingTicks = 55 then begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    Speed := (OriginalLength + 80.0) / 55.0;
    for I := 0 to 1 do
      for J := 0 to 7 do
        for K := -10 to 10 do begin
          Particle := AddParticle;
          Particle.Kind := 2;
          Particle.Position.X := (J * 6 * 10 / OriginalLength + 4.0) * (K / 10.0);
          Particle.Position.Y := Sqrt(256 - Sqr(K)) + J * 10 - 80.0 + I + Sin(3 * K / 10.0 * Pi) * 1.5;
          Particle.ByteOffset := -1;
          Particle.PreviousByteOffset := -1;
          Particle.Color := Colors[(8 * Abs(K)) div 11];
          Particle.SavedPixel := 0;
          Particle.Alpha := 0;
          Particle.Velocity.X := 6.0 * Particle.Position.X / 4.0 / 55.0;
          Particle.Velocity.Y := Speed;
          Particle.Unknown26 := 0;
        end;
  end;
  I := 0;
  Particle := Particles;
  J := ParticleCount;
  while J > 0 do begin
    if Particle.Kind = 2 then begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y >= OriginalLength then Particle.Kind := 0;
      if Particle.Position.Y > 0 then begin
        if Particle.Alpha < 231 then Inc(Particle.Alpha, 24) else Particle.Alpha := 255;
      end;
    end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon13Particle));
    Dec(J);
  end;
  if RemainingTicks > 0 then Dec(RemainingTicks);
end;
{ @end $4C9038 }

{ @routine $4C9280 TPSWeapon13GI_ErasePreviousFrame }
procedure TPSWeapon13GI.ErasePreviousFrame;
var Particle: PWeapon13Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  if not BGImage then begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
      Dec(I);
    end;
  end else begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4C9280 }

{ @routine $4C9330 TPSWeapon13GI_PrepareFrameDraw }
procedure TPSWeapon13GI.PrepareFrameDraw;
var PX, PY, Sine, Cosine, Angle: Single;
  Buffer: Pointer; Pitch: Integer; Scale: Single;
  Particle: PWeapon13Particle; Count, X, Y: Integer;
begin
  if OriginalLength = 0 then Advance(0, 0);
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
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4C9330 }

{ @routine $4C9518 TPSWeapon13GI_DrawUpdateRects }
procedure TPSWeapon13GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4C9518 }

{ @routine $4C9550 TPSWeapon13GI_Draw }
procedure TPSWeapon13GI.Draw(ClipRect: TRect);
var Particle: PWeapon13Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.Kind >= 2 then
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
    Dec(I);
  end;
end;
{ @end $4C9550 }

{ @routine $4C95B4 TPSWeapon13GI_CommitFrameDraw }
procedure TPSWeapon13GI.CommitFrameDraw;
var Particle: PWeapon13Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon13Particle));
    Dec(I);
  end;
end;
{ @end $4C95B4 }

{ @routine $4C9660 TPSWeapon13GI_IsFinished }
function TPSWeapon13GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4C9660 }

end.

unit GI_PSWeapon08;
// Unit bracket (inferred): CODE 0x004C9714..0x004CA177; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon08Particle = ^TWeapon08Particle;
  TWeapon08Particle = record // @size $28
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
  TPSWeapon08GI = class(TPSWeaponGI) // @size $130
  public
    Particles: PWeapon08Particle; // @offset $110
    ParticleCount: Integer; // @offset $114
    ParticleCapacity: Integer; // @offset $118
    OriginalLength: Single; // @offset $11C
    Colors: array[0..7] of Word; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $4C9838
    destructor Destroy; override; // @addr $4C9904
    procedure Invalidate; override; // @addr $4C9938
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4C993C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4C9968
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4C9984
    procedure SetPosition(Position: TPoint); override; // @addr $4C9988
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4C99B4
    procedure UpdateHitTestBounds; override; // @addr $4C99F0
    procedure SetActive(Enabled: Boolean); override; // @addr $4C9A14
    procedure ClearSavedBackground; // @addr $4C9A34
    procedure ClearParticles; // @addr $4C9ADC
    procedure GrowParticles; // @addr $4C9B08
    function AddParticle: PWeapon08Particle; // @addr $4C9B34
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4C9B70
    procedure ErasePreviousFrame; override; // @addr $4C9D74
    procedure PrepareFrameDraw; override; // @addr $4C9E24
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4C9FEC
    procedure Draw(ClipRect: TRect); override; // @addr $4CA024
    procedure CommitFrameDraw; override; // @addr $4CA088
    function IsFinished: Boolean; override; // @addr $4CA134
  end;

implementation

// @unit-initialization $4CA170
// @unit-finalization $4CA140

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4C9838 TPSWeapon08GI_Create }
constructor TPSWeapon08GI.Create(Owner: TObjectGI);
var I: Integer;
begin
  inherited Create(Owner);
  RemainingTicks := 55;
  LifetimeTicks := 55;
  for I := 0 to 7 do
    Colors[I] := CurrentPixelFormat.PackNormalizedRgb((15 - I) / 30.0, (15 - I) / 45.0, (15 - I) / 15.0);
end;
{ @end $4C9838 }

{ @routine $4C9904 TPSWeapon08GI_Destroy }
destructor TPSWeapon08GI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4C9904 }

{ @routine $4C9938 TPSWeapon08GI_Invalidate }
procedure TPSWeapon08GI.Invalidate;
begin

end;
{ @end $4C9938 }

{ @routine $4C993C TPSWeapon08GI_LoadFromConfigPath }
procedure TPSWeapon08GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4C993C }

{ @routine $4C9968 TPSWeapon08GI_LoadFromBlock }
procedure TPSWeapon08GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4C9968 }

{ @routine $4C9984 TPSWeapon08GI_LoadEffectProperties }
procedure TPSWeapon08GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4C9984 }

{ @routine $4C9988 TPSWeapon08GI_SetPosition }
procedure TPSWeapon08GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4C9988 }

{ @routine $4C99B4 TPSWeapon08GI_SetTargetPoint }
procedure TPSWeapon08GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4C99B4 }

{ @routine $4C99F0 TPSWeapon08GI_UpdateHitTestBounds }
procedure TPSWeapon08GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4C99F0 }

{ @routine $4C9A14 TPSWeapon08GI_SetActive }
procedure TPSWeapon08GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4C9A14 }

{ @routine $4C9A34 TPSWeapon08GI_ClearSavedBackground }
procedure TPSWeapon08GI.ClearSavedBackground;
var Particle: PWeapon08Particle; I: Integer;
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4C9A34 }

{ @routine $4C9ADC TPSWeapon08GI_ClearParticles }
procedure TPSWeapon08GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4C9ADC }

{ @routine $4C9B08 TPSWeapon08GI_GrowParticles }
procedure TPSWeapon08GI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon08Particle));
end;
{ @end $4C9B08 }

{ @routine $4C9B34 TPSWeapon08GI_AddParticle }
function TPSWeapon08GI.AddParticle: PWeapon08Particle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon08Particle));
  Inc(ParticleCount);
end;
{ @end $4C9B34 }

{ @routine $4C9B70 TPSWeapon08GI_Advance }
procedure TPSWeapon08GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var I, J, K: Integer; Particle: PWeapon08Particle; Speed: Single;
begin
  if RemainingTicks = 55 then begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    Speed := (OriginalLength + 128.0) / 55.0;
    for I := 0 to 1 do
      for J := 0 to 7 do
        for K := -10 to 10 do begin
          Particle := AddParticle;
          Particle.Kind := 2;
          Particle.Position.X := (J * 6 * 16 / OriginalLength + 4.0) * (K / 10.0);
          Particle.Position.Y := Sqrt(256 - Sqr(K)) + J * 16 - 128.0 + I;
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
    Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon08Particle));
    Dec(J);
  end;
  if RemainingTicks > 0 then Dec(RemainingTicks);
end;
{ @end $4C9B70 }

{ @routine $4C9D74 TPSWeapon08GI_ErasePreviousFrame }
procedure TPSWeapon08GI.ErasePreviousFrame;
var Particle: PWeapon08Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  if not BGImage then begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
      Dec(I);
    end;
  end else begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4C9D74 }

{ @routine $4C9E24 TPSWeapon08GI_PrepareFrameDraw }
procedure TPSWeapon08GI.PrepareFrameDraw;
var PX, PY, Sine, Cosine, Angle: Single;
  Buffer: Pointer; Pitch: Integer; Scale: Single;
  Particle: PWeapon08Particle; Count, X, Y: Integer;
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
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4C9E24 }

{ @routine $4C9FEC TPSWeapon08GI_DrawUpdateRects }
procedure TPSWeapon08GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4C9FEC }

{ @routine $4CA024 TPSWeapon08GI_Draw }
procedure TPSWeapon08GI.Draw(ClipRect: TRect);
var Particle: PWeapon08Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.Kind >= 2 then
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
    Dec(I);
  end;
end;
{ @end $4CA024 }

{ @routine $4CA088 TPSWeapon08GI_CommitFrameDraw }
procedure TPSWeapon08GI.CommitFrameDraw;
var Particle: PWeapon08Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon08Particle));
    Dec(I);
  end;
end;
{ @end $4CA088 }

{ @routine $4CA134 TPSWeapon08GI_IsFinished }
function TPSWeapon08GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4CA134 }

end.

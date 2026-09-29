unit GI_PSWeapon01;
// Unit bracket (inferred): CODE 0x004CACA0..0x004CB7F7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon01Particle = ^TWeapon01Particle;
  TWeapon01Particle = record // @size $28
    Kind: Integer; // @offset $0
    Position: TPointF; // @offset $4
    ByteOffset: Integer; // @offset $C
    PreviousByteOffset: Integer; // @offset $10
    Color: Word; // @offset $14
    SavedPixel: Word; // @offset $16
    Alpha: Byte; // @offset $18
    Velocity: TPointF; // @offset $1C
    FadeInTicks: Byte; // @offset $24
    InitialFadeInTicks: Byte; // @offset $25
    FadeOutThreshold: Byte; // @offset $26
  end;
  TPSWeapon01GI = class(TPSWeaponGI) // @size $124
  public
    Unknown110: Integer; // @offset $110
    Particles: PWeapon01Particle; // @offset $114
    ParticleCount: Integer; // @offset $118
    ParticleCapacity: Integer; // @offset $11C
    OriginalLength: Single; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $4CADC4
    destructor Destroy; override; // @addr $4CAE18
    procedure Invalidate; override; // @addr $4CAE4C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4CAE50
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4CAE7C
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4CAE98
    procedure SetPosition(Position: TPoint); override; // @addr $4CAE9C
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4CAEC8
    procedure UpdateHitTestBounds; override; // @addr $4CAF04
    procedure SetActive(Enabled: Boolean); override; // @addr $4CAF28
    procedure ClearSavedBackground; // @addr $4CAF48
    procedure ClearParticles; // @addr $4CAFE0
    procedure GrowParticles; // @addr $4CB00C
    function AddParticle: PWeapon01Particle; // @addr $4CB038
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4CB074
    procedure ErasePreviousFrame; override; // @addr $4CB404
    procedure PrepareFrameDraw; override; // @addr $4CB4A4
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4CB670
    procedure Draw(ClipRect: TRect); override; // @addr $4CB6A8
    procedure CommitFrameDraw; override; // @addr $4CB708
    function IsFinished: Boolean; override; // @addr $4CB7B4
  end;

implementation

// @unit-initialization $4CB7F0
// @unit-finalization $4CB7C0

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4CADC4 TPSWeapon01GI_Create }
constructor TPSWeapon01GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RemainingTicks := 40;
  LifetimeTicks := 40;
  Unknown110 := 0;
end;
{ @end $4CADC4 }

{ @routine $4CAE18 TPSWeapon01GI_Destroy }
destructor TPSWeapon01GI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4CAE18 }

{ @routine $4CAE4C TPSWeapon01GI_Invalidate }
procedure TPSWeapon01GI.Invalidate;
begin

end;
{ @end $4CAE4C }

{ @routine $4CAE50 TPSWeapon01GI_LoadFromConfigPath }
procedure TPSWeapon01GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4CAE50 }

{ @routine $4CAE7C TPSWeapon01GI_LoadFromBlock }
procedure TPSWeapon01GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4CAE7C }

{ @routine $4CAE98 TPSWeapon01GI_LoadEffectProperties }
procedure TPSWeapon01GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4CAE98 }

{ @routine $4CAE9C TPSWeapon01GI_SetPosition }
procedure TPSWeapon01GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4CAE9C }

{ @routine $4CAEC8 TPSWeapon01GI_SetTargetPoint }
procedure TPSWeapon01GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4CAEC8 }

{ @routine $4CAF04 TPSWeapon01GI_UpdateHitTestBounds }
procedure TPSWeapon01GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4CAF04 }

{ @routine $4CAF28 TPSWeapon01GI_SetActive }
procedure TPSWeapon01GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4CAF28 }

{ @routine $4CAF48 TPSWeapon01GI_ClearSavedBackground }
procedure TPSWeapon01GI.ClearSavedBackground;
var Particle: PWeapon01Particle; I: Integer;
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset, Particle.SavedPixel);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset);
        Particle.PreviousByteOffset := -1;
      end;
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4CAF48 }

{ @routine $4CAFE0 TPSWeapon01GI_ClearParticles }
procedure TPSWeapon01GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4CAFE0 }

{ @routine $4CB00C TPSWeapon01GI_GrowParticles }
procedure TPSWeapon01GI.GrowParticles;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon01Particle));
end;
{ @end $4CB00C }

{ @routine $4CB038 TPSWeapon01GI_AddParticle }
function TPSWeapon01GI.AddParticle: PWeapon01Particle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Result := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon01Particle));
  Inc(ParticleCount);
end;
{ @end $4CB038 }

{ @routine $4CB074 TPSWeapon01GI_Advance }
procedure TPSWeapon01GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Particle: PWeapon01Particle;
  Count, I: Integer;
  Y: Single;
begin
  if RemainingTicks = 40 then
  begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    for I := 0 to 3 do
    begin
      Y := 0;
      while Y < OriginalLength do
      begin
        Particle := AddParticle;
        if Random(2) = 0 then Particle.Position.X := -I
        else Particle.Position.X := I;
        Particle.Position.Y := Y;
        Particle.Kind := 1;
        Particle.ByteOffset := -1;
        Particle.PreviousByteOffset := -1;
        Particle.Alpha := 0;
        Particle.InitialFadeInTicks := 11 - I;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := 7.0 - I * 2;
        Particle.FadeOutThreshold := Trunc(Sin(Pi * Y / 40.0) * 8.0 + 20.0);
        case I of
          0: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 1.0, 0.0);
          1: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.7, 0.7, 0.2);
          2: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.4, 0.4, 0.4);
          3: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(0.3, 0.2, 0.7);
        end;
        Y := Y + 1.5 + I;
      end;
    end;
  end;
  Particle := Particles;
  Count := ParticleCount;
  I := 0;
  while Count > 0 do
  begin
    if Particle.Kind = 1 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
      end
      else
      begin
        Inc(Particle.Alpha, 20);
        Dec(Particle.FadeInTicks);
        if Particle.FadeInTicks = 0 then
        begin
          Particle.FadeInTicks := 100;
          Particle.Kind := 2;
        end;
      end;
      if RemainingTicks < Particle.FadeOutThreshold then Particle.Kind := 3;
    end
    else if Particle.Kind = 2 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if OriginalLength - 32.0 < Particle.Position.Y then
      begin
        if Particle.Alpha < 245 then Inc(Particle.Alpha, 10)
        else Particle.Alpha := 255;
      end;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
        Particle.FadeInTicks := Particle.InitialFadeInTicks;
        Particle.Kind := 1;
      end;
      if RemainingTicks < Particle.FadeOutThreshold then Particle.Kind := 3;
    end
    else if Particle.Kind = 3 then
    begin
      Particle.Position.X := Particle.Position.X + Particle.Velocity.X;
      Particle.Position.Y := Particle.Position.Y + Particle.Velocity.Y;
      if Particle.Position.Y > OriginalLength then
      begin
        Particle.Position.Y := Particle.Position.Y - OriginalLength;
        Particle.Alpha := 0;
      end;
      if Particle.Alpha > 12 then Dec(Particle.Alpha, 12)
      else Particle.Alpha := 0;
    end;
    Inc(I);
    Particle := AddPointerOffset(Particles, I * SizeOf(TWeapon01Particle));
    Dec(Count);
  end;
  Dec(RemainingTicks);
end;
{ @end $4CB074 }

{ @routine $4CB404 TPSWeapon01GI_ErasePreviousFrame }
procedure TPSWeapon01GI.ErasePreviousFrame;
var Particle: PWeapon01Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  Particle := Particles;
  I := ParticleCount;
  if not BGImage then begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
      Dec(I);
    end;
  end else begin
    while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4CB404 }

{ @routine $4CB4A4 TPSWeapon01GI_PrepareFrameDraw }
procedure TPSWeapon01GI.PrepareFrameDraw;
var Buffer: Pointer; PX, PY, Sine, Cosine, Angle: Single;
  Pitch: Integer; Scale: Single;
  Particle: PWeapon01Particle; Count, X, Y, Offset: Integer;
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
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4CB4A4 }

{ @routine $4CB670 TPSWeapon01GI_DrawUpdateRects }
procedure TPSWeapon01GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4CB670 }

{ @routine $4CB6A8 TPSWeapon01GI_Draw }
procedure TPSWeapon01GI.Draw(ClipRect: TRect);
var Particle: PWeapon01Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
    Dec(I);
  end;
end;
{ @end $4CB6A8 }

{ @routine $4CB708 TPSWeapon01GI_CommitFrameDraw }
procedure TPSWeapon01GI.CommitFrameDraw;
var Particle: PWeapon01Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon01Particle));
    Dec(I);
  end;
end;
{ @end $4CB708 }

{ @routine $4CB7B4 TPSWeapon01GI_IsFinished }
function TPSWeapon01GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4CB7B4 }

end.

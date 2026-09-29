unit GI_PSWeapon06;
// Unit bracket (inferred): CODE 0x004C6744..0x004C73AB; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWeapon06Particle = ^TWeapon06Particle;
  TWeapon06Particle = record // @size $3C
    Next: PWeapon06Particle; // @offset $0
    Prev: PWeapon06Particle; // @offset $4
    Kind: Byte; // @offset $8
    Position: TPointF; // @offset $C
    Incoming: Single; // @offset $14
    Displacement: Single; // @offset $18
    Reflected: Single; // @offset $1C
    Color: Word; // @offset $20
    Alpha: Byte; // @offset $22
    Phase: Single; // @offset $24
    PhaseStep: Single; // @offset $28
    PhaseCountdown: Byte; // @offset $2C
    ByteOffset: Integer; // @offset $30
    PreviousByteOffset: Integer; // @offset $34
    SavedPixel: Word; // @offset $38
  end;
  TPSWeapon06GI = class(TPSWeaponGI) // @size $120
  public
    Particles: PWeapon06Particle; // @offset $110
    ParticleCount: Integer; // @offset $114
    ParticleCapacity: Integer; // @offset $118
    OriginalLength: Single; // @offset $11C

    constructor Create(Owner: TObjectGI); // @addr $4C6868
    destructor Destroy; override; // @addr $4C68B4
    procedure Invalidate; override; // @addr $4C68E8
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4C68EC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4C6918
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4C6934
    procedure SetPosition(Position: TPoint); override; // @addr $4C6938
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4C6964
    procedure UpdateHitTestBounds; override; // @addr $4C69A0
    procedure SetActive(Enabled: Boolean); override; // @addr $4C69C4
    procedure ClearSavedBackground; // @addr $4C69E4
    procedure ClearParticles; // @addr $4C6A8C
    procedure GrowParticles; // @addr $4C6AB8
    function AddParticle: PWeapon06Particle; // @addr $4C6B28
    procedure AdvanceWave; // @addr $4C6B98
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4C6CA4
    procedure ErasePreviousFrame; override; // @addr $4C6F78
    procedure PrepareFrameDraw; override; // @addr $4C7028
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4C7220
    procedure Draw(ClipRect: TRect); override; // @addr $4C7258
    procedure CommitFrameDraw; override; // @addr $4C72BC
    function IsFinished: Boolean; override; // @addr $4C7368
  end;

implementation

// @unit-initialization $4C73A4
// @unit-finalization $4C7374

uses aMyFunction, Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4C6868 TPSWeapon06GI_Create }
constructor TPSWeapon06GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RemainingTicks := 60;
  LifetimeTicks := 60;
end;
{ @end $4C6868 }

{ @routine $4C68B4 TPSWeapon06GI_Destroy }
destructor TPSWeapon06GI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  inherited Destroy;
end;
{ @end $4C68B4 }

{ @routine $4C68E8 TPSWeapon06GI_Invalidate }
procedure TPSWeapon06GI.Invalidate;
begin

end;
{ @end $4C68E8 }

{ @routine $4C68EC TPSWeapon06GI_LoadFromConfigPath }
procedure TPSWeapon06GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4C68EC }

{ @routine $4C6918 TPSWeapon06GI_LoadFromBlock }
procedure TPSWeapon06GI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4C6918 }

{ @routine $4C6934 TPSWeapon06GI_LoadEffectProperties }
procedure TPSWeapon06GI.LoadEffectProperties(Block: TBlockParEC);
begin
end;
{ @end $4C6934 }

{ @routine $4C6938 TPSWeapon06GI_SetPosition }
procedure TPSWeapon06GI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then inherited SetPosition(Position);
end;
{ @end $4C6938 }

{ @routine $4C6964 TPSWeapon06GI_SetTargetPoint }
procedure TPSWeapon06GI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
  end;
end;
{ @end $4C6964 }

{ @routine $4C69A0 TPSWeapon06GI_UpdateHitTestBounds }
procedure TPSWeapon06GI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  HitTestBounds.Right := GameScreenWidth;
  HitTestBounds.Bottom := GameScreenHeight;
end;
{ @end $4C69A0 }

{ @routine $4C69C4 TPSWeapon06GI_SetActive }
procedure TPSWeapon06GI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if not Enabled then ClearSavedBackground;
end;
{ @end $4C69C4 }

{ @routine $4C69E4 TPSWeapon06GI_ClearSavedBackground }
procedure TPSWeapon06GI.ClearSavedBackground;
var Particle: PWeapon06Particle; I: Integer;
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
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
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
      Dec(I);
    end;
  end;
end;
{ @end $4C69E4 }

{ @routine $4C6A8C TPSWeapon06GI_ClearParticles }
procedure TPSWeapon06GI.ClearParticles;
begin
  if Particles <> nil then begin
    FreeEC(Particles);
    Particles := nil;
  end;
  ParticleCount := 0;
  ParticleCapacity := 0;
end;
{ @end $4C6A8C }

{ @routine $4C6AB8 TPSWeapon06GI_GrowParticles }
procedure TPSWeapon06GI.GrowParticles;
var
  Index: Integer;
  Particle, Previous, Following: PWeapon06Particle;
begin
  Inc(ParticleCapacity, 100);
  Particles := ReAllocREC(Particles, ParticleCapacity * SizeOf(TWeapon06Particle));
  Particle := Particles;
  Previous := nil;
  for Index := 0 to ParticleCount - 1 do
  begin
    if Index < ParticleCount - 1 then Following := AddPointerOffset(Particle, SizeOf(TWeapon06Particle))
    else Following := nil;
    Particle.Next := Following;
    Particle.Prev := Previous;
    Previous := Particle;
    Particle := Following;
  end;
end;
{ @end $4C6AB8 }

{ @routine $4C6B28 TPSWeapon06GI_AddParticle }
function TPSWeapon06GI.AddParticle: PWeapon06Particle;
var
  Previous, Particle: PWeapon06Particle;
begin
  if ParticleCount >= ParticleCapacity then GrowParticles;
  Particle := AddPointerOffset(Particles, ParticleCount * SizeOf(TWeapon06Particle));
  if ParticleCount = 0 then Previous := nil
  else Previous := AddPointerOffset(Particles, (ParticleCount - 1) * SizeOf(TWeapon06Particle));
  Result := Particle;
  Inc(ParticleCount);
  Particle.Next := nil;
  Particle.Prev := Previous;
  if Previous <> nil then Previous.Next := Particle;
end;
{ @end $4C6B28 }

{ @routine $4C6B98 TPSWeapon06GI_AdvanceWave }
procedure TPSWeapon06GI.AdvanceWave;
var Particle: PWeapon06Particle; Count, Index: Integer;
begin
  Index := 0;
  Particle := Particles;
  Count := ParticleCount;
  while Count > 0 do begin
    if Particle.Kind = 1 then begin
        if Particle.Next <> nil then Particle.Next.Incoming := Particle.Displacement;
        Dec(Particle.PhaseCountdown);
        if Particle.PhaseCountdown = 0 then begin
          Particle.PhaseCountdown := 16;
          Particle.PhaseStep := RandomFloatRange(Pi / 10, Pi / 5);
        end;
        Particle.Phase := Particle.Phase + Particle.PhaseStep;
        if 2 * Pi <= Particle.Phase then Particle.Phase := Particle.Phase - 2 * Pi;
        Particle.Displacement := Sin(Particle.Phase) * 3.0;
    end else if Particle.Kind = 2 then begin
        if Particle.Next <> nil then Particle.Next.Incoming := Particle.Displacement;
        if Particle.Prev <> nil then Particle.Prev.Reflected := Particle.Reflected;
        Particle.Displacement := Particle.Incoming;
    end else if Particle.Kind = 3 then begin
        if Particle.Prev <> nil then Particle.Prev.Reflected := Particle.Reflected;
        Particle.Reflected := -Particle.Incoming;
        Particle.Displacement := Particle.Incoming;
    end;
    Inc(Index);
    Particle := AddPointerOffset(Particles, Index * SizeOf(TWeapon06Particle));
    Dec(Count);
  end;
end;
{ @end $4C6B98 }

{ @routine $4C6CA4 TPSWeapon06GI_Advance }
procedure TPSWeapon06GI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Particle: PWeapon06Particle;
  Index, Step: Integer;
begin
  if RemainingTicks = 60 then
  begin
    OriginalLength := Sqrt(Sqr(LocalPosition.X - TargetPoint.X) + Sqr(LocalPosition.Y - TargetPoint.Y));
    ClearParticles;
    Particle := AddParticle;
    Particle.Kind := 1;
    Particle.Position := MakePointF(0, 16);
    Particle.Incoming := 0;
    Particle.Displacement := 0;
    Particle.Reflected := 0;
    Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.5, 0.33);
    Particle.Alpha := 0;
    Particle.Phase := 0;
    Particle.ByteOffset := -1;
    Particle.PreviousByteOffset := -1;
    Particle.SavedPixel := 0;
    Particle.PhaseCountdown := 1;
    Particle.PhaseStep := Pi / 8;
    Index := 17;
    while Index < OriginalLength do
    begin
      Particle := AddParticle;
      Particle.Kind := 2;
      Particle.Position := MakePointF(0, Index);
      Particle.Incoming := 0;
      Particle.Displacement := 0;
      Particle.Reflected := 0;
      case Random(2) of
        0: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.5, 0.33);
        1: Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.7, 0.5);
      end;
      if Particle.Position.Y < 32.0 then Particle.Alpha := Trunc(Particle.Position.Y * 255.0) shr 5
      else Particle.Alpha := 255;
      Particle.ByteOffset := -1;
      Particle.PreviousByteOffset := -1;
      Particle.SavedPixel := 0;
      Inc(Index);
    end;
    Particle := AddParticle;
    Particle.Kind := 3;
    Particle.Position := MakePointF(0, OriginalLength);
    Particle.Incoming := 0;
    Particle.Displacement := 0;
    Particle.Reflected := 0;
    Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.5, 0.33);
    if Particle.Position.Y < 32.0 then Particle.Alpha := Trunc(Particle.Position.Y * 255.0) shr 5
    else Particle.ByteOffset := -1; // Native leaves this final particle's alpha unchanged here.
    Particle.PreviousByteOffset := -1;
    Particle.SavedPixel := 0;
    for Step := 1 to Trunc(0.3 * OriginalLength) do AdvanceWave;
  end;
  for Step := 1 to 6 do AdvanceWave;
  if RemainingTicks > 0 then Dec(RemainingTicks);
end;
{ @end $4C6CA4 }

{ @routine $4C6F78 TPSWeapon06GI_ErasePreviousFrame }
procedure TPSWeapon06GI.ErasePreviousFrame;
var Particle: PWeapon06Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
  if not BGImage then begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), 0);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
      Dec(I);
    end;
  end else begin
    Particle := Particles;
    I := ParticleCount;
  while I > 0 do begin
      if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset), Particle.SavedPixel);
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
      Dec(I);
    end;
  end;
  end;
end;
{ @end $4C6F78 }

{ @routine $4C7028 TPSWeapon06GI_PrepareFrameDraw }
procedure TPSWeapon06GI.PrepareFrameDraw;
var PX, PY, Sine, Cosine, Angle: Single;
  Buffer: Pointer; Pitch: Integer; Scale: Single;
  Particle: PWeapon06Particle; Count, X, Y: Integer;
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
    if (Particle.Kind >= 1) and (Particle.Kind <= 3) then begin
      Particle.Position.X := Particle.Displacement + Particle.Reflected;
      PX := Particle.Position.X;
      PY := Particle.Position.Y * Scale;
      X := Trunc(PX * Cosine + PY * Sine) + AbsolutePosition.X;
      Y := Trunc(PX * Sine - PY * Cosine) + AbsolutePosition.Y;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset := X * 2 + Y * Pitch;
    end;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
    Dec(Count);
  end;
  if BGImage then begin
    Particle := Particles;
    Count := ParticleCount;
    while Count > 0 do begin
      if Particle.ByteOffset >= 0 then Particle.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset));
      Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
      Dec(Count);
    end;
  end;
end;
{ @end $4C7028 }

{ @routine $4C7220 TPSWeapon06GI_DrawUpdateRects }
procedure TPSWeapon06GI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4C7220 }

{ @routine $4C7258 TPSWeapon06GI_Draw }
procedure TPSWeapon06GI.Draw(ClipRect: TRect);
var Particle: PWeapon06Particle; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.Kind >= 1 then
    if Particle.ByteOffset >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset), Particle.Color, Particle.Alpha);
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
    Dec(I);
  end;
end;
{ @end $4C7258 }

{ @routine $4C72BC TPSWeapon06GI_CommitFrameDraw }
procedure TPSWeapon06GI.CommitFrameDraw;
var Particle: PWeapon06Particle; I: Integer; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := Particles;
  I := ParticleCount;
  while I > 0 do begin
    if Particle.PreviousByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset)));
    if Particle.ByteOffset >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset)));
    Particle.PreviousByteOffset := Particle.ByteOffset;
    Particle := AddPointerOffset(Particle, SizeOf(TWeapon06Particle));
    Dec(I);
  end;
end;
{ @end $4C72BC }

{ @routine $4C7368 TPSWeapon06GI_IsFinished }
function TPSWeapon06GI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4C7368 }

end.

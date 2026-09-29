unit GI_PSWind;
// Unit bracket (inferred): CODE 0x004A0348..0x004A15E7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PWindParticle = ^TWindParticle;
  TWindParticle = record // @size $3C
    Prev: PWindParticle; // @offset $0
    Next: PWindParticle; // @offset $4
    Position: TPointF; // @offset $8
    Color: Word; // @offset $10
    ByteOffset1: Integer; // @offset $14
    ByteOffset2: Integer; // @offset $18
    PreviousByteOffset1: Integer; // @offset $1C
    PreviousByteOffset2: Integer; // @offset $20
    SavedPixel1: Word; // @offset $24
    SavedPixel2: Word; // @offset $26
    Alpha: Byte; // @offset $28
    MaximumAlpha: Byte; // @offset $29
    AlphaStep: Integer; // @offset $2C
    Velocity: TPointF; // @offset $30
    State: Byte; // @offset $38
  end;
  TPSWindGI = class(TPSWeaponGI) // @size $150
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PWindParticle; // @offset $114
    LastParticle: PWindParticle; // @offset $118
    CallbackTimer: TCallbackTimerIdGI; // @offset $120
    Color1: Word; // @offset $124
    Color2: Word; // @offset $126
    Color3: Word; // @offset $128
    ProjectionBounds: TRect; // @offset $12A Native projection rectangle, independently read by both bounds methods.
    LengthScale: Double; // @offset $140
    OriginalLength: Double; // @offset $148

    constructor Create(Owner: TObjectGI); // @addr $4A0468
    destructor Destroy; override; // @addr $4A0568
    procedure SetPosition(Position: TPoint); override; // @addr $4A05A4
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4A05DC
    procedure SetHalfWidth(Value: Integer); // @addr $4A061C
    procedure RestartTimer; // @addr $4A0630
    procedure CancelTimer; // @addr $4A0634
    procedure SetActive(Enabled: Boolean); override; // @addr $4A0658
    procedure UpdateProjectionBounds; // @addr $4A0690
    procedure UpdateHitTestBounds; override; // @addr $4A0914
    function GetLocalBounds: TRect; override; // @addr $4A0948
    function AddParticle: PWindParticle; // @addr $4A0978
    procedure ClearParticles; // @addr $4A09B8
    procedure InvalidateRect(Rect: TRect); override; // @addr $4A09E8
    procedure Invalidate; override; // @addr $4A0AA4
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A0AA8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A0AD4
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4A0AF0
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4A0CB0
    function IsFinished: Boolean; override; // @addr $4A10A4
    procedure ClearSavedBackground; // @addr $4A10B0
    procedure ErasePreviousFrame; override; // @addr $4A1184
    procedure PrepareFrameDraw; override; // @addr $4A1250
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4A1404
    procedure Draw(ClipRect: TRect); override; // @addr $4A143C
    procedure CommitFrameDraw; override; // @addr $4A14B0
  end;

implementation

// @unit-initialization $4A15E0
// @unit-finalization $4A15B0

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4A0468 TPSWindGI_Create }
constructor TPSWindGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 4;
  RemainingTicks := 38;
  LifetimeTicks := RemainingTicks;
  LengthScale := 1;
  OriginalLength := 1;
  UpdateProjectionBounds;
  RestartTimer;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(0, 1, 0.9);
  Color2 := CurrentPixelFormat.PackNormalizedRgb(0, 0.2, 1);
  Color3 := CurrentPixelFormat.PackNormalizedRgb(1, 1, 0);
end;
{ @end $4A0468 }

{ @routine $4A0568 TPSWindGI_Destroy }
destructor TPSWindGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $4A0568 }

{ @routine $4A05A4 TPSWindGI_SetPosition }
procedure TPSWindGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $4A05A4 }

{ @routine $4A05DC TPSWindGI_SetTargetPoint }
procedure TPSWindGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A05DC }

{ @routine $4A061C TPSWindGI_SetHalfWidth }
procedure TPSWindGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A061C }

{ @routine $4A0630 TPSWindGI_RestartTimer }
procedure TPSWindGI.RestartTimer;
begin
end;
{ @end $4A0630 }

{ @routine $4A0634 TPSWindGI_CancelTimer }
procedure TPSWindGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $4A0634 }

{ @routine $4A0658 TPSWindGI_SetActive }
procedure TPSWindGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $4A0658 }

{ @routine $4A0690 TPSWindGI_UpdateProjectionBounds }
procedure TPSWindGI.UpdateProjectionBounds;
var
  Angle, Sine, Cosine, Distance, A, B, C, D: Single;
  DY: Integer;
begin
  DY := -(TargetPoint.Y - LocalPosition.Y);
  if DY = 0 then Inc(DY);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, DY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
  A := (-HalfWidth - 12) * Cosine - -Distance * Sine;
  B := (HalfWidth + 12) * Cosine - -Distance * Sine;
  C := (-HalfWidth - 12) * Cosine;
  D := (HalfWidth + 12) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth - 12) * Sine + -Distance * Cosine;
  B := (HalfWidth + 12) * Sine + -Distance * Cosine;
  C := (-HalfWidth - 12) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth + 12) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;
{ @end $4A0690 }

{ @routine $4A0914 TPSWindGI_UpdateHitTestBounds }
procedure TPSWindGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $4A0914 }

{ @routine $4A0948 TPSWindGI_GetLocalBounds }
function TPSWindGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $4A0948 }

{ @routine $4A0978 TPSWindGI_AddParticle }
function TPSWindGI.AddParticle: PWindParticle;
var Particle: PWindParticle;
begin
  Particle := AllocEC(SizeOf(TWindParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $4A0978 }

{ @routine $4A09B8 TPSWindGI_ClearParticles }
procedure TPSWindGI.ClearParticles;
var Particle, Current: PWindParticle;
begin
  Particle := FirstParticle;
  while Particle <> nil do begin
    Current := Particle;
    Particle := Particle.Next;
    FreeEC(Current);
  end;
  FirstParticle := nil;
  LastParticle := nil;
end;
{ @end $4A09B8 }

{ @routine $4A09E8 TPSWindGI_InvalidateRect }
procedure TPSWindGI.InvalidateRect(Rect: TRect);
var Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(HitTestBounds,
    Parent.ToAbsolutePoint(LocalPosition), Parent.ToAbsolutePoint(TargetPoint), HalfWidth);
  with Parent.ToAbsolutePoint(TargetPoint) do begin
    Rect.Left := X - 24;
    Rect.Right := X + 24;
    Rect.Top := Y - 24;
    Rect.Bottom := Y + 24;
  end;
  if IntersectRects(Intersection, Rect, GameScreenRect) then MessageLoop.QueueUpdateRect(Intersection);
end;
{ @end $4A09E8 }

{ @routine $4A0AA4 TPSWindGI_Invalidate }
procedure TPSWindGI.Invalidate;
begin

end;
{ @end $4A0AA4 }

{ @routine $4A0AA8 TPSWindGI_LoadFromConfigPath }
procedure TPSWindGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4A0AA8 }

{ @routine $4A0AD4 TPSWindGI_LoadFromBlock }
procedure TPSWindGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4A0AD4 }

{ @routine $4A0AF0 TPSWindGI_LoadEffectProperties }
procedure TPSWindGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
  if Block.CountParams('Color2') > 0 then Color2 := GetColorGI(Block.GetParam('Color2'));
  if Block.CountParams('Color3') > 0 then Color3 := GetColorGI(Block.GetParam('Color3'));
end;
{ @end $4A0AF0 }

{ @routine $4A0CB0 TPSWindGI_Advance }
procedure TPSWindGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Y: Integer;
  Distance: Single;
  Particle, Current: PWindParticle;
  UnusedAlpha: Byte;
begin
  if (FirstParticle = nil) and (RemainingTicks >= 2) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    UnusedAlpha := 0;
    while Y < Distance do
    begin
      Particle := AddParticle;
      Particle.Position := MakePointF(Random(HalfWidth * 2) - HalfWidth, Y);
      case Random(3) of
        0: Particle.Color := Color1;
        1: Particle.Color := Color2;
        2: Particle.Color := Color3;
      end;
      Particle.MaximumAlpha := Random(250);
      if Y < 64 then Particle.Alpha := Trunc(Particle.MaximumAlpha * Y) shr 6
      else Particle.Alpha := Particle.MaximumAlpha;
      Particle.AlphaStep := Random(10) + 10;
      Particle.Velocity := MakePointF(0, 3);
      Particle.State := 1 + Random(2);
      Particle.ByteOffset1 := -1;
      Particle.ByteOffset2 := -1;
      Particle.PreviousByteOffset1 := -1;
      Particle.PreviousByteOffset2 := -1;
      if UnusedAlpha + 4 < 255 then Inc(UnusedAlpha, 4)
      else UnusedAlpha := 255;
      Inc(Y);
    end;
  end
  else
  begin
    Distance := OriginalLength;
    LengthScale := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)) / OriginalLength;
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
        1:
        begin
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          if Distance + 16.0 < Current.Position.Y then
        begin
            Current.Position.Y := Current.Position.Y - Distance;
            Current.Position.X := Random(HalfWidth * 2) - HalfWidth;
            Current.Velocity := MakePointF(0, 3);
        end;
        if Current.MaximumAlpha > 254 - Current.AlphaStep then Current.MaximumAlpha := 255
        else Inc(Current.MaximumAlpha, Current.AlphaStep);
        if Current.Position.Y < 64.0 then Current.Alpha := Trunc(Current.MaximumAlpha * Current.Position.Y) shr 6
        else Current.Alpha := Current.MaximumAlpha;
        if Current.MaximumAlpha = 255 then Current.State := 2;
        end;
        2:
        begin
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          if Distance + 16.0 < Current.Position.Y then
        begin
            Current.Position.Y := Current.Position.Y - Distance;
            Current.Position.X := Random(HalfWidth * 2) - HalfWidth;
            Current.Velocity := MakePointF(0, 3);
        end;
        if Current.MaximumAlpha < Current.AlphaStep then Current.MaximumAlpha := 0
        else Dec(Current.MaximumAlpha, Current.AlphaStep);
        if Current.Position.Y < 64.0 then Current.Alpha := Trunc(Current.MaximumAlpha * Current.Position.Y) shr 6
        else Current.Alpha := Current.MaximumAlpha;
        if Current.MaximumAlpha = 0 then Current.State := 1;
        end;
      end;
    end;
  end;
  Dec(RemainingTicks);
end;
{ @end $4A0CB0 }

{ @routine $4A10A4 TPSWindGI_IsFinished }
function TPSWindGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4A10A4 }

{ @routine $4A10B0 TPSWindGI_ClearSavedBackground }
procedure TPSWindGI.ClearSavedBackground;
var Particle: PWindParticle;
begin
  if BGImage then begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, Particle.SavedPixel1);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
      end;
      if Particle.PreviousByteOffset2 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset2, Particle.SavedPixel2);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset2);
        Particle.PreviousByteOffset2 := -1;
      end;
      Particle := Particle.Next;
    end;
  end else begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
      end;
      if Particle.PreviousByteOffset2 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset2, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset2);
        Particle.PreviousByteOffset2 := -1;
      end;
      Particle := Particle.Next;
    end;
  end;
end;
{ @end $4A10B0 }

{ @routine $4A1184 TPSWindGI_ErasePreviousFrame }
procedure TPSWindGI.ErasePreviousFrame;
var Particle: PWindParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
    if BGImage then begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), Particle.SavedPixel1);
        if Particle.PreviousByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset2), Particle.SavedPixel2);
        Particle := Particle.Next;
      end;
    end else begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), 0);
        if Particle.PreviousByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset2), 0);
        Particle := Particle.Next;
      end;
    end;
  end;
end;
{ @end $4A1184 }

{ @routine $4A1250 TPSWindGI_PrepareFrameDraw }
procedure TPSWindGI.PrepareFrameDraw;
var
  Angle, Sine, Cosine, PX, PY: Single;
  X, Y: Integer;
  Particle: PWindParticle;
  Buffer: Pointer;
  Pitch: Integer;
begin
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then Inc(Y);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Particle := FirstParticle;
  while Particle <> nil do begin
    Particle.ByteOffset1 := -1;
    Particle.ByteOffset2 := -1;
    PX := Particle.Position.X;
    PY := -Particle.Position.Y * LengthScale;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset1 := X * 2 + Y * Pitch;
    if ((X - 1) >= 0) and ((X - 1) < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset2 := (X - 1) * 2 + Y * Pitch;
    Particle := Particle.Next;
  end;
  if BGImage then begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.ByteOffset1 >= 0 then Particle.SavedPixel1 := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1));
      if Particle.ByteOffset2 >= 0 then Particle.SavedPixel2 := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset2));
      Particle := Particle.Next;
    end;
  end;
end;
{ @end $4A1250 }

{ @routine $4A1404 TPSWindGI_DrawUpdateRects }
procedure TPSWindGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4A1404 }

{ @routine $4A143C TPSWindGI_Draw }
procedure TPSWindGI.Draw(ClipRect: TRect);
var Particle: PWindParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    if Particle.ByteOffset2 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset2), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $4A143C }

{ @routine $4A14B0 TPSWindGI_CommitFrameDraw }
procedure TPSWindGI.CommitFrameDraw;
var Particle: PWindParticle; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1)));
    if Particle.PreviousByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset2), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset2)));
    if Particle.ByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1)));
    if Particle.ByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset2), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset2)));
    Particle.PreviousByteOffset1 := Particle.ByteOffset1;
    Particle.PreviousByteOffset2 := Particle.ByteOffset2;
    Particle := Particle.Next;
  end;
end;
{ @end $4A14B0 }

end.

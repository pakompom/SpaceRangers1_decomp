unit GI_LaserCannonRay;
// Unit bracket (inferred): CODE 0x0049BEA8..0x0049D3FF; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PLaserCannonRayParticle = ^TLaserCannonRayParticle;
  TLaserCannonRayParticle = record // @size $30
    Prev: PLaserCannonRayParticle; // @offset $0
    Next: PLaserCannonRayParticle; // @offset $4
    Position: TPointF; // @offset $8
    Color: Word; // @offset $10
    SavedPixel1: Word; // @offset $12
    Alpha: Byte; // @offset $14
    Velocity: TPointF; // @offset $18
    State: Byte; // @offset $20
    RemainingTicks: Word; // @offset $22
    ByteOffset1: Integer; // @offset $24
    PreviousByteOffset1: Integer; // @offset $28
    BaseAlpha: Integer; // @offset $2C
  end;
  TPSLaserCannonRayGI = class(TPSWeaponGI) // @size $158
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    Period: Integer; // @offset $114
    PeriodMask: Integer; // @offset $118
    FirstParticle: PLaserCannonRayParticle; // @offset $11C
    LastParticle: PLaserCannonRayParticle; // @offset $120
    PendingSparkSteps: Integer; // @offset $124
    TimerInterval: Integer; // @offset $128
    CallbackTimer: TCallbackTimerIdGI; // @offset $12C
    Color: Word; // @offset $130
    ProjectionBounds: TRect; // @offset $132 Native projection rectangle, independently read by both bounds methods.
    LengthScale: Double; // @offset $148
    OriginalLength: Double; // @offset $150

    constructor Create(Owner: TObjectGI); // @addr $49BFD0
    destructor Destroy; override; // @addr $49C0A8
    procedure SetPeriod(Value: Integer); // @addr $49C0E4
    procedure SetPosition(Position: TPoint); override; // @addr $49C0F4
    procedure SetTargetPoint(Point: TPoint); override; // @addr $49C12C
    procedure SetHalfWidth(Value: Integer); // @addr $49C16C
    procedure SetTimerInterval(Value: Integer); // @addr $49C180
    procedure RestartTimer; // @addr $49C190
    procedure CancelTimer; // @addr $49C194
    procedure SetActive(Enabled: Boolean); override; // @addr $49C1B8
    procedure UpdateProjectionBounds; // @addr $49C1F0
    procedure UpdateHitTestBounds; override; // @addr $49C46C
    function GetLocalBounds: TRect; override; // @addr $49C4AC
    function AddParticle: PLaserCannonRayParticle; // @addr $49C4DC
    procedure RemoveParticle(Particle: PLaserCannonRayParticle); // @addr $49C51C
    procedure ClearParticles; // @addr $49C564
    procedure Invalidate; override; // @addr $49C594
    procedure InvalidateRect(Rect: TRect); override; // @addr $49C598
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49C654
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49C680
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $49C69C
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $49C898
    procedure AdvanceImpactSparks(ClipRect: TRect); // @addr $49CC90
    function IsFinished: Boolean; override; // @addr $49CF88
    procedure ErasePreviousFrame; override; // @addr $49CF94
    procedure PrepareFrameDraw; override; // @addr $49D014
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $49D234
    procedure Draw(ClipRect: TRect); override; // @addr $49D26C
    procedure CommitFrameDraw; override; // @addr $49D2B8
    procedure ClearSavedBackground; // @addr $49D34C
  end;

implementation

// @unit-initialization $49D3F8
// @unit-finalization $49D3C8

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $49BFD0 TPSLaserCannonRayGI_Create }
constructor TPSLaserCannonRayGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 4;
  TimerInterval := 45;
  Period := 32;
  LengthScale := 1;
  OriginalLength := 1;
  PeriodMask := Period - 1;
  UpdateProjectionBounds;
  PendingSparkSteps := 0;
  Color := CurrentPixelFormat.PackNormalizedRgb(1, 1, 0.1);
  RemainingTicks := 50;
  LifetimeTicks := RemainingTicks;
end;
{ @end $49BFD0 }

{ @routine $49C0A8 TPSLaserCannonRayGI_Destroy }
destructor TPSLaserCannonRayGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $49C0A8 }

{ @routine $49C0E4 TPSLaserCannonRayGI_SetPeriod }
procedure TPSLaserCannonRayGI.SetPeriod(Value: Integer);
begin
  Period := Value;
  PeriodMask := Period - 1;
end;
{ @end $49C0E4 }

{ @routine $49C0F4 TPSLaserCannonRayGI_SetPosition }
procedure TPSLaserCannonRayGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $49C0F4 }

{ @routine $49C12C TPSLaserCannonRayGI_SetTargetPoint }
procedure TPSLaserCannonRayGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $49C12C }

{ @routine $49C16C TPSLaserCannonRayGI_SetHalfWidth }
procedure TPSLaserCannonRayGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $49C16C }

{ @routine $49C180 TPSLaserCannonRayGI_SetTimerInterval }
procedure TPSLaserCannonRayGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; end;
end;
{ @end $49C180 }

{ @routine $49C190 TPSLaserCannonRayGI_RestartTimer }
procedure TPSLaserCannonRayGI.RestartTimer;
begin

end;
{ @end $49C190 }

{ @routine $49C194 TPSLaserCannonRayGI_CancelTimer }
procedure TPSLaserCannonRayGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $49C194 }

{ @routine $49C1B8 TPSLaserCannonRayGI_SetActive }
procedure TPSLaserCannonRayGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $49C1B8 }

{ @routine $49C1F0 TPSLaserCannonRayGI_UpdateProjectionBounds }
procedure TPSLaserCannonRayGI.UpdateProjectionBounds;
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
  A := (-HalfWidth * 2) * Cosine - -Distance * Sine;
  B := (HalfWidth * 2) * Cosine - -Distance * Sine;
  C := (-HalfWidth * 2) * Cosine;
  D := (HalfWidth * 2) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth * 2) * Sine + -Distance * Cosine;
  B := (HalfWidth * 2) * Sine + -Distance * Cosine;
  C := (-HalfWidth * 2) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth * 2) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;
{ @end $49C1F0 }

{ @routine $49C46C TPSLaserCannonRayGI_UpdateHitTestBounds }
procedure TPSLaserCannonRayGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X - 32;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y - 32;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X + 32;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y + 32;
end;
{ @end $49C46C }

{ @routine $49C4AC TPSLaserCannonRayGI_GetLocalBounds }
function TPSLaserCannonRayGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $49C4AC }

{ @routine $49C4DC TPSLaserCannonRayGI_AddParticle }
function TPSLaserCannonRayGI.AddParticle: PLaserCannonRayParticle;
var Particle: PLaserCannonRayParticle;
begin
  Particle := AllocEC(SizeOf(TLaserCannonRayParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $49C4DC }

{ @routine $49C51C TPSLaserCannonRayGI_RemoveParticle }
procedure TPSLaserCannonRayGI.RemoveParticle(Particle: PLaserCannonRayParticle);
begin
  if Particle <> nil then begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
  end;
end;
{ @end $49C51C }

{ @routine $49C564 TPSLaserCannonRayGI_ClearParticles }
procedure TPSLaserCannonRayGI.ClearParticles;
var Particle, Current: PLaserCannonRayParticle;
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
{ @end $49C564 }

{ @routine $49C594 TPSLaserCannonRayGI_Invalidate }
procedure TPSLaserCannonRayGI.Invalidate;
begin

end;
{ @end $49C594 }

{ @routine $49C598 TPSLaserCannonRayGI_InvalidateRect }
procedure TPSLaserCannonRayGI.InvalidateRect(Rect: TRect);
var Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(HitTestBounds,
    Parent.ToAbsolutePoint(LocalPosition), Parent.ToAbsolutePoint(TargetPoint), HalfWidth);
  with Parent.ToAbsolutePoint(TargetPoint) do begin
    Rect.Left := X - 32;
    Rect.Right := X + 32;
    Rect.Top := Y - 32;
    Rect.Bottom := Y + 32;
  end;
  if IntersectRects(Intersection, Rect, GameScreenRect) then MessageLoop.QueueUpdateRect(Intersection);
end;
{ @end $49C598 }

{ @routine $49C654 TPSLaserCannonRayGI_LoadFromConfigPath }
procedure TPSLaserCannonRayGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49C654 }

{ @routine $49C680 TPSLaserCannonRayGI_LoadFromBlock }
procedure TPSLaserCannonRayGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $49C680 }

{ @routine $49C69C TPSLaserCannonRayGI_LoadEffectProperties }
procedure TPSLaserCannonRayGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('Period') > 0 then SetPeriod(StrToInt(AnsiString(Block.GetParam('Period'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color') > 0 then Color := GetColorGI(Block.GetParam('Color'));
end;
{ @end $49C69C }

{ @routine $49C898 TPSLaserCannonRayGI_Advance }
procedure TPSLaserCannonRayGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Y, Distance, Angle: Single;
  Current, Spark, Particle: PLaserCannonRayParticle;
begin
  if (FirstParticle = nil) and (RemainingTicks > 18) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    // Native comparison is strictly negative, including its zero-length behavior.
    if OriginalLength < 0 then OriginalLength := 1;
    LengthScale := 1;
    while Y < Distance do
    begin
      Particle := AddParticle;
      Angle := Y / Period * 2.0 * Pi;
      Particle.Position.X := 1;
      Particle.Position.Y := Y;
      Particle.Color := Color;
      Particle.BaseAlpha := Trunc(Sin(Angle) * 95.0 + 160.0);
      if Y < 64.0 then Particle.Alpha := Trunc(Particle.BaseAlpha * Y) shr 6
      else Particle.Alpha := Particle.BaseAlpha;
      Particle.Velocity.X := 0;
      Particle.SavedPixel1 := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Particle.ByteOffset1 := -1;
      Particle.PreviousByteOffset1 := -1;
      Particle := AddParticle;
      Particle.Position.X := 0;
      Particle.Position.Y := Y;
      Particle.Color := Color;
      Particle.SavedPixel1 := 0;
      Particle.BaseAlpha := Trunc(Sin(Angle) * 95.0 + 160.0);
      if Y < 64.0 then Particle.Alpha := Trunc(Particle.BaseAlpha * Y) shr 6
      else Particle.Alpha := Particle.BaseAlpha;
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Particle.ByteOffset1 := -1;
      Particle.PreviousByteOffset1 := -1;
      Y := Y + 1.0;
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
      1: begin
        Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
        Current.Position.X := Current.Position.X + Current.Velocity.X;
        if Current.Position.Y > Distance then
        begin
          Spark := AddParticle;
          Spark.Position := MakePointF(0, 0);
          Spark.Color := Current.Color;
          Spark.Alpha := Current.BaseAlpha;
          Angle := Random(12) * Pi / 6.0;
          Spark.Velocity := MakePointF(Sin(Angle) * 1.0, Cos(Angle) * 1.0);
          Spark.State := 2;
          Spark.RemainingTicks := 18;
          Spark.ByteOffset1 := -1;
          Spark.PreviousByteOffset1 := -1;
          Spark.SavedPixel1 := 0;
          Current.Position.Y := Current.Position.Y - Distance;
        end;
        if Current.Position.Y < 64.0 then Current.Alpha := Trunc(Current.BaseAlpha * Current.Position.Y) shr 6
        else Current.Alpha := Current.BaseAlpha;
        if RemainingTicks < 18 then begin
          if Current.PreviousByteOffset1 >= 0 then begin
            if BGImage then MessageLoop.SavePixel16(Current.PreviousByteOffset1, Current.SavedPixel1)
            else MessageLoop.SavePixel16(Current.PreviousByteOffset1, 0);
            MessageLoop.QueuePixelPresent(Current.PreviousByteOffset1);
          end;
          RemoveParticle(Current);
        end;
      end;
      end;
    end;
  end;
  Inc(PendingSparkSteps);
  Dec(RemainingTicks);
end;
{ @end $49C898 }

{ @routine $49CC90 TPSLaserCannonRayGI_AdvanceImpactSparks }
procedure TPSLaserCannonRayGI.AdvanceImpactSparks(ClipRect: TRect);
var
  TargetX, TargetY, X, Y: Integer;
  Particle, Current: PLaserCannonRayParticle;
  DX, DY: Double;
  Minimum, Brightness: Integer;
  Uniform: Boolean;
begin
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    Current := Particle;
    Particle := Particle.Next;
    if Current.State = 2 then
    begin
      if Current.Alpha > 96 then Dec(Current.Alpha, 4);
      Current.Position.X := Current.Position.X + Current.Velocity.X;
      Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
      X := Round(TargetX + Current.Position.X);
      Y := Round(TargetY + Current.Position.Y);
      DX := 0;
      DY := 0;
      Minimum := 94;
      Uniform := True;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y);
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := -0.25;
          DY := 0;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := -0.25;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y - 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := -0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := 0;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X + 1, Y + 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0.25;
          DY := 0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X, Y + 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          Minimum := Brightness;
          DX := 0;
          DY := 0.25;
        end;
        Brightness := ScreenRenderBuffer.GetBrightness16(X - 1, Y + 1);
        if Brightness <> Minimum then Uniform := False;
        if Brightness < Minimum then
        begin
          DX := -0.25;
          DY := 0.25;
        end;
      if Uniform then
      begin
        DX := 0;
        DY := 0;
      end;
      Current.Velocity.X := Current.Velocity.X + DX;
      Current.Velocity.Y := Current.Velocity.Y + DY;
      Dec(Current.RemainingTicks);
      if Current.RemainingTicks = 0 then RemoveParticle(Current);
    end;
  end;
end;
{ @end $49CC90 }

{ @routine $49CF88 TPSLaserCannonRayGI_IsFinished }
function TPSLaserCannonRayGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $49CF88 }

{ @routine $49CF94 TPSLaserCannonRayGI_ErasePreviousFrame }
procedure TPSLaserCannonRayGI.ErasePreviousFrame;
var Particle: PLaserCannonRayParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
    Particle := FirstParticle;
    if not BGImage then begin
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), 0);
        Particle := Particle.Next;
      end;
    end else begin
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), Particle.SavedPixel1);
        Particle := Particle.Next;
      end;

    end;
  end;
end;
{ @end $49CF94 }

{ @routine $49D014 TPSLaserCannonRayGI_PrepareFrameDraw }
procedure TPSLaserCannonRayGI.PrepareFrameDraw;
var
  Buffer: Pointer;
  PX, PY, Sine, Cosine, Angle: Single;
  TargetX, TargetY, X, Y, Pitch, Offset: Integer;
  Particle: PLaserCannonRayParticle;
  I: Integer;
begin
  for I := 1 to PendingSparkSteps do
    AdvanceImpactSparks(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
  PendingSparkSteps := 0;
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  PY := -(TargetPoint.Y - LocalPosition.Y);
  if PY = 0 then PY := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, PY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  while Particle <> nil do begin
    Particle.ByteOffset1 := -1;
    case Particle.State of
    2: begin
      X := TargetX + Trunc(Particle.Position.X);
      Y := TargetY + Trunc(Particle.Position.Y);
      Offset := X * 2 + Y * Pitch;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then
        Particle.ByteOffset1 := Offset;
    end;
    else begin
      PX := Particle.Position.X;
      PY := Particle.Position.Y * LengthScale;
      X := AbsolutePosition.X + Trunc(PX * Cosine + PY * Sine);
      Y := AbsolutePosition.Y + Trunc(PX * Sine - PY * Cosine);
      Offset := X * 2 + Y * Pitch;
      if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then
        Particle.ByteOffset1 := Offset;
    end;
    end;
    Particle := Particle.Next;
  end;
  if BGImage then begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.ByteOffset1 >= 0 then Particle.SavedPixel1 := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1));
      Particle := Particle.Next;
    end;
  end;
end;
{ @end $49D014 }

{ @routine $49D234 TPSLaserCannonRayGI_DrawUpdateRects }
procedure TPSLaserCannonRayGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $49D234 }

{ @routine $49D26C TPSLaserCannonRayGI_Draw }
procedure TPSLaserCannonRayGI.Draw(ClipRect: TRect);
var Particle: PLaserCannonRayParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $49D26C }

{ @routine $49D2B8 TPSLaserCannonRayGI_CommitFrameDraw }
procedure TPSLaserCannonRayGI.CommitFrameDraw;
var Particle: PLaserCannonRayParticle; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1)));
    if Particle.ByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1)));
    Particle.PreviousByteOffset1 := Particle.ByteOffset1;
    Particle := Particle.Next;
  end;
end;
{ @end $49D2B8 }

{ @routine $49D34C TPSLaserCannonRayGI_ClearSavedBackground }
procedure TPSLaserCannonRayGI.ClearSavedBackground;
var Particle: PLaserCannonRayParticle;
begin
  Particle := FirstParticle;
  if not BGImage then begin
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
      end;
      Particle := Particle.Next;
    end;
  end else begin
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, Particle.SavedPixel1);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
      end;
      Particle := Particle.Next;
    end;

  end;
end;
{ @end $49D34C }

end.

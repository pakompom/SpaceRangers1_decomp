unit GI_PSPhaser;
// Unit bracket (inferred): CODE 0x004A3AD4..0x004A4BFB; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PPhaserParticle = ^TPhaserParticle;
  TPhaserParticle = record // @size $2C
    Prev: PPhaserParticle; // @offset $0
    Next: PPhaserParticle; // @offset $4
    Position: TPointF; // @offset $8
    Color: Word; // @offset $10
    SavedPixel1: Word; // @offset $12
    ByteOffset1: Integer; // @offset $14
    PreviousByteOffset1: Integer; // @offset $18
    Alpha: Byte; // @offset $1C
    MaximumAlpha: Byte; // @offset $1D
    Velocity: TPointF; // @offset $20
    Countdown: Byte; // @offset $28
    State: Byte; // @offset $29
  end;
  TPSPhaserGI = class(TPSWeaponGI) // @size $148
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PPhaserParticle; // @offset $114
    LastParticle: PPhaserParticle; // @offset $118
    TimerInterval: Integer; // @offset $11C
    CallbackTimer: TCallbackTimerIdGI; // @offset $120
    Color1: Word; // @offset $124
    ProjectionBounds: TRect; // @offset $126 Native projection rectangle, independently read by both bounds methods.
    LengthScale: Double; // @offset $138
    OriginalLength: Double; // @offset $140

    constructor Create(Owner: TObjectGI); // @addr $4A3BF4
    destructor Destroy; override; // @addr $4A3CAC
    procedure SetPosition(Position: TPoint); override; // @addr $4A3CE8
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4A3D20
    procedure SetHalfWidth(Value: Integer); // @addr $4A3D60
    procedure SetTimerInterval(Value: Integer); // @addr $4A3D74
    procedure RestartTimer; // @addr $4A3D88
    procedure CancelTimer; // @addr $4A3D8C
    procedure SetActive(Enabled: Boolean); override; // @addr $4A3DB0
    procedure UpdateProjectionBounds; // @addr $4A3DE8
    procedure UpdateHitTestBounds; override; // @addr $4A406C
    function GetLocalBounds: TRect; override; // @addr $4A40A0
    function AddParticle: PPhaserParticle; // @addr $4A40D0
    procedure ClearParticles; // @addr $4A4110
    procedure Invalidate; override; // @addr $4A4140
    procedure InvalidateRect(Rect: TRect); override; // @addr $4A4144
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A4200
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A422C
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4A4248
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4A43E4
    function IsFinished: Boolean; override; // @addr $4A4828
    procedure ClearSavedBackground; // @addr $4A4834
    procedure ErasePreviousFrame; override; // @addr $4A48B8
    procedure PrepareFrameDraw; override; // @addr $4A4940
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4A4AAC
    procedure Draw(ClipRect: TRect); override; // @addr $4A4AE4
    procedure CommitFrameDraw; override; // @addr $4A4B30
  end;

implementation

// @unit-initialization $4A4BF4
// @unit-finalization $4A4BC4

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4A3BF4 TPSPhaserGI_Create }
constructor TPSPhaserGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TimerInterval := 50;
  HalfWidth := 4;
  RemainingTicks := 60;
  LifetimeTicks := 60;
  LengthScale := 1;
  OriginalLength := 1;
  UpdateProjectionBounds;
  RestartTimer;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(0, 1, 0.6);
end;
{ @end $4A3BF4 }

{ @routine $4A3CAC TPSPhaserGI_Destroy }
destructor TPSPhaserGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $4A3CAC }

{ @routine $4A3CE8 TPSPhaserGI_SetPosition }
procedure TPSPhaserGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $4A3CE8 }

{ @routine $4A3D20 TPSPhaserGI_SetTargetPoint }
procedure TPSPhaserGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A3D20 }

{ @routine $4A3D60 TPSPhaserGI_SetHalfWidth }
procedure TPSPhaserGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A3D60 }

{ @routine $4A3D74 TPSPhaserGI_SetTimerInterval }
procedure TPSPhaserGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $4A3D74 }

{ @routine $4A3D88 TPSPhaserGI_RestartTimer }
procedure TPSPhaserGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $4A3D88 }

{ @routine $4A3D8C TPSPhaserGI_CancelTimer }
procedure TPSPhaserGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $4A3D8C }

{ @routine $4A3DB0 TPSPhaserGI_SetActive }
procedure TPSPhaserGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $4A3DB0 }

{ @routine $4A3DE8 TPSPhaserGI_UpdateProjectionBounds }
procedure TPSPhaserGI.UpdateProjectionBounds;
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
{ @end $4A3DE8 }

{ @routine $4A406C TPSPhaserGI_UpdateHitTestBounds }
procedure TPSPhaserGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $4A406C }

{ @routine $4A40A0 TPSPhaserGI_GetLocalBounds }
function TPSPhaserGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $4A40A0 }

{ @routine $4A40D0 TPSPhaserGI_AddParticle }
function TPSPhaserGI.AddParticle: PPhaserParticle;
var Particle: PPhaserParticle;
begin
  Particle := AllocEC(SizeOf(TPhaserParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $4A40D0 }

{ @routine $4A4110 TPSPhaserGI_ClearParticles }
procedure TPSPhaserGI.ClearParticles;
var Particle, Current: PPhaserParticle;
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
{ @end $4A4110 }

{ @routine $4A4140 TPSPhaserGI_Invalidate }
procedure TPSPhaserGI.Invalidate;
begin

end;
{ @end $4A4140 }

{ @routine $4A4144 TPSPhaserGI_InvalidateRect }
procedure TPSPhaserGI.InvalidateRect(Rect: TRect);
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
{ @end $4A4144 }

{ @routine $4A4200 TPSPhaserGI_LoadFromConfigPath }
procedure TPSPhaserGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4A4200 }

{ @routine $4A422C TPSPhaserGI_LoadFromBlock }
procedure TPSPhaserGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4A422C }

{ @routine $4A4248 TPSPhaserGI_LoadEffectProperties }
procedure TPSPhaserGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
end;
{ @end $4A4248 }

{ @routine $4A43E4 TPSPhaserGI_Advance }
procedure TPSPhaserGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Y, I: Integer;
  Distance: Single;
  Particle, Current: PPhaserParticle;
  DelayScale: Single;
begin
  if (FirstParticle = nil) and (RemainingTicks = 60) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    if Distance > 300.0 then DelayScale := 20.0
    else DelayScale := 20.0 * Distance / 300.0;
    while Y < Distance do
    begin
      for I := -HalfWidth to HalfWidth do
      begin
        Particle := AddParticle;
        Particle.Position := MakePointF(I, Y);
        Particle.Color := Color1;
        Particle.MaximumAlpha := 255 - (212 * Abs(I)) div HalfWidth;
        if Y < 64 then Particle.Alpha := (Particle.MaximumAlpha * Trunc(Y)) shr 6
        else Particle.Alpha := Particle.MaximumAlpha;
        Particle.ByteOffset1 := -1;
        Particle.PreviousByteOffset1 := -1;
        Particle.Velocity := MakePointF(0, -2);
        Particle.State := 0;
        Particle.Countdown := Trunc(Particle.Position.Y / Distance * DelayScale);
      end;
      for I := 0 to 7 do
      begin
        Particle := AddParticle;
        Particle.Position := MakePointF(0, Y + I);
        Particle.Color := Color1;
        Particle.MaximumAlpha := 255 - Trunc(Sin(I / 8.0 * Pi) * 192.0);
        if Y < 64 then Particle.Alpha := (Particle.MaximumAlpha * Trunc(Y)) shr 6
        else Particle.Alpha := Particle.MaximumAlpha;
        Particle.ByteOffset1 := -1;
        Particle.PreviousByteOffset1 := -1;
        Particle.Velocity := MakePointF(0, -2);
        Particle.State := 0;
        Particle.Countdown := Trunc(Particle.Position.Y / Distance * DelayScale);
      end;
      Inc(Y, 12);
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
        0:
          if Current.Countdown = 0 then
          begin
            Current.Countdown := RemainingTicks + 21 - 60;
            if Current.Position.Y < 64.0 then Current.Alpha := (Current.MaximumAlpha * Trunc(Current.Position.Y)) shr 6
            else Current.Alpha := Current.MaximumAlpha;
            Current.State := 2;
          end
          else Dec(Current.Countdown);
        1:
          begin
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            if Current.Position.Y > Distance then Current.Position.Y := Current.Position.Y - Distance;
            if Current.Position.Y < 0 then Current.Position.Y := Current.Position.Y + Distance;
            if Current.Position.Y < 64.0 then Current.Alpha := (Current.MaximumAlpha * Trunc(Current.Position.Y)) shr 6
            else Current.Alpha := Current.MaximumAlpha;
          end;
        2:
          if Current.Countdown = 0 then Current.State := 1
          else Dec(Current.Countdown);
      end;
    end;
  end;
  Dec(RemainingTicks);
end;
{ @end $4A43E4 }

{ @routine $4A4828 TPSPhaserGI_IsFinished }
function TPSPhaserGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4A4828 }

{ @routine $4A4834 TPSPhaserGI_ClearSavedBackground }
procedure TPSPhaserGI.ClearSavedBackground;
var Particle: PPhaserParticle;
begin
  if BGImage then begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, Particle.SavedPixel1);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
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
      Particle := Particle.Next;
    end;
  end;
end;
{ @end $4A4834 }

{ @routine $4A48B8 TPSPhaserGI_ErasePreviousFrame }
procedure TPSPhaserGI.ErasePreviousFrame;
var Particle: PPhaserParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
    if not BGImage then begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), 0);
        Particle := Particle.Next;
      end;
    end else begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), Particle.SavedPixel1);
        Particle := Particle.Next;
      end;

    end;
  end;
end;
{ @end $4A48B8 }

{ @routine $4A4940 TPSPhaserGI_PrepareFrameDraw }
procedure TPSPhaserGI.PrepareFrameDraw;
var
  Angle, Sine, Cosine, PX, PY: Single;
  X, Y: Integer;
  Particle: PPhaserParticle;
  Buffer: Pointer;
  Pitch: Integer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then Y := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  while Particle <> nil do begin
    Particle.ByteOffset1 := -1;
    if Particle.State >= 1 then begin
    PX := Particle.Position.X;
    PY := -Particle.Position.Y * LengthScale;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset1 := X * 2 + Pitch * Y;
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
{ @end $4A4940 }

{ @routine $4A4AAC TPSPhaserGI_DrawUpdateRects }
procedure TPSPhaserGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4A4AAC }

{ @routine $4A4AE4 TPSPhaserGI_Draw }
procedure TPSPhaserGI.Draw(ClipRect: TRect);
var Particle: PPhaserParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $4A4AE4 }

{ @routine $4A4B30 TPSPhaserGI_CommitFrameDraw }
procedure TPSPhaserGI.CommitFrameDraw;
var Particle: PPhaserParticle; Buffer, Presented: Pointer;
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
{ @end $4A4B30 }

end.

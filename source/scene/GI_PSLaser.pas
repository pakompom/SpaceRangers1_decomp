unit GI_PSLaser;
// Unit bracket (inferred): CODE 0x00499EE8..0x0049ACE7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PLaserParticle = ^TLaserParticle;
  TLaserParticle = record // @size $24
    Prev: PLaserParticle; // @offset $0
    Next: PLaserParticle; // @offset $4
    Position: TPointF; // @offset $8
    Color: Word; // @offset $10
    Alpha: Byte; // @offset $12
    Velocity: TPointF; // @offset $14
    State: Byte; // @offset $1C
    MaximumAlpha: Integer; // @offset $20
  end;
  TPSLaserGI = class(TPSWeaponGI) // @size $158
  public
    procedure Draw(ClipRect: TRect); override; // @addr $49AAAC
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $49A848
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    Period: Integer; // @offset $114
    PeriodMask: Integer; // @offset $118
    Phase: Single; // @offset $11C
    FirstParticle: PLaserParticle; // @offset $120
    LastParticle: PLaserParticle; // @offset $124
    TimerInterval: Integer; // @offset $128
    CallbackTimer: TCallbackTimerIdGI; // @offset $12C
    Color: Word; // @offset $130
    ProjectionBounds: TRect; // @offset $132 Native projection rectangle, independently read by both bounds methods.
    OriginalLength: Double; // @offset $148
    LengthScale: Double; // @offset $150

    constructor Create(Owner: TObjectGI); // @addr $49A008
    destructor Destroy; override; // @addr $49A0D8
    procedure SetPeriod(Value: Integer); // @addr $49A104
    procedure SetPosition(Position: TPoint); override; // @addr $49A114
    procedure SetTargetPoint(Point: TPoint); override; // @addr $49A14C
    procedure SetHalfWidth(Value: Integer); // @addr $49A18C
    procedure SetTimerInterval(Value: Integer); // @addr $49A1A0
    procedure RestartTimer; // @addr $49A1B4
    procedure CancelTimer; // @addr $49A1B8
    procedure SetActive(Enabled: Boolean); override; // @addr $49A1DC
    procedure UpdateProjectionBounds; // @addr $49A208
    procedure UpdateHitTestBounds; override; // @addr $49A484
    function GetLocalBounds: TRect; override; // @addr $49A4C4
    function AddParticle: PLaserParticle; // @addr $49A4F4
    procedure InvalidateRect(Rect: TRect); override; // @addr $49A534
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49A5F0
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49A61C
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $49A638
    function IsFinished: Boolean; override; // @addr $49AAA0
  end;

implementation

// @unit-initialization $49ACE0
// @unit-finalization $49ACB0

uses Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $49A008 TPSLaserGI_Create }
constructor TPSLaserGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 12;
  OriginalLength := 1;
  LengthScale := 1;
  TimerInterval := 45;
  Period := 32;
  PeriodMask := Period - 1;
  RemainingTicks := 42;
  UpdateProjectionBounds;
  RestartTimer;
  Phase := 0;
  Color := CurrentPixelFormat.PackNormalizedRgb(0, 0.9, 1);
end;
{ @end $49A008 }

{ @routine $49A0D8 TPSLaserGI_Destroy }
destructor TPSLaserGI.Destroy;
begin
  CancelTimer;
  inherited Destroy;
end;
{ @end $49A0D8 }

{ @routine $49A104 TPSLaserGI_SetPeriod }
procedure TPSLaserGI.SetPeriod(Value: Integer);
begin
  Period := Value;
  PeriodMask := Period - 1;
end;
{ @end $49A104 }

{ @routine $49A114 TPSLaserGI_SetPosition }
procedure TPSLaserGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $49A114 }

{ @routine $49A14C TPSLaserGI_SetTargetPoint }
procedure TPSLaserGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $49A14C }

{ @routine $49A18C TPSLaserGI_SetHalfWidth }
procedure TPSLaserGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $49A18C }

{ @routine $49A1A0 TPSLaserGI_SetTimerInterval }
procedure TPSLaserGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $49A1A0 }

{ @routine $49A1B4 TPSLaserGI_RestartTimer }
procedure TPSLaserGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $49A1B4 }

{ @routine $49A1B8 TPSLaserGI_CancelTimer }
procedure TPSLaserGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $49A1B8 }

{ @routine $49A1DC TPSLaserGI_SetActive }
procedure TPSLaserGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
  end;
end;
{ @end $49A1DC }

{ @routine $49A208 TPSLaserGI_UpdateProjectionBounds }
procedure TPSLaserGI.UpdateProjectionBounds;
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
{ @end $49A208 }

{ @routine $49A484 TPSLaserGI_UpdateHitTestBounds }
procedure TPSLaserGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X - 32;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y - 32;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X + 32;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y + 32;
end;
{ @end $49A484 }

{ @routine $49A4C4 TPSLaserGI_GetLocalBounds }
function TPSLaserGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $49A4C4 }

{ @routine $49A4F4 TPSLaserGI_AddParticle }
function TPSLaserGI.AddParticle: PLaserParticle;
var Particle: PLaserParticle;
begin
  Particle := AllocEC(SizeOf(TLaserParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $49A4F4 }

{ @routine $49A534 TPSLaserGI_InvalidateRect }
procedure TPSLaserGI.InvalidateRect(Rect: TRect);
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
{ @end $49A534 }

{ @routine $49A5F0 TPSLaserGI_LoadFromConfigPath }
procedure TPSLaserGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49A5F0 }

{ @routine $49A61C TPSLaserGI_LoadFromBlock }
procedure TPSLaserGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $49A61C }

{ @routine $49A638 TPSLaserGI_LoadEffectProperties }
procedure TPSLaserGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('Period') > 0 then SetPeriod(StrToInt(AnsiString(Block.GetParam('Period'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color') > 0 then Color := StrToInt(AnsiString(Block.GetParam('Color')));
end;
{ @end $49A638 }

{ @routine $49A848 TPSLaserGI_Advance }
procedure TPSLaserGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Y, Distance, Angle: Single; Particle, Current: PLaserParticle;
begin
  Invalidate;
  if FirstParticle = nil then begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    while Y < Distance do begin
      Particle := AddParticle;
      Angle := Y / Period * 2.0 * Pi;
      Particle.Position.X := 0;
      Particle.Position.Y := Y;
      Particle.Color := Color;
      Particle.MaximumAlpha := Trunc(Sin(Angle) * 63.0 + 192.0);
      if Y < 128.0 then Particle.Alpha := Trunc(Particle.MaximumAlpha * Y) shr 7
      else Particle.Alpha := Particle.MaximumAlpha;
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 6;
      Particle.State := 1;
      Y := Y + 1.0;
    end;
    Phase := 0;
  end else begin
    Distance := OriginalLength;
    LengthScale := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)) / OriginalLength;
    Particle := FirstParticle;
    while Particle <> nil do begin
      Current := Particle;
      case Particle.State of
        1: begin
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          if Current.Position.Y > Distance then Current.Position.Y := Current.Position.Y - Distance;
          if Current.Position.Y < 128.0 then Particle.Alpha := Trunc(Particle.MaximumAlpha * Current.Position.Y) shr 7
          else Particle.Alpha := Particle.MaximumAlpha;
          Particle := Particle.Next;
        end;
        else Particle := Particle.Next;
      end;
    end;
    Phase := Pi / 8 + Phase;
  end;
  Dec(RemainingTicks);
end;
{ @end $49A848 }

{ @routine $49AAA0 TPSLaserGI_IsFinished }
function TPSLaserGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $49AAA0 }

{ @routine $49AAAC TPSLaserGI_Draw }
procedure TPSLaserGI.Draw(ClipRect: TRect);
var Angle, Sine, Cosine, PX, PY: Single; X, Y, TargetX, TargetY: Integer; Particle: PLaserParticle;
begin
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then Inc(Y);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Y := -HalfWidth;
  while Y < HalfWidth do begin
    ScreenRenderBuffer.ShiftBand16(TargetX - HalfWidth - 1 + Abs(Y), TargetY + Y,
      (HalfWidth + 1 - Abs(Y)) * 2, 2, Trunc(Sin(Y * Pi / 8.0 + Phase) * 3.0), ClipRect);
    Inc(Y, 2);
  end;
  Particle := FirstParticle;
  while Particle <> nil do begin
    PX := Particle.Position.X * LengthScale;
    PY := -Particle.Position.Y * LengthScale;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    if (X >= ClipRect.Left) and (X < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
      ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
    if (X + 1 >= ClipRect.Left) and (X + 1 < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
      ScreenRenderBuffer.BlendPixel16(X + 1, Y, Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $49AAAC }

end.

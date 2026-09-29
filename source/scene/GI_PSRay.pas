unit GI_PSRay;
// Unit bracket (inferred): CODE 0x00495BA4..0x00496C27; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PRayParticle = ^TRayParticle;
  TRayParticle = record // @size $20
    Prev: PRayParticle; // @offset $00
    Next: PRayParticle; // @offset $04
    Position: TPointF; // @offset $08
    Color: Word; // @offset $10
    Alpha: Byte; // @offset $12
    Velocity: TPointF; // @offset $14
    State: Byte; // @offset $1C
  end;
  TPSRayGI = class(TPSWeaponGI) // @size $150
  public
    HalfWidth: Integer; // @offset $110
    FirstParticle: PRayParticle; // @offset $114
    LastParticle: PRayParticle; // @offset $118
    TimerInterval: Integer; // @offset $11C
    CallbackTimer: TCallbackTimerIdGI; // @offset $120
    Colors: array[0..2] of Word; // @offset $124
    ProjectionBounds: TRect; // @offset $12A Native bounds follow the three packed color words.
    OriginalLength: Double; // @offset $140
    LengthScale: Double; // @offset $148

    constructor Create(Owner: TObjectGI); // @addr $495CC4
    destructor Destroy; override; // @addr $495DD0
    procedure SetPosition(Position: TPoint); override; // @addr $495DFC
    procedure SetTargetPoint(Point: TPoint); override; // @addr $495E34
    procedure SetHalfWidth(Value: Integer); // @addr $495E74
    procedure SetTimerInterval(Value: Integer); // @addr $495E88
    procedure RestartTimer; // @addr $495E9C
    procedure CancelTimer; // @addr $495EA0
    procedure SetActive(Enabled: Boolean); override; // @addr $495EC4
    procedure UpdateProjectionBounds; // @addr $495EF0
    procedure UpdateHitTestBounds; override; // @addr $496174
    function GetLocalBounds: TRect; override; // @addr $4961A8
    function AddParticle: PRayParticle; // @addr $4961D8
    procedure RemoveParticle(Particle: PRayParticle); // @addr $496218
    procedure InvalidateRect(Rect: TRect); override; // @addr $49625C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $496318
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $496344
    procedure LoadRayProperties(Block: TBlockParEC); // @addr $496360
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $496584
    function IsFinished: Boolean; override; // @addr $496AC8
    procedure Draw(ClipRect: TRect); override; // @addr $496AD4
  end;

implementation

// @unit-initialization $496C20
// @unit-finalization $496BF0

uses Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $495CC4 TPSRayGI_Create }
constructor TPSRayGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TimerInterval := 50;
  HalfWidth := 2;
  LengthScale := 1;
  OriginalLength := 1;
  RemainingTicks := 40;
  UpdateProjectionBounds;
  RestartTimer;
  Colors[0] := CurrentPixelFormat.PackNormalizedRgb(1, 0.5, 0.5);
  Colors[1] := CurrentPixelFormat.PackNormalizedRgb(0.7, 1, 0.7);
  Colors[2] := CurrentPixelFormat.PackNormalizedRgb(0.4, 0.4, 0.9);
end;
{ @end $495CC4 }

{ @routine $495DD0 TPSRayGI_Destroy }
destructor TPSRayGI.Destroy;
begin
  CancelTimer;
  inherited Destroy;
end;
{ @end $495DD0 }

{ @routine $495DFC TPSRayGI_SetPosition }
procedure TPSRayGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then
  begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $495DFC }

{ @routine $495E34 TPSRayGI_SetTargetPoint }
procedure TPSRayGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then
  begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $495E34 }

{ @routine $495E74 TPSRayGI_SetHalfWidth }
procedure TPSRayGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin HalfWidth := Value; UpdateProjectionBounds; end;
end;
{ @end $495E74 }

{ @routine $495E88 TPSRayGI_SetTimerInterval }
procedure TPSRayGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $495E88 }

{ @routine $495E9C TPSRayGI_RestartTimer }
procedure TPSRayGI.RestartTimer;
begin
  // The shipped method is empty; timing is driven externally.
end;
{ @end $495E9C }

{ @routine $495EA0 TPSRayGI_CancelTimer }
procedure TPSRayGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $495EA0 }

{ @routine $495EC4 TPSRayGI_SetActive }
procedure TPSRayGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
  end;
end;
{ @end $495EC4 }

{ @routine $495EF0 TPSRayGI_UpdateProjectionBounds }
procedure TPSRayGI.UpdateProjectionBounds;
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
{ @end $495EF0 }

{ @routine $496174 TPSRayGI_UpdateHitTestBounds }
procedure TPSRayGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $496174 }

{ @routine $4961A8 TPSRayGI_GetLocalBounds }
function TPSRayGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $4961A8 }

{ @routine $4961D8 TPSRayGI_AddParticle }
function TPSRayGI.AddParticle: PRayParticle;
var
  Particle: PRayParticle;
begin
  Particle := AllocEC(SizeOf(TRayParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $4961D8 }

{ @routine $496218 TPSRayGI_RemoveParticle }
procedure TPSRayGI.RemoveParticle(Particle: PRayParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $496218 }

{ @routine $49625C TPSRayGI_InvalidateRect }
procedure TPSRayGI.InvalidateRect(Rect: TRect);
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
{ @end $49625C }

{ @routine $496318 TPSRayGI_LoadFromConfigPath }
procedure TPSRayGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadRayProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $496318 }

{ @routine $496344 TPSRayGI_LoadFromBlock }
procedure TPSRayGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadRayProperties(Block);
end;
{ @end $496344 }

{ @routine $496360 TPSRayGI_LoadRayProperties }
procedure TPSRayGI.LoadRayProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color1') > 0 then Colors[0] := GetColorGI(Block.GetParam('Color1'));
  if Block.CountParams('Color2') > 0 then Colors[1] := GetColorGI(Block.GetParam('Color2'));
  if Block.CountParams('Color3') > 0 then Colors[2] := GetColorGI(Block.GetParam('Color3'));
end;
{ @end $496360 }

{ @routine $496584 TPSRayGI_Advance }
procedure TPSRayGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  I, Power: Integer;
  Distance, Angle: Single;
  Particle, Current, Spark: PRayParticle;
  Alpha: Byte;
begin
  Invalidate;
  if (FirstParticle = nil) and (RemainingTicks >= 24) then
  begin
    I := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    Angle := 0;
    Alpha := 0;
    while I < Distance do
    begin
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin(Pi * Angle / 180.0) * (HalfWidth - 0), I);
      Particle.Color := Colors[0];
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 5);
      Particle.State := 1;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin((Angle + 90.0) * Pi / 180.0) * (HalfWidth - 0), I);
      Particle.Color := Colors[1];
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 5);
      Particle.State := 1;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin((Angle + 180.0) * Pi / 180.0) * (HalfWidth - 0), I);
      Particle.Color := Colors[2];
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 5);
      Particle.State := 1;
      if Alpha + 4 < 255 then Inc(Alpha, 4)
      else Alpha := 255;
      Inc(I);
      Angle := Angle + 10.0;
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
            if Current.Alpha + 4 < 255 then Inc(Current.Alpha, 4)
            else Current.Alpha := 255;
            if Current.Position.Y > Distance then
            begin
              for I := 1 to 1 do
              begin
                Spark := AddParticle;
                Spark.Position.X := Current.Position.X;
                Spark.Position.Y := Current.Position.Y;
                Spark.Color := Current.Color;
                Angle := Random(16) / 8.0 * Pi;
                Power := Random(50);
                Spark.Velocity.X := Sin(Angle) * (Power + 50) / 50.0;
                Spark.Velocity.Y := Cos(Angle) * (Power + 50) / 50.0;
                Spark.State := 2;
                Power := (Current.Alpha shr 1) - Random(100);
                if Power < 0 then Power := 0;
                Spark.Alpha := Power;
              end;
              Current.Position.Y := Current.Position.Y - Distance;
              Current.Alpha := 0;
            end;
            if RemainingTicks < 24 then RemoveParticle(Current);
          end;
        2:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Velocity.Y := 0.95 * Current.Velocity.Y;
            Current.Velocity.X := 0.95 * Current.Velocity.X;
            if Current.Alpha < 246 then Inc(Current.Alpha, 16);
            if Current.Alpha > 245 then Current.State := 3;
          end;
        3:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Velocity.Y := 0.95 * Current.Velocity.Y;
            Current.Velocity.X := 0.95 * Current.Velocity.X;
            if Current.Alpha > 25 then Dec(Current.Alpha, 26);
            if Current.Alpha < 26 then RemoveParticle(Current);
          end;
      end;
    end;
  end;
  Dec(RemainingTicks);
end;
{ @end $496584 }

{ @routine $496AC8 TPSRayGI_IsFinished }
function TPSRayGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $496AC8 }

{ @routine $496AD4 TPSRayGI_Draw }
procedure TPSRayGI.Draw(ClipRect: TRect);
var
  Angle, Sine, Cosine, PX, PY: Single;
  Particle: PRayParticle;
  X, Y: Integer;
begin
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then Inc(Y);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
    while Particle <> nil do
    begin
      PX := Particle.Position.X * LengthScale;
      PY := -Particle.Position.Y * LengthScale;
      X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
      Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
      if (X >= ClipRect.Left) and (X < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
        ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      Particle := Particle.Next;
    end;
end;
{ @end $496AD4 }

end.

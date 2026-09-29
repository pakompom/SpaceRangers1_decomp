unit GI_PSDefibrillator;
// Unit bracket (inferred): CODE 0x004A2870..0x004A3AD3; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PDefibrillatorParticle = ^TDefibrillatorParticle;
  TDefibrillatorParticle = record // @size $28
    Prev: PDefibrillatorParticle; // @offset $0
    Next: PDefibrillatorParticle; // @offset $4
    Position: TPointF; // @offset $8
    Depth: Double; // @offset $10
    Color: Word; // @offset $18
    Alpha: Byte; // @offset $1A
    Velocity: TPointF; // @offset $1C
    State: Byte; // @offset $24
  end;
  TPSDefibrillatorGI = class(TPSWeaponGI) // @size $150
  public
    procedure Draw(ClipRect: TRect); override; // @addr $4A394C
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4A3250
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PDefibrillatorParticle; // @offset $114
    LastParticle: PDefibrillatorParticle; // @offset $118
    TimerInterval: Integer; // @offset $11C
    CallbackTimer: TCallbackTimerIdGI; // @offset $120
    Color1: Word; // @offset $124
    Color2: Word; // @offset $126
    Color3: Word; // @offset $128
    ProjectionBounds: TRect; // @offset $12A Native projection rectangle, independently read by both bounds methods.
    OriginalLength: Double; // @offset $140
    LengthScale: Double; // @offset $148

    constructor Create(Owner: TObjectGI); // @addr $4A2998
    destructor Destroy; override; // @addr $4A2A9C
    procedure SetPosition(Position: TPoint); override; // @addr $4A2AC8
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4A2B00
    procedure SetHalfWidth(Value: Integer); // @addr $4A2B40
    procedure SetTimerInterval(Value: Integer); // @addr $4A2B54
    procedure RestartTimer; // @addr $4A2B68
    procedure CancelTimer; // @addr $4A2B6C
    procedure SetActive(Enabled: Boolean); override; // @addr $4A2B90
    procedure UpdateProjectionBounds; // @addr $4A2BBC
    procedure UpdateHitTestBounds; override; // @addr $4A2E40
    function GetLocalBounds: TRect; override; // @addr $4A2E74
    function AddParticle: PDefibrillatorParticle; // @addr $4A2EA4
    procedure RemoveParticle(Particle: PDefibrillatorParticle); // @addr $4A2EE4
    procedure InvalidateRect(Rect: TRect); override; // @addr $4A2F28
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A2FE4
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A3010
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4A302C
    function IsFinished: Boolean; override; // @addr $4A3940
  end;

implementation

// @unit-initialization $4A3ACC
// @unit-finalization $4A3A9C

uses Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4A2998 TPSDefibrillatorGI_Create }
constructor TPSDefibrillatorGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TimerInterval := 50;
  HalfWidth := 3;
  RemainingTicks := 50;
  LengthScale := 1;
  OriginalLength := 1;
  UpdateProjectionBounds;
  RestartTimer;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(1, 1, 0.5);
  Color2 := CurrentPixelFormat.PackNormalizedRgb(0.5, 1, 0.5);
  Color3 := CurrentPixelFormat.PackNormalizedRgb(0.4, 0.4, 1);
end;
{ @end $4A2998 }

{ @routine $4A2A9C TPSDefibrillatorGI_Destroy }
destructor TPSDefibrillatorGI.Destroy;
begin
  CancelTimer;
  inherited Destroy;
end;
{ @end $4A2A9C }

{ @routine $4A2AC8 TPSDefibrillatorGI_SetPosition }
procedure TPSDefibrillatorGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $4A2AC8 }

{ @routine $4A2B00 TPSDefibrillatorGI_SetTargetPoint }
procedure TPSDefibrillatorGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A2B00 }

{ @routine $4A2B40 TPSDefibrillatorGI_SetHalfWidth }
procedure TPSDefibrillatorGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A2B40 }

{ @routine $4A2B54 TPSDefibrillatorGI_SetTimerInterval }
procedure TPSDefibrillatorGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $4A2B54 }

{ @routine $4A2B68 TPSDefibrillatorGI_RestartTimer }
procedure TPSDefibrillatorGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $4A2B68 }

{ @routine $4A2B6C TPSDefibrillatorGI_CancelTimer }
procedure TPSDefibrillatorGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $4A2B6C }

{ @routine $4A2B90 TPSDefibrillatorGI_SetActive }
procedure TPSDefibrillatorGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
  end;
end;
{ @end $4A2B90 }

{ @routine $4A2BBC TPSDefibrillatorGI_UpdateProjectionBounds }
procedure TPSDefibrillatorGI.UpdateProjectionBounds;
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
{ @end $4A2BBC }

{ @routine $4A2E40 TPSDefibrillatorGI_UpdateHitTestBounds }
procedure TPSDefibrillatorGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $4A2E40 }

{ @routine $4A2E74 TPSDefibrillatorGI_GetLocalBounds }
function TPSDefibrillatorGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $4A2E74 }

{ @routine $4A2EA4 TPSDefibrillatorGI_AddParticle }
function TPSDefibrillatorGI.AddParticle: PDefibrillatorParticle;
var Particle: PDefibrillatorParticle;
begin
  Particle := AllocEC(SizeOf(TDefibrillatorParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $4A2EA4 }

{ @routine $4A2EE4 TPSDefibrillatorGI_RemoveParticle }
procedure TPSDefibrillatorGI.RemoveParticle(Particle: PDefibrillatorParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $4A2EE4 }

{ @routine $4A2F28 TPSDefibrillatorGI_InvalidateRect }
procedure TPSDefibrillatorGI.InvalidateRect(Rect: TRect);
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
{ @end $4A2F28 }

{ @routine $4A2FE4 TPSDefibrillatorGI_LoadFromConfigPath }
procedure TPSDefibrillatorGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4A2FE4 }

{ @routine $4A3010 TPSDefibrillatorGI_LoadFromBlock }
procedure TPSDefibrillatorGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4A3010 }

{ @routine $4A302C TPSDefibrillatorGI_LoadEffectProperties }
procedure TPSDefibrillatorGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
  if Block.CountParams('Color2') > 0 then Color2 := GetColorGI(Block.GetParam('Color2'));
  if Block.CountParams('Color3') > 0 then Color3 := GetColorGI(Block.GetParam('Color3'));
end;
{ @end $4A302C }

{ @routine $4A3250 TPSDefibrillatorGI_Advance }
procedure TPSDefibrillatorGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var I, Power: Integer; Distance, Angle: Single;
  Particle, Current, Spark: PDefibrillatorParticle;
  J: Integer; Color: Word; Alpha: Byte;
begin
  Invalidate;
  if (FirstParticle = nil) and (RemainingTicks >= 24) then begin
    I := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    Alpha := 0;
    while I < Distance do begin
      J := 0;
      while I < Distance do begin
        case Random(3) of
          0: Color := Color1;
          1: Color := Color2;
          else Color := Color3;
        end;
      Angle := (I) / 16.0 * Pi;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin(Angle) * HalfWidth, I);
      Particle.Color := Color;
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 3);
      Particle.State := 1;
      Particle.Depth := Cos(Angle) * HalfWidth;
      if Alpha + 8 < 255 then Inc(Alpha, 8) else Alpha := 255;
      Angle := (I + 1) / 16.0 * Pi;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin(Angle) * HalfWidth, I + 1);
      Particle.Color := Color;
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 3);
      Particle.State := 1;
      Particle.Depth := Cos(Angle) * HalfWidth;
      if Alpha + 8 < 255 then Inc(Alpha, 8) else Alpha := 255;
      Angle := (I + 2) / 16.0 * Pi;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin(Angle) * HalfWidth, I + 2);
      Particle.Color := Color;
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 3);
      Particle.State := 1;
      Particle.Depth := Cos(Angle) * HalfWidth;
      if Alpha + 8 < 255 then Inc(Alpha, 8) else Alpha := 255;
      Angle := (I + 3) / 16.0 * Pi;
      Particle := AddParticle;
      Particle.Position := MakePointF(Sin(Angle) * HalfWidth, I + 3);
      Particle.Color := Color;
      Particle.Alpha := Alpha;
      Particle.Velocity := MakePointF(0, 3);
      Particle.State := 1;
      Particle.Depth := Cos(Angle) * HalfWidth;
      if Alpha + 8 < 255 then Inc(Alpha, 8) else Alpha := 255;
        Inc(I, 8);
        Inc(J);
        if J = 4 then Break;
      end;
      Inc(I, 32);
    end;
  end else begin
    Distance := OriginalLength;
    LengthScale := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)) / OriginalLength;
    Particle := FirstParticle;
    while Particle <> nil do begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
      1: begin
        Current.Position.X := Current.Position.X + Current.Velocity.X;
        Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
        if Current.Alpha + 8 < 255 then Inc(Current.Alpha, 8) else Current.Alpha := 255;
        if Current.Position.Y > Distance then begin
          for I := 1 to 4 do begin
            Spark := AddParticle;
            Spark.Position.X := Current.Position.X;
            Spark.Position.Y := Current.Position.Y;
            Spark.Color := Current.Color;
            Spark.Depth := 0;
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
        Angle := Current.Position.Y / 16.0 * Pi;
        Current.Depth := Cos(Angle) * HalfWidth;
        Current.Position.X := Sin(Angle) * HalfWidth;
        if RemainingTicks < 16 then RemoveParticle(Current);
      end;
      2: begin
        Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
        Current.Position.X := Current.Position.X + Current.Velocity.X;
        Current.Velocity.Y := 0.95 * Current.Velocity.Y;
        Current.Velocity.X := 0.95 * Current.Velocity.X;
        if Current.Alpha < 246 then Inc(Current.Alpha, 16);
        if Current.Alpha > 245 then Current.State := 3;
      end;
      3: begin
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
{ @end $4A3250 }

{ @routine $4A3940 TPSDefibrillatorGI_IsFinished }
function TPSDefibrillatorGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4A3940 }

{ @routine $4A394C TPSDefibrillatorGI_Draw }
procedure TPSDefibrillatorGI.Draw(ClipRect: TRect);
var
  Angle, Sine, Cosine, PX, PY: Single;
  X, Y: Integer;
  Particle: PDefibrillatorParticle;
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
      PY := (-Particle.Position.Y - Particle.Depth) * LengthScale;
      X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
      Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
      if (X >= ClipRect.Left) and (X < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
        ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
      if (X - 1 >= ClipRect.Left) and (X - 1 < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
        ScreenRenderBuffer.BlendPixel16(X - 1, Y, Particle.Color, Particle.Alpha);
      Particle := Particle.Next;
    end;
end;
{ @end $4A394C }

end.

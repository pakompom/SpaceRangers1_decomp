unit GI_PSRay2;
// Unit bracket (inferred): CODE 0x00496C28..0x00498813; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PRailRayParticle = ^TRailRayParticle;
  TRailRayParticle = record // @size $48
    Prev: PRailRayParticle; // @offset $0
    Next: PRailRayParticle; // @offset $4
    Position: TPoint; // @offset $08
    FloatPosition: TPointF; // @offset $10
    Color: Word; // @offset $18
    Alpha: Byte; // @offset $1A
    Velocity: TPoint; // @offset $1C
    FloatVelocity: TPointF; // @offset $24
    State: Byte; // @offset $2C
    Unknown2E: Word; // @offset $2E
    Radius: Integer; // @offset $30
    ByteOffset1: Integer; // @offset $34
    PreviousByteOffset1: Integer; // @offset $38
    ByteOffset2: Integer; // @offset $3C
    PreviousByteOffset2: Integer; // @offset $40
    SavedPixel1: Word; // @offset $44
    SavedPixel2: Word; // @offset $46
  end;
  TPSRailRayGI = class(TPSWeaponGI) // @size $298
  public
    OffsetTable: array[0..63] of Integer; // @offset $110
    AlphaTable: array[0..63] of Byte; // @offset $210
    HalfWidth: Integer; // @offset $250 Used by native projection geometry.
    Period: Integer; // @offset $254
    HalfPeriod: Integer; // @offset $258
    RailAttributes: Integer; // @offset $25C
    PeriodMask: Integer; // @offset $260
    FirstParticle: PRailRayParticle; // @offset $264
    LastParticle: PRailRayParticle; // @offset $268
    Color1: Word; // @offset $26C
    Color2: Word; // @offset $26E
    TimerInterval: Integer; // @offset $270
    CallbackTimer: TCallbackTimerIdGI; // @offset $274
    ProjectionBounds: TRect; // @offset $278 Native projection rectangle, independently read by both bounds methods.
    LengthScale: Double; // @offset $288
    OriginalLength: Double; // @offset $290

    constructor Create(Owner: TObjectGI); // @addr $496F94
    destructor Destroy; override; // @addr $4970A0
    procedure SetPeriod(Value: Integer); // @addr $4970DC
    procedure BuildWaveTables; // @addr $497100
    procedure SetPosition(Position: TPoint); override; // @addr $497198
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4971D0
    procedure SetHalfWidth(Value: Integer); // @addr $497210
    procedure SetTimerInterval(Value: Integer); // @addr $497234
    procedure RestartTimer; // @addr $497248
    procedure CancelTimer; // @addr $49724C
    procedure SetActive(Enabled: Boolean); override; // @addr $497270
    procedure UpdateProjectionBounds; // @addr $4972A8
    procedure UpdateHitTestBounds; override; // @addr $497524
    function GetLocalBounds: TRect; override; // @addr $497558
    function AddParticle: PRailRayParticle; // @addr $497588
    procedure RemoveParticle(Particle: PRailRayParticle); // @addr $4975C8
    procedure ClearParticles; // @addr $49760C
    procedure Invalidate; override; // @addr $49763C
    procedure InvalidateRect(Rect: TRect); override; // @addr $497640
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4976FC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $497728
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $497744
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4979E4
    function IsFinished: Boolean; override; // @addr $498220
    procedure ClearSavedBackground; // @addr $49822C
    procedure ErasePreviousFrame; override; // @addr $498300
    procedure PrepareFrameDraw; override; // @addr $4983CC
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $498598
    procedure Draw(ClipRect: TRect); override; // @addr $4985D0
    procedure CommitFrameDraw; override; // @addr $498644
  end;

  TPSBlueWhirlGI = class(TPSRailRayGI) // @size $298
  public
    constructor Create(Owner: TObjectGI); // @addr $49875C
  end;

  TPSGreenWhirlGI = class(TPSRailRayGI) // @size $298
  public
    constructor Create(Owner: TObjectGI); // @addr $49879C
  end;

implementation

// @unit-initialization $49880C
// @unit-finalization $4987DC

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $496F94 TPSRailRayGI_Create }
constructor TPSRailRayGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 4;
  TimerInterval := 45;
  Period := 32;
  HalfPeriod := Period shr 1;
  OriginalLength := 1;
  LengthScale := 1;
  PeriodMask := Period - 1;
  BuildWaveTables;
  UpdateProjectionBounds;
  RestartTimer;
  RailAttributes := 3;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(0.5, 0.5, 1);
  Color2 := CurrentPixelFormat.PackNormalizedRgb(0.3, 1, 0.3);
end;
{ @end $496F94 }

{ @routine $4970A0 TPSRailRayGI_Destroy }
destructor TPSRailRayGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $4970A0 }

{ @routine $4970DC TPSRailRayGI_SetPeriod }
procedure TPSRailRayGI.SetPeriod(Value: Integer);
begin
  Period := Value;
  HalfPeriod := Period shr 1;
  PeriodMask := Period - 1;
  BuildWaveTables;
end;
{ @end $4970DC }

{ @routine $497100 TPSRailRayGI_BuildWaveTables }
procedure TPSRailRayGI.BuildWaveTables;
var I: Integer; Angle: Single;
begin
  for I := 0 to PeriodMask do begin
    Angle := I / Period * 2.0 * Pi;
    OffsetTable[I] := Trunc(Sin(Angle) * HalfWidth);
    AlphaTable[I] := Trunc((Cos(Angle) + 1.5) * 100.0);
  end;
end;
{ @end $497100 }

{ @routine $497198 TPSRailRayGI_SetPosition }
procedure TPSRailRayGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $497198 }

{ @routine $4971D0 TPSRailRayGI_SetTargetPoint }
procedure TPSRailRayGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $4971D0 }

{ @routine $497210 TPSRailRayGI_SetHalfWidth }
procedure TPSRailRayGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    BuildWaveTables;
    UpdateProjectionBounds;
  end;
end;
{ @end $497210 }

{ @routine $497234 TPSRailRayGI_SetTimerInterval }
procedure TPSRailRayGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $497234 }

{ @routine $497248 TPSRailRayGI_RestartTimer }
procedure TPSRailRayGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $497248 }

{ @routine $49724C TPSRailRayGI_CancelTimer }
procedure TPSRailRayGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $49724C }

{ @routine $497270 TPSRailRayGI_SetActive }
procedure TPSRailRayGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $497270 }

{ @routine $4972A8 TPSRailRayGI_UpdateProjectionBounds }
procedure TPSRailRayGI.UpdateProjectionBounds;
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
{ @end $4972A8 }

{ @routine $497524 TPSRailRayGI_UpdateHitTestBounds }
procedure TPSRailRayGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $497524 }

{ @routine $497558 TPSRailRayGI_GetLocalBounds }
function TPSRailRayGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $497558 }

{ @routine $497588 TPSRailRayGI_AddParticle }
function TPSRailRayGI.AddParticle: PRailRayParticle;
var Particle: PRailRayParticle;
begin
  Particle := AllocEC(SizeOf(TRailRayParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $497588 }

{ @routine $4975C8 TPSRailRayGI_RemoveParticle }
procedure TPSRailRayGI.RemoveParticle(Particle: PRailRayParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $4975C8 }

{ @routine $49760C TPSRailRayGI_ClearParticles }
procedure TPSRailRayGI.ClearParticles;
var Particle, Current: PRailRayParticle;
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
{ @end $49760C }

{ @routine $49763C TPSRailRayGI_Invalidate }
procedure TPSRailRayGI.Invalidate;
begin

end;
{ @end $49763C }

{ @routine $497640 TPSRailRayGI_InvalidateRect }
procedure TPSRailRayGI.InvalidateRect(Rect: TRect);
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
{ @end $497640 }

{ @routine $4976FC TPSRailRayGI_LoadFromConfigPath }
procedure TPSRailRayGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4976FC }

{ @routine $497728 TPSRailRayGI_LoadFromBlock }
procedure TPSRailRayGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $497728 }

{ @routine $497744 TPSRailRayGI_LoadEffectProperties }
procedure TPSRailRayGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('Period') > 0 then SetPeriod(StrToInt(AnsiString(Block.GetParam('Period'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('RailAttr') > 0 then RailAttributes := StrToInt(AnsiString(Block.GetParam('RailAttr')));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
  if Block.CountParams('Color2') > 0 then Color2 := GetColorGI(Block.GetParam('Color2'));
end;
{ @end $497744 }

{ @routine $4979E4 TPSRailRayGI_Advance }
procedure TPSRailRayGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  I, Power, Distance: Integer;
  Angle: Single;
  Particle, Current, Spark: PRailRayParticle;
begin
  if (FirstParticle = nil) and (RemainingTicks > 24) then begin
    I := 0;
    Distance := Trunc(Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    while I < Distance do begin
      if RailAttributes and 1 <> 0 then begin
        Particle := AddParticle;
        Particle.Position.X := OffsetTable[I and PeriodMask];
        Particle.Position.Y := I;
        Particle.Color := Color1;
        if I < 64 then Particle.Alpha := (I * AlphaTable[I and PeriodMask]) shr 6;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := 1;
        Particle.State := 1;
        Particle.Unknown2E := 30000;
          Particle.ByteOffset1 := -1;
          Particle.ByteOffset2 := -1;
          Particle.PreviousByteOffset1 := -1;
          Particle.PreviousByteOffset2 := -1;
      end;
      if RailAttributes and 2 <> 0 then begin
        Particle := AddParticle;
        Particle.Position.X := OffsetTable[(I + HalfPeriod) and PeriodMask];
        Particle.Position.Y := I;
        Particle.Color := Color2;
        Particle.Alpha := AlphaTable[(I + HalfPeriod) and PeriodMask];
        if I < 64 then Particle.Alpha := (I * AlphaTable[(I + HalfPeriod) and PeriodMask]) shr 6;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := 1;
        Particle.State := 2;
        Particle.Unknown2E := 30000;
          Particle.ByteOffset1 := -1;
          Particle.ByteOffset2 := -1;
          Particle.PreviousByteOffset1 := -1;
          Particle.PreviousByteOffset2 := -1;
      end;
      Inc(I, 3);
    end;
  end else begin
    Distance := Round(OriginalLength);
    LengthScale := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)) / OriginalLength;
    Particle := FirstParticle;
    while Particle <> nil do begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
        1: begin
          Inc(Current.Position.Y, Current.Velocity.Y);
          if Current.Position.Y > Distance then begin
            for I := 0 to 10 do begin
              Spark := AddParticle;
              Spark.Position := Current.Position;
              Spark.FloatPosition.X := Current.Position.X;
              Spark.FloatPosition.Y := Current.Position.Y;
              Spark.Color := Color1;
              Angle := Random(16) / 8.0 * Pi;
              Power := Random(50);
              Spark.FloatVelocity.X := Sin(Angle) * (Power + 50) / 50.0;
              Spark.FloatVelocity.Y := Cos(Angle) * (Power + 50) / 50.0;
              Spark.State := 5;
              Power := (Current.Alpha shr 1) - Random(100);
              if Power < 0 then Power := 0;
              Spark.Alpha := Power;
          Spark.ByteOffset1 := -1;
          Spark.ByteOffset2 := -1;
          Spark.PreviousByteOffset1 := -1;
          Spark.PreviousByteOffset2 := -1;
            end;
            Dec(Current.Position.Y, Distance);
            Current.Alpha := 0;
          end;
          Current.Position.X := OffsetTable[Current.Position.Y and PeriodMask];
          Current.Alpha := AlphaTable[Current.Position.Y and PeriodMask];
          if Current.Position.Y < 64 then Current.Alpha := (Current.Position.Y * AlphaTable[Current.Position.Y and PeriodMask]) shr 6
          else Current.Alpha := AlphaTable[Current.Position.Y and PeriodMask];
          if Random(100) < 2 then begin
            Spark := AddParticle;
            Spark.Position := Current.Position;
            Spark.Color := Current.Color;
            if Current.Position.Y < 64 then Spark.Alpha := (255 * Current.Position.Y) shr 6
            else Spark.Alpha := 255;
            Spark.Velocity.X := 0;
            Spark.Velocity.Y := 2;
            Spark.State := 4;
            Spark.Radius := 30;
            Spark.Unknown2E := 40;
          Spark.ByteOffset1 := -1;
          Spark.ByteOffset2 := -1;
          Spark.PreviousByteOffset1 := -1;
          Spark.PreviousByteOffset2 := -1;
          end;
          if RemainingTicks < 24 then Current.State := 255;
        end;
        2: begin
          Inc(Current.Position.Y, Current.Velocity.Y);
          if Current.Position.Y > Distance then begin
            for I := 0 to 10 do begin
              Spark := AddParticle;
              Spark.Position := Current.Position;
              Spark.FloatPosition.X := Current.Position.X;
              Spark.FloatPosition.Y := Current.Position.Y;
              Spark.Color := Color2;
              Angle := Random(16) / 8.0 * Pi;
              Power := Random(50);
              Spark.FloatVelocity.X := Sin(Angle) * (Power + 50) / 50.0;
              Spark.FloatVelocity.Y := Cos(Angle) * (Power + 50) / 50.0;
              Spark.State := 5;
              Power := (Current.Alpha shr 1) - Random(100);
              if Power < 0 then Power := 0;
              Spark.Alpha := Power;
          Spark.ByteOffset1 := -1;
          Spark.ByteOffset2 := -1;
          Spark.PreviousByteOffset1 := -1;
          Spark.PreviousByteOffset2 := -1;
            end;
            Dec(Current.Position.Y, Distance);
            Current.Alpha := 0;
          end;
          Current.Position.X := OffsetTable[(Current.Position.Y + HalfPeriod) and PeriodMask];
          if Current.Position.Y < 64 then Current.Alpha := (Current.Position.Y * AlphaTable[(Current.Position.Y + HalfPeriod) and PeriodMask]) shr 6
          else Current.Alpha := AlphaTable[(Current.Position.Y + HalfPeriod) and PeriodMask];
          if Random(100) < 2 then begin
            Spark := AddParticle;
            Spark.Position := Current.Position;
            Spark.Color := Current.Color;
            if Current.Position.Y < 128 then Spark.Alpha := (255 * Current.Position.Y) shr 7
            else Spark.Alpha := 255;
            Spark.Velocity.X := 0;
            Spark.Velocity.Y := 2;
            Spark.State := 3;
            Spark.Radius := 30;
          Spark.ByteOffset1 := -1;
          Spark.ByteOffset2 := -1;
          Spark.PreviousByteOffset1 := -1;
          Spark.PreviousByteOffset2 := -1;
            Spark.Unknown2E := 40;
          end;
        end;
        3:
          begin
            Inc(Current.Position.Y, Current.Velocity.Y);
            I := OffsetTable[(Current.Position.Y + HalfPeriod) and PeriodMask];
            if I < 0 then Current.Position.X := -((Current.Radius * -I) shr 5)
            else Current.Position.X := (Current.Radius * I) shr 5;
            if Current.Alpha > 1 then Dec(Current.Alpha);
            Inc(Current.Radius, 2);
            if Current.Radius > 63 then Current.State := 255;
          end;
        4:
          begin
            Inc(Current.Position.Y, Current.Velocity.Y);
            I := OffsetTable[Current.Position.Y and PeriodMask];
            if I < 0 then Current.Position.X := -((Current.Radius * -I) shr 5)
            else Current.Position.X := (Current.Radius * I) shr 5;
            if Current.Alpha > 1 then Dec(Current.Alpha);
            Inc(Current.Radius, 2);
            if Current.Radius > 63 then Current.State := 255;
          end;
        5:
          begin
            Current.FloatPosition.Y := Current.FloatPosition.Y + Current.FloatVelocity.Y;
            Current.FloatPosition.X := Current.FloatPosition.X + Current.FloatVelocity.X;
            Current.Position.X := Trunc(Current.FloatPosition.X);
            Current.Position.Y := Trunc(Current.FloatPosition.Y);
            Current.FloatVelocity.Y := 0.95 * Current.FloatVelocity.Y;
            Current.FloatVelocity.X := 0.95 * Current.FloatVelocity.X;
            if Current.Alpha < 246 then Inc(Current.Alpha, 16);
            if Current.Alpha > 245 then Current.State := 6;
          end;
        6:
          begin
            Current.FloatPosition.Y := Current.FloatPosition.Y + Current.FloatVelocity.Y;
            Current.FloatPosition.X := Current.FloatPosition.X + Current.FloatVelocity.X;
            Current.Position.X := Trunc(Current.FloatPosition.X);
            Current.Position.Y := Trunc(Current.FloatPosition.Y);
            Current.FloatVelocity.Y := 0.95 * Current.FloatVelocity.Y;
            Current.FloatVelocity.X := 0.95 * Current.FloatVelocity.X;
            if Current.Alpha > 25 then Dec(Current.Alpha, 20);
            if Current.Alpha < 26 then Current.State := 255;
          end;
      end;
    end;
  end;
  Dec(RemainingTicks);
end;
{ @end $4979E4 }

{ @routine $498220 TPSRailRayGI_IsFinished }
function TPSRailRayGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $498220 }

{ @routine $49822C TPSRailRayGI_ClearSavedBackground }
procedure TPSRailRayGI.ClearSavedBackground;
var Particle: PRailRayParticle;
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
{ @end $49822C }

{ @routine $498300 TPSRailRayGI_ErasePreviousFrame }
procedure TPSRailRayGI.ErasePreviousFrame;
var Particle: PRailRayParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  if not SkipSavedPixelRestore then begin
    if not BGImage then begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), 0);
        if Particle.PreviousByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset2), 0);
        Particle := Particle.Next;
      end;
    end else begin
      Particle := FirstParticle;
      while Particle <> nil do begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), Particle.SavedPixel1);
        if Particle.PreviousByteOffset2 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset2), Particle.SavedPixel2);
        Particle := Particle.Next;
      end;

    end;
  end;
end;
{ @end $498300 }

{ @routine $4983CC TPSRailRayGI_PrepareFrameDraw }
procedure TPSRailRayGI.PrepareFrameDraw;
var
  Angle, Sine, Cosine, PX, PY: Double;
  Particle: PRailRayParticle;
  X, Y: Integer;
  Pitch: Integer;
  Buffer: Pointer;
begin
  Pitch := ScreenRenderBuffer.PitchBytes;
  Buffer := ScreenRenderBuffer.Pixels;
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Y = 0 then Inc(Y);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  while Particle <> nil do begin
    PX := Particle.Position.X * LengthScale;
    PY := -Particle.Position.Y * LengthScale;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    Particle.ByteOffset1 := -1;
    Particle.ByteOffset2 := -1;
    if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then
      if Particle.State <> 255 then Particle.ByteOffset1 := X * 2 + Y * Pitch;
    if ((X + 1) >= 0) and ((X + 1) < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then
      if Particle.State <> 255 then Particle.ByteOffset2 := (X + 1) * 2 + Y * Pitch;
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
{ @end $4983CC }

{ @routine $498598 TPSRailRayGI_DrawUpdateRects }
procedure TPSRailRayGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $498598 }

{ @routine $4985D0 TPSRailRayGI_Draw }
procedure TPSRailRayGI.Draw(ClipRect: TRect);
var Particle: PRailRayParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    if Particle.ByteOffset2 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset2), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $4985D0 }

{ @routine $498644 TPSRailRayGI_CommitFrameDraw }
procedure TPSRailRayGI.CommitFrameDraw;
var Particle, Current: PRailRayParticle; Buffer, Presented: Pointer;
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
    Current := Particle;
    Particle := Particle.Next;
    if Current.State = 255 then RemoveParticle(Current);
  end;
end;
{ @end $498644 }

{ @routine $49875C TPSBlueWhirlGI_Create }
constructor TPSBlueWhirlGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RailAttributes := 1;
end;
{ @end $49875C }

{ @routine $49879C TPSGreenWhirlGI_Create }
constructor TPSGreenWhirlGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  RailAttributes := 2;
end;
{ @end $49879C }

end.

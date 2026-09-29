unit GI_PSRocket;
// Unit bracket (inferred): CODE 0x00498814..0x00499EE5; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PRocketParticle = ^TRocketParticle;
  TRocketParticle = record // @size $38
    Prev: PRocketParticle; // @offset $0
    Next: PRocketParticle; // @offset $4
    Position: TPointF; // @offset $08
    Color: Word; // @offset $10
    SavedPixel1: Word; // @offset $12
    SavedPixel2: Word; // @offset $14
    Alpha: Byte; // @offset $16
    Velocity: TPointF; // @offset $18
    State: Byte; // @offset $20
    Unknown22: Word; // @offset $22 Initialized to 30000; not used by this update.
    ByteOffset1: Integer; // @offset $24
    PreviousByteOffset1: Integer; // @offset $28
    ByteOffset2: Integer; // @offset $2C
    PreviousByteOffset2: Integer; // @offset $30
  end;
  TPSRocketGI = class(TPSWeaponGI) // @size $138
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PRocketParticle; // @offset $114
    LastParticle: PRocketParticle; // @offset $118
    TimerInterval: Integer; // @offset $11C
    CallbackTimer: TCallbackTimerIdGI; // @offset $120
    Color1: Word; // @offset $124
    Color2: Word; // @offset $126
    ProjectionBounds: TRect; // @offset $128 Native projection rectangle, independently read by both bounds methods.

    constructor Create(Owner: TObjectGI); // @addr $498950
    destructor Destroy; override; // @addr $498A24
    procedure SetPosition(Position: TPoint); override; // @addr $498A60
    procedure SetTargetPoint(Point: TPoint); override; // @addr $498A98
    procedure SetHalfWidth(Value: Integer); // @addr $498AD8
    procedure SetTimerInterval(Value: Integer); // @addr $498AEC
    procedure RestartTimer; // @addr $498B00
    procedure CancelTimer; // @addr $498B04
    procedure SetActive(Enabled: Boolean); override; // @addr $498B28
    procedure UpdateProjectionBounds; // @addr $498B60
    procedure UpdateHitTestBounds; override; // @addr $498DDC
    function GetLocalBounds: TRect; override; // @addr $498E1C
    function AddParticle: PRocketParticle; // @addr $498E4C
    procedure RemoveParticle(Particle: PRocketParticle); // @addr $498E8C
    procedure ClearParticles; // @addr $498ED0
    procedure InvalidateRect(Rect: TRect); override; // @addr $498F00
    procedure Invalidate; override; // @addr $498FBC
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $498FC0
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $498FEC
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $499008
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4991EC
    function IsFinished: Boolean; override; // @addr $499964
    procedure ClearSavedBackground; // @addr $499970
    procedure ErasePreviousFrame; override; // @addr $499A44
    procedure PrepareFrameDraw; override; // @addr $499B10
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $499CC8
    procedure Draw(ClipRect: TRect); override; // @addr $499D00
    procedure CommitFrameDraw; override; // @addr $499D74
  end;

function NextRocketRandom: Integer; // @addr $498934
var
  RocketRandomIndex: Integer = 0; // @addr $617F1C
implementation
// @unit-initialization $499EBC
// @unit-finalization $499E8C

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;
var
  RocketInitializationIndex: Integer;

var
  RocketRandomValues: array[0..127] of Integer; // @addr $61BDCC Filled with Random(100) by native unit initialization $499EBC.

{ @routine $498934 NextRocketRandom }
function NextRocketRandom: Integer;
begin
  RocketRandomIndex := (RocketRandomIndex + 1) and $7F;
  Result := RocketRandomValues[RocketRandomIndex];
end;
{ @end $498934 }

{ @routine $498950 TPSRocketGI_Create }
constructor TPSRocketGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 4;
  TimerInterval := 45;
  UpdateProjectionBounds;
  RestartTimer;
  RemainingTicks := 60;
  LifetimeTicks := RemainingTicks;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(0.8, 0.7, 0.1);
  Color2 := CurrentPixelFormat.PackNormalizedRgb(0.8, 0.7, 0.4);
end;
{ @end $498950 }

{ @routine $498A24 TPSRocketGI_Destroy }
destructor TPSRocketGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $498A24 }

{ @routine $498A60 TPSRocketGI_SetPosition }
procedure TPSRocketGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $498A60 }

{ @routine $498A98 TPSRocketGI_SetTargetPoint }
procedure TPSRocketGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $498A98 }

{ @routine $498AD8 TPSRocketGI_SetHalfWidth }
procedure TPSRocketGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $498AD8 }

{ @routine $498AEC TPSRocketGI_SetTimerInterval }
procedure TPSRocketGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $498AEC }

{ @routine $498B00 TPSRocketGI_RestartTimer }
procedure TPSRocketGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $498B00 }

{ @routine $498B04 TPSRocketGI_CancelTimer }
procedure TPSRocketGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $498B04 }

{ @routine $498B28 TPSRocketGI_SetActive }
procedure TPSRocketGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $498B28 }

{ @routine $498B60 TPSRocketGI_UpdateProjectionBounds }
procedure TPSRocketGI.UpdateProjectionBounds;
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
{ @end $498B60 }

{ @routine $498DDC TPSRocketGI_UpdateHitTestBounds }
procedure TPSRocketGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X - 32;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y - 32;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X + 32;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y + 32;
end;
{ @end $498DDC }

{ @routine $498E1C TPSRocketGI_GetLocalBounds }
function TPSRocketGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $498E1C }

{ @routine $498E4C TPSRocketGI_AddParticle }
function TPSRocketGI.AddParticle: PRocketParticle;
var Particle: PRocketParticle;
begin
  Particle := AllocEC(SizeOf(TRocketParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $498E4C }

{ @routine $498E8C TPSRocketGI_RemoveParticle }
procedure TPSRocketGI.RemoveParticle(Particle: PRocketParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $498E8C }

{ @routine $498ED0 TPSRocketGI_ClearParticles }
procedure TPSRocketGI.ClearParticles;
var Particle, Current: PRocketParticle;
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
{ @end $498ED0 }

{ @routine $498F00 TPSRocketGI_InvalidateRect }
procedure TPSRocketGI.InvalidateRect(Rect: TRect);
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
{ @end $498F00 }

{ @routine $498FBC TPSRocketGI_Invalidate }
procedure TPSRocketGI.Invalidate;
begin

end;
{ @end $498FBC }

{ @routine $498FC0 TPSRocketGI_LoadFromConfigPath }
procedure TPSRocketGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $498FC0 }

{ @routine $498FEC TPSRocketGI_LoadFromBlock }
procedure TPSRocketGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $498FEC }

{ @routine $499008 TPSRocketGI_LoadEffectProperties }
procedure TPSRocketGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
  if Block.CountParams('Color2') > 0 then Color1 := GetColorGI(Block.GetParam('Color2')); // Native Color2 overwrites Color1.
end;
{ @end $499008 }

{ @routine $4991EC TPSRocketGI_Advance }
procedure TPSRocketGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Y: Single;
  I, Power, J: Integer;
  Distance: Single;
  Current, Spark, Particle: PRocketParticle;
  Speed: Single;
begin
  if (FirstParticle = nil) and (RemainingTicks > 20) then
  begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    Speed := 4.1;
    if Distance / Speed > 38.0 then Speed := Distance / 38.0;
    while (Y < Distance) and (Y < 128.0) do
    begin
      for J := 0 to 1 do
      begin
        Particle := AddParticle;
        I := Random(HalfWidth * 2 + 1) - HalfWidth;
        Particle.Position.X := I + J;
        Particle.Position.Y := Y;
        Particle.Color := Color1;
        if Y < 32.0 then Particle.Alpha := Trunc(255.0 * Y) shr 5;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := Speed;
        Particle.ByteOffset1 := -1;
        Particle.PreviousByteOffset1 := -1;
        Particle.ByteOffset2 := -1;
        Particle.PreviousByteOffset2 := -1;
        Particle.State := 1;
        Particle.Unknown22 := 30000;
        Particle := AddParticle;
        Particle.Position.X := I + J;
        Particle.Position.Y := Y + 1.0;
        Particle.Color := Color1;
        if Y < 32.0 then Particle.Alpha := Trunc(255.0 * Y) shr 5;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := Speed;
        Particle.State := 1;
        Particle.ByteOffset1 := -1;
        Particle.PreviousByteOffset1 := -1;
        Particle.ByteOffset2 := -1;
        Particle.PreviousByteOffset2 := -1;
        Particle.Unknown22 := 30000;
        Particle := AddParticle;
        Particle.Position.X := I + J;
        Particle.Position.Y := Y + 2.0;
        Particle.Color := Color1;
        if Y < 32.0 then Particle.Alpha := Trunc(255.0 * Y) shr 5;
        Particle.Velocity.X := 0;
        Particle.Velocity.Y := Speed;
        Particle.State := 1;
        Particle.ByteOffset1 := -1;
        Particle.PreviousByteOffset1 := -1;
        Particle.ByteOffset2 := -1;
        Particle.PreviousByteOffset2 := -1;
        Particle.Unknown22 := 30000;
      end;
      Y := Y + 64.0;
    end;
  end
  else
  begin
    Distance := Trunc(Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)));
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
        1:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            if Current.Position.Y > Distance then
            begin
              for I := 0 to 11 do
              begin
                Spark := AddParticle;
                Spark.Position.X := Current.Position.X;
                Spark.Position.Y := Current.Position.Y;
                Spark.Color := Color2;
                Y := Random(16) / 8.0 * Pi;
                Power := Random(50);
                Spark.Velocity.X := Sin(Y) * (Power + 50) / 50.0;
                Spark.Velocity.Y := Cos(Y) * (Power + 50) / 50.0;
                Spark.State := 4;
        Spark.ByteOffset1 := -1;
        Spark.PreviousByteOffset1 := -1;
        Spark.ByteOffset2 := -1;
        Spark.PreviousByteOffset2 := -1;
                Power := (Current.Alpha shr 1) - NextRocketRandom;
                if Power < 0 then Power := 0;
                Spark.Alpha := Power;
              end;
              Current.State := 255;
              RemainingTicks := 20;
            end
            else
            begin
              if Current.Position.Y < 32.0 then Current.Alpha := Trunc(Current.Position.Y * 255.0) shr 5
              else Current.Alpha := 255;
              if NextRocketRandom < 17 then
              begin
                Spark := AddParticle;
                Spark.Position.X := Current.Position.X + NextRocketRandom / 100.0 - 0.5;
                Spark.Position.Y := Current.Position.Y - 1.0;
                Spark.Color := Current.Color;
                Spark.Velocity.X := Spark.Position.X - Current.Position.X;
                Spark.Velocity.Y := Current.Velocity.Y * 0.75;
                Spark.State := 2;
                Spark.Unknown22 := 30000;
        Spark.ByteOffset1 := -1;
        Spark.PreviousByteOffset1 := -1;
        Spark.ByteOffset2 := -1;
        Spark.PreviousByteOffset2 := -1;
                I := Current.Alpha - Random(128);
                if I > 255 then I := 255
                else if I < 0 then I := 0;
                Spark.Alpha := I;
              end;
            end;
          end;
        2: Inc(Current.State);
        3:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Velocity.Y := 0.95 * Current.Velocity.Y;
            if Current.Alpha > 8 then Dec(Current.Alpha, 9);
            if Current.Alpha < 15 then
            begin
              Current.State := 255;
              Current := nil;
            end;
            if (Current <> nil) and (NextRocketRandom < 14) then
            begin
              Spark := AddParticle;
              Spark.Position.X := Current.Position.X + NextRocketRandom / 400.0 - 0.125;
              Spark.Position.Y := Current.Position.Y - 1.0;
              Spark.Color := Current.Color;
              Spark.Velocity.X := Spark.Position.X - Current.Position.X + Current.Velocity.X;
              Spark.Velocity.Y := 0.7 * Current.Velocity.Y;
              Spark.State := 2;
              Spark.Unknown22 := 30000;
        Spark.ByteOffset1 := -1;
        Spark.PreviousByteOffset1 := -1;
        Spark.ByteOffset2 := -1;
        Spark.PreviousByteOffset2 := -1;
              I := Current.Alpha + Random(60) - 32;
              if I > 255 then I := 255
              else if I < 0 then I := 0;
              Spark.Alpha := I;
            end;
          end;
        4:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Velocity.Y := 0.95 * Current.Velocity.Y;
            Current.Velocity.X := 0.95 * Current.Velocity.X;
            if Current.Alpha < 246 then Inc(Current.Alpha, 10);
            if Current.Alpha > 245 then Current.State := 5;
          end;
        5:
          begin
            Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
            Current.Position.X := Current.Position.X + Current.Velocity.X;
            Current.Velocity.Y := 0.95 * Current.Velocity.Y;
            Current.Velocity.X := 0.95 * Current.Velocity.X;
            if Current.Alpha > 25 then Dec(Current.Alpha, 26);
            if Current.Alpha < 26 then Current.State := 255;
          end;
      end;
    end;
  end;
  Dec(RemainingTicks);
end;
{ @end $4991EC }

{ @routine $499964 TPSRocketGI_IsFinished }
function TPSRocketGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $499964 }

{ @routine $499970 TPSRocketGI_ClearSavedBackground }
procedure TPSRocketGI.ClearSavedBackground;
var Particle: PRocketParticle;
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
{ @end $499970 }

{ @routine $499A44 TPSRocketGI_ErasePreviousFrame }
procedure TPSRocketGI.ErasePreviousFrame;
var Particle: PRocketParticle; Buffer: Pointer;
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
{ @end $499A44 }

{ @routine $499B10 TPSRocketGI_PrepareFrameDraw }
procedure TPSRocketGI.PrepareFrameDraw;
var
  Angle, Sine, Cosine, PX, PY: Double;
  X, Y: Integer;
  Particle: PRocketParticle;
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
    PX := Particle.Position.X;
    PY := -Particle.Position.Y;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    Particle.ByteOffset1 := -1;
    Particle.ByteOffset2 := -1;
    if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) and (Particle.State <> 255) then Particle.ByteOffset1 := X * 2 + Y * Pitch;
    if ((X - 1) >= 0) and ((X - 1) < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) and (Particle.State <> 255) then Particle.ByteOffset2 := (X - 1) * 2 + Y * Pitch;
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
{ @end $499B10 }

{ @routine $499CC8 TPSRocketGI_DrawUpdateRects }
procedure TPSRocketGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $499CC8 }

{ @routine $499D00 TPSRocketGI_Draw }
procedure TPSRocketGI.Draw(ClipRect: TRect);
var Particle: PRocketParticle; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    if Particle.ByteOffset2 >= 0 then GR_Main.BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset2), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $499D00 }

{ @routine $499D74 TPSRocketGI_CommitFrameDraw }
procedure TPSRocketGI.CommitFrameDraw;
var Particle, Current: PRocketParticle; Buffer, Presented: Pointer;
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
{ @end $499D74 }

initialization
  for RocketInitializationIndex := 0 to 127 do
    RocketRandomValues[RocketInitializationIndex] := Random(100);
end.

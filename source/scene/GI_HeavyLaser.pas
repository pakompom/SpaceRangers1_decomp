unit GI_HeavyLaser;
// Unit bracket (inferred): CODE 0x0049ACE8..0x0049BEA7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PHeavyLaserParticle = ^THeavyLaserParticle;
  THeavyLaserParticle = record // @size $38
    Prev: PHeavyLaserParticle; // @offset $0
    Next: PHeavyLaserParticle; // @offset $4
    Position: TPointF; // @offset $08
    Color: Word; // @offset $10
    Alpha: Byte; // @offset $12
    Velocity: TPointF; // @offset $14
    State: Byte; // @offset $1C
    RemainingTicks: Word; // @offset $1E
    SavedPixel1: Word; // @offset $20
    SavedPixel2: Word; // @offset $22
    ByteOffset1: Integer; // @offset $24
    PreviousByteOffset1: Integer; // @offset $28
    ByteOffset2: Integer; // @offset $2C
    PreviousByteOffset2: Integer; // @offset $30
  end;
  TPSHeavyLaserGI = class(TPSWeaponGI) // @size $140
  public
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $49B350
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    procedure Draw(ClipRect: TRect); override; // @addr $49BC14
    Period: Integer; // @offset $114
    PeriodMask: Integer; // @offset $118
    Phase: Single; // @offset $11C
    FirstParticle: PHeavyLaserParticle; // @offset $120
    LastParticle: PHeavyLaserParticle; // @offset $124
    TimerInterval: Integer; // @offset $128
    CallbackTimer: TCallbackTimerIdGI; // @offset $12C
    ProjectionBounds: TRect; // @offset $130 Native projection rectangle, independently read by both bounds methods.

    constructor Create(Owner: TObjectGI); // @addr $49AE0C
    destructor Destroy; override; // @addr $49AE7C
    procedure SetPeriod(Value: Integer); // @addr $49AEB8
    procedure SetPosition(Position: TPoint); override; // @addr $49AEC8
    procedure SetTargetPoint(Point: TPoint); override; // @addr $49AF00
    procedure SetHalfWidth(Value: Integer); // @addr $49AF40
    procedure SetTimerInterval(Value: Integer); // @addr $49AF54
    procedure RestartTimer; // @addr $49AF68
    procedure CancelTimer; // @addr $49AF6C
    procedure SetActive(Enabled: Boolean); override; // @addr $49AF90
    procedure UpdateProjectionBounds; // @addr $49AFC8
    procedure UpdateHitTestBounds; override; // @addr $49B02C
    function GetLocalBounds: TRect; override; // @addr $49B060
    function AddParticle: PHeavyLaserParticle; // @addr $49B090
    procedure RemoveParticle(Particle: PHeavyLaserParticle); // @addr $49B0D0
    procedure ClearParticles; // @addr $49B114
    procedure InvalidateRect(Rect: TRect); override; // @addr $49B144 Native slot $88; ignores the supplied rectangle.
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49B150
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49B17C
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $49B198
    procedure ClearSavedBackground; // @addr $49B878
    procedure ErasePreviousFrame; override; // @addr $49B94C
    procedure PrepareFrameDraw; override; // @addr $49BA18
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $49BBDC
    procedure CommitFrameDraw; override; // @addr $49BD58
  end;

implementation

// @unit-initialization $49BEA0
// @unit-finalization $49BE70

uses Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $49AE0C TPSHeavyLaserGI_Create }
constructor TPSHeavyLaserGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 16;
  TimerInterval := 45;
  Period := 32;
  PeriodMask := Period - 1;
  UpdateProjectionBounds;
  RestartTimer;
end;
{ @end $49AE0C }

{ @routine $49AE7C TPSHeavyLaserGI_Destroy }
destructor TPSHeavyLaserGI.Destroy;
begin
  ClearSavedBackground;
  ClearParticles;
  CancelTimer;
  inherited Destroy;
end;
{ @end $49AE7C }

{ @routine $49AEB8 TPSHeavyLaserGI_SetPeriod }
procedure TPSHeavyLaserGI.SetPeriod(Value: Integer);
begin
  Period := Value;
  PeriodMask := Period - 1;
end;
{ @end $49AEB8 }

{ @routine $49AEC8 TPSHeavyLaserGI_SetPosition }
procedure TPSHeavyLaserGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $49AEC8 }

{ @routine $49AF00 TPSHeavyLaserGI_SetTargetPoint }
procedure TPSHeavyLaserGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $49AF00 }

{ @routine $49AF40 TPSHeavyLaserGI_SetHalfWidth }
procedure TPSHeavyLaserGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $49AF40 }

{ @routine $49AF54 TPSHeavyLaserGI_SetTimerInterval }
procedure TPSHeavyLaserGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $49AF54 }

{ @routine $49AF68 TPSHeavyLaserGI_RestartTimer }
procedure TPSHeavyLaserGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $49AF68 }

{ @routine $49AF6C TPSHeavyLaserGI_CancelTimer }
procedure TPSHeavyLaserGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $49AF6C }

{ @routine $49AF90 TPSHeavyLaserGI_SetActive }
procedure TPSHeavyLaserGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
    if not Enabled then ClearSavedBackground;
  end;
end;
{ @end $49AF90 }

{ @routine $49AFC8 TPSHeavyLaserGI_UpdateProjectionBounds }
procedure TPSHeavyLaserGI.UpdateProjectionBounds;
begin
  ProjectionBounds.Left := TargetPoint.X - LocalPosition.X - HalfWidth - 8;
  ProjectionBounds.Right := TargetPoint.X - LocalPosition.X + HalfWidth + 8;
  ProjectionBounds.Top := TargetPoint.Y - LocalPosition.Y - HalfWidth - 8;
  ProjectionBounds.Bottom := TargetPoint.Y - LocalPosition.Y + HalfWidth + 8;
end;
{ @end $49AFC8 }

{ @routine $49B02C TPSHeavyLaserGI_UpdateHitTestBounds }
procedure TPSHeavyLaserGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $49B02C }

{ @routine $49B060 TPSHeavyLaserGI_GetLocalBounds }
function TPSHeavyLaserGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $49B060 }

{ @routine $49B090 TPSHeavyLaserGI_AddParticle }
function TPSHeavyLaserGI.AddParticle: PHeavyLaserParticle;
var Particle: PHeavyLaserParticle;
begin
  Particle := AllocEC(SizeOf(THeavyLaserParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $49B090 }

{ @routine $49B0D0 TPSHeavyLaserGI_RemoveParticle }
procedure TPSHeavyLaserGI.RemoveParticle(Particle: PHeavyLaserParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $49B0D0 }

{ @routine $49B114 TPSHeavyLaserGI_ClearParticles }
procedure TPSHeavyLaserGI.ClearParticles;
var Particle, Current: PHeavyLaserParticle;
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
{ @end $49B114 }

{ @routine $49B144 TPSHeavyLaserGI_InvalidateRect }
procedure TPSHeavyLaserGI.InvalidateRect(Rect: TRect);
begin
  MessageLoop.QueueUpdateRect(HitTestBounds);
end;
{ @end $49B144 }

{ @routine $49B150 TPSHeavyLaserGI_LoadFromConfigPath }
procedure TPSHeavyLaserGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49B150 }

{ @routine $49B17C TPSHeavyLaserGI_LoadFromBlock }
procedure TPSHeavyLaserGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $49B17C }

{ @routine $49B198 TPSHeavyLaserGI_LoadEffectProperties }
procedure TPSHeavyLaserGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('Period') > 0 then SetPeriod(StrToInt(AnsiString(Block.GetParam('Period'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
end;
{ @end $49B198 }

{ @routine $49B350 TPSHeavyLaserGI_Advance }
procedure TPSHeavyLaserGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Direction: Integer; Y, Distance, Angle: Single; Particle, Current, Spark: PHeavyLaserParticle;
begin
  Invalidate;
  Particle := FirstParticle;
  if Particle = nil then begin
    Y := 0;
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    while Y < Distance do begin
      Particle := AddParticle;
      Angle := Y / Period * 2.0 * Pi;
      Particle.Position.X := 3;
      Particle.Position.Y := Y;
      Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.1, 0.1);
      Particle.Alpha := Trunc(Sin(Angle) * 63.0 + 192.0);
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Particle.ByteOffset1 := -1;
      Particle.ByteOffset2 := -1;
      Particle.PreviousByteOffset1 := -1;
      Particle.PreviousByteOffset2 := -1;
      Particle.SavedPixel1 := 0;
      Particle.SavedPixel2 := 0;
      Particle := AddParticle;
      Particle.Position.X := -3;
      Particle.Position.Y := Y;
      Particle.Color := CurrentPixelFormat.PackNormalizedRgb(1.0, 0.1, 0.1);
      Particle.Alpha := Trunc(Sin(Angle) * 63.0 + 192.0);
      Particle.Velocity.X := 0;
      Particle.Velocity.Y := 4;
      Particle.State := 1;
      Particle.ByteOffset1 := -1;
      Particle.ByteOffset2 := -1;
      Particle.PreviousByteOffset1 := -1;
      Particle.PreviousByteOffset2 := -1;
      Particle.SavedPixel1 := 0;
      Particle.SavedPixel2 := 0;
      Y := Y + 1.0;
    end;
    Phase := 0;
  end else begin
    Distance := Trunc(Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)));
    while Particle <> nil do begin
      Current := Particle;
      case Particle.State of
        1: begin
          Particle := Particle.Next;
          Current.Position.Y := Current.Position.Y + Current.Velocity.Y;
          Current.Position.X := Current.Position.X + Current.Velocity.X;
          if Current.Position.Y > Distance then begin
            Spark := AddParticle;
            Spark.Position.X := Current.Position.X;
            Spark.Position.Y := Current.Position.Y;
            Spark.Color := Current.Color;
            Spark.Alpha := Current.Alpha;
            Spark.Velocity.X := Random(8);
            Spark.Velocity.Y := 0;
            Spark.State := 2;
            Spark.RemainingTicks := 14;
      Spark.ByteOffset1 := -1;
      Spark.ByteOffset2 := -1;
      Spark.PreviousByteOffset1 := -1;
      Spark.PreviousByteOffset2 := -1;
      Spark.SavedPixel1 := 0;
      Spark.SavedPixel2 := 0;
            Current.Velocity.Y := 4;
            Current.Position.Y := Current.Position.Y - Distance;
          end;
        end;
        2: begin
          Particle.State := 3;
          Particle := Particle.Next;
        end;
        3: begin
          Particle := Particle.Next;
          if Current.Alpha > 1 then Dec(Current.Alpha, 2);
          repeat
            Direction := Random(8);
            if (((Direction < 4) and (Current.Velocity.X < 4)) or ((Direction > 3) and (Current.Velocity.X > 3))) and (Abs(Direction - Current.Velocity.X) < 2) then Break
            else if (Direction > 3) and (Current.Velocity.X < 4) and (Abs(8.0 + Current.Velocity.X - Direction) < 2) then Break
            else if (Direction < 4) and (Current.Velocity.X > 3) and (Abs(Direction + 8 - Current.Velocity.X) < 2) then Break;
          until False;
          Current.Velocity.X := Direction;
          if Direction = 0 then begin
            Current.Position.X := Current.Position.X + 1.0;
            Current.Position.Y := Current.Position.Y + 0.0;
          end else if Direction = 1 then begin
            Current.Position.X := Current.Position.X + 1.0;
            Current.Position.Y := Current.Position.Y + 1.0;
          end else if Direction = 2 then begin
            Current.Position.X := Current.Position.X + 0.0;
            Current.Position.Y := Current.Position.Y + 1.0;
          end else if Direction = 3 then begin
            Current.Position.X := Current.Position.X - 1.0;
            Current.Position.Y := Current.Position.Y + 1.0;
          end else if Direction = 4 then begin
            Current.Position.X := Current.Position.X - 1.0;
            Current.Position.Y := Current.Position.Y + 0.0;
          end else if Direction = 5 then begin
            Current.Position.X := Current.Position.X - 1.0;
            Current.Position.Y := Current.Position.Y - 1.0;
          end else if Direction = 6 then begin
            Current.Position.X := Current.Position.X + 0.0;
            Current.Position.Y := Current.Position.Y - 1.0;
          end else begin
            Current.Position.X := Current.Position.X + 1.0;
            Current.Position.Y := Current.Position.Y - 1.0;
          end;
          Dec(Current.RemainingTicks);
          if Current.RemainingTicks = 0 then Current.State := 255;
        end;
        else Particle := Particle.Next;
      end;
    end;
    Phase := Pi / 8 + Phase;
  end;
end;
{ @end $49B350 }

{ @routine $49B878 TPSHeavyLaserGI_ClearSavedBackground }
procedure TPSHeavyLaserGI.ClearSavedBackground;
var Particle: PHeavyLaserParticle;
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
{ @end $49B878 }

{ @routine $49B94C TPSHeavyLaserGI_ErasePreviousFrame }
procedure TPSHeavyLaserGI.ErasePreviousFrame;
var Particle: PHeavyLaserParticle; Buffer: Pointer;
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
{ @end $49B94C }

{ @routine $49BA18 TPSHeavyLaserGI_PrepareFrameDraw }
procedure TPSHeavyLaserGI.PrepareFrameDraw;
var
  Buffer: Pointer;
  Pitch: Integer;
  Angle, Sine, Cosine, PX, PY: Single;
  X, Y: Integer;
  Particle: PHeavyLaserParticle;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Y := -(TargetPoint.Y - LocalPosition.Y);
  if Abs(Y) < 1 then Y := 1;
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, Y);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Particle := FirstParticle;
  while Particle <> nil do begin
    Particle.ByteOffset1 := -1;
    Particle.ByteOffset2 := -1;
    if Particle.State <> 255 then begin
    PX := Particle.Position.X;
    PY := -Particle.Position.Y;
    X := Round(PX * Cosine - PY * Sine + AbsolutePosition.X);
    Y := Round(PX * Sine + PY * Cosine + AbsolutePosition.Y);
    if (X >= 0) and (X < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset1 := X * 2 + Y * Pitch;
    if ((X + 1) >= 0) and ((X + 1) < GameScreenWidth) and (Y >= 0) and (Y < GameScreenHeight) then Particle.ByteOffset2 := (X + 1) * 2 + Y * Pitch;
    end;
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
{ @end $49BA18 }

{ @routine $49BBDC TPSHeavyLaserGI_DrawUpdateRects }
procedure TPSHeavyLaserGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $49BBDC }

{ @routine $49BC14 TPSHeavyLaserGI_Draw }
procedure TPSHeavyLaserGI.Draw(ClipRect: TRect);
var TargetX, TargetY: Integer; Buffer: Pointer; I: Integer; Particle: PHeavyLaserParticle;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  TargetX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  TargetY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  I := -HalfWidth;
  while I < HalfWidth do begin
    ScreenRenderBuffer.ShiftBand16(TargetX - HalfWidth - 1 + Abs(I), TargetY + I,
      (HalfWidth + 1 - Abs(I)) * 2, 2, Trunc(Sin(I * Pi / 8.0 + Phase) * 6.0), ClipRect);
    Inc(I, 2);
  end;
  Particle := FirstParticle;
  while Particle <> nil do begin
    if Particle.ByteOffset1 >= 0 then BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    if Particle.ByteOffset2 >= 0 then BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset2), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
end;
{ @end $49BC14 }

{ @routine $49BD58 TPSHeavyLaserGI_CommitFrameDraw }
procedure TPSHeavyLaserGI.CommitFrameDraw;
var Particle, Current: PHeavyLaserParticle; Buffer, Presented: Pointer;
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
{ @end $49BD58 }

end.

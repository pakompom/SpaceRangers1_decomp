unit GI_PSEyes;
// Unit bracket (inferred): CODE 0x0049ECD8..0x004A0347; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PEyesLine = ^TEyesLine;
  TEyesLine = packed record // @size $9C
    Next: PEyesLine; // @offset $0
    Prev: PEyesLine; // @offset $4
    First: TPoint; // @offset $8
    Last: TPoint; // @offset $10
    Color: Word; // @offset $18
    PreviousFrame: Boolean; // @offset $1A
    SavedPixels: array[0..63] of Word; // @offset $1B
    Alpha: Byte; // @offset $9B
  end;
  PEyesParticle = ^TEyesParticle;
  TEyesParticle = record // @size $38
    Prev: PEyesParticle; // @offset $0
    Next: PEyesParticle; // @offset $4
    Origin: TPointF; // @offset $8
    Position: TPointF; // @offset $10
    Color: Word; // @offset $18
    SavedPixel1: Word; // @offset $1A
    ByteOffset1: Integer; // @offset $1C
    PreviousByteOffset1: Integer; // @offset $20
    Alpha: Byte; // @offset $24
    Velocity: TPointF; // @offset $28
    State: Byte; // @offset $30
    Countdown: Integer; // @offset $34
  end;
  TPSEyesGI = class(TPSWeaponGI) // @size $13C
  public
    procedure InvalidateRect(Rect: TRect); override; // @addr $49F3E0
    procedure SelectParticleColors; // @addr $49FA40
    procedure ErasePreviousFrame; override; // @addr $49FAD8
    procedure PrepareFrameDraw; override; // @addr $49FBF8
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4A0118
    procedure Draw(ClipRect: TRect); override; // @addr $4A0154
    procedure CommitFrameDraw; override; // @addr $4A0208
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PEyesParticle; // @offset $114
    LastParticle: PEyesParticle; // @offset $118
    FirstLine: PEyesLine; // @offset $11C
    LastLine: PEyesLine; // @offset $120
    ProjectionBounds: TRect; // @offset $124 Native projection rectangle, independently read by both bounds methods.
    Color: Word; // @offset $134
    DarkColor: Word; // @offset $136
    BeamTicks: Integer; // @offset $138

    constructor Create(Owner: TObjectGI); // @addr $49EDF8
    destructor Destroy; override; // @addr $49EECC
    procedure SetPosition(Position: TPoint); override; // @addr $49EF14
    procedure SetTargetPoint(Point: TPoint); override; // @addr $49EF4C
    procedure SetHalfWidth(Value: Integer); // @addr $49EF8C
    procedure SetActive(Enabled: Boolean); override; // @addr $49EFA0
    procedure UpdateProjectionBounds; // @addr $49EFAC
    procedure UpdateHitTestBounds; override; // @addr $49F210
    function GetLocalBounds: TRect; override; // @addr $49F244
    function AddParticle: PEyesParticle; // @addr $49F274
    procedure RemoveParticle(Particle: PEyesParticle); // @addr $49F2B4
    procedure ClearParticles; // @addr $49F2F8
    function AddLine: PEyesLine; // @addr $49F328
    procedure RemoveLine(Line: PEyesLine); // @addr $49F368
    procedure ClearLines; // @addr $49F3AC
    procedure Invalidate; override; // @addr $49F3DC
    procedure ClearSavedBackground; // @addr $49F498
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49F51C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49F548
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $49F564
    procedure EmitBurst(Point: TPoint; Radius: Integer); // @addr $49F654
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $49F838
    function IsFinished: Boolean; override; // @addr $49FA34
  end;

implementation

// @unit-initialization $4A0340
// @unit-finalization $4A0310

uses GR_GraphBuf, EC_OKGF, aMyFunction, Classes, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $49EDF8 TPSEyesGI_Create }
constructor TPSEyesGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfWidth := 32;
  RemainingTicks := 60;
  LifetimeTicks := RemainingTicks;
  Color := CurrentPixelFormat.PackNormalizedRgb(0.9, 0.7, 1);
  DarkColor := CurrentPixelFormat.PackNormalizedRgb(0.25, 0.15, 0.6);
  BeamTicks := 20;
  UpdateProjectionBounds;
  FirstLine := nil;
  LastLine := nil;
end;
{ @end $49EDF8 }

{ @routine $49EECC TPSEyesGI_Destroy }
destructor TPSEyesGI.Destroy;
begin
  ClearSavedBackground;
  InvalidateRect(HitTestBounds);
  ClearLines;
  ClearParticles;
  inherited Destroy;
end;
{ @end $49EECC }

{ @routine $49EF14 TPSEyesGI_SetPosition }
procedure TPSEyesGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $49EF14 }

{ @routine $49EF4C TPSEyesGI_SetTargetPoint }
procedure TPSEyesGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $49EF4C }

{ @routine $49EF8C TPSEyesGI_SetHalfWidth }
procedure TPSEyesGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $49EF8C }

{ @routine $49EFA0 TPSEyesGI_SetActive }
procedure TPSEyesGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then inherited SetActive(Enabled);
end;
{ @end $49EFA0 }

{ @routine $49EFAC TPSEyesGI_UpdateProjectionBounds }
procedure TPSEyesGI.UpdateProjectionBounds;
var
  Distance, Angle, Sine, Cosine, A, B, C, D: Single;
  DY: Integer;
begin
  DY := -(TargetPoint.Y - LocalPosition.Y);
  if DY = 0 then Inc(DY);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, DY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
  A := (-HalfWidth) * Cosine - -Distance * Sine;
  B := HalfWidth * Cosine - -Distance * Sine;
  C := (-HalfWidth) * Cosine;
  D := HalfWidth * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth) * Sine + -Distance * Cosine;
  B := HalfWidth * Sine + -Distance * Cosine;
  C := (-HalfWidth) * Sine;
  // Native uses Cosine for this final corner as well.
  D := HalfWidth * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;
{ @end $49EFAC }

{ @routine $49F210 TPSEyesGI_UpdateHitTestBounds }
procedure TPSEyesGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $49F210 }

{ @routine $49F244 TPSEyesGI_GetLocalBounds }
function TPSEyesGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $49F244 }

{ @routine $49F274 TPSEyesGI_AddParticle }
function TPSEyesGI.AddParticle: PEyesParticle;
var Particle: PEyesParticle;
begin
  Particle := AllocEC(SizeOf(TEyesParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $49F274 }

{ @routine $49F2B4 TPSEyesGI_RemoveParticle }
procedure TPSEyesGI.RemoveParticle(Particle: PEyesParticle);
begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
end;
{ @end $49F2B4 }

{ @routine $49F2F8 TPSEyesGI_ClearParticles }
procedure TPSEyesGI.ClearParticles;
var Particle, Current: PEyesParticle;
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
{ @end $49F2F8 }

{ @routine $49F328 TPSEyesGI_AddLine }
function TPSEyesGI.AddLine: PEyesLine;
var Line: PEyesLine;
begin
  Line := AllocEC(SizeOf(TEyesLine));
  if LastLine <> nil then LastLine.Next := Line;
  Line.Prev := LastLine;
  Line.Next := nil;
  LastLine := Line;
  if FirstLine = nil then FirstLine := Line;
  Result := Line;
end;
{ @end $49F328 }

{ @routine $49F368 TPSEyesGI_RemoveLine }
procedure TPSEyesGI.RemoveLine(Line: PEyesLine);
begin
  if Line.Prev <> nil then Line.Prev.Next := Line.Next;
  if Line.Next <> nil then Line.Next.Prev := Line.Prev;
  if LastLine = Line then LastLine := Line.Prev;
  if FirstLine = Line then FirstLine := Line.Next;
  FreeEC(Line);
end;
{ @end $49F368 }

{ @routine $49F3AC TPSEyesGI_ClearLines }
procedure TPSEyesGI.ClearLines;
var Line, Current: PEyesLine;
begin
  Line := FirstLine;
  while Line <> nil do begin
    Current := Line;
    Line := Line.Next;
    FreeEC(Current);
  end;
  FirstLine := nil;
  LastLine := nil;
end;
{ @end $49F3AC }

{ @routine $49F3DC TPSEyesGI_Invalidate }
procedure TPSEyesGI.Invalidate;
begin

end;
{ @end $49F3DC }

{ @routine $49F3E0 TPSEyesGI_InvalidateRect }
procedure TPSEyesGI.InvalidateRect(Rect: TRect);
var
  Target: TPoint;
  Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(HitTestBounds, Parent.ToAbsolutePoint(LocalPosition), Parent.ToAbsolutePoint(TargetPoint), 4);
  Target := Parent.ToAbsolutePoint(TargetPoint);
  Rect.Left := Target.X - HalfWidth;
  Rect.Right := Target.X + HalfWidth;
  Rect.Top := Target.Y - HalfWidth;
  Rect.Bottom := Target.Y + HalfWidth;
  if IntersectRects(Intersection, Rect, GameScreenRect) then
    MessageLoop.QueueUpdateRect(Intersection);
end;
{ @end $49F3E0 }

{ @routine $49F498 TPSEyesGI_ClearSavedBackground }
procedure TPSEyesGI.ClearSavedBackground;
var Particle: PEyesParticle;
begin
  if not BGImage then begin
    Particle := FirstParticle;
    while Particle <> nil do begin
      if Particle.PreviousByteOffset1 >= 0 then begin
        MessageLoop.SavePixel16(Particle.PreviousByteOffset1, 0);
        MessageLoop.QueuePixelPresent(Particle.PreviousByteOffset1);
        Particle.PreviousByteOffset1 := -1;
      end;
      Particle := Particle.Next;
    end;
  end else begin
    Particle := FirstParticle;
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
{ @end $49F498 }

{ @routine $49F51C TPSEyesGI_LoadFromConfigPath }
procedure TPSEyesGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49F51C }

{ @routine $49F548 TPSEyesGI_LoadFromBlock }
procedure TPSEyesGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $49F548 }

{ @routine $49F564 TPSEyesGI_LoadEffectProperties }
procedure TPSEyesGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
end;
{ @end $49F564 }

{ @routine $49F654 TPSEyesGI_EmitBurst }
procedure TPSEyesGI.EmitBurst(Point: TPoint; Radius: Integer);
var
  X, Y: Integer;
  Particle: PEyesParticle;
begin
  for Y := -Radius to Radius do
    for X := -Radius + Abs(Y) to Radius - Abs(Y) do
    begin
      Particle := AddParticle;
      Particle.Origin := MakePointF(Point.X, Point.Y);
      Particle.Position := Particle.Origin;
      Particle.Color := Color;
      Particle.Alpha := 255;
      Particle.State := 1;
      Particle.Countdown := 7;
      Particle.ByteOffset1 := -1;
      Particle.PreviousByteOffset1 := -1;
      Particle.Velocity := MakePointF(X / Radius * 1.1, Y / Radius * 1.1);
      if Particle.Velocity.X < 0 then Particle.Velocity.X := Particle.Velocity.X - Random(11) / 16.0
      else Particle.Velocity.X := Particle.Velocity.X + Random(11) / 16.0;
      if Particle.Velocity.Y < 0 then Particle.Velocity.Y := Particle.Velocity.Y - Random(11) / 16.0
      else Particle.Velocity.Y := Particle.Velocity.Y + Random(11) / 16.0;
    end;
end;
{ @end $49F654 }

{ @routine $49F838 TPSEyesGI_Advance }
procedure TPSEyesGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Particle, Current: PEyesParticle;
begin
  if (FirstParticle = nil) and (RemainingTicks >= 20) then
  begin
    EmitBurst(Classes.Point(-6, -6), 8);
    EmitBurst(Classes.Point(6, 0), 8);
    EmitBurst(Classes.Point(0, 6), 8);
    EmitBurst(Classes.Point(-6, 1), 8);
    BeamTicks := 20;
  end
  else
  begin
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      Current := Particle;
      Particle := Particle.Next;
      case Current.State of
        2:
        begin
          Current.Position := MakePointF(Current.Position.X + Current.Velocity.X, Current.Position.Y + Current.Velocity.Y);
          Current.Velocity.X := 0.95 * Current.Velocity.X;
          Current.Velocity.Y := 0.95 * Current.Velocity.Y;
          Dec(Current.Countdown);
          if Current.Countdown = 0 then
        begin
            Current.State := 3;
            Current.Countdown := 50;
        end;
        end;
        3:
        begin
          Current.Position := MakePointF(Current.Position.X + Current.Velocity.X, Current.Position.Y + Current.Velocity.Y);
          Current.Velocity.X := 0.95 * Current.Velocity.X;
          Current.Velocity.Y := 0.95 * Current.Velocity.Y;
          if Current.Alpha > 10 then Dec(Current.Alpha, 4);
          Dec(Current.Countdown);
          if Current.Countdown = 0 then begin
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
  Dec(RemainingTicks);
  Dec(BeamTicks);
  if BeamTicks = 0 then begin end;
end;
{ @end $49F838 }

{ @routine $49FA34 TPSEyesGI_IsFinished }
function TPSEyesGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $49FA34 }

{ @routine $49FA40 TPSEyesGI_SelectParticleColors }
procedure TPSEyesGI.SelectParticleColors;
var Particle, Current: PEyesParticle; X, Y: Integer;
begin
  X := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  Y := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Current := FirstParticle;
  while Current <> nil do
  begin
    Particle := Current;
    Current := Current.Next;
    case Particle.State of
    1: begin
      Particle.Color := ScreenRenderBuffer.GetPixel16Checked(Trunc(X + Particle.Origin.X), Trunc(Y + Particle.Origin.Y));
      if Particle.Color = 0 then Particle.Color := DarkColor else Particle.Color := Color;
      Particle.State := 2;
    end;
    end;
  end;
end;
{ @end $49FA40 }

{ @routine $49FAD8 TPSEyesGI_ErasePreviousFrame }
procedure TPSEyesGI.ErasePreviousFrame;
var Particle: PEyesParticle; Line: PEyesLine; Buffer: Pointer; Clip: TRect;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  if not SkipSavedPixelRestore then
  begin
    if not BGImage then
    begin
      Particle := FirstParticle;
      while Particle <> nil do
      begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), 0);
        Particle := Particle.Next;
      end;
      Line := FirstLine;
      while Line <> nil do
      begin
        ScreenRenderBuffer.DrawLine16Clipped(Line.First, Line.Last, 0, Clip);
        Line := Line.Next;
      end;
    end
    else
    begin
      Particle := FirstParticle;
      while Particle <> nil do
      begin
        if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1), Particle.SavedPixel1);
        Particle := Particle.Next;
      end;
      Line := FirstLine;
      while Line <> nil do
      begin
        OKGR_Line_CopyFromBuf_WORD(@Line.SavedPixels, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y);
        Line := Line.Next;
      end;
    end;
  end;
end;
{ @end $49FAD8 }

{ @routine $49FBF8 TPSEyesGI_PrepareFrameDraw }
procedure TPSEyesGI.PrepareFrameDraw;
var
  Particle: PEyesParticle;
  DX, DY, X, Y: Integer;
  Buffer: Pointer;
  Pitch, Progress, Distance, Step: Integer;
  P: TPoint;
  Line, Shadow: PEyesLine;
  Clip: TRect;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  X := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  Y := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    Particle.ByteOffset1 := -1;
    DX := Round(Particle.Position.X) + X;
    DY := Round(Particle.Position.Y) + Y;
    if (DX >= 0) and (DX < GameScreenWidth) and (DY >= 0) and (DY < GameScreenHeight) then
      Particle.ByteOffset1 := DX * 2 + DY * Pitch;
    Particle := Particle.Next;
  end;
  X := AbsolutePosition.X;
  Y := AbsolutePosition.Y;
  DX := TargetPoint.X - LocalPosition.X;
  DY := TargetPoint.Y - LocalPosition.Y;
  if Abs(DX) > Abs(DY) then Distance := Abs(DX) else Distance := Abs(DY);
  if Distance = 0 then Distance := 1;
  Progress := 0;
  Step := Distance div 4;
  if Step < 1 then Step := 1;
  if Step > 32 then Step := 32;
  if BeamTicks > 0 then
  begin
    P := Classes.Point(X, Y);
    while Distance - Progress > Step do
    begin
      Line := AddLine;
      Line.First := P;
      P := Classes.Point(X + (Progress + Step) * DX div Distance + RandomIntRange(-5, 5),
        Y + (Progress + Step) * DY div Distance + RandomIntRange(-5, 5));
      Line.Last := P;
      Line.Alpha := 191 * (Progress + Step) div Distance + 64;
      Line.Color := DarkColor;
      Line.PreviousFrame := False;
      Shadow := AddLine;
      if Abs(DX) > Abs(DY) then
      begin
        Shadow.First := Classes.Point(Line.First.X, Line.First.Y - 1);
        Shadow.Last := Classes.Point(Line.Last.X, Line.Last.Y - 1);
      end
      else
      begin
        Shadow.First := Classes.Point(Line.First.X - 1, Line.First.Y);
        Shadow.Last := Classes.Point(Line.Last.X - 1, Line.Last.Y);
      end;
      Shadow.Alpha := Line.Alpha;
      Shadow.Color := Color;
      Shadow.PreviousFrame := False;
      Inc(Progress, Step);
      if OKGR_Line_Clip(Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y, Clip) = 0 then RemoveLine(Line);
      if OKGR_Line_Clip(Shadow.First.X, Shadow.First.Y, Shadow.Last.X, Shadow.Last.Y, Clip) = 0 then RemoveLine(Shadow);
    end;
    Line := AddLine;
    Line.First := P;
    Line.Last := Classes.Point(X + DX, Y + DY);
    Line.Alpha := 255;
    Line.Color := Color;
    Line.PreviousFrame := False;
    Shadow := AddLine;
    if Abs(DX) > Abs(DY) then
    begin
      Shadow.First := Classes.Point(Line.First.X, Line.First.Y - 1);
      Shadow.Last := Classes.Point(Line.Last.X, Line.Last.Y - 1);
    end
    else
    begin
      Shadow.First := Classes.Point(Line.First.X - 1, Line.First.Y);
      Shadow.Last := Classes.Point(Line.Last.X - 1, Line.Last.Y);
    end;
    Shadow.Alpha := Line.Alpha;
    Shadow.Color := Color;
    Shadow.PreviousFrame := False;
    if OKGR_Line_Clip(Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y, Clip) = 0 then RemoveLine(Line);
    if OKGR_Line_Clip(Shadow.First.X, Shadow.First.Y, Shadow.Last.X, Shadow.Last.Y, Clip) = 0 then RemoveLine(Shadow);
  end;
  if BGImage then
  begin
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      if Particle.ByteOffset1 >= 0 then Particle.SavedPixel1 := ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1));
      Particle := Particle.Next;
    end;
    Line := FirstLine;
    while Line <> nil do
    begin
      if not Line.PreviousFrame then
        OKGR_Line_CopyToBuf_WORD(@Line.SavedPixels, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y);
      Line := Line.Next;
    end;
  end;
end;
{ @end $49FBF8 }

{ @routine $4A0118 TPSEyesGI_DrawUpdateRects }
procedure TPSEyesGI.DrawUpdateRects(ClipRect: TRect);
begin
  SelectParticleColors;
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4A0118 }

{ @routine $4A0154 TPSEyesGI_Draw }
procedure TPSEyesGI.Draw(ClipRect: TRect);
var Particle: PEyesParticle; Line: PEyesLine; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    if Particle.ByteOffset1 >= 0 then BlendPixel16(AddPointerOffset(Buffer, Particle.ByteOffset1), Particle.Color, Particle.Alpha);
    Particle := Particle.Next;
  end;
  Line := FirstLine;
  while Line <> nil do
  begin
    if not Line.PreviousFrame then
      ScreenRenderBuffer.DrawAlphaLine16Clipped(Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y, Line.Color, Line.Alpha, Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
    Line := Line.Next;
  end;
end;
{ @end $4A0154 }

{ @routine $4A0208 TPSEyesGI_CommitFrameDraw }
procedure TPSEyesGI.CommitFrameDraw;
var Particle: PEyesParticle; Line, CurrentLine: PEyesLine; Buffer, Presented: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Presented := ScreenPresentBuffer.Pixels;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    if Particle.PreviousByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.PreviousByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.PreviousByteOffset1)));
    if Particle.ByteOffset1 >= 0 then WriteWordEC(AddPointerOffset(Presented, Particle.ByteOffset1), ReadWordEC(AddPointerOffset(Buffer, Particle.ByteOffset1)));
    Particle.PreviousByteOffset1 := Particle.ByteOffset1;
    Particle := Particle.Next;
  end;
  Line := FirstLine;
  while Line <> nil do
  begin
    OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y);
    if Line.PreviousFrame then
    begin
      CurrentLine := Line;
      Line := Line.Next;
      RemoveLine(CurrentLine);
    end
    else
    begin
      Line.PreviousFrame := not Line.PreviousFrame;
      Line := Line.Next;
    end;
  end;
end;
{ @end $4A0208 }

end.

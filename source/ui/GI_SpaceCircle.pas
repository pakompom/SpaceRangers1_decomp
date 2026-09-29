unit GI_SpaceCircle;
// Unit bracket (inferred): CODE 0x004941A4..0x00494DFB; inclusive evidence, not full bounds.

interface

uses GI_MessageLoop, EC_Struct, EC_BlockPar, Types;

type
  TSpaceCircleSegmentGI = record // @size $24
    First: TPointF; // @offset $00
    Last: TPointF; // @offset $08
    ClipResult: Integer; // @offset $10
    PixelFirst: TPoint; // @offset $14
    PixelLast: TPoint; // @offset $1C
  end;
  PSpaceCircleSegmentGI = ^TSpaceCircleSegmentGI;
  TSpaceCircleSavedLineGI = record // @size $10
    First: TPoint; // @offset $00
    Last: TPoint; // @offset $08
  end;
  PSpaceCircleSavedLineGI = ^TSpaceCircleSavedLineGI;

  TSpaceCircleGI = class(TObjectGI) // @size $134
  public
    SegmentCount: Integer; // @offset $100
    Segments: PSpaceCircleSegmentGI; // @offset $104
    PreviousLineCount: Integer; // @offset $108
    PreviousLines: PSpaceCircleSavedLineGI; // @offset $10C
    Center: TPoint; // @offset $110
    Radius: Integer; // @offset $118
    Color: Cardinal; // @offset $11C
    GeometryDirty: Boolean; // @offset $120
    DrawnSegmentCount: Integer; // @offset $124
    DeactivateAfterFrame: Boolean; // @offset $128
    AnimationTimer: TCallbackTimerIdGI; // @offset $12C
    SavedPixels: Pointer; // @offset $130

    constructor Create(Owner: TObjectGI); // @addr $4942B8
    destructor Destroy; override; // @addr $494314
    procedure SetRadius(Value: Integer); // @addr $494360
    procedure SetCenter(Value: TPoint); // @addr $494388
    procedure RebuildSegments; // @addr $494424
    procedure ProjectAndClipSegments; // @addr $49466C
    procedure RotateSegments(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $494730
    procedure SetActive(Enabled: Boolean); override; // @addr $49488C @note "Deactivation is deferred until CommitFrameDraw."
    procedure OnActivate; override; // @addr $4948DC
    procedure OnDeactivate; override; // @addr $4948FC
    procedure ErasePreviousFrame; override; // @addr $49499C
    procedure PrepareFrameDraw; override; // @addr $494AA8
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49494C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $494978
    procedure Invalidate; override; // @addr $494998 @note "Empty in native code."
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $494BA0
    procedure Draw(ClipRect: TRect); override; // @addr $494BD8
    procedure CommitFrameDraw; override; // @addr $494C3C
    procedure ClearSegments; // @addr $4943DC
    procedure ClearPreviousLines; // @addr $494400
    procedure LoadSpaceCircleProperties(Block: TBlockParEC); // @addr $494994 @note "Empty in native code."
  end;

implementation

// @unit-initialization $494DF4
// @unit-finalization $494DC4

uses EC_OKGF, EC_Mem, GR_Main, GR_GraphBuf, Classes;

{ @routine $4942B8 TSpaceCircleGI_Create }
constructor TSpaceCircleGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  Radius := 100;
end;
{ @end $4942B8 }

{ @routine $494314 TSpaceCircleGI_Destroy }
destructor TSpaceCircleGI.Destroy;
begin
  ClearSegments;
  ClearPreviousLines;
  if SavedPixels <> nil then
  begin
    FreeEC(SavedPixels);
    SavedPixels := nil;
  end;
  inherited Destroy;
end;
{ @end $494314 }

{ @routine $494360 TSpaceCircleGI_SetRadius }
procedure TSpaceCircleGI.SetRadius(Value: Integer);
begin
  if Radius <> Value then
  begin
    Radius := Value;
    if Active then
    begin
      RebuildSegments;
      GeometryDirty := True;
    end;
  end;
end;
{ @end $494360 }

{ @routine $494388 TSpaceCircleGI_SetCenter }
procedure TSpaceCircleGI.SetCenter(Value: TPoint);
begin
  if (Center.X <> Value.X) or (Center.Y <> Value.Y) then
  begin
    Center := Value;
    if Active then
    begin
      RebuildSegments;
      GeometryDirty := True;
    end;
  end;
end;
{ @end $494388 }

{ @routine $4943DC TSpaceCircleGI_ClearSegments }
procedure TSpaceCircleGI.ClearSegments;
begin
  if Segments <> nil then
  begin
    FreeEC(Segments);
    Segments := nil;
  end;
  SegmentCount := 0;
end;
{ @end $4943DC }

{ @routine $494400 TSpaceCircleGI_ClearPreviousLines }
procedure TSpaceCircleGI.ClearPreviousLines;
begin
  if PreviousLines <> nil then
  begin
    FreeEC(PreviousLines);
    PreviousLines := nil;
  end;
  PreviousLineCount := 0;
end;
{ @end $494400 }

{ @routine $494424 TSpaceCircleGI_RebuildSegments }
procedure TSpaceCircleGI.RebuildSegments;
var Spacing, Circumference, Angle, Step, Length: Single;
    I, Count: Integer; Segment: PSpaceCircleSegmentGI; Point, Delta: TPointF;
begin
  ClearSegments;
  if Radius <= 0 then Exit;
  Spacing := 20;
  Circumference := Radius * (2 * 3.1415926);
  Count := Round(Circumference / Spacing);
  if Count < 10 then Count := 10;
  Segments := AllocEC(Count * SizeOf(TSpaceCircleSegmentGI));
  Angle := 0;
  Step := (2 * 3.1415926) / Count;
  Point := MakePointF(Sin(Angle) * Radius, Cos(Angle) * (-Radius));
  Segment := Segments;
  for I := 0 to Count - 1 do
  begin
    Segment.First := AddPointsF(Point, PointToPointF(Center));
    Angle := Angle + Step;
    Point := MakePointF(Sin(Angle) * Radius, Cos(Angle) * (-Radius));
    Segment.Last := AddPointsF(Point, PointToPointF(Center));
    Delta := SubtractPointsF(Segment.Last, Segment.First);
    Length := Sqrt(Delta.X * Delta.X + Delta.Y * Delta.Y);
    Delta.X := Delta.X / Length;
    Delta.Y := Delta.Y / Length;
    Segment.Last.X := Delta.X * Length * 0.75 + Segment.First.X;
    Segment.Last.Y := Delta.Y * Length * 0.75 + Segment.First.Y;
    Segment.First.X := Delta.X * Length * 0.25 + Segment.First.X;
    Segment.First.Y := Delta.Y * Length * 0.25 + Segment.First.Y;
    Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
  end;
  SegmentCount := Count;
end;
{ @end $494424 }

{ @routine $49466C TSpaceCircleGI_ProjectAndClipSegments }
procedure TSpaceCircleGI.ProjectAndClipSegments;
var Segment: PSpaceCircleSegmentGI; I: Integer; Clip: TRect;
begin
  Clip.TopLeft := HitTestBounds.TopLeft;
  Clip.Right := HitTestBounds.Right - 1;
  Clip.Bottom := HitTestBounds.Bottom - 1;
  Segment := Segments;
  for I := 0 to SegmentCount - 1 do
  begin
    Segment.PixelFirst := AddPoints(RoundPointF(Segment.First), AbsolutePosition);
    Segment.PixelLast := AddPoints(RoundPointF(Segment.Last), AbsolutePosition);
    Segment.ClipResult := OKGR_Line_Clip(Segment.PixelFirst.X, Segment.PixelFirst.Y,
      Segment.PixelLast.X, Segment.PixelLast.Y, Clip);
    Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
  end;
end;
{ @end $49466C }

{ @routine $494730 TSpaceCircleGI_RotateSegments }
procedure TSpaceCircleGI.RotateSegments(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Segment: PSpaceCircleSegmentGI; I: Integer; Sine, Cosine, X, Y, Angle: Single;
begin
  if Radius > 0 then
  begin
    Angle := -2 / (Radius * (2 * 3.1415926)) * 3.1415926 * 2;
    Sine := Sin(Angle);
    Cosine := Cos(Angle);
    Segment := Segments;
    for I := 0 to SegmentCount - 1 do
    begin
      X := Segment.First.X - Center.X;
      Y := Segment.First.Y - Center.Y;
      Segment.First.X := Cosine * X + Sine * Y + Center.X;
      Segment.First.Y := -Sine * X + Cosine * Y + Center.Y;
      X := Segment.Last.X - Center.X;
      Y := Segment.Last.Y - Center.Y;
      Segment.Last.X := Cosine * X + Sine * Y + Center.X;
      Segment.Last.Y := -Sine * X + Cosine * Y + Center.Y;
      Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
    end;
    GeometryDirty := True;
  end;
end;
{ @end $494730 }

{ @routine $49488C TSpaceCircleGI_SetActive }
procedure TSpaceCircleGI.SetActive(Enabled: Boolean);
begin
  if Active <> Enabled then
    if Enabled then
    begin
      inherited SetActive(Enabled);
      RebuildSegments;
      GeometryDirty := True;
    end
    else
    begin
      if AnimationTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(AnimationTimer);
        AnimationTimer := 0;
      end;
      DeactivateAfterFrame := True;
      ClearSegments;
    end;
end;
{ @end $49488C }

{ @routine $4948DC TSpaceCircleGI_OnActivate }
procedure TSpaceCircleGI.OnActivate;
begin
  inherited OnActivate;
  if Active then
  begin
    RebuildSegments;
    GeometryDirty := True;
  end;
end;
{ @end $4948DC }

{ @routine $4948FC TSpaceCircleGI_OnDeactivate }
procedure TSpaceCircleGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
  ClearSegments;
  ClearPreviousLines;
  if SavedPixels <> nil then
  begin
    FreeEC(SavedPixels);
    SavedPixels := nil;
  end;
end;
{ @end $4948FC }

{ @routine $49494C TSpaceCircleGI_LoadFromConfigPath }
procedure TSpaceCircleGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadSpaceCircleProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49494C }

{ @routine $494978 TSpaceCircleGI_LoadFromBlock }
procedure TSpaceCircleGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadSpaceCircleProperties(Block);
end;
{ @end $494978 }

{ @routine $494994 TSpaceCircleGI_LoadSpaceCircleProperties }
procedure TSpaceCircleGI.LoadSpaceCircleProperties(Block: TBlockParEC);
begin
end;
{ @end $494994 }

{ @routine $494998 TSpaceCircleGI_Invalidate }
procedure TSpaceCircleGI.Invalidate;
begin
end;
{ @end $494998 }

{ @routine $49499C TSpaceCircleGI_ErasePreviousFrame }
procedure TSpaceCircleGI.ErasePreviousFrame;
var Line: PSpaceCircleSavedLineGI; I: Integer; Buffer: Pointer; Count: Integer;
begin
  if GeometryDirty then
  begin
    ProjectAndClipSegments;
    GeometryDirty := False;
    if AnimationTimer = 0 then
      AnimationTimer := MessageLoop.ScheduleCallbackTimer(50, 50, RotateSegments);
  end;
  if not SkipSavedPixelRestore then
    if not BGImage then
    begin
      Line := PreviousLines;
      for I := 0 to PreviousLineCount - 1 do
      begin
        ScreenRenderBuffer.DrawLine16Clipped(Line.First, Line.Last, 0, HitTestBounds);
        Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
      end;
    end
    else
    begin
      if SavedPixels <> nil then
      begin
        Buffer := SavedPixels;
        Line := PreviousLines;
        for I := 0 to PreviousLineCount - 1 do
        begin
          Count := OKGR_Line_CopyFromBuf_WORD(Buffer, ScreenRenderBuffer.Pixels,
            ScreenRenderBuffer.PitchBytes, Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y);
          Buffer := AddPointerOffset(Buffer, Count * 2);
          Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
        end;
      end;
    end;
end;
{ @end $49499C }

{ @routine $494AA8 TSpaceCircleGI_PrepareFrameDraw }
procedure TSpaceCircleGI.PrepareFrameDraw;
var Segment: PSpaceCircleSegmentGI; Copied: Integer; Count, Capacity, I: Integer;
begin
  if BGImage and (not DeactivateAfterFrame) then
    begin
      Count := 0;
      Capacity := 100;
      SavedPixels := ReAllocREC(SavedPixels, Capacity * 2);
      Segment := Segments;
      for I := 0 to SegmentCount - 1 do
      begin
        if Segment.ClipResult > 0 then
        begin
          Copied := OKGR_Line_CopyToBuf_WORD(AddPointerOffset(SavedPixels, Count * 2),
            ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
            Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.PixelLast.X, Segment.PixelLast.Y);
          Inc(Count, Copied);
          if Count + 30 > Capacity then
          begin
            Capacity := Count + 100;
            SavedPixels := ReAllocREC(SavedPixels, Capacity * 2);
          end;
        end;
        Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
      end;
    end
    else
    begin
      if SavedPixels <> nil then
      begin
        FreeEC(SavedPixels);
        SavedPixels := nil;
      end;
    end;
end;
{ @end $494AA8 }

{ @routine $494BA0 TSpaceCircleGI_DrawUpdateRects }
procedure TSpaceCircleGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $494BA0 }

{ @routine $494BD8 TSpaceCircleGI_Draw }
procedure TSpaceCircleGI.Draw(ClipRect: TRect);
var Segment: PSpaceCircleSegmentGI; I: Integer;
begin
  DrawnSegmentCount := 0;
  if not DeactivateAfterFrame then
  begin
    Segment := Segments;
    begin
      for I := 0 to SegmentCount - 1 do
      begin
        if Segment.ClipResult > 0 then
        begin
          ScreenRenderBuffer.DrawLine16(Segment.PixelFirst, Segment.PixelLast, Color);
          Inc(DrawnSegmentCount);
        end;
        Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
      end;
    end;
  end;
end;
{ @end $494BD8 }

{ @routine $494C3C TSpaceCircleGI_CommitFrameDraw }
procedure TSpaceCircleGI.CommitFrameDraw;
var Line: PSpaceCircleSavedLineGI; Segment: PSpaceCircleSegmentGI; I: Integer;
begin
  if not SkipSavedPixelRestore then
  begin
    Line := PreviousLines;
    for I := 0 to PreviousLineCount - 1 do
    begin
      OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Line.First.X, Line.First.Y, Line.Last.X, Line.Last.Y);
      Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
    end;
  end;
  if not DeactivateAfterFrame then
  begin
    PreviousLineCount := DrawnSegmentCount;
    PreviousLines := ReAllocREC(PreviousLines, PreviousLineCount * SizeOf(TSpaceCircleSavedLineGI));
    Line := PreviousLines;
    Segment := Segments;
    for I := 0 to SegmentCount - 1 do
    begin
      if Segment.ClipResult > 0 then
      begin
        if not SkipSavedPixelRestore then
          OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.PixelLast.X, Segment.PixelLast.Y);
        Line.First := Segment.PixelFirst;
        Line.Last := Segment.PixelLast;
        Line := AddPointerOffset(Line, SizeOf(TSpaceCircleSavedLineGI));
      end;
      Segment := AddPointerOffset(Segment, SizeOf(TSpaceCircleSegmentGI));
    end;
  end
  else
  begin
    PreviousLineCount := 0;
    PreviousLines := ReAllocREC(PreviousLines, PreviousLineCount * SizeOf(TSpaceCircleSavedLineGI));
  end;
  if DeactivateAfterFrame then
  begin
    inherited SetActive(False);
    DeactivateAfterFrame := False;
  end;
end;
{ @end $494C3C }

end.

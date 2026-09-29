unit GI_Tail;
// Unit bracket (inferred): CODE 0x004CC430..0x004CD017; inclusive evidence, not full bounds.
// Native GI_Tail metadata starts at $4D604C; methods end at $4D73E4.
// TTailGI belongs to GI_Tail through its dynamic-array RTTI.

interface

uses EC_BlockPar, EC_CacheGAI, EC_Struct, GI_MessageLoop, Types;

type
  TTailSegmentGI = record // @size $20
    Active: Boolean; // @offset $00
    FrameIndex: Integer; // @offset $04
    Position: TPointF; // @offset $08
    Velocity: TPointF; // @offset $10
    PixelPosition: TPoint; // @offset $18
  end;
  PTailSegmentGI = ^TTailSegmentGI;

  TTailGI = class(TObjectGI) // @size $140
  public
    ImageCache: TCGaiControlEC; // @offset $100
    FrameCount: Integer; // @offset $104
    SegmentCapacity: Integer; // @offset $108
    Segments: array of TTailSegmentGI; // @offset $10C
    ImageSize: TPoint; // @offset $110
    LastSegmentIndex: Integer; // @offset $118
    EmitterPosition: TPointF; // @offset $11C
    SegmentVelocity: TPointF; // @offset $124
    FrameTimer: TCallbackTimerIdGI; // @offset $12C
    MoveTimer: TCallbackTimerIdGI; // @offset $130
    EmitTimer: TCallbackTimerIdGI; // @offset $134
    EmitIntervalMs: Integer; // @offset $138
    Emitting: Boolean; // @offset $13C
    // Segments is a Delphi dynamic array, with inactive slots included in SegmentCapacity.
    // SegmentVelocity is displacement per 20 ms movement callback.

    constructor Create(Owner: TObjectGI); // @addr $4CC56C
    destructor Destroy; override; // @addr $4CC5E8
    procedure ClearSegments; // @addr $4CC67C @note "Preserves timers and emission state."
    procedure SetImagePath(const ImagePath: WideString); // @addr $4CC6A4 @note "Requires at least one GAI sequence. Existing segments are kept."
    function AllocateSegment: PTailSegmentGI; // @addr $4CC804 @note "Reuses the last inactive slot or grows by 16. Growth can invalidate earlier pointers; only Active is initialized."
    procedure MoveSegments(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4CC8E0
    procedure EmitSegment(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4CC93C @note "Suppresses emission within squared distance 0.001 of the last live segment."
    procedure OffsetSegments(Delta: TPointF); // @addr $4CC9F8
    procedure SetActive(Enabled: Boolean); override; // @addr $4CCA60 @note "Deactivation cancels timers. Drawing restarts them when Emitting is true."
    procedure SetEmitting(Enabled: Boolean); // @addr $4CCACC @note "Disabling emission leaves existing segments animating."
    procedure Invalidate; override; // @addr $4CCBC4
    procedure Draw(ClipRect: TRect); override; // @addr $4CCC94
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4CCE2C @note "Ignores ClipRect; uses the message loop's update rectangles."
    procedure AdvanceSegmentFrames(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4CC890
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4CCC44
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4CCC70
    procedure LoadTailProperties(Block: TBlockParEC); // @addr $4CCC8C @note "Empty in the native binary."
    procedure UpdateAutoGeometry; override; // @addr $4CCC90 @note "Empty; does not call inherited UpdateAutoGeometry."
  end;

implementation

// @unit-initialization $4CD010
// @unit-finalization $4CCFE0

uses Math, aMyFunction, GR_Main, EC_Cache, GR_Gi, GR_Rect;

{ @routine $4CC56C TTailGI_Create }
constructor TTailGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  EmitIntervalMs := 20;
  Emitting := True;
  LastSegmentIndex := -1;
end;
{ @end $4CC56C }

{ @routine $4CC5E8 TTailGI_Destroy }
destructor TTailGI.Destroy;
begin
  if FrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := 0;
  end;
  if MoveTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(MoveTimer);
    MoveTimer := 0;
  end;
  if EmitTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(EmitTimer);
    EmitTimer := 0;
  end;
  ClearSegments;
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $4CC5E8 }

{ @routine $4CC67C TTailGI_ClearSegments }
procedure TTailGI.ClearSegments;
begin
  LastSegmentIndex := -1;
  SegmentCapacity := 0;
  Segments := nil;
end;
{ @end $4CC67C }

{ @routine $4CC6A4 TTailGI_SetImagePath }
procedure TTailGI.SetImagePath(const ImagePath: WideString);
var Data: TCGaiEC;
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
    Data := nil;
    try
      Data := AcquireCachedGai(ImageCache);
      if Data.GetSequenceCount < 1 then
        RaiseWideMessage('TTailGI.SetImage.AnimCount Path=' + ImagePath);
      FrameCount := Data.GetSequenceFrameCount(0);
      ImageSize := Data.GetCanvasSize;
    finally
      if Data <> nil then ImageCache.Release;
    end;
  end;
end;
{ @end $4CC6A4 }

{ @routine $4CC804 TTailGI_AllocateSegment }
function TTailGI.AllocateSegment: PTailSegmentGI;
var I: Integer;
begin
  Result := nil;
  for I := 0 to SegmentCapacity - 1 do
    if not Segments[I].Active then
    begin
      Result := @Segments[I];
      LastSegmentIndex := I;
    end;
  if Result = nil then
  begin
    SetLength(Segments, SegmentCapacity + 16);
    Result := @Segments[SegmentCapacity];
    LastSegmentIndex := SegmentCapacity;
    Inc(SegmentCapacity, 16);
  end;
  Result.Active := True;
end;
{ @end $4CC804 }

{ @routine $4CC890 TTailGI_AdvanceSegmentFrames }
procedure TTailGI.AdvanceSegmentFrames(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Segment: PTailSegmentGI;
  I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if not Segment.Active then Continue;
    Inc(Segment.FrameIndex);
    if Segment.FrameIndex >= FrameCount then
    begin
      Segment.Active := False;
      if I = LastSegmentIndex then LastSegmentIndex := -1;
    end;
  end;
end;
{ @end $4CC890 }

{ @routine $4CC8E0 TTailGI_MoveSegments }
procedure TTailGI.MoveSegments(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Segment: PTailSegmentGI; I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Segment.Position.X := Segment.Position.X + Segment.Velocity.X;
      Segment.Position.Y := Segment.Position.Y + Segment.Velocity.Y;
      Segment.PixelPosition.X := Round(Segment.Position.X);
      Segment.PixelPosition.Y := Round(Segment.Position.Y);
    end;
  end;
end;
{ @end $4CC8E0 }

{ @routine $4CC93C TTailGI_EmitSegment }
procedure TTailGI.EmitSegment(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Segment: PTailSegmentGI; Position: TPointF;
begin
  Position.X := SegmentVelocity.X * 1.0 + EmitterPosition.X;
  Position.Y := SegmentVelocity.Y * 1.0 + EmitterPosition.Y;
  if LastSegmentIndex >= 0 then
    if PointDistanceSquared(Position, Segments[LastSegmentIndex].Position) < 0.001 then Exit;
  Segment := AllocateSegment;
  Segment.FrameIndex := 0;
  Segment.Position := Position;
  Segment.Velocity := SegmentVelocity;
  Segment.PixelPosition.X := Round(Segment.Position.X);
  Segment.PixelPosition.Y := Round(Segment.Position.Y);
end;
{ @end $4CC93C }

{ @routine $4CC9F8 TTailGI_OffsetSegments }
procedure TTailGI.OffsetSegments(Delta: TPointF);
var Segment: PTailSegmentGI; I: Integer;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Segment.Position.X := Segment.Position.X + Delta.X;
      Segment.Position.Y := Segment.Position.Y + Delta.Y;
      Segment.PixelPosition.X := Round(Segment.Position.X);
      Segment.PixelPosition.Y := Round(Segment.Position.Y);
    end;
  end;
end;
{ @end $4CC9F8 }

{ @routine $4CCA60 TTailGI_SetActive }
procedure TTailGI.SetActive(Enabled: Boolean);
begin
  if Active <> Enabled then
  begin
    inherited SetActive(Enabled);
    if not Active then
    begin
      if FrameTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(FrameTimer);
        FrameTimer := 0;
      end;
      if MoveTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(MoveTimer);
        MoveTimer := 0;
      end;
      if EmitTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := 0;
      end;
    end;
  end;
end;
{ @end $4CCA60 }

{ @routine $4CCACC TTailGI_SetEmitting }
procedure TTailGI.SetEmitting(Enabled: Boolean);
begin
  if Emitting <> Enabled then
  begin
    Emitting := Enabled;
    if not Emitting then
    begin
      if EmitTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := 0;
      end;
    end
    else
    begin
      if FrameTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(FrameTimer);
        FrameTimer := 0;
      end;
      if MoveTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(MoveTimer);
        MoveTimer := 0;
      end;
      if EmitTimer <> 0 then
      begin
        MessageLoop.CancelCallbackTimer(EmitTimer);
        EmitTimer := 0;
      end;
      FrameTimer := MessageLoop.ScheduleCallbackTimer(20, 20, AdvanceSegmentFrames);
      MoveTimer := MessageLoop.ScheduleCallbackTimer(20, 20, MoveSegments);
      EmitTimer := MessageLoop.ScheduleCallbackTimer(EmitIntervalMs, EmitIntervalMs, EmitSegment);
    end;
  end;
end;
{ @end $4CCACC }

{ @routine $4CCBC4 TTailGI_Invalidate }
procedure TTailGI.Invalidate;
var Segment: PTailSegmentGI; I: Integer; Bounds: TRect;
begin
  for I := 0 to SegmentCapacity - 1 do
  begin
    Segment := @Segments[I];
    if Segment.Active then
    begin
      Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
      Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
      Bounds.Right := Bounds.Left + ImageSize.X;
      Bounds.Bottom := Bounds.Top + ImageSize.Y;
      MessageLoop.QueueUpdateRect(Bounds);
    end;
  end;
end;
{ @end $4CCBC4 }

{ @routine $4CCC44 TTailGI_LoadFromConfigPath }
procedure TTailGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadTailProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4CCC44 }

{ @routine $4CCC70 TTailGI_LoadFromBlock }
procedure TTailGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadTailProperties(Block);
end;
{ @end $4CCC70 }

{ @routine $4CCC8C TTailGI_LoadTailProperties }
procedure TTailGI.LoadTailProperties(Block: TBlockParEC);
begin
end;
{ @end $4CCC8C }

{ @routine $4CCC90 TTailGI_UpdateAutoGeometry }
procedure TTailGI.UpdateAutoGeometry;
begin
end;
{ @end $4CCC90 }

{ @routine $4CCC94 TTailGI_Draw }
procedure TTailGI.Draw(ClipRect: TRect);
var
  Data: TCGaiEC;
  Segment: PTailSegmentGI;
  I: Integer;
  Gi: TgiGR;
  Origin: TPoint;
  Bounds, Intersection: TRect;
begin
  if Emitting then
    if FrameTimer = 0 then
    begin
      Emitting := False;
      SetEmitting(True);
    end;
  Data := nil;
  try
    Data := AcquireCachedGai(ImageCache);
    for I := 0 to SegmentCapacity - 1 do
    begin
      Segment := @Segments[I];
      if Segment.Active then
      begin
        Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
        Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
        Bounds.Right := ImageSize.X + Bounds.Left;
        Bounds.Bottom := ImageSize.Y + Bounds.Top;
        if IntersectRects(Intersection, Bounds, ClipRect) then
        begin
          begin
            Gi := Data.LoadFrameGi(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
            Gi.DrawToGraphBuf(ScreenRenderBuffer, Gi.GetBoundsRect.Left + Bounds.Left - Data.GetBoundsRect.Left,
              Gi.GetBoundsRect.Top + Bounds.Top - Data.GetBoundsRect.Top, ClipRect, 0);
          end;
        end;
      end;
    end;
  finally
    if Data <> nil then ImageCache.Release;
  end;
end;
{ @end $4CCC94 }

{ @routine $4CCE2C TTailGI_DrawUpdateRects }
procedure TTailGI.DrawUpdateRects(ClipRect: TRect);
var
  Data: TCGaiEC;
  Segment: PTailSegmentGI;
  I: Integer;
  Gi: TgiGR;
  RectNode: TRectGR;
  Origin: TPoint;
  Bounds, Intersection: TRect;
begin
  if Emitting then
    if FrameTimer = 0 then
    begin
      Emitting := False;
      SetEmitting(True);
    end;
  Data := nil;
  try
    Data := AcquireCachedGai(ImageCache);
    for I := 0 to SegmentCapacity - 1 do
    begin
      Segment := @Segments[I];
      if Segment.Active then
      begin
        Bounds.Left := AbsolutePosition.X + Segment.PixelPosition.X - (ImageSize.X shr 1);
        Bounds.Top := AbsolutePosition.Y + Segment.PixelPosition.Y - (ImageSize.Y shr 1);
        Bounds.Right := ImageSize.X + Bounds.Left;
        Bounds.Bottom := ImageSize.Y + Bounds.Top;
        RectNode := MessageLoop.UpdateRects.FirstRect;
        while RectNode <> nil do
        begin
          if IntersectRects(Intersection, RectNode.Bounds, Bounds) then
          begin
            begin
              Gi := Data.LoadFrameGi(Data.GetSequenceFrameIndex(0, Segment.FrameIndex));
              Gi.DrawToGraphBuf(ScreenRenderBuffer, Gi.GetBoundsRect.Left + Bounds.Left - Data.GetBoundsRect.Left,
                Gi.GetBoundsRect.Top + Bounds.Top - Data.GetBoundsRect.Top, Intersection, 0);
            end;
          end;
          RectNode := RectNode.Next;
        end;
      end;
    end;
  finally
    if Data <> nil then ImageCache.Release;
  end;
end;
{ @end $4CCE2C }

end.

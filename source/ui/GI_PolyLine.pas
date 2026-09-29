unit GI_PolyLine;
// Unit bracket (inferred): CODE 0x004A4BFC..0x004A5C2F; inclusive evidence, not full bounds.

interface

uses GI_MessageLoop, GI_Circle, EC_BlockPar, Types, Windows;

type
  PPolyLineSegmentGI = ^TPolyLineSegmentGI;
  TPolyLineSegmentGI = packed record // @size $6C
    Next: PPolyLineSegmentGI; // @offset $00
    Prev: PPolyLineSegmentGI; // @offset $04
    First: TPoint; // @offset $08
    Last: TPoint; // @offset $10
    UserData: Integer; // @offset $18
    Animated: Boolean; // @offset $1C
    PixelCount: Integer; // @offset $20
    PixelCapacity: Integer; // @offset $24
    PixelFirst: TPoint; // @offset $28
    PixelLast: TPoint; // @offset $30
    SavedPixels: Pointer; // @offset $38
    Visible: Boolean; // @offset $3C
    PreviousFirst: TPoint; // @offset $3D
    PreviousLast: TPoint; // @offset $45
    PreviousPixels: Pointer; // @offset $50
    PreviouslyVisible: Boolean; // @offset $54
    ClippedColor: Cardinal; // @offset $58
    ClippedEndColor: Cardinal; // @offset $5C
    Color: Cardinal; // @offset $60
    EndColor: Cardinal; // @offset $64
    Kind: Integer; // @offset $68 0 animated RGB565, 1 alpha, 2 gradient.
  end;

  TPolyLineGI = class(TObjectGI) // @size $120
  public
    FirstSegment: PPolyLineSegmentGI; // @offset $100
    LastSegment: PPolyLineSegmentGI; // @offset $104
    AnimationPhase: Cardinal; // @offset $108
    AnimationTimer: TCallbackTimerIdGI; // @offset $10C
    FrameDrawing: Boolean; // @offset $110
    ShadowCircle: TCircleGI; // @offset $114 Borrowed light-mask control.
    AutoRebuildBounds: Boolean; // @offset $118
    NormalizeBounds: Boolean; // @offset $119
    SegmentHeap: Cardinal; // @offset $11C

    constructor Create(Owner: TObjectGI); // @addr $4A4D14
    destructor Destroy; override; // @addr $4A4DF8
    procedure Clear; override; // @addr $4A4E4C
    function AllocateSegment: PPolyLineSegmentGI; // @addr $4A4E8C
    procedure ClearSegments; // @addr $4A4EE8
    procedure RemoveSegment(Segment: PPolyLineSegmentGI); // @addr $4A4F04
    procedure AllocatePixelBuffers(Segment: PPolyLineSegmentGI); // @addr $4A4F88
    procedure RebuildBounds; // @addr $4A5018
    function AddParentLine(First, Last: TPoint; Color: Cardinal; UserData: Integer): PPolyLineSegmentGI; // @addr $4A5184
    function AddLine(First, Last: TPoint; Color: Cardinal): PPolyLineSegmentGI; // @addr $4A5224
    function AddLocalLine(First, Last: TPoint; Color: Cardinal; UserData: Integer): PPolyLineSegmentGI; // @addr $4A5254
    procedure UpdateSegmentLength(Segment: PPolyLineSegmentGI); // @addr $4A52CC
    procedure RetireSegment(Segment: PPolyLineSegmentGI); // @addr $4A5328
    procedure StartAnimation; // @addr $4A5378
    procedure StopAnimation; // @addr $4A53BC
    procedure Invalidate; override; // @addr $4A5408
    procedure PrepareFrameDraw; override; // @addr $4A54B4
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $4A561C
    procedure Draw(ClipRect: TRect); override; // @addr $4A5674
    procedure DrawSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect); virtual; // @addr $4A56F8 @slot $B8
    procedure DrawFrameSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect); virtual; // @addr $4A57A0 @slot $BC
    procedure AdvanceAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4A53E0
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A4FCC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A4FF8
    procedure LoadPolyLineProperties(Block: TBlockParEC); // @addr $4A5014 @note "Empty in native code."
    procedure CommitFrameDraw; override; // @addr $4A5AF0
    procedure ErasePreviousFrame; override; // @addr $4A5448
  end;

implementation

// @unit-initialization $4A5C28
// @unit-finalization $4A5BF8

uses EC_OKGF, EC_Mem, EC_Struct, GR_Main, GR_GraphBuf, GR_Rect,
  Classes, SysUtils, aMyFunction;

{ @routine $4A4D14 TPolyLineGI_Create }
constructor TPolyLineGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  SegmentHeap := HeapCreate(1, $8000, 0);
  if SegmentHeap = 0 then raise Exception.Create('TPolyLineGI.HeapCreate');
  ClientSize := Classes.Point(1, 1);
  AnimationTimer := 0;
  AnimationPhase := 0;
  FrameDrawing := False;
  ShadowCircle := nil;
  AutoRebuildBounds := True;
  NormalizeBounds := True;
  StartAnimation;
end;
{ @end $4A4D14 }

{ @routine $4A4DF8 TPolyLineGI_Destroy }
destructor TPolyLineGI.Destroy;
begin
  ShadowCircle := nil;
  StopAnimation;
  Clear;
  if SegmentHeap <> 0 then
  begin
    HeapDestroy(SegmentHeap);
    SegmentHeap := 0;
  end;
  inherited Destroy;
end;
{ @end $4A4DF8 }

{ @routine $4A4E4C TPolyLineGI_Clear }
procedure TPolyLineGI.Clear;
begin
  ShadowCircle := nil;
  ClientSize := Classes.Point(1, 1);
  ClearSegments;
  inherited Clear;
end;
{ @end $4A4E4C }

{ @routine $4A4E8C TPolyLineGI_AllocateSegment }
function TPolyLineGI.AllocateSegment: PPolyLineSegmentGI;
var Segment: PPolyLineSegmentGI;
begin
  Segment := AllocFromHeapEC(SegmentHeap, SizeOf(TPolyLineSegmentGI));
  Segment.Next := nil;
  Segment.Prev := LastSegment;
  Segment.SavedPixels := nil;
  Segment.PreviousPixels := nil;
  Segment.Visible := False;
  Segment.PreviouslyVisible := False;
  if LastSegment <> nil then LastSegment.Next := Segment;
  if FirstSegment = nil then FirstSegment := Segment;
  LastSegment := Segment;
  Segment.Kind := 0;
  Result := Segment;
end;
{ @end $4A4E8C }

{ @routine $4A4EE8 TPolyLineGI_ClearSegments }
procedure TPolyLineGI.ClearSegments;
begin
  while FirstSegment <> nil do RemoveSegment(FirstSegment);
end;
{ @end $4A4EE8 }

{ @routine $4A4F04 TPolyLineGI_RemoveSegment }
procedure TPolyLineGI.RemoveSegment(Segment: PPolyLineSegmentGI);
begin
  if Segment.Next <> nil then Segment.Next.Prev := Segment.Prev;
  if Segment.Prev <> nil then Segment.Prev.Next := Segment.Next;
  if LastSegment = Segment then LastSegment := Segment.Prev;
  if FirstSegment = Segment then FirstSegment := Segment.Next;
  if SegmentHeap <> 0 then
  begin
    if Segment.SavedPixels <> nil then
    begin
      FreeFromHeapEC(SegmentHeap, Segment.SavedPixels);
      Segment.SavedPixels := nil;
    end;
    if Segment.PreviousPixels <> nil then
    begin
      FreeFromHeapEC(SegmentHeap, Segment.PreviousPixels);
      Segment.PreviousPixels := nil;
    end;
    FreeFromHeapEC(SegmentHeap, Segment);
  end;
end;
{ @end $4A4F04 }

{ @routine $4A4F88 TPolyLineGI_AllocatePixelBuffers }
procedure TPolyLineGI.AllocatePixelBuffers(Segment: PPolyLineSegmentGI);
begin
  if Segment.SavedPixels = nil then Segment.SavedPixels := AllocFromHeapEC(SegmentHeap, Segment.PixelCount * 2 + 10);
  if Segment.PreviousPixels = nil then Segment.PreviousPixels := AllocFromHeapEC(SegmentHeap, Segment.PixelCount * 2 + 10);
end;
{ @end $4A4F88 }

{ @routine $4A4FCC TPolyLineGI_LoadFromConfigPath }
procedure TPolyLineGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadPolyLineProperties(Block);
end;
{ @end $4A4FCC }

{ @routine $4A4FF8 TPolyLineGI_LoadFromBlock }
procedure TPolyLineGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadPolyLineProperties(Block);
end;
{ @end $4A4FF8 }

{ @routine $4A5014 TPolyLineGI_LoadPolyLineProperties }
procedure TPolyLineGI.LoadPolyLineProperties(Block: TBlockParEC);
begin

end;
{ @end $4A5014 }

{ @routine $4A5018 TPolyLineGI_RebuildBounds }
procedure TPolyLineGI.RebuildBounds;
var Segment: PPolyLineSegmentGI; Minimum, Size: TPoint;
begin
  if NormalizeBounds then
  begin
    Segment := FirstSegment;
    if Segment = nil then SetSize(Classes.Point(1, 1))
    else
    begin
      Minimum := Segment.First;
      while Segment <> nil do
      begin
        if Minimum.X > Segment.First.X then Minimum.X := Segment.First.X;
        if Minimum.Y > Segment.First.Y then Minimum.Y := Segment.First.Y;
        if Minimum.X > Segment.Last.X then Minimum.X := Segment.Last.X;
        if Minimum.Y > Segment.Last.Y then Minimum.Y := Segment.Last.Y;
        Segment := Segment.Next;
      end;
      SetPosition(Classes.Point(LocalPosition.X + Minimum.X, LocalPosition.Y + Minimum.Y));
      Size := Classes.Point(1, 1);
      Segment := FirstSegment;
      while Segment <> nil do
      begin
        Segment.First := Classes.Point(Segment.First.X - Minimum.X, Segment.First.Y - Minimum.Y);
        Segment.Last := Classes.Point(Segment.Last.X - Minimum.X, Segment.Last.Y - Minimum.Y);
        if Size.X <= Segment.First.X then Size.X := Segment.First.X + 1;
        if Size.Y <= Segment.First.Y then Size.Y := Segment.First.Y + 1;
        if Size.X <= Segment.Last.X then Size.X := Segment.Last.X + 1;
        if Size.Y <= Segment.Last.Y then Size.Y := Segment.Last.Y + 1;
        Segment := Segment.Next;
      end;
      SetSize(Size);
    end;
  end;
end;
{ @end $4A5018 }

{ @routine $4A5184 TPolyLineGI_AddParentLine }
function TPolyLineGI.AddParentLine(First, Last: TPoint; Color: Cardinal; UserData: Integer): PPolyLineSegmentGI;
var Segment: PPolyLineSegmentGI;
begin
  Segment := AllocateSegment;
  Segment.First := Classes.Point(First.X - LocalPosition.X, First.Y - LocalPosition.Y);
  Segment.Last := Classes.Point(Last.X - LocalPosition.X, Last.Y - LocalPosition.Y);
  Segment.Color := Color;
  Segment.PixelCount := IntegerPointDistancePlusOne(First, Last);
  Segment.PixelCapacity := Segment.PixelCount;
  Segment.UserData := UserData;
  Segment.Animated := True;
  if AutoRebuildBounds then RebuildBounds;
  Result := Segment;
end;
{ @end $4A5184 }

{ @routine $4A5224 TPolyLineGI_AddLine }
function TPolyLineGI.AddLine(First, Last: TPoint; Color: Cardinal): PPolyLineSegmentGI;
begin
  Result := AddLocalLine(First, Last, Color, 0);
end;
{ @end $4A5224 }

{ @routine $4A5254 TPolyLineGI_AddLocalLine }
function TPolyLineGI.AddLocalLine(First, Last: TPoint; Color: Cardinal; UserData: Integer): PPolyLineSegmentGI;
var Segment: PPolyLineSegmentGI;
begin
  Segment := AllocateSegment;
  Segment.First := First;
  Segment.Last := Last;
  Segment.Color := Color;
  Segment.PixelCount := IntegerPointDistancePlusOne(First, Last);
  Segment.PixelCapacity := Segment.PixelCount;
  Segment.UserData := UserData;
  Segment.Animated := True;
  if AutoRebuildBounds then RebuildBounds;
  Result := Segment;
end;
{ @end $4A5254 }

{ @routine $4A52CC TPolyLineGI_UpdateSegmentLength }
procedure TPolyLineGI.UpdateSegmentLength(Segment: PPolyLineSegmentGI);
var Count: Integer;
begin
  Count := IntegerPointDistancePlusOne(Segment.First, Segment.Last);
  if Count > Segment.PixelCapacity then
  begin
    Segment.PixelCount := Count;
    Segment.PixelCapacity := Segment.PixelCount;
    Segment.SavedPixels := ReAllocFromHeapREC(SegmentHeap, Segment.SavedPixels, Segment.PixelCount * 2 + 10);
    Segment.PreviousPixels := ReAllocFromHeapREC(SegmentHeap, Segment.PreviousPixels, Segment.PixelCount * 2 + 10);
  end
  else Segment.PixelCount := Count;
end;
{ @end $4A52CC }

{ @routine $4A5328 TPolyLineGI_RetireSegment }
procedure TPolyLineGI.RetireSegment(Segment: PPolyLineSegmentGI);
var Buffer: Pointer;
begin
  if Segment.PreviouslyVisible and (Segment.PreviousPixels <> nil) then
  begin
    Buffer := AllocEC(Segment.PixelCount * 2 + 10);
    CopyMemory(Buffer, Segment.PreviousPixels, Segment.PixelCount * 2 + 10);
    MessageLoop.AddSavedLine(Segment.PreviousFirst, Segment.PreviousLast, Buffer);
  end;
  RemoveSegment(Segment);
end;
{ @end $4A5328 }

{ @routine $4A5378 TPolyLineGI_StartAnimation }
procedure TPolyLineGI.StartAnimation;
begin
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
  AnimationTimer := MessageLoop.ScheduleCallbackTimer(100, 100, AdvanceAnimation);
end;
{ @end $4A5378 }

{ @routine $4A53BC TPolyLineGI_StopAnimation }
procedure TPolyLineGI.StopAnimation;
begin
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
end;
{ @end $4A53BC }

{ @routine $4A53E0 TPolyLineGI_AdvanceAnimation }
procedure TPolyLineGI.AdvanceAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(AnimationPhase, 30);
  if AnimationPhase >= 360 then Dec(AnimationPhase, 360);
  Invalidate;
end;
{ @end $4A53E0 }

{ @routine $4A5408 TPolyLineGI_Invalidate }
procedure TPolyLineGI.Invalidate;
begin
  if not FrameDrawing then
  begin
    inherited Invalidate;
    Exit;
  end;
  if ShadowCircle = nil then
  begin
    MessageLoop.UpdateRects.Clear;
    MessageLoop.UpdateRectsEnabled := True;
    MessageLoop.InvalidateViewport;
    MessageLoop.UpdateRectsEnabled := False;
  end;
end;
{ @end $4A5408 }

{ @routine $4A5448 TPolyLineGI_ErasePreviousFrame }
procedure TPolyLineGI.ErasePreviousFrame;
var Segment: PPolyLineSegmentGI;
begin
  FrameDrawing := True;
  if not SkipSavedPixelRestore then
  begin
    Segment := FirstSegment;
    while Segment <> nil do
    begin
      AllocatePixelBuffers(Segment);
      if Segment.PreviouslyVisible then
        OKGR_Line_CopyFromBuf_WORD(Segment.PreviousPixels, ScreenRenderBuffer.Pixels,
          ScreenRenderBuffer.PitchBytes, Segment.PreviousFirst.X, Segment.PreviousFirst.Y,
          Segment.PreviousLast.X, Segment.PreviousLast.Y);
      Segment := Segment.Next;
    end;
  end;
end;
{ @end $4A5448 }

{ @routine $4A54B4 TPolyLineGI_PrepareFrameDraw }
procedure TPolyLineGI.PrepareFrameDraw;
var Segment: PPolyLineSegmentGI; Clip: TRect;
begin
  FrameDrawing := True;
  if ShadowCircle <> nil then Clip := ShadowCircle.HitTestBounds
  else Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    AllocatePixelBuffers(Segment);
    Segment.PixelFirst := Classes.Point(Segment.First.X + AbsolutePosition.X, Segment.First.Y + AbsolutePosition.Y);
    Segment.PixelLast := Classes.Point(Segment.Last.X + AbsolutePosition.X, Segment.Last.Y + AbsolutePosition.Y);
    if Segment.Kind <> 2 then
    begin
      if OKGR_Line_Clip(Segment.PixelFirst.X, Segment.PixelFirst.Y,
        Segment.PixelLast.X, Segment.PixelLast.Y, Clip) = 0 then Segment.Visible := False
      else Segment.Visible := True;
    end
    else
    begin
      Segment.ClippedColor := Segment.Color;
      Segment.ClippedEndColor := Segment.EndColor;
      if OKGR_LineColor_Clip(Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.ClippedColor,
        Segment.PixelLast.X, Segment.PixelLast.Y, Segment.ClippedEndColor, Clip) = 0 then
        Segment.Visible := False
      else Segment.Visible := True;
    end;
    Segment := Segment.Next;
  end;
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    if Segment.Visible then
      OKGR_Line_CopyToBuf_WORD(Segment.SavedPixels, ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes, Segment.PixelFirst.X, Segment.PixelFirst.Y,
        Segment.PixelLast.X, Segment.PixelLast.Y);
    Segment := Segment.Next;
  end;
end;
{ @end $4A54B4 }

{ @routine $4A561C TPolyLineGI_DrawUpdateRects }
procedure TPolyLineGI.DrawUpdateRects(ClipRect: TRect);
var Segment: PPolyLineSegmentGI; Clip: TRect;
begin
  FrameDrawing := True;
  Clip := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    if Segment.Visible then DrawFrameSegment(Segment, Clip);
    Segment := Segment.Next;
  end;
end;
{ @end $4A561C }

{ @routine $4A5674 TPolyLineGI_Draw }
procedure TPolyLineGI.Draw(ClipRect: TRect);
var Segment: PPolyLineSegmentGI;
begin
  FrameDrawing := False;
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    Segment.PixelFirst := Classes.Point(Segment.First.X + AbsolutePosition.X, Segment.First.Y + AbsolutePosition.Y);
    Segment.PixelLast := Classes.Point(Segment.Last.X + AbsolutePosition.X, Segment.Last.Y + AbsolutePosition.Y);
    DrawSegment(Segment, ClipRect);
    Segment := Segment.Next;
  end;
end;
{ @end $4A5674 }

{ @routine $4A56F8 TPolyLineGI_DrawSegment }
procedure TPolyLineGI.DrawSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect);
begin
    begin
      if Segment.Animated then ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, AnimationPhase, ClipRect)
      else ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, 0, ClipRect);
    end;
end;
{ @end $4A56F8 }

{ @routine $4A57A0 TPolyLineGI_DrawFrameSegment }
procedure TPolyLineGI.DrawFrameSegment(Segment: PPolyLineSegmentGI; ClipRect: TRect);
var X, Y: Integer;
begin
  X := 0;
  Y := 0;
  if ShadowCircle = nil then
  begin
    if Segment.Kind = 0 then
    begin
    begin
      if Segment.Animated then ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, AnimationPhase, ClipRect)
      else ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, 0, ClipRect);
    end;
    end
    else if Segment.Kind = 1 then
    begin
      ScreenRenderBuffer.DrawLine16Clipped(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y),
        Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, ClipRect);
    end
    else
    begin
      LineRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
        Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.ClippedColor,
        Segment.PixelLast.X, Segment.PixelLast.Y, Segment.ClippedEndColor);
    end;
  end
  else
    if ShadowCircle.LightBuffer <> nil then
      if ShadowCircle.LightBuffer.Pixels <> nil then
        if Segment.Visible then
        begin
          if not SkipSavedPixelRestore then
          begin
            OKGR_Line_CopyFromBuf_WORD(Segment.SavedPixels, ScreenRenderBuffer.Pixels,
              ScreenRenderBuffer.PitchBytes, Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.PixelLast.X, Segment.PixelLast.Y);
            if Segment.Animated then ScreenRenderBuffer.DrawShadowLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, AnimationPhase, ClipRect, AddPointerOffset(ShadowCircle.LightBuffer.Pixels, ShadowCircle.LightBuffer.PitchBytes * Y + X), ShadowCircle.LightBuffer.PitchBytes)
            else ScreenRenderBuffer.DrawShadowLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, 0, ClipRect, AddPointerOffset(ShadowCircle.LightBuffer.Pixels, ShadowCircle.LightBuffer.PitchBytes * Y + X), ShadowCircle.LightBuffer.PitchBytes);
          end
          else
          begin
            if Segment.Animated then ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, AnimationPhase, ClipRect)
            else ScreenRenderBuffer.DrawAnimatedLine16(Classes.Point(Segment.PixelFirst.X, Segment.PixelFirst.Y), Classes.Point(Segment.PixelLast.X, Segment.PixelLast.Y), Segment.Color, 0, ClipRect);
          end;
        end;
end;
{ @end $4A57A0 }

{ @routine $4A5AF0 TPolyLineGI_CommitFrameDraw }
procedure TPolyLineGI.CommitFrameDraw;
var Segment: PPolyLineSegmentGI; Temp: Pointer;
begin
  FrameDrawing := True;
  Segment := FirstSegment;
  while Segment <> nil do
  begin
    AllocatePixelBuffers(Segment);
    if Segment.PreviouslyVisible then
    begin
      if not SkipSavedPixelRestore then
        OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes,
          ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
          Segment.PreviousFirst.X, Segment.PreviousFirst.Y, Segment.PreviousLast.X, Segment.PreviousLast.Y);
      Segment.PreviouslyVisible := False;
    end;
    if Segment.Visible then
    begin
      if not SkipSavedPixelRestore then
        OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes,
          ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
          Segment.PixelFirst.X, Segment.PixelFirst.Y, Segment.PixelLast.X, Segment.PixelLast.Y);
      Segment.PreviouslyVisible := True;
      Segment.PreviousFirst.X := Segment.PixelFirst.X;
      Segment.PreviousFirst.Y := Segment.PixelFirst.Y;
      Segment.PreviousLast.X := Segment.PixelLast.X;
      Segment.PreviousLast.Y := Segment.PixelLast.Y;
      Temp := Segment.SavedPixels;
      Segment.SavedPixels := Segment.PreviousPixels;
      Segment.PreviousPixels := Temp;
      Segment.Visible := False;
    end;
    Segment := Segment.Next;
  end;
end;
{ @end $4A5AF0 }

end.

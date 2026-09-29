unit GI_GraphBuf;
// Unit bracket (inferred): CODE 0x0046EC6C..0x0046F79B; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_Main, GI_MessageLoop, GR_GraphBuf, Types;

type
  TGraphBufGI = class(TObjectGI) // @size $108
  public
    GraphBuf: TGraphBufGR; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105
    HalfAlpha: Boolean; // @offset $106
    SourceHasPerPixelAlpha: Boolean; // @offset $107

    constructor Create(Owner: TObjectGI); // @addr $46ED7C
    destructor Destroy; override; // @addr $46EDD8 @note "Frees GraphBuf only when it is owned."
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46EE10
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $46EE28
    procedure Clear; override; // @addr $46EE40
    procedure SetHalfAlpha(Value: Boolean); // @addr $46EE70
    procedure AllocateBuffer(Width, Height: Integer); // @addr $46EE88
    procedure ClearOwnedBuffer; // @addr $46EEA0
    procedure CopyScreenRectToBuffer(ScreenRect, BufferRect: TRect); // @addr $46EEAC @note "Requires equal nonempty extents, in-bounds rectangles and a buffer without per-pixel alpha."
    procedure LoadBitmapPathAsRgba(const BitmapPath: WideString); // @addr $46EFCC
    procedure LoadBitmapPathAsRgb(const BitmapPath: WideString); // @addr $46F088
    function GetVisualCenter: TPoint; // @addr $46F144 @note "Uses nonzero pixels. CenterFill is unsupported and can leave bounds changed and temporary storage leaked."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $46F444
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $46F470
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $46F48C
    procedure Draw(ClipRect: TRect); override; // @addr $46F558
  end;

implementation

// @unit-initialization $46F794
// @unit-finalization $46F764

uses EC_OKGF, EC_Cache, EC_CacheBitmap, EC_CacheGI, EC_Mem, GR_Main, Classes, Windows;

{ @routine $46ED7C TGraphBufGI_Create }
constructor TGraphBufGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  GraphBuf := TGraphBufGR.Create;
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
end;
{ @end $46ED7C }

{ @routine $46EDD8 TGraphBufGI_Destroy }
destructor TGraphBufGI.Destroy;
begin
  GraphBuf.Free;
  GraphBuf := nil;
  inherited Destroy;
end;
{ @end $46EDD8 }

{ @routine $46EE10 TGraphBufGI_SetImageKindX }
procedure TGraphBufGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $46EE10 }

{ @routine $46EE28 TGraphBufGI_SetImageKindY }
procedure TGraphBufGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $46EE28 }

{ @routine $46EE40 TGraphBufGI_Clear }
procedure TGraphBufGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
  if GraphBuf <> nil then GraphBuf.Clear;
  inherited Clear;
end;
{ @end $46EE40 }

{ @routine $46EE70 TGraphBufGI_SetHalfAlpha }
procedure TGraphBufGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    Invalidate;
  end;
end;
{ @end $46EE70 }

{ @routine $46EE88 TGraphBufGI_AllocateBuffer }
procedure TGraphBufGI.AllocateBuffer(Width, Height: Integer);
begin
  GraphBuf.AllocateNative(Width, Height);
  SourceHasPerPixelAlpha := False;
end;
{ @end $46EE88 }

{ @routine $46EEA0 TGraphBufGI_ClearOwnedBuffer }
procedure TGraphBufGI.ClearOwnedBuffer;
begin
  GraphBuf.Clear;
end;
{ @end $46EEA0 }

{ @routine $46EEAC TGraphBufGI_CopyScreenRectToBuffer }
procedure TGraphBufGI.CopyScreenRectToBuffer(ScreenRect, BufferRect: TRect);
begin
  if SourceHasPerPixelAlpha or (GraphBuf.Pixels = nil) or
    (ScreenRect.Right - ScreenRect.Left <> BufferRect.Right - BufferRect.Left) or
    (ScreenRect.Bottom - ScreenRect.Top <> BufferRect.Bottom - BufferRect.Top) or
    (ScreenRect.Right = ScreenRect.Left) or (ScreenRect.Bottom = ScreenRect.Top) or
    (ScreenRect.Left < 0) or (ScreenRect.Top < 0) or
    (GameScreenWidth < ScreenRect.Right) or (GameScreenHeight < ScreenRect.Bottom) then Exit;
  if (BufferRect.Left < 0) or (BufferRect.Top < 0) or
    (GraphBuf.Width < BufferRect.Right) or (GraphBuf.Height < BufferRect.Bottom) then Exit;
  OKGR_Copy_XY_XY_WORD(GraphBuf.Pixels, GraphBuf.PitchBytes,
    BufferRect.Left, BufferRect.Top, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
    ScreenRect.Left, ScreenRect.Top, BufferRect.Right - BufferRect.Left, BufferRect.Bottom - BufferRect.Top);
end;
{ @end $46EEAC }

{ @routine $46EFCC TGraphBufGI_LoadBitmapPathAsRgba }
procedure TGraphBufGI.LoadBitmapPathAsRgba(const BitmapPath: WideString);
var Control: TCacheControlEC; Bitmap: TCBitmapEC;
begin
  Control := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(BitmapPath);
  Bitmap := AcquireOrCreateBitmap(Control);
  try
    GraphBuf.AllocateRgba(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height, Bitmap.Bitmap.PitchBytes);
    CopyMemory(GraphBuf.Pixels, Bitmap.Bitmap.Pixels, GraphBuf.PitchBytes * GraphBuf.Height);
  finally
    Control.Release;
  end;
  Control.Free;
  SourceHasPerPixelAlpha := True;
end;
{ @end $46EFCC }

{ @routine $46F088 TGraphBufGI_LoadBitmapPathAsRgb }
procedure TGraphBufGI.LoadBitmapPathAsRgb(const BitmapPath: WideString);
var Control: TCacheControlEC; Bitmap: TCBitmapEC;
begin
  Control := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(BitmapPath);
  Bitmap := AcquireOrCreateBitmap(Control);
  try
    GraphBuf.AllocateRgb(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height, Bitmap.Bitmap.PitchBytes);
    CopyMemory(GraphBuf.Pixels, Bitmap.Bitmap.Pixels, GraphBuf.PitchBytes * GraphBuf.Height);
  finally
    Control.Release;
  end;
  Control.Free;
  SourceHasPerPixelAlpha := False;
end;
{ @end $46F088 }

{ @routine $46F144 TGraphBufGI_GetVisualCenter }
function TGraphBufGI.GetVisualCenter: TPoint;
var Buffer: TGraphBufGR; Width, Height, Left, Right, X, Top, Bottom, Y, Count: Integer; SavedBounds, Clip: TRect;
begin
  SavedBounds := HitTestBounds;
  Dec(HitTestBounds.Right, HitTestBounds.Left);
  Dec(HitTestBounds.Bottom, HitTestBounds.Top);
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  Clip := HitTestBounds;
  Buffer := TGraphBufGR.Create;
  Buffer.AllocateNative(HitTestBounds.Right, HitTestBounds.Bottom);
  Width := GraphBuf.Width;
  Height := GraphBuf.Height;
  if ImageKindX = ikxLeftFill then
  begin
    Left := HitTestBounds.Left;
    Right := HitTestBounds.Right;
  end
  else if ImageKindX = ikxRightFill then
  begin
    Right := HitTestBounds.Right;
    Left := Right;
    while Left > Clip.Left do Dec(Left, Width);
  end
  else if ImageKindX = ikxLeft then
  begin
    Left := HitTestBounds.Left;
    Right := Left + Width;
  end
  else if ImageKindX = ikxRight then
  begin
    Right := HitTestBounds.Right;
    Left := Right - Width;
  end
  else if ImageKindX = ikxCenter then
  begin
    Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
    Right := Left + Width;
  end
  else begin Exit; end;
  if ImageKindY = ikyTopFill then
  begin
    Top := HitTestBounds.Top;
    Bottom := HitTestBounds.Bottom;
  end
  else if ImageKindY = ikyBottomFill then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom;
    while Top > Clip.Top do Dec(Top, Height);
  end
  else if ImageKindY = ikyTop then
  begin
    Top := HitTestBounds.Top;
    Bottom := Top + Height;
  end
  else if ImageKindY = ikyBottom then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom - Height;
  end
  else if ImageKindY = ikyCenter then
  begin
    Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
    Bottom := Top + Height;
  end
  else begin Exit; end;
  Buffer.ClearPixels;
  if SourceHasPerPixelAlpha then
  begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        DrawAlphaGraphBuffer16Clipped(Buffer.Pixels, Buffer.PitchBytes, X, Y, GraphBuf, Clip);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  end
  else
  begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        CopyGraphBuffer16Clipped(Buffer.Pixels, Buffer.PitchBytes, X, Y, GraphBuf, Clip, HalfAlpha, False);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  end;
  Result.X := 0;
  Result.Y := 0;
  Count := 0;
  for Y := 0 to Buffer.Height - 1 do
    for X := 0 to Buffer.Width - 1 do
      if Buffer.GetPixel16(X, Y) <> 0 then
      begin
        Inc(Result.X, X);
        Inc(Result.Y, Y);
        Inc(Count);
      end;
  Buffer.Free;
  HitTestBounds := SavedBounds;
  if Count < 1 then Result := Classes.Point(0, 0)
  else Result := Classes.Point(Result.X div Count, Result.Y div Count);
end;
{ @end $46F144 }

{ @routine $46F444 TGraphBufGI_LoadFromConfigPath }
procedure TGraphBufGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $46F444 }

{ @routine $46F470 TGraphBufGI_LoadFromBlock }
procedure TGraphBufGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;
{ @end $46F470 }

{ @routine $46F48C TGraphBufGI_LoadImageProperties }
procedure TGraphBufGI.LoadImageProperties(Block: TBlockParEC);
begin
  if Block.CountParams('HalfAlpha') > 0 then SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
  if Block.CountParams('CacheRGBA') > 0 then LoadBitmapPathAsRgba(Block.GetParam('CacheRGBA'));
end;
{ @end $46F48C }

{ @routine $46F558 TGraphBufGI_Draw }
procedure TGraphBufGI.Draw(ClipRect: TRect);
var Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  if GraphBuf.Pixels = nil then Exit;
  Width := GraphBuf.Width;
  Height := GraphBuf.Height;
  if ImageKindX = ikxLeftFill then
  begin
    Left := HitTestBounds.Left;
    Right := HitTestBounds.Right;
  end
  else if ImageKindX = ikxRightFill then
  begin
    Right := HitTestBounds.Right;
    Left := Right;
    while Left > ClipRect.Left do Dec(Left, Width);
  end
  else if ImageKindX = ikxLeft then
  begin
    Left := HitTestBounds.Left;
    Right := Left + Width;
  end
  else if ImageKindX = ikxRight then
  begin
    Right := HitTestBounds.Right;
    Left := Right - Width;
  end
  else if ImageKindX = ikxCenter then
  begin
    Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
    Right := Left + Width;
  end
  else begin Exit; end;
  if ImageKindY = ikyTopFill then
  begin
    Top := HitTestBounds.Top;
    Bottom := HitTestBounds.Bottom;
  end
  else if ImageKindY = ikyBottomFill then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom;
    while Top > ClipRect.Top do Dec(Top, Height);
  end
  else if ImageKindY = ikyTop then
  begin
    Top := HitTestBounds.Top;
    Bottom := Top + Height;
  end
  else if ImageKindY = ikyBottom then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom - Height;
  end
  else if ImageKindY = ikyCenter then
  begin
    Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
    Bottom := Top + Height;
  end
  else begin Exit; end;
  if SourceHasPerPixelAlpha then
  begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        DrawAlphaGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, GraphBuf, ClipRect);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  end
  else
  begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        CopyGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, GraphBuf, ClipRect, HalfAlpha, False);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  end;

end;
{ @end $46F558 }

end.

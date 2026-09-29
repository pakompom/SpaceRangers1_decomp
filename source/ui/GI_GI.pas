unit GI_GI;
// Unit bracket (inferred): CODE 0x0046D8F0..0x0046E623; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheGI, GI_Main, GI_MessageLoop, GR_GraphBuf, Types;

type
  TgiGI = class(TObjectGI) // @size $108
  public
    ImageCache: TCGiControlEC; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105

    constructor Create(Owner: TObjectGI); // @addr $46D9FC
    destructor Destroy; override; // @addr $46DA6C
    procedure Clear; override; // @addr $46DAA4 @note "Preserves alpha and the cache key."
    procedure SetImagePath(const ImagePath: WideString); // @addr $46DAB8
    function GetContentSize: TPoint; // @addr $46DAEC
    function GetContentOrigin: TPoint; // @addr $46DB48
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46DBB4
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $46DBCC
    function HitTestPixel(Point: TPoint): Boolean; // @addr $46DBE4 @note "Black pixels do not count as hits."
    function GetVisualCenter: TPoint; // @addr $46DE70 @note "Returns the mean coordinates of nonzero rendered pixels, or (0,0) when none exist."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $46E194
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $46E1C0
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $46E1DC
    procedure Draw(ClipRect: TRect); override; // @addr $46E358
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $46E564
  end;

procedure LoadGiByPathIntoGraphBuf(const GiPath: WideString; Destination: TGraphBufGR); // @addr $46E570

implementation

// @unit-initialization $46E61C
// @unit-finalization $46E5EC

uses EC_Cache, EC_Mem, GR_Main;

{ @routine $46D9FC TgiGI_Create }
constructor TgiGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCGiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
end;
{ @end $46D9FC }

{ @routine $46DA6C TgiGI_Destroy }
destructor TgiGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $46DA6C }

{ @routine $46DAA4 TgiGI_Clear }
procedure TgiGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  inherited Clear;
end;
{ @end $46DAA4 }

{ @routine $46DAB8 TgiGI_SetImagePath }
procedure TgiGI.SetImagePath(const ImagePath: WideString);
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
  end;
end;
{ @end $46DAB8 }

{ @routine $46DAEC TgiGI_GetContentSize }
function TgiGI.GetContentSize: TPoint;
var Image: TCGiEC;
begin
  Image := AcquireCachedGi(ImageCache);
  try
    Result := Image.Image.GetContentSize;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46DAEC }

{ @routine $46DB48 TgiGI_GetContentOrigin }
function TgiGI.GetContentOrigin: TPoint;
var Image: TCGiEC; Bounds: TRect;
begin
  Image := AcquireCachedGi(ImageCache);
  try
    Bounds := Image.Image.GetBoundsRect;
    Result := Bounds.TopLeft;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46DB48 }

{ @routine $46DBB4 TgiGI_SetImageKindX }
procedure TgiGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $46DBB4 }

{ @routine $46DBCC TgiGI_SetImageKindY }
procedure TgiGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $46DBCC }

{ @routine $46DBE4 TgiGI_HitTestPixel }
function TgiGI.HitTestPixel(Point: TPoint): Boolean;
var Image: TCGiEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer; Pixel: Cardinal; Pixels: Pointer; Buffer: TGraphBufGR; Clip: TRect;
begin
  Pixel := 0;
  Clip.Left := Point.X;
  Clip.Top := Point.Y;
  Clip.Right := Point.X + 1;
  Clip.Bottom := Point.Y + 1;
  Image := AcquireCachedGi(ImageCache);
  try
  Width := Image.Image.GetContentSize.X;
  Height := Image.Image.GetContentSize.Y;
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
  else begin Result := False; Exit; end;
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
  else begin Result := False; Exit; end;
    Pixels := AddPointerOffset(@Pixel, -(ScreenRenderBuffer.PitchBytes * Point.Y + Point.X * SizeOf(Word)));
    Buffer := TGraphBufGR.Create;
    Buffer.AttachPixels(1, 1, ScreenRenderBuffer.PitchBytes, Pixels);
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Image.Image.DrawToGraphBuf(Buffer, X, Y, Clip, 0);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
    Buffer.Free;
  finally
    ImageCache.Release;
  end;
  Result := Pixel <> 0;
end;
{ @end $46DBE4 }

{ @routine $46DE70 TgiGI_GetVisualCenter }
function TgiGI.GetVisualCenter: TPoint;
var Buffer: TGraphBufGR; Image: TCGiEC; Width, Height, Left, Right, X, Top, Bottom, Y, Count: Integer; SavedBounds, Clip: TRect;
begin
  SavedBounds := HitTestBounds;
  Dec(HitTestBounds.Right, HitTestBounds.Left);
  Dec(HitTestBounds.Bottom, HitTestBounds.Top);
  HitTestBounds.Left := 0;
  HitTestBounds.Top := 0;
  Clip := HitTestBounds;
  Buffer := TGraphBufGR.Create;
  Buffer.AllocateNative(HitTestBounds.Right, HitTestBounds.Bottom);
  Image := AcquireCachedGi(ImageCache);
  try
  Width := Image.Image.GetContentSize.X;
  Height := Image.Image.GetContentSize.Y;
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
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Image.Image.DrawToGraphBuf(Buffer, X, Y, Clip, 0);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  finally
    ImageCache.Release;
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
{ @end $46DE70 }

{ @routine $46E194 TgiGI_LoadFromConfigPath }
procedure TgiGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $46E194 }

{ @routine $46E1C0 TgiGI_LoadFromBlock }
procedure TgiGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;
{ @end $46E1C0 }

{ @routine $46E1DC TgiGI_LoadImageProperties }
procedure TgiGI.LoadImageProperties(Block: TBlockParEC);
begin
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('KindX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
end;
{ @end $46E1DC }

{ @routine $46E358 TgiGI_Draw }
procedure TgiGI.Draw(ClipRect: TRect);
var Image: TCGiEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Image := AcquireCachedGi(ImageCache);
  try
  Width := Image.Image.GetContentSize.X;
  Height := Image.Image.GetContentSize.Y;
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
  begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Image.Image.DrawToGraphBuf(ScreenRenderBuffer, X, Y, ClipRect, 0);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  end;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46E358 }

{ @routine $46E564 TgiGI_QueueImageLoad }
procedure TgiGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $46E564 }

{ @routine $46E570 LoadGiByPathIntoGraphBuf }
procedure LoadGiByPathIntoGraphBuf(const GiPath: WideString; Destination: TGraphBufGR);
var Control: TCacheControlEC; Image: TCGiEC;
begin
  Control := TCGiControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(GiPath);
  Image := AcquireCachedGi(Control);
  try
    Image.Image.DecodeToGraphBuf(Destination);
  finally
    Control.Release;
  end;
  Control.Free;
end;
{ @end $46E570 }

end.

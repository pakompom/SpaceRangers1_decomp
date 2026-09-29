unit GI_AlphaImage;
// Unit bracket (inferred): CODE 0x0046BBD0..0x0046C85B; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheAlphaBitmap, GI_Main, GI_MessageLoop, Types;

type
  TAlphaImageGI = class(TObjectGI) // @size $108
  public
    ImageCache: TCAlphaBitmapControlEC; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105

    constructor Create(Owner: TObjectGI); // @addr $46BCE4
    destructor Destroy; override; // @addr $46BD54
    procedure Clear; override; // @addr $46BD8C
    procedure SetImagePath(const ImagePath: WideString); // @addr $46BDA0
    function GetContentSize: TPoint; // @addr $46BDD4
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46BE2C
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $46BE44
    function HitTestPixel(Point: TPoint): Boolean; // @addr $46BE5C @note "Black pixels do not count as hits."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $46C0A8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $46C370
    procedure Draw(ClipRect: TRect); override; // @addr $46C618
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $46C818
  end;

implementation

// @unit-initialization $46C854
// @unit-finalization $46C824

uses EC_Str, EC_Mem, GR_Main, SysUtils;

{ @routine $46BCE4 TAlphaImageGI_Create }
constructor TAlphaImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCAlphaBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
end;
{ @end $46BCE4 }

{ @routine $46BD54 TAlphaImageGI_Destroy }
destructor TAlphaImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $46BD54 }

{ @routine $46BD8C TAlphaImageGI_Clear }
procedure TAlphaImageGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  inherited Clear;
end;
{ @end $46BD8C }

{ @routine $46BDA0 TAlphaImageGI_SetImagePath }
procedure TAlphaImageGI.SetImagePath(const ImagePath: WideString);
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
  end;
end;
{ @end $46BDA0 }

{ @routine $46BDD4 TAlphaImageGI_GetContentSize }
function TAlphaImageGI.GetContentSize: TPoint;
var Bitmap: TCAlphaBitmapEC;
begin
  Bitmap := AcquireOrCreateAlphaBitmap(ImageCache);
  try
    Result := Bitmap.PixelSize;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46BDD4 }

{ @routine $46BE2C TAlphaImageGI_SetImageKindX }
procedure TAlphaImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $46BE2C }

{ @routine $46BE44 TAlphaImageGI_SetImageKindY }
procedure TAlphaImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $46BE44 }

{ @routine $46BE5C TAlphaImageGI_HitTestPixel }
function TAlphaImageGI.HitTestPixel(Point: TPoint): Boolean;
var Bitmap: TCAlphaBitmapEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer; Pixel: Cardinal; Pixels: Pointer; Clip: TRect;
begin
  Pixel := 0;
  Clip.Left := Point.X;
  Clip.Top := Point.Y;
  Clip.Right := Point.X + 1;
  Clip.Bottom := Point.Y + 1;
  Bitmap := AcquireOrCreateAlphaBitmap(ImageCache);
  try
  Width := Bitmap.PixelSize.X;
  Height := Bitmap.PixelSize.Y;
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
  Y := Top;
  while (Y < Bottom) and (Pixel = 0) do
  begin
    X := Left;
    while (X < Right) and (Pixel = 0) do
    begin
      Bitmap.Draw16(Pixels, ScreenRenderBuffer.PitchBytes, X, Y, Clip);
      Inc(X, Width);
    end;
    Inc(Y, Height);
  end;
  finally
    ImageCache.Release;
  end;
  Result := Pixel <> 0;
end;
{ @end $46BE5C }

{ @routine $46C0A8 TAlphaImageGI_LoadFromConfigPath }
procedure TAlphaImageGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireOrCreateAlphaBitmap(ImageCache) do
  try
    SetSize(PixelSize);
  finally
    ImageCache.Release;
  end;
  end;
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    SetSize(Classes.Point(StrToInt(ExtractDelimitedPartW(Text, 0, ',')), StrToInt(ExtractDelimitedPartW(Text, 1, ','))));
  end;
  if Block.CountParams('KindX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
end;
{ @end $46C0A8 }

{ @routine $46C370 TAlphaImageGI_LoadFromBlock }
procedure TAlphaImageGI.LoadFromBlock(Block: TBlockParEC);
var Text: WideString;
begin
  inherited LoadFromBlock(Block);
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireOrCreateAlphaBitmap(ImageCache) do
  try
    SetSize(PixelSize);
  finally
    ImageCache.Release;
  end;
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    SetSize(Classes.Point(StrToInt(ExtractDelimitedPartW(Text, 0, ',')), StrToInt(ExtractDelimitedPartW(Text, 1, ','))));
  end;
  if Block.CountParams('KindX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
end;
{ @end $46C370 }

{ @routine $46C618 TAlphaImageGI_Draw }
procedure TAlphaImageGI.Draw(ClipRect: TRect);
var Bitmap: TCAlphaBitmapEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Bitmap := AcquireOrCreateAlphaBitmap(ImageCache);
  try
  Width := Bitmap.PixelSize.X;
  Height := Bitmap.PixelSize.Y;
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
      Bitmap.Draw16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, ClipRect);
      Inc(X, Width);
    end;
    Inc(Y, Height);
  end;
  end;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46C618 }

{ @routine $46C818 TAlphaImageGI_QueueImageLoad }
procedure TAlphaImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $46C818 }

end.

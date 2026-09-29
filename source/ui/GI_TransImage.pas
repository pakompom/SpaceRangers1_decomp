unit GI_TransImage;
// Unit bracket (inferred): CODE 0x0046AC90..0x0046B66F; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheTBitmap, GI_Main, GI_MessageLoop, Types;

type
  TTransImageGI = class(TObjectGI) // @size $108
  public
    ImageCache: TCTBitmapControlEC; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105
    HalfAlpha: Boolean; // @offset $106

    constructor Create(Owner: TObjectGI); // @addr $46ADA4
    destructor Destroy; override; // @addr $46AE14
    procedure Clear; override; // @addr $46AE4C @note "Preserves HalfAlpha and the cache key."
    procedure SetImagePath(const ImagePath: WideString); // @addr $46AE60
    function GetContentSize: TPoint; // @addr $46AE94
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46AEEC
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $46AF04
    procedure SetHalfAlpha(Value: Boolean); // @addr $46AF1C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $46AF34
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $46B1BC
    procedure Draw(ClipRect: TRect); override; // @addr $46B420
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $46B62C
  end;

implementation

// @unit-initialization $46B668
// @unit-finalization $46B638

uses EC_Str, EC_Mem, GR_Main, SysUtils;

{ @routine $46ADA4 TTransImageGI_Create }
constructor TTransImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCTBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
end;
{ @end $46ADA4 }

{ @routine $46AE14 TTransImageGI_Destroy }
destructor TTransImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $46AE14 }

{ @routine $46AE4C TTransImageGI_Clear }
procedure TTransImageGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  inherited Clear;
end;
{ @end $46AE4C }

{ @routine $46AE60 TTransImageGI_SetImagePath }
procedure TTransImageGI.SetImagePath(const ImagePath: WideString);
begin
  if ImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    ImageCache.SetCacheKey(ImagePath);
  end;
end;
{ @end $46AE60 }

{ @routine $46AE94 TTransImageGI_GetContentSize }
function TTransImageGI.GetContentSize: TPoint;
var Bitmap: TCTBitmapEC;
begin
  Bitmap := AcquireCachedTransBitmap(ImageCache);
  try
    Result := Bitmap.PixelSize;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46AE94 }

{ @routine $46AEEC TTransImageGI_SetImageKindX }
procedure TTransImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $46AEEC }

{ @routine $46AF04 TTransImageGI_SetImageKindY }
procedure TTransImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $46AF04 }

{ @routine $46AF1C TTransImageGI_SetHalfAlpha }
procedure TTransImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    Invalidate;
  end;
end;
{ @end $46AF1C }

{ @routine $46AF34 TTransImageGI_LoadFromConfigPath }
procedure TTransImageGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireCachedTransBitmap(ImageCache) do
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
  if Block.CountParams('HalfAlpha') > 0 then SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;
{ @end $46AF34 }

{ @routine $46B1BC TTransImageGI_LoadFromBlock }
procedure TTransImageGI.LoadFromBlock(Block: TBlockParEC);
var Text: WideString;
begin
  inherited LoadFromBlock(Block);
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireCachedTransBitmap(ImageCache) do
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
  if Block.CountParams('HalfAlpha') > 0 then SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;
{ @end $46B1BC }

{ @routine $46B420 TTransImageGI_Draw }
procedure TTransImageGI.Draw(ClipRect: TRect);
var Bitmap: TCTBitmapEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Bitmap := AcquireCachedTransBitmap(ImageCache);
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
  Y := Top;
  while Y < Bottom do
  begin
    X := Left;
    while X < Right do
    begin
      DrawTransparentBuffer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, Bitmap.TransBuffer, ClipRect, HalfAlpha);
      Inc(X, Width);
    end;
    Inc(Y, Height);
  end;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46B420 }

{ @routine $46B62C TTransImageGI_QueueImageLoad }
procedure TTransImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $46B62C }

end.

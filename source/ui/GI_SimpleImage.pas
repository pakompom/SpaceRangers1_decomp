unit GI_SimpleImage;
// Unit bracket (inferred): CODE 0x00469F80..0x0046A997; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, GI_Main, GI_MessageLoop, Types;

type
  TSimpleImageGI = class(TObjectGI) // @size $108
  public
    ImageCache: TCBitmapControlEC; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105
    HalfAlpha: Boolean; // @offset $106

    constructor Create(Owner: TObjectGI); // @addr $46A094
    destructor Destroy; override; // @addr $46A10C
    procedure Clear; override; // @addr $46A144 @note "Preserves the cache control and its key."
    procedure SetImagePath(const ImagePath: WideString); // @addr $46A160 @note "Invalidates before changing the cache key."
    function GetContentSize: TPoint; // @addr $46A180
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46A1E4
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $46A1FC
    procedure SetHalfAlpha(Value: Boolean); // @addr $46A214
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $46A22C @note "Image is optional."
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $46A4C8 @note "Requires Image."
    procedure Draw(ClipRect: TRect); override; // @addr $46A744 @note "CenterFill is unimplemented on both axes."
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $46A954
  end;

implementation

// @unit-initialization $46A990
// @unit-finalization $46A960

uses EC_Str, EC_Mem, GR_Main, SysUtils;

{ @routine $46A094 TSimpleImageGI_Create }
constructor TSimpleImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
end;
{ @end $46A094 }

{ @routine $46A10C TSimpleImageGI_Destroy }
destructor TSimpleImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $46A10C }

{ @routine $46A144 TSimpleImageGI_Clear }
procedure TSimpleImageGI.Clear;
begin
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  HalfAlpha := False;
  inherited Clear;
end;
{ @end $46A144 }

{ @routine $46A160 TSimpleImageGI_SetImagePath }
procedure TSimpleImageGI.SetImagePath(const ImagePath: WideString);
begin
  Invalidate;
  ImageCache.SetCacheKey(ImagePath);
end;
{ @end $46A160 }

{ @routine $46A180 TSimpleImageGI_GetContentSize }
function TSimpleImageGI.GetContentSize: TPoint;
var Bitmap: TCBitmapEC;
begin
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    Result := Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height);
  finally
    ImageCache.Release;
  end;
end;
{ @end $46A180 }

{ @routine $46A1E4 TSimpleImageGI_SetImageKindX }
procedure TSimpleImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $46A1E4 }

{ @routine $46A1FC TSimpleImageGI_SetImageKindY }
procedure TSimpleImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $46A1FC }

{ @routine $46A214 TSimpleImageGI_SetHalfAlpha }
procedure TSimpleImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    Invalidate;
  end;
end;
{ @end $46A214 }

{ @routine $46A22C TSimpleImageGI_LoadFromConfigPath }
procedure TSimpleImageGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireOrCreateBitmap(ImageCache) do
  try
    SetSize(Classes.Point(Bitmap.Width, Bitmap.Height));
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
{ @end $46A22C }

{ @routine $46A4C8 TSimpleImageGI_LoadFromBlock }
procedure TSimpleImageGI.LoadFromBlock(Block: TBlockParEC);
var Text: WideString;
begin
  inherited LoadFromBlock(Block);
  ImageCache.SetCacheKey(Block.GetParam('Image'));
  with AcquireOrCreateBitmap(ImageCache) do
  try
    SetSize(Classes.Point(Bitmap.Width, Bitmap.Height));
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
{ @end $46A4C8 }

{ @routine $46A744 TSimpleImageGI_Draw }
procedure TSimpleImageGI.Draw(ClipRect: TRect);
var Bitmap: TCBitmapEC; Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
  Width := Bitmap.Bitmap.Width;
  Height := Bitmap.Bitmap.Height;
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
      CopyGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, Bitmap.Bitmap, ClipRect, HalfAlpha, False);
      Inc(X, Width);
    end;
    Inc(Y, Height);
  end;
  end;
  finally
    ImageCache.Release;
  end;
end;
{ @end $46A744 }

{ @routine $46A954 TSimpleImageGI_QueueImageLoad }
procedure TSimpleImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $46A954 }

end.

unit GI_RotateImage2;
// Unit bracket (inferred): CODE 0x0047DCC4..0x0047E72F; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, EC_CacheRotateBuf, GI_MessageLoop, GR_GraphBuf, Types;

type
  TRotateImage2GI = class(TObjectGI) // @size $110
  public
    ImageCache: TCBitmapControlEC; // @offset $100
    RotationCache: TCRotateBufControlEC; // @offset $104
    RotatedImage: TGraphBufGR; // @offset $108
    RenderedAngle: Byte; // @offset $10C
    Angle: Byte; // @offset $10D
    Alpha: Byte; // @offset $10E
    ImageDirty: Boolean; // @offset $10F

    constructor Create(Owner: TObjectGI); // @addr $47DDD8
    destructor Destroy; override; // @addr $47DE90
    procedure Clear; override; // @addr $47DEF0 @note "Preserves cache keys and the allocated image buffer."
    procedure QueueImagePath(PendingLoads: TList; Path: WideString); // @addr $47E650
    procedure SetImage(Path: WideString; ImageSize, Pivot: TPoint); // @addr $47DF54 @note "Appends ?RGBA to Path; replaces size and origin with a centered square enclosing all rotations."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47E278
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47E2A4
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $47E2DC
    procedure Draw(ClipRect: TRect); override; // @addr $47E498
    procedure SetAngle(Value: Byte); // @addr $47DF14 @note "A full turn has 256 steps."
    procedure SetAlpha(Value: Byte); // @addr $47DF34
  end;

implementation

// @unit-initialization $47E728
// @unit-finalization $47E6F8

uses EC_OKGF, Classes, SysUtils, Math, EC_Cache, EC_Mem, GR_Main, GI_Main;
{ @routine $47DDD8 TRotateImage2GI_Create }
constructor TRotateImage2GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageDirty := True;
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
  RotatedImage := TGraphBufGR.Create;
  RenderedAngle := 0;
  Angle := 0;
  Alpha := 255;
  ImageDirty := True;
end;
{ @end $47DDD8 }

{ @routine $47DE90 TRotateImage2GI_Destroy }
destructor TRotateImage2GI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  RotatedImage.Free;
  RotatedImage := nil;
  inherited Destroy;
end;
{ @end $47DE90 }

{ @routine $47DEF0 TRotateImage2GI_Clear }
procedure TRotateImage2GI.Clear;
begin
  ImageDirty := True;
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited Clear;
end;
{ @end $47DEF0 }

{ @routine $47DF14 TRotateImage2GI_SetAngle }
procedure TRotateImage2GI.SetAngle(Value: Byte);
begin
  if Value <> Angle then
  begin
    Angle := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;
{ @end $47DF14 }

{ @routine $47DF34 TRotateImage2GI_SetAlpha }
procedure TRotateImage2GI.SetAlpha(Value: Byte);
begin
  if Value <> Alpha then
  begin
    Alpha := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;
{ @end $47DF34 }

{ @routine $47DF54 TRotateImage2GI_SetImage }
procedure TRotateImage2GI.SetImage(Path: WideString; ImageSize, Pivot: TPoint);
var
  Image: TCBitmapEC;
  Radius: Double;
begin
  ImageCache.SetCacheKey(Path + '?RGBA');
  Image := AcquireOrCreateBitmap(ImageCache);
  try
    RotationCache.SetCacheKey(IntToStr(ImageSize.X) + ',' + IntToStr(ImageSize.Y) + ',' +
      IntToStr(Cardinal(Image.Bitmap.Width)) + ',' + IntToStr(Cardinal(Image.Bitmap.Height)) + ',' + IntToStr(Pivot.X) + ',' + IntToStr(Pivot.Y));
    // Each subtraction of zero below is an explicit native SUB EAX, 0.
    Radius := Sqr(Pivot.X - 0) + Sqr(Pivot.Y - 0);
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - 0));
    Radius := Max(Radius, Sqr(Pivot.X - 0) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Floor(Sqrt(Radius) * 2.0 + 2.0);
    SetSize(Classes.Point(Trunc(Radius), Trunc(Radius)));
    SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
    if (RotatedImage.Width <> ClientSize.X) or (RotatedImage.Height <> ClientSize.Y) then
      RotatedImage.AllocateRgbaTight(ClientSize.X, ClientSize.Y);
    ImageDirty := True;
  finally
    ImageCache.Release;
  end;
  Invalidate;
end;
{ @end $47DF54 }

{ @routine $47E278 TRotateImage2GI_LoadFromConfigPath }
procedure TRotateImage2GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $47E278 }

{ @routine $47E2A4 TRotateImage2GI_LoadFromBlock }
procedure TRotateImage2GI.LoadFromBlock(Block: TBlockParEC);
begin
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
  ImageDirty := True;
end;
{ @end $47E2A4 }

{ @routine $47E2DC TRotateImage2GI_LoadImageProperties }
procedure TRotateImage2GI.LoadImageProperties(Block: TBlockParEC);
begin
  if (Block.CountParams('Image') > 0) and (Block.CountParams('Size') > 0) and (Block.CountParams('Sme') > 0) then
    SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')), GetPointGI(Block.GetParam('Sme')));
  if Block.CountParams('Angle') > 0 then SetAngle(StrToInt(Block.GetParam('Angle')));
  if Block.CountParams('Trans') > 0 then SetAlpha(StrToInt(Block.GetParam('Trans')));
end;
{ @end $47E2DC }

{ @routine $47E498 TRotateImage2GI_Draw }
procedure TRotateImage2GI.Draw(ClipRect: TRect);
var
  Image: TCBitmapEC;
  Rotation: TCRotateBufEC;
begin
  if (RenderedAngle <> Angle) or (ImageDirty = True) then
  begin
    ImageDirty := False;
    RenderedAngle := Angle;
    Image := nil;
    Rotation := nil;
    try
      Image := AcquireOrCreateBitmap(ImageCache);
      Rotation := AcquireOrCreateRotateBuf(RotationCache);
      RotatedImage.ClearPixels;
      OKGR_RotateBuf_Draw_DWORD(RotatedImage.Pixels, RotatedImage.PitchBytes, Image.Bitmap.Pixels,
        Image.Bitmap.PitchBytes, OriginPoint.X, OriginPoint.Y, Angle, Rotation.Buffer);
      if Alpha <> 255 then
        OKGR_Light_BYTE(AddPointerOffset(RotatedImage.Pixels, 3), 4,
          RotatedImage.PitchBytes - 4 * RotatedImage.Width, RotatedImage.Width, RotatedImage.Height, Alpha);
    finally
      if Image <> nil then ImageCache.Release;
      if Rotation <> nil then RotationCache.Release;
    end;
  end;
  DrawAlphaGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
    HitTestBounds.Left, HitTestBounds.Top, RotatedImage, ClipRect);
end;
{ @end $47E498 }

{ @routine $47E650 TRotateImage2GI_QueueImagePath }
procedure TRotateImage2GI.QueueImagePath(PendingLoads: TList; Path: WideString);
var Control: TCBitmapControlEC;
begin
  Control := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(Path + '?RGBA');
  Control.QueueLoadIfMissing(PendingLoads);
  Control.Free;
end;
{ @end $47E650 }

end.

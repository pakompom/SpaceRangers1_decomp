unit GI_Planet;
// Unit bracket (inferred): CODE 0x0048A6F4..0x0048C02F; inclusive evidence, not full bounds.

interface

uses Types, Classes, EC_CachePalBitmap, EC_CacheRotateBuf, EC_CachePlanetTempl, EC_CacheLightPal, EC_CacheBitmap, GI_MessageLoop, GR_GraphBufPal, EC_BlockPar, GR_GraphBuf;

type
  TPlanetGI = class(TObjectGI) // @size $124
  public
    TemplateCache: TCPlanetTemplControlEC; // @offset $100
    SurfaceImageCache: TCPalBitmapControlEC; // @offset $104
    SurfacePaletteCache: TCLightPalControlEC; // @offset $108
    LightRotationCache: TCRotateBufControlEC; // @offset $10C
    MapWidthMask: Integer; // @offset $110
    SurfaceMapOffset: Integer; // @offset $114
    SourceLightBuffer: Pointer; // @offset $118
    RotatedLightBuffer: Pointer; // @offset $11C
    LightAngle: Byte; // @offset $120
    constructor Create(Owner: TObjectGI); // @addr $48A804
    destructor Destroy; override; // @addr $48A8CC
    procedure Clear; override; // @addr $48A940 @note "Preserves the cache keys."
    procedure SetImage(const MaskPath, ImagePath, LightMapPath: WideString); // @addr $48A988 @note "Image width must be a power of two from 16 through 2048; height must not exceed half the width. The light map must cover that height on both axes."
    procedure SetImageWithRadius(const MaskPath, ImagePath, LightMapPath: WideString; Radius: Integer); // @addr $48AF78 @note "Uses a diameter of 2*Radius+1. Applies the surface-map dimension checks but omits the light-map size check."
    procedure SetImageFromTemplate(const TemplateKey, ImagePath: WideString; Radius: Integer); // @addr $48B508 @note "Uses a diameter of 2*Radius. Reuses an existing surface image and light buffers; ImagePath is used only when the surface cache key is empty."
    procedure SetLightAngle(Value: Byte); // @addr $48B894 @note "A full turn has 256 steps; requires initialized light buffers when the angle changes."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48B940
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48BB10
    procedure Draw(ClipRect: TRect); override; // @addr $48BCA0
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $48BFB8 @note "Queues the template, surface, surface palette and light rotation only."
    procedure SetSurfaceMapOffset(Value: Integer); // @addr $48B87C
  end;

implementation

// @unit-initialization $48C028
// @unit-finalization $48BFF8

uses GlobalsV, EC_OKGF, SysUtils, EC_Cache, EC_Mem, GR_Main, GI_Main;

{ @routine $48A804 TPlanetGI_Create }
constructor TPlanetGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TemplateCache := TCPlanetTemplControlEC.Create;
  GlobalCache.ResetControl(TemplateCache);
  SurfaceImageCache := TCPalBitmapControlEC.Create;
  GlobalCache.ResetControl(SurfaceImageCache);
  SurfacePaletteCache := TCLightPalControlEC.Create;
  GlobalCache.ResetControl(SurfacePaletteCache);
  LightRotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(LightRotationCache);
end;
{ @end $48A804 }

{ @routine $48A8CC TPlanetGI_Destroy }
destructor TPlanetGI.Destroy;
begin
  TemplateCache.Free;
  TemplateCache := nil;
  SurfacePaletteCache.Free;
  SurfacePaletteCache := nil;
  SurfaceImageCache.Free;
  SurfaceImageCache := nil;
  LightRotationCache.Free;
  LightRotationCache := nil;
  inherited Destroy;
end;
{ @end $48A8CC }

{ @routine $48A940 TPlanetGI_Clear }
procedure TPlanetGI.Clear;
begin
  if SourceLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(SourceLightBuffer);
    SourceLightBuffer := nil;
  end;
  if RotatedLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(RotatedLightBuffer);
    RotatedLightBuffer := nil;
  end;
  LightAngle := 0;
  inherited Clear;
end;
{ @end $48A940 }

{ @routine $48A988 TPlanetGI_SetImage }
procedure TPlanetGI.SetImage(const MaskPath, ImagePath, LightMapPath: WideString);
var
  Image: TCPalBitmapEC;
  LightControl: TCPalBitmapControlEC;
  LightImage: TCPalBitmapEC;
begin
  Invalidate;
  if SourceLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(SourceLightBuffer);
    SourceLightBuffer := nil;
  end;
  if RotatedLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(RotatedLightBuffer);
    RotatedLightBuffer := nil;
  end;
  SurfaceImageCache.SetCacheKey(ImagePath);
  SurfacePaletteCache.SetCacheKey(ImagePath);
  Image := AcquireOrCreatePalBitmap(SurfaceImageCache);
  try
    if (Cardinal(Image.Bitmap.Width) shr 1) < Cardinal(Image.Bitmap.Height) then
      raise Exception.Create('TPlanetGI.SetImage. Error create template planet. (LenX div 2)<LenY');
    if (Image.Bitmap.Width <> 16) and (Image.Bitmap.Width <> 32) and
       (Image.Bitmap.Width <> 64) and (Image.Bitmap.Width <> 128) and
       (Image.Bitmap.Width <> 256) and (Image.Bitmap.Width <> 512) and
       (Image.Bitmap.Width <> 1024) and (Image.Bitmap.Width <> 2048) then
      raise Exception.Create('TPlanetGI.SetImage. Error create template planet. LenX<>16 or 32 or 64 or 128 or 256 or 512 or 1024 or 2048');
    MapWidthMask := Image.Bitmap.Width - 1;
    SetSize(Classes.Point(Image.Bitmap.Height + 1, Image.Bitmap.Height + 1));
    TemplateCache.SetCacheKey(MaskPath + '?' + IntToStr(Cardinal(Image.Bitmap.Width)) + ',' + IntToStr(Cardinal(Image.Bitmap.Height)));
    LightControl := TCPalBitmapControlEC.Create;
    GlobalCache.ResetControl(LightControl);
    LightControl.SetCacheKey(LightMapPath);
    LightImage := AcquireOrCreatePalBitmap(LightControl);
    try
      if (Cardinal(Image.Bitmap.Height) > Cardinal(LightImage.Bitmap.Width)) or (Cardinal(Image.Bitmap.Height) > Cardinal(LightImage.Bitmap.Height)) then
        raise Exception.Create('TPlanetGI.SetImage. Error: Size light map < planet.');
      SourceLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(SourceLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if SourceLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      RotatedLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(RotatedLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if RotatedLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      OKGR_LightBuf_Init(SourceLightBuffer, 0);
      OKGR_LightBuf_Init(RotatedLightBuffer, 0);
      LightRotationCache.SetCacheKey(IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width shr 1)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height shr 1)));
      OKGR_LightBuf_LoadFromPalBuf(SourceLightBuffer, LightImage.Bitmap.Pixels, LightImage.Bitmap.Width, LightImage.Bitmap.Height, LightImage.Bitmap.PitchBytes, LightImage.Bitmap.Palette);
    finally
      LightControl.Release;
      LightControl.Free;
    end;
  finally
    SurfaceImageCache.Release;
  end;
  LightAngle := 1;
  SetLightAngle(0);
end;
{ @end $48A988 }

{ @routine $48AF78 TPlanetGI_SetImageWithRadius }
procedure TPlanetGI.SetImageWithRadius(const MaskPath, ImagePath, LightMapPath: WideString; Radius: Integer);
var
  Image: TCPalBitmapEC;
  LightControl: TCPalBitmapControlEC;
  LightImage: TCPalBitmapEC;
begin
  Invalidate;
  if SourceLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(SourceLightBuffer);
    SourceLightBuffer := nil;
  end;
  if RotatedLightBuffer <> nil then
  begin
    OKGR_LightBuf_Destroy(RotatedLightBuffer);
    RotatedLightBuffer := nil;
  end;
  SurfaceImageCache.SetCacheKey(ImagePath);
  SurfacePaletteCache.SetCacheKey(ImagePath);
  Image := AcquireOrCreatePalBitmap(SurfaceImageCache);
  try
    if (Cardinal(Image.Bitmap.Width) shr 1) < Cardinal(Image.Bitmap.Height) then
      raise Exception.Create('TPlanetGI.SetImage. Error create template planet. (LenX div 2)<LenY');
    if (Image.Bitmap.Width <> 16) and (Image.Bitmap.Width <> 32) and
       (Image.Bitmap.Width <> 64) and (Image.Bitmap.Width <> 128) and
       (Image.Bitmap.Width <> 256) and (Image.Bitmap.Width <> 512) and
       (Image.Bitmap.Width <> 1024) and (Image.Bitmap.Width <> 2048) then
      raise Exception.Create('TPlanetGI.SetImage. Error create template planet. LenX<>16 or 32 or 64 or 128 or 256 or 512 or 1024 or 2048');
    MapWidthMask := Image.Bitmap.Width - 1;
    SetSize(Classes.Point(Radius * 2 + 1, Radius * 2 + 1));
    TemplateCache.SetCacheKey(MaskPath + '?' + IntToStr(Cardinal(Image.Bitmap.Width)) + ',' + IntToStr(Cardinal(Image.Bitmap.Height)));
    LightControl := TCPalBitmapControlEC.Create;
    GlobalCache.ResetControl(LightControl);
    LightControl.SetCacheKey(LightMapPath);
    LightImage := AcquireOrCreatePalBitmap(LightControl);
    try
      SourceLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(SourceLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if SourceLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      RotatedLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(RotatedLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if RotatedLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      OKGR_LightBuf_Init(SourceLightBuffer, 0);
      OKGR_LightBuf_Init(RotatedLightBuffer, 0);
      LightRotationCache.SetCacheKey(IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width shr 1)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height shr 1)));
      OKGR_LightBuf_LoadFromPalBuf(SourceLightBuffer, LightImage.Bitmap.Pixels, LightImage.Bitmap.Width, LightImage.Bitmap.Height, LightImage.Bitmap.PitchBytes, LightImage.Bitmap.Palette);
    finally
      LightControl.Release;
      LightControl.Free;
    end;
  finally
    SurfaceImageCache.Release;
  end;
  LightAngle := 1;
  SetLightAngle(0);
end;
{ @end $48AF78 }

{ @routine $48B508 TPlanetGI_SetImageFromTemplate }
procedure TPlanetGI.SetImageFromTemplate(const TemplateKey, ImagePath: WideString; Radius: Integer);
var
  LightControl: TCPalBitmapControlEC;
  LightImage: TCPalBitmapEC;
begin
  Invalidate;
  if SurfaceImageCache.HasEmptyCacheKey then
  begin
    SurfaceImageCache.SetCacheKey(ImagePath);
    SurfacePaletteCache.SetCacheKey(ImagePath);
  end;
  TemplateCache.SetCacheKey(TemplateKey);
  SetSize(Classes.Point(Radius * 2, Radius * 2));
  if SourceLightBuffer = nil then
  begin
    MapWidthMask := SatelliteTemplateParameter1 - 1;
    LightControl := TCPalBitmapControlEC.Create;
    GlobalCache.ResetControl(LightControl);
    LightControl.SetCacheKey(SatelliteLightMapPath);
    LightImage := AcquireOrCreatePalBitmap(LightControl);
    try
      SourceLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(SourceLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if SourceLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      RotatedLightBuffer := OKGR_LightBuf_Create(LightImage.Bitmap.Width, LightImage.Bitmap.Height);
      OKGR_LightBuf_SetSme(RotatedLightBuffer, LightImage.Bitmap.Width shr 1, LightImage.Bitmap.Height shr 1);
      if RotatedLightBuffer = nil then raise Exception.Create('TPlanetGI.SetImage. Error create light buffer.');
      OKGR_LightBuf_Init(SourceLightBuffer, 0);
      OKGR_LightBuf_Init(RotatedLightBuffer, 0);
      LightRotationCache.SetCacheKey(IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height)) + ',' +
        IntToStr(Cardinal(LightImage.Bitmap.Width shr 1)) + ',' + IntToStr(Cardinal(LightImage.Bitmap.Height shr 1)));
      OKGR_LightBuf_LoadFromPalBuf(SourceLightBuffer, LightImage.Bitmap.Pixels, LightImage.Bitmap.Width, LightImage.Bitmap.Height, LightImage.Bitmap.PitchBytes, LightImage.Bitmap.Palette);
    finally
      LightControl.Release;
      LightControl.Free;
    end;
    LightAngle := 1;
    SetLightAngle(0);
  end;
end;
{ @end $48B508 }

{ @routine $48B87C TPlanetGI_SetSurfaceMapOffset }
procedure TPlanetGI.SetSurfaceMapOffset(Value: Integer);
begin
  if SurfaceMapOffset <> Value then
  begin
    SurfaceMapOffset := Value;
    Invalidate;
  end;
end;
{ @end $48B87C }

{ @routine $48B894 TPlanetGI_SetLightAngle }
procedure TPlanetGI.SetLightAngle(Value: Byte);
var
  Rotation: TCRotateBufEC;
begin
  if LightAngle <> Value then
  begin
    LightAngle := Value;
    OKGR_LightBuf_Init(RotatedLightBuffer, 0);
    Rotation := AcquireOrCreateRotateBuf(LightRotationCache);
    try
      OKGR_LightBuf_Rotate(RotatedLightBuffer, SourceLightBuffer, Rotation.Buffer, LightAngle);
    finally
      LightRotationCache.Release;
    end;
    Invalidate;
  end;
end;
{ @end $48B894 }

{ @routine $48B940 TPlanetGI_LoadFromConfigPath }
procedure TPlanetGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if (Block.CountParams('Mask') > 0) or (Block.CountParams('Image') > 0) or (Block.CountParams('ImageLight') > 0) then
    SetImage(Block.GetParam('Mask'), Block.GetParam('Image'), Block.GetParam('ImageLight'));
  if Block.CountParams('SmeMap') > 0 then SurfaceMapOffset := StrToInt(Block.GetParam('SmeMap'));
  if Block.CountParams('AngleLight') > 0 then LightAngle := StrToInt(Block.GetParam('AngleLight'));
end;
{ @end $48B940 }

{ @routine $48BB10 TPlanetGI_LoadFromBlock }
procedure TPlanetGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  SetImage(Block.GetParam('Mask'), Block.GetParam('Image'), Block.GetParam('ImageLight'));
  if Block.CountParams('SmeMap') > 0 then SurfaceMapOffset := StrToInt(Block.GetParam('SmeMap'));
  if Block.CountParams('AngleLight') > 0 then LightAngle := StrToInt(Block.GetParam('AngleLight'));
end;
{ @end $48BB10 }

{ @routine $48BCA0 TPlanetGI_Draw }
procedure TPlanetGI.Draw(ClipRect: TRect);
var Image: TCPalBitmapEC; Palette: TCLightPalEC; Template: TCPlanetTemplEC;
begin
  Image := nil;
  Palette := nil;
  Template := nil;
  try
    Template := AcquireOrCreatePlanetTemplate(TemplateCache);
    Image := AcquireOrCreatePalBitmap(SurfaceImageCache);
    Palette := AcquireOrCreateLightPalette(SurfacePaletteCache);
    if CurrentPixelFormat.TotalChannelBits = 16 then
    begin
      if Image.Bitmap.BytesPerPixel = 2 then
        OKGR_Planet3_DrawAndLightClip_16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Template.TemplateData,
          Image.Bitmap.Pixels, Image.Bitmap.PitchBytes, MapWidthMask, SurfaceMapOffset, RotatedLightBuffer, Palette.PaletteData,
          HitTestBounds.Left + (HitTestBounds.Right - HitTestBounds.Left) div 2,
          HitTestBounds.Top + (HitTestBounds.Bottom - HitTestBounds.Top) div 2, ClipRect)
      else
        OKGR_Planet2_DrawAndLightClip_16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Template.TemplateData,
          Image.Bitmap.Pixels, Image.Bitmap.PitchBytes, MapWidthMask, SurfaceMapOffset, RotatedLightBuffer, Palette.PaletteData,
          HitTestBounds.Left + (HitTestBounds.Right - HitTestBounds.Left) div 2,
          HitTestBounds.Top + (HitTestBounds.Bottom - HitTestBounds.Top) div 2, ClipRect);
    end
    else
    begin
      if Image.Bitmap.BytesPerPixel = 2 then
        OKGR_Planet3_DrawAndLightClip_15(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Template.TemplateData,
          Image.Bitmap.Pixels, Image.Bitmap.PitchBytes, MapWidthMask, SurfaceMapOffset, RotatedLightBuffer, Palette.PaletteData,
          HitTestBounds.Left + (HitTestBounds.Right - HitTestBounds.Left) div 2,
          HitTestBounds.Top + (HitTestBounds.Bottom - HitTestBounds.Top) div 2, ClipRect)
      else
        OKGR_Planet2_DrawAndLightClip_15(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Template.TemplateData,
          Image.Bitmap.Pixels, Image.Bitmap.PitchBytes, MapWidthMask, SurfaceMapOffset, RotatedLightBuffer, Palette.PaletteData,
          HitTestBounds.Left + (HitTestBounds.Right - HitTestBounds.Left) div 2,
          HitTestBounds.Top + (HitTestBounds.Bottom - HitTestBounds.Top) div 2, ClipRect);
    end;
  finally
    if Template <> nil then TemplateCache.Release;
    if Image <> nil then SurfaceImageCache.Release;
    if Palette <> nil then SurfacePaletteCache.Release;
  end;
end;
{ @end $48BCA0 }

{ @routine $48BFB8 TPlanetGI_QueueImageLoad }
procedure TPlanetGI.QueueImageLoad(PendingLoads: TList);
begin
  TemplateCache.QueueLoadIfMissing(PendingLoads);
  SurfaceImageCache.QueueLoadIfMissing(PendingLoads);
  SurfacePaletteCache.QueueLoadIfMissing(PendingLoads);
  LightRotationCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $48BFB8 }

end.

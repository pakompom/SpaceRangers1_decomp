unit GI_RotateImage5;
// Unit bracket (inferred): CODE 0x0047EA4C..0x0047F597; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheHSAI, EC_CacheRotateBuf, GI_MessageLoop, GR_GraphBufPal, GR_GraphBuf, Types;

type
  TRotateImage5GI = class(TObjectGI) // @size $11C
  public
    function HitTestPixel(Point: TPoint): Boolean; // @addr $47F010
    ImageCache: TCHSAIControlEC; // @offset $100
    RotationCache: TCRotateBufControlEC; // @offset $104
    RotatedImage: TGraphBufPalGR; // @offset $108
    RenderedAngle: Byte; // @offset $10C
    RenderedFrameIndex: Cardinal; // @offset $110
    FrameIndex: Cardinal; // @offset $114
    Angle: Byte; // @offset $118
    Alpha: Byte; // @offset $119
    ImageDirty: Boolean; // @offset $11A
    constructor Create(Owner: TObjectGI); // @addr $47EB60
    destructor Destroy; override; // @addr $47EC28
    procedure Clear; override; // @addr $47EC88 @note "Preserves cache keys and image storage."
    procedure SetImage(Path: WideString; ImageSize, Pivot: TPoint); // @addr $47ED1C @note "Replaces size and origin with a centered square enclosing all rotations."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47F068
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47F094
    procedure Draw(ClipRect: TRect); override; // @addr $47F288
    procedure QueueImagePath(PendingLoads: TList; Path: WideString); // @addr $47F4E4 @note "Queues an arbitrary HSAI path; does not change this object's image."
    procedure SetAngle(Value: Byte); // @addr $47ECBC @note "A full turn has 256 steps."
    procedure SetFrameIndex(Value: Cardinal); // @addr $47ECDC @note "Does not validate against the frame count."
    procedure SetAlpha(Value: Byte); // @addr $47ECFC
    procedure AcquireRenderedFrame(var Pixels: Pointer; var Palette: PColorRGBA); // @addr $47F49C
    procedure ReleaseRenderedFrame; // @addr $47F4D8
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $47F0CC
  end;

implementation

// @unit-initialization $47F590
// @unit-finalization $47F560

uses EC_OKGF, SysUtils, Math, EC_Cache, EC_Str, GR_Main, GI_Main, EC_Mem;

{ @routine $47EB60 TRotateImage5GI_Create }
constructor TRotateImage5GI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageDirty := True;
  ImageCache := TCHSAIControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
  RotatedImage := TGraphBufPalGR.Create;
  RenderedAngle := 0;
  RenderedFrameIndex := 0;
  Angle := 0;
  FrameIndex := 0;
  Alpha := 255;
  ImageDirty := True;
end;
{ @end $47EB60 }

{ @routine $47EC28 TRotateImage5GI_Destroy }
destructor TRotateImage5GI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  RotatedImage.Free;
  RotatedImage := nil;
  inherited Destroy;
end;
{ @end $47EC28 }

{ @routine $47EC88 TRotateImage5GI_Clear }
procedure TRotateImage5GI.Clear;
begin
  ImageDirty := True;
  RenderedAngle := 255;
  Angle := 0;
  RenderedFrameIndex := 0;
  FrameIndex := 0;
  Alpha := 255;
  inherited Clear;
end;
{ @end $47EC88 }

{ @routine $47ECBC TRotateImage5GI_SetAngle }
procedure TRotateImage5GI.SetAngle(Value: Byte);
begin
  if Value <> Angle then
  begin
    Angle := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;
{ @end $47ECBC }

{ @routine $47ECDC TRotateImage5GI_SetFrameIndex }
procedure TRotateImage5GI.SetFrameIndex(Value: Cardinal);
begin
  if Value <> FrameIndex then
  begin
    FrameIndex := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;
{ @end $47ECDC }

{ @routine $47ECFC TRotateImage5GI_SetAlpha }
procedure TRotateImage5GI.SetAlpha(Value: Byte);
begin
  if Value <> Alpha then
  begin
    Alpha := Value;
    ImageDirty := True;
    Invalidate;
  end;
end;
{ @end $47ECFC }

{ @routine $47ED1C TRotateImage5GI_SetImage }
procedure TRotateImage5GI.SetImage(Path: WideString; ImageSize, Pivot: TPoint);
var
  Data: TCHSAIEC;
  Radius: Double;
begin
  ImageCache.SetCacheKey(Path);
  Data := AcquireCachedHSAI(ImageCache);
  try
    RotationCache.SetCacheKey(IntToStr(ImageSize.X) + ',' + IntToStr(ImageSize.Y) + ',' +
      IntToStr(Data.Width) + ',' + IntToStr(Data.Height) + ',' + IntToStr(Pivot.X) + ',' + IntToStr(Pivot.Y));
    // Each subtraction of zero below is an explicit native SUB EAX, 0.
    Radius := Sqr(Pivot.X - 0) + Sqr(Pivot.Y - 0);
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Max(Radius, Sqr(Pivot.X - ImageSize.X) + Sqr(Pivot.Y - 0));
    Radius := Max(Radius, Sqr(Pivot.X - 0) + Sqr(Pivot.Y - ImageSize.Y));
    Radius := Floor(Sqrt(Radius) * 2.0 + 2.0);
    SetSize(Classes.Point(Trunc(Radius), Trunc(Radius)));
    SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
    if (RotatedImage.Width <> ClientSize.X) or (RotatedImage.Height <> ClientSize.Y) then
      RotatedImage.AllocateBuffer(ClientSize.X, ClientSize.Y, 256, ClientSize.X);
    ImageDirty := True;
  finally
    ImageCache.Release;
  end;
  Invalidate;
end;
{ @end $47ED1C }

{ @routine $47F010 TRotateImage5GI_HitTestPixel }
function TRotateImage5GI.HitTestPixel(Point: TPoint): Boolean;
begin
  Result := False;
  if ContainsPoint(Point) then
    Result := RotatedImage.GetPaletteColor(RotatedImage.GetPixelIndex(
      Point.X - HitTestBounds.Left, Point.Y - HitTestBounds.Top)).A > 0;
end;
{ @end $47F010 }

{ @routine $47F068 TRotateImage5GI_LoadFromConfigPath }
procedure TRotateImage5GI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $47F068 }

{ @routine $47F094 TRotateImage5GI_LoadFromBlock }
procedure TRotateImage5GI.LoadFromBlock(Block: TBlockParEC);
begin
  RenderedAngle := 255;
  Angle := 0;
  Alpha := 255;
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
  ImageDirty := True;
end;
{ @end $47F094 }

{ @routine $47F0CC TRotateImage5GI_LoadImageProperties }
procedure TRotateImage5GI.LoadImageProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then
    if Block.CountParams('Size') > 0 then
      if Block.CountParams('Sme') > 0 then
        SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')), GetPointGI(Block.GetParam('Sme')));
  if Block.CountParams('Angle') > 0 then SetAngle(StrToInt(Block.GetParam('Angle')));
  if Block.CountParams('Trans') > 0 then SetAlpha(StrToInt(Block.GetParam('Trans')));
end;
{ @end $47F0CC }

{ @routine $47F288 TRotateImage5GI_Draw }
procedure TRotateImage5GI.Draw(ClipRect: TRect);
var
  Data: TCHSAIEC;
  Rotation: TCRotateBufEC;
begin
  begin
    if (RenderedAngle <> Angle) or (ImageDirty = True) or (FrameIndex <> RenderedFrameIndex) then
    begin
      ImageDirty := False;
      RenderedAngle := Angle;
      RenderedFrameIndex := FrameIndex;
      Data := nil;
      Rotation := nil;
      try
        Data := AcquireCachedHSAI(ImageCache);
        Rotation := AcquireOrCreateRotateBuf(RotationCache);
        RotatedImage.FillPixels(ReadByteEC(Data.GetFrameIndexPlane(RenderedFrameIndex)));
        RotatedImage.SetPalette(Data.GetFramePalette(RenderedFrameIndex), 256);
        OKGR_RotateBuf_Draw_BYTE(RotatedImage.Pixels, RotatedImage.PitchBytes,
          Data.GetFrameIndexPlane(RenderedFrameIndex), Data.GetSourcePitchBytes,
          OriginPoint.X, OriginPoint.Y, Angle, Rotation.Buffer);
        if Alpha <> 255 then
          OKGR_Light_BYTE(AddPointerOffset(RotatedImage.Palette, 3), 4, 1024, 256, 1, Alpha);
      finally
        if Data <> nil then ImageCache.Release;
        if Rotation <> nil then RotationCache.Release;
      end;
    end;
    DrawPaletteAlphaBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      HitTestBounds.Left, HitTestBounds.Top, RotatedImage, ClipRect);
  end;
end;
{ @end $47F288 }

{ @routine $47F49C TRotateImage5GI_AcquireRenderedFrame }
procedure TRotateImage5GI.AcquireRenderedFrame(var Pixels: Pointer; var Palette: PColorRGBA);
var Data: TCHSAIEC;
begin
  Data := AcquireCachedHSAI(ImageCache);
  Pixels := Data.GetFrameIndexPlane(RenderedFrameIndex);
  Palette := Data.GetFramePalette(RenderedFrameIndex);
end;
{ @end $47F49C }

{ @routine $47F4D8 TRotateImage5GI_ReleaseRenderedFrame }
procedure TRotateImage5GI.ReleaseRenderedFrame;
begin
  ImageCache.Release;
end;
{ @end $47F4D8 }

{ @routine $47F4E4 TRotateImage5GI_QueueImagePath }
procedure TRotateImage5GI.QueueImagePath(PendingLoads: TList; Path: WideString);
var Control: TCHSAIControlEC;
begin
  Control := TCHSAIControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(Path);
  Control.QueueLoadIfMissing(PendingLoads);
  Control.Free;
end;
{ @end $47F4E4 }

end.

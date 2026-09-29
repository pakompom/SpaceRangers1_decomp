unit GI_RotateImage;
// Unit bracket (inferred): CODE 0x0047D448..0x0047DCC3; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, EC_CacheRotateBuf, GI_MessageLoop, Types;

type
  TRotateImageGI = class(TObjectGI) // @size $10C
  public
    ImageCache: TCBitmapControlEC; // @offset $100
    RotationCache: TCRotateBufControlEC; // @offset $104
    Angle: Byte; // @offset $108

    constructor Create(Owner: TObjectGI); // @addr $47D55C
    destructor Destroy; override; // @addr $47D5E0
    procedure Clear; override; // @addr $47D62C @note "Preserves both cache keys."
    procedure SetAngle(Value: Byte); // @addr $47D63C @note "A full turn has 256 steps."
    procedure UpdateHitTestBounds; override; // @addr $47D684 @note "Leaves bounds unchanged when the rotation cache key is empty."
    function GetLocalBounds: TRect; override; // @addr $47D718 @note "Leaves Result unwritten when the rotation cache key is empty."
    procedure SetImage(Path: WideString; ImageSize: TPoint); // @addr $47D7A4 @note "Uses the current Origin as the rotation pivot."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47D92C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47DA5C
    procedure Draw(ClipRect: TRect); override; // @addr $47DB6C
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $47DC68
  end;

implementation

// @unit-initialization $47DCBC
// @unit-finalization $47DC8C

uses EC_OKGF, SysUtils, GR_Main, GI_Main;

{ @routine $47D55C TRotateImageGI_Create }
constructor TRotateImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  RotationCache := TCRotateBufControlEC.Create;
  GlobalCache.ResetControl(RotationCache);
end;
{ @end $47D55C }

{ @routine $47D5E0 TRotateImageGI_Destroy }
destructor TRotateImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  RotationCache.Free;
  RotationCache := nil;
  inherited Destroy;
end;
{ @end $47D5E0 }

{ @routine $47D62C TRotateImageGI_Clear }
procedure TRotateImageGI.Clear;
begin
  Angle := 0;
  inherited Clear;
end;
{ @end $47D62C }

{ @routine $47D63C TRotateImageGI_SetAngle }
procedure TRotateImageGI.SetAngle(Value: Byte);
begin
  if Value = Angle then Exit;
  if not Active then Angle := Value
  else
  begin
    Invalidate;
    Angle := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $47D63C }

{ @routine $47D684 TRotateImageGI_UpdateHitTestBounds }
procedure TRotateImageGI.UpdateHitTestBounds;
var Rotation: TCRotateBufEC;
begin
  if RotationCache.HasEmptyCacheKey then Exit;
  Rotation := AcquireOrCreateRotateBuf(RotationCache);
  try
    OKGR_RotateBuf_Size(AbsolutePosition.X, AbsolutePosition.Y, Angle, Rotation.Buffer, HitTestBounds);
    Inc(HitTestBounds.Right);
    Inc(HitTestBounds.Bottom);
  finally
    RotationCache.Release;
  end;
end;
{ @end $47D684 }

{ @routine $47D718 TRotateImageGI_GetLocalBounds }
function TRotateImageGI.GetLocalBounds: TRect;
var Rotation: TCRotateBufEC;
begin
  if RotationCache.HasEmptyCacheKey then Exit;
  Rotation := AcquireOrCreateRotateBuf(RotationCache);
  try
    OKGR_RotateBuf_Size(LocalPosition.X, LocalPosition.Y, Angle, Rotation.Buffer, Result);
    Inc(Result.Right);
    Inc(Result.Bottom);
  finally
    RotationCache.Release;
  end;
end;
{ @end $47D718 }

{ @routine $47D7A4 TRotateImageGI_SetImage }
procedure TRotateImageGI.SetImage(Path: WideString; ImageSize: TPoint);
var Bitmap: TCBitmapEC;
begin
  ImageCache.SetCacheKey(Path);
  Bitmap := AcquireOrCreateBitmap(ImageCache);
  try
    RotationCache.SetCacheKey(IntToStr(ImageSize.X) + ',' + IntToStr(ImageSize.Y) + ',' + IntToStr(Cardinal(Bitmap.Bitmap.Width)) + ',' +
      IntToStr(Cardinal(Bitmap.Bitmap.Height)) + ',' + IntToStr(OriginPoint.X) + ',' + IntToStr(OriginPoint.Y));
    SetSize(ImageSize);
  finally
    ImageCache.Release;
  end;
end;
{ @end $47D7A4 }

{ @routine $47D92C TRotateImageGI_LoadFromConfigPath }
procedure TRotateImageGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if (Block.CountParams('Image') > 0) and (Block.CountParams('Size') > 0) then
    SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Angle') > 0 then Angle := StrToInt(Block.GetParam('Angle'));
end;
{ @end $47D92C }

{ @routine $47DA5C TRotateImageGI_LoadFromBlock }
procedure TRotateImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  Angle := 1;
  SetAngle(0);
  SetImage(Block.GetParam('Image'), GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Angle') > 0 then Angle := StrToInt(Block.GetParam('Angle'));
end;
{ @end $47DA5C }

{ @routine $47DB6C TRotateImageGI_Draw }
procedure TRotateImageGI.Draw(ClipRect: TRect);
var Bitmap: TCBitmapEC; Rotation: TCRotateBufEC; Rect: TRect;
begin
  Bitmap := nil;
  Rotation := nil;
  try
    Bitmap := AcquireOrCreateBitmap(ImageCache);
    Rotation := AcquireOrCreateRotateBuf(RotationCache);
    Rect.Left := ClipRect.Left;
    Rect.Top := ClipRect.Top;
    Rect.Right := ClipRect.Right - 1;
    Rect.Bottom := ClipRect.Bottom - 1;
    OKGR_RotateBuf_DrawTransClip_WORD(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Bitmap.Bitmap.Pixels,
      Bitmap.Bitmap.PitchBytes, AbsolutePosition.X, AbsolutePosition.Y, Angle, Rotation.Buffer, Rect);
  finally
    if Bitmap <> nil then ImageCache.Release;
    if Rotation <> nil then RotationCache.Release;
  end;
end;
{ @end $47DB6C }

{ @routine $47DC68 TRotateImageGI_QueueImageLoad }
procedure TRotateImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
  RotationCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $47DC68 }

end.

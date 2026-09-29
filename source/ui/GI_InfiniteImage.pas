unit GI_InfiniteImage;
// Unit bracket (inferred): CODE 0x0047F598..0x0047FA2F; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, GI_MessageLoop, Types;

type
  TInfiniteImageGI = class(TObjectGI) // @size $104
  public
    ImageCache: TCBitmapControlEC; // @offset $100

    constructor Create(Owner: TObjectGI); // @addr $47F6B0
    destructor Destroy; override; // @addr $47F710
    procedure SetImagePath(Path: WideString); // @addr $47F748 @note "Resets size to two billion pixels on each axis and centers the origin."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47F7DC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47F808
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $47F824
    procedure Draw(ClipRect: TRect); override; // @addr $47F8E4 @note "The hardware drawing path is unimplemented."
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $47F9EC
  end;

implementation

// @unit-initialization $47FA28
// @unit-finalization $47F9F8

uses EC_OKGF, Math, GR_Main, GI_Main, EC_Cache;
{ @routine $47F6B0 TInfiniteImageGI_Create }
constructor TInfiniteImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
end;
{ @end $47F6B0 }

{ @routine $47F710 TInfiniteImageGI_Destroy }
destructor TInfiniteImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $47F710 }

{ @routine $47F748 TInfiniteImageGI_SetImagePath }
procedure TInfiniteImageGI.SetImagePath(Path: WideString);
begin
  SetSize(Classes.Point(2000000000, 2000000000));
  SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
  ImageCache.SetCacheKey(Path);
end;
{ @end $47F748 }

{ @routine $47F7DC TInfiniteImageGI_LoadFromConfigPath }
procedure TInfiniteImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $47F7DC }

{ @routine $47F808 TInfiniteImageGI_LoadFromBlock }
procedure TInfiniteImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;
{ @end $47F808 }

{ @routine $47F824 TInfiniteImageGI_LoadImageProperties }
procedure TInfiniteImageGI.LoadImageProperties(Block: TBlockParEC);
begin
  SetSize(Classes.Point(2000000000, 2000000000));
  SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y div 2));
  if Block.CountParams('Image') > 0 then SetImagePath(Block.GetParam('Image'));
end;
{ @end $47F824 }

{ @routine $47F8E4 TInfiniteImageGI_Draw }
procedure TInfiniteImageGI.Draw(ClipRect: TRect);
var
  Start: TPoint;
  Image: TCBitmapEC;
  Width, Height, X, Y: Integer;
begin
  Image := AcquireOrCreateBitmap(ImageCache);
  try
    Width := Image.Bitmap.Width;
    Height := Image.Bitmap.Height;
    Start.X := Floor((ClipRect.Left - AbsolutePosition.X) / Width) * Width + AbsolutePosition.X;
    Start.Y := Floor((ClipRect.Top - AbsolutePosition.Y) / Height) * Height + AbsolutePosition.Y;
    Y := Start.Y;
    while Y < ClipRect.Bottom do
    begin
      X := Start.X;
      while X < ClipRect.Right do
      begin
        CopyGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
          X, Y, Image.Bitmap, ClipRect, False, False);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  finally
    ImageCache.Release;
  end;
end;
{ @end $47F8E4 }

{ @routine $47F9EC TInfiniteImageGI_QueueImageLoad }
procedure TInfiniteImageGI.QueueImageLoad(PendingLoads: TList);
begin
  ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $47F9EC }

end.

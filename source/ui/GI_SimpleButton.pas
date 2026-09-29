unit GI_SimpleButton;
// Unit bracket (inferred): CODE 0x00482A44..0x0048307F; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, GI_MessageLoop, Types;

type
  TSimpleButtonGI = class(TObjectGI) // @size $10C
  public
    CurrentImage: TCBitmapControlEC; // @offset $100
    NormalImage: TCBitmapControlEC; // @offset $104
    ActiveImage: TCBitmapControlEC; // @offset $108
    constructor Create(Owner: TObjectGI); // @addr $482B58
    destructor Destroy; override; // @addr $482BDC
    procedure Clear; override; // @addr $482C28
    procedure OnMouseEnter; override; // @addr $482C30
    procedure OnMouseLeave; override; // @addr $482C54
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $482C78
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $482CAC
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $482CE0
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $482E38
    procedure Draw(ClipRect: TRect); override; // @addr $482F70
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $483024
  end;

implementation

// @unit-initialization $483078
// @unit-finalization $483048

uses EC_OKGF, GR_Main, GI_Main;

{ @routine $482B58 TSimpleButtonGI_Create }
constructor TSimpleButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  NormalImage := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(NormalImage);
  ActiveImage := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ActiveImage);
end;
{ @end $482B58 }

{ @routine $482BDC TSimpleButtonGI_Destroy }
destructor TSimpleButtonGI.Destroy;
begin
  NormalImage.Free;
  NormalImage := nil;
  ActiveImage.Free;
  ActiveImage := nil;
  inherited Destroy;
end;
{ @end $482BDC }

{ @routine $482C28 TSimpleButtonGI_Clear }
procedure TSimpleButtonGI.Clear;
begin
  inherited Clear;
end;
{ @end $482C28 }

{ @routine $482C30 TSimpleButtonGI_OnMouseEnter }
procedure TSimpleButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  CurrentImage := ActiveImage;
  Invalidate;
end;
{ @end $482C30 }

{ @routine $482C54 TSimpleButtonGI_OnMouseLeave }
procedure TSimpleButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  CurrentImage := NormalImage;
  Invalidate;
end;
{ @end $482C54 }

{ @routine $482C78 TSimpleButtonGI_ProcessLeftButtonDown }
procedure TSimpleButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  DispatchNamedEvent(1, Point.X, Point.Y);
end;
{ @end $482C78 }

{ @routine $482CAC TSimpleButtonGI_ProcessLeftButtonUp }
procedure TSimpleButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  DispatchNamedEvent(2, Point.X, Point.Y);
end;
{ @end $482CAC }

{ @routine $482CE0 TSimpleButtonGI_LoadFromConfigPath }
procedure TSimpleButtonGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Bitmap: TCBitmapEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Image') > 0 then
  begin
    NormalImage.SetCacheKey(Block.GetParam('Image'));
    Bitmap := AcquireOrCreateBitmap(NormalImage);
    try
      SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
    finally
      NormalImage.Release;
    end;
  end;
  if Block.CountParams('ImageActive') > 0 then
    ActiveImage.SetCacheKey(Block.GetParam('ImageActive'));
end;
{ @end $482CE0 }

{ @routine $482E38 TSimpleButtonGI_LoadFromBlock }
procedure TSimpleButtonGI.LoadFromBlock(Block: TBlockParEC);
var Bitmap: TCBitmapEC;
begin
  inherited LoadFromBlock(Block);
    NormalImage.SetCacheKey(Block.GetParam('Image'));
    Bitmap := AcquireOrCreateBitmap(NormalImage);
    try
      SetSize(Classes.Point(Bitmap.Bitmap.Width, Bitmap.Bitmap.Height));
    finally
      NormalImage.Release;
    end;
    ActiveImage.SetCacheKey(Block.GetParam('ImageActive'));
  CurrentImage := NormalImage;
end;
{ @end $482E38 }

{ @routine $482F70 TSimpleButtonGI_Draw }
procedure TSimpleButtonGI.Draw(ClipRect: TRect);
var Bitmap: TCBitmapEC;
begin
  if CurrentImage <> nil then
  begin
    Bitmap := AcquireOrCreateBitmap(CurrentImage);
    try
      OKGR_Copy_XY_XY_WORD(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, ClipRect.Left, ClipRect.Top,
        Bitmap.Bitmap.Pixels, Bitmap.Bitmap.PitchBytes, ClipRect.Left - HitTestBounds.Left, ClipRect.Top - HitTestBounds.Top,
        ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
    finally
      CurrentImage.Release;
    end;
  end;
end;
{ @end $482F70 }

{ @routine $483024 TSimpleButtonGI_QueueImageLoad }
procedure TSimpleButtonGI.QueueImageLoad(PendingLoads: TList);
begin
  NormalImage.QueueLoadIfMissing(PendingLoads);
  ActiveImage.QueueLoadIfMissing(PendingLoads);
end;
{ @end $483024 }

end.

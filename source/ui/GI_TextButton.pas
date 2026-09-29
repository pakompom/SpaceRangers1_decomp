unit GI_TextButton;
// Unit bracket (inferred): CODE 0x00483080..0x004845F3; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, EC_CacheFont, GI_MessageLoop, Types;

type
  TTextButtonGI = class(TObjectGI) // @size $138
  public
    FontCache: TCFontControlEC; // @offset $100
    ImageCache: TCBitmapControlEC; // @offset $104
    Kind: Integer; // @offset $108
    Caption: WideString; // @offset $10C
    CaptionColor: Cardinal; // @offset $110
    CaptionActiveColor: Cardinal; // @offset $114
    BorderLightColor: Cardinal; // @offset $118
    BorderDarkColor: Cardinal; // @offset $11C
    Hover: Boolean; // @offset $120
    Down: Boolean; // @offset $121
    DownCallback: TObjectNotifyEventGI; // @offset $128
    UpCallback: TObjectNotifyEventGI; // @offset $130
    constructor Create(Owner: TObjectGI); // @addr $4831A4
    destructor Destroy; override; // @addr $483294
    procedure Clear; override; // @addr $4832E0
    procedure OnActivate; override; // @addr $483364
    procedure OnDeactivate; override; // @addr $4833A8
    procedure OnMouseEnter; override; // @addr $4833CC
    procedure OnMouseLeave; override; // @addr $4833F8
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $483458
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $483548
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4835C8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $483BF8
    procedure Draw(ClipRect: TRect); override; // @addr $484218
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $484594
  end;

implementation

// @unit-initialization $4845EC
// @unit-finalization $4845BC

uses EC_OKGF, SysUtils, EC_Str, GR_Main, GI_Main;

{ @routine $4831A4 TTextButtonGI_Create }
constructor TTextButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  ImageCache := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
  CaptionColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  Kind := 0;
end;
{ @end $4831A4 }

{ @routine $483294 TTextButtonGI_Destroy }
destructor TTextButtonGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $483294 }

{ @routine $4832E0 TTextButtonGI_Clear }
procedure TTextButtonGI.Clear;
begin
  inherited Clear;
  CaptionColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  Caption := '';
  MouseBlocking := True;
end;
{ @end $4832E0 }

{ @routine $483364 TTextButtonGI_OnActivate }
procedure TTextButtonGI.OnActivate;
begin
  inherited OnActivate;
  if HitTestCursor then Hover := True else Hover := False;
  if Kind = 0 then Down := False;
  Invalidate;
end;
{ @end $483364 }

{ @routine $4833A8 TTextButtonGI_OnDeactivate }
procedure TTextButtonGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Hover := False;
  Down := False;
  Invalidate;
end;
{ @end $4833A8 }

{ @routine $4833CC TTextButtonGI_OnMouseEnter }
procedure TTextButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if not IsOccludedAtPoint(AbsolutePosition) then
  begin
    Hover := True;
    Invalidate;
  end;
end;
{ @end $4833CC }

{ @routine $4833F8 TTextButtonGI_OnMouseLeave }
procedure TTextButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if Kind = 0 then
  begin
    if Down then
    begin
      Down := False;
      DispatchNamedEvent(2, 0, 0);
      if Assigned(UpCallback) then UpCallback(Self);
    end;
  end;
  Hover := False;
  Invalidate;
end;
{ @end $4833F8 }

{ @routine $483458 TTextButtonGI_ProcessLeftButtonDown }
procedure TTextButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if IsOccludedAtPoint(Point) then Exit;
  if Kind = 0 then
  begin
    Down := True;
    DispatchNamedEvent(1, Point.X, Point.Y);
    if Assigned(DownCallback) then DownCallback(Self);
  end else
  begin
    if Down then
    begin
      Down := False;
      DispatchNamedEvent(2, Point.X, Point.Y);
      if Assigned(UpCallback) then UpCallback(Self);
    end else
    begin
      Down := True;
      DispatchNamedEvent(1, Point.X, Point.Y);
      if Assigned(DownCallback) then DownCallback(Self);
    end;
  end;
  Invalidate;
end;
{ @end $483458 }

{ @routine $483548 TTextButtonGI_ProcessLeftButtonUp }
procedure TTextButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if IsOccludedAtPoint(Point) then Exit;
  if Kind = 0 then
  begin
    Down := False;
    Invalidate;
    DispatchNamedEvent(2, Point.X, Point.Y);
    if Assigned(UpCallback) then
      if MessageLoop.ConsumeTimerTickChange then UpCallback(Self);
  end;
end;
{ @end $483548 }

{ @routine $4835C8 TTextButtonGI_LoadFromConfigPath }
procedure TTextButtonGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString; Red, Green, Blue: Byte;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Caption := Block.GetParam('Caption');
    if LanguageDataConfig.CountParamsByPath(Caption) > 0 then
      Caption := LanguageDataConfig.GetParamByPath(Caption);
  end;
  if Block.CountParams('Image') > 0 then ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('CaptionColor') > 0 then
  begin
    Text := Block.GetParam('CaptionColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CaptionActiveColor') > 0 then
  begin
    Text := Block.GetParam('CaptionActiveColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    Text := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    Text := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Normal' then Kind := 0 else Kind := 1;
  end;
end;
{ @end $4835C8 }

{ @routine $483BF8 TTextButtonGI_LoadFromBlock }
procedure TTextButtonGI.LoadFromBlock(Block: TBlockParEC);
var Text: WideString; Red, Green, Blue: Byte;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Font') > 0 then FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Caption := Block.GetParam('Caption');
    if LanguageDataConfig.CountParamsByPath(Caption) > 0 then
      Caption := LanguageDataConfig.GetParamByPath(Caption);
  end;
  if Block.CountParams('Image') > 0 then ImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('CaptionColor') > 0 then
  begin
    Text := Block.GetParam('CaptionColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CaptionActiveColor') > 0 then
  begin
    Text := Block.GetParam('CaptionActiveColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    CaptionActiveColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    Text := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    Text := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Normal' then Kind := 0 else Kind := 1;
  end;
end;
{ @end $483BF8 }

{ @routine $484218 TTextButtonGI_Draw }
procedure TTextButtonGI.Draw(ClipRect: TRect);
var Font: TCFontEC; Bitmap: TCBitmapEC; Bounds: TRect;
begin
  Font := nil;
  Bitmap := nil;
  if FontCache <> nil then
  begin
    try
      Font := AcquireCachedFont(FontCache);
      if (ImageCache <> nil) and (ImageCache.CacheKey <> '') then Bitmap := AcquireOrCreateBitmap(ImageCache);
      Bounds := Font.MeasureTaggedTextBounds(Caption, 0, 0);
      if Bitmap <> nil then
        OKGR_Copy_XY_XY_WORD(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, ClipRect.Left, ClipRect.Top,
          Bitmap.Bitmap.Pixels, Bitmap.Bitmap.PitchBytes, ClipRect.Left - HitTestBounds.Left, ClipRect.Top - HitTestBounds.Top,
          ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
      if Hover = True then Font.DefaultColor := CaptionActiveColor else Font.DefaultColor := CaptionColor;
      Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
        (HitTestBounds.Left + HitTestBounds.Right) div 2 - (Bounds.Right - Bounds.Left) div 2,
        (HitTestBounds.Top + HitTestBounds.Bottom) div 2 - (Bounds.Bottom - Bounds.Top) div 2 - Bounds.Top, Caption, ClipRect);
      if not Down then
      begin
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, BorderLightColor, ClipRect);
        ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Bottom - HitTestBounds.Top, BorderLightColor, ClipRect);
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Right - HitTestBounds.Left - 1), BorderDarkColor, ClipRect);
        ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Bottom - HitTestBounds.Top - 1), BorderDarkColor, ClipRect);
      end else
      begin
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left - 1, BorderDarkColor, ClipRect);
        ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Bottom - HitTestBounds.Top - 1, BorderDarkColor, ClipRect);
        ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Right - HitTestBounds.Left), BorderLightColor, ClipRect);
        ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Bottom - HitTestBounds.Top), BorderLightColor, ClipRect);
      end;
    finally
      if Font <> nil then FontCache.Release;
      if Bitmap <> nil then ImageCache.Release;
    end;
  end;
  inherited Draw(ClipRect);
end;
{ @end $484218 }

{ @routine $484594 TTextButtonGI_QueueImageLoad }
procedure TTextButtonGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
  if ImageCache <> nil then ImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $484594 }

end.

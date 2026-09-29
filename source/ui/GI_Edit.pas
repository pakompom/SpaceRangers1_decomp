unit GI_Edit;
// Unit bracket (inferred): CODE 0x00486D30..0x00488727; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheBitmap, EC_CacheFont, GI_Main, GI_MessageLoop, Types;

type
  TEditAcceptCharEventGI = function(Sender: TObjectGI; Character: WideChar): Boolean of object;

  TEditGI = class(TObjectGI) // @size $144
  public
    FontCache: TCFontControlEC; // @offset $100
    BackgroundCache: TCBitmapControlEC; // @offset $104
    Text: WideString; // @offset $108
    TextColor: Cardinal; // @offset $10C
    CaretColor: Cardinal; // @offset $110
    BorderEnabled: Boolean; // @offset $114
    BorderLightColor: Cardinal; // @offset $118
    BorderDarkColor: Cardinal; // @offset $11C
    MaxLength: Integer; // @offset $120
    HasFocus: Boolean; // @offset $124
    CaretPosition: Integer; // @offset $128
    TextAlignX: TTextAlignXGI; // @offset $12C
    ChangedCallback: TObjectNotifyEventGI; // @offset $130
    FocusLostCallback: TObjectNotifyEventGI; // @offset $138
    ClearFocusOnEnter: Boolean; // @offset $140

    constructor Create(Owner: TObjectGI); // @addr $486E50
    destructor Destroy; override; // @addr $486F40
    procedure Clear; override; // @addr $486F8C
    procedure SetFontName(FontName: WideString); // @addr $48701C
    procedure SetText(Value: WideString); // @addr $487078 @note "Resets CaretPosition on change; does not clamp to MaxLength or invoke ChangedCallback."
    function HasGlyph(Character: WideChar): Boolean; // @addr $4870EC
    procedure SetTextAlignX(Value: TTextAlignXGI); // @addr $48714C @note "Only Left and Center are accepted; other values raise."
    procedure SetCaretPosition(Value: Integer); // @addr $4871B4 @note "Clamps to 0..Length(Text)."
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $487200
    procedure OnCaretBlink; override; // @addr $487524
    procedure OnFocusGained; override; // @addr $487230
    procedure OnFocusLost; override; // @addr $487260
    procedure ProcessKeyDown(Key: Integer); override; // @addr $487298
    procedure ProcessCharacter(Character: WideChar); override; // @addr $48745C @note "Requires a font glyph, acceptance by the optional callback, and length below MaxLength."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $487530
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $487C30
    procedure Draw(ClipRect: TRect); override; // @addr $488310
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $4886C8
  end;

implementation

// @unit-initialization $488720
// @unit-finalization $4886F0

uses EC_OKGF, SysUtils, Windows, EC_Cache, GR_Main, GR_GraphBuf, EC_Str;

{ @routine $486E50 TEditGI_Create }
constructor TEditGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  BackgroundCache := nil;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  CaretColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  BorderEnabled := False;
  TextAlignX := taxLeft;
  MaxLength := 256;
  ClearFocusOnEnter := True;
end;
{ @end $486E50 }

{ @routine $486F40 TEditGI_Destroy }
destructor TEditGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  BackgroundCache.Free;
  BackgroundCache := nil;
  inherited Destroy;
end;
{ @end $486F40 }

{ @routine $486F8C TEditGI_Clear }
procedure TEditGI.Clear;
begin
  inherited Clear;
  HasFocus := False;
  MaxLength := 256;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  CaretColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
  Text := '';
end;
{ @end $486F8C }

{ @routine $48701C TEditGI_SetFontName }
procedure TEditGI.SetFontName(FontName: WideString);
begin
  FontCache.SetCacheKey(FontName);
  Invalidate;
end;
{ @end $48701C }

{ @routine $487078 TEditGI_SetText }
procedure TEditGI.SetText(Value: WideString);
begin
  if Text <> Value then
  begin
    Text := Value;
    CaretPosition := 0;
    Invalidate;
  end;
end;
{ @end $487078 }

{ @routine $4870EC TEditGI_HasGlyph }
function TEditGI.HasGlyph(Character: WideChar): Boolean;
var Font: TCFontEC;
begin
  try
    Font := AcquireCachedFont(FontCache);
    Result := Font.HasGlyph(Character);
  finally
    FontCache.Release;
  end;
end;
{ @end $4870EC }

{ @routine $48714C TEditGI_SetTextAlignX }
procedure TEditGI.SetTextAlignX(Value: TTextAlignXGI);
begin
  if (Value <> taxLeft) and (Value <> taxCenter) then raise Exception.Create('Error TEditGI. This align not support.');
  if TextAlignX <> Value then
  begin
    TextAlignX := Value;
    Invalidate;
  end;
end;
{ @end $48714C }

{ @routine $4871B4 TEditGI_SetCaretPosition }
procedure TEditGI.SetCaretPosition(Value: Integer);
begin
  if Value > Length(Text) then CaretPosition := Length(Text)
  else if Value < 0 then CaretPosition := 0
  else CaretPosition := Value;
  Invalidate;
end;
{ @end $4871B4 }

{ @routine $487200 TEditGI_ProcessLeftButtonDown }
procedure TEditGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Active = True then MessageLoop.SetFocusedControl(Self);
end;
{ @end $487200 }

{ @routine $487230 TEditGI_OnFocusGained }
procedure TEditGI.OnFocusGained;
begin
  inherited OnFocusGained;
  HasFocus := True;
  CaretPosition := Length(Text);
  Invalidate;
end;
{ @end $487230 }

{ @routine $487260 TEditGI_OnFocusLost }
procedure TEditGI.OnFocusLost;
begin
  inherited OnFocusLost;
  HasFocus := False;
  if Assigned(FocusLostCallback) then FocusLostCallback(Self);
  Invalidate;
end;
{ @end $487260 }

{ @routine $487298 TEditGI_ProcessKeyDown }
procedure TEditGI.ProcessKeyDown(Key: Integer);
var I, N: Integer;
begin
  if Key = VK_BACK then
  begin
    if CaretPosition > 0 then
    begin
      N := Length(Text);
      I := CaretPosition;
      while I < N do begin Text[I] := Text[I + 1]; Inc(I); end;
      SetLength(Text, N - 1);
      Dec(CaretPosition);
      Invalidate;
      DispatchNamedEvent(4, 0, 0);
      if Assigned(ChangedCallback) then ChangedCallback(Self);
    end;
  end
  else if Key = VK_DELETE then
  begin
    N := Length(Text);
    if CaretPosition < N then
    begin
      I := CaretPosition + 1;
      while I < N do begin Text[I] := Text[I + 1]; Inc(I); end;
      SetLength(Text, N - 1);
      Invalidate;
      DispatchNamedEvent(4, 0, 0);
      if Assigned(ChangedCallback) then ChangedCallback(Self);
    end;
  end
  else if Key = VK_LEFT then
  begin
    if CaretPosition > 0 then begin Dec(CaretPosition); Invalidate; end;
  end
  else if Key = VK_RIGHT then
  begin
    if CaretPosition < Length(Text) then begin Inc(CaretPosition); Invalidate; end;
  end
  else if Key = VK_HOME then begin CaretPosition := 0; Invalidate; end
  else if Key = VK_END then begin CaretPosition := Length(Text); Invalidate; end
  else if (Key = VK_RETURN) and ClearFocusOnEnter then MessageLoop.SetFocusedControl(nil);
end;
{ @end $487298 }

{ @routine $48745C TEditGI_ProcessCharacter }
procedure TEditGI.ProcessCharacter(Character: WideChar);
var I, N: Integer;
begin
  inherited ProcessCharacter(Character);
  if (Character <> '<') and (Character <> '>') then
    if HasGlyph(Character) then
    begin
      N := Length(Text);
      if N < MaxLength then
      begin
        SetLength(Text, N + 1);
        I := N;
        while I >= CaretPosition do
        begin
          Text[I + 1] := Text[I];
          Dec(I);
        end;
        Text[CaretPosition + 1] := Character;
        Inc(CaretPosition);
        Invalidate;
        DispatchNamedEvent(4, 0, 0);
        if Assigned(ChangedCallback) then ChangedCallback(Self);
      end;
    end;
end;
{ @end $48745C }

{ @routine $487524 TEditGI_OnCaretBlink }
procedure TEditGI.OnCaretBlink;
begin
  Invalidate;
end;
{ @end $487524 }

{ @routine $487530 TEditGI_LoadFromConfigPath }
procedure TEditGI.LoadFromConfigPath(const Path: WideString);
var
  Block: TBlockParEC;
  ColorText: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Text') > 0 then
  begin
    Text := Block.GetParam('Text');
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then Text := LanguageDataConfig.GetParamByPath(Text);
  end;
  if Block.CountParams('Image') > 0 then
  begin
    BackgroundCache := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(BackgroundCache);
    BackgroundCache.SetCacheKey(Block.GetParam('Image'));
  end;
  if Block.CountParams('TextColor') > 0 then
  begin
    ColorText := Block.GetParam('TextColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    TextColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Border') > 0 then
    if Block.GetParam('Border') = 'True' then BorderEnabled := True else BorderEnabled := False;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
    BorderDarkColor := BorderLightColor;
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CursorColor') > 0 then
  begin
    ColorText := Block.GetParam('CursorColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    CaretColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('MaxLen') > 0 then MaxLength := StrToInt(Block.GetParam('MaxLen'));
  if Block.CountParams('AlignX') > 0 then SetTextAlignX(ParseTextAlignXName(TrimWideString(Block.GetParam('AlignX'))));
end;
{ @end $487530 }

{ @routine $487C30 TEditGI_LoadFromBlock }
procedure TEditGI.LoadFromBlock(Block: TBlockParEC);
var
  ColorText: WideString;
  Red, Green, Blue: Byte;
begin
  inherited LoadFromBlock(Block);
  FontCache.SetCacheKey(Block.GetParam('Font'));
  if Block.CountParams('Text') > 0 then
  begin
    Text := Block.GetParam('Text');
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then Text := LanguageDataConfig.GetParamByPath(Text);
  end;
  if Block.CountParams('Image') > 0 then
  begin
    BackgroundCache := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(BackgroundCache);
    BackgroundCache.SetCacheKey(Block.GetParam('Image'));
  end;
  if Block.CountParams('TextColor') > 0 then
  begin
    ColorText := Block.GetParam('TextColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    TextColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('Border') > 0 then
    if Block.GetParam('Border') = 'True' then BorderEnabled := True else BorderEnabled := False;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderLightColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderLightColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
    BorderDarkColor := BorderLightColor;
  end;
  if Block.CountParams('BorderDarkColor') > 0 then
  begin
    ColorText := Block.GetParam('BorderDarkColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    BorderDarkColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('CursorColor') > 0 then
  begin
    ColorText := Block.GetParam('CursorColor');
    Red := StrToInt(ExtractDelimitedPartW(ColorText, 0, ','));
    Green := StrToInt(ExtractDelimitedPartW(ColorText, 1, ','));
    Blue := StrToInt(ExtractDelimitedPartW(ColorText, 2, ','));
    CaretColor := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
  end;
  if Block.CountParams('MaxLen') > 0 then MaxLength := StrToInt(Block.GetParam('MaxLen'));
  if Block.CountParams('AlignX') > 0 then SetTextAlignX(ParseTextAlignXName(TrimWideString(Block.GetParam('AlignX'))));
end;
{ @end $487C30 }

{ @routine $488310 TEditGI_Draw }
procedure TEditGI.Draw(ClipRect: TRect);
var
  Font: TCFontEC;
  Bitmap: TCBitmapEC;
  I, Y, X, N, Advance: Integer;
begin
  Font := nil;
  Bitmap := nil;
  if FontCache = nil then Exit;
  try
    Font := AcquireCachedFont(FontCache);
    Font.DefaultColor := TextColor;
    if BackgroundCache <> nil then Bitmap := AcquireOrCreateBitmap(BackgroundCache);
    if BackgroundCache <> nil then
      OKGR_Copy_XY_XY_WORD(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, ClipRect.Left, ClipRect.Top, Bitmap.Bitmap.Pixels, Bitmap.Bitmap.PitchBytes, ClipRect.Left - HitTestBounds.Left, ClipRect.Top - HitTestBounds.Top, ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
    X := HitTestBounds.Left + 2;
    if TextAlignX = taxCenter then
      with Font.MeasureTaggedTextBounds(Text, 0, 0) do
        X := HitTestBounds.Left + (HitTestBounds.Right - HitTestBounds.Left) div 2 - (Right - Left) div 2;
    Y := (HitTestBounds.Top + HitTestBounds.Bottom) div 2 - (Font.AboveBaseline + Font.BelowBaseline) div 2 + Font.AboveBaseline;
    N := Length(Text);
    for I := 0 to N do
    begin
      Advance := 0;
      if I < N then
      begin
        Advance := Font.GetGlyphAdvance(Text[I + 1]);
        Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, Text[I + 1], ClipRect);
      end;
      if (HasFocus = True) and (CaretPosition = I) and (MessageLoop.CaretBlinkOn = True) then
      begin
        ScreenRenderBuffer.DrawVerticalLine16Clipped(X, Y - (Font.AboveBaseline - 1), Font.AboveBaseline + Font.BelowBaseline, CaretColor, ClipRect);
        ScreenRenderBuffer.DrawVerticalLine16Clipped(X + 1, Y - (Font.AboveBaseline - 1), Font.AboveBaseline + Font.BelowBaseline, CaretColor, ClipRect);
      end;
      Inc(X, Advance);
    end;
    if BorderEnabled then
    begin
      ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left, BorderLightColor, ClipRect);
      ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Left, HitTestBounds.Top, HitTestBounds.Bottom - HitTestBounds.Top, BorderLightColor, ClipRect);
      ScreenRenderBuffer.DrawHorizontalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Right - HitTestBounds.Left - 1), BorderDarkColor, ClipRect);
      ScreenRenderBuffer.DrawVerticalLine16Clipped(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1, -(HitTestBounds.Bottom - HitTestBounds.Top - 1), BorderDarkColor, ClipRect);
    end;
  finally
    if Font <> nil then FontCache.Release;
    if Bitmap <> nil then BackgroundCache.Release;
  end;
end;
{ @end $488310 }

{ @routine $4886C8 TEditGI_QueueImageLoad }
procedure TEditGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
  if BackgroundCache <> nil then BackgroundCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $4886C8 }

end.

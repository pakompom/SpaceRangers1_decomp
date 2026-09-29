unit GI_Label;
// Unit bracket (inferred): CODE 0x00474CC0..0x00477757; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_CacheFont, EC_Str, GI_Image, GI_Main, GI_MessageLoop, GR_GraphBuf, Types;

type

  TLabelGI = class(TObjectGI) // @size $13C @methodorder source
  public
    FontCache: TCFontControlEC; // @offset $100
    EmbeddedImage: TImageGI; // @offset $104
    TextLines: TStringsEC; // @offset $108
    TextColor: Cardinal; // @offset $10C
    TextBorderWidth: Integer; // @offset $110
    TextBorderColor: Cardinal; // @offset $114
    TextShadowOffset: Integer; // @offset $118
    TextShadowColor: Cardinal; // @offset $11C
    BorderEnabled: Boolean; // @offset $120
    BorderLightColor: Cardinal; // @offset $124
    BorderDarkColor: Cardinal; // @offset $128
    TextAlignX: TTextAlignXGI; // @offset $12C
    TextAlignY: TTextAlignYGI; // @offset $12D
    TextLeft: Integer; // @offset $130
    TextTop: Integer; // @offset $134
    WordWrapEnabled: Boolean; // @offset $138

    constructor Create(Owner: TObjectGI); // @addr $474DD0
    destructor Destroy; override; // @addr $474EC0
    procedure Clear; override; // @addr $474F0C
    procedure SetFontName(const FontName: WideString); // @addr $474FA8
    procedure SetTextBorderWidth(Value: Integer); // @addr $474FD4
    procedure SetTextBorderColor(Value: Cardinal); // @addr $474FEC
    procedure SetShadowOffset(Value: Integer); // @addr $475004
    procedure SetShadowColor(Value: Cardinal); // @addr $47501C
    procedure SetText(const Text: WideString); // @addr $475034
    procedure LoadTextLinesFromBlockParam(Block: TBlockParEC; const ParamName: WideString); // @addr $4750B8
    function GetText: WideString; // @addr $475260
    procedure SetTextAlignX(Value: TTextAlignXGI); // @addr $475278
    procedure SetTextAlignY(Value: TTextAlignYGI); // @addr $4752A4
    procedure SetWordWrapEnabled(Value: Boolean); // @addr $4752D0
    procedure SetEmbeddedImagePath(const ImagePath: WideString); // @addr $4752FC @note "An empty path frees the embedded child."
    procedure SetEmbeddedImageKindX(Value: TImageKindXGI); // @addr $47538C
    procedure SetEmbeddedImageKindY(Value: TImageKindYGI); // @addr $4753A0
    procedure SetEmbeddedImageHalfAlpha(Value: Boolean); // @addr $4753B4
    procedure SetTextColor(Value: Cardinal); // @addr $4753C8
    procedure SetBorderLightColor(Value: Cardinal); // @addr $4753E0
    procedure SetBorderDarkColor(Value: Cardinal); // @addr $4753F8
    function MeasureContentSize: TPoint; // @addr $475410 @note "Includes text outline/shadow padding."
    function GetLineHeight: Integer; // @addr $4756F8
    procedure UpdateHitTestBounds; override; // @addr $475750 @note "May resize the control to fit its text."
    procedure SetSize(Size: TPoint); override; // @addr $475878
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $475918
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $475D00
    procedure Draw(ClipRect: TRect); override; // @addr $476218
    procedure OnMouseEnter; override; // @addr $4758A8
    procedure OnMouseLeave; override; // @addr $4758C8
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $4758E8
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $475900
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $477244
  end;

procedure RenderLabelTextToBuffer(Buffer: TGraphBufGR; Width, BorderWidth, ShadowOffset: Integer; const Text, FontName: WideString; TextColor, BorderColor, ShadowColor: Cardinal); // @addr $47751C

function MeasureWrappedLabelBounds(Width: Integer; TextLines: TStringsEC; Font: TCFontEC): TRect; // @addr $477250

procedure DrawWrappedLabelLines(Buffer: TGraphBufGR; Width, X, Y: Integer; TextLines: TStringsEC; Font: TCFontEC); // @addr $4773C0

implementation

// @unit-initialization $477750
// @unit-finalization $477720

uses EC_Cache, GR_Main, Math, Windows, SysUtils;

{ @routine $474DD0 TLabelGI_Create }
constructor TLabelGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  FontCache := TCFontControlEC.Create;
  GlobalCache.ResetControl(FontCache);
  EmbeddedImage := nil;
  TextLines := TStringsEC.Create;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  TextBorderWidth := 0;
  TextBorderColor := 0;
  BorderEnabled := False;
  TextAlignX := taxCenter;
  TextAlignY := tayCenter;
end;
{ @end $474DD0 }

{ @routine $474EC0 TLabelGI_Destroy }
destructor TLabelGI.Destroy;
begin
  FontCache.Free;
  FontCache := nil;
  TextLines.Free;
  TextLines := nil;
  inherited Destroy;
end;
{ @end $474EC0 }

{ @routine $474F0C TLabelGI_Clear }
procedure TLabelGI.Clear;
begin
  inherited Clear;
  TextColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderLightColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  BorderDarkColor := CurrentPixelFormat.PackRgbBytes(55, 55, 55);
  BorderEnabled := False;
  TextAlignX := taxCenter;
  TextAlignY := tayCenter;
  if TextLines <> nil then TextLines.Clear;
  if EmbeddedImage <> nil then
  begin
    FreeOwnedChild(EmbeddedImage);
    EmbeddedImage := nil;
  end;
end;
{ @end $474F0C }

{ @routine $474FA8 TLabelGI_SetFontName }
procedure TLabelGI.SetFontName(const FontName: WideString);
begin
  Invalidate;
  FontCache.SetCacheKey(FontName);
  Invalidate;
end;
{ @end $474FA8 }

{ @routine $474FD4 TLabelGI_SetTextBorderWidth }
procedure TLabelGI.SetTextBorderWidth(Value: Integer);
begin
  if Value <> TextBorderWidth then
  begin
    TextBorderWidth := Value;
    Invalidate;
  end;
end;
{ @end $474FD4 }

{ @routine $474FEC TLabelGI_SetTextBorderColor }
procedure TLabelGI.SetTextBorderColor(Value: Cardinal);
begin
  if Value <> TextBorderColor then
  begin
    TextBorderColor := Value;
    Invalidate;
  end;
end;
{ @end $474FEC }

{ @routine $475004 TLabelGI_SetShadowOffset }
procedure TLabelGI.SetShadowOffset(Value: Integer);
begin
  if Value <> TextShadowOffset then
  begin
    TextShadowOffset := Value;
    Invalidate;
  end;
end;
{ @end $475004 }

{ @routine $47501C TLabelGI_SetShadowColor }
procedure TLabelGI.SetShadowColor(Value: Cardinal);
begin
  if Value <> TextShadowColor then
  begin
    TextShadowColor := Value;
    Invalidate;
  end;
end;
{ @end $47501C }

{ @routine $475034 TLabelGI_SetText }
procedure TLabelGI.SetText(const Text: WideString);
begin
  if TextLines.GetText <> Text then
  begin
    Invalidate;
    TextLines.SetText(Text);
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $475034 }

{ @routine $4750B8 TLabelGI_LoadTextLinesFromBlockParam }
procedure TLabelGI.LoadTextLinesFromBlockParam(Block: TBlockParEC; const ParamName: WideString);
var Index, Count: Integer; Key: WideString;
begin
  TextLines.Clear;
  Count := Block.CountParams(ParamName);
  for Index := 0 to Count - 1 do
    TextLines.Add(Block.GetParamByPath(ParamName + ':' + IntToStr(Index)));
  if Count > 0 then
  begin
    Key := TrimWideString(TextLines.GetText);
    Count := LanguageDataConfig.CountParamsByPath(Key);
    if Count > 0 then
    begin
      TextLines.Clear;
      for Index := 0 to Count - 1 do
        TextLines.Add(LanguageDataConfig.GetParamByPath(Key + ':' + IntToStr(Index)));
    end;
  end;
  UpdateAbsolutePosition;
  UpdateSubtreeHitBounds;
  Invalidate;
end;
{ @end $4750B8 }

{ @routine $475260 TLabelGI_GetText }
function TLabelGI.GetText: WideString;
begin
  Result := TextLines.GetText;
end;
{ @end $475260 }

{ @routine $475278 TLabelGI_SetTextAlignX }
procedure TLabelGI.SetTextAlignX(Value: TTextAlignXGI);
begin
  if TextAlignX <> Value then
  begin
    TextAlignX := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $475278 }

{ @routine $4752A4 TLabelGI_SetTextAlignY }
procedure TLabelGI.SetTextAlignY(Value: TTextAlignYGI);
begin
  if TextAlignY <> Value then
  begin
    TextAlignY := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4752A4 }

{ @routine $4752D0 TLabelGI_SetWordWrapEnabled }
procedure TLabelGI.SetWordWrapEnabled(Value: Boolean);
begin
  if WordWrapEnabled <> Value then
  begin
    WordWrapEnabled := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4752D0 }

{ @routine $4752FC TLabelGI_SetEmbeddedImagePath }
procedure TLabelGI.SetEmbeddedImagePath(const ImagePath: WideString);
begin
  Invalidate;
  if ImagePath = '' then
  begin
    if EmbeddedImage <> nil then
    begin
      FreeOwnedChild(EmbeddedImage);
      EmbeddedImage := nil;
    end;
  end
  else
  begin
    if EmbeddedImage = nil then EmbeddedImage := TImageGI.Create(Self);
    EmbeddedImage.SetImagePath(ImagePath);
    EmbeddedImage.SetImageKindX(ikxLeftFill);
    EmbeddedImage.SetImageKindY(ikyTopFill);
    EmbeddedImage.SetSize(ClientSize);
  end;
end;
{ @end $4752FC }

{ @routine $47538C TLabelGI_SetEmbeddedImageKindX }
procedure TLabelGI.SetEmbeddedImageKindX(Value: TImageKindXGI);
begin
  if EmbeddedImage <> nil then EmbeddedImage.SetImageKindX(Value);
end;
{ @end $47538C }

{ @routine $4753A0 TLabelGI_SetEmbeddedImageKindY }
procedure TLabelGI.SetEmbeddedImageKindY(Value: TImageKindYGI);
begin
  if EmbeddedImage <> nil then EmbeddedImage.SetImageKindY(Value);
end;
{ @end $4753A0 }

{ @routine $4753B4 TLabelGI_SetEmbeddedImageHalfAlpha }
procedure TLabelGI.SetEmbeddedImageHalfAlpha(Value: Boolean);
begin
  if EmbeddedImage <> nil then EmbeddedImage.SetHalfAlpha(Value);
end;
{ @end $4753B4 }

{ @routine $4753C8 TLabelGI_SetTextColor }
procedure TLabelGI.SetTextColor(Value: Cardinal);
begin
  if TextColor <> Value then
  begin
    TextColor := Value;
    Invalidate;
  end;
end;
{ @end $4753C8 }

{ @routine $4753E0 TLabelGI_SetBorderLightColor }
procedure TLabelGI.SetBorderLightColor(Value: Cardinal);
begin
  if BorderLightColor <> Value then
  begin
    BorderLightColor := Value;
    Invalidate;
  end;
end;
{ @end $4753E0 }

{ @routine $4753F8 TLabelGI_SetBorderDarkColor }
procedure TLabelGI.SetBorderDarkColor(Value: Cardinal);
begin
  if BorderDarkColor <> Value then
  begin
    BorderDarkColor := Value;
    Invalidate;
  end;
end;
{ @end $4753F8 }

{ @routine $475410 TLabelGI_MeasureContentSize }
function TLabelGI.MeasureContentSize: TPoint;
var Font: TCFontEC; Y: Integer; Lines: TStringsEC; FirstLine: Boolean; Bounds, LineBounds: TRect;
begin
  Bounds.Left := 0;
  Bounds.Right := 0;
  Bounds.Top := 0;
  Bounds.Bottom := 0;
  if not FontCache.HasEmptyCacheKey then
  begin
    Font := AcquireCachedFont(FontCache);
    try
      Y := 0;
      TextLines.First;
      if not WordWrapEnabled then
      begin
        if not TextLines.IsAtEnd then
        begin
          Bounds := Font.MeasureTaggedTextBounds(TextLines.GetCurrentText, 0, Y);
          Inc(Y, Font.GetLineHeight);
          TextLines.Next;
        end;
        while not TextLines.IsAtEnd do
        begin
          LineBounds := Font.MeasureTaggedTextBounds(TextLines.GetCurrentText, 0, Y);
          UnionRect(Bounds, Bounds, LineBounds);
          Inc(Y, Font.GetLineHeight);
          TextLines.Next;
        end;
      end
      else
      begin
        Lines := TStringsEC.Create;
        FirstLine := True;
        while not TextLines.IsAtEnd do
        begin
          Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, ClientSize.X - 4);
          if not Lines.IsEmpty then
          begin
            Lines.First;
            if FirstLine then
            begin
          Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y);
              FirstLine := False;
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
            while not Lines.IsAtEnd do
            begin
          LineBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y);
              UnionRect(Bounds, Bounds, LineBounds);
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
          end;
          TextLines.Next;
        end;
        Lines.Free;
      end;
      Inc(Result.Y, 2);
    finally
      FontCache.Release;
    end;
  end;
  Result := Classes.Point(Bounds.Right - Bounds.Left + TextBorderWidth + Max(TextBorderWidth, TextShadowOffset),
    Bounds.Bottom - Bounds.Top + TextBorderWidth + Max(TextBorderWidth, TextShadowOffset));
end;
{ @end $475410 }

{ @routine $4756F8 TLabelGI_GetLineHeight }
function TLabelGI.GetLineHeight: Integer;
var Font: TCFontEC;
begin
  Font := AcquireCachedFont(FontCache);
  try
    Result := Font.GetLineHeight;
  finally
    FontCache.Release;
  end;
end;
{ @end $4756F8 }

{ @routine $475750 TLabelGI_UpdateHitTestBounds }
procedure TLabelGI.UpdateHitTestBounds;
var Size: TPoint;
begin
  Size := MeasureContentSize;
  if (TextAlignX = taxLeft) or (WordWrapEnabled = True) then TextLeft := AbsolutePosition.X + 2
  else if TextAlignX = taxRight then TextLeft := AbsolutePosition.X + ClientSize.X - Size.X - 2
  else if TextAlignX = taxCenter then TextLeft := ClientSize.X div 2 + AbsolutePosition.X - Size.X div 2
  else if TextAlignX = taxAuto then
  begin
    TextLeft := AbsolutePosition.X + 2;
    ClientSize.X := Size.X + 4;
  end;
  if TextAlignY = tayTop then TextTop := AbsolutePosition.Y + 2
  else if TextAlignY = tayBottom then TextTop := AbsolutePosition.Y + ClientSize.Y - Size.Y - 2
  else if TextAlignY = tayCenter then TextTop := ClientSize.Y div 2 + AbsolutePosition.Y - Size.Y div 2
  else if TextAlignY = tayCenterEx then TextTop := ClientSize.Y div 2 + AbsolutePosition.Y - Size.Y div 2
  else if TextAlignY = tayAuto then
  begin
    TextTop := AbsolutePosition.Y + 2;
    ClientSize.Y := Size.Y + 4;
  end;
  inherited UpdateHitTestBounds;
end;
{ @end $475750 }

{ @routine $475878 TLabelGI_SetSize }
procedure TLabelGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if EmbeddedImage <> nil then EmbeddedImage.SetSize(Size);
end;
{ @end $475878 }

{ @routine $4758A8 TLabelGI_OnMouseEnter }
procedure TLabelGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if Assigned(HelpCallback) then HelpCallback(Self, True);
end;
{ @end $4758A8 }

{ @routine $4758C8 TLabelGI_OnMouseLeave }
procedure TLabelGI.OnMouseLeave;
begin
  if Assigned(HelpCallback) then HelpCallback(Self, False);
  inherited OnMouseLeave;
end;
{ @end $4758C8 }

{ @routine $4758E8 TLabelGI_ProcessLeftButtonDown }
procedure TLabelGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
end;
{ @end $4758E8 }

{ @routine $475900 TLabelGI_ProcessLeftButtonUp }
procedure TLabelGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
end;
{ @end $475900 }

{ @routine $475918 TLabelGI_LoadFromConfigPath }
procedure TLabelGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Alignment: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Font') > 0 then FontCache.SetCacheKey(Block.GetParam('Font'));
  LoadTextLinesFromBlockParam(Block, 'Text');
  if Block.CountParams('Image') > 0 then SetEmbeddedImagePath(Block.GetParam('Image'));
  if Block.CountParams('ImageKindX') > 0 then SetEmbeddedImageKindX(ParseImageKindXName(Block.GetParam('ImageKindX')));
  if Block.CountParams('ImageKindY') > 0 then SetEmbeddedImageKindY(ParseImageKindYName(Block.GetParam('ImageKindY')));
  if Block.CountParams('TextColor') > 0 then SetTextColor(GetColorGI(Block.GetParam('TextColor')));
  if Block.CountParams('Border') > 0 then
  begin
    if Block.GetParam('Border') = 'True' then BorderEnabled := True
    else BorderEnabled := False;
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    SetBorderLightColor(GetColorGI(Block.GetParam('BorderLightColor')));
    SetBorderDarkColor(BorderLightColor);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then SetBorderDarkColor(GetColorGI(Block.GetParam('BorderDarkColor')));
  if Block.CountParams('WordWrap') > 0 then SetWordWrapEnabled(ParseEnabledNameGI(TrimWideString(Block.GetParam('WordWrap'))));
  if Block.CountParams('AlignY') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignY'));
    SetTextAlignY(ParseTextAlignYName(Alignment));
  end;
  if Block.CountParams('AlignX') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignX'));
    SetTextAlignX(ParseTextAlignXName(Alignment));
  end;
end;
{ @end $475918 }

{ @routine $475D00 TLabelGI_LoadFromBlock }
procedure TLabelGI.LoadFromBlock(Block: TBlockParEC);
var Alignment: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Font') > 0 then FontCache.SetCacheKey(Block.GetParam('Font'));
  LoadTextLinesFromBlockParam(Block, 'Text');
  if Block.CountParams('Image') > 0 then SetEmbeddedImagePath(Block.GetParam('Image'));
  if Block.CountParams('ImageKindX') > 0 then SetEmbeddedImageKindX(ParseImageKindXName(Block.GetParam('ImageKindX')));
  if Block.CountParams('ImageKindY') > 0 then SetEmbeddedImageKindY(ParseImageKindYName(Block.GetParam('ImageKindY')));
  if Block.CountParams('TextColor') > 0 then SetTextColor(GetColorGI(Block.GetParam('TextColor')));
  if Block.CountParams('Border') > 0 then
  begin
    if Block.GetParam('Border') = 'True' then BorderEnabled := True
    else BorderEnabled := False;
  end;
  if Block.CountParams('BorderLightColor') > 0 then
  begin
    SetBorderLightColor(GetColorGI(Block.GetParam('BorderLightColor')));
    SetBorderDarkColor(BorderLightColor);
  end;
  if Block.CountParams('BorderDarkColor') > 0 then SetBorderDarkColor(GetColorGI(Block.GetParam('BorderDarkColor')));
  if Block.CountParams('WordWrap') > 0 then SetWordWrapEnabled(ParseEnabledNameGI(TrimWideString(Block.GetParam('WordWrap'))));
  if Block.CountParams('AlignY') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignY'));
    SetTextAlignY(ParseTextAlignYName(Alignment));
  end;
  if Block.CountParams('AlignX') > 0 then
  begin
    Alignment := TrimWideString(Block.GetParam('AlignX'));
    SetTextAlignX(ParseTextAlignXName(Alignment));
  end;
  if Block.CountParams('TextBorderColor') > 0 then SetTextBorderColor(GetColorGI(Block.GetParam('TextBorderColor')));
  if Block.CountParams('TextShadowColor') > 0 then SetShadowColor(GetColorGI(Block.GetParam('TextShadowColor')));
  if Block.CountParams('TextBorder') > 0 then SetTextBorderWidth(ExtractDigitsToIntW(Block.GetParam('TextBorder')));
  if Block.CountParams('TextShadow') > 0 then SetShadowOffset(ExtractDigitsToIntW(Block.GetParam('TextShadow')));
end;
{ @end $475D00 }

{ @routine $476218 TLabelGI_Draw }
procedure TLabelGI.Draw(ClipRect: TRect);
var Font: TCFontEC; Y: Integer; Lines: TStringsEC; Bounds: TRect;
begin
  inherited Draw(ClipRect);
  Font := nil;
  if FontCache <> nil then
  begin
    try
      Font := AcquireCachedFont(FontCache);
        if not WordWrapEnabled then
        begin
          if TextAlignY = tayCenterEx then
            Y := HitTestBounds.Top + ClientSize.Y div 2 - (Font.GetLineHeight * (TextLines.GetCount - 1) + Font.GetCenteringHeight) div 2 + Font.GetCenteringHeight
          else Y := TextTop + Font.AboveBaseline - 2;
          TextLines.First;
          while not TextLines.IsAtEnd do
          begin
            Font.ColorTagsEnabled := False;
            if TextShadowOffset > 0 then
            begin
              Font.DefaultColor := TextShadowColor;
              Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextShadowOffset, Y + TextShadowOffset, TextLines.GetCurrentText, ClipRect);
            end;
            if TextBorderWidth > 0 then
            begin
              Font.DefaultColor := TextBorderColor;
              Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y - TextBorderWidth, TextLines.GetCurrentText, ClipRect);
              Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y - TextBorderWidth, TextLines.GetCurrentText, ClipRect);
              Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y + TextBorderWidth, TextLines.GetCurrentText, ClipRect);
              Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y + TextBorderWidth, TextLines.GetCurrentText, ClipRect);
            end;
            Font.ColorTagsEnabled := True;
            Font.DefaultColor := TextColor;
            Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft, Y, TextLines.GetCurrentText, ClipRect);
            Inc(Y, Font.GetLineHeight);
            TextLines.Next;
          end;
        end
        else
        begin
          Lines := TStringsEC.Create;
          Y := TextTop + Font.AboveBaseline - 2;
          TextLines.First;
          while not TextLines.IsAtEnd do
          begin
            Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, ClientSize.X - 4);
            Lines.First;
            while not Lines.IsAtEnd do
            begin
              if TextAlignX = taxLeft then
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextShadowOffset, Y + TextShadowOffset, Lines.GetCurrentText, ClipRect);
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft, Y, Lines.GetCurrentText, ClipRect);
              end
              else if TextAlignX = taxRight then
              begin
                Font.ColorTagsEnabled := False;
                Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, 0);
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextShadowOffset, Y + TextShadowOffset, Lines.GetCurrentText, ClipRect);
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 - TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 - TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2 + TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, HitTestBounds.Right - (Bounds.Right - Bounds.Left) - 2, Y, Lines.GetCurrentText, ClipRect);
              end
              else if TextAlignX = taxCenter then
              begin
                Font.ColorTagsEnabled := False;
                Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, 0);
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2 + TextShadowOffset, Y + TextShadowOffset, Lines.GetCurrentText, ClipRect);
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2 - TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2 + TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2 - TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2 + TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - (Bounds.Right - Bounds.Left) div 2, Y, Lines.GetCurrentText, ClipRect);
              end
              else if (TextAlignX = taxAuto) and (not Lines.IsAtLast) then
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextShadowOffset, Y + TextShadowOffset, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
                  Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
                  Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
                  Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawJustifiedTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft, Y, Lines.GetCurrentText, ClientSize.X - 4, ClipRect);
              end
              else
              begin
                Font.ColorTagsEnabled := False;
                if TextShadowOffset > 0 then
                begin
                  Font.DefaultColor := TextShadowColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextShadowOffset, Y + TextShadowOffset, Lines.GetCurrentText, ClipRect);
                end;
                if TextBorderWidth > 0 then
                begin
                  Font.DefaultColor := TextBorderColor;
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y - TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft - TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                  Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft + TextBorderWidth, Y + TextBorderWidth, Lines.GetCurrentText, ClipRect);
                end;
                Font.ColorTagsEnabled := True;
                Font.DefaultColor := TextColor;
                Font.DrawTaggedText16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, TextLeft, Y, Lines.GetCurrentText, ClipRect);
              end;
              Inc(Y, Font.GetLineHeight);
              Lines.Next;
            end;
            TextLines.Next;
          end;
          Lines.Free;
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
    end;
  end;
end;
{ @end $476218 }

{ @routine $477244 TLabelGI_QueueImageLoad }
procedure TLabelGI.QueueImageLoad(PendingLoads: TList);
begin
  FontCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $477244 }

{ @routine $477250 MeasureWrappedLabelBounds }
function MeasureWrappedLabelBounds(Width: Integer; TextLines: TStringsEC; Font: TCFontEC): TRect;
var
  Lines: TStringsEC;
  FirstLine: Boolean;
  Y: Integer;
  Bounds, LineBounds: TRect;
begin
  TextLines.First;
  Bounds.Left := 0;
  Bounds.Right := 0;
  Bounds.Top := 0;
  Bounds.Bottom := 0;
  Y := 0;
  Lines := TStringsEC.Create;
  FirstLine := True;
  while not TextLines.IsAtEnd do
  begin
    Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, Width - 4);
    if not Lines.IsEmpty then
    begin
      Lines.First;
      if FirstLine then
      begin
        Bounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y);
        FirstLine := False;
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
      while not Lines.IsAtEnd do
      begin
        LineBounds := Font.MeasureTaggedTextBounds(Lines.GetCurrentText, 0, Y);
        UnionRect(Bounds, Bounds, LineBounds);
        Inc(Y, Font.GetLineHeight);
        Lines.Next;
      end;
    end;
    TextLines.Next;
  end;
  Lines.Free;
  Inc(Bounds.Bottom, 2);
  Inc(Bounds.Right, 4);
  Result := Bounds;
end;
{ @end $477250 }

{ @routine $4773C0 DrawWrappedLabelLines }
procedure DrawWrappedLabelLines(Buffer: TGraphBufGR; Width, X, Y: Integer; TextLines: TStringsEC; Font: TCFontEC);
var
  Lines: TStringsEC;
  CurrentY: Integer;
  ClipRect: TRect;
begin
  Lines := TStringsEC.Create;
  ClipRect := Classes.Rect(0, 0, Buffer.Width, Buffer.Height);
  CurrentY := Y + 2 + Font.AboveBaseline - 2;
  TextLines.First;
  while not TextLines.IsAtEnd do
  begin
    Font.WrapTaggedTextIntoLines(Lines, TextLines.GetCurrentText, Width - 4);
    Lines.First;
    while not Lines.IsAtEnd do
    begin
      if not Lines.IsAtLast then
        Font.DrawJustifiedTaggedText32(Buffer.Pixels, Buffer.PitchBytes, X, CurrentY, Lines.GetCurrentText, Width - 4, ClipRect)
      else
        Font.DrawTaggedText32(Buffer.Pixels, Buffer.PitchBytes, X, CurrentY, Lines.GetCurrentText, ClipRect);
      Inc(CurrentY, Font.GetLineHeight);
      Lines.Next;
    end;
    TextLines.Next;
  end;
  Lines.Free;
end;
{ @end $4773C0 }

{ @routine $47751C RenderLabelTextToBuffer }
procedure RenderLabelTextToBuffer(Buffer: TGraphBufGR; Width, BorderWidth, ShadowOffset: Integer; const Text, FontName: WideString; TextColor, BorderColor, ShadowColor: Cardinal);
var
  Control: TCFontControlEC;
  Font: TCFontEC;
  Lines: TStringsEC;
  InnerWidth, X, Y: Integer;
begin
  Control := nil;
  Font := nil;
  Lines := nil;
  try
    Lines := TStringsEC.Create;
    Lines.SetText(Text);
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(FontName);
    Font := AcquireCachedFont(Control);
    Font.UseARGBColors := True;
    Font.ColorTagsEnabled := False;
    InnerWidth := Width - BorderWidth - Max(BorderWidth, ShadowOffset);
    with MeasureWrappedLabelBounds(InnerWidth, Lines, Font) do
    begin
      Dec(Left, BorderWidth);
      Dec(Top, BorderWidth);
      Inc(Right, Max(BorderWidth, ShadowOffset));
      Bottom := Bottom + Max(BorderWidth, ShadowOffset) + 4;
      Buffer.AllocateRgbaTight(InnerWidth, Bottom - Top);
    end;
    Buffer.ClearPixels;
    X := BorderWidth;
    Y := BorderWidth;
    if ShadowOffset <> 0 then
    begin
      Font.DefaultColor := ShadowColor;
      DrawWrappedLabelLines(Buffer, InnerWidth, X + ShadowOffset, Y + ShadowOffset, Lines, Font);
    end;
    if BorderWidth > 0 then
    begin
      Font.DefaultColor := BorderColor;
      DrawWrappedLabelLines(Buffer, InnerWidth, X - BorderWidth, Y - BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X + BorderWidth, Y - BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X - BorderWidth, Y + BorderWidth, Lines, Font);
      DrawWrappedLabelLines(Buffer, InnerWidth, X + BorderWidth, Y + BorderWidth, Lines, Font);
    end;
    Font.ColorTagsEnabled := True;
    Font.DefaultColor := TextColor;
    DrawWrappedLabelLines(Buffer, InnerWidth, X, Y, Lines, Font);
  finally
    if Font <> nil then Control.Release;
    if Control <> nil then Control.Free;
    if Lines <> nil then Lines.Free;
  end;
end;
{ @end $47751C }

end.

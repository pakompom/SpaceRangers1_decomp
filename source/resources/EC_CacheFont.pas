unit EC_CacheFont;
// Unit bracket (inferred): CODE 0x004732E0..0x00474CBF; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache, EC_Str, Types;

type
  TAftHeaderEC = packed record // @size $20
    Magic: array[0..3] of AnsiChar; // @offset $00
    Version: Integer; // @offset $04
    GlyphCount: Integer; // @offset $08
    CenteringHeight: Integer; // @offset $0C
    LineHeight: Integer; // @offset $14
    // Remaining header metrics have not been identified.
  end;
  PAftHeaderEC = ^TAftHeaderEC;
  TAftGlyphPlaneEC = packed record // @size $18
    Left: Integer; // @offset $00
    Top: Integer; // @offset $04
    Width: Integer; // @offset $08
    Height: Integer; // @offset $0C
    DataOffset: Integer; // @offset $10
    DataSize: Integer; // @offset $14  Encoded buffer size including its 16-byte header.
  end;
  TAftGlyphEC = packed record // @size $40
    CharCode: Cardinal; // @offset $00
    AdvanceA: Integer; // @offset $04
    AdvanceB: Integer; // @offset $08
    AdvanceC: Integer; // @offset $0C
    OpaqueMaskPlane: TAftGlyphPlaneEC; // @offset $10
    AlphaMaskPlane: TAftGlyphPlaneEC; // @offset $28
  end;
  PAftGlyphEC = ^TAftGlyphEC;
  TFontGlyphLookupEC = array[0..65535] of Word;
  PFontGlyphLookupEC = ^TFontGlyphLookupEC;

  TCFontControlEC = class;
  TCFontEC = class;

  TCFontControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $4733B4
    function CreateData: TCacheDataEC; override; // @addr $473420
    function AcquireData: TCacheDataEC; override; // @addr $473460
  end;

  TCFontEC = class(TCacheDataEC) // @size $48
  public
    FontData: PAftHeaderEC; // @offset $20
    GlyphCount: Integer; // @offset $24
    Glyphs: PAftGlyphEC; // @offset $28
    AboveBaseline: Integer; // @offset $2C
    BelowBaseline: Integer; // @offset $30
    GlyphLookup: PFontGlyphLookupEC; // @offset $34
    DefaultColor: Cardinal; // @offset $38
    UseARGBColors: Boolean; // @offset $3C
    ColorTagsEnabled: Boolean; // @offset $3D
    ColorStackCount: Integer; // @offset $40
    ColorStack: PCardinal; // @offset $44
    // ColorStack is a separately allocated buffer.

    constructor Create; // @addr $473468
    destructor Destroy; override; // @addr $4734A4
    procedure ClearLoadedFontData; // @addr $4734D0
    function GetCenteringHeight: Integer; // @addr $473508
    function GetLineHeight: Integer; // @addr $473510 @note "Includes two extra pixels beyond the stored line height."
    function MeasureTaggedTextBounds(const Text: WideString; X, Y: Integer): TRect; // @addr $47351C
    // The native implementation is handwritten assembly.
    function GetGlyphAdvance(CharCode: WideChar): Integer; cdecl; // @addr $47368C @ida "int __cdecl $name(TCFontEC *Self, unsigned __int16 CharCode);" @note "Returns zero for an absent character."
    function HasGlyph(CharCode: WideChar): Boolean; // @addr $4736C0
    procedure WrapTaggedTextIntoLines(Lines: TStringsEC; const Text: WideString; MaxWidth: Integer); // @addr $4736E8 @note "Replaces Lines and preserves tags in its output."
    procedure DrawTaggedText16(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; ClipRect: TRect); // @addr $473938
    procedure DrawTaggedText32(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; ClipRect: TRect); // @addr $473B68
    procedure DrawJustifiedTaggedText16(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; Width: Integer; ClipRect: TRect); // @addr $473D48
    procedure DrawJustifiedTaggedText32(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; Width: Integer; ClipRect: TRect); // @addr $474090
    function GetTaggedTextTokenLength(Text: PWideChar; CharCount: Integer): Integer; // @addr $47437C @note "Returns zero for incomplete tokens or a doubled opening bracket."
    function ParseTabTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer; // @addr $4743B8 @note "For td=n, raises X to at least n and returns the token length."
    function ParseAlignTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer; // @addr $474460 @note "Uppercase alignment checks retain the native incorrect source positions."
    function MatchAlignEndTag(Text: PWideChar; CharCount: Integer): Integer; // @addr $474708
    function ParseColorTag(Text: PWideChar; CharCount: Integer; out Color: Cardinal): Integer; // @addr $474780 @note "Parses color=r,g,b; emits ARGB or the current packed pixel format according to UseARGBColors."
    function MatchColorEndTag(Text: PWideChar; CharCount: Integer): Integer; // @addr $474930
    procedure ApplyColorTag(Text: PWideChar; CharCount: Integer); // @addr $4749A8 @note "Pushes or pops a color only while ColorTagsEnabled is true."
    procedure ClearColorStack; // @addr $4749F8
    procedure PushColor(Color: Cardinal); // @addr $474A14
    function PopColor: Cardinal; // @addr $474A50 @note "Returns zero when empty."
    function GetCurrentColor: Cardinal; // @addr $474A84 @note "Returns DefaultColor when tags are disabled or the stack is empty."
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $474AB8 @note "Requires aft version 1 and at least 0x20 bytes; glyph offsets and counts are trusted. Ignores LoadOption; ResidentBytes remains zero."
  end;

function AcquireCachedFont(Control: TCacheControlEC): TCFontEC; // @addr $473430 @note "Also clears the shared font's color stack, disables ARGB colors and enables color tags."

implementation
// @unit-initialization $474CB8
// @unit-finalization $474C88

uses EC_Mem, EC_OKGF, GR_Main, Math, SysUtils, Windows;

type
  TFontTextCharsEC = array[0..MaxInt div SizeOf(WideChar) - 1] of WideChar;
  PFontTextCharsEC = ^TFontTextCharsEC;

{ @routine $4733B4 TCFontControlEC_QueueLoadIfMissing }
procedure TCFontControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCFontControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCFontEC) = nil then
  begin
    Control := TCFontControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $4733B4 }

{ @routine $473420 TCFontControlEC_CreateData }
function TCFontControlEC.CreateData: TCacheDataEC;
begin
  Result := TCFontEC.Create;
end;
{ @end $473420 }

{ @routine $473430 AcquireCachedFont }
function AcquireCachedFont(Control: TCacheControlEC): TCFontEC;
begin
  Result := Control.AcquireDataFromConfig(TCFontEC) as TCFontEC;
  Result.ClearColorStack;
  Result.UseARGBColors := False;
  Result.ColorTagsEnabled := True;
end;
{ @end $473430 }

{ @routine $473460 TCFontControlEC_AcquireData }
function TCFontControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedFont(Self);
end;
{ @end $473460 }

{ @routine $473468 TCFontEC_Create }
constructor TCFontEC.Create;
begin
  inherited Create;
  ColorTagsEnabled := True;
end;
{ @end $473468 }

{ @routine $4734A4 TCFontEC_Destroy }
destructor TCFontEC.Destroy;
begin
  ClearLoadedFontData;
  inherited Destroy;
end;
{ @end $4734A4 }

{ @routine $4734D0 TCFontEC_ClearLoadedFontData }
procedure TCFontEC.ClearLoadedFontData;
begin
  if FontData <> nil then begin FreeEC(FontData); FontData := nil; end;
  Glyphs := nil; GlyphCount := 0;
  if GlyphLookup <> nil then begin FreeEC(GlyphLookup); GlyphLookup := nil; end;
  ClearColorStack;
end;
{ @end $4734D0 }

{ @routine $473508 TCFontEC_GetCenteringHeight }
function TCFontEC.GetCenteringHeight: Integer;
begin
  Result := FontData.CenteringHeight;
end;
{ @end $473508 }

{ @routine $473510 TCFontEC_GetLineHeight }
function TCFontEC.GetLineHeight: Integer;
begin
  Result := FontData.LineHeight + 2;
end;
{ @end $473510 }

{ @routine $47351C TCFontEC_MeasureTaggedTextBounds }
function TCFontEC.MeasureTaggedTextBounds(const Text: WideString; X, Y: Integer): TRect;
var Index, GlyphIndex, CharCount, PosX, TokenLength: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
begin
  CharCount := Length(Text);
  PosX := X;
  Result.Left := 999999999; Result.Right := -999999999;
  Result.Top := 999999999; Result.Bottom := -999999999;
  Index := 0;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      Index := Index + TokenLength - 1;
      Continue;
    end;
    GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
    if GlyphIndex = 0 then Continue;
    Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
    with Glyph^ do
    begin
      if AlphaMaskPlane.DataOffset <> 0 then
      begin
        if PosX + AlphaMaskPlane.Left < Result.Left then
          Result.Left := PosX + AlphaMaskPlane.Left;
        if Y + AlphaMaskPlane.Top < Result.Top then
          Result.Top := Y + AlphaMaskPlane.Top;
        if PosX + AlphaMaskPlane.Left + AlphaMaskPlane.Width > Result.Right then
          Result.Right := PosX + AlphaMaskPlane.Left + AlphaMaskPlane.Width;
        if Y + AlphaMaskPlane.Top + AlphaMaskPlane.Height > Result.Bottom then
          Result.Bottom := Y + AlphaMaskPlane.Top + AlphaMaskPlane.Height;
      end;
      if OpaqueMaskPlane.DataOffset <> 0 then
      begin
        if PosX + OpaqueMaskPlane.Left < Result.Left then
          Result.Left := PosX + OpaqueMaskPlane.Left;
        if Y + OpaqueMaskPlane.Top < Result.Top then
          Result.Top := Y + OpaqueMaskPlane.Top;
        if PosX + OpaqueMaskPlane.Left + OpaqueMaskPlane.Width > Result.Right then
          Result.Right := PosX + OpaqueMaskPlane.Left + OpaqueMaskPlane.Width;
        if Y + OpaqueMaskPlane.Top + OpaqueMaskPlane.Height > Result.Bottom then
          Result.Bottom := Y + OpaqueMaskPlane.Top + OpaqueMaskPlane.Height;
      end;
      PosX := PosX + AdvanceA + AdvanceB + AdvanceC;
    end;
  end;
  Result.Right := Max(Result.Right, PosX);
end;
{ @end $47351C }

{ @routine $47368C TCFontEC_GetGlyphAdvance }
function TCFontEC.GetGlyphAdvance(CharCode: WideChar): Integer; cdecl;
asm
  PUSH EBX
  MOV EBX, Self
  XOR EAX, EAX
  MOV AX, CharCode
  SHL EAX, 1
  ADD EAX, [EBX].TCFontEC.GlyphLookup
  MOV AX, [EAX]
  AND EAX, $FFFF
  TEST EAX, EAX
  JZ @@Done
  DEC EAX
  SHL EAX, 6
  ADD EAX, [EBX].TCFontEC.Glyphs
  MOV EBX, EAX
  MOV EAX, [EBX].TAftGlyphEC.AdvanceA
  ADD EAX, [EBX].TAftGlyphEC.AdvanceB
  ADD EAX, [EBX].TAftGlyphEC.AdvanceC
@@Done:
  POP EBX
end;
{ @end $47368C }

{ @routine $4736C0 TCFontEC_HasGlyph }
function TCFontEC.HasGlyph(CharCode: WideChar): Boolean;
begin
  Result := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(CharCode) * 2)) > 0;
end;
{ @end $4736C0 }

{ @routine $4736E8 TCFontEC_WrapTaggedTextIntoLines }
procedure TCFontEC.WrapTaggedTextIntoLines(Lines: TStringsEC; const Text: WideString; MaxWidth: Integer);
var
  TokenLength, WordStart, Index, CharCount, WordLength, FitEnd, WordWidth,
    LineWidth, LineStart, LineLength: Integer;
  FirstLine, SeenCharacter: Boolean;
begin
  Lines.Clear;
  LineWidth := 0; WordStart := 0; LineStart := 0; LineLength := 0;
  CharCount := Length(Text);
  FirstLine := True;
  while WordStart < CharCount do
  begin
    SeenCharacter := False;
    for Index := WordStart to CharCount - 1 do
    begin
      if PFontTextCharsEC(Pointer(Text))^[Index] = ' ' then
        if SeenCharacter then Break;
      SeenCharacter := True;
    end;
    WordLength := Index - WordStart;
    WordWidth := 0; Index := WordStart; FitEnd := 0;
    while Index <= WordStart + WordLength - 1 do
    begin
      // Tests the current position before consuming an ordinary character.
      TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index, WordLength - (Index - WordStart));
      if TokenLength > 0 then
      begin
        Index := Index + TokenLength;
        Continue;
      end;
      WordWidth := WordWidth + GetGlyphAdvance(PFontTextCharsEC(Pointer(Text))^[Index]);
      if WordWidth <= MaxWidth then FitEnd := Index;
      Inc(Index);
    end;
    if LineWidth = 0 then
    begin
      if WordWidth > MaxWidth then
      begin
        TokenLength := 0;
        if not FirstLine then
          while Text[LineStart + 1 + TokenLength] = ' ' do Inc(TokenLength);
        if LineLength - TokenLength > 0 then
          Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength)
        else
        begin
          Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, FitEnd + 1 - WordStart);
          WordStart := FitEnd + 1; WordLength := 0; WordWidth := 0;
        end;
        FirstLine := False;
      end;
      LineStart := WordStart; WordStart := WordStart + WordLength;
      LineWidth := WordWidth; LineLength := WordLength;
    end
    else if LineWidth + WordWidth <= MaxWidth then
    begin
      WordStart := WordStart + WordLength;
      LineWidth := LineWidth + WordWidth; LineLength := LineLength + WordLength;
    end
    else
    begin
      TokenLength := 0;
      if not FirstLine then
        while Text[LineStart + 1 + TokenLength] = ' ' do Inc(TokenLength);
      Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength);
      FirstLine := False;
      LineStart := WordStart; WordStart := WordStart + WordLength;
      LineWidth := WordWidth; LineLength := WordLength;
    end;
  end;
  TokenLength := 0; LineLength := CharCount - LineStart;
  if not FirstLine then
    while Text[LineStart + 1 + TokenLength] = ' ' do Inc(TokenLength);
  if LineLength - TokenLength > 0 then
    Lines.AddSlice(PWideChar(Text) + LineStart + TokenLength, LineLength - TokenLength);
end;
{ @end $4736E8 }

{ @routine $473938 TCFontEC_DrawTaggedText16 }
procedure TCFontEC.DrawTaggedText16(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; ClipRect: TRect);
var
  Index, GlyphIndex, TokenLength, CharCount, PosX: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
  Clip: TRect;
begin
  Clip.Left := ClipRect.Left; Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1; Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then Exit;
  Index := 0; PosX := 0;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      ParseTabTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      ParseAlignTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      Index := Index + TokenLength - 1;
      Continue;
    end;
    GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
    if GlyphIndex = 0 then Continue;
    Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
    begin
      OKGR_MaskBuf_DrawClip_WORD(Destination, PitchBytes, X + PosX + Glyph.OpaqueMaskPlane.Left,
        Y + Glyph.OpaqueMaskPlane.Top, AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset), GetCurrentColor, Clip);
    end;
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then
    begin
      if CurrentPixelFormat.TotalChannelBits = 15 then
        OKGR_TransBuf_FillAlphaClip_15(Destination, PitchBytes, X + PosX + Glyph.AlphaMaskPlane.Left,
          Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor)
      else
        OKGR_TransBuf_FillAlphaClip_16(Destination, PitchBytes, X + PosX + Glyph.AlphaMaskPlane.Left,
          Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor);
    end;
    PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
  end;
end;
{ @end $473938 }

{ @routine $473B68 TCFontEC_DrawTaggedText32 }
procedure TCFontEC.DrawTaggedText32(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; ClipRect: TRect);
var
  Index, GlyphIndex, TokenLength, CharCount, PosX: Integer;
  Ch: WideChar;
  Glyph: PAftGlyphEC;
  Clip: TRect;
begin
  Clip.Left := ClipRect.Left; Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1; Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then Exit;
  Index := 0; PosX := 0;
  while Index < CharCount do
  begin
    Ch := Text[Index + 1]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then
    begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      ParseTabTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      ParseAlignTagAndAdjustX(PWideChar(Text) + Index - 1, CharCount - Index + 1, PosX);
      Index := Index + TokenLength - 1;
      Continue;
    end;
    GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
    if GlyphIndex = 0 then Continue;
    Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
    begin
      OKGR_MaskBuf_DrawClip_DWORD(Destination, PitchBytes, X + PosX + Glyph.OpaqueMaskPlane.Left,
        Y + Glyph.OpaqueMaskPlane.Top, AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset), GetCurrentColor, Clip);
    end;
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then
    begin
      OKGR_TransBuf_FillAlphaClip_RGBA(Destination, PitchBytes, X + PosX + Glyph.AlphaMaskPlane.Left,
        Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor);
    end;
    PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
  end;
end;
{ @end $473B68 }

{ @routine $473D48 TCFontEC_DrawJustifiedTaggedText16 }
procedure TCFontEC.DrawJustifiedTaggedText16(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; Width: Integer; ClipRect: TRect);
var
  Character: WideChar;
  Lookup: PFontGlyphLookupEC;
  GlyphIndex: Integer;
  GlyphBase, Glyph: PAftGlyphEC;
  TextWidth, CharCount, Index, SpaceCount: Integer;
  SpaceWidth, PosX: Double;
  LeadingSpaces: Boolean;
  TokenLength: Integer;
  Clip: TRect;
begin
  Clip.Left := ClipRect.Left; Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1; Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then Exit;
  TextWidth := 0;
  SpaceCount := 0;
  LeadingSpaces := True;
  Index := 0;
  while Index < CharCount do begin
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index, CharCount - Index);
    if TokenLength > 0 then begin
      Inc(Index, TokenLength);
      Continue;
    end;
    if Text[Index + 1] <> ' ' then begin
      Inc(TextWidth, GetGlyphAdvance(Text[Index + 1]));
      LeadingSpaces := False;
    end else if LeadingSpaces = True then Inc(TextWidth, GetGlyphAdvance(Text[Index + 1]))
    else Inc(SpaceCount);
    Inc(Index);
  end;
  if SpaceCount < 1 then begin
    DrawTaggedText16(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  SpaceWidth := (Width - TextWidth) / SpaceCount;
  if SpaceWidth < 2 then begin
    DrawTaggedText16(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  Lookup := GlyphLookup;
  GlyphBase := Glyphs;
  PosX := X;
  LeadingSpaces := True;
  Index := 0;
  while Index < CharCount do begin
    Character := Text[Index + 1]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      Index := Index + TokenLength - 1;
      Continue;
    end;
    asm
      XOR EAX, EAX
      MOV AX, Character
      SHL EAX, 1
      ADD EAX, Lookup
      MOV AX, [EAX]
      AND EAX, $FFFF
      MOV GlyphIndex, EAX
    end;
    if GlyphIndex = 0 then Continue;
    asm
      MOV EAX, GlyphIndex
      DEC EAX
      SHL EAX, 6
      ADD EAX, GlyphBase
      MOV Glyph, EAX
    end;
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
      OKGR_MaskBuf_DrawClip_WORD(Destination, PitchBytes, Trunc(PosX) + Glyph.OpaqueMaskPlane.Left,
        Y + Glyph.OpaqueMaskPlane.Top, AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset), GetCurrentColor, Clip);
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then begin
      if CurrentPixelFormat.TotalChannelBits = 15 then
        OKGR_TransBuf_FillAlphaClip_15(Destination, PitchBytes, Trunc(PosX) + Glyph.AlphaMaskPlane.Left,
          Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor)
      else
        OKGR_TransBuf_FillAlphaClip_16(Destination, PitchBytes, Trunc(PosX) + Glyph.AlphaMaskPlane.Left,
          Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor);
    end;
    if Character <> ' ' then begin
      PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
      LeadingSpaces := False;
    end else if LeadingSpaces = True then
      PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC
    else PosX := PosX + SpaceWidth;
  end;
end;
{ @end $473D48 }

{ @routine $474090 TCFontEC_DrawJustifiedTaggedText32 }
procedure TCFontEC.DrawJustifiedTaggedText32(Destination: Pointer; PitchBytes, X, Y: Integer; const Text: WideString; Width: Integer; ClipRect: TRect);
var
  Character: WideChar;
  Lookup: PFontGlyphLookupEC;
  GlyphIndex: Integer;
  GlyphBase, Glyph: PAftGlyphEC;
  TextWidth, CharCount, Index, SpaceCount: Integer;
  SpaceWidth, PosX: Double;
  LeadingSpaces: Boolean;
  TokenLength: Integer;
  Clip: TRect;
begin
  Clip.Left := ClipRect.Left; Clip.Top := ClipRect.Top;
  Clip.Right := ClipRect.Right - 1; Clip.Bottom := ClipRect.Bottom - 1;
  CharCount := Length(Text);
  if CharCount < 1 then Exit;
  TextWidth := 0;
  SpaceCount := 0;
  LeadingSpaces := True;
  Index := 0;
  while Index < CharCount do begin
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index, CharCount - Index);
    if TokenLength > 0 then begin
      Inc(Index, TokenLength);
      Continue;
    end;
    if Text[Index + 1] <> ' ' then begin
      Inc(TextWidth, GetGlyphAdvance(Text[Index + 1]));
      LeadingSpaces := False;
    end else if LeadingSpaces = True then Inc(TextWidth, GetGlyphAdvance(Text[Index + 1]))
    else Inc(SpaceCount);
    Inc(Index);
  end;
  if SpaceCount < 1 then begin
    DrawTaggedText32(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  SpaceWidth := (Width - TextWidth) / SpaceCount;
  if SpaceWidth < 2 then begin
    DrawTaggedText32(Destination, PitchBytes, X, Y, Text, ClipRect);
    Exit;
  end;
  Lookup := GlyphLookup;
  GlyphBase := Glyphs;
  PosX := X;
  LeadingSpaces := True;
  Index := 0;
  while Index < CharCount do begin
    Character := Text[Index + 1]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(PWideChar(Text) + Index - 1, CharCount - Index + 1);
    if TokenLength > 0 then begin
      ApplyColorTag(PWideChar(Text) + Index - 1, CharCount - Index + 1);
      Index := Index + TokenLength - 1;
      Continue;
    end;
    asm
      XOR EAX, EAX
      MOV AX, Character
      SHL EAX, 1
      ADD EAX, Lookup
      MOV AX, [EAX]
      AND EAX, $FFFF
      MOV GlyphIndex, EAX
    end;
    if GlyphIndex = 0 then Continue;
    asm
      MOV EAX, GlyphIndex
      DEC EAX
      SHL EAX, 6
      ADD EAX, GlyphBase
      MOV Glyph, EAX
    end;
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
      OKGR_MaskBuf_DrawClip_DWORD(Destination, PitchBytes, Trunc(PosX) + Glyph.OpaqueMaskPlane.Left,
        Y + Glyph.OpaqueMaskPlane.Top, AddPointerOffset(FontData, Glyph.OpaqueMaskPlane.DataOffset), GetCurrentColor, Clip);
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then
      OKGR_TransBuf_FillAlphaClip_RGBA(Destination, PitchBytes, Trunc(PosX) + Glyph.AlphaMaskPlane.Left,
        Y + Glyph.AlphaMaskPlane.Top, AddPointerOffset(FontData, Glyph.AlphaMaskPlane.DataOffset), Clip, GetCurrentColor);
    if Character <> ' ' then begin
      PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC;
      LeadingSpaces := False;
    end else if LeadingSpaces = True then
      PosX := PosX + Glyph.AdvanceA + Glyph.AdvanceB + Glyph.AdvanceC
    else PosX := PosX + SpaceWidth;
  end;
end;
{ @end $474090 }

{ @routine $47437C TCFontEC_GetTaggedTextTokenLength }
function TCFontEC.GetTaggedTextTokenLength(Text: PWideChar; CharCount: Integer): Integer;
var Index: Integer;
begin
  Result := 0;
  if (CharCount < 2) or (Text[0] <> '<') then Exit;
  if Text[1] = '<' then begin Result := 0; Exit; end;
  Index := 1;
  while Index < CharCount do
  begin
    if Text[Index] = '>' then Break;
    Inc(Index);
  end;
  if Index < CharCount then Result := Index + 1;
end;
{ @end $47437C }

{ @routine $4743B8 TCFontEC_ParseTabTagAndAdjustX }
function TCFontEC.ParseTabTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer;
var Value, Index: Integer;
begin
  Result := 0;
  if CharCount < 4 then Exit;
  if Text[0] <> '<' then Exit;
  if ((Text[1] <> 't') and (Text[1] <> 'T')) or
    ((Text[2] <> 'd') and (Text[2] <> 'D')) or
    ((Text[3] <> '=') and (Text[3] <> '=')) then Exit;
  Value := 0; Index := 4;
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then Break;
    Value := Value * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if (Index < CharCount) and (Text[Index] = '>') then
  begin
    Result := Index + 1;
    if X < Value then X := Value;
  end;
end;
{ @end $4743B8 }

{ @routine $474460 TCFontEC_ParseAlignTagAndAdjustX }
function TCFontEC.ParseAlignTagAndAdjustX(Text: PWideChar; CharCount: Integer; var X: Integer): Integer;
var
  Ch: WideChar;
  AlignRight: Boolean;
  Index, GlyphIndex, Width, TextLength, TokenLength: Integer;
  Glyph: PAftGlyphEC;
  TextCopy: WideString;
begin
  Result := 0;
  if CharCount < 7 then Exit;
  if Text[0] <> '<' then Exit;
  if ((Text[1] <> 'a') and (Text[1] <> 'A')) or
    ((Text[2] <> 'l') and (Text[2] <> 'L')) or
    ((Text[3] <> 'i') and (Text[3] <> 'I')) or
    ((Text[4] <> 'g') and (Text[4] <> 'G')) or
    ((Text[5] <> 'n') and (Text[5] <> 'N')) or
    ((Text[6] <> '=') and (Text[6] <> '=')) then Exit;
  Index := 0; AlignRight := False;
  if CharCount >= 13 then
  begin
    AlignRight := ((Text[7] = 'r') or (Text[1] = 'R')) and
      ((Text[8] = 'i') or (Text[2] = 'I')) and
      ((Text[9] = 'g') or (Text[3] = 'G')) and
      ((Text[10] = 'h') or (Text[4] = 'H')) and
      ((Text[11] = 't') or (Text[5] = 'T')) and (Text[12] = '>');
    Index := 13;
  end;
  if not AlignRight then
  begin
    if CharCount < 14 then Exit;
    if (Text[7] <> 'c') and (Text[1] <> 'C') then Exit;
    if (Text[8] <> 'e') and (Text[2] <> 'E') then Exit;
    if (Text[9] <> 'n') and (Text[3] <> 'N') then Exit;
    if (Text[10] <> 't') and (Text[4] <> 'T') then Exit;
    if (Text[11] <> 'e') and (Text[5] <> 'E') then Exit;
    if (Text[12] <> 'r') and (Text[5] <> 'R') then Exit;
    if Text[13] <> '>' then Exit;
    Index := 14;
  end;
  Result := Index;
  TextCopy := Text;
  TextLength := Length(TextCopy);
  Width := 0;
  while Index < TextLength do
  begin
    Ch := Text[Index]; Inc(Index);
    TokenLength := GetTaggedTextTokenLength(Text + Index - 1, TextLength - Index + 1);
    if TokenLength > 0 then
    begin
      if MatchAlignEndTag(Text + Index - 1, TextLength - Index + 1) > 0 then Break;
      // Convert the tag length to the next text position before advancing.
      TokenLength := Index + TokenLength - 1;
      Index := TokenLength;
    end
    else
    begin
      GlyphIndex := ReadWordEC(AddPointerOffset(GlyphLookup, Ord(Ch) * 2));
      if GlyphIndex <> 0 then
      begin
        Glyph := AddPointerOffset(Glyphs, (GlyphIndex - 1) * SizeOf(TAftGlyphEC));
        Width := Glyph.AdvanceA + Width + Glyph.AdvanceB + Glyph.AdvanceC;
      end;
    end;
  end;
  if AlignRight then X := X - Width else X := X - Width div 2;
end;
{ @end $474460 }

{ @routine $474708 TCFontEC_MatchAlignEndTag }
function TCFontEC.MatchAlignEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount >= 8 then
    if Text[0] = '<' then
      if Text[1] = '/' then
        if ((Text[2] = 'a') or (Text[2] = 'A')) and
          ((Text[3] = 'l') or (Text[3] = 'L')) and
          ((Text[4] = 'i') or (Text[4] = 'I')) and
          ((Text[5] = 'g') or (Text[5] = 'G')) and
          ((Text[6] = 'n') or (Text[6] = 'N')) then
          if Text[7] = '>' then Result := 8;
end;
{ @end $474708 }

{ @routine $474780 TCFontEC_ParseColorTag }
function TCFontEC.ParseColorTag(Text: PWideChar; CharCount: Integer; out Color: Cardinal): Integer;
var Red, Green, Blue, Index: Integer;
begin
  Result := 0;
  if CharCount < 13 then Exit;
  if Text[0] <> '<' then Exit;
  if ((Text[1] <> 'c') and (Text[1] <> 'C')) or
    ((Text[2] <> 'o') and (Text[2] <> 'O')) or
    ((Text[3] <> 'l') and (Text[3] <> 'L')) or
    ((Text[4] <> 'o') and (Text[4] <> 'O')) or
    ((Text[5] <> 'r') and (Text[5] <> 'R')) or
    ((Text[6] <> '=') and (Text[6] <> '=')) then Exit;
  Red := 0; Green := 0; Blue := 0; Index := 7;
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then Break;
    Red := Red * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then Exit;
  if Text[Index] <> ',' then Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then Break;
    Green := Green * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then Exit;
  if Text[Index] <> ',' then Exit;
  Inc(Index);
  while Index < CharCount do
  begin
    if (Text[Index] < '0') or (Text[Index] > '9') then Break;
    Blue := Blue * 10 + Ord(Text[Index]) - Ord('0');
    Inc(Index);
  end;
  if Index >= CharCount then Exit;
  if Text[Index] <> '>' then Exit;
  Result := Index + 1;
  if not UseARGBColors then Color := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue)
  else Color := (Red shl 16) or (Green shl 8) or Blue or $FF000000;
end;
{ @end $474780 }

{ @routine $474930 TCFontEC_MatchColorEndTag }
function TCFontEC.MatchColorEndTag(Text: PWideChar; CharCount: Integer): Integer;
begin
  Result := 0;
  if CharCount >= 8 then
    if Text[0] = '<' then
      if Text[1] = '/' then
        if ((Text[2] = 'c') or (Text[2] = 'C')) and
          ((Text[3] = 'o') or (Text[3] = 'O')) and
          ((Text[4] = 'l') or (Text[4] = 'L')) and
          ((Text[5] = 'o') or (Text[5] = 'O')) and
          ((Text[6] = 'r') or (Text[6] = 'R')) then
          if Text[7] = '>' then Result := 8;
end;
{ @end $474930 }

{ @routine $4749A8 TCFontEC_ApplyColorTag }
procedure TCFontEC.ApplyColorTag(Text: PWideChar; CharCount: Integer);
var Color: Cardinal;
begin
  if ParseColorTag(Text, CharCount, Color) > 0 then
  begin
    if ColorTagsEnabled then PushColor(Color);
  end
  else if MatchColorEndTag(Text, CharCount) > 0 then
  begin
    if ColorTagsEnabled then PopColor;
  end;
end;
{ @end $4749A8 }

{ @routine $4749F8 TCFontEC_ClearColorStack }
procedure TCFontEC.ClearColorStack;
begin
  if ColorStack <> nil then begin FreeEC(ColorStack); ColorStack := nil; end;
  ColorStackCount := 0;
end;
{ @end $4749F8 }

{ @routine $474A14 TCFontEC_PushColor }
procedure TCFontEC.PushColor(Color: Cardinal);
begin
  Inc(ColorStackCount);
  ColorStack := ReAllocREC(ColorStack, ColorStackCount * SizeOf(Cardinal));
  WriteIntegerEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)), Color);
end;
{ @end $474A14 }

{ @routine $474A50 TCFontEC_PopColor }
function TCFontEC.PopColor: Cardinal;
begin
  if ColorStackCount < 1 then begin Result := 0; Exit; end;
  Result := ReadDWordEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)));
  Dec(ColorStackCount);
end;
{ @end $474A50 }

{ @routine $474A84 TCFontEC_GetCurrentColor }
function TCFontEC.GetCurrentColor: Cardinal;
begin
  if not ColorTagsEnabled or (ColorStackCount < 1) then Result := DefaultColor
  else Result := ReadDWordEC(AddPointerOffset(ColorStack, (ColorStackCount - 1) * SizeOf(Cardinal)));
end;
{ @end $474A84 }

{ @routine $474AB8 TCFontEC_LoadFromConfigBuffer }
procedure TCFontEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var Index: Integer; Glyph: PAftGlyphEC;
begin
  ClearLoadedFontData;
  if SourceBuffer.DataSize < SizeOf(TAftHeaderEC) then raise Exception.Create('TCFontEC.Load. Error format file.');
  FontData := AllocEC(SourceBuffer.DataSize);
  CopyMemory(FontData, SourceBuffer.Data, SourceBuffer.DataSize);
  Glyphs := AddPointerOffset(FontData, SizeOf(TAftHeaderEC));
  if (FontData.Magic[0] <> 'a') or (FontData.Magic[1] <> 'f') or (FontData.Magic[2] <> 't') then
    raise Exception.Create('TCFontEC.Load. Error format file.');
  if FontData.Version <> 1 then raise Exception.Create('TCFontEC.Load. Unknown version of font.');
  GlyphCount := FontData.GlyphCount;
  GlyphLookup := AllocClearEC(SizeOf(TFontGlyphLookupEC));
  AboveBaseline := 0; BelowBaseline := 0;
  Glyph := Glyphs;
  for Index := 0 to GlyphCount - 1 do
  begin
    WriteWordEC(AddPointerOffset(GlyphLookup, Glyph.CharCode * 2), Word(Index) + 1);
    if Glyph.OpaqueMaskPlane.DataOffset <> 0 then
    begin
      if (Glyph.OpaqueMaskPlane.Top <= 0) and (-Glyph.OpaqueMaskPlane.Top + 1 > AboveBaseline) then
        AboveBaseline := -Glyph.OpaqueMaskPlane.Top + 1;
      if (Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height > 0) and
         (Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height - 1 > BelowBaseline) then
        BelowBaseline := Glyph.OpaqueMaskPlane.Top + Glyph.OpaqueMaskPlane.Height - 1;
    end;
    if Glyph.AlphaMaskPlane.DataOffset <> 0 then
    begin
      if (Glyph.AlphaMaskPlane.Top <= 0) and (-Glyph.AlphaMaskPlane.Top + 1 > AboveBaseline) then
        AboveBaseline := -Glyph.AlphaMaskPlane.Top + 1;
      if (Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height > 0) and
         (Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height - 1 > BelowBaseline) then
        BelowBaseline := Glyph.AlphaMaskPlane.Top + Glyph.AlphaMaskPlane.Height - 1;
    end;
    Glyph := AddPointerOffset(Glyph, SizeOf(TAftGlyphEC));
  end;
  ResidentBytes := 0;
end;
{ @end $474AB8 }

end.

unit EC_Str;
// Unit bracket (inferred): CODE 0x004C2798..0x004C3E8B; inclusive evidence, not full bounds.

interface

type
  THexDigits = array[0..15] of WideChar; // @size 32

  TWideCasePair = packed record // @size $04
    LowerChar: WideChar; // @offset $00
    UpperChar: WideChar; // @offset $02
  end;

  TStringsElEC = class(TObject) // @size $14
  public
    Prev: TStringsElEC; // @offset $04
    Next: TStringsElEC; // @offset $08
    Text: WideString; // @offset $0C
    Data: Pointer; // @offset $10
  end;

  TStringsEC = class(TObject) // @size $10
  public
    FirstElement: TStringsElEC; // @offset $04
    LastElement: TStringsElEC; // @offset $08
    CurrentElement: TStringsElEC; // @offset $0C

    constructor Create; // @addr $4C285C
    destructor Destroy; override; // @addr $4C2894
    procedure Clear; // @addr $4C28C0
    function AddEmptyElement: TStringsElEC; // @addr $4C28DC
    procedure AppendElement(Item: TStringsElEC); // @addr $4C28FC
    procedure RemoveAndFreeElement(Item: TStringsElEC); // @addr $4C2920 @note "Does not adjust CurrentElement."
    function EnsureElement(Index: Integer): TStringsElEC; // @addr $4C295C @note "Creates missing entries; negative indexes raise."
    function GetCount: Integer; // @addr $4C2A20
    function GetTextAt(Index: Integer): WideString; // @addr $4C2A34 @note "Reading beyond the end extends the list."
    function GetDataAt(Index: Integer): Pointer; // @addr $4C2A54 @note "Reading beyond the end extends the list."
    procedure SetDataAt(Index: Integer; Data: Pointer); // @addr $4C2A6C @note "Creates missing entries; Data is borrowed."
    procedure Add(const Text: WideString); // @addr $4C2A88
    procedure AddSlice(Text: PWideChar; CharCount: Integer); // @addr $4C2AA4 @note "Nonpositive CharCount still appends an empty element."
    function GetCurrentText: WideString; // @addr $4C2AD8 @note "Raises when CurrentElement is nil."
    function GetCurrentData: Pointer; // @addr $4C2B24 @note "Raises when CurrentElement is nil."
    function IsAtEnd: Boolean; // @addr $4C2B64
    function IsAtLast: Boolean; // @addr $4C2B70 @note "Requires nonnil CurrentElement."
    procedure First; // @addr $4C2B80
    procedure Next; // @addr $4C2B88 @note "Requires nonnil CurrentElement."
    function IsEmpty: Boolean; // @addr $4C2B94
    procedure SetText(const Text: WideString); // @addr $4C2B9C @note "Splits CR, LF and CRLF lines; does not append an empty line after a trailing separator."
    function GetText: WideString; // @addr $4C2C00 @note "Joins elements with CRLF, without a trailing separator."
  end;

function CountDelimitedPartsW(const Text: WideString; const Delimiters: WideString): Integer; // @addr $4C2C5C @note "Delimiters is a set of separator characters, not a substring. Counts empty parts; empty Text returns zero."
function GetDelimitedPartStartIndexW(const Text: WideString; PartIndex: Integer; const Delimiters: WideString): Integer; // @addr $4C2CCC @note "Zero-based part index, one-based character result. Nonpositive PartIndex returns 1; missing positive indexes raise."
function GetCharDelimitedPartStartIndexW(const Text: WideString; PartIndex: Integer; Delimiter: WideChar): Integer; // @addr $4C2E3C @note "One-based character result. Nonpositive PartIndex returns 1; 1 returns the position after the first delimiter or -1. Native early exit makes every PartIndex above 1 return -1."
function GetDelimitedPartLengthW(const Text: WideString; StartIndex: Integer; const Delimiters: WideString): Integer; // @addr $4C2E7C @note "StartIndex is a one-based character position, not a part index."
function ExtractDelimitedPartW(const Text: WideString; PartIndex: Integer; const Delimiters: WideString): WideString; // @addr $4C2EEC
function ExtractDelimitedRangeW(const Text: WideString; FirstPart: Integer; LastPart: Integer; const Delimiters: WideString): WideString; // @addr $4C2F2C @note "Includes both zero-based part indexes and the separators between them."
function ExtractNextDelimitedPartW(var Text: WideString; Delimiter: WideChar): WideString; // @addr $4C2F84 @note "Removes the returned prefix and first delimiter from Text; without a delimiter returns all of Text and clears it."
function ExtractLineCommentW(const Text: WideString): WideString; // @addr $4C3014 @note "Returns the first // and following text, including immediately preceding spaces, tabs, CR and LF. Empty when absent; does not recognize quoting."
function RemoveLineCommentW(const Text: WideString): WideString; // @addr $4C3088 @note "Removes the first // and following text, then trims trailing characters <= #32. Without // returns Text unchanged; does not recognize quoting."
function ReplaceAllWideString(const Text: WideString; const Search: WideString; const Replacement: WideString): WideString; // @addr $4C33C4 @note "Case-sensitive, non-overlapping replacement; empty Search returns Text unchanged."
function FindTextOffsetW(const Text: WideString; const Search: WideString; StartIndex: Integer = 0): Integer; // @addr $4C3BC8 @note "Zero-based start and result; starts at a nonnegative character offset and returns -1 when absent."
function FindTextPosW(const Search: WideString; const Text: WideString): Integer; // @addr $4C3C70 @note "One-based result, with Search before Text as in Pos; returns zero when absent."
function ExtractDigitsToIntW(const Text: WideString): Integer; // @addr $4C3164 @note "Ignores signs and other nondigits; unchecked 32-bit arithmetic."
function IsIntegerTextW(const Text: WideString): Boolean; // @addr $4C311C @note "True for any nonempty string containing only digits and minus signs, including '-' and '1--2'; does not validate numeric syntax or range."
function ExtractDecimalToSingleW(const Text: WideString): Single; // @addr $4C31F8 @note "Accepts '.' as the decimal separator; ignores other nondigits and treats any '-' as negative. No exponent syntax."
function ParseDecimalToSingleW(const Text: WideString): Single; // @addr $4C32DC @note "Accepts '.' or ','; accumulation and the result use Single precision."
function CardinalToHexWideString(Value: Cardinal): WideString; // @addr $4C34D8 @note "Lowercase hexadecimal without a prefix or padding; zero becomes '0'."
function IntToFixedWidthWideString(Value: Integer; Width: Integer): WideString; // @addr $4C3570 @note "Left-pads with zeros or keeps only the leftmost Width digits. Nonpositive Value produces zeros; nonpositive Width produces an empty string."
function BoolToWideString(Value: Boolean): WideString; // @addr $4C3634 @note "Returns 'True' or 'False'."
function TrimWideString(const Text: WideString): WideString; // @addr $4C3890 @note "Trims only spaces, tabs, CR, LF and NUL characters at both ends."
function UpperCaseWideString(const Text: WideString): WideString; // @addr $4C3948 @note "Uses the language CaseConv table; characters absent from it remain unchanged."
function LowerCaseWideString(const Text: WideString): WideString; // @addr $4C39C4 @note "Uses the language CaseConv table in reverse; characters absent from it remain unchanged."
function GetTextTagLengthW(Text: PWideChar; CharCount: Integer): Integer; // @addr $4C3A3C @note "Returns the leading <...> token length, 1 for leading <<, or zero when no complete tag is present."
function RemoveTextTagsW(Text: WideString): WideString; // @addr $4C3A78 @note "Removes complete <...> tokens; leading << consumes one character and scanning resumes at the second <. Incomplete tags remain."
function CompareWideChars(Left: PWideChar; Right: PWideChar): Integer; cdecl; // @addr $4C3B24 @note "Case-sensitive NUL-terminated comparison returning -1, 0 or 1. Nil sorts before every nonnil pointer, including an empty string."

function HasWidePrefix(const Text, Prefix: WideString): Boolean; // @addr $4C3B7C @note "Case-sensitive byte comparison; empty Prefix matches."
function ExtractFileNameW(const Path: WideString): WideString; // @addr $4C3C88
function ExtractFileNameNoExtW(const Path: WideString): WideString; // @addr $4C3CC0 @note "Accepts slash and backslash; strips only the final dot and suffix from the last path component."
function ExtractFileExtNoDotW(const Path: WideString): WideString; // @addr $4C3D64 @note "Accepts slash and backslash; returns text after the last dot in the final component, or empty when absent."
function ExtractFileDirW(const Path: WideString): WideString; // @addr $4C3E0C @note "Accepts slash and backslash; excludes the final separator and component."

const
  HexDigits: THexDigits = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'); // @addr $6183EC

function PadOrTruncateAnsiString(Value: AnsiString; Width: Integer): AnsiString; // @addr $4C3678
function AnsiStringToOem(Value: AnsiString): AnsiString; // @addr $4C3828
implementation

// @unit-initialization $4C3E84
// @unit-finalization $4C3E54

uses EC_Mem, GR_Main, SysUtils, Windows;

{ @routine $4C285C TStringsEC_Create }
constructor TStringsEC.Create;
begin
  inherited Create;
end;
{ @end $4C285C }

{ @routine $4C2894 TStringsEC_Destroy }
destructor TStringsEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4C2894 }

{ @routine $4C28C0 TStringsEC_Clear }
procedure TStringsEC.Clear;
begin
  while FirstElement <> nil do RemoveAndFreeElement(LastElement);
  CurrentElement := nil;
end;
{ @end $4C28C0 }

{ @routine $4C28DC TStringsEC_AddEmptyElement }
function TStringsEC.AddEmptyElement: TStringsElEC;
var Item: TStringsElEC;
begin
  Item := TStringsElEC.Create;
  AppendElement(Item);
  Result := Item;
end;
{ @end $4C28DC }

{ @routine $4C28FC TStringsEC_AppendElement }
procedure TStringsEC.AppendElement(Item: TStringsElEC);
begin
  if LastElement <> nil then LastElement.Next := Item;
  Item.Prev := LastElement;
  Item.Next := nil;
  LastElement := Item;
  if FirstElement = nil then FirstElement := Item;
end;
{ @end $4C28FC }

{ @routine $4C2920 TStringsEC_RemoveAndFreeElement }
procedure TStringsEC.RemoveAndFreeElement(Item: TStringsElEC);
begin
  if Item.Prev <> nil then Item.Prev.Next := Item.Next;
  if Item.Next <> nil then Item.Next.Prev := Item.Prev;
  if LastElement = Item then LastElement := Item.Prev;
  if FirstElement = Item then FirstElement := Item.Next;
  Item.Free;
end;
{ @end $4C2920 }

{ @routine $4C295C TStringsEC_EnsureElement }
function TStringsEC.EnsureElement(Index: Integer): TStringsElEC;
var Item: TStringsElEC;
begin
  if Index < 0 then raise Exception.Create('TStringsEC.El_GetEx. i=' + SysUtils.IntToStr(Index));
  Item := FirstElement;
  while Item <> nil do
  begin
    if Index = 0 then
    begin
      Result := Item;
      Exit;
    end;
    Dec(Index);
    Item := Item.Next;
  end;
  while Index >= 0 do
  begin
    AddEmptyElement;
    Dec(Index);
  end;
  Result := LastElement;
end;
{ @end $4C295C }

{ @routine $4C2A20 TStringsEC_GetCount }
function TStringsEC.GetCount: Integer;
var Item: TStringsElEC;
begin
  Item := FirstElement;
  Result := 0;
  while Item <> nil do
  begin
    Inc(Result);
    Item := Item.Next;
  end;
end;
{ @end $4C2A20 }

{ @routine $4C2A34 TStringsEC_GetTextAt }
function TStringsEC.GetTextAt(Index: Integer): WideString;
begin
  Result := EnsureElement(Index).Text;
end;
{ @end $4C2A34 }

{ @routine $4C2A54 TStringsEC_GetDataAt }
function TStringsEC.GetDataAt(Index: Integer): Pointer;
begin
  Result := EnsureElement(Index).Data;
end;
{ @end $4C2A54 }

{ @routine $4C2A6C TStringsEC_SetDataAt }
procedure TStringsEC.SetDataAt(Index: Integer; Data: Pointer);
begin
  EnsureElement(Index).Data := Data;
end;
{ @end $4C2A6C }

{ @routine $4C2A88 TStringsEC_Add }
procedure TStringsEC.Add(const Text: WideString);
begin
  AddEmptyElement.Text := Text;
end;
{ @end $4C2A88 }

{ @routine $4C2AA4 TStringsEC_AddSlice }
procedure TStringsEC.AddSlice(Text: PWideChar; CharCount: Integer);
var Item: TStringsElEC;
begin
  Item := AddEmptyElement;
  if CharCount > 0 then
  begin
    SetLength(Item.Text, CharCount);
    CopyMemory(PWideChar(Item.Text), Text, CharCount * SizeOf(WideChar));
  end;
end;
{ @end $4C2AA4 }

{ @routine $4C2AD8 TStringsEC_GetCurrentText }
function TStringsEC.GetCurrentText: WideString;
begin
  if CurrentElement = nil then raise Exception.Create('TStringsEC.Get.');
  Result := CurrentElement.Text;
end;
{ @end $4C2AD8 }

{ @routine $4C2B24 TStringsEC_GetCurrentData }
function TStringsEC.GetCurrentData: Pointer;
begin
  if CurrentElement = nil then raise Exception.Create('TStringsEC.GetData.');
  Result := CurrentElement.Data;
end;
{ @end $4C2B24 }

{ @routine $4C2B64 TStringsEC_IsAtEnd }
function TStringsEC.IsAtEnd: Boolean;
begin
  if CurrentElement <> nil then Result := False else Result := True;
end;
{ @end $4C2B64 }

{ @routine $4C2B70 TStringsEC_IsAtLast }
function TStringsEC.IsAtLast: Boolean;
begin
  if CurrentElement.Next <> nil then Result := False else Result := True;
end;
{ @end $4C2B70 }

{ @routine $4C2B80 TStringsEC_First }
procedure TStringsEC.First;
begin
  CurrentElement := FirstElement;
end;
{ @end $4C2B80 }

{ @routine $4C2B88 TStringsEC_Next }
procedure TStringsEC.Next;
begin
  CurrentElement := CurrentElement.Next;
end;
{ @end $4C2B88 }

{ @routine $4C2B94 TStringsEC_IsEmpty }
function TStringsEC.IsEmpty: Boolean;
begin
  Result := FirstElement = nil;
end;
{ @end $4C2B94 }

{ @routine $4C2B9C TStringsEC_SetText }
procedure TStringsEC.SetText(const Text: WideString);
var Cursor, Start: PWideChar;
begin
  Clear;
  Cursor := PWideChar(Text);
  if Cursor <> nil then
    while Cursor^ <> #0 do
    begin
      Start := Cursor;
      while (Cursor^ <> #0) and (Cursor^ <> #10) and (Cursor^ <> #13) do Inc(Cursor);
      AddSlice(Start, Integer(PAnsiChar(Cursor) - PAnsiChar(Start)) div SizeOf(WideChar));
      if Cursor^ = #13 then Inc(Cursor);
      if Cursor^ = #10 then Inc(Cursor);
    end;
end;
{ @end $4C2B9C }

{ @routine $4C2C00 TStringsEC_GetText }
function TStringsEC.GetText: WideString;
var Item: TStringsElEC;
begin
  Item := FirstElement;
  Result := '';
  while Item <> nil do
  begin
    if Item.Next = nil then Result := Result + Item.Text
    else Result := Result + Item.Text + #13 + #10;
    Item := Item.Next;
  end;
end;
{ @end $4C2C00 }

{ @routine $4C2C5C CountDelimitedPartsW }
function CountDelimitedPartsW(const Text: WideString; const Delimiters: WideString): Integer;
var TextLength, DelimiterCount, i, j, Count: Integer;
begin
  Count := 1;
  TextLength := Length(Text);
  DelimiterCount := Length(Delimiters);
  if Cardinal(TextLength) < 1 then begin Result := 0; Exit end;
  for i := 1 to TextLength do
    for j := 1 to DelimiterCount do
      if Text[i] = Delimiters[j] then
      begin
        Inc(Count);
        Break;
      end;
  Result := Count;
end;
{ @end $4C2C5C }

{ @routine $4C2CCC GetDelimitedPartStartIndexW }
function GetDelimitedPartStartIndexW(const Text: WideString; PartIndex: Integer; const Delimiters: WideString): Integer;
var TextLength, DelimiterCount, i, j: Integer;
begin
  if PartIndex > 0 then
  begin
    TextLength := Length(Text);
    DelimiterCount := Length(Delimiters);
    for i := 1 to TextLength do
      for j := 1 to DelimiterCount do
        if Text[i] = Delimiters[j] then
        begin
          Dec(PartIndex);
          if PartIndex = 0 then begin Result := i + 1; Exit end;
          Break;
        end;
    raise Exception.Create('GetSmeParEC. Str=' + Text + ' np=' + SysUtils.IntToStr(PartIndex) + ' raz=' + Delimiters);
  end;
  Result := 1;
end;
{ @end $4C2CCC }

{ @routine $4C2E3C GetCharDelimitedPartStartIndexW }
function GetCharDelimitedPartStartIndexW(const Text: WideString; PartIndex: Integer; Delimiter: WideChar): Integer;
var TextLength, i: Integer;
begin
  if PartIndex > 0 then
  begin
    TextLength := Length(Text);
    for i := 1 to TextLength do
      if Text[i] = Delimiter then
      begin
        Dec(PartIndex);
        if PartIndex = 0 then begin Result := i + 1; Exit end;
        Break;
      end;
    Result := -1;
    Exit;
  end;
  Result := 1;
end;
{ @end $4C2E3C }

{ @routine $4C2E7C GetDelimitedPartLengthW }
function GetDelimitedPartLengthW(const Text: WideString; StartIndex: Integer; const Delimiters: WideString): Integer;
var TextLength, DelimiterCount, i, j: Integer;
begin
  TextLength := Length(Text);
  DelimiterCount := Length(Delimiters);
  for i := StartIndex to TextLength do
    for j := 1 to DelimiterCount do
      if Text[i] = Delimiters[j] then
      begin
        Result := i - StartIndex;
        Exit;
      end;
  Result := TextLength - StartIndex + 1;
end;
{ @end $4C2E7C }

{ @routine $4C2EEC ExtractDelimitedPartW }
function ExtractDelimitedPartW(const Text: WideString; PartIndex: Integer; const Delimiters: WideString): WideString;
var StartIndex: Integer;
begin
  StartIndex := GetDelimitedPartStartIndexW(Text, PartIndex, Delimiters);
  Result := Copy(Text, StartIndex, GetDelimitedPartLengthW(Text, StartIndex, Delimiters));
end;
{ @end $4C2EEC }

{ @routine $4C2F2C ExtractDelimitedRangeW }
function ExtractDelimitedRangeW(const Text: WideString; FirstPart: Integer; LastPart: Integer; const Delimiters: WideString): WideString;
var StartIndex, EndIndex: Integer;
begin
  StartIndex := GetDelimitedPartStartIndexW(Text, FirstPart, Delimiters);
  EndIndex := GetDelimitedPartStartIndexW(Text, LastPart, Delimiters);
  EndIndex := EndIndex + GetDelimitedPartLengthW(Text, EndIndex, Delimiters);
  Result := Copy(Text, StartIndex, EndIndex - StartIndex);
end;
{ @end $4C2F2C }

{ @routine $4C2F84 ExtractNextDelimitedPartW }
function ExtractNextDelimitedPartW(var Text: WideString; Delimiter: WideChar): WideString;
var StartIndex, i, TextLength: Integer;
begin
  StartIndex := GetCharDelimitedPartStartIndexW(Text, 1, Delimiter);
  if StartIndex < 0 then
  begin
    Result := Text;
    Text := '';
    Exit;
  end;
  if StartIndex >= 3 then Result := Copy(Text, 1, StartIndex - 2)
  else Result := '';
  TextLength := Length(Text);
  for i := StartIndex to TextLength do Text[i - (StartIndex - 1)] := Text[i];
  SetLength(Text, TextLength - (StartIndex - 1));
end;
{ @end $4C2F84 }

{ @routine $4C3014 ExtractLineCommentW }
function ExtractLineCommentW(const Text: WideString): WideString;
var Position, i: Integer;
begin
  Position := Pos('//', Text);
  if Position < 1 then begin Result := ''; Exit end;
  i := Position - 1;
  while i >= 1 do
  begin
    if (Text[i] <> ' ') and (Text[i] <> #9) and (Text[i] <> #13) and (Text[i] <> #10) then Break;
    Dec(i);
  end;
  Result := Copy(Text, i + 1, Length(Text) - i);
end;
{ @end $4C3014 }

{ @routine $4C3088 RemoveLineCommentW }
function RemoveLineCommentW(const Text: WideString): WideString;
var Position: Integer;
begin
  Position := Pos('//', Text);
  if Position < 1 then begin Result := Text; Exit end;
  if Position = 1 then begin Result := ''; Exit end;
  Result := SysUtils.TrimRight(Copy(Text, 1, Position - 1));
end;
{ @end $4C3088 }

{ @routine $4C311C IsIntegerTextW }
function IsIntegerTextW(const Text: WideString): Boolean;
var TextLength, i: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then begin Result := False; Exit end;
  for i := 1 to TextLength do
    if ((Text[i] < '0') or (Text[i] > '9')) and (Text[i] <> '-') then
    begin Result := False; Exit end;
  Result := True;
end;
{ @end $4C311C }

{ @routine $4C3164 ExtractDigitsToIntW }
function ExtractDigitsToIntW(const Text: WideString): Integer;
var TextLength, i: Integer;
begin
  Result := 0;
  TextLength := Length(Text);
  for i := 1 to TextLength do
    if (Integer(Text[i]) >= Ord('0')) and (Integer(Text[i]) <= Ord('9')) then
      Result := SysUtils.StrToInt(Text[i]) + Result * 10;
end;
{ @end $4C3164 }

{ @routine $4C31F8 ExtractDecimalToSingleW }
function ExtractDecimalToSingleW(const Text: WideString): Single;
var i, TextLength: Integer; Value, Divisor: Single; Code: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then begin Result := 0; Exit end;
  Value := 0;
  for i := 0 to TextLength - 1 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then Value := Value * 10 + (Code - Ord('0'))
    else if Code = Ord('.') then Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
    begin
      Value := (Code - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to TextLength - 1 do
    if Integer(PWideChar(Pointer(Text))[i]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;
{ @end $4C31F8 }

{ @routine $4C32DC ParseDecimalToSingleW }
function ParseDecimalToSingleW(const Text: WideString): Single;
var i, TextLength: Integer; Value, Divisor: Single; Code: Integer;
begin
  TextLength := Length(Text);
  if TextLength < 1 then begin Result := 0; Exit end;
  Value := 0;
  for i := 0 to TextLength - 1 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then Value := Value * 10 + (Code - Ord('0'))
    else if (Code = Ord('.')) or (Code = Ord(',')) then Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[i]);
    if (Code >= Ord('0')) and (Code <= Ord('9')) then
    begin
      Value := (Code - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to TextLength - 1 do
    if Integer(PWideChar(Pointer(Text))[i]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;
{ @end $4C32DC }

{ @routine $4C33C4 ReplaceAllWideString }
function ReplaceAllWideString(const Text, Search, Replacement: WideString): WideString;
var TextLength, SearchLength, i, j: Integer;
begin
  Result := '';
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if (TextLength < SearchLength) or (TextLength < 1) or (SearchLength < 1) then
  begin Result := Text; Exit end;
  i := 0;
  while i <= TextLength - SearchLength do
  begin
    j := 0;
    while j < SearchLength do
    begin
      if PWideChar(Pointer(Text))[i + j] <> PWideChar(Pointer(Search))[j] then Break;
      Inc(j);
    end;
    if j >= SearchLength then
    begin
      Result := Result + Replacement;
      Inc(i, SearchLength);
    end
    else
    begin
      Result := Result + PWideChar(Pointer(Text))[i];
      Inc(i);
    end;
  end;
  if i < TextLength then Result := Result + Copy(Text, i + 1, TextLength - i);
end;
{ @end $4C33C4 }

{ @routine $4C34D8 CardinalToHexWideString }
function CardinalToHexWideString(Value: Cardinal): WideString;
begin
  Result := '';
  while Value <> 0 do
  begin
    Result := HexDigits[Value - (Value div 16) * 16] + Result;
    Value := Value div 16;
  end;
  if Result = '' then Result := '0';
end;
{ @end $4C34D8 }

{ @routine $4C3570 IntToFixedWidthWideString }
function IntToFixedWidthWideString(Value, Width: Integer): WideString;
var Digit, i, TextLength: Integer;
begin
  Result := '';
  while Value > 0 do
  begin
    Digit := Value;
    Value := Value div 10;
    Digit := Digit - Value * 10;
    Result := Chr(Digit + Ord('0')) + Result;
  end;
  TextLength := Length(Result);
  if TextLength < Width then
    for i := 0 to Width - TextLength - 1 do Result := '0' + Result
  else Result := Copy(Result, 0, Width);
end;
{ @end $4C3570 }

{ @routine $4C3634 BoolToWideString }
function BoolToWideString(Value: Boolean): WideString;
begin
  if not Value then Result := 'False' else Result := 'True';
end;
{ @end $4C3634 }

{ @routine $4C3678 PadOrTruncateAnsiString }
function PadOrTruncateAnsiString(Value: AnsiString; Width: Integer): AnsiString;
var Count: Integer;
begin
  Count := Length(Value);
  if Count > Width then Result := Copy(Value, 1, Width)
  else if Count = Width then Result := Value
  // Native padding is limited to this 255-character literal, even for larger widths.
  else Result := Value + Copy('                                                                                                                                                                                                                                                               ', 1, Width - Count);
end;
{ @end $4C3678 }

{ @routine $4C3828 AnsiStringToOem }
function AnsiStringToOem(Value: AnsiString): AnsiString;
begin
  // Native converts in place without a uniqueness check.
  CharToOemBuffA(PAnsiChar(Value), PAnsiChar(Value), Length(Value));
  Result := Value;
end;
{ @end $4C3828 }

{ @routine $4C3890 TrimWideString }
function TrimWideString(const Text: WideString): WideString;
var Code, TextLength, FirstIndex, LastIndex: Integer;
begin
  TextLength := Length(Text);
  FirstIndex := 0;
  while FirstIndex < TextLength do
  begin
    Code := Integer(PWideChar(Pointer(Text))[FirstIndex]);
    if (Code <> Ord(' ')) and (Code <> 9) and (Code <> 13) and (Code <> 10) and (Code <> 0) then Break;
    Inc(FirstIndex);
  end;
  if FirstIndex >= TextLength then begin Result := ''; Exit end;
  LastIndex := TextLength - 1;
  while LastIndex >= 0 do
  begin
    Code := Integer(PWideChar(Pointer(Text))[LastIndex]);
    if (Code <> Ord(' ')) and (Code <> 9) and (Code <> 13) and (Code <> 10) and (Code <> 0) then Break;
    Dec(LastIndex);
  end;
  if LastIndex < FirstIndex then begin Result := ''; Exit end;
  SetLength(Result, LastIndex - FirstIndex + 1);
  CopyMemory(PWideChar(Result), AddPointerOffset(PWideChar(Text), FirstIndex * 2), (LastIndex - FirstIndex + 1) * 2);
end;
{ @end $4C3890 }

{ @routine $4C3948 UpperCaseWideString }
function UpperCaseWideString(const Text: WideString): WideString;
var TextLength, PairCount, i, j: Integer;
begin
  Result := Text;
  TextLength := Length(Result);
  PairCount := High(WideCaseTable) + 1;
  for i := 0 to TextLength - 1 do
    for j := 0 to PairCount - 1 do
      if PWideChar(Pointer(Result))[i] = WideCaseTable[j].LowerChar then
      begin
        Result[i + 1] := WideCaseTable[j].UpperChar;
        Break;
      end;
end;
{ @end $4C3948 }

{ @routine $4C39C4 LowerCaseWideString }
function LowerCaseWideString(const Text: WideString): WideString;
var TextLength, PairCount, i, j: Integer;
begin
  Result := Text;
  TextLength := Length(Result);
  PairCount := High(WideCaseTable) + 1;
  for i := 0 to TextLength - 1 do
    for j := 0 to PairCount - 1 do
      if PWideChar(Pointer(Result))[i] = WideCaseTable[j].UpperChar then
      begin
        Result[i + 1] := WideCaseTable[j].LowerChar;
        Break;
      end;
end;
{ @end $4C39C4 }

{ @routine $4C3A3C GetTextTagLengthW }
function GetTextTagLengthW(Text: PWideChar; CharCount: Integer): Integer;
var i: Integer;
begin
  Result := 0;
  if (CharCount < 2) or (Text[0] <> '<') then Exit;
  if Text[1] = '<' then begin Result := 1; Exit end;
  i := 1;
  while i < CharCount do
  begin
    if Text[i] = '>' then Break;
    Inc(i);
  end;
  if i < CharCount then Result := i + 1;
end;
{ @end $4C3A3C }

{ @routine $4C3A78 RemoveTextTagsW }
function RemoveTextTagsW(Text: WideString): WideString;
var i, TagLength: Integer;
begin
  Result := '';
  i := 0;
  while i < Length(Text) do
  begin
    TagLength := GetTextTagLengthW(PWideChar(Text) + i, Length(Text) - i);
    if TagLength > 0 then Inc(i, TagLength)
    else
    begin
      Result := Result + Text[Succ(i)];
      Inc(i);
    end;
  end;
end;
{ @end $4C3A78 }

{ @routine $4C3B24 CompareWideChars }
function CompareWideChars(Left, Right: PWideChar): Integer; cdecl;
asm
  PUSH ESI
  PUSH EDI
  PUSH EBX
  PUSH EDX
  MOV ESI, Left
  MOV EDI, Right
  TEST ESI, ESI
  JNZ @@HaveLeft
  MOV EAX, -1
  TEST EDI, EDI
  JNZ @@Done
  XOR EAX, EAX
  JMP @@Done
@@HaveLeft:
  TEST EDI, EDI
  JNZ @@Next
  MOV EAX, 1
  JMP @@Done
@@Next:
  MOV BX, [ESI]
  MOV DX, [EDI]
  ADD ESI, 2
  ADD EDI, 2
  CMP BX, DX
  JNZ @@Different
  XOR EAX, EAX
  TEST DX, DX
  JNZ @@Next
  JMP @@Done
@@Different:
  MOV EAX, 1
  JA @@Done
  MOV EAX, -1
@@Done:
  POP EDX
  POP EBX
  POP EDI
  POP ESI
end;
{ @end $4C3B24 }

{ @routine $4C3B7C HasWidePrefix }
function HasWidePrefix(const Text, Prefix: WideString): Boolean;
var TextLength, PrefixLength: Integer;
begin
  TextLength := Length(Text);
  PrefixLength := Length(Prefix);
  if TextLength < PrefixLength then Result := False
  else if (TextLength < 1) and (PrefixLength < 1) then Result := True
  else Result := CompareMem(PWideChar(Text), PWideChar(Prefix), PrefixLength * 2);
end;
{ @end $4C3B7C }

{ @routine $4C3BC8 FindTextOffsetW }
function FindTextOffsetW(const Text, Search: WideString; StartIndex: Integer): Integer;
var TextLength, SearchLength: Integer; TextPtr, SearchPtr: PWideChar;
begin
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if TextLength - StartIndex < SearchLength then begin Result := -1; Exit end;
  if (TextLength < 1) and (SearchLength < 1) then begin Result := -1; Exit end;
  TextPtr := PWideChar(Text);
  SearchPtr := PWideChar(Search);
  if SearchLength = 1 then
  begin
    while StartIndex <= TextLength - SearchLength do
    begin
      if PWideChar(StartIndex * SizeOf(WideChar) + PAnsiChar(TextPtr))^ = SearchPtr^ then begin Result := StartIndex; Exit end;
      Inc(StartIndex);
    end;
  end
  else
    while StartIndex <= TextLength - SearchLength do
    begin
      if SysUtils.CompareMem(Pointer(StartIndex * SizeOf(WideChar) + PAnsiChar(TextPtr)), SearchPtr, SearchLength * 2) then
      begin Result := StartIndex; Exit end;
      Inc(StartIndex);
    end;
  Result := -1;
end;
{ @end $4C3BC8 }

{ @routine $4C3C70 FindTextPosW }
function FindTextPosW(const Search, Text: WideString): Integer;
begin
  Result := FindTextOffsetW(Text, Search) + 1;
end;
{ @end $4C3C70 }

{ @routine $4C3C88 ExtractFileNameW }
function ExtractFileNameW(const Path: WideString): WideString;
var Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  Result := ExtractDelimitedPartW(Path, Count - 1, '\/');
end;
{ @end $4C3C88 }

{ @routine $4C3CC0 ExtractFileNameNoExtW }
function ExtractFileNameNoExtW(const Path: WideString): WideString;
var Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  Result := ExtractDelimitedPartW(Path, Count - 1, '\/');
  Count := CountDelimitedPartsW(Result, '.');
  if Count > 1 then Result := ExtractDelimitedRangeW(Result, 0, Count - 2, '.');
end;
{ @end $4C3CC0 }

{ @routine $4C3D64 ExtractFileExtNoDotW }
function ExtractFileExtNoDotW(const Path: WideString): WideString;
var Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  Result := ExtractDelimitedPartW(Path, Count - 1, '\/');
  Count := CountDelimitedPartsW(Result, '.');
  if Count > 1 then Result := ExtractDelimitedPartW(Result, Count - 1, '.')
  else Result := '';
end;
{ @end $4C3D64 }

{ @routine $4C3E0C ExtractFileDirW }
function ExtractFileDirW(const Path: WideString): WideString;
var Count: Integer;
begin
  Count := CountDelimitedPartsW(Path, '\/');
  if Count < 1 then begin Result := ''; Exit end;
  Result := ExtractDelimitedRangeW(Path, 0, Count - 2, '\/');
end;
{ @end $4C3E0C }

end.

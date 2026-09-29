unit aQuestValueListClass;
// Unit bracket (inferred): CODE 0x004D0004..0x004D082F; inclusive evidence, not full bounds.
// Field layouts follow the native protection traversals at $5E98EC and $5EB564.
interface
uses EC_Buf;
type
  TValuesList = class(TObject) // @size $10
  public
    function ReplaceText(Text, Search, Replacement: AnsiString): AnsiString; // @addr $4D009C
    function NormalizeSemicolonText(Text: AnsiString): AnsiString; // @addr $4D01D8
    function ValidateText(Text: AnsiString): Boolean; // @addr $4D05E0
    procedure LoadFromReader(Reader: TBufEC); // @addr $4D055C
    procedure LoadFromSemicolonText(Text: AnsiString); // @addr $4D064C
    procedure Clear; // @addr $4D05B8
    destructor Destroy; override; // @addr $4D0534
    constructor Create; // @addr $4D04F8
    AcceptListed: Boolean; // @offset $04
    Values: array of Integer; // @offset $8
    Count: Integer; // @offset $0C
  end;
implementation

// @unit-initialization $4D0828
// @unit-finalization $4D07F8

uses SysUtils, Dialogs;

{ @routine $4D009C TValuesList_ReplaceText }
function TValuesList.ReplaceText(Text, Search, Replacement: AnsiString): AnsiString;
var
  Index, CompareIndex, TextLength, SearchLength: Integer;
begin
  Result := '';
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if (SearchLength > TextLength) or (TextLength < 1) or (SearchLength < 1) then begin
    Result := Text;
    Exit;
  end;
  Index := 0;
  while Index <= TextLength - SearchLength do begin
    CompareIndex := 0;
    while CompareIndex < SearchLength do begin
      if Text[Index + CompareIndex + 1] <> Search[CompareIndex + 1] then Break;
      Inc(CompareIndex);
    end;
    if CompareIndex >= SearchLength then begin
      Result := Result + Replacement;
      Inc(Index, SearchLength);
    end else begin
      Result := Result + Text[Index + 1];
      Inc(Index);
    end;
  end;
  if Index < TextLength then Result := Result + Copy(Text, Index + 1, TextLength - Index);
end;
{ @end $4D009C }

{ @routine $4D01D8 TValuesList_NormalizeSemicolonText }
function TValuesList.NormalizeSemicolonText(Text: AnsiString): AnsiString;
var
  I: Integer;
  Normalized: AnsiString;
begin
  Normalized := '';
  for I := 1 to Length(Text) do
    if (Text[I] in ['0'..'9']) or (Text[I] = ';') or (Text[I] = ',') or (Text[I] = '-') then
      Normalized := Normalized + Text[I];
  Text := Normalized;
  Normalized := '(' + Text + ')';
  repeat
    Text := Normalized;
    Normalized := ReplaceText(Normalized, ',', ';');
    Normalized := ReplaceText(Normalized, ';;', ';');
    Normalized := ReplaceText(Normalized, '-;', ';');
    Normalized := ReplaceText(Normalized, '--', '');
    Normalized := ReplaceText(Normalized, '(-;', '(');
    Normalized := ReplaceText(Normalized, '(-)', '(');
    Normalized := ReplaceText(Normalized, '(;', '(');
    Normalized := ReplaceText(Normalized, ';-)', ')');
    Normalized := ReplaceText(Normalized, ';)', ')');
  until Text = Normalized;
  Text := ReplaceText(Text, '(', '');
  Text := ReplaceText(Text, ')', '');
  Result := Text;
end;
{ @end $4D01D8 }

{ @routine $4D04F8 TValuesList_Create }
constructor TValuesList.Create;
begin
  inherited Create;
  Clear;
end;
{ @end $4D04F8 }

{ @routine $4D0534 TValuesList_Destroy }
destructor TValuesList.Destroy;
begin
  inherited Destroy;
end;
{ @end $4D0534 }

{ @routine $4D055C TValuesList_LoadFromReader }
procedure TValuesList.LoadFromReader(Reader: TBufEC);
var I: Integer;
begin
  Count := Reader.GetInt32;
  AcceptListed := Reader.GetBoolean;
  SetLength(Values, Count + 2);
  for I := 1 to Count do Values[I] := Reader.GetInt32;
end;
{ @end $4D055C }

{ @routine $4D05B8 TValuesList_Clear }
procedure TValuesList.Clear;
begin
  SetLength(Values, 1);
  Count := 0;
  AcceptListed := False;
end;
{ @end $4D05B8 }

{ @routine $4D05E0 TValuesList_ValidateText }
function TValuesList.ValidateText(Text: AnsiString): Boolean;
begin
  // The original validator only normalizes and always returns True.
  Result := True;
  Text := NormalizeSemicolonText(Text);
end;
{ @end $4D05E0 }

{ @routine $4D064C TValuesList_LoadFromSemicolonText }
procedure TValuesList.LoadFromSemicolonText(Text: AnsiString);
var
  I: Integer;
  NumberText: AnsiString;
  ParsedValues: array[1..200] of Integer;
begin
  Clear;
  I := 1;
  Count := 0;
  NumberText := '';
  Text := Trim(NormalizeSemicolonText(Text));
  if ValidateText(Text) then begin
    while I <= Length(Text) do begin
      if Text[I] <> ';' then NumberText := NumberText + Text[I];
      if (I = Length(Text)) or (Text[I + 1] = ';') then begin
        Inc(Count);
        // Native fixed buffer has no overflow check.
        ParsedValues[Count] := StrToInt(NumberText);
        NumberText := '';
      end;
      Inc(I);
    end;
    SetLength(Values, Count + 2);
    for I := 1 to Count do Values[I] := ParsedValues[I];
  end else ShowMessage('Формат списка неправилен');
end;
{ @end $4D064C }

end.

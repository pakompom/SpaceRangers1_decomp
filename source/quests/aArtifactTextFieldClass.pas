unit aArtifactTextFieldClass;
// Unit bracket (inferred): CODE 0x004CFE54..0x004CFFFF; inclusive evidence, not full bounds.
interface
uses EC_Buf;
type
  TTextField = class(TObject) // @size $08 Native VMT $4CFE54.
  public
    procedure LoadTextLinesFromReader(Reader: TBufEC); // @addr $4CFED0 @note "Preserves whitespace and inserts CRLF between counted lines."
    procedure ClearText; // @addr $4CFEC0
    Text: WideString; // @offset $04
  end;
implementation

// @unit-initialization $4CFFF8
// @unit-finalization $4CFFC8

{ @routine $4CFEC0 TTextField_ClearText }
procedure TTextField.ClearText;
begin
  Text := '';
end;
{ @end $4CFEC0 }

{ @routine $4CFED0 TTextField_LoadTextLinesFromReader }
procedure TTextField.LoadTextLinesFromReader(Reader: TBufEC);
var Line: WideString; I, J, LineCount, CharCount: Integer;
begin
  Text := '';
  LineCount := Reader.GetInt32;
  for I := 1 to LineCount do begin
    CharCount := Reader.GetInt32;
    if I < LineCount then SetLength(Line, CharCount + 2)
    else SetLength(Line, CharCount);
    for J := 1 to CharCount do Line[J] := Reader.GetWideChar;
    if I < LineCount then begin
      Line[CharCount + 1] := #13;
      Line[CharCount + 2] := #10;
    end;
    Text := Text + Line;
  end;
end;
{ @end $4CFED0 }

end.

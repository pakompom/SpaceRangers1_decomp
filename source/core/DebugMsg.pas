unit DebugMsg;
// Unit bracket (inferred): CODE 0x00453470..0x004536DF; inclusive evidence, not full bounds.
// DebugMsg.dll adapter. PACKAGEINFO names DebugMsg; the native startup
// window $453470..$4536E0 contains these imports and string wrappers.
interface
type TDebugCommand = Pointer;
function DCGet(Names: PWideChar): TDebugCommand; cdecl; external 'DebugMsg.dll' name 'DCGet'; // @addr $453470
procedure DCFree(Command: TDebugCommand); cdecl; external 'DebugMsg.dll' name 'DCFree'; // @addr $453478
function DCNameI(Command: TDebugCommand): Integer; cdecl; external 'DebugMsg.dll' name 'DCNameI'; // @addr $453480
function DCCnt(Command: TDebugCommand): Integer; cdecl; external 'DebugMsg.dll' name 'DCCnt'; // @addr $453488
function DCStrW(Command: TDebugCommand): PWideChar; cdecl; external 'DebugMsg.dll' name 'DCStrW'; // @addr $453490
function DCInt(Command: TDebugCommand): Integer; cdecl; external 'DebugMsg.dll' name 'DCInt'; // @addr $453498
function DCFloat(Command: TDebugCommand): Double; cdecl; external 'DebugMsg.dll' name 'DCFloat'; // @addr $4534A0
procedure DCAnswerW(Command: TDebugCommand; Text: PWideChar); cdecl; external 'DebugMsg.dll' name 'DCAnswerW'; // @addr $4534A8
procedure DCAnswerA(Command: TDebugCommand; Text: PAnsiChar); cdecl; external 'DebugMsg.dll' name 'DCAnswerA'; // @addr $4534B0
procedure AnswerDebugText(Command: TDebugCommand; const Text: AnsiString); // @addr $4534B8
procedure AnswerDebugWideText(Command: TDebugCommand; const Text: WideString); // @addr $4534D4
function AlignDebugColumn(const Text: WideString; Width, Alignment: Integer; Padding: WideChar): WideString; // @addr $4534F0
implementation

// @unit-initialization $4536D8
// @unit-finalization $4536A8

uses Windows;

{ @routine $4534B8 AnswerDebugText }
procedure AnswerDebugText(Command: TDebugCommand; const Text: AnsiString);
begin
  DCAnswerA(Command, PAnsiChar(Text));
end;
{ @end $4534B8 }

{ @routine $4534D4 AnswerDebugWideText }
procedure AnswerDebugWideText(Command: TDebugCommand; const Text: WideString);
begin
  DCAnswerW(Command, PWideChar(Text));
end;
{ @end $4534D4 }

{ @routine $4534F0 AlignDebugColumn }
function AlignDebugColumn(const Text: WideString; Width, Alignment: Integer; Padding: WideChar): WideString;
var TextLength, Index, LeftPadding: Integer;
begin
  TextLength := Length(Text);
  if TextLength > Width then Result := Copy(Text, 1, Width - 1) + '~'
  else if TextLength < Width then
  begin
    SetLength(Result, Width);
    // Native inclusive bounds overwrite the terminator for left/center alignment.
    if Alignment > 0 then
    begin
      for Index := 0 to Width - TextLength do Result[Index + 1] := Padding;
      CopyMemory(PWideChar(Result) + (Width - TextLength), PWideChar(Text), TextLength * 2);
    end
    else if Alignment < 0 then
    begin
      for Index := 0 to Width - TextLength do Result[TextLength + Index + 1] := Padding;
      CopyMemory(PWideChar(Result), PWideChar(Text), TextLength * 2);
    end
    else
    begin
      LeftPadding := (Width - TextLength) div 2;
      if Odd(Width - TextLength) then Inc(LeftPadding);
      for Index := 0 to LeftPadding - 1 do Result[Index + 1] := Padding;
      CopyMemory(PWideChar(Result) + LeftPadding, PWideChar(Text), TextLength * 2);
      for Index := 0 to Width - TextLength - LeftPadding do
        Result[LeftPadding + TextLength + Index + 1] := Padding;
    end;
  end
  else Result := Text;
end;
{ @end $4534F0 }
end.

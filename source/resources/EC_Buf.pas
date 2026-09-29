unit EC_Buf;
// Unit bracket (inferred): CODE 0x004C0C04..0x004C1E97; inclusive evidence, not full bounds.

interface

uses EC_File, EC_Struct;

type
  TBufEC = class(TObjectEx) // @size $14
  public
    DataSize: Integer; // @offset $04
    Capacity: Integer; // @offset $08
    Position: Integer; // @offset $0C
    Data: Pointer; // @offset $10

    constructor Create; // @addr $4C0C58
    destructor Destroy; override; // @addr $4C0C90
    procedure Clear; // @addr $4C0CBC
    function IsAtEnd: Boolean; // @addr $4C0D20
    procedure SetSize(NewSize: Integer); // @addr $4C0CE4 @note "Nonpositive sizes clear the buffer; shrinking clamps Position."
    procedure SetPosition(NewPosition: Integer); // @addr $4C0D30
    procedure EnsureWriteCapacity(AddedBytes: Integer); // @addr $4C0DCC @note "AddedBytes must be positive. Extends DataSize without advancing Position."
    procedure EnsureWriteCapacityAtOffset(Offset, AddedBytes: Integer); // @addr $4C0E98 @note "AddedBytes must be positive; Offset must be in 0..DataSize. Position is unchanged."
    procedure EnsureReadable(Bytes: Integer); // @addr $4C0F98
    procedure EnsureReadableAtOffset(Offset, Bytes: Integer); // @addr $4C1034 @note "Rejects nonpositive counts and ranges ending past DataSize; does not reject negative Offset."

    procedure SetByteAt(Offset: Integer; Value: Byte); // @addr $4C10FC
    procedure SetInt32At(Offset: Integer; Value: Integer); // @addr $4C1128
    function GetByteAt(Offset: Integer): Byte; // @addr $4C14BC
    function GetUInt32At(Offset: Integer): Cardinal; // @addr $4C14E0
    function GetInt32At(Offset: Integer): Integer; // @addr $4C1504

    // Sequential operations use Position, including writes into existing data.
    procedure AddBytes(Source: Pointer; ByteCount: Integer); // @addr $4C1154
    procedure AddByte(Value: Byte); // @addr $4C12B4
    procedure AddWord(Value: Word); // @addr $4C12E8
    procedure AddDWord(Value: Cardinal); // @addr $4C1384
    procedure AddIntegerValue(Value: Integer); // @addr $4C13B8
    procedure AddSingle(Value: Single); // @addr $4C13EC
    procedure AddDouble(Value: Double); // @addr $4C1424
    procedure AddBoolean(Value: Boolean); // @addr $4C1460
    procedure AddBuffer(Value: TBufEC); // @addr $4C1494 @note "Writes a four-byte size followed by the entire source payload, ignoring its Position."

    procedure AddAnsiStringZ(const Value: AnsiString); // @addr $4C1188
    procedure AddWideStringZ(const Value: WideString); // @addr $4C11D4
    procedure AddAnsiStringRaw(const Value: AnsiString); // @addr $4C1224
    procedure AddWideStringRaw(const Value: WideString); // @addr $4C126C
    procedure AddAnsiChar(Value: AnsiChar); // @addr $4C131C
    procedure AddWideChar(Value: WideChar); // @addr $4C1350

    function ReadBytes(Dest: Pointer; ByteCount: Integer): Pointer; // @addr $4C1528 @note "Returns Dest; requires a positive ByteCount."
    // Several scalar readers contain native inline assembly after the bounds check.
    function GetByte: Byte; // @addr $4C15B8
    function GetWideChar: WideChar; // @addr $4C15F4
    function GetWord: Word; // @addr $4C1618
    function GetUInt32: Cardinal; // @addr $4C1658
    function GetInt32: Integer; // @addr $4C1694
    function GetSingle: Single; // @addr $4C16D0 @note "Returns the stored floating-point bits, including NaN."
    function GetDouble: Double; // @addr $4C170C @note "Returns the stored floating-point bits, including NaN."
    function GetBoolean: Boolean; // @addr $4C173C
    procedure ReadLengthPrefixedBuffer(Dest: TBufEC); // @addr $4C1778 @note "Dest.Position is preserved unless it exceeds the new size."

    // Lengths count characters, stop at the buffer end, and leave Position unchanged.
    function GetWideStringLength: Integer; // @addr $4C17A8
    function GetWideStringLengthAt(Offset: Integer): Integer; // @addr $4C17B4
    function GetAnsiTextLineLength: Integer; // @addr $4C17F0
    function GetAnsiTextLineLengthAt(Offset: Integer): Integer; // @addr $4C17FC
    function GetWideTextLineLength: Integer; // @addr $4C1838
    function GetWideTextLineLengthAt(Offset: Integer): Integer; // @addr $4C1844

    // Dest must have room for the text and a terminating zero; returns Dest.
    // Line readers stop at NUL, CR or LF and consume up to two such characters.
    function ReadAnsiTextLineToBuffer(Dest: PAnsiChar): PAnsiChar; // @addr $4C188C
    function ReadWideTextLineToBuffer(Dest: PWideChar): PWideChar; // @addr $4C195C
    function ReadWideStringToBuffer(Dest: PWideChar): PWideChar; // @addr $4C1560 @note "Consumes the terminating zero; an empty scan advances Position by two even at the buffer end."
    function ReadAnsiTextLine: AnsiString; // @addr $4C1908
    function ReadWideTextLine: WideString; // @addr $4C19F4
    function ReadWideString: WideString; // @addr $4C1A48

    // Successful transforms replace the entire payload and reset Position to zero.
    // False leaves the buffer intact, including when DataSize is less than eight.
    function CompressZlibPayloadInPlace(FastMode: Boolean): Boolean; // @addr $4C1AB0 @note "FastMode is ignored in this binary."
    function ExpandZlibPayloadInPlace: Boolean; // @addr $4C1B10
    procedure ApplyDatXorCipher(Seed: Integer); // @addr $4C1BD8 @note "Leaves Position unchanged."
    procedure ApplyDatXorCipherRange(Seed, StartOffset, EndOffset: Integer); // @addr $4C1C54 @note "EndOffset is exclusive; leaves Position unchanged and does not validate offsets."
    function ComputeCrc32: Cardinal; // @addr $4C1C84
    function ComputeCrc32Range(StartOffset, EndOffset: Integer): Cardinal; // @addr $4C1C90 @note "EndOffset is exclusive; offsets are not validated."

    // Loaders release their acquisition in finally; I/O exceptions propagate.
    // File paths are ANSI.
    procedure LoadFromFileChunk(SourceFile: TFileEC; ByteCount: Integer); // @addr $4C1CA0 @note "Consumes from the current file position; balances its own handle acquisition."
    procedure LoadFromFile(SourceFile: TFileEC); // @addr $4C1D38 @note "Reads only the remaining file bytes; balances its own handle acquisition."
    procedure LoadFromFilePath(FileName: PAnsiChar); // @addr $4C1DAC
    procedure SaveToFile(DestFile: TFileEC); // @addr $4C1E50 @note "Writes the entire payload at the open file's current position, ignoring the buffer's Position."
  end;

implementation

// @unit-initialization $4C1E90
// @unit-finalization $4C1E60

uses CrcUnit, EC_Mem, GR_Main, Math, SysUtils, Windows;

const
  // Growth adds fixed slack.
  BufferGrowthSlack = 256;
  CarriageReturnCode = 13;
  LineFeedCode = 10;

{ @routine $4C0C58 TBufEC_Create }
constructor TBufEC.Create;
begin inherited Create end;
{ @end $4C0C58 }

{ @routine $4C0C90 TBufEC_Destroy }
destructor TBufEC.Destroy;
begin Clear; inherited Destroy end;
{ @end $4C0C90 }

{ @routine $4C0CBC TBufEC_Clear }
procedure TBufEC.Clear;
begin
  if Data <> nil then
  begin
    FreeEC(Data);
    Data := nil;
  end;
  DataSize := 0;
  Capacity := 0;
  Position := 0;
end;
{ @end $4C0CBC }

{ @routine $4C0CE4 TBufEC_SetSize }
procedure TBufEC.SetSize(NewSize: Integer);
begin
  if NewSize < 1 then Clear
  else
  begin
    DataSize := NewSize;
    Capacity := NewSize + BufferGrowthSlack;
    Data := ReAllocREC(Data, Capacity);
    if Position > DataSize then Position := DataSize;
  end;
end;
{ @end $4C0CE4 }

{ @routine $4C0D20 TBufEC_IsAtEnd }
function TBufEC.IsAtEnd: Boolean;
begin
  if Position >= DataSize then Result := True else Result := False;
end;
{ @end $4C0D20 }

{ @routine $4C0D30 TBufEC_SetPosition }
procedure TBufEC.SetPosition(NewPosition: Integer);
begin
  if (NewPosition < 0) or (NewPosition > DataSize) then
    raise Exception.Create('TBufEC.PointerSet. zn=' + SysUtils.IntToStr(NewPosition));
  Position := NewPosition;
end;
{ @end $4C0D30 }

{ @routine $4C0DCC TBufEC_EnsureWriteCapacity }
procedure TBufEC.EnsureWriteCapacity(AddedBytes: Integer);
begin
  if AddedBytes < 1 then raise Exception.Create('TBufEC.TestAddLenBuf. addlen=' + SysUtils.IntToStr(AddedBytes));
  if Position + AddedBytes > DataSize then
  begin
    DataSize := Position + AddedBytes;
    if DataSize > Capacity then
    begin
      Capacity := DataSize + BufferGrowthSlack;
      Data := ReAllocREC(Data, Capacity);
    end;
  end;
end;
{ @end $4C0DCC }

{ @routine $4C0E98 TBufEC_EnsureWriteCapacityAtOffset }
procedure TBufEC.EnsureWriteCapacityAtOffset(Offset, AddedBytes: Integer);
begin
  if (AddedBytes < 1) or (Offset < 0) or (Offset > DataSize) then
    raise Exception.Create('TBufEC.TestAddLenBuf. sme=' + SysUtils.IntToStr(Offset) + ' addlen=' + SysUtils.IntToStr(AddedBytes));
  if Offset + AddedBytes > DataSize then
  begin
    DataSize := Offset + AddedBytes;
    if DataSize > Capacity then
    begin
      Capacity := DataSize + BufferGrowthSlack;
      Data := ReAllocREC(Data, Capacity);
    end;
  end;
end;
{ @end $4C0E98 }

{ @routine $4C0F98 TBufEC_EnsureReadable }
procedure TBufEC.EnsureReadable(Bytes: Integer);
begin
  if (Bytes < 1) or (Position + Bytes > DataSize) then
    raise Exception.Create('TBufEC.TestGet. len=' + SysUtils.IntToStr(Bytes));
end;
{ @end $4C0F98 }

{ @routine $4C1034 TBufEC_EnsureReadableAtOffset }
procedure TBufEC.EnsureReadableAtOffset(Offset, Bytes: Integer);
begin
  if (Bytes < 1) or (Offset + Bytes > DataSize) then
    raise Exception.Create('TBufEC.TestGet. sme=' + SysUtils.IntToStr(Offset) + ' len=' + SysUtils.IntToStr(Bytes));
end;
{ @end $4C1034 }

{ @routine $4C10FC TBufEC_SetByteAt }
procedure TBufEC.SetByteAt(Offset: Integer; Value: Byte);
begin
  EnsureWriteCapacityAtOffset(Offset, SizeOf(Value));
  WriteByteEC(Pointer(Cardinal(Data) + Cardinal(Offset)), Value);
end;
{ @end $4C10FC }

{ @routine $4C1128 TBufEC_SetInt32At }
procedure TBufEC.SetInt32At(Offset: Integer; Value: Integer);
begin
  EnsureWriteCapacityAtOffset(Offset, SizeOf(Value));
  WriteIntegerEC(Pointer(Cardinal(Data) + Cardinal(Offset)), Value);
end;
{ @end $4C1128 }

{ @routine $4C1154 TBufEC_AddBytes }
procedure TBufEC.AddBytes(Source: Pointer; ByteCount: Integer);
begin
  EnsureWriteCapacity(ByteCount);
  Windows.CopyMemory(AddPointerOffset(Data, Position), Source, ByteCount);
  Inc(Position, ByteCount);
end;
{ @end $4C1154 }

{ @routine $4C1188 TBufEC_AddAnsiStringZ }
procedure TBufEC.AddAnsiStringZ(const Value: AnsiString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value);
  EnsureWriteCapacity(ByteCount + 1);
  Windows.CopyMemory(AddPointerOffset(Data, Position), PAnsiChar(Value), ByteCount + 1);
  Position := Position + ByteCount + 1;
end;
{ @end $4C1188 }

{ @routine $4C11D4 TBufEC_AddWideStringZ }
procedure TBufEC.AddWideStringZ(const Value: WideString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value) * SizeOf(WideChar);
  EnsureWriteCapacity(ByteCount + SizeOf(WideChar));
  Windows.CopyMemory(AddPointerOffset(Data, Position), PWideChar(Value), ByteCount + SizeOf(WideChar));
  Position := Position + ByteCount + SizeOf(WideChar);
end;
{ @end $4C11D4 }

{ @routine $4C1224 TBufEC_AddAnsiStringRaw }
procedure TBufEC.AddAnsiStringRaw(const Value: AnsiString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value);
  if ByteCount > 0 then
  begin
    EnsureWriteCapacity(ByteCount);
    Windows.CopyMemory(AddPointerOffset(Data, Position), PAnsiChar(Value), ByteCount);
    Inc(Position, ByteCount);
  end;
end;
{ @end $4C1224 }

{ @routine $4C126C TBufEC_AddWideStringRaw }
procedure TBufEC.AddWideStringRaw(const Value: WideString);
var
  ByteCount: Integer;
begin
  ByteCount := Length(Value) * SizeOf(WideChar);
  if ByteCount > 0 then
  begin
    EnsureWriteCapacity(ByteCount);
    Windows.CopyMemory(AddPointerOffset(Data, Position), PWideChar(Value), ByteCount);
    Inc(Position, ByteCount);
  end;
end;
{ @end $4C126C }

{ @routine $4C12B4 TBufEC_AddByte }
procedure TBufEC.AddByte(Value: Byte);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;
{ @end $4C12B4 }

{ @routine $4C12E8 TBufEC_AddWord }
procedure TBufEC.AddWord(Value: Word);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteWordEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;
{ @end $4C12E8 }

{ @routine $4C131C TBufEC_AddAnsiChar }
procedure TBufEC.AddAnsiChar(Value: AnsiChar);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Byte(Value));
  Inc(Position, SizeOf(Value));
end;
{ @end $4C131C }

{ @routine $4C1350 TBufEC_AddWideChar }
procedure TBufEC.AddWideChar(Value: WideChar);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteWordEC(AddPointerOffset(Data, Position), Word(Value));
  Inc(Position, SizeOf(Value));
end;
{ @end $4C1350 }

{ @routine $4C1384 TBufEC_AddDWord }
procedure TBufEC.AddDWord(Value: Cardinal);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteIntegerEC(AddPointerOffset(Data, Position), Integer(Value));
  Inc(Position, SizeOf(Value));
end;
{ @end $4C1384 }

{ @routine $4C13B8 TBufEC_AddIntegerValue }
procedure TBufEC.AddIntegerValue(Value: Integer);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteInt32EC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;
{ @end $4C13B8 }

{ @routine $4C13EC TBufEC_AddSingle }
procedure TBufEC.AddSingle(Value: Single);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteSingleEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;
{ @end $4C13EC }

{ @routine $4C1424 TBufEC_AddDouble }
procedure TBufEC.AddDouble(Value: Double);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteDoubleEC(AddPointerOffset(Data, Position), Value);
  Inc(Position, SizeOf(Value));
end;
{ @end $4C1424 }

{ @routine $4C1460 TBufEC_AddBoolean }
procedure TBufEC.AddBoolean(Value: Boolean);
begin
  EnsureWriteCapacity(SizeOf(Value));
  WriteByteEC(AddPointerOffset(Data, Position), Byte(Value));
  Inc(Position, SizeOf(Value));
end;
{ @end $4C1460 }

{ @routine $4C1494 TBufEC_AddBuffer }
procedure TBufEC.AddBuffer(Value: TBufEC);
begin
  AddDWord(Value.DataSize);
  if Value.DataSize > 0 then AddBytes(Value.Data, Value.DataSize);
end;
{ @end $4C1494 }

{ @routine $4C14BC TBufEC_GetByteAt }
function TBufEC.GetByteAt(Offset: Integer): Byte;
begin
  EnsureReadableAtOffset(Offset, SizeOf(Result));
  Result := ReadByteEC(Pointer(Cardinal(Data) + Cardinal(Offset)));
end;
{ @end $4C14BC }

{ @routine $4C14E0 TBufEC_GetUInt32At }
function TBufEC.GetUInt32At(Offset: Integer): Cardinal;
begin
  EnsureReadableAtOffset(Offset, SizeOf(Result));
  Result := ReadDWordEC(Pointer(Cardinal(Data) + Cardinal(Offset)));
end;
{ @end $4C14E0 }

{ @routine $4C1504 TBufEC_GetInt32At }
function TBufEC.GetInt32At(Offset: Integer): Integer;
begin
  EnsureReadableAtOffset(Offset, SizeOf(Result));
  Result := ReadIntegerEC(Pointer(Cardinal(Data) + Cardinal(Offset)));
end;
{ @end $4C1504 }

{ @routine $4C1528 TBufEC_ReadBytes }
function TBufEC.ReadBytes(Dest: Pointer; ByteCount: Integer): Pointer;
begin
  EnsureReadable(ByteCount);
  Windows.CopyMemory(Dest, AddPointerOffset(Data, Position), ByteCount);
  Inc(Position, ByteCount);
  Result := Dest;
end;
{ @end $4C1528 }

{ @routine $4C1560 TBufEC_ReadWideStringToBuffer }
function TBufEC.ReadWideStringToBuffer(Dest: PWideChar): PWideChar;
var
  Count: Integer;
begin
  Count := GetWideStringLengthAt(Position);
  if Count > 0 then
  begin
    EnsureReadable(Count * SizeOf(WideChar) + SizeOf(WideChar));
    Windows.CopyMemory(Dest, PAnsiChar(Data) + Position, Count * SizeOf(WideChar) + SizeOf(WideChar));
    Position := Position + Count * SizeOf(WideChar) + SizeOf(WideChar);
  end
  else
  begin
    Inc(Position, SizeOf(WideChar));
    Dest^ := #0;
  end;
  Result := Dest;
end;
{ @end $4C1560 }

{ @routine $4C15B8 TBufEC_GetByte }
function TBufEC.GetByte: Byte;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    INC [EBX].TBufEC.Position
    MOV AL, [EDI + EAX]
    MOV Result, AL
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C15B8 }

{ @routine $4C15F4 TBufEC_GetWideChar }
function TBufEC.GetWideChar: WideChar;
begin
  EnsureReadable(SizeOf(Result));
  Result := ReadWideCharEC(PAnsiChar(Data) + Position);
  Inc(Position, 2);
end;
{ @end $4C15F4 }

{ @routine $4C1618 TBufEC_GetWord }
function TBufEC.GetWord: Word;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    ADD [EBX].TBufEC.Position, 2
    MOV AX, [EDI + EAX]
    MOV Result, AX
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C1618 }

{ @routine $4C1658 TBufEC_GetUInt32 }
function TBufEC.GetUInt32: Cardinal;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    ADD [EBX].TBufEC.Position, 4
    MOV EAX, [EDI + EAX]
    MOV Result, EAX
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C1658 }

{ @routine $4C1694 TBufEC_GetInt32 }
function TBufEC.GetInt32: Integer;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    ADD [EBX].TBufEC.Position, 4
    MOV EAX, [EDI + EAX]
    MOV Result, EAX
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C1694 }

{ @routine $4C16D0 TBufEC_GetSingle }
function TBufEC.GetSingle: Single;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    ADD [EBX].TBufEC.Position, 4
    MOV EAX, [EDI + EAX]
    MOV Result, EAX
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C16D0 }

{ @routine $4C170C TBufEC_GetDouble }
function TBufEC.GetDouble: Double;
begin
  EnsureReadable(SizeOf(Result));
  Result := ReadDoubleEC(PAnsiChar(Data) + Position);
  Inc(Position, SizeOf(Result));
end;
{ @end $4C170C }

{ @routine $4C173C TBufEC_GetBoolean }
function TBufEC.GetBoolean: Boolean;
begin
  EnsureReadable(SizeOf(Result));
  asm
    PUSH EAX
    PUSH EBX
    PUSH EDI
    MOV EBX, Self
    MOV EAX, [EBX].TBufEC.Position
    MOV EDI, [EBX].TBufEC.Data
    INC [EBX].TBufEC.Position
    MOV AL, [EDI + EAX]
    MOV Result, AL
    POP EDI
    POP EBX
    POP EAX
  end;
end;
{ @end $4C173C }

{ @routine $4C1778 TBufEC_ReadLengthPrefixedBuffer }
procedure TBufEC.ReadLengthPrefixedBuffer(Dest: TBufEC);
var
  ByteCount: Integer;
begin
  ByteCount := GetUInt32;
  Dest.SetSize(ByteCount);
  if ByteCount > 0 then ReadBytes(Dest.Data, ByteCount);
end;
{ @end $4C1778 }

{ @routine $4C17A8 TBufEC_GetWideStringLength }
function TBufEC.GetWideStringLength: Integer;
begin Result := GetWideStringLengthAt(Position) end;
{ @end $4C17A8 }

{ @routine $4C17B4 TBufEC_GetWideStringLengthAt }
function TBufEC.GetWideStringLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;

begin
  Cursor := Offset;
  Count := 0;
  while Cursor + 1 < DataSize do
  begin
    if ReadWordEC(AddPointerOffset(Data, Cursor)) = 0 then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, SizeOf(WideChar));
  end;
  Result := Count;
end;
{ @end $4C17B4 }

{ @routine $4C17F0 TBufEC_GetAnsiTextLineLength }
function TBufEC.GetAnsiTextLineLength: Integer;
begin Result := GetAnsiTextLineLengthAt(Position) end;
{ @end $4C17F0 }

{ @routine $4C17FC TBufEC_GetAnsiTextLineLengthAt }
function TBufEC.GetAnsiTextLineLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;
  Ch: Byte;
begin
  Cursor := Offset;
  Count := 0;
  while Cursor < DataSize do
  begin
    Ch := ReadByteEC(AddPointerOffset(Data, Cursor));
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, 1);
  end;
  Result := Count;
end;
{ @end $4C17FC }

{ @routine $4C1838 TBufEC_GetWideTextLineLength }
function TBufEC.GetWideTextLineLength: Integer;
begin Result := GetWideTextLineLengthAt(Position) end;
{ @end $4C1838 }

{ @routine $4C1844 TBufEC_GetWideTextLineLengthAt }
function TBufEC.GetWideTextLineLengthAt(Offset: Integer): Integer;
var
  Count, Cursor: Integer;
  Ch: Word;
begin
  Cursor := Offset;
  Count := 0;
  while Cursor + 1 < DataSize do
  begin
    Ch := ReadWordEC(AddPointerOffset(Data, Cursor));
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then
    begin
      Result := Count;
      Exit;
    end;
    Inc(Count);
    Inc(Cursor, SizeOf(WideChar));
  end;
  Result := Count;
end;
{ @end $4C1844 }

{ @routine $4C188C TBufEC_ReadAnsiTextLineToBuffer }
function TBufEC.ReadAnsiTextLineToBuffer(Dest: PAnsiChar): PAnsiChar;
var
  Count: Integer;
  Ch: Byte;
begin
  Count := GetAnsiTextLineLength;
  if Count > 0 then
  begin
    Windows.CopyMemory(Dest, PAnsiChar(Data) + Position, Count);
    Dest[Count] := #0;
    Inc(Position, Count);
  end
  else Dest^ := #0;
  if Position < DataSize then
  begin
    Ch := ReadByteEC(PAnsiChar(Data) + Position);
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then Inc(Position, 1);
    if Position < DataSize then
    begin
      Ch := ReadByteEC(PAnsiChar(Data) + Position);
      if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then Inc(Position, 1);
    end;
  end;
  Result := Dest;
end;
{ @end $4C188C }

{ @routine $4C1908 TBufEC_ReadAnsiTextLine }
function TBufEC.ReadAnsiTextLine: AnsiString;
var
  Count: Integer;
begin
  Count := GetAnsiTextLineLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadAnsiTextLineToBuffer(PAnsiChar(Result));
  end
  else
  begin
    SetLength(Result, 2);
    ReadAnsiTextLineToBuffer(PAnsiChar(Result));
    Result := '';
  end;
end;
{ @end $4C1908 }

{ @routine $4C195C TBufEC_ReadWideTextLineToBuffer }
function TBufEC.ReadWideTextLineToBuffer(Dest: PWideChar): PWideChar;
var
  Count: Integer;
  Ch: Word;
begin
  Count := GetWideTextLineLength;
  if Count > 0 then
  begin
    Windows.CopyMemory(Dest, PAnsiChar(Data) + Position, Count * SizeOf(WideChar));
    Dest[Count] := #0;
    Inc(Position, Count * SizeOf(WideChar));
  end
  else Dest^ := #0;
  if Position + 1 < DataSize then
  begin
    Ch := ReadWordEC(PAnsiChar(Data) + Position);
    if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then Inc(Position, SizeOf(WideChar));
    if Position + 1 < DataSize then
    begin
      Ch := ReadWordEC(PAnsiChar(Data) + Position);
      if (Ch = 0) or (Ch = CarriageReturnCode) or (Ch = LineFeedCode) then Inc(Position, SizeOf(WideChar));
    end;
  end;
  Result := Dest;
end;
{ @end $4C195C }

{ @routine $4C19F4 TBufEC_ReadWideTextLine }
function TBufEC.ReadWideTextLine: WideString;
var
  Count: Integer;
begin
  Count := GetWideTextLineLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadWideTextLineToBuffer(PWideChar(Result));
  end
  else
  begin
    SetLength(Result, 2);
    ReadWideTextLineToBuffer(PWideChar(Result));
    Result := '';
  end;
end;
{ @end $4C19F4 }

{ @routine $4C1A48 TBufEC_ReadWideString }
function TBufEC.ReadWideString: WideString;
var
  Count: Integer;
begin
  Count := GetWideStringLength;
  if Count > 0 then
  begin
    SetLength(Result, Count);
    ReadWideStringToBuffer(PWideChar(Result));
    SetLength(Result, Count);
  end
  else
  begin
    SetLength(Result, 1);
    ReadWideStringToBuffer(@Count);
    SetLength(Result, 0);
    Result := '';
  end;
end;
{ @end $4C1A48 }

{ @routine $4C1AB0 TBufEC_CompressZlibPayloadInPlace }
function TBufEC.CompressZlibPayloadInPlace(FastMode: Boolean): Boolean;
var
  Mode, ByteCount: Integer;
  Buffer: Pointer;
begin
  Mode := 0;
  if FastMode = True then Mode := 0;
  if DataSize < 8 then
  begin
    Result := False;
    Exit;
  end;
  Buffer := AllocEC(DataSize);
  ByteCount := OKGF_ZLib_Compress(Buffer, Data, DataSize, Mode);
  if ByteCount = 0 then
  begin
    FreeEC(Buffer);
    Result := False;
    Exit;
  end;
  FreeEC(Data);
  Data := Buffer;
  DataSize := ByteCount;
  Capacity := ByteCount;
  Position := 0;
  Result := True;
end;
{ @end $4C1AB0 }

{ @routine $4C1B10 TBufEC_ExpandZlibPayloadInPlace }
function TBufEC.ExpandZlibPayloadInPlace: Boolean;
var
  ByteCount: Integer;
  Buffer: Pointer;
begin
  if DataSize < 8 then
  begin
    Result := False;
    Exit;
  end;
  ByteCount := OKGF_ZLib_UnCompress(nil, 0, Data, DataSize);
  if ByteCount = 0 then
  begin
    Result := False;
    Exit;
  end;
  Buffer := AllocEC(ByteCount);
  ByteCount := OKGF_ZLib_UnCompress(Buffer, ByteCount, Data, DataSize);
  if ByteCount = 0 then
  begin
    FreeEC(Buffer);
    Result := False;
    Exit;
  end;
  FreeEC(Data);
  Data := Buffer;
  DataSize := ByteCount;
  Capacity := ByteCount;
  Position := 0;
  Result := True;
end;
{ @end $4C1B10 }

{ @routine $4C1BD8 TBufEC_ApplyDatXorCipher }
procedure TBufEC.ApplyDatXorCipher(Seed: Integer);
var
  State, i: Integer;
  Cursor: PByte;

  // @nested $4C1B84 StepDatXorSeedState
  function StepDatXorSeedState: Integer; // @addr $4C1B84 @note "Nested helper of TBufEC.ApplyDatXorCipher; requires its parent stack frame."
  begin
    State := 16807 * (State mod 127773) - 2836 * (State div 127773);
    if State <= 0 then State := State + $7FFFFFFF;
    Result := State - 1;
  end;

begin
  State := Seed;
  Cursor := Data;
  for i := 0 to DataSize - 1 do
  begin
    Cursor^ := Cursor^ xor Byte(StepDatXorSeedState);
    Cursor := PByte(PAnsiChar(Cursor) + 1);
  end;
end;
{ @end $4C1BD8 }

{ @routine $4C1C54 TBufEC_ApplyDatXorCipherRange }
procedure TBufEC.ApplyDatXorCipherRange(Seed, StartOffset, EndOffset: Integer);
var Cursor: PByte; i: Integer;
  // @nested $4C1C00 StepRangeXorSeed
  function StepRangeXorSeed: Integer; // @addr $4C1C00
  begin
    Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
    if Seed <= 0 then Seed := Seed + $7FFFFFFF;
    Result := Seed - 1;
  end;
begin
  Cursor := PByte(PAnsiChar(Data) + StartOffset);
  for i := StartOffset to EndOffset - 1 do
  begin
    Cursor^ := Cursor^ xor Byte(StepRangeXorSeed);
    Cursor := PByte(PAnsiChar(Cursor) + 1);
  end;
end;
{ @end $4C1C54 }

{ @routine $4C1C84 TBufEC_ComputeCrc32 }
function TBufEC.ComputeCrc32: Cardinal;
begin Result := CrcUnit.ComputeCrc32(Data, DataSize) end;
{ @end $4C1C84 }

{ @routine $4C1C90 TBufEC_ComputeCrc32Range }
function TBufEC.ComputeCrc32Range(StartOffset, EndOffset: Integer): Cardinal;
begin Result := CrcUnit.ComputeCrc32(Pointer(PAnsiChar(Data) + StartOffset), EndOffset - StartOffset) end;
{ @end $4C1C90 }

{ @routine $4C1CA0 TBufEC_LoadFromFileChunk }
procedure TBufEC.LoadFromFileChunk(SourceFile: TFileEC; ByteCount: Integer);
var
  ChunkSize: Integer;
  Cursor: Pointer;
begin
  Self.Clear;
  SourceFile.AcquireReadWriteHandle;
  try
    Self.SetSize(ByteCount);
    Cursor := Self.Data;
    if ByteCount > 0 then
    begin
      repeat
        ChunkSize := Min(262144, ByteCount);
        SourceFile.ReadBuffer(Cursor, ChunkSize);
        Cursor := AddPointerOffset(Cursor, ChunkSize);
        ByteCount := (ByteCount - ChunkSize);
        if ByteCount > 0 then
        begin
          SysUtils.Sleep(1);
        end;
      until ByteCount <= 0;
    end;
  finally
    SourceFile.ReleaseHandle;
  end;
  Exit;
end;
{ @end $4C1CA0 }

{ @routine $4C1D38 TBufEC_LoadFromFile }
procedure TBufEC.LoadFromFile(SourceFile: TFileEC);
var
  ByteCount: Integer;
begin
  Clear;
  SourceFile.AcquireReadWriteHandle;
  try
    ByteCount := SourceFile.GetSize - SourceFile.GetPointer;
    SetSize(ByteCount);
    SourceFile.ReadBuffer(Data, ByteCount);
  finally
    SourceFile.ReleaseHandle;
  end;
end;
{ @end $4C1D38 }

{ @routine $4C1DAC TBufEC_LoadFromFilePath }
procedure TBufEC.LoadFromFilePath(FileName: PAnsiChar);
var
  SourceFile: TFileEC;
begin
  SourceFile := TFileEC.Create;
  try
    SourceFile.SetFileName(AnsiString(FileName));
    SourceFile.AcquireReadHandle;
    LoadFromFile(SourceFile);
  finally
    SourceFile.Free;
  end;
end;
{ @end $4C1DAC }

{ @routine $4C1E50 TBufEC_SaveToFile }
procedure TBufEC.SaveToFile(DestFile: TFileEC);
begin DestFile.WriteBuffer(Data, DataSize) end;
{ @end $4C1E50 }

end.

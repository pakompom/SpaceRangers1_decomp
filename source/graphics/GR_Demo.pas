unit GR_Demo;
// Unit bracket (inferred): CODE 0x004674F4..0x0046892F; inclusive evidence, not full bounds.
// Input demos. PACKAGEINFO names GR_Demo; the TDemo VMT header $4674F4 and
// the TDemo.Get* exception strings identify this region.
interface
uses EC_Struct, EC_Buf, Types;
type
  // Event tags; names follow the text demo format read by LoadFromTextBuffer.
  TDemoEventKind = (dekEnd = 0, dekMouseMove = 1, dekMouseLDown = 2, dekMouseLUp = 3, dekMouseRDown = 4, dekMouseRUp = 5, dekFormStart = 6, dekGameLoad = 7, dekSpacePos = 8, dekState = 9); // @size $01
  TDemo = class(TObjectEx) // @size $08
  public
    Buffer: TBufEC; // @offset $04 Owned binary event stream.
    constructor Create; // @addr $467548
    destructor Destroy; override; // @addr $46758C
    procedure Clear; // @addr $4675C8
    procedure SeekStart; // @addr $4675D4
    procedure SeekEnd; // @addr $4675E0
    function PeekKind: TDemoEventKind; // @addr $4675F0
    function PeekTimeDelta: Cardinal; // @addr $467628
    procedure AddMouseMove(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal); // @addr $4676C8
    procedure GetMouseMove(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal); // @addr $46763C
    procedure AddMouseLDown(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal); // @addr $467728
    procedure GetMouseLDown(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal); // @addr $467788
    procedure AddMouseLUp(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal); // @addr $467814
    procedure GetMouseLUp(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal); // @addr $467874
    procedure AddMouseRDown(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal); // @addr $467900
    procedure GetMouseRDown(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal); // @addr $467960
    procedure AddMouseRUp(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal); // @addr $4679EC
    procedure GetMouseRUp(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal); // @addr $467A4C
    procedure AddFormStart(Name: WideString); // @addr $467AD8
    procedure GetFormStart(var Name: WideString); // @addr $467B40
    procedure AddGameLoad(Name: WideString); // @addr $467BE0
    procedure GetGameLoad(var Name: WideString); // @addr $467C48
    procedure AddSpacePos(TimeDelta: Cardinal; Position: TPoint); // @addr $467CE8
    procedure GetSpacePos(var TimeDelta: Cardinal; var Position: TPoint); // @addr $467D3C
    procedure LoadTextFile(FileName: WideString); // @addr $468868
    procedure LoadFromTextBuffer(Input: TBufEC); // @addr $467F1C
    procedure AddState(TimeDelta: Cardinal; Text: WideString; Position: TPoint); // @addr $467DB4
    procedure GetState(var TimeDelta: Cardinal; var Text: WideString; var Position: TPoint); // @addr $467E4C
  end;
implementation

// @unit-initialization $468928
// @unit-finalization $4688F8

uses SysUtils, aMyFunction, EC_BlockPar, EC_Str;

{ @routine $467548 TDemo_Create }
constructor TDemo.Create;
begin
  inherited Create;
  Buffer := TBufEC.Create;
end;
{ @end $467548 }

{ @routine $46758C TDemo_Destroy }
destructor TDemo.Destroy;
begin
  Clear;
  Buffer.Free;
  Buffer := nil;
  inherited Destroy;
end;
{ @end $46758C }

{ @routine $4675C8 TDemo_Clear }
procedure TDemo.Clear;
begin
  Buffer.Clear;
end;
{ @end $4675C8 }

{ @routine $4675D4 TDemo_SeekStart }
procedure TDemo.SeekStart;
begin
  Buffer.SetPosition(0);
end;
{ @end $4675D4 }

{ @routine $4675E0 TDemo_SeekEnd }
procedure TDemo.SeekEnd;
begin
  Buffer.SetPosition(Buffer.DataSize);
end;
{ @end $4675E0 }

{ @routine $4675F0 TDemo_PeekKind }
function TDemo.PeekKind: TDemoEventKind;
var Position: Integer; Kind: TDemoEventKind;
begin
  if Buffer.Position >= Buffer.DataSize then
  begin
    Result := dekEnd;
    Exit;
  end;
  Position := Buffer.Position;
  WriteByteValue(Buffer.GetByte, Kind);
  Buffer.SetPosition(Position);
  Result := Kind;
end;
{ @end $4675F0 }

{ @routine $467628 TDemo_PeekTimeDelta }
function TDemo.PeekTimeDelta: Cardinal;
begin
  Result := Buffer.GetUInt32At(Buffer.Position + 1);
end;
{ @end $467628 }

{ @routine $46763C TDemo_GetMouseMove }
procedure TDemo.GetMouseMove(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekMouseMove then raise Exception.Create('TDemo.GetMouseMove');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  KeyState := Buffer.GetUInt32;
end;
{ @end $46763C }

{ @routine $4676C8 TDemo_AddMouseMove }
procedure TDemo.AddMouseMove(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  Kind := dekMouseMove;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDWord(KeyState);
end;
{ @end $4676C8 }

{ @routine $467728 TDemo_AddMouseLDown }
procedure TDemo.AddMouseLDown(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  Kind := dekMouseLDown;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDWord(KeyState);
end;
{ @end $467728 }

{ @routine $467788 TDemo_GetMouseLDown }
procedure TDemo.GetMouseLDown(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekMouseLDown then raise Exception.Create('TDemo.GetMouseLDown');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  KeyState := Buffer.GetUInt32;
end;
{ @end $467788 }

{ @routine $467814 TDemo_AddMouseLUp }
procedure TDemo.AddMouseLUp(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  Kind := dekMouseLUp;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDWord(KeyState);
end;
{ @end $467814 }

{ @routine $467874 TDemo_GetMouseLUp }
procedure TDemo.GetMouseLUp(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekMouseLUp then raise Exception.Create('TDemo.GetMouseLUp');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  KeyState := Buffer.GetUInt32;
end;
{ @end $467874 }

{ @routine $467900 TDemo_AddMouseRDown }
procedure TDemo.AddMouseRDown(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  Kind := dekMouseRDown;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDWord(KeyState);
end;
{ @end $467900 }

{ @routine $467960 TDemo_GetMouseRDown }
procedure TDemo.GetMouseRDown(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekMouseRDown then raise Exception.Create('TDemo.GetMouseRDown');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  KeyState := Buffer.GetUInt32;
end;
{ @end $467960 }

{ @routine $4679EC TDemo_AddMouseRUp }
procedure TDemo.AddMouseRUp(TimeDelta: Cardinal; Position: TPoint; KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  Kind := dekMouseRUp;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
  Buffer.AddDWord(KeyState);
end;
{ @end $4679EC }

{ @routine $467A4C TDemo_GetMouseRUp }
procedure TDemo.GetMouseRUp(var TimeDelta: Cardinal; var Position: TPoint; var KeyState: Cardinal);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekMouseRUp then raise Exception.Create('TDemo.GetMouseRUp');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
  KeyState := Buffer.GetUInt32;
end;
{ @end $467A4C }

{ @routine $467AD8 TDemo_AddFormStart }
procedure TDemo.AddFormStart(Name: WideString);
var Kind: TDemoEventKind;
begin
  Kind := dekFormStart;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddWideStringZ(Name);
end;
{ @end $467AD8 }

{ @routine $467B40 TDemo_GetFormStart }
procedure TDemo.GetFormStart(var Name: WideString);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekFormStart then raise Exception.Create('TDemo.GetFormStart');
  Name := Buffer.ReadWideString;
end;
{ @end $467B40 }

{ @routine $467BE0 TDemo_AddGameLoad }
procedure TDemo.AddGameLoad(Name: WideString);
var Kind: TDemoEventKind;
begin
  Kind := dekGameLoad;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddWideStringZ(Name);
end;
{ @end $467BE0 }

{ @routine $467C48 TDemo_GetGameLoad }
procedure TDemo.GetGameLoad(var Name: WideString);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekGameLoad then raise Exception.Create('TDemo.GetGameLoad');
  Name := Buffer.ReadWideString;
end;
{ @end $467C48 }

{ @routine $467CE8 TDemo_AddSpacePos }
procedure TDemo.AddSpacePos(TimeDelta: Cardinal; Position: TPoint);
var Kind: TDemoEventKind;
begin
  Kind := dekSpacePos;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddIntegerValue(Position.X);
  Buffer.AddIntegerValue(Position.Y);
end;
{ @end $467CE8 }

{ @routine $467D3C TDemo_GetSpacePos }
procedure TDemo.GetSpacePos(var TimeDelta: Cardinal; var Position: TPoint);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekSpacePos then raise Exception.Create('TDemo.GetSpacePos');
  TimeDelta := Buffer.GetUInt32;
  Position.X := Buffer.GetInt32;
  Position.Y := Buffer.GetInt32;
end;
{ @end $467D3C }

{ @routine $467DB4 TDemo_AddState }
procedure TDemo.AddState(TimeDelta: Cardinal; Text: WideString; Position: TPoint);
var Kind: TDemoEventKind;
begin
  Kind := dekState;
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddDWord(TimeDelta);
  Buffer.AddWideStringZ(Text);
  { Unlike mouse positions, state positions are truncated to single bytes. }
  Buffer.AddAnsiChar(AnsiChar(Position.X));
  Buffer.AddAnsiChar(AnsiChar(Position.Y));
end;
{ @end $467DB4 }

{ @routine $467E4C TDemo_GetState }
procedure TDemo.GetState(var TimeDelta: Cardinal; var Text: WideString; var Position: TPoint);
var Kind: TDemoEventKind;
begin
  WriteByteValue(Buffer.GetByte, Kind);
  if Kind <> dekState then raise Exception.Create('TDemo.GetState');
  TimeDelta := Buffer.GetUInt32;
  Text := Buffer.ReadWideString;
  Position.X := Buffer.GetByte;
  Position.Y := Buffer.GetByte;
end;
{ @end $467E4C }

{ @routine $467F1C TDemo_LoadFromTextBuffer }
procedure TDemo.LoadFromTextBuffer(Input: TBufEC);
var
  Definitions, State: TBlockParEC;
  I, J, MoveCount: Integer;
  Text, Part: WideString;
  TimeDelta: Cardinal;
  Position: TPoint;
  KeyState: Cardinal;
begin
  Clear;
  Definitions := TBlockParEC.Create;
  Definitions.LoadFromTextBufferWithEncodingProbe(Input, False);
  for I := 0 to Definitions.GetEntryCount - 1 do
  begin
    case Definitions.GetEntryKindByIndex(I) of
      bpkString:
      begin
        Text := Definitions.GetEntryNameByIndex(I);
        if Text = 'MouseMove' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          { Each move ends with ]. The native parser ignores the final part,
            including an unterminated last move, and ignores nondigits in fields. }
          MoveCount := CountDelimitedPartsW(Text, ']') - 1;
          for J := 0 to MoveCount - 1 do
          begin
            Part := ExtractDelimitedPartW(Text, J, ']');
            TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 0, ','));
            Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 1, ','));
            Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 2, ','));
            KeyState := 0;
            if CountDelimitedPartsW(Part, ',') > 3 then
              KeyState := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 3, ','));
            AddMouseMove(TimeDelta, Position, KeyState);
          end;
        end
        else if Text = 'MouseLDown' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
          KeyState := 0;
          if CountDelimitedPartsW(Text, ',') > 3 then
            KeyState := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 3, ','));
          AddMouseLDown(TimeDelta, Position, KeyState);
        end
        else if Text = 'MouseLUp' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
          KeyState := 0;
          if CountDelimitedPartsW(Text, ',') > 3 then
            KeyState := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 3, ','));
          AddMouseLUp(TimeDelta, Position, KeyState);
        end
        else if Text = 'MouseRDown' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
          KeyState := 0;
          if CountDelimitedPartsW(Text, ',') > 3 then
            KeyState := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 3, ','));
          AddMouseRDown(TimeDelta, Position, KeyState);
        end
        else if Text = 'MouseRUp' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
          KeyState := 0;
          if CountDelimitedPartsW(Text, ',') > 3 then
            KeyState := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 3, ','));
          AddMouseRUp(TimeDelta, Position, KeyState);
        end
        else if Text = 'FormStart' then
          AddFormStart(Definitions.GetEntryStringByIndex(I))
        else if Text = 'GameLoad' then
          AddGameLoad(Definitions.GetEntryStringByIndex(I))
        else if Text = 'SpacePos' then
        begin
          Text := Definitions.GetEntryStringByIndex(I);
          TimeDelta := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 2, ','));
          AddSpacePos(TimeDelta, Position);
        end
        else raise Exception.Create('TDemo.LoadText unknown order=' + Text);
      end;
      else
      begin
        Text := Definitions.GetEntryNameByIndex(I);
        if Text = 'State' then
        begin
          State := Definitions.GetEntryBlockByIndex(I);
          TimeDelta := ExtractDigitsToIntW(State.GetParam('Time'));
          Position.X := ExtractDigitsToIntW(ExtractDelimitedPartW(State.GetParam('Pos'), 0, ','));
          Position.Y := ExtractDigitsToIntW(ExtractDelimitedPartW(State.GetParam('Pos'), 1, ','));
          Text := '';
          for J := 0 to State.CountParams('Text') - 1 do
            Text := Text + State.GetParamByPath('Text:' + IntToStr(J)) + #13#10;
          AddState(TimeDelta, Text, Position);
        end;
      end;
    end;
  end;
  { Native cleanup is on the success path only. }
  Definitions.Free;
  SeekStart;
end;
{ @end $467F1C }

{ @routine $468868 TDemo_LoadTextFile }
procedure TDemo.LoadTextFile(FileName: WideString);
var Input: TBufEC;
begin
  Input := TBufEC.Create;
  Input.LoadFromFilePath(PAnsiChar(AnsiString(FileName)));
  LoadFromTextBuffer(Input);
  Input.Free;
end;
{ @end $468868 }

end.

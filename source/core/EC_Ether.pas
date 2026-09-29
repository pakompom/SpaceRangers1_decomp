unit EC_Ether;
// Unit bracket (inferred): CODE 0x004C5570..0x004C5A2B; inclusive evidence, not full bounds.

interface

uses EC_Struct, EC_Buf, SyncObjs;

type
  TEtherUnit = class(TObject) // @size $14
  public
    Prev: TEtherUnit; // @offset $04
    Next: TEtherUnit; // @offset $08
    Value: Integer; // @offset $0C
    Name: WideString; // @offset $10
  end;
  PEtherIndex = ^TEtherIndex;
  TEtherIndex = array[0..$1FFFFFFE] of TEtherUnit;

  TEther = class(TObjectEx) // @size $18
  public
    First: TEtherUnit; // @offset $04
    Last: TEtherUnit; // @offset $08
    Count: Integer; // @offset $0C
    SortedItems: PEtherIndex; // @offset $10
    Lock: TCriticalSection; // @offset $14
    constructor Create; // @addr $4C5630
    destructor Destroy; override; // @addr $4C5674 @note "Native destructor leaves the critical section; it does not free the lock or clear entries."
    procedure Clear; // @addr $4C56A4
    function AppendEntry: TEtherUnit; // @addr $4C56D4
    procedure RemoveEntry(Item: TEtherUnit); // @addr $4C5708 @note "Unlinks and frees the entry without updating SortedItems or Count."
    function GetIndexedEntry(Index: Integer): TEtherUnit; // @addr $4C5744 @note "Native assembly restores EAX after loading the entry, returning Self instead of the indexed value."
    procedure SetIndexedEntry(Index: Integer; Item: TEtherUnit); // @addr $4C5758
    function FindIndex(const Name: WideString): Integer; // @addr $4C57E8
    function FindInsertionIndex(const Name: WideString): Integer; // @addr $4C576C
    procedure Add(const Name: WideString; Value: Integer); // @addr $4C587C
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $4C5928
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $4C5960
    procedure Enter; // @addr $4C59DC
    procedure Leave; // @addr $4C59E8
  end;

implementation

// @unit-initialization $4C5A24
// @unit-finalization $4C59F4

uses EC_Mem, EC_Str;

{ @routine $4C5630 TEther_Create }
constructor TEther.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
end;
{ @end $4C5630 }

{ @routine $4C5674 TEther_Destroy }
destructor TEther.Destroy;
begin
  Lock.Leave;
  inherited Destroy;
end;
{ @end $4C5674 }

{ @routine $4C56A4 TEther_Clear }
procedure TEther.Clear;
begin
  while First <> nil do RemoveEntry(Last);
  if SortedItems <> nil then begin FreeEC(SortedItems); SortedItems := nil; end;
  Count := 0;
end;
{ @end $4C56A4 }

{ @routine $4C56D4 TEther_AppendEntry }
function TEther.AppendEntry: TEtherUnit;
var Item: TEtherUnit;
begin
  Item := TEtherUnit.Create;
  if Last <> nil then Last.Next := Item;
  Item.Prev := Last; Item.Next := nil; Last := Item;
  if First = nil then First := Item;
  Result := Item;
end;
{ @end $4C56D4 }

{ @routine $4C5708 TEther_RemoveEntry }
procedure TEther.RemoveEntry(Item: TEtherUnit);
begin
  if Item.Prev <> nil then Item.Prev.Next := Item.Next;
  if Item.Next <> nil then Item.Next.Prev := Item.Prev;
  if Last = Item then Last := Item.Prev;
  if First = Item then First := Item.Next;
  Item.Free;
end;
{ @end $4C5708 }

{ @routine $4C5744 TEther_GetIndexedEntry }
function TEther.GetIndexedEntry(Index: Integer): TEtherUnit;
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, EAX
  MOV EAX, EDX
  SHL EAX, 2
  ADD EAX, [EBX].TEther.SortedItems
  MOV EAX, [EAX]
  POP EBX
  POP EAX
end;
{ @end $4C5744 }

{ @routine $4C5758 TEther_SetIndexedEntry }
procedure TEther.SetIndexedEntry(Index: Integer; Item: TEtherUnit);
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, EAX
  MOV EAX, EDX
  SHL EAX, 2
  ADD EAX, [EBX].TEther.SortedItems
  MOV EBX, ECX
  MOV [EAX], EBX
  POP EBX
  POP EAX
end;
{ @end $4C5758 }

{ @routine $4C576C TEther_FindInsertionIndex }
function TEther.FindInsertionIndex(const Name: WideString): Integer;
var Left, Right, Middle, Comparison: Integer; Item: TEtherUnit;
begin
  if Count <= 0 then begin Result := 0; Exit; end;
  Left := 0; Right := Count - 1;
  repeat
    Middle := ((Right - Left) shr 1) + Left;
    Item := GetIndexedEntry(Middle);
    Comparison := CompareWideChars(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then begin Result := Middle; Exit; end;
    if Comparison < 0 then Right := Middle - 1 else Left := Middle + 1;
  until Right < Left;
  if Comparison < 0 then Result := Middle else Result := Middle + 1;
end;
{ @end $4C576C }

{ @routine $4C57E8 TEther_FindIndex }
function TEther.FindIndex(const Name: WideString): Integer;
var LowIndex, HighIndex, Middle, Comparison: Integer; Item: TEtherUnit;
begin
  Enter;
  if Count < 1 then
  begin
    Result := -1;
    Leave;
    Exit;
  end;
  LowIndex := 0;
  HighIndex := Count - 1;
  repeat
    Middle := ((HighIndex - LowIndex) shr 1) + LowIndex;
    Item := GetIndexedEntry(Middle);
    Comparison := CompareWideChars(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := Middle;
      Leave;
      Exit;
    end
    else if Comparison < 0 then HighIndex := Middle - 1
    else LowIndex := Middle + 1;
    if HighIndex < LowIndex then
    begin
      Result := -1;
      Leave;
      Exit;
    end;
  until False;
end;
{ @end $4C57E8 }

{ @routine $4C587C TEther_Add }
procedure TEther.Add(const Name: WideString; Value: Integer);
var MoveCount: Integer; Item: TEtherUnit; Index: Integer;
begin
  Enter;
  Item := AppendEntry;
  Item.Name := Name; Item.Value := Value;
  Index := FindInsertionIndex(Name);
  Inc(Count);
  SortedItems := ReAllocREC(SortedItems, Count * SizeOf(TEtherUnit));
  MoveCount := Count - 1 - Index;
  if MoveCount > 0 then
  asm
    PUSH EBX
    PUSH EAX
    PUSH EDX
    MOV EBX, Self
    MOV EDX, [EBX].TEther.Count
    SUB EDX, 1
    SHL EDX, 2
    ADD EDX, [EBX].TEther.SortedItems
    MOV ECX, MoveCount
  @@Move:
    MOV EAX, [EDX - 4]
    MOV [EDX], EAX
    SUB EDX, 4
    DEC ECX
    JNZ @@Move
    POP EDX
    POP EAX
    POP EBX
  end;
  SetIndexedEntry(Index, Item);
  Leave;
end;
{ @end $4C587C }

{ @routine $4C5928 TEther_SaveToBuffer }
procedure TEther.SaveToBuffer(Buffer: TBufEC);
var Item: TEtherUnit;
begin
  Buffer.AddIntegerValue(Count);
  Item := First;
  while Item <> nil do
  begin
    Buffer.AddWideStringZ(Item.Name); Buffer.AddIntegerValue(Item.Value);
    Item := Item.Next;
  end;
end;
{ @end $4C5928 }

{ @routine $4C5960 TEther_LoadFromBuffer }
procedure TEther.LoadFromBuffer(Buffer: TBufEC);
var Name: WideString; Index, ItemCount, Value: Integer;
begin
  Clear;
  ItemCount := Buffer.GetInt32;
  for Index := 0 to ItemCount - 1 do
  begin
    Name := Buffer.ReadWideString; Value := Buffer.GetInt32;
    Add(Name, Value);
  end;
end;
{ @end $4C5960 }

{ @routine $4C59DC TEther_Enter }
procedure TEther.Enter;
begin
  Lock.Enter;
end;
{ @end $4C59DC }

{ @routine $4C59E8 TEther_Leave }
procedure TEther.Leave;
begin
  Lock.Leave;
end;
{ @end $4C59E8 }

end.

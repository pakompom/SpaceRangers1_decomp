unit EC_BlockPar;
// Unit bracket (inferred): CODE 0x00464DE4..0x004674F3; inclusive evidence, not full bounds.

interface

uses EC_Buf, EC_Struct;

type
  TBlockParKind = (bpkText = 0, bpkString = 1, bpkBlock = 2); // @size $04
  TBlockParEC = class;
  PBlockParEC = ^TBlockParEC;

  TBlockParElEC = class(TObjectEx) // @size $2C
  public
    Prev: TBlockParElEC; // @offset $04
    Next: TBlockParElEC; // @offset $08
    OwnerBlock: TBlockParEC; // @offset $0C
    ItemType: TBlockParKind; // @offset $10
    Name: WideString; // @offset $14
    StringValue: WideString; // @offset $18
    Comment: WideString; // @offset $1C
    ChildBlock: TBlockParEC; // @offset $20
    // Sorted entries group equal names and kinds; GroupCount is valid at the head.
    GroupIndex: Integer; // @offset $24
    GroupCount: Integer; // @offset $28

    constructor Create; // @addr $464F1C
    destructor Destroy; override; // @addr $464F54
    procedure Clear; // @addr $464F80 @note "Frees ChildBlock; links and index metadata remain unchanged."
    procedure MakeChildBlock; // @addr $464FB4 @note "Replaces the owned child; caller must update owner counts and index."
  end;
  PBlockParElEC = ^TBlockParElEC;

  TBlockParEC = class(TObjectEx) // @size $24
  public
    procedure WriteUnicodeTextIndented(Buf: TBufEC; Indent: Integer); // @addr $466740
    procedure WriteAnsiTextIndented(Buf: TBufEC; Indent: Integer); // @addr $4668D8
    procedure WriteTextBuffer(Buf: TBufEC; AnsiText: Boolean); // @addr $466B48
    procedure SaveTextFile(FileName: PAnsiChar; AnsiText: Boolean); // @addr $466B7C
    FirstEntry: TBlockParElEC; // @offset $04
    LastEntry: TBlockParElEC; // @offset $08
    EntryCount: Integer; // @offset $0C
    StringParamCount: Integer; // @offset $10
    ChildBlockCount: Integer; // @offset $14
    UseSortedIndex: Boolean; // @offset $18
    // Delphi dynamic array; ordered by case-sensitive name, then kind.
    SortedEntries: array of TBlockParElEC; // @offset $1C
    SortedEntryCount: Integer; // @offset $20

    constructor Create; // @addr $464FE8
    destructor Destroy; override; // @addr $465024
    procedure Clear; // @addr $465050 @note "Preserves UseSortedIndex."
    function AddEntry: TBlockParElEC; // @addr $465098 @note "Caller must maintain kind counts and the sorted index."
    procedure DeleteEntry(Entry: TBlockParElEC); // @addr $4650D0 @note "Frees Entry but leaves its sorted-index entry intact."
    function FindEntryByPath(const Path: WideString): TBlockParElEC; // @addr $46529C @note "Dot, slash and backslash separate components; a :number suffix selects a zero-based occurrence."
    function FindSortedNameRangeStartIndex(const EntryName: WideString): Integer; // @addr $46548C @note "Returns -1 when absent."
    function PrepareSortedInsertion(Entry: TBlockParElEC): Integer; // @addr $465508 @note "Also updates duplicate-group metadata."
    procedure InsertIntoSortedIndex(Entry: TBlockParElEC); // @addr $4655C8
    procedure RemoveFromSortedIndex(Entry: TBlockParElEC); // @addr $465630

    // Params are string entries; blocks have separate accessors. ByPath traverses
    // subtrees, while ParamName addresses a direct child. OrMarker returns
    // '[name]' or '[path]' when missing; ordinary getters raise instead.
    function GetParamByPath(const Path: WideString): WideString; // @addr $4656E8
    function CountParamsByPath(const Path: WideString): Integer; // @addr $46579C @note "Creates missing intermediate subtrees."
    function AddParam(const ParamName, ParamValue: WideString): TBlockParElEC; // @addr $465850
    procedure SetOrAddParam(const ParamName, ParamValue: WideString); // @addr $465898
    procedure DeleteChildBlock(const BlockName: WideString); // @addr $4658E0 @note "Only the first match is affected; raises when absent."
    function GetParam(const ParamName: WideString): WideString; // @addr $4659D0
    function GetParamOrMarker(const ParamName: WideString): WideString; // @addr $465AB4
    function GetParamCount: Integer; // @addr $465AF4
    function CountParams(const ParamName: WideString): Integer; // @addr $465AF8
    // GetParamValue/GetParamName take zero-based string-entry indexes.
    // Kind-specific indexes use sorted order only when all entries have that kind.
    function GetParamValue(Index: Integer): WideString; // @addr $465B64
    function GetParamName(Index: Integer): WideString; // @addr $465C44
    function AddBlockByPath(const Path: WideString): TBlockParEC; // @addr $465D28 @note "Nested insertion updates the receiver's index and block count."
    function GetBlockByPath(const Path: WideString): TBlockParEC; // @addr $465E0C @note "Raises when Path is absent or is not a block."
    function GetOrAddBlockByPath(const Path: WideString): TBlockParEC; // @addr $465ED8
    property BlockPath[const Path: WideString]: TBlockParEC read GetBlockByPath;
    function GetOrAddChildBlock(const Path: WideString): TBlockParEC; // @addr $466080
    function AddChildBlock(const BlockName: WideString): TBlockParEC; // @addr $465F38
    function GetBlock(const BlockName: WideString): TBlockParEC; // @addr $465F74 @note "Raises when absent."
    function FindBlock(const BlockName: WideString): TBlockParEC; // @addr $466050
    function GetBlockCount: Integer; // @addr $4660A0
    function CountBlocks(const BlockName: WideString): Integer; // @addr $4660A4
    function GetBlockByIndex(Index: Integer): TBlockParEC; // @addr $466110
    function GetBlockNameByIndex(Index: Integer): WideString; // @addr $4661DC

    function GetEntryCount: Integer; // @addr $4662C0
    // Mixed-kind indexes use the sorted array only when it covers every entry.
    function GetEntryKindByIndex(Index: Integer): TBlockParKind; // @addr $4662C4
    function GetEntryBlockByIndex(Index: Integer): TBlockParEC; // @addr $466388
    function GetEntryStringByIndex(Index: Integer): WideString; // @addr $4664B8
    function GetEntryNameByIndex(Index: Integer): WideString; // @addr $4665F4

    // Text writers append at Dest.Position. Sorted applies only with UseSortedIndex.
    // Text parsers append entries; they do not clear the existing tree.
    procedure ParseTextBuffer(Buf: TBufEC; const InitialText: WideString; AnsiText, PreserveComments: Boolean); // @addr $466C58
    procedure LoadFromTextBufferWithEncodingProbe(Buf: TBufEC; PreserveComments: Boolean); // @addr $467078 @note "Does nothing with at most two bytes remaining; otherwise consumes a UTF-16LE BOM or parses ANSI text."
    procedure LoadFromTextFileWithEncodingProbe(FileName: PAnsiChar; PreserveComments: Boolean); // @addr $4670C8
    procedure WriteEncodedBuffer(Buf: TBufEC); // @addr $46712C
    procedure SaveEncodedFile(const FileName: WideString); // @addr $467380
    procedure LoadEncodedFile(const FileName: WideString); // @addr $46743C
    procedure LoadFromDecodedBuffer(Buf: TBufEC); // @addr $467238 @note "Replaces existing contents; trusts sorted-group metadata from the stream."
  end;

const

implementation

// @unit-initialization $4674EC
// @unit-finalization $4674BC

uses EC_File, EC_Str, SysUtils, Windows;

{ @routine $464F1C TBlockParElEC_Create }
constructor TBlockParElEC.Create;
begin inherited Create end;
{ @end $464F1C }

{ @routine $464F54 TBlockParElEC_Destroy }
destructor TBlockParElEC.Destroy;
begin Clear; inherited Destroy end;
{ @end $464F54 }

{ @routine $464F80 TBlockParElEC_Clear }
procedure TBlockParElEC.Clear;
begin
  if ChildBlock <> nil then
  begin ChildBlock.Free; ChildBlock := nil end;
  ItemType := bpkText;
  Name := '';
  StringValue := '';
  Comment := '';
end;
{ @end $464F80 }

{ @routine $464FB4 TBlockParElEC_MakeChildBlock }
procedure TBlockParElEC.MakeChildBlock;
begin
  if ChildBlock <> nil then
  begin ChildBlock.Free; ChildBlock := nil end;
  ChildBlock := TBlockParEC.Create;
  ItemType := bpkBlock;
  StringValue := '';
end;
{ @end $464FB4 }

{ @routine $464FE8 TBlockParEC_Create }
constructor TBlockParEC.Create;
begin inherited Create; UseSortedIndex := True end;
{ @end $464FE8 }

{ @routine $465024 TBlockParEC_Destroy }
destructor TBlockParEC.Destroy;
begin Clear; inherited Destroy end;
{ @end $465024 }

{ @routine $465050 TBlockParEC_Clear }
procedure TBlockParEC.Clear;
var Entry, Removed: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    Removed := Entry;
    Entry := Entry.Next;
    Removed.Free;
  end;
  FirstEntry := nil;
  LastEntry := nil;
  EntryCount := 0;
  StringParamCount := 0;
  ChildBlockCount := 0;
  SortedEntries := nil;
  SortedEntryCount := 0;
end;
{ @end $465050 }

{ @routine $465098 TBlockParEC_AddEntry }
function TBlockParEC.AddEntry: TBlockParElEC;
var Entry: TBlockParElEC;
begin
  Entry := TBlockParElEC.Create;
  Entry.OwnerBlock := Self;
  if LastEntry <> nil then LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then FirstEntry := Entry;
  Inc(EntryCount);
  Result := Entry;
end;
{ @end $465098 }

{ @routine $4650D0 TBlockParEC_DeleteEntry }
procedure TBlockParEC.DeleteEntry(Entry: TBlockParElEC);
begin
  if Entry.Prev <> nil then Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then LastEntry := Entry.Prev;
  if FirstEntry = Entry then FirstEntry := Entry.Next;
  Dec(EntryCount);
  if Entry.ItemType = bpkString then Dec(StringParamCount)
  else if Entry.ItemType = bpkBlock then Dec(ChildBlockCount);
  Entry.Free;
end;
{ @end $4650D0 }

{ @routine $46529C TBlockParEC_FindEntryByPath }
function TBlockParEC.FindEntryByPath(const Path: WideString): TBlockParElEC;
var
  Cursor, PathLength, Start, PartLength, Occurrence: Integer;
  Index, Seen: Integer;
  Entry: TBlockParElEC;
  Block: TBlockParEC;

  // @nested $465124 NextBlockPathComponent
  function NextBlockPathComponent: Boolean; // @addr $465124 @note "Nested helper of TBlockParEC.FindEntryByPath."
  var
    Ch: WideChar;
    i: Integer;
  begin
    if Cursor >= PathLength then
    begin Result := False; Exit end;
    Start := Cursor;
    i := Start;
    while PathLength > i do
    begin
      Ch := Path[i + 1];
      if (Ch = '.') or (Ch = '/') or (Ch = '\') then Break;
      Inc(i);
    end;
    PartLength := i - Start;
    Cursor := i + 1;
    Result := True;
  end;

  // @nested $465194 ParseBlockPathOccurrence
  procedure ParseBlockPathOccurrence; // @addr $465194 @note "Nested helper of TBlockParEC.FindEntryByPath."
  var i, Limit: Integer;
      Ch: WideChar;
  begin
    Occurrence := 0;
    i := Start;
    Limit := Start + PartLength;
    while i < Limit do
    begin
      if Path[i + 1] = ':' then
      begin
        PartLength := i - Start;
        Inc(i);
        while i < Limit do
        begin
          Ch := Path[i + 1];
          if (Ch >= '0') and (Ch <= '9') then Occurrence := Occurrence * 10 + (Ord(Ch) - Ord('0'));
          Inc(i);
        end;
        Break;
      end;
      Inc(i);
    end;
  end;

  // @nested $465214 MatchBlockPathComponent
  function MatchBlockPathComponent(Name: WideString): Boolean; // @addr $465214
  begin
    if Length(Name) <> PartLength then Result := False
    else Result := SysUtils.CompareMem(Pointer(PAnsiChar(PWideChar(Path)) + Start * SizeOf(WideChar)), PWideChar(Name), PartLength * 2);
  end;

begin
  PathLength := Length(Path);
  Cursor := 0;
  Block := Self;
  Entry := nil;
  while NextBlockPathComponent do
  begin
    ParseBlockPathOccurrence;
    if Block.UseSortedIndex then
    begin
      Entry := nil;
      Index := Block.FindSortedNameRangeStartIndex(Copy(Path, Start + 1, PartLength));
      if Index >= 0 then
      begin
        Entry := Block.SortedEntries[Index];
        if Occurrence <> 0 then
        begin
          if Occurrence < Entry.GroupCount then Entry := Block.SortedEntries[Index + Occurrence]
          else Entry := nil;
        end;
      end;
    end
    else
    begin
      Entry := Block.FirstEntry;
      Seen := 0;
      while (Seen <= Occurrence) and (Entry <> nil) do
      begin
        while Entry <> nil do
        begin
          if MatchBlockPathComponent(Entry.Name) then
          begin
            if Seen < Occurrence then Entry := Entry.Next;
            Break;
          end;
          Entry := Entry.Next;
        end;
        Inc(Seen);
      end;
    end;
    if Entry = nil then
    begin
      raise Exception.Create('GetEl. Path=' + Path);
    end;
    if Cursor >= PathLength then Break;
    if Entry.ItemType <> bpkBlock then
    begin
      raise Exception.Create('GetEl. Path=' + Path);
    end;
    Block := Entry.ChildBlock;
  end;
  if Entry = nil then
  begin
    raise Exception.Create('GetEl. Path=' + Path);
  end;
  Result := Entry;
end;
{ @end $46529C }

{ @routine $46548C TBlockParEC_FindSortedNameRangeStartIndex }
function TBlockParEC.FindSortedNameRangeStartIndex(const EntryName: WideString): Integer;
var
  Low, High, Middle, Order: Integer;
  Entry: TBlockParElEC;
begin
  if SortedEntryCount < 1 then
  begin
    Result := -1;
    Exit
  end;
  Low := 0;
  High := SortedEntryCount - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Entry := SortedEntries[Middle];
    Order := CompareWideChars(PWideChar(EntryName), PWideChar(Entry.Name));
    if Order = 0 then
    begin
      Result := Middle - Entry.GroupIndex;
      Exit
    end
    else if Order < 0 then High := Middle - 1
    else Low := Middle + 1;
  until High < Low;
  Result := -1;
end;
{ @end $46548C }

{ @routine $465508 TBlockParEC_PrepareSortedInsertion }
function TBlockParEC.PrepareSortedInsertion(Entry: TBlockParElEC): Integer;
var Low, High, Middle, Order: Integer;
    Existing: TBlockParElEC;
begin
  if SortedEntryCount <= 0 then
  begin
    Result := 0;
    Entry.GroupIndex := 0;
    Entry.GroupCount := 1;
    Exit;
  end;
  Low := 0;
  High := SortedEntryCount - 1;
  repeat
    Middle := (High - Low) shr 1 + Low;
    Existing := SortedEntries[Middle];
    Order := CompareWideChars(PWideChar(Entry.Name), PWideChar(Existing.Name));
    if Order = 0 then
    begin
      if Existing.GroupIndex <> 0 then
      begin
        Result := Middle - Existing.GroupIndex;
        Existing := SortedEntries[Result];
      end
      else Result := Middle;
      Entry.GroupIndex := Existing.GroupCount;
      Result := Result + Existing.GroupCount;
      Inc(Existing.GroupCount);
      Exit;
    end;
    if Order < 0 then High := Middle - 1 else Low := Middle + 1;
    if High < Low then
    begin
      if Order < 0 then Result := Middle else Result := Middle + 1;
      Entry.GroupIndex := 0;
      Entry.GroupCount := 1;
      Exit;
    end;
  until False;
end;
{ @end $465508 }

{ @routine $4655C8 TBlockParEC_InsertIntoSortedIndex }
procedure TBlockParEC.InsertIntoSortedIndex(Entry: TBlockParElEC);
var Index: Integer;
begin
  SetLength(SortedEntries, SortedEntryCount + 1);
  Index := PrepareSortedInsertion(Entry);
  if Index >= SortedEntryCount then
  begin
    SortedEntries[SortedEntryCount] := Entry;
    Inc(SortedEntryCount);
  end
  else
  begin
    Windows.MoveMemory(@SortedEntries[Index + 1], @SortedEntries[Index], (SortedEntryCount - Index) * SizeOf(SortedEntries[0]));
    SortedEntries[Index] := Entry;
    Inc(SortedEntryCount);
  end;
end;
{ @end $4655C8 }

{ @routine $465630 TBlockParEC_RemoveFromSortedIndex }
procedure TBlockParEC.RemoveFromSortedIndex(Entry: TBlockParElEC);
var i, Index: Integer;
    Head: TBlockParElEC;
begin
  Index := 0;
  while Index < SortedEntryCount do
  begin
    if SortedEntries[Index] = Entry then
    begin
      Head := SortedEntries[Index - Entry.GroupIndex];
      for i := Index + 1 to Index - Entry.GroupIndex + Head.GroupCount - 1 do
        Dec(SortedEntries[i].GroupIndex);
      Dec(Head.GroupCount);
      if Entry.GroupIndex = 0 then
        if Head.GroupCount > 0 then SortedEntries[Index + 1].GroupCount := Entry.GroupCount;
      if Index < SortedEntryCount - 1 then
        Windows.MoveMemory(@SortedEntries[Index], @SortedEntries[Index + 1], (SortedEntryCount - Index - 1) * SizeOf(SortedEntries[0]));
      Dec(SortedEntryCount);
      SetLength(SortedEntries, SortedEntryCount);
      Exit;
    end;
    Inc(Index);
  end;
end;
{ @end $465630 }

{ @routine $4656E8 TBlockParEC_GetParamByPath }
function TBlockParEC.GetParamByPath(const Path: WideString): WideString;
var Entry: TBlockParElEC;
begin
  Entry := FindEntryByPath(Path);
  if Entry.ItemType <> bpkString then raise Exception.Create('Par_Get. Path=' + Path);
  Result := Entry.StringValue;
end;
{ @end $4656E8 }

{ @routine $46579C TBlockParEC_CountParamsByPath }
function TBlockParEC.CountParamsByPath(const Path: WideString): Integer;
var Count: Integer;
    Part: WideString;
    Block: TBlockParEC;
begin
  Count := CountDelimitedPartsW(Path, './\');
  if Count > 1 then
  begin
    Block := GetOrAddBlockByPath(ExtractDelimitedRangeW(Path, 0, Count - 2, './\'));
    Part := ExtractDelimitedPartW(Path, Count - 1, './\');
  end
  else
  begin
    Part := Path;
    Block := Self;
  end;
  Result := Block.CountParams(Part);
end;
{ @end $46579C }

{ @routine $465850 TBlockParEC_AddParam }
function TBlockParEC.AddParam(const ParamName, ParamValue: WideString): TBlockParElEC;
var Entry: TBlockParElEC;
begin
  Entry := AddEntry;
  Entry.ItemType := bpkString;
  Entry.Name := ParamName;
  Entry.StringValue := ParamValue;
  if UseSortedIndex then InsertIntoSortedIndex(Entry);
  Inc(StringParamCount);
  Result := Entry;
end;
{ @end $465850 }

{ @routine $465898 TBlockParEC_SetOrAddParam }
procedure TBlockParEC.SetOrAddParam(const ParamName, ParamValue: WideString);
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Entry.StringValue := ParamValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  AddParam(ParamName, ParamValue);
end;
{ @end $465898 }

{ @routine $4658E0 TBlockParEC_DeleteChildBlock }
procedure TBlockParEC.DeleteChildBlock(const BlockName: WideString);
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      if UseSortedIndex then RemoveFromSortedIndex(Entry);
      DeleteEntry(Entry);
      Exit;
    end;
    Entry := Entry.Next;
  end;
  // Reports the Block_Get diagnostic even when deleting a block.
  raise Exception.Create('TBlockParEC.Block_Get. name=' + BlockName);
end;
{ @end $4658E0 }

{ @routine $4659D0 TBlockParEC_GetParam }
function TBlockParEC.GetParam(const ParamName: WideString): WideString;
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Result := Entry.StringValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  // Uses the same diagnostic for a missing parameter and block.
  raise Exception.Create('TBlockParEC.Block_Get. name=' + ParamName);
end;
{ @end $4659D0 }

{ @routine $465AB4 TBlockParEC_GetParamOrMarker }
function TBlockParEC.GetParamOrMarker(const ParamName: WideString): WideString;
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = ParamName) and (Entry.ItemType = bpkString) then
    begin
      Result := Entry.StringValue;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  // Returns empty for a missing parameter.
  Result := '';
end;
{ @end $465AB4 }

{ @routine $465AF4 TBlockParEC_GetParamCount }
function TBlockParEC.GetParamCount: Integer;
begin Result := StringParamCount end;
{ @end $465AF4 }

{ @routine $465AF8 TBlockParEC_CountParams }
function TBlockParEC.CountParams(const ParamName: WideString): Integer;
var Entry: TBlockParElEC;
    Count, Index, Limit: Integer;
begin
  if UseSortedIndex then
  begin
    Index := FindSortedNameRangeStartIndex(ParamName);
    Result := 0;
    if Index >= 0 then
    begin
      Limit := SortedEntries[Index].GroupCount + Index;
      while Index < Limit do
      begin
        Entry := SortedEntries[Index];
        if Entry.ItemType = bpkString then Inc(Result);
        Inc(Index);
      end;
    end;
  end
  else
  begin
    Entry := FirstEntry;
    Count := 0;
    while Entry <> nil do
    begin
      if (Entry.ItemType = bpkString) and (Entry.Name = ParamName) then Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  end;
end;
{ @end $465AF8 }

{ @routine $465B64 TBlockParEC_GetParamValue }
function TBlockParEC.GetParamValue(Index: Integer): WideString;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = StringParamCount) then Result := SortedEntries[Index].StringValue
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkString then
      begin
        if Index = 0 then
        begin Result := Entry.StringValue; Exit end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Par_Get. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $465B64 }

{ @routine $465C44 TBlockParEC_GetParamName }
function TBlockParEC.GetParamName(Index: Integer): WideString;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = StringParamCount) then Result := SortedEntries[Index].Name
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkString then
      begin
        if Index = 0 then
        begin Result := Entry.Name; Exit end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Par_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $465C44 }

{ @routine $465D28 TBlockParEC_AddBlockByPath }
function TBlockParEC.AddBlockByPath(const Path: WideString): TBlockParEC;
var Count: Integer;
    Part: WideString;
    Entry: TBlockParElEC;
    Block: TBlockParEC;
begin
  Count := CountDelimitedPartsW(Path, './\');
  if Count > 1 then
  begin
    Block := GetOrAddBlockByPath(ExtractDelimitedRangeW(Path, 0, Count - 2, './\'));
    Part := ExtractDelimitedPartW(Path, Count - 1, './\');
  end
  else
  begin
    Part := Path;
    Block := Self;
  end;
  Entry := Block.AddEntry;
  Entry.MakeChildBlock;
  Entry.Name := Part;
  if UseSortedIndex then InsertIntoSortedIndex(Entry);
  Inc(ChildBlockCount);
  Result := Entry.ChildBlock;
end;
{ @end $465D28 }

{ @routine $465E0C TBlockParEC_GetBlockByPath }
function TBlockParEC.GetBlockByPath(const Path: WideString): TBlockParEC;
var Entry: TBlockParElEC;
begin
  Entry := FindEntryByPath(Path);
  if Entry.ItemType <> bpkBlock then raise Exception.Create('TBlockParEC.BlockPath_Get. Path=' + Path);
  Result := Entry.ChildBlock;
end;
{ @end $465E0C }

{ @routine $465ED8 TBlockParEC_GetOrAddBlockByPath }
function TBlockParEC.GetOrAddBlockByPath(const Path: WideString): TBlockParEC;
begin
  try
    Result := GetBlockByPath(Path);
  except
    on E: Exception do Result := AddBlockByPath(Path);
  end;
end;
{ @end $465ED8 }

{ @routine $465F38 TBlockParEC_AddChildBlock }
function TBlockParEC.AddChildBlock(const BlockName: WideString): TBlockParEC;
var Entry: TBlockParElEC;
begin
  Entry := AddEntry;
  Entry.MakeChildBlock;
  Entry.Name := BlockName;
  if UseSortedIndex then InsertIntoSortedIndex(Entry);
  Inc(ChildBlockCount);
  Result := Entry.ChildBlock;
end;
{ @end $465F38 }

{ @routine $465F74 TBlockParEC_GetBlock }
function TBlockParEC.GetBlock(const BlockName: WideString): TBlockParEC;
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      Result := Entry.ChildBlock;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  raise Exception.Create('TBlockParEC.Block_Get. name=' + BlockName);
end;
{ @end $465F74 }

{ @routine $466050 TBlockParEC_FindBlock }
function TBlockParEC.FindBlock(const BlockName: WideString): TBlockParEC;
var Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if (Entry.Name = BlockName) and (Entry.ItemType = bpkBlock) then
    begin
      Result := Entry.ChildBlock;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $466050 }

{ @routine $466080 TBlockParEC_GetOrAddChildBlock }
function TBlockParEC.GetOrAddChildBlock(const Path: WideString): TBlockParEC;
begin
  Result := FindBlock(Path);
  if Result = nil then Result := AddChildBlock(Path);
end;
{ @end $466080 }

{ @routine $4660A0 TBlockParEC_GetBlockCount }
function TBlockParEC.GetBlockCount: Integer;
begin Result := ChildBlockCount end;
{ @end $4660A0 }

{ @routine $4660A4 TBlockParEC_CountBlocks }
function TBlockParEC.CountBlocks(const BlockName: WideString): Integer;
var Entry: TBlockParElEC;
    Count, Index, Limit: Integer;
begin
  if UseSortedIndex then
  begin
    Index := FindSortedNameRangeStartIndex(BlockName);
    Result := 0;
    if Index >= 0 then
    begin
      Limit := SortedEntries[Index].GroupCount + Index;
      while Index < Limit do
      begin
        Entry := SortedEntries[Index];
        if Entry.ItemType = bpkBlock then Inc(Result);
        Inc(Index);
      end;
    end;
  end
  else
  begin
    Entry := FirstEntry;
    Count := 0;
    while Entry <> nil do
    begin
      if (Entry.ItemType = bpkBlock) and (Entry.Name = BlockName) then Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  end;
end;
{ @end $4660A4 }

{ @routine $466110 TBlockParEC_GetBlockByIndex }
function TBlockParEC.GetBlockByIndex(Index: Integer): TBlockParEC;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = ChildBlockCount) then Result := SortedEntries[Index].ChildBlock
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkBlock then
      begin
        if Index = 0 then
        begin Result := Entry.ChildBlock; Exit end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Block_Get. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $466110 }

{ @routine $4661DC TBlockParEC_GetBlockNameByIndex }
function TBlockParEC.GetBlockNameByIndex(Index: Integer): WideString;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = ChildBlockCount) then Result := SortedEntries[Index].Name
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkBlock then
      begin
        if Index = 0 then
        begin Result := Entry.Name; Exit end;
        Dec(Index);
      end;
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.Block_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $4661DC }

{ @routine $4662C0 TBlockParEC_GetEntryCount }
function TBlockParEC.GetEntryCount: Integer;
begin Result := EntryCount end;
{ @end $4662C0 }

{ @routine $4662C4 TBlockParEC_GetEntryKindByIndex }
function TBlockParEC.GetEntryKindByIndex(Index: Integer): TBlockParKind;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Result := SortedEntries[Index].ItemType;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin

        Result := Entry.ItemType;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetTip. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $4662C4 }

{ @routine $466388 TBlockParEC_GetEntryBlockByIndex }
function TBlockParEC.GetEntryBlockByIndex(Index: Integer): TBlockParEC;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if Entry.ItemType <> bpkBlock then raise Exception.Create('TBlockParEC.All_GetBlock. Error tip.');
    Result := Entry.ChildBlock;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if Entry.ItemType <> bpkBlock then raise Exception.Create('TBlockParEC.All_GetBlock. Error tip.');
        Result := Entry.ChildBlock;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetBlock. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $466388 }

{ @routine $4664B8 TBlockParEC_GetEntryStringByIndex }
function TBlockParEC.GetEntryStringByIndex(Index: Integer): WideString;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if Entry.ItemType <> bpkString then raise Exception.Create('TBlockParEC.All_GetPar. Error tip.');
    Result := Entry.StringValue;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if Entry.ItemType <> bpkString then raise Exception.Create('TBlockParEC.All_GetPar. Error tip.');
        Result := Entry.StringValue;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetPar. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $4664B8 }

{ @routine $4665F4 TBlockParEC_GetEntryNameByIndex }
function TBlockParEC.GetEntryNameByIndex(Index: Integer): WideString;
var Entry: TBlockParElEC;
begin
  if UseSortedIndex and (EntryCount = SortedEntryCount) then
  begin
    Entry := SortedEntries[Index];
    if (Entry.ItemType <> bpkString) and (Entry.ItemType <> bpkBlock) then raise Exception.Create('TBlockParEC.All_GetName. Error tip.');
    Result := Entry.Name;
  end
  else
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Index = 0 then
      begin
        if (Entry.ItemType <> bpkString) and (Entry.ItemType <> bpkBlock) then raise Exception.Create('TBlockParEC.All_GetName. Error tip.');
        Result := Entry.Name;
        Exit;
      end;
      Dec(Index);
      Entry := Entry.Next;
    end;
    raise Exception.Create('TBlockParEC.All_GetName. no=' + SysUtils.IntToStr(Index));
  end;
end;
{ @end $4665F4 }

{ @routine $466740 TBlockParEC_WriteUnicodeTextIndented }
procedure TBlockParEC.WriteUnicodeTextIndented(Buf: TBufEC; Indent: Integer);
var
  I: Integer;
  Entry: TBlockParElEC;
begin
  Entry := FirstEntry;
  while Entry <> nil do begin
    if Entry.ItemType = bpkText then begin
        if Entry.Comment <> '' then Buf.AddWideStringRaw(Entry.Comment);
        Buf.AddWord(13); Buf.AddWord(10);
    end else if Entry.ItemType = bpkString then begin
        for I := 1 to Indent * 4 do Buf.AddWord(32);
        Buf.AddWideStringRaw(Entry.Name);
        Buf.AddWord(Ord('='));
        Buf.AddWideStringRaw(Entry.StringValue);
        if Entry.Comment <> '' then Buf.AddWideStringRaw(Entry.Comment);
        Buf.AddWord(13); Buf.AddWord(10);
    end else begin
      for I := 1 to Indent * 4 do Buf.AddWord(32);
      Buf.AddWideStringRaw(Entry.Name);
      Buf.AddWord(32);
      // The parent block supplies this flag, including for child blocks.
      if UseSortedIndex then Buf.AddWord(Ord('^')) else Buf.AddWord(Ord('~'));
      Buf.AddWord(Ord('{')); Buf.AddWord(13); Buf.AddWord(10);
      Entry.ChildBlock.WriteUnicodeTextIndented(Buf, Indent + 1);
      for I := 1 to Indent * 4 do Buf.AddWord(32);
      Buf.AddWord(Ord('}'));
      if Entry.Comment <> '' then Buf.AddWideStringRaw(Entry.Comment);
      Buf.AddWord(13); Buf.AddWord(10);
    end;
    Entry := Entry.Next;
  end;
end;
{ @end $466740 }

{ @routine $4668D8 TBlockParEC_WriteAnsiTextIndented }
procedure TBlockParEC.WriteAnsiTextIndented(Buf: TBufEC; Indent: Integer);
var
  I: Integer;
  Entry: TBlockParElEC;
begin
  // Converts through a NUL-terminated ANSI buffer.
  Entry := FirstEntry;
  while Entry <> nil do begin
    if Entry.ItemType = bpkText then begin
        if Entry.Comment <> '' then Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.Comment))));
        Buf.AddByte(13); Buf.AddByte(10);
    end else if Entry.ItemType = bpkString then begin
        for I := 1 to Indent * 4 do Buf.AddByte(32);
        Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.Name))));
        Buf.AddByte(Ord('='));
        Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.StringValue))));
        if Entry.Comment <> '' then Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.Comment))));
        Buf.AddByte(13); Buf.AddByte(10);
    end else begin
      for I := 1 to Indent * 4 do Buf.AddByte(32);
      Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.Name))));
      Buf.AddByte(32);
      // The parent block supplies this flag, including for child blocks.
      if UseSortedIndex then Buf.AddByte(Ord('^')) else Buf.AddByte(Ord('~'));
      Buf.AddByte(Ord('{')); Buf.AddByte(13); Buf.AddByte(10);
      Entry.ChildBlock.WriteAnsiTextIndented(Buf, Indent + 1);
      for I := 1 to Indent * 4 do Buf.AddByte(32);
      Buf.AddByte(Ord('}'));
      if Entry.Comment <> '' then Buf.AddAnsiStringRaw(AnsiString(PAnsiChar(AnsiString(Entry.Comment))));
      Buf.AddByte(13); Buf.AddByte(10);
    end;
    Entry := Entry.Next;
  end;
end;
{ @end $4668D8 }

{ @routine $466B48 TBlockParEC_WriteTextBuffer }
procedure TBlockParEC.WriteTextBuffer(Buf: TBufEC; AnsiText: Boolean);
begin
  if not AnsiText then begin
    Buf.AddWord($FEFF);
    WriteUnicodeTextIndented(Buf, 0);
  end else WriteAnsiTextIndented(Buf, 0);
end;
{ @end $466B48 }

{ @routine $466B7C TBlockParEC_SaveTextFile }
procedure TBlockParEC.SaveTextFile(FileName: PAnsiChar; AnsiText: Boolean);
var FileObj: TFileEC;
    Buf: TBufEC;
begin
  FileObj := TFileEC.Create;
  Buf := TBufEC.Create;
  try
    WriteTextBuffer(Buf, AnsiText);
    FileObj.SetFileName(AnsiString(FileName));
    FileObj.CreateNew;
    FileObj.WriteBuffer(Buf.Data, Buf.DataSize);
    FileObj.ReleaseHandle;
  finally
    FileObj.Free;
    Buf.Free;
  end;
end;
{ @end $466B7C }

{ @routine $466C58 TBlockParEC_ParseTextBuffer }
procedure TBlockParEC.ParseTextBuffer(Buf: TBufEC; const InitialText: WideString; AnsiText, PreserveComments: Boolean);
var Text, Name, IncludeFile, Comment: WideString;
    Child: TBlockParEC;
    PartCount: Integer;
    Entry: TBlockParElEC;
    ChildSorted: Boolean;
begin
  Text := TrimWideString(InitialText);
  while not Buf.IsAtEnd do
  begin
    if Text = '' then
      if AnsiText then Text := TrimWideString(WideString(Buf.ReadAnsiTextLine))
      else Text := TrimWideString(Buf.ReadWideTextLine);
    Comment := ExtractLineCommentW(Text);
    Text := TrimWideString(RemoveLineCommentW(Text));
    PartCount := CountDelimitedPartsW(Text, '{');
    if PartCount > 1 then
    begin
      Name := TrimWideString(ExtractDelimitedPartW(Text, 0, '{'));
      if Name = '' then raise Exception.Create('TBlockParEC.LoadFromBuf_r. tstr=' + Text);
      ChildSorted := Name[Length(Name)] = '^';
      if ChildSorted then
      begin
        SetLength(Name, Length(Name) - 1);
        Name := TrimWideString(Name);
      end
      else
      begin
        ChildSorted := Name[Length(Name)] <> '~';
        if not ChildSorted then
        begin
          SetLength(Name, Length(Name) - 1);
          Name := TrimWideString(Name);
        end;
      end;
      IncludeFile := '';
      if CountDelimitedPartsW(Name, '=') = 2 then
      begin
        IncludeFile := TrimWideString(ExtractDelimitedPartW(Name, 1, '='));
        Name := TrimWideString(ExtractDelimitedPartW(Name, 0, '='));
      end;
      Child := AddChildBlock(Name);
      Child.UseSortedIndex := ChildSorted;
      Name := TrimWideString(ExtractDelimitedRangeW(Text, 1, PartCount - 1, '{'));
      Child.ParseTextBuffer(Buf, Name, AnsiText, PreserveComments);
      if IncludeFile <> '' then Child.LoadFromTextFileWithEncodingProbe(PAnsiChar(AnsiString(IncludeFile)), False);
    end
    else
    begin
      if CountDelimitedPartsW(Text, '}') > 1 then Break;
      PartCount := CountDelimitedPartsW(Text, '=');
      if PartCount > 1 then
      begin
        Name := TrimWideString(ExtractDelimitedPartW(Text, 0, '='));
        IncludeFile := ExtractDelimitedRangeW(Text, 1, PartCount - 1, '=');
        if PreserveComments then AddParam(Name, IncludeFile).Comment := Comment
        else AddParam(Name, IncludeFile);
      end
      else if PreserveComments then
      begin
        Entry := AddEntry;
        Entry.ItemType := bpkText;
        Entry.Comment := Comment;
      end;
    end;
    Text := '';
  end;
end;
{ @end $466C58 }

{ @routine $467078 TBlockParEC_LoadFromTextBufferWithEncodingProbe }
procedure TBlockParEC.LoadFromTextBufferWithEncodingProbe(Buf: TBufEC; PreserveComments: Boolean);
begin
  if Buf.DataSize - Buf.Position <= 2 then Exit;
  if Buf.GetWord <> $FEFF then
  begin
    Buf.SetPosition(Buf.Position - 2);
    ParseTextBuffer(Buf, '', True, PreserveComments);
  end
  else ParseTextBuffer(Buf, '', False, PreserveComments);
end;
{ @end $467078 }

{ @routine $4670C8 TBlockParEC_LoadFromTextFileWithEncodingProbe }
procedure TBlockParEC.LoadFromTextFileWithEncodingProbe(FileName: PAnsiChar; PreserveComments: Boolean);
var Buf: TBufEC;
begin
  Buf := TBufEC.Create;
  try
    Buf.LoadFromFilePath(FileName);
    LoadFromTextBufferWithEncodingProbe(Buf, PreserveComments);
  finally
    Buf.Free;
  end;
end;
{ @end $4670C8 }

{ @routine $46712C TBlockParEC_WriteEncodedBuffer }
procedure TBlockParEC.WriteEncodedBuffer(Buf: TBufEC);
var Entry: TBlockParElEC; Index: Integer;
begin
  Buf.AddBoolean(UseSortedIndex);
  Buf.AddIntegerValue(StringParamCount + ChildBlockCount);
  if not UseSortedIndex then
  begin
    Entry := FirstEntry;
    while Entry <> nil do
    begin
      if Entry.ItemType = bpkString then
      begin
        Buf.AddAnsiChar(AnsiChar(Entry.ItemType));
        Buf.AddWideStringZ(Entry.Name);
        Buf.AddWideStringZ(Entry.StringValue);
      end
      else if Entry.ItemType = bpkBlock then
      begin
        Buf.AddAnsiChar(AnsiChar(Entry.ItemType));
        Buf.AddWideStringZ(Entry.Name);
        Entry.ChildBlock.WriteEncodedBuffer(Buf);
      end;
      Entry := Entry.Next;
    end;
  end
  else
    for Index := 0 to SortedEntryCount - 1 do
    begin
      Entry := SortedEntries[Index];
      Buf.AddIntegerValue(Entry.GroupIndex);
      Buf.AddIntegerValue(Entry.GroupCount);
      if Entry.ItemType = bpkString then
      begin
        Buf.AddAnsiChar(AnsiChar(Entry.ItemType));
        Buf.AddWideStringZ(Entry.Name);
        Buf.AddWideStringZ(Entry.StringValue);
      end
      else if Entry.ItemType = bpkBlock then
      begin
        Buf.AddAnsiChar(AnsiChar(Entry.ItemType));
        Buf.AddWideStringZ(Entry.Name);
        Entry.ChildBlock.WriteEncodedBuffer(Buf);
      end;
    end;
end;
{ @end $46712C }

{ @routine $467238 TBlockParEC_LoadFromDecodedBuffer }
procedure TBlockParEC.LoadFromDecodedBuffer(Buf: TBufEC);
var i, Count: Integer;
    Entry: TBlockParElEC;
begin
  Clear;
  UseSortedIndex := Buf.GetBoolean;
  Count := Buf.GetInt32;
  if UseSortedIndex then
  begin
    SortedEntryCount := Count;
    SetLength(SortedEntries, Count);
  end;
  for i := 0 to Count - 1 do
  begin
    Entry := AddEntry;
    if UseSortedIndex then
    begin
      Entry.GroupIndex := Buf.GetInt32;
      Entry.GroupCount := Buf.GetInt32;
    end;
    Entry.ItemType := TBlockParKind(Buf.GetByte);
    Entry.Name := Buf.ReadWideString;
    if Entry.ItemType = bpkString then
    begin
      Entry.StringValue := Buf.ReadWideString;
      Inc(StringParamCount);
      if UseSortedIndex then SortedEntries[i] := Entry;
    end
    else if Entry.ItemType = bpkBlock then
    begin
      Entry.MakeChildBlock;
      if UseSortedIndex then SortedEntries[i] := Entry;
      Inc(ChildBlockCount);
      Entry.ChildBlock.LoadFromDecodedBuffer(Buf);
    end;
  end;
end;
{ @end $467238 }

{ @routine $467380 TBlockParEC_SaveEncodedFile }
procedure TBlockParEC.SaveEncodedFile(const FileName: WideString);
var Buf: TBufEC; Dest: TFileEC;
begin
  Buf := TBufEC.Create;
  WriteEncodedBuffer(Buf);
  Buf.CompressZlibPayloadInPlace(False);
  Dest := TFileEC.Create;
  Dest.SetFileName(AnsiString(PAnsiChar(AnsiString(FileName))));
  Dest.CreateNew;
  Dest.WriteBuffer(Buf.Data, Buf.DataSize);
  Buf.Free;
  Dest.Free;
end;
{ @end $467380 }

{ @routine $46743C TBlockParEC_LoadEncodedFile }
procedure TBlockParEC.LoadEncodedFile(const FileName: WideString);
var Buf: TBufEC;
begin
  Buf := TBufEC.Create;
  Buf.LoadFromFilePath(PAnsiChar(AnsiString(FileName)));
  Buf.ExpandZlibPayloadInPlace;
  LoadFromDecodedBuffer(Buf);
  Buf.Free;
end;
{ @end $46743C }

end.

unit EC_Data;
// Unit bracket (inferred): CODE 0x004B95B4..0x004BA4A7; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, EC_Buf, EC_File, EC_Struct, SyncObjs;

type
  TDataEntryKind = (dekFile = 1, dekSubtree = 2); // @size $04
  TDataEC = class;

  TDataFileEC = class(TObjectEx) // @size $10
  public
    Prev: TDataFileEC; // @offset $04
    Next: TDataFileEC; // @offset $08
    FileRef: TFileEC; // @offset $0C

    constructor Create; // @addr $4B9720
    destructor Destroy; override; // @addr $4B9764
    procedure Clear; // @addr $4B9798 @note "Empty in this binary."
  end;
  PDataFileEC = ^TDataFileEC;

  TDataElEC = class(TObjectEx) // @size $24
  public
    Prev: TDataElEC; // @offset $04
    Next: TDataElEC; // @offset $08
    Name: WideString; // @offset $0C
    Kind: TDataEntryKind; // @offset $10
    ChildData: TDataEC; // @offset $14
    SharedFileRef: TDataFileEC; // @offset $18
    FileOffset: Cardinal; // @offset $1C
    ByteCount: Integer; // @offset $20

    constructor Create; // @addr $4B979C
    destructor Destroy; override; // @addr $4B97D4
    procedure ClearChildData; // @addr $4B9800
  end;
  PDataElEC = ^TDataElEC;

  TDataEC = class(TObjectEx) // @size $2C
  public
    FileLock: TCriticalSection; // @offset $04
    SharesInternedFileList: Boolean; // @offset $08
    InternedFileListHeadRef: PDataFileEC; // @offset $0C
    InternedFileListTailRef: PDataFileEC; // @offset $10
    OwnedInternedFileListHead: TDataFileEC; // @offset $14
    OwnedInternedFileListTail: TDataFileEC; // @offset $18
    FirstEntry: TDataElEC; // @offset $1C
    LastEntry: TDataElEC; // @offset $20
    // Delphi dynamic array sorted by case-sensitive, zero-terminated names.
    IndexedEntries: array of TDataElEC; // @offset $24
    IndexedEntryCount: Integer; // @offset $28

    constructor Create; // @addr $4B9818
    destructor Destroy; override; // @addr $4B9868
    procedure Clear; // @addr $4B989C @note "Frees owned files; linked-list head/tail fields remain unchanged."
    function AddEntry(EntryKind: TDataEntryKind): TDataElEC; // @addr $4B98F8 @note "Caller must update the index. Child subtrees share the interned-file list."
    function FindIndexedEntry(const Name: WideString): TDataElEC; // @addr $4B995C @note "Returns nil when absent."
    function FindInsertionIndex(Entry: TDataElEC): Integer; // @addr $4B99D0
    procedure InsertIntoIndex(Entry: TDataElEC); // @addr $4B9A4C
    function InternFileName(const FileName: WideString): TDataFileEC; // @addr $4B9AB4
    function FindEntry(const Name: WideString): TDataElEC; // @addr $4B9B70
    function FindEntryByPath(const Path: WideString): TDataElEC; // @addr $4B9BE8 @note "Accepts dot, slash and backslash separators; returns nil when absent or an intermediate entry is not a subtree."
    procedure AddFileEntry(const Name, FileName: WideString); // @addr $4B9DB0 @note "Adds an indexed file entry spanning the whole file."
    function FindNameByFileName(FileName: WideString): WideString; // @addr $4B9C80 @note "Compares trimmed ANSI lowercase basenames; returns the first matching entry name or empty."
    procedure ReadEntryBuffer(Entry: TDataElEC; Dest: TBufEC); // @addr $4B9DF8 @note "Requires a file entry. Negative ByteCount uses file size minus FileOffset; zero FileOffset skips seeking."
    procedure ReadBufferByPath(const Path: WideString; Dest: TBufEC); // @addr $4B9EB0 @note "Raises when Path is absent or is not a file entry."
    function HasFileEntry(const Path: WideString): Boolean; // @addr $4B9F80
    procedure AddMissingFromBlock(Block: TBlockParEC); // @addr $4B9F98 @note "Adds only absent names; existing subtrees are not merged recursively."
    procedure WriteToBlock(Block: TBlockParEC); // @addr $4BA0DC
    procedure WriteEncodedBuffer(Buf: TBufEC); // @addr $4BA178
    procedure SaveEncodedFile(const FileName: WideString); // @addr $4BA334
    procedure LoadEncodedFile(const FileName: WideString); // @addr $4BA3F0
    procedure LoadFromDecodedBuffer(Buf: TBufEC); // @addr $4BA230 @note "Replaces existing contents; trusts index order from the stream."
  end;

implementation

// @unit-initialization $4BA4A0
// @unit-finalization $4BA470

uses EC_Mem, EC_Str, SysUtils, Windows;

{ @routine $4B9720 TDataFileEC_Create }
constructor TDataFileEC.Create;
begin
  inherited Create;
  FileRef := TFileEC.Create;
end;
{ @end $4B9720 }

{ @routine $4B9764 TDataFileEC_Destroy }
destructor TDataFileEC.Destroy;
begin
  Clear;
  FileRef.Free;
  inherited Destroy;
end;
{ @end $4B9764 }

{ @routine $4B9798 TDataFileEC_Clear }
procedure TDataFileEC.Clear;
begin
end;
{ @end $4B9798 }

{ @routine $4B979C TDataElEC_Create }
constructor TDataElEC.Create;
begin
  inherited Create;
end;
{ @end $4B979C }

{ @routine $4B97D4 TDataElEC_Destroy }
destructor TDataElEC.Destroy;
begin
  ClearChildData;
  inherited Destroy;
end;
{ @end $4B97D4 }

{ @routine $4B9800 TDataElEC_ClearChildData }
procedure TDataElEC.ClearChildData;
begin
  if ChildData <> nil then
  begin
    ChildData.Free;
    ChildData := nil;
  end;
end;
{ @end $4B9800 }

{ @routine $4B9818 TDataEC_Create }
constructor TDataEC.Create;
begin
  inherited Create;
  FileLock := TCriticalSection.Create;
  InternedFileListHeadRef := @OwnedInternedFileListHead;
  InternedFileListTailRef := @OwnedInternedFileListTail;
end;
{ @end $4B9818 }

{ @routine $4B9868 TDataEC_Destroy }
destructor TDataEC.Destroy;
begin
  Clear;
  FileLock.Free;
  inherited Destroy;
end;
{ @end $4B9868 }

{ @routine $4B989C TDataEC_Clear }
procedure TDataEC.Clear;
var FileEntry, RemovedFile: TDataFileEC;
    Entry, RemovedEntry: TDataElEC;
begin
  if not SharesInternedFileList then
  begin
    FileEntry := InternedFileListHeadRef^;
    while FileEntry <> nil do
    begin
      RemovedFile := FileEntry;
      FileEntry := FileEntry.Next;
      RemovedFile.Free;
    end;
  end;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    RemovedEntry := Entry;
    Entry := Entry.Next;
    RemovedEntry.Free;
  end;
  SharesInternedFileList := False;
  InternedFileListHeadRef := @OwnedInternedFileListHead;
  InternedFileListTailRef := @OwnedInternedFileListTail;
  IndexedEntries := nil;
  IndexedEntryCount := 0;
end;
{ @end $4B989C }

{ @routine $4B98F8 TDataEC_AddEntry }
function TDataEC.AddEntry(EntryKind: TDataEntryKind): TDataElEC;
var Entry: TDataElEC;
begin
  Entry := TDataElEC.Create;
  if LastEntry <> nil then LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then FirstEntry := Entry;
  Entry.Kind := EntryKind;
  case EntryKind of
    dekFile: ;
  else
    begin
      Entry.ChildData := TDataEC.Create;
      Entry.ChildData.SharesInternedFileList := True;
      Entry.ChildData.InternedFileListHeadRef := InternedFileListHeadRef;
      Entry.ChildData.InternedFileListTailRef := InternedFileListTailRef;
    end;
  end;
  Result := Entry;
end;
{ @end $4B98F8 }

{ @routine $4B995C TDataEC_FindIndexedEntry }
function TDataEC.FindIndexedEntry(const Name: WideString): TDataElEC;
var Lo, Hi, Mid, Order: Integer;
    Entry: TDataElEC;
begin
  if IndexedEntryCount < 1 then
  begin Result := nil; Exit end;
  Lo := 0;
  Hi := IndexedEntryCount - 1;
  repeat
    Mid := (Hi - Lo) div 2 + Lo;
    Entry := IndexedEntries[Mid];
    Order := CompareWideChars(PWideChar(Name), PWideChar(Entry.Name));
    if Order = 0 then
    begin Result := Entry; Exit end;
    if Order < 0 then Hi := Mid - 1 else Lo := Mid + 1;
  until Hi < Lo;
  Result := nil;
end;
{ @end $4B995C }

{ @routine $4B99D0 TDataEC_FindInsertionIndex }
function TDataEC.FindInsertionIndex(Entry: TDataElEC): Integer;
var Lo, Hi, Mid, Order: Integer;
    Existing: TDataElEC;
begin
  if IndexedEntryCount <= 0 then
  begin Result := 0; Exit end;
  Lo := 0;
  Hi := IndexedEntryCount - 1;
  repeat
    Mid := ((Hi - Lo) shr 1) + Lo;
    Existing := IndexedEntries[Mid];
    Order := CompareWideChars(PWideChar(Entry.Name), PWideChar(Existing.Name));
    if Order = 0 then
    begin Result := Mid; Exit end;
    if Order < 0 then Hi := Mid - 1 else Lo := Mid + 1;
  until Hi < Lo;
  if Order < 0 then Result := Mid else Result := Mid + 1;
end;
{ @end $4B99D0 }

{ @routine $4B9A4C TDataEC_InsertIntoIndex }
procedure TDataEC.InsertIntoIndex(Entry: TDataElEC);
var Index: Integer;
begin
  SetLength(IndexedEntries, IndexedEntryCount + 1);
  Index := FindInsertionIndex(Entry);
  if Index >= IndexedEntryCount then
  begin
    IndexedEntries[IndexedEntryCount] := Entry;
    Inc(IndexedEntryCount);
  end
  else
  begin
    Windows.MoveMemory(@IndexedEntries[Index + 1], @IndexedEntries[Index], (IndexedEntryCount - Index) * SizeOf(IndexedEntries[0]));
    IndexedEntries[Index] := Entry;
    Inc(IndexedEntryCount);
  end;
end;
{ @end $4B9A4C }

{ @routine $4B9AB4 TDataEC_InternFileName }
function TDataEC.InternFileName(const FileName: WideString): TDataFileEC;
var Entry: TDataFileEC;
begin
  Entry := InternedFileListHeadRef^;
  while Entry <> nil do
  begin
    if Entry.FileRef.GetFileName = FileName then
    begin Result := Entry; Exit end;
    Entry := Entry.Next;
  end;
  Entry := TDataFileEC.Create;
  if InternedFileListTailRef^ <> nil then InternedFileListTailRef^.Next := Entry;
  Entry.Prev := InternedFileListTailRef^;
  Entry.Next := nil;
  InternedFileListTailRef^ := Entry;
  if InternedFileListHeadRef^ = nil then InternedFileListHeadRef^ := Entry;
  Entry.FileRef.SetFileName(AnsiString(FileName));
  Result := Entry;
end;
{ @end $4B9AB4 }

{ @routine $4B9B70 TDataEC_FindEntry }
function TDataEC.FindEntry(const Name: WideString): TDataElEC;
begin
  Result := FindIndexedEntry(Name);
end;
{ @end $4B9B70 }

{ @routine $4B9BE8 TDataEC_FindEntryByPath }
function TDataEC.FindEntryByPath(const Path: WideString): TDataElEC;
var Position, PathLength, PartStart, PartLength: Integer;
    Entry: TDataElEC;
    Data: TDataEC;
  // @nested $4B9B78 NextDataPathComponent
  function NextDataPathComponent: Boolean; // @addr $4B9B78 @note "Nested helper of TDataEC.FindEntryByPath; requires its parent stack frame."
  var Ch: WideChar;
      i: Integer;
  begin
    if Position >= PathLength then
    begin Result := False; Exit end;
    PartStart := Position;
    i := PartStart;
    while PathLength > i do
    begin
      Ch := Path[i + 1];
      if (Ch = '.') or (Ch = '/') or (Ch = '\') then Break;
      Inc(i);
    end;
    PartLength := i - PartStart;
    Position := i + 1;
    Result := True;
  end;
begin
  PathLength := Length(Path);
  Position := 0;
  Data := Self;
  while NextDataPathComponent do
  begin
    Entry := Data.FindEntry(Copy(Path, PartStart + 1, PartLength));
    if Entry = nil then Break;
    if Position >= PathLength then
    begin Result := Entry; Exit end;
    if Entry.Kind <> dekSubtree then Break;
    Data := Entry.ChildData;
  end;
  Result := nil;
end;
{ @end $4B9BE8 }

{ @routine $4B9C80 TDataEC_FindNameByFileName }
function TDataEC.FindNameByFileName(FileName: WideString): WideString;
var Entry: TDataElEC; FileRef: TDataFileEC;
begin
  FileName := Trim(LowerCase(AnsiString(FileName)));
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    FileRef := Entry.SharedFileRef;
    if FileRef <> nil then
      if WideString(Trim(LowerCase(AnsiString(ExtractFileNameW(FileRef.FileRef.FileName))))) = FileName then
      begin
        Result := Entry.Name;
        Exit;
      end;
    Entry := Entry.Next;
  end;
  Result := '';
end;
{ @end $4B9C80 }

{ @routine $4B9DB0 TDataEC_AddFileEntry }
procedure TDataEC.AddFileEntry(const Name, FileName: WideString);
var Entry: TDataElEC;
begin
  Entry := AddEntry(dekFile);
  Entry.Name := Name;
  Entry.SharedFileRef := InternFileName(FileName);
  Entry.FileOffset := 0;
  Entry.ByteCount := -1;
  InsertIntoIndex(Entry);
end;
{ @end $4B9DB0 }

{ @routine $4B9DF8 TDataEC_ReadEntryBuffer }
procedure TDataEC.ReadEntryBuffer(Entry: TDataElEC; Dest: TBufEC);
var Size: Integer;
begin
  FileLock.Enter;
  Entry.SharedFileRef.FileRef.AcquireReadWriteHandle;
  try
    if Entry.FileOffset <> 0 then Entry.SharedFileRef.FileRef.SetPointer(Entry.FileOffset, FILE_BEGIN);
    Size := Entry.ByteCount;
    if Size < 0 then Size := Entry.SharedFileRef.FileRef.GetSize - Entry.FileOffset;
    Dest.LoadFromFileChunk(Entry.SharedFileRef.FileRef, Size);
  finally
    Entry.SharedFileRef.FileRef.ReleaseHandle;
    FileLock.Leave;
  end;
end;
{ @end $4B9DF8 }

{ @routine $4B9EB0 TDataEC_ReadBufferByPath }
procedure TDataEC.ReadBufferByPath(const Path: WideString; Dest: TBufEC);
var Entry: TDataElEC;
begin
  Entry := FindEntryByPath(Path);
  if (Entry = nil) or (Entry.Kind <> dekFile) then
    raise Exception.Create('TDataEC.PathGetBuf. path=' + Path);
  ReadEntryBuffer(Entry, Dest);
end;
{ @end $4B9EB0 }

{ @routine $4B9F80 TDataEC_HasFileEntry }
function TDataEC.HasFileEntry(const Path: WideString): Boolean;
var Entry: TDataElEC;
begin
  Entry := FindEntryByPath(Path);
  Result := (Entry <> nil) and (Entry.Kind = dekFile);
end;
{ @end $4B9F80 }

{ @routine $4B9F98 TDataEC_AddMissingFromBlock }
procedure TDataEC.AddMissingFromBlock(Block: TBlockParEC);
var
  Count, i: Integer;
  Kind: TBlockParKind;
  Entry: TDataElEC;
begin
  Count := Block.GetEntryCount;
  for i := 0 to Count - 1 do
  begin
    Kind := Block.GetEntryKindByIndex(i);
    if ((Kind = bpkString) or (Kind = bpkBlock)) and
      (FindEntry(Block.GetEntryNameByIndex(i)) <> nil) then Continue;
    if Kind = bpkString then
    begin
      Entry := AddEntry(dekFile);
      Entry.Name := Block.GetEntryNameByIndex(i);
      Entry.SharedFileRef := InternFileName(Block.GetEntryStringByIndex(i));
      Entry.FileOffset := 0;
      Entry.ByteCount := -1;
      InsertIntoIndex(Entry);
    end
    else if Kind = bpkBlock then
    begin
      Entry := AddEntry(dekSubtree);
      Entry.Name := Block.GetEntryNameByIndex(i);
      InsertIntoIndex(Entry);
      Entry.ChildData.AddMissingFromBlock(Block.GetEntryBlockByIndex(i));
    end;
  end;
end;
{ @end $4B9F98 }

{ @routine $4BA0DC TDataEC_WriteToBlock }
procedure TDataEC.WriteToBlock(Block: TBlockParEC);
var i: Integer;
    Entry: TDataElEC;
begin
  for i := 0 to IndexedEntryCount - 1 do
  begin
    Entry := IndexedEntries[i];
    if Entry.Kind = dekFile then
      Block.AddParam(Entry.Name, Entry.SharedFileRef.FileRef.GetFileName)
    else Entry.ChildData.WriteToBlock(Block.AddChildBlock(Entry.Name));
  end;
end;
{ @end $4BA0DC }

{ @routine $4BA178 TDataEC_WriteEncodedBuffer }
procedure TDataEC.WriteEncodedBuffer(Buf: TBufEC);
var Entry: TDataElEC; Index: Integer;
begin
  Buf.AddIntegerValue(IndexedEntryCount);
  for Index := 0 to IndexedEntryCount - 1 do
  begin
    Entry := IndexedEntries[Index];
    Buf.AddAnsiChar(AnsiChar(Entry.Kind));
    Buf.AddWideStringZ(Entry.Name);
    if Entry.Kind = dekFile then
      Buf.AddWideStringZ(Entry.SharedFileRef.FileRef.GetFileName)
    else
      Entry.ChildData.WriteEncodedBuffer(Buf);
  end;
end;
{ @end $4BA178 }

{ @routine $4BA230 TDataEC_LoadFromDecodedBuffer }
procedure TDataEC.LoadFromDecodedBuffer(Buf: TBufEC);
var Entry: TDataElEC;
    i: Integer;
    Kind: TDataEntryKind;
begin
  Clear;
  IndexedEntryCount := Buf.GetInt32;
  SetLength(IndexedEntries, IndexedEntryCount);
  for i := 0 to IndexedEntryCount - 1 do
  begin
    Kind := TDataEntryKind(Buf.GetByte);
    Entry := AddEntry(Kind);
    Entry.Name := Buf.ReadWideString;
    Entry.FileOffset := 0;
    Entry.ByteCount := -1;
    if Kind = dekFile then Entry.SharedFileRef := InternFileName(Buf.ReadWideString)
    else Entry.ChildData.LoadFromDecodedBuffer(Buf);
    IndexedEntries[i] := Entry;
  end;
end;
{ @end $4BA230 }

{ @routine $4BA334 TDataEC_SaveEncodedFile }
procedure TDataEC.SaveEncodedFile(const FileName: WideString);
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
{ @end $4BA334 }
{ @routine $4BA3F0 TDataEC_LoadEncodedFile }
procedure TDataEC.LoadEncodedFile(const FileName: WideString);
var Buf: TBufEC;
begin
  Buf := TBufEC.Create;
  Buf.LoadFromFilePath(PAnsiChar(AnsiString(FileName)));
  Buf.ExpandZlibPayloadInPlace;
  LoadFromDecodedBuffer(Buf);
  Buf.Free;
end;
{ @end $4BA3F0 }

end.

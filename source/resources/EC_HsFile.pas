unit EC_HsFile;
// Unit bracket (inferred): CODE 0x004ADB68..0x004B03CF; inclusive evidence, not full bounds.

interface

uses SyncObjs;

type
  THsFolderEC = class;
  PHsFolderEC = ^THsFolderEC;

  TPackEntryEC = packed record // @size $9E
    StoredSize: Cardinal; // @offset $00
    DataSize: Cardinal; // @offset $04
    UpperName: array[0..62] of AnsiChar; // @offset $08
    OriginalName: array[0..62] of AnsiChar; // @offset $47
    // Kind 2 is compressed data; kind 3 is a child folder.
    Kind: Integer; // @offset $86
    KindCopy: Integer; // @offset $8A
    Flags: Cardinal; // @offset $8E
    // The four bytes at +0x92 remain unresolved.
    TargetOffset: Cardinal; // @offset $96
    ChildFolder: THsFolderEC; // @offset $9A
  end;
  PPackEntryEC = ^TPackEntryEC;

  THsFolderEC = class(TObject) // @size $24
  public
    UpperName: AnsiString; // @offset $04
    OriginalName: AnsiString; // @offset $08
    HeaderSize: Cardinal; // @offset $0C
    EntryCount: Cardinal; // @offset $10
    EntryRecordSize: Cardinal; // @offset $14
    Parent: THsFolderEC; // @offset $18
    EntryBuffer: PPackEntryEC; // @offset $1C
    ChangedFlag: Boolean; // @offset $20
    InitializedEmptyFlag: Boolean; // @offset $21

    constructor Create(FolderName: AnsiString); // @addr $4AF33C
    constructor CreateChild(FolderName: AnsiString; Parent: THsFolderEC); // @addr $4AF3F8
    destructor Destroy; override; // @addr $4AF4B8
    function GetEntry(Index: Cardinal): PPackEntryEC; // @addr $4AF4D8 @note "Returns nil for an out-of-range index."
    function FindEntry(EntryName: AnsiString): PPackEntryEC; // @addr $4AF4F4 @note "Uppercases EntryName and skips entries with nonzero Flags."
    procedure InitializeEmpty; // @addr $4AF5AC @note "Requires an unloaded folder."
    function Load(FileHandle, SubtreeOffset: Cardinal): Boolean; // @addr $4AF5D4 @note "Returns false when already loaded; flagged child folders are skipped."
    procedure Unload; // @addr $4AF794 @note "Marks this folder and its parent changed."
    function EntryExists(EntryPath: AnsiString): Boolean; // @addr $4AF810 @note "Accepts slash/backslash paths; a directory alone is not a file."
    function ResolveEntryByPath(EntryPath: AnsiString): PPackEntryEC; // @addr $4AF8C8 @note "Accepts slash and backslash separators; returns nil when absent."
    procedure UpdateParentEntry; // @addr $4AF984 @note "Invalidates the parent's stored target offset."
  end;

  THashSlotEC = packed record // @size $34
    FullHash: Cardinal; // @offset $00
    MappedValue: Integer; // @offset $04
    HitCount: Cardinal; // @offset $08
    Unknown0C: Integer; // @offset $0C
    KeySuffix: array[0..31] of AnsiChar; // @offset $10
    // +0x0C is set to one on insertion; +0x30 remains unresolved.
  end;
  THashSlotArray = array[0..1023] of THashSlotEC;

  TPackOpenSlotEC = packed record // @size $1E
    FileHandle: Cardinal; // @offset $00
    IsAvailable: Boolean; // @offset $04
    DataStartOffset: Cardinal; // @offset $05
    CurrentDataOffset: Cardinal; // @offset $09
    DataSize: Cardinal; // @offset $0D
    CompressedBlockBuffer: Pointer; // @offset $11
    DecompressedBlockBuffer: Pointer; // @offset $15
    UsesChainedBlocks: Boolean; // @offset $19
    CurrentBlockIndex: Integer; // @offset $1A
  end;
  TPackOpenSlotArray = array[0..15] of TPackOpenSlotEC;

  // Package backend and folder directory.
  TPackFileEC = class(TObject) // @size $210
  public
    NextPack: TPackFileEC; // @offset $04
    PrevPack: TPackFileEC; // @offset $08
    UseLooseFiles: Boolean; // @offset $0C
    PackageHandle: Cardinal; // @offset $10
    PackagePath: AnsiString; // @offset $14
    RootFolder: THsFolderEC; // @offset $18
    OpenSlots: TPackOpenSlotArray; // @offset $1C
    RootSubtreeOffset: Cardinal; // @offset $1FC
    CollectionIndex: Integer; // @offset $20C

    constructor Create; // @addr $4ADE80
    destructor Destroy; override; // @addr $4ADEF4
    procedure SetPackagePath(NewPackagePath: AnsiString); // @addr $4ADF1C
    procedure CloseAllOpenEntrySlots; // @addr $4ADF68
    function Open: Boolean; // @addr $4ADF98
    function OpenReadWrite: Boolean; // @addr $4AE268
    function OpenReadWritePath(NewPackagePath: AnsiString): Boolean; // @addr $4AE210
    function FileExists(FileName: AnsiString): Boolean; // @addr $4AF2D4 @note "Checks the package first, then the loose file path."
    function Close: Boolean; // @addr $4AE1B8
    function CloseForDestroy: Boolean; // @addr $4AE490
    function FindFreeOpenSlotIndex: Integer; // @addr $4AE4E8
    function OpenEntryByPath(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer; // @addr $4AE508
    function CreateLooseFile(FilePath: AnsiString): Integer; // @addr $4AE820
    function CloseEntrySlot(SlotIndex: Cardinal): Boolean; // @addr $4AE8EC
    function GetChainedBlockStoredSizeAtIndex(FirstBlockOffset, BlockIndex: Cardinal): Cardinal; // @addr $4AEAB0
    function ReadEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean; // @addr $4AEAFC
    function WriteEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean; // @addr $4AED88
    function SeekEntrySlot(SlotIndex, Offset: Cardinal; Origin: Integer): Boolean; // @addr $4AEF40
    function GetEntrySlotPosition(SlotIndex: Cardinal): Cardinal; // @addr $4AF100
    function GetEntrySlotSize(SlotIndex: Cardinal): Cardinal; // @addr $4AF1EC
  end;
  TPackFileArray = array[0..127] of TPackFileEC;

  THashEC = class(TObject) // @size $D01C
  public
    OperationCount: Cardinal; // @offset $04
    HitCount: Cardinal; // @offset $08
    // Incremented on every hit alongside HitCount; no distinct use recovered.
    HitCountCopy: Cardinal; // @offset $0C
    StaleValueCount: Cardinal; // @offset $10
    MissCount: Cardinal; // @offset $14
    ReservedText: AnsiString; // @offset $18 Native THashEC cleanup owns this otherwise unused field.
    Slots: THashSlotArray; // @offset $1C

    constructor Create; // @addr $4B00FC
    destructor Destroy; override; // @addr $4B0134
    function InitializeEmptyTable(BucketCount: Integer): Boolean; // @addr $4B031C @note "Ignores BucketCount; the table has 1024 buckets. Always returns true."
    function ReleaseTable: Boolean; // @addr $4B0350 @note "Returns true without changing the table."
    function ComputeLookupBucketAndFullHash(var Key: AnsiString; out FullHash: Cardinal): Integer; // @addr $4B0154 @note "Key is not modified; only its trailing 32 bytes contribute to the hash."
    function FindOrInsertKeySlot(Key: AnsiString): Integer; // @addr $4B0198 @note "Returns -1 on failure. Native probing can reach slot 1024; promoted hits return the pre-swap index."
    procedure SetSlotMappedValue(SlotIndex, Value: Integer); // @addr $4B0314
    function GetSlotMappedValue(SlotIndex: Integer): Integer; // @addr $4B0354
    procedure MaybeResetStatistics; // @addr $4B035C
    procedure NoteStaleMappedValue; // @addr $4B0394
  end;

  TPackCollectionEC = class(TObject) // @size $214
  public
    FirstPack: TPackFileEC; // @offset $04
    LastPack: TPackFileEC; // @offset $08
    NameToPackIndexHash: THashEC; // @offset $0C
    UseFastNameIndex: Boolean; // @offset $10
    PackByIndex: TPackFileArray; // @offset $14

    constructor Create; // @addr $4AFAA0
    destructor Destroy; override; // @addr $4AFAE8 @note "Unlinks packs without freeing them."
    procedure Clear(FreePacks: Boolean); // @addr $4AFB0C @note "Frees the name hash even when FreePacks is false."
    // List mutations rebuild PackByIndex and CollectionIndex without clearing the name hash.
    // The fixed array's 128-package capacity is not checked.
    procedure AddPackToFront(Pack: TPackFileEC); // @addr $4AFB4C
    procedure AddPackToBack(Pack: TPackFileEC); // @addr $4AFBC4
    procedure RemovePack(Pack: TPackFileEC; FreePack: Boolean); // @addr $4AFC3C @note "When retained, Pack keeps its old links and CollectionIndex."
    function OpenAllPackages: Boolean; // @addr $4AFCAC @note "A false result rolls back previously opened packages."
    function CloseAllPackages: Boolean; // @addr $4AFD24 @note "Returns true regardless of individual close results."
    function GetPackByIndex(PackIndex: Integer): TPackFileEC; // @addr $4AFD54 @note "Returns nil when out of range."
    function OpenEntryByPathAcrossPackages(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer; // @addr $4AFD68 @note "Returns package index * 16 + slot, or -1."
    function CreateLooseFile(FilePath: AnsiString): Integer; // @addr $4AFEBC @note "Uses the first package; truncates existing files. Returns a handle or -1."
    function CloseEntryHandle(Handle: Integer): Boolean; // @addr $4AFF1C
    function ReadEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean; // @addr $4AFF4C
    function WriteEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean; // @addr $4AFF90
    function SeekEntryHandle(Handle: Integer; Offset: Cardinal; Origin: Integer): Boolean; // @addr $4AFFD4
    function GetEntryHandlePosition(Handle: Integer): Cardinal; // @addr $4B0018 @note "Returns 0xFFFFFFFF for an invalid handle."
    function GetEntryHandleSize(Handle: Integer): Cardinal; // @addr $4B0048 @note "Returns 0xFFFFFFFF for an invalid handle."
  end;

var
  PackageCollection: TPackCollectionEC; // @addr $61C00C
  PackageFileLock: TCriticalSection; // @addr $61C010

function MatchLookupKeySuffix(var Key: AnsiString; SuffixBytes: Pointer; SuffixLength: Integer): Boolean; // @addr $4B0078 @note "Ignores SuffixLength; compares up to 32 trailing key bytes without checking stored length. Key is not modified."
procedure CopyLookupKeySuffix(DestSuffixBytes: Pointer; SuffixLength: Integer; var Key: AnsiString); // @addr $4B00C4 @note "Ignores SuffixLength; copies up to 32 trailing key bytes without terminator or padding. Key is not modified."

function AnsiBeforeFirstDelimiter(Text, Delimiters: AnsiString): AnsiString; // @addr $4ADD14 @note "Returns Text when no delimiter occurs."
function AnsiAfterFirstDelimiter(Text, Delimiters: AnsiString): AnsiString; // @addr $4ADDC8 @note "Returns an empty string when no delimiter occurs."
function OffsetPackPointer(Data: Pointer; ByteOffset: Cardinal): Pointer; // @addr $4ADD10

implementation

// @unit-initialization $4B03C8
// @unit-finalization $4B0398

uses GR_Main, EC_OKGF, SysUtils, Windows;

const
  PackOpenSlotShift = 4;
  PackOpenSlotCount = 16;
  PackCompressionBlockShift = 16;
  PackCompressionBlockSize = 1 shl PackCompressionBlockShift;
  PackCompressedBufferSize = 72112;
  PackSlotRangeError = 'Номер файла не может быть более ';

{ @routine $4ADD10 OffsetPackPointer }
function OffsetPackPointer(Data: Pointer; ByteOffset: Cardinal): Pointer;
begin
  Result := Pointer(Integer(Data) + Integer(ByteOffset));
end;
{ @end $4ADD10 }

{ @routine $4ADD14 AnsiBeforeFirstDelimiter }
function AnsiBeforeFirstDelimiter(Text, Delimiters: AnsiString): AnsiString;
var i, j: Integer;
begin
  i := 1;
  while i <= Length(Text) do
  begin
    for j := 1 to Length(Delimiters) do
      if Delimiters[j] = Text[i] then
      begin
        Result := Copy(Text, 1, i - 1);
        Exit;
      end;
    Inc(i);
  end;
  Result := Text;
end;
{ @end $4ADD14 }

{ @routine $4ADDC8 AnsiAfterFirstDelimiter }
function AnsiAfterFirstDelimiter(Text, Delimiters: AnsiString): AnsiString;
var i, j: Integer;
begin
  i := 1;
  while i <= Length(Text) do
  begin
    for j := 1 to Length(Delimiters) do
      if Delimiters[j] = Text[i] then
      begin
        Result := Copy(Text, i + 1, Length(Text) - i);
        Exit;
      end;
    Inc(i);
  end;
  Result := '';
end;
{ @end $4ADDC8 }

{ @routine $4ADE80 TPackFileEC_Create }
constructor TPackFileEC.Create;
var i: Integer;
begin
  PackageHandle := INVALID_HANDLE_VALUE;
  UseLooseFiles := False;
  PackagePath := '';
  RootFolder := nil;
  RootSubtreeOffset := 0;
  NextPack := nil;
  PrevPack := nil;
  CollectionIndex := -1;
  for i := Low(OpenSlots) to High(OpenSlots) do OpenSlots[i].IsAvailable := True;
end;
{ @end $4ADE80 }

{ @routine $4ADEF4 TPackFileEC_Destroy }
destructor TPackFileEC.Destroy;
begin
  CloseAllOpenEntrySlots;
  CloseForDestroy;
end;
{ @end $4ADEF4 }

{ @routine $4ADF1C TPackFileEC_SetPackagePath }
procedure TPackFileEC.SetPackagePath(NewPackagePath: AnsiString);
begin
  PackagePath := NewPackagePath;
end;
{ @end $4ADF1C }

{ @routine $4ADF68 TPackFileEC_CloseAllOpenEntrySlots }
procedure TPackFileEC.CloseAllOpenEntrySlots;
var i: Integer;
begin
  for i := Low(OpenSlots) to High(OpenSlots) do
    if not OpenSlots[i].IsAvailable then
    begin
      CloseEntrySlot(i);
      OpenSlots[i].IsAvailable := True;
    end;
end;
{ @end $4ADF68 }

{ @routine $4ADF98 TPackFileEC_Open }
function TPackFileEC.Open: Boolean;
var BytesRead: Cardinal;
begin
  if (PackageHandle <> INVALID_HANDLE_VALUE) or (RootFolder <> nil) then Close;
  if UseLooseFiles then
  begin
    RootSubtreeOffset := 0;
    RootFolder := THsFolderEC.Create('');
    RootFolder.InitializeEmpty;
    Result := True;
    Exit;
  end;

  PackageHandle := Windows.CreateFile(PAnsiChar(PackagePath), GENERIC_READ,
    FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if PackageHandle = INVALID_HANDLE_VALUE then
  begin
    raise Exception.Create('Error openning package file [READ]:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  if not Windows.ReadFile(PackageHandle, RootSubtreeOffset, SizeOf(RootSubtreeOffset), BytesRead, nil) then
  begin
    Windows.CloseHandle(PackageHandle);
    raise Exception.Create('Error reading package file:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  RootFolder := THsFolderEC.Create('');
  if not RootFolder.Load(PackageHandle, RootSubtreeOffset) then
  begin
    RootFolder.Free;
    RootFolder := nil;
    Close;
    raise Exception.Create('Error reading file system of the package file:' + PackagePath);
    Exit;
  end;

  Result := True;
end;
{ @end $4ADF98 }

{ @routine $4AE1B8 TPackFileEC_Close }
function TPackFileEC.Close: Boolean;
var Success: Boolean;
begin
  Result := False;
  if (PackageHandle = INVALID_HANDLE_VALUE) and (RootFolder = nil) then Exit;
  CloseAllOpenEntrySlots;
  if RootFolder <> nil then
  begin
    RootFolder.Free;
    RootFolder := nil;
  end;
  if PackageHandle <> INVALID_HANDLE_VALUE then Success := Windows.CloseHandle(PackageHandle)
  else Success := True;
  PackageHandle := INVALID_HANDLE_VALUE;
  if Success then Result := True;
end;
{ @end $4AE1B8 }

{ @routine $4AE210 TPackFileEC_OpenReadWritePath }
function TPackFileEC.OpenReadWritePath(NewPackagePath: AnsiString): Boolean;
begin
  SetPackagePath(NewPackagePath);
  Result := OpenReadWrite;
end;
{ @end $4AE210 }

{ @routine $4AE268 TPackFileEC_OpenReadWrite }
function TPackFileEC.OpenReadWrite: Boolean;
var BytesRead: Cardinal;
begin
  if (PackageHandle <> INVALID_HANDLE_VALUE) or (RootFolder <> nil) then CloseForDestroy;
  if UseLooseFiles then
  begin
    RootSubtreeOffset := 0;
    RootFolder := THsFolderEC.Create('');
    RootFolder.InitializeEmpty;
    Result := True;
    Exit;
  end;

  PackageHandle := Windows.CreateFile(PAnsiChar(PackagePath), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if PackageHandle = INVALID_HANDLE_VALUE then
  begin
    raise Exception.Create('Error openning package file [READ|WRITE]:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  if not Windows.ReadFile(PackageHandle, RootSubtreeOffset, SizeOf(RootSubtreeOffset), BytesRead, nil) then
  begin
    Windows.CloseHandle(PackageHandle);
    raise Exception.Create('Error reading package file:' + PackagePath);
    PackageHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  RootFolder := THsFolderEC.Create('');
  if not RootFolder.Load(PackageHandle, RootSubtreeOffset) then
  begin
    RootFolder.Free;
    RootFolder := nil;
    CloseForDestroy;
    raise Exception.Create('Error reading file system of the package file:' + PackagePath);
    Exit;
  end;

  Result := True;
end;
{ @end $4AE268 }

{ @routine $4AE490 TPackFileEC_CloseForDestroy }
function TPackFileEC.CloseForDestroy: Boolean;
var Success: Boolean;
begin
  Result := False;
  if (PackageHandle = INVALID_HANDLE_VALUE) and (RootFolder = nil) then Exit;
  CloseAllOpenEntrySlots;
  if RootFolder <> nil then
  begin
    RootFolder.Free;
    RootFolder := nil;
  end;
  if PackageHandle <> INVALID_HANDLE_VALUE then Success := Windows.CloseHandle(PackageHandle)
  else Success := True;
  PackageHandle := INVALID_HANDLE_VALUE;
  if Success then Result := True;
end;
{ @end $4AE490 }

{ @routine $4AE4E8 TPackFileEC_FindFreeOpenSlotIndex }
function TPackFileEC.FindFreeOpenSlotIndex: Integer;
var i: Integer;
begin
  for i := Low(OpenSlots) to High(OpenSlots) do
    if OpenSlots[i].IsAvailable then begin Result := i; Exit end;
  Result := -1;
end;
{ @end $4AE4E8 }

{ @routine $4AE508 TPackFileEC_OpenEntryByPath }
function TPackFileEC.OpenEntryByPath(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer;
var Slot: Integer; Entry: PPackEntryEC; Position: Cardinal;
begin
  Result := -1;
  Slot := FindFreeOpenSlotIndex;
  if Slot = -1 then Exit;
  if RootFolder = nil then raise Exception.Create('Package not opened :' + EntryPath);
  Entry := RootFolder.ResolveEntryByPath(EntryPath);
  if Entry = nil then
  begin
    if not SysUtils.FileExists(EntryPath) then Exit;
    OpenSlots[Slot].FileHandle := Windows.CreateFile(PAnsiChar(EntryPath), DesiredAccess,
      FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if OpenSlots[Slot].FileHandle = INVALID_HANDLE_VALUE then Exit;
    OpenSlots[Slot].DataStartOffset := 0;
    OpenSlots[Slot].CurrentDataOffset := 0;
    OpenSlots[Slot].DataSize := Windows.SetFilePointer(OpenSlots[Slot].FileHandle, 0, nil, FILE_END);
    OpenSlots[Slot].CompressedBlockBuffer := nil;
    OpenSlots[Slot].DecompressedBlockBuffer := nil;
    OpenSlots[Slot].UsesChainedBlocks := False;
    OpenSlots[Slot].CurrentBlockIndex := -1;
    if OpenSlots[Slot].DataSize = $FFFFFFFF then raise Exception.Create('Сбой в файловой системе :' + EntryPath);
    Position := Windows.SetFilePointer(OpenSlots[Slot].FileHandle, 0, nil, FILE_BEGIN);
    if Position = $FFFFFFFF then raise Exception.Create('Сбой в файловой системе:' + EntryPath);
    OpenSlots[Slot].IsAvailable := False;
    Result := Slot;
    Exit;
  end;
  if PackageHandle = INVALID_HANDLE_VALUE then Exit;
  OpenSlots[Slot].FileHandle := PackageHandle;
  OpenSlots[Slot].DataStartOffset := Entry.TargetOffset + 4;
  OpenSlots[Slot].CurrentDataOffset := Entry.TargetOffset + 4;
  OpenSlots[Slot].DataSize := Entry.DataSize;
  OpenSlots[Slot].IsAvailable := False;
  OpenSlots[Slot].UsesChainedBlocks := Entry.Kind = 2;
  OpenSlots[Slot].CurrentBlockIndex := -1;
  if OpenSlots[Slot].UsesChainedBlocks then
  begin
    OpenSlots[Slot].CompressedBlockBuffer := AllocMem(PackCompressedBufferSize);
    OpenSlots[Slot].DecompressedBlockBuffer := AllocMem(PackCompressionBlockSize);
  end
  else
  begin
    OpenSlots[Slot].CompressedBlockBuffer := nil;
    OpenSlots[Slot].DecompressedBlockBuffer := nil;
  end;
  Position := Windows.SetFilePointer(OpenSlots[Slot].FileHandle, OpenSlots[Slot].CurrentDataOffset, nil, FILE_BEGIN);
  if Position = $FFFFFFFF then raise Exception.Create('Сбой в пакетном файле :' + PackagePath + ':' + EntryPath);
  Result := Slot;
end;
{ @end $4AE508 }

{ @routine $4AE820 TPackFileEC_CreateLooseFile }
function TPackFileEC.CreateLooseFile(FilePath: AnsiString): Integer;
var Slot: Integer;
begin
  Result := -1;
  Slot := FindFreeOpenSlotIndex;
  if Slot = -1 then Exit;
  OpenSlots[Slot].FileHandle := Windows.CreateFile(PAnsiChar(FilePath), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if OpenSlots[Slot].FileHandle = INVALID_HANDLE_VALUE then Exit;
  OpenSlots[Slot].DataStartOffset := 0;
  OpenSlots[Slot].CurrentDataOffset := 0;
  OpenSlots[Slot].DataSize := 0;
  OpenSlots[Slot].CompressedBlockBuffer := nil;
  OpenSlots[Slot].DecompressedBlockBuffer := nil;
  OpenSlots[Slot].UsesChainedBlocks := False;
  OpenSlots[Slot].CurrentBlockIndex := -1;
  OpenSlots[Slot].IsAvailable := False;
  Result := Slot;
end;
{ @end $4AE820 }

{ @routine $4AE8EC TPackFileEC_CloseEntrySlot }
function TPackFileEC.CloseEntrySlot(SlotIndex: Cardinal): Boolean;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  Result := True;
  if OpenSlots[SlotIndex].FileHandle = PackageHandle then
  begin
    if OpenSlots[SlotIndex].UsesChainedBlocks then
    begin
      FreeMem(OpenSlots[SlotIndex].CompressedBlockBuffer);
      OpenSlots[SlotIndex].CompressedBlockBuffer := nil;
      FreeMem(OpenSlots[SlotIndex].DecompressedBlockBuffer);
      OpenSlots[SlotIndex].DecompressedBlockBuffer := nil;
    end;
    OpenSlots[SlotIndex].IsAvailable := True;
  end
  else
  begin
    if not Boolean(Windows.CloseHandle(THandle(OpenSlots[SlotIndex].FileHandle))) then
      raise Exception.Create('Ошибка закрытия файла : ' + SysUtils.IntToStr(SlotIndex));
    if OpenSlots[SlotIndex].UsesChainedBlocks then
    begin
      FreeMem(OpenSlots[SlotIndex].CompressedBlockBuffer);
      OpenSlots[SlotIndex].CompressedBlockBuffer := nil;
      FreeMem(OpenSlots[SlotIndex].DecompressedBlockBuffer);
      OpenSlots[SlotIndex].DecompressedBlockBuffer := nil;
    end;
    OpenSlots[SlotIndex].IsAvailable := True;
  end;
end;
{ @end $4AE8EC }

{ @routine $4AEAB0 TPackFileEC_GetChainedBlockStoredSizeAtIndex }
function TPackFileEC.GetChainedBlockStoredSizeAtIndex(FirstBlockOffset, BlockIndex: Cardinal): Cardinal;
var BytesRead, StoredSize, Offset: Cardinal;
begin
  Offset := FirstBlockOffset;
  while True do
  begin
    Windows.SetFilePointer(PackageHandle, Offset, nil, FILE_BEGIN);
    Windows.ReadFile(PackageHandle, StoredSize, SizeOf(StoredSize), BytesRead, nil);
    if BlockIndex = 0 then Break;
    Dec(BlockIndex);
    Offset := Offset + StoredSize + SizeOf(StoredSize);
  end;
  Result := StoredSize;
end;
{ @end $4AEAB0 }

{ @routine $4AEAFC TPackFileEC_ReadEntrySlot }
function TPackFileEC.ReadEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean;
var BytesRead, BlockIndex, BlockOffset, ChunkSize, StoredSize, RelativeOffset: Cardinal;
    Decoded, Dest: Pointer;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  if OpenSlots[SlotIndex].UsesChainedBlocks then
  begin
    Decoded := OpenSlots[SlotIndex].DecompressedBlockBuffer;
    Dest := Buffer;
    while ByteCount <> 0 do
    begin
      RelativeOffset := OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
      BlockIndex := RelativeOffset shr PackCompressionBlockShift;
      BlockOffset := RelativeOffset - BlockIndex * PackCompressionBlockSize;
      ChunkSize := ByteCount;
      if PackCompressionBlockSize - BlockOffset < ChunkSize then
        ChunkSize := PackCompressionBlockSize - BlockOffset;
      if OpenSlots[SlotIndex].CurrentBlockIndex <> Integer(BlockIndex) then
      begin
        StoredSize := GetChainedBlockStoredSizeAtIndex(OpenSlots[SlotIndex].DataStartOffset, BlockIndex);
        Result := Windows.ReadFile(PackageHandle, OpenSlots[SlotIndex].CompressedBlockBuffer^, StoredSize, BytesRead, nil);
        if not Result then Exit;
        OKGF_ZLib_UnCompress2(OpenSlots[SlotIndex].DecompressedBlockBuffer, PackCompressionBlockSize,
          OpenSlots[SlotIndex].CompressedBlockBuffer, StoredSize);
        OpenSlots[SlotIndex].CurrentBlockIndex := BlockIndex;
      end;
      Move(OffsetPackPointer(Decoded, BlockOffset)^, Dest^, ChunkSize);
      Dest := OffsetPackPointer(Dest, ChunkSize);
      Dec(ByteCount, ChunkSize);
      Inc(OpenSlots[SlotIndex].CurrentDataOffset, ChunkSize);
    end;
    Result := True;
  end
  else
  begin
    Windows.SetFilePointer(OpenSlots[SlotIndex].FileHandle, OpenSlots[SlotIndex].CurrentDataOffset, nil, FILE_BEGIN);
    Result := Windows.ReadFile(OpenSlots[SlotIndex].FileHandle, Buffer^, ByteCount, BytesRead, nil);
    Result := Result and (ByteCount = BytesRead);
    Inc(OpenSlots[SlotIndex].CurrentDataOffset, BytesRead);
  end;
end;
{ @end $4AEAFC }

{ @routine $4AED88 TPackFileEC_WriteEntrySlot }
function TPackFileEC.WriteEntrySlot(SlotIndex: Cardinal; Buffer: Pointer; ByteCount: Cardinal): Boolean;
var BytesWritten, Size: Cardinal;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  if OpenSlots[SlotIndex].UsesChainedBlocks then raise Exception.Create('Ошибочная операция записи в сжатый файл');
  Windows.SetFilePointer(OpenSlots[SlotIndex].FileHandle, OpenSlots[SlotIndex].CurrentDataOffset, nil, FILE_BEGIN);
  Result := Windows.WriteFile(OpenSlots[SlotIndex].FileHandle, Buffer^, ByteCount, BytesWritten, nil);
  Result := Result and (ByteCount = BytesWritten);
  Inc(OpenSlots[SlotIndex].CurrentDataOffset, BytesWritten);
  Size := OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
  if Size > OpenSlots[SlotIndex].DataSize then OpenSlots[SlotIndex].DataSize := Size;
end;
{ @end $4AED88 }

{ @routine $4AEF40 TPackFileEC_SeekEntrySlot }
function TPackFileEC.SeekEntrySlot(SlotIndex, Offset: Cardinal; Origin: Integer): Boolean;
var Position, BlockIndex: Cardinal;
begin
  Result := False;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  if Origin = FILE_CURRENT then Offset := OpenSlots[SlotIndex].CurrentDataOffset + Offset - OpenSlots[SlotIndex].DataStartOffset
  else if Origin = FILE_END then Offset := OpenSlots[SlotIndex].DataSize - Offset;
  if OpenSlots[SlotIndex].UsesChainedBlocks then
  begin
    if Offset > OpenSlots[SlotIndex].DataSize then Exit;
    BlockIndex := Offset shr PackCompressionBlockShift;
    if BlockIndex <> Cardinal(OpenSlots[SlotIndex].CurrentBlockIndex) then OpenSlots[SlotIndex].CurrentBlockIndex := -1;
    OpenSlots[SlotIndex].CurrentDataOffset := OpenSlots[SlotIndex].DataStartOffset + Offset;
  end
  else
  begin
    Position := Windows.SetFilePointer(OpenSlots[SlotIndex].FileHandle, OpenSlots[SlotIndex].DataStartOffset + Offset, nil, FILE_BEGIN);
    if Position = $FFFFFFFF then raise Exception.Create('Ошибка установки указателя в пакетном файле :' + PackagePath);
    OpenSlots[SlotIndex].CurrentDataOffset := Position;
  end;
  Result := True;
end;
{ @end $4AEF40 }

{ @routine $4AF100 TPackFileEC_GetEntrySlotPosition }
function TPackFileEC.GetEntrySlotPosition(SlotIndex: Cardinal): Cardinal;
begin
  Result := $FFFFFFFF;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  Result := OpenSlots[SlotIndex].CurrentDataOffset - OpenSlots[SlotIndex].DataStartOffset;
end;
{ @end $4AF100 }

{ @routine $4AF1EC TPackFileEC_GetEntrySlotSize }
function TPackFileEC.GetEntrySlotSize(SlotIndex: Cardinal): Cardinal;
begin
  Result := $FFFFFFFF;
  if SlotIndex = $FFFFFFFF then Exit;
  if SlotIndex > High(OpenSlots) then
    raise Exception.Create(PackSlotRangeError + SysUtils.IntToStr(High(OpenSlots)) + ': ' + SysUtils.IntToStr(SlotIndex));
  if OpenSlots[SlotIndex].IsAvailable then Exit;
  Result := OpenSlots[SlotIndex].DataSize;
end;
{ @end $4AF1EC }

{ @routine $4AF2D4 TPackFileEC_FileExists }
function TPackFileEC.FileExists(FileName: AnsiString): Boolean;
begin
  Result := False;
  if RootFolder.EntryExists(FileName) then Result := True
  else if SysUtils.FileExists(FileName) then Result := True;
end;
{ @end $4AF2D4 }

{ @routine $4AF33C THsFolderEC_Create }
constructor THsFolderEC.Create(FolderName: AnsiString);
begin
  EntryBuffer := nil;
  HeaderSize := 12;
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  Parent := nil;
  OriginalName := FolderName;
  UpperName := SysUtils.UpperCase(FolderName);
  ChangedFlag := False;
  InitializedEmptyFlag := False;
end;
{ @end $4AF33C }

{ @routine $4AF3F8 THsFolderEC_CreateChild }
constructor THsFolderEC.CreateChild(FolderName: AnsiString; Parent: THsFolderEC);
begin
  EntryBuffer := nil;
  HeaderSize := 12;
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  Self.Parent := Parent;
  OriginalName := FolderName;
  UpperName := SysUtils.UpperCase(FolderName);
  ChangedFlag := False;
  InitializedEmptyFlag := False;
end;
{ @end $4AF3F8 }

{ @routine $4AF4B8 THsFolderEC_Destroy }
destructor THsFolderEC.Destroy;
begin
  Unload;
end;
{ @end $4AF4B8 }

{ @routine $4AF4D8 THsFolderEC_GetEntry }
function THsFolderEC.GetEntry(Index: Cardinal): PPackEntryEC;
begin
  if Index < EntryCount then Result := OffsetPackPointer(EntryBuffer, EntryRecordSize * Index)
  else Result := nil;
end;
{ @end $4AF4D8 }

{ @routine $4AF4F4 THsFolderEC_FindEntry }
function THsFolderEC.FindEntry(EntryName: AnsiString): PPackEntryEC;
var i: Integer; Entry: PPackEntryEC;
begin
  EntryName := SysUtils.UpperCase(EntryName);
  Result := nil;
  for i := 0 to EntryCount - 1 do
  begin
    Entry := GetEntry(i);
    if Entry.Flags = 0 then
      if SysUtils.StrComp(Entry.UpperName, PAnsiChar(EntryName)) = 0 then
      begin
        Result := Entry;
        Break;
      end;
  end;
end;
{ @end $4AF4F4 }

{ @routine $4AF5AC THsFolderEC_InitializeEmpty }
procedure THsFolderEC.InitializeEmpty;
begin
  EntryCount := 0;
  EntryRecordSize := SizeOf(TPackEntryEC);
  HeaderSize := EntryRecordSize * EntryCount + 12;
  EntryBuffer := nil;
  InitializedEmptyFlag := True;
  UpdateParentEntry;
end;
{ @end $4AF5AC }

{ @routine $4AF5D4 THsFolderEC_Load }
function THsFolderEC.Load(FileHandle, SubtreeOffset: Cardinal): Boolean;
var BytesRead: Cardinal; Success: Boolean; i: Integer; Entry: PPackEntryEC; Folder: THsFolderEC;
begin
  Result := False;
  if EntryBuffer <> nil then Exit;
  InitializedEmptyFlag := False;
  ChangedFlag := False;
  Windows.SetFilePointer(FileHandle, SubtreeOffset, nil, FILE_BEGIN);
  Success := Windows.ReadFile(FileHandle, HeaderSize, 12, BytesRead, nil);
  if not Success then Exit;
  if BytesRead <> 12 then Exit;
  if EntryRecordSize <> SizeOf(TPackEntryEC) then Exit;
  EntryBuffer := AllocMem(EntryCount * EntryRecordSize);
  for i := 0 to EntryCount - 1 do
  begin
    Success := Windows.ReadFile(FileHandle, GetEntry(i)^, EntryRecordSize, BytesRead, nil);
    if not Success or (BytesRead <> EntryRecordSize) then begin Unload; Exit end;
  end;
  for i := 0 to EntryCount - 1 do
  begin
    Entry := GetEntry(i);
    Entry.ChildFolder := nil;
    Entry.KindCopy := Entry.Kind;
  end;
  for i := 0 to EntryCount - 1 do
  begin
    Entry := GetEntry(i);
    if (Entry.Kind = 3) and (Entry.Flags = 0) then
    begin
      Folder := THsFolderEC.CreateChild(Entry.OriginalName + '', Self);
      Entry.ChildFolder := Folder;
      Success := Folder.Load(FileHandle, Entry.TargetOffset);
      if not Success then begin Unload; Exit end;
    end;
  end;
  Result := True;
end;
{ @end $4AF5D4 }

{ @routine $4AF794 THsFolderEC_Unload }
procedure THsFolderEC.Unload;
var
  i: Integer;
  Entry: PPackEntryEC;
  Folder: THsFolderEC;
begin
  if EntryBuffer <> nil then
  begin
    for i := 0 to EntryCount - 1 do
    begin
      Entry := GetEntry(i);
      if (Entry.Kind <> 3) or (Entry.Flags <> 0) then Continue;
      begin
        Folder := Entry.ChildFolder;
        if Folder <> nil then Folder.Free;
        Entry.ChildFolder := nil;
      end;
    end;
    FreeMem(EntryBuffer);
    EntryBuffer := nil;
    EntryCount := 0;
    HeaderSize := EntryCount * EntryRecordSize + 12;
    ChangedFlag := True;
    UpdateParentEntry;
  end;
end;
{ @end $4AF794 }

{ @routine $4AF810 THsFolderEC_EntryExists }
function THsFolderEC.EntryExists(EntryPath: AnsiString): Boolean;
var Name, Tail: AnsiString; Entry: PPackEntryEC; Folder: THsFolderEC; Found: Boolean;
begin
  Found := False;
  Name := AnsiBeforeFirstDelimiter(EntryPath, '/\');
  Tail := AnsiAfterFirstDelimiter(EntryPath, '/\');
  Entry := FindEntry(Name);
  if Entry <> nil then
    if Entry.Kind = 3 then
    begin
      if Tail <> '' then
      begin
        Folder := Entry.ChildFolder;
        Found := Folder.EntryExists(Tail);
      end;
    end
    else if Tail = '' then Found := True;
  Result := Found;
end;
{ @end $4AF810 }

{ @routine $4AF8C8 THsFolderEC_ResolveEntryByPath }
function THsFolderEC.ResolveEntryByPath(EntryPath: AnsiString): PPackEntryEC;
var Head, Tail: AnsiString; Entry: PPackEntryEC; Folder: THsFolderEC;
begin
  Result := nil;
  Head := AnsiBeforeFirstDelimiter(EntryPath, '/\');
  Tail := AnsiAfterFirstDelimiter(EntryPath, '/\');
  Entry := FindEntry(Head);
  if Entry <> nil then
  begin
    if Entry.Kind = 3 then
    begin
      if Tail = '' then Result := Entry
      else
      begin
        Folder := Entry.ChildFolder;
        Result := Folder.ResolveEntryByPath(Tail);
      end;
    end
    else if Tail = '' then Result := Entry;
  end;
end;
{ @end $4AF8C8 }

{ @routine $4AF984 THsFolderEC_UpdateParentEntry }
procedure THsFolderEC.UpdateParentEntry;
var Entry: PPackEntryEC;
begin
  if Parent <> nil then
  begin
    Entry := Parent.FindEntry(OriginalName);
    if Entry = nil then raise Exception.Create('Сбой в файловой системе пакетного файла - Folder: ' + UpperName);
    if Entry.Kind <> 3 then raise Exception.Create('Конфликт имен файл/директория: ' + UpperName);
    Entry.StoredSize := HeaderSize;
    Entry.TargetOffset := 0;
    Parent.ChangedFlag := True;
  end;
end;
{ @end $4AF984 }

{ @routine $4AFAA0 TPackCollectionEC_Create }
constructor TPackCollectionEC.Create;
var i: Integer;
begin
  NameToPackIndexHash := nil;
  UseFastNameIndex := False;
  LastPack := nil;
  FirstPack := nil;
  for i := Low(PackByIndex) to High(PackByIndex) do PackByIndex[i] := nil;
end;
{ @end $4AFAA0 }

{ @routine $4AFAE8 TPackCollectionEC_Destroy }
destructor TPackCollectionEC.Destroy;
begin
  Clear(False);
end;
{ @end $4AFAE8 }

{ @routine $4AFB0C TPackCollectionEC_Clear }
procedure TPackCollectionEC.Clear(FreePacks: Boolean);
var i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do PackByIndex[i] := nil;
  if NameToPackIndexHash <> nil then
  begin
    NameToPackIndexHash.Free;
    NameToPackIndexHash := nil;
  end;
  while FirstPack <> nil do RemovePack(FirstPack, FreePacks);
end;
{ @end $4AFB0C }

{ @routine $4AFB4C TPackCollectionEC_AddPackToFront }
procedure TPackCollectionEC.AddPackToFront(Pack: TPackFileEC);
var Item: TPackFileEC; Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do PackByIndex[i] := nil;
  if FirstPack = nil then
  begin
    FirstPack := Pack;
    LastPack := Pack;
    Pack.NextPack := nil;
    Pack.PrevPack := nil;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end
  else
  begin
    Pack.PrevPack := nil;
    Pack.NextPack := FirstPack;
    FirstPack.PrevPack := Pack;
    FirstPack := Pack;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end;
end;
{ @end $4AFB4C }

{ @routine $4AFBC4 TPackCollectionEC_AddPackToBack }
procedure TPackCollectionEC.AddPackToBack(Pack: TPackFileEC);
var Item: TPackFileEC; Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do PackByIndex[i] := nil;
  if FirstPack = nil then
  begin
    FirstPack := Pack;
    LastPack := Pack;
    Pack.NextPack := nil;
    Pack.PrevPack := nil;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end
  else
  begin
    Pack.PrevPack := LastPack;
    Pack.NextPack := nil;
    LastPack.NextPack := Pack;
    LastPack := Pack;
    Item := FirstPack;
    Count := 0;
    while Item <> nil do
    begin
      Item.CollectionIndex := Count;
      PackByIndex[Count] := Item;
      Inc(Count);
      Item := Item.NextPack;
    end;
  end;
end;
{ @end $4AFBC4 }

{ @routine $4AFC3C TPackCollectionEC_RemovePack }
procedure TPackCollectionEC.RemovePack(Pack: TPackFileEC; FreePack: Boolean);
var Item: TPackFileEC; Count, i: Integer;
begin
  for i := Low(PackByIndex) to High(PackByIndex) do PackByIndex[i] := nil;
  if Pack.PrevPack <> nil then Pack.PrevPack.NextPack := Pack.NextPack;
  if Pack.NextPack <> nil then Pack.NextPack.PrevPack := Pack.PrevPack;
  if FirstPack = Pack then FirstPack := Pack.NextPack;
  if LastPack = Pack then LastPack := Pack.PrevPack;
  if FreePack then Pack.Free;
  Item := FirstPack;
  Count := 0;
  while Item <> nil do
  begin
    Item.CollectionIndex := Count;
    PackByIndex[Count] := Item;
    Inc(Count);
    Item := Item.NextPack;
  end;
end;
{ @end $4AFC3C }

{ @routine $4AFCAC TPackCollectionEC_OpenAllPackages }
function TPackCollectionEC.OpenAllPackages: Boolean;
var Pack: TPackFileEC;
begin
  Result := False;
  if UseFastNameIndex then
  begin
    if NameToPackIndexHash <> nil then NameToPackIndexHash.Free;
    NameToPackIndexHash := THashEC.Create;
    NameToPackIndexHash.InitializeEmptyTable(Length(NameToPackIndexHash.Slots));
  end;
  Pack := FirstPack;
  while Pack <> nil do
  begin
    if not Pack.Open then Break;
    Pack := Pack.NextPack;
  end;
  if Pack <> nil then
  begin
    Pack := Pack.PrevPack;
    while Pack <> nil do
    begin
      Pack.Close;
      Pack := Pack.PrevPack;
    end;
    Exit;
  end;
  Result := True;
end;
{ @end $4AFCAC }

{ @routine $4AFD24 TPackCollectionEC_CloseAllPackages }
function TPackCollectionEC.CloseAllPackages: Boolean;
var Pack: TPackFileEC;
begin
  Pack := FirstPack;
  while Pack <> nil do
  begin
    Pack.Close;
    Pack := Pack.NextPack;
  end;
  if NameToPackIndexHash <> nil then
  begin
    NameToPackIndexHash.Free;
    NameToPackIndexHash := nil;
  end;
  Result := True;
end;
{ @end $4AFD24 }

{ @routine $4AFD54 TPackCollectionEC_GetPackByIndex }
function TPackCollectionEC.GetPackByIndex(PackIndex: Integer): TPackFileEC;
var Pack: TPackFileEC;
begin
  Pack := FirstPack;
  while Pack <> nil do
  begin
    if PackIndex = 0 then Break;
    Pack := Pack.NextPack;
    Dec(PackIndex);
  end;
  Result := Pack;
end;
{ @end $4AFD54 }

{ @routine $4AFD68 TPackCollectionEC_OpenEntryByPathAcrossPackages }
function TPackCollectionEC.OpenEntryByPathAcrossPackages(EntryPath: AnsiString; DesiredAccess: Cardinal): Integer;
var Pack: TPackFileEC; Slot, Index, HashSlot, MappedIndex: Integer;
begin
  Result := -1;
  Index := 0;
  Slot := -1;
  if UseFastNameIndex then
  begin
    HashSlot := NameToPackIndexHash.FindOrInsertKeySlot(EntryPath);
    if HashSlot <> -1 then
    begin
      MappedIndex := NameToPackIndexHash.GetSlotMappedValue(HashSlot);
      if MappedIndex = -1 then
      begin
        Pack := FirstPack;
        while Pack <> nil do
        begin
          Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
          if Slot <> -1 then Break;
          Pack := Pack.NextPack;
        end;
        if Slot = -1 then Exit;
        MappedIndex := Pack.CollectionIndex;
        NameToPackIndexHash.SetSlotMappedValue(HashSlot, MappedIndex);
      end
      else
      begin
        Pack := PackByIndex[MappedIndex];
        Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
        if Slot = -1 then NameToPackIndexHash.NoteStaleMappedValue;
      end;
      if Slot <> -1 then
      begin
        Result := MappedIndex * PackOpenSlotCount + Slot;
        Exit;
      end;
    end;
  end;
  Pack := FirstPack;
  while Pack <> nil do
  begin
    Slot := Pack.OpenEntryByPath(EntryPath, DesiredAccess);
    if Slot <> -1 then Break;
    Pack := Pack.NextPack;
    Inc(Index);
  end;
  if Slot <> -1 then Result := Index * PackOpenSlotCount + Slot;
end;
{ @end $4AFD68 }

{ @routine $4AFEBC TPackCollectionEC_CreateLooseFile }
function TPackCollectionEC.CreateLooseFile(FilePath: AnsiString): Integer;
var Slot: Integer;
begin
  Result := -1;
  if FirstPack <> nil then
  begin
    Slot := FirstPack.CreateLooseFile(FilePath);
    if Slot <> -1 then Result := Slot;
  end;
end;
{ @end $4AFEBC }

{ @routine $4AFF1C TPackCollectionEC_CloseEntryHandle }
function TPackCollectionEC.CloseEntryHandle(Handle: Integer): Boolean;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.CloseEntrySlot(Handle - Index * PackOpenSlotCount);
end;
{ @end $4AFF1C }

{ @routine $4AFF4C TPackCollectionEC_ReadEntryHandle }
function TPackCollectionEC.ReadEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.ReadEntrySlot(Handle - Index * PackOpenSlotCount, @Buffer, ByteCount);
end;
{ @end $4AFF4C }

{ @routine $4AFF90 TPackCollectionEC_WriteEntryHandle }
function TPackCollectionEC.WriteEntryHandle(Handle: Integer; var Buffer; ByteCount: Cardinal): Boolean;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.WriteEntrySlot(Handle - Index * PackOpenSlotCount, @Buffer, ByteCount);
end;
{ @end $4AFF90 }

{ @routine $4AFFD4 TPackCollectionEC_SeekEntryHandle }
function TPackCollectionEC.SeekEntryHandle(Handle: Integer; Offset: Cardinal; Origin: Integer): Boolean;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := False;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.SeekEntrySlot(Handle - Index * PackOpenSlotCount, Offset, Origin);
end;
{ @end $4AFFD4 }

{ @routine $4B0018 TPackCollectionEC_GetEntryHandlePosition }
function TPackCollectionEC.GetEntryHandlePosition(Handle: Integer): Cardinal;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := $FFFFFFFF;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.GetEntrySlotPosition(Handle - Index * PackOpenSlotCount);
end;
{ @end $4B0018 }

{ @routine $4B0048 TPackCollectionEC_GetEntryHandleSize }
function TPackCollectionEC.GetEntryHandleSize(Handle: Integer): Cardinal;
var Pack: TPackFileEC; Index: Integer;
begin
  Result := $FFFFFFFF;
  Index := Handle shr PackOpenSlotShift;
  Pack := GetPackByIndex(Index);
  if Pack <> nil then Result := Pack.GetEntrySlotSize(Handle - Index * PackOpenSlotCount);
end;
{ @end $4B0048 }

{ @routine $4B0078 MatchLookupKeySuffix }
function MatchLookupKeySuffix(var Key: AnsiString; SuffixBytes: Pointer; SuffixLength: Integer): Boolean;
var i, j, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then First := KeyLength - 31 else First := 1;
  j := 0;
  Result := True;
  for i := First to KeyLength do
  begin
    if Key[i] <> PAnsiChar(SuffixBytes)[j] then begin Result := False; Break end;
    Inc(j);
  end;
end;
{ @end $4B0078 }

{ @routine $4B00C4 CopyLookupKeySuffix }
procedure CopyLookupKeySuffix(DestSuffixBytes: Pointer; SuffixLength: Integer; var Key: AnsiString);
var i, j, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then First := KeyLength - 31 else First := 1;
  j := 0;
  for i := First to KeyLength do
  begin
    PAnsiChar(DestSuffixBytes)[j] := Key[i];
    Inc(j);
  end;
end;
{ @end $4B00C4 }

{ @routine $4B00FC THashEC_Create }
constructor THashEC.Create;
begin
  InitializeEmptyTable(Length(Slots));
end;
{ @end $4B00FC }

{ @routine $4B0134 THashEC_Destroy }
destructor THashEC.Destroy;
begin
  ReleaseTable;
end;
{ @end $4B0134 }

{ @routine $4B0154 THashEC_ComputeLookupBucketAndFullHash }
function THashEC.ComputeLookupBucketAndFullHash(var Key: AnsiString; out FullHash: Cardinal): Integer;
var Hash: Cardinal; i, First, KeyLength: Integer;
begin
  KeyLength := Length(Key);
  if KeyLength > 32 then First := KeyLength - 31 else First := 1;
  Hash := 0;
  for i := First to KeyLength do Hash := Ord(Key[i]) + Hash * 2;
  FullHash := Hash;
  Result := Hash and High(Slots);
end;
{ @end $4B0154 }

{ @routine $4B0198 THashEC_FindOrInsertKeySlot }
function THashEC.FindOrInsertKeySlot(Key: AnsiString): Integer;
var Bucket, Hash, i: Cardinal; Found: Integer; Temp: THashSlotEC;
begin
  Bucket := ComputeLookupBucketAndFullHash(Key, Hash);
  Found := -1;
  for i := Bucket to Bucket + 5 do
  begin
    if Slots[i].MappedValue <> -1 then
    begin
      if (Slots[i].FullHash = Hash) and MatchLookupKeySuffix(Key, @Slots[i].KeySuffix, 32) then
      begin
        Found := i;
        Inc(Slots[i].HitCount);
        Inc(OperationCount);
        Inc(HitCount);
        Inc(HitCountCopy);
        MaybeResetStatistics;
        if (i > Bucket) and (i < Cardinal(Length(Slots))) then
          if Slots[i].HitCount > Slots[i - 1].HitCount then
          begin
            Temp := Slots[i];
            Slots[i] := Slots[i - 1];
            Slots[i - 1] := Temp;
          end;
        Break;
      end;
    end
    else
    begin
      Slots[i].FullHash := Hash;
      Slots[i].HitCount := 1;
      Slots[i].Unknown0C := 1;
      CopyLookupKeySuffix(@Slots[i].KeySuffix, 32, Key);
      Found := i;
      Inc(OperationCount);
      Inc(MissCount);
      MaybeResetStatistics;
      Break;
    end;
    if i > High(Slots) then Break;
  end;
  if Found = -1 then
  begin
    Inc(OperationCount);
    Inc(MissCount);
    MaybeResetStatistics;
  end;
  Result := Found;
end;
{ @end $4B0198 }

{ @routine $4B0314 THashEC_SetSlotMappedValue }
procedure THashEC.SetSlotMappedValue(SlotIndex, Value: Integer);
begin
  Slots[SlotIndex].MappedValue := Value;
end;
{ @end $4B0314 }

{ @routine $4B031C THashEC_InitializeEmptyTable }
function THashEC.InitializeEmptyTable(BucketCount: Integer): Boolean;
var i: Integer;
begin
  OperationCount := 0;
  HitCount := 0;
  HitCountCopy := 0;
  StaleValueCount := 0;
  MissCount := 0;
  for i := Low(Slots) to High(Slots) do Slots[i].MappedValue := -1;
  Result := True;
end;
{ @end $4B031C }

{ @routine $4B0350 THashEC_ReleaseTable }
function THashEC.ReleaseTable: Boolean;
begin
  Result := True;
end;
{ @end $4B0350 }

{ @routine $4B0354 THashEC_GetSlotMappedValue }
function THashEC.GetSlotMappedValue(SlotIndex: Integer): Integer;
begin
  Result := Slots[SlotIndex].MappedValue;
end;
{ @end $4B0354 }

{ @routine $4B035C THashEC_MaybeResetStatistics }
procedure THashEC.MaybeResetStatistics;
begin
  if (OperationCount mod 100 = 0) and (OperationCount <> 0) then
  begin
    OperationCount := 0;
    HitCount := 0;
    HitCountCopy := 0;
    StaleValueCount := 0;
    MissCount := 0;
  end;
end;
{ @end $4B035C }

{ @routine $4B0394 THashEC_NoteStaleMappedValue }
procedure THashEC.NoteStaleMappedValue;
begin
  Inc(StaleValueCount);
end;
{ @end $4B0394 }

end.

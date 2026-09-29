unit EC_CacheGAI;
// Unit bracket (inferred): CODE 0x0046E624..0x0046EC6B; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache, GR_gi, Types;

type
  TCGaiControlEC = class;
  TCGaiEC = class;

  TCGaiControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $46E6F4
    function CreateData: TCacheDataEC; override; // @addr $46E760
    function AcquireData: TCacheDataEC; override; // @addr $46E790
  end;

  TCGaiEC = class(TCacheDataEC) // @size $30
  public
    RawGaiData: Pointer; // @offset $20
    Header: PGaiHeader; // @offset $24
    DecodedFrameGi: TgiGR; // @offset $28
    SequenceTableData: PGaiSequenceTableHeader; // @offset $2C

    constructor Create; // @addr $46E798
    destructor Destroy; override; // @addr $46E7DC
    function GetFrameCount: Integer; // @addr $46E81C
    function HasPlaybackFlags: Boolean; // @addr $46E824
    function GetBoundsRect: TRect; // @addr $46E830
    function GetCanvasSize: TPoint; // @addr $46E844
    function LoadFrameGi(FrameIndex: Integer): TgiGR; // @addr $46E860 @note "Returns borrowed, reused DecodedFrameGi storage, or nil."
    function IsFrameCompressed(FrameIndex: Integer): Boolean; // @addr $46E930 @note "Does not validate FrameIndex."
    function GetSequenceCount: Integer; // @addr $46E97C @note "Returns zero when no sequence table exists. Other sequence accessors require a valid table and indexes."
    function GetSequenceFrameCount(SequenceIndex: Integer): Integer; // @addr $46E990
    function GetSequenceFrameIndex(SequenceIndex, FrameInSequence: Integer): Integer; // @addr $46EAEC
    function GetSequenceFrameDelay(SequenceIndex, FrameInSequence: Integer): Integer; // @addr $46EB38
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $46EB84 @note "Requires a complete header; frame and sequence offsets are trusted."
    procedure FillSequenceFrameIndexTable(SequenceIndex: Integer; DestTable: Pointer; EntryStride: Integer); // @addr $46E9CC
    procedure FillSequenceFrameDelayTable(SequenceIndex: Integer; DestTable: Pointer; EntryStride: Integer); // @addr $46EA5C
  end;

function AcquireCachedGai(Control: TCacheControlEC): TCGaiEC; // @addr $46E770

implementation

// @unit-initialization $46EC64
// @unit-finalization $46EC34

uses EC_Mem, EC_Str, EC_Struct, GR_Main, GR_GraphBuf, Windows;

{ @routine $46E6F4 TCGaiControlEC_QueueLoadIfMissing }
procedure TCGaiControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCGaiControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCGaiEC) = nil then
  begin
    Control := TCGaiControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $46E6F4 }

{ @routine $46E760 TCGaiControlEC_CreateData }
function TCGaiControlEC.CreateData: TCacheDataEC;
begin
  Result := TCGaiEC.Create;
end;
{ @end $46E760 }

{ @routine $46E770 AcquireCachedGai }
function AcquireCachedGai(Control: TCacheControlEC): TCGaiEC;
begin
  Result := Control.AcquireDataFromConfig(TCGaiEC) as TCGaiEC;
end;
{ @end $46E770 }

{ @routine $46E790 TCGaiControlEC_AcquireData }
function TCGaiControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedGai(Self);
end;
{ @end $46E790 }

{ @routine $46E798 TCGaiEC_Create }
constructor TCGaiEC.Create;
begin
  inherited Create;
  DecodedFrameGi := TgiGR.Create;
end;
{ @end $46E798 }

{ @routine $46E7DC TCGaiEC_Destroy }
destructor TCGaiEC.Destroy;
begin
  if RawGaiData <> nil then
  begin
    FreeEC(RawGaiData); RawGaiData := nil;
  end;
  DecodedFrameGi.Free;
  inherited Destroy;
end;
{ @end $46E7DC }

{ @routine $46E81C TCGaiEC_GetFrameCount }
function TCGaiEC.GetFrameCount: Integer;
begin
  Result := Header.FrameCount;
end;
{ @end $46E81C }

{ @routine $46E824 TCGaiEC_HasPlaybackFlags }
function TCGaiEC.HasPlaybackFlags: Boolean;
begin
  Result := Header.Flags <> 0;
end;
{ @end $46E824 }

{ @routine $46E830 TCGaiEC_GetBoundsRect }
function TCGaiEC.GetBoundsRect: TRect;
begin
  Result := Header.Bounds;
end;
{ @end $46E830 }

{ @routine $46E844 TCGaiEC_GetCanvasSize }
function TCGaiEC.GetCanvasSize: TPoint;
begin
  Result := SubtractPoints(Header.Bounds.BottomRight, Header.Bounds.TopLeft);
end;
{ @end $46E844 }

{ @routine $46E860 TCGaiEC_LoadFrameGi }
function TCGaiEC.LoadFrameGi(FrameIndex: Integer): TgiGR;
var Offset: Integer;
begin
  Offset := ReadDWordEC(AddPointerOffset(RawGaiData, (FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader)) + 0));
  if Offset = 0 then
  begin
    Result := nil;
    Exit;
  end;
  if ReadWordEC(AddPointerOffset(RawGaiData, Offset)) = $4C5A then
  begin
    DecodedFrameGi.LoadCompressedGiBytes(AddPointerOffset(RawGaiData, Offset), ReadDWordEC(AddPointerOffset(RawGaiData, (FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader)) + 4)));
    DecodedFrameGi.BuildPalettedFormat4ColorCache;
  end
  else DecodedFrameGi.LoadRawGiBytes(AddPointerOffset(RawGaiData, Offset), ReadDWordEC(AddPointerOffset(RawGaiData, (FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader)) + 4)));
  if DecodedFrameGi.IsEmpty then Result := nil
  else Result := DecodedFrameGi;
end;
{ @end $46E860 }

{ @routine $46E930 TCGaiEC_IsFrameCompressed }
function TCGaiEC.IsFrameCompressed(FrameIndex: Integer): Boolean;
var Offset: Integer;
begin
  Offset := ReadDWordEC(AddPointerOffset(RawGaiData, FrameIndex * SizeOf(TGaiFrameEntry) + SizeOf(TGaiHeader)));
  if Offset = 0 then Result := False
  else Result := ReadWordEC(AddPointerOffset(RawGaiData, Offset)) = $4C5A;
end;
{ @end $46E930 }

{ @routine $46E97C TCGaiEC_GetSequenceCount }
function TCGaiEC.GetSequenceCount: Integer;
begin
  if SequenceTableData = nil then Result := 0
  else Result := ReadDWordEC(SequenceTableData);
end;
{ @end $46E97C }

{ @routine $46E990 TCGaiEC_GetSequenceFrameCount }
function TCGaiEC.GetSequenceFrameCount(SequenceIndex: Integer): Integer;
// The directory begins after the eight-byte header.
begin
  Result := ReadDWordEC(AddPointerOffset(SequenceTableData, ReadDWordEC(AddPointerOffset(SequenceTableData, SequenceIndex * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4))));
end;
{ @end $46E990 }

{ @routine $46E9CC TCGaiEC_FillSequenceFrameIndexTable }
procedure TCGaiEC.FillSequenceFrameIndexTable(SequenceIndex: Integer; DestTable: Pointer; EntryStride: Integer);
var Source: Pointer; Index, Count: Integer;
begin
  Source := AddPointerOffset(SequenceTableData, ReadDWordEC(AddPointerOffset(SequenceTableData, SequenceIndex * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4)));
  Count := ReadDWordEC(Source);
  Source := AddPointerOffset(Source, SizeOf(TGaiSequenceDataBlock));
  for Index := 0 to Count - 1 do
  begin
    WriteIntegerEC(DestTable, ReadDWordEC(Source));
    DestTable := AddPointerOffset(DestTable, EntryStride);
    Source := AddPointerOffset(Source, SizeOf(TGaiSequenceFrameEntry));
  end;
end;
{ @end $46E9CC }

{ @routine $46EA5C TCGaiEC_FillSequenceFrameDelayTable }
procedure TCGaiEC.FillSequenceFrameDelayTable(SequenceIndex: Integer; DestTable: Pointer; EntryStride: Integer);
var Source: Pointer; Index, Count: Integer;
begin
  Source := AddPointerOffset(SequenceTableData, ReadDWordEC(AddPointerOffset(SequenceTableData, SequenceIndex * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4)));
  Count := ReadDWordEC(Source);
  Source := AddPointerOffset(Source, SizeOf(TGaiSequenceDataBlock) + SizeOf(Integer));
  for Index := 0 to Count - 1 do
  begin
    WriteIntegerEC(DestTable, ReadDWordEC(Source));
    DestTable := AddPointerOffset(DestTable, EntryStride);
    Source := AddPointerOffset(Source, SizeOf(TGaiSequenceFrameEntry));
  end;
end;
{ @end $46EA5C }

{ @routine $46EAEC TCGaiEC_GetSequenceFrameIndex }
function TCGaiEC.GetSequenceFrameIndex(SequenceIndex, FrameInSequence: Integer): Integer;
begin
  Result := ReadDWordEC(AddPointerOffset(SequenceTableData,
    ReadDWordEC(AddPointerOffset(SequenceTableData, SequenceIndex * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4)) + (FrameInSequence * SizeOf(TGaiSequenceFrameEntry) + 4)));
end;
{ @end $46EAEC }

{ @routine $46EB38 TCGaiEC_GetSequenceFrameDelay }
function TCGaiEC.GetSequenceFrameDelay(SequenceIndex, FrameInSequence: Integer): Integer;
begin
  Result := ReadDWordEC(AddPointerOffset(SequenceTableData,
    ReadDWordEC(AddPointerOffset(SequenceTableData, SequenceIndex * SizeOf(TGaiSequenceDirectoryEntry) + 4 + 4)) + (FrameInSequence * SizeOf(TGaiSequenceFrameEntry) + 4 + 4)));
end;
{ @end $46EB38 }

{ @routine $46EB84 TCGaiEC_LoadFromConfigBuffer }
procedure TCGaiEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var FrameIndex: Integer; Frame: TgiGR;
begin
  if SourceBuffer.DataSize < SizeOf(TGaiHeader) then raise Exception.Create('Error Load Gai');
  RawGaiData := AllocEC(SourceBuffer.DataSize);
  CopyMemory(RawGaiData, SourceBuffer.Data, SourceBuffer.DataSize);
  ResidentBytes := SourceBuffer.DataSize;
  Header := RawGaiData;
  if Header.SequenceTableOffset <> 0 then SequenceTableData := AddPointerOffset(RawGaiData, Header.SequenceTableOffset);
  for FrameIndex := 0 to Header.FrameCount - 1 do
    if not IsFrameCompressed(FrameIndex) then
    begin
      Frame := LoadFrameGi(FrameIndex);
      if Frame <> nil then Frame.BuildPalettedFormat4ColorCache;
    end;
end;
{ @end $46EB84 }

end.

unit EC_CacheSound;
// Unit bracket (inferred): CODE 0x004B84E8..0x004B880B; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache;

type
  TWaveFormatEx = packed record // @size $12
    FormatTag: Word; // @offset $00
    Channels: Word; // @offset $02
    SamplesPerSecond: Cardinal; // @offset $04
    AverageBytesPerSecond: Cardinal; // @offset $08
    BlockAlign: Word; // @offset $0C
    BitsPerSample: Word; // @offset $0E
    ExtraSize: Word; // @offset $10
  end;
  PWaveFormatEx = ^TWaveFormatEx;

  TWaveFileHeader = packed record // @size $2C
    // Uninterpreted RIFF/fmt identifiers and lengths precede these fields.
    Channels: Word; // @offset $16
    SamplesPerSecond: Cardinal; // @offset $18
    BlockAlign: Word; // @offset $20
    BitsPerSample: Word; // @offset $22
    DataId: Cardinal; // @offset $24
    DataSize: Cardinal; // @offset $28
  end;

  TCSoundControlEC = class;
  TCSoundEC = class;

  TCSoundControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $4B85C0 @slot $08
    function CreateData: TCacheDataEC; override; // @addr $4B862C @slot $0C
    function AcquireData: TCacheDataEC; override; // @addr $4B865C @slot $10
  end;

  TCSoundEC = class(TCacheDataEC) // @size $3C
  public
    Format: TWaveFormatEx; // @offset $20
    SampleData: Pointer; // @offset $34
    SampleDataSize: Cardinal; // @offset $38

    constructor Create; // @addr $4B8664
    destructor Destroy; override; // @addr $4B869C
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $4B86D4 @slot $00 @note "Reads 44 bytes from the current position. Forces PCM without validating RIFF, WAVE or fmt identifiers. Scans for data when it is not at offset 36. Ignores LoadOption."
  end;

function AcquireCachedSound(Control: TCacheControlEC): TCSoundEC; // @addr $4B863C

implementation

// @unit-initialization $4B8804
// @unit-finalization $4B87D4

uses EC_Mem, GR_Main, MMSystem;

const
  WaveDataChunkId = $61746164; // little-endian 'data'
  WaveChunkHeaderSize = 2 * SizeOf(Cardinal);

{ @routine $4B85C0 TCSoundControlEC_QueueLoadIfMissing }
procedure TCSoundControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCSoundControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCSoundEC) = nil then
  begin
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $4B85C0 }

{ @routine $4B862C TCSoundControlEC_CreateData }
function TCSoundControlEC.CreateData: TCacheDataEC;
begin
  Result := TCSoundEC.Create;
end;
{ @end $4B862C }

{ @routine $4B863C AcquireCachedSound }
function AcquireCachedSound(Control: TCacheControlEC): TCSoundEC;
begin
  Result := Control.AcquireDataFromConfig(TCSoundEC) as TCSoundEC;
end;
{ @end $4B863C }

{ @routine $4B865C TCSoundControlEC_AcquireData }
function TCSoundControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedSound(Self);
end;
{ @end $4B865C }

{ @routine $4B8664 TCSoundEC_Create }
constructor TCSoundEC.Create;
begin
  inherited Create;
end;
{ @end $4B8664 }

{ @routine $4B869C TCSoundEC_Destroy }
destructor TCSoundEC.Destroy;
begin
  if SampleData <> nil then
  begin
    FreeEC(SampleData);
    SampleData := nil;
  end;
  inherited Destroy;
end;
{ @end $4B869C }

{ @routine $4B86D4 TCSoundEC_LoadFromConfigBuffer }
procedure TCSoundEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var
  Offset: Integer;
  Header: TWaveFileHeader;
begin
  SourceBuffer.ReadBytes(@Header, SizeOf(Header));
  if Header.DataId <> WaveDataChunkId then
  begin
    Offset := 0;
    while SourceBuffer.DataSize - WaveChunkHeaderSize > Offset do
    begin
      if SourceBuffer.GetUInt32At(Offset) = WaveDataChunkId then Break;
      Inc(Offset);
    end;
    if SourceBuffer.DataSize - WaveChunkHeaderSize <= Offset then RaiseWideMessage('WAVE format');
    Header.DataId := WaveDataChunkId;
    Header.DataSize := SourceBuffer.GetUInt32At(Offset + SizeOf(Header.DataId));
    SourceBuffer.SetPosition(Offset + WaveChunkHeaderSize);
  end;
  Format.FormatTag := WAVE_FORMAT_PCM;
  Format.Channels := Header.Channels;
  Format.SamplesPerSecond := Header.SamplesPerSecond;
  Format.BitsPerSample := Header.BitsPerSample;
  Format.BlockAlign := Header.BlockAlign;
  Format.AverageBytesPerSecond := Format.BlockAlign * Format.SamplesPerSecond;
  Format.ExtraSize := 0;
  SampleDataSize := Header.DataSize;
  if SampleData <> nil then
  begin
    FreeEC(SampleData);
    SampleData := nil;
  end;
  SampleData := AllocEC(SampleDataSize);
  SourceBuffer.ReadBytes(SampleData, SampleDataSize);
end;
{ @end $4B86D4 }

end.

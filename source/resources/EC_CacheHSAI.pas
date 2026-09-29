unit EC_CacheHSAI;
// Unit bracket (inferred): CODE 0x0047E730..0x0047EA4B; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache, GR_GraphBuf;

type
  THSAIHeaderEC = packed record // @size $34
    // The leading dword and format metadata at +0x18..+0x2C remain unresolved.
    Width: Integer; // @offset $04
    Height: Integer; // @offset $08
    PitchBytes: Integer; // @offset $0C
    FrameCount: Cardinal; // @offset $10
    FrameStride: Cardinal; // @offset $14
    PalettePresent: Cardinal; // @offset $30
  end;
  PHSAIHeaderEC = ^THSAIHeaderEC;

  TCHSAIControlEC = class;
  TCHSAIEC = class;

  TCHSAIControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $47E804
    function CreateData: TCacheDataEC; override; // @addr $47E870
    function AcquireData: TCacheDataEC; override; // @addr $47E8A0
  end;

  TCHSAIEC = class(TCacheDataEC) // @size $30
  public
    BlobData: Pointer; // @offset $20
    Header: PHSAIHeaderEC; // @offset $24
    Width: Integer; // @offset $28
    Height: Integer; // @offset $2C

    constructor Create; // @addr $47E8A8
    destructor Destroy; override; // @addr $47E8E0
    function GetFramePalette(FrameIndex: Cardinal): PColorRGBA; // @addr $47E944 @note "Returns nil for an invalid frame or absent palette."
    function GetSourcePitchBytes: Integer; // @addr $47E984
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $47E98C @note "Validates only the minimum 0x34-byte header, forces frame stride to 0x4400 and ignores LoadOption."
    function GetFrameIndexPlane(FrameIndex: Cardinal): Pointer; // @addr $47E918 @note "Returns nil when FrameIndex is outside the header count."
  end;

function AcquireCachedHSAI(Control: TCacheControlEC): TCHSAIEC; // @addr $47E880

implementation

// @unit-initialization $47EA44
// @unit-finalization $47EA14

uses EC_OKGF, SysUtils, EC_Mem, GR_Main, Windows;

{ @routine $47E804 TCHSAIControlEC_QueueLoadIfMissing }
procedure TCHSAIControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCHSAIControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCHSAIEC) = nil then
  begin
    Control := TCHSAIControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $47E804 }

{ @routine $47E870 TCHSAIControlEC_CreateData }
function TCHSAIControlEC.CreateData: TCacheDataEC;
begin
  Result := TCHSAIEC.Create;
end;
{ @end $47E870 }

{ @routine $47E880 AcquireCachedHSAI }
function AcquireCachedHSAI(Control: TCacheControlEC): TCHSAIEC;
begin
  Result := Control.AcquireDataFromConfig(TCHSAIEC) as TCHSAIEC;
end;
{ @end $47E880 }

{ @routine $47E8A0 TCHSAIControlEC_AcquireData }
function TCHSAIControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedHSAI(Self);
end;
{ @end $47E8A0 }

{ @routine $47E8A8 TCHSAIEC_Create }
constructor TCHSAIEC.Create;
begin
  inherited Create;
end;
{ @end $47E8A8 }

{ @routine $47E8E0 TCHSAIEC_Destroy }
destructor TCHSAIEC.Destroy;
begin
  if BlobData <> nil then
  begin
    FreeEC(BlobData);
    BlobData := nil;
  end;
  inherited Destroy;
end;
{ @end $47E8E0 }

{ @routine $47E918 TCHSAIEC_GetFrameIndexPlane }
function TCHSAIEC.GetFrameIndexPlane(FrameIndex: Cardinal): Pointer;
begin
  if Header.FrameCount <= Cardinal(FrameIndex) then Result := nil
  else Result := AddPointerOffset(BlobData, SizeOf(THSAIHeaderEC) + Cardinal(FrameIndex) * Header.FrameStride);
end;
{ @end $47E918 }

{ @routine $47E944 TCHSAIEC_GetFramePalette }
function TCHSAIEC.GetFramePalette(FrameIndex: Cardinal): PColorRGBA;
begin
  if Header.FrameCount <= Cardinal(FrameIndex) then Result := nil
  else if Header.PalettePresent = 0 then Result := nil
  else Result := AddPointerOffset(BlobData, SizeOf(THSAIHeaderEC) + Cardinal(FrameIndex) * Header.FrameStride + Header.PitchBytes * Header.Height);
end;
{ @end $47E944 }

{ @routine $47E984 TCHSAIEC_GetSourcePitchBytes }
function TCHSAIEC.GetSourcePitchBytes: Integer;
begin
  Result := Header.PitchBytes;
end;
{ @end $47E984 }

{ @routine $47E98C TCHSAIEC_LoadFromConfigBuffer }
procedure TCHSAIEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  if SourceBuffer.DataSize < SizeOf(THSAIHeaderEC) then raise Exception.Create('Error Load HSAI');
  BlobData := AllocEC(SourceBuffer.DataSize);
  CopyMemory(BlobData, SourceBuffer.Data, SourceBuffer.DataSize);
  ResidentBytes := SourceBuffer.DataSize;
  Header := BlobData;
  Header.FrameStride := $4400;
  Width := Header.Width;
  Height := Header.Height;
  if CurrentPixelFormat.TotalChannelBits = 15 then begin end;
end;
{ @end $47E98C }

end.

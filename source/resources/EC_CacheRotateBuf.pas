unit EC_CacheRotateBuf;
// Unit bracket (inferred): CODE 0x0047CFF4..0x0047D447; inclusive evidence, not full bounds.

interface

uses Classes, EC_Cache;

type
  TCRotateBufControlEC = class;
  TCRotateBufEC = class;

  TCRotateBufControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $47D0D4
    function CreateData: TCacheDataEC; override; // @addr $47D140
    function AcquireData: TCacheDataEC; override; // @addr $47D170
  end;

  TCRotateBufEC = class(TCacheDataEC) // @size $24
  public
    Buffer: Pointer; // @offset $20

    constructor Create; // @addr $47D178
    destructor Destroy; override; // @addr $47D1B4
    procedure LoadFromKey(const Key: WideString); override; // @addr $47D1EC @note "Key contains width,height,source width,source height,center X,center Y as comma-delimited integers."
  end;

function AcquireOrCreateRotateBuf(Control: TCacheControlEC): TCRotateBufEC; // @addr $47D150

implementation

// @unit-initialization $47D440
// @unit-finalization $47D410

uses EC_OKGF, SysUtils, EC_Str, GR_Main, GR_GraphBuf;

{ @routine $47D0D4 TCRotateBufControlEC_QueueLoadIfMissing }
procedure TCRotateBufControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCRotateBufControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCRotateBufEC) = nil then
  begin
    Control := TCRotateBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $47D0D4 }

{ @routine $47D140 TCRotateBufControlEC_CreateData }
function TCRotateBufControlEC.CreateData: TCacheDataEC;
begin
  Result := TCRotateBufEC.Create;
end;
{ @end $47D140 }

{ @routine $47D150 AcquireOrCreateRotateBuf }
function AcquireOrCreateRotateBuf(Control: TCacheControlEC): TCRotateBufEC;
begin
  Result := Control.AcquireDataFromDirectKey(TCRotateBufEC) as TCRotateBufEC;
end;
{ @end $47D150 }

{ @routine $47D170 TCRotateBufControlEC_AcquireData }
function TCRotateBufControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateRotateBuf(Self);
end;
{ @end $47D170 }

{ @routine $47D178 TCRotateBufEC_Create }
constructor TCRotateBufEC.Create;
begin
  inherited Create;
  Buffer := nil;
end;
{ @end $47D178 }

{ @routine $47D1B4 TCRotateBufEC_Destroy }
destructor TCRotateBufEC.Destroy;
begin
  if Buffer <> nil then
  begin
    OKGR_RotateBuf_Free(Buffer);
    Buffer := nil;
  end;
  inherited Destroy;
end;
{ @end $47D1B4 }

{ @routine $47D1EC TCRotateBufEC_LoadFromKey }
procedure TCRotateBufEC.LoadFromKey(const Key: WideString);
begin
  if CountDelimitedPartsW(Key, ',') <> 6 then
    raise Exception.Create('TCRotateBufEC.Load. Error create rotate buf.');
  Buffer := OKGR_RotateBuf_Build(
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 0, ','))),
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 1, ','))),
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 2, ','))),
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 3, ','))),
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 4, ','))),
    StrToInt(AnsiString(ExtractDelimitedPartW(Key, 5, ','))));
  if Buffer = nil then
    raise Exception.Create('TCRotateBufEC.Load. Error create rotate buf.');
end;
{ @end $47D1EC }

end.

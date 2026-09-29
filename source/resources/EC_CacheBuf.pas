unit EC_CacheBuf;
// Unit bracket (inferred): CODE 0x004C5A2C..0x004C5C7F; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache;

type
  TCBufControlEC = class;
  TCBufEC = class;

  TCBufControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $4C5AFC
    function CreateData: TCacheDataEC; override; // @addr $4C5B68
    function AcquireData: TCacheDataEC; override; // @addr $4C5BA4
  end;

  TCBufEC = class(TCacheDataEC) // @size $24
  public
    Buffer: TBufEC; // @offset $20

    constructor Create; // @addr $4C5BAC
    destructor Destroy; override; // @addr $4C5BE4
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $4C5C1C @note "Ignores LoadOption; ResidentBytes is not updated."
  end;

function AcquireOrCreateBuffer(Control: TCacheControlEC): TCBufEC; // @addr $4C5B78 @note "Rewinds the shared buffer."

implementation

// @unit-initialization $4C5C78
// @unit-finalization $4C5C48

uses GR_Main;

{ @routine $4C5AFC TCBufControlEC_QueueLoadIfMissing }
procedure TCBufControlEC.QueueLoadIfMissing(PendingLoads: TList);
var
  Control: TCBufControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCBufEC) = nil then
  begin
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $4C5AFC }

{ @routine $4C5B68 TCBufControlEC_CreateData }
function TCBufControlEC.CreateData: TCacheDataEC;
begin
  Result := TCBufEC.Create;
end;
{ @end $4C5B68 }

{ @routine $4C5B78 AcquireOrCreateBuffer }
function AcquireOrCreateBuffer(Control: TCacheControlEC): TCBufEC;
begin
  Result := Control.AcquireDataFromConfig(TCBufEC) as TCBufEC;
  Result.Buffer.SetPosition(0);
end;
{ @end $4C5B78 }

{ @routine $4C5BA4 TCBufControlEC_AcquireData }
function TCBufControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateBuffer(Self);
end;
{ @end $4C5BA4 }

{ @routine $4C5BAC TCBufEC_Create }
constructor TCBufEC.Create;
begin
  inherited Create;
end;
{ @end $4C5BAC }

{ @routine $4C5BE4 TCBufEC_Destroy }
destructor TCBufEC.Destroy;
begin
  if Buffer <> nil then
  begin
    Buffer.Free;
    Buffer := nil;
  end;
  inherited Destroy;
end;
{ @end $4C5BE4 }

{ @routine $4C5C1C TCBufEC_LoadFromConfigBuffer }
procedure TCBufEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  Buffer := TBufEC.Create;
  Buffer.AddBytes(SourceBuffer.Data, SourceBuffer.DataSize);
end;
{ @end $4C5C1C }

end.

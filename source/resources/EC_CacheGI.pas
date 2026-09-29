unit EC_CacheGI;
// Unit bracket (inferred): CODE 0x0046D6A4..0x0046D8EF; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache, GR_GraphBuf, GR_gi, Types;

type
  TCGiControlEC = class;
  TCGiEC = class;

  TCGiControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $46D774
    function CreateData: TCacheDataEC; override; // @addr $46D7E0
    function AcquireData: TCacheDataEC; override; // @addr $46D810
  end;

  TCGiEC = class(TCacheDataEC) // @size $24
  public
    Image: TgiGR; // @offset $20

    constructor Create; // @addr $46D818
    destructor Destroy; override; // @addr $46D85C
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $46D88C @note "May modify SourceBuffer for resource-specific layout fixups. Ignores LoadOption."
  end;

function AcquireCachedGi(Control: TCacheControlEC): TCGiEC; // @addr $46D7F0

implementation

// @unit-initialization $46D8E8
// @unit-finalization $46D8B8

uses EC_Mem, EC_Str, GR_Main, Windows, Math;

{ @routine $46D774 TCGiControlEC_QueueLoadIfMissing }
procedure TCGiControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCGiControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCGiEC) = nil then
  begin
    Control := TCGiControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $46D774 }

{ @routine $46D7E0 TCGiControlEC_CreateData }
function TCGiControlEC.CreateData: TCacheDataEC;
begin
  Result := TCGiEC.Create;
end;
{ @end $46D7E0 }

{ @routine $46D7F0 AcquireCachedGi }
function AcquireCachedGi(Control: TCacheControlEC): TCGiEC;
begin
  Result := Control.AcquireDataFromConfig(TCGiEC) as TCGiEC;
end;
{ @end $46D7F0 }

{ @routine $46D810 TCGiControlEC_AcquireData }
function TCGiControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedGi(Self);
end;
{ @end $46D810 }

{ @routine $46D818 TCGiEC_Create }
constructor TCGiEC.Create;
begin
  inherited Create;
  Image := TgiGR.Create;
end;
{ @end $46D818 }

{ @routine $46D85C TCGiEC_Destroy }
destructor TCGiEC.Destroy;
begin
  Image.Free;
  inherited Destroy;
end;
{ @end $46D85C }

{ @routine $46D88C TCGiEC_LoadFromConfigBuffer }
procedure TCGiEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  Image.LoadRawGiFromBuffer(SourceBuffer);
  ResidentBytes := Image.DataSize;
  if CurrentPixelFormat.TotalChannelBits = 15 then Image.Convert565To555;
end;
{ @end $46D88C }

end.

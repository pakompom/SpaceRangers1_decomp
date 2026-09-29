unit EC_CachePalBitmap;
// Unit bracket (inferred): CODE 0x0047CD98..0x0047CFF3; inclusive evidence, not full bounds.

interface

uses EC_Buf, GR_GraphBufPal, EC_Cache, Classes;

type
  TCPalBitmapControlEC = class;
  TCPalBitmapEC = class;

  TCPalBitmapControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $47CE78
    function CreateData: TCacheDataEC; override; // @addr $47CEE4
    function AcquireData: TCacheDataEC; override; // @addr $47CF14
  end;

  TCPalBitmapEC = class(TCacheDataEC) // @size $24
  public
    Bitmap: TGraphBufPalGR; // @offset $20

    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $47CF98
    constructor Create; // @addr $47CF1C
    destructor Destroy; override; // @addr $47CF60
  end;

function AcquireOrCreatePalBitmap(Control: TCacheControlEC): TCPalBitmapEC; // @addr $47CEF4

implementation

// @unit-initialization $47CFEC
// @unit-finalization $47CFBC

uses GR_Main;

{ @routine $47CE78 TCPalBitmapControlEC_QueueLoadIfMissing }
procedure TCPalBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCPalBitmapControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCPalBitmapEC) = nil then
  begin
    Control := TCPalBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $47CE78 }

{ @routine $47CEE4 TCPalBitmapControlEC_CreateData }
function TCPalBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCPalBitmapEC.Create;
end;
{ @end $47CEE4 }

{ @routine $47CEF4 AcquireOrCreatePalBitmap }
function AcquireOrCreatePalBitmap(Control: TCacheControlEC): TCPalBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCPalBitmapEC) as TCPalBitmapEC;
end;
{ @end $47CEF4 }

{ @routine $47CF14 TCPalBitmapControlEC_AcquireData }
function TCPalBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreatePalBitmap(Self);
end;
{ @end $47CF14 }

{ @routine $47CF1C TCPalBitmapEC_Create }
constructor TCPalBitmapEC.Create;
begin
  inherited Create;
  Bitmap := TGraphBufPalGR.Create;
end;
{ @end $47CF1C }

{ @routine $47CF60 TCPalBitmapEC_Destroy }
destructor TCPalBitmapEC.Destroy;
begin
  if Bitmap <> nil then
  begin
    Bitmap.Free;
    Bitmap := nil;
  end;
  inherited Destroy;
end;
{ @end $47CF60 }

{ @routine $47CF98 TCPalBitmapEC_LoadFromConfigBuffer }
procedure TCPalBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  Bitmap.LoadImage(SourceBuffer);
  ResidentBytes := Bitmap.PitchBytes * Bitmap.Height + Bitmap.PaletteCount * 4;
end;
{ @end $47CF98 }

end.

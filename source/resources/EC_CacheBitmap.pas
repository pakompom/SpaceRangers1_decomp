unit EC_CacheBitmap;
// Unit bracket (inferred): CODE 0x00469CDC..0x00469F7F; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Cache, GR_GraphBuf;

type
  TCBitmapControlEC = class;
  TCBitmapEC = class;

  TCBitmapControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $469DB4
    function CreateData: TCacheDataEC; override; // @addr $469E20
    function AcquireData: TCacheDataEC; override; // @addr $469E50
  end;

  TCBitmapEC = class(TCacheDataEC) // @size $24
  public
    Bitmap: TGraphBufGR; // @offset $20

    constructor Create; // @addr $469E58
    destructor Destroy; override; // @addr $469E9C
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $469ED4 @note "LoadOption accepts RGBA and RGB; other values select default decoding."
  end;

function AcquireOrCreateBitmap(Control: TCacheControlEC): TCBitmapEC; // @addr $469E30

implementation

// @unit-initialization $469F78
// @unit-finalization $469F48

uses GR_Main;

{ @routine $469DB4 TCBitmapControlEC_QueueLoadIfMissing }
procedure TCBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCBitmapControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCBitmapEC) = nil then
  begin
    Control := TCBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $469DB4 }

{ @routine $469E20 TCBitmapControlEC_CreateData }
function TCBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCBitmapEC.Create;
end;
{ @end $469E20 }

{ @routine $469E30 AcquireOrCreateBitmap }
function AcquireOrCreateBitmap(Control: TCacheControlEC): TCBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCBitmapEC) as TCBitmapEC;
end;
{ @end $469E30 }

{ @routine $469E50 TCBitmapControlEC_AcquireData }
function TCBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateBitmap(Self);
end;
{ @end $469E50 }

{ @routine $469E58 TCBitmapEC_Create }
constructor TCBitmapEC.Create;
begin
  inherited Create;
  Bitmap := TGraphBufGR.Create;
end;
{ @end $469E58 }

{ @routine $469E9C TCBitmapEC_Destroy }
destructor TCBitmapEC.Destroy;
begin
  if Bitmap <> nil then
  begin
    Bitmap.Free;
    Bitmap := nil;
  end;
  inherited Destroy;
end;
{ @end $469E9C }

{ @routine $469ED4 TCBitmapEC_LoadFromConfigBuffer }
procedure TCBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
begin
  if LoadOption = 'RGBA' then Bitmap.LoadImageRgba(SourceBuffer)

  else if LoadOption = 'RGB' then Bitmap.LoadImageRgb(SourceBuffer)
  else Bitmap.LoadImage(SourceBuffer);
  ResidentBytes := Bitmap.PitchBytes * Bitmap.Height;
end;
{ @end $469ED4 }

end.

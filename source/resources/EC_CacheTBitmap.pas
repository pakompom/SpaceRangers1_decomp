unit EC_CacheTBitmap;
// Unit bracket (inferred): CODE 0x0046A998..0x0046AC8F; inclusive evidence, not full bounds.

interface

uses Types, Classes, EC_Buf, EC_Cache;

type
  TCTBitmapControlEC = class;
  TCTBitmapEC = class;

  TCTBitmapControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $46AA70
    function CreateData: TCacheDataEC; override; // @addr $46AADC
    function AcquireData: TCacheDataEC; override; // @addr $46AB0C
  end;
  TCTBitmapEC = class(TCacheDataEC) // @size $2C
  public
    TransBuffer: Pointer; // @offset $20
    PixelSize: TPoint; // @offset $24

    constructor Create; // @addr $46AB14
    destructor Destroy; override; // @addr $46AB4C
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $46AB84 @note "Applies LoadOption image operations before building the transparent buffer."
  end;

function AcquireCachedTransBitmap(Control: TCacheControlEC): TCTBitmapEC; // @addr $46AAEC

implementation

// @unit-initialization $46AC88
// @unit-finalization $46AC58

uses EC_OKGF, SysUtils, EC_Str, GR_Main, GR_GraphBuf;

{ @routine $46AA70 TCTBitmapControlEC_QueueLoadIfMissing }
procedure TCTBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCTBitmapControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCTBitmapEC) = nil then
  begin
    Control := TCTBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $46AA70 }

{ @routine $46AADC TCTBitmapControlEC_CreateData }
function TCTBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCTBitmapEC.Create;
end;
{ @end $46AADC }

{ @routine $46AAEC AcquireCachedTransBitmap }
function AcquireCachedTransBitmap(Control: TCacheControlEC): TCTBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCTBitmapEC) as TCTBitmapEC;
end;
{ @end $46AAEC }

{ @routine $46AB0C TCTBitmapControlEC_AcquireData }
function TCTBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireCachedTransBitmap(Self);
end;
{ @end $46AB0C }

{ @routine $46AB14 TCTBitmapEC_Create }
constructor TCTBitmapEC.Create;
begin
  inherited Create;
end;
{ @end $46AB14 }

{ @routine $46AB4C TCTBitmapEC_Destroy }
destructor TCTBitmapEC.Destroy;
begin
  if TransBuffer <> nil then
  begin
    FreeMem(TransBuffer);
    TransBuffer := nil;
  end;
  inherited Destroy;
end;
{ @end $46AB4C }

{ @routine $46AB84 TCTBitmapEC_LoadFromConfigBuffer }
procedure TCTBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var Bitmap: TGraphBufGR; ByteCount: Cardinal;
begin
  Bitmap := TGraphBufGR.Create;
  Bitmap.LoadImage(SourceBuffer);
  Bitmap.ApplyOperations(LoadOption);
  ByteCount := OKGR_TransBuf_Build_WORD(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil, 0);
  if ByteCount < 1 then raise Exception.Create('TCTBitmapEC.Load. Error load file.');
  GetMem(TransBuffer, ByteCount);
  OKGR_TransBuf_Build_WORD(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, TransBuffer, 0);
  ResidentBytes := ByteCount;
  PixelSize.X := Bitmap.Width;
  PixelSize.Y := Bitmap.Height;
  Bitmap.Free;
end;
{ @end $46AB84 }

end.

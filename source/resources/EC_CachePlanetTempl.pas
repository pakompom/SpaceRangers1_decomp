unit EC_CachePlanetTempl;
// Unit bracket (inferred): CODE 0x0048A398..0x0048A6F3; inclusive evidence, not full bounds.

interface

uses EC_Buf, EC_Cache, Classes;

type
  TCPlanetTemplControlEC = class;
  TCPlanetTemplEC = class;

  TCPlanetTemplControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $48A478
    function CreateData: TCacheDataEC; override; // @addr $48A4E4
    function AcquireData: TCacheDataEC; override; // @addr $48A514
  end;

  TCPlanetTemplEC = class(TCacheDataEC) // @size $24
  public
    TemplateData: Pointer; // @offset $20

    constructor Create; // @addr $48A51C
    destructor Destroy; override; // @addr $48A558
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $48A590
  end;

function AcquireOrCreatePlanetTemplate(Control: TCacheControlEC): TCPlanetTemplEC; // @addr $48A4F4

implementation

// @unit-initialization $48A6EC
// @unit-finalization $48A6BC

uses EC_OKGF, EC_CachePalBitmap, EC_Struct, GR_Main, EC_Str, GR_GraphBuf, SysUtils;

{ @routine $48A478 TCPlanetTemplControlEC_QueueLoadIfMissing }
procedure TCPlanetTemplControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCPlanetTemplControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCPlanetTemplEC) = nil then
  begin
    Control := TCPlanetTemplControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $48A478 }

{ @routine $48A4E4 TCPlanetTemplControlEC_CreateData }
function TCPlanetTemplControlEC.CreateData: TCacheDataEC;
begin
  Result := TCPlanetTemplEC.Create;
end;
{ @end $48A4E4 }

{ @routine $48A4F4 AcquireOrCreatePlanetTemplate }
function AcquireOrCreatePlanetTemplate(Control: TCacheControlEC): TCPlanetTemplEC;
begin
  Result := Control.AcquireDataFromConfig(TCPlanetTemplEC) as TCPlanetTemplEC;
end;
{ @end $48A4F4 }

{ @routine $48A514 TCPlanetTemplControlEC_AcquireData }
function TCPlanetTemplControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreatePlanetTemplate(Self);
end;
{ @end $48A514 }

{ @routine $48A51C TCPlanetTemplEC_Create }
constructor TCPlanetTemplEC.Create;
begin
  inherited Create;
  TemplateData := nil;
end;
{ @end $48A51C }

{ @routine $48A558 TCPlanetTemplEC_Destroy }
destructor TCPlanetTemplEC.Destroy;
begin
  if TemplateData <> nil then
  begin
    OKGR_Planet2_TemplDel(TemplateData);
    TemplateData := nil;
  end;
  inherited Destroy;
end;
{ @end $48A558 }

{ @routine $48A590 TCPlanetTemplEC_LoadFromConfigBuffer }
procedure TCPlanetTemplEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var Bitmap: TGraphBufGR; TextureWidth, TextureHeight: Integer;
begin
  Bitmap := TGraphBufGR.Create;
  Bitmap.LoadImageRgba(SourceBuffer);
  TextureWidth := ExtractDigitsToIntW(ExtractDelimitedPartW(LoadOption, 0, ','));
  TextureHeight := ExtractDigitsToIntW(ExtractDelimitedPartW(LoadOption, 1, ','));
  TemplateData := OKGR_Planet2_TemplBuild(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Height, TextureWidth, TextureHeight, ResidentBytes);
  if TemplateData = nil then
    raise Exception.Create('TCPlanetTemplEC.Load. Error create template planet.');
  Bitmap.Free;
end;
{ @end $48A590 }

end.

unit EC_CacheAlphaBitmap;
// Unit bracket (inferred): CODE 0x0046B670..0x0046BBCF; inclusive evidence, not full bounds.

interface

uses Types, Classes, EC_Buf, EC_Cache, GR_GraphBuf;

type
  TCAlphaBitmapControlEC = class;
  TCAlphaBitmapEC = class;

  TCAlphaBitmapControlEC = class(TCacheControlEC) // @size $18
  public
    procedure QueueLoadIfMissing(PendingLoads: TList); override; // @addr $46B750
    function CreateData: TCacheDataEC; override; // @addr $46B7BC
    function AcquireData: TCacheDataEC; override; // @addr $46B7EC
  end;

  TCAlphaBitmapEC = class(TCacheDataEC) // @size $34
  public
    TransBuf16: Pointer; // @offset $20
    TransAlphaBuf16: Pointer; // @offset $24
    AlphaBuf: Pointer; // @offset $28
    PixelSize: TPoint; // @offset $2C

    procedure Draw16(Dest: Pointer; Pitch, X, Y: Integer; Clip: TRect); // @addr $46BAE4
    constructor Create; // @addr $46B7F4
    destructor Destroy; override; // @addr $46B82C
    procedure LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString); override; // @addr $46B884
  end;

function AcquireOrCreateAlphaBitmap(Control: TCacheControlEC): TCAlphaBitmapEC; // @addr $46B7CC

implementation

// @unit-initialization $46BBC8
// @unit-finalization $46BB98

uses EC_OKGF, SysUtils, EC_Mem, GR_Main, Windows;

{ @routine $46B750 TCAlphaBitmapControlEC_QueueLoadIfMissing }
procedure TCAlphaBitmapControlEC.QueueLoadIfMissing(PendingLoads: TList);
var Control: TCAlphaBitmapControlEC;
begin
  if RetainCount > 0 then Exit;
  if BoundData <> nil then Exit;
  if HasEmptyCacheKey then Exit;
  if GlobalCache.FindDataByKeyAndClass(CacheKey, TCAlphaBitmapEC) = nil then
  begin
    Control := TCAlphaBitmapControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(CacheKey);
    PendingLoads.Add(Control);
  end;
end;
{ @end $46B750 }

{ @routine $46B7BC TCAlphaBitmapControlEC_CreateData }
function TCAlphaBitmapControlEC.CreateData: TCacheDataEC;
begin
  Result := TCAlphaBitmapEC.Create;
end;
{ @end $46B7BC }

{ @routine $46B7CC AcquireOrCreateAlphaBitmap }
function AcquireOrCreateAlphaBitmap(Control: TCacheControlEC): TCAlphaBitmapEC;
begin
  Result := Control.AcquireDataFromConfig(TCAlphaBitmapEC) as TCAlphaBitmapEC;
end;
{ @end $46B7CC }

{ @routine $46B7EC TCAlphaBitmapControlEC_AcquireData }
function TCAlphaBitmapControlEC.AcquireData: TCacheDataEC;
begin
  Result := AcquireOrCreateAlphaBitmap(Self);
end;
{ @end $46B7EC }

{ @routine $46B7F4 TCAlphaBitmapEC_Create }
constructor TCAlphaBitmapEC.Create;
begin
  inherited Create;
end;
{ @end $46B7F4 }

{ @routine $46B82C TCAlphaBitmapEC_Destroy }
destructor TCAlphaBitmapEC.Destroy;
begin
  if TransBuf16 <> nil then
  begin
    FreeEC(TransBuf16);
    TransBuf16 := nil;
  end;
  if TransAlphaBuf16 <> nil then
  begin
    FreeEC(TransAlphaBuf16);
    TransAlphaBuf16 := nil;
  end;
  if AlphaBuf <> nil then
  begin
    FreeEC(AlphaBuf);
    AlphaBuf := nil;
  end;
  inherited Destroy;
end;
{ @end $46B82C }

{ @routine $46B884 TCAlphaBitmapEC_LoadFromConfigBuffer }
procedure TCAlphaBitmapEC.LoadFromConfigBuffer(SourceBuffer: TBufEC; const LoadOption: WideString);
var Bitmap: TGraphBufGR; ByteCount: Cardinal;
begin
  Bitmap := TGraphBufGR.Create;
  Bitmap.LoadImageRgba(SourceBuffer);
  ResidentBytes := 0;
  if CurrentPixelFormat.TotalChannelBits = 16 then
  begin
  ByteCount := OKGR_TransBuf_BuildFromRGBA_16(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil);
  if ByteCount < 1 then raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransBuf16 := AllocEC(ByteCount);
  OKGR_TransBuf_BuildFromRGBA_16(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, TransBuf16);
  Inc(ResidentBytes, ByteCount);
  ByteCount := OKGR_TransAlphaBuf_BuildFromRGBA_16(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil);
  if ByteCount < 1 then raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransAlphaBuf16 := AllocEC(ByteCount);
  OKGR_TransAlphaBuf_BuildFromRGBA_16(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, TransAlphaBuf16);
  Inc(ResidentBytes, ByteCount);
  end
  else
  begin
  ByteCount := OKGR_TransBuf_BuildFromRGBA_15(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil);
  if ByteCount < 1 then raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransBuf16 := AllocEC(ByteCount);
  OKGR_TransBuf_BuildFromRGBA_15(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, TransBuf16);
  Inc(ResidentBytes, ByteCount);
  ByteCount := OKGR_TransAlphaBuf_BuildFromRGBA_15(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil);
  if ByteCount < 1 then raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  TransAlphaBuf16 := AllocEC(ByteCount);
  OKGR_TransAlphaBuf_BuildFromRGBA_15(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, TransAlphaBuf16);
  Inc(ResidentBytes, ByteCount);
  end;
  ByteCount := OKGR_AlphaBuf_BuildFromRGBA(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, nil);
  if ByteCount < 1 then raise Exception.Create('TCAlphaBitmapEC.Load. Error load file.');
  AlphaBuf := AllocEC(ByteCount);
  OKGR_AlphaBuf_BuildFromRGBA(Bitmap.Pixels, Bitmap.PitchBytes, Bitmap.Width, Bitmap.Height, AlphaBuf);
  Inc(ResidentBytes, ByteCount);
  PixelSize.X := Bitmap.Width;
  PixelSize.Y := Bitmap.Height;
  Bitmap.Free;
end;
{ @end $46B884 }

{ @routine $46BAE4 TCAlphaBitmapEC_Draw16 }
procedure TCAlphaBitmapEC.Draw16(Dest: Pointer; Pitch, X, Y: Integer; Clip: TRect);
var InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaBuf_DrawClip_16(Dest, Pitch, X, Y, AlphaBuf, InclusiveClip)
  else OKGR_AlphaBuf_DrawClip_15(Dest, Pitch, X, Y, AlphaBuf, InclusiveClip);
  OKGR_TransAlphaBuf_DrawClip_WORD(Dest, Pitch, X, Y, TransAlphaBuf16, InclusiveClip);
  OKGR_TransBuf_DrawClip_WORD(Dest, Pitch, X, Y, TransBuf16, InclusiveClip);
end;
{ @end $46BAE4 }

end.

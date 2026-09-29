unit GR_GraphBufPal;
// Unit bracket (inferred): CODE 0x004C083C..0x004C0B63; inclusive evidence, not full bounds.

interface

uses EC_OKGF, EC_Buf, EC_Struct, GR_GraphBuf;

type
  TGraphBufPalGR = class(TObjectEx) // @size $20
  public
    Width: Integer; // @offset $04
    Height: Integer; // @offset $08
    PitchBytes: Integer; // @offset $0C
    BytesPerPixel: Integer; // @offset $10
    Pixels: Pointer; // @offset $14
    PaletteCount: Integer; // @offset $18
    Palette: PColorRGBA; // @offset $1C

    constructor Create; // @addr $4C0898
    destructor Destroy; override; // @addr $4C08D0
    procedure Clear; // @addr $4C08FC
    procedure AllocateBuffer(AWidth, AHeight, APaletteCount, APitchBytes: Integer); // @addr $4C0938 @note "Discards existing pixels and palette; rounds pitch up to a multiple of four."
    procedure LoadImage(Buffer: TBufEC); // @addr $4C0A48 @note "Decodes the entire payload, ignoring Position; retains the codec's one- or two-byte indexed pixel width. Failures raise."
    procedure SetPalette(Source: PColorRGBA; Count: Integer); // @addr $4C0A00
    function GetPaletteColor(Index: Integer): TColorRGBA; // @addr $4C09D8
    function GetPixelIndex(X, Y: Integer): Byte; // @addr $4C0A38
    procedure FillPixels(Value: Byte); // @addr $4C0B18 @note "Includes row padding."
  end;

implementation

// @unit-initialization $4C0B5C
// @unit-finalization $4C0B2C

uses EC_Mem, GR_Main, SysUtils, Windows;

{ @routine $4C0898 TGraphBufPalGR_Create }
constructor TGraphBufPalGR.Create;
begin
  inherited Create;
end;
{ @end $4C0898 }

{ @routine $4C08D0 TGraphBufPalGR_Destroy }
destructor TGraphBufPalGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4C08D0 }

{ @routine $4C08FC TGraphBufPalGR_Clear }
procedure TGraphBufPalGR.Clear;
begin
  if Pixels <> nil then begin FreeEC(Pixels); Pixels := nil; end;
  Width := 0; Height := 0; PitchBytes := 0;
  if Palette <> nil then begin FreeEC(Palette); Palette := nil; end;
  PaletteCount := 0;
end;
{ @end $4C08FC }

{ @routine $4C0938 TGraphBufPalGR_AllocateBuffer }
procedure TGraphBufPalGR.AllocateBuffer(AWidth, AHeight, APaletteCount, APitchBytes: Integer);
begin
  Clear;
  Width := AWidth; Height := AHeight; PitchBytes := APitchBytes;
  if PitchBytes and 3 <> 0 then PitchBytes := PitchBytes + 4 - (PitchBytes and 3);
  PaletteCount := APaletteCount;
  Pixels := AllocEC(PitchBytes * Height);
  Palette := AllocEC(APaletteCount * SizeOf(Palette^));
  if (PitchBytes and 3 <> 0) or (Cardinal(Pixels) and 3 <> 0) then
    raise Exception.Create('TGraphBufPalGR.CreateN');
end;
{ @end $4C0938 }

{ @routine $4C09D8 TGraphBufPalGR_GetPaletteColor }
function TGraphBufPalGR.GetPaletteColor(Index: Integer): TColorRGBA;
begin
  Result := PColorRGBA(AddPointerOffset(Palette, Index * SizeOf(TColorRGBA)))^;
end;
{ @end $4C09D8 }

{ @routine $4C0A00 TGraphBufPalGR_SetPalette }
procedure TGraphBufPalGR.SetPalette(Source: PColorRGBA; Count: Integer);
begin
  if PaletteCount <> Count then
  begin
    PaletteCount := Count;
    Palette := ReAllocREC(Palette, PaletteCount * SizeOf(Palette^));
  end;
  CopyMemory(Palette, Source, Count * SizeOf(Source^));
end;
{ @end $4C0A00 }

{ @routine $4C0A38 TGraphBufPalGR_GetPixelIndex }
function TGraphBufPalGR.GetPixelIndex(X, Y: Integer): Byte;
var Data: PByteArray;
begin
  Data := Pixels;
  Result := Data^[X + Y * PitchBytes];
end;
{ @end $4C0A38 }

{ @routine $4C0A48 TGraphBufPalGR_LoadImage }
procedure TGraphBufPalGR.LoadImage(Buffer: TBufEC);
var Context: POkgfReadContext;
begin
  Clear;
  Context := OKGF_ReadStartPal_Buf(Buffer.Data, Buffer.DataSize, Width, Height, PaletteCount, BytesPerPixel);
  if Context = nil then raise Exception.Create('TGraphBufPalGR.LoadFromFile. Error load file');
  AllocateBuffer(Width, Height, PaletteCount, Width * BytesPerPixel);
  Context := Pointer(OKGF_ReadPal(Context, Pixels, PitchBytes, Palette));
  if Context = nil then raise Exception.Create('TGraphBufPalGR.LoadFromFile. Error load file');
end;
{ @end $4C0A48 }
{ @routine $4C0B18 TGraphBufPalGR_FillPixels }
procedure TGraphBufPalGR.FillPixels(Value: Byte);
begin
  FillMemory(Pixels, PitchBytes * Height, Value);
end;
{ @end $4C0B18 }

end.

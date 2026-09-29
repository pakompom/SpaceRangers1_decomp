unit GR_GraphBuf;
// Unit bracket (inferred): CODE 0x004BE6F8..0x004C083B; inclusive evidence, not full bounds.
// Software graphics buffers.

interface

uses EC_Buf, EC_Struct, Types;

type
  TPixelFormatGR = class(TObject) // @size $4C
  public
    RedMask: Cardinal; // @offset $04
    GreenMask: Cardinal; // @offset $08
    BlueMask: Cardinal; // @offset $0C
    AlphaMask: Cardinal; // @offset $10
    RedShift: Cardinal; // @offset $14
    GreenShift: Cardinal; // @offset $18
    BlueShift: Cardinal; // @offset $1C
    AlphaShift: Cardinal; // @offset $20
    RedLevels: Cardinal; // @offset $24
    GreenLevels: Cardinal; // @offset $28
    BlueLevels: Cardinal; // @offset $2C
    AlphaLevels: Cardinal; // @offset $30
    RedBits: Cardinal; // @offset $34
    GreenBits: Cardinal; // @offset $38
    BlueBits: Cardinal; // @offset $3C
    AlphaBits: Cardinal; // @offset $40
    BytesPerPixel: Integer; // @offset $44
    TotalChannelBits: Cardinal; // @offset $48

    function UnpackRed(Color: Cardinal): Byte; // @addr $4BE97C
    function UnpackGreen(Color: Cardinal): Byte; // @addr $4BE990
    function UnpackBlue(Color: Cardinal): Byte; // @addr $4BE9A4
    procedure RebuildChannelMetrics; // @addr $4BE7AC @note "Ignores disjoint bits after each mask's first contiguous run; BytesPerPixel is unchanged."
    function PackRgbBytes(Red, Green, Blue: Byte): Cardinal; // @addr $4BE8A8
    function PackNormalizedRgb(Red, Green, Blue: Double): Cardinal; // @addr $4BE90C @note "Does not clamp inputs or include alpha."
  end;

  TColorRGBA = packed record // @size $04
    R: Byte; // @offset $00
    G: Byte; // @offset $01
    B: Byte; // @offset $02
    A: Byte; // @offset $03
  end;
  PColorRGBA = ^TColorRGBA;
  TColorRGBAArray = array[0..0] of TColorRGBA;
  PColorRGBAArray = ^TColorRGBAArray;
  // Screen/texture byte order used by the brightness and grayscale routines.
  TColorBGRA = packed record // @size $04
    B: Byte; // @offset $00
    G: Byte; // @offset $01
    R: Byte; // @offset $02
    A: Byte; // @offset $03
  end;
  PColorBGRA = ^TColorBGRA;
  TPixelWordsGR = array[0..0] of Word;
  PPixelWordsGR = ^TPixelWordsGR;
  TGraphBufGR = class(TObjectEx) // @size $18
  public
    procedure ShiftBand16(X, Y, Width, Height, Shift: Integer; Clip: TRect); // @addr $4BEF48
    function GetPixel16Checked(X, Y: Integer): Cardinal; // @addr $4BF1CC
    procedure DrawAlphaLine16Clipped(X1, Y1, X2, Y2: Integer; Color: Word; Alpha: Byte; Clip: TRect); // @addr $4BF240
    function GetPixel16(X, Y: Integer): Cardinal; // @addr $4BEF10
    procedure SetPixel16(X, Y: Integer; Color: Cardinal); // @addr $4BEF28
    function GetBrightness16(X, Y: Integer): Cardinal; // @addr $4BF158
    procedure DrawHorizontalLine16(X, Y, Count: Integer; Color: Cardinal); // @addr $4BF2B4
    procedure DrawVerticalLine16(X, Y, Count: Integer; Color: Cardinal); // @addr $4BF300
    procedure DrawHorizontalLine16Clipped(X, Y, Count: Integer; Color: Cardinal; Clip: TRect); // @addr $4BF354
    procedure DrawVerticalLine16Clipped(X, Y, Count: Integer; Color: Cardinal; Clip: TRect); // @addr $4BF3C0
    procedure DrawLine32(First, Last: TPoint; Color: Cardinal); // @addr $4BF7CC
    procedure ClearPixels; // @addr $4BF810
    procedure FillPixels(Value: Byte); // @addr $4BF820
    procedure FillRect32(Rect: TRect; Color: Cardinal); // @addr $4BF850
    procedure BlendPixel16(X, Y: Integer; Color: Cardinal; Alpha: Byte); // @addr $4BF200
    procedure DrawLine16(First, Last: TPoint; Color: Cardinal); // @addr $4BF42C
    procedure DrawAnimatedLine16(First, Last: TPoint; Color: Cardinal; Phase: Integer; Clip: TRect); // @addr $4BF4AC
    procedure DrawShadowLine16(First, Last: TPoint; Color: Cardinal; Phase: Integer; Clip: TRect; ShadowPixels: Pointer; ShadowPitch: Integer); // @addr $4BF538
    procedure DrawAlphaTrapezium16(X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; Alpha: Byte; Clip: TRect); // @addr $4BF5D0
    procedure DrawLine16Clipped(First, Last: TPoint; Color: Cardinal; Clip: TRect); // @addr $4BF6CC
    procedure FillPixels16(Color: Word); // @addr $4BF834
    procedure ScaleAlpha(Rect: TRect; Alpha: Byte); // @addr $4BF8CC
    procedure RotateLeft16; // @addr $4BF960
    procedure Stretch16(Width, Height: Cardinal); // @addr $4BFAC0
    procedure ConvertRgbTo565; // @addr $4BFB2C
    procedure ShiftLight16(Shift: Integer; Rect: TRect); // @addr $4BFBAC
    procedure DrawCircleOutline16(Center: TPoint; Radius: Integer; Color: Cardinal; Clip: TRect); // @addr $4BFC54
    procedure DrawCircle16(Center: TPoint; Radius: Integer; OutlineColor, FillColor: Cardinal; Clip: TRect); // @addr $4BFCB4
    procedure DrawCircle8(Center: TPoint; Radius: Integer; OutlineColor, FillColor: Cardinal; Clip: TRect); // @addr $4BFD40
    procedure ApplyOperations(const Operations: WideString); // @addr $4BFDCC
    procedure RescaleRgb(Width, Height: Integer); // @addr $4BFF7C
    procedure RescaleRgba(Width, Height, Filter: Integer); // @addr $4C0000
    procedure RescaleBilinearRgba(Width, Height: Integer); // @addr $4C009C
    procedure FillPolygon32(Points: array of TPoint; Color: Cardinal); // @addr $4C0364
    procedure BlendRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect); // @addr $4C05D8
    Width: Integer; // @offset $04
    Height: Integer; // @offset $08
    PitchBytes: Integer; // @offset $0C
    Pixels: Pointer; // @offset $10
    // Zero owns software pixels; one borrows them.
    StorageKind: Integer; // @offset $14
    // Cleared on allocation and reset; purpose unresolved.

    constructor Create; // @addr $4BE9AC
    destructor Destroy; override; // @addr $4BE9F8
    procedure Clear; // @addr $4BEA24
    procedure AllocateNativePitch(Width, Height, PitchBytes: Integer); // @addr $4BEAE0
    procedure AttachPixels(Width, Height, PitchBytes: Integer; Data: Pointer); // @addr $4BEB14
    procedure AllocateNative(Width, Height: Integer); // @addr $4BEA58 @note "Records 16-bit pixels; software pitch uses CurrentPixelFormat.BytesPerPixel and four-byte alignment."
    procedure AllocateRgbaTight(Width, Height: Integer); // @addr $4BEB48 @note "Software storage uses Width*4 pitch; texture storage uses the returned surface pitch."
    procedure AllocateRgba(Width, Height, PitchBytes: Integer); // @addr $4BEB78
    procedure AllocateRgbTight(Width, Height: Integer); // @addr $4BEBAC
    procedure AllocateRgb(Width, Height, PitchBytes: Integer); // @addr $4BEBDC @note "Always allocates software storage, even when UseTexture is enabled."
    procedure AllocateGrayscale(Width, Height: Integer); // @addr $4BEC10 @note "Eight-bit software pixels with four-byte-aligned pitch."
    // Decode the entire file payload, ignoring Buffer.Position. Failures raise.
    procedure LoadImage(Buffer: TBufEC); // @addr $4BEC90 @note "Uses CurrentPixelFormat masks and byte width."
    procedure LoadImageRgba(Buffer: TBufEC); // @addr $4BED7C @note "Produces BGRA byte order, with alpha in the high byte."
    procedure LoadImageRgb(Buffer: TBufEC); // @addr $4BEE48 @note "Produces RGB byte order."
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $4C073C @note "Replaces Buffer with width, height, pitch and raw pixels. Leaves Position at 12, before the pixel data."
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $4C079C @note "Accepts zlib-packed or raw buffer data. Allocates software pixels and leaves Position immediately after the 12-byte image header."
  end;

implementation

// @unit-initialization $4C0834
// @unit-finalization $4C0804

uses EC_OKGF, EC_Mem, GR_Main, EC_Str, Math, SysUtils, Classes, Windows;

{ @routine $4BE7AC TPixelFormatGR_RebuildChannelMetrics }
procedure TPixelFormatGR.RebuildChannelMetrics;
var Mask: Cardinal;
begin
  RedShift := 0; RedBits := 0; RedLevels := 0;
  GreenShift := 0; GreenBits := 0; GreenLevels := 0;
  BlueShift := 0; BlueBits := 0; BlueLevels := 0;
  AlphaShift := 0; AlphaBits := 0; AlphaLevels := 0;
  if RedMask <> 0 then
  begin
    Mask := RedMask;
    while Mask and 1 = 0 do begin Inc(RedShift); Mask := Mask shr 1; end;
    while Mask and 1 <> 0 do begin Inc(RedBits); Mask := Mask shr 1; end;
    RedLevels := 1 shl RedBits;
  end;
  if GreenMask <> 0 then
  begin
    Mask := GreenMask;
    while Mask and 1 = 0 do begin Inc(GreenShift); Mask := Mask shr 1; end;
    while Mask and 1 <> 0 do begin Inc(GreenBits); Mask := Mask shr 1; end;
    GreenLevels := 1 shl GreenBits;
  end;
  if BlueMask <> 0 then
  begin
    Mask := BlueMask;
    while Mask and 1 = 0 do begin Inc(BlueShift); Mask := Mask shr 1; end;
    while Mask and 1 <> 0 do begin Inc(BlueBits); Mask := Mask shr 1; end;
    BlueLevels := 1 shl BlueBits;
  end;
  if AlphaMask <> 0 then
  begin
    Mask := AlphaMask;
    while Mask and 1 = 0 do begin Inc(AlphaShift); Mask := Mask shr 1; end;
    while Mask and 1 <> 0 do begin Inc(AlphaBits); Mask := Mask shr 1; end;
    AlphaLevels := 1 shl AlphaBits;
  end;
  TotalChannelBits := RedBits + GreenBits + BlueBits + AlphaBits;
end;
{ @end $4BE7AC }

{ @routine $4BE8A8 TPixelFormatGR_PackRgbBytes }
function TPixelFormatGR.PackRgbBytes(Red, Green, Blue: Byte): Cardinal;
begin
  Result := PackNormalizedRgb(Red / 255, Green / 255, Blue / 255);
end;
{ @end $4BE8A8 }

{ @routine $4BE90C TPixelFormatGR_PackNormalizedRgb }
function TPixelFormatGR.PackNormalizedRgb(Red, Green, Blue: Double): Cardinal;
begin
  Result := (Cardinal(Trunc(Red * (RedLevels - 1))) shl RedShift) or
    (Cardinal(Trunc(Green * (GreenLevels - 1))) shl GreenShift) or
    (Cardinal(Trunc(Blue * (BlueLevels - 1))) shl BlueShift);
end;
{ @end $4BE90C }

{ @routine $4BE97C TPixelFormatGR_UnpackRed }
function TPixelFormatGR.UnpackRed(Color: Cardinal): Byte;
begin
  if TotalChannelBits = 16 then Result := Color shr 8 else Result := Color shr 7;
end;
{ @end $4BE97C }

{ @routine $4BE990 TPixelFormatGR_UnpackGreen }
function TPixelFormatGR.UnpackGreen(Color: Cardinal): Byte;
begin
  if TotalChannelBits = 16 then Result := Color shr 3 else Result := Color shr 2;
end;
{ @end $4BE990 }

{ @routine $4BE9A4 TPixelFormatGR_UnpackBlue }
function TPixelFormatGR.UnpackBlue(Color: Cardinal): Byte;
begin
  Result := Byte(Color) shl 3;
end;
{ @end $4BE9A4 }

{ @routine $4BE9AC TGraphBufGR_Create }
constructor TGraphBufGR.Create;
begin
  inherited Create;
  Width := 0; Height := 0; PitchBytes := 0; StorageKind := 0;
end;
{ @end $4BE9AC }

{ @routine $4BE9F8 TGraphBufGR_Destroy }
destructor TGraphBufGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4BE9F8 }

{ @routine $4BEA24 TGraphBufGR_Clear }
procedure TGraphBufGR.Clear;
begin
  if (StorageKind = 0) and (Pixels <> nil) then
  begin
    FreeEC(Pixels);
    Pixels := nil;
  end;
  Width := 0; Height := 0; PitchBytes := 0; StorageKind := 0;
end;
{ @end $4BEA24 }

{ @routine $4BEA58 TGraphBufGR_AllocateNative }
procedure TGraphBufGR.AllocateNative(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := CurrentPixelFormat.BytesPerPixel * Width;
  if Self.PitchBytes and 3 <> 0 then Self.PitchBytes := Self.PitchBytes + 4 - (Self.PitchBytes and 3);
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
  if (Self.PitchBytes and 3 <> 0) or (Cardinal(Pixels) and 3 <> 0) then raise Exception.Create('TGraphBufGR.CreateN');
end;
{ @end $4BEA58 }

{ @routine $4BEAE0 TGraphBufGR_AllocateNativePitch }
procedure TGraphBufGR.AllocateNativePitch(Width, Height, PitchBytes: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := PitchBytes;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;
{ @end $4BEAE0 }

{ @routine $4BEB14 TGraphBufGR_AttachPixels }
procedure TGraphBufGR.AttachPixels(Width, Height, PitchBytes: Integer; Data: Pointer);
begin
  Clear;
  Pixels := Data; Self.Width := Width; Self.Height := Height; Self.PitchBytes := PitchBytes;
  StorageKind := 1;
end;
{ @end $4BEB14 }

{ @routine $4BEB48 TGraphBufGR_AllocateRgbaTight }
procedure TGraphBufGR.AllocateRgbaTight(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := Width * SizeOf(TColorRGBA);
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;
{ @end $4BEB48 }

{ @routine $4BEB78 TGraphBufGR_AllocateRgba }
procedure TGraphBufGR.AllocateRgba(Width, Height, PitchBytes: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := PitchBytes;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;
{ @end $4BEB78 }

{ @routine $4BEBAC TGraphBufGR_AllocateRgbTight }
procedure TGraphBufGR.AllocateRgbTight(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := Width * 3;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;
{ @end $4BEBAC }

{ @routine $4BEBDC TGraphBufGR_AllocateRgb }
procedure TGraphBufGR.AllocateRgb(Width, Height, PitchBytes: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := PitchBytes;
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
end;
{ @end $4BEBDC }

{ @routine $4BEC10 TGraphBufGR_AllocateGrayscale }
procedure TGraphBufGR.AllocateGrayscale(Width, Height: Integer);
begin
  Clear;
  Self.Width := Width; Self.Height := Height;
  Self.PitchBytes := Width;
  if Self.PitchBytes and 3 <> 0 then Self.PitchBytes := Self.PitchBytes + 4 - (Self.PitchBytes and 3);
  Pixels := AllocEC(Self.PitchBytes * Self.Height);
  if (Self.PitchBytes and 3 <> 0) or (Cardinal(Pixels) and 3 <> 0) then raise Exception.Create('TGraphBufGR.CreateBYTE');
end;
{ @end $4BEC10 }

{ @routine $4BEC90 TGraphBufGR_LoadImage }
procedure TGraphBufGR.LoadImage(Buffer: TBufEC);
var Context: POkgfReadContext;
begin
  Clear;
  Context := OKGF_ReadStart_Buf(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBuf. Error load file');
  AllocateNative(Width, Height);
  Context := Pointer(OKGF_Read(Context, Pixels, PitchBytes, CurrentPixelFormat.RedMask,
    CurrentPixelFormat.GreenMask, CurrentPixelFormat.BlueMask, CurrentPixelFormat.AlphaMask, CurrentPixelFormat.BytesPerPixel));
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBuf. Error load file');
end;
{ @end $4BEC90 }

{ @routine $4BED7C TGraphBufGR_LoadImageRgba }
procedure TGraphBufGR.LoadImageRgba(Buffer: TBufEC);
var Context: POkgfReadContext;
begin
  Clear;
  Context := OKGF_ReadStart_Buf(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBufRGBA. Error load file');
  AllocateRgbaTight(Width, Height);
  Context := Pointer(OKGF_Read(Context, Pixels, PitchBytes, $FF0000, $FF00, $FF, $FF000000, 4));
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBufRGBA. Error load file');
end;
{ @end $4BED7C }

{ @routine $4BEE48 TGraphBufGR_LoadImageRgb }
procedure TGraphBufGR.LoadImageRgb(Buffer: TBufEC);
var Context: POkgfReadContext;
begin
  Clear;
  Context := OKGF_ReadStart_Buf(Buffer.Data, Buffer.DataSize, Width, Height);
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBufRGB. Error load file');
  AllocateRgbTight(Width, Height);
  Context := Pointer(OKGF_Read(Context, Pixels, PitchBytes, $FF, $FF00, $FF0000, 0, 3));
  if Context = nil then raise Exception.Create('TGraphBufGR.LoadFromBufRGB. Error load file');
end;
{ @end $4BEE48 }

{ @routine $4BEF10 TGraphBufGR_GetPixel16 }
function TGraphBufGR.GetPixel16(X, Y: Integer): Cardinal;
var
  Data: PByteArray; Pixel: PWord;
begin
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Result := Pixel^;
end;
{ @end $4BEF10 }

{ @routine $4BEF28 TGraphBufGR_SetPixel16 }
procedure TGraphBufGR.SetPixel16(X, Y: Integer; Color: Cardinal);
var
  Data: PByteArray; Pixel: PWord;
begin
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Pixel^ := Color;
end;
{ @end $4BEF28 }

{ @routine $4BEF48 TGraphBufGR_ShiftBand16 }
procedure TGraphBufGR.ShiftBand16(X, Y, Width, Height, Shift: Integer; Clip: TRect);
var Row, DestX, Column: Integer; Color: Cardinal;
begin
  if (Y + Height - 1 < Clip.Top) or (Y >= Clip.Bottom) then Exit;
  if Y < Clip.Top then
  begin
    Height := Height + Y - Clip.Top;
    Y := Clip.Top;
  end;
  if Y + Height - 1 >= Clip.Bottom then Height := Clip.Bottom - Y;
  DestX := X + Shift;
  if Shift < 0 then
  begin
    if DestX >= Clip.Right then Exit;
    if X + Width - 1 >= Clip.Left then
      begin
        if DestX < Clip.Left then
        begin
          Width := Width + DestX - Clip.Left;
          DestX := Clip.Left;
          X := DestX - Shift;
        end;
        if X + Width - 1 >= Clip.Right then Width := Clip.Right - X;
        for Row := 0 to Height - 1 do
        begin
          Color := 0;

          for Column := 0 to Width - 1 do
          begin
            Color := GetPixel16(Column + X, Row + Y);
            SetPixel16(Column + DestX, Row + Y, Color);
          end;
          // Native leaves one pixel of the vacated span untouched.
          for Column := 0 to X - DestX - 2 do SetPixel16(DestX + Width + Column, Row + Y, Color);
        end;
      end;
  end
  else
  begin
    if X >= Clip.Right then Exit;
    if DestX + Width - 1 >= Clip.Left then
      begin
        if X < Clip.Left then
        begin
          Width := Width + X - Clip.Left;
          X := Clip.Left;
          DestX := X + Shift;
        end;
        if DestX + Width - 1 >= Clip.Right then Width := Clip.Right - DestX;
        for Row := 0 to Height - 1 do
        begin
          Color := 0;
          for Column := Width - 1 downto 0 do
          begin
            Color := GetPixel16(Column + X, Row + Y);
            SetPixel16(Column + DestX, Row + Y, Color);
          end;
          for Column := 0 to Shift - 2 do SetPixel16(Column + X, Row + Y, Color);
        end;
      end;
  end;
end;
{ @end $4BEF48 }

{ @routine $4BF158 TGraphBufGR_GetBrightness16 }
function TGraphBufGR.GetBrightness16(X, Y: Integer): Cardinal;
var
  Color: Cardinal;
  Data: PByteArray; Pixel: PWord;
begin
  Result := 0;
  if (X < 0) or (Y < 0) or (Width - 1 < X) or (Height - 1 < Y) then Exit;
  Data := Pixels;
  Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
  Color := Pixel^;
  if CurrentPixelFormat.TotalChannelBits = 16 then
    Result := (Color and 31) + ((Color shr 6) and 31) + ((Color shr 11) and 31)
  else
    Result := (Color and 31) + ((Color shr 5) and 31) + ((Color shr 10) and 31);
end;
{ @end $4BF158 }

{ @routine $4BF1CC TGraphBufGR_GetPixel16Checked }
function TGraphBufGR.GetPixel16Checked(X, Y: Integer): Cardinal;
var Data: PByteArray; Pixel: PWord;
begin
  Result := 0;
  if (X >= 0) and (Y >= 0) and (X <= Width - 1) and (Y <= Height - 1) then
  begin
    Data := Pixels;
    Pixel := @Data^[Y * PitchBytes + X * SizeOf(Word)];
    Result := Pixel^;
  end;
end;
{ @end $4BF1CC }

{ @routine $4BF200 TGraphBufGR_BlendPixel16 }
procedure TGraphBufGR.BlendPixel16(X, Y: Integer; Color: Cardinal; Alpha: Byte);
begin
  GR_Main.BlendPixel16(AddPointerOffset(Pixels, Y * PitchBytes + X * 2), Word(Color), Alpha);
end;
{ @end $4BF200 }

{ @routine $4BF240 TGraphBufGR_DrawAlphaLine16Clipped }
procedure TGraphBufGR.DrawAlphaLine16Clipped(X1, Y1, X2, Y2: Integer; Color: Word; Alpha: Byte; Clip: TRect);
begin
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGR_Line_DrawClip_Alpha_16(Pixels, PitchBytes, X1, Y1, X2, Y2, Color, Alpha, Clip)
  else OKGR_Line_DrawClip_Alpha_15(Pixels, PitchBytes, X1, Y1, X2, Y2, Color, Alpha, Clip);
end;
{ @end $4BF240 }

{ @routine $4BF2B4 TGraphBufGR_DrawHorizontalLine16 }
procedure TGraphBufGR.DrawHorizontalLine16(X, Y, Count: Integer; Color: Cardinal);
var Data: Pointer;
begin
  if Count = 0 then Exit;
  if Count < 0 then
  begin
    X := X + Count + 1;
    Count := -Count;
  end;
  X := Y * PitchBytes + X * SizeOf(Word);
  Data := Pixels;
  // Native bug: clobbers EDI without saving it.
  asm
    MOV EDI, X
    MOV ECX, Count
    ADD EDI, Data
    MOV EAX, Color
    CLD
    REP STOSW
  end;
end;
{ @end $4BF2B4 }

{ @routine $4BF300 TGraphBufGR_DrawVerticalLine16 }
procedure TGraphBufGR.DrawVerticalLine16(X, Y, Count: Integer; Color: Cardinal);
var Data: Pointer; Step: Integer;
begin
  if Count = 0 then Exit;
  if Count < 0 then
  begin
    Y := Y + Count + 1;
    Count := -Count;
  end;
  X := Y * PitchBytes + X * SizeOf(Word);
  Data := Pixels;
  Step := PitchBytes;
  // Native bug: clobbers EDI and EBX without saving them.
  asm
    MOV EDI, X
    MOV ECX, Count
    ADD EDI, Data
    MOV EAX, Color
    MOV EBX, Step
  @@Next:
    MOV [EDI], AX
    ADD EDI, EBX
    LOOP @@Next
  end;
end;
{ @end $4BF300 }

{ @routine $4BF354 TGraphBufGR_DrawHorizontalLine16Clipped }
procedure TGraphBufGR.DrawHorizontalLine16Clipped(X, Y, Count: Integer; Color: Cardinal; Clip: TRect);
begin
  if Count = 0 then Exit;
  if Count < 0 then begin X := X + Count + 1; Count := -Count; end;
  if (Y < Clip.Top) or (Y >= Clip.Bottom) or (X >= Clip.Right) or (X + Count <= Clip.Left) then Exit;
  if X < Clip.Left then begin Dec(Count, Clip.Left - X); X := Clip.Left; end;
  if X + Count > Clip.Right then Dec(Count, X + Count - Clip.Right);
  DrawHorizontalLine16(X, Y, Count, Color);
end;
{ @end $4BF354 }

{ @routine $4BF3C0 TGraphBufGR_DrawVerticalLine16Clipped }
procedure TGraphBufGR.DrawVerticalLine16Clipped(X, Y, Count: Integer; Color: Cardinal; Clip: TRect);
begin
  if Count = 0 then Exit;
  if Count < 0 then begin Y := Y + Count + 1; Count := -Count; end;
  if (X < Clip.Left) or (X >= Clip.Right) or (Y >= Clip.Bottom) or (Y + Count <= Clip.Top) then Exit;
  if Y < Clip.Top then begin Dec(Count, Clip.Top - Y); Y := Clip.Top; end;
  if Y + Count > Clip.Bottom then Dec(Count, Y + Count - Clip.Bottom);
  DrawVerticalLine16(X, Y, Count, Color);
end;
{ @end $4BF3C0 }

{ @routine $4BF42C TGraphBufGR_DrawLine16 }
procedure TGraphBufGR.DrawLine16(First, Last: TPoint; Color: Cardinal);
begin
  if First.Y = Last.Y then
  begin
    DrawHorizontalLine16(First.X, First.Y, Last.X - First.X + 1, Color);
    Exit;
  end;
  if First.X = Last.X then
  begin
    DrawVerticalLine16(First.X, First.Y, Last.Y - First.Y + 1, Color);
    Exit;
  end;
  OKGR_Line_Draw_WORD(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color);
end;
{ @end $4BF42C }

{ @routine $4BF4AC TGraphBufGR_DrawAnimatedLine16 }
procedure TGraphBufGR.DrawAnimatedLine16(First, Last: TPoint; Color: Cardinal; Phase: Integer; Clip: TRect);
begin
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGR_AnimLine_Draw_16(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color, Phase, Clip)
  else OKGR_AnimLine_Draw_15(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color, Phase, Clip);
end;
{ @end $4BF4AC }

{ @routine $4BF538 TGraphBufGR_DrawShadowLine16 }
procedure TGraphBufGR.DrawShadowLine16(First, Last: TPoint; Color: Cardinal; Phase: Integer; Clip: TRect; ShadowPixels: Pointer; ShadowPitch: Integer);
begin
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGR_AnimShadowLine_Draw_16(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color, Phase, Clip, ShadowPixels, ShadowPitch)
  else OKGR_AnimShadowLine_Draw_15(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color, Phase, Clip, ShadowPixels, ShadowPitch);
end;
{ @end $4BF538 }

{ @routine $4BF5D0 TGraphBufGR_DrawAlphaTrapezium16 }
procedure TGraphBufGR.DrawAlphaTrapezium16(X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; Alpha: Byte; Clip: TRect);
begin
  if Alpha = 64 then
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGR_Alpha64Trapezium_16(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip)
    else OKGR_Alpha64Trapezium_15(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip);
  end
  else if Alpha = 128 then
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGR_Alpha128Trapezium_16(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip)
    else OKGR_Alpha128Trapezium_15(Pixels, PitchBytes, X1, Y1, X2, Y2, X3, X4, Color, Clip);
  end;
end;
{ @end $4BF5D0 }

{ @routine $4BF6CC TGraphBufGR_DrawLine16Clipped }
procedure TGraphBufGR.DrawLine16Clipped(First, Last: TPoint; Color: Cardinal; Clip: TRect);
var InclusiveClip: TRect;
begin
  if (First.X >= Clip.Left) and (First.Y >= Clip.Top) and (First.X < Clip.Right) and (First.Y < Clip.Bottom) and
    (Last.X >= Clip.Left) and (Last.Y >= Clip.Top) and (Last.X < Clip.Right) and (Last.Y < Clip.Bottom) then
  begin
    DrawLine16(First, Last, Color);
    Exit;
  end;
  if First.Y = Last.Y then
  begin
    DrawHorizontalLine16Clipped(First.X, First.Y, Last.X - First.X + 1, Color, Clip);
    Exit;
  end;
  if First.X = Last.X then
  begin
    DrawVerticalLine16Clipped(First.X, First.Y, Last.Y - First.Y + 1, Color, Clip);
    Exit;
  end;
  InclusiveClip.Left := Clip.Left; InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1; InclusiveClip.Bottom := Clip.Bottom - 1;
  OKGR_Line_DrawClip_WORD(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color, InclusiveClip);
end;
{ @end $4BF6CC }

{ @routine $4BF7CC TGraphBufGR_DrawLine32 }
procedure TGraphBufGR.DrawLine32(First, Last: TPoint; Color: Cardinal);
begin
  OKGR_Line_Draw_DWORD(Pixels, PitchBytes, First.X, First.Y, Last.X, Last.Y, Color);
end;
{ @end $4BF7CC }

{ @routine $4BF810 TGraphBufGR_ClearPixels }
procedure TGraphBufGR.ClearPixels;
begin
  ZeroMemory(Pixels, PitchBytes * Height);
end;
{ @end $4BF810 }

{ @routine $4BF820 TGraphBufGR_FillPixels }
procedure TGraphBufGR.FillPixels(Value: Byte);
begin
  FillMemory(Pixels, PitchBytes * Height, Value);
end;
{ @end $4BF820 }

{ @routine $4BF834 TGraphBufGR_FillPixels16 }
procedure TGraphBufGR.FillPixels16(Color: Word);
begin
  OKGR_Fill_WORD(Pixels, PitchBytes, Width, Height, Color);
end;
{ @end $4BF834 }

{ @routine $4BF850 TGraphBufGR_FillRect32 }
procedure TGraphBufGR.FillRect32(Rect: TRect; Color: Cardinal);
var Data: Pointer; Rows, Columns, RowSkip: Integer;
begin
  Columns := Rect.Right - Rect.Left;
  Rows := Rect.Bottom - Rect.Top;
  RowSkip := PitchBytes - Columns * SizeOf(TColorRGBA);
  Data := Pointer(Rect.Top * PitchBytes + Rect.Left * SizeOf(TColorRGBA) + PAnsiChar(Pixels));
  // Columns and Rows must be positive; zero overruns the rectangle.
  asm
    PUSH ESI
    PUSH EDI
    PUSH EAX
    PUSH ECX
    PUSH EBX
    PUSH EDX
    MOV EAX, Color
    MOV EDI, Data
    MOV EDX, Rows
    MOV ECX, Columns
    MOV EBX, ECX
    MOV ESI, RowSkip
  @@Pixel:
    MOV [EDI], EAX
    ADD EDI, 4
    DEC ECX
    JNZ @@Pixel
    MOV ECX, EBX
    ADD EDI, ESI
    DEC EDX
    JNZ @@Pixel
    POP EDX
    POP EBX
    POP ECX
    POP EAX
    POP EDI
    POP ESI
  end;
end;
{ @end $4BF850 }

{ @routine $4BF8CC TGraphBufGR_ScaleAlpha }
procedure TGraphBufGR.ScaleAlpha(Rect: TRect; Alpha: Byte);
var Data: Pointer; Rows, Columns: Integer; Table: Pointer; RowSkip: Integer;
begin
  Columns := Rect.Right - Rect.Left; Rows := Rect.Bottom - Rect.Top;
  RowSkip := PitchBytes - Columns * SizeOf(TColorRGBA);
  Data := Pointer(Rect.Top * PitchBytes + Rect.Left * SizeOf(TColorRGBA) + 3 + PAnsiChar(Pixels));
  Table := Pointer(PAnsiChar(OKGF_MulTable256x256) + Integer(Alpha) shl 8);
  // Columns and Rows must be positive; zero overruns the rectangle.
  asm
    PUSH ESI
    PUSH EDI
    PUSH EAX
    PUSH ECX
    PUSH EBX
    PUSH EDX
    MOV EDI, Data
    MOV EDX, Rows
    MOV ECX, Columns
    MOV EBX, ECX
    MOV ESI, Table
  @@Pixel:
    XOR EAX, EAX
    MOV AL, [EDI]
    MOV AL, [ESI + EAX]
    MOV [EDI], AL
    ADD EDI, 4
    DEC ECX
    JNZ @@Pixel
    MOV ECX, EBX
    ADD EDI, RowSkip
    DEC EDX
    JNZ @@Pixel
    POP EDX
    POP EBX
    POP ECX
    POP EAX
    POP EDI
    POP ESI
  end;
end;
{ @end $4BF8CC }

{ @routine $4BF960 TGraphBufGR_RotateLeft16 }
procedure TGraphBufGR.RotateLeft16;
var X, Y: Integer; Source: Pointer; DestRows: Integer; Dest, NewPixels: Pointer; NewWidth, NewHeight, NewPitch: Integer;
begin
  if (StorageKind = 1) or (Cardinal(Width) < 1) or (Cardinal(Height) < 1) then Exit;
  NewWidth := Height; NewHeight := Width; NewPitch := NewWidth * SizeOf(Word);
  NewPixels := AllocEC(NewHeight * NewPitch);
  Source := Pixels; Y := Height; DestRows := NewHeight;
  Dest := AddPointerOffset(NewPixels, (NewHeight - 1) * NewPitch);
  while Y > 0 do
  begin
    X := Width;
    while X > 0 do
    begin
      WriteWordEC(Dest, ReadWordEC(Source));
      Dec(DestRows);
      Dest := AddPointerOffset(Dest, -NewPitch);
      if DestRows <= 0 then
      begin
        DestRows := NewHeight;
        Dest := AddPointerOffset(Dest, NewPitch * NewHeight + SizeOf(Word));
      end;
      Source := AddPointerOffset(Source, SizeOf(Word));
      Dec(X);
    end;
    Source := AddPointerOffset(Source, PitchBytes - Width * SizeOf(Word));
    Dec(Y);
  end;
  FreeEC(Pixels);
  Pixels := NewPixels; Width := NewWidth; Height := NewHeight; PitchBytes := NewPitch;
end;
{ @end $4BF960 }

{ @routine $4BFAC0 TGraphBufGR_Stretch16 }
procedure TGraphBufGR.Stretch16(Width, Height: Cardinal);
var Data: Pointer;
begin
  if (Width = Cardinal(Self.Width)) and (Height = Cardinal(Self.Height)) then Exit;
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then Exit;
  Data := AllocEC(Width * Height * SizeOf(Word));
  OKGR_StretchGdi_WORD(Data, Width, Height, Pixels, Self.Width, Self.Height);
  FreeEC(Pixels);
  Pixels := Data; Self.Width := Width; Self.Height := Height; PitchBytes := Width * SizeOf(Word);
end;
{ @end $4BFAC0 }

{ @routine $4BFB2C TGraphBufGR_ConvertRgbTo565 }
procedure TGraphBufGR.ConvertRgbTo565;
var Converted: Pointer;
begin
  if (Cardinal(Width) >= 1) and (Cardinal(Height) >= 1)
    and (Cardinal(Width) >= 1) and (Cardinal(Height) >= 1) then
  begin
    Converted := AllocEC(Width * Height * 2);
    if CurrentPixelFormat.TotalChannelBits = 16 then OKGF_ConvertRGBto565(Pixels, Converted, Width * 2, Width, Height)
    else OKGF_ConvertRGBto555(Pixels, Converted, Width * 2, Width, Height);
    FreeEC(Pixels);
    Pixels := Converted;
    PitchBytes := Width * 2;
  end;
end;
{ @end $4BFB2C }

{ @routine $4BFBAC TGraphBufGR_ShiftLight16 }
procedure TGraphBufGR.ShiftLight16(Shift: Integer; Rect: TRect);
begin
  if Pixels = nil then Exit;
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGR_ShrLight_16(AddPointerOffset(Pixels, Rect.Left * 2 + Rect.Top * PitchBytes), PitchBytes, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, Shift)
  else OKGR_ShrLight_15(AddPointerOffset(Pixels, Rect.Left * 2 + Rect.Top * PitchBytes), PitchBytes, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, Shift);
end;
{ @end $4BFBAC }

{ @routine $4BFC54 TGraphBufGR_DrawCircleOutline16 }
procedure TGraphBufGR.DrawCircleOutline16(Center: TPoint; Radius: Integer; Color: Cardinal; Clip: TRect);
var InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left;
  InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1;
  InclusiveClip.Bottom := Clip.Bottom - 1;
  OKGR_Circle_DrawClip_WORD(Pixels, PitchBytes, Center.X, Center.Y, Radius, Color, InclusiveClip);
end;
{ @end $4BFC54 }
{ @routine $4BFCB4 TGraphBufGR_DrawCircle16 }
procedure TGraphBufGR.DrawCircle16(Center: TPoint; Radius: Integer; OutlineColor, FillColor: Cardinal; Clip: TRect);
var InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left; InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1; InclusiveClip.Bottom := Clip.Bottom - 1;
  OKGR_Circle_DrawFillClip_WORD(Pixels, PitchBytes, Center.X, Center.Y, Radius, FillColor, InclusiveClip);
  if OutlineColor <> FillColor then
    OKGR_Circle_DrawClip_WORD(Pixels, PitchBytes, Center.X, Center.Y, Radius, OutlineColor, InclusiveClip);
end;
{ @end $4BFCB4 }

{ @routine $4BFD40 TGraphBufGR_DrawCircle8 }
procedure TGraphBufGR.DrawCircle8(Center: TPoint; Radius: Integer; OutlineColor, FillColor: Cardinal; Clip: TRect);
var InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left; InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1; InclusiveClip.Bottom := Clip.Bottom - 1;
  OKGR_Circle_DrawFillClip_BYTE(Pixels, PitchBytes, Center.X, Center.Y, Radius, FillColor, InclusiveClip);
  if OutlineColor <> FillColor then
    OKGR_Circle_DrawClip_BYTE(Pixels, PitchBytes, Center.X, Center.Y, Radius, OutlineColor, InclusiveClip);
end;
{ @end $4BFD40 }

{ @routine $4BFDCC TGraphBufGR_ApplyOperations }
procedure TGraphBufGR.ApplyOperations(const Operations: WideString);
var Count, i: Integer; Part, Value: WideString;
begin
  Count := CountDelimitedPartsW(Operations, '&');
  for i := 0 to Count - 1 do
  begin
    Part := ExtractDelimitedPartW(Operations, i, '&');
    if CountDelimitedPartsW(Part, '=') <= 1 then
    begin
      if Part = '270' then RotateLeft16;
    end
    else
    begin
      Value := ExtractDelimitedPartW(Part, 0, '=');
      if Value = 'Stretch' then
      begin
        Value := ExtractDelimitedPartW(Part, 1, '=');
        if CountDelimitedPartsW(Value, ',') > 1 then
          Stretch16(StrToInt(ExtractDelimitedPartW(Value, 0, ',')), StrToInt(ExtractDelimitedPartW(Value, 1, ',')));
      end;
    end;
  end;
end;
{ @end $4BFDCC }

{ @routine $4BFF7C TGraphBufGR_RescaleRgb }
procedure TGraphBufGR.RescaleRgb(Width, Height: Integer);
var Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then Exit;
  if (Cardinal(Self.Width) = Cardinal(Width)) and (Cardinal(Self.Height) = Cardinal(Height)) then Exit;
  Data := AllocEC(Width * 3 * Height);
  OKGF_Rescale(Data, Width, Height, Width * 3, Pixels, Self.Width, Self.Height, PitchBytes, 3, 5);
  if StorageKind = 0 then FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data; Self.Width := Width; Self.Height := Height; PitchBytes := Width * 3;
end;
{ @end $4BFF7C }

{ @routine $4C0000 TGraphBufGR_RescaleRgba }
procedure TGraphBufGR.RescaleRgba(Width, Height, Filter: Integer);
var Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then Exit;
  if (Cardinal(Self.Width) = Cardinal(Width)) and (Cardinal(Self.Height) = Cardinal(Height)) then Exit;
  Data := AllocEC(Width * SizeOf(TColorRGBA) * Height);
  OKGF_Rescale(Data, Width, Height, Width * SizeOf(TColorRGBA), Pixels, Self.Width, Self.Height, PitchBytes, 4, Filter);
  if StorageKind = 0 then FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data; Self.Width := Width; Self.Height := Height; PitchBytes := Width * SizeOf(TColorRGBA);
end;
{ @end $4C0000 }

{ @routine $4C009C TGraphBufGR_RescaleBilinearRgba }
procedure TGraphBufGR.RescaleBilinearRgba(Width, Height: Integer);
var
  X, Y, SourceX, YPosition, YStep, XStep, PixelX, FractionX: Integer;
  BottomWeight, TopWeight, TopLeftWeight, TopRightWeight, BottomLeftWeight, BottomRightWeight: Integer;
  TopRow, BottomRow: PColorRGBAArray;
  Dest: PColorRGBA;
  Data: Pointer;
begin
  if (Cardinal(Self.Width) < 1) or (Cardinal(Self.Height) < 1) or (Width < 1) or (Height < 1) then Exit;
  if (Self.Width = Width) and (Self.Height = Height) then Exit;
  Data := AllocEC(Width * SizeOf(TColorRGBA) * Height);
  YPosition := 0;
  XStep := ((Self.Width - 1) shl 16) div Width;
  YStep := ((Self.Height - 1) shl 16) div Height;
  Dest := Data;
  for Y := 0 to Height - 1 do
  begin
    SourceX := YPosition shr 16;
    TopRow := AddPointerOffset(Pixels, PitchBytes * SourceX);
    if Self.Height - 1 > SourceX then Inc(SourceX);
    BottomRow := AddPointerOffset(Pixels, PitchBytes * SourceX);
    SourceX := 0;
    BottomWeight := (YPosition and $FFFF) + 1;
    TopWeight := ((not YPosition) and $FFFF) + 1;
    for X := 0 to Width - 1 do
    begin
      PixelX := SourceX shr 16;
      FractionX := SourceX and $FFFF;
      TopRightWeight := (TopWeight * FractionX) shr 16;
      TopLeftWeight := TopWeight - TopRightWeight;
      BottomRightWeight := (BottomWeight * FractionX) shr 16;
      BottomLeftWeight := BottomWeight - BottomRightWeight;
      Dest.R := (TopRow^[PixelX].R * TopLeftWeight + TopRow^[PixelX + 1].R * TopRightWeight +
        BottomRow^[PixelX].R * BottomLeftWeight + BottomRow^[PixelX + 1].R * BottomRightWeight) shr 16;
      Dest.G := (TopRow^[PixelX].G * TopLeftWeight + TopRow^[PixelX + 1].G * TopRightWeight +
        BottomRow^[PixelX].G * BottomLeftWeight + BottomRow^[PixelX + 1].G * BottomRightWeight) shr 16;
      Dest.B := (TopRow^[PixelX].B * TopLeftWeight + TopRow^[PixelX + 1].B * TopRightWeight +
        BottomRow^[PixelX].B * BottomLeftWeight + BottomRow^[PixelX + 1].B * BottomRightWeight) shr 16;
      Dest.A := (TopRow^[PixelX].A * TopLeftWeight + TopRow^[PixelX + 1].A * TopRightWeight +
        BottomRow^[PixelX].A * BottomLeftWeight + BottomRow^[PixelX + 1].A * BottomRightWeight) shr 16;
      Inc(SourceX, XStep);
      Inc(Dest);
    end;
    Inc(YPosition, YStep);
  end;
  if StorageKind = 0 then FreeEC(Pixels);
  StorageKind := 0;
  Pixels := Data; Self.Width := Width; Self.Height := Height; PitchBytes := Width * SizeOf(TColorRGBA);
end;
{ @end $4C009C }

{ @routine $4C0364 TGraphBufGR_FillPolygon32 }
procedure TGraphBufGR.FillPolygon32(Points: array of TPoint; Color: Cardinal);
var
  i, Count, Y, NextY, LeftX, NextLeftX, RightX, NextRightX: Integer;
  Top, Bottom, LeftStart, RightStart, LeftEnd, RightEnd: Integer;
  Clip: TRect;
begin
  Count := Length(Points);
  if Count < 3 then Exit;
  Clip := Classes.Rect(0, 0, Width, Height);
  Top := 0; Bottom := 0;
  for i := 1 to Count - 1 do
  begin
    if Points[i].Y < Points[Top].Y then Top := i;
    if Points[i].Y > Points[Bottom].Y then Bottom := i;
  end;
  if Points[Top].Y = Points[Bottom].Y then Exit;
  LeftStart := Top; RightStart := Top; LeftEnd := Top; RightEnd := Top;
  LeftX := Points[Top].X; RightX := LeftX; Y := Points[Top].Y;
  repeat
    if Points[LeftEnd].Y = Y then
    begin
      while Points[LeftEnd].Y = Y do
      begin
        LeftStart := LeftEnd;
        Dec(LeftEnd);
        if LeftEnd < 0 then LeftEnd := Count - 1;
      end;
      if Points[Top].Y = Y then LeftX := Points[LeftStart].X;
    end;
    if Points[RightEnd].Y = Y then
    begin
      while Points[RightEnd].Y = Y do
      begin
        RightStart := RightEnd;
        Inc(RightEnd);
        if RightEnd >= Count then RightEnd := 0;
      end;
      if Points[Top].Y = Y then RightX := Points[RightStart].X;
    end;
    if Points[RightEnd].Y < Points[LeftEnd].Y then
    begin
      NextY := Points[RightEnd].Y;
      NextRightX := Points[RightEnd].X;
      NextLeftX := (Points[RightEnd].Y - Points[LeftStart].Y) *
        (Points[LeftEnd].X - Points[LeftStart].X) div (Points[LeftEnd].Y - Points[LeftStart].Y) + Points[LeftStart].X;
    end
    else
    begin
      NextY := Points[LeftEnd].Y;
      NextLeftX := Points[LeftEnd].X;
      NextRightX := (Points[RightEnd].X - Points[RightStart].X) *
        (Points[LeftEnd].Y - Points[RightStart].Y) div (Points[RightEnd].Y - Points[RightStart].Y) + Points[RightStart].X;
    end;
    // Endpoints are asymmetric: -1 and +1.
    if (LeftX < RightX) or (NextRightX > NextLeftX) then
      OKGR_FillTrapezium_DWORD(Pixels, PitchBytes, LeftX, RightX - 1, Y, NextLeftX, NextRightX + 1, NextY, Color, Clip)
    else
      OKGR_FillTrapezium_DWORD(Pixels, PitchBytes, RightX, LeftX - 1, Y, NextRightX, NextLeftX + 1, NextY, Color, Clip);
    LeftX := NextLeftX; RightX := NextRightX; Y := NextY;
  until Points[Bottom].Y = Y;
end;
{ @end $4C0364 }

{ @routine $4C05D8 TGraphBufGR_BlendRect32 }
procedure TGraphBufGR.BlendRect32(Dest: TPoint; Source: TGraphBufGR; Rect: TRect);
var Src, Dst: Pointer; Columns: Integer; Table: Pointer; SrcSkip, DstSkip, Rows: Integer;
begin
  Src := Pointer(PAnsiChar(Source.Pixels) + (Rect.Top * Source.PitchBytes + Rect.Left * SizeOf(TColorRGBA)));
  Columns := Rect.Right - Rect.Left; Rows := Rect.Bottom - Rect.Top;
  SrcSkip := Source.PitchBytes - Columns * SizeOf(TColorRGBA);
  Dst := Pointer(PAnsiChar(Pixels) + (Dest.Y * PitchBytes + Dest.X * SizeOf(TColorRGBA)));
  DstSkip := PitchBytes - Columns * SizeOf(TColorRGBA);
  Table := OKGF_MulTable256x256;
  // Columns and Rows must be positive; zero overruns the rectangle.
  asm
    PUSH EAX
    PUSH ECX
    PUSH EBX
    PUSH EDX
    PUSH ESI
    PUSH EDI
    MOV ESI, Src
    MOV EDI, Dst
    MOV EDX, Columns
  @@Pixel:
    MOV EAX, [ESI]
    MOV EBX, EAX
    SHR EBX, 24
    AND EAX, $FF
    SHL EAX, 8
    ADD EAX, EBX
    ADD EAX, Table
    MOV AL, [EAX]
    MOV ECX, [EDI]
    AND ECX, $FF
    SHL ECX, 8
    ADD ECX, $FF
    SUB ECX, EBX
    ADD ECX, Table
    MOV CL, [ECX]
    ADD EAX, ECX
    MOV [EDI], AL
    MOV EAX, [ESI]
    MOV EBX, EAX
    SHR EBX, 24
    SHR EAX, 8
    AND EAX, $FF
    SHL EAX, 8
    ADD EAX, EBX
    ADD EAX, Table
    MOV AL, [EAX]
    MOV ECX, [EDI]
    SHR ECX, 8
    AND ECX, $FF
    SHL ECX, 8
    ADD ECX, $FF
    SUB ECX, EBX
    ADD ECX, Table
    MOV CL, [ECX]
    ADD EAX, ECX
    MOV [EDI + 1], AL
    MOV EAX, [ESI]
    MOV EBX, EAX
    SHR EBX, 24
    SHR EAX, 16
    AND EAX, $FF
    SHL EAX, 8
    ADD EAX, EBX
    ADD EAX, Table
    MOV AL, [EAX]
    MOV ECX, [EDI]
    SHR ECX, 16
    AND ECX, $FF
    SHL ECX, 8
    ADD ECX, $FF
    SUB ECX, EBX
    ADD ECX, Table
    MOV CL, [ECX]
    ADD EAX, ECX
    MOV [EDI + 2], AL
    MOV AL, [ESI + 3]
    ADD AL, [EDI + 3]
    JNC @@Alpha
    MOV AL, $FF
  @@Alpha:
    MOV [EDI + 3], AL
    ADD ESI, 4
    ADD EDI, 4
    DEC EDX
    JNZ @@Pixel
    MOV EDX, Columns
    ADD ESI, SrcSkip
    ADD EDI, DstSkip
    DEC Rows
    JNZ @@Pixel
    POP EDI
    POP ESI
    POP EDX
    POP EBX
    POP ECX
    POP EAX
  end;
end;
{ @end $4C05D8 }

{ @routine $4C073C TGraphBufGR_SaveToBuffer }
procedure TGraphBufGR.SaveToBuffer(Buffer: TBufEC);
var Size: Integer;
begin
  Buffer.Clear;
  Buffer.AddDWord(Width); Buffer.AddDWord(Height); Buffer.AddDWord(PitchBytes);
  Size := PitchBytes * Height;
  Buffer.SetSize(Buffer.DataSize + Size);
  CopyMemory(AddPointerOffset(Buffer.Data, Buffer.Position), Pixels, Size);
end;
{ @end $4C073C }

{ @routine $4C079C TGraphBufGR_LoadFromBuffer }
procedure TGraphBufGR.LoadFromBuffer(Buffer: TBufEC);
var Size: Integer;
begin
  Clear;
  Buffer.ExpandZlibPayloadInPlace;
  Width := Buffer.GetUInt32; Height := Buffer.GetUInt32; PitchBytes := Buffer.GetUInt32;
  Size := PitchBytes * Height;
  Pixels := AllocEC(Size);
  CopyMemory(Pixels, AddPointerOffset(Buffer.Data, Buffer.Position), Size);
end;
{ @end $4C079C }

end.

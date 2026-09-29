unit GR_gi;
// Unit bracket (inferred): CODE 0x0046C85C..0x0046D6A3; inclusive evidence, not full bounds.

interface

uses EC_Buf, EC_Struct, GR_GraphBuf, Types;

type

  // Shared GI/GAI disk structures; ownership inferred from both readers and unit order.
  TGaiHeader = packed record // @size $30
    // +0x00..+0x07 and +0x24..+0x2F metadata remain unresolved.
    Bounds: TRect; // @offset $08
    FrameCount: Integer; // @offset $18
    Flags: Cardinal; // @offset $1C
    SequenceTableOffset: Integer; // @offset $20
  end;
  PGaiHeader = ^TGaiHeader;
  TGaiFrameEntry = packed record // @size $08
    DataOffset: Integer; // @offset $00
    DataSize: Integer; // @offset $04
  end;
  PGaiFrameEntry = ^TGaiFrameEntry;
  TGaiSequenceTableHeader = packed record // @size $08
    SequenceCount: Integer; // @offset $00
  end;
  PGaiSequenceTableHeader = ^TGaiSequenceTableHeader;
  TGaiSequenceDirectoryEntry = packed record // @size $08
    SequenceDataOffset: Integer; // @offset $00
  end;
  PGaiSequenceDirectoryEntry = ^TGaiSequenceDirectoryEntry;
  TGaiSequenceFrameEntry = packed record // @size $08
    SourceFrameIndex: Integer; // @offset $00
    FrameDelay: Integer; // @offset $04
  end;
  PGaiSequenceFrameEntry = ^TGaiSequenceFrameEntry;
  TGaiSequenceDataBlock = packed record // @size $04
    FrameCount: Integer; // @offset $00
    // Followed by FrameCount TGaiSequenceFrameEntry records.
  end;
  PGaiSequenceDataBlock = ^TGaiSequenceDataBlock;

  TgiHeaderGR = packed record // @size $40
    Magic: array[0..3] of AnsiChar; // @offset $00
    Version: Integer; // @offset $04
    Bounds: TRect; // @offset $08
    RedMask: Cardinal; // @offset $18
    GreenMask: Cardinal; // @offset $1C
    BlueMask: Cardinal; // @offset $20
    AlphaMask: Cardinal; // @offset $24
    Format: Integer; // @offset $28
    PlaneCount: Integer; // @offset $2C
    ClipRectCount: Integer; // @offset $30
    ClipRectTableOffset: Integer; // @offset $34
    // +0x38..+0x3F are not interpreted by the recovered reader/writer.
  end;
  PgiHeaderGR = ^TgiHeaderGR;
  TgiPlaneGR = packed record // @size $20
    DataOffset: Integer; // @offset $00
    DataSize: Integer; // @offset $04
    Bounds: TRect; // @offset $08
    // The last two dwords remain unresolved.
  end;
  PgiPlaneGR = ^TgiPlaneGR;
  TgiClipRectDiskGR = packed record // @size $08
    Left: Word; // @offset $00
    Top: Word; // @offset $02
    Bottom: Word; // @offset $04
    Right: Word; // @offset $06
  end;
  PgiClipRectDiskGR = ^TgiClipRectDiskGR;

  TgiGR = class(TObjectEx) // @size $14
  public
    Data: Pointer; // @offset $04
    DataSize: Integer; // @offset $08
    UsesExternalData: Boolean; // @offset $0C
    Header: PgiHeaderGR; // @offset $10

    constructor Create; // @addr $46C8B0
    destructor Destroy; override; // @addr $46C8E8
    procedure ClearData; // @addr $46C914 @note "Borrowed data is detached without freeing it."
    function IsEmpty: Boolean; // @addr $46C940
    procedure LoadRawGiBytes(BufferPtr: Pointer; ByteCount: Integer); // @addr $46C948 @note "BufferPtr is borrowed; its header and length are not validated."
    procedure LoadRawGiFromBuffer(SourceBuffer: TBufEC); // @addr $46C96C @note "Owns its copy; ignores SourceBuffer.Position."
    procedure LoadCompressedGiBytes(BufferPtr: Pointer; ByteCount: Integer); // @addr $46C9AC @note "Owns decompressed storage; empty on decompression failure."
    function GetBoundsRect: TRect; // @addr $46CA1C
    function GetContentSize: TPoint; // @addr $46CA30
    function GetFormat: Integer; // @addr $46CA4C
    function GetPlane(PlaneIndex: Integer): PgiPlaneGR; // @addr $46CA54 @note "Does not validate PlaneIndex."
    function GetClipRectCount: Integer; // @addr $46CA60
    function GetClipRect(RectIndex: Integer): TRect; // @addr $46CA68 @note "Does not validate RectIndex."
    procedure Convert565To555; // @addr $46CA98
    procedure DrawToGraphBuf(GraphBuf: TGraphBufGR; X, Y: Integer; DrawRect: TRect; BlendMode: Byte); // @addr $46CCE4
    procedure DecodeToGraphBuf(GraphBuf: TGraphBufGR); // @addr $46D0F4
    procedure BuildPalettedFormat4ColorCache; // @addr $46CC28 @note "Modifies Data even when borrowed."
  end;

procedure PrepareRawGiColorCache(Data: Pointer); // @addr $46D638

implementation

// @unit-initialization $46D69C
// @unit-finalization $46D66C

uses EC_Mem, EC_OKGF, Windows, GR_Main, EC_Str;

{ @routine $46C8B0 TgiGR_Create }
constructor TgiGR.Create;
begin
  inherited Create;
end;
{ @end $46C8B0 }

{ @routine $46C8E8 TgiGR_Destroy }
destructor TgiGR.Destroy;
begin
  ClearData;
  inherited Destroy;
end;
{ @end $46C8E8 }

{ @routine $46C914 TgiGR_ClearData }
procedure TgiGR.ClearData;
begin
  if (Data <> nil) and not UsesExternalData then FreeEC(Data);
  Data := nil; DataSize := 0; UsesExternalData := False; Header := nil;
end;
{ @end $46C914 }

{ @routine $46C940 TgiGR_IsEmpty }
function TgiGR.IsEmpty: Boolean;
begin
  Result := Header = nil;
end;
{ @end $46C940 }

{ @routine $46C948 TgiGR_LoadRawGiBytes }
procedure TgiGR.LoadRawGiBytes(BufferPtr: Pointer; ByteCount: Integer);
begin
  ClearData;
  Data := BufferPtr; DataSize := ByteCount; UsesExternalData := True; Header := Data;
end;
{ @end $46C948 }

{ @routine $46C96C TgiGR_LoadRawGiFromBuffer }
procedure TgiGR.LoadRawGiFromBuffer(SourceBuffer: TBufEC);
begin
  ClearData;
  DataSize := SourceBuffer.DataSize;
  Data := AllocEC(DataSize);
  CopyMemory(Data, SourceBuffer.Data, DataSize);
  UsesExternalData := False;
  Header := Data;
end;
{ @end $46C96C }

{ @routine $46C9AC TgiGR_LoadCompressedGiBytes }
procedure TgiGR.LoadCompressedGiBytes(BufferPtr: Pointer; ByteCount: Integer);
begin
  ClearData;
  if ByteCount < 8 then Exit;
  DataSize := OKGF_ZLib_UnCompress(nil, 0, BufferPtr, ByteCount);
  if DataSize = 0 then Exit;
  Data := AllocEC(DataSize);
  DataSize := OKGF_ZLib_UnCompress(Data, DataSize, BufferPtr, ByteCount);
  if DataSize = 0 then
  begin
    FreeEC(Data);
    Data := nil;
  end
  else
  begin
    Header := Data;
    UsesExternalData := False;
  end;
end;
{ @end $46C9AC }

{ @routine $46CA1C TgiGR_GetBoundsRect }
function TgiGR.GetBoundsRect: TRect;
begin
  Result := Header.Bounds;
end;
{ @end $46CA1C }

{ @routine $46CA30 TgiGR_GetContentSize }
function TgiGR.GetContentSize: TPoint;
begin
  Result.X := Header.Bounds.Right - Header.Bounds.Left;
  Result.Y := Header.Bounds.Bottom - Header.Bounds.Top;
end;
{ @end $46CA30 }

{ @routine $46CA4C TgiGR_GetFormat }
function TgiGR.GetFormat: Integer;
begin
  Result := Header.Format;
end;
{ @end $46CA4C }

{ @routine $46CA54 TgiGR_GetPlane }
function TgiGR.GetPlane(PlaneIndex: Integer): PgiPlaneGR;
begin
  Result := Pointer(PlaneIndex * SizeOf(TgiPlaneGR) + SizeOf(TgiHeaderGR) + PAnsiChar(Data));
end;
{ @end $46CA54 }

{ @routine $46CA60 TgiGR_GetClipRectCount }
function TgiGR.GetClipRectCount: Integer;
begin
  Result := Header.ClipRectCount;
end;
{ @end $46CA60 }

{ @routine $46CA68 TgiGR_GetClipRect }
function TgiGR.GetClipRect(RectIndex: Integer): TRect;
var Rect: PgiClipRectDiskGR;
begin
  Rect := Pointer(PAnsiChar(Data) + Header.ClipRectTableOffset + 1 + RectIndex * SizeOf(TgiClipRectDiskGR));
  Result.Left := Rect.Left; Result.Top := Rect.Top;
  Result.Right := Rect.Right; Result.Bottom := Rect.Bottom;
end;
{ @end $46CA68 }

{ @routine $46CA98 TgiGR_Convert565To555 }
procedure TgiGR.Convert565To555;
var Plane: PgiPlaneGR;
begin
  if Header.Format = 0 then
  begin
    if (Header.RedMask = $F800) and (Header.GreenMask = $7E0) and
       (Header.BlueMask = $1F) and (Header.AlphaMask = 0) then
    begin
      Plane := GetPlane(0);
      OKGF_Convert_565to555(AddPointerOffset(Data, Plane.DataOffset), (Header.Bounds.Right - Header.Bounds.Left) * 2, 0, 0,
        AddPointerOffset(Data, Plane.DataOffset), (Header.Bounds.Right - Header.Bounds.Left) * 2, 0, 0,
        Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top);
    end;
  end
  else if Header.Format = 1 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then OKGR_TransBuf_Convert565to555_WORD(AddPointerOffset(Data, Plane.DataOffset));
  end
  else if Header.Format = 2 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then OKGR_TransBuf_Convert565to555_WORD(AddPointerOffset(Data, Plane.DataOffset));
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then OKGR_TransBuf_Convert565to555_WORD(AddPointerOffset(Data, Plane.DataOffset));
  end
  else if Header.Format = 3 then
  begin
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then OKGR_AlphaIndexed_Copy16to15(AddPointerOffset(Data, Plane.DataOffset));
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then OKGR_AlphaIndexed_Alpha16to15(AddPointerOffset(Data, Plane.DataOffset));
  end;
end;
{ @end $46CA98 }

{ @routine $46CC28 TgiGR_BuildPalettedFormat4ColorCache }
procedure TgiGR.BuildPalettedFormat4ColorCache;
var Plane: PgiPlaneGR; Source, Dest: Pointer; Index, Count: Integer; Color: Cardinal;
begin
  if Header = nil then Exit;
  if CurrentPixelFormat.TotalChannelBits = 15 then Convert565To555;
  if Header.Format <> 4 then Exit;
  Plane := GetPlane(1);
  Source := AddPointerOffset(Data, Plane.DataOffset);
  Dest := Source;
  Count := Plane.DataSize div SizeOf(TColorRGBA);
  for Index := 0 to Count - 1 do
  begin
    Color := ReadDWordEC(Source);
    Color := CurrentPixelFormat.PackRgbBytes(Color and $FF, (Color shr 8) and $FF, (Color shr 16) and $FF);
    WriteWordEC(Dest, Color);
    Source := AddPointerOffset(Source, SizeOf(TColorRGBA));
    Dest := AddPointerOffset(Dest, SizeOf(Word));
  end;
end;
{ @end $46CC28 }

{ @routine $46CCE4 TgiGR_DrawToGraphBuf }
procedure TgiGR.DrawToGraphBuf(GraphBuf: TGraphBufGR; X, Y: Integer; DrawRect: TRect; BlendMode: Byte);
var Plane, PalettePlane: PgiPlaneGR; InclusiveClip: TRect;
begin
  case Header.Format of
    0:
      begin
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
          if (Header.RedMask = $FF0000) and (Header.GreenMask = $FF00) and (Header.BlueMask = $FF) and (Header.AlphaMask = $FF000000) then
            DrawAlphaBuffer16Clipped(GraphBuf.Pixels, GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PAnsiChar(Data) + Plane.DataOffset), (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(Word),
              Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, DrawRect)
          else CopyBuffer16Clipped(GraphBuf.Pixels, GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PAnsiChar(Data) + Plane.DataOffset), (Header.Bounds.Right - Header.Bounds.Left) * SizeOf(Word),
              Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, DrawRect, Boolean(BlendMode));
      end;
    1:
      begin
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
        if Plane.DataOffset <> 0 then
          DrawTransparentBuffer16(GraphBuf.Pixels, GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PAnsiChar(Data) + Plane.DataOffset), DrawRect, False);
      end;
    2:
      begin
        InclusiveClip.Left := DrawRect.Left; InclusiveClip.Top := DrawRect.Top;
        InclusiveClip.Right := DrawRect.Right - 1; InclusiveClip.Bottom := DrawRect.Bottom - 1;
        Plane := Pointer(PAnsiChar(Data) + (SizeOf(TgiHeaderGR) + 2 * SizeOf(TgiPlaneGR)));
        if Plane.DataOffset <> 0 then
          begin
            if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaBuf_DrawClip_16(GraphBuf.Pixels, GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip)
            else OKGR_AlphaBuf_DrawClip_15(GraphBuf.Pixels, GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip);
          end;
        Plane := Pointer(PAnsiChar(Data) + (SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR)));
        if Plane.DataOffset <> 0 then
          OKGR_TransAlphaBuf_DrawClip_WORD(GraphBuf.Pixels, GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip);
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
        if Plane.DataOffset <> 0 then
          OKGR_TransBuf_DrawClip_WORD(GraphBuf.Pixels, GraphBuf.PitchBytes,
            X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
            Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip);
      end;
    3:
      begin
        InclusiveClip.Left := DrawRect.Left; InclusiveClip.Top := DrawRect.Top;
        InclusiveClip.Right := DrawRect.Right - 1; InclusiveClip.Bottom := DrawRect.Bottom - 1;
          Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
          if Plane.DataOffset <> 0 then
            OKGR_AlphaIndexed_CopyDrawClip_WORD(GraphBuf.Pixels, GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip);
          Plane := Pointer(PAnsiChar(Data) + (SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR)));
          if Plane.DataOffset <> 0 then
            begin
            if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaIndexed_AlphaDrawClip_16(GraphBuf.Pixels, GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip)
            else OKGR_AlphaIndexed_AlphaDrawClip_15(GraphBuf.Pixels, GraphBuf.PitchBytes,
              X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
              Pointer(PAnsiChar(Data) + Plane.DataOffset), InclusiveClip);
          end;
      end;
    4:
      begin
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
        PalettePlane := Pointer(PAnsiChar(Data) + (SizeOf(TgiHeaderGR) + SizeOf(TgiPlaneGR)));
        CopyPalettedBuffer16Clipped(GraphBuf.Pixels, GraphBuf.PitchBytes,
          X + Plane.Bounds.Left - Header.Bounds.Left, Y + Plane.Bounds.Top - Header.Bounds.Top,
          Pointer(PAnsiChar(Data) + Plane.DataOffset), Pointer(PalettePlane.DataOffset + PAnsiChar(Data)),
          Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Right - Header.Bounds.Left,
          Header.Bounds.Bottom - Header.Bounds.Top, DrawRect);
      end;
    5:
      begin
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
        OKGR_F5_DrawRGBA(Pointer(PAnsiChar(GraphBuf.Pixels) + (X * SizeOf(TColorRGBA) + GraphBuf.PitchBytes * Y)), GraphBuf.PitchBytes, Pointer(PAnsiChar(Data) + Plane.DataOffset));
      end;
    6:
      begin
        Plane := Pointer(PAnsiChar(Data) + SizeOf(TgiHeaderGR));
        OKGR_F6_DrawRGBA(Pointer(PAnsiChar(GraphBuf.Pixels) + (X * SizeOf(TColorRGBA) + GraphBuf.PitchBytes * Y)), GraphBuf.PitchBytes, Pointer(PAnsiChar(Data) + Plane.DataOffset));
      end;
  end;
end;
{ @end $46CCE4 }

{ @routine $46D0F4 TgiGR_DecodeToGraphBuf }
procedure TgiGR.DecodeToGraphBuf(GraphBuf: TGraphBufGR);
var Plane: PgiPlaneGR; TempPixels: Pointer;
begin
  // Formats 1..3 decode through a temporary packed color-plus-alpha buffer.
  // Format 0 is always 16-bit color; formats 4..6 do nothing.
  if Header.Format = 0 then
  begin
    GraphBuf.AllocateRgba(Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, (Header.Bounds.Right - Header.Bounds.Left) * 4);
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      if CurrentPixelFormat.TotalChannelBits = 16 then
        OKGF_Convert565toBGRA(AddPointerOffset(Data, Plane.DataOffset), GraphBuf.Width * 2, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height)
      else OKGF_Convert555toBGRA(AddPointerOffset(Data, Plane.DataOffset), GraphBuf.Width * 2, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height);
  end
  else if Header.Format = 1 then
  begin
    GraphBuf.AllocateRgba(Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, (Header.Bounds.Right - Header.Bounds.Left) * 4);
    TempPixels := AllocClearEC(GraphBuf.Width * GraphBuf.Height * 3);
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      OKGR_TransBuf_Draw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGF_Convert5658toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height)
    else OKGF_Convert5558toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height);
    FreeEC(TempPixels);
  end
  else if Header.Format = 2 then
  begin
    GraphBuf.AllocateRgba(Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, (Header.Bounds.Right - Header.Bounds.Left) * 4);
    TempPixels := AllocClearEC(GraphBuf.Width * GraphBuf.Height * 3);
    Plane := GetPlane(2);
    if Plane.DataOffset <> 0 then
      OKGR_AlphaBuf_Draw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_TransAlphaBuf_Draw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset))
      else OKGR_TransAlphaBuf_Draw_5558(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      OKGR_TransBuf_Draw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGF_Convert5658toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height)
    else OKGF_Convert5558toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height);
    FreeEC(TempPixels);
  end
  else if Header.Format = 3 then
  begin
    GraphBuf.AllocateRgba(Header.Bounds.Right - Header.Bounds.Left, Header.Bounds.Bottom - Header.Bounds.Top, (Header.Bounds.Right - Header.Bounds.Left) * 4);
    TempPixels := AllocClearEC(GraphBuf.Width * GraphBuf.Height * 3);
    Plane := GetPlane(0);
    if Plane.DataOffset <> 0 then
      OKGR_AlphaIndexed_CopyDraw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    Plane := GetPlane(1);
    if Plane.DataOffset <> 0 then
      if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaIndexed_AlphaDraw_5658(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset))
      else OKGR_AlphaIndexed_AlphaDraw_5558(AddPointerOffset(TempPixels, (Plane.Bounds.Left - Header.Bounds.Left) * 3 + (Plane.Bounds.Top - Header.Bounds.Top) * GraphBuf.Width * 3), GraphBuf.Width * 3, AddPointerOffset(Data, Plane.DataOffset));
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGF_Convert5658toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height)
    else OKGF_Convert5558toBGRA(TempPixels, GraphBuf.Width * 3, GraphBuf.Pixels, GraphBuf.PitchBytes, GraphBuf.Width, GraphBuf.Height);
    FreeEC(TempPixels);
  end
  else if Header.Format = 4 then
  begin
  end;
end;
{ @end $46D0F4 }

{ @routine $46D638 PrepareRawGiColorCache }
procedure PrepareRawGiColorCache(Data: Pointer);
var Image: TgiGR;
begin
  Image := TgiGR.Create;
  Image.LoadRawGiBytes(Data, 1);
  Image.BuildPalettedFormat4ColorCache;
  Image.Free;
end;
{ @end $46D638 }

end.

unit GI_XviD;
// Unit bracket (inferred): CODE 0x004A5C30..0x004A68F3; inclusive evidence, not full bounds.
// Buffered Xvid stream playback with DirectDraw overlay and RGBA fallback.
interface

uses GI_MessageLoop, EC_BlockPar, EC_File, EC_Buf, GR_GraphBuf, GR_DirectX;

type
  TXvidEntry = function(Handle: Pointer; Operation: Integer; Param1, Param2: Pointer): Integer; cdecl;
  TXvidInit = record // @size $0C
    Version: Integer; // @offset $00
    CpuFlags: Cardinal; // @offset $04
    Debug: Integer; // @offset $08
  end;
  TXvidCreate = record // @size $10
    Version: Integer; // @offset $00
    Width: Integer; // @offset $04
    Height: Integer; // @offset $08
    Handle: Pointer; // @offset $0C
  end;
  TXvidFrame = record // @size $34
    Version: Integer; // @offset $00
    General: Integer; // @offset $04
    Bitstream: Pointer; // @offset $08
    Length: Integer; // @offset $0C
    ColorSpace: Integer; // @offset $10
    Planes: array[0..3] of Pointer; // @offset $14
    Strides: array[0..3] of Integer; // @offset $24
  end;
  TXvidStats = record // @size $20
    Version: Integer; // @offset $00
    FrameType: Integer; // @offset $04
    General: Cardinal; // @offset $08
    Width: Integer; // @offset $0C
    Height: Integer; // @offset $10
    Unread: array[0..2] of Cardinal; // @offset $14
  end;
  TxvidGI = class(TObjectGI) // @size $2B4
  public
    FileObject: TFileEC; // @offset $100
    CompressedFrame: TBufEC; // @offset $104
    Bitstream: Pointer; // @offset $108
    BufferedBytes: Integer; // @offset $10C
    Image: TGraphBufGR; // @offset $110
    Decoder: Pointer; // @offset $114
    DecodedFrameCount: Integer; // @offset $118
    RequestedFrameCount: Integer; // @offset $11C
    Resampler: Pointer; // @offset $120
    CompleteCallback: TObjectNotifyEventGI; // @offset $128
    DriverCaps: TDDCaps; // @offset $130
    ColorSpace: Integer; // @offset $2AC
    OverlayNeedsPresent: Boolean; // @offset $2B0

    constructor Create(Owner: TObjectGI); // @addr $4A5D54
    destructor Destroy; override; // @addr $4A5D8C
    procedure Clear; override; // @addr $4A5DB8
    procedure ImageOpen(const FileName: WideString); // @addr $4A5DCC
    procedure ImageClose; // @addr $4A600C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A60C4
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A60F0
    procedure LoadVideoProperties(Block: TBlockParEC); // @addr $4A610C
    function DecodeNextFrame: Boolean; // @addr $4A6110 @note "Refills the compressed stream and handles decoder-reported dimensions. Unhandled overlay-lock errors still enter the decode path."
    function InitializeOverlay(Width, Height: Integer): Boolean; // @addr $4A6624
    procedure ReleaseOverlay; // @addr $4A6828
    procedure SetFramePosition(Frame: Integer); // @addr $4A686C @note "Forward only; Frame is the requested count of decoded samples."
  end;

function PackFourCC(A, B, C, D: Byte): Cardinal; // @addr $4A65F8

var
  XvidLibrary: Cardinal = 0; // @addr $617F20
  XvidGlobal: TXvidEntry = nil; // @addr $617F24
  XvidDecode: TXvidEntry = nil; // @addr $617F28

function Resample_Init(Filter: Integer; DestWidth, DestHeight, SourceWidth, SourceHeight: Double): Pointer; cdecl; external 'okgf.dll' name 'Resample_Init'; // @addr $4A5D3C
procedure Resample_Deinit(Context: Pointer); cdecl; external 'okgf.dll' name 'Resample_Deinit'; // @addr $4A5D44
procedure Resample_Process(Context, Source: Pointer; SourcePitch, SourceWidth, SourceHeight: Integer; Dest: Pointer; DestPitch, DestWidth, DestHeight: Integer); cdecl; external 'okgf.dll' name 'Resample_Process'; // @addr $4A5D4C

implementation

uses Windows, Types, Math, EC_Str, GR_Main;

// @unit-initialization $4A68EC
// @unit-finalization $4A68BC

const
  XvidVersion = $00010084;
  XvidCspBgra = $100;
  XvidCspYuy2 = $08;
  XvidCspUyvy = $10;

type
  // Surface 7's descriptor extends the common prefix used by the dispatch ABI.
  TDDSurfaceDesc2 = record
    Prefix: TDDSurfaceDesc;
    ExtraCaps: array[0..2] of Cardinal;
    TextureStage: Cardinal;
  end;

{ @routine $4A5D54 TxvidGI_Create }
constructor TxvidGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;
{ @end $4A5D54 }

{ @routine $4A5D8C TxvidGI_Destroy }
destructor TxvidGI.Destroy;
begin
  ImageClose;
  inherited Destroy;
end;
{ @end $4A5D8C }

{ @routine $4A5DB8 TxvidGI_Clear }
procedure TxvidGI.Clear;
begin
  ImageClose;
  inherited Clear;
end;
{ @end $4A5DB8 }

{ @routine $4A5DCC TxvidGI_ImageOpen }
procedure TxvidGI.ImageOpen(const FileName: WideString);
var Init: TXvidInit; CreateParams: TXvidCreate;
begin
  ImageClose;
  ColorSpace := XvidCspBgra;
  if XvidLibrary = 0 then
  begin
    XvidLibrary := LoadLibrary('xvidcore.dll');
    if XvidLibrary = 0 then RaiseWideMessage('');
    XvidGlobal := GetProcAddress(XvidLibrary, 'xvid_global');
    if @XvidGlobal = nil then RaiseWideMessage('');
    XvidDecode := GetProcAddress(XvidLibrary, 'xvid_decore');
    if @XvidDecode = nil then RaiseWideMessage('');
  end;
  ZeroMemory(@Init, SizeOf(Init));
  Init.Version := XvidVersion;
  Init.CpuFlags := 0;
  XvidGlobal(nil, 0, @Init, nil);
  ZeroMemory(@CreateParams, SizeOf(CreateParams));
  CreateParams.Version := XvidVersion;
  CreateParams.Width := 0;
  CreateParams.Height := 0;
  if XvidDecode(nil, 0, @CreateParams, nil) <> 0 then RaiseWideMessage('');
  Decoder := CreateParams.Handle;
  FileObject := TFileEC.Create;
  CompressedFrame := TBufEC.Create;
  CompressedFrame.SetSize($180000);
  FileObject.SetFileName(AnsiString(FileName));
  FileObject.AcquireReadWriteHandle;
  BufferedBytes := Min(CompressedFrame.DataSize, FileObject.GetSize);
  FileObject.ReadBuffer(CompressedFrame.Data, Min(CompressedFrame.DataSize, FileObject.GetSize));
  Bitstream := CompressedFrame.Data;
  Image := TGraphBufGR.Create;
  DecodedFrameCount := 0;
  SetFramePosition(1);
end;
{ @end $4A5DCC }

{ @routine $4A600C TxvidGI_ImageClose }
procedure TxvidGI.ImageClose;
var Status: Integer;
begin
  ReleaseOverlay;
  if Resampler <> nil then begin Resample_Deinit(Resampler); Resampler := nil; end;
  if Decoder <> nil then
  begin
    Status := XvidDecode(Decoder, 1, nil, nil);
    Decoder := nil;
    if Status <> 0 then RaiseWideMessage('');
  end;
  if FileObject <> nil then begin FileObject.Free; FileObject := nil; end;
  if CompressedFrame <> nil then begin CompressedFrame.Free; CompressedFrame := nil; end;
  if Image <> nil then begin Image.Free; Image := nil; end;
  if PresentationOverrideBuffer <> nil then
  begin
    PresentationOverrideBuffer.Free;
    PresentationOverrideBuffer := nil;
  end;
end;
{ @end $4A600C }

{ @routine $4A60C4 TxvidGI_LoadFromConfigPath }
procedure TxvidGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadVideoProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4A60C4 }

{ @routine $4A60F0 TxvidGI_LoadFromBlock }
procedure TxvidGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadVideoProperties(Block);
end;
{ @end $4A60F0 }

{ @routine $4A610C TxvidGI_LoadVideoProperties }
procedure TxvidGI.LoadVideoProperties(Block: TBlockParEC);
begin
end;
{ @end $4A610C }

{ @routine $4A6110 TxvidGI_DecodeNextFrame }
function TxvidGI.DecodeNextFrame: Boolean;
var Frame: TXvidFrame; Stats: TXvidStats; Surface: TDDSurfaceDesc2;
    Remaining, FileBytes, Count: Integer; LockFlags: Cardinal; Status: Integer;
begin
  Result := True;
  if Cardinal(Bitstream) > Cardinal(CompressedFrame.Data) + (Cardinal(CompressedFrame.DataSize) shr 1) then
  begin
    Remaining := Integer(CompressedFrame.Data) + CompressedFrame.DataSize - Integer(Bitstream);
    if Remaining > 0 then CopyMemory(CompressedFrame.Data, Bitstream, Remaining);
    Bitstream := CompressedFrame.Data;
    FileBytes := FileObject.GetSize - FileObject.GetPointer;
    if FileBytes > 0 then
    begin
      Inc(BufferedBytes, Min(FileBytes, CompressedFrame.DataSize - Remaining));
      FileObject.ReadBuffer(PAnsiChar(CompressedFrame.Data) + Remaining,
        Min(FileBytes, CompressedFrame.DataSize - Remaining));
    end;
  end;
  repeat
    ZeroMemory(@Stats, SizeOf(Stats));
    Stats.Version := XvidVersion;
    ZeroMemory(@Frame, SizeOf(Frame));
    Frame.Version := XvidVersion;
    Frame.General := 1;
    Frame.Bitstream := Bitstream;
    Frame.Length := BufferedBytes;
    Frame.ColorSpace := ColorSpace;
    if (PresentationOverrideBuffer = nil) and (VideoOverlaySurface = nil) then
    begin
      Frame.Planes[0] := nil;
      Frame.Strides[0] := 0;
      Count := XvidDecode(Decoder, 2, @Frame, @Stats);
    end
    else if VideoOverlaySurface <> nil then
    begin
      ZeroMemory(@Surface, SizeOf(Surface));
      Surface.Prefix.Size := SizeOf(Surface);
      if GetVersion and $80000000 <> 0 then LockFlags := $821 else LockFlags := $21;
      while True do
      begin
        Status := VideoOverlaySurface.Lock(nil, Surface.Prefix, LockFlags, 0);
        if Status = 0 then Break;
        if Cardinal(Status) = $887601C2 then RaiseWideMessage('Overlay.Lock')
        else if Cardinal(Status) <> $8876021C then Break;
        SysUtils.Sleep(10);
      end;
      Frame.Planes[0] := Surface.Prefix.Surface;
      Frame.Strides[0] := Surface.Prefix.Pitch;
      Count := XvidDecode(Decoder, 2, @Frame, @Stats);
      VideoOverlaySurface.Unlock(nil);
      if OverlayNeedsPresent then
      begin
        OverlayNeedsPresent := False;
        PresentVideoOverlay;
      end;
    end
    else
    begin
      Frame.Planes[0] := Image.Pixels;
      Frame.Strides[0] := Image.PitchBytes;
      Count := XvidDecode(Decoder, 2, @Frame, @Stats);
      Resample_Process(Resampler, Image.Pixels, Image.PitchBytes, Image.Width, Image.Height,
        PresentationOverrideBuffer.Pixels, PresentationOverrideBuffer.PitchBytes,
        PresentationOverrideBuffer.Width, PresentationOverrideBuffer.Height);
    end;
    if Count > 0 then
    begin
      Bitstream := Pointer(Cardinal(Bitstream) + Cardinal(Count));
      Dec(BufferedBytes, Count);
    end;
    if (Stats.FrameType = -1) and (VideoOverlaySurface = nil) then
      if (PresentationOverrideBuffer = nil) or (Image.Width <> Stats.Width) or (Image.Height <> Stats.Height) then
        if not InitializeOverlay(Stats.Width, Stats.Height) then
        begin
          AppendLogLineThreadSafe('InitOverlay=fail');
          ColorSpace := XvidCspBgra;
          Image.AllocateRgbaTight(Stats.Width, Stats.Height);
          if PresentationOverrideBuffer <> nil then PresentationOverrideBuffer.Free;
          PresentationOverrideBuffer := TGraphBufGR.Create;
          PresentationOverrideBuffer.AllocateRgbaTight(GameScreenWidth,
            Round(Cardinal(GameScreenWidth) * (Stats.Height / Stats.Width)));
          if Resampler <> nil then begin Resample_Deinit(Resampler); Resampler := nil; end;
          Resampler := Resample_Init(1, Cardinal(PresentationOverrideBuffer.Width),
            Cardinal(PresentationOverrideBuffer.Height), Cardinal(Image.Width), Cardinal(Image.Height));
        end;
  until (Stats.FrameType > 0) or (BufferedBytes <= 0);
  if BufferedBytes < 0 then Result := False
  else
  begin
    Inc(DecodedFrameCount);
    ForcePresentationOverride := True;
  end;
end;
{ @end $4A6110 }

{ @routine $4A65F8 PackFourCC }
function PackFourCC(A, B, C, D: Byte): Cardinal;
begin
  Result := Cardinal(A) or (Cardinal(B) shl 8) or (Cardinal(C) shl 16) or (Cardinal(D) shl 24);
end;
{ @end $4A65F8 }

{ @routine $4A6624 TxvidGI_InitializeOverlay }
function TxvidGI.InitializeOverlay(Width, Height: Integer): Boolean;
var Surface: IDirectDrawSurface; Desc: TDDSurfaceDesc; I, Status: Integer;
begin
  Result := False;
  ReleaseOverlay;
  if PrimarySurface.QueryInterface(IID_IDirectDrawSurface7, VideoPrimarySurface) = 0 then
  begin
    ZeroMemory(@DriverCaps, SizeOf(DriverCaps));
    DriverCaps.Size := SizeOf(DriverCaps);
    if DirectDrawDevice.GetCaps(DriverCaps, nil) = 0 then
    begin
      for I := 0 to 1 do
      begin
        ZeroMemory(@Desc, SizeOf(Desc));
        Desc.Size := SizeOf(Desc);
        Desc.Flags := $1007;
        Desc.Width := Width;
        Desc.Height := Height;
        Desc.Caps := $4080;
        Desc.PixelFormat.Size := SizeOf(Desc.PixelFormat);
        Desc.PixelFormat.Flags := 4;
        if I = 1 then
        begin
          Desc.PixelFormat.FourCC := PackFourCC($55, $59, $56, $59);
          ColorSpace := XvidCspUyvy;
        end
        else
        begin
          Desc.PixelFormat.FourCC := PackFourCC($59, $55, $59, $32);
          ColorSpace := XvidCspYuy2;
        end;
        if DriverCaps.Caps and $10 <> 0 then
        begin
          Desc.Width := Desc.Width + DriverCaps.AlignSizeSrc - 1;
          Desc.Width := Desc.Width - Desc.Width mod DriverCaps.AlignSizeSrc;
        end;
        Status := DirectDrawDevice.CreateSurface(Desc, Surface, nil);
        if Status = 0 then Break;
      end;
      if Status = 0 then
      begin
        Status := Surface.QueryInterface(IID_IDirectDrawSurface7, VideoOverlaySurface);
        Surface := nil;
        if Status = 0 then
        begin
          ZeroMemory(@VideoOverlayFX, SizeOf(VideoOverlayFX));
          VideoOverlayFX.Size := SizeOf(VideoOverlayFX);
          VideoOverlayFlags := $84000;
          if DriverCaps.FXCaps and $40000 <> 0 then
            VideoOverlayFX.Flags := VideoOverlayFX.Flags or 1;
          VideoOverlayWidth := Width;
          VideoOverlayHeight := Height;
          ClearPresentationScreen;
          OverlayNeedsPresent := True;
          Result := True;
        end;
      end;
    end;
  end;
end;
{ @end $4A6624 }

{ @routine $4A6828 TxvidGI_ReleaseOverlay }
procedure TxvidGI.ReleaseOverlay;
begin
  if VideoOverlaySurface <> nil then
    VideoOverlaySurface.UpdateOverlay(nil, VideoPrimarySurface, nil, $200, nil);
  VideoOverlaySurface := nil;
  VideoPrimarySurface := nil;
end;
{ @end $4A6828 }

{ @routine $4A686C TxvidGI_SetFramePosition }
procedure TxvidGI.SetFramePosition(Frame: Integer);
begin
  if Decoder <> nil then
  begin
    RequestedFrameCount := Frame;
    while RequestedFrameCount > DecodedFrameCount do
      if not DecodeNextFrame then
      begin
        ImageClose;
        if Assigned(CompleteCallback) then CompleteCallback(Self);
        Exit;
      end;
  end;
end;
{ @end $4A686C }

end.

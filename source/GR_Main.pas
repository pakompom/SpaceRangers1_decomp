unit GR_Main;
// Unit bracket (inferred): CODE 0x004B05AC..0x004B84E7; inclusive evidence, not full bounds.
// Native graphics globals used by recovered drawing helpers.
interface
uses EC_OKGF, GR_GraphBufPal, Types, EC_Str, EC_Cache, GR_Sound, EC_BlockPar, GR_GraphBuf, GR_Music, GR_Demo, Classes, SyncObjs, EC_Data, GR_DirectX;
type
  PMoneyIntegrityFlag = ^Boolean;
  TCursorUnit = class(TObject) // @size $1C
  public
    Prev: TCursorUnit; // @offset $04
    Next: TCursorUnit; // @offset $08
    Name: WideString; // @offset $0C
    ImagePath: WideString; // @offset $10
    HotSpot: TPoint; // @offset $14
  end;
  TWindowMessageCallbackGR = procedure(Message, WParam: Cardinal; LParam: Integer) of object;
  TDebugKeyCallbackGR = procedure(Key: Word);
  TTriangleRasterizer16 = procedure(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal; X3, Y3: Integer; Color3: Cardinal; Clip: POkgfRect); cdecl;
  TBlendPixel16 = procedure(Pixel: Pointer; Color: Word; Alpha: Byte); cdecl;
  TLineRasterizer16 = procedure(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal); cdecl;
const
  MainWindowClassName = 'Rangers MainClassName';
  MainWindowTitle = 'Rangers';

var
  DirectDrawDevice: IDirectDraw = nil; // @addr $617F2C
  DirectDraw7Device: IDirectDraw7 = nil; // @addr $617F30
  PrimarySurface: IDirectDrawSurface = nil; // @addr $617F34
  VideoPrimarySurface: IDirectDrawSurface = nil; // @addr $617F38 Destination used by the video overlay; creation path not yet recovered.
  WindowClipper: IDirectDrawClipper = nil; // @addr $617F3C
  GammaControl: IDirectDrawGammaControl = nil; // @addr $617F40
  ExitScreenLoop: Boolean = False; // @addr $617F44
  FullFrameRedrawRequested: Boolean = True; // @addr $617F48
  Brightness: Single = 0.0; // @addr $617F4C
  Contrast: Single = 0.0; // @addr $617F50
  PresentationOverrideBuffer: TGraphBufGR = nil; // @addr $617F54 Displayed instead of the normal UI; format is 32-bit RGBA.
  ForcePresentationOverride: Boolean = False; // @addr $617F58 Bypasses the 100 ms redraw limit.
  LastPresentationOverrideTick: Cardinal = 0; // @addr $617F5C
  VideoOverlaySurface: IDirectDrawSurface = nil; // @addr $617F60 Non-nil suppresses queued UI presentation.
  Direct3D8Library: Cardinal = 0; // @addr $617F64
  Direct3D8: IDirect3D8 = nil; // @addr $617F68
  Direct3D8Device: IDirect3DDevice8 = nil; // @addr $617F6C
  ReturnToMainAfterDemo: Boolean = True; // @addr $617F70
  InterfaceBlendPalette: Pointer = nil; // @addr $617F74
  PreferredRefreshRate: Integer = 0; // @addr $617F78 Minus one selects the highest enumerated refresh rate.
  HighestRefreshRate: Integer = 0; // @addr $617F7C
  DebugSelectedShipId: Cardinal = 0; // @addr $617F80 Selected by the GBpShip debug command.
  ShipDatabaseLoggingEnabled: Boolean = False; // @addr $617F84 Enables the turn worker's #ship.dbf append.
  QuestDisplayNames: TBlockParEC = nil; // @addr $617F88 Loaded by native $4B0E28; quest picker resolves display filenames through it.
  CacheLoadLoggingEnabled: Boolean = False; // @addr $617F8C
  SoundManager: TSoundControl = nil; // @addr $617F90
  MusicManager: TMusicControl = nil; // @addr $617F94
  ShowFPS: Boolean = False; // @addr $617F98
  RecordingFrames: Boolean = False; // @addr $617F9C
  RecordingFrameCount: Integer = 0; // @addr $617FA0
  RecordingFrameBuffers: TList = nil; // @addr $617FA4
  RecordingFrameInterval: Cardinal = 50; // @addr $617FA8
  DemoRecording: Boolean = False; // @addr $617FAC
  DemoPlaying: Boolean = False; // @addr $617FB0
  FirstRegisteredCursor: TCursorUnit = nil; // @addr $617FB4
  LastRegisteredCursor: TCursorUnit = nil; // @addr $617FB8
  BuildVersionMismatch: Boolean = False; // @addr $617FBC Also set by the optional executable CRC check; never reset by this loader.
  SessionLogLock: TCriticalSection = nil; // @addr $617FC0
  DebugKeyCallback: TDebugKeyCallbackGR = nil; // @addr $617FC4
  PendingMoneyIntegrityFailure: PMoneyIntegrityFlag = nil; // @addr $617FC8 Heap flag moved and poisoned by BeginFramePresentation, then propagated to Galaxy.MoneyIntegrityFailed at $6017F7.
  PresentationDepth: Integer = 0; // @addr $617FCC
  GammaRampCapable: Boolean; // @addr $61C01C
  OriginalGammaRamp: TDDGammaRamp; // @addr $61C020
  RuntimeActive: Boolean; // @addr $61C620
  WindowedRendering: Boolean; // @addr $61C621 Native byte used by cursor and screen-coordinate conversion.
  RestoreNormalCooperativeLevel: Boolean; // @addr $61C622
  ShowSystemMouse: Boolean; // @addr $61C623
  RawObjectInfo: Boolean; // @addr $61C624 Selects the generic text view instead of specialized star-map information panels.
  VideoOverlayFlags: Cardinal; // @addr $61C628
  VideoOverlayWidth: Integer; // @addr $61C62C
  VideoOverlayHeight: Integer; // @addr $61C630
  VideoOverlayFX: TDDOverlayFX; // @addr $61C634
  Direct3D8DisplayMode: TD3DDisplayMode8; // @addr $61C66C
  ScreenPresentBuffer: TGraphBufGR; // @addr $61C67C
  ScreenRenderBuffer: TGraphBufGR; // @addr $61C680
  RenderScratchBuffer: TGraphBufGR; // @addr $61C684
  AuxRenderBuffer: TGraphBufGR; // @addr $61C688 Scanner backdrop, cleared when leaving the screen.
  CurrentLanguage: WideString; // @addr $61C68C
  CurrentPixelFormat: TPixelFormatGR; // @addr $61C690
  GameScreenWidth: Integer; // @addr $61C694
  GameScreenHeight: Integer; // @addr $61C698
  GameScreenRect: TRect; // @addr $61C69C
  MainWindowHandle: Cardinal; // @addr $61C6AC
  WideCaseTable: array of TWideCasePair; // @addr $61C6B0
  InstallConfig: TBlockParEC; // @addr $61C6B4
  Config: TBlockParEC; // @addr $61C6B8
  MainDataConfig: TBlockParEC; // @addr $61C6BC
  LanguageDataConfig: TBlockParEC; // @addr $61C6C0
  UiStyleConfig: TBlockParEC; // @addr $61C6C4
  GameDataConfig: TBlockParEC; // @addr $61C6C8
  UiDepthConfig: TBlockParEC; // @addr $61C6CC
  RootResourceData: TDataEC; // @addr $61C6D0
  GlobalCache: TCacheEC; // @addr $61C6D4
  SessionLog: TextFile; // @addr $61C6D8
  SavePreviewGraph: TGraphBufGR; // @addr $61C8A4
  LastRecordingFrameTick: Cardinal; // @addr $61C8A8
  DemoLastEventTick: Cardinal; // @addr $61C8AC
  Demo: TDemo; // @addr $61C8B0
  CounterFrequency: Int64; // @addr $61C8B4
  DebugCommandMessage: Cardinal; // @addr $61C8BC
  ExceptionLogGuard: Integer; // @addr $61C8C0 Nonzero suppresses native exception logging; no native writer found.

  SuppressExceptionLogCopy: Boolean; // @addr $61C8C4 Shared by native abort paths and BreakUiMessage.
  BlendPixel16: TBlendPixel16; // @addr $61C8C8
  TriangleRasterizer16: TTriangleRasterizer16; // @addr $61C8CC OKGF_Triangle_15 or _16 for the current pixel format; used by TfAB.DrawShipHealthBars.
  LineRasterizer16: TLineRasterizer16; // @addr $61C8D0
  DebugCommandCallback: procedure; // @addr $61C8D4
  OnWindowActivate: procedure; // @addr $61C8D8
  OnWindowDeactivate: procedure; // @addr $61C8DC
  RuntimeStartupTick: Cardinal; // @addr $61C8E0
  MainRuntimeThreadId: Cardinal; // @addr $61C8E4 Native scene destruction compares this with GetCurrentThreadId.

// Native OKGF import table $4B0640..$4B0A30.
function OKGF_MulTable256x256: Pointer; cdecl;
  external 'okgf.dll' name 'OKGF_MulTable256x256'; // @addr $4B0640
function OKGF_ReadStart_Buf(Source: Pointer; SourceSize: Integer; out Width, Height: Integer): POkgfReadContext; cdecl;
  external 'okgf.dll' name 'OKGF_ReadStart_Buf'; // @addr $4B0648
function OKGF_Read(Context: POkgfReadContext; Pixels: Pointer; PitchBytes: Integer; RedMask, GreenMask, BlueMask, AlphaMask: Cardinal; BytesPerPixel: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGF_Read'; // @addr $4B0650
function OKGF_ReadStartPal_Buf(Source: Pointer; SourceSize: Integer; out Width, Height, PaletteCount, BytesPerPixel: Integer): POkgfReadContext; cdecl;
  external 'okgf.dll' name 'OKGF_ReadStartPal_Buf'; // @addr $4B0658
function OKGF_ReadPal(Context: POkgfReadContext; Pixels: Pointer; PitchBytes: Integer; Palette: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGF_ReadPal'; // @addr $4B0660
procedure OKGF_Write_BMP_File(FileName: PAnsiChar; Pixels: Pointer; Pitch, BitsPerPixel: Integer; RedMask, GreenMask, BlueMask, AlphaMask: Cardinal; Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Write_BMP_File'; // @addr $4B0668
procedure OKGF_AVI_Init; cdecl; external 'okgf.dll' name 'OKGF_AVI_Init'; // @addr $4B0670
procedure OKGF_AVI_DeInit; cdecl; external 'okgf.dll' name 'OKGF_AVI_DeInit'; // @addr $4B0678
function OKGF_AVI_Open(FileName: PAnsiChar; var Width, Height, Count: Integer; var FramesPerSecond: Single): Pointer; cdecl; external 'okgf.dll' name 'OKGF_AVI_Open'; // @addr $4B0680
procedure OKGF_AVI_Close(Decoder: Pointer); cdecl; external 'okgf.dll' name 'OKGF_AVI_Close'; // @addr $4B0688
procedure OKGF_AVI_Draw_16(Decoder: Pointer; Frame, SourceX, SourceY: Integer; Pixels: Pointer; Pitch, X, Y, Width, Height: Integer); cdecl; external 'okgf.dll' name 'OKGF_AVI_Draw_16'; // @addr $4B0690
procedure OKGF_AVI_Draw_15(Decoder: Pointer; Frame, SourceX, SourceY: Integer; Pixels: Pointer; Pitch, X, Y, Width, Height: Integer); cdecl; external 'okgf.dll' name 'OKGF_AVI_Draw_15'; // @addr $4B0698
function OKGF_ZLib_Compress(Dest, Source: Pointer; SourceSize, Mode: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGF_ZLib_Compress'; // @addr $4B06A0
function OKGF_ZLib_UnCompress(Dest: Pointer; DestCapacity: Integer; Source: Pointer; SourceSize: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGF_ZLib_UnCompress'; // @addr $4B06A8
procedure OKGR_AlphaBuf_Draw_5658(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaBuf_Draw_5658'; // @addr $4B06B0
procedure OKGR_TransAlphaBuf_Draw_5658(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_TransAlphaBuf_Draw_5658'; // @addr $4B06B8
procedure OKGR_TransAlphaBuf_Draw_5558(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_TransAlphaBuf_Draw_5558'; // @addr $4B06C0
procedure OKGR_AlphaIndexed_CopyDraw_5658(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_CopyDraw_5658'; // @addr $4B06C8
procedure OKGR_AlphaIndexed_AlphaDraw_5658(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_AlphaDraw_5658'; // @addr $4B06D0
procedure OKGR_AlphaIndexed_AlphaDraw_5558(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_AlphaDraw_5558'; // @addr $4B06D8
procedure OKGR_TransBuf_Draw_5658(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_Draw_5658'; // @addr $4B06E0
procedure OKGR_TransBuf_DrawClip_WORD(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_DrawClip_WORD'; // @addr $4B06E8
procedure OKGR_TransBuf_Convert565to555_WORD(Data: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_Convert565to555_WORD'; // @addr $4B06F0
procedure OKGR_TransBuf_HADrawClip_16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_HADrawClip_16'; // @addr $4B06F8
procedure OKGR_TransBuf_HADrawClip_15(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_HADrawClip_15'; // @addr $4B0700
function OKGR_TransBuf_Build_WORD(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer; TransparentColor: Word): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_Build_WORD'; // @addr $4B0708
function OKGR_TransBuf_BuildFromRGBA_16(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_BuildFromRGBA_16'; // @addr $4B0710
function OKGR_TransBuf_BuildFromRGBA_15(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_BuildFromRGBA_15'; // @addr $4B0718
procedure OKGR_TransAlphaBuf_DrawClip_WORD(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_TransAlphaBuf_DrawClip_WORD'; // @addr $4B0720
procedure OKGR_AlphaBuf_DrawClip_16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaBuf_DrawClip_16'; // @addr $4B0728
procedure OKGR_AlphaBuf_DrawClip_15(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaBuf_DrawClip_15'; // @addr $4B0730
function OKGR_TransAlphaBuf_BuildFromRGBA_16(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_TransAlphaBuf_BuildFromRGBA_16'; // @addr $4B0738
function OKGR_TransAlphaBuf_BuildFromRGBA_15(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_TransAlphaBuf_BuildFromRGBA_15'; // @addr $4B0740
function OKGR_AlphaBuf_BuildFromRGBA(Source: Pointer; Pitch, Width, Height: Integer; Dest: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_AlphaBuf_BuildFromRGBA'; // @addr $4B0748
procedure OKGR_AlphaSimpleBuf_Draw_16(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaSimpleBuf_Draw_16'; // @addr $4B0750
procedure OKGR_AlphaSimpleBuf_Draw_15(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaSimpleBuf_Draw_15'; // @addr $4B0758
procedure OKGR_AlphaSimpleBufPalAlpha_Draw_16(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer; Palette: PColorRGBA); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaSimpleBufPalAlpha_Draw_16'; // @addr $4B0760
procedure OKGR_AlphaSimpleBufPalAlpha_Draw_15(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer; Palette: PColorRGBA); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaSimpleBufPalAlpha_Draw_15'; // @addr $4B0768
procedure OKGR_MaskBuf_DrawClip_DWORD(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; Color: Cardinal; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_MaskBuf_DrawClip_DWORD'; // @addr $4B0770
procedure OKGR_MaskBuf_DrawClip_WORD(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_MaskBuf_DrawClip_WORD'; // @addr $4B0778
procedure OKGR_TransBuf_FillAlphaClip_RGBA(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect; Color: Cardinal); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_FillAlphaClip_RGBA'; // @addr $4B0780
procedure OKGR_TransBuf_FillAlphaClip_16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect; Color: Word); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_FillAlphaClip_16'; // @addr $4B0788
procedure OKGR_TransBuf_FillAlphaClip_15(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect; Color: Word); cdecl;
  external 'okgf.dll' name 'OKGR_TransBuf_FillAlphaClip_15'; // @addr $4B0790
procedure OKGR_AlphaIndexed_Copy16to15(Data: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_Copy16to15'; // @addr $4B0798
procedure OKGR_AlphaIndexed_Alpha16to15(Data: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_Alpha16to15'; // @addr $4B07A0
procedure OKGR_AlphaIndexed_CopyDrawClip_WORD(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_CopyDrawClip_WORD'; // @addr $4B07A8
procedure OKGR_AlphaIndexed_AlphaDrawClip_16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_AlphaDrawClip_16'; // @addr $4B07B0
procedure OKGR_AlphaIndexed_AlphaDrawClip_15(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AlphaIndexed_AlphaDrawClip_15'; // @addr $4B07B8
function OKGR_RotateBuf_Build(Width, Height, SourceWidth, SourceHeight, CenterX, CenterY: Integer): Pointer; cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_Build'; // @addr $4B07C0
procedure OKGR_RotateBuf_Free(Buffer: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_Free'; // @addr $4B07C8
procedure OKGR_RotateBuf_Size(X, Y: Integer; Angle: Byte; RotationMap: Pointer; var Bounds: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_Size'; // @addr $4B07D0
procedure OKGR_RotateBuf_Draw_DWORD(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, CenterX, CenterY: Integer; Angle: Byte; RotationMap: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_Draw_DWORD'; // @addr $4B07D8
procedure OKGR_RotateBuf_Draw_BYTE(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, Width, Height: Integer; Angle: Byte; RotationMap: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_Draw_BYTE'; // @addr $4B07E0
procedure OKGR_RotateBuf_DrawTransClip_WORD(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, CenterX, CenterY: Integer; Angle: Byte; RotationMap: Pointer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_RotateBuf_DrawTransClip_WORD'; // @addr $4B07E8
function OKGR_LightBuf_Create(Width, Height: Integer): Pointer; cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_Create'; // @addr $4B07F0
procedure OKGR_LightBuf_Destroy(Buffer: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_Destroy'; // @addr $4B07F8
procedure OKGR_LightBuf_SetSme(Buffer: Pointer; X, Y: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_SetSme'; // @addr $4B0800
procedure OKGR_LightBuf_Init(Buffer: Pointer; Value: Byte); cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_Init'; // @addr $4B0808
procedure OKGR_LightBuf_LoadFromPalBuf(Buffer, Source: Pointer; Width, Height, Pitch: Integer; Palette: PColorRGBA); cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_LoadFromPalBuf'; // @addr $4B0810
procedure OKGR_LightBuf_Rotate(Dest, Source, RotationMap: Pointer; Angle: Byte); cdecl;
  external 'okgf.dll' name 'OKGR_LightBuf_Rotate'; // @addr $4B0818
function OKGR_Planet2_TemplBuild(Source: Pointer; Pitch, Height, TextureWidth, TextureHeight: Integer; var ByteCount: Integer): Pointer; cdecl;
  external 'okgf.dll' name 'OKGR_Planet2_TemplBuild'; // @addr $4B0820
function OKGR_Planet2_TemplDel(TemplateData: Pointer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_Planet2_TemplDel'; // @addr $4B0828
procedure OKGR_Planet2_DrawAndLightClip_16(Dest: Pointer; DestPitch: Integer; TemplateData, Source: Pointer; SourcePitch, WidthMask, MapOffset: Integer; LightBuffer, Palette: Pointer; X, Y: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Planet2_DrawAndLightClip_16'; // @addr $4B0830
procedure OKGR_Planet2_DrawAndLightClip_15(Dest: Pointer; DestPitch: Integer; TemplateData, Source: Pointer; SourcePitch, WidthMask, MapOffset: Integer; LightBuffer, Palette: Pointer; X, Y: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Planet2_DrawAndLightClip_15'; // @addr $4B0838
procedure OKGR_Planet3_DrawAndLightClip_16(Dest: Pointer; DestPitch: Integer; TemplateData, Source: Pointer; SourcePitch, WidthMask, MapOffset: Integer; LightBuffer, Palette: Pointer; X, Y: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Planet3_DrawAndLightClip_16'; // @addr $4B0840
procedure OKGR_Planet3_DrawAndLightClip_15(Dest: Pointer; DestPitch: Integer; TemplateData, Source: Pointer; SourcePitch, WidthMask, MapOffset: Integer; LightBuffer, Palette: Pointer; X, Y: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Planet3_DrawAndLightClip_15'; // @addr $4B0848
procedure OKGR_Copy_XY_XY_WORD(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_Copy_XY_XY_WORD'; // @addr $4B0850
procedure OKGR_PalCopy_XY_XY_WORD(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY: Integer; Palette: Pointer; Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_PalCopy_XY_XY_WORD'; // @addr $4B0858
procedure OKGR_PalCopySwap_XY_XY_DWORD(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY: Integer; Palette: PColorRGBA; Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_PalCopySwap_XY_XY_DWORD'; // @addr $4B0860
procedure OKGR_CopyTrans_XY_XY_WORD(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer; TransparentColor: Word); cdecl;
  external 'okgf.dll' name 'OKGR_CopyTrans_XY_XY_WORD'; // @addr $4B0868
procedure OKGR_CopySingleBuf_XY_XY_WORD(Pixels: Pointer; Pitch, DestX, DestY, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_CopySingleBuf_XY_XY_WORD'; // @addr $4B0870
procedure OKGR_HACopy_XY_XY_16(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_HACopy_XY_XY_16'; // @addr $4B0878
procedure OKGR_HACopy_XY_XY_15(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_HACopy_XY_XY_15'; // @addr $4B0880
procedure OKGR_StretchGdi_WORD(Dest: Pointer; Width, Height: Cardinal; Source: Pointer; SourceWidth, SourceHeight: Cardinal); cdecl;
  external 'okgf.dll' name 'OKGR_StretchGdi_WORD'; // @addr $4B0888
procedure OKGR_Fill_WORD(Pixels: Pointer; Pitch, Width, Height: Integer; Color: Word); cdecl;
  external 'okgf.dll' name 'OKGR_Fill_WORD'; // @addr $4B0890
procedure OKGF_ConvertRGBto565(Source, Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_ConvertRGBto565'; // @addr $4B0898
procedure OKGF_ConvertRGBto555(Source, Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_ConvertRGBto555'; // @addr $4B08A0
procedure OKGF_Convert565toRGB(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert565toRGB'; // @addr $4B08A8
procedure OKGF_Convert565toBGR(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert565toBGR'; // @addr $4B08B0
procedure OKGF_Convert555toRGB(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert555toRGB'; // @addr $4B08B8
procedure OKGF_Convert555toBGR(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert555toBGR'; // @addr $4B08C0
procedure OKGF_Convert5658toBGRA(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert5658toBGRA'; // @addr $4B08C8
procedure OKGF_Convert5558toBGRA(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert5558toBGRA'; // @addr $4B08D0
procedure OKGF_Convert565toBGRA(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert565toBGRA'; // @addr $4B08D8
procedure OKGF_Convert555toBGRA(Source: Pointer; SourcePitch: Integer; Dest: Pointer; DestPitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert555toBGRA'; // @addr $4B08E0
procedure OKGF_Convert_8888to565(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert_8888to565'; // @addr $4B08E8
procedure OKGF_Convert_8888to555(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert_8888to555'; // @addr $4B08F0
procedure OKGF_Convert_565to555(Dest: Pointer; DestPitch, DestX, DestY: Integer; Source: Pointer; SourcePitch, SourceX, SourceY, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Convert_565to555'; // @addr $4B08F8
procedure OKGR_ShrLight_16(Pixels: Pointer; Pitch, Width, Height, Shift: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_ShrLight_16'; // @addr $4B0900
procedure OKGR_ShrLight_15(Pixels: Pointer; Pitch, Width, Height, Shift: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_ShrLight_15'; // @addr $4B0908
procedure OKGR_MulLightMask_16(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_MulLightMask_16'; // @addr $4B0910
procedure OKGR_MulLightMask_15(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_MulLightMask_15'; // @addr $4B0918
procedure OKGR_ShrLightMask_16(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_ShrLightMask_16'; // @addr $4B0920
procedure OKGR_ShrLightMask_15(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, Width, Height: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_ShrLightMask_15'; // @addr $4B0928
procedure OKGR_Light_BYTE(Pixels: Pointer; PixelStride, Pitch, Width, Height: Integer; Alpha: Byte); cdecl;
  external 'okgf.dll' name 'OKGR_Light_BYTE'; // @addr $4B0930
procedure OKGR_Circle_DrawClip_WORD(Pixels: Pointer; Pitch, X, Y, Radius: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Circle_DrawClip_WORD'; // @addr $4B0938
procedure OKGR_Circle_DrawClip_BYTE(Pixels: Pointer; Pitch, X, Y, Radius: Integer; Color: Byte; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Circle_DrawClip_BYTE'; // @addr $4B0940
procedure OKGR_Circle_DrawFillClip_WORD(Pixels: Pointer; Pitch, X, Y, Radius: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Circle_DrawFillClip_WORD'; // @addr $4B0948
procedure OKGR_Circle_DrawFillClip_BYTE(Pixels: Pointer; Pitch, X, Y, Radius: Integer; Color: Byte; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Circle_DrawFillClip_BYTE'; // @addr $4B0950
procedure OKGR_PixelAlpha_16(Pixel: Pointer; Color: Word; Alpha: Byte); cdecl;
  external 'okgf.dll' name 'OKGR_PixelAlpha_16'; // @addr $4B0958
procedure OKGR_PixelAlpha_15(Pixel: Pointer; Color: Word; Alpha: Byte); cdecl;
  external 'okgf.dll' name 'OKGR_PixelAlpha_15'; // @addr $4B0960
function OKGR_Line_Clip(var X1, Y1, X2, Y2: Integer; const Clip: TRect): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_Line_Clip'; // @addr $4B0968
function OKGR_LineColor_Clip(var X1, Y1: Integer; var Color1: Cardinal; var X2, Y2: Integer; var Color2: Cardinal; const Clip: TRect): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_LineColor_Clip'; // @addr $4B0970
procedure OKGR_Line_Draw_WORD(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Word); cdecl;
  external 'okgf.dll' name 'OKGR_Line_Draw_WORD'; // @addr $4B0978
procedure OKGR_Line_DrawClip_WORD(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Line_DrawClip_WORD'; // @addr $4B0980
procedure OKGR_Line_Draw_DWORD(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Cardinal); cdecl;
  external 'okgf.dll' name 'OKGR_Line_Draw_DWORD'; // @addr $4B0988
procedure OKGR_Line_Copy_WORD(Dest: Pointer; DestPitch: Integer; Source: Pointer; SourcePitch, X1, Y1, X2, Y2: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_Line_Copy_WORD'; // @addr $4B0990
function OKGR_Line_CopyToBuf_WORD(Dest, Source: Pointer; Pitch, X1, Y1, X2, Y2: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_Line_CopyToBuf_WORD'; // @addr $4B0998
function OKGR_Line_CopyFromBuf_WORD(Source, Dest: Pointer; Pitch, X1, Y1, X2, Y2: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGR_Line_CopyFromBuf_WORD'; // @addr $4B09A0
procedure OKGR_Line_DrawClip_Alpha_15(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Word; Alpha: Byte; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Line_DrawClip_Alpha_15'; // @addr $4B09A8
procedure OKGR_Line_DrawClip_Alpha_16(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Word; Alpha: Byte; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Line_DrawClip_Alpha_16'; // @addr $4B09B0
procedure OKGR_AnimLine_Draw_15(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Cardinal; Phase: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AnimLine_Draw_15'; // @addr $4B09B8
procedure OKGR_AnimLine_Draw_16(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Cardinal; Phase: Integer; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_AnimLine_Draw_16'; // @addr $4B09C0
procedure OKGR_AnimShadowLine_Draw_15(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Cardinal; Phase: Integer; const Clip: TRect; ShadowPixels: Pointer; ShadowPitch: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_AnimShadowLine_Draw_15'; // @addr $4B09C8
procedure OKGR_AnimShadowLine_Draw_16(Pixels: Pointer; Pitch, X1, Y1, X2, Y2: Integer; Color: Cardinal; Phase: Integer; const Clip: TRect; ShadowPixels: Pointer; ShadowPitch: Integer); cdecl;
  external 'okgf.dll' name 'OKGR_AnimShadowLine_Draw_16'; // @addr $4B09D0
procedure OKGR_Alpha64Trapezium_16(Pixels: Pointer; Pitch, X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Alpha64Trapezium_16'; // @addr $4B09D8
procedure OKGR_Alpha64Trapezium_15(Pixels: Pointer; Pitch, X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Alpha64Trapezium_15'; // @addr $4B09E0
procedure OKGR_Alpha128Trapezium_16(Pixels: Pointer; Pitch, X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Alpha128Trapezium_16'; // @addr $4B09E8
procedure OKGR_Alpha128Trapezium_15(Pixels: Pointer; Pitch, X1, Y1, X2, Y2, X3, X4: Integer; Color: Word; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_Alpha128Trapezium_15'; // @addr $4B09F0
procedure OKGR_FillTrapezium_DWORD(Pixels: Pointer; Pitch, X1, X2, Y1, X3, X4, Y2: Integer; Color: Cardinal; const Clip: TRect); cdecl;
  external 'okgf.dll' name 'OKGR_FillTrapezium_DWORD'; // @addr $4B09F8
procedure OKGF_Rescale(Dest: Pointer; Width, Height, DestPitch: Integer; Source: Pointer; SourceWidth, SourceHeight, SourcePitch, BytesPerPixel, Filter: Integer); cdecl;
  external 'okgf.dll' name 'OKGF_Rescale'; // @addr $4B0A00
procedure OKGR_F5_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_F5_DrawRGBA'; // @addr $4B0A08
procedure OKGR_F6_DrawRGBA(Dest: Pointer; Pitch: Integer; Source: Pointer); cdecl;
  external 'okgf.dll' name 'OKGR_F6_DrawRGBA'; // @addr $4B0A10
procedure OKGF_Triangle_15(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal; X3, Y3: Integer; Color3: Cardinal; Clip: POkgfRect); cdecl;
  external 'okgf.dll' name 'OKGF_Triangle_15'; // @addr $4B0A18
procedure OKGF_Triangle_16(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal; X3, Y3: Integer; Color3: Cardinal; Clip: POkgfRect); cdecl;
  external 'okgf.dll' name 'OKGF_Triangle_16'; // @addr $4B0A20
procedure OKGF_LineIp_15(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal); cdecl;
  external 'okgf.dll' name 'OKGF_LineIp_15'; // @addr $4B0A28
procedure OKGF_LineIp_16(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal); cdecl;
  external 'okgf.dll' name 'OKGF_LineIp_16'; // @addr $4B0A30

procedure InitializePlatformRuntimeAndMainWindow; // @addr $4B0A4C
procedure FinalizePlatformRuntime; // @addr $4B0DD0
procedure InitializeRuntimeAndSettings; // @addr $4B1E3C
procedure FinalizeRuntimeAndSettings; // @addr $4B46A0
function ReadPerformanceCounter: Int64; // @addr $4B0A38
procedure InitializeDirectDraw; // @addr $4B4BA0 @note "Creates 16-bit DirectDraw surfaces; optional Direct3D 8 setup catches only EAbort."
procedure ReleaseDirectDraw; // @addr $4B5BC8
procedure ConfigureDirectDrawMode; // @addr $4B4940
function EnumerateRefreshRate(const Desc: TDDSurfaceDesc; Context: Pointer): Integer; stdcall; // @addr $4B480C
procedure PresentVideoOverlay; // @addr $4B6E0C
procedure PostMouseMoveMessage; // @addr $4B809C
function MeasureCpuClockMHz: Double; // @addr $4B80D8
function LookupLocalizedTextLines(const Path: WideString): WideString; // @addr $4B7C34
procedure LoadAdditionalQuestPackages; // @addr $4B0E28 @note "Reads AddQuest.txt; swallows package and manifest exceptions, retaining any changes already made."
procedure UnloadAdditionalQuestPackages; // @addr $4B1D30
procedure AppendOptionalDebugLogLine(const Text: AnsiString); // @addr $4B7EC8
procedure AppendLogTextThreadSafe(const Text: AnsiString); // @addr $4B7E70
procedure AppendLogLineThreadSafe(const Text: AnsiString); // @addr $4B7E18

function MainWindowProc(WindowHandle, Message, WParam: Cardinal; LParam: Integer): Integer; stdcall; // @addr $4B63C4
procedure ClearPresentationScreen; // @addr $4B6D80
function WinMessage(Callback: TWindowMessageCallbackGR): Integer; // @addr $4B5F3C
procedure FlushRecordingFrames; // @addr $4B70D0
procedure CaptureRecordingFrame; // @addr $4B7050
procedure DrawPresentationOverride; // @addr $4B6B78
function AddCursorUnit: TCursorUnit; // @addr $4B7FC0
procedure RemoveCursorUnit(Cursor: TCursorUnit); // @addr $4B8000
function FindCursorByName(const Name: WideString): TCursorUnit; // @addr $4B8044
procedure PresentScreenRect(Rect: TRect); // @addr $4B6A50

procedure RaiseWideMessage(const Message: WideString); // @addr $4B83E4

function LookupLocalizedTextByKey(const Path: WideString): WideString; // @addr $4B7BE8
function LookupLocalizedTextOrEmpty(const Path: WideString): WideString; // @addr $4B7C00

procedure DrawTransparentBuffer16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; Clip: TRect; HalfAlpha: Boolean); // @addr $4B736C

procedure CopyPalettedBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source, Palette: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect); // @addr $4B73F4

procedure CopyGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect; HalfAlpha, UnusedOption: Boolean); // @addr $4B74D4

procedure CopyBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect; UnusedOption: Boolean); // @addr $4B7624

procedure CopyTransparentGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect; TransparentColor: Word); // @addr $4B7700

procedure DrawAlphaGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect); // @addr $4B77F4

procedure DrawAlphaBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect); // @addr $4B7918

function GiResourceSuffix: WideString; // @addr $4B7D34
function GiScalePixels(Value: Integer): Integer; // @addr $4B7D70

procedure DrawPaletteAlphaBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufPalGR; Clip: TRect); // @addr $4B7A28

procedure ApplyGammaRamp(Brightness, Contrast: Single); // @addr $4B5CB4

function GiResourceVariant: Integer; // @addr $4B7D1C

function IsInstallFeatureEnabled(const Name: WideString): Boolean; // @addr $4B7F58

function IsVirtualKeyDown(Key: Integer): Boolean; // @addr $4B7BCC
function BeginFramePresentation: Boolean; // @addr $4B6878
procedure EndFramePresentation; // @addr $4B69C4

function ReadRegistryText(Root: Cardinal; KeyPath, ValueName, DefaultValue: WideString): WideString; // @addr $4B81B4 @note "ANSI registry API, fixed 2048-byte buffer, REG_SZ only."

function ReadRegistryInteger(Root: Cardinal; KeyPath, ValueName: WideString; DefaultValue: Integer): Integer; // @addr $4B82F4

procedure CaptureScreenBackground; // @addr $4B6B38

procedure FreeSavePreviewBuffer; // @addr $4B7034
procedure CaptureSavePreview; // @addr $4B6F34

procedure NotifyLoadingStage(const Stage: WideString); // @addr $4B7368 Native dormant progress hook.

function PackArgbFloats(Alpha, Red, Green, Blue: Single): Cardinal; // @addr $4B7DA8
procedure DrawGradientLine16Clipped(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal; Clip: TRect); // @addr $4B7B54 @note "Native ignores Pixels and Pitch, drawing into ScreenRenderBuffer."

implementation

// @unit-initialization $4B84E0
// @unit-finalization $4B843C

uses Windows, SysUtils, EC_OKGF, EC_Mem, MMSystem, Messages, GlobalsV, GI_MessageLoop, Math, GI_Main, EC_HsFile, EC_Buf, GR_DirectX, EC_File, aPacket, ActiveX, Forms;

var
  StartupState: Integer; // @addr $61C8EC Cleared by settings initialization; later states not yet recovered.
  ScreenCenterX: Integer; // @addr $61C8F0
  ScreenCenterY: Integer; // @addr $61C8F4

{ @routine $4B0A38 ReadPerformanceCounter }
function ReadPerformanceCounter: Int64;
begin
  QueryPerformanceCounter(Result);
end;
{ @end $4B0A38 }

{ @routine $4B0A4C InitializePlatformRuntimeAndMainWindow }
procedure InitializePlatformRuntimeAndMainWindow;
var WindowClass: TWndClassA; ClassName: PAnsiChar;
begin
  CoInitialize(nil);
  DebugCommandMessage := RegisterWindowMessage('DebugMsgCommand');
  CopyFile('#ship_c.dbf', '#ship.dbf', False);
  {$I-}
  AssignFile(SessionLog, '########.log');
  Rewrite(SessionLog);
  Writeln(SessionLog, 'Start');
  CloseFile(SessionLog);
  {$I+}
  CounterFrequency := 0;
  QueryPerformanceFrequency(CounterFrequency);
  WindowClass.style := 11;
  WindowClass.cbClsExtra := 0;
  WindowClass.cbWndExtra := 0;
  WindowClass.hInstance := HInstance;
  // Native passes the process pseudo-handle here, not the module instance.
  if ShowSystemMouse then WindowClass.hIcon := LoadIcon(GetCurrentProcess, IDI_APPLICATION)
  else WindowClass.hIcon := 0;
  WindowClass.hCursor := LoadCursor(0, IDC_ARROW);
  WindowClass.hbrBackground := 0;
  WindowClass.lpszMenuName := nil;
  ClassName := MainWindowClassName;
  WindowClass.lpszClassName := ClassName;
  WindowClass.lpfnWndProc := @MainWindowProc;
  if RegisterClass(WindowClass) = 0 then
    raise Exception.Create('RegisterClass GetLastError()=' + IntToStr(Int64(GetLastError)));
  MainWindowHandle := CreateWindowEx(0, MainWindowClassName, MainWindowTitle, WS_POPUP,
    0, 0, 1, 1, 0, 0, HInstance, nil);
  if MainWindowHandle = 0 then
    raise Exception.Create('CreateWindowEx GetLastError()=' + IntToStr(Int64(GetLastError)));
  Application.Handle := MainWindowHandle;
  if not InitializePackageCollection then
    raise Exception.Create('Error while initializing package files');
  InstallConfig := TBlockParEC.Create;
  InstallConfig.LoadFromTextFileWithEncodingProbe('install.txt', False);
  if not LoadConfiguredPackages then
    raise Exception.Create('Error while openning package files');
  Demo := TDemo.Create;
end;
{ @end $4B0A4C }

{ @routine $4B0DD0 FinalizePlatformRuntime }
procedure FinalizePlatformRuntime;
begin
  if Demo <> nil then
  begin
    Demo.Free;
    Demo := nil;
  end;
  FreeSavePreviewBuffer;
  if InstallConfig <> nil then
  begin
    InstallConfig.Free;
    InstallConfig := nil;
  end;
  FinalizePackageCollection;
  DestroyWindow(MainWindowHandle);
  MainWindowHandle := 0;
  CoUninitialize;
end;
{ @end $4B0DD0 }

{ @routine $4B0E28 LoadAdditionalQuestPackages }
procedure LoadAdditionalQuestPackages;
var
  Definitions, QuestInfo, Links, OutputBlock, QuestImages, Images: TBlockParEC;
  Index, LastImage, QuestNumber, LinkIndex, ImageNumber, LinkCount, Seed: Integer;
  Text, QuestId, ImageName: WideString;
  Pack: TPackFileEC;
  Slot: Cardinal;
  Buffer: TBufEC;
  HasItem: Boolean;
  Checksum, EntrySize: Cardinal;
  ItemText: TBlockParEC;
begin
  if FileExists('AddQuest.txt') then
  begin
    Definitions := TBlockParEC.Create;
    QuestInfo := TBlockParEC.Create;
    OutputBlock := TBlockParEC.Create;
    Pack := TPackFileEC.Create;
    Buffer := TBufEC.Create;
    if QuestDisplayNames <> nil then
    begin
      QuestDisplayNames.Free;
      QuestDisplayNames := nil;
    end;
    QuestDisplayNames := TBlockParEC.Create;
    QuestImages := OutputBlock.AddChildBlock('PQAdd');
    try
      Definitions.LoadFromTextFileWithEncodingProbe('AddQuest.txt', False);
      for Index := 0 to Definitions.GetParamCount - 1 do
      begin
        Text := Definitions.GetParamName(Index);
        if IsIntegerTextW(Text) then
        begin
          QuestNumber := ExtractDigitsToIntW(Text);
          if QuestNumber >= 10000 then
          begin
            Text := Definitions.GetParamValue(Index);
            if FileExists(AnsiString('PQuest\' + Text)) then
            begin
              Slot := $FFFFFFFF;
              try
                Pack.CloseForDestroy;
                Pack.OpenReadWritePath(AnsiString('PQuest\' + Text));
                Buffer.Clear;
                Slot := Pack.OpenEntryByPath('questinfo.txt', GENERIC_READ or GENERIC_WRITE);
                if Slot = $FFFFFFFF then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                EntrySize := Pack.GetEntrySlotSize(Slot);
                if EntrySize = $FFFFFFFF then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                Buffer.SetSize(EntrySize);
                if not Pack.ReadEntrySlot(Slot, Buffer.Data, EntrySize) then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                Pack.CloseEntrySlot(Slot);
                Slot := $FFFFFFFF;
                QuestInfo.Clear;
                Buffer.SetPosition(0);
                Buffer.GetUInt32;
                Buffer.GetUInt32;
                Checksum := Buffer.GetUInt32;
                Seed := Buffer.GetUInt32;
                Buffer.ApplyDatXorCipherRange(Seed, 16, Buffer.DataSize);
                if Checksum <> Buffer.ComputeCrc32Range(16, Buffer.DataSize) then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                QuestInfo.LoadFromTextBufferWithEncodingProbe(Buffer, False);
                QuestId := QuestInfo.GetParam('Id');
                if not Pack.FileExists(AnsiString('data\PQuest\' + QuestId + '.qm')) then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                if QuestDisplayNames.CountParams(QuestId) > 0 then
                begin
                  SuppressExceptionLogCopy := True;
                  Abort;
                end;
                QuestDisplayNames.AddParam(QuestId, Text);
                HasItem := False;
                if Pack.FileExists(AnsiString('data\PQuest\' + QuestId + '_2.gi')) then
                begin
                  RootResourceData.FindEntry('Bm').ChildData.FindEntry('ItemsUseless').ChildData.AddFileEntry(
                    '1' + QuestId + '_s', 'data\PQuest\' + QuestId + '_1.gi');
                  RootResourceData.FindEntry('Bm').ChildData.FindEntry('ItemsUseless').ChildData.AddFileEntry(
                    '2' + QuestId + '_s', 'data\PQuest\' + QuestId + '_2.gi');
                  ItemText := LanguageDataConfig.GetBlock('UselessItems').AddChildBlock(QuestId);
                  ItemText.AddParam('Name', QuestInfo.GetParamOrMarker('ItemName'));
                  ItemText.AddParam('Text', QuestInfo.GetParamOrMarker('ItemText'));
                  ItemText.AddParam('Description', QuestInfo.GetParamOrMarker('ItemDescription'));
                  ItemText.AddParam('Owner', QuestInfo.GetParamOrMarker('ItemOwner'));
                  ItemText.AddParam('Cost', QuestInfo.GetParamOrMarker('ItemCost'));
                  ItemText.AddParam('Size', QuestInfo.GetParamOrMarker('ItemSize'));
                  HasItem := True;
                end;
                Images := QuestInfo.FindBlock('Images');
                if QuestInfo.CountBlocks('Links') > 0 then
                begin
                  Links := QuestInfo.GetBlock('Links');
                  LinkCount := Links.GetParamCount;
                  LastImage := -1;
                  for LinkIndex := 0 to LinkCount - 1 do
                  begin
                    ImageNumber := ExtractDigitsToIntW(Links.GetParamName(LinkIndex));
                    if Images <> nil then
                    begin
                      ImageName := Images.GetParam(IntToFixedWidthWideString(ImageNumber, 6));
                      if not IsIntegerTextW(ImageName) then
                      begin
                        ImageName := RootResourceData.FindEntry('Bm').ChildData.FindEntry('PQI').ChildData.FindNameByFileName(ImageName);
                        if ImageName <> '' then
                          MainDataConfig.GetBlock('Data').GetBlock('PQI').AddParam(
                            WideString(IntToStr(QuestNumber) + ',') + Links.GetParamValue(LinkIndex), 'Bm.PQI.' + ImageName);
                        Continue;
                      end;
                    end;
                    if ImageNumber <> LastImage then
                    begin
                      LastImage := ImageNumber;
                      QuestImages.AddParam(IntToStr(QuestNumber) + '_' + IntToStr(ImageNumber),
                        'data\PQI\' + QuestId + '\' + IntToStr(ImageNumber) + '.jpg');
                    end;
                    MainDataConfig.GetBlock('Data').GetBlock('PQI').AddParam(
                      WideString(IntToStr(QuestNumber) + ',') + Links.GetParamValue(LinkIndex),
                      'PQAdd.' + IntToStr(QuestNumber) + '_' + IntToStr(ImageNumber));
                  end;
                end;
                LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').AddParam(IntToStr(QuestNumber),
                  'data\PQuest\' + QuestId + '.qm');
                if not HasItem then
                  LanguageDataConfig.GetBlockByPath('PlanetQuest.ItemForPlanetQuest').AddParam(IntToStr(QuestNumber), 'none')
                else
                  LanguageDataConfig.GetBlockByPath('PlanetQuest.ItemForPlanetQuest').AddParam(IntToStr(QuestNumber), QuestId);
                LanguageDataConfig.GetBlock('PlanetQuest').GetOrAddChildBlock('PlanetQuestLic').AddParam(
                  IntToStr(QuestNumber), QuestInfo.GetParamOrMarker('Lic'));
                PackageCollection.AddPackToBack(Pack);
                Pack := TPackFileEC.Create;
              except
                if Slot <> $FFFFFFFF then Pack.CloseEntrySlot(Slot);
              end;
            end;
          end;
        end;
      end;
    except
      { Native swallows manifest errors too, then publishes accumulated images. }
    end;
    if QuestImages.GetParamCount > 0 then RootResourceData.AddMissingFromBlock(OutputBlock);
    QuestInfo.Free;
    Buffer.Free;
    Pack.Free;
    OutputBlock.Free;
    Definitions.Free;
  end;
end;
{ @end $4B0E28 }

{ @routine $4B1D30 UnloadAdditionalQuestPackages }
procedure UnloadAdditionalQuestPackages;
var Pack, NextPack: TPackFileEC;
begin
  PackageFileLock.Enter;
  NextPack := PackageCollection.FirstPack;
  while NextPack <> nil do
  begin
    Pack := NextPack;
    NextPack := NextPack.NextPack;
    if HasWidePrefix(LowerCase(Pack.PackagePath), 'pquest\') or
      HasWidePrefix(LowerCase(Pack.PackagePath), 'pquest/') then
      PackageCollection.RemovePack(Pack, True);
  end;
  PackageFileLock.Leave;
end;
{ @end $4B1D30 }

{ @routine $4B1E3C InitializeRuntimeAndSettings }
procedure InitializeRuntimeAndSettings;
var
  Mode, Text, ExtraText, Suffix: WideString;
  Index, BufferSize: Integer;
  Cursor: TCursorUnit;
  FileText: AnsiString;
  WindowRect: TRect;
  VersionInformation: TOSVersionInfoA;
  MemoryStatus: TMemoryStatus;
  Block: TBlockParEC;
  Frame: Pointer;
  Buf: TBufEC;
  VersionFile: TFileEC;
begin
  StartupState := 0;
  FinalizeRuntimeAndSettings;
  AppendLogLineThreadSafe('Build=1.7.2');
  AppendLogLineThreadSafe('NORMAL_ARRAY_RECT');
  ZeroMemory(@VersionInformation, SizeOf(VersionInformation));
  VersionInformation.dwOSVersionInfoSize := SizeOf(VersionInformation);
  if GetVersionEx(VersionInformation) then
  begin
    Text := '';
    if VersionInformation.dwPlatformId = 0 then Text := '32s'
    else if VersionInformation.dwPlatformId = 1 then
    begin
      Text := 'Windows';
      if VersionInformation.dwMajorVersion = 4 then
      begin
        if VersionInformation.dwMinorVersion = 0 then Text := Text + ' 95'
        else if VersionInformation.dwMinorVersion = 10 then Text := Text + ' 98'
        else if VersionInformation.dwMinorVersion = 90 then Text := Text + ' Me';
      end;
      VersionInformation.dwBuildNumber := VersionInformation.dwBuildNumber and $FFFF;
    end
    else if VersionInformation.dwPlatformId = 2 then
    begin
      Text := 'Windows';
      if (VersionInformation.dwMajorVersion = 3) and (VersionInformation.dwMinorVersion = 51) then Text := Text + ' NT 3.51'
      else if (VersionInformation.dwMajorVersion = 4) and (VersionInformation.dwMinorVersion = 0) then Text := Text + ' NT 4.0'
      else if (VersionInformation.dwMajorVersion = 5) and (VersionInformation.dwMinorVersion = 0) then Text := Text + ' 2000'
      else if (VersionInformation.dwMajorVersion = 5) and (VersionInformation.dwMinorVersion = 1) then Text := Text + ' XP'
      else Text := Text + ' NT';
    end
    else Text := WideString(IntToStr(Int64(VersionInformation.dwPlatformId)));
    AppendLogLineThreadSafe(Format('%s %d.%d.%d %s', [Text, VersionInformation.dwMajorVersion,
      VersionInformation.dwMinorVersion, VersionInformation.dwBuildNumber, PAnsiChar(@VersionInformation.szCSDVersion)]));
  end;
  AppendLogLineThreadSafe('CPUSpeed=' + IntToStr(Round(Min(Min(MeasureCpuClockMHz, MeasureCpuClockMHz), MeasureCpuClockMHz))));
  Index := 0;
  while True do
  begin
    Text := TrimWideString(ReadRegistryText(HKEY_LOCAL_MACHINE,
      WideString('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)), 'Identifier', ''));
    ExtraText := TrimWideString(ReadRegistryText(HKEY_LOCAL_MACHINE,
      WideString('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)), 'ProcessorNameString', ''));
    BufferSize := ReadRegistryInteger(HKEY_LOCAL_MACHINE,
      WideString('HARDWARE\DESCRIPTION\System\CentralProcessor\' + IntToStr(Index)), '~MHz', 0);
    if (Text = '') and (ExtraText = '') then Break;
    if BufferSize <> 0 then Suffix := WideString(' (' + IntToStr(BufferSize) + ' MHz)')
    else Suffix := '';
    AppendLogLineThreadSafe(AnsiString(WideString('Processor' + IntToStr(Index) + '=') + Text + ' ' + ExtraText + Suffix));
    Inc(Index);
  end;
  // Native does not initialize dwLength before GlobalMemoryStatus.
  GlobalMemoryStatus(MemoryStatus);
  AppendLogLineThreadSafe('Physical memory.Total = ' + IntToStr(Int64(MemoryStatus.dwTotalPhys shr 20)));
  AppendLogLineThreadSafe('Physical memory.Free  = ' + IntToStr(Int64(MemoryStatus.dwAvailPhys shr 20)));
  AppendLogLineThreadSafe('Paging file.Total     = ' + IntToStr(Int64(MemoryStatus.dwTotalPageFile shr 20)));
  AppendLogLineThreadSafe('Paging file.Free      = ' + IntToStr(Int64(MemoryStatus.dwAvailPageFile shr 20)));
  AppendLogLineThreadSafe('Virtual memory.Total  = ' + IntToStr(Int64(MemoryStatus.dwTotalVirtual shr 20)));
  AppendLogLineThreadSafe('Virtual memory.Free   = ' + IntToStr(Int64(MemoryStatus.dwAvailVirtual shr 20)));
  AppendLogLineThreadSafe('Memory.Use            = ' + IntToStr(Int64(MemoryStatus.dwMemoryLoad)) + '%');
  NotifyLoadingStage('');
  Config := TBlockParEC.Create;
  Config.LoadFromTextFileWithEncodingProbe('cfg.txt', True);
  MainDataConfig := TBlockParEC.Create;
  if GenerateEncodedResources or not FileExists('CFG\CacheData.dat') or not FileExists('CFG\Main.dat') then
    MainDataConfig.LoadFromTextFileWithEncodingProbe('cfg\main.txt', False)
  else MainDataConfig.LoadEncodedFile('CFG\Main.dat');
  NotifyLoadingStage('CFG');
  WindowedRendering := False;
  if Config.CountParams('Window') > 0 then
    WindowedRendering := ParseEnabledNameGI(TrimWideString(Config.GetParamByPath('Window')));
  RestoreNormalCooperativeLevel := False;
  if Config.CountParams('Debug') > 0 then
    RestoreNormalCooperativeLevel := ParseEnabledNameGI(TrimWideString(Config.GetParamByPath('Debug')));
  ShowSystemMouse := False;
  if Config.CountParams('ShowSystemMouse') > 0 then
    ShowSystemMouse := ParseEnabledNameGI(TrimWideString(Config.GetParamByPath('ShowSystemMouse')));
  RawObjectInfo := False;
  if Config.CountParams('ShowDebugInfo') > 0 then
    RawObjectInfo := ParseEnabledNameGI(TrimWideString(Config.GetParamByPath('ShowDebugInfo')));
  if Config.CountParams('LogShip') > 0 then
    ShipDatabaseLoggingEnabled := ParseEnabledNameGI(TrimWideString(Config.GetParamByPath('LogShip')));
  CurrentLanguage := TrimWideString(Config.GetParamByPath('Lang'));
  if InstallConfig.CountParamsByPath('Lang.' + CurrentLanguage) < 1 then
    raise Exception.Create('Not installed language: ' + CurrentLanguage);
  LanguageDataConfig := TBlockParEC.Create;
  if GenerateEncodedResources then
  begin
    Block := InstallConfig.GetBlock('Lang');
    Index := Block.GetParamCount;
    for Index := 0 to Index - 1 do
    begin
      Text := ExtractDelimitedPartW(Block.GetParamValue(Index), 1, ',');
      LanguageDataConfig.LoadFromTextFileWithEncodingProbe(PAnsiChar(AnsiString('cfg\' + Text + '\Main.txt')), False);
      LanguageDataConfig.SaveEncodedFile('CFG\' + Text + '.dat');
      LanguageDataConfig.Clear;
    end;
  end;
  if ExportDecodedResources then
  begin
    Block := InstallConfig.GetBlock('Lang');
    Index := Block.GetParamCount;
    for Index := 0 to Index - 1 do
    begin
      Text := ExtractDelimitedPartW(Block.GetParamValue(Index), 1, ',');
      LanguageDataConfig.LoadEncodedFile('CFG\' + Text + '.dat');
      LanguageDataConfig.SaveTextFile(PAnsiChar(AnsiString('CFG\' + Text + '_e.txt')), False);
      LanguageDataConfig.Clear;
    end;
  end;
  if not FileExists(AnsiString('CFG\' + ExtractDelimitedPartW(InstallConfig.GetParamByPath('Lang.' + CurrentLanguage), 1, ',') + '.dat')) then
    LanguageDataConfig.LoadFromTextFileWithEncodingProbe(PAnsiChar(AnsiString('cfg\' +
      ExtractDelimitedPartW(InstallConfig.GetParamByPath('Lang.' + CurrentLanguage), 1, ',') + '\Main.txt')), False)
  else
    LanguageDataConfig.LoadEncodedFile('CFG\' + ExtractDelimitedPartW(InstallConfig.GetParamByPath('Lang.' + CurrentLanguage), 1, ',') + '.dat');
  RootResourceData := TDataEC.Create;
  if GenerateEncodedResources or not FileExists('CFG\CacheData.dat') then
  begin
    RootResourceData.AddMissingFromBlock(MainDataConfig.GetBlockByPath('CacheData'));
    MainDataConfig.DeleteChildBlock('CacheData');
  end
  else RootResourceData.LoadEncodedFile('CFG\CacheData.dat');
  if GenerateEncodedResources then RootResourceData.SaveEncodedFile('CFG\CacheData.dat');
  if GenerateEncodedResources then MainDataConfig.SaveEncodedFile('CFG\Main.dat');
  if ExportDecodedResources then
  begin
    RootResourceData.WriteToBlock(MainDataConfig.AddChildBlock('CacheData'));
    MainDataConfig.SaveTextFile('CFG\main_e.txt', False);
  end;
  if FileExists('MusicChange.txt') then
  begin
    MainDataConfig.GetBlock('Music').Clear;
    MainDataConfig.GetBlock('Music').LoadFromTextFileWithEncodingProbe('MusicChange.txt', False);
  end;
  LoadAdditionalQuestPackages;
  RootResourceData.AddMissingFromBlock(LanguageDataConfig.GetBlockByPath('PlanetQuest'));
  GlobalCache := TCacheEC.Create;
  GlobalCache.SetDataRoot(RootResourceData);
  GlobalCache.ResidentByteLimit := 20; // Native uses bytes here, unlike the configured MB value.
  if Config.CountParams('CacheSize') > 0 then
    GlobalCache.ResidentByteLimit := (ExtractDigitsToIntW(Config.GetParamByPath('CacheSize')) shl 10) shl 10;
  Mode := TrimWideString(Config.GetParamByPath('VideoMode'));
  if Mode = 'R1' then
  begin
    GameScreenWidth := 800;
    GameScreenHeight := 600;
  end
  else
  begin
    GameScreenWidth := 1024;
    GameScreenHeight := 768;
  end;
  GameScreenRect := Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight);
  if Config.CountParams('RefreshRate') > 0 then
    PreferredRefreshRate := StrToInt(AnsiString(Config.GetParamByPath('RefreshRate')));
  if Config.CountParams('Brightness') > 0 then
    Brightness := ParseDecimalToSingleW(Config.GetParamByPath('Brightness'));
  if Config.CountParams('Contrast') > 0 then
    Contrast := ParseDecimalToSingleW(Config.GetParamByPath('Contrast'));
  if (GameScreenWidth = 800) and not IsInstallFeatureEnabled('Resolution_R1') then
    raise Exception.Create('Not installed 800x600');
  if (GameScreenWidth = 1024) and not IsInstallFeatureEnabled('Resolution_R2') then
    raise Exception.Create('Not installed 1024x768');
  if Config.CountParams('3D') > 0 then
    Direct3D8Enabled := ParseEnabledNameGI(Config.GetParamByPath('3D'));
  UiStyleConfig := MainDataConfig.GetBlockByPath('ML.' + Mode);
  GameDataConfig := MainDataConfig.GetBlockByPath('Data');
  UiDepthConfig := MainDataConfig.GetBlockByPath('ZPos');
  PlanetDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('Planet'));
  ShipPathDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathShip'));
  ShipPathEndDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathEndShip'));
  UnitPathDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPath'));
  UnitPathEndDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('UnitPathEnd'));
  ActionButtonDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ButtonAction'));
  GalaxyStarDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyStar'));
  GalaxyStarNameDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyStarName'));
  GalaxyWarDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('GalaxyWar'));
  ConstellationLineDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ConstellationLine'));
  ConstellationColorDepth := ExtractDecimalToSingleW(UiDepthConfig.GetParam('ConstellationColor'));
  if Config.CountParamsByPath('Sound') > 0 then
    SoundEnabled := ParseEnabledNameGI(Config.GetParamByPath('Sound'));
  if Config.CountParamsByPath('SoundInSpace') > 0 then
    SoundInSpaceEnabled := ParseEnabledNameGI(Config.GetParamByPath('SoundInSpace'));
  if Config.CountParamsByPath('SoundVolume') > 0 then
    SoundVolume := StrToInt(AnsiString(Config.GetParamByPath('SoundVolume'))) / 100;
  if SoundVolume > 1 then SoundVolume := 1;
  if SoundVolume < 0 then SoundVolume := 0;
  if not IsInstallFeatureEnabled('Sound') then SoundEnabled := False;
  if not IsInstallFeatureEnabled('SoundInSpace') then SoundInSpaceEnabled := False;
  if Config.CountParamsByPath('Music') > 0 then
    MusicEnabled := ParseEnabledNameGI(Config.GetParamByPath('Music'));
  if Config.CountParamsByPath('MusicInSpace') > 0 then
    MusicInSpace := ParseEnabledNameGI(Config.GetParamByPath('MusicInSpace'));
  if Config.CountParamsByPath('MusicInHyper') > 0 then
    MusicInHyper := ParseEnabledNameGI(Config.GetParamByPath('MusicInHyper'));
  if Config.CountParamsByPath('MusicInPlanet') > 0 then
    MusicInPlanet := ParseEnabledNameGI(Config.GetParamByPath('MusicInPlanet'));
  if Config.CountParamsByPath('MusicVolume') > 0 then
    MusicVolume := StrToInt(AnsiString(Config.GetParamByPath('MusicVolume'))) / 100;
  if MusicVolume > 1 then MusicVolume := 1;
  if MusicVolume < 0 then MusicVolume := 0;
  if not IsInstallFeatureEnabled('Music') then MusicEnabled := False;
  if not IsInstallFeatureEnabled('MusicInSpace') then MusicInSpace := False;
  Block := LanguageDataConfig.GetBlock('CaseConv');
  Index := Block.GetParamCount;
  SetLength(WideCaseTable, Index);
  for Index := 0 to Index - 1 do
  begin
    WideCaseTable[Index].LowerChar := Block.GetParamName(Index)[1];
    WideCaseTable[Index].UpperChar := Block.GetParamValue(Index)[1];
  end;
  AppendLogLineThreadSafe('Load CFG.... ok');
  ScreenCenterX := Cardinal(GameScreenWidth) shr 1;
  ScreenCenterY := Cardinal(GameScreenHeight) shr 1;
  if not WindowedRendering then
  begin
    SetWindowLong(MainWindowHandle, -16, Integer($80000000));
    SetWindowPos(MainWindowHandle, 0, 0, 0, 1, 1, $204);
  end
  else
  begin
    WindowRect.Left := 0;
    WindowRect.Top := 0;
    WindowRect.Right := GameScreenWidth;
    WindowRect.Bottom := GameScreenHeight;
    AdjustWindowRectEx(WindowRect, $C80000, False, 0);
    SetWindowLong(MainWindowHandle, -16, $C80000);
    SetWindowPos(MainWindowHandle, 0, 0, 0, WindowRect.Right - WindowRect.Left, WindowRect.Bottom - WindowRect.Top, $204);
  end;
  AppendLogLineThreadSafe('Create window.... ok');
  SoundManager := TSoundControl.Create;
  MusicManager := TMusicControl.Create;
  InitializeDirectDraw;
  ShowWindow(MainWindowHandle, 1);
  UpdateWindow(MainWindowHandle);
  SetFocus(MainWindowHandle);
  if not ShowSystemMouse then ShowCursor(False);
  AppendLogLineThreadSafe(AnsiString('Sound=' + BoolToWideString(SoundEnabled)));
  AppendLogLineThreadSafe(AnsiString('Music=' + BoolToWideString(MusicEnabled)));
  OKGF_AVI_Init;
  InterfaceBlendPalette := AllocEC(512);
  for Index := 0 to 255 do
  begin
    WriteWordEC(AddPointerOffset(InterfaceBlendPalette, 2 * Index), CurrentPixelFormat.PackRgbBytes(8, 32, 255));
    BlendPixel16(AddPointerOffset(InterfaceBlendPalette, 2 * Index), CurrentPixelFormat.PackRgbBytes(200, 128, 128), Index);
  end;
  if RecordingFrameBuffers <> nil then
  begin
    for Index := 0 to RecordingFrameBuffers.Count - 1 do FreeEC(RecordingFrameBuffers[Index]);
    RecordingFrameBuffers.Clear;
    RecordingFrameBuffers.Free;
    RecordingFrameBuffers := nil;
  end;
  if Config.CountParamsByPath('FilmBufSize') > 0 then
  begin
    BufferSize := ExtractDigitsToIntW(Config.GetParamByPath('FilmBufSize'));
    if BufferSize > 0 then
    begin
      RecordingFrameBuffers := TList.Create;
      Index := ((BufferSize shl 10) shl 10) div (GameScreenWidth * GameScreenHeight * 2) + 1;
      AppendLogLineThreadSafe('FilmFrame=' + IntToStr(Index));
      for Index := 0 to Index - 1 do
      begin
        Frame := AllocEC(GameScreenWidth * GameScreenHeight * 2);
        RecordingFrameBuffers.Add(Frame);
      end;
    end;
  end;
  if Config.CountParamsByPath('FilmFPS') > 0 then
    RecordingFrameInterval := 1000 div ExtractDigitsToIntW(Config.GetParamByPath('FilmFPS'));
  Block := MainDataConfig.GetBlockByPath('Graph.Cursor');
  for Index := 0 to Block.GetBlockCount - 1 do
  begin
    Cursor := AddCursorUnit;
    Cursor.Name := Block.GetBlockNameByIndex(Index);
    Cursor.ImagePath := Block.GetBlockByIndex(Index).GetParam('Image');
    Cursor.HotSpot := GetPointGI(Block.GetBlockByIndex(Index).GetParam('Sme'));
  end;
  if LanguageDataConfig.GetParamByPath('BV.BV') <> '1.7.2' then BuildVersionMismatch := True;
  if MainDataConfig.GetParamByPath('BV.BV') <> '1.7.2' then BuildVersionMismatch := True;
  if RootResourceData.FindEntry('BV').ChildData.FindEntry('BV').SharedFileRef.FileRef.FileName <> '1.7.2' then
    BuildVersionMismatch := True;
  if MainDataConfig.GetParamByPath('BV.EC') <> '' then
  begin
    SetLength(FileText, 260);
    // Failure exits the complete loader, including the final version-file check.
    if GetModuleFileName(0, PAnsiChar(FileText), 260) = 0 then Exit;
    SetLength(FileText, StrLen(PAnsiChar(FileText)));
    Buf := TBufEC.Create;
    Buf.LoadFromFilePath(PAnsiChar(FileText));
    if Trim(LowerCase(AnsiString(CardinalToHexWideString(Buf.ComputeCrc32)))) <>
      Trim(LowerCase(AnsiString(MainDataConfig.GetParamByPath('BV.EC')))) then
      BuildVersionMismatch := True;
    Buf.Free;
  end;
  VersionFile := TFileEC.Create;
  VersionFile.SetFileName('DATA\bv.dat');
  VersionFile.AcquireReadHandle;
  Index := VersionFile.GetSize;
  SetLength(FileText, Index);
  VersionFile.ReadBuffer(PAnsiChar(FileText), Index);
  VersionFile.Free;
  if TrimWideString(WideString(FileText)) <> '1.7.2' then BuildVersionMismatch := True;
  NotifyLoadingStage('GR_Init End');
end;
{ @end $4B1E3C }

{ @routine $4B46A0 FinalizeRuntimeAndSettings }
procedure FinalizeRuntimeAndSettings;
begin
  UnloadAdditionalQuestPackages;
  while FirstRegisteredCursor <> nil do RemoveCursorUnit(LastRegisteredCursor);
  if DirectDrawDevice <> nil then DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 8);
  if InterfaceBlendPalette <> nil then
  begin
    FreeEC(InterfaceBlendPalette);
    InterfaceBlendPalette := nil;
  end;
  OKGF_AVI_DeInit;
  if SoundManager <> nil then SoundManager.SignalStop;
  if MusicManager <> nil then
  begin
    MusicManager.Free;
    MusicManager := nil;
  end;
  if SoundManager <> nil then
  begin
    SoundManager.Free;
    SoundManager := nil;
  end;
  if GlobalCache <> nil then
  begin
    GlobalCache.Free;
    GlobalCache := nil;
  end;
  if RootResourceData <> nil then
  begin
    RootResourceData.Free;
    RootResourceData := nil;
  end;
  if LanguageDataConfig <> nil then
  begin
    LanguageDataConfig.Free;
    LanguageDataConfig := nil;
  end;
  GameDataConfig := nil;
  if MainDataConfig <> nil then
  begin
    MainDataConfig.Free;
    MainDataConfig := nil;
  end;
  if Config <> nil then
  begin
    Config.Free;
    Config := nil;
  end;
  ReleaseDirectDraw;
  if not WindowedRendering then SetWindowPos(MainWindowHandle, 0, 0, 0, 1, 1, $40);
  RedrawWindow(0, nil, 0, $787);
  WideCaseTable := nil;
end;
{ @end $4B46A0 }

{ @routine $4B480C EnumerateRefreshRate }
function EnumerateRefreshRate(const Desc: TDDSurfaceDesc; Context: Pointer): Integer; stdcall;
begin
  if Desc.PixelFormat.RGBBitCount = 16 then
    if GiResourceVariant = 1 then
    begin
      if (Desc.Width = 800) and (Desc.Height = 600) then
      begin
        AppendLogLineThreadSafe('Find RefreshRate ' + IntToStr(Desc.RefreshRate));
        HighestRefreshRate := Max(HighestRefreshRate, Desc.RefreshRate);
      end;
    end
    else if GiResourceVariant = 2 then
    begin
      if (Desc.Width = 1024) and (Desc.Height = 768) then
      begin
        AppendLogLineThreadSafe('Find RefreshRate ' + IntToStr(Desc.RefreshRate));
        HighestRefreshRate := Max(HighestRefreshRate, Desc.RefreshRate);
      end;
    end;
  Result := 1;
end;
{ @end $4B480C }

{ @routine $4B4940 ConfigureDirectDrawMode }
procedure ConfigureDirectDrawMode;
var Code, SavedRefreshRate: Integer;
begin
  if not WindowedRendering then
  begin
    Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 17);
    if (Code <> 0) and (Code <> -2005532091) then raise Exception.Create(DirectXErrorText(Code));
    if DirectDraw7Device = nil then
      Code := DirectDrawDevice.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16)
    else if PreferredRefreshRate = -1 then
    begin
      HighestRefreshRate := 0;
      Code := DirectDraw7Device.EnumDisplayModes(1, nil, nil, @EnumerateRefreshRate);
      if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
      Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, HighestRefreshRate, 0);
      if Code <> 0 then Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, 0, 0);
    end
    else
    begin
      SavedRefreshRate := PreferredRefreshRate;
      DirectDraw7Device.EnumDisplayModes(1, nil, nil, @EnumerateRefreshRate);
      PreferredRefreshRate := SavedRefreshRate;
      Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, PreferredRefreshRate, 0);
      if Code <> 0 then Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, 0, 0);
    end;
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end
  else
  begin
    Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 8);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end;
  if not WindowedRendering then
    if RestoreNormalCooperativeLevel then
    begin
      Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 8);
      if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
    end;
end;
{ @end $4B4940 }

{ @routine $4B4BA0 InitializeDirectDraw }
{$I-}
procedure InitializeDirectDraw;
var
  Create8: Pointer;
  MonitorFrequency: Cardinal;
  Identifier: TDDDeviceIdentifier;
  Desc: TDDSurfaceDesc;
  Caps: TDDCaps;
  Parameters: TD3DPresentParameters8;
  Code, SavedRefreshRate: Integer;
begin
  ReleaseDirectDraw;
  ScreenPresentBuffer := TGraphBufGR.Create;
  ScreenRenderBuffer := TGraphBufGR.Create;
  RenderScratchBuffer := TGraphBufGR.Create;
  AuxRenderBuffer := TGraphBufGR.Create;
  Code := DirectDrawCreate(nil, DirectDrawDevice, nil);
  if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  AppendLogLineThreadSafe('Create DirectDraw.... ok');
  ZeroMemory(@Caps, SizeOf(Caps));
  Caps.Size := SizeOf(Caps);
  Code := DirectDrawDevice.GetCaps(Caps, nil);
  if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  GammaRampCapable := Caps.Caps2 and $20000 = $20000;
  DirectDraw7Device := nil;
  Code := DirectDrawDevice.QueryInterface(IID_IDirectDraw7, DirectDraw7Device);
  if Code <> 0 then
  begin
    DirectDraw7Device := nil;
    AppendLogLineThreadSafe('Create DirectDraw7.... fail');
  end
  else AppendLogLineThreadSafe('Create DirectDraw7.... ok');
  if not WindowedRendering then
  begin
    Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 17);
    if (Code <> 0) and (Code <> -2005532091) then raise Exception.Create(DirectXErrorText(Code));
    if DirectDraw7Device = nil then
      Code := DirectDrawDevice.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16)
    else if PreferredRefreshRate = -1 then
    begin
      HighestRefreshRate := 0;
      Code := DirectDraw7Device.EnumDisplayModes(1, nil, nil, @EnumerateRefreshRate);
      if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
      Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, HighestRefreshRate, 0);
      if Code <> 0 then Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, 0, 0);
    end
    else
    begin
      SavedRefreshRate := PreferredRefreshRate;
      DirectDraw7Device.EnumDisplayModes(1, nil, nil, @EnumerateRefreshRate);
      PreferredRefreshRate := SavedRefreshRate;
      Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, PreferredRefreshRate, 0);
      if Code <> 0 then Code := DirectDraw7Device.SetDisplayMode(GameScreenWidth, GameScreenHeight, 16, 0, 0);
    end;
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end
  else
  begin
    Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 8);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end;
  ZeroMemory(@Desc, SizeOf(Desc));
  Desc.Size := SizeOf(Desc);
  Desc.Flags := 1;
  Desc.Caps := 512;
  Code := DirectDrawDevice.CreateSurface(Desc, PrimarySurface, nil);
  if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  ZeroMemory(@Desc, SizeOf(Desc));
  Desc.Size := SizeOf(Desc);
  Code := PrimarySurface.Lock(nil, Desc, 33, 0);
  if Code = 0 then PrimarySurface.Unlock(nil)
  else if Code = -2005532237 then
  begin
    PrimarySurface := nil;
    ZeroMemory(@Desc, SizeOf(Desc));
    Desc.Size := SizeOf(Desc);
    Desc.Flags := 1;
    Desc.Caps := 2560;
    Code := DirectDrawDevice.CreateSurface(Desc, PrimarySurface, nil);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end;
  if WindowedRendering then
  begin
    Code := DirectDrawDevice.CreateClipper(0, WindowClipper, nil);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
    Code := WindowClipper.SetHWnd(0, MainWindowHandle);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
    Code := PrimarySurface.SetClipper(WindowClipper);
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  end;
  if not WindowedRendering then
    if RestoreNormalCooperativeLevel then
    begin
      Code := DirectDrawDevice.SetCooperativeLevel(MainWindowHandle, 8);
      if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
    end;
  AppendLogLineThreadSafe('Create DirectDrawSurface.... ok');
  if DirectDraw7Device <> nil then
  begin
    ZeroMemory(@Identifier, SizeOf(Identifier));
    Code := DirectDraw7Device.GetDeviceIdentifier(Identifier, 0);
    if Code <> 0 then
    begin
      DirectDraw7Device := nil;
      raise Exception.Create(DirectXErrorText(Code));
    end;
    Append(SessionLog);
    Writeln(SessionLog, Format('Driver=%s', [PAnsiChar(@Identifier.Driver)]));
    Writeln(SessionLog, Format('Description=%s', [PAnsiChar(@Identifier.Description)]));
    CloseFile(SessionLog);
  end;
  Code := DirectDrawDevice.GetDisplayMode(Desc);
  if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  AppendLogLineThreadSafe('Resolution=' + IntToStr(Desc.Width) + 'x' + IntToStr(Desc.Height));
  AppendLogLineThreadSafe('RefreshRate=' + IntToStr(Desc.RefreshRate));
  if DirectDrawDevice.GetMonitorFrequency(MonitorFrequency) = 0 then
    AppendLogLineThreadSafe('MonitorFrequency=' + IntToStr(MonitorFrequency));
  Code := PrimarySurface.GetSurfaceDesc(Desc);
  if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
  Append(SessionLog);
  Writeln(SessionLog, Format('RGBBitCount=%d', [Desc.PixelFormat.RGBBitCount]));
  Writeln(SessionLog, Format('RBitMask=0x0%x', [Desc.PixelFormat.RedMask]));
  Writeln(SessionLog, Format('GBitMask=0x0%x', [Desc.PixelFormat.GreenMask]));
  Writeln(SessionLog, Format('BBitMask=0x0%x', [Desc.PixelFormat.BlueMask]));
  Writeln(SessionLog, Format('ABitMask=0x0%x', [Desc.PixelFormat.AlphaMask]));
  CloseFile(SessionLog);
  if Desc.PixelFormat.RGBBitCount <> 16 then raise Exception.Create('Error: Not 16bit video mode.');
  CurrentPixelFormat := TPixelFormatGR.Create;
  CurrentPixelFormat.RedMask := Desc.PixelFormat.RedMask;
  CurrentPixelFormat.GreenMask := Desc.PixelFormat.GreenMask;
  CurrentPixelFormat.BlueMask := Desc.PixelFormat.BlueMask;
  CurrentPixelFormat.AlphaMask := 0;
  CurrentPixelFormat.BytesPerPixel := Desc.PixelFormat.RGBBitCount shr 3;
  CurrentPixelFormat.RebuildChannelMetrics;
  if CurrentPixelFormat.TotalChannelBits = 15 then
  begin
    BlendPixel16 := @OKGR_PixelAlpha_15;
    TriangleRasterizer16 := @OKGF_Triangle_15;
    LineRasterizer16 := @OKGF_LineIp_15;
  end
  else
  begin
    BlendPixel16 := @OKGR_PixelAlpha_16;
    TriangleRasterizer16 := @OKGF_Triangle_16;
    LineRasterizer16 := @OKGF_LineIp_16;
  end;
  if ((CurrentPixelFormat.RedMask <> $F800) and (CurrentPixelFormat.RedMask <> $7C00)) or
    ((CurrentPixelFormat.GreenMask <> $7E0) and (CurrentPixelFormat.GreenMask <> $3E0)) or
    (CurrentPixelFormat.BlueMask <> $1F) then raise Exception.Create('Error: Not support video mode.');
  ScreenRenderBuffer.AllocateNativePitch(Desc.Width, Desc.Height, Desc.Pitch);
  if GiResourceVariant = 2 then RenderScratchBuffer.AllocateNative(156, 156)
  else RenderScratchBuffer.AllocateNative(122, 122);
  try
    Direct3D8Library := LoadLibrary('d3d8.dll');
    if Direct3D8Library = 0 then
    begin
      SuppressExceptionLogCopy := True;
      raise EAbort.Create('LoadLibrary');
    end;
    Create8 := GetProcAddress(Direct3D8Library, 'Direct3DCreate8');
    if Create8 = nil then
    begin
      SuppressExceptionLogCopy := True;
      raise EAbort.Create('GetProcAddress');
    end;
    asm
      mov eax, 120
      push eax
      mov eax, Create8
      call eax
      mov Direct3D8, eax
    end;
    if Direct3D8 = nil then
    begin
      SuppressExceptionLogCopy := True;
      raise EAbort.Create('Direct3DCreate8');
    end;
    Code := Direct3D8.GetAdapterDisplayMode(0, Direct3D8DisplayMode);
    if Code <> 0 then
    begin
      SuppressExceptionLogCopy := True;
      raise EAbort.Create('GetAdapterDisplayMode');
    end;
    ZeroMemory(@Parameters, SizeOf(Parameters));
    Parameters.Windowed := True;
    Parameters.SwapEffect := 1;
    Parameters.BackBufferFormat := Direct3D8DisplayMode.Format;
    Parameters.EnableAutoDepthStencil := True;
    Parameters.AutoDepthStencilFormat := 80;
    Code := Direct3D8.CreateDevice(0, 1, MainWindowHandle, 32, Parameters, Direct3D8Device);
    if Code <> 0 then
    begin
      SuppressExceptionLogCopy := True;
      raise EAbort.Create('CreateDevice');
    end;
    AppendLogLineThreadSafe('Create DirectX 8 .... ok');
  except
    on E: EAbort do
    begin
      Direct3D8Enabled := False;
      Direct3D8Device := nil;
      Direct3D8 := nil;
      if Direct3D8Library <> 0 then
      begin
        FreeLibrary(Direct3D8Library);
        Direct3D8Library := 0;
      end;
      AppendLogLineThreadSafe('Init DirectX 8.... fail  (' + E.Message + ')');
    end;
  end;
  GammaControl := nil;
  if GammaRampCapable then
  begin
    Code := PrimarySurface.QueryInterface(IID_IDirectDrawGammaControl, GammaControl);
    if Code <> 0 then GammaControl := nil
    else if GammaControl.GetGammaRamp(0, OriginalGammaRamp) <> 0 then GammaControl := nil;
  end;
  if GammaControl <> nil then
  begin
    ApplyGammaRamp(Brightness, Contrast);
    AppendLogLineThreadSafe('Create GammaControl .... ok');
  end
  else AppendLogLineThreadSafe('Create GammaControl .... fail');
end;
{$I+}
{ @end $4B4BA0 }

{ @routine $4B5BC8 ReleaseDirectDraw }
procedure ReleaseDirectDraw;
begin
  if GammaControl <> nil then GammaControl.SetGammaRamp(0, OriginalGammaRamp);
  GammaControl := nil;
  Direct3D8Device := nil;
  Direct3D8 := nil;
  if Direct3D8Library <> 0 then
  begin
    FreeLibrary(Direct3D8Library);
    Direct3D8Library := 0;
  end;
  if RenderScratchBuffer <> nil then
  begin
    RenderScratchBuffer.Free;
    RenderScratchBuffer := nil;
  end;
  if AuxRenderBuffer <> nil then
  begin
    AuxRenderBuffer.Free;
    AuxRenderBuffer := nil;
  end;
  if ScreenRenderBuffer <> nil then
  begin
    ScreenRenderBuffer.Free;
    ScreenRenderBuffer := nil;
  end;
  if ScreenPresentBuffer <> nil then
  begin
    ScreenPresentBuffer.Free;
    ScreenPresentBuffer := nil;
  end;
  WindowClipper := nil;
  PrimarySurface := nil;
  DirectDraw7Device := nil;
  DirectDrawDevice := nil;
  PresentationDepth := 0;
end;
{ @end $4B5BC8 }

{ @routine $4B5CB4 ApplyGammaRamp }
procedure ApplyGammaRamp(Brightness, Contrast: Single);
var
  Index, Value: Integer;
  LowInput, LowOutput, HighInput, HighOutput: Single;
  LowIndex, HighIndex: Integer;
  Level, Step: Single;
  Ramp: TDDGammaRamp;
begin
  if GammaControl = nil then Exit;
  if Brightness >= 0 then
  begin
    LowInput := 0;
    LowOutput := Brightness * 0.5;
    HighInput := 1 - Brightness * 0.5;
    HighOutput := 1;
  end
  else
  begin
    LowInput := -Brightness * 0.5;
    LowOutput := 0;
    HighInput := 1;
    HighOutput := 1 - -Brightness * 0.5;
  end;
  Step := (HighOutput - LowOutput) / (HighInput - LowInput);
  Level := (0.5 - LowInput) * Step + LowOutput;
  LowInput := LowInput + 0.4 * Contrast * Level;
  HighInput := HighInput - (1 - Level) * (0.4 * Contrast);
  LowIndex := Round(LowInput * 255);
  HighIndex := Round(HighInput * 255);
  Value := Round(Max(0, LowOutput) * 65535);
  for Index := 0 to LowIndex - 1 do
  begin
    Ramp[Index] := Value;
    Ramp[256 + Index] := Value;
    Ramp[512 + Index] := Value;
  end;
  Level := LowOutput;
  Step := (HighOutput - LowOutput) / (HighIndex - LowIndex);
  for Index := LowIndex to HighIndex - 1 do
  begin
    if (Index >= 0) and (Index <= 255) then
    begin
      Value := Round(Max(0, Level) * 65535);
      if Value < 0 then Value := 0
      else if Value > 65535 then Value := 65535;
      Ramp[Index] := Value;
      Ramp[256 + Index] := Value;
      Ramp[512 + Index] := Value;
    end;
    Level := Level + Step;
  end;
  Value := Round(Min(1.0, HighOutput) * 65535);
  for Index := HighIndex to 255 do
  begin
    Ramp[Index] := Value;
    Ramp[256 + Index] := Value;
    Ramp[512 + Index] := Value;
  end;
  if GammaControl.SetGammaRamp(0, Ramp) <> 0 then begin end;
end;
{ @end $4B5CB4 }

{ @routine $4B5F3C WinMessage }
function WinMessage(Callback: TWindowMessageCallbackGR): Integer;
var
  ContinueLoop: Integer;
  Position: TPoint;
  TimeDelta, KeyState: Cardinal;
  Text: WideString;
  Msg: TMsg;
  Elapsed, Consumed: Cardinal;
  Kind: TDemoEventKind;
begin
  if SoundManager <> nil then SoundManager.UpdateFades;
  ContinueLoop := 1;
  while True do
  begin
    if ExitScreenLoop then
    begin
      Result := 0;
      Exit;
    end;
    while Boolean(PeekMessage(Msg, 0, 0, 0, PM_REMOVE)) = True do
    begin
      TranslateMessage(Msg);
      if Msg.message = DebugCommandMessage then
      begin
        if Assigned(DebugCommandCallback) then DebugCommandCallback;
      end
      else if Msg.message = WM_QUIT then ContinueLoop := 0;
      DispatchMessage(Msg);
      if (Msg.hwnd = MainWindowHandle) and Assigned(Callback) and not DemoPlaying then
        Callback(Msg.message, Msg.wParam, Msg.lParam);
    end;
    if ContinueLoop = 0 then Break;
    if RuntimeActive then Break;
    WaitMessage;
  end;
  if DemoPlaying then
  begin
    Elapsed := timeGetTime - DemoLastEventTick;
    Consumed := 0;
    while True do
    begin
      Kind := Demo.PeekKind;
      if Kind = dekEnd then
      begin
        DemoPlaying := False;
        TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).ClearTransientControl;
        if ReturnToMainAfterDemo then
        begin
          RequestedScreenId := screenMainMenu;
          TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).RequestClose(1);
        end;
        Break;
      end
      else if Kind = dekMouseMove then
      begin
        if Elapsed < Demo.PeekTimeDelta + Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetMouseMove(TimeDelta, Position, KeyState);
        Inc(Consumed, TimeDelta);
        SetCursorPos(Position.X, Position.Y);
        Callback(WM_MOUSEMOVE, KeyState, Word(Position.X) or (Word(Position.Y) shl 16));
        MainWindowProc(MainWindowHandle, WM_MOUSEMOVE, KeyState,
          Word(Position.X) or (Word(Position.Y) shl 16));
      end
      else if Kind = dekMouseLDown then
      begin
        if Elapsed < Demo.PeekTimeDelta + Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetMouseLDown(TimeDelta, Position, KeyState);
        Inc(Consumed, TimeDelta);
        Callback(WM_LBUTTONDOWN, KeyState, Word(Position.X) or (Word(Position.Y) shl 16));
        MainWindowProc(MainWindowHandle, WM_LBUTTONDOWN, KeyState,
          Word(Position.X) or (Word(Position.Y) shl 16));
      end
      else if Kind = dekMouseLUp then
      begin
        { The native left-release test subtracts Consumed; other events add it. }
        if Elapsed < Demo.PeekTimeDelta - Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetMouseLUp(TimeDelta, Position, KeyState);
        Inc(Consumed, TimeDelta);
        Callback(WM_LBUTTONUP, KeyState, Word(Position.X) or (Word(Position.Y) shl 16));
        MainWindowProc(MainWindowHandle, WM_LBUTTONUP, KeyState,
          Word(Position.X) or (Word(Position.Y) shl 16));
      end
      else if Kind = dekMouseRDown then
      begin
        if Elapsed < Demo.PeekTimeDelta + Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetMouseRDown(TimeDelta, Position, KeyState);
        Inc(Consumed, TimeDelta);
        Callback(WM_RBUTTONDOWN, KeyState, Word(Position.X) or (Word(Position.Y) shl 16));
        MainWindowProc(MainWindowHandle, WM_RBUTTONDOWN, KeyState,
          Word(Position.X) or (Word(Position.Y) shl 16));
      end
      else if Kind = dekMouseRUp then
      begin
        if Elapsed < Demo.PeekTimeDelta + Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetMouseRUp(TimeDelta, Position, KeyState);
        Inc(Consumed, TimeDelta);
        Callback(WM_RBUTTONUP, KeyState, Word(Position.X) or (Word(Position.Y) shl 16));
        MainWindowProc(MainWindowHandle, WM_RBUTTONUP, KeyState,
          Word(Position.X) or (Word(Position.Y) shl 16));
      end
      else if Kind = dekGameLoad then
      begin
        RequestedScreenId := screenNone;
        TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).RequestClose(1);
        Break;
      end
      else if Kind = dekState then
      begin
        if Elapsed < Demo.PeekTimeDelta + Consumed then Break;
        DemoLastEventTick := timeGetTime;
        Demo.GetState(TimeDelta, Text, Position);
        Inc(Consumed, TimeDelta);
        if Text = '' then TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).ClearTransientControl
        else TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).ShowTransientText(Position, Text);
      end
      else Break;
    end;
  end;
  Result := ContinueLoop;
end;
{ @end $4B5F3C }
{ @routine $4B63C4 MainWindowProc }
function MainWindowProc(WindowHandle, Message, WParam: Cardinal; LParam: Integer): Integer; stdcall;
begin
  if Message = WM_DESTROY then
  begin
    if ExitScreenLoop then PostQuitMessage(0);
  end
  else if Message = WM_PAINT then
  begin
    if CurrentScreenId <> screenNone then
      if RuntimeActive then
      begin
        if VideoOverlaySurface <> nil then ClearPresentationScreen
        else if RuntimeActive then
          TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).Present;
      end;
  end
  else if Message = WM_MOUSEMOVE then
  begin
    if DemoRecording then
    begin
      Demo.AddMouseMove(timeGetTime - DemoLastEventTick,
        Classes.Point(Word(LParam), HiWord(LParam)), WParam);
      DemoLastEventTick := timeGetTime;
    end;
  end
  else if Message = WM_LBUTTONDOWN then
  begin
    if DemoRecording then
    begin
      Demo.AddMouseLDown(timeGetTime - DemoLastEventTick,
        Classes.Point(Word(LParam), HiWord(LParam)), WParam);
      DemoLastEventTick := timeGetTime;
    end;
  end
  else if Message = WM_LBUTTONUP then
  begin
    if DemoRecording then
    begin
      Demo.AddMouseLUp(timeGetTime - DemoLastEventTick,
        Classes.Point(Word(LParam), HiWord(LParam)), WParam);
      DemoLastEventTick := timeGetTime;
    end;
  end
  else if Message = WM_RBUTTONDOWN then
  begin
    if DemoRecording then
    begin
      Demo.AddMouseRDown(timeGetTime - DemoLastEventTick,
        Classes.Point(Word(LParam), HiWord(LParam)), WParam);
      DemoLastEventTick := timeGetTime;
    end;
  end
  else if Message = WM_RBUTTONUP then
  begin
    if DemoRecording then
    begin
      Demo.AddMouseRUp(timeGetTime - DemoLastEventTick,
        Classes.Point(Word(LParam), HiWord(LParam)), WParam);
      DemoLastEventTick := timeGetTime;
    end;
  end
  else if (Message = WM_SYSKEYDOWN) and
    (WParam in [VK_MENU, VK_LEFT..VK_DOWN]) then
  begin
    Result := 1;
    Exit;
  end
  else if (Message = WM_SYSKEYUP) and
    (WParam in [VK_MENU, VK_LEFT..VK_DOWN]) then
  begin
    Result := 1;
    Exit;
  end
  else if Message = WM_KEYDOWN then
  begin
    if not DemoPlaying and (WParam = Ord('R')) and IsVirtualKeyDown(VK_CONTROL) and
      IsVirtualKeyDown(VK_SHIFT) and IsVirtualKeyDown(VK_MENU) and (CurrentScreenId <> screenNone) then
    begin
      RequestedScreenId := screenNone;
      RestartScreenId := CurrentScreenId;
      TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).RequestClose(1);
    end
    else if DemoRecording and (WParam = Ord('S')) and IsVirtualKeyDown(VK_CONTROL) and
      IsVirtualKeyDown(VK_SHIFT) and IsVirtualKeyDown(VK_MENU) then
    begin
      Demo.AddState(timeGetTime - DemoLastEventTick,
        GetRegisteredScreenLoop(CurrentScreenId).ClassName, Classes.Point(0, 0));
      DemoLastEventTick := timeGetTime;
    end
    else if DemoPlaying and (WParam = VK_ESCAPE) then
    begin
      if ReturnToMainAfterDemo then Demo.SeekEnd
      else
      begin
        TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)).ClearTransientControl;
        DemoPlaying := False;
        Demo.Clear;
      end;
    end;
  end
  else if Message = WM_CLOSE then ExitScreenLoop := True
  else if Message = WM_CANCELMODE then RuntimeActive := False
  else if Message = WM_ACTIVATE then
  begin
    if (Word(WParam) = WA_ACTIVE) or (Word(WParam) = WA_CLICKACTIVE) then
    begin
      if HiWord(WParam) = 0 then
      begin
        RuntimeActive := True;
        if Assigned(OnWindowActivate) then OnWindowActivate;
      end;
    end
    else
    begin
      if DirectDrawDevice <> nil then DirectDrawDevice.FlipToGDISurface;
      RuntimeActive := False;
      { Native tests the activation callback before calling the deactivation
        callback. Preserve this mismatched guard, including a possible nil call. }
      if Assigned(OnWindowActivate) then OnWindowDeactivate;
    end;
  end;
  Result := DefWindowProc(WindowHandle, Message, WParam, LParam);
end;
{ @end $4B63C4 }

{ @routine $4B6878 BeginFramePresentation }
function BeginFramePresentation: Boolean;
var Desc: TDDSurfaceDesc; Code, DispatchCode: Cardinal; PreviousFlag: PMoneyIntegrityFlag; PreviousValue: Boolean;
begin
  Inc(PresentationDepth);
  if PresentationDepth = 1 then
  begin
    ZeroMemory(@Desc, SizeOf(Desc));
    Desc.Size := SizeOf(Desc);
    Code := $88760082;
    while True do
    begin
      Code := PrimarySurface.Lock(nil, Desc, 33, 0);
      DispatchCode := Code;
      if DispatchCode = 0 then Break
      else if DispatchCode = $887601C2 then
      begin
        Code := PrimarySurface.Restore;
        if Code = $8876024B then ConfigureDirectDrawMode
        else
        begin
          if Code <> 0 then Break;
          if CurrentScreenId <> screenNone then
            if RuntimeActive then FullFrameRedrawRequested := True;
        end;
      end
      else if DispatchCode = $8876021C then SysUtils.Sleep(10)
      else Break;
    end;
    if Code <> 0 then raise Exception.Create(DirectXErrorText(Code));
    ScreenPresentBuffer.AttachPixels(Desc.Width, Desc.Height, Desc.Pitch, Desc.Surface);
    PreviousFlag := PendingMoneyIntegrityFailure;
    PendingMoneyIntegrityFailure := nil;
    New(PendingMoneyIntegrityFailure);
    PreviousValue := PreviousFlag^;
    PendingMoneyIntegrityFailure^ := PreviousValue;
    PreviousFlag^ := True;
    Dispose(PreviousFlag);
  end;
  Result := True;
end;
{ @end $4B6878 }

{ @routine $4B69C4 EndFramePresentation }
procedure EndFramePresentation;
var Code, DispatchCode: Cardinal;
begin
  if PresentationDepth > 0 then
  begin
    Dec(PresentationDepth);
    if PresentationDepth = 0 then
    begin
      Code := PrimarySurface.Unlock(nil);
      DispatchCode := Code;
      if (DispatchCode <> 0) and (DispatchCode <> $88760248) then
        raise Exception.Create(DirectXErrorText(Code));
    end;
  end;
end;
{ @end $4B69C4 }

{ @routine $4B6A50 PresentScreenRect }
procedure PresentScreenRect(Rect: TRect);
var Dest: TPoint;
begin
  if WindowedRendering then
  begin
    Dest.X := Rect.Left;
    Dest.Y := Rect.Top;
    ClientToScreen(MainWindowHandle, Dest);
    BeginFramePresentation;
    OKGR_Copy_XY_XY_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes, Dest.X, Dest.Y,
      ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Rect.Left, Rect.Top, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
    EndFramePresentation;
  end
  else
  begin
    BeginFramePresentation;
    OKGR_Copy_XY_XY_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes, Rect.Left, Rect.Top,
      ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, Rect.Left, Rect.Top, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
    EndFramePresentation;
  end;
end;
{ @end $4B6A50 }

{ @routine $4B6B38 CaptureScreenBackground }
procedure CaptureScreenBackground;
begin
  AuxRenderBuffer.AllocateNativePitch(ScreenRenderBuffer.Width, ScreenRenderBuffer.Height, ScreenRenderBuffer.PitchBytes);
  CopyMemory(AuxRenderBuffer.Pixels, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.Height * ScreenRenderBuffer.PitchBytes);
end;
{ @end $4B6B38 }

{ @routine $4B6B78 DrawPresentationOverride }
procedure DrawPresentationOverride;
var Origin: TPoint; Band: TRect; Top, Bottom: Integer;
begin
  if ForcePresentationOverride or (timeGetTime - LastPresentationOverrideTick >= 100) then
  begin
    LastPresentationOverrideTick := timeGetTime;
    Origin := Classes.Point(0, 0);
    ClientToScreen(MainWindowHandle, Origin);
    Top := (GameScreenHeight shr 1) - (PresentationOverrideBuffer.Height shr 1);
    Bottom := PresentationOverrideBuffer.Height + Top;
    BeginFramePresentation;
    Band := Classes.Rect(Origin.X, Origin.Y, GameScreenWidth + Origin.X, (Top) + Origin.Y);
    if (Band.Right - Band.Left > 0) and (Band.Bottom - Band.Top > 0) then
      OKGR_Fill_WORD(Pointer(2 * Band.Left + Band.Top * ScreenPresentBuffer.PitchBytes + Integer(ScreenPresentBuffer.Pixels)),
        ScreenPresentBuffer.PitchBytes, Band.Right - Band.Left, Band.Bottom - Band.Top, 0);
    Band := Classes.Rect(Origin.X, Origin.Y + Bottom, GameScreenWidth + Origin.X, GameScreenHeight + Origin.Y);
    if (Band.Right - Band.Left > 0) and (Band.Bottom - Band.Top > 0) then
      OKGR_Fill_WORD(Pointer(2 * Band.Left + Band.Top * ScreenPresentBuffer.PitchBytes + Integer(ScreenPresentBuffer.Pixels)),
        ScreenPresentBuffer.PitchBytes, Band.Right - Band.Left, Band.Bottom - Band.Top, 0);
    if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGF_Convert_8888to565(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes,
        Origin.X, Origin.Y + Top, PresentationOverrideBuffer.Pixels, PresentationOverrideBuffer.PitchBytes,
        0, 0, PresentationOverrideBuffer.Width, PresentationOverrideBuffer.Height)
    else
      OKGF_Convert_8888to555(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes,
        Origin.X, Origin.Y + Top, PresentationOverrideBuffer.Pixels, PresentationOverrideBuffer.PitchBytes,
        0, 0, PresentationOverrideBuffer.Width, PresentationOverrideBuffer.Height);
    EndFramePresentation;
  end;
end;
{ @end $4B6B78 }

{ @routine $4B6D80 ClearPresentationScreen }
procedure ClearPresentationScreen;
var Origin: TPoint; Rect: TRect;
begin
  Origin := Classes.Point(0, 0);
  ClientToScreen(MainWindowHandle, Origin);
  BeginFramePresentation;
  Rect := Classes.Rect(Origin.X, Origin.Y, Origin.X + GameScreenWidth, Origin.Y + GameScreenHeight);
  OKGR_Fill_WORD(Pointer(2 * Rect.Left + Rect.Top * ScreenPresentBuffer.PitchBytes + Integer(ScreenPresentBuffer.Pixels)),
    ScreenPresentBuffer.PitchBytes, Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, 0);
  EndFramePresentation;
end;
{ @end $4B6D80 }

{ @routine $4B6E0C PresentVideoOverlay }
procedure PresentVideoOverlay;
var Width, Height, X, Y, ScreenHeight: Integer; SourceRect, DestRect: TRect; Origin: TPoint;
begin
  SourceRect.Left := 0;
  SourceRect.Top := 0;
  SourceRect.Right := VideoOverlayWidth;
  SourceRect.Bottom := VideoOverlayHeight;
  Origin := Classes.Point(0, 0);
  ClientToScreen(MainWindowHandle, Origin);
  Width := GameScreenWidth;
  X := 0;
  Height := Round(Cardinal(GameScreenWidth) * (VideoOverlayHeight / VideoOverlayWidth));
  ScreenHeight := GameScreenHeight;
  Y := ScreenHeight div 2 - Height div 2;
  if Height > ScreenHeight then
  begin
    Height := GameScreenHeight;
    Y := 0;
    Width := Round(Cardinal(GameScreenHeight) * (VideoOverlayWidth / VideoOverlayHeight));
    X := GameScreenWidth div 2 - Width div 2;
  end;
  DestRect.Left := X + Origin.X;
  DestRect.Top := Y + Origin.Y;
  DestRect.Right := X + Origin.X + Width;
  DestRect.Bottom := Y + Origin.Y + Height;
  VideoOverlaySurface.UpdateOverlay(@SourceRect, VideoPrimarySurface, @DestRect, VideoOverlayFlags, @VideoOverlayFX);
end;
{ @end $4B6E0C }

{ @routine $4B6F34 CaptureSavePreview }
procedure CaptureSavePreview;
var Frame: TGraphBufGR;
begin
  FreeSavePreviewBuffer;
  SavePreviewGraph := TGraphBufGR.Create;
  SavePreviewGraph.AllocateNativePitch(300, 225, 900);
  Frame := TGraphBufGR.Create;
  Frame.AllocateNativePitch(ScreenRenderBuffer.Width, ScreenRenderBuffer.Height, ScreenRenderBuffer.Width * 3);
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGF_Convert565toRGB(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Frame.Pixels, Frame.PitchBytes, Frame.Width, Frame.Height)
  else
    OKGF_Convert555toRGB(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Frame.Pixels, Frame.PitchBytes, Frame.Width, Frame.Height);
  OKGF_Rescale(SavePreviewGraph.Pixels, 300, 225, SavePreviewGraph.PitchBytes,
    Frame.Pixels, Frame.Width, Frame.Height, Frame.PitchBytes, 3, 5);
  Frame.Free;
end;
{ @end $4B6F34 }

{ @routine $4B7034 FreeSavePreviewBuffer }
procedure FreeSavePreviewBuffer;
begin
  if SavePreviewGraph <> nil then
  begin
    SavePreviewGraph.Free;
    SavePreviewGraph := nil;
  end;
end;
{ @end $4B7034 }

{ @routine $4B7050 CaptureRecordingFrame }
procedure CaptureRecordingFrame;
begin
  if timeGetTime - LastRecordingFrameTick >= RecordingFrameInterval then
  begin
    OKGR_Copy_XY_XY_WORD(RecordingFrameBuffers[RecordingFrameCount], GameScreenWidth * 2,
      0, 0, ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      0, 0, GameScreenWidth, GameScreenHeight);
    Inc(RecordingFrameCount);
    if RecordingFrameCount >= RecordingFrameBuffers.Count then FlushRecordingFrames;
    LastRecordingFrameTick := timeGetTime;
  end;
end;
{ @end $4B7050 }

{ @routine $4B70D0 FlushRecordingFrames }
procedure FlushRecordingFrames;
var
  SearchHandle: THandle;
  FirstFrameNumber, Index: Integer;
  Directory: AnsiString;
  Frame: TGraphBufGR;
  FileName: AnsiString;
  FindData: TWin32FindDataA;
begin
  if RecordingFrameCount >= 1 then
  begin
    Directory := GetCurrentDir;
    SetCurrentDir('Film');
    FirstFrameNumber := -1;
    SearchHandle := Windows.FindFirstFile('*.*', FindData);
    // Native code scans without testing for INVALID_HANDLE_VALUE.
    repeat
      if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> FILE_ATTRIBUTE_DIRECTORY then
        FirstFrameNumber := Max(FirstFrameNumber, ExtractDigitsToIntW(WideString(AnsiString(FindData.cFileName))));
    until not Boolean(Windows.FindNextFile(SearchHandle, FindData));
    Windows.FindClose(SearchHandle);
    SetCurrentDir(Directory);
    Inc(FirstFrameNumber);
    Frame := TGraphBufGR.Create;
    Frame.AllocateNativePitch(ScreenRenderBuffer.Width, ScreenRenderBuffer.Height, ScreenRenderBuffer.Width * 3);
    for Index := 0 to RecordingFrameCount - 1 do
    begin
      if CurrentPixelFormat.TotalChannelBits = 16 then
        OKGF_Convert565toBGR(RecordingFrameBuffers[Index], GameScreenWidth * 2,
          Frame.Pixels, Frame.PitchBytes, Frame.Width, Frame.Height)
      else
        OKGF_Convert555toBGR(RecordingFrameBuffers[Index], GameScreenWidth * 2,
          Frame.Pixels, Frame.PitchBytes, Frame.Width, Frame.Height);
      FileName := AnsiString('Film\' + IntToFixedWidthWideString(FirstFrameNumber + Index, 6) + '.bmp');
      OKGF_Write_BMP_File(PAnsiChar(FileName), Frame.Pixels, Frame.PitchBytes,
        24, $FF, $FF00, $FF0000, 0, Frame.Width, Frame.Height);
    end;
    Frame.Free;
    RecordingFrameCount := 0;
  end;
end;
{ @end $4B70D0 }

{ @routine $4B7368 NotifyLoadingStage }
procedure NotifyLoadingStage(const Stage: WideString);
begin
end;
{ @end $4B7368 }

{ @routine $4B736C DrawTransparentBuffer16 }
procedure DrawTransparentBuffer16(Dest: Pointer; Pitch, X, Y: Integer; Source: Pointer; Clip: TRect; HalfAlpha: Boolean);
var InclusiveClip: TRect;
begin
  InclusiveClip.Left := Clip.Left; InclusiveClip.Top := Clip.Top;
  InclusiveClip.Right := Clip.Right - 1; InclusiveClip.Bottom := Clip.Bottom - 1;
  if HalfAlpha then
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_TransBuf_HADrawClip_16(Dest, Pitch, X, Y, Source, InclusiveClip)
    else OKGR_TransBuf_HADrawClip_15(Dest, Pitch, X, Y, Source, InclusiveClip);
  end
  else OKGR_TransBuf_DrawClip_WORD(Dest, Pitch, X, Y, Source, InclusiveClip);
end;
{ @end $4B736C }

// Operand parentheses in these clipping routines preserve D7's native MOV/ADD evaluation.
{ @routine $4B73F4 CopyPalettedBuffer16Clipped }
procedure CopyPalettedBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source, Palette: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect);
var SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or ((Width) + X - 1 < Clip.Left) or ((Height) + Y - 1 < Clip.Top) then Exit;
  SourceX := 0; SourceY := 0;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if (Height) + Y - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X; Dec(Width, SourceX); X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y; Dec(Height, SourceY); Y := Clip.Top;
  end;
  OKGR_PalCopy_XY_XY_WORD(Dest, DestPitch, X, Y, Source, SourcePitch, SourceX, SourceY, Palette, Width, Height);
end;
{ @end $4B73F4 }

{ @routine $4B74D4 CopyGraphBuffer16Clipped }
procedure CopyGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect; HalfAlpha, UnusedOption: Boolean);
var SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or
    (Source.Width + X - 1 < Clip.Left) or (Source.Height + Y - 1 < Clip.Top) then Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  if HalfAlpha then
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_HACopy_XY_XY_16(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height)
    else OKGR_HACopy_XY_XY_15(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height);
  end
  else OKGR_Copy_XY_XY_WORD(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height);
end;
{ @end $4B74D4 }

{ @routine $4B7624 CopyBuffer16Clipped }
procedure CopyBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect; UnusedOption: Boolean);
var SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or ((Width) + X - 1 < Clip.Left) or ((Height) + Y - 1 < Clip.Top) then Exit;
  SourceX := 0; SourceY := 0;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if (Height) + Y - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X; Dec(Width, SourceX); X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y; Dec(Height, SourceY); Y := Clip.Top;
  end;
  OKGR_Copy_XY_XY_WORD(Dest, DestPitch, X, Y, Source, SourcePitch, SourceX, SourceY, Width, Height);
end;
{ @end $4B7624 }

{ @routine $4B7700 CopyTransparentGraphBuffer16Clipped }
procedure CopyTransparentGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect; TransparentColor: Word);
var SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or
    (Source.Width + X - 1 < Clip.Left) or (Source.Height + Y - 1 < Clip.Top) then Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  OKGR_CopyTrans_XY_XY_WORD(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height, TransparentColor);
end;
{ @end $4B7700 }

{ @routine $4B77F4 DrawAlphaGraphBuffer16Clipped }
procedure DrawAlphaGraphBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufGR; Clip: TRect);
var SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or
    (Source.Width + X - 1 < Clip.Left) or (Source.Height + Y - 1 < Clip.Top) then Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaSimpleBuf_Draw_16(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height)
    else OKGR_AlphaSimpleBuf_Draw_15(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height);
  end;
end;
{ @end $4B77F4 }

{ @routine $4B7918 DrawAlphaBuffer16Clipped }
procedure DrawAlphaBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: Pointer; SourcePitch, Width, Height: Integer; Clip: TRect);
var SourceX, SourceY: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or ((Width) + X - 1 < Clip.Left) or ((Height) + Y - 1 < Clip.Top) then Exit;
  SourceX := 0; SourceY := 0;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if (Height) + Y - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X; Dec(Width, SourceX); X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y; Dec(Height, SourceY); Y := Clip.Top;
  end;
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then OKGR_AlphaSimpleBuf_Draw_16(Dest, DestPitch, X, Y, Source, SourcePitch, SourceX, SourceY, Width, Height)
    else OKGR_AlphaSimpleBuf_Draw_15(Dest, DestPitch, X, Y, Source, SourcePitch, SourceX, SourceY, Width, Height);
  end;
end;
{ @end $4B7918 }

{ @routine $4B7A28 DrawPaletteAlphaBuffer16Clipped }
procedure DrawPaletteAlphaBuffer16Clipped(Dest: Pointer; DestPitch, X, Y: Integer; Source: TGraphBufPalGR; Clip: TRect);
var SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or
    (Source.Width + X - 1 < Clip.Left) or (Source.Height + Y - 1 < Clip.Top) then Exit;
  SourceX := 0;
  SourceY := 0;
  Width := Source.Width;
  Height := Source.Height;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  if CurrentPixelFormat.TotalChannelBits = 16 then
  OKGR_AlphaSimpleBufPalAlpha_Draw_16(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height, Source.Palette)
  else
  OKGR_AlphaSimpleBufPalAlpha_Draw_15(Dest, DestPitch, X, Y, Source.Pixels, Source.PitchBytes, SourceX, SourceY, Width, Height, Source.Palette);
end;
{ @end $4B7A28 }

{ @routine $4B7B54 DrawGradientLine16Clipped }
procedure DrawGradientLine16Clipped(Pixels: Pointer; Pitch, X1, Y1: Integer; Color1: Cardinal; X2, Y2: Integer; Color2: Cardinal; Clip: TRect);
begin
  if OKGR_LineColor_Clip(X1, Y1, Color1, X2, Y2, Color2, Clip) <> 0 then
    LineRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      X1, Y1, Color1, X2, Y2, Color2);
end;
{ @end $4B7B54 }

{ @routine $4B7BCC IsVirtualKeyDown }
function IsVirtualKeyDown(Key: Integer): Boolean;
begin
  Result := GetAsyncKeyState(Key) and $8000 = $8000;
end;
{ @end $4B7BCC }

{ @routine $4B7BE8 LookupLocalizedTextByKey }
function LookupLocalizedTextByKey(const Path: WideString): WideString;
begin
  Result := LanguageDataConfig.GetParamByPath(Path);
end;
{ @end $4B7BE8 }

{ @routine $4B7C00 LookupLocalizedTextOrEmpty }
function LookupLocalizedTextOrEmpty(const Path: WideString): WideString;
begin
  if LanguageDataConfig.CountParamsByPath(Path) > 0 then Result := LanguageDataConfig.GetParamByPath(Path)
  else Result := '';
end;
{ @end $4B7C00 }

{ @routine $4B7C34 LookupLocalizedTextLines }
function LookupLocalizedTextLines(const Path: WideString): WideString;
var Index: Integer;
begin
  Result := '';
  for Index := 0 to LanguageDataConfig.CountParamsByPath(Path) - 1 do
  begin
    if Result <> '' then Result := Result + #13#10;
    Result := Result + LanguageDataConfig.GetParamByPath(Path + ':' + IntToStr(Index));
  end;
end;
{ @end $4B7C34 }

{ @routine $4B7D1C GiResourceVariant }
function GiResourceVariant: Integer;
begin
  if GameScreenWidth = 1024 then Result := 2 else Result := 1;
end;
{ @end $4B7D1C }

{ @routine $4B7D34 GiResourceSuffix }
function GiResourceSuffix: WideString;
begin
  if GameScreenWidth = 1024 then Result := '2' else Result := '1';
end;
{ @end $4B7D34 }

{ @routine $4B7D70 GiScalePixels }
function GiScalePixels(Value: Integer): Integer;
begin
  if GameScreenWidth = 800 then Value := Round(Value * 800.0 / 1024.0);
  Result := Value;
end;
{ @end $4B7D70 }

{ @routine $4B7DA8 PackArgbFloats }
function PackArgbFloats(Alpha, Red, Green, Blue: Single): Cardinal;
begin
  Result := (Integer(Round(Alpha * 255)) and $FF) shl 24 or
    (Integer(Round(Red * 255)) and $FF) shl 16 or
    (Integer(Round(Green * 255)) and $FF) shl 8 or
    (Integer(Round(Blue * 255)) and $FF);
end;
{ @end $4B7DA8 }

{ @routine $4B7E18 AppendLogLineThreadSafe }
{$I-}
procedure AppendLogLineThreadSafe(const Text: AnsiString);
begin
  if SessionLogLock = nil then SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  Append(SessionLog);
  Writeln(SessionLog, Text);
  CloseFile(SessionLog);
  SessionLogLock.Leave;
end;
{$I+}
{ @end $4B7E18 }

{ @routine $4B7E70 AppendLogTextThreadSafe }
{$I-}
procedure AppendLogTextThreadSafe(const Text: AnsiString);
begin
  if SessionLogLock = nil then SessionLogLock := TCriticalSection.Create;
  SessionLogLock.Enter;
  Append(SessionLog);
  Write(SessionLog, Text);
  CloseFile(SessionLog);
  SessionLogLock.Leave;
end;
{$I+}
{ @end $4B7E70 }

{ @routine $4B7EC8 AppendOptionalDebugLogLine }
{$I-}
procedure AppendOptionalDebugLogLine(const Text: AnsiString);
var Log: TextFile;
begin
  if FileExists('#####add.log') then
  begin
    if SessionLogLock = nil then SessionLogLock := TCriticalSection.Create;
    SessionLogLock.Enter;
    AssignFile(Log, '#####add.log');
    Append(Log);
    Writeln(Log, Text);
    CloseFile(Log);
    SessionLogLock.Leave;
  end;
end;
{$I+}
{ @end $4B7EC8 }

{ @routine $4B7F58 IsInstallFeatureEnabled }
function IsInstallFeatureEnabled(const Name: WideString): Boolean;
begin
  if InstallConfig.CountParamsByPath(Name) < 1 then Result := False
  else Result := ParseEnabledNameGI(InstallConfig.GetParamByPath(Name));
end;
{ @end $4B7F58 }

{ @routine $4B7FC0 AddCursorUnit }
function AddCursorUnit: TCursorUnit;
var Cursor: TCursorUnit;
begin
  Cursor := TCursorUnit.Create;
  if LastRegisteredCursor <> nil then LastRegisteredCursor.Next := Cursor;
  Cursor.Prev := LastRegisteredCursor;
  Cursor.Next := nil;
  LastRegisteredCursor := Cursor;
  if FirstRegisteredCursor = nil then FirstRegisteredCursor := Cursor;
  Result := Cursor;
end;
{ @end $4B7FC0 }

{ @routine $4B8000 RemoveCursorUnit }
procedure RemoveCursorUnit(Cursor: TCursorUnit);
begin
  if Cursor.Prev <> nil then Cursor.Prev.Next := Cursor.Next;
  if Cursor.Next <> nil then Cursor.Next.Prev := Cursor.Prev;
  if LastRegisteredCursor = Cursor then LastRegisteredCursor := Cursor.Prev;
  if FirstRegisteredCursor = Cursor then FirstRegisteredCursor := Cursor.Next;
  Cursor.Free;
end;
{ @end $4B8000 }

{ @routine $4B8044 FindCursorByName }
function FindCursorByName(const Name: WideString): TCursorUnit;
var Cursor: TCursorUnit;
begin
  Cursor := FirstRegisteredCursor;
  while Cursor <> nil do
  begin
    if Cursor.Name = Name then
    begin
      Result := Cursor;
      Exit;
    end;
    Cursor := Cursor.Next;
  end;
  raise Exception.Create('GR_CursorFind');
end;
{ @end $4B8044 }

{ @routine $4B809C PostMouseMoveMessage }
procedure PostMouseMoveMessage;
var
  Point: TPoint;
begin
  GetCursorPos(Point);
  ScreenToClient(MainWindowHandle, Point);
  PostMessage(MainWindowHandle, WM_MOUSEMOVE, 0, SmallInt(Point.X) or (SmallInt(Point.Y) shl 16));
end;
{ @end $4B809C }

{ @routine $4B80D8 MeasureCpuClockMHz }
function MeasureCpuClockMHz: Double;
var TickLow, TickHigh: Cardinal; ProcessPriority: Cardinal; ThreadPriority: Integer;
begin
  ProcessPriority := GetPriorityClass(GetCurrentProcess);
  ThreadPriority := GetThreadPriority(GetCurrentThread);
  SetPriorityClass(GetCurrentProcess, REALTIME_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
  try
    SysUtils.Sleep(10);
    // The native timestamp reads and 64-bit subtraction are handwritten asm.
    asm
      rdtsc
      mov TickLow, eax
      mov TickHigh, edx
    end;
    SysUtils.Sleep(200);
    asm
      rdtsc
      sub eax, TickLow
      sbb edx, TickHigh
      mov TickLow, eax
      mov TickHigh, edx
    end;
    Result := TickLow / 200000;
  except
    Result := 1500;
  end;
  SetThreadPriority(GetCurrentThread, ThreadPriority);
  SetPriorityClass(GetCurrentProcess, ProcessPriority);
end;
{ @end $4B80D8 }

{ @routine $4B81B4 ReadRegistryText }
function ReadRegistryText(Root: Cardinal; KeyPath, ValueName, DefaultValue: WideString): WideString;
var Key: HKey; ValueType: Cardinal; Data: Pointer; ByteCount: Cardinal;
begin
  if RegOpenKeyExA(Root, PAnsiChar(AnsiString(KeyPath)), 0, KEY_READ, Key) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    Exit;
  end;

  ByteCount := 2048;
  Data := AllocEC(ByteCount);
  if RegQueryValueExA(Key, PAnsiChar(AnsiString(ValueName)), nil, @ValueType, PByte(Data), @ByteCount) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    RegCloseKey(Key);
    FreeEC(Data);
    Exit;
  end;

  if ValueType <> REG_SZ then Result := DefaultValue
  else Result := PAnsiChar(Data);
  FreeEC(Data);
  RegCloseKey(Key);
end;
{ @end $4B81B4 }

{ @routine $4B82F4 ReadRegistryInteger }
function ReadRegistryInteger(Root: Cardinal; KeyPath, ValueName: WideString; DefaultValue: Integer): Integer;
var Key: HKey; ValueType: Cardinal; Value: Integer; ByteCount: Cardinal;
begin
  if RegOpenKeyExA(Root, PAnsiChar(AnsiString(KeyPath)), 0, KEY_READ, Key) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    Exit;
  end;

  ByteCount := 4;
  if RegQueryValueExA(Key, PAnsiChar(AnsiString(ValueName)), nil, @ValueType, @Value, @ByteCount) <> ERROR_SUCCESS then
  begin
    Result := DefaultValue;
    RegCloseKey(Key);
    Exit;
  end;

  if ValueType <> REG_DWORD then Result := DefaultValue
  else Result := Value;
  RegCloseKey(Key);
end;
{ @end $4B82F4 }

{ @routine $4B83E4 RaiseWideMessage }
procedure RaiseWideMessage(const Message: WideString);
begin
  raise Exception.Create(Message);
end;
{ @end $4B83E4 }
end.

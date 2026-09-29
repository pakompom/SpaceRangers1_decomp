unit GR_DirectX;
// Unit bracket (inferred): CODE 0x00453F54..0x00455C13; inclusive evidence, not full bounds.
// DirectDraw/DirectSound declarations and HRESULT formatter.
// Native interface RTTI names GR_DirectX at $453F54, $453F8C and $453FC8.
interface

uses Types;

type
  PDDRect = ^TRect;
  TDDPixelFormat = record // @size $20
    Size: Cardinal; // @offset $00
    Flags: Cardinal; // @offset $04
    FourCC: Cardinal; // @offset $08
    RGBBitCount: Cardinal; // @offset $0C
    RedMask: Cardinal; // @offset $10
    GreenMask: Cardinal; // @offset $14
    BlueMask: Cardinal; // @offset $18
    AlphaMask: Cardinal; // @offset $1C
  end;
  TDDSurfaceDesc = record // @size $6C
    Size: Cardinal; // @offset $00
    Flags: Cardinal; // @offset $04
    Height: Cardinal; // @offset $08
    Width: Cardinal; // @offset $0C
    Pitch: Integer; // @offset $10
    BackBufferCount: Cardinal; // @offset $14
    RefreshRate: Cardinal; // @offset $18
    AlphaBitDepth: Cardinal; // @offset $1C
    Reserved: Cardinal; // @offset $20
    Surface: Pointer; // @offset $24
    ColorKeys: array[0..7] of Cardinal; // @offset $28
    PixelFormat: TDDPixelFormat; // @offset $48
    Caps: Cardinal; // @offset $68
  end;
  PDDSurfaceDesc = ^TDDSurfaceDesc;
  TDDCaps = record // @size $17C
    Size: Cardinal; // @offset $00
    Caps: Cardinal; // @offset $04
    Caps2: Cardinal; // @offset $08
    CKeyCaps: Cardinal; // @offset $0C
    FXCaps: Cardinal; // @offset $10
    BeforeAlignSizeSrc: array[0..15] of Cardinal; // @offset $14
    AlignSizeSrc: Cardinal; // @offset $54
    Remaining: array[0..72] of Cardinal; // @offset $58
  end;
  TDDOverlayFX = record // @size $38
    Size: Cardinal; // @offset $00
    Reserved: array[0..11] of Cardinal; // @offset $04
    Flags: Cardinal; // @offset $34
  end;
  PDDOverlayFX = ^TDDOverlayFX;
  TDDGammaRamp = array[0..767] of Word;
  TDDDeviceIdentifier = record // @size $430
    Driver: array[0..511] of AnsiChar; // @offset $00
    Description: array[0..511] of AnsiChar; // @offset $200
    Remaining: array[0..47] of Byte; // @offset $400
  end;
  // The mode callback reads only the common descriptor prefix, through RGBBitCount.
  TDDEnumModesCallback = function(const Desc: TDDSurfaceDesc; Context: Pointer): Integer; stdcall;
  IDirectDrawSurface = interface;
  IDirectDrawClipper = interface;
  IDirectDraw = interface(IInterface)
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    function CreateClipper(Flags: Cardinal; out Clipper: IDirectDrawClipper; Outer: IInterface): Integer; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    function CreateSurface(const Desc: TDDSurfaceDesc; out Surface: IDirectDrawSurface; Outer: IInterface): Integer; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    function EnumDisplayModes(Flags: Cardinal; Desc: PDDSurfaceDesc; Context: Pointer; Callback: TDDEnumModesCallback): Integer; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    function FlipToGDISurface: Integer; stdcall; // slot $28
    function GetCaps(var DriverCaps: TDDCaps; EmulationCaps: Pointer): Integer; stdcall; // slot $2C
    function GetDisplayMode(var Desc: TDDSurfaceDesc): Integer; stdcall; // slot $30
    procedure UnrecoveredSlot34; stdcall; // slot $34
    procedure UnrecoveredSlot38; stdcall; // slot $38
    function GetMonitorFrequency(var Frequency: Cardinal): Integer; stdcall; // slot $3C
    procedure UnrecoveredSlot40; stdcall; // slot $40
    procedure UnrecoveredSlot44; stdcall; // slot $44
    procedure UnrecoveredSlot48; stdcall; // slot $48
    procedure UnrecoveredSlot4C; stdcall; // slot $4C
    function SetCooperativeLevel(Window, Flags: Cardinal): Integer; stdcall; // slot $50
    function SetDisplayMode(Width, Height, BitsPerPixel: Cardinal): Integer; stdcall; // slot $54
    procedure UnrecoveredSlot58; stdcall; // slot $58
  end;
  IDirectDraw7 = interface(IInterface)
    ['{15E65EC0-3B9C-11D2-B92F-00609797EA5B}']
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    function EnumDisplayModes(Flags: Cardinal; Desc: PDDSurfaceDesc; Context: Pointer; Callback: TDDEnumModesCallback): Integer; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    procedure UnrecoveredSlot28; stdcall; // slot $28
    procedure UnrecoveredSlot2C; stdcall; // slot $2C
    procedure UnrecoveredSlot30; stdcall; // slot $30
    procedure UnrecoveredSlot34; stdcall; // slot $34
    procedure UnrecoveredSlot38; stdcall; // slot $38
    procedure UnrecoveredSlot3C; stdcall; // slot $3C
    procedure UnrecoveredSlot40; stdcall; // slot $40
    procedure UnrecoveredSlot44; stdcall; // slot $44
    procedure UnrecoveredSlot48; stdcall; // slot $48
    procedure UnrecoveredSlot4C; stdcall; // slot $4C
    procedure UnrecoveredSlot50; stdcall; // slot $50
    function SetDisplayMode(Width, Height, BitsPerPixel, RefreshRate, Flags: Cardinal): Integer; stdcall; // slot $54
    procedure UnrecoveredSlot58; stdcall; // slot $58
    procedure UnrecoveredSlot5C; stdcall; // slot $5C
    procedure UnrecoveredSlot60; stdcall; // slot $60
    procedure UnrecoveredSlot64; stdcall; // slot $64
    procedure UnrecoveredSlot68; stdcall; // slot $68
    function GetDeviceIdentifier(var Identifier: TDDDeviceIdentifier; Flags: Cardinal): Integer; stdcall; // slot $6C
    procedure UnrecoveredSlot70; stdcall; // slot $70
    procedure UnrecoveredSlot74; stdcall; // slot $74
  end;
  IDirectDrawSurface = interface(IInterface)
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    procedure UnrecoveredSlot20; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    procedure UnrecoveredSlot28; stdcall; // slot $28
    procedure UnrecoveredSlot2C; stdcall; // slot $2C
    procedure UnrecoveredSlot30; stdcall; // slot $30
    procedure UnrecoveredSlot34; stdcall; // slot $34
    procedure UnrecoveredSlot38; stdcall; // slot $38
    procedure UnrecoveredSlot3C; stdcall; // slot $3C
    procedure UnrecoveredSlot40; stdcall; // slot $40
    procedure UnrecoveredSlot44; stdcall; // slot $44
    procedure UnrecoveredSlot48; stdcall; // slot $48
    procedure UnrecoveredSlot4C; stdcall; // slot $4C
    procedure UnrecoveredSlot50; stdcall; // slot $50
    procedure UnrecoveredSlot54; stdcall; // slot $54
    function GetSurfaceDesc(var Desc: TDDSurfaceDesc): Integer; stdcall; // slot $58
    procedure UnrecoveredSlot5C; stdcall; // slot $5C
    procedure UnrecoveredSlot60; stdcall; // slot $60
    function Lock(Rect: Pointer; var Desc: TDDSurfaceDesc; Flags, Event: Cardinal): Integer; stdcall; // slot $64
    procedure UnrecoveredSlot68; stdcall; // slot $68
    function Restore: Integer; stdcall; // slot $6C
    function SetClipper(Clipper: IDirectDrawClipper): Integer; stdcall; // slot $70
    procedure UnrecoveredSlot74; stdcall; // slot $74
    procedure UnrecoveredSlot78; stdcall; // slot $78
    procedure UnrecoveredSlot7C; stdcall; // slot $7C
    function Unlock(Surface: Pointer): Integer; stdcall; // slot $80
    function UpdateOverlay(SourceRect: PDDRect; DestSurface: IDirectDrawSurface; DestRect: PDDRect; Flags: Cardinal; FX: PDDOverlayFX): Integer; stdcall; // slot $84
  end;
  IDirectDrawClipper = interface(IInterface)
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    function SetHWnd(Flags, Window: Cardinal): Integer; stdcall; // slot $20
  end;
  IDirectDrawGammaControl = interface(IInterface)
    ['{69C11C3E-B46B-11D1-AD7A-00C04FC29B4E}']
    function GetGammaRamp(Flags: Cardinal; var Ramp: TDDGammaRamp): Integer; stdcall; // slot $0C
    function SetGammaRamp(Flags: Cardinal; const Ramp: TDDGammaRamp): Integer; stdcall; // slot $10
  end;

const
  DS_OK = 0;
  DS_NO_VIRTUALIZATION = 142082058;
  DS_INCOMPLETE = 142082068;
  DSERR_ALLOCATED = -2005401590;
  DSERR_CONTROLUNAVAIL = -2005401570;
  DSERR_INVALIDPARAM = -2147024809;
  DSERR_INVALIDCALL = -2005401550;
  DSERR_GENERIC = -2147467259;
  DSERR_PRIOLEVELNEEDED = -2005401530;
  DSERR_OUTOFMEMORY = -2147024882;
  DSERR_BADFORMAT = -2005401500;
  DSERR_UNSUPPORTED = -2147467263;
  DSERR_NODRIVER = -2005401480;
  DSERR_ALREADYINITIALIZED = -2005401470;
  DSERR_NOAGGREGATION = -2147221232;
  DSERR_BUFFERLOST = -2005401450;
  DSERR_OTHERAPPHASPRIO = -2005401440;
  DSERR_UNINITIALIZED = -2005401430;
  DSERR_NOINTERFACE = -2147467262;
  DSERR_ACCESSDENIED = -2147024891;
  DSERR_BUFFERTOOSMALL = -2005401420;
  DSERR_DS8_REQUIRED = -2005401410;
  DSERR_SENDLOOP = -2005401400;
  DSERR_BADSENDBUFFERGUID = -2005401390;
  DSERR_OBJECTNOTFOUND = -2005397151;
  DSERR_FXUNAVAILABLE = -2005401380;

  DSBCAPS_PRIMARYBUFFER = $00000001;
  DSBCAPS_STATIC = $00000002;
  DSBCAPS_LOCSOFTWARE = $00000008;
  DSBCAPS_CTRLPAN = $00000040;
  DSBCAPS_CTRLVOLUME = $00000080;
  DSBCAPS_CTRLPOSITIONNOTIFY = $00000100;
  DSBCAPS_GETCURRENTPOSITION2 = $00010000;
  DSBCAPS_CTRL3D = $00000010;
  DSBCAPS_CTRLFREQUENCY = $00000020;
  DSBCAPS_GLOBALFOCUS = $00008000;
  DSBCAPS_LOCDEFER = $00040000;
  DSBCAPS_LOCHARDWARE = $00000004;
  DSBCAPS_MUTE3DATMAXDISTANCE = $00020000;
  DSBCAPS_STICKYFOCUS = $00004000;
  DSCAPS_CERTIFIED = $00000040;
  DSCAPS_CONTINUOUSRATE = $00000010;
  DSCAPS_EMULDRIVER = $00000020;
  DSCAPS_PRIMARY16BIT = $00000008;
  DSCAPS_PRIMARY8BIT = $00000004;
  DSCAPS_PRIMARYMONO = $00000001;
  DSCAPS_PRIMARYSTEREO = $00000002;
  DSCAPS_SECONDARY16BIT = $00000800;
  DSCAPS_SECONDARY8BIT = $00000400;
  DSCAPS_SECONDARYMONO = $00000100;
  DSCAPS_SECONDARYSTEREO = $00000200;
  DSBPLAY_LOOPING = 1;
  DSBLOCK_ENTIREBUFFER = 2;
  DSBSTATUS_PLAYING = 1;
  DSSCL_PRIORITY = 2;
  DSBVOLUME_MIN = -10000;
  DSBPAN_LEFT = -10000;
  DSBPAN_RIGHT = 10000;

type
  // The engine copies 20 bytes, including the aligned wave-format tail.
  TSoundWaveFormat = record // @size $14
    FormatTag: Word; // @offset 0
    Channels: Word; // @offset 2
    SamplesPerSecond: Cardinal; // @offset 4
    AverageBytesPerSecond: Cardinal; // @offset 8
    BlockAlign: Word; // @offset 12
    BitsPerSample: Word; // @offset 14
    ExtraSize: Word; // @offset 16
  end;

  TDSBufferDesc = record // @size $14
    Size: Cardinal; // @offset 0
    Flags: Cardinal; // @offset 4
    BufferBytes: Cardinal; // @offset 8
    Reserved: Cardinal; // @offset 12
    WaveFormat: Pointer; // @offset 16
  end;
  TDSCaps = record // @size $60
    Size: Cardinal; // @offset $00
    Flags: Cardinal; // @offset $04
    MinSecondarySampleRate: Cardinal; // @offset $08
    MaxSecondarySampleRate: Cardinal; // @offset $0C
    PrimaryBuffers: Cardinal; // @offset $10
    MaxHwMixingAllBuffers: Cardinal; // @offset $14
    MaxHwMixingStaticBuffers: Cardinal; // @offset $18
    MaxHwMixingStreamingBuffers: Cardinal; // @offset $1C
    FreeHwMixingAllBuffers: Cardinal; // @offset $20
    FreeHwMixingStaticBuffers: Cardinal; // @offset $24
    FreeHwMixingStreamingBuffers: Cardinal; // @offset $28
    MaxHw3DAllBuffers: Cardinal; // @offset $2C
    MaxHw3DStaticBuffers: Cardinal; // @offset $30
    MaxHw3DStreamingBuffers: Cardinal; // @offset $34
    FreeHw3DAllBuffers: Cardinal; // @offset $38
    FreeHw3DStaticBuffers: Cardinal; // @offset $3C
    FreeHw3DStreamingBuffers: Cardinal; // @offset $40
    TotalHwMemBytes: Cardinal; // @offset $44
    FreeHwMemBytes: Cardinal; // @offset $48
    MaxContigFreeHwMemBytes: Cardinal; // @offset $4C
    UnlockTransferRateHwBuffers: Cardinal; // @offset $50
    PlayCpuOverheadSwBuffers: Cardinal; // @offset $54
    Reserved1: Cardinal; // @offset $58
    Reserved2: Cardinal; // @offset $5C
  end;

  TDSBufferCaps = record // @size $14
    Size: Cardinal; // @offset $00
    Flags: Cardinal; // @offset $04
    BufferBytes: Cardinal; // @offset $08
    UnlockTransferRate: Cardinal; // @offset $0C
    PlayCpuOverhead: Cardinal; // @offset $10
  end;

  PDSPositionNotify = ^TDSPositionNotify;
  TDSPositionNotify = record // @size 8
    Offset: Cardinal; // @offset 0
    EventHandle: Cardinal; // @offset 4
  end;

  IDirectSoundBuffer = interface;
  IDirectSound = interface(IInterface)
    ['{279AFA83-4981-11CE-A521-0020AF0BE560}']
    function CreateSoundBuffer(const Desc: TDSBufferDesc; out Buffer: IDirectSoundBuffer; Outer: IInterface): LongInt; stdcall;
    function GetCaps(Caps: Pointer): LongInt; stdcall;
    function DuplicateSoundBuffer(Original: IDirectSoundBuffer; out Duplicate: IDirectSoundBuffer): LongInt; stdcall;
    function SetCooperativeLevel(Window: Cardinal; Level: Cardinal): LongInt; stdcall;
    function Compact: LongInt; stdcall;
    function GetSpeakerConfig(out Configuration: Cardinal): LongInt; stdcall;
    function SetSpeakerConfig(Configuration: Cardinal): LongInt; stdcall;
    function Initialize(Guid: Pointer): LongInt; stdcall;
  end;

  IDirectSoundBuffer = interface(IInterface)
    ['{279AFA85-4981-11CE-A521-0020AF0BE560}']
    function GetCaps(Caps: Pointer): LongInt; stdcall;
    function GetCurrentPosition(PlayCursor, WriteCursor: PCardinal): LongInt; stdcall;
    function GetFormat(Format: Pointer; Size: Cardinal; Written: PCardinal): LongInt; stdcall;
    function GetVolume(out Volume: Integer): LongInt; stdcall;
    function GetPan(out Pan: Integer): LongInt; stdcall;
    function GetFrequency(out Frequency: Cardinal): LongInt; stdcall;
    function GetStatus(out Status: Cardinal): LongInt; stdcall;
    function Initialize(DirectSound: Pointer; const Desc: TDSBufferDesc): LongInt; stdcall;
    function Lock(Offset, Bytes: Cardinal; Audio1: PPointer; Bytes1: PCardinal; Audio2: PPointer; Bytes2: PCardinal; Flags: Cardinal): LongInt; stdcall;
    function Play(Reserved1, Reserved2, Flags: Cardinal): LongInt; stdcall;
    function SetCurrentPosition(Position: Cardinal): LongInt; stdcall;
    function SetFormat(Format: Pointer): LongInt; stdcall;
    function SetVolume(Volume: Integer): LongInt; stdcall;
    function SetPan(Pan: Integer): LongInt; stdcall;
    function SetFrequency(Frequency: Cardinal): LongInt; stdcall;
    function Stop: LongInt; stdcall;
    function Unlock(Audio1: Pointer; Bytes1: Cardinal; Audio2: Pointer; Bytes2: Cardinal): LongInt; stdcall;
    function Restore: LongInt; stdcall;
  end;

  IDirectSoundNotify = interface(IInterface)
    ['{B0210783-89CD-11D0-AF08-00A0C925CD16}']
    function SetNotificationPositions(Count: Cardinal; Positions: PDSPositionNotify): LongInt; stdcall;
  end;

  TDirectSoundCreate = function(Guid: Pointer; out DirectSound: IDirectSound; Outer: IInterface): LongInt; stdcall;
  TDSEnumCallback = function(Guid: Pointer; Description, Module: PAnsiChar; Context: Pointer): LongBool; stdcall;
  TDirectSoundEnumerate = function(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;

var
  IID_IDirectDraw7: TGUID = (D1: $15E65EC0; D2: $3B9C; D3: $11D2; D4: ($B9, $2F, $00, $60, $97, $97, $EA, $5B)); // @addr $617EB8
  IID_IDirectDrawSurface7: TGUID = (D1: $06675A80; D2: $3B9B; D3: $11D2; D4: ($B9, $2F, $00, $60, $97, $97, $EA, $5B)); // @addr $617EC8
  IID_IDirectSoundNotify: TGUID = (D1: $B0210783; D2: $89CD; D3: $11D0; D4: ($AF, $08, $00, $A0, $C9, $25, $CD, $16)); // @addr $617ED8
  IID_IDirectDrawGammaControl: TGUID = (D1: $69C11C3E; D2: $B46B; D3: $11D1; D4: ($AD, $7A, $00, $C0, $4F, $C2, $9B, $4E)); // @addr $617EE8

function DirectDrawCreate(Guid: Pointer; out DirectDraw: IDirectDraw; Outer: IInterface): Integer; stdcall;
  external 'DDraw.dll' name 'DirectDrawCreate'; // @addr $454000
function DirectSoundCreate(Guid: Pointer; out DirectSound: IDirectSound; Outer: IInterface): LongInt; stdcall;
  external 'DSound.dll' name 'DirectSoundCreate'; // @addr $454008
function DirectSoundEnumerateA(Callback: TDSEnumCallback; Context: Pointer): LongInt; stdcall;
  external 'DSound.dll' name 'DirectSoundEnumerateA'; // @addr $454010

function DirectXErrorText(Code: Integer): AnsiString; // @addr $454018

implementation

// @unit-initialization $455C0C
// @unit-finalization $455BDC

uses SysUtils;

const
  DD_OK = 0;
  DD_FALSE = 1;
  DDERR_ALREADYINITIALIZED = -2005532667;
  DDERR_CANNOTATTACHSURFACE = -2005532662;
  DDERR_CANNOTDETACHSURFACE = -2005532652;
  DDERR_CURRENTLYNOTAVAIL = -2005532632;
  DDERR_EXCEPTION = -2005532617;
  DDERR_GENERIC = -2147467259;
  DDERR_HEIGHTALIGN = -2005532582;
  DDERR_INCOMPATIBLEPRIMARY = -2005532577;
  DDERR_INVALIDCAPS = -2005532572;
  DDERR_INVALIDCLIPLIST = -2005532562;
  DDERR_INVALIDMODE = -2005532552;
  DDERR_INVALIDOBJECT = -2005532542;
  DDERR_INVALIDPARAMS = -2147024809;
  DDERR_INVALIDPIXELFORMAT = -2005532527;
  DDERR_INVALIDRECT = -2005532522;
  DDERR_LOCKEDSURFACES = -2005532512;
  DDERR_NO3D = -2005532502;
  DDERR_NOALPHAHW = -2005532492;
  DDERR_NOCLIPLIST = -2005532467;
  DDERR_NOCOLORCONVHW = -2005532462;
  DDERR_NOCOOPERATIVELEVELSET = -2005532460;
  DDERR_NOCOLORKEY = -2005532457;
  DDERR_NOCOLORKEYHW = -2005532452;
  DDERR_NODIRECTDRAWSUPPORT = -2005532450;
  DDERR_NOEXCLUSIVEMODE = -2005532447;
  DDERR_NOFLIPHW = -2005532442;
  DDERR_NOGDI = -2005532432;
  DDERR_NOMIRRORHW = -2005532422;
  DDERR_NOTFOUND = -2005532417;
  DDERR_NOOVERLAYHW = -2005532412;
  DDERR_OVERLAPPINGRECTS = -2005532402;
  DDERR_NORASTEROPHW = -2005532392;
  DDERR_NOROTATIONHW = -2005532382;
  DDERR_NOSTRETCHHW = -2005532362;
  DDERR_NOT4BITCOLOR = -2005532356;
  DDERR_NOT4BITCOLORINDEX = -2005532355;
  DDERR_NOT8BITCOLOR = -2005532352;
  DDERR_NOTEXTUREHW = -2005532342;
  DDERR_NOVSYNCHW = -2005532337;
  DDERR_NOZBUFFERHW = -2005532332;
  DDERR_NOZOVERLAYHW = -2005532322;
  DDERR_OUTOFCAPS = -2005532312;
  DDERR_OUTOFMEMORY = -2147024882;
  DDERR_OUTOFVIDEOMEMORY = -2005532292;
  DDERR_OVERLAYCANTCLIP = -2005532290;
  DDERR_OVERLAYCOLORKEYONLYONEACTIVE = -2005532288;
  DDERR_PALETTEBUSY = -2005532285;
  DDERR_COLORKEYNOTSET = -2005532272;
  DDERR_SURFACEALREADYATTACHED = -2005532262;
  DDERR_SURFACEALREADYDEPENDENT = -2005532252;
  DDERR_SURFACEBUSY = -2005532242;
  DDERR_CANTLOCKSURFACE = -2005532237;
  DDERR_SURFACEISOBSCURED = -2005532232;
  DDERR_SURFACELOST = -2005532222;
  DDERR_SURFACENOTATTACHED = -2005532212;
  DDERR_TOOBIGHEIGHT = -2005532202;
  DDERR_TOOBIGSIZE = -2005532192;
  DDERR_TOOBIGWIDTH = -2005532182;
  DDERR_UNSUPPORTED = -2147467263;
  DDERR_UNSUPPORTEDFORMAT = -2005532162;
  DDERR_UNSUPPORTEDMASK = -2005532152;
  DDERR_INVALIDSTREAM = -2005532151;
  DDERR_VERTICALBLANKINPROGRESS = -2005532135;
  DDERR_WASSTILLDRAWING = -2005532132;
  DDERR_XALIGN = -2005532112;
  DDERR_INVALIDDIRECTDRAWGUID = -2005532111;
  DDERR_DIRECTDRAWALREADYCREATED = -2005532110;
  DDERR_NODIRECTDRAWHW = -2005532109;
  DDERR_PRIMARYSURFACEALREADYEXISTS = -2005532108;
  DDERR_NOEMULATION = -2005532107;
  DDERR_REGIONTOOSMALL = -2005532106;
  DDERR_CLIPPERISUSINGHWND = -2005532105;
  DDERR_NOCLIPPERATTACHED = -2005532104;
  DDERR_NOHWND = -2005532103;
  DDERR_HWNDSUBCLASSED = -2005532102;
  DDERR_HWNDALREADYSET = -2005532101;
  DDERR_NOPALETTEATTACHED = -2005532100;
  DDERR_NOPALETTEHW = -2005532099;
  DDERR_BLTFASTCANTCLIP = -2005532098;
  DDERR_NOBLTHW = -2005532097;
  DDERR_NODDROPSHW = -2005532096;
  DDERR_OVERLAYNOTVISIBLE = -2005532095;
  DDERR_NOOVERLAYDEST = -2005532094;
  DDERR_INVALIDPOSITION = -2005532093;
  DDERR_NOTAOVERLAYSURFACE = -2005532092;
  DDERR_EXCLUSIVEMODEALREADYSET = -2005532091;
  DDERR_NOTFLIPPABLE = -2005532090;
  DDERR_CANTDUPLICATE = -2005532089;
  DDERR_NOTLOCKED = -2005532088;
  DDERR_CANTCREATEDC = -2005532087;
  DDERR_NODC = -2005532086;
  DDERR_WRONGMODE = -2005532085;
  DDERR_IMPLICITLYCREATED = -2005532084;
  DDERR_NOTPALETTIZED = -2005532083;
  DDERR_UNSUPPORTEDMODE = -2005532082;
  DDERR_NOMIPMAPHW = -2005532081;
  DDERR_INVALIDSURFACETYPE = -2005532080;
  DDERR_NOOPTIMIZEHW = -2005532072;
  DDERR_NOTLOADED = -2005532071;
  DDERR_NOFOCUSWINDOW = -2005532070;
  DDERR_DCALREADYCREATED = -2005532052;
  DDERR_NONONLOCALVIDMEM = -2005532042;
  DDERR_CANTPAGELOCK = -2005532032;
  DDERR_CANTPAGEUNLOCK = -2005532012;
  DDERR_NOTPAGELOCKED = -2005531992;
  DDERR_MOREDATA = -2005531982;
  DDERR_EXPIRED = -2005531981;
  DDERR_VIDEONOTACTIVE = -2005531977;
  DDERR_DEVICEDOESNTOWNSURFACE = -2005531973;
  DDERR_NOTINITIALIZED = -2147221008;

{ @routine $454018 DirectXErrorText }
function DirectXErrorText(Code: Integer): AnsiString;
var
  Text: AnsiString;
begin
  case HResult(Code) of
    DD_OK: Text := 'DD_OK';
    DD_FALSE: Text := 'DD_FALSE';
    DDERR_ALREADYINITIALIZED: Text := 'DDERR_ALREADYINITIALIZED';
    DDERR_CANNOTATTACHSURFACE: Text := 'DDERR_CANNOTATTACHSURFACE';
    DDERR_CANNOTDETACHSURFACE: Text := 'DDERR_CANNOTDETACHSURFACE';
    DDERR_CURRENTLYNOTAVAIL: Text := 'DDERR_CURRENTLYNOTAVAIL';
    DDERR_EXCEPTION: Text := 'DDERR_EXCEPTION';
    DDERR_GENERIC: Text := 'DDERR_GENERIC';
    DDERR_HEIGHTALIGN: Text := 'DDERR_HEIGHTALIGN';
    DDERR_INCOMPATIBLEPRIMARY: Text := 'DDERR_INCOMPATIBLEPRIMARY';
    DDERR_INVALIDCAPS: Text := 'DDERR_INVALIDCAPS';
    DDERR_INVALIDCLIPLIST: Text := 'DDERR_INVALIDCLIPLIST';
    DDERR_INVALIDMODE: Text := 'DDERR_INVALIDMODE';
    DDERR_INVALIDOBJECT: Text := 'DDERR_INVALIDOBJECT';
    DDERR_INVALIDPARAMS: Text := 'DDERR_INVALIDPARAMS';
    DDERR_INVALIDPIXELFORMAT: Text := 'DDERR_INVALIDPIXELFORMAT';
    DDERR_INVALIDRECT: Text := 'DDERR_INVALIDRECT';
    DDERR_LOCKEDSURFACES: Text := 'DDERR_LOCKEDSURFACES';
    DDERR_NO3D: Text := 'DDERR_NO3D';
    DDERR_NOALPHAHW: Text := 'DDERR_NOALPHAHW';
    DDERR_NOCLIPLIST: Text := 'DDERR_NOCLIPLIST';
    DDERR_NOCOLORCONVHW: Text := 'DDERR_NOCOLORCONVHW';
    DDERR_NOCOOPERATIVELEVELSET: Text := 'DDERR_NOCOOPERATIVELEVELSET';
    DDERR_NOCOLORKEY: Text := 'DDERR_NOCOLORKEY';
    DDERR_NOCOLORKEYHW: Text := 'DDERR_NOCOLORKEYHW';
    DDERR_NODIRECTDRAWSUPPORT: Text := 'DDERR_NODIRECTDRAWSUPPORT';
    DDERR_NOEXCLUSIVEMODE: Text := 'DDERR_NOEXCLUSIVEMODE';
    DDERR_NOFLIPHW: Text := 'DDERR_NOFLIPHW';
    DDERR_NOGDI: Text := 'DDERR_NOGDI';
    DDERR_NOMIRRORHW: Text := 'DDERR_NOMIRRORHW';
    DDERR_NOTFOUND: Text := 'DDERR_NOTFOUND';
    DDERR_NOOVERLAYHW: Text := 'DDERR_NOOVERLAYHW';
    DDERR_OVERLAPPINGRECTS: Text := 'DDERR_OVERLAPPINGRECTS';
    DDERR_NORASTEROPHW: Text := 'DDERR_NORASTEROPHW';
    DDERR_NOROTATIONHW: Text := 'DDERR_NOROTATIONHW';
    DDERR_NOSTRETCHHW: Text := 'DDERR_NOSTRETCHHW';
    DDERR_NOT4BITCOLOR: Text := 'DDERR_NOT4BITCOLOR';
    DDERR_NOT4BITCOLORINDEX: Text := 'DDERR_NOT4BITCOLORINDEX';
    DDERR_NOT8BITCOLOR: Text := 'DDERR_NOT8BITCOLOR';
    DDERR_NOTEXTUREHW: Text := 'DDERR_NOTEXTUREHW';
    DDERR_NOVSYNCHW: Text := 'DDERR_NOVSYNCHW';
    DDERR_NOZBUFFERHW: Text := 'DDERR_NOZBUFFERHW';
    DDERR_NOZOVERLAYHW: Text := 'DDERR_NOZOVERLAYHW';
    DDERR_OUTOFCAPS: Text := 'DDERR_OUTOFCAPS';
    DDERR_OUTOFMEMORY: Text := 'DDERR_OUTOFMEMORY';
    DDERR_OUTOFVIDEOMEMORY: Text := 'DDERR_OUTOFVIDEOMEMORY';
    DDERR_OVERLAYCANTCLIP: Text := 'DDERR_OVERLAYCANTCLIP';
    DDERR_OVERLAYCOLORKEYONLYONEACTIVE: Text := 'DDERR_OVERLAYCOLORKEYONLYONEACTIVE';
    DDERR_PALETTEBUSY: Text := 'DDERR_PALETTEBUSY';
    DDERR_COLORKEYNOTSET: Text := 'DDERR_COLORKEYNOTSET';
    DDERR_SURFACEALREADYATTACHED: Text := 'DDERR_SURFACEALREADYATTACHED';
    DDERR_SURFACEALREADYDEPENDENT: Text := 'DDERR_SURFACEALREADYDEPENDENT';
    DDERR_SURFACEBUSY: Text := 'DDERR_SURFACEBUSY';
    DDERR_CANTLOCKSURFACE: Text := 'DDERR_CANTLOCKSURFACE';
    DDERR_SURFACEISOBSCURED: Text := 'DDERR_SURFACEISOBSCURED';
    DDERR_SURFACELOST: Text := 'DDERR_SURFACELOST';
    DDERR_SURFACENOTATTACHED: Text := 'DDERR_SURFACENOTATTACHED';
    DDERR_TOOBIGHEIGHT: Text := 'DDERR_TOOBIGHEIGHT';
    DDERR_TOOBIGSIZE: Text := 'DDERR_TOOBIGSIZE';
    DDERR_TOOBIGWIDTH: Text := 'DDERR_TOOBIGWIDTH';
    DDERR_UNSUPPORTED: Text := 'DDERR_UNSUPPORTED';
    DDERR_UNSUPPORTEDFORMAT: Text := 'DDERR_UNSUPPORTEDFORMAT';
    DDERR_UNSUPPORTEDMASK: Text := 'DDERR_UNSUPPORTEDMASK';
    DDERR_INVALIDSTREAM: Text := 'DDERR_INVALIDSTREAM';
    DDERR_VERTICALBLANKINPROGRESS: Text := 'DDERR_VERTICALBLANKINPROGRESS';
    DDERR_WASSTILLDRAWING: Text := 'DDERR_WASSTILLDRAWING';
    DDERR_XALIGN: Text := 'DDERR_XALIGN';
    DDERR_INVALIDDIRECTDRAWGUID: Text := 'DDERR_INVALIDDIRECTDRAWGUID';
    DDERR_DIRECTDRAWALREADYCREATED: Text := 'DDERR_DIRECTDRAWALREADYCREATED';
    DDERR_NODIRECTDRAWHW: Text := 'DDERR_NODIRECTDRAWHW';
    DDERR_PRIMARYSURFACEALREADYEXISTS: Text := 'DDERR_PRIMARYSURFACEALREADYEXISTS';
    DDERR_NOEMULATION: Text := 'DDERR_NOEMULATION';
    DDERR_REGIONTOOSMALL: Text := 'DDERR_REGIONTOOSMALL';
    DDERR_CLIPPERISUSINGHWND: Text := 'DDERR_CLIPPERISUSINGHWND';
    DDERR_NOCLIPPERATTACHED: Text := 'DDERR_NOCLIPPERATTACHED';
    DDERR_NOHWND: Text := 'DDERR_NOHWND';
    DDERR_HWNDSUBCLASSED: Text := 'DDERR_HWNDSUBCLASSED';
    DDERR_HWNDALREADYSET: Text := 'DDERR_HWNDALREADYSET';
    DDERR_NOPALETTEATTACHED: Text := 'DDERR_NOPALETTEATTACHED';
    DDERR_NOPALETTEHW: Text := 'DDERR_NOPALETTEHW';
    DDERR_BLTFASTCANTCLIP: Text := 'DDERR_BLTFASTCANTCLIP';
    DDERR_NOBLTHW: Text := 'DDERR_NOBLTHW';
    DDERR_NODDROPSHW: Text := 'DDERR_NODDROPSHW';
    DDERR_OVERLAYNOTVISIBLE: Text := 'DDERR_OVERLAYNOTVISIBLE';
    DDERR_NOOVERLAYDEST: Text := 'DDERR_NOOVERLAYDEST';
    DDERR_INVALIDPOSITION: Text := 'DDERR_INVALIDPOSITION';
    DDERR_NOTAOVERLAYSURFACE: Text := 'DDERR_NOTAOVERLAYSURFACE';
    DDERR_EXCLUSIVEMODEALREADYSET: Text := 'DDERR_EXCLUSIVEMODEALREADYSET';
    DDERR_NOTFLIPPABLE: Text := 'DDERR_NOTFLIPPABLE';
    DDERR_CANTDUPLICATE: Text := 'DDERR_CANTDUPLICATE';
    DDERR_NOTLOCKED: Text := 'DDERR_NOTLOCKED';
    DDERR_CANTCREATEDC: Text := 'DDERR_CANTCREATEDC';
    DDERR_NODC: Text := 'DDERR_NODC';
    DDERR_WRONGMODE: Text := 'DDERR_WRONGMODE';
    DDERR_IMPLICITLYCREATED: Text := 'DDERR_IMPLICITLYCREATED';
    DDERR_NOTPALETTIZED: Text := 'DDERR_NOTPALETTIZED';
    DDERR_UNSUPPORTEDMODE: Text := 'DDERR_UNSUPPORTEDMODE';
    DDERR_NOMIPMAPHW: Text := 'DDERR_NOMIPMAPHW';
    DDERR_INVALIDSURFACETYPE: Text := 'DDERR_INVALIDSURFACETYPE';
    DDERR_NOOPTIMIZEHW: Text := 'DDERR_NOOPTIMIZEHW';
    DDERR_NOTLOADED: Text := 'DDERR_NOTLOADED';
    DDERR_NOFOCUSWINDOW: Text := 'DDERR_NOFOCUSWINDOW';
    DDERR_DCALREADYCREATED: Text := 'DDERR_DCALREADYCREATED';
    DDERR_NONONLOCALVIDMEM: Text := 'DDERR_NONONLOCALVIDMEM';
    DDERR_CANTPAGELOCK: Text := 'DDERR_CANTPAGELOCK';
    DDERR_CANTPAGEUNLOCK: Text := 'DDERR_CANTPAGEUNLOCK';
    DDERR_NOTPAGELOCKED: Text := 'DDERR_NOTPAGELOCKED';
    DDERR_MOREDATA: Text := 'DDERR_MOREDATA';
    DDERR_EXPIRED: Text := 'DDERR_EXPIRED';
    DDERR_VIDEONOTACTIVE: Text := 'DDERR_VIDEONOTACTIVE';
    DDERR_DEVICEDOESNTOWNSURFACE: Text := 'DDERR_DEVICEDOESNTOWNSURFACE';
    DDERR_NOTINITIALIZED: Text := 'DDERR_NOTINITIALIZED';
    DSERR_CONTROLUNAVAIL: Text := 'DSERR_CONTROLUNAVAIL';
    DSERR_PRIOLEVELNEEDED: Text := 'DSERR_PRIOLEVELNEEDED';
  else Text := 'Unknown';
  end;
  Result := 'HResult=' + IntToStr(Cardinal(Code)) + ' Str=' + Text;
end;
{ @end $454018 }

end.

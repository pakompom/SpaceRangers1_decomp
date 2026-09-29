unit GR_DirectX3D8;
// Unit bracket (inferred): CODE 0x00455C18..0x00455D43; inclusive evidence, not full bounds.
// Direct3D 8 declarations and color helper.
// Native interface RTTI names GR_DirectX3D8 at $455C18, $455C58 and $455C9C.
interface

type
  TD3DDisplayMode8 = record // @size $10
    Width: Cardinal; // @offset $00
    Height: Cardinal; // @offset $04
    RefreshRate: Cardinal; // @offset $08
    Format: Cardinal; // @offset $0C
  end;
  TD3DPresentParameters8 = record // @size $34
    BackBufferWidth: Cardinal; // @offset $00
    BackBufferHeight: Cardinal; // @offset $04
    BackBufferFormat: Cardinal; // @offset $08
    BackBufferCount: Cardinal; // @offset $0C
    MultiSampleType: Cardinal; // @offset $10
    SwapEffect: Cardinal; // @offset $14
    DeviceWindow: Cardinal; // @offset $18
    Windowed: LongBool; // @offset $1C
    EnableAutoDepthStencil: LongBool; // @offset $20
    AutoDepthStencilFormat: Cardinal; // @offset $24
    Flags: Cardinal; // @offset $28
    FullScreenRefreshRate: Cardinal; // @offset $2C
    FullScreenPresentationInterval: Cardinal; // @offset $30
  end;
  TD3DLockedRect8 = record // @size $08
    Pitch: Integer; // @offset $00
    Bits: Pointer; // @offset $04
  end;
  TD3DVertexBufferDesc8 = record // @size $18
    Format: Cardinal; // @offset $00
    ResourceType: Cardinal; // @offset $04
    Usage: Cardinal; // @offset $08
    Pool: Cardinal; // @offset $0C
    Size: Cardinal; // @offset $10
    FVF: Cardinal; // @offset $14
  end;
  TD3DIndexBufferDesc8 = record // @size $14
    Format: Cardinal; // @offset $00
    ResourceType: Cardinal; // @offset $04
    Usage: Cardinal; // @offset $08
    Pool: Cardinal; // @offset $0C
    Size: Cardinal; // @offset $10
  end;
  IDirect3DTexture8 = interface(IInterface)
    ['{E4CDD575-2866-4F01-B12E-7EECE1EC9358}']
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
    function LockRect(Level: Cardinal; var Locked: TD3DLockedRect8; Rect: Pointer; Flags: Cardinal): Integer; stdcall; // slot $40
    function UnlockRect(Level: Cardinal): Integer; stdcall; // slot $44
    function AddDirtyRect(Rect: Pointer): Integer; stdcall; // slot $48
  end;
  IDirect3DVertexBuffer8 = interface(IInterface)
    ['{8AEEEAC7-05F9-44D4-B591-000B0DF1CB95}']
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    procedure UnrecoveredSlot20; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    procedure UnrecoveredSlot28; stdcall; // slot $28
    function Lock(Offset, Size: Cardinal; out Data: PByte; Flags: Cardinal): Integer; stdcall; // slot $2C
    function Unlock: Integer; stdcall; // slot $30
    function GetDesc(out Desc: TD3DVertexBufferDesc8): Integer; stdcall; // slot $34
  end;
  IDirect3DIndexBuffer8 = interface(IInterface)
    ['{0E689C9A-053D-44A0-9D92-DB0E3D750F86}']
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    procedure UnrecoveredSlot20; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    procedure UnrecoveredSlot28; stdcall; // slot $28
    function Lock(Offset, Size: Cardinal; out Data: PByte; Flags: Cardinal): Integer; stdcall; // slot $2C
    function Unlock: Integer; stdcall; // slot $30
    function GetDesc(out Desc: TD3DIndexBufferDesc8): Integer; stdcall; // slot $34
  end;
  IDirect3DDevice8 = interface(IInterface)
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
    function Present(SourceRect, DestRect: Pointer; OverrideWindow: Cardinal; DirtyRegion: Pointer): Integer; stdcall; // slot $3C
    procedure UnrecoveredSlot40; stdcall; // slot $40
    procedure UnrecoveredSlot44; stdcall; // slot $44
    procedure UnrecoveredSlot48; stdcall; // slot $48
    procedure UnrecoveredSlot4C; stdcall; // slot $4C
    function CreateTexture(Width, Height, Levels, Usage, Format, Pool: Cardinal; out Texture: IDirect3DTexture8): Integer; stdcall; // slot $50
    procedure UnrecoveredSlot54; stdcall; // slot $54
    procedure UnrecoveredSlot58; stdcall; // slot $58
    function CreateVertexBuffer(Length, Usage, FVF, Pool: Cardinal; out Buffer: IDirect3DVertexBuffer8): Integer; stdcall; // slot $5C
    function CreateIndexBuffer(Length, Usage, Format, Pool: Cardinal; out Buffer: IDirect3DIndexBuffer8): Integer; stdcall; // slot $60
    procedure UnrecoveredSlot64; stdcall; // slot $64
    procedure UnrecoveredSlot68; stdcall; // slot $68
    procedure UnrecoveredSlot6C; stdcall; // slot $6C
    procedure UnrecoveredSlot70; stdcall; // slot $70
    procedure UnrecoveredSlot74; stdcall; // slot $74
    procedure UnrecoveredSlot78; stdcall; // slot $78
    procedure UnrecoveredSlot7C; stdcall; // slot $7C
    procedure UnrecoveredSlot80; stdcall; // slot $80
    procedure UnrecoveredSlot84; stdcall; // slot $84
    function BeginScene: Integer; stdcall; // slot $88
    function EndScene: Integer; stdcall; // slot $8C
    function Clear(Count: Cardinal; Rects: Pointer; Flags, Color: Cardinal; Z: Single; Stencil: Cardinal): Integer; stdcall; // slot $90
    procedure UnrecoveredSlot94; stdcall; // slot $94
    procedure UnrecoveredSlot98; stdcall; // slot $98
    procedure UnrecoveredSlot9C; stdcall; // slot $9C
    procedure UnrecoveredSlotA0; stdcall; // slot $A0
    procedure UnrecoveredSlotA4; stdcall; // slot $A4
    procedure UnrecoveredSlotA8; stdcall; // slot $A8
    procedure UnrecoveredSlotAC; stdcall; // slot $AC
    procedure UnrecoveredSlotB0; stdcall; // slot $B0
    procedure UnrecoveredSlotB4; stdcall; // slot $B4
    procedure UnrecoveredSlotB8; stdcall; // slot $B8
    procedure UnrecoveredSlotBC; stdcall; // slot $BC
    procedure UnrecoveredSlotC0; stdcall; // slot $C0
    procedure UnrecoveredSlotC4; stdcall; // slot $C4
    function SetRenderState(State, Value: Cardinal): Integer; stdcall; // slot $C8
    procedure UnrecoveredSlotCC; stdcall; // slot $CC
    procedure UnrecoveredSlotD0; stdcall; // slot $D0
    procedure UnrecoveredSlotD4; stdcall; // slot $D4
    procedure UnrecoveredSlotD8; stdcall; // slot $D8
    procedure UnrecoveredSlotDC; stdcall; // slot $DC
    procedure UnrecoveredSlotE0; stdcall; // slot $E0
    procedure UnrecoveredSlotE4; stdcall; // slot $E4
    procedure UnrecoveredSlotE8; stdcall; // slot $E8
    procedure UnrecoveredSlotEC; stdcall; // slot $EC
    procedure UnrecoveredSlotF0; stdcall; // slot $F0
    function SetTexture(Stage: Cardinal; Texture: IDirect3DTexture8): Integer; stdcall; // slot $F4
    procedure UnrecoveredSlotF8; stdcall; // slot $F8
    function SetTextureStageState(Stage, State, Value: Cardinal): Integer; stdcall; // slot $FC
    procedure UnrecoveredSlot100; stdcall; // slot $100
    procedure UnrecoveredSlot104; stdcall; // slot $104
    procedure UnrecoveredSlot108; stdcall; // slot $108
    procedure UnrecoveredSlot10C; stdcall; // slot $10C
    procedure UnrecoveredSlot110; stdcall; // slot $110
    procedure UnrecoveredSlot114; stdcall; // slot $114
    procedure UnrecoveredSlot118; stdcall; // slot $118
    function DrawIndexedPrimitive(PrimitiveType, MinIndex, NumVertices, StartIndex, PrimitiveCount: Cardinal): Integer; stdcall; // slot $11C
    procedure UnrecoveredSlot120; stdcall; // slot $120
    procedure UnrecoveredSlot124; stdcall; // slot $124
    procedure UnrecoveredSlot128; stdcall; // slot $128
    procedure UnrecoveredSlot12C; stdcall; // slot $12C
    function SetVertexShader(Handle: Cardinal): Integer; stdcall; // slot $130
    procedure UnrecoveredSlot134; stdcall; // slot $134
    procedure UnrecoveredSlot138; stdcall; // slot $138
    procedure UnrecoveredSlot13C; stdcall; // slot $13C
    procedure UnrecoveredSlot140; stdcall; // slot $140
    procedure UnrecoveredSlot144; stdcall; // slot $144
    procedure UnrecoveredSlot148; stdcall; // slot $148
    function SetStreamSource(Stream: Cardinal; Buffer: IDirect3DVertexBuffer8; Stride: Cardinal): Integer; stdcall; // slot $14C
    procedure UnrecoveredSlot150; stdcall; // slot $150
    function SetIndices(Buffer: IDirect3DIndexBuffer8; BaseVertexIndex: Cardinal): Integer; stdcall; // slot $154
  end;
  IDirect3D8 = interface(IInterface)
    procedure UnrecoveredSlot0C; stdcall; // slot $0C
    procedure UnrecoveredSlot10; stdcall; // slot $10
    procedure UnrecoveredSlot14; stdcall; // slot $14
    procedure UnrecoveredSlot18; stdcall; // slot $18
    procedure UnrecoveredSlot1C; stdcall; // slot $1C
    function GetAdapterDisplayMode(Adapter: Cardinal; var Mode: TD3DDisplayMode8): Integer; stdcall; // slot $20
    procedure UnrecoveredSlot24; stdcall; // slot $24
    procedure UnrecoveredSlot28; stdcall; // slot $28
    procedure UnrecoveredSlot2C; stdcall; // slot $2C
    procedure UnrecoveredSlot30; stdcall; // slot $30
    procedure UnrecoveredSlot34; stdcall; // slot $34
    procedure UnrecoveredSlot38; stdcall; // slot $38
    function CreateDevice(Adapter, DeviceType, FocusWindow, BehaviorFlags: Cardinal; var Parameters: TD3DPresentParameters8; out Device: IDirect3DDevice8): Integer; stdcall; // slot $3C
  end;
  TDirect3DCreate8 = function(SDKVersion: Cardinal): Pointer; stdcall;
function D3DColorXRGB(Red, Green, Blue: Byte): Cardinal; // @addr $455CDC
implementation

// @unit-initialization $455D3C
// @unit-finalization $455D0C

{ @routine $455CDC D3DColorXRGB }
function D3DColorXRGB(Red, Green, Blue: Byte): Cardinal;
begin
  Result := $FF000000 or ((Red and $FF) shl 16) or ((Green and $FF) shl 8) or (Blue and $FF);
end;
{ @end $455CDC }
end.

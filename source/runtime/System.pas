unit System;
// Unit bracket (inferred): CODE 0x004010DC..0x004069F6; inclusive evidence, not full bounds.

// Declaration-only Delphi 7 types and native RTL storage identities.
// The build uses System.dcu, not a replacement RTL implementation.
interface

type
  TGUID = record // @size $10
    D1: Cardinal; // @offset $00
    D2: Word; // @offset $04
    D3: Word; // @offset $06
    D4: array[0..7] of Byte; // @offset $08
  end;
  IInterface = interface
    function QueryInterface(const IID: TGUID; out Obj): LongInt; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;
  PInteger = ^Integer;
  PCardinal = ^Cardinal;
  PPointer = ^Pointer;
  AnsiChar = Char;
  PWideChar = ^WideChar;
  PAnsiChar = ^AnsiChar;
  PByte = ^Byte;
  // Stock Delphi 7 TextFile storage. The native optional-log local reserves
  // $1CC bytes; the session log at $61C6D8 ends at the next global, $61C8A4.
  // Its internal RTL fields are not needed by the recovered callers.
  TTextRec = packed record // @size $1CC
    Storage: array[0..459] of Byte; // @offset $00
  end;
  TextFile = TTextRec;
  // Private allocator layouts from the selected D7 RTL Sys/getmem.inc.
  TRtlBlockDescriptor = packed record // @size $10
    Next: Pointer; // @offset $00
    Prev: Pointer; // @offset $04
    Address: PAnsiChar; // @offset $08
    Size: Integer; // @offset $0C
  end;
  TRtlFreeBlock = packed record // @size $0C
    Prev: Pointer; // @offset $00
    Next: Pointer; // @offset $04
    Size: Integer; // @offset $08
  end;
  TRtlCriticalSection = record // @size $18
    DebugInfo: Pointer; // @offset $00
    LockCount: Longint; // @offset $04
    RecursionCount: Longint; // @offset $08
    OwningThread: Integer; // @offset $0C
    LockSemaphore: Integer; // @offset $10
    Reserved: Cardinal; // @offset $14
  end;
  TMemoryManager = record // @size $0C
    GetMem: Pointer; // @offset $00
    FreeMem: Pointer; // @offset $04
    ReallocMem: Pointer; // @offset $08
  end;
  TObject = class // @size $04
  public
    constructor Create; // @addr $40399C
    destructor Destroy; virtual; // @addr $4039BC
  end;

var
  HInstance: Cardinal; // @addr $61B664
  RandSeed: Integer; // @addr $617008
  ExceptObjProc: Pointer; // @addr $61B010
  RaiseExceptionProc: Pointer; // @addr $61B014
  InitProc: Pointer; // @addr $61B040

// RTL identities come from native instruction operands and the stock D7 MAP,
// with sizes checked against System.pas and getmem.inc.
// These declarations do not replace or add storage to System.dcu.
var
  ExitCode: Integer; // @addr $617000
  ErrorAddr: Pointer; // @addr $617004
  FileMode: Byte; // @addr $61700C
  VarClearProc: Pointer; // @addr $617010
  VarCopyProc: Pointer; // @addr $617018
  Default8087CW: Word; // @addr $617024
  DebugHook: Byte; // @addr $61702C
  JITEnable: Byte; // @addr $617030
  NoErrMsg: Boolean; // @addr $617034
  DefaultTextLineBreakStyle: Byte; // @addr $617038
  LibModuleList: Pointer; // @addr $61703C
  ModuleUnloadList: Pointer; // @addr $617040
  MemoryManager: TMemoryManager; // @addr $617044
  DispCallByIDProc: Pointer; // @addr $61B000
  ExceptProc: Pointer; // @addr $61B004
  ErrorProc: Pointer; // @addr $61B008
  ExceptClsProc: Pointer; // @addr $61B00C
  RTLUnwindProc: Pointer; // @addr $61B018
  ExitProcessProc: Pointer; // @addr $61B024
  AbstractErrorProc: Pointer; // @addr $61B028
  MainInstance: Cardinal; // @addr $61B02C
  MainThreadID: Cardinal; // @addr $61B030
  IsLibrary: Boolean; // @addr $61B034
  CmdShow: Integer; // @addr $61B038
  CmdLine: PAnsiChar; // @addr $61B03C
  ExitProc: Pointer; // @addr $61B044
  IsConsole: Boolean; // @addr $61B048
  IsMultiThread: Boolean; // @addr $61B049
  Test8086: Byte; // @addr $61B04A
  Input: TextFile; // @addr $61B04C
  Output: TextFile; // @addr $61B218
  ErrOutput: TextFile; // @addr $61B3E4
  AllocMemCount: Integer; // @addr $61B5B0
  AllocMemSize: Integer; // @addr $61B5B4
  DefaultUserCodePage: Integer; // @addr $61B5BC
  initialized: Boolean; // @addr $61B5C0
  heapErrorCode: Integer; // @addr $61B5C4
  heapLock: TRtlCriticalSection; // @addr $61B5C8
  blockDescBlockList: Pointer; // @addr $61B5E0
  blockDescFreeList: Pointer; // @addr $61B5E4
  spaceRoot: TRtlBlockDescriptor; // @addr $61B5E8
  decommittedRoot: TRtlBlockDescriptor; // @addr $61B5F8
  avail: TRtlFreeBlock; // @addr $61B608
  rover: Pointer; // @addr $61B614
  remBytes: Integer; // @addr $61B618
  curAlloc: PAnsiChar; // @addr $61B61C
  smallTab: Pointer; // @addr $61B620
  committedRoot: TRtlBlockDescriptor; // @addr $61B624

function LStrToPChar(Value: Pointer): PAnsiChar; // @addr $404C84

implementation
end.

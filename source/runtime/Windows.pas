unit Windows;
// Unit bracket (inferred): CODE 0x00406BB4..0x004079BB; inclusive evidence, not full bounds.
// Declaration-only Win32 heap API, supplied by Delphi 7's Windows.dcu.
interface
type
  PExceptionRecord = ^TExceptionRecord;
  TExceptionRecord = record // @size $50
    ExceptionCode: Cardinal; // @offset $00
    ExceptionFlags: Cardinal; // @offset $04
    ExceptionRecord: PExceptionRecord; // @offset $08
    ExceptionAddress: Pointer; // @offset $0C
    NumberParameters: Cardinal; // @offset $10
    ExceptionInformation: array[0..14] of Cardinal; // @offset $14
  end;
  TMemoryBasicInformation = record // @size $1C
    BaseAddress: Pointer; // @offset $00
    AllocationBase: Pointer; // @offset $04
    AllocationProtect: Cardinal; // @offset $08
    RegionSize: Cardinal; // @offset $0C
    State: Cardinal; // @offset $10
    Protect: Cardinal; // @offset $14
    Type_9: Cardinal; // @offset $18
  end;
  TSystemTime = packed record // @size $10
    wYear: Word; // @offset $00
    wMonth: Word; // @offset $02
    wDayOfWeek: Word; // @offset $04
    wDay: Word; // @offset $06
    wHour: Word; // @offset $08
    wMinute: Word; // @offset $0A
    wSecond: Word; // @offset $0C
    wMilliseconds: Word; // @offset $0E
  end;
const
  GENERIC_READ = $80000000;
  GENERIC_WRITE = $40000000;
function GetLastError: Cardinal; stdcall; external 'kernel32.dll' name 'GetLastError'; // @addr $406DA4
procedure CopyMemory(Destination, Source: Pointer; Length: Cardinal); // @addr $407734
function GetProcessHeap: Cardinal; stdcall; external 'kernel32.dll' name 'GetProcessHeap'; // @addr $406DDC
function HeapAlloc(Heap: Cardinal; Flags, Bytes: Cardinal): Pointer; stdcall; external 'kernel32.dll' name 'HeapAlloc'; // @addr $406E7C
function HeapReAlloc(Heap: Cardinal; Flags: Cardinal; Data: Pointer; Bytes: Cardinal): Pointer; stdcall; external 'kernel32.dll' name 'HeapReAlloc'; // @addr $406E9C
function HeapFree(Heap: Cardinal; Flags: Cardinal; Data: Pointer): LongBool; stdcall; external 'kernel32.dll' name 'HeapFree'; // @addr $406E94
procedure MoveMemory(Destination, Source: Pointer; Length: Cardinal); // @addr $40772C
procedure FillMemory(Destination: Pointer; Length: Cardinal; Fill: Byte); // @addr $40773C
procedure ZeroMemory(Destination: Pointer; Length: Cardinal); // @addr $407748
implementation
end.

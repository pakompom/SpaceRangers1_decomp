unit EC_Mem;
// Unit bracket (inferred): CODE 0x00453998..0x00453F4F; inclusive evidence, not full bounds.

interface

function AllocEC(ByteCount: Integer): Pointer; // @addr $453998 @note "Uses the process heap; raises immediately on allocation failure."
function AllocClearEC(ByteCount: Integer): Pointer; // @addr $453A34
function ReAllocREC(Data: Pointer; ByteCount: Integer): Pointer; // @addr $453AD4 @note "Nonpositive sizes free Data and return nil; raises on allocation failure."
procedure FreeEC(Data: Pointer); // @addr $453BF0
procedure FreeFromHeapEC(Heap: Cardinal; Data: Pointer); // @addr $453E44
// The diagnostics retain AllocEC/AllocClearEC/ReAllocREC for these explicit-heap variants.
function AllocFromHeapEC(Heap: Cardinal; ByteCount: Integer): Pointer; // @addr $453C04 @note "Raises on allocation failure; does not evict caches."
function AllocClearFromHeapEC(Heap: Cardinal; ByteCount: Integer): Pointer; // @addr $453C9C @note "Raises on allocation failure; does not evict caches."
function ReAllocFromHeapREC(Heap: Cardinal; Data: Pointer; ByteCount: Integer): Pointer; // @addr $453D38 @note "Nonpositive sizes free Data and return nil. Raises on allocation failure; does not evict caches."
// These stack-ABI accessors are handwritten assembly in the native unit.
function AddPointerOffset(Data: Pointer; ByteOffset: Integer): Pointer; cdecl; // @addr $453E50
procedure WriteByteEC(Dest: Pointer; Value: Byte); cdecl; // @addr $453E5C
procedure WriteWordEC(Dest: Pointer; Value: Word); cdecl; // @addr $453E6C
procedure WriteIntegerEC(Dest: Pointer; Value: Integer); cdecl; // @addr $453E7C
procedure WriteInt32EC(Dest: Pointer; Value: Integer); cdecl; // @addr $453E8C
procedure WriteSingleEC(Dest: Pointer; Value: Single); cdecl; // @addr $453E9C
procedure WriteDoubleEC(Dest: Pointer; Value: Double); cdecl; // @addr $453EAC
function ReadByteEC(Source: Pointer): Byte; cdecl; // @addr $453EC4
function ReadWideCharEC(Source: Pointer): WideChar; cdecl; // @addr $453ED0
function ReadWordEC(Source: Pointer): Word; cdecl; // @addr $453EDC
function ReadDWordEC(Source: Pointer): Cardinal; cdecl; // @addr $453EE8
function ReadIntegerEC(Source: Pointer): Integer; cdecl; // @addr $453EF4
function ReadSingleEC(Source: Pointer): Single; cdecl; // @addr $453F00
function ReadDoubleEC(Source: Pointer): Double; cdecl; // @addr $453F0C

implementation

// @unit-initialization $453F48
// @unit-finalization $453F18

uses SysUtils, Windows;

const
  HEAP_ZERO_MEMORY = $00000008;

{ @routine $453998 AllocEC }
function AllocEC(ByteCount: Integer): Pointer;
var Memory: Pointer;
begin
  Memory := HeapAlloc(GetProcessHeap, 0, ByteCount);
  if Memory = nil then
    raise Exception.Create('AllocEC. size=' + SysUtils.IntToStr(ByteCount));
  Result := Memory;
end;
{ @end $453998 }

{ @routine $453A34 AllocClearEC }
function AllocClearEC(ByteCount: Integer): Pointer;
var Memory: Pointer;
begin
  Memory := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, ByteCount);
  if Memory = nil then
    raise Exception.Create('AllocClearEC. size=' + SysUtils.IntToStr(ByteCount));
  Result := Memory;
end;
{ @end $453A34 }

{ @routine $453AD4 ReAllocREC }
function ReAllocREC(Data: Pointer; ByteCount: Integer): Pointer;
begin
  if (ByteCount <= 0) and (Data <> nil) then
  begin
    HeapFree(GetProcessHeap, 0, Data);
    Data := nil;
  end
  else if ByteCount <= 0 then Data := nil
  else if (ByteCount > 0) and (Data <> nil) then
  begin
    Data := HeapReAlloc(GetProcessHeap, 0, Data, ByteCount);
    if Data = nil then
      raise Exception.Create('ReAllocREC. size=' + SysUtils.IntToStr(ByteCount));
  end
  else
  begin
    Data := HeapAlloc(GetProcessHeap, 0, ByteCount);
    if Data = nil then
      raise Exception.Create('ReAllocREC. size=' + SysUtils.IntToStr(ByteCount));
  end;
  Result := Data;
end;
{ @end $453AD4 }

{ @routine $453BF0 FreeEC }
procedure FreeEC(Data: Pointer);
begin HeapFree(GetProcessHeap, 0, Data) end;
{ @end $453BF0 }

{ @routine $453C04 AllocFromHeapEC }
function AllocFromHeapEC(Heap: Cardinal; ByteCount: Integer): Pointer;
var
  Memory: Pointer;
begin
  Memory := HeapAlloc(Heap, 0, ByteCount);
  if Memory = nil then
  begin
    raise Exception.Create('AllocEC. size=' + SysUtils.IntToStr(ByteCount));
  end;
  Result := Memory;
end;
{ @end $453C04 }

{ @routine $453C9C AllocClearFromHeapEC }
function AllocClearFromHeapEC(Heap: Cardinal; ByteCount: Integer): Pointer;
var
  Memory: Pointer;
begin
  Memory := HeapAlloc(Heap, HEAP_ZERO_MEMORY, ByteCount);
  if Memory = nil then
  begin
    raise Exception.Create('AllocClearEC. size=' + SysUtils.IntToStr(ByteCount));
  end;
  Result := Memory;
end;
{ @end $453C9C }

{ @routine $453D38 ReAllocFromHeapREC }
function ReAllocFromHeapREC(Heap: Cardinal; Data: Pointer; ByteCount: Integer): Pointer;

begin
  if (ByteCount <= 0) and (Data <> nil) then
  begin
    HeapFree(Heap, 0, Data);
    Data := nil;
  end
  else if ByteCount <= 0 then Data := nil
  else if (ByteCount > 0) and (Data <> nil) then
  begin
    Data := HeapReAlloc(Heap, 0, Data, ByteCount);
    if Data = nil then
    begin
      raise Exception.Create('ReAllocREC. size=' + SysUtils.IntToStr(ByteCount));
    end;
  end
  else
  begin
    Data := HeapAlloc(Heap, 0, ByteCount);
    if Data = nil then
    begin
      raise Exception.Create('ReAllocREC. size=' + SysUtils.IntToStr(ByteCount));
    end;
  end;
  Result := Data;
end;
{ @end $453D38 }

{ @routine $453E44 FreeFromHeapEC }
procedure FreeFromHeapEC(Heap: Cardinal; Data: Pointer);
begin HeapFree(Heap, 0, Data) end;
{ @end $453E44 }

{ @routine $453E50 AddPointerOffset }
function AddPointerOffset(Data: Pointer; ByteOffset: Integer): Pointer; cdecl;
asm
  MOV EAX, Data
  ADD EAX, ByteOffset
end;
{ @end $453E50 }

{ @routine $453E5C WriteByteEC }
procedure WriteByteEC(Dest: Pointer; Value: Byte); cdecl;
asm
  MOV EDX, Dest
  MOV AL, Value
  MOV [EDX], AL
end;
{ @end $453E5C }

{ @routine $453E6C WriteWordEC }
procedure WriteWordEC(Dest: Pointer; Value: Word); cdecl;
asm
  MOV EDX, Dest
  MOV AX, Value
  MOV [EDX], AX
end;
{ @end $453E6C }

{ @routine $453E7C WriteIntegerEC }
procedure WriteIntegerEC(Dest: Pointer; Value: Integer); cdecl;
asm
  MOV EDX, Dest
  MOV EAX, Value
  MOV [EDX], EAX
end;
{ @end $453E7C }

{ @routine $453E8C WriteInt32EC }
procedure WriteInt32EC(Dest: Pointer; Value: Integer); cdecl;
asm
  MOV EDX, Dest
  MOV EAX, Value
  MOV [EDX], EAX
end;
{ @end $453E8C }

{ @routine $453E9C WriteSingleEC }
procedure WriteSingleEC(Dest: Pointer; Value: Single); cdecl;
asm
  MOV EDX, Dest
  MOV EAX, Value
  MOV [EDX], EAX
end;
{ @end $453E9C }

{ @routine $453EAC WriteDoubleEC }
procedure WriteDoubleEC(Dest: Pointer; Value: Double); cdecl;
asm
  PUSH EBX
  MOV EBX, Dest
  LEA EDX, Value
  MOV EAX, [EDX]
  MOV [EBX], EAX
  MOV EAX, [EDX + 4]
  MOV [EBX + 4], EAX
  POP EBX
end;
{ @end $453EAC }

{ @routine $453EC4 ReadByteEC }
function ReadByteEC(Source: Pointer): Byte; cdecl;
asm
  MOV EAX, Source
  MOV AL, [EAX]
end;
{ @end $453EC4 }

{ @routine $453ED0 ReadWideCharEC }
function ReadWideCharEC(Source: Pointer): WideChar; cdecl;
asm
  MOV EAX, Source
  MOV AX, [EAX]
end;
{ @end $453ED0 }

{ @routine $453EDC ReadWordEC }
function ReadWordEC(Source: Pointer): Word; cdecl;
asm
  MOV EAX, Source
  MOV AX, [EAX]
end;
{ @end $453EDC }

{ @routine $453EE8 ReadDWordEC }
function ReadDWordEC(Source: Pointer): Cardinal; cdecl;
asm
  MOV EAX, Source
  MOV EAX, [EAX]
end;
{ @end $453EE8 }

{ @routine $453EF4 ReadIntegerEC }
function ReadIntegerEC(Source: Pointer): Integer; cdecl;
asm
  MOV EAX, Source
  MOV EAX, [EAX]
end;
{ @end $453EF4 }

{ @routine $453F00 ReadSingleEC }
function ReadSingleEC(Source: Pointer): Single; cdecl;
asm
  MOV EAX, Source
  FLD DWORD PTR [EAX]
end;
{ @end $453F00 }

{ @routine $453F0C ReadDoubleEC }
function ReadDoubleEC(Source: Pointer): Double; cdecl;
asm
  MOV EAX, Source
  FLD QWORD PTR [EAX]
end;
{ @end $453F0C }

end.

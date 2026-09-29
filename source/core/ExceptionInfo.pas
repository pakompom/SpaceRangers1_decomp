unit ExceptionInfo;
// Unit bracket (inferred): CODE 0x004D89B4..0x004D9743; inclusive evidence, not full bounds.
interface
uses Windows;
type
  PWinExceptionRecord = ^TExceptionRecord;
  // D7 SysUtils.GetExceptionObject and Windows.RaiseException signatures.
  TExceptionObjectProc = function(Rec: PWinExceptionRecord): TObject;
  TRaiseExceptionProc = procedure(Code, Flags, ArgumentCount: Cardinal;
    Arguments: PCardinal); stdcall;
  PExceptionContext = ^TExceptionContext;
  // The native RaiseException hook reserves and clears $2CC bytes, including
  // the extended-register tail beyond Delphi 7's $CC-byte Windows.TContext.
  TExceptionContext = packed record // @size $2CC
    DebugAndFloatState: array[0..139] of Byte; // @offset $00
    SegGs: Cardinal; // @offset $8C
    SegFs: Cardinal; // @offset $90
    SegEs: Cardinal; // @offset $94
    SegDs: Cardinal; // @offset $98
    Edi: Cardinal; // @offset $9C
    Esi: Cardinal; // @offset $A0
    Ebx: Cardinal; // @offset $A4
    Edx: Cardinal; // @offset $A8
    Ecx: Cardinal; // @offset $AC
    Eax: Cardinal; // @offset $B0
    Ebp: Cardinal; // @offset $B4
    Eip: Cardinal; // @offset $B8
    SegCs: Cardinal; // @offset $BC
    EFlags: Cardinal; // @offset $C0
    Esp: Cardinal; // @offset $C4
    SegSs: Cardinal; // @offset $C8
    ExtendedRegisters: array[0..511] of Byte; // @offset $CC
  end;
function HexDigit(Value: Byte): WideChar; // @addr $4D89B4
function ByteToHexText(Value: Byte): WideString; // @addr $4D89C4
function DWordToHexText(Value: Cardinal): WideString; // @addr $4D8A04
function FormatExceptionReport(Context: PExceptionContext; Rec: PWinExceptionRecord; Instance: TObject): WideString; // @addr $4D8A98
procedure LogException(Context: PExceptionContext; Rec: PWinExceptionRecord; Instance: TObject); stdcall; // @addr $4D9394
procedure HardwareExceptionHook; // @addr $4D95DC
procedure RaiseExceptionHook; // @addr $4D9600
const
  ExportHexDigits: array[0..15] of WideChar = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'); // @addr $618418
implementation
// @unit-initialization $4D970C
// @unit-finalization $4D96DC
uses SysUtils, MMSystem, GR_Main;
var
  PreviousExceptionObjectProc: TExceptionObjectProc; // @addr $61C9D8
  PreviousRaiseExceptionProc: TRaiseExceptionProc; // @addr $61C9DC

{ @routine $4D89B4 HexDigit }
function HexDigit(Value: Byte): WideChar;
begin
  Result := ExportHexDigits[Value and $F];
end;
{ @end $4D89B4 }
{ @routine $4D89C4 ByteToHexText }
function ByteToHexText(Value: Byte): WideString;
begin
  SetLength(Result, 2);
  Result[1] := HexDigit(Value shr 4);
  Result[2] := HexDigit(Value shr 0); // Native code explicitly emits SHR EAX, 0.
end;
{ @end $4D89C4 }
{ @routine $4D8A04 DWordToHexText }
function DWordToHexText(Value: Cardinal): WideString;
begin
  SetLength(Result, 8);
  Result[1] := HexDigit(Value shr 28);
  Result[2] := HexDigit(Value shr 24);
  Result[3] := HexDigit(Value shr 20);
  Result[4] := HexDigit(Value shr 16);
  Result[5] := HexDigit(Value shr 12);
  Result[6] := HexDigit(Value shr 8);
  Result[7] := HexDigit(Value shr 4);
  Result[8] := HexDigit(Value shr 0); // Native code explicitly emits SHR EAX, 0.
end;
{ @end $4D8A04 }
{ @routine $4D8A98 FormatExceptionReport }
function FormatExceptionReport(Context: PExceptionContext; Rec: PWinExceptionRecord; Instance: TObject): WideString;
var
  Count, ElapsedMs: Integer;
  Buffer: TMemoryBasicInformation;
  Data: PByte;
begin
  Result := '=== Exception context ==='#13#10;
  ElapsedMs := Integer(timeGetTime - RuntimeStartupTick);
  Result := Result + Format('Time: %.2d:%.2d:%.2d:%.3d'#13#10#13#10,
    [ElapsedMs div 3600000, ElapsedMs mod 3600000 div 60000,
     ElapsedMs mod 60000 div 1000, ElapsedMs mod 1000]);
  if Instance <> nil then
  begin
    if Instance is Exception then
      Result := Result + 'RTL: ' + Instance.ClassName + #13#10 +
        Exception(Instance).Message + #13#10 + #13#10
    else
      Result := Result + 'RTL: ' + Instance.ClassName + #13#10 + #13#10;
  end;
  if (Rec <> nil) and (Rec.NumberParameters >= 2) then
  begin
    Result := Result + 'Error:' + #13#10;
    if Rec.ExceptionInformation[0] = 0 then
      Result := Result + 'Read: '
    else
      Result := Result + 'Write: ';
    Result := Result + DWordToHexText(Rec.ExceptionInformation[1]) + #13#10 + #13#10;
  end;
  Result := Result + 'Synchronize:' + #13#10;
  Result := Result + 'myRaiseExceptionProc: ' + DWordToHexText(Cardinal(@RaiseExceptionHook)) + #13#10 + #13#10;
  Result := Result + 'Registers:' + #13#10;
  Result := Result + 'Flags=' + DWordToHexText(Context.EFlags) + #13#10 + #13#10;
  Result := Result + 'EAX=' + DWordToHexText(Context.Eax) + #13#10;
  Result := Result + 'EBX=' + DWordToHexText(Context.Ebx) + #13#10;
  Result := Result + 'ECX=' + DWordToHexText(Context.Ecx) + #13#10;
  Result := Result + 'EDX=' + DWordToHexText(Context.Edx) + #13#10 + #13#10;
  Result := Result + 'ESI=' + DWordToHexText(Context.Esi) + #13#10;
  Result := Result + 'EDI=' + DWordToHexText(Context.Edi) + #13#10 + #13#10;
  Result := Result + 'EBP=' + DWordToHexText(Context.Ebp) + #13#10;
  Result := Result + 'EIP=' + DWordToHexText(Context.Eip) + #13#10;
  Result := Result + 'ESP=' + DWordToHexText(Context.Esp) + #13#10 + #13#10;
  Result := Result + 'DS=' + DWordToHexText(Context.SegDs) + #13#10;
  Result := Result + 'ES=' + DWordToHexText(Context.SegEs) + #13#10;
  Result := Result + 'FS=' + DWordToHexText(Context.SegFs) + #13#10;
  Result := Result + 'GS=' + DWordToHexText(Context.SegGs) + #13#10;
  Result := Result + 'CS=' + DWordToHexText(Context.SegCs) + #13#10;
  Result := Result + 'SS=' + DWordToHexText(Context.SegSs) + #13#10;
  Result := Result + #13#10 + 'Stack:' + #13#10;
  Count := 0;
  if (VirtualQuery(Pointer(Context.Esp), Buffer, SizeOf(Buffer)) <> 0) and
    (Buffer.Protect = PAGE_READWRITE) and (Buffer.AllocationBase <> nil) then
  begin
    Count := Integer(Cardinal(Buffer.BaseAddress) + Buffer.RegionSize - Context.Esp);
    while Count < 4096 do
    begin
      if VirtualQuery(PAnsiChar(Buffer.BaseAddress) + Buffer.RegionSize, Buffer, SizeOf(Buffer)) = 0 then Break
      else if Buffer.Protect <> PAGE_READWRITE then Break
      else if Buffer.AllocationBase = nil then Break
      else Inc(Count, Buffer.RegionSize);
    end;
    if Count > 4096 then Count := 4096;
  end;
  Data := PByte(Context.Esp);
  for Count := 0 to Count - 1 do
  begin
    if Count and $F = 0 then Result := Result + DWordToHexText(Cardinal(Data)) + ':';
    Result := Result + ' ' + ByteToHexText(Data^);
    if Count and $F = $F then Result := Result + #13#10;
    Inc(Data);
  end;
end;
{ @end $4D8A98 }

{ @routine $4D9394 LogException }
procedure LogException(Context: PExceptionContext; Rec: PWinExceptionRecord; Instance: TObject); stdcall;
var
  FileName: AnsiString;
  I: Integer;
  Time: TSystemTime;
begin
  if ExceptionLogGuard = 0 then
  begin
    if SuppressExceptionLogCopy then
      SuppressExceptionLogCopy := False
    else
    begin
      AppendLogLineThreadSafe(AnsiString(FormatExceptionReport(Context, Rec, Instance)));
      CreateDir('Errors');
      GetSystemTime(Time);
      I := 0;
      repeat
        FileName := Format('Errors\%d-%.2d-%.2d %.2d.%.2d.%.2d.%.3d',
          [Time.wYear, Time.wMonth, Time.wDay, Time.wHour, Time.wMinute,
           Time.wSecond, Time.wMilliseconds]);
        if I <> 0 then
        begin
          if I < 10 then FileName := FileName + ' 0' + IntToStr(I)
          else FileName := FileName + ' ' + IntToStr(I);
        end;
        if not FileExists(FileName + '.log') then Break;
        Inc(I);
      until I >= 100;
      if I < 100 then CopyFile('########.log', PAnsiChar(FileName + '.log'), False);
    end;
  end;
end;
{ @end $4D9394 }

{ @routine $4D95DC HardwareExceptionHook }
// Handwritten native hook; reads the exception and context from the caller's SEH frame.
procedure HardwareExceptionHook;
asm
  PUSH EAX
  PUSH EBX
  PUSH ECX
  PUSH EDX
  DB $68; DD 0 // Native PUSH imm32 0; D7 otherwise selects PUSH imm8.
  PUSH [ESP+$1C]
  PUSH [ESP+$28]
  CALL LogException
  POP EDX
  POP ECX
  POP EBX
  POP EAX
  JMP [PreviousExceptionObjectProc]
end;
{ @end $4D95DC }

{ @routine $4D9600 RaiseExceptionHook }
// Handwritten native hook; the synthetic context leaves segment, debug and FPU fields zero.
procedure RaiseExceptionHook;
asm
  CMP DWORD PTR [ESP+4], $0EEDFADE
  JNZ @@Chain
  PUSH EAX
  PUSH EBX
  PUSHFD
  MOV EBX, ESP
  SUB ESP, $2CC
  MOV EAX, 0
@@Clear:
  MOV DWORD PTR [ESP+EAX], 0
  ADD EAX, 4
  CMP EAX, $2CC
  JNZ @@Clear
  MOV EAX, [EBX+8]
  MOV [ESP+$B0], EAX
  MOV EAX, [EBX+4]
  MOV [ESP+$A4], EAX
  MOV [ESP+$A8], EDX
  MOV [ESP+$AC], ECX
  MOV [ESP+$C4], EBX
  MOV [ESP+$A0], ESI
  MOV [ESP+$9C], EDI
  MOV [ESP+$B4], EBP
  MOV EAX, [EBX]
  MOV [ESP+$C0], EAX
  CALL @@CaptureEip
@@CaptureEip:
  POP EAX
  MOV [ESP+$B8], EAX
  CMP DWORD PTR [EBX+$10], $0EEDFADE
  JNZ @@NoObject
  CMP DWORD PTR [EBX+$14], 1
  JNZ @@NoObject
  CMP DWORD PTR [EBX+$18], 7
  JNZ @@NoObject
  LEA EAX, [EBX+$1C]
  ADD EAX, 4
  CMP EAX, [EBX+$1C]
  JNZ @@NoObject
  MOV EAX, [EBX+$1C]
  MOV EAX, [EAX+4]
  PUSH EAX
  JMP @@Log
@@NoObject:
  DB $68; DD 0
@@Log:
  DB $68; DD 0
  MOV EAX, ESP
  ADD EAX, 8
  PUSH EAX
  CALL LogException
  ADD ESP, $2CC
  POPFD
  POP EBX
  POP EAX
  MOV DWORD PTR [ESP+4], $0EEDFADE
@@Chain:
  JMP [PreviousRaiseExceptionProc]
end;
{ @end $4D9600 }

initialization
  PreviousRaiseExceptionProc := TRaiseExceptionProc(RaiseExceptionProc);
  RaiseExceptionProc := @RaiseExceptionHook;
  PreviousExceptionObjectProc := TExceptionObjectProc(ExceptObjProc);
  ExceptObjProc := @HardwareExceptionHook;
end.

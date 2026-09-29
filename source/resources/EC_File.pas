unit EC_File;
// Unit bracket (inferred): CODE 0x004C1E98..0x004C2797; inclusive evidence, not full bounds.

interface

uses EC_Struct;

type
  TFileEC = class(TObjectEx) // @size $10
  public
    // Package index * 16 + open-entry slot; -1 while closed.
    Handle: Integer; // @offset $04
    OpenDepth: Integer; // @offset $08
    FileName: AnsiString; // @offset $0C

    constructor Create; // @addr $4C1F00
    destructor Destroy; override; // @addr $4C1F3C
    procedure Reset; // @addr $4C1F68 @note "Closes even when OpenDepth is nonzero."
    procedure SetFileName(NewFileName: AnsiString); // @addr $4C1FB0 @note "Closes the current entry regardless of OpenDepth."
    function GetFileName: WideString; // @addr $4C23A4
    // Nested acquisitions reuse the existing handle and access mode.
    // File names are ANSI; GetFileName converts the result to WideString.
    procedure AcquireReadWriteHandle; // @addr $4C2004
    function TryAcquireReadHandle: Boolean; // @addr $4C217C
    procedure AcquireReadHandle; // @addr $4C20C0
    procedure ReleaseHandle; // @addr $4C2298 @note "FileName is retained after closing."
    procedure CreateNew; // @addr $4C21C8 @note "Truncates an existing file; ignores prior OpenDepth and leaves it at one."

    function GetSize: Cardinal; // @addr $4C22E0 @note "If closed, opens for read/write and releases that acquisition on success."
    function SetPointer(Offset: Cardinal; Origin: Integer): Cardinal; // @addr $4C23B8 @note "Requires an open entry. Origin 0 is absolute, 1 adds Offset to the current position, 2 subtracts Offset from the size; returns the new position."
    function GetPointer: Cardinal; // @addr $4C24A0 @note "Returns 0xFFFFFFFF when no entry is open."
    procedure ReadBuffer(Dest: Pointer; ByteCount: Cardinal); // @addr $4C24D0 @note "Requires an open entry; raises on backend read failure, including short uncompressed reads."
    function ReadWideString: WideString; // @addr $4C26E4 @note "Consumes UTF-16 code units through the terminating NUL; requires an open entry."
    procedure WriteBuffer(Source: Pointer; ByteCount: Cardinal); // @addr $4C25F0 @note "Requires an open writable uncompressed entry; raises on backend failure or a short write. Zero count does nothing."
  end;

implementation

// @unit-initialization $4C2790
// @unit-finalization $4C2760

uses EC_HsFile, SyncObjs, SysUtils, Windows;

{ @routine $4C1F00 TFileEC_Create }
constructor TFileEC.Create;
begin
  inherited Create;
  Handle := -1;
end;
{ @end $4C1F00 }

{ @routine $4C1F3C TFileEC_Destroy }
destructor TFileEC.Destroy;
begin
  Reset;
  inherited Destroy;
end;
{ @end $4C1F3C }

{ @routine $4C1F68 TFileEC_Reset }
procedure TFileEC.Reset;
begin
  if Handle <> -1 then
  begin
    PackageFileLock.Enter;
    PackageCollection.CloseEntryHandle(Handle);
    PackageFileLock.Leave;
  end;
  OpenDepth := 0;
  Handle := -1;
  FileName := '';
end;
{ @end $4C1F68 }

{ @routine $4C1FB0 TFileEC_SetFileName }
procedure TFileEC.SetFileName(NewFileName: AnsiString);
begin
  Reset;
  FileName := NewFileName;
end;
{ @end $4C1FB0 }

{ @routine $4C2004 TFileEC_AcquireReadWriteHandle }
procedure TFileEC.AcquireReadWriteHandle;
begin
  if OpenDepth = 0 then
  begin
    PackageFileLock.Enter;
    Handle := PackageCollection.OpenEntryByPathAcrossPackages(FileName, GENERIC_READ or GENERIC_WRITE);
    PackageFileLock.Leave;
    if Handle = -1 then raise Exception.Create('TFileEC.Open. FileName=' + FileName);
  end;
  Inc(OpenDepth);
end;
{ @end $4C2004 }

{ @routine $4C20C0 TFileEC_AcquireReadHandle }
procedure TFileEC.AcquireReadHandle;
begin
  if OpenDepth = 0 then
  begin
    PackageFileLock.Enter;
    Handle := PackageCollection.OpenEntryByPathAcrossPackages(FileName, GENERIC_READ);
    PackageFileLock.Leave;
    if Handle = -1 then raise Exception.Create('TFileEC.Open. FileName=' + FileName);
  end;
  Inc(OpenDepth);
end;
{ @end $4C20C0 }

{ @routine $4C217C TFileEC_TryAcquireReadHandle }
function TFileEC.TryAcquireReadHandle: Boolean;
begin
  if OpenDepth = 0 then begin
    PackageFileLock.Enter;
    Handle := PackageCollection.OpenEntryByPathAcrossPackages(FileName, GENERIC_READ);
    PackageFileLock.Leave;
    if Handle = -1 then begin Result := False; Exit; end;
  end;
  Inc(OpenDepth);
  Result := True;
end;
{ @end $4C217C }

{ @routine $4C21C8 TFileEC_CreateNew }
procedure TFileEC.CreateNew;
begin
  OpenDepth := 1;
  ReleaseHandle;
  PackageFileLock.Enter;
  Handle := PackageCollection.CreateLooseFile(FileName);
  PackageFileLock.Leave;
  if Handle = -1 then
  begin
    Handle := -1;
    raise Exception.Create('TFileEC.CreateNew. FileName=' + FileName);
  end;
  OpenDepth := 1;
end;
{ @end $4C21C8 }

{ @routine $4C2298 TFileEC_ReleaseHandle }
procedure TFileEC.ReleaseHandle;
begin
  Dec(OpenDepth);
  if OpenDepth <= 0 then
  begin
    if Handle <> -1 then
    begin
      PackageFileLock.Enter;
      PackageCollection.CloseEntryHandle(Handle);
      PackageFileLock.Leave;
    end;
    Handle := -1;
    OpenDepth := 0;
  end;
end;
{ @end $4C2298 }

{ @routine $4C22E0 TFileEC_GetSize }
function TFileEC.GetSize: Cardinal;
var Size: Cardinal;
begin
  AcquireReadWriteHandle;
  PackageFileLock.Enter;
  Size := PackageCollection.GetEntryHandleSize(Handle);
  PackageFileLock.Leave;
  if Size = $FFFFFFFF then raise Exception.Create('TFileEC.GetSize. FileName=' + FileName);
  ReleaseHandle;
  Result := Size;
end;
{ @end $4C22E0 }

{ @routine $4C23A4 TFileEC_GetFileName }
function TFileEC.GetFileName: WideString;
begin
  Result := FileName;
end;
{ @end $4C23A4 }

{ @routine $4C23B8 TFileEC_SetPointer }
function TFileEC.SetPointer(Offset: Cardinal; Origin: Integer): Cardinal;
var Success: Boolean;
begin
  PackageFileLock.Enter;
  Success := PackageCollection.SeekEntryHandle(Handle, Offset, Origin);
  PackageFileLock.Leave;
  if not Success then raise Exception.Create('TFileEC.SetPointer. FileName=' + FileName);
  PackageFileLock.Enter;
  Result := PackageCollection.GetEntryHandlePosition(Handle);
  PackageFileLock.Leave;
end;
{ @end $4C23B8 }

{ @routine $4C24A0 TFileEC_GetPointer }
function TFileEC.GetPointer: Cardinal;
begin
  PackageFileLock.Enter;
  Result := PackageCollection.GetEntryHandlePosition(Handle);
  PackageFileLock.Leave;
end;
{ @end $4C24A0 }

{ @routine $4C24D0 TFileEC_ReadBuffer }
procedure TFileEC.ReadBuffer(Dest: Pointer; ByteCount: Cardinal);
var Success: Boolean;
begin
  PackageFileLock.Enter;
  Success := PackageCollection.ReadEntryHandle(Handle, Dest^, ByteCount);
  PackageFileLock.Leave;
  if not Success then raise Exception.Create('TFileEC.Read. FileName=' + FileName +
    ' kolbyte=' + SysUtils.IntToStr(ByteCount) + ' GetLastError=' + SysUtils.IntToStr(Windows.GetLastError));
end;
{ @end $4C24D0 }

{ @routine $4C25F0 TFileEC_WriteBuffer }
procedure TFileEC.WriteBuffer(Source: Pointer; ByteCount: Cardinal);
var Success: Boolean;
begin
  if ByteCount > 0 then
  begin
    PackageFileLock.Enter;
    Success := PackageCollection.WriteEntryHandle(Handle, Source^, ByteCount);
    PackageFileLock.Leave;
    if not Success then raise Exception.Create('TFileEC.Write. FileName=' + FileName + ' kolbyte=' + SysUtils.IntToStr(ByteCount));
  end;
end;
{ @end $4C25F0 }

{ @routine $4C26E4 TFileEC_ReadWideString }
function TFileEC.ReadWideString: WideString;
var Ch: WideChar;
begin
  Result := '';
  while True do
  begin
    ReadBuffer(@Ch, SizeOf(Ch));
    if Ch = #0 then Break;
    Result := Result + Ch;
  end;
end;
{ @end $4C26E4 }

end.

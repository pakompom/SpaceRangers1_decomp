unit EC_CPUTime;
// Unit bracket (inferred): CODE 0x004AD248..0x004ADB27; inclusive evidence, not full bounds.
interface
uses SyncObjs;
type
  TCPUTimeUnitEC = class(TObject) // @size $34
  public
    ActiveNext: TCPUTimeUnitEC; // @offset $08
    FreePrev: TCPUTimeUnitEC; // @offset $0C
    FreeNext: TCPUTimeUnitEC; // @offset $10
    Name: WideString; // @offset $14
    StartText: WideString; // @offset $18
    EndText: WideString; // @offset $1C
    StartCounter: Int64; // @offset $20
    EndCounter: Int64; // @offset $28
    Processed: Boolean; // @offset $30
  end;
  TCPUTimeEC = class(TObject) // @size $1C
  public
    constructor Create; // @addr $4AD334

    ActiveFirst: TCPUTimeUnitEC; // @offset $04
    ActiveLast: TCPUTimeUnitEC; // @offset $08
    FreeFirst: TCPUTimeUnitEC; // @offset $0C
    FreeLast: TCPUTimeUnitEC; // @offset $10
    FileName: WideString; // @offset $14
    Lock: TCriticalSection; // @offset $18
    destructor Destroy; override; // @addr $4AD384
    procedure Clear; // @addr $4AD3DC
    procedure AllocateEntries(Count: Integer); // @addr $4AD414
    procedure Save(AppendToFile: Boolean); // @addr $4AD454
  end;
implementation

// @unit-initialization $4ADB20
// @unit-finalization $4ADAF0

uses SysUtils, GR_Main;

{ @routine $4AD334 TCPUTimeEC_Create }
constructor TCPUTimeEC.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  AllocateEntries(1000);
end;
{ @end $4AD334 }

{ @routine $4AD384 TCPUTimeEC_Destroy }
destructor TCPUTimeEC.Destroy;
var Entry, Old: TCPUTimeUnitEC;
begin
  Clear;
  Entry := FreeFirst;
  while Entry <> nil do begin
    Old := Entry;
    Entry := Entry.FreeNext;
    Old.Free;
  end;
  FreeFirst := nil;
  FreeLast := nil;
  Lock.Free;
  inherited Destroy;
end;
{ @end $4AD384 }

{ @routine $4AD3DC TCPUTimeEC_Clear }
procedure TCPUTimeEC.Clear;
var Entry: TCPUTimeUnitEC;
begin
  while ActiveFirst <> nil do begin
    Entry := ActiveFirst;
    ActiveFirst := ActiveFirst.ActiveNext;
    if FreeLast <> nil then FreeLast.FreeNext := Entry;
    Entry.FreePrev := FreeLast;
    Entry.FreeNext := nil;
    FreeLast := Entry;
    if FreeFirst = nil then FreeFirst := Entry;
  end;
  ActiveLast := nil;
end;
{ @end $4AD3DC }

{ @routine $4AD414 TCPUTimeEC_AllocateEntries }
procedure TCPUTimeEC.AllocateEntries(Count: Integer);
var Entry: TCPUTimeUnitEC;
begin
  while Count > 0 do begin
    Entry := TCPUTimeUnitEC.Create;
    if FreeLast <> nil then FreeLast.FreeNext := Entry;
    Entry.FreePrev := FreeLast;
    Entry.FreeNext := nil;
    FreeLast := Entry;
    if FreeFirst = nil then FreeFirst := Entry;
    Dec(Count);
  end;
end;
{ @end $4AD414 }

{ @routine $4AD454 TCPUTimeEC_Save }
{$I-}
procedure TCPUTimeEC.Save(AppendToFile: Boolean);
var
  Entry, Other: TCPUTimeUnitEC;
  Count: Integer;
  Total: Int64;
  LogFile: TextFile;
begin
  { Native logging ignores I/O errors and does not guard the lock with finally. }
  Lock.Enter;
  AssignFile(LogFile, FileName);
  if AppendToFile then Append(LogFile) else Rewrite(LogFile);
  if ActiveFirst = nil then begin
    CloseFile(LogFile);
    Lock.Leave;
    Exit;
  end;
  WriteLn(LogFile, '##################################################');
  WriteLn(LogFile, '#### Start ####');
  WriteLn(LogFile, '##################################################');
  Entry := ActiveFirst;
  while Entry <> nil do begin
    Write(LogFile, Format('%s', [Entry.Name]));
    if Entry.EndCounter = 0 then
      Write(LogFile, '  Not end.')
    else
      Write(LogFile, Format('  Time=%.5f(%d)', [(Entry.EndCounter - Entry.StartCounter) / CounterFrequency,
        Entry.EndCounter - Entry.StartCounter]));
    if Entry.StartText <> '' then Write(LogFile, Format('  S={%s}', [Entry.StartText]));
    if Entry.EndText <> '' then Write(LogFile, Format('  E={%s}', [Entry.EndText]));
    WriteLn(LogFile, '');
    Entry := Entry.ActiveNext;
  end;
  WriteLn(LogFile, '##################################################');
  Entry := ActiveFirst;
  while Entry <> nil do begin
    Entry.Processed := False;
    Entry := Entry.ActiveNext;
  end;
  Entry := ActiveFirst;
  while Entry <> nil do begin
    if not Entry.Processed and (Entry.EndCounter <> 0) then begin
      Count := 0;
      Total := 0;
      Other := Entry;
      while Other <> nil do begin
        if (Entry.Name = Other.Name) and not Other.Processed and (Other.EndCounter <> 0) then begin
          Inc(Count);
          Total := Total + (Other.EndCounter - Other.StartCounter);
          Other.Processed := True;
        end;
        Other := Other.ActiveNext;
      end;
      Write(LogFile, Format('%s', [Entry.Name]));
      Write(LogFile, Format('  Time=%.5f(%d)', [Total / CounterFrequency, Total]));
      Write(LogFile, Format('  Count=%d', [Count]));
      Write(LogFile, Format('  Ave=%.5f(%.5f)', [Total / Count / CounterFrequency, Total / Count]));
      WriteLn(LogFile, '');
    end;
    Entry := Entry.ActiveNext;
  end;
  WriteLn(LogFile, '##################################################');
  WriteLn(LogFile, '#### End ####');
  WriteLn(LogFile, '##################################################');
  CloseFile(LogFile);
  Lock.Leave;
end;
{$I+}
{ @end $4AD454 }

end.

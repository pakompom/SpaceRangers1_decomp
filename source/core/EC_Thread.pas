unit EC_Thread;
// Unit bracket (inferred): CODE 0x004BE10C..0x004BE6F7; inclusive evidence, not full bounds.

interface

uses EC_Struct, SyncObjs;

type
  TThreadEC = class(TObjectEx) // @size $2C
  public
    Lock: TCriticalSection; // @offset $4
    ThreadHandle: Cardinal; // @offset $8
    ThreadId: Cardinal; // @offset $C
    Priority: Byte; // @offset $10
    StopRequested: Boolean; // @offset $11
    StopEvent: Cardinal; // @offset $14
    // Set/cleared by two helpers; its purpose is unresolved.
    Flag18: Boolean; // @offset $18
    ShutdownEvent: Cardinal; // @offset $1C
    StartEvent: Cardinal; // @offset $20
    RunningEvent: Cardinal; // @offset $24
    IdleEvent: Cardinal; // @offset $28

    constructor Create; // @addr $4BE1C0
    destructor Destroy; override; // @addr $4BE338
    procedure ProcessRequests; // @addr $4BE3D8
    procedure Execute; virtual; // @addr $4BE528 @slot $00
    procedure SetPriority(Value: Byte); // @addr $4BE544
    procedure SetFlag18; // @addr $4BE560
    procedure ClearFlag18; // @addr $4BE568
    procedure RequestStop; // @addr $4BE570
    function IsStopRequested: Boolean; // @addr $4BE594
    procedure SetStopRequested(Value: Boolean); // @addr $4BE5B0
    procedure Start; // @addr $4BE5E0 @note "Schedules Execute on the existing OS thread; does nothing while a run is pending or active."
    function IsRunning: Boolean; // @addr $4BE670
    function WaitForIdle(TimeoutMs: Cardinal): Boolean; // @addr $4BE69C @note "False only on timeout; a wait failure also returns true."
  end;

function ThreadEntryEC(Thread: Pointer): Integer; // @addr $4BE168

const
  // Indices into ThreadPriorityValues, not Win32 priority values.
  ThreadPriorityLowest = 1;
  ThreadPriorityAboveNormal = 4;

  ThreadPriorityValues: array[0..6] of Integer = (-15, -2, -1, 0, 1, 2, 15); // @addr $617FD0

implementation

// @unit-initialization $4BE6F0
// @unit-finalization $4BE6C0

uses Windows, SysUtils, GR_Main;

{ @routine $4BE168 ThreadEntryEC }
function ThreadEntryEC(Thread: Pointer): Integer;
var Worker: TThreadEC absolute Thread;
begin
  try
    Worker.ProcessRequests;
  finally
    if Worker.ThreadHandle <> 0 then
    begin
      CloseHandle(Worker.ThreadHandle);
      Worker.ThreadHandle := 0;
    end;
    Worker.ThreadId := 0;
  end;
  Result := 0;
end;
{ @end $4BE168 }

{ @routine $4BE1C0 TThreadEC_Create }
constructor TThreadEC.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  StopEvent := CreateEvent(nil, True, False, nil);
  if StopEvent = 0 then raise Exception.Create('TThreadEC.Create CreateEvent');
  ShutdownEvent := CreateEvent(nil, False, False, nil);
  if ShutdownEvent = 0 then raise Exception.Create('TThreadEC.Create CreateEvent');
  StartEvent := CreateEvent(nil, False, False, nil);
  if StartEvent = 0 then raise Exception.Create('TThreadEC.Create CreateEvent');
  RunningEvent := CreateEvent(nil, True, False, nil);
  if RunningEvent = 0 then raise Exception.Create('TThreadEC.Create CreateEvent');
  IdleEvent := CreateEvent(nil, True, True, nil);
  if IdleEvent = 0 then raise Exception.Create('TThreadEC.Create CreateEvent');
  ThreadHandle := BeginThread(nil, 0, @ThreadEntryEC, Self, CREATE_SUSPENDED, ThreadId);
  SetThreadPriority(ThreadHandle, THREAD_PRIORITY_NORMAL);
  ResumeThread(ThreadHandle);
end;
{ @end $4BE1C0 }

{ @routine $4BE338 TThreadEC_Destroy }
destructor TThreadEC.Destroy;
begin
  if ShutdownEvent <> 0 then
  begin
    SetEvent(ShutdownEvent);
    WaitForSingleObject(ThreadHandle, INFINITE);
  end;
  if IdleEvent <> 0 then
  begin CloseHandle(IdleEvent); IdleEvent := 0 end;
  if StartEvent <> 0 then
  begin CloseHandle(StartEvent); StartEvent := 0 end;
  if RunningEvent <> 0 then
  begin CloseHandle(RunningEvent); RunningEvent := 0 end;
  if ShutdownEvent <> 0 then
  begin CloseHandle(ShutdownEvent); ShutdownEvent := 0 end;
  if StopEvent <> 0 then
  begin CloseHandle(StopEvent); StopEvent := 0 end;
  Lock.Free;
  inherited Destroy;
end;
{ @end $4BE338 }

{ @routine $4BE3D8 TThreadEC_ProcessRequests }
procedure TThreadEC.ProcessRequests;
var Events: array[0..1] of THandle;
    WaitResult: Cardinal;
begin
  Events[0] := ShutdownEvent;
  Events[1] := StartEvent;
  while True do
  begin
    WaitResult := WaitForMultipleObjects(Length(Events), @Events, False, INFINITE);
    if WaitResult <> WAIT_OBJECT_0 + 1 then Break;
    Lock.Enter;
    try
      if not IsRunning then
      begin
        ResetEvent(StopEvent);
        StopRequested := False;
        ResetEvent(IdleEvent);
        SetEvent(RunningEvent);
      end;
    finally
      Lock.Leave;
    end;
    try
      Execute;
    except
      AppendLogLineThreadSafe('Thread exception');
    end;
    Lock.Enter;
    try
      ResetEvent(RunningEvent);
      SetEvent(IdleEvent);
    finally
      Lock.Leave;
    end;
  end;
end;
{ @end $4BE3D8 }

{ @routine $4BE528 TThreadEC_Execute }
procedure TThreadEC.Execute;
begin
  while not IsStopRequested do SysUtils.Sleep(100);
end;
{ @end $4BE528 }

{ @routine $4BE544 TThreadEC_SetPriority }
procedure TThreadEC.SetPriority(Value: Byte);
begin
  Priority := Value;
  if ThreadHandle <> 0 then SetThreadPriority(ThreadHandle, ThreadPriorityValues[Integer(Value) and $7F]);
end;
{ @end $4BE544 }

{ @routine $4BE560 TThreadEC_SetFlag18 }
procedure TThreadEC.SetFlag18;
begin
  Flag18 := True;
end;
{ @end $4BE560 }

{ @routine $4BE568 TThreadEC_ClearFlag18 }
procedure TThreadEC.ClearFlag18;
begin
  Flag18 := False;
end;
{ @end $4BE568 }

{ @routine $4BE570 TThreadEC_RequestStop }
procedure TThreadEC.RequestStop;
begin
  Lock.Enter;
  StopRequested := True;
  SetEvent(StopEvent);
  Lock.Leave;
end;
{ @end $4BE570 }

{ @routine $4BE594 TThreadEC_IsStopRequested }
function TThreadEC.IsStopRequested: Boolean;
begin
  Lock.Enter;
  Result := StopRequested;
  Lock.Leave;
end;
{ @end $4BE594 }

{ @routine $4BE5B0 TThreadEC_SetStopRequested }
procedure TThreadEC.SetStopRequested(Value: Boolean);
begin
  if Value then RequestStop
  else
  begin
    Lock.Enter;
    StopRequested := False;
    ResetEvent(StopEvent);
    Lock.Leave;
  end;
end;
{ @end $4BE5B0 }

{ @routine $4BE5E0 TThreadEC_Start }
procedure TThreadEC.Start;
begin
  Lock.Enter;
  try
    if IsRunning then Exit;
    ResetEvent(StopEvent);
    StopRequested := False;
    ResetEvent(IdleEvent);
    SetEvent(RunningEvent);
    SetEvent(StartEvent);
  finally
    Lock.Leave;
  end;
end;
{ @end $4BE5E0 }

{ @routine $4BE670 TThreadEC_IsRunning }
function TThreadEC.IsRunning: Boolean;
begin
  Lock.Enter;
  Result := WaitForSingleObject(IdleEvent, 0) = WAIT_TIMEOUT;
  Lock.Leave;
end;
{ @end $4BE670 }

{ @routine $4BE69C TThreadEC_WaitForIdle }
function TThreadEC.WaitForIdle(TimeoutMs: Cardinal): Boolean;
begin
  if WaitForSingleObject(IdleEvent, TimeoutMs) = WAIT_TIMEOUT then Result := False
  else Result := True;
end;
{ @end $4BE69C }

end.

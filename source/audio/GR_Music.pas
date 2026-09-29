unit GR_Music;
// Unit bracket (inferred): CODE 0x004BA4A8..0x004BB617; inclusive evidence, not full bounds.

interface

uses EC_Thread, EC_FileStream, GR_Sound, SyncObjs;

type
  TMusicReadCallback = function(Destination: Pointer; ByteCount: Integer; Context: Pointer): Integer; cdecl;
  TMusicDecoderInit = function(Reader: TMusicReadCallback; Context: Pointer; Format: Pointer): Integer; stdcall;
  TMusicDecoderClear = procedure; stdcall;
  TMusicUnit = class(TThreadEC) // @size $54
  public
    ImmediateStop: Boolean; // @offset $2C
    Buffer: TSoundBuffer; // @offset $30
    DecodeLock: TCriticalSection; // @offset $34
    DecoderLibrary: Cardinal; // @offset $38
    DecoderInit: TMusicDecoderInit; // @offset $3C
    DecoderClear: TMusicDecoderClear; // @offset $40
    DecoderRead: TSoundStreamReader; // @offset $44
    Stream: TFileStreamEC; // @offset $48
    StartPlaybackEvent: Cardinal; // @offset $4C
    CompletionEvent: Cardinal; // @offset $50
    constructor Create(LibraryName: PAnsiChar); // @addr $4BA574
    destructor Destroy; override; // @addr $4BA950
    procedure Clear; // @addr $4BA9F4
    procedure LoadFile(const FileName: WideString; Deferred: Boolean); // @addr $4BAA3C
    function GetFileName: WideString; // @addr $4BAB3C
    procedure Execute; override; // @addr $4BAB9C
  end;
  TMusicControl = class(TThreadEC) // @size $40
  public
    CompletionEvent: Cardinal; // @offset $2C
    ControlLock: TCriticalSection; // @offset $30
    Current: TMusicUnit; // @offset $34
    Queued: TMusicUnit; // @offset $38
    CurrentFileName: WideString; // @offset $3C
    constructor Create; // @addr $4BADC0
    destructor Destroy; override; // @addr $4BAF00
    procedure Clear; // @addr $4BAF78
    procedure Execute; override; // @addr $4BB00C
    procedure PlayFile(const FileName: WideString); // @addr $4BB0D0
    procedure PlayCategory(const Category: WideString); // @addr $4BB1A4
    procedure RequestFadeOut; // @addr $4BB29C
    procedure StopImmediately; // @addr $4BB2C0
    function HasSelectedMusic: Boolean; // @addr $4BB2EC
    function IsPlaying: Boolean; // @addr $4BB3AC
  end;

function GetMusicFile(const path, curplayfile: WideString): WideString; // @addr $4BB43C

function ReadMusicData(Destination: Pointer; ByteCount: Integer; Context: Pointer): Integer; cdecl; // @addr $4BAB84

implementation

// @unit-initialization $4BB610
// @unit-finalization $4BB5E0

uses Windows, SysUtils, GR_DirectX, EC_Str, EC_BlockPar, GR_Main, GlobalsV, aMyFunction;

{ @routine $4BA574 TMusicUnit_Create }
constructor TMusicUnit.Create(LibraryName: PAnsiChar);
begin
  inherited Create;
  Buffer := nil;
  DecodeLock := nil;
  DecodeLock := TCriticalSection.Create;
  AppendLogTextThreadSafe('Load ' + AnsiString(LibraryName) + ' .... ');
  try
    DecoderLibrary := LoadLibrary(LibraryName);
  except
    AppendLogLineThreadSafe('fail');
    raise;
  end;
  if DecoderLibrary = 0 then
  begin
    AppendLogLineThreadSafe('fail GetLastError=' + IntToStr(GetLastError));
    raise Exception.Create('Error load=' + AnsiString(LibraryName) + '  GetLastError=' + IntToStr(GetLastError));
  end;
  AppendLogLineThreadSafe('ok');
  @DecoderInit := GetProcAddress(DecoderLibrary, 'OKMP_Init');
  if Cardinal(@DecoderInit) = 0 then
    raise Exception.Create('Error load=' + AnsiString(LibraryName) + ' Fun=OKMP_Init GetLastError=' + IntToStr(GetLastError));
  @DecoderClear := GetProcAddress(DecoderLibrary, 'OKMP_Clear');
  if Cardinal(@DecoderClear) = 0 then
    raise Exception.Create('Error load=' + AnsiString(LibraryName) + ' Fun=OKMP_Clear GetLastError=' + IntToStr(GetLastError));
  @DecoderRead := GetProcAddress(DecoderLibrary, 'OKMP_Decode');
  if Cardinal(@DecoderRead) = 0 then
    raise Exception.Create('Error load=' + AnsiString(LibraryName) + ' Fun=OKMP_Decode GetLastError=' + IntToStr(GetLastError));
  Buffer := SoundManager.AddBuffer;
end;
{ @end $4BA574 }

{ @routine $4BA950 TMusicUnit_Destroy }
destructor TMusicUnit.Destroy;
begin
  if IsRunning then
  begin
    RequestStop;
    if StartPlaybackEvent <> 0 then SetEvent(StartPlaybackEvent);
    WaitForIdle(INFINITE);
  end;
  Clear;
  if Buffer <> nil then
  begin
    SoundManager.RemoveBuffer(Buffer);
    Buffer := nil;
  end;
  if DecoderLibrary <> 0 then
  begin
    FreeLibrary(DecoderLibrary);
    DecoderLibrary := 0;
  end;
  if DecodeLock <> nil then
  begin
    DecodeLock.Free;
    DecodeLock := nil;
  end;
  DecoderInit := nil;
  DecoderClear := nil;
  DecoderRead := nil;
  inherited Destroy;
end;
{ @end $4BA950 }

{ @routine $4BA9F4 TMusicUnit_Clear }
procedure TMusicUnit.Clear;
begin
  ImmediateStop := False;
  Buffer.Clear;
  DecoderClear;
  if StartPlaybackEvent <> 0 then
  begin
    CloseHandle(StartPlaybackEvent);
    StartPlaybackEvent := 0;
  end;
  DecodeLock.Enter;
  if Stream <> nil then
  begin
    Stream.Free;
    Stream := nil;
  end;
  DecodeLock.Leave;
end;
{ @end $4BA9F4 }

{ @routine $4BAA3C TMusicUnit_LoadFile }
procedure TMusicUnit.LoadFile(const FileName: WideString; Deferred: Boolean);
begin
  if GetFileName <> FileName then
  begin
    if IsRunning then
    begin
      RequestStop;
      if StartPlaybackEvent <> 0 then SetEvent(StartPlaybackEvent);
      WaitForIdle(INFINITE);
    end;
    Clear;
    Stream := TFileStreamEC.Create($400FF, FileName);
    if Deferred then
    begin
      SetPriority(ThreadPriorityLowest);
      StartPlaybackEvent := CreateEvent(nil, False, False, nil);
      if StartPlaybackEvent = 0 then raise Exception.Create('CreateEvent');
    end
    else SetPriority(ThreadPriorityAboveNormal);
    Start;
  end;
end;
{ @end $4BAA3C }

{ @routine $4BAB3C TMusicUnit_GetFileName }
function TMusicUnit.GetFileName: WideString;
begin
  if not IsRunning then Result := '';
  DecodeLock.Enter;
  if Stream = nil then Result := ''
  else Result := Stream.SourceFile.GetFileName;
  DecodeLock.Leave;
end;
{ @end $4BAB3C }

{ @routine $4BAB84 ReadMusicData }
function ReadMusicData(Destination: Pointer; ByteCount: Integer; Context: Pointer): Integer; cdecl;
var Music: TMusicUnit;
begin
  Music := TMusicUnit(Context);
  Result := Music.Stream.Read(Destination, ByteCount);
end;
{ @end $4BAB84 }

{ @routine $4BAB9C TMusicUnit_Execute }
procedure TMusicUnit.Execute;
var
  Ended: Boolean;
  Format: TSoundWaveFormat;
  Chunk: Integer;

begin
  if DecoderInit(@ReadMusicData, Self, @Format) = 0 then
  begin
    Clear;
    SetEvent(CompletionEvent);
    Exit;
  end;
  try
    Buffer.InitStream(176400, @Format);
    if not Buffer.WriteStream(DecoderRead, 1) then
    begin
      Clear;
      SetEvent(CompletionEvent);
      Exit;
    end;
    if not Buffer.WriteStream(DecoderRead, 2) then
    begin
      Clear;
      SetEvent(CompletionEvent);
      Exit;
    end;
    if StartPlaybackEvent <> 0 then
    begin
      WaitForSingleObject(StartPlaybackEvent, INFINITE);
      if IsStopRequested then
      begin
        Clear;
        SetEvent(CompletionEvent);
        Exit;
      end;
      SetPriority(ThreadPriorityAboveNormal);
      SysUtils.Sleep(100);
      SysUtils.Sleep(100);
    end;
    Ended := False;
    Buffer.SetVolumeScale(0);
    Buffer.StartVolumeRamp(100, 0.1);
    Buffer.Play(False);
    Chunk := Buffer.WaitForChunk;
    while not Ended do
    begin
      if ImmediateStop then Break;
      if IsStopRequested then
      begin
        SetStopRequested(False);
        Buffer.StartVolumeRamp(100, -0.1);
      end;
      Ended := not Buffer.WriteStream(DecoderRead, Chunk);
      if Stream.EndOfFile then
        if Stream.FillAvailable + Stream.ReadAvailable <= $C800 then RequestStop;
      Chunk := Buffer.WaitForChunk;
      if Chunk < 0 then Break;
    end;
  except
  end;
  Clear;
  SetEvent(CompletionEvent);
end;
{ @end $4BAB9C }

{ @routine $4BADC0 TMusicControl_Create }
constructor TMusicControl.Create;
begin
  inherited Create;
  Current := nil;
  Queued := nil;
  ControlLock := TCriticalSection.Create;
  if MusicEnabled then
  begin
    if MusicEnabled then
    begin
      Current := TMusicUnit.Create('OKMPA.dll');
    Queued := TMusicUnit.Create('OKMPB.dll');
      Current.CompletionEvent := CompletionEvent;
      Queued.CompletionEvent := 0;
    end;
    SetPriority(ThreadPriorityAboveNormal);
    CompletionEvent := CreateEvent(nil, False, False, nil);
    if CompletionEvent = 0 then raise Exception.Create('CreateEvent');
    if MusicEnabled then Start;
    AppendLogLineThreadSafe('Create music .... ok');
  end;
end;
{ @end $4BADC0 }

{ @routine $4BAF00 TMusicControl_Destroy }
destructor TMusicControl.Destroy;
begin
  RequestStop;
  if CompletionEvent <> 0 then SetEvent(CompletionEvent);
  if IsRunning then WaitForIdle(INFINITE);
  Clear;
  if CompletionEvent <> 0 then
  begin
    CloseHandle(CompletionEvent);
    CompletionEvent := 0;
  end;
  if ControlLock <> nil then
  begin
    ControlLock.Free;
    ControlLock := nil;
  end;
  inherited Destroy;
end;
{ @end $4BAF00 }

{ @routine $4BAF78 TMusicControl_Clear }
procedure TMusicControl.Clear;
begin
  if Current <> nil then
  begin
    Current.RequestStop;
    SetEvent(Current.StartPlaybackEvent);
  end;
  if Queued <> nil then
  begin
    Queued.RequestStop;
    SetEvent(Queued.StartPlaybackEvent);
  end;
  if Current <> nil then
    if Current.IsRunning then Current.WaitForIdle(INFINITE);
  if Queued <> nil then
    if Queued.IsRunning then Queued.WaitForIdle(INFINITE);
  if Current <> nil then
  begin
    Current.Free;
    Current := nil;
  end;
  if Queued <> nil then
  begin
    Queued.Free;
    Queued := nil;
  end;
end;
{ @end $4BAF78 }

{ @routine $4BB00C TMusicControl_Execute }
procedure TMusicControl.Execute;
var Previous: TMusicUnit;
begin
  while not IsStopRequested do
  begin
    WaitForSingleObject(CompletionEvent, INFINITE);
    if IsStopRequested then Break;
    SysUtils.Sleep(10);
    ControlLock.Enter;
    if Queued.IsRunning then
    begin
      Previous := Current;
      Current := Queued;
      Queued := Previous;
      CurrentFileName := Current.GetFileName;
      Current.CompletionEvent := CompletionEvent;
      Queued.CompletionEvent := 0;
      if Current.StartPlaybackEvent <> 0 then SetEvent(Current.StartPlaybackEvent);
    end;
    ControlLock.Leave;
  end;
end;
{ @end $4BB00C }

{ @routine $4BB0D0 TMusicControl_PlayFile }
procedure TMusicControl.PlayFile(const FileName: WideString);
begin
  if not MusicEnabled then Exit;
  if FileName = '' then Exit;
  ControlLock.Enter;
  try
    if Queued.IsRunning then
    begin
      Queued.RequestStop;
      SetEvent(Queued.StartPlaybackEvent);
      Queued.WaitForIdle(INFINITE);
    end;
    Queued.LoadFile(FileName, True);
    if Current.IsRunning then Current.RequestStop
    else SetEvent(CompletionEvent);
  finally
    ControlLock.Leave;
  end;
end;
{ @end $4BB0D0 }

{ @routine $4BB1A4 TMusicControl_PlayCategory }
procedure TMusicControl.PlayCategory(const Category: WideString);
var Chosen: WideString;
begin
  if MusicEnabled then
  begin
    ControlLock.Enter;
    try
      Chosen := GetMusicFile(Category, Current.GetFileName);
      if (Chosen <> '') and (Chosen = CurrentFileName) then
        Chosen := GetMusicFile('All', Current.GetFileName);
      PlayFile(Chosen);
    finally
      ControlLock.Leave;
    end;
  end;
end;
{ @end $4BB1A4 }

{ @routine $4BB29C TMusicControl_RequestFadeOut }
procedure TMusicControl.RequestFadeOut;
begin
  if MusicEnabled and Current.IsRunning then Current.RequestStop;
end;
{ @end $4BB29C }

{ @routine $4BB2C0 TMusicControl_StopImmediately }
procedure TMusicControl.StopImmediately;
begin
  if MusicEnabled and Current.IsRunning then
  begin
    Current.RequestStop;
    Current.ImmediateStop := True;
  end;
end;
{ @end $4BB2C0 }

{ @routine $4BB2EC TMusicControl_HasSelectedMusic }
function TMusicControl.HasSelectedMusic: Boolean;
begin
  ControlLock.Enter;
  try
    Result := (Current.GetFileName <> '') or (Queued.GetFileName <> '');
  finally
    ControlLock.Leave;
  end;
end;
{ @end $4BB2EC }

{ @routine $4BB3AC TMusicControl_IsPlaying }
function TMusicControl.IsPlaying: Boolean;
begin
  ControlLock.Enter;
  try
    Result := ((Current <> nil) and (Current.Buffer <> nil) and Current.Buffer.IsPlaying) or
      ((Queued <> nil) and (Queued.Buffer <> nil) and Queued.Buffer.IsPlaying);
  finally
    ControlLock.Leave;
  end;
end;
{ @end $4BB3AC }

{ @routine $4BB43C GetMusicFile }
function GetMusicFile(const path, curplayfile: WideString): WideString;
var
  bp: TBlockParEC;
  count, i, t: Integer;
begin
  try
    bp := MainDataConfig.BlockPath['Music.' + path];
    count := bp.GetParamCount;
    for i := 0 to count - 1 do
      if TrimWideString(LowerCaseWideString(bp.GetParamValue(i))) = curplayfile then
      begin
        Result := '';
        Exit;
      end;
    t := 0;
    for i := 0 to count - 1 do
      Inc(t, ExtractDigitsToIntW(bp.GetParamName(i)));
    t := RandomIntRange(0, t - 1);
    for i := 0 to count - 1 do
    begin
      Dec(t, ExtractDigitsToIntW(bp.GetParamName(i)));
      if t < 0 then
      begin
        Result := TrimWideString(LowerCaseWideString(bp.GetParamValue(i)));
        Exit;
      end;
    end;
  except
    Result := '';
  end;
end;
{ @end $4BB43C }

end.

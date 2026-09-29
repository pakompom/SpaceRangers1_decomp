unit GR_Sound;
// Unit bracket (inferred): CODE 0x004BB618..0x004BE10B; inclusive evidence, not full bounds.

interface

uses EC_Struct, GR_DirectX, SyncObjs;

const
  SoundStreamPrimeAll = -1;

type

  TSoundStreamReader = function(Data: Pointer; var ByteCount: Integer): LongBool; stdcall;

  TSoundBufferControl = class;
  TSoundBuffer = class;
  TSoundControl = class;

  TSoundBufferControl = class(TObjectEx) // @size $14
  public
    SoundPath: WideString; // @offset $04
    SoundGroup: Integer; // @offset $08  Nonzero groups suppress quieter concurrent sounds in the same group.
    Buffer: TSoundBuffer; // @offset $0C  Borrowed from the sound manager; the buffer holds a back-reference to this controller.
    Volume: Single; // @offset $10

    constructor Create; // @addr $4BB774
    destructor Destroy; override; // @addr $4BB7AC
    procedure Clear; // @addr $4BB7D8 @note "Clears the active buffer and volume, retaining the path and group."
    procedure Configure(const Path: WideString; Group: Integer); // @addr $4BB7F8 @note "Identical paths leave every setting unchanged, including the group."
    procedure SetVolume(Value: Single); // @addr $4BB828 @note "Unchanged values do nothing. Looping sounds start lazily at nonzero volume; changing to zero clears an active loop. The controller retains the unclamped value."
  end;

  TSoundBuffer = class(TObjectEx) // @size $60
  public
    Prev: TSoundBuffer; // @offset $04
    Next: TSoundBuffer; // @offset $08
    AutoRelease: Boolean; // @offset $0C
    Streaming: Boolean; // @offset $0D
    Started: Boolean; // @offset $0E
    DirectBuffer: IDirectSoundBuffer; // @offset $10
    Notify: IDirectSoundNotify; // @offset $14
    // WaitForChunk passes this contiguous stop/chunk/volume event sequence to Win32.
    StopEvent: Cardinal; // @offset $18
    ChunkEvents: array[0..2] of Cardinal; // @offset $1C
    VolumeEvent: Cardinal; // @offset $28
    BufferBytes: Integer; // @offset $2C  One chunk when Streaming, otherwise the whole buffer.
    WaveFormat: TSoundWaveFormat; // @offset $30
    VolumeTimer: Cardinal; // @offset $44
    Volume: Single; // @offset $48
    VolumeScale: Single; // @offset $4C
    VolumeStep: Single; // @offset $50
    FadingOut: Boolean; // @offset $54
    SoundGroup: Integer; // @offset $58
    Controller: TSoundBufferControl; // @offset $5C

    destructor Destroy; override; // @addr $4BB9F0
    procedure Clear; // @addr $4BBA78
    function WaitForChunk: Integer; // @addr $4BC4A0
    procedure SignalStop; // @addr $4BC630
    procedure SetVolumeScale(Value: Single); // @addr $4BC724
    procedure StartVolumeRamp(Interval: Cardinal; Step: Single); // @addr $4BC73C
    constructor Create; // @addr $4BB89C
    procedure Init(ByteCount: Integer; Format: Pointer); // @addr $4BBB24 @note "Copies 20 bytes from Format into internal wave-format storage."
    procedure InitStream(ChunkBytes: Integer; Format: Pointer); // @addr $4BBC70 @note "Copies 20 bytes from Format; allocates three chunks of streaming audio."
    procedure ClearBuf; // @addr $4BBF20 @note "Fills the audio buffer with silence; does not release it."
    procedure Write(Data: Pointer; ByteCount: Cardinal; Format: Pointer); // @addr $4BC04C @note "Format points to 20 bytes; data and format are copied, not retained."
    function WriteStream(Reader: TSoundStreamReader; Chunk: Integer): Boolean; // @addr $4BC198 @note "Reader fills one temporary chunk. Chunk selects the preceding ring-buffer segment. False indicates a short read or a nonstreaming buffer."
    procedure Play(Looping: Boolean); // @addr $4BC36C @note "Streaming buffers always loop."
    function IsPlaying: Boolean; // @addr $4BC560
    procedure SetVolume(Value: Single); // @addr $4BC63C @note "Stores the unclamped value and combines it with the buffer's secondary volume multiplier."
  end;

  TSoundControl = class(TObjectEx) // @size $30
  public
    FirstBuffer: TSoundBuffer; // @offset $04
    LastBuffer: TSoundBuffer; // @offset $08
    DirectSound: IDirectSound; // @offset $0C
    PrimaryBuffer: IDirectSoundBuffer; // @offset $10
    WaveFormat: TSoundWaveFormat; // @offset $14
    Lock: TCriticalSection; // @offset $28
    LastFadeTick: Cardinal; // @offset $2C

    destructor Destroy; override; // @addr $4BD9F8
    procedure Clear; // @addr $4BDA3C
    procedure StopUncontrolledSounds; // @addr $4BDA54
    function AddBuffer: TSoundBuffer; // @addr $4BDAA0
    procedure RemoveBuffer(Buffer: TSoundBuffer); // @addr $4BDB38
    function SuppressGroup(Group: Integer; Volume: Single): Boolean; // @addr $4BDBC4
    procedure RemoveFinishedBuffers; // @addr $4BDC60
    procedure UpdateFades; // @addr $4BDCD8
    procedure PlaySound(const Path: WideString); // @addr $4BDDA8
    procedure PlayEffect(const Path: WideString; Group: Integer); // @addr $4BDE8C
    function PlayLoop(const Path: WideString; Group: Integer; Volume: Single): TSoundBuffer; // @addr $4BDF94
    procedure SignalStop; // @addr $4BE0A8
    constructor Create; // @addr $4BC818
  end;

function EnumerateSoundDevice(Guid: Pointer; Description, Module: PAnsiChar; Context: Pointer): LongBool; stdcall; // @addr $4BC780

implementation

// @unit-initialization $4BE104
// @unit-finalization $4BE0D4

uses GR_DirectX, Windows, SysUtils, GR_Main, GlobalsV, MMSystem, EC_Cache, EC_CacheSound, EC_Str, EC_Mem, Math;

const
  UnsignedPcmSilence = $80;
  SoundEventPollMs = 1000;

{ @routine $4BB774 TSoundBufferControl_Create }
constructor TSoundBufferControl.Create;
begin
  inherited Create;
end;
{ @end $4BB774 }

{ @routine $4BB7AC TSoundBufferControl_Destroy }
destructor TSoundBufferControl.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4BB7AC }

{ @routine $4BB7D8 TSoundBufferControl_Clear }
procedure TSoundBufferControl.Clear;
begin
  if Buffer <> nil then
  begin
    Buffer.Controller := nil;
    Buffer.Clear;
    Buffer := nil;
    Volume := 0;
  end;
end;
{ @end $4BB7D8 }

{ @routine $4BB7F8 TSoundBufferControl_Configure }
procedure TSoundBufferControl.Configure(const Path: WideString; Group: Integer);
begin
  if SoundPath <> Path then
  begin
    Clear;
    SoundGroup := Group;
    SoundPath := Path;
  end;
end;
{ @end $4BB7F8 }

{ @routine $4BB828 TSoundBufferControl_SetVolume }
procedure TSoundBufferControl.SetVolume(Value: Single);
begin
  if Volume <> Value then
  begin
    if Value = 0 then
    begin
      if Buffer <> nil then Clear;
    end
    else
    begin
      Volume := Value;
      if Buffer = nil then
      begin
        Buffer := SoundManager.PlayLoop(SoundPath, SoundGroup, Volume);
        if Buffer <> nil then Buffer.Controller := Self;
      end
      else Buffer.SetVolumeScale(Volume);
    end;
  end;
end;
{ @end $4BB828 }

{ @routine $4BB89C TSoundBuffer_Create }
constructor TSoundBuffer.Create;
begin
  inherited Create;
  Streaming := False;
  DirectBuffer := nil;
  Notify := nil;
  ChunkEvents[0] := 0;
  ChunkEvents[1] := 0;
  StopEvent := Windows.CreateEvent(nil, True, False, nil);
  ChunkEvents[0] := Windows.CreateEvent(nil, False, False, nil);
  ChunkEvents[1] := Windows.CreateEvent(nil, False, False, nil);
  ChunkEvents[2] := Windows.CreateEvent(nil, False, False, nil);
  VolumeEvent := Windows.CreateEvent(nil, False, False, nil);
  BufferBytes := 0;
  Volume := 1;
  VolumeScale := 1;
  ZeroMemory(@WaveFormat, SizeOf(WaveFormat));
  if PAnsiChar(@ChunkEvents[0]) - PAnsiChar(@StopEvent) <> 4 then
    RaiseWideMessage('TSoundBuffer.Create 1');
  if PAnsiChar(@ChunkEvents[1]) - PAnsiChar(@ChunkEvents[0]) <> 4 then
    RaiseWideMessage('TSoundBuffer.Create 2');
end;
{ @end $4BB89C }

{ @routine $4BB9F0 TSoundBuffer_Destroy }
destructor TSoundBuffer.Destroy;
begin
  Clear;
  if StopEvent <> 0 then
  begin
    CloseHandle(StopEvent);
    StopEvent := 0;
  end;
  if ChunkEvents[0] <> 0 then
  begin
    CloseHandle(ChunkEvents[0]);
    ChunkEvents[0] := 0;
  end;
  if ChunkEvents[1] <> 0 then
  begin
    CloseHandle(ChunkEvents[1]);
    ChunkEvents[1] := 0;
  end;
  if ChunkEvents[2] <> 0 then
  begin
    CloseHandle(ChunkEvents[2]);
    ChunkEvents[2] := 0;
  end;
  if VolumeEvent <> 0 then
  begin
    CloseHandle(VolumeEvent);
    VolumeEvent := 0;
  end;
  inherited Destroy;
end;
{ @end $4BB9F0 }

{ @routine $4BBA78 TSoundBuffer_Clear }
procedure TSoundBuffer.Clear;
begin
  SoundManager.Lock.Enter;
  try
    if Controller <> nil then
    begin
      Controller.Buffer := nil;
      Controller.Volume := 0;
      Controller := nil;
    end;
    if VolumeTimer <> 0 then
    begin
      timeKillEvent(VolumeTimer);
      VolumeTimer := 0;
    end;
    if DirectBuffer <> nil then DirectBuffer.Stop;
    Notify := nil;
    DirectBuffer := nil;
    BufferBytes := 0;
    Streaming := False;
    Started := False;
    ZeroMemory(@WaveFormat, SizeOf(WaveFormat));
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BBA78 }

{ @routine $4BBB24 TSoundBuffer_Init }
procedure TSoundBuffer.Init(ByteCount: Integer; Format: Pointer);
var Status: Integer;
    Desc: TDSBufferDesc;
begin
  SoundManager.Lock.Enter;
  try
    Clear;
    BufferBytes := ByteCount;
    CopyMemory(@WaveFormat, Format, SizeOf(WaveFormat));
    ZeroMemory(@Desc, SizeOf(Desc));
    Desc.Size := SizeOf(Desc);
    Desc.Flags := DSBCAPS_STATIC or DSBCAPS_LOCSOFTWARE or DSBCAPS_CTRLVOLUME;
    Desc.BufferBytes := ByteCount;
    Desc.WaveFormat := @WaveFormat;
    SoundManager.Lock.Enter;
    try
      Status := SoundManager.DirectSound.CreateSoundBuffer(Desc, DirectBuffer, nil);
    finally
      SoundManager.Lock.Leave;
    end;
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BBB24 }

{ @routine $4BBC70 TSoundBuffer_InitStream }
procedure TSoundBuffer.InitStream(ChunkBytes: Integer; Format: Pointer);
var Status: Integer;
    Positions, Position: PDSPositionNotify;
    Desc: TDSBufferDesc;
begin
  SoundManager.Lock.Enter;
  try
    Clear;
    BufferBytes := ChunkBytes;
    CopyMemory(@WaveFormat, Format, SizeOf(WaveFormat));
    ZeroMemory(@Desc, SizeOf(Desc));
    Desc.Size := SizeOf(Desc);
    Desc.Flags := DSBCAPS_LOCSOFTWARE or DSBCAPS_CTRLVOLUME or
      DSBCAPS_CTRLPOSITIONNOTIFY or DSBCAPS_GETCURRENTPOSITION2;
    Desc.BufferBytes := ChunkBytes * Length(ChunkEvents);
    Desc.WaveFormat := @WaveFormat;
    SoundManager.Lock.Enter;
    try
      Status := SoundManager.DirectSound.CreateSoundBuffer(Desc, DirectBuffer, nil);
    finally
      SoundManager.Lock.Leave;
    end;
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    Status := DirectBuffer.QueryInterface(IID_IDirectSoundNotify, Notify);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    Positions := AllocClearEC(Length(ChunkEvents) * SizeOf(TDSPositionNotify));
    Positions.Offset := 0;
    Positions.EventHandle := ChunkEvents[0];
    Position := AddPointerOffset(Positions, SizeOf(TDSPositionNotify));
    Position.Offset := ChunkBytes;
    Position.EventHandle := ChunkEvents[1];
    Position := AddPointerOffset(Position, SizeOf(TDSPositionNotify));
    Position.Offset := ChunkBytes * 2;
    Position.EventHandle := ChunkEvents[2];
    Status := Notify.SetNotificationPositions(Length(ChunkEvents), Positions);
    if Status <> DS_OK then
    begin
      FreeEC(Positions);
      raise Exception.Create(DirectXErrorText(Status));
    end;
    FreeEC(Positions);
    Status := DirectBuffer.GetFormat(@WaveFormat, SizeOf(WaveFormat), nil);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    ClearBuf;
    SetVolume(MusicVolume);
    SetVolumeScale(1);
    Streaming := True;
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BBC70 }

{ @routine $4BBF20 TSoundBuffer_ClearBuf }
procedure TSoundBuffer.ClearBuf;
var Data: Pointer;
    Bytes: Cardinal;
    Status: Integer;
begin
  SoundManager.Lock.Enter;
  try
    Data := nil;
    Bytes := 0;
    Status := DirectBuffer.Lock(0, 0, @Data, @Bytes, nil, nil, DSBLOCK_ENTIREBUFFER);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    if WaveFormat.BitsPerSample = 8 then FillMemory(Data, Bytes, UnsignedPcmSilence)
    else ZeroMemory(Data, Bytes);
    Status := DirectBuffer.Unlock(Data, Bytes, nil, 0);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BBF20 }

{ @routine $4BC04C TSoundBuffer_Write }
procedure TSoundBuffer.Write(Data: Pointer; ByteCount: Cardinal; Format: Pointer);
var Dest: Pointer;
    Bytes: Cardinal;
    Status: Integer;
begin
  SoundManager.Lock.Enter;
  try
    if (Cardinal(BufferBytes) < ByteCount) or not CompareMem(@WaveFormat, Format, SizeOf(WaveFormat)) or Streaming then
      Init(ByteCount, Format);
    Dest := nil;
    Bytes := 0;
    Status := DirectBuffer.Lock(0, ByteCount, @Dest, @Bytes, nil, nil, DSBLOCK_ENTIREBUFFER);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    CopyMemory(Dest, Data, ByteCount);
    Status := DirectBuffer.Unlock(Dest, Bytes, nil, 0);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BC04C }

{ @routine $4BC198 TSoundBuffer_WriteStream }
function TSoundBuffer.WriteStream(Reader: TSoundStreamReader; Chunk: Integer): Boolean;
var Dest: Pointer;
    LockedBytes: Cardinal;
    ReadBytes: Integer;
    Offset, Status: Integer;
    Temp: Pointer;
begin
  SoundManager.Lock.Enter;
  try
    if not Streaming then begin Result := False; Exit; end;
    if Chunk = 0 then Offset := 2 * BufferBytes
    else if Chunk = 1 then Offset := 0
    else Offset := BufferBytes;
    Temp := AllocEC(BufferBytes);
    ReadBytes := BufferBytes;
    if not Reader(Temp, ReadBytes) then ReadBytes := 0;
    Dest := nil;
    LockedBytes := 0;
    Status := DirectBuffer.Lock(Offset, BufferBytes, @Dest, @LockedBytes, nil, nil, 0);
    if Status <> DS_OK then raise Exception.Create(DirectXErrorText(Status));
    if ReadBytes > 0 then CopyMemory(Dest, Temp, ReadBytes);
    if BufferBytes > ReadBytes then
      if WaveFormat.BitsPerSample = 8 then
        FillMemory(Pointer(Cardinal(Dest) + Cardinal(ReadBytes)), BufferBytes - ReadBytes, UnsignedPcmSilence)
      else ZeroMemory(Pointer(Cardinal(Dest) + Cardinal(ReadBytes)), BufferBytes - ReadBytes);
    Status := DirectBuffer.Unlock(Dest, LockedBytes, nil, 0);
    if Status <> DS_OK then raise Exception.Create(DirectXErrorText(Status));
    FreeEC(Temp);
  finally
    SoundManager.Lock.Leave;
  end;
  Result := BufferBytes <= ReadBytes;
end;
{ @end $4BC198 }

{ @routine $4BC36C TSoundBuffer_Play }
procedure TSoundBuffer.Play(Looping: Boolean);
var Status: Integer;
begin
  SoundManager.Lock.Enter;
  try
    ResetEvent(ChunkEvents[0]);
    ResetEvent(ChunkEvents[1]);
    ResetEvent(ChunkEvents[2]);
    ResetEvent(VolumeEvent);
    if not Streaming then
    begin
      if Looping then Status := DirectBuffer.Play(0, 0, DSBPLAY_LOOPING)
      else Status := DirectBuffer.Play(0, 0, 0);
      if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    end
    else
    begin
      Status := DirectBuffer.Play(0, 0, DSBPLAY_LOOPING);
      if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    end;
    Started := True;
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BC36C }

{ @routine $4BC4A0 TSoundBuffer_WaitForChunk }
function TSoundBuffer.WaitForChunk: Integer;
var WaitResult: Cardinal;
begin
  Result := -1;
  if not Streaming then
  begin
    WaitForSingleObject(ChunkEvents[0], INFINITE);
    Result := 0;
  end
  else if VolumeTimer = 0 then
    Result := WaitForMultipleObjects(4, @StopEvent, False, INFINITE) - WAIT_OBJECT_0 - 1
  else
  begin
    while True do
    begin
      WaitResult := WaitForMultipleObjects(5, @StopEvent, False, INFINITE);
      if WaitResult = 0 then begin Result := -1; Break end;
      if WaitResult <> 4 then
      begin
        Result := WaitResult - WAIT_OBJECT_0 - 1;
        Break;
      end;
      VolumeScale := VolumeScale + VolumeStep;
      if VolumeScale < 0 then VolumeScale := 0
      else if VolumeScale > 1 then VolumeScale := 1;
      SetVolumeScale(VolumeScale);
      if VolumeScale = 0 then begin Result := -1; Break end;
    end;
  end;
end;
{ @end $4BC4A0 }

{ @routine $4BC560 TSoundBuffer_IsPlaying }
function TSoundBuffer.IsPlaying: Boolean;
var Flags: Cardinal;
    Status: Integer;
begin
  SoundManager.Lock.Enter;
  try
    if DirectBuffer = nil then
    begin
      Result := False;
      Exit;
    end;
    Status := DirectBuffer.GetStatus(Flags);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
  finally
    SoundManager.Lock.Leave;
  end;
  Result := (Flags and DSBSTATUS_PLAYING) = DSBSTATUS_PLAYING;
end;
{ @end $4BC560 }

{ @routine $4BC630 TSoundBuffer_SignalStop }
procedure TSoundBuffer.SignalStop;
begin
  SetEvent(StopEvent);
end;
{ @end $4BC630 }

{ @routine $4BC63C TSoundBuffer_SetVolume }
procedure TSoundBuffer.SetVolume(Value: Single);
var Status: Integer;
    Minimum: Single;
begin
  SoundManager.Lock.Enter;
  try
    Volume := Value;
    if DirectBuffer = nil then Exit;
    Minimum := -3000;
    Status := DirectBuffer.SetVolume(Round((0 - Minimum) * (Volume * VolumeScale) + Minimum));
    if Status <> DS_OK then raise Exception.Create(DirectXErrorText(Status));
  finally
    SoundManager.Lock.Leave;
  end;
end;
{ @end $4BC63C }

{ @routine $4BC724 TSoundBuffer_SetVolumeScale }
procedure TSoundBuffer.SetVolumeScale(Value: Single);
begin
  VolumeScale := Value;
  SetVolume(Volume);
end;
{ @end $4BC724 }

{ @routine $4BC73C TSoundBuffer_StartVolumeRamp }
procedure TSoundBuffer.StartVolumeRamp(Interval: Cardinal; Step: Single);
begin
  ResetEvent(VolumeEvent);
  VolumeStep := Step;
  if VolumeTimer <> 0 then
  begin
    timeKillEvent(VolumeTimer);
    VolumeTimer := 0;
  end;
  VolumeTimer := timeSetEvent(Interval, 0, TFNTimeCallBack(VolumeEvent), 0, TIME_PERIODIC or TIME_CALLBACK_EVENT_SET);
end;
{ @end $4BC73C }

{ @routine $4BC780 EnumerateSoundDevice }
function EnumerateSoundDevice(Guid: Pointer; Description, Module: PAnsiChar; Context: Pointer): LongBool; stdcall;
begin
  AppendLogLineThreadSafe(Format('Sound.Driver=%s (%s)', [Description, Module]));
  Result := True;
end;
{ @end $4BC780 }

{ @routine $4BC818 TSoundControl_Create }
constructor TSoundControl.Create;
var Status: Integer;
    Desc: TDSBufferDesc;
    Caps: TDSCaps;
    BufferCaps: TDSBufferCaps;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  FirstBuffer := nil;
  LastBuffer := nil;
  DirectSound := nil;
  PrimaryBuffer := nil;
  if not (SoundEnabled or MusicEnabled) then Exit;
  try
    DirectSoundEnumerateA(EnumerateSoundDevice, nil);
    Status := DirectSoundCreate(nil, DirectSound, nil);
    if Status <> DS_OK then
    begin
      SuppressExceptionLogCopy := True;
      raise Exception.Create(DirectXErrorText(Status));
    end;
    Status := DirectSound.SetCooperativeLevel(MainWindowHandle, DSSCL_PRIORITY);
    if Status <> DS_OK then
    begin
      SuppressExceptionLogCopy := True;
      raise Exception.Create(DirectXErrorText(Status));
    end;
    ZeroMemory(@Desc, SizeOf(Desc));
    Desc.Size := SizeOf(Desc);
    Desc.Flags := DSBCAPS_PRIMARYBUFFER or DSBCAPS_LOCSOFTWARE;
    Status := DirectSound.CreateSoundBuffer(Desc, PrimaryBuffer, nil);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    ZeroMemory(@WaveFormat, SizeOf(WaveFormat));
    WaveFormat.FormatTag := 1;
    WaveFormat.Channels := 2;
    WaveFormat.SamplesPerSecond := 44100;
    WaveFormat.BitsPerSample := 16;
    WaveFormat.BlockAlign := (WaveFormat.BitsPerSample shr 3) * WaveFormat.Channels;
    WaveFormat.AverageBytesPerSecond := WaveFormat.SamplesPerSecond * WaveFormat.BlockAlign;
    Status := PrimaryBuffer.SetFormat(@WaveFormat);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    Status := PrimaryBuffer.GetFormat(@WaveFormat, SizeOf(WaveFormat), nil);
    if Status <> DS_OK then
    begin
      raise Exception.Create(DirectXErrorText(Status));
    end;
    AppendLogLineThreadSafe('Sound.Channels=' + IntToStr(WaveFormat.Channels));
    AppendLogLineThreadSafe('Sound.SamplesPerSec=' + IntToStr(Int64(WaveFormat.SamplesPerSecond)));
    AppendLogLineThreadSafe('Sound.BitsPerSample=' + IntToStr(WaveFormat.BitsPerSample));
    ZeroMemory(@BufferCaps, SizeOf(BufferCaps));
    BufferCaps.Size := SizeOf(BufferCaps);
    if PrimaryBuffer.GetCaps(@BufferCaps) = DS_OK then
      with BufferCaps do begin
        AppendLogTextThreadSafe('Sound.Flags=');
        if (Flags and DSBCAPS_CTRL3D) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_CTRL3D ');
        if (Flags and DSBCAPS_CTRLFREQUENCY) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_CTRLFREQUENCY ');
        if (Flags and DSBCAPS_CTRLPAN) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_CTRLPAN ');
        if (Flags and DSBCAPS_CTRLVOLUME) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_CTRLVOLUME ');
        if (Flags and DSBCAPS_CTRLPOSITIONNOTIFY) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_CTRLPOSITIONNOTIFY ');
        if (Flags and DSBCAPS_GETCURRENTPOSITION2) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_GETCURRENTPOSITION2 ');
        if (Flags and DSBCAPS_GLOBALFOCUS) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_GLOBALFOCUS ');
        if (Flags and DSBCAPS_LOCDEFER) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_LOCDEFER ');
        if (Flags and DSBCAPS_LOCHARDWARE) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_LOCHARDWARE ');
        if (Flags and DSBCAPS_LOCSOFTWARE) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_LOCSOFTWARE ');
        if (Flags and DSBCAPS_MUTE3DATMAXDISTANCE) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_MUTE3DATMAXDISTANCE ');
        if (Flags and DSBCAPS_PRIMARYBUFFER) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_PRIMARYBUFFER ');
        if (Flags and DSBCAPS_STATIC) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_STATIC ');
        if (Flags and DSBCAPS_STICKYFOCUS) <> 0 then AppendLogTextThreadSafe(' DSBCAPS_STICKYFOCUS ');
        AppendLogLineThreadSafe('');
        AppendLogLineThreadSafe('Sound.dwBufferBytes=' + IntToStr(Int64(BufferBytes)));
        AppendLogLineThreadSafe('Sound.dwUnlockTransferRate=' + IntToStr(Int64(UnlockTransferRate)));
        AppendLogLineThreadSafe('Sound.dwPlayCpuOverhead=' + IntToStr(Int64(PlayCpuOverhead)));
      end;
    ZeroMemory(@Caps, SizeOf(Caps));
    Caps.Size := SizeOf(Caps);
    if DirectSound.GetCaps(@Caps) = DS_OK then
      with Caps do begin
        AppendLogTextThreadSafe('Sound.Flags=');
        if (Flags and DSCAPS_CERTIFIED) <> 0 then AppendLogTextThreadSafe(' DSCAPS_CERTIFIED');
        if (Flags and DSCAPS_CONTINUOUSRATE) <> 0 then AppendLogTextThreadSafe(' DSCAPS_CONTINUOUSRATE');
        if (Flags and DSCAPS_EMULDRIVER) <> 0 then AppendLogTextThreadSafe(' DSCAPS_EMULDRIVER');
        if (Flags and DSCAPS_PRIMARY16BIT) <> 0 then AppendLogTextThreadSafe(' DSCAPS_PRIMARY16BIT');
        if (Flags and DSCAPS_PRIMARY8BIT) <> 0 then AppendLogTextThreadSafe(' DSCAPS_PRIMARY8BIT');
        if (Flags and DSCAPS_PRIMARYMONO) <> 0 then AppendLogTextThreadSafe(' DSCAPS_PRIMARYMONO');
        if (Flags and DSCAPS_PRIMARYSTEREO) <> 0 then AppendLogTextThreadSafe(' DSCAPS_PRIMARYSTEREO');
        if (Flags and DSCAPS_SECONDARY16BIT) <> 0 then AppendLogTextThreadSafe(' DSCAPS_SECONDARY16BIT');
        if (Flags and DSCAPS_SECONDARY8BIT) <> 0 then AppendLogTextThreadSafe(' DSCAPS_SECONDARY8BIT');
        if (Flags and DSCAPS_SECONDARYMONO) <> 0 then AppendLogTextThreadSafe(' DSCAPS_SECONDARYMONO');
        if (Flags and DSCAPS_SECONDARYSTEREO) <> 0 then AppendLogTextThreadSafe(' DSCAPS_SECONDARYSTEREO');
        AppendLogLineThreadSafe('');
        AppendLogLineThreadSafe('Sound.dwMinSecondarySampleRate=' + IntToStr(Int64(MinSecondarySampleRate)));
        AppendLogLineThreadSafe('Sound.dwMaxSecondarySampleRate=' + IntToStr(Int64(MaxSecondarySampleRate)));
        AppendLogLineThreadSafe('Sound.dwPrimaryBuffers=' + IntToStr(Int64(PrimaryBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHwMixingAllBuffers=' + IntToStr(Int64(MaxHwMixingAllBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHwMixingStaticBuffers=' + IntToStr(Int64(MaxHwMixingStaticBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHwMixingStreamingBuffers=' + IntToStr(Int64(MaxHwMixingStreamingBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHwMixingAllBuffers=' + IntToStr(Int64(FreeHwMixingAllBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHwMixingStaticBuffers=' + IntToStr(Int64(FreeHwMixingStaticBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHwMixingStreamingBuffers=' + IntToStr(Int64(FreeHwMixingStreamingBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHw3DAllBuffers=' + IntToStr(Int64(MaxHw3DAllBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHw3DStaticBuffers=' + IntToStr(Int64(MaxHw3DStaticBuffers)));
        AppendLogLineThreadSafe('Sound.dwMaxHw3DStreamingBuffers=' + IntToStr(Int64(MaxHw3DStreamingBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHw3DAllBuffers=' + IntToStr(Int64(FreeHw3DAllBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHw3DStaticBuffers=' + IntToStr(Int64(FreeHw3DStaticBuffers)));
        AppendLogLineThreadSafe('Sound.dwFreeHw3DStreamingBuffers=' + IntToStr(Int64(FreeHw3DStreamingBuffers)));
        AppendLogLineThreadSafe('Sound.dwTotalHwMemBytes=' + IntToStr(Int64(TotalHwMemBytes)));
        AppendLogLineThreadSafe('Sound.dwFreeHwMemBytes=' + IntToStr(Int64(FreeHwMemBytes)));
        AppendLogLineThreadSafe('Sound.dwMaxContigFreeHwMemBytes=' + IntToStr(Int64(MaxContigFreeHwMemBytes)));
        AppendLogLineThreadSafe('Sound.dwUnlockTransferRateHwBuffers=' + IntToStr(Int64(UnlockTransferRateHwBuffers)));
        AppendLogLineThreadSafe('Sound.dwPlayCpuOverheadSwBuffers=' + IntToStr(Int64(PlayCpuOverheadSwBuffers)));
      end;
    AppendLogLineThreadSafe('Create sound .... ok');
  except
    PrimaryBuffer := nil;
    DirectSound := nil;
    SoundEnabled := False;
    MusicEnabled := False;
    AppendLogLineThreadSafe('Create sound .... fail');
  end;
end;
{ @end $4BC818 }

{ @routine $4BD9F8 TSoundControl_Destroy }
destructor TSoundControl.Destroy;
begin
  Clear;
  PrimaryBuffer := nil;
  DirectSound := nil;
  Lock.Free;
  inherited Destroy;
end;
{ @end $4BD9F8 }

{ @routine $4BDA3C TSoundControl_Clear }
procedure TSoundControl.Clear;
begin
  while FirstBuffer <> nil do RemoveBuffer(FirstBuffer);
end;
{ @end $4BDA3C }

{ @routine $4BDA54 TSoundControl_StopUncontrolledSounds }
procedure TSoundControl.StopUncontrolledSounds;
var NextBuffer, Buffer: TSoundBuffer;
begin
  Lock.Enter;
    NextBuffer := FirstBuffer;
    while NextBuffer <> nil do
    begin
      Buffer := NextBuffer;
      NextBuffer := NextBuffer.Next;
      if (Buffer.Controller = nil) and not Buffer.Streaming and Buffer.IsPlaying then RemoveBuffer(Buffer);
    end;
    Lock.Leave;
end;
{ @end $4BDA54 }

{ @routine $4BDAA0 TSoundControl_AddBuffer }
function TSoundControl.AddBuffer: TSoundBuffer;
var Buffer: TSoundBuffer;
begin
  Lock.Enter;
  try
    Buffer := TSoundBuffer.Create;
    if LastBuffer <> nil then LastBuffer.Next := Buffer;
    Buffer.Prev := LastBuffer;
    Buffer.Next := nil;
    LastBuffer := Buffer;
    if FirstBuffer = nil then FirstBuffer := Buffer;
  finally
    Lock.Leave;
  end;
  Result := Buffer;
end;
{ @end $4BDAA0 }

{ @routine $4BDB38 TSoundControl_RemoveBuffer }
procedure TSoundControl.RemoveBuffer(Buffer: TSoundBuffer);
begin
  Lock.Enter;
  try
    if Buffer.Prev <> nil then Buffer.Prev.Next := Buffer.Next;
    if Buffer.Next <> nil then Buffer.Next.Prev := Buffer.Prev;
    if LastBuffer = Buffer then LastBuffer := Buffer.Prev;
    if FirstBuffer = Buffer then FirstBuffer := Buffer.Next;
    Buffer.Free;
  finally
    Lock.Leave;
  end;
end;
{ @end $4BDB38 }

{ @routine $4BDBC4 TSoundControl_SuppressGroup }
function TSoundControl.SuppressGroup(Group: Integer; Volume: Single): Boolean;
var Buffer: TSoundBuffer;
begin
  Result := False;
  Lock.Enter;
  try
    Buffer := FirstBuffer;
    while Buffer <> nil do
    begin
      if Buffer.SoundGroup = Group then
      begin
        if Buffer.VolumeScale > Volume then
        begin
          Result := True;
          Exit;
        end;
        Buffer.FadingOut := True;
        if Buffer.Controller <> nil then
        begin
          Buffer.Controller.Buffer := nil;
          Buffer.Controller.Volume := 0;
          Buffer.Controller := nil;
        end;
      end;
      Buffer := Buffer.Next;
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $4BDBC4 }

{ @routine $4BDC60 TSoundControl_RemoveFinishedBuffers }
procedure TSoundControl.RemoveFinishedBuffers;
var NextBuffer, Buffer: TSoundBuffer;
begin
  Lock.Enter;
  try
    NextBuffer := FirstBuffer;
    while NextBuffer <> nil do
    begin
      Buffer := NextBuffer;
      NextBuffer := NextBuffer.Next;
      if Buffer.AutoRelease and not Buffer.IsPlaying then RemoveBuffer(Buffer);
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $4BDC60 }

{ @routine $4BDCD8 TSoundControl_UpdateFades }
procedure TSoundControl.UpdateFades;
var NextBuffer, Buffer: TSoundBuffer;
    NewVolume: Single;
    Tick: Cardinal;
begin
  Tick := timeGetTime;
  if Tick - LastFadeTick < 10 then Exit;
  LastFadeTick := Tick;
  Lock.Enter;
  try
    NextBuffer := FirstBuffer;
    while NextBuffer <> nil do
    begin
      Buffer := NextBuffer;
      NextBuffer := NextBuffer.Next;
      if Buffer.FadingOut then
      begin
        NewVolume := Max(0, Buffer.VolumeScale - 0.05);
        if NewVolume > 0.05 then Buffer.SetVolumeScale(NewVolume)
        else RemoveBuffer(Buffer);
      end;
    end;
  finally
    Lock.Leave;
  end;
end;
{ @end $4BDCD8 }

{ @routine $4BDDA8 TSoundControl_PlaySound }
procedure TSoundControl.PlaySound(const Path: WideString);
var Control: TCSoundControlEC;
    Sound: TCSoundEC;
    Buffer: TSoundBuffer;
begin
  if Path = '' then Exit;
  if not SoundEnabled then Exit;
  Control := nil;
  RemoveFinishedBuffers;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(1);
    Buffer.Play(False);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $4BDDA8 }

{ @routine $4BDE8C TSoundControl_PlayEffect }
procedure TSoundControl.PlayEffect(const Path: WideString; Group: Integer);
var Control: TCSoundControlEC;
    Sound: TCSoundEC;
    Buffer: TSoundBuffer;
begin
  if Path = '' then Exit;
  if not SoundEnabled then Exit;
  Control := nil;
  RemoveFinishedBuffers;
  if (Group <> 0) and SuppressGroup(Group, 1) then Exit;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.SoundGroup := Group;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(1);
    Buffer.Play(False);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $4BDE8C }

{ @routine $4BDF94 TSoundControl_PlayLoop }
function TSoundControl.PlayLoop(const Path: WideString; Group: Integer; Volume: Single): TSoundBuffer;
var Control: TCSoundControlEC;
    Sound: TCSoundEC;
    Buffer: TSoundBuffer;
begin
  Result := nil;
  if Path = '' then Exit;
  if not SoundEnabled then Exit;
  Control := nil;
  RemoveFinishedBuffers;
  if (Group <> 0) and SuppressGroup(Group, Volume) then Exit;
  try
    Control := TCSoundControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Sound := AcquireCachedSound(Control);
    Buffer := AddBuffer;
    Buffer.SoundGroup := Group;
    Buffer.AutoRelease := True;
    Buffer.Write(Sound.SampleData, Sound.SampleDataSize, @Sound.Format);
    Buffer.SetVolume(SoundVolume);
    Buffer.SetVolumeScale(Volume);
    Buffer.Play(True);
    Result := Buffer;
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $4BDF94 }

{ @routine $4BE0A8 TSoundControl_SignalStop }
procedure TSoundControl.SignalStop;
var Buffer: TSoundBuffer;
begin
  Lock.Enter;
  Buffer := FirstBuffer;
  while Buffer <> nil do
  begin
    Buffer.SignalStop;
    Buffer := Buffer.Next;
  end;
  Lock.Leave;
end;
{ @end $4BE0A8 }

end.

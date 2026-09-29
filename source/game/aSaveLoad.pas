unit aSaveLoad;
// Unit bracket (inferred): CODE 0x004E3E7C..0x004E4953; inclusive evidence, not full bounds.
// Saves are written synchronously. The loader also accepts the older, pre-cipher save envelope.
interface
function SaveGameToFile(FileName: AnsiString; Mode: WideString): Boolean; // @addr $4E3E7C
function LoadGameFromFile(FileName: AnsiString): Boolean; // @addr $4E4394
implementation

// @unit-initialization $4E494C
// @unit-finalization $4E491C

uses SysUtils, Windows, Types, EC_Buf, EC_File, EC_Str, EC_Struct, GR_Main, Globals, GlobalsV,
  aGalaxy, aPlayer, aShip, aConst, aMyFunction, fShip2, fStarMap, fFilmFile;

{ @routine $4E3E7C SaveGameToFile }
function SaveGameToFile(FileName: AnsiString; Mode: WideString): Boolean;
var
  F: TFileEC;
  Buffer: TBufEC;
  Size, Count, Seed, I: Integer;
  Message: TMessagePlayer;
  Entry: TPlayerHoldUnit;
begin
  Result := False;
  if (Galaxy = nil) or (Player = nil) then Exit;
  F := nil;
  Buffer := nil;
  PendingLoadFileName := FileName;
  CreateDir('Save');
  try
    F := TFileEC.Create;
    F.SetFileName(FileName);
    F.CreateNew;
    Buffer := TBufEC.Create;
    Buffer.AddWideStringZ('RSG');
    Buffer.AddWideStringZ('v10');
    Buffer.AddWideStringZ(Mode);
    Buffer.AddWideStringZ(IntToStr(Galaxy.CurrentTurn));
    Buffer.AddWideStringZ(IntToStr(Player.Money));
    Buffer.AddWideStringZ(Player.Name);
    Buffer.AddWideStringZ(OwnerInfo[Player.OwnerId].InternalName);
    Buffer.AddWideStringZ('EZ');
    Buffer.SaveToFile(F);
    Buffer.Clear;
    if SavePreviewGraph <> nil then SavePreviewGraph.SaveToBuffer(Buffer);
    Size := Buffer.DataSize;
    F.WriteBuffer(@Size, SizeOf(Size));
    if Size > 0 then F.WriteBuffer(Buffer.Data, Size);
    Buffer.Clear;
    Buffer.AddIntegerValue(ReadByteValue(SaveManagerReturnScreenId));
    Buffer.AddIntegerValue(StarMapScreen.GetMapCenter.X);
    Buffer.AddIntegerValue(StarMapScreen.GetMapCenter.Y);
    Buffer.AddBoolean(StarMapWeaponPanelOpen);
    Buffer.AddAnsiChar(#0);
    Buffer.AddBoolean(FilmCameraFollow);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(LegacySaveByte1)));
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(LegacySaveByte2)));
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(LegacySaveByte3)));
    Buffer.AddBoolean(False);
    Buffer.AddBoolean(PlayerStarDayPrepared);
    if PlayerStarDayPrepared then begin end;
    Buffer.AddDWord(ShownPlayerTips);
    Buffer.AddIntegerValue(0);
    Count := CountPersistentPlayerMessages;
    Buffer.AddIntegerValue(Count);
    Message := FirstPersistentPlayerMessage;
    while Message <> nil do
    begin
      Message.SaveToBuffer(Buffer);
      Message := Message.Next;
    end;
    RefreshPlayerHoldView;
    Count := PlayerHoldEntries.Count;
    Buffer.AddWideChar(WideChar(Count));
    for I := 0 to Count - 1 do
    begin
      Entry := PlayerHoldEntries[I];
      Buffer.AddAnsiChar(AnsiChar(Entry.Kind));
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Entry.GoodsIndex)));
      Buffer.AddDWord(Entry.ItemId);
    end;
    Galaxy.SaveToBuffer(Buffer);
    Size := Buffer.ComputeCrc32;
    F.WriteBuffer(@Size, SizeOf(Size));
    Seed := RandomIntRange(0, 2000000000);
    Buffer.ApplyDatXorCipher(Seed);
    F.WriteBuffer(@Seed, SizeOf(Seed));
    Size := Buffer.DataSize;
    F.WriteBuffer(@Size, SizeOf(Size));
    if Size > 0 then F.WriteBuffer(Buffer.Data, Size);
    Count := FilmHistory.GetCount;
    F.WriteBuffer(@Count, SizeOf(Count));
    for I := 0 to Count - 1 do
    begin
      FilmHistory.SaveEntryToBuffer(FilmHistory.GetEntry(I), Buffer);
      Size := Buffer.DataSize;
      F.WriteBuffer(@Size, SizeOf(Size));
      if Size > 0 then F.WriteBuffer(Buffer.Data, Size);
    end;
    Result := True;
  except
    // Native failure is swallowed and may leave a partially written file.
  end;
  if Buffer <> nil then Buffer.Free;
  if F <> nil then F.Free;
  if Result = True then FreeSavePreviewBuffer;
end;
{ @end $4E3E7C }

{ @routine $4E4394 LoadGameFromFile }
function LoadGameFromFile(FileName: AnsiString): Boolean;
var
  F: TFileEC;
  Buffer: TBufEC;
  Center: TPoint;
  Size, Count, Seed: Integer;
  Crc: Cardinal;
  StartedAt: Int64;
  I: Integer;
  Message: TMessagePlayer;
  Entry: TPlayerHoldUnit;
begin
  Result := False;
  F := nil;
  Buffer := nil;
  try
    if Galaxy <> nil then
    begin
      Galaxy.Free;
      Galaxy := nil;
    end;
    StartedAt := ReadPerformanceCounter; // Native samples the clock but never uses the result.
    F := TFileEC.Create;
    F.SetFileName(FileName);
    if not F.TryAcquireReadHandle then raise EAbort.Create('Err');
    if F.ReadWideString <> 'RSG' then raise EAbort.Create('Err');
    LoadedSaveVersion := ExtractDigitsToIntW(F.ReadWideString);
    F.ReadWideString;
    StrToInt(F.ReadWideString);
    StrToInt(F.ReadWideString);
    F.ReadWideString;
    F.ReadWideString;
    if F.ReadWideString <> 'EZ' then raise EAbort.Create('Err');
    Buffer := TBufEC.Create;
    F.ReadBuffer(@Size, SizeOf(Size));
    if Size > 0 then F.SetPointer(Size, FILE_CURRENT);
    if LoadedSaveVersion >= 4 then
    begin
      F.ReadBuffer(@Crc, SizeOf(Crc));
      F.ReadBuffer(@Seed, SizeOf(Seed));
    end;
    F.ReadBuffer(@Size, SizeOf(Size));
    if Size > 0 then
    begin
      Buffer.SetSize(Size);
      F.ReadBuffer(Buffer.Data, Size);
    end;
    if LoadedSaveVersion >= 4 then
    begin
      Buffer.ApplyDatXorCipher(Seed);
      if Buffer.ComputeCrc32 <> Crc then raise EAbort.Create('Err');
    end;
    Buffer.ExpandZlibPayloadInPlace;
    ActiveLoadBuffer := Buffer;
    WriteByteValue(Byte(Buffer.GetInt32), RequestedScreenId);
    Galaxy := TGalaxy.Create;
    Center.X := Buffer.GetInt32;
    Center.Y := Buffer.GetInt32;
    SpaceViewPosition := PointToPointF(Center);
    StarMapScreen.SetMapCenterManually(Center);
    StarMapWeaponPanelOpen := Buffer.GetBoolean;
    Buffer.GetByte;
    FilmCameraFollow := Buffer.GetBoolean;
    WriteByteValue(Buffer.GetByte, LegacySaveByte1);
    WriteByteValue(Buffer.GetByte, LegacySaveByte2);
    WriteByteValue(Buffer.GetByte, LegacySaveByte3);
    Buffer.GetBoolean;
    PlayerStarDayPrepared := Buffer.GetBoolean;
    if PlayerStarDayPrepared then begin end;
    ShownPlayerTips := Buffer.GetUInt32;
    Buffer.GetInt32;
    Count := Buffer.GetInt32;
    for I := 0 to Count - 1 do
    begin
      Message := CreatePersistentPlayerMessage;
      Message.LoadFromBuffer(Buffer);
    end;
    InitializePlayerHoldView;
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do
    begin
      Entry := TPlayerHoldUnit.Create;
      PlayerHoldEntries.Add(Entry);
      Entry.Kind := Buffer.GetByte;
      WriteByteValue(Buffer.GetByte, Entry.GoodsIndex);
      Entry.ItemId := Buffer.GetUInt32;
    end;
    Galaxy.LoadFromBuffer(Buffer);
    FilmHistory.Clear;
    F.ReadBuffer(@Count, SizeOf(Count));
    LoadingFilmCount := Count;
    LoadedFilmCount := 0;
    for I := 0 to Count - 1 do
    begin
      F.ReadBuffer(@Size, SizeOf(Size));
      if Size > 0 then
      begin
        Buffer.SetSize(Size);
        F.ReadBuffer(Buffer.Data, Size);
        Buffer.SetPosition(0);
        FilmHistory.LoadEntryFromBuffer(Buffer);
      end;
      Inc(LoadedFilmCount);
    end;
    LoadingFilmCount := -1;
    PreviousFilmActivity := 0;
    Result := True;
  except
    if Galaxy <> nil then
    begin
      Galaxy.Free;
      Galaxy := nil;
    end;
  end;
  LoadingFilmCount := -1;
  ActiveLoadBuffer := nil;
  if Buffer <> nil then Buffer.Free;
  if F <> nil then F.Free;
end;
{ @end $4E4394 }
end.

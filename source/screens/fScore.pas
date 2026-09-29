unit fScore;
// Unit bracket (inferred): CODE 0x004D9748..0x004DE477; inclusive evidence, not full bounds.
// Score entries, component scoring and the version 0/1 format.
interface
uses Classes, EC_Buf, GI_MessageLoop, Types;
type
  TScoreQuestResult = packed record // @size $04
    Successful: Boolean; // @offset $00
    QuestType: Byte; // @offset $01
    QuestNumber: Word; // @offset $02
  end;
  TfScoreUnit = class(TObject) // @size $44
  public
    Outcome: Integer; // @offset $04
    Disqualified: Boolean; // @offset $08
    Difficulty: TDifficulty; // @offset $09
    PlayerName: WideString; // @offset $0C
    PilotRace: TRaceId; // @offset $10
    FinishedTurn: Integer; // @offset $14
    Rank: TCoalitionRank; // @offset $18
    OtherShipKillCount: Word; // @offset $1A
    PirateKillCount: Word; // @offset $1C
    KlissanKillCount: Word; // @offset $1E
    LiberatedSystemCount: Word; // @offset $20
    AwardCount: Integer; // @offset $24
    ProtoplasmCount: Integer; // @offset $28 Captured from TShip.NodeReserve ($EC), not TotalExperience ($F0).
    SkillLevels: array[TSkill] of TSkillLevel; // @offset $2C
    GenerationSeed: Integer; // @offset $34
    ScoreTags: TBufEC; // @offset $38 Owned.
    QuestResults: array of TScoreQuestResult; // @offset $3C
    TotalScore: Integer; // @offset $40
    constructor Create; // @addr $4D985C
    destructor Destroy; override; // @addr $4D98A0
    procedure CapturePlayer(ResultKind: Integer); // @addr $4D98D0
    function ComputeTurnScore: Integer; // @addr $4D9A40
    function ComputeRankScore: Integer; // @addr $4D9AC4
    function ComputeOtherKillsScore: Integer; // @addr $4D9B08
    function ComputePirateKillsScore: Integer; // @addr $4D9B34
    function ComputeKlissanKillsScore: Integer; // @addr $4D9B60
    function ComputeLiberationScore: Integer; // @addr $4D9B90
    function ComputeAwardScore: Integer; // @addr $4D9BBC
    function ComputeProtoplasmScore: Integer; // @addr $4D9BE8
    function ComputeSkillScore: Integer; // @addr $4D9C14
    function ComputeOutcomeScore: Integer; // @addr $4D9C48
    function ComputeSubtotal: Integer; // @addr $4D9CB4
    procedure RecalculateTotalScore; // @addr $4D9D10
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $4D9D2C
    procedure LoadFromBuffer(Buffer: TBufEC; FileVersion: Integer); // @addr $4D9E3C
    procedure ExportToFile(FileName: WideString); // @addr $4D9FD8
  end;
  TfScore = class(TMessageLoopGI) // @size $BC
  public
    Entries: TList; // @offset $B0 Owned TfScoreUnit objects; eleven slots.
    SelectedIndex: Integer; // @offset $B4
    ReturnToEndScreen: Boolean; // @offset $B8
    constructor Create; // @addr $4DB770
    destructor Destroy; override; // @addr $4DB7B8
    procedure CreateDefaultTable; // @addr $4DAAD4
    procedure RecordPlayerResult(ResultKind: Integer); // @addr $4DB1F4
    procedure ClearEntries; // @addr $4DB2F4
    procedure ReloadTable; // @addr $4DB330
    procedure SaveTableToDisk; // @addr $4DB5C4
    procedure InitializeLayout; override; // @addr $4DB7F0
    procedure OnOpen; override; // @addr $4DB8C8
    procedure OnClose; override; // @addr $4DC3CC
    procedure ClearTableClicked(Sender: TObjectGI); // @addr $4DC444
    procedure CloseClicked(Sender: TObjectGI); // @addr $4DC50C
    procedure KeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $4DC534
    procedure RefreshDetails; // @addr $4DC620
    procedure EntryMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4DE02C
    procedure ExportEntryClicked(Sender: TObjectGI); // @addr $4DE078
    procedure HideExportPanel(Sender: TObjectGI); // @addr $4DE394
    procedure ShowControlHelp(Sender: TObjectGI; Visible: Boolean); // @addr $4DE3B8
    procedure SelectMusic; override; // @addr $4DE41C
  end;
implementation

// @unit-initialization $4DE470
// @unit-finalization $4DE440

uses SysUtils, Windows, Math, EC_File, EC_Str, GR_Main, GlobalsV, Globals,
  ExceptionInfo, GI_GAI, EC_Struct, aGalaxy, aConst, aMyFunction, aRanger, aShip, aPlayer, GR_Music,
  GI_GraphButton, GI_Image, GI_Label, GI_Panel, GI_MessageBox, GI_Main;

{ @routine $4D985C TfScoreUnit_Create }
constructor TfScoreUnit.Create;
begin
  inherited Create;
  ScoreTags := TBufEC.Create;
end;
{ @end $4D985C }

{ @routine $4D98A0 TfScoreUnit_Destroy }
destructor TfScoreUnit.Destroy;
begin
  ScoreTags.Free;
  inherited Destroy;
end;
{ @end $4D98A0 }

{ @routine $4D98D0 TfScoreUnit_CapturePlayer }
procedure TfScoreUnit.CapturePlayer(ResultKind: Integer);
type
  TScoreKillCounters = array[0..3] of Word;
  PShipCounterView = ^TShipCounterView;
  TShipCounterView = packed record
    Prefix: array[0..$1B3] of Byte;
    Counters: TScoreKillCounters;
  end;
  PScoreCounterView = ^TScoreCounterView;
  TScoreCounterView = packed record
    Prefix: array[0..$19] of Byte;
    Counters: TScoreKillCounters;
  end;
var
  Skill: TSkill;
  I: Integer;
  Quest: PPlayerOldQuest;
begin
  PlayerName := Player.Name;
  PilotRace := OwnerToRace(Player.OwnerId);
  Difficulty := Galaxy.Difficulty;
  Disqualified := Galaxy.MoneyIntegrityFailed;
  FinishedTurn := Galaxy.CurrentTurn;
  Rank := Player.Rank;
  PScoreCounterView(Self).Counters := PShipCounterView(Player).Counters;
  OtherShipKillCount := OtherShipKillCount - PirateKillCount - KlissanKillCount;
  if Player.AwardIds = nil then AwardCount := 0 else AwardCount := Player.AwardIds.Count;
  ProtoplasmCount := Player.NodeReserve;
  for Skill := skAccuracy to skLeadership do SkillLevels[Skill] := Player.BaseSkills[Skill];
  Outcome := ResultKind;
  ScoreTags.Clear;
  if Galaxy.IntegrityBuffer.DataSize > 0 then
    ScoreTags.AddBytes(Galaxy.IntegrityBuffer.Data, Galaxy.IntegrityBuffer.DataSize);
  GenerationSeed := Galaxy.GenerationSeed;
  SetLength(QuestResults, PlayerOldQuests.Count);
  for I := 0 to PlayerOldQuests.Count - 1 do
  begin
    Quest := PlayerOldQuests[I];
    QuestResults[I].Successful := Quest.Successful;
    QuestResults[I].QuestType := Ord(Quest.QuestType);
    QuestResults[I].QuestNumber := Quest.QuestNumber;
  end;
  RecalculateTotalScore;
end;
{ @end $4D98D0 }

{ @routine $4D9A40 TfScoreUnit_ComputeTurnScore }
function TfScoreUnit.ComputeTurnScore: Integer;
begin
  Result := RoundAndTruncateToTens(RemapClampedAlternate(FinishedTurn, 2500, 10000, 30000, 1000));
  if FinishedTurn > 10000 then
    Result := RoundAndTruncateToTens(1000 - (FinishedTurn - 10000) / 365 * 300);
end;
{ @end $4D9A40 }

{ @routine $4D9AC4 TfScoreUnit_ComputeRankScore }
function TfScoreUnit.ComputeRankScore: Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Ord(Rank), 0, 6, 0, 2500));
end;
{ @end $4D9AC4 }

{ @routine $4D9B08 TfScoreUnit_ComputeOtherKillsScore }
function TfScoreUnit.ComputeOtherKillsScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(2 * OtherShipKillCount));
end;
{ @end $4D9B08 }

{ @routine $4D9B34 TfScoreUnit_ComputePirateKillsScore }
function TfScoreUnit.ComputePirateKillsScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(5 * PirateKillCount));
end;
{ @end $4D9B34 }

{ @routine $4D9B60 TfScoreUnit_ComputeKlissanKillsScore }
function TfScoreUnit.ComputeKlissanKillsScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(10 * KlissanKillCount));
end;
{ @end $4D9B60 }

{ @routine $4D9B90 TfScoreUnit_ComputeLiberationScore }
function TfScoreUnit.ComputeLiberationScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(100 * LiberatedSystemCount));
end;
{ @end $4D9B90 }

{ @routine $4D9BBC TfScoreUnit_ComputeAwardScore }
function TfScoreUnit.ComputeAwardScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(150 * AwardCount));
end;
{ @end $4D9BBC }

{ @routine $4D9BE8 TfScoreUnit_ComputeProtoplasmScore }
function TfScoreUnit.ComputeProtoplasmScore: Integer;
begin
  Result := Min(15000, RoundAndTruncateToTens(ProtoplasmCount * 0.5));
end;
{ @end $4D9BE8 }

{ @routine $4D9C14 TfScoreUnit_ComputeSkillScore }
function TfScoreUnit.ComputeSkillScore: Integer;
var I: TSkill;
begin
  Result := 0;
  for I := skAccuracy to skLeadership do Result := RoundAndTruncateToTens(100 * SkillLevels[I] + Result);
end;
{ @end $4D9C14 }

{ @routine $4D9C48 TfScoreUnit_ComputeOutcomeScore }
function TfScoreUnit.ComputeOutcomeScore: Integer;
begin
  case Outcome of
    0: Result := RoundAndTruncateToTens(1500);
    1: Result := RoundAndTruncateToTens(2000);
    10: Result := RoundAndTruncateToTens(1500);
    11: Result := RoundAndTruncateToTens(2000);
  else
    if ComputeSubtotal >= 0 then Result := -ComputeSubtotal else Result := 0;
  end;
end;
{ @end $4D9C48 }

{ @routine $4D9CB4 TfScoreUnit_ComputeSubtotal }
function TfScoreUnit.ComputeSubtotal: Integer;
begin
  Result := ComputeTurnScore + ComputeRankScore + ComputeOtherKillsScore + ComputePirateKillsScore +
    ComputeKlissanKillsScore + ComputeLiberationScore + ComputeAwardScore + ComputeProtoplasmScore + ComputeSkillScore;
end;
{ @end $4D9CB4 }

{ @routine $4D9D10 TfScoreUnit_RecalculateTotalScore }
procedure TfScoreUnit.RecalculateTotalScore;
begin
  TotalScore := ComputeSubtotal + ComputeOutcomeScore;
end;
{ @end $4D9D10 }

{ @routine $4D9D2C TfScoreUnit_SaveToBuffer }
procedure TfScoreUnit.SaveToBuffer(Buffer: TBufEC);
var Skill: TSkill; I: Integer;
begin
  Buffer.AddIntegerValue(Outcome);
  Buffer.AddAnsiChar(AnsiChar(Difficulty));
  Buffer.AddWideStringZ(PlayerName);
  Buffer.AddAnsiChar(AnsiChar(PilotRace));
  Buffer.AddIntegerValue(FinishedTurn);
  Buffer.AddAnsiChar(AnsiChar(Rank));
  Buffer.AddWideChar(WideChar(OtherShipKillCount));
  Buffer.AddWideChar(WideChar(PirateKillCount));
  Buffer.AddWideChar(WideChar(KlissanKillCount));
  Buffer.AddWideChar(WideChar(LiberatedSystemCount));
  Buffer.AddIntegerValue(AwardCount);
  Buffer.AddIntegerValue(ProtoplasmCount);
  for Skill := skAccuracy to skLeadership do Buffer.AddAnsiChar(AnsiChar(SkillLevels[Skill]));
  Buffer.AddBoolean(Disqualified);
  Buffer.AddBuffer(ScoreTags);
  Buffer.AddIntegerValue(GenerationSeed);
  Buffer.AddWideChar(WideChar(High(QuestResults) + 1));
  for I := 0 to High(QuestResults) do
  begin
    Buffer.AddBoolean(QuestResults[I].Successful);
    Buffer.AddAnsiChar(AnsiChar(QuestResults[I].QuestType));
    // The original format truncates the Word quest number to one byte.
    Buffer.AddAnsiChar(AnsiChar(QuestResults[I].QuestNumber));
  end;
end;
{ @end $4D9D2C }

{ @routine $4D9E3C TfScoreUnit_LoadFromBuffer }
procedure TfScoreUnit.LoadFromBuffer(Buffer: TBufEC; FileVersion: Integer);
var Skill: TSkill; I: Integer;
begin
  Outcome := Buffer.GetInt32;
  Difficulty := TDifficulty(Buffer.GetByte);
  PlayerName := Buffer.ReadWideString;
  PilotRace := TRaceId(Buffer.GetByte);
  FinishedTurn := Buffer.GetInt32;
  Rank := TCoalitionRank(Buffer.GetByte);
  OtherShipKillCount := Buffer.GetWord;
  PirateKillCount := Buffer.GetWord;
  KlissanKillCount := Buffer.GetWord;
  LiberatedSystemCount := Buffer.GetWord;
  AwardCount := Buffer.GetInt32;
  ProtoplasmCount := Buffer.GetInt32;
  for Skill := skAccuracy to skLeadership do SkillLevels[Skill] := Buffer.GetByte;
  if FileVersion < 1 then
  begin
    Disqualified := False;
    ScoreTags.Clear;
    GenerationSeed := 0;
    QuestResults := nil;
  end
  else
  begin
    Disqualified := Buffer.GetBoolean;
    Buffer.ReadLengthPrefixedBuffer(ScoreTags);
    GenerationSeed := Buffer.GetInt32;
    SetLength(QuestResults, Buffer.GetWord);
    for I := 0 to High(QuestResults) do
    begin
      QuestResults[I].Successful := Buffer.GetBoolean;
      QuestResults[I].QuestType := Buffer.GetByte;
      QuestResults[I].QuestNumber := Buffer.GetByte;
    end;
  end;
  RecalculateTotalScore;
end;
{ @end $4D9E3C }

{ @routine $4D9FD8 TfScoreUnit_ExportToFile }
procedure TfScoreUnit.ExportToFile(FileName: WideString);
var
  Text: WideString;
  AnsiText: AnsiString;
  FileObject: TFileEC;
  Buffer, Encoded: TBufEC;
  Seed: Integer;
  Checksum: Cardinal;
  Data: PByte;
  I: Integer;
begin
  Text := '// Score for Space Rangers' + #13#10;
  Text := Text + 'Name=' + PlayerName + #13#10;
  Text := Text + 'EMail=' + #13#10;
  Text := Text + 'Race=' + OwnerInfo[RaceToOwner(PilotRace)].DisplayName + #13#10;
  Text := Text + 'Score=' + WideString(IntToStr(TotalScore)) + #13#10;
  Text := Text + 'Level=' + DifficultyModifiers[Difficulty].DisplayName + #13#10;
  Text := Text + 'Date=' + FormatGameTurnDate(FinishedTurn) + #13#10;
  Text := Text + 'Rank=' + LocalizedText('Rank.' + CoalitionRankNames[Rank] + '.Name') + #13#10;
  Text := Text + 'KillNormalShip=' + WideString(IntToStr(OtherShipKillCount)) + #13#10;
  Text := Text + 'KillPirate=' + WideString(IntToStr(PirateKillCount)) + #13#10;
  Text := Text + 'KillKling=' + WideString(IntToStr(KlissanKillCount)) + #13#10;
  Text := Text + 'LiberationSystem=' + WideString(IntToStr(LiberatedSystemCount)) + #13#10;
  Text := Text + 'Rewards=' + WideString(IntToStr(AwardCount)) + #13#10;
  Text := Text + 'Protoplasm=' + WideString(IntToStr(ProtoplasmCount)) + #13#10;
  Text := Text + 'TypeWin=' + RemoveTextTagsW(ReplaceAllWideString(LocalizedColorText('FormScore.TypeWin.' + IntToStr(Outcome)), '<Name>', PlayerName)) + #13#10;
  Text := Text + 'SkillAccuracy=' + WideString(IntToStr(SkillLevels[skAccuracy])) + #13#10;
  Text := Text + 'SkillMobility=' + WideString(IntToStr(SkillLevels[skMobility])) + #13#10;
  Text := Text + 'SkillTechnical=' + WideString(IntToStr(SkillLevels[skTechnical])) + #13#10;
  Text := Text + 'SkillTrader=' + WideString(IntToStr(SkillLevels[skTrader])) + #13#10;
  Text := Text + 'SkillCharm=' + WideString(IntToStr(SkillLevels[skCharm])) + #13#10;
  Text := Text + 'SkillLeadership=' + WideString(IntToStr(SkillLevels[skLeadership])) + #13#10 + #13#10 + #13#10;
  Text := Text + '*************** Protect database ****************' + #13#10 + #13#10;
  Buffer := TBufEC.Create;
  Encoded := TBufEC.Create;
  Seed := RandomIntRange(0, 2000000000);
  SaveToBuffer(Buffer);
  Checksum := Buffer.ComputeCrc32;
  Buffer.CompressZlibPayloadInPlace(False);
  Buffer.ApplyDatXorCipher(Seed);
  Encoded.AddIntegerValue(1);
  Encoded.AddDWord(Seed);
  Encoded.AddDWord(Checksum);
  Encoded.AddBytes(Buffer.Data, Buffer.DataSize);
  Buffer.Clear;
  Data := Encoded.Data;
  for I := 0 to Encoded.DataSize - 1 do
  begin
    Buffer.AddAnsiStringRaw(AnsiString(' ' + ByteToHexText(Data^)));
    if I and $0F = $0F then Buffer.AddAnsiStringRaw(#13#10);
    Data := PByte(PAnsiChar(Data) + 1);
  end;
  AnsiText := AnsiString(Text);
  FileObject := TFileEC.Create;
  try
    FileObject.SetFileName(FileName);
    FileObject.CreateNew;
    FileObject.WriteBuffer(PAnsiChar(AnsiText), Length(AnsiText));
    FileObject.WriteBuffer(Buffer.Data, Buffer.DataSize);
  except
  end;
  FileObject.Free;
  Buffer.Free;
  Encoded.Free;
end;
{ @end $4D9FD8 }

{ @routine $4DAAD4 TfScore_CreateDefaultTable }
procedure TfScore.CreateDefaultTable;
var I, J, N: Integer; Skill: TSkill; Entry, First, Second: TfScoreUnit;
begin
  ClearEntries;
  for I := 0 to 10 do
  begin
    Entry := TfScoreUnit.Create;
    Entries.Add(Entry);
    case I of
      0:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 5600;
        Entry.OtherShipKillCount := 34;
        Entry.PirateKillCount := 50;
        Entry.KlissanKillCount := 270;
        Entry.LiberatedSystemCount := 15;
        Entry.AwardCount := 14;
        Entry.ProtoplasmCount := 4000;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(3, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 0;
      end;
      1:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 6000;
        Entry.OtherShipKillCount := 12;
        Entry.PirateKillCount := 95;
        Entry.KlissanKillCount := 180;
        Entry.LiberatedSystemCount := 13;
        Entry.AwardCount := 11;
        Entry.ProtoplasmCount := 3510;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(1, 5, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 1;
      end;
      2:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 6500;
        Entry.OtherShipKillCount := 110;
        Entry.PirateKillCount := 199;
        Entry.KlissanKillCount := 203;
        Entry.LiberatedSystemCount := 8;
        Entry.AwardCount := 7;
        Entry.ProtoplasmCount := 2480;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(1, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 11;
      end;
      3:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 7000;
        Entry.OtherShipKillCount := 102;
        Entry.PirateKillCount := 2;
        Entry.KlissanKillCount := 135;
        Entry.LiberatedSystemCount := 6;
        Entry.AwardCount := 12;
        Entry.ProtoplasmCount := 2400;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(1, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 10;
      end;
      4:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 7500;
        Entry.OtherShipKillCount := 28;
        Entry.PirateKillCount := 113;
        Entry.KlissanKillCount := 122;
        Entry.LiberatedSystemCount := 7;
        Entry.AwardCount := 11;
        Entry.ProtoplasmCount := 2020;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(1, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 11;
      end;
      5:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 8000;
        Entry.OtherShipKillCount := 34;
        Entry.PirateKillCount := 120;
        Entry.KlissanKillCount := 148;
        Entry.LiberatedSystemCount := 11;
        Entry.AwardCount := 10;
        Entry.ProtoplasmCount := 1800;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(0, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 11;
      end;
      6:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 8500;
        Entry.OtherShipKillCount := 40;
        Entry.PirateKillCount := 105;
        Entry.KlissanKillCount := 130;
        Entry.LiberatedSystemCount := 8;
        Entry.AwardCount := 7;
        Entry.ProtoplasmCount := 1680;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(0, 4, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 1;
      end;
      7:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 9000;
        Entry.OtherShipKillCount := 60;
        Entry.PirateKillCount := 35;
        Entry.KlissanKillCount := 92;
        Entry.LiberatedSystemCount := 6;
        Entry.AwardCount := 9;
        Entry.ProtoplasmCount := 1400;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(1, 3, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 10;
      end;
      8:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 9300;
        Entry.OtherShipKillCount := 10;
        Entry.PirateKillCount := 82;
        Entry.KlissanKillCount := 78;
        Entry.LiberatedSystemCount := 5;
        Entry.AwardCount := 7;
        Entry.ProtoplasmCount := 1250;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(0, 3, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 11;
      end;
      9:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 9500;
        Entry.OtherShipKillCount := 2;
        Entry.PirateKillCount := 15;
        Entry.KlissanKillCount := 45;
        Entry.LiberatedSystemCount := 3;
        Entry.AwardCount := 5;
        Entry.ProtoplasmCount := 1100;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(0, 3, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := 0;
      end;
      10:
      begin
        Entry.Difficulty := dfExpert;
        Entry.FinishedTurn := 10000;
        Entry.OtherShipKillCount := 33;
        Entry.PirateKillCount := 7;
        Entry.KlissanKillCount := 30;
        Entry.LiberatedSystemCount := 1;
        Entry.AwardCount := 1;
        Entry.ProtoplasmCount := 300;
        for Skill := skAccuracy to skLeadership do Entry.SkillLevels[Skill] := SeededRandomIntRange(0, 1, Entry.ProtoplasmCount + I + Ord(Skill));
        Entry.Outcome := -1;
      end;
    end;
    Entry.PlayerName := LookupLocalizedTextByKey('FormScore.Winners.' + IntToStr(I) + '.Name');
    Entry.PilotRace := OwnerToRace(OwnerFromInternalName(LookupLocalizedTextByKey('FormScore.Winners.' + IntToStr(I) + '.Race')));
    Entry.Rank := TCoalitionRank(Round(RemapClampedAlternate(I, 0, 10, 5, 3)));
    Entry.Difficulty := TDifficulty(Round(RemapClampedAlternate(I, 0, 10, 2, 0)));
    Entry.RecalculateTotalScore;
  end;
  N := Entries.Count;
  if N <> 11 then RaiseWideMessage('Score error');
  for I := 0 to N - 2 do
    for J := I + 1 to N - 1 do
    begin
      First := Entries[I];
      Second := Entries[J];
      if Second.TotalScore > First.TotalScore then
      begin
        Entries[I] := Second;
        Entries[J] := First;
      end;
    end;
end;
{ @end $4DAAD4 }

{ @routine $4DB1F4 TfScore_RecordPlayerResult }
procedure TfScore.RecordPlayerResult(ResultKind: Integer);
var I, J, N: Integer; First, Second: TfScoreUnit;
begin
  ReloadTable;
  N := Entries.Count;
  if N <> 11 then RaiseWideMessage('Score sort');
  Galaxy.AppendScoreIntegritySnapshot;
  TfScoreUnit(Entries[Entries.Count - 1]).CapturePlayer(ResultKind);
  SelectedIndex := N - 1;
  for I := 0 to N - 2 do
    for J := I + 1 to N - 1 do
    begin
      First := Entries[I];
      Second := Entries[J];
      if Second.TotalScore > First.TotalScore then
      begin
        Entries[I] := Second;
        SelectedIndex := I;
        Entries[J] := First;
      end;
    end;
  SaveTableToDisk;
end;
{ @end $4DB1F4 }

{ @routine $4DB2F4 TfScore_ClearEntries }
procedure TfScore.ClearEntries;
var I: Integer; Entry: TObject;
begin
  for I := 0 to Entries.Count - 1 do
  begin
    Entry := Entries[I];
    Entry.Free;
  end;
  Entries.Clear;
end;
{ @end $4DB2F4 }

{ @routine $4DB330 TfScore_ReloadTable }
procedure TfScore.ReloadTable;
var
  Buffer: TBufEC;
  Data: PByte;
  I, J, N, Size, Seed, Version: Integer;
  Checksum: Cardinal;
  Entry, First, Second: TfScoreUnit;
begin
  ClearEntries;
  if not FileExists('score.dat') then CreateDefaultTable
  else
  begin
    Buffer := TBufEC.Create;
    try
      Buffer.LoadFromFilePath('score.dat');
      Buffer.ExpandZlibPayloadInPlace;
      Version := Buffer.GetInt32At(0);
      if Version > 1 then raise EAbort.Create('');
      Seed := Integer(Buffer.GetByteAt(6)) or (Integer(Buffer.GetByteAt(7)) shl 8) or
        (Integer(Buffer.GetByteAt(4)) shl 16) or (Integer(Buffer.GetByteAt(5)) shl 24);
      Data := PByte(Cardinal(Buffer.Data) + 8);
      Size := Buffer.DataSize;
      for I := 8 to Size - 1 do
      begin
        Data^ := Data^ xor Byte(Seed - 1);
        Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
        if Seed <= 0 then Inc(Seed, MaxInt);
        Data := PByte(PAnsiChar(Data) + 1);
      end;
      Checksum := 0;
      Data := PByte(Cardinal(Buffer.Data) + 12);
      for I := 12 to Size - 1 do
      begin
        Inc(Checksum, Byte(Data^ xor $FF));
        Data := PByte(PAnsiChar(Data) + 1);
      end;
      if Checksum <> Buffer.GetUInt32At(8) then raise EAbort.Create('');
      Buffer.SetPosition(12);
      for I := 0 to 10 do
      begin
        Entry := TfScoreUnit.Create;
        Entries.Add(Entry);
        Entry.LoadFromBuffer(Buffer, Version);
      end;
    except
      CreateDefaultTable;
    end;
    N := Entries.Count;
    // Native leaves the eleventh entry outside this post-load sort.
    for I := 0 to N - 3 do
      for J := I + 1 to N - 2 do
      begin
        First := Entries[I];
        Second := Entries[J];
        if Second.TotalScore > First.TotalScore then
        begin
          Entries[I] := Second;
          Entries[J] := First;
        end;
      end;
    Buffer.Free;
  end;
end;
{ @end $4DB330 }

{ @routine $4DB5C4 TfScore_SaveTableToDisk }
procedure TfScore.SaveTableToDisk;
var
  Buffer: TBufEC;
  I, Size, Seed: Integer;
  Entry: TfScoreUnit;
  Data: PByte;
  FileObject: TFileEC;
  Checksum: Integer;
begin
  if Entries.Count <> 11 then CreateDefaultTable;
  Seed := Random(MaxInt);
  Buffer := TBufEC.Create;
  Buffer.AddIntegerValue(1);
  Buffer.AddIntegerValue(0);
  Buffer.AddIntegerValue(0);
  Buffer.SetByteAt(6, Byte(Seed));
  Buffer.SetByteAt(7, Byte(Cardinal(Seed) shr 8));
  Buffer.SetByteAt(4, Byte(Cardinal(Seed) shr 16));
  Buffer.SetByteAt(5, Byte(Cardinal(Seed) shr 24));
  for I := 0 to Entries.Count - 1 do
  begin
    Entry := Entries[I];
    Entry.SaveToBuffer(Buffer);
  end;
  Size := Buffer.DataSize;
  Checksum := 0;
  Data := PByte(Cardinal(Buffer.Data) + 12);
  for I := 12 to Size - 1 do
  begin
    Inc(Checksum, Byte(Data^ xor $FF));
    Data := PByte(PAnsiChar(Data) + 1);
  end;
  Buffer.SetInt32At(8, Checksum);
  Data := PByte(Cardinal(Buffer.Data) + 8);
  for I := 8 to Size - 1 do
  begin
    Data^ := Data^ xor Byte(Seed - 1);
    Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
    if Seed <= 0 then Inc(Seed, MaxInt);
    Data := PByte(PAnsiChar(Data) + 1);
  end;
  Buffer.CompressZlibPayloadInPlace(False);
  FileObject := TFileEC.Create;
  FileObject.SetFileName('score.dat');
  FileObject.CreateNew;
  FileObject.WriteBuffer(Buffer.Data, Buffer.DataSize);
  FileObject.Free;
  Buffer.Free;
end;
{ @end $4DB5C4 }

{ @routine $4DB770 TfScore_Create }
constructor TfScore.Create;
begin
  inherited Create;
  Entries := TList.Create;
end;
{ @end $4DB770 }

{ @routine $4DB7B8 TfScore_Destroy }
destructor TfScore.Destroy;
begin
  ClearEntries;
  Entries.Free;
  inherited Destroy;
end;
{ @end $4DB7B8 }

{ @routine $4DB7F0 TfScore_InitializeLayout }
procedure TfScore.InitializeLayout;
begin
  inherited InitializeLayout;
  with GetByName('ButClear') as TGraphButtonGI do
  begin
    UpCallback := ClearTableClicked;
    HelpCallback := ShowControlHelp;
  end;
  with GetByName('ButExit') as TGraphButtonGI do
  begin
    UpCallback := CloseClicked;
    HelpCallback := ShowControlHelp;
  end;
  GetByName('MainPanel').KeyDownCallback := KeyDown;
  SelectedIndex := 0;
end;
{ @end $4DB7F0 }

{ @routine $4DB8C8 TfScore_OnOpen }
procedure TfScore.OnOpen;
var I: Integer; Row, Panel: TPanelGI;
begin
  GetByName('LabelHelp').SetActive(False);
  Panel := GetByName('PanelSlot') as TPanelGI;
  for I := 0 to 10 do
  begin
    Row := TPanelGI.Create(Panel);
    if GiResourceVariant = 1 then
    begin
      Row.SetPosition(Classes.Point(0, I * 42));
      Row.SetSize(Classes.Point(Panel.ClientSize.X, 42));
    end
    else
    begin
      Row.SetPosition(Classes.Point(0, I * 55));
      Row.SetSize(Classes.Point(Panel.ClientSize.X, 55));
    end;
    Row.SetName(WideString('Slot' + IntToStr(I)));
    Row.LeftButtonDownCallback := EntryMouseDown;
    with TImageGI.Create(Row) do
    begin
      SetDepthByName('99');
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(0, 0));
        SetSize(Classes.Point(348, 43));
      end
      else
      begin
        SetPosition(Classes.Point(0, 0));
        SetSize(Classes.Point(445, 56));
      end;
      SetActive(False);
      SetName(WideString('Slot' + IntToStr(I) + 'Active'));
      SetImagePath('GI,Bm.FormScore.' + GiResourceSuffix + 'sel');
    end;
    with TLabelGI.Create(Row) do
    begin
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(1, 1));
        SetSize(Classes.Point(29, 42));
      end
      else
      begin
        SetPosition(Classes.Point(1, 1));
        SetSize(Classes.Point(37, 54));
      end;
      SetDepthByName('98');
      SetFontName(HitPointFontName);
      SetTextAlignX(taxCenter);
      SetTextAlignY(tayCenterEx);
      SetText(WideString(IntToStr(I + 1)));
    end;
    with TImageGI.Create(Row) do
    begin
      SetDepthByName('98');
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(33, 5));
        SetSize(Classes.Point(36, 33));
      end
      else
      begin
        SetPosition(Classes.Point(41, 5));
        SetSize(Classes.Point(47, 46));
      end;
      SetActive(True);
      SetName(WideString('Slot' + IntToStr(I) + 'Emblem'));
    end;
    with TLabelGI.Create(Row) do
    begin
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(73, 1));
        SetSize(Classes.Point(105, 42));
      end
      else
      begin
        SetPosition(Classes.Point(93, 1));
        SetSize(Classes.Point(135, 54));
      end;
      SetDepthByName('98');
      SetFontName(HitPointFontName);
      SetTextAlignX(taxCenter);
      SetTextAlignY(tayCenterEx);
      SetName(WideString('Slot' + IntToStr(I) + 'Score'));
    end;
    with TLabelGI.Create(Row) do
    begin
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(188, 4));
        SetSize(Classes.Point(130, 15));
      end
      else
      begin
        SetPosition(Classes.Point(240, 5));
        SetSize(Classes.Point(167, 19));
      end;
      SetDepthByName('98');
      SetFontName(HitPointFontName);
      SetTextAlignX(taxCenter);
      SetTextAlignY(tayCenterEx);
      SetName(WideString('Slot' + IntToStr(I) + 'Name'));
    end;
    with TLabelGI.Create(Row) do
    begin
      if GiResourceVariant = 1 then
      begin
        SetPosition(Classes.Point(188, 23));
        SetSize(Classes.Point(130, 15));
      end
      else
      begin
        SetPosition(Classes.Point(240, 30));
        SetSize(Classes.Point(167, 19));
      end;
      SetDepthByName('98');
      SetFontName(HitPointFontName);
      SetTextAlignX(taxCenter);
      SetTextAlignY(tayCenterEx);
      SetName(WideString('Slot' + IntToStr(I) + 'Code'));
    end;
    with TGraphButtonGI.Create(GetByName('PanelToServer') as TPanelGI) do
    begin
      UpCallback := ExportEntryClicked;
      if GiResourceVariant = 1 then SetPosition(Classes.Point(0, I * 42 + 1))
      else SetPosition(Classes.Point(0, I * 55 + 2));
      SetImageNormalPath('GI,Bm.FormScore.' + GiResourceSuffix + 'ToServerN');
      SetImageNormalActivePath('GI,Bm.FormScore.' + GiResourceSuffix + 'ToServerA');
      SetImageDownPath('GI,Bm.FormScore.' + GiResourceSuffix + 'ToServerD');
      HitKind := gbhGraph;
      MouseBlocking := True;
      SetSize(GetMaxStateImageSize);
      UserValue := I;
      SetName(WideString('Slot' + IntToStr(I) + 'ToServer'));
      HelpText := LookupLocalizedTextByKey('FormScore.HelpToServer');
      HelpCallback := ShowControlHelp;
    end;
  end;
  ReloadTable;
  RefreshDetails;
  HideExportPanel(nil);
end;
{ @end $4DB8C8 }

{ @routine $4DC3CC TfScore_OnClose }
procedure TfScore.OnClose;
begin
  (GetByName('PanelSlot') as TPanelGI).FreeOwnedChildren;
  (GetByName('PanelToServer') as TPanelGI).FreeOwnedChildren;
end;
{ @end $4DC3CC }

{ @routine $4DC444 TfScore_ClearTableClicked }
procedure TfScore.ClearTableClicked(Sender: TObjectGI);
begin
  HideExportPanel(nil);
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormScore.QueryClear'), mbgOK or mbgCancel) = mbgResultOK then
  begin
    SysUtils.DeleteFile('score.dat');
    ReloadTable;
    RefreshDetails;
  end;
end;
{ @end $4DC444 }

{ @routine $4DC50C TfScore_CloseClicked }
procedure TfScore.CloseClicked(Sender: TObjectGI);
begin
  if ReturnToEndScreen then RequestedScreenId := screenAbout else RequestedScreenId := screenMainMenu;
  RequestClose(1);
end;
{ @end $4DC50C }

{ @routine $4DC534 TfScore_KeyDown }
procedure TfScore.KeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if (Key = VK_ESCAPE) or (Key = VK_RETURN) then
  begin
    if GetByName('PTS').Active then HideExportPanel(nil) else CloseClicked(nil);
  end
  else if Key = Ord('C') then ClearTableClicked(nil)
  else if (Key = VK_HOME) or (Key = VK_PRIOR) then
  begin
    SelectedIndex := 0;
    RefreshDetails;
  end
  else if (Key = VK_END) or (Key = VK_NEXT) then
  begin
    SelectedIndex := Entries.Count - 1;
    RefreshDetails;
  end
  else if (Key = VK_UP) or (Key = VK_LEFT) then
  begin
    SelectedIndex := Max(0, SelectedIndex - 1);
    RefreshDetails;
  end
  else if (Key = VK_DOWN) or (Key = VK_RIGHT) then
  begin
    SelectedIndex := Min(Entries.Count - 1, SelectedIndex + 1);
    RefreshDetails;
  end;
end;
{ @end $4DC534 }

{ @routine $4DC620 TfScore_RefreshDetails }
procedure TfScore.RefreshDetails;
var I: Integer; Entry: TfScoreUnit; Selected: Boolean;
begin
  for I := 0 to Entries.Count - 1 do
  begin
    Entry := Entries[I];
    (GetByName(WideString('Slot' + IntToStr(I) + 'Active')) as TImageGI).SetActive(I = SelectedIndex);
    Selected := I = SelectedIndex;
    with GetByName(WideString('Slot' + IntToStr(I) + 'Emblem')) as TImageGI do
    begin
      SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix +
        OwnerInfo[RaceToOwner(Entry.PilotRace)].InternalName));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
    with GetByName(WideString('Slot' + IntToStr(I) + 'Score')) as TLabelGI do
    begin
      SetText(WideString(IntToStr(Entry.TotalScore)));
      if Selected then
      begin
        SetTextColor(CurrentPixelFormat.PackRgbBytes(219, 219, 86));
        SetFontName(ScoreFontName);
      end
      else
      begin
        SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
        SetFontName(ScoreFontName);
      end;
    end;
    with GetByName(WideString('Slot' + IntToStr(I) + 'Name')) as TLabelGI do
    begin
      SetText(Entry.PlayerName);
      if Selected then SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 255, 50))
      else SetTextColor(CurrentPixelFormat.PackRgbBytes(0, 255, 0));
    end;
    with GetByName(WideString('Slot' + IntToStr(I) + 'Code')) as TLabelGI do
    begin
      SetText(WrapTextInColor(DifficultyModifiers[Entry.Difficulty].DisplayName, '<color=191,185,128>'));
      if Selected then SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230))
      else SetTextColor(CurrentPixelFormat.PackRgbBytes(161, 202, 205));
    end;
    with GetByName(WideString('Slot' + IntToStr(I) + 'ToServer')) as TGraphButtonGI do
      if ((Entry.Outcome >= 0) or AllowDefeatScoreExport) and (Entry.ScoreTags.DataSize > 0) then SetActive(True)
      else SetActive(False);
  end;
  Entry := Entries[SelectedIndex];
  with GetByName('CaptainI') as TImageGI do
  begin
    SetImagePath('GI,Bm.Captain.' + GiResourceSuffix +
      OwnerInfo[RaceToOwner(Entry.PilotRace)].InternalName + '0i');
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetActive(True);
  end;
  with GetByName('CaptainA') as TgaiGI do
  begin
    FirstFrameOnly := not AnimCaptain;
    SetImagePath('Bm.Captain.' + GiResourceSuffix +
      OwnerInfo[RaceToOwner(Entry.PilotRace)].InternalName + '0a');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetActive(True);
    RestartPlayback;
  end;
  with GetByName('RankI') as TImageGI do
    if Entry.Rank = crRookie then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank0')
    else if Entry.Rank = crCadet then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank1')
    else if Entry.Rank = crPilot then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank2')
    else if Entry.Rank = crWingman then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank3')
    else if Entry.Rank = crLeader then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank4')
    else if Entry.Rank = crAce then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank5')
    else if Entry.Rank = crCommander then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank6');
  with GetByName('Skill0') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skAccuracy]), ClientSize.Y));
  with GetByName('Skill1') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skMobility]), ClientSize.Y));
  with GetByName('Skill2') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skTechnical]), ClientSize.Y));
  with GetByName('Skill3') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skTrader]), ClientSize.Y));
  with GetByName('Skill4') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skCharm]), ClientSize.Y));
  with GetByName('Skill5') as TImageGI do
    SetSize(Classes.Point(Round(GetContentSize.X / 5 * Entry.SkillLevels[skLeadership]), ClientSize.Y));
  (GetByName('I0') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.DayWin'),
    HighlightColorTag, '<Date>', FormatGameTurnDate(Entry.FinishedTurn)));
  (GetByName('I0S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeTurnScore)));
  (GetByName('I1') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.Rank'),
    HighlightColorTag, '<Rank>', LocalizedText('Rank.' + CoalitionRankNames[Entry.Rank] + '.Name')));
  (GetByName('I1S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeRankScore)));
  (GetByName('I2') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.KillNormalShip'),
    HighlightColorTag, '<KillNormalShip>', WideString(IntToStr(Entry.OtherShipKillCount))));
  (GetByName('I2S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeOtherKillsScore)));
  (GetByName('I3') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.KillPirate'),
    HighlightColorTag, '<KillPirate>', WideString(IntToStr(Entry.PirateKillCount))));
  (GetByName('I3S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputePirateKillsScore)));
  (GetByName('I4') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.KillKling'),
    HighlightColorTag, '<KillKling>', WideString(IntToStr(Entry.KlissanKillCount))));
  (GetByName('I4S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeKlissanKillsScore)));
  (GetByName('I5') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.LiberationSystem'),
    HighlightColorTag, '<LiberationSystem>', WideString(IntToStr(Entry.LiberatedSystemCount))));
  (GetByName('I5S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeLiberationScore)));
  (GetByName('I6') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.Rewards'),
    HighlightColorTag, '<Rewards>', WideString(IntToStr(Entry.AwardCount))));
  (GetByName('I6S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeAwardScore)));
  (GetByName('I7') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.Protoplasm'),
    HighlightColorTag, '<Protoplasm>', WideString(IntToStr(Entry.ProtoplasmCount))));
  (GetByName('I7S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeProtoplasmScore)));
  (GetByName('I8S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeSkillScore)));
  (GetByName('I9') as TLabelGI).SetText(FormatText1(LocalizedColorText('FormScore.TypeWin.' + IntToStr(Entry.Outcome)),
    HighlightColorTag, '<Name>', Entry.PlayerName));
  (GetByName('I9') as TLabelGI).SetFontName(ScoreFontName);
  (GetByName('I9S') as TLabelGI).SetText(WideString(IntToStr(Entry.ComputeOutcomeScore)));
  (GetByName('I10') as TLabelGI).SetText(LocalizedColorText('FormScore.Total'));
  (GetByName('I10S') as TLabelGI).SetText(WideString(IntToStr(Entry.TotalScore)));
end;
{ @end $4DC620 }

{ @routine $4DE02C TfScore_EntryMouseDown }
procedure TfScore.EntryMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  HideExportPanel(nil);
  if not Sender.IsOccludedAtPoint(Point) then
  begin
    SelectedIndex := ExtractDigitsToIntW(Sender.ControlName);
    RefreshDetails;
  end;
end;
{ @end $4DE02C }

{ @routine $4DE078 TfScore_ExportEntryClicked }
procedure TfScore.ExportEntryClicked(Sender: TObjectGI);
var Index: Integer; Entry: TfScoreUnit; FileName, Text: WideString;
begin
  HideExportPanel(nil);
  Index := Sender.UserValue;
  Entry := Entries[Index];
  if Index + 1 < 10 then FileName := GetCurrentDir + '\ToServer0' + IntToStr(Index + 1) + '.txt'
  else FileName := GetCurrentDir + '\ToServer' + IntToStr(Index + 1) + '.txt';
  Entry.ExportToFile(FileName);
  Text := LocalizedColorText('FormScore.ToServer');
  Text := ReplaceColoredToken(Text, '<Player>', Entry.PlayerName, HighlightColorTag);
  Text := ReplaceColoredToken(Text, '<File>', FileName, HighlightColorTag);
  Text := ReplaceColoredToken(Text, '<WinGameDate>', FormatGameTurnDate(Entry.FinishedTurn), HighlightColorTag);
  GetByName('PTS').SetActive(True);
  (GetByName('PTSLabel') as TLabelGI).SetText(Text);
  with GetByName('PTSClose') as TGraphButtonGI do
  begin
    SetSize(GetMaxStateImageSize);
    UpCallback := HideExportPanel;
  end;
end;
{ @end $4DE078 }

{ @routine $4DE394 TfScore_HideExportPanel }
procedure TfScore.HideExportPanel(Sender: TObjectGI);
begin
  GetByName('PTS').SetActive(False);
end;
{ @end $4DE394 }

{ @routine $4DE3B8 TfScore_ShowControlHelp }
procedure TfScore.ShowControlHelp(Sender: TObjectGI; Visible: Boolean);
begin
  with GetByName('LabelHelp') as TLabelGI do
  begin
    if Sender.HelpText = '' then Visible := False;
    SetActive(Visible);
    SetText(Sender.HelpText);
  end;
end;
{ @end $4DE3B8 }

{ @routine $4DE41C TfScore_SelectMusic }
procedure TfScore.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;
{ @end $4DE41C }

end.

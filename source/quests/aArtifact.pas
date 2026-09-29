unit aArtifact;
// Unit bracket (inferred): CODE 0x005E1494..0x005E237B; inclusive evidence, not full bounds.
// Native quest-content VMT $5E14D8; consumers include ranger quest descriptions.
interface
uses EC_Buf, aArtifactTextFieldClass, aQuestParameterClass, aArtifactLocationClass, aArtifactPathClass;
type
  TQuestFlagBits = set of 0..7; // @size $01
  TQuestGameContent = class(TObject) // @size $150
  public
    function FindLocationIndex(Id: Integer): Integer; // @addr $5E2314
    function HasEmptyPathLabel(PathIndex: Integer): Boolean; // @addr $5E1550
    procedure LoadQuest(Number: Integer); // @addr $5E2210
    procedure LoadFromReader(Reader: TBufEC); // @addr $5E1B48
    procedure ResetEventIndices; // @addr $5E1740
    destructor Destroy; override; // @addr $5E19EC
    constructor Create; // @addr $5E18B8
    procedure Reset; // @addr $5E1768
    function ConvertLegacyIssuerRaceMask(Value: Integer): TQuestFlagBits; // @addr $5E16D4
    function ConvertLegacyTargetOwnerMask(Value: Integer): TQuestFlagBits; // @addr $5E1668
    function ConvertLegacyPlayerCareerMask(Value: Integer): TQuestFlagBits; // @addr $5E1624
    function ConvertLegacyPlayerRaceMask(Value: Integer): TQuestFlagBits; // @addr $5E15B8
    FormatVersion: Integer; // @offset $4
    EditorScreenWidth: Integer; // @offset $8
    EditorScreenHeight: Integer; // @offset $C
    EditorGridWidth: Integer; // @offset $10
    EditorGridHeight: Integer; // @offset $14
    Difficulty: Integer; // @offset $18
    CompleteOnFinish: Boolean; // @offset $1C
    LegacyIssuerRace: Integer; // @offset $20
    IssuerRaceMask: TQuestFlagBits; // @offset $24
    LegacyTargetOwner: Integer; // @offset $28
    TargetOwnerMask: TQuestFlagBits; // @offset $2C
    LegacyPlayerCareer: Integer; // @offset $30
    PlayerCareerMask: TQuestFlagBits; // @offset $34
    LegacyPlayerRace: Integer; // @offset $38
    PlayerRaceMask: TQuestFlagBits; // @offset $3C
    SuccessRelationDelta: Integer; // @offset $40
    UnresolvedValue44: Integer; // @offset $44
    Parameters: array[1..48] of TQuestParameter; // @offset $48
    QuestDescriptionText: TTextField; // @offset $108
    QuestSuccessGovMessageText: TTextField; // @offset $10C
    UnresolvedText110: TTextField; // @offset $110
    UnresolvedValue114: Integer; // @offset $114
    ToStarText: TTextField; // @offset $118
    UnresolvedText11C: TTextField; // @offset $11C
    UnresolvedText120: TTextField; // @offset $120
    ToPlanetText: TTextField; // @offset $124
    DateText: TTextField; // @offset $128
    MoneyText: TTextField; // @offset $12C
    FromPlanetText: TTextField; // @offset $130
    FromStarText: TTextField; // @offset $134
    RangerText: TTextField; // @offset $138
    Locations: array of TLocation; // @offset $13C
    Paths: array of TPath; // @offset $140
    LocationCount: Integer; // @offset $144
    PathCount: Integer; // @offset $148
    UnresolvedValue14C: Integer; // @offset $14C
  end;
implementation

// @unit-initialization $5E2374
// @unit-finalization $5E2344

uses EC_Cache, EC_CacheBuf, SysUtils;

{ @routine $5E1550 TQuestGameContent_HasEmptyPathLabel }
function TQuestGameContent.HasEmptyPathLabel(PathIndex: Integer): Boolean;
begin
  if SysUtils.Trim(Paths[PathIndex].ChoiceText.Text) = '' then Result := True
  else Result := False;
end;
{ @end $5E1550 }

{ @routine $5E15B8 TQuestGameContent_ConvertLegacyPlayerRaceMask }
function TQuestGameContent.ConvertLegacyPlayerRaceMask(Value: Integer): TQuestFlagBits;
begin
  Result := [];
  case Value of
    -1: Result := [0..4];
    0: Result := [0];
    1: Result := [1];
    2: Result := [2];
    3: Result := [3];
    4: Result := [4];
  end;
end;
{ @end $5E15B8 }

{ @routine $5E1624 TQuestGameContent_ConvertLegacyPlayerCareerMask }
function TQuestGameContent.ConvertLegacyPlayerCareerMask(Value: Integer): TQuestFlagBits;
begin
  Result := [];
  case Value of
    -1: Result := [0..2];
    0: Result := [0];
    1: Result := [1];
    2: Result := [2];
  end;
end;
{ @end $5E1624 }

{ @routine $5E1668 TQuestGameContent_ConvertLegacyTargetOwnerMask }
function TQuestGameContent.ConvertLegacyTargetOwnerMask(Value: Integer): TQuestFlagBits;
begin
  Result := [];
  case Value of
    -1: Result := [6];
    0: Result := [0];
    1: Result := [1];
    2: Result := [2];
    3: Result := [3];
    4: Result := [4];
  end;
end;
{ @end $5E1668 }

{ @routine $5E16D4 TQuestGameContent_ConvertLegacyIssuerRaceMask }
function TQuestGameContent.ConvertLegacyIssuerRaceMask(Value: Integer): TQuestFlagBits;
begin
  Result := [];
  case Value of
    -1: Result := [6];
    0: Result := [0];
    1: Result := [1];
    2: Result := [2];
    3: Result := [3];
    4: Result := [4];
  end;
end;
{ @end $5E16D4 }

{ @routine $5E1740 TQuestGameContent_ResetEventIndices }
procedure TQuestGameContent.ResetEventIndices;
var I: Integer;
begin
  for I := 1 to LocationCount do Locations[I].NextEventIndex := 1;
end;
{ @end $5E1740 }

{ @routine $5E1768 TQuestGameContent_Reset }
procedure TQuestGameContent.Reset;
var I: Integer;
begin
  FormatVersion := 1111111123;
  CompleteOnFinish := True;
  Difficulty := 50;
  IssuerRaceMask := [0..4];
  TargetOwnerMask := [6];
  PlayerRaceMask := [0..4];
  PlayerCareerMask := [0..2];
  UnresolvedValue114 := 1;
  LegacyIssuerRace := 0;
  EditorScreenWidth := 0;
  EditorScreenHeight := 0;
  UnresolvedValue44 := 1;
  LegacyTargetOwner := -1;
  LegacyPlayerCareer := -1;
  LegacyPlayerRace := -1;
  SuccessRelationDelta := 0;
  for I := 1 to 48 do Parameters[I].Reset(I);
  QuestSuccessGovMessageText.Text := '';
  QuestDescriptionText.Text := '';
  UnresolvedText110.Text := '';
  ToStarText.Text := '';
  UnresolvedText11C.Text := '';
  UnresolvedText120.Text := '';
  ToPlanetText.Text := '';
  DateText.Text := '';
  MoneyText.Text := '';
  FromPlanetText.Text := '';
  FromStarText.Text := '';
  RangerText.Text := '';
  LocationCount := 0;
  PathCount := 0;
end;
{ @end $5E1768 }

{ @routine $5E18B8 TQuestGameContent_Create }
constructor TQuestGameContent.Create;
var I: Integer;
begin
  inherited Create;
  QuestSuccessGovMessageText := TTextField.Create;
  QuestDescriptionText := TTextField.Create;
  UnresolvedText110 := TTextField.Create;
  for I := 1 to 48 do Parameters[I] := TQuestParameter.Create(I);
  ToStarText := TTextField.Create;
  UnresolvedText11C := TTextField.Create;
  UnresolvedText120 := TTextField.Create;
  ToPlanetText := TTextField.Create;
  DateText := TTextField.Create;
  MoneyText := TTextField.Create;
  FromPlanetText := TTextField.Create;
  FromStarText := TTextField.Create;
  RangerText := TTextField.Create;
  Reset;
end;
{ @end $5E18B8 }

{ @routine $5E19EC TQuestGameContent_Destroy }
destructor TQuestGameContent.Destroy;
var I: Integer;
begin
  if QuestSuccessGovMessageText <> nil then begin QuestSuccessGovMessageText.Free; QuestSuccessGovMessageText := nil; end;
  if QuestDescriptionText <> nil then begin QuestDescriptionText.Free; QuestDescriptionText := nil; end;
  if UnresolvedText110 <> nil then begin UnresolvedText110.Free; UnresolvedText110 := nil; end;
  for I := 1 to 48 do begin
    if Parameters[I] <> nil then begin Parameters[I].Free; Parameters[I] := nil; end;
  end;
  if ToStarText <> nil then begin ToStarText.Free; ToStarText := nil; end;
  if UnresolvedText11C <> nil then begin UnresolvedText11C.Free; UnresolvedText11C := nil; end;
  if UnresolvedText120 <> nil then begin UnresolvedText120.Free; UnresolvedText120 := nil; end;
  if ToPlanetText <> nil then begin ToPlanetText.Free; ToPlanetText := nil; end;
  if DateText <> nil then begin DateText.Free; DateText := nil; end;
  if MoneyText <> nil then begin MoneyText.Free; MoneyText := nil; end;
  if FromPlanetText <> nil then begin FromPlanetText.Free; FromPlanetText := nil; end;
  if FromStarText <> nil then begin FromStarText.Free; FromStarText := nil; end;
  if RangerText <> nil then begin RangerText.Free; RangerText := nil; end;
  // Leaves the location and path objects allocated.
  inherited Destroy;
end;
{ @end $5E19EC }

{ @routine $5E1B48 TQuestGameContent_LoadFromReader }
procedure TQuestGameContent.LoadFromReader(Reader: TBufEC);
var I: Integer;
begin
  FormatVersion := Reader.GetInt32;
  if FormatVersion <= 1111111111 then begin
    LegacyIssuerRace := FormatVersion;
    FormatVersion := 1111111111;
  end else LegacyIssuerRace := Reader.GetInt32;
  if FormatVersion >= 1111111119 then Reader.ReadBytes(@IssuerRaceMask, SizeOf(IssuerRaceMask))
  else IssuerRaceMask := ConvertLegacyIssuerRaceMask(LegacyIssuerRace);
  if FormatVersion >= 1111111112 then CompleteOnFinish := Reader.GetBoolean;
  LegacyTargetOwner := Reader.GetInt32;
  if FormatVersion >= 1111111119 then Reader.ReadBytes(@TargetOwnerMask, SizeOf(TargetOwnerMask))
  else TargetOwnerMask := ConvertLegacyTargetOwnerMask(LegacyTargetOwner);
  LegacyPlayerCareer := Reader.GetInt32;
  if FormatVersion >= 1111111120 then Reader.ReadBytes(@PlayerCareerMask, SizeOf(PlayerCareerMask))
  else PlayerCareerMask := ConvertLegacyPlayerCareerMask(LegacyPlayerCareer);
  LegacyPlayerRace := Reader.GetInt32;
  if FormatVersion >= 1111111120 then Reader.ReadBytes(@PlayerRaceMask, SizeOf(PlayerRaceMask))
  else PlayerRaceMask := ConvertLegacyPlayerRaceMask(LegacyPlayerRace);
  SuccessRelationDelta := Reader.GetInt32;
  EditorScreenWidth := Reader.GetInt32;
  EditorScreenHeight := Reader.GetInt32;
  EditorGridWidth := Reader.GetInt32;
  EditorGridHeight := Reader.GetInt32;
  UnresolvedValue114 := Reader.GetInt32;
  if FormatVersion >= 1111111120 then UnresolvedValue44 := Reader.GetInt32;
  if FormatVersion >= 1111111121 then Difficulty := Reader.GetInt32;
  if FormatVersion >= 1111111123 then begin
    for I := 1 to 48 do Parameters[I].LoadLegacyV4FromReader(Reader);
  end else if FormatVersion >= 1111111121 then begin
    for I := 1 to 24 do Parameters[I].LoadLegacyV4FromReader(Reader);
  end else if FormatVersion >= 1111111119 then begin
    for I := 1 to 24 do Parameters[I].LoadLegacyV3FromReader(Reader);
    // Native appends each current value, including the 24 unused parameters.
    for I := 1 to 48 do Parameters[I].InitialRange.AddValue(Parameters[I].Value);
  end else if FormatVersion >= 1111111118 then begin
    for I := 1 to 12 do Parameters[I].LoadLegacyV2FromReader(Reader);
  end else if FormatVersion >= 1111111115 then begin
    for I := 1 to 12 do Parameters[I].LoadLegacyV1FromReader(Reader);
  end else if FormatVersion >= 1111111113 then begin
    for I := 1 to 9 do Parameters[I].LoadLegacyV1FromReader(Reader);
  end else begin
    for I := 1 to 9 do Parameters[I].LoadLegacyV0FromReader(Reader);
  end;
  ToStarText.LoadTextLinesFromReader(Reader);
  UnresolvedText11C.LoadTextLinesFromReader(Reader);
  UnresolvedText120.LoadTextLinesFromReader(Reader);
  ToPlanetText.LoadTextLinesFromReader(Reader);
  DateText.LoadTextLinesFromReader(Reader);
  MoneyText.LoadTextLinesFromReader(Reader);
  FromPlanetText.LoadTextLinesFromReader(Reader);
  FromStarText.LoadTextLinesFromReader(Reader);
  RangerText.LoadTextLinesFromReader(Reader);
  LocationCount := Reader.GetInt32;
  PathCount := Reader.GetInt32;
  SetLength(Locations, LocationCount + 1);
  SetLength(Paths, PathCount + 1);
  for I := 1 to LocationCount do Locations[I] := TLocation.Create(0);
  for I := 1 to PathCount do Paths[I] := TPath.Create(0, 0, 0, 0, 1, 0, 1, 0, 1);
  QuestSuccessGovMessageText.LoadTextLinesFromReader(Reader);
  QuestDescriptionText.LoadTextLinesFromReader(Reader);
  UnresolvedText110.LoadTextLinesFromReader(Reader);
  if FormatVersion >= 1111111123 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV6FromReader(Reader);
  end else if FormatVersion >= 1111111121 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV5FromReader(Reader);
  end else if FormatVersion >= 1111111119 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV4FromReader(Reader);
  end else if FormatVersion >= 1111111117 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV3FromReader(Reader);
  end else if FormatVersion >= 1111111116 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV2FromReader(Reader);
  end else if FormatVersion >= 1111111115 then begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV1FromReader(Reader);
  end else begin
    for I := 1 to LocationCount do Locations[I].LoadLegacyV0FromReader(Reader);
  end;
  if FormatVersion  >= 1111111123 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV8FromReader(Reader);
  end else if FormatVersion  >= 1111111122 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV7FromReader(Reader);
  end else if FormatVersion  >= 1111111119 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV6FromReader(Reader);
  end else if FormatVersion  >= 1111111117 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV5FromReader(Reader);
  end else if FormatVersion  >= 1111111116 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV4FromReader(Reader);
  end else if FormatVersion  >= 1111111115 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV3FromReader(Reader);
  end else if FormatVersion  >= 1111111114 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV2FromReader(Reader);
  end else if FormatVersion  >= 1111111112 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV1FromReader(Reader);
  end else if FormatVersion  = 1111111111 then begin
    for I := 1 to PathCount do Paths[I].LoadLegacyV0FromReader(Reader);
  end;
  FormatVersion := 1111111123;
end;
{ @end $5E1B48 }

{ @routine $5E2210 TQuestGameContent_LoadQuest }
procedure TQuestGameContent.LoadQuest(Number: Integer);
var Control: TCBufControlEC; Data: TCBufEC;
begin
  Control := nil;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + IntToStr(Number));
    Data := AcquireOrCreateBuffer(Control);
    LoadFromReader(Data.Buffer);
  finally
    if Control <> nil then begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $5E2210 }

{ @routine $5E2314 TQuestGameContent_FindLocationIndex }
function TQuestGameContent.FindLocationIndex(Id: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 1 to LocationCount do
    if Id = Locations[I].Id then Result := I;
end;
{ @end $5E2314 }

end.

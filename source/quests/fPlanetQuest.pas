unit fPlanetQuest;
// Unit bracket (inferred): CODE 0x0053D224..0x0054356F; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, aArtifact, EC_Buf, Types, aRanger, aQuestCalcParseClass, aQuestParameterDeltaClass, aQuestValueListClass;
type
  TQuestParameterChanges = array[1..48] of TQuestParameterDelta;
  TQuestChoiceEvent = procedure of object;
  TAnswer = record // @size $10
    PathIndex: Integer; // @offset $00
    DisplayOrder: Integer; // @offset $04
    Enabled: Boolean; // @offset $08
    Text: WideString; // @offset $0C
  end;
  ATAnswer = array of TAnswer;
  TAnswerBuffer = array[1..50] of TAnswer;
  SituationDescriptionText = record // @size $08
    Text: WideString; // @offset $00
    Pending: Boolean; // @offset $04
  end;
  TfPlanetQuest = class(TMessageLoopGI) // @size $1D518C
  public
    CurrentPicture: WideString; // @offset $B0
    QuestName: WideString; // @offset $B4
    PlayerDied: Boolean; // @offset $B8
    CurrentDate: WideString; // @offset $BC
    ChoiceCallbacks: array[0..50] of TQuestChoiceEvent; // @offset $C0
    ChoicePathIndexes: array[0..50] of Integer; // @offset $258
    procedure ContinueAlongPath(PathIndex, AutomaticStepCount: Integer); // @addr $540BE0
    function SelectWeightedPath(Choices: ATAnswer; Count: Integer): TAnswer; // @addr $53E670
    function BuildPathChoices(SkipPathChoiceRefresh: Boolean): Integer; // @addr $540D90 Success action is added even when path-choice refresh is skipped.
    procedure AdvanceQuest(AutomaticStepCount: Integer); // @addr $54162C
    procedure SelectQuestPicture; // @addr $53D7A4
    procedure StartLoadedQuest; // @addr $53FD3C
    procedure OnOpen; override; // @addr $542578
    ChoiceEnabled: array[0..50] of Boolean; // @offset $324
    Quest: TQuestGameContent; // @offset $358
    DaysElapsed: Integer; // @offset $35C
    CurrentLocationId: Integer; // @offset $360
    ShowingPathTransition: Boolean; // @offset $364
    ParameterValues: TQuestParameterValues; // @offset $368
    PreviousParameterValues: TQuestParameterValues; // @offset $428
    ParameterVisible: array[1..48] of Boolean; // @offset $4E8
    CriticalMessage: WideString; // @offset $518
    CriticalParameterIndex: Integer; // @offset $51C
    LastPathIndex: Integer; // @offset $520
    Description: SituationDescriptionText; // @offset $524 Native managed-record descriptor $53D24C.
    UnresolvedFlag52C: Boolean; // @offset $52C
    RemainingPathVisits: array[1..400, 1..1200] of Integer; // @offset $530 Native row stride is 4800 bytes.
    MoneyLimitComplement: Cardinal; // @offset $1D5130
    NextChoiceTop: Integer; // @offset $1D5134
    ChoiceCount: Integer; // @offset $1D5138
    VisibleChoiceCallbacks: array[0..8] of TQuestChoiceEvent; // @offset $1D5140
    WaitFinished: Boolean; // @offset $1D5188
    WaitingForContinuation: Boolean; // @offset $1D5189
    function CheckPathFailure(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean; // @addr $53DF28
    function CheckPathSuccess(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean; // @addr $53E05C
    function CheckLocationFailure(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean; // @addr $53E1C8
    function CheckLocationSuccess(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean; // @addr $53E31C
    function HasAvailablePath(LocationIndex, ParameterIndex: Integer; var Values: TQuestParameterValues): Boolean; // @addr $53E164
    function CheckPathConditions(var Values: TQuestParameterValues; PathIndex: Integer): Boolean; // @addr $53E41C
    procedure ApplyParameterVisibility(Changes: TQuestParameterChanges); // @addr $53E954 @ida "void __usercall $name(TfPlanetQuest *Self@<eax>, TQuestParameterChanges *Changes@<edx>);"
    procedure ApplyParameterChanges(var Values: TQuestParameterValues; var Changes: TQuestParameterChanges); // @addr $53E9A4
    function HasLocationContinuation(LocationIndex: Integer): Boolean; // @addr $53EBE8
    function HasNoOutgoingPaths(LocationIndex: Integer): Boolean; // @addr $53EC5C
    function MatchesValueList(Value: Integer; List: TValuesList): Boolean; // @addr $53E5A4
    function MatchesMultipleList(Value: Integer; List: TValuesList): Boolean; // @addr $53E5FC
    function MatchesRequiredBits(Value, RequiredBits: Integer): Boolean; // @addr $53E928
    procedure StartQuestLoop; // @addr $53DAC8
    procedure SetPendingText(Text: WideString); // @addr $53D358
    procedure RefreshMessageText; // @addr $53D438
    function WaitForContinuation: Boolean; // @addr $54252C
    procedure ShowQuestText(Text: WideString; Immediate: Boolean); // @addr $53D4E0
    function GetTextBeforeDelimiter(Text: WideString; Delimiter: WideChar): WideString; // @addr $53D64C
    function GetTextAfterComma(Text: WideString; IgnoredDelimiter: WideChar): WideString; // @addr $53D6FC
    function ExpandParameterExpressions(Text: WideString; ParameterIndex: Integer): WideString; // @addr $53F2AC
    procedure RefreshParameterText; // @addr $541A84
    procedure CompleteQuestSuccess; // @addr $53F988
    procedure AddSuccessAction; // @addr $54010C
    procedure AddFailureAction; // @addr $540308
    procedure CompleteQuestDeath; // @addr $54083C
    procedure CompleteQuestFailure; // @addr $5409D0
    procedure AdvanceGalaxyDay; // @addr $53D338
    procedure LoadQuestById(QuestId: Integer); // @addr $53DBE0
    procedure LoadQuestByName(Name: WideString); // @addr $53DE14
    procedure LoadQuestFromReader(Reader: TBufEC); // @addr $53DF1C
    function ExpandTemplateText(Text: WideString): WideString; // @addr $53ECB8
    procedure SetQuestPicture(Name: WideString); // @addr $543234
    procedure RequestExit(Sender: TObjectGI); // @addr $54336C
    procedure QuestKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $54342C
    procedure SelectMusic; override; // @addr $543470
    procedure SetNamedLabelText(Name, Text: WideString); // @addr $541C70
    procedure ClearChoices; // @addr $541CE4
    procedure ChoiceMouseEnter(Sender: TObjectGI); // @addr $542178
    procedure ChoiceMouseLeave(Sender: TObjectGI); // @addr $5421A4
    procedure DisabledChoiceMouseEnter(Sender: TObjectGI); // @addr $542270
    procedure DisabledChoiceMouseLeave(Sender: TObjectGI); // @addr $5422A0
    procedure AddChoice(Text: WideString; Callback: TQuestChoiceEvent); // @addr $541D68
    procedure AddDisabledChoice(Text: WideString; Callback: TQuestChoiceEvent); // @addr $541F78
    procedure ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5421D4
    procedure FinishChoiceLayout; // @addr $5422CC
    procedure FinishWait; // @addr $542570
    procedure OnClose; override; // @addr $5431C8
    procedure ChoosePath0; // @addr $53F668
    procedure ChoosePath1; // @addr $53F678
    procedure ChoosePath2; // @addr $53F688
    procedure ChoosePath3; // @addr $53F698
    procedure ChoosePath4; // @addr $53F6A8
    procedure ChoosePath5; // @addr $53F6B8
    procedure ChoosePath6; // @addr $53F6C8
    procedure ChoosePath7; // @addr $53F6D8
    procedure ChoosePath8; // @addr $53F6E8
    procedure ChoosePath9; // @addr $53F6F8
    procedure ChoosePath10; // @addr $53F708
    procedure ChoosePath11; // @addr $53F718
    procedure ChoosePath12; // @addr $53F728
    procedure ChoosePath13; // @addr $53F738
    procedure ChoosePath14; // @addr $53F748
    procedure ChoosePath15; // @addr $53F758
    procedure ChoosePath16; // @addr $53F768
    procedure ChoosePath17; // @addr $53F778
    procedure ChoosePath18; // @addr $53F788
    procedure ChoosePath19; // @addr $53F798
    procedure ChoosePath20; // @addr $53F7A8
    procedure ChoosePath21; // @addr $53F7B8
    procedure ChoosePath22; // @addr $53F7C8
    procedure ChoosePath23; // @addr $53F7D8
    procedure ChoosePath24; // @addr $53F7E8
    procedure ChoosePath25; // @addr $53F7F8
    procedure ChoosePath26; // @addr $53F808
    procedure ChoosePath27; // @addr $53F818
    procedure ChoosePath28; // @addr $53F828
    procedure ChoosePath29; // @addr $53F838
    procedure ChoosePath30; // @addr $53F848
    procedure ChoosePath31; // @addr $53F858
    procedure ChoosePath32; // @addr $53F868
    procedure ChoosePath33; // @addr $53F878
    procedure ChoosePath34; // @addr $53F888
    procedure ChoosePath35; // @addr $53F898
    procedure ChoosePath36; // @addr $53F8A8
    procedure ChoosePath37; // @addr $53F8B8
    procedure ChoosePath38; // @addr $53F8C8
    procedure ChoosePath39; // @addr $53F8D8
    procedure ChoosePath40; // @addr $53F8E8
    procedure ChoosePath41; // @addr $53F8F8
    procedure ChoosePath42; // @addr $53F908
    procedure ChoosePath43; // @addr $53F918
    procedure ChoosePath44; // @addr $53F928
    procedure ChoosePath45; // @addr $53F938
    procedure ChoosePath46; // @addr $53F948
    procedure ChoosePath47; // @addr $53F958
    procedure ChoosePath48; // @addr $53F968
    procedure ChoosePath49; // @addr $53F978
    function GetQuestContentHash(QuestId: Integer): WideString; // @addr $53DAD0
  end;

implementation
// @unit-initialization $543568
// @unit-finalization $543538
uses EC_CacheBuf, EC_Cache, EC_Buf, EC_Expression, SysUtils, GR_Main, Globals, GlobalsV, aGalaxy, aPlayer, aPlanet, aConst, aMyFunction, EC_Str, GI_GraphBuf, GI_Main, GI_MessageBox, GR_Music, Windows, GI_PanelScrollBar, GI_Label, Classes, GI_GraphButton, GI_Panel, aRanger, Math, aArtifactPathClass, aItem, fSaveManager, fScore, fHangar, ThreadCalc, aCalc;
var
  ActiveGovernmentQuest: PQuest; // @addr $61CFA4 Direct assignment in OnOpen; consumed by quest outcomes.

{ @routine $53D338 TfPlanetQuest_AdvanceGalaxyDay }
procedure TfPlanetQuest.AdvanceGalaxyDay;
begin
  if not StandaloneQuestMode then
  begin
    WaitForTurnCalculation;
    PruneExpiredPersistentPlayerMessages;
    CalculatePlayerStarTurnAndWait;
    QueueGalaxyTurnCalculation;
  end;
end;
{ @end $53D338 }
{ @routine $53D358 TfPlanetQuest_SetPendingText }
procedure TfPlanetQuest.SetPendingText(Text: WideString);
begin
  Text := TrimWideString(Text);
  Description.Text := Text;
  if (Text = TrimWideString((GetByName('MessageText') as TLabelGI).GetText)) or (Text = '') then
    Description.Pending := False
  else Description.Pending := True;
end;
{ @end $53D358 }
{ @routine $53D438 TfPlanetQuest_RefreshMessageText }
procedure TfPlanetQuest.RefreshMessageText;
begin
  if Description.Text <> TrimWideString((GetByName('MessageText') as TLabelGI).GetText) then
    SetNamedLabelText('MessageText', Description.Text);
end;
{ @end $53D438 }
{ @routine $53D4E0 TfPlanetQuest_ShowQuestText }
procedure TfPlanetQuest.ShowQuestText(Text: WideString; Immediate: Boolean);
begin
  Text := TrimWideString(Text);
  UnresolvedFlag52C := False;
  if Immediate or (Description.Text = Text) then Description.Pending := False;
  if Description.Pending then
  begin
    UnresolvedFlag52C := False;
    ClearChoices;
    if not WaitingForContinuation then
    begin
      ClearChoices;
      AddChoice('  - ' + LocalizedText('Planet.NotCivil.QuestPlay.MsgContinue'), FinishWait);
      FinishChoiceLayout;
      WaitMessage;
      if WaitForContinuation then BreakUiMessage;
    end;
  end;
  SetPendingText(Text);
  RefreshMessageText;
end;
{ @end $53D4E0 }
{ @routine $53D64C TfPlanetQuest_GetTextBeforeDelimiter }
function TfPlanetQuest.GetTextBeforeDelimiter(Text: WideString; Delimiter: WideChar): WideString;
var
  I, N: Integer;
  S: WideString;
begin
  S := '';
  N := Length(Text);
  for I := 1 to N do
  begin
    if Text[I] = Delimiter then Break;
    S := S + Text[I];
  end;
  Result := S;
end;
{ @end $53D64C }
{ @routine $53D6FC TfPlanetQuest_GetTextAfterComma }
function TfPlanetQuest.GetTextAfterComma(Text: WideString; IgnoredDelimiter: WideChar): WideString;
var
  I, N: Integer;
  S: WideString;
begin
  S := '';
  N := Length(Text);
  if N <> 0 then
  begin
    I := 1;
    // Native ignores IgnoredDelimiter and scans beyond Text if no comma exists.
    while Text[I] <> ',' do Inc(I);
    Inc(I);
    while I <= N do
    begin
      S := S + Text[I];
      Inc(I);
    end;
  end;
  Result := S;
end;
{ @end $53D6FC }
{ @routine $53D7A4 TfPlanetQuest_SelectQuestPicture }
procedure TfPlanetQuest.SelectQuestPicture;
var LocationMatch, PathMatch, ParameterMatch, I, J: Integer;
  Kind, Indices, Name: WideString;
  Values: TValuesList;
begin
  Values := TValuesList.Create;
  LocationMatch := -1;
  PathMatch := -1;
  ParameterMatch := -1;
  for I := 0 to GameDataConfig.GetBlock('PQI').GetParamCount - 1 do
  begin
    Name := GameDataConfig.GetBlock('PQI').GetParamName(I);
    if GetTextBeforeDelimiter(Name, ',') = QuestName then
    begin
      Kind := GetTextAfterComma(Name, ',');
      Indices := GetTextAfterComma(Kind, ',');
      Kind := GetTextBeforeDelimiter(Kind, ',');
      Values.LoadFromSemicolonText(Indices);
      if Kind = 'L' then
        for J := 1 to Values.Count do
          if Values.Values[J] = CurrentLocationId then LocationMatch := I;
      if Kind = 'P' then
        for J := 1 to Values.Count do
          if LastPathIndex > 0 then
            if Values.Values[J] = Quest.Paths[LastPathIndex].Id then PathMatch := I;
      if Kind = 'PAR' then
        for J := 1 to Values.Count do
          if Values.Values[J] = CriticalParameterIndex then ParameterMatch := I;
    end;
  end;
  Values.Destroy;
  Kind := '';
  if ParameterMatch <> -1 then Kind := GameDataConfig.GetBlock('PQI').GetParamName(ParameterMatch)
  else if (PathMatch <> -1) and ShowingPathTransition then Kind := GameDataConfig.GetBlock('PQI').GetParamName(PathMatch)
  else if (LocationMatch <> -1) and not ShowingPathTransition then Kind := GameDataConfig.GetBlock('PQI').GetParamName(LocationMatch);
  if Kind <> '' then SetQuestPicture(GameDataConfig.GetParamByPath('PQI.' + Kind));
end;
{ @end $53D7A4 }
{ @routine $53DAC8 TfPlanetQuest_StartQuestLoop }
procedure TfPlanetQuest.StartQuestLoop;
begin
  AdvanceQuest(0);
end;
{ @end $53DAC8 }
{ @routine $53DAD0 TfPlanetQuest_GetQuestContentHash }
function TfPlanetQuest.GetQuestContentHash(QuestId: Integer): WideString;
var
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  Control := nil;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + IntToStr(QuestId));
    Data := AcquireOrCreateBuffer(Control);
    Result := ScriptDwordToHex(Data.Buffer.ComputeCrc32 xor $FFFFFFFF);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $53DAD0 }

{ @routine $53DBE0 TfPlanetQuest_LoadQuestById }
procedure TfPlanetQuest.LoadQuestById(QuestId: Integer);
var Control: TCBufControlEC; Data: TCBufEC;
begin
  Control := nil;
  QuestName := IntToStr(QuestId);
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + IntToStr(QuestId));
    Data := AcquireOrCreateBuffer(Control);
    LoadQuestFromReader(Data.Buffer);
    if not StandaloneQuestMode and (QuestId >= 10000) then
      if (LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') <= 0) or
        (LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuestLic').GetParamOrMarker(IntToStr(QuestId)) <>
          ScriptDwordToHex(Data.Buffer.ComputeCrc32 xor $FFFFFFFF)) then
        Galaxy.MoneyIntegrityFailed := True;
  finally
    if Control <> nil then begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $53DBE0 }

{ @routine $53DE14 TfPlanetQuest_LoadQuestByName }
procedure TfPlanetQuest.LoadQuestByName(Name: WideString);
var Control: TCBufControlEC; Data: TCBufEC;
begin
  Control := nil;
  QuestName := Name;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey('PlanetQuest.' + Name);
    Data := AcquireOrCreateBuffer(Control);
    LoadQuestFromReader(Data.Buffer);
  finally
    if Control <> nil then begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $53DE14 }

{ @routine $53DF1C TfPlanetQuest_LoadQuestFromReader }
procedure TfPlanetQuest.LoadQuestFromReader(Reader: TBufEC);

begin
  Quest.LoadFromReader(Reader);
end;
{ @end $53DF1C }

{ @routine $53DF28 TfPlanetQuest_CheckPathFailure }
function TfPlanetQuest.CheckPathFailure(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean;
var I: Integer; Found: Boolean;
begin
  Found := False;
  if Index > 0 then
  for I := 1 to 48 do
    if (PreviousValues[I] <> Values[I]) and
      ((Quest.Parameters[I].CriticalOutcome = qoFailure) or (Quest.Parameters[I].CriticalOutcome = qoDeath)) and
      ((Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MinValue >= Values[I])) or
       (not Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MaxValue <= Values[I]))) then
    begin
      Found := True;
      CriticalMessage := TrimWideString(Quest.Paths[Index].ParameterChanges[I].CriticalText.Text);
      CriticalParameterIndex := I;
      if Quest.Parameters[I].CriticalOutcome = qoDeath then PlayerDied := True;
      Break;
    end;
  Result := Found;
end;
{ @end $53DF28 }

{ @routine $53E05C TfPlanetQuest_CheckPathSuccess }
function TfPlanetQuest.CheckPathSuccess(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean;
var I: Integer; Found: Boolean;
begin
  Found := False;
  if Index > 0 then
  for I := 1 to 48 do
    if (PreviousValues[I] <> Values[I]) and
      (Quest.Parameters[I].CriticalOutcome = qoSuccess) and
      ((Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MinValue >= Values[I])) or
       (not Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MaxValue <= Values[I]))) then
    begin
      Found := True;
      CriticalMessage := TrimWideString(Quest.Paths[Index].ParameterChanges[I].CriticalText.Text);
      CriticalParameterIndex := I;
      Break;
    end;
  Result := Found;
end;
{ @end $53E05C }

{ @routine $53E164 TfPlanetQuest_HasAvailablePath }
function TfPlanetQuest.HasAvailablePath(LocationIndex, ParameterIndex: Integer; var Values: TQuestParameterValues): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 1 to Quest.PathCount do
    if (RemainingPathVisits[LocationIndex, I] >= 1) and CheckPathConditions(Values, I) then
    begin
      Result := True;
      Break;
    end;
end;
{ @end $53E164 }

{ @routine $53E1C8 TfPlanetQuest_CheckLocationFailure }
function TfPlanetQuest.CheckLocationFailure(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean;
var I: Integer; Found: Boolean;
begin
  Found := False;
  for I := 1 to 48 do
    if (PreviousValues[I] <> Values[I]) and not HasAvailablePath(Index, I, Values) and
      ((Quest.Parameters[I].CriticalOutcome = qoFailure) or (Quest.Parameters[I].CriticalOutcome = qoDeath)) and
      ((Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MinValue >= Values[I])) or
       (not Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MaxValue <= Values[I]))) then
    begin
      Found := True;
      CriticalMessage := TrimWideString(Quest.Locations[Index].ParameterChanges[I].CriticalText.Text);
      CriticalParameterIndex := I;
      if Quest.Parameters[I].CriticalOutcome = qoDeath then PlayerDied := True;
      Break;
    end;
  Result := Found;
end;
{ @end $53E1C8 }

{ @routine $53E31C TfPlanetQuest_CheckLocationSuccess }
function TfPlanetQuest.CheckLocationSuccess(Index: Integer; var Values, PreviousValues: TQuestParameterValues): Boolean;
var I: Integer; Found: Boolean;
begin
  Found := False;
  for I := 1 to 48 do
    if (PreviousValues[I] <> Values[I]) and
      (Quest.Parameters[I].CriticalOutcome = qoSuccess) and
      ((Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MinValue >= Values[I])) or
       (not Quest.Parameters[I].CriticalAtMinimum and (Quest.Parameters[I].MaxValue <= Values[I]))) then
    begin
      Found := True;
      CriticalMessage := TrimWideString(Quest.Locations[Index].ParameterChanges[I].CriticalText.Text);
      CriticalParameterIndex := I;
      Break;
    end;
  Result := Found;
end;
{ @end $53E31C }

{ @routine $53E41C TfPlanetQuest_CheckPathConditions }
function TfPlanetQuest.CheckPathConditions(var Values: TQuestParameterValues; PathIndex: Integer): Boolean;
var I: Integer; Found: Boolean; Text: AnsiString; Parser: TQuestCalcParse; Path: TPath;
begin
  Found := True;
  Path := Quest.Paths[PathIndex];
  Text := TrimWideString(Path.ConditionExpression.Text);
  if Text <> '' then
  begin
    Parser := TQuestCalcParse.Create;
    Parser.Expression := Parser.NormalizeTokens(Text);
    if not Parser.UsesDefaultParameter and not Parser.HasError then
    begin
      Parser.Evaluate(Values);
      if not Parser.EvaluationError and (Parser.ResultValue = 0) then Found := False;
    end;
    Parser.Destroy;
  end;
  for I := 1 to 48 do
    if Quest.Parameters[I].Enabled then
    begin
      if Path.ParameterChanges[I].MaxValue < Values[I] then begin Found := False; Break; end;
      if Path.ParameterChanges[I].MinValue > Values[I] then begin Found := False; Break; end;
      if not MatchesRequiredBits(Values[I], Path.ParameterChanges[I].RequiredBits) then begin Found := False; Break; end;
      if not MatchesValueList(Values[I], Path.ParameterChanges[I].ValueConstraint) then begin Found := False; Break; end;
      if not MatchesMultipleList(Values[I], Path.ParameterChanges[I].MultipleConstraint) then begin Found := False; Break; end;
    end;
  Result := Found;
end;
{ @end $53E41C }

{ @routine $53E5A4 TfPlanetQuest_MatchesValueList }
function TfPlanetQuest.MatchesValueList(Value: Integer; List: TValuesList): Boolean;
var I: Integer;
begin
  if not List.AcceptListed then
  begin
    Result := True;
    for I := 1 to List.Count do
      if Value = List.Values[I] then begin Result := False; Break; end;
  end
  else
  begin
    Result := False;
    for I := 1 to List.Count do
      if Value = List.Values[I] then begin Result := True; Break; end;
  end;
  if List.Count = 0 then Result := True;
end;
{ @end $53E5A4 }

{ @routine $53E5FC TfPlanetQuest_MatchesMultipleList }
function TfPlanetQuest.MatchesMultipleList(Value: Integer; List: TValuesList): Boolean;
var I: Integer;
begin
  if not List.AcceptListed then
  begin
    Result := True;
    for I := 1 to List.Count do
    begin
      if Value mod List.Values[I] <> 0 then Continue;
      Result := False;
      Break;
    end;
  end
  else
  begin
    Result := False;
    for I := 1 to List.Count do
    begin
      if Value mod List.Values[I] <> 0 then Continue;
      Result := True;
      Break;
    end;
  end;
  if List.Count = 0 then Result := True;
end;
{ @end $53E5FC }

{ @routine $53E670 TfPlanetQuest_SelectWeightedPath }
function TfPlanetQuest.SelectWeightedPath(Choices: ATAnswer; Count: Integer): TAnswer;
var
  I, FilteredCount, TotalWeight, RandomWeight, AccumulatedWeight, DieRoll, PriorityThreshold: Integer;
  NoEnabledChoices: Boolean;
  Selected: TAnswer;
  Filtered: TAnswerBuffer;
  Weights: array[1..50] of Integer;
begin
  Selected.PathIndex := -1;
  if (Count = 1) and (((not Choices[1].Enabled) and Quest.Paths[Choices[1].PathIndex].AlwaysShow) or Choices[1].Enabled) then begin
    if Quest.Paths[Choices[1].PathIndex].Priority < 1 then begin
      DieRoll := Random(1000);
      PriorityThreshold := Trunc(Quest.Paths[Choices[1].PathIndex].Priority * 1000);
      if DieRoll <= PriorityThreshold then
        Selected := Choices[1]
      else Selected.PathIndex := -1;
    end else Selected := Choices[1];
  end else begin
    FilteredCount := 0;
    NoEnabledChoices := True;
    for I := 1 to Count do
      if Choices[I].Enabled then NoEnabledChoices := False;
    for I := 1 to Count do
      if Choices[I].Enabled or (NoEnabledChoices and Quest.Paths[Choices[I].PathIndex].AlwaysShow) then begin
        Inc(FilteredCount);
        Filtered[FilteredCount] := Choices[I];
      end;
    TotalWeight := 0;
    for I := 1 to FilteredCount do begin
      Weights[I] := Round(Quest.Paths[Filtered[I].PathIndex].Priority * 1000);
      TotalWeight := TotalWeight + Weights[I];
    end;
    RandomWeight := Random(TotalWeight);
    AccumulatedWeight := 0;
    for TotalWeight := 1 to FilteredCount do begin
      if Weights[TotalWeight] + AccumulatedWeight > RandomWeight then begin
        Selected := Filtered[TotalWeight];
        Break;
      end;
      AccumulatedWeight := AccumulatedWeight + Weights[TotalWeight];
    end;
  end;
  Result := Selected;
end;
{ @end $53E670 }

{ @routine $53E928 TfPlanetQuest_MatchesRequiredBits }
function TfPlanetQuest.MatchesRequiredBits(Value, RequiredBits: Integer): Boolean;
var I: Integer;
begin
  Result := True;
  I := 1;
  repeat
    if (Value and 1 = 0) and (RequiredBits and 1 = 1) then begin Result := False; Break; end;
    Value := Value shr 1;
    RequiredBits := RequiredBits shr 1;
    Inc(I);
  until I = 10;
end;
{ @end $53E928 }

{ @routine $53E954 TfPlanetQuest_ApplyParameterVisibility }
procedure TfPlanetQuest.ApplyParameterVisibility(Changes: TQuestParameterChanges);
var I: Integer;
begin
  for I := 1 to 48 do
  begin
    if Changes[I].VisibilityChange = pvcHide then ParameterVisible[I] := False;
    if Changes[I].VisibilityChange = pvcShow then ParameterVisible[I] := True;
  end;
end;
{ @end $53E954 }

{ @routine $53E9A4 TfPlanetQuest_ApplyParameterChanges }
procedure TfPlanetQuest.ApplyParameterChanges(var Values: TQuestParameterValues; var Changes: TQuestParameterChanges);
var I: Integer; Parser: TQuestCalcParse; Text: AnsiString; NewValues: TQuestParameterValues;
begin
  for I := 1 to 48 do
    if Quest.Parameters[I].Enabled then
    begin
      Text := TrimWideString(Changes[I].ExpressionText.Text);
      if Changes[I].UseExpression then
      begin
        if Text <> '' then
        begin
          Parser := TQuestCalcParse.Create;
          Parser.Expression := Parser.NormalizeTokens(Text);
          Parser.Evaluate(Values);
          // Native leaves NewValues[I] uninitialized when expression evaluation fails.
          if not Parser.HasError then NewValues[I] := Parser.ResultValue;
          Parser.Destroy;
        end
        else NewValues[I] := Values[I];
      end
      else if Changes[I].SetValue then NewValues[I] := Changes[I].ChangeValue
      else if Changes[I].ChangeByPercent then NewValues[I] := Values[I] + Round(Values[I] / 100 * Changes[I].ChangeValue)
      else NewValues[I] := Values[I] + Changes[I].ChangeValue;
      if Quest.Parameters[I].IsMoney then
      begin
        if NewValues[I] < 0 then NewValues[I] := 0;
      end
      else
      begin
        if Quest.Parameters[I].MaxValue < NewValues[I] then NewValues[I] := Quest.Parameters[I].MaxValue;
        if Quest.Parameters[I].MinValue > NewValues[I] then NewValues[I] := Quest.Parameters[I].MinValue;
      end;
    end;
  for I := 1 to 48 do
    if Quest.Parameters[I].Enabled then Values[I] := NewValues[I];
  for I := 1 to 48 do
    if Quest.Parameters[I].IsMoney and not StandaloneQuestMode then Player.SetMoney(ParameterValues[I]);
end;
{ @end $53E9A4 }

{ @routine $53EBE8 TfPlanetQuest_HasLocationContinuation }
function TfPlanetQuest.HasLocationContinuation(LocationIndex: Integer): Boolean;
var I: Integer;
begin
  if Quest.Locations[LocationIndex].IsSuccess or Quest.Locations[LocationIndex].IsFailure then begin Result := True; Exit; end;
  if HasNoOutgoingPaths(LocationIndex) then begin Result := True; Exit; end;
  for I := 1 to Quest.PathCount do
    if RemainingPathVisits[LocationIndex, I] >= 1 then begin Result := True; Exit; end;
  Result := False;
end;
{ @end $53EBE8 }

{ @routine $53EC5C TfPlanetQuest_HasNoOutgoingPaths }
function TfPlanetQuest.HasNoOutgoingPaths(LocationIndex: Integer): Boolean;
var I: Integer;
begin
  Result := True;
  for I := 1 to Quest.PathCount do
    if Quest.Paths[I].FromLocationId = Quest.Locations[LocationIndex].Id then
    begin Result := False; Break; end;
end;
{ @end $53EC5C }

{ @routine $53ECB8 TfPlanetQuest_ExpandTemplateText }
function TfPlanetQuest.ExpandTemplateText(Text: WideString): WideString;
var
  Expanded, SourceLineBreak, ReplacementLineBreak, IndentedLineBreak: WideString;

begin
  if Player = nil then CurrentDate := TrimWideString(Galaxy.FormatTurnDate(200))
  else CurrentDate := TrimWideString(Galaxy.FormatTurnDate(Galaxy.CurrentTurn));
  Expanded := Text;
  SourceLineBreak := #13#10;
  ReplacementLineBreak := #13#10'     ';
  IndentedLineBreak := #13#10'          ';
  Expanded := ReplaceAllWideString(Text, '<ToStar>', WrapTextInColor(TrimWideString(Quest.ToStarText.Text), HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<ToPlanet>', WrapTextInColor(TrimWideString(Quest.ToPlanetText.Text), HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<Date>', WrapTextInColor(Quest.DateText.Text, HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<Money>', WrapTextInColor(Quest.MoneyText.Text, HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<FromPlanet>', WrapTextInColor(TrimWideString(Quest.FromPlanetText.Text), HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<FromStar>', WrapTextInColor(TrimWideString(Quest.FromStarText.Text), HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<Ranger>', WrapTextInColor(TrimWideString(Quest.RangerText.Text), HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, '<CurDate>', WrapTextInColor(CurrentDate, HighlightColorTag));
  Expanded := ReplaceAllWideString(Expanded, SourceLineBreak, ReplacementLineBreak);
  Expanded := ReplaceAllWideString(Expanded, IndentedLineBreak, ReplacementLineBreak);
  if Pos('<', Expanded) > 0 then
  begin
    Expanded := ReplaceAllWideString(Expanded, '<br>', #13#10);
    Expanded := ReplaceAllWideString(Expanded, '<ll>', #13#10' '#13#10);
    // Native expands <Player> into Result, then overwrites it below.
    if Player <> nil then
      Result := ReplaceAllWideString(Result, '<Player>', WrapTextInColor(Player.Name, HighlightColorTag));
    Expanded := ReplaceAllWideString(Expanded, '<clr>', HighlightColorTag);
    Expanded := ReplaceAllWideString(Expanded, '<clrEnd>', ColorEndTag);
  end;
  Result := Expanded;
end;
{ @end $53ECB8 }

{ @routine $53F2AC TfPlanetQuest_ExpandParameterExpressions }
function TfPlanetQuest.ExpandParameterExpressions(Text: WideString; ParameterIndex: Integer): WideString;
var I, N: Integer; Expanded, Expression: WideString; Parser: TQuestCalcParse;
begin
  Text := ExpandTemplateText(Text);
  Parser := TQuestCalcParse.Create;
  Expanded := '';
  I := 1;
  N := Length(Text);
  while I <= N do
  begin
    if Text[I] <> '{' then
    begin
      Expanded := Expanded + Text[I];
      Inc(I);
    end
    else
    begin
      Inc(I);
      Expression := '';
      while (I <= N) and (Text[I] <> '}') do
      begin
        Expression := Expression + Text[I];
        Inc(I);
      end;
      if Expression <> '' then
      begin
        Expression := ReplaceAllWideString(Expression, '<>', IntToStr(ParameterValues[ParameterIndex]));
        Parser.Reset;
        Parser.Prepare(Expression, 1);
        if not Parser.HasError and not Parser.UsesDefaultParameter then
        begin
          Parser.Evaluate(ParameterValues);
          if not Parser.HasError then
            Expanded := Expanded + HighlightColorTag + IntToStr(Parser.ResultValue) + ColorEndTag
          else Expanded := Expanded + '{' + Expression;
        end
        else Expanded := Expanded + '{' + Expression;
      end;
      Inc(I);
    end;
  end;
  Text := Expanded;
  for I := 1 to 48 do
    Text := ReplaceAllWideString(Text, '[p' + IntToStr(I) + ']', HighlightColorTag + IntToStr(ParameterValues[I]) + ColorEndTag);
  // The native routine does not destroy Parser.
  Result := Text;
end;
{ @end $53F2AC }

{ @routine $53F668 TfPlanetQuest_ChoosePath0 }
procedure TfPlanetQuest.ChoosePath0;

begin
  ContinueAlongPath(ChoicePathIndexes[0], 0);
end;
{ @end $53F668 }

{ @routine $53F678 TfPlanetQuest_ChoosePath1 }
procedure TfPlanetQuest.ChoosePath1;

begin
  ContinueAlongPath(ChoicePathIndexes[1], 0);
end;
{ @end $53F678 }

{ @routine $53F688 TfPlanetQuest_ChoosePath2 }
procedure TfPlanetQuest.ChoosePath2;

begin
  ContinueAlongPath(ChoicePathIndexes[2], 0);
end;
{ @end $53F688 }

{ @routine $53F698 TfPlanetQuest_ChoosePath3 }
procedure TfPlanetQuest.ChoosePath3;

begin
  ContinueAlongPath(ChoicePathIndexes[3], 0);
end;
{ @end $53F698 }

{ @routine $53F6A8 TfPlanetQuest_ChoosePath4 }
procedure TfPlanetQuest.ChoosePath4;

begin
  ContinueAlongPath(ChoicePathIndexes[4], 0);
end;
{ @end $53F6A8 }

{ @routine $53F6B8 TfPlanetQuest_ChoosePath5 }
procedure TfPlanetQuest.ChoosePath5;

begin
  ContinueAlongPath(ChoicePathIndexes[5], 0);
end;
{ @end $53F6B8 }

{ @routine $53F6C8 TfPlanetQuest_ChoosePath6 }
procedure TfPlanetQuest.ChoosePath6;

begin
  ContinueAlongPath(ChoicePathIndexes[6], 0);
end;
{ @end $53F6C8 }

{ @routine $53F6D8 TfPlanetQuest_ChoosePath7 }
procedure TfPlanetQuest.ChoosePath7;

begin
  ContinueAlongPath(ChoicePathIndexes[7], 0);
end;
{ @end $53F6D8 }

{ @routine $53F6E8 TfPlanetQuest_ChoosePath8 }
procedure TfPlanetQuest.ChoosePath8;

begin
  ContinueAlongPath(ChoicePathIndexes[8], 0);
end;
{ @end $53F6E8 }

{ @routine $53F6F8 TfPlanetQuest_ChoosePath9 }
procedure TfPlanetQuest.ChoosePath9;

begin
  ContinueAlongPath(ChoicePathIndexes[9], 0);
end;
{ @end $53F6F8 }

{ @routine $53F708 TfPlanetQuest_ChoosePath10 }
procedure TfPlanetQuest.ChoosePath10;

begin
  ContinueAlongPath(ChoicePathIndexes[10], 0);
end;
{ @end $53F708 }

{ @routine $53F718 TfPlanetQuest_ChoosePath11 }
procedure TfPlanetQuest.ChoosePath11;

begin
  ContinueAlongPath(ChoicePathIndexes[11], 0);
end;
{ @end $53F718 }

{ @routine $53F728 TfPlanetQuest_ChoosePath12 }
procedure TfPlanetQuest.ChoosePath12;

begin
  ContinueAlongPath(ChoicePathIndexes[12], 0);
end;
{ @end $53F728 }

{ @routine $53F738 TfPlanetQuest_ChoosePath13 }
procedure TfPlanetQuest.ChoosePath13;

begin
  ContinueAlongPath(ChoicePathIndexes[13], 0);
end;
{ @end $53F738 }

{ @routine $53F748 TfPlanetQuest_ChoosePath14 }
procedure TfPlanetQuest.ChoosePath14;

begin
  ContinueAlongPath(ChoicePathIndexes[14], 0);
end;
{ @end $53F748 }

{ @routine $53F758 TfPlanetQuest_ChoosePath15 }
procedure TfPlanetQuest.ChoosePath15;

begin
  ContinueAlongPath(ChoicePathIndexes[15], 0);
end;
{ @end $53F758 }

{ @routine $53F768 TfPlanetQuest_ChoosePath16 }
procedure TfPlanetQuest.ChoosePath16;

begin
  ContinueAlongPath(ChoicePathIndexes[16], 0);
end;
{ @end $53F768 }

{ @routine $53F778 TfPlanetQuest_ChoosePath17 }
procedure TfPlanetQuest.ChoosePath17;

begin
  ContinueAlongPath(ChoicePathIndexes[17], 0);
end;
{ @end $53F778 }

{ @routine $53F788 TfPlanetQuest_ChoosePath18 }
procedure TfPlanetQuest.ChoosePath18;

begin
  ContinueAlongPath(ChoicePathIndexes[18], 0);
end;
{ @end $53F788 }

{ @routine $53F798 TfPlanetQuest_ChoosePath19 }
procedure TfPlanetQuest.ChoosePath19;

begin
  ContinueAlongPath(ChoicePathIndexes[19], 0);
end;
{ @end $53F798 }

{ @routine $53F7A8 TfPlanetQuest_ChoosePath20 }
procedure TfPlanetQuest.ChoosePath20;

begin
  ContinueAlongPath(ChoicePathIndexes[20], 0);
end;
{ @end $53F7A8 }

{ @routine $53F7B8 TfPlanetQuest_ChoosePath21 }
procedure TfPlanetQuest.ChoosePath21;

begin
  ContinueAlongPath(ChoicePathIndexes[21], 0);
end;
{ @end $53F7B8 }

{ @routine $53F7C8 TfPlanetQuest_ChoosePath22 }
procedure TfPlanetQuest.ChoosePath22;

begin
  ContinueAlongPath(ChoicePathIndexes[22], 0);
end;
{ @end $53F7C8 }

{ @routine $53F7D8 TfPlanetQuest_ChoosePath23 }
procedure TfPlanetQuest.ChoosePath23;

begin
  ContinueAlongPath(ChoicePathIndexes[23], 0);
end;
{ @end $53F7D8 }

{ @routine $53F7E8 TfPlanetQuest_ChoosePath24 }
procedure TfPlanetQuest.ChoosePath24;

begin
  ContinueAlongPath(ChoicePathIndexes[24], 0);
end;
{ @end $53F7E8 }

{ @routine $53F7F8 TfPlanetQuest_ChoosePath25 }
procedure TfPlanetQuest.ChoosePath25;

begin
  ContinueAlongPath(ChoicePathIndexes[25], 0);
end;
{ @end $53F7F8 }

{ @routine $53F808 TfPlanetQuest_ChoosePath26 }
procedure TfPlanetQuest.ChoosePath26;

begin
  ContinueAlongPath(ChoicePathIndexes[26], 0);
end;
{ @end $53F808 }

{ @routine $53F818 TfPlanetQuest_ChoosePath27 }
procedure TfPlanetQuest.ChoosePath27;

begin
  ContinueAlongPath(ChoicePathIndexes[27], 0);
end;
{ @end $53F818 }

{ @routine $53F828 TfPlanetQuest_ChoosePath28 }
procedure TfPlanetQuest.ChoosePath28;

begin
  ContinueAlongPath(ChoicePathIndexes[28], 0);
end;
{ @end $53F828 }

{ @routine $53F838 TfPlanetQuest_ChoosePath29 }
procedure TfPlanetQuest.ChoosePath29;

begin
  ContinueAlongPath(ChoicePathIndexes[29], 0);
end;
{ @end $53F838 }

{ @routine $53F848 TfPlanetQuest_ChoosePath30 }
procedure TfPlanetQuest.ChoosePath30;

begin
  ContinueAlongPath(ChoicePathIndexes[30], 0);
end;
{ @end $53F848 }

{ @routine $53F858 TfPlanetQuest_ChoosePath31 }
procedure TfPlanetQuest.ChoosePath31;

begin
  ContinueAlongPath(ChoicePathIndexes[31], 0);
end;
{ @end $53F858 }

{ @routine $53F868 TfPlanetQuest_ChoosePath32 }
procedure TfPlanetQuest.ChoosePath32;

begin
  ContinueAlongPath(ChoicePathIndexes[32], 0);
end;
{ @end $53F868 }

{ @routine $53F878 TfPlanetQuest_ChoosePath33 }
procedure TfPlanetQuest.ChoosePath33;

begin
  ContinueAlongPath(ChoicePathIndexes[33], 0);
end;
{ @end $53F878 }

{ @routine $53F888 TfPlanetQuest_ChoosePath34 }
procedure TfPlanetQuest.ChoosePath34;

begin
  ContinueAlongPath(ChoicePathIndexes[34], 0);
end;
{ @end $53F888 }

{ @routine $53F898 TfPlanetQuest_ChoosePath35 }
procedure TfPlanetQuest.ChoosePath35;

begin
  ContinueAlongPath(ChoicePathIndexes[35], 0);
end;
{ @end $53F898 }

{ @routine $53F8A8 TfPlanetQuest_ChoosePath36 }
procedure TfPlanetQuest.ChoosePath36;

begin
  ContinueAlongPath(ChoicePathIndexes[36], 0);
end;
{ @end $53F8A8 }

{ @routine $53F8B8 TfPlanetQuest_ChoosePath37 }
procedure TfPlanetQuest.ChoosePath37;

begin
  ContinueAlongPath(ChoicePathIndexes[37], 0);
end;
{ @end $53F8B8 }

{ @routine $53F8C8 TfPlanetQuest_ChoosePath38 }
procedure TfPlanetQuest.ChoosePath38;

begin
  ContinueAlongPath(ChoicePathIndexes[38], 0);
end;
{ @end $53F8C8 }

{ @routine $53F8D8 TfPlanetQuest_ChoosePath39 }
procedure TfPlanetQuest.ChoosePath39;

begin
  ContinueAlongPath(ChoicePathIndexes[39], 0);
end;
{ @end $53F8D8 }

{ @routine $53F8E8 TfPlanetQuest_ChoosePath40 }
procedure TfPlanetQuest.ChoosePath40;

begin
  ContinueAlongPath(ChoicePathIndexes[40], 0);
end;
{ @end $53F8E8 }

{ @routine $53F8F8 TfPlanetQuest_ChoosePath41 }
procedure TfPlanetQuest.ChoosePath41;

begin
  ContinueAlongPath(ChoicePathIndexes[41], 0);
end;
{ @end $53F8F8 }

{ @routine $53F908 TfPlanetQuest_ChoosePath42 }
procedure TfPlanetQuest.ChoosePath42;

begin
  ContinueAlongPath(ChoicePathIndexes[42], 0);
end;
{ @end $53F908 }
{ @routine $53F918 TfPlanetQuest_ChoosePath43 }
procedure TfPlanetQuest.ChoosePath43;

begin
  ContinueAlongPath(ChoicePathIndexes[43], 0);
end;
{ @end $53F918 }

{ @routine $53F928 TfPlanetQuest_ChoosePath44 }
procedure TfPlanetQuest.ChoosePath44;

begin
  ContinueAlongPath(ChoicePathIndexes[44], 0);
end;
{ @end $53F928 }

{ @routine $53F938 TfPlanetQuest_ChoosePath45 }
procedure TfPlanetQuest.ChoosePath45;

begin
  ContinueAlongPath(ChoicePathIndexes[45], 0);
end;
{ @end $53F938 }

{ @routine $53F948 TfPlanetQuest_ChoosePath46 }
procedure TfPlanetQuest.ChoosePath46;

begin
  ContinueAlongPath(ChoicePathIndexes[46], 0);
end;
{ @end $53F948 }

{ @routine $53F958 TfPlanetQuest_ChoosePath47 }
procedure TfPlanetQuest.ChoosePath47;

begin
  ContinueAlongPath(ChoicePathIndexes[47], 0);
end;
{ @end $53F958 }

{ @routine $53F968 TfPlanetQuest_ChoosePath48 }
procedure TfPlanetQuest.ChoosePath48;

begin
  ContinueAlongPath(ChoicePathIndexes[48], 0);
end;
{ @end $53F968 }

{ @routine $53F978 TfPlanetQuest_ChoosePath49 }
procedure TfPlanetQuest.ChoosePath49;

begin
  ContinueAlongPath(ChoicePathIndexes[49], 0);
end;
{ @end $53F978 }

{ @routine $53F988 TfPlanetQuest_CompleteQuestSuccess }
procedure TfPlanetQuest.CompleteQuestSuccess;
var
  I: Integer;
  GovernmentQuest: PQuest;
  LoadedQuest: TQuestGameContent;
  Item: TUselessItem;
  News, ItemName: WideString;

begin
  ClearChoices;
  if (Player <> nil) and not Player.InPrison and (Player.Quests.Count > 0) then
    for I := 0 to Player.Quests.Count - 1 do
    begin
      GovernmentQuest := Player.Quests[I];
      if (GovernmentQuest.QuestType = qtPlanetQuest) and
        (GovernmentQuest.ObjectiveTarget is TPlanet) and
        ((GovernmentQuest.ObjectiveTarget as TPlanet) = Player.CurrentPlanet) then
      begin
        LoadedQuest := TQuestGameContent.Create;
        LoadedQuest.LoadQuest(GovernmentQuest.QuestNumber);
        if LoadedQuest.CompleteOnFinish then
        begin
          GovernmentQuest.Successful := True;
          News := PickLocalizedTextVariant('GalaxyNews.Quest.Successful.PlanetaryQuest', (Galaxy.CurrentTurn div 10) * Integer(Galaxy.GenerationSeed));
          ReplaceTextToken(News, '<FromPlanet>', GovernmentQuest.Planet.Name, '');
          ReplaceTextToken(News, '<ToPlanet>', Player.CurrentPlanet.Name, '');
          AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, News, '');
        end;
        ItemName := LookupLocalizedTextByKey('PlanetQuest.ItemForPlanetQuest.' + IntToStr(GovernmentQuest.QuestNumber));
        if ItemName <> 'none' then
        begin
          Item := TUselessItem.Create;
          Item.Init(ItemName, 0);
          Player.Inventory.Add(Item);
        end;
        Player.CurrentPlanet.TextQuestId := -1;
        (GetByName('QuestPanel') as TPanelGI).SetActive(False);
        if Player.CurrentPlanet.IsCoalitionOwned then
        begin
          Player.CurrentPlanet.ChangeRelationToRanger(Player, LoadedQuest.SuccessRelationDelta);
          if Player.CurrentPlanet.RelationToShip(Player) < 20 then
            Player.CurrentPlanet.SetRelationLevelToRanger(Player, rlBad);
        end;
        LoadedQuest.Free;
        Break;
      end;
    end;
  RequestedScreenId := PlanetQuestReturnScreenId;
  RequestClose(1);
end;
{ @end $53F988 }

{ @routine $53FD3C TfPlanetQuest_StartLoadedQuest }
procedure TfPlanetQuest.StartLoadedQuest;
var I, J, StartId: Integer;
begin
  ClearChoices;
  DaysElapsed := 0;
  Quest.ResetEventIndices;
  ShowingPathTransition := False;
  if Player = nil then CurrentDate := TrimWideString(Galaxy.FormatTurnDate(200))
  else CurrentDate := TrimWideString(Galaxy.FormatTurnDate(Galaxy.CurrentTurn));
  for I := 1 to 48 do ParameterVisible[I] := True;
  for I := 1 to Quest.LocationCount do Quest.Locations[I].NextEventIndex := 1;
  for I := 1 to Quest.LocationCount do
    for J := 1 to Quest.PathCount do RemainingPathVisits[I, J] := 0;
  for I := 1 to Quest.PathCount do
    if Quest.Paths[I].TraversalLimit = 0 then
      RemainingPathVisits[Quest.FindLocationIndex(Quest.Paths[I].FromLocationId), I] := 2000000000
    else RemainingPathVisits[Quest.FindLocationIndex(Quest.Paths[I].FromLocationId), I] := Quest.Paths[I].TraversalLimit;
  PlayerDied := False;
  for I := 1 to 48 do ParameterVisible[I] := True;
  for I := 1 to 48 do
  begin
    ParameterValues[I] := Quest.Parameters[I].Value;
    PreviousParameterValues[I] := Quest.Parameters[I].Value;
  end;
  StartId := 0;
  for I := 1 to Quest.LocationCount do
    if Quest.Locations[I].IsStart then StartId := Quest.Locations[I].Id;
  CurrentLocationId := StartId;
  LastPathIndex := 0;
  for I := 1 to 48 do
    if not Quest.Parameters[I].IsMoney then
    begin
      if Quest.Parameters[I].InitialRange.RangeCount > 0 then
        ParameterValues[I] := Trunc(Quest.Parameters[I].InitialRange.GetRandomValue)
      else ParameterValues[I] := Quest.Parameters[I].Value;
    end
    else
    begin
      for J := 1 to Quest.PathCount do
        with Quest.Paths[J].ParameterChanges[I] do
          if MaxValue >= Quest.Parameters[I].MaxValue then MaxValue := 184549375;
      Quest.Parameters[I].MaxValue := 184549375;
      if Player = nil then
        if Quest.Parameters[I].InitialRange.RangeCount > 0 then
          ParameterValues[I] := Trunc(Quest.Parameters[I].InitialRange.GetRandomValue)
        else ParameterValues[I] := Quest.Parameters[I].Value
      else ParameterValues[I] := Player.Money;
    end;
  Description.Pending := False;
  Description.Text := '';
  SetNamedLabelText('MessageText', '');
  StartQuestLoop;
  FinishChoiceLayout;
end;
{ @end $53FD3C }

{ @routine $54010C TfPlanetQuest_AddSuccessAction }
procedure TfPlanetQuest.AddSuccessAction;
begin
  if TrimWideString(CriticalMessage) = '' then
    ShowQuestText(ExpandParameterExpressions(TrimWideString(Quest.Parameters[CriticalParameterIndex].CriticalText.Text), 1), False)
  else ShowQuestText(ExpandParameterExpressions(CriticalMessage, 1), False);
  SelectQuestPicture;
  ClearChoices;
  if (Player <> nil) and Player.InPrison then
    AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgSuccessPrison'), CompleteQuestSuccess)
  else AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgSuccess'), CompleteQuestSuccess);
end;
{ @end $54010C }

{ @routine $540308 TfPlanetQuest_AddFailureAction }
procedure TfPlanetQuest.AddFailureAction;
var News: WideString; I: Integer; GovernmentQuest: PQuest;
begin
  if TrimWideString(CriticalMessage) = '' then
    ShowQuestText(ExpandParameterExpressions(TrimWideString(Quest.Parameters[CriticalParameterIndex].CriticalText.Text), 1), False)
  else ShowQuestText(ExpandParameterExpressions(CriticalMessage, 1), False);
  SelectQuestPicture;
  ClearChoices;
  if (Player <> nil) and Player.InPrison then
  begin
    if PlayerDied then
      AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgDeath'), CompleteQuestDeath)
    else
    begin
      if Player.CurrentPlanet <> nil then Player.CurrentPlanet.SetRelationLevelToRanger(Player, rlHostile);
      AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgFailPrison'), CompleteQuestDeath);
    end;
  end
  else if PlayerDied then
    AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgDeath'), CompleteQuestFailure)
  else
  begin
    AddChoice(' - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgFail'), CompleteQuestFailure);
    if (Player <> nil) and (Player.Quests.Count > 0) then
        for I := Player.Quests.Count - 1 downto 0 do
        begin
          GovernmentQuest := Player.Quests[I];
          if (GovernmentQuest.QuestType = qtPlanetQuest) and
            (GovernmentQuest.ObjectiveTarget is TPlanet) and
            ((GovernmentQuest.ObjectiveTarget as TPlanet) = Player.CurrentPlanet) then
          begin
            GovernmentQuest.Successful := False;
            Player.PublishQuestStatus(GovernmentQuest, -1);
            News := PickLocalizedTextVariant('GalaxyNews.Quest.Failure.PlanetaryQuest', (Galaxy.CurrentTurn div 10) * Integer(Player.Seed));
            ReplaceTextToken(News, '<ToPlanet>', Player.CurrentPlanet.Name, HighlightColorTag);
            ReplaceTextToken(News, '<FromPlanet>', GovernmentQuest.Planet.Name, HighlightColorTag);
            ReplaceTextToken(News, '<Relation>', GovernmentQuest.Planet.GetRelationLevelTextToShip(Player), HighlightColorTag);
            AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, News, '');
            Player.CurrentPlanet.TextQuestId := -1;
            Player.ArchiveQuest(I);
            Break;
          end;
        end;
  end;
end;
{ @end $540308 }

{ @routine $54083C TfPlanetQuest_CompleteQuestDeath }
procedure TfPlanetQuest.CompleteQuestDeath;
begin
  if Player = nil then
  begin
    RequestedScreenId := PlanetQuestReturnScreenId;
    RequestClose(1);
  end
  else if PlayerDied then
  begin
    if not SaveManagerScreen.IsSlotEmpty(10) and
      (ShowMessageBoxGI(Self, LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'), mbgOK or mbgCancel) = mbgResultOK) then
    begin
      PendingLoadFileName := SaveManagerScreen.GetSaveSlotPath(10);
      RequestedScreenId := screenGameLoad;
      RequestClose(1);
    end
    else
    begin
      ScoreScreen.RecordPlayerResult(-1);
      Player.Free;
      GameEndReason := 1;
      RequestedScreenId := screenGameEnd;
      RequestClose(1);
    end;
  end
  else
  begin
    Player.InPrison := False;
    HangarScreen.PrepareTakeoff;
    RequestClose(1);
  end;
end;
{ @end $54083C }

{ @routine $5409D0 TfPlanetQuest_CompleteQuestFailure }
procedure TfPlanetQuest.CompleteQuestFailure;
begin
  if Player = nil then
  begin
    RequestedScreenId := PlanetQuestReturnScreenId;
    RequestClose(1);
  end
  else if PlayerDied then
  begin
    if not SaveManagerScreen.IsSlotEmpty(10) and
      (ShowMessageBoxGI(Self, LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'), mbgOK or mbgCancel) = mbgResultOK) then
    begin
      PendingLoadFileName := SaveManagerScreen.GetSaveSlotPath(10);
      RequestedScreenId := screenGameLoad;
      RequestClose(1);
    end
    else
    begin
      ScoreScreen.RecordPlayerResult(-1);
      Player.Free;
      GameEndReason := 1;
      RequestedScreenId := screenGameEnd;
      RequestClose(1);
    end;
  end
  else if not SaveManagerScreen.IsSlotEmpty(10) and
    (ShowMessageBoxGI(Self, LocalizedText('Planet.NotCivil.QuestPlay.MsgLoad'), mbgOK or mbgCancel) = mbgResultOK) then
  begin
    PendingLoadFileName := SaveManagerScreen.GetSaveSlotPath(10);
    RequestedScreenId := screenGameLoad;
    RequestClose(1);
  end
  else
  begin
    RequestedScreenId := PlanetQuestReturnScreenId;
    RequestClose(1);
  end;
end;
{ @end $5409D0 }

{ @routine $540BE0 TfPlanetQuest_ContinueAlongPath }
procedure TfPlanetQuest.ContinueAlongPath(PathIndex, AutomaticStepCount: Integer);
var I: Integer; Changes: TQuestParameterChanges;
begin
  ShowingPathTransition := True;
  Dec(RemainingPathVisits[Quest.FindLocationIndex(CurrentLocationId), PathIndex]);
  CurrentLocationId := Quest.Paths[PathIndex].ToLocationId;
  LastPathIndex := PathIndex;
  for I := 1 to 48 do Changes[I] := Quest.Paths[PathIndex].ParameterChanges[I];
  ApplyParameterChanges(ParameterValues, Changes);
  ApplyParameterVisibility(Changes);
  if not Quest.HasEmptyPathLabel(PathIndex) then RefreshParameterText;
  if TrimWideString(Quest.Paths[LastPathIndex].TransitionText.Text) <> '' then
    ShowQuestText(ExpandParameterExpressions(TrimWideString(Quest.Paths[LastPathIndex].TransitionText.Text), 1), False);
  SelectQuestPicture;
  ShowingPathTransition := False;
  AdvanceQuest(AutomaticStepCount);
end;
{ @end $540BE0 }

{ @routine $540D90 TfPlanetQuest_BuildPathChoices }
function TfPlanetQuest.BuildPathChoices(SkipPathChoiceRefresh: Boolean): Integer;
var
  I, CandidateCount, GroupCount, SelectedCount: Integer;
  Eligible: ATAnswer;
  EligibleCount, FirstIndex, J, RandomIndex, VisibleIndex: Integer;
  MaxPriority: Extended;
  AutomaticPath: Integer;
  Candidates: array[1..50] of TAnswer;
  Group: array[1..50] of TAnswer;
  SelectedChoices: array[1..50] of TAnswer;
  Unprocessed: array[1..50] of Boolean;
  Choice, Swap: TAnswer;
begin
  if not SkipPathChoiceRefresh then ClearChoices;
  if not SkipPathChoiceRefresh then RefreshParameterText;
  AutomaticPath := 0;
  if Quest.Locations[Quest.FindLocationIndex(CurrentLocationId)].IsSuccess then begin
    if (Player = nil) or not Player.InPrison then
      AddChoice('       - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgSuccess'), CompleteQuestSuccess)
    else AddChoice('       - ' + LocalizedColorText('Planet.NotCivil.QuestPlay.MsgSuccessPrison'), CompleteQuestSuccess);
  end else begin
    SetLength(Eligible, 51);
    for I := 1 to 50 do begin
      Candidates[I].PathIndex := -1;
      SelectedChoices[I].PathIndex := -1;
    end;
    CandidateCount := 0;
    SelectedCount := 0;
    for I := 1 to Quest.PathCount do begin
      if Quest.Paths[I].FromLocationId <> CurrentLocationId then Continue;
      if (RemainingPathVisits[Quest.FindLocationIndex(CurrentLocationId), I] >= 1) and
        HasLocationContinuation(Quest.FindLocationIndex(Quest.Paths[I].ToLocationId)) then begin
        if CheckPathConditions(ParameterValues, I) then begin
          Inc(CandidateCount);
          Candidates[CandidateCount].PathIndex := I;
          Candidates[CandidateCount].DisplayOrder := Quest.Paths[I].DisplayOrder;
          Candidates[CandidateCount].Enabled := True;
          Candidates[CandidateCount].Text := ExpandParameterExpressions(TrimWideString(Quest.Paths[I].ChoiceText.Text), I);
        end else if Quest.Paths[I].AlwaysShow then begin
          Inc(CandidateCount);
          Candidates[CandidateCount].PathIndex := I;
          Candidates[CandidateCount].DisplayOrder := Quest.Paths[I].DisplayOrder;
          Candidates[CandidateCount].Enabled := False;
          Candidates[CandidateCount].Text := ExpandParameterExpressions(TrimWideString(Quest.Paths[I].ChoiceText.Text), I);
        end;
      end;
    end;
    for I := 1 to CandidateCount do begin
      RandomIndex := Random(CandidateCount) + 1;
      Swap := Candidates[RandomIndex];
      Candidates[RandomIndex] := Candidates[I];
      Candidates[I] := Swap;
    end;
    for I := 1 to 50 do Unprocessed[I] := True;
    for I := 1 to CandidateCount do begin
      EligibleCount := 0;
      GroupCount := 0;
      FirstIndex := 0;
      MaxPriority := 0;
      Choice.PathIndex := -1;
      if Unprocessed[I] then FirstIndex := I;
      if FirstIndex <> 0 then
        for J := 1 to CandidateCount do
          if TrimWideString(Candidates[FirstIndex].Text) = TrimWideString(Candidates[J].Text) then begin
            Unprocessed[J] := False;
            Inc(GroupCount);
            Group[GroupCount] := Candidates[J];
            if MaxPriority < Quest.Paths[Candidates[J].PathIndex].Priority then
              MaxPriority := Quest.Paths[Candidates[J].PathIndex].Priority;
          end;
      for J := 1 to GroupCount do
        if MaxPriority <= 100 * Quest.Paths[Group[J].PathIndex].Priority then begin
          Inc(EligibleCount);
          Eligible[EligibleCount] := Group[J];
        end;
      Choice := SelectWeightedPath(Eligible, EligibleCount);
      if Choice.PathIndex <> -1 then begin
        Inc(SelectedCount);
        SelectedChoices[SelectedCount] := Choice;
      end;
    end;
    if not SkipPathChoiceRefresh then
      for I := 1 to SelectedCount do
        for J := 1 to SelectedCount - 1 do
          if SelectedChoices[J].DisplayOrder < SelectedChoices[J + 1].DisplayOrder then begin
            Swap := SelectedChoices[J + 1];
            SelectedChoices[J + 1] := SelectedChoices[J];
            SelectedChoices[J] := Swap;
          end;
    if (SelectedCount = 1) and Quest.HasEmptyPathLabel(SelectedChoices[1].PathIndex) then
      AutomaticPath := SelectedChoices[1].PathIndex
    else begin
      VisibleIndex := 0;
      for I := 1 to SelectedCount do
        if (TrimWideString(Quest.Paths[SelectedChoices[I].PathIndex].ChoiceText.Text) <> '') and not SkipPathChoiceRefresh then begin
          if SelectedChoices[I].Enabled then begin
            ChoicePathIndexes[VisibleIndex] := SelectedChoices[I].PathIndex;
            ChoiceEnabled[VisibleIndex] := SelectedChoices[I].Enabled;
            AddChoice('    - ' + SelectedChoices[I].Text, ChoiceCallbacks[VisibleIndex]);
            Inc(VisibleIndex);
          end else begin
            if Quest.Paths[SelectedChoices[I].PathIndex].AlwaysShow then begin
            ChoicePathIndexes[VisibleIndex] := SelectedChoices[I].PathIndex;
            ChoiceEnabled[VisibleIndex] := SelectedChoices[I].Enabled;
            AddDisabledChoice('    - ' + SelectedChoices[I].Text, ChoiceCallbacks[VisibleIndex]);
            Inc(VisibleIndex);
            end;
          end;
        end;
    end;
  end;
  Result := AutomaticPath;
end;
{ @end $540D90 }

{ @routine $54162C TfPlanetQuest_AdvanceQuest }
procedure TfPlanetQuest.AdvanceQuest(AutomaticStepCount: Integer);
var LocationIndex: Integer; Success, Failure: Boolean; Text: WideString; I, PathIndex: Integer; Changes: TQuestParameterChanges;
begin
  Success := False;
  Failure := CheckPathFailure(LastPathIndex, ParameterValues, PreviousParameterValues);
  if not Failure then Success := CheckPathSuccess(LastPathIndex, ParameterValues, PreviousParameterValues);
  if Success then
  begin
    AddSuccessAction;
    RefreshParameterText;
  end
  else if Failure then
  begin
    AddFailureAction;
    RefreshParameterText;
  end
  else
  begin
    LocationIndex := Quest.FindLocationIndex(CurrentLocationId);
    for I := 1 to Quest.Locations[LocationIndex].Days do
    begin
      AdvanceGalaxyDay;
      Inc(DaysElapsed);
    end;
    for I := 1 to 48 do
    begin
      Changes[I] := Quest.Locations[LocationIndex].ParameterChanges[I];
      PreviousParameterValues[I] := ParameterValues[I];
    end;
    ApplyParameterChanges(ParameterValues, Changes);
    ApplyParameterVisibility(Changes);
    if not Quest.Locations[LocationIndex].IsEmpty then
    begin
      Quest.Locations[LocationIndex].SelectEvent(ParameterValues);
      Text := ExpandParameterExpressions(TrimWideString(Quest.Locations[LocationIndex].SelectedEventText.Text), 1);
      ShowQuestText(Text, False);
    end;
    SelectQuestPicture;
    // Native counts these days twice: once in the galaxy loop above and here.
    DaysElapsed := DaysElapsed + Quest.Locations[LocationIndex].Days;
    RefreshParameterText;
    Success := False;
    Failure := CheckLocationFailure(LocationIndex, ParameterValues, PreviousParameterValues);
    if not Failure then Success := CheckLocationSuccess(LocationIndex, ParameterValues, PreviousParameterValues);
    for I := 1 to 48 do PreviousParameterValues[I] := ParameterValues[I];
    if Success then
    begin
      ClearChoices;
      AddChoice(LocalizedColorText('Planet.NotCivil.QuestPlay.MsgContinue'), AddSuccessAction);
    end
    else if Failure then
    begin
      ClearChoices;
      AddChoice(LocalizedColorText('Planet.NotCivil.QuestPlay.MsgContinue'), AddFailureAction);
    end
    else if Quest.Locations[LocationIndex].IsFailure then
    begin
      if Quest.Locations[LocationIndex].IsDeath then PlayerDied := True;
      CriticalMessage := Text;
      AddFailureAction;
    end
    else
    begin
      PathIndex := BuildPathChoices(False);
      if PathIndex > 0 then
      begin
        Inc(AutomaticStepCount);
        if AutomaticStepCount < 2401 then ContinueAlongPath(PathIndex, AutomaticStepCount);
      end
      else
      begin
        if Quest.Locations[LocationIndex].IsEmpty then
          if TrimWideString(Quest.Paths[LastPathIndex].TransitionText.Text) = '' then
          begin
            Quest.Locations[LocationIndex].SelectEvent(ParameterValues);
            ShowQuestText(ExpandParameterExpressions(TrimWideString(Quest.Locations[LocationIndex].SelectedEventText.Text), 1), False);
          end;
        BuildPathChoices(False);
      end;
    end;
  end;
end;
{ @end $54162C }

{ @routine $541A84 TfPlanetQuest_RefreshParameterText }
procedure TfPlanetQuest.RefreshParameterText;
var Text, Combined: WideString; I: Integer; Visible: Boolean;
begin
  Combined := '';
  for I := 1 to 48 do
  begin
    Visible := ParameterVisible[I];
    if not Quest.Parameters[I].Enabled or Quest.Parameters[I].Hidden then Visible := False;
    if (ParameterValues[I] = 0) and not Quest.Parameters[I].ShowWhenZero then Visible := False;
    if Visible then
    begin
      Text := Quest.Parameters[I].GetDisplayText(ParameterValues[I]);
      Text := ExpandParameterExpressions(Text, I);
      Text := ReplaceAllWideString(Text, '<>', HighlightColorTag + IntToStr(ParameterValues[I]) + ColorEndTag);
      if Text <> '' then Combined := Combined + TrimWideString(Text) + #13#10;
    end;
  end;
  SetNamedLabelText('ParamsShowWindow', Combined);
end;
{ @end $541A84 }

{ @routine $541C70 TfPlanetQuest_SetNamedLabelText }
procedure TfPlanetQuest.SetNamedLabelText(Name, Text: WideString);

begin
  (GetByName(Name) as TLabelGI).SetText(Text);
end;
{ @end $541C70 }

{ @routine $541CE4 TfPlanetQuest_ClearChoices }
procedure TfPlanetQuest.ClearChoices;
var I: Integer;
begin
  with GetByName('ActionListWindow') as TPanelScrollBarGI do begin
    FreeOwnedChildren;
    Invalidate;
  end;
  // Native clears slots 1..8; slot zero is overwritten by the next AddChoice.
  for I := 1 to 8 do VisibleChoiceCallbacks[I] := nil;
  NextChoiceTop := 0;
  ChoiceCount := 0;
end;
{ @end $541CE4 }

{ @routine $541D68 TfPlanetQuest_AddChoice }
procedure TfPlanetQuest.AddChoice(Text: WideString; Callback: TQuestChoiceEvent);
var Panel: TPanelScrollBarGI; LabelControl: TLabelGI;
begin
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  VisibleChoiceCallbacks[ChoiceCount] := Callback;
  LabelControl := TLabelGI.Create(Panel);
  LabelControl.SetName(IntToStr(ChoiceCount));
  LabelControl.SetFontName(HitPointFontName);
  LabelControl.SetSize(Classes.Point(Panel.ClientSize.X, 20));
  LabelControl.SetPosition(Classes.Point(0, NextChoiceTop));
  LabelControl.SetDepth(2);
  LabelControl.SetWordWrapEnabled(True);
  LabelControl.SetTextAlignX(taxAuto);
  LabelControl.SetTextAlignY(tayAuto);
  LabelControl.SetText(Text);
  LabelControl.SetTextBorderWidth(1);
  LabelControl.SetTextBorderColor(CurrentPixelFormat.PackRgbBytes(60, 60, 60));
  LabelControl.SetPositionModeW(True);
  LabelControl.SetActive(True);
  LabelControl.MouseEnterCallback := ChoiceMouseEnter;
  LabelControl.MouseLeaveCallback := ChoiceMouseLeave;
  LabelControl.LeftButtonDownCallback := ChoiceMouseDown;
  LabelControl.SetTextColor(CurrentPixelFormat.PackRgbBytes(219, 218, 156));
  NextChoiceTop := NextChoiceTop + LabelControl.ClientSize.Y + 3;
  Panel.UpdateScrollRanges;
  Inc(ChoiceCount);
end;
{ @end $541D68 }

{ @routine $541F78 TfPlanetQuest_AddDisabledChoice }
procedure TfPlanetQuest.AddDisabledChoice(Text: WideString; Callback: TQuestChoiceEvent);
var Panel: TPanelScrollBarGI; LabelControl: TLabelGI;
begin
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  VisibleChoiceCallbacks[ChoiceCount] := Callback;
  LabelControl := TLabelGI.Create(Panel);
  LabelControl.SetName(IntToStr(ChoiceCount));
  LabelControl.SetFontName(HitPointFontName);
  LabelControl.SetSize(Classes.Point(Panel.ClientSize.X, 20));
  LabelControl.SetPosition(Classes.Point(0, NextChoiceTop));
  LabelControl.SetDepth(2);
  LabelControl.SetWordWrapEnabled(True);
  LabelControl.SetTextAlignX(taxAuto);
  LabelControl.SetTextAlignY(tayAuto);
  LabelControl.SetText(Text);
  LabelControl.SetTextBorderWidth(1);
  LabelControl.SetTextBorderColor(CurrentPixelFormat.PackRgbBytes(60, 60, 60));
  LabelControl.SetPositionModeW(True);
  LabelControl.SetActive(True);
  LabelControl.MouseEnterCallback := DisabledChoiceMouseEnter;
  LabelControl.MouseLeaveCallback := DisabledChoiceMouseLeave;
  LabelControl.SetTextColor(CurrentPixelFormat.PackRgbBytes(120, 120, 120));
  NextChoiceTop := NextChoiceTop + LabelControl.ClientSize.Y + 3;
  Panel.UpdateScrollRanges;
  Inc(ChoiceCount);
end;
{ @end $541F78 }

{ @routine $542178 TfPlanetQuest_ChoiceMouseEnter }
procedure TfPlanetQuest.ChoiceMouseEnter(Sender: TObjectGI);

begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 245, 80));
end;
{ @end $542178 }

{ @routine $5421A4 TfPlanetQuest_ChoiceMouseLeave }
procedure TfPlanetQuest.ChoiceMouseLeave(Sender: TObjectGI);

begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(219, 218, 156));
end;
{ @end $5421A4 }

{ @routine $5421D4 TfPlanetQuest_ChoiceMouseDown }
procedure TfPlanetQuest.ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Callback: TQuestChoiceEvent;
begin
  Callback := VisibleChoiceCallbacks[StrToInt(Sender.ControlName)];
  Description.Pending := False;
  ClearChoices;
  if Assigned(Callback) then Callback;
  FinishChoiceLayout;
  BreakUiMessage;
end;
{ @end $5421D4 }

{ @routine $542270 TfPlanetQuest_DisabledChoiceMouseEnter }
procedure TfPlanetQuest.DisabledChoiceMouseEnter(Sender: TObjectGI);

begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(150, 150, 150));
end;
{ @end $542270 }

{ @routine $5422A0 TfPlanetQuest_DisabledChoiceMouseLeave }
procedure TfPlanetQuest.DisabledChoiceMouseLeave(Sender: TObjectGI);

begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(120, 120, 120));
end;
{ @end $5422A0 }

{ @routine $5422CC TfPlanetQuest_FinishChoiceLayout }
procedure TfPlanetQuest.FinishChoiceLayout;
var Panel: TPanelScrollBarGI; Child: TObjectGI; ExtraHeight, Top: Integer;
begin
  Panel := GetByName('ActionListWindow') as TPanelScrollBarGI;
  Panel.VerticalScrollBar.SetSmallChange((GetByName('MessageText') as TLabelGI).GetLineHeight);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  if NextChoiceTop > Panel.ClientSize.Y then begin
    Panel.SetScrollOffset(Classes.Point(0, 0));
    Panel.SetVerticalScrollbarEnabled(True);
    Panel.SetDragScrollingEnabled(True);
    Panel.UpdateScrollRanges;
  end else begin
    if ChoiceCount > 0 then begin
      ExtraHeight := (Panel.ClientSize.Y - NextChoiceTop) div ChoiceCount;
      Child := Panel.FirstChild;
      Top := 0;
      while Child <> nil do begin
        (Child as TLabelGI).SetTextAlignY(tayCenterEx);
        Child.SetPosition(Classes.Point(Child.LocalPosition.X, Top));
        Child.SetSize(Classes.Point(Child.ClientSize.X, Child.ClientSize.Y + ExtraHeight));
        Inc(Top, Child.ClientSize.Y);
        Child := Child.NextSibling;
      end;
    end;
    Panel.SetVerticalScrollbarEnabled(False);
    Panel.SetScrollOffset(Classes.Point(0, 0));
    Panel.SetDragScrollingEnabled(False);
  end;
  Panel := GetByName('MessageWindow') as TPanelScrollBarGI;
  Panel.SetScrollOffset(Classes.Point(0, 0));
  Panel.SetVerticalScrollbarEnabled(GetByName('MessageText').ClientSize.Y > Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetSmallChange((GetByName('MessageText') as TLabelGI).GetLineHeight);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  Panel.UpdateScrollRanges;
end;
{ @end $5422CC }

{ @routine $54252C TfPlanetQuest_WaitForContinuation }
function TfPlanetQuest.WaitForContinuation: Boolean;
begin
  WaitingForContinuation := True;
  WaitFinished := False;
  while not WaitFinished do
  begin
    if ProcessUiIteration then
    begin
      Result := True;
      WaitingForContinuation := False;
      Exit;
    end;
    WaitMessage;
  end;
  WaitingForContinuation := False;
  Result := False;
end;
{ @end $54252C }

{ @routine $542570 TfPlanetQuest_FinishWait }
procedure TfPlanetQuest.FinishWait;

begin
  WaitFinished := True;
end;
{ @end $542570 }

{ @routine $542578 TfPlanetQuest_OnOpen }
procedure TfPlanetQuest.OnOpen;
var Found: Boolean; I, J: Integer; GovernmentQuest: PQuest;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  CriticalParameterIndex := 0;
  GetByName('PQI').SetActive(False);
  CurrentPicture := '';
  GetByName('MainPanel').KeyDownCallback := QuestKeyDown;
  (GetByName('ButtonExit') as TGraphButtonGI).UpCallback := RequestExit;
  (GetByName('QuestPanel') as TPanelGI).SetActive(True);
  ClearChoices;
  ChoiceCallbacks[0] := ChoosePath0;
  ChoiceCallbacks[1] := ChoosePath1;
  ChoiceCallbacks[2] := ChoosePath2;
  ChoiceCallbacks[3] := ChoosePath3;
  ChoiceCallbacks[4] := ChoosePath4;
  ChoiceCallbacks[5] := ChoosePath5;
  ChoiceCallbacks[6] := ChoosePath6;
  ChoiceCallbacks[7] := ChoosePath7;
  ChoiceCallbacks[8] := ChoosePath8;
  ChoiceCallbacks[9] := ChoosePath9;
  ChoiceCallbacks[10] := ChoosePath10;
  ChoiceCallbacks[11] := ChoosePath11;
  ChoiceCallbacks[12] := ChoosePath12;
  ChoiceCallbacks[13] := ChoosePath13;
  ChoiceCallbacks[14] := ChoosePath14;
  ChoiceCallbacks[15] := ChoosePath15;
  ChoiceCallbacks[16] := ChoosePath16;
  ChoiceCallbacks[17] := ChoosePath17;
  ChoiceCallbacks[18] := ChoosePath18;
  ChoiceCallbacks[19] := ChoosePath19;
  ChoiceCallbacks[20] := ChoosePath20;
  ChoiceCallbacks[21] := ChoosePath21;
  ChoiceCallbacks[22] := ChoosePath22;
  ChoiceCallbacks[23] := ChoosePath23;
  ChoiceCallbacks[24] := ChoosePath24;
  ChoiceCallbacks[25] := ChoosePath25;
  ChoiceCallbacks[26] := ChoosePath26;
  ChoiceCallbacks[27] := ChoosePath27;
  ChoiceCallbacks[28] := ChoosePath28;
  ChoiceCallbacks[29] := ChoosePath29;
  ChoiceCallbacks[30] := ChoosePath30;
  ChoiceCallbacks[31] := ChoosePath31;
  ChoiceCallbacks[32] := ChoosePath32;
  ChoiceCallbacks[33] := ChoosePath33;
  ChoiceCallbacks[34] := ChoosePath34;
  ChoiceCallbacks[35] := ChoosePath35;
  ChoiceCallbacks[36] := ChoosePath36;
  ChoiceCallbacks[37] := ChoosePath37;
  ChoiceCallbacks[38] := ChoosePath38;
  ChoiceCallbacks[39] := ChoosePath39;
  ChoiceCallbacks[40] := ChoosePath40;
  ChoiceCallbacks[41] := ChoosePath41;
  ChoiceCallbacks[42] := ChoosePath42;
  ChoiceCallbacks[43] := ChoosePath43;
  ChoiceCallbacks[44] := ChoosePath44;
  ChoiceCallbacks[45] := ChoosePath45;
  ChoiceCallbacks[46] := ChoosePath46;
  ChoiceCallbacks[47] := ChoosePath47;
  ChoiceCallbacks[48] := ChoosePath48;
  ChoiceCallbacks[49] := ChoosePath49;
  SetNamedLabelText('MessageText', '');
  SetNamedLabelText('ParamsShowWindow', '');
  if (Player <> nil) and (Player.CurrentPlanet.TextQuestId >= 10000) and
    ((LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') <= 0) or
     (LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuestLic').GetParamOrMarker(IntToStr(Player.CurrentPlanet.TextQuestId)) =
      PlanetQuestScreen.GetQuestContentHash(Player.CurrentPlanet.TextQuestId))) then
    MoneyLimitComplement := (Galaxy.ComputeScaledBigMoney(oiPeople) + Player.Money) xor $FFFFFFFF
  else if Player <> nil then MoneyLimitComplement := (Player.Money + 50000) xor $FFFFFFFF
  else MoneyLimitComplement := 1000000000 xor $FFFFFFFF;
  if (Player <> nil) and Player.InPrison then begin
    Quest := TQuestGameContent.Create;
    LoadQuestByName('Prison');
    Quest.UnresolvedText120.Text := Quest.UnresolvedText110.Text;
    Quest.ToStarText.Text := Player.CurrentStar.Name;
    Quest.UnresolvedText11C.Text := '';
    Quest.ToPlanetText.Text := Player.CurrentPlanet.Name;
    Quest.DateText.Text := '';
    Quest.MoneyText.Text := '';
    Quest.RangerText.Text := Player.Name;
    for I := 1 to 48 do
      with Quest.Parameters[I] do
        if IsMoney then begin
          Value := Player.Money;
          MinValue := 0;
        end;
    StartLoadedQuest;
  end else if (Player <> nil) and not StandaloneQuestMode then begin
    Found := False;
    if Player.CurrentPlanet.TextQuestId > -1 then
      if Player.Quests.Count > 0 then
        for I := 0 to Player.Quests.Count - 1 do begin
          GovernmentQuest := Player.Quests[I];
          if (GovernmentQuest.QuestType = qtPlanetQuest) and (GovernmentQuest.ObjectiveTarget is TPlanet) and
            ((GovernmentQuest.ObjectiveTarget as TPlanet) = Player.CurrentPlanet) then begin
            ActiveGovernmentQuest := GovernmentQuest;
            Quest := TQuestGameContent.Create;
            LoadQuestById(Player.CurrentPlanet.TextQuestId);
            Quest.UnresolvedText120.Text := Quest.UnresolvedText110.Text;
            Quest.ToStarText.Text := Player.CurrentStar.Name;
            Quest.UnresolvedText11C.Text := '';
            Quest.ToPlanetText.Text := Player.CurrentPlanet.Name;
            Quest.DateText.Text := Galaxy.FormatTurnDate(GovernmentQuest.DeadlineTurn);
            Quest.MoneyText.Text := IntToStr(GovernmentQuest.RewardMoney);
            Quest.FromPlanetText.Text := GovernmentQuest.Planet.Name;
            Quest.FromStarText.Text := GovernmentQuest.Planet.CurrentStar.Name;
            Quest.RangerText.Text := Player.Name;
            for J := 1 to 48 do
              with Quest.Parameters[J] do
                if IsMoney then begin
                  Value := Player.Money;
                  MinValue := 0;
                end;
            StartLoadedQuest;
            Found := True;
            Break;
          end;
        end;
    if not Found then begin
      RequestedScreenId := PlanetQuestReturnScreenId;
      RequestClose(1);
    end;
  end else begin
    Quest := TQuestGameContent.Create;
    if IsIntegerTextW(TestQuestPath) then LoadQuestById(StrToInt(TestQuestPath))
    else LoadQuestByName(TestQuestPath);
    Quest.UnresolvedText120.Text := Quest.UnresolvedText110.Text;
    Quest.ToStarText.Text := 'FromStar';
    Quest.UnresolvedText11C.Text := '666';
    Quest.ToPlanetText.Text := 'Planet';
    Quest.DateText.Text := '66.66.6666';
    Quest.MoneyText.Text := '666.666';
    Quest.FromPlanetText.Text := 'Razzaxar!';
    Quest.FromStarText.Text := 'Pitaxxa!';
    Quest.RangerText.Text := 'Player';
    for I := 1 to 48 do
      with Quest.Parameters[I] do
        if IsMoney then begin
          if Player = nil then
            if Quest.Parameters[I].InitialRange.RangeCount > 0 then Value := Trunc(Quest.Parameters[I].InitialRange.GetRandomValue)
            else Value := Quest.Parameters[I].Value
          else Value := Player.Money;
          MinValue := 0;
        end;
    StartLoadedQuest;
  end;
end;
{ @end $542578 }

{ @routine $5431C8 TfPlanetQuest_OnClose }
procedure TfPlanetQuest.OnClose;

begin
  if Player <> nil then Player.SetMoney(Min(Int64(MoneyLimitComplement xor $FFFFFFFF), Int64(Player.Money)));
  if Quest <> nil then begin
    Quest.Free;
    Quest := nil;
  end;
  if Player <> nil then Player.ProcessQuestTimersAndOutcomes;
end;
{ @end $5431C8 }

{ @routine $543234 TfPlanetQuest_SetQuestPicture }
procedure TfPlanetQuest.SetQuestPicture(Name: WideString);
var Image: TGraphBufGI;
begin
  if CurrentPicture <> Name then begin
    CurrentPicture := Name;
    Image := GetByName('PQI') as TGraphBufGI;
    Image.SetActive(True);
    Image.LoadBitmapPathAsRgb(Name + '?RGB');
    if GiResourceVariant = 1 then
      Image.GraphBuf.RescaleRgb(Round(Cardinal(Image.GraphBuf.Width) * 800 / 1024), Round(Cardinal(Image.GraphBuf.Height) * 800 / 1024));
    Image.GraphBuf.ConvertRgbTo565;
    Image.Invalidate;
  end;
end;
{ @end $543234 }

{ @routine $54336C TfPlanetQuest_RequestExit }
procedure TfPlanetQuest.RequestExit(Sender: TObjectGI);

begin
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormGameMenu.QExit'), mbgOK or mbgCancel) = mbgResultOK then begin
    if Galaxy <> nil then begin
      Galaxy.Free;
      Galaxy := nil;
    end;
    RequestedScreenId := screenMainMenu;
    RequestClose(1);
  end;
end;
{ @end $54336C }

{ @routine $54342C TfPlanetQuest_QuestKeyDown }
procedure TfPlanetQuest.QuestKeyDown(Sender: TObjectGI; Key: Cardinal);

begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then
    if Key = VK_ESCAPE then RequestExit(nil);
end;
{ @end $54342C }

{ @routine $543470 TfPlanetQuest_SelectMusic }
procedure TfPlanetQuest.SelectMusic;

begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else if Player = nil then MusicManager.PlayCategory('Base')
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
end;
{ @end $543470 }

end.

unit fGov;
// Unit bracket (inferred): CODE 0x00574C1C..0x005786BB; inclusive evidence, not full bounds.
// Planetary government, quests, bribes, charts and item storage.
interface
uses GI_MessageLoop, Types, fPanelMain, fPanelPlanet, EC_Str, aRanger;
type
  TfGov = class(TMessageLoopGI) // @size $100
  public
    procedure ClearDialogChoices; // @addr $575474
    procedure RunScriptShopAnswer(Answer: Integer); // @addr $576BEC
    procedure RunScriptGoodsAnswer(Answer: Integer); // @addr $576BC4
    procedure RunScriptPlanetAnswer(Answer: Integer); // @addr $576B9C
    procedure RunScriptTakeoff(Answer: Integer); // @addr $576B70
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4
    DialogText: WideString; // @offset $B8
    PresentedTextLength: Integer; // @offset $BC
    TextPresentationTimer: TCallbackTimerIdGI; // @offset $C0
    ChoiceHeight: Integer; // @offset $C4
    NextPortraitCycleAlternate: Boolean; // @offset $C8
    QuestOffer: TQuest; // @offset $CC
    QuestNegotiationLevel: Integer; // @offset $EC
    QuestRewardStep: Integer; // @offset $F0
    QuestDurationStep: Integer; // @offset $F4
    ScriptDialogNames: TStringsEC; // @offset $F8
    ScriptDialogCursor: Integer; // @offset $FC
    procedure AddScriptTakeoffChoice(Text: WideString); // @addr $576610
    procedure AddScriptPlanetChoice(Text: WideString); // @addr $576694
    procedure AddScriptGoodsChoice(Text: WideString); // @addr $576718
    procedure AddScriptShopChoice(Text: WideString); // @addr $57679C
    procedure ContinueScriptDialog; // @addr $5764B4
    procedure AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI); // @addr $5754CC
    procedure RunScriptAnswer(Answer: Integer); // @addr $576A78
    procedure ChoiceMouseEnter(Sender: TObjectGI); // @addr $575638
    procedure ChoiceMouseLeave(Sender: TObjectGI); // @addr $575664
    procedure ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $575694
    procedure RestartTextPresentation; // @addr $5756E8
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $575B08
    procedure AddMessageClicked(Sender: TObjectGI); // @addr $575C04
    procedure AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $575768
    procedure ResetPortraitCycle; // @addr $5752B0
    procedure PortraitCycleComplete(Sender: TObjectGI); // @addr $5752B8
    procedure SelectPortraitAnimation(Alternate: Boolean); // @addr $5752E4
    constructor Create; // @addr $574CB8
    destructor Destroy; override; // @addr $574D24
    procedure InitializeLayout; override; // @addr $574D90
    procedure OnClose; override; // @addr $5751CC
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $575B90
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $575204
    procedure ShipClicked(Sender: TObjectGI); // @addr $575274
    procedure SelectMusic; override; // @addr $575CD4
    procedure FinishScriptDialog(Action: Integer); // @addr $576ADC
    procedure DeclineBribe(Action: Integer); // @addr $577338
    procedure DeclineMapOffer(Action: Integer); // @addr $5782D8
    procedure StartScriptMessage(Action: Integer); // @addr $576A50
    procedure ExitGovernment(Action: Integer); // @addr $578370
    procedure ContinueAfterLiberation(Action: Integer); // @addr $578384
    procedure ContinueAfterPrison(Action: Integer); // @addr $576D6C
    procedure BuildQuestOfferChoices; // @addr $576820
    procedure BuildGreeting; // @addr $575D6C
    procedure BuildGovernmentChoices; // @addr $57607C
    procedure BuildBuiltinChoices; // @addr $576200
    procedure RequestQuest(Action: Integer); // @addr $5773D0
    procedure ShowBribeOffer(Action: Integer); // @addr $576E1C
    procedure ShowMapOffer(Action: Integer); // @addr $577F00
    procedure RetrieveStoredItems(Action: Integer); // @addr $578398
    procedure EnterPrison(Action: Integer); // @addr $576C14
    procedure AcceptQuest(Action: Integer); // @addr $577BB0
    procedure RejectQuest(Action: Integer); // @addr $577E00
    procedure MakeQuestEasier(Action: Integer); // @addr $577668
    procedure MakeQuestHarder(Action: Integer); // @addr $57790C
    procedure PayBribe(Action: Integer); // @addr $577100
    procedure BuyMap(Action: Integer); // @addr $578188
    procedure OnOpen; override; // @addr $574E3C
  end;
implementation

// @unit-initialization $5786B4
// @unit-finalization $578684

uses aScript, GR_Main, aConst, Classes, SysUtils, Windows, aPlanet, aPlayer, aGalaxy,
  Globals, GlobalsV, EC_Expression, GI_GAI, GI_Label, GI_PanelScrollBar, GI_GraphButton,
  fTalk, fEquipmentShop, fShip2, fPlanetQuest, aItem, aMyFunction, Math, aShip, aTranclucator, aSaveLoad, fHangar, fSaveManager;
{ @routine $574CB8 TfGov_Create }
constructor TfGov.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
  ScriptDialogNames := TStringsEC.Create;
end;
{ @end $574CB8 }

{ @routine $574D24 TfGov_Destroy }
destructor TfGov.Destroy;
begin
  if MainPanel <> nil then begin MainPanel.Free; MainPanel := nil; end;
  if PlanetPanel <> nil then begin PlanetPanel.Free; PlanetPanel := nil; end;
  if ScriptDialogNames <> nil then begin ScriptDialogNames.Free; ScriptDialogNames := nil; end;
  inherited Destroy;
end;
{ @end $574D24 }

{ @routine $574D90 TfGov_InitializeLayout }
procedure TfGov.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('UserMsgAdd') as TGraphButtonGI).UpCallback := AddMessageClicked;
end;
{ @end $574D90 }

{ @routine $574E3C TfGov_OnOpen }
procedure TfGov.OnOpen;
var Owner: TOwnerId;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  MainPanel.OnOpen;
  PlanetPanel.OnOpen;
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  if Player.CurrentPlanet.OwnerId = oiMaloc then SoundSection := 1
  else if Player.CurrentPlanet.OwnerId = oiPeleng then SoundSection := 2
  else if Player.CurrentPlanet.OwnerId = oiPeople then SoundSection := 3
  else if Player.CurrentPlanet.OwnerId = oiFei then SoundSection := 4
  else if Player.CurrentPlanet.OwnerId = oiGaal then SoundSection := 5
  else SoundSection := 0;
  if TemporaryShopSlots = nil then
  begin
    SelectMusic;
    RunStarTransitionScript(Player.CurrentStar, 0);
    PruneExpiredPersistentPlayerMessages;
    BuildTemporaryShopSlotGrid;
    ShowPlayerTipOnce(0);
  end;
  if (Player = nil) or ((Player.CurrentPlanet <> nil) and (Player.CurrentStar.ControlFaction = sfKlissan)) then
  begin
    GameEndReason := 2;
    RequestedScreenId := screenGameEnd;
    RequestClose(1);
    Exit;
  end;
  for Owner := oiMaloc to oiGaal do
  begin
    GetByName('Gov' + OwnerInfo[Owner].InternalName).SetActive(Owner = Player.CurrentPlanet.OwnerId);
    if Owner = Player.CurrentPlanet.OwnerId then
    begin
      with GetByName('Gov' + OwnerInfo[Owner].InternalName + 'Anim0') as TgaiGI do
      begin
        FirstFrameOnly := not AnimGov;
        PreloadImages;
      end;
      with GetByName('Gov' + OwnerInfo[Owner].InternalName + 'Anim1') as TgaiGI do
      begin
        FirstFrameOnly := not AnimGov;
        PreloadImages;
      end;
    end;
  end;
  (GetByName('TalkText') as TLabelGI).SetText('');
  SelectPortraitAnimation(True);
  BuildGreeting;
  RestartTextPresentation;
  (GetByName('TalkPA') as TPanelScrollBarGI).SetVerticalScrollbarEnabled(False);
  NextPortraitCycleAlternate := False;
  MainPanel.RebuildMessageButtons;
end;
{ @end $574E3C }

{ @routine $5751CC TfGov_OnClose }
procedure TfGov.OnClose;
begin
  ScriptDialogIndex := -1;
  ClearDialogChoices;
  MainPanel.OnClose;
  PlanetPanel.OnClose;
  ScriptDialogNames.Clear;
end;
{ @end $5751CC }

{ @routine $575204 TfGov_EndTurnClicked }
procedure TfGov.EndTurnClicked(Sender: TObjectGI);
begin
  if Player.CurrentPlanet.RelationToShip(Player) > 0 then
  begin
    RestoreTemporaryShopStock;
    ClearTemporaryShopSlots;
    MainPanel.EndTurnClicked(Sender);
    MainPanel.RebuildMessageButtons;
    if ExitCode = 0 then
    begin
      BuildTemporaryShopSlotGrid;
      SelectPortraitAnimation(True);
      BuildGreeting;
      RestartTextPresentation;
      NextPortraitCycleAlternate := False;
    end;
  end;
end;
{ @end $575204 }

{ @routine $575274 TfGov_ShipClicked }
procedure TfGov.ShipClicked(Sender: TObjectGI);
begin
  MainPanel.ShipClicked(Sender);
  if ShipScreen.RefreshStationDialog then
  begin
    BuildGreeting;
    RestartTextPresentation;
    MainPanel.RebuildMessageButtons;
  end;
end;
{ @end $575274 }

{ @routine $5752B0 TfGov_ResetPortraitCycle }
procedure TfGov.ResetPortraitCycle;
begin
  NextPortraitCycleAlternate := True;
end;
{ @end $5752B0 }

{ @routine $5752B8 TfGov_PortraitCycleComplete }
procedure TfGov.PortraitCycleComplete(Sender: TObjectGI);
begin
  if NextPortraitCycleAlternate then
  begin
    SelectPortraitAnimation(True);
    NextPortraitCycleAlternate := False;
  end
  else SelectPortraitAnimation(False);
end;
{ @end $5752B8 }

{ @routine $5752E4 TfGov_SelectPortraitAnimation }
procedure TfGov.SelectPortraitAnimation(Alternate: Boolean);
var Normal, AlternateAnimation: TgaiGI;
begin
  Normal := GetByName('Gov' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName + 'Anim0') as TgaiGI;
  Normal.CycleCompleteCallback := PortraitCycleComplete;
  Normal.SetSequenceFrame(0);
  Normal.StopAutoPlayback;
  if not Alternate then Normal.RestartPlayback else Normal.StopAutoPlayback;
  Normal.SetActive(not Alternate);
  AlternateAnimation := GetByName('Gov' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName + 'Anim1') as TgaiGI;
  AlternateAnimation.CycleCompleteCallback := PortraitCycleComplete;
  AlternateAnimation.SetSequenceFrame(0);
  AlternateAnimation.StopAutoPlayback;
  if Alternate then AlternateAnimation.RestartPlayback else AlternateAnimation.StopAutoPlayback;
  AlternateAnimation.SetActive(Alternate);
end;
{ @end $5752E4 }

{ @routine $575474 TfGov_ClearDialogChoices }
procedure TfGov.ClearDialogChoices;
var Panel, Child: TObjectGI;
begin
  ChoiceHeight := 0;
  Panel := GetByName('TalkPA');
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    TObject(Child.UserValue).Free;
    Child := Child.NextSibling;
  end;
  Panel.FreeOwnedChildren;
  Panel.Invalidate;
end;
{ @end $575474 }

{ @routine $5754CC TfGov_AddChoice }
procedure TfGov.AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI);
var
  Panel: TPanelScrollBarGI;
  Choice: TfTalkA;
begin
  Panel := GetByName('TalkPA') as TPanelScrollBarGI;
  Choice := TfTalkA.Create;
  Choice.Callback := Callback;
  Choice.Value := Value;
  with TLabelGI.Create(Panel) do
  begin
    SetFontName(HitPointFontName);
    SetSize(Point(Panel.ClientSize.X, 20));
    SetPosition(Point(0, ChoiceHeight));
    SetWordWrapEnabled(True);
    SetTextAlignX(taxAuto);
    SetTextAlignY(tayAuto);
    SetText(Text);
    SetPositionModeW(True);
    UserValue := Integer(Choice);
    SetActive(False);
    MouseEnterCallback := ChoiceMouseEnter;
    MouseLeaveCallback := ChoiceMouseLeave;
    LeftButtonDownCallback := ChoiceMouseDown;
    Inc(ChoiceHeight, ClientSize.Y);
  end;
end;
{ @end $5754CC }

{ @routine $575638 TfGov_ChoiceMouseEnter }
procedure TfGov.ChoiceMouseEnter(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 245, 80));
end;
{ @end $575638 }

{ @routine $575664 TfGov_ChoiceMouseLeave }
procedure TfGov.ChoiceMouseLeave(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
end;
{ @end $575664 }

{ @routine $575694 TfGov_ChoiceMouseDown }
procedure TfGov.ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Choice: TfTalkA;
begin
  Choice := TfTalkA(Sender.UserValue);
  if Assigned(Choice.Callback) then Choice.Callback(Choice.Value)
  else if Assigned(Choice.FallbackCallback) then Choice.FallbackCallback(Choice.FallbackText);
  RestartTextPresentation;
  BreakUiMessage;
end;
{ @end $575694 }

{ @routine $5756E8 TfGov_RestartTextPresentation }
procedure TfGov.RestartTextPresentation;
begin
  ResetPortraitCycle;
  (GetByName('TalkPA') as TPanelScrollBarGI).SetActive(False);
  PresentedTextLength := 0;
  if TextPresentationTimer <> 0 then
  begin
    CancelCallbackTimer(TextPresentationTimer);
    TextPresentationTimer := 0;
  end;
  TextPresentationTimer := ScheduleCallbackTimer(10, 10, AdvanceTextPresentation, 0);
end;
{ @end $5756E8 }

{ @routine $575768 TfGov_AdvanceTextPresentation }
procedure TfGov.AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Choices, TextPanel: TPanelScrollBarGI; Child: TObjectGI; Count, ExtraHeight, Top: Integer;
begin
  if PresentedTextLength >= Length(DialogText) then
  begin
    Choices := GetByName('TalkPA') as TPanelScrollBarGI;
    Choices.SetActive(True);
    Count := 0;
    Child := Choices.FirstChild;
    while Child <> nil do
    begin
      Child.SetActive(True);
      Child := Child.NextSibling;
      Inc(Count);
    end;
    if ChoiceHeight < Choices.ClientSize.Y then
    begin
      ExtraHeight := (Choices.ClientSize.Y - ChoiceHeight) div Count;
      Child := Choices.FirstChild;
      Top := 0;
      while Child <> nil do
      begin
        (Child as TLabelGI).SetTextAlignY(tayCenterEx);
        Child.SetPosition(Point(Child.LocalPosition.X, Top));
        Child.SetSize(Point(Child.ClientSize.X, Child.ClientSize.Y + ExtraHeight));
        Inc(Top, Child.ClientSize.Y);
        Child := Child.NextSibling;
      end;
      Choices.VerticalScrollBar.SetActive(False);
      Choices.SetScrollOffset(Point(0, 0));
      Choices.SetDragScrollingEnabled(False);
    end
    else
    begin
      Choices.SetScrollOffset(Point(0, 0));
      Choices.VerticalScrollBar.SetActive(True);
      Choices.SetDragScrollingEnabled(True);
      Choices.UpdateScrollRanges;
    end;
    Choices.VerticalScrollBar.SetSmallChange((GetByName('TalkText') as TLabelGI).GetLineHeight);
    Choices.VerticalScrollBar.SetLargeChange(Choices.ClientSize.Y);
    Choices.VerticalScrollBar.SetPageSize(Choices.ClientSize.Y);
    if TextPresentationTimer <> 0 then
    begin
      CancelCallbackTimer(TextPresentationTimer);
      TextPresentationTimer := 0;
    end;
  end
  else
  begin
    DialogText := DialogueLinePrefix + TrimWideString(DialogText);
    DialogText := ReplaceAllWideString(DialogText, #13#10, #13#10 + DialogueLinePrefix);
    PresentedTextLength := Length(DialogText);
    (GetByName('TalkText') as TLabelGI).SetText(DialogText);
    TextPanel := GetByName('TextScroll') as TPanelScrollBarGI;
    TextPanel.SetScrollOffset(Point(0, 0));
    TextPanel.UpdateScrollRanges;
    TextPanel.VerticalScrollBar.SetActive((TextPanel.FindByNameRecursive('TalkText') as TLabelGI).ClientSize.Y > TextPanel.ClientSize.Y);
    TextPanel.VerticalScrollBar.SetSmallChange((TextPanel.FindByNameRecursive('TalkText') as TLabelGI).GetLineHeight);
    TextPanel.VerticalScrollBar.SetLargeChange(TextPanel.ClientSize.Y);
    TextPanel.VerticalScrollBar.SetPageSize(TextPanel.ClientSize.Y);
  end;
end;
{ @end $575768 }

{ @routine $575B08 TfGov_ProcessMouseWheel }
procedure TfGov.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  with GetByName('TextScroll') as TPanelScrollBarGI do
    if Delta = 120 then VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.SmallChange)
    else if Delta = -120 then VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.SmallChange);
end;
{ @end $575B08 }

{ @routine $575B90 TfGov_MainPanelKeyDown }
procedure TfGov.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) or (ExitCode <> 0) then Exit;
  if Key = VK_SPACE then EndTurnClicked(nil)
  else if Key = Ord('S') then ShipClicked(nil)
  else
  begin
    MainPanel.ProcessKeyDown(Key);
    PlanetPanel.ProcessKeyDown(Key);
  end;
end;
{ @end $575B90 }

{ @routine $575C04 TfGov_AddMessageClicked }
procedure TfGov.AddMessageClicked(Sender: TObjectGI);
var Text: WideString;
begin
  Text := (GetByName('TalkText') as TLabelGI).GetText;
  SoundManager.PlaySound('Sound.UserMsgAdd');
  AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Text, '');
  MainPanel.RebuildMessageButtons;
  BreakUiMessage;
end;
{ @end $575C04 }

{ @routine $575CD4 TfGov_SelectMusic }
procedure TfGov.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
end;
{ @end $575CD4 }

{ @routine $575D6C TfGov_BuildGreeting }
procedure TfGov.BuildGreeting;
begin
  if Player.InPrison then
  begin
    DialogText := LocalizedColorText('FormGov.Prison.GovAfterPrison');
    ClearDialogChoices;
    AddChoice('- ' + LocalizedColorText('FormGov.I_Continue'), 0, ContinueAfterPrison);
  end
  else if Player.CurrentPlanet.GetRelationLevelToShip(Player) = rlHostile then
  begin
    DialogText := LocalizedColorText('FormGov.Prison.GovBeforePrison');
    ClearDialogChoices;
    AddChoice('- ' + LocalizedColorText('FormGov.Prison.PlayerGoToPrison'), 0, EnterPrison);
  end
  else if Player.CurrentPlanet = Player.PendingLiberationCeremonyPlanet then
  begin
    DialogText := Player.CollectLiberationRewards;
    ClearDialogChoices;
    AddChoice('- ' + LocalizedColorText('FormGov.PlayerAfterCongratulationsLiberator'), 0, ContinueAfterLiberation);
  end
  else
  begin
    DialogText := Player.CurrentPlanet.BuildGovernmentGreeting;
    BuildGovernmentChoices;
  end;
end;
{ @end $575D6C }

{ @routine $57607C TfGov_BuildGovernmentChoices }
procedure TfGov.BuildGovernmentChoices;
var Response: WideString; Script: TScript;
begin
  ClearDialogChoices;
  Player.CurrentPlanet.CollectScriptDialogChoices(ScriptDialogNames);
  ScriptDialogCursor := 0;
  Script := nil;
  ScriptDialogIndex := -1;
  while ScriptDialogCursor < ScriptDialogNames.GetCount do
  begin
    Script := TScript(ScriptDialogNames.GetDataAt(ScriptDialogCursor));
    Script.CallDialog(Script.InitCode.LocalVar.GetVar(ScriptDialogNames.GetTextAt(ScriptDialogCursor)).GetInt);
    if ScriptDialogIndex >= 0 then Break;
    Inc(ScriptDialogCursor);
  end;
  if Player.TryTurnInAnyQuest(Response) then DialogText := Response;
  if ScriptDialogIndex < 0 then BuildBuiltinChoices
  else if not Script.SkipGreeting then
    AddChoice('- ' + LocalizedColorText('FormGov.I_Continue'), Integer(Script), StartScriptMessage)
  else StartScriptMessage(Integer(Script));
end;
{ @end $57607C }

{ @routine $576200 TfGov_BuildBuiltinChoices }
procedure TfGov.BuildBuiltinChoices;
var I: Integer;
begin
  AddChoice('- ' + LocalizedColorText('FormGov.I_QueryQuest'), 0, RequestQuest);
  if Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlNormal then
    AddChoice('- ' + LocalizedColorText('FormGov.Bribe.I_Bribe'), 0, ShowBribeOffer);
  if Player.CurrentPlanet.FindUnchartedNeighborConstellation <> nil then
    AddChoice('- ' + LocalizedColorText('FormGov.BuyMap.I_BuyMap'), 0, ShowMapOffer);
  for I := 0 to Player.StorageEntries.Count - 1 do
    if PStorageEntry(Player.StorageEntries[I]).Planet = Player.CurrentPlanet then
    begin
      AddChoice('- ' + LocalizedText('FormGov.Storage.I_StorageExtract'), 0, RetrieveStoredItems);
      Break;
    end;
  AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
end;
{ @end $576200 }

{ @routine $5764B4 TfGov_ContinueScriptDialog }
procedure TfGov.ContinueScriptDialog;
var Script: TScript;
begin
  ScriptDialogIndex := -1;
  Inc(ScriptDialogCursor);
  Script := nil;
  while ScriptDialogCursor < ScriptDialogNames.GetCount do
  begin
    Script := TScript(ScriptDialogNames.GetDataAt(ScriptDialogCursor));
    Script.CallDialog(Script.InitCode.LocalVar.GetVar(ScriptDialogNames.GetTextAt(ScriptDialogCursor)).GetInt);
    if ScriptDialogIndex >= 0 then Break;
    Inc(ScriptDialogCursor);
  end;
  if ScriptDialogIndex < 0 then
    AddChoice('- ' + LocalizedColorText('FormGov.I_Continue'), 0, FinishScriptDialog)
  else AddChoice('- ' + LocalizedColorText('FormGov.I_Continue'), Integer(Script), StartScriptMessage);
end;
{ @end $5764B4 }

{ @routine $576610 TfGov_AddScriptTakeoffChoice }
procedure TfGov.AddScriptTakeoffChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptTakeoff);
end;
{ @end $576610 }

{ @routine $576694 TfGov_AddScriptPlanetChoice }
procedure TfGov.AddScriptPlanetChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptPlanetAnswer);
end;
{ @end $576694 }

{ @routine $576718 TfGov_AddScriptGoodsChoice }
procedure TfGov.AddScriptGoodsChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptGoodsAnswer);
end;
{ @end $576718 }

{ @routine $57679C TfGov_AddScriptShopChoice }
procedure TfGov.AddScriptShopChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptShopAnswer);
end;
{ @end $57679C }

{ @routine $576820 TfGov_BuildQuestOfferChoices }
procedure TfGov.BuildQuestOfferChoices;
begin
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormGov.I_QuestAccept'), 0, AcceptQuest);
  AddChoice('- ' + LocalizedColorText('FormGov.I_QuestReject'), 0, RejectQuest);
  AddChoice('- ' + LocalizedColorText('FormGov.I_QuestEasy'), 0, MakeQuestEasier);
  AddChoice('- ' + LocalizedColorText('FormGov.I_QuestDifficult'), 0, MakeQuestHarder);
  AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
end;
{ @end $576820 }

{ @routine $576A50 TfGov_StartScriptMessage }
procedure TfGov.StartScriptMessage(Action: Integer);
begin
  ClearDialogChoices;
  CurrentScript := TScript(Action);
  CurrentScript.CallDialogMessage(ScriptDialogIndex);
end;
{ @end $576A50 }

{ @routine $576A78 TfGov_RunScriptAnswer }
procedure TfGov.RunScriptAnswer(Answer: Integer);
begin
  ClearDialogChoices;
  ScriptDialogIndex := -1;
  CurrentScript.ExecuteDialogAnswer(Answer);
  if ScriptDialogIndex < 0 then RaiseWideMessage('I_Script');
  CurrentScript.CallDialogMessage(ScriptDialogIndex);
end;
{ @end $576A78 }

{ @routine $576ADC TfGov_FinishScriptDialog }
procedure TfGov.FinishScriptDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormGov.GovAfterScript');
  ClearDialogChoices;
  BuildBuiltinChoices;
end;
{ @end $576ADC }

{ @routine $576B70 TfGov_RunScriptTakeoff }
procedure TfGov.RunScriptTakeoff(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  HangarScreen.PrepareTakeoff;
  RequestClose(1);
end;
{ @end $576B70 }

{ @routine $576B9C TfGov_RunScriptPlanetAnswer }
procedure TfGov.RunScriptPlanetAnswer(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  RequestedScreenId := screenPlanet;
  RequestClose(1);
end;
{ @end $576B9C }

{ @routine $576BC4 TfGov_RunScriptGoodsAnswer }
procedure TfGov.RunScriptGoodsAnswer(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  RequestedScreenId := screenGoodsShop;
  RequestClose(1);
end;
{ @end $576BC4 }

{ @routine $576BEC TfGov_RunScriptShopAnswer }
procedure TfGov.RunScriptShopAnswer(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  RequestedScreenId := screenEquipmentShop;
  RequestClose(1);
end;
{ @end $576BEC }

{ @routine $576C14 TfGov_EnterPrison }
procedure TfGov.EnterPrison(Action: Integer);
var I: Integer; Ship: TShip;
begin
  CaptureSavePreview;
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
  Player.InPrison := True;
  Player.CurrentPlanet.ChangeRelationToRanger(Player, 80);
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 20, CoalitionOwners);
  for I := 0 to Player.CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(Player.CurrentStar.Ships[I]);
    if (Ship.ShipType = t_Warrior) and (Ship.EnemyShip = Player) then
    begin
      Ship.EnemyShip := nil;
      if Ship.OrderTarget = Player then Ship.OrderNone;
    end;
  end;
  StandaloneQuestMode := False;
  PlanetQuestReturnScreenId := FormToId(Self);
  RequestedScreenId := screenPlanetQuest;
  RequestClose(1);
end;
{ @end $576C14 }

{ @routine $576D6C TfGov_ContinueAfterPrison }
procedure TfGov.ContinueAfterPrison(Action: Integer);
begin
  Player.InPrison := False;
  DialogText := LocalizedColorText('FormGov.Prison.GovAfterPrisonNext');
  BuildGovernmentChoices;
end;
{ @end $576D6C }

{ @routine $576E1C TfGov_ShowBribeOffer }
procedure TfGov.ShowBribeOffer(Action: Integer);
var Text: WideString; Price: Integer;
begin
  Price := 100 - (Player.CurrentPlanet.RelationToShip(Player));
  Price := Round((Galaxy.AverageRangerCapital div 100) *
    RemapClamped(Price, 0, 100, 1, 5) * OwnerInfo[Player.CurrentPlanet.OwnerId].FuelPriceFactor);
  Text := LocalizedColorText('FormGov.Bribe.Question');
  ReplaceTextToken(Text, '<Money>', IntToStr(Price), HighlightColorTag);
  DialogText := Text;
  ClearDialogChoices;
  if Price <= Player.Money then
    AddChoice('- ' + FormatText2(LocalizedColorText('FormGov.Bribe.Ok'), HighlightColorTag,
      '<Money>', IntToStr(Price), '<Planet>', Player.CurrentPlanet.Name), 0, PayBribe);
  AddChoice('- ' + LocalizedColorText('FormGov.Bribe.No'), 0, DeclineBribe);
end;
{ @end $576E1C }

{ @routine $577100 TfGov_PayBribe }
procedure TfGov.PayBribe(Action: Integer);
var Price: Integer;
begin
  Price := 100 - (Player.CurrentPlanet.RelationToShip(Player));
  Price := Round((Galaxy.AverageRangerCapital div 100) *
    RemapClamped(Price, 0, 100, 1, 5) * OwnerInfo[Player.CurrentPlanet.OwnerId].FuelPriceFactor);
  Player.SetMoney(Player.Money - Price);
  SoundManager.PlaySound('Sound.Sell');
  Player.CurrentPlanet.ChangeRelationToRanger(Player, 100);
  Player.ChangePlanetRelations(Player.CurrentStar, rcmIncrease, 20, [oiMaloc..oiGaal]);
  DialogText := LocalizedColorText('FormGov.Bribe.QuestionOk');
  ReplaceTextToken(DialogText, '<Money>', IntToStr(Price), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag);
  ClearDialogChoices;
  BuildBuiltinChoices;
end;
{ @end $577100 }

{ @routine $577338 TfGov_DeclineBribe }
procedure TfGov.DeclineBribe(Action: Integer);
begin
  DialogText := LocalizedColorText('FormGov.Bribe.QuestionNo');
  ClearDialogChoices;
  BuildBuiltinChoices;
end;
{ @end $577338 }

{ @routine $5773D0 TfGov_RequestQuest }
procedure TfGov.RequestQuest(Action: Integer);
var ResponseText: WideString;
begin
  if not Player.GenerateQuestOffer(QuestOffer, ResponseText) then
  begin
    DialogText := ResponseText;
    ClearDialogChoices;
    BuildBuiltinChoices;
  end
  else
  begin
    QuestNegotiationLevel := 0;
    DialogText := Player.BuildQuestText(QuestOffer, False);
    if (QuestOffer.QuestType = qtPlanetQuest) and (QuestOffer.QuestNumber >= 10000) then
      if (LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') <= 0) or
        (LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuestLic').GetParamOrMarker(WideString(IntToStr(QuestOffer.QuestNumber))) <>
          PlanetQuestScreen.GetQuestContentHash(QuestOffer.QuestNumber)) then
        DialogText := DialogText + #13#10 + ' ' + #13#10 + LocalizedText('FormGov.QuestCertificate.NotCertificate');
    QuestRewardStep := Round(QuestOffer.RewardMoney * 0.3);
    QuestDurationStep := Round((QuestOffer.DeadlineTurn - Galaxy.CurrentTurn) * 0.5);
    BuildQuestOfferChoices;
  end;
end;
{ @end $5773D0 }

{ @routine $577668 TfGov_MakeQuestEasier }
procedure TfGov.MakeQuestEasier(Action: Integer);
begin
  Dec(QuestNegotiationLevel);
  case QuestOffer.QuestType of
    qtSendLetter..qtPlanetQuest: Inc(QuestOffer.DeadlineTurn, QuestDurationStep);
    qtDefendSystem..qtDefendShip: Dec(QuestOffer.DeadlineTurn, QuestDurationStep);
  end;
  Dec(QuestOffer.RewardMoney, QuestRewardStep);
  DialogText := LocalizedColorText('FormGov.CheckQuest.Easy') + #13#10 + Player.BuildQuestText(QuestOffer, False);
  if QuestNegotiationLevel <= -1 then
  begin
    ClearDialogChoices;
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestAccept'), 0, AcceptQuest);
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestReject'), 0, RejectQuest);
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestDifficult'), 0, MakeQuestHarder);
    AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
  end
  else BuildQuestOfferChoices;
end;
{ @end $577668 }

{ @routine $57790C TfGov_MakeQuestHarder }
procedure TfGov.MakeQuestHarder(Action: Integer);
begin
  Inc(QuestNegotiationLevel);
  case QuestOffer.QuestType of
    qtSendLetter..qtPlanetQuest: Dec(QuestOffer.DeadlineTurn, QuestDurationStep);
    qtDefendSystem..qtDefendShip: Inc(QuestOffer.DeadlineTurn, QuestDurationStep);
  end;
  Inc(QuestOffer.RewardMoney, QuestRewardStep);
  DialogText := LocalizedColorText('FormGov.CheckQuest.Difficult') + #13#10 + Player.BuildQuestText(QuestOffer, False);
  if QuestNegotiationLevel >= 1 then
  begin
    ClearDialogChoices;
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestAccept'), 0, AcceptQuest);
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestReject'), 0, RejectQuest);
    AddChoice('- ' + LocalizedColorText('FormGov.I_QuestEasy'), 0, MakeQuestEasier);
    AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
  end
  else BuildQuestOfferChoices;
end;
{ @end $57790C }

{ @routine $577BB0 TfGov_AcceptQuest }
procedure TfGov.AcceptQuest(Action: Integer);
var Quest: PQuest; Item: TUselessItem;
begin
  New(Quest);
  Quest^ := QuestOffer;
  Quest.Description := Player.BuildQuestText(Quest^, False);
  Quest.CompletionText := Player.BuildQuestText(Quest^, True);
  Player.Quests.Add(Quest);
  Player.PublishQuestStatus(Quest, 0);
  if Quest.QuestType = qtSendLetter then
  begin
    Item := TUselessItem.Create;
    Item.Init(LookupLocalizedTextByKey(WideString('Quest.SendLetter.' + IntToStr(Quest.QuestNumber) + '.SysName')), 0);
    Player.Inventory.Add(Item);
  end;
  DialogText := LocalizedColorText('FormGov.AfterPlayerTakeQuest');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
end;
{ @end $577BB0 }

{ @routine $577E00 TfGov_RejectQuest }
procedure TfGov.RejectQuest(Action: Integer);
begin
  DialogText := LocalizedColorText('FormGov.PlayerDontTakeQuest');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormGov.I_Exit'), 0, ExitGovernment);
end;
{ @end $577E00 }

{ @routine $577F00 TfGov_ShowMapOffer }
procedure TfGov.ShowMapOffer(Action: Integer);
var Price: Integer;
begin
  Price := RoundAndTruncateToTens(50 + Min(Player.Wealth div 40, Galaxy.ComputeScaledBigMoney(Player.CurrentPlanet.OwnerId)));
  DialogText := FormatText2(LocalizedColorText('FormGov.BuyMap.GovAsk'), HighlightColorTag,
    '<Name>', (Player.CurrentPlanet.FindUnchartedNeighborConstellation as TConstellation).GetName,
    '<Money>', IntToStr(Price));
  ClearDialogChoices;
  if Price <= Player.Money then
    AddChoice('- ' + LocalizedColorText('FormGov.BuyMap.PlayerOk'), 0, BuyMap);
  AddChoice('- ' + LocalizedColorText('FormGov.BuyMap.PlayerNO'), 0, DeclineMapOffer);
end;
{ @end $577F00 }

{ @routine $578188 TfGov_BuyMap }
procedure TfGov.BuyMap(Action: Integer);
begin
  Player.SetMoney(Player.Money - RoundAndTruncateToTens(50 +
    Min(Player.Wealth div 40, Galaxy.ComputeScaledBigMoney(Player.CurrentPlanet.OwnerId))));
  (Player.CurrentPlanet.FindUnchartedNeighborConstellation as TConstellation).Visible := True;
  SoundManager.PlaySound('Sound.Sell');
  DialogText := LocalizedColorText('FormGov.BuyMap.GovAfterOk');
  ClearDialogChoices;
  BuildBuiltinChoices;
end;
{ @end $578188 }

{ @routine $5782D8 TfGov_DeclineMapOffer }
procedure TfGov.DeclineMapOffer(Action: Integer);
begin
  DialogText := LocalizedColorText('FormGov.BuyMap.GovAfterNo');
  ClearDialogChoices;
  BuildBuiltinChoices;
end;
{ @end $5782D8 }

{ @routine $578370 TfGov_ExitGovernment }
procedure TfGov.ExitGovernment(Action: Integer);
begin
  RequestedScreenId := screenPlanet;
  RequestClose(1);
end;
{ @end $578370 }

{ @routine $578384 TfGov_ContinueAfterLiberation }
procedure TfGov.ContinueAfterLiberation(Action: Integer);
begin
  RequestedScreenId := screenPlanet;
  RequestClose(1);
end;
{ @end $578384 }

{ @routine $578398 TfGov_RetrieveStoredItems }
procedure TfGov.RetrieveStoredItems(Action: Integer);
var I, J, N: Integer; Entry: PStorageEntry; Item: TItem; EntryPointer: Pointer;
begin
  I := 0;
  while Player.StorageEntries.Count > I do
  begin
    EntryPointer := Player.StorageEntries[I];
    Entry := PStorageEntry(EntryPointer);
    if Entry.Planet = Player.CurrentPlanet then
    begin
      Item := Entry.Item;
      if Item is TArtefact then
      begin
        (Item as TEquipment).EquippedFlag := False;
        Player.Artefacts.Add(Item);
        if Item is TArtefactTranclucator then
          ((Item as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Player;
      end
      else if Item is TProtoplasm then
      begin
        TProtoplasm(Item).DropFlag := 0;
        Item.ReleaseGraphObject;
        (Item as TEquipment).EquippedFlag := False;
        N := Player.Inventory.Count;
        J := 0;
        while J < N do
        begin
          if TItem(Player.Inventory[J]).ItemType = t_Protoplasm then Break;
          Inc(J);
        end;
        if J < N then
        begin
          Inc(TProtoplasm(Player.Inventory[J]).Quantity, TProtoplasm(Item).Quantity);
          Inc(TItem(Player.Inventory[J]).Weight, Item.Weight);
          TItem(Player.Inventory[J]).Cost := 10 * TProtoplasm(Player.Inventory[J]).Quantity;
          Item.Free;
        end
        else Player.Inventory.Add(Item);
      end
      else if Item is TEquipment then
      begin
        (Item as TEquipment).EquippedFlag := False;
        Player.Inventory.Add(Item);
      end
      else if Item is TGoods then
      begin
        Inc(Player.CargoGoods[(Item as TGoods).ItemType].Count, (Item as TGoods).Quantity);
        Inc(Player.CargoGoods[(Item as TGoods).ItemType].TotalCost, (Item as TGoods).Cost);
        Item.Free;
      end;
      Player.StorageEntries.Delete(I);
      Entry.Planet := nil;
      Entry.Item := nil;
      Dispose(Entry);
    end
    else Inc(I);
  end;
  Player.RefreshDerivedStats;
  BuildGreeting;
  Player.RefreshStorageMessage;
  MainPanel.RefreshMoneyAndCargo;
  MainPanel.RebuildMessageButtons;
end;
{ @end $578398 }

end.

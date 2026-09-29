unit fRuinsTalk;
// Unit bracket (inferred): CODE 0x005237C0..0x0052B837; inclusive evidence, not full bounds.
// Station services and dialogue choices; native VMT $5237C0.
interface
uses GI_MessageLoop, Types, fPanelMain, fPanelRuins;
type
  TfRuinsTalk = class(TMessageLoopGI) // @size $D4
  public
    procedure RunScriptTakeoff(Answer: Integer); // @addr $5262D4
    procedure RunScriptNewsExit(Answer: Integer); // @addr $5262F4
    MainPanel: TfPanelMain; // @offset $B0
    StationPanel: TfPanelRuins; // @offset $B4
    DialogText: WideString; // @offset $B8
    PresentedTextLength: Integer; // @offset $BC
    TextPresentationTimer: TCallbackTimerIdGI; // @offset $C0
    ChoiceHeight: Integer; // @offset $C4
    NextPortraitCycleAlternate: Boolean; // @offset $C8
    PortraitOffsetY: Integer; // @offset $CC Gaal science-base portrait is shifted by 100 pixels.
    PortraitOwner: TOwnerId; // @offset $D0 Saved for restoring the portrait position on close.
    procedure AddScriptTakeoffChoice(Text: WideString); // @addr $525FAC
    procedure ContinueScriptDialog; // @addr $525EF8
    procedure AddScriptNewsExitChoice(Text: WideString); // @addr $5260A0
    procedure AddScriptGameEndChoice(Text: WideString); // @addr $526124
    procedure RunScriptAnswer(Answer: Integer); // @addr $5261D0
    procedure ShowRangerCenterRatingAnswer(Action: Integer); // @addr $526530
    procedure ShowRangerCenterBestRangerAnswer(Action: Integer); // @addr $5265D0
    procedure DeclinePirateBaseNationality(Action: Integer); // @addr $5275F0
    procedure DeclinePirateBaseNodes(Action: Integer); // @addr $527E70
    procedure DeclinePirateBaseRepair(Action: Integer); // @addr $52850C
    procedure DeclineMilitaryBaseRepair(Action: Integer); // @addr $5297FC
    procedure DeclineScienceBaseImprovement(Action: Integer); // @addr $529EC8
    procedure DeclineScienceBaseRepeatImprovement(Action: Integer); // @addr $52AB1C
    procedure DeclineScienceBaseRepair(Action: Integer); // @addr $52B244
    procedure ChangeNationalityMaloc(Action: Integer); // @addr $526F04
    procedure ChangeNationalityPeleng(Action: Integer); // @addr $527068
    procedure ChangeNationalityPeople(Action: Integer); // @addr $5271CC
    procedure ChangeNationalityFei(Action: Integer); // @addr $527330
    procedure ChangeNationalityGaal(Action: Integer); // @addr $527490
    procedure ShowPirateBaseNationalityDialog(Action: Integer); // @addr $526678
    procedure ShowScienceBaseImprovementDialog(Action: Integer); // @addr $52989C
    procedure ShowMilitaryBaseRepairDialog(Action: Integer); // @addr $52918C
    procedure ShowScienceBaseRepairDialog(Action: Integer); // @addr $52ABD4
    procedure SelectScriptDialog(Script: Integer); // @addr $5261A8
    procedure RunScriptAnswerReturnToMain(Answer: Integer); // @addr $526234
    procedure RunScriptGameEnd(Answer: Integer); // @addr $526314
    procedure ClearDialogChoices; // @addr $524080
    procedure AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI); // @addr $5240D8
    procedure ChoiceMouseEnter(Sender: TObjectGI); // @addr $524244
    procedure ChoiceMouseLeave(Sender: TObjectGI); // @addr $524270
    procedure ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5242A0
    procedure RestartTextPresentation; // @addr $5242F4
    procedure ResetPortraitCycle; // @addr $524714
    procedure PortraitCycleComplete(Sender: TObjectGI); // @addr $52471C
    procedure BuildBuiltinServiceOptions; // @addr $525650
    procedure BuildPirateBaseNationalityChoices(Action: Integer); // @addr $526864
    procedure ShowScienceBaseImprovementItems(Action: Integer); // @addr $5299D0
    procedure ShowMilitaryBaseRepairQuote(Action: Integer); // @addr $529310
    procedure ShowScienceBaseRepairQuote(Action: Integer); // @addr $52AD58
    procedure DepositNodesAtRangerCenter(Action: Integer); // @addr $526344
    procedure ShowPirateBaseNodeDialog(Action: Integer); // @addr $5276A8
    procedure ShowPirateBaseRepairDialog(Action: Integer); // @addr $527F18
    procedure ShowMilitaryCombatAdvice(Action: Integer); // @addr $5285AC
    procedure ShowMilitaryBaseNextRankDialog(Action: Integer); // @addr $528C1C
    procedure ShowCommunicatorResearchDialog(Action: Integer); // @addr $52B2E4
    procedure BuyCommunicator(Action: Integer); // @addr $52B698
    procedure AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $524374
    procedure SelectPortraitAnimation(Alternate: Boolean); // @addr $524748
    procedure SelectMusic; override; // @addr $524AA4
    constructor Create; // @addr $52385C
    destructor Destroy; override; // @addr $5238B8
    procedure AddMessageClicked(Sender: TObjectGI); // @addr $5249D4
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $5248DC
    procedure AcceptMilitaryBaseRepair(Action: Integer); // @addr $529708
    procedure AcceptScienceBaseRepair(Action: Integer); // @addr $52B150
    procedure AcceptPirateBaseRepair(Action: Integer); // @addr $52834C
    procedure BuyPirateBaseNodes(Action: Integer); // @addr $527C14
    procedure OnClose; override; // @addr $523E94
    procedure ShowGreeting; // @addr $524B3C
    procedure BuildGreeting; // @addr $524B44
    procedure InitializeLayout; override; // @addr $52390C
    procedure OnOpen; override; // @addr $523A34
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $524000
    procedure ShipClicked(Sender: TObjectGI); // @addr $524044
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $524964
    procedure ShowScienceBaseImprovementQuote(Action: Integer); // @addr $529F80
    procedure AcceptScienceBaseImprovementMax(Action: Integer); // @addr $52A460
    procedure AcceptScienceBaseImprovementAverage(Action: Integer); // @addr $52A684
    procedure AcceptScienceBaseImprovementMin(Action: Integer); // @addr $52A8B0
  end;
implementation

// @unit-initialization $52B830
// @unit-finalization $52B800

uses aScript, Classes, SysUtils, GR_Main, aConst, aGalaxy, aPlayer, aMyFunction, GlobalsV,
  GI_Label, GI_PanelScrollBar, fTalk, Globals, aRuins, aRuinsWB, aRuinsSB, aRuinsPB, aItem, Math, EC_Str, GI_GAI, GI_Image, GI_GraphButton, fEquipmentShop, fShip2, aScriptFun, Windows;
{ @routine $52385C TfRuinsTalk_Create }
constructor TfRuinsTalk.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  StationPanel := TfPanelRuins.Create;
end;
{ @end $52385C }

{ @routine $5238B8 TfRuinsTalk_Destroy }
destructor TfRuinsTalk.Destroy;
begin
  if MainPanel <> nil then
  begin
    MainPanel.Free;
    MainPanel := nil;
  end;
  if StationPanel <> nil then
  begin
    StationPanel.Free;
    StationPanel := nil;
  end;
  inherited Destroy;
end;
{ @end $5238B8 }

{ @routine $52390C TfRuinsTalk_InitializeLayout }
procedure TfRuinsTalk.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  StationPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('UserMsgAdd') as TGraphButtonGI).UpCallback := AddMessageClicked;
end;
{ @end $52390C }

{ @routine $523A34 TfRuinsTalk_OnOpen }
procedure TfRuinsTalk.OnOpen;
var Owner: TOwnerId;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  PortraitOwner := Player.DockedTo.OwnerId;
  MainPanel.OnOpen;
  StationPanel.OnOpen;
  if TemporaryShopSlots = nil then
  begin
    SelectMusic;
    RunStarTransitionScript(Player.CurrentStar, 0);
    PruneExpiredPersistentPlayerMessages;
    BuildTemporaryShopSlotGrid;
  end;
  Galaxy.ReleaseItemGraphics;
  ShowGreeting;
  RestartTextPresentation;
  (GetByName('TalkPA') as TPanelScrollBarGI).SetVerticalScrollbarEnabled(False);
  with GetByName('ImageBG') as TImageGI do
    if Player.DockedTo.ShipType = t_RangerCenter then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'RCbg')
    else if Player.DockedTo.ShipType = t_PirateBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'PBbg')
    else if Player.DockedTo.ShipType = t_MilitaryBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'WBbg')
    else if Player.DockedTo.ShipType = t_ScientificBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'SBbg');
  PortraitOffsetY := 0;
  if (Player.DockedTo.OwnerId = oiGaal) and (Player.DockedTo.ShipType = t_ScientificBase) then PortraitOffsetY := 100;
  for Owner := oiMaloc to oiGaal do
    if FindControlByPath('Panel' + OwnerInfo[Owner].InternalName) <> nil then
      GetByName('Panel' + OwnerInfo[Owner].InternalName).SetActive(Owner = Player.DockedTo.OwnerId);
  with GetByName('Panel' + OwnerInfo[Player.DockedTo.OwnerId].InternalName + '_Anim0') as TgaiGI do
  begin
    SetPosition(Point(LocalPosition.X, LocalPosition.Y + PortraitOffsetY));
    FirstFrameOnly := not AnimGov;
    PreloadImages;
  end;
  with GetByName('Panel' + OwnerInfo[Player.DockedTo.OwnerId].InternalName + '_Anim1') as TgaiGI do
  begin
    SetPosition(Point(LocalPosition.X, LocalPosition.Y + PortraitOffsetY));
    FirstFrameOnly := not AnimGov;
    PreloadImages;
  end;
  SelectPortraitAnimation(True);
  NextPortraitCycleAlternate := False;
  MainPanel.RebuildMessageButtons;
end;
{ @end $523A34 }

{ @routine $523E94 TfRuinsTalk_OnClose }
procedure TfRuinsTalk.OnClose;
var Animation: TgaiGI;
begin
  Animation := GetByName('Panel' + OwnerInfo[PortraitOwner].InternalName + '_Anim0') as TgaiGI;
  Animation.SetPosition(Point(Animation.LocalPosition.X, Animation.LocalPosition.Y - PortraitOffsetY));
  Animation := GetByName('Panel' + OwnerInfo[PortraitOwner].InternalName + '_Anim1') as TgaiGI;
  Animation.SetPosition(Point(Animation.LocalPosition.X, Animation.LocalPosition.Y - PortraitOffsetY));
  ScriptDialogIndex := -1;
  ClearDialogChoices;
  MainPanel.OnClose;
  StationPanel.OnClose;
end;
{ @end $523E94 }

{ @routine $524000 TfRuinsTalk_EndTurnClicked }
procedure TfRuinsTalk.EndTurnClicked(Sender: TObjectGI);
begin
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  if ExitCode = 0 then
  begin
    BuildTemporaryShopSlotGrid;
    ShowGreeting;
    RestartTextPresentation;
    MainPanel.RebuildMessageButtons;
  end;
end;
{ @end $524000 }

{ @routine $524044 TfRuinsTalk_ShipClicked }
procedure TfRuinsTalk.ShipClicked(Sender: TObjectGI);
begin
  MainPanel.ShipClicked(Sender);
  if ShipScreen.RefreshStationDialog then
  begin
    ShowGreeting;
    RestartTextPresentation;
    MainPanel.RebuildMessageButtons;
  end;
end;
{ @end $524044 }

{ @routine $524080 TfRuinsTalk_ClearDialogChoices }
procedure TfRuinsTalk.ClearDialogChoices;
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
{ @end $524080 }

{ @routine $5240D8 TfRuinsTalk_AddChoice }
procedure TfRuinsTalk.AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI);
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
{ @end $5240D8 }

{ @routine $524244 TfRuinsTalk_ChoiceMouseEnter }
procedure TfRuinsTalk.ChoiceMouseEnter(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 245, 80));
end;
{ @end $524244 }

{ @routine $524270 TfRuinsTalk_ChoiceMouseLeave }
procedure TfRuinsTalk.ChoiceMouseLeave(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
end;
{ @end $524270 }

{ @routine $5242A0 TfRuinsTalk_ChoiceMouseDown }
procedure TfRuinsTalk.ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Choice: TfTalkA;
begin
  Choice := TfTalkA(Sender.UserValue);
  if Assigned(Choice.Callback) then Choice.Callback(Choice.Value)
  else if Assigned(Choice.FallbackCallback) then Choice.FallbackCallback(Choice.FallbackText);
  RestartTextPresentation;
  BreakUiMessage;
end;
{ @end $5242A0 }

{ @routine $5242F4 TfRuinsTalk_RestartTextPresentation }
procedure TfRuinsTalk.RestartTextPresentation;
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
{ @end $5242F4 }

{ @routine $524374 TfRuinsTalk_AdvanceTextPresentation }
procedure TfRuinsTalk.AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
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
{ @end $524374 }

{ @routine $524714 TfRuinsTalk_ResetPortraitCycle }
procedure TfRuinsTalk.ResetPortraitCycle;
begin
  NextPortraitCycleAlternate := True;
end;
{ @end $524714 }

{ @routine $52471C TfRuinsTalk_PortraitCycleComplete }
procedure TfRuinsTalk.PortraitCycleComplete(Sender: TObjectGI);
begin
  if NextPortraitCycleAlternate then
  begin
    SelectPortraitAnimation(True);
    NextPortraitCycleAlternate := False;
  end
  else SelectPortraitAnimation(False);
end;
{ @end $52471C }

{ @routine $524748 TfRuinsTalk_SelectPortraitAnimation }
procedure TfRuinsTalk.SelectPortraitAnimation(Alternate: Boolean);
var Normal, AlternateAnimation: TgaiGI;
begin
  Normal := GetByName('Panel' + OwnerInfo[Player.DockedTo.OwnerId].InternalName + '_Anim0') as TgaiGI;
  Normal.CycleCompleteCallback := PortraitCycleComplete;
  Normal.SetSequenceFrame(0);
  Normal.StopAutoPlayback;
  if not Alternate then Normal.RestartPlayback else Normal.StopAutoPlayback;
  Normal.SetActive(not Alternate);
  AlternateAnimation := GetByName('Panel' + OwnerInfo[Player.DockedTo.OwnerId].InternalName + '_Anim1') as TgaiGI;
  AlternateAnimation.CycleCompleteCallback := PortraitCycleComplete;
  AlternateAnimation.SetSequenceFrame(0);
  AlternateAnimation.StopAutoPlayback;
  if Alternate then AlternateAnimation.RestartPlayback else AlternateAnimation.StopAutoPlayback;
  AlternateAnimation.SetActive(Alternate);
end;
{ @end $524748 }

{ @routine $5248DC TfRuinsTalk_ProcessMouseWheel }
procedure TfRuinsTalk.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  with GetByName('TextScroll') as TPanelScrollBarGI do
    if Delta = 120 then VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.SmallChange)
    else if Delta = -120 then VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.SmallChange);
end;
{ @end $5248DC }

{ @routine $524964 TfRuinsTalk_MainPanelKeyDown }
procedure TfRuinsTalk.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = VK_SPACE then EndTurnClicked(nil)
  else if Key = Ord('S') then ShipClicked(nil)
  else
  begin
    MainPanel.ProcessKeyDown(Key);
    StationPanel.ProcessKeyDown(Key);
  end;
end;
{ @end $524964 }

{ @routine $5249D4 TfRuinsTalk_AddMessageClicked }
procedure TfRuinsTalk.AddMessageClicked(Sender: TObjectGI);
var Text: WideString;
begin
  Text := (GetByName('TalkText') as TLabelGI).GetText;
  SoundManager.PlaySound('Sound.UserMsgAdd');
  AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Text, '');
  MainPanel.RebuildMessageButtons;
  BreakUiMessage;
end;
{ @end $5249D4 }

{ @routine $524AA4 TfRuinsTalk_SelectMusic }
procedure TfRuinsTalk.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
end;
{ @end $524AA4 }

{ @routine $524B3C TfRuinsTalk_ShowGreeting }
procedure TfRuinsTalk.ShowGreeting;
begin
  BuildGreeting;
end;
{ @end $524B3C }

{ @routine $524B44 TfRuinsTalk_BuildGreeting }
procedure TfRuinsTalk.BuildGreeting;
var Name: WideString; Script: TScript; Types: TItemTypeMask; Item: TEquipment;
begin
  ClearDialogChoices;
  ScriptDialogIndex := -1;
  Script := nil;
  if Player.DockedTo.ScriptShip <> nil then
  begin
    Script := TScriptShip(Player.DockedTo.ScriptShip).Script;
    Name := TScriptShip(Player.DockedTo.ScriptShip).GetGroup.DialogVariableName;
    if Name <> '' then Script.CallDialog(Script.InitCode.LocalVar.GetVar(Name).GetInt);
  end;
  case Player.DockedTo.ShipType of
    t_RangerCenter:
    begin
      Galaxy.RefreshRangerRatingPlaces;
      if Player.PlaceInRating = 1 then DialogText := LocalizedColorText('FormRuins.RC.GreetingBest')
      else
        case Player.PlaceInRating * (100 div Galaxy.Rangers.Count) of
          0..30: DialogText := LocalizedColorText('FormRuins.RC.GreetingGood');
          31..66: DialogText := LocalizedColorText('FormRuins.RC.GreetingNormal');
          67..100: DialogText := LocalizedColorText('FormRuins.RC.GreetingBad');
        end;
      ReplaceTextToken(DialogText, '<RC>', Player.DockedTo.Name, HighlightColorTag);
      ReplaceTextToken(DialogText, '<Number>', IntToStr(Player.PlaceInRating), HighlightColorTag);
    end;
    t_PirateBase:
    begin
      DialogText := LocalizedColorText('FormRuins.PB.Greeting');
      ReplaceTextToken(DialogText, '<PB>', Player.DockedTo.Name, HighlightColorTag);
    end;
    t_ScientificBase:
    begin
      DialogText := LocalizedColorText('FormRuins.SB.Greeting');
      if (not Player.HaveCommunicator) and (Galaxy.CommunicatorResearchProgress >= 100) then
        DialogText := DialogText + #13#10 + ' ' + #13#10 + FormatText1(LocalizedColorText('FormRuins.SB.Communicator.SBCreateCommunicator'), HighlightColorTag, '<CommunicatorCost>', IntToStr(GetCommunicatorCost));
      ReplaceTextToken(DialogText, '<SB>', Player.DockedTo.Name, HighlightColorTag);
    end;
    t_MilitaryBase:
    begin
      if Player.TryPromoteRank then
      begin
        DialogText := LocalizedColorText('FormRuins.WB.' + CoalitionRankNames[Player.Rank] + '.NewRank');
        if not Player.HaveHyperspaceLocator and
          ((Player.Rank = crCommander) or (Galaxy.GetFactionControlPercent(sfCoalition) > 75) or
          ((Player.PlaceInRating < 10) and (Player.Rank > crPilot))) then
        begin
          DialogText := DialogText + #13#10 + LocalizedColorText('FormRuins.WB.GiveHyperSpacePelengator');
          Player.HaveHyperspaceLocator := True;
        end;
        ReplaceTextToken(DialogText, '<PredPoints>', IntToStr(CoalitionRankPointThresholds[Pred(Player.Rank)]), HighlightColorTag);
        Types := RewardEquipmentTypes;
        Types := Types + Galaxy.SelectRandomWeaponTypes(Galaxy.TechLevel, 3, False, Player.DockedTo.Id * (Ord(Player.Rank) + 11) * (Galaxy.CurrentTurn div 50));
        Item := Player.CreateRandomEquipment(Types, False, scAverage, Round(RemapClamped(Ord(Player.Rank), 0, 6, 1, 5)), PortraitOwner, Player.DockedTo.Id * (Ord(Player.Rank) + 11) * (Galaxy.CurrentTurn div 50));
        if Item <> nil then ReplaceTextToken(DialogText, '<ItemName>', Item.GetDisplayName, HighlightColorTag)
        else RaiseWideMessage('eq=nil');
      end
      else DialogText := LocalizedColorText('FormRuins.WB.' + CoalitionRankNames[Player.Rank] + '.Greeting');
      ReplaceTextToken(DialogText, '<WB>', Player.DockedTo.Name, HighlightColorTag);
      ReplaceTextToken(DialogText, '<Rank>', Player.GetRankName, HighlightColorTag);
      ReplaceTextToken(DialogText, '<NeedPoints>', IntToStr(Player.GetRankPointsToNextRank), HighlightColorTag);
    end;
  end;
  if ScriptDialogIndex < 0 then BuildBuiltinServiceOptions
  else if not Script.SkipGreeting then
    AddChoice('- ' + LocalizedColorText('FormRuins.I_Continue'), Integer(Script), SelectScriptDialog)
  else SelectScriptDialog(Integer(Script));
end;
{ @end $524B44 }

{ @routine $525650 TfRuinsTalk_BuildBuiltinServiceOptions }
procedure TfRuinsTalk.BuildBuiltinServiceOptions;
begin
  case Player.DockedTo.ShipType of
    t_RangerCenter:
    begin
      if Player.GetCarriedNodeCount > 0 then
        AddChoice('- ' + FormatText1(LocalizedColorText('FormRuins.RC.Protoplasm.PlayerSend'), HighlightColorTag, '<ProtoplasmCount>', IntToStr(Player.GetCarriedNodeCount)), 0, DepositNodesAtRangerCenter);
      AddChoice('- ' + LocalizedColorText('FormRuins.RC.Rating.PlayerSend'), 0, ShowRangerCenterRatingAnswer);
      AddChoice('- ' + LocalizedColorText('FormRuins.RC.BestRanger.PlayerSend'), 0, ShowRangerCenterBestRangerAnswer);
    end;
    t_PirateBase:
    begin
      AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChangeNationality'), 0, ShowPirateBaseNationalityDialog);
      AddChoice('- ' + LocalizedColorText('FormRuins.PB.Protoplasm.PlayerAsk'), 0, ShowPirateBaseNodeDialog);
      AddChoice('- ' + LocalizedColorText('FormRuins.PB.Repair.PlayerSend'), 0, ShowPirateBaseRepairDialog);
    end;
    t_MilitaryBase:
    begin
      AddChoice('- ' + LocalizedColorText('FormRuins.WB.WarWithKling.PlayerSend'), 0, ShowMilitaryCombatAdvice);
      if Player.Rank < crCommander then
        AddChoice('- ' + FormatText1(LocalizedColorText('FormRuins.WB.NextRank.PlayerSend'), HighlightColorTag, '<NextRank>', Player.GetNextRankName), 0, ShowMilitaryBaseNextRankDialog);
      AddChoice('- ' + LocalizedColorText('FormRuins.WB.Repair.PlayerSend'), 0, ShowMilitaryBaseRepairDialog);
    end;
    t_ScientificBase:
    begin
      AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerSend'), 0, ShowScienceBaseImprovementDialog);
      AddChoice('- ' + LocalizedColorText('FormRuins.SB.Repair.PlayerSend'), 0, ShowScienceBaseRepairDialog);
      if Galaxy.CommunicatorResearchProgress < 100 then
        AddChoice('- ' + LocalizedColorText('FormRuins.SB.Communicator.PlayerAsk'), 0, ShowCommunicatorResearchDialog);
      if (not Player.HaveCommunicator) and (Galaxy.CommunicatorResearchProgress >= 100) and (GetCommunicatorCost <= Player.Money) then
        AddChoice('- ' + FormatText1(LocalizedColorText('FormRuins.SB.Communicator.PlayerOk'), HighlightColorTag, '<CommunicatorCost>', IntToStr(GetCommunicatorCost)), 0, BuyCommunicator);
    end;
  end;
end;
{ @end $525650 }

{ @routine $525EF8 TfRuinsTalk_ContinueScriptDialog }
procedure TfRuinsTalk.ContinueScriptDialog;
begin
  AddChoice('- ' + LocalizedColorText('FormRuins.I_Continue'), CurrentScript.CurrentAnswer, RunScriptAnswerReturnToMain);
end;
{ @end $525EF8 }

{ @routine $525FAC TfRuinsTalk_AddScriptTakeoffChoice }
procedure TfRuinsTalk.AddScriptTakeoffChoice(Text: WideString);
begin
  if Text = '' then AddChoice('- ' + LocalizedColorText('FormRuins.I_TakeOff'), CurrentScript.CurrentAnswer, RunScriptTakeoff)
  else AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptTakeoff);
end;
{ @end $525FAC }

{ @routine $5260A0 TfRuinsTalk_AddScriptNewsExitChoice }
procedure TfRuinsTalk.AddScriptNewsExitChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptNewsExit);
end;
{ @end $5260A0 }

{ @routine $526124 TfRuinsTalk_AddScriptGameEndChoice }
procedure TfRuinsTalk.AddScriptGameEndChoice(Text: WideString);
begin
  AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptGameEnd);
end;
{ @end $526124 }

{ @routine $5261A8 TfRuinsTalk_SelectScriptDialog }
procedure TfRuinsTalk.SelectScriptDialog(Script: Integer);
begin
  ClearDialogChoices;
  CurrentScript := TScript(Script);
  CurrentScript.CallDialogMessage(ScriptDialogIndex);
end;
{ @end $5261A8 }

{ @routine $5261D0 TfRuinsTalk_RunScriptAnswer }
procedure TfRuinsTalk.RunScriptAnswer(Answer: Integer);
begin
  ClearDialogChoices;
  ScriptDialogIndex := -1;
  CurrentScript.ExecuteDialogAnswer(Answer);
  if ScriptDialogIndex < 0 then RaiseWideMessage('I_Script');
  CurrentScript.CallDialogMessage(ScriptDialogIndex);
end;
{ @end $5261D0 }

{ @routine $526234 TfRuinsTalk_RunScriptAnswerReturnToMain }
procedure TfRuinsTalk.RunScriptAnswerReturnToMain(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  DialogText := LocalizedColorText('FormRuins.I_AfterScript');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $526234 }

{ @routine $5262D4 TfRuinsTalk_RunScriptTakeoff }
procedure TfRuinsTalk.RunScriptTakeoff(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  StationPanel.TakeoffClicked(nil);
end;
{ @end $5262D4 }

{ @routine $5262F4 TfRuinsTalk_RunScriptNewsExit }
procedure TfRuinsTalk.RunScriptNewsExit(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  StationPanel.InformationClicked(nil);
end;
{ @end $5262F4 }

{ @routine $526314 TfRuinsTalk_RunScriptGameEnd }
procedure TfRuinsTalk.RunScriptGameEnd(Answer: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Answer);
  GameEndReason := 0;
  RequestedScreenId := screenGameEnd;
  RequestClose(1);
end;
{ @end $526314 }

{ @routine $526344 TfRuinsTalk_DepositNodesAtRangerCenter }
procedure TfRuinsTalk.DepositNodesAtRangerCenter(Action: Integer);
var Count: Integer;
begin
  Count := Player.GetCarriedNodeCount;
  Player.DepositCarriedNodes;
  Player.ResetCounterAfterNodeDeposit;
  Galaxy.RefreshRangerRatingPlaces;
  SoundManager.PlaySound('Sound.Sell');
  DialogText := LocalizedColorText('FormRuins.RC.Protoplasm.RCAnswer');
  ReplaceTextToken(DialogText, '<Point>', IntToStr(Count), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Number>', IntToStr(Player.PlaceInRating), HighlightColorTag);
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $526344 }

{ @routine $526530 TfRuinsTalk_ShowRangerCenterRatingAnswer }
procedure TfRuinsTalk.ShowRangerCenterRatingAnswer(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.RC.Rating.RCAnswer');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $526530 }

{ @routine $5265D0 TfRuinsTalk_ShowRangerCenterBestRangerAnswer }
procedure TfRuinsTalk.ShowRangerCenterBestRangerAnswer(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.RC.BestRanger.RCAnswer');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $5265D0 }

{ @routine $526678 TfRuinsTalk_ShowPirateBaseNationalityDialog }
procedure TfRuinsTalk.ShowPirateBaseNationalityDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AnswerChangeNationality');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.PlayerOk'), 0, BuildPirateBaseNationalityChoices);
  AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.PlayerNo'), 0, DeclinePirateBaseNationality);
end;
{ @end $526678 }

{ @routine $526864 TfRuinsTalk_BuildPirateBaseNationalityChoices }
procedure TfRuinsTalk.BuildPirateBaseNationalityChoices(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.PBNext');
  ReplaceTextToken(DialogText, '<MoneyMaloc>', IntToStr(Galaxy.ComputeScaledBigMoney(oiMaloc)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<MoneyPeleng>', IntToStr(Galaxy.ComputeScaledBigMoney(oiPeleng)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<MoneyPeople>', IntToStr(Galaxy.ComputeScaledBigMoney(oiPeople)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<MoneyFei>', IntToStr(Galaxy.ComputeScaledBigMoney(oiFei)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<MoneyGaal>', IntToStr(Galaxy.ComputeScaledBigMoney(oiGaal)), HighlightColorTag);
  ClearDialogChoices;
  if (Player.OwnerId <> oiMaloc) and (Galaxy.ComputeScaledBigMoney(oiMaloc) <= Player.Money) then
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChooseMaloc'), 0, ChangeNationalityMaloc);
  if (Player.OwnerId <> oiPeleng) and (Galaxy.ComputeScaledBigMoney(oiPeleng) <= Player.Money) then
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChoosePeleng'), 0, ChangeNationalityPeleng);
  if (Player.OwnerId <> oiPeople) and (Galaxy.ComputeScaledBigMoney(oiPeople) <= Player.Money) then
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChoosePeople'), 0, ChangeNationalityPeople);
  if (Player.OwnerId <> oiFei) and (Galaxy.ComputeScaledBigMoney(oiFei) <= Player.Money) then
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChooseFei'), 0, ChangeNationalityFei);
  if (Player.OwnerId <> oiGaal) and (Galaxy.ComputeScaledBigMoney(oiGaal) <= Player.Money) then
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.ChooseGaal'), 0, ChangeNationalityGaal);
  AddChoice('- ' + LocalizedColorText('FormRuins.PB.ChangeNationality.PlayerNo'), 0, DeclinePirateBaseNationality);
end;
{ @end $526864 }

{ @routine $526F04 TfRuinsTalk_ChangeNationalityMaloc }
procedure TfRuinsTalk.ChangeNationalityMaloc(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AfterOperationMaloc');
  Player.SetMoney(Player.Money - Galaxy.ComputeScaledBigMoney(oiMaloc));
  Player.AddPirateCareerActivity(8);
  Player.OwnerId := oiMaloc;
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  Player.ChangeShipRelations(nil, rcmRaiseTo, 70, [htRanger, htPirate, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $526F04 }

{ @routine $527068 TfRuinsTalk_ChangeNationalityPeleng }
procedure TfRuinsTalk.ChangeNationalityPeleng(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AfterOperationPeleng');
  Player.SetMoney(Player.Money - Galaxy.ComputeScaledBigMoney(oiPeleng));
  Player.AddPirateCareerActivity(8);
  Player.OwnerId := oiPeleng;
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  Player.ChangeShipRelations(nil, rcmRaiseTo, 70, [htRanger, htPirate, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $527068 }

{ @routine $5271CC TfRuinsTalk_ChangeNationalityPeople }
procedure TfRuinsTalk.ChangeNationalityPeople(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AfterOperationPeople');
  Player.SetMoney(Player.Money - Galaxy.ComputeScaledBigMoney(oiPeople));
  Player.AddPirateCareerActivity(8);
  Player.OwnerId := oiPeople;
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  Player.ChangeShipRelations(nil, rcmRaiseTo, 70, [htRanger, htPirate, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $5271CC }

{ @routine $527330 TfRuinsTalk_ChangeNationalityFei }
procedure TfRuinsTalk.ChangeNationalityFei(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AfterOperationFei');
  Player.SetMoney(Player.Money - Galaxy.ComputeScaledBigMoney(oiFei));
  Player.AddPirateCareerActivity(8);
  Player.OwnerId := oiFei;
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  Player.ChangeShipRelations(nil, rcmRaiseTo, 70, [htRanger, htPirate, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $527330 }

{ @routine $527490 TfRuinsTalk_ChangeNationalityGaal }
procedure TfRuinsTalk.ChangeNationalityGaal(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.AfterOperationGaal');
  Player.SetMoney(Player.Money - Galaxy.ComputeScaledBigMoney(oiGaal));
  Player.AddPirateCareerActivity(8);
  Player.OwnerId := oiGaal;
  Player.ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  Player.ChangeShipRelations(nil, rcmRaiseTo, 70, [htRanger, htPirate, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $527490 }

{ @routine $5275F0 TfRuinsTalk_DeclinePirateBaseNationality }
procedure TfRuinsTalk.DeclinePirateBaseNationality(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.ChangeNationality.PBAfterNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $5275F0 }

{ @routine $5276A8 TfRuinsTalk_ShowPirateBaseNodeDialog }
procedure TfRuinsTalk.ShowPirateBaseNodeDialog(Action: Integer);
var
  Count, Cost, DiscountedCost: Integer;
  Text: WideString;
  OtherBase: TRuins;
  Discount: Byte;
begin
  if Player.DockedTo.NodeReserve > 0 then
  begin
    Count := (Player.DockedTo as TPB).GetNodeSaleBatchSize;
    Cost := Galaxy.ScaleGoodsPriceByGalaxyAge(Count * 10 * 3);
  Discount := Round(Player.CareerStatus[rcPirate] / 1.3) + 1;
  DiscountedCost := Max(1, Cost - Round(Cost / 100 * Discount));
    Text := LocalizedColorText('FormRuins.PB.Protoplasm.PBStart');
  ReplaceTextToken(Text, '<Count>', IntToStr(Count), HighlightColorTag);
  ReplaceTextToken(Text, '<MoneyAll>', IntToStr(Cost), HighlightColorTag);
  ReplaceTextToken(Text, '<Percent>', IntToStr(Discount), HighlightColorTag);
  ReplaceTextToken(Text, '<MoneyDec>', IntToStr(DiscountedCost), HighlightColorTag);
    DialogText := Text;
    ClearDialogChoices;
    if Player.Money >= DiscountedCost then
  AddChoice('- ' + LocalizedColorText('FormRuins.PB.Protoplasm.PlayerOk'), 0, BuyPirateBaseNodes);
  AddChoice('- ' + LocalizedColorText('FormRuins.PB.Protoplasm.PlayerNo'), 0, DeclinePirateBaseNodes);
  end
  else
  begin
    Text := LocalizedColorText('FormRuins.PB.Protoplasm.PBEnd');
    OtherBase := (Player.DockedTo as TPB).FindPirateBaseWithNodes;
    if OtherBase <> nil then
    begin
      Text := Text + #13#10 + LocalizedColorText('FormRuins.PB.Protoplasm.PBEndPlus');
      ReplaceTextToken(Text, '<ToSector>', OtherBase.CurrentStar.Constellation.GetName, HighlightColorTag);
      ReplaceTextToken(Text, '<ToBase>', OtherBase.Name, HighlightColorTag);
    end;
    DialogText := Text;
    ClearDialogChoices;
    BuildBuiltinServiceOptions;
  end;
end;
{ @end $5276A8 }

{ @routine $527C14 TfRuinsTalk_BuyPirateBaseNodes }
procedure TfRuinsTalk.BuyPirateBaseNodes(Action: Integer);
var
  Count, Cost, DiscountedCost: Integer;
  Stack: TProtoplasm;
  Item: TItem;
  I: Integer;
  NewStack: Boolean;
  Discount: Byte;
begin
  Count := (Player.DockedTo as TPB).GetNodeSaleBatchSize;
  Cost := Galaxy.ScaleGoodsPriceByGalaxyAge(Count * 10 * 3);
  Discount := Round(Player.CareerStatus[rcPirate] / 1.3) + 1;
  DiscountedCost := Max(1, Cost - Round(Cost / 100 * Discount));
  Player.SetMoney(Player.Money - DiscountedCost);
  Dec(Player.DockedTo.NodeReserve, Count);
  Player.AddPirateCareerActivity(4);
  NewStack := True;
  for I := 1 to Player.Inventory.Count - 1 do
  begin
    Item := Player.Inventory[I];
    if Item is TProtoplasm then
    begin
      Stack := Item as TProtoplasm;
      Stack.Init(Stack.Quantity + Count, 1);
      NewStack := False;
      Break;
    end;
  end;
  if NewStack then
  begin
    Stack := TProtoplasm.Create;
    Stack.Init(Count, 1);
    Player.Inventory.Add(Stack);
  end;
  DialogText := LocalizedColorText('FormRuins.PB.Protoplasm.PBSell');
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $527C14 }

{ @routine $527E70 TfRuinsTalk_DeclinePirateBaseNodes }
procedure TfRuinsTalk.DeclinePirateBaseNodes(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.Protoplasm.PBAfterNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $527E70 }

{ @routine $527F18 TfRuinsTalk_ShowPirateBaseRepairDialog }
procedure TfRuinsTalk.ShowPirateBaseRepairDialog(Action: Integer);
var Cost, DiscountedCost: Integer; Text: WideString; Discount: Byte;
begin
  Cost := (Player.DockedTo as TPB).GetRepairCost(Player);
  Discount := Round(Player.CareerStatus[rcPirate] / 1.3) + 1;
  DiscountedCost := Max(1, Cost - Round(Cost / 100 * Discount));
  if Cost = 0 then
  begin
    DialogText := LocalizedColorText('FormRuins.PB.Repair.PBYouNotNeedRepair');
    ClearDialogChoices;
    BuildBuiltinServiceOptions;
  end
  else
  begin
    Text := LocalizedColorText('FormRuins.PB.Repair.PBYouNeedRepair');
    ReplaceTextToken(Text, '<MoneyAll>', IntToStr(Cost), HighlightColorTag);
    ReplaceTextToken(Text, '<Percent>', IntToStr(Discount), HighlightColorTag);
    ReplaceTextToken(Text, '<MoneyDec>', IntToStr(DiscountedCost), HighlightColorTag);
    ReplaceTextToken(Text, '<PB>', Player.DockedTo.Name, HighlightColorTag);
    DialogText := Text;
    ClearDialogChoices;
    if Player.Money >= DiscountedCost then
      AddChoice('- ' + LocalizedColorText('FormRuins.PB.Repair.PlayerOk'), 0, AcceptPirateBaseRepair);
    AddChoice('- ' + LocalizedColorText('FormRuins.PB.Repair.PlayerNo'), 0, DeclinePirateBaseRepair);
  end;
end;
{ @end $527F18 }

{ @routine $52834C TfRuinsTalk_AcceptPirateBaseRepair }
procedure TfRuinsTalk.AcceptPirateBaseRepair(Action: Integer);
var Cost, DiscountedCost: Integer; Discount: Byte;
begin
  Cost := (Player.DockedTo as TPB).GetRepairCost(Player);
  Discount := Round(Player.CareerStatus[rcPirate] / 1.3) + 1;
  DiscountedCost := Max(1, Cost - Round(Cost / 100 * Discount));
  if DiscountedCost <= Player.Money then
  begin
    Player.SetMoney(Player.Money + (Cost - DiscountedCost));
    (Player.DockedTo as TPB).RepairShip(Player);
  end;
  Player.AddPirateCareerActivity(4);
  DialogText := LocalizedColorText('FormRuins.PB.Repair.PBAfterOk');
  SoundManager.PlaySound('Sound.Repair');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52834C }

{ @routine $52850C TfRuinsTalk_DeclinePirateBaseRepair }
procedure TfRuinsTalk.DeclinePirateBaseRepair(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.PB.Repair.PBAfterNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52850C }

{ @routine $5285AC TfRuinsTalk_ShowMilitaryCombatAdvice }
procedure TfRuinsTalk.ShowMilitaryCombatAdvice(Action: Integer);
var Percent: Byte;
begin
  Percent := Galaxy.GetFactionControlPercent(sfCoalition);
  case Percent of
    0..9: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore00Percent');
    10..22: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore10Percent');
    23..35: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore30Percent');
    36..59: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore50Percent');
    60..89: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore70Percent');
    90..99: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControlMore90Percent');
    100: DialogText := LocalizedColorText('FormRuins.WB.WarWithKling.WBAnswerWeControl100Percent');
  else DialogText := 'Error in procedure TfRuinsTalk.I_WarWithKling';
  end;
  ReplaceTextToken(DialogText, '<WB>', Player.DockedTo.Name, HighlightColorTag);
  ReplaceTextToken(DialogText, '<Percent>', IntToStr(Percent), HighlightColorTag);
  if Percent < 100 then
  begin
    ReplaceTextToken(DialogText, '<Star>', Player.FindNearestStarByControlFaction(sfKlissan).Name, HighlightColorTag);
    ReplaceTextToken(DialogText, '<Sector>', Player.FindNearestStarByControlFaction(sfKlissan).Constellation.GetName, HighlightColorTag);
  end;
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $5285AC }

{ @routine $528C1C TfRuinsTalk_ShowMilitaryBaseNextRankDialog }
procedure TfRuinsTalk.ShowMilitaryBaseNextRankDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.WB.NextRank.WBAnswer');
  ReplaceTextToken(DialogText, '<WB>', Player.DockedTo.Name, HighlightColorTag);
  ReplaceTextToken(DialogText, '<NextRank>', Player.GetNextRankName, HighlightColorTag);
  ReplaceTextToken(DialogText, '<NeedPoints>', IntToStr(Player.GetRankPointsToNextRank), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForLiberationSystem>', IntToStr(30), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForDeadPirates>', IntToStr(10), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForDeadPiratesInGiperSpace>', IntToStr(2), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForK1>', IntToStr(KlissanInfo[ktEgemon].RankPoints), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForK2>', IntToStr(KlissanInfo[ktNondus].RankPoints), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForK3>', IntToStr(KlissanInfo[ktKatauri].RankPoints), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForK4>', IntToStr(KlissanInfo[ktRoggit].RankPoints), HighlightColorTag);
  ReplaceTextToken(DialogText, '<RankPointsForK5>', IntToStr(KlissanInfo[ktMutenok].RankPoints), HighlightColorTag);
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $528C1C }

{ @routine $52918C TfRuinsTalk_ShowMilitaryBaseRepairDialog }
procedure TfRuinsTalk.ShowMilitaryBaseRepairDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.WB.Repair.WBAnswer');
  ReplaceTextToken(DialogText, '<WB>', Player.DockedTo.Name, HighlightColorTag);
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.WB.Repair.PlayerCostAsk'), 0, ShowMilitaryBaseRepairQuote);
end;
{ @end $52918C }

{ @routine $529310 TfRuinsTalk_ShowMilitaryBaseRepairQuote }
procedure TfRuinsTalk.ShowMilitaryBaseRepairQuote(Action: Integer);
var Cost: Integer;
begin
  Cost := (Player.DockedTo as TWB).GetRepairCost(Player);
  if Cost = 0 then
  begin
    DialogText := LocalizedColorText('FormRuins.WB.Repair.WBCostAnswerNonEquipmentsForRepair');
    ClearDialogChoices;
    BuildBuiltinServiceOptions;
  end
  else
  begin
    if Cost < Player.Wealth div 10 then
      DialogText := LocalizedColorText('FormRuins.WB.Repair.WBCostAnswerYouHaveGoodEquipments')
    else DialogText := LocalizedColorText('FormRuins.WB.Repair.WBCostAnswerYouHaveBadEquipments');
    ReplaceTextToken(DialogText, '<WB>', Player.DockedTo.Name, HighlightColorTag);
    ReplaceTextToken(DialogText, '<Money>', IntToStr(Cost), HighlightColorTag);
    ClearDialogChoices;
    if (Cost > 0) and (Cost <= Player.Money) then
      AddChoice('- ' + LocalizedColorText('FormRuins.WB.Repair.PlayerOk'), 0, AcceptMilitaryBaseRepair);
    AddChoice('- ' + LocalizedColorText('FormRuins.WB.Repair.PlayerNo'), 0, DeclineMilitaryBaseRepair);
  end;
end;
{ @end $529310 }

{ @routine $529708 TfRuinsTalk_AcceptMilitaryBaseRepair }
procedure TfRuinsTalk.AcceptMilitaryBaseRepair(Action: Integer);
begin
  (Player.DockedTo as TWB).RepairShip(Player);
  DialogText := LocalizedColorText('FormRuins.WB.Repair.WBAfterOk');
  SoundManager.PlaySound('Sound.Repair');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $529708 }

{ @routine $5297FC TfRuinsTalk_DeclineMilitaryBaseRepair }
procedure TfRuinsTalk.DeclineMilitaryBaseRepair(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.WB.Repair.WBAfterNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $5297FC }

{ @routine $52989C TfRuinsTalk_ShowScienceBaseImprovementDialog }
procedure TfRuinsTalk.ShowScienceBaseImprovementDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAnswer');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerAsk'), 0, ShowScienceBaseImprovementItems);
end;
{ @end $52989C }

{ @routine $5299D0 TfRuinsTalk_ShowScienceBaseImprovementItems }
procedure TfRuinsTalk.ShowScienceBaseImprovementItems(Action: Integer);
var I, Count: Integer; Item: TEquipment; Text: WideString;
begin
  ClearDialogChoices;
  Count := 0;
  for I := 0 to Player.Inventory.Count - 1 do
  begin
    Item := Player.Inventory[I];
    if (Item.ItemType in (DirectEquipmentTypes + WeaponItemTypes)) and (Item.OwnerId <> oiKling) then
    begin
      if Item.HasStandardStats then
      begin
        Inc(Count);
        Text := Text + #13#10 + IntToStr(Count) + ') ' + LocalizedColorText('FormRuins.SB.Improvement.ItemReadyForImprovement');
        AddChoice('- ' + Item.GetDisplayName, Integer(Item), ShowScienceBaseImprovementQuote);
      end;
      ReplaceTextToken(Text, '<ItemName>', Item.GetDisplayName, '');
      ReplaceTextToken(Text, '<Money>', IntToStr(Item.Cost), HighlightColorTag);
    end;
  end;
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBSeeItems');
  ReplaceTextToken(DialogText, '<ListItems>', Text, '');
  if Count > 0 then
  begin
    DialogText := DialogText + #13#10 + LocalizedColorText('FormRuins.SB.Improvement.SBSeeItemsHaveItems');
    AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerNothing'), 0, DeclineScienceBaseImprovement);
  end
  else
  begin
    DialogText := DialogText + #13#10 + LocalizedColorText('FormRuins.SB.Improvement.SBSeeItemsNotHaveItems');
    BuildBuiltinServiceOptions;
  end;
end;
{ @end $5299D0 }

{ @routine $529EC8 TfRuinsTalk_DeclineScienceBaseImprovement }
procedure TfRuinsTalk.DeclineScienceBaseImprovement(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAnswerNothing');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $529EC8 }

{ @routine $529F80 TfRuinsTalk_ShowScienceBaseImprovementQuote }
procedure TfRuinsTalk.ShowScienceBaseImprovementQuote(Action: Integer);
var Item: TEquipment;
begin
  Item := TEquipment(Action);
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBNeedCostImprovement');
  ReplaceTextToken(DialogText, '<FullName>', Item.GetDisplayName, HighlightColorTag);
  ReplaceTextToken(DialogText, '<Money>', IntToStr(Item.Cost), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Min>', IntToStr(Item.CalculateImprovementCost(ikMinor)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Average>', IntToStr(Item.CalculateImprovementCost(ikMedium)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Max>', IntToStr(Item.CalculateImprovementCost(ikMajor)), HighlightColorTag);
  ClearDialogChoices;
  if Item.CalculateImprovementCost(ikMajor) <= Player.Money then
    AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerOkMax'), Integer(Item), AcceptScienceBaseImprovementMax);
  if Item.CalculateImprovementCost(ikMedium) <= Player.Money then
    AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerOkAverage'), Integer(Item), AcceptScienceBaseImprovementAverage);
  if Item.CalculateImprovementCost(ikMinor) <= Player.Money then
    AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerOkMin'), Integer(Item), AcceptScienceBaseImprovementMin);
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerNo'), 0, DeclineScienceBaseImprovement);
end;
{ @end $529F80 }

{ @routine $52A460 TfRuinsTalk_AcceptScienceBaseImprovementMax }
procedure TfRuinsTalk.AcceptScienceBaseImprovementMax(Action: Integer);
var Item: TEquipment;
begin
  Item := TEquipment(Action);
  Player.SetMoney(Player.Money - Item.CalculateImprovementCost(ikMajor));
  Item.Improve(ikMajor);
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAfterOkMax');
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatOk'), 0, ShowScienceBaseImprovementItems);
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatNo'), 0, DeclineScienceBaseRepeatImprovement);
end;
{ @end $52A460 }

{ @routine $52A684 TfRuinsTalk_AcceptScienceBaseImprovementAverage }
procedure TfRuinsTalk.AcceptScienceBaseImprovementAverage(Action: Integer);
var Item: TEquipment;
begin
  Item := TEquipment(Action);
  Player.SetMoney(Player.Money - Item.CalculateImprovementCost(ikMedium));
  Item.Improve(ikMedium);
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAfterOkAverage');
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatOk'), 0, ShowScienceBaseImprovementItems);
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatNo'), 0, DeclineScienceBaseRepeatImprovement);
end;
{ @end $52A684 }

{ @routine $52A8B0 TfRuinsTalk_AcceptScienceBaseImprovementMin }
procedure TfRuinsTalk.AcceptScienceBaseImprovementMin(Action: Integer);
var Item: TEquipment;
begin
  Item := TEquipment(Action);
  Player.SetMoney(Player.Money - Item.CalculateImprovementCost(ikMinor));
  Item.Improve(ikMinor);
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAfterOkMin');
  ReplaceTextToken(DialogText, '<ShortName>', LowerCaseWideString(Item.GetShortName), '');
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatOk'), 0, ShowScienceBaseImprovementItems);
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Improvement.PlayerRepeatNo'), 0, DeclineScienceBaseRepeatImprovement);
end;
{ @end $52A8B0 }

{ @routine $52AB1C TfRuinsTalk_DeclineScienceBaseRepeatImprovement }
procedure TfRuinsTalk.DeclineScienceBaseRepeatImprovement(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.SB.Improvement.SBAfterRepeatNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52AB1C }

{ @routine $52ABD4 TfRuinsTalk_ShowScienceBaseRepairDialog }
procedure TfRuinsTalk.ShowScienceBaseRepairDialog(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.SB.Repair.SBAnswer');
  ReplaceTextToken(DialogText, '<SB>', Player.DockedTo.Name, HighlightColorTag);
  ClearDialogChoices;
  AddChoice('- ' + LocalizedColorText('FormRuins.SB.Repair.PlayerCostAsk'), 0, ShowScienceBaseRepairQuote);
end;
{ @end $52ABD4 }

{ @routine $52AD58 TfRuinsTalk_ShowScienceBaseRepairQuote }
procedure TfRuinsTalk.ShowScienceBaseRepairQuote(Action: Integer);
var Cost: Integer;
begin
  Cost := (Player.DockedTo as TSB).GetRepairCost(Player);
  if Cost = 0 then
  begin
    DialogText := LocalizedColorText('FormRuins.SB.Repair.SBCostAnswerNonEquipmentsForRepair');
    ClearDialogChoices;
    BuildBuiltinServiceOptions;
  end
  else
  begin
    if Cost < Player.Wealth div 10 then
      DialogText := LocalizedColorText('FormRuins.SB.Repair.SBCostAnswerYouHaveGoodEquipments')
    else DialogText := LocalizedColorText('FormRuins.SB.Repair.SBCostAnswerYouHaveBadEquipments');
    ReplaceTextToken(DialogText, '<SB>', Player.DockedTo.Name, HighlightColorTag);
    ReplaceTextToken(DialogText, '<Money>', IntToStr(Cost), HighlightColorTag);
    ClearDialogChoices;
    if (Cost > 0) and (Cost <= Player.Money) then
      AddChoice('- ' + LocalizedColorText('FormRuins.SB.Repair.PlayerOk'), 0, AcceptScienceBaseRepair);
    AddChoice('- ' + LocalizedColorText('FormRuins.SB.Repair.PlayerNo'), 0, DeclineScienceBaseRepair);
  end;
end;
{ @end $52AD58 }

{ @routine $52B150 TfRuinsTalk_AcceptScienceBaseRepair }
procedure TfRuinsTalk.AcceptScienceBaseRepair(Action: Integer);
begin
  (Player.DockedTo as TSB).RepairShip(Player);
  DialogText := LocalizedColorText('FormRuins.SB.Repair.SBAfterOk');
  SoundManager.PlaySound('Sound.Repair');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52B150 }

{ @routine $52B244 TfRuinsTalk_DeclineScienceBaseRepair }
procedure TfRuinsTalk.DeclineScienceBaseRepair(Action: Integer);
begin
  DialogText := LocalizedColorText('FormRuins.SB.Repair.SBAfterNo');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52B244 }

{ @routine $52B2E4 TfRuinsTalk_ShowCommunicatorResearchDialog }
procedure TfRuinsTalk.ShowCommunicatorResearchDialog(Action: Integer);
begin
  if Galaxy.CommunicatorResearchProgress < 50 then
    DialogText := LocalizedColorText('FormRuins.SB.Communicator.SBAnswerOpenLow')
  else if Galaxy.CommunicatorResearchProgress < 90 then
    DialogText := LocalizedColorText('FormRuins.SB.Communicator.SBAnswerOpenAverage')
  else DialogText := LocalizedColorText('FormRuins.SB.Communicator.SBAnswerOpenHigh');
  ReplaceTextToken(DialogText, '<SB>', Player.DockedTo.Name, HighlightColorTag);
  ReplaceTextToken(DialogText, '<OpenCommunicator>', IntToStr(Min(Round(Galaxy.CommunicatorResearchProgress), 99)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<SBWorkPercent>', IntToStr(Round(Galaxy.CommunicatorResearchPerDay / 0.01 * 100)), HighlightColorTag);
  ReplaceTextToken(DialogText, '<Date>', Galaxy.FormatTurnDate(Galaxy.CurrentTurn + Round((100 - Galaxy.CommunicatorResearchProgress) / Galaxy.CommunicatorResearchPerDay) + 1), HighlightColorTag);
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52B2E4 }

{ @routine $52B698 TfRuinsTalk_BuyCommunicator }
procedure TfRuinsTalk.BuyCommunicator(Action: Integer);
begin
  if GetCommunicatorCost > Player.Money then RaiseWideMessage('Player.FMoney<CommunicatorCost');
  DialogText := LocalizedColorText('FormRuins.SB.Communicator.SBAfterOk');
  Player.SetMoney(Player.Money - GetCommunicatorCost);
  Player.HaveCommunicator := True;
  SoundManager.PlaySound('Sound.Sell');
  ClearDialogChoices;
  BuildBuiltinServiceOptions;
end;
{ @end $52B698 }

end.

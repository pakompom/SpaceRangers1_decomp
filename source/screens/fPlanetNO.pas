unit fPlanetNO;
// Unit bracket (inferred): CODE 0x0060083C..0x0060145B; inclusive evidence, not full bounds.
interface
uses fPanelMain, GI_MessageLoop, Types;
type
  TfPlanetNO = class(TMessageLoopGI) // @size $B4
  public
    constructor Create; // @addr $6008C4
    destructor Destroy; override; // @addr $60090C
    procedure InitializeLayout; override; // @addr $600948
    procedure OnOpen; override; // @addr $6009F8
    procedure OnClose; override; // @addr $600E14
    procedure TakeoffClicked(Sender: TObjectGI); // @addr $600E20
    procedure StartTextQuest(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $600F88
    procedure QuestMouseEnter(Sender: TObjectGI); // @addr $6010E0
    procedure QuestMouseLeave(Sender: TObjectGI); // @addr $6011F8
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $601310
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $60132C
    procedure SelectMusic; override; // @addr $60138C
    MainPanel: TfPanelMain; // @offset $B0

  end;
implementation

// @unit-initialization $601454
// @unit-finalization $601424

uses Classes, SysUtils, Windows, GR_Main, Globals, GlobalsV, GI_GraphButton,
  GI_GAI, GI_MessageBox, aConst, aPlayer, aRanger, aPlanet, aGalaxy, aScript,
  aCalc, aSaveLoad, fSaveManager, fPlanetQuest, fStarMap, EC_Struct;

{ @routine $6008C4 TfPlanetNO_Create }
constructor TfPlanetNO.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
end;
{ @end $6008C4 }

{ @routine $60090C TfPlanetNO_Destroy }
destructor TfPlanetNO.Destroy;
begin
  if MainPanel <> nil then
  begin
    MainPanel.Free;
    MainPanel := nil;
  end;
  inherited Destroy;
end;
{ @end $60090C }

{ @routine $600948 TfPlanetNO_InitializeLayout }
procedure TfPlanetNO.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  with GetByName('ButTakeoff') as TGraphButtonGI do
  begin
    UpCallback := TakeoffClicked;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
end;
{ @end $600948 }

{ @routine $6009F8 TfPlanetNO_OnOpen }
procedure TfPlanetNO.OnOpen;
var I: Integer; Quest: PQuest; Animation: TgaiGI;
begin
  SelectMusic;
  MainPanel.OnOpen;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  Animation := GetByName('SearchArtefact') as TgaiGI;
  with Animation do
  begin
    LeftButtonDownCallback := StartTextQuest;
    MouseEnterCallback := QuestMouseEnter;
    MouseLeaveCallback := QuestMouseLeave;
    SetImagePath('Bm.FormPQuest.' + GiResourceSuffix + 'PlanetButA');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetImagePath('Bm.FormPQuest.' + GiResourceSuffix + 'PlanetButN');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetActive(False);
    if (Player.CurrentPlanet.TextQuestId > -1) and (Player.Quests.Count > 0) then
      for I := 0 to Player.Quests.Count - 1 do
      begin
        Quest := Player.Quests[I];
        if (Quest.QuestType = qtPlanetQuest) and (Quest.ObjectiveTarget is TPlanet) and
          ((Quest.ObjectiveTarget as TPlanet) = Player.CurrentPlanet) then
          if LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').CountParams(IntToStr(Quest.QuestNumber)) > 0 then
          begin
            if (Quest.QuestNumber < 10000) or
              ((LanguageDataConfig.GetBlock('PlanetQuest').CountBlocks('PlanetQuestLic') > 0) and
               (LanguageDataConfig.GetBlock('PlanetQuest').GetBlock('PlanetQuestLic').GetParamOrMarker(IntToStr(Quest.QuestNumber)) =
                PlanetQuestScreen.GetQuestContentHash(Quest.QuestNumber))) then UserValue := 0
            else UserValue := 1;
            SetActive(True);
            Break;
          end;
      end;
  end;
  MainPanel.RebuildMessageButtons;
end;
{ @end $6009F8 }

{ @routine $600E14 TfPlanetNO_OnClose }
procedure TfPlanetNO.OnClose;
begin
  MainPanel.OnClose;
end;
{ @end $600E14 }

{ @routine $600E20 TfPlanetNO_TakeoffClicked }
procedure TfPlanetNO.TakeoffClicked(Sender: TObjectGI);
var I: Integer;
begin
  if (TurnCalculationPhase = 1) or (TurnCalculationPhase = 3) then Exit;
  CaptureSavePreview;
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
  PruneExpiredPersistentPlayerMessages;
  Player.OrderTakeoff;
  for I := 0 to Galaxy.Scripts.Count - 1 do TScript(Galaxy.Scripts[I]).RunTurnCode;
  StarMapScreen.SetMapCenterManually(TruncatePointF(Player.Position));
  PlayerStar.RefreshSpaceObjectPositions;
  RunStarTransitionScript(Player.CurrentStar, 1);
  CalculatePlayerStarTurnAndWait;
  StarMapWeaponPanelOpen := False;
  StarMapScreen.ResumeMode := 2;
  ScreenLoadMode := 2;
  RestartScreenId := screenStarMap;
  RequestedScreenId := screenLoad;
  RequestClose(1);
end;
{ @end $600E20 }

{ @routine $600F88 TfPlanetNO_StartTextQuest }
procedure TfPlanetNO.StartTextQuest(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if Sender.UserValue <> 0 then
    if ShowMessageBoxGI(Self, LocalizedText('FormGov.QuestCertificate.NotCertificateAttention'), mbgOK or mbgCancel) <> mbgResultOK then Exit;
  CaptureSavePreview;
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
  StandaloneQuestMode := False;
  PlanetQuestReturnScreenId := FormToId(Self);
  RequestedScreenId := screenPlanetQuest;
  RequestClose(1);
end;
{ @end $600F88 }

{ @routine $6010E0 TfPlanetNO_QuestMouseEnter }
procedure TfPlanetNO.QuestMouseEnter(Sender: TObjectGI);
var Frame: Integer;
begin
  MainPanel.ShowControlHelp(Sender, True);
  with GetByName('SearchArtefact') as TgaiGI do
  begin
    Frame := SequenceFrame;
    SetImagePath('Bm.FormPQuest.' + GiResourceSuffix + 'PlanetButA');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetSequenceFrame(Frame);
  end;
end;
{ @end $6010E0 }

{ @routine $6011F8 TfPlanetNO_QuestMouseLeave }
procedure TfPlanetNO.QuestMouseLeave(Sender: TObjectGI);
var Frame: Integer;
begin
  MainPanel.ShowControlHelp(Sender, False);
  with GetByName('SearchArtefact') as TgaiGI do
  begin
    Frame := SequenceFrame;
    SetImagePath('Bm.FormPQuest.' + GiResourceSuffix + 'PlanetButN');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetSequenceFrame(Frame);
  end;
end;
{ @end $6011F8 }

{ @routine $601310 TfPlanetNO_EndTurnClicked }
procedure TfPlanetNO.EndTurnClicked(Sender: TObjectGI);
begin
  MainPanel.EndTurnClicked(Sender);
  MainPanel.RebuildMessageButtons;
end;
{ @end $601310 }

{ @routine $60132C TfPlanetNO_MainPanelKeyDown }
procedure TfPlanetNO.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = VK_SPACE then EndTurnClicked(nil)
  else if Key = Ord('F') then TakeoffClicked(nil)
  else MainPanel.ProcessKeyDown(Key);
end;
{ @end $60132C }

{ @routine $60138C TfPlanetNO_SelectMusic }
procedure TfPlanetNO.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
end;
{ @end $60138C }

end.

unit fPlanet;
// Unit bracket (inferred): CODE 0x0060145C..0x006022C3; inclusive evidence, not full bounds.
interface
uses fPanelMain, fPanelPlanet, GI_MessageLoop, Types;
type
  TfPlanet = class(TMessageLoopGI) // @size $BC
  public
    constructor Create; // @addr $6014E4
    destructor Destroy; override; // @addr $601540
    procedure InitializeLayout; override; // @addr $601594
    procedure OnOpen; override; // @addr $60160C
    procedure OnClose; override; // @addr $6018D8
    procedure RefreshPlanetInfo; // @addr $6018F4 Includes the legacy animated quest prompt.
    procedure StartTextQuest(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $601DCC
    procedure QuestMouseEnter(Sender: TObjectGI); // @addr $601F24
    procedure QuestMouseLeave(Sender: TObjectGI); // @addr $60203C
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $602154
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $602194
    procedure SelectMusic; override; // @addr $6021F4
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4

  end;
implementation

// @unit-initialization $6022BC
// @unit-finalization $60228C

uses Classes, SysUtils, Windows, GR_Main, Globals, GlobalsV, GI_GraphButton,
  GI_GAI, GI_Image, GI_Label, GI_Window, GI_MessageBox, aConst, aMyFunction,
  aGalaxy, aPlanet, aPlayer, aRanger, aSaveLoad, aScript, fEquipmentShop,
  fSaveManager, fPlanetQuest;

{ @routine $6014E4 TfPlanet_Create }
constructor TfPlanet.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
end;
{ @end $6014E4 }

{ @routine $601540 TfPlanet_Destroy }
destructor TfPlanet.Destroy;
begin
  if MainPanel <> nil then
  begin
    MainPanel.Free;
    MainPanel := nil;
  end;
  if PlanetPanel <> nil then
  begin
    PlanetPanel.Free;
    PlanetPanel := nil;
  end;
  inherited Destroy;
end;
{ @end $601540 }

{ @routine $601594 TfPlanet_InitializeLayout }
procedure TfPlanet.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
end;
{ @end $601594 }

{ @routine $60160C TfPlanet_OnOpen }
procedure TfPlanet.OnOpen;
var OldFlag: PMoneyIntegrityFlag;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  MainPanel.OnOpen;
  PlanetPanel.OnOpen;
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
  end;
  Galaxy.ReleaseItemGraphics;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('BGCity') as TImageGI).SetImagePath('GI,Bm.City.' + GiResourceSuffix +
    OwnerInfo[RaceToOwner(Player.CurrentPlanet.RaceId)].InternalName);
  RefreshPlanetInfo;
  if (Player = nil) or ((Player.CurrentPlanet <> nil) and (Player.CurrentStar.ControlFaction = sfKlissan)) then
  begin
    GameEndReason := 2;
    RequestedScreenId := screenGameEnd;
    RequestClose(1);
    Exit;
  end;
  if Player.PendingLiberationCeremonyPlanet = Player.CurrentPlanet then
  begin
    RequestedScreenId := screenGovernment;
    RequestClose(1);
    Exit;
  end;
  if Player.CurrentPlanet.GetRelationLevelToShip(Player) = rlHostile then
  begin
    RequestedScreenId := screenGovernment;
    RequestClose(1);
    Exit;
  end;
  OldFlag := PendingMoneyIntegrityFailure;
  PendingMoneyIntegrityFailure := nil;
  New(PendingMoneyIntegrityFailure);
  PendingMoneyIntegrityFailure^ := OldFlag^;
  OldFlag^ := True;
  Dispose(OldFlag);
  if not Galaxy.MoneyIntegrityFailed then Galaxy.MoneyIntegrityFailed := PendingMoneyIntegrityFailure^;
  MainPanel.RebuildMessageButtons;
end;
{ @end $60160C }

{ @routine $6018D8 TfPlanet_OnClose }
procedure TfPlanet.OnClose;
begin
  MainPanel.OnClose;
  PlanetPanel.OnClose;
end;
{ @end $6018D8 }

{ @routine $6018F4 TfPlanet_RefreshPlanetInfo }
procedure TfPlanet.RefreshPlanetInfo;
var
  I: Integer;
  Window: TWindowGI;
  Quest: PQuest;
  Animation: TgaiGI;
begin
  Window := GetByName('PanelInfo') as TWindowGI;
  with GetByName('PanelInfo_Text') as TLabelGI do
  begin
    SetText(Player.CurrentPlanet.GetCivilInfoText);
    Window.SetSize(Classes.Point(ClientSize.X + Window.WorkSubRect.Left + Window.WorkSubRect.Right,
      ClientSize.Y + Window.WorkSubRect.Top + Window.WorkSubRect.Bottom));
    Window.UpdateAutoGeometry;
    Window.SetPosition(Classes.Point(GameScreenWidth - 10 - Window.ClientSize.X, 10));
    Window.SetActive(True);
    SetPosition(Window.WorkSubRect.TopLeft);
  end;
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
          if (LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').CountParams(IntToStr(Quest.QuestNumber)) > 0) then
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
end;
{ @end $6018F4 }

{ @routine $601DCC TfPlanet_StartTextQuest }
procedure TfPlanet.StartTextQuest(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
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
{ @end $601DCC }

{ @routine $601F24 TfPlanet_QuestMouseEnter }
procedure TfPlanet.QuestMouseEnter(Sender: TObjectGI);
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
{ @end $601F24 }

{ @routine $60203C TfPlanet_QuestMouseLeave }
procedure TfPlanet.QuestMouseLeave(Sender: TObjectGI);
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
{ @end $60203C }

{ @routine $602154 TfPlanet_EndTurnClicked }
procedure TfPlanet.EndTurnClicked(Sender: TObjectGI);
begin
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  RefreshPlanetInfo;
  MainPanel.RebuildMessageButtons;
  if ExitCode = 0 then BuildTemporaryShopSlotGrid;
end;
{ @end $602154 }

{ @routine $602194 TfPlanet_MainPanelKeyDown }
procedure TfPlanet.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = VK_SPACE then EndTurnClicked(nil)
  else
  begin
    MainPanel.ProcessKeyDown(Key);
    PlanetPanel.ProcessKeyDown(Key);
  end;
end;
{ @end $602194 }

{ @routine $6021F4 TfPlanet_SelectMusic }
procedure TfPlanet.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
end;
{ @end $6021F4 }

end.

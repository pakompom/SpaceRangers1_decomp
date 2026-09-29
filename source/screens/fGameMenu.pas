unit fGameMenu;
// Unit bracket (inferred): CODE 0x0054DD04..0x0054E513; inclusive evidence, not full bounds.
// Hovered button help appears in a shared label.
interface
uses GI_MessageLoop, Types;
type
  TfGameMenu = class(TMessageLoopGI) // @size $B0
  public
    procedure InitializeLayout; override; // @addr $54DD8C
    procedure OnOpen; override; // @addr $54DEEC
    procedure OnClose; override; // @addr $54DF74
    procedure ResumeClicked(Sender: TObjectGI); // @addr $54DF78
    procedure SaveClicked(Sender: TObjectGI); // @addr $54DF94
    procedure LoadClicked(Sender: TObjectGI); // @addr $54DFC4
    procedure SettingsClicked(Sender: TObjectGI); // @addr $54DFF4
    procedure ExitClicked(Sender: TObjectGI); // @addr $54E018
    procedure MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $54E0D8
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $54E2B8
    procedure SelectMusic; override; // @addr $54E344
  end;
implementation
// @unit-initialization $54E50C
// @unit-finalization $54E4DC
uses Windows, GR_Main, GR_Music, GI_Main, GI_GraphBuf, GI_GraphButton, GI_Label,
  GI_MessageBox, Globals, GlobalsV, aConst, aPlayer, aShip, aPlanet, aGalaxy, fSaveManager;

{ @routine $54DD8C TfGameMenu_InitializeLayout }
procedure TfGameMenu.InitializeLayout;
begin
  inherited;
  GetByName('MainPanel').MouseMoveCallback := MainPanelMouseMove;
  (GetByName('Resume') as TGraphButtonGI).UpCallback := ResumeClicked;
  (GetByName('Save') as TGraphButtonGI).UpCallback := SaveClicked;
  (GetByName('Load') as TGraphButtonGI).UpCallback := LoadClicked;
  (GetByName('Settings') as TGraphButtonGI).UpCallback := SettingsClicked;
  (GetByName('Exit') as TGraphButtonGI).UpCallback := ExitClicked;
end;
{ @end $54DD8C }

{ @routine $54DEEC TfGameMenu_OnOpen }
procedure TfGameMenu.OnOpen;
begin
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width,
    AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  ContentPanel.KeyDownCallback := MainPanelKeyDown;
end;
{ @end $54DEEC }

{ @routine $54DF74 TfGameMenu_OnClose }
procedure TfGameMenu.OnClose;
begin
end;
{ @end $54DF74 }

{ @routine $54DF78 TfGameMenu_ResumeClicked }
procedure TfGameMenu.ResumeClicked(Sender: TObjectGI);
begin
  RequestedScreenId := GameMenuReturnScreenId;
  RequestClose(1);
end;
{ @end $54DF78 }

{ @routine $54DF94 TfGameMenu_SaveClicked }
procedure TfGameMenu.SaveClicked(Sender: TObjectGI);
begin
  SaveManagerReturnScreenId := GameMenuReturnScreenId;
  SaveManagerMode := smmSave;
  RequestedScreenId := screenSaveManager;
  RequestClose(1);
end;
{ @end $54DF94 }

{ @routine $54DFC4 TfGameMenu_LoadClicked }
procedure TfGameMenu.LoadClicked(Sender: TObjectGI);
begin
  SaveManagerReturnScreenId := GameMenuReturnScreenId;
  SaveManagerMode := smmLoad;
  RequestedScreenId := screenSaveManager;
  RequestClose(1);
end;
{ @end $54DFC4 }

{ @routine $54DFF4 TfGameMenu_SettingsClicked }
procedure TfGameMenu.SettingsClicked(Sender: TObjectGI);
begin
  SettingsReturnScreenId := GameMenuReturnScreenId;
  RequestedScreenId := screenSettings;
  RequestClose(1);
end;
{ @end $54DFF4 }

{ @routine $54E018 TfGameMenu_ExitClicked }
procedure TfGameMenu.ExitClicked(Sender: TObjectGI);
begin
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormGameMenu.QExit'), mbgOK or mbgCancel) = mbgResultOK then
  begin
    if Galaxy <> nil then
    begin
      Galaxy.Free;
      Galaxy := nil;
    end;
    RequestedScreenId := screenMainMenu;
    RequestClose(1);
  end;
end;
{ @end $54E018 }

{ @routine $54E0D8 TfGameMenu_MainPanelMouseMove }
procedure TfGameMenu.MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var HelpLabel: TLabelGI;
begin
  HelpLabel := GetByName('LabelHelp') as TLabelGI;
  if (GetByName('Resume') as TGraphButtonGI).HitTest(Point) then HelpLabel.SetText(GetByName('Resume').HelpText)
  else if (GetByName('Save') as TGraphButtonGI).HitTest(Point) then HelpLabel.SetText(GetByName('Save').HelpText)
  else if (GetByName('Load') as TGraphButtonGI).HitTest(Point) then HelpLabel.SetText(GetByName('Load').HelpText)
  else if (GetByName('Settings') as TGraphButtonGI).HitTest(Point) then HelpLabel.SetText(GetByName('Settings').HelpText)
  else if (GetByName('Exit') as TGraphButtonGI).HitTest(Point) then HelpLabel.SetText(GetByName('Exit').HelpText)
  else HelpLabel.SetText('');
end;
{ @end $54E0D8 }

{ @routine $54E2B8 TfGameMenu_MainPanelKeyDown }
procedure TfGameMenu.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or
    IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = VK_ESCAPE then ResumeClicked(nil)
  else if (Key = Ord('S')) or (Key = VK_F2) then SaveClicked(nil)
  else if (Key = Ord('L')) or (Key = VK_F3) then LoadClicked(nil)
  else if Key = Ord('C') then SettingsClicked(nil)
  else if Key = Ord('E') then ExitClicked(nil);
end;
{ @end $54E2B8 }

{ @routine $54E344 TfGameMenu_SelectMusic }
procedure TfGameMenu.SelectMusic;
begin
  if Player = nil then MusicManager.PlayCategory('Base')
  else if Player.IsOnPlanet then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
  end
  else if Player.IsDockedToShip then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
  end
  else if Player.InNormalSpace then
  begin
    if MusicInSpace then MusicManager.PlayCategory('StarMap')
    else MusicManager.RequestFadeOut;
  end;
end;
{ @end $54E344 }
end.

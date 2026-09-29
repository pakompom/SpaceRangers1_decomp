unit fPanelRuins;
// Unit bracket (inferred): CODE 0x005D0464..0x005D0D87; inclusive evidence, not full bounds.
// Station navigation panel; native VMT $5D0464.
interface
uses EC_Struct, GI_MessageLoop;
type
  TfPanelRuins = class(TObjectEx) // @size $08
  public
    destructor Destroy; override; // @addr $5D04F8
    procedure Show; // @addr $5D088C
    procedure Hide; // @addr $5D08C4
    Screen: TMessageLoopGI; // @offset $04
    constructor Create; // @addr $5D04C0
    procedure InitializeLayout(Screen: TMessageLoopGI; Help: TObjectHelpEventGI); // @addr $5D0520
    procedure OnOpen; // @addr $5D06A8
    procedure OnClose; // @addr $5D0888
    procedure ProcessKeyDown(Key: Cardinal); // @addr $5D0C0C
    procedure GovernmentClicked(Sender: TObjectGI); // @addr $5D08FC
    procedure EquipmentShopClicked(Sender: TObjectGI); // @addr $5D0914
    procedure GoodsShopClicked(Sender: TObjectGI); // @addr $5D092C
    procedure InformationClicked(Sender: TObjectGI); // @addr $5D0944
    procedure TakeoffClicked(Sender: TObjectGI); // @addr $5D095C
  end;
implementation
// @unit-initialization $5D0D80
// @unit-finalization $5D0D50
uses aConst, GI_MessageBox, Globals, aGalaxy, aScript, aSaveLoad, fEquipmentShop, aCalc, fStarMap, fSaveManager, GlobalsV, GI_GraphButton, Classes, aPlayer, aRuins, GR_Main, Windows;

{ @routine $5D04C0 TfPanelRuins_Create }
constructor TfPanelRuins.Create;
begin
  inherited Create;
end;
{ @end $5D04C0 }

{ @routine $5D04F8 TfPanelRuins_Destroy }
destructor TfPanelRuins.Destroy;
begin
  inherited Destroy;
end;
{ @end $5D04F8 }

{ @routine $5D0520 TfPanelRuins_InitializeLayout }
procedure TfPanelRuins.InitializeLayout(Screen: TMessageLoopGI; Help: TObjectHelpEventGI);
begin
  Self.Screen := Screen;
  with Self.Screen.GetByName('PR_Gov') as TGraphButtonGI do
  begin
    UpCallback := GovernmentClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PR_Shop') as TGraphButtonGI do
  begin
    UpCallback := EquipmentShopClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PR_Goods') as TGraphButtonGI do
  begin
    UpCallback := GoodsShopClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PR_Info') as TGraphButtonGI do
  begin
    UpCallback := InformationClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PR_Takeoff') as TGraphButtonGI do
  begin
    UpCallback := TakeoffClicked;
    HelpCallback := Help;
  end;
end;
{ @end $5D0520 }

{ @routine $5D06A8 TfPanelRuins_OnOpen }
procedure TfPanelRuins.OnOpen;
var X, Y: Integer; Flags: TStationServiceFlags;
begin
  X := Screen.GetByName('PR_Gov').LocalPosition.X;
  Y := Screen.GetByName('PR_Gov').LocalPosition.Y;
  Flags := (Player.DockedTo as TRuins).StationFlags;
  with Screen.GetByName('PR_Gov') do
  begin
    SetActive((1 in Flags) or (2 in Flags) or (3 in Flags));
    if Active then
    begin
      SetPosition(Classes.Point(X, Y));
      X := X + ClientSize.X + 2;
    end;
  end;
  with Screen.GetByName('PR_Shop') do
  begin
    SetActive(1 in Flags);
    if Active then
    begin
      SetPosition(Classes.Point(X, Y));
      X := X + ClientSize.X + 2;
    end;
  end;
  with Screen.GetByName('PR_Goods') do
  begin
    SetActive(2 in Flags);
    if Active then
    begin
      SetPosition(Classes.Point(X, Y));
      X := X + ClientSize.X + 2;
    end;
  end;
  with Screen.GetByName('PR_Info') do
  begin
    SetActive(3 in Flags);
    if Active then
    begin
      SetPosition(Classes.Point(X, Y));
    end;
  end;
end;
{ @end $5D06A8 }

{ @routine $5D0888 TfPanelRuins_OnClose }
procedure TfPanelRuins.OnClose;
begin
end;
{ @end $5D0888 }

{ @routine $5D088C TfPanelRuins_Show }
procedure TfPanelRuins.Show;
begin
  Screen.GetByName('PanelRuins').SetActive(True);
end;
{ @end $5D088C }

{ @routine $5D08C4 TfPanelRuins_Hide }
procedure TfPanelRuins.Hide;
begin
  Screen.GetByName('PanelRuins').SetActive(False);
end;
{ @end $5D08C4 }

{ @routine $5D08FC TfPanelRuins_GovernmentClicked }
procedure TfPanelRuins.GovernmentClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenRuinsTalk;
  Screen.RequestClose(1);
end;
{ @end $5D08FC }

{ @routine $5D0914 TfPanelRuins_EquipmentShopClicked }
procedure TfPanelRuins.EquipmentShopClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenEquipmentShop;
  Screen.RequestClose(1);
end;
{ @end $5D0914 }

{ @routine $5D092C TfPanelRuins_GoodsShopClicked }
procedure TfPanelRuins.GoodsShopClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenGoodsShop;
  Screen.RequestClose(1);
end;
{ @end $5D092C }

{ @routine $5D0944 TfPanelRuins_InformationClicked }
procedure TfPanelRuins.InformationClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenInfo;
  Screen.RequestClose(1);
end;
{ @end $5D0944 }

{ @routine $5D095C TfPanelRuins_TakeoffClicked }
procedure TfPanelRuins.TakeoffClicked(Sender: TObjectGI);
var
  Index: Integer;
begin
  if Player.Speed = 0 then
  begin
    if Player.GetCargoFreeSpace < 0 then
      ShowMessageBoxGI(Screen, LocalizedText('FormRuins.ShipOvercharging'), mbgCancel, 0)
    else if Player.Engine = nil then
      ShowMessageBoxGI(Screen, LocalizedText('FormRuins.NotEngine'), mbgCancel, 0)
    else if Player.FuelTanks = nil then
      ShowMessageBoxGI(Screen, LocalizedText('FormRuins.NotFuelTank'), mbgCancel, 0);
  end
  else
  begin
    CaptureSavePreview;
    SaveManagerReturnScreenId := FormToId(Screen);
    SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
    PruneExpiredPersistentPlayerMessages;
    Player.OrderTakeoff;
    for Index := 0 to Galaxy.Scripts.Count - 1 do
      TScript(Galaxy.Scripts[Index]).RunTurnCode;
    StarMapScreen.SetMapCenterManually(TruncatePointF(Player.Position));
    PlayerStar.RefreshSpaceObjectPositions;
    RestoreTemporaryShopStock;
    ClearTemporaryShopSlots;
    RunStarTransitionScript(Player.CurrentStar, 1);
    CalculatePlayerStarTurnAndWait;
    StarMapWeaponPanelOpen := False;
    StarMapScreen.ResumeMode := 2;
    ScreenLoadMode := 2;
    RestartScreenId := screenStarMap;
    RequestedScreenId := screenLoad;
    Screen.RequestClose(1);
  end;
end;
{ @end $5D095C }

{ @routine $5D0C0C TfPanelRuins_ProcessKeyDown }
procedure TfPanelRuins.ProcessKeyDown(Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) and Player.IsDockedToShip then
  begin
    if (Key = Ord('G')) and Screen.GetByName('PR_Gov').Active then GovernmentClicked(nil)
    else if (Key = Ord('E')) and Screen.GetByName('PR_Shop').Active then EquipmentShopClicked(nil)
    else if (Key = Ord('T')) and Screen.GetByName('PR_Goods').Active then GoodsShopClicked(nil)
    else if (Key = Ord('I')) and Screen.GetByName('PR_Info').Active then InformationClicked(nil)
    else if Key = Ord('F') then TakeoffClicked(nil);
  end;
end;
{ @end $5D0C0C }

end.

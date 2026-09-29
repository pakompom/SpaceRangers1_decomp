unit fPanelPlanet;
// Unit bracket (inferred): CODE 0x006022C4..0x00602DA7; inclusive evidence, not full bounds.
// Planet navigation panel; native VMT $602310.
interface
uses EC_Struct, GI_MessageLoop, GI_Planet;
type
  TfPanelPlanet = class(TObjectEx) // @size $10
  public
    Screen: TMessageLoopGI; // @offset $04
    PlanetImage: TPlanetGI; // @offset $08
    RotationTimer: TCallbackTimerIdGI; // @offset $0C
    constructor Create; // @addr $602320
    destructor Destroy; override; // @addr $602358
    procedure InitializeLayout(Screen: TMessageLoopGI; Help: TObjectHelpEventGI); // @addr $602380
    procedure OnOpen; // @addr $602550
    procedure OnClose; // @addr $6026DC
    procedure Show; // @addr $602708
    procedure Hide; // @addr $602740
    procedure HangarClicked(Sender: TObjectGI); // @addr $602778
    procedure EquipmentShopClicked(Sender: TObjectGI); // @addr $6027BC
    procedure GoodsShopClicked(Sender: TObjectGI); // @addr $602934
    procedure GovernmentClicked(Sender: TObjectGI); // @addr $602AAC
    procedure InformationClicked(Sender: TObjectGI); // @addr $602AF0
    procedure PlanetClicked(Sender: TObjectGI); // @addr $602C68
    procedure AdvancePlanetRotation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $602CAC
    procedure ProcessKeyDown(Key: Cardinal); // @addr $602CC8
  end;
implementation

// @unit-initialization $602DA0
// @unit-finalization $602D70

uses GlobalsV, aPlayer, aPlanet, fGov, GI_GraphButton, GR_Main, Windows, Globals, aMyFunction, aConst, GI_MessageBox, Classes, SysUtils;
{ @routine $602320 TfPanelPlanet_Create }
constructor TfPanelPlanet.Create;
begin
  inherited Create;
end;
{ @end $602320 }

{ @routine $602358 TfPanelPlanet_Destroy }
destructor TfPanelPlanet.Destroy;
begin
  inherited Destroy;
end;
{ @end $602358 }

{ @routine $602380 TfPanelPlanet_InitializeLayout }
procedure TfPanelPlanet.InitializeLayout(Screen: TMessageLoopGI; Help: TObjectHelpEventGI);
begin
  Self.Screen := Screen;
  with Self.Screen.GetByName('PP_Hangar') as TGraphButtonGI do
  begin
    UpCallback := HangarClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PP_Shop') as TGraphButtonGI do
  begin
    UpCallback := EquipmentShopClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PP_Goods') as TGraphButtonGI do
  begin
    UpCallback := GoodsShopClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PP_Gov') as TGraphButtonGI do
  begin
    UpCallback := GovernmentClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PP_Planet') as TGraphButtonGI do
  begin
    UpCallback := PlanetClicked;
    HelpCallback := Help;
  end;
  with Self.Screen.GetByName('PP_Info') as TGraphButtonGI do
  begin
    UpCallback := InformationClicked;
    HelpCallback := Help;
  end;
end;
{ @end $602380 }

{ @routine $602550 TfPanelPlanet_OnOpen }
procedure TfPanelPlanet.OnOpen;
var Template: TPlanetTempl; I, N: Integer;
begin
  Template := nil;
  N := PlanetRenderTemplates.Count;
  for I := 0 to N - 1 do
  begin
    Template := TPlanetTempl(PlanetRenderTemplates[I]);
    if Template.Radius = 33 then Break;
  end;
  // The native loop accepts the last template if none has radius 33.
  if Template = nil then raise Exception.Create('Error');
  PlanetImage := TPlanetGI.Create(Screen.GetByName('PanelPlanet'));
  with PlanetImage do
  begin
    if GameScreenWidth = 800 then
    begin
      SetPosition(Classes.Point(37, 36));
      SetImageWithRadius(Template.SmallMaskName, Player.CurrentPlanet.Graphic.ImagePath, Template.SmallLightName, 26);
    end
    else
    begin
      SetPosition(Classes.Point(49, 46));
      SetImageWithRadius(Template.MaskName, Player.CurrentPlanet.Graphic.ImagePath, Template.LightName, 33);
    end;
    SetDepth(8);
    SetLightAngle(223);
    SetSurfaceMapOffset(PlanetPanelRotation);
  end;
  RotationTimer := Screen.ScheduleCallbackTimer(50, 50, AdvancePlanetRotation, 0);
end;
{ @end $602550 }

{ @routine $6026DC TfPanelPlanet_OnClose }
procedure TfPanelPlanet.OnClose;
begin
  if RotationTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(RotationTimer);
    RotationTimer := 0;
  end;
  if PlanetImage <> nil then
  begin
    PlanetImage.Free;
    PlanetImage := nil;
  end;
end;
{ @end $6026DC }

{ @routine $602708 TfPanelPlanet_Show }
procedure TfPanelPlanet.Show;
begin
  Self.Screen.GetByName('PanelPlanet').SetActive(True);
end;
{ @end $602708 }

{ @routine $602740 TfPanelPlanet_Hide }
procedure TfPanelPlanet.Hide;
begin
  Self.Screen.GetByName('PanelPlanet').SetActive(False);
end;
{ @end $602740 }

{ @routine $602778 TfPanelPlanet_HangarClicked }
procedure TfPanelPlanet.HangarClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    RequestedScreenId := screenHangar;
    Screen.RequestClose(1);
  end;
end;
{ @end $602778 }

{ @routine $6027BC TfPanelPlanet_EquipmentShopClicked }
procedure TfPanelPlanet.EquipmentShopClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    if Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad then
      ShowMessageBoxGI(Screen, ReplaceColoredToken(LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
        '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag), mbgCancel, 0)
    else
    begin
      RequestedScreenId := screenEquipmentShop;
      Screen.RequestClose(1);
    end;
  end;
end;
{ @end $6027BC }

{ @routine $602934 TfPanelPlanet_GoodsShopClicked }
procedure TfPanelPlanet.GoodsShopClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    if Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad then
      ShowMessageBoxGI(Screen, ReplaceColoredToken(LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
        '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag), mbgCancel, 0)
    else
    begin
      RequestedScreenId := screenGoodsShop;
      Screen.RequestClose(1);
    end;
  end;
end;
{ @end $602934 }

{ @routine $602AAC TfPanelPlanet_GovernmentClicked }
procedure TfPanelPlanet.GovernmentClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    RequestedScreenId := screenGovernment;
    Screen.RequestClose(1);
  end;
end;
{ @end $602AAC }

{ @routine $602AF0 TfPanelPlanet_InformationClicked }
procedure TfPanelPlanet.InformationClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    if Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad then
      ShowMessageBoxGI(Screen, ReplaceColoredToken(LocalizedColorText('FormShip.SellOrBuyInPlanetAndBadRelations'),
        '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag), mbgCancel, 0)
    else
    begin
      RequestedScreenId := screenInfo;
      Screen.RequestClose(1);
    end;
  end;
end;
{ @end $602AF0 }

{ @routine $602C68 TfPanelPlanet_PlanetClicked }
procedure TfPanelPlanet.PlanetClicked(Sender: TObjectGI);
begin
  if (Player.CurrentPlanet.GetRelationLevelToShip(Player) <> rlHostile) or (GovernmentScreen <> Screen) then
  begin
    RequestedScreenId := screenPlanet;
    Screen.RequestClose(1);
  end;
end;
{ @end $602C68 }

{ @routine $602CAC TfPanelPlanet_AdvancePlanetRotation }
procedure TfPanelPlanet.AdvancePlanetRotation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(PlanetPanelRotation);
  PlanetImage.SetSurfaceMapOffset(PlanetPanelRotation);
end;
{ @end $602CAC }

{ @routine $602CC8 TfPanelPlanet_ProcessKeyDown }
procedure TfPanelPlanet.ProcessKeyDown(Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and
    not IsVirtualKeyDown(VK_MENU) and Player.IsOnPlanet then
    if Key = Ord('H') then HangarClicked(nil)
    else if Key = Ord('E') then EquipmentShopClicked(nil)
    else if Key = Ord('T') then GoodsShopClicked(nil)
    else if Key = Ord('G') then GovernmentClicked(nil)
    else if Key = Ord('I') then InformationClicked(nil)
    else if Key = Ord('P') then PlanetClicked(nil);
end;
{ @end $602CC8 }

end.

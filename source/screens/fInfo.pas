unit fInfo;
// Unit bracket (inferred): CODE 0x0051B870..0x0051F1AB; inclusive evidence, not full bounds.
// Planetary and station news and paid object search.
interface
uses aGalaxy, aPlanet, aItem, GI_Label, GI_MessageLoop, GI_PanelScrollBar, Types,
  fPanelMain, fPanelPlanet, fPanelRuins;
type
  TfInfo = class(TMessageLoopGI) // @size $C8
  public
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4
    StationPanel: TfPanelRuins; // @offset $B8
    InfoPanel: TPanelScrollBarGI; // @offset $BC
    InfoContentHeight: Integer; // @offset $C0
    SearchMode: Boolean; // @offset $C4
    constructor Create; // @addr $51B8F4
    destructor Destroy; override; // @addr $51B960
    procedure InitializeLayout; override; // @addr $51B9CC
    procedure OnOpen; override; // @addr $51BB04
    procedure OnClose; override; // @addr $51BFB4
    procedure RefreshNewsAnimation(Sender: TObjectGI); // @addr $51C004
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $51C208
    procedure ShipClicked(Sender: TObjectGI); // @addr $51C258
    procedure ClearInfoContents; // @addr $51C290
    procedure FinishInfoLayout; // @addr $51C2D8
    procedure AddInfoSpacing(Pixels: Integer); // @addr $51C3C0
    procedure AddInfoHeading(Title, BookmarkText: WideString); // @addr $51C3D8
    procedure AddInfoText(Text: WideString; Alignment: TTextAlignXGI); // @addr $51C76C
    procedure AddInfoImageText(ImagePath, Text: WideString); // @addr $51C868
    procedure AddPlanetInfoText(Planet: TPlanet; Text: WideString); // @addr $51CA88
    procedure AddEquipmentInfoText(Item: TItem; Text: WideString); // @addr $51CCD4
    procedure AddStarInfoText(Star: TStar; Text: WideString); // @addr $51CF14
    procedure ToggleSearchMode(Sender: TObjectGI); // @addr $51D158
    procedure MainPanelMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $51D25C
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $51D2AC
    procedure MainPanelKeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $51D3F0
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $51D3F4
    procedure BookmarkClicked(Sender: TObjectGI); // @addr $51D44C
    procedure SelectMusic; override; // @addr $51D4C8
    procedure ShowNews; // @addr $51D5C4
    procedure ShowSearch; // @addr $51D754
    procedure RunSearch(Sender: TObjectGI); // @addr $51E9D4
  end;
implementation

// @unit-initialization $51F1A4
// @unit-finalization $51F174

uses Classes, SysUtils, Windows, Math, Globals, GlobalsV, GR_Main, GR_Music,
  GR_GraphBuf, GI_Main, GI_Image, GI_GraphBuf, GI_GraphButton, GI_GAI, GI_Edit,
  GI_Panel, aMyFunction, aConst, EC_Str, aPlayer, aShip, aRuins, fShip2,
  fGov, fEquipmentShop, SE_Planet, SE_Star, GR_gi;

{ @routine $51B8F4 TfInfo_Create }
constructor TfInfo.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
  StationPanel := TfPanelRuins.Create;
end;
{ @end $51B8F4 }

{ @routine $51B960 TfInfo_Destroy }
destructor TfInfo.Destroy;
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
  if StationPanel <> nil then
  begin
    StationPanel.Free;
    StationPanel := nil;
  end;
  inherited Destroy;
end;
{ @end $51B960 }

{ @routine $51B9CC TfInfo_InitializeLayout }
procedure TfInfo.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  StationPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  InfoPanel := GetByName('PanelInfo') as TPanelScrollBarGI;
  (GetByName('TextSearch') as TEditGI).ClearFocusOnEnter := False;
end;
{ @end $51B9CC }

{ @routine $51BB04 TfInfo_OnOpen }
procedure TfInfo.OnOpen;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  MainPanel.OnOpen;
  if Player.IsOnPlanet then
  begin
    PlanetPanel.OnOpen;
    PlanetPanel.Show;
    StationPanel.Hide;
  end
  else
  begin
    PlanetPanel.Hide;
    StationPanel.OnOpen;
    StationPanel.Show;
  end;
  with GetByName('MainPanel') do
  begin
    KeyDownCallback := MainPanelKeyDown;
    KeyUpCallback := MainPanelKeyUp;
    LeftButtonDownCallback := MainPanelMouseDown;
  end;
  with GetByName('OkSearch') as TGraphButtonGI do
  begin
    UpCallback := RunSearch;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  MainPanel.RebuildMessageButtons;
  SearchMode := False;
  with GetByName('ButSearch') as TGraphButtonGI do
  begin
    UpCallback := ToggleSearchMode;
    SetActive(not SearchMode);
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  with GetByName('ButNews') as TGraphButtonGI do
  begin
    UpCallback := ToggleSearchMode;
    SetActive(SearchMode);
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  GetByName('PanelSearch').SetActive(SearchMode);
  with GetByName('BGCity') as TImageGI do
    if Player.IsOnPlanet then
      SetImagePath('GI,Bm.City.' + GiResourceSuffix + OwnerInfo[RaceToOwner(Player.CurrentPlanet.RaceId)].InternalName)
    else if Player.DockedTo.ShipType = t_RangerCenter then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'RCbg')
    else if Player.DockedTo.ShipType = t_PirateBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'PBbg')
    else if Player.DockedTo.ShipType = t_MilitaryBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'WBbg')
    else if Player.DockedTo.ShipType = t_ScientificBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'SBbg');
  with GetByName('ImageDict') as TgaiGI do
  begin
    CycleCompleteCallback := RefreshNewsAnimation;
    RestartPlayback;
  end;
  RefreshNewsAnimation(nil);
  ShowNews;
end;
{ @end $51BB04 }

{ @routine $51BFB4 TfInfo_OnClose }
procedure TfInfo.OnClose;
begin
  InfoPanel.FreeOwnedChildren;
  MainPanel.OnClose;
  if (Player <> nil) and Player.IsOnPlanet then PlanetPanel.OnClose
  else StationPanel.OnClose;
end;
{ @end $51BFB4 }

{ @routine $51C004 TfInfo_RefreshNewsAnimation }
procedure TfInfo.RefreshNewsAnimation(Sender: TObjectGI);
var Dice, I: Integer;
begin
  with GetByName('ImageDict') as TgaiGI do
  begin
    if GetImagePath <> 'Bm.FormInfo.' + GiResourceSuffix + 'Anim0a' then Dice := 0
    else Dice := RandomIntRange(0, 100);
    if Dice < 70 then I := 0
    else if Dice <= 80 then I := 1
    else if Dice <= 90 then I := 2
    else I := 3;
    SetImagePath('Bm.FormInfo.' + GiResourceSuffix + 'Anim' + WideString(IntToStr(I)) + 'a');
    SetFirstFrameImagePath('Bm.FormInfo.' + GiResourceSuffix + 'Anim' + WideString(IntToStr(I)) + 'i');
    SequenceIndex := 0;
    UpdateAutoGeometry;
  end;
end;
{ @end $51C004 }

{ @routine $51C208 TfInfo_EndTurnClicked }
procedure TfInfo.EndTurnClicked(Sender: TObjectGI);
begin
  if SearchMode then ToggleSearchMode(nil);
  ShowNews;
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  MainPanel.RebuildMessageButtons;
  if ExitCode = 0 then BuildTemporaryShopSlotGrid;
end;
{ @end $51C208 }

{ @routine $51C258 TfInfo_ShipClicked }
procedure TfInfo.ShipClicked(Sender: TObjectGI);
begin
  MainPanel.ShipClicked(Sender);
  if ShipScreen.RefreshStationDialog then
  begin
    MainPanel.RebuildMessageButtons;
    MainPanel.RefreshMoneyAndCargo;
  end;
end;
{ @end $51C258 }

{ @routine $51C290 TfInfo_ClearInfoContents }
procedure TfInfo.ClearInfoContents;
begin
  InfoContentHeight := 0;
  InfoPanel.FreeOwnedChildren;
  InfoPanel.SetScrollOffset(Classes.Point(0,0));
  InfoPanel.Invalidate;
end;
{ @end $51C290 }

{ @routine $51C2D8 TfInfo_FinishInfoLayout }
procedure TfInfo.FinishInfoLayout;
begin
  InfoPanel.UpdateScrollRanges;
  InfoPanel.VerticalScrollBar.SetRange(0,InfoPanel.VerticalScrollBar.Maximum);
  InfoPanel.VerticalScrollBar.SetActive(InfoPanel.ClientSize.Y < InfoContentHeight);
  InfoPanel.VerticalScrollBar.SetSmallChange((GovernmentScreen.GetByName('TalkText') as TLabelGI).GetLineHeight);
  InfoPanel.VerticalScrollBar.SetLargeChange(InfoPanel.ClientSize.Y);
  InfoPanel.VerticalScrollBar.SetPageSize(InfoPanel.ClientSize.Y);
  InfoPanel.SetScrollOffset(Classes.Point(0,0));
  InfoPanel.Invalidate;
end;
{ @end $51C2D8 }

{ @routine $51C3C0 TfInfo_AddInfoSpacing }
procedure TfInfo.AddInfoSpacing(Pixels: Integer);
begin
  Inc(InfoContentHeight,GiScalePixels(Pixels));
end;
{ @end $51C3C0 }

{ @routine $51C3D8 TfInfo_AddInfoHeading }
procedure TfInfo.AddInfoHeading(Title, BookmarkText: WideString);
var Image: TImageGI; Caption: TLabelGI; Button: TGraphButtonGI;
begin
  Image := TImageGI.Create(InfoPanel);
  Image.SetImagePath('GI,Bm.FormInfo.' + GiResourceSuffix + 'Line');
  Image.SetPosition(Classes.Point(0, InfoContentHeight));
  Image.SetDepth(1);
  Image.SetSize(Classes.Point(InfoPanel.ClientSize.X, Image.GetContentSize.Y + 10));
  Image.SetImageKindX(ikxLeftFill);
  Image.SetImageKindY(ikyCenter);
  Inc(InfoContentHeight, Image.ClientSize.Y);
  Image.SetPositionModeW(True);
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Image.LocalPosition);
  Caption.SetDepth(-1);
  Caption.SetSize(Image.ClientSize);
  Caption.SetWordWrapEnabled(False);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(taxCenter);
  Caption.SetTextAlignY(tayCenterEx);
  Caption.SetText(Title);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  if BookmarkText <> '' then
  begin
    Button := TGraphButtonGI.Create(InfoPanel);
    Button.SetImageNormalPath('GI,Bm.MsgPlayer.' + GiResourceSuffix + 'UserN');
    Button.SetImageNormalActivePath('GI,Bm.MsgPlayer.' + GiResourceSuffix + 'UserA');
    Button.SetImageDownPath('GI,Bm.MsgPlayer.' + GiResourceSuffix + 'UserD');
    Button.SetSize(Button.GetMaxStateImageSize);
    Button.SetPosition(Classes.Point(Image.LocalPosition.X + Image.ClientSize.X - Button.ClientSize.X,
      Image.LocalPosition.Y + Image.ClientSize.Y div 2 - Button.ClientSize.Y div 2));
    Button.SetPositionModeW(True);
    Button.HelpText := BookmarkText;
    Button.UpCallback := BookmarkClicked;
    Button.SetDown(False);
    Button.SetHovered(True);
    Button.Invalidate;
    Button.SetHovered(False);
  end;
end;
{ @end $51C3D8 }

{ @routine $51C76C TfInfo_AddInfoText }
procedure TfInfo.AddInfoText(Text: WideString; Alignment: TTextAlignXGI);
var Caption: TLabelGI;
begin
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Classes.Point(0, InfoContentHeight));
  Caption.SetSize(Classes.Point(InfoPanel.ClientSize.X, 1));
  Caption.SetWordWrapEnabled(True);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(Alignment);
  Caption.SetTextAlignY(tayAuto);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  Inc(InfoContentHeight, Caption.ClientSize.Y);
end;
{ @end $51C76C }

{ @routine $51C868 TfInfo_AddInfoImageText }
procedure TfInfo.AddInfoImageText(ImagePath, Text: WideString);
var Size: Integer; Image: TGraphBufGI; Caption: TLabelGI;
begin
  Size := GiScalePixels(64);
  Image := TGraphBufGI.Create(InfoPanel);
  Image.SetPositionModeW(True);
  Image.SetPosition(Classes.Point(0, InfoContentHeight));
  Image.SetSize(Classes.Point(Size, Size));
  Image.SourceHasPerPixelAlpha := True;
  LoadGiByPathIntoGraphBuf(ImagePath, Image.GraphBuf);
  if Cardinal(Image.GraphBuf.Width) >= Cardinal(Image.GraphBuf.Height) then
    Image.GraphBuf.RescaleRgba(Image.ClientSize.X, Round(Image.ClientSize.X / Cardinal(Image.GraphBuf.Width) * Cardinal(Image.GraphBuf.Height)), 5)
  else Image.GraphBuf.RescaleRgba(Round(Image.ClientSize.Y / Cardinal(Image.GraphBuf.Height) * Cardinal(Image.GraphBuf.Width)), Image.ClientSize.Y, 5);
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Classes.Point(Size + 10, InfoContentHeight));
  Caption.SetSize(Classes.Point(InfoPanel.ClientSize.X - Caption.LocalPosition.X, Size));
  Caption.SetWordWrapEnabled(True);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(taxLeft);
  Caption.SetTextAlignY(tayCenter);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  InfoContentHeight := InfoContentHeight + Size + 5;
end;
{ @end $51C868 }

{ @routine $51CA88 TfInfo_AddPlanetInfoText }
procedure TfInfo.AddPlanetInfoText(Planet: TPlanet; Text: WideString);
var Size: Integer; Image: TGraphBufGI; Caption: TLabelGI;
begin
  Size := GiScalePixels(64);
  Image := TGraphBufGI.Create(InfoPanel);
  Image.SetPositionModeW(True);
  Image.SetPosition(Classes.Point(0, InfoContentHeight));
  Image.SetSize(Classes.Point(Size, Size));
  Image.SourceHasPerPixelAlpha := True;
  Planet.Graphic.RenderToBuffer(Self, Image.GraphBuf, False);
  if Cardinal(Image.GraphBuf.Width) >= Cardinal(Image.GraphBuf.Height) then
    Image.GraphBuf.RescaleRgba(Image.ClientSize.X, Round(Image.ClientSize.X / Cardinal(Image.GraphBuf.Width) * Cardinal(Image.GraphBuf.Height)), 5)
  else Image.GraphBuf.RescaleRgba(Round(Image.ClientSize.Y / Cardinal(Image.GraphBuf.Height) * Cardinal(Image.GraphBuf.Width)), Image.ClientSize.Y, 5);
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Classes.Point(Size + 10, InfoContentHeight));
  Caption.SetSize(Classes.Point(InfoPanel.ClientSize.X - Caption.LocalPosition.X, Size));
  Caption.SetWordWrapEnabled(True);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(taxLeft);
  Caption.SetTextAlignY(tayAuto);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  Size := Max(Size, Caption.ClientSize.Y);
  Caption.SetTextAlignY(tayCenter);
  Caption.SetSize(Classes.Point(Caption.ClientSize.X, Size));
  InfoContentHeight := InfoContentHeight + Size + 5;
end;
{ @end $51CA88 }

{ @routine $51CCD4 TfInfo_AddEquipmentInfoText }
procedure TfInfo.AddEquipmentInfoText(Item: TItem; Text: WideString);
var Size: Integer; Image: TGraphBufGI; Caption: TLabelGI;
begin
  Size := GiScalePixels(64);
  Image := TGraphBufGI.Create(InfoPanel);
  Image.SetPositionModeW(True);
  Image.SetPosition(Classes.Point(0, InfoContentHeight));
  Image.SetSize(Classes.Point(Size, Size));
  Image.SourceHasPerPixelAlpha := True;
  LoadGiByPathIntoGraphBuf(Item.GetBitmapResourceName + 'i', Image.GraphBuf);
  if Cardinal(Image.GraphBuf.Width) >= Cardinal(Image.GraphBuf.Height) then
    Image.GraphBuf.RescaleRgba(Image.ClientSize.X, Round(Image.ClientSize.X / Cardinal(Image.GraphBuf.Width) * Cardinal(Image.GraphBuf.Height)), 5)
  else Image.GraphBuf.RescaleRgba(Round(Image.ClientSize.Y / Cardinal(Image.GraphBuf.Height) * Cardinal(Image.GraphBuf.Width)), Image.ClientSize.Y, 5);
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Classes.Point(Size + 10, InfoContentHeight));
  Caption.SetSize(Classes.Point(InfoPanel.ClientSize.X - Caption.LocalPosition.X, Size));
  Caption.SetWordWrapEnabled(True);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(taxLeft);
  Caption.SetTextAlignY(tayCenter);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  InfoContentHeight := InfoContentHeight + Size + 5;
end;
{ @end $51CCD4 }

{ @routine $51CF14 TfInfo_AddStarInfoText }
procedure TfInfo.AddStarInfoText(Star: TStar; Text: WideString);
var Size: Integer; Image: TGraphBufGI; Caption: TLabelGI;
begin
  Size := GiScalePixels(64);
  Image := TGraphBufGI.Create(InfoPanel);
  Image.SetPositionModeW(True);
  Image.SetPosition(Classes.Point(0, InfoContentHeight));
  Image.SetSize(Classes.Point(Size, Size));
  Image.SourceHasPerPixelAlpha := True;
  LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TStarSE(Star.Graphic).StaticImagePath, 1, ','), Image.GraphBuf);
  if Cardinal(Image.GraphBuf.Width) >= Cardinal(Image.GraphBuf.Height) then
    Image.GraphBuf.RescaleRgba(Image.ClientSize.X, Round(Image.ClientSize.X / Cardinal(Image.GraphBuf.Width) * Cardinal(Image.GraphBuf.Height)), 5)
  else Image.GraphBuf.RescaleRgba(Round(Image.ClientSize.Y / Cardinal(Image.GraphBuf.Height) * Cardinal(Image.GraphBuf.Width)), Image.ClientSize.Y, 5);
  Caption := TLabelGI.Create(InfoPanel);
  Caption.SetFontName(HitPointFontName);
  Caption.SetPosition(Classes.Point(Size + 10, InfoContentHeight));
  Caption.SetSize(Classes.Point(InfoPanel.ClientSize.X - Caption.LocalPosition.X, Size));
  Caption.SetWordWrapEnabled(True);
  Caption.SetPositionModeW(True);
  Caption.SetTextAlignX(taxLeft);
  Caption.SetTextAlignY(tayCenter);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  InfoContentHeight := InfoContentHeight + Size + 5;
end;
{ @end $51CF14 }

{ @routine $51D158 TfInfo_ToggleSearchMode }
procedure TfInfo.ToggleSearchMode(Sender: TObjectGI);
begin
  SearchMode := not SearchMode;
  GetByName('ButSearch').SetActive(not SearchMode);
  GetByName('ButNews').SetActive(SearchMode);
  GetByName('PanelSearch').SetActive(SearchMode);
  if SearchMode then SetFocusedControl(GetByName('TextSearch')) else SetFocusedControl(nil);
  if not SearchMode then ShowNews else ShowSearch;
end;
{ @end $51D158 }

{ @routine $51D25C TfInfo_MainPanelMouseDown }
procedure TfInfo.MainPanelMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  SetFocusedControl(GetByName('TextSearch'));
end;
{ @end $51D25C }

{ @routine $51D2AC TfInfo_MainPanelKeyDown }
procedure TfInfo.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then
    if not (SearchMode and (Key >= Ord('A')) and (Key <= Ord('Z'))) then
    begin
      if Key = VK_HOME then
      begin
        if not SearchMode then InfoPanel.SetScrollOffset(Classes.Point(0, 0));
      end
      else if Key = VK_SPACE then
      begin
        if (GetByName('TextSearch') <> FocusedControl) or not GetByName('TextSearch').Active then EndTurnClicked(nil);
      end
      else if (Key = VK_RETURN) and SearchMode then RunSearch(nil)
      else if (Key = Ord('F')) and not SearchMode then ToggleSearchMode(nil)
      else if Key = Ord('S') then ShipClicked(nil)
      else
      begin
        MainPanel.ProcessKeyDown(Key);
        PlanetPanel.ProcessKeyDown(Key);
        StationPanel.ProcessKeyDown(Key);
      end;
    end;
end;
{ @end $51D2AC }

{ @routine $51D3F0 TfInfo_MainPanelKeyUp }
procedure TfInfo.MainPanelKeyUp(Sender: TObjectGI; Key: Cardinal);
begin
end;
{ @end $51D3F0 }

{ @routine $51D3F4 TfInfo_ProcessMouseWheel }
procedure TfInfo.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then InfoPanel.VerticalScrollBar.SetPosition(InfoPanel.VerticalScrollBar.Position - InfoPanel.VerticalScrollBar.SmallChange)
  else if Delta = -WHEEL_DELTA then InfoPanel.VerticalScrollBar.SetPosition(InfoPanel.VerticalScrollBar.Position + InfoPanel.VerticalScrollBar.SmallChange);
end;
{ @end $51D3F4 }

{ @routine $51D44C TfInfo_BookmarkClicked }
procedure TfInfo.BookmarkClicked(Sender: TObjectGI);
begin
  SoundManager.PlaySound('Sound.UserMsgAdd');
  AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Sender.HelpText, '');
  MainPanel.RebuildMessageButtons;
  Sender.Invalidate;
  Sender.Free;
  BreakUiMessage;
end;
{ @end $51D44C }

{ @routine $51D4C8 TfInfo_SelectMusic }
procedure TfInfo.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else
  begin
    if Player.IsOnPlanet then MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName)
    else if Player.IsDockedToShip then MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
  end;
end;
{ @end $51D4C8 }

{ @routine $51D5C4 TfInfo_ShowNews }
procedure TfInfo.ShowNews;
var I: Integer; Entry: PPlanetNewsEntry;
begin
  ClearInfoContents;
  AddInfoSpacing(10);
  for I := Galaxy.PlanetNews.Count - 1 downto 0 do
  begin
    Entry := Galaxy.PlanetNews[I];
    AddInfoHeading(WrapTextInColor(Galaxy.FormatTurnDate(Entry.Turn), HighlightColorTag),
      WrapTextInColor(Galaxy.FormatTurnDate(Entry.Turn), HighlightColorTag) + #13#10 + ' ' + #13#10 + Entry.Text);
    AddInfoText(' .', taxCenter);
    AddInfoText(Entry.Text, taxAuto);
    AddInfoText(' .', taxCenter);
    AddInfoSpacing(10);
  end;
  FinishInfoLayout;
end;
{ @end $51D5C4 }

{ @routine $51D754 TfInfo_ShowSearch }
procedure TfInfo.ShowSearch;
begin
  ClearInfoContents;
  AddInfoSpacing(20);
  AddInfoText(FormatText2(LocalizedColorText('FormInfo.SearchInfo'), HighlightColorTag, '<Money>', IntToStr(3), '<Count>', IntToStr(30)), taxAuto);
  FinishInfoLayout;
end;
{ @end $51D754 }

{ @routine $51E9D4 TfInfo_RunSearch }
procedure TfInfo.RunSearch(Sender: TObjectGI);
const SearchNameSeparator = WideString(' ');
var
  Ship: TShip;
  ResultCount: Integer;
  Found: Boolean;
  Description, Heading: WideString;
  Planet: TPlanet;
  Star: TStar;
  I, J, K: Integer;
  Search: WideString;
  Item: TItem;

  // @nested $51D8C0 AddSearchResult
  procedure AddSearchResult(Value: TObject); // @addr $51D8C0 @calls "0x0051EB21,0x0051EB88,0x0051EBF7,0x0051EC85,0x0051ECF9,0x0051ED82,0x0051EDE5,0x0051EE6D" Nested in RunSearch; captures the current star, planet and ship.
  const FullNameSeparator = WideString(' ');
  var
    GoodsText, Color: WideString;
    Good: TGoodsIndex;
  begin
    if (Value is TShip) and (Ship <> nil) and not (Ship.OwnerId in CoalitionOwners) then Exit;
    if (Value is TEquipment) and not ((Value as TEquipment).OwnerId in CoalitionOwners) then Exit;
    if ResultCount < 30 then
    begin
      if not Found then
      begin
        AddInfoText(FormatText1(LocalizedText('FormInfo.ObjectFoundStart'),HighlightColorTag,'<Count>',IntToStr(30)),taxCenter);
        AddInfoText(' .',taxCenter);
      end;
      if Value is TShip then
      begin
        Description := FormatText1(LocalizedText('FormInfo.Sector'),HighlightColorTag,'<SectorName>',Ship.CurrentStar.Constellation.GetName);
        Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Star'),HighlightColorTag,'<StarName>',Ship.CurrentStar.Name);
        if Ship.CurrentPlanet <> nil then
          Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Planet'),HighlightColorTag,'<PlanetName>',Ship.CurrentPlanet.Name);
        if Ship.IsInPrison then Description := Description + #13#10 + LocalizedText('FormInfo.InPrison');
        Ship.DaysSincePlayerSeen := 0;
        Heading := WrapTextInColor('- ' + WrapTextInColor(Ship.GetFullName(FullNameSeparator),HighlightColorTag) + ' -',HighlightColorTag);
        AddInfoHeading(Heading,Heading + #13#10 + Description);
        AddInfoText(' .',taxCenter);
        AddInfoImageText(ExtractDelimitedPartW(Ship.GetShipPortraitImagePath,1,','),Description);
      end
      else if Value is TPlanet then
      begin
        Description := FormatText1(LocalizedText('FormInfo.Sector'),HighlightColorTag,'<SectorName>',Planet.CurrentStar.Constellation.GetName);
        Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Star'),HighlightColorTag,'<StarName>',Planet.CurrentStar.Name);
        Description := Description + #13#10 + Planet.GetInfoText;
        GoodsText := '';
        if Planet.IsCoalitionOwned then
        begin
          for Good := t_Food to t_Narcotics do
          begin
            GoodsText := GoodsText + #13#10 + '<td=' + IntToStr(GiScalePixels(5)) + '>' + '<align=center>' + WrapTextInColor(IntToStr(Ord(Good) + 1),'') + '.' + '</align>';
            if PlanetRaceMarket[Planet.RaceId].Goods[Good].Legal then Color := ''
            else Color := RedColorTag;
            GoodsText := GoodsText + '<td=' + IntToStr(GiScalePixels(15)) + '>' + WideString('') + WrapTextInColor(GoodsMarket[Good].DisplayName,Color) + WideString('');
            GoodsText := GoodsText + '<td=' + IntToStr(GiScalePixels(160)) + '>' + '<align=center>' + WrapTextInColor(IntToStr(Planet.Goods[Good].Count),'') + '</align>';
            GoodsText := GoodsText + '<td=' + IntToStr(GiScalePixels(205)) + '><align=right>' + WrapTextInColor(IntToStr(Planet.Goods[Good].PurchasePrice),'') + '</align>';
            GoodsText := GoodsText + '<td=' + IntToStr(GiScalePixels(215)) + '><align=center>' + WrapTextInColor('/','') + '</align>';
            GoodsText := GoodsText + '<td=' + IntToStr(GiScalePixels(245)) + '><align=right>' + WrapTextInColor(IntToStr(Planet.Goods[Good].BaseSalePrice),'') + '</align>';
          end;
        end;
        Description := Description + GoodsText;
        Heading := WrapTextInColor('- ' + WrapTextInColor(Planet.GetFullName(' '),HighlightColorTag) + ' -',HighlightColorTag);
        AddInfoHeading(Heading,Heading + #13#10 + Description);
        AddInfoText(' .',taxCenter);
        AddPlanetInfoText(Value as TPlanet,Description);
      end
      else if Value is TStar then
      begin
        Description := FormatText1(LocalizedText('FormInfo.Sector'),HighlightColorTag,'<SectorName>',Star.Constellation.GetName);
        Heading := WrapTextInColor('- ' + WrapTextInColor((Value as TStar).Name,HighlightColorTag) + ' -',HighlightColorTag);
        AddInfoHeading(Heading,Heading + #13#10 + Description);
        AddInfoText(' .',taxCenter);
        AddStarInfoText(Value as TStar,Description);
      end
      else if Value is TEquipment then
      begin
        if Planet <> nil then
        begin
          Description := FormatText1(LocalizedText('FormInfo.Sector'),HighlightColorTag,'<SectorName>',Planet.CurrentStar.Constellation.GetName);
          Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Star'),HighlightColorTag,'<StarName>',Planet.CurrentStar.Name);
          Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Planet'),HighlightColorTag,'<PlanetName>',Planet.Name);
        end
        else
        begin
          Description := FormatText1(LocalizedText('FormInfo.Sector'),HighlightColorTag,'<SectorName>',Ship.CurrentStar.Constellation.GetName);
          Description := Description + #13#10 + FormatText1(LocalizedText('FormInfo.Star'),HighlightColorTag,'<StarName>',Ship.CurrentStar.Name);
          Description := Description + #13#10 + Ship.GetFullName(FullNameSeparator);
        end;
        Heading := WrapTextInColor('- ' + WrapTextInColor(TItem(Value).GetDisplayName,HighlightColorTag) + ' [' +
          WrapTextInColor(IntToStr(TItem(Value).Weight),GreenColorTag) + ']' + ' -',HighlightColorTag);
        AddInfoHeading(Heading,Heading + #13#10 + Description);
        AddInfoText(' .',taxCenter);
        AddEquipmentInfoText(Value as TItem,Description);
      end;
      Found := True;
      Inc(ResultCount);
    end;
  end;

begin
  if Player.Money < 3 then
    AddInfoText(FormatText1(LocalizedText('FormInfo.NotMoney'),HighlightColorTag,'<Money>',IntToStr(3)),taxCenter)
  else
  begin
    Found := False;
    ResultCount := 0;
    ClearInfoContents;
    AddInfoSpacing(10);
    Search := TrimWideString(LowerCaseWideString((GetByName('TextSearch') as TEditGI).Text));
    if Search = '' then Search := '   ';
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      // Native search order is distance from the player, not Galaxy.Stars order.
      Star := Player.CurrentStar.StarDistances[I].Star as TStar;
      if FindTextPosW(Search,LowerCaseWideString(Star.Name)) > 0 then AddSearchResult(Star);
      Planet := nil;
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := Star.Ships[J];
        if FindTextPosW(Search,LowerCaseWideString(Ship.GetFullName(SearchNameSeparator))) > 0 then AddSearchResult(Ship);
        if Player.DockedTo = Ship then
        begin
          for K := 0 to TemporaryShopSlots.Count - 1 do
          begin
            Item := TShopSlot(TemporaryShopSlots[K]).Item;
            if Item = nil then Continue;
            if FindTextOffsetW(LowerCaseWideString(Item.GetDisplayName),Search,0) >= 0 then AddSearchResult(Item);
          end;
        end
        else if Ship is TRuins then
          for K := 0 to (Ship as TRuins).EquipmentShop.Count - 1 do
          begin
            Item := (Ship as TRuins).EquipmentShop[K];
            if FindTextOffsetW(LowerCaseWideString(Item.GetDisplayName),Search,0) >= 0 then AddSearchResult(Item);
          end;
      end;
      for J := 0 to Star.Planets.Count - 1 do
      begin
        Planet := Star.Planets[J];
        if FindTextPosW(Search,LowerCaseWideString(Planet.GetFullName(' '))) > 0 then AddSearchResult(Planet);
        if Planet.IsCoalitionOwned then
        begin
          if (Player.CurrentPlanet <> nil) and (Player.CurrentPlanet = Planet) then
          begin
            for K := 0 to TemporaryShopSlots.Count - 1 do
            begin
              Item := TShopSlot(TemporaryShopSlots[K]).Item;
              if Item = nil then Continue;
              if FindTextOffsetW(LowerCaseWideString(Item.GetDisplayName),Search,0) >= 0 then AddSearchResult(Item);
            end;
          end
          else
            for K := 0 to Planet.EquipmentShop.Count - 1 do
            begin
              Item := Planet.EquipmentShop[K];
              if FindTextOffsetW(LowerCaseWideString(Item.GetDisplayName),Search,0) >= 0 then AddSearchResult(Item);
            end;
          for K := 0 to Planet.Warriors.Count - 1 do
          begin
            Ship := Planet.Warriors[K];
            if Ship.CurrentStar.Ships.IndexOf(Ship) < 0 then
              if FindTextPosW(Search,LowerCaseWideString(Ship.GetFullName(SearchNameSeparator))) > 0 then AddSearchResult(Ship);
          end;
        end;
      end;
    end;
    if Found then
    begin
      AddInfoHeading(' ','');
      AddInfoText(' .',taxCenter);
      AddInfoText(FormatText1(LocalizedText('FormInfo.ObjectFoundEnd'),HighlightColorTag,'<Count>',IntToStr(ResultCount)),taxCenter);
      Player.SetMoney(Player.Money - 3);
      SoundManager.PlaySound('Sound.Sell');
    end
    else
    begin
      ClearInfoContents;
      AddInfoSpacing(15);
      AddInfoText(LookupLocalizedTextByKey('FormInfo.NotFound'),taxCenter);
      SoundManager.PlaySound('Sound.NoMoney');
    end;
    AddInfoSpacing(100);
    AddInfoText(' .',taxCenter);
    FinishInfoLayout;
  end;
end;
{ @end $51E9D4 }

end.

unit fGoodsShop;
// Unit bracket (inferred): CODE 0x005C9D24..0x005CD8DF; inclusive evidence, not full bounds.
// Goods market: quantity-panel trading, prices and saved market messages.
interface
uses aItem, aShip, fPanelMain, fPanelPlanet, fPanelRuins, GI_MessageLoop;
type
  TfGoodsShop = class(TMessageLoopGI) // @size $D0
  public
    constructor Create; // @addr $5C9DAC
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4
    RuinsPanel: TfPanelRuins; // @offset $B8

    SelectedRow: Integer; // @offset $BC Market rows 0..7, cargo rows 10..17, -1 when none is selected.
    TradePanelHeight: Integer; // @offset $C0
    TradePanelPosition: Integer; // @offset $C4
    TradePanelStep: Integer; // @offset $C8
    TradePanelTimer: TCallbackTimerIdGI; // @offset $CC
    destructor Destroy; override; // @addr $5C9E18
    procedure InitializeLayout; override; // @addr $5C9E84
    procedure OnOpen; override; // @addr $5CA2E4
    procedure OnClose; override; // @addr $5CA6F4
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $5CA754
    procedure ShipClicked(Sender: TObjectGI); // @addr $5CA794
    function GoodsToRow(Good: TItemType): Integer; // @addr $5CA810
    function RowToGoods(Row: Integer): TItemType; // @addr $5CA850
    procedure RefreshGoodsDisplay; // @addr $5CA88C
    procedure GoodsClicked(Sender: TObjectGI); // @addr $5CB990
    procedure RefreshTradeCount(Sender: TObjectGI); // @addr $5CBC6C
    procedure MaximumClicked(Sender: TObjectGI); // @addr $5CC08C
    procedure TradeClicked(Sender: TObjectGI); // @addr $5CC1B8
    procedure CancelClicked(Sender: TObjectGI); // @addr $5CC50C
    procedure ShowTradePanel; // @addr $5CC514
    procedure ResetTradeSelection; // @addr $5CC56C
    procedure SlideTradePanel(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5CC6D0
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $5CC7A4
    procedure SavePricesClicked(Sender: TObjectGI); // @addr $5CC948
    procedure GoodsInfoEnter(Sender: TObjectGI); // @addr $5CD78C
    procedure GoodsInfoLeave(Sender: TObjectGI); // @addr $5CD79C
    procedure SelectMusic; override; // @addr $5CD7AC

  end;
implementation

// @unit-initialization $5CD8D8
// @unit-finalization $5CD8A8

uses Classes, Math, SysUtils, Windows, aConst, aPlanet, aPlayer, aGalaxy,
  aMyFunction, EC_Str, GI_Panel, GI_Image, GI_Label, GI_GraphButton, GI_CountBar,
  GI_MessageBox, GR_Main, GR_GraphBuf, GR_Sound, GR_Music, Globals, GlobalsV,
  fEquipmentShop, fShip2;

{ @routine $5C9DAC TfGoodsShop_Create }
constructor TfGoodsShop.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
  RuinsPanel := TfPanelRuins.Create;
end;
{ @end $5C9DAC }

{ @routine $5C9E18 TfGoodsShop_Destroy }
destructor TfGoodsShop.Destroy;
begin
  if MainPanel <> nil then begin MainPanel.Free; MainPanel := nil; end;
  if PlanetPanel <> nil then begin PlanetPanel.Free; PlanetPanel := nil; end;
  if RuinsPanel <> nil then begin RuinsPanel.Free; RuinsPanel := nil; end;
  inherited Destroy;
end;
{ @end $5C9E18 }

{ @routine $5C9E84 TfGoodsShop_InitializeLayout }
procedure TfGoodsShop.InitializeLayout;
var I: Integer;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  RuinsPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  for I := 0 to 7 do begin
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).DownCallback := GoodsClicked;
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).UpCallback := GoodsClicked;
  end;
  for I := 10 to 17 do begin
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).DownCallback := GoodsClicked;
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).UpCallback := GoodsClicked;
  end;
  (GetByName('TrackCount') as TCountBarGI).PositionChangedCallback := RefreshTradeCount;
  with GetByName('Max') as TGraphButtonGI do begin
    UpCallback := MaximumClicked;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  with GetByName('Ok') as TGraphButtonGI do begin
    UpCallback := TradeClicked;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  with GetByName('Cancel') as TGraphButtonGI do begin
    UpCallback := CancelClicked;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  if GiResourceVariant = 2 then TradePanelHeight := 90 else TradePanelHeight := 70;
  TradePanelPosition := 0;
  TradePanelStep := 0;
  (GetByName('UserMsgAdd') as TGraphButtonGI).UpCallback := SavePricesClicked;
end;
{ @end $5C9E84 }

{ @routine $5CA2E4 TfGoodsShop_OnOpen }
procedure TfGoodsShop.OnOpen;
var I: Integer;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut;
  MainPanel.OnOpen;
  if Player.IsOnPlanet then begin
    PlanetPanel.OnOpen;
    PlanetPanel.Show;
    RuinsPanel.Hide;
  end else begin
    PlanetPanel.Hide;
    RuinsPanel.OnOpen;
    RuinsPanel.Show;
  end;
  for I := 0 to 7 do
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).HelpCallback := MainPanel.ShowControlHelp;
  for I := 10 to 17 do
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).HelpCallback := MainPanel.ShowControlHelp;
  SelectedRow := -1;
  TradePanelPosition := 0;
  TradePanelStep := 0;
  (GetByName('PanelDown') as TPanelGI).SetPosition(Classes.Point(0, TradePanelPosition - TradePanelHeight));
  with GetByName('BGCity') as TImageGI do begin
    if Player.IsOnPlanet then SetImagePath('GI,Bm.City.' + GiResourceSuffix + OwnerInfo[RaceToOwner(Player.CurrentPlanet.RaceId)].InternalName)
    else if Player.DockedTo.ShipType = t_RangerCenter then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'RCbg')
    else if Player.DockedTo.ShipType = t_PirateBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'PBbg')
    else if Player.DockedTo.ShipType = t_MilitaryBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'WBbg')
    else if Player.DockedTo.ShipType = t_ScientificBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'SBbg');
  end;
  RefreshGoodsDisplay;
  MainPanel.RebuildMessageButtons;
end;
{ @end $5CA2E4 }

{ @routine $5CA6F4 TfGoodsShop_OnClose }
procedure TfGoodsShop.OnClose;
begin
  if TradePanelTimer <> 0 then begin CancelCallbackTimer(TradePanelTimer); TradePanelTimer := 0; end;
  MainPanel.OnClose;
  if (Player <> nil) and Player.IsOnPlanet then PlanetPanel.OnClose else RuinsPanel.OnClose;
end;
{ @end $5CA6F4 }

{ @routine $5CA754 TfGoodsShop_EndTurnClicked }
procedure TfGoodsShop.EndTurnClicked(Sender: TObjectGI);
begin
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  if ExitCode = 0 then begin
    BuildTemporaryShopSlotGrid;
    ResetTradeSelection;
    MainPanel.RebuildMessageButtons;
  end;
end;
{ @end $5CA754 }

{ @routine $5CA794 TfGoodsShop_ShipClicked }
procedure TfGoodsShop.ShipClicked(Sender: TObjectGI);
begin
  SetCursorActive(False);
  Present;
  CaptureScreenBackground;
  SetCursorActive(True);
  ShipScreen.PlayTransitionSounds := True;
  repeat
    RunShipEquipment(Self);
    MainPanel.RefreshMoneyAndCargo;
    MainPanel.RebuildMessageButtons;
    if not ShipScreen.SkipOpeningSlide then Break;
    RefreshGoodsDisplay;
    ResetTradeSelection;
    DrawQueuedUpdateRects;
    CaptureScreenBackground;
  until False;
end;
{ @end $5CA794 }

{ @routine $5CA810 TfGoodsShop_GoodsToRow }
function TfGoodsShop.GoodsToRow(Good: TItemType): Integer;
// Presents goods in their 0..7 order.
var I: TGoodsIndex; Row: Integer;
begin
  Row := 0;
  for I := t_Food to t_Narcotics do begin
    if I = Good then begin Result := Row; Exit; end;
    Inc(Row);
  end;
  raise Exception.Create('GoodsTipToN');
end;
{ @end $5CA810 }

{ @routine $5CA850 TfGoodsShop_RowToGoods }
function TfGoodsShop.RowToGoods(Row: Integer): TItemType;
begin
  Result := t_Food;
  repeat
    if Row = 0 then Exit;
    Dec(Row);
    Inc(Result);
  until Result = Succ(t_Narcotics);
  raise Exception.Create('NomToGoodsTip');
end;
{ @end $5CA850 }

{ @routine $5CA88C TfGoodsShop_RefreshGoodsDisplay }
procedure TfGoodsShop.RefreshGoodsDisplay;
var
  Row, SalePrice, AveragePrice: Integer;
  Good: TItemType;
  Text, SaleText, AverageText: WideString;
  Color: Cardinal;
begin
  for Good := t_Food to t_Narcotics do begin
    Row := GoodsToRow(Good);
    with GetByName('Tov' + IntToStr(Row) + 'b') as TImageGI do begin
      if Player.GetLocationGoodsEntry(Good).PurchasePrice < (GoodsMarket[Good].MinPrice + GoodsMarket[Good].BasePrice) / 2 then begin
        SetActive(True);
        SetImageKindX(ikxLeft);
      end else if (Player.GetLocationGoodsEntry(Good).BaseSalePrice > (GoodsMarket[Good].BasePrice + GoodsMarket[Good].MaxPrice) / 2) or
        ((Player.CargoGoods[Good].Count > 0) and (Player.GetLocationGoodsEntry(Good).BaseSalePrice > Player.GetAverageCargoCost(Good))) then begin
        SetActive(True);
        SetImageKindX(ikxRight);
      end else SetActive(False);
    end;
  end;
  for Good := t_Food to t_Narcotics do begin
    Color := CurrentPixelFormat.PackRgbBytes(255, 255, 230);
    if Player.GetLocationGoodsEntry(Good).Count = 0 then Color := CurrentPixelFormat.PackRgbBytes(191, 185, 128);
    Row := GoodsToRow(Good);
    with GetByName('TovPrice' + IntToStr(Row)) as TLabelGI do begin
      SetText(IntToStr(Player.GetLocationGoodsEntry(Good).PurchasePrice));
      SetTextColor(Color);
    end;
    with GetByName('TovCount' + IntToStr(Row)) as TLabelGI do begin
      if Player.GetLocationGoodsEntry(Good).Count > 0 then SetText(IntToStr(Player.GetLocationGoodsEntry(Good).Count)) else SetText('-');
      SetTextColor(Color);
    end;
    with GetByName('Tov' + IntToStr(Row)) as TGraphButtonGI do begin
      SetDisabled(Player.GetLocationGoodsEntry(Good).Count < 1);
      if Player.GetLocationGoodsEntry(Good).Count > 0 then
        HelpText := FormatText1(LookupLocalizedTextByKey('FormGS.BuyHelp'), HighlightColorTag, '<Goods>', LowerCaseWideString(GoodsNames[Good]))
      else HelpText := FormatText1(LookupLocalizedTextByKey('FormGS.NotGoodsForBuyHelp'), HighlightColorTag, '<Goods>', LowerCaseWideString(GoodsNames[Good]));
    end;
    GetByName('Tov' + IntToStr(Row) + 'c').SetActive(Player.IsOnPlanet and not PlanetRaceMarket[Player.CurrentPlanet.RaceId].Goods[Good].Legal);
    with GetByName('Tov' + IntToStr(Row) + 'i') do begin
      if Player.IsOnPlanet and not PlanetRaceMarket[Player.CurrentPlanet.RaceId].Goods[Good].Legal then
        HelpText := GoodsNames[Good] + ' (' + LookupLocalizedTextByKey('FormGS.NotPermit') + ')'
      else HelpText := GoodsNames[Good];
      if Player.GetLocationGoodsEntry(Good).PurchasePrice < (GoodsMarket[Good].MinPrice + GoodsMarket[Good].BasePrice) / 2 then
        HelpText := HelpText + ' ' + WrapTextInColor(LookupLocalizedTextByKey('FormGS.ForExport'), HighlightColorTag)
      else if (Player.GetLocationGoodsEntry(Good).BaseSalePrice > (GoodsMarket[Good].BasePrice + GoodsMarket[Good].MaxPrice) / 2) or
        ((Player.CargoGoods[Good].Count > 0) and (Player.GetLocationGoodsEntry(Good).BaseSalePrice > Player.GetAverageCargoCost(Good))) then
        HelpText := HelpText + ' ' + WrapTextInColor(LookupLocalizedTextByKey('FormGS.ForImport'), HighlightColorTag);
      MouseEnterCallback := GoodsInfoEnter;
      MouseLeaveCallback := GoodsInfoLeave;
    end;
  end;
  for Good := t_Food to t_Narcotics do begin
    Color := CurrentPixelFormat.PackRgbBytes(255, 255, 230);
    if Player.CargoGoods[Good].Count = 0 then Color := CurrentPixelFormat.PackRgbBytes(191, 185, 128);
    Row := GoodsToRow(Good) + 10;
    if Player.CargoGoods[Good].Count > 0 then Text := IntToStr(Player.CargoGoods[Good].Count) else Text := '-';
    with GetByName('TovCount' + IntToStr(Row)) as TLabelGI do begin
      SetText(Text);
      SetTextColor(Color);
    end;
    if Player.CargoGoods[Good].Count > 0 then begin
      AveragePrice := Round(Player.GetAverageCargoCost(Good));
      SalePrice := Player.GetLocationGoodsEntry(Good).BaseSalePrice;
      if SalePrice > AveragePrice then begin
        SaleText := WrapTextInColor(IntToStr(SalePrice), GreenColorTag);
        AverageText := WrapTextInColor(IntToStr(AveragePrice), '');
      end else if SalePrice < AveragePrice then begin
        SaleText := WrapTextInColor(IntToStr(SalePrice), '');
        AverageText := WrapTextInColor(IntToStr(AveragePrice), RedColorTag);
      end else begin
        SaleText := WrapTextInColor(IntToStr(SalePrice), '');
        AverageText := WrapTextInColor(IntToStr(AveragePrice), '');
      end;
      Text := SaleText + '/' + AverageText;
    end else Text := IntToStr(Player.GetLocationGoodsEntry(Good).BaseSalePrice);
    with GetByName('TovPrice' + IntToStr(Row)) as TLabelGI do begin
      SetText(Text);
      SetTextColor(Color);
    end;
    with GetByName('Tov' + IntToStr(Row)) as TGraphButtonGI do begin
      SetDisabled(Player.CargoGoods[Good].Count < 1);
      if Player.CargoGoods[Good].Count > 0 then
        HelpText := FormatText1(LookupLocalizedTextByKey('FormGS.SellHelp'), HighlightColorTag, '<Goods>', LowerCaseWideString(GoodsNames[Good]))
      else HelpText := FormatText1(LookupLocalizedTextByKey('FormGS.NotGoodsForSellHelp'), HighlightColorTag, '<Goods>', LowerCaseWideString(GoodsNames[Good]));
    end;
  end;
  if SelectedRow < 0 then (GetByName('TrackCount') as TCountBarGI).SetRange(0, 0)
  else if SelectedRow < 10 then begin
    Good := RowToGoods(SelectedRow);
    (GetByName('TrackCount') as TCountBarGI).SetRange(0, Player.GetLocationGoodsEntry(Good).Count);
    (GetByName('TrackCount') as TCountBarGI).SetPositionInternal(0);
    GetByName('Ok').HelpText := LocalizedColorText('FormGS.HelpBuy');
  end else begin
    Good := RowToGoods(SelectedRow - 10);
    (GetByName('TrackCount') as TCountBarGI).SetRange(0, Player.CargoGoods[Good].Count);
    (GetByName('TrackCount') as TCountBarGI).SetPositionInternal(0);
    GetByName('Ok').HelpText := LocalizedColorText('FormGS.HelpSell');
  end;
  RefreshTradeCount(nil);
end;
{ @end $5CA88C }

{ @routine $5CB990 TfGoodsShop_GoodsClicked }
procedure TfGoodsShop.GoodsClicked(Sender: TObjectGI);
var I, Row: Integer;
begin
  Row := ExtractDigitsToIntW(Sender.ControlName);
  for I := 0 to 7 do
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).SetDown(I = Row);
  for I := 10 to 17 do
    (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).SetDown(I = Row);
  if Row < 10 then begin
    (GetByName('NameAction') as TLabelGI).SetText(LookupLocalizedTextByKey('FormGS.Buy'));
    with GetByName('ImageCurGoods') as TImageGI do begin
      SetImagePath('GI,' + GetItemTypeBitmapPath(RowToGoods(Row)));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end else begin
    (GetByName('NameAction') as TLabelGI).SetText(LookupLocalizedTextByKey('FormGS.Sell'));
    with GetByName('ImageCurGoods') as TImageGI do begin
      SetImagePath('GI,' + GetItemTypeBitmapPath(RowToGoods(Row - 10)));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end;
  SelectedRow := Row;
  RefreshGoodsDisplay;
  MaximumClicked(nil);
  ShowTradePanel;
end;
{ @end $5CB990 }

{ @routine $5CBC6C TfGoodsShop_RefreshTradeCount }
procedure TfGoodsShop.RefreshTradeCount(Sender: TObjectGI);
var Count: Integer; Good: TGoodsIndex;
begin
  Count := (GetByName('TrackCount') as TCountBarGI).Position;
  if SelectedRow < 0 then begin
    (GetByName('Count') as TLabelGI).SetText('');
    (GetByName('Sum') as TLabelGI).SetText('');
  end else if SelectedRow < 10 then begin
    Good := RowToGoods(SelectedRow);
    (GetByName('Count') as TLabelGI).SetText(IntToStr(Count));
    (GetByName('Sum') as TLabelGI).SetText(IntToStr(Count * Player.GetLocationGoodsEntry(Good).PurchasePrice));
    (GetByName('Ok') as TGraphButtonGI).SetDisabled((Count > Player.GetCargoFreeSpace) or (Count * Player.GetLocationGoodsEntry(Good).PurchasePrice > Player.Money));
    if Count <= Player.GetCargoFreeSpace then
      (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230))
    else (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
    if Count * Player.GetLocationGoodsEntry(Good).PurchasePrice <= Player.Money then
      (GetByName('Sum') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230))
    else (GetByName('Sum') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 0, 0));
  end else begin
    Good := RowToGoods(SelectedRow - 10);
    (GetByName('Count') as TLabelGI).SetText(IntToStr(Count));
    (GetByName('Sum') as TLabelGI).SetText(IntToStr(Count * Player.GetLocationGoodsEntry(Good).BaseSalePrice));
    (GetByName('Ok') as TGraphButtonGI).SetDisabled(Count < 1);
    (GetByName('Count') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
    (GetByName('Sum') as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
  end;
end;
{ @end $5CBC6C }

{ @routine $5CC08C TfGoodsShop_MaximumClicked }
procedure TfGoodsShop.MaximumClicked(Sender: TObjectGI);
var Good: TGoodsIndex; Count: Integer;
begin
  if SelectedRow < 0 then Exit;
  if SelectedRow < 10 then begin
    Good := RowToGoods(SelectedRow);
    Count := Player.GetLocationGoodsEntry(Good).Count;
    if Count > Player.GetCargoFreeSpace then Count := Player.GetCargoFreeSpace;
    if Count * Player.GetLocationGoodsEntry(Good).PurchasePrice > Player.Money then
      Count := Trunc(Player.Money / Player.GetLocationGoodsEntry(Good).PurchasePrice);
    (GetByName('TrackCount') as TCountBarGI).SetPositionInternal(Count);
    RefreshTradeCount(nil);
  end else begin
    Good := RowToGoods(SelectedRow - 10);
    (GetByName('TrackCount') as TCountBarGI).SetPositionInternal(Player.CargoGoods[Good].Count);
    RefreshTradeCount(nil);
  end;
end;
{ @end $5CC08C }

{ @routine $5CC1B8 TfGoodsShop_TradeClicked }
procedure TfGoodsShop.TradeClicked(Sender: TObjectGI);
var Good: TGoodsIndex; Count: Integer;
begin
  if SelectedRow < 0 then Exit;
  if SelectedRow < 10 then begin
    Good := RowToGoods(SelectedRow);
    Count := (GetByName('TrackCount') as TCountBarGI).Position;
    if Count <= 0 then Exit;
    if Count > Player.GetCargoFreeSpace then begin SoundManager.PlaySound('Sound.NoSize'); Exit; end;
    if Count * Player.GetLocationGoodsEntry(Good).PurchasePrice > Player.Money then begin SoundManager.PlaySound('Sound.NoMoney'); Exit; end;
    if Player.IsOnPlanet and not PlanetRaceMarket[Player.CurrentPlanet.RaceId].Goods[Good].Legal then
      if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormGS.NotPermitGoods'), mbgOK or mbgCancel) <> mbgResultOK then begin ResetTradeSelection; Exit; end;
    SoundManager.PlaySound('Sound.Buy');
    Player.BuyGoodsFromLocation(Good, Count);
    ResetTradeSelection;
    if Player.IsOnPlanet and (Player.CurrentPlanet.GetRelationLevelToShip(Player) = rlHostile) then begin
      RequestedScreenId := screenGovernment;
      RequestClose(1);
    end;
  end else begin
    Good := RowToGoods(SelectedRow - 10);
    Count := (GetByName('TrackCount') as TCountBarGI).Position;
    if Count <= 0 then Exit;
    if Player.IsOnPlanet and not PlanetRaceMarket[Player.CurrentPlanet.RaceId].Goods[Good].Legal then
      if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormGS.NotPermitGoods'), mbgOK or mbgCancel) <> mbgResultOK then begin ResetTradeSelection; Exit; end;
    SoundManager.PlaySound('Sound.Sell');
    Player.SellGoodsToLocation(Good, Count);
    ResetTradeSelection;
  end;
end;
{ @end $5CC1B8 }

{ @routine $5CC50C TfGoodsShop_CancelClicked }
procedure TfGoodsShop.CancelClicked(Sender: TObjectGI);
begin
  ResetTradeSelection;
end;
{ @end $5CC50C }

{ @routine $5CC514 TfGoodsShop_ShowTradePanel }
procedure TfGoodsShop.ShowTradePanel;
begin
  if TradePanelPosition < TradePanelHeight then begin
    TradePanelStep := 10;
    if TradePanelTimer <> 0 then begin CancelCallbackTimer(TradePanelTimer); TradePanelTimer := 0; end;
    TradePanelTimer := ScheduleCallbackTimer(35, 35, SlideTradePanel);
  end;
end;
{ @end $5CC514 }

{ @routine $5CC56C TfGoodsShop_ResetTradeSelection }
procedure TfGoodsShop.ResetTradeSelection;
var I: Integer;
begin
  SelectedRow := -1;
  for I := 0 to 7 do (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).SetDown(False);
  for I := 10 to 17 do (GetByName('Tov' + IntToStr(I)) as TGraphButtonGI).SetDown(False);
  RefreshGoodsDisplay;
  if TradePanelPosition > 0 then begin
    TradePanelStep := -10;
    if TradePanelTimer <> 0 then begin CancelCallbackTimer(TradePanelTimer); TradePanelTimer := 0; end;
    TradePanelTimer := ScheduleCallbackTimer(35, 35, SlideTradePanel);
  end;
end;
{ @end $5CC56C }

{ @routine $5CC6D0 TfGoodsShop_SlideTradePanel }
procedure TfGoodsShop.SlideTradePanel(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(TradePanelPosition, TradePanelStep);
  if TradePanelPosition <= 0 then begin
    TradePanelPosition := 0;
    if TradePanelTimer <> 0 then begin CancelCallbackTimer(TradePanelTimer); TradePanelTimer := 0; end;
  end else if TradePanelPosition >= TradePanelHeight then begin
    TradePanelPosition := TradePanelHeight;
    if TradePanelTimer <> 0 then begin CancelCallbackTimer(TradePanelTimer); TradePanelTimer := 0; end;
  end;
  (GetByName('PanelDown') as TPanelGI).SetPosition(Classes.Point((GetByName('PanelDown') as TPanelGI).LocalPosition.X, TradePanelPosition - TradePanelHeight));
end;
{ @end $5CC6D0 }

{ @routine $5CC7A4 TfGoodsShop_MainPanelKeyDown }
procedure TfGoodsShop.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  if (Key = VK_LEFT) and (SelectedRow >= 0) then
    with GetByName('TrackCount') as TCountBarGI do SetPosition(Max(Minimum, Position - 1))
  else if (Key = VK_RIGHT) and (SelectedRow >= 0) then
    with GetByName('TrackCount') as TCountBarGI do SetPosition(Min(Maximum, Position + 1))
  else if (Key = VK_UP) and (SelectedRow >= 0) then MaximumClicked(nil)
  // The native down-arrow path uses Min, even though this can request less than Minimum.
  else if (Key = VK_DOWN) and (SelectedRow >= 0) then
    with GetByName('TrackCount') as TCountBarGI do SetPosition(Min(Minimum, 0))
  else if (Key = VK_RETURN) and (SelectedRow >= 0) then TradeClicked(nil)
  else if Key = VK_SPACE then EndTurnClicked(nil)
  else if Key = Ord('S') then ShipClicked(nil)
  else begin
    MainPanel.ProcessKeyDown(Key);
    PlanetPanel.ProcessKeyDown(Key);
    RuinsPanel.ProcessKeyDown(Key);
  end;
end;
{ @end $5CC7A4 }

{ @routine $5CC948 TfGoodsShop_SavePricesClicked }
procedure TfGoodsShop.SavePricesClicked(Sender: TObjectGI);
var
  Text, Title, Info: WideString;
  Good: TGoodsIndex;
begin
  if Player.CurrentPlanet <> nil then
    Title := FormatText1(LocalizedColorText('FormGS.PlanetInfo'), HighlightColorTag, '<Planet>', Player.CurrentPlanet.Name);
  if Player.DockedTo <> nil then Title := WrapTextInColor(Player.DockedTo.GetName, HighlightColorTag);
  Text := '<td=' + IntToStr(GiScalePixels(0)) + '>' + '<align=left>' + Title + '</align>';
  Text := Text + '<td=' + IntToStr(GiScalePixels(250)) + '>' + '<align=center>' +
    WrapTextInColor(Galaxy.FormatTurnDate(Galaxy.CurrentTurn), GreenColorTag) + '</align>';
  Info := FormatText1(LocalizedColorText('FormGS.StarInfo'), HighlightColorTag, '<Star>', Player.CurrentStar.Name);
  Text := Text + '<td=' + IntToStr(GiScalePixels(470)) + '>' + '<align=center>' + WrapTextInColor(Info, '') + '</align>';
  Text := Text + #13#10 + '---------------------------------------------------------------------------------------------------------';
  Text := Text + #13#10 + '<td=' + IntToStr(GiScalePixels(10)) + '>' + '<align=center>' +
    WrapTextInColor(LocalizedColorText('FormGS.ColumnNumber'), HighlightColorTag) + '</align>';
  Text := Text + '<td=' + IntToStr(GiScalePixels(85)) + '>' + '<align=center>' +
    WrapTextInColor(LocalizedColorText('FormGS.ColumnName'), HighlightColorTag) + '</align>';
  Text := Text + '<td=' + IntToStr(GiScalePixels(210)) + '>' + '<align=center>' +
    WrapTextInColor(LocalizedColorText('FormGS.ColumnCount'), HighlightColorTag) + '</align>';
  Text := Text + '<td=' + IntToStr(GiScalePixels(340)) + '>' + '<align=center>' +
    WrapTextInColor(LocalizedColorText('FormGS.ColumnCost'), HighlightColorTag) + '</align>';
  Text := Text + '<td=' + IntToStr(GiScalePixels(470)) + '>' + '<align=center>' +
    WrapTextInColor(LocalizedColorText('FormGS.ColumnLegality'), HighlightColorTag) + '</align>';
  Text := Text + #13#10 + '---------------------------------------------------------------------------------------------------------';
  for Good := t_Food to t_Narcotics do begin
    Text := Text + #13#10 + '<td=' + IntToStr(GiScalePixels(10)) + '>' + '<align=center>' +
      WrapTextInColor(IntToStr(Ord(Good) + 1), '') + '</align>';
    Text := Text + '<td=' + IntToStr(GiScalePixels(30)) + '>' + '' + WrapTextInColor(GoodsMarket[Good].DisplayName, '') + '';
    Text := Text + '<td=' + IntToStr(GiScalePixels(210)) + '>' + '<align=center>' +
      WrapTextInColor(IntToStr(Player.GetLocationGoodsEntry(Good).Count), '') + '</align>';
    Text := Text + '<td=' + IntToStr(GiScalePixels(325)) + '><align=right>' +
      WrapTextInColor(IntToStr(Player.GetLocationGoodsEntry(Good).PurchasePrice), '') + '</align>';
    Text := Text + '<td=' + IntToStr(GiScalePixels(340)) + '><align=center>' + WrapTextInColor('/', '') + '</align>';
    Text := Text + '<td=' + IntToStr(GiScalePixels(375)) + '><align=right>' +
      WrapTextInColor(IntToStr(Player.GetLocationGoodsEntry(Good).BaseSalePrice), '') + '</align>';
    if Player.CurrentPlanet <> nil then begin
      if PlanetRaceMarket[Player.CurrentPlanet.RaceId].Goods[Good].Legal then Info := LookupLocalizedTextByKey('FormGS.LegalityOk')
      else Info := WrapTextInColor(LookupLocalizedTextByKey('FormGS.LegalityNo'), RedColorTag);
    end else if Player.DockedTo <> nil then Info := LookupLocalizedTextByKey('FormGS.LegalityOk');
    Text := Text + '<td=' + IntToStr(GiScalePixels(465)) + '><align=center>' + WrapTextInColor(Info, '') + '</align>';
  end;
  SoundManager.PlaySound('Sound.UserMsgAdd');
  AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Text, '');
  MainPanel.RebuildMessageButtons;
  BreakUiMessage;
end;
{ @end $5CC948 }
{ @routine $5CD78C TfGoodsShop_GoodsInfoEnter }
procedure TfGoodsShop.GoodsInfoEnter(Sender: TObjectGI);
begin MainPanel.ShowControlHelp(Sender, True); end;
{ @end $5CD78C }

{ @routine $5CD79C TfGoodsShop_GoodsInfoLeave }
procedure TfGoodsShop.GoodsInfoLeave(Sender: TObjectGI);
begin MainPanel.ShowControlHelp(Sender, False); end;
{ @end $5CD79C }

{ @routine $5CD7AC TfGoodsShop_SelectMusic }
procedure TfGoodsShop.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else if Player.IsOnPlanet then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName)
  else if Player.IsDockedToShip then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
end;
{ @end $5CD7AC }

end.

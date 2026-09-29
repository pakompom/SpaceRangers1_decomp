unit fEquipmentShop;
// Unit bracket (inferred): CODE 0x005CD8E0..0x005D0463; inclusive evidence, not full bounds.
// Native stock-slot boundary used by the galaxy save stream and destruction.
interface
uses GI_GAI, GI_Image, fPanelMain, fPanelPlanet, fPanelRuins, GI_MessageLoop, Classes, EC_Buf, EC_Struct, aItem, Types;
type
  TShopSlot = class;
  TShopSlot = class(TObjectEx) // @size $1C
  public
    GridPoint: TPoint; // @offset $04
    Item: TItem; // @offset $0C
    SlotImage: TImageGI; // @offset $10
    ItemIconImage: TImageGI; // @offset $14
    ItemAnimation: TgaiGI; // @offset $18
    destructor Destroy; override; // @addr $5CDEBC
    constructor Create; // @addr $5CDE84
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5CDF80
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5CDF28
  end;
  TfEquipmentShop = class(TMessageLoopGI) // @size $D8
  public
    constructor Create; // @addr $5CDFE8
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4
    RuinsPanel: TfPanelRuins; // @offset $B8
    UnknownBC: Integer; // @offset $BC Cleared when rebuilding stock controls; purpose unresolved.
    ContentColumnCount: Integer; // @offset $C0
    TargetScrollX: Integer; // @offset $C4
    ScrollTimer: TCallbackTimerIdGI; // @offset $C8
    ItemInfoTimer: TCallbackTimerIdGI; // @offset $CC
    OpenPreviewTimer: TCallbackTimerIdGI; // @offset $D0
    PreviewSlot: TShopSlot; // @offset $D4
    destructor Destroy; override; // @addr $5CE054
    procedure InitializeLayout; override; // @addr $5CE0C0
    procedure OnOpen; override; // @addr $5CE1C0
    procedure OnClose; override; // @addr $5CE56C
    procedure ClearGoodsControls; // @addr $5CEB78
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $5CEBE0
    procedure ShipClicked(Sender: TObjectGI); // @addr $5CEC30
    procedure UpdateScrollButtons; // @addr $5CECB4
    procedure StartSlotAnimatedPreview(Slot: TShopSlot); // @addr $5CEDA4
    procedure ScrollLeft(Sender: TObjectGI); // @addr $5CF024
    procedure ScrollRight(Sender: TObjectGI); // @addr $5CF0E4
    procedure PanelScrollChanged(Sender: TObjectGI); // @addr $5CF278
    procedure ChooseAnimatedPreview(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5CF97C
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $5D016C
    procedure ScrollTick(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5CF1B8
    procedure ScheduleSlotPreviewStop(Slot: TShopSlot); // @addr $5CEDF8
    procedure ItemMouseEnter(Sender: TObjectGI); // @addr $5CEE08
    procedure ItemMouseLeave(Sender: TObjectGI); // @addr $5CEF04
    procedure HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5CFA40
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $5D020C
    procedure SelectMusic; override; // @addr $5D0330
    procedure BuildGoodsControls; // @addr $5CE668
    procedure RefreshItemInfo(Item: TItem); // @addr $5CFB24
    procedure ItemMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5CF2C4

  end;
var
  ShopVisibleColumnCount: Integer = 6; // @addr $6188F0
  ShopGridRowCount: Integer = 4; // @addr $6188F4
  TemporaryShopSlots: TList = nil; // @addr $6188F8
  ShopSortMode: Byte = 0; // @addr $6188FC 0 sorts by type then cost, 1 by cost; other values preserve stock order.
function FindShopSlotByItem(Item: TItem): TShopSlot; // @addr $5CDE44
procedure ClearTemporaryShopSlots; // @addr $5CDDB8
procedure RestoreTemporaryShopStock; // @addr $5CDCEC
procedure BuildTemporaryShopSlotGrid; // @addr $5CD9C4
function FindShopSlotByGridPoint(Point: TPoint): TShopSlot; // @addr $5CDDFC
implementation
// @unit-initialization $5D045C
// @unit-finalization $5D042C
uses aGalaxy, GR_Sound, GI_MessageBox, SE_Ship2, EC_Str, Math, Windows, SysUtils, GI_Panel, GI_PanelScrollBar, GI_GraphButton, GI_Label, GR_Main, GR_Music, Globals, fShip2, aConst, aMyFunction, aPlayer, aRuins, aPlanet, GlobalsV;

{ @routine $5CD9C4 BuildTemporaryShopSlotGrid }
procedure BuildTemporaryShopSlotGrid;
var X, Y, EmptyCount, I, J: Integer; Slot, Other: TShopSlot; Item: TItem; Station: TRuins;
begin
  ClearTemporaryShopSlots;
  TemporaryShopSlots := TList.Create;
  if Player.IsOnPlanet then
  begin
    for I := 0 to Player.CurrentPlanet.EquipmentShop.Count - 1 do
    begin
      Item := TItem(Player.CurrentPlanet.EquipmentShop[I]);
      Slot := TShopSlot.Create;
      TemporaryShopSlots.Add(Slot);
      Slot.Item := Item;
    end;
    Player.CurrentPlanet.EquipmentShop.Clear;
  end
  else
  begin
    Station := Player.DockedTo as TRuins;

    for I := 0 to Station.EquipmentShop.Count - 1 do
    begin
      Item := TItem(Station.EquipmentShop[I]);
      Slot := TShopSlot.Create;
      TemporaryShopSlots.Add(Slot);
      Slot.Item := Item;
    end;
    Station.EquipmentShop.Clear;
  end;
  case ShopSortMode of
    0:
      for I := 0 to TemporaryShopSlots.Count - 1 do
      begin
        Slot := TemporaryShopSlots[I];
        if Slot.Item = nil then Continue;
        for J := I to TemporaryShopSlots.Count - 1 do
        begin
          Other := TemporaryShopSlots[J];
          if (Other.Item <> nil) and ((Slot.Item.ItemType > Other.Item.ItemType) or
          ((Slot.Item.ItemType = Other.Item.ItemType) and (Slot.Item.Cost > Other.Item.Cost))) then
          begin
            Item := Slot.Item;
            Slot.Item := Other.Item;
            Other.Item := Item;
          end;
        end;
      end;
    1:
      for I := 0 to TemporaryShopSlots.Count - 1 do
      begin
        Slot := TemporaryShopSlots[I];
        if Slot.Item = nil then Continue;
        for J := I to TemporaryShopSlots.Count - 1 do
        begin
          Other := TemporaryShopSlots[J];
          if (Other.Item <> nil) and (Slot.Item.Cost > Other.Item.Cost) then
          begin
            Item := Slot.Item;
            Slot.Item := Other.Item;
            Other.Item := Item;
          end;
        end;
      end;
  end;
  EmptyCount := 0;
  if TemporaryShopSlots.Count < ShopVisibleColumnCount * ShopGridRowCount then
    EmptyCount := ShopVisibleColumnCount * ShopGridRowCount - TemporaryShopSlots.Count
  else if TemporaryShopSlots.Count mod ShopGridRowCount <> 0 then
    EmptyCount := ShopGridRowCount - TemporaryShopSlots.Count mod ShopGridRowCount;
  for I := 1 to EmptyCount do
  begin
    Slot := TShopSlot.Create;
    Slot.Item := nil;
    TemporaryShopSlots.Add(Slot);
  end;
  EmptyCount := 0;
  for Y := 0 to ShopGridRowCount - 1 do
    for X := 0 to TemporaryShopSlots.Count div ShopGridRowCount - 1 do
    begin
      Slot := TemporaryShopSlots[EmptyCount];
      Slot.GridPoint := Classes.Point(X, Y);
      Inc(EmptyCount);
    end;
end;
{ @end $5CD9C4 }

{ @routine $5CDCEC RestoreTemporaryShopStock }
procedure RestoreTemporaryShopStock;
var I, Count: Integer; Slot: TShopSlot; Station: TRuins;
begin
  if TemporaryShopSlots <> nil then
  begin
    if Player.IsOnPlanet then
    begin
      Count := TemporaryShopSlots.Count;
      for I := 0 to Count - 1 do
      begin
        Slot := TemporaryShopSlots[I];
        if Slot.Item <> nil then Player.CurrentPlanet.EquipmentShop.Add(Slot.Item);
        Slot.Item := nil;
      end;
    end
    else
    begin
      Station := Player.DockedTo as TRuins;
      Count := TemporaryShopSlots.Count;
      for I := 0 to Count - 1 do
      begin
        Slot := TemporaryShopSlots[I];
        if Slot.Item <> nil then Station.EquipmentShop.Add(Slot.Item);
        Slot.Item := nil;
      end;
    end;
    ClearTemporaryShopSlots;
  end;
end;
{ @end $5CDCEC }

{ @routine $5CDDB8 ClearTemporaryShopSlots }
procedure ClearTemporaryShopSlots;
var
  I, Count: Integer;
begin
  if TemporaryShopSlots = nil then Exit;
  Count := TemporaryShopSlots.Count;
  for I := 0 to Count - 1 do TObject(TemporaryShopSlots[I]).Free;
  TemporaryShopSlots.Clear;
  TemporaryShopSlots.Free;
  TemporaryShopSlots := nil;
end;
{ @end $5CDDB8 }

{ @routine $5CDDFC FindShopSlotByGridPoint }
function FindShopSlotByGridPoint(Point: TPoint): TShopSlot;
var
  Count, I: Integer;
  Slot: TShopSlot;
begin
  Count := TemporaryShopSlots.Count;
  for I := 0 to Count - 1 do
  begin
    Slot := TemporaryShopSlots[I];
    if (Slot.GridPoint.X = Point.X) and (Slot.GridPoint.Y = Point.Y) then
    begin
      Result := Slot;
      Exit;
    end;
  end;
  Result := nil;
end;
{ @end $5CDDFC }

{ @routine $5CDE44 FindShopSlotByItem }
function FindShopSlotByItem(Item: TItem): TShopSlot;
var I: Integer;
begin
  for I := 0 to TemporaryShopSlots.Count - 1 do
    if Item = TShopSlot(TemporaryShopSlots[I]).Item then
    begin
      Result := TShopSlot(TemporaryShopSlots[I]);
      Exit;
    end;
  Result := nil;
end;
{ @end $5CDE44 }

{ @routine $5CDE84 TShopSlot_Create }
constructor TShopSlot.Create;
begin
  inherited Create;
end;
{ @end $5CDE84 }

{ @routine $5CDEBC TShopSlot_Destroy }
destructor TShopSlot.Destroy;
begin
  if Item <> nil then begin Item.Free; Item := nil; end;
  if SlotImage <> nil then begin SlotImage.Free; SlotImage := nil; end;
  if ItemIconImage <> nil then begin ItemIconImage.Free; ItemIconImage := nil; end;
  if ItemAnimation <> nil then begin ItemAnimation.Free; ItemAnimation := nil; end;
  inherited Destroy;
end;
{ @end $5CDEBC }

{ @routine $5CDF28 TShopSlot_SaveToBuffer }
procedure TShopSlot.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddAnsiChar(AnsiChar(GridPoint.X));
  Buffer.AddAnsiChar(AnsiChar(GridPoint.Y));
  if Item = nil then Buffer.AddAnsiChar(#0)
  else
  begin
    Buffer.AddAnsiChar(#1);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
end;
{ @end $5CDF28 }

{ @routine $5CDF80 TShopSlot_LoadFromBuffer }
procedure TShopSlot.LoadFromBuffer(Buffer: TBufEC);
var Kind: TItemType;
begin
  GridPoint.X := Buffer.GetByte;
  GridPoint.Y := Buffer.GetByte;
  if Buffer.GetByte = 1 then begin
    WriteByteValue(Buffer.GetByte, Kind);
    Item := CreateItemByType(Kind) as TEquipment;
    TEquipment(Item).LoadFromBuffer(Buffer);
  end;
end;
{ @end $5CDF80 }

{ @routine $5CDFE8 TfEquipmentShop_Create }
constructor TfEquipmentShop.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
  RuinsPanel := TfPanelRuins.Create;
end;
{ @end $5CDFE8 }

{ @routine $5CE054 TfEquipmentShop_Destroy }
destructor TfEquipmentShop.Destroy;
begin
  if MainPanel <> nil then begin MainPanel.Free; MainPanel := nil; end;
  if PlanetPanel <> nil then begin PlanetPanel.Free; PlanetPanel := nil; end;
  if RuinsPanel <> nil then begin RuinsPanel.Free; RuinsPanel := nil; end;
  inherited Destroy;
end;
{ @end $5CE054 }

{ @routine $5CE0C0 TfEquipmentShop_InitializeLayout }
procedure TfEquipmentShop.InitializeLayout;
begin
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  RuinsPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  inherited InitializeLayout;
end;
{ @end $5CE0C0 }

{ @routine $5CE1C0 TfEquipmentShop_OnOpen }
procedure TfEquipmentShop.OnOpen;
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
  with GetByName('BGCity') as TImageGI do
    if Player.IsOnPlanet then
      SetImagePath('GI,Bm.City.' + GiResourceSuffix + OwnerInfo[RaceToOwner(Player.CurrentPlanet.RaceId)].InternalName)
    else if Player.DockedTo.ShipType = t_RangerCenter then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'RCbg')
    else if Player.DockedTo.ShipType = t_PirateBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'PBbg')
    else if Player.DockedTo.ShipType = t_MilitaryBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'WBbg')
    else if Player.DockedTo.ShipType = t_ScientificBase then SetImagePath('GI,Bm.FormRuins.' + GiResourceSuffix + 'SBbg');
  (GetByName('Left') as TGraphButtonGI).DownCallback := ScrollLeft;
  (GetByName('Right') as TGraphButtonGI).DownCallback := ScrollRight;
  GetByName('PII').SetActive(False);
  BuildGoodsControls;
  UpdateScrollButtons;
  PreviewSlot := nil;
  if OpenPreviewTimer <> 0 then begin CancelCallbackTimer(OpenPreviewTimer); OpenPreviewTimer := 0; end;
  if AnimItem then OpenPreviewTimer := ScheduleCallbackTimer(100, 99999, ChooseAnimatedPreview);
  MainPanel.RebuildMessageButtons;
end;
{ @end $5CE1C0 }

{ @routine $5CE56C TfEquipmentShop_OnClose }
procedure TfEquipmentShop.OnClose;
var I, Count: Integer; Slot: TShopSlot;
begin
  if TemporaryShopSlots <> nil then begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do begin
      Slot := TemporaryShopSlots[I];
      if Slot.SlotImage <> nil then begin Slot.SlotImage.Free; Slot.SlotImage := nil; end;
      if Slot.ItemIconImage <> nil then begin Slot.ItemIconImage.Free; Slot.ItemIconImage := nil; end;
      if Slot.ItemAnimation <> nil then begin Slot.ItemAnimation.Free; Slot.ItemAnimation := nil; end;
    end;
  end;
  if OpenPreviewTimer <> 0 then begin CancelCallbackTimer(OpenPreviewTimer); OpenPreviewTimer := 0; end;
  if ScrollTimer <> 0 then begin CancelCallbackTimer(ScrollTimer); ScrollTimer := 0; end;
  if ItemInfoTimer <> 0 then begin CancelCallbackTimer(ItemInfoTimer); ItemInfoTimer := 0; end;
  MainPanel.OnClose;
  if (Player <> nil) and Player.IsOnPlanet then PlanetPanel.OnClose else RuinsPanel.OnClose;
end;
{ @end $5CE56C }

{ @routine $5CE668 TfEquipmentShop_BuildGoodsControls }
procedure TfEquipmentShop.BuildGoodsControls;
var
  Slot: TShopSlot;
  I, Count: Integer;
  Panel: TPanelGI;
  X, Y: Integer;
  CellWidth, CellHeight: Single;
  Image: TImageGI;
  Animation: TgaiGI;
begin
  UnknownBC := 0;
  ContentColumnCount := 0;
  Count := TemporaryShopSlots.Count;
  for I := 0 to Count - 1 do begin
    Slot := TemporaryShopSlots[I];
    if ContentColumnCount <= Slot.GridPoint.X then ContentColumnCount := Slot.GridPoint.X + 1;
  end;
  Panel := GetByName('PanelGoods') as TPanelGI;
  CellWidth := Panel.ClientSize.X / ShopVisibleColumnCount;
  CellHeight := Panel.ClientSize.Y / ShopGridRowCount;
  for Y := 0 to ShopGridRowCount - 1 do
    for X := 0 to ContentColumnCount - 1 do begin
      Slot := FindShopSlotByGridPoint(Classes.Point(X, Y));
      Image := TImageGI.Create(Panel);
      Slot.SlotImage := Image;
      with Image do begin
        SetPositionModeW(True);
        SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
        SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
        SetDepth(3);
        UserValue := Integer(Slot);
        if Slot.Item = nil then SetImagePath('GI,Bm.FormShop.' + GiResourceSuffix + 'selE')
        else begin
          SetImagePath('GI,Bm.FormShop.' + GiResourceSuffix + 'sel' + IntToStr(TEquipment(Slot.Item).GetLevel));
          MouseEnterCallback := ItemMouseEnter;
          MouseLeaveCallback := ItemMouseLeave;
          LeftButtonUpCallback := ItemMouseUp;
        end;
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyBottom);
      end;
      if Slot.Item <> nil then begin
        Image := TImageGI.Create(Panel);
        Slot.ItemIconImage := Image;
        with Image do begin
          SetPositionModeW(True);
          SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
          SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
          SetDepth(2);
          SetActive(True);
          SetImagePath('GI,' + Slot.Item.GetBitmapResourceName + 'i');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetActive(True);
        end;
        if AnimItem then begin
          Animation := TgaiGI.Create(Panel);
          Slot.ItemAnimation := Animation;
          with Animation do begin
            SetPositionModeW(True);
            SetPosition(Classes.Point(Round(X * CellWidth), Round(Y * CellHeight)));
            Animation.SetSize(Classes.Point(Trunc(CellWidth), Trunc(CellHeight)));
            SetDepth(1);
            SetImagePath(Slot.Item.GetBitmapResourceName + 'a');
            SequenceIndex := 0;
            Animation.SetActive(False);
          end;
        end;
      end;
    end;
  (Panel as TPanelScrollBarGI).UpdateScrollRanges;
  Panel.ScrollChangedCallback := PanelScrollChanged;
  TargetScrollX := 0;
  Panel.SetScrollOffset(Classes.Point(0, 0));
end;
{ @end $5CE668 }

{ @routine $5CEB78 TfEquipmentShop_ClearGoodsControls }
procedure TfEquipmentShop.ClearGoodsControls;
var I, Count: Integer; Slot: TShopSlot;
begin
  if TemporaryShopSlots <> nil then begin
    Count := TemporaryShopSlots.Count;
    for I := 0 to Count - 1 do begin
      Slot := TemporaryShopSlots[I];
      if Slot.SlotImage <> nil then begin Slot.SlotImage.Free; Slot.SlotImage := nil; end;
      if Slot.ItemIconImage <> nil then begin Slot.ItemIconImage.Free; Slot.ItemIconImage := nil; end;
      if Slot.ItemAnimation <> nil then begin Slot.ItemAnimation.Free; Slot.ItemAnimation := nil; end;
    end;
  end;
end;
{ @end $5CEB78 }

{ @routine $5CEBE0 TfEquipmentShop_EndTurnClicked }
procedure TfEquipmentShop.EndTurnClicked(Sender: TObjectGI);
begin
  RefreshItemInfo(nil);
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  MainPanel.RebuildMessageButtons;
  if ExitCode = 0 then begin
    BuildTemporaryShopSlotGrid;
    BuildGoodsControls;
    UpdateScrollButtons;
  end;
end;
{ @end $5CEBE0 }

{ @routine $5CEC30 TfEquipmentShop_ShipClicked }
procedure TfEquipmentShop.ShipClicked(Sender: TObjectGI);
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
    ClearGoodsControls;
    BuildGoodsControls;
    UpdateScrollButtons;
    DrawQueuedUpdateRects;
    CaptureScreenBackground;
  until False;
end;
{ @end $5CEC30 }

{ @routine $5CECB4 TfEquipmentShop_UpdateScrollButtons }
procedure TfEquipmentShop.UpdateScrollButtons;
var Panel: TPanelGI;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  with GetByName('Left') as TGraphButtonGI do SetDisabled(Panel.ScrollOffset.X <= 0);
  with GetByName('Right') as TGraphButtonGI do
    SetDisabled(Panel.ScrollOffset.X >= Round(Panel.ClientSize.X / ShopVisibleColumnCount * ContentColumnCount - Panel.ClientSize.X / ShopVisibleColumnCount * ShopVisibleColumnCount) - 1);
end;
{ @end $5CECB4 }

{ @routine $5CEDA4 TfEquipmentShop_StartSlotAnimatedPreview }
procedure TfEquipmentShop.StartSlotAnimatedPreview(Slot: TShopSlot);
begin
  if Slot.ItemAnimation <> nil then
  begin
    if not Slot.ItemAnimation.Active then
    begin
      Slot.ItemAnimation.UpdateAutoGeometry;
      Slot.ItemAnimation.SetImageKindX(ikxCenter);
      Slot.ItemAnimation.SetImageKindY(ikyCenter);
      Slot.ItemAnimation.SetActive(True);
    end;
    Slot.ItemAnimation.RestartPlayback;
    if Slot.ItemIconImage <> nil then
    begin
      Slot.ItemIconImage.Free;
      Slot.ItemIconImage := nil;
    end;
  end;
end;
{ @end $5CEDA4 }

{ @routine $5CEDF8 TfEquipmentShop_ScheduleSlotPreviewStop }
procedure TfEquipmentShop.ScheduleSlotPreviewStop(Slot: TShopSlot);
begin
  if Slot.ItemAnimation <> nil then Slot.ItemAnimation.StopAutoPlayback;
end;
{ @end $5CEDF8 }

{ @routine $5CEE08 TfEquipmentShop_ItemMouseEnter }
procedure TfEquipmentShop.ItemMouseEnter(Sender: TObjectGI);
var Slot: TShopSlot;
begin
  Slot := TShopSlot(Sender.UserValue);
  Slot.SlotImage.SetImagePath('GI,Bm.FormShop.' + GiResourceSuffix + 'selA');
  Slot.SlotImage.SetImageKindX(ikxCenter);
  Slot.SlotImage.SetImageKindY(ikyBottom);
  StartSlotAnimatedPreview(Slot);
  RefreshItemInfo(Slot.Item);
  if not IsCursorImageSelected('Take') then SetCursorByName('Take');
end;
{ @end $5CEE08 }

{ @routine $5CEF04 TfEquipmentShop_ItemMouseLeave }
procedure TfEquipmentShop.ItemMouseLeave(Sender: TObjectGI);
var Slot: TShopSlot;
begin
  Slot := TShopSlot(Sender.UserValue);
  Slot.SlotImage.SetImagePath('GI,Bm.FormShop.' + GiResourceSuffix + 'sel' + IntToStr(TEquipment(Slot.Item).GetLevel));
  Slot.SlotImage.SetImageKindX(ikxCenter);
  Slot.SlotImage.SetImageKindY(ikyBottom);
  ScheduleSlotPreviewStop(Slot);
  RefreshItemInfo(nil);
  if not IsCursorImageSelected('Main') then SetCursorByName('Main');
end;
{ @end $5CEF04 }

{ @routine $5CF024 TfEquipmentShop_ScrollLeft }
procedure TfEquipmentShop.ScrollLeft(Sender: TObjectGI);
var
  Panel: TPanelGI;
  Column: Integer;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  Column := Round((Panel.ScrollOffset.X - Panel.ClientSize.X / ShopVisibleColumnCount) / (Panel.ClientSize.X / ShopVisibleColumnCount));
  if Column < 0 then Column := 0;
  TargetScrollX := Round(Panel.ClientSize.X / ShopVisibleColumnCount * Column);
  if (ScrollTimer = 0) and (TargetScrollX <> Panel.ScrollOffset.X) then ScrollTimer := ScheduleCallbackTimer(0, 20, ScrollTick);
  UpdateScrollButtons;
end;
{ @end $5CF024 }

{ @routine $5CF0E4 TfEquipmentShop_ScrollRight }
procedure TfEquipmentShop.ScrollRight(Sender: TObjectGI);
var
  Panel: TPanelGI;
  Column: Integer;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  Column := Round((Panel.ScrollOffset.X + Panel.ClientSize.X / ShopVisibleColumnCount) / (Panel.ClientSize.X / ShopVisibleColumnCount));
  if Column > ContentColumnCount - ShopVisibleColumnCount then Column := Max(ContentColumnCount - ShopVisibleColumnCount, 0);
  TargetScrollX := Round(Panel.ClientSize.X / ShopVisibleColumnCount * Column);
  if (ScrollTimer = 0) and (TargetScrollX <> Panel.ScrollOffset.X) then ScrollTimer := ScheduleCallbackTimer(0, 20, ScrollTick);
  UpdateScrollButtons;
end;
{ @end $5CF0E4 }

{ @routine $5CF1B8 TfEquipmentShop_ScrollTick }
procedure TfEquipmentShop.ScrollTick(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Panel: TPanelGI;
begin
  Panel := GetByName('PanelGoods') as TPanelGI;
  if Panel.ScrollOffset.X = TargetScrollX then
  begin
    if ScrollTimer <> 0 then
    begin
      CancelCallbackTimer(ScrollTimer);
      ScrollTimer := 0;
    end;
  end
  else if TargetScrollX < Panel.ScrollOffset.X then Panel.SetScrollOffset(Classes.Point(Max(TargetScrollX, Panel.ScrollOffset.X - 12), 0))
  else Panel.SetScrollOffset(Classes.Point(Min(TargetScrollX, Panel.ScrollOffset.X + 12), 0));
  UpdateScrollButtons;
end;
{ @end $5CF1B8 }

{ @routine $5CF278 TfEquipmentShop_PanelScrollChanged }
procedure TfEquipmentShop.PanelScrollChanged(Sender: TObjectGI);
begin
  (GetByName('PanelGoods') as TPanelScrollBarGI).PanelScrollChanged(Sender);
  UpdateScrollButtons;
end;
{ @end $5CF278 }

{ @routine $5CF2C4 TfEquipmentShop_ItemMouseUp }
procedure TfEquipmentShop.ItemMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Slot: TShopSlot;
  Owner: TOwnerId;
  Cost, Armor: Integer;
begin
  Slot := TShopSlot(Sender.UserValue);
  if (Slot = nil) or (Slot.Item = nil) then Exit;
  Galaxy.PendingEquipmentPurchasePrice := Slot.Item.GetConditionAdjustedCost;
  if Slot.Item is THull then
    Galaxy.PendingEquipmentPurchasePrice := Max(1, Galaxy.PendingEquipmentPurchasePrice - Player.Hull.CalculateResaleValue(Player.BaseSkills[skTrader]));
  if Galaxy.PendingEquipmentPurchasePrice > Player.Money then begin
    SoundManager.PlaySound('Sound.NoMoney');
    ShowMessageBoxGI(Self, FormatText1(LanguageDataConfig.GetParamByPath('FormShop.NoMoney'), HighlightColorTag, '<Money>', IntToStr(Galaxy.PendingEquipmentPurchasePrice - Player.Money)), mbgCancel);
    Exit;
  end;
  if not (Slot.Item is THull) and (Player.GetCargoFreeSpace < Slot.Item.Weight) then begin
    SoundManager.PlaySound('Sound.NoSize');
    ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormShop.NoSize'), mbgCancel);
    Exit;
  end;
  if Slot.Item is THull then begin
    if ShowMessageBoxGI(Self, FormatText1(LanguageDataConfig.GetParamByPath('FormShop.UpgradeHull'), HighlightColorTag, '<Money>', IntToStr(Galaxy.PendingEquipmentPurchasePrice)), mbgOK or mbgCancel) <> mbgResultOK then Exit;
  end else begin
    if ShowMessageBoxGI(Self, FormatText2(LanguageDataConfig.GetParamByPath('FormShop.Buy'), HighlightColorTag, '<Item>', Slot.Item.GetDisplayName, '<Money>', IntToStr(Galaxy.PendingEquipmentPurchasePrice)), mbgOK or mbgCancel) <> mbgResultOK then Exit;
  end;
  SoundManager.PlaySound('Sound.Buy');
  Player.SetMoney(Player.Money - Galaxy.PendingEquipmentPurchasePrice);
  if Slot.Item is THull then begin
    Cost := Slot.Item.Cost;
    Armor := (Slot.Item as THull).Armor;
    Player.Hull.Init(True, Slot.Item.Weight, (Slot.Item as THull).TechLevel, Slot.Item.OwnerId);
    Player.Hull.Armor := Armor;
    Player.Hull.Cost := Cost;
    Player.RefreshGraphicSize;
    Owner := Slot.Item.OwnerId;
    Slot.Item.Free;
    Slot.Item := nil;
    Player.Graphic.Free;
    Player.Graphic := TShip2SE.CreateEmpty;
    ShipRenderTemplates[Owner, 0].SpaceObject.CopyTo(Player.Graphic);
    Player.Graphic.SetPosition(Player.Position);
    Player.Graphic.SetAngle(HeadingDegreesToByte(Player.MovementDirection));
    Player.Graphic.SetAlpha(0);
    Player.CollisionRadius := 32;
    Player.RefreshGraphicSize;
  end else begin
    TEquipment(Slot.Item).EquippedFlag := False;
    Player.Inventory.Add(Slot.Item);
    Slot.Item := nil;
  end;
  Player.RefreshDerivedStats;
  with Slot.SlotImage do begin
    SetImagePath('GI,Bm.FormShop.' + GiResourceSuffix + 'selE');
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyBottom);
    MouseEnterCallback := nil;
    MouseLeaveCallback := nil;
    LeftButtonUpCallback := nil;
  end;
  if Slot.ItemIconImage <> nil then begin Slot.ItemIconImage.Free; Slot.ItemIconImage := nil; end;
  if Slot.ItemAnimation <> nil then begin Slot.ItemAnimation.Free; Slot.ItemAnimation := nil; end;
  RefreshItemInfo(nil);
  if not IsCursorImageSelected('Main') then SetCursorByName('Main');
end;
{ @end $5CF2C4 }

{ @routine $5CF97C TfEquipmentShop_ChooseAnimatedPreview }
procedure TfEquipmentShop.ChooseAnimatedPreview(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  I: Integer;
  Slot: TShopSlot;
  Attempts: Integer;
begin
  if TemporaryShopSlots.IndexOf(PreviewSlot) >= 0 then ScheduleSlotPreviewStop(PreviewSlot);
  PreviewSlot := nil;
  Attempts := 20;
  while Attempts > 0 do
  begin
    I := RandomIntRange(0, TemporaryShopSlots.Count - 1);
    Slot := TemporaryShopSlots[I];
    if Slot.Item <> nil then
    begin
      StartSlotAnimatedPreview(Slot);
      PreviewSlot := Slot;
      Break;
    end;
    Dec(Attempts);
  end;
  if OpenPreviewTimer <> 0 then
  begin
    CancelCallbackTimer(OpenPreviewTimer);
    OpenPreviewTimer := 0;
  end;
  if AnimItem then OpenPreviewTimer := ScheduleCallbackTimer(RandomIntRange(3000, 6000), 99999, ChooseAnimatedPreview);
end;
{ @end $5CF97C }

{ @routine $5CFA40 TfEquipmentShop_HideItemInfo }
procedure TfEquipmentShop.HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if ItemInfoTimer <> 0 then begin CancelCallbackTimer(ItemInfoTimer); ItemInfoTimer := 0; end;
  GetByName('PII').SetActive(False);
  (GetByName('InfoText') as TLabelGI).SetText('');
  (GetByName('InfoSize') as TLabelGI).SetText('');
  (GetByName('InfoPrice') as TLabelGI).SetText('');
end;
{ @end $5CFA40 }

{ @routine $5CFB24 TfEquipmentShop_RefreshItemInfo }
procedure TfEquipmentShop.RefreshItemInfo(Item: TItem);
var
  PriceText: WideString;
begin
  Item := Item as TEquipment;
  if Item = nil then begin
    if ItemInfoTimer <> 0 then begin CancelCallbackTimer(ItemInfoTimer); ItemInfoTimer := 0; end;
    ItemInfoTimer := ScheduleCallbackTimer(300, 99999, HideItemInfo);
    MainPanel.HelpLabel.SetActive(False);
    MainPanel.SlideMessagesIn;
    if AnimItem then OpenPreviewTimer := ScheduleCallbackTimer(1000, 99999, ChooseAnimatedPreview);
  end else begin
    if OpenPreviewTimer <> 0 then begin CancelCallbackTimer(OpenPreviewTimer); OpenPreviewTimer := 0; end;
    if TemporaryShopSlots.IndexOf(PreviewSlot) >= 0 then ScheduleSlotPreviewStop(PreviewSlot);
    PreviewSlot := nil;
    if ItemInfoTimer <> 0 then begin CancelCallbackTimer(ItemInfoTimer); ItemInfoTimer := 0; end;
    with MainPanel.HelpLabel do begin
      SetActive(True);
      SetText(FormatText1(LookupLocalizedTextByKey('FormShop.BuyHelp'), HighlightColorTag, '<Item>', TEquipment(Item).GetDisplayName));
    end;
    MainPanel.SlideMessagesOut;
    GetByName('PII').SetActive(True);
    with GetByName('InfoImage') as TImageGI do begin
      SetImagePath('GI,' + TEquipment(Item).GetBitmapResourceName + 's');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
    end;
    (GetByName('InfoName') as TLabelGI).SetText(WrapTextInColor(TEquipment(Item).GetDisplayName, HighlightColorTag));
    (GetByName('InfoText') as TLabelGI).SetText(TEquipment(Item).GetInfoText(HighlightColorTag));
    (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(TEquipment(Item).Weight));
    PriceText := IntToStr(TEquipment(Item).GetConditionAdjustedCost);
    if TEquipment(Item).GetConditionAdjustedCost < TEquipment(Item).Cost then PriceText := WrapTextInColor(PriceText, RedColorTag);
    (GetByName('InfoPrice') as TLabelGI).SetText(PriceText);
    with GetByName('EmRace') as TImageGI do begin
      SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[TEquipment(Item).OwnerId].InternalName));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
    with GetByName('InfoDurable') as TImageGI do
      if not (TEquipment(Item).ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) then SetSize(GetContentSize)
      else if TEquipment(Item).ItemType = t_Hull then
          SetSize(Classes.Point(Round(GetContentSize.X * ((Item as THull).HullPoints / (Item as THull).Weight)), ClientSize.Y))
        else SetSize(Classes.Point(Round(GetContentSize.X * (TEquipment(Item).ConditionPercent / 100)), ClientSize.Y));
  end;
end;
{ @end $5CFB24 }

{ @routine $5D016C TfEquipmentShop_ProcessMouseWheel }
procedure TfEquipmentShop.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if (Delta = WHEEL_DELTA) and not (GetByName('Left') as TGraphButtonGI).Disabled then
  begin
    ScrollLeft(nil);
    RefreshItemInfo(nil);
  end
  else if (Delta = -WHEEL_DELTA) and not (GetByName('Right') as TGraphButtonGI).Disabled then
  begin
    ScrollRight(nil);
    RefreshItemInfo(nil);
  end;
end;
{ @end $5D016C }

{ @routine $5D020C TfEquipmentShop_MainPanelKeyDown }
procedure TfEquipmentShop.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then
  begin
    if Key = Ord('S') then begin ShipClicked(nil); Exit; end;
    if ((Key = VK_LEFT) or (Key = VK_UP)) and not (GetByName('Left') as TGraphButtonGI).Disabled then
    begin
      ScrollLeft(nil);
      RefreshItemInfo(nil);
    end
    else if ((Key = VK_RIGHT) or (Key = VK_DOWN)) and not (GetByName('Right') as TGraphButtonGI).Disabled then
    begin
      ScrollRight(nil);
      RefreshItemInfo(nil);
    end
    else if Key = VK_SPACE then
    begin
      EndTurnClicked(nil);
    end
    else
    begin
      MainPanel.ProcessKeyDown(Key);
      PlanetPanel.ProcessKeyDown(Key);
      RuinsPanel.ProcessKeyDown(Key);
    end;
  end;
end;
{ @end $5D020C }

{ @routine $5D0330 TfEquipmentShop_SelectMusic }
procedure TfEquipmentShop.SelectMusic;
begin
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else if Player.IsOnPlanet then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName)
  else if Player.IsDockedToShip then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
end;
{ @end $5D0330 }
end.

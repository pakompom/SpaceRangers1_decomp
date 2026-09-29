unit fShip2;
// Unit bracket (inferred): CODE 0x005857AC..0x0058F2E3; inclusive evidence, not full bounds.
// Ship screen: equipment slots, ordered cargo entries, rewards and action panels.
interface
uses aItem, GI_MessageLoop, Types, Classes, GI_Panel, GI_Label, GI_Image, GI_Zone, GI_GraphButton, GI_GraphBuf, GI_Window, aNormalShip, aShip;
type
  TPlayerHoldKind = Integer; // @size $04 Native integer discriminator; 0 empty, 1 goods, 2 equipment, 3 artefact.
  TPlayerHoldUnit = class(TObject) // @size $18
  public
    Kind: TPlayerHoldKind; // @offset $04
    GoodsIndex: TGoodsIndex; // @offset $08
    ItemId: Integer; // @offset $0C
    Item: TItem; // @offset $10 Borrowed.
    Retained: Boolean; // @offset $14
  end;
  TfShip2 = class(TMessageLoopGI) // @size $268
  public
    procedure ProcessCallbackTimers; override; // @addr $58EF04
    procedure SelectMusic; override; // @addr $58EF34
    procedure OnOpen; override; // @addr $586774
    procedure UseSelectedArtefact(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58DF30
    procedure SellSelected(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58D65C
    procedure RepairSelected(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58CFD8
    procedure DropSelectedInArcade; // @addr $58CA8C
    procedure DropSelectedOutside(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58C058
    procedure StoreSelectedOnPlanet(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58BB6C
    procedure ShowHoldGoodsInfo(ItemType: TGoodsIndex); // @addr $58EAB0
    procedure ShowEquipmentInfo(Item: TItem); // @addr $58E668
    procedure HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $58E600
    procedure AdvanceItemHover(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $58E5F0
    procedure UpdateItemHover; // @addr $58E34C
    procedure HoldSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58B200
    procedure ArtefactSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58B010
    procedure EquipmentSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58ADBC
    procedure InitializeLayout; override; // @addr $585EF8
    function IsCompatibleSlot(ItemType, SlotType: TItemType): Boolean; // @addr $588D80
    procedure OnClose; override; // @addr $587394
    procedure MainRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58BB4C
    procedure MainLeftButtonUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $58BAAC
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $58BA60
    procedure MainKeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $58BA00
    procedure MainKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $58B894
    procedure ScrollHoldRight(Sender: TObjectGI); // @addr $58B784
    procedure ScrollHoldLeft(Sender: TObjectGI); // @addr $58B778
    procedure ReturnSelectedHoldEntry; // @addr $58B790
    procedure TrainSkillClicked(Sender: TObjectGI); // @addr $58ACF0
    procedure UpdateActionCursor; // @addr $58AB70
    function SlotToTip(SlotName: WideString): TItemType; // @addr $588B6C
    procedure RewardsClicked(Sender: TObjectGI); // @addr $587D2C
    procedure CloseClicked(Sender: TObjectGI); // @addr $587CF4
    procedure PropertyMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $587D88
    procedure RefreshRewardHint(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $588B24
    procedure HidePropertyInfo(Sender: TObjectGI); // @addr $588AE4
    procedure BuildRewardStrip(Ship: TNormalShip); // @addr $587480
    procedure RewardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $587898
    procedure AdvancePanelSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $587C78
    procedure RewardMouseLeave(Sender: TObjectGI); // @addr $587928
    procedure HideRewardInfo; // @addr $587C60
    procedure ShowRewardInfo(Ship: TNormalShip; AwardId: Integer); // @addr $587930
    procedure UpdateSelectedItemActions(Kind: TPlayerHoldKind; Goods: TItemType; Quantity, Cost: Integer; Item: TItem); // @addr $589C70
    procedure ShowPropertyInfo(Sender: TObjectGI); // @addr $587DA8
    procedure RefreshShipView; // @addr $588E88
    ParentLoop: TMessageLoopGI; // @offset $B0
    SkipOpeningSlide: Boolean; // @offset $B4
    ItemInfoPanel: TPanelGI; // @offset $B8
    ItemImage: TImageGI; // @offset $BC
    ItemNameLabel: TLabelGI; // @offset $C0
    ItemDescriptionLabel: TLabelGI; // @offset $C4
    ItemSizeLabel: TLabelGI; // @offset $C8
    ItemPriceLabel: TLabelGI; // @offset $CC
    ItemRaceImage: TImageGI; // @offset $D0
    RightOpenImage: TImageGI; // @offset $D4
    RightCloseImage: TImageGI; // @offset $D8
    SkillsPanel: TPanelGI; // @offset $DC
    FreeSkillPointsLabel: TLabelGI; // @offset $E0
    SkillImages: array[0..5] of TImageGI; // @offset $E4
    SkillButtons: array[0..5] of TGraphButtonGI; // @offset $FC
    ArtefactSlotZones: array[t_ArtefactHull..t_ArtefactAntigrav] of TZoneGI; // @offset $114
    HoldSlotZones: array[0..5] of TZoneGI; // @offset $148
    EquipmentSlotZones: array[0..7,0..4] of TZoneGI; // @offset $160
    BackgroundBuffer: TGraphBufGI; // @offset $200
    ExitButton: TGraphButtonGI; // @offset $204
    RewardsBuffer: TGraphBufGI; // @offset $208
    RewardWindow: TWindowGI; // @offset $20C
    HoldFirstIndex: Integer; // @offset $210
    SelectedHoldKind: TPlayerHoldKind; // @offset $214
    SelectedGoodsIndex: TGoodsIndex; // @offset $218
    SelectedGoodsQuantity: Integer; // @offset $21C
    SelectedGoodsCost: Integer; // @offset $220
    SelectedHoldItem: TItem; // @offset $224
    ActionPanel: TPanelGI; // @offset $228
    Action0Image: TImageGI; // @offset $22C
    Action0Label: TLabelGI; // @offset $230
    Action1Image: TImageGI; // @offset $234
    Action1Label: TLabelGI; // @offset $238
    PanelSlideTimer: TCallbackTimerIdGI; // @offset $23C

    PanelSlideStep: Integer; // @offset $240
    ItemHoverTimer: TCallbackTimerIdGI; // @offset $244
    HideItemTimer: TCallbackTimerIdGI; // @offset $248
    PropertyHintTimer: TCallbackTimerIdGI; // @offset $24C
    ShipImageCenter: TPoint; // @offset $250
    ItemImageCenter: TPoint; // @offset $258
    RefreshStationDialog: Boolean; // @offset $260 Checked after returning to the station dialogue.
    OpenedFromArcade: Boolean; // @offset $261
    HoveredRewardId: Integer; // @offset $264
  end;
const
  phkEmpty = 0;
  phkGoods = 1;
  phkEquipment = 2;
  phkArtefact = 3;
var
  PlayerHoldEntries: TList = nil; // @addr $618804

function GetRankImagePath(Rank: TCoalitionRank): WideString; // @addr $58588C
function GetRaceEmblemPath(Owner: TOwnerId): WideString; // @addr $585A98

procedure InitializePlayerHoldView; // @addr $585B3C

procedure FinalizePlayerHoldView; // @addr $585B54

procedure RefreshPlayerHoldView; // @addr $585B70

function RunShipEquipment(ParentLoop: TMessageLoopGI): Boolean; // @addr $58F0D8

implementation
// @unit-initialization $58F2D0
// @unit-finalization $58F19C
uses aPlanet, GR_Music, SysUtils, Math, EC_Str, EC_Struct, GR_GraphBuf, GR_Main, GR_Sound, aPlayer, aGalaxy, aConst, Globals, GlobalsV, fRewards, Windows, aMyFunction, aRuinsRC, GI_gai, GI_CountBox, GI_MessageBox, aTranclucator, SE_Weapon, aEFilmEnd, ab_Global, ab_Item, ab_Ship, aRuinsSB, aRuins, fEquipmentShop;
{ @routine $58588C GetRankImagePath }
function GetRankImagePath(Rank: TCoalitionRank): WideString;
begin
  if Rank = crRookie then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank0'
  else if Rank = crCadet then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank1'
  else if Rank = crPilot then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank2'
  else if Rank = crWingman then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank3'
  else if Rank = crLeader then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank4'
  else if Rank = crAce then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank5'
  else if Rank = crCommander then Result := 'GI,Bm.FormShip.' + GiResourceSuffix + 'Rank6'
  else RaiseWideMessage('error');
end;
{ @end $58588C }

{ @routine $585A98 GetRaceEmblemPath }
function GetRaceEmblemPath(Owner: TOwnerId): WideString;
begin
  Result := GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Owner].InternalName);
end;
{ @end $585A98 }

{ @routine $585B3C InitializePlayerHoldView }
procedure InitializePlayerHoldView;
begin
  FinalizePlayerHoldView;
  PlayerHoldEntries := TList.Create;
end;
{ @end $585B3C }

{ @routine $585B54 FinalizePlayerHoldView }
procedure FinalizePlayerHoldView;
begin
  if PlayerHoldEntries <> nil then begin
    // Frees only the list here; entry cleanup is confined to refresh.
    PlayerHoldEntries.Free;
    PlayerHoldEntries := nil;
  end;
end;
{ @end $585B54 }

{ @routine $585B70 RefreshPlayerHoldView }
procedure RefreshPlayerHoldView;
var Goods: TGoodsIndex; Entry: TPlayerHoldUnit; I, J: Integer; Item: TEquipment;
begin
  if PlayerHoldEntries = nil then InitializePlayerHoldView;
  for I := 0 to PlayerHoldEntries.Count - 1 do begin
    Entry := PlayerHoldEntries[I];
    Entry.Retained := Entry.Kind = phkEmpty;
  end;
  for Goods := t_Food to t_Narcotics do begin
    if Player.CargoGoods[Goods].Count > 0 then begin
      I := 0;
      while I < PlayerHoldEntries.Count do begin
        Entry := PlayerHoldEntries[I];
        if not Entry.Retained and (Entry.Kind = phkGoods) and (Entry.GoodsIndex = Goods) then begin
          Entry.Retained := True;
          Break;
        end;
        Inc(I);
      end;
      if I >= PlayerHoldEntries.Count then begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Insert(0, Entry);
        Entry.Kind := phkGoods;
        Entry.GoodsIndex := Goods;
        Entry.Retained := True;
      end;
    end;
  end;
  for J := 0 to Player.Inventory.Count - 1 do begin
    Item := TEquipment(Player.Inventory[J]);
    if (Item.ItemType <> t_Hull) and not Item.EquippedFlag then begin
      I := 0;
      while I < PlayerHoldEntries.Count do begin
        Entry := PlayerHoldEntries[I];
        if not Entry.Retained and (Entry.Kind = phkEquipment) and (Item.Id = Entry.ItemId) then begin
          Entry.Retained := True;
          Entry.Item := Item;
          Break;
        end;
        Inc(I);
      end;
      if I >= PlayerHoldEntries.Count then begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Add(Entry);
        Entry.Kind := phkEquipment;
        Entry.ItemId := Item.Id;
        Entry.Item := Item;
        Entry.Retained := True;
      end;
    end;
  end;
  for J := 0 to Player.Artefacts.Count - 1 do begin
    Item := TEquipment(Player.Artefacts[J]);
    if not Item.EquippedFlag then begin
      I := 0;
      while I < PlayerHoldEntries.Count do begin
        Entry := PlayerHoldEntries[I];
        if not Entry.Retained and (Entry.Kind = phkArtefact) and (Item.Id = Entry.ItemId) then begin
          Entry.Retained := True;
          Entry.Item := Item;
          Break;
        end;
        Inc(I);
      end;
      if I >= PlayerHoldEntries.Count then begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Add(Entry);
        Entry.Kind := phkArtefact;
        Entry.ItemId := Item.Id;
        Entry.Item := Item;
        Entry.Retained := True;
      end;
    end;
  end;
  I := PlayerHoldEntries.Count - 1;
  while I >= 0 do begin
    Entry := PlayerHoldEntries[I];
    if Entry.Kind <> phkEmpty then Break;
    Entry.Retained := False;
    Dec(I);
  end;
  I := 0;
  while I < PlayerHoldEntries.Count do begin
    Entry := PlayerHoldEntries[I];
    if not Entry.Retained then begin
      PlayerHoldEntries.Delete(I);
      Entry.Free;
    end else Inc(I);
  end;
end;
{ @end $585B70 }

{ @routine $585EF8 TfShip2_InitializeLayout }
procedure TfShip2.InitializeLayout;
type
  SEquipment = record // @size $08
    ItemType: TItemType; // @offset $00
    Name: WideString; // @offset $04
  end;
const
  ShipEquipmentSlots: array[0..7] of SEquipment = (
    (ItemType: t_FuelTanks; Name: 'FuelTanks'),
    (ItemType: t_Engine; Name: 'Engine'),
    (ItemType: t_Radar; Name: 'Radar'),
    (ItemType: t_Scaner; Name: 'Scaner'),
    (ItemType: t_RepairRobot; Name: 'RepairRobot'),
    (ItemType: t_CargoHook; Name: 'CargoHook'),
    (ItemType: t_DefGenerator; Name: 'DefGenerator'),
    (ItemType: WeaponCategoryItemType; Name: 'Weapon')); // @addr $618808
var I: Integer; ItemType: TItemType; J: Integer;
begin
  inherited InitializeLayout;
  BackgroundBuffer := GetByName('BGBuf') as TGraphBufGI;
  ItemInfoPanel := GetByName('PII') as TPanelGI;
  ItemImage := GetByName('InfoImage') as TImageGI;
  ItemNameLabel := GetByName('InfoName') as TLabelGI;
  ItemDescriptionLabel := GetByName('InfoText') as TLabelGI;
  ItemSizeLabel := GetByName('InfoSize') as TLabelGI;
  ItemPriceLabel := GetByName('InfoPrice') as TLabelGI;
  ItemRaceImage := GetByName('EmRace') as TImageGI;
  RightOpenImage := GetByName('RightOpen') as TImageGI;
  RightCloseImage := GetByName('RightClose') as TImageGI;
  SkillsPanel := GetByName('Skills') as TPanelGI;
  FreeSkillPointsLabel := GetByName('SkillFreePoints') as TLabelGI;
  J := 0;
  for ItemType := t_ArtefactHull to t_ArtefactAntigrav do begin
    ArtefactSlotZones[ItemType] := GetByName('Ar' + IntToStr(J) + 'z') as TZoneGI;
    Inc(J);
  end;
  for J := 0 to 5 do HoldSlotZones[J] := GetByName('S_' + IntToStr(J) + 'z') as TZoneGI;
  for J := 0 to 7 do begin
    for I := 0 to Player.GetSlotCountForItemType(ShipEquipmentSlots[J].ItemType) - 1 do
      EquipmentSlotZones[J,I] := GetByName('S_' + ShipEquipmentSlots[J].Name + '_' + IntToStr(I) + 'z') as TZoneGI;
  end;
  for J := 0 to 5 do begin
    SkillImages[J] := GetByName('Skill' + IntToStr(J)) as TImageGI;
    SkillButtons[J] := GetByName('Skill' + IntToStr(J) + 'Add') as TGraphButtonGI;
  end;
  RewardsBuffer := GetByName('RewardsImg') as TGraphBufGI;
  RewardWindow := GetByName('RewardWnd') as TWindowGI;
  ExitButton := GetByName('Exit') as TGraphButtonGI;
  ExitButton.UpCallback := CloseClicked;
  (GetByName('S_Left') as TGraphButtonGI).UpCallback := ScrollHoldLeft;
  (GetByName('S_Right') as TGraphButtonGI).UpCallback := ScrollHoldRight;
  GetByName('MainPanel').KeyDownCallback := MainKeyDown;
  GetByName('MainPanel').KeyUpCallback := MainKeyUp;
  GetByName('MainPanel').LeftButtonUpCallback := MainLeftButtonUp;
  GetByName('MainPanel').RightButtonDownCallback := MainRightButtonDown;
  ActionPanel := GetByName('PanelAction') as TPanelGI;
  Action0Image := GetByName('Act0i') as TImageGI;
  Action0Label := GetByName('Act0l') as TLabelGI;
  Action1Image := GetByName('Act1i') as TImageGI;
  Action1Label := GetByName('Act1l') as TLabelGI;
  with GetByName('Ship3D') do ShipImageCenter := AddPoints(LocalPosition, HalfPoint(ClientSize));
  with GetByName('InfoImage') do ItemImageCenter := AddPoints(LocalPosition, HalfPoint(ClientSize));
end;
{ @end $585EF8 }

{ @routine $586774 TfShip2_OnOpen }
procedure TfShip2.OnOpen;
var
  I, FaceCount: Integer;
  CharacterName: WideString;
  CaptainAnimation: TgaiGI;
begin
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  BackgroundBuffer.GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  OpenedFromArcade := ArcadeBattleScreen = ParentLoop;
  RefreshStationDialog := False;
  HoldFirstIndex := 0;
  for I := 0 to 5 do
    with GetByName('Skill' + IntToStr(I) + 'z') as TZoneGI do begin
      EnterCallback := ShowPropertyInfo;
      LeaveCallback := HidePropertyInfo;
    end;
  GetByName('PII').SetActive(False);
  CharacterName := Player.GetCharacterName;
  (GetByName('ShipName') as TLabelGI).SetText(Player.GetFullName(#13#10) + #13#10 + ' ' + #13#10 + CharacterName);
  GetByName('RankWnd').SetActive(False);
  with GetByName('RankI') as TImageGI do begin
    MouseEnterCallback := ShowPropertyInfo;
    MouseLeaveCallback := HidePropertyInfo;
    if Player.Rank = crRookie then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank0')
    else if Player.Rank = crCadet then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank1')
    else if Player.Rank = crPilot then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank2')
    else if Player.Rank = crWingman then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank3')
    else if Player.Rank = crLeader then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank4')
    else if Player.Rank = crAce then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank5')
    else if Player.Rank = crCommander then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank6');
  end;
  with GetByName('RankAdd') as TImageGI do begin
    MouseEnterCallback := ShowPropertyInfo;
    MouseLeaveCallback := HidePropertyInfo;
    SetActive(Player.CanPromoteRank);
  end;
  with GetByName('KlingCom') do begin
    SetActive(Player.HaveCommunicator);
    MouseMoveCallback := PropertyMouseMove;
    MouseLeaveCallback := HidePropertyInfo;
  end;
  with GetByName('KlingCoor') do begin
    SetActive(Player.HaveHyperspaceLocator);
    MouseMoveCallback := PropertyMouseMove;
    MouseLeaveCallback := HidePropertyInfo;
  end;
  if (Player.AwardIds = nil) or (Player.AwardIds.Count < 1) then
  begin
    GetByName('RewardBut').SetActive(False);
    GetByName('RewardBG').SetActive(False);
    GetByName('RewardLabel').SetActive(False);
  end
  else
  begin
    with GetByName('RewardBut') as TGraphButtonGI do
    begin
      UpCallback := RewardsClicked;
      SetActive(True);
    end;
    GetByName('RewardBG').SetActive(True);
    with GetByName('RewardLabel') as TLabelGI do
    begin
      SetText(IntToStr(Player.AwardIds.Count));
      SetActive(True);
    end;
  end;
  with GetByName('Ship3D') as TImageGI do begin
    SetImagePath(ShipRenderTemplates[Player.Hull.OwnerId, 0].PortraitImagePath);
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetPosition(SubtractPoints(ShipImageCenter, GetVisualCenter));
  end;
  GetByName('S_Left').SetActive(False);
  GetByName('S_Right').SetActive(False);
  GetByName('S_Left').SetActive(True);
  GetByName('S_Right').SetActive(True);
  FaceCount := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Player.OwnerId].InternalName));
  I := 0;
  with GetByName('CaptainI') as TImageGI do
    if FaceCount > 0 then
    begin
      SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Player.OwnerId].InternalName + IntToStr(I) + 'i');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end else SetActive(False);
  CaptainAnimation := GetByName('CaptainA') as TgaiGI;
  with CaptainAnimation do
  begin
    FirstFrameOnly := not AnimCaptain;
    if FaceCount > 0 then
    begin
      SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Player.OwnerId].InternalName + IntToStr(I) + 'a');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end
    else CaptainAnimation.SetActive(False);
  end;
  BuildRewardStrip(Player);
  RefreshShipView;
  InvalidateViewport;
  DrawQueuedUpdateRects;
  if PanelSlideTimer <> 0 then begin
    CancelCallbackTimer(PanelSlideTimer);
    PanelSlideTimer := 0;
  end;
  if not SkipOpeningSlide then begin
    if GiResourceVariant = 2 then GetByName('Left').SetPosition(Classes.Point(355, GetByName('Left').LocalPosition.Y))
    else GetByName('Left').SetPosition(Classes.Point(277, GetByName('Left').LocalPosition.Y));
    PanelSlideStep := -30;
    PanelSlideTimer := ScheduleCallbackTimer(20, 20, AdvancePanelSlide, 0);
  end else GetByName('Left').SetPosition(Classes.Point(0, GetByName('Left').LocalPosition.Y));
  if ItemHoverTimer <> 0 then begin
    CancelCallbackTimer(ItemHoverTimer);
    ItemHoverTimer := 0;
  end;
  ItemHoverTimer := ScheduleCallbackTimer(100, 100, AdvanceItemHover, 0);
  SkipOpeningSlide := False;
end;
{ @end $586774 }

{ @routine $587394 TfShip2_OnClose }
procedure TfShip2.OnClose;
begin
  if ItemHoverTimer <> 0 then begin CancelCallbackTimer(ItemHoverTimer); ItemHoverTimer := 0; end;
  if HideItemTimer <> 0 then begin CancelCallbackTimer(HideItemTimer); HideItemTimer := 0; end;
  if PropertyHintTimer <> 0 then begin CancelCallbackTimer(PropertyHintTimer); PropertyHintTimer := 0; end;
  ReturnSelectedHoldEntry;
  if PanelSlideTimer <> 0 then begin CancelCallbackTimer(PanelSlideTimer); PanelSlideTimer := 0; end;
  Player.RefreshDerivedStats;
  if Player.Order = soJump then
    if Player.JumpRange < Round(PointDistance(Player.CurrentStar.Position, TStar(Player.OrderTarget).Position)) then Player.OrderNone;
end;
{ @end $587394 }

{ @routine $587480 TfShip2_BuildRewardStrip }
procedure TfShip2.BuildRewardStrip(Ship: TNormalShip);
var
  I, DrawIndex: Integer;
  Image: TGraphBufGR;
  AwardId: PByte;
  Path: WideString;
  Size, Spacing, VisibleCount: Integer;
begin
  VisibleCount := 8;
  Size := GiScalePixels(20);
  Spacing := Size div 2;
  HideRewardInfo;
  if (Ship.AwardIds = nil) or (Ship.AwardIds.Count < 1) then RewardsBuffer.SetActive(False)
  else begin
  with RewardsBuffer do
  begin
    SetActive(True);
    SetImageKindX(ikxLeft);
    SetImageKindY(ikyBottom);
    GraphBuf.AllocateRgbaTight(Max(ClientSize.X, Spacing * VisibleCount + Size - Spacing), Size);
    MouseMoveCallback := RewardsMouseMove;
    MouseLeaveCallback := RewardMouseLeave;
    for I := 0 to Size - 1 do
      GraphBuf.FillRect32(Classes.Rect(0, I, GraphBuf.Width, I + 1),
        (Cardinal(Round(I / Size * 240) + 10) shl 24) or (250 shl 16) or (250 shl 8) or 50);
    SourceHasPerPixelAlpha := True;
  end;
  Image := TGraphBufGR.Create;
  I := Max(0, Ship.AwardIds.Count - VisibleCount);
  DrawIndex := 0;
  while I < Ship.AwardIds.Count do
  begin
    AwardId := Ship.AwardIds[I];
    if AwardId^ < 10 then Path := 'Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(AwardId^)
    else Path := 'Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(AwardId^);
    LoadGiByPathIntoGraphBuf(Path, Image);
    if Cardinal(Image.Width) >= Cardinal(Image.Height) then
      Image.RescaleRgba(Size, Round(Size / Cardinal(Image.Width) * Cardinal(Image.Height)), 5)
    else Image.RescaleRgba(Round(Size / Cardinal(Image.Height) * Cardinal(Image.Width)), Size, 5);
    if Image.Height > Size then AppendLogLineThreadSafe('Error: Ship RewardsBuild Y')
    else if Image.Width + DrawIndex * Spacing > RewardsBuffer.GraphBuf.Width then AppendLogLineThreadSafe('Error: Ship RewardsBuild X')
    else RewardsBuffer.GraphBuf.BlendRect32(Classes.Point(DrawIndex * Spacing, 0), Image, Classes.Rect(0, 0, Image.Width, Image.Height));
    Inc(I);
    Inc(DrawIndex);
  end;
  Image.Free;
  end;
end;
{ @end $587480 }

{ @routine $587898 TfShip2_RewardsMouseMove }
procedure TfShip2.RewardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Size, Index: Integer;
  Ship: TNormalShip;
  Reward: Pointer;
begin
  Size := GiScalePixels(20) div 2;
  Ship := Player;
  Index := Sender.ToLocalPoint(Point).X div Size + Max(0, Ship.AwardIds.Count - 8);
  if Index >= Ship.AwardIds.Count then Index := Ship.AwardIds.Count - 1;
  Reward := Ship.AwardIds[Index];
  ShowRewardInfo(Ship, PByte(Reward)^);
end;
{ @end $587898 }

{ @routine $587928 TfShip2_RewardMouseLeave }
procedure TfShip2.RewardMouseLeave(Sender: TObjectGI);
begin
  HideRewardInfo;
end;
{ @end $587928 }

{ @routine $587930 TfShip2_ShowRewardInfo }
procedure TfShip2.ShowRewardInfo(Ship: TNormalShip; AwardId: Integer);
var
  CursorPoint: TPoint;
  Path: WideString;
begin
  if HoveredRewardId = AwardId then Exit;
  HoveredRewardId := AwardId;
  RewardWindow.SetActive(True);
  CursorPoint := GetCursorPoint;
  RewardWindow.SetPosition(Classes.Point(CursorPoint.X - RewardWindow.ClientSize.X - 50,
    Max(0, CursorPoint.Y - RewardWindow.ClientSize.Y - 20)));
  if AwardId < 10 then Path := 'Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(AwardId)
  else Path := 'Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(AwardId);
  with GetByName('RewardImage') as TGraphBufGI do
  begin
    SourceHasPerPixelAlpha := True;
    LoadGiByPathIntoGraphBuf(Path, GraphBuf);
    if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
      GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
    else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  with GetByName('RewardName') as TLabelGI do SetText(Ship.GetAwardInfo(AwardId).Name);
  with GetByName('RewardText') as TLabelGI do SetText(Ship.GetAwardInfo(AwardId).Text);
end;
{ @end $587930 }

{ @routine $587C60 TfShip2_HideRewardInfo }
procedure TfShip2.HideRewardInfo;
begin
  HoveredRewardId := -1;
  RewardWindow.SetActive(False);
end;
{ @end $587C60 }

{ @routine $587C78 TfShip2_AdvancePanelSlide }
procedure TfShip2.AdvancePanelSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  X: Integer;
  Panel: TObjectGI;
begin
  Panel := GetByName('Left');
  X := Panel.LocalPosition.X + PanelSlideStep;
  if X < 0 then
  begin
    X := 0;
    if PanelSlideTimer <> 0 then
    begin
      CancelCallbackTimer(PanelSlideTimer);
      PanelSlideTimer := 0;
    end;
    RootUiObject.UpdateAbsolutePosition;
    RootUiObject.UpdateSubtreeHitBounds;
  end;
  Panel.SetPosition(Classes.Point(X, Panel.LocalPosition.Y));
end;
{ @end $587C78 }

{ @routine $587CF4 TfShip2_CloseClicked }
procedure TfShip2.CloseClicked(Sender: TObjectGI);
begin
  ReturnSelectedHoldEntry;
  AuxRenderBuffer.Clear;
  RequestedScreenId := ShipReturnScreenId;
  RequestClose(1);
  BreakUiMessage;
end;
{ @end $587CF4 }

{ @routine $587D2C TfShip2_RewardsClicked }
procedure TfShip2.RewardsClicked(Sender: TObjectGI);
begin
  if SelectedHoldKind <> phkEmpty then ReturnSelectedHoldEntry;
  AwardSubject := Player;
  if ParentLoop = nil then begin
    RequestedScreenId := screenRewards;
    RequestClose(1);
  end else begin
    if not RunRewards(Self) then RequestClose(2);
  end;
end;
{ @end $587D2C }

{ @routine $587D88 TfShip2_PropertyMouseMove }
procedure TfShip2.PropertyMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  ShowPropertyInfo(Sender);
end;
{ @end $587D88 }

{ @routine $587DA8 TfShip2_ShowPropertyInfo }
procedure TfShip2.ShowPropertyInfo(Sender: TObjectGI);
var ImagePath, Title, Text: WideString; Skill: TSkill;
begin
  ImagePath := '';
  Text := '';
  if Sender = GetByName('KlingCom') then begin
    Title := WrapTextInColor(LocalizedText('Items.Communicator.Name'), HighlightColorTag);
    Text := LocalizedColorText('Items.Communicator.Text');
    with GetByName('RankImage') as TGraphBufGI do begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TImageGI(Sender).GetImagePath, 1, ','), GraphBuf);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
        GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
      else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end
  else if Sender = GetByName('KlingCoor') then begin
    Title := WrapTextInColor(LocalizedText('Items.Pelengator.Name'), HighlightColorTag);
    Text := LocalizedColorText('Items.Pelengator.Text');
    with GetByName('RankImage') as TGraphBufGI do begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TImageGI(Sender).GetImagePath, 1, ','), GraphBuf);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
        GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
      else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end
  else if Sender is TImageGI then begin
    if Player.Rank = crRookie then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank0'
    else if Player.Rank = crCadet then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank1'
    else if Player.Rank = crPilot then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank2'
    else if Player.Rank = crWingman then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank3'
    else if Player.Rank = crLeader then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank4'
    else if Player.Rank = crAce then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank5'
    else if Player.Rank = crCommander then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank6';
    with GetByName('RankImage') as TGraphBufGI do begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf(ImagePath, GraphBuf);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
        GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
      else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
    Title := WrapTextInColor(Player.GetRankLongName, HighlightColorTag);
    Text := Player.GetRankDescription;
    if Player.Rank <> crCommander then
      if Player.GetRankPointsToNextRank > 0 then
        Text := Text + ' ' + FormatText2(LocalizedText('Rank.NextRankText'), HighlightColorTag, '<NextRank>', Player.GetNextRankName, '<WarPoints>', IntToStr(Player.GetRankPointsToNextRank))
      else Text := Text + ' ' + FormatText1(LocalizedText('Rank.NextRankGetText'), HighlightColorTag, '<NextRank>', Player.GetNextRankName);
  end
  else if Sender is TZoneGI then
  begin
    with GetByName('RankImage') as TGraphBufGI do
    begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf('Bm.FormShip.2skill' + IntToStr(ExtractDigitsToIntW(Sender.ControlName)) + 'i', GraphBuf);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
    Skill := TSkill(ExtractDigitsToIntW(Sender.ControlName));
    Title := WrapTextInColor(LocalizedText('Skills.' + SkillConfigNames[Skill] + '.Name'), HighlightColorTag);
    Text := FormatText1(LocalizedText('Skills.' + SkillConfigNames[Skill] + '.Text'), HighlightColorTag, '<SkillValue>', IntToStr(SkillEffectValues[Player.BaseSkills[Skill], Skill]));
    if Player.BaseSkills[Skill] < 5 then
      Text := Text + #13#10 + #13#10 + FormatText1(LocalizedText('Skills.PointForNextLevel'), HighlightColorTag, '<PointForNextLevel>', IntToStr(SkillTrainingCosts[Player.BaseSkills[Skill] + 1, Skill]));
  end;
  (GetByName('RankName') as TLabelGI).SetText(Title);
  (GetByName('RankText') as TLabelGI).SetText(Text);
  with GetByName('RankWnd') as TWindowGI do
    SetPosition(Classes.Point(LocalPosition.X, Sender.LocalPosition.Y - Sender.ClientSize.Y div 3 - 60));
  GetByName('RankWnd').SetActive(True);
  if PropertyHintTimer <> 0 then
  begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
end;
{ @end $587DA8 }

{ @routine $588AE4 TfShip2_HidePropertyInfo }
procedure TfShip2.HidePropertyInfo(Sender: TObjectGI);
begin
  if PropertyHintTimer <> 0 then
  begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
  PropertyHintTimer := ScheduleCallbackTimer(300, 99999, RefreshRewardHint, 0);
end;
{ @end $588AE4 }

{ @routine $588B24 TfShip2_RefreshRewardHint }
procedure TfShip2.RefreshRewardHint(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if PropertyHintTimer <> 0 then begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
  GetByName('RankWnd').SetActive(False);
end;
{ @end $588B24 }

{ @routine $588B6C TfShip2_SlotToTip }
function TfShip2.SlotToTip(SlotName: WideString): TItemType;
var Name: WideString;
begin
  Name := ExtractDelimitedPartW(SlotName, 1, '_');
  if Name = 'Hull' then Result := t_Hull
  else if Name = 'FuelTanks' then Result := t_FuelTanks
  else if Name = 'Engine' then Result := t_Engine
  else if Name = 'Radar' then Result := t_Radar
  else if Name = 'Scaner' then Result := t_Scaner
  else if Name = 'RepairRobot' then Result := t_RepairRobot
  else if Name = 'CargoHook' then Result := t_CargoHook
  else if Name = 'DefGenerator' then Result := t_DefGenerator
  else if Name = 'Weapon' then Result := WeaponCategoryItemType
  else raise Exception.Create('SlotToTip');
end;
{ @end $588B6C }

{ @routine $588D80 TfShip2_IsCompatibleSlot }
function TfShip2.IsCompatibleSlot(ItemType, SlotType: TItemType): Boolean;
begin
  Result := (SlotType = ItemType) or (IsWeaponItemType(ItemType) and IsWeaponItemType(SlotType));
end;
{ @end $588D80 }

{ @routine $588E88 TfShip2_RefreshShipView }
procedure TfShip2.RefreshShipView;
type
  SEquipment = record // @size $08
    ItemType: TItemType; // @offset $00
    Name: WideString; // @offset $04
  end;
const
  ShipDisplaySlots: array[0..7] of SEquipment = (
    (ItemType: t_FuelTanks; Name: 'FuelTanks'),
    (ItemType: t_Engine; Name: 'Engine'),
    (ItemType: t_Radar; Name: 'Radar'),
    (ItemType: t_Scaner; Name: 'Scaner'),
    (ItemType: t_RepairRobot; Name: 'RepairRobot'),
    (ItemType: t_CargoHook; Name: 'CargoHook'),
    (ItemType: t_DefGenerator; Name: 'DefGenerator'),
    (ItemType: WeaponCategoryItemType; Name: 'Weapon')); // @addr $618848
var I: Integer; Item: TEquipment; Compatible: Boolean; Artefact: TArtefact; Text: WideString; J: Integer; ItemType: TItemType; Entry: TPlayerHoldUnit; Image: TGraphBufGI;
begin
  Player.RefreshAssignedItemSlots;
  Player.RefreshDerivedStats;
  RefreshPlayerHoldView;
  Text := IntToStr(Player.GetDefensePercent) + '%';
  Text := Text + ' + ' + WrapTextInColor(IntToStr(Player.Hull.Armor + 5 * (Ord(Player.HasActiveArtefact(t_ArtefactHull)))), '');
  (GetByName('IDef') as TLabelGI).SetText(Text);
  (GetByName('IMass') as TLabelGI).SetText(IntToStr(Player.GetEffectiveMass));
  if Player.CalculateSpeed = 0 then Text := RedColorTag else Text := '';
  (GetByName('ISpeed') as TLabelGI).SetText(WrapTextInColor(IntToStr(Player.CalculateSpeed), Text));
  if Player.GetCargoFreeSpace < 0 then Text := RedColorTag else Text := '';
  (GetByName('IEmpty') as TLabelGI).SetText(WrapTextInColor(IntToStr(Player.GetCargoFreeSpace), Text));
  (GetByName('S_Left') as TGraphButtonGI).SetDisabled(HoldFirstIndex <= 0);
  (GetByName('S_Right') as TGraphButtonGI).SetDisabled(HoldFirstIndex + 6 > PlayerHoldEntries.Count);
  UpdateSelectedItemActions(SelectedHoldKind, SelectedGoodsIndex, SelectedGoodsQuantity, SelectedGoodsCost, SelectedHoldItem);
  for I := 0 to 7 do begin
    for J := 0 to Player.GetSlotCountForItemType(ShipDisplaySlots[I].ItemType) - 1 do begin
      Item := Player.FindEquippedItemInSlot(ShipDisplaySlots[I].ItemType, J);
      with GetByName('S_' + ShipDisplaySlots[I].Name + '_' + IntToStr(J) + 'i') as TImageGI do begin
        if Item = nil then SetImagePath('')
        else begin
          SetImagePath('GI,' + Item.GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
      end;
      with GetByName('S_' + ShipDisplaySlots[I].Name + '_' + IntToStr(J) + 'z') as TZoneGI do ZoneMouseDownCallback := EquipmentSlotMouseDown;
      Compatible := (SelectedHoldKind = phkEquipment) and IsCompatibleSlot(SelectedHoldItem.ItemType, ShipDisplaySlots[I].ItemType);
      GetByName('S_' + ShipDisplaySlots[I].Name + '_' + IntToStr(J) + 'a').SetActive(Compatible);
      GetByName('S_' + ShipDisplaySlots[I].Name + '_' + IntToStr(J) + 'n').SetActive((Item <> nil) and not Compatible and not Item.BrokenFlag);
      GetByName('S_' + ShipDisplaySlots[I].Name + '_' + IntToStr(J) + 'b').SetActive((Item <> nil) and not Compatible and Item.BrokenFlag);
    end;
  end;
  I := 0;
  for ItemType := t_ArtefactHull to t_ArtefactAntigrav do begin
    Player.FindEquippedArtefact(ItemType, Artefact, False);
    Compatible := (SelectedHoldKind = phkArtefact) and (ItemType = SelectedHoldItem.ItemType);
    GetByName('Ar' + IntToStr(I) + 'n').SetActive((Artefact <> nil) and not Compatible and not Artefact.BrokenFlag);
    GetByName('Ar' + IntToStr(I) + 'b').SetActive((Artefact <> nil) and not Compatible and Artefact.BrokenFlag);
    GetByName('Ar' + IntToStr(I) + 'a').SetActive(Compatible);
    GetByName('Ar' + IntToStr(I) + 'i').SetActive(Artefact <> nil);
    if Artefact <> nil then begin
      with GetByName('Ar' + IntToStr(I) + 'i') as TImageGI do begin
        SetImagePath('GI,' + Artefact.GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
    end;
    with GetByName('Ar' + IntToStr(I) + 'z') as TZoneGI do begin
      SetActive((Artefact <> nil) or Compatible);
      ZoneMouseDownCallback := ArtefactSlotMouseDown;
    end;
    Inc(I);
  end;
  for I := 0 to 5 do begin
    if HoldFirstIndex + I >= PlayerHoldEntries.Count then Entry := nil
    else Entry := PlayerHoldEntries[HoldFirstIndex + I];
    with GetByName('S_' + IntToStr(I) + 'i') as TImageGI do begin
      if (Entry = nil) or (Entry.Kind = phkEmpty) then SetImagePath('')
      else begin
        if Entry.Kind = phkGoods then begin
          SetImagePath('GI,' + GetItemTypeBitmapPath(Entry.GoodsIndex));
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end
        else if Entry.Kind = phkEquipment then begin
          SetImagePath('GI,' + Entry.Item.GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end
        else if Entry.Kind = phkArtefact then begin
          SetImagePath('GI,' + Entry.Item.GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
      end;
    end;
    (GetByName('S_' + IntToStr(I) + 'z') as TZoneGI).ZoneMouseDownCallback := HoldSlotMouseDown;
    GetByName('S_' + IntToStr(I) + 'f').SetActive(SelectedHoldKind <> phkEmpty);
  end;
  UpdateItemHover;
end;
{ @end $588E88 }

{ @routine $589C70 TfShip2_UpdateSelectedItemActions }
procedure TfShip2.UpdateSelectedItemActions(Kind: TPlayerHoldKind; Goods: TItemType; Quantity, Cost: Integer; Item: TItem);
var I, TotalRepair: Integer; Equipment: TEquipment;
begin
  RightOpenImage.SetActive(Kind <> phkEmpty);
  RightCloseImage.SetActive(Kind = phkEmpty);
  SkillsPanel.SetActive(Kind = phkEmpty);
  with FreeSkillPointsLabel do SetText(IntToStr(Player.FreeExperience));
  with SkillImages[Ord(skAccuracy)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skAccuracy]), ClientSize.Y));
  with SkillImages[Ord(skMobility)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skMobility]), ClientSize.Y));
  with SkillImages[Ord(skTechnical)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skTechnical]), ClientSize.Y));
  with SkillImages[Ord(skTrader)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skTrader]), ClientSize.Y));
  with SkillImages[Ord(skCharm)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skCharm]), ClientSize.Y));
  with SkillImages[Ord(skLeadership)] do SetSize(Classes.Point(Round(GetContentSize.X / 5 * Player.BaseSkills[skLeadership]), ClientSize.Y));
  with SkillButtons[Ord(skAccuracy)] do begin
    UserValue := Ord(skAccuracy);
    SetActive(Player.CanTrainSkill(skAccuracy));
    UpCallback := TrainSkillClicked;
  end;
  with SkillButtons[Ord(skMobility)] do begin
    UserValue := Ord(skMobility);
    SetActive(Player.CanTrainSkill(skMobility));
    UpCallback := TrainSkillClicked;
  end;
  with SkillButtons[Ord(skTechnical)] do begin
    UserValue := Ord(skTechnical);
    SetActive(Player.CanTrainSkill(skTechnical));
    UpCallback := TrainSkillClicked;
  end;
  with SkillButtons[Ord(skTrader)] do begin
    UserValue := Ord(skTrader);
    SetActive(Player.CanTrainSkill(skTrader));
    UpCallback := TrainSkillClicked;
  end;
  with SkillButtons[Ord(skCharm)] do begin
    UserValue := Ord(skCharm);
    SetActive(Player.CanTrainSkill(skCharm));
    UpCallback := TrainSkillClicked;
  end;
  with SkillButtons[Ord(skLeadership)] do begin
    UserValue := Ord(skLeadership);
    SetActive(Player.CanTrainSkill(skLeadership));
    UpCallback := TrainSkillClicked;
  end;
  Action0Label.SetActive(False);
  Action1Label.SetActive(False);
  if Kind = phkEmpty then ActionPanel.SetActive(False)
  else if IsVirtualKeyDown(VK_CONTROL) and Player.IsOnPlanet and (Player.CurrentPlanet.OwnerId <> oiNone) and
    ((Kind = phkGoods) or ((Kind in [phkEquipment, phkArtefact]) and (Item.ScriptItem = nil) and ((Item.ItemType <> t_UselessItem) or (Item.OwnerId = oiKling)))) then begin
    ActionPanel.SetActive(True);
    Action0Label.SetText(LocalizedText('FormShip.Storage'));
    Action0Image.LeftButtonDownCallback := StoreSelectedOnPlanet;
    Action0Label.SetActive(True);
  end
  else if Kind = phkGoods then begin
    ActionPanel.SetActive(True);
    if Player.InNormalSpace or OpenedFromArcade then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
    end else if (Player.CurrentPlanet <> nil) and ((Player.CurrentPlanet.OwnerId in [oiKling,oiNone]) or (Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad)) then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
    end else begin
    Action0Label.SetText(FormatText1(LocalizedText('FormShip.Sell'), '', '<Money>', IntToStr(Player.GetLocationGoodsEntry(Goods).BaseSalePrice * Quantity)));
    Action0Image.LeftButtonDownCallback := SellSelected;
    Action0Label.SetActive(True);
    end;
  end
  else if Kind = phkEquipment then begin
    ActionPanel.SetActive(True);
    if Player.InNormalSpace or OpenedFromArcade then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
    end else if (Player.CurrentPlanet <> nil) and ((Player.CurrentPlanet.OwnerId in [oiKling,oiNone]) or (Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad)) then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
    end else if (Item.ScriptItem = nil) and ((Item.ItemType <> t_Protoplasm) or not (Player.DockedTo is TRC)) then begin
    Action0Label.SetText(FormatText1(LocalizedText('FormShip.Sell'), '', '<Money>', IntToStr(Item.CalculateResaleValue(Player.BaseSkills[skTrader]))));
    Action0Image.LeftButtonDownCallback := SellSelected;
    Action0Label.SetActive(True);
      if IsVirtualKeyDown(VK_SHIFT) then begin
        TotalRepair := 0;
        if (Item as TEquipment).NeedsRepair then Inc(TotalRepair, (Item as TEquipment).CalculateRepairCost);
        for I := 0 to Player.Inventory.Count - 1 do begin
          Equipment := Player.Inventory[I];
          if (Equipment <> Item) and Equipment.EquippedFlag and Equipment.NeedsRepair then
            Inc(TotalRepair, Equipment.CalculateRepairCost);
        end;
        if TotalRepair > 0 then begin
    Action1Label.SetText(FormatText1(LocalizedText('FormShip.RepairAll'), '', '<Money>', IntToStr(TotalRepair)));
    Action1Image.LeftButtonDownCallback := RepairSelected;
    Action1Label.SetActive(True);
        end;
      end else if (Item as TEquipment).NeedsRepair then begin
    Action1Label.SetText(FormatText1(LocalizedText('FormShip.Repair'), '', '<Money>', IntToStr((Item as TEquipment).CalculateRepairCost)));
    Action1Image.LeftButtonDownCallback := RepairSelected;
    Action1Label.SetActive(True);
      end;
    end;
  end
  else if Kind = phkArtefact then begin
    ActionPanel.SetActive(True);
    if Player.InNormalSpace or OpenedFromArcade then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
      if Player.InNormalSpace and not OpenedFromArcade and ((Item.ItemType = t_ArtefactTranclucator) or (Item.ItemType = t_ArtefactTransmitter)) then begin
    Action1Label.SetText(LocalizedText('FormShip.Use'));
    Action1Image.LeftButtonDownCallback := UseSelectedArtefact;
    Action1Label.SetActive(True);
      end;
    end else if (Player.CurrentPlanet <> nil) and ((Player.CurrentPlanet.OwnerId in [oiKling,oiNone]) or (Player.CurrentPlanet.GetRelationLevelToShip(Player) <= rlBad)) then begin
    Action0Label.SetText(LocalizedText('FormShip.Drop'));
    Action0Image.LeftButtonDownCallback := DropSelectedOutside;
    Action0Label.SetActive(True);
    end else begin
    Action0Label.SetText(FormatText1(LocalizedText('FormShip.Sell'), '', '<Money>', IntToStr(Item.CalculateResaleValue(Player.BaseSkills[skTrader]))));
    Action0Image.LeftButtonDownCallback := SellSelected;
    Action0Label.SetActive(True);
      if (Item as TEquipment).NeedsRepair then begin
    Action1Label.SetText(FormatText1(LocalizedText('FormShip.Repair'), '', '<Money>', IntToStr((Item as TEquipment).CalculateRepairCost)));
    Action1Image.LeftButtonDownCallback := RepairSelected;
    Action1Label.SetActive(True);
      end;
    end;
  end;
  Action0Image.SetActive(Action0Label.Active);
  Action1Image.SetActive(Action1Label.Active);
  if Action0Image.Active and not Action1Image.Active then begin
    Action0Image.SetPosition(Classes.Point(Action0Image.LocalPosition.X, ActionPanel.ClientSize.Y div 2 - (Action0Image.ClientSize.Y + Action0Label.ClientSize.Y) div 2));
    Action0Label.SetPosition(Classes.Point(Action0Label.LocalPosition.X, Action0Image.LocalPosition.Y + Action0Image.ClientSize.Y));
  end else if Action0Image.Active and Action1Image.Active then begin
    Action0Image.SetPosition(Classes.Point(Action0Image.LocalPosition.X, 0));
    Action0Label.SetPosition(Classes.Point(Action0Label.LocalPosition.X, Action0Image.LocalPosition.Y + Action0Image.ClientSize.Y));
    with Action1Image do SetPosition(Classes.Point(LocalPosition.X, ActionPanel.ClientSize.Y - (ClientSize.Y + Action1Label.ClientSize.Y)));
    Action1Label.SetPosition(Classes.Point(Action1Label.LocalPosition.X, Action1Image.LocalPosition.Y + Action1Image.ClientSize.Y));
  end;
end;
{ @end $589C70 }

{ @routine $58AB70 TfShip2_UpdateActionCursor }
procedure TfShip2.UpdateActionCursor;
begin
  if SelectedHoldKind = phkEmpty then begin
    if not IsCursorImageSelected('Take') then SetCursorByName('Take');
  end
  else if SelectedHoldKind = phkEquipment then SetCursorImage('GI,' + SelectedHoldItem.GetBitmapResourceName + 's', Classes.Point(16, 16))
  else if SelectedHoldKind = phkGoods then SetCursorImage('GI,' + GetItemTypeBitmapPath(SelectedGoodsIndex), Classes.Point(16, 16))
  else if SelectedHoldKind = phkArtefact then SetCursorImage('GI,' + SelectedHoldItem.GetBitmapResourceName + 's', Classes.Point(16, 16));
end;
{ @end $58AB70 }

{ @routine $58ACF0 TfShip2_TrainSkillClicked }
procedure TfShip2.TrainSkillClicked(Sender: TObjectGI);
begin
  Player.TrainSkill(TSkill(Sender.UserValue));
  RefreshShipView;
  ShowPropertyInfo(GetByName('Skill' + IntToStr(Cardinal(Sender.UserValue)) + 'z'));
end;
{ @end $58ACF0 }

{ @routine $58ADBC TfShip2_EquipmentSlotMouseDown }
procedure TfShip2.EquipmentSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var ItemType: TItemType; Slot: Integer; Item: TEquipment;
begin
  ItemType := SlotToTip(Sender.ControlName);
  Slot := ExtractDigitsToIntW(Sender.ControlName);
  if SelectedHoldKind = phkEmpty then begin
    Item := Player.FindEquippedItemInSlot(ItemType, Slot);
    if Item <> nil then begin
      Item.EquippedFlag := False;
      Player.Inventory.Delete(Player.Inventory.IndexOf(Item));
      Player.RebuildEquipmentCache;
      Player.RefreshDerivedStats;
      SelectedHoldKind := phkEquipment;
      SelectedHoldItem := Item;
      if Item is TWeapon then (Item as TWeapon).Target := nil;
      UpdateActionCursor;
      SoundManager.PlaySound('Sound.SlotGet');
    end;
  end else if (SelectedHoldKind = phkEquipment) and IsCompatibleSlot(ItemType, SelectedHoldItem.ItemType) then begin
    Item := Player.FindEquippedItemInSlot(ItemType, Slot);
    Player.Inventory.Add(SelectedHoldItem);
    (SelectedHoldItem as TEquipment).AssignedSlotData := (SelectedHoldItem as TEquipment).AssignedSlotData and $80 or Slot;
    (SelectedHoldItem as TEquipment).EquippedFlag := True;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    SoundManager.PlaySound('Sound.SlotPut');
    if Item <> nil then begin
      Player.Inventory.Delete(Player.Inventory.IndexOf(Item));
      SelectedHoldKind := phkEquipment;
      SelectedHoldItem := Item;
      if Item is TWeapon then (Item as TWeapon).Target := nil;
    end;
    UpdateActionCursor;
  end;
  RefreshShipView;
end;
{ @end $58ADBC }

{ @routine $58B010 TfShip2_ArtefactSlotMouseDown }
procedure TfShip2.ArtefactSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  ItemType: TItemType;
  Item: TArtefact;
  ParsedType: Integer;
begin
  ParsedType := ExtractDigitsToIntW(Sender.ControlName);
  ItemType := TItemType(ParsedType);
  Inc(ItemType, Ord(t_ArtefactHull));
  if SelectedHoldKind = phkEmpty then begin
    if Player.FindEquippedArtefact(ItemType, Item, False) then begin
      Item.Unequip;
      Player.Artefacts.Delete(Player.Artefacts.IndexOf(Item));
      Player.RefreshDerivedStats;
      SelectedHoldKind := phkArtefact;
      SelectedHoldItem := Item;
      UpdateActionCursor;
      SoundManager.PlaySound('Sound.SlotGet');
    end;
  end else if (SelectedHoldKind = phkArtefact) and (ItemType = SelectedHoldItem.ItemType) then begin
    Player.FindEquippedArtefact(ItemType, Item, False);
    Player.Artefacts.Add(SelectedHoldItem);
    (SelectedHoldItem as TEquipment).AssignedSlotData := 0;
    (SelectedHoldItem as TEquipment).EquippedFlag := False;
    (SelectedHoldItem as TEquipment).Equip;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    SoundManager.PlaySound('Sound.SlotPut');
    if Item <> nil then begin
      Player.Artefacts.Delete(Player.Artefacts.IndexOf(Item));
      SelectedHoldKind := phkArtefact;
      SelectedHoldItem := Item;
    end;
    UpdateActionCursor;
  end;
  RefreshShipView;
end;
{ @end $58B010 }

{ @routine $58B200 TfShip2_HoldSlotMouseDown }
procedure TfShip2.HoldSlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Slot, I, Count: Integer; Entry: TPlayerHoldUnit;
begin
  Slot := ExtractDigitsToIntW(Sender.ControlName);
  I := Slot + HoldFirstIndex;
  if (I < 0) or (I >= PlayerHoldEntries.Count) then Entry := nil
  else Entry := PlayerHoldEntries[I];
  if SelectedHoldKind = phkEmpty then begin
    if Entry <> nil then begin
      if Entry.Kind = phkEquipment then begin
        SelectedHoldKind := phkEquipment;
        SelectedHoldItem := Entry.Item;
        PlayerHoldEntries.Delete(Slot + HoldFirstIndex);
        Player.Inventory.Delete(Player.Inventory.IndexOf(Entry.Item));
        // Native removes the entry without freeing it.
        Player.RefreshDerivedStats;
        UpdateActionCursor;
        SoundManager.PlaySound('Sound.SlotGet');
      end
      else if Entry.Kind = phkGoods then begin
        SelectedHoldKind := phkGoods;
        SelectedGoodsIndex := Entry.GoodsIndex;
        SelectedGoodsQuantity := Player.CargoGoods[SelectedGoodsIndex].Count;
        SelectedGoodsCost := Player.CargoGoods[SelectedGoodsIndex].TotalCost;
        Player.CargoGoods[SelectedGoodsIndex].Count := 0;
        Player.CargoGoods[SelectedGoodsIndex].TotalCost := 0;
        PlayerHoldEntries.Delete(Slot + HoldFirstIndex);
        // Native removes the entry without freeing it.
        Player.RefreshDerivedStats;
        UpdateActionCursor;
        SoundManager.PlaySound('Sound.SlotGet');
      end
      else if Entry.Kind = phkArtefact then begin
        SelectedHoldKind := phkArtefact;
        SelectedHoldItem := Entry.Item;
        PlayerHoldEntries.Delete(Slot + HoldFirstIndex);
        Player.Artefacts.Delete(Player.Artefacts.IndexOf(Entry.Item));
        // Native removes the entry without freeing it.
        Player.RefreshDerivedStats;
        UpdateActionCursor;
        SoundManager.PlaySound('Sound.SlotGet');
      end;
    end;
  end
  else if SelectedHoldKind = phkEquipment then begin
    if Entry = nil then begin
      Count := Slot + HoldFirstIndex - PlayerHoldEntries.Count + 1;
      for I := 0 to Count - 1 do begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Add(Entry);
        Entry.Kind := phkEmpty;
      end;
      Entry := PlayerHoldEntries[PlayerHoldEntries.Count - 1];
    end else if Entry.Kind <> phkEmpty then begin
      Entry := TPlayerHoldUnit.Create;
      PlayerHoldEntries.Insert(Slot + HoldFirstIndex, Entry);
      Entry.Kind := phkEmpty;
    end;
    SoundManager.PlaySound('Sound.SlotPut');
    Player.Inventory.Add(SelectedHoldItem);
    (SelectedHoldItem as TEquipment).EquippedFlag := False;
    Entry.Kind := phkEquipment;
    Entry.ItemId := SelectedHoldItem.Id;
    Entry.Item := SelectedHoldItem;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    Player.RefreshDerivedStats;
    UpdateActionCursor;
  end
  else if SelectedHoldKind = phkGoods then begin
    if Entry = nil then begin
      Count := Slot + HoldFirstIndex - PlayerHoldEntries.Count + 1;
      for I := 0 to Count - 1 do begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Add(Entry);
        Entry.Kind := phkEmpty;
      end;
      Entry := PlayerHoldEntries[PlayerHoldEntries.Count - 1];
    end else if Entry.Kind <> phkEmpty then begin
      Entry := TPlayerHoldUnit.Create;
      PlayerHoldEntries.Insert(Slot + HoldFirstIndex, Entry);
      Entry.Kind := phkEmpty;
    end;
    SoundManager.PlaySound('Sound.SlotPut');
    Player.CargoGoods[SelectedGoodsIndex].Count := SelectedGoodsQuantity;
    Player.CargoGoods[SelectedGoodsIndex].TotalCost := SelectedGoodsCost;
    Entry.Kind := phkGoods;
    Entry.GoodsIndex := SelectedGoodsIndex;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    Player.RefreshDerivedStats;
    UpdateActionCursor;
  end
  else if SelectedHoldKind = phkArtefact then begin
    if Entry = nil then begin
      Count := Slot + HoldFirstIndex - PlayerHoldEntries.Count + 1;
      for I := 0 to Count - 1 do begin
        Entry := TPlayerHoldUnit.Create;
        PlayerHoldEntries.Add(Entry);
        Entry.Kind := phkEmpty;
      end;
      Entry := PlayerHoldEntries[PlayerHoldEntries.Count - 1];
    end else if Entry.Kind <> phkEmpty then begin
      Entry := TPlayerHoldUnit.Create;
      PlayerHoldEntries.Insert(Slot + HoldFirstIndex, Entry);
      Entry.Kind := phkEmpty;
    end;
    SoundManager.PlaySound('Sound.SlotPut');
    Player.Artefacts.Add(SelectedHoldItem);
    (SelectedHoldItem as TEquipment).EquippedFlag := False;
    Entry.Kind := phkArtefact;
    Entry.ItemId := SelectedHoldItem.Id;
    Entry.Item := SelectedHoldItem;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    Player.RefreshDerivedStats;
    UpdateActionCursor;
  end;
  RefreshShipView;
end;
{ @end $58B200 }

{ @routine $58B778 TfShip2_ScrollHoldLeft }
procedure TfShip2.ScrollHoldLeft(Sender: TObjectGI);
begin
  Dec(HoldFirstIndex);
  RefreshShipView;
end;
{ @end $58B778 }

{ @routine $58B784 TfShip2_ScrollHoldRight }
procedure TfShip2.ScrollHoldRight(Sender: TObjectGI);
begin
  Inc(HoldFirstIndex);
  RefreshShipView;
end;
{ @end $58B784 }

{ @routine $58B790 TfShip2_ReturnSelectedHoldEntry }
procedure TfShip2.ReturnSelectedHoldEntry;
begin
  if SelectedHoldKind <> phkEmpty then begin
    if SelectedHoldKind = phkGoods then begin
      Player.CargoGoods[SelectedGoodsIndex].Count := SelectedGoodsQuantity;
      Player.CargoGoods[SelectedGoodsIndex].TotalCost := SelectedGoodsCost;
    end
    else if SelectedHoldKind = phkEquipment then begin
      Player.Inventory.Add(SelectedHoldItem);
      (SelectedHoldItem as TEquipment).EquippedFlag := False;
    end
    else if SelectedHoldKind = phkArtefact then begin
      Player.Artefacts.Add(SelectedHoldItem);
      (SelectedHoldItem as TEquipment).EquippedFlag := False;
    end;
    SelectedHoldKind := phkEmpty;
    SelectedHoldItem := nil;
    Player.RefreshDerivedStats;
    if not IsCursorImageSelected('Main') then SetCursorByName('Main');
    RefreshShipView;
  end;
end;
{ @end $58B790 }

{ @routine $58B894 TfShip2_MainKeyDown }
procedure TfShip2.MainKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if (Key = 16) and (SelectedHoldKind = phkEquipment) then
    UpdateSelectedItemActions(SelectedHoldKind, SelectedGoodsIndex, SelectedGoodsQuantity, SelectedGoodsCost, SelectedHoldItem)
  else if (Key = 17) and Player.IsOnPlanet then RefreshShipView;
  if not IsVirtualKeyDown(17) and not IsVirtualKeyDown(16) and not IsVirtualKeyDown(18) then begin
    if Key = 83 then CloseClicked(nil)
    else if (Key = 27) or (Key = 13) then begin
      if SelectedHoldKind <> phkEmpty then ReturnSelectedHoldEntry
      else begin
        AuxRenderBuffer.Clear;
        RequestedScreenId := ShipReturnScreenId;
        RequestClose(1);
      end;
    end
    else if Key = 37 then begin
      if HoldFirstIndex > 0 then begin
        Dec(HoldFirstIndex);
        RefreshShipView;
      end;
    end
    else if Key = 39 then begin
      if HoldFirstIndex + 6 <= PlayerHoldEntries.Count then begin
        Inc(HoldFirstIndex);
        RefreshShipView;
      end;
    end
    else if (Key = 82) and GetByName('RewardBut').Active then RewardsClicked(nil);
  end;
end;
{ @end $58B894 }

{ @routine $58BA00 TfShip2_MainKeyUp }
procedure TfShip2.MainKeyUp(Sender: TObjectGI; Key: Cardinal);
begin
  if (Key = 16) and (SelectedHoldKind = phkEquipment) then
    UpdateSelectedItemActions(SelectedHoldKind, SelectedGoodsIndex, SelectedGoodsQuantity, SelectedGoodsCost, SelectedHoldItem)
  else if (Key = 17) and Player.IsOnPlanet then RefreshShipView;
end;
{ @end $58BA00 }

{ @routine $58BA60 TfShip2_ProcessMouseWheel }
procedure TfShip2.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = 120 then begin
    if HoldFirstIndex > 0 then begin
      Dec(HoldFirstIndex);
      RefreshShipView;
    end;
  end else if (Delta = -120) and (HoldFirstIndex + 6 <= PlayerHoldEntries.Count) then begin
    Inc(HoldFirstIndex);
    RefreshShipView;
  end;
end;
{ @end $58BA60 }

{ @routine $58BAAC TfShip2_MainLeftButtonUp }
procedure TfShip2.MainLeftButtonUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not (GetByName('PanelLeft') as TImageGI).HitTestPixel(Point) and
    not (GetByName('RightClose') as TImageGI).HitTestPixel(Point) then CloseClicked(nil);
end;
{ @end $58BAAC }

{ @routine $58BB4C TfShip2_MainRightButtonDown }
procedure TfShip2.MainRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  ReturnSelectedHoldEntry;
end;
{ @end $58BB4C }

{ @routine $58BB6C TfShip2_StoreSelectedOnPlanet }
procedure TfShip2.StoreSelectedOnPlanet(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Entry: PStorageEntry; Quantity, Step: Integer;
begin
  if SelectedHoldKind = phkEmpty then Exit;
  if (SelectedHoldKind = phkEquipment) and (SelectedHoldItem is TProtoplasm) and (TProtoplasm(SelectedHoldItem).Quantity > 1) then begin
    Quantity := TProtoplasm(SelectedHoldItem).Quantity;
    Step := 5;
    if Quantity <= 5 then Step := 1;
    if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.StorageItem'), HighlightColorTag, '<Name>',
      LowerCaseWideString(GoodsNames[SelectedHoldItem.ItemType])), 0, Quantity, Step, Quantity) <> 1 then Exit;
    if (Quantity < 1) or (TProtoplasm(SelectedHoldItem).Quantity < Quantity) then Exit;
    Dec(TProtoplasm(SelectedHoldItem).Quantity, Quantity);
    with TProtoplasm(SelectedHoldItem) do begin
      Weight := Quantity;
      Cost := Quantity * 10;
    end;
    New(Entry);
    Player.StorageEntries.Add(Entry);
    Entry.Planet := Player.CurrentPlanet;
    Entry.Item := TProtoplasm.Create;
    (Entry.Item as TProtoplasm).Init(Quantity, 0);
    if TProtoplasm(SelectedHoldItem).Quantity < 1 then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end;
    SoundManager.PlaySound('Sound.Drop');
  end else if (SelectedHoldKind = phkEquipment) or (SelectedHoldKind = phkArtefact) then begin
    if SelectedHoldItem is TArtefactTranclucator then
      ((SelectedHoldItem as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := nil;
    SoundManager.PlaySound('Sound.Drop');
    New(Entry);
    Player.StorageEntries.Add(Entry);
    Entry.Planet := Player.CurrentPlanet;
    Entry.Item := SelectedHoldItem;
    SelectedHoldKind := phkEmpty;
    SetCursorByName('Main');
    RefreshShipView;
  end else if SelectedHoldKind = phkGoods then begin
    Quantity := SelectedGoodsQuantity;
    if SelectedGoodsQuantity > 1 then begin
      Step := 5;
      if SelectedGoodsQuantity <= 5 then Step := 1;
      if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.StorageItem'), HighlightColorTag, '<Name>',
        LowerCaseWideString(GoodsNames[SelectedGoodsIndex])), 0, SelectedGoodsQuantity, Step, Quantity) <> 1 then Exit;
      if (Quantity < 1) or (Quantity > SelectedGoodsQuantity) then Exit;
    end;
    SoundManager.PlaySound('Sound.Drop');
    New(Entry);
    Player.StorageEntries.Add(Entry);
    Entry.Planet := Player.CurrentPlanet;
    Entry.Item := TGoods.Create;
    (Entry.Item as TGoods).Init(SelectedGoodsIndex, Quantity);
    Entry.Item.Cost := Round(Quantity / SelectedGoodsQuantity * SelectedGoodsCost);
    Dec(SelectedGoodsCost, Round(Quantity / SelectedGoodsQuantity * SelectedGoodsCost));
    Dec(SelectedGoodsQuantity, Quantity);
    if SelectedGoodsQuantity < 1 then begin
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end;
  end;
  Player.RefreshStorageMessage;
  RefreshStationDialog := True;
  SkipOpeningSlide := True;
  PlayTransitionSounds := False;
  CloseClicked(nil);
end;
{ @end $58BB6C }

{ @routine $58C058 TfShip2_DropSelectedOutside }
procedure TfShip2.DropSelectedOutside(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Item: TItem;
  Goods: TGoods;
  Angle: Double;
  Effect: TWeaponSE;
  Entry: PEFilmEndEntry;
  Quantity, I, Index, Step: Integer;
begin
  if SelectedHoldKind = phkEmpty then Exit;
  if OpenedFromArcade then begin DropSelectedInArcade; Exit; end;
  if (SelectedHoldKind = phkEquipment) and (SelectedHoldItem is TProtoplasm) and (TProtoplasm(SelectedHoldItem).Quantity > 1) then begin
    Quantity := TProtoplasm(SelectedHoldItem).Quantity;
    Step := 5;
    if Quantity <= 5 then Step := 1;
    if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.ThrowItem'), HighlightColorTag, '<Name>',
      LowerCaseWideString(GoodsNames[SelectedHoldItem.ItemType])), 0, Quantity, Step, Quantity) <> 1 then Exit;
    if (Quantity < 1) or (TProtoplasm(SelectedHoldItem).Quantity < Quantity) then Exit;
    Dec(TProtoplasm(SelectedHoldItem).Quantity, Quantity);
    with TProtoplasm(SelectedHoldItem) do begin Weight := Quantity; Cost := Quantity * 10; end;
    if not Player.IsOnPlanet then begin
      Item := TProtoplasm.Create;
      TProtoplasm(Item).Init(Quantity, 0);
      with Player.CurrentStar do begin
        Items.Add(Item);
        Angle := SeededRandomIntRange(0, 360, Player.CurrentStar.GenerationSeed * Galaxy.CurrentTurn * Item.Id) * Pi / 180;
        Item.Position.X := Sin(Angle) * 100 + Player.Position.X;
        Item.Position.Y := Player.Position.Y - Cos(Angle) * 100;
        Item.GetGraphObject.SetPosition(Item.Position);
        if DamageRadius * DamageRadius > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then begin
          Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
          Effect.SetEndpoints(nil, Item.GetGraphObject);
          Effect.SetHit(0, 0, True, True);
          if TrailingFilmEffects = nil then TrailingFilmEffects := TEFilmEnd.Create;
          Entry := TrailingFilmEffects.AppendEntry;
          Entry.SceneObject := Effect;
          Entry.RelatedObject1 := Item.GetGraphObject;
          Item.GraphObject := nil;
          Items.Delete(Items.IndexOf(Item));
          Item.Free;
        end;
      end;
    end;
    if TProtoplasm(SelectedHoldItem).Quantity < 1 then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end;
    SoundManager.PlaySound('Sound.Drop');
  end else if (SelectedHoldKind = phkEquipment) or (SelectedHoldKind = phkArtefact) then begin
    if SelectedHoldItem is TArtefactTranclucator then
      ((SelectedHoldItem as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := nil;
    if SelectedHoldItem.ItemType = t_FuelTanks then begin
      if Player.FuelTanks = nil then begin
        ShowMessageBoxGI(Self, LocalizedText('FormShip.ThrowFuelTanksError'), mbgCancel);
        Exit;
      end;
    end else if SelectedHoldItem.ItemType = t_Engine then begin
      if Player.Engine = nil then begin
        ShowMessageBoxGI(Self, LocalizedText('FormShip.ThrowEngineError'), mbgCancel);
        Exit;
      end;
    end;
    SoundManager.PlaySound('Sound.Drop');
    if Player.IsOnPlanet then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
    end else
      with Player.CurrentStar do begin
        Items.Add(SelectedHoldItem);
        Angle := SeededRandomIntRange(0, 360, Player.CurrentStar.GenerationSeed * Galaxy.CurrentTurn * SelectedHoldItem.Id) * Pi / 180;
        if SelectedHoldItem is TWeapon then (SelectedHoldItem as TWeapon).Target := nil;
        SelectedHoldItem.Position.X := Sin(Angle) * 100 + Player.Position.X;
        SelectedHoldItem.Position.Y := Player.Position.Y - Cos(Angle) * 100;
        SelectedHoldItem.GetGraphObject.SetPosition(SelectedHoldItem.Position);
        if DamageRadius * DamageRadius > Sqr(SelectedHoldItem.Position.X) + Sqr(SelectedHoldItem.Position.Y) then begin
          Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
          Effect.SetEndpoints(nil, SelectedHoldItem.GetGraphObject);
          Effect.SetHit(0, 0, True, True);
          if TrailingFilmEffects = nil then TrailingFilmEffects := TEFilmEnd.Create;
          Entry := TrailingFilmEffects.AppendEntry;
          Entry.SceneObject := Effect;
          Entry.RelatedObject1 := SelectedHoldItem.GetGraphObject;
          SelectedHoldItem.GraphObject := nil;
          Items.Delete(Items.IndexOf(SelectedHoldItem));
          SelectedHoldItem.Free;
        end;
      end;
    SelectedHoldKind := phkEmpty;
    SetCursorByName('Main');
    RefreshShipView;
  end else if SelectedHoldKind = phkGoods then begin
    if Player.IsOnPlanet and (Player.CurrentPlanet.OwnerId <> oiNone) then begin
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end else begin
      Quantity := SelectedGoodsQuantity;
      if SelectedGoodsQuantity > 1 then begin
        Step := 5;
        if SelectedGoodsQuantity <= 5 then Step := 1;
        if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.ThrowItem'), HighlightColorTag, '<Name>',
          LowerCaseWideString(GoodsNames[SelectedGoodsIndex])), 0, SelectedGoodsQuantity, Step, Quantity) <> 1 then Exit;
        if (Quantity < 1) or (Quantity > SelectedGoodsQuantity) then Exit;
      end;
      SoundManager.PlaySound('Sound.Drop');
      if not Player.IsOnPlanet then
        with Player.CurrentStar do begin
          Goods := TGoods.Create;
          Goods.Init(SelectedGoodsIndex, Quantity);
          for I := 0 to 20 do begin
            Angle := SeededRandomIntRange(0, 360, Player.CurrentStar.GenerationSeed * Galaxy.CurrentTurn * (ReadByteValue(SelectedGoodsIndex) + I)) * Pi / 180;
            Goods.Position.X := Sin(Angle) * 100 + Player.Position.X;
            Goods.Position.Y := Player.Position.Y - Cos(Angle) * 100;
            Index := 0;
            while Index < Items.Count do begin
              Item := Items[Index];
              if PointDistanceSquared(Item.Position, Goods.Position) < 100 then Break;
              Inc(Index);
            end;
            if Index >= Items.Count then Break;
          end;
          Items.Add(Goods);
          Goods.GetGraphObject.SetPosition(Goods.Position);
        end;
      Dec(SelectedGoodsCost, Round(Quantity / SelectedGoodsQuantity * SelectedGoodsCost));
      Dec(SelectedGoodsQuantity, Quantity);
      if SelectedGoodsQuantity < 1 then begin
        SelectedHoldKind := phkEmpty;
        SetCursorByName('Main');
        RefreshShipView;
      end;
    end;
  end;
  SkipOpeningSlide := True;
  PlayTransitionSounds := False;
  CloseClicked(nil);
end;
{ @end $58C058 }

{ @routine $58CA8C TfShip2_DropSelectedInArcade }
procedure TfShip2.DropSelectedInArcade;
var Item: TItem; Quantity, Step: Integer;
begin
  if (SelectedHoldKind = phkEquipment) and (SelectedHoldItem is TProtoplasm) and (TProtoplasm(SelectedHoldItem).Quantity > 1) then begin
    Quantity := TProtoplasm(SelectedHoldItem).Quantity;
    Step := 5;
    if Quantity <= 5 then Step := 1;
    if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.ThrowItem'), HighlightColorTag, '<Name>',
      LowerCaseWideString(GoodsNames[SelectedHoldItem.ItemType])), 0, Quantity, Step, Quantity) <> 1 then Exit;
    if (Quantity < 1) or (TProtoplasm(SelectedHoldItem).Quantity < Quantity) then Exit;
    Dec(TProtoplasm(SelectedHoldItem).Quantity, Quantity);
    with TProtoplasm(SelectedHoldItem) do begin Weight := Quantity; Cost := Quantity * 10; end;
    if ArcadeViewMode = avmSpace then begin
      Item := TProtoplasm.Create;
      TProtoplasm(Item).Init(Quantity, 0);
      ab_Item_Drop(PlayerArcadeShip, Item, 100, 150);
    end;
    if TProtoplasm(SelectedHoldItem).Quantity < 1 then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end;
    SoundManager.PlaySound('Sound.Drop');
  end else if (SelectedHoldKind = phkEquipment) or (SelectedHoldKind = phkArtefact) then begin
    if SelectedHoldItem is TArtefactTranclucator then
      ((SelectedHoldItem as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := nil;
    if SelectedHoldItem.ItemType = t_FuelTanks then begin
      if Player.FuelTanks = nil then begin
        ShowMessageBoxGI(Self, LocalizedText('FormShip.ThrowFuelTanksError'), mbgCancel);
        Exit;
      end;
    end else if SelectedHoldItem.ItemType = t_Engine then begin
      if Player.Engine = nil then begin
        ShowMessageBoxGI(Self, LocalizedText('FormShip.ThrowEngineError'), mbgCancel);
        Exit;
      end;
    end;
    SoundManager.PlaySound('Sound.Drop');
    if ArcadeViewMode <> avmSpace then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
    end else ab_Item_Drop(PlayerArcadeShip, SelectedHoldItem, 100, 150);
    SelectedHoldKind := phkEmpty;
    SetCursorByName('Main');
    RefreshShipView;
  end else if SelectedHoldKind = phkGoods then begin
    Quantity := SelectedGoodsQuantity;
    if SelectedGoodsQuantity > 1 then begin
      Step := 5;
      if SelectedGoodsQuantity <= 5 then Step := 1;
      if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.ThrowItem'), HighlightColorTag, '<Name>',
        LowerCaseWideString(GoodsNames[SelectedGoodsIndex])), 0, SelectedGoodsQuantity, Step, Quantity) <> 1 then Exit;
      if (Quantity < 1) or (Quantity > SelectedGoodsQuantity) then Exit;
    end;
    SoundManager.PlaySound('Sound.Drop');
    if ArcadeViewMode = avmSpace then begin
      Item := TGoods.Create;
      TGoods(Item).Init(SelectedGoodsIndex, Quantity);
      ab_Item_Drop(PlayerArcadeShip, Item, 100, 150);
    end;
    Dec(SelectedGoodsCost, Round(Quantity / SelectedGoodsQuantity * SelectedGoodsCost));
    Dec(SelectedGoodsQuantity, Quantity);
    if SelectedGoodsQuantity < 1 then begin
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
    end;
  end;
  BreakUiMessage;
end;
{ @end $58CA8C }

{ @routine $58CFD8 TfShip2_RepairSelected }
procedure TfShip2.RepairSelected(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var TotalCost, I: Integer; Equipment: TEquipment;
begin
  if ((SelectedHoldKind = phkEquipment) or (SelectedHoldKind = phkArtefact)) and
    (SelectedHoldItem as TEquipment).NeedsRepair then begin
      if (SelectedHoldKind = phkEquipment) or Player.CanRepairArtefactsAtLocation then begin
        if IsVirtualKeyDown(VK_SHIFT) then begin
          TotalCost := 0;
          if (SelectedHoldItem as TEquipment).NeedsRepair then
            Inc(TotalCost, (SelectedHoldItem as TEquipment).CalculateRepairCost);
          for I := 0 to Player.Inventory.Count - 1 do begin
            Equipment := Player.Inventory[I];
            if (Equipment <> SelectedHoldItem) and Equipment.EquippedFlag and Equipment.NeedsRepair then
              Inc(TotalCost, Equipment.CalculateRepairCost);
          end;
          if TotalCost > Player.Money then begin
            SoundManager.PlaySound('Sound.NoMoney');
            ShowMessageBoxGI(Self, FormatText2(LocalizedText('FormShip.RepairMsgNeedMoney'), HighlightColorTag,
              '<Name>', LowerCaseWideString(SelectedHoldItem.GetDisplayName), '<NeedMoney>', IntToStr(TotalCost - Player.Money)), mbgCancel);
            Exit;
          end;
          Player.SetMoney(Player.Money - TotalCost);
          for I := 0 to Player.Inventory.Count - 1 do begin
            Equipment := Player.Inventory[I];
            if (Equipment <> SelectedHoldItem) and Equipment.EquippedFlag and Equipment.NeedsRepair then Equipment.Repair;
          end;
        end else begin
          if (SelectedHoldItem as TEquipment).CalculateRepairCost > Player.Money then begin
            SoundManager.PlaySound('Sound.NoMoney');
            ShowMessageBoxGI(Self, FormatText2(LocalizedText('FormShip.RepairMsgNeedMoney'), HighlightColorTag,
              '<Name>', LowerCaseWideString(SelectedHoldItem.GetDisplayName), '<NeedMoney>',
              IntToStr((SelectedHoldItem as TEquipment).CalculateRepairCost - Player.Money)), mbgCancel);
            Exit;
          end;
          Player.SetMoney(Player.Money - (SelectedHoldItem as TEquipment).CalculateRepairCost);
        end;
        (SelectedHoldItem as TEquipment).Repair;
        RefreshStationDialog := True;
        SoundManager.PlaySound('Sound.Repair');
        if SelectedHoldKind = phkEquipment then begin
          I := 0;
          while I < Player.GetSlotCountForItemType(SelectedHoldItem.ItemType) do begin
            if Player.FindEquippedItemInSlot(SelectedHoldItem.ItemType, I) = nil then Break;
            Inc(I);
          end;
          if I < Player.GetSlotCountForItemType(SelectedHoldItem.ItemType) then begin
            Player.Inventory.Add(SelectedHoldItem);
            (SelectedHoldItem as TEquipment).AssignedSlotData := ((SelectedHoldItem as TEquipment).AssignedSlotData and $80) or I;
            (SelectedHoldItem as TEquipment).EquippedFlag := True;
            SelectedHoldKind := phkEmpty;
            SelectedHoldItem := nil;
          end;
        end else if SelectedHoldKind = phkArtefact then
          if not Player.HasActiveArtefact(SelectedHoldItem.ItemType) then begin
            Player.Artefacts.Add(SelectedHoldItem);
            (SelectedHoldItem as TEquipment).AssignedSlotData := 0;
            (SelectedHoldItem as TEquipment).EquippedFlag := False;
            (SelectedHoldItem as TEquipment).Equip;
            SelectedHoldKind := phkEmpty;
            SelectedHoldItem := nil;
          end;
        RefreshShipView;
      end else begin
        RefreshStationDialog := True;
        ShowMessageBoxGI(Self, LocalizedText('FormShip.NotLicenseForRepair'), mbgCancel);
        RefreshShipView;
      end;
    end;
  SkipOpeningSlide := True;
  PlayTransitionSounds := False;
  CloseClicked(nil);
end;
{ @end $58CFD8 }

{ @routine $58D65C TfShip2_SellSelected }
procedure TfShip2.SellSelected(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Text: WideString; Count, Remaining, Step: Integer;
begin
  if SelectedHoldKind = phkEmpty then Exit;
  if (Player.CurrentPlanet <> nil) and (Player.CurrentPlanet.GetRelationLevelToShip(Player) = rlHostile) then begin
    Text := LocalizedText('FormShip.SellOrBuyInPlanetAndBadRelations');
    Text := ReplaceColoredToken(Text, '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag);
    ShowMessageBoxGI(Self, Text, mbgCancel);
    Exit;
  end;
  if (SelectedHoldKind = phkEquipment) or (SelectedHoldKind = phkArtefact) then begin
    if (SelectedHoldItem.OwnerId = oiKling) and (Galaxy.CommunicatorResearchProgress < 100) and (Player.DockedTo is TSB) then begin
      if SelectedHoldItem.ItemType = t_Protoplasm then begin
        Text := LocalizedText('FormShip.SellProtoplasmInSB');
        ShowMessageBoxGI(Self, Text, mbgCancel);
      end else begin
        Galaxy.CommunicatorResearchProgress := Galaxy.CommunicatorResearchProgress + RemapClamped(SelectedHoldItem.Weight, 0, 100, 0.1, 0.5);
        if Galaxy.CommunicatorResearchProgress >= 100 then
          Galaxy.CommunicatorResearchProgress := Galaxy.CommunicatorResearchProgress - 0.0001;
        Galaxy.CommunicatorResearchPerDay := Min(0.01 * 10, Galaxy.CommunicatorResearchPerDay + RemapClamped(SelectedHoldItem.Weight, 0, 100, 0.001, 0.003));
        Text := LocalizedText('FormShip.SellRemainsInSB');
        ReplaceTextToken(Text, '<SBWorkPercent>', IntToStr(Round(Galaxy.CommunicatorResearchPerDay / 0.01 * 100)), HighlightColorTag);
        ShowMessageBoxGI(Self, Text, mbgCancel);
      end;
    end;
    if (SelectedHoldItem.ItemType = t_Protoplasm) and ((SelectedHoldItem as TProtoplasm).Quantity > 1) then begin
      Count := (SelectedHoldItem as TProtoplasm).Quantity;
      Step := 1;
      // Uses the selected goods index even for a protoplasm stack.
      if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.SellItem'), HighlightColorTag, '<Name>',
        LowerCaseWideString(GoodsNames[SelectedGoodsIndex])), 0, (SelectedHoldItem as TProtoplasm).Quantity, Step, Count) <> 1 then Exit;
      if (Count < 1) or ((SelectedHoldItem as TProtoplasm).Quantity < Count) then Exit;
      if (SelectedHoldItem as TProtoplasm).Quantity = Count then begin
        Player.SetMoney(Player.Money + SelectedHoldItem.CalculateResaleValue(Player.BaseSkills[skTrader]));
        (SelectedHoldItem as TProtoplasm).Quantity := 0;
      end else with SelectedHoldItem as TProtoplasm do begin
        Remaining := Quantity - Count;
        Quantity := Count;
        Weight := Count;
        Cost := Quantity * 10;
        Player.SetMoney(Player.Money + SelectedHoldItem.CalculateResaleValue(Player.BaseSkills[skTrader]));
        Quantity := Remaining;
        Weight := Remaining;
        Cost := Quantity * 10;
      end;
    end else begin
      Player.SetMoney(Player.Money + SelectedHoldItem.CalculateResaleValue(Player.BaseSkills[skTrader]));
      if SelectedHoldItem.ItemType = t_Protoplasm then (SelectedHoldItem as TProtoplasm).Quantity := 0;
    end;
    SoundManager.PlaySound('Sound.Sell');
    RefreshStationDialog := True;
    if (SelectedHoldItem.OwnerId in CoalitionOwners) and (SelectedHoldKind = phkEquipment) and
      (SelectedHoldItem.ItemType in ImprovableEquipmentTypes) then begin
      RestoreTemporaryShopStock;
      ClearTemporaryShopSlots;
      if Player.CurrentPlanet <> nil then Player.CurrentPlanet.EquipmentShop.Add(SelectedHoldItem)
      else (Player.DockedTo as TRuins).EquipmentShop.Add(SelectedHoldItem);
      BuildTemporaryShopSlotGrid;
    end else if (SelectedHoldItem.ItemType <> t_Protoplasm) or ((SelectedHoldItem as TProtoplasm).Quantity = 0) then begin
      SelectedHoldItem.Free;
      SelectedHoldItem := nil;
    end;
    if (SelectedHoldItem = nil) or (SelectedHoldItem.ItemType <> t_Protoplasm) or ((SelectedHoldItem as TProtoplasm).Quantity = 0) then begin
      SelectedHoldItem := nil;
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
    end;
    RefreshShipView;
  end else if SelectedHoldKind = phkGoods then begin
    Count := SelectedGoodsQuantity;
    if SelectedGoodsQuantity > 1 then begin
      Step := 1;
      if ShowCountBoxGI(Self, FormatText1(LocalizedText('FormShip.SellItem'), HighlightColorTag, '<Name>',
        LowerCaseWideString(GoodsNames[SelectedGoodsIndex])), 0, SelectedGoodsQuantity, Step, Count) <> 1 then Exit;
      if (Count < 1) or (Count > SelectedGoodsQuantity) then Exit;
    end;
    RefreshStationDialog := True;
    SoundManager.PlaySound('Sound.Sell');
    Player.CargoGoods[SelectedGoodsIndex].Count := SelectedGoodsQuantity;
    Player.CargoGoods[SelectedGoodsIndex].TotalCost := SelectedGoodsCost;
    Player.SellGoodsToLocation(SelectedGoodsIndex, Count);
    SelectedHoldKind := phkEmpty;
    SetCursorByName('Main');
    RefreshShipView;
  end;
  SkipOpeningSlide := True;
  PlayTransitionSounds := False;
  CloseClicked(nil);
end;
{ @end $58D65C }

{ @routine $58DF30 TfShip2_UseSelectedArtefact }
procedure TfShip2.UseSelectedArtefact(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Ship: TTranclucator;
  Angle: Single;
begin
  if SelectedHoldKind = phkArtefact then
  begin
    if (SelectedHoldItem is TArtefactTranclucator) and Player.InNormalSpace then
    begin
      SoundManager.PlaySound('Sound.UseATranc');
      Ship := (SelectedHoldItem as TArtefactTranclucator).Ship as TTranclucator;
      (SelectedHoldItem as TArtefactTranclucator).Ship := nil;
      Ship.CurrentStar := Player.CurrentStar;
      Player.CurrentStar.Ships.Add(Ship);
      Angle := SeededRandomIntRange(0, 360, Player.CurrentStar.GenerationSeed * Galaxy.CurrentTurn * Ship.Id) * Pi / 180;
      Ship.Position.X := Sin(Angle) * 100 + Player.Position.X;
      Ship.Position.Y := Player.Position.Y - Cos(Angle) * 100;
      Ship.Graphic.SetPosition(Ship.Position);
      SelectedHoldItem.Free;
      Player.RefreshDerivedStats;
      SelectedHoldKind := phkEmpty;
      SetCursorByName('Main');
      RefreshShipView;
      Ship.NextDay;
    end
    else if SelectedHoldItem is TArtefactTransmitter then
    begin
      if Player.UseArtefact(SelectedHoldItem as TArtefactTransmitter) then
      begin
        SoundManager.PlaySound('Sound.UseATranc');
        ShowMessageBoxGI(Self, LocalizedColorText('FormShip.UseTransmitter'), mbgCancel, 0);
      end
      else
      begin
        SoundManager.PlaySound('Sound.NoMoney');
        ShowMessageBoxGI(Self, LocalizedColorText('FormShip.NotUseTransmitter'), mbgCancel, 0);
      end;
    end;
    SkipOpeningSlide := True;
    PlayTransitionSounds := False;
    CloseClicked(nil);
  end;
end;
{ @end $58DF30 }
{ @routine $58E34C TfShip2_UpdateItemHover }
procedure TfShip2.UpdateItemHover;
type
  SEquipment = record // @size $08
    ItemType: TItemType; // @offset $00
    Name: WideString; // @offset $04
  end;
const
  ShipHoverSlots: array[0..7] of SEquipment = (
    (ItemType: t_FuelTanks; Name: 'FuelTanks'),
    (ItemType: t_Engine; Name: 'Engine'),
    (ItemType: t_Radar; Name: 'Radar'),
    (ItemType: t_Scaner; Name: 'Scaner'),
    (ItemType: t_RepairRobot; Name: 'RepairRobot'),
    (ItemType: t_CargoHook; Name: 'CargoHook'),
    (ItemType: t_DefGenerator; Name: 'DefGenerator'),
    (ItemType: WeaponCategoryItemType; Name: 'Weapon')); // @addr $618888
var Artefact: TArtefact; Item: TEquipment; Found, CanTake: Boolean; I, J: Integer; ItemType: TItemType; Entry: TPlayerHoldUnit;
begin
  Found := False;
  CanTake := False;
  if not Found then
  for ItemType := t_ArtefactHull to t_ArtefactAntigrav do begin
    with ArtefactSlotZones[ItemType] do
    if HitTest(GetCursorPoint) and Player.FindEquippedArtefact(ItemType, Artefact, False) then begin
      ShowEquipmentInfo(Artefact);
      Found := True;
      CanTake := True;
      Break;
    end;
  end;
  if not Found then begin
    for I := 0 to 7 do begin
      for J := 0 to Player.GetSlotCountForItemType(ShipHoverSlots[I].ItemType) - 1 do begin
        Item := Player.FindEquippedItemInSlot(ShipHoverSlots[I].ItemType, J);
        if Item = nil then Continue;
        with EquipmentSlotZones[I,J] do
        if HitTest(GetCursorPoint) then begin
          ShowEquipmentInfo(Item);
          Found := True;
          CanTake := True;
          Break;
        end;
      end;
    end;
  end;
  if not Found then begin
    with GetByName('S_Hull_0z') as TZoneGI do
    if HitTest(GetCursorPoint) then begin
      ShowEquipmentInfo(Player.Hull);
      Found := True;
    end;
  end;
  if not Found then begin
    for I := 0 to 5 do begin
      if I + HoldFirstIndex >= PlayerHoldEntries.Count then Entry := nil
      else Entry := PlayerHoldEntries[I + HoldFirstIndex];
      with HoldSlotZones[I] do
      if HitTest(GetCursorPoint) then begin
        if (Entry <> nil) and ((Entry.Kind = phkEquipment) or (Entry.Kind = phkArtefact)) then
          ShowEquipmentInfo(Entry.Item)
        else if (Entry <> nil) and (Entry.Kind = phkGoods) then
          ShowHoldGoodsInfo(Entry.GoodsIndex)
        else Continue;
        Found := True;
        CanTake := True;
        Break;
      end;
    end;
  end;
  if SelectedHoldKind = phkEmpty then begin
    if CanTake then begin
      if not IsCursorImageSelected('Take') then SetCursorByName('Take');
    end else if not IsCursorImageSelected('Main') then SetCursorByName('Main');
  end;
  if not Found and (HideItemTimer = 0) then ShowEquipmentInfo(nil);
end;
{ @end $58E34C }

{ @routine $58E5F0 TfShip2_AdvanceItemHover }
procedure TfShip2.AdvanceItemHover(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if PanelSlideTimer = 0 then UpdateItemHover;
end;
{ @end $58E5F0 }

{ @routine $58E600 TfShip2_HideItemInfo }
procedure TfShip2.HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if HideItemTimer <> 0 then begin
    CancelCallbackTimer(HideItemTimer);
    HideItemTimer := 0;
  end;
  GetByName('PII').SetActive(False);
  UpdateSelectedItemActions(SelectedHoldKind, SelectedGoodsIndex, SelectedGoodsQuantity, SelectedGoodsCost, SelectedHoldItem);
end;
{ @end $58E600 }

{ @routine $58E668 TfShip2_ShowEquipmentInfo }
procedure TfShip2.ShowEquipmentInfo(Item: TItem);
var Equipment: TEquipment;
begin
  Equipment := Item as TEquipment;
  if Equipment = nil then begin
    if HideItemTimer <> 0 then begin
      CancelCallbackTimer(HideItemTimer);
      HideItemTimer := 0;
    end;
    HideItemTimer := ScheduleCallbackTimer(300, 99999, HideItemInfo, 0);
  end else begin
    if HideItemTimer <> 0 then begin
      CancelCallbackTimer(HideItemTimer);
      HideItemTimer := 0;
    end;
    if (SelectedHoldKind = phkEmpty) and (Item is TArtefact) then
      UpdateSelectedItemActions(phkArtefact, Item.ItemType, 0, 0, Item)
    else if (SelectedHoldKind = phkEmpty) and (Item.ItemType <> t_Hull) then
      UpdateSelectedItemActions(phkEquipment, Item.ItemType, 0, 0, Item)
    else UpdateSelectedItemActions(phkEmpty, t_Hull, 0, 0, nil);
    GetByName('PII').SetActive(True);
    with ItemImage do begin
      SetImagePath('GI,' + Equipment.GetBitmapResourceName + 's');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetPosition(SubtractPoints(ItemImageCenter, GetVisualCenter));
    end;
    ItemNameLabel.SetText(WrapTextInColor(Equipment.GetDisplayName, HighlightColorTag));
    ItemDescriptionLabel.SetText(Equipment.GetInfoText(HighlightColorTag));
    ItemSizeLabel.SetText(IntToStr(Equipment.Weight));
    ItemPriceLabel.SetText(IntToStr(Equipment.Cost));
    with ItemRaceImage do begin
      SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Equipment.OwnerId].InternalName));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
    with GetByName('InfoDurable') as TImageGI do
      if not (Equipment.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) and (Equipment.ItemType <> t_Hull) then SetSize(GetContentSize)
      else if Equipment.ItemType = t_Hull then
        SetSize(Classes.Point(Round(GetContentSize.X * ((Equipment as THull).HullPoints / (Equipment as THull).Weight)), ClientSize.Y))
      else SetSize(Classes.Point(Round(GetContentSize.X * (Equipment.ConditionPercent / 100)), ClientSize.Y));
  end;
end;
{ @end $58E668 }

{ @routine $58EAB0 TfShip2_ShowHoldGoodsInfo }
procedure TfShip2.ShowHoldGoodsInfo(ItemType: TGoodsIndex);
begin
  RefreshRewardHint(0, 0);
  if HideItemTimer <> 0 then begin
    CancelCallbackTimer(HideItemTimer);
    HideItemTimer := 0;
  end;
  if SelectedHoldKind = phkEmpty then
    UpdateSelectedItemActions(phkGoods, ItemType, Player.CargoGoods[ItemType].Count, Player.CargoGoods[ItemType].TotalCost, nil);
  GetByName('PII').SetActive(True);
  with GetByName('InfoImage') as TImageGI do begin
    SetImagePath('GI,' + GetItemTypeBitmapPath(ItemType));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetPosition(SubtractPoints(ItemImageCenter, GetVisualCenter));
  end;
  (GetByName('InfoName') as TLabelGI).SetText(WrapTextInColor(GoodsNames[ItemType], HighlightColorTag));
  (GetByName('InfoText') as TLabelGI).SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(ItemType) + 1)));
  (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(Player.CargoGoods[ItemType].Count));
  (GetByName('InfoPrice') as TLabelGI).SetText(IntToStr(Player.CargoGoods[ItemType].TotalCost));
  with GetByName('EmRace') as TImageGI do begin
    SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Player.OwnerId].InternalName));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  with GetByName('InfoDurable') as TImageGI do SetSize(GetContentSize);
end;
{ @end $58EAB0 }

{ @routine $58EF04 TfShip2_ProcessCallbackTimers }
procedure TfShip2.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(2);
end;
{ @end $58EF04 }

{ @routine $58EF34 TfShip2_SelectMusic }
procedure TfShip2.SelectMusic;
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
  else if not OpenedFromArcade and Player.InNormalSpace then
  begin
    if MusicInSpace then MusicManager.PlayCategory('StarMap')
    else MusicManager.RequestFadeOut;
  end;
end;
{ @end $58EF34 }

{ @routine $58F0D8 RunShipEquipment }
function RunShipEquipment(ParentLoop: TMessageLoopGI): Boolean;
var State: TCursorStateGI;
begin
  ParentLoop.RootUiObject.NativeHook50;
  ParentLoop.CaptureCursorState(@State);
  ParentLoop.SetCursorActive(False);
  ParentLoop.DrawQueuedUpdateRects;
  ShipScreen.ParentLoop := ParentLoop;
  if ShipScreen.Run = 1 then Result := True else Result := False;
  ShipScreen.ParentLoop := nil;
  ParentLoop.InvalidateViewport;
  ParentLoop.RestoreCursorState(@State);
  ParentLoop.UpdateCursorPosition;
  ParentLoop.RootUiObject.NativeHook48;
end;
{ @end $58F0D8 }

end.

unit fScaner;
// Unit bracket (inferred): CODE 0x0057E79C..0x0058330B; inclusive evidence, not full bounds.
// Scanner: native VMT $57E7E8; portraits, skills, awards, cargo and item hints.
interface
uses GI_MessageLoop, GI_GraphBuf, GI_GraphButton, GI_Window, GI_Label, GI_Image,
  Types, aShip, aNormalShip, aItem;
type
  TfScaner = class(TMessageLoopGI) // @size $F0
  public
    BackgroundBuffer: TGraphBufGI; // @offset $B0
    ExitButton: TGraphButtonGI; // @offset $B4
    ShipToInspect: TShip; // @offset $B8 Borrowed scan target.
    RewardsBuffer: TGraphBufGI; // @offset $BC
    RewardWindow: TWindowGI; // @offset $C0
    VisibleCargoCount: Integer; // @offset $C4
    CargoOffset: Integer; // @offset $C8
    CargoEntryCount: Integer; // @offset $CC
    PanelSlideTimer: TCallbackTimerIdGI; // @offset $D0
    PanelSlideStep: Integer; // @offset $D4
    ItemHoverTimer: TCallbackTimerIdGI; // @offset $D8
    HideItemTimer: TCallbackTimerIdGI; // @offset $DC
    PropertyHintTimer: TCallbackTimerIdGI; // @offset $E0
    ShipImageCenter: TPoint; // @offset $E4
    HoveredRewardId: Integer; // @offset $EC
    procedure SelectMusic; override; // @addr $5831AC
    procedure OnOpen; override; // @addr $57EA28
    procedure Update; // @addr $58141C
    procedure UpdateItemHover; // @addr $581F7C
    procedure ShowPropertyInfo(Sender: TObjectGI); // @addr $58069C
    procedure ShowItemInfo(Item: TItem); // @addr $58240C
    procedure ShowGoodsInfo(ItemType: TGoodsIndex); // @addr $582D24
    procedure BuildRewardStrip(Ship: TShip); // @addr $57FDA8
    procedure InitializeLayout; override; // @addr $57E824
    procedure OnClose; override; // @addr $57FD34
    procedure RewardMouseLeave(Sender: TObjectGI); // @addr $580280
    procedure ShowRewardInfo(Ship: TNormalShip; AwardId: Integer); // @addr $580288
    procedure HideRewardInfo; // @addr $5805B8
    procedure AdvancePanelSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5805D0
    procedure CloseClicked(Sender: TObjectGI); // @addr $58064C
    procedure RewardsClicked(Sender: TObjectGI); // @addr $580678
    procedure HidePropertyInfo(Sender: TObjectGI); // @addr $5810FC
    procedure RefreshRewardHint(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $58113C
    procedure CountCargoEntries; // @addr $5811BC
    function GetCargoEntry(Index: Integer; var ItemType: TItemType; var Item: TItem): Boolean; // @addr $581240
    procedure ScrollCargoLeft(Sender: TObjectGI); // @addr $581D20
    procedure ScrollCargoRight(Sender: TObjectGI); // @addr $581D2C
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $581D38
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $581DB0
    procedure MainPanelMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $581DFC
    procedure AdvanceItemHover(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $582320
    procedure HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $582328
    procedure RewardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5801E0
  end;
implementation

// @unit-initialization $5832F8
// @unit-finalization $583218

uses Classes, SysUtils, Math, Windows, EC_Struct, GR_Main, GR_gi, GR_GraphBuf, GI_Zone,
  Globals, GlobalsV, aConst, aMyFunction, aPlayer, fShip2, aTranclucator, EC_Str, aRanger, aWarrior, aPirate, aTransport, aKling, GI_gai;

{ @routine $57E824 TfScaner_InitializeLayout }
procedure TfScaner.InitializeLayout;
begin
  inherited InitializeLayout;
  BackgroundBuffer := GetByName('BGBuf') as TGraphBufGI;
  ExitButton := GetByName('Exit') as TGraphButtonGI;
  ExitButton.UpCallback := CloseClicked;
  RewardsBuffer := GetByName('RewardsImg') as TGraphBufGI;
  RewardWindow := GetByName('RewardWnd') as TWindowGI;
  (GetByName('S_Left') as TGraphButtonGI).UpCallback := ScrollCargoLeft;
  (GetByName('S_Right') as TGraphButtonGI).UpCallback := ScrollCargoRight;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  GetByName('MainPanel').LeftButtonUpCallback := MainPanelMouseUp;
  with GetByName('Ship3D') do ShipImageCenter := AddPoints(LocalPosition, HalfPoint(ClientSize));
end;
{ @end $57E824 }

{ @routine $57EA28 TfScaner_OnOpen }
procedure TfScaner.OnOpen;
var
  I, FaceCount: Integer;
  CharacterName: WideString;
  CaptainAnimation: TgaiGI;
begin
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  BackgroundBuffer.GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  ShipToInspect := ScannerTarget as TShip;
  CountCargoEntries;
  VisibleCargoCount := 6;
  CargoOffset := 0;
  for I := 0 to 5 do
    with GetByName('Skill' + IntToStr(I) + 'z') as TZoneGI do
    begin
      EnterCallback := ShowPropertyInfo;
      LeaveCallback := HidePropertyInfo;
    end;
  GetByName('PII').SetActive(False);
  if ShipToInspect.ShipType = t_Ranger then
  begin
    with ShipToInspect as TRanger do
    begin
      CharacterName := (ShipToInspect as TRanger).GetCharacterName;
      (GetByName('ShipName') as TLabelGI).SetText(GetFullName(#13#10) + #13#10 + ' ' + #13#10 + CharacterName);
    end;
  end
  else (GetByName('ShipName') as TLabelGI).SetText(ShipToInspect.GetFullName(#13#10));
  with GetByName('Ship3D') as TImageGI do
  begin
    if ShipToInspect is TRanger then SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 0].PortraitImagePath)
    else if ShipToInspect is TWarrior then SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 1].PortraitImagePath)
    else if ShipToInspect is TPirate then SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 2].PortraitImagePath)
    else if ShipToInspect is TTransport then
      case (ShipToInspect as TTransport).TransportType of
        ttTransport: SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 3].PortraitImagePath);
        ttLiner: SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 4].PortraitImagePath);
        ttDiplomat: SetImagePath(ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 5].PortraitImagePath);
      end
    else if ShipToInspect is TKling then SetImagePath(KlissanRenderTemplates[Ord((ShipToInspect as TKling).KlingType)].PortraitImagePath)
    else if ShipToInspect is TTranclucator then SetImagePath(GameDataConfig.GetParamByPath('SE.Ship.Tranclucator.' + GiResourceSuffix + 'ImageP'))
    else SetImagePath('');
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetPosition(SubtractPoints(ShipImageCenter, GetVisualCenter));
  end;
  GetByName('RankWnd').SetActive(False);
  with GetByName('RankI') as TImageGI do
  begin
    MouseEnterCallback := ShowPropertyInfo;
    MouseLeaveCallback := HidePropertyInfo;
    if ShipToInspect is TNormalShip then
    begin
      if ShipToInspect is TTranclucator then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank3')
      else if (ShipToInspect as TNormalShip).Rank = crRookie then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank0')
      else if (ShipToInspect as TNormalShip).Rank = crCadet then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank1')
      else if (ShipToInspect as TNormalShip).Rank = crPilot then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank2')
      else if (ShipToInspect as TNormalShip).Rank = crWingman then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank3')
      else if (ShipToInspect as TNormalShip).Rank = crLeader then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank4')
      else if (ShipToInspect as TNormalShip).Rank = crAce then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank5')
      else if (ShipToInspect as TNormalShip).Rank = crCommander then SetImagePath('GI,Bm.FormShip.' + GiResourceSuffix + 'Rank6');
    end;
  end;
  if (ShipToInspect.AwardIds = nil) or (ShipToInspect.AwardIds.Count < 1) then
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
      SetText(IntToStr(ShipToInspect.AwardIds.Count));
      SetActive(True);
    end;
  end;
  with GetByName('SkillFreePoints') as TLabelGI do SetText(IntToStr(ShipToInspect.FreeExperience));
  with GetByName('Skill0') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skAccuracy]), ClientSize.Y));
  with GetByName('Skill1') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skMobility]), ClientSize.Y));
  with GetByName('Skill2') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skTechnical]), ClientSize.Y));
  with GetByName('Skill3') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skTrader]), ClientSize.Y));
  with GetByName('Skill4') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skCharm]), ClientSize.Y));
  with GetByName('Skill5') as TImageGI do SetSize(Classes.Point(Round(GetContentSize.X / 5 * ShipToInspect.BaseSkills[skLeadership]), ClientSize.Y));
  GetByName('S_Left').SetActive(False);
  GetByName('S_Right').SetActive(False);
  GetByName('S_Left').SetActive(True);
  GetByName('S_Right').SetActive(True);
  if ShipToInspect is TTranclucator then
  begin
    with GetByName('CaptainI') as TImageGI do
    begin
      SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + 'Tranclucatori');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end;
    with GetByName('CaptainA') as TgaiGI do
    begin
      FirstFrameOnly := not AnimCaptain;
      SetImagePath('Bm.Captain.' + GiResourceSuffix + 'Tranclucatora');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end;
  end
  else if ShipToInspect is TNormalShip then
  begin
    FaceCount := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[ShipToInspect.OwnerId].InternalName));
    // The original divides by FaceCount - 1, including the FaceCount = 1 edge case.
    if FaceCount < 1 then I := 0 else I := Integer(ShipToInspect.Seed) mod (FaceCount - 1) + 1;
    with GetByName('CaptainI') as TImageGI do
      if FaceCount > 0 then
      begin
        SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[ShipToInspect.OwnerId].InternalName + IntToStr(I) + 'i');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
      end
      else SetActive(False);
    CaptainAnimation := GetByName('CaptainA') as TgaiGI;
    with CaptainAnimation do
    begin
      FirstFrameOnly := not AnimCaptain;
      if FaceCount > 0 then
      begin
        SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[ShipToInspect.OwnerId].InternalName + IntToStr(I) + 'a');
        SequenceIndex := 0;
        UpdateAutoGeometry;
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
        RestartPlayback;
      end
      else CaptainAnimation.SetActive(False);
    end;
  end;
  BuildRewardStrip(ShipToInspect);
  Update;
  InvalidateViewport;
  DrawQueuedUpdateRects;
  if GiResourceVariant = 2 then GetByName('Left').SetPosition(Classes.Point(355, GetByName('Left').LocalPosition.Y))
  else GetByName('Left').SetPosition(Classes.Point(277, GetByName('Left').LocalPosition.Y));
  PanelSlideStep := -30;
  if PanelSlideTimer <> 0 then
  begin
    CancelCallbackTimer(PanelSlideTimer);
    PanelSlideTimer := 0;
  end;
  PanelSlideTimer := ScheduleCallbackTimer(20, 20, AdvancePanelSlide, 0);
  if ItemHoverTimer <> 0 then
  begin
    CancelCallbackTimer(ItemHoverTimer);
    ItemHoverTimer := 0;
  end;
  ItemHoverTimer := ScheduleCallbackTimer(100, 100, AdvanceItemHover, 0);
end;
{ @end $57EA28 }

{ @routine $57FD34 TfScaner_OnClose }
procedure TfScaner.OnClose;
begin
  if ItemHoverTimer <> 0 then
  begin
    CancelCallbackTimer(ItemHoverTimer);
    ItemHoverTimer := 0;
  end;
  if HideItemTimer <> 0 then
  begin
    CancelCallbackTimer(HideItemTimer);
    HideItemTimer := 0;
  end;
  if PropertyHintTimer <> 0 then
  begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
  if PanelSlideTimer <> 0 then
  begin
    CancelCallbackTimer(PanelSlideTimer);
    PanelSlideTimer := 0;
  end;
end;
{ @end $57FD34 }

{ @routine $57FDA8 TfScaner_BuildRewardStrip }
procedure TfScaner.BuildRewardStrip(Ship: TShip);
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
  if not (Ship is TNormalShip) or (Ship.AwardIds = nil) or (Ship.AwardIds.Count < 1) then
  begin
    RewardsBuffer.SetActive(False);
    Exit;
  end;
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
    if Image.Height > Size then AppendLogLineThreadSafe('Error: Scaner RewardsBuild Y')
    else if Image.Width + DrawIndex * Spacing > RewardsBuffer.GraphBuf.Width then AppendLogLineThreadSafe('Error: Scaner RewardsBuild X')
    else RewardsBuffer.GraphBuf.BlendRect32(Classes.Point(DrawIndex * Spacing, 0), Image, Classes.Rect(0, 0, Image.Width, Image.Height));
    Inc(I);
    Inc(DrawIndex);
  end;
  Image.Free;
end;
{ @end $57FDA8 }

{ @routine $5801E0 TfScaner_RewardsMouseMove }
procedure TfScaner.RewardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Size, Index: Integer;
  Ship: TNormalShip;
  Reward: Pointer;
begin
  Size := GiScalePixels(20) div 2;
  Ship := ShipToInspect as TNormalShip;
  Index := Sender.ToLocalPoint(Point).X div Size + Max(0, Ship.AwardIds.Count - 8);
  if Index >= Ship.AwardIds.Count then Index := Ship.AwardIds.Count - 1;
  Reward := Ship.AwardIds[Index];
  ShowRewardInfo(Ship, PByte(Reward)^);
end;
{ @end $5801E0 }

{ @routine $580280 TfScaner_RewardMouseLeave }
procedure TfScaner.RewardMouseLeave(Sender: TObjectGI);
begin
  HideRewardInfo;
end;
{ @end $580280 }

{ @routine $580288 TfScaner_ShowRewardInfo }
procedure TfScaner.ShowRewardInfo(Ship: TNormalShip; AwardId: Integer);
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
{ @end $580288 }

{ @routine $5805B8 TfScaner_HideRewardInfo }
procedure TfScaner.HideRewardInfo;
begin
  HoveredRewardId := -1;
  RewardWindow.SetActive(False);
end;
{ @end $5805B8 }

{ @routine $5805D0 TfScaner_AdvancePanelSlide }
procedure TfScaner.AdvancePanelSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal);
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
{ @end $5805D0 }

{ @routine $58064C TfScaner_CloseClicked }
procedure TfScaner.CloseClicked(Sender: TObjectGI);
begin
  AuxRenderBuffer.Clear;
  RequestedScreenId := ScannerReturnScreenId;
  RequestClose(1);
end;
{ @end $58064C }

{ @routine $580678 TfScaner_RewardsClicked }
procedure TfScaner.RewardsClicked(Sender: TObjectGI);
begin
  AwardSubject := ShipToInspect;
  RequestedScreenId := screenRewards;
  RequestClose(1);
end;
{ @end $580678 }

{ @routine $58069C TfScaner_ShowPropertyInfo }
procedure TfScaner.ShowPropertyInfo(Sender: TObjectGI);
var
  ImagePath, Title, Text: WideString;
  Skill: TSkill;
  Ship: TNormalShip;
begin
  ImagePath := '';
  if Sender is TImageGI then
  begin
    if ShipToInspect is TNormalShip then
    begin
      if ShipToInspect is TTranclucator then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank3'
      else if (ShipToInspect as TNormalShip).Rank = crRookie then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank0'
      else if (ShipToInspect as TNormalShip).Rank = crCadet then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank1'
      else if (ShipToInspect as TNormalShip).Rank = crPilot then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank2'
      else if (ShipToInspect as TNormalShip).Rank = crWingman then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank3'
      else if (ShipToInspect as TNormalShip).Rank = crLeader then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank4'
      else if (ShipToInspect as TNormalShip).Rank = crAce then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank5'
      else if (ShipToInspect as TNormalShip).Rank = crCommander then ImagePath := 'Bm.FormShip.' + GiResourceSuffix + 'Rank6';
    end;
    with GetByName('RankImage') as TGraphBufGI do
    begin
      SetActive(ImagePath <> '');
      SourceHasPerPixelAlpha := True;
      if ImagePath <> '' then
      begin
        LoadGiByPathIntoGraphBuf(ImagePath, GraphBuf);
        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
        else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
    end;
    if ShipToInspect is TNormalShip then
    begin
      Ship := ShipToInspect as TNormalShip;
      Title := WrapTextInColor(Ship.GetRankLongName, HighlightColorTag);
      Text := Ship.GetRankDescription;
      if Ship.Rank <> crCommander then
        if Ship.GetRankPointsToNextRank > 0 then
          Text := Text + ' ' + FormatText2(LocalizedText('Rank.NextRankText'), HighlightColorTag, '<NextRank>', Ship.GetNextRankName, '<WarPoints>', IntToStr(Ship.GetRankPointsToNextRank))
        else Text := Text + ' ' + FormatText1(LocalizedText('Rank.NextRankGetText'), HighlightColorTag, '<NextRank>', Ship.GetNextRankName);
    end;
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
    Text := FormatText1(LocalizedText('Skills.' + SkillConfigNames[Skill] + '.Text'), HighlightColorTag, '<SkillValue>', IntToStr(SkillEffectValues[ShipToInspect.BaseSkills[Skill], Skill]));
    if ShipToInspect.BaseSkills[Skill] < 5 then
      Text := Text + #13#10 + #13#10 + FormatText1(LocalizedText('Skills.PointForNextLevel'), HighlightColorTag, '<PointForNextLevel>', IntToStr(SkillTrainingCosts[ShipToInspect.BaseSkills[Skill] + 1, Skill]));
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
{ @end $58069C }

{ @routine $5810FC TfScaner_HidePropertyInfo }
procedure TfScaner.HidePropertyInfo(Sender: TObjectGI);
begin
  if PropertyHintTimer <> 0 then
  begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
  PropertyHintTimer := ScheduleCallbackTimer(300, 99999, RefreshRewardHint, 0);
end;
{ @end $5810FC }

{ @routine $58113C TfScaner_RefreshRewardHint }
procedure TfScaner.RefreshRewardHint(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if PropertyHintTimer <> 0 then
  begin
    CancelCallbackTimer(PropertyHintTimer);
    PropertyHintTimer := 0;
  end;
  GetByName('RankWnd').SetActive(False);
  (GetByName('RankText') as TLabelGI).SetText('');
end;
{ @end $58113C }

{ @routine $5811BC TfScaner_CountCargoEntries }
procedure TfScaner.CountCargoEntries;
var I: Integer; Kind: TGoodsIndex; Equipment: TEquipment;
begin
  CargoEntryCount := 0;
  for Kind := t_Food to t_Narcotics do
    if ShipToInspect.CargoGoods[Kind].Count > 0 then Inc(CargoEntryCount);
  for I := 0 to ShipToInspect.Inventory.Count - 1 do
  begin
    Equipment := TEquipment(ShipToInspect.Inventory[I]);
    if (Equipment.ItemType <> t_Hull) and not Equipment.EquippedFlag then Inc(CargoEntryCount);
  end;
  // The native count includes equipped artefacts; GetCargoEntry skips them.
  Inc(CargoEntryCount, ShipToInspect.Artefacts.Count);
end;
{ @end $5811BC }

{ @routine $581240 TfScaner_GetCargoEntry }
function TfScaner.GetCargoEntry(Index: Integer; var ItemType: TItemType; var Item: TItem): Boolean;
var
  I: Integer;
  Kind: TGoodsIndex;
  Equipment: TEquipment;
begin
  for Kind := t_Food to t_Narcotics do
  begin
    if ShipToInspect.CargoGoods[Kind].Count <= 0 then Continue;
    Dec(Index);
    if Index < 0 then
    begin
      Item := nil;
      ItemType := Kind;
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to ShipToInspect.Inventory.Count - 1 do
  begin
    Equipment := TEquipment(ShipToInspect.Inventory[I]);
    if (Equipment.ItemType = t_Hull) or Equipment.EquippedFlag then Continue;
    Dec(Index);
    if Index < 0 then
    begin
      Item := Equipment;
      ItemType := Equipment.ItemType;
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to ShipToInspect.Artefacts.Count - 1 do
  begin
    Equipment := TEquipment(ShipToInspect.Artefacts[I]);
    if Equipment.EquippedFlag then Continue;
    Dec(Index);
    if Index < 0 then
    begin
      Item := Equipment;
      ItemType := Equipment.ItemType;
      Result := True;
      Exit;
    end;
  end;
  Item := nil;
  ItemType := t_Food;
  Result := False;
end;
{ @end $581240 }

{ @routine $58141C TfScaner_Update }
procedure TfScaner.Update;
type
  SEquipment = record // @size $08
    ItemType: TItemType; // @offset $00
    Name: WideString; // @offset $04
  end;
const
  ScannerDisplaySlots: array[0..7] of SEquipment = (
    (ItemType: t_FuelTanks; Name: 'FuelTanks'),
    (ItemType: t_Engine; Name: 'Engine'),
    (ItemType: t_Radar; Name: 'Radar'),
    (ItemType: t_Scaner; Name: 'Scaner'),
    (ItemType: t_RepairRobot; Name: 'RepairRobot'),
    (ItemType: t_CargoHook; Name: 'CargoHook'),
    (ItemType: t_DefGenerator; Name: 'DefGenerator'),
    (ItemType: WeaponCategoryItemType; Name: 'Weapon')); // @addr $618784
var
  I, SlotIndex: Integer;
  Item: TItem;
  CargoKind: TItemType;
  Artefact: TArtefact;
  Text: WideString;
begin
  ShipToInspect.RefreshAssignedItemSlots;
  Text := IntToStr(ShipToInspect.GetDefensePercent) + '%';
  Text := Text + ' + ' + WrapTextInColor(IntToStr(ShipToInspect.Hull.Armor + 5 * (Ord(ShipToInspect.HasActiveArtefact(t_ArtefactHull)))), '');
  (GetByName('IDef') as TLabelGI).SetText(Text);
  (GetByName('IMass') as TLabelGI).SetText(IntToStr(ShipToInspect.GetEffectiveMass));
  if ShipToInspect.CalculateSpeed = 0 then Text := RedColorTag else Text := '';
  (GetByName('ISpeed') as TLabelGI).SetText(WrapTextInColor(IntToStr(ShipToInspect.CalculateSpeed), Text));
  if ShipToInspect.GetCargoFreeSpace < 0 then Text := RedColorTag else Text := '';
  (GetByName('IEmpty') as TLabelGI).SetText(WrapTextInColor(IntToStr(ShipToInspect.GetCargoFreeSpace), Text));
  (GetByName('S_Left') as TGraphButtonGI).SetDisabled(not (CargoOffset > 0));
  (GetByName('S_Right') as TGraphButtonGI).SetDisabled(not (CargoOffset + VisibleCargoCount <= CargoEntryCount));
  for I := 0 to 7 do
    for SlotIndex := 0 to ShipToInspect.GetSlotCountForItemType(ScannerDisplaySlots[I].ItemType) - 1 do
    begin
      Item := ShipToInspect.FindEquippedItemInSlot(ScannerDisplaySlots[I].ItemType, SlotIndex);
      with GetByName('S_' + ScannerDisplaySlots[I].Name + '_' + IntToStr(SlotIndex) + 'i') as TImageGI do
        if Item = nil then SetImagePath('')
        else
        begin
          SetImagePath('GI,' + Item.GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
      GetByName('S_' + ScannerDisplaySlots[I].Name + '_' + IntToStr(SlotIndex) + 'n').SetActive(Item <> nil);
    end;
  I := 0;
  for CargoKind := t_ArtefactHull to t_ArtefactAntigrav do
  begin
    ShipToInspect.FindEquippedArtefact(CargoKind, Artefact, True);
    GetByName('Ar' + IntToStr(I) + 'n').SetActive(Artefact <> nil);
    GetByName('Ar' + IntToStr(I) + 'i').SetActive(Artefact <> nil);
    if Artefact <> nil then
      with GetByName('Ar' + IntToStr(I) + 'i') as TImageGI do
      begin
        SetImagePath('GI,' + Artefact.GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
    (GetByName('Ar' + IntToStr(I) + 'z') as TZoneGI).SetActive(Artefact <> nil);
    Inc(I);
  end;
  for I := 0 to VisibleCargoCount - 1 do
    with GetByName('S_' + IntToStr(I) + 'i') as TImageGI do
      if not GetCargoEntry(CargoOffset + I, CargoKind, Item) then SetImagePath('')
      else if CargoKind in [t_Food..t_Narcotics] then
      begin
        SetImagePath('GI,' + GetItemTypeBitmapPath(CargoKind));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end
      else
      begin
        SetImagePath('GI,' + Item.GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
end;
{ @end $58141C }

{ @routine $581D20 TfScaner_ScrollCargoLeft }
procedure TfScaner.ScrollCargoLeft(Sender: TObjectGI);
begin
  Dec(CargoOffset);
  Update;
end;
{ @end $581D20 }

{ @routine $581D2C TfScaner_ScrollCargoRight }
procedure TfScaner.ScrollCargoRight(Sender: TObjectGI);
begin
  Inc(CargoOffset);
  Update;
end;
{ @end $581D2C }

{ @routine $581D38 TfScaner_MainPanelKeyDown }
procedure TfScaner.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_ESCAPE then
  begin
    AuxRenderBuffer.Clear;
    RequestedScreenId := ScannerReturnScreenId;
    RequestClose(1);
  end
  else if Key = VK_LEFT then
  begin
    if CargoOffset > 0 then
    begin
      Dec(CargoOffset);
      Update;
    end;
  end
  else if (Key = VK_RIGHT) and (CargoOffset + VisibleCargoCount <= CargoEntryCount) then
  begin
    Inc(CargoOffset);
    Update;
  end;
end;
{ @end $581D38 }

{ @routine $581DB0 TfScaner_ProcessMouseWheel }
procedure TfScaner.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then
  begin
    if CargoOffset > 0 then
    begin
      Dec(CargoOffset);
      Update;
    end;
  end
  else if (Delta = -WHEEL_DELTA) and (CargoOffset + VisibleCargoCount <= CargoEntryCount) then
  begin
    Inc(CargoOffset);
    Update;
  end;
end;
{ @end $581DB0 }

{ @routine $581DFC TfScaner_MainPanelMouseUp }
procedure TfScaner.MainPanelMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if PanelSlideTimer <> 0 then Exit;
  if (GetByName('PanelLeft') as TImageGI).HitTestPixel(Point) then Exit;
  if (GetByName('RightClose') as TImageGI).HitTestPixel(Point) then Exit;
  CloseClicked(nil);
end;
{ @end $581DFC }

{ @routine $581F7C TfScaner_UpdateItemHover }
procedure TfScaner.UpdateItemHover;
type
  SEquipment = record // @size $08
    ItemType: TItemType; // @offset $00
    Name: WideString; // @offset $04
  end;
const
  ScannerHoverSlots: array[0..7] of SEquipment = (
    (ItemType: t_FuelTanks; Name: 'FuelTanks'),
    (ItemType: t_Engine; Name: 'Engine'),
    (ItemType: t_Radar; Name: 'Radar'),
    (ItemType: t_Scaner; Name: 'Scaner'),
    (ItemType: t_RepairRobot; Name: 'RepairRobot'),
    (ItemType: t_CargoHook; Name: 'CargoHook'),
    (ItemType: t_DefGenerator; Name: 'DefGenerator'),
    (ItemType: WeaponCategoryItemType; Name: 'Weapon')); // @addr $6187C4
var
  Artefact: TArtefact;
  Item: TItem;
  CargoKind: TItemType;
  I, SlotIndex: Integer;
  Found: Boolean;
begin
  Found := False;
  if not Found then
  begin
    I := 0;
    for CargoKind := t_ArtefactHull to t_ArtefactAntigrav do
    begin
      with GetByName('Ar' + IntToStr(I) + 'z') as TZoneGI do
        if HitTest(GetCursorPoint) and ShipToInspect.FindEquippedArtefact(CargoKind, Artefact, True) then
        begin
          ShowItemInfo(Artefact);
          Found := True;
          Break;
        end;
      Inc(I);
    end;
  end;
  if not Found then
    for I := 0 to 7 do
      for SlotIndex := 0 to ShipToInspect.GetSlotCountForItemType(ScannerHoverSlots[I].ItemType) - 1 do
      begin
        Item := ShipToInspect.FindEquippedItemInSlot(ScannerHoverSlots[I].ItemType, SlotIndex);
        if Item = nil then Continue;
        with GetByName('S_' + ScannerHoverSlots[I].Name + '_' + IntToStr(SlotIndex) + 'z') as TZoneGI do
          if HitTest(GetCursorPoint) then
          begin
            ShowItemInfo(Item);
            Found := True;
            Break;
          end;
      end;
  if not Found then
    with GetByName('S_Hull_0z') as TZoneGI do
      if HitTest(GetCursorPoint) then
      begin
        ShowItemInfo(ShipToInspect.Hull);
        Found := True;
      end;
  if not Found then
    for I := 0 to VisibleCargoCount - 1 do
      with GetByName('S_' + IntToStr(I) + 'z') as TZoneGI do
        if HitTest(GetCursorPoint) then
          if GetCargoEntry(CargoOffset + I, CargoKind, Item) then
          begin
            if CargoKind in [t_Food..t_Narcotics] then ShowGoodsInfo(CargoKind) else ShowItemInfo(Item);
            Found := True;
            Break;
          end;
  if not Found and (HideItemTimer = 0) then ShowItemInfo(nil);
end;
{ @end $581F7C }

{ @routine $582320 TfScaner_AdvanceItemHover }
procedure TfScaner.AdvanceItemHover(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  UpdateItemHover;
end;
{ @end $582320 }

{ @routine $582328 TfScaner_HideItemInfo }
procedure TfScaner.HideItemInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if HideItemTimer <> 0 then
  begin
    CancelCallbackTimer(HideItemTimer);
    HideItemTimer := 0;
  end;
  GetByName('PII').SetActive(False);
  (GetByName('InfoText') as TLabelGI).SetText('');
  (GetByName('InfoSize') as TLabelGI).SetText('');
  (GetByName('InfoPrice') as TLabelGI).SetText('');
end;
{ @end $582328 }

{ @routine $58240C TfScaner_ShowItemInfo }
procedure TfScaner.ShowItemInfo(Item: TItem);
var
  Text: WideString;
begin
  Item := Item as TEquipment;
  if Item = nil then
  begin
    if HideItemTimer <> 0 then
    begin
      CancelCallbackTimer(HideItemTimer);
      HideItemTimer := 0;
    end;
    HideItemTimer := ScheduleCallbackTimer(300, 99999, HideItemInfo, 0);
  end
  else
  begin
    if HideItemTimer <> 0 then
    begin
      CancelCallbackTimer(HideItemTimer);
      HideItemTimer := 0;
    end;
    GetByName('PII').SetActive(True);
    with GetByName('InfoImage') as TImageGI do
    begin
      SetActive(Item.ItemType <> t_Hull);
      if Active then
      begin
        SetImagePath('GI,' + Item.GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
      end;
    end;
    with GetByName('InfoImage2') as TGraphBufGI do
    begin
      SetActive(Item.ItemType = t_Hull);
      if Active then
      begin
        Text := '';
        if ShipToInspect is TRanger then Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 0].PortraitImagePath
        else if ShipToInspect is TWarrior then Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 1].PortraitImagePath
        else if ShipToInspect is TPirate then Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 2].PortraitImagePath
        else if ShipToInspect is TTransport then
          case (ShipToInspect as TTransport).TransportType of
            ttTransport: Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 3].PortraitImagePath;
            ttLiner: Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 4].PortraitImagePath;
            ttDiplomat: Text := ShipRenderTemplates[ShipToInspect.Hull.OwnerId, 5].PortraitImagePath;
          end
        else if ShipToInspect is TKling then Text := KlissanRenderTemplates[Ord((ShipToInspect as TKling).KlingType)].PortraitImagePath
        else if ShipToInspect is TTranclucator then Text := GameDataConfig.GetParamByPath('SE.Ship.Tranclucator.' + GiResourceSuffix + 'ImageP')
        else Text := '';
        SetActive(Text <> '');
        if Active then
        begin
          SourceHasPerPixelAlpha := True;
          LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(Text, 1, ','), GraphBuf);
          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X - 5, Round((ClientSize.X - 5) / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else GraphBuf.RescaleRgba(Round((ClientSize.Y - 5) / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y - 5, 5);
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
      end;
    end;
    (GetByName('InfoName') as TLabelGI).SetText(WrapTextInColor(Item.GetDisplayName, HighlightColorTag));
    (GetByName('InfoText') as TLabelGI).SetText(Item.GetInfoText(HighlightColorTag));
    (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(Item.Weight));
    (GetByName('InfoPrice') as TLabelGI).SetText(IntToStr(Item.Cost));
    if ShipToInspect is TNormalShip then
      with GetByName('EmRace') as TImageGI do
      begin
        SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Item.OwnerId].InternalName));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
    with GetByName('InfoDurable') as TImageGI do
      if not (Item.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) and (Item.ItemType <> t_Hull) then SetSize(GetContentSize)
      else if Item.ItemType = t_Hull then
        SetSize(Classes.Point(Round(GetContentSize.X * ((Item as THull).HullPoints / (Item as THull).Weight)), ClientSize.Y))
      else SetSize(Classes.Point(Round(GetContentSize.X * (TEquipment(Item).ConditionPercent / 100)), ClientSize.Y));
  end;
end;
{ @end $58240C }

{ @routine $582D24 TfScaner_ShowGoodsInfo }
procedure TfScaner.ShowGoodsInfo(ItemType: TGoodsIndex);
begin
  if HideItemTimer <> 0 then
  begin
    CancelCallbackTimer(HideItemTimer);
    HideItemTimer := 0;
  end;
  GetByName('PII').SetActive(True);
  GetByName('InfoImage2').SetActive(False);
  with GetByName('InfoImage') as TImageGI do
  begin
    SetActive(True);
    SetImagePath('GI,' + GetItemTypeBitmapPath(ItemType));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
  end;
  (GetByName('InfoName') as TLabelGI).SetText(WrapTextInColor(GoodsNames[ItemType], HighlightColorTag));
  (GetByName('InfoText') as TLabelGI).SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(ItemType) + 1)));
  (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(ShipToInspect.CargoGoods[ItemType].Count));
  if Player = ShipToInspect then
    (GetByName('InfoPrice') as TLabelGI).SetText(IntToStr(ShipToInspect.CargoGoods[ItemType].TotalCost))
  else (GetByName('InfoPrice') as TLabelGI).SetText('-');
  with GetByName('EmRace') as TImageGI do
  begin
    SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[ShipToInspect.OwnerId].InternalName));
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  with GetByName('InfoDurable') as TImageGI do SetSize(GetContentSize);
end;
{ @end $582D24 }

{ @routine $5831AC TfScaner_SelectMusic }
procedure TfScaner.SelectMusic;
begin
  if Player = nil then MusicManager.PlayCategory('Base')
  else if MusicInSpace then MusicManager.PlayCategory('StarMap')
  else MusicManager.RequestFadeOut;
end;
{ @end $5831AC }

end.

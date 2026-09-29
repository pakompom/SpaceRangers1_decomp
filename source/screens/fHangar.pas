unit fHangar;
// Unit bracket (inferred): CODE 0x005578CC..0x00559C47; inclusive evidence, not full bounds.
interface
uses fPanelMain, fPanelPlanet, GI_MessageLoop;
type
  TfHangar = class(TMessageLoopGI) // @size $C0
  public
    constructor Create; // @addr $557964
    destructor Destroy; override; // @addr $5579C0
    procedure InitializeLayout; override; // @addr $557A14
    procedure OnOpen; override; // @addr $557C18
    procedure OnClose; override; // @addr $55804C
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $5583C4
    procedure ShipClicked(Sender: TObjectGI); // @addr $558404
    procedure BeginTakeOff; // @addr $558434
    procedure StartRefuelAnimation; // @addr $558458
    procedure StartTakeOffAnimation; // @addr $558538
    procedure RefuelAnimationComplete(Sender: TObjectGI); // @addr $558618
    procedure TakeOffAnimationComplete(Sender: TObjectGI); // @addr $5586F0
    procedure MainKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $5587C4
    procedure SelectMusic; override; // @addr $558924
    procedure RefreshServiceButtons; // @addr $5589C8
    procedure RepairHullClicked(Sender: TObjectGI); // @addr $558AF0
    procedure RefuelClicked(Sender: TObjectGI); // @addr $558D64
    procedure TakeOffClicked(Sender: TObjectGI); // @addr $558F5C
    procedure ServiceMouseEnter(Sender: TObjectGI); // @addr $5590D8
    procedure ServiceMouseLeave(Sender: TObjectGI); // @addr $55941C
    function RefreshTakeOffStatus: Boolean; // @addr $55945C
    MainPanel: TfPanelMain; // @offset $B0
    PlanetPanel: TfPanelPlanet; // @offset $B4
    LeavingHangar: Boolean; // @offset $B8 Suppresses music once takeoff is requested.
    RefuelAnimationRunning: Boolean; // @offset $B9
    TakeOffPending: Boolean; // @offset $BA Waits for the refuel animation before takeoff.
    StatusText: WideString; // @offset $BC

    procedure PrepareTakeoff; // @addr $558074
  end;

implementation

// @unit-initialization $559C40
// @unit-finalization $559C10

uses Windows, SysUtils, GR_Main, Globals, GlobalsV, GI_GraphButton, GI_GAI,
  GI_Image, GI_Label, GI_MessageBox, aConst, aMyFunction, aPlayer, aItem,
  aRanger, aSaveLoad, aCalc, fEquipmentShop, fSaveManager, aGalaxy, aScript, EC_Buf, EC_Str, fStarMap;

{ @routine $557964 TfHangar_Create }
constructor TfHangar.Create;
begin
  inherited Create;
  MainPanel := TfPanelMain.Create;
  PlanetPanel := TfPanelPlanet.Create;
end;
{ @end $557964 }

{ @routine $5579C0 TfHangar_Destroy }
destructor TfHangar.Destroy;
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
{ @end $5579C0 }

{ @routine $557A14 TfHangar_InitializeLayout }
procedure TfHangar.InitializeLayout;
begin
  inherited InitializeLayout;
  MainPanel.InitializeLayout(Self);
  PlanetPanel.InitializeLayout(Self, MainPanel.ShowControlHelp);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  with GetByName('ButRepair') as TGraphButtonGI do
  begin
    UpCallback := RepairHullClicked;
    MouseEnterCallback := ServiceMouseEnter;
    MouseLeaveCallback := ServiceMouseLeave;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  with GetByName('ButRefuel') as TGraphButtonGI do
  begin
    UpCallback := RefuelClicked;
    MouseEnterCallback := ServiceMouseEnter;
    MouseLeaveCallback := ServiceMouseLeave;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
  with GetByName('ButTakeOff') as TGraphButtonGI do
  begin
    UpCallback := TakeOffClicked;
    MouseEnterCallback := ServiceMouseEnter;
    MouseLeaveCallback := ServiceMouseLeave;
    HelpCallback := MainPanel.ShowControlHelp;
  end;
end;
{ @end $557A14 }

{ @routine $557C18 TfHangar_OnOpen }
procedure TfHangar.OnOpen;
var Owner: TOwnerId;
begin
  SelectMusic;
  MainPanel.OnOpen;
  MainPanel.NavigationLocked := False;
  PlanetPanel.OnOpen;
  MainPanel.Show;
  PlanetPanel.Show;
  LeavingHangar := False;
  RefuelAnimationRunning := False;
  TakeOffPending := False;
  GetByName('MainPanel').KeyDownCallback := MainKeyDown;
  for Owner := oiMaloc to oiGaal do
    GetByName('Hangar' + OwnerInfo[Owner].InternalName + 'BG').SetActive(Owner = Player.Hull.OwnerId);
  for Owner := oiMaloc to oiGaal do
  begin
    with GetByName('Hangar' + OwnerInfo[Owner].InternalName + 'L') as TgaiGI do
    begin
      SetActive(False);
      CycleCompleteCallback := nil;
      StopAutoPlayback;
    end;
    with GetByName('Hangar' + OwnerInfo[Owner].InternalName + 'F') as TgaiGI do
    begin
      SetActive(False);
      CycleCompleteCallback := nil;
      StopAutoPlayback;
    end;
  end;
  with GetByName('CaptainI') as TImageGI do
  begin
    SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + 'Dispatcheri');
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetActive(True);
  end;
  with GetByName('CaptainA') as TgaiGI do
  begin
    FirstFrameOnly := not AnimCaptain;
    SetImagePath('Bm.Captain.' + GiResourceSuffix + 'Dispatchera');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
    SetActive(True);
    RestartPlayback;
  end;
  (GetByName('TalkText') as TLabelGI).SetText('');
  GetByName('PanelUp').SetActive(True);
  GetByName('PanelDown').SetActive(True);
  RefreshServiceButtons;
  MainPanel.RebuildMessageButtons;
end;
{ @end $557C18 }

{ @routine $55804C TfHangar_OnClose }
procedure TfHangar.OnClose;
begin
  SoundManager.StopUncontrolledSounds;
  MainPanel.OnClose;
  PlanetPanel.OnClose;
end;
{ @end $55804C }

{ @routine $558074 TfHangar_PrepareTakeoff }
procedure TfHangar.PrepareTakeoff;
var I: Integer; OldFlag: PMoneyIntegrityFlag; FileName: AnsiString;
  Key: WideString; Buffer: TBufEC;
begin
  PruneExpiredPersistentPlayerMessages;
  Player.OrderTakeoff;
  for I := 0 to Galaxy.Scripts.Count - 1 do TScript(Galaxy.Scripts[I]).RunTurnCode;
  StarMapWeaponPanelOpen := False;
  FilmCameraFollow := True;
  PlayerStar.RefreshSpaceObjectPositions;
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  RunStarTransitionScript(Player.CurrentStar, 1);
  OldFlag := PendingMoneyIntegrityFailure;
  PendingMoneyIntegrityFailure := nil;
  New(PendingMoneyIntegrityFailure);
  PendingMoneyIntegrityFailure^ := OldFlag^;
  OldFlag^ := True;
  Dispose(OldFlag);
  if not PendingMoneyIntegrityFailure^ then
  begin
    SetLength(FileName, MAX_PATH);
    if GetModuleFileName(0, PAnsiChar(FileName), MAX_PATH) = 0 then Exit;
    SetLength(FileName, StrLen(PAnsiChar(FileName)));
    PendingMoneyIntegrityFailure^ := Trim(LowerCase(GetCurrentDir)) <>
      Trim(LowerCase(AnsiString(ExtractFileDirW(FileName))));
    if not PendingMoneyIntegrityFailure^ then
    begin
      // Native constructs the executable checksum key one character at a time.
      Key := 'B';
      Key := Key + 'V';
      Key := Key + '.';
      Key := Key + 'E';
      Key := Key + 'C';
      if MainDataConfig.GetParamByPath(Key) <> '' then
      begin
        Buffer := TBufEC.Create;
        Buffer.LoadFromFilePath(PAnsiChar(FileName));
        PendingMoneyIntegrityFailure^ := Trim(LowerCase(AnsiString(CardinalToHexWideString(Buffer.ComputeCrc32)))) <>
          Trim(LowerCase(AnsiString(MainDataConfig.GetParamByPath(Key))));
        Buffer.Free;
      end;
    end;
  end;
  CalculatePlayerStarTurnAndWait;
  StarMapScreen.ResumeMode := 2;
  ScreenLoadMode := 2;
  RestartScreenId := screenStarMap;
  RequestedScreenId := screenLoad;
end;
{ @end $558074 }

{ @routine $5583C4 TfHangar_EndTurnClicked }
procedure TfHangar.EndTurnClicked(Sender: TObjectGI);
begin
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  MainPanel.EndTurnClicked(Sender);
  RefreshServiceButtons;
  MainPanel.RebuildMessageButtons;
  if ExitCode = 0 then BuildTemporaryShopSlotGrid;
end;
{ @end $5583C4 }

{ @routine $558404 TfHangar_ShipClicked }
procedure TfHangar.ShipClicked(Sender: TObjectGI);
begin
  MainPanel.ShipClicked(Sender);
  MainPanel.RebuildMessageButtons;
  MainPanel.RefreshMoneyAndCargo;
  RefreshServiceButtons;
end;
{ @end $558404 }

{ @routine $558434 TfHangar_BeginTakeOff }
procedure TfHangar.BeginTakeOff;
begin
  MainPanel.NavigationLocked := True;
  if AnimHangar then StartTakeOffAnimation
  else TakeOffAnimationComplete(nil);
end;
{ @end $558434 }

{ @routine $558458 TfHangar_StartRefuelAnimation }
procedure TfHangar.StartRefuelAnimation;
begin
  with GetByName('Hangar' + OwnerInfo[Player.Hull.OwnerId].InternalName + 'F') as TgaiGI do
  begin
    SetSequenceFrame(0);
    AutoUpdateFlags := 3;
    UpdateAutoGeometry;
    SetActive(True);
    CycleCompleteCallback := RefuelAnimationComplete;
    RestartPlayback;
  end;
end;
{ @end $558458 }

{ @routine $558538 TfHangar_StartTakeOffAnimation }
procedure TfHangar.StartTakeOffAnimation;
begin
  with GetByName('Hangar' + OwnerInfo[Player.Hull.OwnerId].InternalName + 'L') as TgaiGI do
  begin
    SetSequenceFrame(0);
    AutoUpdateFlags := 3;
    UpdateAutoGeometry;
    SetActive(True);
    CycleCompleteCallback := TakeOffAnimationComplete;
    RestartPlayback;
  end;
end;
{ @end $558538 }

{ @routine $558618 TfHangar_RefuelAnimationComplete }
procedure TfHangar.RefuelAnimationComplete(Sender: TObjectGI);
begin
  with GetByName('Hangar' + OwnerInfo[Player.Hull.OwnerId].InternalName + 'F') as TgaiGI do
  begin
    CycleCompleteCallback := nil;
    SetActive(False);
    StopAutoPlayback;
  end;
  RefuelAnimationRunning := False;
  if TakeOffPending then BeginTakeOff;
end;
{ @end $558618 }

{ @routine $5586F0 TfHangar_TakeOffAnimationComplete }
procedure TfHangar.TakeOffAnimationComplete(Sender: TObjectGI);
begin
  with GetByName('Hangar' + OwnerInfo[Player.Hull.OwnerId].InternalName + 'L') as TgaiGI do
  begin
    CycleCompleteCallback := nil;
    SetActive(False);
    StopAutoPlayback;
  end;
  PrepareTakeoff;
  RequestClose(1);
end;
{ @end $5586F0 }

{ @routine $5587C4 TfHangar_MainKeyDown }
procedure TfHangar.MainKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = VK_SPACE then EndTurnClicked(nil)
  else if Key = Ord('F') then
  begin
    if not (GetByName('ButTakeOff') as TGraphButtonGI).Disabled then TakeOffClicked(nil);
  end
  else if Key = Ord('A') then
  begin
    if not (GetByName('ButRepair') as TGraphButtonGI).Disabled then RepairHullClicked(nil);
  end
  else if Key = Ord('B') then
  begin
    if not (GetByName('ButRefuel') as TGraphButtonGI).Disabled then RefuelClicked(nil);
  end
  else if Key = Ord('S') then ShipClicked(nil)
  else
  begin
    MainPanel.ProcessKeyDown(Key);
    PlanetPanel.ProcessKeyDown(Key);
  end;
end;
{ @end $5587C4 }

{ @routine $558924 TfHangar_SelectMusic }
procedure TfHangar.SelectMusic;
begin
  if LeavingHangar then Exit;
  if not MusicInPlanet then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
end;
{ @end $558924 }

{ @routine $5589C8 TfHangar_RefreshServiceButtons }
procedure TfHangar.RefreshServiceButtons;
begin
  (GetByName('ButRepair') as TGraphButtonGI).SetDisabled(Player.Hull.HullPoints >= Player.Hull.Weight);
  (GetByName('ButRefuel') as TGraphButtonGI).SetDisabled(Player.GetFullRefuelCost <= 0);
  (GetByName('ButTakeOff') as TGraphButtonGI).SetDisabled(not RefreshTakeOffStatus);
  (GetByName('TalkText') as TLabelGI).SetText(StatusText);
  ServiceMouseLeave(nil);
end;
{ @end $5589C8 }

{ @routine $558AF0 TfHangar_RepairHullClicked }
procedure TfHangar.RepairHullClicked(Sender: TObjectGI);
begin
  if MainPanel.NavigationLocked then Exit;
  if Player.Money <= 0 then
  begin
    Player.SetMoney(0);
    ShowMessageBoxGI(Self, FormatText1(LocalizedColorText('FormHangar.HullStatus.NotMoney'),
      HighlightColorTag, '<Money>', IntToStr(Player.Hull.CalculateRepairCost)), mbgCancel);
  end
  else if Player.Money < Player.Hull.CalculateRepairCost then
  begin
    Inc(Player.Hull.HullPoints, Round((Player.Hull.Weight - Player.Hull.HullPoints) *
      (Player.Money / Player.Hull.CalculateRepairCost)));
    Player.SetMoney(0);
    SoundManager.PlaySound('Sound.Repair');
  end
  else
  begin
    Player.SetMoney(Player.Money - Player.Hull.CalculateRepairCost);
    Player.Hull.HullPoints := Player.Hull.Weight;
    SoundManager.PlaySound('Sound.Repair');
  end;
  RefreshServiceButtons;
end;
{ @end $558AF0 }

{ @routine $558D64 TfHangar_RefuelClicked }
procedure TfHangar.RefuelClicked(Sender: TObjectGI);
begin
  if MainPanel.NavigationLocked then Exit;
  if Player.GetFullRefuelCost > Player.Money then
    ShowMessageBoxGI(Self, FormatText1(LocalizedColorText('FormHangar.FuelTankStatus.NotMoney'),
      HighlightColorTag, '<Money>', IntToStr(Player.GetFullRefuelCost)), mbgCancel)
  else
  begin
    Player.SetMoney(Player.Money - Player.GetFullRefuelCost);
    Player.FuelTanks.Fuel := Player.FuelTanks.Capacity;
    Player.RefreshDerivedStats;
    SoundManager.PlaySound('Sound.Sell');
    if AnimHangar then
    begin
      RefuelAnimationRunning := True;
      StartRefuelAnimation;
    end;
  end;
  RefreshServiceButtons;
end;
{ @end $558D64 }

{ @routine $558F5C TfHangar_TakeOffClicked }
procedure TfHangar.TakeOffClicked(Sender: TObjectGI);
begin
  if MainPanel.NavigationLocked then Exit;
  if (TurnCalculationPhase = 1) or (TurnCalculationPhase = 3) then Exit;
  CaptureSavePreview;
  SaveManagerReturnScreenId := FormToId(Self);
  SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
  PlayerAutomaticControl := False;
  (GetByName('ButRepair') as TGraphButtonGI).SetDisabled(True);
  (GetByName('ButRefuel') as TGraphButtonGI).SetDisabled(True);
  (GetByName('ButTakeOff') as TGraphButtonGI).SetDisabled(True);
  LeavingHangar := True;
  MusicManager.RequestFadeOut;
  TakeOffPending := True;
  if not RefuelAnimationRunning then BeginTakeOff;
end;
{ @end $558F5C }

{ @routine $5590D8 TfHangar_ServiceMouseEnter }
procedure TfHangar.ServiceMouseEnter(Sender: TObjectGI);
var Text: WideString;
begin
  Text := '';
  if (Sender.ControlName = 'ButRepair') and not (Sender as TGraphButtonGI).Disabled then
    Text := FormatText1(LocalizedColorText('FormHangar.HullStatus.Cost'), HighlightColorTag, '<Money>', IntToStr(Player.Hull.CalculateRepairCost))
  else if (Sender.ControlName = 'ButRefuel') and not (Sender as TGraphButtonGI).Disabled then
    Text := FormatText1(LocalizedColorText('FormHangar.FuelTankStatus.Cost'), HighlightColorTag, '<Money>', IntToStr(Player.GetFullRefuelCost))
  else if (Sender.ControlName = 'ButTakeOff') and not (Sender as TGraphButtonGI).Disabled then
    Text := FormatText1(LocalizedColorText('FormHangar.TakeOff'), HighlightColorTag, '<CurPlanet>', Player.CurrentPlanet.Name);
  (GetByName('ActionText') as TLabelGI).SetText(Text);
end;
{ @end $5590D8 }

{ @routine $55941C TfHangar_ServiceMouseLeave }
procedure TfHangar.ServiceMouseLeave(Sender: TObjectGI);
begin
  (GetByName('ActionText') as TLabelGI).SetText('');
end;
{ @end $55941C }

{ @routine $55945C TfHangar_RefreshTakeOffStatus }
function TfHangar.RefreshTakeOffStatus: Boolean;
var TotalText: WideString;
begin
  Result := True;
  TotalText := WrapTextInColor(LocalizedColorText('FormHangar.TotalStatus.Good'), GreenColorTag);
  StatusText := LocalizedColorText('FormHangar.TestSystem');
  StatusText := StatusText + #13#10;
  if Player.Hull.HullPoints = Player.Hull.Weight then
    ReplaceTextToken(StatusText, '<HullStatus>', LocalizedColorText('FormHangar.HullStatus.Ok'), '')
  else ReplaceTextToken(StatusText, '<HullStatus>', LocalizedColorText('FormHangar.HullStatus.NeedRepair'), YellowColorTag);
  if Player.FuelTanks = nil then
  begin
    ReplaceTextToken(StatusText, '<FuelTankStatus>', LocalizedColorText('FormHangar.FuelTankStatus.Non'), YellowColorTag);
    TotalText := WrapTextInColor(LocalizedText('FormHangar.TotalStatus.Bad'), YellowColorTag);
    Result := False;
  end
  else if Player.FuelTanks.Fuel = 0 then
  begin
    ReplaceTextToken(StatusText, '<FuelTankStatus>', LocalizedColorText('FormHangar.FuelTankStatus.Empty'), YellowColorTag);
    TotalText := WrapTextInColor(LocalizedText('FormHangar.TotalStatus.Bad'), YellowColorTag);
    Result := False;
  end
  else if Player.FuelTanks.BrokenFlag then
    ReplaceTextToken(StatusText, '<FuelTankStatus>', LocalizedColorText('FormHangar.FuelTankStatus.NeedRepair'), YellowColorTag)
  else if Player.FuelTanks.Fuel < Player.FuelTanks.Capacity then
    ReplaceTextToken(StatusText, '<FuelTankStatus>', LocalizedColorText('FormHangar.FuelTankStatus.NeedFuel'), YellowColorTag)
  else ReplaceTextToken(StatusText, '<FuelTankStatus>', LocalizedColorText('FormHangar.FuelTankStatus.Ok'), '');
  if Player.Engine = nil then
  begin
    ReplaceTextToken(StatusText, '<EngineStatus>', LocalizedColorText('FormHangar.EngineStatus.Non'), YellowColorTag);
    TotalText := WrapTextInColor(LocalizedColorText('FormHangar.TotalStatus.Bad'), YellowColorTag);
    Result := False;
  end
  else
  begin
    if Player.Engine.BrokenFlag then
      ReplaceTextToken(StatusText, '<EngineStatus>', LocalizedColorText('FormHangar.EngineStatus.NeedRepair'), YellowColorTag)
    else ReplaceTextToken(StatusText, '<EngineStatus>', LocalizedColorText('FormHangar.EngineStatus.Ok'), '');
    if Player.CargoFreeSpace < 0 then
    begin
      TotalText := WrapTextInColor(LocalizedColorText('FormHangar.TotalStatus.ShipOvercharging'), YellowColorTag);
      Result := False;
    end;
  end;
  ReplaceTextToken(StatusText, '<TotalStatus>', TotalText, '');
end;
{ @end $55945C }

end.

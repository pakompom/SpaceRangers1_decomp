unit fMainForm;
// Unit bracket (inferred): CODE 0x0055E224..0x0055FC43; inclusive evidence, not full bounds.
// Main menu.
interface
uses GI_MessageLoop, Types;
type
  TfMainForm = class(TMessageLoopGI) // @size $C0
  public
    DemoTimer: TCallbackTimerIdGI; // @offset $B0
    BackgroundTimer: TCallbackTimerIdGI; // @offset $B4
    DeveloperKeySequence: WideString; // @offset $B8
    SelectedQuestControl: TObjectGI; // @offset $BC
    procedure OnOpen; override; // @addr $55E2C0
    procedure OnClose; override; // @addr $55EA04
    procedure QuitClicked(Sender: TObjectGI); // @addr $55EA48
    procedure NewGameClicked(Sender: TObjectGI); // @addr $55EAE8
    procedure LoadGameClicked(Sender: TObjectGI); // @addr $55EAFC
    procedure SettingsClicked(Sender: TObjectGI); // @addr $55EB50
    procedure ScoresClicked(Sender: TObjectGI); // @addr $55EB9C
    procedure AboutClicked(Sender: TObjectGI); // @addr $55EBC0
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $55EBD4
    function HasDemoEntries: Boolean; // @addr $55EE90
    procedure DemoTimerTick(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $55EF00
    procedure MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55F064
    procedure ScrollBackground(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $55F0BC
    procedure ClosePopup; // @addr $55F114
    procedure QuestMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55FADC
    procedure QuestDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55FB64
    procedure AcceptQuest(Sender: TObjectGI); // @addr $55FB84
    procedure CancelQuest(Sender: TObjectGI); // @addr $55FBDC
    procedure SelectMusic; override; // @addr $55FBE8
    procedure OpenPopup; // @addr $55F208
  end;
implementation
// @unit-initialization $55FC3C
// @unit-finalization $55FC0C
uses Classes, SysUtils, Windows, GR_Main, Globals, GlobalsV, aGalaxy, EC_Str, GI_Image, GI_GAI, GI_Label, GI_GraphButton, GI_MessageBox, EC_BlockPar, GI_Panel, GI_PanelScrollBar, GI_ShrLight, GI_Main, GR_Music, GR_Demo, aMyFunction;

{ @routine $55E2C0 TfMainForm_OnOpen }
procedure TfMainForm.OnOpen;
var I: Integer; Text: WideString; Logo1, Logo2: TImageGI;
begin
  (GetByName('Title') as TImageGI).SetImagePath('Bm.' + GiResourceSuffix + 'Title' + CurrentLanguage);
  DeveloperKeySequence := '';
  GetByName('Dev0').SetActive(False);
  GetByName('Dev1').SetActive(False);
  GetByName('Dev2').SetActive(False);
  if Galaxy <> nil then begin Galaxy.Free; Galaxy := nil; end;
  I := 0;
  while FindControlByPath('TempGAI' + IntToStr(I)) <> nil do begin
    (GetByName('TempGAI' + IntToStr(I)) as TgaiGI).RestartPlayback;
    Inc(I);
  end;
  GetByName('MainPanel').MouseMoveCallback := MainPanelMouseMove;
  (GetByName('Exit') as TGraphButtonGI).UpCallback := QuitClicked;
  (GetByName('New') as TGraphButtonGI).UpCallback := NewGameClicked;
  (GetByName('Load') as TGraphButtonGI).UpCallback := LoadGameClicked;
  (GetByName('Settings') as TGraphButtonGI).UpCallback := SettingsClicked;
  (GetByName('Score') as TGraphButtonGI).UpCallback := ScoresClicked;
  (GetByName('About') as TGraphButtonGI).UpCallback := AboutClicked;
  SelectMusic;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  if DemoTimer <> 0 then begin CancelCallbackTimer(DemoTimer); DemoTimer := 0; end;
  DemoTimer := ScheduleCallbackTimer(30000, 999999, DemoTimerTick);
  if BackgroundTimer <> 0 then begin CancelCallbackTimer(BackgroundTimer); BackgroundTimer := 0; end;
  BackgroundTimer := ScheduleCallbackTimer(20, 20, ScrollBackground);
  (GetByName('Anim0') as TgaiGI).RestartPlayback;
  with GetByName('LVersion') as TLabelGI do
    if InstallConfig.CountParams('Version') > 0 then SetText('v' + InstallConfig.GetParam('Version'))
    else SetText('');
  if InstallConfig.CountParams('Logo') > 0 then begin
    Text := InstallConfig.GetParam('Logo');
    if CountDelimitedPartsW(Text, ',') >= 3 then begin
      Text := TrimWideString(ExtractDelimitedPartW(Text, 2, ',.'));
      if FileExists('data\' + GiResourceSuffix + Text + 'Logo.gi') then begin
        Logo1 := GetByName('Logo1') as TImageGI;
        Logo2 := GetByName('Logo2') as TImageGI;
        with GetByName('Logo3') as TImageGI do begin
        SetImagePath('GI,Bm.' + GiResourceSuffix + LowerCase(Text) + 'Logo');
        SetSize(GetContentSize);
        SetPosition(Classes.Point(Logo2.LocalPosition.X - ClientSize.X -
          (Logo1.LocalPosition.X - (Logo2.LocalPosition.X + Logo2.ClientSize.X)),
          Logo2.LocalPosition.Y + Logo2.ClientSize.Y div 2 - ClientSize.Y div 2));
        SetActive(True);
        end;
      end;
    end;
  end;
  ClosePopup;
end;
{ @end $55E2C0 }

{ @routine $55EA04 TfMainForm_OnClose }
procedure TfMainForm.OnClose;
begin
  ClosePopup;
  if DemoTimer <> 0 then begin CancelCallbackTimer(DemoTimer); DemoTimer := 0; end;
  if BackgroundTimer <> 0 then begin CancelCallbackTimer(BackgroundTimer); BackgroundTimer := 0; end;
end;
{ @end $55EA04 }

{ @routine $55EA48 TfMainForm_QuitClicked }
procedure TfMainForm.QuitClicked(Sender: TObjectGI);
begin
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormMain.MsgExit'), mbgOK or mbgCancel) = mbgResultOK then begin
    RequestedScreenId := screenNone;
    RequestClose(1);
  end;
end;
{ @end $55EA48 }

{ @routine $55EAE8 TfMainForm_NewGameClicked }
procedure TfMainForm.NewGameClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenNewGame;
  RequestClose(1);
end;
{ @end $55EAE8 }

{ @routine $55EAFC TfMainForm_LoadGameClicked }
procedure TfMainForm.LoadGameClicked(Sender: TObjectGI);
begin
  SetCursorActive(False);
  Present;
  CaptureScreenBackground;
  CaptureSavePreview;
  SetCursorActive(True);
  SaveManagerReturnScreenId := FormToId(Self);
  SaveManagerMode := smmLoad;
  RequestedScreenId := screenSaveManager;
  RequestClose(1);
end;
{ @end $55EAFC }

{ @routine $55EB50 TfMainForm_SettingsClicked }
procedure TfMainForm.SettingsClicked(Sender: TObjectGI);
begin
  SetCursorActive(False);
  Present;
  CaptureScreenBackground;
  CaptureSavePreview;
  SetCursorActive(True);
  SettingsReturnScreenId := FormToId(Self);
  RequestedScreenId := screenSettings;
  RequestClose(1);
end;
{ @end $55EB50 }

{ @routine $55EB9C TfMainForm_ScoresClicked }
procedure TfMainForm.ScoresClicked(Sender: TObjectGI);
begin
  ScoreScreen.ReturnToEndScreen := False;
  RequestedScreenId := screenScores;
  RequestClose(1);
end;
{ @end $55EB9C }

{ @routine $55EBC0 TfMainForm_AboutClicked }
procedure TfMainForm.AboutClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenAbout;
  RequestClose(1);
end;
{ @end $55EBC0 }

{ @routine $55EBD4 TfMainForm_MainPanelKeyDown }
procedure TfMainForm.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) and IsVirtualKeyDown(VK_SHIFT) then begin
    DeveloperKeySequence := DeveloperKeySequence + WideChar(Key);
    if FindTextOffsetW(DeveloperKeySequence, 'DIMKA', 0) >= 0 then begin
      DeveloperKeySequence := '';
      GetByName('Dev0').SetActive(not GetByName('Dev0').Active);
    end else if FindTextOffsetW(DeveloperKeySequence, 'DAB', 0) >= 0 then begin
      DeveloperKeySequence := '';
      GetByName('Dev1').SetActive(not GetByName('Dev1').Active);
    end else if FindTextOffsetW(DeveloperKeySequence, 'ALEXART', 0) >= 0 then begin
      DeveloperKeySequence := '';
      GetByName('Dev2').SetActive(not GetByName('Dev2').Active);
    end;
  end;
  if Key = Ord('Q') then
    if FindControlByPath('PanelQL') = nil then OpenPopup else ClosePopup;
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then begin
    if (Key = VK_F3) or (Key = Ord('L')) then begin
      SaveManagerReturnScreenId := FormToId(Self);
      SaveManagerMode := smmLoad;
      RequestedScreenId := screenSaveManager;
      RequestClose(1);
    end else if Key = Ord('A') then begin
      RequestedScreenId := screenArcadeBattle;
      RequestClose(1);
    end else if Key = VK_ESCAPE then begin
      if FindControlByPath('PanelQL') <> nil then ClosePopup else QuitClicked(nil);
    end else if (Key = Ord('N')) or (Key = VK_RETURN) then NewGameClicked(nil)
    else if Key = Ord('C') then SettingsClicked(nil);
  end;
end;
{ @end $55EBD4 }

{ @routine $55EE90 TfMainForm_HasDemoEntries }
function TfMainForm.HasDemoEntries: Boolean;
begin
  Result := LanguageDataConfig.CountParams(GiResourceSuffix + 'Demo') > 0;
end;
{ @end $55EE90 }

{ @routine $55EF00 TfMainForm_DemoTimerTick }
procedure TfMainForm.DemoTimerTick(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if DemoTimer = 0 then Exit;
  CancelCallbackTimer(DemoTimer);
  DemoTimer := 0;
  Exit;
  if HasDemoEntries then;
  Demo.LoadTextFile(LanguageDataConfig.GetParamByPath(GiResourceSuffix + 'Demo:' +
    IntToStr(RandomIntRange(0, LanguageDataConfig.CountParams(GiResourceSuffix + 'Demo') - 1))));
  if Demo.PeekKind = dekGameLoad then
  begin
    DemoRecording := False;
    DemoPlaying := True;
    DemoLastEventTick := 0;
    RequestedScreenId := screenNone;
    RequestClose(1);
  end;
end;
{ @end $55EF00 }

{ @routine $55F064 TfMainForm_MainPanelMouseMove }
procedure TfMainForm.MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if DemoTimer <> 0 then begin CancelCallbackTimer(DemoTimer); DemoTimer := 0; end;
  DemoTimer := ScheduleCallbackTimer(30000, 999999, DemoTimerTick);
end;
{ @end $55F064 }
{ @routine $55F0BC TfMainForm_ScrollBackground }
procedure TfMainForm.ScrollBackground(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Background: TObjectGI; X: Integer;
begin
  Background := GetByName('Fon');
  with Background do begin
    X := LocalPosition.X - 1;
    if X < -ClientSize.X div 2 then X := X + ClientSize.X div 2;
    SetPosition(Classes.Point(X, LocalPosition.Y));
  end;
end;
{ @end $55F0BC }

{ @routine $55F114 TfMainForm_ClosePopup }
procedure TfMainForm.ClosePopup;
begin
  SelectedQuestControl := nil;
  if FindControlByPath('PanelQL') <> nil then with FindControlByPath('PanelQL') do begin
    Invalidate;
    Free;
  end;
end;
{ @end $55F114 }

{ @routine $55F208 TfMainForm_OpenPopup }
procedure TfMainForm.OpenPopup;
var
  Overlay, Row: TPanelGI;
  List: TPanelScrollBarGI;
  Count, Y: Integer;
  QuestName: WideString;
  Order: array of Integer;
  Quests: TBlockParEC;
  I, J, Temp: Integer;
  LabelControl: TLabelGI;
  // @nested $55F188 CompareQuestIds
  function CompareQuestIds(const Left, Right: WideString): Integer; // @addr $55F188
  var LeftNumeric, RightNumeric: Boolean; A, B: Integer;
  begin
    LeftNumeric := IsIntegerTextW(Left);
    RightNumeric := IsIntegerTextW(Right);
    if (LeftNumeric <> RightNumeric) and RightNumeric then begin Result := -1; Exit; end;
    if (LeftNumeric <> RightNumeric) and LeftNumeric then begin Result := 1; Exit; end;
    if not LeftNumeric then Result := CompareWideChars(PWideChar(Left), PWideChar(Right))
    else begin
      A := ExtractDigitsToIntW(Left);
      B := ExtractDigitsToIntW(Right);
      if A < B then Result := -1
      else if A > B then Result := 1
      else Result := 0;
    end;
  end;
begin
  ClosePopup;
  Overlay := TPanelGI.Create(GetByName('MainPanel'));
  Overlay.SetName('PanelQL');
  Overlay.SetPosition(Classes.Point(0, 0));
  Overlay.SetDepth(-100);
  Overlay.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  Overlay.MouseBlocking := True;
  with TShrLightGI.Create(Overlay) do begin
    SetPosition(Classes.Point(0, 0));
    SetDepth(10);
    SetSize(Overlay.ClientSize);
    SetLightShift(2);
  end;
  List := TPanelScrollBarGI.Create(Overlay);
  List.SetPosition(Classes.Point(GiScalePixels(400), GiScalePixels(100)));
  List.SetDepth(9);
  List.SetSize(Classes.Point(Overlay.ClientSize.X - GiScalePixels(800), Overlay.ClientSize.Y - GiScalePixels(200)));
  List.SetUnlimitedWorldEnabled(False);
  List.SetScrollbarsOutside(True);
  List.SetVerticalScrollBarConfigPath('Style.ScrollBar.' + GiResourceSuffix + 'V0');
  List.SetHorizontalScrollbarEnabled(False);
  List.SetVerticalScrollbarEnabled(True);
  Y := 0;
  Quests := LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest');
  Count := Quests.GetParamCount;
  SetLength(Order, Count);
  for I := 0 to Count - 1 do Order[I] := I;
  for I := 0 to Count - 2 do
    for J := I + 1 to Count - 1 do
      if CompareQuestIds(Quests.GetParamName(Order[I]), Quests.GetParamName(Order[J])) > 0 then begin
        Temp := Order[I];
        Order[I] := Order[J];
        Order[J] := Temp;
      end;
  for I := 0 to Count - 1 do begin
    QuestName := ExtractFileNameNoExtW(Quests.GetParamValue(Order[I]));
    Row := TPanelGI.Create(List);
    Row.SetPositionModeW(True);
    Row.SetPosition(Classes.Point(0, Y));
    Row.SetSize(Classes.Point(List.ClientSize.X, GiScalePixels(30)));
    LabelControl := TLabelGI.Create(Row);
    LabelControl.SetPosition(Classes.Point(0, 0));
    LabelControl.SetTextAlignX(taxLeft);
    LabelControl.SetTextAlignY(tayCenterEx);
    LabelControl.SetWordWrapEnabled(False);
    LabelControl.SetSize(Row.ClientSize);
    LabelControl.SetFontName(HitPointFontName);
    if (QuestDisplayNames <> nil) and (QuestDisplayNames.CountParams(QuestName) > 0) then
      LabelControl.SetText(ExtractFileNameNoExtW(QuestDisplayNames.GetParam(QuestName)))
    else LabelControl.SetText(QuestName);
    LabelControl.HelpText := TrimWideString(Quests.GetParamName(Order[I]));
    if TestQuestPath = LabelControl.HelpText then begin
      SelectedQuestControl := LabelControl;
      LabelControl.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 0));
    end;
    LabelControl.LeftButtonDownCallback := QuestMouseDown;
    LabelControl.LeftButtonDoubleClickCallback := QuestDoubleClick;
    Inc(Y, Row.ClientSize.Y);
  end;
  Order := nil;
  List.UpdateScrollbarPlacement;
  List.UpdateScrollRanges;
  List.VerticalScrollBar.SetSmallChange(GiScalePixels(30));
  List.VerticalScrollBar.SetLargeChange(List.ClientSize.Y);
  List.VerticalScrollBar.SetPageSize(List.ClientSize.Y);
  if SelectedQuestControl <> nil then List.ScrollRectIntoView(SelectedQuestControl.Parent.GetLocalBounds);
  with TGraphButtonGI.Create(Overlay) do begin
    UpOnlyDown := True;
    SetDepth(8);
    SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkN');
    SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkA');
    SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkD');
    SetSize(GetMaxStateImageSize);
    SetPosition(Classes.Point(List.LocalPosition.X + List.ClientSize.X - GiScalePixels(70),
      List.LocalPosition.Y + List.ClientSize.Y + 10));
    HitKind := gbhRect;
    UpdateStateImagePlacement;
    UpdateStateVisuals;
    UpCallback := AcceptQuest;
  end;
  with TGraphButtonGI.Create(Overlay) do begin
    UpOnlyDown := True;
    SetDepth(8);
    SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelN');
    SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelA');
    SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelD');
    SetSize(GetMaxStateImageSize);
    SetPosition(Classes.Point(List.LocalPosition.X + List.ClientSize.X - GiScalePixels(10),
      List.LocalPosition.Y + List.ClientSize.Y + 10));
    HitKind := gbhRect;
    UpdateStateImagePlacement;
    UpdateStateVisuals;
    UpCallback := CancelQuest;
  end;
end;
{ @end $55F208 }

{ @routine $55FADC TfMainForm_QuestMouseDown }
procedure TfMainForm.QuestMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if SelectedQuestControl <> nil then begin
    (SelectedQuestControl as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
    SelectedQuestControl := nil;
  end;
  SelectedQuestControl := Sender;
  (SelectedQuestControl as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 0));
end;
{ @end $55FADC }

{ @routine $55FB64 TfMainForm_QuestDoubleClick }
procedure TfMainForm.QuestDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  AcceptQuest(nil);
end;
{ @end $55FB64 }

{ @routine $55FB84 TfMainForm_AcceptQuest }
procedure TfMainForm.AcceptQuest(Sender: TObjectGI);
begin
  if SelectedQuestControl <> nil then begin
    TestQuestPath := SelectedQuestControl.HelpText;
    ClosePopup;
    StandaloneQuestMode := True;
    PlanetQuestReturnScreenId := FormToId(Self);
    RequestedScreenId := screenPlanetQuest;
    RequestClose(1);
    BreakUiMessage;
  end;
end;
{ @end $55FB84 }

{ @routine $55FBDC TfMainForm_CancelQuest }
procedure TfMainForm.CancelQuest(Sender: TObjectGI);
begin
  ClosePopup;
  BreakUiMessage;
end;
{ @end $55FBDC }

{ @routine $55FBE8 TfMainForm_SelectMusic }
procedure TfMainForm.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;
{ @end $55FBE8 }

end.

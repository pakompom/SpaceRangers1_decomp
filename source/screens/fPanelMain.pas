unit fPanelMain;
// Unit bracket (inferred): CODE 0x00602DA8..0x00604D33; inclusive evidence, not full bounds.
interface
uses EC_Struct, GI_MessageLoop, GI_Label, GI_GraphButton, GI_Panel, GI_Image, Types;
type
  TfPanelMain = class(TObjectEx) // @size $40
  public
    Screen: TMessageLoopGI; // @offset $04 Initialized by InitializeLayout.
    StatusTimer: TCallbackTimerIdGI; // @offset $08
    MessagePulseTimer: TCallbackTimerIdGI; // @offset $0C
    MessageSlideTimer: TCallbackTimerIdGI; // @offset $10
    HelpLabel: TLabelGI; // @offset $14
    LastMessageTargetId: Cardinal; // @offset $18 Cycles through a clicked message's three ship IDs; cleared by OnOpen.
    MessagePanel: TPanelGI; // @offset $1C
    BackgroundImage: TImageGI; // @offset $20
    ShipButton: TGraphButtonGI; // @offset $24
    GalaxyButton: TGraphButtonGI; // @offset $28
    QuestButton: TGraphButtonGI; // @offset $2C
    NavigationLocked: Boolean; // @offset $30 Cleared by Create; blocks ShipClicked, QuestClicked, GalaxyClicked and MenuClicked.
    MessagePulseStep: Integer; // @offset $34
    MessageSlideDirection: Integer; // @offset $38
    MessagePanelRestTop: Integer; // @offset $3C Captured from MessagePanel.LocalPosition.Y.
    constructor Create; // @addr $602E00
    destructor Destroy; override; // @addr $602E3C
    procedure InitializeLayout(Screen: TMessageLoopGI); // @addr $602E64
    procedure ProcessKeyDown(Key: Cardinal); // @addr $604BE8
    procedure OnOpen; // @addr $60315C
    procedure OnClose; // @addr $60321C
    procedure Show; // @addr $603264
    procedure Hide; // @addr $6032C4
    procedure RefreshMoneyAndCargo; // @addr $6032F8
    procedure RefreshEndTurnButton; // @addr $6039F8
    procedure DisableNavigationButtons; // @addr $603A5C
    procedure EnableNavigationButtons; // @addr $603B64
    procedure ClearMessageButtons; // @addr $6040BC
    procedure SlideMessagesIn; // @addr $604724
    procedure SlideMessagesOut; // @addr $604770
    procedure AdvanceMessageSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $6047C4
    procedure ShowControlHelp(Sender: TObjectGI; Visible: Boolean); // @addr $604BA0
    procedure RefreshStatusTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $603764
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $603508
    procedure ShipClicked(Sender: TObjectGI); // @addr $60360C
    procedure QuestClicked(Sender: TObjectGI); // @addr $603694
    procedure GalaxyClicked(Sender: TObjectGI); // @addr $6036C8
    procedure MenuClicked(Sender: TObjectGI); // @addr $60370C
    procedure RebuildMessageButtons; // @addr $603C6C
    procedure PulseUnreadMessages(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $60376C
    procedure MessageMouseEnter(Sender: TObjectGI); // @addr $60414C
    procedure MessageMouseLeave(Sender: TObjectGI); // @addr $6042FC
    procedure AdvanceMessageDeletion(Sender: TObjectGI); // @addr $604500
    procedure FinishMessageDeletion(Sender: TObjectGI); // @addr $6046A0
    procedure DeleteMessage(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $604330
    procedure MessageClicked(Sender: TObjectGI); // @addr $604860
    procedure PlayUnreadMessageSounds; // @addr $604B34
  end;
implementation
// @unit-initialization $604D2C
// @unit-finalization $604CFC

uses Classes, GR_Main, aGalaxy, aPlayer, aMyFunction, SysUtils, aCalc, Globals, GR_gi, GI_Window, GlobalsV, Windows, GI_GAI, fShip2, fRating, fGalaxy2,
  fStarMap, fSaveManager, aShip, aPlanet, aEFilm;

{ @routine $602E00 TfPanelMain_Create }
constructor TfPanelMain.Create;
begin
  inherited Create;
  NavigationLocked := False;
end;
{ @end $602E00 }

{ @routine $602E3C TfPanelMain_Destroy }
destructor TfPanelMain.Destroy;
begin
  inherited Destroy;
end;
{ @end $602E3C }

{ @routine $602E64 TfPanelMain_InitializeLayout }
procedure TfPanelMain.InitializeLayout(Screen: TMessageLoopGI);
begin
  Self.Screen := Screen;
  MessagePanel := Self.Screen.GetByName('PM_PanelMsg') as TPanelGI;
  MessagePanelRestTop := MessagePanel.LocalPosition.Y;
  HelpLabel := Self.Screen.GetByName('PM_Help') as TLabelGI;
  BackgroundImage := Self.Screen.GetByName('PM_ImageBG') as TImageGI;
  ShipButton := Self.Screen.GetByName('PM_Ship') as TGraphButtonGI;
  GalaxyButton := Self.Screen.GetByName('PM_Gal') as TGraphButtonGI;
  QuestButton := Self.Screen.GetByName('PM_Quest') as TGraphButtonGI;
  (Self.Screen.GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  ShipButton.UpCallback := ShipClicked;
  QuestButton.UpCallback := QuestClicked;
  GalaxyButton.UpCallback := GalaxyClicked;
  (Self.Screen.GetByName('PM_Logo') as TGraphButtonGI).UpCallback := MenuClicked;
  (Self.Screen.GetByName('PM_EndTurn') as TGraphButtonGI).HelpCallback := ShowControlHelp;
  ShipButton.HelpCallback := ShowControlHelp;
  QuestButton.HelpCallback := ShowControlHelp;
  GalaxyButton.HelpCallback := ShowControlHelp;
  (Self.Screen.GetByName('PM_Logo') as TGraphButtonGI).HelpCallback := ShowControlHelp;
  Self.Screen.GetByName('PM_Date').HelpCallback := ShowControlHelp;
  Self.Screen.GetByName('PM_FreeSpace').HelpCallback := ShowControlHelp;
  Self.Screen.GetByName('PM_Money').HelpCallback := ShowControlHelp;
end;
{ @end $602E64 }

{ @routine $60315C TfPanelMain_OnOpen }
procedure TfPanelMain.OnOpen;
begin
  if MessageSlideTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessageSlideTimer);
    MessageSlideTimer := 0;
  end;
  if MessagePulseTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessagePulseTimer);
    MessagePulseTimer := 0;
  end;
  if StatusTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(StatusTimer);
    StatusTimer := 0;
  end;
  StatusTimer := Screen.ScheduleCallbackTimer(200, 200, RefreshStatusTimer);
  MessagePanel.SetPosition(Classes.Point(MessagePanel.LocalPosition.X, MessagePanelRestTop));
  Screen.GetByName('PM_Help').SetActive(False);
  EnableNavigationButtons;
  LastMessageTargetId := 0;
  RefreshMoneyAndCargo;
end;
{ @end $60315C }

{ @routine $60321C TfPanelMain_OnClose }
procedure TfPanelMain.OnClose;
begin
  if StatusTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(StatusTimer);
    StatusTimer := 0;
  end;
  if MessagePulseTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessagePulseTimer);
    MessagePulseTimer := 0;
  end;
  if MessageSlideTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessageSlideTimer);
    MessageSlideTimer := 0;
  end;
end;
{ @end $60321C }

{ @routine $603264 TfPanelMain_Show }
procedure TfPanelMain.Show;
begin
  Screen.GetByName('PanelMain').SetActive(True);
  Screen.GetByName('PM_Help').SetActive(False);
  EnableNavigationButtons;
end;
{ @end $603264 }

{ @routine $6032C4 TfPanelMain_Hide }
procedure TfPanelMain.Hide;
begin
  Screen.GetByName('PanelMain').SetActive(False);
end;
{ @end $6032C4 }

{ @routine $6032F8 TfPanelMain_RefreshMoneyAndCargo }
procedure TfPanelMain.RefreshMoneyAndCargo;
var ColorTag: WideString;
begin
  (Screen.GetByName('PM_Date') as TLabelGI).SetText(Galaxy.FormatTurnDate(Galaxy.CurrentTurn));
  if Player <> nil then
  begin
    (Screen.GetByName('PM_Money') as TLabelGI).SetText(IntToStr(Player.Money));
    if Player.GetCargoFreeSpace < 0 then ColorTag := RedColorTag else ColorTag := '';
    (Screen.GetByName('PM_FreeSpace') as TLabelGI).SetText(WrapTextInColor(IntToStr(Player.GetCargoFreeSpace), ColorTag));
  end
  else
  begin
    (Screen.GetByName('PM_Money') as TLabelGI).SetText('');
    (Screen.GetByName('PM_FreeSpace') as TLabelGI).SetText('');
  end;
end;
{ @end $6032F8 }

{ @routine $603508 TfPanelMain_EndTurnClicked }
procedure TfPanelMain.EndTurnClicked(Sender: TObjectGI);
begin
  if NavigationLocked then Exit;
  if Player = nil then Exit;
  if (Player.CurrentPlanet <> nil) and (Player.CurrentPlanet.OwnerId = oiKling) then Exit;
  if (Player <> nil) and (Player.CurrentPlanet <> nil) and
    (Player.CurrentPlanet.GetRelationLevelToShip(Player) = rlHostile) then begin
    if GovernmentScreen <> Screen then begin
      RequestedScreenId := screenGovernment;
      Screen.RequestClose(1);
    end;
    Exit;
  end;
  if not IsTurnCalculationRunningUI then begin
    SoundManager.PlaySound('Sound.Turn');
    PruneExpiredPersistentPlayerMessages;
    CalculatePlayerStarTurnAndWait;
    if Player <> nil then begin
      QueueGalaxyTurnCalculation;
      RefreshEndTurnButton;
    end;
  end;
  if (Player = nil) or ((Player.CurrentPlanet <> nil) and (Player.CurrentPlanet.OwnerId = oiKling)) then begin
    GameEndReason := 2;
    RequestedScreenId := screenGameEnd;
    Screen.RequestClose(1);
  end;
end;
{ @end $603508 }

{ @routine $60360C TfPanelMain_ShipClicked }
procedure TfPanelMain.ShipClicked(Sender: TObjectGI);
var RefreshDialog: Boolean;
begin
  if NavigationLocked then Exit;
  Screen.SetCursorActive(False);
  Screen.Present;
  CaptureScreenBackground;
  Screen.SetCursorActive(True);
  RefreshDialog := False;
  ShipScreen.PlayTransitionSounds := True;
  while True do begin
    RunShipEquipment(Screen);
    if ShipScreen.RefreshStationDialog then RefreshDialog := True;
    RefreshMoneyAndCargo;
    RebuildMessageButtons;
    if not ShipScreen.SkipOpeningSlide then Break;
    Screen.DrawQueuedUpdateRects;
    CaptureScreenBackground;
  end;
  ShipScreen.RefreshStationDialog := RefreshDialog;
end;
{ @end $60360C }

{ @routine $603694 TfPanelMain_QuestClicked }
procedure TfPanelMain.QuestClicked(Sender: TObjectGI);
begin
  if NavigationLocked then Exit;
  Screen.SetCursorActive(False);
  Screen.Present;
  CaptureScreenBackground;
  Screen.SetCursorActive(True);
  ShowRangerRating(Screen);
end;
{ @end $603694 }

{ @routine $6036C8 TfPanelMain_GalaxyClicked }
procedure TfPanelMain.GalaxyClicked(Sender: TObjectGI);
begin
  if NavigationLocked then Exit;
  Screen.SetCursorActive(False);
  Screen.Present;
  CaptureScreenBackground;
  Screen.SetCursorActive(True);
  GalaxyMapScreen.ViewMode := 1;
  RunGalaxyMap(Screen);
end;
{ @end $6036C8 }

{ @routine $60370C TfPanelMain_MenuClicked }
procedure TfPanelMain.MenuClicked(Sender: TObjectGI);
begin
  if NavigationLocked then Exit;
  Screen.SetCursorActive(False);
  Screen.Present;
  CaptureScreenBackground;
  CaptureSavePreview;
  Screen.SetCursorActive(True);
  GameMenuReturnScreenId := FormToId(Screen);
  RequestedScreenId := screenGameMenu;
  Screen.RequestClose(1);
end;
{ @end $60370C }

{ @routine $603764 TfPanelMain_RefreshStatusTimer }
procedure TfPanelMain.RefreshStatusTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  RefreshEndTurnButton;
end;
{ @end $603764 }

{ @routine $60376C TfPanelMain_PulseUnreadMessages }
procedure TfPanelMain.PulseUnreadMessages(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Control: TObjectGI;
  Finished: Boolean;
  MessageEntry: TMessagePlayer;
  Alpha: Byte;
begin
  Inc(MessagePulseStep);
  Finished := True;
  if MessagePanel.Active = True then
  begin
    MessagePulseStep := MessagePulseStep mod 32;
    if MessagePulseStep < 16 then Alpha := 255 - MessagePulseStep * 8
    else Alpha := 127 + (MessagePulseStep - 16) * 8;
    Control := MessagePanel.FirstChild;
    while Control <> nil do
    begin
      MessageEntry := TMessagePlayer(Control.UserValue);
      if Control is TGraphButtonGI then
      begin
        if (MessageEntry.Kind in [pmGalaxy, pmTips]) and not MessageEntry.WasRead then
        begin
          with Control as TGraphButtonGI do
          begin
            LoadGiByPathIntoGraphBuf('Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].NormalImage,
              ImageNormal.GraphBufControl.GraphBuf);
            ImageNormal.GraphBufControl.GraphBuf.ScaleAlpha(Classes.Rect(0, 0,
              ImageNormal.GraphBufControl.GraphBuf.Width, ImageNormal.GraphBufControl.GraphBuf.Height), Alpha);
            Finished := False;
            Invalidate;
          end;
        end
        else if ((Control as TGraphButtonGI).ImageNormal <> nil) and
          ((Control as TGraphButtonGI).ImageNormal.GraphBufControl <> nil) then
        begin
          (Control as TGraphButtonGI).ImageNormal.SetImagePath('GI,Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].NormalImage);
          (Control as TGraphButtonGI).Invalidate;
        end;
      end;
      Control := Control.NextSibling;
    end;
  end;
  if Finished then
  begin
    if MessagePulseTimer <> 0 then
    begin
      Screen.CancelCallbackTimer(MessagePulseTimer);
      MessagePulseTimer := 0;
    end;
  end;
end;
{ @end $60376C }

{ @routine $6039F8 TfPanelMain_RefreshEndTurnButton }
procedure TfPanelMain.RefreshEndTurnButton;
var Button: TGraphButtonGI;
begin
  Button := Screen.GetByName('PM_EndTurn') as TGraphButtonGI;
  if IsTurnCalculationRunningUI then Button.SetDisabled(True)
  else Button.SetDisabled(False);
  RefreshMoneyAndCargo;
end;
{ @end $6039F8 }

{ @routine $603A5C TfPanelMain_DisableNavigationButtons }
procedure TfPanelMain.DisableNavigationButtons;
begin
  Screen.GetByName('PM_Ship').SetActive(False);
  Screen.GetByName('PM_Gal').SetActive(False);
  Screen.GetByName('PM_Quest').SetActive(False);
  Screen.GetByName('PM_EndTurn').SetActive(False);
  Screen.GetByName('PM_Break').SetActive(True);
  Screen.GetByName('PM_Logo').SetActive(False);
end;
{ @end $603A5C }

{ @routine $603B64 TfPanelMain_EnableNavigationButtons }
procedure TfPanelMain.EnableNavigationButtons;
begin
  Screen.GetByName('PM_Ship').SetActive(True);
  Screen.GetByName('PM_Gal').SetActive(True);
  Screen.GetByName('PM_Quest').SetActive(True);
  Screen.GetByName('PM_EndTurn').SetActive(True);
  Screen.GetByName('PM_Break').SetActive(False);
  Screen.GetByName('PM_Logo').SetActive(True);
end;
{ @end $603B64 }

{ @routine $603C6C TfPanelMain_RebuildMessageButtons }
procedure TfPanelMain.RebuildMessageButtons;
var
  Panel: TPanelGI;
  MessageEntry: TMessagePlayer;
  Button: TGraphButtonGI;
  Count, MaxCount, X: Integer;
begin
  ClearMessageButtons;
  PersistentPlayerMessageLock.Enter;
  try
    Screen.GetByName('PM_Help').SetActive(False);
    if FirstPersistentPlayerMessage = nil then Exit;
    LastMessageTargetId := 0;
    Panel := Screen.GetByName('PM_PanelMsg') as TPanelGI;
    Panel.SetActive(True);
    Screen.GetByName('PM_WinMsg').SetActive(False);
    MessageEntry := LastPersistentPlayerMessage;
    Count := 0;
    if GiResourceVariant = 1 then MaxCount := 11 else MaxCount := 12;
    while (MessageEntry <> nil) and (Count < MaxCount) do
    begin
      Inc(Count);
      MessageEntry := MessageEntry.Prev;
    end;
    if MessageEntry = nil then MessageEntry := FirstPersistentPlayerMessage;
    X := 0;
    while MessageEntry <> nil do
    begin
      Button := TGraphButtonGI.Create(Panel);
      Button.UserValue := Integer(MessageEntry);
      Button.MouseEnterCallback := MessageMouseEnter;
      Button.MouseLeaveCallback := MessageMouseLeave;
      Button.RightButtonDownCallback := DeleteMessage;
      Button.UpCallback := MessageClicked;
      if (MessageEntry.Kind in [pmGalaxy, pmTips]) and not MessageEntry.WasRead then
      begin
        Button.SetImageNormalPath('GraphBuf');
        Button.ImageNormal.GraphBufControl.SourceHasPerPixelAlpha := True;
        LoadGiByPathIntoGraphBuf('Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].NormalImage,
          Button.ImageNormal.GraphBufControl.GraphBuf);
        Button.ImageNormal.SetSize(Button.ImageNormal.GetContentSize);
        if MessagePulseTimer = 0 then
          MessagePulseTimer := Screen.ScheduleCallbackTimer(40, 40, PulseUnreadMessages);
      end
      else
        Button.SetImageNormalPath('GI,Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].NormalImage);
      Button.SetImageNormalActivePath('GI,Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].ActiveImage);
      Button.SetImageDownPath('GI,Bm.MsgPlayer.' + GiResourceSuffix + PlayerMessagePresentations[MessageEntry.Kind].PressedImage);
      Button.HitKind := gbhRect;
      Button.SetSize(Button.GetMaxStateImageSize);
      Button.SetPosition(Classes.Point(X, Panel.ClientSize.Y div 2 - Button.ClientSize.Y div 2));
      X := X + Button.ClientSize.X + 2;
      Button.UpdateStateImagePlacement;
      Button.UpdateStateVisuals;
      MessageEntry := MessageEntry.Next;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  PlayUnreadMessageSounds;
  SlideMessagesIn;
end;
{ @end $603C6C }

{ @routine $6040BC TfPanelMain_ClearMessageButtons }
procedure TfPanelMain.ClearMessageButtons;
var
  Panel: TPanelGI;
begin
  if MessagePulseTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessagePulseTimer);
    MessagePulseTimer := 0;
  end;
  Panel := Screen.GetByName('PM_PanelMsg') as TPanelGI;
  Panel.SetActive(False);
  Panel.FreeOwnedChildren;
  Screen.GetByName('PM_WinMsg').SetActive(False);
end;
{ @end $6040BC }

{ @routine $60414C TfPanelMain_MessageMouseEnter }
procedure TfPanelMain.MessageMouseEnter(Sender: TObjectGI);
var
  MessageEntry: TMessagePlayer;
  Panel: TPanelGI;
  Window: TWindowGI;
  LabelControl: TLabelGI;
begin
  PersistentPlayerMessageLock.Enter;
  try
    MessageEntry := TMessagePlayer(Sender.UserValue);
    if not IsPersistentPlayerMessageQueued(MessageEntry) then Exit;
    Panel := Screen.GetByName('PM_PanelMsg') as TPanelGI;
    Window := Screen.GetByName('PM_WinMsg') as TWindowGI;
    LabelControl := Screen.GetByName('PM_LabelMsg') as TLabelGI;
    LabelControl.SetText(MessageEntry.Text);
    Window.SetSize(Classes.Point(LabelControl.ClientSize.X + Window.WorkSubRect.Left + Window.WorkSubRect.Right,
      LabelControl.ClientSize.Y + Window.WorkSubRect.Top + Window.WorkSubRect.Bottom));
    Window.UpdateAutoGeometry;
    Window.SetPosition(Classes.Point(Window.LocalPosition.X, Panel.LocalPosition.Y - Window.ClientSize.Y - 5 - 5));
    Window.SetActive(True);
    if not MessageEntry.WasRead then
    begin
      MessageEntry.WasRead := True;
      if MessageEntry.Kind = pmTips then MessageEntry.Turn := Galaxy.CurrentTurn;
    end;
    LabelControl.SetPosition(Window.WorkSubRect.TopLeft);
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $60414C }

{ @routine $6042FC TfPanelMain_MessageMouseLeave }
procedure TfPanelMain.MessageMouseLeave(Sender: TObjectGI);
begin
  Screen.GetByName('PM_WinMsg').SetActive(False);
end;
{ @end $6042FC }

{ @routine $604330 TfPanelMain_DeleteMessage }
procedure TfPanelMain.DeleteMessage(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var MessageEntry: TMessagePlayer; Animation: TgaiGI; Child: TObjectGI;
begin
  PersistentPlayerMessageLock.Enter;
  try
    MessageEntry := TMessagePlayer(Sender.UserValue);
    if not IsPersistentPlayerMessageQueued(MessageEntry) then Exit;
    if MessageEntry.Kind = pmQuestNormal then Exit;
    SoundManager.PlaySound('Sound.DelMsg');
    Sender.SetActive(False);
    Animation := TgaiGI.Create(MessagePanel);
    Animation.SetImagePath('Bm.PanelMain.MsgDel');
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetPosition(AddPoints(Sender.LocalPosition, HalfPoint(Sender.ClientSize)));
    Animation.RestartPlayback;
    Animation.FrameAdvancedCallback := AdvanceMessageDeletion;
    Animation.CycleCompleteCallback := FinishMessageDeletion;
    Animation.UserValue := Integer(MessageEntry);
    Animation.UserIndex := Integer(Sender);
    Child := MessagePanel.FirstChild;
    while Child <> nil do begin
      Child.UserState := Child.LocalPosition.X;
      Child := Child.NextSibling;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  BreakUiMessage;
end;
{ @end $604330 }

{ @routine $604500 TfPanelMain_AdvanceMessageDeletion }
procedure TfPanelMain.AdvanceMessageDeletion(Sender: TObjectGI);
var DeletedButton, Child: TObjectGI; Progress: Double; CursorPoint: TPoint;
begin
  DeletedButton := TObjectGI(Sender.UserIndex);
  Progress := (Sender as TgaiGI).SequenceFrame / (Sender as TgaiGI).SequenceFrameCount;
  Child := MessagePanel.FirstChild;
  while Child <> nil do begin
    if Child is TGraphButtonGI then Child.SetPosition(Classes.Point(Child.UserState, Child.LocalPosition.Y));
    Child := Child.NextSibling;
  end;
  if ((GiResourceVariant = 2) and (CountPersistentPlayerMessages > 13)) or
    ((GiResourceVariant = 1) and (CountPersistentPlayerMessages > 12)) then begin
    Child := DeletedButton.PrevSibling;
    while Child <> nil do begin
      if Child is TGraphButtonGI then Child.SetPosition(Classes.Point(
        Child.LocalPosition.X + Round((DeletedButton.ClientSize.X + 2) * Progress), Child.LocalPosition.Y));
      Child := Child.PrevSibling;
    end;
  end else begin
    Child := DeletedButton.NextSibling;
    while Child <> nil do begin
      if Child is TGraphButtonGI then Child.SetPosition(Classes.Point(
        Child.LocalPosition.X - Round((DeletedButton.ClientSize.X + 2) * Progress), Child.LocalPosition.Y));
      Child := Child.NextSibling;
    end;
  end;
  GetCursorPos(CursorPoint);
  ScreenToClient(MainWindowHandle, CursorPoint);
  // Packs signed words, sign-extending X into the high word.
  PostMessage(MainWindowHandle, $200, 0, SmallInt(CursorPoint.X) or (SmallInt(CursorPoint.Y) shl 16));
end;
{ @end $604500 }

{ @routine $6046A0 TfPanelMain_FinishMessageDeletion }
procedure TfPanelMain.FinishMessageDeletion(Sender: TObjectGI);
begin
  PersistentPlayerMessageLock.Enter;
  try
    if not IsPersistentPlayerMessageQueued(TMessagePlayer(Sender.UserValue)) then Exit;
    RemovePersistentPlayerMessage(TMessagePlayer(Sender.UserValue));
    with Sender as TgaiGI do Sender.Free;
    RebuildMessageButtons;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $6046A0 }

{ @routine $604724 TfPanelMain_SlideMessagesIn }
procedure TfPanelMain.SlideMessagesIn;
begin
  MessageSlideDirection := -1;
  if MessageSlideTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessageSlideTimer);
    MessageSlideTimer := 0;
  end;
  if MessagePanel.LocalPosition.Y > MessagePanelRestTop then
    MessageSlideTimer := Screen.ScheduleCallbackTimer(10, 10, AdvanceMessageSlide);
end;
{ @end $604724 }

{ @routine $604770 TfPanelMain_SlideMessagesOut }
procedure TfPanelMain.SlideMessagesOut;
begin
  MessageSlideDirection := 1;
  if MessageSlideTimer <> 0 then
  begin
    Screen.CancelCallbackTimer(MessageSlideTimer);
    MessageSlideTimer := 0;
  end;
  if MessagePanel.LocalPosition.Y < GameScreenHeight - 5 then
    MessageSlideTimer := Screen.ScheduleCallbackTimer(10, 10, AdvanceMessageSlide);
end;
{ @end $604770 }

{ @routine $6047C4 TfPanelMain_AdvanceMessageSlide }
procedure TfPanelMain.AdvanceMessageSlide(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if MessageSlideDirection < 0 then
  begin
    if MessagePanel.LocalPosition.Y <= MessagePanelRestTop then
    begin
      if MessageSlideTimer <> 0 then
      begin
        Screen.CancelCallbackTimer(MessageSlideTimer);
        MessageSlideTimer := 0;
      end;
      Exit;
    end;
    MessagePanel.SetPosition(Classes.Point(MessagePanel.LocalPosition.X, MessagePanel.LocalPosition.Y + MessageSlideDirection));
  end
  else
  begin
    if MessagePanel.LocalPosition.Y >= GameScreenHeight - 5 then
    begin
      if MessageSlideTimer <> 0 then
      begin
        Screen.CancelCallbackTimer(MessageSlideTimer);
        MessageSlideTimer := 0;
      end;
      Exit;
    end;
    MessagePanel.SetPosition(Classes.Point(MessagePanel.LocalPosition.X, MessagePanel.LocalPosition.Y + MessageSlideDirection));
  end;
end;
{ @end $6047C4 }

{ @routine $604860 TfPanelMain_MessageClicked }
procedure TfPanelMain.MessageClicked(Sender: TObjectGI);
var MessageEntry: TMessagePlayer; TargetId: Cardinal; Attempts: Integer; Ship: TShip; FilmObject: TEFilmObj;
begin
  if (CurrentScreenId <> screenStarMap) or
    ((StarMapScreen.Mode <> 1) and (StarMapScreen.Mode <> 2)) then Exit;
  PersistentPlayerMessageLock.Enter;
  try
    MessageEntry := TMessagePlayer(Sender.UserValue);
    if not IsPersistentPlayerMessageQueued(MessageEntry) then Exit;
    Attempts := 0;
    while Attempts < 3 do begin
      if LastMessageTargetId = 0 then begin
        TargetId := MessageEntry.TargetIds[0];
        if TargetId < 1 then Exit;
      end else begin
        TargetId := 0;
        if LastMessageTargetId = MessageEntry.TargetIds[0] then TargetId := MessageEntry.TargetIds[1]
        else if LastMessageTargetId = MessageEntry.TargetIds[1] then TargetId := MessageEntry.TargetIds[2]
        else if LastMessageTargetId = MessageEntry.TargetIds[2] then TargetId := MessageEntry.TargetIds[0];
        if TargetId < 1 then TargetId := MessageEntry.TargetIds[0];
        if TargetId < 1 then Exit;
      end;
      LastMessageTargetId := TargetId;
      if StarMapScreen.Mode = 1 then begin
        Ship := Galaxy.IdToShip(TargetId, False) as TShip;
        if (Ship <> nil) and Ship.InNormalSpace and (Ship.CurrentStar = Player.CurrentStar) then begin
          StarMapScreen.SetMapCenterManually(TruncatePointF(Ship.Position));
          StarMapScreen.AddMapAnimation(Ship.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 0);
          StarMapScreen.AddMapAnimation(Ship.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 200);
          StarMapScreen.AddMapAnimation(Ship.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 400);
          Break;
        end;
      end else begin
        FilmObject := SecondaryFilm.FindObjectById('Ship2', TargetId);
        if (FilmObject <> nil) and (FilmObject.SceneObject <> nil) then begin
          StarMapScreen.SetMapCenterManually(TruncatePointF(FilmObject.SceneObject.Position));
          Break;
        end;
      end;
      Inc(Attempts);
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $604860 }

{ @routine $604B34 TfPanelMain_PlayUnreadMessageSounds }
procedure TfPanelMain.PlayUnreadMessageSounds;
var MessageEntry: TMessagePlayer;
begin
  MessageEntry := FirstPersistentPlayerMessage;
  while MessageEntry <> nil do
  begin
    if not MessageEntry.NotificationSoundPlayed and (MessageEntry.Kind in [pmGalaxy..pmTips]) then
    begin
      SoundManager.PlaySound('Sound.NewMsg');
      Break;
    end;
    MessageEntry := MessageEntry.Next;
  end;
  MessageEntry := FirstPersistentPlayerMessage;
  while MessageEntry <> nil do
  begin
    MessageEntry.NotificationSoundPlayed := True;
    MessageEntry := MessageEntry.Next;
  end;
end;
{ @end $604B34 }

{ @routine $604BA0 TfPanelMain_ShowControlHelp }
procedure TfPanelMain.ShowControlHelp(Sender: TObjectGI; Visible: Boolean);
var LabelControl: TLabelGI;
begin
  LabelControl := HelpLabel;
  if Sender.HelpText = '' then Visible := False;
  if Visible then SlideMessagesOut else SlideMessagesIn;
  LabelControl.SetActive(Visible);
  LabelControl.SetText(Sender.HelpText);
end;
{ @end $604BA0 }

{ @routine $604BE8 TfPanelMain_ProcessKeyDown }
procedure TfPanelMain.ProcessKeyDown(Key: Cardinal);
begin
  if IsVirtualKeyDown(17) or IsVirtualKeyDown(16) or IsVirtualKeyDown(18) or
    NavigationLocked or IsTurnCalculationRunningUI then Exit;
  if Key = $71 then begin
    CaptureSavePreview;
    SaveManagerReturnScreenId := FormToId(Screen);
    SaveManagerMode := smmSave;
    RequestedScreenId := screenSaveManager;
    Screen.RequestClose(1);
  end else if Key = $72 then begin
    SaveManagerReturnScreenId := FormToId(Screen);
    SaveManagerMode := smmLoad;
    RequestedScreenId := screenSaveManager;
    Screen.RequestClose(1);
  end else if Key = $20 then EndTurnClicked(nil)
  else if Key = $4D then GalaxyClicked(nil)
  else if Key = $53 then ShipClicked(nil)
  else if Key = $52 then QuestClicked(nil)
  else if Key = $1B then MenuClicked(nil);
end;
{ @end $604BE8 }

end.

unit fGameEnd;
// Unit bracket (inferred): CODE 0x00543570..0x00543E5B; inclusive evidence, not full bounds.
// Victory texts depend on the mother ship and ScenarioState.
interface
uses GI_MessageLoop;
type
  TfGameEnd = class(TMessageLoopGI) // @size $C0
  public
    Outcome: Integer; // @offset $B0 -1 defeat; 0, 1, 10 and 11 select the victory texts.
    TextScrollTimer: TCallbackTimerIdGI; // @offset $B4
    TextPanelTop: Integer; // @offset $B8
    TextPanelBottom: Integer; // @offset $BC
    procedure InitializeLayout; override; // @addr $5435F8
    procedure OnOpen; override; // @addr $54366C
    procedure OnClose; override; // @addr $543C2C
    procedure ScrollEndingText(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $543C84
    procedure ContinueClicked(Sender: TObjectGI); // @addr $543D38
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $543D90
    procedure SelectMusic; override; // @addr $543DD8
  end;
implementation
// @unit-initialization $543E54
// @unit-finalization $543E24
uses Classes, Windows, EC_Struct, GR_Main, GR_Music, GI_Main, GI_GraphBuf, GI_GraphButton,
  GI_Label, Globals, GlobalsV, aShip, aPlayer, aPlanet, aGalaxy, aKling, aMyFunction, fScore;

{ @routine $5435F8 TfGameEnd_InitializeLayout }
procedure TfGameEnd.InitializeLayout;
begin
  inherited;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('Ok') as TGraphButtonGI).UpCallback := ContinueClicked;
end;
{ @end $5435F8 }

{ @routine $54366C TfGameEnd_OnOpen }
procedure TfGameEnd.OnOpen;
var Text: WideString;
begin
  if (Player = nil) or ((ScenarioState = scenNone) and Player.IsOnPlanet) then Outcome := -1
  else if (KlingMotherShip <> nil) and (ScenarioState = scenPeaceRachekhanAtLarge) then Outcome := 0
  else if KlingMotherShip <> nil then Outcome := 1
  else if (KlingMotherShip = nil) and ((ScenarioState = scenNone) or (ScenarioState = scenMachpellaFled)) then Outcome := 10
  else if KlingMotherShip = nil then Outcome := 11
  else RaiseWideMessage('EndGame');
  SelectMusic;
  if Player <> nil then ScoreScreen.RecordPlayerResult(Outcome);
  TextPanelTop := GiScalePixels(148);
  TextPanelBottom := GiScalePixels(620);
  if Outcome < 0 then
  begin
    if (GameEndReason = 2) and (Player <> nil) then
    begin
      Text := LookupLocalizedTextLines('FormGameEnd.LossInPlanet');
      if Player.CurrentPlanet <> nil then ReplaceTextToken(Text, '<Planet>', Player.CurrentPlanet.Name, HighlightColorTag)
      else ReplaceTextToken(Text, '<Planet>', '', '');
    end
    else if GameEndReason = 2 then Text := LookupLocalizedTextLines('FormGameEnd.LossInShip')
    else Text := LookupLocalizedTextLines('FormGameEnd.Loss');
  end
  else if Outcome = 0 then Text := LookupLocalizedTextLines('FormGameEnd.00')
  else if Outcome = 10 then Text := LookupLocalizedTextLines('FormGameEnd.10')
  else if Outcome = 1 then Text := LookupLocalizedTextLines('FormGameEnd.01')
  else Text := LookupLocalizedTextLines('FormGameEnd.11');
  if PlayerName = '' then PlayerName := 'GPlayerName='#39;
  ReplaceTextToken(Text, '<Player>', PlayerName, HighlightColorTag);
  ReplaceTextToken(Text, '<Date>', FormatGameTurnDate(Galaxy.CurrentTurn), HighlightColorTag);
  ReplaceTextToken(Text, '<Money>', '10.000', HighlightColorTag);
  ReplaceTextToken(Text, '<br>', #13#10, '');
  with GetByName('GBText') as TGraphBufGI do
  begin
    SourceHasPerPixelAlpha := True;
    RenderLabelTextToBuffer(GraphBuf, ClientSize.X, 1, 0, Text, 'Font.' + GiResourceSuffix + 'Intro',
      $FFDBDA9C, $FF373737, $FFDBDA9C);
    SetSize(Classes.Point(ClientSize.X, GraphBuf.Height));
    SetPosition(Classes.Point(LocalPosition.X, TextPanelBottom));
  end;
  if TextScrollTimer <> 0 then
  begin
    CancelCallbackTimer(TextScrollTimer);
    TextScrollTimer := 0;
  end;
  TextScrollTimer := ScheduleCallbackTimer(20, 20, ScrollEndingText);
end;
{ @end $54366C }

{ @routine $543C2C TfGameEnd_OnClose }
procedure TfGameEnd.OnClose;
begin
  if TextScrollTimer <> 0 then
  begin
    CancelCallbackTimer(TextScrollTimer);
    TextScrollTimer := 0;
  end;
  (GetByName('GBText') as TGraphBufGI).GraphBuf.Clear;
end;
{ @end $543C2C }

{ @routine $543C84 TfGameEnd_ScrollEndingText }
procedure TfGameEnd.ScrollEndingText(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Limit: Single;
begin
  with GetByName('GBText') as TGraphBufGI do
  begin
    SetPosition(AddPoints(LocalPosition, Classes.Point(0, -1)));
    Limit := (TextPanelTop + TextPanelBottom) div 2 - ClientSize.Y div 2;
    if LocalPosition.Y < Limit then
      if TextScrollTimer <> 0 then
      begin
        CancelCallbackTimer(TextScrollTimer);
        TextScrollTimer := 0;
      end;
  end;
end;
{ @end $543C84 }

{ @routine $543D38 TfGameEnd_ContinueClicked }
procedure TfGameEnd.ContinueClicked(Sender: TObjectGI);
begin
  if Galaxy <> nil then
  begin
    Galaxy.Free;
    Galaxy := nil;
  end;
  ScoreScreen.ReturnToEndScreen := Outcome >= 0;
  RequestedScreenId := screenScores;
  RequestClose(1);
  BreakUiMessage;
end;
{ @end $543D38 }

{ @routine $543D90 TfGameEnd_MainPanelKeyDown }
procedure TfGameEnd.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or
    IsVirtualKeyDown(VK_MENU) then Exit;
  if (Key = VK_ESCAPE) or (Key = VK_RETURN) then ContinueClicked(nil);
end;
{ @end $543D90 }

{ @routine $543DD8 TfGameEnd_SelectMusic }
procedure TfGameEnd.SelectMusic;
begin
  if Outcome < 0 then MusicManager.PlayCategory('Loss')
  else MusicManager.PlayCategory('Win');
end;
{ @end $543DD8 }
end.

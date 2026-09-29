unit fTalk;
// Unit bracket (inferred): CODE 0x005786BC..0x0057E79B; inclusive evidence, not full bounds.
// Ship and scripted-planet dialogue.
interface
uses GI_MessageLoop, EC_Struct, Types, aShip, aPlanet;
type
  TDialogTextChoiceEvent = procedure(Text: WideString) of object;
  // Native VMT $5786BC owns the fallback WideString at $1C.
  TfTalkA = class(TObjectEx) // @size $20
  public
    Callback: TDialogChoiceEventGI; // @offset $08
    FallbackCallback: TDialogTextChoiceEvent; // @offset $10
    Value: Integer; // @offset $18
    FallbackText: WideString; // @offset $1C
    constructor Create; // @addr $5787BC
    destructor Destroy; override; // @addr $5787F4
  end;
  TfTalk = class(TMessageLoopGI) // @size $D4
  public
    procedure AddMessageClicked(Sender: TObjectGI); // @addr $5797D4
    procedure ShowGreeting(Action: Integer); // @addr $57AEC4
    procedure ShowMoneyDemand(Action: Integer); // @addr $57AF5C
    procedure DemandMoney(Action: Integer); // @addr $57B434
    procedure HalveMoneyDemand(Action: Integer); // @addr $57B494
    procedure DoubleMoneyDemand(Action: Integer); // @addr $57B4B0
    procedure DemandCargo(Action: Integer); // @addr $57B4C8
    procedure ShowTruceOffer(Action: Integer); // @addr $57B4F4
    procedure AcceptTruceOffer(Action: Integer); // @addr $57B9D4
    procedure HalveTruceOffer(Action: Integer); // @addr $57BAD4
    procedure DoubleTruceOffer(Action: Integer); // @addr $57BB00
    procedure ShowPartnerOffer(Action: Integer); // @addr $57CDE8
    procedure AcceptPartnerOffer(Action: Integer); // @addr $57D530
    procedure HalvePartnerOffer(Action: Integer); // @addr $57D594
    procedure DoublePartnerOffer(Action: Integer); // @addr $57D5B0
    procedure OrderPartnerFollow(Action: Integer); // @addr $57D5E4
    procedure OrderPartnerLand(Action: Integer); // @addr $57D880
    procedure OrderPartnerJump(Action: Integer); // @addr $57DBF4
    procedure OrderPartnerDropCargo(Action: Integer); // @addr $57DF18
    procedure ExitPartnerConversation(Action: Integer); // @addr $57E284
    procedure OrderTranclucatorReturn(Action: Integer); // @addr $57E28C
    function GetShipGreeting: WideString; // @addr $57E6F8
    ParentLoop: TMessageLoopGI; // @offset $B0
    DialogText: WideString; // @offset $B4
    procedure BuildStandardChoices; // @addr $5799C4
    procedure StartConversation; // @addr $57AA8C
    procedure FastExit(Action: Integer); // @addr $57AE48
    procedure RunScriptExitAnswer(Action: Integer); // @addr $57AE80
    procedure AcceptScriptedConversation(Action: Integer); // @addr $57AF1C
    procedure ShowAttackTargets(Action: Integer); // @addr $57BCA8
    procedure RequestAttackTarget(Action: Integer); // @addr $57C268
    procedure RequestProtection(Action: Integer); // @addr $57C5E4
    procedure ApplyOrderToAllPartners(Action: Integer); // @addr $57E134
    function AddImmediateAttackChoices: Boolean; // @addr $57E3E0
    procedure InitializeLayout; override; // @addr $57881C
    procedure OnOpen; override; // @addr $578878
    procedure OnClose; override; // @addr $579130
    procedure ProcessCallbackTimers; override; // @addr $5797A4
    procedure SelectMusic; override; // @addr $5798C0
    PresentedTextLength: Integer; // @offset $B8 Text-presentation progress, $579420/$57949C.
    TextPresentationTimer: TCallbackTimerIdGI; // @offset $BC
    ChoiceHeight: Integer; // @offset $C0 Accumulated by AddChoice, cleared by ClearDialogChoices.
    procedure ClearDialogChoices; // @addr $5791AC
    procedure ChoiceMouseEnter(Sender: TObjectGI); // @addr $579370
    procedure ChoiceMouseLeave(Sender: TObjectGI); // @addr $57939C
    procedure ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5793CC
    procedure RestartTextPresentation; // @addr $579420
    procedure AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $57949C
    ScriptChoicesActive: Boolean; // @offset $D0
    procedure AddScriptExitChoice(Text: WideString); // @addr $57A954
    procedure BuildBuiltinChoices; // @addr $579A30
    procedure AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI); // @addr $579204
    procedure RunScriptAnswer(Answer: Integer); // @addr $57ADBC
  end;
function RunTalk(ParentLoop: TMessageLoopGI): Boolean; // @addr $579900

implementation

// @unit-initialization $57E794
// @unit-finalization $57E764

uses Classes, GI_Label, GI_PanelScrollBar, GI_ScrollBar, GI_Main, GR_GraphBuf, Globals, GlobalsV, aPlayer, aNormalShip, aRanger, aRuins, aGalaxy, aTranclucator, aConst, aMyFunction, aScript, GR_Main, SysUtils, Math, fStarMap, GI_GraphButton, GI_Image, GI_GAI, GI_GraphBuf, aItem;

var
  TruceOfferAmount: Integer; // @addr $61D018
  ExtortionDemandAmount: Integer; // @addr $61D01C
  PartnerOfferAmount: Integer; // @addr $61D020

{ @routine $5787BC TfTalkA_Create }
constructor TfTalkA.Create;
begin
  inherited Create;
end;
{ @end $5787BC }

{ @routine $5787F4 TfTalkA_Destroy }
destructor TfTalkA.Destroy;
begin
  inherited Destroy;
end;
{ @end $5787F4 }

{ @routine $57881C TfTalk_InitializeLayout }
procedure TfTalk.InitializeLayout;
begin
  inherited InitializeLayout;
  ScriptDialogIndex := -1;
  (GetByName('UserMsgAdd') as TGraphButtonGI).UpCallback := AddMessageClicked;
end;
{ @end $57881C }

{ @routine $578878 TfTalk_OnOpen }
procedure TfTalk.OnOpen;
var Owner: TOwnerId; Seed, Portrait, Count: Integer;
begin
  if not MusicInSpace then MusicManager.RequestFadeOut;
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width,
    AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  (GetByName('TalkText') as TLabelGI).SetText('');
  if TalkShip <> nil then
    (GetByName('TalkShip') as TLabelGI).SetText(FormatText1(LocalizedText('Talk.ShipSay'),
      HighlightColorTag, '<Name>', TalkShip.GetFullName(#13#10)))
  else if TalkPlanet <> nil then
    (GetByName('TalkShip') as TLabelGI).SetText(FormatText1(LocalizedText('Talk.PlanetSay'),
      HighlightColorTag, '<Name>', TalkPlanet.GetFullName(#13#10)))
  else (GetByName('TalkShip') as TLabelGI).SetText('');
  if TalkShip <> nil then
  begin
    Owner := TalkShip.OwnerId;
    Seed := TalkShip.Seed;
  end
  else if TalkPlanet <> nil then
  begin
    Owner := TalkPlanet.OwnerId;
    Seed := TalkPlanet.GenerationSeed;
  end
  else raise Exception.Create('Talk error');
  if Owner = oiNone then
  begin
    Portrait := SeededRandomIntRange(0, 4, Seed);
    if Portrait = 0 then Owner := oiMaloc
    else if Portrait = 1 then Owner := oiPeleng
    else if Portrait = 2 then Owner := oiPeople
    else if Portrait = 3 then Owner := oiFei
    else Owner := oiGaal;
  end;
  Count := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Owner].InternalName));
  // Tests only for zero; a configured count of one divides by zero.
  if Count = 0 then Portrait := 0 else Portrait := Seed mod (Count - 1) + 1;
  with GetByName('CaptainI') as TImageGI do
  begin
    if (TalkShip <> nil) and (TalkShip is TTranclucator) then
    begin
      SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + 'Tranclucatori');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
    else if (TalkShip <> nil) and (TalkShip.OwnerId = oiKling) then
    begin
      SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + 'Mamai');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
    else if Count > 0 then
    begin
      SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Owner].InternalName + IntToStr(Portrait) + 'i');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
    end
    else SetActive(False);
  end;
  with GetByName('CaptainA') as TgaiGI do
  begin
    FirstFrameOnly := not AnimCaptain;
    if (TalkShip <> nil) and (TalkShip is TTranclucator) then
    begin
      SetImagePath('Bm.Captain.' + GiResourceSuffix + 'Tranclucatora');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end
    else if (TalkShip <> nil) and (TalkShip.OwnerId = oiKling) then
    begin
      SetImagePath('Bm.Captain.' + GiResourceSuffix + 'Mamaa');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end
    else if Count > 0 then
    begin
      SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Owner].InternalName + IntToStr(Portrait) + 'a');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetActive(True);
      RestartPlayback;
    end
    else SetActive(False);
  end;
  GetByName('ObjArrow').SetActive((TalkShip <> nil) or ((TalkPlanet <> nil) and (TalkPlanet.CurrentStar = Player.CurrentStar)));
  StartConversation;
  RestartTextPresentation;
  (GetByName('TalkPA') as TPanelScrollBarGI).SetVerticalScrollbarEnabled(False);
end;
{ @end $578878 }

{ @routine $579130 TfTalk_OnClose }
procedure TfTalk.OnClose;
var I: Integer; Ship: TShip;
begin
  ClearDialogChoices;
  AuxRenderBuffer.Clear;
  ScriptDialogIndex := -1;
  TalkShip := nil;
  TalkPlanet := nil;
  if not TalkScripted then
    for I := 0 to Player.CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(Player.CurrentStar.Ships[I]);
      if Ship.ScriptShip <> nil then Ship.NextDay;
    end;
end;
{ @end $579130 }

{ @routine $5791AC TfTalk_ClearDialogChoices }
procedure TfTalk.ClearDialogChoices;
var Panel, Child: TObjectGI;
begin
  ChoiceHeight := 0;
  Panel := GetByName('TalkPA');
  Child := Panel.FirstChild;
  while Child <> nil do
  begin
    TObject(Child.UserValue).Free;
    Child := Child.NextSibling;
  end;
  Panel.FreeOwnedChildren;
  Panel.Invalidate;
end;
{ @end $5791AC }

{ @routine $579204 TfTalk_AddChoice }
procedure TfTalk.AddChoice(Text: WideString; Value: Integer; Callback: TDialogChoiceEventGI);
var
  Panel: TPanelScrollBarGI;
  Choice: TfTalkA;
begin
  Panel := GetByName('TalkPA') as TPanelScrollBarGI;
  Choice := TfTalkA.Create;
  Choice.Callback := Callback;
  Choice.Value := Value;
  with TLabelGI.Create(Panel) do
  begin
    SetFontName(HitPointFontName);
    SetSize(Point(Panel.ClientSize.X, 20));
    SetPosition(Point(0, ChoiceHeight));
    SetWordWrapEnabled(True);
    SetTextAlignX(taxLeft);
    SetTextAlignY(tayAuto);
    SetText(Text);
    SetPositionModeW(True);
    UserValue := Integer(Choice);
    SetActive(False);
    MouseEnterCallback := ChoiceMouseEnter;
    MouseLeaveCallback := ChoiceMouseLeave;
    LeftButtonDownCallback := ChoiceMouseDown;
    Inc(ChoiceHeight, ClientSize.Y);
  end;
end;
{ @end $579204 }

{ @routine $579370 TfTalk_ChoiceMouseEnter }
procedure TfTalk.ChoiceMouseEnter(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 245, 80));
end;
{ @end $579370 }

{ @routine $57939C TfTalk_ChoiceMouseLeave }
procedure TfTalk.ChoiceMouseLeave(Sender: TObjectGI);
begin
  (Sender as TLabelGI).SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
end;
{ @end $57939C }

{ @routine $5793CC TfTalk_ChoiceMouseDown }
procedure TfTalk.ChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Choice: TfTalkA;
begin
  Choice := TfTalkA(Sender.UserValue);
  if Assigned(Choice.Callback) then Choice.Callback(Choice.Value)
  else if Assigned(Choice.FallbackCallback) then Choice.FallbackCallback(Choice.FallbackText);
  RestartTextPresentation;
  BreakUiMessage;
end;
{ @end $5793CC }
{ @routine $579420 TfTalk_RestartTextPresentation }
procedure TfTalk.RestartTextPresentation;
begin
  (GetByName('TalkPA') as TPanelScrollBarGI).SetActive(False);
  PresentedTextLength := 0;
  if TextPresentationTimer <> 0 then
  begin
    CancelCallbackTimer(TextPresentationTimer);
    TextPresentationTimer := 0;
  end;
  TextPresentationTimer := ScheduleCallbackTimer(10, 10, AdvanceTextPresentation, 0);
end;
{ @end $579420 }
{ @routine $57949C TfTalk_AdvanceTextPresentation }
procedure TfTalk.AdvanceTextPresentation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Choices, TextPanel: TPanelScrollBarGI; Child: TObjectGI; Count, ExtraHeight, Top: Integer;
begin
  if PresentedTextLength >= Length(DialogText) then
  begin
    Choices := GetByName('TalkPA') as TPanelScrollBarGI;
    Choices.SetActive(True);
    Count := 0;
    Child := Choices.FirstChild;
    while Child <> nil do
    begin
      Child.SetActive(True);
      Child := Child.NextSibling;
      Inc(Count);
    end;
    if ChoiceHeight < Choices.ClientSize.Y then
    begin
      ExtraHeight := (Choices.ClientSize.Y - ChoiceHeight) div Count;
      Child := Choices.FirstChild;
      Top := 0;
      while Child <> nil do
      begin
        (Child as TLabelGI).SetTextAlignY(tayCenterEx);
        Child.SetPosition(Point(Child.LocalPosition.X, Top));
        Child.SetSize(Point(Child.ClientSize.X, Child.ClientSize.Y + ExtraHeight));
        Inc(Top, Child.ClientSize.Y);
        Child := Child.NextSibling;
      end;
      Choices.SetVerticalScrollbarEnabled(False);
      Choices.SetScrollOffset(Point(0, 0));
      Choices.SetDragScrollingEnabled(False);
    end
    else
    begin
      Choices.SetScrollOffset(Point(0, 0));
      Choices.SetVerticalScrollbarEnabled(True);
      Choices.SetDragScrollingEnabled(True);
      Choices.UpdateScrollRanges;
    end;
    Choices.VerticalScrollBar.SetSmallChange((GetByName('TalkText') as TLabelGI).GetLineHeight);
    Choices.VerticalScrollBar.SetLargeChange(Choices.ClientSize.Y);
    Choices.VerticalScrollBar.SetPageSize(Choices.ClientSize.Y);
    if TextPresentationTimer <> 0 then
    begin
      CancelCallbackTimer(TextPresentationTimer);
      TextPresentationTimer := 0;
    end;
  end
  else
  begin
    PresentedTextLength := Length(DialogText);
    (GetByName('TalkText') as TLabelGI).SetText(DialogText);
    TextPanel := GetByName('TextScroll') as TPanelScrollBarGI;
    TextPanel.SetScrollOffset(Point(0, 0));
    TextPanel.UpdateScrollRanges;
    TextPanel.VerticalScrollBar.SetActive((TextPanel.FindByNameRecursive('TalkText') as TLabelGI).ClientSize.Y > TextPanel.ClientSize.Y);
    TextPanel.VerticalScrollBar.SetSmallChange((TextPanel.FindByNameRecursive('TalkText') as TLabelGI).GetLineHeight);
    TextPanel.VerticalScrollBar.SetLargeChange(TextPanel.ClientSize.Y);
    TextPanel.VerticalScrollBar.SetPageSize(TextPanel.ClientSize.Y);
    GetByName('UserMsgAdd').SetActive(True);
  end;
end;
{ @end $57949C }
{ @routine $5797A4 TfTalk_ProcessCallbackTimers }
procedure TfTalk.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(2);
end;
{ @end $5797A4 }
{ @routine $5797D4 TfTalk_AddMessageClicked }
procedure TfTalk.AddMessageClicked(Sender: TObjectGI);
var Text: WideString;
begin
  Text := (GetByName('TalkText') as TLabelGI).GetText;
  GetByName('UserMsgAdd').SetActive(False);
  SoundManager.PlaySound('Sound.UserMsgAdd');
  AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Text, '');

end;
{ @end $5797D4 }
{ @routine $5798C0 TfTalk_SelectMusic }
procedure TfTalk.SelectMusic;
begin
  if not MusicInSpace then MusicManager.RequestFadeOut
  else MusicManager.PlayCategory('StarMap');
end;
{ @end $5798C0 }
{ @routine $579900 RunTalk }
function RunTalk(ParentLoop: TMessageLoopGI): Boolean;
var State: TCursorStateGI;
begin
  ParentLoop.RootUiObject.NativeHook50;
  ParentLoop.CaptureCursorState(@State);
  ParentLoop.SetCursorActive(False);
  ParentLoop.DrawQueuedUpdateRects;
  TalkScreen.ParentLoop := ParentLoop;
  if TalkScreen.Run = 1 then Result := True else Result := False;
  TalkScreen.ParentLoop := nil;
  ParentLoop.InvalidateViewport;
  ParentLoop.RestoreCursorState(@State);
  ParentLoop.UpdateCursorPosition;
  ParentLoop.RootUiObject.NativeHook48;
end;
{ @end $579900 }
{ @routine $5799C4 TfTalk_BuildStandardChoices }
procedure TfTalk.BuildStandardChoices;
var ScriptShip: TScriptShip;
begin
  ClearDialogChoices;
  if ScriptChoicesActive and (TalkShip.ScriptShip <> nil) then
  begin
    ScriptShip := TScriptShip(TalkShip.ScriptShip);
    ScriptShip.Script.CallDialog(ScriptShip.Script.CurrentDialog);
    if ScriptDialogIndex < 0 then BuildBuiltinChoices
    else ScriptShip.Script.CallDialogMessage(ScriptDialogIndex);
  end
  else BuildBuiltinChoices;
end;
{ @end $5799C4 }
{ @routine $579A30 TfTalk_BuildBuiltinChoices }
procedure TfTalk.BuildBuiltinChoices;
var TargetName: WideString;
begin
  if TalkScripted then
  begin
    case TalkScriptedKind of
      0: ;
      1: if Player.Money >= TalkScriptedAmount then
           AddChoice('- ' + Player.LookupTalkText('Talk.Money.RangerOk'), 0, AcceptScriptedConversation)
         else AddChoice('- ' + Player.LookupTalkText('Talk.Money.AnswerNotMoney'), 0, FastExit);
      2: if Player.HasCargoGoods then
           AddChoice('- ' + Player.LookupTalkText('Talk.Goods.RangerOk'), 0, AcceptScriptedConversation)
         else AddChoice('- ' + Player.LookupTalkText('Talk.Goods.AnswerNotGoods'), 0, FastExit);
      3: AddChoice('- ' + Player.LookupTalkText('Talk.Truce.RangerOk'), 0, AcceptScriptedConversation);
      4: AddChoice('- ' + Player.LookupTalkText('Talk.Attack.RangerOk'), 0, AcceptScriptedConversation);
      5: AddChoice('- ' + Player.LookupTalkText('Talk.Partner.AnswerLiderBreak'), 0, FastExit);
      6: AddChoice('- ' + Player.LookupTalkText('Talk.Partner.AnswerLiderTheEnd'), 0, FastExit);
    end;
    AddChoice('- ' + Player.LookupTalkText('Talk.Exit'), 0, FastExit);
  end
  else
  begin
    TruceOfferAmount := Min(Player.Money, Player.GetWealthScaledAmount(scAverage));
    ExtortionDemandAmount := (TalkShip.GetWealthScaledAmount(scAverage) + Player.GetWealthScaledAmount(scAverage)) div 2;
    PartnerOfferAmount := Player.Money;
    if TalkShip.ShipType <> t_Tranclucator then
    begin
      if (TalkShip.GetRelationLevelToShip(Player) = rlHostile) and (TalkShip.PartnerShip <> Player) then
      begin
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Truce.PlayerSend'), 0, ShowTruceOffer);
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Money.PlayerSend'), 0, ShowMoneyDemand);
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Goods.PlayerSend'), 0, DemandCargo);
      end
      else
      begin
        if not AddImmediateAttackChoices and (TalkShip.PartnerShip <> Player) then
        begin
          AddChoice('- ' + TalkShip.LookupTalkText('Talk.Money.PlayerSend'), 0, ShowMoneyDemand);
          AddChoice('- ' + TalkShip.LookupTalkText('Talk.Goods.PlayerSend'), 0, DemandCargo);
        end;
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Attack.PlayerSend'), 0, ShowAttackTargets);
      end;
      if (TalkShip.PartnerShip <> Player) and (TalkShip.OrderTarget is TShip) and
        (TalkShip.OrderTarget <> Player) then
        if ((TalkShip.OrderTarget as TShip).GetRelationLevelToShip(Player) > rlHostile) and
          ((TalkShip.OrderTarget as TShip).OrderTarget <> TalkShip) and
          (TalkShip.GetRelationLevelToShip(TalkShip.OrderTarget as TShip) = rlHostile) then
          AddChoice(FormatText1('- ' + TalkShip.LookupTalkText('Talk.Protect.PlayerSend'), '', '<Target>', (TalkShip.OrderTarget as TShip).GetFullName(' ')), 0, RequestProtection);
    end;
    case TalkShip.ShipType of
    t_Ranger: begin
      if TalkShip.PartnerShip <> Player then
      begin
        if (Player.Money > 0) and (Player.CountWingmen < 5) then
          AddChoice(FormatText1('- ' + TalkShip.LookupTalkText('Talk.Partner.PlayerSend'), '', '<Ranger>', TalkShip.GetName), 0, ShowPartnerOffer);
      end
      else
      begin
        if TalkShip.OrderTarget <> Player then
          AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.FlyToMe'), 0, OrderPartnerFollow);
        case Player.Order of
        soLanding: begin
          if Player.OrderTarget <> TalkShip.OrderTarget then
          begin
            if Player.OrderTarget is TShip then TargetName := (Player.OrderTarget as TShip).Name
            else TargetName := (Player.OrderTarget as TPlanet).Name;
            AddChoice(FormatText1('- ' + TalkShip.LookupTalkText('Talk.Partner.LandingToObject'), HighlightColorTag, '<ObjectName>', TargetName), 0, OrderPartnerLand);
          end;
        end;
        soJump: if TalkShip.OrderTarget <> Player.OrderTarget then
          AddChoice(FormatText1('- ' + TalkShip.LookupTalkText('Talk.Partner.FlyToStar'), HighlightColorTag, '<Star>', (Player.OrderTarget as TStar).Name), 0, OrderPartnerJump);
        end;
        if TalkShip.HasLooseNonScriptItemsOrGoods or not Player.CanResolveObjectWithScanner(TalkShip) then
          AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.PlayerSendDropCargo'), 0, OrderPartnerDropCargo);
      end;
    end;
    t_Tranclucator: if (TalkShip as TTranclucator).OwnerShip = Player then
    begin
      AddImmediateAttackChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Attack.PlayerSend'), 0, ShowAttackTargets);
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Tranclucator.Return.PlayerSend'), 0, OrderTranclucatorReturn);
    end;
    end;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end;
end;
{ @end $579A30 }
{ @routine $57A954 TfTalk_AddScriptExitChoice }
procedure TfTalk.AddScriptExitChoice(Text: WideString);
begin
  if Text <> '' then AddChoice('- ' + Text, CurrentScript.CurrentAnswer, RunScriptExitAnswer)
  else if TalkPlanet = nil then AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), CurrentScript.CurrentAnswer, RunScriptExitAnswer)
  else AddChoice('- ' + Player.LookupTalkText('Talk.Exit'), CurrentScript.CurrentAnswer, RunScriptExitAnswer);
end;
{ @end $57A954 }
{ @routine $57AA8C TfTalk_StartConversation }
procedure TfTalk.StartConversation;
var Binding: TScriptShip;
begin
  ScriptChoicesActive := False;
  if TalkPlanet <> nil then
  begin
    ClearDialogChoices;
    CurrentScript.CallDialogMessage(ScriptDialogIndex);
  end
  else if TalkShip.ScriptShip <> nil then
  begin
    CurrentScript := TScriptShip(TalkShip.ScriptShip).Script;
    ClearDialogChoices;
    TScriptShip(TalkShip.ScriptShip).Script.PublishShipContext(TalkShip.ScriptShip as TScriptShip);
    if ScriptDialogIndex < 0 then
    begin
      Binding := TScriptShip(TalkShip.ScriptShip);
      // Ships belonging to the player's script use the state action dialog.
      if (Player.ScriptShip <> nil) and (TScriptShip(Player.ScriptShip).Script = Binding.Script) then
      begin
        if Binding.State.ActionCode <> nil then
        begin
          Binding.State.ActionCode.Run(ScriptProcess);
          BuildStandardChoices;
        end
        else if (Binding.State.OnActionText <> '') and (Binding.Script.InitCode.LocalVar.GetVarNE(Binding.State.OnActionText) <> nil) then
        begin
          CurrentScript.CallDialog(Binding.Script.InitCode.LocalVar.GetVar(Binding.State.OnActionText).GetInt);
          if ScriptDialogIndex < 0 then
          begin
            DialogText := GetShipGreeting;
            BuildBuiltinChoices;
          end
          else
          begin
            ScriptChoicesActive := True;
            CurrentScript.CallDialogMessage(ScriptDialogIndex);
          end;
        end
        else
        begin
          DialogText := GetShipGreeting;
          BuildStandardChoices;
        end;
      end
      else
      begin
        if Binding.State.AuxiliaryCode <> nil then
        begin
          Binding.State.AuxiliaryCode.Run(ScriptProcess);
          BuildStandardChoices;
        end
        else if (Binding.State.AuxiliaryText <> '') and (Binding.Script.InitCode.LocalVar.GetVarNE(Binding.State.AuxiliaryText) <> nil) then
        begin
          CurrentScript.CallDialog(Binding.Script.InitCode.LocalVar.GetVar(Binding.State.AuxiliaryText).GetInt);
          if ScriptDialogIndex < 0 then
          begin
            DialogText := GetShipGreeting;
            BuildBuiltinChoices;
          end
          else
          begin
            ScriptChoicesActive := True;
            CurrentScript.CallDialogMessage(ScriptDialogIndex);
          end;
        end
        else
        begin
          DialogText := GetShipGreeting;
          BuildStandardChoices;
        end;
      end;
    end
    else
    begin
      ScriptChoicesActive := True;
      CurrentScript.CallDialogMessage(ScriptDialogIndex);
    end;
  end
  else
  begin
    if TalkScripted then DialogText := ScriptedTalkText else DialogText := GetShipGreeting;
    BuildStandardChoices;
  end;
end;
{ @end $57AA8C }
{ @routine $57ADBC TfTalk_RunScriptAnswer }
procedure TfTalk.RunScriptAnswer(Answer: Integer);
begin
  ClearDialogChoices;
  ScriptDialogIndex := -1;
  CurrentScript.ExecuteDialogAnswer(Answer);
  if ScriptDialogIndex < 0 then RaiseWideMessage('I_Script');
  if TalkPlanet <> nil then CurrentScript.CallDialogMessage(ScriptDialogIndex)
  else TScriptShip(TalkShip.ScriptShip).Script.CallDialogMessage(ScriptDialogIndex);
end;
{ @end $57ADBC }
{ @routine $57AE48 TfTalk_FastExit }
procedure TfTalk.FastExit(Action: Integer);
begin
  RequestedScreenId := TalkReturnScreenId;
  if TalkScripted then StarMapScreen.ResumeMode := 3;
  RequestClose(1);
end;
{ @end $57AE48 }
{ @routine $57AE80 TfTalk_RunScriptExitAnswer }
procedure TfTalk.RunScriptExitAnswer(Action: Integer);
begin
  CurrentScript.ExecuteDialogAnswer(Action);
  RequestedScreenId := TalkReturnScreenId;
  if TalkScripted then StarMapScreen.ResumeMode := 3;
  RequestClose(1);
end;
{ @end $57AE80 }
{ @routine $57AEC4 TfTalk_ShowGreeting }
procedure TfTalk.ShowGreeting(Action: Integer);
begin
  DialogText := GetShipGreeting;
  BuildStandardChoices;
end;
{ @end $57AEC4 }
{ @routine $57AF1C TfTalk_AcceptScriptedConversation }
procedure TfTalk.AcceptScriptedConversation(Action: Integer);
begin
  TalkScriptedAccepted := True;
  RequestedScreenId := TalkReturnScreenId;
  if TalkScripted then StarMapScreen.ResumeMode := 3;
  RequestClose(1);
end;
{ @end $57AF1C }
{ @routine $57AF5C TfTalk_ShowMoneyDemand }
procedure TfTalk.ShowMoneyDemand(Action: Integer);
begin
  if (Player.TruceShip = TalkShip) or ((TalkShip is TNormalShip) and
    ((TalkShip as TNormalShip).LastPlayerExtortionTurn + 30 > Galaxy.CurrentTurn)) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Money.WeAlreadyHavePact');
    TalkShip.ReactToExtortionDemand(Player);
    BuildStandardChoices;
  end
  else
  begin
    if not TalkShip.AcceptsRansomDemandFrom(Player) then
    begin
      DialogText := TalkShip.LookupTalkText('Talk.Money.' + TalkShip.GetTypeNameKey + 'No');
      TalkShip.ReactToExtortionDemand(Player);
      BuildStandardChoices;
    end
    else if (TalkShip.ShipType <> t_Warrior) and TalkShip.CanEscapePursuer(Player) then
    begin
      DialogText := TalkShip.LookupTalkText('Talk.Money.' + TalkShip.GetTypeNameKey + 'LongDistance');
      TalkShip.ReactToExtortionDemand(Player);
      BuildStandardChoices;
    end
    else
    begin
      DialogText := TalkShip.LookupTalkText('Talk.Money.ComputerAsk');
      ClearDialogChoices;
      AddChoice('- ' + ReplaceColoredToken(TalkShip.LookupTalkText('Talk.Money.PlayerSendSum'), '<Money>',
        WideString(IntToStr(ExtortionDemandAmount)), HighlightColorTag), 0, DemandMoney);
      if ExtortionDemandAmount div 2 > 10 then AddChoice('- ' + TalkShip.LookupTalkText('Talk.Money.PlayerLess'), 0, HalveMoneyDemand);
      if 3 * (TalkShip.GetWealthScaledAmount(scAverage) + Player.GetWealthScaledAmount(scAverage)) >= 2 * ExtortionDemandAmount then
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Money.PlayerMore'), 0, DoubleMoneyDemand);
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Cancel'), 0, ShowGreeting);
    end;
  end;
end;
{ @end $57AF5C }
{ @routine $57B434 TfTalk_DemandMoney }
procedure TfTalk.DemandMoney(Action: Integer);
begin
  if TalkShip.BuildMoneyExtortionResponse(Player, DialogText, ExtortionDemandAmount) then
  begin
    SoundManager.PlaySound('Sound.Sell');
  end;
  BuildStandardChoices;
end;
{ @end $57B434 }
{ @routine $57B494 TfTalk_HalveMoneyDemand }
procedure TfTalk.HalveMoneyDemand(Action: Integer);
begin
  ExtortionDemandAmount := ExtortionDemandAmount div 2;
  ShowMoneyDemand(0);
end;
{ @end $57B494 }
{ @routine $57B4B0 TfTalk_DoubleMoneyDemand }
procedure TfTalk.DoubleMoneyDemand(Action: Integer);
begin
  ExtortionDemandAmount := ExtortionDemandAmount * 2;
  ShowMoneyDemand(0);
end;
{ @end $57B4B0 }
{ @routine $57B4C8 TfTalk_DemandCargo }
procedure TfTalk.DemandCargo(Action: Integer);
begin
  TalkShip.BuildCargoExtortionResponse(Player, DialogText);
  BuildStandardChoices;
end;
{ @end $57B4C8 }
{ @routine $57B4F4 TfTalk_ShowTruceOffer }
procedure TfTalk.ShowTruceOffer(Action: Integer);
var
  Response: WideString;
begin
  if Player.TruceShip = TalkShip then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Truce.WeAlreadyHavePact');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
    Exit;
  end;
  if TalkShip.BuildTrucePaymentResponse(Player, Response, 0) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Truce.ComputerOkWithoutMoney');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
    Exit;
  end;
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Truce.ComputerAsk');
    ClearDialogChoices;
    if Player.Money > 0 then
    begin
      AddChoice('- ' + ReplaceColoredToken(TalkShip.LookupTalkText('Talk.Truce.PlayerSendSum'), '<Money>',
        WideString(IntToStr(TruceOfferAmount)), HighlightColorTag), 0, AcceptTruceOffer);
      if TruceOfferAmount div 2 > 100 then
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Truce.PlayerLess'), 0, HalveTruceOffer);
      if Player.Money > TruceOfferAmount then
        AddChoice('- ' + TalkShip.LookupTalkText('Talk.Truce.PlayerMore'), 0, DoubleTruceOffer);
    end
    else
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Truce.PlayerNotHaveMoney'), 0, ShowGreeting);
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Cancel'), 0, ShowGreeting);
  end;
end;
{ @end $57B4F4 }
{ @routine $57B9D4 TfTalk_AcceptTruceOffer }
procedure TfTalk.AcceptTruceOffer(Action: Integer);
begin
  if TalkShip.BuildTrucePaymentResponse(Player, DialogText, TruceOfferAmount) then
  begin
    SoundManager.PlaySound('Sound.Sell');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end
  else BuildStandardChoices;
end;
{ @end $57B9D4 }

{ @routine $57BAD4 TfTalk_HalveTruceOffer }
procedure TfTalk.HalveTruceOffer(Action: Integer);
begin
  TruceOfferAmount := Max(100, TruceOfferAmount div 2);
  ShowTruceOffer(0);
end;
{ @end $57BAD4 }

{ @routine $57BB00 TfTalk_DoubleTruceOffer }
procedure TfTalk.DoubleTruceOffer(Action: Integer);
begin
  TruceOfferAmount := Min(Player.Money, TruceOfferAmount * 2);
  ShowTruceOffer(0);
end;
{ @end $57BB00 }

{ @routine $57BCA8 TfTalk_ShowAttackTargets }
procedure TfTalk.ShowAttackTargets(Action: Integer);
var RadarRangeSquared: Integer; Ship: TShip;
  // @nested $57BB2C AddAvailableAttackTargets
  procedure AddAvailableAttackTargets; // @addr $57BB2C @calls "0x0057BD98 0x0057BFFE"
  var I: Integer;
  begin
    RadarRangeSquared := Player.GetRadarRange * Player.GetRadarRange;
    for I := 0 to Player.CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(Player.CurrentStar.Ships[I]);
      if (TalkShip.OrderTarget <> Ship) and (Ship <> Player) and (Ship <> TalkShip) and
        (Ship.PartnerShip <> Player) and Ship.InNormalSpace and
        (RadarRangeSquared > PointDistanceSquared(Player.Position, Ship.Position)) and
        not (Ship.ShipType in [t_RangerCenter..t_ScientificBase]) then
        AddChoice('- ' + Ship.GetFullName(' '), Integer(Ship), RequestAttackTarget);
    end;
  end;
begin
  if TalkShip.OrderTarget is TShip then
  begin
    Ship := TalkShip.OrderTarget as TShip;
    if TalkShip.GetRelationLevelToShip(Ship) = rlHostile then
    begin
      DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Attack.ComputerReadyAttack'), HighlightColorTag, '<Target>', Ship.GetFullName(' '));
      ClearDialogChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Attack.RangerOk'), Integer(Ship), RequestAttackTarget);
      AddAvailableAttackTargets;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Cancel'), 0, ShowGreeting);
      Exit;
    end;
  end;
  if TalkShip.RecomputeFearState and (TalkShip.PartnerShip <> Player) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Attack.ComputerInFear');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end
  else
  begin
    if TalkShip is TTranclucator then DialogText := TalkShip.LookupTalkText('Talk.Tranclucator.Attack.Ask')
    else if not TalkShip.TrustsAttackRequester(Player) then
    begin
      DialogText := TalkShip.LookupTalkText('Talk.Attack.' + TalkShip.GetTypeNameKey + 'Suspect');
      ClearDialogChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
      Exit;
    end
    else if TalkShip.HasLockedOrFollowOrder and (TalkShip.PartnerShip <> Player) and (TalkShip.ShipType <> t_Warrior) then
    begin
      DialogText := TalkShip.LookupTalkText('Talk.Attack.' + TalkShip.GetTypeNameKey + 'HaveBusiness');
      ClearDialogChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
      Exit;
    end
    else DialogText := TalkShip.LookupTalkText('Talk.Attack.ComputerAsk');
    ClearDialogChoices;
    AddAvailableAttackTargets;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Cancel'), 0, ShowGreeting);
  end;
end;
{ @end $57BCA8 }

{ @routine $57C268 TfTalk_RequestAttackTarget }
procedure TfTalk.RequestAttackTarget(Action: Integer);
var Target: TShip;
begin
  Target := TShip(Action);
  if TalkShip.RecomputeFearState and (TalkShip.OrderTarget <> Target) and (TalkShip.PartnerShip <> Player) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Attack.ComputerInFear');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end
  else if TalkShip.BuildAttackRequestResponse(Player, DialogText, Target) and (TalkShip.PartnerShip = Player) then
  begin
    if Player.CountPartnersInNormalSpace > 1 then
    begin
      DialogText := DialogText + #13#10 + TalkShip.LookupTalkText('Talk.Partner.IsOrderForAll');
      ClearDialogChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForAll'), 0, ApplyOrderToAllPartners);
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForYou'), 0, ExitPartnerConversation);
    end
    else
    begin
      ClearDialogChoices;
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
    end;
  end
  else
  begin
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end;
end;
{ @end $57C268 }

{ @routine $57C5E4 TfTalk_RequestProtection }
procedure TfTalk.RequestProtection(Action: Integer);
const FullNameSeparator = WideString(' ');
var Target: TShip; I, Reward: Integer; Weapon: TWeapon;
  CanEscape, FearsAttacker: Boolean;
begin
  if (not TalkShip.RecomputeFearState) and (TalkShip.GetRelationLevelToShip(Player) = rlHostile) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Protect.ComputerNotFearAndWar');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
    Exit;
  end;

  Target := TShip(TalkShip.OrderTarget);
  if TalkShip.EvaluateAllyRelationAndStrength(Player) then
  begin
    CanEscape := Target.CanEscapePursuer(TalkShip);
    FearsAttacker := Target.AcceptsRansomDemandFrom(TalkShip);
    Reward := Round(RemapClampedAlternate(Target.ChanceToWin(TalkShip), 0.1, 1,
      Galaxy.ComputeScaledSmallMoney(Target.OwnerId) * 0.5,
      Galaxy.ComputeScaledMiniMoney(Target.OwnerId) * 0.5));
    if TalkShip.EnemyShip = Target then TalkShip.EnemyShip := nil;
    if TalkShip.ShipType = t_Ranger then Target.ChangeRelationToRanger(TalkShip, 15);
    if TalkShip = Target.EnemyShip then Target.EnemyShip := nil;
    if Target.ShipType = t_Ranger then TalkShip.ChangeRelationToRanger(Target, 15);
    TalkShip.TruceShip := Target;
    TalkShip.NextDay;
    if TalkShip.OrderTarget = Target then TalkShip.OrderNone;
    if (TalkShip.Order = soFollowShip) and ((TalkShip.OrderTarget as TShip).ShipType in [t_Ranger..t_Pirate]) then
    begin
      TalkShip.NavigateToQueuedPlanet(False);
      if TalkShip.Order = soFollowShip then TalkShip.OrderNone;
    end;
    for I := 1 to Target.WeaponCount do
    begin
      Weapon := Target.Weapons[I-1];
      if TalkShip = Weapon.Target then Weapon.Target := nil;
    end;
    for I := 1 to TalkShip.WeaponCount do
    begin
      Weapon := TalkShip.Weapons[I-1];
      if Weapon.Target = Target then Weapon.Target := nil;
    end;
    Target.ChangeRelationToRanger(Player, 50);
    if TalkShip.ShipType = t_Pirate then Player.AddWarriorCareerActivity(4);
    if Target.ShipType = t_Pirate then Player.AddPirateCareerActivity(8);
    DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Protect.' + TalkShip.GetTypeNameKey + 'Ok'), HighlightColorTag, '<Target>', Target.GetFullName(FullNameSeparator));
    if Target.ShipType in [t_Ranger..t_Pirate] then
    begin
      if not FearsAttacker then Target.ShowMessageToPlayer(Target.LookupTalkText('Talk.Protect.TargetNotFearShip'))
      else if CanEscape and (Target.GetHullIntegrityPercent > 30) then
        Target.ShowMessageToPlayer(Target.LookupTalkText('Talk.Protect.TargetMayRunAway'))
      else if Target.HasCargoGoods then
      begin
        Target.JettisonCargoGoodsTowardTargetValue(Reward);
        Target.ShowMessageToPlayer(Target.LookupTalkText('Talk.Protect.TargetGiveGoods'));
      end
      else if Target.Money >= Reward then
      begin
        Target.SetMoney(Target.Money - Reward);
        Player.SetMoney(Player.Money + Reward);
        Target.ShowMessageToPlayer(FormatText1(Target.LookupTalkText('Talk.Protect.TargetGiveMoney'),
          HighlightColorTag, '<Money>', WideString(IntToStr(Reward))));
      end
      else Target.ShowMessageToPlayer(Target.LookupTalkText('Talk.Protect.TargetThanks'));
    end;
  end
  else DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Protect.' + TalkShip.GetTypeNameKey + 'No'), HighlightColorTag, '<Target>', Target.GetFullName(FullNameSeparator));
  ClearDialogChoices;
  AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
end;
{ @end $57C5E4 }

{ @routine $57CDE8 TfTalk_ShowPartnerOffer }
procedure TfTalk.ShowPartnerOffer(Action: Integer);
var
  Response: WideString;
begin
  if TalkShip.RelationToNonRanger(Player) < 45 then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Partner.Suspect');
    BuildStandardChoices;
    Exit;
  end;
  if TalkShip.PartnerShip <> nil then
  begin
    DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.AlreadyHavePartner'),
      HighlightColorTag, '<Partner>', (TalkShip.PartnerShip as TRanger).Name);
    BuildStandardChoices;
    Exit;
  end;
  if (TalkShip as TRanger).CountWingmen > 0 then
  begin
    DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.ILeader'),
      HighlightColorTag, '<Ranger>', Player.Name);
    BuildStandardChoices;
    Exit;
  end;
  if Player.BaseSkills[skLeadership] <= Player.CountWingmen then
  begin
    DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.NeedLeadership'),
      HighlightColorTag, '<Ranger>', Player.Name);
    BuildStandardChoices;
    Exit;
  end;
  if (TalkShip as TRanger).Rank > Player.Rank then
  begin
    DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.YouNeedInMoreRank'),
      HighlightColorTag, '<Ranger>', Player.Name);
    BuildStandardChoices;
    Exit;
  end;
  begin
    if TalkShip.BuildPartnershipOfferResponse(Player, Response, PartnerOfferAmount) then
      DialogText := FormatText2(TalkShip.LookupTalkText('Talk.Partner.ComputerSayOk'), HighlightColorTag,
        '<Money>', WideString(IntToStr(PartnerOfferAmount)), '<Month>',
        WideString(IntToStr(TalkShip.CalculatePartnershipMonths(PartnerOfferAmount,
          TalkShip.RelationToNonRanger(Player)))))
    else
      DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.ComputerSayNo'),
        HighlightColorTag, '<Money>', WideString(IntToStr(PartnerOfferAmount)));
    ClearDialogChoices;
    if TalkShip.BuildPartnershipOfferResponse(Player, Response, PartnerOfferAmount) then
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.PlayerOk'), 0, AcceptPartnerOffer);
    if PartnerOfferAmount div 2 > 0 then
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.PlayerLess'), 0, HalvePartnerOffer);
    if Player.Money > PartnerOfferAmount then
      AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.PlayerMore'), 0, DoublePartnerOffer);
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Cancel'), 0, ShowGreeting);
  end;
end;
{ @end $57CDE8 }

{ @routine $57D530 TfTalk_AcceptPartnerOffer }
procedure TfTalk.AcceptPartnerOffer(Action: Integer);
begin
  if TalkShip.AcceptPartnershipOffer(Player, DialogText, PartnerOfferAmount) then SoundManager.PlaySound('Sound.Sell');
  BuildStandardChoices;
end;
{ @end $57D530 }

{ @routine $57D594 TfTalk_HalvePartnerOffer }
procedure TfTalk.HalvePartnerOffer(Action: Integer);
begin
  PartnerOfferAmount := PartnerOfferAmount div 2;
  ShowPartnerOffer(0);
end;
{ @end $57D594 }

{ @routine $57D5B0 TfTalk_DoublePartnerOffer }
procedure TfTalk.DoublePartnerOffer(Action: Integer);
begin
  if Player.Money < PartnerOfferAmount * 2 then PartnerOfferAmount := Player.Money
  else PartnerOfferAmount := PartnerOfferAmount * 2;
  ShowPartnerOffer(0);
end;
{ @end $57D5B0 }

{ @routine $57D5E4 TfTalk_OrderPartnerFollow }
procedure TfTalk.OrderPartnerFollow(Action: Integer);
begin
  TalkShip.OrderFollowShip(Player, fmNear, True);
  DialogText := TalkShip.LookupTalkText('Talk.Partner.ComputerAgreeFlyToMe');
  if Player.CountPartnersInNormalSpace > 1 then
  begin
    DialogText := DialogText + #13#10;
    DialogText := DialogText + TalkShip.LookupTalkText('Talk.Partner.IsOrderForAll');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForAll'), 0, ApplyOrderToAllPartners);
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForYou'), 0, ExitPartnerConversation);
  end
  else
  begin
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end;
end;
{ @end $57D5E4 }

{ @routine $57D880 TfTalk_OrderPartnerLand }
procedure TfTalk.OrderPartnerLand(Action: Integer);
var
  Name: WideString;
begin
  TalkShip.OrderLanding(Player.OrderTarget, True);
  if Player.OrderTarget is TShip then Name := (Player.OrderTarget as TShip).Name
  else Name := (Player.OrderTarget as TPlanet).Name;
  DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.ComputerAgreeLandingToObject'), HighlightColorTag, '<ObjectName>', Name);
  if Player.CountPartnersInNormalSpace > 1 then
  begin
    DialogText := DialogText + #13#10;
    DialogText := DialogText + TalkShip.LookupTalkText('Talk.Partner.IsOrderForAll');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForAll'), 0, ApplyOrderToAllPartners);
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForYou'), 0, ExitPartnerConversation);
  end
  else
  begin
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end;
end;
{ @end $57D880 }

{ @routine $57DBF4 TfTalk_OrderPartnerJump }
procedure TfTalk.OrderPartnerJump(Action: Integer);
begin
  TalkShip.OrderJump(Player.OrderTarget as TStar, True);
  DialogText := FormatText1(TalkShip.LookupTalkText('Talk.Partner.ComputerAgreeFlyToStar'), HighlightColorTag, '<Star>',
    (Player.OrderTarget as TStar).Name);
  if Player.CountPartnersInNormalSpace > 1 then
  begin
    DialogText := DialogText + #13#10;
    DialogText := DialogText + TalkShip.LookupTalkText('Talk.Partner.IsOrderForAll');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForAll'), 0, ApplyOrderToAllPartners);
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Partner.OrderForYou'), 0, ExitPartnerConversation);
  end
  else
  begin
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end;
end;
{ @end $57DBF4 }

{ @routine $57DF18 TfTalk_OrderPartnerDropCargo }
procedure TfTalk.OrderPartnerDropCargo(Action: Integer);
begin
  TalkShip.ChangeRelationToRanger(Player, -Round(TalkShip.RandomInt(5, 15) / PlanetRaceMarket[OwnerToRace(TalkShip.OwnerId)].PirateRelationFactor));
  if TalkShip.GetRelationLevelToShip(Player) = rlHostile then TalkShip.ChangeRelationToRanger(Player, 10);
  if not Player.CanResolveObjectWithScanner(TalkShip) then
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Partner.ComputerDropCargoNo');
    ClearDialogChoices;
    AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
  end
  else
  begin
    DialogText := TalkShip.LookupTalkText('Talk.Partner.ComputerDropCargoOk');
    TalkShip.DropUnequippedItemsAndGoods;
    BuildStandardChoices;
  end;
end;
{ @end $57DF18 }
{ @routine $57E134 TfTalk_ApplyOrderToAllPartners }
procedure TfTalk.ApplyOrderToAllPartners(Action: Integer);
var
  I: Integer;
  Ship: TShip;
begin
  for I := 0 to Player.CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(Player.CurrentStar.Ships[I]);
    if (Player = Ship.PartnerShip) and Ship.InNormalSpace and (Player <> Ship) and (TalkShip <> Ship) then
    begin
      if Player = TalkShip.OrderTarget then Ship.OrderFollowShip(Player, fmNear, True)
      else if TalkShip.Order = soFollowShip then Ship.BuildAttackRequestResponse(Player, DialogText, TalkShip.OrderTarget as TShip)
      else if TalkShip.Order = soLanding then Ship.OrderLanding(Player.OrderTarget, True)
      else if TalkShip.Order = soJump then Ship.OrderJump(Player.OrderTarget as TStar, True);
    end;
  end;
  FastExit(0);
end;
{ @end $57E134 }

{ @routine $57E284 TfTalk_ExitPartnerConversation }
procedure TfTalk.ExitPartnerConversation(Action: Integer);
begin
  FastExit(0);
end;
{ @end $57E284 }

{ @routine $57E28C TfTalk_OrderTranclucatorReturn }
procedure TfTalk.OrderTranclucatorReturn(Action: Integer);
begin
  (TalkShip as TTranclucator).OrderFollowShip((TalkShip as TTranclucator).OwnerShip, fmMinWeaponRange, False);
  (TalkShip as TTranclucator).FollowOwner := True;
  DialogText := TalkShip.LookupTalkText('Talk.Tranclucator.Return.Ok');
  ClearDialogChoices;
  AddChoice('- ' + TalkShip.LookupTalkText('Talk.Exit'), 0, FastExit);
end;
{ @end $57E28C }

{ @routine $57E3E0 TfTalk_AddImmediateAttackChoices }
function TfTalk.AddImmediateAttackChoices: Boolean;
var I, J, N: Integer; Ship: TShip; RadarRangeSquared: Integer; Weapon: TWeapon;
begin
  Result := False;
  RadarRangeSquared := Player.GetRadarRange * Player.GetRadarRange;
  N := Player.CurrentStar.Ships.Count;
  for I := 0 to N - 1 do
  begin
    Ship := TShip(Player.CurrentStar.Ships[I]);
    if (Player <> Ship) and (TalkShip <> Ship) and Ship.InNormalSpace and
        (RadarRangeSquared > PointDistanceSquared(Player.Position, Ship.Position)) then
      begin
        if (Ship.GetRelationLevelToShip(Player) = rlHostile) and
          ((Player = Ship.OrderTarget) or (Player.OrderTarget = Ship)) then
        begin
          AddChoice('- ' + ReplaceColoredToken(TalkShip.LookupTalkText('Talk.Attack.RangerSend'), '<Target>', Ship.GetFullName(' '), ''), Integer(Ship), RequestAttackTarget);
          Result := True;
          Continue;
        end;
        if PendingPlayerFollowTarget = Ship then
        begin
          AddChoice('- ' + ReplaceColoredToken(TalkShip.LookupTalkText('Talk.Attack.RangerSend'), '<Target>', Ship.GetFullName(' '), ''), Integer(Ship), RequestAttackTarget);
          Result := True;
          Continue;
        end;
          for J := 1 to Player.WeaponCount do
          begin
            Weapon := Player.Weapons[J-1];
            if Weapon.Target = Ship then
            begin
              AddChoice('- ' + ReplaceColoredToken(TalkShip.LookupTalkText('Talk.Attack.RangerSend'), '<Target>', Ship.GetFullName(' '), ''), Integer(Ship), RequestAttackTarget);
              Result := True;
              Break;
            end;
          end;
      end;
  end;
end;
{ @end $57E3E0 }
{ @routine $57E6F8 TfTalk_GetShipGreeting }
function TfTalk.GetShipGreeting: WideString;
begin
  Result := TalkShip.GetGreetingText;
  if Result = '' then RaiseWideMessage('Не найдено приветствие корабля');
end;
{ @end $57E6F8 }
end.

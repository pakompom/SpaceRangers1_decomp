unit fIntroduction;
// Unit bracket (inferred): CODE 0x0054E8FC..0x0054F317; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop;
type
  TfIntroduction = class(TMessageLoopGI) // @size $C0
  public
    GenerationProgressTimer: TCallbackTimerIdGI; // @offset $B0
    TextScrollTimer: TCallbackTimerIdGI; // @offset $B4
    TextPanelTop: Integer; // @offset $B8
    TextPanelBottom: Integer; // @offset $BC
    procedure OnOpen; override; // @addr $54E988
    procedure OnClose; override; // @addr $54ED30
    procedure UpdateGenerationProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $54EDC0
    procedure ScrollIntroductionText(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $54F188
    procedure ContinueClicked(Sender: TObjectGI); // @addr $54F23C
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $54F250
    procedure SelectMusic; override; // @addr $54F2BC
  end;
var
  IntroductionPulseCounter: Integer = 0; // @addr $618778
  NewGameGenerationStage: Integer; // @addr $61CFC4 Direct writes in OnOpen $54E988; read by progress timer $54EDC0.
implementation

// @unit-initialization $54F310
// @unit-finalization $54F2E0

uses Classes, Windows, EC_Struct, EC_Str, GI_Label, GI_GraphBuf, GI_GraphButton,
  GR_Main, GR_Music, GR_GraphBuf, GlobalsV, aMyFunction, aPlayer, fGameSettings, Globals;

var
  IntroductionPulseRed: Byte; // @addr $61CFCC
  IntroductionPulseGreen: Byte; // @addr $61CFCD
  IntroductionPulseBlue: Byte; // @addr $61CFCE
  DisplayedGenerationStage: Integer; // @addr $61CFD0

{ @routine $54E988 TfIntroduction_OnOpen }
procedure TfIntroduction.OnOpen;
var Text: WideString;
begin
  DisplayedGenerationStage := 0;
  NewGameGenerationStage := 0;
  with GetByName('MsgCreateWorld') as TLabelGI do begin
    SetTextColor(CurrentPixelFormat.PackRgbBytes(IntroductionPulseRed, IntroductionPulseGreen, IntroductionPulseBlue));
    SetText(LocalizedText('FormIntroduction.MsgCreateWorld'));
  end;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  TextPanelTop := GiScalePixels(148);
  TextPanelBottom := GiScalePixels(620);
  with GetByName('Ok') as TGraphButtonGI do begin
    UpCallback := ContinueClicked;
    SetActive(False);
  end;
  Text := FormatText1(LocalizedText('FormIntroduction.Text'), HighlightColorTag, '<Player>', NewGameGenerationThread.CaptainName);
  with GetByName('GBText') as TGraphBufGI do begin
    SourceHasPerPixelAlpha := True;
    RenderLabelTextToBuffer(GraphBuf, ClientSize.X, 1, 0, Text, 'Font.' + GiResourceSuffix + 'Intro', $FFDBDA9C, $FF373737, $FFDBDA9C);
    SetSize(Classes.Point(ClientSize.X, GraphBuf.Height));
    SetPosition(Classes.Point(LocalPosition.X, TextPanelBottom));
  end;
  if GenerationProgressTimer <> 0 then begin
    CancelCallbackTimer(GenerationProgressTimer);
    GenerationProgressTimer := 0;
  end;
  GenerationProgressTimer := ScheduleCallbackTimer(20, 20, UpdateGenerationProgress);
  if TextScrollTimer <> 0 then begin
    CancelCallbackTimer(TextScrollTimer);
    TextScrollTimer := 0;
  end;
  TextScrollTimer := ScheduleCallbackTimer(20, 20, ScrollIntroductionText);
  IntroductionPulseRed := 20;
  IntroductionPulseGreen := 30;
  IntroductionPulseBlue := 50;
end;
{ @end $54E988 }

{ @routine $54ED30 TfIntroduction_OnClose }
procedure TfIntroduction.OnClose;
begin
  if GenerationProgressTimer <> 0 then begin
    CancelCallbackTimer(GenerationProgressTimer);
    GenerationProgressTimer := 0;
  end;
  if TextScrollTimer <> 0 then begin
    CancelCallbackTimer(TextScrollTimer);
    TextScrollTimer := 0;
  end;
  if NewGameGenerationThread <> nil then begin
    NewGameGenerationThread.Free;
    NewGameGenerationThread := nil;
  end;
  (GetByName('GBText') as TGraphBufGI).GraphBuf.Clear;
end;
{ @end $54ED30 }

{ @routine $54EDC0 TfIntroduction_UpdateGenerationProgress }
procedure TfIntroduction.UpdateGenerationProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Delta: Integer;
begin
  if IntroductionPulseCounter > 50 then Delta := -3 else Delta := 3;
  Inc(IntroductionPulseRed, Delta);
  Inc(IntroductionPulseGreen, Delta);
  Inc(IntroductionPulseBlue, Delta);
  IncrementWrapped(IntroductionPulseCounter, 0, 100);
  if (IntroductionPulseCounter = 0) or (IntroductionPulseRed <= 20) then begin
    IntroductionPulseRed := 20;
    IntroductionPulseGreen := 30;
    IntroductionPulseBlue := 50;
  end;
  with GetByName('MsgCreateWorld') as TLabelGI do begin
    SetTextColor(CurrentPixelFormat.PackRgbBytes(IntroductionPulseRed, IntroductionPulseGreen, IntroductionPulseBlue));
    if DisplayedGenerationStage < NewGameGenerationStage then begin
      if NewGameGenerationStage = 1 then SetText(LocalizedText('FormIntroduction.MsgCreateWorld1'));
      if NewGameGenerationStage = 2 then SetText(LocalizedText('FormIntroduction.MsgCreateWorld2'));
      if NewGameGenerationStage = 3 then SetText(LocalizedText('FormIntroduction.MsgCreateWorld3'));
      Inc(DisplayedGenerationStage);
    end;
  end;
  if not NewGameGenerationThread.IsRunning then begin
    if GenerationProgressTimer <> 0 then begin
      CancelCallbackTimer(GenerationProgressTimer);
      GenerationProgressTimer := 0;
    end;
    with GetByName('MsgCreateWorld') as TLabelGI do begin
      SetText(FormatText1(LocalizedText('FormIntroduction.MsgCreateWorldEnd'), HighlightColorTag, '<Planet>', Player.CurrentPlanet.Name));
      SetTextColor(CurrentPixelFormat.PackRgbBytes(120, 130, 150));
    end;
    (GetByName('Ok') as TGraphButtonGI).SetActive(True);
    NewGameGenerationThread.Free;
    NewGameGenerationThread := nil;
  end;
end;
{ @end $54EDC0 }

{ @routine $54F188 TfIntroduction_ScrollIntroductionText }
procedure TfIntroduction.ScrollIntroductionText(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Limit: Single;
begin
  with GetByName('GBText') as TGraphBufGI do begin
    SetPosition(AddPoints(LocalPosition, Classes.Point(0, -1)));
    Limit := (TextPanelTop + TextPanelBottom) div 2 - ClientSize.Y div 2;
    if LocalPosition.Y < Limit then
      if TextScrollTimer <> 0 then begin
        CancelCallbackTimer(TextScrollTimer);
        TextScrollTimer := 0;
      end;
  end;
end;
{ @end $54F188 }

{ @routine $54F23C TfIntroduction_ContinueClicked }
procedure TfIntroduction.ContinueClicked(Sender: TObjectGI);
begin
  RequestedScreenId := screenGovernment;
  RequestClose(1);
end;
{ @end $54F23C }

{ @routine $54F250 TfIntroduction_MainPanelKeyDown }
procedure TfIntroduction.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) and
    ((Key = VK_SPACE) or (Key = VK_RETURN) or (Key = VK_RIGHT)) then
    if GetByName('Ok').Active then ContinueClicked(nil);
end;
{ @end $54F250 }

{ @routine $54F2BC TfIntroduction_SelectMusic }
procedure TfIntroduction.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;
{ @end $54F2BC }

end.

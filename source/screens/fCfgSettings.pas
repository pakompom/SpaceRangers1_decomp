unit fCfgSettings;
// Unit bracket (inferred): CODE 0x00548288..0x0054DD03; inclusive evidence, not full bounds.

interface

uses EC_CacheFont, EC_BlockPar, GI_CountBar, GI_Image, GI_Label, GI_MessageLoop, GI_Panel, Types;

type
  TOptionSliderEvent = procedure(Sender: TCountBarGI) of object;

  TfCfgSettings = class(TMessageLoopGI) // @size $D4
  public
    ActiveGroupIndex: Integer; // @offset $B0
    BuildGroupIndex: Integer; // @offset $B4
    CurrentOptionName: WideString; // @offset $B8
    GroupPanels: array[0..2] of TPanelGI; // @offset $BC
    GroupNextY: array[0..2] of Integer; // @offset $C8

    procedure InitializeLayout; override; // @addr $548324
    procedure OnOpen; override; // @addr $548598
    procedure OnClose; override; // @addr $54A7E0
    procedure SelectMusic; override; // @addr $54DB34
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $54CC94
    procedure MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $54A7E4
    procedure ShowControlHelp(Sender: TObjectGI; Show: Boolean); // @addr $54A93C
    procedure GroupClicked(Sender: TObjectGI); // @addr $54A9A0
    procedure RefreshVisibleGroup; // @addr $54AA80
    procedure AddOptionLabel(OptionName, Caption: WideString; UnusedFlag: Boolean); // @addr $54ACB0
    procedure AddOptionChoice(Value: Integer; Caption: WideString; Selected, Disabled: Boolean); // @addr $54AF38
    procedure OptionChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $54B2EC
    procedure AddOptionSlider(Minimum, Maximum, Position: Integer; ShowValue: Boolean; Callback: TOptionSliderEvent); // @addr $54B440 @note "Invokes Callback immediately with the new slider."
    function HasOptionValue(OptionName: WideString): Boolean; // @addr $54B98C @note "Searches only the active group."
    function GetOptionValue(OptionName: WideString): Integer; // @addr $54BABC @note "Searches only the active group; raises when no selected choice or slider exists."
    procedure SetOptionValue(OptionName: WideString; Value: Integer); // @addr $54BC40 @note "Searches only the active group; missing options are ignored."
    procedure PreviewBrightness(Sender: TCountBarGI); // @addr $54BD1C @note "Changes display gamma before settings are applied."
    procedure PreviewContrast(Sender: TCountBarGI); // @addr $54BE3C @note "Changes display gamma before settings are applied."
    procedure FormatInteger(Sender: TCountBarGI); // @addr $54BF5C
    procedure HighPresetClicked(Sender: TObjectGI); // @addr $54BFD4
    procedure MediumPresetClicked(Sender: TObjectGI); // @addr $54C420
    procedure LowPresetClicked(Sender: TObjectGI); // @addr $54C840
    procedure CancelClicked(Sender: TObjectGI); // @addr $54CC5C
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $54CC78
    procedure ApplyClicked(Sender: TObjectGI); // @addr $54CD18 @note "Persists CFG.TXT; changes requiring rebuilt resources request another runtime session."
  end;

implementation

// @unit-initialization $54DCFC
// @unit-finalization $54DCCC
uses Classes, SysUtils, Math, Windows, EC_Str, EC_Struct, GI_GraphButton, GI_PanelScrollBar, GR_Main, Globals, GlobalsV, aConst, aMyFunction, GR_Sound, GR_Music, aPlayer, aPlanet, aShip;

{ @routine $548324 TfCfgSettings_InitializeLayout }
procedure TfCfgSettings.InitializeLayout;
begin
  inherited InitializeLayout;
  with GetByName('Cancel') as TGraphButtonGI do UpCallback := CancelClicked;
  (GetByName('Ok') as TGraphButtonGI).UpCallback := ApplyClicked;
  GetByName('MainPanel').MouseMoveCallback := MainPanelMouseMove;
  with GetByName('ButAUp') as TGraphButtonGI do UpCallback := HighPresetClicked;
  with GetByName('ButAMiddle') as TGraphButtonGI do UpCallback := MediumPresetClicked;
  with GetByName('ButADown') as TGraphButtonGI do UpCallback := LowPresetClicked;
  with GetByName('MainPanel') do KeyDownCallback := MainPanelKeyDown;
  with GetByName('ButGroup0') as TGraphButtonGI do
  begin
    UpCallback := GroupClicked;
    DownCallback := GroupClicked;
  end;
  with GetByName('ButGroup1') as TGraphButtonGI do
  begin
    UpCallback := GroupClicked;
    DownCallback := GroupClicked;
  end;
  with GetByName('ButGroup2') as TGraphButtonGI do
  begin
    UpCallback := GroupClicked;
    DownCallback := GroupClicked;
  end;
end;
{ @end $548324 }

{ @routine $548598 TfCfgSettings_OnOpen }
procedure TfCfgSettings.OnOpen;
var
  Panel: TPanelScrollBarGI;
  I: Integer;
  Language: WideString;
begin
  GetByName('LabelHelp').SetActive(False);
  Panel := GetByName('PanelSet') as TPanelScrollBarGI;
  Panel.FreeOwnedChildren;
  for I := 0 to 2 do
  begin
    GroupNextY[I] := 0;
    GroupPanels[I] := TPanelGI.Create(Panel);
    with GroupPanels[I] do
    begin
      SetSize(Classes.Point(Panel.ClientSize.X, 0));
      SetPosition(Classes.Point(0, 0));
      SetDepth(-100);
      SetPositionModeW(True);
    end;
  end;
  BuildGroupIndex := 0;
  AddOptionLabel('Lang', LocalizedText('FormCfgSettings.Lang'), True);
  for I := 0 to InstallConfig.GetBlock('Lang').GetParamCount - 1 do
  begin
    Language := InstallConfig.GetBlock('Lang').GetParamName(I);
    AddOptionChoice(I, ExtractDelimitedPartW(InstallConfig.GetBlock('Lang').GetParamValue(I), 0, ','), CurrentLanguage = Language, False);
  end;
  AddOptionLabel('CountFilmSave', LocalizedText('FormCfgSettings.CountFilmSave'), False);
  AddOptionSlider(1, 100, CountFilmSave, True, FormatInteger);
  AddOptionLabel('CacheSize', LocalizedText('FormCfgSettings.CacheSize'), False);
  AddOptionSlider(20, 150, GlobalCache.ResidentByteLimit div $100000, True, FormatInteger);
  AddOptionLabel('ScrollSpeed', LocalizedText('FormCfgSettings.ScrollSpeed'), False);
  AddOptionSlider(1, 80, ScrollSpeed, True, FormatInteger);
  AddOptionLabel('FilmSpeed', LocalizedText('FormCfgSettings.FilmSpeed'), False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.FilmSpeed0'), FilmSpeed = 0, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.FilmSpeed1'), FilmSpeed = 1, False);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.FilmSpeed2'), FilmSpeed = 2, False);
  AddOptionLabel('SkipGiper', LocalizedText('FormCfgSettings.SkipGiper'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), SkipHyperAnimation, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not SkipHyperAnimation, False);
  AddOptionLabel('ChangeAutoPilot', LocalizedText('FormCfgSettings.ChangeAutoPilot'), False);
  case ChangeAutoPilot of
    2, 4, 6, 20: ;
    else ChangeAutoPilot := 4;
  end;
  AddOptionChoice(2, LocalizedText('FormCfgSettings.CAP0'), ChangeAutoPilot = 2, False);
  AddOptionChoice(4, LocalizedText('FormCfgSettings.CAP1'), ChangeAutoPilot = 4, False);
  AddOptionChoice(6, LocalizedText('FormCfgSettings.CAP2'), ChangeAutoPilot = 6, False);
  AddOptionChoice(20, LocalizedText('FormCfgSettings.CAP3'), ChangeAutoPilot = 20, False);
  BuildGroupIndex := 1;
  AddOptionLabel('Resolution', LocalizedText('FormCfgSettings.Resolution'), True);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.Resolution1024'), GiResourceVariant = 2, not IsInstallFeatureEnabled('Resolution_R2'));
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Resolution800'), GiResourceVariant = 1, not IsInstallFeatureEnabled('Resolution_R1'));
  if GammaControl <> nil then
  begin
  AddOptionLabel('Brightness', LocalizedText('FormCfgSettings.Brightness'), False);
  AddOptionSlider(0, 100, Round(Brightness * 50 + 50), True, PreviewBrightness);
  AddOptionLabel('Contrast', LocalizedText('FormCfgSettings.Contrast'), False);
  AddOptionSlider(0, 100, Round(Contrast * 50 + 50), True, PreviewContrast);
  end;
  AddOptionLabel('BGImage', LocalizedText('FormCfgSettings.BGImage'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), BGImage, not IsInstallFeatureEnabled('BGImage'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not BGImage, False);
  AddOptionLabel('AnimCaptain', LocalizedText('FormCfgSettings.AnimCaptain'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), AnimCaptain, not IsInstallFeatureEnabled('AnimCaptain'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not AnimCaptain, False);
  AddOptionLabel('AnimShip', LocalizedText('FormCfgSettings.AnimShip'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.AnimShipFull'), AnimShipFull, not IsInstallFeatureEnabled('AnimShipFull'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.AnimShipSmall'), not AnimShipFull, not IsInstallFeatureEnabled('AnimShipSmall'));
  AddOptionLabel('AnimItem', LocalizedText('FormCfgSettings.AnimItem'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), AnimItem, not IsInstallFeatureEnabled('AnimItem'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not AnimItem, False);
  AddOptionLabel('AnimGov', LocalizedText('FormCfgSettings.AnimGov'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), AnimGov, not IsInstallFeatureEnabled('AnimGov'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not AnimGov, False);
  AddOptionLabel('AnimHangar', LocalizedText('FormCfgSettings.AnimHangar'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), AnimHangar, not IsInstallFeatureEnabled('AnimHangar'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not AnimHangar, False);
  AddOptionLabel('AnimStar', LocalizedText('FormCfgSettings.AnimStar'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), AnimStar, not IsInstallFeatureEnabled('AnimStar'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not AnimStar, False);
  AddOptionLabel('SpaceImage', LocalizedText('FormCfgSettings.SpaceImage'), False);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.CometLarge'), SpaceImage >= 2, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.CometSmall'), SpaceImage = 1, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.CometOff'), SpaceImage = 0, False);
  AddOptionLabel('SputnikShow', LocalizedText('FormCfgSettings.SputnikShow'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), SputnikShow, not IsInstallFeatureEnabled('SputnikShow'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not SputnikShow, False);
  AddOptionLabel('CircleAction', LocalizedText('FormCfgSettings.CircleAction'), False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.CircleActionNormal'), not HideActionCircle, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.CircleActionHide'), HideActionCircle, False);
  AddOptionLabel('Tail', LocalizedText('FormCfgSettings.Tails'), False);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.TailAll'), ShipTail = 2, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.TailPlayer'), ShipTail = 1, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.TailOff'), ShipTail = 0, False);
  AddOptionLabel('Comet', LocalizedText('FormCfgSettings.Comet'), False);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.CometLarge'), CometDensity >= 2, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.CometSmall'), CometDensity = 1, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.CometOff'), CometDensity = 0, False);
  AddOptionLabel('Wind', LocalizedText('FormCfgSettings.Wind'), False);
  AddOptionChoice(2, LocalizedText('FormCfgSettings.WindFull'), WindDensity >= 2, False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.WindSmall'), WindDensity = 1, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.WindOff'), WindDensity = 0, False);
  AddOptionLabel('ShowFPS', LocalizedText('FormCfgSettings.ShowFPS'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), ShowFPS, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not ShowFPS, False);
  BuildGroupIndex := 2;
  AddOptionLabel('Sound', LocalizedText('FormCfgSettings.Sound'), True);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), SoundEnabled, not IsInstallFeatureEnabled('Sound'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not SoundEnabled, False);
  AddOptionLabel('SoundInSpace', LocalizedText('FormCfgSettings.SoundInSpace'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), SoundInSpaceEnabled, not IsInstallFeatureEnabled('SoundInSpace'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not SoundInSpaceEnabled, False);
  AddOptionLabel('SoundVolume', LocalizedText('FormCfgSettings.SoundVolume'), False);
  AddOptionSlider(0, 100, Round(SoundVolume * 100), True, FormatInteger);
  AddOptionLabel('Music', LocalizedText('FormCfgSettings.Music'), True);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), MusicEnabled, not IsInstallFeatureEnabled('Music'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not MusicEnabled, False);
  AddOptionLabel('MusicInSpace', LocalizedText('FormCfgSettings.MusicInSpace'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), MusicInSpace, not IsInstallFeatureEnabled('MusicInSpace'));
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not MusicInSpace, False);
  AddOptionLabel('MusicVolume', LocalizedText('FormCfgSettings.MusicVolume'), False);
  AddOptionSlider(0, 100, Round(MusicVolume * 100), True, FormatInteger);
  AddOptionLabel('MusicInHyper', LocalizedText('FormCfgSettings.MusicInHyper'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), MusicInHyper, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not MusicInHyper, False);
  AddOptionLabel('MusicInPlanet', LocalizedText('FormCfgSettings.MusicInPlanet'), False);
  AddOptionChoice(1, LocalizedText('FormCfgSettings.Yes'), MusicInPlanet, False);
  AddOptionChoice(0, LocalizedText('FormCfgSettings.No'), not MusicInPlanet, False);
  for I := 0 to 2 do
    with GroupPanels[I] do SetSize(Classes.Point(ClientSize.X, GroupNextY[I]));
  Panel.VerticalScrollBar.SetSmallChange((GetByName('ButGroup0') as TGraphButtonGI).CaptionLabel.GetLineHeight);
  Panel.VerticalScrollBar.SetLargeChange(Panel.ClientSize.Y);
  Panel.VerticalScrollBar.SetPageSize(Panel.ClientSize.Y);
  ActiveGroupIndex := 0;
  RefreshVisibleGroup;
end;
{ @end $548598 }

{ @routine $54A7E0 TfCfgSettings_OnClose }
procedure TfCfgSettings.OnClose;
begin
end;
{ @end $54A7E0 }

{ @routine $54A7E4 TfCfgSettings_MainPanelMouseMove }
procedure TfCfgSettings.MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Button: TGraphButtonGI; Show: Boolean;
begin
  Button := nil;
  Show := False;
  while True do
  begin
    Button := GetByName('ButAUp') as TGraphButtonGI;
    Show := Button.HitTest(Point);
    if Show then Break;
    Button := GetByName('ButAMiddle') as TGraphButtonGI;
    Show := Button.HitTest(Point);
    if Show then Break;
    Button := GetByName('ButADown') as TGraphButtonGI;
    Show := Button.HitTest(Point);
    if Show then Break;
    Button := GetByName('Cancel') as TGraphButtonGI;
    Show := Button.HitTest(Point);
    if Show then Break;
    Button := GetByName('Ok') as TGraphButtonGI;
    Show := Button.HitTest(Point);
    if Show then Break;
    Break;
  end;
  ShowControlHelp(Button, Show);
end;
{ @end $54A7E4 }

{ @routine $54A93C TfCfgSettings_ShowControlHelp }
procedure TfCfgSettings.ShowControlHelp(Sender: TObjectGI; Show: Boolean);
var LabelControl: TLabelGI;
begin
  LabelControl := GetByName('LabelHelp') as TLabelGI;
    if Sender.HelpText = '' then Show := False;
    LabelControl.SetActive(Show);
    LabelControl.SetText(Sender.HelpText);
end;
{ @end $54A93C }

{ @routine $54A9A0 TfCfgSettings_GroupClicked }
procedure TfCfgSettings.GroupClicked(Sender: TObjectGI);
var Group: Integer;
begin
  Group := ExtractDigitsToIntW(Sender.ControlName);
  (GetByName('ButGroup0') as TGraphButtonGI).SetDown(Group = 0);
  (GetByName('ButGroup1') as TGraphButtonGI).SetDown(Group = 1);
  (GetByName('ButGroup2') as TGraphButtonGI).SetDown(Group = 2);
  if ActiveGroupIndex <> Group then
  begin
    ActiveGroupIndex := ExtractDigitsToIntW(Sender.ControlName);
    RefreshVisibleGroup;
  end;
end;
{ @end $54A9A0 }

{ @routine $54AA80 TfCfgSettings_RefreshVisibleGroup }
procedure TfCfgSettings.RefreshVisibleGroup;
var I: Integer;
begin
  with GetByName('ButGroup0') as TGraphButtonGI do
  begin
    SetDown(ActiveGroupIndex = 0);
    if Down then SetCaptionColor(CurrentPixelFormat.PackRgbBytes(250, 255, 218))
    else SetCaptionColor(CurrentPixelFormat.PackRgbBytes(169, 211, 255));
  end;
  with GetByName('ButGroup1') as TGraphButtonGI do
  begin
    SetDown(ActiveGroupIndex = 1);
    if Down then SetCaptionColor(CurrentPixelFormat.PackRgbBytes(250, 255, 218))
    else SetCaptionColor(CurrentPixelFormat.PackRgbBytes(169, 211, 255));
  end;
  with GetByName('ButGroup2') as TGraphButtonGI do
  begin
    SetDown(ActiveGroupIndex = 2);
    if Down then SetCaptionColor(CurrentPixelFormat.PackRgbBytes(250, 255, 218))
    else SetCaptionColor(CurrentPixelFormat.PackRgbBytes(169, 211, 255));
  end;
  for I := 0 to 2 do
    with GroupPanels[I] do SetActive(I = ActiveGroupIndex);
  with GetByName('PanelSet') as TPanelScrollBarGI do
  begin
    SetScrollOffset(Classes.Point(0, 0));
    UpdateScrollRanges;
    SetVerticalScrollbarEnabled(GroupNextY[ActiveGroupIndex] > ClientSize.Y);
  end;
end;
{ @end $54AA80 }

{ @routine $54ACB0 TfCfgSettings_AddOptionLabel }
procedure TfCfgSettings.AddOptionLabel(OptionName, Caption: WideString; UnusedFlag: Boolean);
begin
  CurrentOptionName := OptionName;
  Inc(GroupNextY[BuildGroupIndex], GiScalePixels(5));
  with TLabelGI.Create(GroupPanels[BuildGroupIndex]) do
  begin
    SetFontName(NormalFontName);
    SetPositionModeW(False);
    SetPosition(Classes.Point(0, GroupNextY[BuildGroupIndex]));
    SetSize(Classes.Point(GroupPanels[BuildGroupIndex].ClientSize.X, 1));
    SetTextAlignX(taxLeft);
    SetTextAlignY(tayAuto);
    SetTextColor(CurrentPixelFormat.PackRgbBytes(250, 255, 218));
    SetText(Caption);
    SetTextAlignY(tayTop);
    SetSize(Classes.Point(ClientSize.X, ClientSize.Y + 1));
    GroupNextY[BuildGroupIndex] := GroupNextY[BuildGroupIndex] + ClientSize.Y + 2;
  end;
  with TImageGI.Create(GroupPanels[BuildGroupIndex]) do
  begin
    SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'Line');
    SetPosition(Classes.Point(0, GroupNextY[BuildGroupIndex]));
    SetSize(Classes.Point(GroupPanels[BuildGroupIndex].ClientSize.X, GetContentSize.Y + 4));
    GroupNextY[BuildGroupIndex] := GroupNextY[BuildGroupIndex] + ClientSize.Y + 2 + GiScalePixels(8);
  end;
end;
{ @end $54ACB0 }

{ @routine $54AF38 TfCfgSettings_AddOptionChoice }
procedure TfCfgSettings.AddOptionChoice(Value: Integer; Caption: WideString; Selected, Disabled: Boolean);
var Image: TImageGI; ValueLabel: TLabelGI;
begin
  ValueLabel := TLabelGI.Create(GroupPanels[BuildGroupIndex]);
  ValueLabel.SetFontName(NormalFontName);
  ValueLabel.SetPositionModeW(False);
  ValueLabel.SetPosition(Classes.Point(0, GroupNextY[BuildGroupIndex]));
  ValueLabel.SetSize(Classes.Point(GroupPanels[BuildGroupIndex].ClientSize.X, 1));
  ValueLabel.SetTextAlignX(taxRight);
  ValueLabel.SetTextAlignY(tayAuto);
  if Selected then ValueLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes(250, 255, 218))
  else ValueLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes(169, 211, 255));
  ValueLabel.SetTextAlignY(tayTop);
  ValueLabel.SetSize(Classes.Point(ValueLabel.ClientSize.X, ValueLabel.ClientSize.Y + 1));
  ValueLabel.SetText(Caption);
  ValueLabel.SetTextAlignY(tayCenterEx);
  Image := TImageGI.Create(GroupPanels[BuildGroupIndex]);
  if Disabled then Image.SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchD')
  else if not Selected then Image.SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchN')
  else Image.SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchA');
  Image.SetPosition(Classes.Point(GroupPanels[BuildGroupIndex].ClientSize.X - Image.GetContentSize.X, GroupNextY[BuildGroupIndex]));
  Image.SetSize(Image.GetContentSize);
  Image.SetImageKindY(ikyCenter);
  if not Disabled then Image.LeftButtonDownCallback := OptionChoiceMouseDown;
  if not Disabled then Image.SetName(CurrentOptionName);
  Image.UserValue := Value;
  ValueLabel.SetSize(Classes.Point(ValueLabel.ClientSize.X - Image.ClientSize.X - 10, Max(ValueLabel.ClientSize.Y, Image.ClientSize.Y) + 2));
  Image.SetSize(Classes.Point(Image.ClientSize.X, Max(ValueLabel.ClientSize.Y, Image.ClientSize.Y) + 2));
  GroupNextY[BuildGroupIndex] := GroupNextY[BuildGroupIndex] + Image.ClientSize.Y - GiScalePixels(5);
end;
{ @end $54AF38 }

{ @routine $54B2EC TfCfgSettings_OptionChoiceMouseDown }
procedure TfCfgSettings.OptionChoiceMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Control: TObjectGI;
begin
  Control := GroupPanels[ActiveGroupIndex].FirstChild;
  while Control <> nil do
  begin
    if Control.ControlName = Sender.ControlName then
      if Control = Sender then
        (Control as TImageGI).SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchA')
      else (Control as TImageGI).SetImagePath('GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchN');
    Control := Control.NextSibling;
  end;
end;
{ @end $54B2EC }

{ @routine $54B440 TfCfgSettings_AddOptionSlider }
procedure TfCfgSettings.AddOptionSlider(Minimum, Maximum, Position: Integer; ShowValue: Boolean; Callback: TOptionSliderEvent);
var Slider: TCountBarGI; ValueLabel: TLabelGI;
begin
  Slider := TCountBarGI.Create(GroupPanels[BuildGroupIndex]);
  Inc(GroupNextY[BuildGroupIndex], 20);
  Slider.SetPositionModeW(False);
  if GiResourceVariant = 2 then Slider.SetSize(Classes.Point(168, 17))
  else Slider.SetSize(Classes.Point(131, 13));
  TObjectGI(Slider).SetPosition(Classes.Point(GroupPanels[BuildGroupIndex].ClientSize.X - Slider.ClientSize.X, GroupNextY[BuildGroupIndex]));
  Slider.DecreaseButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftN');
  Slider.DecreaseButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftA');
  Slider.DecreaseButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftD');
  Slider.IncreaseButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightN');
  Slider.IncreaseButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightA');
  Slider.IncreaseButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightD');
  Slider.AfterThumbImage.SetImagePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeft');
  Slider.BeforeThumbImage.SetImagePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRight');
  Slider.ThumbButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolN');
  Slider.ThumbButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolA');
  Slider.ThumbButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolD');
  Slider.PositionChangedCallback := TObjectNotifyEventGI(Callback);
  Slider.UpdateLayout;
  Slider.SetRange(Minimum, Maximum);
  Slider.SetPositionInternal(Position);
  Slider.SetName(CurrentOptionName);
  GroupNextY[BuildGroupIndex] := GroupNextY[BuildGroupIndex] + Slider.ClientSize.Y + 20;
  if ShowValue then
  begin
    ValueLabel := TLabelGI.Create(GroupPanels[BuildGroupIndex]);
    ValueLabel.SetFontName(NormalFontName);
    ValueLabel.SetPosition(Classes.Point(0, Slider.LocalPosition.Y - 13));
    ValueLabel.SetSize(Classes.Point(Slider.LocalPosition.X - 10, Slider.ClientSize.Y + 20));
    ValueLabel.SetPositionModeW(False);
    ValueLabel.SetTextAlignX(taxRight);
    ValueLabel.SetTextAlignY(tayCenter);
      Slider.UserIndex := Integer(ValueLabel);
    if Assigned(Callback) then Callback(Slider);
  end;
end;
{ @end $54B440 }

{ @routine $54B98C TfCfgSettings_HasOptionValue }
function TfCfgSettings.HasOptionValue(OptionName: WideString): Boolean;
var Control: TObjectGI;
begin
  Control := GroupPanels[ActiveGroupIndex].FirstChild;
  while Control <> nil do
  begin
    if Control.ControlName = OptionName then
      if Control is TImageGI then
      begin
        if (Control as TImageGI).GetImagePath = 'GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchA' then
        begin
          Result := True;
          Exit;
        end;
      end
      else if Control is TCountBarGI then
      begin
        Result := True;
        Exit;
      end;
    Control := Control.NextSibling;
  end;
  Result := False;
end;
{ @end $54B98C }

{ @routine $54BABC TfCfgSettings_GetOptionValue }
function TfCfgSettings.GetOptionValue(OptionName: WideString): Integer;
var Control: TObjectGI;
begin
  Result := 0;
  Control := GroupPanels[ActiveGroupIndex].FirstChild;
  while Control <> nil do
  begin
    if Control.ControlName = OptionName then
      if Control is TImageGI then
      begin
        if (Control as TImageGI).GetImagePath = 'GI,Bm.FormOptions.' + GiResourceSuffix + 'SwitchA' then
        begin
          Result := Control.UserValue;
          Exit;
        end;
      end
      else if Control is TCountBarGI then
      begin
        Result := (Control as TCountBarGI).Position;
        Exit;
      end;
    Control := Control.NextSibling;
  end;
  RaiseWideMessage('UnitGet Type=' + OptionName);
end;
{ @end $54BABC }
{ @routine $54BC40 TfCfgSettings_SetOptionValue }
procedure TfCfgSettings.SetOptionValue(OptionName: WideString; Value: Integer);
var Control: TObjectGI;
begin
  Control := GroupPanels[ActiveGroupIndex].FirstChild;
  while Control <> nil do
  begin
    if Control.ControlName = OptionName then
    begin
      if (Control is TImageGI) and (Control.UserValue = Value) and Assigned(Control.LeftButtonDownCallback) then
      begin
        OptionChoiceMouseDown(Control, 0, Classes.Point(0, 0));
        Break;
      end
      else if Control is TCountBarGI then
      begin
        (Control as TCountBarGI).SetPosition(Value);
        Break;
      end;
    end;
    Control := Control.NextSibling;
  end;
end;
{ @end $54BC40 }

{ @routine $54BD1C TfCfgSettings_PreviewBrightness }
procedure TfCfgSettings.PreviewBrightness(Sender: TCountBarGI);
var ValueLabel: TLabelGI;
begin
  if HasOptionValue('Contrast') and HasOptionValue('Brightness') then
  begin
    ApplyGammaRamp((GetOptionValue('Brightness') - 50) / 50.0, (GetOptionValue('Contrast') - 50) / 50.0);
  end;
  if Sender.UserIndex <> 0 then
  begin
    ValueLabel := TLabelGI(Sender.UserIndex);
    ValueLabel.SetText(IntToStr(Sender.Position));
  end;
end;
{ @end $54BD1C }

{ @routine $54BE3C TfCfgSettings_PreviewContrast }
procedure TfCfgSettings.PreviewContrast(Sender: TCountBarGI);
var ValueLabel: TLabelGI;
begin
  if HasOptionValue('Contrast') and HasOptionValue('Brightness') then
  begin
    ApplyGammaRamp((GetOptionValue('Brightness') - 50) / 50.0, (GetOptionValue('Contrast') - 50) / 50.0);
  end;
  if Sender.UserIndex <> 0 then
  begin
    ValueLabel := TLabelGI(Sender.UserIndex);
    ValueLabel.SetText(IntToStr(Sender.Position));
  end;
end;
{ @end $54BE3C }

{ @routine $54BF5C TfCfgSettings_FormatInteger }
procedure TfCfgSettings.FormatInteger(Sender: TCountBarGI);
var ValueLabel: TLabelGI;
begin
  if Sender.UserIndex <> 0 then
  begin
    ValueLabel := TLabelGI(Sender.UserIndex);
    ValueLabel.SetText(IntToStr(Sender.Position));
  end;
end;
{ @end $54BF5C }

{ @routine $54BFD4 TfCfgSettings_HighPresetClicked }
procedure TfCfgSettings.HighPresetClicked(Sender: TObjectGI);
var SavedGroup: Integer;
begin
  SavedGroup := ActiveGroupIndex;
  ActiveGroupIndex := 0;
  SetOptionValue('CountFilmSave', 30);
  SetOptionValue('CacheSize', 130);
  SetOptionValue('ScrollSpeed', 20);
  ActiveGroupIndex := 1;
  SetOptionValue('Resolution', 2);
  if GammaControl <> nil then
  begin
  SetOptionValue('Brightness', 50);
  SetOptionValue('Contrast', 50);
  end;
  SetOptionValue('BGImage', 1);
  SetOptionValue('AnimCaptain', 1);
  SetOptionValue('AnimShip', 1);
  SetOptionValue('AnimItem', 1);
  SetOptionValue('AnimGov', 1);
  SetOptionValue('AnimHangar', 1);
  SetOptionValue('AnimStar', 1);
  SetOptionValue('SpaceImage', 2);
  SetOptionValue('SputnikShow', 1);
  SetOptionValue('CircleAction', 0);
  SetOptionValue('Tail', 2);
  SetOptionValue('Comet', 2);
  SetOptionValue('Wind', 2);
  ActiveGroupIndex := 2;
  SetOptionValue('Sound', 1);
  SetOptionValue('SoundInSpace', 1);
  SetOptionValue('SoundVolume', 100);
  SetOptionValue('Music', 1);
  SetOptionValue('MusicInSpace', 1);
  SetOptionValue('MusicVolume', 75);
  ActiveGroupIndex := SavedGroup;
end;
{ @end $54BFD4 }

{ @routine $54C420 TfCfgSettings_MediumPresetClicked }
procedure TfCfgSettings.MediumPresetClicked(Sender: TObjectGI);
var SavedGroup: Integer;
begin
  SavedGroup := ActiveGroupIndex;
  ActiveGroupIndex := 0;
  SetOptionValue('CountFilmSave', 20);
  SetOptionValue('CacheSize', 60);
  SetOptionValue('ScrollSpeed', 20);
  ActiveGroupIndex := 1;
  if GammaControl <> nil then
  begin
  SetOptionValue('Brightness', 50);
  SetOptionValue('Contrast', 50);
  end;
  SetOptionValue('BGImage', 1);
  SetOptionValue('AnimCaptain', 1);
  SetOptionValue('AnimShip', 1);
  SetOptionValue('AnimItem', 1);
  SetOptionValue('AnimGov', 1);
  SetOptionValue('AnimHangar', 1);
  SetOptionValue('AnimStar', 1);
  SetOptionValue('SpaceImage', 1);
  SetOptionValue('SputnikShow', 1);
  SetOptionValue('CircleAction', 0);
  SetOptionValue('Tail', 1);
  SetOptionValue('Comet', 1);
  SetOptionValue('Wind', 1);
  ActiveGroupIndex := 2;
  SetOptionValue('Sound', 1);
  SetOptionValue('SoundInSpace', 1);
  SetOptionValue('SoundVolume', 100);
  SetOptionValue('Music', 1);
  SetOptionValue('MusicInSpace', 1);
  SetOptionValue('MusicVolume', 75);
  ActiveGroupIndex := SavedGroup;
end;
{ @end $54C420 }

{ @routine $54C840 TfCfgSettings_LowPresetClicked }
procedure TfCfgSettings.LowPresetClicked(Sender: TObjectGI);
var SavedGroup: Integer;
begin
  SavedGroup := ActiveGroupIndex;
  ActiveGroupIndex := 0;
  SetOptionValue('CountFilmSave', 1);
  SetOptionValue('CacheSize', 30);
  SetOptionValue('ScrollSpeed', 20);
  ActiveGroupIndex := 1;
  SetOptionValue('Resolution', 1);
  if GammaControl <> nil then
  begin
  SetOptionValue('Brightness', 50);
  SetOptionValue('Contrast', 50);
  end;
  SetOptionValue('BGImage', 0);
  SetOptionValue('AnimCaptain', 0);
  SetOptionValue('AnimShip', 0);
  SetOptionValue('AnimItem', 0);
  SetOptionValue('AnimGov', 0);
  SetOptionValue('AnimHangar', 0);
  SetOptionValue('AnimStar', 0);
  SetOptionValue('SpaceImage', 0);
  SetOptionValue('SputnikShow', 0);
  SetOptionValue('CircleAction', 0);
  SetOptionValue('Tail', 0);
  SetOptionValue('Comet', 0);
  SetOptionValue('Wind', 0);
  ActiveGroupIndex := 2;
  SetOptionValue('Sound', 0);
  SetOptionValue('SoundInSpace', 0);
  SetOptionValue('SoundVolume', 100);
  SetOptionValue('Music', 0);
  SetOptionValue('MusicInSpace', 0);
  SetOptionValue('MusicVolume', 75);
  ActiveGroupIndex := SavedGroup;
end;
{ @end $54C840 }

{ @routine $54CC5C TfCfgSettings_CancelClicked }
procedure TfCfgSettings.CancelClicked(Sender: TObjectGI);
begin
  RequestedScreenId := SettingsReturnScreenId;
  RequestClose(1);
end;
{ @end $54CC5C }

{ @routine $54CC78 TfCfgSettings_MainPanelKeyDown }
procedure TfCfgSettings.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_ESCAPE then CancelClicked(nil)
  else if Key = VK_RETURN then ApplyClicked(nil);
end;
{ @end $54CC78 }

{ @routine $54CC94 TfCfgSettings_ProcessMouseWheel }
procedure TfCfgSettings.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  with GetByName('PanelSet') as TPanelScrollBarGI do
    if Delta = WHEEL_DELTA then VerticalScrollBar.SetPosition(VerticalScrollBar.Position - VerticalScrollBar.SmallChange)
    else if Delta = -WHEEL_DELTA then VerticalScrollBar.SetPosition(VerticalScrollBar.Position + VerticalScrollBar.SmallChange);
end;
{ @end $54CC94 }

{ @routine $54CD18 TfCfgSettings_ApplyClicked }
procedure TfCfgSettings.ApplyClicked(Sender: TObjectGI);
var
  RestartRequired: Boolean;
  Language: WideString;
  Buffer: TSoundBuffer;
begin
  RestartRequired := False;
  ActiveGroupIndex := 0;
  Language := InstallConfig.GetBlock('Lang').GetParamName(GetOptionValue('Lang'));
  if Language <> CurrentLanguage then
  begin
    RestartRequired := True;
    Config.SetOrAddParam('Lang', Language);
  end;
  CountFilmSave := GetOptionValue('CountFilmSave');
  Config.SetOrAddParam('CountFilmSave', IntToStr(CountFilmSave));
  GlobalCache.ResidentByteLimit := GetOptionValue('CacheSize') shl 20;
  Config.SetOrAddParam('CacheSize', IntToStr(GetOptionValue('CacheSize')));
  ScrollSpeed := GetOptionValue('ScrollSpeed');
  Config.SetOrAddParam('ScrollStep', IntToStr(ScrollSpeed));
  FilmSpeed := GetOptionValue('FilmSpeed');
  Config.SetOrAddParam('FilmSpeed', IntToStr(FilmSpeed));
  SkipHyperAnimation := Boolean(GetOptionValue('SkipGiper'));
  Config.SetOrAddParam('SkipGiper', BoolToWideString(SkipHyperAnimation));
  ChangeAutoPilot := GetOptionValue('ChangeAutoPilot');
  Config.SetOrAddParam('ChangeAutoPilot', IntToStr(ChangeAutoPilot));
  ActiveGroupIndex := 1;
  if GetOptionValue('Resolution') = 1 then
  begin
    if GiResourceVariant <> 1 then
    begin
      RestartRequired := True;
      Config.SetOrAddParam('VideoMode', 'R1');
    end;
  end
  else if GiResourceVariant <> 2 then
  begin
    RestartRequired := True;
    Config.SetOrAddParam('VideoMode', 'R2');
  end;
  if GammaControl <> nil then
  begin
    Brightness := (GetOptionValue('Brightness') - 50) / 50;
    Contrast := (GetOptionValue('Contrast') - 50) / 50;
    Config.SetOrAddParam('Brightness', Format('%.2f', [Brightness]));
    Config.SetOrAddParam('Contrast', Format('%.2f', [Contrast]));
    ApplyGammaRamp(Brightness, Contrast);
  end;
  BGImage := Boolean(GetOptionValue('BGImage'));
  Config.SetOrAddParam('BGImage', BoolToWideString(BGImage));
  AnimCaptain := Boolean(GetOptionValue('AnimCaptain'));
  Config.SetOrAddParam('AnimCaptain', BoolToWideString(AnimCaptain));
  AnimShipFull := Boolean(GetOptionValue('AnimShip'));
  Config.SetOrAddParam('AnimShipFull', BoolToWideString(AnimShipFull));
  AnimItem := Boolean(GetOptionValue('AnimItem'));
  Config.SetOrAddParam('AnimItem', BoolToWideString(AnimItem));
  AnimGov := Boolean(GetOptionValue('AnimGov'));
  Config.SetOrAddParam('AnimGov', BoolToWideString(AnimGov));
  AnimHangar := Boolean(GetOptionValue('AnimHangar'));
  Config.SetOrAddParam('AnimHangar', BoolToWideString(AnimHangar));
  AnimStar := Boolean(GetOptionValue('AnimStar'));
  Config.SetOrAddParam('AnimStar', BoolToWideString(AnimStar));
  if GetOptionValue('SpaceImage') <> SpaceImage then
  begin
    SpaceImage := GetOptionValue('SpaceImage');
    if (Galaxy <> nil) and (SpaceImage > 0) then Galaxy.GenerateSpaceBackground;
    Config.SetOrAddParam('SpaceImage', IntToStr(SpaceImage));
  end;
  SputnikShow := Boolean(GetOptionValue('SputnikShow'));
  Config.SetOrAddParam('SputnikShow', BoolToWideString(SputnikShow));
  HideActionCircle := Boolean(GetOptionValue('CircleAction'));
  Config.SetOrAddParam('CircleAction', BoolToWideString(HideActionCircle));
  ShipTail := GetOptionValue('Tail');
  Config.SetOrAddParam('ShipTail', IntToStr(ShipTail));
  CometDensity := GetOptionValue('Comet');
  Config.SetOrAddParam('Comet', IntToStr(CometDensity));
  WindDensity := GetOptionValue('Wind');
  Config.SetOrAddParam('Wind', IntToStr(WindDensity));
  ShowFPS := Boolean(GetOptionValue('ShowFPS'));
  Config.SetOrAddParam('ShowFPS', BoolToWideString(ShowFPS));
  ActiveGroupIndex := 2;
  if Boolean(GetOptionValue('Sound')) <> SoundEnabled then
  begin
    Config.SetOrAddParam('Sound', BoolToWideString(not SoundEnabled));
    RestartRequired := True;
  end;
  SoundInSpaceEnabled := Boolean(GetOptionValue('SoundInSpace'));
  Config.SetOrAddParam('SoundInSpace', BoolToWideString(SoundInSpaceEnabled));
  SoundVolume := GetOptionValue('SoundVolume') / 100;
  Config.SetOrAddParam('SoundVolume', IntToStr(GetOptionValue('SoundVolume')));
  if Boolean(GetOptionValue('Music')) <> MusicEnabled then
  begin
    Config.SetOrAddParam('Music', BoolToWideString(not MusicEnabled));
    RestartRequired := True;
  end;
  MusicInSpace := Boolean(GetOptionValue('MusicInSpace'));
  Config.SetOrAddParam('MusicInSpace', BoolToWideString(MusicInSpace));
  MusicVolume := GetOptionValue('MusicVolume') / 100;
  Config.SetOrAddParam('MusicVolume', IntToStr(GetOptionValue('MusicVolume')));
  MusicInHyper := Boolean(GetOptionValue('MusicInHyper'));
  Config.SetOrAddParam('MusicInHyper', BoolToWideString(MusicInHyper));
  MusicInPlanet := Boolean(GetOptionValue('MusicInPlanet'));
  Config.SetOrAddParam('MusicInPlanet', BoolToWideString(MusicInPlanet));
  Config.SaveTextFile('cfg.txt', True);
  if SoundManager <> nil then
  begin
    Buffer := SoundManager.FirstBuffer;
    while Buffer <> nil do
    begin
      if Buffer.Streaming then Buffer.SetVolume(MusicVolume)
      else Buffer.SetVolume(SoundVolume);
      Buffer := Buffer.Next;
    end;
  end;
  if not RestartRequired then RequestedScreenId := SettingsReturnScreenId
  else
  begin
    RequestedScreenId := screenNone;
    RestartScreenId := SettingsReturnScreenId;
  end;
  RequestClose(1);
end;
{ @end $54CD18 }

{ @routine $54DB34 TfCfgSettings_SelectMusic }
procedure TfCfgSettings.SelectMusic;
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
  else if Player.InNormalSpace then
  begin
    if MusicInSpace then MusicManager.PlayCategory('StarMap')
    else MusicManager.RequestFadeOut;
  end;
end;
{ @end $54DB34 }
end.

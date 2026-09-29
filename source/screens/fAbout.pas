unit fAbout;
// Unit bracket (inferred): CODE 0x005155D0..0x00515CB7; inclusive evidence, not full bounds.
// Scrolling credits and close/navigation behavior.
interface
uses GI_MessageLoop, GI_Panel, Types;
type
  TfAbout = class(TMessageLoopGI) // @size $C0
  public
    ScrollTimer: TCallbackTimerIdGI; // @offset $B0
    ViewportPanel: TPanelGI; // @offset $B4
    CreditsPanel: TPanelGI; // @offset $B8
    CreditsHeight: Integer; // @offset $BC
    procedure InitializeLayout; override; // @addr $515654
    procedure OnOpen; override; // @addr $515718
    procedure OnClose; override; // @addr $515934
    procedure ClearCredits; // @addr $515954
    procedure AddCreditLine(Text: WideString; Red, Green, Blue: Byte); // @addr $515968
    procedure AddCreditSeparator; // @addr $515A94
    procedure AddCreditSpacing(Height: Integer); // @addr $515BC0
    procedure ScrollCredits(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $515BC8
    procedure CloseMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $515C1C
    procedure CloseKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $515C48
    procedure SelectMusic; override; // @addr $515C5C
  end;
implementation

// @unit-initialization $515CB0
// @unit-finalization $515C80

uses Classes, EC_BlockPar, EC_Str, GI_Image, GI_Label, GR_Main, GlobalsV, GR_Music;

{ @routine $515654 TfAbout_InitializeLayout }
procedure TfAbout.InitializeLayout;
begin
  inherited InitializeLayout;
  ViewportPanel := GetByName('PAbout') as TPanelGI;
  CreditsPanel := GetByName('PAboutI') as TPanelGI;
  with GetByName('MainPanel') do begin
    KeyDownCallback := CloseKeyDown;
    LeftButtonUpCallback := CloseMouseDown;
    RightButtonUpCallback := CloseMouseDown;
  end;
end;
{ @end $515654 }

{ @routine $515718 TfAbout_OnOpen }
procedure TfAbout.OnOpen;
var
  Block: TBlockParEC;
  I, Count: Integer;
  Kind: WideString;
begin
  SetCursorActive(False);
  if ScrollTimer <> 0 then
  begin
    CancelCallbackTimer(ScrollTimer);
    ScrollTimer := 0;
  end;
  ScrollTimer := ScheduleCallbackTimer(30, 30, ScrollCredits);
  CreditsPanel.SetPosition(Classes.Point(0, ViewportPanel.ClientSize.Y));
  ClearCredits;
  Block := LanguageDataConfig.GetBlock('FormAbout');
  Count := Block.GetParamCount;
  for I := 0 to Count - 1 do
  begin
    Kind := Block.GetParamName(I);
    if (Kind = 'T') or (Kind = 'N') then
    begin
      if Kind = 'T' then AddCreditLine(Block.GetParamValue(I), 219, 218, 156)
      else AddCreditLine(Block.GetParamValue(I), 255, 255, 230);
    end
    else if Kind = 'S' then
    begin
      Kind := Block.GetParamValue(I);
      AddCreditSpacing(GiScalePixels(ExtractDigitsToIntW(Kind)));
    end
    else if Kind = 'L' then AddCreditSeparator;
  end;
  CreditsPanel.SetSize(Classes.Point(CreditsPanel.ClientSize.X, CreditsHeight));
end;
{ @end $515718 }

{ @routine $515934 TfAbout_OnClose }
procedure TfAbout.OnClose;
begin
  if ScrollTimer <> 0 then
  begin
    CancelCallbackTimer(ScrollTimer);
    ScrollTimer := 0;
  end;
end;
{ @end $515934 }

{ @routine $515954 TfAbout_ClearCredits }
procedure TfAbout.ClearCredits;
begin
  CreditsHeight := 0;
  CreditsPanel.FreeOwnedChildren;
end;
{ @end $515954 }

{ @routine $515968 TfAbout_AddCreditLine }
procedure TfAbout.AddCreditLine(Text: WideString; Red, Green, Blue: Byte);
var
  LabelControl: TLabelGI;
begin
  LabelControl := TLabelGI.Create(CreditsPanel);
  LabelControl.SetPosition(Classes.Point(0, CreditsHeight));
  LabelControl.SetSize(Classes.Point(ViewportPanel.ClientSize.X, 1));
  LabelControl.SetFontName(AuthorsFontName);
  LabelControl.SetWordWrapEnabled(False);
  LabelControl.SetPositionModeW(False);
  LabelControl.SetTextAlignX(taxCenter);
  LabelControl.SetTextAlignY(tayAuto);
  LabelControl.SetText(Text);
  LabelControl.SetTextColor(CurrentPixelFormat.PackRgbBytes(Red, Green, Blue));
  LabelControl.SetTextAlignX(taxCenter);
  LabelControl.SetTextAlignY(tayCenter);
  LabelControl.SetSize(Classes.Point(LabelControl.ClientSize.X, LabelControl.ClientSize.Y + 4));
  CreditsHeight := CreditsHeight + LabelControl.ClientSize.Y;
end;
{ @end $515968 }

{ @routine $515A94 TfAbout_AddCreditSeparator }
procedure TfAbout.AddCreditSeparator;
var
  Image: TImageGI;
begin
  Image := TImageGI.Create(CreditsPanel);
  Image.SetImagePath('GI,Bm.FormAbout.' + GiResourceSuffix + 'Line');
  Image.SetPosition(Classes.Point(0, CreditsHeight));
  Image.SetSize(Classes.Point(ViewportPanel.ClientSize.X, Image.GetContentSize.Y + 4));
  Image.SetPositionModeW(False);
  Image.SetImageKindX(ikxCenter);
  Image.SetImageKindY(ikyCenter);
  CreditsHeight := CreditsHeight + Image.ClientSize.Y;
end;
{ @end $515A94 }

{ @routine $515BC0 TfAbout_AddCreditSpacing }
procedure TfAbout.AddCreditSpacing(Height: Integer);
begin
  CreditsHeight := CreditsHeight + Height;
end;
{ @end $515BC0 }

{ @routine $515BC8 TfAbout_ScrollCredits }
procedure TfAbout.ScrollCredits(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  CreditsPanel.SetPosition(Classes.Point(0, CreditsPanel.LocalPosition.Y - 1));
  if -CreditsPanel.LocalPosition.Y >= CreditsPanel.ClientSize.Y then
    CreditsPanel.SetPosition(Classes.Point(0, ViewportPanel.ClientSize.Y));
end;
{ @end $515BC8 }

{ @routine $515C1C TfAbout_CloseMouseDown }
procedure TfAbout.CloseMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  RequestedScreenId := screenMainMenu;
  RequestClose(1);
end;
{ @end $515C1C }

{ @routine $515C48 TfAbout_CloseKeyDown }
procedure TfAbout.CloseKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  RequestedScreenId := screenMainMenu;
  RequestClose(1);
end;
{ @end $515C48 }

{ @routine $515C5C TfAbout_SelectMusic }
procedure TfAbout.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;
{ @end $515C5C }
end.

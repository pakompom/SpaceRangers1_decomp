unit GI_CountBox;
// Unit bracket (inferred): CODE 0x005848EC..0x005857AB; inclusive evidence, not full bounds.
// Quantity dialog.
interface
uses GI_MessageLoop, GI_Label, GI_CountBar;
type
  TCountBoxGI = class(TMessageLoopGI) // @size $D0
  public
    ParentLoop: TMessageLoopGI; // @offset $B0
    Minimum: Integer; // @offset $B4
    Maximum: Integer; // @offset $B8
    Step: Integer; // @offset $BC
    Value: Integer; // @offset $C0
    TextLabel: TLabelGI; // @offset $C4
    CountBar: TCountBarGI; // @offset $C8
    MessageText: WideString; // @offset $CC
    procedure OnOpen; override; // @addr $584988
    procedure CountChanged(Sender: TObjectGI); // @addr $5854B4
    procedure AcceptClick(Sender: TObjectGI); // @addr $5855C4
    procedure CancelClick(Sender: TObjectGI); // @addr $5855D0
    procedure DialogKeyDown(Sender: TObjectGI; VirtualKey: Cardinal); // @addr $5855DC
    procedure ProcessCallbackTimers; override; // @addr $5855FC
  end;
function ShowCountBoxGI(Parent: TMessageLoopGI; const Text: WideString; Minimum, Maximum, Step: Integer; var Value: Integer): Cardinal; // @addr $585628
implementation

// @unit-initialization $5857A4
// @unit-finalization $585774

uses GlobalsV, Classes, SysUtils, EC_Struct, EC_Str, GI_GraphButton, GI_Main, GI_Window, Globals, GR_Main, Types, Windows, aMyFunction;

{ @routine $584988 TCountBoxGI_OnOpen }
procedure TCountBoxGI.OnOpen;
var
  Window: TWindowGI;
  LabelControl, BarControl, ButtonControl: TObjectGI;
  TextSize, WindowSize, CandidateSize: TPoint;
  BottomMargin, TopMargin, TextHeight: Integer;
  Borders: TRect;
begin
  if GiResourceVariant = 1 then BottomMargin := 31 else BottomMargin := 40;
  TopMargin := BottomMargin div 2;
  ContentPanel.KeyDownCallback := DialogKeyDown;
  Window := TWindowGI.Create(ContentPanel);
  Window.SetDepth(1);
  Window.SetConfigPath('Style.Window.' + GiResourceSuffix + 'Normal');
  Borders := Window.WorkSubRect;
  CandidateSize := Window.AlignSizeToBorderTiles(Classes.Point(0, 0));
  TextHeight := Round((CandidateSize.Y - Borders.Top - Borders.Bottom) * 0.55);
  LabelControl := TLabelGI.Create(ContentPanel);
  TextLabel := TLabelGI(LabelControl);
  with TLabelGI(LabelControl) do begin
    SetDepth(0);
    SetFontName(HitPointFontName);
    SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
    SetText(MessageText);
    SetPosition(Classes.Point(Borders.Left, Borders.Top));
    SetSize(Classes.Point(CandidateSize.X - Borders.Left - Borders.Right, TextHeight));
    SetWordWrapEnabled(True);
    SetTextAlignX(taxCenter);
    SetTextAlignY(tayCenterEx);
    TextSize := MeasureContentSize;
  end;
  Window.SetPosition(Classes.Point(0, 0));
  Window.SetSize(Classes.Point(TextSize.X + Borders.Left + Borders.Right,
    TextSize.Y + Borders.Top + Borders.Bottom + BottomMargin + TopMargin));
  Window.UpdateAutoGeometry;
  WindowSize := Window.ClientSize;
  CountBar := TCountBarGI.Create(ContentPanel);
  BarControl := CountBar;
  with TCountBarGI(BarControl) do begin
    if GiResourceVariant = 2 then SetSize(Classes.Point(168, 17))
    else SetSize(Classes.Point(131, 13));
    BarControl.SetPosition(Classes.Point(CandidateSize.X div 2 - ClientSize.X div 2, Borders.Top + TextHeight));
    DecreaseButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftN');
    DecreaseButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftA');
    DecreaseButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeftD');
    IncreaseButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightN');
    IncreaseButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightA');
    IncreaseButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRightD');
    AfterThumbImage.SetImagePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackLeft');
    BeforeThumbImage.SetImagePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackRight');
    ThumbButton.SetImageNormalPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolN');
    ThumbButton.SetImageNormalActivePath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolA');
    ThumbButton.SetImageDownPath('GI,Bm.FormGoods.' + GiResourceSuffix + 'TrackPolD');
    PositionChangedCallback := CountChanged;
    UpdateLayout;
    SetRange(Self.Minimum, Self.Maximum);
    Step := Self.Step;
    // Opens at Maximum, ignoring the incoming Value.
    SetPositionInternal(Self.Maximum);
  end;
  ButtonControl := TGraphButtonGI.Create(ContentPanel);
  with TGraphButtonGI(ButtonControl) do begin
    SetDepth(0);
    SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkN');
    SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkA');
    SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkD');
    SetName('ok');
    SetSize(GetMaxStateImageSize);
    if GiResourceVariant = 2 then
      SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 55 + 55,
        ClientSize.Y + Borders.Bottom)))
    else
      SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 45 + 45,
        ClientSize.Y + Borders.Bottom)));
    HitKind := gbhRect;
    UpdateStateImagePlacement;
    UpdateStateVisuals;
    UpCallback := AcceptClick;
  end;
  ButtonControl := TGraphButtonGI.Create(ContentPanel);
  with TGraphButtonGI(ButtonControl) do begin
    SetDepth(0);
    SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelN');
    SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelA');
    SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelD');
    // The original gives both buttons the same name.
    SetName('ok');
    SetSize(GetMaxStateImageSize);
    if GiResourceVariant = 2 then
      SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 55,
        ClientSize.Y + Borders.Bottom)))
    else
      SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 45,
        ClientSize.Y + Borders.Bottom)));
    HitKind := gbhRect;
    UpdateStateImagePlacement;
    UpdateStateVisuals;
    UpCallback := CancelClick;
  end;
  ViewportRect.Left := GameScreenWidth shr 1 - WindowSize.X div 2;
  ViewportRect.Top := GameScreenHeight shr 1 - WindowSize.Y div 2;
  ViewportRect.Right := GameScreenWidth shr 1 + WindowSize.X div 2;
  ViewportRect.Bottom := GameScreenHeight shr 1 + WindowSize.Y div 2;
  ContentPanel.SetPosition(ViewportRect.TopLeft);
  ContentPanel.SetSize(WindowSize);
  ContentPanel.UpdateAbsolutePosition;
  ContentPanel.UpdateSubtreeHitBounds;
  CountChanged(nil);
end;
{ @end $584988 }

{ @routine $5854B4 TCountBoxGI_CountChanged }
procedure TCountBoxGI.CountChanged(Sender: TObjectGI);
begin
  if CountBar.Position < CountBar.Maximum then CountBar.SetPositionInternal(CountBar.Position div Step * Step);
  TextLabel.SetText(FormatText1(MessageText, HighlightColorTag, '<Cnt>', IntToStr(CountBar.Position)));
  Value := CountBar.Position;
end;
{ @end $5854B4 }

{ @routine $5855C4 TCountBoxGI_AcceptClick }
procedure TCountBoxGI.AcceptClick(Sender: TObjectGI);
begin
  RequestClose(1);
end;
{ @end $5855C4 }

{ @routine $5855D0 TCountBoxGI_CancelClick }
procedure TCountBoxGI.CancelClick(Sender: TObjectGI);
begin
  RequestClose(2);
end;
{ @end $5855D0 }

{ @routine $5855DC TCountBoxGI_DialogKeyDown }
procedure TCountBoxGI.DialogKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
begin
  if (VirtualKey = VK_ESCAPE) or (VirtualKey = Ord('N')) then CancelClick(Sender)
  else if (VirtualKey = VK_RETURN) or (VirtualKey = Ord('Y')) then AcceptClick(Sender);
end;
{ @end $5855DC }

{ @routine $5855FC TCountBoxGI_ProcessCallbackTimers }
procedure TCountBoxGI.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(255);
end;
{ @end $5855FC }

{ @routine $585628 ShowCountBoxGI }
function ShowCountBoxGI(Parent: TMessageLoopGI; const Text: WideString; Minimum, Maximum, Step: Integer; var Value: Integer): Cardinal;
var Dialog: TCountBoxGI; CursorState: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@CursorState);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  Dialog := TCountBoxGI.Create;
  Dialog.ParentLoop := Parent;
  Dialog.InitializeDefaults;
  try
    Dialog.MessageText := Text;
    Dialog.Minimum := Minimum;
    Dialog.Maximum := Maximum;
    Dialog.Step := Step;
    Dialog.Value := Value;
    Result := Dialog.Run;
    Value := Dialog.Value;
    Parent.InvalidateViewport;
  finally
    Dialog.Free;
  end;
  Parent.RestoreCursorState(@CursorState);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
end;
{ @end $585628 }
end.

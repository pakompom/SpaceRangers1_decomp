unit GI_MessageBox;
// Unit bracket (inferred): CODE 0x004C5D28..0x004C669B; inclusive evidence, not full bounds.
// Message dialog; native VMT $4C5D74.

interface

uses GI_MessageLoop;

const
  // Button bits; OnOpen and DialogKeyDown read no others.
  mbgOK = $1;
  mbgCancel = $2;
  // Returned by the click handlers.
  mbgResultOK = 1;
  mbgResultCancel = 2;

type
  TMessageBoxGI = class(TMessageLoopGI) // @size $C0
  public
    ParentLoop: TMessageLoopGI; // @offset $B0
    MessageText: WideString; // @offset $B4
    Options: Cardinal; // @offset $B8 // mbg* button bits.
    UnusedOption: Integer; // @offset $BC // Stored by ShowMessageBoxGI; no recovered reader.
    procedure OnOpen; override; // @addr $4C5DC4
    procedure AcceptClick(Sender: TObjectGI); // @addr $4C64A8
    procedure CancelClick(Sender: TObjectGI); // @addr $4C64B4
    procedure DialogKeyDown(Sender: TObjectGI; VirtualKey: Cardinal); // @addr $4C64C0
    procedure ProcessCallbackTimers; override; // @addr $4C6514
  end;

function ShowMessageBoxGI(Parent: TMessageLoopGI; const Text: WideString; Options: Cardinal; UnusedOption: Integer = 0): Cardinal; // @addr $4C6540

implementation

// @unit-initialization $4C6694
// @unit-finalization $4C6664

uses GlobalsV, Classes, EC_Struct, EC_Str, GI_GraphButton, GI_Image, GI_Label, GI_Main, GI_Window,
  Globals, GR_Main, Types, Windows;

{ @routine $4C5DC4 TMessageBoxGI_OnOpen }
procedure TMessageBoxGI.OnOpen;
var
  Window: TWindowGI;
  AcceptButton, CancelButton: TGraphButtonGI;
  TextLabel: TLabelGI;
  TextSize, WindowSize, CandidateSize: TPoint;
  BottomMargin, TopMargin: Integer;
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
  TextLabel := TLabelGI.Create(ContentPanel);
  TextLabel.SetDepth(0);
  TextLabel.SetFontName(HitPointFontName);
  TextLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
  TextLabel.SetText(MessageText);
  TextLabel.SetSize(Classes.Point(CandidateSize.X - Borders.Left - Borders.Right, 1));
  TextLabel.SetWordWrapEnabled(True);
  TextLabel.SetTextAlignX(taxAuto);
  TextLabel.SetTextAlignY(tayAuto);
  TextSize := TextLabel.MeasureContentSize;
  Window.SetPosition(Classes.Point(0, 0));
  Window.SetSize(Classes.Point(TextSize.X + Borders.Left + Borders.Right,
    TextSize.Y + Borders.Top + Borders.Bottom + BottomMargin + TopMargin));
  Window.UpdateAutoGeometry;
  WindowSize := Window.ClientSize;
  if Options and mbgOK = mbgOK then
  begin
    AcceptButton := TGraphButtonGI.Create(ContentPanel);
    AcceptButton.UpOnlyDown := True;
    AcceptButton.SetDepth(0);
    AcceptButton.SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkN');
    AcceptButton.SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkA');
    AcceptButton.SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2OkD');
    AcceptButton.SetName('ok');
    AcceptButton.SetSize(AcceptButton.GetMaxStateImageSize);
    if GiResourceVariant = 2 then
      AcceptButton.SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 55 + 55,
        AcceptButton.ClientSize.Y + Borders.Bottom)))
    else
      AcceptButton.SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 45 + 45,
        AcceptButton.ClientSize.Y + Borders.Bottom)));
    AcceptButton.HitKind := gbhRect;
    AcceptButton.UpdateStateImagePlacement;
    AcceptButton.UpdateStateVisuals;
    AcceptButton.UpCallback := AcceptClick;
  end;
  if Options and mbgCancel = mbgCancel then
  begin
    CancelButton := TGraphButtonGI.Create(ContentPanel);
    CancelButton.UpOnlyDown := True;
    CancelButton.SetDepth(0);
    CancelButton.SetImageNormalPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelN');
    CancelButton.SetImageNormalActivePath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelA');
    CancelButton.SetImageDownPath('GI,Bm.SI.' + GiResourceSuffix + 'But2CancelD');
    // The original gives both buttons the same name.
    CancelButton.SetName('ok');
    CancelButton.SetSize(CancelButton.GetMaxStateImageSize);
    if GiResourceVariant = 2 then
      CancelButton.SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 55,
        CancelButton.ClientSize.Y + Borders.Bottom)))
    else
      CancelButton.SetPosition(SubtractPoints(WindowSize, Classes.Point(Borders.Right + 45,
        CancelButton.ClientSize.Y + Borders.Bottom)));
    CancelButton.HitKind := gbhRect;
    CancelButton.UpdateStateImagePlacement;
    CancelButton.UpdateStateVisuals;
    CancelButton.UpCallback := CancelClick;
  end;
  ViewportRect.Left := GameScreenWidth shr 1 - WindowSize.X div 2;
  ViewportRect.Top := GameScreenHeight shr 1 - WindowSize.Y div 2;
  ViewportRect.Right := GameScreenWidth shr 1 + (WindowSize.X + 0) div 2;
  ViewportRect.Bottom := GameScreenHeight shr 1 + WindowSize.Y div 2;
  ContentPanel.SetPosition(ViewportRect.TopLeft);
  ContentPanel.SetSize(WindowSize);
  ContentPanel.UpdateAbsolutePosition;
  ContentPanel.UpdateSubtreeHitBounds;
  TextLabel.SetTextAlignX(taxCenter);
  TextLabel.SetTextAlignY(tayCenterEx);
  TextLabel.SetPosition(Classes.Point(Borders.Left, Borders.Top + TopMargin));
  TextLabel.SetSize(Classes.Point(WindowSize.X - Borders.Left - Borders.Right,
    WindowSize.Y - Borders.Top - Borders.Bottom - BottomMargin - TopMargin));
  TextSize := TextLabel.MeasureContentSize;
end;
{ @end $4C5DC4 }

{ @routine $4C64A8 TMessageBoxGI_AcceptClick }
procedure TMessageBoxGI.AcceptClick(Sender: TObjectGI);
begin
  RequestClose(mbgResultOK);
end;
{ @end $4C64A8 }

{ @routine $4C64B4 TMessageBoxGI_CancelClick }
procedure TMessageBoxGI.CancelClick(Sender: TObjectGI);
begin
  RequestClose(mbgResultCancel);
end;
{ @end $4C64B4 }

{ @routine $4C64C0 TMessageBoxGI_DialogKeyDown }
procedure TMessageBoxGI.DialogKeyDown(Sender: TObjectGI; VirtualKey: Cardinal);
begin
  if (Options and mbgCancel = mbgCancel) and ((VirtualKey = VK_ESCAPE) or (VirtualKey = Ord('N')) or ((VirtualKey = VK_RETURN) and (Options and mbgOK <> mbgOK))) then
    CancelClick(Sender)
  else if (Options and mbgOK = mbgOK) and ((VirtualKey = VK_RETURN) or (VirtualKey = Ord('Y'))) then
    AcceptClick(Sender);
end;
{ @end $4C64C0 }

{ @routine $4C6514 TMessageBoxGI_ProcessCallbackTimers }
procedure TMessageBoxGI.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(255);
end;
{ @end $4C6514 }

{ @routine $4C6540 ShowMessageBoxGI }
function ShowMessageBoxGI(Parent: TMessageLoopGI; const Text: WideString; Options: Cardinal; UnusedOption: Integer): Cardinal;
var
  Dialog: TMessageBoxGI;
  CursorState: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@CursorState);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  Dialog := TMessageBoxGI.Create;
  Dialog.ParentLoop := Parent;
  Dialog.InitializeDefaults;
  try
    Dialog.MessageText := Text;
    Dialog.Options := Options;
    Dialog.UnusedOption := UnusedOption;
    Result := Dialog.Run;
    Parent.InvalidateViewport;
  finally
    Dialog.Free;
  end;
  Parent.RestoreCursorState(@CursorState);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
end;
{ @end $4C6540 }

end.

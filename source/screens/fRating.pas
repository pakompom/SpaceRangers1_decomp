unit fRating;
// Unit bracket (inferred): CODE 0x00516AC8..0x0051B86F; inclusive evidence, not full bounds.
// The rating table uses column spans and expandable rows.
interface
uses GI_MessageLoop, GI_Panel, GI_PanelScrollBar, GI_Window, GI_Label, GI_Image, Types,
  aRanger, aNormalShip;
type
  TRatingColumn = record // @size $08
    Width: Integer; // @offset $00
    CanAscend: Boolean; // @offset $04
    CanDescend: Boolean; // @offset $05
    Ascending: Boolean; // @offset $06
  end;
  TRatingRow = record // @size $0C
    Ranger: TRanger; // @offset $00 Borrowed.
    Top: Integer; // @offset $04
    Height: Integer; // @offset $08
  end;
  TfRating = class(TMessageLoopGI) // @size $F8
  public
    ParentLoop: TMessageLoopGI; // @offset $B0
    RewardWindow: TWindowGI; // @offset $B4
    ColumnLinesPanel: TPanelGI; // @offset $B8
    HeaderPanel: TPanelGI; // @offset $BC
    TablePanel: TPanelScrollBarGI; // @offset $C0
    Columns: array of TRatingColumn; // @offset $C4
    Rows: array of TRatingRow; // @offset $C8
    SelectedIndex: Integer; // @offset $CC
    CurrentRowIndex: Integer; // @offset $D0
    CurrentLineCount: Integer; // @offset $D4
    SelectedRangerId: Integer; // @offset $D8
    SortColumn: Integer; // @offset $DC
    FirstRowControl: TObjectGI; // @offset $E0
    SelectedRowRect: TRect; // @offset $E4
    HoveredAwardId: Integer; // @offset $F4
    constructor Create; // @addr $516BA4
    destructor Destroy; override; // @addr $516BDC
    procedure InitializeLayout; override; // @addr $516C04
    procedure OnOpen; override; // @addr $516D3C
    procedure OnClose; override; // @addr $516E20
    procedure CloseClicked(Sender: TObjectGI); // @addr $516E40
    procedure KeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $516E4C
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); override; // @addr $516F84
    procedure BackgroundMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $516FDC
    procedure RowMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $517040
    procedure RewardsClicked(Sender: TObjectGI); // @addr $517080
    procedure FeaturedRangerClicked(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5170C8
    procedure SortHeaderMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $517104
    procedure AwardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $5171A4
    procedure HintMouseLeave(Sender: TObjectGI); // @addr $517274
    procedure ShowAwardHint(Ranger: TNormalShip; AwardId: Integer); // @addr $51727C
    procedure HideAwardHint; // @addr $5175AC
    function FindRowByRangerId(RangerId: Cardinal): Integer; // @addr $5175C4
    procedure ClearRows; // @addr $517620
    function ColumnRight(Index: Integer): Integer; // @addr $5176D0
    procedure AddColumnLine(Column, Offset: Integer; NaturalHeight: Boolean); // @addr $517708
    procedure AddColumnHeader(Column, LastColumn, SortIndex: Integer; Text: WideString); // @addr $517840
    procedure BeginRow(Index: Integer); // @addr $517AA8
    procedure FinishRow(RangerId: Cardinal; Selected: Boolean); // @addr $517AC8
    procedure AddTextCell(Column, Row, LastColumn, LastRow: Integer; Text: WideString; AlignX: TTextAlignXGI; AlignY: TTextAlignYGI; WordWrap: Boolean; ExtraHeight: Integer); // @addr $517D84
    procedure AddImageCell(Column, Row, LastColumn, LastRow: Integer; Path: WideString; Padding: Integer; AlignX: TImageKindXGI; AlignY: TImageKindYGI; Height: Integer); // @addr $517F08
    procedure AddStatusCell(Column, Row, LastColumn, LastRow, Percent, Padding: Integer; AlignX: TImageKindXGI; AlignY: TImageKindYGI); // @addr $518060
    procedure AddShipCell(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger; Padding: Integer; Animate: Boolean; AlignX: TImageKindXGI; AlignY: TImageKindYGI); // @addr $518244
    procedure AddAwardsCell(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger); // @addr $51861C
    procedure AddRewardButton(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger; Offset: TPoint); // @addr $518AA0
    procedure AddSpacerCell(Column, Row, LastColumn, LastRow, Height: Integer); // @addr $518D0C
    procedure AddFillCell(Column, Row, LastColumn, LastRow: Integer; AColor: Word; Translucent: Boolean); // @addr $518DDC
    procedure RefreshFeaturedRangers; // @addr $518ED8
    procedure SelectMusic; override; // @addr $519930
    procedure ProcessCallbackTimers; override; // @addr $519AC8
    procedure InitializeColumns; // @addr $519BC4
    procedure RebuildTable; // @addr $519DA0
    procedure RebuildRow(Index: Integer); // @addr $51A58C
    procedure SelectRow(Index: Integer); // @addr $51A654
    procedure CreateRow(Index: Integer); // @addr $51A6E8
  end;
function ShowRangerRating(Parent: TMessageLoopGI): Boolean; // @addr $519AF8
implementation

// @unit-initialization $51B868
// @unit-finalization $51B838

uses SysUtils, Classes, Windows, Math, GR_Main, GR_GraphBuf, GR_Music, GR_gi,
  GI_Main, GI_GraphBuf, GI_GAI, GI_Frame, GI_GraphButton, aGalaxy, aPlayer, aShip,
  aPlanet, aConst, aMyFunction, EC_Str, Globals, GlobalsV, fRewards, fShip2;

{ @routine $516BA4 TfRating_Create }
constructor TfRating.Create;
begin
  inherited Create;
end;
{ @end $516BA4 }

{ @routine $516BDC TfRating_Destroy }
destructor TfRating.Destroy;
begin
  inherited Destroy;
end;
{ @end $516BDC }

{ @routine $516C04 TfRating_InitializeLayout }
procedure TfRating.InitializeLayout;
begin
  inherited InitializeLayout;
  (GetByName('ButClose') as TGraphButtonGI).UpCallback := CloseClicked;
  RewardWindow := GetByName('RewardWnd') as TWindowGI;
  ColumnLinesPanel := GetByName('PVLine') as TPanelGI;
  HeaderPanel := GetByName('PZag') as TPanelGI;
  TablePanel := GetByName('PTable') as TPanelScrollBarGI;
  TablePanel.VerticalScrollBar.SetPageSize(TablePanel.ClientSize.Y);
  TablePanel.VerticalScrollBar.SetLargeChange(TablePanel.ClientSize.Y);
end;
{ @end $516C04 }

{ @routine $516D3C TfRating_OnOpen }
procedure TfRating.OnOpen;
begin
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  GetByName('MainPanel').KeyDownCallback := KeyDown;
  GetByName('MainPanel').LeftButtonUpCallback := BackgroundMouseUp;
  HideAwardHint;
  RefreshFeaturedRangers;
  InitializeColumns;
  RebuildTable;
end;
{ @end $516D3C }

{ @routine $516E20 TfRating_OnClose }
procedure TfRating.OnClose;
begin
  ClearRows;
  Columns := nil;
end;
{ @end $516E20 }

{ @routine $516E40 TfRating_CloseClicked }
procedure TfRating.CloseClicked(Sender: TObjectGI);
begin
  RequestClose(1);
end;
{ @end $516E40 }

{ @routine $516E4C TfRating_KeyDown }
procedure TfRating.KeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or
    IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = Ord('R') then CloseClicked(nil)
  else if (Key = VK_UP) or (Key = VK_LEFT) then
  begin
    if SelectedIndex > 0 then SelectRow(SelectedIndex - 1);
  end
  else if (Key = VK_DOWN) or (Key = VK_RIGHT) then
  begin
    if SelectedIndex < High(Rows) then SelectRow(SelectedIndex + 1);
  end
  else if Key = VK_HOME then SelectRow(0)
  else if Key = VK_END then SelectRow(High(Rows))
  else if Key = VK_PRIOR then
    TablePanel.VerticalScrollBar.SetPosition(
      TablePanel.VerticalScrollBar.Position - TablePanel.VerticalScrollBar.LargeChange)
  else if Key = VK_NEXT then
    TablePanel.VerticalScrollBar.SetPosition(
      TablePanel.VerticalScrollBar.Position + TablePanel.VerticalScrollBar.LargeChange)
  else if Key = VK_ESCAPE then RequestClose(1)
  else if Key = VK_SPACE then begin end;
end;
{ @end $516E4C }

{ @routine $516F84 TfRating_ProcessMouseWheel }
procedure TfRating.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
  if Delta = WHEEL_DELTA then TablePanel.VerticalScrollBar.SetPosition(TablePanel.VerticalScrollBar.Position - TablePanel.VerticalScrollBar.SmallChange)
  else if Delta = -WHEEL_DELTA then TablePanel.VerticalScrollBar.SetPosition(TablePanel.VerticalScrollBar.Position + TablePanel.VerticalScrollBar.SmallChange);
end;
{ @end $516F84 }

{ @routine $516FDC TfRating_BackgroundMouseUp }
procedure TfRating.BackgroundMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not (GetByName('ImagePanel') as TImageGI).HitTestPixel(Point) then CloseClicked(nil);
end;
{ @end $516FDC }

{ @routine $517040 TfRating_RowMouseUp }
procedure TfRating.RowMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not Sender.IsOccludedAtPoint(Point) then
  begin
    SelectRow(Sender.UserState);
    BreakUiMessage;
  end;
end;
{ @end $517040 }

{ @routine $517080 TfRating_RewardsClicked }
procedure TfRating.RewardsClicked(Sender: TObjectGI);
begin
  AwardSubject := Galaxy.IdToShip(ExtractDigitsToIntW(Sender.ControlName), True);
  if not RunRewards(Self) then RequestClose(2);
  BreakUiMessage;
end;
{ @end $517080 }

{ @routine $5170C8 TfRating_FeaturedRangerClicked }
procedure TfRating.FeaturedRangerClicked(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  SelectRow(FindRowByRangerId(Sender.UserValue));
  BreakUiMessage;
end;
{ @end $5170C8 }

{ @routine $517104 TfRating_SortHeaderMouseDown }
procedure TfRating.SortHeaderMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Index: Integer;
begin
  Index := Sender.UserValue;
  if not Columns[Index].CanAscend and not Columns[Index].CanDescend then Exit;
  if Index = SortColumn then
  begin
    if Columns[Index].CanAscend <> Columns[Index].CanDescend then Exit;
    Columns[Index].Ascending := not Columns[Index].Ascending;
  end
  else SortColumn := Index;
  SelectedRangerId := Rows[SelectedIndex].Ranger.Id;
  SelectedIndex := -1;
  RebuildTable;
  BreakUiMessage;
end;
{ @end $517104 }

{ @routine $5171A4 TfRating_AwardsMouseMove }
procedure TfRating.AwardsMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Size, Step: Integer; Ranger: TRanger; Index: Integer; Reward: Pointer;
begin
  Size := GiScalePixels(20);
  Step := Size div 2;
  Ranger := Rows[Sender.UserState].Ranger;
  Index := Max(0,Ranger.AwardIds.Count - 8) + Sender.ToLocalPoint(Point).X div Step;
  if Sender.ToLocalPoint(Point).Y < Sender.ClientSize.Y - Size then
  begin
    HideAwardHint;
    Exit;
  end;
  if Index >= Ranger.AwardIds.Count then Index := Ranger.AwardIds.Count - 1;
  Reward := Ranger.AwardIds[Index];
  ShowAwardHint(Ranger, PByte(Reward)^);
end;
{ @end $5171A4 }

{ @routine $517274 TfRating_HintMouseLeave }
procedure TfRating.HintMouseLeave(Sender: TObjectGI);
begin
  HideAwardHint;
end;
{ @end $517274 }

{ @routine $51727C TfRating_ShowAwardHint }
procedure TfRating.ShowAwardHint(Ranger: TNormalShip; AwardId: Integer);
var
  CursorPoint: TPoint;
  Path: WideString;
begin
  if HoveredAwardId = AwardId then Exit;
  HoveredAwardId := AwardId;
  RewardWindow.SetActive(True);
  CursorPoint := GetCursorPoint;
  with RewardWindow do SetPosition(Classes.Point(CursorPoint.X - ClientSize.X - 50,
    Max(0, CursorPoint.Y - ClientSize.Y - 20)));
  if AwardId < 10 then Path := 'Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(AwardId)
  else Path := 'Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(AwardId);
  with GetByName('RewardImage') as TGraphBufGI do
  begin
    SourceHasPerPixelAlpha := True;
    LoadGiByPathIntoGraphBuf(Path, GraphBuf);
    if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
      GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
    else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  with GetByName('RewardName') as TLabelGI do SetText(Ranger.GetAwardInfo(AwardId).Name);
  with GetByName('RewardText') as TLabelGI do SetText(Ranger.GetAwardInfo(AwardId).Text);
end;
{ @end $51727C }

{ @routine $5175AC TfRating_HideAwardHint }
procedure TfRating.HideAwardHint;
begin
  HoveredAwardId := -1;
  RewardWindow.SetActive(False);
end;
{ @end $5175AC }

{ @routine $5175C4 TfRating_FindRowByRangerId }
function TfRating.FindRowByRangerId(RangerId: Cardinal): Integer;
var
  Index: Integer;
begin
  for Index := 0 to High(Rows) do
    if RangerId = Rows[Index].Ranger.Id then
    begin
      Result := Index;
      Exit;
    end;
  RaiseWideMessage('FindById');
  Result := -1;
end;
{ @end $5175C4 }

{ @routine $517620 TfRating_ClearRows }
procedure TfRating.ClearRows;
begin
  ColumnLinesPanel.FreeOwnedChildren;
  HeaderPanel.FreeOwnedChildren;
  TablePanel.FreeOwnedChildren;
  CurrentLineCount := 0;
  Rows := nil;
  GetByName('MainPanel').Invalidate;
  SelectedRowRect := Classes.Rect(0, 0, 1, 1);
  TablePanel.VerticalScrollBar.SetSmallChange(TablePanel.VerticalScrollBar.LargeChange);
end;
{ @end $517620 }

{ @routine $5176D0 TfRating_ColumnRight }
function TfRating.ColumnRight(Index: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  I := 0;
  while Index >= 0 do
  begin
    if I > High(Columns) then Break;
    Inc(Result, Columns[I].Width);
    Dec(Index);
    Inc(I);
  end;
end;
{ @end $5176D0 }

{ @routine $517708 TfRating_AddColumnLine }
procedure TfRating.AddColumnLine(Column, Offset: Integer; NaturalHeight: Boolean);
begin
  with TImageGI.Create(ColumnLinesPanel) do
  begin
  SetImagePath('GI,Bm.FormRating.' + GiResourceSuffix + 'VLine');
  SetPosition(Classes.Point(ColumnRight(Column) + Offset, 0));
  if NaturalHeight then SetSize(GetContentSize)
  else SetSize(Classes.Point(GetContentSize.X, TablePanel.LocalPosition.Y - ColumnLinesPanel.LocalPosition.Y));
  end;
end;
{ @end $517708 }

{ @routine $517840 TfRating_AddColumnHeader }
procedure TfRating.AddColumnHeader(Column, LastColumn, SortIndex: Integer; Text: WideString);
var Caption: TLabelGI; Image: TImageGI;
begin
  Caption := TLabelGI.Create(HeaderPanel);
  Caption.LeftButtonDownCallback := SortHeaderMouseDown;
  Caption.SetPosition(Classes.Point(ColumnRight(Column - 1), 0));
  Caption.SetSize(Classes.Point(ColumnRight(LastColumn) - Caption.LocalPosition.X, HeaderPanel.ClientSize.Y));
  Caption.SetFontName(HitPointFontName);
  Caption.SetWordWrapEnabled(False);
  Caption.SetPositionModeW(False);
  Caption.SetTextAlignX(taxCenter);
  Caption.SetTextAlignY(tayCenterEx);
  Caption.SetText(Text);
  Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255,255,230));
  Caption.UserValue := SortIndex;
  if SortIndex = SortColumn then
  begin
    Image := TImageGI.Create(HeaderPanel);
    if Columns[SortIndex].Ascending then Image.SetImagePath('GI,Bm.FormRating.' + GiResourceSuffix + 'Up')
    else Image.SetImagePath('GI,Bm.FormRating.' + GiResourceSuffix + 'Down');
    Image.SetPosition(Classes.Point(ColumnRight(LastColumn) - Image.GetContentSize.X - GiScalePixels(7), 0));
    Image.SetSize(Classes.Point(Image.GetContentSize.X, HeaderPanel.ClientSize.Y));
  end;
end;
{ @end $517840 }

{ @routine $517AA8 TfRating_BeginRow }
procedure TfRating.BeginRow(Index: Integer);
begin
  CurrentRowIndex := Index;
  FirstRowControl := TablePanel.LastChild;
  CurrentLineCount := 0;
end;
{ @end $517AA8 }

{ @routine $517AC8 TfRating_FinishRow }
procedure TfRating.FinishRow(RangerId: Cardinal; Selected: Boolean);
var Control: TObjectGI; I, Height, Top: Integer;
begin
  if FirstRowControl = nil then FirstRowControl := TablePanel.FirstChild;
  Top := Rows[CurrentRowIndex].Top;
  Height := 0;
  for I := 0 to CurrentLineCount - 1 do
  begin
    Control := FirstRowControl;
    while Control <> nil do
    begin
      if I = Control.UserValue - 1 then Control.SetPosition(Classes.Point(Control.LocalPosition.X, Top + Height));
      Control := Control.NextSibling;
    end;
    Control := FirstRowControl;
    while Control <> nil do
    begin
      if I = Control.UserIndex - 1 then Height := Max(Height, Control.LocalPosition.Y - Top + Control.ClientSize.Y);
      Control := Control.NextSibling;
    end;
    Control := FirstRowControl;
    while Control <> nil do
    begin
      if I = Control.UserIndex - 1 then
      begin
        Control.SetSize(Classes.Point(Control.ClientSize.X, Height - (Control.LocalPosition.Y - Top)));
        if Control.HelpText <> '' then
          Control.SetSize(Classes.Point(Control.ClientSize.X, Control.ClientSize.Y - StrToInt(Control.HelpText)));
      end;
      Control := Control.NextSibling;
    end;
  end;
  Control := FirstRowControl;
  while Control <> nil do
  begin
    if Control.UserValue <> 0 then Control.SetName(IntToStr(Int64(RangerId)));
    if Control.HelpText <> '' then
    begin
      Control.SetPosition(Classes.Point(Control.LocalPosition.X, Control.LocalPosition.Y + StrToInt(Control.HelpText)));
      Control.HelpText := '';
    end;
    Control.UserValue := 0;
    Control.UserIndex := 0;
    Control := Control.NextSibling;
  end;
  if Selected then SelectedRowRect := Classes.Rect(0,Top,1,Top + Height);
  TablePanel.VerticalScrollBar.SetSmallChange(Min(Height,TablePanel.VerticalScrollBar.SmallChange));
  Rows[CurrentRowIndex].Height := Height;
end;
{ @end $517AC8 }

{ @routine $517D84 TfRating_AddTextCell }
procedure TfRating.AddTextCell(Column, Row, LastColumn, LastRow: Integer; Text: WideString; AlignX: TTextAlignXGI; AlignY: TTextAlignYGI; WordWrap: Boolean; ExtraHeight: Integer);
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  with TLabelGI.Create(TablePanel) do
  begin
  LeftButtonUpCallback := RowMouseUp;
  SetPosition(Classes.Point(ColumnRight(Column - 1),0));
  SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X,0));
  SetFontName(HitPointFontName);
  SetWordWrapEnabled(WordWrap);
  SetPositionModeW(True);
  SetTextAlignX(AlignX);
  SetTextAlignY(tayAuto);
  SetText(Text);
  SetTextColor(CurrentPixelFormat.PackRgbBytes(255,255,230));
  SetTextAlignX(AlignX);
  SetTextAlignY(AlignY);
  SetSize(Classes.Point(ClientSize.X, ClientSize.Y + ExtraHeight));
  UserValue := Row + 1;
  UserIndex := LastRow + 1;
  UserState := CurrentRowIndex;
  end;
end;
{ @end $517D84 }

{ @routine $517F08 TfRating_AddImageCell }
procedure TfRating.AddImageCell(Column, Row, LastColumn, LastRow: Integer; Path: WideString; Padding: Integer; AlignX: TImageKindXGI; AlignY: TImageKindYGI; Height: Integer);
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  with TImageGI.Create(TablePanel) do
  begin
  SetImagePath(Path);
  SetPosition(Classes.Point(ColumnRight(Column - 1) + Padding,0));
  if Height < 0 then SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X - 2 * Padding, GetContentSize.Y))
  else SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X - 2 * Padding, Height));
  SetPositionModeW(True);
  SetImageKindX(AlignX);
  SetImageKindY(AlignY);
  UserValue := Row + 1;
  UserIndex := LastRow + 1;
  UserState := CurrentRowIndex;
  end;
end;
{ @end $517F08 }

{ @routine $518060 TfRating_AddStatusCell }
procedure TfRating.AddStatusCell(Column, Row, LastColumn, LastRow, Percent, Padding: Integer; AlignX: TImageKindXGI; AlignY: TImageKindYGI);
var Animation: TgaiGI;
begin
  if Percent < 0 then Percent := 0
  else if Percent > 100 then Percent := 100;
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  Animation := TgaiGI.Create(TablePanel);
  with Animation do
  begin
    SetImagePath('Bm.FormRating.' + GiResourceSuffix + 'Status');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetSequenceFrame(Round(Percent / 100 * (SequenceFrameCount - 1)));
    StopAutoPlayback;
    SetPosition(Classes.Point(ColumnRight(Column - 1) + Padding,0));
    Animation.SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X - 2 * Padding,GetContentSize.Y));
    SetPositionModeW(True);
    SetImageKindX(AlignX);
    SetImageKindY(AlignY);
    UserValue := Row + 1;
    UserIndex := LastRow + 1;
    UserState := CurrentRowIndex;
  end;
end;
{ @end $518060 }

{ @routine $518244 TfRating_AddShipCell }
procedure TfRating.AddShipCell(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger; Padding: Integer; Animate: Boolean; AlignX: TImageKindXGI; AlignY: TImageKindYGI);
var Count, Portrait: Integer; Animation: TgaiGI;
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  Count := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Ranger.OwnerId].InternalName));
  if Ranger = Player then Portrait := 0
  else Portrait := Integer(Ranger.Seed) mod (Count - 1) + 1;
  with TImageGI.Create(TablePanel) do
  begin
    SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'i');
    SetImageKindX(AlignX);
    SetImageKindY(AlignY);
    SetPosition(Classes.Point(ColumnRight(Column - 1) + Padding,0));
    SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X - 2 * Padding,GetContentSize.Y));
    SetPositionModeW(True);
    UserValue := Row + 1;
    UserIndex := LastRow + 1;
    UserState := CurrentRowIndex;
  end;
  if Animate and AnimCaptain then
  begin
    Animation := TgaiGI.Create(TablePanel);
    with Animation do
    begin
      FirstFrameOnly := not AnimCaptain;
      UsesPlaybackBuffer := True;
      SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'a');
      SequenceIndex := 0;
      UpdateAutoGeometry;
      TransparentColor := CurrentPixelFormat.PackRgbBytes(255,0,255);
      SetImageKindX(AlignX);
      SetImageKindY(AlignY);
      SetPosition(Classes.Point(ColumnRight(Column - 1) + Padding,0));
      Animation.SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X - 2 * Padding,GetContentSize.Y));
      SetPositionModeW(True);
      RestartPlayback;
      UserValue := Row + 1;
      UserIndex := LastRow + 1;
      UserState := CurrentRowIndex;
    end;
  end;
end;
{ @end $518244 }

{ @routine $51861C TfRating_AddAwardsCell }
procedure TfRating.AddAwardsCell(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger);
var I, J: Integer; Buffer: TGraphBufGI; Path: WideString; Size, Step, Count: Integer;
  Icon: TGraphBufGR; Award: PByte;
begin
  Count := 8;
  Size := GiScalePixels(20);
  Step := Size div 2;
  if (Ranger.AwardIds <> nil) and (Ranger.AwardIds.Count >= 1) then
  begin
    Buffer := TGraphBufGI.Create(TablePanel);
    Buffer.SetImageKindX(ikxLeft);
    Buffer.SetImageKindY(ikyBottom);
    Buffer.SetPosition(Classes.Point(ColumnRight(Column - 1),0));
    Buffer.SetSize(Classes.Point(ColumnRight(LastColumn) - Buffer.LocalPosition.X,Size));
    Buffer.SetPositionModeW(True);
    Buffer.MouseMoveCallback := AwardsMouseMove;
    Buffer.MouseLeaveCallback := HintMouseLeave;
    Buffer.GraphBuf.AllocateRgbaTight(Max(Buffer.ClientSize.X, Size + Step * Count - Step),Size);
    for I := 0 to Size - 1 do
      Buffer.GraphBuf.FillRect32(Classes.Rect(0,I,Buffer.GraphBuf.Width,I + 1),Integer(Round(I / Size * 240) + 10) shl 24 or (250 shl 16) or (250 shl 8) or 50);
    Buffer.SourceHasPerPixelAlpha := True;
    Buffer.UserValue := Row + 1;
    Buffer.UserIndex := LastRow + 1;
    Buffer.UserState := CurrentRowIndex;
    Icon := TGraphBufGR.Create;
    I := Max(0,Ranger.AwardIds.Count - Count);
    J := 0;
    while I < Ranger.AwardIds.Count do
    begin
      Award := Ranger.AwardIds[I];
      if Award^ < 10 then Path := 'Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(Award^)
      else Path := 'Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(Award^);
      LoadGiByPathIntoGraphBuf(Path,Icon);
      if Cardinal(Icon.Width) >= Cardinal(Icon.Height) then
        Icon.RescaleRgba(Size,Round(Size / Cardinal(Icon.Width) * Cardinal(Icon.Height)),5)
      else Icon.RescaleRgba(Round(Size / Cardinal(Icon.Height) * Cardinal(Icon.Width)),Size,5);
      if Icon.Height > Size then AppendLogLineThreadSafe('Error: Rating RewardsBuild Y')
      else if Icon.Width + J * Step > Buffer.GraphBuf.Width then AppendLogLineThreadSafe('Error: Rating RewardsBuild X')
      else Buffer.GraphBuf.BlendRect32(Classes.Point(J * Step,0),Icon,Classes.Rect(0,0,Icon.Width,Icon.Height));
      Inc(I);
      Inc(J);
    end;
    Icon.Free;
  end;
end;
{ @end $51861C }

{ @routine $518AA0 TfRating_AddRewardButton }
procedure TfRating.AddRewardButton(Column, Row, LastColumn, LastRow: Integer; Ranger: TRanger; Offset: TPoint);
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  with TGraphButtonGI.Create(TablePanel) do
  begin
    UpCallback := RewardsClicked;
    SetName(IntToStr(Int64(Ranger.Id)));
    MouseBlocking := True;
    SetImageNormalPath('GI,Bm.FormShip.' + GiResourceSuffix + 'rewardN');
    SetImageNormalActivePath('GI,Bm.FormShip.' + GiResourceSuffix + 'rewardA');
    SetImageDownPath('GI,Bm.FormShip.' + GiResourceSuffix + 'rewardD');
    HitKind := gbhGraph;
    HelpText := IntToStr(Offset.Y);
    SetPosition(Classes.Point(ColumnRight(Column - 1) + Offset.X,0));
    SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X,GetMaxStateImageSize.Y));
    SetPositionModeW(True);
    UserValue := Row + 1;
    UserIndex := LastRow + 1;
    UserState := CurrentRowIndex;
  end;
end;
{ @end $518AA0 }

{ @routine $518D0C TfRating_AddSpacerCell }
procedure TfRating.AddSpacerCell(Column, Row, LastColumn, LastRow, Height: Integer);
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  with TObjectGI.Create(TablePanel) do
  begin
  LeftButtonUpCallback := RowMouseUp;
  SetPosition(Classes.Point(ColumnRight(Column - 1),0));
  SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X,Height));
  SetPositionModeW(True);
  UserValue := Row + 1;
  UserIndex := LastRow + 1;
  UserState := CurrentRowIndex;
  end;
end;
{ @end $518D0C }

{ @routine $518DDC TfRating_AddFillCell }
procedure TfRating.AddFillCell(Column, Row, LastColumn, LastRow: Integer; AColor: Word; Translucent: Boolean);
begin
  CurrentLineCount := Max(CurrentLineCount, Row + 1);
  CurrentLineCount := Max(CurrentLineCount, LastRow + 1);
  with TFrameGI.Create(TablePanel) do
  begin
  LeftButtonUpCallback := RowMouseUp;
  SetPosition(Classes.Point(ColumnRight(Column - 1),0));
  SetSize(Classes.Point(ColumnRight(LastColumn) - LocalPosition.X,0));
  SetPositionModeW(True);
  SetFillColor(AColor);
  SetFill(True);
  if Translucent then SetFillAlpha(64) else SetFillAlpha(255);
  UserValue := Row + 1;
  UserIndex := LastRow + 1;
  UserState := CurrentRowIndex;
  end;
end;
{ @end $518DDC }

{ @routine $518ED8 TfRating_RefreshFeaturedRangers }
procedure TfRating.RefreshFeaturedRangers;
var Ranger: TShip; Count, Portrait: Integer;
begin
  if Galaxy.EminentCareerShips[rcTrader] = nil then
  begin
    GetByName('TraderCaptainI').SetActive(False);
    GetByName('TraderCaptainA').SetActive(False);
    GetByName('BestTrader').SetActive(False);
  end
  else
  begin
    Ranger := TShip(Galaxy.EminentCareerShips[rcTrader]);
    with GetByName('BestTrader') as TLabelGI do
    begin
      SetText(Ranger.Name);
      SetActive(True);
    end;
    Count := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Ranger.OwnerId].InternalName));
    if Ranger = Player then Portrait := 0
    else Portrait := Integer(Ranger.Seed) mod (Count - 1) + 1;
    with GetByName('TraderCaptainI') as TImageGI do
    begin
      if Count > 0 then
      begin
        UserValue := Ranger.Id;
        LeftButtonDownCallback := FeaturedRangerClicked;
        SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'i');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
      end
      else SetActive(False);
    end;
    with GetByName('TraderCaptainA') as TgaiGI do
    begin
      FirstFrameOnly := not AnimCaptain;
      if Count > 0 then
      begin
        SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'a');
        SequenceIndex := 0;
        UpdateAutoGeometry;
        SetSequenceFrame(RandomIntRange(0,SequenceFrameCount - 1));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
        RestartPlayback;
      end
      else SetActive(False);
    end;
  end;
  if Galaxy.EminentCareerShips[rcWarrior] = nil then
  begin
    GetByName('WarriorCaptainI').SetActive(False);
    GetByName('WarriorCaptainA').SetActive(False);
    GetByName('BestWarrior').SetActive(False);
  end
  else
  begin
    Ranger := TShip(Galaxy.EminentCareerShips[rcWarrior]);
    with GetByName('BestWarrior') as TLabelGI do
    begin
      SetText(Ranger.Name);
      SetActive(True);
    end;
    Count := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Ranger.OwnerId].InternalName));
    if Ranger = Player then Portrait := 0
    else Portrait := Integer(Ranger.Seed) mod (Count - 1) + 1;
    with GetByName('WarriorCaptainI') as TImageGI do
    begin
      if Count > 0 then
      begin
        UserValue := Ranger.Id;
        LeftButtonDownCallback := FeaturedRangerClicked;
        SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'i');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
      end
      else SetActive(False);
    end;
    with GetByName('WarriorCaptainA') as TgaiGI do
    begin
      FirstFrameOnly := not AnimCaptain;
      if Count > 0 then
      begin
        SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'a');
        SequenceIndex := 0;
        UpdateAutoGeometry;
        SetSequenceFrame(RandomIntRange(0,SequenceFrameCount - 1));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
        RestartPlayback;
      end
      else SetActive(False);
    end;
  end;
  if Galaxy.EminentCareerShips[rcPirate] = nil then
  begin
    GetByName('PirateCaptainI').SetActive(False);
    GetByName('PirateCaptainA').SetActive(False);
    GetByName('BestPirate').SetActive(False);
  end
  else
  begin
    Ranger := TShip(Galaxy.EminentCareerShips[rcPirate]);
    with GetByName('BestPirate') as TLabelGI do
    begin
      SetText(Ranger.Name);
      SetActive(True);
    end;
    Count := StrToInt(GameDataConfig.GetParamByPath('Captain.' + OwnerInfo[Ranger.OwnerId].InternalName));
    if Ranger = Player then Portrait := 0
    else Portrait := Integer(Ranger.Seed) mod (Count - 1) + 1;
    with GetByName('PirateCaptainI') as TImageGI do
    begin
      if Count > 0 then
      begin
        UserValue := Ranger.Id;
        LeftButtonDownCallback := FeaturedRangerClicked;
        SetImagePath('GI,Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'i');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
      end
      else SetActive(False);
    end;
    with GetByName('PirateCaptainA') as TgaiGI do
    begin
      FirstFrameOnly := not AnimCaptain;
      if Count > 0 then
      begin
        SetImagePath('Bm.Captain.' + GiResourceSuffix + OwnerInfo[Ranger.OwnerId].InternalName + IntToStr(Portrait) + 'a');
        SequenceIndex := 0;
        UpdateAutoGeometry;
        SetSequenceFrame(RandomIntRange(0,SequenceFrameCount - 1));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetActive(True);
        RestartPlayback;
      end
      else SetActive(False);
    end;
  end;
end;
{ @end $518ED8 }

{ @routine $519930 TfRating_SelectMusic }
procedure TfRating.SelectMusic;
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
{ @end $519930 }

{ @routine $519AC8 TfRating_ProcessCallbackTimers }
procedure TfRating.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(2);
end;
{ @end $519AC8 }

{ @routine $519AF8 ShowRangerRating }
function ShowRangerRating(Parent: TMessageLoopGI): Boolean;
var State: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  RatingScreen.ParentLoop := Parent;
  if RatingScreen.Run = 1 then Result := True else Result := False;
  RatingScreen.ParentLoop := nil;
  Parent.InvalidateViewport;
  Parent.RestoreCursorState(@State);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
  Parent.Present;
end;
{ @end $519AF8 }

{ @routine $519BC4 TfRating_InitializeColumns }
procedure TfRating.InitializeColumns;
begin
  Columns := nil;
  SetLength(Columns,13);
  Columns[0].CanAscend := False;
  Columns[0].CanDescend := False;
  Columns[0].Ascending := False;
  Columns[1].CanAscend := True;
  Columns[1].CanDescend := True;
  Columns[1].Ascending := False;
  Columns[2].CanAscend := True;
  Columns[2].CanDescend := True;
  Columns[2].Ascending := False;
  Columns[3].CanAscend := True;
  Columns[3].CanDescend := True;
  Columns[3].Ascending := False;
  Columns[4].CanAscend := True;
  Columns[4].CanDescend := True;
  Columns[4].Ascending := False;
  Columns[5].CanAscend := False;
  Columns[5].CanDescend := False;
  Columns[5].Ascending := False;
  Columns[6].CanAscend := False;
  Columns[6].CanDescend := False;
  Columns[6].Ascending := False;
  Columns[7].CanAscend := False;
  Columns[7].CanDescend := False;
  Columns[7].Ascending := False;
  Columns[8].CanAscend := False;
  Columns[8].CanDescend := False;
  Columns[8].Ascending := False;
  Columns[9].CanAscend := False;
  Columns[9].CanDescend := False;
  Columns[9].Ascending := False;
  Columns[10].CanAscend := False;
  Columns[10].CanDescend := False;
  Columns[10].Ascending := False;
  Columns[11].CanAscend := False;
  Columns[11].CanDescend := False;
  Columns[11].Ascending := False;
  Columns[12].CanAscend := False;
  Columns[12].CanDescend := False;
  Columns[12].Ascending := False;
  SortColumn := 2;
  SelectedIndex := -1;
  SelectedRangerId := Player.Id;
end;
{ @end $519BC4 }

{ @routine $519DA0 TfRating_RebuildTable }
procedure TfRating.RebuildTable;
var I, J, Top: Integer; List: TList; First, Second: TRanger;
begin
  TablePanel.SetActive(False);
  ClearRows;
  Columns[0].Width := GiScalePixels(40);
  Columns[1].Width := GiScalePixels(120);
  Columns[2].Width := GiScalePixels(80);
  Columns[3].Width := GiScalePixels(40);
  Columns[4].Width := GiScalePixels(40);
  Columns[5].Width := GiScalePixels(40);
  Columns[5].Width := GiScalePixels(40);
  Columns[6].Width := GiScalePixels(40);
  Columns[7].Width := GiScalePixels(40);
  Columns[8].Width := GiScalePixels(40);
  Columns[9].Width := GiScalePixels(40);
  Columns[10].Width := GiScalePixels(40);
  Columns[11].Width := GiScalePixels(40);
  Columns[12].Width := GiScalePixels(40);
  Columns[High(Columns)].Width := Max(Columns[High(Columns)].Width,TablePanel.ClientSize.X - ColumnRight(High(Columns) - 1));
  AddColumnLine(0,0,True);
  AddColumnLine(1,0,True);
  AddColumnLine(2,0,True);
  AddColumnLine(5,-1,False);
  AddColumnLine(8,-1,False);
  AddColumnHeader(0,0,0,WrapTextInColor(' ' + LookupLocalizedTextByKey('FormRating.Number'),HighlightColorTag));
  AddColumnHeader(1,1,1,WrapTextInColor(LookupLocalizedTextByKey('FormRating.Name'),HighlightColorTag));
  AddColumnHeader(2,2,2,WrapTextInColor(LookupLocalizedTextByKey('FormRating.Points'),HighlightColorTag));
  AddColumnHeader(3,5,3,WrapTextInColor(LookupLocalizedTextByKey('FormRating.Race'),HighlightColorTag));
  AddColumnHeader(6,8,4,WrapTextInColor(LookupLocalizedTextByKey('FormRating.Rank'),HighlightColorTag));
  AddColumnHeader(9,12,5,WrapTextInColor(LookupLocalizedTextByKey('FormRating.Character'),HighlightColorTag));
  List := TList.Create;
  for I := 0 to Galaxy.Rangers.Count - 1 do List.Add(Galaxy.Rangers[I]);
  for I := 0 to List.Count - 2 do
    for J := I + 1 to List.Count - 1 do
    begin
      First := List[I];
      Second := List[J];
      if SortColumn = 1 then
      begin
        if Columns[SortColumn].Ascending then
        begin
          if AnsiStrComp(PAnsiChar(AnsiString(Second.Name)),PAnsiChar(AnsiString(First.Name))) > 0 then List.Exchange(I,J);
        end
        else if AnsiStrComp(PAnsiChar(AnsiString(Second.Name)),PAnsiChar(AnsiString(First.Name))) < 0 then List.Exchange(I,J);
      end
      else if SortColumn = 2 then
      begin
        if Columns[SortColumn].Ascending then
        begin
          if Second.TotalExperience < First.TotalExperience then List.Exchange(I,J);
        end
        else if Second.TotalExperience > First.TotalExperience then List.Exchange(I,J);
      end
      else if SortColumn = 3 then
      begin
        if Columns[SortColumn].Ascending then
        begin
          if Ord(Second.OwnerId) < Ord(First.OwnerId) then List.Exchange(I,J);
        end
        else if Ord(Second.OwnerId) > Ord(First.OwnerId) then List.Exchange(I,J);
      end
      else if SortColumn = 4 then
      begin
        if Columns[SortColumn].Ascending then
        begin
          if Ord(Second.Rank) < Ord(First.Rank) then List.Exchange(I,J);
        end
        else if Ord(Second.Rank) > Ord(First.Rank) then List.Exchange(I,J);
      end;
    end;
  Rows := nil;
  if List.Count > 0 then
  begin
    SetLength(Rows,List.Count);
    for I := 0 to List.Count - 1 do
    begin
      Rows[I].Ranger := List[I];
      Rows[I].Top := 0;
      Rows[I].Height := 0;
      if (SelectedIndex < 0) and (Rows[I].Ranger.Id = Cardinal(SelectedRangerId)) then SelectedIndex := I;
    end;
  end;
  List.Free;
  Top := 0;
  for I := 0 to High(Rows) do
  begin
    Rows[I].Top := Top;
    CreateRow(I);
    Inc(Top,Rows[I].Height);
  end;
  TablePanel.SetActive(True);
  TablePanel.UpdateScrollRanges;
  TablePanel.ScrollRectIntoView(SelectedRowRect);
end;
{ @end $519DA0 }

{ @routine $51A58C TfRating_RebuildRow }
procedure TfRating.RebuildRow(Index: Integer);
var Control, Old: TObjectGI; HeightChange, I, RowIndex: Integer;
begin
  Control := TablePanel.FirstChild;
  while Control <> nil do
  begin
    Old := Control;
    Control := Control.NextSibling;
    RowIndex := Old.UserState;
    if Index = RowIndex then Old.Free;
  end;
  HeightChange := Rows[Index].Height;
  CreateRow(Index);
  HeightChange := Rows[Index].Height - HeightChange;
  for I := Index + 1 to High(Rows) do Inc(Rows[I].Top, HeightChange);
  Control := TablePanel.FirstChild;
  while Control <> nil do
  begin
    if Cardinal(Control.UserState) > Cardinal(Index) then
      Control.SetPosition(Classes.Point(Control.LocalPosition.X, Control.LocalPosition.Y + HeightChange));
    Control := Control.NextSibling;
  end;
end;
{ @end $51A58C }

{ @routine $51A654 TfRating_SelectRow }
procedure TfRating.SelectRow(Index: Integer);
var OldIndex: Integer;
begin
  if Index = SelectedIndex then Exit;
  OldIndex := SelectedIndex;
  SelectedIndex := Index;
  RebuildRow(OldIndex);
  RebuildRow(SelectedIndex);
  SelectedRowRect := Classes.Rect(0, Rows[Index].Top, 1, Rows[Index].Top + Rows[Index].Height);
  TablePanel.ScrollRectIntoView(SelectedRowRect);
  HideAwardHint;
end;
{ @end $51A654 }

{ @routine $51A6E8 TfRating_CreateRow }
procedure TfRating.CreateRow(Index: Integer);
var Ranger: TRanger; Color: Word; Name: WideString;
begin
  Ranger := Rows[Index].Ranger;
  BeginRow(Index);
  if Index = SelectedIndex then
    case Ranger.OwnerId of
      oiMaloc: Color := CurrentPixelFormat.PackRgbBytes(255,0,0);
      oiPeleng: Color := CurrentPixelFormat.PackRgbBytes(0,100,0);
      oiPeople: Color := CurrentPixelFormat.PackRgbBytes(10,10,30);
      oiFei: Color := CurrentPixelFormat.PackRgbBytes(60,30,60);
      oiGaal: Color := CurrentPixelFormat.PackRgbBytes(111,120,30);
      oiKling: Color := CurrentPixelFormat.PackRgbBytes(97,167,190);
      else Color := CurrentPixelFormat.PackRgbBytes(255,0,255);
    end
  else if (Index and 1) = 0 then Color := CurrentPixelFormat.PackRgbBytes(0,0,155)
  else Color := CurrentPixelFormat.PackRgbBytes(0,0,70);
  if Index = SelectedIndex then
  begin
    AddFillCell(0,0,12,11,Color,True);
    if Index <> 0 then AddFillCell(0,0,12,0,CurrentPixelFormat.PackRgbBytes(0,0,0),False);
    AddSpacerCell(0,0,0,0,1);
    AddTextCell(0,2,0,11,IntToStr(Index + 1) + '',taxCenter,tayCenterEx,True,0);
    Name := WrapTextInColor(Ranger.GetName,'');
    if Ranger.IsInPrison then Name := Name + #13#10 + WrapTextInColor(FormatText1(LookupLocalizedTextByKey('FormRating.InPrisonFull'),'','<Planet>',Ranger.CurrentPlanet.Name),'<color=5,5,5>')
    else if Ranger.PartnerShip <> nil then Name := Name + #13#10 + WrapTextInColor(FormatText1(LookupLocalizedTextByKey('FormRating.PartnerFull'),HighlightColorTag,'<Ranger>',Ranger.PartnerShip.Name),'<color=5,5,5>');
    AddTextCell(1,2,1,11,Name,taxCenter,tayCenterEx,True,0);
    AddTextCell(2,2,2,11,IntToStr(Ranger.TotalExperience),taxCenter,tayCenterEx,True,0);
    AddSpacerCell(0,2,0,2,17);
    AddSpacerCell(0,3,0,3,17);
    AddSpacerCell(0,4,0,4,17);
    AddSpacerCell(0,6,0,6,17);
    AddSpacerCell(0,8,0,8,17);
    AddFillCell(3,5,6,5,CurrentPixelFormat.PackRgbBytes(0,0,0),False);
    AddSpacerCell(3,5,6,5,1);
    AddFillCell(3,7,10,7,CurrentPixelFormat.PackRgbBytes(0,0,0),False);
    AddSpacerCell(3,7,10,7,1);
    AddFillCell(3,9,10,9,CurrentPixelFormat.PackRgbBytes(0,0,0),False);
    AddSpacerCell(3,9,10,9,1);
    AddImageCell(6,5,6,7,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(10,2,10,11,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(4,7,4,11,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(6,2,6,11,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(8,7,8,11,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(12,2,12,11,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddTextCell(3,2,4,2,LookupLocalizedTextByKey('FormRating.Character') + ':',taxRight,tayTop,False,0);
    AddTextCell(5,2,7,2,Ranger.GetCharacterName,taxLeft,tayTop,False,0);
    AddTextCell(3,3,4,3,LookupLocalizedTextByKey('FormRating.Rank') + ':',taxRight,tayTop,False,0);
    AddTextCell(5,3,7,3,Ranger.GetRankName,taxLeft,tayTop,False,0);
    AddTextCell(3,4,6,4,LookupLocalizedTextByKey('FormRating.LiberationSystem') + ': ' + IntToStr(Ranger.ScriptStatistics[ssSystemsLiberated]),taxCenter,tayTop,False,0);
    AddTextCell(3,6,6,6,LookupLocalizedTextByKey('FormRating.Kill'),taxCenter,tayTop,True,0);
    AddTextCell(3,8,4,8,LookupLocalizedTextByKey('FormRating.Kling'),taxCenter,tayTop,True,0);
    AddTextCell(3,10,4,10,IntToStr(Ranger.ScriptStatistics[ssKlissansKilled]),taxCenter,tayTop,False,3);
    AddTextCell(5,8,6,8,LookupLocalizedTextByKey('FormRating.Pirate'),taxCenter,tayTop,True,0);
    AddTextCell(5,10,6,10,IntToStr(Ranger.ScriptStatistics[ssPiratesKilled]),taxCenter,tayTop,False,3);
    AddTextCell(7,8,8,8,LookupLocalizedTextByKey('FormRating.Other'),taxCenter,tayTop,True,0);
    AddTextCell(7,10,8,10,IntToStr(Ranger.ScriptStatistics[ssShipsKilled] - Ranger.ScriptStatistics[ssPiratesKilled] - Ranger.ScriptStatistics[ssKlissansKilled]),taxCenter,tayTop,False,3);
    AddTextCell(9,8,10,8,LookupLocalizedTextByKey('FormRating.KillAllShip'),taxCenter,tayTop,True,0);
    AddTextCell(9,10,10,10,IntToStr(Ranger.ScriptStatistics[ssShipsKilled]),taxCenter,tayTop,False,3);
    AddTextCell(7,2,10,2,LookupLocalizedTextByKey('FormRating.Strength') + ':',taxCenter,tayTop,True,0);
    AddStatusCell(7,3,10,3,Round(100 / (Galaxy.FindStrongestRanger as TRanger).Strength * Ranger.Strength),0,ikxCenter,ikyCenter);
    AddTextCell(7,4,10,4,LookupLocalizedTextByKey('FormRating.Capital') + ':',taxCenter,tayTop,True,0);
    AddStatusCell(7,6,10,6,Round(100 / (Galaxy.FindWealthiestRanger as TRanger).Wealth * Ranger.Wealth),0,ikxCenter,ikyCenter);
    AddShipCell(11,2,12,10,Ranger,GiScalePixels(1),True,ikxRight,ikyCenter);
    if (Ranger.AwardIds <> nil) and (Ranger.AwardIds.Count > 0) then
      if Ranger.AwardIds.Count > 8 then
      begin
        if GiResourceVariant = 2 then AddRewardButton(11,2,12,10,Ranger,Classes.Point(50,67))
        else AddRewardButton(11,2,12,10,Ranger,Classes.Point(42,73));
      end
      else AddAwardsCell(11,2,12,10,Ranger);
    FinishRow(Ranger.Id,True);
  end
  else
  begin
    AddFillCell(0,0,12,3,Color,True);
    if Index <> 0 then AddFillCell(0,0,12,0,CurrentPixelFormat.PackRgbBytes(0,0,0),False);
    AddSpacerCell(0,0,0,0,1);
    AddSpacerCell(0,1,0,1,4);
    AddImageCell(5,0,5,3,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddImageCell(8,0,8,3,'GI,Bm.FormRating.2VLine',0,ikxRight,ikyCenter,1);
    AddTextCell(0,2,0,2,IntToStr(Index + 1) + '',taxCenter,tayCenterEx,True,0);
    Name := WrapTextInColor(Ranger.GetName,'');
    if Ranger.IsInPrison then Name := Name + #13#10 + WrapTextInColor(FormatText1(LookupLocalizedTextByKey('FormRating.InPrison'),'','<Planet>',Ranger.CurrentPlanet.Name),'<color=5,5,5>')
    else if Ranger.PartnerShip <> nil then Name := Name + #13#10 + WrapTextInColor(FormatText1(LookupLocalizedTextByKey('FormRating.Partner'),HighlightColorTag,'<Ranger>',Ranger.PartnerShip.Name),'<color=5,5,5>');
    AddTextCell(1,2,1,2,Name,taxCenter,tayCenterEx,True,0);
    AddTextCell(2,2,2,2,IntToStr(Ranger.TotalExperience),taxCenter,tayCenterEx,True,0);
    AddImageCell(3,2,5,2,GetRaceEmblemPath(Ranger.OwnerId),0,ikxCenter,ikyCenter,-1);
    AddImageCell(6,2,8,2,GetRankImagePath(Ranger.Rank),0,ikxCenter,ikyCenter,-1);
    AddTextCell(9,2,12,2,Ranger.GetCharacterName,taxCenter,tayCenterEx,True,0);
    AddSpacerCell(0,3,0,3,4);
    FinishRow(Ranger.Id,False);
  end;
end;
{ @end $51A6E8 }

end.

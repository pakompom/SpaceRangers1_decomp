unit fRewards;
// Unit bracket (inferred): CODE 0x00515CB8..0x00516AC3; inclusive evidence, not full bounds.
// The medal display is a read-only, staggered three-column platform layout.
interface
uses GI_MessageLoop, GI_PanelScrollBar, aShip;
type
  TfRewards = class(TMessageLoopGI) // @size $BC
  public
    ParentLoop: TMessageLoopGI; // @offset $B0
    AwardsPanel: TPanelScrollBarGI; // @offset $B4
    Ship: TShip; // @offset $B8 Borrowed award subject.
    procedure InitializeLayout; override; // @addr $515D40
    procedure OnOpen; override; // @addr $515DEC
    procedure OnClose; override; // @addr $515EB0
    procedure CloseClicked(Sender: TObjectGI); // @addr $515EC8
    procedure PlatformMouseEnter(Sender: TObjectGI); // @addr $515EF8
    procedure ClearHighlight(Sender: TObjectGI); // @addr $51614C
    procedure BuildAwardControls; // @addr $51630C
    procedure ProcessCallbackTimers; override; // @addr $5167B8
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $516830
    procedure SelectMusic; override; // @addr $516878
  end;
function RunRewards(Parent: TMessageLoopGI): Boolean; // @addr $5169C8
implementation

// @unit-initialization $516ABC
// @unit-finalization $516A8C

uses Classes, SysUtils, Math, Windows, EC_Struct, GI_Image, GI_Label, GI_GraphButton,
  GI_GraphBuf, GR_Main, GR_Music, aPlayer, aNormalShip, aPlanet, aConst, aMyFunction,
  Globals, GlobalsV, fShip2, fRating;

{ @routine $515D40 TfRewards_InitializeLayout }
procedure TfRewards.InitializeLayout;
begin
  inherited InitializeLayout;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  (GetByName('ButExit') as TGraphButtonGI).UpCallback := CloseClicked;
  AwardsPanel := GetByName('PTable') as TPanelScrollBarGI;
end;
{ @end $515D40 }

{ @routine $515DEC TfRewards_OnOpen }
procedure TfRewards.OnOpen;
begin
  inherited OnOpen;
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  Ship := AwardSubject as TShip;
  AwardsPanel.SetScrollOffset(Classes.Point(0, 0));
  BuildAwardControls;
  ClearHighlight(nil);
end;
{ @end $515DEC }

{ @routine $515EB0 TfRewards_OnClose }
procedure TfRewards.OnClose;
begin
  AwardsPanel.FreeOwnedChildren;
  inherited OnClose;
end;
{ @end $515EB0 }

{ @routine $515EC8 TfRewards_CloseClicked }
procedure TfRewards.CloseClicked(Sender: TObjectGI);
begin
  if Player = Ship then RequestedScreenId := screenShip
  else RequestedScreenId := screenScanner;
  RequestClose(1);
end;
{ @end $515EC8 }

{ @routine $515EF8 TfRewards_PlatformMouseEnter }
procedure TfRewards.PlatformMouseEnter(Sender: TObjectGI);
var
  Obj: TObjectGI;
  Platform: TImageGI;
  AwardId: Integer;
begin
  Platform := TImageGI(Sender.UserValue);
  AwardId := Sender.UserIndex;
  with GetByName('InfoZag') as TLabelGI do
    SetText((Ship as TNormalShip).GetAwardInfo(AwardId).Name);
  with GetByName('Info') as TLabelGI do
    SetText((Ship as TNormalShip).GetAwardInfo(AwardId).Text);
  Obj := AwardsPanel.FirstChild;
  while Obj <> nil do
  begin
    if Obj is TImageGI then
      with TImageGI(Obj) do
        if GetImagePath = 'GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA' then
          SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Obj := Obj.NextSibling;
  end;
  Platform.SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA');
  GetByName('ButExit').SetActive(False);
end;
{ @end $515EF8 }

{ @routine $51614C TfRewards_ClearHighlight }
procedure TfRewards.ClearHighlight(Sender: TObjectGI);
var Obj: TObjectGI;
begin
  with GetByName('InfoZag') as TLabelGI do SetText('');
  with GetByName('Info') as TLabelGI do SetText('');
  Obj := AwardsPanel.FirstChild;
  while Obj <> nil do
  begin
    if Obj is TImageGI then
      with TImageGI(Obj) do
        if GetImagePath = 'GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformA' then
          SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Obj := Obj.NextSibling;
  end;
  GetByName('ButExit').SetActive(True);
end;
{ @end $51614C }

{ @routine $51630C TfRewards_BuildAwardControls }
procedure TfRewards.BuildAwardControls;
var
  I, Count, X, Y: Integer;
  Platform: TImageGI;
  Award: PByte;
begin
  AwardsPanel.FreeOwnedChildren;
  if Ship.AwardIds <> nil then Count := Max(10, Ship.AwardIds.Count) else Count := 10;
  if Count > 10 then Count := ((Count + 2) div 3) * 3;
  with TObjectGI.Create(AwardsPanel) do
  begin
    SetPosition(Classes.Point(0, 0));
    SetSize(Classes.Point(1, 1));
    SetPositionModeW(True);
  end;
  for I := 0 to Count - 1 do
  begin
    Platform := TImageGI.Create(AwardsPanel);
    Platform.SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + 'PlatformN');
    Platform.SetSize(Platform.GetContentSize);
    Platform.SetOrigin(HalfPoint(Platform.ClientSize));
    X := 0;
    Y := AwardsPanel.ClientSize.Y div 4 * (I div 3) + (AwardsPanel.ClientSize.Y div 4 - Platform.ClientSize.Y div 2) + GiScalePixels(50);
    case I mod 3 of
      0: begin
        X := AwardsPanel.ClientSize.X div 2;
        Dec(Y, GiScalePixels(50));
      end;
      1: X := Platform.ClientSize.X div 2;
      2: X := AwardsPanel.ClientSize.X - Platform.ClientSize.X div 2 - 2;
    end;
    Platform.SetPosition(Classes.Point(X, Y));
    Platform.SetPositionModeW(True);
    if (Ship.AwardIds <> nil) and (I < Ship.AwardIds.Count) then
    begin
      Platform.UserValue := Integer(Platform);
      Platform.UserIndex := 0;
      Platform.MouseEnterCallback := PlatformMouseEnter;
    end
    else
    begin
      Platform.UserValue := 0;
      Platform.UserIndex := 0;
    end;
    if (Ship.AwardIds <> nil) and (I < Ship.AwardIds.Count) then
    begin
      Award := Ship.AwardIds[I];
      with TImageGI.Create(AwardsPanel) do
      begin
        if Award^ < 10 then SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + '_0' + IntToStr(Award^))
        else SetImagePath('GI,Bm.FormRewards.' + GiResourceSuffix + '_' + IntToStr(Award^));
        SetSize(GetContentSize);
        SetOrigin(Classes.Point(ClientSize.X div 2, ClientSize.Y));
        SetPositionModeW(True);
        SetPosition(Classes.Point(X, Y));
        UserValue := Integer(Platform);
        UserIndex := Award^;
        Platform.UserIndex := Award^;
        MouseEnterCallback := PlatformMouseEnter;
      end;
    end;
  end;
  AwardsPanel.MouseLeaveCallback := ClearHighlight;
  AwardsPanel.UpdateScrollRanges;
  AwardsPanel.SetVerticalScrollbarEnabled(Count > 10);
end;
{ @end $51630C }

{ @routine $5167B8 TfRewards_ProcessCallbackTimers }
procedure TfRewards.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if ((ParentLoop <> nil) and (ParentLoop is TfShip2) and (TfShip2(ParentLoop).ParentLoop.ExitCode <> 0) and (ExitCode = 0)) or
    ((ParentLoop <> nil) and (ParentLoop is TfRating) and (TfRating(ParentLoop).ParentLoop.ExitCode <> 0) and (ExitCode = 0)) then RequestClose(2);
end;
{ @end $5167B8 }

{ @routine $516830 TfRewards_MainPanelKeyDown }
procedure TfRewards.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or
    IsVirtualKeyDown(VK_MENU) then Exit;
  if (Key = VK_ESCAPE) or (Key = VK_RETURN) then CloseClicked(nil);
end;
{ @end $516830 }

{ @routine $516878 TfRewards_SelectMusic }
procedure TfRewards.SelectMusic;
begin
  if Player.IsOnPlanet then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
  end
  else if Player.IsDockedToShip then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
  end
  else if Player.InNormalSpace then MusicManager.PlayCategory('StarMap');
end;
{ @end $516878 }

{ @routine $5169C8 RunRewards }
function RunRewards(Parent: TMessageLoopGI): Boolean;
var State: TCursorStateGI;
begin
  Parent.RootUiObject.NativeHook50;
  Parent.CaptureCursorState(@State);
  Parent.SetCursorActive(False);
  Parent.DrawQueuedUpdateRects;
  RewardsScreen.ParentLoop := Parent;
  if RewardsScreen.Run = 1 then Result := True else Result := False;
  RewardsScreen.ParentLoop := nil;
  Parent.InvalidateViewport;
  Parent.RestoreCursorState(@State);
  Parent.UpdateCursorPosition;
  Parent.RootUiObject.NativeHook48;
end;
{ @end $5169C8 }

end.

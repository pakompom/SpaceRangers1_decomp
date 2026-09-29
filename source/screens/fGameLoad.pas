unit fGameLoad;
// Unit bracket (inferred): CODE 0x0054F318..0x0054FAD7; inclusive evidence, not full bounds.
// Save loading and asset preloading run separately; the displayed progress advances gradually.
interface
uses GI_MessageLoop, EC_Thread;
type
  TThreadGameLoad = class(TThreadEC) // @size $30
  public
    Succeeded: Boolean; // @offset $2C
    procedure Execute; override; // @addr $54F400
  end;
  TfGameLoad = class(TMessageLoopGI) // @size $C8
  public
    LoadThread: TThreadGameLoad; // @offset $B0
    ProgressTimer: TCallbackTimerIdGI; // @offset $B4
    AssetPreloadStarted: Boolean; // @offset $B8
    TargetProgress: Single; // @offset $BC
    DisplayedProgress: Single; // @offset $C0
    LoadingComplete: Boolean; // @offset $C4
    procedure OnOpen; override; // @addr $54F418
    procedure OnClose; override; // @addr $54F578
    function IsLoading: Boolean; // @addr $54F71C
    procedure UpdateLoadingProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $54F740
    procedure SetProgress(Progress: Single); // @addr $54F9B4
    procedure SelectMusic; override; // @addr $54FA9C
  end;
implementation
// @unit-initialization $54FAD0
// @unit-finalization $54FAA0
uses Classes, Math, GR_Main, GR_Music, GI_Main, GI_Image, GI_MessageBox,
  Globals, GlobalsV, aSaveLoad, aConst, aPlayer, aShip, aPlanet, aGalaxy, fLoad, fStarMap;

{ @routine $54F400 TThreadGameLoad_Execute }
procedure TThreadGameLoad.Execute;
begin
  Succeeded := False;
  Succeeded := LoadGameFromFile(PendingLoadFileName);
end;
{ @end $54F400 }

{ @routine $54F418 TfGameLoad_OnOpen }
procedure TfGameLoad.OnOpen;
begin
  MusicManager.RequestFadeOut;
  TargetProgress := 0;
  DisplayedProgress := 0;
  LoadingComplete := False;
  if Galaxy <> nil then
  begin
    Galaxy.Free;
    Galaxy := nil;
  end;
  AssetPreloadStarted := False;
  LoadThread := TThreadGameLoad.Create;
  LoadThread.SetPriority(2);
  LoadThread.Start;
  ProgressTimer := ScheduleCallbackTimer(20, 20, UpdateLoadingProgress);
  with GetByName('Fon') as TImageGI do SetImagePath('GI,Bm.SI.' + GiResourceSuffix + 'BG_TakeOff2');
  SetProgress(0);
end;
{ @end $54F418 }

{ @routine $54F578 TfGameLoad_OnClose }
procedure TfGameLoad.OnClose;
begin
  if LoadThread <> nil then
  begin
    LoadThread.Free;
    LoadThread := nil;
  end;
  if ProgressTimer <> 0 then
  begin
    CancelCallbackTimer(ProgressTimer);
    ProgressTimer := 0;
  end;
  if Player = nil then MusicManager.PlayCategory('Base')
  else if Player.IsOnPlanet then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName)
  else if Player.IsDockedToShip then
    MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName)
  else if Player.InNormalSpace then
  begin
    if MusicInSpace then MusicManager.PlayCategory('StarMap')
    else MusicManager.RequestFadeOut;
  end;
  // Immediately requests a fade even after selecting the destination category.
  MusicManager.RequestFadeOut;
end;
{ @end $54F578 }

{ @routine $54F71C TfGameLoad_IsLoading }
function TfGameLoad.IsLoading: Boolean;
begin
  if (LoadThread <> nil) and LoadThread.IsRunning then Result := True
  else Result := False;
end;
{ @end $54F71C }

{ @routine $54F740 TfGameLoad_UpdateLoadingProgress }
procedure TfGameLoad.UpdateLoadingProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Loads: TList;
begin
  if LoadThread.IsRunning then
  begin
    if (LoadingFilmCount < 0) and (ActiveLoadBuffer <> nil) then
      TargetProgress := ActiveLoadBuffer.Position / ActiveLoadBuffer.DataSize * 0.5;
  end
  else if not LoadingComplete then
  begin
    if not LoadThread.Succeeded then
    begin
      ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormSaveManager.LoadError'), mbgOK);
      RequestedScreenId := screenMainMenu;
      RequestClose(1);
      Exit;
    end;
    if not AssetPreloadStarted then
    begin
      Loads := TList.Create;
      StarMapScreen.ResumeMode := 1;
      if ScreenUsesCompositeLoadAssets(RequestedScreenId) then QueueSpaceLoadingAssets(Loads, RootUiObject);
      if Loads.Count < 1 then
      begin
        Loads.Free;
        TargetProgress := 1;
        LoadingComplete := True;
        AssetPreloadStarted := True;
      end
      else
      begin
        CacheLoader.SetPendingLoads(Loads, True);
        AssetPreloadStarted := True;
      end;
    end
    else if not CacheLoader.IsRunning then
    begin
      LoadingComplete := True;
      TargetProgress := 1;
    end
    else TargetProgress := CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount * 0.5 + 0.5;
  end;
  if DisplayedProgress < TargetProgress then
  begin
    DisplayedProgress := Min(0.005 + DisplayedProgress, TargetProgress);
    SetProgress(DisplayedProgress);
  end;
  if LoadingComplete and (DisplayedProgress >= 0.999) then RequestClose(1);
end;
{ @end $54F740 }

{ @routine $54F9B4 TfGameLoad_SetProgress }
procedure TfGameLoad.SetProgress(Progress: Single);
var X: Integer;
begin
  X := Round(Cardinal(GameScreenWidth) * Progress);
  with GetByName('PBmin') do
  begin
    SetActive(GameScreenWidth - X > 0);
    if Active then
    begin
      SetPosition(Classes.Point(X, LocalPosition.Y));
      SetSize(Classes.Point(GameScreenWidth - X, ClientSize.Y));
    end;
  end;
  with GetByName('PBmax') do
  begin
    SetActive(X > 0);
    if Active then SetSize(Classes.Point(X, ClientSize.Y));
  end;
end;
{ @end $54F9B4 }

{ @routine $54FA9C TfGameLoad_SelectMusic }
procedure TfGameLoad.SelectMusic;
begin
end;
{ @end $54FA9C }
end.

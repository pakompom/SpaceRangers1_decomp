unit fFilm;
// Unit bracket (inferred): CODE 0x0055FC44..0x00561777; inclusive evidence, not full bounds.

interface

uses EC_Struct, EC_Thread, GI_GraphBuf, GI_GraphButton, GI_Label, GI_MessageLoop, GI_Panel, GI_ScrollBar, Types, aEFilm;

type
  TfFilmLoader = class(TThreadEC) // @size $2C
  public
    procedure Execute; override; // @addr $55FD28 @note "Loads FilmScreen.PreloadHistoryIndex into PreloadedFilm and supplies its separately stored Turn."
  end;

  TfFilm = class(TMessageLoopGI) // @size $110
  public
    PanTimer: TCallbackTimerIdGI; // @offset $B0
    PanLeft: Boolean; // @offset $B4
    PanRight: Boolean; // @offset $B5
    PanUp: Boolean; // @offset $B6
    PanDown: Boolean; // @offset $B7
    Playing: Boolean; // @offset $B8
    CenterShipButton: TGraphButtonGI; // @offset $BC
    SpacePanel: TPanelGI; // @offset $C0
    MapPanel: TObjectGI; // @offset $C4
    FrameSlider: TScrollBarGI; // @offset $C8
    SpeedSlider: TScrollBarGI; // @offset $CC
    TurnSlider: TScrollBarGI; // @offset $D0
    PlayButton: TGraphButtonGI; // @offset $D4
    StopButton: TGraphButtonGI; // @offset $D8
    DateLabel: TLabelGI; // @offset $DC
    Loader: TfFilmLoader; // @offset $E0
    CurrentFilm: TEFilm; // @offset $E4
    PreloadedFilm: TEFilm; // @offset $E8
    CurrentHistoryIndex: Integer; // @offset $EC
    PreloadHistoryIndex: Integer; // @offset $F0
    CameraTarget: TPointF; // @offset $F4
    FrameIntervalMs: Integer; // @offset $FC
    PlaybackTimer: TCallbackTimerIdGI; // @offset $100
    EffectsTimer: TCallbackTimerIdGI; // @offset $104
    StepIndex: Integer; // @offset $108
    NextCommand: PEFilmCommand; // @offset $10C

    procedure SelectMusic; override; // @addr $561700
    procedure InitializeLayout; override; // @addr $55FD8C
    procedure OnOpen; override; // @addr $55FFC8
    procedure OnClose; override; // @addr $560288
    function GetViewOffset: TPoint; // @addr $5603C0
    procedure SetViewOffset(Offset: TPoint); // @addr $560418 @note "Disables automatic camera following."
    procedure FollowViewOffset(Offset: TPoint); // @addr $5604A0 @note "Ignored while automatic camera following is disabled."
    procedure PanView(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $560528
    procedure KeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $560640
    procedure KeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $5606E0
    procedure CopyLiveVisualStateToFilm; // @addr $560718
    procedure CopyFilmVisualStateToLive; // @addr $56099C
    procedure ExitClicked(Sender: TObjectGI); // @addr $560C20
    procedure CenterShipClicked(Sender: TObjectGI); // @addr $560C40
    procedure SelectHistoryEntry(Index: Integer; InitialLoad: Boolean); // @addr $560C60 @note "Waits for the loader, swaps film buffers, resets the command cursor, then preloads the following entry. Requires a valid index and nonempty command stream."
    procedure CreateFilmSceneObjects(Film: TEFilm); // @addr $560FC4
    procedure ReleaseFilmSceneObjects(Film: TEFilm; ReleaseTrailingReferences: Boolean); // @addr $560FFC
    procedure ReuseSceneObjectsForPreloadedFilm; // @addr $561088
    procedure AdvancePausedEffects(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $561104
    procedure SetFrameInterval(IntervalMs: Integer; UpdateSlider: Boolean); // @addr $56114C
    procedure SpeedSliderChanged(Sender: TObjectGI); // @addr $5611F4
    procedure FrameSliderChanged(Sender: TObjectGI); // @addr $561240 @note "Backward seeking reloads the recording and executes commands forward to the requested step."
    procedure PlayStopClicked(Sender: TObjectGI); // @addr $5612A8
    procedure TurnSliderChanged(Sender: TObjectGI); // @addr $5612F8
    procedure StartPlayback; // @addr $561334
    procedure PausePlayback; // @addr $5613A0 @note "Trailing effects continue on a separate timer."
    procedure AdvancePlayback(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $561438 @note "Automatically advances to the following retained recording when this one ends."
    procedure AdvanceOneStep; // @addr $561488 @note "Requires NextCommand <> nil."
    procedure InvalidateAnimatedControls; // @addr $5615A8
    procedure DrawFrame; override; // @addr $5615D0
  end;

implementation

// @unit-initialization $561770
// @unit-finalization $561740

uses SysUtils, Math, Windows, fFilmFile, Globals, GlobalsV, GR_Main,
  GR_Music, GR_Sound, GI_Main, aMyFunction, aPlayer, aShip, aEFilmEnd, SE_Process,
  SE_Space, SE_Ship2, SE_Weapon, SE_Star, SE_Planet, SE_Sputnik, SE_Asteroid,
  aGalaxy, aPlanet, aAsteroid, GI_StarField, GI_StarFieldImg, GI_SpaceImg,
  GR_Rect, GR_GraphBuf, Classes, fStarMap;

{ @routine $55FD28 TfFilmLoader_Execute }
procedure TfFilmLoader.Execute;
begin
  FilmHistory.LoadFilm(FilmHistory.GetEntry(FilmScreen.PreloadHistoryIndex), FilmScreen.PreloadedFilm);
  FilmScreen.PreloadedFilm.Turn := FilmHistory.GetEntry(FilmScreen.PreloadHistoryIndex).Turn;
end;
{ @end $55FD28 }

{ @routine $55FD8C TfFilm_InitializeLayout }
procedure TfFilm.InitializeLayout;
var
  Graph: TGraphBufGI;
begin
  inherited InitializeLayout;
  CenterShipButton := GetByName('CenterShip') as TGraphButtonGI;
  CenterShipButton.DownCallback := CenterShipClicked;
  SpacePanel := GetByName('MainPanel') as TPanelGI;
  MapPanel := GetByName('MapPanel');
  FrameSlider := GetByName('SBFrame') as TScrollBarGI;
  SpeedSlider := GetByName('SBSpeed') as TScrollBarGI;
  PlayButton := GetByName('PF_Play') as TGraphButtonGI;
  StopButton := GetByName('PF_Stop') as TGraphButtonGI;
  TurnSlider := GetByName('PF_SBTurn') as TScrollBarGI;
  DateLabel := GetByName('PF_Date') as TLabelGI;
  SpacePanel.ScrollType := pstSimple;
  Graph := MapPanel as TGraphBufGI;
  Graph.GraphBuf.AttachPixels(RenderScratchBuffer.Width, RenderScratchBuffer.Height,
    RenderScratchBuffer.PitchBytes, RenderScratchBuffer.Pixels);
end;
{ @end $55FD8C }

{ @routine $55FFC8 TfFilm_OnOpen }
procedure TfFilm.OnOpen;
var Stars: TStarFieldImgGI;
begin
  GetByName('FPS').SetActive(ShowFPS);
  Stars := GetByName('StarFieldImg') as TStarFieldImgGI;
  Stars.SetActive(WindDensity >= 2);
  if Stars.StarCount <= 0 then Stars.SeedStars;
  Stars.CopyStarsFrom(StarMapScreen.GetByName('StarFieldImg') as TStarFieldImgGI);
  FindControlByPath('StarFieldM').SetActive(WindDensity >= 1);
  UpdateRectsEnabled := False;
  SetViewOffset(TruncatePointF(SpaceViewPosition));
  UpdateRectsEnabled := True;
  PreloadHistoryIndex := -1;
  if Loader <> nil then
  begin
    Loader.Free;
    Loader := nil;
  end;
  Loader := TfFilmLoader.Create;
  Loader.SetPriority(1);
  PanTimer := ScheduleCallbackTimer(ScrollTime, ScrollTime, PanView);
  ContentPanel.KeyDownCallback := KeyDown;
  ContentPanel.KeyUpCallback := KeyUp;
  CurrentFilm := TEFilm.Create;
  PreloadedFilm := TEFilm.Create;
  FrameSlider.PositionChangedCallback := FrameSliderChanged;
  SpeedSlider.PositionChangedCallback := SpeedSliderChanged;
  SpeedSlider.SetRange(0, 100);
  SetFrameInterval(18, True);
  (GetByName('PF_Exit') as TGraphButtonGI).UpCallback := ExitClicked;
  PlayButton.UpCallback := PlayStopClicked;
  StopButton.UpCallback := PlayStopClicked;
  TurnSlider.SetRange(0, FilmHistory.GetCount - 1);
  TurnSlider.PositionChangedCallback := TurnSliderChanged;
  SelectHistoryEntry(FilmHistory.GetCount - 1, True);
  CopyLiveVisualStateToFilm;
  AdvanceOneStep;
  StartPlayback;
end;
{ @end $55FFC8 }

{ @routine $560288 TfFilm_OnClose }
procedure TfFilm.OnClose;
begin
  (StarMapScreen.GetByName('StarFieldImg') as TStarFieldImgGI).CopyStarsFrom(GetByName('StarFieldImg') as TStarFieldImgGI);
  StarMapScreen.SaveSpaceImageState(GetByName('SpaceImg') as TSpaceImgGI);
  if TrailingFilmEffects <> nil then
  begin
    TrailingFilmEffects.Free;
    TrailingFilmEffects := nil;
  end;
  ReleaseFilmSceneObjects(CurrentFilm, True);
  if Loader <> nil then
  begin
    Loader.Free;
    Loader := nil;
  end;
  if CurrentFilm <> nil then
  begin
    CurrentFilm.Free;
    CurrentFilm := nil;
  end;
  if PreloadedFilm <> nil then
  begin
    PreloadedFilm.Free;
    PreloadedFilm := nil;
  end;
  if PanTimer <> 0 then
  begin
    CancelCallbackTimer(PanTimer);
    PanTimer := 0;
  end;
  SpaceProcess.CloseSpace;
end;
{ @end $560288 }

{ @routine $5603C0 TfFilm_GetViewOffset }
function TfFilm.GetViewOffset: TPoint;
begin
  if SpacePanel = nil then SpacePanel := GetByName('MainPanel') as TPanelGI;
  Result := SpacePanel.ScrollOffset;
end;
{ @end $5603C0 }

{ @routine $560418 TfFilm_SetViewOffset }
procedure TfFilm.SetViewOffset(Offset: TPoint);
begin
  if SpacePanel = nil then SpacePanel := GetByName('MainPanel') as TPanelGI;
  SpacePanel.SetScrollOffset(Offset);
  if SpaceProcess.Space <> nil then SpaceProcess.Space.MapScrollChanged(nil);
  FilmCameraFollow := False;
end;
{ @end $560418 }

{ @routine $5604A0 TfFilm_FollowViewOffset }
procedure TfFilm.FollowViewOffset(Offset: TPoint);
begin
  if FilmCameraFollow then
  begin
    if SpacePanel = nil then SpacePanel := GetByName('MainPanel') as TPanelGI;
    SpacePanel.SetScrollOffset(Offset);
    if SpaceProcess.Space <> nil then SpaceProcess.Space.MapScrollChanged(nil);
  end;
end;
{ @end $5604A0 }

{ @routine $560528 TfFilm_PanView }
procedure TfFilm.PanView(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Offset, OldOffset: TPoint;
begin
  OldOffset := GetViewOffset;
  Offset := OldOffset;
  if PanLeft then Dec(Offset.X, ScrollSpeed);
  if PanRight then Inc(Offset.X, ScrollSpeed);
  if PanUp then Dec(Offset.Y, ScrollSpeed);
  if PanDown then Inc(Offset.Y, ScrollSpeed);
  if GetCursorPoint.X = 0 then Dec(Offset.X, ScrollSpeed);
  if GetCursorPoint.X = GameScreenWidth - 1 then Inc(Offset.X, ScrollSpeed);
  if GetCursorPoint.Y = 0 then Dec(Offset.Y, ScrollSpeed);
  if GetCursorPoint.Y = GameScreenHeight - 1 then Inc(Offset.Y, ScrollSpeed);
  if (OldOffset.X <> Offset.X) or (OldOffset.Y <> Offset.Y) then SetViewOffset(Offset);
end;
{ @end $560528 }

{ @routine $560640 TfFilm_KeyDown }
procedure TfFilm.KeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then
    if Key = VK_LEFT then PanLeft := True
    else if Key = VK_RIGHT then PanRight := True
    else if Key = VK_UP then PanUp := True
    else if Key = VK_DOWN then PanDown := True
    else if Key = Ord('C') then CenterShipClicked(nil)
    else if Key = VK_SPACE then PlayStopClicked(nil)
    else if Key = VK_ESCAPE then ExitClicked(nil);
end;
{ @end $560640 }

{ @routine $5606E0 TfFilm_KeyUp }
procedure TfFilm.KeyUp(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_LEFT then PanLeft := False
  else if Key = VK_RIGHT then PanRight := False
  else if Key = VK_UP then PanUp := False
  else if Key = VK_DOWN then PanDown := False;
end;
{ @end $5606E0 }

{ @routine $560718 TfFilm_CopyLiveVisualStateToFilm }
procedure TfFilm.CopyLiveVisualStateToFilm;
var
  Index, Count, SatelliteIndex, SatelliteCount: Integer;
  Planet: TPlanet;
  Satellite: TSputnik;
  Asteroid: TAsteroid;
  Obj: TEFilmObj;
begin
  Obj := CurrentFilm.FindObject(ClassSEtoName(PlayerStar.Graphic), PlayerStar.Graphic.GraphKey, PlayerStar.Id);
  if (Obj <> nil) and (Obj.SceneObject <> nil) then
    (Obj.SceneObject as TStarSE).SetSequenceFrameIndex(TStarSE(PlayerStar.Graphic).GetSequenceFrameIndex);
  Count := PlayerStar.Planets.Count;
  for Index := 0 to Count - 1 do
  begin
    Planet := TPlanet(PlayerStar.Planets[Index]);
    Obj := CurrentFilm.FindObject(ClassSEtoName(Planet.Graphic), Planet.Graphic.GraphKey, Planet.Id);
    if (Obj <> nil) and (Obj.SceneObject <> nil) then
    begin
      (Obj.SceneObject as TPlanetSE).SetSurfaceMapOffset(Planet.Graphic.SurfaceMapOffset);
    end;
    SatelliteCount := Planet.Satellites.Count;
    for SatelliteIndex := 0 to SatelliteCount - 1 do
    begin
      Satellite := TSputnik(Planet.Satellites[SatelliteIndex]);
      Obj := CurrentFilm.FindObject(ClassSEtoName(Satellite.Graphic), Satellite.Graphic.GraphKey, Satellite.Id);
      if (Obj <> nil) and (Obj.SceneObject <> nil) then
      begin
        (Obj.SceneObject as TSputnikSE).SurfaceMapOffset := Satellite.Graphic.SurfaceMapOffset;
        (Obj.SceneObject as TSputnikSE).OrbitAngle := Satellite.Graphic.OrbitAngle;
      end;
    end;
  end;
  Count := PlayerStar.Asteroids.Count;
  for Index := 0 to Count - 1 do
  begin
    Asteroid := TAsteroid(PlayerStar.Asteroids[Index]);
    Obj := CurrentFilm.FindObject(ClassSEtoName(Asteroid.GraphObject), Asteroid.GraphObject.GraphKey, Asteroid.Id);
    if (Obj <> nil) and (Obj.SceneObject <> nil) then
      (Obj.SceneObject as TAsteroidSE).SetSequenceFrameIndex(Asteroid.GraphObject.GetSequenceFrameIndex);
  end;
end;
{ @end $560718 }

{ @routine $56099C TfFilm_CopyFilmVisualStateToLive }
procedure TfFilm.CopyFilmVisualStateToLive;
var
  Index, Count, SatelliteIndex, SatelliteCount: Integer;
  Planet: TPlanet;
  Satellite: TSputnik;
  Asteroid: TAsteroid;
  Obj: TEFilmObj;
begin
  Obj := CurrentFilm.FindObject(ClassSEtoName(PlayerStar.Graphic), PlayerStar.Graphic.GraphKey, PlayerStar.Id);
  if (Obj <> nil) and (Obj.SceneObject <> nil) then
    TStarSE(PlayerStar.Graphic).SetSequenceFrameIndex((Obj.SceneObject as TStarSE).GetSequenceFrameIndex);
  Count := PlayerStar.Planets.Count;
  for Index := 0 to Count - 1 do
  begin
    Planet := TPlanet(PlayerStar.Planets[Index]);
    Obj := CurrentFilm.FindObject(ClassSEtoName(Planet.Graphic), Planet.Graphic.GraphKey, Planet.Id);
    if (Obj <> nil) and (Obj.SceneObject <> nil) then
    begin
      Planet.Graphic.SetSurfaceMapOffset((Obj.SceneObject as TPlanetSE).SurfaceMapOffset);
    end;
    SatelliteCount := Planet.Satellites.Count;
    for SatelliteIndex := 0 to SatelliteCount - 1 do
    begin
      Satellite := TSputnik(Planet.Satellites[SatelliteIndex]);
      Obj := CurrentFilm.FindObject(ClassSEtoName(Satellite.Graphic), Satellite.Graphic.GraphKey, Satellite.Id);
      if (Obj <> nil) and (Obj.SceneObject <> nil) then
      begin
        Satellite.Graphic.SurfaceMapOffset := (Obj.SceneObject as TSputnikSE).SurfaceMapOffset;
        Satellite.Graphic.OrbitAngle := (Obj.SceneObject as TSputnikSE).OrbitAngle;
      end;
    end;
  end;
  Count := PlayerStar.Asteroids.Count;
  for Index := 0 to Count - 1 do
  begin
    Asteroid := TAsteroid(PlayerStar.Asteroids[Index]);
    Obj := CurrentFilm.FindObject(ClassSEtoName(Asteroid.GraphObject), Asteroid.GraphObject.GraphKey, Asteroid.Id);
    if (Obj <> nil) and (Obj.SceneObject <> nil) then
      Asteroid.GraphObject.SetSequenceFrameIndex((Obj.SceneObject as TAsteroidSE).GetSequenceFrameIndex);
  end;
end;
{ @end $56099C }

{ @routine $560C20 TfFilm_ExitClicked }
procedure TfFilm.ExitClicked(Sender: TObjectGI);
begin
  CopyFilmVisualStateToLive;
  RequestedScreenId := screenStarMap;
  RequestClose(1);
end;
{ @end $560C20 }

{ @routine $560C40 TfFilm_CenterShipClicked }
procedure TfFilm.CenterShipClicked(Sender: TObjectGI);
begin
  SetViewOffset(TruncatePointF(CameraTarget));
end;
{ @end $560C40 }

{ @routine $560C60 TfFilm_SelectHistoryEntry }
procedure TfFilm.SelectHistoryEntry(Index: Integer; InitialLoad: Boolean);
var SwapFilm: TEFilm;
begin
  if Loader.IsRunning then Loader.WaitForIdle(INFINITE);
  if PreloadHistoryIndex <> Index then
  begin
    PreloadHistoryIndex := Index;
    Loader.Start;
    Loader.WaitForIdle(INFINITE);
  end;
  if (CurrentHistoryIndex >= PreloadHistoryIndex) and (TrailingFilmEffects <> nil) then
  begin
    TrailingFilmEffects.Free;
    TrailingFilmEffects := nil;
  end;
  ReuseSceneObjectsForPreloadedFilm;
  ReleaseFilmSceneObjects(CurrentFilm, True);
  CreateFilmSceneObjects(PreloadedFilm);
  SwapFilm := CurrentFilm;
  CurrentFilm := PreloadedFilm;
  PreloadedFilm := SwapFilm;
  CurrentHistoryIndex := Index;
  PreloadHistoryIndex := 0;
  if not InitialLoad then StarMapScreen.SaveSpaceImageState(GetByName('SpaceImg') as TSpaceImgGI);
  StarMapScreen.BuildSpaceBackground(GetByName('StarField') as TStarFieldGI,
    GetByName('SpaceImg') as TSpaceImgGI, CurrentFilm.StarGenerationSeed);
  PreloadedFilm.StarGenerationSeed := 0;
  TurnSlider.SetPositionInternal(Index);
  DateLabel.SetText(Galaxy.FormatTurnDate(CurrentFilm.Turn));
  if Player <> nil then
  begin
    SpaceProcess.RadarCenter := MakePointF(0, 0);
    SpaceProcess.RadarRange := CurrentFilm.RadarRange;
    SpaceProcess.ActionRange := CurrentFilm.RadarRange;
    SpaceProcess.ActionColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
  end;
  SpaceProcess.SystemRadius := CurrentFilm.MapDiameter div 2;
  SpaceProcess.PopulateAmbientObjects(CurrentFilm.MapDiameter div 2);
  SpaceProcess.OpenSpace(SpacePanel, Self);
  SpaceProcess.Space.MinimapScale := 0.0000001;
  SpaceProcess.BindMinimap(MapPanel);
  SpaceProcess.Space.MinimapScale := MapPanel.ClientSize.X / CurrentFilm.MapDiameter;
  SpaceProcess.Space.CreateMinimapViewport;
  StepIndex := 0;
  NextCommand := CurrentFilm.FirstCommand;
  FrameSlider.SetRange(1, CurrentFilm.LastCommand.StepIndex);
  PreloadHistoryIndex := Index + 1;
  if PreloadHistoryIndex >= FilmHistory.GetCount then PreloadHistoryIndex := FilmHistory.GetCount - 1;
  Loader.Start;
  MinimapFrameCounter := 0;
end;
{ @end $560C60 }

{ @routine $560FC4 TfFilm_CreateFilmSceneObjects }
procedure TfFilm.CreateFilmSceneObjects(Film: TEFilm);
var Obj: TEFilmObj;
begin
  Obj := Film.FirstObject;
  while Obj <> nil do
  begin
    if Obj.SceneObject = nil then
      Obj.SceneObject := CreateSpaceObjectByName(Obj.KindName, Obj.GraphKey, Classes.Point(0, 0));
    Obj := Obj.Next;
  end;
end;
{ @end $560FC4 }

{ @routine $560FFC TfFilm_ReleaseFilmSceneObjects }
procedure TfFilm.ReleaseFilmSceneObjects(Film: TEFilm; ReleaseTrailingReferences: Boolean);
var
  Obj: TEFilmObj;
  Entry, NextEntry: PEFilmEndEntry;
begin
  Obj := Film.FirstObject;
  while Obj <> nil do
  begin
    if Obj.SceneObject <> nil then
    begin
      Obj.SceneObject.DetachFromSpace;
      if ReleaseTrailingReferences then
      begin
        if TrailingFilmEffects <> nil then
        begin
          NextEntry := TrailingFilmEffects.FirstEntry;
          while NextEntry <> nil do
          begin
            Entry := NextEntry;
            NextEntry := NextEntry.Next;
            if Entry.RelatedObject1 = Obj.SceneObject then Entry.RelatedObject1 := nil;
            if (TWeaponSE(Entry.SceneObject).SourceObject = Obj.SceneObject) or
              (TWeaponSE(Entry.SceneObject).TargetObject = Obj.SceneObject) then
              TrailingFilmEffects.RemoveEntry(Entry);
          end;
        end;
        Obj.SceneObject.Free;
      end;
      Obj.SceneObject := nil;
    end;
    Obj := Obj.Next;
  end;
end;
{ @end $560FFC }

{ @routine $561088 TfFilm_ReuseSceneObjectsForPreloadedFilm }
procedure TfFilm.ReuseSceneObjectsForPreloadedFilm;
var NewObj, OldObj: TEFilmObj;
begin
  NewObj := PreloadedFilm.FirstObject;
  while NewObj <> nil do
  begin
    if NewObj.SceneObject = nil then
    begin
      OldObj := CurrentFilm.FindObject(NewObj.KindName, NewObj.GraphKey, NewObj.ObjectId);
      if (OldObj <> nil) and (OldObj.SceneObject <> nil) then
      begin
        NewObj.SceneObject := OldObj.SceneObject;
        if not (OldObj.SceneObject is TShip2SE) or
          (CurrentHistoryIndex <> PreloadHistoryIndex - 1) then NewObj.SceneObject.DetachFromSpace;
        OldObj.SceneObject := nil;
      end;
    end;
    NewObj := NewObj.Next;
  end;
end;
{ @end $561088 }

{ @routine $561104 TfFilm_AdvancePausedEffects }
procedure TfFilm.AdvancePausedEffects(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if TrailingFilmEffects <> nil then
  begin
    TrailingFilmEffects.AdvanceEffects;
    if TrailingFilmEffects.FirstEntry = nil then
    begin
      TrailingFilmEffects.Free;
      TrailingFilmEffects := nil;
    end;
  end;
  SpaceProcess.Space.AdvanceTimers;
end;
{ @end $561104 }

{ @routine $56114C TfFilm_SetFrameInterval }
procedure TfFilm.SetFrameInterval(IntervalMs: Integer; UpdateSlider: Boolean);
begin
  FrameIntervalMs := IntervalMs;
  if Playing then
  begin
    PausePlayback;
    StartPlayback;
  end
  else
  begin
    if EffectsTimer <> 0 then
    begin
      CancelCallbackTimer(EffectsTimer);
      EffectsTimer := 0;
    end;
    EffectsTimer := ScheduleCallbackTimer(FrameIntervalMs, FrameIntervalMs, AdvancePausedEffects);
  end;
  if UpdateSlider then SpeedSlider.SetPositionInternal(100 - Round((5 - FrameIntervalMs) / -95.0 * 100.0));
end;
{ @end $56114C }

{ @routine $5611F4 TfFilm_SpeedSliderChanged }
procedure TfFilm.SpeedSliderChanged(Sender: TObjectGI);
begin
  SetFrameInterval(Round((100 - SpeedSlider.Position) / 100.0 * 95.0 + 5.0), False);
end;
{ @end $5611F4 }

{ @routine $561240 TfFilm_FrameSliderChanged }
procedure TfFilm.FrameSliderChanged(Sender: TObjectGI);
var
  Position: Integer;
begin
  Position := FrameSlider.Position;
  if Playing then PausePlayback;
  if Position <> StepIndex then
  begin
    if Position < StepIndex then
    begin
      SelectHistoryEntry(CurrentHistoryIndex, False);
      AdvanceOneStep;
    end;
    FilmSoundEffectsEnabled := False;
    while Position > StepIndex do AdvanceOneStep;
    FilmSoundEffectsEnabled := True;
  end;
end;
{ @end $561240 }

{ @routine $5612A8 TfFilm_PlayStopClicked }
procedure TfFilm.PlayStopClicked(Sender: TObjectGI);
begin
  if Playing then PausePlayback
  else
  begin
    FilmCameraFollow := True;
    if NextCommand = nil then
    begin
      SelectHistoryEntry(FilmHistory.GetCount - 1, False);
      AdvanceOneStep;
    end;
    StartPlayback;
  end;
end;
{ @end $5612A8 }

{ @routine $5612F8 TfFilm_TurnSliderChanged }
procedure TfFilm.TurnSliderChanged(Sender: TObjectGI);
begin
  if Playing then PausePlayback;
  FilmCameraFollow := True;
  SelectHistoryEntry(TurnSlider.Position, False);
  AdvanceOneStep;
end;
{ @end $5612F8 }

{ @routine $561334 TfFilm_StartPlayback }
procedure TfFilm.StartPlayback;
begin
  if not Playing then
  begin
    if EffectsTimer <> 0 then
    begin
      CancelCallbackTimer(EffectsTimer);
      EffectsTimer := 0;
    end;
    PlaybackTimer := ScheduleCallbackTimer(FrameIntervalMs, FrameIntervalMs, AdvancePlayback);
    PlayButton.SetActive(False);
    StopButton.SetActive(True);
    Playing := True;
  end;
end;
{ @end $561334 }

{ @routine $5613A0 TfFilm_PausePlayback }
procedure TfFilm.PausePlayback;
begin
  if Playing then
  begin
    if PlaybackTimer <> 0 then
    begin
      CancelCallbackTimer(PlaybackTimer);
      PlaybackTimer := 0;
    end;
    SpacePanel.SetDragScrollingEnabled(True);
    if EffectsTimer <> 0 then
    begin
      CancelCallbackTimer(EffectsTimer);
      EffectsTimer := 0;
    end;
    EffectsTimer := ScheduleCallbackTimer(FrameIntervalMs, FrameIntervalMs, AdvancePausedEffects);
    PlayButton.SetActive(True);
    StopButton.SetActive(False);
    Playing := False;
  end;
end;
{ @end $5613A0 }

{ @routine $561438 TfFilm_AdvancePlayback }
procedure TfFilm.AdvancePlayback(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  AdvanceOneStep;
  if NextCommand = nil then
  begin
    PausePlayback;
    if CurrentHistoryIndex < FilmHistory.GetCount - 1 then
    begin
      SelectHistoryEntry(CurrentHistoryIndex + 1, False);
      AdvanceOneStep;
      StartPlayback;
    end;
  end;
end;
{ @end $561438 }

{ @routine $561488 TfFilm_AdvanceOneStep }
procedure TfFilm.AdvanceOneStep;
begin
  if TrailingFilmEffects <> nil then
  begin
    TrailingFilmEffects.AdvanceEffects;
    if TrailingFilmEffects.FirstEntry = nil then
    begin
      TrailingFilmEffects.Free;
      TrailingFilmEffects := nil;
    end;
  end;
  SpaceProcess.Space.AdvanceTimers;
  if NextCommand.Kind = efcBeginTrailingEffects then
  begin
    if TrailingFilmEffects <> nil then
    begin
      TrailingFilmEffects.Free;
      TrailingFilmEffects := nil;
    end;
    TrailingFilmEffects := TEFilmEnd.Create;
    TrailingFilmEffects.TakeTrailingEffects(CurrentFilm);
    Inc(StepIndex);
    FrameSlider.SetPositionInternal(StepIndex);
    NextCommand := NextCommand.Next;
  end
  else
  begin
    Inc(StepIndex);
    FrameSlider.SetPositionInternal(StepIndex);
    while NextCommand <> nil do
    begin
      if NextCommand.Kind = efcBeginTrailingEffects then Break;
      if NextCommand.StepIndex >= StepIndex then Break;
      CurrentFilm.ExecuteCommand(SpaceProcess, NextCommand, True);
      NextCommand := NextCommand.Next;
    end;
  end;
end;
{ @end $561488 }

{ @routine $5615A8 TfFilm_InvalidateAnimatedControls }
procedure TfFilm.InvalidateAnimatedControls;
begin
  UpdateRectsEnabled := True;
  SpacePanel.InvalidateChildren(True);
  CursorControl.Invalidate;
  UpdateRectsEnabled := False;
end;
{ @end $5615A8 }

{ @routine $5615D0 TfFilm_DrawFrame }
procedure TfFilm.DrawFrame;
var
  RectNode: TRectGR;
  StarField: TStarFieldGI;
begin
  if (MinimapFrameCounter mod 16) = 0 then SpaceProcess.Space.DrawMinimap;
  Inc(MinimapFrameCounter);
  InvalidateAnimatedControls;
  StarField := GetByName('StarField') as TStarFieldGI;
  StarField.UpdateBackgroundBounds;
  if SkipSavedPixelRestore or FullFrameRedrawRequested then
  begin
    UpdateRects.Clear;
    UpdateRectsEnabled := True;
    InvalidateViewport;
    UpdateRectsEnabled := False;
  end;
  FullFrameRedrawRequested := False;
  RestoreSavedPixels16;
  ErasePreviousFrame;
  RectNode := UpdateRects.FirstRect;
  while RectNode <> nil do
  begin
    StarField.DrawBackground(RectNode.Bounds);
    RectNode := RectNode.Next;
  end;
  PrepareFrameDraw;
  DrawQueuedControlRects;
  if not BeginFramePresentation then
  begin
    RequestedScreenId := screenNone;
    RestartScreenId := FormToId(Self);
    RequestClose(1);
  end
  else
  begin
    FinishQueuedDraw;
    CommitFrameDraw;
    ResetSecondaryPixelCount;
    EndFramePresentation;
    InvalidateAnimatedControls;
  end;
end;
{ @end $5615D0 }

{ @routine $561700 TfFilm_SelectMusic }
procedure TfFilm.SelectMusic;
begin
  if MusicInSpace then MusicManager.PlayCategory('StarMap')
  else MusicManager.RequestFadeOut;
end;
{ @end $561700 }

end.

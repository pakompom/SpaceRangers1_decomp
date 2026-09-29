unit fLoad;
// Unit bracket (inferred): CODE 0x00555BF4..0x005578CB; inclusive evidence, not full bounds.
// Intro stages: publisher animation, game animation, configured logo.
interface
uses Classes, GI_MessageLoop, EC_Thread;
type
  TCacheLoader = class(TThreadEC) // @size $38
  public
    PendingLoads: TList; // @offset $2C
    TotalLoadCount: Integer; // @offset $30
    CompletedLoadCount: Integer; // @offset $34
    procedure Execute; override; // @addr $556138
    procedure SetPendingLoads(Loads: TList; StartImmediately: Boolean); // @addr $5561C8
  end;
  TfLoad = class(TMessageLoopGI) // @size $EC
  public
    ProgressTimer: TCallbackTimerIdGI; // @offset $B0
    LoadProgress: Single; // @offset $B4
    DisplayedProgress: Single; // @offset $B8
    LoadingFinished: Boolean; // @offset $BC
    IntroStartedAt: Cardinal; // @offset $C0
    SkipLogo: Boolean; // @offset $C4
    SkipPublisher: Boolean; // @offset $C5
    SkipGameIntro: Boolean; // @offset $C6
    PublisherTimer: TCallbackTimerIdGI; // @offset $C8
    GameIntroTimer: TCallbackTimerIdGI; // @offset $CC
    LogoTimer: TCallbackTimerIdGI; // @offset $D0
    LogoOption0: Integer; // @offset $D4 Parsed but unused by the native intro routines.
    LogoDurationMs: Integer; // @offset $D8
    LogoPath: WideString; // @offset $DC
    LogoVideoFrameCount: Integer; // @offset $E0
    LogoIsVideo: Boolean; // @offset $E4
    constructor Create; // @addr $556210
    destructor Destroy; override; // @addr $556248
    procedure InitializeLayout; override; // @addr $556270
    procedure OnOpen; override; // @addr $556278
    procedure OnClose; override; // @addr $556820
    procedure UpdateLoadingProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $556A7C
    procedure IntroKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $556B64
    procedure SetProgress(Progress: Single); // @addr $556BA0
    procedure SelectMusic; override; // @addr $556C94
    procedure StartPublisherVideo; // @addr $556C9C
    procedure UpdatePublisherVideo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $556EA8
    procedure FinishPublisherVideo; // @addr $556FA8
    procedure StartGameIntro; // @addr $557018
    procedure UpdateGameIntro(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $557218
    procedure FinishGameIntro; // @addr $55731C
    procedure StartCustomLogo; // @addr $557380
    procedure UpdateCustomLogo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5576C8
    procedure FinishCustomLogo; // @addr $55781C
  end;
procedure QueueCommonLoadingAssets(PendingLoads: TList; Owner: TObjectGI); // @addr $555CEC
procedure QueueSpaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI); // @addr $555D1C
procedure QueueHyperspaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI); // @addr $555EF4
procedure QueueArcadeLoadingAssets(PendingLoads: TList; Owner: TObjectGI); // @addr $555F10
procedure RemoveDuplicateCacheLoads(PendingLoads: TList); // @addr $555F3C
procedure QueueConfiguredLoadingAssets(PendingLoads: TList; Path: WideString); // @addr $555FE0
procedure LoadPendingAssets(PendingLoads: TList); // @addr $5560F4
var
  IntroFinished: Boolean = False; // @addr $61877C
implementation

// @unit-initialization $5578C4
// @unit-finalization $557894

uses fCommand, Windows, SysUtils, Math, MMSystem, EC_Cache, EC_CacheGAI, EC_Str, EC_BlockPar,
  GR_Main, Globals, GlobalsV, GI_Main, GI_Image, GI_GAI, GI_XviD,
  ab_Object, aGalaxy, aPlanet, aShip, aPlayer, SE_Gate, aMyFunction, aItem, aConst, ThreadCalc, aScript, EC_Expression, aRanger, aAsteroid;

var
  IntroPlaying: Boolean; // @addr $61CFE4

{ @routine $555CEC QueueCommonLoadingAssets }
procedure QueueCommonLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  QueueConfiguredLoadingAssets(PendingLoads, 'LoadGame');
  RemoveDuplicateCacheLoads(PendingLoads);
end;
{ @end $555CEC }

{ @routine $555D1C QueueSpaceLoadingAssets }
procedure QueueSpaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TSputnikTempl;
  I, Count: Integer;
  Gate: TGateSE;
begin
  PlayerStar.QueueSpaceImageLoads(PendingLoads, Owner);
  if SputnikShow then
  begin
    Count := SatelliteRenderTemplates.Count;
    for I := 0 to Count - 1 do
    begin
      Template := SatelliteRenderTemplates[I];
      GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'PlanetTempl', Template.MaskName);
    end;
  end;
  Gate := TGateSE.Create('Gate', Classes.Point(0, 0));
  Gate.QueueImageLoad(PendingLoads, Owner);
  Gate.Free;
  for I := 0 to High(SpaceImageTemplates) do
    if SpaceImageTemplates[I].CacheControl <> nil then TCGaiControlEC(SpaceImageTemplates[I].CacheControl).QueueLoadIfMissing(PendingLoads);
  GlobalCache.QueueNamedLoadIfMissing(PendingLoads, 'GAI', PlayerStar.SelectBackground(I));
  QueueConfiguredLoadingAssets(PendingLoads, 'Space');
  if SoundEnabled then QueueConfiguredLoadingAssets(PendingLoads, 'SpaceSound');
  RemoveDuplicateCacheLoads(PendingLoads);
end;
{ @end $555D1C }

{ @routine $555EF4 QueueHyperspaceLoadingAssets }
procedure QueueHyperspaceLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  PlayerStar.QueueHyperspaceShipImageLoads(PendingLoads, Owner);
  RemoveDuplicateCacheLoads(PendingLoads);
end;
{ @end $555EF4 }

{ @routine $555F10 QueueArcadeLoadingAssets }
procedure QueueArcadeLoadingAssets(PendingLoads: TList; Owner: TObjectGI);
begin
  ab_Object_QueueImageLoads(PendingLoads, Owner);
  QueueConfiguredLoadingAssets(PendingLoads, 'AB');
  RemoveDuplicateCacheLoads(PendingLoads);
end;
{ @end $555F10 }

{ @routine $555F3C RemoveDuplicateCacheLoads }
procedure RemoveDuplicateCacheLoads(PendingLoads: TList);
var
  I, J: Integer;
  First, Second: TCacheControlEC;
begin
  I := 0;
  while PendingLoads.Count - 1 > I do
  begin
    First := TCacheControlEC(PendingLoads[I]);
    J := I + 1;
    while PendingLoads.Count > J do
    begin
      Second := TCacheControlEC(PendingLoads[J]);
      if (First.ClassName = Second.ClassName) and (First.CacheKey = Second.CacheKey) then
      begin
        Second.Free;
        PendingLoads.Delete(J);
      end
      else Inc(J);
    end;
    Inc(I);
  end;
end;
{ @end $555F3C }

{ @routine $555FE0 QueueConfiguredLoadingAssets }
procedure QueueConfiguredLoadingAssets(PendingLoads: TList; Path: WideString);
var
  I, Count: Integer;
  Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('Load.' + Path);
  Count := Block.GetBlockCount;
  for I := 0 to Count - 1 do
    QueueConfiguredLoadingAssets(PendingLoads, Path + '.' + Block.GetBlockNameByIndex(I));
  Count := Block.GetParamCount;
  for I := 0 to Count - 1 do
    GlobalCache.QueueNamedLoadIfMissing(PendingLoads,
      Block.GetParamName(I), Block.GetParamValue(I));
end;
{ @end $555FE0 }

{ @routine $5560F4 LoadPendingAssets }
procedure LoadPendingAssets(PendingLoads: TList);
var
  I, Count: Integer;
  Control: TCacheControlEC;
begin
  Count := PendingLoads.Count;
  for I := 0 to Count - 1 do
  begin
    Control := TCacheControlEC(PendingLoads[I]);
    Control.AcquireData;
    Control.Release;
    Control.Free;
  end;
  PendingLoads.Clear;
end;
{ @end $5560F4 }

{ @routine $556138 TCacheLoader_Execute }
procedure TCacheLoader.Execute;
var
  I, Count: Integer;
  Control: TCacheControlEC;
begin
  if PendingLoads <> nil then
  begin
    Count := PendingLoads.Count;
    for I := 0 to Count - 1 do
    begin
      while Flag18 and
        not ExitScreenLoop and not IsStopRequested do SysUtils.Sleep(100);
      Control := TCacheControlEC(PendingLoads[I]);
      if not ExitScreenLoop and not IsStopRequested then
      begin
        Control.AcquireData;
        Control.Release;
      end;
      Control.Free;
      Inc(CompletedLoadCount);
    end;
    PendingLoads.Free;
    PendingLoads := nil;
  end;
end;
{ @end $556138 }

{ @routine $5561C8 TCacheLoader_SetPendingLoads }
procedure TCacheLoader.SetPendingLoads(Loads: TList; StartImmediately: Boolean);
begin
  if IsRunning then WaitForIdle(INFINITE);
  PendingLoads := Loads;
  CompletedLoadCount := 0;
  TotalLoadCount := PendingLoads.Count;
  SetPriority(1);
  if StartImmediately then Start;
end;
{ @end $5561C8 }

{ @routine $556210 TfLoad_Create }
constructor TfLoad.Create;
begin
  inherited Create;
end;
{ @end $556210 }

{ @routine $556248 TfLoad_Destroy }
destructor TfLoad.Destroy;
begin
  inherited Destroy;
end;
{ @end $556248 }

{ @routine $556270 TfLoad_InitializeLayout }
procedure TfLoad.InitializeLayout;
begin
  inherited InitializeLayout;
end;
{ @end $556270 }

{ @routine $556278 TfLoad_OnOpen }
procedure TfLoad.OnOpen;
var
  I, BackgroundKind: Integer;
  BestDistance: Single;
  Text: WideString;
  Planet: TPlanet;
  PendingLoads: TList;
begin
  SkipPublisher := False;
  SkipGameIntro := False;
  SkipLogo := False;
  ContentPanel.KeyDownCallback := IntroKeyDown;
  if IntroFinished then MusicManager.RequestFadeOut else SelectMusic;
  DebugCommandCallback := @HandleRuntimeDebugCommand;
  LoadProgress := 0;
  DisplayedProgress := 0;
  LoadingFinished := False;
  SetCursorActive(False);
  PendingLoads := TList.Create;
  if ScreenLoadMode = 0 then QueueCommonLoadingAssets(PendingLoads, RootUiObject)
  else if ScreenLoadMode = 2 then QueueSpaceLoadingAssets(PendingLoads, RootUiObject)
  else if ScreenLoadMode = 3 then
  begin
    QueueCommonLoadingAssets(PendingLoads, RootUiObject);
    QueueSpaceLoadingAssets(PendingLoads, RootUiObject);
  end;
  if PendingLoads.Count > 0 then
  begin
    CacheLoader.SetPendingLoads(PendingLoads, False);
    ProgressTimer := ScheduleCallbackTimer(20, 20, UpdateLoadingProgress, 0);
  end
  else
  begin
    PendingLoads.Free;
    RequestClose(1);
  end;
  if IntroFinished then
  begin
    CacheLoader.Start;
    BackgroundKind := 0;
    if Player <> nil then
    begin
      if Player.IsOnPlanet then
      begin
        if Player.CurrentPlanet.OwnerId <> oiNone then BackgroundKind := 1;
      end
      else
      begin
        BestDistance := 1.0e30;
        for I := 0 to Player.CurrentStar.Planets.Count - 1 do
        begin
          Planet := Player.CurrentStar.Planets[I];
          if PointDistanceSquared(Planet.GetPosition, Player.Position) < BestDistance then
          begin
            BestDistance := PointDistanceSquared(Planet.GetPosition, Player.Position);
            if Planet.OwnerId = oiNone then BackgroundKind := 0 else BackgroundKind := 1;
          end;
        end;
      end;
    end;
    with GetByName('Fon') as TImageGI do
    begin
      SetActive(True);
      if RandomIntRange(0, 2) > 0 then
        SetImagePath('GI,Bm.SI.' + GiResourceSuffix + 'BG_TakeOff' + IntToStr(BackgroundKind))
      else SetImagePath('GI,Bm.SI.' + GiResourceSuffix + 'BG_TakeOff2');
    end;
    GetByName('IntroRect').SetActive(False);
    GetByName('Intro').SetActive(False);
    SetProgress(0);
  end
  else
  begin
    IntroPlaying := True;
    GetByName('PBmin').SetActive(False);
    GetByName('PBmax').SetActive(False);
    CacheLoader.Start;
    if InstallConfig.CountParams('Logo') > 0 then
    begin
      Text := InstallConfig.GetParam('Logo');
      if CountDelimitedPartsW(Text, ',') >= 3 then
      begin
        LogoOption0 := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
        LogoDurationMs := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 1, ','));
        LogoPath := TrimWideString(ExtractDelimitedPartW(Text, 2, ','));
        LogoVideoFrameCount := 0;
        if CountDelimitedPartsW(Text, ',') >= 4 then
          LogoVideoFrameCount := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 3, ','));
        LogoIsVideo := LowerCaseWideString(TrimWideString(ExtractFileExtNoDotW(LogoPath))) = 'vdo';
      end;
    end;
    if not SkipPublisherIntro then StartPublisherVideo
    else
    begin
      SkipPublisher := True;
      StartGameIntro;
    end;
  end;
end;
{ @end $556278 }

{ @routine $556820 TfLoad_OnClose }
procedure TfLoad.OnClose;
begin
  (GetByName('Film') as TxvidGI).ImageClose;
  if CacheLoader.IsRunning then CacheLoader.WaitForIdle(INFINITE);
  if ProgressTimer <> 0 then
  begin
    CancelCallbackTimer(ProgressTimer);
    ProgressTimer := 0;
  end;
  if PublisherTimer <> 0 then
  begin
    CancelCallbackTimer(PublisherTimer);
    PublisherTimer := 0;
  end;
  if GameIntroTimer <> 0 then
  begin
    CancelCallbackTimer(GameIntroTimer);
    GameIntroTimer := 0;
  end;
  if LogoTimer <> 0 then
  begin
    CancelCallbackTimer(LogoTimer);
    LogoTimer := 0;
  end;
  if (ScreenLoadMode = 0) or (ScreenLoadMode = 3) then
  begin
    MainMenuScreen.InitializeLayout;
    NewGameScreen.InitializeLayout;
    IntroductionScreen.InitializeLayout;
    HangarScreen.InitializeLayout;
    PlanetScreen.InitializeLayout;
    UninhabitedPlanetScreen.InitializeLayout;
    RuinsTalkScreen.InitializeLayout;
    ArcadeBattleScreen.InitializeLayout;
    EquipmentShopScreen.InitializeLayout;
    GoodsShopScreen.InitializeLayout;
    GovernmentScreen.InitializeLayout;
    InfoScreen.InitializeLayout;
    RatingScreen.InitializeLayout;
    RewardsScreen.InitializeLayout;
    ShipScreen.InitializeLayout;
    LoadScreen.InitializeLayout;
    ScannerScreen.InitializeLayout;
    StarMapScreen.InitializeLayout;
    FilmScreen.InitializeLayout;
    GalaxyMapScreen.InitializeLayout;
    JumpScreen.InitializeLayout;
    SaveManagerScreen.InitializeLayout;
    GameLoadScreen.InitializeLayout;
    GameMenuScreen.InitializeLayout;
    SettingsScreen.InitializeLayout;
    GameEndScreen.InitializeLayout;
    AboutScreen.InitializeLayout;
    ScoreScreen.InitializeLayout;
    SpaceObjectUiLoop.InitializeLayout;
    TalkScreen.InitializeLayout;
  end;
  IntroFinished := True;
  RequestedScreenId := RestartScreenId;
  RestartScreenId := screenNone;
end;
{ @end $556820 }

{ @routine $556A7C TfLoad_UpdateLoadingProgress }
procedure TfLoad.UpdateLoadingProgress(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if not LoadingFinished then
  begin
    if CacheLoader.IsRunning then
      LoadProgress := CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount
    else
    begin
      LoadingFinished := True;
      LoadProgress := 1;
    end;
  end;
  if DisplayedProgress < LoadProgress then
  begin
    DisplayedProgress := Min(DisplayedProgress + 0.05, LoadProgress);
    SetProgress(DisplayedProgress);
  end;
  if LoadingFinished and (DisplayedProgress >= 0.999) and not IntroPlaying then
  begin
    Present;
    RequestClose(1);
  end;
end;
{ @end $556A7C }

{ @routine $556B64 TfLoad_IntroKeyDown }
procedure TfLoad.IntroKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_ESCAPE then
  begin
    if not SkipPublisher then SkipPublisher := True
    else if not SkipGameIntro then SkipGameIntro := True
    else if not SkipLogo then SkipLogo := True;
  end;
end;
{ @end $556B64 }

{ @routine $556BA0 TfLoad_SetProgress }
procedure TfLoad.SetProgress(Progress: Single);
var X: Integer;
begin
  if IntroFinished then
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
end;
{ @end $556BA0 }

{ @routine $556C94 TfLoad_SelectMusic }
procedure TfLoad.SelectMusic;
begin
  if IntroFinished then begin end;
end;
{ @end $556C94 }

{ @routine $556C9C TfLoad_StartPublisherVideo }
procedure TfLoad.StartPublisherVideo;
begin
  GetByName('Fon').SetActive(False);
  GetByName('IntroRect').SetActive(True);
  with GetByName('Intro') as TgaiGI do
  begin
    SetImagePath('Bm.SI.' + GiResourceSuffix + '_1C');
    SetPosition(Classes.Point(0, 0));
    SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    LoadFrameSequenceFromText('[80,0-119]');
    PreloadImages;
    SetActive(True);
    StopAutoPlayback;
    SetSequenceFrame(0);
  end;
  if MusicEnabled then
  begin
    MusicManager.PlayCategory('1C');
    while not MusicManager.IsPlaying do SysUtils.Sleep(1);
  end;
  IntroStartedAt := timeGetTime;
  if PublisherTimer <> 0 then
  begin
    CancelCallbackTimer(PublisherTimer);
    PublisherTimer := 0;
  end;
  PublisherTimer := ScheduleCallbackTimer(10, 10, UpdatePublisherVideo, 0);
end;
{ @end $556C9C }

{ @routine $556EA8 TfLoad_UpdatePublisherVideo }
procedure TfLoad.UpdatePublisherVideo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Progress: Double;
begin
  if SkipPublisher then
  begin
    if PublisherTimer <> 0 then
    begin
      CancelCallbackTimer(PublisherTimer);
      PublisherTimer := 0;
    end;
    FinishPublisherVideo;
    Exit;
  end;
  Progress := (timeGetTime - IntroStartedAt) / 10000.0;
  if Progress > 1 then Progress := 1;
  with GetByName('Intro') as TgaiGI do
    AdvanceToSequenceFrame(Round((SequenceFrameCount - 1) * Progress), True);
  if Progress >= 1 then
  begin
    if PublisherTimer <> 0 then
    begin
      CancelCallbackTimer(PublisherTimer);
      PublisherTimer := 0;
    end;
    FinishPublisherVideo;
  end;
end;
{ @end $556EA8 }

{ @routine $556FA8 TfLoad_FinishPublisherVideo }
procedure TfLoad.FinishPublisherVideo;
begin
  (GetByName('Intro') as TgaiGI).SetActive(False);
  if MusicEnabled then
  begin
    MusicManager.StopImmediately;
    while MusicManager.IsPlaying do SysUtils.Sleep(1);
  end;
  SkipPublisher := True;
  StartGameIntro;
end;
{ @end $556FA8 }

{ @routine $557018 TfLoad_StartGameIntro }
procedure TfLoad.StartGameIntro;
begin
  GetByName('Fon').SetActive(False);
  GetByName('IntroRect').SetActive(True);
  with GetByName('Intro') as TgaiGI do
  begin
    SetImagePath('Bm.SI.' + GiResourceSuffix + 'Intro');
    SequenceIndex := 0;
    UpdateAutoGeometry;
    LoadFrameSequenceFromText('[50,0-' + IntToStr(SequenceFrameCount - 1) + ']');
    PreloadImages;
    SetActive(True);
    StopAutoPlayback;
    SetSequenceFrame(0);
  end;
  if MusicEnabled then MusicManager.PlayCategory('Base');
  IntroStartedAt := timeGetTime;
  if GameIntroTimer <> 0 then
  begin
    CancelCallbackTimer(GameIntroTimer);
    GameIntroTimer := 0;
  end;
  GameIntroTimer := ScheduleCallbackTimer(10, 10, UpdateGameIntro, 0);
end;
{ @end $557018 }

{ @routine $557218 TfLoad_UpdateGameIntro }
procedure TfLoad.UpdateGameIntro(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Progress: Double; Intro: TgaiGI;
begin
  if SkipGameIntro then
  begin
    if GameIntroTimer <> 0 then
    begin
      CancelCallbackTimer(GameIntroTimer);
      GameIntroTimer := 0;
    end;
    FinishGameIntro;
    Exit;
  end;
  Intro := GetByName('Intro') as TgaiGI;
  Progress := (timeGetTime - IntroStartedAt) / (50 * Intro.SequenceFrameCount);
  if Progress > 1 then Progress := 1;
  Intro.AdvanceToSequenceFrame(Round(Progress * (Intro.SequenceFrameCount - 1)), True);
  if Progress >= 1 then
  begin
    if GameIntroTimer <> 0 then
    begin
      CancelCallbackTimer(GameIntroTimer);
      GameIntroTimer := 0;
    end;
    FinishGameIntro;
  end;
end;
{ @end $557218 }

{ @routine $55731C TfLoad_FinishGameIntro }
procedure TfLoad.FinishGameIntro;
begin
  (GetByName('Intro') as TgaiGI).SetActive(False);
  if MusicEnabled then begin end;
  SkipGameIntro := True;
  if LogoPath <> '' then StartCustomLogo else FinishCustomLogo;
end;
{ @end $55731C }

{ @routine $557380 TfLoad_StartCustomLogo }
procedure TfLoad.StartCustomLogo;
begin
  if not LogoIsVideo then
  begin
    with GetByName('Fon') as TImageGI do
    begin
      SetActive(True);
      SetImagePath('GI,Bm.' + GiResourceSuffix + LogoPath + 'I');
    end;
    GetByName('IntroRect').SetActive(False);
    with GetByName('Intro') as TgaiGI do
    begin
      SetImagePath('Bm.' + GiResourceSuffix + LogoPath + 'A');
      SetPosition(Classes.Point(0, 0));
      SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
      UpdateAutoGeometry;
      LoadFrameSequenceFromText('[40,0-' + IntToStr(GetMainImageFrameCount - 1) + ']');
      PreloadImages;
      SetActive(True);
      StopAutoPlayback;
      SetSequenceFrame(0);
    end;
  end
  else with GetByName('Film') as TxvidGI do ImageOpen('data\' + LogoPath);
  if MusicEnabled then
  begin
    if not LogoIsVideo then MusicManager.PlayCategory(LogoPath)
    else MusicManager.PlayCategory(ExtractFileNameNoExtW(LogoPath));
    while not MusicManager.IsPlaying do SysUtils.Sleep(1);
  end;
  IntroStartedAt := timeGetTime;
  if LogoTimer <> 0 then
  begin
    CancelCallbackTimer(LogoTimer);
    LogoTimer := 0;
  end;
  LogoTimer := ScheduleCallbackTimer(5, 5, UpdateCustomLogo, 0);
end;
{ @end $557380 }

{ @routine $5576C8 TfLoad_UpdateCustomLogo }
procedure TfLoad.UpdateCustomLogo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Progress: Double;
begin
  if SkipLogo then
  begin
    if LogoTimer <> 0 then
    begin
      CancelCallbackTimer(LogoTimer);
      LogoTimer := 0;
    end;
    FinishCustomLogo;
    Exit;
  end;
  Progress := (timeGetTime - IntroStartedAt) / LogoDurationMs;
  if Progress > 1 then Progress := 1;
  if not LogoIsVideo then
    with GetByName('Intro') as TgaiGI do
      AdvanceToSequenceFrame(Round(Progress * (GetMainImageFrameCount - 1)), True)
  else
    with GetByName('Film') as TxvidGI do SetFramePosition(Round(Progress * (LogoVideoFrameCount - 1)));
  if Progress >= 1 then
  begin
    if LogoTimer <> 0 then
    begin
      CancelCallbackTimer(LogoTimer);
      LogoTimer := 0;
    end;
    FinishCustomLogo;
  end;
end;
{ @end $5576C8 }

{ @routine $55781C TfLoad_FinishCustomLogo }
procedure TfLoad.FinishCustomLogo;
begin
  if MusicEnabled then
  begin
    MusicManager.StopImmediately;
    while MusicManager.IsPlaying do SysUtils.Sleep(1);
  end;
  SkipLogo := True;
  (GetByName('Film') as TxvidGI).ImageClose;
  InvalidateViewport;
  IntroPlaying := False;
end;
{ @end $55781C }

end.

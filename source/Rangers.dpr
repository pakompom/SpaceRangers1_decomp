program Rangers;

// Native entry $6162BC.
// Native command-line parsing rechecks argument 1 on every iteration.
{$APPTYPE GUI}
{$IMPLICITBUILD OFF} // Native PACKAGEINFO pfNeverBuild.
{$R Rangers.res}

uses
  Windows, SysUtils, Forms, MMSystem, Classes, Dialogs, EC_OKGF, GI_avi, GR_DirectX3D8, fCommand,
  PrintGameState, EC_FileEx, GR_AMStream, GR_DXBuf, GR_RectEx, GR_RectWin, GI_AlphaBuf, GI_PSWeapon03, GI_PSWeapon10, GI_PSWeapon14, GI_PolyFill, GI_Track, GI_dabWeapon14, GI_dabWeaponLine, SE_Garbage, aRelation, ab_Fast, ab_ShipWall, sb_W01, fGalaxy,
  CheatCode, fHangar,
  fMainForm, fGameSettings, fIntroduction, fPlanet, fPlanetNO, fGameEnd, fGameMenu, fGameLoad, fAbout, fJump, fGoodsShop, fDebugMusic, fLoad, EC_CPUTime,
  fInfo, fRating, fRewards, ExceptionInfo, fScore, fShip2, fPanelPlanet, fSaveManager, fPlanetQuest, GI_MessageBox,
  GI_XviD, GI_PSRay, GI_PSRay2, GI_PSRocket, GI_PSLaser, GI_HeavyLaser, GI_LaserCannonRay, GI_Lightning, GI_PSEyes, GI_PSWind, GI_PSSubmesonicCannon, GI_PSDefibrillator, GI_PSPhaser, GI_PSWeapon01, GI_PSWeapon02, GI_PSWeapon06, GI_PSWeapon08, GI_PSWeapon09, GI_PSWeapon13,
  GR_Music, GI_PlanetButton, SE_Gate, GI_Cursor, GR_DirectX, aConst,
  fCfgSettings, fRuinsTalk, fTalk, fGalaxy2, fGov, fPanelMain, fPanelRuins, aRuins, aRuinsWB, aRuinsRC, aRuinsSB, aRuinsPB, fScaner,
  aScript, aScriptFun, aSaveLoad,
  SE_Weapon, SE_Sputnik,
  aAsteroid, aGroup, aGalaxy, aPlanet, aShip, aNormalShip, aPlayer, aRanger, aTransport, aPirate, aKling, aWarrior,
  aItem, ab_Item, abWall, GI_CountBox,
  SE_Comet, SE_Angel, SE_Planet, SE_Ship2, aPath, EC_FileStream,
  aCalc, ThreadCalc, aEFilm, aEObjInfo, EC_Struct, EC_Mem, CrcUnit, aVector,
  aMyFunction, EC_Str, EC_Ether, EC_Buf, EC_File, EC_HsFile,
  DebugMsg, aPacket, EC_BlockPar, EC_Thread, EC_Data, EC_Cache, EC_CacheBuf, EC_CacheSound, EC_CacheFont,
  EC_Expression, aArtifact, aArtifactTextFieldClass, aQuestParViewStringClass, aQuestValueListClass, aQuestParameterClass, aQuestParameterDeltaClass, aArtifactLocationClass, aArtifactPathClass, aQuestCalcParseClass, aQuestCPVarClass, aQuestCPDiapClass, GR_Main, GR_Rect,
  GR_GraphBuf, GR_Sound, GI_MessageLoop, GI_Main, GI_Panel, GI_Image,
  GI_Label, GI_ScrollBar, GI_PanelScrollBar, GI_Frame, GI_Line, GI_Grid,
  GR_GI, GR_Demo, EC_CacheGI, GI_GI, GI_GAIFile, EC_CacheBitmap, EC_CacheTBitmap,
  EC_CacheAlphaBitmap, GI_SimpleImage, GI_TransImage, GI_AlphaImage, GI_AImage, GI_GraphBuf,
  EC_CacheGAI, GI_GAI, GI_SimpleButton, GI_TextButton, GI_CheckBox, GI_RadioGroup,
  GI_StatusBar, GI_Door, GI_MultiImage, GI_Window, GI_GraphButton, GI_CountBar,
  ab_Global, GI_Circle, GI_PolyLine, GI_Tail, Globals, GlobalsV, ab_MainForm, ab_Obj3D, ab_Tex,
  ab_Zone, ab_StopLine, ab_WorldImage, ab_WorldLine, ab_Space, GI_StarField,
  GI_StarFieldM, GI_StarFieldImg, GI_SpaceCircle, GI_Zone, GI_SpaceImg, GI_SBPath,
  GI_ShrLight, GI_InfiniteImage, GI_Edit, EC_CacheRotateBuf, GI_RotateImage, GI_RotateImage2,
  GR_GraphBufPal, EC_CacheLightPal, EC_CacheHSAI, SE_SoundRnd, SE_Space, SE_Process,
  SE_Anim, SE_BGObj, SE_StarsField, SE_Container, SE_Asteroid, SE_Star,
  SE_Hole, SE_Ruins, SE_Meteorite, SE_Laser, ab_Object, ab_W01,
  ab_W02, ab_W03, ab_W04, ab_W05, ab_W06, ab_W07,
  ab_W08, ab_W09, ab_W10, ab_W11, ab_W12, ab_W13,
  ab_W14, ab_W15, ab_Hit, ab_Ship, ab_ShipAI, EC_CachePalBitmap,
  EC_CachePlanetTempl, GI_Planet, GI_RotateImage5, ab_W, ab_Polygon, fFilmFile, fFilm, aEFilmEnd, fStarMap, aTranclucator, GI_PSWeapon, fEquipmentShop;

type
  TAD = class(TObject) // @size $04
  public
    procedure ApplicationActivated(Sender: TObject); // @addr $61582C
    procedure ApplicationDeactivated(Sender: TObject); // @addr $61583C
  end;
var
  StartupTime: TSystemTime; // @addr $61D230
  ExecutableFileName: AnsiString; // @addr $61D240
  ArgumentIndex: Integer;
  HadProtectedStatus: Boolean;

{ @routine $61564C ClearReadOnlyAttributesRecursive }
procedure ClearReadOnlyAttributesRecursive(DirectoryPath: WideString); // @addr 0x0061564C @note "Changes the process working directory and does not restore it; paths pass through the ANSI filesystem API."
var
  SearchHandle: THandle;
  FindData: TWin32FindDataA;
begin
  SetCurrentDir(AnsiString(DirectoryPath));
  SearchHandle := Windows.FindFirstFile('*.*', FindData);
  if SearchHandle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (FindData.dwFileAttributes and FILE_ATTRIBUTE_READONLY) <> 0 then
        if SetFileAttributesA(FindData.cFileName, FILE_ATTRIBUTE_NORMAL) then;
    until not Windows.FindNextFile(SearchHandle, FindData);
    Windows.FindClose(SearchHandle);
  end;
  SearchHandle := Windows.FindFirstFile('*.*', FindData);
  if SearchHandle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
        if (AnsiString(FindData.cFileName) <> '.') and
           (AnsiString(FindData.cFileName) <> '..') then
          ClearReadOnlyAttributesRecursive(DirectoryPath + '\' + WideString(AnsiString(FindData.cFileName)));
    until not Windows.FindNextFile(SearchHandle, FindData);
    Windows.FindClose(SearchHandle);
  end;
end;
{ @end $61564C }

{ @routine $61582C TAD_ApplicationActivated }
procedure TAD.ApplicationActivated(Sender: TObject);
begin
  if VideoOverlaySurface <> nil then PresentVideoOverlay;
end;
{ @end $61582C }

{ @routine $61583C TAD_ApplicationDeactivated }
procedure TAD.ApplicationDeactivated(Sender: TObject);
begin
  ClipCursor(nil);
  if VideoOverlaySurface <> nil then
    VideoOverlaySurface.UpdateOverlay(nil, VideoPrimarySurface, nil, $200, nil);
end;
{ @end $61583C }

{$I RecoveredExports.inc}

{ @routine $6162BC Rangers_Main }
begin
  // @unit-finalization $615874
  DecimalSeparator := '.';
  MainRuntimeThreadId := GetCurrentThreadId;
  GetMem(PendingMoneyIntegrityFailure, 1);
  OnWindowActivate := @VerifyGalaxyIntegrityCallback;
  OnWindowDeactivate := @ProtectGalaxyIntegrityCallback;
  DebugKeyCallback := @HandleDebugKey;
  RuntimeStartupTick := timeGetTime;
  Application.Initialize;
  with TAD.Create do
  begin
    Application.OnActivate := ApplicationActivated;
    Application.OnDeactivate := ApplicationDeactivated;
  end;
  if OpenEvent(EVENT_MODIFY_STATE, False, 'EG_SpaceRangers_Run') <> 0 then
  begin
    Windows.MessageBox(0, 'Finish game Space Rangers and program AddQuest', 'Space Rangers', MB_ICONERROR);
    Exit;
  end;
  CreateEvent(nil, True, True, 'EG_SpaceRangers_Run');
  for ArgumentIndex := 0 to ParamCount - 1 do
    if LowerCase(ParamStr(1)) = 'buildcfg' then GenerateEncodedResources := True
    else if LowerCase(ParamStr(1)) = 'extractcfg' then ExportDecodedResources := True
    else if LowerCase(ParamStr(1)) = 'skip1c' then SkipPublisherIntro := True;
  SetLength(ExecutableFileName, MAX_PATH);
  if GetModuleFileName(0, PAnsiChar(ExecutableFileName), MAX_PATH) <> 0 then
  begin
    SetLength(ExecutableFileName, StrLen(PAnsiChar(ExecutableFileName)));
    ClearReadOnlyAttributesRecursive(ExtractFileDirW(WideString(ExecutableFileName)));
    SetCurrentDir(AnsiString(ExtractFileDirW(WideString(ExecutableFileName))));
  end;
  Randomize;
  try
    try
      RestartScreenId := screenMainMenu;
      InitializePlatformRuntimeAndMainWindow;
      InitializeScriptHostRuntime;
      HadProtectedStatus := False;
      GetSystemTime(StartupTime);
      AppendOptionalDebugLogLine(Format('=== Start %d-%.2d-%.2d %.2d.%.2d.%.2d.%.3d',
        [StartupTime.wYear, StartupTime.wMonth, StartupTime.wDay, StartupTime.wHour,
         StartupTime.wMinute, StartupTime.wSecond, StartupTime.wMilliseconds]));
      while True do
      begin
        InitializeRuntimeAndSettings;
        InitializeGlobalUiRuntime;
        timeBeginPeriod(1);
        if Galaxy <> nil then
        begin
          Galaxy.RefreshAllShipDerivedState;
          if HadProtectedStatus then;
        end;
        if BuildVersionMismatch then Break;
        RequestedScreenId := screenLoad;
        ScreenLoadMode := 0;
        if ScreenUsesCompositeLoadAssets(RestartScreenId) then ScreenLoadMode := 3;
        RunMainScreenStateLoop;
        timeEndPeriod(1);
        HadProtectedStatus := False;
        if Galaxy <> nil then
        begin
          HadProtectedStatus := Galaxy.ProtectedStateXorSeed <> 0;
          Galaxy.RestoreProtectedState;
          Galaxy.IntegrityChecksumPending := False;
        end;
        FinalizeGlobalUiRuntime;
        FinalizeRuntimeAndSettings;
        if ((RequestedScreenId = screenNone) and (RestartScreenId = screenNone)) or ExitScreenLoop then Break;
      end;
      if Galaxy <> nil then
      begin
        if IsTurnCalculationRunning then WaitForTurnCalculation;
        Galaxy.Free;
        Galaxy := nil;
      end;
      FreeAllRandomSounds;
      FinalizeScriptHostRuntime;
      FinalizePlatformRuntime;
      if StartupCleanupObject <> nil then
      begin
        StartupCleanupObject.Free;
        StartupCleanupObject := nil;
      end;
    except
      if Galaxy <> nil then
      begin
        if IsTurnCalculationRunning then WaitForTurnCalculation;
        Galaxy.Free;
        Galaxy := nil;
      end;
      if DirectDrawDevice <> nil then DirectDrawDevice.FlipToGDISurface;
      FinalizeGlobalUiRuntime;
      FinalizeRuntimeAndSettings;
      FreeAllRandomSounds;
      FinalizeScriptHostRuntime;
      FinalizePlatformRuntime;
      if StartupCleanupObject <> nil then
      begin
        StartupCleanupObject.Free;
        StartupCleanupObject := nil;
      end;
      raise;
    end;
  except
    on E: Exception do
    begin
      AppendLogLineThreadSafe('Exception:' + E.Message);
      if RestoreNormalCooperativeLevel then
        Windows.MessageBox(MainWindowHandle, PAnsiChar(E.Message), 'Exception:', 0);
    end;
  end;
end.
{ @end $6162BC }

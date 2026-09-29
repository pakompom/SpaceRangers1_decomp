unit GlobalsV;
// Unit bracket (inferred): CODE 0x00453728..0x00453997; inclusive evidence, not full bounds.
// Scene image caches.
interface
uses EC_Struct, Classes;
type
  // Screen 13 has a return screen but no form; 14 is unused.
  TGameScreenId = (
    screenNone = 0,
    screenMainMenu = 1,
    screenNewGame = 2,
    screenIntroduction = 3,
    screenHangar = 4,
    screenPlanet = 5,
    screenPlanetNO = 6,
    screenPlanetQuest = 7,
    screenEquipmentShop = 8,
    screenGoodsShop = 9,
    screenShip = 10,
    screenTalk = 11,
    screenScanner = 12,
    screenUnknown13 = 13, // Not registered; identity unresolved.
    screenGovernment = 15,
    screenStarMap = 16,
    screenFilm = 17,
    screenGalaxy = 18,
    screenJump = 19,
    screenRuinsTalk = 20,
    screenArcadeBattle = 21,
    screenLoad = 22,
    screenSaveManager = 23,
    screenGameLoad = 24,
    screenGameMenu = 25,
    screenSettings = 26,
    screenGameEnd = 27,
    screenInfo = 28,
    screenRating = 29,
    screenRewards = 30,
    screenAbout = 31,
    screenScores = 32
  ); // @size $01
  TSpaceImageTemplate = record // @size $10
    Kind: Integer; // @offset $00 SpaceImg parameter name; used for weighted selection.
    Weight: Integer; // @offset $04
    CacheControl: TObject; // @offset $08 Owned, released by UI shutdown.
    CachedData: TObject; // @offset $0C Borrowed during rendering.
  end;

  TStarFieldImageTemplate = record // @size $10
    Reserved: Integer; // @offset $00 Zero-initialized; use not yet established.
    Weight: Integer; // @offset $04 StarFieldImg parameter name.
    CacheControl: TObject; // @offset $08 Owned, released by UI shutdown.
    CachedData: TObject; // @offset $0C Borrowed during rendering.
  end;

var
  GenerateEncodedResources: Boolean = False; // @addr $617D98 Startup writes the language, cache-data and main .dat files.
  ExportDecodedResources: Boolean = False; // @addr $617D9C Startup writes decoded language and main _e.txt files.
  AllowDefeatScoreExport: Boolean = False; // @addr $617DA0 Allows export of negative-outcome entries with integrity data.
  ChangeAutoPilot: Integer = 4; // @addr $617DA4
  SkipHyperAnimation: Boolean = False; // @addr $617DA8
  WindDensity: Integer = 2; // @addr $617DAC
  TestQuestPath: WideString = 'Prison'; // @addr $617DB0
  ShipTail: Integer = 0; // @addr $617DB4
  Direct3D8Enabled: Boolean = False; // @addr $617DB8 Config '3D' flag; disabled after an EAbort during Direct3D 8 initialization. Used by arena entry only when Player is nil.
  AnimCaptain: Boolean = False; // @addr $617DBC
  AnimItem: Boolean = False; // @addr $617DC0
  CometDensity: Integer = 1; // @addr $617DC4
  BGImage: Boolean = False; // @addr $617DC8
  AnimShipFull: Boolean = False; // @addr $617DCC
  AnimCity: Boolean = False; // @addr $617DD0
  AnimGov: Boolean = True; // @addr $617DD4
  AnimStar: Boolean = True; // @addr $617DD8
  AnimHangar: Boolean = True; // @addr $617DDC
  HideActionCircle: Boolean = True; // @addr $617DE0
  StaticBackground: Boolean = True; // @addr $617DE4
  ScrollTime: Integer = 20; // @addr $617DE8
  ScrollSpeed: Integer = 5; // @addr $617DEC
  FilmSpeed: Integer = 1; // @addr $617DF0
  BGOCount: Integer = 50; // @addr $617DF4
  BGOTime: Integer = 300; // @addr $617DF8
  SpaceImage: Integer = 0; // @addr $617DFC
  SoundEnabled: Boolean = False; // @addr $617E00
  SoundInSpaceEnabled: Boolean = False; // @addr $617E04
  SoundVolume: Single = 1.0; // @addr $617E08
  MusicEnabled: Boolean = False; // @addr $617E0C
  MusicInSpace: Boolean = False; // @addr $617E10
  MusicInHyper: Boolean = True; // @addr $617E14
  MusicInPlanet: Boolean = True; // @addr $617E18
  MusicVolume: Single = 0.75; // @addr $617E1C
  MaxFilmStepSkip: Integer = 3; // @addr $617E20
  CountFilmSave: Integer = 50; // @addr $617E24
  AutoSave: Boolean = False; // @addr $617E28
  PlanetDepth: Single = 0.0; // @addr $617E2C
  ShipPathDepth: Single = 15.0; // @addr $617E30
  ShipPathEndDepth: Single = 14.0; // @addr $617E34
  UnitPathDepth: Single = 13.0; // @addr $617E38
  UnitPathEndDepth: Single = 12.0; // @addr $617E3C
  ActionButtonDepth: Single = 9.0; // @addr $617E40
  GalaxyStarDepth: Single = 20.0; // @addr $617E44
  GalaxyStarNameDepth: Single = 19.0; // @addr $617E48
  GalaxyWarDepth: Single = 18.0; // @addr $617E4C
  ConstellationLineDepth: Single = 21.0; // @addr $617E50
  ConstellationColorDepth: Single = 22.0; // @addr $617E54
  CurrentScreenId: TGameScreenId = screenNone; // @addr $617E58
  RequestedScreenId: TGameScreenId = screenNone; // @addr $617E5C
  RestartScreenId: TGameScreenId = screenNone; // @addr $617E60
  ShipReturnScreenId: TGameScreenId = screenNone; // @addr $617E64
  TalkReturnScreenId: TGameScreenId = screenNone; // @addr $617E68
  ScannerReturnScreenId: TGameScreenId = screenNone; // @addr $617E6C Restored by scanner close/escape callbacks.
  PlanetQuestReturnScreenId: TGameScreenId = screenNone; // @addr $617E70
  Screen13ReturnScreenId: TGameScreenId = screenNone; // @addr $617E74 Return screen for dormant screen 13; its identity is unresolved.
  GalaxyReturnScreenId: TGameScreenId = screenNone; // @addr $617E78
  SaveManagerReturnScreenId: TGameScreenId = screenNone; // @addr $617E7C
  GameMenuReturnScreenId: TGameScreenId = screenNone; // @addr $617E80
  SettingsReturnScreenId: TGameScreenId = screenNone; // @addr $617E84
  LoadedSaveVersion: Integer = 0; // @addr $617E88
  LoadingFilmCount: Integer = -1; // @addr $617E8C Negative during galaxy loading; then the number of film entries.
  SputnikShow: Boolean = True; // @addr $617E90
  RegisteredScreens: array[TGameScreenId] of TObject; // @addr $61BC04
  SkipSavedPixelRestore: Boolean; // @addr $61BC88
  HitPointFontName: WideString; // @addr $61BC8C
  ScoreFontName: WideString; // @addr $61BC90 Score and outcome labels; broader font role unresolved.
  NormalPlusFontName: WideString; // @addr $61BC94
  NormalFontName: WideString; // @addr $61BC98
  AuthorsFontName: WideString; // @addr $61BC9C
  PendingLoadFileName: AnsiString; // @addr $61BCA0
  LoadedFilmCount: Integer; // @addr $61BCA4
  GameEndReason: Integer; // @addr $61BCA8
  SatelliteLightMapPath: WideString = 'Bm.Planet.S.Light094'; // @addr $617E94
  SatelliteTemplateParameter1: Integer = 128; // @addr $617E98
  SatelliteTemplateParameter2: Integer = 60; // @addr $617E9C
  MinimumSatelliteTemplateRadius: Integer = 10; // @addr $617EA0
  GeneratedSatelliteBaseRadius: Integer = 13; // @addr $617EA4
  MaximumSatelliteTemplateRadius: Integer = 60; // @addr $617EA8

  SatelliteRenderTemplates: TList = nil; // @addr $617EAC

function GetRegisteredScreenLoop(ScreenId: TGameScreenId): TObject; // @addr $4537B0

function FormToId(Screen: TObject): TGameScreenId; // @addr $45376C
function IsSpaceBackdropScreen(ScreenId: TGameScreenId): Boolean; // @addr $4537BC
function ScreenUsesCompositeLoadAssets(ScreenId: TGameScreenId): Boolean; // @addr $4537D4

var
  SpaceImageTemplates: array of TSpaceImageTemplate = nil; // @addr $617EB0
  StarFieldImageTemplates: array of TStarFieldImageTemplate = nil; // @addr $617EB4

implementation

// @unit-initialization $453984
// @unit-finalization $4538D0

uses SysUtils;

{ @routine $45376C FormToId }
function FormToId(Screen: TObject): TGameScreenId;
var Id: TGameScreenId;
begin
  for Id := screenNone to screenScores do
    if Screen = RegisteredScreens[Id] then
    begin
      Result := Id;
      Exit;
    end;
  raise Exception.Create('FormToId');
end;
{ @end $45376C }

{ @routine $4537B0 GetRegisteredScreenLoop }
function GetRegisteredScreenLoop(ScreenId: TGameScreenId): TObject;
begin
  Result := RegisteredScreens[ScreenId];
end;
{ @end $4537B0 }

{ @routine $4537BC IsSpaceBackdropScreen }
function IsSpaceBackdropScreen(ScreenId: TGameScreenId): Boolean;
begin
  Result := (ScreenId = screenStarMap) or (ScreenId = screenGalaxy) or (ScreenId = screenFilm) or (ScreenId = screenTalk);
end;
{ @end $4537BC }

{ @routine $4537D4 ScreenUsesCompositeLoadAssets }
function ScreenUsesCompositeLoadAssets(ScreenId: TGameScreenId): Boolean;
begin
  Result := False;
  if IsSpaceBackdropScreen(ScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenLoad) and IsSpaceBackdropScreen(RestartScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenShip) and IsSpaceBackdropScreen(ShipReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenScanner) and IsSpaceBackdropScreen(ScannerReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenUnknown13) and IsSpaceBackdropScreen(Screen13ReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenSaveManager) and IsSpaceBackdropScreen(SaveManagerReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenGameMenu) and IsSpaceBackdropScreen(GameMenuReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenSettings) and IsSpaceBackdropScreen(SettingsReturnScreenId) then begin Result := True; Exit; end;
  if (ScreenId = screenSettings) and (SettingsReturnScreenId = screenGameMenu) and IsSpaceBackdropScreen(GameMenuReturnScreenId) then Result := True;
end;
{ @end $4537D4 }
end.

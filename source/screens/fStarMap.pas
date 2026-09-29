unit fStarMap;
// Unit bracket (inferred): CODE 0x00565708..0x00574C1B; inclusive evidence, not full bounds.
// Star-map backgrounds, camera, path overlays and animation ownership.
interface
uses aEFilm, SE_Space, GI_GraphButton, GI_Panel, GI_MessageLoop, GI_StarField, GI_SpaceImg, Types, EC_Struct, aAsteroid, fPanelMain, aShip, GI_Window, GI_Label, GI_SpaceCircle, GI_Circle, GI_Image;
type
  TStarMapPathKind = (smpNone, smpAsteroid, smpShip); // @size $04
  TStarMapReservedEntry = packed record // @size $08 Anonymous array RTTI $565708/$56572C; element meaning unresolved.
    Data: array[0..7] of Byte; // @offset $00
  end;
  TfStarMap = class(TMessageLoopGI) // @size $1BC
  public
    procedure InitializeLayout; override; // @addr $565A48
    procedure OnOpen; override; // @addr $5663A8
    procedure OnClose; override; // @addr $5666E4
    procedure RedrawMap; // @addr $56910C
    procedure DrawFrame; override; // @addr $569138
    procedure SelectMusic; override; // @addr $574B78
    procedure GalaxyClicked(Sender: TObjectGI); // @addr $569264
    procedure ShipClicked(Sender: TObjectGI); // @addr $5692B8
    procedure OpenFilmHistoryClicked(Sender: TObjectGI); // @addr $5675BC
    procedure AllWeaponsClicked(Sender: TObjectGI); // @addr $56EB58
    procedure ScannerClicked(Sender: TObjectGI); // @addr $56EB80
    procedure TalkClicked(Sender: TObjectGI); // @addr $56EBD8
    procedure ToggleWeaponPanelClicked(Sender: TObjectGI); // @addr $56EC30
    procedure MapKeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $567574
    procedure MapKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $56739C
    procedure AdvanceSpaceEffects(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $569A3C
    procedure MapScrollChanged; // @addr $56EA0C
    procedure OrderKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $56AB2C
    procedure OrderKeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $56AD54
    procedure ScrollTimerTick(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $569908
    procedure RefreshWeaponButtons; // @addr $56ECFC
    procedure SelectAllWeapons; // @addr $56AD68
    procedure SelectUntargetedWeapons; // @addr $56ADB4
    procedure StopOrderMode; // @addr $569750
    procedure HideWeaponImages; // @addr $56EE30
    procedure WeaponClicked(Sender: TObjectGI); // @addr $56EC70
    procedure HideOrderInterface; // @addr $569840
    procedure EndTurnClicked(Sender: TObjectGI); // @addr $567138
    procedure MapLeftButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $569A94
    procedure MapRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $56A7DC
    procedure MapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $56AA00
    PanelController: TfPanelMain; // @offset $B0 Owned, created at $5657EC and freed at $565880.
    Mode: Byte; // @offset $B4 2 while playing the turn film.
    ResumeMode: Byte; // @offset $B5 Conversation exit schedules native resume mode 3.
    ScrollLeftHeld: Boolean; // @offset $B6
    ScrollRightHeld: Boolean; // @offset $B7
    ScrollUpHeld: Boolean; // @offset $B8
    ScrollDownHeld: Boolean; // @offset $B9
    CenterShipButton: TGraphButtonGI; // @offset $BC MinimapMouseDown/Move.
    DisplayedObject: TObject; // @offset $C0 Cached object for information panels.
    SpaceEffectsTimer: TCallbackTimerIdGI; // @offset $C4
    CursorObject: TObject; // @offset $C8 Object under the cursor; controls player minimap path updates.
    ScrollTimer: TCallbackTimerIdGI; // @offset $CC
    ScannerSelectionActive: Boolean; // @offset $D0
    TalkSelectionActive: Boolean; // @offset $D1
    SelectedWeapons: array[0..4] of Boolean; // @offset $D2
    MinimapPathKind: TStarMapPathKind; // @offset $DC 0 none, 1 asteroid, 2 ship.
    function FindObjectAtCursor: TObject; // @addr $568E14
    procedure RefreshActionRanges; // @addr $56EE50
    procedure HideActionRanges; // @addr $56F2DC
    procedure RebuildTargetMarkers; // @addr $56F308
    procedure ClearTargetMarkers; // @addr $56F6F4
    procedure UpdateActionCursor; // @addr $56F728
    procedure PartnerClicked(Sender: TObjectGI); // @addr $5688EC
    procedure CenterOnPlayer(Sender: TObjectGI); // @addr $56EA24
    PathAsteroid: TAsteroid; // @offset $E0 ClearAsteroidPath clears the reference and controls tagged 101.
    FilmFrameTimer: TCallbackTimerIdGI; // @offset $E4
    FilmStepIndex: Integer; // @offset $E8
    NextFilmCommand: PEFilmCommand; // @offset $EC
    FilmProgressTimer: TCallbackTimerIdGI; // @offset $F0
    procedure FilmMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $571224
    ContinueTurnCalculation: Boolean; // @offset $F4
    BreakRequested: Boolean; // @offset $F5
    BreakOnNextFilm: Boolean; // @offset $F6
    FilmFlagF7: Boolean; // @offset $F7 Set when starting playback; meaning unresolved.
    ReservedFilmStateF8: Integer; // @offset $F8 Cleared after the first playback frame.
    FilmFrameIntervalMs: Single; // @offset $FC
    FilmFrameIntervalDelta: Single; // @offset $100
    FilmCameraPosition: TPointF; // @offset $104
    FilmCameraTarget: TPointF; // @offset $10C
    FilmCameraTargetUntilStep: Integer; // @offset $114
    FilmCameraEventIndex: Integer; // @offset $118
    procedure ShowObjectInfo(Obj: TObject); // @addr $56AE00
    FilmCameraTargetKind: Integer; // @offset $11C
    FilmCameraShakeAngle: Single; // @offset $120
    FilmCameraShakeOffset: TPointF; // @offset $124
    FilmCameraSpeed: Single; // @offset $12C Initialized to 1.
    FilmCameraMoving: Boolean; // @offset $130
    ReservedEntries1: array of TStarMapReservedEntry; // @offset $134 Allocated with 250 entries.
    ReservedEntries2: array of TStarMapReservedEntry; // @offset $138 Allocated with 250 entries.
    ReservedFilmState13C: Integer; // @offset $13C Cleared on film start/restart; meaning unresolved.
    TrailingEffectSteps: Integer; // @offset $144
    DisplayedFilmObject: TObjectSE; // @offset $148 Cached scene object from the turn film.
    MapControls: TPanelGI; // @offset $14C Lazily resolved MainPanel in SetMapCenter.
    SecondaryPartnerPanel: TPanelGI; // @offset $150 MinimapMouseDown.
    InfoWindow: TWindowGI; // @offset $154
    InfoTextLabel: TLabelGI; // @offset $158
    ItemInfoWindow: TPanelGI; // @offset $15C
    procedure StartTurnFilm; // @addr $56FCE4
    procedure StopTurnFilm(StopTurnProcessing: Boolean); // @addr $56FFFC
    procedure RestartTurnFilm; // @addr $5700D0
    procedure ClearPartnerButtons; // @addr $5684E0
    procedure PartnerMouseEnter(Sender: TObjectGI); // @addr $568C68
    procedure CenterShipMouseLeave(Sender: TObjectGI); // @addr $568CA8
    procedure PartnerRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $568B5C
    procedure RebuildPartnerButtons; // @addr $5684EC
    procedure PrepareTalkDisplay; // @addr $5748CC
    procedure WaitForTurnOrTalk; // @addr $574A04
    procedure QueueInterfaceImages; // @addr $5690BC
    procedure StartOrderMode; // @addr $569324
    procedure ProcessTurnFilm; // @addr $5702D8
    procedure AdvanceFilmFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5708E0
    procedure UpdateTurnCalculation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $570A04
    procedure BreakTurnClicked(Sender: TObjectGI); // @addr $570A7C
    ShipInfoPanel: TPanelGI; // @offset $160
    PlanetInfoPanel: TPanelGI; // @offset $164
    StarInfoWindow: TPanelGI; // @offset $168
    StandardInfoPanel: TPanelGI; // @offset $16C
    StarField: TStarFieldGI; // @offset $170
    ActionCircle: TCircleGI; // @offset $174
    ActionColorCircle: TSpaceCircleGI; // @offset $178
    InnerWeaponColorCircle: TSpaceCircleGI; // @offset $17C
    WeaponButtons: array[0..4] of TGraphButtonGI; // @offset $180
    procedure UpdateFilmCamera; // @addr $570AC0
    procedure CenterFilmShipClicked(Sender: TObjectGI); // @addr $571210
    procedure RefreshFilmObjectInfoAtCursor; // @addr $5712CC Native cursor lookup also updates the information panel.
    procedure ShowFilmObjectInfo(Obj: TObjectSE; ObjectId: Cardinal); // @addr $571598
    WeaponImages: array[0..4] of TImageGI; // @offset $194
    AllWeaponsButton: TGraphButtonGI; // @offset $1A8
    HideWeaponPanelButton: TGraphButtonGI; // @offset $1AC
    constructor Create; // @addr $5657EC
    destructor Destroy; override; // @addr $565880
    function GetMapCenter: TPoint; // @addr $5658E0
    procedure SetMapCenterManually(Point: TPoint); // @addr $565938
    procedure SaveSpaceBackground; // @addr $5670F8
    procedure BuildShipPathOverlay(Ship: TShip); // @addr $5675E0
    procedure ShowAsteroidPath(Asteroid: TAsteroid); // @addr $5681E8
    procedure ClearPathOverlay(PlayerPath: Boolean); // @addr $5680EC
    procedure ClearAsteroidPath; // @addr $568468
    procedure AddMapAnimation(Position: TPointF; ImagePath: WideString; DelayMs: Integer); // @addr $568CB0
    procedure ClearMapAnimations; // @addr $568DC8
    procedure MapAnimationFinished(Sender: TObjectGI); // @addr $568DFC
    ScannerButton: TGraphButtonGI; // @offset $1B0
    TalkButton: TGraphButtonGI; // @offset $1B4
    TurnFilmButton: TGraphButtonGI; // @offset $1B8
    procedure BuildSpaceBackground(StarField: TStarFieldGI; SpaceImage: TSpaceImgGI; Seed: Cardinal); // @addr $5667DC
    procedure SaveSpaceImageState(SpaceImage: TSpaceImgGI); // @addr $566F8C
    procedure SetMapCenter(Center: TPoint); // @addr $5659C4
  end;
function GetTurnFilmFrameInterval(Activity: Integer): Integer; // @addr $56FCA8

implementation

// @unit-initialization $574C14
// @unit-finalization $574BE4

uses Globals, GlobalsV, SE_Process, SE_Space, aGalaxy, aMyFunction, GR_Main, GI_MultiImage, GI_GAI, Classes, GI_Image, GI_Label, aPath, aPlayer, aRanger, aPlanet, EC_Mem, SysUtils, Math, aItem, aConst, aRuins, SE_Hole, SE_Asteroid, SE_Planet, SE_Star, SE_Ship2, SE_Ruins, GI_GraphBuf, EC_Str, GR_gi, fShip2, aEObjInfo, SE_Container, aCalc, GR_Music, aKling, aEFilmEnd, Windows, fLoad, GR_Sound, GI_Main, fSaveManager, aSaveLoad, GI_MessageBox, GI_StarFieldImg, GR_Rect, ThreadCalc;

var
  FilmCameraLookAheadSteps: Integer = 30; // @addr $618780

{ @routine $5657EC TfStarMap_Create }
constructor TfStarMap.Create;
begin
  inherited Create;
  UpdateRectsEnabled := False;
  PanelController := TfPanelMain.Create;
  SetLength(ReservedEntries1, 250);
  SetLength(ReservedEntries2, 250);
  FilmCameraSpeed := 1;
end;
{ @end $5657EC }

{ @routine $565880 TfStarMap_Destroy }
destructor TfStarMap.Destroy;
begin
  ReservedEntries1 := nil;
  ReservedEntries2 := nil;
  if PanelController <> nil then
  begin
    PanelController.Free;
    PanelController := nil;
  end;
  inherited Destroy;
end;
{ @end $565880 }

{ @routine $5658E0 TfStarMap_GetMapCenter }
function TfStarMap.GetMapCenter: TPoint;
begin
  if MapControls = nil then MapControls := GetByName('MainPanel') as TPanelGI;
  Result := MapControls.ScrollOffset;
end;
{ @end $5658E0 }

{ @routine $565938 TfStarMap_SetMapCenterManually }
procedure TfStarMap.SetMapCenterManually(Point: TPoint);
begin
  if MapControls = nil then MapControls := GetByName('MainPanel') as TPanelGI;
  MapControls.SetScrollOffset(Point);
  if SpaceProcess.IsSpaceOpen then SpaceProcess.Space.MapScrollChanged(nil);
  FilmCameraFollow := False;
end;
{ @end $565938 }

{ @routine $5659C4 TfStarMap_SetMapCenter }
procedure TfStarMap.SetMapCenter(Center: TPoint);
begin
  if MapControls = nil then MapControls := GetByName('MainPanel') as TPanelGI;
  MapControls.SetScrollOffset(Center);
  if SpaceProcess.IsSpaceOpen then SpaceProcess.Space.MapScrollChanged(nil);
end;
{ @end $5659C4 }

{ @routine $565A48 TfStarMap_InitializeLayout }
procedure TfStarMap.InitializeLayout;
begin
  inherited InitializeLayout;
  PanelController.InitializeLayout(Self);
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  (GetByName('PM_Gal') as TGraphButtonGI).UpCallback := GalaxyClicked;
  (GetByName('PM_Ship') as TGraphButtonGI).UpCallback := ShipClicked;
  MapControls := GetByName('MainPanel') as TPanelGI;
  SecondaryPartnerPanel := GetByName('MapPartner') as TPanelGI;
  InfoWindow := GetByName('Info') as TWindowGI;
  InfoTextLabel := GetByName('InfoText') as TLabelGI;
  ItemInfoWindow := GetByName('InfoItem') as TPanelGI;
  ShipInfoPanel := GetByName('InfoShip') as TPanelGI;
  PlanetInfoPanel := GetByName('InfoPlanet') as TPanelGI;
  StarInfoWindow := GetByName('InfoStar') as TPanelGI;
  StandardInfoPanel := GetByName('InfoStd') as TPanelGI;
  StarField := GetByName('StarField') as TStarFieldGI;
  ActionCircle := GetByName('CircleActionShr') as TCircleGI;
  ActionColorCircle := GetByName('CircleActionColor') as TSpaceCircleGI;
  InnerWeaponColorCircle := GetByName('CircleActionWeaponColor') as TSpaceCircleGI;
  WeaponButtons[0] := GetByName('PS_W0') as TGraphButtonGI;
  WeaponButtons[1] := GetByName('PS_W1') as TGraphButtonGI;
  WeaponButtons[2] := GetByName('PS_W2') as TGraphButtonGI;
  WeaponButtons[3] := GetByName('PS_W3') as TGraphButtonGI;
  WeaponButtons[4] := GetByName('PS_W4') as TGraphButtonGI;
  WeaponImages[0] := GetByName('PS_W0I') as TImageGI;
  WeaponImages[1] := GetByName('PS_W1I') as TImageGI;
  WeaponImages[2] := GetByName('PS_W2I') as TImageGI;
  WeaponImages[3] := GetByName('PS_W3I') as TImageGI;
  WeaponImages[4] := GetByName('PS_W4I') as TImageGI;
  AllWeaponsButton := GetByName('PS_WA') as TGraphButtonGI;
  HideWeaponPanelButton := GetByName('PS_Hide') as TGraphButtonGI;
  ScannerButton := GetByName('PS_Scaner') as TGraphButtonGI;
  TalkButton := GetByName('PS_Talk') as TGraphButtonGI;
  TurnFilmButton := GetByName('PS_Film') as TGraphButtonGI;
  MapControls.KeyDownCallback := MapKeyDown;
  MapControls.KeyUpCallback := MapKeyUp;
  MapControls.SetDragScrollingEnabled(True);
  MapControls.ScrollType := pstSimple;
  (GetByName('PM_Gal') as TGraphButtonGI).UpCallback := GalaxyClicked;
  with GetByName('PS_Film') as TGraphButtonGI do begin
    UpCallback := OpenFilmHistoryClicked;
    HelpCallback := PanelController.ShowControlHelp;
  end;
  (GetByName('PM_EndTurn') as TGraphButtonGI).UpCallback := EndTurnClicked;
  CenterShipButton := GetByName('CenterShip') as TGraphButtonGI;
  CenterShipButton.HelpCallback := PanelController.ShowControlHelp;
  with GetByName('PS_WA') as TGraphButtonGI do begin
    UpCallback := AllWeaponsClicked;
    HelpCallback := PanelController.ShowControlHelp;
  end;
  with GetByName('PS_Scaner') as TGraphButtonGI do begin
    UpCallback := ScannerClicked;
    HelpCallback := PanelController.ShowControlHelp;
  end;
  with GetByName('PS_Talk') as TGraphButtonGI do begin
    UpCallback := TalkClicked;
    HelpCallback := PanelController.ShowControlHelp;
  end;
  with GetByName('PS_Hide') as TGraphButtonGI do begin
    UpCallback := ToggleWeaponPanelClicked;
    HelpCallback := PanelController.ShowControlHelp;
  end;
  GetByName('PS_W0').HelpCallback := PanelController.ShowControlHelp;
  GetByName('PS_W1').HelpCallback := PanelController.ShowControlHelp;
  GetByName('PS_W2').HelpCallback := PanelController.ShowControlHelp;
  GetByName('PS_W3').HelpCallback := PanelController.ShowControlHelp;
  GetByName('PS_W4').HelpCallback := PanelController.ShowControlHelp;
  with GetByName('MapPanel') as TGraphBufGI do
    GraphBuf.AttachPixels(RenderScratchBuffer.Width, RenderScratchBuffer.Height,
      RenderScratchBuffer.PitchBytes, RenderScratchBuffer.Pixels);
end;
{ @end $565A48 }

{ @routine $5663A8 TfStarMap_OnOpen }
procedure TfStarMap.OnOpen;
var Entry: PEFilmEndEntry;
begin
  BreakOnNextFilm := False;
  ClearMapAnimations;
  GetByName('FPS').SetActive(ShowFPS);
  SetMapCenter(TruncatePointF(SpaceViewPosition));
  PanelController.OnOpen;
  PanelController.Hide;
  GetByName('PanelSpace').SetActive(False);
  UpdateRectsEnabled := True;
  MapControls.Invalidate;
  UpdateRectsEnabled := False;
  PlayerStar.OpenSpaceScene(MapControls, GetByName('MapPanel'), Self);
  if ResumeMode <> 2 then PlayerStar.RefreshSpaceObjectPositions;
  BuildSpaceBackground(GetByName('StarField') as TStarFieldGI, GetByName('SpaceImg') as TSpaceImgGI,
    PlayerStar.GenerationSeed);
  ScrollTimer := ScheduleCallbackTimer(ScrollTime, ScrollTime, ScrollTimerTick);
  with GetByName('StarFieldImg') as TStarFieldImgGI do begin
    SetActive(WindDensity >= 2);
    if StarCount <= 0 then SeedStars;
  end;
  FindControlByPath('StarFieldM').SetActive(WindDensity >= 1);
  if ResumeMode = 2 then begin
    SelectMusic;
    StartTurnFilm;
  end
  else if ResumeMode = 3 then begin
    if not MusicInSpace then MusicManager.RequestFadeOut;
    WaitForTurnOrTalk;
  end
  else begin
    if not MusicInSpace then MusicManager.RequestFadeOut;
    StartOrderMode;
  end;
  ResumeMode := 0;
  if TrailingFilmEffects <> nil then begin
    Entry := TrailingFilmEffects.FirstEntry;
    while Entry <> nil do begin
      Entry.SceneObject.AttachToSpace(SpaceProcess.Space);
      if Entry.RelatedObject1 <> nil then TWeaponSE(Entry.RelatedObject1).AttachToSpace(SpaceProcess.Space);
      Entry := Entry.Next;
    end;
  end;
  if ShipScreen.SkipOpeningSlide then begin
    SetCursorActive(False);
    PanelController.RefreshMoneyAndCargo;
    FullFrameRedrawRequested := True;
    DrawFrame;
    CaptureScreenBackground;
    ShipReturnScreenId := FormToId(Self);
    RequestedScreenId := screenShip;
    RequestClose(1);
  end
  else SetCursorActive(True);
end;
{ @end $5663A8 }

{ @routine $5666E4 TfStarMap_OnClose }
procedure TfStarMap.OnClose;
begin
  ClearPartnerButtons;
  SaveSpaceBackground;
  if ScrollTimer <> 0 then begin
    CancelCallbackTimer(ScrollTimer);
    ScrollTimer := 0;
  end;
  if TrailingFilmEffects <> nil then begin
    TrailingFilmEffects.Free;
    TrailingFilmEffects := nil;
  end;
  (GetByName('InfoStarPanel') as TPanelGI).FreeOwnedChildren;
  PanelController.OnClose;
  if Mode = 1 then StopOrderMode
  else if Mode = 2 then StopTurnFilm(True);
  SpaceProcess.CloseSpace;
  if CacheLoader.IsRunning then CacheLoader.WaitForIdle(INFINITE);
  if ExitScreenLoop then WaitForTurnCalculation;
  CacheLoadLoggingEnabled := False;
end;
{ @end $5666E4 }

{ @routine $5667DC TfStarMap_BuildSpaceBackground }
procedure TfStarMap.BuildSpaceBackground(StarField: TStarFieldGI; SpaceImage: TSpaceImgGI; Seed: Cardinal);
var
  Radius, Diameter, X, Y, Index, Attempts, Kind: Integer;
  Depth: Single;
  Scale: Double;
  Count: Integer;
  Image: PSpaceImageGI;
  Colors: array[0..15] of Cardinal;
begin
  Seed := StepRandomSeed(Seed);
  Radius := Round(PlayerStar.ComputeMapDiameter div 2);
  Diameter := PlayerStar.ComputeMapDiameter;
  Scale := RemapClamped(Radius, 2500.0, 4500.0, 1.0, 2.0);
  Count := Round(Scale * 2000.0);
  for Index := 0 to 3 do Colors[Index] := CurrentPixelFormat.PackRgbBytes(100 + 16 * Index, 100 + 16 * Index, 100 + 16 * Index);
  for Index := 0 to 3 do Colors[Index + 4] := CurrentPixelFormat.PackRgbBytes(100 + 40 * Index, 1, 1);
  for Index := 0 to 3 do Colors[Index + 8] := CurrentPixelFormat.PackRgbBytes(1, 100 + 40 * Index, 1);
  for Index := 0 to 3 do Colors[Index + 12] := CurrentPixelFormat.PackRgbBytes(1, 1, 100 + 40 * Index);
  StarField.Stars.Clear;
  for Index := 0 to Round(Count * 0.6) do
  begin
    X := SeededRandomIntRange(-Radius * 5, Radius * 5, Seed);
    Seed := StepRandomSeed(Seed);
    Y := SeededRandomIntRange(-Radius * 5, Radius * 5, Seed);
    Seed := StepRandomSeed(Seed);
    Depth := SeededRandomIntRange(2, 8, Seed);
    Seed := StepRandomSeed(Seed);
    StarField.Stars.AddPoint(X, Y, Depth, Colors[RandomIntRange(4, 15)]);
  end;
  for Index := 0 to Round(Count * 0.3) do
  begin
    X := SeededRandomIntRange(-Diameter, Diameter, Seed);
    Seed := StepRandomSeed(Seed);
    Y := SeededRandomIntRange(-Diameter, Diameter, Seed);
    Seed := StepRandomSeed(Seed);
    Depth := SeededRandomIntRange(1, 100, Seed) / 100.0 + 1.0;
    Seed := StepRandomSeed(Seed);
    StarField.Stars.AddPoint(X, Y, Depth, Colors[RandomIntRange(4, 15)]);
  end;
  for Index := 0 to Round(Count * 0.1) do
  begin
    X := SeededRandomIntRange(-Radius, Radius, Seed);
    Seed := StepRandomSeed(Seed);
    Y := SeededRandomIntRange(-Radius, Radius, Seed);
    Seed := StepRandomSeed(Seed);
    Depth := 1.1;
    StarField.Stars.AddPoint(X, Y, Depth, Colors[RandomIntRange(4, 15)]);
  end;
  StarField.MarkViewDirty;
  StarField.Invalidate;
  System.RandSeed := PlayerStar.GenerationSeed;
  Count := Round(RemapClamped(Scale, 1.0, 2.0, 1.0, 2.0));
  if (GlobalsV.SpaceImage = 1) and (Count > 1) then Count := 1;
  SpaceImage.ClearImages;
  if GlobalsV.SpaceImage > 0 then
  begin
    Kind := SeededRandomIntRange(0, 5, Seed);
    for Index := 1 to Count do
    begin
      Attempts := 0;
      repeat
        X := SeededRandomIntRange(-Diameter, Diameter, Seed);
        Seed := StepRandomSeed(Seed);
        Y := SeededRandomIntRange(-Diameter, Diameter, Seed);
        Seed := StepRandomSeed(Seed);
        Depth := RandomFloatRange(5.5, 6.0) * 1.1 + RemapClamped(Radius, 2500.0, 4000.0, 0.0, 3.0);
        Seed := StepRandomSeed(Seed);
        Inc(Attempts);
      until (SpaceImage.NearestImageDistance(X, Y) > RemapClamped(Radius, 2500.0, 4000.0, 3000.0, 6000.0)) or (Attempts > 100);
      if Attempts > 100 then Break;
      SpaceImage.AddImage(SelectSpaceImageTemplate(Kind), X, Y, Depth);
      IncrementWrapped(Kind, 0, 5);
      Seed := StepRandomSeed(Seed);
    end;
    if High(Galaxy.SpaceBackgroundEntries) + 1 <= 0 then Galaxy.GenerateSpaceBackground;
    for Index := 0 to High(Galaxy.SpaceBackgroundEntries) do
    begin
      Image := SpaceImage.AddImage(Galaxy.SpaceBackgroundEntries[Index].ImageIndex,
        Galaxy.SpaceBackgroundEntries[Index].Position.X, Galaxy.SpaceBackgroundEntries[Index].Position.Y, Galaxy.SpaceBackgroundEntries[Index].Position.Z);
      Image.OrbitCenter := Galaxy.SpaceBackgroundEntries[Index].OrbitCenter;
      Image.OrbitStepDegrees := Galaxy.SpaceBackgroundEntries[Index].OrbitStepDegrees;
      Image.Unknown70 := Galaxy.SpaceBackgroundEntries[Index].ImageIndex;
      Image.FrameIndex := Galaxy.SpaceBackgroundEntries[Index].FrameIndex;
      SpaceImage.UpdateImageOrbitAndFrame(Image);
    end;
    SpaceImage.AnimateImages(0, 0);
    SpaceImage.ProjectImages;
    SpaceImage.Invalidate;
  end;
  StarField.SetBackgroundImage(PlayerStar.SelectBackground(X));
  StarField.BackgroundScale := Diameter * 3 / X;
end;
{ @end $5667DC }

{ @routine $566F8C TfStarMap_SaveSpaceImageState }
procedure TfStarMap.SaveSpaceImageState(SpaceImage: TSpaceImgGI);
var
  Index, SavedCount: Integer;
  Image: PSpaceImageGI;
begin
  SetLength(Galaxy.SpaceBackgroundEntries, SpaceImage.ImageCount);
  SavedCount := 0;
  for Index := 0 to SpaceImage.ImageCount - 1 do
  begin
    Image := SpaceImage.GetImage(Index);
    if Image.TemplateIndex >= 100 then
    begin
      Galaxy.SpaceBackgroundEntries[SavedCount].ImageIndex := Image.Unknown70;
      Galaxy.SpaceBackgroundEntries[SavedCount].OrbitCenter := Image.OrbitCenter;
      Galaxy.SpaceBackgroundEntries[SavedCount].Position := MakeVector3D(Image.X, Image.Y, Image.Depth);
      Galaxy.SpaceBackgroundEntries[SavedCount].Unknown38 := Image.Unknown38;
      Galaxy.SpaceBackgroundEntries[SavedCount].OrbitStepDegrees := Image.OrbitStepDegrees;
      Galaxy.SpaceBackgroundEntries[SavedCount].FrameIndex := Image.FrameIndex;
      Inc(SavedCount);
    end;
  end;
  SetLength(Galaxy.SpaceBackgroundEntries, SavedCount);
end;
{ @end $566F8C }

{ @routine $5670F8 TfStarMap_SaveSpaceBackground }
procedure TfStarMap.SaveSpaceBackground;
begin
  SaveSpaceImageState(GetByName('SpaceImg') as TSpaceImgGI);
end;
{ @end $5670F8 }

{ @routine $567138 TfStarMap_EndTurnClicked }
procedure TfStarMap.EndTurnClicked(Sender: TObjectGI);
var
  WaitResult: Cardinal;
  Events: array[0..1] of THandle;
  EventList: Pointer;
begin
  if not IsTurnCalculationRunningUI and (TurnCalculationPhase <> 1) and (TurnCalculationPhase <> 3) then
  begin
    PreviousFilmActivity := 0;
    SoundManager.PlaySound('Sound.Turn');
    PruneExpiredPersistentPlayerMessages;
    if AutoSave then begin
      SaveManagerReturnScreenId := FormToId(Self);
      SaveGameToFile(SaveManagerScreen.GetSaveSlotPath(10), 'as');
    end;
    ClearPathOverlay(True);
    ClearPathOverlay(False);
    StopOrderMode;
    BreakOnNextFilm := IsVirtualKeyDown(VK_SHIFT);
    PlayerAutomaticControl := False;
    FilmCameraFollow := True;
    if not PlayerStarDayPrepared then raise Exception.Create('Not calc NextDay header');
    Player.NextDay;
    QueuePlayerStarTurnCalculation;
    Events[0] := TurnCalculationThread.IdleEvent;
    Events[1] := TalkRequestEvent;
    EventList := @Events;
    WaitResult := WaitForMultipleObjects(Length(Events), EventList, False, INFINITE);
    if (TurnCalculationThread.IdleEvent = 0) or (WaitResult = WAIT_OBJECT_0) then
    begin
      if (Player <> nil) and not Player.InHyperspace then QueueGalaxyTurnCalculation;
      StartTurnFilm;
    end
    else if WaitResult = WAIT_FAILED then
      raise Exception.Create('Error GetLastError()=' + IntToStr(Int64(GetLastError)))
    else if WaitResult = WAIT_OBJECT_0 + 1 then
    begin
      PrepareTalkDisplay;
      TalkReturnScreenId := FormToId(Self);
      RequestedScreenId := screenTalk;
      RequestClose(1);
    end;
  end;
end;
{ @end $567138 }

{ @routine $56739C TfStarMap_MapKeyDown }
procedure TfStarMap.MapKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_MENU) then Exit;
  if (Mode = 1) and not IsTurnCalculationRunningUI then begin
    if Key = VK_F2 then begin
      CaptureSavePreview;
      ResumeMode := 1;
      SaveManagerReturnScreenId := FormToId(Self);
      SaveManagerMode := smmSave;
      RequestedScreenId := screenSaveManager;
      RequestClose(1);
    end else if Key = VK_F3 then begin
      ResumeMode := 1;
      SaveManagerReturnScreenId := FormToId(Self);
      SaveManagerMode := smmLoad;
      RequestedScreenId := screenSaveManager;
      RequestClose(1);
    end;
  end;
  if Key = VK_LEFT then begin
    ScrollLeftHeld := True;
    if Mode = 1 then ShowObjectInfo(nil);
  end else if Key = VK_RIGHT then begin
    ScrollRightHeld := True;
    if Mode = 1 then ShowObjectInfo(nil);
  end else if Key = VK_UP then begin
    ScrollUpHeld := True;
    if Mode = 1 then ShowObjectInfo(nil);
  end else if Key = VK_DOWN then begin
    ScrollDownHeld := True;
    if Mode = 1 then ShowObjectInfo(nil);
  end else if Key = Ord('C') then begin
    if Mode = 1 then CenterOnPlayer(nil)
    else CenterFilmShipClicked(nil);
  end else if (Mode = 1) and (Key = VK_SPACE) then EndTurnClicked(nil)
  else if (Mode = 2) and (Key = VK_SPACE) then
    if not (GetByName('PM_Break') as TGraphButtonGI).Disabled then BreakTurnClicked(nil);
end;
{ @end $56739C }

{ @routine $567574 TfStarMap_MapKeyUp }
procedure TfStarMap.MapKeyUp(Sender: TObjectGI; Key: Cardinal);
begin
  if Mode = 1 then DisplayedObject := nil;
  if Key = VK_LEFT then ScrollLeftHeld := False
  else if Key = VK_RIGHT then ScrollRightHeld := False
  else if Key = VK_UP then ScrollUpHeld := False
  else if Key = VK_DOWN then ScrollDownHeld := False;
end;
{ @end $567574 }

{ @routine $5675BC TfStarMap_OpenFilmHistoryClicked }
procedure TfStarMap.OpenFilmHistoryClicked(Sender: TObjectGI);
begin
  if IsTurnCalculationRunningUI then Exit;
  RequestedScreenId := screenFilm;
  RequestClose(1);
end;
{ @end $5675BC }

{ @routine $5675E0 TfStarMap_BuildShipPathOverlay }
procedure TfStarMap.BuildShipPathOverlay(Ship: TShip);
var
  LabelGI: TLabelGI;
  Point, TargetPosition: TPointF;
  ImageSize: TPoint;
  Cursor, Node, LastNode: PSPathNode;
  Owner: TObjectGI;
  EndImage: TgaiGI;
  TargetShip, OtherShip: TShip;
  Distance, Angle, AngleOffset, Radius: Single;
  Index, Count, LandingTurns: Integer;
  EndPosition: TPoint;
  PathImages: TMultiImageGI;
  UnitImage: TMultiImageUnitGI;
  Positions: PPointF;
  WritePosition: PSingle;
begin
  Owner := MapControls;
  LandingTurns := -1;
  if (Ship.Order = soFollowShip) or ((Ship = Player) and (PendingPlayerFollowTarget <> nil)) then
  begin
    if (Ship = Player) and (PendingPlayerFollowTarget <> nil) then TargetShip := PendingPlayerFollowTarget
    else TargetShip := Ship.OrderTarget as TShip;
    if TargetShip.IsOnPlanet then TargetPosition := TargetShip.CurrentPlanet.GetPosition
    else TargetPosition := TargetShip.Position;
    Distance := PointDistance(Ship.Position, TargetShip.Position);
    AngleOffset := 0;
    Count := 0;
    while Count < 4 do
    begin
      Inc(Count);
      Radius := TargetShip.Graphic.Size.X / 2 + 20;
      if Distance < 1 then
      begin
        Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 259, Ship.Seed * TargetShip.Seed)) + AngleOffset;
        Point.X := TargetPosition.X + Sin(Angle) * Radius;
        Point.Y := TargetPosition.Y - Cos(Angle) * Radius;
      end
      else
      begin
        Angle := ArcTan2(Ship.Position.X - TargetPosition.X, -(Ship.Position.Y - TargetPosition.Y)) + AngleOffset;
        Point.X := TargetPosition.X + Sin(Angle) * Radius;
        Point.Y := TargetPosition.Y - Cos(Angle) * Radius;
      end;
      Index := 0;
      while Index < Ship.CurrentStar.Ships.Count do
      begin
        OtherShip := TShip(Ship.CurrentStar.Ships[Index]);
        if OtherShip.InNormalSpace and (PointDistanceSquared(Point, OtherShip.Position) < 900) then Break;
        Inc(Index);
      end;
      AngleOffset := AngleOffset + 1.5707963;
      if Index >= Ship.CurrentStar.Ships.Count then Break;
    end;
    Ship.OrderDestination := Point;
    Ship.ClearMovementPath;
    Ship.BuildFullPathTo(Ship.OrderDestination);
  end
  else if Ship.Order = soLanding then
  begin
    Ship.ClearMovementPath;
    if (Ship = Player) and (Ship.Order = soLanding) and (Ship.OrderTarget is TPlanet) then
    begin
      Ship.BuildPlanetLandingPath;
      LandingTurns := Ship.GetMovementPathTurnCount;
      Ship.BuildFullPathTo(AddPointsF((Ship.OrderTarget as TPlanet).GetPosition, Ship.OrderDestination));
    end
    else
    begin
      if Ship.OrderTarget is TShip then
        Ship.BuildFullPathTo(AddPointsF((Ship.OrderTarget as TShip).Position, Ship.OrderDestination))
      else Ship.BuildFullPathTo(AddPointsF((Ship.OrderTarget as TPlanet).GetPosition, Ship.OrderDestination));
    end;
  end
  else if Ship.Order = soEnterBlackHole then
  begin
    Ship.ClearMovementPath;
    Ship.BuildFullPathTo(Ship.OrderDestination);
  end
  else if (Ship <> Player) and (Ship.Order = soJump) then
  begin
    Ship.ClearMovementPath;
    Ship.BuildOrderMovementPath(UnlimitedPathNodes);
  end
  else if (Ship <> Player) and (Ship.Order = soMove) then
  begin
    Ship.ClearMovementPath;
    Ship.BuildFullPathTo(Ship.OrderDestination);
  end;
  if Ship.MovementPath.ActiveHead <> nil then
  begin
    if Ship = Player then PathImages := GetByName('PlayerPath') as TMultiImageGI
    else PathImages := GetByName('ShipPath') as TMultiImageGI;
    if PathImages.Images.Count < 1 then
    begin
      PathImages.AddImage('Bm.PI.Path1');
      PathImages.AddImage('Bm.PI.Path2');
      PathImages.AddImage('Bm.PI.Path3');
      PathImages.AddImage('Bm.PI.Path4');
    end;
    PathImages.ClearUnits;
    Node := Ship.MovementPath.ActiveHead;
    while Node <> nil do
    begin
      LastNode := Ship.MovementPath.GetFollowingNode(Node, 198);
      if LastNode = nil then LastNode := Ship.MovementPath.ActiveTail;
      Point := MakePointF(1e10, 1e10);
      Cursor := LastNode;
      while True do
      begin
        if PointDistanceSquared(Point, Cursor.Position) > 225 then
        begin
          Point := Cursor.Position;
          if Cursor <> Ship.MovementPath.ActiveTail then
          begin
            UnitImage := PathImages.AddUnit;
            PathImages.SetUnitPosition(UnitImage, TruncatePointF(Point));
            if Cursor <> LastNode then
            begin
              if Node = Ship.MovementPath.ActiveHead then UnitImage.ImageIndex := 0
              else UnitImage.ImageIndex := 1;
            end
            else
            begin
              if Node = Ship.MovementPath.ActiveHead then UnitImage.ImageIndex := 2
              else UnitImage.ImageIndex := 2;
            end;
          end;
        end;
        if Cursor = Node then Break;
        Cursor := Cursor.Prev;
      end;
      Node := LastNode.Next;
    end;
    if (Ship.Order = soLanding) and not ((Ship = Player) and (PendingPlayerFollowTarget <> nil)) then
    begin
      if Ship.OrderTarget is TShip then EndPosition := TruncatePointF(AddPointsF((Ship.OrderTarget as TShip).Position, Ship.OrderDestination))
      else EndPosition := TruncatePointF(AddPointsF((Ship.OrderTarget as TPlanet).GetPosition, Ship.OrderDestination));
    end
    else EndPosition := TruncatePointF(Ship.OrderDestination);
    EndImage := TgaiGI.Create(Owner);
    if (PendingPlayerFollowTarget <> nil) and (Ship = Player) then EndImage.SetImagePath('Bm.PI.PathEndAutoBattle')
    else if Ship.Order = soFollowShip then
    begin
      if Ship.GetFollowMode = fmNear then EndImage.SetImagePath('Bm.PI.PathEndFollowNear')
      else if Ship.GetFollowMode = fmMinWeaponRange then EndImage.SetImagePath('Bm.PI.PathEndFollowMin')
      else EndImage.SetImagePath('Bm.PI.PathEndFollowMax');
    end
    else if Ship.Order = soLanding then EndImage.SetImagePath('Bm.PI.PathEndLanding')
    else if Ship.Order = soEnterBlackHole then EndImage.SetImagePath('Bm.PI.PathEndJumpHole')
    else EndImage.SetImagePath('Bm.PI.PathEndMove');
    EndImage.SequenceIndex := 0;
    EndImage.UpdateAutoGeometry;
    if Ship = Player then EndImage.SetDepth(UnitPathEndDepth)
    else EndImage.SetDepth(ShipPathEndDepth);
    EndImage.SetPosition(EndPosition);
    EndImage.SetPositionModeW(True);
    ImageSize := EndImage.GetContentSize;
    EndImage.SetOrigin(HalfPoint(ImageSize));
    EndImage.SetSize(ImageSize);
    EndImage.RestartPlayback;
    LabelGI := TLabelGI.Create(Owner);
    with LabelGI do
    begin
      if Ship = Player then SetDepth(UnitPathEndDepth)
      else SetDepth(ShipPathEndDepth);
      SetFontName(HitPointFontName);
      SetSize(Classes.Point(20, 20));
      SetTextAlignX(taxAuto);
      SetTextAlignY(tayCenterEx);
      if LandingTurns < 0 then SetText(IntToStr(Ship.GetMovementPathTurnCount))
      else SetText(IntToStr(LandingTurns));
      SetPositionModeW(True);
      SetPosition(AddPoints(EndPosition, Classes.Point(ClientSize.X, -ImageSize.Y)));
    end;
    if (Ship <> Player) or (CursorObject = Player) then
    begin
      Count := Ship.MovementPath.NodeCount;
      Positions := AllocEC(Count * SizeOf(TPointF));
      WritePosition := Pointer(Positions);
      Cursor := Ship.MovementPath.ActiveHead;
      while Cursor <> nil do
      begin
        WritePosition^ := Cursor.Position.X;
        WritePosition := Pointer(PAnsiChar(WritePosition) + SizeOf(Single));
        WritePosition^ := Cursor.Position.Y;
        WritePosition := Pointer(PAnsiChar(WritePosition) + SizeOf(Single));
        Cursor := Cursor.Next;
      end;
      SpaceProcess.Space.SetPath(Positions, Count);
      SpaceProcess.Space.DrawMinimap;
      FreeEC(Positions);
      MinimapPathKind := smpShip;
    end;
  end;
end;
{ @end $5675E0 }

{ @routine $5680EC TfStarMap_ClearPathOverlay }
procedure TfStarMap.ClearPathOverlay(PlayerPath: Boolean);
var
  NextControl, Control: TObjectGI;
begin
  with MapControls do NextControl := FirstChild;
  while NextControl <> nil do
  begin
    Control := NextControl;
    NextControl := NextControl.NextSibling;
    if (PlayerPath and (Control.Depth = UnitPathEndDepth)) or
      (not PlayerPath and (Control.Depth = ShipPathEndDepth)) then
    begin
      Control.SetActive(False);
      Control.Free;
    end;
  end;
  if PlayerPath then
    with GetByName('PlayerPath') as TMultiImageGI do ClearUnits
  else
    with GetByName('ShipPath') as TMultiImageGI do ClearUnits;
  if MinimapPathKind = smpShip then
  begin
    SpaceProcess.Space.ClearPath;
    SpaceProcess.Space.DrawMinimap;
    MinimapPathKind := smpNone;
  end;
end;
{ @end $5680EC }

{ @routine $5681E8 TfStarMap_ShowAsteroidPath }
procedure TfStarMap.ShowAsteroidPath(Asteroid: TAsteroid);
var
  Count: Integer;
  Positions, Cursor: Pointer;
  X, Y, NextX, NextY: Single;
  I: Integer;
begin
  if PathAsteroid = Asteroid then Exit;
  ClearAsteroidPath;
  PathAsteroid := Asteroid;
  Count := 400;
  Cursor := AllocEC(Count * SizeOf(TPointF));
  Positions := Cursor;
  Asteroid.WritePredictedPositions(Cursor, Count);
  X := ReadSingleEC(Cursor);
  Cursor := AddPointerOffset(Cursor, SizeOf(Single));
  Y := ReadSingleEC(Cursor);
  Cursor := AddPointerOffset(Cursor, SizeOf(Single));
  for I := 1 to Count - 1 do
  begin
    NextX := ReadSingleEC(Cursor);
    Cursor := AddPointerOffset(Cursor, SizeOf(Single));
    NextY := ReadSingleEC(Cursor);
    Cursor := AddPointerOffset(Cursor, SizeOf(Single));
    if Sqr(X - NextX) + Sqr(Y - NextY) > 144 then
    begin
      X := NextX;
      Y := NextY;
      with TImageGI.Create(MapControls) do
      begin
        SetDepth(UnitPathDepth);
        SetPosition(Classes.Point(Round(NextX), Round(NextY)));
        SetPositionModeW(True);
        if I < 200 then SetImagePath('GI,Bm.PI.Path1')
        else SetImagePath('GI,Bm.PI.Path2');
        SetSize(GetContentSize);
        SetOrigin(HalfPoint(ClientSize));
        UserValue := 101;
      end;
    end;
  end;
  FreeEC(Positions);
  Count := 2400;
  Cursor := AllocEC(Count * SizeOf(TPointF));
  Asteroid.WritePredictedPositions(Cursor, Count);
  SpaceProcess.Space.SetPath(Cursor, Count);
  SpaceProcess.Space.DrawMinimap;
  FreeEC(Cursor);
  MinimapPathKind := smpAsteroid;
end;
{ @end $5681E8 }

{ @routine $568468 TfStarMap_ClearAsteroidPath }
procedure TfStarMap.ClearAsteroidPath;
var
  NextControl, Control: TObjectGI;
begin
  if PathAsteroid <> nil then
  begin
    PathAsteroid := nil;
    if MinimapPathKind = smpAsteroid then
    begin
      SpaceProcess.Space.ClearPath;
      SpaceProcess.Space.DrawMinimap;
      MinimapPathKind := smpNone;
    end;
    NextControl := MapControls.FirstChild;
    while NextControl <> nil do
    begin
      Control := NextControl;
      NextControl := NextControl.NextSibling;
      if Control.UserValue = 101 then
      begin
        Control.SetActive(False);
        Control.Free;
      end;
    end;
  end;
end;
{ @end $568468 }

{ @routine $5684E0 TfStarMap_ClearPartnerButtons }
procedure TfStarMap.ClearPartnerButtons;
begin
  SecondaryPartnerPanel.FreeOwnedChildren;
end;
{ @end $5684E0 }

{ @routine $5684EC TfStarMap_RebuildPartnerButtons }
procedure TfStarMap.RebuildPartnerButtons;
var
  Index: Integer;
  PlacedCount: Cardinal;
  Origin: TPoint;
  Direction: Integer;
  Ship: TRanger;
begin
  ClearPartnerButtons;
  if Player <> nil then
  begin
    Origin := Classes.Point(SecondaryPartnerPanel.ClientSize.X - 17, 5);
    if (-(PlayerStar.ComputeMapDiameter div 6) > Player.Position.Y) and
       (PlayerStar.ComputeMapDiameter div 6 < Player.Position.X) then
    begin
      Origin := Classes.Point(5, SecondaryPartnerPanel.ClientSize.Y - 20);
      Direction := -1;
    end
    else
    begin
      Origin := Classes.Point(SecondaryPartnerPanel.ClientSize.X - 17, 5);
      Direction := 1;
    end;
    PlacedCount := 0;
    for Index := 0 to Galaxy.Rangers.Count - 1 do
    begin
      Ship := Galaxy.Rangers[Index];
      if (Ship.PartnerShip = Player) and (Ship.OwnerId in CoalitionOwners) then
        with TGraphButtonGI.Create(SecondaryPartnerPanel) do
        begin
          SetKind(gbkDisable);
          SetImageNormalPath('GI,Bm.PSPartner.' + OwnerInfo[Ship.OwnerId].InternalName + 'N');
          SetImageNormalActivePath('GI,Bm.PSPartner.' + OwnerInfo[Ship.OwnerId].InternalName + 'A');
          SetImageDownPath('GI,Bm.PSPartner.' + OwnerInfo[Ship.OwnerId].InternalName + 'N');
          SetImageDisabledPath('GI,Bm.PSPartner.' + OwnerInfo[Ship.OwnerId].InternalName + 'D');
          UserValue := Ship.Id;
          HitKind := gbhRect;
          SetSize(GetMaxStateImageSize);
          if (PlacedCount and 1) = 0 then
            SetPosition(Classes.Point(Origin.X - 15 * Direction * (PlacedCount shr 1), Origin.Y))
          else
            SetPosition(Classes.Point(Origin.X, Origin.Y + 15 * Direction * ((PlacedCount shr 1) + 1)));
          UpdateStateImagePlacement;
          UpdateStateVisuals;
          DownCallback := PartnerClicked;
          RightButtonDownCallback := PartnerRightButtonDown;
          MouseEnterCallback := PartnerMouseEnter;
          MouseLeaveCallback := CenterShipMouseLeave;
          SetDisabled(Ship.InHyperspace or (Ship.CurrentStar <> Player.CurrentStar));
          HelpCallback := PanelController.ShowControlHelp;
          HelpText := Ship.GetFullName(' ');
          Inc(PlacedCount);
        end;
    end;
  end;
end;
{ @end $5684EC }

{ @routine $5688EC TfStarMap_PartnerClicked }
procedure TfStarMap.PartnerClicked(Sender: TObjectGI);
var Ship: TShip; FilmObject: TEFilmObj; Instance: TObject;
begin
  if Mode = 2 then
  begin
    FilmObject := SecondaryFilm.FindObjectById('Ship2', Sender.UserValue);
    if (FilmObject = nil) or (FilmObject.SceneObject = nil) then Exit;
    SetMapCenterManually(TruncatePointF(FilmObject.SceneObject.Position));
  end
  else
  begin
    Instance := Galaxy.IdToShip(Sender.UserValue, False);
    if Instance = nil then Exit;
    Ship := Instance as TShip;
    if (Player.CurrentStar <> Ship.CurrentStar) or Ship.InHyperspace then Exit;
    if Ship.InNormalSpace then SetMapCenterManually(TruncatePointF(Ship.Position))
    else if Ship.IsOnPlanet then SetMapCenterManually(TruncatePointF(Ship.CurrentPlanet.GetPosition))
    else if Ship.IsDockedToShip then SetMapCenterManually(TruncatePointF(Ship.DockedTo.Position))
    else Exit;
  end;
  AddMapAnimation(PointToPointF(GetMapCenter), 'Bm.SI.' + GiResourceSuffix + 'Ring', 0);
  AddMapAnimation(PointToPointF(GetMapCenter), 'Bm.SI.' + GiResourceSuffix + 'Ring', 200);
  AddMapAnimation(PointToPointF(GetMapCenter), 'Bm.SI.' + GiResourceSuffix + 'Ring', 400);
end;
{ @end $5688EC }

{ @routine $568B5C TfStarMap_PartnerRightButtonDown }
procedure TfStarMap.PartnerRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Ship: TShip;
  Obj: TObject;
  Distance: Double;
  PlayerPosition: PPointF;
begin
  if Mode = 1 then
  begin
    Obj := Galaxy.IdToShip(Sender.UserValue, False);
    if Obj <> nil then
    begin
      Ship := Obj as TShip;
      if (Player.CurrentStar = Ship.CurrentStar) and Ship.InNormalSpace then
      begin
        PlayerPosition := @Player.Position;
        Distance := PointDistance(PlayerPosition^, Ship.Position);
        if Distance <= Player.GetRadarRange then
        begin
          SoundManager.PlaySound('Sound.Talk');
          TalkShip := Ship;
          TalkScripted := False;
          PrepareTalkDisplay;
          TalkReturnScreenId := FormToId(Self);
          RequestedScreenId := screenTalk;
          RequestClose(1);
        end;
      end;
    end;
  end;
end;
{ @end $568B5C }

{ @routine $568C68 TfStarMap_PartnerMouseEnter }
procedure TfStarMap.PartnerMouseEnter(Sender: TObjectGI);
var
  Obj, Instance: TObject;
begin
  if Mode = 1 then
  begin
    Instance := Galaxy.IdToShip(Sender.UserValue, False);
    if Instance <> nil then
    begin
      Obj := Instance as TShip;
      ShowObjectInfo(Obj);
    end;
  end;
end;
{ @end $568C68 }

{ @routine $568CA8 TfStarMap_CenterShipMouseLeave }
procedure TfStarMap.CenterShipMouseLeave(Sender: TObjectGI);
begin
  ShowObjectInfo(nil);
end;
{ @end $568CA8 }

{ @routine $568CB0 TfStarMap_AddMapAnimation }
procedure TfStarMap.AddMapAnimation(Position: TPointF; ImagePath: WideString; DelayMs: Integer);
begin
  with TgaiGI.Create(MapControls) do
  begin
    SetDepthByName('IAnim');
    SetPosition(TruncatePointF(Position));
    SetPositionModeW(True);
    SetImagePath(ImagePath);
    SetSize(GetContentSize);
    SetOrigin(HalfPoint(ClientSize));
    UserValue := 102;
    SequenceIndex := 0;
    UpdateAutoGeometry;
    if DelayMs >= 0 then SetFrameDelay(0, DelayMs);
    CycleCompleteCallback := Self.MapAnimationFinished;
    RestartPlayback;
  end;
end;
{ @end $568CB0 }

{ @routine $568DC8 TfStarMap_ClearMapAnimations }
procedure TfStarMap.ClearMapAnimations;
var
  NextControl, Control: TObjectGI;
begin
  NextControl := MapControls.FirstChild;
  while NextControl <> nil do
  begin
    Control := NextControl;
    NextControl := NextControl.NextSibling;
    if Control.UserValue = 102 then
    begin
      Control.SetActive(False);
      Control.Free;
    end;
  end;
end;
{ @end $568DC8 }

{ @routine $568DFC TfStarMap_MapAnimationFinished }
procedure TfStarMap.MapAnimationFinished(Sender: TObjectGI);
begin
  Sender.SetActive(False);
  Sender.Free;
end;
{ @end $568DFC }

{ @routine $568E14 TfStarMap_FindObjectAtCursor }
function TfStarMap.FindObjectAtCursor: TObject;
var
  Index, Count: Integer;
  Ship: TShip;
  Item: TItem;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Point: TPoint;
  Hole: THole;
  Graphic: TObjectSE;
begin
  if PanelController.BackgroundImage.HitTestPixel(GetCursorPoint) then begin
    Result := nil;
    Exit;
  end;
  Point := MapControls.ToLocalPoint(GetCursorPoint);
  Count := PlayerStar.Ships.Count;
  for Index := 0 to Count - 1 do begin
    Ship := PlayerStar.Ships[Index];
    if not (Ship is TRuins) then begin
      Graphic := Ship.Graphic;
      if (Graphic <> nil) and Graphic.HitTestCursor then begin
        Result := Ship;
        Exit;
      end;
    end;
  end;
  Count := PlayerStar.Items.Count;
  for Index := 0 to Count - 1 do begin
    Item := PlayerStar.Items[Index];
    if Item.GetGraphObject.HitTestCursor then begin
      Result := Item;
      Exit;
    end;
  end;
  Count := PlayerStar.Ships.Count;
  for Index := 0 to Count - 1 do begin
    Ship := PlayerStar.Ships[Index];
    if Ship is TRuins then begin
      Graphic := Ship.Graphic;
      if (Graphic <> nil) and Graphic.HitTestCursor then begin
        Result := Ship;
        Exit;
      end;
    end;
  end;
  Count := PlayerStar.Asteroids.Count;
  for Index := 0 to Count - 1 do begin
    Asteroid := PlayerStar.Asteroids[Index];
    if (Asteroid.GraphObject <> nil) and Asteroid.GraphObject.HitTestCursor then begin
      Result := Asteroid;
      Exit;
    end;
  end;
  Count := PlayerStar.Planets.Count;
  for Index := 0 to Count - 1 do begin
    Planet := PlayerStar.Planets[Index];
    if Sqr(Point.X - Planet.GetPosition.X) + Sqr(Point.Y - Planet.GetPosition.Y) < Sqr(Planet.GraphicRadius) then begin
      Result := Planet;
      Exit;
    end;
  end;
  if Point.X * Point.X + Point.Y * Point.Y < Sqr(PlayerStar.Radius) then begin
    Result := PlayerStar;
    Exit;
  end;
  for Index := 0 to Galaxy.Holes.Count - 1 do begin
    Hole := Galaxy.Holes[Index];
    if ((Hole.Star1 = PlayerStar) or (Hole.Star2 = PlayerStar)) then begin
      Graphic := Hole.Graphic;
      if (Graphic <> nil) and Graphic.HitTestCursor then begin
        Result := Hole;
        Exit;
      end;
    end;
  end;
  Result := nil;
end;
{ @end $568E14 }

{ @routine $5690BC TfStarMap_QueueInterfaceImages }
procedure TfStarMap.QueueInterfaceImages;
var Loads: TList;
begin
  if not CacheLoader.IsRunning then
  begin
    Loads := TList.Create;
    QueueHyperspaceLoadingAssets(Loads, RootUiObject);
    if Loads.Count > 0 then CacheLoader.SetPendingLoads(Loads, True)
    else Loads.Free;
  end;
end;
{ @end $5690BC }

{ @routine $56910C TfStarMap_RedrawMap }
procedure TfStarMap.RedrawMap;
begin
  UpdateRectsEnabled := True;
  MapControls.InvalidateChildren(False);
  CursorControl.Invalidate;
  UpdateRectsEnabled := False;
  InvalidateTransientControl;
end;
{ @end $56910C }

{ @routine $569138 TfStarMap_DrawFrame }
procedure TfStarMap.DrawFrame;
var RectNode: TRectGR;
begin
  if (MinimapFrameCounter mod 16 = 0) and (Mode = 2) then SpaceProcess.Space.DrawMinimap;
  Inc(MinimapFrameCounter);
  RedrawMap;
  StarField.UpdateBackgroundBounds;
  if SkipSavedPixelRestore or FullFrameRedrawRequested then begin
    UpdateRects.Clear;
    UpdateRectsEnabled := True;
    InvalidateViewport;
    UpdateRectsEnabled := False;
  end;
  FullFrameRedrawRequested := False;
  RestoreSavedPixels16;
  RestoreSavedLines;
  ErasePreviousFrame;
  RectNode := UpdateRects.FirstRect;
  while RectNode <> nil do begin
    StarField.DrawBackground(RectNode.Bounds);
    RectNode := RectNode.Next;
  end;
  PrepareFrameDraw;
  DrawQueuedControlRects;
  if not ShipScreen.SkipOpeningSlide then begin
    if not BeginFramePresentation then begin
      RequestedScreenId := screenNone;
      RestartScreenId := FormToId(Self);
      RequestClose(1);
      Exit;
    end;
    FinishQueuedDraw;
    CommitFrameDraw;
    ResetSavedLineCount;
    ResetSecondaryPixelCount;
    EndFramePresentation;
  end;
  RedrawMap;
end;
{ @end $569138 }

{ @routine $569264 TfStarMap_GalaxyClicked }
procedure TfStarMap.GalaxyClicked(Sender: TObjectGI);
begin
  SetCursorActive(False);
  Present;
  CaptureScreenBackground;
  SetCursorActive(True);
  GalaxyMapScreen.ViewMode := 2;
  GalaxyReturnScreenId := FormToId(Self);
  RequestedScreenId := screenGalaxy;
  RequestClose(1);
end;
{ @end $569264 }

{ @routine $5692B8 TfStarMap_ShipClicked }
procedure TfStarMap.ShipClicked(Sender: TObjectGI);
begin
  ClearPathOverlay(True);
  BuildShipPathOverlay(Player);
  SetCursorActive(False);
  Present;
  CaptureScreenBackground;
  SetCursorActive(True);
  ShipScreen.PlayTransitionSounds := True;
  ShipReturnScreenId := FormToId(Self);
  RequestedScreenId := screenShip;
  RequestClose(1);
end;
{ @end $5692B8 }

{ @routine $569324 TfStarMap_StartOrderMode }
procedure TfStarMap.StartOrderMode;
var Index: Integer; Item: TItem; Range: Single;
begin
  ScrollLeftHeld := False;
  ScrollRightHeld := False;
  ScrollUpHeld := False;
  ScrollDownHeld := False;
  ShowPlayerTipOnce(2);
  if HasShownPlayerTip(1) then ShowPlayerTipOnce(3);
  if HasShownPlayerTip(3) and not HasShownPlayerTip(4) then begin
    Range := Player.GetMaxWeaponRange;
    if Range <= 0 then Range := 200;
    for Index := 0 to PlayerStar.Items.Count - 1 do begin
      Item := PlayerStar.Items[Index];
      if (Item is TUselessItem) and (TUselessItem(Item).ConfigBlockName = 'ExampleAsteroid') and
        (PointDistanceSquared(Player.Position, Item.Position) < Range * Range) then begin
        ShowPlayerTipOnce(4);
        Break;
      end;
    end;
  end;
  if HasShownPlayerTip(4) and not HasShownPlayerTip(5) then begin
    Index := 0;
    while Index < PlayerStar.Items.Count do begin
      Item := PlayerStar.Items[Index];
      if (Item is TUselessItem) and (TUselessItem(Item).ConfigBlockName = 'ExampleAsteroid') then Break;
      Inc(Index);
    end;
    if Index >= PlayerStar.Items.Count then begin
      ShowPlayerTipOnce(5);
      ShowPlayerTipOnce(6);
    end;
  end;
  if HasShownPlayerTip(5) and not HasShownPlayerTip(7) and (Player.CargoGoods[t_Minerals].Count > 0) then begin
    ShowPlayerTipOnce(7);
    ShowPlayerTipOnce(8);
  end;
  MinimapFrameCounter := 0;
  ScannerSelectionActive := False;
  TalkSelectionActive := False;
  for Index := 0 to 4 do SelectedWeapons[Index] := False;
  DisplayedObject := nil;
  CursorObject := nil;
  UpdateRectsEnabled := True;
  MapControls.Invalidate;
  UpdateRectsEnabled := False;
  Player.BuildOrderMovementPath(UnlimitedPathNodes);
  CenterShipButton.DownCallback := CenterOnPlayer;
  SpaceEffectsTimer := ScheduleCallbackTimer(18, 18, AdvanceSpaceEffects);
  InfoWindow.SetActive(False);
  ItemInfoWindow.SetActive(False);
  ShipInfoPanel.SetActive(False);
  PlanetInfoPanel.SetActive(False);
  StarInfoWindow.SetActive(False);
  StandardInfoPanel.SetActive(False);
  SpaceProcess.Space.ScrollChangedCallback := MapScrollChanged;
  GetByName('PanelSpace').SetActive(True);
  PanelController.Show;
  GetByName('PS_Up').SetActive(StarMapWeaponPanelOpen);
  MapControls.LeftButtonDownCallback := MapLeftButtonDown;
  MapControls.LeftButtonDoubleClickCallback := MapLeftButtonDown;
  MapControls.RightButtonDownCallback := MapRightButtonDown;
  MapControls.MouseMoveCallback := MapMouseMove;
  ContentPanel.KeyDownCallback := OrderKeyDown;
  ContentPanel.KeyUpCallback := OrderKeyUp;
  BuildShipPathOverlay(Player);
  SpaceProcess.Space.DrawMinimap;
  RebuildTargetMarkers;
  RefreshActionRanges;
  RefreshWeaponButtons;
  PanelController.RebuildMessageButtons;
  Mode := 1;
  RebuildPartnerButtons;
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive then EndTurnClicked(nil);
  PostMouseMoveMessage;
end;
{ @end $569324 }

{ @routine $569750 TfStarMap_StopOrderMode }
procedure TfStarMap.StopOrderMode;
var I: Integer;
begin
  Mode := 0;
  CenterShipButton.DownCallback := nil;
  CursorObject := nil;
  ScannerSelectionActive := False;
  TalkSelectionActive := False;
  for I := 0 to 4 do SelectedWeapons[I] := False;
  RefreshActionRanges;
  HideActionRanges;
  PanelController.ClearMessageButtons;
  HideOrderInterface;
  SpaceProcess.Space.ScrollChangedCallback := nil;
  MapControls.LeftButtonDownCallback := nil;
  MapControls.LeftButtonDoubleClickCallback := nil;
  MapControls.RightButtonDownCallback := nil;
  MapControls.MouseMoveCallback := nil;
  ContentPanel.KeyDownCallback := nil;
  ContentPanel.KeyUpCallback := nil;
  if SpaceEffectsTimer <> 0 then begin
    CancelCallbackTimer(SpaceEffectsTimer);
    SpaceEffectsTimer := 0;
  end;
end;
{ @end $569750 }

{ @routine $569840 TfStarMap_HideOrderInterface }
procedure TfStarMap.HideOrderInterface;
begin
  HideWeaponImages;
  ClearAsteroidPath;
  ClearTargetMarkers;
  ClearMapAnimations;
  ClearPathOverlay(True);
  ClearPathOverlay(False);
  PanelController.ClearMessageButtons;
  InfoWindow.SetActive(False);
  ItemInfoWindow.SetActive(False);
  ShipInfoPanel.SetActive(False);
  PlanetInfoPanel.SetActive(False);
  StarInfoWindow.SetActive(False);
  StandardInfoPanel.SetActive(False);
  PanelController.Hide;
  GetByName('PanelSpace').SetActive(False);
end;
{ @end $569840 }

{ @routine $569908 TfStarMap_ScrollTimerTick }
procedure TfStarMap.ScrollTimerTick(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Point, OldPoint: TPoint;
begin
  if DemoPlaying or DemoRecording then Exit;
  OldPoint := GetMapCenter;
  Point := OldPoint;
  if ScrollLeftHeld then Dec(Point.X, ScrollSpeed);
  if ScrollRightHeld then Inc(Point.X, ScrollSpeed);
  if ScrollUpHeld then Dec(Point.Y, ScrollSpeed);
  if ScrollDownHeld then Inc(Point.Y, ScrollSpeed);
  if GetCursorPoint.X = 0 then Dec(Point.X, ScrollSpeed);
  if GetCursorPoint.X = GameScreenWidth - 1 then Inc(Point.X, ScrollSpeed);
  if GetCursorPoint.Y = 0 then Dec(Point.Y, ScrollSpeed);
  if GetCursorPoint.Y = GameScreenHeight - 1 then Inc(Point.Y, ScrollSpeed);
  if (OldPoint.X <> Point.X) or (OldPoint.Y <> Point.Y) then SetMapCenterManually(Point);
end;
{ @end $569908 }
{ @routine $569A3C TfStarMap_AdvanceSpaceEffects }
procedure TfStarMap.AdvanceSpaceEffects(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if TrailingFilmEffects <> nil then begin
    TrailingFilmEffects.AdvanceEffects;
    if TrailingFilmEffects.FirstEntry = nil then begin
      TrailingFilmEffects.Free;
      TrailingFilmEffects := nil;
    end;
  end;
  SpaceProcess.Space.AdvanceTimers;
  SpaceProcess.Space.AdvanceObjects;
end;
{ @end $569A3C }

{ @routine $569A94 TfStarMap_MapLeftButtonDown }
procedure TfStarMap.MapLeftButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  MapControl: TPanelGI;
  Destination: TPointF;
  Ship: TShip;
  Location: TObject;
  Hole: THole;
  I: Integer;
  HadWeapons: Boolean;
  Weapon: TWeapon;
  FollowTarget: TShip;
begin
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive or
    Sender.IsOccludedAtPoint(Point) or PanelController.BackgroundImage.HitTestPixel(Point) or
    WeaponButtons[0].HitTest(Point) or WeaponButtons[1].HitTest(Point) or
    WeaponButtons[2].HitTest(Point) or WeaponButtons[3].HitTest(Point) or
    WeaponButtons[4].HitTest(Point) or AllWeaponsButton.HitTest(Point) or
    HideWeaponPanelButton.HitTest(Point) or ScannerButton.HitTest(Point) or
    TalkButton.HitTest(Point) or TurnFilmButton.HitTest(Point) or
    PanelController.ShipButton.HitTest(Point) or PanelController.GalaxyButton.HitTest(Point) or
    PanelController.QuestButton.HitTest(Point) then Exit;
  CursorObject := FindObjectAtCursor;
  HadWeapons := False;
  for I := 0 to 4 do
    if SelectedWeapons[I] then begin
      HadWeapons := True;
      Break;
    end;
  MapControl := MapControls;
  Destination := PointToPointF(MapControl.ToLocalPoint(Point));
  if (ScannerSelectionActive or TalkSelectionActive) and not (CursorObject is TShip) then begin
    ScannerSelectionActive := False;
    TalkSelectionActive := False;
    RefreshActionRanges;
    RefreshWeaponButtons;
    UpdateActionCursor;
    Exit;
  end;
  if (Player.CalculateSpeed <= 0) and not HadWeapons and not ScannerSelectionActive and
    not TalkSelectionActive and not (CursorObject is TItem) then begin
    SetCursorActive(False);
    DrawFrame;
    SetCursorActive(True);
    ShowMessageBoxGI(Self, LocalizedColorText('Help.Speed0'), mbgCancel, 0);
    FullFrameRedrawRequested := True;
    DrawFrame;
    Exit;
  end;
  if CursorObject = nil then begin
    ClearPathOverlay(True);
    PendingPlayerFollowTarget := nil;
    Player.OrderMove(Destination, False);
    Player.BuildOrderMovementPath(UnlimitedPathNodes);
    BuildShipPathOverlay(Player);
  end
  else if CursorObject is TPlanet then begin
    Location := CursorObject as TPlanet;
    ClearPathOverlay(True);
    PendingPlayerFollowTarget := nil;
    if ((Player.Order <> soLanding) or (Location <> Player.OrderTarget)) and
      ((CursorObject as TPlanet).OwnerId <> oiKling) then begin
      Player.OrderLanding(Location, False);
      Player.OrderDestination := SubtractPointsF(Destination, TPlanet(Location).GetPosition);
    end else begin
      Player.OrderMove(Destination, False);
      Player.BuildOrderMovementPath(UnlimitedPathNodes);
    end;
    BuildShipPathOverlay(Player);
  end
  else if CursorObject is THole then begin
    Hole := CursorObject as THole;
    ClearPathOverlay(True);
    PendingPlayerFollowTarget := nil;
    if (Player.Order <> soEnterBlackHole) or (Hole <> Player.OrderTarget) then begin
      if Hole.Star1 = Hole.Star2 then
        Player.OrderEnterBlackHole(Hole,
          Single(PointDistanceSquared(Player.OrderDestination, Hole.Position1)) <
          PointDistanceSquared(Player.OrderDestination, Hole.Position2), False)
      else if Hole.Star1 = Player.CurrentStar then Player.OrderEnterBlackHole(Hole, True, False)
      else Player.OrderEnterBlackHole(Hole, False, False);
      Player.OrderDestination := Destination;
      Player.BuildOrderMovementPath(UnlimitedPathNodes);
    end else begin
      Player.OrderMove(Destination, False);
      Player.BuildOrderMovementPath(UnlimitedPathNodes);
    end;
    BuildShipPathOverlay(Player);
  end
  else if CursorObject is TRuins then begin
    Ship := CursorObject as TShip;
    ClearPathOverlay(True);
    PendingPlayerFollowTarget := nil;
    if (Player.Order <> soLanding) or (Ship <> Player.OrderTarget) then begin
      Player.OrderLanding(Ship, False);
      Player.OrderDestination := SubtractPointsF(Destination, Ship.Position);
    end else begin
      Player.OrderMove(Destination, False);
      Player.BuildOrderMovementPath(UnlimitedPathNodes);
    end;
    BuildShipPathOverlay(Player);
  end
  else if CursorObject is TShip then begin
    if ScannerSelectionActive then begin
      if (PointDistance(Player.Position, (CursorObject as TShip).Position) <= Player.GetRadarRange) and
        (Player <> CursorObject) and not (CursorObject is TRuins) and not (CursorObject is TKling) and
        Player.CanResolveObjectWithScanner(CursorObject) then begin
        SoundManager.PlaySound('Sound.Scan');
        SetCursorActive(False);
        Present;
        CaptureScreenBackground;
        SetCursorActive(True);
        ScannerTarget := CursorObject;
        ScannerReturnScreenId := FormToId(Self);
        RequestedScreenId := screenScanner;
        RequestClose(1);
      end;
    end
    else if TalkSelectionActive then begin
      if (PointDistance(Player.Position, (CursorObject as TShip).Position) <= Player.GetRadarRange) and
        (Player <> CursorObject) then
        if not (CursorObject is TKling) or (((CursorObject as TKling).KlingType = ktMakhpella) and
          Player.HaveCommunicator and ((CursorObject as TKling).ScriptShip <> nil)) then begin
          SoundManager.PlaySound('Sound.Talk');
          TalkShip := CursorObject as TShip;
          TalkScripted := False;
          PrepareTalkDisplay;
          TalkReturnScreenId := FormToId(Self);
          RequestedScreenId := screenTalk;
          RequestClose(1);
        end;
    end
    else if HadWeapons and (Player <> CursorObject) then begin
      for I := 0 to 4 do
        if SelectedWeapons[I] then begin
          Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, I) as TWeapon;
          if PointDistance(Player.Position, (CursorObject as TShip).Position) <= Weapon.Range then
            Weapon.Target := CursorObject;
        end;
      RebuildTargetMarkers;
    end
    else if ((GetAsyncKeyState(VK_CONTROL) and $8000) = $8000) and (Player <> CursorObject) then begin
      ClearPathOverlay(True);
      PendingPlayerFollowTarget := CursorObject as TShip;
      BuildShipPathOverlay(Player);
    end
    else begin
      Ship := CursorObject as TShip;
      if Ship = Player then begin
        ClearPathOverlay(True);
        PendingPlayerFollowTarget := nil;
        Player.OrderNone;
      end else begin
        ClearPathOverlay(True);
        FollowTarget := nil;
        if PendingPlayerFollowTarget <> nil then FollowTarget := PendingPlayerFollowTarget
        else if Player.Order = soFollowShip then FollowTarget := Player.OrderTarget as TShip;
        if FollowTarget <> Ship then begin
          PendingPlayerFollowTarget := nil;
          Player.OrderFollowShip(Ship, fmNear, False);
        end
        else if PendingPlayerFollowTarget <> nil then begin
          PendingPlayerFollowTarget := nil;
          Player.OrderFollowShip(Ship, fmMinWeaponRange, False);
        end
        else if Player.GetFollowMode = fmMinWeaponRange then Player.OrderFollowShip(Ship, fmMaxWeaponRange, False)
        else if Player.GetFollowMode = fmMaxWeaponRange then Player.OrderFollowShip(Ship, fmNear, False)
        else if Player.GetFollowMode = fmNear then begin
          Player.OrderNone;
          PendingPlayerFollowTarget := CursorObject as TShip;
        end
        else Player.OrderFollowShip(Ship, fmNear, False);
        BuildShipPathOverlay(Player);
      end;
    end;
  end
  else if CursorObject is TStar then begin
    // Leaves PendingPlayerFollowTarget unchanged in this branch.
    ClearPathOverlay(True);
    Player.OrderMove(Destination, False);
    Player.BuildOrderMovementPath(UnlimitedPathNodes);
    BuildShipPathOverlay(Player);
  end
  else if CursorObject is TItem then begin
    if HadWeapons then begin
      for I := 0 to 4 do
        if SelectedWeapons[I] then begin
          Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, I) as TWeapon;
          if PointDistance(Player.Position, (CursorObject as TItem).Position) <= Weapon.Range then
            Weapon.Target := CursorObject;
        end;
      RebuildTargetMarkers;
    end
    else if Player.CanPickupItemNow(CursorObject as TItem) then begin
      if Player.IsPickupQueued(CursorObject as TItem) then Player.RemoveQueuedPickupItem(CursorObject as TItem)
      else Player.QueuePickupItem(CursorObject as TItem);
      RebuildTargetMarkers;
    end;
  end
  else if CursorObject is TAsteroid then
  if HadWeapons then begin
    for I := 0 to 4 do
      if SelectedWeapons[I] then begin
        Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, I) as TWeapon;
        if PointDistance(Player.Position, (CursorObject as TAsteroid).Position) <= Weapon.Range then
          Weapon.Target := CursorObject;
      end;
    RebuildTargetMarkers;
  end;
  ScannerSelectionActive := False;
  TalkSelectionActive := False;
  for I := 0 to 4 do SelectedWeapons[I] := False;
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $569A94 }

{ @routine $56A7DC TfStarMap_MapRightButtonDown }
procedure TfStarMap.MapRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var I: Integer;
begin
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive then Exit;
  ScannerSelectionActive := False;
  TalkSelectionActive := False;
  for I := 0 to 4 do SelectedWeapons[I] := False;
  CursorObject := FindObjectAtCursor;
  if (Player.Radar <> nil) and not Player.Radar.BrokenFlag and
    (Player.Scanner <> nil) and not Player.Scanner.BrokenFlag and (Player <> CursorObject) then
  begin
    if (CursorObject <> nil) and (CursorObject is TShip) and
      (RawObjectInfo or not (CursorObject is TRuins)) and
      (RawObjectInfo or not (CursorObject is TKling)) and
      (PointDistance(Player.Position, (CursorObject as TShip).Position) <= Player.GetRadarRange) and
      (Player <> CursorObject) and (RawObjectInfo or Player.CanResolveObjectWithScanner(CursorObject)) then
    begin
      SoundManager.PlaySound('Sound.Scan');
      SetCursorActive(False);
      Present;
      CaptureScreenBackground;
      SetCursorActive(True);
      ScannerTarget := CursorObject;
      ScannerReturnScreenId := FormToId(Self);
      RequestedScreenId := screenScanner;
      RequestClose(1);
    end;
  end
  else if Player = CursorObject then ShipClicked(nil);
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $56A7DC }

{ @routine $56AA00 TfStarMap_MapMouseMove }
procedure TfStarMap.MapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive then Exit;
  RefreshActionRanges;
  UpdateActionCursor;
  if not Sender.IsOccludedAtPoint(Point) and (KeyState and 2 <> 2) then begin
    if (Point.X = 0) or (Point.Y = 0) or (Point.X = GameScreenWidth - 1) or (Point.Y = GameScreenHeight - 1) then begin
      if not IsCursorImageSelected('Scroll') then SetCursorByName('Scroll');
      ShowObjectInfo(nil);
    end else if not (ScrollLeftHeld or ScrollRightHeld or ScrollUpHeld or ScrollDownHeld) then
      ShowObjectInfo(FindObjectAtCursor)
    else begin
      if not IsCursorImageSelected('Main') then SetCursorByName('Main');
    end;
  end;
end;
{ @end $56AA00 }

{ @routine $56AB2C TfStarMap_OrderKeyDown }
procedure TfStarMap.OrderKeyDown(Sender: TObjectGI; Key: Cardinal);
var Slot: Integer; Weapon: TWeapon;
begin
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive then Exit;
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU) then Exit;
  DisplayedObject := nil;
  if Key = VK_BACK then Exit
  else if Key = Ord('I') then ScannerClicked(nil)
  else if Key = Ord('T') then TalkClicked(nil)
  else if (Key >= Ord('1')) and (Key < Ord('6')) then begin
    Slot := Key - Ord('1');
    Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Slot) as TWeapon;
    if (Weapon = nil) or Weapon.BrokenFlag then SelectedWeapons[Slot] := False
    else begin
      Weapon.Target := nil;
      SelectedWeapons[Slot] := not SelectedWeapons[Slot];
    end;
    RebuildTargetMarkers;
    RefreshActionRanges;
    RefreshWeaponButtons;
    UpdateActionCursor;
  end
  else if Key = $C0 then begin
    SelectAllWeapons;
    RebuildTargetMarkers;
    RefreshActionRanges;
    RefreshWeaponButtons;
    UpdateActionCursor;
  end
  else if (Key = $BB) or (Key = VK_ADD) then begin
    SelectUntargetedWeapons;
    RebuildTargetMarkers;
    RefreshActionRanges;
    RefreshWeaponButtons;
    UpdateActionCursor;
  end
  else if Key = VK_DELETE then begin
    for Slot := 0 to 4 do begin
      SelectedWeapons[Slot] := False;
      Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Slot) as TWeapon;
      if Weapon <> nil then Weapon.Target := nil;
    end;
    RebuildTargetMarkers;
    RefreshActionRanges;
    RefreshWeaponButtons;
    UpdateActionCursor;
  end
  else if Key = Ord('S') then ShipClicked(nil)
  else if Key = Ord('M') then GalaxyClicked(nil)
  else if Key = Ord('R') then PanelController.QuestClicked(nil)
  else if Key = VK_ESCAPE then PanelController.MenuClicked(nil)
  else if Key = Ord('F') then OpenFilmHistoryClicked(nil)
  else if Key = Ord('W') then ToggleWeaponPanelClicked(nil);
end;
{ @end $56AB2C }

{ @routine $56AD54 TfStarMap_OrderKeyUp }
procedure TfStarMap.OrderKeyUp(Sender: TObjectGI; Key: Cardinal);
begin
  if (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive then Exit;
end;
{ @end $56AD54 }

{ @routine $56AD68 TfStarMap_SelectAllWeapons }
procedure TfStarMap.SelectAllWeapons;
var I: Integer; Weapon: TWeapon;
begin
  for I := 0 to 4 do begin
    Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, I) as TWeapon;
    if (Weapon = nil) or Weapon.BrokenFlag then SelectedWeapons[I] := False
    else begin
      Weapon.Target := nil;
      SelectedWeapons[I] := True;
    end;
  end;
end;
{ @end $56AD68 }

{ @routine $56ADB4 TfStarMap_SelectUntargetedWeapons }
procedure TfStarMap.SelectUntargetedWeapons;
var I: Integer; Weapon: TWeapon;
begin
  for I := 0 to 4 do begin
    Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, I) as TWeapon;
    if (Weapon = nil) or Weapon.BrokenFlag then SelectedWeapons[I] := False
    else begin
      if Weapon.Target = nil then SelectedWeapons[I] := True;
    end;
  end;
end;
{ @end $56ADB4 }

{ @routine $56AE00 TfStarMap_ShowObjectInfo }
procedure TfStarMap.ShowObjectInfo(Obj: TObject);
const FullNameSeparator = WideString(' ');
var
  Panel: TPanelGI;
  Objects: TList;
  I, J, RowHeight, RowX: Integer;
  IconInset: Cardinal;
  Distance: Single;
  OwnerId: TOwnerId;
  ImagePath, Text, ColorTag: WideString;
begin
  if (Obj <> nil) and (Obj is TAsteroid) then ShowAsteroidPath(Obj as TAsteroid)
  else ClearAsteroidPath;
  if Obj = nil then
  begin
    InfoWindow.SetActive(False);
    ItemInfoWindow.SetActive(False);
    ShipInfoPanel.SetActive(False);
    PlanetInfoPanel.SetActive(False);
    StarInfoWindow.SetActive(False);
    StandardInfoPanel.SetActive(False);
    ClearAsteroidPath;
    ClearPathOverlay(False);
    DisplayedObject := nil;
  end
  else if not RawObjectInfo and (
    ((Obj is TItem) and (PointDistance(TItem(Obj).Position, Player.Position) > Player.GetRadarRange)) or
    ((Obj is TShip) and ((TShip(Obj).CurrentStar <> Player.CurrentStar) or TShip(Obj).InHyperspace or
      (PointDistance(TShip(Obj).Position, Player.Position) > Player.GetRadarRange))) or
    ((Obj is TAsteroid) and (PointDistance(TAsteroid(Obj).Position, Player.Position) > Player.GetRadarRange)) or
    (Obj is THole) or (Obj is TPlanet)) then
  begin
    if DisplayedObject <> Obj then
    begin
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(True);
      if Obj is TItem then
      begin
        GetByName('InfoStdGB').SetActive(False);
        with GetByName('InfoStdImage') as TImageGI do
        begin
          SetActive(True);
          if Obj is TGoods then SetImagePath('GI,' + GetItemTypeBitmapPath(TItem(Obj).ItemType))
          else SetImagePath('GI,' + TItem(Obj).GetBitmapResourceName + 's');
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        if Obj is TGoods then
        begin
          (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(GoodsNames[TItem(Obj).ItemType], GreenColorTag));
          (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(TItem(Obj).ItemType) + 1)));
        end
        else
        begin
          (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(LocalizedText('FormInfo.ContainerName'), GreenColorTag));
          (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
        end;
        (GetByName('InfoItemSize') as TLabelGI).SetText('???');
        (GetByName('InfoItemPrice') as TLabelGI).SetText('???');
      end
      else if Obj is TShip then
      begin
        if (Obj as TShip).Graphic is TShip2SE then
        begin
          GetByName('InfoStdImage').SetActive(False);

          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            ImagePath := (Obj as TShip).GetShipPortraitImagePath;
            SetActive(ImagePath <> '');
            if Active then
            begin
              SourceHasPerPixelAlpha := True;
              LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(ImagePath, 1, ','), GraphBuf);
              if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
                GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
              else
                GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
              SetImageKindX(ikxCenter);
              SetImageKindY(ikyCenter);
              SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
            end;
          end;
        end
        else
        begin
          GetByName('InfoStdImage').SetActive(False);
          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            SetActive(True);
            SourceHasPerPixelAlpha := True;
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(((Obj as TShip).Graphic as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);

            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor((Obj as TShip).GetFullName(FullNameSeparator), GreenColorTag));

        if Obj is TRanger then
        if (Obj as TRanger).PartnerShip = Player then
          (GetByName('InfoStdName') as TLabelGI).SetText((GetByName('InfoStdName') as TLabelGI).GetText + #13#10 + WrapTextInColor(LookupLocalizedTextByKey('FormInfo.Partner'), HighlightColorTag));

        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
      end
      else if Obj is TAsteroid then
      begin
        GetByName('InfoStdImage').SetActive(False);
        with GetByName('InfoStdGB') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGaiFrameToGraphBuf(TAsteroidSE(TAsteroid(Obj).GraphObject).ImagePath, GraphBuf, TAsteroid(Obj).Id);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor((Obj as TAsteroid).GetDisplayName, GreenColorTag));
        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
      end
      else if Obj is THole then
      begin
        GetByName('InfoStdImage').SetActive(False);
        with GetByName('InfoStdGB') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGaiFrameToGraphBuf(THoleSE(THole(Obj).Graphic).ImagePath, GraphBuf, THole(Obj).Id);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(LocalizedText('FormInfo.HoleName'), GreenColorTag));
        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.HoleText'));
      end
      else if Obj is TPlanet then
      begin
        if (Obj as TPlanet).OwnerId in CoalitionOwners then
        begin
          if DisplayedObject = Obj then Exit;
          InfoWindow.SetActive(False);
          ItemInfoWindow.SetActive(False);
          ShipInfoPanel.SetActive(False);
          PlanetInfoPanel.SetActive(True);
          StarInfoWindow.SetActive(False);
          StandardInfoPanel.SetActive(False);
          (GetByName('InfoPlanetName') as TLabelGI).SetText(WrapTextInColor((Obj as TPlanet).Name, GreenColorTag));
          if (Obj as TPlanet).OwnerId in CoalitionOwners then
          begin
            with GetByName('InfoPlanetEmRace') as TImageGI do
            begin
              SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[(Obj as TPlanet).OwnerId].InternalName));
              SetImageKindX(ikxCenter);
              SetImageKindY(ikyCenter);
              SetActive(True);
            end;
          end
          else GetByName('InfoPlanetEmRace').SetActive(False);
          with GetByName('InfoPlanetImage') as TGraphBufGI do
          begin
            SourceHasPerPixelAlpha := True;
            TPlanetSE((Obj as TPlanet).Graphic).RenderToBuffer(Self, GraphBuf, False);
            GraphBuf.RescaleBilinearRgba(ClientSize.X, ClientSize.Y);
          end;
          (GetByName('InfoPlanetOwner') as TLabelGI).SetText((Obj as TPlanet).GetNativeRaceName);
          (GetByName('InfoPlanetPop') as TLabelGI).SetText(IntToStr(Round((Obj as TPlanet).Population / 1000)));
          (GetByName('InfoPlanetEco') as TLabelGI).SetText(PlanetEconomyInfo[(Obj as TPlanet).Economy].DisplayName);
          (GetByName('InfoPlanetGov') as TLabelGI).SetText((Obj as TPlanet).GetGovernmentName);
          (GetByName('InfoPlanetRel') as TLabelGI).SetText((Obj as TPlanet).GetRelationLevelTextToShip(Player));
        end
        else
        begin
          GetByName('InfoStdImage').SetActive(False);
          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            SetActive(True);
            SourceHasPerPixelAlpha := True;
            TPlanetSE((Obj as TPlanet).Graphic).RenderToBuffer(Self, GraphBuf, False);
            GraphBuf.RescaleBilinearRgba(ClientSize.X, ClientSize.Y);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
          (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor((Obj as TPlanet).Name, GreenColorTag));
          (GetByName('InfoStdText') as TLabelGI).SetText((Obj as TPlanet).GetInfoText);
        end;
      end;
      DisplayedObject := Obj;
    end;
  end
  else if (Obj is TItem) and not RawObjectInfo then
  begin
    if DisplayedObject <> Obj then
    begin
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(True);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(False);
      with GetByName('InfoItemImage') as TImageGI do
      begin
        if Obj is TGoods then SetImagePath('GI,' + GetItemTypeBitmapPath(TItem(Obj).ItemType))
        else SetImagePath('GI,' + TItem(Obj).GetBitmapResourceName + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
      end;
      if Obj is TGoods then
      begin
        (GetByName('InfoItemName') as TLabelGI).SetText(WrapTextInColor(GoodsNames[TItem(Obj).ItemType], GreenColorTag));
        (GetByName('InfoItemText') as TLabelGI).SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(TItem(Obj).ItemType) + 1)));
      end
      else
      begin
        (GetByName('InfoItemName') as TLabelGI).SetText(WrapTextInColor(TItem(Obj).GetDisplayName, GreenColorTag));
        (GetByName('InfoItemText') as TLabelGI).SetText(TItem(Obj).GetInfoText(HighlightColorTag));
      end;
      (GetByName('InfoItemSize') as TLabelGI).SetText(IntToStr(TItem(Obj).Weight));
      (GetByName('InfoItemPrice') as TLabelGI).SetText(IntToStr(TItem(Obj).Cost));
      with GetByName('InfoItemEmRace') as TImageGI do
      begin
        if Obj is TGoods then SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[oiNone].InternalName))
        else SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[TItem(Obj).OwnerId].InternalName));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      with GetByName('InfoItemDurable') as TImageGI do
      begin
        if not ((Obj as TItem).ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) then
          SetSize(GetContentSize)
        else
        begin
          if (Obj as TItem).ItemType = t_Hull then
            SetSize(Classes.Point(Round((Obj as THull).HullPoints / (Obj as THull).Weight * GetContentSize.X), ClientSize.Y))
          else SetSize(Classes.Point(Round((Obj as TEquipment).ConditionPercent / 100 * GetContentSize.X), ClientSize.Y));
        end;
      end;
      DisplayedObject := Obj;
    end;
  end
  else if (Obj is TShip) and not RawObjectInfo then
  begin
    if DisplayedObject <> Obj then
    begin
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(True);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(False);
      if Player <> Obj then
      begin
        (GetByName('InfoShipName') as TLabelGI).SetText(WrapTextInColor((Obj as TShip).GetFullName(FullNameSeparator), GreenColorTag));

        if Obj is TRanger then
        if (Obj as TRanger).PartnerShip = Player then
          (GetByName('InfoShipName') as TLabelGI).SetText((GetByName('InfoShipName') as TLabelGI).GetText + #13#10 + WrapTextInColor(LookupLocalizedTextByKey('FormInfo.Partner'), HighlightColorTag));
      end
      else
        (GetByName('InfoShipName') as TLabelGI).SetText(WrapTextInColor((Obj as TShip).GetFullName(FullNameSeparator), GreenColorTag));
      if (Obj as TShip).OwnerId in [oiMaloc..oiGaal] then
      begin
        with GetByName('InfoShipEmRace') as TImageGI do
        begin
          SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[(Obj as TShip).OwnerId].InternalName));
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetActive(True);
        end;
      end
      else GetByName('InfoShipEmRace').SetActive(False);
      if (Obj as TShip).Graphic is TShip2SE then
      begin
        with GetByName('InfoShipImage2') as TGraphBufGI do
        begin
          ImagePath := (Obj as TShip).GetShipPortraitImagePath;
          SetActive(ImagePath <> '');
          if Active then
          begin
            SourceHasPerPixelAlpha := True;
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(ImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
        end;
      end
      else
      begin
        with GetByName('InfoShipImage2') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(((Obj as TShip).Graphic as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
      end;
      if Obj is TRuins then
      begin
        (GetByName('ISType') as TLabelGI).SetActive(False);
        (GetByName('InfoShipType') as TLabelGI).SetActive(False);
      end
      else
      begin
        (GetByName('ISType') as TLabelGI).SetActive(True);
        (GetByName('InfoShipType') as TLabelGI).SetActive(True);
        if Obj is TRanger then (GetByName('InfoShipType') as TLabelGI).SetText((Obj as TRanger).GetCharacterName)
        else (GetByName('InfoShipType') as TLabelGI).SetText((Obj as TShip).GetLocalizedTypeName);
      end;
      (GetByName('InfoShipSpeed') as TLabelGI).SetText(IntToStr((Obj as TShip).CalculateSpeed));
      if (Obj as TShip).Hull.HullPoints <= (Obj as TShip).Hull.Weight / 2 then ColorTag := YellowColorTag
      else ColorTag := '';
      if Player.CanResolveObjectWithScanner(Obj) or (Player = Obj) then
        (GetByName('InfoShipSize') as TLabelGI).SetText(WrapTextInColor(IntToStr((Obj as TShip).Hull.HullPoints), ColorTag) + '/' + IntToStr((Obj as TShip).Hull.Weight))
      else (GetByName('InfoShipSize') as TLabelGI).SetText(WrapTextInColor('???', ColorTag));
      Text := IntToStr((Obj as TShip).GetDefensePercent) + '%';
      if Player.CanResolveObjectWithScanner(Obj) or (Player = Obj) then
        Text := Text + ' + ' + WrapTextInColor(IntToStr((Obj as TShip).Hull.Armor + 5 * (Ord((Obj as TShip).HasActiveArtefact(t_ArtefactHull)))), HighlightColorTag);
      (GetByName('InfoShipDef') as TLabelGI).SetText(Text);
      (GetByName('InfoShipRel') as TLabelGI).SetText((Obj as TShip).GetRelationLevelTextToShip(Player));
      if (Player <> Obj) and not (Obj is TRuins) and Player.HasActiveArtefact(t_ArtefactAnalyzer) and Player.CanResolveObjectWithScanner(Obj) then
      begin
        (GetByName('ISWin') as TLabelGI).SetActive(True);
        (GetByName('InfoShipWin') as TLabelGI).SetActive(True);
        (GetByName('InfoShipWin') as TLabelGI).SetText(IntToStr(Player.GetWinChancePercent(Obj as TShip)) + '%');
      end
      else
      begin
        (GetByName('ISWin') as TLabelGI).SetActive(False);
        (GetByName('InfoShipWin') as TLabelGI).SetActive(False);
      end;
      with GetByName('InfoShipDurable') as TImageGI do
      begin
        if Player.CanResolveObjectWithScanner(Obj) or (Player = Obj) then
          SetSize(Classes.Point(Round((Obj as TShip).Hull.HullPoints / (Obj as TShip).Hull.Weight * GetContentSize.X), ClientSize.Y))
        else SetSize(Classes.Point(Round(1 * GetContentSize.X), ClientSize.Y));
      end;
      DisplayedObject := Obj;
      if Obj is TShip then BuildShipPathOverlay(Obj as TShip)
      else ClearPathOverlay(False);
    end;
  end
  else if (Obj is TStar) and not RawObjectInfo then
  begin
    if DisplayedObject <> Obj then
    begin
      ClearPathOverlay(False);
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(True);
      StandardInfoPanel.SetActive(False);
      (GetByName('InfoStarName') as TLabelGI).SetText(WrapTextInColor((Obj as TStar).Name, GreenColorTag));
      with GetByName('InfoStarImage') as TGraphBufGI do
      begin
        SourceHasPerPixelAlpha := True;
        LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TStarSE((Obj as TStar).Graphic).StaticImagePath, 1, ','), GraphBuf);
        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleBilinearRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)))
        else GraphBuf.RescaleBilinearRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      Panel := GetByName('InfoStarPanel') as TPanelGI;
      Panel.FreeOwnedChildren;
      Objects := TList.Create;
      for I := 0 to Player.CurrentStar.Planets.Count - 1 do Objects.Add(Player.CurrentStar.Planets[I]);
      for I := 0 to Player.CurrentStar.Ships.Count - 1 do
        if TObject(Player.CurrentStar.Ships[I]) is TRuins then
        begin
          Distance := PointDistanceSquared(TShip(Player.CurrentStar.Ships[I]).Position, MakePointF(0, 0));
          J := 0;
          while J < Objects.Count do
          begin
            if TObject(Objects[J]) is TPlanet then
            begin
              if PointDistanceSquared(TPlanet(Objects[J]).GetPosition, MakePointF(0, 0)) > Distance then Break;
            end
            else if PointDistanceSquared(TShip(Objects[J]).Position, MakePointF(0, 0)) > Distance then Break;
            Inc(J);
          end;
          Objects.Insert(J, Player.CurrentStar.Ships[I]);
        end;
      RowHeight := GiScalePixels(20);
      for I := 0 to Objects.Count - 1 do
      begin
        with TLabelGI.Create(Panel) do
        begin
          SetFontName(HitPointFontName);
          SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
          SetSize(Classes.Point(Panel.ClientSize.X div 2 + 15, RowHeight));
          SetPosition(Classes.Point(0, RowHeight * I));
          SetWordWrapEnabled(False);
          SetTextAlignX(taxRight);
          SetTextAlignY(tayCenterEx);
          if TObject(Objects[I]) is TPlanet then SetText(TPlanet(Objects[I]).Name)
          else SetText(TShip(Objects[I]).Name);
        end;
        with TGraphBufGI.Create(Panel) do
        begin
          IconInset := 0;
          if TObject(Objects[I]) is TPlanet then
          begin
            if (TObject(Objects[I]) as TPlanet).Radius < 70 then IconInset := 4
            else if (TObject(Objects[I]) as TPlanet).Radius < 80 then IconInset := 3
            else if (TObject(Objects[I]) as TPlanet).Radius < 90 then IconInset := 2
            else if (TObject(Objects[I]) as TPlanet).Radius < 100 then IconInset := 1
            else IconInset := 0;
          end;
          SourceHasPerPixelAlpha := True;
          SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + 1 + (IconInset shr 1), RowHeight * I + 1 + (IconInset shr 1)));
          SetSize(Classes.Point(RowHeight - 2 - IconInset, RowHeight - 2 - IconInset));
          if TObject(Objects[I]) is TPlanet then
          begin
            TPlanetSE(TPlanet(Objects[I]).Graphic).RenderToBuffer(Self, GraphBuf, True);
            GraphBuf.RescaleRgba(ClientSize.X, ClientSize.Y, 5);
          end
          else
          begin
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((TShip(Objects[I]).Graphic as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          end;
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
        if TObject(Objects[I]) is TPlanet then OwnerId := TPlanet(Objects[I]).OwnerId
        else OwnerId := TShip(Objects[I]).OwnerId;
        if OwnerId in [oiMaloc..oiKling] then
          with TGraphBufGI.Create(Panel) do
          begin
            SourceHasPerPixelAlpha := True;
            LoadBitmapPathAsRgba(ExtractDelimitedPartW(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[OwnerId].InternalName), 1, ',') + '?RGBA');
            SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1, RowHeight * I + 1));
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
          end;
        if not ((TObject(Objects[I]) is TPlanet) and
          ((TObject(Objects[I]) as TPlanet).OwnerId in CoalitionOwners)) then Continue;
        RowX := Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1;
        with TImageGI.Create(Panel) do
        begin
          case (TObject(Objects[I]) as TPlanet).GetRelationLevelToShip(Player) of
            rlHostile: SetImagePath('GI,Bm.FormGalaxy.Face4');
            rlBad: SetImagePath('GI,Bm.FormGalaxy.Face3');
            rlNormal: SetImagePath('GI,Bm.FormGalaxy.Face2');
            rlGood: SetImagePath('GI,Bm.FormGalaxy.Face1');
            rlExcellent: SetImagePath('GI,Bm.FormGalaxy.Face0');
          else SetImagePath('GI,Bm.FormGalaxy.Face2');
          end;
          SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
          SetPosition(Classes.Point(RowX + RowHeight + 2, RowHeight * I + 1));
        end;
        RowX := RowX + RowHeight + 2;
        if not ((TObject(Objects[I]) as TPlanet).Economy in [peAgriculture, peIndustrial]) then Continue;
        with TImageGI.Create(Panel) do
        begin
          case (TObject(Objects[I]) as TPlanet).Economy of
            peAgriculture: SetImagePath('GI,Bm.FormGalaxy.EconAgrar');
            peIndustrial: SetImagePath('GI,Bm.FormGalaxy.EconIndustr');
          end;
          SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
          SetPosition(Classes.Point(RowX + RowHeight, RowHeight * I + 1));
        end;
      end;
      Panel.SetSize(Classes.Point(Panel.ClientSize.X, RowHeight * Objects.Count));
      StarInfoWindow.SetSize(Classes.Point(StarInfoWindow.ClientSize.X, Panel.LocalPosition.Y + RowHeight * Objects.Count + GiScalePixels(30)));
      StarInfoWindow.UpdateAutoGeometry;
      Objects.Free;
      DisplayedObject := Obj;
    end;
  end
  else if (Obj is TAsteroid) and not RawObjectInfo then
  begin
    if DisplayedObject <> Obj then
    begin
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(True);
      GetByName('InfoStdImage').SetActive(False);
      with GetByName('InfoStdGB') as TGraphBufGI do
      begin
        SetActive(True);
        SourceHasPerPixelAlpha := True;
        LoadGaiFrameToGraphBuf(TAsteroidSE(TAsteroid(Obj).GraphObject).ImagePath, GraphBuf, TAsteroid(Obj).Id);

        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
        else
          GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
        SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
      end;
      (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor((Obj as TAsteroid).GetDisplayName, GreenColorTag));
      (GetByName('InfoStdText') as TLabelGI).SetText((Obj as TAsteroid).GetInfoText);
      DisplayedObject := Obj;
    end;
  end
  else
  begin
    if DisplayedObject <> Obj then
    begin
      InfoWindow.SetActive(True);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(False);
      InfoTextLabel.SetText(Player.GetObjectInfoText(Obj));
      InfoWindow.SetSize(Classes.Point(InfoTextLabel.ClientSize.X + InfoWindow.WorkSubRect.Left + InfoWindow.WorkSubRect.Right,
        InfoTextLabel.ClientSize.Y + InfoWindow.WorkSubRect.Top + InfoWindow.WorkSubRect.Bottom));
      InfoWindow.UpdateAutoGeometry;
      InfoTextLabel.SetPosition(Classes.Point(InfoWindow.WorkSubRect.Left, InfoWindow.WorkSubRect.Top));
      DisplayedObject := Obj;
      if Obj is TAsteroid then ShowAsteroidPath(Obj as TAsteroid)
      else ClearAsteroidPath;
      if Obj is TShip then BuildShipPathOverlay(Obj as TShip)
      else ClearPathOverlay(False);
    end;
  end;
end;
{ @end $56AE00 }

{ @routine $56EA0C TfStarMap_MapScrollChanged }
procedure TfStarMap.MapScrollChanged;
begin
  RefreshActionRanges;
  SpaceProcess.Space.DrawMinimap;
end;
{ @end $56EA0C }

{ @routine $56EA24 TfStarMap_CenterOnPlayer }
procedure TfStarMap.CenterOnPlayer(Sender: TObjectGI);
begin
  SetMapCenterManually(TruncatePointF(Player.Position));
  AddMapAnimation(Player.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 0);
  AddMapAnimation(Player.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 200);
  AddMapAnimation(Player.Position, 'Bm.SI.' + GiResourceSuffix + 'Ring', 400);
end;
{ @end $56EA24 }

{ @routine $56EB58 TfStarMap_AllWeaponsClicked }
procedure TfStarMap.AllWeaponsClicked(Sender: TObjectGI);
begin
  SelectAllWeapons;
  RebuildTargetMarkers;
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $56EB58 }

{ @routine $56EB80 TfStarMap_ScannerClicked }
procedure TfStarMap.ScannerClicked(Sender: TObjectGI);
var I: Integer;
begin
  TalkSelectionActive := False;
  for I := 0 to 4 do SelectedWeapons[I] := False;
  if Player.Scanner <> nil then ScannerSelectionActive := not ScannerSelectionActive
  else ScannerSelectionActive := False;
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $56EB80 }

{ @routine $56EBD8 TfStarMap_TalkClicked }
procedure TfStarMap.TalkClicked(Sender: TObjectGI);
var I: Integer;
begin
  ScannerSelectionActive := False;
  for I := 0 to 4 do SelectedWeapons[I] := False;
  if Player.Radar <> nil then TalkSelectionActive := not TalkSelectionActive
  else TalkSelectionActive := False;
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $56EBD8 }

{ @routine $56EC30 TfStarMap_ToggleWeaponPanelClicked }
procedure TfStarMap.ToggleWeaponPanelClicked(Sender: TObjectGI);
begin
  StarMapWeaponPanelOpen := not StarMapWeaponPanelOpen;
  GetByName('PS_Up').SetActive(StarMapWeaponPanelOpen);
end;
{ @end $56EC30 }

{ @routine $56EC70 TfStarMap_WeaponClicked }
procedure TfStarMap.WeaponClicked(Sender: TObjectGI);
var Slot: Integer; Weapon: TWeapon;
begin
  DisplayedObject := nil;
  Slot := ExtractDigitsToIntW(Sender.ControlName);
  Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Slot) as TWeapon;
  if (Weapon = nil) or Weapon.BrokenFlag then SelectedWeapons[Slot] := False
    else begin
    if Weapon.Target <> nil then begin
      Weapon.Target := nil;
      SelectedWeapons[Slot] := False;
    end else SelectedWeapons[Slot] := not SelectedWeapons[Slot];
  end;
  RebuildTargetMarkers;
  RefreshActionRanges;
  RefreshWeaponButtons;
  UpdateActionCursor;
end;
{ @end $56EC70 }

{ @routine $56ECFC TfStarMap_RefreshWeaponButtons }
procedure TfStarMap.RefreshWeaponButtons;
var Slot: Integer; Weapon: TWeapon; Button: TGraphButtonGI; Image: TImageGI;
begin
  for Slot := 0 to 4 do begin
    Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Slot) as TWeapon;
    Button := WeaponButtons[Slot];
    Button.SetDown(SelectedWeapons[Slot] or ((Weapon <> nil) and (Weapon.Target <> nil)));
    Button.DownCallback := WeaponClicked;
    Button.UpCallback := WeaponClicked;
    Image := WeaponImages[Slot];
    if Weapon = nil then Image.SetActive(False)
    else begin
      Image.SetActive(True);
      Image.SetImagePath('GI,' + Weapon.GetBitmapResourceName + 's');
    end;
    Image.SetImageKindX(ikxCenter);
    Image.SetImageKindY(ikyCenter);
  end;
end;
{ @end $56ECFC }

{ @routine $56EE30 TfStarMap_HideWeaponImages }
procedure TfStarMap.HideWeaponImages;
var I: Integer;
begin
  for I := 0 to 4 do with WeaponImages[I] do SetActive(False);
end;
{ @end $56EE30 }

{ @routine $56EE50 TfStarMap_RefreshActionRanges }
procedure TfStarMap.RefreshActionRanges;
var
  Point: TPoint;
  MainCenter: TPoint;
  MainRadius: Integer;
  MainColor: Cardinal;
  MainVisible: Boolean;
  InnerCenter: TPoint;
  InnerRadius: Integer;
  InnerColor: Cardinal;
  InnerVisible: Boolean;
  RadarCenter: TPointF;
  RadarRadius: Integer;
  RadarColor: Cardinal;
  RadarChanged: Boolean;
  Slot, MinRange, MaxRange: Integer;
  AnyWeapon: Boolean;
  Weapon: TWeapon;
  MainCircle, InnerCircle: TSpaceCircleGI;
  SimpleCircle: TCircleGI;
begin
  CursorObject := FindObjectAtCursor;
  AnyWeapon := False;
  for Slot := 0 to 4 do
    if SelectedWeapons[Slot] then
    begin
      AnyWeapon := True;
      Break;
    end;
  RadarCenter := Player.Position;
  RadarRadius := Player.GetRadarRange;
  RadarColor := 0;
  InnerCenter := TruncatePointF(Player.Position);
  InnerRadius := 0;
  InnerColor := 0;
  InnerVisible := False;
  MainCenter := TruncatePointF(Player.Position);
  MainRadius := Player.GetRadarRange;
  MainColor := 0;
  MainVisible := False;
  if ScannerSelectionActive then
  begin
    MainColor := CurrentPixelFormat.PackRgbBytes(255, 255, 0);
    MainVisible := True;
    RadarColor := MainColor;
  end
  else if TalkSelectionActive then
  begin
    MainColor := CurrentPixelFormat.PackRgbBytes(255, 0, 255);
    MainVisible := True;
    RadarColor := MainColor;
  end
  else if AnyWeapon then
  begin
    MinRange := 999999999;
    MaxRange := -999999999;
    for Slot := 0 to 4 do
      if SelectedWeapons[Slot] then
      begin
        Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Slot) as TWeapon;
        if Weapon.Range < MinRange then MinRange := Weapon.Range;
        if Weapon.Range > MaxRange then MaxRange := Weapon.Range;
      end;
    MainColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
    MainRadius := MaxRange;
    MainVisible := True;
    if MaxRange <> MinRange then
    begin
      InnerRadius := MinRange;
      InnerColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
      InnerVisible := True;
    end;
    RadarColor := MainColor;
    RadarRadius := MainRadius;
  end
  else if CursorObject = nil then
  begin
    MainVisible := False;
    RadarColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
  end
  else
  begin
    if (CursorObject is TItem) and (Player.CargoHook <> nil) then
    begin
      MainColor := CurrentPixelFormat.PackRgbBytes(0, 0, 255);
      MainRadius := Player.GetCargoHookRange;
      MainVisible := True;
      RadarColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
    end
    else if CursorObject <> nil then
    begin
      MainColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
      MainVisible := True;
      RadarColor := MainColor;
    end;
  end;
  MainCircle := ActionColorCircle;
  Point := MainCircle.ToLocalPoint(MapControls.ToAbsolutePoint(MainCenter));
  if (MainCircle.Center.X <> Point.X) or (MainCircle.Center.Y <> Point.Y) then MainCircle.SetCenter(Point);
  if MainCircle.Radius <> MainRadius then MainCircle.SetRadius(MainRadius);
  if MainCircle.Color <> MainColor then MainCircle.Color := MainColor;
  if MainCircle.Active <> MainVisible then MainCircle.SetActive(MainVisible);
  InnerCircle := InnerWeaponColorCircle;
  Point := InnerCircle.ToLocalPoint(MapControls.ToAbsolutePoint(InnerCenter));
  if (InnerCircle.Center.X <> Point.X) or (InnerCircle.Center.Y <> Point.Y) then InnerCircle.SetCenter(Point);
  if InnerCircle.Radius <> InnerRadius then InnerCircle.SetRadius(InnerRadius);
  if InnerCircle.Color <> InnerColor then InnerCircle.Color := InnerColor;
  if InnerCircle.Active <> InnerVisible then InnerCircle.SetActive(InnerVisible);
  SimpleCircle := ActionCircle;
  if not HideActionCircle then SimpleCircle.SetActive(False)
  else
  begin
    Point := SimpleCircle.ToLocalPoint(MapControls.ToAbsolutePoint(MainCenter));
    if (SimpleCircle.Center.X <> Point.X) or (SimpleCircle.Center.Y <> Point.Y) then SimpleCircle.SetCenter(Point);
    if SimpleCircle.Radius <> MainRadius then SimpleCircle.SetRadius(MainRadius);
    if SimpleCircle.Active <> MainVisible then SimpleCircle.SetActive(MainVisible);
  end;
  RadarChanged := False;
  if (SpaceProcess.RadarCenter.X <> RadarCenter.X) or (SpaceProcess.RadarCenter.Y <> RadarCenter.Y) then
  begin
    SpaceProcess.RadarCenter := RadarCenter;
    RadarChanged := True;
  end;
  if SpaceProcess.ActionRange <> RadarRadius then
  begin
    SpaceProcess.ActionRange := RadarRadius;
    RadarChanged := True;
  end;
  if SpaceProcess.ActionColor <> RadarColor then
  begin
    SpaceProcess.ActionColor := RadarColor;
    RadarChanged := True;
  end;
  if RadarChanged then SpaceProcess.Space.DrawMinimap;
end;
{ @end $56EE50 }

{ @routine $56F2DC TfStarMap_HideActionRanges }
procedure TfStarMap.HideActionRanges;
begin
  with ActionColorCircle do SetActive(False);
  with InnerWeaponColorCircle do SetActive(False);
  with ActionCircle do SetActive(False);
end;
{ @end $56F2DC }

{ @routine $56F308 TfStarMap_RebuildTargetMarkers }
procedure TfStarMap.RebuildTargetMarkers;
var
  J, I: Integer;
  Weapon: TWeapon;
  Point: TPointF;
  Image: TImageGI;
  Item: TItem;
begin
  ClearTargetMarkers;
  for I := 1 to Player.WeaponCount do
  begin
    Weapon := Player.Weapons[I - 1];
    if Weapon.Target <> nil then
      if (Weapon.Target is TItem) or (Weapon.Target is TAsteroid) or
        ((Weapon.Target is TShip) and (Weapon.Target as TShip).InNormalSpace) then
      begin
        if Weapon.Target is TItem then Point := (Weapon.Target as TItem).Position
        else if Weapon.Target is TAsteroid then Point := (Weapon.Target as TAsteroid).Position
        else if Weapon.Target is TShip then Point := (Weapon.Target as TShip).Position;
        Point := AddPointsF(Point, MakePointF(-40, -40));
        for J := 1 to I - 1 do
          if Player.Weapons[J - 1].Target = Weapon.Target then Point.X := Point.X + 32;
        Image := TImageGI.Create(MapControls);
        Image.SetImagePath('GI,' + Weapon.GetBitmapResourceName + 's');
        Image.SetSize(Image.GetContentSize);
        Image.SetOrigin(HalfPoint(Image.ClientSize));
        Image.SetPosition(TruncatePointF(Point));
        Image.SetDepthByName('Weapon');
        Image.SetPositionModeW(True);
        Image.UserValue := 100;
        Image.UserIndex := I;
        Image.MouseBlocking := True;
      end;
  end;
  if Player.PickupTargets <> nil then
    for I := 0 to Player.PickupTargets.Count - 1 do
    begin
      Item := Player.PickupTargets[I];
      Image := TImageGI.Create(MapControls);
      Image.SetImagePath('GAI,Bm.PI.ItemTakeAnim');
      Image.SetSize(Image.GetContentSize);
      Image.SetOrigin(HalfPoint(Image.ClientSize));
      Image.SetPosition(TruncatePointF(AddPointsF(Item.Position, MakePointF(-20, 20))));
      Image.SetDepthByName('Weapon');
      Image.SetPositionModeW(True);
      Image.UserValue := 100;
      Image.MouseBlocking := True;
      Image.RestartPlayback;
    end;
end;
{ @end $56F308 }

{ @routine $56F6F4 TfStarMap_ClearTargetMarkers }
procedure TfStarMap.ClearTargetMarkers;
var
  NextControl, Control: TObjectGI;
begin
  NextControl := MapControls.FirstChild;
  while NextControl <> nil do
  begin
    Control := NextControl;
    NextControl := NextControl.NextSibling;
    if Control.UserValue = 100 then
    begin
      Control.SetActive(False);
      Control.Free;
    end;
  end;
end;
{ @end $56F6F4 }

{ @routine $56F728 TfStarMap_UpdateActionCursor }
procedure TfStarMap.UpdateActionCursor;
var
  Point: TPointF;
  Obj: TObject;
  Index, Range: Integer;
  AnyWeapon: Boolean;
  Weapon: TWeapon;
begin
  AnyWeapon := False;
  for Index := 0 to 4 do
    if SelectedWeapons[Index] then
    begin
      AnyWeapon := True;
      Break;
    end;
  if ScannerSelectionActive then
  begin
    Obj := FindObjectAtCursor;
    if (Obj is TShip) and not (Obj is TRuins) and not (Obj is TKling) then
    begin
      if Sqr(Player.GetRadarRange) >= Single(PointDistanceSquared((Obj as TShip).Position, Player.Position)) then
      begin
        if not IsCursorImageSelected('ScanFull') then SetCursorByName('ScanFull');
      end
      else if not IsCursorImageSelected('ScanSmall') then SetCursorByName('ScanSmall');
    end
    else if not IsCursorImageSelected('ScanSmall') then SetCursorByName('ScanSmall');
  end
  else if TalkSelectionActive then
  begin
    Obj := FindObjectAtCursor;
    if (Obj is TShip) and not (Obj is TRuins) and
      (not (Obj is TKling) or (((Obj as TKling).KlingType = ktMakhpella) and
        Player.HaveCommunicator and ((Obj as TKling).ScriptShip <> nil))) then
    begin
      if Sqr(Player.GetRadarRange) >= Single(PointDistanceSquared((Obj as TShip).Position, Player.Position)) then
      begin
        if not IsCursorImageSelected('TalkFull') then SetCursorByName('TalkFull');
      end
      else if not IsCursorImageSelected('TalkSmall') then SetCursorByName('TalkSmall');
    end
    else if not IsCursorImageSelected('TalkSmall') then SetCursorByName('TalkSmall');
  end
  else if AnyWeapon then
  begin
    Obj := FindObjectAtCursor;
    if (Obj is TShip) or (Obj is TItem) or (Obj is TAsteroid) then
    begin
      Range := -999999999;
      for Index := 0 to 4 do
        if SelectedWeapons[Index] then
        begin
          Weapon := Player.FindEquippedItemInSlot(WeaponCategoryItemType, Index) as TWeapon;
          if Weapon.Range > Range then Range := Weapon.Range;
        end;
      if Obj is TShip then Point := (Obj as TShip).Position
      else if Obj is TItem then Point := (Obj as TItem).Position
      else if Obj is TAsteroid then Point := (Obj as TAsteroid).Position;
      if PointDistanceSquared(Point, Player.Position) <= Sqr(Range) then
      begin
        if not IsCursorImageSelected('FireFull') then SetCursorByName('FireFull');
      end
      else if not IsCursorImageSelected('FireSmall') then SetCursorByName('FireSmall');
    end
    else if not IsCursorImageSelected('FireSmall') then SetCursorByName('FireSmall');
  end
  else
  begin
    Obj := FindObjectAtCursor;
    if (Obj is TItem) and Player.CanPickupItemNow(Obj as TItem) then
    begin
      if not IsCursorImageSelected('Take') then SetCursorByName('Take');
    end
    else if MapControls.Dragging then
    begin
      if not IsCursorImageSelected('Scroll') then SetCursorByName('Scroll');
    end
    else if not IsCursorImageSelected('Main') then SetCursorByName('Main');
  end;
end;
{ @end $56F728 }

{ @routine $56FCA8 GetTurnFilmFrameInterval }
function GetTurnFilmFrameInterval(Activity: Integer): Integer;
begin
  if Activity = 0 then Result := 18
  else if Cardinal(Activity) = 1 then Result := 14
  else Result := 10;
  if FilmSpeed = 0 then Inc(Result, 2)
  else if FilmSpeed = 2 then Dec(Result, 2);
end;
{ @end $56FCA8 }

{ @routine $56FCE4 TfStarMap_StartTurnFilm }
procedure TfStarMap.StartTurnFilm;
begin
  DisplayedFilmObject := nil;
  MapControls.MouseMoveCallback := FilmMouseMove;
  ScrollLeftHeld := False;
  ScrollRightHeld := False;
  ScrollUpHeld := False;
  ScrollDownHeld := False;
  RebuildPartnerButtons;
  FilmStepIndex := -1;
  TrailingEffectSteps := 0;
  BreakRequested := BreakOnNextFilm;
  FilmFlagF7 := True;
  PanelController.Show;
  PanelController.DisableNavigationButtons;
  PanelController.RebuildMessageButtons;
  SwapTurnFilms;
  SpaceProcess.RadarRange := SecondaryFilm.RadarRange;
  SpaceProcess.ActionRange := SecondaryFilm.RadarRange;
  SpaceProcess.ActionColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
  if SecondaryFilm.PlayerCombatRecorded then
  begin
    if not MusicInSpace then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Battle');
  end;
  CenterShipButton.DownCallback := CenterFilmShipClicked;
  with GetByName('PM_Break') as TGraphButtonGI do
  begin
    SetActive(True);
    SetDisabled(False);
    UpCallback := BreakTurnClicked;
  end;
  ContinueTurnCalculation := False;
  FilmProgressTimer := ScheduleCallbackTimer(50, 50, UpdateTurnCalculation);
  NextFilmCommand := SecondaryFilm.FirstCommand;
  // Native code tests the command pointer but leaves the empty branch in place.
  if NextFilmCommand = nil then begin end;
  Mode := 2;
  FilmFrameIntervalMs := GetTurnFilmFrameInterval(SecondaryFilm.InitialActivity);
  if SecondaryFilm.InitialActivity = SecondaryFilm.FinalActivity then FilmFrameIntervalDelta := 0
  else FilmFrameIntervalDelta := (GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity) - GetTurnFilmFrameInterval(SecondaryFilm.InitialActivity)) / 180.0;
  if FilmFrameTimer <> 0 then
  begin
    CancelCallbackTimer(FilmFrameTimer);
    FilmFrameTimer := 0;
  end;
  FilmFrameTimer := ScheduleCallbackTimer(Round(FilmFrameIntervalMs), Round(FilmFrameIntervalMs), AdvanceFilmFrame);
  FilmCameraTargetUntilStep := 0;
  FilmCameraEventIndex := 0;
  FilmCameraTargetKind := 0;
  FilmCameraPosition := PointToPointF(GetMapCenter);
  FilmCameraTarget := FilmCameraPosition;
  ReservedFilmState13C := 0;
  FilmCameraMoving := False;
  AdvanceFilmFrame(0, 0);
  ReservedFilmStateF8 := 0;
  if not IsCursorImageSelected('Main') then SetCursorByName('Main');
end;
{ @end $56FCE4 }

{ @routine $56FFFC TfStarMap_StopTurnFilm }
procedure TfStarMap.StopTurnFilm(StopTurnProcessing: Boolean);
begin
  DisplayedFilmObject := nil;
  Mode := 0;
  (GetByName('PM_Break') as TGraphButtonGI).SetDisabled(True);
  if StopTurnProcessing and ContinueTurnCalculation then WaitForTurnCalculationUI;
  if FilmProgressTimer <> 0 then
  begin
    CancelCallbackTimer(FilmProgressTimer);
    FilmProgressTimer := 0;
  end;
  if FilmFrameTimer <> 0 then
  begin
    CancelCallbackTimer(FilmFrameTimer);
    FilmFrameTimer := 0;
  end;
  CenterShipButton.DownCallback := nil;
  MapControls.MouseMoveCallback := nil;
  PanelController.ClearMessageButtons;
  PanelController.Hide;
end;
{ @end $56FFFC }

{ @routine $5700D0 TfStarMap_RestartTurnFilm }
procedure TfStarMap.RestartTurnFilm;
begin
  DisplayedFilmObject := nil;
  PanelController.RebuildMessageButtons;
  RebuildPartnerButtons;
  FilmStepIndex := -1;
  if FilmProgressTimer <> 0 then
  begin
    CancelCallbackTimer(FilmProgressTimer);
    FilmProgressTimer := 0;
  end;
  FilmProgressTimer := ScheduleCallbackTimer(50, 50, UpdateTurnCalculation);
  ContinueTurnCalculation := False;
  BreakRequested := BreakOnNextFilm;
  (GetByName('PM_Break') as TGraphButtonGI).UpCallback := BreakTurnClicked;
  SwapTurnFilms;
  NextFilmCommand := SecondaryFilm.FirstCommand;
  FilmFrameIntervalMs := GetTurnFilmFrameInterval(SecondaryFilm.InitialActivity);
  if SecondaryFilm.InitialActivity = SecondaryFilm.FinalActivity then FilmFrameIntervalDelta := 0
  else FilmFrameIntervalDelta := (GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity) - GetTurnFilmFrameInterval(SecondaryFilm.InitialActivity)) / 180.0;
  if FilmFrameTimer <> 0 then
  begin
    CancelCallbackTimer(FilmFrameTimer);
    FilmFrameTimer := 0;
  end;
  FilmFrameTimer := ScheduleCallbackTimer(Round(FilmFrameIntervalMs), Round(FilmFrameIntervalMs), AdvanceFilmFrame);
  FilmCameraTargetUntilStep := 0;
  FilmCameraEventIndex := 0;
  FilmCameraTargetKind := 0;
  FilmCameraPosition := PointToPointF(GetMapCenter);
  FilmCameraTarget := FilmCameraPosition;
  ReservedFilmState13C := 0;
  FilmCameraMoving := False;
  AdvanceFilmFrame(0, 0);
end;
{ @end $5700D0 }

{ @routine $5702D8 TfStarMap_ProcessTurnFilm }
procedure TfStarMap.ProcessTurnFilm;
var
  WaitResult: Cardinal;
  Events: array[0..1] of THandle;
  EventList: Pointer;
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
  if TrailingEffectSteps <= 0 then
  begin
    // Dereferences this pointer before the loop's later nil check.
    if NextFilmCommand.Kind = efcBeginTrailingEffects then
    begin
      if TrailingFilmEffects = nil then TrailingFilmEffects := TEFilmEnd.Create;
      TrailingFilmEffects.TakeTrailingEffects(SecondaryFilm);
      Inc(FilmStepIndex);
      NextFilmCommand := NextFilmCommand.Next;
    end
    else
    begin
      Inc(FilmStepIndex);
      while NextFilmCommand <> nil do
      begin
        if NextFilmCommand.Kind = efcBeginTrailingEffects then Break;
        if NextFilmCommand.StepIndex > FilmStepIndex then Break;
        SecondaryFilm.ExecuteCommand(SpaceProcess, NextFilmCommand, False);
        NextFilmCommand := NextFilmCommand.Next;
      end;
    end;
  end;
  UpdateFilmCamera;
  if TrailingEffectSteps > 0 then
  begin
    Dec(TrailingEffectSteps);
    if TrailingEffectSteps <= 0 then
    begin
      StopTurnFilm(True);
      GameEndReason := 0;
      RequestedScreenId := screenGameEnd;
      RequestClose(1);
    end;
  end
  else if NextFilmCommand = nil then
  begin
    if ((Player = nil) or (KlingMotherShip = nil)) and (SecondaryFilm.Turn >= Galaxy.CurrentTurn) then
      TrailingEffectSteps := 200
    else if (Player <> nil) and ((Player.Order = soJump) or (Player.Order = soEnterBlackHole)) and Player.InHyperspace and not Player.Graphic.IsAttachedToSpace then
    begin
      StopTurnFilm(True);
      if Player.Order = soEnterBlackHole then RequestedScreenId := screenArcadeBattle
      else if SkipHyperAnimation then
      begin
        if IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_MENU) then RequestedScreenId := screenArcadeBattle
        else RequestedScreenId := screenJump;
      end
      else
      begin
        if IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_MENU) then RequestedScreenId := screenJump
        else RequestedScreenId := screenArcadeBattle;
      end;
      RequestClose(1);
    end
    else if (Player <> nil) and not PlayerAutomaticControl and (ScenarioState <> scenAllianceAgainstRachekhan) and Player.IsOnPlanet and not Player.Graphic.IsAttachedToSpace then
    begin
      StopTurnFilm(True);
      if not IsTurnCalculationRunningUI and (TurnCalculationPhase = 4) then QueueGalaxyTurnCalculation;
      if Player.CurrentPlanet.OwnerId = oiNone then RequestedScreenId := screenPlanetNO
      else RequestedScreenId := screenPlanet;
      RequestClose(1);
    end
    else if (Player <> nil) and not PlayerAutomaticControl and (ScenarioState <> scenAllianceAgainstRachekhan) and Player.IsDockedToShip and not Player.Graphic.IsAttachedToSpace then
    begin
      StopTurnFilm(True);
      if not IsTurnCalculationRunningUI and (TurnCalculationPhase = 4) then QueueGalaxyTurnCalculation;
      RequestedScreenId := screenRuinsTalk;
      RequestClose(1);
    end
    else
    begin
      if ContinueTurnCalculation then
      begin
        if IsTurnCalculationRunningUI then
        begin
          Events[0] := TurnCalculationThread.IdleEvent;
          Events[1] := TalkRequestEvent;
          EventList := @Events;
          WaitResult := WaitForMultipleObjects(Length(Events), EventList, False, INFINITE);
        end
        else WaitResult := WAIT_OBJECT_0;
        if WaitResult = WAIT_FAILED then
          raise Exception.Create('Error GetLastError()=' + IntToStr(Int64(GetLastError)))
        else if WaitResult = WAIT_OBJECT_0 then
        begin
          QueueInterfaceImages;
          if (Player <> nil) and not Player.InHyperspace then QueueGalaxyTurnCalculation;
          if BreakRequested then
          begin
            RestartTurnFilm;
            BreakRequested := True;
          end
          else RestartTurnFilm;
        end
        else if WaitResult = WAIT_OBJECT_0 + 1 then
        begin
          StopTurnFilm(False);
          PrepareTalkDisplay;
          TalkReturnScreenId := FormToId(Self);
          RequestedScreenId := screenTalk;
          RequestClose(1);
        end;
      end
      else
      begin
        StopTurnFilm(True);
        QueueInterfaceImages;
        if IsTurnCalculationRunningUI then WaitForTurnCalculationUI;
        QueuePlayerStarPreparation;
        Events[0] := TurnCalculationThread.IdleEvent;
        Events[1] := TalkRequestEvent;
        EventList := @Events;
        WaitResult := WaitForMultipleObjects(Length(Events), EventList, False, INFINITE);
        if (TurnCalculationThread.IdleEvent = 0) or (WaitResult = WAIT_OBJECT_0) then StartOrderMode
        else if WaitResult = WAIT_FAILED then
          raise Exception.Create('Error GetLastError()=' + IntToStr(Int64(GetLastError)))
        else if WaitResult = WAIT_OBJECT_0 + 1 then
        begin
          PrepareTalkDisplay;
          TalkReturnScreenId := FormToId(Self);
          RequestedScreenId := screenTalk;
          RequestClose(1);
        end;
      end;
    end;
  end;
end;
{ @end $5702D8 }

{ @routine $5708E0 TfStarMap_AdvanceFilmFrame }
procedure TfStarMap.AdvanceFilmFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  ProcessTurnFilm;
  if FilmFrameIntervalDelta <> 0.0 then
  begin
    FilmFrameIntervalMs := FilmFrameIntervalMs + FilmFrameIntervalDelta;
    if FilmFrameIntervalDelta < 0.0 then
    begin
      if FilmFrameIntervalMs < GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity) then
      begin
        FilmFrameIntervalMs := GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity);
        FilmFrameIntervalDelta := 0.0;
      end;
    end
    else if FilmFrameIntervalMs > GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity) then
    begin
      FilmFrameIntervalMs := GetTurnFilmFrameInterval(SecondaryFilm.FinalActivity);
      FilmFrameIntervalDelta := 0.0;
    end;
    if FilmFrameTimer <> 0 then
    begin
      CancelCallbackTimer(FilmFrameTimer);
      FilmFrameTimer := 0;
    end;
    FilmFrameTimer := ScheduleCallbackTimer(Round(FilmFrameIntervalMs), Round(FilmFrameIntervalMs), AdvanceFilmFrame);
  end;
end;
{ @end $5708E0 }

{ @routine $570A04 TfStarMap_UpdateTurnCalculation }
procedure TfStarMap.UpdateTurnCalculation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if BreakRequested and (Player <> nil) and not Player.IsOnPlanet then
    ContinueTurnCalculation := False
  else if not IsTurnCalculationRunningUI then
  begin
    ContinueTurnCalculation := ShouldContinuePlayerTravel;
    if ContinueTurnCalculation and (TurnCalculationPhase = 2) then QueuePlayerStarTurnCalculation;
    if FilmProgressTimer <> 0 then
    begin
      CancelCallbackTimer(FilmProgressTimer);
      FilmProgressTimer := 0;
    end;
  end;
end;
{ @end $570A04 }

{ @routine $570A7C TfStarMap_BreakTurnClicked }
procedure TfStarMap.BreakTurnClicked(Sender: TObjectGI);
begin
  BreakRequested := True;
  (GetByName('PM_Break') as TGraphButtonGI).SetDisabled(True);
end;
{ @end $570A7C }

{ @routine $570AC0 TfStarMap_UpdateFilmCamera }
procedure TfStarMap.UpdateFilmCamera;
var
  BestPriority, BestIndex: Integer;
  Center: TPoint;
  HalfSize: TPoint;
  Vector, TopLeft, BottomRight: TPointF;
  Distance, Speed: Single;
  ViewRect: TRect;
begin
  if FilmStepIndex > 200 then Exit;
  if (FilmStepIndex = 0) and not SecondaryFilm.ForceCameraMovement then
  begin
    HalfSize.X := (GameScreenWidth shr 1) - GiScalePixels(100);
    HalfSize.Y := (GameScreenHeight shr 1) - GiScalePixels(100);
    FilmCameraMoving := (FilmCameraPosition.X - HalfSize.X > SecondaryFilm.CameraAnchor.X) or
      (FilmCameraPosition.X + HalfSize.X <= SecondaryFilm.CameraAnchor.X) or
      (FilmCameraPosition.Y - HalfSize.Y > SecondaryFilm.CameraAnchor.Y) or
      (FilmCameraPosition.Y + HalfSize.Y <= SecondaryFilm.CameraAnchor.Y);
  end;
  if FilmCameraMoving or SecondaryFilm.ForceCameraMovement or (SecondaryFilm.CameraEventCount <> 0) then
  begin
    if FilmCameraTargetUntilStep <= FilmStepIndex then
    begin
      BestPriority := -1;
      BestIndex := -1;
      while FilmCameraEventIndex < SecondaryFilm.CameraEventCount do
      begin
        if PEFilmCameraEventArray(SecondaryFilm.CameraEvents)[FilmCameraEventIndex].StepIndex >= FilmStepIndex + FilmCameraLookAheadSteps then Break;
        if PEFilmCameraEventArray(SecondaryFilm.CameraEvents)[FilmCameraEventIndex].Priority > BestPriority then
        begin
          BestPriority := PEFilmCameraEventArray(SecondaryFilm.CameraEvents)[FilmCameraEventIndex].Priority;
          BestIndex := FilmCameraEventIndex;
        end;
        Inc(FilmCameraEventIndex);
      end;
      if BestIndex >= 0 then
      begin
        FilmCameraTargetUntilStep := PEFilmCameraEventArray(SecondaryFilm.CameraEvents)[BestIndex].StepIndex + FilmCameraLookAheadSteps;
        HalfSize.X := (GameScreenWidth shr 1) - GiScalePixels(100);
        HalfSize.Y := (GameScreenHeight shr 1) - GiScalePixels(100);
        ViewRect.Left := Round(FilmCameraPosition.X - HalfSize.X);
        ViewRect.Top := Round(FilmCameraPosition.Y - HalfSize.Y);
        ViewRect.Right := Round(FilmCameraPosition.X + HalfSize.X);
        ViewRect.Bottom := Round(FilmCameraPosition.Y + HalfSize.Y);
        with ViewRect, PEFilmCameraEventArray(SecondaryFilm.CameraEvents)[BestIndex] do
        begin
          if (Left > StartPosition.X) or (Right <= StartPosition.X) or
             (Top > StartPosition.Y) or (Bottom <= StartPosition.Y) or
             (Left > EndPosition.X) or (Right <= EndPosition.X) or
             (Top > EndPosition.Y) or (Bottom <= EndPosition.Y) then
          begin
            Vector.X := EndPosition.X - StartPosition.X;
            Vector.Y := EndPosition.Y - StartPosition.Y;
            Distance := Sqrt(Sqr(Vector.X) + Sqr(Vector.Y));
            if Distance = 0 then FilmCameraTarget := StartPosition
            else
            begin
              Vector.X := Vector.X / Distance;
              Vector.Y := Vector.Y / Distance;
              Distance := Math.Min(Distance, GiScalePixels(600));
              FilmCameraTarget.X := StartPosition.X + Vector.X * Distance * 0.5;
              FilmCameraTarget.Y := StartPosition.Y + Vector.Y * Distance * 0.5;
            end;
          end;
        end;
        FilmCameraTargetKind := 1;
      end
      else
      begin
        FilmCameraTargetKind := 0;
        FilmCameraTargetUntilStep := FilmStepIndex + FilmCameraLookAheadSteps;
      end;
    end;
    if FilmCameraTargetKind = 0 then
    begin
      if (SpaceProcess.RadarCenter.X <> SecondaryFilm.CameraAnchor.X) or
         (SpaceProcess.RadarCenter.Y <> SecondaryFilm.CameraAnchor.Y) then
      begin
        Vector.X := (GameScreenWidth shr 1) - GiScalePixels(150);
        Vector.Y := (GameScreenHeight shr 1) - GiScalePixels(150);
        TopLeft := SubtractPointsF(SpaceProcess.RadarCenter, Vector);
        BottomRight := AddPointsF(SpaceProcess.RadarCenter, Vector);
        if SegmentIntersectsRectEdges(SpaceProcess.RadarCenter, SecondaryFilm.CameraAnchor, TopLeft, BottomRight, Vector) then
          FilmCameraTarget := Vector
        else FilmCameraTarget := SecondaryFilm.CameraAnchor;
      end
      else FilmCameraTarget := SpaceProcess.RadarCenter;
    end;
    if (FilmStepIndex <> 0) and FilmCameraFollow then
    begin
      Center := GetMapCenter;
      if (Center.X <> Round(FilmCameraPosition.X - FilmCameraShakeOffset.X)) or
         (Center.Y <> Round(FilmCameraPosition.Y - FilmCameraShakeOffset.Y)) then
      begin
        FilmCameraPosition.X := Center.X - FilmCameraShakeOffset.X;
        FilmCameraPosition.Y := Center.Y - FilmCameraShakeOffset.Y;
      end;
      Vector.X := FilmCameraTarget.X - FilmCameraPosition.X;
      Vector.Y := FilmCameraTarget.Y - FilmCameraPosition.Y;
      Distance := Sqrt(Sqr(Vector.X) + Sqr(Vector.Y));
      if Distance <= 2 then
      begin
        FilmCameraMoving := False;
        FilmCameraPosition := FilmCameraTarget;
      end
      else
      begin
        Vector.X := Vector.X / Distance;
        Vector.Y := Vector.Y / Distance;
        Speed := Math.Max(1, Distance * 0.1);
        if Speed > FilmCameraSpeed then Speed := Math.Min(Speed, FilmCameraSpeed * 1.1)
        else if Speed < FilmCameraSpeed then Speed := Math.Max(Speed, FilmCameraSpeed * 0.9);
        FilmCameraSpeed := Speed;
        FilmCameraPosition.X := FilmCameraPosition.X + Vector.X * Speed;
        FilmCameraPosition.Y := FilmCameraPosition.Y + Vector.Y * Speed;
      end;
      FilmCameraShakeOffset.X := Sin(FilmCameraShakeAngle) * GiScalePixels(30);
      FilmCameraShakeOffset.Y := -Cos(FilmCameraShakeAngle) * GiScalePixels(30);
      FilmCameraShakeAngle := FilmCameraShakeAngle + Pi / 256;
      SetMapCenter(Classes.Point(Round(FilmCameraPosition.X + FilmCameraShakeOffset.X),
        Round(FilmCameraPosition.Y + FilmCameraShakeOffset.Y)));
    end;
  end;
end;
{ @end $570AC0 }

{ @routine $571210 TfStarMap_CenterFilmShipClicked }
procedure TfStarMap.CenterFilmShipClicked(Sender: TObjectGI);
begin
  FilmCameraFollow := True;
  FilmCameraMoving := True;
end;
{ @end $571210 }

{ @routine $571224 TfStarMap_FilmMouseMove }
procedure TfStarMap.FilmMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if ScenarioState = scenAllianceAgainstRachekhan then Exit;
  if IsKlingMotherShipFollowActive then Exit;
  if Sender.IsOccludedAtPoint(Point) or ((KeyState and 2) = 2) then Exit;
  if (Point.X = 0) or (Point.Y = 0) or (Point.X = GameScreenWidth - 1) or (Point.Y = GameScreenHeight - 1) then
    ShowFilmObjectInfo(nil, 0)
  else if not ScrollLeftHeld and not ScrollRightHeld and not ScrollUpHeld and not ScrollDownHeld then
    RefreshFilmObjectInfoAtCursor;
end;
{ @end $571224 }

{ @routine $5712CC TfStarMap_RefreshFilmObjectInfoAtCursor }
procedure TfStarMap.RefreshFilmObjectInfoAtCursor;
var
  Point: TPoint;
  Obj: TEFilmObj;
  Scene: TObjectSE;
begin
  if PanelController.BackgroundImage.HitTestPixel(GetCursorPoint) then
  begin
    ShowFilmObjectInfo(nil, 0);
    Exit;
  end;
  Point := MapControls.ToLocalPoint(GetCursorPoint);
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is TShip2SE) and Scene.HitTestCursor then
    begin
      ShowFilmObjectInfo(Obj.SceneObject, Obj.ObjectId);
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is TContainerSE) and Scene.HitTestCursor then
    begin
      ShowFilmObjectInfo(Obj.SceneObject, Obj.ObjectId);
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is TRuinsSE) and Scene.HitTestCursor then
    begin
      ShowFilmObjectInfo(Obj.SceneObject, Obj.ObjectId);
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is TAsteroidSE) and Scene.HitTestCursor then
    begin
      ShowFilmObjectInfo(Obj.SceneObject, Obj.ObjectId);
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is TPlanetSE) then
      if Sqr(Point.X - Scene.Position.X) + Sqr(Point.Y - Scene.Position.Y) < Sqr((Scene as TPlanetSE).Radius) then
      begin
        ShowFilmObjectInfo(Scene, Obj.ObjectId);
        Exit;
      end;
    Obj := Obj.Next;
  end;
  if Sqr((SecondaryFilm.ObjectInfo as TEObjInfo).StarRadius) > Point.X * Point.X + Point.Y * Point.Y then
  begin
    Obj := SecondaryFilm.FirstObject;
    while Obj <> nil do
    begin
      Scene := Obj.SceneObject;
      if (Scene <> nil) and (Scene is TStarSE) then
      begin
        ShowFilmObjectInfo(Scene, Obj.ObjectId);
        Exit;
      end;
      Obj := Obj.Next;
    end;
  end;
  Obj := SecondaryFilm.FirstObject;
  while Obj <> nil do
  begin
    Scene := Obj.SceneObject;
    if (Scene <> nil) and (Scene is THoleSE) and Scene.HitTestCursor then
    begin
      ShowFilmObjectInfo(Obj.SceneObject, Obj.ObjectId);
      Exit;
    end;
    Obj := Obj.Next;
  end;
  ShowFilmObjectInfo(nil, 0);
end;
{ @end $5712CC }

{ @routine $571598 TfStarMap_ShowFilmObjectInfo }
procedure TfStarMap.ShowFilmObjectInfo(Obj: TObjectSE; ObjectId: Cardinal);
var
  I, J, RowHeight, RowX: Integer;
  IconInset: Cardinal;
  Planet: PEPlanetInfo;
  Ship: PEShipInfo;
  Item: PEItemInfo;
  Asteroid: PEAsteroidInfo;
  Text: WideString;
  Panel: TPanelGI;
  Objects, Records: TList;
  Distance: Single;
  OwnerId: TOwnerId;
  Snapshot: TEObjInfo;
  FilmObject: TEFilmObj;
  ImagePath, ColorTag: WideString;
begin
  Item := nil;
  Asteroid := nil;
  Planet := nil;
  Ship := nil;
  Snapshot := SecondaryFilm.ObjectInfo as TEObjInfo;
  if Obj <> nil then
  begin
    if Obj is TPlanetSE then Planet := (SecondaryFilm.ObjectInfo as TEObjInfo).FindPlanet(ObjectId);
    if (Obj is TShip2SE) or (Obj is TRuinsSE) then Ship := (SecondaryFilm.ObjectInfo as TEObjInfo).FindShip(ObjectId);
    if Obj is TContainerSE then Item := (SecondaryFilm.ObjectInfo as TEObjInfo).FindItem(ObjectId);
    if Obj is TAsteroidSE then Asteroid := (SecondaryFilm.ObjectInfo as TEObjInfo).FindAsteroid(ObjectId);
  end;
  if (Obj = nil) or ((Obj is TPlanetSE) and (Planet = nil)) or
     ((Obj is TShip2SE) and (Ship = nil)) or ((Obj is TRuinsSE) and (Ship = nil)) or
     ((Obj is TContainerSE) and (Item = nil)) or ((Obj is TAsteroidSE) and (Asteroid = nil)) then
  begin
    InfoWindow.SetActive(False);
    ItemInfoWindow.SetActive(False);
    ShipInfoPanel.SetActive(False);
    PlanetInfoPanel.SetActive(False);
    StarInfoWindow.SetActive(False);
    StandardInfoPanel.SetActive(False);
    DisplayedFilmObject := nil;
    Exit;
  end;
  if (Obj is TPlanetSE) or (Obj is THoleSE) or
     ((Obj is TContainerSE) and (PointDistance(Obj.Position, SpaceProcess.RadarCenter) > SecondaryFilm.RadarRange)) or
     (((Obj is TShip2SE) or (Obj is TRuinsSE)) and (PointDistance(Obj.Position, SpaceProcess.RadarCenter) > SecondaryFilm.RadarRange)) or
     ((Obj is TAsteroidSE) and (PointDistance(Obj.Position, SpaceProcess.RadarCenter) > SecondaryFilm.RadarRange)) then
  begin
    if DisplayedFilmObject <> Obj then
    begin
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(True);
      if Obj is TContainerSE then
      begin
        GetByName('InfoStdGB').SetActive(False);
        with GetByName('InfoStdImage') as TImageGI do
        begin
          SetActive(True);
          SetImagePath(Item^.ImagePath);
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        if Item^.ItemType in [t_Food..t_Narcotics] then
        begin
          (GetByName('InfoStdName') as TLabelGI).SetText(Item^.Name);
          (GetByName('InfoStdText') as TLabelGI).SetText(Item^.InfoText);
        end
        else
        begin
          (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(LocalizedText('FormInfo.ContainerName'), GreenColorTag));
          (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
        end;
        (GetByName('InfoItemSize') as TLabelGI).SetText('???');
        (GetByName('InfoItemPrice') as TLabelGI).SetText('???');
      end
      else if (Obj is TShip2SE) or (Obj is TRuinsSE) then
      begin
        if Obj is TShip2SE then
        begin
          GetByName('InfoStdImage').SetActive(False);

          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            ImagePath := Ship^.PortraitImage;
            SetActive(ImagePath <> '');
            if Active then
            begin
              SourceHasPerPixelAlpha := True;
              LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(ImagePath, 1, ','), GraphBuf);
              if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
                GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
              else
                GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
              SetImageKindX(ikxCenter);
              SetImageKindY(ikyCenter);
              SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
            end;
          end;
        end
        else
        begin
          GetByName('InfoStdImage').SetActive(False);
          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            SetActive(True);
            SourceHasPerPixelAlpha := True;
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((Obj as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);

            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(Ship^.FullName);
        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
      end
      else if Obj is TPlanetSE then
      begin
        if Planet^.OwnerId in CoalitionOwners then
        begin
          InfoWindow.SetActive(False);
          ItemInfoWindow.SetActive(False);
          ShipInfoPanel.SetActive(False);
          PlanetInfoPanel.SetActive(True);
          StarInfoWindow.SetActive(False);
          StandardInfoPanel.SetActive(False);
          (GetByName('InfoPlanetName') as TLabelGI).SetText(WrapTextInColor(Planet^.Name, GreenColorTag));
          if Planet^.OwnerId in CoalitionOwners then
          begin
            with GetByName('InfoPlanetEmRace') as TImageGI do
            begin
              SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Planet^.OwnerId].InternalName));
              SetImageKindX(ikxCenter);
              SetImageKindY(ikyCenter);
              SetActive(True);
            end;
          end
          else GetByName('InfoPlanetEmRace').SetActive(False);
          with GetByName('InfoPlanetImage') as TGraphBufGI do
          begin
            SourceHasPerPixelAlpha := True;
            (Obj as TPlanetSE).RenderToBuffer(Self, GraphBuf, False);
            GraphBuf.RescaleBilinearRgba(ClientSize.X, ClientSize.Y);
          end;
          (GetByName('InfoPlanetOwner') as TLabelGI).SetText(OwnerInfo[RaceToOwner(Planet^.RaceId)].DisplayName);
          (GetByName('InfoPlanetPop') as TLabelGI).SetText(IntToStr(Round(Planet^.Population / 1000)));
          (GetByName('InfoPlanetEco') as TLabelGI).SetText(PlanetEconomyInfo[Planet^.Economy].DisplayName);
          (GetByName('InfoPlanetGov') as TLabelGI).SetText(PlanetGovernmentMarket[Planet^.Government].DisplayName);
          (GetByName('InfoPlanetRel') as TLabelGI).SetText(RelationInfo[Planet^.Relation].DisplayName);
        end
        else
        begin
          GetByName('InfoStdImage').SetActive(False);
          with GetByName('InfoStdGB') as TGraphBufGI do
          begin
            SetActive(True);
            SourceHasPerPixelAlpha := True;
            (Obj as TPlanetSE).RenderToBuffer(Self, GraphBuf, False);
            GraphBuf.RescaleBilinearRgba(ClientSize.X, ClientSize.Y);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
          (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(Planet^.Name, GreenColorTag));
          if Planet^.OwnerId = oiKling then Text := LocalizedText('Planet.Kling.Info.TextAboutPlanet')
          else Text := LocalizedText('Planet.NotCivil.Info.TextAboutPlanet');
          (GetByName('InfoStdText') as TLabelGI).SetText(Text);
        end;
      end
      else if Obj is TAsteroidSE then
      begin
        GetByName('InfoStdImage').SetActive(False);
        with GetByName('InfoStdGB') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGaiFrameToGraphBuf((Obj as TAsteroidSE).ImagePath, GraphBuf, ObjectId);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(Asteroid^.Name, GreenColorTag));
        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.ObjOutOfRange'));
      end
      else if Obj is THoleSE then
      begin
        GetByName('InfoStdImage').SetActive(False);
        with GetByName('InfoStdGB') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGaiFrameToGraphBuf((Obj as THoleSE).ImagePath, GraphBuf, ObjectId);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(LocalizedText('FormInfo.HoleName'), GreenColorTag));
        (GetByName('InfoStdText') as TLabelGI).SetText(LocalizedText('FormInfo.HoleText'));
      end;
      DisplayedFilmObject := Obj;
    end;
  end
  else if Obj is TContainerSE then
  begin
    if DisplayedFilmObject <> Obj then
    begin
      DisplayedFilmObject := Obj;
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(True);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(False);
      with GetByName('InfoItemImage') as TImageGI do
      begin
        SetImagePath(Item^.ImagePath);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
      end;
      (GetByName('InfoItemName') as TLabelGI).SetText(Item^.Name);
      (GetByName('InfoItemText') as TLabelGI).SetText(Item^.InfoText);
      (GetByName('InfoItemSize') as TLabelGI).SetText(IntToStr(Item^.Weight));
      (GetByName('InfoItemPrice') as TLabelGI).SetText(IntToStr(Item^.Cost));
      with GetByName('InfoItemEmRace') as TImageGI do
      begin
        SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Item^.OwnerId].InternalName));
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      with GetByName('InfoItemDurable') as TImageGI do
        SetSize(Classes.Point(Round(Item^.ConditionPercent / 100 * GetContentSize.X), ClientSize.Y));
    end;
  end
  else if (Obj is TShip2SE) or (Obj is TRuinsSE) then
  begin
    if DisplayedFilmObject <> Obj then
    begin
      DisplayedFilmObject := Obj;
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(True);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(False);
      (GetByName('InfoShipName') as TLabelGI).SetText(Ship^.FullName);
      if Ship^.OwnerId in [oiMaloc..oiGaal] then
      begin
        with GetByName('InfoShipEmRace') as TImageGI do
        begin
          SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Ship^.OwnerId].InternalName));
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
          SetActive(True);
        end;
      end
      else GetByName('InfoShipEmRace').SetActive(False);
      if Obj is TShip2SE then
      begin
        with GetByName('InfoShipImage2') as TGraphBufGI do
        begin
          ImagePath := Ship^.PortraitImage;
          SetActive(ImagePath <> '');
          if Active then
          begin
            SourceHasPerPixelAlpha := True;
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(ImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
            SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
          end;
        end;
      end
      else
      begin
        with GetByName('InfoShipImage2') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((Obj as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
      end;
      if Obj is TRuinsSE then
      begin
        (GetByName('ISType') as TLabelGI).SetActive(False);
        (GetByName('InfoShipType') as TLabelGI).SetActive(False);
      end
      else
      begin
        (GetByName('ISType') as TLabelGI).SetActive(True);
        (GetByName('InfoShipType') as TLabelGI).SetActive(True);
        (GetByName('InfoShipType') as TLabelGI).SetText(Ship^.TypeName);
      end;
      (GetByName('InfoShipSpeed') as TLabelGI).SetText(IntToStr(Ship^.Speed));
      // Native $572EA1 references the UTF-16 color tag at $5745FC.
      if Ship^.HullPoints <= Ship^.HullCapacity / 2 then ColorTag := YellowColorTag
      else ColorTag := '';
      if Ship^.HullPoints <= Ship^.HullCapacity then
        (GetByName('InfoShipSize') as TLabelGI).SetText(WrapTextInColor(IntToStr(Ship^.HullPoints), ColorTag) + '/' + IntToStr(Ship^.HullCapacity))
      else (GetByName('InfoShipSize') as TLabelGI).SetText(WrapTextInColor('???', ColorTag));
      (GetByName('InfoShipDef') as TLabelGI).SetText(Ship^.DefenseText);
      (GetByName('InfoShipRel') as TLabelGI).SetText(RelationInfo[Ship^.Relation].DisplayName);
      if Ship^.WinChance >= 0 then
      begin
        (GetByName('ISWin') as TLabelGI).SetActive(True);
        (GetByName('InfoShipWin') as TLabelGI).SetActive(True);
        (GetByName('InfoShipWin') as TLabelGI).SetText(IntToStr(Ship^.WinChance) + '%');
      end
      else
      begin
        (GetByName('ISWin') as TLabelGI).SetActive(False);
        (GetByName('InfoShipWin') as TLabelGI).SetActive(False);
      end;
      with GetByName('InfoShipDurable') as TImageGI do
      begin
        if Ship^.HullPoints <= Ship^.HullCapacity then
          SetSize(Classes.Point(Round(Ship^.HullPoints / Ship^.HullCapacity * GetContentSize.X), ClientSize.Y))
        else SetSize(Classes.Point(Round(1 * GetContentSize.X), ClientSize.Y));
      end;
    end;
  end
  else if Obj is TStarSE then
  begin
    if DisplayedFilmObject <> Obj then
    begin
      DisplayedFilmObject := Obj;
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(True);
      StandardInfoPanel.SetActive(False);
      (GetByName('InfoStarName') as TLabelGI).SetText(WrapTextInColor((SecondaryFilm.ObjectInfo as TEObjInfo).StarName, GreenColorTag));
      with GetByName('InfoStarImage') as TGraphBufGI do
      begin
        SourceHasPerPixelAlpha := True;
        LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((Obj as TStarSE).StaticImagePath, 1, ','), GraphBuf);
        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleBilinearRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)))
        else GraphBuf.RescaleBilinearRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      Panel := GetByName('InfoStarPanel') as TPanelGI;
      Panel.FreeOwnedChildren;
      Objects := TList.Create;
      Records := TList.Create;
      FilmObject := SecondaryFilm.FirstObject;
      while FilmObject <> nil do
      begin
        if FilmObject.SceneObject <> nil then
          if FilmObject.SceneObject is TPlanetSE then
          begin
            Planet := Snapshot.FindPlanet(FilmObject.ObjectId);
            if Planet <> nil then
            begin
              Objects.Add(FilmObject.SceneObject);
              Records.Add(Planet);
            end;
          end;
        FilmObject := FilmObject.Next;
      end;
      FilmObject := SecondaryFilm.FirstObject;
      while FilmObject <> nil do
      begin
        if FilmObject.SceneObject <> nil then
          if FilmObject.SceneObject is TRuinsSE then
          begin
            Ship := Snapshot.FindShip(FilmObject.ObjectId);
            if Ship <> nil then
            begin
              Distance := PointDistanceSquared(FilmObject.SceneObject.Position, MakePointF(0, 0));
              J := 0;
              while J < Objects.Count do
              begin
                if PointDistanceSquared(TObjectSE(Objects[J]).Position, MakePointF(0, 0)) > Distance then Break;
                Inc(J);
              end;
              Objects.Insert(J, FilmObject.SceneObject);
              Records.Insert(J, Ship);
            end;
          end;
        FilmObject := FilmObject.Next;
      end;
      RowHeight := GiScalePixels(20);
      for I := 0 to Objects.Count - 1 do
      begin
        with TLabelGI.Create(Panel) do
        begin
          SetFontName(HitPointFontName);
          SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
          SetSize(Classes.Point(Panel.ClientSize.X div 2 + 15, RowHeight));
          SetPosition(Classes.Point(0, RowHeight * I));
          SetWordWrapEnabled(False);
          SetTextAlignX(taxRight);
          SetTextAlignY(tayCenterEx);
          if TObject(Objects[I]) is TPlanetSE then SetText(PEPlanetInfo(Records[I])^.Name)
          else SetText(PEShipInfo(Records[I])^.Name);
        end;
        with TGraphBufGI.Create(Panel) do
        begin
          IconInset := 0;
          if TObject(Objects[I]) is TPlanetSE then
          begin
            if (TObject(Objects[I]) as TPlanetSE).Radius < 70 then IconInset := 4
            else if (TObject(Objects[I]) as TPlanetSE).Radius < 80 then IconInset := 3
            else if (TObject(Objects[I]) as TPlanetSE).Radius < 90 then IconInset := 2
            else if (TObject(Objects[I]) as TPlanetSE).Radius < 100 then IconInset := 1
            else IconInset := 0;
          end;
          SourceHasPerPixelAlpha := True;
          SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + 1 + (IconInset shr 1), RowHeight * I + 1 + (IconInset shr 1)));
          SetSize(Classes.Point(RowHeight - 2 - IconInset, RowHeight - 2 - IconInset));
          if TObject(Objects[I]) is TPlanetSE then
          begin
            TPlanetSE(Objects[I]).RenderToBuffer(Self, GraphBuf, True);
            GraphBuf.RescaleRgba(ClientSize.X, ClientSize.Y, 5);
          end
          else
          begin
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TRuinsSE(Objects[I]).StaticImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          end;
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
        if TObject(Objects[I]) is TPlanetSE then OwnerId := PEPlanetInfo(Records[I])^.OwnerId
        else OwnerId := PEShipInfo(Records[I])^.OwnerId;
        if OwnerId in [oiMaloc..oiKling] then
          with TGraphBufGI.Create(Panel) do
          begin
            SourceHasPerPixelAlpha := True;
            LoadBitmapPathAsRgba(ExtractDelimitedPartW(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[OwnerId].InternalName), 1, ',') + '?RGBA');
            SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1, RowHeight * I + 1));
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
          end;
        if (TObject(Objects[I]) is TPlanetSE) and (PEPlanetInfo(Records[I])^.OwnerId in CoalitionOwners) then
        begin
          RowX := Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1;
          with TImageGI.Create(Panel) do
          begin
            case PEPlanetInfo(Records[I])^.Relation of
              rlHostile: SetImagePath('GI,Bm.FormGalaxy.Face4');
              rlBad: SetImagePath('GI,Bm.FormGalaxy.Face3');
              rlNormal: SetImagePath('GI,Bm.FormGalaxy.Face2');
              rlGood: SetImagePath('GI,Bm.FormGalaxy.Face1');
              rlExcellent: SetImagePath('GI,Bm.FormGalaxy.Face0');
            else SetImagePath('GI,Bm.FormGalaxy.Face2');
            end;
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            SetPosition(Classes.Point(RowX + RowHeight + 2, RowHeight * I + 1));
          end;
          RowX := RowX + RowHeight + 2;
          if PEPlanetInfo(Records[I])^.Economy in [peAgriculture, peIndustrial] then
            with TImageGI.Create(Panel) do
            begin
              case PEPlanetInfo(Records[I])^.Economy of
                peAgriculture: SetImagePath('GI,Bm.FormGalaxy.EconAgrar');
                peIndustrial: SetImagePath('GI,Bm.FormGalaxy.EconIndustr');
              end;
              SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
              SetPosition(Classes.Point(RowX + RowHeight, RowHeight * I + 1));
            end;
        end;
      end;
      Panel.SetSize(Classes.Point(Panel.ClientSize.X, RowHeight * Objects.Count));
      StarInfoWindow.SetSize(Classes.Point(StarInfoWindow.ClientSize.X, Panel.LocalPosition.Y + RowHeight * Objects.Count + GiScalePixels(30)));
      StarInfoWindow.UpdateAutoGeometry;
      Objects.Free;
      Records.Free;
    end;
  end
  else if Obj is TAsteroidSE then
  begin
    if DisplayedFilmObject <> Obj then
    begin
      DisplayedFilmObject := Obj;
      InfoWindow.SetActive(False);
      ItemInfoWindow.SetActive(False);
      ShipInfoPanel.SetActive(False);
      PlanetInfoPanel.SetActive(False);
      StarInfoWindow.SetActive(False);
      StandardInfoPanel.SetActive(True);
        GetByName('InfoStdImage').SetActive(False);
        with GetByName('InfoStdGB') as TGraphBufGI do
        begin
          SetActive(True);
          SourceHasPerPixelAlpha := True;
          LoadGaiFrameToGraphBuf((Obj as TAsteroidSE).ImagePath, GraphBuf, ObjectId);

          if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
            GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
          else
            GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
        end;
        (GetByName('InfoStdName') as TLabelGI).SetText(WrapTextInColor(Asteroid^.Name, GreenColorTag));
        (GetByName('InfoStdText') as TLabelGI).SetText(Asteroid^.InfoText);
      end;
  end;
end;
{ @end $571598 }

{ @routine $5748CC TfStarMap_PrepareTalkDisplay }
procedure TfStarMap.PrepareTalkDisplay;
var
  Offset: TPoint;
begin
  FilmCameraMoving := True;
  if GiResourceVariant = 1 then
    Offset := Classes.Point(181 - (GameScreenWidth shr 1) - 16, 163 - (GameScreenHeight shr 1) - 16)
  else
    Offset := Classes.Point(232 - (GameScreenWidth shr 1) - 20, 209 - (GameScreenHeight shr 1) - 20);
  ShowObjectInfo(nil);
  if TalkShip <> nil then SetMapCenter(SubtractPoints(TruncatePointF(TalkShip.Position), Offset))
  else if (TalkPlanet <> nil) and (TalkPlanet.CurrentStar = Player.CurrentStar) then
    SetMapCenter(SubtractPoints(TruncatePointF(Player.Position), Offset));
  SpaceProcess.Space.DrawMinimap;
  SetCursorActive(False);
  DrawFrame;
  CaptureScreenBackground;
  SetCursorActive(True);
end;
{ @end $5748CC }

{ @routine $574A04 TfStarMap_WaitForTurnOrTalk }
procedure TfStarMap.WaitForTurnOrTalk;
var
  WaitResult: Cardinal;
  Events: array[0..1] of THandle;
  EventList: Pointer;
begin
  ResumeMode := 0;
  // Both dormant pointer tests are present in the native wait setup.
  if TurnCalculationThread.IdleEvent = 0 then
    if TurnCalculationThread.IdleEvent = 0 then ;
  SetEvent(TalkCompletedEvent);
  Events[0] := TurnCalculationThread.IdleEvent;
  Events[1] := TalkRequestEvent;
  EventList := @Events;
  WaitResult := WaitForMultipleObjects(Length(Events), EventList, False, INFINITE);
  if (TurnCalculationThread.IdleEvent = 0) or (WaitResult = WAIT_OBJECT_0) then
  begin
    if PlayerStarDayPrepared then StartOrderMode
    else
    begin
      if (Player <> nil) and not Player.InHyperspace then QueueGalaxyTurnCalculation;
      StartTurnFilm;
    end;
  end
  else if WaitResult = WAIT_FAILED then
    raise Exception.Create('Error GetLastError()=' + IntToStr(Int64(GetLastError)))
  else if WaitResult = WAIT_OBJECT_0 + 1 then
  begin
    PrepareTalkDisplay;
    TalkReturnScreenId := FormToId(Self);
    RequestedScreenId := screenTalk;
    RequestClose(1);
  end;
end;
{ @end $574A04 }

{ @routine $574B78 TfStarMap_SelectMusic }
procedure TfStarMap.SelectMusic;
begin
  if Player = nil then MusicManager.PlayCategory('Base')
  else if MusicInSpace then MusicManager.PlayCategory('StarMap')
  else MusicManager.RequestFadeOut;
end;
{ @end $574B78 }

end.

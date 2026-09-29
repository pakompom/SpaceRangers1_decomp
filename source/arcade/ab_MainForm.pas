unit ab_MainForm;
// Unit bracket (inferred): CODE 0x004FC658..0x005095C3; inclusive evidence, not full bounds.
// Native TfAB VMT +$0C is the software and Direct3D frame renderer.
interface
uses SE_Ship2, EC_Buf, GI_MessageLoop, GI_Panel, GI_PolyLine, EC_Struct, EC_BlockPar, Types, Classes, GI_GAI, GI_Label, aPath, ab_Space, SE_Space, GI_StarField, GI_Window, GI_GraphButton, GI_Image, EC_Thread, GI_GraphBuf, aItem, ab_Item, ab_Zone, ab_StopLine, fLoad;
type
  TArcadeHealthBarCorners = packed record // @size $20
    TopLeft: TPoint; // @offset $00
    TopRight: TPoint; // @offset $08
    BottomRight: TPoint; // @offset $10
    BottomLeft: TPoint; // @offset $18
  end;
  PArcadeHealthBarCorners = ^TArcadeHealthBarCorners;
  TArcadeMapColorHeader = packed record // @size $10
    CurrentColor: Integer; // @offset $00
    VariantCount: Integer; // @offset $04
    SelectedVariant: Integer; // @offset $08
    ByteSize: Integer; // @offset $0C
  end;
  PArcadeMapColorHeader = ^TArcadeMapColorHeader;
  TArcadeMapColorVariant = packed record // @size $08
    SequenceOffset: Integer; // @offset $00 Relative to the containing color header.
    AppearanceTag: Integer; // @offset $04
  end;
  PArcadeMapColorVariant = ^TArcadeMapColorVariant;
  TArcadeMapColorSequence = packed record // @size $08
    FrameIndex: Integer; // @offset $00
    FrameCount: Integer; // @offset $04 Followed by FrameCount packed 32-bit colors.
  end;
  PArcadeMapColorSequence = ^TArcadeMapColorSequence;

  TfAB = class(TMessageLoopGI) // @size $26C
  public
    function ScreenPointToSphere(Point: TPoint; var Longitude, PolarAngle: Double): Boolean; // @addr $500580
    procedure BeginBattleExit; // @addr $507388
    procedure UpdateExitProgress(Progress: Single); // @addr $507444
    procedure FinishCampaignTransition; // @addr $505E64
    procedure ClearBattle; // @addr $501F60
    procedure ShowVictory; // @addr $509184
    procedure PickUpItem(Item: TabItem); // @addr $508E68
    procedure SyncWeaponInventory; // @addr $508C1C
    procedure OpenShipEquipment(Sender: TObjectGI); // @addr $508B50
    procedure ShowItemInfo(Item: TabItem); // @addr $5083D8
    procedure DrawFrame; override; // @addr $5062CC
    procedure DrawShipHealthBars; // @addr $506018
    procedure InvalidateFrame; // @addr $505FA0
    procedure TimerTakt(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $50449C
    procedure ToggleWeaponGroup(Sender: TObjectGI); // @addr $501BBC
    procedure UpdateWeaponHighlights; // @addr $500DB8
    procedure ClearWeaponPanel; // @addr $500CDC
    procedure UpdateWeaponPanel; // @addr $500740
    procedure BattleMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4FF700
    procedure BattleRightMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4FF65C
    procedure BattleRightMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4FF530
    procedure BattleMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4FF26C
    procedure BattleMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $4FEE9C
    procedure BattleKeyUp(Sender: TObjectGI; Key: Cardinal); // @addr $4FED30
    procedure BattleKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $4FDCE8
    procedure RequestExit(Sender: TObjectGI); // @addr $4FDBFC
    procedure OnOpen; override; // @addr $4FCDD8
    procedure InitializeLayout; override; // @addr $4FC778
    procedure ScrollMapTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $505C64
    procedure WeaponMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $501D8C
    procedure WeaponButtonClick(Sender: TObjectGI); // @addr $501D84
    procedure WeaponSelect(Sender: TObjectGI); // @addr $501B7C
    procedure BeginMachpellaDialogTransition; // @addr $507370
    procedure AdvanceMapColors; // @addr $504420
    procedure TogglePause(Sender: TObjectGI); // @addr $501ED8
    procedure ToggleAutopilot(Sender: TObjectGI); // @addr $501E84
    procedure ResetBattleControls; // @addr $503494
    procedure OnClose; override; // @addr $4FDAE4
    procedure CloseVictory(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5094EC
    procedure SelectMusic; override; // @addr $509540
    procedure CancelCargoPickup; // @addr $508AE8
    procedure BeginMapTransition; // @addr $503564
    procedure ControlMouseLeave(Sender: TObjectGI); // @addr $50916C
    procedure ControlMouseEnter(Sender: TObjectGI); // @addr $509164
    procedure UpdateHelp(Sender: TObjectGI; Show: Boolean); // @addr $509138
    destructor Destroy; override; // @addr $4FC73C
    constructor Create; // @addr $4FC6F4
    MapPanel: TPanelGI; // @offset $B0
    WorldPanel: TPanelGI; // @offset $B4
    StarField: TStarFieldGI; // @offset $B8
    StartStarImage: TgaiGI; // @offset $BC
    EndStarImage: TgaiGI; // @offset $C0
    ItemPanel: TPanelGI; // @offset $C4
    ItemInfoWindow: TPanelGI; // @offset $C8
    AutoButton: TGraphButtonGI; // @offset $CC
    BattleHelpLabel: TLabelGI; // @offset $D0
    VictoryPanel: TPanelGI; // @offset $D4
    PlayerVisual: TShip2SE; // @offset $D8 Always a Ship2 visual.
    PlayerMapPosition: TPointF; // @offset $DC
    ShipPath: TSPath; // @offset $E4
    RouteSpaces: TList; // @offset $E8
    MapDragging: Boolean; // @offset $EC
    MapDragPosition: TPoint; // @offset $ED Native packed drag state, immediately after the flag.
    ScrollTimer: TCallbackTimerIdGI; // @offset $F8
    MapBackgroundPath: WideString; // @offset $FC
    PlayerPanel: TImageGI; // @offset $100
    PlayerHealthImage: TGraphBufGI; // @offset $104
    PlayerHealthFill: TImageGI; // @offset $108
    PlayerHealthHeight: Integer; // @offset $10C
    WeaponButtons: array[0..6] of TObjectGI; // @offset $110
    WeaponIcons: array[0..6] of TImageGI; // @offset $12C
    WeaponChargeImages: array[0..6] of TImageGI; // @offset $148
    WeaponImageWidth: Integer; // @offset $164
    PlayerHealthBottom: Integer; // @offset $168
    PlayButton: TGraphButtonGI; // @offset $16C
    PauseButton: TGraphButtonGI; // @offset $170
    WorldLines: TPolyLineGI; // @offset $174
    UpdateTimer: TCallbackTimerIdGI; // @offset $178
    WorldCenterX: Integer; // @offset $17C Screen projection center, ab_Polygon_ProjectVisiblePoints.
    WorldCenterY: Integer; // @offset $180
    BonusIcons: array[0..7] of TImageGI; // @offset $184
    BonusRings: array[0..7] of TgaiGI; // @offset $1A4
    CampaignWeapons: array[0..4] of TWeapon; // @offset $1C4
    ForwardKeyDown: Boolean; // @offset $1D8
    ReverseKeyDown: Boolean; // @offset $1D9
    BrakeKeyDown: Boolean; // @offset $1DA
    TurnLeftKeyDown: Boolean; // @offset $1DB
    TurnRightKeyDown: Boolean; // @offset $1DC
    PrimaryFireKeyDown: Boolean; // @offset $1DD
    SecondaryFireKeyDown: Boolean; // @offset $1DE
    GridLines: TList; // @offset $1E0
    EditorAction: Integer; // @offset $1E4 Editor mouse state: -1 rectangle selection; 0 idle; 1..5 point/zone manipulation.
    EditorInfoText: WideString; // @offset $1E8
    SelectionBounds: TRect; // @offset $1EC World-panel coordinates.
    procedure NormalizeWeaponSelection; // @addr $501DAC
    procedure ClearOverlaySegments; // @addr $5000FC
    procedure UpdateSelectionRectangle; // @addr $50012C
    procedure UpdateStopPointLinkPreview; // @addr $500300
    procedure UpdateZoneLinkPreview; // @addr $500440
    OverlaySegments: array[0..3] of PPolyLineSegmentGI; // @offset $1FC ClearOverlaySegments.
    DraggedStopPoint: PabStopPoint; // @offset $20C
    DragLongitude: Double; // @offset $210
    DragPolarAngle: Double; // @offset $218
    DraggedZone: PabZone; // @offset $220
    procedure ClearMap; // @addr $501FC4
    procedure SaveMap(Buffer: TBufEC); // @addr $502298
    procedure SaveMapFile(Path: WideString); // @addr $502324
    procedure LoadMap(Buffer: TBufEC; LoadPolygons: Boolean); // @addr $50200C
    procedure LoadMapResource(Path: WideString; LoadPolygons: Boolean); // @addr $50211C
    TransitionSpeed: Double; // @offset $228
    CampaignTransitionStarted: Boolean; // @offset $230
    CampaignLoadStarted: Boolean; // @offset $231
    CampaignLoadFinished: Boolean; // @offset $232
    procedure HideHelp; // @addr $509174
    procedure HideObjectInfo; // @addr $508364
    procedure ClearGrid; // @addr $5023E4
    CacheLoader: TCacheLoader; // @offset $234
    procedure BuildGrid; // @addr $50242C
    procedure EnterMapView; // @addr $5035C0
    procedure EnterCurrentSpace; // @addr $503914
    procedure ShowSpaceInfo(Space: TabSpace); // @addr $50752C
    DefeatCountdownTicks: Integer; // @offset $238
    CampaignLoadProgress: Single; // @offset $23C
    DepartureTurn: Integer; // @offset $240
    ArrivalTurn: Integer; // @offset $244
    InfoObject: TObject; // @offset $248
    CargoPickupItem: TabItem; // @offset $24C
    CargoPickupZone: PabZone; // @offset $250
    InitialRandomSeed: Cardinal; // @offset $254
    procedure AppendShipPathArc(Destination: TPointF); // @addr $506724
    procedure AppendShipPathLine(Destination: TPointF); // @addr $5069EC
    RandomSeed: Cardinal; // @offset $258
    ViewModeBeforeExit: TArcadeViewMode; // @offset $25C
    SimulationPaused: Boolean; // @offset $260
    VictoryTimer: TCallbackTimerIdGI; // @offset $264
    ListedObjects: TList; // @offset $268 Owned list of borrowed items.
    procedure WorldImageCycleComplete(Sender: TObjectGI); // @addr $506708
    function RandomRange(BoundA, BoundB: Integer): Integer; // @addr $509060
    function RandomFloat(BoundA, BoundB: Double): Double; // @addr $5090B4
    procedure ABSpaceBuild(GridSize: Integer; Angle: Single); // @addr $5026B8
    procedure AppendShipPath(Destination: TPointF); // @addr $506C68
    procedure BuildSpaceRoute(Route: TList; Origin, Destination: TabSpace); // @addr $506CDC
    procedure RebuildShipPath; // @addr $506EAC
    procedure BuildShipPathImages; // @addr $506F00
    procedure UpdateShipPathImages; // @addr $5071D8
    procedure ClearShipPath; // @addr $5072FC
  end;
implementation

// @unit-initialization $5095BC
// @unit-finalization $50958C

uses GR_Rect, GR_DirectX3D8, ab_Hit, abWall, fScore, fTalk, fStarMap, aCalc, SE_Process, SE_Ship2, ab_W, aScript, ab_Obj3D, Windows, GR_Music, GI_Main, ab_Object, EC_File, EC_CacheBuf, ab_Ship, ab_StopLine, ab_Zone, ab_Polygon, GI_GraphBuf, GI_GI, GI_Window, EC_Str, aGalaxy, aPlanet, aShip, aRuins, SE_Star, SE_Ruins, ab_ShipAI, aConst, fShip2, ab_WorldLine, ab_WorldImage, aMyFunction, Math, SysUtils, GR_Main, Globals, GlobalsV, ab_Global, GI_GAI, GI_MultiImage, aPlayer, aTranclucator, GI_MessageBox;
{ @routine $4FC6F4 TfAB_Create }
constructor TfAB.Create;
begin
  inherited Create;
  ListedObjects := TList.Create;
end;
{ @end $4FC6F4 }
{ @routine $4FC73C TfAB_Destroy }
destructor TfAB.Destroy;
begin
  if ListedObjects <> nil then
  begin
    ListedObjects.Free;
    ListedObjects := nil;
  end;
  inherited Destroy;
end;
{ @end $4FC73C }

{ @routine $4FC778 TfAB_InitializeLayout }
procedure TfAB.InitializeLayout;
var I: Integer;
begin
  inherited InitializeLayout;
  with GetByName('MainPanel') do
  begin
    KeyDownCallback := BattleKeyDown;
    KeyUpCallback := BattleKeyUp;
    LeftButtonDownCallback := BattleMouseDown;
    LeftButtonUpCallback := BattleMouseUp;
    RightButtonDownCallback := BattleRightMouseDown;
    RightButtonUpCallback := BattleRightMouseUp;
    MouseMoveCallback := BattleMouseMove;
  end;
  MapPanel := GetByName('Map') as TPanelGI;
  WorldPanel := GetByName('SE') as TPanelGI;
  StarField := GetByName('StarField') as TStarFieldGI;
  StartStarImage := GetByName('StarStart') as TgaiGI;
  EndStarImage := GetByName('StarEnd') as TgaiGI;
  ItemPanel := GetByName('PItem') as TPanelGI;
  ItemInfoWindow := GetByName('InfoItem') as TPanelGI;
  AutoButton := GetByName('ButAI') as TGraphButtonGI;
  AutoButton.DownCallback := ToggleAutopilot;
  AutoButton.UpCallback := ToggleAutopilot;
  AutoButton.HelpCallback := UpdateHelp;
  BattleHelpLabel := GetByName('LHelp') as TLabelGI;
  VictoryPanel := GetByName('PanelWin') as TPanelGI;
  with GetByName('ButShip') as TGraphButtonGI do
  begin
    UpCallback := OpenShipEquipment;
    HelpCallback := UpdateHelp;
  end;
  for I := 0 to 6 do
  begin
    if I <= 4 then
    begin
      WeaponButtons[I] := GetByName('W' + IntToStr(I)) as TGraphButtonGI;
      with WeaponButtons[I] as TGraphButtonGI do
      begin
        DownCallback := WeaponButtonClick;
        UpCallback := WeaponButtonClick;
        LeftButtonDownCallback := WeaponMouseDown;
      end;
    end
    else WeaponButtons[I] := GetByName('W' + IntToStr(I));
    WeaponIcons[I] := GetByName('W' + IntToStr(I) + 'I') as TImageGI;
    WeaponChargeImages[I] := GetByName('W' + IntToStr(I) + 'A') as TImageGI;
  end;
  WeaponImageWidth := WeaponIcons[0].ClientSize.X;
  PlayerPanel := GetByName('Player') as TImageGI;
  PlayerHealthImage := GetByName('PlayerI') as TGraphBufGI;
  PlayerHealthFill := GetByName('PlayerA') as TImageGI;
  PlayerHealthHeight := PlayerHealthFill.ClientSize.Y;
  PlayerHealthBottom := PlayerHealthFill.LocalPosition.Y;
  PlayButton := GetByName('ButPlay') as TGraphButtonGI;
  PlayButton.UpCallback := TogglePause;
  PlayButton.HelpCallback := UpdateHelp;
  PauseButton := GetByName('ButPause') as TGraphButtonGI;
  PauseButton.UpCallback := TogglePause;
  PauseButton.HelpCallback := UpdateHelp;
end;
{ @end $4FC778 }

{ @routine $4FCDD8 TfAB_OnOpen }
procedure TfAB.OnOpen;
var
  Ship, AlliedShip, EnemyShip: TabShip;
  Index: Integer;
begin
  if not MusicInHyper then MusicManager.RequestFadeOut;
  if Player <> nil then begin
    InitialRandomSeed := Player.TransitOriginStar.GenerationSeed * Player.CurrentStar.GenerationSeed * (Galaxy.CurrentTurn div 77 + 1783);
    RandomSeed := InitialRandomSeed;
  end else begin
    InitialRandomSeed := RandomIntRange(100000, MaxInt);
    RandomSeed := InitialRandomSeed;
  end;
  ArcadeFinalEncounter := False;
  ArcadeMapViewPosition := Classes.Point(0, 0);
  DefeatCountdownTicks := 150;
  GetByName('ButShip').SetActive(True);
  if Player <> nil then begin
    DepartureTurn := Galaxy.CurrentTurn;
    ArrivalTurn := DepartureTurn + (Player.OrderStateData and TravelDaysMask);
  end;
  GetByName('LInfo').SetActive(False);
  GetByName('PBmin').SetActive(False);
  GetByName('PBmax').SetActive(False);
  ShipPath := TSPath.Create;
  RouteSpaces := TList.Create;
  if ArcadeSpaceProcess <> nil then begin ArcadeSpaceProcess.Free; ArcadeSpaceProcess := nil; end;
  ArcadeSpaceProcess := TProcessSE.Create('Process.Normal');
  ArcadeSpaceProcess.RadarCenter := MakePointF(0, 0);
  ArcadeSpaceProcess.RadarRange := 0;
  ArcadeSpaceProcess.ActionRange := 0;
  ArcadeSpaceProcess.ActionColor := 0;
  ArcadeSpaceProcess.OpenSpace(WorldPanel, Self);
  SkipSavedPixelRestore := True;
  StarField.Stars.Clear;
  StarField.BackgroundScale := 8;
  WorldLines := TPolyLineGI.Create(MapPanel);
  WorldLines.SetDepth(200);
  WorldLines.NormalizeBounds := False;
  WorldLines.SetPosition(StarField.LocalPosition);
  WorldLines.SetSize(StarField.ClientSize);
  WorldLines.SetOrigin(StarField.OriginPoint);
  WorldLines.AutoRebuildBounds := True;
  WorldLines.SetPositionModeW(True);
  WorldLines.SetActive(True);
  WorldCenterX := MapPanel.ClientSize.X div 2;
  WorldCenterY := MapPanel.ClientSize.Y div 2;
  if Player = nil then begin
    PlayerVisual := CreateSpaceObjectByName('Ship2', 'Ship.People.Ranger', Classes.Point(0, 0)) as TShip2SE;
    PlayerVisual.SetSize(Classes.Point(GiScalePixels(64), GiScalePixels(64)));
  end else begin
    PlayerVisual := CreateSpaceObjectByName('Ship2', Player.Graphic.GraphKey, Classes.Point(0, 0)) as TShip2SE;
    PlayerVisual.SetSize(Classes.Point(Player.Graphic.Size.X, Player.Graphic.Size.Y));
  end;
  PlayerVisual.TailEmitIntervalMs := 10;
  PlayerVisual.SetAlpha(255);
  PlayerVisual.SetTailsActive(ShipTail <> 0);
  ab_Object_Clear;
  Ship := TabShipAI.Create;
  ab_Object_Add(Ship);
  PlayerArcadeShip := Ship;
  if Player = nil then Ship.CreateShipVisual('Ship.People.Ranger', 64)
  else begin
    if GiResourceVariant = 2 then Ship.CreateShipVisual(Player.Graphic.GraphKey, Player.Graphic.Size.X)
    else Ship.CreateShipVisual(Player.Graphic.GraphKey, Round((Player.Graphic.Size.X shl 10) / 800));
  end;
  Ship.MaxSpeed := 11;
  Ship.TurnSpeed := PlayerInitialTurnSpeed;
  Ship.Thrust := 0;
  if Player = nil then begin
    Ship.MaxHealth := 1000;
    Ship.Health := 1000;
    Ship.WeaponCount := 5;
    ab_Weapon_Initialize(@Ship.Weapons[0], t_TachionCleaver); Ship.Weapons[0].SlotData := 0;
    ab_Weapon_Initialize(@Ship.Weapons[1], t_VortexProjector); Ship.Weapons[1].SlotData := 1;
    ab_Weapon_Initialize(@Ship.Weapons[2], t_AbsoluteMatrix); Ship.Weapons[2].SlotData := 2;
    ab_Weapon_Initialize(@Ship.Weapons[3], t_HellWave); Ship.Weapons[3].SlotData := 131;
    ab_Weapon_Initialize(@Ship.Weapons[4], t_EyesOfMachpella); Ship.Weapons[4].SlotData := 132;
    Ship.PrimaryWeapon := -1;
    Ship.SecondaryWeapon := -1;
    NormalizeWeaponSelection;
  end else begin
    Ship.MaxHealth := Player.Hull.Weight;
    Ship.Health := Player.Hull.HullPoints;
    for Index := 0 to 4 do CampaignWeapons[Index] := nil;
    SyncWeaponInventory;
    for Index := 0 to Ship.WeaponCount - 1 do Ship.Weapons[Index].Ammo := Ship.Weapons[Index].MaxAmmo;
    Ship.PrimaryWeapon := -1;
    Ship.SecondaryWeapon := -1;
    NormalizeWeaponSelection;
  end;
  if Player = nil then begin
    Ship := TabShipAI.Create;
    ab_Object_Add(Ship);
    Ship.CreateShipVisual('Ship.Fei.Ranger', 64);
    Ship.MaxSpeed := 12; Ship.TurnSpeed := 4; Ship.Thrust := 0;
    Ship.Health := 500; Ship.MaxHealth := 500; Ship.WeaponCount := 1;
    ab_Weapon_Initialize(@Ship.Weapons[0], t_IndustrialLaser);
    Ship.PrimaryWeapon := 0;
    AlliedShip := Ship;
    Ship := TabShipAI.Create;
    ab_Object_Add(Ship);
    Ship.CreateShipVisual('Ship.Kling.K3', 60);
    Ship.MaxSpeed := 12; Ship.TurnSpeed := 4; Ship.Thrust := 0;
    Ship.Health := 500; Ship.MaxHealth := 500; Ship.WeaponCount := 2;
    ab_Weapon_Initialize(@Ship.Weapons[0], t_IndustrialLaser);
    ab_Weapon_Initialize(@Ship.Weapons[1], t_ZipGun);
    Ship.PrimaryWeapon := 0;
    EnemyShip := Ship;
    Ship := TabShipAI.Create;
    ab_Object_Add(Ship);
    Ship.CreateShipVisual('Ship.Kling.K0', 128);
    Ship.MaxSpeed := 8; Ship.TurnSpeed := 1.8; Ship.Thrust := 0;
    Ship.Health := 3000; Ship.MaxHealth := 3000; Ship.WeaponCount := 5;
    ab_Weapon_Initialize(@Ship.Weapons[0], t_IndustrialLaser);
    ab_Weapon_Initialize(@Ship.Weapons[1], t_GravitonBeamer);
    ab_Weapon_Initialize(@Ship.Weapons[2], t_AbsoluteMatrix);
    ab_Weapon_Initialize(@Ship.Weapons[3], t_HellWave);
    ab_Weapon_Initialize(@Ship.Weapons[4], t_EyesOfMachpella);
    Ship.PrimaryWeapon := 0;
    BossArcadeShip := Ship;
    Ship.Enemies.Add(AlliedShip); Ship.Enemies.Add(PlayerArcadeShip);
    EnemyShip.Enemies.Add(AlliedShip); EnemyShip.Enemies.Add(PlayerArcadeShip);
    AlliedShip.Enemies.Add(Ship); AlliedShip.Enemies.Add(EnemyShip);
    PlayerArcadeShip.Enemies.Add(Ship); PlayerArcadeShip.Enemies.Add(EnemyShip);
  end;
  if Player = nil then ABSpaceBuild(RandomIntRange(3, 8), HeadingDegreesToRadians(RandomRange(0, 355)))
  else begin
    if Player.Order = soEnterBlackHole then ABSpaceBuild(1, HeadingDegreesToRadians(PointBearingDegrees(Player.TransitOriginStar.Position, Player.CurrentStar.Position)))
    else ABSpaceBuild(Round(RemapClamped(PointDistance(Player.CurrentStar.Position, Player.TransitOriginStar.Position), 10, 50, 3, 8)),
      HeadingDegreesToRadians(PointBearingDegrees(Player.TransitOriginStar.Position, Player.CurrentStar.Position)));
  end;
  ForwardKeyDown := False; ReverseKeyDown := False; BrakeKeyDown := False;
  TurnLeftKeyDown := False; TurnRightKeyDown := False; PrimaryFireKeyDown := False; SecondaryFireKeyDown := False;
  ArcadeEditorMode := False;
  ArcadeRoutePlaying := False;
  ArcadeTransitionShiftHeld := False;
  PlayButton.SetActive(not ArcadeRoutePlaying);
  PauseButton.SetActive(ArcadeRoutePlaying);
  CampaignTransitionStarted := False; CampaignLoadStarted := False; CampaignLoadFinished := False;
  CacheLoader := nil;
  if Player <> nil then begin
    RunStarTransitionScript(Player.CurrentStar, 2);
    CacheLoader := TCacheLoader.Create;
  end;
  if (Player <> nil) and (Player.Order = soEnterBlackHole) then begin
    CurrentArcadeSpace := NextArcadeSpace;
    ArcadeMapViewPosition := CurrentArcadeSpace.MapPosition;
    EnterCurrentSpace;
    SelectMusic;
  end else EnterMapView;
  ArcadeTickCount := 0;
  UpdateTimer := ScheduleCallbackTimer(20, 20, TimerTakt);
  ScrollTimer := ScheduleCallbackTimer(ScrollTime, ScrollTime, ScrollMapTimer);
  with PlayerHealthImage do begin
    SetActive(Player <> nil);
    if Active = True then begin
      SourceHasPerPixelAlpha := True;
      LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(Player.GetShipPortraitImagePath, 1, ','), GraphBuf);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
        GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
      else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
      SetImageKindX(ikxCenter); SetImageKindY(ikyCenter);
    end;
  end;
  TimerTakt(0, 0);
  HideHelp;
end;
{ @end $4FCDD8 }

{ @routine $4FDAE4 TfAB_OnClose }
procedure TfAB.OnClose;
begin
  ClearShipPath;
  ClearBattle;
  ab_Space_Clear;
  if CacheLoader <> nil then
  begin
    CacheLoader.ClearFlag18;
    CacheLoader.Free;
    CacheLoader := nil;
  end;
  if PlayerVisual <> nil then
  begin
    PlayerVisual.Free;
    PlayerVisual := nil;
  end;
  if ScrollTimer <> 0 then
  begin
    CancelCallbackTimer(ScrollTimer);
    ScrollTimer := 0;
  end;
  if UpdateTimer <> 0 then
  begin
    CancelCallbackTimer(UpdateTimer);
    UpdateTimer := 0;
  end;
  if WorldLines <> nil then
  begin
    WorldLines.Free;
    WorldLines := nil;
  end;
  if ArcadeSpaceProcess <> nil then
  begin
    ArcadeSpaceProcess.Free;
    ArcadeSpaceProcess := nil;
  end;
  if ShipPath <> nil then
  begin
    ShipPath.Free;
    ShipPath := nil;
  end;
  if RouteSpaces <> nil then
  begin
    RouteSpaces.Free;
    RouteSpaces := nil;
  end;
  if ArcadeMapColorBuffer <> nil then
  begin
    ArcadeMapColorBuffer.Free;
    ArcadeMapColorBuffer := nil;
  end;
  CloseVictory(0, 0);
end;
{ @end $4FDAE4 }

{ @routine $4FDBFC TfAB_RequestExit }
procedure TfAB.RequestExit(Sender: TObjectGI);
begin
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormGameMenu.QExit'), mbgOK or mbgCancel) = mbgResultOK then begin
    if CacheLoader <> nil then CacheLoader.ClearFlag18;
    ClearShipPath;
    PlayerArcadeShip := nil;
    ab_Object_Clear;
    if Galaxy <> nil then begin
      Galaxy.Free;
      Galaxy := nil;
    end;
    RequestedScreenId := screenMainMenu;
    RequestClose(1);
    BreakUiMessage;
  end;
end;
{ @end $4FDBFC }

{ @routine $4FDCE8 TfAB_BattleKeyDown }
procedure TfAB.BattleKeyDown(Sender: TObjectGI; Key: Cardinal);
var
  Step, Longitude, PolarAngle: Double;
  StopPoint, RemovedPoint: PabStopPoint;
  StopLine: PabStopLine;
  Zone: PabZone;
  Link: PabZoneLink;
  Button: TObjectGI;
  Polygon: PabPolygon;
  Index, ColorKind: Integer;
begin
  CancelCargoPickup;
  if (Key = VK_ESCAPE) and VictoryPanel.Active then begin
    CloseVictory(0, 0);
    Exit;
  end;
  if (Key = Ord('E')) and (ArcadeViewMode = avmSpace) and IsVirtualKeyDown(VK_CONTROL) and
    IsVirtualKeyDown(VK_SHIFT) and IsVirtualKeyDown(VK_MENU) then begin
    ArcadeEditorMode := not ArcadeEditorMode;
    ForwardKeyDown := False;
    ReverseKeyDown := False;
    BrakeKeyDown := False;
    TurnLeftKeyDown := False;
    TurnRightKeyDown := False;
    PrimaryFireKeyDown := False;
    SecondaryFireKeyDown := False;
    EditorAction := 0;
    SelectedStopPoint := nil;
    SelectedStopLine := nil;
    SelectedZone := nil;
    SelectedZoneLink := nil;
    StopPoint := FirstStopPoint;
    while StopPoint <> nil do begin
      ab_StopPoint_ClearSegments(StopPoint);
      StopPoint := StopPoint.Next;
    end;
    StopLine := FirstStopLine;
    while StopLine <> nil do begin
      ab_StopLine_ClearSegments(StopLine);
      StopLine := StopLine.Next;
    end;
    Zone := FirstZone;
    while Zone <> nil do begin
      ab_Zone_ClearSegments(Zone);
      Zone := Zone.Next;
    end;
    Link := FirstZoneLink;
    while Link <> nil do begin
      ab_ZoneLink_ClearSegments(Link);
      Link := Link.Next;
    end;
    ClearOverlaySegments;
    if ArcadeEditorMode then ab_Zone_UpdateAllImages else ab_Zone_ClearImages;
    if ArcadeEditorMode then ab_ZoneLink_UpdateAllImages else ab_ZoneLink_ClearImages;
    if ArcadeEditorMode then ab_StopPoint_UpdateImages else ab_StopPoint_ClearImages;
    if not ArcadeEditorMode then ab_Zone_BuildAllRoutes;
    if not ArcadeEditorMode then ab_StopLine_BuildCollisionList;
    GetByName('LInfo').SetActive(ArcadeEditorMode);
    EditorInfoText := 'Editor';
  end;
  if IsVirtualKeyDown(VK_CONTROL) and IsVirtualKeyDown(VK_SHIFT) and IsVirtualKeyDown(VK_MENU) then begin
    if (Key = Ord('K')) and (Player = nil) and (PlayerArcadeShip <> nil) then
      for Index := 0 to PlayerArcadeShip.Enemies.Count - 1 do
        TabShip(PlayerArcadeShip.Enemies[Index]).ApplyDamage(TabShip(PlayerArcadeShip.Enemies[Index]).Health, nil, False);
    Exit;
  end;
  if not ArcadeEditorMode then begin
    if (PlayerArcadeShip <> nil) and (Key >= Ord('1')) and (Key <= Ord('5')) and IsVirtualKeyDown(VK_SHIFT) then begin
      Button := WeaponButtons[Key - Ord('1')];
      if not (Button as TGraphButtonGI).Disabled then ToggleWeaponGroup(Button);
    end
    else if (PlayerArcadeShip <> nil) and (Key >= Ord('1')) and (Key <= Ord('5')) then begin
      if Integer(Key - Ord('1')) < 5 then WeaponSelect(WeaponButtons[Key - Ord('1')]);
    end
    else if (Key = VK_SPACE) and (ArcadeViewMode = avmMap) then begin
      ArcadeRoutePlaying := not ArcadeRoutePlaying;
      PlayButton.SetActive(not ArcadeRoutePlaying);
      PauseButton.SetActive(ArcadeRoutePlaying);
      ArcadeTransitionShiftHeld := IsVirtualKeyDown(VK_SHIFT);
    end
    else if (Key = VK_RETURN) and (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) and
      (CurrentArcadeSpace <> EndArcadeSpace) and (CurrentArcadeSpace <> EndArcadeSpace) then EnterCurrentSpace
    else if (Key = Ord('C')) and (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) then
      ArcadeMapViewPosition := TruncatePointF(PlayerMapPosition)
    else if (Key = Ord('Q')) and (Player = nil) then begin
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[0], t_PhotonGun);
      PlayerArcadeShip.Weapons[0].SlotData := 0;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[1], t_IndustrialLaser);
      PlayerArcadeShip.Weapons[1].SlotData := 1;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[2], t_ZipGun);
      PlayerArcadeShip.Weapons[2].SlotData := 2;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[3], t_GravitonBeamer);
      PlayerArcadeShip.Weapons[3].SlotData := 131;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[4], t_Retractor);
      PlayerArcadeShip.Weapons[4].SlotData := 132;
      NormalizeWeaponSelection;
      UpdateWeaponPanel;
    end
    else if (Key = Ord('W')) and (Player = nil) then begin
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[0], t_KellersPhaser);
      PlayerArcadeShip.Weapons[0].SlotData := 0;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[1], t_AeonicBlaster);
      PlayerArcadeShip.Weapons[1].SlotData := 1;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[2], t_XDefibrillator);
      PlayerArcadeShip.Weapons[2].SlotData := 2;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[3], t_SubmesonicGun);
      PlayerArcadeShip.Weapons[3].SlotData := 131;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[4], t_FieldAnnihilator);
      PlayerArcadeShip.Weapons[4].SlotData := 132;
      NormalizeWeaponSelection;
      UpdateWeaponPanel;
    end
    else if (Key = Ord('E')) and (Player = nil) then begin
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[0], t_TachionCleaver);
      PlayerArcadeShip.Weapons[0].SlotData := 0;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[1], t_VortexProjector);
      PlayerArcadeShip.Weapons[1].SlotData := 1;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[2], t_AbsoluteMatrix);
      PlayerArcadeShip.Weapons[2].SlotData := 2;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[3], t_HellWave);
      PlayerArcadeShip.Weapons[3].SlotData := 131;
      ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[4], t_EyesOfMachpella);
      PlayerArcadeShip.Weapons[4].SlotData := 132;
      NormalizeWeaponSelection;
      UpdateWeaponPanel;
    end
    else if (Key = VK_SPACE) and (ArcadeViewMode = avmMap) and (CurrentArcadeSpace = NextArcadeSpace) then
      EnterCurrentSpace;
  end;
  if Key = VK_UP then begin
    ForwardKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_DOWN then begin
    ReverseKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if (Key = VK_SPACE) or (Key = VK_SHIFT) then begin
    SecondaryFireKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_LEFT then begin
    TurnLeftKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_RIGHT then begin
    TurnRightKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_CONTROL then begin
    PrimaryFireKeyDown := True;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_ESCAPE then begin
    RequestExit(nil);
    Exit;
  end
  else if Key = Ord('A') then begin
    AutoButton.SetDown(not AutoButton.Down);
    ToggleAutopilot(nil);
  end
  else if (Key = Ord('S')) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_CONTROL) then
    OpenShipEquipment(nil)
  else if (Key = Ord('P')) or (Key = VK_PAUSE) then SimulationPaused := not SimulationPaused;
  if ArcadeEditorMode then begin
    if Key = Ord('P') then begin
      if EditorAction = 0 then
        if ScreenPointToSphere(GetCursorPoint, Longitude, PolarAngle) then begin
          StopPoint := ab_StopPoint_Add;
          StopPoint.Longitude := Longitude;
          StopPoint.PolarAngle := PolarAngle;
          StopPoint.Kind := 1;
          StopPoint.Selected := False;
          ab_StopPoint_UpdatePosition(StopPoint);
          ab_StopPoint_UpdateImages;
          if (SelectedStopPoint <> nil) and not SelectedStopPoint.Selected then ab_StopPoint_ClearSegments(SelectedStopPoint);
          SelectedStopPoint := StopPoint;
          ab_StopPoint_DrawSelection(StopPoint);
        end;
    end
    else if Key = Ord('Z') then begin
      if EditorAction = 0 then
        if ScreenPointToSphere(GetCursorPoint, Longitude, PolarAngle) then begin
          Zone := ab_Zone_Add;
          Zone.Longitude := Longitude;
          Zone.PolarAngle := PolarAngle;
          Zone.Radius := 50;
          ab_Zone_UpdatePosition(Zone);
          ab_Zone_UpdateImages(Zone);
          // Clears the new zone's segments when an old selection exists.
          if SelectedZone <> nil then ab_Zone_ClearSegments(Zone);
          SelectedZone := Zone;
          ab_Zone_DrawSelection(Zone);
        end;
    end
    else if Key = VK_DELETE then begin
      if EditorAction = 0 then begin
        if SelectedStopLine <> nil then ab_StopLine_Delete(SelectedStopLine)
        else if SelectedZone <> nil then ab_Zone_Delete(SelectedZone)
        else if SelectedZoneLink <> nil then ab_ZoneLink_Delete(SelectedZoneLink)
        else begin
          StopPoint := FirstStopPoint;
          while StopPoint <> nil do begin
            RemovedPoint := StopPoint;
            StopPoint := StopPoint.Next;
            if RemovedPoint.Selected or (RemovedPoint = SelectedStopPoint) then ab_StopPoint_Delete(RemovedPoint);
          end;
        end;
      end;
    end
    else if (Key = Ord('W')) and ((GetAsyncKeyState(VK_CONTROL) and $8000) <> $8000) then begin
      if ArcadeGridMode = 0 then ArcadeGridMode := 1 else ArcadeGridMode := 0;
      BuildGrid;
    end
    else if Key = Ord('S') then begin
      if ShowMessageBoxGI(Self, 'Save in data\edit.map ?', mbgOK or mbgCancel) = mbgResultOK then SaveMapFile('data\edit.map');
    end
    else if Key = Ord('L') then begin
      if ShowMessageBoxGI(Self, 'Load style ?', mbgOK or mbgCancel) = mbgResultOK then ab_StopLine_UpdateWorldLines;
    end
    else if Key = VK_PRIOR then begin
      Step := 1;
      if (GetAsyncKeyState(VK_CONTROL) and $8000) = $8000 then Step := 10;
      SphereCameraDistance := Max(SphereRadius + 10, SphereCameraDistance - 20 * Step);
      EditorInfoText := Format('%f', [SphereCameraDistance]);
    end
    else if Key = VK_NEXT then begin
      Step := 1;
      if (GetAsyncKeyState(VK_CONTROL) and $8000) = $8000 then Step := 10;
      SphereCameraDistance := 20 * Step + SphereCameraDistance;
      EditorInfoText := Format('World radius = %f Camera radius = %f', [SphereRadius, SphereCameraDistance]);
    end
    else if Key = VK_HOME then begin
      SphereCameraDistance := SphereRadius + SphereNearCameraOffset;
      EditorInfoText := Format('World radius = %f Camera radius = %f', [SphereRadius, SphereCameraDistance]);
    end
    else if (Key = VK_SUBTRACT) or (Key = VK_ADD) then begin
      if Key = VK_SUBTRACT then Step := -10 else Step := 10;
      if (GetAsyncKeyState(VK_CONTROL) and $8000) = $8000 then Step := Step * 10;
      SphereCameraDistance := SphereRadius + Step + (SphereCameraDistance - SphereRadius);
      SphereRadius := SphereRadius + Step;
      ab_StopPoint_UpdatePosition(nil);
      ab_StopPoint_UpdateImages;
      ab_StopLine_UpdateWorldLines;
      ab_Zone_UpdateAllPositions;
      ab_Zone_UpdateAllImages;
      ab_ZoneLink_UpdateAllDistances;
      ab_ZoneLink_UpdateAllImages;
      BuildGrid;
      EditorInfoText := Format('World radius = %f Camera radius = %f', [SphereRadius, SphereCameraDistance]);
    end
    else if (Key >= Ord('1')) and (Key <= Ord('7')) and (SelectedZone <> nil) then begin
      SelectedZone.Kind := Key - Ord('1');
      ab_Zone_UpdateImages(SelectedZone);
    end
    else if (Key >= Ord('0')) and (Key <= Ord('9')) and ((GetAsyncKeyState(VK_CONTROL) and $8000) = $8000) then begin
    end
    else if ((Key = Ord('Q')) or (Key = Ord('W')) or (Key = Ord('E')) or (Key = Ord('R'))) and
      ((GetAsyncKeyState(VK_CONTROL) and $8000) = $8000) then begin
      ColorKind := 0;
      if Key = Ord('Q') then ColorKind := 0
      else if Key = Ord('W') then ColorKind := 1
      else if Key = Ord('E') then ColorKind := 2
      else if Key = Ord('R') then ColorKind := 3;
      if SelectedStopPoint <> nil then begin
        Polygon := ab_Polygon_FindByPoint(SelectedStopPoint);
        if Polygon <> nil then begin
          Polygon.EditorColorKind := ColorKind;
          if ColorKind = 1 then Polygon.EditorColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0)
          else if ColorKind = 2 then Polygon.EditorColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0)
          else if ColorKind = 3 then Polygon.EditorColor := CurrentPixelFormat.PackRgbBytes(0, 0, 255);
        end;
      end;
    end;
  end;
end;
{ @end $4FDCE8 }

{ @routine $4FED30 TfAB_BattleKeyUp }
procedure TfAB.BattleKeyUp(Sender: TObjectGI; Key: Cardinal);
begin
  CancelCargoPickup;
  if Key = VK_UP then begin
    ForwardKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_DOWN then begin
    ReverseKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if (Key = VK_SPACE) or (Key = VK_SHIFT) then begin
    SecondaryFireKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_LEFT then begin
    TurnLeftKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_RIGHT then begin
    TurnRightKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end
  else if Key = VK_CONTROL then begin
    PrimaryFireKeyDown := False;
    ArcadeLastInputTick := ArcadeTickCount;
    ArcadeAutopilotEnabled := False;
    AutoButton.SetDown(ArcadeAutopilotEnabled);
  end;
end;
{ @end $4FED30 }

{ @routine $4FEE9C TfAB_BattleMouseDown }
procedure TfAB.BattleMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Origin: TabSpace; Route: TList; Index: Integer;
begin
  CloseVictory(0, 0);
  if ArcadeEditorMode then begin
    if EditorAction = 0 then begin
      if SelectedZone <> nil then begin
        if IsVirtualKeyDown(VK_CONTROL) then EditorAction := 4
        else begin
          EditorAction := 5;
          DraggedZone := SelectedZone;
        end;
      end
      else if SelectedStopPoint = nil then begin
        Point := WorldPanel.ToLocalPoint(Point);
        SelectionBounds := Classes.Rect(Point.X, Point.Y, Point.X, Point.Y);
        EditorAction := -1;
      end
      else if ScreenPointToSphere(Point, DragLongitude, DragPolarAngle) then begin
        EditorAction := 2;
        DraggedStopPoint := SelectedStopPoint;
      end;
    end;
  end
  else if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) and (HoveredArcadeSpace <> nil) and
    not Sender.IsOccludedAtPoint(Point) then begin
    Origin := CurrentArcadeSpace;
    if (RouteSpaces.Count > 0) and IsVirtualKeyDown(VK_CONTROL) then Origin := RouteSpaces[RouteSpaces.Count - 1];
    if (HoveredArcadeSpace = CurrentArcadeSpace) and (CurrentArcadeSpace <> EndArcadeSpace) then
      EnterCurrentSpace
    else if (RouteSpaces.Count > 0) and (RouteSpaces[RouteSpaces.Count - 1] = HoveredArcadeSpace) then begin
      ArcadeRoutePlaying := True;
      PlayButton.SetActive(not ArcadeRoutePlaying);
      PauseButton.SetActive(ArcadeRoutePlaying);
      ArcadeTransitionShiftHeld := IsVirtualKeyDown(VK_SHIFT);
      HideObjectInfo;
    end
    else begin
      ClearShipPath;
      if not IsVirtualKeyDown(VK_CONTROL) then RouteSpaces.Clear;
      Route := TList.Create;
      BuildSpaceRoute(Route, Origin, HoveredArcadeSpace);
      if Route.Count > 0 then
        for Index := 0 to Route.Count - 1 do RouteSpaces.Add(Route[Index]);
      Route.Free;
      RebuildShipPath;
      BuildShipPathImages;
    end;
  end
  else if (ArcadeViewMode = avmSpace) and (CargoPickupItem <> nil) and (CargoPickupItem.BonusKind < 0) and
    (PlayerArcadeShip <> nil) and (PlayerArcadeShip.Health > 0) and (Player <> nil) then begin
    if (CargoPickupItem.Item.Weight <= Player.CargoFreeSpace) and
      (PlayerArcadeShip.DistanceTo(CargoPickupItem) < ManualCargoPickupDistance) and
      (Player.CargoHook <> nil) and not Player.CargoHook.BrokenFlag and
      (Player.CargoHook.PickupPower + 15 * (Ord(Player.HasActiveArtefact(t_ArtefactHook))) >= CargoPickupItem.Item.Weight) then begin
      PickUpItem(CargoPickupItem);
      CancelCargoPickup;
    end;
  end;
end;
{ @end $4FEE9C }

{ @routine $4FF26C TfAB_BattleMouseUp }
procedure TfAB.BattleMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var StopPoint: PabStopPoint; Link: PabZoneLink; Bounds: TRect; Position: TVector3D;
begin
  if ArcadeEditorMode then begin
    if EditorAction = -1 then begin
      if (Abs(SelectionBounds.Left - SelectionBounds.Right) < 2) and
        (Abs(SelectionBounds.Top - SelectionBounds.Bottom) < 2) then begin
        if IsVirtualKeyDown(VK_SHIFT) then begin
          if SelectedStopPoint <> nil then SelectedStopPoint.Selected := True;
        end
        else if IsVirtualKeyDown(VK_CONTROL) then begin
          if SelectedStopPoint <> nil then SelectedStopPoint.Selected := False;
        end
        else begin
          StopPoint := FirstStopPoint;
          while StopPoint <> nil do begin
            if StopPoint <> SelectedStopPoint then begin
              StopPoint.Selected := False;
              ab_StopPoint_ClearSegments(StopPoint);
            end;
            StopPoint := StopPoint.Next;
          end;
          if SelectedStopPoint <> nil then SelectedStopPoint.Selected := not SelectedStopPoint.Selected;
        end;
      end
      else begin
        if not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_CONTROL) then begin
          StopPoint := FirstStopPoint;
          while StopPoint <> nil do begin
            StopPoint.Selected := False;
            ab_StopPoint_ClearSegments(StopPoint);
            StopPoint := StopPoint.Next;
          end;
        end;
        Bounds.Left := Min(SelectionBounds.Left, SelectionBounds.Right);
        Bounds.Right := Max(SelectionBounds.Left, SelectionBounds.Right);
        Bounds.Top := Min(SelectionBounds.Top, SelectionBounds.Bottom);
        Bounds.Bottom := Max(SelectionBounds.Top, SelectionBounds.Bottom);
        StopPoint := FirstStopPoint;
        while StopPoint <> nil do begin
          Position := ProjectPointByMatrix(SphereProjectionMatrix, StopPoint.Position);
          if IsDepthBeforeSphereHorizon(Position.Z) and (Position.X >= Bounds.Left) and
            (Position.X < Bounds.Right) and (Position.Y >= Bounds.Top) and (Position.Y < Bounds.Bottom) then begin
            if IsVirtualKeyDown(VK_CONTROL) then begin
              StopPoint.Selected := False;
              ab_StopPoint_ClearSegments(StopPoint);
            end
            else StopPoint.Selected := True;
          end;
          StopPoint := StopPoint.Next;
        end;
      end;
      EditorAction := 0;
      ClearOverlaySegments;
    end
    else if EditorAction = 5 then begin
      EditorAction := 0;
      ClearOverlaySegments;
      if (SelectedZone <> nil) and (SelectedZone <> DraggedZone) and
        (ab_ZoneLink_Find(DraggedZone, SelectedZone) = nil) and
        (ab_ZoneLink_Find(SelectedZone, DraggedZone) = nil) then begin
        Link := ab_ZoneLink_Add;
        Link.First := DraggedZone;
        Link.Last := SelectedZone;
        ab_ZoneLink_UpdateDistance(Link);
        ab_ZoneLink_UpdateImages(Link);
      end;
    end
    else if EditorAction = 4 then EditorAction := 0;
    end;
end;
{ @end $4FF26C }

{ @routine $4FF530 TfAB_BattleRightMouseDown }
procedure TfAB.BattleRightMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if ArcadeEditorMode then begin
    if EditorAction = 0 then begin
      if SelectedZone <> nil then EditorAction := 3
      else if SelectedStopPoint <> nil then EditorAction := 1;
    end
    else if EditorAction = -1 then begin
      EditorAction := 0;
      ClearOverlaySegments;
    end
    else if EditorAction = 2 then begin
      EditorAction := 0;
      ClearOverlaySegments;
    end
    else if EditorAction = 5 then begin
      EditorAction := 0;
      ClearOverlaySegments;
    end;
  end
  else if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) and not ContentPanel.IsOccludedAtPoint(Point) then begin
    MapDragging := True;
    MapDragPosition := Point;
    if IsCursorImageSelected('Main') then SetCursorByName('Scroll');
  end;
end;
{ @end $4FF530 }

{ @routine $4FF65C TfAB_BattleRightMouseUp }
procedure TfAB.BattleRightMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if ArcadeEditorMode then begin
    if EditorAction = 1 then EditorAction := 0
    else if EditorAction = 3 then EditorAction := 0;
  end
  else if (ArcadeViewMode = avmMap) and MapDragging then begin
    MapDragging := False;
    if IsCursorImageSelected('Scroll') then SetCursorByName('Main');
  end;
end;
{ @end $4FF65C }

{ @routine $4FF700 TfAB_BattleMouseMove }
procedure TfAB.BattleMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  TargetLongitude, TargetPolarAngle, Bearing, Distance, TravelBearing, ArcDistance, ItemDistance: Double;
  LocalPoint: TPoint;
  State: TSphericalBearingState;
  Position: TVector3D;
  StopPoint: PabStopPoint;
  Count: Integer;
  Space: TabSpace;
  Obj: TabObject;
begin
  if ArcadeEditorMode then begin
    if (EditorAction = 0) or (EditorAction = -1) or (EditorAction = 2) or (EditorAction = 5) then begin
      if EditorAction = -1 then begin
        SelectionBounds.BottomRight := WorldPanel.ToLocalPoint(Point);
        UpdateSelectionRectangle;
      end;
      if ScreenPointToSphere(Point, TargetLongitude, TargetPolarAngle) then begin
        if EditorAction = 2 then begin
          DragLongitude := TargetLongitude;
          DragPolarAngle := TargetPolarAngle;
          UpdateStopPointLinkPreview;
        end;
        if EditorAction = 5 then begin
          DragLongitude := TargetLongitude;
          DragPolarAngle := TargetPolarAngle;
          UpdateZoneLinkPreview;
        end;
        StopPoint := ab_StopPoint_FindAtAngles(TargetLongitude, TargetPolarAngle);
        if (StopPoint <> SelectedStopPoint) and (SelectedStopPoint <> nil) then begin
          if not SelectedStopPoint.Selected then ab_StopPoint_ClearSegments(SelectedStopPoint);
          SelectedStopPoint := nil;
        end;
        if StopPoint <> nil then SelectedStopPoint := StopPoint;
        if SelectedStopLine <> nil then begin
          ab_StopLine_ClearSegments(SelectedStopLine);
          SelectedStopLine := nil;
        end;
        if (SelectedStopPoint = nil) and (EditorAction = 0) then begin
          SelectedStopLine := ab_StopLine_FindAtAngles(TargetLongitude, TargetPolarAngle);
          if SelectedStopLine <> nil then ab_StopLine_DrawSelection(SelectedStopLine);
        end;
        if SelectedZone <> nil then begin
          ab_Zone_ClearSegments(SelectedZone);
          SelectedZone := nil;
        end;
        if (SelectedStopPoint = nil) and (SelectedStopLine = nil) and
          ((EditorAction = 0) or (EditorAction = 5)) then begin
          SelectedZone := ab_Zone_FindAtAngles(TargetLongitude, TargetPolarAngle);
          if SelectedZone <> nil then ab_Zone_DrawSelection(SelectedZone);
        end;
        if SelectedZoneLink <> nil then begin
          ab_ZoneLink_ClearSegments(SelectedZoneLink);
          SelectedZoneLink := nil;
        end;
        if (SelectedStopPoint = nil) and (SelectedStopLine = nil) and
          (SelectedZone = nil) and (EditorAction = 0) then begin
          SelectedZoneLink := ab_ZoneLink_FindAtAngles(TargetLongitude, TargetPolarAngle);
          if SelectedZoneLink <> nil then ab_ZoneLink_DrawSelection(SelectedZoneLink);
        end;
      end;
    end
    else if EditorAction = 3 then begin
      if ScreenPointToSphere(Point, TargetLongitude, TargetPolarAngle) then begin
        SelectedZone.Longitude := TargetLongitude;
        SelectedZone.PolarAngle := TargetPolarAngle;
        ab_Zone_UpdatePosition(SelectedZone);
        ab_Zone_UpdateImages(SelectedZone);
        ab_Zone_DrawSelection(SelectedZone);
        ab_ZoneLink_UpdateAllDistances;
        ab_ZoneLink_UpdateAllImages;
      end;
    end
    else if EditorAction = 4 then begin
      if ScreenPointToSphere(Point, TargetLongitude, TargetPolarAngle) then begin
        ComputeSphericalBearingAndDistance(SelectedZone.Longitude, SelectedZone.PolarAngle,
          0, TargetLongitude, TargetPolarAngle, SphereRadius, Bearing, Distance);
        SelectedZone.RadiusDegrees := Distance * 180 / (Pi * SphereRadius);
        ab_Zone_UpdatePosition(SelectedZone);
        ab_Zone_UpdateImages(SelectedZone);
      end;
    end
    else if EditorAction = 1 then begin
      if ScreenPointToSphere(Point, TargetLongitude, TargetPolarAngle) then begin
        Count := 1;
        StopPoint := FirstStopPoint;
        while StopPoint <> nil do begin
          if StopPoint.Selected and (StopPoint <> SelectedStopPoint) then Inc(Count);
          StopPoint := StopPoint.Next;
        end;
        if Count = 1 then begin
          SelectedStopPoint.Longitude := TargetLongitude;
          SelectedStopPoint.PolarAngle := TargetPolarAngle;
          ab_StopPoint_UpdatePosition(SelectedStopPoint);
          ab_StopPoint_UpdateImages;
          ab_StopLine_UpdateWorldLines;
        end
        else begin
          ComputeSphericalBearingAndDistance(SelectedStopPoint.Longitude, SelectedStopPoint.PolarAngle,
            0, TargetLongitude, TargetPolarAngle, SphereRadius, Bearing, Distance);
          if Bearing < 0 then Bearing := 360 + Bearing;
          StopPoint := FirstStopPoint;
          while StopPoint <> nil do begin
            if StopPoint.Selected and (StopPoint <> SelectedStopPoint) then begin
              ComputeSphericalBearingAndDistance(SelectedStopPoint.Longitude, SelectedStopPoint.PolarAngle,
                0, StopPoint.Longitude, StopPoint.PolarAngle, SphereRadius, TravelBearing, ArcDistance);
              if TravelBearing < 0 then TravelBearing := 360 + TravelBearing;
              State := AdvanceSphericalStateAlongBearing(MakeSphericalBearingState(SelectedStopPoint.Longitude,
                SelectedStopPoint.PolarAngle, Bearing), TravelBearing, ArcDistance);
              with AdvanceSphericalStateOnCurrentSphere(State, Distance) do begin
                StopPoint.Longitude := LongitudeDegrees;
                StopPoint.PolarAngle := PolarAngleDegrees;
              end;
              ab_StopPoint_UpdatePosition(StopPoint);
            end;
            StopPoint := StopPoint.Next;
          end;
          StopPoint := SelectedStopPoint;
          with AdvanceSphericalStateOnCurrentSphere(MakeSphericalBearingState(StopPoint.Longitude,
            StopPoint.PolarAngle, Bearing), Distance) do begin
            StopPoint.Longitude := LongitudeDegrees;
            StopPoint.PolarAngle := PolarAngleDegrees;
          end;
          ab_StopPoint_UpdatePosition(StopPoint);
          ab_StopPoint_UpdateImages;
          ab_StopLine_UpdateWorldLines;
        end;
      end;
    end;
  end
  else if MapDragging then begin
    if IsCursorImageSelected('Main') then SetCursorByName('Scroll');
    ArcadeMapViewPosition := Classes.Point(ArcadeMapViewPosition.X + MapDragPosition.X - Point.X,
      ArcadeMapViewPosition.Y + MapDragPosition.Y - Point.Y);
    MapDragPosition := Point;
    if ArcadeMapBounds.Top - ArcadeMapPanMargin > ArcadeMapViewPosition.Y then
      ArcadeMapViewPosition.Y := ArcadeMapBounds.Top - ArcadeMapPanMargin;
    if ArcadeMapBounds.Bottom + ArcadeMapPanMargin < ArcadeMapViewPosition.Y then
      ArcadeMapViewPosition.Y := ArcadeMapBounds.Bottom + ArcadeMapPanMargin;
    if ArcadeMapBounds.Left - ArcadeMapPanMargin > ArcadeMapViewPosition.X then
      ArcadeMapViewPosition.X := ArcadeMapBounds.Left - ArcadeMapPanMargin;
    if ArcadeMapBounds.Right + ArcadeMapPanMargin < ArcadeMapViewPosition.X then
      ArcadeMapViewPosition.X := ArcadeMapBounds.Right + ArcadeMapPanMargin;
    Exit;
  end
  else begin
    if (Point.X = 0) or (Point.Y = 0) or (GameScreenWidth - 1 = Point.X) or (GameScreenHeight - 1 = Point.Y) then begin
      if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) then begin
        SetCursorByName('Scroll');
        Exit;
      end;
    end
    else if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) then begin
      Point.X := Point.X - WorldCenterX + ArcadeMapViewPosition.X;
      Point.Y := Point.Y - WorldCenterY + ArcadeMapViewPosition.Y;
      HoveredArcadeSpace := nil;
      ArcDistance := 1E20;
      Space := FirstArcadeSpace;
      while Space <> nil do begin
        Distance := PointDistanceSquared(PointToPointF(Point), PointToPointF(Space.MapPosition));
        if (Distance < ArcDistance) and (Sqr(GiScalePixels(ArcadeMapNodeRadius)) > Distance) then begin
          ArcDistance := Distance;
          HoveredArcadeSpace := Space;
        end;
        Space := Space.Next;
      end;
      ShowSpaceInfo(HoveredArcadeSpace);
    end
    else if ArcadeViewMode = avmSpace then begin
      LocalPoint := WorldPanel.ToLocalPoint(Point);
      Obj := FirstArcadeObject;
      while Obj <> nil do begin
        if Obj is TabItem then begin
          Position := Obj.GetWorldPosition;
          Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
          if IsDepthBeforeSphereHorizon(Position.Z) then begin
            ItemDistance := Sqr(LocalPoint.X - Position.X) + Sqr(LocalPoint.Y - Position.Y);
            if ItemDistance < 256 then begin
              ShowItemInfo(TabItem(Obj));
              Break;
            end;
          end;
        end;
        Obj := Obj.Next;
      end;
      if Obj = nil then CancelCargoPickup;
    end;
  end;
  if IsCursorImageSelected('Scroll') then SetCursorByName('Main');
end;
{ @end $4FF700 }

{ @routine $5000FC TfAB_ClearOverlaySegments }
procedure TfAB.ClearOverlaySegments;
var
  Index: Integer;
begin
  for Index := 0 to 3 do
    if OverlaySegments[Index] <> nil then
    begin
      WorldLines.RetireSegment(OverlaySegments[Index]);
      OverlaySegments[Index] := nil;
    end;
end;
{ @end $5000FC }

{ @routine $50012C TfAB_UpdateSelectionRectangle }
procedure TfAB.UpdateSelectionRectangle;
var I: Integer;
begin
  for I := 0 to 3 do
    if OverlaySegments[I] = nil then begin
      OverlaySegments[I] := WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0), CurrentPixelFormat.PackRgbBytes(255, 0, 0));
      OverlaySegments[I].Animated := True;
    end;
  OverlaySegments[0].First := Classes.Point(SelectionBounds.Left, SelectionBounds.Top);
  OverlaySegments[0].Last := Classes.Point(SelectionBounds.Right, SelectionBounds.Top);
  WorldLines.UpdateSegmentLength(OverlaySegments[0]);
  OverlaySegments[1].First := Classes.Point(SelectionBounds.Right, SelectionBounds.Top);
  OverlaySegments[1].Last := Classes.Point(SelectionBounds.Right, SelectionBounds.Bottom);
  WorldLines.UpdateSegmentLength(OverlaySegments[1]);
  OverlaySegments[2].First := Classes.Point(SelectionBounds.Right, SelectionBounds.Bottom);
  OverlaySegments[2].Last := Classes.Point(SelectionBounds.Left, SelectionBounds.Bottom);
  WorldLines.UpdateSegmentLength(OverlaySegments[2]);
  OverlaySegments[3].First := Classes.Point(SelectionBounds.Left, SelectionBounds.Bottom);
  OverlaySegments[3].Last := Classes.Point(SelectionBounds.Left, SelectionBounds.Top);
  WorldLines.UpdateSegmentLength(OverlaySegments[3]);
end;
{ @end $50012C }

{ @routine $500300 TfAB_UpdateStopPointLinkPreview }
procedure TfAB.UpdateStopPointLinkPreview;
var
  Target: TVector3D;
begin
  if OverlaySegments[0] = nil then begin
    OverlaySegments[0] := WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0), CurrentPixelFormat.PackRgbBytes(255, 255, 0));
    OverlaySegments[0].Animated := True;
  end;
  Target := SphericalToVector3D(HeadingDegreesToRadians(DragLongitude), HeadingDegreesToRadians(DragPolarAngle), SphereRadius);
  with ProjectPointByMatrix(SphereProjectionMatrix, Target) do
    OverlaySegments[0].First := Classes.Point(Round(X), Round(Y));
  with ProjectPointByMatrix(SphereProjectionMatrix, DraggedStopPoint.Position) do begin
    OverlaySegments[0].Last := Classes.Point(Round(X), Round(Y));
    WorldLines.UpdateSegmentLength(OverlaySegments[0]);
  end;
end;
{ @end $500300 }

{ @routine $500440 TfAB_UpdateZoneLinkPreview }
procedure TfAB.UpdateZoneLinkPreview;
var
  Target: TVector3D;
begin
  if OverlaySegments[0] = nil then begin
    OverlaySegments[0] := WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0), CurrentPixelFormat.PackRgbBytes(0, 0, 255));
    OverlaySegments[0].Animated := True;
  end;
  Target := SphericalToVector3D(HeadingDegreesToRadians(DragLongitude), HeadingDegreesToRadians(DragPolarAngle), SphereRadius);
  with ProjectPointByMatrix(SphereProjectionMatrix, Target) do
    OverlaySegments[0].First := Classes.Point(Round(X), Round(Y));
  with ProjectPointByMatrix(SphereProjectionMatrix, DraggedZone.Position) do begin
    OverlaySegments[0].Last := Classes.Point(Round(X), Round(Y));
    WorldLines.UpdateSegmentLength(OverlaySegments[0]);
  end;
end;
{ @end $500440 }

{ @routine $500580 TfAB_ScreenPointToSphere }
function TfAB.ScreenPointToSphere(Point: TPoint; var Longitude, PolarAngle: Double): Boolean;
var
  Source, RayOrigin, RayDirection: TVector3D;
  Matrix: TMatrix4D;
begin
  Point := WorldPanel.ToLocalPoint(Point);
  Matrix := InvertMatrix4D(SpherePerspectiveMatrix);
  Source := MakeVector3D(Point.X, Point.Y, 1);
  Source := ProjectPointByMatrix(Matrix, Source);
  Matrix := InvertMatrix4D(SphereViewMatrix);
  RayDirection.X := Source.X * Matrix[0][0] + Source.Y * Matrix[1][0] + Source.Z * Matrix[2][0];
  RayDirection.Y := Source.X * Matrix[0][1] + Source.Y * Matrix[1][1] + Source.Z * Matrix[2][1];
  RayDirection.Z := Source.X * Matrix[0][2] + Source.Y * Matrix[1][2] + Source.Z * Matrix[2][2];
  RayOrigin.X := Matrix[3][0];
  RayOrigin.Y := Matrix[3][1];
  RayOrigin.Z := Matrix[3][2];
  Result := TryIntersectRayWithSphere(RayOrigin,
    MakeVector3D(RayOrigin.X + RayDirection.X, RayOrigin.Y + RayDirection.Y, RayOrigin.Z + RayDirection.Z),
    MakeVector3D(0, 0, 0), SphereRadius, RayOrigin);
  if not Result then Exit;
  VectorToSphericalAngles(RayOrigin, Longitude, PolarAngle);
end;
{ @end $500580 }

{ @routine $500740 TfAB_UpdateWeaponPanel }
procedure TfAB.UpdateWeaponPanel;
var Index, SlotIndex: Integer;
begin
  if (PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0) then
  begin
    if (PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0) then ClearWeaponPanel;
  end
  else
  begin
    Index := 0;
    while Index <= 4 do
    begin
      (WeaponButtons[Index] as TGraphButtonGI).SetDisabled(True);
      WeaponButtons[Index].SetActive(True);
      WeaponIcons[Index].SetActive(False);
      WeaponChargeImages[Index].SetActive(False);
      WeaponButtons[Index].UserValue := -1;
      Inc(Index);
    end;
    while Index <= 6 do
    begin
      WeaponButtons[Index].SetActive(False);
      WeaponIcons[Index].SetActive(False);
      WeaponChargeImages[Index].SetActive(False);
      WeaponButtons[Index].UserValue := -1;
      Inc(Index);
    end;
    Index := 0;
    while Index < PlayerArcadeShip.WeaponCount do
    begin
      SlotIndex := PlayerArcadeShip.Weapons[Index].SlotData and $7F;
      (WeaponButtons[SlotIndex] as TGraphButtonGI).SetDisabled(False);
      WeaponButtons[SlotIndex].SetActive(True);
      WeaponButtons[SlotIndex].HelpCallback := UpdateHelp;
      with WeaponIcons[SlotIndex] do
      begin
        SetActive(True);
        SetImagePath('GI,Bm.Items.' + GiResourceSuffix + ItemTypeNames[PlayerArcadeShip.Weapons[Index].ItemType] + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      with WeaponChargeImages[SlotIndex] do
      begin
        if (PlayerArcadeShip.Weapons[Index].SlotData and $80) <> 0 then
        begin
          SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF');
          WeaponButtons[SlotIndex].HelpText := ReplaceAllWideString(ReplaceAllWideString(LookupLocalizedTextByKey('Help.ABWeapon2'), '<SelectKey>', IntToStr(Index + 1)), '<WeaponName>', LocalizedText('Items.Weapon.Name.' + IntToStr(Ord(PlayerArcadeShip.Weapons[Index].ItemType) - Ord(t_PhotonGun) + 1)));
        end
        else
        begin
          SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF2');
          WeaponButtons[SlotIndex].HelpText := ReplaceAllWideString(ReplaceAllWideString(LookupLocalizedTextByKey('Help.ABWeapon1'), '<SelectKey>', IntToStr(Index + 1)), '<WeaponName>', LocalizedText('Items.Weapon.Name.' + IntToStr(Ord(PlayerArcadeShip.Weapons[Index].ItemType) - Ord(t_PhotonGun) + 1)));
        end;
        SetImageKindX(ikxLeft);
        WeaponChargeImages[SlotIndex].SetActive(True);
      end;
      Inc(Index);
    end;
    PlayerPanel.SetActive(True);
    AutoButton.SetActive(True);
    with PlayerHealthImage do SetActive(Player <> nil);
    PlayerHealthFill.SetActive(True);
    UpdateWeaponHighlights;
  end;
end;
{ @end $500740 }

{ @routine $500CDC TfAB_ClearWeaponPanel }
procedure TfAB.ClearWeaponPanel;
var I: Integer;
begin
  if WeaponButtons[0].Active then
  begin
    GetByName('ButShip').SetActive(False);
    for I := 0 to 6 do
    begin
      WeaponButtons[I].SetActive(False);
      WeaponIcons[I].SetActive(False);
      WeaponChargeImages[I].SetActive(False);
    end;
    PlayerPanel.SetActive(False);
    PlayerHealthImage.SetActive(False);
    PlayerHealthFill.SetActive(False);
    AutoButton.SetActive(False);
    for I := 0 to 7 do
      if BonusIcons[I] <> nil then
      begin
        BonusIcons[I].Free;
        BonusIcons[I] := nil;
        BonusRings[I].Free;
        BonusRings[I] := nil;
      end;
  end;
end;
{ @end $500CDC }

{ @routine $500DB8 TfAB_UpdateWeaponHighlights }
procedure TfAB.UpdateWeaponHighlights;
var I, Offset, Size, Slot: Integer; Position: TPoint; Angle: Single;
begin
  if (PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0) then
  begin
    if (PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0) then ClearWeaponPanel;
  end
  else
  begin
    I := 0;
    while I < PlayerArcadeShip.WeaponCount do
    begin
      Slot := PlayerArcadeShip.Weapons[I].SlotData and $7F;
      with WeaponChargeImages[Slot] do
      begin
        if (ArcadeTickCount and 3) = 0 then
        begin
          if PlayerArcadeShip.Weapons[I].Ammo < PlayerArcadeShip.Weapons[I].AmmoCost then
          begin
            SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF3');
            SetImageKindX(ikxLeft);
          end
          else if (PlayerArcadeShip.Weapons[I].SlotData and $80) <> 0 then
          begin
            SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF');
            SetImageKindX(ikxLeft);
          end
          else
          begin
            SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF2');
            SetImageKindX(ikxLeft);
          end;
        end;
        SetSize(Classes.Point(Round(PlayerArcadeShip.Weapons[I].Ammo / PlayerArcadeShip.Weapons[I].MaxAmmo * WeaponImageWidth), ClientSize.Y));
      end;
      (WeaponButtons[Slot] as TGraphButtonGI).SetDown((I = PlayerArcadeShip.PrimaryWeapon) or (I = PlayerArcadeShip.SecondaryWeapon));
      WeaponButtons[Slot].UserValue := I;
      Inc(I);
    end;
    with PlayerHealthFill do
    begin
      SetSize(Classes.Point(ClientSize.X, Round((1 - PlayerArcadeShip.Health / PlayerArcadeShip.MaxHealth) * PlayerHealthHeight)));
      SetPosition(Classes.Point(LocalPosition.X, PlayerHealthBottom + PlayerHealthHeight - ClientSize.Y));
    end;
    Size := GiScalePixels(64);
    for I := 0 to 7 do
    begin
      if PlayerArcadeShip.BonusTicks[I] <= 0 then
      begin
        if BonusIcons[I] <> nil then
        begin
          BonusIcons[I].Free;
          BonusIcons[I] := nil;
          BonusRings[I].Free;
          BonusRings[I] := nil;
          HideHelp;
        end;
      end
      else if BonusIcons[I] = nil then
      begin
        BonusIcons[I] := TImageGI.Create(ItemPanel);
        with BonusIcons[I] do
        begin
          SetImagePath('GI,Bm.ABItem.' + GiResourceSuffix + '_0' + IntToStr(I) + '_i');
          SetSize(Classes.Point(Size, ItemPanel.ClientSize.Y));
          SetDepth(0);
        end;
        BonusRings[I] := TgaiGI.Create(ItemPanel);
        with BonusRings[I] do
        begin
          SetImagePath('Bm.ABItem.' + GiResourceSuffix + '_Ring');
          SetSize(Classes.Point(Size, ItemPanel.ClientSize.Y));
          SequenceIndex := 0;
          UpdateAutoGeometry;
          SetMouseViewUpdates(True);
          MouseBlocking := True;
          StopAutoPlayback;
          SetDepth(1);
          HelpCallback := UpdateHelp;
          MouseEnterCallback := ControlMouseEnter;
          MouseLeaveCallback := ControlMouseLeave;
          if I = 0 then HelpText := LookupLocalizedTextByKey('Help.ABItemLife')
          else if I = 1 then HelpText := LookupLocalizedTextByKey('Help.ABItemFast')
          else if I = 2 then HelpText := LookupLocalizedTextByKey('Help.ABItemSlow')
          else if I = 3 then HelpText := LookupLocalizedTextByKey('Help.ABItemLock')
          else if I = 4 then HelpText := LookupLocalizedTextByKey('Help.ABItemDamage')
          else if I = 5 then HelpText := LookupLocalizedTextByKey('Help.ABItemReload')
          else if I = 6 then HelpText := LookupLocalizedTextByKey('Help.ABItemDefence')
          else if I = 7 then HelpText := LookupLocalizedTextByKey('Help.ABItemInvisible');
        end;
      end;
    end;
    Offset := 0;
    for I := 0 to 7 do
      if PlayerArcadeShip.BonusTicks[I] > 0 then
      begin
        BonusIcons[I].SetPosition(Classes.Point(Offset, 0));
        BonusRings[I].SetPosition(Classes.Point(Offset, 0));
        BonusRings[I].SetSequenceFrame(Round((1 - PlayerArcadeShip.BonusTicks[I] / (BonusDurationSeconds[I] * 20)) * BonusRings[I].SequenceFrameCount));
        Inc(Offset, Size);
      end;
    I := PlayerArcadeShip.PrimaryWeapon;
    Slot := 5;
    if (ArcadeViewMode <> avmSpace) or (I < 0) or not PlayerArcadeShip.PrimaryWeaponSwitchReady(I) or not PlayerArcadeShip.CanFireWeapon(I) then
    begin
      WeaponButtons[Slot].SetActive(False);
      WeaponIcons[Slot].SetActive(False);
      WeaponChargeImages[Slot].SetActive(False);
    end
    else
    begin
      Angle := HeadingDegreesToRadians(WrapHeadingDegrees(ByteToHeadingDegrees(PlayerArcadeShip.Visual.GetAngle) + 180 + 30));
      Position.X := WorldCenterX + Round(PlayerArcadeShip.Visual.Position.X + Sin(Angle) * GiScalePixels(50));
      Position.Y := WorldCenterY + Round(PlayerArcadeShip.Visual.Position.Y - Cos(Angle) * GiScalePixels(50));
      with WeaponButtons[Slot] do
      begin
        SetActive(True);
        SetPosition(Position);
      end;
      with WeaponIcons[Slot] do
      begin
        SetActive(True);
        SetImagePath('GI,Bm.Items.' + GiResourceSuffix + ItemTypeNames[PlayerArcadeShip.Weapons[I].ItemType] + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(Position);
      end;
      with WeaponChargeImages[Slot] do
      begin
        SetActive(True);
        SetSize(Classes.Point(Round(PlayerArcadeShip.Weapons[I].Ammo / PlayerArcadeShip.Weapons[I].MaxAmmo * WeaponImageWidth), ClientSize.Y));
        SetPosition(Position);
      end;
    end;
    I := PlayerArcadeShip.SecondaryWeapon;
    Slot := 6;
    if (ArcadeViewMode <> avmSpace) or (I < 0) or not PlayerArcadeShip.SecondaryWeaponSwitchReady(I) or not PlayerArcadeShip.CanFireWeapon(I) then
    begin
      WeaponButtons[Slot].SetActive(False);
      WeaponIcons[Slot].SetActive(False);
      WeaponChargeImages[Slot].SetActive(False);
    end
    else
    begin
      Angle := HeadingDegreesToRadians(WrapHeadingDegrees(ByteToHeadingDegrees(PlayerArcadeShip.Visual.GetAngle) + 180 - 30));
      Position.X := WorldCenterX + Round(PlayerArcadeShip.Visual.Position.X + Sin(Angle) * GiScalePixels(50));
      Position.Y := WorldCenterY + Round(PlayerArcadeShip.Visual.Position.Y - Cos(Angle) * GiScalePixels(50));
      with WeaponButtons[Slot] do
      begin
        SetActive(True);
        SetPosition(Position);
      end;
      with WeaponIcons[Slot] do
      begin
        SetActive(True);
        SetImagePath('GI,Bm.Items.' + GiResourceSuffix + ItemTypeNames[PlayerArcadeShip.Weapons[I].ItemType] + 's');
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
        SetPosition(Position);
      end;
      with WeaponChargeImages[Slot] do
      begin
        SetActive(True);
        SetSize(Classes.Point(Round(PlayerArcadeShip.Weapons[I].Ammo / PlayerArcadeShip.Weapons[I].MaxAmmo * WeaponImageWidth), ClientSize.Y));
        SetPosition(Position);
      end;
    end;
  end;
end;
{ @end $500DB8 }

{ @routine $501B7C TfAB_WeaponSelect }
procedure TfAB.WeaponSelect(Sender: TObjectGI);
var Index: Integer;
begin
  if PlayerArcadeShip <> nil then
  begin
    Index := Sender.UserValue;
    if (Index >= 0) and (Index <> PlayerArcadeShip.PrimaryWeapon) then
    begin
      PlayerArcadeShip.SelectWeapon(Index);
      UpdateWeaponHighlights;
    end;
  end;
end;
{ @end $501B7C }

{ @routine $501BBC TfAB_ToggleWeaponGroup }
procedure TfAB.ToggleWeaponGroup(Sender: TObjectGI);
var Index: Integer;
begin
  if PlayerArcadeShip <> nil then begin
    Index := Sender.UserValue;
    if Index >= 0 then begin
      PlayerArcadeShip.Weapons[Index].SlotData := PlayerArcadeShip.Weapons[Index].SlotData xor $80;
      with WeaponChargeImages[PlayerArcadeShip.Weapons[Index].SlotData and $7F] do begin
        if PlayerArcadeShip.Weapons[Index].SlotData and $80 <> 0 then
          SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF')
        else SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF2');
        SetImageKindX(ikxLeft);
      end;
      if Player <> nil then
        (Player.FindEquippedItemInSlot(WeaponCategoryItemType, PlayerArcadeShip.Weapons[Index].SlotData and $7F) as TWeapon).AssignedSlotData := PlayerArcadeShip.Weapons[Index].SlotData;
      NormalizeWeaponSelection;
      UpdateWeaponPanel;
      UpdateHelp(Sender, True);
    end;
  end;
end;
{ @end $501BBC }

{ @routine $501D84 TfAB_WeaponButtonClick }
procedure TfAB.WeaponButtonClick(Sender: TObjectGI);
begin
  UpdateWeaponHighlights;
end;
{ @end $501D84 }

{ @routine $501D8C TfAB_WeaponMouseDown }
procedure TfAB.WeaponMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  ToggleWeaponGroup(Sender);
end;
{ @end $501D8C }

{ @routine $501DAC TfAB_NormalizeWeaponSelection }
procedure TfAB.NormalizeWeaponSelection;
var
  Index: Integer;
begin
  if (PlayerArcadeShip.PrimaryWeapon >= 0) and
     ((PlayerArcadeShip.Weapons[PlayerArcadeShip.PrimaryWeapon].SlotData and $80) <> 0) then
    PlayerArcadeShip.PrimaryWeapon := -1;
  if PlayerArcadeShip.PrimaryWeapon < 0 then
    for Index := 0 to PlayerArcadeShip.WeaponCount - 1 do
      if (PlayerArcadeShip.Weapons[Index].SlotData and $80) = 0 then
      begin
        PlayerArcadeShip.PrimaryWeapon := Index;
        Break;
      end;
  if (PlayerArcadeShip.SecondaryWeapon >= 0) and
     ((PlayerArcadeShip.Weapons[PlayerArcadeShip.SecondaryWeapon].SlotData and $80) = 0) then
    PlayerArcadeShip.SecondaryWeapon := -1;
  if PlayerArcadeShip.SecondaryWeapon < 0 then
    for Index := 0 to PlayerArcadeShip.WeaponCount - 1 do
      if (PlayerArcadeShip.Weapons[Index].SlotData and $80) <> 0 then
      begin
        PlayerArcadeShip.SecondaryWeapon := Index;
        Break;
      end;
end;
{ @end $501DAC }

{ @routine $501E84 TfAB_ToggleAutopilot }
procedure TfAB.ToggleAutopilot(Sender: TObjectGI);
begin
  if AutoButton.Down and ArcadeEnemiesDefeated then AutoButton.SetDown(False);
  ArcadeLastInputTick := ArcadeTickCount;
  ArcadeAutopilotEnabled := False;
  ArcadeAutopilotEnabled := AutoButton.Down;
end;
{ @end $501E84 }

{ @routine $501ED8 TfAB_TogglePause }
procedure TfAB.TogglePause(Sender: TObjectGI);
begin
  HideObjectInfo;
  ArcadeTransitionShiftHeld := IsVirtualKeyDown(VK_SHIFT);
  ArcadeRoutePlaying := Sender = PlayButton;
  PlayButton.SetActive(not ArcadeRoutePlaying);
  PauseButton.SetActive(ArcadeRoutePlaying);
  if PlayButton.Active then UpdateHelp(PlayButton, True)
  else UpdateHelp(PauseButton, True);
  BreakUiMessage;
end;
{ @end $501ED8 }

{ @routine $501F60 TfAB_ClearBattle }
procedure TfAB.ClearBattle;
begin
  PlayerArcadeShip := nil;
  ab_Object_Clear;
  ClearGrid;
  ClearOverlaySegments;
  ab_Zone_ClearImages;
  ab_ZoneLink_ClearImages;
  ab_Polygon_Clear;
  ab_StopLine_Clear;
  ab_StopPoint_Clear;
  ab_WorldLine_Clear;
  ab_WorldImage_Clear;
  ab_Space_ClearImages;
  WorldLines.ClearSegments;
  ab_Obj3D_Clear;
  EditorAction := 0;
end;
{ @end $501F60 }

{ @routine $501FC4 TfAB_ClearMap }
procedure TfAB.ClearMap;
begin
  ClearGrid;
  ClearOverlaySegments;
  ab_Zone_ClearImages;
  ab_ZoneLink_ClearImages;
  ab_Polygon_Clear;
  ab_StopLine_Clear;
  ab_StopPoint_Clear;
  ab_WorldLine_Clear;
  ab_WorldImage_Clear;
  ab_Space_ClearImages;
  WorldLines.ClearSegments;
end;
{ @end $501FC4 }

{ @routine $50200C TfAB_LoadMap }
procedure TfAB.LoadMap(Buffer: TBufEC; LoadPolygons: Boolean);
begin
  ClearMap;
  if (Buffer = nil) or (Buffer.DataSize < 32) then
    ab_StopLine_AddLatitude(10, 10)
  else
  begin
    if Buffer.GetUInt32 <> $6D776261 then RaiseWideMessage('Incorrect format ABMap');
    ArcadeMapVersion := Buffer.GetUInt32;
    SphereRadius := Buffer.GetSingle;
    if ArcadeMapColorBuffer = nil then ArcadeMapColorBuffer := TBufEC.Create
    else ArcadeMapColorBuffer.Clear;
    ArcadeMapColorBuffer.SetSize(Buffer.GetInt32);
    Buffer.ReadBytes(ArcadeMapColorBuffer.Data, ArcadeMapColorBuffer.DataSize);
    ab_StopLine_Load(Buffer);
    ab_Zone_Load(Buffer);
    if LoadPolygons then ab_Polygon_Load(Buffer);
  end;
end;
{ @end $50200C }

{ @routine $50211C TfAB_LoadMapResource }
procedure TfAB.LoadMapResource(Path: WideString; LoadPolygons: Boolean);
var
  Control: TCBufControlEC;
  Data: TCBufEC;
begin
  Control := nil;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Path);
    Data := AcquireOrCreateBuffer(Control);
    LoadMap(Data.Buffer, LoadPolygons);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
  if LoadPolygons then
  begin
    Control := nil;
    try
      Control := TCBufControlEC.Create;
      GlobalCache.ResetControl(Control);
      Control.SetCacheKey(Path + '_');
      Data := AcquireOrCreateBuffer(Control);
      Data.Buffer.ExpandZlibPayloadInPlace;
      ab_Polygon_LoadVisibility(Data.Buffer);
    finally
      if Control <> nil then
      begin
        Control.Release;
        Control.Free;
      end;
    end;
  end;
  ab_StopPoint_ClearIndex;
end;
{ @end $50211C }

{ @routine $502298 TfAB_SaveMap }
procedure TfAB.SaveMap(Buffer: TBufEC);
begin
  Buffer.Clear;
  Buffer.AddDWord($6D776261);
  Buffer.AddDWord(ArcadeEditorMapVersion);
  Buffer.AddSingle(SphereRadius);
  Buffer.AddSingle(SphereCameraDistance);
  Buffer.AddSingle(SphereFieldOfView);
  Buffer.AddIntegerValue(ArcadeGridMode);
  ab_StopLine_Save(Buffer);
  ab_Polygon_Save(Buffer);
  ab_Zone_Save(Buffer);
end;
{ @end $502298 }

{ @routine $502324 TfAB_SaveMapFile }
procedure TfAB.SaveMapFile(Path: WideString);
var Buffer: TBufEC; Dest: TFileEC;
begin
  Buffer := TBufEC.Create;
  SaveMap(Buffer);
  Dest := TFileEC.Create;
  Dest.SetFileName(PAnsiChar(AnsiString(Path)));
  Dest.CreateNew;
  Buffer.SaveToFile(Dest);
  Dest.Free;
  Buffer.Free;
end;
{ @end $502324 }

{ @routine $5023E4 TfAB_ClearGrid }
procedure TfAB.ClearGrid;
var
  Index: Integer;
begin
  if GridLines = nil then Exit;
  for Index := 0 to GridLines.Count - 1 do
    ab_WorldLine_Delete(GridLines[Index]);
  GridLines.Free;
  GridLines := nil;
end;
{ @end $5023E4 }

{ @routine $50242C TfAB_BuildGrid }
procedure TfAB.BuildGrid;
var
  PolarAngle, Longitude, LongitudeStep, PolarStep: Double;
  First, Last: TVector3D;
begin
  ClearGrid;
  if (ArcadeGridMode <> 0) and (ArcadeViewMode = avmSpace) then
  begin
    GridLines := TList.Create;
    LongitudeStep := Pi / 8;
    PolarStep := Pi / 16;
    Longitude := 0;
    while Longitude < Pi * 2 - 0.001 do
    begin
      PolarAngle := PolarStep * 2;
      while PolarAngle < Pi - PolarStep * 2 - 0.001 do
      begin
        First := SphericalToVector3D(Longitude, PolarAngle, SphereRadius);
        Last := SphericalToVector3D(Longitude, PolarAngle + PolarStep, SphereRadius);
        GridLines.Add(ab_WorldLine_Create(First, Last, 1,
          CurrentPixelFormat.PackRgbBytes(240, 240, 255),
          CurrentPixelFormat.PackRgbBytes(75, 75, 75), True));
        PolarAngle := PolarAngle + PolarStep;
      end;
      Longitude := Longitude + LongitudeStep;
    end;
    PolarStep := PolarStep * 2;
    PolarAngle := PolarStep;
    while PolarAngle < Pi - PolarStep + 0.001 do
    begin
      Longitude := 0;
      while Longitude < Pi * 2 - 0.001 do
      begin
        First := SphericalToVector3D(Longitude, PolarAngle, SphereRadius);
        Last := SphericalToVector3D(Longitude + LongitudeStep, PolarAngle, SphereRadius);
        GridLines.Add(ab_WorldLine_Create(First, Last, 1,
          CurrentPixelFormat.PackRgbBytes(240, 240, 255),
          CurrentPixelFormat.PackRgbBytes(75, 75, 75), True));
        Longitude := Longitude + LongitudeStep;
      end;
      PolarAngle := PolarAngle + PolarStep;
    end;
  end;
end;
{ @end $50242C }

{ @routine $5026B8 TfAB_ABSpaceBuild }
procedure TfAB.ABSpaceBuild(GridSize: Integer; Angle: Single);
var
  Index, Attempt, OtherIndex, Choice: Integer;
  Space, Other: TabSpace;
  Link: PabSpaceLink;
  Current, Candidate, Previous, StartPoint, EndPoint: TPoint;
  Position: TPointF;
  Changed, Retry: Boolean;
  UnusedLocal: Integer;
  BlockCount, Weight: Integer;
  Config, Selected: TBlockParEC;
  Exits: array[0..2] of Integer;
begin
  if Player <> nil then MapBackgroundPath := Player.CurrentStar.SelectBackground(Index)
  else
  begin
    Config := GameDataConfig.GetBlock('BGImage');
    MapBackgroundPath := Config.GetParamValue(RandomRange(0, Config.GetParamCount - 1));
  end;
  Weight := Min(10, Round(GridSize * 0.8));
  if Weight < 1 then Weight := 1;
  Retry := True;
  while Retry do
  begin
    Retry := False;
    ab_Space_Clear;
    for Index := 0 to GridSize - 1 do
      for Attempt := 0 to GridSize - 1 do
        with ab_Space_Add do
        begin
          GridPosition := Classes.Point(Index, Attempt);
          Position.X := RandomRange(-GiScalePixels(ArcadeMapNodeRadius), GiScalePixels(ArcadeMapNodeRadius)) + 5 * GiScalePixels(ArcadeMapNodeRadius) * Attempt;
          Position.Y := RandomRange(-GiScalePixels(ArcadeMapNodeRadius), GiScalePixels(ArcadeMapNodeRadius)) + 5 * GiScalePixels(ArcadeMapNodeRadius) * Index;
          MapPosition := Classes.Point(Round(Cos(Angle) * Position.X + Sin(Angle) * Position.Y),
            Round(Sin(Angle) * Position.X - Cos(Angle) * Position.Y));
        end;
    StartPoint := Classes.Point(0, GridSize div 2);
    EndPoint := Classes.Point(GridSize - 1, GridSize div 2);
    Previous := StartPoint;
    if Weight > 1 then
    begin
      for Index := 0 to Weight - 1 do
      begin
        Current := StartPoint;
        Space := ab_Space_Find(Current);
        while GridSize - 1 > Current.X do
        begin
          if (Abs(Current.X - EndPoint.X) <= 1) and (Abs(Current.Y - EndPoint.Y) <= 1) then
            Candidate := EndPoint
          else
          begin
            Attempt := 0;
            while Attempt < 5 do
            begin
              Inc(Attempt);
              Candidate.X := Current.X + 1;
              Candidate.Y := Current.Y + RandomRange(-1, 1);
              if not (((Candidate.X <> Current.X) or (Candidate.Y <> Current.Y)) and
                ((Candidate.X <> Previous.X) or (Candidate.Y <> Previous.Y))) then Continue;
              if not ((Candidate.X >= 0) and (Candidate.X < GridSize) and
                (Candidate.Y >= 0) and (Candidate.Y < GridSize)) then Continue;
              if (Candidate.X = Current.X) or (Candidate.Y = Current.Y) or
                (ab_SpaceLink_Find(ab_Space_Find(Classes.Point(Candidate.X, Current.Y)),
                  ab_Space_Find(Classes.Point(Current.X, Candidate.Y))) = nil) then
              begin
                Other := ab_Space_Find(Candidate);
                if (Other.IncomingCount < 3) and (Other.IncomingCount + Other.OutgoingCount < 4) then Break;
              end;
            end;
            if Attempt >= 5 then Break;
          end;
          Other := ab_Space_Find(Candidate);
          if ab_SpaceLink_Find(Space, Other) = nil then
          begin
            if (Current.X = StartPoint.X) and (Current.Y = StartPoint.Y) and (Space.OutgoingCount >= 3) then Break;
            ab_SpaceLink_Connect(Space, Other);
            Inc(Space.OutgoingCount);
            Inc(Other.IncomingCount);
          end;
          Previous := Current;
          Current := Candidate;
          Space := Other;
        end;
        ab_Space_RecountLinks;
      end;
      Changed := True;
      while Changed do
      begin
        Changed := False;
        Space := FirstArcadeSpace;
        while Space <> nil do
        begin
          Other := Space;
          Space := Space.Next;
          if ((Other.GridPosition.X <> EndPoint.X) or (Other.GridPosition.Y <> EndPoint.Y)) and
            ((Other.GridPosition.X <> StartPoint.X) or (Other.GridPosition.Y <> StartPoint.Y)) and
            ((Other.OutgoingCount = 0) or (Other.IncomingCount = 0)) then
          begin
            Changed := True;
            ab_Space_Delete(Other);
          end;
        end;
        ab_Space_RecountLinks;
      end;
      Space := ab_Space_Find(EndPoint);
      if Space.IncomingCount <= 0 then Retry := True;
    end;
  end;
  StartArcadeSpace := ab_Space_Add;
  StartArcadeSpace.GridPosition := Classes.Point(StartPoint.X - 1, StartPoint.Y);
  Position.X := 5 * GiScalePixels(ArcadeMapNodeRadius) * StartArcadeSpace.GridPosition.Y;
  Position.Y := 5 * GiScalePixels(ArcadeMapNodeRadius) * StartArcadeSpace.GridPosition.X;
  StartArcadeSpace.BoundaryKind := 1;
  StartArcadeSpace.MapPosition := Classes.Point(Round(Cos(Angle) * Position.X + Sin(Angle) * Position.Y),
    Round(Sin(Angle) * Position.X - Cos(Angle) * Position.Y));
  EndArcadeSpace := ab_Space_Add;
  EndArcadeSpace.GridPosition := Classes.Point(EndPoint.X + 1, EndPoint.Y);
  Position.X := 5 * GiScalePixels(ArcadeMapNodeRadius) * EndArcadeSpace.GridPosition.Y;
  Position.Y := 5 * GiScalePixels(ArcadeMapNodeRadius) * EndArcadeSpace.GridPosition.X;
  EndArcadeSpace.BoundaryKind := 1;
  EndArcadeSpace.MapPosition := Classes.Point(Round(Cos(Angle) * Position.X + Sin(Angle) * Position.Y),
    Round(Sin(Angle) * Position.X - Cos(Angle) * Position.Y));
  ab_SpaceLink_Connect(StartArcadeSpace, ab_Space_Find(StartPoint));
  ab_SpaceLink_Connect(ab_Space_Find(EndPoint), EndArcadeSpace);
  ab_Space_RecountLinks;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    if (StartArcadeSpace <> Space) and (EndArcadeSpace <> Space) then Space.Danger := RandomRange(10, 100);
    Space := Space.Next;
  end;
  Space := StartArcadeSpace;
  while EndArcadeSpace <> Space do
  begin
    Choice := RandomRange(0, Space.OutgoingCount - 1);
    Link := FirstArcadeSpaceLink;
    while Link <> nil do
    begin
      if Link.First = Space then
      begin
        Dec(Choice);
        if Choice < 0 then
        begin
          Space := Link.Last;
          Break;
        end;
      end;
      Link := Link.Next;
    end;
    Space.Danger := 0;
  end;
  Other := nil;
  if (Player <> nil) and ((ScenarioState = scenAllianceAgainstRachekhan) or (ScenarioState = scenMachpellaFled)) then
  begin
    Other := ab_Space_Find(EndPoint);
    Other.Danger := 100;
  end;
  ab_Space_UpdateApproachDanger;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    if Space.Danger <= 0 then Space.AppearanceIndex := RandomRange(0, 1)
    else if Space.Danger + Space.ApproachDanger < ArcadeHighDangerThreshold then Space.AppearanceIndex := RandomRange(0, 1) + 2
    else Space.AppearanceIndex := RandomRange(0, 1) + 4;
    Space := Space.Next;
  end;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    if (StartArcadeSpace <> Space) and (EndArcadeSpace <> Space) then
    begin
      Space.Color28 := ArcadeMapPalette[Space.AppearanceIndex * 6 + 4];
      Space.Color30 := ArcadeMapPalette[Space.AppearanceIndex * 6 + 5];
      Space.Color2C := (ArcadeMapPalette[Space.AppearanceIndex * 6 + 4] and $FFFFFF) or $80000000;
      Space.Color34 := (ArcadeMapPalette[Space.AppearanceIndex * 6 + 5] and $FFFFFF) or $80000000;
      if Space = Other then Space.PopulateFinalEncounter
      else if (Player <> nil) and (Player.Order = soEnterBlackHole) and (ScenarioState = scenNone) then Space.PopulateHoleEncounter
      else Space.PopulateObjects;
    end;
    Space := Space.Next;
  end;
  CurrentArcadeSpace := StartArcadeSpace;
  NextArcadeSpace := ab_Space_Find(StartPoint);
  ArcadeMapViewPosition := CurrentArcadeSpace.MapPosition;
  PlayerVisual.SetAngle(HeadingDegreesToByte(RadiansToHeadingDegrees(Angle)));
  PlayerMapPosition := PointToPointF(StartArcadeSpace.MapPosition);
  RouteSpaces.Add(NextArcadeSpace);
  RebuildShipPath;
  ClearShipPath;
  ArcadeMapCenter := Classes.Point((StartArcadeSpace.MapPosition.X + EndArcadeSpace.MapPosition.X) div 2,
    (StartArcadeSpace.MapPosition.Y + EndArcadeSpace.MapPosition.Y) div 2);
  Config := GameDataConfig.GetBlock('ABMap');
  BlockCount := Config.GetBlockCount;
  Weight := 0;
  for Index := 0 to BlockCount - 1 do
    Inc(Weight, ExtractDigitsToIntW(Config.GetBlockByIndex(Index).GetParam('Priority')));
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    if Space.BoundaryKind = 1 then Space := Space.Next
    else
    begin
      if Space.OutgoingCount > 3 then RaiseWideMessage('Error');
      Changed := False;
      Retry := False;
      Selected := nil;
        if BossArcadeShip <> nil then Attempt := RandomIntRange(0, Weight - 1)
        else Attempt := RandomRange(0, Weight - 1);
        Index := 0;
        while True do
        begin
          Selected := Config.GetBlockByIndex(Index);
          if FindTextOffsetW(Selected.GetParam('Portal'), IntToStr(Space.OutgoingCount)) >= 0 then
          begin
            Changed := True;
            Retry := True;
            Dec(Attempt, ExtractDigitsToIntW(Selected.GetParam('Priority')));
            if Attempt < 0 then Break;
          end;
          Inc(Index);
          if Index >= BlockCount then
          begin
            Index := 0;
            if not Retry then Break;
            Retry := False;
          end;
        end;
        if not Changed then RaiseWideMessage('ABMap not found');
        Space.MapPath := Selected.GetParam('Path');
      Space := Space.Next;
    end;
  end;
  ArcadeMapBounds.TopLeft := FirstArcadeSpace.MapPosition;
  ArcadeMapBounds.BottomRight := FirstArcadeSpace.MapPosition;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    ArcadeMapBounds.Left := Min(ArcadeMapBounds.Left, Space.MapPosition.X);
    ArcadeMapBounds.Right := Max(ArcadeMapBounds.Right, Space.MapPosition.X);
    ArcadeMapBounds.Top := Min(ArcadeMapBounds.Top, Space.MapPosition.Y);
    ArcadeMapBounds.Bottom := Max(ArcadeMapBounds.Bottom, Space.MapPosition.Y);
    Exits[0] := 0;
    Exits[1] := 0;
    Exits[2] := 0;
    if Space.PortalSlotCount > 1 then Exits[1] := 1;
    if Space.PortalSlotCount > 2 then Exits[2] := 2;
    for Index := 0 to 4 do
    begin
      Attempt := RandomRange(0, Space.PortalSlotCount - 1);
      OtherIndex := RandomRange(0, Space.PortalSlotCount - 1);
      Choice := Exits[Attempt];
      Exits[Attempt] := Exits[OtherIndex];
      Exits[OtherIndex] := Choice;
    end;
    Index := 0;
    Link := FirstArcadeSpaceLink;
    while Link <> nil do
    begin
      if Link.First = Space then
      begin
        if Index >= 3 then RaiseWideMessage('EError');
        Link.ExitIndex := Exits[Index];
        Inc(Index);
      end;
      Link := Link.Next;
    end;
    Space := Space.Next;
  end;
end;
{ @end $5026B8 }

{ @routine $503494 TfAB_ResetBattleControls }
procedure TfAB.ResetBattleControls;
begin
  CloseVictory(0, 0);
  ListedObjects.Clear;
  SimulationPaused := False;
  ForwardKeyDown := False;
  ReverseKeyDown := False;
  BrakeKeyDown := False;
  TurnLeftKeyDown := False;
  TurnRightKeyDown := False;
  PrimaryFireKeyDown := False;
  SecondaryFireKeyDown := False;
  PlayerArcadeShip.DisruptUntilTick := 0;
  ArcadeLastInputTick := ArcadeTickCount;
  ArcadeAutopilotEnabled := False;
  ArcadeEnemiesDefeated := False;
  AutoButton.SetDown(ArcadeAutopilotEnabled);
  CacheLoadLoggingEnabled := False;
  ArcadeViewMode := avmSpace;
  SetSystemCursorPosition(Classes.Point(GameScreenWidth - 2, GameScreenHeight - 2));
end;
{ @end $503494 }

{ @routine $503564 TfAB_BeginMapTransition }
procedure TfAB.BeginMapTransition;
var
  NextObject, Obj: TabObject;
begin
  CloseVictory(0, 0);
  ArcadeViewMode := avmToMap;
  CancelCargoPickup;
  NextObject := FirstArcadeObject;
  while NextObject <> nil do
  begin
    Obj := NextObject;
    NextObject := NextObject.Next;
    if PlayerArcadeShip <> Obj then ab_Object_Delete(Obj);
  end;
  TransitionSpeed := 10;
end;
{ @end $503564 }

{ @routine $5035C0 TfAB_EnterMapView }
procedure TfAB.EnterMapView;
var
  Obj: TabObject;
begin
  CloseVictory(0, 0);
  ForwardKeyDown := False;
  ReverseKeyDown := False;
  BrakeKeyDown := False;
  TurnLeftKeyDown := False;
  TurnRightKeyDown := False;
  PrimaryFireKeyDown := False;
  SecondaryFireKeyDown := False;
  ArcadeViewMode := avmMap;
  UpdateWeaponPanel;
  CancelCargoPickup;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj is TabShip then (Obj as TabShip).DetachVisual;
    Obj := Obj.Next;
  end;
  with StartStarImage do
  begin
    SetSize(GetContentSize);
    SetOrigin(HalfPoint(ClientSize));
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetActive(True);
    RestartPlayback;
  end;
  with EndStarImage do
  begin
    SetSize(GetContentSize);
    SetOrigin(HalfPoint(ClientSize));
    SequenceIndex := 0;
    UpdateAutoGeometry;
    SetActive(True);
    RestartPlayback;
  end;
  StarField.SetBackgroundImage(MapBackgroundPath);
  StarField.BackgroundScale := 8;
  SphereCameraDistance := 1000 + SphereNearCameraOffset;
  UpdateSphereProjectionMetrics;
  ab_Space_CreateImages;
  ab_SpaceLink_BuildGeometry;
  PlayerVisual.AttachToSpace(ArcadeSpaceProcess.Space);
  PlayerVisual.SetDepth(ShipFrontDepth);
  PlayerMapPosition := PointToPointF(CurrentArcadeSpace.MapPosition);
  PlayerVisual.SetPosition(PlayerMapPosition);
  if NextArcadeSpace <> nil then
    PlayerVisual.SetAngle(HeadingDegreesToByte(PointBearingDegrees(PointToPointF(CurrentArcadeSpace.MapPosition), PointToPointF(NextArcadeSpace.MapPosition))));
  if NextArcadeSpace = nil then BuildSpaceRoute(RouteSpaces, CurrentArcadeSpace, EndArcadeSpace)
  else if (RouteSpaces.Count < 1) or (RouteSpaces[0] <> NextArcadeSpace) then begin
    RouteSpaces.Clear;
    RouteSpaces.Add(NextArcadeSpace);
  end;
  RebuildShipPath;
  if NextArcadeSpace = nil then BuildShipPathImages else ClearShipPath;
  ArcadeTransitionShiftHeld := False;
  ArcadeRoutePlaying := NextArcadeSpace <> nil;
  PlayButton.SetActive(not ArcadeRoutePlaying);
  PauseButton.SetActive(ArcadeRoutePlaying);
  ab_StopLine_Clear;
  ab_StopPoint_Clear;
  if (Player <> nil) and CampaignTransitionStarted and CampaignLoadStarted and not CampaignLoadFinished then CacheLoader.ClearFlag18;
  GetByName('PRight').SetActive(True);
end;
{ @end $5035C0 }

{ @routine $503914 TfAB_EnterCurrentSpace }
procedure TfAB.EnterCurrentSpace;
var
  Obj, Other: TabObject;
  ExitLink: PabSpaceLink;
  StopLine: PabStopLine;
  Zone: PabZone;
  ZoneLink: PabZoneLink;
  Ship, OtherShip: TabShipAI;
  Wall, OtherWall: TabWall;
  Index, OtherIndex, ColorCount, BestDifference, ColorValue, Selection: Integer;
  HasEnemies: Boolean;
  PendingLoads: TList;
  Remaining: Integer;
  ColorData: PArcadeMapColorHeader;
begin
  CloseVictory(0, 0);
  GetByName('PRight').SetActive(False);
  HideObjectInfo;
  CancelCargoPickup;
  HasEnemies := Player = nil;
  ArcadeViewMode := avmToSpace;
  StarField.SetViewPosition(MakePointF(0, 0));
  ClearShipPath;
  if (Player <> nil) and CampaignTransitionStarted and CampaignLoadStarted and not CampaignLoadFinished then CacheLoader.SetFlag18;
  PlayerArcadeShip.StopThrust;
  PlayerArcadeShip.Velocity := MakePointF(0, 0);
  PlayerArcadeShip.SetTurnInput(0);
  ab_Space_ClearImages;
  StartStarImage.SetActive(False);
  EndStarImage.SetActive(False);
  PlayerVisual.DetachFromSpace;
  StarField.SetBackgroundImage(MapBackgroundPath);
  StarField.BackgroundScale := 8;
  if Player = nil then LoadMapResource(CurrentArcadeSpace.MapPath, True)
  else LoadMapResource(CurrentArcadeSpace.MapPath, True);
  Remaining := ArcadeMapColorBuffer.DataSize;
  ColorData := ArcadeMapColorBuffer.Data;
  while Remaining > 0 do
  begin
    ColorCount := PInteger(Integer(ColorData) + 4)^;
    Selection := PInteger(Integer(ColorData) + 8)^;
    if Selection = 0 then
    begin
      Selection := 0;
      for Index := 0 to ColorCount - 1 do
      begin
        ColorValue := PInteger(Index * SizeOf(TArcadeMapColorVariant) + SizeOf(TArcadeMapColorHeader) + SizeOf(Integer) + PAnsiChar(ColorData))^;
        if ColorValue = 0 then
        begin
          Selection := Index;
          Break;
        end;
      end;
    end
    else
    begin
      ExitLink := ab_SpaceLink_FindExit(CurrentArcadeSpace, Selection - 1);
      if ExitLink = nil then
      begin
        Selection := -1;
        for Index := 0 to ColorCount - 1 do
        begin
          ColorValue := PInteger(Index * SizeOf(TArcadeMapColorVariant) + SizeOf(TArcadeMapColorHeader) + SizeOf(Integer) + PAnsiChar(ColorData))^;
          if ColorValue = 0 then
          begin
            Selection := Index;
            Break;
          end;
        end;
      end
      else
      begin
        OtherIndex := 0;
        case ExitLink.Last.AppearanceIndex of
          0: OtherIndex := 1;
          1: OtherIndex := 2;
          2: OtherIndex := 21;
          3: OtherIndex := 22;
          4: OtherIndex := 31;
          5: OtherIndex := 32;
        else RaiseWideMessage('');
        end;
        Selection := 0;
        BestDifference := 999999;
        for Index := 0 to ColorCount - 1 do
        begin
          ColorValue := PInteger(Index * SizeOf(TArcadeMapColorVariant) + SizeOf(TArcadeMapColorHeader) + SizeOf(Integer) + PAnsiChar(ColorData))^;
          if ColorValue < 20 then Dec(ColorValue, 10);
          ColorValue := Abs(OtherIndex - ColorValue);
          if ColorValue < BestDifference then
          begin
            BestDifference := ColorValue;
            Selection := Index;
          end;
        end;
      end;
    end;
    PInteger(Integer(ColorData) + 8)^ := Selection;
    Dec(Remaining, PInteger(Integer(ColorData) + 12)^);
    ColorData := Pointer(PInteger(Integer(ColorData) + 12)^ + Integer(ColorData));
  end;
  ArcadeFinalEncounter := (Player <> nil) and ((ScenarioState = scenAllianceAgainstRachekhan) or (ScenarioState = scenMachpellaFled)) and
    (CurrentArcadeSpace.Objects.IndexOf(BossArcadeShip) >= 0);
  if Player <> nil then
  begin
    if (ScenarioState = scenAllianceAgainstRachekhan) and ArcadeFinalEncounter then
    begin
      HasEnemies := True;
      for Index := 0 to CurrentArcadeSpace.Objects.Count - 1 do
      begin
        Obj := CurrentArcadeSpace.Objects[Index];
        ab_Object_Add(Obj);
        if Obj is TabShipAI then
        begin
          Ship := Obj as TabShipAI;
          if Ship.EncounterTag = 2 then
          begin
            PlayerArcadeShip.Enemies.Add(Ship);
            Ship.Enemies.Add(PlayerArcadeShip);
          end;
          for OtherIndex := 0 to CurrentArcadeSpace.Objects.Count - 1 do
          begin
            Other := CurrentArcadeSpace.Objects[OtherIndex];
            if (Obj <> Other) and (Other is TabShipAI) then
              begin
                OtherShip := Other as TabShipAI;
                if Ship.EncounterTag <> OtherShip.EncounterTag then Ship.Enemies.Add(OtherShip);
              end;
          end;
        end;
      end;
    end
    else
      for Index := 0 to CurrentArcadeSpace.Objects.Count - 1 do
      begin
        Obj := CurrentArcadeSpace.Objects[Index];
        ab_Object_Add(Obj);
        if Obj is TabShipAI then
        begin
          Ship := Obj as TabShipAI;
          PlayerArcadeShip.Enemies.Add(Ship);
          Ship.Enemies.Add(PlayerArcadeShip);
          HasEnemies := True;
        end;
      end;
    CurrentArcadeSpace.Objects.Clear;
  end;
  ab_StopLine_BuildCollisionList;
  ab_Zone_BuildAllRoutes;
  BuildGrid;
  ab_StopPoint_ClearImages;
  ab_StopLine_UpdateWorldLines;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj is TabShip then
    begin
      if PlayerArcadeShip = Obj then
      begin
        Zone := ab_Zone_RandomKind(1);
        if Zone = nil then Zone := ab_Zone_RandomKind(0);
        (Obj as TabShip).State := ab_Zone_RandomPosition(Zone);
      end
      else (Obj as TabShip).State := ab_Zone_RandomPosition(ab_Zone_RandomKind(0));
      (Obj as TabShip).Visual.SetAlpha(0);
      TShip2SE((Obj as TabShip).Visual).Use3D := Direct3D8Enabled and (Player = nil);
      (Obj as TabShip).AttachVisual;
      if Obj is TabShipAI then (Obj as TabShipAI).ResetIntent;
    end
    else if Obj is TabItem then
      (Obj as TabItem).State := ab_Zone_RandomPosition(ab_Zone_RandomKind(0));
    Obj := Obj.Next;
  end;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if (Zone.Kind = 5) or ((Zone.Kind in [6..8]) and (HasEnemies <> False)) then
    begin
      Wall := TabWall.Create;
      ab_Object_Add(Wall);
      Wall.BindZone(Zone);
      Wall.CollisionRadius := 40;
      Wall.MaxSpeed := 0;
      if Zone.Kind = 5 then
      begin
        Wall.MaxHealth := Zone.BarrierHealth;
        if TabHit(Wall).MaxHealth >= 1000000 then Wall.CollisionRadius := 0;
      end
      else if ArcadeFinalEncounter then
      begin
        Wall.MaxHealth := 1000000;
        Wall.CollisionRadius := 0;
      end
      else if (Player <> nil) and (Player.Order = soEnterBlackHole) then
        Wall.MaxHealth := Zone.BarrierHealth
      else Wall.MaxHealth := Zone.BarrierHealth;
      Wall.Health := Wall.MaxHealth;
      Wall.State := MakeSphericalBearingState(Zone.Longitude, Zone.PolarAngle, 0);
      Wall.AttachVisual;
    end;
    Zone := Zone.Next;
  end;
  ZoneLink := FirstZoneLink;
  while ZoneLink <> nil do
  begin
    if (ZoneLink.BarrierLinkMode = 1) and (ZoneLink.First.Kind in [6..8]) and (ZoneLink.Last.Kind in [6..8]) then
    begin
      Wall := ab_Wall_FindZone(ZoneLink.First);
      OtherWall := ab_Wall_FindZone(ZoneLink.Last);
      if Wall <> nil then
        if OtherWall <> nil then
        begin
          if Wall.StopPoint = nil then
          begin
            Wall.StopPoint := ab_StopPoint_Add;
            Wall.StopPoint.Longitude := ZoneLink.First.Longitude;
            Wall.StopPoint.PolarAngle := ZoneLink.First.PolarAngle;
            Wall.StopPoint.Radius := SphereRadius;
            ab_StopPoint_UpdatePosition(Wall.StopPoint);
          end;
          if OtherWall.StopPoint = nil then
          begin
            OtherWall.StopPoint := ab_StopPoint_Add;
            OtherWall.StopPoint.Longitude := ZoneLink.Last.Longitude;
            OtherWall.StopPoint.PolarAngle := ZoneLink.Last.PolarAngle;
            OtherWall.StopPoint.Radius := SphereRadius;
            ab_StopPoint_UpdatePosition(OtherWall.StopPoint);
          end;
          StopLine := ab_StopLine_Add;
          StopLine.First := Wall.StopPoint;
          StopLine.Last := OtherWall.StopPoint;
          StopLine.Visible := False;
          StopLine.Collidable := True;
        end;
    end;
    ZoneLink := ZoneLink.Next;
  end;
  ZoneLink := FirstZoneLink;
  while ZoneLink <> nil do
  begin
    if (ZoneLink.BarrierLinkMode = 1) and (ZoneLink.First.Kind = 5) and (ZoneLink.Last.Kind = 5) then
    begin
      Wall := ab_Wall_FindZone(ZoneLink.First);
      OtherWall := ab_Wall_FindZone(ZoneLink.Last);
      if Wall <> nil then
        if OtherWall <> nil then
        begin
          if Wall.StopPoint = nil then
          begin
            Wall.StopPoint := ab_StopPoint_Add;
            Wall.StopPoint.Longitude := ZoneLink.First.Longitude;
            Wall.StopPoint.PolarAngle := ZoneLink.First.PolarAngle;
            Wall.StopPoint.Radius := SphereRadius;
            ab_StopPoint_UpdatePosition(Wall.StopPoint);
          end;
          if OtherWall.StopPoint = nil then
          begin
            OtherWall.StopPoint := ab_StopPoint_Add;
            OtherWall.StopPoint.Longitude := ZoneLink.Last.Longitude;
            OtherWall.StopPoint.PolarAngle := ZoneLink.Last.PolarAngle;
            OtherWall.StopPoint.Radius := SphereRadius;
            ab_StopPoint_UpdatePosition(OtherWall.StopPoint);
          end;
          StopLine := ab_StopLine_Add;
          StopLine.First := Wall.StopPoint;
          StopLine.Last := OtherWall.StopPoint;
          StopLine.Visible := False;
          StopLine.Collidable := True;
        end;
    end;
    ZoneLink := ZoneLink.Next;
  end;
  ab_StopLine_BuildCollisionList;
  ab_Wall_BuildBarrierImages;
  ab_StopLine_UpdateWorldLines;
  SphereViewState := PlayerArcadeShip.State;
  SphereViewState.BearingDegrees := 0;
  SphereCameraDistance := SphereRadius + SphereFarCameraOffset;
  TransitionSpeed := 500;
  UpdateWeaponPanel;
  PendingLoads := TList.Create;
  QueueArcadeLoadingAssets(PendingLoads, ContentPanel);
  LoadPendingAssets(PendingLoads);
  PendingLoads.Free;
  RefreshTimerTick;
end;
{ @end $503914 }

{ @routine $504420 TfAB_AdvanceMapColors }
procedure TfAB.AdvanceMapColors;
var
  Remaining, BlockBytes, Selection, FrameIndex, FrameCount: Integer;
  ColorData: PArcadeMapColorHeader;
  Frames: PArcadeMapColorSequence;
begin
  // Variable-sized native color blocks: current color, variant count, selected
  // variant, byte size; then (sequence offset, appearance tag) pairs. Each
  // sequence stores its current frame, frame count and packed color frames.
  Remaining := ArcadeMapColorBuffer.DataSize;
  ColorData := ArcadeMapColorBuffer.Data;
  while Remaining > 0 do
  begin
    Selection := PInteger(Integer(ColorData) + 8)^;
    BlockBytes := PInteger(Integer(ColorData) + 12)^;
    if Selection < 0 then ColorData.CurrentColor := 0
    else
    begin
      Frames := Pointer(PArcadeMapColorVariant(Selection * SizeOf(TArcadeMapColorVariant) + SizeOf(TArcadeMapColorHeader) + Integer(ColorData)).SequenceOffset + Integer(ColorData));
      FrameIndex := Frames.FrameIndex;
      FrameCount := PInteger(Integer(Frames) + 4)^;
      Inc(FrameIndex);
      if FrameIndex >= FrameCount then FrameIndex := 0;
      Frames.FrameIndex := FrameIndex;
      ColorData.CurrentColor := PInteger(FrameIndex * SizeOf(Integer) + SizeOf(TArcadeMapColorSequence) + Integer(Frames))^;
    end;
    ColorData := Pointer(Integer(ColorData) + BlockBytes);
    Dec(Remaining, BlockBytes);
  end;
end;
{ @end $504420 }

{ @routine $50449C TfAB_TimerTakt }
procedure TfAB.TimerTakt(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Space: TabSpace;
  Ship: TabShip;
  Obj, NextObject: TabObject;
  BearingDegrees, Distance, Step: Double;
  Position: TPointF;
  TargetLongitude, TargetPolarAngle, SourceLongitude, SourcePolarAngle: Double;
  Loads: TList;
  Index: Integer;
  StopPoint: PabStopPoint;
  DateLabel: TLabelGI;
  CameraPos, TargetPos, UpVector: TVector3D;
  View, Rotation: TMatrix4D;
  Bearing: TSphericalBearingDistance;
  State: TSphericalBearingState;
begin
  if ArcadeViewMode = avmSpace then begin
    if not ArcadeAutopilotEnabled and not ArcadeEnemiesDefeated and ((ArcadeTickCount - ArcadeLastInputTick) * 20 > ChangeAutoPilot * 1000) then begin
      ArcadeAutopilotEnabled := True;
      AutoButton.SetDown(ArcadeAutopilotEnabled);
    end;
    AdvanceMapColors;
    ab_Item_Update;
  end;
  if (Player <> nil) and ((PlayerArcadeShip = nil) or (PlayerArcadeShip.Health <= 0)) then begin
    if DefeatCountdownTicks <= 0 then begin
      ScoreScreen.RecordPlayerResult(-1);
      Player.Free;
      GameEndReason := 3;
      RequestedScreenId := screenGameEnd;
      RequestClose(1);
      Exit;
    end;
    Dec(DefeatCountdownTicks);
  end else if ArcadeFinalEncounter then begin
    if (BossArcadeShip = nil) and (AlliedArcadeFlagship = nil) and (ScenarioState <> scenPeaceRachekhanDestroyed) and
      (PlayerArcadeShip <> nil) and (PlayerArcadeShip.Health > 0) and (PlayerArcadeShip.Enemies.Count <= 0) then begin
      if DefeatCountdownTicks <= 0 then begin
        KlingMotherShip.Free;
        GameEndReason := 0;
        RequestedScreenId := screenGameEnd;
        RequestClose(1);
        Exit;
      end;
      Dec(DefeatCountdownTicks);
    end else if (ScenarioState = scenAllianceAgainstRachekhan) and (AlliedArcadeFlagship = nil) and (BossArcadeShip <> nil) and
      (BossArcadeShip.Enemies.IndexOf(PlayerArcadeShip) < 0) then begin
      Obj := FirstArcadeObject;
      while Obj <> nil do begin
        if Obj is TabShip then begin Ship := TabShip(Obj); Ship.Enemies.Clear; end;
        Obj := Obj.Next;
      end;
      Obj := FirstArcadeObject;
      while Obj <> nil do begin
        if (Obj <> PlayerArcadeShip) and (Obj is TabShip) then begin
          Ship := TabShip(Obj);
          PlayerArcadeShip.Enemies.Add(Ship);
          Ship.Enemies.Add(PlayerArcadeShip);
        end;
        Obj := Obj.Next;
      end;
      BeginMachpellaDialogTransition;
    end;
  end;
    if ArcadeViewMode in [avmMap, avmExit] then
    begin

      if (ArcadeViewMode = avmMap) and (NextArcadeSpace <> nil) and (ShipPath <> nil) and (ShipPath.ActiveHead <> nil) then
      begin

        if IsCursorImageSelected('Scroll') then SetCursorByName('Main');
        MapDragging := False;
        PlayerVisual.OffsetTailsAlongHeading(PointDistance(PlayerMapPosition, ShipPath.ActiveHead.Position) / 2.5 + RandomIntRange(0, 1) * 0.3);
        PlayerMapPosition := ShipPath.ActiveHead.Position;
        PlayerVisual.SetAngle(HeadingDegreesToByte(ShipPath.ActiveHead.Heading));
        ShipPath.RemoveNode(ShipPath.ActiveHead);
        if (ShipPath.ActiveHead = nil) or
          (PointDistanceSquared(PointToPointF(NextArcadeSpace.MapPosition), PlayerMapPosition) <= ArcadePathStep * ArcadePathStep) then
        begin

          CurrentArcadeSpace := NextArcadeSpace;
          RouteSpaces.Delete(RouteSpaces.IndexOf(NextArcadeSpace));
          NextArcadeSpace := nil;
          Index := 0;
          while Index < CurrentArcadeSpace.Objects.Count do
          begin
            if TObject(CurrentArcadeSpace.Objects[Index]) is TabShip then Break;
            Inc(Index);
          end;
          if (Index < CurrentArcadeSpace.Objects.Count) and (CurrentArcadeSpace.Danger <> 0) then
          begin
            SelectMusic;
            EnterCurrentSpace;
          end
          else
          begin
            if (RouteSpaces.Count > 0) and ArcadeRoutePlaying then NextArcadeSpace := RouteSpaces[0]
            else
            begin
              ArcadeTransitionShiftHeld := False;
              ArcadeRoutePlaying := False;
              PlayButton.SetActive(not ArcadeRoutePlaying);
              PauseButton.SetActive(ArcadeRoutePlaying);
              if RouteSpaces.Count < 1 then BuildSpaceRoute(RouteSpaces, CurrentArcadeSpace, EndArcadeSpace);
              RebuildShipPath;
              BuildShipPathImages;
            end;
          end;
        end;
      end;
      if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) and (CurrentArcadeSpace <> EndArcadeSpace) and ArcadeRoutePlaying then
      begin

        HideObjectInfo;
        ClearShipPath;
        if RouteSpaces.Count < 1 then BuildSpaceRoute(RouteSpaces, CurrentArcadeSpace, EndArcadeSpace);
        RebuildShipPath;
        NextArcadeSpace := RouteSpaces[0];
        if ArcadeTransitionShiftHeld then
        begin
          ArcadeTransitionShiftHeld := False;
          ArcadeRoutePlaying := False;
          PlayButton.SetActive(not ArcadeRoutePlaying);
          PauseButton.SetActive(ArcadeRoutePlaying);
        end;
      end;
      if (CurrentArcadeSpace = EndArcadeSpace) and (Player <> nil) and CampaignLoadFinished and (CampaignLoadProgress >= 1) then begin
        Player.Hull.HullPoints := PlayerArcadeShip.Health;
        StarMapWeaponPanelOpen := False;
        RequestedScreenId := screenStarMap;
        RequestClose(1);
        Exit;
      end;
      if (CurrentArcadeSpace = EndArcadeSpace) and not CampaignLoadFinished and (ArcadeViewMode = avmMap) then BeginBattleExit;
      if (Player <> nil) and not CampaignTransitionStarted then FinishCampaignTransition;
      if (Player <> nil) and CampaignTransitionStarted and not CampaignLoadStarted then
      begin

        CampaignLoadStarted := True;
        Loads := TList.Create;
        QueueSpaceLoadingAssets(Loads, RootUiObject);
        if Loads.Count > 0 then
        begin
          CacheLoader.SetPendingLoads(Loads, True);
          if ArcadeViewMode = avmExit then CacheLoader.SetPriority(3);
        end
        else
        begin
          Loads.Free;
          CampaignLoadFinished := True;
          CampaignLoadProgress := 1;
        end;
      end;
      if Player <> nil then
        if CampaignTransitionStarted then
          if CampaignLoadStarted then
            if not CampaignLoadFinished then
            begin
              CampaignLoadFinished := not CacheLoader.IsRunning;
              if CampaignLoadFinished and (ArcadeViewMode <> avmExit) then CampaignLoadProgress := 1;
            end;
    end
    else if ArcadeViewMode = avmToSpace then
    begin

      Step := Max(10, (SphereCameraDistance - (SphereRadius + SphereNearCameraOffset)) / 20);
      if Step > TransitionSpeed then Step := Min(Step, TransitionSpeed + 50)
      else if Step < TransitionSpeed then Step := Max(Step, TransitionSpeed - 10);
      TransitionSpeed := Step;
      SphereCameraDistance := SphereCameraDistance - Step;
      if SphereCameraDistance <= SphereRadius + SphereNearCameraOffset then
      begin
        SphereCameraDistance := SphereRadius + SphereNearCameraOffset;
        ResetBattleControls;
      end;
    end;
    if ArcadeViewMode in [avmToMap] then
    begin

      Step := 1000;
      if Step > TransitionSpeed then Step := Min(Step, TransitionSpeed + 20)
      else if Step < TransitionSpeed then Step := Max(Step, TransitionSpeed - 5);
      TransitionSpeed := Step;
      SphereCameraDistance := SphereCameraDistance + Step;
      if SphereCameraDistance >= SphereRadius + SphereFarCameraOffset then
      begin
        SphereCameraDistance := SphereRadius + SphereFarCameraOffset;
        if ArcadeViewMode = avmToMap then EnterMapView;
      end;
    end;
    if ArcadeViewMode = avmExit then
    begin

      if CampaignLoadStarted then
      begin
        if CacheLoader.TotalLoadCount <= 0 then CampaignLoadProgress := 1
        else
        begin
          CampaignLoadProgress := Min(CampaignLoadProgress + 0.004, CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount);
          if CampaignLoadProgress > 0.99 then CampaignLoadProgress := 1;
        end;
        UpdateExitProgress(CampaignLoadProgress);
      end;
    end;
    if not ArcadeEditorMode and (ArcadeViewMode = avmSpace) and not SimulationPaused then
    begin

      Inc(ArcadeTickCount);
      if (PlayerArcadeShip <> nil) and not ArcadeAutopilotEnabled then
      begin
        if ForwardKeyDown then PlayerArcadeShip.StartThrust
        else if ReverseKeyDown then PlayerArcadeShip.StartReverseThrust
        else PlayerArcadeShip.StopThrust;

        if BrakeKeyDown then PlayerArcadeShip.Brake;

        if TurnLeftKeyDown then
        begin
          PlayerArcadeShip.SetTurnInput(-100);
          SphereViewState.BearingDegrees := WrapHeadingDegrees(SphereViewState.BearingDegrees - 0.3);
        end
        else if TurnRightKeyDown then
        begin
          PlayerArcadeShip.SetTurnInput(100);
          SphereViewState.BearingDegrees := WrapHeadingDegrees(SphereViewState.BearingDegrees + 0.3);
        end
        else PlayerArcadeShip.SetTurnInput(0);

        if PrimaryFireKeyDown then PlayerArcadeShip.FirePrimary;

        if SecondaryFireKeyDown then PlayerArcadeShip.FireSecondary;
      end;

      Obj := FirstArcadeObject;
      while Obj <> nil do
      begin
        Obj.UpdateState;
        Obj := Obj.Next;
      end;

      Obj := FirstArcadeObject;
      while Obj <> nil do
      begin
        Obj.Advance;
        if Obj.DeletionPending then
        begin

          NextObject := Obj;
          Obj := Obj.Next;
          ab_Object_Delete(NextObject);

        end
        else Obj := Obj.Next;
      end;

      if (Player <> nil) and (PlayerArcadeShip <> nil) and (PlayerArcadeShip.Health > 0) and
        TabShipAI(PlayerArcadeShip).InsideCurrentZone and (TabShipAI(PlayerArcadeShip).CurrentZone.Kind in [2..4]) then
      begin
        NextArcadeSpace := nil;
        if Player.Order = soEnterBlackHole then BeginBattleExit
        else
        begin
          ArcadeRoutePlaying := False;
          ArcadeTransitionShiftHeld := False;
          PlayButton.SetActive(not ArcadeRoutePlaying);
          PauseButton.SetActive(ArcadeRoutePlaying);
          BeginMapTransition;
        end;
      end;
    end
    else if ArcadeViewMode = avmSpace then
    begin

      Step := 0.5;
      if GetAsyncKeyState(VK_CONTROL) and $8000 = $8000 then Step := Step * 10;
      if ForwardKeyDown then SphereViewState.PolarAngleDegrees := Max(0, SphereViewState.PolarAngleDegrees - Step);
      if ReverseKeyDown then SphereViewState.PolarAngleDegrees := Min(180, SphereViewState.PolarAngleDegrees + Step);
      if TurnLeftKeyDown then SphereViewState.LongitudeDegrees := WrapHeadingDegrees(SphereViewState.LongitudeDegrees - Step);
      if TurnRightKeyDown then SphereViewState.LongitudeDegrees := WrapHeadingDegrees(SphereViewState.LongitudeDegrees + Step);
    end;
    if (PlayerArcadeShip <> nil) and (((ArcadeViewMode = avmSpace) and not ArcadeEditorMode) or (ArcadeViewMode = avmToSpace)) then
    begin

      State := PlayerArcadeShip.State;
      State := AdvanceSphericalStateOnCurrentSphere(State, CameraLookAheadDistance);
      Bearing := GetSphericalBearingAndDistance(SphereViewState, State);
      if Bearing.Distance > CameraFollowStep then Bearing.Distance := CameraFollowStep;
      BearingDegrees := WrapHeadingDegrees(SphereViewState.BearingDegrees + Bearing.BearingDeltaDegrees);
      AdvanceSphericalBearingState(SphereViewState.LongitudeDegrees, SphereViewState.PolarAngleDegrees,
        BearingDegrees, SphereRadius, Bearing.Distance);
    end
    else if (ArcadeViewMode = avmMachpellaDialog) and (BossArcadeShip <> nil) then
    begin

      ScreenPointToSphere(Classes.Point(GameScreenWidth div 2, GameScreenHeight div 2), TargetLongitude, TargetPolarAngle);
      ScreenPointToSphere(Classes.Point(GiScalePixels(220), GiScalePixels(200)), SourceLongitude, SourcePolarAngle);
      ComputeSphericalBearingAndDistance(SourceLongitude, SourcePolarAngle, 0,
        TargetLongitude, TargetPolarAngle, SphereRadius, BearingDegrees, Distance);
      if BearingDegrees < 0 then BearingDegrees := 360 + BearingDegrees;
      State := BossArcadeShip.State;
      State := AdvanceSphericalStateAlongBearing(State, BearingDegrees, Distance);
      Bearing := GetSphericalBearingAndDistance(SphereViewState, State);
      if Bearing.Distance > CameraFollowStep * 2 then Bearing.Distance := CameraFollowStep * 2;
      BearingDegrees := WrapHeadingDegrees(SphereViewState.BearingDegrees + Bearing.BearingDeltaDegrees);
      AdvanceSphericalBearingState(SphereViewState.LongitudeDegrees, SphereViewState.PolarAngleDegrees,
        BearingDegrees, SphereRadius, Bearing.Distance);
      SphereViewState.BearingDegrees := 0;
      if Bearing.Distance < 5 then
      begin

        Index := 0;
        while Index < Galaxy.Scripts.Count do begin
          CurrentScript := TScript(Galaxy.Scripts[Index]);
          if CurrentScript.ScriptFileName = 'Script.MS_Machpella' then begin
            ScriptDialogIndex := -1;
            CurrentScript.CallDialog(CurrentScript.InitCode.LocalVar.GetVar('dMama').GetInt);
            if ScriptDialogIndex < 0 then RaiseWideMessage('Not found dialog');
            TalkShip := KlingMotherShip; TalkPlanet := nil; TalkScripted := True;
            SetCursorActive(False);
            Present;
            CaptureScreenBackground;
            SetCursorActive(True);
            TalkReturnScreenId := FormToId(Self);
            RunTalk(Self);
            ArcadeViewMode := avmSpace;
            if ScenarioState = scenPeaceRachekhanDestroyed then BeginBattleExit else ArcadeEnemiesDefeated := False;
            Break;
          end;
          Inc(Index);
        end;
        if Index >= Galaxy.Scripts.Count then RaiseWideMessage('Not found script');
      end;
    end;

    CameraPos := SphericalToVector3D(HeadingDegreesToRadians(SphereViewState.LongitudeDegrees),
      HeadingDegreesToRadians(SphereViewState.PolarAngleDegrees), SphereCameraDistance);
    TargetPos := MakeVector3D(0, 0, 0);
    UpVector := SphericalToVector3D(HeadingDegreesToRadians(SphereViewState.LongitudeDegrees),
      HeadingDegreesToRadians(SphereViewState.PolarAngleDegrees + 90), SphereCameraDistance);
    View := BuildLookAtMatrix(CameraPos, TargetPos, UpVector);
    Rotation := BuildZAxisRotationMatrix(HeadingDegreesToRadians(SphereViewState.BearingDegrees));
    SphereViewMatrix := MultiplyMatrix4D(Rotation, View);
    SpherePerspectiveMatrix := BuildPerspectiveProjectionMatrix(SphereCameraDistance - SphereRadius - 100,
      SphereCameraDistance + SphereRadius + 100, HeadingDegreesToRadians(SphereFieldOfView), Cardinal(GameScreenWidth));
    SphereProjectionMatrix := MultiplyMatrix4D(SpherePerspectiveMatrix, SphereViewMatrix);
    UpdateSphereProjectionMetrics;
    if ArcadeViewMode = avmMap then
    begin

      if NextArcadeSpace <> nil then
      begin
        ArcadeMapViewPosition := TruncatePointF(PlayerMapPosition);
        HoveredArcadeSpace := nil;
      end;
      ab_Space_Update;
      ab_Space_CreateImages;
      StartStarImage.SetPosition(SubtractPoints(StartArcadeSpace.MapPosition, ArcadeMapViewPosition));
      EndStarImage.SetPosition(SubtractPoints(EndArcadeSpace.MapPosition, ArcadeMapViewPosition));
      Space := FirstArcadeSpace;
      while Space <> nil do begin
        with Space do
          if Image <> nil then Image.SetPosition(SubtractPoints(MapPosition, ArcadeMapViewPosition));
        Space := Space.Next;
      end;
      Position := PointToPointF(SubtractPoints(TruncatePointF(PlayerMapPosition), ArcadeMapViewPosition));
      PlayerVisual.OffsetTails(MakePointF(Position.X - PlayerVisual.Position.X, Position.Y - PlayerVisual.Position.Y));
      PlayerVisual.SetPosition(Position);
      StarField.SetViewPosition(PointToPointF(SubtractPoints(ArcadeMapViewPosition, ArcadeMapCenter)));
      if NextArcadeSpace = nil then UpdateShipPathImages;
    end;

    ab_StopLine_UpdateColors;
    ab_WorldLine_Update;
    ab_WorldImage_Update;

    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      Obj.UpdateVisuals;
      Obj := Obj.Next;
    end;

    ab_Object_UpdateSounds;

    if ArcadeEditorMode then begin
      if SelectedStopPoint <> nil then ab_StopPoint_DrawSelection(SelectedStopPoint);
      StopPoint := FirstStopPoint;
      while StopPoint <> nil do begin
        if StopPoint.Selected and (StopPoint <> SelectedStopPoint) then ab_StopPoint_DrawSelection(StopPoint);
        StopPoint := StopPoint.Next;
      end;
    end;
    if not ArcadeEditorMode and (ArcadeViewMode = avmSpace) then UpdateWeaponHighlights
    else if ArcadeViewMode = avmSpace then (GetByName('LInfo') as TLabelGI).SetText(EditorInfoText);

    if (ArcadeViewMode = avmMap) and (Player <> nil) then
    begin
      DateLabel := GetByName('Turn') as TLabelGI;
      DateLabel.HelpCallback := UpdateHelp;
      CameraPos.X := EndArcadeSpace.MapPosition.X - StartArcadeSpace.MapPosition.X;
      CameraPos.Y := EndArcadeSpace.MapPosition.Y - StartArcadeSpace.MapPosition.Y;
      TargetPos.X := PlayerMapPosition.X - StartArcadeSpace.MapPosition.X;
      TargetPos.Y := PlayerMapPosition.Y - StartArcadeSpace.MapPosition.Y;
      DateLabel.SetText(FormatGameTurnDate(Round((CameraPos.X * TargetPos.X + CameraPos.Y * TargetPos.Y) /
        (Sqr(CameraPos.X) + Sqr(CameraPos.Y)) * (ArrivalTurn - DepartureTurn) + DepartureTurn)));
    end;

    if not SimulationPaused then ab_Ship_RepelOverlaps;
end;
{ @end $50449C }

{ @routine $505C64 TfAB_ScrollMapTimer }
procedure TfAB.ScrollMapTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Position, PreviousPosition: TPoint;
begin
  if (ArcadeViewMode = avmMap) and (NextArcadeSpace = nil) then
  begin
    PreviousPosition := ArcadeMapViewPosition;
    Position := PreviousPosition;
    if TurnLeftKeyDown then Dec(Position.X, ScrollSpeed);
    if TurnRightKeyDown then Inc(Position.X, ScrollSpeed);
    if ForwardKeyDown then Dec(Position.Y, ScrollSpeed);
    if ReverseKeyDown then Inc(Position.Y, ScrollSpeed);
    if GetCursorPoint.X = 0 then Dec(Position.X, ScrollSpeed);
    if GetCursorPoint.X = GameScreenWidth - 1 then Inc(Position.X, ScrollSpeed);
    if GetCursorPoint.Y = 0 then Dec(Position.Y, ScrollSpeed);
    if GetCursorPoint.Y = GameScreenHeight - 1 then Inc(Position.Y, ScrollSpeed);
    if (PreviousPosition.X <> Position.X) or (PreviousPosition.Y <> Position.Y) then
    begin
      ArcadeMapViewPosition := Position;
      if ArcadeMapBounds.Top - ArcadeMapPanMargin > ArcadeMapViewPosition.Y then ArcadeMapViewPosition.Y := ArcadeMapBounds.Top - ArcadeMapPanMargin;
      if ArcadeMapBounds.Bottom + ArcadeMapPanMargin < ArcadeMapViewPosition.Y then ArcadeMapViewPosition.Y := ArcadeMapBounds.Bottom + ArcadeMapPanMargin;
      if ArcadeMapBounds.Left - ArcadeMapPanMargin > ArcadeMapViewPosition.X then ArcadeMapViewPosition.X := ArcadeMapBounds.Left - ArcadeMapPanMargin;
      if ArcadeMapBounds.Right + ArcadeMapPanMargin < ArcadeMapViewPosition.X then ArcadeMapViewPosition.X := ArcadeMapBounds.Right + ArcadeMapPanMargin;
    end;
  end;
end;
{ @end $505C64 }

{ @routine $505E64 TfAB_FinishCampaignTransition }
procedure TfAB.FinishCampaignTransition;
var SavedStar: TStar;
begin
  if not IsTurnCalculationRunningUI then
    if TurnCalculationPhase <> 1 then
      if TurnCalculationPhase <> 3 then begin
        if TurnCalculationPhase = 2 then QueuePlayerStarTurnCalculation
        else if ((Player.Order <> soJump) and (Player.Order <> soEnterBlackHole)) or ((Player.Order = soEnterBlackHole) and (Player.OrderStateData = BlackHoleExitFlightState)) then begin
          QueueGalaxyTurnCalculation;
          StarMapScreen.SetMapCenterManually(TruncatePointF(Player.Position));
          StarMapScreen.ResumeMode := 2;
          CampaignTransitionStarted := True;
        end else begin
          Galaxy.ClearJumpGates;
          SavedStar := PlayerStar;
          PlayerStar := Player.CurrentStar;
          PlayerStar.RebuildShipMovementPaths;
          SavedStar.RebuildShipMovementPaths;
          if Cardinal(Player.OrderStateData and TravelDaysMask) = 1 then begin
            PruneExpiredPersistentPlayerMessages;
            RunStarTransitionScript(Player.CurrentStar, 3);
          end;
          Galaxy.GenerateSpaceBackground;
          QueueGalaxyTurnCalculation;
        end;
      end;
end;
{ @end $505E64 }

{ @routine $505FA0 TfAB_InvalidateFrame }
procedure TfAB.InvalidateFrame;
begin
  UpdateRectsEnabled := True;
  GetByName('UpdateObj').InvalidateChildren(True);
  WorldPanel.InvalidateChildren(True);
  if (ArcadeViewMode <> avmMap) and (ArcadeViewMode <> avmExit) then ab_Polygon_QueueUpdateRects;
  if ArcadeViewMode = avmMap then ab_SpaceLink_Invalidate;
  CursorControl.Invalidate;
  UpdateRectsEnabled := False;
end;
{ @end $505FA0 }
{ @routine $506018 TfAB_DrawShipHealthBars }
procedure TfAB.DrawShipHealthBars;
var
  Obj: TabObject;
  Ship: TabShip;
  CenterX, CenterY, Width, FilledWidth, Height: Integer;
  Corners: TArcadeHealthBarCorners;
begin
  with Corners do
  begin
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if not (Obj is TabShip) then begin Obj := Obj.Next; Continue; end;
      Ship := TabShip(Obj);
      Obj := Obj.Next;
      if (Ship.Visual <> nil) and Ship.Visual.IsAttachedToSpace and
         (Ship.Visual.GetDepth = ShipFrontDepth) and
         ((Ship.BonusTicks[7] <= 0) or (Ship.RevealTicks > 0) or (PlayerArcadeShip = Ship)) then
      begin
        CenterX := Round(Ship.Visual.Position.X) + WorldCenterX;
        CenterY := Round(Ship.Visual.Position.Y) + WorldCenterY;
        Width := Ship.EffectOriginSpread;
        Height := 3;
        FilledWidth := Round(Ship.Health / Ship.MaxHealth * Width);
        TopLeft.Y := CenterY + Ship.EffectOriginSpread div 2;
        TopRight.Y := TopLeft.Y;
        BottomRight.Y := TopRight.Y + Height;
        BottomLeft.Y := TopLeft.Y + Height;
        if FilledWidth > 0 then
        begin
          TopLeft.X := CenterX - Width div 2;
          TopRight.X := TopLeft.X + FilledWidth;
          BottomRight.X := TopRight.X;
          BottomLeft.X := TopLeft.X;
          TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
            TopLeft.X, TopLeft.Y, $FFFF0000,
            TopRight.X, TopRight.Y, $FFFF0000,
            BottomLeft.X, BottomLeft.Y, $FFFFFFFF, @GameScreenRect);
          TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
            TopRight.X, TopRight.Y, $FFFF0000,
            BottomRight.X, BottomRight.Y, $FFFFFFFF,
            BottomLeft.X, BottomLeft.Y, $FFFFFFFF, @GameScreenRect);
        end;
        if FilledWidth < Width then
        begin
          TopLeft.X := CenterX - Width div 2 + FilledWidth;
          TopRight.X := TopLeft.X + Width - FilledWidth;
          BottomRight.X := TopRight.X;
          BottomLeft.X := TopLeft.X;
          TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
            TopLeft.X, TopLeft.Y, $FF0000FF,
            TopRight.X, TopRight.Y, $FF0000FF,
            BottomLeft.X, BottomLeft.Y, $FFFFFFFF, @GameScreenRect);
          TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
            TopRight.X, TopRight.Y, $FF0000FF,
            BottomRight.X, BottomRight.Y, $FFFFFFFF,
            BottomLeft.X, BottomLeft.Y, $FFFFFFFF, @GameScreenRect);
        end;
      end;
    end;
  end;
end;
{ @end $506018 }

{ @routine $5062CC TfAB_DrawFrame }
procedure TfAB.DrawFrame;
var
  Rect: TRectGR;
  Background: TStarFieldGI;
  PreviousSkipRestore: Boolean;
  Obj: TabObject;
begin
  Inc(ArcadeFrameCount);
  if (ArcadeViewMode = avmSpace) and (CargoPickupZone <> nil) and (PlayerArcadeShip <> nil) then
  begin
    CargoPickupZone.Longitude := PlayerArcadeShip.State.LongitudeDegrees;
    CargoPickupZone.PolarAngle := PlayerArcadeShip.State.PolarAngleDegrees;
    ab_Zone_UpdatePosition(CargoPickupZone);
    ab_Zone_UpdateImages(CargoPickupZone);
  end;
  if (ArcadeViewMode <> avmMap) and (ArcadeViewMode <> avmExit) then
  begin
    ab_Polygon_SelectVisibilityCell;
    ab_Polygon_ProjectVisiblePoints;
  end;
  if ArcadeViewMode = avmExit then SysUtils.Sleep(10);
  if (not Direct3D8Enabled) or (ArcadeViewMode = avmMap) or (Player <> nil) then
  begin
  InvalidateFrame;
  Background := GetByName('StarField') as TStarFieldGI;
  PreviousSkipRestore := SkipSavedPixelRestore;
  Background.UpdateBackgroundBounds;
  SkipSavedPixelRestore := SkipSavedPixelRestore or PreviousSkipRestore;
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
  Rect := UpdateRects.FirstRect;
  while Rect <> nil do
  begin
    Background.DrawBackground(Rect.Bounds);
    Rect := Rect.Next;
  end;
  PrepareFrameDraw;
  if (ArcadeViewMode = avmMap) or ((ArcadeViewMode = avmExit) and (ViewModeBeforeExit = avmMap)) then
    ab_SpaceLink_Draw
  else
  begin
    ab_Polygon_DrawVisible;
    DrawShipHealthBars;
  end;
  DrawQueuedControlRects;
  if not BeginFramePresentation then
  begin
    RequestedScreenId := screenNone;
    RestartScreenId := FormToId(Self);
    RequestClose(1);
    Exit;
  end;
  begin
    FinishQueuedDraw;
    CommitFrameDraw;
    ResetSecondaryPixelCount;
    EndFramePresentation;
    InvalidateFrame;
  end;
  end
  else
  begin
    ab_StopPoint_UpdateVertices;
    if Direct3D8Device.Clear(0, nil, 3, D3DColorXRGB(0, 0, 0), 1.0, 0) <> 0 then
      RaiseWideMessage('TabObj3D Dev.Clear');
    if Direct3D8Device.BeginScene <> 0 then RaiseWideMessage('TabObj3D BeginScene');
    Direct3D8Device.SetRenderState(141, 1);
    Direct3D8Device.SetRenderState(27, 1);
    Direct3D8Device.SetRenderState(19, 5);
    Direct3D8Device.SetRenderState(20, 6);
    Direct3D8Device.SetRenderState(22, 3);
    Direct3D8Device.SetRenderState(136, 0);
    Direct3D8Device.SetRenderState(26, 1);
    Direct3D8Device.SetRenderState(7, 1);
    Direct3D8Device.SetRenderState(14, 1);
    Direct3D8Device.SetRenderState(23, 4);
    Direct3D8Device.SetTextureStageState(0, 16, 2);
    Direct3D8Device.SetTextureStageState(0, 17, 2);
    Direct3D8Device.SetTextureStageState(0, 18, 2);
    ab_Obj3D_Draw;
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if Obj is TabShip then TShip2SE((Obj as TabShip).Visual).Draw3D;
      Obj := Obj.Next;
    end;
    if Direct3D8Device.EndScene <> 0 then RaiseWideMessage('TabObj3D EndScene');
    if Direct3D8Device.Present(nil, nil, 0, nil) <> 0 then RaiseWideMessage('TabObj3D Present');
  end;
  SkipSavedPixelRestore := False;
end;
{ @end $5062CC }

{ @routine $506708 TfAB_WorldImageCycleComplete }
procedure TfAB.WorldImageCycleComplete(Sender: TObjectGI);
var Entry: PabWorldImage;
begin
  Entry := PabWorldImage(Sender.UserValue);
  Entry.Finished := True;
  if Entry.Image <> nil then Entry.Image.SetActive(False);
end;
{ @end $506708 }

{ @routine $506724 TfAB_AppendShipPathArc }
procedure TfAB.AppendShipPathArc(Destination: TPointF);
var
  Node: PSPathNode;
  Position: TPointF;
  AngleStep, Step, FromHeading, ToHeading, Difference, InitialDifference, TangentStep: Double;
begin
  if ShipPath.ActiveTail = nil then
  begin
    Position := PlayerMapPosition;
    FromHeading := ByteToHeadingDegrees(PlayerVisual.GetAngle);
  end
  else
  begin
    Node := ShipPath.ActiveTail;
    Position := Node.Position;
    FromHeading := Node.Heading;
  end;
  if (Position.X = Destination.X) and (Position.Y = Destination.Y) then Exit;
  AngleStep := ArcadePathStep;
  Step := ArcadePathArcStep;
  if PointDistanceSquared(Position, Destination) < Step then
  begin
    ShipPath.AppendNode;
    Node := ShipPath.ActiveTail;
    Node.Position := Position;
    Node.Heading := FromHeading;
  end
  else
  begin
    ToHeading := RadiansToHeadingDegrees(ArcTan2(-(Position.X - Destination.X), Position.Y - Destination.Y));
    InitialDifference := HeadingDifferenceDegrees(FromHeading, ToHeading);
    if Abs(InitialDifference) >= AngleStep then
    begin
      TangentStep := CalculateTangentArcOffset(Position, Destination, FromHeading, AngleStep);
      if TangentStep < Step then Step := TangentStep;
      while (Position.X <> Destination.X) or (Position.Y <> Destination.Y) do
      begin
        ToHeading := RadiansToHeadingDegrees(ArcTan2(-(Position.X - Destination.X), Position.Y - Destination.Y));
        Difference := HeadingDifferenceDegrees(FromHeading, ToHeading);
        if Abs(Difference) <= AngleStep then Break;
        if InitialDifference > 0 then FromHeading := WrapHeadingDegrees(FromHeading + AngleStep)
        else FromHeading := WrapHeadingDegrees(FromHeading - AngleStep);
        Position.X := Sin(HeadingDegreesToRadians(FromHeading)) * Step + Position.X;
        Position.Y := Position.Y - Cos(HeadingDegreesToRadians(FromHeading)) * Step;
        if (Position.X - Destination.X) * (Position.X - Destination.X) +
          (Position.Y - Destination.Y) * (Position.Y - Destination.Y) <= Step * Step then Position := Destination;
        ShipPath.AppendNode;
        Node := ShipPath.ActiveTail;
        Node.Position := Position;
        Node.Heading := FromHeading;
      end;
    end;
  end;
end;
{ @end $506724 }

{ @routine $5069EC TfAB_AppendShipPathLine }
procedure TfAB.AppendShipPathLine(Destination: TPointF);
var
  Vertical: Boolean;
  Distance, Travelled, Slope, AxisScale, AxisOrigin, Heading: Double;
  Position, Origin: TPointF;
  OriginPtr: PPointF;
  Node: PSPathNode;
  Step: Double;
begin
  OriginPtr := @Origin;
  if ShipPath.ActiveTail = nil then OriginPtr^ := PlayerMapPosition
  else OriginPtr^ := ShipPath.ActiveTail.Position;
  if (OriginPtr^.X <> Destination.X) or (OriginPtr^.Y <> Destination.Y) then
  begin
    Step := ArcadePathStep;
    Heading := RadiansToHeadingDegrees(ArcTan2(-(OriginPtr^.X - Destination.X), OriginPtr^.Y - Destination.Y));
    if Abs(OriginPtr^.X - Destination.X) < Abs(OriginPtr^.Y - Destination.Y) then Vertical := True
    else Vertical := False;
    Distance := Sqrt((OriginPtr^.X - Destination.X) * (OriginPtr^.X - Destination.X) +
      (OriginPtr^.Y - Destination.Y) * (OriginPtr^.Y - Destination.Y));
    if Vertical then
    begin
      Slope := (Destination.X - OriginPtr^.X) / (Destination.Y - OriginPtr^.Y);
      AxisScale := 1 / Sqrt(Slope * Slope + 1);
      if Destination.Y - OriginPtr^.Y < 0 then AxisScale := -AxisScale;
      AxisOrigin := OriginPtr^.Y;
    end
    else
    begin
      Slope := (Destination.Y - OriginPtr^.Y) / (Destination.X - OriginPtr^.X);
      AxisScale := 1 / Sqrt(Slope * Slope + 1);
      if Destination.X - OriginPtr^.X < 0 then AxisScale := -AxisScale;
      AxisOrigin := OriginPtr^.X;
    end;
    Travelled := Step;
    if Travelled >= Distance then
    begin
      ShipPath.AppendNode;
      Node := ShipPath.ActiveTail;
      Node.Position := Destination;
      Node.Heading := Heading;
    end
    else
      while Travelled < Distance do
      begin
        if Vertical then
        begin
          Position.Y := Travelled * AxisScale + AxisOrigin;
          Position.X := (Position.Y - OriginPtr^.Y) * Slope + OriginPtr^.X;
        end
        else
        begin
          Position.X := Travelled * AxisScale + AxisOrigin;
          Position.Y := (Position.X - OriginPtr^.X) * Slope + OriginPtr^.Y;
        end;
        ShipPath.AppendNode;
        Node := ShipPath.ActiveTail;
        Node.Position := Position;
        Node.Heading := Heading;
        Travelled := Travelled + Step;
      end;
  end;
end;
{ @end $5069EC }

{ @routine $506C68 TfAB_AppendShipPath }
procedure TfAB.AppendShipPath(Destination: TPointF);
var
  Step: Single;
begin
  AppendShipPathArc(Destination);
  AppendShipPathLine(Destination);
  Step := ArcadePathStep;
  if (ShipPath.ActiveHead <> nil) and
    (Step * Step > PointDistanceSquared(ShipPath.ActiveTail.Position, Destination)) then
    ShipPath.ActiveTail.Position := Destination;
end;
{ @end $506C68 }

{ @routine $506CDC TfAB_BuildSpaceRoute }
procedure TfAB.BuildSpaceRoute(Route: TList; Origin, Destination: TabSpace);
var
  Space, BestSpace: TabSpace;
  Link: PabSpaceLink;
  Pending, Following, Swap: TList;
  Index: Integer;
  BestCost: Double;
begin
  Route.Clear;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.RouteCost := -1;
    Space := Space.Next;
  end;
  Pending := TList.Create;
  Following := TList.Create;
  Pending.Add(Destination);
  Destination.RouteCost := 0;
  while Pending.Count > 0 do
  begin
    Following.Clear;
    for Index := 0 to Pending.Count - 1 do
    begin
      Space := Pending[Index];
      Link := FirstArcadeSpaceLink;
      while Link <> nil do
      begin
        if Link.Last = Space then
          if ((Link.First.RouteCost < 0) or
          (Space.RouteCost + Link.First.Danger + 0.001 < Link.First.RouteCost)) then
          begin
            Link.First.RouteCost := Space.RouteCost + Link.First.Danger + 0.001;
            if Following.IndexOf(Link.First) < 0 then Following.Add(Link.First);
          end;
        Link := Link.Next;
      end;
    end;
    Swap := Pending;
    Pending := Following;
    Following := Swap;
  end;
  Following.Free;
  Pending.Free;
  Space := Origin;
  while Space <> Destination do
  begin
    BestCost := 1E20;
    BestSpace := nil;
    Link := FirstArcadeSpaceLink;
    while Link <> nil do
    begin
      if Link.First = Space then
        if (Link.Last.RouteCost >= 0) and (Link.Last.RouteCost < BestCost) then
        begin
          BestSpace := Link.Last;
          BestCost := Link.Last.RouteCost;
        end;
      Link := Link.Next;
    end;
    if BestSpace = nil then Break;
    Space := BestSpace;
    Route.Add(Space);
  end;
end;
{ @end $506CDC }

{ @routine $506EAC TfAB_RebuildShipPath }
procedure TfAB.RebuildShipPath;
var
  Index: Integer;
  Space: TabSpace;
begin
  ShipPath.Clear;
  for Index := 0 to RouteSpaces.Count - 1 do
  begin
    Space := RouteSpaces[Index];
    AppendShipPath(PointToPointF(Space.MapPosition));
  end;
end;
{ @end $506EAC }

{ @routine $506F00 TfAB_BuildShipPathImages }
procedure TfAB.BuildShipPathImages;
var
  PreviousPosition: TPointF;
  Node, First, Last: PSPathNode;
  Images: TMultiImageGI;
  Item: TMultiImageUnitGI;
  Index: Integer;
  Space: TabSpace;
begin
  if ShipPath.ActiveHead <> nil then
  begin
    Images := GetByName('ShipPath') as TMultiImageGI;
    if Images.Images.Count < 1 then
    begin
      Images.AddImage('Bm.PI.Path1');
      Images.AddImage('Bm.PI.Path2');
      Images.AddImage('Bm.PI.Path3');
      Images.AddImage('Bm.PI.Path4');
    end;
    Images.ClearUnits;
    First := ShipPath.ActiveHead;
    for Index := 0 to RouteSpaces.Count - 1 do
    begin
      Space := RouteSpaces[Index];
      Last := ShipPath.FindNearestFollowingNode(First, PointToPointF(Space.MapPosition));
      if Last = nil then Last := ShipPath.ActiveTail;
      PreviousPosition := MakePointF(1E10, 1E10);
      Node := Last;
      while True do
      begin
        if PointDistanceSquared(PreviousPosition, Node.Position) > 225 then
        begin
          PreviousPosition := Node.Position;
          if ShipPath.ActiveTail <> Node then
          begin
            Item := Images.AddUnit;
            Item.UserData := Node;
            Images.SetUnitPosition(Item, SubtractPoints(TruncatePointF(PreviousPosition), ArcadeMapViewPosition));
            if Node <> Last then Item.ImageIndex := 1
            else Item.ImageIndex := 2;
          end;
        end;
        if Node = First then Break;
        Node := Node.Prev;
      end;
      First := Last.Next;
    end;
    with GetByName('ShipPathEnd') as TgaiGI do
    begin
      SetActive(True);
      SetOrigin(HalfPoint(GetContentSize));
      SetPosition(SubtractPoints(TruncatePointF(ShipPath.ActiveTail.Position), ArcadeMapViewPosition));
      RestartPlayback;
    end;
  end;
end;
{ @end $506F00 }

{ @routine $5071D8 TfAB_UpdateShipPathImages }
procedure TfAB.UpdateShipPathImages;
var
  PathImage: TMultiImageGI;
  Node: PSPathNode;
  Item: TMultiImageUnitGI;
begin
  if ShipPath.ActiveHead = nil then Exit;
  PathImage := GetByName('ShipPath') as TMultiImageGI;
  with PathImage do
  begin
    Item := FirstUnit;
    while Item <> nil do
    begin
      Node := Item.UserData;
      SetUnitPosition(Item, SubtractPoints(TruncatePointF(Node.Position), ArcadeMapViewPosition));
      Item := Item.Next;
    end;
  end;
  with GetByName('ShipPathEnd') as TgaiGI do
  begin
    SetActive(True);
    SetOrigin(HalfPoint(GetContentSize));
    SetPosition(SubtractPoints(TruncatePointF(ShipPath.ActiveTail.Position), ArcadeMapViewPosition));
    RestartPlayback;
  end;
end;
{ @end $5071D8 }

{ @routine $5072FC TfAB_ClearShipPath }
procedure TfAB.ClearShipPath;
begin
  (GetByName('ShipPath') as TMultiImageGI).ClearUnits;
  (GetByName('ShipPathEnd') as TgaiGI).SetActive(False);
end;
{ @end $5072FC }

{ @routine $507370 TfAB_BeginMachpellaDialogTransition }
procedure TfAB.BeginMachpellaDialogTransition;
begin
  CloseVictory(0, 0);
  ArcadeViewMode := avmMachpellaDialog;
end;
{ @end $507370 }

{ @routine $507388 TfAB_BeginBattleExit }
procedure TfAB.BeginBattleExit;
begin
  CloseVictory(0, 0);
  ViewModeBeforeExit := ArcadeViewMode;
  ArcadeViewMode := avmExit;
  NextArcadeSpace := EndArcadeSpace;
  CurrentArcadeSpace := EndArcadeSpace;
  if CampaignLoadStarted and not CampaignLoadFinished then CacheLoader.SetPriority(3);
  GetByName('PBmin').SetActive(True);
  GetByName('PBmax').SetActive(True);
  UpdateExitProgress(0);
  CampaignLoadProgress := 0;
end;
{ @end $507388 }

{ @routine $507444 TfAB_UpdateExitProgress }
procedure TfAB.UpdateExitProgress(Progress: Single);
var Width: Integer;
begin
  Width := Round(Cardinal(GameScreenWidth) * Progress);
  with GetByName('PBmin') do begin
    SetActive(Integer(GameScreenWidth - Width) > 0);
    if Active then begin
      SetPosition(Classes.Point(Width, LocalPosition.Y));
      SetSize(Classes.Point(GameScreenWidth - Width, ClientSize.Y));
    end;
  end;
  with GetByName('PBmax') do begin
    SetActive(Width > 0);
    if Active then SetSize(Classes.Point(Width, ClientSize.Y));
  end;
end;
{ @end $507444 }

{ @routine $50752C TfAB_ShowSpaceInfo }
procedure TfAB.ShowSpaceInfo(Space: TabSpace);
var
  Distance: Single;
  Index, InsertIndex, RowHeight, ShipCount: Integer;
  Obj: TObject;
  Text: WideString;
  Star: TStar;
  Owner: TPanelGI;
  Objects: TList;
  OwnerId: TOwnerId;
begin
  if Space = nil then HideObjectInfo
  else if InfoObject <> Space then
  begin
    InfoObject := Space;
    if (Player <> nil) and ((StartArcadeSpace = Space) or (EndArcadeSpace = Space)) then
    begin
      GetByName('InfoStar').SetActive(True);
      if StartArcadeSpace = Space then Star := Player.TransitOriginStar else Star := Player.CurrentStar;
      (GetByName('InfoStarName') as TLabelGI).SetText(WrapTextInColor(Star.Name, HighlightColorTag));
      with GetByName('InfoStarImage') as TGraphBufGI do
      begin
        SourceHasPerPixelAlpha := True;
        LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TStarSE(Star.Graphic).StaticImagePath, 1, ','), GraphBuf);
        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleBilinearRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)))
        else
          GraphBuf.RescaleBilinearRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      Owner := GetByName('InfoStarPanel') as TPanelGI;
      Owner.FreeOwnedChildren;
      Objects := TList.Create;
      for Index := 0 to Star.Planets.Count - 1 do Objects.Add(Star.Planets[Index]);
      for Index := 0 to Star.Ships.Count - 1 do
        if TObject(Star.Ships[Index]) is TRuins then
        begin
          Distance := PointDistanceSquared(TShip(Star.Ships[Index]).Position, MakePointF(0, 0));
          InsertIndex := 0;
          while InsertIndex < Objects.Count do
          begin
            if TObject(Objects[InsertIndex]) is TPlanet then
            begin
              if PointDistanceSquared(TPlanet(Objects[InsertIndex]).GetPosition, MakePointF(0, 0)) > Distance then Break;
            end
            else if PointDistanceSquared(TShip(Objects[InsertIndex]).Position, MakePointF(0, 0)) > Distance then Break;
            Inc(InsertIndex);
          end;
          Objects.Insert(InsertIndex, Star.Ships[Index]);
        end;
      RowHeight := GiScalePixels(20);
      for Index := 0 to Objects.Count - 1 do
      begin
        with TLabelGI.Create(Owner) do
        begin
          SetFontName(HitPointFontName);
          SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
          SetSize(Classes.Point(Owner.ClientSize.X div 2 + 15, RowHeight));
          SetPosition(Classes.Point(0, RowHeight * Index));
          SetWordWrapEnabled(False);
          SetTextAlignX(taxRight);
          SetTextAlignY(tayCenterEx);
          if TObject(Objects[Index]) is TPlanet then SetText(TPlanet(Objects[Index]).Name)
          else SetText(TShip(Objects[Index]).Name);
        end;
        with TGraphBufGI.Create(Owner) do
        begin
          SourceHasPerPixelAlpha := True;
          SetPosition(Classes.Point(Owner.ClientSize.X div 2 + 15 + 5 + 1, RowHeight * Index + 1));
          SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
          if TObject(Objects[Index]) is TPlanet then
          begin
            TPlanet(Objects[Index]).Graphic.RenderToBuffer(Self, GraphBuf, True);
            GraphBuf.RescaleBilinearRgba(ClientSize.X, ClientSize.Y);
          end
          else
          begin
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((TShip(Objects[Index]).Graphic as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          end;
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
        if TObject(Objects[Index]) is TPlanet then OwnerId := TPlanet(Objects[Index]).OwnerId
        else OwnerId := TShip(Objects[Index]).OwnerId;
        if OwnerId in [oiMaloc..oiKling] then
        begin
          with TGraphBufGI.Create(Owner) do
          begin
            SourceHasPerPixelAlpha := True;
            LoadBitmapPathAsRgba(ExtractDelimitedPartW(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[OwnerId].InternalName), 1, ',') + '?RGBA');
            SetPosition(Classes.Point(Owner.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1, RowHeight * Index + 1));
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else
              GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
          end;
        end;
      end;
      Owner.SetSize(Classes.Point(Owner.ClientSize.X, Objects.Count * RowHeight));
      with GetByName('InfoStar') as TPanelGI do
      begin
        SetSize(Classes.Point(ClientSize.X, Owner.LocalPosition.Y + Objects.Count * RowHeight + GiScalePixels(30)));
        UpdateAutoGeometry;
      end;
      Objects.Free;
      GetByName('InfoPanel').SetActive(False);
      Exit;
    end;
    GetByName('InfoStar').SetActive(False);
    GetByName('InfoPanel').SetActive(True);
    (GetByName('InfoName') as TLabelGI).SetText(WrapTextInColor(LocalizedColorText('FormAB.InfoName'), HighlightColorTag));
    (GetByName('InfoSize') as TLabelGI).SetText(IntToStr(Round(Space.ArenaSize)));
    (GetByName('InfoExit') as TLabelGI).SetText(IntToStr(Space.OutgoingCount));
    if (Player <> nil) and Player.HaveHyperspaceLocator then Text := Space.GetDangerText
    else Text := LocalizedColorText('FormAB.Unknow');
    (GetByName('InfoDanger') as TLabelGI).SetText(Text);
    ShipCount := 0;
    for Index := 0 to Space.Objects.Count - 1 do
    begin
      Obj := Space.Objects[Index];
      if Obj is TabShipAI then Inc(ShipCount);
    end;
    if (Player <> nil) and Player.HaveHyperspaceLocator then Text := IntToStr(ShipCount)
    else Text := LocalizedColorText('FormAB.Unknow');
    (GetByName('InfoPirate') as TLabelGI).SetText(Text);
    with GetByName('InfoPlanetImage') as TGraphBufGI do
    begin
      SetActive(True);
      SourceHasPerPixelAlpha := True;
      if StartArcadeSpace = Space then LoadGaiFrameToGraphBuf(StartStarImage.GetImagePath, GraphBuf, 0)
      else if EndArcadeSpace = Space then LoadGaiFrameToGraphBuf(EndStarImage.GetImagePath, GraphBuf, 0)
      else LoadGaiFrameToGraphBuf(Space.Image.GetImagePath, GraphBuf, 0);
      if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
      begin
        GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5);
      end
      else
      begin
        GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
      end;
      SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
    end;
    BattleHelpLabel.SetActive(True);
    BattleHelpLabel.SetText(LocalizedColorText('Help.ABSphere'));
  end;
end;
{ @end $50752C }

{ @routine $508364 TfAB_HideObjectInfo }
procedure TfAB.HideObjectInfo;
begin
  if InfoObject <> nil then
  begin
    GetByName('InfoPanel').SetActive(False);
    GetByName('InfoStar').SetActive(False);
    HideHelp;
  end;
  InfoObject := nil;
end;
{ @end $508364 }

{ @routine $5083D8 TfAB_ShowItemInfo }
procedure TfAB.ShowItemInfo(Item: TabItem);
var Instance: TItem;
begin
  if (Item = nil) or (PlayerArcadeShip = nil) then
  begin
    CancelCargoPickup;
    Exit;
  end;
  if Item.BonusKind >= 0 then
  begin
    CancelCargoPickup;
    Exit;
  end;
  if CargoPickupItem = Item then Exit;
  CargoPickupItem := Item;
  if Item.BonusKind >= 0 then
  begin
    if not IsCursorImageSelected('Take') then SetCursorByName('Take');
  end
  else
  begin
    if (Player <> nil) and (Item.Item.Weight <= Player.CargoFreeSpace) and
      (PlayerArcadeShip.DistanceTo(Item) < ManualCargoPickupDistance) and
      (Item.Item.Weight <= Player.CargoFreeSpace) and
      (Player.CargoHook <> nil) and not Player.CargoHook.BrokenFlag and
      (Player.CargoHook.PickupPower + 15 * (Ord(Player.HasActiveArtefact(t_ArtefactHook))) >= Item.Item.Weight) then
    begin
      if not IsCursorImageSelected('Take') then SetCursorByName('Take');
    end
    else if not IsCursorImageSelected('Main') then SetCursorByName('Main');
    Instance := Item.Item;
    ItemInfoWindow.SetActive(True);
    with GetByName('InfoItemImage') as TImageGI do
    begin
      if Instance is TGoods then SetImagePath('GI,' + GetItemTypeBitmapPath(Instance.ItemType))
      else SetImagePath('GI,' + Instance.GetBitmapResourceName + 's');
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      SetPosition(SubtractPoints(ShipScreen.ItemImageCenter, GetVisualCenter));
    end;
    if Instance is TGoods then
    begin
      (GetByName('InfoItemName') as TLabelGI).SetText(WrapTextInColor(GoodsNames[Instance.ItemType], HighlightColorTag));
      (GetByName('InfoItemText') as TLabelGI).SetText(LocalizedText('Items.Goods.Text.' + IntToStr(Ord(Instance.ItemType) + 1)));
    end
    else
    begin
      (GetByName('InfoItemName') as TLabelGI).SetText(WrapTextInColor(Instance.GetDisplayName, HighlightColorTag));
      (GetByName('InfoItemText') as TLabelGI).SetText(Instance.GetInfoText(HighlightColorTag));
    end;
    (GetByName('InfoItemSize') as TLabelGI).SetText(IntToStr(Instance.Weight));
    (GetByName('InfoItemPrice') as TLabelGI).SetText(IntToStr(Instance.Cost));
    with GetByName('InfoItemEmRace') as TImageGI do
    begin
      if Instance is TGoods then SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[oiNone].InternalName))
      else SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[Instance.OwnerId].InternalName));
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
    end;
  end;
  if CargoPickupZone = nil then
  begin
    CargoPickupZone := ab_Zone_Add;
    CargoPickupZone.Kind := 20;
    CargoPickupZone.Radius := ManualCargoPickupDistance;
    CargoPickupZone.RadiusDegrees := CargoPickupZone.Radius * 180 / (Pi * SphereRadius);
  end;
  CargoPickupZone.Longitude := PlayerArcadeShip.State.LongitudeDegrees;
  CargoPickupZone.PolarAngle := PlayerArcadeShip.State.PolarAngleDegrees;
  ab_Zone_UpdatePosition(CargoPickupZone);
  ab_Zone_UpdateImages(CargoPickupZone);
end;
{ @end $5083D8 }

{ @routine $508AE8 TfAB_CancelCargoPickup }
procedure TfAB.CancelCargoPickup;
begin
  if CargoPickupItem <> nil then
  begin
    if not IsCursorImageSelected('Main') then SetCursorByName('Main');
    ItemInfoWindow.SetActive(False);
    CargoPickupItem := nil;
    if CargoPickupZone <> nil then
    begin
      ab_Zone_Delete(CargoPickupZone);
      CargoPickupZone := nil;
    end;
  end;
end;
{ @end $508AE8 }

{ @routine $508B50 TfAB_OpenShipEquipment }
procedure TfAB.OpenShipEquipment(Sender: TObjectGI);
begin
  if (ArcadeViewMode <> avmExit) and (Player <> nil) and (PlayerArcadeShip <> nil) and (PlayerArcadeShip.Health > 0) then begin
    ForwardKeyDown := False;
    ReverseKeyDown := False;
    BrakeKeyDown := False;
    TurnLeftKeyDown := False;
    TurnRightKeyDown := False;
    PrimaryFireKeyDown := False;
    SecondaryFireKeyDown := False;
    Player.Hull.HullPoints := PlayerArcadeShip.Health;
    SetCursorActive(False);
    Present;
    CaptureScreenBackground;
    SetCursorActive(True);
    RunShipEquipment(Self);
    SyncWeaponInventory;
    UpdateWeaponPanel;
    Present;
  end;
end;
{ @end $508B50 }

{ @routine $508C1C TfAB_SyncWeaponInventory }
procedure TfAB.SyncWeaponInventory;
var
  SlotIndex: Integer;
  Item: TWeapon;
begin
  PlayerArcadeShip.WeaponCount := 0;
  for SlotIndex := 0 to Player.GetSlotCountForItemType(WeaponCategoryItemType) - 1 do begin
    Item := Player.FindEquippedItemInSlot(WeaponCategoryItemType, SlotIndex) as TWeapon;
    if (Item <> nil) and not Item.BrokenFlag then begin
      if (CampaignWeapons[PlayerArcadeShip.WeaponCount] <> Item) or
        (PlayerArcadeShip.Weapons[PlayerArcadeShip.WeaponCount].SlotData <> Item.AssignedSlotData) then begin
        ab_Weapon_Initialize(@PlayerArcadeShip.Weapons[PlayerArcadeShip.WeaponCount], Item.ItemType);
        CampaignWeapons[PlayerArcadeShip.WeaponCount] := Item;
        PlayerArcadeShip.Weapons[PlayerArcadeShip.WeaponCount].Ammo := 0;
        PlayerArcadeShip.Weapons[PlayerArcadeShip.WeaponCount].SlotData := Item.AssignedSlotData;
      end;
      with WeaponChargeImages[Item.AssignedSlotData and $7F] do begin
      if Item.AssignedSlotData and $80 <> 0 then SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF')
      else SetImagePath('GI,Bm.FormAB.' + GiResourceSuffix + 'WF2');
        SetImageKindX(ikxLeft);
      end;
      Inc(PlayerArcadeShip.WeaponCount);
    end;
  end;
  for SlotIndex := PlayerArcadeShip.WeaponCount to 4 do CampaignWeapons[SlotIndex] := nil;
  NormalizeWeaponSelection;
end;
{ @end $508C1C }

{ @routine $508E68 TfAB_PickUpItem }
procedure TfAB.PickUpItem(Item: TabItem);
var
  Instance: TItem;
  Index, Count: Integer;
begin
  Instance := Item.Item;
  Instance.GetGraphObject.DetachFromSpace;
  Instance.ReleaseGraphObject;
  Item.Item := nil;
  ab_Object_Delete(Item);
  if Instance is TArtefact then begin
    (Instance as TEquipment).EquippedFlag := False;
    Player.Artefacts.Add(Instance);
    if Instance is TArtefactTranclucator then
      ((Instance as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Player;
  end
  else if Instance is TProtoplasm then begin
    TProtoplasm(Instance).DropFlag := 0;
    (Instance as TEquipment).EquippedFlag := False;
    Count := Player.Inventory.Count;
    Index := 0;
    while Index < Count do begin
      if TItem(Player.Inventory[Index]).ItemType = t_Protoplasm then Break;
      Inc(Index);
    end;
    if Index < Count then begin
      Inc(TProtoplasm(Player.Inventory[Index]).Quantity, TProtoplasm(Instance).Quantity);
      Inc(TProtoplasm(Player.Inventory[Index]).Weight, TProtoplasm(Instance).Weight);
      Instance.Free;
    end
    else Player.Inventory.Add(Instance);
  end
  else if Instance is TEquipment then begin
    (Instance as TEquipment).EquippedFlag := False;
    Player.Inventory.Add(Instance);
  end
  else if Instance is TGoods then begin
    // Adds goods quantity without their purchase cost.
    Inc(Player.CargoGoods[(Instance as TGoods).ItemType].Count, (Instance as TGoods).Quantity);
    Instance.Free;
  end;
  Player.RefreshDerivedStats;
end;
{ @end $508E68 }

{ @routine $509060 TfAB_RandomRange }
function TfAB.RandomRange(BoundA, BoundB: Integer): Integer;
begin
  RandomSeed := RandomSeed div 7981 + (RandomSeed * 7981 + 567);
  if BoundA < BoundB then Result := RandomSeed mod Cardinal(BoundB - BoundA + 1) + BoundA
  else Result := RandomSeed mod Cardinal(BoundA - BoundB + 1) + BoundB;
end;
{ @end $509060 }

{ @routine $5090B4 TfAB_RandomFloat }
function TfAB.RandomFloat(BoundA, BoundB: Double): Double;
begin
  RandomSeed := RandomSeed div 7931 + (RandomSeed * 7981 + 567);
  Result := SeededRandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1), RandomSeed) / 1000;
end;
{ @end $5090B4 }

{ @routine $509138 TfAB_UpdateHelp }
procedure TfAB.UpdateHelp(Sender: TObjectGI; Show: Boolean);
begin
  BattleHelpLabel.SetActive(Show);
  if Show then BattleHelpLabel.SetText(Sender.HelpText);
end;
{ @end $509138 }

{ @routine $509164 TfAB_ControlMouseEnter }
procedure TfAB.ControlMouseEnter(Sender: TObjectGI);
begin
  UpdateHelp(Sender, True);
end;
{ @end $509164 }

{ @routine $50916C TfAB_ControlMouseLeave }
procedure TfAB.ControlMouseLeave(Sender: TObjectGI);
begin
  HideHelp;
end;
{ @end $50916C }

{ @routine $509174 TfAB_HideHelp }
procedure TfAB.HideHelp;
begin
  BattleHelpLabel.SetActive(False);
end;
{ @end $509174 }

{ @routine $509184 TfAB_ShowVictory }
procedure TfAB.ShowVictory;
var ItemsPanel: TPanelGI; Index: Integer; Caption: TLabelGI; Panel: TObjectGI;
begin
  GetByName('WinItem').FreeOwnedChildren;
  ItemsPanel := GetByName('WinItem') as TPanelGI;
  ItemsPanel.FreeOwnedChildren;
  if ListedObjects.Count <= 0 then
    ItemsPanel.SetSize(Classes.Point(ItemsPanel.ClientSize.X, 0))
  else
  begin
    ItemsPanel.SetSize(Classes.Point(ItemsPanel.ClientSize.X, (ListedObjects.Count + 1) * GiScalePixels(20) + 5));
    Caption := TLabelGI.Create(ItemsPanel);
    begin
      Caption.SetFontName(HitPointFontName);
      Caption.SetPosition(Classes.Point(0, 0 * GiScalePixels(20)));
      Caption.SetSize(Classes.Point(ItemsPanel.ClientSize.X, GiScalePixels(20)));
      Caption.SetTextAlignX(taxCenter);
      Caption.SetTextAlignY(tayCenterEx);
      Caption.SetText(LocalizedColorText('FormAB.WinItems'));
      Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(219, 218, 156));
    end;
    for Index := 0 to ListedObjects.Count - 1 do
      begin
        Caption := TLabelGI.Create(ItemsPanel);
        Caption.SetFontName(HitPointFontName);
        Caption.SetPosition(Classes.Point(0, (Index + 1) * GiScalePixels(20) + 5));
        Caption.SetSize(Classes.Point(ItemsPanel.ClientSize.X, GiScalePixels(20)));
        Caption.SetTextAlignX(taxCenter);
        Caption.SetTextAlignY(tayCenterEx);
        Caption.SetText(TEquipment(ListedObjects[Index]).GetDisplayName);
        Caption.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
      end;
  end;
  Panel := VictoryPanel;
  begin
    Panel.SetSize(Classes.Point(Panel.ClientSize.X, ItemsPanel.LocalPosition.Y + ItemsPanel.ClientSize.Y + GiScalePixels(20)));
    Panel.SetActive(True);
  end;
  Panel := GetByName('WinShr');
    Panel.SetSize(Classes.Point(Panel.ClientSize.X, ItemsPanel.LocalPosition.Y + ItemsPanel.ClientSize.Y + GiScalePixels(20)));
  if VictoryTimer <> 0 then
  begin
    CancelCallbackTimer(VictoryTimer);
    VictoryTimer := 0;
  end;
  VictoryTimer := ScheduleCallbackTimer(10000, 999999, CloseVictory, 0);
end;
{ @end $509184 }

{ @routine $5094EC TfAB_CloseVictory }
procedure TfAB.CloseVictory(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  VictoryPanel.SetActive(False);
  GetByName('WinItem').FreeOwnedChildren;
  if VictoryTimer <> 0 then
  begin
    CancelCallbackTimer(VictoryTimer);
    VictoryTimer := 0;
  end;
end;
{ @end $5094EC }

{ @routine $509540 TfAB_SelectMusic }
procedure TfAB.SelectMusic;
begin
  // Native arcade playback follows the hyper-space music setting.
  if MusicInHyper then MusicManager.PlayCategory('ArcadeBattle')
  else MusicManager.RequestFadeOut;
end;
{ @end $509540 }

end.

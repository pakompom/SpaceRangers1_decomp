unit Globals;
// Unit bracket (inferred): CODE 0x004E4954..0x004EFD87; inclusive evidence, not full bounds.
// Shared screen references.
interface
uses fFilmFile, ThreadCalc, fShip2, fStarMap, fRuinsTalk, fGov, fPlanetQuest, fSaveManager, fHangar, fMainForm, fGameSettings, fIntroduction, fPlanet, fPlanetNO, fGameEnd, fGameMenu, fGameLoad, fAbout, fJump, fGoodsShop, fDebugMusic, fLoad, EC_CPUTime, fEquipmentShop, fCfgSettings, fInfo, fScore, fScaner, fGalaxy2, fTalk, fFilm, GI_MessageLoop, ab_MainForm, SE_Process, aGalaxy, aPlanet, aPlayer, aShip, EC_Struct, EC_Expression, aEFilm, EC_Buf, SyncObjs, SE_Space, SE_Planet, fRating, fRewards;
type
  TScriptTemplUnit = class(TObjectEx) // @size $20
  public
    destructor Destroy; override; // @addr $4E8E50
    constructor Create; // @addr $4E8E04

    ConfigValue: Integer; // @offset $04 TryStartScriptInstanceFromTemplate.
    Name: WideString; // @offset $08 SaveToBuffer and native template lookup.
    FileName: WideString; // @offset $0C CompileScriptTemplateCondition.
    UseCount: Integer; // @offset $10
    LastTurn: Integer; // @offset $14
    ActiveScriptIndex: Integer; // @offset $18
    ConditionCode: TCodeEC; // @offset $1C
  end;
  SShipFC = record // @size $08
    SpaceObject: TObjectSE; // @offset $00 Copied by generated ships.
    PortraitImagePath: WideString; // @offset $04 Returned by TShip.GetShipPortraitImagePath $5AD268.
  end;
  TPlanetSpaceTemplate = record // @size $08
    Radius: Integer; // @offset $00
    SpaceObject: TPlanetSE; // @offset $04 Copied by planet generation.
  end;
  TPlanetTempl = class(TObject) // @size $18
  public
    Radius: Integer; // @offset $04
    SmallMaskName: WideString; // @offset $08
    SmallLightName: WideString; // @offset $0C
    MaskName: WideString; // @offset $10
    LightName: WideString; // @offset $14
  end;
  TSputnikTempl = class(TObject) // @size $0C
  public
    Radius: Integer; // @offset $04
    MaskName: WideString; // @offset $08
  end;
  TPlayerMessageKind = (pmGalaxy = 0, pmEther = 1, pmShip = 2, pmQuestNormal = 3, pmQuestOk = 4, pmQuestCancel = 5,
    pmTips = 6, pmUser = 7); // @size $01
  TMessagePlayerTypeGraph = record // @size $10
    NormalImage: WideString; // @offset $00
    ActiveImage: WideString; // @offset $04
    PressedImage: WideString; // @offset $08
    LifetimeTurns: Integer; // @offset $0C
  end;
var
  PlayerMessagePresentations: array[TPlayerMessageKind] of TMessagePlayerTypeGraph = (
    (NormalImage: 'GalaxyN'; ActiveImage: 'GalaxyA'; PressedImage: 'GalaxyD'; LifetimeTurns: 10),
    (NormalImage: 'EtherN'; ActiveImage: 'EtherA'; PressedImage: 'EtherD'; LifetimeTurns: 0),
    (NormalImage: 'ShipN'; ActiveImage: 'ShipA'; PressedImage: 'ShipD'; LifetimeTurns: 5),
    (NormalImage: 'QuestNormalN'; ActiveImage: 'QuestNormalA'; PressedImage: 'QuestNormalD'; LifetimeTurns: 1000000),
    (NormalImage: 'QuestOkN'; ActiveImage: 'QuestOkA'; PressedImage: 'QuestOkD'; LifetimeTurns: 1000000),
    (NormalImage: 'QuestCancelN'; ActiveImage: 'QuestCancelA'; PressedImage: 'QuestCancelD'; LifetimeTurns: 1000000),
    (NormalImage: 'TipsN'; ActiveImage: 'TipsA'; PressedImage: 'TipsD'; LifetimeTurns: 182),
    (NormalImage: 'UserN'; ActiveImage: 'UserA'; PressedImage: 'UserD'; LifetimeTurns: 1000000)
  ); // @addr $6185E8
  ReloadScriptTemplates: Boolean = True; // @addr $618668
  StandaloneQuestMode: Boolean = False; // @addr $61866C
  ScannerTarget: TObject = nil; // @addr $618670 Selected by the star map and cast to TShip by the scanner.
  ScriptDialogIndex: Integer = -1; // @addr $618674
  AwardSubject: TObject = nil; // @addr $618678 Ship shown by screenRewards; read with a native as TShip.
  PlayerStarDayPrepared: Boolean = False; // @addr $61867C Gates ambient messages in TNormalShip.NextDay.
  PreviousFilmActivity: Integer = 0; // @addr $618680
  FilmSoundEffectsEnabled: Boolean = True; // @addr $618684
  TurnCalculationThread: TThreadCalc = nil; // @addr $618688
type
  TMessagePlayer = class(TObjectEx) // @size $2C
  public
    Prev: TMessagePlayer; // @offset $04
    Next: TMessagePlayer; // @offset $08
    Key: WideString; // @offset $0C
    Kind: TPlayerMessageKind; // @offset $10
    Turn: Integer; // @offset $14
    Text: WideString; // @offset $18
    TargetIds: array[0..2] of Cardinal; // @offset $1C Ship dialogue uses the first two entries.
    WasRead: Boolean; // @offset $28
    NotificationSoundPlayed: Boolean; // @offset $29
    constructor Create; // @addr $4E877C
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $4E87B4
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $4E8828
  end;
var
  MainMenuScreen: TfMainForm; // @addr $61CBD0
  NewGameScreen: TfGameSettings; // @addr $61CBD4
  IntroductionScreen: TfIntroduction; // @addr $61CBD8
  HangarScreen: TfHangar; // @addr $61CBDC
  PlanetScreen: TfPlanet; // @addr $61CBE0
  UninhabitedPlanetScreen: TfPlanetNO; // @addr $61CBE4
  PlanetQuestScreen: TfPlanetQuest; // @addr $61CBE8
  RuinsTalkScreen: TfRuinsTalk; // @addr $61CBEC
  ArcadeBattleScreen: TfAB; // @addr $61CBF0
  EquipmentShopScreen: TfEquipmentShop; // @addr $61CBF4
  GoodsShopScreen: TfGoodsShop; // @addr $61CBF8
  GovernmentScreen: TfGov; // @addr $61CBFC
  InfoScreen: TfInfo; // @addr $61CC00
  RatingScreen: TfRating; // @addr $61CC04
  RewardsScreen: TfRewards; // @addr $61CC08
  ShipScreen: TfShip2; // @addr $61CC0C
  TalkScreen: TfTalk; // @addr $61CC10
  ScannerScreen: TfScaner; // @addr $61CC14
  StarMapScreen: TfStarMap; // @addr $61CC18
  FilmScreen: TfFilm; // @addr $61CC1C
  GalaxyMapScreen: TfGalaxy2; // @addr $61CC20
  JumpScreen: TfJump; // @addr $61CC24
  LoadScreen: TfLoad; // @addr $61CC28
  SaveManagerScreen: TfSaveManager; // @addr $61CC2C
  GameLoadScreen: TfGameLoad; // @addr $61CC30
  GameMenuScreen: TfGameMenu; // @addr $61CC34
  SettingsScreen: TfCfgSettings; // @addr $61CC38
  GameEndScreen: TfGameEnd; // @addr $61CC3C
  AboutScreen: TfAbout; // @addr $61CC40
  ScoreScreen: TfScore; // @addr $61CC44
  SpaceObjectUiLoop: TMessageLoopGI; // @addr $61CC48
  SpaceViewPosition: TPointF; // @addr $61CC4C
  FilmCameraFollow: Boolean; // @addr $61CC54
  TalkShip: TShip; // @addr $61CC58
  TalkPlanet: TPlanet; // @addr $61CC5C
  TalkScripted: Boolean; // @addr $61CC60
  TalkScriptedKind: Byte; // @addr $61CC61
  TalkScriptedAmount: Integer; // @addr $61CC64
  TalkScriptedAccepted: Boolean; // @addr $61CC68
  ScriptedTalkText: WideString; // @addr $61CC6C
  ScreenLoadMode: Byte; // @addr $61CC70
  ScriptTemplates: TList; // @addr $61CC74
  SharedScriptVariables: TVarArrayEC; // @addr $61CC78
  GlobalScriptVariables: TVarArrayEC; // @addr $61CC7C
  ScriptTemplateStartRequested: Boolean; // @addr $61CC80
  ScenarioState: TScenarioState; // @addr $61CC84 Directly accessed by the endgame predicates.
  PlayerName: WideString; // @addr $61CC88 Copied from TPlayer.Name after loading.
  LegacyResourceName1: WideString = 'Laser.W1'; // @addr $61868C Native initialized resource name; remaining role unresolved.
  LegacyResourceName2: WideString = 'Anim.H1'; // @addr $618690 Native initialized resource name; remaining role unresolved.
  LegacyResourceName3: WideString = 'Anim.E1'; // @addr $618694 Native initialized resource name; remaining role unresolved.
  FilmHistory: TFilmFile = nil; // @addr $618698 Direct accesses in the native Globals startup and shutdown.
  CacheLoader: TCacheLoader = nil; // @addr $61869C
  SaveManagerMode: TSaveManagerMode = smmLoad; // @addr $6186A0
  PlanetPanelRotation: Integer = 0; // @addr $6186A4 Shared surface-map offset advanced by planet navigation.
  TalkRequestEvent: Cardinal = 0; // @addr $6186A8 Second event in the calculation/dialogue waits.
  TalkCompletedEvent: Cardinal = 0; // @addr $6186AC Set when the star map resumes from dialogue.
  LegacySaveByte1: Byte = 0; // @addr $6186B0 Only serialized and restored; no other native readers or writers found.
  LegacySaveByte2: Byte = 0; // @addr $6186B4
  LegacySaveByte3: Byte = 25; // @addr $6186B8
  PlanetRenderTemplates: TList = nil; // @addr $6186BC
  MinimapFrameCounter: Integer = 0; // @addr $6186C0
  SkipPublisherIntro: Boolean = False; // @addr $6186C4
  NewGameGenerationThread: TThreadCreateNewGame; // @addr $61CC8C Direct cleanup access at $4E9216.
  ShownPlayerTips: Cardinal; // @addr $61CC90
  StarMapWeaponPanelOpen: Boolean; // @addr $61CC94 Visibility of PS_Up; toggled by TfStarMap.ToggleWeaponPanelClicked.
type
  TGreetingCountMask = set of 0..15; // @size $02
var
  PrimaryFilm: TEFilm; // @addr $61CC98
  SecondaryFilm: TEFilm; // @addr $61CC9C
  TrailingFilmEffects: TEFilmEnd; // @addr $61CCA0
  StarPreparationFlag: Boolean; // @addr $61CCA4 True during PrepareNextDay, or RecordFilm during NextDay; cleared after turn processing.
  DebugMusic: TfDebugMusic; // @addr $61CCA8
  SpaceProcess: TProcessSE; // @addr $61CCAC
  GlobalCpuTimes: TCPUTimeEC; // @addr $61CCB0
  LocalCpuTimes: TCPUTimeEC; // @addr $61CCB4
  ActiveLoadBuffer: TBufEC; // @addr $61CCB8 Borrowed by the loading screen while the worker reads the save.
  PersistentPlayerMessageLock: TCriticalSection; // @addr $61CCBC
  FirstPersistentPlayerMessage: TMessagePlayer; // @addr $61CCC0
  LastPersistentPlayerMessage: TMessagePlayer; // @addr $61CCC4
  ArcadeExplosionSounds: array of WideString; // @addr $61CCC8
  ArcadeItemSounds: array of WideString; // @addr $61CCCC
  ArcadeHitSounds: array of WideString; // @addr $61CCD0
  ArcadeWeaponFirstSounds: array[0..14] of WideString; // @addr $61CCD4
  ArcadeWeaponLoopSounds: array[0..14] of WideString; // @addr $61CD10
  ArcadeWeaponLoopTicks: array[0..14] of Integer; // @addr $61CD4C
procedure InitializeShipGreetingDefinitions; // @addr $4E92F4
procedure InitializeGovernmentGreetingDefinitions; // @addr $4EDA48

function FindScriptTemplateIndex(const Name: WideString): Integer; // @addr $4E8E84

procedure ClearPersistentPlayerMessages; // @addr $4E88F8
function AddOrUpdatePlayerBubble(Kind: TPlayerMessageKind; Turn: Integer; const Text, Key: WideString): TMessagePlayer; // @addr $4E8C0C

function SelectSpaceImageTemplateFromSeed(Kind: Integer; Seed: Cardinal): Integer; // @addr $4E911C @note "Weighted selection restricted to Kind; returns 0 if no weight is available."

function SelectSpaceImageTemplate(Kind: Integer): Integer; // @addr $4E91B8

function CountPersistentPlayerMessages: Integer; // @addr $4E895C

function IsPersistentPlayerMessageQueued(MessageEntry: TMessagePlayer): Boolean; // @addr $4E89B4

procedure RemovePersistentPlayerMessage(MessageEntry: TMessagePlayer); // @addr $4E8A1C

function FindPlayerBubbleByText(const Text: WideString): TMessagePlayer; // @addr $4E8AA0

function FindPlayerBubbleByKey(const Key: WideString): TMessagePlayer; // @addr $4E8B0C

function CreatePersistentPlayerMessage: TMessagePlayer; // @addr $4E8B78

procedure PruneExpiredPersistentPlayerMessages; // @addr $4E8D24

procedure CollectInactiveScriptTemplates(Dest: TList); // @addr $4E8EC8 @note "Clears Dest, borrows templates with ActiveScriptIndex < 0, then performs twice Count seeded swaps. Chaotic RNG mode ignores the seeds."

function ShowPlayerTipOnce(Index: Integer): Boolean; // @addr $4E8FC0 @note "Sets the shown bit and enqueues localized Tips.00-style player text; returns whether a new tip was shown."

function HasShownPlayerTip(Index: Integer): Boolean; // @addr $4E9108

function IsKlingMotherShipFollowActive: Boolean; // @addr $4E4F08

procedure InitializeGlobalUiRuntime; // @addr $4E5190
procedure FinalizeGlobalUiRuntime; // @addr $4E808C
procedure RecreateSpaceProcess(const ConfigName: WideString); // @addr $4E8640

procedure SwapTurnFilms; // @addr $4E8764 Exchanges the producer and playback films.

procedure InitializeScriptHostRuntime; // @addr $4E4F34
procedure FinalizeScriptHostRuntime; // @addr $4E503C
procedure RunMainScreenStateLoop; // @addr $4E8674

procedure VerifyGalaxyIntegrityCallback; // @addr $4E91D4
procedure ProtectGalaxyIntegrityCallback; // @addr $4E920C
var
  ShipRenderTemplates: array[oiMaloc..oiGaal, 0..5] of SShipFC; // @addr $61CD88 Coalition hull or planet owner, then ranger/warrior/pirate/transport/liner/diplomat.
  KlissanRenderTemplates: array[0..5] of SShipFC; // @addr $61CE78 Indexed by Ord(KlingType).
  PlanetSpaceTemplates: array of TPlanetSpaceTemplate; // @addr $61CEA8 First seven entries describe the Solar system.
const
  // A greeting definition with no goods condition.
  GreetingDefinitionNoGoods = t_Hull;
  // Skips the goods checks while selecting a greeting.
  GreetingSelectionNoGoods = t_PhotonGun;
type
  TGreetingCondition = (gcYes = 0, gcNo = 1, gcAny = 2); // @size $01
  TGreetingFlightKind = (gfAny = 0, gfToPlanet = 1, gfToStar = 2, gfToItem = 3, gfToShip = 4); // @size $01
  TShipGreetingsInfo = object // @size $7C
    Name: WideString; // @offset $00
    Priority: Integer; // @offset $04
    AutoTalk: TGreetingCondition; // @offset $08
    FlyType: TGreetingFlightKind; // @offset $09
    ShipType: TGreetingShipCategories; // @offset $0A
    Relations: TRelationLevels; // @offset $0B
    ShipRace: TOwnerSet; // @offset $0C
    PlayerRace: TOwnerSet; // @offset $0D
    ShipRaceIsPlayerRace: TGreetingCondition; // @offset $0E
    PlayerAttackGoodShip: TGreetingCondition; // @offset $0F
    InFear: TGreetingCondition; // @offset $10
    ShipBadFlyToShip: TGreetingCondition; // @offset $11
    ShipBadType: TGreetingShipCategories; // @offset $12
    ShipBadRace: TOwnerSet; // @offset $13
    ShipFlyToPlayer: TGreetingCondition; // @offset $14
    PlayerFlyToShip: TGreetingCondition; // @offset $15
    PlayerIsShipBad: TGreetingCondition; // @offset $16
    ShipTurnBeforeEndOrder: TGreetingCountMask; // @offset $17
    PlayerTurnBeforeEndOrder: TGreetingCountMask; // @offset $19
    ShipBadTurnBeforeEndOrder: TGreetingCountMask; // @offset $1B
    ShipStatus: TRangerCareerSet; // @offset $1D
    PlayerStatus: TRangerCareerSet; // @offset $1E
    ShipStrength: TStandardCounts; // @offset $1F
    PlayerStrength: TStandardCounts; // @offset $20
    ShipStructure: TStandardCounts; // @offset $21
    PlayerStructure: TStandardCounts; // @offset $22
    ShipRating: TStandardCounts; // @offset $23
    PlayerRating: TStandardCounts; // @offset $24
    ShipRank: TCoalitionRanks; // @offset $25
    PlayerRank: TCoalitionRanks; // @offset $26
    RatingShipWithPlayer: TStandardCounts; // @offset $27
    RankShipWithPlayer: TStandardCounts; // @offset $28
    StrengthShipWithPlayer: TStandardCounts; // @offset $29
    Goods: TItemType; // @offset $2A
    ShipGoodsCnt: TStandardCounts; // @offset $2B
    PlayerGoodsCnt: TStandardCounts; // @offset $2C
    ShipHaveGoods: TGreetingCondition; // @offset $2D
    PlayerHaveGoods: TGreetingCondition; // @offset $2E
    ShipGoodsTypeCnt: TGreetingCountMask; // @offset $2F
    PlayerGoodsTypeCnt: TGreetingCountMask; // @offset $31
    ShipMayScanPlayer: TGreetingCondition; // @offset $33
    RangerInCurStar: TGreetingCountMask; // @offset $34
    PirateInCurStar: TGreetingCountMask; // @offset $36
    KlingInCurStar: TGreetingCountMask; // @offset $38
    WarriorInCurStar: TGreetingCountMask; // @offset $3A
    TransportInCurStar: TGreetingCountMask; // @offset $3C
    LastPlanetRace: TOwnerSet; // @offset $3E
    LastPlanetRelations: TRelationLevels; // @offset $3F
    LastPlanetGoodsCnt: TStandardCounts; // @offset $40
    LastPlanetGoodsSale: TStandardCounts; // @offset $41
    LastPlanetGoodsBuy: TStandardCounts; // @offset $42
    LastPlanetIsHomePlanet: TGreetingCondition; // @offset $43
    LastPlanetRaceIsShipRace: TGreetingCondition; // @offset $44
    LastPlanetRaceIsPlayerRace: TGreetingCondition; // @offset $45
    LastPlanetEconomy: TPlanetEconomies; // @offset $46
    LastPlanetGovernment: TPlanetGovernments; // @offset $47
    LastPlanetInCurStar: TGreetingCondition; // @offset $48
    LastPlanetDistToShipInTurn: TGreetingCountMask; // @offset $49
    RangerInLastPlanetStar: TGreetingCountMask; // @offset $4B
    PirateInLastPlanetStar: TGreetingCountMask; // @offset $4D
    KlingInLastPlanetStar: TGreetingCountMask; // @offset $4F
    WarriorInLastPlanetStar: TGreetingCountMask; // @offset $51
    TransportInLastPlanetStar: TGreetingCountMask; // @offset $53
    ToPlanetRace: TOwnerSet; // @offset $55
    ToPlanetRelations: TRelationLevels; // @offset $56
    ToPlanetGoodsCnt: TStandardCounts; // @offset $57
    ToPlanetGoodsSale: TStandardCounts; // @offset $58
    ToPlanetGoodsBuy: TStandardCounts; // @offset $59
    ToPlanetIsHomePlanet: TGreetingCondition; // @offset $5A
    ToPlanetRaceIsShipRace: TGreetingCondition; // @offset $5B
    ToPlanetRaceIsPlayerRace: TGreetingCondition; // @offset $5C
    ToPlanetEconomy: TPlanetEconomies; // @offset $5D
    ToPlanetGovernment: TPlanetGovernments; // @offset $5E
    ToPlanetIsLastPlanet: TGreetingCondition; // @offset $5F
    ToPlanetRaceIsLastPlanetRace: TGreetingCondition; // @offset $60
    HomePlanetInToStar: TGreetingCondition; // @offset $61
    HomePlanetInCurStar: TGreetingCondition; // @offset $62
    ToStarControlByKling: TGreetingCondition; // @offset $63
    ToStarInBattle: TGreetingCondition; // @offset $64
    RangerInToStar: TGreetingCountMask; // @offset $65
    PirateInToStar: TGreetingCountMask; // @offset $67
    KlingInToStar: TGreetingCountMask; // @offset $69
    WarriorInToStar: TGreetingCountMask; // @offset $6B
    TransportInToStar: TGreetingCountMask; // @offset $6D
    ItemType: WideString; // @offset $70
    ShipNeedInItem: TGreetingCondition; // @offset $74
    ToShipType: TGreetingShipCategories; // @offset $75
    ToShipRace: TOwnerSet; // @offset $76
    ToShipInPlanet: TGreetingCondition; // @offset $77
    ToShipBad: TGreetingCondition; // @offset $78
  end;
  TGovGreetingsInfo = record // @size $38
    Name: WideString; // @offset $0
    Priority: Integer; // @offset $4
    PlayerRace: TOwnerSet; // @offset $8
    PlayerStatus: TRangerCareerSet; // @offset $9
    PlayerRating: TStandardCounts; // @offset $A
    PlayerRank: TCoalitionRanks; // @offset $B
    Goods: TItemType; // @offset $C
    CurPlanetRace: TOwnerSet; // @offset $D
    CurPlanetRaceIsPlayerRace: TGreetingCondition; // @offset $E
    CurPlanetRelations: TRelationLevels; // @offset $F
    CurPlanetGoodsCnt: TStandardCounts; // @offset $10
    CurPlanetGoodsSale: TStandardCounts; // @offset $11
    CurPlanetGoodsBuy: TStandardCounts; // @offset $12
    CurPlanetEconomy: TPlanetEconomies; // @offset $13
    CurPlanetGovernment: TPlanetGovernments; // @offset $14
    RangerInCurStar: TGreetingCountMask; // @offset $15
    PirateInCurStar: TGreetingCountMask; // @offset $17
    KlingInCurStar: TGreetingCountMask; // @offset $19
    WarriorInCurStar: TGreetingCountMask; // @offset $1B
    TransportInCurStar: TGreetingCountMask; // @offset $1D
    CurStarInBattle: TGreetingCondition; // @offset $1F
    ToPlanetRace: TOwnerSet; // @offset $20
    ToPlanetRaceIsPlayerRace: TGreetingCondition; // @offset $21
    ToPlanetRaceIsCurPlanetRace: TGreetingCondition; // @offset $22
    ToPlanetRelations: TRelationLevels; // @offset $23
    ToPlanetGoodsCnt: TStandardCounts; // @offset $24
    ToPlanetGoodsSale: TStandardCounts; // @offset $25
    ToPlanetGoodsBuy: TStandardCounts; // @offset $26
    ToPlanetEconomy: TPlanetEconomies; // @offset $27
    ToPlanetGovernment: TPlanetGovernments; // @offset $28
    ToPlanetInCurStar: TGreetingCondition; // @offset $29
    RangerInToStar: TGreetingCountMask; // @offset $2A
    PirateInToStar: TGreetingCountMask; // @offset $2C
    KlingInToStar: TGreetingCountMask; // @offset $2E
    WarriorInToStar: TGreetingCountMask; // @offset $30
    TransportInToStar: TGreetingCountMask; // @offset $32
    ToStarControlByKling: TGreetingCondition; // @offset $34
    ToStarInBattle: TGreetingCondition; // @offset $35
  end;
var
  UselessItemRemainsCount: Integer; // @addr $61CEAC
  ShipGreetingDefinitions: array of TShipGreetingsInfo; // @addr $61CEB0
  ShipGreetingCount: Integer; // @addr $61CEB4
  GovernmentGreetingDefinitions: array of TGovGreetingsInfo; // @addr $61CEB8
  GovernmentGreetingCount: Integer; // @addr $61CEBC

implementation

// @unit-initialization $4EFD74
// @unit-finalization $4EFB68

uses Windows, aPath, GR_Demo, aKling, SysUtils, Math, GR_Main, EC_BlockPar, GlobalsV, EC_Str, GI_Main, EC_CacheGAI, SE_Ship2, aScript, aConst, fHangar, fSaveManager, fPlanetQuest, fRuinsTalk, fGov, fShip2, fStarMap;
{ @routine $4E4F08 IsKlingMotherShipFollowActive }
function IsKlingMotherShipFollowActive: Boolean;
begin
  Result := (ScenarioState = scenPeaceRachekhanAtLarge) and (KlingMotherShip <> nil) and KlingMotherShip.InNormalSpace;
end;
{ @end $4E4F08 }

{ @routine $4E4F34 InitializeScriptHostRuntime }
procedure InitializeScriptHostRuntime;
begin
  PersistentPlayerMessageLock := TCriticalSection.Create;
  GetLastError;
  InitializePathNodePool;
  FilmHistory := TFilmFile.Create;
  TalkRequestEvent := CreateEvent(nil, False, False, nil);
  TalkCompletedEvent := CreateEvent(nil, False, False, nil);
  TurnCalculationThread := TThreadCalc.Create;
  TurnCalculationThread.SetPriority(2);
  ScriptTemplates := TList.Create;
  GlobalScriptVariables := TVarArrayEC.Create;
  SharedScriptVariables := TVarArrayEC.Create;
  GlobalScriptVariables.Add('GRunFrom', vkInt).SetInt(0);
  GlobalScriptVariables.Add('GRunStar', vkDword).SetInt(0);
  InitializeScriptEngine;
end;
{ @end $4E4F34 }
{ @routine $4E503C FinalizeScriptHostRuntime }
procedure FinalizeScriptHostRuntime;
var
  Owner: TOwnerId;
  Kind: Byte;
  Index: Integer;
begin
  FinalizeScriptEngine;
  if GlobalScriptVariables <> nil then
  begin
    GlobalScriptVariables.Free;
    GlobalScriptVariables := nil;
  end;
  if SharedScriptVariables <> nil then
  begin
    SharedScriptVariables.Free;
    SharedScriptVariables := nil;
  end;
  if ScriptTemplates <> nil then
  begin
    for Index := 0 to ScriptTemplates.Count - 1 do TObject(ScriptTemplates[Index]).Free;
    ScriptTemplates.Free;
    ScriptTemplates := nil;
  end;
  if TurnCalculationThread <> nil then
  begin
    TurnCalculationThread.Free;
    TurnCalculationThread := nil;
  end;
  if TalkRequestEvent <> 0 then
  begin
    CloseHandle(TalkRequestEvent);
    TalkRequestEvent := 0;
  end;
  if TalkCompletedEvent <> 0 then
  begin
    CloseHandle(TalkCompletedEvent);
    TalkCompletedEvent := 0;
  end;
  for Owner := oiMaloc to oiGaal do
    for Kind := 0 to 5 do
      if ShipRenderTemplates[Owner, Kind].SpaceObject <> nil then
      begin
        ShipRenderTemplates[Owner, Kind].SpaceObject.Free;
        ShipRenderTemplates[Owner, Kind].SpaceObject := nil;
      end;
  for Kind := 0 to 5 do
    if KlissanRenderTemplates[Kind].SpaceObject <> nil then
    begin
      KlissanRenderTemplates[Kind].SpaceObject.Free;
      KlissanRenderTemplates[Kind].SpaceObject := nil;
    end;
  if FilmHistory <> nil then
  begin
    FilmHistory.Free;
    FilmHistory := nil;
  end;
  FinalizePathNodePool;
  if PersistentPlayerMessageLock <> nil then
  begin
    PersistentPlayerMessageLock.Free;
    PersistentPlayerMessageLock := nil;
  end;
end;
{ @end $4E503C }

{ @routine $4E5190 InitializeGlobalUiRuntime }
procedure InitializeGlobalUiRuntime;
var Owner: TOwnerId; Index, Count: Integer; SatelliteTemplate: TSputnikTempl; PlanetTemplate: TPlanetTempl; Section: TBlockParEC; Kind: Byte; ScriptTemplate: TScriptTemplUnit; Text: WideString;
begin
  GlobalCpuTimes := TCPUTimeEC.Create;
  LocalCpuTimes := TCPUTimeEC.Create;
  GlobalCpuTimes.FileName := '#ctg.log';
  LocalCpuTimes.FileName := '#ctl.log';
  CacheLoader := TCacheLoader.Create;
  if GameScreenWidth = 800 then begin
    HitPointFontName := 'Font.1Normal';
    ScoreFontName := 'Font.1NormalBold';
    NormalFontName := 'Font.1Big';
    AuthorsFontName := 'Font.1Authors';
    NormalPlusFontName := 'Font.1NormalPlus';
  end else begin
    HitPointFontName := 'Font.2Normal';
    ScoreFontName := 'Font.2NormalBold';
    NormalFontName := 'Font.2Big';
    AuthorsFontName := 'Font.2Authors';
    NormalPlusFontName := 'Font.2NormalPlus';
  end;
  if Config.CountParamsByPath('ChangeAutoPilot') > 0 then begin
    ChangeAutoPilot := ExtractDigitsToIntW(Config.GetParamByPath('ChangeAutoPilot'));
    case ChangeAutoPilot of
      2,4,6,20: ;
    else ChangeAutoPilot := 4;
    end;
  end;
  if Config.CountParamsByPath('SkipGiper') > 0 then SkipHyperAnimation := ParseEnabledNameGI(Config.GetParamByPath('SkipGiper'));
  if Config.CountParamsByPath('WriteLossResult') > 0 then AllowDefeatScoreExport := ParseEnabledNameGI(Config.GetParamByPath('WriteLossResult'));
  if Config.CountParamsByPath('Wind') > 0 then WindDensity := ExtractDigitsToIntW(Config.GetParamByPath('Wind'));
  if Config.CountParamsByPath('Skip1C') > 0 then SkipPublisherIntro := ParseEnabledNameGI(Config.GetParamByPath('Skip1C'));
  if Config.CountParamsByPath('TestQuest') > 0 then TestQuestPath := Config.GetParamByPath('TestQuest');
  if Config.CountParamsByPath('ShipTail') > 0 then ShipTail := ExtractDigitsToIntW(Config.GetParamByPath('ShipTail'));
  if Config.CountParamsByPath('AnimCaptain') > 0 then AnimCaptain := ParseEnabledNameGI(Config.GetParamByPath('AnimCaptain'));
  if Config.CountParamsByPath('AnimItem') > 0 then AnimItem := ParseEnabledNameGI(Config.GetParamByPath('AnimItem'));
  if Config.CountParamsByPath('BGImage') > 0 then BGImage := ParseEnabledNameGI(Config.GetParamByPath('BGImage'));
  if Config.CountParamsByPath('Comet') > 0 then CometDensity := ExtractDigitsToIntW(Config.GetParamByPath('Comet'));
  if Config.CountParamsByPath('AnimShipFull') > 0 then AnimShipFull := ParseEnabledNameGI(Config.GetParamByPath('AnimShipFull'));
  if Config.CountParamsByPath('AnimCity') > 0 then AnimCity := ParseEnabledNameGI(Config.GetParamByPath('AnimCity'));
  if Config.CountParamsByPath('AnimGov') > 0 then AnimGov := ParseEnabledNameGI(Config.GetParamByPath('AnimGov'));
  if Config.CountParamsByPath('AnimStar') > 0 then AnimStar := ParseEnabledNameGI(Config.GetParamByPath('AnimStar'));
  if Config.CountParamsByPath('AnimHangar') > 0 then AnimHangar := ParseEnabledNameGI(Config.GetParamByPath('AnimHangar'));
  if Config.CountParamsByPath('CircleAction') > 0 then HideActionCircle := ParseEnabledNameGI(Config.GetParamByPath('CircleAction'));
  if Config.CountParamsByPath('StaticBackground') > 0 then StaticBackground := ParseEnabledNameGI(Config.GetParamByPath('StaticBackground'));
  if Config.CountParamsByPath('ScrollTime') > 0 then ScrollTime := StrToInt(Config.GetParamByPath('ScrollTime'));
  if Config.CountParamsByPath('ScrollStep') > 0 then ScrollSpeed := StrToInt(Config.GetParamByPath('ScrollStep'));
  if Config.CountParamsByPath('FilmSpeed') > 0 then FilmSpeed := StrToInt(Config.GetParamByPath('FilmSpeed'));
  if Config.CountParamsByPath('BGOCount') > 0 then BGOCount := StrToInt(Config.GetParamByPath('BGOCount'));
  if Config.CountParamsByPath('BGOTime') > 0 then BGOTime := StrToInt(Config.GetParamByPath('BGOTime'));
  if Config.CountParamsByPath('MaxFilmStepSkip') > 0 then MaxFilmStepSkip := StrToInt(Config.GetParamByPath('MaxFilmStepSkip'));
  if Config.CountParamsByPath('CountFilmSave') > 0 then CountFilmSave := Max(1, StrToInt(Config.GetParamByPath('CountFilmSave')));
  if Config.CountParamsByPath('SputnikShow') > 0 then SputnikShow := ParseEnabledNameGI(Config.GetParamByPath('SputnikShow'));
  if Config.CountParamsByPath('AutoSave') > 0 then AutoSave := ParseEnabledNameGI(Config.GetParamByPath('AutoSave'));
  if Config.CountParamsByPath('SpaceImage') > 0 then SpaceImage := ExtractDigitsToIntW(Config.GetParamByPath('SpaceImage'));
  if Config.CountParamsByPath('ShowFPS') > 0 then ShowFPS := ParseEnabledNameGI(Config.GetParamByPath('ShowFPS'));
  if ReloadScriptTemplates then begin
    Section := GameDataConfig.GetBlockByPath('Script');
    Count := Section.GetParamCount;
    for Index := 0 to Count - 1 do begin
      if FindScriptTemplateIndex(Section.GetParamName(Index)) >= 0 then raise Exception.Create('Script name not unique');
      ScriptTemplate := TScriptTemplUnit.Create;
      ScriptTemplate.Name := Section.GetParamName(Index);
      Text := Section.GetParamValue(Index);
      ScriptTemplate.ConfigValue := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
      ScriptTemplate.FileName := ExtractDelimitedPartW(Text, 1, ',');
      ScriptTemplates.Add(ScriptTemplate);
      CompileScriptTemplateCondition(ScriptTemplates.Count - 1);
    end;
  end;
  NotifyLoadingStage('t1');
  for Owner := oiMaloc to oiGaal do begin
    if ReloadScriptTemplates then begin
      ShipRenderTemplates[Owner,0].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Ranger', Classes.Point(0,0)) as TShip2SE;
      ShipRenderTemplates[Owner,1].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Warrior', Classes.Point(0,0)) as TShip2SE;
      ShipRenderTemplates[Owner,2].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Pirate', Classes.Point(0,0)) as TShip2SE;
      ShipRenderTemplates[Owner,3].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Transport', Classes.Point(0,0)) as TShip2SE;
      ShipRenderTemplates[Owner,4].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Liner', Classes.Point(0,0)) as TShip2SE;
      ShipRenderTemplates[Owner,5].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.' + OwnerInfo[Owner].InternalName + '.Diplomat', Classes.Point(0,0)) as TShip2SE;
    end;
    ShipRenderTemplates[Owner,0].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Ranger.' + GiResourceSuffix + 'ImageP');
    ShipRenderTemplates[Owner,1].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Warrior.' + GiResourceSuffix + 'ImageP');
    ShipRenderTemplates[Owner,2].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Pirate.' + GiResourceSuffix + 'ImageP');
    ShipRenderTemplates[Owner,3].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Transport.' + GiResourceSuffix + 'ImageP');
    ShipRenderTemplates[Owner,4].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Liner.' + GiResourceSuffix + 'ImageP');
    ShipRenderTemplates[Owner,5].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.' + OwnerInfo[Owner].InternalName + '.Diplomat.' + GiResourceSuffix + 'ImageP');
  end;
  Index := 0;
  for Kind := 0 to 5 do begin
    KlissanRenderTemplates[Kind].SpaceObject := CreateSpaceObjectByName('Ship2', 'Ship.Kling.K' + IntToStr(Index), Classes.Point(0,0)) as TShip2SE;
    KlissanRenderTemplates[Kind].PortraitImagePath := GameDataConfig.GetParamByPath('SE.Ship.Kling.K' + IntToStr(Index) + '.' + GiResourceSuffix + 'ImageP');
    Inc(Index);
  end;
  NotifyLoadingStage('t2');
  Count := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockCount;
  SetLength(PlanetSpaceTemplates, Count);
  for Index := 0 to Count - 1 do begin
    Section := GameDataConfig.GetBlockByPath('SE.Planet').GetBlockByIndex(Index);
    PlanetSpaceTemplates[Index].SpaceObject := CreateSpaceObjectByName('Planet', 'Planet.' + GameDataConfig.GetBlockByPath('SE.Planet').GetBlockNameByIndex(Index), Classes.Point(0,0)) as TPlanetSE;
    PlanetSpaceTemplates[Index].Radius := StrToInt(Section.GetParam('Radius'));
  end;
  NotifyLoadingStage('t3');
  NotifyLoadingStage('t4');
  LoadScreen := TfLoad.Create;
  RegisteredScreens[screenLoad] := LoadScreen;
  LoadScreen.InitializeFromConfig(UiStyleConfig, 'Load', True);
  LoadScreen.InitializeLayout;
  MainMenuScreen := TfMainForm.Create;
  RegisteredScreens[screenMainMenu] := MainMenuScreen;
  MainMenuScreen.InitializeFromConfig(UiStyleConfig, 'MainForm', True);
  NewGameScreen := TfGameSettings.Create;
  RegisteredScreens[screenNewGame] := NewGameScreen;
  NewGameScreen.InitializeFromConfig(UiStyleConfig, 'GameSettings', True);
  IntroductionScreen := TfIntroduction.Create;
  RegisteredScreens[screenIntroduction] := IntroductionScreen;
  IntroductionScreen.InitializeFromConfig(UiStyleConfig, 'Introduction', True);
  HangarScreen := TfHangar.Create;
  RegisteredScreens[screenHangar] := HangarScreen;
  HangarScreen.InitializeFromConfig(UiStyleConfig, 'Hangar', True);
  PlanetScreen := TfPlanet.Create;
  RegisteredScreens[screenPlanet] := PlanetScreen;
  PlanetScreen.InitializeFromConfig(UiStyleConfig, 'Planet', True);
  UninhabitedPlanetScreen := TfPlanetNO.Create;
  RegisteredScreens[screenPlanetNO] := UninhabitedPlanetScreen;
  UninhabitedPlanetScreen.InitializeFromConfig(UiStyleConfig, 'PlanetNO', True);
  PlanetQuestScreen := TfPlanetQuest.Create;
  RegisteredScreens[screenPlanetQuest] := PlanetQuestScreen;
  PlanetQuestScreen.InitializeFromConfig(UiStyleConfig, 'PlanetQuest', True);
  RuinsTalkScreen := TfRuinsTalk.Create;
  RegisteredScreens[screenRuinsTalk] := RuinsTalkScreen;
  RuinsTalkScreen.InitializeFromConfig(UiStyleConfig, 'RuinsTalk', True);
  ArcadeBattleScreen := TfAB.Create;
  RegisteredScreens[screenArcadeBattle] := ArcadeBattleScreen;
  ArcadeBattleScreen.InitializeFromConfig(UiStyleConfig, 'AB', True);
  GovernmentScreen := TfGov.Create;
  RegisteredScreens[screenGovernment] := GovernmentScreen;
  GovernmentScreen.InitializeFromConfig(UiStyleConfig, 'Gov', True);
  InfoScreen := TfInfo.Create;
  RegisteredScreens[screenInfo] := InfoScreen;
  InfoScreen.InitializeFromConfig(UiStyleConfig, 'Info', True);
  RatingScreen := TfRating.Create;
  RegisteredScreens[screenRating] := RatingScreen;
  RatingScreen.InitializeFromConfig(UiStyleConfig, 'Rating', True);
  RewardsScreen := TfRewards.Create;
  RegisteredScreens[screenRewards] := RewardsScreen;
  RewardsScreen.InitializeFromConfig(UiStyleConfig, 'Rewards', True);
  ShipScreen := TfShip2.Create;
  RegisteredScreens[screenShip] := ShipScreen;
  ShipScreen.InitializeFromConfig(UiStyleConfig, 'Ship', True);
  TalkScreen := TfTalk.Create;
  RegisteredScreens[screenTalk] := TalkScreen;
  TalkScreen.InitializeFromConfig(UiStyleConfig, 'Talk', True);
  ScannerScreen := TfScaner.Create;
  RegisteredScreens[screenScanner] := ScannerScreen;
  ScannerScreen.InitializeFromConfig(UiStyleConfig, 'Scaner', True);
  StarMapScreen := TfStarMap.Create;
  RegisteredScreens[screenStarMap] := StarMapScreen;
  StarMapScreen.InitializeFromConfig(UiStyleConfig, 'StarMap', True);
  FilmScreen := TfFilm.Create;
  RegisteredScreens[screenFilm] := FilmScreen;
  FilmScreen.InitializeFromConfig(UiStyleConfig, 'Film', True);
  GalaxyMapScreen := TfGalaxy2.Create;
  RegisteredScreens[screenGalaxy] := GalaxyMapScreen;
  GalaxyMapScreen.InitializeFromConfig(UiStyleConfig, 'Galaxy2', True);
  JumpScreen := TfJump.Create;
  RegisteredScreens[screenJump] := JumpScreen;
  JumpScreen.InitializeFromConfig(UiStyleConfig, 'Jump', True);
  EquipmentShopScreen := TfEquipmentShop.Create;
  RegisteredScreens[screenEquipmentShop] := EquipmentShopScreen;
  EquipmentShopScreen.InitializeFromConfig(UiStyleConfig, 'EquipmentShop', True);
  GoodsShopScreen := TfGoodsShop.Create;
  RegisteredScreens[screenGoodsShop] := GoodsShopScreen;
  GoodsShopScreen.InitializeFromConfig(UiStyleConfig, 'GoodsShop', True);
  SaveManagerScreen := TfSaveManager.Create;
  RegisteredScreens[screenSaveManager] := SaveManagerScreen;
  SaveManagerScreen.InitializeFromConfig(UiStyleConfig, 'SaveManager', True);
  GameLoadScreen := TfGameLoad.Create;
  RegisteredScreens[screenGameLoad] := GameLoadScreen;
  GameLoadScreen.InitializeFromConfig(UiStyleConfig, 'GameLoad', True);
  GameMenuScreen := TfGameMenu.Create;
  RegisteredScreens[screenGameMenu] := GameMenuScreen;
  GameMenuScreen.InitializeFromConfig(UiStyleConfig, 'GameMenu', True);
  SettingsScreen := TfCfgSettings.Create;
  RegisteredScreens[screenSettings] := SettingsScreen;
  SettingsScreen.InitializeFromConfig(UiStyleConfig, 'CfgSettings', True);
  GameEndScreen := TfGameEnd.Create;
  RegisteredScreens[screenGameEnd] := GameEndScreen;
  GameEndScreen.InitializeFromConfig(UiStyleConfig, 'GameEnd', True);
  AboutScreen := TfAbout.Create;
  RegisteredScreens[screenAbout] := AboutScreen;
  AboutScreen.InitializeFromConfig(UiStyleConfig, 'About', True);
  ScoreScreen := TfScore.Create;
  RegisteredScreens[screenScores] := ScoreScreen;
  ScoreScreen.InitializeFromConfig(UiStyleConfig, 'Score', True);
  SpaceObjectUiLoop := TMessageLoopGI.Create;
  SpaceObjectUiLoop.InitializeDefaults;
  SpaceObjectUiLoop.ViewportRect := Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
  SpaceObjectUiLoop.UpdateRectsEnabled := False;
  SpaceObjectUiLoop.ContentPanel.SetOrigin(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
  SpaceObjectUiLoop.ContentPanel.SetPosition(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
  PrimaryFilm := TEFilm.Create;
  SecondaryFilm := TEFilm.Create;
  DebugMusic := TfDebugMusic.Create;
  RecreateSpaceProcess('Process.Normal');
  PlanetRenderTemplates := TList.Create;
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 33;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask052';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light052';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask066';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light066';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 60;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask094';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light094';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask120';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light120';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 70;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask108';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light108';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask140';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light140';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 80;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask124';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light124';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask160';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light160';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 90;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask142';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light142';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask180';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light180';
  PlanetTemplate := TPlanetTempl.Create;
  PlanetRenderTemplates.Add(PlanetTemplate);
  PlanetTemplate.Radius := 100;
  PlanetTemplate.SmallMaskName := 'Bm.Planet.S.Mask156';
  PlanetTemplate.SmallLightName := 'Bm.Planet.S.Light156';
  PlanetTemplate.MaskName := 'Bm.Planet.S.Mask200';
  PlanetTemplate.LightName := 'Bm.Planet.S.Light200';
  SatelliteRenderTemplates := TList.Create;
  Index := MinimumSatelliteTemplateRadius;
  while Index <= MaximumSatelliteTemplateRadius do
  begin
    SatelliteTemplate := TSputnikTempl.Create;
    SatelliteRenderTemplates.Add(SatelliteTemplate);
    SatelliteTemplate.MaskName := WideString('Bm.Planet.S.Mask0' + IntToStr(Index) + '?' + IntToStr(SatelliteTemplateParameter1) + ',' + IntToStr(SatelliteTemplateParameter2));
    SatelliteTemplate.Radius := Index;
    Inc(Index);
  end;
  Section := GameDataConfig.GetBlock('SpaceImg');
  Count := Section.GetParamCount;
  SetLength(SpaceImageTemplates, Count);
  for Index := 0 to Count - 1 do
  begin
    Text := Section.GetParamValue(Index);
    if CountDelimitedPartsW(Text, ',') < 2 then raise Exception.Create('Error');
    SpaceImageTemplates[Index].Kind := ExtractDigitsToIntW(Section.GetParamName(Index));
    SpaceImageTemplates[Index].Weight := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ','));
    SpaceImageTemplates[Index].CacheControl := TCGaiControlEC.Create;
    SpaceImageTemplates[Index].CachedData := nil;
    GlobalCache.ResetControl(TCGaiControlEC(SpaceImageTemplates[Index].CacheControl));
    TCGaiControlEC(SpaceImageTemplates[Index].CacheControl).SetCacheKey(ExtractDelimitedPartW(Text, 1, ','));
  end;
  Section := GameDataConfig.GetBlock('StarFieldImg');
  Count := Section.GetParamCount;
  SetLength(StarFieldImageTemplates, Count);
  for Index := 0 to Count - 1 do
  begin
    StarFieldImageTemplates[Index].Weight := ExtractDigitsToIntW(Section.GetParamName(Index));
    StarFieldImageTemplates[Index].CacheControl := TCGaiControlEC.Create;
    StarFieldImageTemplates[Index].CachedData := nil;
    GlobalCache.ResetControl(TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl));
    TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl).SetCacheKey(Section.GetParamValue(Index));
  end;
  ReloadScriptTemplates := False;
  InitializeGameplayConfig;
  InitializeShipGreetingDefinitions;
  InitializeGovernmentGreetingDefinitions;
  UselessItemRemainsCount := StrToInt(AnsiString(LookupLocalizedTextByKey('UselessItems.CntRemains')));
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Explosion');
  Count := Section.GetParamCount;
  SetLength(ArcadeExplosionSounds, Count);
  for Index := 0 to Count - 1 do ArcadeExplosionSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Hit');
  Count := Section.GetParamCount;
  SetLength(ArcadeHitSounds, Count);
  for Index := 0 to Count - 1 do ArcadeHitSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('Item');
  Count := Section.GetParamCount;
  SetLength(ArcadeItemSounds, Count);
  for Index := 0 to Count - 1 do ArcadeItemSounds[Index] := Section.GetParamValue(Index);
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('WeaponFirst');
  for Index := 0 to 14 do
    if Section.CountParams(WideString(IntToStr(Index))) <= 0 then
      ArcadeWeaponFirstSounds[Index] := ''
    else ArcadeWeaponFirstSounds[Index] := Section.GetParam(WideString(IntToStr(Index)));
  Section := GameDataConfig.GetBlock('ABSound').GetBlock('WeaponLoop');
  for Index := 0 to 14 do
    if Section.CountParams(WideString(IntToStr(Index))) <= 0 then
    begin
      ArcadeWeaponLoopSounds[Index] := '';
      ArcadeWeaponLoopTicks[Index] := -1;
    end else begin
      Text := Section.GetParam(WideString(IntToStr(Index)));
      ArcadeWeaponLoopTicks[Index] := ExtractDigitsToIntW(ExtractDelimitedPartW(Text, 0, ',')) div 20;
      ArcadeWeaponLoopSounds[Index] := ExtractDelimitedPartW(Text, 1, ',');
    end;
end;
{ @end $4E5190 }

{ @routine $4E808C FinalizeGlobalUiRuntime }
procedure FinalizeGlobalUiRuntime;
var Index, Count: Integer; SatelliteTemplate: TSputnikTempl; PlanetTemplate: TPlanetTempl; ScreenIndex: TGameScreenId;
begin
  ArcadeHitSounds := nil;
  ArcadeExplosionSounds := nil;
  ArcadeItemSounds := nil;
  Count := High(SpaceImageTemplates) + 1;
  for Index := 0 to Count - 1 do
    if TCGaiControlEC(SpaceImageTemplates[Index].CacheControl) <> nil then begin
      TCGaiControlEC(SpaceImageTemplates[Index].CacheControl).Free;
      SpaceImageTemplates[Index].CacheControl := nil;
    end;
  SpaceImageTemplates := nil;
  Count := High(StarFieldImageTemplates) + 1;
  for Index := 0 to Count - 1 do
    if TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl) <> nil then begin
      TCGaiControlEC(StarFieldImageTemplates[Index].CacheControl).Free;
      StarFieldImageTemplates[Index].CacheControl := nil;
    end;
  StarFieldImageTemplates := nil;
  if PlanetRenderTemplates <> nil then begin
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do begin
      PlanetTemplate := PlanetRenderTemplates[Index];
      PlanetTemplate.Free;
    end;
    PlanetRenderTemplates.Free;
    PlanetRenderTemplates := nil;
  end;
  if SatelliteRenderTemplates <> nil then begin
    Count := SatelliteRenderTemplates.Count;
    for Index := 0 to Count - 1 do begin
      SatelliteTemplate := SatelliteRenderTemplates[Index];
      SatelliteTemplate.Free;
    end;
    SatelliteRenderTemplates.Free;
    SatelliteRenderTemplates := nil;
  end;
  if SpaceProcess <> nil then begin
    SpaceProcess.Free;
    SpaceProcess := nil;
  end;
  if MainMenuScreen <> nil then begin
    MainMenuScreen.Free;
    MainMenuScreen := nil;
  end;
  if NewGameScreen <> nil then begin
    NewGameScreen.Free;
    NewGameScreen := nil;
  end;
  if IntroductionScreen <> nil then begin
    IntroductionScreen.Free;
    IntroductionScreen := nil;
  end;
  if HangarScreen <> nil then begin
    HangarScreen.Free;
    HangarScreen := nil;
  end;
  if PlanetScreen <> nil then begin
    PlanetScreen.Free;
    PlanetScreen := nil;
  end;
  if UninhabitedPlanetScreen <> nil then begin
    UninhabitedPlanetScreen.Free;
    UninhabitedPlanetScreen := nil;
  end;
  if PlanetQuestScreen <> nil then begin
    PlanetQuestScreen.Free;
    PlanetQuestScreen := nil;
  end;
  if RuinsTalkScreen <> nil then begin
    RuinsTalkScreen.Free;
    RuinsTalkScreen := nil;
  end;
  if ArcadeBattleScreen <> nil then begin
    ArcadeBattleScreen.Free;
    ArcadeBattleScreen := nil;
  end;
  if EquipmentShopScreen <> nil then begin
    EquipmentShopScreen.Free;
    EquipmentShopScreen := nil;
  end;
  if GoodsShopScreen <> nil then begin
    GoodsShopScreen.Free;
    GoodsShopScreen := nil;
  end;
  if GovernmentScreen <> nil then begin
    GovernmentScreen.Free;
    GovernmentScreen := nil;
  end;
  if InfoScreen <> nil then begin
    InfoScreen.Free;
    InfoScreen := nil;
  end;
  if RatingScreen <> nil then begin
    RatingScreen.Free;
    RatingScreen := nil;
  end;
  if RewardsScreen <> nil then begin
    RewardsScreen.Free;
    RewardsScreen := nil;
  end;
  if ShipScreen <> nil then begin
    ShipScreen.Free;
    ShipScreen := nil;
  end;
  if TalkScreen <> nil then begin
    TalkScreen.Free;
    TalkScreen := nil;
  end;
  if ScannerScreen <> nil then begin
    ScannerScreen.Free;
    ScannerScreen := nil;
  end;
  if StarMapScreen <> nil then begin
    StarMapScreen.Free;
    StarMapScreen := nil;
  end;
  if FilmScreen <> nil then begin
    FilmScreen.Free;
    FilmScreen := nil;
  end;
  if GalaxyMapScreen <> nil then begin
    GalaxyMapScreen.Free;
    GalaxyMapScreen := nil;
  end;
  if JumpScreen <> nil then begin
    JumpScreen.Free;
    JumpScreen := nil;
  end;
  if LoadScreen <> nil then begin
    LoadScreen.Free;
    LoadScreen := nil;
  end;
  if SaveManagerScreen <> nil then begin
    SaveManagerScreen.Free;
    SaveManagerScreen := nil;
  end;
  if GameLoadScreen <> nil then begin
    GameLoadScreen.Free;
    GameLoadScreen := nil;
  end;
  if GameMenuScreen <> nil then begin
    GameMenuScreen.Free;
    GameMenuScreen := nil;
  end;
  if SettingsScreen <> nil then begin
    SettingsScreen.Free;
    SettingsScreen := nil;
  end;
  if GameEndScreen <> nil then begin
    GameEndScreen.Free;
    GameEndScreen := nil;
  end;
  if AboutScreen <> nil then begin
    AboutScreen.Free;
    AboutScreen := nil;
  end;
  if ScoreScreen <> nil then begin
    ScoreScreen.Free;
    ScoreScreen := nil;
  end;
  if SpaceObjectUiLoop <> nil then begin
    SpaceObjectUiLoop.Free;
    SpaceObjectUiLoop := nil;
  end;
  for ScreenIndex := screenNone to screenScores do RegisteredScreens[ScreenIndex] := nil;
  if SecondaryFilm <> nil then begin
    SecondaryFilm.Free;
    SecondaryFilm := nil;
  end;
  if PrimaryFilm <> nil then begin
    PrimaryFilm.Free;
    PrimaryFilm := nil;
  end;
  if DebugMusic <> nil then begin
    DebugMusic.Free;
    DebugMusic := nil;
  end;
  if PlanetSpaceTemplates <> nil then
    for Index := 0 to High(PlanetSpaceTemplates) do
      if PlanetSpaceTemplates[Index].SpaceObject <> nil then begin
        PlanetSpaceTemplates[Index].SpaceObject.Free;
        PlanetSpaceTemplates[Index].SpaceObject := nil;
      end;
  PlanetSpaceTemplates := nil;
  if CacheLoader <> nil then begin
    CacheLoader.Free;
    CacheLoader := nil;
  end;
  if GlobalCpuTimes <> nil then begin
    GlobalCpuTimes.Save(True);
    GlobalCpuTimes.Free;
    GlobalCpuTimes := nil;
  end;
  if LocalCpuTimes <> nil then begin
    LocalCpuTimes.Save(True);
    LocalCpuTimes.Free;
    LocalCpuTimes := nil;
  end;

end;
{ @end $4E808C }

{ @routine $4E8640 RecreateSpaceProcess }
procedure RecreateSpaceProcess(const ConfigName: WideString);
begin
  if SpaceProcess <> nil then begin
    SpaceProcess.Free;
    SpaceProcess := nil;
  end;
  SpaceProcess := TProcessSE.Create(ConfigName);
end;
{ @end $4E8640 }

{ @routine $4E8674 RunMainScreenStateLoop }
procedure RunMainScreenStateLoop;
var
  LoadName: WideString;
begin
  while True do
  begin
    if ExitScreenLoop then Break;
    if (RequestedScreenId = screenStarMap) or (RequestedScreenId = screenFilm) or (RequestedScreenId = screenArcadeBattle) then
    begin
      CurrentScreenId := RequestedScreenId;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).RunContinuous;
      CurrentScreenId := screenNone;
    end
    else
    begin
      if RequestedScreenId = screenNone then Break;
      CurrentScreenId := RequestedScreenId;
      RequestedScreenId := screenNone;
      TMessageLoopGI(RegisteredScreens[CurrentScreenId]).Run;
      CurrentScreenId := screenNone;
    end;
    if DemoPlaying and (RequestedScreenId = screenNone) then
    begin
      if Galaxy <> nil then
      begin
        Galaxy.Free;
        Galaxy := nil;
      end;
      Demo.GetGameLoad(LoadName);
      PendingLoadFileName := LoadName;
      RequestedScreenId := screenGameLoad;
    end;
  end;
end;
{ @end $4E8674 }

{ @routine $4E8764 SwapTurnFilms }
procedure SwapTurnFilms;
var
  Film: TEFilm;
begin
  Film := PrimaryFilm;
  PrimaryFilm := SecondaryFilm;
  SecondaryFilm := Film;
end;
{ @end $4E8764 }

{ @routine $4E877C TMessagePlayer_Create }
constructor TMessagePlayer.Create;
begin
  inherited Create;
end;
{ @end $4E877C }

{ @routine $4E87B4 TMessagePlayer_SaveToBuffer }
procedure TMessagePlayer.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(Key);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
  Buffer.AddIntegerValue(Turn);
  Buffer.AddWideStringZ(Text);
  Buffer.AddBoolean(False);
  Buffer.AddDWord(TargetIds[0]);
  Buffer.AddDWord(TargetIds[1]);
  Buffer.AddDWord(TargetIds[2]);
  Buffer.AddBoolean(WasRead);
  Buffer.AddBoolean(NotificationSoundPlayed);
end;
{ @end $4E87B4 }

{ @routine $4E8828 TMessagePlayer_LoadFromBuffer }
procedure TMessagePlayer.LoadFromBuffer(Buffer: TBufEC);
begin
  Key := Buffer.ReadWideString;
  WriteByteValue(Buffer.GetByte, Kind);
  Turn := Buffer.GetInt32;
  Text := Buffer.ReadWideString;
  Buffer.GetBoolean;
  TargetIds[0] := Buffer.GetUInt32;
  TargetIds[1] := Buffer.GetUInt32;
  TargetIds[2] := Buffer.GetUInt32;
  WasRead := Buffer.GetBoolean;
  if LoadedSaveVersion >= 2 then NotificationSoundPlayed := Buffer.GetBoolean
  else NotificationSoundPlayed := True;
end;
{ @end $4E8828 }

{ @routine $4E88F8 ClearPersistentPlayerMessages }
procedure ClearPersistentPlayerMessages;
var Next, Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Next := FirstPersistentPlayerMessage;
    while Next <> nil do
    begin
      Entry := Next;
      Next := Next.Next;
      Entry.Free;
    end;
    FirstPersistentPlayerMessage := nil;
    LastPersistentPlayerMessage := nil;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E88F8 }

{ @routine $4E895C CountPersistentPlayerMessages }
function CountPersistentPlayerMessages: Integer;
var Entry: TMessagePlayer; Count: Integer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Count := 0;
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      Inc(Count);
      Entry := Entry.Next;
    end;
    Result := Count;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E895C }

{ @routine $4E89B4 IsPersistentPlayerMessageQueued }
function IsPersistentPlayerMessageQueued(MessageEntry: TMessagePlayer): Boolean;
var Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry = MessageEntry then
      begin
        Result := True;
        Exit;
      end;
      Entry := Entry.Next;
    end;
    Result := False;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E89B4 }

{ @routine $4E8A1C RemovePersistentPlayerMessage }
procedure RemovePersistentPlayerMessage(MessageEntry: TMessagePlayer);
begin
  PersistentPlayerMessageLock.Enter;
  try
    if MessageEntry.Prev <> nil then MessageEntry.Prev.Next := MessageEntry.Next;
    if MessageEntry.Next <> nil then MessageEntry.Next.Prev := MessageEntry.Prev;
    if LastPersistentPlayerMessage = MessageEntry then LastPersistentPlayerMessage := MessageEntry.Prev;
    if FirstPersistentPlayerMessage = MessageEntry then FirstPersistentPlayerMessage := MessageEntry.Next;
    MessageEntry.Free;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E8A1C }

{ @routine $4E8AA0 FindPlayerBubbleByText }
function FindPlayerBubbleByText(const Text: WideString): TMessagePlayer;
var Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry.Text = Text then
      begin
        Result := Entry;
        Exit;
      end;
      Entry := Entry.Next;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  Result := nil;
end;
{ @end $4E8AA0 }

{ @routine $4E8B0C FindPlayerBubbleByKey }
function FindPlayerBubbleByKey(const Key: WideString): TMessagePlayer;
var Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := FirstPersistentPlayerMessage;
    while Entry <> nil do
    begin
      if Entry.Key = Key then
      begin
        Result := Entry;
        Exit;
      end;
      Entry := Entry.Next;
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  Result := nil;
end;
{ @end $4E8B0C }

{ @routine $4E8B78 CreatePersistentPlayerMessage }
function CreatePersistentPlayerMessage: TMessagePlayer;
var Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Entry := TMessagePlayer.Create;
    if LastPersistentPlayerMessage <> nil then LastPersistentPlayerMessage.Next := Entry;
    Entry.Prev := LastPersistentPlayerMessage;
    Entry.Next := nil;
    LastPersistentPlayerMessage := Entry;
    if FirstPersistentPlayerMessage = nil then FirstPersistentPlayerMessage := Entry;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
  Result := Entry;
end;
{ @end $4E8B78 }

{ @routine $4E8C0C AddOrUpdatePlayerBubble }
function AddOrUpdatePlayerBubble(Kind: TPlayerMessageKind; Turn: Integer; const Text, Key: WideString): TMessagePlayer;
var Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    if Key <> '' then
    begin
      Entry := FindPlayerBubbleByKey(Key);
      if Entry <> nil then
      begin
        Entry.Kind := Kind;
        Entry.Turn := Turn;
        Entry.Text := Text;
        Entry.WasRead := False;
        Result := Entry;
        Exit;
      end;
    end;
    Entry := FindPlayerBubbleByText(Text);
    if Entry <> nil then
    begin
      Result := Entry;
      Exit;
    end;
    Entry := TMessagePlayer.Create;
    if LastPersistentPlayerMessage <> nil then LastPersistentPlayerMessage.Next := Entry;
    Entry.Prev := LastPersistentPlayerMessage;
    Entry.Next := nil;
    LastPersistentPlayerMessage := Entry;
    if FirstPersistentPlayerMessage = nil then FirstPersistentPlayerMessage := Entry;
    Entry.Key := Key;
    Entry.Kind := Kind;
    Entry.Turn := Turn;
    Entry.Text := Text;
    Entry.WasRead := False;
    Result := Entry;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E8C0C }

{ @routine $4E8D24 PruneExpiredPersistentPlayerMessages }
procedure PruneExpiredPersistentPlayerMessages;
var Next, Entry: TMessagePlayer;
begin
  PersistentPlayerMessageLock.Enter;
  try
    Next := FirstPersistentPlayerMessage;
    while Next <> nil do
    begin
      Entry := Next;
      Next := Next.Next;
      if Entry.WasRead and (Entry.Kind in [pmTips]) and (Galaxy.CurrentTurn - Entry.Turn >= 7) then
        RemovePersistentPlayerMessage(Entry)
      else if Galaxy.CurrentTurn - Entry.Turn >= PlayerMessagePresentations[Entry.Kind].LifetimeTurns then
        RemovePersistentPlayerMessage(Entry)
      else if Entry.WasRead and (Entry.Kind in [pmGalaxy..pmShip, pmQuestOk, pmQuestCancel]) then
        RemovePersistentPlayerMessage(Entry)
      else if not Player.InNormalSpace and (Entry.Kind = pmEther) then
        RemovePersistentPlayerMessage(Entry);
    end;
  finally
    PersistentPlayerMessageLock.Leave;
  end;
end;
{ @end $4E8D24 }

{ @routine $4E8E04 TScriptTemplUnit_Create }
constructor TScriptTemplUnit.Create;
begin
  inherited Create;
  ConditionCode := TCodeEC.Create;
  ActiveScriptIndex := -1;
end;
{ @end $4E8E04 }

{ @routine $4E8E50 TScriptTemplUnit_Destroy }
destructor TScriptTemplUnit.Destroy;
begin
  ConditionCode.Free;
  ConditionCode := nil;
  inherited Destroy;
end;
{ @end $4E8E50 }

{ @routine $4E8E84 FindScriptTemplateIndex }
function FindScriptTemplateIndex(const Name: WideString): Integer;
var
  Item: TScriptTemplUnit;
  Count, Index: Integer;
begin
  Count := ScriptTemplates.Count;
  for Index := 0 to Count - 1 do
  begin
    Item := ScriptTemplates[Index];
    if Item.Name = Name then
    begin
      Result := Index;
      Exit;
    end;
  end;
  Result := -1;
end;
{ @end $4E8E84 }

{ @routine $4E8EC8 CollectInactiveScriptTemplates }
procedure CollectInactiveScriptTemplates(Dest: TList);
var
  Item: TScriptTemplUnit;
  Count, Index, First, Second: Integer;
begin
  Dest.Clear;
  Count := ScriptTemplates.Count;
  for Index := 0 to Count - 1 do
  begin
    Item := ScriptTemplates[Index];
    if Item.ActiveScriptIndex < 0 then begin
      Dest.Add(Item);
    end;
  end;
  if Dest.Count < 2 then Exit;
  Count := Dest.Count * 2;
  for Index := 0 to Count - 1 do
  begin
    First := SeededRandomIntRange(0, Dest.Count - 1,
      Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Cardinal(Index));
    Second := SeededRandomIntRange(0, Dest.Count - 1,
      Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn + Index));
    if First <> Second then
    begin
      Item := Dest[First];
      Dest[First] := Dest[Second];
      Dest[Second] := Item;
    end;
  end;
end;
{ @end $4E8EC8 }

{ @routine $4E8FC0 ShowPlayerTipOnce }
function ShowPlayerTipOnce(Index: Integer): Boolean;
begin
  Result := False;
  if ShownPlayerTips shr Index and 1 = 0 then
  begin
    ShownPlayerTips := ShownPlayerTips or (1 shl Index);
    if Index < 10 then AddOrUpdatePlayerBubble(pmTips, Galaxy.CurrentTurn, LocalizedColorText('Tips.0' + SysUtils.IntToStr(Index)), '')
    else AddOrUpdatePlayerBubble(pmTips, Galaxy.CurrentTurn, LocalizedColorText('Tips.' + SysUtils.IntToStr(Index)), '');
    Result := True;
  end;
end;
{ @end $4E8FC0 }

{ @routine $4E9108 HasShownPlayerTip }
function HasShownPlayerTip(Index: Integer): Boolean;
begin
  Result := ((ShownPlayerTips shr Index) and 1) = 1;
end;
{ @end $4E9108 }

{ @routine $4E911C SelectSpaceImageTemplateFromSeed }
function SelectSpaceImageTemplateFromSeed(Kind: Integer; Seed: Cardinal): Integer;
var
  Index, Weight: Integer;
begin
  Weight := 0;
  for Index := 0 to High(SpaceImageTemplates) do
    if SpaceImageTemplates[Index].Kind = Kind then
      Inc(Weight, SpaceImageTemplates[Index].Weight);
  if Weight = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Weight := SeededRandomIntRange(0, Weight - 1, Seed);
  for Index := 0 to High(SpaceImageTemplates) do
    if SpaceImageTemplates[Index].Kind = Kind then
    begin
      Dec(Weight, SpaceImageTemplates[Index].Weight);
      if Weight < 0 then
      begin
        Result := Index;
        Exit;
      end;
    end;
  Result := 0;
end;
{ @end $4E911C }

{ @routine $4E91B8 SelectSpaceImageTemplate }
function SelectSpaceImageTemplate(Kind: Integer): Integer;
begin
  Result := SelectSpaceImageTemplateFromSeed(Kind, RandomIntRange(0, 2000000000));
end;
{ @end $4E91B8 }

{ @routine $4E91D4 VerifyGalaxyIntegrityCallback }
procedure VerifyGalaxyIntegrityCallback;
begin
  if not ExitScreenLoop then
    if Galaxy <> nil then
      if not IsTurnCalculationRunning then
      begin
        Galaxy.RestoreProtectedState;
        Galaxy.VerifyIntegrityChecksum;
      end;
end;
{ @end $4E91D4 }

{ @routine $4E920C ProtectGalaxyIntegrityCallback }
procedure ProtectGalaxyIntegrityCallback;
begin
  if not ExitScreenLoop then
    if (NewGameGenerationThread = nil) or not NewGameGenerationThread.IsRunning then
      if (GameLoadScreen = nil) or not GameLoadScreen.IsLoading then
        if Galaxy <> nil then
        begin
          if IsTurnCalculationRunning then WaitForTurnCalculation;
          if Galaxy.ProtectedStateXorSeed = 0 then
          begin
            Galaxy.StoreIntegrityChecksum;
            Galaxy.ProtectState;
          end;
        end;
end;
{ @end $4E920C }

{ @routine $4E92F4 InitializeShipGreetingDefinitions }
procedure InitializeShipGreetingDefinitions;
var
  Block: TBlockParEC;
  Index, EntryIndex, Item, Count: Integer;
  Text: WideString;

  // @nested $4E9288 ReadShipGreetingField
  function ReadShipGreetingField(FieldName: WideString): WideString; // @addr $4E9288
  begin
    if Block.CountParams(FieldName) > 0 then Result := Block.GetParam(FieldName)
    else Result := '';
  end;

begin
  ShipGreetingCount := 0;
  Count := StrToInt(AnsiString(LookupLocalizedTextByKey('ShipGreetings.CountShipGreetings')));
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('ShipGreetings').CountBlocks(WideString(IntToStr(Index))) <> 0 then
    begin
      Inc(ShipGreetingCount);
      SetLength(ShipGreetingDefinitions, ShipGreetingCount);
      EntryIndex := ShipGreetingCount - 1;
      Block := LanguageDataConfig.GetBlockByPath(WideString('ShipGreetings.' + IntToStr(Index)));
      with ShipGreetingDefinitions[EntryIndex] do
      begin
        Name := WideString(IntToStr(Index));
        Text := ReadShipGreetingField('Priority');
        if Text = '' then Priority := 10 else Priority := StrToInt(AnsiString(Text));
        Text := ReadShipGreetingField('AutoTalk');
        if (Text = '') or (Text = 'No') then AutoTalk := gcNo
        else if Text = 'Any' then AutoTalk := gcAny
        else AutoTalk := gcYes;
        Text := ReadShipGreetingField('FlyType');
        if Text = 'Any' then FlyType := gfAny
        else if Text = 'ToPlanet' then FlyType := gfToPlanet
        else if Text = 'ToStar' then FlyType := gfToStar
        else if Text = 'ToItem' then FlyType := gfToItem
        else if Text = 'ToShip' then FlyType := gfToShip
        else RaiseWideMessage(Text);
        Text := ReadShipGreetingField('ShipType');
        ShipType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', Text) > 0 then Include(ShipType, gscTransport);
          if Pos('Liner', Text) > 0 then Include(ShipType, gscLiner);
          if Pos('Diplomat', Text) > 0 then Include(ShipType, gscDiplomat);
          if Pos('Ranger', Text) > 0 then Include(ShipType, gscRanger);
          if Pos('Pirate', Text) > 0 then Include(ShipType, gscPirate);
          if Pos('Warrior', Text) > 0 then Include(ShipType, gscWarrior);
          if Pos('Kling', Text) > 0 then Include(ShipType, gscKling);
        end;
        Text := ReadShipGreetingField('Relations');
        Relations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', Text) > 0 then Include(Relations, rlHostile);
          if Pos('Bad', Text) > 0 then Include(Relations, rlBad);
          if Pos('Normal', Text) > 0 then Include(Relations, rlNormal);
          if Pos('Good', Text) > 0 then Include(Relations, rlGood);
          if Pos('Best', Text) > 0 then Include(Relations, rlExcellent);
        end;
        Text := ReadShipGreetingField('ShipRace');
        ShipRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(ShipRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(ShipRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(ShipRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(ShipRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(ShipRace, oiGaal);
        end;
        Text := ReadShipGreetingField('PlayerRace');
        PlayerRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(PlayerRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(PlayerRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(PlayerRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(PlayerRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(PlayerRace, oiGaal);
        end;
        Text := ReadShipGreetingField('ShipRaceIsPlayerRace');
        if Text = 'Yes' then ShipRaceIsPlayerRace := gcYes
        else if Text = 'No' then ShipRaceIsPlayerRace := gcNo
        else ShipRaceIsPlayerRace := gcAny;
        Text := ReadShipGreetingField('PlayerAttackGoodShip');
        if Text = 'Yes' then PlayerAttackGoodShip := gcYes
        else if Text = 'No' then PlayerAttackGoodShip := gcNo
        else PlayerAttackGoodShip := gcAny;
        Text := ReadShipGreetingField('InFear');
        if Text = 'Yes' then InFear := gcYes
        else if Text = 'Any' then InFear := gcAny
        else InFear := gcNo;
        Text := ReadShipGreetingField('ShipBadFlyToShip');
        if Text = 'Yes' then ShipBadFlyToShip := gcYes
        else if Text = 'Any' then ShipBadFlyToShip := gcAny
        else ShipBadFlyToShip := gcNo;
        Text := ReadShipGreetingField('ShipBadType');
        ShipBadType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', Text) > 0 then Include(ShipBadType, gscTransport);
          if Pos('Liner', Text) > 0 then Include(ShipBadType, gscLiner);
          if Pos('Diplomat', Text) > 0 then Include(ShipBadType, gscDiplomat);
          if Pos('Ranger', Text) > 0 then Include(ShipBadType, gscRanger);
          if Pos('Pirate', Text) > 0 then Include(ShipBadType, gscPirate);
          if Pos('Warrior', Text) > 0 then Include(ShipBadType, gscWarrior);
          if Pos('Kling', Text) > 0 then Include(ShipBadType, gscKling);
        end;
        Text := ReadShipGreetingField('ShipBadRace');
        ShipBadRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(ShipBadRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(ShipBadRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(ShipBadRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(ShipBadRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(ShipBadRace, oiGaal);
        end;
        Text := ReadShipGreetingField('ShipFlyToPlayer');
        if Text = 'Yes' then ShipFlyToPlayer := gcYes
        else if Text = 'No' then ShipFlyToPlayer := gcNo
        else ShipFlyToPlayer := gcAny;
        Text := ReadShipGreetingField('PlayerFlyToShip');
        if Text = 'Yes' then PlayerFlyToShip := gcYes
        else if Text = 'No' then PlayerFlyToShip := gcNo
        else PlayerFlyToShip := gcAny;
        Text := ReadShipGreetingField('PlayerIsShipBad');
        if Text = 'Yes' then PlayerIsShipBad := gcYes
        else if Text = 'No' then PlayerIsShipBad := gcNo
        else PlayerIsShipBad := gcAny;
        Text := ReadShipGreetingField('ShipTurnBeforeEndOrder');
        ShipTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(ShipTurnBeforeEndOrder, Item);
          if Pos('Far', Text) > 0 then Include(ShipTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('PlayerTurnBeforeEndOrder');
        PlayerTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PlayerTurnBeforeEndOrder, Item);
          if Pos('Far', Text) > 0 then Include(PlayerTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('ShipBadTurnBeforeEndOrder');
        ShipBadTurnBeforeEndOrder := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(ShipBadTurnBeforeEndOrder, Item);
          if Pos('Far', Text) > 0 then Include(ShipBadTurnBeforeEndOrder, 10);
        end;
        Text := ReadShipGreetingField('ShipStatus');
        ShipStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', Text) > 0 then Include(ShipStatus, rcTrader);
          if Pos('Pirate', Text) > 0 then Include(ShipStatus, rcPirate);
          if Pos('Warrior', Text) > 0 then Include(ShipStatus, rcWarrior);
        end;
        Text := ReadShipGreetingField('PlayerStatus');
        PlayerStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', Text) > 0 then Include(PlayerStatus, rcTrader);
          if Pos('Pirate', Text) > 0 then Include(PlayerStatus, rcPirate);
          if Pos('Warrior', Text) > 0 then Include(PlayerStatus, rcWarrior);
        end;
        Text := ReadShipGreetingField('ShipStrength');
        ShipStrength := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ShipStrength, scMini);
          // Native uses Pirate here, unlike the other strength/size filters.
          if Pos('Pirate', Text) > 0 then Include(ShipStrength, scSmall);
          if Pos('Average', Text) > 0 then Include(ShipStrength, scAverage);
          if Pos('Big', Text) > 0 then Include(ShipStrength, scBig);
          if Pos('Huge', Text) > 0 then Include(ShipStrength, scHuge);
        end;
        Text := ReadShipGreetingField('PlayerStrength');
        PlayerStrength := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(PlayerStrength, scMini);
          if Pos('Small', Text) > 0 then Include(PlayerStrength, scSmall);
          if Pos('Average', Text) > 0 then Include(PlayerStrength, scAverage);
          if Pos('Big', Text) > 0 then Include(PlayerStrength, scBig);
          if Pos('Huge', Text) > 0 then Include(PlayerStrength, scHuge);
        end;
        Text := ReadShipGreetingField('ShipStructure');
        ShipStructure := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ShipStructure, scMini);
          if Pos('Small', Text) > 0 then Include(ShipStructure, scSmall);
          if Pos('Average', Text) > 0 then Include(ShipStructure, scAverage);
          if Pos('Big', Text) > 0 then Include(ShipStructure, scBig);
          if Pos('Huge', Text) > 0 then Include(ShipStructure, scHuge);
        end;
        Text := ReadShipGreetingField('PlayerStructure');
        PlayerStructure := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(PlayerStructure, scMini);
          if Pos('Small', Text) > 0 then Include(PlayerStructure, scSmall);
          if Pos('Average', Text) > 0 then Include(PlayerStructure, scAverage);
          if Pos('Big', Text) > 0 then Include(PlayerStructure, scBig);
          if Pos('Huge', Text) > 0 then Include(PlayerStructure, scHuge);
        end;
        Text := ReadShipGreetingField('ShipRating');
        ShipRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ShipRating, scMini);
          if Pos('Small', Text) > 0 then Include(ShipRating, scSmall);
          if Pos('Average', Text) > 0 then Include(ShipRating, scAverage);
          if Pos('Big', Text) > 0 then Include(ShipRating, scBig);
          if Pos('Huge', Text) > 0 then Include(ShipRating, scHuge);
        end;
        Text := ReadShipGreetingField('PlayerRating');
        PlayerRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(PlayerRating, scMini);
          if Pos('Small', Text) > 0 then Include(PlayerRating, scSmall);
          if Pos('Average', Text) > 0 then Include(PlayerRating, scAverage);
          if Pos('Big', Text) > 0 then Include(PlayerRating, scBig);
          if Pos('Huge', Text) > 0 then Include(PlayerRating, scHuge);
        end;
        Text := ReadShipGreetingField('ShipRank');
        ShipRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', Text) > 0 then Include(ShipRank, crRookie);
          if Pos('Cadet', Text) > 0 then Include(ShipRank, crCadet);
          if Pos('Pilot', Text) > 0 then Include(ShipRank, crPilot);
          if Pos('Wingman', Text) > 0 then Include(ShipRank, crWingman);
          if Pos('Leader', Text) > 0 then Include(ShipRank, crLeader);
          if Pos('Ace', Text) > 0 then Include(ShipRank, crAce);
          if Pos('Commander', Text) > 0 then Include(ShipRank, crCommander);
        end;
        Text := ReadShipGreetingField('PlayerRank');
        PlayerRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', Text) > 0 then Include(PlayerRank, crRookie);
          if Pos('Cadet', Text) > 0 then Include(PlayerRank, crCadet);
          if Pos('Pilot', Text) > 0 then Include(PlayerRank, crPilot);
          if Pos('Wingman', Text) > 0 then Include(PlayerRank, crWingman);
          if Pos('Leader', Text) > 0 then Include(PlayerRank, crLeader);
          if Pos('Ace', Text) > 0 then Include(PlayerRank, crAce);
          if Pos('Commander', Text) > 0 then Include(PlayerRank, crCommander);
        end;
        Text := ReadShipGreetingField('RatingShipWithPlayer');
        RatingShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(RatingShipWithPlayer, scMini);
          if Pos('Small', Text) > 0 then Include(RatingShipWithPlayer, scSmall);
          if Pos('Average', Text) > 0 then Include(RatingShipWithPlayer, scAverage);
          if Pos('Big', Text) > 0 then Include(RatingShipWithPlayer, scBig);
          if Pos('Huge', Text) > 0 then Include(RatingShipWithPlayer, scHuge);
        end;
        Text := ReadShipGreetingField('RankShipWithPlayer');
        RankShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(RankShipWithPlayer, scMini);
          if Pos('Small', Text) > 0 then Include(RankShipWithPlayer, scSmall);
          if Pos('Average', Text) > 0 then Include(RankShipWithPlayer, scAverage);
          if Pos('Big', Text) > 0 then Include(RankShipWithPlayer, scBig);
          if Pos('Huge', Text) > 0 then Include(RankShipWithPlayer, scHuge);
        end;
        Text := ReadShipGreetingField('StrengthShipWithPlayer');
        StrengthShipWithPlayer := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(StrengthShipWithPlayer, scMini);
          if Pos('Small', Text) > 0 then Include(StrengthShipWithPlayer, scSmall);
          if Pos('Average', Text) > 0 then Include(StrengthShipWithPlayer, scAverage);
          if Pos('Big', Text) > 0 then Include(StrengthShipWithPlayer, scBig);
          if Pos('Huge', Text) > 0 then Include(StrengthShipWithPlayer, scHuge);
        end;
        Text := ReadShipGreetingField('Goods');
        if Text = '' then Goods := GreetingDefinitionNoGoods
        else if Text = 'Food' then Goods := t_Food
        else if Text = 'Medicine' then Goods := t_Medicine
        else if Text = 'Technics' then Goods := t_Technics
        else if Text = 'Luxury' then Goods := t_Luxury
        else if Text = 'Minerals' then Goods := t_Minerals
        else if Text = 'Alcohol' then Goods := t_Alcohol
        else if Text = 'Arms' then Goods := t_Arms
        else if Text = 'Narcotics' then Goods := t_Narcotics
        else Goods := GreetingDefinitionNoGoods;
        Text := ReadShipGreetingField('ShipGoodsCnt');
        ShipGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(ShipGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(ShipGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(ShipGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(ShipGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(ShipGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(ShipGoodsCnt, scHuge);
        end;
        Text := ReadShipGreetingField('PlayerGoodsCnt');
        PlayerGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(PlayerGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(PlayerGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(PlayerGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(PlayerGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(PlayerGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(PlayerGoodsCnt, scHuge);
        end;
        Text := ReadShipGreetingField('ShipHaveGoods');
        if Text = 'Yes' then ShipHaveGoods := gcYes
        else if Text = 'No' then ShipHaveGoods := gcNo
        else ShipHaveGoods := gcAny;
        Text := ReadShipGreetingField('PlayerHaveGoods');
        if Text = 'Yes' then PlayerHaveGoods := gcYes
        else if Text = 'No' then PlayerHaveGoods := gcNo
        else PlayerHaveGoods := gcAny;
        Text := ReadShipGreetingField('ShipGoodsTypeCnt');
        ShipGoodsTypeCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 8 do
            if Pos(IntToStr(Item), Text) > 0 then Include(ShipGoodsTypeCnt, Item);
        end;
        Text := ReadShipGreetingField('PlayerGoodsTypeCnt');
        PlayerGoodsTypeCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 8 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PlayerGoodsTypeCnt, Item);
        end;
        Text := ReadShipGreetingField('ShipMayScanPlayer');
        if Text = 'Yes' then ShipMayScanPlayer := gcYes
        else if Text = 'No' then ShipMayScanPlayer := gcNo
        else ShipMayScanPlayer := gcAny;
        Text := ReadShipGreetingField('RangerInCurStar');
        RangerInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(RangerInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(RangerInCurStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInCurStar');
        PirateInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PirateInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(PirateInCurStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInCurStar');
        KlingInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(KlingInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(KlingInCurStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInCurStar');
        WarriorInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(WarriorInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(WarriorInCurStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInCurStar');
        TransportInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(TransportInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(TransportInCurStar, 10);
        end;
        Text := ReadShipGreetingField('LastPlanetRace');
        LastPlanetRace := [];
        if Text <> '' then
        begin
          if Text = 'Any' then LastPlanetRace := [oiMaloc..oiGaal]
          else
          begin
            if Pos('Maloc', Text) > 0 then Include(LastPlanetRace, oiMaloc);
            if Pos('Peleng', Text) > 0 then Include(LastPlanetRace, oiPeleng);
            if Pos('People', Text) > 0 then Include(LastPlanetRace, oiPeople);
            if Pos('Fei', Text) > 0 then Include(LastPlanetRace, oiFei);
            if Pos('Gaal', Text) > 0 then Include(LastPlanetRace, oiGaal);
          end;
        end;
        Text := ReadShipGreetingField('LastPlanetRelations');
        LastPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', Text) > 0 then Include(LastPlanetRelations, rlHostile);
          if Pos('Bad', Text) > 0 then Include(LastPlanetRelations, rlBad);
          if Pos('Normal', Text) > 0 then Include(LastPlanetRelations, rlNormal);
          if Pos('Good', Text) > 0 then Include(LastPlanetRelations, rlGood);
          if Pos('Best', Text) > 0 then Include(LastPlanetRelations, rlExcellent);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsCnt');
        LastPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(LastPlanetGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(LastPlanetGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(LastPlanetGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(LastPlanetGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(LastPlanetGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(LastPlanetGoodsCnt, scHuge);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsSale');
        LastPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(LastPlanetGoodsSale, scMini);
          if Pos('Small', Text) > 0 then Include(LastPlanetGoodsSale, scSmall);
          if Pos('Average', Text) > 0 then Include(LastPlanetGoodsSale, scAverage);
          if Pos('Big', Text) > 0 then Include(LastPlanetGoodsSale, scBig);
          if Pos('Huge', Text) > 0 then Include(LastPlanetGoodsSale, scHuge);
        end;
        Text := ReadShipGreetingField('LastPlanetGoodsBuy');
        LastPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(LastPlanetGoodsBuy, scMini);
          if Pos('Small', Text) > 0 then Include(LastPlanetGoodsBuy, scSmall);
          if Pos('Average', Text) > 0 then Include(LastPlanetGoodsBuy, scAverage);
          if Pos('Big', Text) > 0 then Include(LastPlanetGoodsBuy, scBig);
          if Pos('Huge', Text) > 0 then Include(LastPlanetGoodsBuy, scHuge);
        end;
        Text := ReadShipGreetingField('LastPlanetIsHomePlanet');
        if Text = 'Yes' then LastPlanetIsHomePlanet := gcYes
        else if Text = 'No' then LastPlanetIsHomePlanet := gcNo
        else LastPlanetIsHomePlanet := gcAny;
        Text := ReadShipGreetingField('LastPlanetRaceIsShipRace');
        if Text = 'Yes' then LastPlanetRaceIsShipRace := gcYes
        else if Text = 'No' then LastPlanetRaceIsShipRace := gcNo
        else LastPlanetRaceIsShipRace := gcAny;
        Text := ReadShipGreetingField('LastPlanetRaceIsPlayerRace');
        if Text = 'Yes' then LastPlanetRaceIsPlayerRace := gcYes
        else if Text = 'No' then LastPlanetRaceIsPlayerRace := gcNo
        else LastPlanetRaceIsPlayerRace := gcAny;
        Text := ReadShipGreetingField('LastPlanetEconomy');
        LastPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', Text) > 0 then Include(LastPlanetEconomy, peAgriculture);
          if Pos('Mixed', Text) > 0 then Include(LastPlanetEconomy, peMixed);
          if Pos('Industrial', Text) > 0 then Include(LastPlanetEconomy, peIndustrial);
        end;
        Text := ReadShipGreetingField('LastPlanetGoverment');
        LastPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', Text) > 0 then Include(LastPlanetGovernment, pgAnarchy);
          if Pos('Dictatorship', Text) > 0 then Include(LastPlanetGovernment, pgDictatorship);
          if Pos('Monarchy', Text) > 0 then Include(LastPlanetGovernment, pgMonarchy);
          if Pos('Republic', Text) > 0 then Include(LastPlanetGovernment, pgRepublic);
          if Pos('Democracy', Text) > 0 then Include(LastPlanetGovernment, pgDemocracy);
        end;
        Text := ReadShipGreetingField('LastPlanetInCurStar');
        if Text = 'Yes' then LastPlanetInCurStar := gcYes
        else if Text = 'No' then LastPlanetInCurStar := gcNo
        else LastPlanetInCurStar := gcAny;
        Text := ReadShipGreetingField('LastPlanetDistToShipInTurn');
        LastPlanetDistToShipInTurn := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 1 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(LastPlanetDistToShipInTurn, Item);
          if Pos('Far', Text) > 0 then Include(LastPlanetDistToShipInTurn, 10);
        end;
        Text := ReadShipGreetingField('RangerInLastPlanetStar');
        RangerInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(RangerInLastPlanetStar, Item);
          if Pos('Many', Text) > 0 then Include(RangerInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInLastPlanetStar');
        PirateInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PirateInLastPlanetStar, Item);
          if Pos('Many', Text) > 0 then Include(PirateInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInLastPlanetStar');
        KlingInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(KlingInLastPlanetStar, Item);
          if Pos('Many', Text) > 0 then Include(KlingInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInLastPlanetStar');
        WarriorInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(WarriorInLastPlanetStar, Item);
          if Pos('Many', Text) > 0 then Include(WarriorInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInLastPlanetStar');
        TransportInLastPlanetStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(TransportInLastPlanetStar, Item);
          if Pos('Many', Text) > 0 then Include(TransportInLastPlanetStar, 10);
        end;
        Text := ReadShipGreetingField('ToPlanetRace');
        ToPlanetRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(ToPlanetRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(ToPlanetRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(ToPlanetRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(ToPlanetRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(ToPlanetRace, oiGaal);
        end;
        Text := ReadShipGreetingField('ToPlanetRelations');
        ToPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', Text) > 0 then Include(ToPlanetRelations, rlHostile);
          if Pos('Bad', Text) > 0 then Include(ToPlanetRelations, rlBad);
          if Pos('Normal', Text) > 0 then Include(ToPlanetRelations, rlNormal);
          if Pos('Good', Text) > 0 then Include(ToPlanetRelations, rlGood);
          if Pos('Best', Text) > 0 then Include(ToPlanetRelations, rlExcellent);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsCnt');
        ToPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(ToPlanetGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsCnt, scHuge);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsSale');
        ToPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsSale, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsSale, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsSale, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsSale, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsSale, scHuge);
        end;
        Text := ReadShipGreetingField('ToPlanetGoodsBuy');
        ToPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsBuy, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsBuy, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsBuy, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsBuy, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsBuy, scHuge);
        end;
        Text := ReadShipGreetingField('ToPlanetIsHomePlanet');
        if Text = 'Yes' then ToPlanetIsHomePlanet := gcYes
        else if Text = 'No' then ToPlanetIsHomePlanet := gcNo
        else ToPlanetIsHomePlanet := gcAny;
        Text := ReadShipGreetingField('ToPlanetRaceIsShipRace');
        if Text = 'Yes' then ToPlanetRaceIsShipRace := gcYes
        else if Text = 'No' then ToPlanetRaceIsShipRace := gcNo
        else ToPlanetRaceIsShipRace := gcAny;
        Text := ReadShipGreetingField('ToPlanetRaceIsPlayerRace');
        if Text = 'Yes' then ToPlanetRaceIsPlayerRace := gcYes
        else if Text = 'No' then ToPlanetRaceIsPlayerRace := gcNo
        else ToPlanetRaceIsPlayerRace := gcAny;
        Text := ReadShipGreetingField('ToPlanetEconomy');
        ToPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', Text) > 0 then Include(ToPlanetEconomy, peAgriculture);
          if Pos('Mixed', Text) > 0 then Include(ToPlanetEconomy, peMixed);
          if Pos('Industrial', Text) > 0 then Include(ToPlanetEconomy, peIndustrial);
        end;
        Text := ReadShipGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', Text) > 0 then Include(ToPlanetGovernment, pgAnarchy);
          if Pos('Dictatorship', Text) > 0 then Include(ToPlanetGovernment, pgDictatorship);
          if Pos('Monarchy', Text) > 0 then Include(ToPlanetGovernment, pgMonarchy);
          if Pos('Republic', Text) > 0 then Include(ToPlanetGovernment, pgRepublic);
          if Pos('Democracy', Text) > 0 then Include(ToPlanetGovernment, pgDemocracy);
        end;
        Text := ReadShipGreetingField('ToPlanetIsLastPlanet');
        if Text = 'Yes' then ToPlanetIsLastPlanet := gcYes
        else if Text = 'Any' then ToPlanetIsLastPlanet := gcAny
        else ToPlanetIsLastPlanet := gcNo;
        Text := ReadShipGreetingField('ToPlanetRaceIsLastPlanetRace');
        if Text = 'Yes' then ToPlanetRaceIsLastPlanetRace := gcYes
        else if Text = 'No' then ToPlanetRaceIsLastPlanetRace := gcNo
        else ToPlanetRaceIsLastPlanetRace := gcAny;
        Text := ReadShipGreetingField('HomePlanetInToStar');
        if Text = 'Yes' then HomePlanetInToStar := gcYes
        else if Text = 'No' then HomePlanetInToStar := gcNo
        else HomePlanetInToStar := gcAny;
        Text := ReadShipGreetingField('HomePlanetInCurStar');
        if Text = 'Yes' then HomePlanetInCurStar := gcYes
        else if Text = 'No' then HomePlanetInCurStar := gcNo
        else HomePlanetInCurStar := gcAny;
        Text := ReadShipGreetingField('ToStarControlByKling');
        if Text = 'Yes' then ToStarControlByKling := gcYes
        else if Text = 'Any' then ToStarControlByKling := gcAny
        else ToStarControlByKling := gcNo;
        Text := ReadShipGreetingField('ToStarInBattle');
        if Text = 'Yes' then ToStarInBattle := gcYes
        else if Text = 'Any' then ToStarInBattle := gcAny
        else ToStarInBattle := gcNo;
        Text := ReadShipGreetingField('RangerInToStar');
        RangerInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(RangerInToStar, Item);
          if Pos('Many', Text) > 0 then Include(RangerInToStar, 10);
        end;
        Text := ReadShipGreetingField('PirateInToStar');
        PirateInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PirateInToStar, Item);
          if Pos('Many', Text) > 0 then Include(PirateInToStar, 10);
        end;
        Text := ReadShipGreetingField('KlingInToStar');
        KlingInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(KlingInToStar, Item);
          if Pos('Many', Text) > 0 then Include(KlingInToStar, 10);
        end;
        Text := ReadShipGreetingField('WarriorInToStar');
        WarriorInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(WarriorInToStar, Item);
          if Pos('Many', Text) > 0 then Include(WarriorInToStar, 10);
        end;
        Text := ReadShipGreetingField('TransportInToStar');
        TransportInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(TransportInToStar, Item);
          if Pos('Many', Text) > 0 then Include(TransportInToStar, 10);
        end;
        ItemType := ReadShipGreetingField('ItemType');
        Text := ReadShipGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', Text) > 0 then Include(ToPlanetGovernment, pgAnarchy);
          if Pos('Dictatorship', Text) > 0 then Include(ToPlanetGovernment, pgDictatorship);
          if Pos('Monarchy', Text) > 0 then Include(ToPlanetGovernment, pgMonarchy);
          if Pos('Republic', Text) > 0 then Include(ToPlanetGovernment, pgRepublic);
          if Pos('Democracy', Text) > 0 then Include(ToPlanetGovernment, pgDemocracy);
        end;
        Text := ReadShipGreetingField('ShipNeedInItem');
        if Text = 'Yes' then ShipNeedInItem := gcYes
        else if Text = 'No' then ShipNeedInItem := gcNo
        else ShipNeedInItem := gcAny;
        Text := ReadShipGreetingField('ToShipType');
        ToShipType := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Transport', Text) > 0 then Include(ToShipType, gscTransport);
          if Pos('Liner', Text) > 0 then Include(ToShipType, gscLiner);
          if Pos('Diplomat', Text) > 0 then Include(ToShipType, gscDiplomat);
          if Pos('Ranger', Text) > 0 then Include(ToShipType, gscRanger);
          if Pos('Pirate', Text) > 0 then Include(ToShipType, gscPirate);
          if Pos('Warrior', Text) > 0 then Include(ToShipType, gscWarrior);
          if Pos('Kling', Text) > 0 then Include(ToShipType, gscKling);
        end;
        Text := ReadShipGreetingField('ToShipRace');
        ToShipRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(ToShipRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(ToShipRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(ToShipRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(ToShipRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(ToShipRace, oiGaal);
        end;
        Text := ReadShipGreetingField('ToShipInPlanet');
        if Text = 'Yes' then ToShipInPlanet := gcYes
        else if Text = 'No' then ToShipInPlanet := gcNo
        else ToShipInPlanet := gcAny;
        Text := ReadShipGreetingField('ToShipBad');
        if Text = 'Yes' then ToShipBad := gcYes
        else if Text = 'No' then ToShipBad := gcNo
        else ToShipBad := gcAny;
      end;
    end;
end;
{ @end $4E92F4 }

{ @routine $4EDA48 InitializeGovernmentGreetingDefinitions }
procedure InitializeGovernmentGreetingDefinitions;
var
  Block: TBlockParEC;
  Index, EntryIndex, Item, Count: Integer;
  Text: WideString;

  // @nested $4ED9DC ReadGovernmentGreetingField
  function ReadGovernmentGreetingField(FieldName: WideString): WideString; // @addr $4ED9DC
  begin
    if Block.CountParams(FieldName) > 0 then Result := Block.GetParam(FieldName)
    else Result := '';
  end;

begin
  GovernmentGreetingCount := 0;
  Count := StrToInt(AnsiString(LookupLocalizedTextByKey('GovGreetings.CountGovGreetings')));
  for Index := 0 to Count - 1 do
    if LanguageDataConfig.GetBlock('GovGreetings').CountBlocks(WideString(IntToStr(Index))) <> 0 then
    begin
      Inc(GovernmentGreetingCount);
      SetLength(GovernmentGreetingDefinitions, GovernmentGreetingCount);
      EntryIndex := GovernmentGreetingCount - 1;
      Block := LanguageDataConfig.GetBlockByPath(WideString('GovGreetings.' + IntToStr(Index)));
      with GovernmentGreetingDefinitions[EntryIndex] do
      begin
        Name := WideString(IntToStr(Index));
        Text := ReadGovernmentGreetingField('Priority');
        if Text = '' then Priority := 10 else Priority := StrToInt(AnsiString(Text));
        Text := ReadGovernmentGreetingField('PlayerRace');
        PlayerRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(PlayerRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(PlayerRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(PlayerRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(PlayerRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(PlayerRace, oiGaal);
        end;
        Text := ReadGovernmentGreetingField('PlayerStatus');
        PlayerStatus := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Trader', Text) > 0 then Include(PlayerStatus, rcTrader);
          if Pos('Pirate', Text) > 0 then Include(PlayerStatus, rcPirate);
          if Pos('Warrior', Text) > 0 then Include(PlayerStatus, rcWarrior);
        end;
        Text := ReadGovernmentGreetingField('PlayerRating');
        PlayerRating := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(PlayerRating, scMini);
          if Pos('Small', Text) > 0 then Include(PlayerRating, scSmall);
          if Pos('Average', Text) > 0 then Include(PlayerRating, scAverage);
          if Pos('Big', Text) > 0 then Include(PlayerRating, scBig);
          if Pos('Huge', Text) > 0 then Include(PlayerRating, scHuge);
        end;
        Text := ReadGovernmentGreetingField('PlayerRank');
        PlayerRank := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Rookie', Text) > 0 then Include(PlayerRank, crRookie);
          if Pos('Cadet', Text) > 0 then Include(PlayerRank, crCadet);
          if Pos('Pilot', Text) > 0 then Include(PlayerRank, crPilot);
          if Pos('Wingman', Text) > 0 then Include(PlayerRank, crWingman);
          if Pos('Leader', Text) > 0 then Include(PlayerRank, crLeader);
          if Pos('Ace', Text) > 0 then Include(PlayerRank, crAce);
          if Pos('Commander', Text) > 0 then Include(PlayerRank, crCommander);
        end;
        Text := ReadGovernmentGreetingField('Goods');
        if Text = '' then Goods := GreetingDefinitionNoGoods
        else if Text = 'Food' then Goods := t_Food
        else if Text = 'Medicine' then Goods := t_Medicine
        else if Text = 'Technics' then Goods := t_Technics
        else if Text = 'Luxury' then Goods := t_Luxury
        else if Text = 'Minerals' then Goods := t_Minerals
        else if Text = 'Alcohol' then Goods := t_Alcohol
        else if Text = 'Arms' then Goods := t_Arms
        else if Text = 'Narcotics' then Goods := t_Narcotics
        else Goods := GreetingDefinitionNoGoods;
        Text := ReadGovernmentGreetingField('CurPlanetRace');
        CurPlanetRace := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Maloc', Text) > 0 then Include(CurPlanetRace, oiMaloc);
          if Pos('Peleng', Text) > 0 then Include(CurPlanetRace, oiPeleng);
          if Pos('People', Text) > 0 then Include(CurPlanetRace, oiPeople);
          if Pos('Fei', Text) > 0 then Include(CurPlanetRace, oiFei);
          if Pos('Gaal', Text) > 0 then Include(CurPlanetRace, oiGaal);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetRaceIsPlayerRace');
        if Text = 'Yes' then CurPlanetRaceIsPlayerRace := gcYes
        else if Text = 'No' then CurPlanetRaceIsPlayerRace := gcNo
        else CurPlanetRaceIsPlayerRace := gcAny;
        Text := ReadGovernmentGreetingField('CurPlanetRelations');
        CurPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', Text) > 0 then Include(CurPlanetRelations, rlHostile);
          if Pos('Bad', Text) > 0 then Include(CurPlanetRelations, rlBad);
          if Pos('Normal', Text) > 0 then Include(CurPlanetRelations, rlNormal);
          if Pos('Good', Text) > 0 then Include(CurPlanetRelations, rlGood);
          if Pos('Best', Text) > 0 then Include(CurPlanetRelations, rlExcellent);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsCnt');
        CurPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(CurPlanetGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(CurPlanetGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(CurPlanetGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(CurPlanetGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(CurPlanetGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(CurPlanetGoodsCnt, scHuge);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsSale');
        CurPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(CurPlanetGoodsSale, scMini);
          if Pos('Small', Text) > 0 then Include(CurPlanetGoodsSale, scSmall);
          if Pos('Average', Text) > 0 then Include(CurPlanetGoodsSale, scAverage);
          if Pos('Big', Text) > 0 then Include(CurPlanetGoodsSale, scBig);
          if Pos('Huge', Text) > 0 then Include(CurPlanetGoodsSale, scHuge);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoodsBuy');
        CurPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(CurPlanetGoodsBuy, scMini);
          if Pos('Small', Text) > 0 then Include(CurPlanetGoodsBuy, scSmall);
          if Pos('Average', Text) > 0 then Include(CurPlanetGoodsBuy, scAverage);
          if Pos('Big', Text) > 0 then Include(CurPlanetGoodsBuy, scBig);
          if Pos('Huge', Text) > 0 then Include(CurPlanetGoodsBuy, scHuge);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetEconomy');
        CurPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', Text) > 0 then Include(CurPlanetEconomy, peAgriculture);
          if Pos('Mixed', Text) > 0 then Include(CurPlanetEconomy, peMixed);
          if Pos('Industrial', Text) > 0 then Include(CurPlanetEconomy, peIndustrial);
        end;
        Text := ReadGovernmentGreetingField('CurPlanetGoverment');
        CurPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', Text) > 0 then Include(CurPlanetGovernment, pgAnarchy);
          if Pos('Dictatorship', Text) > 0 then Include(CurPlanetGovernment, pgDictatorship);
          if Pos('Monarchy', Text) > 0 then Include(CurPlanetGovernment, pgMonarchy);
          if Pos('Republic', Text) > 0 then Include(CurPlanetGovernment, pgRepublic);
          if Pos('Democracy', Text) > 0 then Include(CurPlanetGovernment, pgDemocracy);
        end;
        Text := ReadGovernmentGreetingField('RangerInCurStar');
        RangerInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(RangerInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(RangerInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('PirateInCurStar');
        PirateInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PirateInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(PirateInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('KlingInCurStar');
        KlingInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(KlingInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(KlingInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('WarriorInCurStar');
        WarriorInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(WarriorInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(WarriorInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('TransportInCurStar');
        TransportInCurStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(TransportInCurStar, Item);
          if Pos('Many', Text) > 0 then Include(TransportInCurStar, 10);
        end;
        Text := ReadGovernmentGreetingField('CurStarInBattle');
        if Text = 'Yes' then CurStarInBattle := gcYes
        else if Text = 'Any' then CurStarInBattle := gcAny
        else CurStarInBattle := gcNo;
        Text := ReadGovernmentGreetingField('ToPlanetRace');
        ToPlanetRace := [];
        if Text <> '' then
        begin
          if Text = 'Any' then ToPlanetRace := [oiMaloc..oiGaal]
          else
          begin
            if Pos('Maloc', Text) > 0 then Include(ToPlanetRace, oiMaloc);
            if Pos('Peleng', Text) > 0 then Include(ToPlanetRace, oiPeleng);
            if Pos('People', Text) > 0 then Include(ToPlanetRace, oiPeople);
            if Pos('Fei', Text) > 0 then Include(ToPlanetRace, oiFei);
            if Pos('Gaal', Text) > 0 then Include(ToPlanetRace, oiGaal);
          end;
        end;
        Text := ReadGovernmentGreetingField('ToPlanetRaceIsPlayerRace');
        if Text = 'Yes' then ToPlanetRaceIsPlayerRace := gcYes
        else if Text = 'No' then ToPlanetRaceIsPlayerRace := gcNo
        else ToPlanetRaceIsPlayerRace := gcAny;
        Text := ReadGovernmentGreetingField('ToPlanetRaceIsCurPlanetRace');
        if Text = 'Yes' then ToPlanetRaceIsCurPlanetRace := gcYes
        else if Text = 'No' then ToPlanetRaceIsCurPlanetRace := gcNo
        else ToPlanetRaceIsCurPlanetRace := gcAny;
        Text := ReadGovernmentGreetingField('ToPlanetRelations');
        ToPlanetRelations := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('War', Text) > 0 then Include(ToPlanetRelations, rlHostile);
          if Pos('Bad', Text) > 0 then Include(ToPlanetRelations, rlBad);
          if Pos('Normal', Text) > 0 then Include(ToPlanetRelations, rlNormal);
          if Pos('Good', Text) > 0 then Include(ToPlanetRelations, rlGood);
          if Pos('Best', Text) > 0 then Include(ToPlanetRelations, rlExcellent);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsCnt');
        ToPlanetGoodsCnt := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Zero', Text) > 0 then Include(ToPlanetGoodsCnt, scZero);
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsCnt, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsCnt, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsCnt, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsCnt, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsCnt, scHuge);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsSale');
        ToPlanetGoodsSale := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsSale, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsSale, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsSale, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsSale, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsSale, scHuge);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoodsBuy');
        ToPlanetGoodsBuy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Mini', Text) > 0 then Include(ToPlanetGoodsBuy, scMini);
          if Pos('Small', Text) > 0 then Include(ToPlanetGoodsBuy, scSmall);
          if Pos('Average', Text) > 0 then Include(ToPlanetGoodsBuy, scAverage);
          if Pos('Big', Text) > 0 then Include(ToPlanetGoodsBuy, scBig);
          if Pos('Huge', Text) > 0 then Include(ToPlanetGoodsBuy, scHuge);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetEconomy');
        ToPlanetEconomy := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Agriculture', Text) > 0 then Include(ToPlanetEconomy, peAgriculture);
          if Pos('Mixed', Text) > 0 then Include(ToPlanetEconomy, peMixed);
          if Pos('Industrial', Text) > 0 then Include(ToPlanetEconomy, peIndustrial);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetGoverment');
        ToPlanetGovernment := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          if Pos('Anarchy', Text) > 0 then Include(ToPlanetGovernment, pgAnarchy);
          if Pos('Dictatorship', Text) > 0 then Include(ToPlanetGovernment, pgDictatorship);
          if Pos('Monarchy', Text) > 0 then Include(ToPlanetGovernment, pgMonarchy);
          if Pos('Republic', Text) > 0 then Include(ToPlanetGovernment, pgRepublic);
          if Pos('Democracy', Text) > 0 then Include(ToPlanetGovernment, pgDemocracy);
        end;
        Text := ReadGovernmentGreetingField('ToPlanetInCurStar');
        if Text = 'Any' then ToPlanetInCurStar := gcAny
        else if Text = 'No' then ToPlanetInCurStar := gcNo
        else ToPlanetInCurStar := gcYes;
        Text := ReadGovernmentGreetingField('RangerInToStar');
        RangerInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(RangerInToStar, Item);
          if Pos('Many', Text) > 0 then Include(RangerInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('PirateInToStar');
        PirateInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(PirateInToStar, Item);
          if Pos('Many', Text) > 0 then Include(PirateInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('KlingInToStar');
        KlingInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(KlingInToStar, Item);
          if Pos('Many', Text) > 0 then Include(KlingInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('WarriorInToStar');
        WarriorInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(WarriorInToStar, Item);
          if Pos('Many', Text) > 0 then Include(WarriorInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('TransportInToStar');
        TransportInToStar := [];
        if (Text <> '') and (Text <> 'Any') then
        begin
          for Item := 0 to 9 do
            if Pos(IntToStr(Item), Text) > 0 then Include(TransportInToStar, Item);
          if Pos('Many', Text) > 0 then Include(TransportInToStar, 10);
        end;
        Text := ReadGovernmentGreetingField('ToStarControlByKling');
        if Text = 'Yes' then ToStarControlByKling := gcYes
        else if Text = 'Any' then ToStarControlByKling := gcAny
        else ToStarControlByKling := gcNo;
        Text := ReadGovernmentGreetingField('ToStarInBattle');
        if Text = 'Yes' then ToStarInBattle := gcYes
        else if Text = 'Any' then ToStarInBattle := gcAny
        else ToStarInBattle := gcNo;
      end;
    end;
end;
{ @end $4EDA48 }

end.

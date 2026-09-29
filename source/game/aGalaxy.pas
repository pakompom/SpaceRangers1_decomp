unit aGalaxy;
// Unit bracket (inferred): CODE 0x005E500C..0x005FDB63; inclusive evidence, not full bounds.
// Galaxy lifecycle and save-format layouts.
interface
uses aConst, EC_Struct, Classes, Types, EC_Buf, aMyFunction, aVector, SE_Space, SE_Hole, SE_Gate, GI_Panel, GI_MessageLoop;
type
  TStarControlFaction = (sfCoalition = 0, sfKlissan = 1); // @size $01
  TStarCombatEvent = packed record // @size $20 Native NextDay allocates 32 bytes; effects and deferred target release are written by the same routine.
    StepIndex: Integer; // @offset $00
    CombatGroup: Integer; // @offset $04 Zero until connected attacks are grouped.
    Attacker: TObject; // @offset $08
    Target: TObject; // @offset $0C
    Weapon: TObject; // @offset $10
    Effect: TObjectSE; // @offset $14
    EffectFilm: TObject; // @offset $18 Borrowed TEFilmObj; avoids aEObjInfo interface cycle.
    DestroyedTargetFilm: TObject; // @offset $1C TEFilmObj released after the turn.
  end;
  PStarCombatEvent = ^TStarCombatEvent;
  TSpaceBackgroundEntry = record // @size $60
    ImageIndex: Integer; // @offset $00
    OrbitCenter: TVector3D; // @offset $08
    Position: TVector3D; // @offset $20
    Unknown38: TVector3D; // @offset $38 Preserved by the serializer; meaning unresolved.
    OrbitStepDegrees: Double; // @offset $50
    FrameIndex: Integer; // @offset $58
  end;
  TJumpGateEntry = record // @size $0C Allocation at $5E84D8.
    Gate: TGateSE; // @offset $00 Owned, detached before freeing.
    UnresolvedFlag: Boolean; // @offset $04 Explicitly cleared by CreateJumpGate.
    FilmObject: TObject; // @offset $08 Borrowed TEFilmObj released after the turn.
  end;
  PJumpGateEntry = ^TJumpGateEntry;
  // Only used to limit duplicate news; gnGeneral entries are never counted.
  TGalaxyNewsKind = (gnGeneral = 0, gnRevolutionAnarchy = 1, gnRevolutionDictatorship = 2,
    gnRevolutionMonarchy = 3, gnRevolutionRepublic = 4, gnRevolutionDemocracy = 5,
    gnMineralDeposit = 6, gnNeedMineral = 7, gnManyArms = 8, gnNeedArms = 9, gnManyTechnics = 10,
    gnManyFood = 11, gnNeedFood = 12, gnManyMedicine = 13, gnManyLuxury = 14, gnNeedLuxury = 15,
    gnManyAlcohol = 16, gnNeedAlcohol = 17, gnManyTransports = 18, gnManyPirates = 19,
    gnSomePirates = 20, gnNoPirates = 21, gnManyRangers = 22, gnBestRanger = 23,
    gnKlingAttack = 24, gnKlingLost = 25, gnWarriorLiberatorGroup = 26); // @size $01
  TPlanetNews = record // @size $0C
    Turn: Integer; // @offset $00
    NewsType: TGalaxyNewsKind; // @offset $04
    Text: WideString; // @offset $08 Managed; New/Dispose in $5F9C9C / $5F9DB0.
  end;
  PPlanetNewsEntry = ^TPlanetNews;
  TMovingDropItemEntry = packed record // @size $14
    Payload: TObject; // @offset $00 Owned TItem until inserted into the star.
    Destination: TPointF; // @offset $04
    SourceShipId: Cardinal; // @offset $0C Zero for mineral drops.
    InsertedIntoStar: Boolean; // @offset $10
    UseFlag: Boolean; // @offset $11 Serialized by TStar.SaveToBuffer.
  end;
  PMovingDropItemEntry = ^TMovingDropItemEntry;
  TConstellationBoundaryRaySample = packed record // @size $18
    Position: TPointF; // @offset $00
    Direction: TPointF; // @offset $08
    Angle: Single; // @offset $10  Radians.
    GrowthStopped: Boolean; // @offset $14
  end;
  PConstellationBoundaryRaySample = ^TConstellationBoundaryRaySample;

  TMapLineSegment = packed record // @size $1C
    StartPoint: TPointF; // @offset $00
    EndPoint: TPointF; // @offset $08
  end;
  PMapLineSegment = ^TMapLineSegment;

  TConstellationStarLink = packed record // @size $1C
    StartPoint: TPointF; // @offset $00
    EndPoint: TPointF; // @offset $08
    StartStarIndex: Integer; // @offset $10  One-based ConstellationGraphIndex.
    EndStarIndex: Integer; // @offset $14
    TraversalMark: Boolean; // @offset $18
  end;
  PConstellationStarLink = ^TConstellationStarLink;
  TBlackHoleKind = (bhkNone = 0, bhkOrdinary = 1, bhkMachpella = 2, bhkUsed = 3); // @size $04

  TGalaxy = class;
  TConstellation = class;
  THole = class;
  TStar = class;
  TStarDistance = record // @size $08
    Distance: Integer; // @offset $00
    Star: TObject; // @offset $04 Readers use as TStar, a native AsClass call that a TStar declaration would drop.
  end;
  TGalaxy = class(TObjectEx) // @size $F8
  public
    procedure NextDay; // @addr $5E6DCC
    procedure TryCreateDailyStation; // @addr $5FACFC
    procedure TryCreateRangerCenter; // @addr $5FAD38
    procedure TryCreatePirateBase; // @addr $5FAF44
    procedure TryCreateMilitaryBase; // @addr $5FB168
    procedure TryCreateScienceBase; // @addr $5FB38C
    procedure AdvanceCommunicatorResearch; // @addr $5FB598
    procedure ApplyNodeDepositInactivityPenalty; // @addr $5FB70C
    function SelectStarForLiberationAttack(Origin: TStar): TStar; // @addr $5FA054
    function TryCreateLiberationGroup(Mode: Byte): Boolean; // @addr $5FB978
    procedure CompleteDay; // @addr $5E70C0
    procedure TransferShipsInTransit; // @addr $5E7BB4
    procedure AppendShipDatabaseLog; // @addr $5E767C Appends native #ship.dbf records.
    function HasPlayerQuestHistory(QuestType: TQuestType; QuestNumber: Word): Boolean; // @addr $5F9A3C
    // Scaled by the owner's FuelPriceFactor; oiPeople's is 1.0.
    function ComputeScaledMiniMoney(Owner: TOwnerId): Integer; // @addr $5FA468
    function ComputeScaledSmallMoney(Owner: TOwnerId): Integer; // @addr $5FA4D8
    function ComputeScaledAverageMoney(Owner: TOwnerId): Integer; // @addr $5FA548
    function ComputeScaledBigMoney(Owner: TOwnerId): Integer; // @addr $5FA5B8
    function ComputeScaledHugeMoney(Owner: TOwnerId): Integer; // @addr $5FA628
    function ResolveMoneySizeTag(Tag: WideString; Owner: TOwnerId): Integer; // @addr $5FA698
    function GetMiniGoodsQuantity(GoodsType: TGoodsIndex): Integer; // @addr $5FA880
    function GetAverageGoodsQuantity(GoodsType: TGoodsIndex): Integer; // @addr $5FA8D8
    function GetGoodsQuantityBySize(Size: TStandardCount; GoodsType: TGoodsIndex): Integer; // @addr $5FA94C
    function ClassifyGoodsQuantity(Quantity: Integer; GoodsType: TGoodsIndex): TStandardCount; // @addr $5FAA30
    function GetGoodsPriceByLevel(Level: TStandardCount; GoodsType: TGoodsIndex): Integer; // @addr $5FAB70
    function ClassifyGoodsPrice(Price: Integer; GoodsType: TGoodsIndex): TStandardCount; // @addr $5FAC48
    function GetSmallGoodsQuantity(GoodsType: TGoodsIndex): Integer; // @addr $5FA8B0
    function GetBigGoodsQuantity(GoodsType: TGoodsIndex): Integer; // @addr $5FA8FC
    function GetHugeGoodsQuantity(GoodsType: TGoodsIndex): Integer; // @addr $5FA924
    function GetMinimumGoodsPrice(GoodsType: TGoodsIndex): Integer; // @addr $5FAAE4
    function GetLowGoodsPrice(GoodsType: TGoodsIndex): Integer; // @addr $5FAAF8
    function GetAverageGoodsPrice(GoodsType: TGoodsIndex): Integer; // @addr $5FAB20
    function GetHighGoodsPrice(GoodsType: TGoodsIndex): Integer; // @addr $5FAB34
    function GetMaximumGoodsPrice(GoodsType: TGoodsIndex): Integer; // @addr $5FAB5C
    procedure ReleaseItemGraphics; // @addr $5E8534
    procedure RefreshAllShipDerivedState; // @addr $5E7D4C
    function IdToAsteroid(Id: Cardinal): TObject; // @addr $5E83FC Searches Asteroids.
    NextConstellationId: Cardinal; // @offset $04
    NextStarId: Cardinal; // @offset $08
    NextHoleId: Cardinal; // @offset $0C
    NextPlanetId: Cardinal; // @offset $10
    NextSputnikId: Cardinal; // @offset $14
    NextAsteroidId: Cardinal; // @offset $18
    NextShipId: Cardinal; // @offset $1C
    NextItemId: Cardinal; // @offset $20
    Stars: TObjectList; // @offset $24 Owns TStar instances.
    Holes: TObjectList; // @offset $28 Owns THole instances.
    Planets: TList; // @offset $2C Borrowed global TPlanet index.
    Rangers: TList; // @offset $30 Borrowed ranger roster, including player.
    AuxiliaryShips: TList; // @offset $34 Borrowed ship-ID roster in SaveToBuffer.
    PirateCount: Integer; // @offset $38 Dword live counter in TPirate.Destroy $58F3D0; saved as Word.
    TransportCount: Integer; // @offset $3C Dword live counter in TTransport.Destroy; saved as Word.
    CurrentTurn: Integer; // @offset $40
    Difficulty: TDifficulty; // @offset $44
    GenerationSeed: Cardinal; // @offset $48
    RandomState: Cardinal; // @offset $4C
    AverageRangerCapital: Integer; // @offset $50
    MaxRangerWealth: Integer; // @offset $54
    AverageRangerStrength: Single; // @offset $58
    BestRangerStrength: Single; // @offset $5C
    StrongestRanger: TObject; // @offset $60 Cached by RefreshRangerStrengthStats $5F950C.
    WealthiestRanger: TObject; // @offset $64 Cached by native wealth refresh $5F945C.
    EminentCareerShips: array[TRangerCareer] of TObject; // @offset $68 Trader, pirate, warrior; TNormalShip.Destroy clears matching entries.
    ShipTypeCounts: array[TShipType] of Integer; // @offset $74 Sum of constellation counts, $5F9E38.
    PlanetNews: TList; // @offset $9C Owns PPlanetNewsEntry records.
    CommunicatorResearchProgress: Single; // @offset $A0
    CommunicatorResearchPerDay: Single; // @offset $A4
    function SelectRandomWeaponTypes(Level, Count: Byte; Heavy: Boolean; Seed: Cardinal): TItemTypeMask; // @addr $5FA37C @ida "void __userpurge $name(TGalaxy *Self@<eax>, unsigned __int8 Level@<dl>, unsigned __int8 Count@<cl>, TItemTypeMask *Result@<^0>, unsigned int Seed@<^4>, bool Heavy@<^8>);"
    function ScaleGoodsPriceByGalaxyAge(Value: Integer): Integer; // @addr $5FA278
    function ScaleByTechLevel(LowValue, HighValue: Integer): Integer; // @addr $5FA2CC
    TechLevel: Byte; // @offset $A8
    WarDeltaWin: Integer; // @offset $AC Signed campaign momentum; $5FBD2C updates on captures/liberations.
    Scripts: TList; // @offset $B0
    LiberationGroups: TList; // @offset $B4 Owns TGroup entries; AddShip/Disband confirm cross-links.
    JumpGates: TList; // @offset $B8 Owns raw descriptors and scene objects; $5E8480.
    ShipsInTransit: TList; // @offset $BC Borrowed ship transfer queue; consumed and cleared by $5E7BB4.
    ConstellationCount: Integer; // @offset $C0 Create initializes 15.
    Constellations: TObjectList; // @offset $C4 Owns TConstellation instances.
    ConstellationOutlineJunctions: TList; // @offset $C8 Owns eight-byte point records; Destroy $5E5460.
    SpaceBackgroundEntries: array of TSpaceBackgroundEntry; // @offset $CC
    MoneyIntegrityFailed: Boolean; // @offset $D0 SetMoney $5ABD4C latches mismatched encoded money.
    StoredIntegrityChecksum: Cardinal; // @offset $D4
    IntegrityChecksumPending: Boolean; // @offset $D8
    ProtectedStateXorSeed: Integer; // @offset $DC RestoreProtectedState consumes it before destruction.
    LastCheatTurn: Integer; // @offset $E0 Cooldown origin in CheatCode.TryUseCheat $5E2B90.
    TotalCheatPoints: Integer; // @offset $E4 Cumulative successful-cheat cost, $5E2B90.
    procedure AppendScoreIntegritySnapshot; // @addr $5ECCA4
    SaveCount: Integer; // @offset $E8 Incremented on each save.
    LoadCount: Integer; // @offset $EC
    PendingEquipmentPurchasePrice: Integer; // @offset $F0
    IntegrityBuffer: TBufEC; // @offset $F4 Owned; contents included in saves.

    constructor Create; // @addr $5E51DC
    destructor Destroy; override; // @addr $5E5460
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5E5828
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5E6014
    procedure InitializeCampaignState; // @addr $5E57D0
    procedure AssignTextQuestsToPlanets; // @addr $5F97C8
    procedure RefreshGoodsMarketPrices; // @addr $5FA1A8
    procedure InitializeConstellationDistanceTiers; // @addr $5F6168
    procedure RebuildAllStarDistances; // @addr $5E7D20
    procedure CreateKlissanSpawnProxy(Star: TObject); // @addr $5F9E04 Star is TObject: the body's as TStar is a native AsClass call.
    procedure XorProtectedState(Seed: Integer); // @addr $5E98EC
    function ComputeIntegrityChecksum: Cardinal; // @addr $5EB564
    procedure ProtectState; // @addr $5EAF74
    procedure StoreIntegrityChecksum; // @addr $5ECC4C
    procedure VerifyIntegrityChecksum; // @addr $5ECC70
    procedure RestoreProtectedState; // @addr $5EAFAC
    procedure ClearJumpGates; // @addr $5E8480
    function CreateJumpGate: PJumpGateEntry; // @addr $5E84D8 Owned by JumpGates until ClearJumpGates.
    function TurnToDateTime(Turn: Integer): Double; // @addr $5F9A7C
    function FormatTurnDate(Turn: Integer): WideString; // @addr $5F9AA4
    procedure UpdateConstellationMilitaryStats; // @addr $5F9E38
    procedure RefreshRangerWealthStats; // @addr $5F945C
    procedure RefreshRangerRatingPlaces; // @addr $5F9598
    procedure RefreshRangerStrengthStats; // @addr $5F950C
    function CountStarsByFaction(Faction: TStarControlFaction): Integer; // @addr $5F9758
    function GetFactionControlPercent(Faction: TStarControlFaction): TPercent; // @addr $5F9794
    function FindStrongestRanger: TObject; // @addr $5F96C8
    function FindWealthiestRanger: TObject; // @addr $5F9710
    procedure AddPlanetNewsWithPlayerBubble(Text: WideString); // @addr $5F9C40
    procedure AddPlanetNews(NewsType: TGalaxyNewsKind; Text: WideString); // @addr $5F9C9C
    function CountPlanetNewsByType(NewsType: TGalaxyNewsKind): Integer; // @addr $5F9D6C
    procedure PrunePlanetNews; // @addr $5F9DB0
    function IdToConstellation(Id: Cardinal): TObject; // @addr $5E7DC4
    function IdToHole(Id: Cardinal): TObject; // @addr $5E7E80
    function IdToStar(Id: Cardinal): TObject; // @addr $5E7E24
    function IdToPlanet(Id: Cardinal): TObject; // @addr $5E7EDC
    function IdToItem(Id: Integer): TObject; // @addr $5E8148
    function IdToShip(Id: Cardinal; RaiseIfMissing: Boolean): TObject; // @addr $5E7F78 Zero ID returns nil; missing nonzero ID raises only when requested.
    procedure GenerateGalaxyLayout(PlayerRace: TRaceId); // @addr $5F6CAC
    procedure GenerateSpaceBackground; // @addr $5E86C4
    procedure CancelEnemyJumpsToStar(Star: TStar); // @addr $5F9FBC
    function RefreshTechLevel: Byte; // @addr $5F9F0C
    function CountVisibleConstellationsWithBoundaryPoints(FirstPoint, SecondPoint: TPointF): Integer; // @addr $5F7D80
    function FindConstellationIndexForStar(Star: TStar): Integer; // @addr $5F611C
    procedure BuildConstellationOutlineJunctions; // @addr $5F62A4
    function ShouldKeepConstellationOutlineVertex(Point: TPointF): Boolean; // @addr $5F6650
    procedure SimplifyConstellationOutline(ConstellationIndex: Integer); // @addr $5F6744
    function BuildConstellationStarGraphs: Boolean; // @addr $5F693C
    procedure BuildConstellationPolygonsAndAdjacency(WorkingPolygon: TPolygon2D); // @addr $5F6984
  end;
  TConstellation = class(TObjectEx) // @size $74
  public
    Id: Cardinal; // @offset $04
    HomeDistanceTier: Byte; // @offset $08 Border-hop tier from the home constellation.
    Visible: Boolean; // @offset $09
    MapCenter: TPointF; // @offset $0C
    OutlineGrowthStepsRemaining: Integer; // @offset $14
    Stars: TList; // @offset $18
    AdjacentConstellations: TList; // @offset $1C Borrowed TConstellation entries.
    OutlineSegments: TList; // @offset $20 Owns PMapLineSegment records, $1C bytes each.
    BoundaryRaySamples: TList; // @offset $24 Owns PConstellationBoundaryRaySample records, $18 bytes each.
    OutlineBounds: TRect; // @offset $28
    OutlineBoundsSize: TPoint; // @offset $38
    StarLinks: TList; // @offset $40 Owns PConstellationStarLink records, $1C bytes each.
    ShipTypeCounts: array[TShipType] of Integer; // @offset $44 Sum of member-star counts, $5F9E38.
    OutlinePolygons: TPolygon2D; // @offset $6C Owned polygon chain.
    SerializedValue70: Word; // @offset $70 Saved at $5F7F54; meaning unresolved.

    constructor Create; // @addr $5F7DEC
    destructor Destroy; override; // @addr $5F7EE8
    procedure ClearStarLinks; // @addr $5F84C8
    procedure ClearBoundaryRaySamples; // @addr $5F8500
    procedure ClearOutlineSegmentsAndBounds; // @addr $5F866C
    procedure ResetGeneratedMapShape; // @addr $5F8770
    procedure ClearStars; // @addr $5F87B0
    procedure ClearAdjacentConstellations; // @addr $5F87C0
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5F7F54
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5F81B4
    procedure ResolveLoadedReferences; // @addr $5F8450
    procedure GenerateBoundaryRaySamples(Count: Integer); // @addr $5F8538
    procedure SetOutlinePolygon(Polygon: TPolygon2D); // @addr $5F8628
    procedure RebuildOutlineSegments; // @addr $5F8648
    procedure AddStar(Star: TStar); // @addr $5F86E4
    procedure AddAdjacentConstellation(Constellation: TConstellation); // @addr $5F8700
    function SharesOutlineSegment(Constellation: TConstellation): Boolean; // @addr $5F8720
    function GetOutlineArea: Single; // @addr $5F87D0
    function FindNextClosestStarPair(var FirstStar, SecondStar: TStar; MinimumDistance: Integer): Integer; // @addr $5F87E4
    function HasStarGraphCycle: Boolean; // @addr $5F89AC
    function IsStarGraphConnected: Boolean; // @addr $5F8AFC
    function BuildStarGraph: Boolean; // @addr $5F8C04
    procedure ExpandOutlineBounds(Point: TPointF); // @addr $5F8D5C
    procedure RefreshOutlineBounds; // @addr $5F8DD0
    function ContainsPoint(Point: TPointF): Boolean; // @addr $5F8EA4
    function HasAdjacentConstellation(Constellation: TConstellation): Boolean; // @addr $5F8F08
    function HasOutlineSegment(FirstPoint, SecondPoint: TPointF): Boolean; // @addr $5F8F44
    function AreBothPointsOnOutline(FirstPoint, SecondPoint: TPointF): Boolean; // @addr $5F8FA0
    function CalculateLabelPosition: TPointF; // @addr $5F9028
    function HasOutlineVertex(Point: TPointF): Boolean; // @addr $5F91AC
    function IsPointNearOutline(Point: TPointF): Boolean; // @addr $5F91F4
    procedure NormalizeOutlineSegmentOrder; // @addr $5F926C
    function GetName: WideString; // @addr $5F9348
    function CountShipsByTypeMask(Types: TShipTypeMask): Integer; // @addr $5F942C
    function HasDominatorPresence: Boolean; // @addr $5F93F8
  end;
  THole = class(TObjectEx) // @size $30
  public
    Id: Cardinal; // @offset $04
    Star1: TStar; // @offset $08
    Position1: TPointF; // @offset $0C
    Star2: TStar; // @offset $14
    Position2: TPointF; // @offset $18
    CreatedTurn: Integer; // @offset $20
    HoleType: TBlackHoleKind; // @offset $24
    Graphic: THoleSE; // @offset $28 Owned; Destroy frees it directly.
    FilmObject: TObject; // @offset $2C Borrowed TEFilmObj.

    constructor Create; // @addr $5ED05C

    destructor Destroy; override; // @addr $5ED0A4
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5ED1EC
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5ED264
    procedure InitializeGraphic; // @addr $5ED0DC
    procedure ResolveLoadedReferences; // @addr $5ED37C
  end;
  TStar = class(TObject) // @size $9C
  public
    function CountPlanetsByOwner(Owner: TOwnerId): Integer; // @addr $5FC338
    function GetRawInfoText: WideString; // @addr $5FC588
    function IsConstellationVisible: Boolean; // @addr $5FC9F0
    function CountDistinctInhabitedPlanetOwners: Integer; // @addr $5FC378

    function CountShipsByTypeMask(Types: TShipTypeMask): Integer; // @addr $5FC420
    function SumBestRangerRelativeStrength(Types: TShipTypeMask): Single; // @addr $5FC9FC Excludes the Klissan mother ship.
    procedure RebuildStarDistances; // @addr $5FCA5C
    procedure QueueHyperspaceShipImageLoads(PendingLoads: TList; Owner: TObjectGI); // @addr $5F5BA0
    procedure QueueSpaceImageLoads(PendingLoads: TList; Owner: TObjectGI); // @addr $5F5A10
    procedure AvoidShipPathCollisions; // @addr $5F512C
    procedure OpenSpaceScene(MapPanel: TPanelGI; Minimap: TObjectGI; Screen: TMessageLoopGI); // @addr $5F5484
    procedure GenerateSystemContents; // @addr $5ED514
    function CountRatedRangersByCareerMask(CareerMask: TRangerCareerSet): Byte; // @addr $5FC450
    function GetRangerNamesByCareerMask(CareerMask: TRangerCareerSet): WideString; // @addr $5FC4C0
    procedure RefreshSpaceObjectPositions; // @addr $5F5888
    procedure NextDay(RecordFilm: Boolean); // @addr $5EEA28
    procedure ClearShipCombatTargets(Target: TObject); // @addr $5EE1B8
    procedure ClearItemReferences(Item: TObject); // @addr $5EE254
    procedure PruneWeaponTargetsAfterTurn; // @addr $5EE2CC
    procedure MarkConnectedCombatEvents(Events: TList; Target: TObject; Group: Integer); // @addr $5EE3D0 Group must be nonzero; Events contains PStarCombatEvent records.
    procedure PrepareNextDay; // @addr $5EE450
    function FindNearestStarByFaction(Faction: TStarControlFaction; InBattle: Boolean): TStar; // @addr $5FCBA4
    function GetBoundaryPointTowardStar(Star: TStar): TPointF; // @addr $5FCBF0
    function HasLiberationGroupOrder: Boolean; // @addr $5FCC8C
    procedure TryGenerateSystemNews; // @addr $5FCD28
    Id: Cardinal; // @offset $04
    GenerationSeed: Cardinal; // @offset $08
    RandomState: Cardinal; // @offset $0C
    LegacySystemKind: Boolean; // @offset $10
    Name: WideString; // @offset $14
    Position: TPointF; // @offset $18
    SystemRadius: Word; // @offset $20
    MapDiameter: Integer; // @offset $24
    Planets: TObjectList; // @offset $28
    Asteroids: TObjectList; // @offset $2C
    Ships: TObjectList; // @offset $30
    Items: TObjectList; // @offset $34
    MovingDropItems: TList; // @offset $38 Owns raw descriptors freed through FreeEC, not TObject instances.
    SystemProcessName: WideString; // @offset $3C
    ThreatLevel: Byte; // @offset $40 RefreshDerivedStats sums ship threat values.
    TrafficLevel: Byte; // @offset $41 Mapped from ship count to 0..100.
    ControlFaction: TStarControlFaction; // @offset $42 Updated at $5FBD2C.
    Battle: Boolean; // @offset $43
    SafeRadius: Single; // @offset $44
    DamageRadius: Single; // @offset $48
    Radius: Integer; // @offset $4C Generation reads the star template; saved as Word.
    Graphic: TObjectSE; // @offset $50 Owned.
    TemplatePath: WideString; // @offset $54 Star.<template>; GenerateSystemContents $5ED514.
    DaysSincePlayerVisit: Integer; // @offset $58 Reset/incremented by NextDay at $5EEB06/$5EEB0E.
    DaysSinceLastNpcShipSpawn: Integer; // @offset $5C BuyRanger resets it at $5C53A6.
    CombatOccurred: Boolean; // @offset $60 Ship combat or stellar damage this turn.
    PlayerCombatActive: Boolean; // @offset $61 Planned combat for camera setup, then actual combat/stellar damage for film and travel.
    PlayerInteractionOccurred: Boolean; // @offset $62 Player pickup or completed dialogue; interrupts travel.
    KlissanCaptureDays: Byte; // @offset $63 Consecutive uncontested Klissan presence; capture at three.
    StarDistances: array of TStarDistance; // @offset $64
    ShipTypeCounts: array[TShipType] of Integer; // @offset $68 Reset and counted by $5FC3E0.
    Constellation: TConstellation; // @offset $90
    ConstellationGraphIndex: Word; // @offset $94 One-based index stored by BuildStarGraph.
    RangerCenter: TObject; // @offset $98 TRC cache restored by ResolveLoadedReferences.

    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5ED934
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5EDBD0
    procedure ResolveLoadedReferences; // @addr $5EE0D4
    procedure RefreshDerivedStats; // @addr $5FBC74
    procedure RefreshMapDiameterAndStats; // @addr $5FC2DC
    function ComputeMapDiameter: Integer; // @addr $5FC2F4
    procedure RebuildShipMovementPaths; // @addr $5F5448
    function FindFirstInhabitedPlanet: TObject; // @addr $5FC39C Returns the final planet if none is inhabited.
    procedure HandleObjectLeavingStar(Obj: TObject); // @addr $5F5004
    procedure UpdateControlFaction; // @addr $5FBD2C
    procedure RecountShipTypes; // @addr $5FC3E0
    function SelectBackground(var Index: Integer): WideString; // @addr $5F5BFC
    function HasHostilePresenceForScriptBinding: Boolean; // @addr $5FCB68
    constructor Create; // @addr $5ED3B8
    destructor Destroy; override; // @addr $5ED478
  end;
function GameTurnToDateTime(Turn: Integer): Double; // @addr $5F5CCC
function FormatGameTurnDate(Turn: Integer): WideString; // @addr $5F5CEC

var
  Galaxy: TGalaxy; // @addr $61D090
  PlayerStar: TStar; // @addr $61D094 Selects detailed movement timing for the player system.
  RangerWealthDerivedValue1: Integer; // @addr $61D098 Written as AverageRangerCapital / 30; no native readers found.
  RangerWealthDerivedValue2: Integer; // @addr $61D09C Same calculation, separate native store; use unresolved.
  FollowModeSeed: Cardinal; // @addr $61D0A0 Used with CurrentTurn by ship follow-mode selection.
  PlayerDialogueRequestCount: Byte; // @addr $61D0A4 Incremented by TShip.TryExtortShip; caps manual player dialogue requests.
  ReservedMessageCounter: Cardinal; // @addr $61D0A8
  TurnsSinceLastShipMessage: Cardinal; // @addr $61D0AC

function EstimatePlayerTravelTurns: Single; // @addr $5F5F5C

function ShouldContinuePlayerTravel: Boolean; // @addr $5F5E70

implementation

// @unit-initialization $5FDB5C
// @unit-finalization $5FDB2C

uses Globals, aKling, EC_Mem, SE_Process, aShip, aPlanet, aPlayer, aItem, aAsteroid, Math, SysUtils, GR_Main, aConst, EC_BlockPar, SE_Star, aTranclucator, aRanger, aScript, aGroup, GlobalsV, fEquipmentShop, EC_Str, aRuins, SE_Ship2, EC_Expression, aRuinsRC, aNormalShip, aArtifact, aQuestParameterClass, aQuestParameterDeltaClass, aArtifactLocationClass, aArtifactPathClass, fPlanetQuest, fShip2, fGov, ab_Ship, EC_File, CrcUnit, aRuinsWB, aRuinsPB, aRuinsSB, aPath, aEFilm, aEObjInfo, SE_Weapon;

const GalaxySizeX = 145; GalaxySizeY = 100;
var
  CameraSlowSpeed: Integer = 10; // @addr $618964
  CameraFastSpeed: Integer = 20; // @addr $618968

var
  SystemNewsChance: Integer = 55; // @addr $61896C Scratch probability used by TStar.TryGenerateSystemNews.

{ @routine $5E51DC TGalaxy_Create }
constructor TGalaxy.Create;
var I, TemplateCount: Integer; Template: TScriptTemplUnit;
begin
  inherited Create;
  LastCheatTurn := 0;
  TotalCheatPoints := 0;
  SaveCount := 0;
  LoadCount := 0;
  IntegrityBuffer := TBufEC.Create;
  Randomize;
  GenerationSeed := RandomIntRange(100000, MaxInt);
  RandomState := GenerationSeed;
  AverageRangerCapital := 3000;
  MaxRangerWealth := 3000;
  AverageRangerStrength := 1;
  BestRangerStrength := 1;
  ConstellationCount := 15;
  Constellations := TObjectList.Create;
  Stars := TObjectList.Create;
  Holes := TObjectList.Create;
  Planets := TList.Create;
  Rangers := TList.Create;
  AuxiliaryShips := TList.Create;
  ShipsInTransit := TList.Create;
  Scripts := TList.Create;
  LiberationGroups := TList.Create;
  PlanetNews := TList.Create;
  if PrimaryFilm <> nil then PrimaryFilm.Clear;
  if SecondaryFilm <> nil then SecondaryFilm.Clear;
  ClearPersistentPlayerMessages;
  JumpGates := TList.Create;
  NextConstellationId := 1;
  NextStarId := 1;
  NextHoleId := 1;
  NextPlanetId := 1;
  NextSputnikId := 1;
  NextAsteroidId := 1;
  NextShipId := 1;
  NextItemId := 1;
  SharedScriptVariables.CopyFrom(GlobalScriptVariables);
  TemplateCount := ScriptTemplates.Count;
  for I := 0 to TemplateCount - 1 do
  begin
    Template := ScriptTemplates[I];
    Template.UseCount := 0;
    Template.LastTurn := 0;
    Template.ConditionCode.LinkAll(SharedScriptVariables);
    Template.ConditionCode.LinkAll(ScriptFunctionScope);
    Template.ActiveScriptIndex := -1;
  end;
  ScenarioState := scenNone;
  PreviousFilmActivity := 0;
  ShownPlayerTips := 0;
  EminentCareerShips[rcTrader] := nil;
  EminentCareerShips[rcPirate] := nil;
  EminentCareerShips[rcWarrior] := nil;
  ReservedMessageCounter := 0;
  TurnsSinceLastShipMessage := 0;
end;
{ @end $5E51DC }

{ @routine $5E5460 TGalaxy_Destroy }
destructor TGalaxy.Destroy;
var
  Point: PPointF;
  I, J: Integer;
  Star: TStar;
  Planet: TPlanet;
  News: PPlanetNewsEntry;
begin
  if ProtectedStateXorSeed <> 0 then Galaxy.RestoreProtectedState;
  if ConstellationOutlineJunctions <> nil then
  begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do
    begin
      Point := ConstellationOutlineJunctions[I];
      Dispose(Point);
    end;
    ConstellationOutlineJunctions.Clear;
    ConstellationOutlineJunctions.Free;
    ConstellationOutlineJunctions := nil;
  end;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    while Star.Ships.Count > 0 do TObject(Star.Ships[0]).Free;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      while Planet.Warriors.Count > 0 do TObject(Planet.Warriors[0]).Free;
    end;
  end;
  if Scripts <> nil then
  begin
    for I := 0 to Scripts.Count - 1 do TObject(Scripts[I]).Free;
    Scripts.Free;
    Scripts := nil;
  end;
  if LiberationGroups <> nil then
  begin
    for I := 0 to LiberationGroups.Count - 1 do TObject(LiberationGroups[I]).Free;
    LiberationGroups.Free;
    LiberationGroups := nil;
  end;
  Stars.Free;
  Stars := nil;
  Holes.Free;
  Holes := nil;
  Planets.Clear;
  Planets.Free;
  Planets := nil;
  Rangers.Clear;
  Rangers.Free;
  Rangers := nil;
  AuxiliaryShips.Clear;
  AuxiliaryShips.Free;
  AuxiliaryShips := nil;
  ShipsInTransit.Clear;
  ShipsInTransit.Free;
  ShipsInTransit := nil;
  Constellations.Free;
  Constellations := nil;
  for I := PlanetNews.Count - 1 downto 0 do
  begin
    News := PlanetNews[I];
    PlanetNews.Delete(I);
    Dispose(News);
  end;
  PlanetNews.Clear;
  PlanetNews.Free;
  PlanetNews := nil;
  ClearJumpGates;
  JumpGates.Free;
  JumpGates := nil;
  Player := nil;
  PlayerStar := nil;
  if KlissanSpawnPlanet <> nil then
  begin
    KlissanSpawnPlanet.Free;
    KlissanSpawnPlanet := nil;
  end;
  ClearTemporaryShopSlots;
  ClearPersistentPlayerMessages;
  if PrimaryFilm <> nil then PrimaryFilm.Clear;
  if SecondaryFilm <> nil then SecondaryFilm.Clear;
  SpaceBackgroundEntries := nil;
  IntegrityBuffer.Free;
  inherited Destroy;
end;
{ @end $5E5460 }

{ @routine $5E57D0 TGalaxy_InitializeCampaignState }
procedure TGalaxy.InitializeCampaignState;
begin
  CurrentTurn := 0;
  PirateCount := 0;
  TransportCount := 0;
  StarMapWeaponPanelOpen := True;
  CommunicatorResearchProgress := DifficultyModifiers[Difficulty].InitialCommunicatorResearch;
  CommunicatorResearchPerDay := 0.01;
  WarDeltaWin := 0;
  RefreshGoodsMarketPrices;
end;
{ @end $5E57D0 }

{ @routine $5E5828 TGalaxy_SaveToBuffer }
procedure TGalaxy.SaveToBuffer(Buffer: TBufEC);
var I, Count: Integer; Star: TStar; Planet: TPlanet; Ranger: TRanger;
  OldQuest: PPlayerOldQuest; Gate: PJumpGateEntry; Constellation: TConstellation;
  Template: TScriptTemplUnit; Script: TScript; Group: TGroup; ShopSlot: TShopSlot;
  Hole: THole; Career: TRangerCareer; News: PPlanetNewsEntry; AuxiliaryShip: TShip;
begin
  Buffer.AddIntegerValue(GenerationSeed);
  Buffer.AddDWord(RandomState);
  Buffer.AddIntegerValue(AverageRangerCapital);
  Buffer.AddIntegerValue(MaxRangerWealth);
  Buffer.AddSingle(AverageRangerStrength);
  Buffer.AddSingle(BestRangerStrength);
  Buffer.AddBoolean(MoneyIntegrityFailed);
  Buffer.AddIntegerValue(LastCheatTurn);
  Buffer.AddIntegerValue(TotalCheatPoints);
  Inc(SaveCount);
  Buffer.AddIntegerValue(SaveCount);
  Buffer.AddIntegerValue(LoadCount);
  Count := Constellations.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.SaveToBuffer(Buffer);
  end;
  Count := Stars.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Star := TStar(Stars[I]);
    Star.SaveToBuffer(Buffer);
  end;
  Count := Holes.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Hole := THole(Holes[I]);
    Hole.SaveToBuffer(Buffer);
  end;
  Count := JumpGates.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Gate := JumpGates[I];
    Buffer.AddSingle(Gate.Gate.Position.X);
    Buffer.AddSingle(Gate.Gate.Position.Y);
    Buffer.AddAnsiChar(AnsiChar(Gate.Gate.GetAngle));
    Buffer.AddWideStringZ(Gate.Gate.GetText);
  end;
  Count := Planets.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Planet := Planets[I];
    Buffer.AddDWord(Planet.Id);
  end;
  Count := Rangers.Count;
  Buffer.AddWord(Word(Count));
  for I := 0 to Count - 1 do begin
    Ranger := Rangers[I];
    Buffer.AddDWord(Ranger.Id);
  end;
  Count := AuxiliaryShips.Count;
  Buffer.AddWord(Word(Count));
  for I := 0 to Count - 1 do begin
    AuxiliaryShip := AuxiliaryShips[I];
    Buffer.AddDWord(AuxiliaryShip.Id);
  end;
  Count := 0;
  if TemporaryShopSlots <> nil then Count := TemporaryShopSlots.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    ShopSlot := TemporaryShopSlots[I];
    ShopSlot.SaveToBuffer(Buffer);
  end;
  SharedScriptVariables.SaveToBuffer(Buffer);
  Count := ScriptTemplates.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Template := ScriptTemplates[I];
    Buffer.AddWideStringZ(Template.Name);
    Buffer.AddWideChar(WideChar(Template.UseCount));
    Buffer.AddIntegerValue(Template.LastTurn);
    Buffer.AddIntegerValue(Template.ActiveScriptIndex);
  end;
  Count := Scripts.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Script := Scripts[I];
    Script.SaveState(Buffer);
  end;
  Count := LiberationGroups.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Group := LiberationGroups[I];
    Group.Save(Buffer);
  end;
  Buffer.AddIntegerValue(Integer(ScenarioState));
  Buffer.AddWideChar(WideChar(PirateCount));
  Buffer.AddWideChar(WideChar(TransportCount));
  Buffer.AddDWord(CurrentTurn);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Difficulty)));
  Buffer.AddDWord(Player.Id);
  if PendingPlayerFollowTarget = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(PendingPlayerFollowTarget.Id);
  if KlingMotherShip = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(KlingMotherShip.Id);
  Buffer.AddDWord(PlayerStar.Id);
  for Career := Low(TRangerCareer) to High(TRangerCareer) do begin
    if EminentCareerShips[Career] = nil then Buffer.AddDWord(0)
    else Buffer.AddDWord((EminentCareerShips[Career] as TShip).Id);
  end;
  Count := PlayerOldQuests.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    OldQuest := PlayerOldQuests[I];
    if OldQuest.Planet = nil then Buffer.AddDWord(0)
    else Buffer.AddDWord(OldQuest.Planet.Id);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(OldQuest.QuestType)));
    Buffer.AddWideChar(WideChar(OldQuest.QuestNumber));
    Buffer.AddWideStringZ(OldQuest.Description);
    Buffer.AddBoolean(OldQuest.Successful);
  end;
  Count := PlanetNews.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    News := PlanetNews[I];
    Buffer.AddDWord(News.Turn);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(News.NewsType)));
    Buffer.AddWideStringZ(News.Text);
  end;
  Buffer.AddDWord(ReservedMessageCounter);
  Buffer.AddDWord(TurnsSinceLastShipMessage);
  Buffer.AddSingle(CommunicatorResearchProgress);
  Buffer.AddSingle(CommunicatorResearchPerDay);
  Buffer.AddIntegerValue(WarDeltaWin);
  Buffer.AddBuffer(IntegrityBuffer);
  Buffer.AddIntegerValue(High(SpaceBackgroundEntries) + 1);
  for I := 0 to High(SpaceBackgroundEntries) do begin
    Buffer.AddIntegerValue(SpaceBackgroundEntries[I].ImageIndex);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitCenter.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Position.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.X);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.Y);
    Buffer.AddSingle(SpaceBackgroundEntries[I].Unknown38.Z);
    Buffer.AddSingle(SpaceBackgroundEntries[I].OrbitStepDegrees);
    Buffer.AddIntegerValue(SpaceBackgroundEntries[I].FrameIndex);
  end;
end;
{ @end $5E5828 }

{ @routine $5E6014 TGalaxy_LoadFromBuffer }
procedure TGalaxy.LoadFromBuffer(Buffer: TBufEC);
var I, J: Integer; X, Y: Single; Star: TStar; Ship: TShip;
  OldQuest: PPlayerOldQuest; Gate: PJumpGateEntry; Constellation: TConstellation;
  Template: TScriptTemplUnit; Script: TScript; Group: TGroup; ShopSlot: TShopSlot;
  Hole: THole; Career: TRangerCareer; News: PPlanetNewsEntry;
  Variables: TVarArrayEC; Variable, Existing: TVarEC;
begin
  GenerationSeed := Buffer.GetInt32;
  RandomState := Buffer.GetUInt32;
  AverageRangerCapital := Buffer.GetInt32;
  MaxRangerWealth := Buffer.GetInt32;
  AverageRangerStrength := Buffer.GetSingle;
  BestRangerStrength := Buffer.GetSingle;
  if LoadedSaveVersion >= 4 then MoneyIntegrityFailed := Buffer.GetBoolean
  else MoneyIntegrityFailed := False;
  if LoadedSaveVersion >= 7 then begin
    LastCheatTurn := Buffer.GetInt32;
    TotalCheatPoints := Buffer.GetInt32;
  end else begin
    LastCheatTurn := 0;
    TotalCheatPoints := 0;
  end;
  if LoadedSaveVersion >= 10 then begin
    SaveCount := Buffer.GetInt32;
    LoadCount := Buffer.GetInt32 + 1;
  end else begin
    SaveCount := 0;
    LoadCount := 1;
  end;
  I := Buffer.GetWord;
  if (I < 1) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do begin
    Constellation := TConstellation.Create;
    Constellations.Add(Constellation);
    Constellation.LoadFromBuffer(Buffer);
  end;
  I := Buffer.GetWord;
  if (I < 1) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do begin
    Star := TStar.Create;
    Stars.Add(Star);
    Star.LoadFromBuffer(Buffer);
  end;
  I := Buffer.GetWord;
  if (I < 0) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do begin
    Hole := THole.Create;
    Holes.Add(Hole);
    Hole.LoadFromBuffer(Buffer);
  end;
  ClearJumpGates;
  I := Buffer.GetWord;
  if (I < 0) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do begin
    Gate := CreateJumpGate;
    X := Buffer.GetSingle;
    Y := Buffer.GetSingle;
    Gate.Gate.SetPosition(MakePointF(X, Y));
    Gate.Gate.SetAngle(Buffer.GetByte);
    Gate.Gate.SetText(Buffer.ReadWideString);
  end;
  I := Buffer.GetWord;
  if (I < 1) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do Planets.Add(Pointer(Buffer.GetUInt32));
  I := Buffer.GetWord;
  if (I < 1) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do Rangers.Add(Pointer(Buffer.GetUInt32));
  I := Buffer.GetWord;
  if (I < 0) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do AuxiliaryShips.Add(Pointer(Buffer.GetUInt32));
  ClearTemporaryShopSlots;
  I := Buffer.GetWord;
  if I > 0 then begin
    TemporaryShopSlots := TList.Create;
    for I := 0 to I - 1 do begin
      ShopSlot := TShopSlot.Create;
      TemporaryShopSlots.Add(ShopSlot);
      ShopSlot.LoadFromBuffer(Buffer);
    end;
  end;
  Variables := TVarArrayEC.Create;
  Variables.LoadFromBuffer(Buffer);
  for I := 0 to Variables.Count - 1 do begin
    Variable := Variables.GetItem(I);
    Existing := SharedScriptVariables.GetVarNE(Variable.Name);
    if Existing <> nil then Existing.Assume(Variable);
  end;
  Variables.Free;
  I := ScriptTemplates.Count;
  for I := 0 to I - 1 do begin
    Template := ScriptTemplates[I];
    Template.UseCount := 0;
    Template.LastTurn := 0;
  end;
  I := Buffer.GetWord;
  for I := 0 to I - 1 do begin
    J := FindScriptTemplateIndex(Buffer.ReadWideString);
    if J < 0 then raise Exception.Create('Script not found');
    Template := ScriptTemplates[J];
    Template.UseCount := Buffer.GetWord;
    Template.LastTurn := Buffer.GetInt32;
    Template.ActiveScriptIndex := Buffer.GetInt32;
  end;
  I := Buffer.GetWord;
  for I := 0 to I - 1 do begin
    Script := TScript.Create;
    Scripts.Add(Script);
    Script.LoadState(Buffer);
  end;
  I := Buffer.GetWord;
  for I := 0 to I - 1 do begin
    Group := TGroup.Create;
    LiberationGroups.Add(Group);
    Group.Load(Buffer);
  end;
  ScenarioState := TScenarioState(Buffer.GetInt32);
  PirateCount := Buffer.GetWord;
  TransportCount := Buffer.GetWord;
  if LoadedSaveVersion < 8 then CurrentTurn := Buffer.GetWord
  else CurrentTurn := Buffer.GetUInt32;
  WriteByteValue(Buffer.GetByte, Difficulty);
  Player := TPlayer(Buffer.GetUInt32);
  PendingPlayerFollowTarget := TShip(Buffer.GetUInt32);
  KlingMotherShip := TKling(Buffer.GetUInt32);
  PlayerStar := TStar(Buffer.GetUInt32);
  for Career := Low(TRangerCareer) to High(TRangerCareer) do EminentCareerShips[Career] := TObject(Buffer.GetUInt32);
  I := Constellations.Count;
  for I := 0 to I - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.ResolveLoadedReferences;
  end;
  I := Stars.Count;
  for I := 0 to I - 1 do begin
    Star := TStar(Stars[I]);
    Star.ResolveLoadedReferences;
  end;
  I := Holes.Count;
  for I := 0 to I - 1 do begin
    Hole := THole(Holes[I]);
    Hole.ResolveLoadedReferences;
  end;
  I := Planets.Count;
  for I := 0 to I - 1 do Planets[I] := Galaxy.IdToPlanet(Cardinal(Planets[I])) as TPlanet;
  I := Rangers.Count;
  for I := 0 to I - 1 do Rangers[I] := Galaxy.IdToShip(Cardinal(Rangers[I]), True) as TShip;
  I := AuxiliaryShips.Count;
  for I := 0 to I - 1 do AuxiliaryShips[I] := Galaxy.IdToShip(Cardinal(AuxiliaryShips[I]), True) as TShip;
  Player := Galaxy.IdToShip(Cardinal(Player), True) as TPlayer;
  PendingPlayerFollowTarget := Galaxy.IdToShip(Cardinal(PendingPlayerFollowTarget), True) as TShip;
  KlingMotherShip := Galaxy.IdToShip(Cardinal(KlingMotherShip), True) as TKling;
  PlayerStar := Galaxy.IdToStar(Cardinal(PlayerStar)) as TStar;
  for Career := Low(TRangerCareer) to High(TRangerCareer) do EminentCareerShips[Career] := Galaxy.IdToShip(Cardinal(EminentCareerShips[Career]), True) as TRanger;
  PlayerOldQuests := TObjectList.Create;
  I := Buffer.GetWord;
  if (I < 0) or (I > 10000) then raise EAbort.Create('Err in PlayerQuests load');
  for I := 0 to I - 1 do begin
    New(OldQuest);
    PlayerOldQuests.Add(OldQuest);
    OldQuest.Planet := TPlanet(Buffer.GetUInt32);
    OldQuest.Planet := Galaxy.IdToPlanet(Cardinal(OldQuest.Planet)) as TPlanet;
    WriteByteValue(Buffer.GetByte, OldQuest.QuestType);
    OldQuest.QuestNumber := Buffer.GetWord;
    OldQuest.Description := Buffer.ReadWideString;
    OldQuest.Successful := Buffer.GetBoolean;
  end;
  I := Buffer.GetWord;
  if (I < 0) or (I > 10000) then raise EAbort.Create('Err');
  for I := 0 to I - 1 do begin
    New(News);
    PlanetNews.Add(News);
    News.Turn := Buffer.GetUInt32;
    WriteByteValue(Buffer.GetByte, News.NewsType);
    News.Text := Buffer.ReadWideString;
  end;
  ReservedMessageCounter := Buffer.GetUInt32;
  TurnsSinceLastShipMessage := Buffer.GetUInt32;
  CommunicatorResearchProgress := Buffer.GetSingle;
  CommunicatorResearchPerDay := Buffer.GetSingle;
  if LoadedSaveVersion < 7 then WarDeltaWin := 0
  else WarDeltaWin := Buffer.GetInt32;
  if LoadedSaveVersion < 5 then IntegrityBuffer.Clear
  else Buffer.ReadLengthPrefixedBuffer(IntegrityBuffer);
  if LoadedSaveVersion < 3 then SpaceBackgroundEntries := nil
  else begin
    I := Buffer.GetInt32;
    if (I < 0) or (I > 1000000) then raise EAbort.Create('Err');
    SetLength(SpaceBackgroundEntries, I);
    for I := 0 to High(SpaceBackgroundEntries) do begin
      SpaceBackgroundEntries[I].ImageIndex := Buffer.GetInt32;
      SpaceBackgroundEntries[I].OrbitCenter.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitCenter.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitCenter.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Position.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.X := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.Y := Buffer.GetSingle;
      SpaceBackgroundEntries[I].Unknown38.Z := Buffer.GetSingle;
      SpaceBackgroundEntries[I].OrbitStepDegrees := Buffer.GetSingle;
      SpaceBackgroundEntries[I].FrameIndex := Buffer.GetInt32;
    end;
  end;
  I := Scripts.Count;
  for I := 0 to I - 1 do begin
    Script := Scripts[I];
    Script.ResolveLoadedReferences;
  end;
  I := LiberationGroups.Count;
  for I := 0 to I - 1 do begin
    Group := LiberationGroups[I];
    Group.ResolveLoadedReferences;
  end;
  I := Stars.Count;
  for I := 0 to I - 1 do begin
    Star := TStar(Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := TShip(Star.Ships[J]);
      if Ship.ShipType = t_Warrior then Ship.HomePlanet.Warriors.Add(Ship);
    end;
  end;
  RefreshGoodsMarketPrices;
  InitializeConstellationDistanceTiers;
  RebuildAllStarDistances;
  UpdateConstellationMilitaryStats;
  RefreshRangerWealthStats;
  RefreshRangerStrengthStats;
  RefreshRangerRatingPlaces;
  RefreshTechLevel;
  if KlingMotherShip <> nil then CreateKlissanSpawnProxy(KlingMotherShip.CurrentStar)
  else CreateKlissanSpawnProxy(nil);
  for I := 0 to Stars.Count - 1 do begin
    Star := TStar(Stars[I]);
    Star.RefreshMapDiameterAndStats;
  end;
end;
{ @end $5E6014 }

{ @routine $5E6DCC TGalaxy_NextDay }
procedure TGalaxy.NextDay;
var I, J: Integer; Script: TScript; Message: TMessagePlayer; Group: TGroup; Star: TStar;
begin
  I := 0;
  while I < Scripts.Count do
  begin
    Script := TScript(Scripts[I]);
    Script.RunTurnCode;
    if Script.Ships.Count < 1 then
    begin
      for J := 0 to Script.EtherIds.GetCount - 1 do
      begin
        Message := FindPlayerBubbleByKey(Script.EtherIds.GetTextAt(J));
        if (Message <> nil) and (Message.Kind = pmQuestNormal) then Message.Kind := pmQuestCancel;
      end;
      Scripts.Delete(I);
      try
        Script.Free;
      except
        AppendLogLineThreadSafe('Error Galaxy.Script.Free');
      end;
      for J := 0 to ScriptTemplates.Count - 1 do
        if TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex = I then
          TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex := -1
        else if TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex > I then
          Dec(TScriptTemplUnit(ScriptTemplates[J]).ActiveScriptIndex);
    end
    else Inc(I);
  end;
  Inc(CurrentTurn);
  RefreshTechLevel;
  UpdateConstellationMilitaryStats;
  TryCreateDailyStation;
  PlayerDialogueRequestCount := 0;
  Inc(ReservedMessageCounter);
  Inc(TurnsSinceLastShipMessage);
  if CurrentTurn mod 365 = 0 then RefreshGoodsMarketPrices;
  RefreshRangerWealthStats;
  RefreshRangerStrengthStats;
  RefreshRangerRatingPlaces;
  PrunePlanetNews;
  if Player <> nil then
  begin
    Player.RebuildEquipmentCache;
    if IsFinalScenarioActive then Player.ProcessFinalScenarioWithdrawal;
  end;
  if (((CurrentTurn + Integer(GenerationSeed)) mod DifficultyModifiers[Difficulty].LiberationGroupInterval = 0) and
    (CurrentTurn >= 200)) or (Galaxy.WarDeltaWin < -4) then TryCreateLiberationGroup(0);
  for I := LiberationGroups.Count - 1 downto 0 do
  begin
    Group := TGroup(LiberationGroups[I]);
    Group.NextDay;
  end;
  for I := 1 to Galaxy.Stars.Count do
  begin
    Star := TStar(Stars[I - 1]);
    if (Player = nil) or (Star <> Player.CurrentStar) then Star.NextDay(False);
  end;
end;
{ @end $5E6DCC }

{ @routine $5E70C0 TGalaxy_CompleteDay }
procedure TGalaxy.CompleteDay;
var Hole: THole; Ship: TShip; I, J, Count: Integer; Angle, Radius: Single; Star: TStar;
begin
  AdvanceCommunicatorResearch;
  ApplyNodeDepositInactivityPenalty;
  if (Player <> nil) and Player.InHyperspace and (Cardinal(Player.OrderStateData and TravelDaysMask) = 1) then
  begin
    I := 0;
    while I < Galaxy.Holes.Count do
    begin
      Hole := THole(Galaxy.Holes[I]);
      if (Hole.HoleType = bhkUsed) or ((Hole.HoleType = bhkOrdinary) and (CurrentTurn - Hole.CreatedTurn > 200)) then
      begin
        J := 0;
        Count := Hole.Star1.Ships.Count;
        while J < Count do
        begin
          Ship := TShip(Hole.Star1.Ships[J]);
          if (Ship.Order = soEnterBlackHole) and (Ship.OrderTarget = Hole) then Break;
          Inc(J);
        end;
        if J >= Count then
        begin
          J := 0;
          Count := Hole.Star2.Ships.Count;
          while J < Count do
          begin
            Ship := TShip(Hole.Star2.Ships[J]);
            if (Ship.Order = soEnterBlackHole) and (Ship.OrderTarget = Hole) then Break;
            Inc(J);
          end;
          if J >= Count then
          begin
            Galaxy.Holes.Delete(I);
            Hole.Free;
            Dec(I);
          end;
        end;
      end;
      Inc(I);
    end;
  end;
  if (Player <> nil) and
    (NextRandomIntRange(0, DifficultyModifiers[Difficulty].HoleCreationRandomMaximum, RandomState) = 0) and
    (Galaxy.Holes.Count <= 2) and (ScenarioState = scenNone) and
    (Galaxy.CountStarsByFaction(sfCoalition) > 3) and (Galaxy.CurrentTurn > 200) then
  begin
    Hole := THole.Create;
    Hole.InitializeGraphic;
    Hole.HoleType := bhkOrdinary;
    Hole.CreatedTurn := Galaxy.CurrentTurn;
    J := 0;
    while True do
    begin
      Inc(J);
      if J > 100 then Break;
      Count := Integer((Galaxy).Stars[NextRandomIntRange(0, Galaxy.Stars.Count - 1, RandomState)]);
      Hole.Star1 := TStar(Count);
      if (Count <> Integer(Player.CurrentStar)) and TStar(Count).Constellation.Visible and
        (TStar(Count).DaysSincePlayerVisit >= 30) and (TStar(Count).ControlFaction <> sfKlissan) then Break;
    end;
    if J > 100 then Hole.Free
    else
    begin
      J := 0;
      while True do
      begin
        Inc(J);
        if J > 100 then Break;
        Count := Integer((Galaxy).Stars[NextRandomIntRange(0, Galaxy.Stars.Count - 1, RandomState)]);
        Hole.Star2 := TStar(Count);
        // Native rechecks Star1's visit age while selecting Star2.
        Star := Hole.Star1;
        if (Count <> Integer(Star)) and (Count <> Integer(Player.CurrentStar)) and
          TStar(Count).Constellation.Visible and (Star.DaysSincePlayerVisit >= 30) then Break;
      end;
      if J > 100 then Hole.Free
      else
      begin
        Galaxy.Holes.Add(Hole);
        Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, (Galaxy.CurrentTurn + Hole.Star1.GenerationSeed) * Galaxy.GenerationSeed));
        Radius := SeededRandomIntRange(Round(Hole.Star1.MapDiameter * 0.5 * 0.7), Round(Hole.Star1.MapDiameter * 0.5 * 0.9),
          (Galaxy.CurrentTurn + Hole.Star1.GenerationSeed + J) * Galaxy.GenerationSeed);
        Hole.Position1 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
        Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, (Galaxy.CurrentTurn + Hole.Star2.GenerationSeed) * Galaxy.GenerationSeed));
        Radius := SeededRandomIntRange(Round(Hole.Star2.MapDiameter * 0.5 * 0.7), Round(Hole.Star2.MapDiameter * 0.5 * 0.9),
          (Galaxy.CurrentTurn + Hole.Star2.GenerationSeed + J) * Galaxy.GenerationSeed);
        Hole.Position2 := MakePointF(Sin(Angle) * Radius, -Cos(Angle) * Radius);
        AddPlanetNews(gnGeneral, FormatText2(PickLocalizedTextVariant('GalaxyNews.BlackHole.Create',
          (Galaxy.CurrentTurn + Hole.Star1.GenerationSeed) * Galaxy.GenerationSeed),
          HighlightColorTag, '<Star1>', Hole.Star1.Name, '<Star2>', Hole.Star2.Name));
      end;
    end;
  end;
  if CurrentTurn mod 30 = 0 then AppendScoreIntegritySnapshot;
end;
{ @end $5E70C0 }

{ @routine $5E767C TGalaxy_AppendShipDatabaseLog }
procedure TGalaxy.AppendShipDatabaseLog;
var I, J, Count: Integer; Star: TStar; Ship: TShip; LogFile: TFileEC; Buffer: TBufEC;
    RecordCount: Integer; OrderText, TargetText, ParameterText: WideString;
begin
  LogFile := TFileEC.Create;
  LogFile.SetFileName('#ship.dbf');
  LogFile.AcquireReadWriteHandle;
  Buffer := TBufEC.Create;
  LogFile.SetPointer(4, 0);
  LogFile.ReadBuffer(@RecordCount, SizeOf(RecordCount));
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Ships.Count;
    for J := 0 to Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      Buffer.AddAnsiChar(' ');
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(IntToStr(CurrentTurn), 8)));
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(IntToStr(Ship.Id), 8)));
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(AnsiString(Ship.GetLegacyShipTypeLabel), 64)));
      Buffer.AddAnsiStringRaw(PAnsiChar(AnsiStringToOem(PadOrTruncateAnsiString(AnsiString(Ship.CurrentStar.Name), 64))));
      if Ship.CurrentPlanet = nil then Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString('', 64)))
      else Buffer.AddAnsiStringRaw(PAnsiChar(AnsiStringToOem(PadOrTruncateAnsiString(AnsiString(Ship.CurrentPlanet.Name), 64))));
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(IntToStr(Round(Ship.Position.X)), 16)));
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(IntToStr(Round(Ship.Position.Y)), 16)));
      Ship.GetOrderDebugText(OrderText, TargetText, ParameterText);
      Buffer.AddAnsiStringRaw(PAnsiChar(PadOrTruncateAnsiString(AnsiString(OrderText), 64)));
      Buffer.AddAnsiStringRaw(PAnsiChar(AnsiStringToOem(PadOrTruncateAnsiString(AnsiString(TargetText), 64))));
      Buffer.AddAnsiStringRaw(PAnsiChar(AnsiStringToOem(PadOrTruncateAnsiString(AnsiString(ParameterText), 64))));
      Buffer.AddAnsiStringRaw(PAnsiChar(AnsiStringToOem(PadOrTruncateAnsiString(AnsiString(Ship.DatabaseLogText), 254))));
      Ship.DatabaseLogText := '';
      Inc(RecordCount);
    end;
  end;
  LogFile.SetPointer(4, 0);
  LogFile.WriteBuffer(@RecordCount, SizeOf(RecordCount));
  Buffer.AddAnsiChar(#26);
  LogFile.SetPointer(Cardinal(-1), 2);
  LogFile.WriteBuffer(Buffer.Data, Buffer.DataSize);
  LogFile.Free;
  Buffer.Free;
end;
{ @end $5E767C }

{ @routine $5E7BB4 TGalaxy_TransferShipsInTransit }
procedure TGalaxy.TransferShipsInTransit;
var I, J, Count: Integer; Ship: TShip; Hole: THole;
begin
  for I := 0 to ShipsInTransit.Count - 1 do
  begin
    Ship := TShip(ShipsInTransit[I]);
    if (Ship = Player) and ((ScenarioState = scenMachpellaFled) or (ScenarioState = scenPeaceRachekhanDestroyed)) then
    begin
      Count := Galaxy.Holes.Count;
      Hole := nil;
      J := 0;
      while J < Count do
      begin
        Hole := THole(Galaxy.Holes[J]);
        if Hole.HoleType = bhkMachpella then Break;
        Inc(J);
      end;
      if J < Count then
        if (Ship.OrderTarget is TStar) or (Ship.OrderTarget <> Hole) then
        begin
          Hole.HoleType := bhkUsed;
          if ScenarioState = scenMachpellaFled then ScenarioState := scenNone;
          KlingMotherShip.Hull.HullPoints := KlingMotherShip.Hull.Weight;
        end;
    end;
    if Ship.OrderTarget is TStar then Ship.TransferToStar(Ship.OrderTarget as TStar)
    else
    begin
      Hole := Ship.OrderTarget as THole;
      if Ship.OrderStateData shr BlackHoleDirectionShift = 0 then Ship.TransferToStar(Hole.Star2)
      else Ship.TransferToStar(Hole.Star1);
    end;
  end;
  ShipsInTransit.Clear;
end;
{ @end $5E7BB4 }

{ @routine $5E7D20 TGalaxy_RebuildAllStarDistances }
procedure TGalaxy.RebuildAllStarDistances;
var I, Count: Integer; Star: TStar;
begin
  Count := Stars.Count;
  for I := 0 to Count - 1 do begin
    Star := TStar(Stars[I]);
    Star.RebuildStarDistances;
  end;
end;
{ @end $5E7D20 }

{ @routine $5E7D4C TGalaxy_RefreshAllShipDerivedState }
procedure TGalaxy.RefreshAllShipDerivedState;
var I, J, Count: Integer; Star: TStar; Ship: TShip;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Ships.Count;
    for J := 0 to Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      Ship.RefreshDerivedStats;
      Ship.RefreshGraphicSize;
    end;
  end;
end;
{ @end $5E7D4C }

{ @routine $5E7DC4 TGalaxy_IdToConstellation }
function TGalaxy.IdToConstellation(Id: Cardinal): TObject;
var Item: TConstellation; I: Integer;
begin
  Result := nil;
  if Id = 0 then Exit;
  for I := 0 to Constellations.Count - 1 do begin
    Item := TConstellation(Constellations[I]);
    if Item.Id = Id then begin Result := Item; Exit; end;
  end;
  raise Exception.Create('Error');
end;
{ @end $5E7DC4 }

{ @routine $5E7E24 TGalaxy_IdToStar }
function TGalaxy.IdToStar(Id: Cardinal): TObject;
var Item: TStar; I, Count: Integer;
begin
  Result := nil;
  if Id = 0 then Exit;
  Count := Stars.Count;
  for I := 0 to Count - 1 do begin
    Item := TStar(Stars[I]);
    if Item.Id = Id then begin Result := Item; Exit; end;
  end;
  raise Exception.Create('Error');
end;
{ @end $5E7E24 }

{ @routine $5E7E80 TGalaxy_IdToHole }
function TGalaxy.IdToHole(Id: Cardinal): TObject;
var Item: THole; I, Count: Integer;
begin
  Result := nil;
  if Id = 0 then Exit;
  Count := Holes.Count;
  for I := 0 to Count - 1 do begin
    Item := THole(Holes[I]);
    if Item.Id = Id then begin Result := Item; Exit; end;
  end;
  raise Exception.Create('Error');
end;
{ @end $5E7E80 }

{ @routine $5E7EDC TGalaxy_IdToPlanet }
function TGalaxy.IdToPlanet(Id: Cardinal): TObject;
var Star: TStar; Planet: TPlanet; I, StarCount, J, PlanetCount: Integer;
begin
  Result := nil;
  if Id = 0 then Exit;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    PlanetCount := Star.Planets.Count;
    for J := 0 to PlanetCount - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Cardinal(Planet.Id) = Id then
      begin
        Result := Planet;
        Exit;
      end;
    end;
  end;
  raise Exception.Create('Error');
end;
{ @end $5E7EDC }

{ @routine $5E7F78 TGalaxy_IdToShip }
function TGalaxy.IdToShip(Id: Cardinal; RaiseIfMissing: Boolean): TObject;
var
  Star: TStar; Planet: TPlanet; Ship: TShip;
  I, StarCount, J, Count, K, ArtefactCount: Integer;
  Artefact: TArtefact;
begin
  Result := nil;
  if Id = 0 then Exit;
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Ships.Count;
    for J := 0 to Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if Cardinal(Ship.Id) = Id then
      begin
        Result := Ship;
        Exit;
      end;
      ArtefactCount := Ship.Artefacts.Count;
      for K := 0 to ArtefactCount - 1 do
      begin
        Artefact := TArtefact(Ship.Artefacts[K]);
        if (Artefact is TArtefactTranclucator) and
           (Cardinal(((Artefact as TArtefactTranclucator).Ship as TTranclucator).Id) = Id) then
        begin
          Result := (Artefact as TArtefactTranclucator).Ship;
          Exit;
        end;
      end;
    end;
    Count := Star.Planets.Count;
    for J := 0 to Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      ArtefactCount := Planet.Warriors.Count;
      for K := 0 to ArtefactCount - 1 do
      begin
        Ship := TShip(Planet.Warriors[K]);
        if Cardinal(Ship.Id) = Id then
        begin
          Result := Ship;
          Exit;
        end;
      end;
    end;
  end;
  if RaiseIfMissing then raise Exception.Create('Error')
  else Result := nil;
end;
{ @end $5E7F78 }

{ @routine $5E8148 TGalaxy_IdToItem }
function TGalaxy.IdToItem(Id: Integer): TObject;
var
  Star: TStar;
  Planet: TPlanet;
  I, J, K, Count: Integer;
  Ship: TShip;
begin
  Result := nil;
  if Id = 0 then Exit;
  for I := 0 to Stars.Count - 1 do begin
    Star := Stars[I];
    for J := 0 to Star.Items.Count - 1 do begin
      Result := Star.Items[J];
      if Id = TItem(Result).Id then Exit;
    end;
    for J := 0 to Star.MovingDropItems.Count - 1 do begin
      with PMovingDropItemEntry(Star.MovingDropItems[J])^ do begin
        if Id = (Payload as TItem).Id then begin
          Result := Payload;
          Exit;
        end;
      end;
    end;
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := Star.Ships[J];
      Result := Ship.FindCarriedItemById(Id);
      if Result <> nil then Exit;
      if (Ship.ShipType = t_Ranger) and (Ship is TPlayer) then
        for K := 0 to TPlayer(Ship).StorageEntries.Count - 1 do begin
          { Native bug: reads the storage record itself as TItem instead of
            dereferencing PStorageEntry.Item. }
          Result := TPlayer(Ship).StorageEntries[K];
          if Id = TItem(Result).Id then Exit;
        end;
    end;
    for J := 0 to Star.Planets.Count - 1 do begin
      Planet := Star.Planets[J];
      Count := Planet.Warriors.Count;
      for K := 0 to Count - 1 do begin
        Ship := Planet.Warriors[K];
        Result := Ship.FindCarriedItemById(Id);
        if Result <> nil then Exit;
      end;
      Count := Planet.EquipmentShop.Count;
      for K := 0 to Count - 1 do begin
        Result := Planet.EquipmentShop[K];
        if Id = TItem(Result).Id then Exit;
      end;
    end;
  end;
  if TemporaryShopSlots <> nil then
    for I := 0 to TemporaryShopSlots.Count - 1 do
      if Id = TShopSlot(TemporaryShopSlots[I]).Item.Id then begin
        Result := TShopSlot(TemporaryShopSlots[I]).Item;
        Exit;
      end;
  raise Exception.Create('Error');
end;
{ @end $5E8148 }

{ @routine $5E83FC TGalaxy_IdToAsteroid }
function TGalaxy.IdToAsteroid(Id: Cardinal): TObject;
var I, J, Count: Integer; Star: TStar; Asteroid: TAsteroid;
begin
  Result := nil;
  if Id = 0 then Exit;
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    Count := Star.Asteroids.Count;
    for J := 0 to Count - 1 do
    begin
      Asteroid := TAsteroid(Star.Asteroids[J]);
      if Id = Asteroid.Id then
      begin
        Result := Asteroid;
        Exit;
      end;
    end;
  end;
end;
{ @end $5E83FC }

{ @routine $5E8480 TGalaxy_ClearJumpGates }
procedure TGalaxy.ClearJumpGates;
var I: Integer; Gate: PJumpGateEntry;
begin
  for I := 0 to JumpGates.Count - 1 do
  begin
    Gate := JumpGates[I];
    if Gate.Gate <> nil then
    begin
      Gate.Gate.DetachFromSpace;
      Gate.Gate.Free;
      Gate.Gate := nil;
    end;
    FreeEC(Gate);
  end;
  JumpGates.Clear;
end;
{ @end $5E8480 }

{ @routine $5E84D8 TGalaxy_CreateJumpGate }
function TGalaxy.CreateJumpGate: PJumpGateEntry;
var Gate: PJumpGateEntry;
begin
  Gate := AllocClearEC(SizeOf(TJumpGateEntry));
  JumpGates.Add(Gate);
  Gate.UnresolvedFlag := False;
  Gate.Gate := TGateSE.Create('Gate', Classes.Point(0, 0));
  Result := Gate;
end;
{ @end $5E84D8 }

{ @routine $5E8534 TGalaxy_ReleaseItemGraphics }
procedure TGalaxy.ReleaseItemGraphics;
var Star: TStar; Ship: TShip; Item: TItem; StarCount, ShipCount, ItemCount, I, J, K: Integer;
begin
  StarCount := Stars.Count;
  for I := 0 to StarCount - 1 do
  begin
    Star := TStar(Stars[I]);
    ItemCount := Star.Items.Count;
    for K := 0 to ItemCount - 1 do
    begin
      Item := TItem(Star.Items[K]);
      if Item.GraphObject <> nil then begin Item.GraphObject.Free; Item.GraphObject := nil; end;
    end;
    ShipCount := Star.Ships.Count;
    for J := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      ItemCount := Ship.Inventory.Count;
      for K := 0 to ItemCount - 1 do
      begin
        Item := TItem(Ship.Inventory[K]);
        if Item.GraphObject <> nil then begin Item.GraphObject.Free; Item.GraphObject := nil; end;
      end;
      ItemCount := Ship.Artefacts.Count;
      for K := 0 to ItemCount - 1 do
      begin
        Item := TItem(Ship.Artefacts[K]);
        if Item.GraphObject <> nil then begin Item.GraphObject.Free; Item.GraphObject := nil; end;
      end;
    end;
  end;
end;
{ @end $5E8534 }

{ @routine $5E86C4 TGalaxy_GenerateSpaceBackground }
procedure TGalaxy.GenerateSpaceBackground;
var
  EntryIndex, Capacity: Integer;
  I, GroupCount, GroupSize, J, K, ImageKind: Integer;
  OrbitStep, Angle1, Angle2, Radius, Angle, DepthRange: Double;
  MinRadius, MaxRadius, StarRadius: Integer;
  RadiusFraction, Density: Single;
  LayerIndex, OffsetX, OffsetY, Quadrant: Integer;
  NearDepth, FarDepth, DepthScale: Single;
  Center: TVector3D;

  // @nested $5E8674 AdvanceEntry
  procedure AdvanceEntry; // @addr $005E8674
  begin
    Inc(EntryIndex);
    if EntryIndex + 1 > Capacity then
    begin
      Capacity := EntryIndex + 100;
      SetLength(SpaceBackgroundEntries, Capacity);
    end;
  end;

begin
  MinRadius := TStar(Galaxy.Stars[0]).MapDiameter;
  MaxRadius := MinRadius;
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    StarRadius := TStar(Galaxy.Stars[I]).MapDiameter;
    MinRadius := Min(MinRadius, StarRadius);
    MaxRadius := Max(MaxRadius, StarRadius);
  end;
  MinRadius := MinRadius div 2;
  MaxRadius := MaxRadius div 2;
  StarRadius := PlayerStar.MapDiameter div 2;
  // The native formula requires differing extrema.
  RadiusFraction := (PlayerStar.MapDiameter div 2 - MinRadius) / (MaxRadius - MinRadius);
  if SpaceImage <= 1 then Density := 0.5 else Density := 1;
  EntryIndex := 0;
  Capacity := 500;
  NearDepth := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 5.1, 7.1);
  FarDepth := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 7, 10);
  DepthScale := RemapClamped(PlayerStar.MapDiameter div 2, MinRadius, MaxRadius, 1, 1.5);
  SetLength(SpaceBackgroundEntries, Capacity);
  GroupCount := Round((RadiusFraction * 1 + 4) * Density);
  Quadrant := 0;
  for I := 0 to GroupCount - 1 do
  begin
    J := Round(RandomFloatRange(0, 1) * (StarRadius * 0.6));
    case Quadrant of
      0: begin
           Center.X := RandomFloatRange(0.1, 0.2) * StarRadius * (RandomIntRange(0, 1) * 2 - 1);
           Center.Y := RandomFloatRange(0.1, 0.2) * StarRadius * (RandomIntRange(0, 1) * 2 - 1);
           Quadrant := RandomIntRange(1, 4);
         end;
      1: begin
           Center.X := RandomFloatRange(0.6, 1.5) * StarRadius;
           Center.Y := -RandomFloatRange(0.6, 1.5) * StarRadius + J;
         end;
      2: begin
           Center.X := RandomFloatRange(0.6, 1.5) * StarRadius - J;
           Center.Y := RandomFloatRange(0.6, 1.5) * StarRadius;
         end;
      3: begin
           Center.X := -RandomFloatRange(0.6, 1.5) * StarRadius;
           Center.Y := RandomFloatRange(0.6, 1.5) * StarRadius - J;
         end;
      4: begin
           Center.X := -RandomFloatRange(0.6, 1.5) * StarRadius + J;
           Center.Y := -RandomFloatRange(0.6, 1.5) * StarRadius;
         end;
    end;
    IncrementWrapped(Quadrant, 1, 4);
    Center.Z := RandomFloatRange(0.9, 1.9);
    // Consumes these orbit draws even though this layer remains stationary.
    OrbitStep := RandomFloatRange(0.05, 0.1) * (RandomIntRange(0, 1) * 2 - 1);
    ImageKind := RandomIntRange(1, 5) * 100;
    LayerIndex := 0;
    for J := 0 to 5 do
    begin
      OffsetX := Round(RandomIntRange(-100, 100));
      OffsetY := Round(RandomIntRange(-100, 100));
      for K := 0 to 1 do
      begin
        Inc(LayerIndex);
        SpaceBackgroundEntries[EntryIndex].ImageIndex := SelectSpaceImageTemplate(ImageKind + 5 - J);
        SpaceBackgroundEntries[EntryIndex].OrbitCenter := Center;
        SpaceBackgroundEntries[EntryIndex].Position.X := RemapClamped(LayerIndex, 1, 8, 1, 5) * OffsetX * DepthScale + (Center.X + RandomIntRange(-100, 100));
        SpaceBackgroundEntries[EntryIndex].Position.Y := RemapClamped(LayerIndex, 1, 10, 1, 5) * OffsetY * DepthScale + (Center.Y + RandomIntRange(-100, 100));
        SpaceBackgroundEntries[EntryIndex].Position.Z := RemapClamped(LayerIndex, 1, 12, NearDepth, FarDepth);
        SpaceBackgroundEntries[EntryIndex].Unknown38 := MakeVector3D(0, 0, 0);
        SpaceBackgroundEntries[EntryIndex].OrbitStepDegrees := 0;
        SpaceBackgroundEntries[EntryIndex].FrameIndex := RandomIntRange(0, 2000000000);
        AdvanceEntry;
      end;
    end;
  end;
  GroupCount := Round((RadiusFraction * 2 + 4) * Density);
  for I := 0 to GroupCount - 1 do
  begin
    repeat
      J := Round(PlayerStar.MapDiameter * 0.8);
      Center.X := RandomIntRange(-J, J);
      Center.Y := RandomIntRange(-J, J);
      Center.Z := FarDepth + RandomFloatRange(2.05, 3) * DepthScale;
    until Center.X * Center.X + Center.Y * Center.Y > 25;
    DepthRange := RandomFloatRange(4, 10);
    OrbitStep := RandomFloatRange(0.05, 0.1) * (RandomIntRange(0, 1) * 2 - 1);
    Angle1 := HeadingDegreesToRadians(RandomIntRange(0, 360));
    Angle2 := HeadingDegreesToRadians(RandomIntRange(0, 360));
    GroupSize := RandomIntRange(1, 2);
    for J := 0 to GroupSize - 1 do
    begin
      SpaceBackgroundEntries[EntryIndex].Position.Z := Center.Z + RandomFloatRange(0, DepthRange);
      SpaceBackgroundEntries[EntryIndex].ImageIndex := SelectSpaceImageTemplate(1000 + 5 - Round((SpaceBackgroundEntries[EntryIndex].Position.Z - Center.Z) / DepthRange * 5));
      SpaceBackgroundEntries[EntryIndex].OrbitCenter := Center;
      if RandomIntRange(0, 2) = 0 then
      begin
        Radius := RandomIntRange(100, 250);
        Angle := Angle1 + RandomIntRange(-1, 1) * 3.1415926 / 180;
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + Sin(Angle) * Radius;
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y - Cos(Angle) * Radius;
      end
      else if RandomIntRange(0, 2) <> 0 then
      begin
        Radius := RandomIntRange(100, 250);
        Angle := Angle2 + RandomIntRange(-3, 3) * 3.1415926 / 180;
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + Sin(Angle) * Radius;
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y - Cos(Angle) * Radius;
      end
      else
      begin
        SpaceBackgroundEntries[EntryIndex].Position.X := Center.X + RandomIntRange(-100, 100);
        SpaceBackgroundEntries[EntryIndex].Position.Y := Center.Y + RandomIntRange(-100, 100);
      end;
      SpaceBackgroundEntries[EntryIndex].Unknown38 := MakeVector3D(0, 0, 0);
      SpaceBackgroundEntries[EntryIndex].OrbitStepDegrees := OrbitStep + RandomFloatRange(0.07, 0.1);
      SpaceBackgroundEntries[EntryIndex].FrameIndex := RandomIntRange(0, 2000000000);
      AdvanceEntry;
    end;
  end;
  SetLength(SpaceBackgroundEntries, EntryIndex);
end;
{ @end $5E86C4 }

{ @routine $5E98EC TGalaxy_XorProtectedState }
procedure TGalaxy.XorProtectedState(Seed: Integer);
var
  UnusedNativeFrame: array[0..3] of Byte;
  I, J, K, L: Integer; Star: TStar; Planet: TPlanet; Skill: TSkill; Good: TGoodsIndex; CargoGood: TGoodsIndex;
  Asteroid: TAsteroid; Ship: TShip; RangerQuest: PQuest; Quest: TQuestGameContent;
  Parameter: TQuestParameter; Location: TLocation; Change: TQuestParameterDelta; Path: TPath;

  // @nested $5E9360 NextStateXorMask
  function NextStateXorMask: Cardinal; // @addr $5E9360
  begin
    Seed := 16807 * (Seed mod 127773) - 2836 * (Seed div 127773);
    if Seed <= 0 then Inc(Seed, $7FFFFFFF);
    Result := Seed - 1;
  end;

  // @nested $5E93B4 XorStateUInt64
  procedure XorStateUInt64(var Value: Int64); // @addr $5E93B4
  var Data: PCardinal;
  begin
    Data := @Value;
    Data^ := Data^ xor NextStateXorMask;
    PCardinal(Cardinal(Data) + 4)^ := PCardinal(Cardinal(Data) + 4)^ xor NextStateXorMask;
  end;

  // @nested $5E93D8 XorStateUInt32
  procedure XorStateUInt32(var Value: Cardinal); // @addr $5E93D8
  begin Value := Value xor NextStateXorMask; end;

  // @nested $5E93F0 XorStateWord
  procedure XorStateWord(var Value: Word); // @addr $5E93F0
  begin Value := Value xor Word(NextStateXorMask); end;

  // @nested $5E9408 XorStateByte
  procedure XorStateByte(var Value: Byte); // @addr $5E9408
  begin Value := Value xor Byte(NextStateXorMask); end;

  // @nested $5E9420 XorStateWords
  procedure XorStateWords(Data: PWord; Count: Integer); // @addr $5E9420
  var I: Cardinal;
  begin
    I := 0;
    while I < Cardinal(Count) do begin
      Data^ := Data^ xor Word(NextStateXorMask);
      Data := Pointer(Cardinal(Data) + SizeOf(Data^));
      Inc(I);
    end;
  end;

  // @nested $5E9448 XorStateBytes
  procedure XorStateBytes(Data: PByte; Count: Integer); // @addr $5E9448
  var I: Cardinal;
  begin
    I := 0;
    while I < Cardinal(Count) do begin
      Data^ := Data^ xor Byte(NextStateXorMask);
      Data := Pointer(Cardinal(Data) + SizeOf(Data^));
      Inc(I);
    end;
  end;

  // @nested $5E9470 XorStateItem
  procedure XorStateItem(Item: TItem); // @addr $5E9470
  begin
    XorStateUInt32(PCardinal(@Item.Id)^);
    XorStateByte(PByte(@Item.ItemType)^);
    XorStateByte(PByte(@Item.OwnerId)^);
    XorStateUInt32(PCardinal(@Item.Cost)^);
    XorStateUInt32(PCardinal(@Item.Weight)^);
    if Item is TEquipment then
    begin
      XorStateByte(PByte(@(Item as TEquipment).EquippedFlag)^);
      // Native protects only the low dword of this Double.
      XorStateUInt32(PCardinal(@(Item as TEquipment).ConditionPercent)^);
      XorStateByte(PByte(@(Item as TEquipment).BrokenFlag)^);
    end;
    if Item is THull then
    begin
      XorStateUInt32(PCardinal(@(Item as THull).HullPoints)^);
      XorStateByte(PByte(@(Item as THull).TechLevel)^);
      XorStateByte(PByte(@(Item as THull).Armor)^);
    end
    else if Item is TFuelTanks then
    begin
      XorStateByte(PByte(@(Item as TFuelTanks).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TFuelTanks).Fuel)^);
      XorStateByte(PByte(@(Item as TFuelTanks).Capacity)^);
    end
    else if Item is TEngine then
    begin
      XorStateByte(PByte(@(Item as TEngine).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TEngine).Speed)^);
      XorStateByte(PByte(@(Item as TEngine).JumpRange)^);
      XorStateByte(PByte(@(Item as TEngine).OutputPercent)^);
    end
    else if Item is TRadar then
    begin
      XorStateByte(PByte(@(Item as TRadar).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TRadar).Range)^);
    end
    else if Item is TScaner then
    begin
      XorStateByte(PByte(@(Item as TScaner).TechLevel)^);
      XorStateByte(PByte(@(Item as TScaner).ScanPower)^);
    end
    else if Item is TRepairRobot then
    begin
      XorStateByte(PByte(@(Item as TRepairRobot).TechLevel)^);
      XorStateByte(PByte(@(Item as TRepairRobot).RepairPoints)^);
    end
    else if Item is TCargoHook then
    begin
      XorStateByte(PByte(@(Item as TCargoHook).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TCargoHook).PickupPower)^);
    end
    else if Item is TDefGenerator then
    begin
      XorStateByte(PByte(@(Item as TDefGenerator).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TDefGenerator).DamageFactor)^);
    end
    else if Item is TWeapon then
    begin
      XorStateByte(PByte(@(Item as TWeapon).TechLevel)^);
      XorStateUInt32(PCardinal(@(Item as TWeapon).Range)^);
      XorStateByte(PByte(@(Item as TWeapon).MinDamage)^);
      XorStateByte(PByte(@(Item as TWeapon).MaxDamage)^);
    end
    else if Item is TGoods then
    begin
      XorStateUInt32(PCardinal(@(Item as TGoods).Quantity)^);
    end
    else if Item is TProtoplasm then
    begin
      XorStateUInt32(PCardinal(@(Item as TProtoplasm).Quantity)^);
    end
    else if Item is TArtefactTransmitter then
    begin
      XorStateUInt32(PCardinal(@(Item as TArtefactTransmitter).Charges)^);
    end;
  end;
begin
  XorStateByte(PByte(@MoneyIntegrityFailed)^);
  XorStateUInt32(PCardinal(@LastCheatTurn)^);
  XorStateUInt32(PCardinal(@TotalCheatPoints)^);
  XorStateUInt32(PCardinal(@PendingEquipmentPurchasePrice)^);
  XorStateUInt32(PCardinal(@CurrentTurn)^);
  XorStateUInt32(PCardinal(@AverageRangerCapital)^);
  XorStateUInt32(PCardinal(@MaxRangerWealth)^);
  XorStateUInt32(PCardinal(@AverageRangerStrength)^);
  XorStateUInt32(PCardinal(@BestRangerStrength)^);
  XorStateUInt32(PCardinal(@CommunicatorResearchProgress)^);
  XorStateUInt32(PCardinal(@CommunicatorResearchPerDay)^);
  XorStateByte(PByte(@TechLevel)^);
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    XorStateUInt32(PCardinal(@Star.Id)^);
    XorStateUInt32(PCardinal(@Star.GenerationSeed)^);
    XorStateUInt32(PCardinal(@Star.DaysSincePlayerVisit)^);
    XorStateUInt32(PCardinal(@Star.DaysSinceLastNpcShipSpawn)^);
    XorStateByte(PByte(@Star.CombatOccurred)^);
    XorStateByte(PByte(@Star.PlayerCombatActive)^);
    XorStateByte(PByte(@Star.PlayerInteractionOccurred)^);
    XorStateByte(PByte(@Star.KlissanCaptureDays)^);
    for J := 0 to Star.Items.Count - 1 do
      XorStateItem(TItem(Star.Items[J]));
    if Assigned(Star.MovingDropItems) then
      for J := 0 to Star.MovingDropItems.Count - 1 do
        if PMovingDropItemEntry(Star.MovingDropItems[J]).Payload is TItem then
          XorStateItem(PMovingDropItemEntry(Star.MovingDropItems[J]).Payload as TItem);
    for J := 0 to Star.Asteroids.Count - 1 do begin
      Asteroid := TAsteroid(Star.Asteroids[J]);
      XorStateUInt32(PCardinal(@Asteroid.MineralCount)^);
    end;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      XorStateUInt32(PCardinal(@Planet.Id)^);
      XorStateUInt32(PCardinal(@Planet.GenerationSeed)^);
      XorStateUInt32(PCardinal(@Planet.ReservedSaveValue)^);
      XorStateUInt32(PCardinal(@Planet.Radius)^);
      XorStateUInt32(PCardinal(@Planet.Population)^);
      XorStateByte(PByte(@Planet.Economy)^);
      XorStateUInt32(PCardinal(@Planet.Money)^);
      XorStateByte(PByte(@Planet.IsCoalitionOwned)^);
      XorStateByte(PByte(@Planet.RaceId)^);
      XorStateByte(PByte(@Planet.Government)^);
      XorStateByte(PByte(@Planet.OwnerId)^);
      for Good := t_Food to t_Narcotics do
      begin
        XorStateUInt32(PCardinal(@Planet.Goods[Good].Count)^);
        XorStateUInt32(PCardinal(@Planet.Goods[Good].PriceState)^);
        XorStateUInt32(PCardinal(@Planet.Goods[Good].PurchasePrice)^);
        XorStateUInt32(PCardinal(@Planet.Goods[Good].BaseSalePrice)^);
      end;
      for K := 0 to Planet.EquipmentShop.Count - 1 do
        XorStateItem(TItem(Planet.EquipmentShop[K]));
    end;
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      XorStateUInt32(PCardinal(@Ship.Id)^);
      XorStateUInt32(PCardinal(@Ship.Seed)^);
      XorStateByte(PByte(@Ship.ShipType)^);
      XorStateByte(PByte(@Ship.OwnerId)^);
      for CargoGood := t_Food to t_Narcotics do
      begin
        XorStateUInt32(PCardinal(@Ship.CargoGoods[CargoGood].Count)^);
        XorStateUInt32(PCardinal(@Ship.CargoGoods[CargoGood].TotalCost)^);
      end;
      XorStateUInt32(PCardinal(@Ship.Money)^);
      // The checksum skips the XOR-encoded money.
      XorStateUInt32(PCardinal(@Ship.EncodedMoney)^);
      XorStateUInt32(PCardinal(@Ship.Wealth)^);
      XorStateUInt32(PCardinal(@Ship.WealthInBestRanger)^);
      XorStateUInt32(PCardinal(@Ship.Strength)^);
      XorStateUInt32(PCardinal(@Ship.StrengthInBestRanger)^);
      XorStateUInt32(PCardinal(@Ship.StrengthInAverageRanger)^);
      XorStateUInt32(PCardinal(@Ship.Speed)^);
      XorStateByte(PByte(@Ship.JumpRange)^);
      // Native protects only the low dword of this Double.
      XorStateUInt32(PCardinal(@Ship.DefenseDamageFactor)^);
      XorStateUInt32(PCardinal(@Ship.CargoFreeSpace)^);
      XorStateUInt32(PCardinal(@Ship.CreationTurn)^);
      for Skill := skAccuracy to skLeadership do
        XorStateByte(PByte(@Ship.BaseSkills[Skill])^);
      XorStateUInt32(PCardinal(@Ship.NodeReserve)^);
      XorStateUInt32(PCardinal(@Ship.TotalExperience)^);
      XorStateUInt32(PCardinal(@Ship.FreeExperience)^);
      XorStateUInt32(PCardinal(@Ship.DaysSincePlayerSeen)^);
      XorStateByte(PByte(@Ship.InFear)^);
      for K := 0 to Ship.Inventory.Count - 1 do
        XorStateItem(TItem(Ship.Inventory[K]));
      for K := 0 to Ship.Artefacts.Count - 1 do
        XorStateItem(TItem(Ship.Artefacts[K]));
      XorStateUInt32(PCardinal(@Ship.PartnershipDaysRemaining)^);
      XorStateByte(PByte(@Ship.Order)^);
      XorStateUInt32(PCardinal(@Ship.OrderStateData)^);
      XorStateByte(PByte(@Ship.DestroyKind)^);
      if Ship is TNormalShip then
      begin
        XorStateWord(PWord(@(Ship as TNormalShip).ScriptStatistics[ssShipsKilled])^);
        XorStateWord(PWord(@(Ship as TNormalShip).ScriptStatistics[ssPiratesKilled])^);
        XorStateWord(PWord(@(Ship as TNormalShip).ScriptStatistics[ssKlissansKilled])^);
        XorStateWord(PWord(@(Ship as TNormalShip).ScriptStatistics[ssSystemsLiberated])^);
        XorStateWord(PWord(@(Ship as TNormalShip).CurrentSystemKillCount)^);
        XorStateByte(PByte(@(Ship as TNormalShip).Rank)^);
        XorStateWord(PWord(@(Ship as TNormalShip).RankPoints)^);
      end;
      if Ship is TRuins then
      begin
        XorStateByte(PByte(@(Ship as TRuins).StationFlags)^);
        for K := 0 to (Ship as TRuins).EquipmentShop.Count - 1 do
          XorStateItem(TItem((Ship as TRuins).EquipmentShop[K]));
        for Good := t_Food to t_Narcotics do
        begin
          XorStateUInt32(PCardinal(@(Ship as TRuins).Goods[Good].Count)^);
          XorStateUInt32(PCardinal(@(Ship as TRuins).Goods[Good].PriceState)^);
          XorStateUInt32(PCardinal(@(Ship as TRuins).Goods[Good].PurchasePrice)^);
          XorStateUInt32(PCardinal(@(Ship as TRuins).Goods[Good].BaseSalePrice)^);
        end;
      end;
      if Ship is TRanger then
      begin
        XorStateWord(PWord(@(Ship as TRanger).PlaceInRating)^);
        XorStateByte(PByte(@(Ship as TRanger).CareerStatus[rcTrader])^);
        XorStateByte(PByte(@(Ship as TRanger).CareerStatus[rcPirate])^);
        XorStateByte(PByte(@(Ship as TRanger).CareerStatus[rcWarrior])^);
        XorStateByte(PByte(@(Ship as TRanger).EminentProgress[rcTrader])^);
        XorStateByte(PByte(@(Ship as TRanger).EminentProgress[rcPirate])^);
        XorStateByte(PByte(@(Ship as TRanger).EminentProgress[rcWarrior])^);
        XorStateByte(PByte(@(Ship as TRanger).PendingCareerActivity[rcTrader])^);
        XorStateByte(PByte(@(Ship as TRanger).PendingCareerActivity[rcPirate])^);
        XorStateByte(PByte(@(Ship as TRanger).PendingCareerActivity[rcWarrior])^);
        XorStateByte(PByte(@(Ship as TRanger).PreferredCareer)^);
        XorStateByte(PByte(@(Ship as TRanger).Aggression)^);
        XorStateByte(PByte(@(Ship as TRanger).PrisonTermRemaining)^);
        if (Ship as TRanger).Quests <> nil then
          for K := 0 to (Ship as TRanger).Quests.Count - 1 do
          begin
            RangerQuest := PQuest((Ship as TRanger).Quests[K]);
            if RangerQuest <> nil then
            begin
              XorStateUInt32(PCardinal(@RangerQuest.DeadlineTurn)^);
              XorStateUInt32(PCardinal(@RangerQuest.RewardMoney)^);
            end;
          end;
      end;
      if Ship is TPlayer then
      begin
        XorStateByte(PByte(@(Ship as TPlayer).InPrison)^);
        XorStateByte(PByte(@(Ship as TPlayer).HaveCommunicator)^);
        XorStateByte(PByte(@(Ship as TPlayer).HaveHyperspaceLocator)^);
        XorStateUInt32(PCardinal(@(Ship as TPlayer).UnresolvedCounter1F4)^);
        XorStateUInt32(PCardinal(@(Ship as TPlayer).HyperspaceKillCount)^);
        XorStateUInt32(PCardinal(@(Ship as TPlayer).BlackHoleKillCount)^);
      end;
    end;
  end;
  if (Player <> nil) and (Player.IsOnPlanet or Player.IsDockedToShip) and (TemporaryShopSlots <> nil) then
    for I := 0 to TemporaryShopSlots.Count - 1 do
      if TShopSlot(TemporaryShopSlots[I]).Item <> nil then
        XorStateItem(TShopSlot(TemporaryShopSlots[I]).Item);
  if Player <> nil then
    if Player.IsOnPlanet and (CurrentScreenId = screenPlanetQuest) then
    begin
      for I := 0 to 50 do
        XorStateUInt32(PCardinal(@PlanetQuestScreen.ChoicePathIndexes[I])^);
      for I := 0 to 50 do
        XorStateByte(PByte(@PlanetQuestScreen.ChoiceEnabled[I])^);
      for I := 1 to 48 do
        XorStateUInt32(PCardinal(@PlanetQuestScreen.ParameterValues[I])^);
      for I := 1 to 48 do
        XorStateUInt32(PCardinal(@PlanetQuestScreen.PreviousParameterValues[I])^);
      for I := 1 to 48 do
        XorStateByte(PByte(@PlanetQuestScreen.ParameterVisible[I])^);
      XorStateUInt32(PCardinal(@PlanetQuestScreen.MoneyLimitComplement)^);
      XorStateByte(PByte(@PlanetQuestScreen.PlayerDied)^);
      XorStateUInt32(PCardinal(@PlanetQuestScreen.DaysElapsed)^);
      XorStateUInt32(PCardinal(@PlanetQuestScreen.CurrentLocationId)^);
      XorStateByte(PByte(@PlanetQuestScreen.ShowingPathTransition)^);
      XorStateUInt32(PCardinal(@PlanetQuestScreen.CriticalParameterIndex)^);
      XorStateUInt32(PCardinal(@PlanetQuestScreen.LastPathIndex)^);
      Quest := PlanetQuestScreen.Quest;
      if Quest <> nil then
      begin
        XorStateWords(PWord(PWideChar(Quest.QuestDescriptionText.Text)), Length(Quest.QuestDescriptionText.Text));
        XorStateWords(PWord(PWideChar(Quest.QuestSuccessGovMessageText.Text)), Length(Quest.QuestSuccessGovMessageText.Text));
        XorStateWords(PWord(PWideChar(Quest.UnresolvedText110.Text)), Length(Quest.UnresolvedText110.Text));
        XorStateWords(PWord(PWideChar(Quest.ToStarText.Text)), Length(Quest.ToStarText.Text));
        XorStateWords(PWord(PWideChar(Quest.UnresolvedText11C.Text)), Length(Quest.UnresolvedText11C.Text));
        XorStateWords(PWord(PWideChar(Quest.UnresolvedText120.Text)), Length(Quest.UnresolvedText120.Text));
        XorStateWords(PWord(PWideChar(Quest.ToPlanetText.Text)), Length(Quest.ToPlanetText.Text));
        XorStateWords(PWord(PWideChar(Quest.DateText.Text)), Length(Quest.DateText.Text));
        XorStateWords(PWord(PWideChar(Quest.MoneyText.Text)), Length(Quest.MoneyText.Text));
        XorStateWords(PWord(PWideChar(Quest.FromPlanetText.Text)), Length(Quest.FromPlanetText.Text));
        XorStateWords(PWord(PWideChar(Quest.FromStarText.Text)), Length(Quest.FromStarText.Text));
        XorStateWords(PWord(PWideChar(Quest.RangerText.Text)), Length(Quest.RangerText.Text));
        XorStateUInt32(PCardinal(@Quest.UnresolvedValue14C)^);
        XorStateUInt32(PCardinal(@Quest.UnresolvedValue114)^);
        XorStateUInt32(PCardinal(@Quest.UnresolvedValue44)^);
        for J := 1 to 48 do
        begin
          Parameter := Quest.Parameters[J];
          XorStateWords(PWord(PWideChar(Parameter.NameText.Text)), Length(Parameter.NameText.Text));
          XorStateWords(PWord(PWideChar(Parameter.ValueText.Text)), Length(Parameter.ValueText.Text));
          XorStateWords(PWord(PWideChar(Parameter.CriticalText.Text)), Length(Parameter.CriticalText.Text));
          for K := 1 to 10 do
          begin
            XorStateUInt32(PCardinal(@Parameter.ViewStrings[K].MinValue)^);
            XorStateUInt32(PCardinal(@Parameter.ViewStrings[K].MaxValue)^);
            XorStateWords(PWord(PWideChar(Parameter.ViewStrings[K].Text.Text)), Length(Parameter.ViewStrings[K].Text.Text));
          end;
          for K := 0 to High(Parameter.InitialValues.Values) do
            XorStateUInt32(PCardinal(@Parameter.InitialValues.Values[K])^);
          for K := 0 to High(Parameter.InitialRange.RangeStarts) do
            XorStateUInt64(PInt64(@Parameter.InitialRange.RangeStarts[K])^);
          for K := 0 to High(Parameter.InitialRange.RangeEnds) do
            XorStateUInt64(PInt64(@Parameter.InitialRange.RangeEnds[K])^);
          XorStateUInt32(PCardinal(@Parameter.MinValue)^);
          XorStateUInt32(PCardinal(@Parameter.MaxValue)^);
          XorStateUInt32(PCardinal(@Parameter.Value)^);
          XorStateUInt32(PCardinal(@Parameter.CriticalOutcome)^);
          XorStateByte(PByte(@Parameter.Hidden)^);
          XorStateByte(PByte(@Parameter.ShowWhenZero)^);
          XorStateByte(PByte(@Parameter.CriticalAtMinimum)^);
          XorStateByte(PByte(@Parameter.Enabled)^);
          XorStateByte(PByte(@Parameter.IsMoney)^);
          XorStateUInt32(PCardinal(@Parameter.ViewStringCount)^);
        end;
        for J := 1 to High(Quest.Locations) do
        begin
          Location := Quest.Locations[J];
          XorStateWords(PWord(PWideChar(Location.UnresolvedText14.Text)), Length(Location.UnresolvedText14.Text));
          XorStateWords(PWord(PWideChar(Location.SelectedEventText.Text)), Length(Location.SelectedEventText.Text));
          XorStateWords(PWord(PWideChar(Location.EventExpression.Text)), Length(Location.EventExpression.Text));
          for K := 1 to 10 do
            XorStateWords(PWord(PWideChar(Location.EventTexts[K].Text)), Length(Location.EventTexts[K].Text));
          XorStateUInt32(PCardinal(@Location.Days)^);
          XorStateUInt32(PCardinal(@Location.Id)^);
          XorStateByte(PByte(@Location.UseEventExpression)^);
          XorStateUInt32(PCardinal(@Location.NextEventIndex)^);
          XorStateByte(PByte(@Location.IsEmpty)^);
          XorStateByte(PByte(@Location.UnresolvedFlag51)^);
          XorStateByte(PByte(@Location.UnresolvedFlag52)^);
          XorStateByte(PByte(@Location.IsDeath)^);
          XorStateByte(PByte(@Location.UnresolvedFlag115)^);
          XorStateByte(PByte(@Location.IsStart)^);
          XorStateByte(PByte(@Location.IsSuccess)^);
          XorStateByte(PByte(@Location.IsFailure)^);
          for K := 1 to 48 do
          begin
            Change := Location.ParameterChanges[K];
            XorStateWords(PWord(PWideChar(Change.ExpressionText.Text)), Length(Change.ExpressionText.Text));
            XorStateWords(PWord(PWideChar(Change.CriticalText.Text)), Length(Change.CriticalText.Text));
            for L := 0 to High(Change.ValueConstraint.Values) do
              XorStateUInt32(PCardinal(@Change.ValueConstraint.Values[L])^);
            for L := 0 to High(Change.MultipleConstraint.Values) do
              XorStateUInt32(PCardinal(@Change.MultipleConstraint.Values[L])^);
            XorStateUInt32(PCardinal(@Change.RequiredBits)^);
            XorStateUInt32(PCardinal(@Change.MinValue)^);
            XorStateUInt32(PCardinal(@Change.MaxValue)^);
            XorStateUInt32(PCardinal(@Change.ChangeValue)^);
            XorStateByte(PByte(@Change.ChangeByPercent)^);
            XorStateByte(PByte(@Change.SetValue)^);
            XorStateByte(PByte(@Change.UseExpression)^);
            XorStateUInt32(PCardinal(@Change.VisibilityChange)^);
            XorStateByte(PByte(@Change.LegacyFlag)^);
          end;
        end;
        for J := 1 to High(Quest.Paths) do
        begin
          Path := Quest.Paths[J];
          XorStateWords(PWord(PWideChar(Path.ChoiceText.Text)), Length(Path.ChoiceText.Text));
          XorStateWords(PWord(PWideChar(Path.TransitionText.Text)), Length(Path.TransitionText.Text));
          XorStateWords(PWord(PWideChar(Path.ConditionExpression.Text)), Length(Path.ConditionExpression.Text));
          XorStateUInt64(PInt64(@Path.Priority)^);
          XorStateByte(PByte(@Path.IsAutomatic)^);
          XorStateByte(PByte(@Path.AlwaysShow)^);
          XorStateUInt32(PCardinal(@Path.UnresolvedValue14)^);
          XorStateUInt32(PCardinal(@Path.DisplayOrder)^);
          XorStateUInt32(PCardinal(@Path.Id)^);
          XorStateUInt32(PCardinal(@Path.TraversalLimit)^);
          XorStateUInt32(PCardinal(@Path.FromLocationId)^);
          XorStateUInt32(PCardinal(@Path.ToLocationId)^);
          for K := 1 to 48 do
          begin
            Change := Path.ParameterChanges[K];
            XorStateWords(PWord(PWideChar(Change.ExpressionText.Text)), Length(Change.ExpressionText.Text));
            XorStateWords(PWord(PWideChar(Change.CriticalText.Text)), Length(Change.CriticalText.Text));
            for L := 0 to High(Change.ValueConstraint.Values) do
              XorStateUInt32(PCardinal(@Change.ValueConstraint.Values[L])^);
            for L := 0 to High(Change.MultipleConstraint.Values) do
              XorStateUInt32(PCardinal(@Change.MultipleConstraint.Values[L])^);
            XorStateUInt32(PCardinal(@Change.RequiredBits)^);
            XorStateUInt32(PCardinal(@Change.MinValue)^);
            XorStateUInt32(PCardinal(@Change.MaxValue)^);
            XorStateUInt32(PCardinal(@Change.ChangeValue)^);
            XorStateByte(PByte(@Change.ChangeByPercent)^);
            XorStateByte(PByte(@Change.SetValue)^);
            XorStateByte(PByte(@Change.UseExpression)^);
            XorStateUInt32(PCardinal(@Change.VisibilityChange)^);
            XorStateByte(PByte(@Change.LegacyFlag)^);
          end;
        end;
      end;
    end;
  if (CurrentScreenId = screenArcadeBattle) and (PlayerArcadeShip <> nil) then
  begin
    XorStateUInt32(PCardinal(@PlayerArcadeShip.Health)^);
    XorStateUInt32(PCardinal(@PlayerArcadeShip.MaxHealth)^);
    for I := 0 to 4 do
    begin
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].Ammo)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].MaxAmmo)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].RechargePerTick)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].AmmoCost)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].LastFireTick)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].FireIntervalTicks)^);
      XorStateUInt32(PCardinal(@PlayerArcadeShip.Weapons[I].Damage)^);
    end;
  end;
  if CurrentScreenId = screenShip then
  begin
    XorStateUInt32(PCardinal(@ShipScreen.SelectedHoldKind)^);
    XorStateByte(PByte(@ShipScreen.SelectedGoodsIndex)^);
    XorStateUInt32(PCardinal(@ShipScreen.SelectedGoodsQuantity)^);
    XorStateUInt32(PCardinal(@ShipScreen.SelectedGoodsCost)^);
    if ShipScreen.SelectedHoldKind in [2, 3] then
      if ShipScreen.SelectedHoldItem <> nil then
        XorStateItem(ShipScreen.SelectedHoldItem);
  end;
  XorStateUInt32(PCardinal(@GovernmentScreen.QuestOffer.DeadlineTurn)^);
  XorStateUInt32(PCardinal(@GovernmentScreen.QuestOffer.RewardMoney)^);
  XorStateUInt32(PCardinal(@GovernmentScreen.QuestNegotiationLevel)^);
  XorStateUInt32(PCardinal(@GovernmentScreen.QuestRewardStep)^);
  XorStateUInt32(PCardinal(@GovernmentScreen.QuestDurationStep)^);
  if PlayerArcadeShip <> nil then
  begin
    XorStateUInt32(PCardinal(@PlayerArcadeShip.Health)^);
    XorStateUInt32(PCardinal(@PlayerArcadeShip.MaxHealth)^);
  end;
  XorStateBytes(@IntegrityDataBegin, Cardinal(@IntegrityDataEnd) - Cardinal(@IntegrityDataBegin));
end;
{ @end $5E98EC }

{ @routine $5EAF74 TGalaxy_ProtectState }
procedure TGalaxy.ProtectState;
begin
  if ProtectedStateXorSeed = 0 then begin
    while True do begin
      ProtectedStateXorSeed := RandomIntRange(0, 2000000000);
      if ProtectedStateXorSeed <> 0 then Break;
    end;
    XorProtectedState(ProtectedStateXorSeed);
  end;
end;
{ @end $5EAF74 }

{ @routine $5EAFAC TGalaxy_RestoreProtectedState }
procedure TGalaxy.RestoreProtectedState;
begin
  if ProtectedStateXorSeed <> 0 then begin
    XorProtectedState(ProtectedStateXorSeed);
    ProtectedStateXorSeed := 0;
  end;
end;
{ @end $5EAFAC }

{ @routine $5EB564 TGalaxy_ComputeIntegrityChecksum }
function TGalaxy.ComputeIntegrityChecksum: Cardinal;
var
  State: Cardinal;
  I, J, K, L: Integer; Star: TStar; Planet: TPlanet; Skill: TSkill; Good: TGoodsIndex; CargoGood: TGoodsIndex;
  Asteroid: TAsteroid; Ship: TShip; RangerQuest: PQuest; Quest: TQuestGameContent;
  Parameter: TQuestParameter; Location: TLocation; Change: TQuestParameterDelta; Path: TPath;

  // @nested $5EAFCC AccumulateIntegrityUInt32
  procedure AccumulateIntegrityUInt32(Value: Cardinal); // @addr $5EAFCC
  begin
    State := UpdateCrc32(State, @Value, 4);
  end;

  // @nested $5EAFF0 AccumulateIntegrityInt64
  procedure AccumulateIntegrityInt64(Value: Int64); // @addr $5EAFF0 @calls "0x005EC49A 0x005EC4C9"
  begin
    State := UpdateCrc32(State, @Value, 8);
  end;

  // @nested $5EB010 AccumulateIntegritySingle
  procedure AccumulateIntegritySingle(Value: Single); // @addr $5EB010 @calls "0x005EB150 0x005EB449 0x005EB5D6 0x005EB5E3 0x005EB5F3 0x005EB603 0x005EB85A 0x005EB94E 0x005EB958 0x005EB962 0x005EB96F 0x005EB99F 0x005EBC30"
  begin
    State := UpdateCrc32(State, @Value, 4);
  end;

  // @nested $5EB030 AccumulateIntegrityDouble
  procedure AccumulateIntegrityDouble(Value: Double); // @addr $5EB030 @calls "0x005EC87F"
  begin
    State := UpdateCrc32(State, @Value, 8);
  end;

  // @nested $5EB050 AccumulateIntegrityByte
  procedure AccumulateIntegrityByte(Value: Byte); // @addr $5EB050
  begin
    State := UpdateCrc32(State, @Value, 1);
  end;

  // @nested $5EB074 AccumulateIntegrityWords
  procedure AccumulateIntegrityWords(Data: PWord; Count: Integer); // @addr $5EB074
  begin
    State := UpdateCrc32(State, Data, Count * 2);
  end;

  // @nested $5EB098 AccumulateIntegrityBytes
  procedure AccumulateIntegrityBytes(Data: PByte; Count: Integer); // @addr $5EB098
  begin
    State := UpdateCrc32(State, Data, Count);
  end;

  // @nested $5EB0BC AccumulateIntegrityItem
  procedure AccumulateIntegrityItem(Item: TItem); // @addr $5EB0BC
  begin
    AccumulateIntegrityUInt32(Item.Id);
    AccumulateIntegrityUInt32(Ord(Item.ItemType));
    AccumulateIntegrityUInt32(Ord(Item.OwnerId));
    AccumulateIntegrityUInt32(Item.Cost);
    AccumulateIntegrityUInt32(Item.Weight);
    if Item is TEquipment then
    begin
      AccumulateIntegrityByte(Byte((Item as TEquipment).EquippedFlag));
      AccumulateIntegritySingle((Item as TEquipment).ConditionPercent);
      AccumulateIntegrityByte(Byte((Item as TEquipment).BrokenFlag));
    end;
    if Item is THull then
    begin
      AccumulateIntegrityUInt32((Item as THull).HullPoints);
      AccumulateIntegrityUInt32((Item as THull).TechLevel);
      AccumulateIntegrityUInt32((Item as THull).Armor);
    end
    else if Item is TFuelTanks then
    begin
      AccumulateIntegrityUInt32((Item as TFuelTanks).TechLevel);
      AccumulateIntegrityUInt32((Item as TFuelTanks).Fuel);
      AccumulateIntegrityUInt32((Item as TFuelTanks).Capacity);
    end
    else if Item is TEngine then
    begin
      AccumulateIntegrityUInt32((Item as TEngine).TechLevel);
      AccumulateIntegrityUInt32((Item as TEngine).Speed);
      AccumulateIntegrityUInt32((Item as TEngine).JumpRange);
      AccumulateIntegrityUInt32((Item as TEngine).OutputPercent);
    end
    else if Item is TRadar then
    begin
      AccumulateIntegrityUInt32((Item as TRadar).TechLevel);
      AccumulateIntegrityUInt32((Item as TRadar).Range);
    end
    else if Item is TScaner then
    begin
      AccumulateIntegrityUInt32((Item as TScaner).TechLevel);
      AccumulateIntegrityUInt32((Item as TScaner).ScanPower);
    end
    else if Item is TRepairRobot then
    begin
      AccumulateIntegrityUInt32((Item as TRepairRobot).TechLevel);
      AccumulateIntegrityUInt32((Item as TRepairRobot).RepairPoints);
    end
    else if Item is TCargoHook then
    begin
      AccumulateIntegrityUInt32((Item as TCargoHook).TechLevel);
      AccumulateIntegrityUInt32((Item as TCargoHook).PickupPower);
    end
    else if Item is TDefGenerator then
    begin
      AccumulateIntegrityUInt32((Item as TDefGenerator).TechLevel);
      AccumulateIntegritySingle((Item as TDefGenerator).DamageFactor);
    end
    else if Item is TWeapon then
    begin
      AccumulateIntegrityUInt32((Item as TWeapon).TechLevel);
      AccumulateIntegrityUInt32((Item as TWeapon).Range);
      AccumulateIntegrityUInt32((Item as TWeapon).MinDamage);
      AccumulateIntegrityUInt32((Item as TWeapon).MaxDamage);
    end
    else if Item is TGoods then
    begin
      AccumulateIntegrityUInt32((Item as TGoods).Quantity);
    end
    else if Item is TProtoplasm then
    begin
      AccumulateIntegrityUInt32((Item as TProtoplasm).Quantity);
    end
    else if Item is TArtefactTransmitter then
    begin
      AccumulateIntegrityUInt32((Item as TArtefactTransmitter).Charges);
    end;
  end;
begin
  State := InitCrc32;
  AccumulateIntegrityUInt32(LastCheatTurn);
  AccumulateIntegrityUInt32(TotalCheatPoints);
  AccumulateIntegrityUInt32(PendingEquipmentPurchasePrice);
  AccumulateIntegrityUInt32(CurrentTurn);
  AccumulateIntegrityUInt32(AverageRangerCapital);
  AccumulateIntegrityUInt32(MaxRangerWealth);
  AccumulateIntegritySingle(AverageRangerStrength);
  AccumulateIntegritySingle(BestRangerStrength);
  AccumulateIntegritySingle(CommunicatorResearchProgress);
  AccumulateIntegritySingle(CommunicatorResearchPerDay);
  AccumulateIntegrityUInt32(TechLevel);
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TStar(Stars[I]);
    AccumulateIntegrityUInt32(Star.Id);
    AccumulateIntegrityUInt32(Star.GenerationSeed);
    AccumulateIntegrityUInt32(Star.DaysSincePlayerVisit);
    AccumulateIntegrityUInt32(Star.DaysSinceLastNpcShipSpawn);
    AccumulateIntegrityByte(Byte(Star.CombatOccurred));
    AccumulateIntegrityByte(Byte(Star.PlayerCombatActive));
    AccumulateIntegrityByte(Byte(Star.PlayerInteractionOccurred));
    AccumulateIntegrityUInt32(Star.KlissanCaptureDays);
    for J := 0 to Star.Items.Count - 1 do
      AccumulateIntegrityItem(TItem(Star.Items[J]));
    if Assigned(Star.MovingDropItems) then
      for J := 0 to Star.MovingDropItems.Count - 1 do
        if PMovingDropItemEntry(Star.MovingDropItems[J]).Payload is TItem then
          AccumulateIntegrityItem(PMovingDropItemEntry(Star.MovingDropItems[J]).Payload as TItem);
    for J := 0 to Star.Asteroids.Count - 1 do begin
      Asteroid := TAsteroid(Star.Asteroids[J]);
      AccumulateIntegrityUInt32(Asteroid.MineralCount);
    end;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      AccumulateIntegrityUInt32(Planet.Id);
      AccumulateIntegrityUInt32(Planet.GenerationSeed);
      AccumulateIntegrityUInt32(Planet.ReservedSaveValue);
      AccumulateIntegrityUInt32(Planet.Radius);
      AccumulateIntegrityUInt32(Planet.Population);
      AccumulateIntegrityUInt32(Ord(Planet.Economy));
      AccumulateIntegrityUInt32(Planet.Money);
      AccumulateIntegrityByte(Byte(Planet.IsCoalitionOwned));
      AccumulateIntegrityUInt32(Ord(Planet.RaceId));
      AccumulateIntegrityUInt32(Ord(Planet.Government));
      AccumulateIntegrityUInt32(Ord(Planet.OwnerId));
      for Good := t_Food to t_Narcotics do
      begin
        AccumulateIntegrityUInt32(Planet.Goods[Good].Count);
        AccumulateIntegritySingle(Planet.Goods[Good].PriceState);
        AccumulateIntegrityUInt32(Planet.Goods[Good].PurchasePrice);
        AccumulateIntegrityUInt32(Planet.Goods[Good].BaseSalePrice);
      end;
      for K := 0 to Planet.EquipmentShop.Count - 1 do
        AccumulateIntegrityItem(TItem(Planet.EquipmentShop[K]));
    end;
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      AccumulateIntegrityUInt32(Ship.Id);
      AccumulateIntegrityUInt32(Ship.Seed);
      AccumulateIntegrityUInt32(Ord(Ship.ShipType));
      AccumulateIntegrityUInt32(Ord(Ship.OwnerId));
      for CargoGood := t_Food to t_Narcotics do
      begin
        AccumulateIntegrityUInt32(Ship.CargoGoods[CargoGood].Count);
        AccumulateIntegrityUInt32(Ship.CargoGoods[CargoGood].TotalCost);
      end;
      AccumulateIntegrityUInt32(Ship.Money);
      AccumulateIntegrityUInt32(Ship.Wealth);
      AccumulateIntegritySingle(Ship.WealthInBestRanger);
      AccumulateIntegritySingle(Ship.Strength);
      AccumulateIntegritySingle(Ship.StrengthInBestRanger);
      AccumulateIntegritySingle(Ship.StrengthInAverageRanger);
      AccumulateIntegrityUInt32(Ship.Speed);
      AccumulateIntegrityUInt32(Ship.JumpRange);
      AccumulateIntegritySingle(Ship.DefenseDamageFactor);
      AccumulateIntegrityUInt32(Ship.CargoFreeSpace);
      AccumulateIntegrityUInt32(Ship.CreationTurn);
      for Skill := skAccuracy to skLeadership do
        AccumulateIntegrityUInt32(Ship.BaseSkills[Skill]);
      AccumulateIntegrityUInt32(Ship.NodeReserve);
      AccumulateIntegrityUInt32(Ship.TotalExperience);
      AccumulateIntegrityUInt32(Ship.FreeExperience);
      AccumulateIntegrityUInt32(Ship.DaysSincePlayerSeen);
      AccumulateIntegrityByte(Byte(Ship.InFear));
      for K := 0 to Ship.Inventory.Count - 1 do
        AccumulateIntegrityItem(TItem(Ship.Inventory[K]));
      for K := 0 to Ship.Artefacts.Count - 1 do
        AccumulateIntegrityItem(TItem(Ship.Artefacts[K]));
      AccumulateIntegrityUInt32(Ship.PartnershipDaysRemaining);
      AccumulateIntegrityUInt32(Ord(Ship.Order));
      AccumulateIntegrityUInt32(Ship.OrderStateData);
      AccumulateIntegrityByte(Byte(Ship.DestroyKind));
      if Ship is TNormalShip then
      begin
        AccumulateIntegrityUInt32((Ship as TNormalShip).ScriptStatistics[ssShipsKilled]);
        AccumulateIntegrityUInt32((Ship as TNormalShip).ScriptStatistics[ssPiratesKilled]);
        AccumulateIntegrityUInt32((Ship as TNormalShip).ScriptStatistics[ssKlissansKilled]);
        AccumulateIntegrityUInt32((Ship as TNormalShip).ScriptStatistics[ssSystemsLiberated]);
        AccumulateIntegrityUInt32((Ship as TNormalShip).CurrentSystemKillCount);
        AccumulateIntegrityUInt32(Ord((Ship as TNormalShip).Rank));
        AccumulateIntegrityUInt32((Ship as TNormalShip).RankPoints);
      end;
      if Ship is TRuins then
      begin
        AccumulateIntegrityUInt32(Byte((Ship as TRuins).StationFlags));
        for K := 0 to (Ship as TRuins).EquipmentShop.Count - 1 do
          AccumulateIntegrityItem(TItem((Ship as TRuins).EquipmentShop[K]));
        for Good := t_Food to t_Narcotics do
        begin
          AccumulateIntegrityUInt32((Ship as TRuins).Goods[Good].Count);
          AccumulateIntegritySingle((Ship as TRuins).Goods[Good].PriceState);
          AccumulateIntegrityUInt32((Ship as TRuins).Goods[Good].PurchasePrice);
          AccumulateIntegrityUInt32((Ship as TRuins).Goods[Good].BaseSalePrice);
        end;
      end;
      if Ship is TRanger then
      begin
        AccumulateIntegrityUInt32((Ship as TRanger).PlaceInRating);
        AccumulateIntegrityUInt32((Ship as TRanger).CareerStatus[rcTrader]);
        AccumulateIntegrityUInt32((Ship as TRanger).CareerStatus[rcPirate]);
        AccumulateIntegrityUInt32((Ship as TRanger).CareerStatus[rcWarrior]);
        AccumulateIntegrityUInt32((Ship as TRanger).EminentProgress[rcTrader]);
        AccumulateIntegrityUInt32((Ship as TRanger).EminentProgress[rcPirate]);
        AccumulateIntegrityUInt32((Ship as TRanger).EminentProgress[rcWarrior]);
        AccumulateIntegrityUInt32((Ship as TRanger).PendingCareerActivity[rcTrader]);
        AccumulateIntegrityUInt32((Ship as TRanger).PendingCareerActivity[rcPirate]);
        AccumulateIntegrityUInt32((Ship as TRanger).PendingCareerActivity[rcWarrior]);
        AccumulateIntegrityUInt32(Ord((Ship as TRanger).PreferredCareer));
        AccumulateIntegrityUInt32((Ship as TRanger).Aggression);
        AccumulateIntegrityUInt32((Ship as TRanger).PrisonTermRemaining);
        if (Ship as TRanger).Quests <> nil then
          for K := 0 to (Ship as TRanger).Quests.Count - 1 do
          begin
            RangerQuest := PQuest((Ship as TRanger).Quests[K]);
            if RangerQuest <> nil then
            begin
              AccumulateIntegrityUInt32(RangerQuest.DeadlineTurn);
              AccumulateIntegrityUInt32(RangerQuest.RewardMoney);
            end;
          end;
      end;
      if Ship is TPlayer then
      begin
        AccumulateIntegrityByte(Byte((Ship as TPlayer).InPrison));
        AccumulateIntegrityByte(Byte((Ship as TPlayer).HaveCommunicator));
        AccumulateIntegrityByte(Byte((Ship as TPlayer).HaveHyperspaceLocator));
        AccumulateIntegrityUInt32((Ship as TPlayer).UnresolvedCounter1F4);
        AccumulateIntegrityUInt32((Ship as TPlayer).HyperspaceKillCount);
        AccumulateIntegrityUInt32((Ship as TPlayer).BlackHoleKillCount);
      end;
    end;
  end;
  if (Player <> nil) and (Player.IsOnPlanet or Player.IsDockedToShip) and (TemporaryShopSlots <> nil) then
    for I := 0 to TemporaryShopSlots.Count - 1 do
      if TShopSlot(TemporaryShopSlots[I]).Item <> nil then
        AccumulateIntegrityItem(TShopSlot(TemporaryShopSlots[I]).Item);
  if Player <> nil then
    if Player.IsOnPlanet and (CurrentScreenId = screenPlanetQuest) then
    begin
      for I := 0 to 50 do
        AccumulateIntegrityUInt32(PlanetQuestScreen.ChoicePathIndexes[I]);
      for I := 0 to 50 do
        AccumulateIntegrityByte(Byte(PlanetQuestScreen.ChoiceEnabled[I]));
      for I := 1 to 48 do
        AccumulateIntegrityUInt32(PlanetQuestScreen.ParameterValues[I]);
      for I := 1 to 48 do
        AccumulateIntegrityUInt32(PlanetQuestScreen.PreviousParameterValues[I]);
      for I := 1 to 48 do
        AccumulateIntegrityByte(Byte(PlanetQuestScreen.ParameterVisible[I]));
      AccumulateIntegrityUInt32(PlanetQuestScreen.MoneyLimitComplement);
      AccumulateIntegrityByte(Byte(PlanetQuestScreen.PlayerDied));
      AccumulateIntegrityUInt32(PlanetQuestScreen.DaysElapsed);
      AccumulateIntegrityUInt32(PlanetQuestScreen.CurrentLocationId);
      AccumulateIntegrityByte(Byte(PlanetQuestScreen.ShowingPathTransition));
      AccumulateIntegrityUInt32(PlanetQuestScreen.CriticalParameterIndex);
      AccumulateIntegrityUInt32(PlanetQuestScreen.LastPathIndex);
      Quest := PlanetQuestScreen.Quest;
      if Quest <> nil then
      begin
        AccumulateIntegrityWords(PWord(PWideChar(Quest.QuestDescriptionText.Text)), Length(Quest.QuestDescriptionText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.QuestSuccessGovMessageText.Text)), Length(Quest.QuestSuccessGovMessageText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.UnresolvedText110.Text)), Length(Quest.UnresolvedText110.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.ToStarText.Text)), Length(Quest.ToStarText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.UnresolvedText11C.Text)), Length(Quest.UnresolvedText11C.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.UnresolvedText120.Text)), Length(Quest.UnresolvedText120.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.ToPlanetText.Text)), Length(Quest.ToPlanetText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.DateText.Text)), Length(Quest.DateText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.MoneyText.Text)), Length(Quest.MoneyText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.FromPlanetText.Text)), Length(Quest.FromPlanetText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.FromStarText.Text)), Length(Quest.FromStarText.Text));
        AccumulateIntegrityWords(PWord(PWideChar(Quest.RangerText.Text)), Length(Quest.RangerText.Text));
        AccumulateIntegrityUInt32(Quest.UnresolvedValue14C);
        AccumulateIntegrityUInt32(Quest.UnresolvedValue114);
        AccumulateIntegrityUInt32(Quest.UnresolvedValue44);
        for J := 1 to 48 do
        begin
          Parameter := Quest.Parameters[J];
          AccumulateIntegrityWords(PWord(PWideChar(Parameter.NameText.Text)), Length(Parameter.NameText.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Parameter.ValueText.Text)), Length(Parameter.ValueText.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Parameter.CriticalText.Text)), Length(Parameter.CriticalText.Text));
          for K := 1 to 10 do
          begin
            AccumulateIntegrityUInt32(Parameter.ViewStrings[K].MinValue);
            AccumulateIntegrityUInt32(Parameter.ViewStrings[K].MaxValue);
            AccumulateIntegrityWords(PWord(PWideChar(Parameter.ViewStrings[K].Text.Text)), Length(Parameter.ViewStrings[K].Text.Text));
          end;
          for K := 0 to High(Parameter.InitialValues.Values) do
            AccumulateIntegrityUInt32(Parameter.InitialValues.Values[K]);
          for K := 0 to High(Parameter.InitialRange.RangeStarts) do
            AccumulateIntegrityInt64(Parameter.InitialRange.RangeStarts[K]);
          for K := 0 to High(Parameter.InitialRange.RangeEnds) do
            AccumulateIntegrityInt64(Parameter.InitialRange.RangeEnds[K]);
          AccumulateIntegrityUInt32(Parameter.MinValue);
          AccumulateIntegrityUInt32(Parameter.MaxValue);
          AccumulateIntegrityUInt32(Parameter.Value);
          AccumulateIntegrityUInt32(Cardinal(Parameter.CriticalOutcome));
          AccumulateIntegrityByte(Byte(Parameter.Hidden));
          AccumulateIntegrityByte(Byte(Parameter.ShowWhenZero));
          AccumulateIntegrityByte(Byte(Parameter.CriticalAtMinimum));
          AccumulateIntegrityByte(Byte(Parameter.Enabled));
          AccumulateIntegrityByte(Byte(Parameter.IsMoney));
          AccumulateIntegrityUInt32(Parameter.ViewStringCount);
        end;
        for J := 1 to High(Quest.Locations) do
        begin
          Location := Quest.Locations[J];
          AccumulateIntegrityWords(PWord(PWideChar(Location.UnresolvedText14.Text)), Length(Location.UnresolvedText14.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Location.SelectedEventText.Text)), Length(Location.SelectedEventText.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Location.EventExpression.Text)), Length(Location.EventExpression.Text));
          for K := 1 to 10 do
            AccumulateIntegrityWords(PWord(PWideChar(Location.EventTexts[K].Text)), Length(Location.EventTexts[K].Text));
          AccumulateIntegrityUInt32(Location.Days);
          AccumulateIntegrityUInt32(Location.Id);
          AccumulateIntegrityByte(Byte(Location.UseEventExpression));
          AccumulateIntegrityUInt32(Location.NextEventIndex);
          AccumulateIntegrityByte(Byte(Location.IsEmpty));
          AccumulateIntegrityByte(Byte(Location.UnresolvedFlag51));
          AccumulateIntegrityByte(Byte(Location.UnresolvedFlag52));
          AccumulateIntegrityByte(Byte(Location.IsDeath));
          AccumulateIntegrityByte(Byte(Location.UnresolvedFlag115));
          AccumulateIntegrityByte(Byte(Location.IsStart));
          AccumulateIntegrityByte(Byte(Location.IsSuccess));
          AccumulateIntegrityByte(Byte(Location.IsFailure));
          for K := 1 to 48 do
          begin
            Change := Location.ParameterChanges[K];
            AccumulateIntegrityWords(PWord(PWideChar(Change.ExpressionText.Text)), Length(Change.ExpressionText.Text));
            AccumulateIntegrityWords(PWord(PWideChar(Change.CriticalText.Text)), Length(Change.CriticalText.Text));
            for L := 0 to High(Change.ValueConstraint.Values) do
              AccumulateIntegrityUInt32(Change.ValueConstraint.Values[L]);
            for L := 0 to High(Change.MultipleConstraint.Values) do
              AccumulateIntegrityUInt32(Change.MultipleConstraint.Values[L]);
            AccumulateIntegrityUInt32(Change.RequiredBits);
            AccumulateIntegrityUInt32(Change.MinValue);
            AccumulateIntegrityUInt32(Change.MaxValue);
            AccumulateIntegrityUInt32(Change.ChangeValue);
            AccumulateIntegrityByte(Byte(Change.ChangeByPercent));
            AccumulateIntegrityByte(Byte(Change.SetValue));
            AccumulateIntegrityByte(Byte(Change.UseExpression));
            AccumulateIntegrityUInt32(Cardinal(Change.VisibilityChange));
            AccumulateIntegrityByte(Byte(Change.LegacyFlag));
          end;
        end;
        for J := 1 to High(Quest.Paths) do
        begin
          Path := Quest.Paths[J];
          AccumulateIntegrityWords(PWord(PWideChar(Path.ChoiceText.Text)), Length(Path.ChoiceText.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Path.TransitionText.Text)), Length(Path.TransitionText.Text));
          AccumulateIntegrityWords(PWord(PWideChar(Path.ConditionExpression.Text)), Length(Path.ConditionExpression.Text));
          AccumulateIntegrityDouble(Path.Priority);
          AccumulateIntegrityByte(Byte(Path.IsAutomatic));
          AccumulateIntegrityByte(Byte(Path.AlwaysShow));
          AccumulateIntegrityUInt32(Path.UnresolvedValue14);
          AccumulateIntegrityUInt32(Path.DisplayOrder);
          AccumulateIntegrityUInt32(Path.Id);
          AccumulateIntegrityUInt32(Path.TraversalLimit);
          AccumulateIntegrityUInt32(Path.FromLocationId);
          AccumulateIntegrityUInt32(Path.ToLocationId);
          for K := 1 to 48 do
          begin
            Change := Path.ParameterChanges[K];
            AccumulateIntegrityWords(PWord(PWideChar(Change.ExpressionText.Text)), Length(Change.ExpressionText.Text));
            AccumulateIntegrityWords(PWord(PWideChar(Change.CriticalText.Text)), Length(Change.CriticalText.Text));
            for L := 0 to High(Change.ValueConstraint.Values) do
              AccumulateIntegrityUInt32(Change.ValueConstraint.Values[L]);
            for L := 0 to High(Change.MultipleConstraint.Values) do
              AccumulateIntegrityUInt32(Change.MultipleConstraint.Values[L]);
            AccumulateIntegrityUInt32(Change.RequiredBits);
            AccumulateIntegrityUInt32(Change.MinValue);
            AccumulateIntegrityUInt32(Change.MaxValue);
            AccumulateIntegrityUInt32(Change.ChangeValue);
            AccumulateIntegrityByte(Byte(Change.ChangeByPercent));
            AccumulateIntegrityByte(Byte(Change.SetValue));
            AccumulateIntegrityByte(Byte(Change.UseExpression));
            AccumulateIntegrityUInt32(Cardinal(Change.VisibilityChange));
            AccumulateIntegrityByte(Byte(Change.LegacyFlag));
          end;
        end;
      end;
    end;
  if (CurrentScreenId = screenArcadeBattle) and (PlayerArcadeShip <> nil) then
  begin
    AccumulateIntegrityUInt32(PlayerArcadeShip.Health);
    AccumulateIntegrityUInt32(PlayerArcadeShip.MaxHealth);
    for I := 0 to 4 do
    begin
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].Ammo);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].MaxAmmo);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].RechargePerTick);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].AmmoCost);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].LastFireTick);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].FireIntervalTicks);
      AccumulateIntegrityUInt32(PlayerArcadeShip.Weapons[I].Damage);
    end;
  end;
  if CurrentScreenId = screenShip then
  begin
    AccumulateIntegrityUInt32(ShipScreen.SelectedHoldKind);
    AccumulateIntegrityUInt32(Ord(ShipScreen.SelectedGoodsIndex));
    AccumulateIntegrityUInt32(ShipScreen.SelectedGoodsQuantity);
    AccumulateIntegrityUInt32(ShipScreen.SelectedGoodsCost);
    if ShipScreen.SelectedHoldKind in [2, 3] then
      if ShipScreen.SelectedHoldItem <> nil then
        AccumulateIntegrityItem(ShipScreen.SelectedHoldItem);
  end;
  AccumulateIntegrityUInt32(GovernmentScreen.QuestOffer.DeadlineTurn);
  AccumulateIntegrityUInt32(GovernmentScreen.QuestOffer.RewardMoney);
  AccumulateIntegrityUInt32(GovernmentScreen.QuestNegotiationLevel);
  AccumulateIntegrityUInt32(GovernmentScreen.QuestRewardStep);
  AccumulateIntegrityUInt32(GovernmentScreen.QuestDurationStep);
  if PlayerArcadeShip <> nil then
  begin
    AccumulateIntegrityUInt32(PlayerArcadeShip.Health);
    AccumulateIntegrityUInt32(PlayerArcadeShip.MaxHealth);
  end;
  AccumulateIntegrityBytes(@IntegrityDataBegin, Cardinal(@IntegrityDataEnd) - Cardinal(@IntegrityDataBegin));
  Result := FinishCrc32(State);
end;
{ @end $5EB564 }

{ @routine $5ECC4C TGalaxy_StoreIntegrityChecksum }
procedure TGalaxy.StoreIntegrityChecksum;
begin
  if not MoneyIntegrityFailed then begin
    StoredIntegrityChecksum := ComputeIntegrityChecksum;
    IntegrityChecksumPending := True;
  end;
end;
{ @end $5ECC4C }

{ @routine $5ECC70 TGalaxy_VerifyIntegrityChecksum }
procedure TGalaxy.VerifyIntegrityChecksum;
begin
  if not MoneyIntegrityFailed and IntegrityChecksumPending then begin
    IntegrityChecksumPending := False;
    if ComputeIntegrityChecksum <> StoredIntegrityChecksum then MoneyIntegrityFailed := True;
  end;
end;
{ @end $5ECC70 }

{ @routine $5ECCA4 TGalaxy_AppendScoreIntegritySnapshot }
procedure TGalaxy.AppendScoreIntegritySnapshot;
var StartOffset, Partners, I, SnapshotLength: Integer; Ranger: TRanger; Owner: TOwnerId;
begin
  if Player <> nil then
  begin
    IntegrityBuffer.SetPosition(IntegrityBuffer.DataSize);
    StartOffset := IntegrityBuffer.Position;
    IntegrityBuffer.AddIntegerValue(3);
    IntegrityBuffer.AddIntegerValue(0);
    IntegrityBuffer.AddDWord(0);
    IntegrityBuffer.AddDWord(0);
    IntegrityBuffer.AddIntegerValue(CurrentTurn);
    IntegrityBuffer.AddIntegerValue(MaxRangerWealth);
    IntegrityBuffer.AddSingle(BestRangerStrength);
    IntegrityBuffer.AddIntegerValue(Player.Money);
    IntegrityBuffer.AddIntegerValue(Player.Wealth);
    IntegrityBuffer.AddSingle(Player.Strength);
    IntegrityBuffer.AddIntegerValue(Player.NodeReserve);
    IntegrityBuffer.AddIntegerValue(Player.TotalExperience);
    IntegrityBuffer.AddIntegerValue(Player.FreeExperience);
    IntegrityBuffer.AddIntegerValue(Player.CargoFreeSpace);
    IntegrityBuffer.AddIntegerValue(Player.Speed);
    IntegrityBuffer.AddSingle(Player.DefenseDamageFactor);
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skAccuracy]));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skMobility]));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skTechnical]));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skTrader]));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skCharm]));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.BaseSkills[skLeadership]));
    IntegrityBuffer.AddWideChar(WideChar(Player.PlaceInRating));
    IntegrityBuffer.AddWideChar(WideChar(Player.ScriptStatistics[ssShipsKilled]));
    IntegrityBuffer.AddWideChar(WideChar(Player.ScriptStatistics[ssPiratesKilled]));
    IntegrityBuffer.AddWideChar(WideChar(Player.ScriptStatistics[ssKlissansKilled]));
    IntegrityBuffer.AddWideChar(WideChar(Player.ScriptStatistics[ssSystemsLiberated]));
    IntegrityBuffer.AddWideChar(WideChar(Player.CurrentSystemKillCount));
    IntegrityBuffer.AddAnsiChar(AnsiChar(Player.Rank));
    IntegrityBuffer.AddWideChar(WideChar(Player.RankPoints));
    IntegrityBuffer.AddWideChar(WideChar(Player.HyperspaceKillCount));
    IntegrityBuffer.AddWideChar(WideChar(Player.BlackHoleKillCount));
    if Player.AwardIds = nil then IntegrityBuffer.AddAnsiChar(#0)
    else IntegrityBuffer.AddAnsiChar(AnsiChar(Player.AwardIds.Count));
    IntegrityBuffer.AddAnsiStringZ('1.7.2');
    IntegrityBuffer.AddByte(CountStarsByFaction(sfCoalition));
    Partners := 0;
    for I := 0 to Rangers.Count - 1 do
    begin
      Ranger := Rangers[I];
      if Player = Ranger.PartnerShip then
      begin
        Owner := Ranger.OwnerId;
        if Owner in CoalitionOwners then Inc(Partners);
      end;
    end;
    IntegrityBuffer.AddAnsiChar(AnsiChar(Partners));
    IntegrityBuffer.AddIntegerValue(TotalCheatPoints);
    IntegrityBuffer.AddIntegerValue(LoadCount);
    if PlayerOldQuests = nil then IntegrityBuffer.AddIntegerValue(0)
    else IntegrityBuffer.AddIntegerValue(PlayerOldQuests.Count);
    SnapshotLength := IntegrityBuffer.Position - StartOffset;
    PInteger(Cardinal(IntegrityBuffer.Data) + Cardinal(StartOffset) + 4)^ := SnapshotLength;
    PCardinal(Cardinal(IntegrityBuffer.Data) + Cardinal(StartOffset) + 8)^ := IntegrityBuffer.ComputeCrc32Range(StartOffset + 16, IntegrityBuffer.Position);
  end;
end;
{ @end $5ECCA4 }

{ @routine $5ED05C THole_Create }
constructor THole.Create;
begin
  inherited Create;
  Id := Galaxy.NextHoleId;
  Inc(Galaxy.NextHoleId);
end;
{ @end $5ED05C }

{ @routine $5ED0A4 THole_Destroy }
destructor THole.Destroy;
begin
  if Graphic <> nil then
  begin
    Graphic.Free;
    Graphic := nil;
  end;
  inherited Destroy;
end;
{ @end $5ED0A4 }

{ @routine $5ED0DC THole_InitializeGraphic }
procedure THole.InitializeGraphic;
var Block: TBlockParEC;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Hole');
  Graphic := CreateSpaceObjectByName('Hole', 'Hole.' + Block.GetBlockNameByIndex(
    SeededRandomIntRange(0, Block.GetBlockCount - 1, Id + Galaxy.CurrentTurn)), Classes.Point(0, 0)) as THoleSE;
  Graphic.SetPosition(MakePointF(0, 0));
end;
{ @end $5ED0DC }

{ @routine $5ED1EC THole_SaveToBuffer }
procedure THole.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddDWord(Star1.Id);
  Buffer.AddSingle(Position1.X);
  Buffer.AddSingle(Position1.Y);
  Buffer.AddDWord(Star2.Id);
  Buffer.AddSingle(Position2.X);
  Buffer.AddSingle(Position2.Y);
  Buffer.AddIntegerValue(CreatedTurn);
  Buffer.AddIntegerValue(Integer(HoleType));
  Buffer.AddWideStringZ(Graphic.GraphKey);
end;
{ @end $5ED1EC }

{ @routine $5ED264 THole_LoadFromBuffer }
procedure THole.LoadFromBuffer(Buffer: TBufEC);
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextHoleId <= Id then Galaxy.NextHoleId := Id + 1;
  Star1 := TStar(Buffer.GetUInt32);
  Position1.X := Buffer.GetSingle;
  Position1.Y := Buffer.GetSingle;
  Star2 := TStar(Buffer.GetUInt32);
  Position2.X := Buffer.GetSingle;
  Position2.Y := Buffer.GetSingle;
  CreatedTurn := Buffer.GetInt32;
  HoleType := TBlackHoleKind(Buffer.GetInt32);
  Graphic := CreateSpaceObjectByName('Hole', Buffer.ReadWideString, Classes.Point(0, 0)) as THoleSE;
  Graphic.SetPosition(MakePointF(0, 0));
end;
{ @end $5ED264 }

{ @routine $5ED37C THole_ResolveLoadedReferences }
procedure THole.ResolveLoadedReferences;
begin
  Star1 := Galaxy.IdToStar(Cardinal(Star1)) as TStar;
  Star2 := Galaxy.IdToStar(Cardinal(Star2)) as TStar;
end;
{ @end $5ED37C }

{ @routine $5ED3B8 TStar_Create }
constructor TStar.Create;
begin
  inherited Create;
  Id := Galaxy.NextStarId;
  Inc(Galaxy.NextStarId);
  GenerationSeed := NextRandomIntRange(100000, MaxInt, Galaxy.RandomState);
  RandomState := GenerationSeed;
  Planets := TObjectList.Create;
  Asteroids := TObjectList.Create;
  Ships := TObjectList.Create;
  Items := TObjectList.Create;
  MovingDropItems := TList.Create;
  CombatOccurred := False;
  PlayerCombatActive := False;
  PlayerInteractionOccurred := False;
end;
{ @end $5ED3B8 }

{ @routine $5ED478 TStar_Destroy }
destructor TStar.Destroy;
var I: Integer;
begin
  if Graphic <> nil then
  begin
    Graphic.Free;
    Graphic := nil;
  end;
  for I := 0 to MovingDropItems.Count - 1 do FreeEC(MovingDropItems[I]);
  MovingDropItems.Free;
  MovingDropItems := nil;
  Items.Free;
  Items := nil;
  Ships.Free;
  Ships := nil;
  Planets.Free;
  Planets := nil;
  Asteroids.Free;
  Asteroids := nil;
  inherited Destroy;
end;
{ @end $5ED478 }

{ @routine $5ED514 TStar_GenerateSystemContents }
procedure TStar.GenerateSystemContents;
var I, NameIndex, J, TotalPlanets, Inhabited: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Text: WideString;
  Definition: TBlockParEC;
begin
  NameIndex := Galaxy.Stars.IndexOf(Self) mod LanguageDataConfig.GetBlock('Star').GetParamCount;
  Text := LanguageDataConfig.GetBlock('Star').GetParamValue(NameIndex);
  Name := ExtractDelimitedPartW(Text, 0, ',');
  Definition := GameDataConfig.GetBlockByPath('Star');
  TemplatePath := 'Star.' + Definition.GetBlockNameByIndex(RandomIntRange(0, Definition.GetBlockCount - 1));
  Definition := GameDataConfig.GetBlockByPath(TemplatePath);
  Radius := StrToInt(AnsiString(Definition.GetParam('Radius')));
  SafeRadius := ExtractDecimalToSingleW(Definition.GetParam('SafeRadius'));
  DamageRadius := ExtractDecimalToSingleW(Definition.GetParam('DamageRadius'));
  SystemRadius := Radius;
  Graphic := CreateSpaceObjectByName('Star', Definition.GetParam('SEGraph'), Classes.Point(0, 0)) as TStarSE;
  SystemProcessName := Definition.GetParam('SEProcess');
  Graphic.SetPosition(MakePointF(0, 0));
  if Galaxy.Stars.IndexOf(Self) = 2 then begin TotalPlanets := 7; Inhabited := 0; end
  else if Galaxy.Stars.IndexOf(Self) < 5 then begin TotalPlanets := 6; Inhabited := 3; end
  else begin
    TotalPlanets := NextRandomIntRange(3, 6, RandomState);
    Inhabited := Round(TotalPlanets div 2 + NextRandomIntRange(0, 1, RandomState));
    if Inhabited > 2 * TotalPlanets / 3 then Inhabited := Round(2 * TotalPlanets / 3);
    if Inhabited > 3 then Inhabited := 3;
  end;
  for I := 1 to TotalPlanets do begin
    Planet := TPlanet.Create;
    Planet.InitGenerated(Self, TotalPlanets, Inhabited);
    Planets.Add(Planet);
    Galaxy.Planets.Add(Planet);
  end;
  ControlFaction := sfCoalition;
  Battle := False;
  KlissanCaptureDays := 0;
  for I := 0 to NextRandomIntRange(8, 10, RandomState) - 1 do begin
    Asteroid := TAsteroid.Create;
    Asteroid.InitializeAtStar(Self);
    Asteroids.Add(Asteroid);
    for J := 0 to 300 do Asteroid.IntegrateMotion(20);
  end;
  DaysSincePlayerVisit := 100;
  DaysSinceLastNpcShipSpawn := 100;
  RefreshMapDiameterAndStats;
end;
{ @end $5ED514 }

{ @routine $5ED934 TStar_SaveToBuffer }
procedure TStar.SaveToBuffer(Buffer: TBufEC);
var I, Count: Integer; Planet: TPlanet; Asteroid: TAsteroid;
  Ship: TShip; Item: TItem; Drop: PMovingDropItemEntry;
begin
  Buffer.AddDWord(Id);
  Buffer.AddIntegerValue(GenerationSeed);
  Buffer.AddDWord(RandomState);
  Buffer.AddBoolean(LegacySystemKind);
  Buffer.AddWideStringZ(Name);
  Buffer.AddSingle(Position.X);
  Buffer.AddSingle(Position.Y);
  Buffer.AddWideChar(WideChar(SystemRadius));
  Count := Planets.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Planet := Planets[I];
    Planet.SaveToBuffer(Buffer);
  end;
  Count := Asteroids.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Asteroid := Asteroids[I];
    Asteroid.SaveToBuffer(Buffer);
  end;
  Count := Ships.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Ship := Ships[I];
    if Ship is TPlayer then Buffer.AddAnsiChar(AnsiChar(255))
    else Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Ship.ShipType)));
    Ship.SaveToBuffer(Buffer);
  end;
  Count := Items.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Item := Items[I];
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  Count := MovingDropItems.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Drop := MovingDropItems[I];
    Buffer.AddSingle(Drop.Destination.X);
    Buffer.AddSingle(Drop.Destination.Y);
    Buffer.AddDWord(Drop.SourceShipId);
    Buffer.AddBoolean(Drop.UseFlag);
    Item := Drop.Payload as TItem;
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  Buffer.AddDWord(Constellation.Id);
  Buffer.AddWideStringZ(SystemProcessName);
  Buffer.AddAnsiChar(AnsiChar(ThreatLevel));
  Buffer.AddAnsiChar(AnsiChar(TrafficLevel));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(ControlFaction)));
  Buffer.AddSingle(SafeRadius);
  Buffer.AddSingle(DamageRadius);
  Buffer.AddWideChar(WideChar(Radius));
  Buffer.AddWideStringZ(TemplatePath);
  Buffer.AddBoolean(CombatOccurred);
  Buffer.AddBoolean(PlayerCombatActive);
  Buffer.AddAnsiChar(AnsiChar(KlissanCaptureDays));
  Buffer.AddIntegerValue(DaysSincePlayerVisit);
  Buffer.AddIntegerValue(DaysSinceLastNpcShipSpawn);
end;
{ @end $5ED934 }

{ @routine $5EDBD0 TStar_LoadFromBuffer }
procedure TStar.LoadFromBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Ship: TShip;
  Item: TItem;
  ShipKind: TShipType; ItemKind: TItemType;
  Drop: PMovingDropItemEntry;
  Definition: TBlockParEC;
  Tag: Byte;
begin
    Id := Buffer.GetUInt32;
    if Galaxy.NextStarId <= Id then Galaxy.NextStarId := Id + 1;
    GenerationSeed := Buffer.GetInt32;
    RandomState := Buffer.GetUInt32;
    LegacySystemKind := Buffer.GetBoolean;
    Name := Buffer.ReadWideString;
    Position.X := Buffer.GetSingle;
    Position.Y := Buffer.GetSingle;
    SystemRadius := Buffer.GetWord;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do begin
      Planet := TPlanet.Create;
      Planet.CurrentStar := Self;
      Planets.Add(Planet);
      Planet.LoadFromBuffer(Buffer);
    end;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do begin
      Asteroid := TAsteroid.Create;
      Asteroid.CurrentStar := Self;
      Asteroids.Add(Asteroid);
      Asteroid.LoadFromBuffer(Buffer);
    end;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do begin
      Tag := Buffer.GetByte;
      if Tag = 255 then Ship := TPlayer.Create
      else begin WriteByteValue(Tag, ShipKind); Ship := CreateShipByType(ShipKind); end;
      Ships.Add(Ship);
      Ship.CurrentStar := Self;
      Ship.LoadFromBuffer(Buffer);
    end;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do begin
      WriteByteValue(Buffer.GetByte, ItemKind);
      Item := CreateItemByType(ItemKind);
      Items.Add(Item);
      Item.LoadFromBuffer(Buffer);
    end;
    Count := Buffer.GetWord;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do begin
      Drop := AllocEC(SizeOf(TMovingDropItemEntry));
      Drop.Destination.X := Buffer.GetSingle;
      Drop.Destination.Y := Buffer.GetSingle;
      Drop.SourceShipId := Buffer.GetUInt32;
      Drop.InsertedIntoStar := False;
      Drop.UseFlag := Buffer.GetBoolean;
      WriteByteValue(Buffer.GetByte, ItemKind);
      Item := CreateItemByType(ItemKind);
      Drop.Payload := Item;
      Item.LoadFromBuffer(Buffer);
      MovingDropItems.Add(Drop);
    end;
    Constellation := TConstellation(Buffer.GetUInt32);
    SystemProcessName := Buffer.ReadWideString;
    ThreatLevel := Buffer.GetByte;
    TrafficLevel := Buffer.GetByte;
    WriteByteValue(Buffer.GetByte, ControlFaction);
    for I := 0 to Planets.Count - 1 do begin
      Planet := TPlanet(Planets[I]);
      if (ControlFaction = sfKlissan) and (Planet.OwnerId in CoalitionOwners) then Planet.OwnerId := oiKling
      else if (ControlFaction = sfCoalition) and (Planet.OwnerId = oiKling) then Planet.OwnerId := RaceToOwner(Planet.RaceId);
    end;
    SafeRadius := Buffer.GetSingle;
    DamageRadius := Buffer.GetSingle;
    Radius := Buffer.GetWord;
    TemplatePath := Buffer.ReadWideString;
    Definition := GameDataConfig.GetBlockByPath(TemplatePath);
    Graphic := CreateSpaceObjectByName('Star', Definition.GetParam('SEGraph'), Classes.Point(0, 0)) as TStarSE;
    Graphic.SetPosition(MakePointF(0, 0));
    CombatOccurred := Buffer.GetBoolean;
    PlayerCombatActive := Buffer.GetBoolean;
    KlissanCaptureDays := Buffer.GetByte;
    DaysSincePlayerVisit := Buffer.GetInt32;
    if LoadedSaveVersion >= 2 then DaysSinceLastNpcShipSpawn := Buffer.GetInt32
    else DaysSinceLastNpcShipSpawn := 5;
end;
{ @end $5EDBD0 }

{ @routine $5EE0D4 TStar_ResolveLoadedReferences }
procedure TStar.ResolveLoadedReferences;
var I, Count: Integer; Planet: TPlanet; Ship: TShip; Item: TItem; Drop: PMovingDropItemEntry;
begin
  Count := Planets.Count;
  for I := 0 to Count - 1 do begin
    Planet := TPlanet(Planets[I]);
    Planet.ResolveLoadedReferences;
  end;
  Count := Ships.Count;
  for I := 0 to Count - 1 do begin
    Ship := TShip(Ships[I]);
    Ship.ResolveLoadedReferences;
    if Ship is TRC then RangerCenter := Ship;
  end;
  Count := Items.Count;
  for I := 0 to Count - 1 do begin
    Item := TItem(Items[I]);
    Item.ClearReferences;
  end;
  Count := MovingDropItems.Count;
  for I := 0 to Count - 1 do begin
    Drop := MovingDropItems[I];
    (Drop.Payload as TItem).ClearReferences;
  end;
  Constellation := Galaxy.IdToConstellation(Cardinal(Constellation)) as TConstellation;
end;
{ @end $5EE0D4 }

{ @routine $5EE1B8 TStar_ClearShipCombatTargets }
procedure TStar.ClearShipCombatTargets(Target: TObject);
var I, J, Count: Integer; Ship: TShip; Weapon: TWeapon;
begin
  Count := Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship <> Target then
      for J := 1 to Ship.WeaponCount do
      begin
        Weapon := Ship.Weapons[J - 1];
        if Target = Weapon.Target then Weapon.Target := nil;
      end;
  end;
  Ship := Target as TShip;
  for J := 1 to Ship.WeaponCount do
  begin
    Weapon := Ship.Weapons[J - 1];
    Weapon.Target := nil;
  end;
end;
{ @end $5EE1B8 }

{ @routine $5EE254 TStar_ClearItemReferences }
procedure TStar.ClearItemReferences(Item: TObject);
var I, J: Integer; Ship: TShip; Weapon: TWeapon;
begin
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    Ship.RemoveQueuedPickupItem(TItem(Item));
    for J := 1 to Ship.WeaponCount do
    begin
      Weapon := Ship.Weapons[J - 1];
      if Item = Weapon.Target then Weapon.Target := nil;
    end;
  end;
end;
{ @end $5EE254 }

{ @routine $5EE2CC TStar_PruneWeaponTargetsAfterTurn }
procedure TStar.PruneWeaponTargetsAfterTurn;
var I, J: Integer; Ship: TShip; Weapon: TWeapon;
begin
  for I := 0 to Ships.Count - 1 do begin
    Ship := Ships[I];
    for J := 1 to Ship.WeaponCount do begin
      Weapon := Ship.Weapons[J - 1];
      if Weapon.Target <> nil then begin
        if Weapon.Target is TItem then Weapon.Target := nil
        else if Weapon.Target is TAsteroid then Weapon.Target := nil
        else if not Ship.InNormalSpace or not (Weapon.Target as TShip).InNormalSpace or
          (PointDistanceSquared(Ship.Position, (Weapon.Target as TShip).Position) > Sqr(Weapon.Range)) then
          Weapon.Target := nil;
      end;
    end;
  end;
end;
{ @end $5EE2CC }

{ @routine $5EE3D0 TStar_MarkConnectedCombatEvents }
procedure TStar.MarkConnectedCombatEvents(Events: TList; Target: TObject; Group: Integer);
var I, Count: Integer; Event: PStarCombatEvent;
begin
  Count := Events.Count;
  for I := 0 to Count - 1 do
  begin
    Event := Events[I];
    if Event.CombatGroup = 0 then
    begin
      if Event.Attacker = Target then
      begin
        Event.CombatGroup := Group;
        MarkConnectedCombatEvents(Events, Event.Target, Group);
      end
      else if Event.Target = Target then
      begin
        Event.CombatGroup := Group;
        MarkConnectedCombatEvents(Events, Event.Attacker, Group);
      end;
    end;
  end;
end;
{ @end $5EE3D0 }

{ @routine $5EE450 TStar_PrepareNextDay }
procedure TStar.PrepareNextDay;
var Planet: TPlanet; Asteroid: TAsteroid; I: Integer; Ship: TShip;
begin
  if (Player <> nil) and (Player.CurrentStar = Self) then DaysSincePlayerVisit := 0
  else Inc(DaysSincePlayerVisit);
  Inc(DaysSinceLastNpcShipSpawn);
  StarPreparationFlag := True;
  if StarPreparationFlag then begin end;
  TryGenerateSystemNews;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.NextDay;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.RespawnIfOutsideSystem;
  end;
  // Visits ships forwards, including the native mutation behavior of NextDay.
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    Ship.NextDay;
  end;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Ship.Order = soLanding) and (Ship.OrderTarget is TShip) and
      ((Ship.OrderTarget as TShip).Order <> soNone) then
      (Ship.OrderTarget as TShip).OrderNone
    else if (Ship.Order = soTakeoff) and (Ship.DockedTo <> nil) and (Ship.DockedTo.Order <> soNone) then
      Ship.DockedTo.OrderNone;
  end;
end;
{ @end $5EE450 }

{ @routine $5EEA28 TStar_NextDay }
procedure TStar.NextDay(RecordFilm: Boolean);
var
  Angle: Single;
  PathStep, WorkCount, StepIndex, Index, K, ShipCount, Quantity, EntryIndex: Integer;
  J: Integer;
  CombatGroup: Integer;
  WorkValue: Integer;
  WorkSingle, WorkScale: Single;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  OtherShip, OwnerShip, TargetShip, NearestShip: TShip;
  Item, NearestItem: TItem;
  Weapon: TWeapon;
  CombatEvent, CleanupEvent: PStarCombatEvent; // Cleanup loops fetch each native event once.
  Events: TList;
  DamageColor: Cardinal;
  Damage: Integer;
  StarOrGateFilm, ObjectFilm: TEFilmObj;
  Distance: Single;
  X: Single;
  Y: Single;
  ImpactX: Single;
  ImpactY: Single;
  PointB: TPointF;
  WorkY, WorkX: Single;
  CameraPath: TSPath;
  Node: PSPathNode;
  Effect: TObjectSE;
  DamageStep1, DamageStep2, DamageStep3: Integer;
  GateEntry: PJumpGateEntry;
  Target: TObject;
  Artefact: TArtefactTranclucator;
  StoredTranclucator: TTranclucator;
  ReservedBeforeShot: Integer;
  FirstShot: Boolean;
  PendingFilmRemovals: TList;
  ReservedAfterRemovals: Integer;
  Ship: TShip;
  I: Integer;
  MovingDrop: PMovingDropItemEntry;
  Hole: THole;
// @nested $5EE598 RepelFollowOverlaps
procedure RepelFollowOverlaps(FromShip: TShip); // @addr $5EE598
var
  Count, Index: Integer;
  Distance, Penetration, DeltaY, DeltaX: Single;
  Other: TShip;
begin
  Count := Ships.Count;
  repeat
    Index := 0;
    while Index < Count do
    begin
      Other := TShip(Ships[Index]);
      if (FromShip = Other) or (Other.Order <> soFollowShip) then
      begin
        Inc(Index);
        Continue;
      end;
      Distance := PointDistance(FromShip.FollowPosition, Other.FollowPosition);
      Penetration := Distance - FromShip.CollisionRadius - Other.CollisionRadius - 5;
      if Penetration < -0.01 then
      begin
        Penetration := -Penetration;
        if Distance = 0 then
        begin
          Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360,
            (FromShip.Seed + Other.Seed) * Cardinal(Galaxy.CurrentTurn)));
          DeltaX := Sin(Angle) * Penetration;
          DeltaY := -Cos(Angle) * Penetration;
        end
        else
        begin
          Distance := 1 / Distance * Penetration;
          DeltaX := (Other.FollowPosition.X - FromShip.FollowPosition.X) * Distance;
          DeltaY := (Other.FollowPosition.Y - FromShip.FollowPosition.Y) * Distance;
        end;
        Other.FollowPosition.X := Other.FollowPosition.X + DeltaX;
        Other.FollowPosition.Y := Other.FollowPosition.Y + DeltaY;
        RepelFollowOverlaps(Other);
      end;
      Inc(Index);
    end;
  until Index >= Count;
end;
// @nested $5EE730 DropMinerals
procedure DropMinerals(Quantity: Integer; Position: TPointF; Seed: Cardinal); // @addr $5EE730
var
  Angle, AngleStep, Radius, Jitter: Single;
  Count, Index, Chunk: Integer;
  Goods: TGoods;
  Drop: PMovingDropItemEntry;
begin
  Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, Seed));
  Seed := StepRandomSeed(Seed);
  Count := 0;
  while Quantity > 0 do
  begin
    if (Quantity < 10) or (Count >= 3) then Chunk := Quantity
    else Chunk := Round((SeededRandomUnitFloat(Seed) * 0.2 + 0.55) * Quantity);
    Seed := StepRandomSeed(Seed);
    Dec(Quantity, Chunk);
    Goods := TGoods.Create;
    Goods.Init(t_Minerals, Chunk);
    Goods.NaturalFlag := True;
    Goods.Position := Position;
    Drop := AllocEC(SizeOf(TMovingDropItemEntry));
    Drop.Payload := Goods;
    Drop.SourceShipId := 0;
    Drop.InsertedIntoStar := False;
    Drop.UseFlag := False;
    MovingDropItems.Add(Drop);
    Inc(Count);
  end;
  AngleStep := 3.1415926;
  if Count > 1 then AngleStep := 6.2831852 / Count;
  for Index := 0 to Count - 1 do
  begin
    Drop := MovingDropItems[MovingDropItems.Count - 1 - Index];
    Radius := SeededRandomIntRange(50, 150, Seed);
    if (Self = PlayerStar) and (PathStep > WorkCount - 20) then Radius := 5;
    Seed := StepRandomSeed(Seed);
    Jitter := SeededRandomUnitFloat(Seed) * 0.3 - 0.15;
    Seed := StepRandomSeed(Seed);
    Drop.Destination.X := (Drop.Payload as TItem).Position.X +
      Sin(SeededRandomUnitFloat(Seed) * (Angle + Jitter)) * Radius;
    Seed := StepRandomSeed(Seed);
    Drop.Destination.Y := (Drop.Payload as TItem).Position.Y -
      Cos(SeededRandomUnitFloat(Seed) * (Angle + Jitter)) * Radius;
    Seed := StepRandomSeed(Seed);
    Angle := Angle + AngleStep;
  end;
end;
// @nested $5EE9B0 ClearUnequippedWeaponTargets
procedure ClearUnequippedWeaponTargets(Ship: TShip); // @addr $5EE9B0
var
  I: Integer;
  Item: TEquipment;
begin
  for I := 0 to Ship.Inventory.Count - 1 do
  begin
    Item := TEquipment(Ship.Inventory[I]);
    if not Item.EquippedFlag and (Item is TWeapon) and
      ((Item as TWeapon).Target <> nil) then
      (Item as TWeapon).Target := nil;
  end;
end;
begin
  if RecordFilm and (Player <> nil) and (KlingMotherShip <> nil) and
    (Player.CurrentStar = KlingMotherShip.CurrentStar) and Player.HaveCommunicator and
    (Galaxy.Scripts.Count <= 0) then TryStartScriptByName(Player.CurrentStar, nil, 'MS_Machpella');
  if (Player <> nil) and (Player.CurrentStar = Self) then DaysSincePlayerVisit := 0
  else Inc(DaysSincePlayerVisit);
  if not Globals.PlayerStarDayPrepared then Inc(DaysSinceLastNpcShipSpawn);
  StarPreparationFlag := RecordFilm;
  CombatOccurred := False;
  PlayerCombatActive := False;
  PlayerInteractionOccurred := False;
  StepIndex := 0;
  if RecordFilm then PendingFilmRemovals := TList.Create;
  if (Globals.PlayerStarDayPrepared xor True) and StarPreparationFlag then;
  if Globals.PlayerStarDayPrepared xor True then TryGenerateSystemNews;
  if not Globals.PlayerStarDayPrepared then
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[Index]);
      Planet.NextDay;
    end;
  if not Globals.PlayerStarDayPrepared then
    for Index := 0 to Asteroids.Count - 1 do
    begin
      Asteroid := TAsteroid(Asteroids[Index]);
      Asteroid.RespawnIfOutsideSystem;
    end;
  if not Globals.PlayerStarDayPrepared then
  begin
    for Index := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[Index]);
      Ship.NextDay;
    end;
    for Index := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[Index]);
      if (Ship.Order = soLanding) and (Ship.OrderTarget is TShip) and
        ((Ship.OrderTarget as TShip).Order <> soNone) then (Ship.OrderTarget as TShip).OrderNone
      else if (Ship.Order = soTakeoff) and (Ship.DockedTo <> nil) and (Ship.DockedTo.Order <> soNone) then
        Ship.DockedTo.OrderNone;
    end;
  end;
  if RecordFilm then
  begin
    PrimaryFilm.SystemProcessName := SystemProcessName;
    PrimaryFilm.MapDiameter := ComputeMapDiameter;
    PrimaryFilm.StarGenerationSeed := GenerationSeed;
    PrimaryFilm.Turn := Galaxy.CurrentTurn;
    PrimaryFilm.RadarRange := 0;
    if (Player.Radar <> nil) and not Player.Radar.BrokenFlag then
      PrimaryFilm.RadarRange := Player.GetRadarRange;
    StarOrGateFilm := PrimaryFilm.AddObject(Id, Graphic, 0, 0);
    PrimaryFilm.SetObjectPosition(StepIndex, StarOrGateFilm, MakePointF(0, 0));
    PrimaryFilm.AttachObject(StepIndex, StarOrGateFilm);
    (PrimaryFilm.ObjectInfo as TEObjInfo).LoadFromStar(Self);
  end;
  Events := TList.Create;
  WorkCount := Ships.Count;
  for Index := 0 to WorkCount - 1 do
  begin
    Ship := TShip(Ships[Index]);
    if Ship.InNormalSpace then
      for K := 1 to Ship.WeaponCount do
      begin
        Weapon := Ship.Weapons[K - 1];
        if (Weapon.Target <> nil) and ((Weapon.Target is TItem) or
          (Weapon.Target is TAsteroid) or ((Weapon.Target is TShip) and
          (Weapon.Target as TShip).InNormalSpace)) then
        begin
          if Ship.IsOnPlanet then
            raise Exception.Create('Корабль сидящий на планете не может cтрелять');
          CombatEvent := AllocEC(SizeOf(TStarCombatEvent));
          CombatEvent.Attacker := Ship;
          CombatEvent.Target := Weapon.Target;
          CombatEvent.Weapon := Weapon;
          CombatEvent.CombatGroup := 0;
          CombatEvent.EffectFilm := nil;
          CombatEvent.Effect := nil;
          CombatEvent.DestroyedTargetFilm := nil;
          if RecordFilm then CombatEvent.StepIndex := Round(Weapon.GetShotDelayFactor * 170)
          else CombatEvent.StepIndex := Round(Weapon.GetShotDelayFactor * 9);
          if (Ship = Player) or (CombatEvent.Target = Player) then PlayerCombatActive := True;
          Quantity := Events.Count;
          I := 0;
          while I < Quantity do
          begin
            CleanupEvent := Events[I];
            if CombatEvent.StepIndex < CleanupEvent.StepIndex then Break;
            Inc(I);
          end;
          if I >= Quantity then Events.Add(CombatEvent) else Events.Insert(I, CombatEvent);
          if Ship.ShipType <> t_Kling then
            Ship.ApplyItemDegradation(Weapon, idkUse, NextRandomUnitFloat(Ship.RandomState) * 2);
        end;
      end;
  end;
  if RecordFilm then
  begin
    CombatGroup := 0;
    WorkCount := Events.Count;
    for Index := 0 to WorkCount - 1 do
    begin
      CombatEvent := Events[Index];
      if CombatEvent.CombatGroup = 0 then
      begin
        Inc(CombatGroup);
        CombatEvent.CombatGroup := CombatGroup;
        MarkConnectedCombatEvents(Events, CombatEvent.Attacker, CombatGroup);
        MarkConnectedCombatEvents(Events, CombatEvent.Target, CombatGroup);
      end;
    end;
    for Index := 1 to CombatGroup do
    begin
      Quantity := 0;
      for K := 0 to WorkCount - 1 do
      begin
        CombatEvent := Events[K];
        if CombatEvent.CombatGroup = Index then Inc(Quantity);
      end;
      WorkSingle := 5;
      WorkScale := 170 / Quantity;
      for K := 0 to WorkCount - 1 do
      begin
        CombatEvent := Events[K];
        if CombatEvent.CombatGroup = Index then
        begin
          CombatEvent.StepIndex := Round(WorkSingle);
          WorkSingle := WorkSingle + WorkScale;
        end;
      end;
    end;
  end;
  WorkCount := Ships.Count;
  for Index := 0 to WorkCount - 1 do
  begin
    Ship := TShip(Ships[Index]);
    if not Ship.InHyperspace then
      if Ship.Order <> soFollowShip then Ship.RebuildOrderMovementPath
      else
      begin
        Ship.ClearMovementPath;
        Ship.OrderDestination := Ship.Position;
        if Ship.GetEffectiveFollowMode = fmNear then
        begin
          Angle := HeadingDegreesToRadians(Abs(Integer((Ship.OrderTarget as TShip).Seed * Ship.Seed *
            Cardinal(Galaxy.CurrentTurn))) mod 360);
          WorkValue := Ship.CalculateFollowRadius;
          Ship.FollowPosition.X := Sin(Angle) * WorkValue;
          Ship.FollowPosition.Y := Cos(Angle) * (-WorkValue);
        end;
      end;
  end;
  if PlayerStar = Self then WorkCount := 200 else WorkCount := 10;
  ShipCount := Ships.Count;
  for PathStep := 0 to WorkCount - 1 do
    for K := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Ships[K]);
      if Ship.Order = soFollowShip then
      begin
        OtherShip := Ship.OrderTarget as TShip;
        if OtherShip.Order <> soFollowShip then
        begin
          if OtherShip.IsOnPlanet and (OtherShip.Order = soNone) then
            PointB := OtherShip.CurrentPlanet.GetPosition
          else if OtherShip.MovementPath.ActiveTail = nil then
            PointB := OtherShip.Position
          else PointB := OtherShip.MovementPath.ActiveTail.Position;
        end
        else PointB := OtherShip.OrderDestination;
        WorkValue := Ship.CalculateFollowRadius;
        if Ship.GetEffectiveFollowMode = fmNear then
        begin
          if (Ship is TTranclucator) and (Ship as TTranclucator).CanFollowOwnerInCurrentStar then
          begin
            Ship.OrderDestination := PointB;
            Distance := 0;
            WorkSingle := 0;
          end
          else
          begin
            PointB.X := PointB.X + Ship.FollowPosition.X;
            PointB.Y := PointB.Y + Ship.FollowPosition.Y;
            Distance := PointDistance(Ship.OrderDestination, PointB);
            WorkSingle := 0 - Distance;
          end;
        end
        else
        begin
          Distance := PointDistance(Ship.OrderDestination, PointB);
          WorkSingle := WorkValue - Distance;
        end;
        if PlayerStar = Self then WorkScale := Ship.MovementSpeed
        else WorkScale := Ship.MovementSpeedPerTurn;
        if Distance <> 0 then
          if WorkSingle <= 0 then
          begin
            WorkSingle := Math.Min(-WorkSingle, WorkScale) / Distance;
            Ship.OrderDestination.X := (PointB.X - Ship.OrderDestination.X) * WorkSingle + Ship.OrderDestination.X;
            Ship.OrderDestination.Y := (PointB.Y - Ship.OrderDestination.Y) * WorkSingle + Ship.OrderDestination.Y;
          end
          else
          begin
            WorkSingle := Math.Min(WorkSingle, WorkScale) / Distance;
            Ship.OrderDestination.X := (Ship.OrderDestination.X - PointB.X) * WorkSingle + Ship.OrderDestination.X;
            Ship.OrderDestination.Y := (Ship.OrderDestination.Y - PointB.Y) * WorkSingle + Ship.OrderDestination.Y;
          end;
      end;
    end;
  if RecordFilm then
    for K := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Ships[K]);
      if Ship.Order = soFollowShip then
      begin
        Distance := MapDiameter / 2;
        WorkSingle := (Ship.Position.X * Ship.Position.X) + (Ship.Position.Y * Ship.Position.Y);
        WorkScale := (Ship.OrderDestination.X * Ship.OrderDestination.X) + (Ship.OrderDestination.Y * Ship.OrderDestination.Y);
        if (Sqr(0.7 * Distance) <= WorkScale) and (WorkSingle < WorkScale) and
          ((TShip(Ship.OrderTarget).Position.X * TShip(Ship.OrderTarget).Position.X) + (TShip(Ship.OrderTarget).Position.Y * TShip(Ship.OrderTarget).Position.Y) <= WorkSingle) then
        begin
          WorkX := -Ship.Position.Y;
          WorkY := Ship.Position.X;
          PointB.X := Ship.OrderDestination.X - Ship.Position.X;
          PointB.Y := Ship.OrderDestination.Y - Ship.Position.Y;
          Angle := HeadingDegreesToRadians(Math.Min(50, (Sqrt(WorkSingle) - Distance / 2) / (Distance / 2) * 40 + 10));
          if WorkX * PointB.X + WorkY * PointB.Y < 0 then Angle := -Angle;
          X := Sin(Angle);
          Y := Cos(Angle);
          WorkX := PointB.X * Y - PointB.Y * X;
          WorkY := PointB.X * X + PointB.Y * Y;
          Ship.OrderDestination.X := Ship.Position.X + WorkX;
          Ship.OrderDestination.Y := Ship.Position.Y + WorkY;
        end;
      end;
    end;
  if RecordFilm then
  begin
    for K := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Ships[K]);
      if Ship.Order = soFollowShip then Ship.FollowPosition := Ship.Position;
    end;
    for PathStep := 1 to WorkCount - 1 do
      for K := 0 to ShipCount - 1 do
      begin
        Ship := TShip(Ships[K]);
        if (Ship.Order = soFollowShip) and (not (Ship is TTranclucator) or not TTranclucator(Ship).FollowOwner) then
        begin
          WorkScale := Ship.MovementSpeed;
          Distance := PointDistanceSquared(Ship.FollowPosition, Ship.OrderDestination);
          if Distance <> 0 then
          begin
            if Sqr(WorkScale) >= Distance then Ship.FollowPosition := Ship.OrderDestination
            else
            begin
              Distance := 1 / Sqrt(Distance) * WorkScale;
              Ship.FollowPosition.X := (Ship.OrderDestination.X - Ship.FollowPosition.X) * Distance + Ship.FollowPosition.X;
              Ship.FollowPosition.Y := (Ship.OrderDestination.Y - Ship.FollowPosition.Y) * Distance + Ship.FollowPosition.Y;
            end;
            RepelFollowOverlaps(Ship);
          end;
        end;
      end;
    for K := 0 to ShipCount - 1 do
    begin
      Ship := TShip(Ships[K]);
      if (Ship.Order = soFollowShip) and (not (Ship is TTranclucator) or not TTranclucator(Ship).FollowOwner) then
        Ship.OrderDestination := Ship.FollowPosition;
    end;
  end;
  WorkCount := Ships.Count;
  for Index := 0 to WorkCount - 1 do
  begin
    Ship := TShip(Ships[Index]);
    if Ship.Order = soFollowShip then
    begin
      if (Sqr(Ship.Position.X) + Sqr(Ship.Position.Y) > Sqr(SafeRadius)) and
        (Sqr(Ship.OrderDestination.X) + Sqr(Ship.OrderDestination.Y) < Sqr(SafeRadius)) then
      begin
        RayIntersectsOriginCircle(Ship.Position, Ship.OrderDestination, PointB, SafeRadius);
        WorkSingle := PointDistance(PointB, Ship.OrderDestination);
        WorkScale := HeadingDegreesToRadians(WorkSingle * 360 / (2 * Pi * SafeRadius));
        WorkSingle := ArcTan2(PointB.X, -PointB.Y);
        if HeadingDifferenceDegrees(RadiansToHeadingDegrees(WorkSingle),
          RadiansToHeadingDegrees(ArcTan2(Ship.Position.X - PointB.X, -(Ship.Position.Y - PointB.Y)))) < 0 then
          WorkSingle := WorkSingle + WorkScale
        else WorkSingle := WorkSingle - WorkScale;
        Ship.OrderDestination.X := Sin(WorkSingle) * (SafeRadius + 0.1);
        Ship.OrderDestination.Y := -Cos(WorkSingle) * (SafeRadius + 0.1);
      end;
      Ship.RebuildFollowMovementPath;
    end;
  end;
  WorkCount := Ships.Count;
  for Index := 0 to WorkCount - 1 do
  begin
    Ship := TShip(Ships[Index]);
    if (Ship.Order = soJump) and (Ship.ShipType = t_Ranger) and (Ship.MovementPath.ActiveHead <> nil) and
      (Sqr(Ship.Speed + 100) < PointDistanceSquared(Ship.MovementPath.ActiveHead.Position,
        Ship.MovementPath.ActiveTail.Position)) then
    begin
      OwnerShip := (Ship as TRanger).PartnerShip;
      if OwnerShip = nil then OwnerShip := Ship;
      for K := 0 to WorkCount - 1 do
      begin
        OtherShip := TShip(Ships[K]);
        if (OtherShip.Order = soJump) and (OtherShip.OrderTarget = Ship.OrderTarget) and
          (OtherShip.ShipType = t_Ranger) and (Ship <> OtherShip) and
          (((OtherShip as TRanger).PartnerShip = OwnerShip) or (OtherShip = OwnerShip)) and
          ((OtherShip.MovementPath.ActiveHead = nil) or
            (Sqr(OtherShip.Speed + 100) >= PointDistanceSquared(OtherShip.MovementPath.ActiveHead.Position,
              OtherShip.MovementPath.ActiveTail.Position))) and
          ((OtherShip.PickupTargets = nil) or (OtherShip.PickupTargets.Count <= 0)) and
          (PointDistanceSquared(Ship.Position, OtherShip.Position) <= 640000) then
        begin
          Angle := Abs(HeadingDifferenceDegrees(OtherShip.MovementDirection,
            RadiansToHeadingDegrees(ArcTan2(-Ship.Position.X, Ship.Position.Y))));
          if ((Angle >= 90) and (OtherShip.Speed >= 200)) or (Angle >= 175) then
          begin
            OtherShip.ClearMovementPath;
            if (Angle < 175) and (OtherShip.Speed >= 200) and (OtherShip.CurrentStar = PlayerStar) then
            begin
              Distance := 1 / Sqrt((Ship.Position.X * Ship.Position.X) + (Ship.Position.Y * Ship.Position.Y));
              PointB.X := Ship.Position.X * Distance * 10000 + OtherShip.Position.X;
              PointB.Y := Ship.Position.Y * Distance * 10000 + OtherShip.Position.Y;
              OtherShip.AppendTurningPath(PointB, False, 200);
            end;
            OtherShip.AppendHyperspaceTransitionPath(1);
            if OtherShip.MovementPath.ActiveTail <> nil then
              OtherShip.OrderDestination := OtherShip.MovementPath.ActiveTail.Position
            else OtherShip.OrderDestination := OtherShip.Position;
          end;
        end;
      end;
    end;
  end;
  if PlayerStar = Self then AvoidShipPathCollisions;
  if RecordFilm then
  begin
    ShipCount := Galaxy.JumpGates.Count;
    for Index := 0 to ShipCount - 1 do
    begin
      GateEntry := Galaxy.JumpGates[Index];
      GateEntry.UnresolvedFlag := True;
      StarOrGateFilm := PrimaryFilm.AddObject(0, GateEntry.Gate, 0, 0);
      GateEntry.FilmObject := StarOrGateFilm;
      PrimaryFilm.SetObjectPosition(StepIndex, StarOrGateFilm, GateEntry.Gate.Position);
      PrimaryFilm.SetObjectAngle(StepIndex, StarOrGateFilm, GateEntry.Gate.GetAngle);
      PrimaryFilm.SetGateState(StepIndex, StarOrGateFilm, 2);
      PrimaryFilm.CloseGate(StepIndex, StarOrGateFilm);
      PrimaryFilm.SetObjectText(StepIndex, StarOrGateFilm, GateEntry.Gate.GetText);
      PrimaryFilm.AttachObject(StepIndex, StarOrGateFilm);
    end;
  end;
  if RecordFilm then
    for Index := 0 to Galaxy.Holes.Count - 1 do
    begin
      Hole := THole(Galaxy.Holes[Index]);
      if Hole.Star1 = Self then
      begin
        ObjectFilm := PrimaryFilm.AddObject(Hole.Id, Hole.Graphic, 0, 0);
        Hole.FilmObject := ObjectFilm;
        PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Hole.Position1);
        if Galaxy.CurrentTurn = Hole.CreatedTurn then PrimaryFilm.SetHoleState(StepIndex, ObjectFilm, 1)
        else PrimaryFilm.SetHoleState(StepIndex, ObjectFilm, 0);
        PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
      end
      else if Hole.Star2 = Self then
      begin
        ObjectFilm := PrimaryFilm.AddObject(Hole.Id, Hole.Graphic, 0, 0);
        Hole.FilmObject := ObjectFilm;
        PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Hole.Position2);
        if Galaxy.CurrentTurn = Hole.CreatedTurn then PrimaryFilm.SetHoleState(StepIndex, ObjectFilm, 1)
        else PrimaryFilm.SetHoleState(StepIndex, ObjectFilm, 0);
        PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
      end;
    end;
  for Index := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[Index]);
    Planet.InitializeFilmState(StepIndex, RecordFilm);
  end;
  for Index := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[Index]);
    Asteroid.PrepareTurnMovement(StepIndex, RecordFilm);
  end;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[Index]);
    Ship.PrepareTurnMovement(StepIndex, RecordFilm);
  end;
  if RecordFilm then
  begin
    WorkCount := Items.Count;
    for Index := 0 to WorkCount - 1 do
    begin
      Item := TItem(Items[Index]);
      Item.FilmObject := PrimaryFilm.AddObject(Item.Id, Item.GetGraphObject, 0, 0);
      PrimaryFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
      PrimaryFilm.AttachObject(StepIndex, Item.FilmObject);
    end;
  end;
  if PlayerStar = Self then WorkCount := 200 else WorkCount := 10;
  DamageStep1 := Round(WorkCount / 5 * 1);
  DamageStep2 := Round(WorkCount / 5 * 2);
  DamageStep3 := Round(WorkCount / 5 * 3);
  // Also runs for off-screen simulation.
  PrimaryFilm.AdvanceObjects(StepIndex);
  Inc(StepIndex);
  if RecordFilm then
    if (not PlayerCombatActive) or ((Player.MovementPath.ActiveTail <> nil) and
      (Player.Speed * Player.Speed + 100 < PointDistanceSquared(Player.Position, Player.MovementPath.ActiveTail.Position))) or
      ((Player.Order = soLanding) and (Player.FilmAlphaStep <> 0)) then CameraPath := nil
    else
    begin
      CameraPath := TSPath.Create;
      CameraPath.AppendWaypoint(Player.Position, StepIndex);
    end;
  K := 0;
  while K < Items.Count do
  begin
    Item := TItem(Items[K]);
    if Sqr(Item.Position.X) + Sqr(Item.Position.Y) < (DamageRadius * DamageRadius) then
    begin
      ClearItemReferences(Item);
      Quantity := Events.Count;
      for I := 0 to Quantity - 1 do
      begin
        CleanupEvent := Events[I];
        if CleanupEvent.Target = Item then CleanupEvent.Target := nil;
      end;
      if RecordFilm then
      begin
        Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
        ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
        PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, nil, Item.FilmObject);
        PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, True, True);
        PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
        Item.GraphObject := nil;
        PendingFilmRemovals.Add(Item.FilmObject);
      end;
      Items.Delete(K);
      Item.Free;
    end
    else Inc(K);
  end;
  NearestShip := nil;
  NearestItem := nil;
  WorkSingle := 1e20;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[Index]);
    if Ship.PickupTargets <> nil then
      if Ship.CargoHook = nil then Ship.ClearPickupTargets
      else
      begin
        Item := TItem(Ship.PickupTargets[0]);
        WorkScale := PointDistanceSquared(Ship.Position, Item.Position);
        if WorkScale < WorkSingle then
        begin
          WorkSingle := WorkScale;
          NearestShip := Ship;
          NearestItem := Item;
        end;
      end;
  end;
  PlayerCombatActive := False;
  for PathStep := 0 to WorkCount - 1 do
  begin
    if PathStep and 3 = 0 then
    begin
      ShipCount := Asteroids.Count;
      for K := 0 to ShipCount - 1 do
      begin
        Asteroid := TAsteroid(Asteroids[K]);
        if (Asteroid.Position.X * Asteroid.Position.X) + (Asteroid.Position.Y * Asteroid.Position.Y) < Sqr(Radius * 0.7) then
        begin
          if RecordFilm then
          begin
            Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0));
            ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
            PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Asteroid.Position);
            PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, False, True);
            PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
          end;
          Asteroid.Respawn;
          Continue;
        end;
        Planet := nil;
        Quantity := Planets.Count;
        for I := 0 to Quantity - 1 do
        begin
          Planet := TPlanet(Planets[I]);
          PointB := Planet.GetPosition;
          X := PointB.X;
          Y := PointB.Y;
          ImpactX := Asteroid.Position.X;
          ImpactY := Asteroid.Position.Y;
          if Planet.GraphicRadius * Planet.GraphicRadius >= (X - ImpactX) * (X - ImpactX) + (Y - ImpactY) * (Y - ImpactY) then Break;
        end;
        if I < Planets.Count then
        begin
          Planet.HandleAsteroidCollision(Asteroid);
          if RecordFilm then
          begin
            Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0));
            ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
            PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Asteroid.Position);
            PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, False, True);
            PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
          end;
          if Items.Count < 8 then
          begin
            Quantity := Trunc(Asteroid.MineralCount / 5);
            Item := TGoods.Create;
            (Item as TGoods).Init(t_Minerals, Quantity);
            (Item as TGoods).NaturalFlag := True;
            Item.Position := Asteroid.Position;
            MovingDrop := AllocEC(SizeOf(TMovingDropItemEntry));
            MovingDrop.Payload := Item;
            MovingDrop.SourceShipId := 0;
            MovingDrop.InsertedIntoStar := False;
            MovingDrop.UseFlag := False;
            Distance := SeededRandomIntRange(50, 150, GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Item.Id);
            if (PlayerStar = Self) and (WorkCount - 20 < PathStep) then Distance := 5;
            Angle := ArcTan2(Asteroid.Position.X - Planet.GetPosition.X,
              -(Asteroid.Position.Y - Planet.GetPosition.Y)) +
              (SeededRandomUnitFloat(GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Item.Id) * 1.2 - 0.6);
            MovingDrop.Destination.X := Sin(Angle) * Distance + Item.Position.X;
            MovingDrop.Destination.Y := Item.Position.Y - Cos(Angle) * Distance;
            MovingDropItems.Add(MovingDrop);
          end;
          Asteroid.Respawn;
          Continue;
        end;
        Ship := nil;
        Quantity := Ships.Count;
        for I := 0 to Quantity - 1 do
        begin
          Ship := TShip(Ships[I]);
          if Ship.InNormalSpace and not Ship.IsHullDestroyed and
            (PointDistanceSquared(Asteroid.Position, Ship.Position) <= 2500) and
            ((Ship = Player) or (Ship.ScriptShip = nil)) then Break;
        end;
        if I < Ships.Count then
        begin
          Damage := Ship.ApplyAsteroidImpactDamage(Asteroid, DamageColor);
          if RecordFilm then
          begin
            Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0));
            ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
            PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Asteroid.Position);
            PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, nil, Ship.FilmObject);
            PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True);
            PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
          end;
          if Ship.IsHullDestroyed then
          begin
            ClearShipCombatTargets(Ship);
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
              if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
            end;
          end;
          Quantity := Trunc(Asteroid.MineralCount / 4);
          Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, Asteroid.Id * GenerationSeed * Cardinal(Galaxy.CurrentTurn)));
          J := 0;
          while Quantity > 0 do
          begin
            if (Quantity < 10) or (J >= 3) then WorkValue := Quantity
            else WorkValue := Round((SeededRandomUnitFloat(GenerationSeed * Cardinal(Galaxy.CurrentTurn) * Asteroid.Id) * 0.2 + 0.55) * Quantity);
            Dec(Quantity, WorkValue);
            Item := TGoods.Create;
            (Item as TGoods).Init(t_Minerals, WorkValue);
            (Item as TGoods).NaturalFlag := True;
            Item.Position := Asteroid.Position;
            MovingDrop := AllocEC(SizeOf(TMovingDropItemEntry));
            MovingDrop.Payload := Item;
            MovingDrop.SourceShipId := 0;
            MovingDrop.InsertedIntoStar := False;
            MovingDrop.UseFlag := False;
            MovingDropItems.Add(MovingDrop);
            Inc(J);
          end;
          WorkSingle := 3.1415926;
          if J > 1 then WorkSingle := 6.2831852 / J;
          for EntryIndex := 0 to J - 1 do
          begin
            MovingDrop := MovingDropItems[MovingDropItems.Count - 1 - EntryIndex];
            Distance := SeededRandomIntRange(50, 150, (MovingDrop.Payload as TItem).Id * (GenerationSeed * Cardinal(Galaxy.CurrentTurn)));
            if (PlayerStar = Self) and (WorkCount - 20 < PathStep) then Distance := 5;
            WorkScale := SeededRandomUnitFloat((MovingDrop.Payload as TItem).Id * (GenerationSeed * Cardinal(Galaxy.CurrentTurn))) * 0.3 - 0.15;
            // These repeated seeds and unequal angle multipliers are native behavior.
            MovingDrop.Destination.X := (MovingDrop.Payload as TItem).Position.X +
              Sin(SeededRandomUnitFloat((MovingDrop.Payload as TItem).Id * (GenerationSeed * Cardinal(Galaxy.CurrentTurn))) * (Angle + WorkScale) * 113) * Distance;
            MovingDrop.Destination.Y := (MovingDrop.Payload as TItem).Position.Y -
              Cos(SeededRandomUnitFloat((MovingDrop.Payload as TItem).Id * (GenerationSeed * Cardinal(Galaxy.CurrentTurn))) * (Angle + WorkScale) * 517) * Distance;
            Angle := Angle + WorkSingle;
          end;
          Asteroid.Respawn;
        end;
      end;
    end;
    ShipCount := Events.Count;
    for K := 0 to ShipCount - 1 do
    begin
      CombatEvent := Events[K];
      if (CombatEvent.Weapon <> nil) and TWeapon(CombatEvent.Weapon).EquippedFlag and
        (CombatEvent.StepIndex = PathStep) and (CombatEvent.Attacker <> nil) and (CombatEvent.Target <> nil) then
      begin
        if CombatEvent.Target is TShip then
        begin
          if not (CombatEvent.Target as TShip).IsHullDestroyed then
          begin
            OwnerShip := TShip(CombatEvent.Attacker);
            TargetShip := CombatEvent.Target as TShip;
            if (TWeapon(CombatEvent.Weapon).ItemType <> t_SubmesonicGun) and (TWeapon(CombatEvent.Weapon).ItemType <> t_FieldAnnihilator) and
              (TWeapon(CombatEvent.Weapon).ItemType <> t_AbsoluteMatrix) and (TWeapon(CombatEvent.Weapon).ItemType <> t_HellWave) then
            begin
              if Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, TargetShip.Position) then
              begin
                CombatOccurred := True;
                if (Player = TargetShip) or (CombatEvent.Attacker = Player) then
                begin
                  PlayerCombatActive := True;
                  if CombatEvent.Attacker = Player then PrimaryFilm.AddCameraEvent(StepIndex, Player.Position, TargetShip.Position, 1)
                  else PrimaryFilm.AddCameraEvent(StepIndex, Player.Position, TShip(CombatEvent.Attacker).Position, 1);
                end;
                Damage := TargetShip.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), -1, DamageColor);
                if RecordFilm then
                begin
                  CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
                  CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
                  PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, TargetShip.FilmObject);
                  PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), DamageColor, Damage, TargetShip.IsHullDestroyed, True);
                  PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));

                end;
                if TargetShip.IsHullDestroyed then
                begin
                  ClearShipCombatTargets(TargetShip);
                  Quantity := Events.Count;
                  for I := 0 to Quantity - 1 do
                  begin
                    CleanupEvent := Events[I];
                    if TargetShip = CleanupEvent.Target then CleanupEvent.Target := nil;
                    if TargetShip = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                  end;
                end;
              end;
            end
            else
            begin
              if TWeapon(CombatEvent.Weapon).ItemType = t_SubmesonicGun then
              begin
                if Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, TargetShip.Position) then
                begin
                  CombatOccurred := True;
                  if (Player = TargetShip) or (CombatEvent.Attacker = Player) then
                  begin
                    PlayerCombatActive := True;
                    if CameraPath <> nil then
                      CameraPath.AppendWaypoint(MakePointF((TargetShip.Position.X + TShip(CombatEvent.Attacker).Position.X) / 2,
                        (TargetShip.Position.Y + TShip(CombatEvent.Attacker).Position.Y) / 2), StepIndex + 25);
                  end;
                  Damage := TargetShip.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), -1, DamageColor);
                  if RecordFilm then
                  begin
                    CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
                    CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
                    PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, TargetShip.FilmObject);
                    PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), DamageColor, Damage, TargetShip.IsHullDestroyed, True);
                    PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));

                  end;
                  if TargetShip.IsHullDestroyed then
                  begin
                    ClearShipCombatTargets(TargetShip);
                    Quantity := Events.Count;
                    for I := 0 to Quantity - 1 do
                    begin
                      CleanupEvent := Events[I];
                      if TargetShip = CleanupEvent.Target then CleanupEvent.Target := nil;
                      if TargetShip = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                    end;
                  end;
                  J := Ships.Count;
                  for EntryIndex := 0 to J - 1 do
                  begin
                    Ship := TShip(Ships[EntryIndex]);
                    if (Ship <> CombatEvent.Attacker) and (Ship <> TargetShip) and Ship.InNormalSpace and not Ship.IsHullDestroyed then
                    begin
                      Distance := PointDistanceSquared(Ship.Position, TargetShip.Position);
                      if Sqr(WeaponInfo[TWeapon(CombatEvent.Weapon).ItemType].SplashRadius) >= Distance then
                      begin
                        Damage := Ship.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), Sqrt(Distance), DamageColor);
                        if RecordFilm then
                        begin
                          Effect := TWeaponSE.Create('Weapon.Nine', Classes.Point(0, 0));
                          ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                          PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, TargetShip.FilmObject, Ship.FilmObject);
                          PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True);
                          PrimaryFilm.AttachObject(StepIndex, ObjectFilm);

                        end;
                        if Ship.IsHullDestroyed then
                        begin
                          ClearShipCombatTargets(Ship);
                          Quantity := Events.Count;
                          for I := 0 to Quantity - 1 do
                          begin
                            CleanupEvent := Events[I];
                            if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                            if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
              end
              else if TWeapon(CombatEvent.Weapon).ItemType = t_FieldAnnihilator then
              begin
                if Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, TargetShip.Position) then
                begin
                  CombatOccurred := True;
                  if (Player = TargetShip) or (CombatEvent.Attacker = Player) then
                  begin
                    PlayerCombatActive := True;
                    if CameraPath <> nil then
                      CameraPath.AppendWaypoint(MakePointF((TargetShip.Position.X + TShip(CombatEvent.Attacker).Position.X) / 2,
                        (TargetShip.Position.Y + TShip(CombatEvent.Attacker).Position.Y) / 2), StepIndex + 25);
                  end;
                  Damage := TargetShip.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), -1, DamageColor);
                  if RecordFilm then
                  begin
                    CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
                    CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
                    PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, TargetShip.FilmObject);
                    PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), DamageColor, Damage, TargetShip.IsHullDestroyed, True);
                    PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));

                  end;
                  if TargetShip.IsHullDestroyed then
                  begin
                    ClearShipCombatTargets(TargetShip);
                    Quantity := Events.Count;
                    for I := 0 to Quantity - 1 do
                    begin
                      CleanupEvent := Events[I];
                      if TargetShip = CleanupEvent.Target then CleanupEvent.Target := nil;
                      if TargetShip = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                    end;
                  end;
                  J := Ships.Count;
                  for EntryIndex := 0 to J - 1 do
                  begin
                    Ship := TShip(Ships[EntryIndex]);
                    if (Ship <> TargetShip) and Ship.InNormalSpace and not Ship.IsHullDestroyed then
                    begin
                      Distance := PointDistanceSquared(Ship.Position, TargetShip.Position);
                      if Sqr(WeaponInfo[TWeapon(CombatEvent.Weapon).ItemType].SplashRadius) >= Distance then
                      begin
                        Damage := Ship.ApplyWeaponHit(OwnerShip, TWeapon(CombatEvent.Weapon), Sqrt(Distance), DamageColor);
                        if RecordFilm then
                        begin
                          Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
                          ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                          PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, TargetShip.FilmObject, Ship.FilmObject);
                          PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True);
                          PrimaryFilm.AttachObject(StepIndex, ObjectFilm);

                        end;
                        // Compares the splash victim with the saved owner here, clearing every attacker if the owner died.
                        if Ship.IsHullDestroyed then
                        begin
                          ClearShipCombatTargets(Ship);
                          Quantity := Events.Count;
                          for I := 0 to Quantity - 1 do
                          begin
                            CleanupEvent := Events[I];
                            if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                            if Ship = OwnerShip then CleanupEvent.Attacker := nil;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
              end
              else if TWeapon(CombatEvent.Weapon).ItemType = t_AbsoluteMatrix then
              begin
                FirstShot := True;
                J := Ships.Count;
                for EntryIndex := 0 to J - 1 do
                begin
                  Ship := TShip(Ships[EntryIndex]);
                  if (Ship <> CombatEvent.Attacker) and Ship.InNormalSpace and not Ship.IsHullDestroyed and
                    (Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 >= PointDistanceSquared(Ship.Position, TShip(CombatEvent.Attacker).Position)) then
                  begin
                    if Ship = CombatEvent.Target then Damage := Ship.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), -1, DamageColor)
                    else Damage := Ship.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), PointDistance(TShip(CombatEvent.Attacker).Position, Ship.Position), DamageColor);
                    if RecordFilm then
                    begin
                      Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
                      ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                      PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, TShip(CombatEvent.Attacker).FilmObject, Ship.FilmObject);
                      PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, FirstShot);
                      PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
                      FirstShot := False;
                    end;
                    if Ship.IsHullDestroyed then
                    begin
                      ClearShipCombatTargets(Ship);
                      Quantity := Events.Count;
                      for I := 0 to Quantity - 1 do
                      begin
                        CleanupEvent := Events[I];
                        if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                        if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                      end;
                    end;
                  end;
                end;
              end
              else if TWeapon(CombatEvent.Weapon).ItemType = t_HellWave then
              begin
                if RecordFilm then
                begin
                  Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
                  ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                  PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, TShip(CombatEvent.Attacker).FilmObject, TShip(CombatEvent.Attacker).FilmObject);
                  PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, False, True);
                  PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
                end;
                J := Ships.Count;
                for EntryIndex := 0 to J - 1 do
                begin
                  Ship := TShip(Ships[EntryIndex]);
                  if (Ship <> CombatEvent.Attacker) and Ship.InNormalSpace and not Ship.IsHullDestroyed and
                    (Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 >= PointDistanceSquared(Ship.Position, TShip(CombatEvent.Attacker).Position)) then
                  begin
                    if Ship = CombatEvent.Target then Damage := Ship.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), -1, DamageColor)
                    else Damage := Ship.ApplyWeaponHit(TShip(CombatEvent.Attacker), TWeapon(CombatEvent.Weapon), PointDistance(TShip(CombatEvent.Attacker).Position, Ship.Position), DamageColor);
                    if RecordFilm then
                    begin
                      Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
                      ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                      PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, TShip(CombatEvent.Attacker).FilmObject, Ship.FilmObject);
                      PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True);
                      PrimaryFilm.AttachObject(StepIndex, ObjectFilm);

                    end;
                    if Ship.IsHullDestroyed then
                    begin
                      ClearShipCombatTargets(Ship);
                      Quantity := Events.Count;
                      for I := 0 to Quantity - 1 do
                      begin
                        CleanupEvent := Events[I];
                        if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                        if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                      end;
                    end;
                  end;
                end;
              end
            end;
          end;
        end
        else
          begin
          if (CombatEvent.Attacker = Player) and (CombatEvent.Target is TGoods) and
            (CombatEvent.Target as TGoods).NaturalFlag and
            (Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, (CombatEvent.Target as TItem).Position)) then
          begin
            Item := CombatEvent.Target as TItem;
            if RecordFilm then
            begin
              CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
              CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
              PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, (CombatEvent.Target as TItem).FilmObject);
              PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 0, 0, True, True);
              if Item is TArtefactBomb then PrimaryFilm.SetDestructionEffect(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 1)
              else PrimaryFilm.SetDestructionEffect(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 3);
              PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));
            end;
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if CleanupEvent.Target = Item then CleanupEvent.Target := nil;
            end;
            ClearItemReferences(Item);
            Quantity := (Item as TGoods).Quantity;
            if Quantity >= 5 then DropMinerals(Trunc(Quantity * 0.8 / WeaponInfo[TWeapon(CombatEvent.Weapon).ItemType].MineralDivisor), Item.Position, GenerationSeed * Item.Id);
            if RecordFilm then
            begin
              CombatEvent.DestroyedTargetFilm := Item.FilmObject;
              Item.GraphObject := nil;
              Items.Delete(Items.IndexOf(Item));
              Item.Free;
            end
            else
            begin
              Items.Delete(Items.IndexOf(Item));
              Item.Free;
            end;
          end
          else if (CombatEvent.Target is TItem) and
            (Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, (CombatEvent.Target as TItem).Position)) then
          begin
            Item := CombatEvent.Target as TItem;
            if RecordFilm then
            begin
              CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
              CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
              PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, (CombatEvent.Target as TItem).FilmObject);
              PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 0, 0, True, True);
              if Item is TArtefactBomb then PrimaryFilm.SetDestructionEffect(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 1)
              else PrimaryFilm.SetDestructionEffect(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 3);
              PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));
            end;
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if CleanupEvent.Target = Item then CleanupEvent.Target := nil;
            end;
            ClearItemReferences(Item);
            if Item is TArtefactBomb then
            begin
              J := Ships.Count;
              for EntryIndex := 0 to J - 1 do
              begin
                Ship := TShip(Ships[EntryIndex]);
                if Ship.InNormalSpace and not Ship.IsHullDestroyed then
                begin
                  Distance := PointDistanceSquared(Ship.Position, Item.Position);
                  if Distance <= 62500 then
                  begin
                    Damage := Round(RemapClampedAlternate(Distance, 0, 62500, 800, 400));
                    Ship.Hull.HullPoints := Math.Max(Ship.Hull.HullPoints - Damage, 0);
                    if (Ship = KlingMotherShip) and (Ship.Hull.HullPoints <= 0) then Ship.Hull.HullPoints := 1;
                    if Ship.IsHullDestroyed and (Player <> nil) then
                    begin
                      Player.ProcessShipDestructionQuests(Ship);
                      if Ship.OwnerId = oiKling then Ship.CurrentStar.UpdateControlFaction;
                      if Player.CurrentStar = Ship.CurrentStar then
                      begin
                        Player.RecordShipKill(Ship);
                        Player.UpdateRelationsAfterShipKill(Ship);
                      end;
                    end;
                    Ship.RefreshDerivedStats;
                    DamageColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
                    if RecordFilm then
                    begin
                      Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
                      ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                      PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, Ship.FilmObject, Ship.FilmObject);
                      PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True);
                      PrimaryFilm.AttachObject(StepIndex, ObjectFilm);

                    end;
                    if Ship.IsHullDestroyed then
                    begin
                      ClearShipCombatTargets(Ship);
                      Quantity := Events.Count;
                      for I := 0 to Quantity - 1 do
                      begin
                        CleanupEvent := Events[I];
                        if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                        if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                      end;
                    end;
                  end;
                end;
              end;
            end
            else if (Item is TUselessItem) and (TUselessItem(Item).ConfigBlockName = 'ExampleAsteroid') then
                DropMinerals(SeededRandomIntRange(20, 30, GenerationSeed * Item.Id), Item.Position, GenerationSeed * Item.Id);
            if RecordFilm then
            begin
              CombatEvent.DestroyedTargetFilm := Item.FilmObject;
              Item.GraphObject := nil;
              Items.Delete(Items.IndexOf(Item));
              Item.Free;
            end
            else
            begin
              Items.Delete(Items.IndexOf(Item));
              Item.Free;
            end;
          end
          else if (CombatEvent.Target is TAsteroid) and
            (Sqr(TWeapon(CombatEvent.Weapon).Range) * 1.3 > PointDistanceSquared(TShip(CombatEvent.Attacker).Position, (CombatEvent.Target as TAsteroid).Position)) then
          begin
            Asteroid := CombatEvent.Target as TAsteroid;
            if RecordFilm then
            begin
              CombatEvent.Effect := TWeaponSE.Create(GetWeaponResourceName(TWeapon(CombatEvent.Weapon).ItemType), Classes.Point(0, 0));
              CombatEvent.EffectFilm := PrimaryFilm.AddObject(0, CombatEvent.Effect, 0, 0);
              PrimaryFilm.SetWeaponEndpoints(StepIndex, TEFilmObj(CombatEvent.EffectFilm), TShip(CombatEvent.Attacker).FilmObject, nil);
              PrimaryFilm.SetObjectPosition(StepIndex, TEFilmObj(CombatEvent.EffectFilm), Asteroid.Position);
              PrimaryFilm.SetDestructionEffect(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 2);
              PrimaryFilm.SetWeaponHit(StepIndex, TEFilmObj(CombatEvent.EffectFilm), 0, 0, False, True);
              PrimaryFilm.AttachObject(StepIndex, TEFilmObj(CombatEvent.EffectFilm));
              Effect := TWeaponSE.Create('Weapon.Asteroid', Classes.Point(0, 0));
              ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
              PrimaryFilm.SetObjectPosition(StepIndex, ObjectFilm, Asteroid.Position);
              PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, False, True);
              PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
            end;
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if CleanupEvent.Target = Asteroid then CleanupEvent.Target := nil;
            end;
            DropMinerals(Trunc(Asteroid.MineralCount / WeaponInfo[TWeapon(CombatEvent.Weapon).ItemType].MineralDivisor), Asteroid.Position, GenerationSeed * Asteroid.Id);
            Asteroid.Respawn;
          end;
          end;
      end;
    end;
    ShipCount := MovingDropItems.Count;
    for K := 0 to ShipCount - 1 do
    begin
      MovingDrop := MovingDropItems[K];
      if MovingDrop.Payload <> nil then
        if MovingDrop.Payload is TItem then
        begin
          Item := MovingDrop.Payload as TItem;
          if not MovingDrop.InsertedIntoStar then
          begin
            if (Item is TArtefactTranclucator) and MovingDrop.UseFlag then
            begin
              StoredTranclucator := (Item as TArtefactTranclucator).Ship as TTranclucator;
              (Item as TArtefactTranclucator).Ship := nil;
              StoredTranclucator.CurrentStar := Self;
              Ships.Add(StoredTranclucator);
              StoredTranclucator.Position := Item.Position;
              StoredTranclucator.MovementDirection := 0;
              Item.Free;
              MovingDrop.Payload := StoredTranclucator;
              MovingDrop.InsertedIntoStar := True;
              if RecordFilm then
              begin
                StoredTranclucator.FilmObject := PrimaryFilm.AddObject(StoredTranclucator.Id, StoredTranclucator.Graphic, 0, 0);
                // The original records the star's position here, not the launched ship's.
                PrimaryFilm.SetObjectPosition(StepIndex, StoredTranclucator.FilmObject, Position);
                PrimaryFilm.SetObjectAngle(StepIndex, StoredTranclucator.FilmObject, 0);
                PrimaryFilm.SetObjectAlpha(StepIndex, StoredTranclucator.FilmObject, 255);
                PrimaryFilm.AttachObject(StepIndex, StoredTranclucator.FilmObject);
              end;
            end
            else
          begin
            Items.Add(Item);
            MovingDrop.InsertedIntoStar := True;
            if RecordFilm then
            begin
              Item.FilmObject := PrimaryFilm.AddObject(Item.Id, Item.GetGraphObject, 0, 0);
              PrimaryFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
              PrimaryFilm.AttachObject(StepIndex, Item.FilmObject);
            end;
          end;
          end
          else
          begin
            Item.Position.X := (MovingDrop.Destination.X - Item.Position.X) / (WorkCount - PathStep) + Item.Position.X;
            Item.Position.Y := (MovingDrop.Destination.Y - Item.Position.Y) / (WorkCount - PathStep) + Item.Position.Y;
            if RecordFilm then PrimaryFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
            if (DamageRadius * DamageRadius) > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then
            begin
              if RecordFilm then
              begin
                Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
                ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, nil, Item.FilmObject);
                PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, True, True);
                PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
                Item.GraphObject := nil;
                PendingFilmRemovals.Add(Item.FilmObject);
              end;
              Items.Delete(Items.IndexOf(Item));
              Item.Free;
              MovingDrop.Payload := nil;
            end;
          end;
        end
        else
        begin
          TargetShip := MovingDrop.Payload as TShip;
          TargetShip.Position.X := (MovingDrop.Destination.X - TargetShip.Position.X) / (WorkCount - PathStep) + TargetShip.Position.X;
          TargetShip.Position.Y := (MovingDrop.Destination.Y - TargetShip.Position.Y) / (WorkCount - PathStep) + TargetShip.Position.Y;
          if RecordFilm then PrimaryFilm.SetObjectPosition(StepIndex, TargetShip.FilmObject, TargetShip.Position);
        end;
    end;
    for Index := 0 to Planets.Count - 1 do
    begin
      Planet := TPlanet(Planets[Index]);
      Planet.AdvanceOrbitStep(StepIndex, RecordFilm);
    end;
    for Index := 0 to Asteroids.Count - 1 do
    begin
      Asteroid := TAsteroid(Asteroids[Index]);
      Asteroid.AdvanceOrbitStep(StepIndex, RecordFilm);
    end;
    if WorkCount shr 2 = PathStep then
    begin
      Index := 0;
      while Index < Items.Count do
      begin
        Item := TItem(Items[Index]);
        if Item.DestroyFlag <> 0 then
        begin
          if RecordFilm then
          begin
            Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
            ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
            PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, Item.FilmObject, Item.FilmObject);
            PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, True, True);
            if Abs(Item.DestroyFlag) = 1 then PrimaryFilm.SetDestructionEffect(StepIndex, ObjectFilm, 3)
            else PrimaryFilm.SetDestructionEffect(StepIndex, ObjectFilm, 1);
            PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
          end;
          Quantity := Events.Count;
          for I := 0 to Quantity - 1 do
          begin
            CleanupEvent := Events[I];
            if CleanupEvent.Target = Item then CleanupEvent.Target := nil;
          end;
          ClearItemReferences(Item);
          if Abs(Item.DestroyFlag) > 1 then
          begin
            J := Ships.Count;
            for EntryIndex := 0 to J - 1 do
            begin
              Ship := TShip(Ships[EntryIndex]);
              if Ship.InNormalSpace and not Ship.IsHullDestroyed then
              begin
                Distance := PointDistanceSquared(Ship.Position, Item.Position);
                if Distance <= 62500 then
                begin
                  if Abs(Item.DestroyFlag) = 2 then Damage := 600 else Damage := Abs(Item.DestroyFlag);
                  Ship.Hull.HullPoints := Math.Max(Ship.Hull.HullPoints - Damage, 0);
                  if Ship.ScriptShip <> nil then TScriptShip(Ship.ScriptShip).Hit := True;
                  if (Ship = KlingMotherShip) and (Ship.Hull.HullPoints <= 0) then Ship.Hull.HullPoints := 1;
                  if Ship.IsHullDestroyed and (Player <> nil) then Player.ProcessShipDestructionQuests(Ship);
                  Ship.RefreshDerivedStats;
                  DamageColor := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
                  if RecordFilm then
                  begin
                    Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
                    ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
                    PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, Ship.FilmObject, Ship.FilmObject);
                    if Item.DestroyFlag > 0 then PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, DamageColor, Damage, Ship.IsHullDestroyed, True)
                    else PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, Ship.IsHullDestroyed, True);
                    PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
                  end;
                  if Ship.IsHullDestroyed then
                  begin
                    ClearShipCombatTargets(Ship);
                    Quantity := Events.Count;
                    for I := 0 to Quantity - 1 do
                    begin
                      CleanupEvent := Events[I];
                      if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
                      if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
                    end;
                  end;
                end;
              end;
            end;
          end;
          if RecordFilm then
          begin
            PendingFilmRemovals.Add(Item.FilmObject);
            Item.GraphObject := nil;
            Items.Delete(Items.IndexOf(Item));
            Item.Free;
            Dec(Index);
          end
          else
          begin
            Items.Delete(Items.IndexOf(Item));
            Item.Free;
            Dec(Index);
          end;
        end;
        Inc(Index);
      end;
      for Index := 0 to Ships.Count - 1 do
      begin
        Ship := TShip(Ships[Index]);
        if Ship.InNormalSpace and ((Ship <> Player) or (CurrentScreenId = screenStarMap)) then
          for I := 0 to Ship.Inventory.Count - 1 do
          begin
            Item := TItem(Ship.Inventory[I]);
            if Item.DestroyFlag <> 0 then
            begin
              while Ship.DockedTo <> nil do Ship := Ship.DockedTo;
              Ship.DestroyKind := 1;
              Break;
            end;
          end;
      end;
    end;
    Index := 0;
    while Index < Ships.Count do
    begin
      Ship := TShip(Ships[Index]);
      if Ship.IsHullDestroyed then
      begin
        Inc(Index);
        Continue;
      end;
      if (Ship.DestroyKind <> 0) and (WorkCount shr 2 = PathStep) and
        ((Ship <> Player) or (CurrentScreenId = screenStarMap)) then
      begin
        Ship.Hull.HullPoints := 0;
        if Ship.IsHullDestroyed and (Player <> nil) then Player.ProcessShipDestructionQuests(Ship);
        Ship.RefreshDerivedStats;
        if RecordFilm and (Ship.FilmObject <> nil) then
        begin
          Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
          ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
          PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, Ship.FilmObject, Ship.FilmObject);
          PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, 0, 0, Ship.IsHullDestroyed, True);
          PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
        end;
        ClearShipCombatTargets(Ship);
        Quantity := Events.Count;
        for I := 0 to Quantity - 1 do
        begin
          CleanupEvent := Events[I];
          if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
          if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
        end;
        Inc(Index);
        Continue;
      end;
      if ((PathStep = DamageStep1) or (PathStep = DamageStep2) or (PathStep = DamageStep3)) and
        not Ship.IsHullDestroyed and Ship.InNormalSpace then
      begin
        Distance := Sqr(Ship.Position.X) + Sqr(Ship.Position.Y);
        if (DamageRadius * DamageRadius) > Distance then
        begin
          CombatOccurred := True;
          if Ship = Player then PlayerCombatActive := True;
          if Ship.ShipType = t_Kling then WorkSingle := Math.Max((1 - Sqrt(Distance) / DamageRadius) * 30, 1)
          else WorkSingle := Math.Max((1 - Sqrt(Distance) / DamageRadius) * 100, 1);
          Ship.Hull.HullPoints := Math.Max(Ship.Hull.HullPoints - Round(WorkSingle), 0);
          if Ship.OwnerId = oiKling then
          begin
            if (Ship = KlingMotherShip) and (Ship.Hull.HullPoints <= 0) then Ship.Hull.HullPoints := 1;
            if Ship.IsHullDestroyed and (Player.CurrentStar = Ship.CurrentStar) and Player.InNormalSpace then
              Player.RechargeTransmittersFromKlissan(Ship);
          end;
          if Ship.IsHullDestroyed and (Player <> nil) then Player.ProcessShipDestructionQuests(Ship);
          Ship.FuelTanks.Fuel := Math.Min(Ship.FuelTanks.Fuel + 5, Ship.FuelTanks.Capacity);
          Ship.RefreshDerivedStats;
          if RecordFilm then
          begin
            Effect := TWeaponSE.Create('Weapon.Star', Classes.Point(0, 0));
            ObjectFilm := PrimaryFilm.AddObject(0, Effect, 0, 0);
            PrimaryFilm.SetWeaponEndpoints(StepIndex, ObjectFilm, Ship.FilmObject, Ship.FilmObject);
            PrimaryFilm.SetWeaponHit(StepIndex, ObjectFilm, CurrentPixelFormat.PackRgbBytes(255, 255, 255), Round(WorkSingle), Ship.IsHullDestroyed, True);
            PrimaryFilm.AttachObject(StepIndex, ObjectFilm);
          end;
          if Ship.IsHullDestroyed then
          begin
            ClearShipCombatTargets(Ship);
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if Ship = CleanupEvent.Target then CleanupEvent.Target := nil;
              if Ship = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
            end;
            Inc(Index);
            Continue;
          end;
        end;
      end;
      if (Ship.PickupTargets <> nil) and (Ship.CargoHook <> nil) then
      begin
        Target := TObject(Ship.PickupTargets[0]);
        if Target is TShip then
        begin
          TargetShip := Target as TShip;
          Distance := PointDistance(TargetShip.Position, Ship.Position);
          if Distance < 5 then
          begin
            HandleObjectLeavingStar(TargetShip);
            if TargetShip is TTranclucator then
            begin
              Artefact := TArtefactTranclucator.Create;
              Artefact.Init(TargetShip.OwnerId, Ship, TargetShip);
              Ship.Artefacts.Add(Artefact);
            end;
            Ship.RefreshDerivedStats;
            Quantity := Ships.Count;
            for I := 0 to Quantity - 1 do
            begin
              OtherShip := TShip(Ships[I]);
              OtherShip.RemoveQueuedPickupItem(TargetShip);
            end;
            ClearShipCombatTargets(TargetShip);
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if TargetShip = CleanupEvent.Target then CleanupEvent.Target := nil;
              if TargetShip = CleanupEvent.Attacker then CleanupEvent.Attacker := nil;
            end;
            if RecordFilm then PrimaryFilm.DetachObject(StepIndex, TargetShip.FilmObject);
            TargetShip.Hull.HullPoints := 0;
          end
          else
          begin
            Distance := Distance - (4 - RemapClamped(Distance, 0, 150, 1, 3));
            Angle := ArcTan2(TargetShip.Position.X - Ship.Position.X, -(TargetShip.Position.Y - Ship.Position.Y));
            TargetShip.Position := MakePointF(Sin(Angle) * Distance + Ship.Position.X, Ship.Position.Y - Cos(Angle) * Distance);
            if RecordFilm then PrimaryFilm.SetObjectPosition(StepIndex, TargetShip.FilmObject, TargetShip.Position);
          end;
        end
        else
        begin
          Item := Target as TItem;
          Distance := PointDistance(Item.Position, Ship.Position);
          if Distance < 5 then
          begin
            Ship.ApplyItemDegradation(Ship.CargoHook, idkUse, NextRandomIntRange(2, 4, Ship.RandomState));
            Items.Delete(Items.IndexOf(Item));
            if Item is TArtefact then
            begin
              (Item as TEquipment).EquippedFlag := False;
              Ship.Artefacts.Add(Item);
              if Item is TArtefactTranclucator then
                ((Item as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Ship;
            end
            else if Item is TProtoplasm then
            begin
              TProtoplasm(Item).DropFlag := 0;
              if not RecordFilm then Item.ReleaseGraphObject
              else
              begin
                PendingFilmRemovals.Add(Item.FilmObject);
                Item.GraphObject := nil;
              end;
              (Item as TEquipment).EquippedFlag := False;
              Quantity := Ship.Inventory.Count;
              I := 0;
              while I < Quantity do
              begin
                if TItem(Ship.Inventory[I]).ItemType = t_Protoplasm then Break;
                Inc(I);
              end;
              if I < Quantity then
              begin
                Inc(TProtoplasm(Ship.Inventory[I]).Quantity, TProtoplasm(Item).Quantity);
                Inc(TItem(Ship.Inventory[I]).Weight, Item.Weight);
                TItem(Ship.Inventory[I]).Cost := 10 * TProtoplasm(Ship.Inventory[I]).Quantity;
                Item.DestroyFlag := 1;
              end
              else
              begin
                Item.DestroyFlag := 0;
                Ship.Inventory.Add(Item);
              end;
            end
            else if Item is TEquipment then
            begin
              (Item as TEquipment).EquippedFlag := False;
              Ship.Inventory.Add(Item);
              if (Ship <> Player) or PlayerAutomaticControl then
              begin
                Ship.RefreshEquipmentSlots;
                ClearUnequippedWeaponTargets(Ship);
              end;
            end
            else if Item is TGoods then Inc(Ship.CargoGoods[(Item as TGoods).ItemType].Count, (Item as TGoods).Quantity);
            Ship.RefreshDerivedStats;
            if Ship = Player then PlayerInteractionOccurred := True;
            ClearItemReferences(Item);
            Quantity := Events.Count;
            for I := 0 to Quantity - 1 do
            begin
              CleanupEvent := Events[I];
              if CleanupEvent.Target = Item then CleanupEvent.Target := nil;
            end;
            if RecordFilm then
            begin
              PrimaryFilm.PlayPickupSound(StepIndex, Item.FilmObject);
              PrimaryFilm.DetachObject(StepIndex, Item.FilmObject);
            end;
            if Item is TGoods then
            begin
              if RecordFilm then
              begin
                Item.GraphObject := nil;
                PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
              end;
              Item.Free;
            end
            else if (Item is TProtoplasm) and (Item.DestroyFlag <> 0) then Item.Free
            else if RecordFilm and (Item.GraphObject <> nil) then
            begin
              Item.GraphObject := nil;
              PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
            end;
            if Ship.Speed < 1 then Ship.MovementPath.Clear;
          end
          else
          begin
            if (Ship <> NearestShip) and (Item = NearestItem) then
              Distance := Distance - (2.5 - RemapClamped(Distance, 0, 150, 1, 2))
            else Distance := Distance - (4 - RemapClamped(Distance, 0, 150, 1, 3));
            Angle := ArcTan2(Item.Position.X - Ship.Position.X, -(Item.Position.Y - Ship.Position.Y));
            Item.Position := MakePointF(Sin(Angle) * Distance + Ship.Position.X, Ship.Position.Y - Cos(Angle) * Distance);
            if RecordFilm then PrimaryFilm.SetObjectPosition(StepIndex, Item.FilmObject, Item.Position);
          end;
        end;
        Inc(Index);
      end
      else if not Ship.ProcessMovementStep(StepIndex, RecordFilm) then Inc(Index);
    end;
    if RecordFilm and (WorkCount shr 2 = StepIndex) then
    begin
      K := 0;
      while K < Galaxy.Holes.Count do
      begin
        Hole := THole(Galaxy.Holes[K]);
        if (Hole.HoleType = bhkUsed) and ((Hole.Star1 = Self) or (Hole.Star2 = Self)) then
        begin
          Index := 0;
          // Native reuses the turn's step-count variable for these endpoint scans.
          WorkCount := Hole.Star1.Ships.Count;
          while Index < WorkCount do
          begin
            Ship := TShip(Hole.Star1.Ships[Index]);
            if (Ship.Order = soEnterBlackHole) and (Ship.OrderTarget = Hole) then Break;
            Inc(Index);
          end;
          if Index >= WorkCount then
          begin
            Index := 0;
            WorkCount := Hole.Star2.Ships.Count;
            while Index < WorkCount do
            begin
              Ship := TShip(Hole.Star2.Ships[Index]);
              if (Ship.Order = soEnterBlackHole) and (Ship.OrderTarget = Hole) then Break;
              Inc(Index);
            end;
            if Index >= WorkCount then
            begin
              Hole.Graphic := nil;
              PendingFilmRemovals.Add(Hole.FilmObject);
              PrimaryFilm.SetHoleState(StepIndex, TEFilmObj(Hole.FilmObject), 2);
              Galaxy.Holes.Delete(K);
              Hole.Free;
              Dec(K);
            end;
          end;
        end;
        Inc(K);
      end;
    end;
    if RecordFilm then PrimaryFilm.AdvanceObjects(StepIndex);
    Inc(StepIndex);
  end;
  if RecordFilm and (CameraPath <> nil) then
  begin
    WorkValue := 0;
    CameraPath.AppendWaypoint(Player.Position, StepIndex);
    Node := CameraPath.ActiveHead;
    PointB := Node.Position;
    PathStep := Round(Node.Heading);
    Node := Node.Next;
    while (Node <> nil) and (PathStep >= Round(Node.Heading)) do Node := Node.Next;
    while Node <> nil do
    begin
      ShipCount := Round(Node.Heading) - PathStep + 1;
      WorkSingle := PointDistance(PointB, Node.Position);
      if (WorkSingle > 200) or ((WorkSingle > 0) and (CameraPath.ActiveTail = Node)) then
      begin
        WorkX := (Node.Position.X - PointB.X) / WorkSingle;
        WorkY := (Node.Position.Y - PointB.Y) / WorkSingle;
        WorkSingle := WorkSingle / ShipCount;
        if (WorkValue = 0) or (CameraPath.ActiveTail = Node) then
        begin
          if CameraFastSpeed < WorkSingle then WorkSingle := CameraFastSpeed;
          if CameraSlowSpeed < WorkSingle then WorkValue := 1;
        end
        else
        begin
          if CameraSlowSpeed < WorkSingle then WorkSingle := CameraSlowSpeed;
        end;
        WorkX := WorkX * WorkSingle;
        WorkY := WorkY * WorkSingle;
        for I := 0 to ShipCount - 1 do
        begin
          PointB.X := PointB.X + WorkX;
          PointB.Y := PointB.Y + WorkY;
          Inc(PathStep);
        end;
      end;
      Node := Node.Next;
      while (Node <> nil) and (PathStep >= Round(Node.Heading)) do Node := Node.Next;
    end;
    CameraPath.Free;
  end;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[Index]);
    Ship.CancelCompletedMovementOrder(StepIndex, RecordFilm);
  end;
  ShipCount := MovingDropItems.Count;
  for K := 0 to ShipCount - 1 do
  begin
    MovingDrop := MovingDropItems[K];
    if not MovingDrop.InsertedIntoStar then
    begin
      Item := MovingDrop.Payload as TItem;
      if Item is TArtefactTranclucator then
      begin
        StoredTranclucator := (Item as TArtefactTranclucator).Ship as TTranclucator;
        (Item as TArtefactTranclucator).Ship := nil;
        StoredTranclucator.CurrentStar := Self;
        Ships.Add(StoredTranclucator);
        StoredTranclucator.Position := MovingDrop.Destination;
        StoredTranclucator.MovementDirection := 0;
        Item.Free;
        if RecordFilm then
        begin
          StoredTranclucator.FilmObject := PrimaryFilm.AddObject(StoredTranclucator.Id, StoredTranclucator.Graphic, 0, 0);
          PrimaryFilm.SetObjectPosition(StepIndex, StoredTranclucator.FilmObject, Position);
          PrimaryFilm.SetObjectAngle(StepIndex, StoredTranclucator.FilmObject, 0);
          PrimaryFilm.SetObjectAlpha(StepIndex, StoredTranclucator.FilmObject, 255);
          PrimaryFilm.AttachObject(StepIndex, StoredTranclucator.FilmObject);
        end;
      end
      else
      begin
        Item.Position := MovingDrop.Destination;
        Items.Add(Item);
        MovingDrop.InsertedIntoStar := True;
        if RecordFilm then
        begin
          Item.FilmObject := PrimaryFilm.AddObject(Item.Id, Item.GetGraphObject, 0, 0);
          PrimaryFilm.SetObjectPosition(StepIndex, Item.FilmObject, Position);
          PrimaryFilm.AttachObject(StepIndex, Item.FilmObject);
        end;
      end;
    end;
    FreeEC(MovingDrop);
  end;
  MovingDropItems.Clear;
  if RecordFilm then
  begin
    Inc(StepIndex);
    PrimaryFilm.BeginTrailingEffects(StepIndex);
    Inc(StepIndex);
  end;
  if RecordFilm then PrimaryFilm.ReleaseWeaponEffects(StepIndex);
  WorkCount := Events.Count;
  for Index := 0 to WorkCount - 1 do
  begin
    CombatEvent := Events[Index];
    if TEFilmObj(CombatEvent.DestroyedTargetFilm) <> nil then PrimaryFilm.ReleaseObject(StepIndex, TEFilmObj(CombatEvent.DestroyedTargetFilm));
    FreeEC(CombatEvent);
  end;
  Events.Clear;
  Events.Free;
  if not RecordFilm and (Player <> nil) and (Player.CurrentStar <> Self) then
  begin
    Index := 0;
    while Index < Ships.Count do
    begin
      Ship := TShip(Ships[Index]);
      if Ship.IsHullDestroyed and (Ship is TRanger) then Ship.TryRelocateUnseenShip;
      Inc(Index);
    end;
  end;
  Index := 0;
  while Index < Ships.Count do
  begin
    Ship := TShip(Ships[Index]);
    if (Ship.DockedTo <> nil) and Ship.DockedTo.IsHullDestroyed then
    begin
      ClearShipCombatTargets(Ship);
      Ship.DockedTo := nil;
      Ship.Hull.HullPoints := 0;
      if Ship.IsHullDestroyed and (Player <> nil) then Player.ProcessShipDestructionQuests(Ship);
      Index := 0;
      if RecordFilm and (Ship.FilmObject = nil) then
      begin
        Ship.FilmObject := PrimaryFilm.AddObject(Ship.Id, Ship.Graphic, 0, 0);
        PrimaryFilm.DetachObject(0, Ship.FilmObject);
      end;
    end
    else Inc(Index);
  end;
  Index := 0;
  while Index < Ships.Count do
  begin
    Ship := TShip(Ships[Index]);
    if Ship.IsHullDestroyed then
    begin
      if RecordFilm then
      begin
        ShipCount := Ship.Inventory.Count;
        for K := 0 to ShipCount - 1 do
        begin
          Item := TItem(Ship.Inventory[K]);
          if PrimaryFilm.ContainsObject(Item.FilmObject) then
          begin
            PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
            Item.GraphObject := nil;
          end;
        end;
        ShipCount := Ship.Artefacts.Count;
        for K := 0 to ShipCount - 1 do
        begin
          Item := TItem(Ship.Artefacts[K]);
          if PrimaryFilm.ContainsObject(Item.FilmObject) then
          begin
            PrimaryFilm.ReleaseObject(StepIndex, Item.FilmObject);
            Item.GraphObject := nil;
          end;
        end;
        if Ship.FilmObject = nil then
        begin
          Ship.FilmObject := PrimaryFilm.AddObject(Ship.Id, Ship.Graphic, 0, 0);
          PrimaryFilm.DetachObject(0, Ship.FilmObject);
        end;
        if Ship.FilmObject <> nil then
        begin
          PrimaryFilm.ReleaseObject(StepIndex, Ship.FilmObject);
          Ship.Graphic := nil;
        end;
      end;
      if Ship = Player then ScoreScreen.RecordPlayerResult(-1);
      Ship.Free;
    end
    else Inc(Index);
  end;
  Index := 0;
  while Index < Ships.Count do
  begin
    Ship := TShip(Ships[Index]);
    if (Ship is TTranclucator) and (Ship as TTranclucator).FollowOwner and
      ((Ship as TTranclucator).OwnerShip <> nil) and
      (PointDistanceSquared(Ship.Position, (Ship as TTranclucator).OwnerShip.Position) < 25) then
    begin
      HandleObjectLeavingStar(Ship);
      Ship.EnemyShip := nil;
      Ship.TruceShip := nil;
      Ship.PartnerShip := nil;
      Ship.OrderNone;
      for K := 1 to Ship.WeaponCount do Ship.Weapons[K - 1].Target := nil;
      if RecordFilm then PrimaryFilm.DetachObject(StepIndex, Ship.FilmObject);
      Ships.Delete(Index);
      Ship.CurrentStar := nil;
      Artefact := TArtefactTranclucator.Create;
      Artefact.Init((Ship as TTranclucator).OwnerShip.OwnerId, (Ship as TTranclucator).OwnerShip, Ship);
      (Ship as TTranclucator).OwnerShip.Artefacts.Add(Artefact);
      (Ship as TTranclucator).OwnerShip.RefreshDerivedStats;
      (Ship as TTranclucator).FollowOwner := False;
    end
    else Inc(Index);
  end;
  if RecordFilm then
  begin
    Index := 0;
    while Index < Galaxy.JumpGates.Count do
    begin
      GateEntry := Galaxy.JumpGates[Index];
      if GateEntry.UnresolvedFlag then
      begin
        PrimaryFilm.ReleaseObject(StepIndex, TEFilmObj(GateEntry.FilmObject));
        Galaxy.JumpGates.Delete(Index);
        FreeEC(GateEntry);
      end
      else Inc(Index);
    end;
  end;
  PruneWeaponTargetsAfterTurn;
  if RecordFilm then
  begin
    ShipCount := PendingFilmRemovals.Count;
    for K := 0 to ShipCount - 1 do
    begin
      ObjectFilm := TEFilmObj(PendingFilmRemovals[K]);
      PrimaryFilm.ReleaseObject(StepIndex, ObjectFilm);
    end;
    PendingFilmRemovals.Free;
  end;
  PrimaryFilm.PlayerCombatRecorded := RecordFilm and PlayerCombatActive;
  RefreshDerivedStats;
  if RecordFilm then
  begin
    if PlayerCombatActive then
    begin
      PrimaryFilm.InitialActivity := 0;
      PrimaryFilm.FinalActivity := 0;
    end
    else
    begin
      PrimaryFilm.InitialActivity := PreviousFilmActivity;
      PrimaryFilm.FinalActivity := PrimaryFilm.InitialActivity;
      WorkSingle := EstimatePlayerTravelTurns;
      if PreviousFilmActivity = 0 then
      begin
        if WorkSingle >= 1 then PrimaryFilm.FinalActivity := 1;
      end
      else if PreviousFilmActivity = 1 then
      begin
        if WorkSingle >= 2 then PrimaryFilm.FinalActivity := 2;
      end
      else if (PreviousFilmActivity = 2) and (WorkSingle <= 2) then PrimaryFilm.FinalActivity := 1;
      PreviousFilmActivity := PrimaryFilm.FinalActivity;
    end;
    FilmHistory.AddFilm(PrimaryFilm);
  end;
  if StarPreparationFlag then;
  if (Player <> nil) and (Player.CurrentStar = Self) and (PendingPlayerFollowTarget <> nil) and
    ((PendingPlayerFollowTarget.CurrentStar <> Self) or not PendingPlayerFollowTarget.InNormalSpace) then
  begin
    PendingPlayerFollowTarget := nil;
    Player.OrderNone;
  end;
  StarPreparationFlag := False;
end;
{ @end $5EEA28 }

{ @routine $5F5004 TStar_HandleObjectLeavingStar }
procedure TStar.HandleObjectLeavingStar(Obj: TObject);
var I, J, Count: Integer; Ship: TShip;
begin
  if Obj is TShip then
    for J := 1 to TShip(Obj).WeaponCount do TShip(Obj).Weapons[J - 1].Target := nil;
  Count := Ships.Count;
  for I := 0 to Count - 1 do begin
    Ship := Ships[I];
    if ((Ship.Order = soFollowShip) and (Ship.OrderTarget = Obj)) or
      ((Ship.Order = soLanding) and (Ship.OrderTarget = Obj)) then Ship.OrderNone;
    if (Ship is TTranclucator) and ((Ship as TTranclucator).OwnerShip = Obj) then
      (Ship as TTranclucator).FollowOwner := False;
    for J := 1 to Ship.WeaponCount do
      if Ship.Weapons[J - 1].Target = Obj then Ship.Weapons[J - 1].Target := nil;
    if Ship.DockedTo = Obj then HandleObjectLeavingStar(Ship);
  end;
  // The tail requires a ship even though the earlier test accepts TObject.
  (Obj as TShip).ClearPickupTargets;
end;
{ @end $5F5004 }

{ @routine $5F512C TStar_AvoidShipPathCollisions }
procedure TStar.AvoidShipPathCollisions;
type
  TCollisionEntry = record
    Ship: TShip;
    Position: TPointF;
    DistanceSquared: Single;
  end;
  PCollisionEntry = ^TCollisionEntry;
var
  Ship: TShip;
  Entries: TList;
  Entry, Other: PCollisionEntry;
  I, J, ShipCount, StationaryCount, Count: Integer;
  Node: PSPathNode;
  Collides: Boolean;
begin
  ShipCount := Ships.Count;
  if ShipCount < 1 then Exit;
  Entries := TList.Create;
  StationaryCount := 0;
  for I := 0 to ShipCount - 1 do
  begin
    Ship := TShip(Ships[I]);
    if (Ship.Order <> soTakeoff) and not Ship.IsTravelCompletionPathReady and
       (Ship.CurrentPlanet = nil) and (Ship.DockedTo = nil) then
    begin
      if (not (Ship is TTranclucator) or not (Ship as TTranclucator).CanFollowOwnerInCurrentStar or
          (Sqr(Ship.Speed) <= PointDistanceSquared(Ship.Position, (Ship as TTranclucator).OwnerShip.Position))) and
         not (Ship is TRuins) then
      begin
        Entry := AllocEC(SizeOf(TCollisionEntry));
        Entry.Ship := Ship;
        Entry.DistanceSquared := 0;
        Entry.Position := Ship.Position;
        if Ship.MovementPath.ActiveTail <> nil then
        begin
          Entry.DistanceSquared := PointDistanceSquared(Entry.Position, Ship.MovementPath.ActiveTail.Position);
          Entry.Position := Ship.MovementPath.ActiveTail.Position;
        end
        else Inc(StationaryCount);
        J := 0;
        while J < Entries.Count do
        begin
          Other := Entries[J];
          if Other.DistanceSquared > Entry.DistanceSquared then Break;
          Inc(J);
        end;
        if J >= Entries.Count then Entries.Add(Entry)
        else Entries.Insert(J, Entry);
      end;
    end;
  end;
  Count := Entries.Count;
  for I := StationaryCount to Count - 1 do
  begin
    Entry := Entries[I];
    Node := Entry.Ship.MovementPath.ActiveTail;
    while Node <> nil do
    begin
      Collides := False;
      for J := 0 to I - 1 do
      begin
        Other := Entries[J];
        if (PointDistanceSquared(Node.Position, Other.Position) < Sqr(Entry.Ship.CollisionRadius + Other.Ship.CollisionRadius)) then
        begin
          Collides := True;
          Break;
        end;
      end;
      if not Collides then Break;
      Node := Node.Prev;
    end;
    if Node = nil then
    begin
      Entry.Position := Entry.Ship.Position;
      Entry.Ship.ClearMovementPath;
    end
    else
    begin
      Entry.Position := Node.Position;
      if Node.Next <> nil then
      begin
        Entry.Ship.MovementPath.RemoveNodeRange(Node.Next, Entry.Ship.MovementPath.ActiveTail);
        Entry.Ship.MovementPath.ResampleBezierRange(Entry.Ship.MovementPath.ActiveHead, Entry.Ship.MovementPath.ActiveTail, 200);
      end;
    end;
  end;
  Count := Entries.Count;
  for I := 0 to Count - 1 do FreeEC(Entries[I]);
  Entries.Free;
end;
{ @end $5F512C }

{ @routine $5F5448 TStar_RebuildShipMovementPaths }
procedure TStar.RebuildShipMovementPaths;
var I: Integer; Ship: TShip;
begin
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship.InNormalSpace then Ship.RebuildOrderMovementPath;
  end;
end;
{ @end $5F5448 }

{ @routine $5F5484 TStar_OpenSpaceScene }
procedure TStar.OpenSpaceScene(MapPanel: TPanelGI; Minimap: TObjectGI; Screen: TMessageLoopGI);
var
  I, J: Integer;
  Planet: TPlanet;
  Asteroid: TAsteroid;
  Hole: THole;
  Satellite: TSputnik;
  Ship: TShip;
  Item: TItem;
  Gate: PJumpGateEntry;
begin
  if Player <> nil then
  begin
    SpaceProcess.RadarCenter := Player.Position;
    SpaceProcess.RadarRange := Player.GetRadarRange;
    SpaceProcess.ActionRange := Player.GetRadarRange;
    SpaceProcess.ActionColor := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
  end
  else
  begin
    SpaceProcess.RadarCenter := MakePointF(0, 0);
    SpaceProcess.RadarRange := 0;
    SpaceProcess.ActionRange := 0;
    SpaceProcess.ActionColor := 0;
  end;
  SpaceProcess.SystemRadius := ComputeMapDiameter div 2;
  SpaceProcess.PopulateAmbientObjects(ComputeMapDiameter div 2);
  SpaceProcess.OpenSpace(MapPanel, Screen);
  SpaceProcess.Space.MinimapScale := Minimap.ClientSize.X / ComputeMapDiameter;
  SpaceProcess.BindMinimap(Minimap);
  Graphic.AttachToSpace(SpaceProcess.Space);
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    Planet.Graphic.Civilized := Planet.OwnerId <> oiNone;
    Planet.Graphic.SetMinimapOwner(Planet.OwnerId);
    Planet.Graphic.AttachToSpace(SpaceProcess.Space);
    if SputnikShow then
      for J := 0 to Planet.Satellites.Count - 1 do
      begin
        Satellite := TSputnik(Planet.Satellites[J]);
        Satellite.Graphic.OrbitCenter := Planet.GetPosition;
        Satellite.Graphic.AttachToSpace(SpaceProcess.Space);
      end;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Ships.Count - 1 do
  begin
    Ship := TShip(Ships[I]);
    if Ship.InNormalSpace then
    begin
      Ship.Graphic.SetAlpha(255);
      if Ship.Graphic is TShip2SE then
        TShip2SE(Ship.Graphic).SetTailsActive((ShipTail = 2) or ((ShipTail = 1) and (Player = Ship)));
      Ship.Graphic.AttachToSpace(SpaceProcess.Space);
    end;
  end;
  for I := 0 to Items.Count - 1 do
  begin
    Item := TItem(Items[I]);
    Item.GetGraphObject.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Galaxy.JumpGates.Count - 1 do
  begin
    Gate := Galaxy.JumpGates[I];
    TGateSE(Gate.Gate).SetState(2);
    Gate.Gate.AttachToSpace(SpaceProcess.Space);
  end;
  for I := 0 to Galaxy.Holes.Count - 1 do
  begin
    Hole := THole(Galaxy.Holes[I]);
    if Hole.Star1 = Self then
    begin
      Hole.Graphic.SetPosition(Hole.Position1);
      Hole.Graphic.SetState(0);
      Hole.Graphic.AttachToSpace(SpaceProcess.Space);
    end
    else if Hole.Star2 = Self then
    begin
      Hole.Graphic.SetPosition(Hole.Position2);
      Hole.Graphic.SetState(0);
      Hole.Graphic.AttachToSpace(SpaceProcess.Space);
    end;
  end;
end;
{ @end $5F5484 }

{ @routine $5F5888 TStar_RefreshSpaceObjectPositions }
procedure TStar.RefreshSpaceObjectPositions;
var Planet: TPlanet; Asteroid: TAsteroid; Ship: TShip; Item: TItem;
    I, J: Integer; Satellite: TSputnik;
begin
  for I := 1 to Planets.Count do
  begin
    Planet := TPlanet(Planets[I - 1]);
    Planet.Graphic.SetPosition(PolarToPoint(Planet.Orbit));
    for J := 0 to Planet.Satellites.Count - 1 do
    begin
      Satellite := TSputnik(Planet.Satellites[J]);
      Satellite.Graphic.OrbitCenter := Planet.GetPosition;
      Satellite.Graphic.UpdateOrbitDisplay;
    end;
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.SetPosition(Asteroid.Position);
  end;
  for I := 1 to Ships.Count do
  begin
    Ship := TShip(Ships[I - 1]);
    Ship.Graphic.SetPosition(Ship.Position);
    Ship.Graphic.SetAngle(HeadingDegreesToByte(Ship.MovementDirection));
  end;
  for I := 1 to Items.Count do
  begin
    Item := TItem(Items[I - 1]);
    Item.GetGraphObject.SetPosition(Item.Position);
  end;
end;
{ @end $5F5888 }

{ @routine $5F5A10 TStar_QueueSpaceImageLoads }
procedure TStar.QueueSpaceImageLoads(PendingLoads: TList; Owner: TObjectGI);
var
  Planet: TPlanet;
  Ship: TShip;
  Hole: THole;
  Item: TItem;
  I, J: Integer;
  Satellite: TSputnik;
  Asteroid: TAsteroid;
begin
  Graphic.QueueImageLoad(PendingLoads, Owner);
  for I := 1 to Planets.Count do
  begin
    Planet := TPlanet(Planets[I - 1]);
    Planet.Graphic.QueueImageLoad(PendingLoads, Owner);
    if SputnikShow then
      for J := 0 to Planet.Satellites.Count - 1 do
      begin
        Satellite := TSputnik(Planet.Satellites[J]);
        Satellite.Graphic.QueueImageLoad(PendingLoads, Owner);
      end;
  end;
  for I := 1 to Ships.Count do
  begin
    Ship := TShip(Ships[I - 1]);
    Ship.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 1 to Items.Count do
  begin
    Item := TItem(Items[I - 1]);
    Item.GetGraphObject.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 0 to Asteroids.Count - 1 do
  begin
    Asteroid := TAsteroid(Asteroids[I]);
    Asteroid.GraphObject.QueueImageLoad(PendingLoads, Owner);
  end;
  for I := 0 to Galaxy.Holes.Count - 1 do
  begin
    Hole := THole(Galaxy.Holes[I]);
    if (Hole.Star1 = Self) or (Hole.Star2 = Self) then Hole.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
end;
{ @end $5F5A10 }

{ @routine $5F5BA0 TStar_QueueHyperspaceShipImageLoads }
procedure TStar.QueueHyperspaceShipImageLoads(PendingLoads: TList; Owner: TObjectGI);
var Ship: TShip; I: Integer;
begin
  for I := 1 to Ships.Count do begin
    Ship := TShip(Ships[I - 1]);
    if Ship.InHyperspace then Ship.Graphic.QueueImageLoad(PendingLoads, Owner);
  end;
end;
{ @end $5F5BA0 }

{ @routine $5F5BFC TStar_SelectBackground }
function TStar.SelectBackground(var Index: Integer): WideString;
var Block: TBlockParEC; Selected: Integer;
begin
  Block := GameDataConfig.GetBlock('BGImage');
  if (Player <> nil) and (Player.HomePlanet <> nil) and (Self = Player.HomePlanet.CurrentStar) then
    Selected := 0
  else Selected := SeededRandomIntRange(0, Block.GetParamCount - 1, GenerationSeed);
  Index := ExtractDigitsToIntW(Block.GetParamName(Selected));
  Result := Block.GetParamValue(Selected);
end;
{ @end $5F5BFC }

{ @routine $5F5CCC GameTurnToDateTime }
function GameTurnToDateTime(Turn: Integer): Double;
begin
  Result := Turn + 401768.5;
end;
{ @end $5F5CCC }

{ @routine $5F5CEC FormatGameTurnDate }
function FormatGameTurnDate(Turn: Integer): WideString;
var
  MonthNumber, MonthName: WideString;
begin
  MonthNumber := FormatDateTime('mm', GameTurnToDateTime(Turn - 200));
  MonthName := LocalizedText('Month.' + MonthNumber);
  Result := FormatDateTime('d', GameTurnToDateTime(Turn - 200)) + ' ' + MonthName + ' ' + FormatDateTime('yyyy', GameTurnToDateTime(Turn - 200));
end;
{ @end $5F5CEC }

{ @routine $5F5E70 ShouldContinuePlayerTravel }
function ShouldContinuePlayerTravel: Boolean;
begin
  if Player = nil then begin Result := False; Exit; end;
  if PlayerEquipmentChanged then begin Result := False; Exit; end;
  if (PendingPlayerFollowTarget <> nil) and (Player.GetHullIntegrityPercent < 25) then
  begin Result := False; Exit; end;
  if PlayerAutomaticControl or (ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive or (PendingPlayerFollowTarget <> nil) then
  begin Result := True; Exit; end;
  Player.RebuildOrderMovementPath;
  if (not PlayerStar.PlayerCombatActive) and (not PlayerStar.PlayerInteractionOccurred) and
     (Player.GetMovementPathTurnCount > 0) and (Player.PickupTargets = nil) then
  begin
    if (Player.Order = soFollowShip) and
       (PointDistanceSquared(Player.Position, (Player.OrderTarget as TShip).Position) < Sqr(Player.Speed)) then
      Result := False
    else Result := True;
  end
  else Result := False;
end;
{ @end $5F5E70 }

{ @routine $5F5F5C EstimatePlayerTravelTurns }
function EstimatePlayerTravelTurns: Single;
var Destination: TPointF;
begin
  Result := 0;
  if Player = nil then Exit;
  if PlayerStar.PlayerCombatActive or PlayerStar.PlayerInteractionOccurred then Exit;
  if Player.PickupTargets <> nil then Exit;
  if PendingPlayerFollowTarget <> nil then Destination := PendingPlayerFollowTarget.Position
  else if Player.Order = soMove then Destination := Player.OrderDestination
  else if Player.Order = soJump then Destination := Player.OrderDestination
  else if (Player.Order = soEnterBlackHole) and (Player.OrderStateData <> BlackHoleExitFlightState) then Destination := Player.OrderDestination
  else if Player.Order = soLanding then
  begin
    if Player.OrderTarget is TShip then Destination := TShip(Player.OrderTarget).Position
    else Destination := TPlanet(Player.OrderTarget).GetPosition;
  end
  else if Player.Order = soTakeoff then Exit
  else if Player.Order = soFollowShip then Destination := TShip(Player.OrderTarget).Position
  else Exit;
  Result := PointDistance(Destination, Player.Position) / (Player.Speed + 1);
end;
{ @end $5F5F5C }

{ @routine $5F611C TGalaxy_FindConstellationIndexForStar }
function TGalaxy.FindConstellationIndexForStar(Star: TStar): Integer;
var I: Integer; Constellation: TConstellation;
begin
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.ContainsPoint(Star.Position) then begin Result := I; Exit; end;
  end;
  Result := -1;
end;
{ @end $5F611C }

{ @routine $5F6168 TGalaxy_InitializeConstellationDistanceTiers }
procedure TGalaxy.InitializeConstellationDistanceTiers;
var I, J, Pass: Integer; Constellation, Other: TConstellation; Tier: Byte;
begin
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.SharesOutlineSegment(Player.HomePlanet.CurrentStar.Constellation) then Constellation.HomeDistanceTier := 0
    else Constellation.HomeDistanceTier := 3;
  end;
  Tier := 0;
  for Pass := 1 to 2 do begin
    for I := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      for J := 0 to Constellations.Count - 1 do begin
        Other := TConstellation(Constellations[J]);
        if Other.SharesOutlineSegment(Constellation) and (Other.HomeDistanceTier = 3) and (Constellation.HomeDistanceTier = Tier) then
          Other.HomeDistanceTier := Tier + 1;
      end;
    end;
    Inc(Tier);
  end;
  if KlingMotherShip <> nil then KlingMotherShip.CurrentStar.Constellation.HomeDistanceTier := 3;
end;
{ @end $5F6168 }

{ @routine $5F62A4 TGalaxy_BuildConstellationOutlineJunctions }
procedure TGalaxy.BuildConstellationOutlineJunctions;
var I, J, K: Integer; Segment, First, Next: PMapLineSegment; Temp: Pointer; Point: PPointF; Constellation, Other: TConstellation; Edges: TList; Outer: Boolean; TempPoint: TPointF; Distance: Single;
begin
  if ConstellationOutlineJunctions <> nil then begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do begin
      Point := ConstellationOutlineJunctions[I];
      Dispose(Point);
    end;
    ConstellationOutlineJunctions.Clear;
  end else ConstellationOutlineJunctions := TList.Create;
  Edges := TList.Create;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    for J := 0 to Constellation.OutlineSegments.Count - 1 do begin
      Segment := Constellation.OutlineSegments[J];
      Outer := True;
      for K := 0 to Constellations.Count - 1 do
        if K <> I then begin
          Other := TConstellation(Constellations[K]);
          if Other.HasOutlineSegment(Segment.StartPoint, Segment.EndPoint) then begin Outer := False; Break; end;
        end;
      if Outer then begin
        GetMem(Next, SizeOf(TMapLineSegment));
        Next.StartPoint := Segment.StartPoint;
        Next.EndPoint := Segment.EndPoint;
        Edges.Add(Next);
      end;
    end;
  end;
  for I := 0 to Edges.Count - 2 do begin
    First := Edges[I];
    J := I + 1;
    while J < Edges.Count do begin
      Next := Edges[J];
      if PointsNearlyEqualF(First.EndPoint, Next.StartPoint) then Break;
      if PointsNearlyEqualF(First.EndPoint, Next.EndPoint) then begin
        TempPoint := Next.StartPoint;
        Next.StartPoint := Next.EndPoint;
        Next.EndPoint := TempPoint;
        Break;
      end;
      Inc(J);
    end;
    if J < Edges.Count then begin
      Temp := Edges[I + 1];
      Edges[I + 1] := Edges[J];
      Edges[J] := Temp;
    end;
  end;
  Distance := 0;
  for I := 0 to Edges.Count - 1 do begin
    Segment := Edges[I];
    Outer := False;
    K := 0;
    for J := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[J]);
      if Constellation.HasOutlineVertex(Segment.StartPoint) then begin
        Inc(K);
        if K > 1 then begin Outer := True; Break; end;
      end;
    end;
    if (Distance > 0) or (Outer <> False) then begin
      GetMem(Point, SizeOf(TPointF));
      Point^ := Segment.StartPoint;
      ConstellationOutlineJunctions.Add(Point);
      Distance := 0;
    end;
    Distance := PointDistanceF(Segment.StartPoint, Segment.EndPoint) + Distance;
  end;
  for I := 0 to Edges.Count - 1 do begin
    Segment := Edges[I];
    Dispose(Segment);
  end;
  Edges.Clear;
  Edges.Free;
end;
{ @end $5F62A4 }

{ @routine $5F6650 TGalaxy_ShouldKeepConstellationOutlineVertex }
function TGalaxy.ShouldKeepConstellationOutlineVertex(Point: TPointF): Boolean;
var I, Count: Integer; Constellation: TConstellation; Vertex: PPointF;
begin
  Count := 0;
  if ConstellationOutlineJunctions = nil then begin
    if ScalarsNearlyEqualF(Point.X, 0) then Inc(Count);
    if ScalarsNearlyEqualF(Point.Y, 0) then Inc(Count);
    if ScalarsNearlyEqualF(Point.X, GalaxySizeY) then Inc(Count);
    if ScalarsNearlyEqualF(Point.Y, GalaxySizeY) then Inc(Count);
  end else begin
    for I := 0 to ConstellationOutlineJunctions.Count - 1 do begin
      Vertex := ConstellationOutlineJunctions[I];
      if PointsNearlyEqualF(Vertex^, Point) then begin Result := True; Exit; end;
    end;
  end;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.HasOutlineVertex(Point) then begin
      Inc(Count);
      if Count > 2 then Break;
    end;
  end;
  if Count > 2 then Result := True else Result := False;
end;
{ @end $5F6650 }

{ @routine $5F6744 TGalaxy_SimplifyConstellationOutline }
procedure TGalaxy.SimplifyConstellationOutline(ConstellationIndex: Integer);
var Constellation: TConstellation; I: Integer; Points: TList; Segment: PMapLineSegment; First, Last: PPointF; Polygon: TPolygon2D;
begin
  Constellation := TConstellation(Constellations[ConstellationIndex]);
  if Constellation <> nil then begin
    Points := TList.Create;
    for I := 0 to Constellation.OutlineSegments.Count - 1 do begin
      Segment := Constellation.OutlineSegments[I];
      if ShouldKeepConstellationOutlineVertex(Segment.StartPoint) then begin
        GetMem(First, SizeOf(TPointF));
        First^ := Segment.StartPoint;
        Points.Add(First);
      end;
    end;
    Constellation.ClearOutlineSegmentsAndBounds;
    for I := 0 to Points.Count - 1 do begin
      First := Points[I];
      if I = Points.Count - 1 then Last := Points[0] else Last := Points[I + 1];
      GetMem(Segment, SizeOf(TMapLineSegment));
      Segment.StartPoint := First^;
      Segment.EndPoint := Last^;
      Constellation.OutlineSegments.Add(Segment);
    end;
    Constellation.RefreshOutlineBounds;
    Polygon := nil;
    for I := 0 to Points.Count - 1 do begin
      First := Points[I];
      if I = Points.Count - 1 then Last := Points[0] else Last := Points[I + 1];
      if Polygon = nil then Polygon := TPolygon2D.CreateTriangle(First^, Last^, Constellation.MapCenter)
      else Polygon.Append(TPolygon2D.CreateTriangle(First^, Last^, Constellation.MapCenter));
    end;
    Constellation.SetOutlinePolygon(Polygon);
    for I := 0 to Points.Count - 1 do Dispose(PPointF(Points[I]));
    Points.Free;
  end;
end;
{ @end $5F6744 }

{ @routine $5F693C TGalaxy_BuildConstellationStarGraphs }
function TGalaxy.BuildConstellationStarGraphs: Boolean;
var I: Integer; Constellation: TConstellation;
begin
  Result := True;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    if not Constellation.BuildStarGraph then Result := False;
  end;
end;
{ @end $5F693C }

{ @routine $5F6984 TGalaxy_BuildConstellationPolygonsAndAdjacency }
procedure TGalaxy.BuildConstellationPolygonsAndAdjacency(WorkingPolygon: TPolygon2D);
var I, J: Integer; Constellation, Other: TConstellation; Pass, Steps: Integer; Sample: PConstellationBoundaryRaySample; PreviousPoint, Point: TPointF; Step: Single;
begin
  Step := 3;
  WorkingPolygon.ResetChainGroups;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    WorkingPolygon.AssignGroupAtPoint(Constellation.MapCenter, I);
    Constellation.GenerateBoundaryRaySamples(128);
  end;
  Steps := Trunc(GalaxySizeY / Sqrt(Cardinal(ConstellationCount)) / Step * 0.5) + 1;
  for I := 0 to 7 do begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.OutlineGrowthStepsRemaining := Steps + 20;
  end;
  Inc(Steps, 20);
  for I := 8 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.OutlineGrowthStepsRemaining := Steps;
  end;
  Pass := -1;
  repeat
    for I := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      if Cardinal(Constellation.OutlineGrowthStepsRemaining) > 0 then begin
        for J := 0 to Constellation.BoundaryRaySamples.Count - 1 do begin
          Sample := Constellation.BoundaryRaySamples[J];
          if not Sample.GrowthStopped then begin
            PreviousPoint := Sample.Position;
            Point := MakePointF(Step * Sample.Direction.X + PreviousPoint.X, Step * Sample.Direction.Y + PreviousPoint.Y);
            if (Point.X < 0) or (Point.X >= GalaxySizeX) or (Point.Y < 0) or (Point.Y >= GalaxySizeY) then Point := PreviousPoint;
            Sample.Position := Point;
            Sample.GrowthStopped := not WorkingPolygon.AssignGroupAtPoint(Point, I);
          end;
        end;
        Dec(Constellation.OutlineGrowthStepsRemaining);
      end;
    end;
    Inc(Pass);
  until Pass >= Steps;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    Constellation.SetOutlinePolygon(WorkingPolygon.ExtractFollowingGroup(I));
  end;
  for I := 0 to Constellations.Count - 1 do begin
    Constellation := TConstellation(Constellations[I]);
    for J := I + 1 to Constellations.Count - 1 do begin
      Other := TConstellation(Constellations[J]);
      if Constellation.SharesOutlineSegment(Other) then begin
        Constellation.AddAdjacentConstellation(Other);
        Other.AddAdjacentConstellation(Constellation);
      end;
    end;
  end;
end;
{ @end $5F6984 }

{ @routine $5F6CAC TGalaxy_GenerateGalaxyLayout }
procedure TGalaxy.GenerateGalaxyLayout(PlayerRace: TRaceId);
var I, J, K, FirstIndex, SecondIndex, N, Attempts: Integer;
  Star, OtherStar, SecondStar: TStar; InvalidLayout: Boolean;
  FuelRange, NearestDistance, Distance: Integer;
  Constellation, OtherConstellation: TConstellation;
  MinimumConstellationDistance, MinimumStarDistance, ConstellationIndex: Integer;
  BoundsSize: TPoint; BestAreaPerStar: Double;
  WorkingPolygon, Polygon: TPolygon2D; Occupied: Boolean;
  MinimumArea, MaximumArea: Single; PlacementAttempts, TotalLinks, AxisLinks: Integer;
  Link: PConstellationStarLink; Coordinate: Single; GenerationAttempts, HumanPosition: Integer;
  Reserved1, Reserved2, Reserved3: Integer;
  RaceOrder: array[0..7] of Byte;
  CoalitionPositions: array[0..4] of Byte;
  Reached: array[0..99] of Boolean;
  Bounds: TRect;
begin
  System.RandSeed := aGalaxy.Galaxy.GenerationSeed;
  Constellations.Clear;
  for I := 1 to ConstellationCount do begin
    Constellation := TConstellation.Create;
    Constellations.Add(Constellation);
  end;
  MinimumConstellationDistance := Round(Sqrt(GalaxySizeY * GalaxySizeY / Cardinal(ConstellationCount)) * 0.75);
  MinimumArea := GalaxySizeX * 0.52 * GalaxySizeY / Cardinal(ConstellationCount);
  MaximumArea := GalaxySizeX * 1.5 * GalaxySizeY / Cardinal(ConstellationCount);
  GenerationAttempts := 0;
  repeat
    WorkingPolygon := TPolygon2D.Create;
    Polygon := TPolygon2D.Create;
    Polygon.SetRectangle(Classes.Rect(0, 0, GalaxySizeX, GalaxySizeY));
    WorkingPolygon.Append(Polygon);
    Coordinate := 5;
    while Coordinate < GalaxySizeX do begin
      WorkingPolygon.SplitChainByPoints(MakePointF(Coordinate, 0), MakePointF(Coordinate, GalaxySizeY));
      Coordinate := Coordinate + 5;
    end;
    Coordinate := 5;
    while Coordinate < GalaxySizeY do begin
      WorkingPolygon.SplitChainByPoints(MakePointF(0, Coordinate), MakePointF(GalaxySizeX, Coordinate));
      Coordinate := Coordinate + 5;
    end;
    for I := 0 to 7 do RaceOrder[I] := I;
    for K := 1 to NextRandomIntRange(0, 3, aGalaxy.Galaxy.RandomState) do
      for I := 0 to 7 do begin
        RaceOrder[I] := DecrementWrappedValue(RaceOrder[I], 0, 7);
        RaceOrder[I] := DecrementWrappedValue(RaceOrder[I], 0, 7);
      end;
    N := 0;
    for I := 0 to 7 do
      if RaceOrder[I] in [0..4] then begin
        CoalitionPositions[N] := I;
        Inc(N);
        if RaceOrder[I] = 2 then HumanPosition := I;
      end;
    N := 0;
    repeat
      repeat
        I := CoalitionPositions[NextRandomIntRange(0, 4, aGalaxy.Galaxy.RandomState)];
        K := CoalitionPositions[NextRandomIntRange(0, 4, aGalaxy.Galaxy.RandomState)];
      until I <> K;
      Attempts := RaceOrder[I];
      RaceOrder[I] := RaceOrder[K];
      RaceOrder[K] := Attempts;
      Inc(N);
    until (N > 3) and (Byte(Ord(PlayerRace)) = RaceOrder[HumanPosition]);
    Constellation := TConstellation(Constellations[RaceOrder[0]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[1]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (GalaxySizeX / 2 - 1);
    Constellation.MapCenter.Y := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[2]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (GalaxySizeX - MinimumConstellationDistance * 0.6 - 2);
    Constellation.MapCenter.Y := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation := TConstellation(Constellations[RaceOrder[3]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (GalaxySizeX - MinimumConstellationDistance * 0.6 - 2);
    Constellation.MapCenter.Y := Random(3) + (GalaxySizeY / 2 - 1);
    Constellation := TConstellation(Constellations[RaceOrder[4]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (GalaxySizeX - MinimumConstellationDistance * 0.6 - 2);
    Constellation.MapCenter.Y := Random(3) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[5]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (GalaxySizeX / 2 - 1);
    Constellation.MapCenter.Y := Random(3) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[6]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y := Random(3) + (GalaxySizeY - MinimumConstellationDistance * 0.6 - 2);
    Constellation := TConstellation(Constellations[RaceOrder[7]]);
    Constellation.ResetGeneratedMapShape;
    Constellation.MapCenter.X := Random(3) + (MinimumConstellationDistance * 0.6);
    Constellation.MapCenter.Y := Random(3) + (GalaxySizeY / 2 - 1);
    for I := 8 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.ResetGeneratedMapShape;
      Constellation.MapCenter.X := 0;
      Constellation.MapCenter.Y := 0;
      PlacementAttempts := 0;
      while True do begin
        Inc(PlacementAttempts);
        if PlacementAttempts > 100 then Break;
        Constellation.MapCenter.X := Random(GalaxySizeX) + 1;
        Constellation.MapCenter.Y := Random(GalaxySizeY) + 1;
        if (Constellation.MapCenter.X < MinimumConstellationDistance * 0.4) or
          (Constellation.MapCenter.X > GalaxySizeX - MinimumConstellationDistance * 0.4) or
          (Constellation.MapCenter.Y < MinimumConstellationDistance * 0.4) or
          (Constellation.MapCenter.Y > GalaxySizeY - MinimumConstellationDistance * 0.4) then Continue;
        Occupied := False;
        for K := 0 to I - 1 do begin
          OtherConstellation := TConstellation(Constellations[K]);
          if WorkingPolygon.FindContainingPolygon(Constellation.MapCenter) =
            WorkingPolygon.FindContainingPolygon(OtherConstellation.MapCenter) then begin
            Occupied := True;
            Break;
          end;
        end;
        if Occupied then Continue;
        NearestDistance := Max(GalaxySizeX, GalaxySizeY);
        for K := 0 to I - 1 do begin
          OtherConstellation := TConstellation(Constellations[K]);
          Distance := Round(PointDistance(Constellation.MapCenter, OtherConstellation.MapCenter));
          if Distance < NearestDistance then NearestDistance := Distance;
        end;
        if (NearestDistance >= MinimumConstellationDistance) and (NearestDistance >= 7.0) then Break;
      end;
    end;
    BuildConstellationPolygonsAndAdjacency(WorkingPolygon);
    WorkingPolygon.Free;
    InvalidLayout := False;
    for I := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.NormalizeOutlineSegmentOrder;
    end;
    BuildConstellationOutlineJunctions;
    for I := 0 to Constellations.Count - 1 do SimplifyConstellationOutline(I);
    TotalLinks := 0;
    AxisLinks := 0;
    for I := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      if (Constellation.OutlinePolygons.GetChainArea < MinimumArea) or
        (Constellation.OutlinePolygons.GetChainArea > MaximumArea) then begin
        InvalidLayout := True;
        Break;
      end;
      if Constellation.OutlinePolygons.ChainSelfIntersects then begin
        InvalidLayout := True;
        Break;
      end;
      Inc(TotalLinks, Constellation.StarLinks.Count);
      for K := 0 to Constellation.StarLinks.Count - 1 do begin
        Link := Constellation.StarLinks[K];
        if (Link.StartPoint.Y = Link.EndPoint.Y) or (Link.StartPoint.X = Link.EndPoint.X) then Inc(AxisLinks);
      end;
      for J := I + 1 to Constellations.Count - 1 do
        if Constellation.OutlinePolygons.IntersectsChain(TConstellation(Constellations[J]).OutlinePolygons) then begin
          InvalidLayout := True;
          Break;
        end;
      if InvalidLayout then Break;
    end;
    if AxisLinks * 7 > TotalLinks then InvalidLayout := True;
    Inc(GenerationAttempts);
  until (GenerationAttempts > 100) or not InvalidLayout;
  GenerationAttempts := 0;
  repeat
    for I := 0 to Constellations.Count - 1 do begin
      Constellation := TConstellation(Constellations[I]);
      Constellation.ClearStars;
    end;
    for I := 0 to aGalaxy.Galaxy.Stars.Count - 1 do begin
      Star := TStar(aGalaxy.Galaxy.Stars[I]);
      Star.Position.X := 0;
      Star.Position.Y := 0;
    end;
    for I := 0 to aGalaxy.Galaxy.Stars.Count - 1 do begin
      Star := TStar(aGalaxy.Galaxy.Stars[I]);
      ConstellationIndex := I mod Constellations.Count;
      if (I > aGalaxy.Galaxy.Stars.Count / 1.3) and (System.Random < 0.5) then begin
        BestAreaPerStar := 0;
        for K := 0 to Constellations.Count - 1 do begin
          Constellation := TConstellation(Constellations[K]);
          if Constellation.GetOutlineArea / Constellation.Stars.Count > BestAreaPerStar then begin
            ConstellationIndex := K;
            BestAreaPerStar := Constellation.GetOutlineArea / Constellation.Stars.Count;
          end;
        end;
      end;
      Constellation := TConstellation(Constellations[ConstellationIndex]);
      Constellation.AddStar(Star);
      Bounds := Constellation.OutlineBounds;
      BoundsSize := Constellation.OutlineBoundsSize;
      MinimumStarDistance := Round(Sqrt(Constellation.GetOutlineArea / (Stars.Count div Constellations.Count)) * 0.5);
      FuelRange := CalculateGeneratedFuelCapacity(Round(ItemSizeFactors[5] * 40), 1);
      Attempts := 0;
      while True do begin
        while True do begin
          Star.Position.X := Bounds.Left + Random(Round(BoundsSize.X * 1.0)) + BoundsSize.X * 0.0;
          Star.Position.Y := Bounds.Top + Random(Round(BoundsSize.Y * 1.0)) + BoundsSize.Y * 0.0;
          if Round(Star.Position.X) in [9..137] then
            if Round(Star.Position.Y) in [5..92] then
              if Constellation.ContainsPoint(Star.Position) then Break;
        end;
        Inc(Attempts);
        if Attempts > 100 then Break;
        if Constellation.IsPointNearOutline(Star.Position) then Continue;
        NearestDistance := MaxInt;
        for K := 0 to I - 1 do begin
          OtherStar := TStar(aGalaxy.Galaxy.Stars[K]);
          Distance := Round(PointDistance(Star.Position, OtherStar.Position));
          if NearestDistance > Distance then NearestDistance := Distance;
        end;
        if (NearestDistance >= 4) and ((NearestDistance <= FuelRange) or (Ord(PlayerRace) <> ConstellationIndex) or
          (ConstellationCount >= I)) and ((NearestDistance >= MinimumStarDistance) or (Attempts >= 20)) then Break;
      end;
    end;
    InvalidLayout := False;
    for K := 0 to aGalaxy.Galaxy.Stars.Count - 1 do Reached[K] := False;
    Reached[Ord(PlayerRace)] := True;
    FuelRange := CalculateGeneratedFuelCapacity(Round(ItemSizeFactors[5] * 40), 1);
    N := 0;
    for FirstIndex := 0 to aGalaxy.Galaxy.Stars.Count - 1 do begin
      OtherStar := TStar(aGalaxy.Galaxy.Stars[FirstIndex]);
      for SecondIndex := 0 to aGalaxy.Galaxy.Stars.Count - 1 do begin
        SecondStar := TStar(aGalaxy.Galaxy.Stars[SecondIndex]);
        if (FirstIndex <> SecondIndex) and (Abs(OtherStar.Position.X - SecondStar.Position.X) < 7.0) and
          (Abs(OtherStar.Position.Y - SecondStar.Position.Y) < 2.0) then begin
          InvalidLayout := True;
          Break;
        end;
        Distance := Round(PointDistance(OtherStar.Position, SecondStar.Position));
        if (Distance <= FuelRange) and ((Reached[FirstIndex] and not Reached[SecondIndex]) or
          (Reached[SecondIndex] and not Reached[FirstIndex])) then begin
          Reached[FirstIndex] := True;
          Reached[SecondIndex] := True;
          Inc(N);
          if N > 2 then Break;
        end;
      end;
      if InvalidLayout then Break;
    end;
    if N < 3 then InvalidLayout := True;
    if not InvalidLayout then
      if not BuildConstellationStarGraphs then InvalidLayout := True;
    Inc(GenerationAttempts);
  until (GenerationAttempts > 15) or not InvalidLayout;
end;
{ @end $5F6CAC }

{ @routine $5F7D80 TGalaxy_CountVisibleConstellationsWithBoundaryPoints }
function TGalaxy.CountVisibleConstellationsWithBoundaryPoints(FirstPoint, SecondPoint: TPointF): Integer;
var
  I, Count: Integer;
  Constellation: TConstellation;
begin
  Result := 0;
  Count := Constellations.Count;
  for I := 0 to Count - 1 do
  begin
    Constellation := TConstellation(Constellations[I]);
    if Constellation.Visible and Constellation.AreBothPointsOnOutline(FirstPoint, SecondPoint) then Inc(Result);
  end;
end;
{ @end $5F7D80 }

{ @routine $5F7DEC TConstellation_Create }
constructor TConstellation.Create;
begin
  inherited Create;
  Id := Galaxy.NextConstellationId;
  Inc(Galaxy.NextConstellationId);
  MapCenter := MakePointF(0, 0);
  Stars := TList.Create;
  AdjacentConstellations := TList.Create;
  OutlineBounds := Classes.Rect(0, 0, 0, 0);
  OutlineBoundsSize := Classes.Point(0, 0);
  StarLinks := TList.Create;
  OutlinePolygons := TPolygon2D.Create;
  BoundaryRaySamples := TList.Create;
  OutlineSegments := TList.Create;
end;
{ @end $5F7DEC }

{ @routine $5F7EE8 TConstellation_Destroy }
destructor TConstellation.Destroy;
begin
  ClearStarLinks;
  ClearOutlineSegmentsAndBounds;
  ClearBoundaryRaySamples;
  StarLinks.Free;
  OutlineSegments.Free;
  AdjacentConstellations.Free;
  Stars.Free;
  OutlinePolygons.Free;
  BoundaryRaySamples.Free;
  inherited Destroy;
end;
{ @end $5F7EE8 }

{ @routine $5F7F54 TConstellation_SaveToBuffer }
procedure TConstellation.SaveToBuffer(Buffer: TBufEC);
var
  i, j: Integer;
  Star: TStar;
  Constellation: TConstellation;
  Segment: PMapLineSegment;
  Polygon: TPolygon2D;
  Point: PPointF;
begin
  Buffer.AddDWord(Self.Id);
  Buffer.AddBoolean(Self.Visible);
  Buffer.AddWideChar(WideChar(Self.SerializedValue70));
  Buffer.AddSingle(Self.MapCenter.X);
  Buffer.AddSingle(Self.MapCenter.Y);
  Buffer.AddWideChar(WideChar(Self.Stars.Count));
  for i := 0 to Self.Stars.Count - 1 do
  begin
    Star := TStar(Self.Stars[i]);
    Buffer.AddDWord(Star.Id);
  end;
  Buffer.AddWideChar(WideChar(Self.AdjacentConstellations.Count));
  for i := 0 to Self.AdjacentConstellations.Count - 1 do
  begin
    Constellation := TConstellation(Self.AdjacentConstellations[i]);
    Buffer.AddDWord(Constellation.Id);
  end;
  Buffer.AddWideChar(WideChar(Self.OutlineSegments.Count));
  for i := 0 to Self.OutlineSegments.Count - 1 do
  begin
    Segment := PMapLineSegment(Self.OutlineSegments[i]);
    Buffer.AddSingle(Segment^.StartPoint.X);
    Buffer.AddSingle(Segment^.StartPoint.Y);
    Buffer.AddSingle(Segment^.EndPoint.X);
    Buffer.AddSingle(Segment^.EndPoint.Y);
  end;
  Buffer.AddIntegerValue(Self.OutlineBounds.Left);
  Buffer.AddIntegerValue(Self.OutlineBounds.Top);
  Buffer.AddIntegerValue(Self.OutlineBounds.Right);
  Buffer.AddIntegerValue(Self.OutlineBounds.Bottom);
  Buffer.AddIntegerValue(Self.OutlineBoundsSize.X);
  Buffer.AddIntegerValue(Self.OutlineBoundsSize.Y);
  Buffer.AddWideChar(WideChar(Self.StarLinks.Count));
  for i := 0 to Self.StarLinks.Count - 1 do
  begin
    Segment := PMapLineSegment(Self.StarLinks[i]);
    Buffer.AddSingle(Segment^.StartPoint.X);
    Buffer.AddSingle(Segment^.StartPoint.Y);
    Buffer.AddSingle(Segment^.EndPoint.X);
    Buffer.AddSingle(Segment^.EndPoint.Y);
  end;
  Buffer.AddWideChar(WideChar(Self.OutlinePolygons.CountChain));
  Polygon := Self.OutlinePolygons;
  while Polygon <> nil do
  begin
    Buffer.AddWideChar(WideChar(Polygon.Points.Count));
    for j := 0 to Polygon.Points.Count - 1 do
    begin
      Point := PPointF(Polygon.Points[j]);
      Buffer.AddSingle(Point^.X);
      Buffer.AddSingle(Point^.Y);
    end;
    Buffer.AddSingle(Polygon.Extent.X);
    Buffer.AddSingle(Polygon.Extent.Y);
    Buffer.AddSingle(Polygon.Bounds.Left);
    Buffer.AddSingle(Polygon.Bounds.Top);
    Buffer.AddSingle(Polygon.Bounds.Right);
    Buffer.AddSingle(Polygon.Bounds.Bottom);
    Polygon := Polygon.Next;
  end;
end;
{ @end $5F7F54 }

{ @routine $5F81B4 TConstellation_LoadFromBuffer }
procedure TConstellation.LoadFromBuffer(Buffer: TBufEC);
var
  i, j, Count, PointCount: Integer;
  Segment: PMapLineSegment;
  Polygon: TPolygon2D;
  Point: PPointF;
begin
  Self.Id := Buffer.GetUInt32;
  if Galaxy.NextConstellationId <= Self.Id then
    Galaxy.NextConstellationId := Self.Id + 1;
  Self.Visible := Buffer.GetBoolean;
  Self.SerializedValue70 := Buffer.GetWord;
  Self.MapCenter.X := Buffer.GetSingle;
  Self.MapCenter.Y := Buffer.GetSingle;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
    Self.Stars.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
    Self.AdjacentConstellations.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    System.GetMem(Segment, SizeOf(TMapLineSegment));
    Segment^.StartPoint.X := Buffer.GetSingle;
    Segment^.StartPoint.Y := Buffer.GetSingle;
    Segment^.EndPoint.X := Buffer.GetSingle;
    Segment^.EndPoint.Y := Buffer.GetSingle;
    Self.OutlineSegments.Add(Segment);
  end;
  Self.OutlineBounds.Left := Buffer.GetInt32;
  Self.OutlineBounds.Top := Buffer.GetInt32;
  Self.OutlineBounds.Right := Buffer.GetInt32;
  Self.OutlineBounds.Bottom := Buffer.GetInt32;
  Self.OutlineBoundsSize.X := Buffer.GetInt32;
  Self.OutlineBoundsSize.Y := Buffer.GetInt32;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    System.GetMem(Segment, SizeOf(TMapLineSegment));
    Segment^.StartPoint.X := Buffer.GetSingle;
    Segment^.StartPoint.Y := Buffer.GetSingle;
    Segment^.EndPoint.X := Buffer.GetSingle;
    Segment^.EndPoint.Y := Buffer.GetSingle;
    Self.StarLinks.Add(Segment);
  end;
  Count := Buffer.GetWord;
  for i := 0 to Count - 1 do
  begin
    Polygon := TPolygon2D.Create;
    if i = 0 then
      Self.OutlinePolygons := Polygon
    else
      Self.OutlinePolygons.Append(Polygon);
    PointCount := Buffer.GetWord;
    for j := 0 to PointCount - 1 do
    begin
      System.GetMem(Point, SizeOf(TPointF));
      Point^.X := Buffer.GetSingle;
      Point^.Y := Buffer.GetSingle;
      Polygon.Points.Add(Point);
    end;
    Polygon.Extent.X := Buffer.GetSingle;
    Polygon.Extent.Y := Buffer.GetSingle;
    Polygon.Bounds.Left := Buffer.GetSingle;
    Polygon.Bounds.Top := Buffer.GetSingle;
    Polygon.Bounds.Right := Buffer.GetSingle;
    Polygon.Bounds.Bottom := Buffer.GetSingle;
  end;
end;
{ @end $5F81B4 }

{ @routine $5F8450 TConstellation_ResolveLoadedReferences }
procedure TConstellation.ResolveLoadedReferences;
var I: Integer;
begin
  for I := 0 to Stars.Count - 1 do Stars[I] := Galaxy.IdToStar(Cardinal(Stars[I]));
  for I := 0 to AdjacentConstellations.Count - 1 do
    AdjacentConstellations[I] := Galaxy.IdToConstellation(Cardinal(AdjacentConstellations[I]));
end;
{ @end $5F8450 }

{ @routine $5F84C8 TConstellation_ClearStarLinks }
procedure TConstellation.ClearStarLinks;
var I: Integer;
begin
  for I := 0 to StarLinks.Count - 1 do Dispose(PConstellationStarLink(StarLinks[I]));
  StarLinks.Clear;
end;
{ @end $5F84C8 }

{ @routine $5F8500 TConstellation_ClearBoundaryRaySamples }
procedure TConstellation.ClearBoundaryRaySamples;
var I: Integer;
begin
  for I := 0 to BoundaryRaySamples.Count - 1 do Dispose(PConstellationBoundaryRaySample(BoundaryRaySamples[I]));
  BoundaryRaySamples.Clear;
end;
{ @end $5F8500 }

{ @routine $5F8538 TConstellation_GenerateBoundaryRaySamples }
procedure TConstellation.GenerateBoundaryRaySamples(Count: Integer);
var Angle, Step: Single; I: Integer; Sample: PConstellationBoundaryRaySample;
begin
  ClearBoundaryRaySamples;
  Step := 2 * Pi / Count;
  Angle := 0;
  for I := 0 to Count - 1 do begin
    GetMem(Sample, SizeOf(TConstellationBoundaryRaySample));
    Sample.Position := MakePointF(Cos(Angle) + MapCenter.X, Sin(Angle) + MapCenter.Y);
    Sample.Direction := MakePointF(Cos(Angle), Sin(Angle));
    Sample.Angle := Angle;
    Sample.GrowthStopped := False;
    BoundaryRaySamples.Add(Sample);
    Angle := Angle + Step;
  end;
end;
{ @end $5F8538 }

{ @routine $5F8628 TConstellation_SetOutlinePolygon }
procedure TConstellation.SetOutlinePolygon(Polygon: TPolygon2D);
begin
  if OutlinePolygons <> nil then OutlinePolygons.Free;
  OutlinePolygons := Polygon;
  RebuildOutlineSegments;
end;
{ @end $5F8628 }
{ @routine $5F8648 TConstellation_RebuildOutlineSegments }
procedure TConstellation.RebuildOutlineSegments;
begin
  if OutlineSegments <> nil then OutlineSegments.Free;
  OutlineSegments := OutlinePolygons.ExtractBoundaryEdges;
  RefreshOutlineBounds;
end;
{ @end $5F8648 }
{ @routine $5F866C TConstellation_ClearOutlineSegmentsAndBounds }
procedure TConstellation.ClearOutlineSegmentsAndBounds;
var I: Integer;
begin
  for I := 0 to OutlineSegments.Count - 1 do Dispose(PMapLineSegment(OutlineSegments[I]));
  OutlineSegments.Clear;
  OutlineBounds := Classes.Rect(0, 0, 0, 0);
  OutlineBoundsSize := Classes.Point(0, 0);
end;
{ @end $5F866C }

{ @routine $5F86E4 TConstellation_AddStar }
procedure TConstellation.AddStar(Star: TStar);
begin
  Stars.Add(Star);
  Star.Constellation := Self;
end;
{ @end $5F86E4 }

{ @routine $5F8700 TConstellation_AddAdjacentConstellation }
procedure TConstellation.AddAdjacentConstellation(Constellation: TConstellation);
begin
  if not HasAdjacentConstellation(Constellation) then AdjacentConstellations.Add(Constellation);
end;
{ @end $5F8700 }

{ @routine $5F8720 TConstellation_SharesOutlineSegment }
function TConstellation.SharesOutlineSegment(Constellation: TConstellation): Boolean;
var I: Integer; Segment: PMapLineSegment;
begin
  if Self = Constellation then begin Result := True; Exit; end;
  for I := 0 to OutlineSegments.Count - 1 do begin
    Segment := OutlineSegments[I];
    if Constellation.HasOutlineSegment(Segment.StartPoint, Segment.EndPoint) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5F8720 }

{ @routine $5F8770 TConstellation_ResetGeneratedMapShape }
procedure TConstellation.ResetGeneratedMapShape;
begin
  ClearBoundaryRaySamples;
  ClearStarLinks;
  ClearOutlineSegmentsAndBounds;
  ClearStars;
  ClearAdjacentConstellations;
  OutlinePolygons.Free;
  OutlinePolygons := TPolygon2D.Create;
end;
{ @end $5F8770 }

{ @routine $5F87B0 TConstellation_ClearStars }
procedure TConstellation.ClearStars;
begin
  if Stars <> nil then Stars.Clear;
end;
{ @end $5F87B0 }

{ @routine $5F87C0 TConstellation_ClearAdjacentConstellations }
procedure TConstellation.ClearAdjacentConstellations;
begin
  if AdjacentConstellations <> nil then AdjacentConstellations.Clear;
end;
{ @end $5F87C0 }

{ @routine $5F87D0 TConstellation_GetOutlineArea }
function TConstellation.GetOutlineArea: Single;
begin
  Result := OutlinePolygons.GetChainArea;
end;
{ @end $5F87D0 }

{ @routine $5F87E4 TConstellation_FindNextClosestStarPair }
function TConstellation.FindNextClosestStarPair(var FirstStar, SecondStar: TStar; MinimumDistance: Integer): Integer;
var I, J, Distance, BestDistance: Integer; A, B: TStar; StartI, StartJ: Integer;
begin
  BestDistance := MinimumDistance + 1;
  StartI := 0;
  StartJ := -1;
  if FirstStar <> nil then StartI := FirstStar.ConstellationGraphIndex - 1;
  if SecondStar <> nil then StartJ := SecondStar.ConstellationGraphIndex - 1;
  FirstStar := nil;
  SecondStar := nil;
  for I := StartI to Stars.Count - 1 do
    for J := I + 1 to Stars.Count - 1 do
      if (I <> StartI) or ((I = StartI) and (J > StartJ)) then begin
        A := Stars[I];
        B := Stars[J];
        Distance := Round(PointDistance(A.Position, B.Position));
        if (Distance < BestDistance) and (Distance >= MinimumDistance) then begin
          BestDistance := Distance;
          FirstStar := A;
          SecondStar := B;
        end;
      end;
  if FirstStar = nil then begin
    BestDistance := Round(GalaxySizeY * Sqrt(2));
    for I := 0 to Stars.Count - 1 do
      for J := I + 1 to Stars.Count - 1 do begin
        A := Stars[I];
        B := Stars[J];
        Distance := Round(PointDistance(A.Position, B.Position));
        if (Distance < BestDistance) and (Distance > MinimumDistance) then begin
          BestDistance := Distance;
          FirstStar := A;
          SecondStar := B;
        end;
      end;
  end;
  if FirstStar = nil then Result := 0 else Result := BestDistance;
end;
{ @end $5F87E4 }

{ @routine $5F89AC TConstellation_HasStarGraphCycle }
function TConstellation.HasStarGraphCycle: Boolean;
var I: Integer; Link: PConstellationStarLink; Changed: Boolean; Parents: array[1..100] of Integer;
begin
  Result := False;
  if Stars.Count > 100 then Exit;
  for I := 0 to StarLinks.Count - 1 do begin Link := StarLinks[I]; Link.TraversalMark := False; end;
  while True do begin
    for I := 1 to Stars.Count do Parents[I] := -1;
    I := 0;
    Link := nil;
    while I < StarLinks.Count do begin
      Link := StarLinks[I];
      if not Link.TraversalMark then Break;
      Inc(I);
    end;
    if I = StarLinks.Count then Break;
    Parents[Link.StartStarIndex] := Link.EndStarIndex;
    Changed := True;
    while Changed do begin
      Changed := False;
      for I := 0 to StarLinks.Count - 1 do begin
        Link := StarLinks[I];
        if Parents[Link.StartStarIndex] <> -1 then begin
          Link.TraversalMark := True;
          if Parents[Link.EndStarIndex] = -1 then begin
            Changed := True;
            Parents[Link.EndStarIndex] := Link.StartStarIndex;
          end else if (Parents[Link.EndStarIndex] <> Link.StartStarIndex) and
            (Parents[Link.StartStarIndex] <> Link.EndStarIndex) then begin Result := True; Exit; end;
        end else if Parents[Link.EndStarIndex] <> -1 then begin
          Link.TraversalMark := True;
          if Parents[Link.StartStarIndex] = -1 then begin
            Changed := True;
            Parents[Link.StartStarIndex] := Link.EndStarIndex;
          end else if (Parents[Link.StartStarIndex] <> Link.EndStarIndex) and
            (Parents[Link.EndStarIndex] <> Link.StartStarIndex) then begin Result := True; Exit; end;
        end;
      end;
    end;
  end;
end;
{ @end $5F89AC }

{ @routine $5F8AFC TConstellation_IsStarGraphConnected }
function TConstellation.IsStarGraphConnected: Boolean;
var I, J: Integer; Link: PConstellationStarLink; Stable: Boolean; Parents: array[1..100] of Integer;
begin
  Result := False;
  if Stars.Count > 100 then Exit;
  for I := 0 to StarLinks.Count - 1 do begin Link := StarLinks[I]; Link.TraversalMark := False; end;
  for I := 1 to Stars.Count do Parents[I] := -1;
  Parents[1] := 0;
  for I := 0 to StarLinks.Count - 1 do begin
    Stable := True;
    for J := 0 to StarLinks.Count - 1 do begin
      Link := StarLinks[J];
      if (Parents[Link.StartStarIndex] <> -1) and (Parents[Link.EndStarIndex] = -1) then begin
        Parents[Link.EndStarIndex] := 0;
        Stable := False;
      end else if (Parents[Link.EndStarIndex] <> -1) and (Parents[Link.StartStarIndex] = -1) then begin
        Parents[Link.StartStarIndex] := 0;
        Stable := False;
      end;
    end;
    if Stable then Break;
  end;
  Result := True;
  for I := 1 to Stars.Count do if Parents[I] = -1 then Result := False;
end;
{ @end $5F8AFC }

{ @routine $5F8C04 TConstellation_BuildStarGraph }
function TConstellation.BuildStarGraph: Boolean;
var
  I: Integer;
  Star, FirstStar, SecondStar: TStar;
  MinimumDistance: Integer;
  Link: PConstellationStarLink;
  Segment: PMapLineSegment;
  Intersection: TPointF;
begin
  ClearStarLinks;
  for I := 0 to Stars.Count - 1 do begin
    Star := Stars[I];
    Star.ConstellationGraphIndex := Cardinal(I) + 1;
  end;
  MinimumDistance := 0;
  FirstStar := nil;
  SecondStar := nil;
  while True do begin
    MinimumDistance := FindNextClosestStarPair(FirstStar, SecondStar, MinimumDistance);
    if MinimumDistance = 0 then Break;
    GetMem(Link, SizeOf(TConstellationStarLink));
    Link.StartPoint := FirstStar.Position;
    Link.EndPoint := SecondStar.Position;
    Link.StartStarIndex := FirstStar.ConstellationGraphIndex;
    Link.EndStarIndex := SecondStar.ConstellationGraphIndex;
    StarLinks.Add(Link);
    if HasStarGraphCycle then begin
      StarLinks.Delete(StarLinks.Count - 1);
      Dispose(Link);
    end
    else
      for I := 0 to OutlineSegments.Count - 1 do begin
        Segment := OutlineSegments[I];
        if IntersectSegmentsF(Link.StartPoint, Link.EndPoint, Segment.StartPoint, Segment.EndPoint, Intersection) then begin
          StarLinks.Delete(StarLinks.Count - 1);
          Dispose(Link);
          Break;
        end;
      end;
  end;
  Result := IsStarGraphConnected;
end;
{ @end $5F8C04 }

{ @routine $5F8D5C TConstellation_ExpandOutlineBounds }
procedure TConstellation.ExpandOutlineBounds(Point: TPointF);
begin
  if OutlineBounds.Left > Point.X then OutlineBounds.Left := Round(Point.X);
  if OutlineBounds.Top > Point.Y then OutlineBounds.Top := Round(Point.Y);
  if OutlineBounds.Right < Point.X then OutlineBounds.Right := Round(Point.X);
  if OutlineBounds.Bottom < Point.Y then OutlineBounds.Bottom := Round(Point.Y);
end;
{ @end $5F8D5C }

{ @routine $5F8DD0 TConstellation_RefreshOutlineBounds }
procedure TConstellation.RefreshOutlineBounds;
var I: Integer; Segment: PMapLineSegment;
begin
  OutlineBounds.TopLeft := Classes.Point(0, 0);
  OutlineBounds.BottomRight := Classes.Point(0, 0);
  if OutlineSegments.Count <> 0 then begin
    Segment := OutlineSegments[0];
    OutlineBounds.Top := Round(Segment.StartPoint.Y);
    OutlineBounds.Left := Round(Segment.StartPoint.X);
    OutlineBounds.Bottom := Round(Segment.StartPoint.Y);
    OutlineBounds.Right := Round(Segment.StartPoint.X);
    for I := 0 to OutlineSegments.Count - 1 do begin
      Segment := OutlineSegments[I];
      ExpandOutlineBounds(Segment.StartPoint);
      ExpandOutlineBounds(Segment.EndPoint);
    end;
    OutlineBoundsSize := Classes.Point(OutlineBounds.Right - OutlineBounds.Left, OutlineBounds.Bottom - OutlineBounds.Top);
  end;
end;
{ @end $5F8DD0 }

{ @routine $5F8EA4 TConstellation_ContainsPoint }
function TConstellation.ContainsPoint(Point: TPointF): Boolean;
begin
  Result := False;
  if (OutlineBounds.Left <= Point.X) and (OutlineBounds.Top <= Point.Y) and
    (OutlineBounds.Right >= Point.X) and (OutlineBounds.Bottom >= Point.Y) then
  begin
    if OutlinePolygons <> nil then if OutlinePolygons.ChainContainsPoint(Point) then Result := True else Result := False;
  end;
end;
{ @end $5F8EA4 }

{ @routine $5F8F08 TConstellation_HasAdjacentConstellation }
function TConstellation.HasAdjacentConstellation(Constellation: TConstellation): Boolean;
var I: Integer;
begin
  Result := True;
  for I := 0 to AdjacentConstellations.Count - 1 do
    if AdjacentConstellations[I] = Constellation then Exit;
  Result := False;
end;
{ @end $5F8F08 }

{ @routine $5F8F44 TConstellation_HasOutlineSegment }
function TConstellation.HasOutlineSegment(FirstPoint, SecondPoint: TPointF): Boolean;
var I: Integer; Segment: PMapLineSegment;
begin
  for I := 0 to OutlineSegments.Count - 1 do begin
    Segment := OutlineSegments[I];
    if SegmentsNearlyEqualF(FirstPoint, SecondPoint, Segment.StartPoint, Segment.EndPoint) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5F8F44 }

{ @routine $5F8FA0 TConstellation_AreBothPointsOnOutline }
function TConstellation.AreBothPointsOnOutline(FirstPoint, SecondPoint: TPointF): Boolean;
var I: Integer; Segment: PMapLineSegment; Classification: Integer; FoundFirst, FoundSecond: Boolean;
begin
  FoundFirst := False;
  FoundSecond := False;
  for I := 0 to OutlineSegments.Count - 1 do begin
    Segment := OutlineSegments[I];
    Classification := ClassifyPointToSegment(Segment.StartPoint, Segment.EndPoint, FirstPoint);
    if Classification >= 5 then FoundFirst := True;
    Classification := ClassifyPointToSegment(Segment.StartPoint, Segment.EndPoint, SecondPoint);
    if Classification >= 5 then FoundSecond := True;
  end;
  Result := FoundFirst and FoundSecond;
end;
{ @end $5F8FA0 }

{ @routine $5F9028 TConstellation_CalculateLabelPosition }
function TConstellation.CalculateLabelPosition: TPointF;
var
  I: Integer;
  Segment: PMapLineSegment;
  MinPoint, MaxPoint: TPointF;
  X, Y, StepX, StepY, SumX, SumY: Single;
  Count: Integer;
begin
  MinPoint := MakePointF(1.0e20, 1.0e20);
  MaxPoint := MakePointF(-1.0e20, -1.0e20);
  for I := 0 to OutlineSegments.Count - 1 do
  begin
    Segment := OutlineSegments[I];
    MinPoint.X := Min(MinPoint.X, Segment.StartPoint.X);
    MinPoint.Y := Min(MinPoint.Y, Segment.StartPoint.Y);
    MaxPoint.X := Max(MaxPoint.X, Segment.StartPoint.X);
    MaxPoint.Y := Max(MaxPoint.Y, Segment.StartPoint.Y);
  end;
  StepX := (MaxPoint.X - MinPoint.X) / 10;
  StepY := (MaxPoint.Y - MinPoint.Y) / 10;
  SumX := 0;
  SumY := 0;
  Count := 0;
  Y := MinPoint.Y;
  while Y < MaxPoint.Y do
  begin
    X := MinPoint.X;
    while X < MaxPoint.X do
    begin
      if ContainsPoint(MakePointF(X, Y)) then
      begin
        SumX := SumX + X;
        SumY := SumY + Y;
        Inc(Count);
      end;
      X := X + StepX;
    end;
    Y := Y + StepY;
  end;
  Result := MakePointF(SumX / Count, SumY / Count);
end;
{ @end $5F9028 }

{ @routine $5F91AC TConstellation_HasOutlineVertex }
function TConstellation.HasOutlineVertex(Point: TPointF): Boolean;
var I: Integer; Segment: PMapLineSegment;
begin
  for I := 0 to OutlineSegments.Count - 1 do begin
    Segment := OutlineSegments[I];
    if PointsNearlyEqualF(Segment.StartPoint, Point) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5F91AC }

{ @routine $5F91F4 TConstellation_IsPointNearOutline }
function TConstellation.IsPointNearOutline(Point: TPointF): Boolean;
var I: Integer; Segment: PMapLineSegment; Minimum, Distance: Single;
begin
  Minimum := GalaxySizeX;
  for I := 0 to OutlineSegments.Count - 1 do begin
    Segment := OutlineSegments[I];
    Distance := PointSegmentDistanceF(Segment.StartPoint, Segment.EndPoint, Point);
    if Distance < Minimum then Minimum := Distance;
  end;
  if Minimum <= 2 then Result := True else Result := False;
end;
{ @end $5F91F4 }

{ @routine $5F926C TConstellation_NormalizeOutlineSegmentOrder }
procedure TConstellation.NormalizeOutlineSegmentOrder;
var I, J: Integer; First, Next: PMapLineSegment; Temp: Pointer; Point: TPointF;
begin
  for I := 0 to OutlineSegments.Count - 2 do begin
    First := OutlineSegments[I];
    J := I + 1;
    while J < OutlineSegments.Count do begin
      Next := OutlineSegments[J];
      if PointsNearlyEqualF(First.EndPoint, Next.StartPoint) then Break;
      if PointsNearlyEqualF(First.EndPoint, Next.EndPoint) then begin
        Point := Next.StartPoint;
        Next.StartPoint := Next.EndPoint;
        Next.EndPoint := Point;
        Break;
      end;
      Inc(J);
    end;
    if J < OutlineSegments.Count then begin
      Temp := OutlineSegments[I + 1];
      OutlineSegments[I + 1] := OutlineSegments[J];
      OutlineSegments[J] := Temp;
    end;
  end;
end;
{ @end $5F926C }

{ @routine $5F9348 TConstellation_GetName }
function TConstellation.GetName: WideString;
var Index: Integer;
begin
  Index := Galaxy.Constellations.IndexOf(Self);
  Result := LocalizedText(AnsiString('Constellations.Name.') + IntToStr(Index + 1));
end;
{ @end $5F9348 }

{ @routine $5F93F8 TConstellation_HasDominatorPresence }
function TConstellation.HasDominatorPresence: Boolean;
var I: Integer; Star: TStar;
begin
  for I := 0 to Stars.Count - 1 do begin
    Star := Stars[I];
    if Star.ShipTypeCounts[t_Kling] > 0 then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5F93F8 }

{ @routine $5F942C TConstellation_CountShipsByTypeMask }
function TConstellation.CountShipsByTypeMask(Types: TShipTypeMask): Integer;
var I: TShipType;
begin
  Result := 0;
  for I := t_Kling to t_ScientificBase do
    if I in Types then Inc(Result, ShipTypeCounts[I]);
end;
{ @end $5F942C }

{ @routine $5F945C TGalaxy_RefreshRangerWealthStats }
procedure TGalaxy.RefreshRangerWealthStats;
var I, Total: Integer; Ranger: TRanger;
begin
  if Rangers.Count <> 0 then
  begin
    Total := 0;
    MaxRangerWealth := 0;
    for I := 0 to Rangers.Count - 1 do
    begin
      Ranger := TRanger(Rangers[I]);
      Inc(Total, Ranger.CalculateWealth);
      if Ranger.Wealth > MaxRangerWealth then
      begin
        MaxRangerWealth := Ranger.Wealth;
        WealthiestRanger := Ranger;
      end;
    end;
    AverageRangerCapital := Total div Rangers.Count;
    RangerWealthDerivedValue1 := Round(AverageRangerCapital * (1 / 30));
    RangerWealthDerivedValue2 := Round(AverageRangerCapital * (1 / 30));
  end;
end;
{ @end $5F945C }

{ @routine $5F950C TGalaxy_RefreshRangerStrengthStats }
procedure TGalaxy.RefreshRangerStrengthStats;
var I: Integer; Total: Single; Ship: TShip;
begin
  if Rangers.Count = 0 then Exit;
  Total := 0;
  BestRangerStrength := 1;
  for I := 0 to Rangers.Count - 1 do begin
    Ship := Rangers[I];
    Total := Total + Ship.Strength;
    if BestRangerStrength < Ship.Strength then begin
      BestRangerStrength := Ship.Strength;
      StrongestRanger := Ship;
    end;
  end;
  AverageRangerStrength := Total / Rangers.Count;
end;
{ @end $5F950C }

{ @routine $5F9598 TGalaxy_RefreshRangerRatingPlaces }
procedure TGalaxy.RefreshRangerRatingPlaces;
var I, J: Integer; First, Second: TRanger; Sorted: array of Cardinal; SwapFirst, SwapSecond: Cardinal; // Native RTTI: dynamic Cardinal array storing object addresses.
begin
  SetLength(Sorted, Rangers.Count);
  for I := 0 to Rangers.Count - 1 do
  begin
    First := Rangers[I];
    Sorted[I] := Cardinal(First);
  end;
  for I := 0 to Rangers.Count - 1 do
    for J := I to Rangers.Count - 1 do
    begin
      First := TRanger(Sorted[I]);
      Second := TRanger(Sorted[J]);
      if First.TotalExperience < Second.TotalExperience then
      begin
        SwapFirst := Sorted[I];
        SwapSecond := Sorted[J];
        Sorted[J] := SwapFirst;
        Sorted[I] := SwapSecond;
      end;
    end;
  for I := 0 to Rangers.Count - 1 do
  begin
    First := TRanger(Sorted[I]);
    First.PlaceInRating := I + 1;
  end;
end;
{ @end $5F9598 }

{ @routine $5F96C8 TGalaxy_FindStrongestRanger }
function TGalaxy.FindStrongestRanger: TObject;
var I: Integer; BestValue: Single; Ship: TShip;
begin
  BestValue := 0;
  Result := nil;
  for I := 0 to Rangers.Count - 1 do begin
    Ship := Rangers[I];
    if Ship.Strength > BestValue then begin
      Result := Ship;
      BestValue := Ship.Strength;
    end;
  end;
end;
{ @end $5F96C8 }

{ @routine $5F9710 TGalaxy_FindWealthiestRanger }
function TGalaxy.FindWealthiestRanger: TObject;
var I: Integer; BestValue: Single; Ship: TShip;
begin
  BestValue := 0;
  Result := nil;
  for I := 0 to Rangers.Count - 1 do begin
    Ship := Rangers[I];
    if Ship.Wealth > BestValue then begin
      Result := Ship;
      BestValue := Ship.Wealth;
    end;
  end;
end;
{ @end $5F9710 }

{ @routine $5F9758 TGalaxy_CountStarsByFaction }
function TGalaxy.CountStarsByFaction(Faction: TStarControlFaction): Integer;
var I: Integer; Star: TStar;
begin
  Result := 0;
  for I := 0 to Stars.Count - 1 do begin
    Star := Stars[I];
    if Faction = Star.ControlFaction then Inc(Result);
  end;
end;
{ @end $5F9758 }

{ @routine $5F9794 TGalaxy_GetFactionControlPercent }
function TGalaxy.GetFactionControlPercent(Faction: TStarControlFaction): TPercent;
begin
  Result := Round(CountStarsByFaction(Faction) / Stars.Count * 100);
end;
{ @end $5F9794 }

{ @routine $5F97C8 TGalaxy_AssignTextQuestsToPlanets }
procedure TGalaxy.AssignTextQuestsToPlanets;
var I, J, Index, Number: Integer; Content: TQuestGameContent; Planet: TPlanet;
begin
  for I := 0 to LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamCount - 1 do begin
    if IsIntegerTextW(LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamName(I)) then begin
      Number := StrToInt(LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').GetParamName(I));
      Content := TQuestGameContent.Create;
      Content.LoadQuest(Number);
      Index := NextRandomIntRange(0, Planets.Count - 1, RandomState);
      for J := 0 to Planets.Count - 1 do begin
        IncrementWrapped(Index, 0, Planets.Count - 1);
        Planet := Planets[Index];
        if (Planet.TextQuestId > -1) or (Planet.OwnerId = oiKling) then Continue;
        if ((Planet.OwnerId = oiNone) and (6 in Content.TargetOwnerMask)) or
          ((0 in Content.TargetOwnerMask) and (Planet.OwnerId = oiMaloc)) or
          ((1 in Content.TargetOwnerMask) and (Planet.OwnerId = oiPeleng)) or
          ((2 in Content.TargetOwnerMask) and (Planet.OwnerId = oiPeople)) or
          ((3 in Content.TargetOwnerMask) and (Planet.OwnerId = oiFei)) or
          ((4 in Content.TargetOwnerMask) and (Planet.OwnerId = oiGaal)) or
          ((Content.TargetOwnerMask = []) and
            (((Planet.RaceId = raMaloc) and (0 in Content.IssuerRaceMask)) or
             ((Planet.RaceId = raPeleng) and (1 in Content.IssuerRaceMask)) or
             ((Planet.RaceId = raPeople) and (2 in Content.IssuerRaceMask)) or
             ((Planet.RaceId = raFei) and (3 in Content.IssuerRaceMask)) or
             ((Planet.RaceId = raGaal) and (4 in Content.IssuerRaceMask)))) then begin
          Planet.TextQuestId := Number;
          Break;
        end;
      end;
      Content.Free;
    end;
  end;
end;
{ @end $5F97C8 }

{ @routine $5F9A3C TGalaxy_HasPlayerQuestHistory }
function TGalaxy.HasPlayerQuestHistory(QuestType: TQuestType; QuestNumber: Word): Boolean;
var I: Integer; Quest: PPlayerOldQuest;
begin
  for I := PlayerOldQuests.Count - 1 downto 0 do begin
    Quest := PlayerOldQuests[I];
    if (QuestType = Quest.QuestType) and (QuestNumber = Quest.QuestNumber) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5F9A3C }

{ @routine $5F9A7C TGalaxy_TurnToDateTime }
function TGalaxy.TurnToDateTime(Turn: Integer): Double;
begin
  if Turn = -1 then Turn := CurrentTurn;
  Result := Turn + 401768.5;
end;
{ @end $5F9A7C }

{ @routine $5F9AA4 TGalaxy_FormatTurnDate }
function TGalaxy.FormatTurnDate(Turn: Integer): WideString;
var
  MonthNumber, MonthName: WideString;
begin
  if Turn = -1 then Turn := CurrentTurn;
  MonthNumber := FormatDateTime('mm', TurnToDateTime(Turn - 200));
  MonthName := LocalizedText('Month.' + MonthNumber);
  Result := FormatDateTime('d', TurnToDateTime(Turn - 200)) + ' ' + MonthName + ' ' + FormatDateTime('yyyy', TurnToDateTime(Turn - 200));
end;
{ @end $5F9AA4 }

{ @routine $5F9C40 TGalaxy_AddPlanetNewsWithPlayerBubble }
procedure TGalaxy.AddPlanetNewsWithPlayerBubble(Text: WideString);
begin
  AddOrUpdatePlayerBubble(pmGalaxy, CurrentTurn, Text, '');
  AddPlanetNews(gnGeneral, Text);
end;
{ @end $5F9C40 }

{ @routine $5F9C9C TGalaxy_AddPlanetNews }
procedure TGalaxy.AddPlanetNews(NewsType: TGalaxyNewsKind; Text: WideString);
var Entry: PPlanetNewsEntry;
begin
  if Text = '' then raise Exception.Create('Error! Получена пустая планетарная новость');
  New(Entry);
  Entry.Turn := CurrentTurn;
  Entry.NewsType := NewsType;
  Entry.Text := Text;
  PlanetNews.Add(Entry);
end;
{ @end $5F9C9C }

{ @routine $5F9D6C TGalaxy_CountPlanetNewsByType }
function TGalaxy.CountPlanetNewsByType(NewsType: TGalaxyNewsKind): Integer;
var Entry: PPlanetNewsEntry; Index: Integer;
begin
  Result := 0;
  for Index := 0 to PlanetNews.Count - 1 do
  begin
    Entry := PlanetNews[Index];
    if Entry.NewsType = NewsType then Inc(Result);
  end;
end;
{ @end $5F9D6C }

{ @routine $5F9DB0 TGalaxy_PrunePlanetNews }
procedure TGalaxy.PrunePlanetNews;
var I: Integer; News: PPlanetNewsEntry;
begin
  for I := PlanetNews.Count - 1 downto 0 do begin
    News := PlanetNews[I];
    if News.Turn < CurrentTurn - 30 then begin
      PlanetNews.Delete(I);
      Dispose(News);
    end;
  end;
end;
{ @end $5F9DB0 }

{ @routine $5F9E04 TGalaxy_CreateKlissanSpawnProxy }
procedure TGalaxy.CreateKlissanSpawnProxy(Star: TObject);
begin
  KlissanSpawnPlanet := TPlanet.Create;
  KlissanSpawnPlanet.InitKlissanSpawnProxy(Star as TStar);
end;
{ @end $5F9E04 }

{ @routine $5F9E38 TGalaxy_UpdateConstellationMilitaryStats }
procedure TGalaxy.UpdateConstellationMilitaryStats;
var I, J: Integer; Constellation: TConstellation; Star: TStar; Kind: TShipType;
begin
  for Kind := t_Kling to t_ScientificBase do ShipTypeCounts[Kind] := 0;
  for I := 0 to Galaxy.Constellations.Count - 1 do begin
    Constellation := Galaxy.Constellations[I];
    for Kind := t_Kling to t_ScientificBase do Constellation.ShipTypeCounts[Kind] := 0;
    for J := 0 to Constellation.Stars.Count - 1 do begin
      Star := Constellation.Stars[J];
      Star.RecountShipTypes;
      for Kind := t_Kling to t_ScientificBase do begin
        Inc(Constellation.ShipTypeCounts[Kind], Star.ShipTypeCounts[Kind]);
        Inc(ShipTypeCounts[Kind], Star.ShipTypeCounts[Kind]);
      end;
    end;
  end;
end;
{ @end $5F9E38 }

{ @routine $5F9F0C TGalaxy_RefreshTechLevel }
function TGalaxy.RefreshTechLevel: Byte;
var I, HighestCount, HighestLevel: Integer; Planet: TPlanet;
begin
  Result := 0;
  HighestCount := 0;
  HighestLevel := 0;
  for I := 0 to Planets.Count - 1 do
  begin
    Planet := TPlanet(Planets[I]);
    if Planet.IsCoalitionOwned then
    begin
      if Planet.InventionLevels[invTechLevel] > HighestLevel then
      begin
        HighestCount := 1;
        HighestLevel := Planet.InventionLevels[invTechLevel];
      end
      else if Planet.InventionLevels[invTechLevel] = HighestLevel then Inc(HighestCount);
    end;
  end;
  if HighestCount >= 5 then TechLevel := Max(1, HighestLevel)
  else if HighestCount >= 2 then TechLevel := Max(1, HighestLevel - 1)
  else TechLevel := Max(1, HighestLevel - 2);
end;
{ @end $5F9F0C }

{ @routine $5F9FBC TGalaxy_CancelEnemyJumpsToStar }
procedure TGalaxy.CancelEnemyJumpsToStar(Star: TStar);
var I, J: Integer; Other: TStar; Ship: TShip;
begin
  for I := 0 to Stars.Count - 1 do
  begin
    Other := TStar(Stars[I]);
    for J := 0 to Other.Ships.Count - 1 do
    begin
      Ship := TShip(Other.Ships[J]);
      if (Ship is TKling) and (Ship.Order = soJump) and (Ship.OrderTarget = Star) then Ship.OrderNone;
    end;
  end;
end;
{ @end $5F9FBC }

{ @routine $5FA054 TGalaxy_SelectStarForLiberationAttack }
function TGalaxy.SelectStarForLiberationAttack(Origin: TStar): TStar;
var
  I, J, Weight, BestWeight: Integer;
  Star, Other: TStar;
  Faction: TStarControlFaction;
begin
  BestWeight := MaxInt;
  Result := nil;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    Faction := Star.ControlFaction;
    if (Faction <> sfCoalition) and not Star.Battle then
    begin
      Weight := 0;
      for J := 1 to Galaxy.Stars.Count - 1 do
      begin
        Other := Star.StarDistances[J].Star as TStar;
        Faction := Other.ControlFaction;
        if Faction = sfCoalition then Inc(Weight, Star.StarDistances[J].Distance);
      end;
      if Origin <> nil then Weight := Round(RemapClamped(PointDistance(Origin.Position, Star.Position), 10, 100, Weight, 100 * Weight));
      Weight := Round(NextRandomFloatRange(Weight, 2 * Weight, RandomState));
      if Weight < BestWeight then
      begin
        BestWeight := Weight;
        Result := Star;
      end;
    end;
  end;
end;
{ @end $5FA054 }
{ @routine $5FA1A8 TGalaxy_RefreshGoodsMarketPrices }
procedure TGalaxy.RefreshGoodsMarketPrices;
var Good: TGoodsIndex; Spread: Single;
begin
  for Good := t_Food to t_Narcotics do begin
    GoodsMarket[Good].MinPrice := ScaleGoodsPriceByGalaxyAge(InitialGoodsMarket[Good].MinPrice);
    GoodsMarket[Good].BasePrice := ScaleGoodsPriceByGalaxyAge(InitialGoodsMarket[Good].BasePrice);
    GoodsMarket[Good].MaxPrice := ScaleGoodsPriceByGalaxyAge(InitialGoodsMarket[Good].MaxPrice);
    Spread := GoodsMarket[Good].BasePrice - GoodsMarket[Good].MinPrice;
    Inc(GoodsMarket[Good].MinPrice, Round(Spread * DifficultyModifiers[Difficulty].MarketPriceSpreadReduction));
    if GoodsMarket[Good].BasePrice - 1 <= GoodsMarket[Good].MinPrice then GoodsMarket[Good].MinPrice := GoodsMarket[Good].BasePrice - 2;
    Dec(GoodsMarket[Good].MaxPrice, Round(Spread * DifficultyModifiers[Difficulty].MarketPriceSpreadReduction));
    if GoodsMarket[Good].BasePrice + 1 >= GoodsMarket[Good].MaxPrice then GoodsMarket[Good].MaxPrice := GoodsMarket[Good].BasePrice + 2;
  end;
end;
{ @end $5FA1A8 }
{ @routine $5FA278 TGalaxy_ScaleGoodsPriceByGalaxyAge }
function TGalaxy.ScaleGoodsPriceByGalaxyAge(Value: Integer): Integer;
begin
  Result := Round(RemapClamped(CurrentTurn, 1000, 10000, Value, Value * 3));
end;
{ @end $5FA278 }

{ @routine $5FA2CC TGalaxy_ScaleByTechLevel }
function TGalaxy.ScaleByTechLevel(LowValue, HighValue: Integer): Integer;
begin
  if LowValue <= HighValue then Result := Round(RemapClamped(TechLevel, 2, 6, LowValue, HighValue))
  else Result := Round(RemapClampedAlternate(TechLevel, 2, 6, LowValue, HighValue));
end;
{ @end $5FA2CC }

{ @routine $5FA37C TGalaxy_SelectRandomWeaponTypes }
function TGalaxy.SelectRandomWeaponTypes(Level, Count: Byte; Heavy: Boolean; Seed: Cardinal): TItemTypeMask;
var Value, I, Added: Integer; Kind: TItemType;
begin
  Result := [];
  Added := 0;
  Value := SeededRandomIntRange(Ord(t_PhotonGun), Ord(t_EyesOfMachpella), Seed);
  for I := 0 to 14 do
  begin
    IncrementWrapped(Value, Ord(t_PhotonGun), Ord(t_EyesOfMachpella));
    Kind := TItemType(Value);
    if Abs(WeaponInfo[Kind].RequiredTechLevel - Level) <= 1 then
      if not ((Heavy = True) and (Kind in StandardWeaponTypes)) then
        if Heavy or not (Kind in HeavyWeaponTypes) then
        begin
          Include(Result, Kind);
          Inc(Added);
          if Added >= Count then Break;
        end;
  end;
end;
{ @end $5FA37C }

{ @routine $5FA468 TGalaxy_ComputeScaledMiniMoney }
function TGalaxy.ComputeScaledMiniMoney(Owner: TOwnerId): Integer;
begin
  Result := Round(AverageRangerCapital * 0.01 * OwnerInfo[Owner].FuelPriceFactor);
  if Result > 250 then Result := Round((Result - 250) * 0.3) + 250;
end;
{ @end $5FA468 }

{ @routine $5FA4D8 TGalaxy_ComputeScaledSmallMoney }
function TGalaxy.ComputeScaledSmallMoney(Owner: TOwnerId): Integer;
begin
  Result := Round(AverageRangerCapital * (1 / 70) * OwnerInfo[Owner].FuelPriceFactor);
  if Result > 1000 then Result := Round((Result - 1000) * 0.3) + 1000;
end;
{ @end $5FA4D8 }

{ @routine $5FA548 TGalaxy_ComputeScaledAverageMoney }
function TGalaxy.ComputeScaledAverageMoney(Owner: TOwnerId): Integer;
begin
  Result := Round(AverageRangerCapital * 0.025 * OwnerInfo[Owner].FuelPriceFactor);
  if Result > 5000 then Result := Round((Result - 5000) * 0.3) + 5000;
end;
{ @end $5FA548 }

{ @routine $5FA5B8 TGalaxy_ComputeScaledBigMoney }
function TGalaxy.ComputeScaledBigMoney(Owner: TOwnerId): Integer;
begin
  Result := Round(AverageRangerCapital * (1 / 30) * OwnerInfo[Owner].FuelPriceFactor);
  if Result > 10000 then Result := Round((Result - 10000) * 0.3) + 10000;
end;
{ @end $5FA5B8 }

{ @routine $5FA628 TGalaxy_ComputeScaledHugeMoney }
function TGalaxy.ComputeScaledHugeMoney(Owner: TOwnerId): Integer;
begin
  Result := Round(AverageRangerCapital * (1 / 20) * OwnerInfo[Owner].FuelPriceFactor);
  if Result > 25000 then Result := Round((Result - 25000) * 0.3) + 25000;
end;
{ @end $5FA628 }

{ @routine $5FA698 TGalaxy_ResolveMoneySizeTag }
function TGalaxy.ResolveMoneySizeTag(Tag: WideString; Owner: TOwnerId): Integer;
begin
  if Tag = 'Zero' then Result := 0
  else if Tag = 'Mini' then Result := Galaxy.ComputeScaledMiniMoney(Owner)
  else if Tag = 'Small' then Result := Galaxy.ComputeScaledSmallMoney(Owner)
  else if Tag = 'Average' then Result := Galaxy.ComputeScaledAverageMoney(Owner)
  else if Tag = 'Big' then Result := Galaxy.ComputeScaledBigMoney(Owner)
  else if Tag = 'Huge' then Result := Galaxy.ComputeScaledHugeMoney(Owner)
  else begin RaiseWideMessage('Error! Указан неправильный формат размера у вещи ' + Tag); Result := -1; end;
end;
{ @end $5FA698 }

{ @routine $5FA880 TGalaxy_GetMiniGoodsQuantity }
function TGalaxy.GetMiniGoodsQuantity(GoodsType: TGoodsIndex): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 0.1);
end;
{ @end $5FA880 }
{ @routine $5FA8B0 TGalaxy_GetSmallGoodsQuantity }
function TGalaxy.GetSmallGoodsQuantity(GoodsType: TGoodsIndex): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 0.5);
end;
{ @end $5FA8B0 }

{ @routine $5FA8D8 TGalaxy_GetAverageGoodsQuantity }
function TGalaxy.GetAverageGoodsQuantity(GoodsType: TGoodsIndex): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 1);
end;
{ @end $5FA8D8 }

{ @routine $5FA8FC TGalaxy_GetBigGoodsQuantity }
function TGalaxy.GetBigGoodsQuantity(GoodsType: TGoodsIndex): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 1.5);
end;
{ @end $5FA8FC }

{ @routine $5FA924 TGalaxy_GetHugeGoodsQuantity }
function TGalaxy.GetHugeGoodsQuantity(GoodsType: TGoodsIndex): Integer;
begin
  Result := Round(GoodsMarket[GoodsType].BaseStock * 2.0);
end;
{ @end $5FA924 }

{ @routine $5FA94C TGalaxy_GetGoodsQuantityBySize }
function TGalaxy.GetGoodsQuantityBySize(Size: TStandardCount; GoodsType: TGoodsIndex): Integer;
begin
  if Size = scZero then Result := 0
  else if Size = scMini then Result := Galaxy.GetMiniGoodsQuantity(GoodsType)
  else if Size = scSmall then Result := Galaxy.GetSmallGoodsQuantity(GoodsType)
  else if Size = scAverage then Result := Galaxy.GetAverageGoodsQuantity(GoodsType)
  else if Size = scBig then Result := Galaxy.GetBigGoodsQuantity(GoodsType)
  else if Size = scHuge then Result := Galaxy.GetHugeGoodsQuantity(GoodsType)
  else begin RaiseWideMessage('Error! Указан неправильный формат количества товара '); Result := -1; end;
end;
{ @end $5FA94C }

{ @routine $5FAA30 TGalaxy_ClassifyGoodsQuantity }
function TGalaxy.ClassifyGoodsQuantity(Quantity: Integer; GoodsType: TGoodsIndex): TStandardCount;
var Distance1, Distance2, Distance3, Distance4, Distance5: Integer;
begin
  if Quantity = 0 then begin Result := scZero; Exit; end;
  Distance1 := Abs(GetGoodsQuantityBySize(scMini, GoodsType) - Quantity);
  Distance2 := Abs(GetGoodsQuantityBySize(scSmall, GoodsType) - Quantity);
  Distance3 := Abs(GetGoodsQuantityBySize(scAverage, GoodsType) - Quantity);
  Distance4 := Abs(GetGoodsQuantityBySize(scBig, GoodsType) - Quantity);
  Distance5 := Abs(GetGoodsQuantityBySize(scHuge, GoodsType) - Quantity);
  if Distance1 < Distance2 then Result := scMini
  else if Distance2 < Distance3 then Result := scSmall
  else if Distance3 < Distance4 then Result := scAverage
  else if Distance4 < Distance5 then Result := scBig
  else Result := scHuge;
end;
{ @end $5FAA30 }

{ @routine $5FAAE4 TGalaxy_GetMinimumGoodsPrice }
function TGalaxy.GetMinimumGoodsPrice(GoodsType: TGoodsIndex): Integer;
begin
  Result := GoodsMarket[GoodsType].MinPrice;
end;
{ @end $5FAAE4 }

{ @routine $5FAAF8 TGalaxy_GetLowGoodsPrice }
function TGalaxy.GetLowGoodsPrice(GoodsType: TGoodsIndex): Integer;
begin
  Result := (GoodsMarket[GoodsType].MinPrice + GoodsMarket[GoodsType].BasePrice) div 2;
end;
{ @end $5FAAF8 }

{ @routine $5FAB20 TGalaxy_GetAverageGoodsPrice }
function TGalaxy.GetAverageGoodsPrice(GoodsType: TGoodsIndex): Integer;
begin
  Result := GoodsMarket[GoodsType].BasePrice;
end;
{ @end $5FAB20 }

{ @routine $5FAB34 TGalaxy_GetHighGoodsPrice }
function TGalaxy.GetHighGoodsPrice(GoodsType: TGoodsIndex): Integer;
begin
  Result := (GoodsMarket[GoodsType].BasePrice + GoodsMarket[GoodsType].MaxPrice) div 2;
end;
{ @end $5FAB34 }

{ @routine $5FAB5C TGalaxy_GetMaximumGoodsPrice }
function TGalaxy.GetMaximumGoodsPrice(GoodsType: TGoodsIndex): Integer;
begin
  Result := GoodsMarket[GoodsType].MaxPrice;
end;
{ @end $5FAB5C }

{ @routine $5FAB70 TGalaxy_GetGoodsPriceByLevel }
function TGalaxy.GetGoodsPriceByLevel(Level: TStandardCount; GoodsType: TGoodsIndex): Integer;
begin
  if Level = scMini then Result := Galaxy.GetMinimumGoodsPrice(GoodsType)
  else if Level = scSmall then Result := Galaxy.GetLowGoodsPrice(GoodsType)
  else if Level = scAverage then Result := Galaxy.GetAverageGoodsPrice(GoodsType)
  else if Level = scBig then Result := Galaxy.GetHighGoodsPrice(GoodsType)
  else if Level = scHuge then Result := Galaxy.GetMaximumGoodsPrice(GoodsType)
  else begin RaiseWideMessage('Error! Указан неправильный формат стоимости товара '); Result := -1; end;
end;
{ @end $5FAB70 }

{ @routine $5FAC48 TGalaxy_ClassifyGoodsPrice }
function TGalaxy.ClassifyGoodsPrice(Price: Integer; GoodsType: TGoodsIndex): TStandardCount;
var Distance1, Distance2, Distance3, Distance4, Distance5: Integer;
begin
  if Price = 0 then begin Result := scZero; Exit; end;
  Distance1 := Abs(GetGoodsPriceByLevel(scMini, GoodsType) - Price);
  Distance2 := Abs(GetGoodsPriceByLevel(scSmall, GoodsType) - Price);
  Distance3 := Abs(GetGoodsPriceByLevel(scAverage, GoodsType) - Price);
  Distance4 := Abs(GetGoodsPriceByLevel(scBig, GoodsType) - Price);
  Distance5 := Abs(GetGoodsPriceByLevel(scHuge, GoodsType) - Price);
  if Distance1 < Distance2 then Result := scMini
  else if Distance2 < Distance3 then Result := scSmall
  else if Distance3 < Distance4 then Result := scAverage
  else if Distance4 < Distance5 then Result := scBig
  else Result := scHuge;
end;
{ @end $5FAC48 }

{ @routine $5FACFC TGalaxy_TryCreateDailyStation }
procedure TGalaxy.TryCreateDailyStation;
begin
  case (CurrentTurn + 100) mod 4 of
    0: TryCreateRangerCenter;
    1: TryCreatePirateBase;
    2: TryCreateMilitaryBase;
    3: TryCreateScienceBase;
  end;
end;
{ @end $5FACFC }

{ @routine $5FAD38 TGalaxy_TryCreateRangerCenter }
procedure TGalaxy.TryCreateRangerCenter;
var I: Integer; Constellation: TConstellation; Star: TStar; Station: TRC;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if (Constellation.ShipTypeCounts[t_RangerCenter] <= 0) and
      (Constellation.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) < Constellation.Stars.Count) and
      (Constellation.ShipTypeCounts[t_Kling] <= 0) then
    begin
      Star := TStar(Constellation.Stars[NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState)]);
      if (Star <> Player.CurrentStar) and (Star.DaysSincePlayerVisit >= 70) and
        (Star.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) <= 1) then
      begin
        Station := TRC.Create;
        Station.Init(Star);
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(
          PickLocalizedTextVariant('GalaxyNews.CreateNewObject.RC', GenerationSeed * (Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Station.GetName, '<Star>', Star.Name));
        Break;
      end;
    end;
  end;
end;
{ @end $5FAD38 }

{ @routine $5FAF44 TGalaxy_TryCreatePirateBase }
procedure TGalaxy.TryCreatePirateBase;
var I: Integer; Constellation: TConstellation; Star: TStar; Station: TPB;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if (Constellation.ShipTypeCounts[t_PirateBase] <= 0) and
      (Constellation.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) < Constellation.Stars.Count) and
      (Constellation.ShipTypeCounts[t_Kling] <= 0) then
    begin
      Star := TStar(Constellation.Stars[NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState)]);
      if (Star <> Player.CurrentStar) and (Star.DaysSincePlayerVisit >= 70) and
        (Star.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) <= 1) and
        (Star.CountShipsByTypeMask([t_MilitaryBase]) <= 0) then
      begin
        Station := TPB.Create;
        Station.Init(Star);
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(
          PickLocalizedTextVariant('GalaxyNews.CreateNewObject.PB', GenerationSeed * (Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Station.GetName, '<Star>', Star.Name));
        Break;
      end;
    end;
  end;
end;
{ @end $5FAF44 }

{ @routine $5FB168 TGalaxy_TryCreateMilitaryBase }
procedure TGalaxy.TryCreateMilitaryBase;
var I: Integer; Constellation: TConstellation; Star: TStar; Station: TWB;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if (Constellation.ShipTypeCounts[t_MilitaryBase] <= 0) and
      (Constellation.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) < Constellation.Stars.Count) and
      (Constellation.ShipTypeCounts[t_Kling] <= 0) then
    begin
      Star := TStar(Constellation.Stars[NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState)]);
      if (Star <> Player.CurrentStar) and (Star.DaysSincePlayerVisit >= 70) and
        (Star.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) <= 1) and
        (Star.CountShipsByTypeMask([t_PirateBase]) <= 0) then
      begin
        Station := TWB.Create;
        Station.Init(Star);
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(
          PickLocalizedTextVariant('GalaxyNews.CreateNewObject.WB', GenerationSeed * (Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Station.GetName, '<Star>', Star.Name));
        Break;
      end;
    end;
  end;
end;
{ @end $5FB168 }

{ @routine $5FB38C TGalaxy_TryCreateScienceBase }
procedure TGalaxy.TryCreateScienceBase;
var I: Integer; Constellation: TConstellation; Star: TStar; Station: TSB;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if (Constellation.ShipTypeCounts[t_ScientificBase] <= 0) and
      (Constellation.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) < Constellation.Stars.Count) and
      (Constellation.ShipTypeCounts[t_Kling] <= 0) then
    begin
      Star := TStar(Constellation.Stars[NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState)]);
      if (Star <> Player.CurrentStar) and (Star.DaysSincePlayerVisit >= 70) and
        (Star.CountShipsByTypeMask([t_RangerCenter, t_PirateBase, t_MilitaryBase, t_ScientificBase]) <= 1) then
      begin
        Station := TSB.Create;
        Station.Init(Star);
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(
          PickLocalizedTextVariant('GalaxyNews.CreateNewObject.SB', GenerationSeed * (Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Station.GetName, '<Star>', Star.Name));
        Break;
      end;
    end;
  end;
end;
{ @end $5FB38C }

{ @routine $5FB598 TGalaxy_AdvanceCommunicatorResearch }
procedure TGalaxy.AdvanceCommunicatorResearch;
begin
  if (CommunicatorResearchProgress < 100) and (ShipTypeCounts[t_ScientificBase] > 0) then
  begin
    CommunicatorResearchProgress := CommunicatorResearchProgress + CommunicatorResearchPerDay;
    if CommunicatorResearchProgress < 100 then
    begin
      if (CommunicatorResearchPerDay >= 0.005) and (CurrentTurn mod 90 = 0) then
        CommunicatorResearchPerDay := CommunicatorResearchPerDay -
          CommunicatorResearchPerDay / 100 * DifficultyModifiers[Difficulty].CommunicatorResearchDecayPercent;
    end
    else
    begin
      CommunicatorResearchProgress := 100;
      Galaxy.AddPlanetNewsWithPlayerBubble(PickLocalizedTextVariant('GalaxyNews.SB.CommunicatorCreate',
        GenerationSeed * (Galaxy.CurrentTurn div 10)));
    end;
  end;
end;
{ @end $5FB598 }

{ @routine $5FB70C TGalaxy_ApplyNodeDepositInactivityPenalty }
procedure TGalaxy.ApplyNodeDepositInactivityPenalty;
begin
  if Player <> nil then
    if Galaxy.CurrentTurn > 3 * 365 * DifficultyModifiers[Galaxy.Difficulty].NodeDepositGraceFactor + 200 then
    begin
      Inc(Player.UnresolvedCounter1F4);
      if (Player.CurrentStar.ControlFaction = sfCoalition) and
        (Player.UnresolvedCounter1F4 > 2 * 365 * DifficultyModifiers[Galaxy.Difficulty].NodeDepositGraceFactor) then
      begin
        Player.ChangePlanetRelations(Player.CurrentStar, rcmDecreaseWithFloor20, 90, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
        Player.ChangeShipRelations(Player.CurrentStar, rcmDecreaseWithFloor20, 90, [htRanger, htTransport, htLiner, htDiplomat], [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(
          PickLocalizedTextVariant('GalaxyNews.RC.PlayerNotWork', GenerationSeed * (Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Month>', IntToStr(Player.UnresolvedCounter1F4 div 30),
          '<Star>', Player.CurrentStar.Name));
        Player.ResetCounterAfterNodeDeposit;
      end;
    end;
end;
{ @end $5FB70C }

{ @routine $5FB978 TGalaxy_TryCreateLiberationGroup }
function TGalaxy.TryCreateLiberationGroup(Mode: Byte): Boolean;
var
  I, Index, J, K: Integer;
  Star: TStar;
  Ship: TShip;
  Planet: TPlanet;
  Group: TGroup;
  Constellation: TConstellation;
  GroupStrength: Single;
  ShipCount: Integer;
begin
  Result := False;
  // Nonzero modes return success without creating a group.
  case Mode of
    0:
    begin
      if (Galaxy.GetFactionControlPercent(sfCoalition) > 90) and
        (NextRandomUnitFloat(RandomState) < 0.5) and (Galaxy.WarDeltaWin > 3) then Exit;
      if (Galaxy.WarDeltaWin > 5) and (NextRandomUnitFloat(RandomState) < 0.8) then Exit;
      Constellation := nil;
      Index := NextRandomIntRange(0, Constellations.Count - 1, RandomState);
      for I := 0 to Constellations.Count - 1 do
      begin
        IncrementWrapped(Index, 0, Constellations.Count - 1);
        Constellation := TConstellation(Constellations[Index]);
        if not Constellation.HasDominatorPresence then Break;
      end;
      if Constellation <> nil then
      begin
        Group := TGroup.Create;
        LiberationGroups.Add(Group);
        ShipCount := 0;
        GroupStrength := 0;
        Index := NextRandomIntRange(0, Constellation.Stars.Count - 1, RandomState);
        for I := 0 to Constellation.Stars.Count - 1 do
        begin
          IncrementWrapped(Index, 0, Constellation.Stars.Count - 1);
          Star := TStar(Constellation.Stars[Index]);
          if (Star.ControlFaction <> sfKlissan) and not Star.Battle and not Star.HasLiberationGroupOrder then
            for J := 0 to Star.Planets.Count - 1 do
            begin
              Planet := TPlanet(Star.Planets[J]);
              if not Planet.IsCoalitionOwned then Continue;
              for K := NextRandomIntRange(0, 1, Planet.RandomState) to Planet.Warriors.Count - 1 do
              begin
                Ship := TShip(Planet.Warriors[K]);
                if (Ship.ScriptShip <> nil) or (Ship.CurrentPlanet <> Planet) or
                  (Star.Ships.IndexOf(Ship) >= 0) then Continue;
                begin
                  Ship.LiberationGroup := Group;
                  Star.Ships.Add(Ship);
                  Group.AddShip(Ship);
                  Inc(ShipCount);
                  Ship.UpdateAverageRangerRelativeStrength;
                  GroupStrength := GroupStrength + Ship.StrengthInAverageRanger;
                  if (ShipCount > NextRandomIntRange(5, 7, RandomState)) or
                    ((ShipCount > 3) and (GroupStrength > 3)) then
                  begin
                    Group.BuildLiberationOrders;
                    Result := True;
                    Exit;
                  end;
                end;
              end;
            end;
        end;
        Group.Disband;
        Result := False;
        Exit;
      end;
    end;
  else Result := True;
  end;
end;
{ @end $5FB978 }

{ @routine $5FBC74 TStar_RefreshDerivedStats }
procedure TStar.RefreshDerivedStats;
var I, Strength: Integer; Ship: TShip;
begin
  TrafficLevel := Round(RemapClamped(Ships.Count, 3, 13, 0, 100));
  if Ships.Count > 0 then
  begin
    Strength := 0;
    for I := 0 to Ships.Count - 1 do
    begin
      Ship := TShip(Ships[I]);
      Inc(Strength, Ship.GetStrengthScaledPirateStatus);
    end;
    ThreatLevel := Round(RemapClamped(Strength, 0, 500, 0, 100));
  end
  else ThreatLevel := 0;
  UpdateControlFaction;
  RecountShipTypes;
end;
{ @end $5FBC74 }

{ @routine $5FBD2C TStar_UpdateControlFaction }
procedure TStar.UpdateControlFaction;
var
  Planet: TPlanet;
  KlissanPresent, KlissanCaptured, CoalitionPresent, CoalitionCaptured: Boolean;
  I: Integer;
  Ship: TShip;
begin
  if Player = nil then Exit;
  KlissanPresent := False;
  KlissanCaptured := False;
  CoalitionPresent := False;
  CoalitionCaptured := False;
  for I := 0 to Ships.Count - 1 do begin
    Ship := Ships[I];
    with Ship do
      if not InHyperspace then
        if OwnerId = oiKling then KlissanPresent := True
        else if (Ship <> Player) or ((Player.CurrentPlanet = nil) and (Player.DockedTo = nil)) then
          CoalitionPresent := True;
  end;
  if not CoalitionPresent then
    for I := 0 to Planets.Count - 1 do begin
      Planet := Planets[I];
      if Planet.IsCoalitionOwned and (Planet.Warriors.Count > 0) then CoalitionPresent := True;
    end;
  if Battle and CoalitionPresent and not KlissanPresent and (ControlFaction = sfCoalition) and
    Constellation.Visible and (Galaxy.CountPlanetNewsByType(gnKlingLost) < 2) then
    Galaxy.AddPlanetNews(gnKlingLost, FormatText1(PickLocalizedTextVariant('GalaxyNews.Star.Kling.Lost',
      (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name));
  if CoalitionPresent then KlissanCaptureDays := 0;
  if KlissanPresent and CoalitionPresent then begin
    if Constellation.Visible and (Galaxy.CountPlanetNewsByType(gnKlingAttack) < 2) and not Battle and (ControlFaction = sfCoalition) then
      Galaxy.AddPlanetNews(gnKlingAttack, FormatText1(PickLocalizedTextVariant('GalaxyNews.Star.Kling.Attack',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name));
    Battle := True;
  end else begin
    if KlissanPresent and not CoalitionPresent and (ControlFaction = sfCoalition) then begin
      Inc(KlissanCaptureDays);
      Battle := True;
    end;
    if CoalitionPresent and not KlissanPresent then Battle := False;
    if not CoalitionPresent and not KlissanPresent then Battle := False
    else if KlissanPresent and not CoalitionPresent and (ControlFaction = sfKlissan) and Battle then Battle := False
    else if KlissanPresent and (ControlFaction = sfCoalition) and (KlissanCaptureDays >= 3) then begin
      for I := 0 to Planets.Count - 1 do begin
        Planet := Planets[I];
        if Planet.OwnerId in CoalitionOwners then begin
          Planet.OwnerId := oiKling;
          Planet.UpdateOwnerFlags;
          KlissanCaptured := True;
        end;
      end;
      if KlissanCaptured then begin
        Galaxy.AddPlanetNewsWithPlayerBubble(FormatText2(PickLocalizedTextVariant('GalaxyNews.Globals.KlingTakeSystem',
          (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Sector>', Constellation.GetName));
        ControlFaction := sfKlissan;
        Battle := False;
        if Galaxy.WarDeltaWin <= 0 then Dec(Galaxy.WarDeltaWin)
        else if Galaxy.WarDeltaWin = 1 then Galaxy.WarDeltaWin := 0
        else Galaxy.WarDeltaWin := Galaxy.WarDeltaWin div 2;
      end;
    end else if CoalitionPresent and not KlissanPresent and (ControlFaction = sfKlissan) then begin
      for I := 0 to Planets.Count - 1 do begin
        Planet := Planets[I];
        if Planet.OwnerId = oiKling then begin
          Planet.OwnerId := RaceToOwner(Planet.RaceId);
          Planet.UpdateOwnerFlags;
          Planet.InventionLevels[invTechLevel] := Max(Integer(Planet.InventionLevels[invTechLevel]), Galaxy.TechLevel - 2);
          CoalitionCaptured := True;
        end;
      end;
      if CoalitionCaptured then begin
        ControlFaction := sfCoalition;
        Battle := False;
        ProcessSystemLiberationRewards(Player, Self);
        if Galaxy.WarDeltaWin >= 0 then Inc(Galaxy.WarDeltaWin)
        else if Galaxy.WarDeltaWin = -1 then Galaxy.WarDeltaWin := 0
        else Galaxy.WarDeltaWin := Galaxy.WarDeltaWin div 2;
      end;
    end;
  end;
end;
{ @end $5FBD2C }

{ @routine $5FC2DC TStar_RefreshMapDiameterAndStats }
procedure TStar.RefreshMapDiameterAndStats;
begin
  MapDiameter := ComputeMapDiameter;
  RefreshDerivedStats;
end;
{ @end $5FC2DC }

{ @routine $5FC2F4 TStar_ComputeMapDiameter }
function TStar.ComputeMapDiameter: Integer;
var Planet: TPlanet;
begin
  if Planets.Count > 0 then
  begin
    Planet := TPlanet(Planets[Planets.Count - 1]);
    Result := Round(Planet.Orbit.Radius + Planet.Radius + 800) * 2;
  end
  else Result := (SystemRadius + 800) * 2;
end;
{ @end $5FC2F4 }

{ @routine $5FC338 TStar_CountPlanetsByOwner }
function TStar.CountPlanetsByOwner(Owner: TOwnerId): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to Planets.Count - 1 do
    if Owner = TPlanet(Planets[I]).OwnerId then Inc(Result);
end;
{ @end $5FC338 }

{ @routine $5FC378 TStar_CountDistinctInhabitedPlanetOwners }
function TStar.CountDistinctInhabitedPlanetOwners: Integer;
var Owner: TOwnerId;
begin
  Result := 0;
  for Owner := oiMaloc to oiKling do
    if CountPlanetsByOwner(Owner) > 0 then Inc(Result);
end;
{ @end $5FC378 }

{ @routine $5FC39C TStar_FindFirstInhabitedPlanet }
function TStar.FindFirstInhabitedPlanet: TObject;
var I: Integer;
begin
  Result := nil;
  for I := 0 to Planets.Count - 1 do begin
    Result := Planets[I];
    if (Result as TPlanet).OwnerId <> oiNone then Break;
  end;
end;
{ @end $5FC39C }

{ @routine $5FC3E0 TStar_RecountShipTypes }
procedure TStar.RecountShipTypes;
var Kind: TShipType; I: Integer; Ship: TShip;
begin
  for Kind := t_Kling to t_ScientificBase do ShipTypeCounts[Kind] := 0;
  for I := 0 to Ships.Count - 1 do begin
    Ship := Ships[I];
    Inc(ShipTypeCounts[Ship.ShipType]);
  end;
end;
{ @end $5FC3E0 }

{ @routine $5FC420 TStar_CountShipsByTypeMask }
function TStar.CountShipsByTypeMask(Types: TShipTypeMask): Integer;
var I: TShipType;
begin
  Result := 0;
  for I := t_Kling to t_ScientificBase do
    if I in Types then Inc(Result, ShipTypeCounts[I]);
end;
{ @end $5FC420 }

{ @routine $5FC450 TStar_CountRatedRangersByCareerMask }
function TStar.CountRatedRangersByCareerMask(CareerMask: TRangerCareerSet): Byte;
var Index: Integer; Ship: TObject; Ranger: TRanger;
begin
  Result := 0;
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TObject(Ships[Index]);
    if Ship is TRanger then
    begin
      Ranger := Ship as TRanger;
      if Ranger.GetDominantCareer in CareerMask then Inc(Result);
    end;
  end;
end;
{ @end $5FC450 }

{ @routine $5FC4C0 TStar_GetRangerNamesByCareerMask }
function TStar.GetRangerNamesByCareerMask(CareerMask: TRangerCareerSet): WideString;
var Index: Integer; Ship: TObject; Ranger: TRanger;
begin
  Result := '';
  for Index := 0 to Ships.Count - 1 do
  begin
    Ship := TObject(Ships[Index]);
    if Ship is TRanger then
    begin
      Ranger := Ship as TRanger;
      if Ranger.GetDominantCareer in CareerMask then
      begin
        if Result <> '' then Result := Result + ',' + ' ' + Ranger.Name
        else Result := Ranger.Name;
      end;
    end;
  end;
end;
{ @end $5FC4C0 }

{ @routine $5FC588 TStar_GetRawInfoText }
function TStar.GetRawInfoText: WideString;
var I: TShipType;
begin
  Result := Name;
  for I := t_Kling to t_ScientificBase do
    if ShipTypeCounts[I] > 0 then
      case I of
        t_Kling: Result := Result + #13#10 + 'Клисаны: ' + IntToStr(ShipTypeCounts[I]);
        t_Ranger: Result := Result + #13#10 + 'Рейнджеры: ' + IntToStr(ShipTypeCounts[I]);
        t_Transport: Result := Result + #13#10 + 'Транспорты: ' + IntToStr(ShipTypeCounts[I]);
        t_Pirate: Result := Result + #13#10 + 'Пираты: ' + IntToStr(ShipTypeCounts[I]);
        t_Warrior: Result := Result + #13#10 + 'Военные: ' + IntToStr(ShipTypeCounts[I]);
        t_RangerCenter: Result := Result + #13#10 + 'Центр рейнджеров: ' + IntToStr(ShipTypeCounts[I]);
        t_PirateBase: Result := Result + #13#10 + 'Пиратская база: ' + IntToStr(ShipTypeCounts[I]);
        t_MilitaryBase: Result := Result + #13#10 + 'Военная база: ' + IntToStr(ShipTypeCounts[I]);
        t_ScientificBase: Result := Result + #13#10 + 'Научная база: ' + IntToStr(ShipTypeCounts[I]);
      end;
end;
{ @end $5FC588 }

{ @routine $5FC9F0 TStar_IsConstellationVisible }
function TStar.IsConstellationVisible: Boolean;
begin
  Result := Constellation.Visible;
end;
{ @end $5FC9F0 }

{ @routine $5FC9FC TStar_SumBestRangerRelativeStrength }
function TStar.SumBestRangerRelativeStrength(Types: TShipTypeMask): Single;
var I: Integer; Ship: TShip;
begin
  Result := 0;
  for I := 0 to Ships.Count - 1 do begin
    Ship := Ships[I];
    if (Ship <> KlingMotherShip) and (Ship.ShipType in Types) then
      Result := Result + Ship.StrengthInBestRanger;
  end;
end;
{ @end $5FC9FC }

{ @routine $5FCA5C TStar_RebuildStarDistances }
procedure TStar.RebuildStarDistances;
var Count, I, J, Distance: Integer; Star: TStar;
begin
  Count := Galaxy.Stars.Count;
  StarDistances := nil;
  SetLength(StarDistances, Count);
  for I := 0 to Count - 1 do begin
    Star := TStar(Galaxy.Stars[I]);
    StarDistances[I].Star := Star;
    StarDistances[I].Distance := Round(PointDistance(Position, Star.Position));
  end;
  for I := 0 to Count - 2 do
    for J := I to Count - 1 do
      if StarDistances[J].Distance < StarDistances[I].Distance then begin
        Distance := StarDistances[J].Distance;
        StarDistances[J].Distance := StarDistances[I].Distance;
        StarDistances[I].Distance := Distance;
        Star := StarDistances[J].Star as TStar;
        StarDistances[J].Star := StarDistances[I].Star;
        StarDistances[I].Star := Star;
      end;
end;
{ @end $5FCA5C }

{ @routine $5FCB68 TStar_HasHostilePresenceForScriptBinding }
function TStar.HasHostilePresenceForScriptBinding: Boolean;
var I: Integer;
begin
  for I := 0 to Ships.Count - 1 do
    if TObject(Ships[I]) is TKling then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;
{ @end $5FCB68 }

{ @routine $5FCBA4 TStar_FindNearestStarByFaction }
function TStar.FindNearestStarByFaction(Faction: TStarControlFaction; InBattle: Boolean): TStar;
var I: Integer; Star: TStar;
begin
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    Star := StarDistances[I].Star as TStar;
    if (Star.ControlFaction = Faction) and (Star.Battle = InBattle) then
    begin
      Result := Star;
      Exit;
    end;
  end;
  Result := nil;
end;
{ @end $5FCBA4 }

{ @routine $5FCBF0 TStar_GetBoundaryPointTowardStar }
function TStar.GetBoundaryPointTowardStar(Star: TStar): TPointF;
var Angle, Radius: Double;
begin
  Angle := HeadingDegreesToRadians(PointBearingDegrees(Position, Star.Position));
  Radius := ComputeMapDiameter * 0.4;
  Result.X := Trunc(Sin(Angle) * Radius);
  Result.Y := Trunc(-Cos(Angle) * Radius);
end;
{ @end $5FCBF0 }

{ @routine $5FCC8C TStar_HasLiberationGroupOrder }
function TStar.HasLiberationGroupOrder: Boolean;
var I, J: Integer; Group: TGroup; Order: TGroupRouteOrder;
begin
  for I := 0 to Galaxy.LiberationGroups.Count - 1 do begin
    Group := Galaxy.LiberationGroups[I];
    for J := 0 to Length(Group.Route) - 1 do begin
      Order := Group.Route[J];
      if (Order.Target is TStar) and (Order.Target = Self) then begin Result := True; Exit; end;
    end;
  end;
  Result := False;
end;
{ @end $5FCC8C }

{ @routine $5FCD28 TStar_TryGenerateSystemNews }
procedure TStar.TryGenerateSystemNews;
var Names: WideString;
begin
  if (not Constellation.Visible or (Galaxy.PlanetNews.Count < 9)) and
    (ControlFaction <> sfKlissan) and not Battle then
  begin
    SystemNewsChance := Round(RemapClampedAlternate(Galaxy.PlanetNews.Count, 0, 9, 95, 5));
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2111) < SystemNewsChance) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyTransports) = 0)) and (ShipTypeCounts[t_Transport] > 9) then
    begin
      if Constellation.Visible then
      begin
      Galaxy.AddPlanetNews(gnManyTransports, FormatText1(PickLocalizedTextVariant('GalaxyNews.Star.Transport.Many',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name));
      end;
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2211) < SystemNewsChance) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyTransports) = 0)) and (ShipTypeCounts[t_Transport] > 9) then
    begin
      if Constellation.Visible then
      begin
      Galaxy.AddPlanetNews(gnManyTransports, FormatText1(PickLocalizedTextVariant('GalaxyNews.Star.Transport.Many1',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name));
      end;
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2311) < SystemNewsChance) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyPirates) < 1)) and (DaysSincePlayerVisit > 30) and
      (ShipTypeCounts[t_Kling] = 0) and (ShipTypeCounts[t_Pirate] > 4) then
    begin
      if Constellation.Visible then
      begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[t_Pirate]);
      Galaxy.AddPlanetNews(gnManyPirates, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Pirates.Many',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<AttackCount>', Names));
      end;
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2411) < SystemNewsChance) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnSomePirates) < 1)) and (DaysSincePlayerVisit > 30) and
      (ShipTypeCounts[t_Kling] = 0) and (ShipTypeCounts[t_Pirate] > 2) then
    begin
      if Constellation.Visible then
      begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[t_Pirate]);
      Galaxy.AddPlanetNews(gnSomePirates, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Pirates.Some',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<AttackCount>', Names));
      end;
      Exit;
    end;
    if (SeededRandomIntRange(50, 100, Galaxy.CurrentTurn * GenerationSeed * 2511) < SystemNewsChance) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnNoPirates) < 1)) and (DaysSincePlayerVisit > 30) and
      (ShipTypeCounts[t_Kling] = 0) and (ShipTypeCounts[t_Pirate] = 0) then
    begin
      if Constellation.Visible then
      begin
      Names := IntToStr(NextRandomIntRange(1, 2, RandomState) + ShipTypeCounts[t_Pirate]);
      Galaxy.AddPlanetNews(gnNoPirates, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Pirates.None',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<AttackCount>', Names));
      end;
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2611) < 90) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyRangers) = 0)) and (ShipTypeCounts[t_Ranger] >= 4) and
      (CountRatedRangersByCareerMask([rcTrader]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcTrader]);
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnManyRangers, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.ManyTrader',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Names>', Names));
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2711) < 90) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyRangers) = 0)) and (ShipTypeCounts[t_Ranger] >= 4) and
      (CountRatedRangersByCareerMask([rcPirate]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcPirate]);
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnManyRangers, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.ManyPirate',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Names>', Names));
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 2811) < 90) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnManyRangers) = 0)) and (ShipTypeCounts[t_Kling] = 0) and (ShipTypeCounts[t_Ranger] >= 4) and
      (CountRatedRangersByCareerMask([rcWarrior]) > 4) then
    begin
      Names := GetRangerNamesByCareerMask([rcWarrior]);
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnManyRangers, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.ManyWarrior',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Names>', Names));
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3011) < 100) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnBestRanger) = 0)) and (Galaxy.EminentCareerShips[rcTrader] <> nil) and
      (Galaxy.EminentCareerShips[rcTrader] as TRanger).InHyperspace and
      ((Galaxy.EminentCareerShips[rcTrader] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[rcTrader] as TRanger).Name;
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnBestRanger, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.BestTrader',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Name>', Names));
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3111) < 100) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnBestRanger) = 0)) and (Galaxy.EminentCareerShips[rcPirate] <> nil) and
      (Galaxy.EminentCareerShips[rcPirate] as TRanger).InHyperspace and
      ((Galaxy.EminentCareerShips[rcPirate] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[rcPirate] as TRanger).Name;
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnBestRanger, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.BestPirate',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Name>', Names));
      Exit;
    end;
    if (SeededRandomIntRange(0, 100, Galaxy.CurrentTurn * GenerationSeed * 3211) < 100) and
      (not Constellation.Visible or (Galaxy.CountPlanetNewsByType(gnBestRanger) = 0)) and (Galaxy.EminentCareerShips[rcWarrior] <> nil) and
      (Galaxy.EminentCareerShips[rcWarrior] as TRanger).InHyperspace and
      ((Galaxy.EminentCareerShips[rcWarrior] as TRanger).CurrentStar = Self) then
    begin
      Names := (Galaxy.EminentCareerShips[rcWarrior] as TRanger).Name;
      if Constellation.Visible then
      Galaxy.AddPlanetNews(gnBestRanger, FormatText2(PickLocalizedTextVariant('GalaxyNews.Star.Rangers.BestWarrior',
        (Galaxy.CurrentTurn div 10) * GenerationSeed), HighlightColorTag, '<Star>', Name, '<Name>', Names));
    end;
  end;
end;
{ @end $5FCD28 }

end.

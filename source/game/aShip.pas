unit aShip;
// Unit bracket (inferred): CODE 0x005AA9D0..0x005BEAFF; inclusive evidence, not full bounds.
// Layout from Create $5AAAD0, SaveToBuffer $5AAFB0 and order/cleanup consumers.
interface
uses aConst, aAsteroid, EC_Struct, Classes, aItem, aGalaxy, aPlanet, aMyFunction, aPath, EC_Buf, SE_Space, aEFilm;
const
  UnlimitedPathNodes = 999999; // MaximumNodes for full-length movement paths.
  AsteroidTargetRangeSquared = 1000000; // Asteroid targeting range 1000, squared.
  // Travel orders keep remaining days in the low word of OrderStateData.
  TravelDaysMask = $FFFF;
  // Black-hole transit uses high word 0 toward Star2, 1 toward Star1.
  BlackHoleDirectionShift = 16;
  BlackHoleForwardTransitState = 2;
  BlackHoleReverseTransitState = $10002;
  BlackHoleExitFlightState = -65536; // Transit finished; flying away from the exit.
type
  TShipOrder = (soNone = 0, soMove = 1, soLanding = 2, soJump = 3, soEnterBlackHole = 4, soTakeoff = 5,
    soFollowShip = 6); // @size $01
  // Kept in the low byte of OrderStateData.
  TFollowMode = (fmNear = 0, fmMinWeaponRange = 1, fmMaxWeaponRange = 2); // @size $01
  // Picks the broken-in-battle or broken-in-use message.
  TItemDegradationKind = (idkBattle = 0, idkUse = 1); // @size $01
  TWeaponCount = 0..5; // @size $01 Five weapon slots; native count promotion masks with $7F.
  TCargoGoodsEntry = packed record // @size $08
    Count: Integer; // @offset $00
    TotalCost: Integer; // @offset $04 Purchase cost basis.
  end;
  TShip = class(TObjectEx) // @size $1B0 @methodorder source
  public
    Id: Cardinal; // @offset $04
    Name: WideString; // @offset $08
    ShipType: TShipType; // @offset $0C
    OwnerId: TOwnerId; // @offset $0D
    Position: TPointF; // @offset $10
    CurrentPlanet: TPlanet; // @offset $18
    DockedTo: TShip; // @offset $1C
    CurrentStar: TStar; // @offset $20
    TransitOriginStar: TStar; // @offset $24 Serialized separately from CurrentStar.
    HomePlanet: TPlanet; // @offset $28
    CargoGoods: array[TGoodsIndex] of TCargoGoodsEntry; // @offset $2C
    Money: Integer; // @offset $6C
    Wealth: Integer; // @offset $70
    WealthInBestRanger: Single; // @offset $74
    Strength: Single; // @offset $78
    StrengthInBestRanger: Single; // @offset $7C
    StrengthInAverageRanger: Single; // @offset $80
    Speed: Integer; // @offset $84
    JumpRange: Byte; // @offset $88
    DefenseDamageFactor: Double; // @offset $90 One means no damage reduction.
    HasInactiveDirectEquipment: Boolean; // @offset $98
    CargoFreeSpace: Integer; // @offset $9C
    Seed: Cardinal; // @offset $A0
    RandomState: Cardinal; // @offset $A4
    CreationTurn: Integer; // @offset $A8
    LastProcessedTurn: Integer; // @offset $AC
    Hull: THull; // @offset $B0
    FuelTanks: TFuelTanks; // @offset $B4
    Engine: TEngine; // @offset $B8
    Radar: TRadar; // @offset $BC
    Scanner: TScaner; // @offset $C0
    RepairRobot: TRepairRobot; // @offset $C4
    CargoHook: TCargoHook; // @offset $C8
    DefGenerator: TDefGenerator; // @offset $CC
    Weapons: array[0..4] of TWeapon; // @offset $D0
    WeaponCount: TWeaponCount; // @offset $E4
    UsableWeaponCount: TWeaponCount; // @offset $E5
    BaseSkills: array[TSkill] of TSkillLevel; // @offset $E6
    NodeReserve: Integer; // @offset $EC Stored as a Word in saves.
    TotalExperience: Integer; // @offset $F0 Stored as a Word in saves.
    FreeExperience: Integer; // @offset $F4 Stored as a Word in saves.
    DaysSincePlayerSeen: Integer; // @offset $F8
    InFear: Boolean; // @offset $FC
    Inventory: TObjectList; // @offset $100 Owns TItem entries.
    Artefacts: TObjectList; // @offset $104 Owns TItem entries.
    ScriptShip: TObject; // @offset $108
    LiberationGroup: TObject; // @offset $10C
    LiberationGroupRouteIndex: Integer; // @offset $110
    PickupTargets: TList; // @offset $114 Borrowed TItem references; list may be nil.
    PlanetQueue: TList; // @offset $118 Borrowed TPlanet references; ClearPlanetQueue frees the list.
    AwardIds: TList; // @offset $11C Owns separately allocated one-byte award IDs.
    RangerRelations: TList; // @offset $120 Byte scores stored directly in list slots.
    EnemyShip: TShip; // @offset $124
    TruceShip: TShip; // @offset $128
    PartnerShip: TShip; // @offset $12C
    PartnershipDaysRemaining: Integer; // @offset $130
    MovementSpeed: Double; // @offset $138 Speed * 0.005, confirmed at $5B1524.
    MovementSpeedPerTurn: Double; // @offset $140 MovementSpeed * 200 * 0.1.
    MovementTurnRate: Double; // @offset $148 Create sets 1.2.
    MovementTurnRatePerTurn: Double; // @offset $150 Create computes MovementTurnRate * 200 * 0.1.
    MovementDirection: Double; // @offset $158 Serialized as Single.
    Order: TShipOrder; // @offset $160
    OrderStateData: Integer; // @offset $164
    OrderTarget: TObject; // @offset $168 Object class depends on Order.
    OrderDestination: TPointF; // @offset $16C
    OrderAbsolute: Boolean; // @offset $174
    MovementPath: TSPath; // @offset $178 Owned.
    Graphic: TObjectSE; // @offset $17C Owned scene object.
    InHyperspace: Boolean; // @offset $180
    CollisionRadius: Single; // @offset $184
    DestroyKind: Byte; // @offset $188
    EncodedMoney: Cardinal; // @offset $18C Money xor MoneyEncodingKey ($C0A57EB5).
    DatabaseLogText: WideString; // @offset $190 Pending ship log, appended by $5B3A50 and flushed to #ship.dbf by $5E767C.
    FollowPosition: TPointF; // @offset $198 Temporary follow offset, then collision-adjusted position, in TStar.NextDay.
    FilmAlpha: Single; // @offset $1A4 Landing and jump opacity, permitted outside 0..255.
    FilmAlphaStep: Single; // @offset $1A8 Per movement-node opacity change.
    FilmObject: TEFilmObj; // @offset $1AC Borrowed entry in PrimaryFilm, assigned by PrepareTurnMovement.

    procedure SaveToBuffer(Buffer: TBufEC); virtual; // @addr $5AAFB0 @slot $00
    procedure LoadFromBuffer(Buffer: TBufEC); virtual; // @addr $5AB494 @slot $04
    procedure ResolveLoadedReferences; virtual; // @addr $5ABABC @slot $08
    procedure NextDay; virtual; // @addr $5ABDA4 @slot $0C
    function GetName: WideString; virtual; abstract; // @slot $10
    function GetFullName(const Separator: WideString): WideString; virtual; abstract; // @slot $14
    function GetTypeNameKey: WideString; virtual; abstract; // @slot $18
    function GetGreetingShipCategory: TGreetingShipCategory; virtual; abstract; // @slot $1C
    function GetHomeStar: TStar; virtual; abstract; // @slot $20
    function GetDominantCareer: TRangerCareer; virtual; abstract; // @slot $24
    function GetStrengthScaledPirateStatus: TPercent; virtual; abstract; // @slot $28
    function GetDesiredCargoFreeSpace: Integer; virtual; abstract; // @slot $2C
    function GetEstimatedMemoryUsage: Integer; virtual; // @addr $5ACDF4 @slot $30
    procedure RefuelAtLocation; virtual; abstract; // @slot $34
    procedure RepairBrokenEquipmentAtLocation; virtual; abstract; // @slot $38
    procedure BuildReachablePlanetQueue; virtual; abstract; // @slot $3C
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; virtual; abstract; // @slot $40
    procedure SelectEnemyShipInStar; virtual; abstract; // @slot $44
    procedure EngageEnemyShip; virtual; abstract; // @slot $48
    function RelationToRanger(Ranger: TObject): Byte; virtual; abstract; // @slot $4C
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); virtual; abstract; // @slot $50
    procedure ReactToAttack(Attacker: TShip); virtual; abstract; // @slot $54
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; virtual; abstract; // @slot $58
    function RecomputeFearState: Boolean; virtual; abstract; // @slot $5C
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; virtual; abstract; // @slot $60
    function TrustsAttackRequester(Ship: TShip): Boolean; virtual; abstract; // @slot $64
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; virtual; abstract; // @slot $68
    procedure BuyInitialEquipment; virtual; abstract; // @slot $6C
    function TrainSkill(Skill: TSkill): Boolean; // @addr $5BE6D8
    function GetCargoGoodsWeight: Integer; // @addr $5B1E4C
    procedure LiquidateInventoryItem(Item: TItem); // @addr $5B39A0
    procedure DepositCarriedNodes; // @addr $5BE660
    procedure GenerateExtraWeapon; // @addr $5B402C
    procedure BuyHullUpgrade(SizeClass: TStandardCount); // @addr $5B4124
    procedure BuyFuelTanksUpgrade(SizeClass: TStandardCount); // @addr $5B43C4
    procedure BuyEngineUpgrade(SizeClass: TStandardCount); // @addr $5B46BC
    procedure BuyRadarUpgrade(SizeClass: TStandardCount); // @addr $5B49F8
    procedure BuyScannerUpgrade(SizeClass: TStandardCount); // @addr $5B4CC4
    procedure BuyRepairRobotUpgrade(SizeClass: TStandardCount); // @addr $5B4F90
    procedure BuyDefGeneratorUpgrade(SizeClass: TStandardCount); // @addr $5B5524
    procedure BuyCargoHookUpgrade(SizeClass: TStandardCount); // @addr $5B5250
    procedure BuyWeaponUpgrade(SizeClass: TStandardCount); // @addr $5B57E4
    procedure UpgradeEquipmentAtLocation; virtual; abstract; // @slot $70
    procedure ProcessCombatDialogue; virtual; abstract; // @slot $74
    function CalculatePartnershipMonths(Amount: Integer; Relation: Byte): Integer; // @addr $5BDBD0
    function GetRelationLevelTextToShip(Ship: TShip): WideString; // @addr $5AFE64
    procedure TruceWithShip(Ship: TShip); // @addr $5B00EC
    function LookupVisibleTalkText(const Path: WideString): WideString; // @addr $5ACF98
    function GetRelationLevelToShip(Ship: TShip): TRelationLevel; // @addr $5AFE24
    function ShowPlayerDialogue(Kind: Byte; const Text: WideString; Amount: Integer): Byte; // @addr $5BC510
    procedure ReactToExtortionDemand(Ranger: TObject); virtual; abstract; // @slot $78
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; virtual; abstract; // @slot $7C
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; virtual; abstract; // @slot $80
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; virtual; abstract; // @slot $84
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; virtual; abstract; // @slot $88
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; virtual; abstract; // @slot $8C
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; virtual; abstract; // @slot $90
    function CanTrainSkill(Skill: TSkill): Boolean; // @addr $5BE738
    function HasLooseNonScriptItemsOrGoods: Boolean; // @addr $5B2344
    function DropItemIntoStar(Item: TItem): Boolean; // @addr $5B2E8C
    procedure TryRelocateUnseenShip; // @addr $5AD5BC
    function DropCarriedItemAsMovingLoot(Item: TItem): Boolean; // @addr $5B2DF8
    function DropCarriedArtefactAsMovingLoot(Item: TItem): Boolean; // @addr $5B2E48
    procedure DropUnequippedItemsAndGoods; // @addr $5B23C4
    function FindCarriedItemById(Id: Integer): TItem; // @addr $5AD558 Searches inventory and artefacts only.
    function GetLocalizedTypeName: WideString; // @addr $5AC230
    function IsInPrison: Boolean; // @addr $5B04D4
    function GetShipPortraitImagePath: WideString; // @addr $5AD268
    function FindScriptFollowTarget: TShip; // @addr $5BE5B8
    function HasArtefact(Kind: TItemType): Boolean; // @addr $5BBDA8
    function GetEffectiveMass: Integer; // @addr $5B1094
    function HasActiveArtefact(Kind: TItemType): Boolean; // @addr $5BBDEC
    function GetSpaceInfoText: WideString; // @addr $5AC2D4
    function GetLegacyShipTypeLabel: WideString; // @addr $5ACC68
    procedure GetOrderDebugText(out OrderText, TargetText, ParameterText: WideString); // @addr $5B6C00
    procedure TransferToStar(Star: TStar); // @addr $5AD4F4 Moves Self and docked ships; leaves InHyperspace unchanged.
    procedure RefreshAssignedItemSlots; // @addr $5BB9D0
    function GetSlotCountForItemType(ItemType: TItemType): Integer; // @addr $5BB8A8 Five weapon slots and one per other equipment type.
    function FindEquippedItemInSlot(ItemType: TItemType; SlotIndex: Integer): TEquipment; // @addr $5BBA24
    function CountUnequippedItemsInSlot(SlotIndex: Integer): Integer; // @addr $5BBB00
    function FindFreeUnequippedSlot: Integer; // @addr $5BBB4C
    procedure ReassignActiveItemSlots(ItemType: TItemType); // @addr $5BB8C4
    procedure RefreshInactiveItemSlotAssignments; // @addr $5BBAA4
    procedure GainExperience(Amount: Integer); // @addr $5BE620
    procedure RemoveExperience(Amount: Integer); // @addr $5BE630
    function ChanceToWin(OtherShip: TShip): Double; // @addr $5AF84C Combat strength ratio; the invalid-hull warning does not abort.
    function IsOutsideStarSpace: Boolean; // @addr $5AD864
    function GetHullIntegrityPercent: Byte; // @addr $5B10E0
    function GetLocationGoodsEntry(Good: TGoodsIndex): PPlanetGoodsEntry; // @addr $5B051C
    procedure SellGoodsToLocation(Good: TGoodsIndex; Count: Integer); // @addr $5B0620
    procedure BuyGoodsFromLocation(Good: TGoodsIndex; Count: Integer); // @addr $5B0724
    procedure RequestAlliesAttackShip(Target: TShip); // @addr $5B024C
    procedure DropGoodsIntoSpace(Good: TGoodsIndex; Count: Integer); // @addr $5B3110
    function JettisonCargoGoodsTowardTargetValue(TargetValue: Integer): Boolean; // @addr $5B3164
    procedure DropAllCargoGoods; // @addr $5B3274
    procedure QueueMovingItemDrop(Item: TItem; UseFlag: Byte); // @addr $5B329C
    procedure EquipItemDirect(Item: TEquipment); // @addr $5B0CEC Installs into the direct slot; caller handles replacement and capacity.
    function CreateAndEquipHull(Equipped: Boolean; Capacity: Word; Level: Byte; Owner: TOwnerId): THull; // @addr $5B5C78
    function CreateRandomEquipment(Types: TItemTypeMask; Equipped: Boolean; SizeClass: TStandardCount; StandardLevel: ShortInt; Owner: TOwnerId; Seed: Cardinal): TEquipment; // @addr $5B5F78 @ida "TEquipment *__userpurge $name@<eax>(TShip *Self@<eax>, TItemTypeMask *Types@<edx>, bool Equipped@<cl>, unsigned int Seed@<^0>, TOwnerId Owner@<^4>, __int8 StandardLevel@<^8>, TStandardCount SizeClass@<^12>);"
    function CreateAndEquipFuelTanks(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TFuelTanks; // @addr $5B5CD4
    function CreateAndEquipEngine(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TEngine; // @addr $5B5D28
    function CreateAndEquipRadar(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TRadar; // @addr $5B5D7C
    function CreateAndEquipScanner(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TScaner; // @addr $5B5DD0
    function CreateAndEquipRepairRobot(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TRepairRobot; // @addr $5B5E24
    function CreateAndEquipCargoHook(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TCargoHook; // @addr $5B5E78
    function CreateAndEquipDefGenerator(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TDefGenerator; // @addr $5B5ECC
    function CreateAndEquipWeapon(Kind: TItemType; Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TWeapon; // @addr $5B5F20
    function GetAverageCargoCost(Good: TGoodsIndex): Double; // @addr $5B05A8
    function GetFullRefuelCost: Integer; // @addr $5B113C
    function FindCoalitionPlanetForStation: TPlanet; // @addr $5AD9AC Returns the last planet if none is coalition-owned.
    function FindNearestStarByControlFaction(Faction: TStarControlFaction): TStar; // @addr $5AE508
    function FindNextStarTowardDestination(Destination: TStar; RequireFuelMargin: Boolean): TStar; // @addr $5AE1E8 Margin applies only to the final jump.
    function GetFullFuelBaseJumpRange: Integer; // @addr $5AE19C
    function TryMirrorPartnerTravelOrders: Boolean; // @addr $5ADAF0
    function ScanForCollectableItems: Boolean; // @addr $5B6228
    procedure OrderRandomFreeFlightMove; // @addr $5ADEC0
    procedure SetJointAttackTarget(Ally, Target: TShip); // @addr $5AFB68
    procedure LeaveLiberationGroup; // @addr $5B0AF0
    procedure InitializeScriptStateOrders; // @addr $5BDFA8
    procedure SetStoredRangerRelationLevel(Ranger: TShip; Level: TRelationLevel); // @addr $5AFCC4
    function IsOnPlanet: Boolean; // @addr $5AD888
    function IsDockedToShip: Boolean; // @addr $5AD890
    procedure RebuildEquipmentCache; // @addr $5B1B80
    procedure UnequipSlot(ItemType: TItemType; WeaponIndex: Integer); // @addr $5B0E2C WeaponIndex is 1-based.
    function CountMatchingInventoryEquipment(ItemType: TItemType): Integer; // @addr $5B214C
    function SelectBestUnequippedWeapon(PreferHullDamage: Boolean): TWeapon; // @addr $5B21D0
    function SelectLeastValuableInventoryItem: TEquipment; // @addr $5B3414
    function SelectMostValuableArtefact: TArtefact; // @addr $5B35A4 Native chooses the greatest cost/weight ratio.
    function SelectCheapestCargoGood: Byte; // @addr $5B3644
    procedure DropExcessCargo; // @addr $5B28E8
    procedure RefreshEquipmentSlots; // @addr $5B244C
    function HasScriptBindings: Boolean; // @addr $5AD238
    function GetMaxWeaponRange: Integer; // @addr $5AF794
    function RepairHullAtLocation: Boolean; // @addr $5B3B88
    function FindEquippedArtefact(Kind: TItemType; var Item: TArtefact; RequireWorking: Boolean): Boolean; // @addr $5BBE3C
    function UseArtefact(Item: TArtefact): Boolean; // @addr $5BBB68
    procedure LiquidateArtefact(Item: TArtefact); // @addr $5B3A50
    procedure OptimizeInventory; // @addr $5B36A8
    procedure ClearOrderToShipOutsideStar; // @addr $5AD8A4
    procedure RepairHullWithRobot; // @addr $5B141C
    procedure ApplyNanoArtefactRepair; // @addr $5BBEB4
    function ApplyWeaponHit(Source: TShip; Weapon: TWeapon; HitRange: Single; out DamageColor: Cardinal): Integer; // @addr $5AE85C
    function ApplyAsteroidImpactDamage(Asteroid: TAsteroid; out DamageColor: Cardinal): Integer; // @addr $5AF5C4 Asteroid is unused; damage depends on hull weight.
    procedure DropRandomCheapItemsOnDestruction(Count: Integer); // @addr $5B2C08
    procedure DropRandomValuableItemsOnDestruction(Count: Integer); // @addr $5B2DBC
    procedure DropAllArtefactsOnDestruction; // @addr $5B30E8
    procedure DegradeEquipmentFromDamage(Amount: Double); // @addr $5B3BD8
    procedure DegradeActiveArtefacts(Amount: Double); // @addr $5B3D94
    function ApplyItemDegradation(Item: TEquipment; Kind: TItemDegradationKind; Amount: Double): Boolean; // @addr $5B3DF0
    procedure ScriptNextDay; // @addr $5BE57C
    procedure ApplyScriptStateOrders; // @addr $5BDFD0
    procedure UpdateScriptStateCompletionAndPickups; // @addr $5BE424
    function GetRadarRange: Integer; // @addr $5B1364
    function CountCargoGoodsTypes: Byte; // @addr $5ACEBC
    function CanResolveObjectWithScanner(Target: TObject): Boolean; // @addr $5B13AC
    procedure SetMoney(Value: Integer); // @addr $5ABD4C
    function InNormalSpace: Boolean; // @addr $5AD840
    procedure EquipItem(Item: TEquipment); // @addr $5B0F78
    procedure UpdateBestRangerRelativeRatings; // @addr $5ACFD4
    procedure UpdateAverageRangerRelativeStrength; // @addr $5ACFFC
    function CalculateWealth: Integer; // @addr $5AD014 Updates Wealth from money, inventory and eight cargo cost totals.
    function CalculateStrength: Double; // @addr $5AD05C Updates the Single cache and returns the unrounded Double.
    function GetFuelLimitedJumpRange: Byte; // @addr $5B1330
    function GetDefenseDamageFactor: Double; // @addr $5B14A4
    function GetCargoHookRange: Integer; // @addr $5B1488 Always 150, including without a hook.
    function GetBaseCargoHookPower: Integer; // @addr $5B1490 Ignores damage and artefact bonuses.
    function GetCargoFreeSpace: Integer; // @addr $5B1DF8
    function CalculateUsedCargoSpace: Integer; // @addr $5B1D8C
    function CalculateSpeed: Integer; // @addr $5B11F4
    procedure DerivedStateCompatibilityHook; // @addr $5AC22C
    procedure RefreshGraphicSize; // @addr $5B1684 Maps hull weight and ship/race subtype to the scene sprite size.
    procedure RefreshDerivedStats; // @addr $5B1524
    constructor Create; // @addr $5AAAD0
    function GetTurnSeedFraction(TurnOffset: Integer): Single; // @addr $5ACDC0
    function CanRefuel: Boolean; // @addr $5ACF7C
    function GetCarriedItemWeight: Integer; // @addr $5B1E14
    function HasCargoGoods: Boolean; // @addr $5ACE9C
    function GetCarriedNodeCount: Integer; // @addr $5ACED8
    function HasLockedOrFollowOrder: Boolean; // @addr $5ACF14
    function HasHullDamageOrBrokenEquippedItems: Boolean; // @addr $5ACF2C
    function GetWealthScaledAmount(ScaleIndex: TStandardCount): Integer; // @addr $5AD1C0
    function SelectNearestQueuedPlanet: TPlanet; // @addr $5AD8FC
    function NavigateToQueuedPlanet(Absolute: Boolean): TPlanet; // @addr $5AD9F8
    function NavigateToEscapePlanet(Absolute: Boolean): Boolean; // @addr $5ADA5C
    function CanEscapePursuer(Pursuer: TShip): Boolean; // @addr $5ADF68
    function IsTargetStillPursuable(Target: TShip): Boolean; // @addr $5ADF2C
    function HasLandablePlanetInStar(Star: TStar): Boolean; // @addr $5AE154
    function DistanceToNearestShipByTypeMask(ShipTypeMask: TShipTypeMask): Double; // @addr $5AE480
    function EstimateOrderTravelTurns: Integer; // @addr $5AE54C
    function EstimateTravelTurnsToObject(Target: TObject): Integer; // @addr $5AE6B8
    function EstimateTravelTurnsToPlanet(Planet: TPlanet): Integer; // @addr $5AE80C
    function TryCollectBestFloatingItem(MaximumTravelTurns: Integer): Boolean; // @addr $5B62EC
    function TryExtortShip(Ship: TShip): Boolean; // @addr $5AFE94
    function IsOutsideExtortionRange(Ship: TShip): Boolean; // @addr $5BC128
    function CanReplaceCargoForItem(Item: TItem): Boolean; // @addr $5B667C
    function CanPickupItemNow(Item: TItem): Boolean; // @addr $5B680C
    procedure QueuePickupItem(Item: TItem); // @addr $5B6918
    procedure RemoveQueuedPickupItem(Item: TObject); // @addr $5B6974
    function IsPickupQueued(Item: TItem): Boolean; // @addr $5B69EC
    function CountOtherShipsPickingUpItem(Item: TItem): Integer; // @addr $5B6A34
    function CanReachItemBeforeOtherShips(Item: TItem): Boolean; // @addr $5B6AC0
    function GetPickupApproachPosition(ItemPosition: TPointF): TPointF; // @addr $5B6B9C
    function CanHookItem(Item: TItem): Boolean; // @addr $5B68C4
    procedure ImproveMostValuableEquipment; // @addr $5B3F90
    procedure ProcessLiberationGroupRoute; // @addr $5B0854
    function HasWeaponTarget(Target: TObject): Boolean; // @addr $5AF81C
    procedure ClearWeaponTargets(Target: TObject); // @addr $5AF7C8
    procedure OrderEnterBlackHole(Hole: THole; Forward, Absolute: Boolean); // @addr $5B7128
    function RandomInt(BoundA, BoundB: Integer): Integer; // @addr $5AC2C4
    function GetHeaviestWeaponIndex: Integer; // @addr $5AF6F4 One-based; zero when none has positive weight.
    function CountEquippedWeapons: TWeaponCount; // @addr $5AF6A4
    function CountHullDamageWeapons: TWeaponCount; // @addr $5AF72C
    function CountSpecialDamageWeapons: TWeaponCount; // @addr $5AF760
    function GetWinChancePercent(Target: TShip): TPercent; // @addr $5AFAEC
    function IsEnemyPursuingSelf: Boolean; // @addr $5AFC8C
    procedure ConsumeCargoGoods(Good: TGoodsIndex; Count: Integer); // @addr $5B05D8
    function GetJumpDestinationDistance: Integer; // @addr $5B1104
    function GetDefensePercent: TPercent; // @addr $5B150C
    function GetFollowMode: TFollowMode; // @addr $5B1FD8
    function GetMovementPathTurnCount: Integer; // @addr $5B76B4
    function GetEffectiveFollowMode: TFollowMode; // @addr $5B2030
    function GetReservedPickupWeight: Integer; // @addr $5B6644
    function GetRelativeStrengthCategory: TStandardCount; // @addr $5BE774
    function GetHullConditionCategory: TStandardCount; // @addr $5BE8AC
    function GetRangerRatingBand: TStandardCount; // @addr $5BE9A0
    function LookupTalkText(const Path: WideString): WideString; // @addr $5BC178
    procedure NotifyMoneyDemand(OtherShip: TShip; Response: WideString; Amount: Integer); // @addr $5BC560
    procedure NotifyCargoDemand(OtherShip: TShip; Response: WideString); // @addr $5BC800
    procedure NotifyFearCargoDrop(OtherShip: TShip); // @addr $5BCA54
    procedure NotifyTruceOffer(OtherShip: TShip; Response: WideString; Amount: Integer); // @addr $5BCCF8
    procedure NotifyAttackRequest(OtherShip: TShip; Response: WideString; Target: TShip); // @addr $5BCFC0
    procedure NotifyPartnershipOffer(OtherShip: TShip; Response: WideString; Amount: Integer); // @addr $5BD288
    procedure NotifyPartnerBreak(Leader: TShip); // @addr $5BD530
    procedure NotifyPartnerRebellion(Leader: TShip); // @addr $5BD7FC
    procedure ShowMessageToPlayer(Text: WideString); // @addr $5BDACC
    function GetGreetingText: WideString; // @addr $5BDC8C
    destructor Destroy; override; // @addr $5AACEC
    function CalculateJumpTravelDays(Origin, Destination: TStar): Integer; // @addr $5B7078
    function CalculateFollowRadius: Integer; // @addr $5B1E64
    function HasPositiveSpeed: Boolean; // @addr $5AD898
    procedure OrderNone; // @addr $5B6EAC
    procedure ClearMovementPath; // @addr $5BB89C
    procedure ClearPlanetQueue; // @addr $5AD8E0
    procedure ClearPickupTargets; // @addr $5B69D0
    procedure OrderMove(Destination: TPointF; Absolute: Boolean); // @addr $5B6EC8
    function GetJumpDeparturePoint(Destination: TStar): TPointF; // @addr $5B6F1C
    function GetArrivalPosition(DestinationStar: TStar): TPointF; // @addr $5B6FE4
    procedure OrderJump(Star: TStar; Absolute: Boolean); // @addr $5B70B8
    procedure OrderLanding(Location: TObject; Absolute: Boolean); // @addr $5B71B0
    procedure OrderTakeoff; // @addr $5B7218
    procedure OrderFollowShip(Ship: TShip; FollowMode: TFollowMode; Absolute: Boolean); // @addr $5B7670
    procedure BuildFullPathTo(Destination: TPointF); // @addr $5B9B54
    procedure AppendPathToWithTurnPadding(Destination: TPointF; MaximumNodes: Integer); // @addr $5BA618
    procedure AppendPathTo(Destination: TPointF; MaximumNodes: Integer); // @addr $5BA708
    procedure AppendStarAvoidingPathWithTurnPadding(Destination: TPointF; MaximumNodes: Integer); // @addr $5BA79C
    procedure AppendTurningPath(Destination: TPointF; AvoidStar: Boolean; MaximumNodes: Integer); // @addr $5BA878
    procedure AppendStraightPath(Destination: TPointF; MaximumNodes: Integer); // @addr $5BADB8
    procedure AppendHyperspaceTransitionPath(Direction: Single); // @addr $5BB0D4
    procedure AppendStarAvoidingPath(Destination: TPointF; MaximumNodes: Integer); // @addr $5BB270
    procedure AppendCircularDetour(Destination: TPointF; MaximumNodes: Integer; Radius: Double); // @addr $5BB600
    procedure BuildPlanetLandingPath; // @addr $5B9B9C
    procedure RebuildOrderMovementPath; // @addr $5B9ABC
    procedure RebuildFollowMovementPath; // @addr $5B9AE0
    procedure BuildOrderMovementPath(MaximumNodes: Integer); // @addr $5B9C58
    function IsHullDestroyed: Boolean; // @addr $5ACC58
    function ProcessMovementStep(StepIndex: Integer; RecordFilm: Boolean): Boolean; // @addr $5B8B8C Native result remains False.
    procedure PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean); // @addr $5B7718
    procedure CancelCompletedMovementOrder(StepIndex: Integer; RecordFilm: Boolean); // @addr $5B98B8 Native callers pass both unused arguments.
    function RequestPlayerDialogue: Boolean; // @addr $5BC450
    function IsTravelCompletionPathReady: Boolean; // @addr $5B98F8
  end;
function CompareShipGroupsStrength(Ships, Opponents: TList): Single; // @addr $5B0B40
function CreateShipByType(Kind: TShipType): TShip; // @addr $5B0BF0

var
  PlayerHomeRanger: TShip = nil; // @addr $6188D4 First other ranger generated at the player home planet ($59800C); cleared by ship destruction.

implementation

// @unit-initialization $5BEAF8
// @unit-finalization $5BEAC8

uses Windows, aCalc, aRuinsRC, aRuinsWB, aRuinsSB, aRuinsPB, aKling, aTransport, aWarrior, aPirate, SE_Ruins, Globals, GR_Main, Math, aGroup, SysUtils, Dialogs, SE_Process, SE_Ship2, aRuins, aScript, aTranclucator, aNormalShip, aRanger, aPlayer, GlobalsV, aConst, EC_Mem, SE_Weapon, aEFilmEnd;

const MoneyEncodingKey = $C0A57EB5;

{ @routine $5AAAD0 TShip_Create }
constructor TShip.Create;
var Skill: TSkill; Kind: TGoodsIndex;
begin
  inherited Create;
  Money := 0;
  EncodedMoney := Money xor MoneyEncodingKey;
  Id := Galaxy.NextShipId;
  Inc(Galaxy.NextShipId);
  Seed := NextRandomIntRange(100000, MaxInt, Galaxy.RandomState);
  if Integer(Seed) < 0 then RaiseWideMessage('TShip.Create; - FRnd<0');
  RandomState := Seed;
  for Kind := t_Food to t_Narcotics do
  begin
    CargoGoods[Kind].Count := 0;
    CargoGoods[Kind].TotalCost := 0;
  end;
  CreationTurn := Galaxy.CurrentTurn;
  WeaponCount := 0;
  for Skill := skAccuracy to skLeadership do BaseSkills[Skill] := 0;
  MovementPath := TSPath.Create;
  OrderNone;
  Inventory := TObjectList.Create;
  Artefacts := TObjectList.Create;
  MovementTurnRate := 1.2;
  MovementTurnRatePerTurn := MovementTurnRate * 200 * 0.1;
  EnemyShip := nil;
  TruceShip := nil;
  PartnerShip := nil;
  // Native leak: the newly allocated list is immediately discarded.
  PlanetQueue := TList.Create;
  PlanetQueue := nil;
  RangerRelations := TList.Create;
  AwardIds := nil;
  NodeReserve := 0;
  TotalExperience := 0;
  FreeExperience := 0;
  DaysSincePlayerSeen := 100;
  LastProcessedTurn := -1;
  LiberationGroup := nil;
  LiberationGroupRouteIndex := 0;
end;
{ @end $5AAAD0 }

{ @routine $5AACEC TShip_Destroy }
destructor TShip.Destroy;
var
  I, J: Integer;
  Star: TStar;
  Ship: TShip;
  Binding: TScriptShip;
  Award: PByte;
begin
  if PlayerHomeRanger = Self then PlayerHomeRanger := nil;
  if PendingPlayerFollowTarget = Self then PendingPlayerFollowTarget := nil;
  if ScriptShip <> nil then begin
    Binding := ScriptShip as TScriptShip;
    Binding.Script.UnbindShip(Self);
  end;
  if LiberationGroup <> nil then LeaveLiberationGroup;
  ClearPlanetQueue;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := Galaxy.Stars[I];
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := Star.Ships[J];
      if Ship.EnemyShip = Self then Ship.EnemyShip := nil;
      if Ship.TruceShip = Self then Ship.TruceShip := nil;
      if Ship.PartnerShip = Self then Ship.PartnerShip := nil;
      if Ship.DockedTo = Self then Ship.DockedTo := nil;
      if Ship.OrderTarget = Self then Ship.OrderNone;
      if (Ship is TTranclucator) and ((Ship as TTranclucator).OwnerShip = Self) then begin
        (Ship as TTranclucator).OwnerShip := nil;
        (Ship as TTranclucator).FollowOwner := False;
      end;
    end;
  end;
  ClearPickupTargets;
  if CurrentStar <> nil then begin
    I := CurrentStar.Ships.IndexOf(Self);
    if I >= 0 then CurrentStar.Ships.Delete(I);
  end;
  I := Galaxy.ShipsInTransit.IndexOf(Self);
  if I >= 0 then Galaxy.ShipsInTransit.Delete(I);
  if Graphic <> nil then begin Graphic.Free; Graphic := nil; end;
  Inventory.Free;
  Artefacts.Free;
  MovementPath.Free;
  if aPlayer.Player = Self then aPlayer.Player := nil;
  if KlingMotherShip = Self then KlingMotherShip := nil;
  RangerRelations.Free;
  if AwardIds <> nil then begin
    for I := AwardIds.Count - 1 downto 0 do begin
      Award := AwardIds[I];
      AwardIds.Delete(I);
      Dispose(Award);
    end;
    AwardIds.Free;
  end;
  inherited Destroy;
end;
{ @end $5AACEC }

{ @routine $5AAFB0 TShip_SaveToBuffer }
procedure TShip.SaveToBuffer(Buffer: TBufEC);
var
  Good: TGoodsIndex;
  Item: TItem;
  I, Count: Integer;
  Award: PByte;
  Skill: TSkill;
begin
  Buffer.AddDWord(Id);
  Buffer.AddWideStringZ(Name);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(ShipType)));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(OwnerId)));
  Buffer.AddSingle(Position.X);
  Buffer.AddSingle(Position.Y);
  if TransitOriginStar = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(TransitOriginStar.Id);
  if CurrentPlanet = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(CurrentPlanet.Id);
  if DockedTo = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(DockedTo.Id);
  if HomePlanet = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(HomePlanet.Id);
  for Good := t_Food to t_Narcotics do
  begin
    Buffer.AddDWord(CargoGoods[Good].Count);
    Buffer.AddDWord(CargoGoods[Good].TotalCost);
  end;
  Buffer.AddDWord(Money);
  Buffer.AddDWord(Seed);
  Buffer.AddDWord(RandomState);
  Buffer.AddDWord(CreationTurn);
  Count := Inventory.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Item := Inventory[I];
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  Count := Artefacts.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Item := Artefacts[I];
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  if PickupTargets = nil then Buffer.AddWideChar(#0)
  else
  begin
    Count := PickupTargets.Count;
    Buffer.AddWideChar(WideChar(Count));
    for I := 0 to Count - 1 do
    begin
      Item := PickupTargets[I];
      Buffer.AddDWord(Item.Id);
    end;
  end;
  if EnemyShip = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(EnemyShip.Id);
  if TruceShip = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(TruceShip.Id);
  if PartnerShip = nil then Buffer.AddDWord(0)
  else
  begin
    Buffer.AddDWord(PartnerShip.Id);
    Buffer.AddDWord(Max(0, PartnershipDaysRemaining));
  end;
  Buffer.AddSingle(MovementDirection);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Order)));
  Buffer.AddDWord(OrderStateData);
  if Order = soJump then Buffer.AddDWord((OrderTarget as TStar).Id)
  else if Order = soEnterBlackHole then Buffer.AddDWord((OrderTarget as THole).Id)
  else if Order = soLanding then
  begin
    if OrderTarget is TShip then Buffer.AddDWord((OrderTarget as TShip).Id or $80000000)
    else Buffer.AddDWord((OrderTarget as TPlanet).Id);
  end
  else if Order = soFollowShip then Buffer.AddDWord((OrderTarget as TShip).Id)
  else Buffer.AddDWord(0);
  Buffer.AddSingle(OrderDestination.X);
  Buffer.AddSingle(OrderDestination.Y);
  Buffer.AddBoolean(OrderAbsolute);
  Buffer.AddWideStringZ(Graphic.GraphKey);
  Buffer.AddAnsiChar(AnsiChar(Graphic.GetAlpha));
  Buffer.AddBoolean(InHyperspace);
  Buffer.AddSingle(CollisionRadius);
  Count := RangerRelations.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do Buffer.AddAnsiChar(AnsiChar(RangerRelations[I]));
  if AwardIds = nil then Buffer.AddAnsiChar(#0)
  else
  begin
    Buffer.AddAnsiChar(AnsiChar(AwardIds.Count));
    for I := 0 to AwardIds.Count - 1 do
    begin
      Award := PByte(AwardIds[I]);
      Buffer.AddAnsiChar(AnsiChar(Award^));
    end;
  end;
  Buffer.AddBoolean(Boolean(DestroyKind));
  for Skill := skAccuracy to skLeadership do Buffer.AddAnsiChar(AnsiChar(BaseSkills[Skill]));
  Buffer.AddWideChar(WideChar(NodeReserve));
  Buffer.AddWideChar(WideChar(TotalExperience));
  Buffer.AddWideChar(WideChar(FreeExperience));
  Buffer.AddWideChar(WideChar(DaysSincePlayerSeen));
  Buffer.AddDWord(EncodedMoney);
  Buffer.AddWideChar(WideChar(LiberationGroupRouteIndex));
end;
{ @end $5AAFB0 }

{ @routine $5AB494 TShip_LoadFromBuffer }
procedure TShip.LoadFromBuffer(Buffer: TBufEC);
var
  Kind: TItemType;
  Item: TItem;
  I, Count: Integer;
  Award: PByte;
  SavedPartner: TShip;
  Skill: TSkill;
begin
  Id := Buffer.GetUInt32;
  if Cardinal(Id) >= Cardinal(Galaxy.NextShipId) then Galaxy.NextShipId := Id + 1;
  Name := Buffer.ReadWideString;
  WriteByteValue(Buffer.GetByte, ShipType);
  WriteByteValue(Buffer.GetByte, OwnerId);
  Position.X := Buffer.GetSingle;
  Position.Y := Buffer.GetSingle;
  TransitOriginStar := TStar(Buffer.GetUInt32);
  CurrentPlanet := TPlanet(Buffer.GetUInt32);
  DockedTo := TShip(Buffer.GetUInt32);
  HomePlanet := TPlanet(Buffer.GetUInt32);
  for Kind := t_Food to t_Narcotics do begin
    CargoGoods[Kind].Count := Buffer.GetUInt32;
    CargoGoods[Kind].TotalCost := Buffer.GetUInt32;
  end;
  SetMoney(Buffer.GetUInt32);
  Seed := Buffer.GetUInt32;
  RandomState := Buffer.GetUInt32;
  if Integer(Seed) < 0 then ShowMessage('TShip.Create; - FRnd<0');
  CreationTurn := Buffer.GetUInt32;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do begin
    WriteByteValue(Buffer.GetByte, Kind);
    Item := CreateItemByType(Kind);
    Inventory.Add(Item);
    Item.LoadFromBuffer(Buffer);
  end;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do begin
    WriteByteValue(Buffer.GetByte, Kind);
    Item := CreateItemByType(Kind);
    Artefacts.Add(Item);
    Item.LoadFromBuffer(Buffer);
  end;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  if Count > 0 then begin
    if PickupTargets <> nil then PickupTargets.Free;
    PickupTargets := TList.Create;
    for I := 0 to Count - 1 do PickupTargets.Add(Pointer(Buffer.GetUInt32));
  end;
  EnemyShip := TShip(Buffer.GetUInt32);
  TruceShip := TShip(Buffer.GetUInt32);
  SavedPartner := TShip(Buffer.GetUInt32);
  PartnerShip := SavedPartner;
  if Cardinal(SavedPartner) > 0 then PartnershipDaysRemaining := Buffer.GetUInt32;
  MovementDirection := Buffer.GetSingle;
  WriteByteValue(Buffer.GetByte, Order);
  OrderStateData := Buffer.GetUInt32;
  OrderTarget := TObject(Buffer.GetUInt32);
  OrderDestination.X := Buffer.GetSingle;
  OrderDestination.Y := Buffer.GetSingle;
  OrderAbsolute := Buffer.GetBoolean;
  if Self is TRuins then Graphic := CreateSpaceObjectByName('Ruins', Buffer.ReadWideString, Classes.Point(0, 0))
  else Graphic := CreateSpaceObjectByName('Ship2', Buffer.ReadWideString, Classes.Point(0, 0)) as TShip2SE;
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(Buffer.GetByte);
  InHyperspace := Buffer.GetBoolean;
  CollisionRadius := Buffer.GetSingle;
  // Native replaces and leaks the constructor's list.
  RangerRelations := TList.Create;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Error FRelationToRangers not in 0..10000');
  for I := 0 to Count - 1 do RangerRelations.Add(Pointer(Buffer.GetByte));
  AwardIds := nil;
  Count := Buffer.GetByte;
  if (Count < 0) or (Count > 255) then raise EAbort.Create('Error FRewards not in 0..255');
  if Count > 0 then begin
    AwardIds := TList.Create;
    for I := 0 to Count - 1 do begin
      New(Award);
      AwardIds.Add(Award);
      Award^ := Buffer.GetByte;
    end;
  end;
  DestroyKind := Byte(Buffer.GetBoolean);
  for Skill := skAccuracy to skLeadership do BaseSkills[Skill] := Buffer.GetByte;
  NodeReserve := Buffer.GetWord;
  TotalExperience := Buffer.GetWord;
  FreeExperience := Buffer.GetWord;
  DaysSincePlayerSeen := Buffer.GetWord;
  if LoadedSaveVersion >= 4 then EncodedMoney := Buffer.GetUInt32;
  LiberationGroupRouteIndex := Buffer.GetWord;
end;
{ @end $5AB494 }

{ @routine $5ABABC TShip_ResolveLoadedReferences }
procedure TShip.ResolveLoadedReferences;
var
  I, Count: Integer;
  Item: TItem;
begin
  TransitOriginStar := Galaxy.IdToStar(Cardinal(TransitOriginStar)) as TStar;
  CurrentPlanet := Galaxy.IdToPlanet(Cardinal(CurrentPlanet)) as TPlanet;
  DockedTo := Galaxy.IdToShip(Cardinal(DockedTo), True) as TShip;
  HomePlanet := Galaxy.IdToPlanet(Cardinal(HomePlanet)) as TPlanet;
  if PickupTargets <> nil then
  begin
    Count := PickupTargets.Count;
    for I := 0 to Count - 1 do
      PickupTargets[I] := Galaxy.IdToItem(Cardinal(PickupTargets[I])) as TItem;
  end;
  EnemyShip := Galaxy.IdToShip(Cardinal(EnemyShip), False) as TShip;
  TruceShip := Galaxy.IdToShip(Cardinal(TruceShip), False) as TShip;
  PartnerShip := Galaxy.IdToShip(Cardinal(PartnerShip), False) as TShip;
  if Order = soJump then OrderTarget := Galaxy.IdToStar(Cardinal(OrderTarget)) as TStar
  else if Order = soEnterBlackHole then OrderTarget := Galaxy.IdToHole(Cardinal(OrderTarget)) as THole
  else if Order = soLanding then
  begin
    if (Cardinal(OrderTarget) and $80000000) = $80000000 then
      OrderTarget := Galaxy.IdToShip(Cardinal(OrderTarget) and $7FFFFFFF, True) as TShip
    else OrderTarget := Galaxy.IdToPlanet(Cardinal(OrderTarget)) as TPlanet;
  end
  else if Order = soFollowShip then OrderTarget := Galaxy.IdToShip(Cardinal(OrderTarget), True) as TShip;
  Count := Inventory.Count;
  for I := 0 to Count - 1 do
  begin
    Item := Inventory[I];
    Item.ClearReferences;
  end;
  Count := Artefacts.Count;
  for I := 0 to Count - 1 do
  begin
    Item := Artefacts[I];
    Item.ClearReferences;
  end;
  RefreshDerivedStats;
  RefreshGraphicSize;
  DerivedStateCompatibilityHook;
end;
{ @end $5ABABC }

{ @routine $5ABD4C TShip_SetMoney }
procedure TShip.SetMoney(Value: Integer);
begin
  if Value > 100000000 then Value := 100000000
  else if Value < 0 then Value := 0;
  if ((EncodedMoney xor MoneyEncodingKey) <> Cardinal(Money)) and not Galaxy.MoneyIntegrityFailed then
    Galaxy.MoneyIntegrityFailed := True;
  Money := Value;
  EncodedMoney := Money xor MoneyEncodingKey;
end;
{ @end $5ABD4C }

{ @routine $5ABDA4 TShip_NextDay }
procedure TShip.NextDay;
begin
  ClearOrderToShipOutsideStar;
  if InHyperspace or (CurrentPlanet <> nil) then TruceShip := nil;
  if (ScriptShip <> nil) and IsOnPlanet and (Self <> Player) then RefuelAtLocation;
  if Galaxy.CurrentTurn <= LastProcessedTurn then Exit;
  Inc(DaysSincePlayerSeen);
  LastProcessedTurn := Galaxy.CurrentTurn;
  if (ShipType = t_Ranger) and (PartnerShip <> nil) and (PartnershipDaysRemaining > 0) then Dec(PartnershipDaysRemaining);
  if Hull.Weight > Hull.HullPoints then RepairHullWithRobot;
  if (Engine <> nil) and (Engine.OutputPercent < 100) then begin
    RefreshDerivedStats;
    if Cardinal(Engine.OutputPercent) + 10 > 100 then Engine.OutputPercent := 100
    else Inc(Engine.OutputPercent, 10);
  end;
  if (FuelTanks <> nil) and FuelTanks.BrokenFlag and (NextRandomUnitFloat(RandomState) < 0.3) and (FuelTanks.Fuel > 2) then begin
    Dec(FuelTanks.Fuel, Round(RemapClamped(FuelTanks.ConditionPercent, -100, 0, FuelTanks.Fuel, 1)));
    if (Self = Player) and not HasActiveArtefact(t_ArtefactFuel) then
      AddOrUpdatePlayerBubble(pmShip, Galaxy.CurrentTurn, LocalizedText('Items.FuelTanks.LostFuel'), '').TargetIds[0] := Id;
    // The native comparison cancels even an in-range jump after this leak.
    if InNormalSpace and (Order = soJump) then
      if JumpRange * JumpRange > PointDistanceSquared(CurrentStar.Position, (OrderTarget as TStar).Position) then OrderNone;
  end;
  if Self = Player then begin
    if Artefacts.Count > 0 then begin
      if (FuelTanks <> nil) and (FuelTanks.Fuel < FuelTanks.Capacity) then
        Inc(FuelTanks.Fuel, Min(2 * (Ord(HasActiveArtefact(t_ArtefactFuel))), FuelTanks.Capacity - FuelTanks.Fuel));
      if (Engine <> nil) and (Engine.OutputPercent < 100) then
        Inc(Engine.OutputPercent, Min(20 * (Ord(HasActiveArtefact(t_ArtefactPower))), 100 - Engine.OutputPercent));
      if (Hull.HullPoints < Hull.Weight) and HasActiveArtefact(t_ArtefactDroid) then
        Inc(Hull.HullPoints, Min(10, Hull.Weight - Hull.HullPoints));
      if HasActiveArtefact(t_ArtefactNano) then ApplyNanoArtefactRepair;
      RefreshDerivedStats;
    end;
    if InNormalSpace then begin
      if Order in [soMove,soLanding,soJump,soTakeoff,soFollowShip] then begin
        ApplyItemDegradation(Engine, idkUse, NextRandomUnitFloat(RandomState) * 0.5);
        ApplyItemDegradation(FuelTanks, idkUse, NextRandomUnitFloat(RandomState) * 0.5);
      end;
      if Radar <> nil then ApplyItemDegradation(Radar, idkUse, NextRandomUnitFloat(RandomState) * 0.3);
      if Scanner <> nil then ApplyItemDegradation(Scanner, idkUse, NextRandomUnitFloat(RandomState) * 0.3);
      if DefGenerator <> nil then ApplyItemDegradation(DefGenerator, idkUse, NextRandomUnitFloat(RandomState) * 0.3);
      DegradeActiveArtefacts(NextRandomFloatRange(0.1, 0.3, RandomState));
    end;
  end;
end;
{ @end $5ABDA4 }

{ @routine $5AC22C TShip_DerivedStateCompatibilityHook }
procedure TShip.DerivedStateCompatibilityHook;
begin
end;
{ @end $5AC22C }

{ @routine $5AC230 TShip_GetLocalizedTypeName }
function TShip.GetLocalizedTypeName: WideString;
begin
  Result := LocalizedText('ShipType.TypeName.' + GetTypeNameKey);
end;
{ @end $5AC230 }

{ @routine $5AC2C4 TShip_RandomInt }
function TShip.RandomInt(BoundA, BoundB: Integer): Integer;
begin
  Result := NextRandomIntRange(BoundA, BoundB, RandomState);
end;
{ @end $5AC2C4 }

{ @routine $5AC2D4 TShip_GetSpaceInfoText }
function TShip.GetSpaceInfoText: WideString;
begin
  Result := GetName;
  case Order of
    soLanding:
      if OrderTarget is TPlanet then
        Result := Result + ' ' + ReplaceColoredToken(LookupLocalizedTextByKey('ShipInfo.Order.LandingToPlanet'), '<Planet>', (OrderTarget as TPlanet).Name, HighlightColorTag)
      else if OrderTarget is TShip then
        Result := Result + ' ' + ReplaceColoredToken(LookupLocalizedTextByKey('ShipInfo.Order.LandingToShip'), '<Ship>', (OrderTarget as TShip).Name, HighlightColorTag);
    soJump:
      Result := Result + ' ' + ReplaceColoredToken(LookupLocalizedTextByKey('ShipInfo.Order.GoToStar'), '<Star>', (OrderTarget as TStar).Name, HighlightColorTag);
    soFollowShip:
      if (OrderTarget as TShip).CurrentPlanet = nil then
      begin
        if EnemyShip <> OrderTarget then
          Result := Result + ' ' + ReplaceColoredToken(LookupLocalizedTextByKey('ShipInfo.Order.GoToShip'), '<Ship>', (OrderTarget as TShip).GetName, HighlightColorTag)
        else
          Result := Result + ' ' + ReplaceColoredToken(LookupLocalizedTextByKey('ShipInfo.Order.GoToShipBad'), '<Ship>', (OrderTarget as TShip).GetName, HighlightColorTag);
      end
      else Result := Result + ' ' + LookupLocalizedTextByKey('ShipInfo.Order.None');
    soMove:
      Result := Result + ' ' + LookupLocalizedTextByKey('ShipInfo.Order.Move');
  end;
  Result := Result + #13#10 + FormatText1(LookupLocalizedTextByKey('ShipInfo.SpaceSize'), HighlightColorTag, '<Size>', IntToStr(Hull.Weight));
  if Hull.Weight > Hull.HullPoints then
    Result := Result + ' ' + FormatText1(LookupLocalizedTextByKey('ShipInfo.SpaceDamageProc'), HighlightColorTag, '<Proc>', IntToStr(Trunc(100 - Hull.HullPoints / (Hull.Weight * 0.01))));
  Result := Result + #13#10 + FormatText1(LookupLocalizedTextByKey('ShipInfo.SpaceSpeed'), HighlightColorTag, '<Speed>', IntToStr(CalculateSpeed));
  Result := Result + #13#10 + FormatText1(LookupLocalizedTextByKey('ShipInfo.SpaceDefField'), HighlightColorTag, '<Proc>', IntToStr(GetDefensePercent));
  if Player <> Self then
  begin
    Result := Result + #13#10 + FormatText1(LookupLocalizedTextByKey('ShipInfo.SpaceRelation'), HighlightColorTag, '<Type>', LowerCaseWideString(GetRelationLevelTextToShip(Player)));
    if Player.HasActiveArtefact(t_ArtefactAnalyzer) then
      Result := Result + #13#10 + FormatText1(LookupLocalizedTextByKey('Items.ArtefactAnalyzer.TextToRadar'), HighlightColorTag, '<ChanceToWin>', IntToStr(Player.GetWinChancePercent(Self)));
  end;
end;
{ @end $5AC2D4 }

{ @routine $5ACC58 TShip_IsHullDestroyed }
// Uses a denser path in the player's currently displayed star.
function TShip.IsHullDestroyed: Boolean;
begin
  Result := Hull.HullPoints <= 0;
end;
{ @end $5ACC58 }

{ @routine $5ACC68 TShip_GetLegacyShipTypeLabel }
function TShip.GetLegacyShipTypeLabel: WideString;
begin
  Result := '';
  if ShipType = t_Kling then Result := 'Kling'
  else if ShipType = t_Ranger then Result := 'Ranger'
  else if ShipType = t_Transport then
  begin
    if (Self as TTransport).TransportType = ttTransport then Result := 'Transport'
    else if (Self as TTransport).TransportType = ttLiner then Result := 'Liner'
    else if (Self as TTransport).TransportType = ttDiplomat then Result := 'Diplomat';
  end
  else if ShipType = t_Pirate then Result := 'Pirate'
  else if ShipType = t_Warrior then Result := 'Warrior';
end;
{ @end $5ACC68 }

{ @routine $5ACDC0 TShip_GetTurnSeedFraction }
function TShip.GetTurnSeedFraction(TurnOffset: Integer): Single;
begin
  Result := Frac(Integer(Seed) / (Galaxy.CurrentTurn + TurnOffset));
end;
{ @end $5ACDC0 }

{ @routine $5ACDF4 TShip_GetEstimatedMemoryUsage }
function TShip.GetEstimatedMemoryUsage: Integer;
begin
  Result := InstanceSize;
  if Inventory <> nil then Result := Result + Inventory.InstanceSize + Inventory.Count * 4;
  if Artefacts <> nil then Result := Result + Artefacts.InstanceSize + Artefacts.Count * 4;
  if PickupTargets <> nil then Result := Result + PickupTargets.InstanceSize + PickupTargets.Count * 4;
  if PlanetQueue <> nil then Result := Result + PlanetQueue.InstanceSize + PlanetQueue.Count * 4;
  Result := Result + Length(DatabaseLogText) * SizeOf(WideChar);
end;
{ @end $5ACDF4 }

{ @routine $5ACE9C TShip_HasCargoGoods }
function TShip.HasCargoGoods: Boolean;
var
  Good: TGoodsIndex;
begin
  Result := False;
  for Good := t_Food to t_Narcotics do
    if CargoGoods[Good].Count > 0 then
    begin
      Result := True;
      Break;
    end;
end;
{ @end $5ACE9C }

{ @routine $5ACEBC TShip_CountCargoGoodsTypes }
function TShip.CountCargoGoodsTypes: Byte;
var Good: TGoodsIndex;
begin
  Result := 0;
  for Good := t_Food to t_Narcotics do if CargoGoods[Good].Count > 0 then Inc(Result);
end;
{ @end $5ACEBC }

{ @routine $5ACED8 TShip_GetCarriedNodeCount }
function TShip.GetCarriedNodeCount: Integer;
var
  I: Integer;
  Item: TItem;
begin
  Result := 0;
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := Inventory[I];
    if Item.ItemType = t_Protoplasm then Inc(Result, Item.Weight);
  end;
end;
{ @end $5ACED8 }

{ @routine $5ACF14 TShip_HasLockedOrFollowOrder }
function TShip.HasLockedOrFollowOrder: Boolean;
begin
  if OrderAbsolute or (Order = soFollowShip) then Result := True
  else Result := False;
end;
{ @end $5ACF14 }

{ @routine $5ACF2C TShip_HasHullDamageOrBrokenEquippedItems }
function TShip.HasHullDamageOrBrokenEquippedItems: Boolean;
var
  I: Integer;
  Item: TEquipment;
begin
  Result := Hull.HullPoints < Hull.Weight;
  if Result then Exit;
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := Inventory[I];
    if Item.BrokenFlag then
    begin
      Result := True;
      Break;
    end;
  end;
end;
{ @end $5ACF2C }

{ @routine $5ACF7C TShip_CanRefuel }
function TShip.CanRefuel: Boolean;
begin
  if FuelTanks <> nil then Result := FuelTanks.Fuel < FuelTanks.Capacity
  else Result := False;
end;
{ @end $5ACF7C }

{ @routine $5ACF98 TShip_LookupVisibleTalkText }
function TShip.LookupVisibleTalkText(const Path: WideString): WideString;
begin
  if (Player <> nil) and (Player.CurrentStar = CurrentStar) then Result := LookupTalkText(Path)
  else Result := '';
end;
{ @end $5ACF98 }

{ @routine $5ACFD4 TShip_UpdateBestRangerRelativeRatings }
procedure TShip.UpdateBestRangerRelativeRatings;
begin
  WealthInBestRanger := Wealth / Galaxy.MaxRangerWealth;
  StrengthInBestRanger := Strength / Galaxy.BestRangerStrength;
end;
{ @end $5ACFD4 }

{ @routine $5ACFFC TShip_UpdateAverageRangerRelativeStrength }
procedure TShip.UpdateAverageRangerRelativeStrength;
begin
  StrengthInAverageRanger := Strength / Galaxy.AverageRangerStrength;
end;
{ @end $5ACFFC }

{ @routine $5AD014 TShip_CalculateWealth }
function TShip.CalculateWealth: Integer;
var I, Total: Integer; Kind: TGoodsIndex; Item: TItem;
begin
  Total := Money;
  for I := 0 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    Inc(Total, Item.Cost);
  end;
  for Kind := t_Food to t_Narcotics do Inc(Total, CargoGoods[Kind].TotalCost);
  Result := Total;
  Wealth := Result;
end;
{ @end $5AD014 }

{ @routine $5AD05C TShip_CalculateStrength }
function TShip.CalculateStrength: Double;
var
  I: Integer;
  Mode: TWeaponDamageMode;
begin
  Result := 0.0000001;
  for I := 1 to WeaponCount do begin
    if Weapons[I - 1].BrokenFlag then Continue;
    Mode := WeaponInfo[Weapons[I - 1].ItemType].Mode;
    if Mode = wmHullDamage then
      Result := Result + RemapClamped(BaseSkills[skAccuracy], 0, 5,
        (Weapons[I - 1].MaxDamage + Weapons[I - 1].MinDamage) div 2, Weapons[I - 1].MaxDamage);
  end;
  Result := Result * (UsableWeaponCount + 7) * Hull.HullPoints * (Hull.Armor + 5) / DefenseDamageFactor;
  if (GetHullIntegrityPercent > 50) and (RepairRobot <> nil) and not RepairRobot.BrokenFlag then
    Result := Result * (RepairRobot.TechLevel + 5)
  else Result := Result * 5;
  Strength := Result;
end;
{ @end $5AD05C }

{ @routine $5AD1C0 TShip_GetWealthScaledAmount }
function TShip.GetWealthScaledAmount(ScaleIndex: TStandardCount): Integer;
var Value: Single;
begin
  Value := Round(Wealth * WealthDemandScales[ScaleIndex]);
  if Value < 5000 then Result := Round(Value)
  else Result := Round((Value - 5000) * 0.3 + 5000);
end;
{ @end $5AD1C0 }

{ @routine $5AD238 TShip_HasScriptBindings }
function TShip.HasScriptBindings: Boolean;
begin
  if Self is TPlayer then Result := TPlayer(Self).ScriptShipBindings.Count > 0
  else Result := ScriptShip <> nil;
end;
{ @end $5AD238 }

{ @routine $5AD268 TShip_GetShipPortraitImagePath }
function TShip.GetShipPortraitImagePath: WideString;
begin
  Result := '';
  if Self is TRanger then Result := ShipRenderTemplates[Hull.OwnerId, 0].PortraitImagePath
  else if Self is TWarrior then Result := ShipRenderTemplates[Hull.OwnerId, 1].PortraitImagePath
  else if Self is TPirate then Result := ShipRenderTemplates[Hull.OwnerId, 2].PortraitImagePath
  else if Self is TTransport then
    case (Self as TTransport).TransportType of
      ttTransport: Result := ShipRenderTemplates[Hull.OwnerId, 3].PortraitImagePath;
      ttLiner: Result := ShipRenderTemplates[Hull.OwnerId, 4].PortraitImagePath;
      ttDiplomat: Result := ShipRenderTemplates[Hull.OwnerId, 5].PortraitImagePath;
    end
  else if Self is TKling then Result := KlissanRenderTemplates[Ord((Self as TKling).KlingType)].PortraitImagePath
  else if Self is TTranclucator then Result := GameDataConfig.GetParamByPath('SE.Ship.Tranclucator.' + GiResourceSuffix + 'ImageP')
  else if Self is TRuins then Result := (Graphic as TRuinsSE).StaticImagePath
  else Result := '';
end;
{ @end $5AD268 }

{ @routine $5AD4F4 TShip_TransferToStar }
procedure TShip.TransferToStar(Star: TStar);
var PreviousStar: TStar; I: Integer; Ship: TShip;
begin
  TransitOriginStar := CurrentStar;
  PreviousStar := CurrentStar;
  I := PreviousStar.Ships.IndexOf(Self);
  if I >= 0 then PreviousStar.Ships.Delete(I);
  Star.Ships.Add(Self);
  CurrentStar := Star;
  I := 0;
  while I < TransitOriginStar.Ships.Count do
  begin
    Ship := TShip(TransitOriginStar.Ships[I]);
    if Ship.DockedTo = Self then Ship.TransferToStar(Star)
    else Inc(I);
  end;
end;
{ @end $5AD4F4 }

{ @routine $5AD558 TShip_FindCarriedItemById }
function TShip.FindCarriedItemById(Id: Integer): TItem;
var I, Count: Integer;
begin
  Count := Inventory.Count;
  for I := 0 to Count - 1 do begin
    Result := Inventory[I];
    if Id = Result.Id then Exit;
  end;
  Count := Artefacts.Count;
  for I := 0 to Count - 1 do begin
    Result := Artefacts[I];
    if Id = Result.Id then Exit;
  end;
  Result := nil;
end;
{ @end $5AD558 }

{ @routine $5AD5BC TShip_TryRelocateUnseenShip }
procedure TShip.TryRelocateUnseenShip;
var
  Candidate, Destination: TStar;
  Index: Integer;
  Distance, BestDistance: Single;
  Planet: TPlanet;
begin
  if (Player <> nil) and (Player = PartnerShip) then Exit;
  if NextRandomUnitFloat(RandomState) < 0.002 then Exit;
  if DaysSincePlayerSeen < 20 then Exit;
  if (Galaxy.CountStarsByFaction(sfCoalition) * 2.5 < Galaxy.Rangers.Count) and
    (Self is TRanger) and ((Self as TRanger).PlaceInRating > 10) then Exit;
  if Player = Self then Exit;
  BestDistance := 1e20;
  Destination := nil;
  for Index := 0 to Galaxy.Stars.Count - 1 do
  begin
    Candidate := Galaxy.Stars[Index];
    if (Candidate = CurrentStar) or (Candidate.ControlFaction <> sfCoalition) or
      Candidate.Battle or (Player.CurrentStar = Candidate) or
      (Candidate.ShipTypeCounts[t_Ranger] >= 3) then Continue;
    Distance := PointDistanceSquared(CurrentStar.Position, Candidate.Position);
    if (Distance < BestDistance) and ((Destination = nil) or (NextRandomIntRange(0, 1, RandomState) = 0)) then
    begin
      BestDistance := Distance;
      Destination := Candidate;
    end;
  end;
  if Destination = nil then Exit;
  Planet := nil;
  Index := 0;
  while Index < Destination.Planets.Count do
  begin
    Planet := Destination.Planets[Index];
    if Planet.IsCoalitionOwned then Break;
    Planet := nil;
    Inc(Index);
  end;
  if Planet = nil then Exit;
  OrderNone;
  if FuelTanks = nil then CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
  if Engine = nil then CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
  CurrentStar.HandleObjectLeavingStar(Self);
  DockedTo := nil;
  CurrentPlanet := Planet;
  OrderTarget := Destination;
  Hull.HullPoints := Hull.Weight div 2;
  Galaxy.ShipsInTransit.Add(Self);
  if Galaxy.AverageRangerCapital > Wealth then
  begin
    SetMoney(Money + (Galaxy.AverageRangerCapital - Wealth) div 2);
    CalculateWealth;
  end;
end;
{ @end $5AD5BC }

{ @routine $5AD840 TShip_InNormalSpace }
function TShip.InNormalSpace: Boolean;
begin
  if (CurrentStar = nil) or (CurrentPlanet <> nil) or (DockedTo <> nil) or InHyperspace then
    Result := False
  else Result := True;
end;
{ @end $5AD840 }

{ @routine $5AD864 TShip_IsOutsideStarSpace }
function TShip.IsOutsideStarSpace: Boolean;
begin
  Result := (CurrentPlanet <> nil) or (DockedTo <> nil) or InHyperspace or (CurrentStar = nil);
end;
{ @end $5AD864 }

{ @routine $5AD888 TShip_IsOnPlanet }
function TShip.IsOnPlanet: Boolean;
begin
  Result := CurrentPlanet <> nil;
end;
{ @end $5AD888 }

{ @routine $5AD890 TShip_IsDockedToShip }
function TShip.IsDockedToShip: Boolean;
begin
  Result := DockedTo <> nil;
end;
{ @end $5AD890 }

{ @routine $5AD898 TShip_HasPositiveSpeed }
function TShip.HasPositiveSpeed: Boolean;
begin
  Result := Speed > 0;
end;
{ @end $5AD898 }

{ @routine $5AD8A4 TShip_ClearOrderToShipOutsideStar }
procedure TShip.ClearOrderToShipOutsideStar;
begin
  if OrderTarget is TShip then
    if (OrderTarget as TShip).CurrentStar <> CurrentStar then OrderNone;
end;
{ @end $5AD8A4 }

{ @routine $5AD8E0 TShip_ClearPlanetQueue }
procedure TShip.ClearPlanetQueue;
begin
  if PlanetQueue <> nil then
  begin
    PlanetQueue.Free;
    PlanetQueue := nil;
  end;
end;
{ @end $5AD8E0 }

{ @routine $5AD8FC TShip_SelectNearestQueuedPlanet }
function TShip.SelectNearestQueuedPlanet: TPlanet;
var Planet: TPlanet; I: Integer; BestDistance: Double;
begin
  if PlanetQueue.Count = 0 then begin Result := nil; Exit; end;
  begin
    Result := PlanetQueue[0];
    if Result.CurrentStar = CurrentStar then begin
      BestDistance := PointDistanceSquared(Position, Result.GetPosition);
      for I := 1 to PlanetQueue.Count - 1 do begin
        Planet := PlanetQueue[I];
        if Planet.CurrentStar <> CurrentStar then Break;
        if PointDistanceSquared(Position, Planet.GetPosition) < BestDistance then Result := Planet;
      end;
    end;
  end;
end;
{ @end $5AD8FC }

{ @routine $5AD9AC TShip_FindCoalitionPlanetForStation }
function TShip.FindCoalitionPlanetForStation: TPlanet;
var I: Integer;
begin
  Result := CurrentStar.Planets[0];
  if Result.IsCoalitionOwned then Exit;
  for I := 1 to CurrentStar.Planets.Count - 1 do
  begin
    Result := CurrentStar.Planets[I];
    if Result.IsCoalitionOwned then Exit;
  end;
end;
{ @end $5AD9AC }

{ @routine $5AD9F8 TShip_NavigateToQueuedPlanet }
function TShip.NavigateToQueuedPlanet(Absolute: Boolean): TPlanet;
var Planet: TPlanet;
begin
  if PlanetQueue = nil then begin
    BuildReachablePlanetQueue;
    if PlanetQueue = nil then begin Result := nil; Exit; end;
  end;
  if PlanetQueue.Count > 0 then begin
  Planet := SelectNearestQueuedPlanet;
  if CurrentStar = Planet.CurrentStar then OrderLanding(Planet, Absolute)
  else OrderJump(Planet.CurrentStar, Absolute);
  Result := Planet;
  end else Result := nil;
end;
{ @end $5AD9F8 }

{ @routine $5ADA5C TShip_NavigateToEscapePlanet }
function TShip.NavigateToEscapePlanet(Absolute: Boolean): Boolean;
var Planet: TPlanet;
begin
  if PlanetQueue = nil then begin Result := False; Exit; end;
  if PlanetQueue.Count > 0 then begin
  if (NextRandomUnitFloat(RandomState) > 0.9) or (FuelTanks.Fuel = FuelTanks.Capacity) then Planet := PlanetQueue[PlanetQueue.Count - 1]
  else Planet := SelectNearestQueuedPlanet;
  if CurrentStar = Planet.CurrentStar then OrderLanding(Planet, Absolute)
  else OrderJump(Planet.CurrentStar, Absolute);
  Result := True;
  end else Result := False;
end;
{ @end $5ADA5C }

{ @routine $5ADAF0 TShip_TryMirrorPartnerTravelOrders }
function TShip.TryMirrorPartnerTravelOrders: Boolean;
var Star: TStar;
begin
  if (PartnerShip as TRanger).PrisonTermRemaining > 0 then begin Result := False; Exit; end;
  if PartnerShip.CurrentStar = CurrentStar then
  begin
    if PartnerShip.InNormalSpace then
    begin
      if (PartnerShip.OrderTarget is TStar) and (PartnerShip.EstimateOrderTravelTurns < 6) then
      begin
        OrderJump(PartnerShip.OrderTarget as TStar, False);
        Result := True; Exit;
      end;
      if (PartnerShip.OrderTarget is TPlanet) and CanQueueReachablePlanet(PartnerShip.OrderTarget as TPlanet) and
        (PartnerShip.EstimateOrderTravelTurns < 6) then
      begin
        OrderLanding(PartnerShip.OrderTarget, CanRefuel);
        Result := True; Exit;
      end;
      if (PartnerShip.OrderTarget is TShip) and (PartnerShip.Order = soLanding) and (PartnerShip.EstimateOrderTravelTurns < 6) then
      begin
        OrderLanding(PartnerShip.OrderTarget, CanRefuel);
        Result := True; Exit;
      end;
      if (PartnerShip.Order = soFollowShip) and (PartnerShip.EstimateOrderTravelTurns < 3) then
      begin
        OrderFollowShip(PartnerShip.OrderTarget as TShip, fmNear, False);
        Result := True; Exit;
      end;
      if (PartnerShip.OrderTarget is TStar) and CanRefuel then
      begin
        (Self as TRanger).SelectNearestReachableDestination;
        Result := False; Exit;
      end
      else
      begin
        OrderFollowShip(PartnerShip, fmNear, False);
        Result := True; Exit;
      end;
    end
    else
    begin
      if PartnerShip.CurrentPlanet <> nil then
      begin
        if CanQueueReachablePlanet(PartnerShip.CurrentPlanet) then
        begin
          OrderLanding(PartnerShip.CurrentPlanet, True);
          Result := True; Exit;
        end;
      end
      else if PartnerShip.DockedTo <> nil then
      begin
        OrderLanding(PartnerShip.DockedTo, False);
        Result := True; Exit;
      end;
    end;
  end
  else
  begin
    if (PartnerShip.OrderTarget is TStar) and
      (((PartnerShip.OrderTarget as TStar).ControlFaction = sfCoalition) or
      (FuelTanks.Fuel div 2 >= PointDistance(CurrentStar.Position, (PartnerShip.OrderTarget as TStar).Position))) then
    begin
      Star := PartnerShip.OrderTarget as TStar;
      if (Star <> CurrentStar) and
        ((JumpRange * JumpRange >= PointDistanceSquared(CurrentStar.Position, Star.Position)) or
        (FuelTanks.Fuel = FuelTanks.Capacity)) then
      begin
        OrderJump(Star, True);
        Result := True; Exit;
      end;
    end
    else
    begin
      if ((JumpRange * JumpRange >= PointDistanceSquared(CurrentStar.Position, PartnerShip.CurrentStar.Position)) or
        (FuelTanks.Fuel = FuelTanks.Capacity)) and
        ((PartnerShip.CurrentStar.ControlFaction = sfCoalition) or
        (FuelTanks.Fuel div 2 >= PointDistance(CurrentStar.Position, PartnerShip.CurrentStar.Position))) then
      begin
        OrderJump(PartnerShip.CurrentStar, True);
        Result := True; Exit;
      end;
    end;
  end;
  Result := False;
end;
{ @end $5ADAF0 }

{ @routine $5ADEC0 TShip_OrderRandomFreeFlightMove }
procedure TShip.OrderRandomFreeFlightMove;
var
  Polar: TPolarPoint;
begin
  Polar.Radius := NextRandomIntRange(CurrentStar.SystemRadius + 300, CurrentStar.ComputeMapDiameter, RandomState);
  Polar.AngleDegrees := NextRandomUnitFloat(RandomState) * 360;
  OrderMove(PolarToPoint(Polar), False);
end;
{ @end $5ADEC0 }

{ @routine $5ADF2C TShip_IsTargetStillPursuable }
function TShip.IsTargetStillPursuable(Target: TShip): Boolean;
begin
  if (Target.Order <> soJump) or (PointDistance(Position, Target.Position) < Speed * 2) then Result := True
  else Result := False;
end;
{ @end $5ADF2C }

{ @routine $5ADF68 TShip_CanEscapePursuer }
function TShip.CanEscapePursuer(Pursuer: TShip): Boolean;
var I: Integer; Weapon: TWeapon; Distance: Double;
begin
  Result := True;
  if ((EstimateOrderTravelTurns = 1) and (Hull.HullPoints > Hull.Weight * 0.5)) or
    ((EstimateOrderTravelTurns = 2) and (Hull.HullPoints > Hull.Weight * 0.9)) then Exit;
  Distance := PointDistance(Position, Pursuer.Position);
  for I := 1 to Pursuer.WeaponCount do begin
    Weapon := Pursuer.Weapons[I - 1];
    if not Weapon.BrokenFlag and (Weapon.Range > Distance) then begin Result := False; Exit; end;
  end;
  if (Pursuer.Speed < Speed) and (2 * Pursuer.Speed < Distance) then Exit;
  if 2 * Pursuer.Speed > Distance then begin Result := False; Exit; end;
  if 6 * Pursuer.Speed < Distance then Exit;
  if Order = soLanding then begin
    if OrderTarget is TShip then begin
      if PointDistance((OrderTarget as TShip).Position, Position) / Speed > 3 then begin Result := False; Exit; end;
    end else if PointDistance((OrderTarget as TPlanet).GetPosition, Position) / Speed > 3 then begin Result := False; Exit; end;
  end else if (Pursuer.Order = soJump) and (PointDistance(OrderDestination, Position) / Speed > 6) then begin Result := False; Exit; end;
end;
{ @end $5ADF68 }

{ @routine $5AE154 TShip_HasLandablePlanetInStar }
function TShip.HasLandablePlanetInStar(Star: TStar): Boolean;
var I: Integer; Planet: TPlanet;
begin
  for I := 0 to Star.Planets.Count - 1 do begin
    Planet := TPlanet(Star.Planets[I]);
    if CanQueueReachablePlanet(Planet) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5AE154 }

{ @routine $5AE19C TShip_GetFullFuelBaseJumpRange }
function TShip.GetFullFuelBaseJumpRange: Integer;
begin
  Result := Min(FuelTanks.Capacity, Engine.JumpRange);
end;
{ @end $5AE19C }

{ @routine $5AE1E8 TShip_FindNextStarTowardDestination }
function TShip.FindNextStarTowardDestination(Destination: TStar; RequireFuelMargin: Boolean): TStar;
var
  I, J, K, RangeSquared, CapacitySquared: Integer;
  Origin, Star: TStar;
  Predecessors: TList;
  Previous, Entry, CurrentEntry, CandidateEntry: PInteger;
  // @nested $5AE1B8 ClearPredecessors
  procedure ClearPredecessors; // @addr $5AE1B8 @calls "0x005AE3CD,0x005AE468"
  var Index: Integer;
  begin
    // Deletes list entries without freeing their allocated integers.
    for Index := Predecessors.Count - 1 downto 0 do Predecessors.Delete(Index);
    Predecessors.Free;
  end;
begin
  Predecessors := TList.Create;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    New(Entry);
    if I = 0 then Entry^ := 0 else Entry^ := -1;
    Predecessors.Add(Entry);
  end;
  RangeSquared := GetFullFuelBaseJumpRange * GetFullFuelBaseJumpRange;
  CapacitySquared := FuelTanks.Capacity * FuelTanks.Capacity;
  for I := 0 to Galaxy.Stars.Count - 2 do
  begin
    Origin := CurrentStar.StarDistances[I].Star as TStar;
    Entry := Predecessors[I];
    if Entry^ = -1 then Break;
    for J := 1 to Galaxy.Stars.Count - 1 do
    begin
      Star := Origin.StarDistances[J].Star as TStar;
      if RangeSquared < PointDistanceSquared(Origin.Position, Star.Position) then Break;
      if Star = Destination then
      begin
        if (RequireFuelMargin <> True) or (CapacitySquared >= PointDistanceSquared(Origin.Position, Star.Position) * 2) then
        begin
          Previous := Entry;
          while Previous^ > 1 do
          begin
            CurrentEntry := Previous;
            Result := CurrentStar.StarDistances[Predecessors.IndexOf(CurrentEntry)].Star as TStar;
            Previous := Predecessors[Previous^ - 1];
          end;
          Result := CurrentStar.StarDistances[Predecessors.IndexOf(Previous)].Star as TStar;
          ClearPredecessors;
          Exit;
        end;
        Continue;
      end;
      if HasLandablePlanetInStar(Star) and (Star.CountShipsByTypeMask([t_Ranger..t_Tranclucator]) <= 20) and (Star.ShipTypeCounts[t_Ranger] <= 9) then
        for K := 1 to Galaxy.Stars.Count - 1 do
          if Star = (CurrentStar.StarDistances[K].Star as TStar) then
          begin
            CandidateEntry := Predecessors[K];
            if CandidateEntry^ = -1 then CandidateEntry^ := I + 1;
            Break;
          end;
    end;
  end;
  Result := nil;
  ClearPredecessors;
end;
{ @end $5AE1E8 }

{ @routine $5AE480 TShip_DistanceToNearestShipByTypeMask }
function TShip.DistanceToNearestShipByTypeMask(ShipTypeMask: TShipTypeMask): Double;
var I: Integer; Ship: TShip; BestDistance, Distance: Single;
begin
  BestDistance := 1000000000;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := TShip(CurrentStar.Ships[I]);
    if (Ship.ShipType in ShipTypeMask) and (Ship <> Self) then begin
      Distance := PointDistanceSquared(Position, Ship.Position);
      if Distance < BestDistance then BestDistance := Distance;
    end;
  end;
  Result := Sqrt(BestDistance);
end;
{ @end $5AE480 }

{ @routine $5AE508 TShip_FindNearestStarByControlFaction }
function TShip.FindNearestStarByControlFaction(Faction: TStarControlFaction): TStar;
var I: Integer;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Result := CurrentStar.StarDistances[I].Star as TStar;
    if Result.ControlFaction = Faction then Exit;
  end;
  Result := nil;
end;
{ @end $5AE508 }

{ @routine $5AE54C TShip_EstimateOrderTravelTurns }
function TShip.EstimateOrderTravelTurns: Integer;
begin
  case Order of
    soMove: Result := Round(PointDistance(OrderDestination, Position) / (Speed + 1)) + 1;
    soLanding:
      if OrderTarget is TPlanet then
        Result := Round(PointDistance((OrderTarget as TPlanet).GetPosition, Position) / (Speed + 1)) + 1
      else Result := Round(PointDistance((OrderTarget as TShip).Position, Position) / (Speed + 1)) + 1;
    soJump: Result := Round(PointDistance(OrderDestination, Position) / (Speed + 1)) + 1;
    soEnterBlackHole: Result := Round(PointDistance(OrderDestination, Position) / (Speed + 1)) + 1;
    soFollowShip: Result := Round(PointDistance((OrderTarget as TShip).Position, Position) / (Speed + 1)) + 1;
  else Result := 0;
  end;
end;
{ @end $5AE54C }

{ @routine $5AE6B8 TShip_EstimateTravelTurnsToObject }
function TShip.EstimateTravelTurnsToObject(Target: TObject): Integer;
var Angle, Radius: Double; Point: TPointF;
begin
  if Target is TPlanet then Result := Round(PointDistance((Target as TPlanet).GetPosition, Position) / Speed) + 1
  else if Target is TShip then Result := Round(PointDistance((Target as TShip).Position, Position) / Speed) + 1
  else if Target is TStar then begin
    Angle := HeadingDegreesToRadians(PointBearingDegrees(CurrentStar.Position, (Target as TStar).Position));
    Radius := CurrentStar.ComputeMapDiameter / 2;
    Point.X := Trunc(Sin(Angle) * Radius);
    Point.Y := Trunc(-Cos(Angle) * Radius);
    Result := Round(PointDistance(Point, Position) / Speed) + 1;
  end else Result := 0;
end;
{ @end $5AE6B8 }

{ @routine $5AE80C TShip_EstimateTravelTurnsToPlanet }
function TShip.EstimateTravelTurnsToPlanet(Planet: TPlanet): Integer;
begin
  if (Speed = 0) or (Planet = nil) or (Planet.CurrentStar = nil) or (Planet.CurrentStar <> CurrentStar) then begin Result := -1; Exit; end;
  Result := Round(PointDistance(Planet.GetPosition, Position) / Speed) + 1;
end;
{ @end $5AE80C }

{ @routine $5AE85C TShip_ApplyWeaponHit }
function TShip.ApplyWeaponHit(Source: TShip; Weapon: TWeapon; HitRange: Single; out DamageColor: Cardinal): Integer;
var
  Damage, I, DropCount, OutputLoss, EngineLoss: Integer;
  Factor, Value: Double;
  Remains: TUselessItem;
  MinimumDistance: Single;
  Text: WideString;
  Item: TItem;
  Nodes: TProtoplasm;
  Hole: THole;
  HoleFilmObject: TEFilmObj;
  ShipKind: TShipType; AttackSkill, DefenseSkill: TSkillLevel;
begin
  if Self is TPlayer then
  begin
    Damage := TPlayer(Self).ScriptShipBindings.Count;
    for I := 0 to Damage - 1 do TScriptShip(TPlayer(Self).ScriptShipBindings[I]).HitPlayer := True;
  end
  else if ScriptShip <> nil then TScriptShip(ScriptShip).Hit := True;
  if HitRange = -1 then ReactToAttack(Source);
  Damage := 0;
  DamageColor := 0;
  ShipKind := ShipType;
  if (ShipKind <> t_Kling) or (Source.ShipType <> t_Kling) then
    case WeaponInfo[Weapon.ItemType].Mode of
      wmHullDamage:
        begin
          AttackSkill := Source.BaseSkills[skAccuracy];
          DefenseSkill := BaseSkills[skMobility];
          if AttackSkill = DefenseSkill then
            Damage := NextRandomIntRange(Weapon.MinDamage, Weapon.MaxDamage, RandomState)
          else if AttackSkill < DefenseSkill then
            Damage := NextRandomIntRange(Weapon.MinDamage, Weapon.MaxDamage - (Weapon.MaxDamage - Weapon.MinDamage) div 2, RandomState)
          else
            Damage := NextRandomIntRange(Weapon.MinDamage + (Weapon.MaxDamage - Weapon.MinDamage) div 2, Weapon.MaxDamage, RandomState);
          Damage := Round(Damage * GetDefenseDamageFactor - Hull.Armor - 5 * (Ord(HasActiveArtefact(t_ArtefactHull))));
          if Damage <= 0 then
            if NextRandomUnitFloat(RandomState) < 0.5 then Damage := 0 else Damage := 1;
          if Self = KlingMotherShip then
          begin
            if (Player.CurrentStar <> CurrentStar) and (DaysSincePlayerSeen >= 20) then Damage := Damage div 2;
            if Damage >= Hull.HullPoints then Damage := Hull.HullPoints - 1;
          end;
          if Hull.HullPoints - Damage <= 0 then
          begin
            if Source is TNormalShip then (Source as TNormalShip).RecordShipKill(Self);
            if Source.ShipType = t_Ranger then (Source as TRanger).UpdateRelationsAfterShipKill(Self);
            if Player = PartnerShip then
            begin
              Text := PickLocalizedTextVariant('GalaxyNews.DeadShip.Partner', Seed + Galaxy.CurrentTurn div 11);
              ReplaceTextToken(Text, '<Star>', CurrentStar.Name, HighlightColorTag);
              ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(-1), HighlightColorTag);
              ReplaceTextToken(Text, '<Name>', GetName, HighlightColorTag);
              ReplaceTextToken(Text, '<FullName>', GetFullName(' '), HighlightColorTag);
              AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
            end;
            if (Source.OwnerId = oiKling) or (OwnerId = oiKling) then CurrentStar.UpdateControlFaction;
            Player.ProcessShipDestructionQuests(Self);
            Hull.HullPoints := 0;
            if Self is TRuins then JettisonCargoGoodsTowardTargetValue(Galaxy.ComputeScaledHugeMoney(oiPeople))
            else if (CurrentStar.Items = nil) or (CurrentStar.Items.Count < 20) or (OwnerId = oiKling) then
            begin
              Value := NextRandomUnitFloat(RandomState);
              if Value < 0.1 then DropRandomValuableItemsOnDestruction(1)
              else
              begin
                if Value < 0.85 then DropCount := 1 else DropCount := 2;
                if (Player = Source) and Source.HasActiveArtefact(t_ArtefactMiniExpl) then
                begin
                  if NextRandomUnitFloat(RandomState) > 0.6 then Inc(DropCount)
                  else if NextRandomUnitFloat(RandomState) > 0.8 then DropRandomValuableItemsOnDestruction(1);
                end;
                DropRandomCheapItemsOnDestruction(DropCount);
              end;
              if OwnerId = oiKling then
              begin
                if (Cardinal(Galaxy.CurrentTurn) + RandomState) mod 2 = 0 then
                begin
                  Nodes := TProtoplasm.Create;
                  Nodes.Init(NodeReserve + 1, 1);
                  Inventory.Add(Nodes);
                  DropCarriedItemAsMovingLoot(Nodes);
                end
                else
                begin
                  Remains := TUselessItem.Create;
                  Remains.Init('Remains', Seed + Galaxy.CurrentTurn div 10);
                  Inventory.Add(Remains);
                  DropCarriedItemAsMovingLoot(Remains);
                end;
              end
              else if ShipType in [t_Ranger..t_Pirate] then JettisonCargoGoodsTowardTargetValue(Galaxy.ComputeScaledAverageMoney(OwnerId));
            end;
            if Artefacts.Count > 0 then DropAllArtefactsOnDestruction;
            I := 0;
            while Inventory.Count > I do
            begin
              Item := TItem(Inventory[I]);
              if (Item is TUselessItem) and (Item.DestroyFlag = 0) then DropCarriedItemAsMovingLoot(Item)
              else Inc(I);
            end;
          end
          else
          begin
            Dec(Hull.HullPoints, Damage);
            EngineLoss := NextRandomIntRange(0, 2, RandomState);
            { Unlike the engine-targeting weapon mode, this path has no nil guard. }
            if EngineLoss > 0 then
              if Engine.OutputPercent > EngineLoss then Dec(Engine.OutputPercent, EngineLoss)
              else Engine.OutputPercent := 0;
            if ShipType <> t_Tranclucator then
              if OwnerId <> oiKling then
              begin
                Factor := RemapClamped(Damage, 1, Hull.Weight * 0.1, 0.05, 0.15);
                if Self is TRanger then
                begin
                  if Self = Player then Factor := Factor * DifficultyModifiers[Galaxy.Difficulty].PlayerCombatEquipmentWearFactor
                  else Factor := 0.8 * Factor;
                end
                else if Self is TWarrior then Factor := Factor * 0.5;
                DegradeEquipmentFromDamage(Factor);
              end
              else if (Self <> KlingMotherShip) and ((Cardinal(Galaxy.CurrentTurn) + RandomState) mod 4 = 0) and
                (CurrentStar.Items.Count < 25) then
              begin
                Nodes := TProtoplasm.Create;
                Nodes.Init(NextRandomIntRange(NodeReserve div 8, NodeReserve div 4, RandomState) + 1, 1);
                Inventory.Add(Nodes);
                DropCarriedItemAsMovingLoot(Nodes);
              end;
          end;
        end;
      wmEngineOutputLoss:
        begin
          Damage := 0;
          OutputLoss := NextRandomIntRange(Weapon.MinDamage, Weapon.MaxDamage, RandomState);
          if Engine <> nil then
            if OutputLoss < Engine.OutputPercent then Dec(Engine.OutputPercent, OutputLoss)
            else Engine.OutputPercent := 0;
        end;
      wmEquipmentWear:
        begin
          Damage := 0;
          if (ShipKind <> t_Tranclucator) and (OwnerId <> oiKling) then
          begin
            Factor := NextRandomFloatRange(Weapon.MinDamage, Weapon.MaxDamage, RandomState);
            if Self is TWarrior then Factor := 0.3 * Factor
            else if Self is TRanger then
              if Self = Player then Factor := Factor * DifficultyModifiers[Galaxy.Difficulty].PlayerCombatEquipmentWearFactor
              else Factor := 0.6 * Factor;
            DegradeEquipmentFromDamage(0.1 * Factor);
          end;
        end;
    end;
  DamageColor := GetOwnerDamageColor(OwnerId);
  if Damage <= 0 then DamageColor := 0;
  RefreshDerivedStats;
  Result := Damage;
  if (Self = Player) and (Hull.HullPoints < 1) then ScoreScreen.RecordPlayerResult(-1)
  else if (ScenarioState = scenNone) and (Self is TKling) and (TKling(Self).KlingType = ktMakhpella) and
    (Hull.HullPoints < 1000) and (Player <> nil) and (Player.CurrentStar = CurrentStar) then
  begin
    ScenarioState := scenMachpellaFled;
    Hole := THole.Create;
    Hole.InitializeGraphic;
    Hole.Graphic.SetState(1);
    Hole.Star1 := KlingMotherShip.CurrentStar;
    Hole.Position1.X := KlingMotherShip.Position.X - Player.Position.X;
    Hole.Position1.Y := KlingMotherShip.Position.Y - Player.Position.Y;
    Value := 1 / Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
    Hole.Position2.X := Hole.Position1.X * Value;
    Hole.Position2.Y := Hole.Position1.Y * Value;
    Hole.Position1.X := Hole.Position2.X * 200 + KlingMotherShip.Position.X;
    Hole.Position1.Y := Hole.Position2.Y * 200 + KlingMotherShip.Position.Y;
    Value := Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
    if Value < CurrentStar.SafeRadius then
    begin
      Hole.Position1.X := KlingMotherShip.Position.X - Hole.Position2.Y * 200;
      Hole.Position1.Y := Hole.Position2.X * 200 + KlingMotherShip.Position.Y;
      Value := Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
      if Value < CurrentStar.SafeRadius then
      begin
        Hole.Position1.X := Hole.Position2.Y * 200 + KlingMotherShip.Position.X;
        Hole.Position1.Y := KlingMotherShip.Position.Y - Hole.Position2.X * 200;
      end;
    end;
    Hole.Star2 := nil;
    MinimumDistance := 1E20;
    for I := 0 to Galaxy.Stars.Count - 1 do
    begin
      Value := PointDistanceSquared(KlingMotherShip.CurrentStar.Position, TStar(Galaxy.Stars[I]).Position);
      if (Value > 5) and (Value < MinimumDistance) then
      begin
        MinimumDistance := Value;
        Hole.Star2 := TStar(Galaxy.Stars[I]);
      end;
    end;
    MinimumDistance := HeadingDegreesToRadians(SeededRandomIntRange(0, 359, Galaxy.CurrentTurn));
    Value := SeededRandomIntRange(1000, 2000, Galaxy.CurrentTurn);
    Hole.Position2 := MakePointF(Sin(MinimumDistance) * Value, -Cos(MinimumDistance) * Value);
    Hole.CreatedTurn := Galaxy.CurrentTurn;
    Hole.HoleType := bhkMachpella;
    Galaxy.Holes.Add(Hole);
    if StarPreparationFlag then
    begin
      HoleFilmObject := PrimaryFilm.AddObject(Hole.Id, Hole.Graphic, 0, 0);
      PrimaryFilm.SetObjectPosition(0, HoleFilmObject, Hole.Position1);
      PrimaryFilm.SetHoleState(0, HoleFilmObject, 1);
      PrimaryFilm.AttachObject(0, HoleFilmObject);
    end;
  end;
end;
{ @end $5AE85C }

{ @routine $5AF5C4 TShip_ApplyAsteroidImpactDamage }
function TShip.ApplyAsteroidImpactDamage(Asteroid: TAsteroid; out DamageColor: Cardinal): Integer;
var Damage: Integer;
begin
  if ScriptShip <> nil then Damage := 0
  else
  begin
    Damage := Round(RemapClamped(NextRandomUnitFloat(RandomState), 0, 1, Hull.Weight div 10, Hull.Weight div 5));
    if (Self = KlingMotherShip) and (Damage >= Hull.HullPoints) then Damage := Hull.HullPoints - 1;
    if Hull.HullPoints - Damage <= 0 then
    begin
      Hull.HullPoints := 0;
      Player.ProcessShipDestructionQuests(Self);
    end
    else Dec(Hull.HullPoints, Damage);
  end;
  if Damage <= 0 then DamageColor := 0
  else DamageColor := GetOwnerDamageColor(OwnerId);
  Result := Damage;
end;
{ @end $5AF5C4 }

{ @routine $5AF6A4 TShip_CountEquippedWeapons }
function TShip.CountEquippedWeapons: TWeaponCount;
var
  I, Count: Integer;
  Item: TEquipment;
begin
  Count := 0;
  for I := 0 to Inventory.Count - 1 do
  begin
    Item := Inventory[I];
    if Item.EquippedFlag and (Item.ItemType in WeaponItemTypes) then Inc(Count);
  end;
  Result := Count;
end;
{ @end $5AF6A4 }

{ @routine $5AF6F4 TShip_GetHeaviestWeaponIndex }
function TShip.GetHeaviestWeaponIndex: Integer;
var I, MaxWeight: Integer;
begin
  Result := 0;
  MaxWeight := 0;
  for I := 1 to WeaponCount do
    if MaxWeight < Weapons[I - 1].Weight then begin
      MaxWeight := Weapons[I - 1].Weight;
      Result := I;
    end;
end;
{ @end $5AF6F4 }

{ @routine $5AF72C TShip_CountHullDamageWeapons }
function TShip.CountHullDamageWeapons: TWeaponCount;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to WeaponCount do
  begin
    if Weapons[I - 1].DealsHullDamage then Inc(Result);
  end;
end;
{ @end $5AF72C }

{ @routine $5AF760 TShip_CountSpecialDamageWeapons }
function TShip.CountSpecialDamageWeapons: TWeaponCount;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to WeaponCount do
  begin
    if Weapons[I - 1].HasSpecialDamageMode then Inc(Result);
  end;
end;
{ @end $5AF760 }

{ @routine $5AF794 TShip_GetMaxWeaponRange }
function TShip.GetMaxWeaponRange: Integer;
var I: Integer;
begin
  Result := 0;
  for I := 1 to WeaponCount do begin
    if not Weapons[I - 1].BrokenFlag and (Weapons[I - 1].Range > Result) then Result := Weapons[I - 1].Range;
  end;
end;
{ @end $5AF794 }

{ @routine $5AF7C8 TShip_ClearWeaponTargets }
procedure TShip.ClearWeaponTargets(Target: TObject);
var I: Integer;
begin
  if Target = nil then
    for I := 1 to WeaponCount do Weapons[I - 1].Target := nil
  else
    for I := 1 to WeaponCount do
      if Target = Weapons[I - 1].Target then Weapons[I - 1].Target := nil;
end;
{ @end $5AF7C8 }

{ @routine $5AF81C TShip_HasWeaponTarget }
function TShip.HasWeaponTarget(Target: TObject): Boolean;
var I: Integer;
begin
  for I := 1 to WeaponCount do
    if Target = Weapons[I - 1].Target then begin Result := True; Exit; end;
  Result := False;
end;
{ @end $5AF81C }

{ @routine $5AF84C TShip_ChanceToWin }
function TShip.ChanceToWin(OtherShip: TShip): Double;
var
  I: Integer;
  Damage, OwnDamage, TargetDamage, DefenseFactor, Armor: Double;
begin
  if (Hull.HullPoints < 1) or (OtherShip.Hull.HullPoints < 1) then
    ShowMessage('У корабля в функции ChanceToWin, hitpoints=0. Нужен ваш последний Save файл!');
  OwnDamage := 0;
  DefenseFactor := OtherShip.GetDefenseDamageFactor;
  if OtherShip.Artefacts.Count = 0 then Armor := OtherShip.Hull.Armor
  else Armor := 5 * (Ord(OtherShip.HasActiveArtefact(t_ArtefactHull))) + OtherShip.Hull.Armor;
  for I := 1 to WeaponCount do
  begin
    if not Weapons[I - 1].BrokenFlag and (WeaponInfo[Weapons[I - 1].ItemType].Mode in [wmHullDamage]) then
    begin
      Damage := Weapons[I - 1].MaxDamage * DefenseFactor - Armor;
      if Damage > 0 then OwnDamage := OwnDamage + Damage;
    end;
  end;
  if OwnDamage = 0 then
  begin
    Result := 0;
    Exit;
  end;
  TargetDamage := 0;
  DefenseFactor := GetDefenseDamageFactor;
  if Artefacts.Count = 0 then Armor := Hull.Armor
  else Armor := 5 * (Ord(HasActiveArtefact(t_ArtefactHull))) + Hull.Armor;
  for I := 1 to OtherShip.WeaponCount do
  begin
    if not OtherShip.Weapons[I - 1].BrokenFlag and (WeaponInfo[OtherShip.Weapons[I - 1].ItemType].Mode in [wmHullDamage]) then
    begin
      Damage := OtherShip.Weapons[I - 1].MaxDamage * DefenseFactor - Armor;
      if Damage > 0 then TargetDamage := TargetDamage + Damage;
    end;
  end;
  if TargetDamage = 0 then Result := 100
  else Result := (Hull.HullPoints * OwnDamage) / (OtherShip.Hull.HullPoints * TargetDamage);
end;
{ @end $5AF84C }

{ @routine $5AFAEC TShip_GetWinChancePercent }
function TShip.GetWinChancePercent(Target: TShip): TPercent;
var Value: Double;
begin
  Value := ChanceToWin(Target);
  if Value >= 1 then Result := Round(RemapClamped(Value, 1, 4, 50, 100))
  else Result := Round(RemapClamped(Value, 0, 1, 0, 50));
end;
{ @end $5AFAEC }

{ @routine $5AFB68 TShip_SetJointAttackTarget }
procedure TShip.SetJointAttackTarget(Ally, Target: TShip);
var  I: Integer; Weapon: TWeapon;
begin
  EnemyShip := Target;
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I - 1];
    if not (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Target.Position)) then Continue;
    if Weapon.BrokenFlag then Continue;
    Weapon.Target := Target;
  end;
  if Player = Self then PendingPlayerFollowTarget := Target
  else OrderFollowShip(EnemyShip, fmMinWeaponRange, True);
  Ally.EnemyShip := Target;
  for I := 1 to Ally.WeaponCount do
  begin
    Weapon := Ally.Weapons[I - 1];
    if not (Weapon.Range * Weapon.Range >= PointDistanceSquared(Ally.Position, Target.Position)) then Continue;
    if Weapon.BrokenFlag then Continue;
    Weapon.Target := Target;
  end;
  if Player = Ally then PendingPlayerFollowTarget := Target
  else Ally.OrderFollowShip(Ally.EnemyShip, fmMinWeaponRange, True);
end;
{ @end $5AFB68 }

{ @routine $5AFC8C TShip_IsEnemyPursuingSelf }
function TShip.IsEnemyPursuingSelf: Boolean;
begin
  if (EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar) or not EnemyShip.InNormalSpace then Result := False
  else Result := EnemyShip.OrderTarget = Self;
end;
{ @end $5AFC8C }

{ @routine $5AFCC4 TShip_SetStoredRangerRelationLevel }
procedure TShip.SetStoredRangerRelationLevel(Ranger: TShip; Level: TRelationLevel);
begin
  if RangerRelations.Count < 1 then Exit;
  case Level of
    rlHostile: RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(5);
    rlBad: RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(20);
    rlNormal: RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(45);
    rlGood: RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(70);
    rlExcellent: RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(90);
  else RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(5);
  end;
end;
{ @end $5AFCC4 }

{ @routine $5AFE24 TShip_GetRelationLevelToShip }
function TShip.GetRelationLevelToShip(Ship: TShip): TRelationLevel;
begin
  case RelationToNonRanger(Ship) of
    0..9: Result := rlHostile;
    10..29: Result := rlBad;
    30..59: Result := rlNormal;
    60..79: Result := rlGood;
    80..100: Result := rlExcellent;
  else Result := rlNormal;
  end;
end;
{ @end $5AFE24 }

{ @routine $5AFE64 TShip_GetRelationLevelTextToShip }
function TShip.GetRelationLevelTextToShip(Ship: TShip): WideString;
begin
  Result := RelationInfo[GetRelationLevelToShip(Ship)].DisplayName;
end;
{ @end $5AFE64 }

{ @routine $5AFE94 TShip_TryExtortShip }
function TShip.TryExtortShip(Ship: TShip): Boolean;
var Amount: Integer; Response: WideString;
begin
  if ShipType = t_Ranger then (Self as TRanger).AddPirateCareerActivity(2);
  Result := False;
  if (Ship.ShipType in [t_Ranger..t_Pirate]) and (Ship <> TruceShip) and Ship.InNormalSpace and
    (Max(GetRadarRange * GetRadarRange, 250000) >= PointDistanceSquared(Position, Ship.Position)) then begin
    if (Ship = Player) and not PlayerAutomaticControl then begin
      if ReservedMessageCounter < 7 then Exit;
      ReservedMessageCounter := 0;
      Inc(PlayerDialogueRequestCount);
      if PlayerDialogueRequestCount > 1 then Exit;
    end;
    if (CargoHook <> nil) and (CargoFreeSpace > 20) and (NextRandomUnitFloat(RandomState) > 0.4) and Ship.HasCargoGoods then begin
      if Ship.BuildCargoExtortionResponse(Self, Response) then Result := True;
      if (Player.CurrentStar = CurrentStar) and (Result or (NextRandomUnitFloat(RandomState) > 0.8)) and
        ((Ship <> Player) or PlayerAutomaticControl) then NotifyCargoDemand(Ship, Response);
    end else begin
      Amount := Round(Wealth * (1 / 30));
      if Ship.BuildMoneyExtortionResponse(Self, Response, Amount) then Result := True;
      if (Player.CurrentStar = CurrentStar) and (Result or (NextRandomUnitFloat(RandomState) > 0.8)) and
        ((Ship <> Player) or PlayerAutomaticControl) then NotifyMoneyDemand(Ship, Response, Amount);
    end;
  end;
end;
{ @end $5AFE94 }

{ @routine $5B00EC TShip_TruceWithShip }
procedure TShip.TruceWithShip(Ship: TShip);
var I: Integer; Weapon: TWeapon;
begin
  if ((Player = Ship) and (PendingPlayerFollowTarget = Self)) or
    ((Player = Self) and (PendingPlayerFollowTarget = Ship)) then PendingPlayerFollowTarget := nil;
  if EnemyShip = Ship then EnemyShip := nil;
  TruceShip := Ship;
  for I := 1 to WeaponCount do begin
    Weapon := Weapons[I - 1];
    if Weapon.Target = Ship then Weapon.Target := nil;
  end;
  if Ship.EnemyShip = Self then Ship.EnemyShip := nil;
  for I := 1 to Ship.WeaponCount do begin
    Weapon := Ship.Weapons[I - 1];
    if Weapon.Target = Self then Weapon.Target := nil;
  end;
  if Player = Ship then Player.TruceShip := Self;
  if (ShipType = t_Ranger) and (Ship.RelationToRanger(Self) < 10) then Ship.ChangeRelationToRanger(Self, 10);
  if Ship.ShipType = t_Ranger then ChangeRelationToRanger(Ship, 30);
  if (Order = soFollowShip) and ((OrderTarget as TShip) = Ship) then begin
    OrderNone;
    if Player <> Self then NextDay;
  end;
  if (Ship.Order = soFollowShip) and ((Ship.OrderTarget as TShip) = Self) then begin
    Ship.OrderNone;
    if Player <> Ship then Ship.NextDay;
  end;
end;
{ @end $5B00EC }

{ @routine $5B024C TShip_RequestAlliesAttackShip }
procedure TShip.RequestAlliesAttackShip(Target: TShip);
var I, Requests, RangeSquared: Integer; Other: TShip; Response: WideString;
begin
  if Target.InNormalSpace then
    if Max(GetRadarRange * GetRadarRange, 250000) >= PointDistanceSquared(Position, Target.Position) then
    begin
      RangeSquared := Max(GetRadarRange * GetRadarRange, 250000);
      if ShipType = t_Ranger then (Self as TRanger).AddWarriorCareerActivity(1);
      Requests := 0;
      for I := 0 to CurrentStar.Ships.Count - 1 do
      begin
        Other := TShip(CurrentStar.Ships[I]);
        if (Other <> Self) and (Other <> Target) and Other.InNormalSpace and
          not (Other.ShipType in NonNegotiatingShipTypes) and (Other.OrderTarget <> Target) then
          if ((Other.EnemyShip = nil) or (Other.EnemyShip.CurrentStar <> CurrentStar)) then
            if (Other.GetRelationLevelToShip(Self) >= rlGood) and (Other.GetRelationLevelToShip(Target) <= rlNormal) and
              (RangeSquared >= PointDistanceSquared(Position, Other.Position)) and
              (NextRandomUnitFloat(RandomState) <= 0.9) then
            begin
              if (Other = Player) and not PlayerAutomaticControl then
              begin
                if ReservedMessageCounter < 7 then Continue;
                ReservedMessageCounter := 0;
                Inc(PlayerDialogueRequestCount);
                if PlayerDialogueRequestCount > 1 then Continue;
              end;
              if (Other.BuildAttackRequestResponse(Self, Response, Target) or
                (NextRandomUnitFloat(RandomState) > 0.8)) and
                (Player.CurrentStar = CurrentStar) and ((Other <> Player) or PlayerAutomaticControl) then
              begin
                NotifyAttackRequest(Other, Response, Target);
                Break;
              end;
              Inc(Requests);
              if Requests = 2 then Break;
            end;
      end;
    end;
end;
{ @end $5B024C }

{ @routine $5B04D4 TShip_IsInPrison }
function TShip.IsInPrison: Boolean;
begin
  case ShipType of
    t_Ranger: if (Self as TRanger).PrisonTermRemaining > 0 then begin Result := True; Exit; end;
    t_Pirate: if (Self as TPirate).PrisonTermRemaining > 0 then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5B04D4 }

{ @routine $5B051C TShip_GetLocationGoodsEntry }
function TShip.GetLocationGoodsEntry(Good: TGoodsIndex): PPlanetGoodsEntry;
begin
  if IsOnPlanet then Result := @CurrentPlanet.Goods[Good]
  else if (DockedTo <> nil) and (DockedTo is TRuins) then
    Result := @TRuins(DockedTo).Goods[Good]
  else raise Exception.Create('Error in TShip.ShopGoods');
end;
{ @end $5B051C }

{ @routine $5B05A8 TShip_GetAverageCargoCost }
function TShip.GetAverageCargoCost(Good: TGoodsIndex): Double;
begin
  if CargoGoods[Good].Count > 0 then Result := CargoGoods[Good].TotalCost / CargoGoods[Good].Count
  else Result := 0;
end;
{ @end $5B05A8 }

{ @routine $5B05D8 TShip_ConsumeCargoGoods }
procedure TShip.ConsumeCargoGoods(Good: TGoodsIndex; Count: Integer);
begin
  if CargoGoods[Good].Count = Count then
  begin
    CargoGoods[Good].Count := 0;
    CargoGoods[Good].TotalCost := 0;
  end
  else
  begin
    Dec(CargoGoods[Good].TotalCost, Round(GetAverageCargoCost(Good) * Count));
    Dec(CargoGoods[Good].Count, Count);
  end;
end;
{ @end $5B05D8 }

{ @routine $5B0620 TShip_SellGoodsToLocation }
procedure TShip.SellGoodsToLocation(Good: TGoodsIndex; Count: Integer);
begin
  if Count > CargoGoods[Good].Count then
    raise Exception.Create('Error in SaleCurrProduct')
  else begin
    Inc(GetLocationGoodsEntry(Good).Count, Count);
    SetMoney(Money + GetLocationGoodsEntry(Good).BaseSalePrice * Count);
    ConsumeCargoGoods(Good, Count);
  end;
  if (Self is TRanger) and (CurrentPlanet <> nil) then begin
    if not PlanetRaceMarket[CurrentPlanet.RaceId].Goods[Good].Legal then
      (Self as TRanger).ApplyIllegalGoodsTradeRelationsPenalty(GetLocationGoodsEntry(Good).BaseSalePrice * Count);
    if Player <> Self then (Self as TRanger).AddTraderCareerActivity(2);
  end;
  RefreshDerivedStats;
end;
{ @end $5B0620 }

{ @routine $5B0724 TShip_BuyGoodsFromLocation }
procedure TShip.BuyGoodsFromLocation(Good: TGoodsIndex; Count: Integer);
begin
  if (Count > GetLocationGoodsEntry(Good).Count) or
    (GetLocationGoodsEntry(Good).PurchasePrice * Count > Money) then
    ShowMessage('Не верные параметры покупки')
  else begin
    Dec(GetLocationGoodsEntry(Good).Count, Count);
    SetMoney(Money - GetLocationGoodsEntry(Good).PurchasePrice * Count);
    Inc(CargoGoods[Good].Count, Count);
    Inc(CargoGoods[Good].TotalCost, GetLocationGoodsEntry(Good).PurchasePrice * Count);
  end;
  // Native continues with career/reputation and refresh even after the message.
  if (Self is TRanger) and (CurrentPlanet <> nil) then begin
    if not PlanetRaceMarket[CurrentPlanet.RaceId].Goods[Good].Legal then
      (Self as TRanger).ApplyIllegalGoodsTradeRelationsPenalty(GetLocationGoodsEntry(Good).PurchasePrice * Count);
    if Player = Self then Player.AddTraderCareerActivity(2)
    else (Self as TRanger).AddTraderCareerActivity(8);
  end;
  RefreshDerivedStats;
end;
{ @end $5B0724 }

{ @routine $5B0854 TShip_ProcessLiberationGroupRoute }
procedure TShip.ProcessLiberationGroupRoute;
var GroupOrder: TGroupRouteOrder; Point: TPointF;
begin
  if LiberationGroup <> nil then begin
    GroupOrder := (LiberationGroup as TGroup).Route[LiberationGroupRouteIndex];
    case GroupOrder.Kind of
      soJump: if not IsOutsideStarSpace and (Order = soNone) then begin
        if GroupOrder.Target = CurrentStar then begin
          Inc(LiberationGroupRouteIndex);
          if LiberationGroupRouteIndex >= Length((LiberationGroup as TGroup).Route) then LeaveLiberationGroup;
          ProcessLiberationGroupRoute;
        end else OrderJump(GroupOrder.Target as TStar, False);
      end;
      soLanding: if CurrentPlanet = GroupOrder.Target then begin
        Inc(LiberationGroupRouteIndex);
        if LiberationGroupRouteIndex >= Length((LiberationGroup as TGroup).Route) then LeaveLiberationGroup;
      end else if not IsOutsideStarSpace and (Order = soNone) then begin
        if (GroupOrder.Target as TPlanet).CurrentStar <> CurrentStar then
          ShowMessage('FCurStar<>(GroupOrder.FOrderObj as TPlanet).FStar')
        else OrderLanding(GroupOrder.Target, False);
      end;
      soMove: if not IsOutsideStarSpace then begin
        if (PointDistance(Position, GroupOrder.Destination) < 300) and (GroupOrder.WaitMode in [0]) then begin
          Inc(LiberationGroupRouteIndex);
          if LiberationGroupRouteIndex >= Length((LiberationGroup as TGroup).Route) then LeaveLiberationGroup;
        end else if (GroupOrder.WaitMode in [2]) and (LiberationGroup as TGroup).AreShipsAssembled then
          (LiberationGroup as TGroup).AdvanceRouteForShips
        else begin
          Point.X := NextRandomFloatRange(-100, 100, RandomState) + GroupOrder.Destination.X;
          Point.Y := NextRandomFloatRange(-100, 100, RandomState) + GroupOrder.Destination.Y;
          OrderMove(Point, False);
        end;
      end;
    end;
  end;
end;
{ @end $5B0854 }

{ @routine $5B0AF0 TShip_LeaveLiberationGroup }
procedure TShip.LeaveLiberationGroup;
begin
  (LiberationGroup as TGroup).Ships.Delete((LiberationGroup as TGroup).Ships.IndexOf(Self));
  LiberationGroup := nil;
  LiberationGroupRouteIndex := 0;
end;
{ @end $5B0AF0 }

{ @routine $5B0B40 CompareShipGroupsStrength }
function CompareShipGroupsStrength(Ships, Opponents: TList): Single;
var I, J, ShipCount, Count: Integer; Ship, Target: TShip; Sum, Chance: Single;
begin
  ShipCount := Ships.Count;
  Count := Opponents.Count;
  Result := 0;
  for I := 0 to ShipCount - 1 do begin
    Ship := TShip(Ships[I]);
    Sum := 0;
    for J := 0 to Count - 1 do begin
      Target := TShip(Opponents[J]);
      Chance := Ship.ChanceToWin(Target);
      Sum := Sum + Chance;
    end;
    Result := Sum / Count / Count + Result;
  end;
end;
{ @end $5B0B40 }

{ @routine $5B0BF0 CreateShipByType }
function CreateShipByType(Kind: TShipType): TShip;
begin
  Result := nil;
  if Kind = t_Ranger then Result := TRanger.Create
  else if Kind = t_Kling then Result := TKling.Create
  else if Kind = t_Transport then Result := TTransport.Create
  else if Kind = t_Pirate then Result := TPirate.Create
  else if Kind = t_Warrior then Result := TWarrior.Create
  else if Kind = t_Tranclucator then Result := TTranclucator.Create
  else if Kind = t_RangerCenter then Result := TRC.Create
  else if Kind = t_PirateBase then Result := TPB.Create
  else if Kind = t_MilitaryBase then Result := TWB.Create
  else if Kind = t_ScientificBase then Result := TSB.Create
  else Exception.Create('Error'); // Native constructs the exception without raising it.
end;
{ @end $5B0BF0 }

{ @routine $5B0CEC TShip_EquipItemDirect }
procedure TShip.EquipItemDirect(Item: TEquipment);
begin
  Item.Equip;
  case Item.ItemType of
    t_Hull: Hull := Item as THull;
    t_FuelTanks: FuelTanks := Item as TFuelTanks;
    t_Engine: Engine := Item as TEngine;
    t_Radar: Radar := Item as TRadar;
    t_Scaner: Scanner := Item as TScaner;
    t_RepairRobot: RepairRobot := Item as TRepairRobot;
    t_CargoHook: CargoHook := Item as TCargoHook;
    t_DefGenerator: DefGenerator := Item as TDefGenerator;
    t_PhotonGun..t_EyesOfMachpella: begin
      Inc(WeaponCount);
      Weapons[WeaponCount - 1] := Item as TWeapon;
    end;
  end;
end;
{ @end $5B0CEC }

{ @routine $5B0E2C TShip_UnequipSlot }
procedure TShip.UnequipSlot(ItemType: TItemType; WeaponIndex: Integer);
var
  I: Integer;
begin
  case ItemType of
    t_FuelTanks: begin FuelTanks.Unequip; FuelTanks := nil; end;
    t_Engine: begin Engine.Unequip; Engine := nil; end;
    t_Radar: begin Radar.Unequip; Radar := nil; end;
    t_Scaner: begin Scanner.Unequip; Scanner := nil; end;
    t_RepairRobot: begin RepairRobot.Unequip; RepairRobot := nil; end;
    t_CargoHook: begin CargoHook.Unequip; CargoHook := nil; end;
    t_DefGenerator: begin DefGenerator.Unequip; DefGenerator := nil; end;
    t_PhotonGun..t_EyesOfMachpella:
      begin
        Weapons[WeaponIndex - 1].Unequip;
        Weapons[WeaponIndex - 1] := nil;
        if WeaponIndex < WeaponCount then
        begin
          { Native repeats the same copy instead of advancing the slot index. }
          for I := WeaponIndex to WeaponCount - 1 do
            Weapons[WeaponIndex - 1] := Weapons[WeaponIndex];
          Weapons[WeaponCount - 1] := nil;
        end;
        Dec(WeaponCount);
      end;
  end;
end;
{ @end $5B0E2C }

{ @routine $5B0F78 TShip_EquipItem }
procedure TShip.EquipItem(Item: TEquipment);
begin
  case Item.ItemType of
    t_FuelTanks: begin
      if FuelTanks <> nil then UnequipSlot(t_FuelTanks, 0);
      EquipItemDirect(Item);
    end;
    t_Engine: begin
      if Engine <> nil then UnequipSlot(t_Engine, 0);
      EquipItemDirect(Item);
    end;
    t_Radar: begin
      if Radar <> nil then UnequipSlot(t_Radar, 0);
      EquipItemDirect(Item);
    end;
    t_Scaner: begin
      if Scanner <> nil then UnequipSlot(t_Scaner, 0);
      EquipItemDirect(Item);
    end;
    t_RepairRobot: begin
      if RepairRobot <> nil then UnequipSlot(t_RepairRobot, 0);
      EquipItemDirect(Item);
    end;
    t_CargoHook: begin
      if CargoHook <> nil then UnequipSlot(t_CargoHook, 0);
      EquipItemDirect(Item);
    end;
    t_DefGenerator: begin
      if DefGenerator <> nil then UnequipSlot(t_DefGenerator, 0);
      EquipItemDirect(Item);
    end;
  end;
end;
{ @end $5B0F78 }

{ @routine $5B1094 TShip_GetEffectiveMass }
function TShip.GetEffectiveMass: Integer;
begin
  Result := 2 * Hull.Weight - CargoFreeSpace;
  if (Artefacts.Count > 0) and HasActiveArtefact(t_ArtefactAntigrav) then Result := Round(Result * 0.75);
end;
{ @end $5B1094 }

{ @routine $5B10E0 TShip_GetHullIntegrityPercent }
function TShip.GetHullIntegrityPercent: Byte;
begin
  Result := Round(Hull.HullPoints / Hull.Weight * 100);
end;
{ @end $5B10E0 }

{ @routine $5B1104 TShip_GetJumpDestinationDistance }
function TShip.GetJumpDestinationDistance: Integer;
begin
  if Order = soJump then Result := Trunc(PointDistance(CurrentStar.Position, (OrderTarget as TStar).Position))
  else Result := 0;
end;
{ @end $5B1104 }

{ @routine $5B113C TShip_GetFullRefuelCost }
function TShip.GetFullRefuelCost: Integer;
var Cost: Single; MissingFuel: Integer;
begin
  if FuelTanks <> nil then
  begin
    MissingFuel := FuelTanks.Capacity - FuelTanks.Fuel;
    Cost := MissingFuel;
    Cost := Cost * RemapClamped(Galaxy.CurrentTurn, 1000, 15000, 1, 10);
    if CurrentPlanet <> nil then Cost := Cost * OwnerInfo[CurrentPlanet.OwnerId].FuelPriceFactor;
    Cost := Cost * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor;
    Result := Round(Cost);
  end
  else Result := 0;
end;
{ @end $5B113C }

{ @routine $5B11F4 TShip_CalculateSpeed }
function TShip.CalculateSpeed: Integer;
var MassFactor, OutputFactor: Double;
begin
  if (Engine <> nil) and (FuelTanks <> nil) and (CargoFreeSpace >= 0) then begin
    MassFactor := RemapClampedAlternate(GetEffectiveMass, MinimumShipMass, MaximumShipMass, 1, 0.333);
    if Engine.OutputPercent = 100 then OutputFactor := 1
    else OutputFactor := RemapClamped(Engine.OutputPercent, 0, 100, 0.5, 1);
    Result := Round(Engine.Speed * MassFactor * OutputFactor);
    if Engine.BrokenFlag then Result := Result div 2;
    if (Artefacts.Count > 0) and HasActiveArtefact(t_ArtefactSpeed) then Result := Round(Result * 1.2);
  end else Result := 0;
end;
{ @end $5B11F4 }

{ @routine $5B1330 TShip_GetFuelLimitedJumpRange }
function TShip.GetFuelLimitedJumpRange: Byte;
begin
  if (FuelTanks = nil) or (Engine = nil) then begin Result := 0; Exit; end;
  Result := Min(FuelTanks.Fuel, Engine.JumpRange);
end;
{ @end $5B1330 }

{ @routine $5B1364 TShip_GetRadarRange }
function TShip.GetRadarRange: Integer;
begin
  if (Radar = nil) or Radar.BrokenFlag then Result := 0
  else begin
    Result := Radar.Range;
    if (Artefacts.Count > 0) and HasActiveArtefact(t_ArtefactRadar) then Result := Radar.Range + 600;
  end;
end;
{ @end $5B1364 }

{ @routine $5B13AC TShip_CanResolveObjectWithScanner }
function TShip.CanResolveObjectWithScanner(Target: TObject): Boolean;
begin
  if (Scanner = nil) or Scanner.BrokenFlag then begin Result := False; Exit; end;
  if Target is TShip then
    Result := 10 * (Ord(HasActiveArtefact(t_ArtefactScaner))) + Scanner.ScanPower >=
      ((Target as TShip).GetDefensePercent)
  else Result := True;
end;
{ @end $5B13AC }

{ @routine $5B141C TShip_RepairHullWithRobot }
procedure TShip.RepairHullWithRobot;
begin
  if (RepairRobot <> nil) and not RepairRobot.BrokenFlag then begin
    Inc(Hull.HullPoints, Min(RepairRobot.RepairPoints, Hull.Weight - Hull.HullPoints));
    if ShipType <> t_Kling then ApplyItemDegradation(RepairRobot, idkUse, NextRandomUnitFloat(RandomState) * 2);
  end;
end;
{ @end $5B141C }

{ @routine $5B1488 TShip_GetCargoHookRange }
function TShip.GetCargoHookRange: Integer;
begin
  Result := 150;
end;
{ @end $5B1488 }

{ @routine $5B1490 TShip_GetBaseCargoHookPower }
function TShip.GetBaseCargoHookPower: Integer;
begin
  if CargoHook <> nil then Result := CargoHook.PickupPower
  else Result := 0;
end;
{ @end $5B1490 }

{ @routine $5B14A4 TShip_GetDefenseDamageFactor }
function TShip.GetDefenseDamageFactor: Double;
begin
  if (DefGenerator = nil) or DefGenerator.BrokenFlag then Result := 1
  else begin
    Result := DefGenerator.DamageFactor;
    if (Artefacts.Count > 0) and HasActiveArtefact(t_ArtefactDef) then Result := Result - 0.05;
  end;
end;
{ @end $5B14A4 }

{ @routine $5B150C TShip_GetDefensePercent }
function TShip.GetDefensePercent: TPercent;
begin
  Result := DefenseDamageFactorToPercent(GetDefenseDamageFactor);
end;
{ @end $5B150C }

{ @routine $5B1524 TShip_RefreshDerivedStats }
procedure TShip.RefreshDerivedStats;
begin
  RebuildEquipmentCache;
  CargoFreeSpace := GetCargoFreeSpace;
  Speed := CalculateSpeed;
  JumpRange := GetFuelLimitedJumpRange;
  DefenseDamageFactor := GetDefenseDamageFactor;
  CalculateStrength;
  CalculateWealth;
  UpdateBestRangerRelativeRatings;
  UpdateAverageRangerRelativeStrength;
  if Engine <> nil then begin
    MovementTurnRate := RemapClamped(Speed, EngineSpeedByLevel[1] / 2, EngineSpeedByLevel[8], 1, 5);
    MovementTurnRatePerTurn := MovementTurnRate * 200 * 0.1;
    MovementSpeed := Speed * 0.005;
    MovementSpeedPerTurn := MovementSpeed * 200 * 0.1;
  end else begin
    MovementSpeed := 0;
    MovementSpeedPerTurn := 0;
  end;
  DerivedStateCompatibilityHook;
end;
{ @end $5B1524 }

{ @routine $5B1684 TShip_RefreshGraphicSize }
procedure TShip.RefreshGraphicSize;
var
  Size, Small, Large: Integer;
begin
  case ShipType of
    t_Kling: case (Self as TKling).KlingType of
      ktMakhpella: begin Small := 127; Large := 127; end;
      ktEgemon: begin Small := 80; Large := 120; end;
      ktNondus: begin Small := 70; Large := 100; end;
      ktKatauri: begin Small := 50; Large := 60; end;
      ktRoggit: begin Small := 35; Large := 55; end;
      ktMutenok: begin Small := 40; Large := 50; end;
    else Small := 50; Large := 128;
    end;
    t_Ranger: case OwnerId of
      oiMaloc: begin Small := 45; Large := 65; end;
      oiPeleng: begin Small := 45; Large := 60; end;
      oiPeople: begin Small := 45; Large := 65; end;
      oiFei: begin Small := 45; Large := 65; end;
      oiGaal: begin Small := 43; Large := 60; end;
    else Small := 50; Large := 128;
    end;
    t_Transport: case (Self as TTransport).TransportType of
      ttTransport: case OwnerId of
        oiMaloc: begin Small := 50; Large := 80; end;
        oiPeleng: begin Small := 50; Large := 80; end;
        oiPeople: begin Small := 50; Large := 80; end;
        oiFei: begin Small := 50; Large := 80; end;
        oiGaal: begin Small := 50; Large := 80; end;
      else Small := 50; Large := 128;
      end;
      ttLiner: case OwnerId of
        oiMaloc: begin Small := 40; Large := 80; end;
        oiPeleng: begin Small := 50; Large := 80; end;
        oiPeople: begin Small := 50; Large := 80; end;
        oiFei: begin Small := 50; Large := 80; end;
        oiGaal: begin Small := 50; Large := 80; end;
      else Small := 50; Large := 128;
      end;
      ttDiplomat: case OwnerId of
        oiMaloc: begin Small := 40; Large := 60; end;
        oiPeleng: begin Small := 40; Large := 60; end;
        oiPeople: begin Small := 40; Large := 60; end;
        oiFei: begin Small := 40; Large := 60; end;
        oiGaal: begin Small := 40; Large := 60; end;
      else Small := 50; Large := 128;
      end;
    else Small := 50; Large := 128;
    end;
    t_Pirate: case OwnerId of
      oiMaloc: begin Small := 40; Large := 60; end;
      oiPeleng: begin Small := 40; Large := 60; end;
      oiPeople: begin Small := 40; Large := 60; end;
      oiFei: begin Small := 40; Large := 70; end;
      oiGaal: begin Small := 40; Large := 70; end;
    else Small := 50; Large := 128;
    end;
    t_Warrior: case OwnerId of
      oiMaloc: begin Small := 35; Large := 70; end;
      oiPeleng: begin Small := 35; Large := 70; end;
      oiPeople: begin Small := 35; Large := 70; end;
      oiFei: begin Small := 40; Large := 70; end;
      oiGaal: begin Small := 35; Large := 70; end;
    else Small := 50; Large := 128;
    end;
    t_Tranclucator: begin Small := 40; Large := 50; end;
    t_RangerCenter: begin Small := 128; Large := 128; end;
    t_PirateBase: begin Small := 128; Large := 128; end;
    t_MilitaryBase: begin Small := 128; Large := 128; end;
    t_ScientificBase: begin Small := 128; Large := 128; end;
  else Small := 50; Large := 128;
  end;
  Size := Round(RemapClamped(Hull.Weight, 500 * ItemSizeFactors[5], 500 * ItemSizeFactors[1], Small, Large));
  if GiResourceVariant = 1 then Size := Round(Size * 0.78125);
  TShip2SE(Graphic).SetSize(Classes.Point(Size, Size));
end;
{ @end $5B1684 }

{ @routine $5B1B80 TShip_RebuildEquipmentCache }
procedure TShip.RebuildEquipmentCache;
var I: Integer; Item: TEquipment;
begin
  Hull := THull(Inventory[0]);
  FuelTanks := nil;
  Engine := nil;
  Radar := nil;
  Scanner := nil;
  RepairRobot := nil;
  CargoHook := nil;
  DefGenerator := nil;
  for I := 1 to 5 do Weapons[I - 1] := nil;
  WeaponCount := 0;
  UsableWeaponCount := 0;
  HasInactiveDirectEquipment := False;
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TEquipment(Inventory[I]);
    if Item.EquippedFlag then
    begin
      case Item.ItemType of
        t_FuelTanks: FuelTanks := Item as TFuelTanks;
        t_Engine: Engine := Item as TEngine;
        t_Radar: Radar := Item as TRadar;
        t_Scaner: Scanner := Item as TScaner;
        t_RepairRobot: RepairRobot := Item as TRepairRobot;
        t_CargoHook: CargoHook := Item as TCargoHook;
        t_DefGenerator: DefGenerator := Item as TDefGenerator;
        t_PhotonGun..t_EyesOfMachpella:
          begin
            Inc(WeaponCount);
            Weapons[WeaponCount - 1] := Item as TWeapon;
            if not Weapons[WeaponCount - 1].BrokenFlag then Inc(UsableWeaponCount);
          end;
      end;
    end
    else if Item.ItemType in DirectEquipmentTypes then HasInactiveDirectEquipment := True;
  end;
end;
{ @end $5B1B80 }

{ @routine $5B1D8C TShip_CalculateUsedCargoSpace }
function TShip.CalculateUsedCargoSpace: Integer;
var I: Integer; Good: TGoodsIndex;
begin
  Result := 0;
  for I := 1 to Inventory.Count - 1 do Inc(Result, TItem(Inventory[I]).Weight);
  for I := 0 to Artefacts.Count - 1 do Inc(Result, TItem(Artefacts[I]).Weight);
  for Good := t_Food to t_Narcotics do Inc(Result, CargoGoods[Good].Count);
end;
{ @end $5B1D8C }

{ @routine $5B1DF8 TShip_GetCargoFreeSpace }
function TShip.GetCargoFreeSpace: Integer;
begin
  Result := Hull.Weight - CalculateUsedCargoSpace;
end;
{ @end $5B1DF8 }

{ @routine $5B1E14 TShip_GetCarriedItemWeight }
function TShip.GetCarriedItemWeight: Integer;
var Item: TItem; I, Weight: Integer;
begin
  Weight := 0;
  for I := 1 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    Inc(Weight, Item.Weight);
  end;
  Result := Weight;
end;
{ @end $5B1E14 }

{ @routine $5B1E4C TShip_GetCargoGoodsWeight }
function TShip.GetCargoGoodsWeight: Integer;
var Good: TGoodsIndex;
begin
  Result := 0;
  for Good := t_Food to t_Narcotics do Inc(Result, CargoGoods[Good].Count);
end;
{ @end $5B1E4C }

{ @routine $5B1E64 TShip_CalculateFollowRadius }
function TShip.CalculateFollowRadius: Integer;
const NoWeaponRange = 999999;
var Mode: TFollowMode; Target: TShip; I: Integer; Weapon: TWeapon;
begin
  if Order <> soFollowShip then raise Exception.Create('TShip.CalcFollowRadius()');
  Target := OrderTarget as TShip;
  WriteByteValue(Byte(OrderStateData), Mode);
  case Mode of
    fmMinWeaponRange: begin
      Result := NoWeaponRange;
      for I := 1 to WeaponCount do
      begin
        Weapon := Weapons[I - 1];
        if not Weapon.BrokenFlag and (WeaponInfo[Weapon.ItemType].Mode = wmHullDamage) and
          (Result > Weapon.Range) then Result := Weapon.Range;
      end;
    end;
    fmMaxWeaponRange: begin
      Result := 0;
      for I := 1 to WeaponCount do
      begin
        Weapon := Weapons[I - 1];
        if not Weapon.BrokenFlag and (WeaponInfo[Weapon.ItemType].Mode = wmHullDamage) and
          (Result < Weapon.Range) then Result := Weapon.Range;
      end;
    end;
  else Result := NoWeaponRange;
  end;
  if (Result > 0) and (Result < NoWeaponRange) then Result := Round(Result * 0.85)
  else Result := Trunc(CollisionRadius + Target.CollisionRadius) + 15;
end;
{ @end $5B1E64 }

{ @routine $5B1FD8 TShip_GetFollowMode }
function TShip.GetFollowMode: TFollowMode;
begin
  if Order <> soFollowShip then raise Exception.Create('TShip.CalcFollowRadius()');
  WriteByteValue(Byte(OrderStateData), Result);
end;
{ @end $5B1FD8 }

{ @routine $5B2030 TShip_GetEffectiveFollowMode }
function TShip.GetEffectiveFollowMode: TFollowMode;
var Mode: TFollowMode; BoundarySquared, DistanceSquared, TargetDistanceSquared: Single;
begin
  if Order <> soFollowShip then raise Exception.Create('TShip.GetRealFollowType()');
  WriteByteValue(Byte(OrderStateData), Mode);
  if (Mode <> fmNear) and (WeaponCount > 0) then
  begin
  Result := Mode;
  if (Player <> Self) and (SeededRandomIntRange(0, 6, FollowModeSeed + Galaxy.CurrentTurn) = 0) then begin Result := fmNear; Exit; end;
  BoundarySquared := Sqr(CurrentStar.MapDiameter / 2);
  DistanceSquared := Sqr(Position.X) + Sqr(Position.Y);
  TargetDistanceSquared := Sqr(TShip(OrderTarget).Position.X) + Sqr(TShip(OrderTarget).Position.Y);
  if (DistanceSquared > BoundarySquared) and (TargetDistanceSquared > DistanceSquared) then begin Result := fmNear; Exit; end;
  end
  else Result := fmNear;
end;
{ @end $5B2030 }

{ @routine $5B214C TShip_CountMatchingInventoryEquipment }
function TShip.CountMatchingInventoryEquipment(ItemType: TItemType): Integer;
var
  I: Integer;
  Item: TItem;
begin
  Result := 0;
  if ItemType in SlottedEquipmentTypes then
    for I := 1 to Inventory.Count - 1 do
    begin
      Item := TItem(Inventory[I]);
      if (ItemType = Item.ItemType) or
        ((ItemType in WeaponItemTypes) and (Item.ItemType in WeaponItemTypes)) then Inc(Result);
    end;
end;
{ @end $5B214C }

{ @routine $5B21D0 TShip_SelectBestUnequippedWeapon }
function TShip.SelectBestUnequippedWeapon(PreferHullDamage: Boolean): TWeapon;
var
  I: Integer;
  Item: TEquipment;
  Weapon: TWeapon;
begin
  Result := nil;
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TEquipment(Inventory[I]);
    if (Item.ItemType in WeaponItemTypes) and not Item.EquippedFlag then
    begin
      if Result = nil then Result := Item as TWeapon
      else
      begin
        Weapon := Item as TWeapon;
        if PreferHullDamage then
        begin
          if (WeaponInfo[Weapon.ItemType].Mode <> wmHullDamage) and
            (WeaponInfo[Result.ItemType].Mode = wmHullDamage) then Continue
          else if (WeaponInfo[Weapon.ItemType].Mode = wmHullDamage) and
            (WeaponInfo[Result.ItemType].Mode <> wmHullDamage) then
          begin
            Result := Weapon;
            Continue;
          end;
        end;
        if (WeaponInfo[Weapon.ItemType].Mode = wmHullDamage) and
          (WeaponInfo[Result.ItemType].Mode = wmHullDamage) then
        begin
          if Result.Cost * Result.MaxDamage < Weapon.Cost * Weapon.MaxDamage then Result := Weapon;
        end
        else if Result.Cost < Weapon.Cost then Result := Weapon;
      end;
    end;
  end;
end;
{ @end $5B21D0 }

{ @routine $5B2344 TShip_HasLooseNonScriptItemsOrGoods }
function TShip.HasLooseNonScriptItemsOrGoods: Boolean;
var I: Integer; Item: TEquipment;
begin
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TEquipment(Inventory[I]);
    if not Item.EquippedFlag and (Item.ScriptItem = nil) then begin Result := True; Exit; end;
  end;
  if HasCargoGoods then begin Result := True; Exit; end;
  for I := 0 to Artefacts.Count - 1 do
  begin
    Item := TEquipment(Artefacts[I]);
    if not Item.EquippedFlag and (Item.ScriptItem = nil) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5B2344 }

{ @routine $5B23C4 TShip_DropUnequippedItemsAndGoods }
procedure TShip.DropUnequippedItemsAndGoods;
var I: Integer; Item: TEquipment;
begin
  for I := Inventory.Count - 1 downto 1 do
  begin
    Item := TEquipment(Inventory[I * 1]);
    if not Item.EquippedFlag and (Item.ScriptItem = nil) then DropCarriedItemAsMovingLoot(Item);
  end;
  if HasCargoGoods then DropAllCargoGoods;
  for I := Artefacts.Count - 1 downto 0 do
  begin
    Item := TEquipment(Artefacts[I * 1]);
    if not Item.EquippedFlag and (Item.ScriptItem = nil) then DropCarriedArtefactAsMovingLoot(Item);
  end;
end;
{ @end $5B23C4 }

{ @routine $5B244C TShip_RefreshEquipmentSlots }
procedure TShip.RefreshEquipmentSlots;
var
  I: Integer;
  Item: TItem;
begin
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TItem(Inventory[I]);
    TEquipment(Item).Unequip;
  end;
  FuelTanks := nil;
  Engine := nil;
  Radar := nil;
  Scanner := nil;
  RepairRobot := nil;
  CargoHook := nil;
  DefGenerator := nil;
  for I := 1 to 5 do Weapons[I - 1] := nil;
  WeaponCount := 0;
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TItem(Inventory[I]);
    case Item.ItemType of
      t_FuelTanks:
        if FuelTanks = nil then EquipItemDirect(Item as TFuelTanks)
        else if (Item.Cost > FuelTanks.Cost) and
          (GetJumpDestinationDistance <= (Item as TFuelTanks).Fuel) then
        begin
          UnequipSlot(FuelTanks.ItemType, 0);
          EquipItemDirect(Item as TFuelTanks);
        end;
      t_Engine:
        if Engine = nil then EquipItemDirect(Item as TEngine)
        else if Hull.Weight > 500 then
        begin
          if (Item as TEngine).Speed > Engine.Speed then
          begin
            UnequipSlot(Engine.ItemType, 0);
            EquipItemDirect(Item as TEngine);
          end;
        end
        else if Item.Cost > Engine.Cost then
        begin
          UnequipSlot(Engine.ItemType, 0);
          EquipItemDirect(Item as TEngine);
        end;
      t_Radar:
        if Radar = nil then EquipItemDirect(Item as TRadar)
        else if Item.Cost > Radar.Cost then
        begin
          UnequipSlot(Radar.ItemType, 0);
          EquipItemDirect(Item as TRadar);
        end;
      t_Scaner:
        if Scanner = nil then EquipItemDirect(Item as TScaner)
        else if Item.Cost > Scanner.Cost then
        begin
          UnequipSlot(Scanner.ItemType, 0);
          EquipItemDirect(Item as TScaner);
        end;
      t_RepairRobot:
        if RepairRobot = nil then EquipItemDirect(Item as TRepairRobot)
        else if Item.Cost > RepairRobot.Cost then
        begin
          UnequipSlot(RepairRobot.ItemType, 0);
          EquipItemDirect(Item as TRepairRobot);
        end;
      t_CargoHook:
        if CargoHook = nil then EquipItemDirect(Item as TCargoHook)
        else if Item.Cost > CargoHook.Cost then
        begin
          UnequipSlot(CargoHook.ItemType, 0);
          EquipItemDirect(Item as TCargoHook);
        end;
      t_DefGenerator:
        if DefGenerator = nil then EquipItemDirect(Item as TDefGenerator)
        else if Item.Cost > DefGenerator.Cost then
        begin
          UnequipSlot(DefGenerator.ItemType, 0);
          EquipItemDirect(Item as TDefGenerator);
        end;
      t_PhotonGun..t_EyesOfMachpella: if WeaponCount < 5 then EquipItemDirect(Item as TWeapon);
    end;
  end;
  if (WeaponCount = 5) and (CountMatchingInventoryEquipment(WeaponCategoryItemType) > 5) then
  begin
    for I := 5 downto 1 do
    begin
      Weapons[I - 1].Unequip;
      Weapons[I - 1] := nil;
    end;
    WeaponCount := 0;
    for I := 1 to 5 do
      if I < 4 then EquipItemDirect(SelectBestUnequippedWeapon(True))
      else EquipItemDirect(SelectBestUnequippedWeapon(False));
  end;
  RefreshDerivedStats;
  DropExcessCargo;
end;
{ @end $5B244C }

{ @routine $5B28E8 TShip_DropExcessCargo }
procedure TShip.DropExcessCargo;
type
  PItemMask = ^TItemTypeMask;
var
  Item: TEquipment;
  Artefact: TArtefact;
  ItemValue, ArtefactValue, GoodsValue: Double;
  Good: TGoodsIndex;
  Count: Integer;
  Mask: PItemMask;
begin
  while CargoFreeSpace < 0 do
  begin
    Item := SelectLeastValuableInventoryItem;
    if Item <> nil then ItemValue := Item.Cost / Item.Weight else ItemValue := 0;
    Artefact := SelectMostValuableArtefact;
    if Artefact <> nil then ArtefactValue := Artefact.Cost / Artefact.Weight else ArtefactValue := 0;
    if SelectCheapestCargoGood < 255 then
    begin
      Good := TGoodsIndex(SelectCheapestCargoGood);

      Count := Min(Abs(CargoFreeSpace), CargoGoods[Good].Count);
      GoodsValue := GoodsMarket[Good].BasePrice * Count;
      { Native reads Item.Cost here without checking Item for nil. }
      if Item.Cost > GoodsValue then
      begin
        DropGoodsIntoSpace(Good, Count);
        Continue;
      end;
      if (Artefact <> nil) and (Artefact.Cost > GoodsValue) then
      begin
        DropGoodsIntoSpace(Good, Count);
        Continue;
      end;
    end
    else
    begin
      Count := 0;
      GoodsValue := 0;
      Good := t_Food;
    end;
    if (Artefact <> nil) and (ArtefactValue < ItemValue) then
    begin
      DropCarriedArtefactAsMovingLoot(Artefact);
      Continue;
    end;
    if (Item <> nil) and not Item.EquippedFlag and
      ((Count = 0) or (Item.Cost < GoodsValue)) then
    begin
      DropCarriedItemAsMovingLoot(Item);
      Continue;
    end;
    if Count > 0 then
    begin
      DropGoodsIntoSpace(Good, Count);
      Continue;
    end;
    if Artefact <> nil then
    begin
      DropCarriedArtefactAsMovingLoot(Artefact);
      Continue;
    end;
    if Item <> nil then
    begin
      Mask := @ExclusiveEquipmentTypes;
      if not (Item.ItemType in Mask^) or not Item.EquippedFlag then
      begin
        DropCarriedItemAsMovingLoot(Item);
        Continue;
      end;
    end;
    RaiseWideMessage('Выкинуть вообще ничего не можем, а места нет');
  end;
end;
{ @end $5B28E8 }

{ @routine $5B2C08 TShip_DropRandomCheapItemsOnDestruction }
procedure TShip.DropRandomCheapItemsOnDestruction(Count: Integer);
var
  Index, I: Integer;
  Item: TItem;
  // @nested $5B2AE8 SelectCheapItem
  function SelectCheapItem: TItem; // @addr $5B2AE8
  var Attempt: Integer; Candidate: TItem;
  begin
    Result := nil;
    Index := NextRandomIntRange(1, Inventory.Count - 1, RandomState);
    for Attempt := 1 to Inventory.Count - 1 do
    begin
      IncrementWrapped(Index, 1, Inventory.Count - 1);
      Candidate := TItem(Inventory[Index]);
      if Candidate.DestroyFlag <> 0 then Continue;
      if (OwnerId = oiKling) and (Candidate.ItemType in WeaponItemTypes) and
        not (Candidate.ItemType in HeavyWeaponTypes) then Continue;
      if (Galaxy.AverageRangerCapital div 25 >= Candidate.Cost) and
        ((Result = nil) or (Candidate.Cost < NextRandomFloatRange(0.5, 1, RandomState) * Result.Cost)) then
        Result := Candidate;
    end;
  end;
begin
  for I := 1 to Count do
    if Inventory.Count > 1 then
    begin
      Item := SelectCheapItem;
      if Item <> nil then DropCarriedItemAsMovingLoot(Item);
    end;
end;
{ @end $5B2C08 }

{ @routine $5B2DBC TShip_DropRandomValuableItemsOnDestruction }
procedure TShip.DropRandomValuableItemsOnDestruction(Count: Integer);
var
  Index, I: Integer;
  Item: TItem;
  // @nested $5B2C44 SelectValuableItem
  function SelectValuableItem: TItem; // @addr $5B2C44
  var Attempt: Integer; Candidate: TItem;
  begin
    Result := nil;
    if Player = nil then Exit;
    Index := NextRandomIntRange(1, Inventory.Count - 1, RandomState);
    for Attempt := 1 to Inventory.Count - 1 do
    begin
      IncrementWrapped(Index, 1, Inventory.Count - 1);
      Candidate := TItem(Inventory[Index]);
      if Candidate.DestroyFlag <> 0 then Continue;
      if (OwnerId = oiKling) and (Candidate.ItemType in WeaponItemTypes) and
        not (Candidate.ItemType in HeavyWeaponTypes) then Continue;
      if ((Galaxy.AverageRangerCapital div 12 >= Candidate.Cost) or (NextRandomUnitFloat(RandomState) <= 0.3)) and
        ((Galaxy.AverageRangerCapital div 3 >= Candidate.Cost) or (NextRandomUnitFloat(RandomState) <= 0.3)) and
        ((Result = nil) or (Candidate.Cost > NextRandomFloatRange(0.5, 1, RandomState) * Result.Cost)) then
        Result := Candidate;
    end;
  end;
begin
  for I := 1 to Count do
    if Inventory.Count > 1 then
    begin
      Item := SelectValuableItem;
      if Item <> nil then DropCarriedItemAsMovingLoot(Item);
    end;
end;
{ @end $5B2DBC }

{ @routine $5B2DF8 TShip_DropCarriedItemAsMovingLoot }
function TShip.DropCarriedItemAsMovingLoot(Item: TItem): Boolean;
begin
  if Item.ItemType = t_Hull then
  begin
    Result := False;
    Exit;
  end;
  Inventory.Delete(Inventory.IndexOf(Item));
  Item.Position := Position;
  QueueMovingItemDrop(Item, 0);
  RefreshDerivedStats;
  Result := True;
end;
{ @end $5B2DF8 }

{ @routine $5B2E48 TShip_DropCarriedArtefactAsMovingLoot }
function TShip.DropCarriedArtefactAsMovingLoot(Item: TItem): Boolean;
begin
  Artefacts.Delete(Artefacts.IndexOf(Item));
  Item.Position := Position;
  QueueMovingItemDrop(Item, 0);
  RefreshDerivedStats;
  Result := True;
end;
{ @end $5B2E48 }

{ @routine $5B2E8C TShip_DropItemIntoStar }
function TShip.DropItemIntoStar(Item: TItem): Boolean;
var
  Star: TStar;
  Angle: Double;
  Effect: TWeaponSE;
  FilmEntry: PEFilmEndEntry;
begin
  if Player <> Self then
  begin
    if Item is TArtefact then
    begin
      Result := DropCarriedArtefactAsMovingLoot(Item);
      Exit;
    end;
    Result := DropCarriedItemAsMovingLoot(Item);
    Exit;
  end
  else
  begin
    Star := CurrentStar;
    Star.Items.Add(Item);
    Angle := SeededRandomIntRange(0, 360, CurrentStar.GenerationSeed * Galaxy.CurrentTurn * Item.Id) * Pi / 180;
    if Item is TWeapon then (Item as TWeapon).Target := nil;
    Item.Position.X := Player.Position.X + Sin(Angle) * 100;
    Item.Position.Y := Player.Position.Y - Cos(Angle) * 100;
    Item.GetGraphObject.SetPosition(Item.Position);
    if Star.DamageRadius * Star.DamageRadius > Sqr(Item.Position.X) + Sqr(Item.Position.Y) then
    begin
      Effect := TWeaponSE.Create('Weapon.NoGraph', Classes.Point(0, 0));
      Effect.SetEndpoints(nil, Item.GetGraphObject);
      Effect.SetHit(0, 0, True, True);
      if TrailingFilmEffects = nil then TrailingFilmEffects := TEFilmEnd.Create;
      FilmEntry := TrailingFilmEffects.AppendEntry;
      FilmEntry.SceneObject := Effect;
      FilmEntry.RelatedObject1 := Item.GetGraphObject;
      Item.GraphObject := nil;
      Star.Items.Delete(Star.Items.IndexOf(Item));
      Item.Free;
    end;
    // Native performs these list lookups even after stellar heat frees Item.
    if Inventory.IndexOf(Item) >= 0 then Inventory.Delete(Inventory.IndexOf(Item))
    else if Artefacts.IndexOf(Item) >= 0 then
      Inventory.Delete(Artefacts.IndexOf(Item)); // Native uses Inventory here too.
    Result := True;
  end;
end;
{ @end $5B2E8C }

{ @routine $5B30E8 TShip_DropAllArtefactsOnDestruction }
procedure TShip.DropAllArtefactsOnDestruction;
begin
  while Artefacts.Count > 0 do DropCarriedArtefactAsMovingLoot(TItem(Artefacts[0]));
end;
{ @end $5B30E8 }

{ @routine $5B3110 TShip_DropGoodsIntoSpace }
procedure TShip.DropGoodsIntoSpace(Good: TGoodsIndex; Count: Integer);
var
  Goods: TGoods;
begin
  Goods := TGoods.Create;
  Goods.Init(Good, Count);
  Goods.Position := Position;
  QueueMovingItemDrop(Goods, 0);
  ConsumeCargoGoods(Good, Count);
  RefreshDerivedStats;
end;
{ @end $5B3110 }

{ @routine $5B3164 TShip_JettisonCargoGoodsTowardTargetValue }
function TShip.JettisonCargoGoodsTowardTargetValue(TargetValue: Integer): Boolean;
var
  Good: TGoodsIndex;
  Pass, Quantity, Value, Drops: Integer;
  Done: Boolean;
  Factor: Single;
begin
  Result := False;
  Value := 0;
  Done := False;
  Drops := 0;
  for Pass := 1 to 3 do
  begin
    for Good := t_Food to t_Narcotics do
      if CargoGoods[Good].Count > 0 then
      begin
        Factor := RemapClamped(CargoGoods[Good].Count * GoodsMarket[Good].BasePrice,
          TargetValue div 3, TargetValue * 3, 1, 7);
        Quantity := Max(1, Round(CargoGoods[Good].Count / Factor));
        Inc(Value, Quantity * GoodsMarket[Good].BasePrice);
        DropGoodsIntoSpace(Good, Quantity);
        Inc(Drops);
        if (Value > TargetValue) or (Drops > 2) then
        begin
          Done := True;
          Break;
        end;
      end;
    if Done then Break;
  end;
  Result := Drops > 0;
end;
{ @end $5B3164 }

{ @routine $5B3274 TShip_DropAllCargoGoods }
procedure TShip.DropAllCargoGoods;
var
  Good: TGoodsIndex;
  Quantity: Integer;
begin
  for Good := t_Food to t_Narcotics do
    if CargoGoods[Good].Count > 0 then
    begin
      Quantity := CargoGoods[Good].Count;
      DropGoodsIntoSpace(Good, Quantity);
    end;
end;
{ @end $5B3274 }

{ @routine $5B329C TShip_QueueMovingItemDrop }
procedure TShip.QueueMovingItemDrop(Item: TItem; UseFlag: Byte);
var
  OtherItem: TItem;
  Drop: PMovingDropItemEntry;
  Retry: Boolean;
  Angle, Distance: Single;
  I, Count, Attempts: Integer;
begin
  if Item is TWeapon then
  begin
    (Item as TWeapon).Target := nil;
  end;
  Drop := AllocEC(SizeOf(TMovingDropItemEntry));
  Drop.Payload := Item;
  Drop.SourceShipId := Id;
  Drop.InsertedIntoStar := False;
  Drop.UseFlag := Boolean(UseFlag);
  Attempts := 0;
  Retry := True;
  while Retry do
  begin
    Angle := HeadingDegreesToRadians(NextRandomIntRange(0, 360, RandomState));
    Distance := NextRandomIntRange(100, 200, RandomState);
    Drop.Destination.X := Sin(Angle) * Distance + Item.Position.X;
    Drop.Destination.Y := Item.Position.Y - Cos(Angle) * Distance;
    Retry := False;
    Count := CurrentStar.Items.Count;
    for I := 0 to Count - 2 do
    begin
      OtherItem := CurrentStar.Items[I];
      if PointDistanceSquared(Drop.Destination, OtherItem.Position) < 100 then
      begin
        Retry := True;
        Break;
      end;
    end;
    if Attempts > 15 then Break;
    Inc(Attempts);
  end;
  CurrentStar.MovingDropItems.Add(Drop);
end;
{ @end $5B329C }

{ @routine $5B3414 TShip_SelectLeastValuableInventoryItem }
function TShip.SelectLeastValuableInventoryItem: TEquipment;
var
  I: Integer;
  BestValue, Value: Double;
  Item, Best: TEquipment;
begin
  Result := nil;
  Best := Hull;
  BestValue := 100000000;
  while Best <> Result do
  begin
    Result := Best;
    for I := 1 to Inventory.Count - 1 do
    begin
      Item := TEquipment(Inventory[I]);
      if Item = Best then Continue;
      Value := Item.Cost / Item.Weight;
      if (Item.ItemType in ExclusiveEquipmentTypes) and Item.EquippedFlag and
        (not (Best.ItemType in ExclusiveEquipmentTypes) or not Best.EquippedFlag) then Continue;
      if (Item.ItemType in WeaponItemTypes) and (WeaponCount = 1) then Continue;
      if (Item.ItemType in DeferredDropWeaponTypes) and (Best.ItemType in StandardWeaponTypes) then Continue;
      if ((Value < BestValue) and (not (Item.ItemType in OptionalEquipmentTypes) or
          (Best.ItemType in OptionalEquipmentTypes))) or
        ((Best.ItemType in ExclusiveEquipmentTypes) and Best.EquippedFlag and
          (not (Item.ItemType in ExclusiveEquipmentTypes) or not Item.EquippedFlag)) then
      begin
        Best := Item;
        BestValue := Value;
      end;
    end;
  end;
end;
{ @end $5B3414 }

{ @routine $5B35A4 TShip_SelectMostValuableArtefact }
function TShip.SelectMostValuableArtefact: TArtefact;
var
  I: Integer;
  BestValue, Value: Double;
  Item: TArtefact;
begin
  if Artefacts.Count = 0 then
  begin
    Result := nil;
    Exit;
  end;
  if Artefacts.Count = 0 then
  begin
    Result := TArtefact(Artefacts[0]);
    Exit;
  end;
  Result := TArtefact(Artefacts[0]);
  BestValue := Result.Cost / Result.Weight;
  for I := 1 to Artefacts.Count - 1 do
  begin
    Item := TArtefact(Artefacts[I]);
    Value := Item.Cost / Item.Weight;
    if Value >= BestValue then
    begin
      Result := Item;
      BestValue := Value;
    end;
  end;
end;
{ @end $5B35A4 }

{ @routine $5B3644 TShip_SelectCheapestCargoGood }
function TShip.SelectCheapestCargoGood: Byte;
var
  BestValue, Value: Double;
  Good: TGoodsIndex;
begin
  BestValue := 100000;
  Result := 255;
  for Good := t_Food to t_Narcotics do
  begin
    if CargoGoods[Good].Count = 0 then Continue;
    Value := GoodsMarket[Good].BasePrice;
    if Value < BestValue then
    begin
      BestValue := Value;
      Result := Ord(Good);
    end;
  end;
end;
{ @end $5B3644 }

{ @routine $5B36A8 TShip_OptimizeInventory }
procedure TShip.OptimizeInventory;
var Done: Boolean; I, Count: Integer; Item, Selected: TEquipment;
  Weapon, SelectedWeapon: TWeapon; Good: TGoodsIndex; Ratio: Double;
begin
  repeat
    Done := True;
    for I := 1 to Inventory.Count - 1 do begin
      Item := Inventory[I];
      if Item.EquippedFlag then Continue;
      LiquidateInventoryItem(Item);
      Done := False;
      Break;
    end;
  until Done;
  if Byte(CountHullDamageWeapons) <= Byte(CountSpecialDamageWeapons) then begin
    SelectedWeapon := nil;
    for I := 1 to WeaponCount do begin
      Weapon := Weapons[I - 1];
      if WeaponInfo[Weapon.ItemType].Mode <> wmHullDamage then
        if (SelectedWeapon = nil) or (SelectedWeapon.Cost > Weapon.Cost) or (SelectedWeapon.Weight * 2 < Weapon.Weight) then
          SelectedWeapon := Weapon;
    end;
    if SelectedWeapon <> nil then LiquidateInventoryItem(SelectedWeapon);
  end;
  while Hull.Weight - GetDesiredCargoFreeSpace < GetCarriedItemWeight do begin
    Ratio := 0;
    Selected := Hull;
    for I := 1 to Inventory.Count - 1 do begin
      Item := Inventory[I];
      if not (Item.ItemType in ExclusiveEquipmentTypes) then
      if not ((Item.ItemType in WeaponItemTypes) and (WeaponCount = 1)) then
      if (Item.Cost / Item.Weight < Ratio) or (Ratio = 0) or
        ((Item.ItemType in OptionalEquipmentTypes) and not (Selected.ItemType in OptionalEquipmentTypes)) then begin
        Selected := Item;
        Ratio := Item.Cost / Item.Weight;
      end;
    end;
    if Selected = Hull then Break;
    LiquidateInventoryItem(Selected);
  end;
  while (CargoFreeSpace < 0) and HasCargoGoods do
    for Good := t_Food to t_Narcotics do
      if CargoGoods[Good].Count > 0 then begin
        if CargoGoods[Good].Count >= Abs(CargoFreeSpace) then Count := Abs(CargoFreeSpace)
        else Count := CargoGoods[Good].Count;
        SellGoodsToLocation(Good, Count);
        Break;
      end;
  repeat
    Done := True;
    for I := 0 to Artefacts.Count - 1 do begin
      Selected := Artefacts[I];
      if Selected.ItemType in AIPreservedArtefactTypes then UseArtefact(Selected as TArtefact)
      else begin
        LiquidateArtefact(Selected as TArtefact);
        Done := False;
        Break;
      end;
    end;
  until Done;
  if not Done then ShowMessage('Корабль продал и оборудование и товары, а места так и нет');
end;
{ @end $5B36A8 }

{ @routine $5B39A0 TShip_LiquidateInventoryItem }
procedure TShip.LiquidateInventoryItem(Item: TItem);
begin
  SetMoney(Money + Item.CalculateResaleValue(BaseSkills[skTrader]));
  if (Item.ItemType = t_Protoplasm) and (Self is TRanger) and (Self <> Player) then
    if ((DockedTo <> nil) and (DockedTo.ShipType = t_RangerCenter)) or (DaysSincePlayerSeen > 100) then
    begin
      (Self as TRanger).DepositCarriedNodes;
      (Self as TRanger).TrainSkillsAutomatically;
      Exit;
    end;
  Inventory.Delete(Inventory.IndexOf(Item));
  Item.Free;
  RefreshDerivedStats;
end;
{ @end $5B39A0 }

{ @routine $5B3A50 TShip_LiquidateArtefact }
procedure TShip.LiquidateArtefact(Item: TArtefact);
begin
  DatabaseLogText := DatabaseLogText + 'Продал ' + Item.GetDisplayName + ' за половину стоимости:' +
    IntToStr(Item.CalculateResaleValue(BaseSkills[skTrader])) + #13#10;
  SetMoney(Money + Item.CalculateResaleValue(BaseSkills[skTrader]));
  Artefacts.Delete(Artefacts.IndexOf(Item));
  Item.Free;
  RefreshDerivedStats;
end;
{ @end $5B3A50 }

{ @routine $5B3B88 TShip_RepairHullAtLocation }
function TShip.RepairHullAtLocation: Boolean;
var Amount: Integer;
begin
  Result := False;
  if Hull.HullPoints <> Hull.Weight then begin
    Amount := Trunc(Hull.Weight / 10);
    if Hull.Weight < Hull.HullPoints + Amount then Hull.HullPoints := Hull.Weight
    else begin
      Inc(Hull.HullPoints, Amount);
      Result := True;
    end;
  end;
end;
{ @end $5B3B88 }

{ @routine $5B3BD8 TShip_DegradeEquipmentFromDamage }
procedure TShip.DegradeEquipmentFromDamage(Amount: Double);
var I: Integer; Item, Artefact: TEquipment;
begin
  for I := 1 to Inventory.Count - 1 do
  begin
    Item := TEquipment(Inventory[I]);
    if not Item.BrokenFlag and (Item.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) then
    begin
      if Item = DefGenerator then ApplyItemDegradation(Item, idkBattle, 1.3 * Amount)
      else if Item = RepairRobot then ApplyItemDegradation(Item, idkBattle, Amount * 1.25)
      else if Item.ItemType in WeaponItemTypes then ApplyItemDegradation(Item, idkBattle, 1.15 * Amount)
      else ApplyItemDegradation(Item, idkBattle, Amount);
    end;
  end;
  for I := 0 to Artefacts.Count - 1 do
  begin
    Artefact := TEquipment(Artefacts[I]);
    if not Artefact.BrokenFlag and (Artefact.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) then
      ApplyItemDegradation(Artefact, idkBattle, 0.3 * Amount);
  end;
end;
{ @end $5B3BD8 }

{ @routine $5B3D94 TShip_DegradeActiveArtefacts }
procedure TShip.DegradeActiveArtefacts(Amount: Double);
var I: Integer; Item: TEquipment;
begin
  if Artefacts.Count = 0 then Exit;
  for I := 0 to Artefacts.Count - 1 do begin
    Item := Artefacts[I];
    if not Item.BrokenFlag and Item.EquippedFlag then ApplyItemDegradation(Item, idkUse, Amount);
  end;
end;
{ @end $5B3D94 }

{ @routine $5B3DF0 TShip_ApplyItemDegradation }
function TShip.ApplyItemDegradation(Item: TEquipment; Kind: TItemDegradationKind; Amount: Double): Boolean;
begin
  Result := False;
  if Item.ConditionPercent < -95 then Exit;
  if BaseSkills[skTechnical] > 0 then Amount := Amount / (BaseSkills[skTechnical] * 0.2 + 1);
  Item.ConditionPercent := Item.ConditionPercent - Amount / OwnerInfo[Item.OwnerId].FuelPriceFactor;
  if (Item.ConditionPercent < 0) and not Item.BrokenFlag then begin
    if Item is TWeapon then begin
      if (ShipType = t_Warrior) and (UsableWeaponCount < 3) then begin
        Item.ConditionPercent := 1;
        Exit;
      end;
      (Item as TWeapon).Target := nil;
    end;
    Result := True;
    Item.BrokenFlag := True;
    if (Self = Player) and Item.EquippedFlag then begin
      case Kind of
        idkBattle: AddOrUpdatePlayerBubble(pmShip, Galaxy.CurrentTurn, Item.GetBrokenInBattleText, '').TargetIds[0] := Id;
        idkUse: AddOrUpdatePlayerBubble(pmShip, Galaxy.CurrentTurn, Item.GetBrokenInUseText, '').TargetIds[0] := Id;
      end;
      PlayerEquipmentChanged := True;
    end;
    RefreshDerivedStats;
  end;
end;
{ @end $5B3DF0 }

{ @routine $5B3F90 TShip_ImproveMostValuableEquipment }
procedure TShip.ImproveMostValuableEquipment;
var Equipment, Best: TEquipment; I, BestCost: Integer;
begin
  BestCost := 0;
  Best := nil;
  for I := 0 to Inventory.Count - 1 do begin
    Equipment := Inventory[I];
    if not Equipment.BrokenFlag and (Equipment.ItemType in ImprovableEquipmentTypes) and
      Equipment.HasStandardStats and (Equipment.OwnerId in CoalitionOwners) then
      if Equipment.Cost > BestCost then begin BestCost := Equipment.Cost; Best := Equipment; end;
  end;
  if Best <> nil then Best.Improve(ikAny);
end;
{ @end $5B3F90 }

{ @routine $5B402C TShip_GenerateExtraWeapon }
procedure TShip.GenerateExtraWeapon;
var Minimum, Maximum, Kind: Integer; I: TItemType;
begin
  Minimum := Max(Galaxy.TechLevel - 1, 1);
  Maximum := Min(Galaxy.TechLevel + 1, 8);
  Kind := NextRandomIntRange(Ord(t_PhotonGun), Ord(t_VortexProjector), RandomState);
  for I := t_PhotonGun to t_VortexProjector do begin
    IncrementWrapped(Kind, Ord(t_PhotonGun), Ord(t_VortexProjector));
    if WeaponInfo[TItemType(Kind)].RequiredTechLevel in [Minimum..Maximum] then begin
      // Native uses the loop's weight, which can belong to another weapon.
      CreateAndEquipWeapon(TItemType(Kind), False, WeaponInfo[I].Weight, NextRandomIntRange(Minimum, Maximum, RandomState), OwnerId);
      RefreshEquipmentSlots;
      OptimizeInventory;
      Break;
    end;
  end;
end;
{ @end $5B402C }

{ @routine $5B4124 TShip_BuyHullUpgrade }
procedure TShip.BuyHullUpgrade(SizeClass: TStandardCount);
var LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: THull;
begin
  if Hull.OwnerId <> CurrentPlanet.OwnerId then Exit;
  if Hull.Cost > Wealth * 0.2 then Exit;
  GetItemSizeBounds(t_Hull, SizeClass, Minimum, Maximum);
  if Hull.Weight > Minimum then Minimum := Hull.Weight;
  Maximum := Min(Maximum, Round(ItemSizeFactors[5 - CurrentPlanet.InventionLevels[invHullSize] + 1] * 500));
  if Hull.Weight > Maximum then Exit;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invHull];
  Budget := Min(Money + Hull.CalculateResaleValue(0), Round(Wealth * 0.2));
  if CalculateGeneratedHullCost(Minimum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedHullCost(Maximum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Maximum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedHullCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Minimum := Weight;
        LowLevel := Level;
      end else begin
        Maximum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Minimum;
    Level := LowLevel;
  end;
  Item := Hull;
  if Item.Weight > CargoFreeSpace + Weight then Exit;
  if CalculateGeneratedHullCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 1.8 then Exit;
  SetMoney(Money + Hull.CalculateResaleValue(0));
  SetMoney(Money - CalculateGeneratedHullCost(Weight, Level, CurrentPlanet.OwnerId));
  Hull.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  RefreshGraphicSize;
  RefreshDerivedStats;
end;
{ @end $5B4124 }

{ @routine $5B43C4 TShip_BuyFuelTanksUpgrade }
procedure TShip.BuyFuelTanksUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TFuelTanks;
begin
  if FuelTanks <> nil then begin
    if FuelTanks.Cost > Wealth * 0.125 then Exit;
    AvailableWeight := CargoFreeSpace + FuelTanks.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_FuelTanks, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(ItemSizeFactors[5 - CurrentPlanet.InventionLevels[invFuelTanksSize] + 1] * 40));
  Maximum := Min(Maximum, Round(Hull.Weight * 0.1));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invFuelTanks];
  if FuelTanks <> nil then Budget := Min(Money + FuelTanks.CalculateResaleValue(0), Round(Wealth * 0.125))
  else Budget := Min(Money, Round(Wealth * 0.125));
  if CalculateGeneratedFuelTanksCost(Minimum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedFuelTanksCost(Maximum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Maximum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedFuelTanksCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Minimum := Weight;
        LowLevel := Level;
      end else begin
        Maximum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Minimum;
    Level := LowLevel;
  end;
  Item := FuelTanks;
  if Item <> nil then begin
    if CalculateGeneratedFuelTanksCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 3 then Exit;
    LiquidateInventoryItem(FuelTanks);
  end;
  Item := TFuelTanks.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B43C4 }

{ @routine $5B46BC TShip_BuyEngineUpgrade }
procedure TShip.BuyEngineUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TEngine;
begin
  if Engine <> nil then begin
    if Engine.Cost > Wealth * (1/7) then Exit;
    AvailableWeight := CargoFreeSpace + Engine.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_Engine, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * 0.125));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  if Engine <> nil then LowLevel := Engine.TechLevel;
  HighLevel := CurrentPlanet.InventionLevels[invEngineSpeed];
  if Engine <> nil then Budget := Min(Money + Engine.CalculateResaleValue(0), Round(Wealth * (1/7)))
  else Budget := Min(Money, Round(Wealth * (1/7)));
  if CalculateGeneratedEngineCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedEngineCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    if (ShipType in [t_Ranger,t_Pirate]) and (CalculateSpeed < 600) then Level := Round(HighLevel * 0.8)
    else Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedEngineCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  if Engine <> nil then begin
    if Level <= Engine.TechLevel then
      if ((Engine.Cost * 1.3 > CalculateGeneratedEngineCost(Weight, Level, CurrentPlanet.OwnerId)) or
        (Level < Engine.TechLevel)) then Exit;
    LiquidateInventoryItem(Engine);
  end;
  Item := TEngine.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B46BC }

{ @routine $5B49F8 TShip_BuyRadarUpgrade }
procedure TShip.BuyRadarUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TRadar;
begin
  if Radar <> nil then begin
    if Radar.Cost > Wealth * (1/12) then Exit;
    AvailableWeight := CargoFreeSpace + Radar.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_Radar, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * (1/11)));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invRadarRange];
  if Radar <> nil then Budget := Min(Money + Radar.CalculateResaleValue(0), Round(Wealth * (1/12)))
  else Budget := Min(Money, Round(Wealth * (1/12)));
  if CalculateGeneratedRadarCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedRadarCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedRadarCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  Item := Radar;
  if Item <> nil then begin
    if CalculateGeneratedRadarCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 3 then Exit;
    LiquidateInventoryItem(Radar);
  end;
  Item := TRadar.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B49F8 }

{ @routine $5B4CC4 TShip_BuyScannerUpgrade }
procedure TShip.BuyScannerUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TScaner;
begin
  if Scanner <> nil then begin
    if Scanner.Cost > Wealth * (1/13) then Exit;
    AvailableWeight := CargoFreeSpace + Scanner.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_Scaner, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * (1/12)));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invScanner];
  if Scanner <> nil then Budget := Min(Money + Scanner.CalculateResaleValue(0), Round(Wealth * (1/13)))
  else Budget := Min(Money, Round(Wealth * (1/13)));
  if CalculateGeneratedScanerCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedScanerCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedScanerCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  Item := Scanner;
  if Item <> nil then begin
    if CalculateGeneratedScanerCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 3 then Exit;
    LiquidateInventoryItem(Scanner);
  end;
  Item := TScaner.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B4CC4 }

{ @routine $5B4F90 TShip_BuyRepairRobotUpgrade }
procedure TShip.BuyRepairRobotUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TRepairRobot;
begin
  if RepairRobot <> nil then begin
    if RepairRobot.Cost > Wealth * 0.125 then Exit;
    AvailableWeight := CargoFreeSpace + RepairRobot.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_RepairRobot, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * (1/9)));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invRepairRobot];
  if RepairRobot <> nil then Budget := Min(Money + RepairRobot.CalculateResaleValue(0), Round(Wealth * 0.125))
  else Budget := Min(Money, Round(Wealth * 0.125));
  if CalculateGeneratedRepairRobotCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedRepairRobotCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedRepairRobotCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  Item := RepairRobot;
  if Item <> nil then begin
    if CalculateGeneratedRepairRobotCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 3 then Exit;
    LiquidateInventoryItem(RepairRobot);
  end;
  Item := TRepairRobot.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B4F90 }

{ @routine $5B5250 TShip_BuyCargoHookUpgrade }
procedure TShip.BuyCargoHookUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TCargoHook;
begin
  if CargoHook <> nil then begin
    if CargoHook.Cost > Wealth * 0.1 then Exit;
    AvailableWeight := CargoFreeSpace + CargoHook.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_CargoHook, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * 0.1));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invCargoHook];
  if CargoHook <> nil then Budget := Min(Money + CargoHook.CalculateResaleValue(0), Round(Wealth * 0.1))
  else Budget := Min(Money, Round(Wealth * 0.1));
  if CalculateGeneratedCargoHookCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedCargoHookCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedCargoHookCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  if CargoHook <> nil then begin
    if (CargoHook.Cost * 3 > CalculateGeneratedCargoHookCost(Weight, Level, CurrentPlanet.OwnerId)) or (Level <= CargoHook.TechLevel) then Exit;
    LiquidateInventoryItem(CargoHook);
  end;
  Item := TCargoHook.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B5250 }

{ @routine $5B5524 TShip_BuyDefGeneratorUpgrade }
procedure TShip.BuyDefGeneratorUpgrade(SizeClass: TStandardCount);
var AvailableWeight, LowLevel, Weight, Level, Attempts, Budget, Minimum, Maximum, HighLevel: Integer;
  Item: TDefGenerator;
begin
  if DefGenerator <> nil then begin
    if DefGenerator.Cost > Wealth * 0.125 then Exit;
    AvailableWeight := CargoFreeSpace + DefGenerator.Weight - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  end else AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  GetItemSizeBounds(t_DefGenerator, SizeClass, Minimum, Maximum);
  if AvailableWeight < Minimum then Exit;
  Maximum := Min(Maximum, Round(Hull.Weight * (1/9)));
  if AvailableWeight < Maximum then Maximum := AvailableWeight;
  LowLevel := 1;
  HighLevel := CurrentPlanet.InventionLevels[invTechLevel];
  if DefGenerator <> nil then Budget := Min(Money + DefGenerator.CalculateResaleValue(0), Round(Wealth * 0.125))
  else Budget := Min(Money, Round(Wealth * 0.125));
  if CalculateGeneratedDefGeneratorCost(Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Exit;
  if CalculateGeneratedDefGeneratorCost(Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
    Weight := Minimum;
    Level := HighLevel;
  end else begin
    Weight := Round((Minimum + Maximum) * 0.5);
    Level := Round((HighLevel + LowLevel) * 0.5);
    Attempts := 0;
    repeat
      Inc(Attempts);
      if CalculateGeneratedDefGeneratorCost(Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
        Maximum := Weight;
        LowLevel := Level;
      end else begin
        Minimum := Weight;
        HighLevel := Level;
      end;
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((HighLevel + LowLevel) * 0.5);
    until Attempts > 5;
    Weight := Maximum;
    Level := LowLevel;
  end;
  Item := DefGenerator;
  if Item <> nil then begin
    if CalculateGeneratedDefGeneratorCost(Weight, Level, CurrentPlanet.OwnerId) < Item.Cost * 3 then Exit;
    LiquidateInventoryItem(DefGenerator);
  end;
  Item := TDefGenerator.Create;
  Item.Init(True, Weight, Level, CurrentPlanet.OwnerId);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  SetMoney(Money - Item.Cost);
  RefreshDerivedStats;
end;
{ @end $5B5524 }

{ @routine $5B57E4 TShip_BuyWeaponUpgrade }
procedure TShip.BuyWeaponUpgrade(SizeClass: TStandardCount);
var I, AvailableWeight, WeakestIndex, Budget: Integer;
  Item: TWeapon;
  Minimum, LowLevel, Maximum, HighLevel: Integer;
  Kind, LastKind: TItemType;
  Info: TWeaponInfo;
  Weight, Level: Integer;
begin
  AvailableWeight := CargoFreeSpace - Max(0, GetDesiredCargoFreeSpace - GetCargoGoodsWeight);
  if AvailableWeight < 1 then Exit;
  Item := nil;
  if ShipType = t_Kling then LastKind := t_EyesOfMachpella else LastKind := t_VortexProjector;
  for Kind := t_PhotonGun to LastKind do begin
    Info := WeaponInfo[Kind];
    if CurrentPlanet.InventionLevels[invTechLevel] < Info.RequiredTechLevel then Break;
    if Info.Mode <> wmHullDamage then
      if (ShipType = t_Ranger) or (CountHullDamageWeapons <= CountSpecialDamageWeapons + 1) then Continue;
    if (WeaponCount > 2) and (Integer(Galaxy.TechLevel) - 2 > WeaponInfo[Kind].RequiredTechLevel) then Continue;
    GetItemSizeBounds(Kind, SizeClass, Minimum, Maximum);
    if Minimum > AvailableWeight then Continue;
    Maximum := Min(Maximum, Round(Hull.Weight * 0.2));
    if Maximum > AvailableWeight then Maximum := AvailableWeight;
    LowLevel := 1;
    HighLevel := CurrentPlanet.InventionLevels[invTechLevel];
    Budget := Min(Money, Round(Wealth * (1/7)));
    if CalculateGeneratedWeaponCost(Kind, Maximum, LowLevel, CurrentPlanet.OwnerId) > Budget then Continue;
    if CalculateGeneratedWeaponCost(Kind, Minimum, HighLevel, CurrentPlanet.OwnerId) <= Budget then begin
      Weight := Minimum;
      Level := HighLevel;
    end else begin
      Weight := Round((Minimum + Maximum) * 0.5);
      Level := Round((LowLevel + HighLevel) * 0.5);
      I := 0;
      repeat
        Inc(I);
        if CalculateGeneratedWeaponCost(Kind, Weight, Level, CurrentPlanet.OwnerId) < Budget then begin
          Maximum := Weight;
          LowLevel := Level;
        end else begin
          Minimum := Weight;
          HighLevel := Level;
        end;
        Weight := Round((Minimum + Maximum) * 0.5);
        Level := Round((LowLevel + HighLevel) * 0.5);
      until I > 5;
      Weight := Maximum;
      Level := LowLevel;
    end;
    if Item <> nil then begin
      if CalculateGeneratedWeaponCost(Kind, Weight, Level, CurrentPlanet.OwnerId) *
        RemapClamped(Hull.Weight / Weight, 6, 20, 3, 6) <
        Item.Cost * RemapClamped(Hull.Weight / Item.Weight, 6, 20, 1, 3) then Continue;
    end else begin
      if WeaponCount = 5 then begin
        WeakestIndex := 1;
        for I := 2 to WeaponCount do
          if Weapons[WeakestIndex - 1].Cost > Weapons[I - 1].Cost then WeakestIndex := I;
        if CalculateGeneratedWeaponCost(Kind, Weight, Level, CurrentPlanet.OwnerId) <=
          3 * Weapons[WeakestIndex - 1].Cost then Continue;
        LiquidateInventoryItem(Weapons[WeakestIndex - 1]);
      end;
      Item := TWeapon.Create;
    end;
    Item.Init(Kind, True, Weight, Level, CurrentPlanet.OwnerId);
  end;
  if Item <> nil then begin
    Inventory.Add(Item);
    EquipItemDirect(Item);
    SetMoney(Money - Item.Cost);
    RefreshDerivedStats;
  end else Item.Free;
end;
{ @end $5B57E4 }

{ @routine $5B5C78 TShip_CreateAndEquipHull }
function TShip.CreateAndEquipHull(Equipped: Boolean; Capacity: Word; Level: Byte; Owner: TOwnerId): THull;
var Item: THull;
begin
  Item := THull.Create;
  Item.Init(Equipped, Capacity, Level, Owner);
  Inventory.Add(Item);
  EquipItemDirect(Item);
  Result := Item;
  RefreshGraphicSize;
end;
{ @end $5B5C78 }

{ @routine $5B5CD4 TShip_CreateAndEquipFuelTanks }
function TShip.CreateAndEquipFuelTanks(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TFuelTanks;
var Item: TFuelTanks;
begin
  Item := TFuelTanks.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5CD4 }

{ @routine $5B5D28 TShip_CreateAndEquipEngine }
function TShip.CreateAndEquipEngine(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TEngine;
var Item: TEngine;
begin
  Item := TEngine.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5D28 }

{ @routine $5B5D7C TShip_CreateAndEquipRadar }
function TShip.CreateAndEquipRadar(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TRadar;
var Item: TRadar;
begin
  Item := TRadar.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5D7C }

{ @routine $5B5DD0 TShip_CreateAndEquipScanner }
function TShip.CreateAndEquipScanner(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TScaner;
var Item: TScaner;
begin
  Item := TScaner.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5DD0 }

{ @routine $5B5E24 TShip_CreateAndEquipRepairRobot }
function TShip.CreateAndEquipRepairRobot(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TRepairRobot;
var Item: TRepairRobot;
begin
  Item := TRepairRobot.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5E24 }

{ @routine $5B5E78 TShip_CreateAndEquipCargoHook }
function TShip.CreateAndEquipCargoHook(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TCargoHook;
var Item: TCargoHook;
begin
  Item := TCargoHook.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5E78 }

{ @routine $5B5ECC TShip_CreateAndEquipDefGenerator }
function TShip.CreateAndEquipDefGenerator(Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TDefGenerator;
var Item: TDefGenerator;
begin
  Item := TDefGenerator.Create;
  Item.Init(Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5ECC }

{ @routine $5B5F20 TShip_CreateAndEquipWeapon }
function TShip.CreateAndEquipWeapon(Kind: TItemType; Equipped: Boolean; Weight: Integer; Level: Byte; Owner: TOwnerId): TWeapon;
var Item: TWeapon;
begin
  Item := TWeapon.Create;
  Item.Init(Kind, Equipped, Weight, Level, Owner);
  Inventory.Add(Item);
  if Equipped then EquipItemDirect(Item);
  Result := Item;
end;
{ @end $5B5F20 }

{ @routine $5B5F78 TShip_CreateRandomEquipment }
function TShip.CreateRandomEquipment(Types: TItemTypeMask; Equipped: Boolean; SizeClass: TStandardCount; StandardLevel: ShortInt; Owner: TOwnerId; Seed: Cardinal): TEquipment;
var I, Kind: TItemType; Count, Choice: Integer;
begin
  Result := nil;
  Count := 0;
  Kind := t_Hull;
  for I := t_FuelTanks to t_EyesOfMachpella do if I in Types then Inc(Count);
  if Count <> 0 then
  begin
    Choice := SeededRandomIntRange(1, Count, Seed);
    Count := 0;
    for I := t_FuelTanks to t_EyesOfMachpella do
      if I in Types then
      begin
        Inc(Count);
        if Choice = Count then
        begin
          Kind := I;
          Break;
        end;
      end;
    case Kind of
      t_FuelTanks: Result := CreateAndEquipFuelTanks(Equipped, GenerateItemSize(t_FuelTanks, SizeClass, Seed), StandardToItemTechLevel(t_FuelTanks, StandardLevel, Seed), Owner);
      t_Engine: Result := CreateAndEquipEngine(Equipped, GenerateItemSize(t_Engine, SizeClass, Seed), StandardToItemTechLevel(t_Engine, StandardLevel, Seed), Owner);
      t_Radar: Result := CreateAndEquipRadar(Equipped, GenerateItemSize(t_Radar, SizeClass, Seed), StandardToItemTechLevel(t_Radar, StandardLevel, Seed), Owner);
      t_Scaner: Result := CreateAndEquipScanner(Equipped, GenerateItemSize(t_Scaner, SizeClass, Seed), StandardToItemTechLevel(t_Scaner, StandardLevel, Seed), Owner);
      t_RepairRobot: Result := CreateAndEquipRepairRobot(Equipped, GenerateItemSize(t_RepairRobot, SizeClass, Seed), StandardToItemTechLevel(t_RepairRobot, StandardLevel, Seed), Owner);
      t_CargoHook: Result := CreateAndEquipCargoHook(Equipped, GenerateItemSize(t_CargoHook, SizeClass, Seed), StandardToItemTechLevel(t_CargoHook, StandardLevel, Seed), Owner);
      t_DefGenerator: Result := CreateAndEquipDefGenerator(Equipped, GenerateItemSize(t_DefGenerator, SizeClass, Seed), StandardToItemTechLevel(t_DefGenerator, StandardLevel, Seed), Owner);
      t_PhotonGun..t_EyesOfMachpella: Result := CreateAndEquipWeapon(Kind, Equipped, GenerateItemSize(Kind, SizeClass, Seed), StandardToItemTechLevel(Kind, StandardLevel, Seed), Owner);
    else RaiseWideMessage('TShip.AddRandomEq = nil');
    end;
  end;
end;
{ @end $5B5F78 }

{ @routine $5B6228 TShip_ScanForCollectableItems }
function TShip.ScanForCollectableItems: Boolean;
var I: Integer; Item: TItem;
begin
  Result := False;
  if (CargoHook <> nil) and not CargoHook.BrokenFlag then
    for I := 0 to CurrentStar.Items.Count - 1 do
    begin
      Item := CurrentStar.Items[I];
      if (CanReplaceCargoForItem(Item) or (Item.Cost > Wealth * 0.05)) and
        (Item.Weight <= CargoFreeSpace) and (CountOtherShipsPickingUpItem(Item) = 0) and
        (15 * (Ord(HasActiveArtefact(t_ArtefactHook))) + CargoHook.PickupPower >= Item.Weight) and
        (Item.ScriptItem = nil) then
      begin
        Result := True;
        Exit;
      end;
    end;
end;
{ @end $5B6228 }

{ @routine $5B62EC TShip_TryCollectBestFloatingItem }
function TShip.TryCollectBestFloatingItem(MaximumTravelTurns: Integer): Boolean;
var I: Integer; Item, Best: TItem; Found: Boolean; Distance, BestDistance: Double;
begin
  Result := False;
  if (CargoHook = nil) or CargoHook.BrokenFlag or (Speed < 1) then Exit;
  Found := False;
  Best := nil;
  BestDistance := 10000;
  for I := 0 to CurrentStar.Items.Count - 1 do begin
    Item := CurrentStar.Items[I];
    if (CargoHook.PickupPower + 15 * (Ord(HasActiveArtefact(t_ArtefactHook))) >= Item.Weight) and
      (Item.ScriptItem = nil) and
      ((CargoFreeSpace - GetReservedPickupWeight >= Item.Weight) or CanReplaceCargoForItem(Item)) and
      (CountOtherShipsPickingUpItem(Item) < 2) and CanReachItemBeforeOtherShips(Item) then begin
      if CanPickupItemNow(Item) then QueuePickupItem(Item)
      else begin
        Distance := PointDistance(Position, Item.Position);
        if MaximumTravelTurns >= Distance / Speed then begin
          case ShipType of
            t_Pirate: if not (Item.ItemType in PiratePriorityPickupTypes) and (2 * Speed < Distance) and
              (Item.Cost < RemapClamped(Distance / Speed, 1, 10, 0.01, 0.05) * Wealth) then Continue;
            t_Ranger: if Item.ItemType <> t_Protoplasm then begin
              if (Speed * 1.2 < Distance) and
                (Item.Cost < RemapClamped(Distance / Speed, 1, 10, 0.01, 0.05) * Wealth) then Continue;
            end else if (Item.Weight < 30) and (Distance / Speed > 3) then Continue;
          end;
          if (not OrderAbsolute or (Order = soMove)) and
            ((Best = nil) or ((10 * Best.Cost < Item.Cost) and (Best.Cost > Wealth * 0.01)) or
             ((1.3 * Distance < BestDistance) and (Best.Cost < 2 * Item.Cost))) then begin
            Found := True;
            Best := Item;
            BestDistance := Distance;
          end;
        end;
      end;
    end;
  end;
  if Best <> nil then OrderMove(GetPickupApproachPosition(Best.Position), True);
  if not Found and (Order = soMove) then OrderNone;
  if Order = soMove then Result := True;
end;
{ @end $5B62EC }

{ @routine $5B6644 TShip_GetReservedPickupWeight }
function TShip.GetReservedPickupWeight: Integer;
var I: Integer; Item: TItem;
begin
  Result := 0;
  if PickupTargets <> nil then
    for I := 0 to PickupTargets.Count - 1 do begin
      Item := TItem(PickupTargets[I]);
      Inc(Result, Item.Weight);
    end;
end;
{ @end $5B6644 }

{ @routine $5B667C TShip_CanReplaceCargoForItem }
function TShip.CanReplaceCargoForItem(Item: TItem): Boolean;
var
  Equipment: TEquipment;
  I, Weight: Integer;
begin
  Result := False;
  if (Item is TEquipment) and (Item as TEquipment).BrokenFlag then Exit;
  if Item.ItemType in DirectEquipmentTypes then begin
    for I := 1 to Inventory.Count - 1 do begin
      Equipment := Inventory[I];
      if Equipment.ItemType = Item.ItemType then begin
        if ((Equipment.Weight <= Item.Weight) and (Equipment.Cost * 1.1 < Item.Cost)) or
          ((Equipment.Weight + CargoFreeSpace > Item.Weight) and not Equipment.EquippedFlag and
           (Equipment.Cost * 1.4 < Item.Cost)) then begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end else if Item.ItemType in WeaponItemTypes then begin
    Weight := 0;
    for I := 1 to Inventory.Count - 1 do begin
      Equipment := Inventory[I];
      if (Equipment.ItemType in WeaponItemTypes) and Item.IsBetterThan(Equipment) then
        Inc(Weight, Equipment.Weight);
    end;
    if Weight + CargoFreeSpace >= Item.Weight then Result := True;
  end;
end;
{ @end $5B667C }

{ @routine $5B680C TShip_CanPickupItemNow }
function TShip.CanPickupItemNow(Item: TItem): Boolean;
begin
  Result := (CargoHook <> nil) and not CargoHook.BrokenFlag and
    (PointDistanceSquared(Position, Item.Position) <= 22500) and
    (CargoHook.PickupPower + 15 * (Ord(HasActiveArtefact(t_ArtefactHook))) >= Item.Weight) and
    (((Self <> Player) and (Item.ScriptItem = nil)) or (Self = Player)) and
    (not (Item is TUselessItem) or (TUselessItem(Item).ConfigBlockName <> 'ExampleAsteroid'));
end;
{ @end $5B680C }

{ @routine $5B68C4 TShip_CanHookItem }
function TShip.CanHookItem(Item: TItem): Boolean;
begin
  Result := (CargoHook <> nil) and not CargoHook.BrokenFlag and
    (CargoHook.PickupPower + 15 * (Ord(HasActiveArtefact(t_ArtefactHook))) >= Item.Weight) and
    (((Self <> Player) and (Item.ScriptItem = nil)) or (Self = Player));
end;
{ @end $5B68C4 }

{ @routine $5B6918 TShip_QueuePickupItem }
procedure TShip.QueuePickupItem(Item: TItem);
var I: Integer;
begin
  if PickupTargets = nil then PickupTargets := TList.Create;
  for I := 0 to PickupTargets.Count - 1 do
    if Item = PickupTargets[I] then Exit;
  PickupTargets.Add(Item);
end;
{ @end $5B6918 }

{ @routine $5B6974 TShip_RemoveQueuedPickupItem }
procedure TShip.RemoveQueuedPickupItem(Item: TObject);
var I: Integer;
begin
  if PickupTargets <> nil then begin
    I := 0;
    while I < PickupTargets.Count do
      if Item = PickupTargets[I] then PickupTargets.Delete(I)
      else Inc(I);
    if PickupTargets.Count < 1 then begin
      PickupTargets.Free;
      PickupTargets := nil;
    end;
  end;
end;
{ @end $5B6974 }

{ @routine $5B69D0 TShip_ClearPickupTargets }
procedure TShip.ClearPickupTargets;
begin
  if PickupTargets <> nil then
  begin
    PickupTargets.Free;
    PickupTargets := nil;
  end;
end;
{ @end $5B69D0 }

{ @routine $5B69EC TShip_IsPickupQueued }
function TShip.IsPickupQueued(Item: TItem): Boolean;
var I: Integer;
begin
  Result := False;
  if PickupTargets = nil then Exit;
  for I := 0 to PickupTargets.Count - 1 do
    if Item = PickupTargets[I] then begin
      Result := True;
      Break;
    end;
end;
{ @end $5B69EC }

{ @routine $5B6A34 TShip_CountOtherShipsPickingUpItem }
function TShip.CountOtherShipsPickingUpItem(Item: TItem): Integer;
var
  I, Count, J: Integer;
  Ship: TShip;
begin
  Count := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship = Self then Continue;
    if Ship.PickupTargets <> nil then
      for J := 0 to Ship.PickupTargets.Count - 1 do
        if Ship.PickupTargets[J] = Item then begin
          Inc(Count);
          Break;
        end;
  end;
  Result := Count;
end;
{ @end $5B6A34 }

{ @routine $5B6AC0 TShip_CanReachItemBeforeOtherShips }
function TShip.CanReachItemBeforeOtherShips(Item: TItem): Boolean;
var I: Integer; Ship: TShip;
begin
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if (Ship <> Self) and Ship.InNormalSpace and (Ship.Speed >= 1) and
      (Ship.GetPickupApproachPosition(Item.Position).X = Ship.OrderDestination.X) and
      (Ship.GetPickupApproachPosition(Item.Position).Y = Ship.OrderDestination.Y) then
      if PointDistance(Ship.Position, Item.Position) / Ship.Speed <
        PointDistance(Position, Item.Position) / Speed then begin
        Result := False;
        Exit;
      end;
  end;
  Result := True;
end;
{ @end $5B6AC0 }

{ @routine $5B6B9C TShip_GetPickupApproachPosition }
function TShip.GetPickupApproachPosition(ItemPosition: TPointF): TPointF;
var Direction: Integer;
begin
  if ItemPosition.X < Position.X then Direction := -1 else Direction := 1;
  Result.X := ItemPosition.X + 75 * Direction;
  if ItemPosition.Y < Position.Y then Direction := -1 else Direction := 1;
  Result.Y := ItemPosition.Y + 75 * Direction;
end;
{ @end $5B6B9C }

{ @routine $5B6C00 TShip_GetOrderDebugText }
procedure TShip.GetOrderDebugText(out OrderText, TargetText, ParameterText: WideString);
begin
  if Order = soNone then
  begin
    OrderText := 'None';
    TargetText := '';
    ParameterText := '';
  end
  else if Order = soMove then
  begin
    OrderText := 'Move';
    TargetText := '';
    ParameterText := IntToStr(Round(OrderDestination.X)) + ',' + IntToStr(Round(OrderDestination.Y));
  end
  else if Order = soJump then
  begin
    OrderText := 'Jump';
    TargetText := (OrderTarget as TStar).Name;
    ParameterText := IntToStr(Cardinal(OrderStateData));
  end
  else if Order = soLanding then
  begin
    OrderText := 'Landing';
    TargetText := (OrderTarget as TPlanet).Name;
    ParameterText := '';
  end
  else if Order = soTakeoff then
  begin
    OrderText := 'TakeOff';
    TargetText := '';
    ParameterText := '';
  end
  else if Order = soFollowShip then
  begin
    OrderText := 'FollowShip';
    TargetText := IntToStr((OrderTarget as TShip).Id);
    ParameterText := IntToStr(Cardinal(OrderStateData));
  end
  else
  begin
    OrderText := '';
    TargetText := '';
    ParameterText := '';
  end;
end;
{ @end $5B6C00 }

{ @routine $5B6EAC TShip_OrderNone }
procedure TShip.OrderNone;
begin
  OrderAbsolute := False;
  Order := soNone;
  OrderTarget := nil;
  ClearMovementPath;
end;
{ @end $5B6EAC }

{ @routine $5B6EC8 TShip_OrderMove }
procedure TShip.OrderMove(Destination: TPointF; Absolute: Boolean);
begin
  if not HasPositiveSpeed then
  begin
    OrderNone;
    Exit;
  end;
  Order := soMove;
  OrderDestination := Destination;
  OrderAbsolute := Absolute;
  OrderTarget := nil;
end;
{ @end $5B6EC8 }

{ @routine $5B6F1C TShip_GetJumpDeparturePoint }
function TShip.GetJumpDeparturePoint(Destination: TStar): TPointF;
var Angle, Radius: Double;
begin
  Angle := HeadingDegreesToRadians(PointBearingDegrees(CurrentStar.Position, Destination.Position) +
    SeededRandomIntRange(-4, 4, (CurrentStar.GenerationSeed + Seed) * Destination.GenerationSeed));
  Radius := CurrentStar.ComputeMapDiameter / 2;
  Result.X := Trunc(Sin(Angle) * Radius);
  Result.Y := Trunc(-Cos(Angle) * Radius);
end;
{ @end $5B6F1C }

{ @routine $5B6FE4 TShip_GetArrivalPosition }
function TShip.GetArrivalPosition(DestinationStar: TStar): TPointF;
var
  Angle, Radius: Double;
begin
  Angle := HeadingDegreesToRadians(PointBearingDegrees(DestinationStar.Position, CurrentStar.Position));
  Radius := DestinationStar.ComputeMapDiameter / 2;
  Result.X := Trunc(Sin(Angle) * Radius);
  Result.Y := Trunc(-Cos(Angle) * Radius);
end;
{ @end $5B6FE4 }

{ @routine $5B7078 TShip_CalculateJumpTravelDays }
function TShip.CalculateJumpTravelDays(Origin, Destination: TStar): Integer;
begin
  Result := Max(2, Round(PointDistance(Origin.Position, Destination.Position) * 0.1) + 1);
end;
{ @end $5B7078 }

{ @routine $5B70B8 TShip_OrderJump }
procedure TShip.OrderJump(Star: TStar; Absolute: Boolean);
begin
  if CurrentStar = Star then Exit;
  if not HasPositiveSpeed then
  begin
    OrderNone;
    Exit;
  end;
  Order := soJump;
  OrderTarget := Star;
  OrderAbsolute := Absolute;
  OrderDestination := GetJumpDeparturePoint(Star);
  OrderStateData := CalculateJumpTravelDays(CurrentStar, Star);
end;
{ @end $5B70B8 }

{ @routine $5B7128 TShip_OrderEnterBlackHole }
procedure TShip.OrderEnterBlackHole(Hole: THole; Forward, Absolute: Boolean);
begin
  if not HasPositiveSpeed then OrderNone
  else begin
    Order := soEnterBlackHole;
    OrderTarget := Hole;
    OrderAbsolute := Absolute;
    if CurrentStar = Hole.Star1 then OrderDestination := Hole.Position1
    else OrderDestination := Hole.Position2;
    if Forward then OrderStateData := BlackHoleForwardTransitState
    else OrderStateData := BlackHoleReverseTransitState;
  end;
end;
{ @end $5B7128 }

{ @routine $5B71B0 TShip_OrderLanding }
procedure TShip.OrderLanding(Location: TObject; Absolute: Boolean);
begin
  if Location = nil then
  begin
    OrderNone;
    Exit;
  end;
  if not HasPositiveSpeed then
  begin
    OrderNone;
    Exit;
  end;
  Order := soLanding;
  OrderTarget := Location;
  OrderDestination := MakePointF(0, 0);
  OrderAbsolute := Absolute;
end;
{ @end $5B71B0 }

{ @routine $5B7218 TShip_OrderTakeoff }
procedure TShip.OrderTakeoff;
var
  Angle: Double;
  Conflict: Boolean;
  I, Count, Attempt: Integer;
  Ship: TShip;
  DX, DY: Single;
begin
  if not HasPositiveSpeed then
  begin
    OrderNone;
    Exit;
  end;
  OrderTarget := nil;
  if CurrentPlanet <> nil then
  begin
    Order := soTakeoff;
    if Self is TNormalShip then (Self as TNormalShip).LastDockedPlanet := CurrentPlanet;
    Position := CurrentPlanet.GetPosition;
    Conflict := True;
    Attempt := 0;
    while Conflict do
    begin
      Angle := SeededRandomIntRange(0, 360, CurrentPlanet.GenerationSeed * Seed * Galaxy.CurrentTurn * (Attempt + 1)) * Pi / 180;
      OrderDestination.X := Trunc(CurrentPlanet.GetPosition.X + Sin(Angle) * 400);
      OrderDestination.Y := Trunc(CurrentPlanet.GetPosition.Y + -Cos(Angle) * 400);
      DX := OrderDestination.X - Position.X;
      DY := OrderDestination.Y - Position.Y;
      if Odd(Galaxy.CurrentTurn) then
        MovementDirection := RadiansToHeadingDegrees(ArcTan2(0 - DY, -(0 + DX)))
      else
        MovementDirection := RadiansToHeadingDegrees(ArcTan2(0 + DY, -(0 - DX)));
      MovementDirection := WrapHeadingDegrees(MovementDirection + SeededRandomIntRange(-5, 5, CurrentPlanet.GenerationSeed * Seed * Galaxy.CurrentTurn * (Attempt + 3 + 1)));
      Conflict := False;
      Count := CurrentStar.Ships.Count;
      for I := 0 to Count - 1 do
      begin
        Ship := TShip(CurrentStar.Ships[I]);
        if (Ship <> Self) and (Ship.Order = soTakeoff) and (Ship.CurrentPlanet = CurrentPlanet) and
          (Abs(HeadingDifferenceDegrees(MovementDirection, Ship.MovementDirection)) < 20) then
        begin
          Conflict := True;
          Break;
        end;
      end;
      Inc(Attempt);
      if Attempt > 5 then Break;
    end;
  end
  else if DockedTo <> nil then
  begin
    Order := soTakeoff;
    if Self is TRanger then (Self as TRanger).LastDockedNonPlanetLocation := DockedTo;
    Position := DockedTo.Position;
    Angle := SeededRandomIntRange(0, 360, (DockedTo.Seed + Seed) * Galaxy.CurrentTurn) * Pi / 180;
    OrderDestination.X := Trunc(Position.X + Sin(Angle) * 400);
    OrderDestination.Y := Trunc(Position.Y + -Cos(Angle) * 400);
    MovementDirection := RadiansToHeadingDegrees(ArcTan2(-(OrderDestination.X - Position.X), -(-(OrderDestination.Y - Position.Y))));
    MovementDirection := WrapHeadingDegrees(MovementDirection + SeededRandomIntRange(-5, 5, (DockedTo.Seed + Seed + 234) * Galaxy.CurrentTurn * 4));
  end;
end;
{ @end $5B7218 }

{ @routine $5B7670 TShip_OrderFollowShip }
procedure TShip.OrderFollowShip(Ship: TShip; FollowMode: TFollowMode; Absolute: Boolean);
begin
  OrderNone;
  Order := soFollowShip;
  OrderTarget := Ship;
  OrderStateData := ReadByteValue(FollowMode);
  OrderAbsolute := Absolute;
end;
{ @end $5B7670 }

{ @routine $5B76B4 TShip_GetMovementPathTurnCount }
function TShip.GetMovementPathTurnCount: Integer;
begin
  if PlayerStar = CurrentStar then
    Result := Ceil(MovementPath.NodeCount * 0.005)
  else
    Result := Ceil(MovementPath.NodeCount * 0.1);
end;
{ @end $5B76B4 }

{ @routine $5B7718 TShip_PrepareTurnMovement }
procedure TShip.PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean);
var
  Distance, Angle: Double;
  Gate: PJumpGateEntry;
  EffectFilm: TEFilmObj;
  Owner: TShip;
  Point, TargetPosition: TPointF;
  Countdown: Integer;
  Node: PSPathNode;
begin
  FilmObject := nil;
  if RecordFilm and ((Order <> soNone) or not IsOnPlanet) and ((Order <> soNone) or not IsDockedToShip) then
  begin
    FilmObject := PrimaryFilm.AddObject(Id, Graphic);
    if not (Self is TRuins) then PrimaryFilm.SetShipSize(StartStepIndex, FilmObject, Graphic.Size);
  end;
  if Order = soNone then
  begin
    if RecordFilm and not IsOnPlanet and not IsDockedToShip then
    begin
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
    end;
  end
  else if Order = soMove then
  begin
    FilmAlpha := 255;
    FilmAlphaStep := 0;
    if RecordFilm then
    begin
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, OrderDestination, True);
    end;
  end
  else if (Order = soLanding) and (OrderTarget is TShip) then
  begin
    FilmAlpha := 510;
    FilmAlphaStep := 0;
    if RecordFilm then
    begin
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
    end;
    OrderStateData := 0;
    if MovementPath.ActiveHead <> nil then
    begin
      if ((PickupTargets = nil) or (PickupTargets.Count <= 0)) and
        (PointDistanceSquared(MovementPath.ActiveTail.Position, AddPointsF((OrderTarget as TShip).Position, OrderDestination)) <= 0) then
        begin
          if RecordFilm then
          begin
            FilmAlphaStep := -(FilmAlpha / MovementPath.NodeCount);
            PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
            if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
          end
          else FilmAlpha := 0;
          OrderStateData := 1;
        end;
    end
    else if RecordFilm then
    begin
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, (OrderTarget as TShip).Position, True);
    end;
  end
  else if Order = soLanding then
  begin
    FilmAlpha := 510;
    FilmAlphaStep := 0;
    if RecordFilm then
    begin
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
    end;
    OrderStateData := 0;
    if MovementPath.ActiveHead <> nil then
    begin
      if ((PickupTargets = nil) or (PickupTargets.Count <= 0)) and
        (PointDistanceSquared((OrderTarget as TPlanet).PredictPosition(MovementPath.NodeCount), MovementPath.ActiveTail.Position) < Sqr((OrderTarget as TPlanet).GraphicRadius)) then
        begin
          if RecordFilm then
          begin
            FilmAlphaStep := -(FilmAlpha / MovementPath.NodeCount);
            PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
            if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
          end
          else FilmAlpha := 0;
          OrderStateData := 1;
        end;
    end
    else if RecordFilm then
    begin
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, (OrderTarget as TPlanet).GetPosition, True);
    end;
  end
  else if Order = soJump then
  begin
    if not InHyperspace then
    begin
      FilmAlpha := 255;
      FilmAlphaStep := 0;
      if RecordFilm then
      begin
        PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
        PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
        PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
        PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      end;
      if (MovementPath.ActiveHead <> nil) and
        (PointDistanceSquared(MovementPath.ActiveHead.Position, MovementPath.ActiveTail.Position) > Sqr(Speed + 100)) then
      begin
        OrderDestination := MakePointF(0, 0);
        if RecordFilm then
        begin
          if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
          FilmAlphaStep := -(255 / MovementPath.NodeCount);
          if PlayerStar = CurrentStar then
          begin
            Point := MovementPath.ActiveHead.Position;
            Angle := MovementPath.ActiveHead.Heading;
            Node := MovementPath.ActiveHead.Next;
            while Node <> nil do
            begin
              if Abs(Angle - Node.Heading) < 0.001 then Break;
              Angle := Node.Heading;
              Point := Node.Position;
              Node := Node.Next;
            end;
            Gate := Galaxy.CreateJumpGate;
            Gate.Gate.SetPosition(MakePointF(Point.X + Sin(HeadingDegreesToRadians(Angle)) * 100, Point.Y - Cos(HeadingDegreesToRadians(Angle)) * 100));
            Gate.Gate.SetAngle(HeadingDegreesToByte(Angle) + 127);
            EffectFilm := PrimaryFilm.AddObject(0, Gate.Gate);
            PrimaryFilm.SetObjectPosition(StartStepIndex, EffectFilm, Gate.Gate.Position);
            PrimaryFilm.SetObjectAngle(StartStepIndex, EffectFilm, Gate.Gate.GetAngle);
            PrimaryFilm.SetGateState(StartStepIndex, EffectFilm, 0);
            PrimaryFilm.OpenGate(StartStepIndex, EffectFilm);
            if not (Self is TKling) then
              if Engine.JumpRange >= Round(PointDistance((OrderTarget as TStar).Position, CurrentStar.Position)) then
                PrimaryFilm.SetObjectText(StartStepIndex, EffectFilm, (OrderTarget as TStar).Name);
            PrimaryFilm.AttachObject(StartStepIndex, EffectFilm);
          end;
        end;
      end
      else if RecordFilm and (Self = Player) then PrimaryFilm.SetCameraAnchor(StartStepIndex, OrderDestination, False);
    end
    else
    begin
      FilmAlpha := 0;
      FilmAlphaStep := 0;
      Dec(OrderStateData);
      // Native tests the integral part of an unsigned conversion, not signed <= 0.
      if Int(Cardinal(OrderStateData)) <= 0 then
      begin
        InHyperspace := False;
        Angle := MovementDirection;
        Angle := HeadingDegreesToRadians(WrapHeadingDegrees(Angle + Abs(Integer(CurrentStar.GenerationSeed + Seed)) mod 10 - 5));
        Distance := -(CurrentStar.ComputeMapDiameter / 2 + 2500);
        Position.X := Sin(Angle) * Distance;
        Position.Y := -Cos(Angle) * Distance;
        MovementDirection := RadiansToHeadingDegrees(ArcTan2(-Position.X, -(-Position.Y)));
        Graphic.SetPosition(Position);
        Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
        OrderNone;
        Order := soMove;
        AppendHyperspaceTransitionPath(-1);
        if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position
        else OrderDestination := Position;
        if RecordFilm then
        begin
          FilmAlphaStep := 255 / MovementPath.NodeCount;
          PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
          PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
          PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 0);
          PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
          if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, True);
          if PlayerStar = CurrentStar then
          begin
            Distance := PointDistance(Position, OrderDestination);
            Gate := Galaxy.CreateJumpGate;
            Gate.Gate.SetPosition(MakePointF(OrderDestination.X + (Position.X - OrderDestination.X) / Distance * 100,
              OrderDestination.Y + (Position.Y - OrderDestination.Y) / Distance * 100));
            Gate.Gate.SetAngle(HeadingDegreesToByte(MovementDirection));
            EffectFilm := PrimaryFilm.AddObject(0, Gate.Gate);
            PrimaryFilm.SetObjectPosition(StartStepIndex, EffectFilm, Gate.Gate.Position);
            PrimaryFilm.SetObjectAngle(StartStepIndex, EffectFilm, Gate.Gate.GetAngle);
            PrimaryFilm.SetGateState(StartStepIndex, EffectFilm, 0);
            PrimaryFilm.OpenGate(StartStepIndex, EffectFilm);
            if (TransitOriginStar <> nil) and not (Self is TKling) then
              if Engine.JumpRange >= Round(PointDistance(TransitOriginStar.Position, CurrentStar.Position)) then
                PrimaryFilm.SetObjectText(StartStepIndex, EffectFilm, TransitOriginStar.Name);
            PrimaryFilm.AttachObject(StartStepIndex, EffectFilm);
          end;
          if Self = Player then
          begin
            PrimaryFilm.SetViewCenter(StartStepIndex, OrderDestination);
            PrimaryFilm.SetCameraAnchor(StartStepIndex, OrderDestination, False);
          end;
        end;
      end;
    end;
  end
  else if Order = soEnterBlackHole then
  begin
    if not InHyperspace then
    begin
      FilmAlpha := 510;
      FilmAlphaStep := 0;
      if RecordFilm then
      begin
        PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
        PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
        PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
        PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      end;
      if MovementPath.ActiveHead <> nil then
      begin
        if PointDistanceSquared(MovementPath.ActiveTail.Position, OrderDestination) <= 0 then
        begin
          if RecordFilm then
          begin
            FilmAlphaStep := -(FilmAlpha / MovementPath.NodeCount);
            PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
            if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
          end
          else FilmAlpha := 0;
        end;
      end
      else if RecordFilm then
      begin
        PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
        if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, OrderDestination, True);
      end;
    end
    else
    begin
      FilmAlpha := 0;
      FilmAlphaStep := 0;
      Countdown := OrderStateData and TravelDaysMask;
      Dec(Countdown);
      if (Self = KlingMotherShip) and (Countdown < 1) and (ScenarioState in [scenAllianceAgainstRachekhan..scenPeaceRachekhanDestroyed]) then Countdown := 1;
      OrderStateData := ((OrderStateData shr BlackHoleDirectionShift) shl BlackHoleDirectionShift) or Countdown;
      if Countdown <= 0 then
      begin
        InHyperspace := False;
        if OrderStateData shr BlackHoleDirectionShift = 0 then Point := THole(OrderTarget).Position2
        else Point := THole(OrderTarget).Position1;
        Position := Point;
        Angle := SeededRandomIntRange(0, 360, (Seed + CurrentStar.GenerationSeed + 1) * Galaxy.CurrentTurn) * Pi / 180;
        OrderDestination.X := Trunc(Point.X + Sin(Angle) * 400);
        OrderDestination.Y := Trunc(Point.Y + -Cos(Angle) * 400);
        MovementDirection := RadiansToHeadingDegrees(ArcTan2(-(OrderDestination.X - Point.X), -(-(OrderDestination.Y - Point.Y))));
        MovementDirection := WrapHeadingDegrees(MovementDirection + SeededRandomIntRange(-5, 5, (CurrentStar.GenerationSeed + Galaxy.CurrentTurn) * Seed * 4));
        OrderStateData := BlackHoleExitFlightState;
        OrderTarget := nil;
        BuildOrderMovementPath(1000);
        if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position
        else OrderDestination := Position;
        if RecordFilm then
        begin
          FilmAlphaStep := 1.275;
          PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
          PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
          PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 0);
          PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
          if Self = Player then
          begin
            PrimaryFilm.SetViewCenter(StartStepIndex, Position);
            PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
          end;
        end;
      end;
    end;
  end
  else if Order = soTakeoff then
  begin
    if RecordFilm then
    begin
      FilmAlpha := 0;
      FilmAlphaStep := 1.275;
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 0);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      if Self = Player then
      begin
        PrimaryFilm.SetViewCenter(StartStepIndex, Position);
        PrimaryFilm.SetCameraAnchor(StartStepIndex, Position, False);
      end;
    end;
    DockedTo := nil;
    CurrentPlanet := nil;
  end
  else if Order = soFollowShip then
  begin
    FilmAlpha := 255;
    FilmAlphaStep := 0;
    if RecordFilm then
    begin
      PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
      PrimaryFilm.SetObjectAngle(StartStepIndex, FilmObject, HeadingDegreesToByte(MovementDirection));
      PrimaryFilm.SetObjectAlpha(StartStepIndex, FilmObject, 255);
      PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
      if Self = Player then PrimaryFilm.SetCameraAnchor(StartStepIndex, (OrderTarget as TShip).Position, True);
    end;
    if (Self is TTranclucator) and (Self as TTranclucator).CanFollowOwnerInCurrentStar then
    begin
      Owner := (Self as TTranclucator).OwnerShip;
      if Owner.MovementPath.ActiveTail = nil then TargetPosition := Owner.Position
      else TargetPosition := Owner.MovementPath.ActiveTail.Position;
      if MovementPath.ActiveTail = nil then Point := Position
      else Point := MovementPath.ActiveTail.Position;
      if PointDistanceSquared(Point, TargetPosition) < 25 then
      begin
        if RecordFilm then
        begin
          if MovementPath.NodeCount < 1 then
          begin
            FilmAlpha := 0;
            FilmAlphaStep := 0;
          end
          else FilmAlphaStep := -(200 / MovementPath.NodeCount);
        end
        else FilmAlpha := 0;
      end;
    end;
  end
  else raise Exception.Create('Error');
  if RecordFilm and (Self = Player) then PrimaryFilm.SetRadarCenter(StartStepIndex, Position);
end;
{ @end $5B7718 }

{ @routine $5B8B8C TShip_ProcessMovementStep }
function TShip.ProcessMovementStep(StepIndex: Integer; RecordFilm: Boolean): Boolean;
var Node: PSPathNode; Angle: Byte;
begin
  Result := False;
  if IsHullDestroyed then Exit;
  if Order = soNone then Exit
  else if Order = soMove then begin
    if MovementPath.ActiveHead <> nil then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);

        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha < 0 then FilmAlpha := 0
        else if FilmAlpha > 255 then FilmAlpha := 255;
        PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
      if (Position.X = OrderDestination.X) and (Position.Y = OrderDestination.Y) then OrderNone;
    end;
  end else if Order = soLanding then begin
    if MovementPath.ActiveHead <> nil then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);
          if OrderStateData = 0 then begin
            if OrderTarget is TShip then PrimaryFilm.SetCameraAnchor(StepIndex, (OrderTarget as TShip).Position, True)
            else PrimaryFilm.SetCameraAnchor(StepIndex, (OrderTarget as TPlanet).GetPosition, True);
          end;
        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha <= 0 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 0)
        else if FilmAlpha >= 255 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 255)
        else PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
      if ((MovementPath.ActiveHead = nil) or (MovementPath.ActiveHead.Next = nil)) and (OrderStateData = 1) then begin
        if OrderTarget is TShip then DockedTo := OrderTarget as TShip
        else CurrentPlanet := OrderTarget as TPlanet;
        OrderNone;
        Engine.OutputPercent := 100;
        if RecordFilm then PrimaryFilm.DetachObject(StepIndex, FilmObject);
      end;
    end;
  end else if Order = soJump then begin
    if not InHyperspace and (MovementPath.ActiveHead <> nil) then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);

        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha < 0 then FilmAlpha := 0
        else if FilmAlpha > 255 then FilmAlpha := 255;
        PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
      if (OrderDestination.X = 0) and (OrderDestination.Y = 0) and (MovementPath.ActiveHead = nil) then begin
        InHyperspace := True;
        if RecordFilm then PrimaryFilm.DetachObject(StepIndex, FilmObject);
        ClearMovementPath;
        if (Self = Player) or (ShipType <> t_Ranger) or (PartnerShip = nil) or ((OrderTarget as TStar).ControlFaction <> sfKlissan) then
          FuelTanks.Fuel := FuelTanks.Fuel - Integer(Round(PointDistance((OrderTarget as TStar).Position, CurrentStar.Position)));
        if FuelTanks.Fuel < 0 then FuelTanks.Fuel := 0;
        RefreshDerivedStats;
        Galaxy.ShipsInTransit.Add(Self);
        CurrentStar.HandleObjectLeavingStar(Self);
      end;
    end;
  end else if Order = soEnterBlackHole then begin
    if (OrderStateData = BlackHoleExitFlightState) and (MovementPath.ActiveHead <> nil) then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);

        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha <= 0 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 0)
        else if FilmAlpha >= 255 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 255)
        else PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
    end else if not InHyperspace and (MovementPath.ActiveHead <> nil) then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);

        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha <= 0 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 0)
        else if FilmAlpha >= 255 then PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, 255)
        else PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
      if (FilmAlphaStep = 0) and (Self = Player) and RecordFilm then PrimaryFilm.SetCameraAnchor(StepIndex, OrderDestination, True);
      if (Position.X = OrderDestination.X) and (Position.Y = OrderDestination.Y) then begin
        if THole(OrderTarget).HoleType in [bhkOrdinary] then THole(OrderTarget).HoleType := bhkUsed;
        InHyperspace := True;
        if RecordFilm then PrimaryFilm.DetachObject(StepIndex, FilmObject);
        ClearMovementPath;
        Galaxy.ShipsInTransit.Add(Self);
        CurrentStar.HandleObjectLeavingStar(Self);
      end;
    end;
  end else if Order = soTakeoff then begin
    if MovementPath.ActiveHead <> nil then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);

        end;
      end;
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha < 0 then FilmAlpha := 0
        else if FilmAlpha > 255 then FilmAlpha := 255;
        PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
    end;
  end else if Order = soFollowShip then begin
    if MovementPath.ActiveHead <> nil then begin
      Node := MovementPath.ActiveHead;
      if RecordFilm then begin
        Angle := HeadingDegreesToByte(Node.Heading);
        if HeadingDegreesToByte(MovementDirection) <> Angle then PrimaryFilm.SetObjectAngle(StepIndex, FilmObject, Angle);
      end;
      Position := Node.Position;
      MovementDirection := Node.Heading;
      MovementPath.RemoveNode(MovementPath.ActiveHead);
      if RecordFilm then begin
        PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
      end;
      if RecordFilm then begin
        if Self = Player then begin
          PrimaryFilm.SetRadarCenter(StepIndex, Position);
          PrimaryFilm.SetCameraAnchor(StepIndex, (OrderTarget as TShip).Position, True);
        end;
      end;
      if RecordFilm then begin
      if (FilmAlphaStep <> 0) and RecordFilm then begin
        FilmAlpha := FilmAlpha + FilmAlphaStep;
        if FilmAlpha < 0 then FilmAlpha := 0
        else if FilmAlpha > 255 then FilmAlpha := 255;
        PrimaryFilm.SetObjectAlpha(StepIndex, FilmObject, Round(FilmAlpha));
      end;
      end;
    end;
  end else raise Exception.Create('Error');
end;
{ @end $5B8B8C }

{ @routine $5B98B8 TShip_CancelCompletedMovementOrder }
procedure TShip.CancelCompletedMovementOrder(StepIndex: Integer; RecordFilm: Boolean);
begin
  if not IsHullDestroyed then
    if Order = soTakeoff then OrderNone
    else if (Order = soEnterBlackHole) and (OrderStateData = BlackHoleExitFlightState) then OrderNone;
end;
{ @end $5B98B8 }

{ @routine $5B98F8 TShip_IsTravelCompletionPathReady }
function TShip.IsTravelCompletionPathReady: Boolean;
begin
  if Order = soJump then begin
    if InNormalSpace and (MovementPath.ActiveHead <> nil) and
      (PointDistanceSquared(MovementPath.ActiveHead.Position, MovementPath.ActiveTail.Position) > Sqr(Speed + 100)) then begin Result := True; Exit; end;
  end else if Order = soEnterBlackHole then begin
    if InNormalSpace and (OrderStateData <> BlackHoleExitFlightState) and (MovementPath.ActiveHead <> nil) and
      (PointDistanceSquared(MovementPath.ActiveTail.Position, OrderDestination) <= 0) then begin Result := True; Exit; end;
  end else if (Order = soLanding) and (OrderTarget is TShip) then begin
    if (MovementPath.ActiveHead <> nil) and
      (PointDistanceSquared(AddPointsF((OrderTarget as TShip).Position, OrderDestination), MovementPath.ActiveTail.Position) <= 0) then begin Result := True; Exit; end;
  end else if Order = soLanding then begin
    if (MovementPath.ActiveHead <> nil) and
      (PointDistanceSquared((OrderTarget as TPlanet).PredictPosition(MovementPath.NodeCount), MovementPath.ActiveTail.Position) < Sqr((OrderTarget as TPlanet).GraphicRadius)) then begin Result := True; Exit; end;
  end;
  Result := False;
end;
{ @end $5B98F8 }

{ @routine $5B9ABC TShip_RebuildOrderMovementPath }
procedure TShip.RebuildOrderMovementPath;
begin
  if PlayerStar = CurrentStar then BuildOrderMovementPath(200)
  else BuildOrderMovementPath(10);
end;
{ @end $5B9ABC }

{ @routine $5B9AE0 TShip_RebuildFollowMovementPath }
procedure TShip.RebuildFollowMovementPath;
begin
  ClearMovementPath;
  if PlayerStar = CurrentStar then AppendStarAvoidingPath(OrderDestination, 200)
  else AppendStarAvoidingPath(OrderDestination, 10);
  if MovementPath.ActiveTail <> nil then
    OrderDestination := MovementPath.ActiveTail.Position
  else OrderDestination := Position;
end;
{ @end $5B9AE0 }

{ @routine $5B9B54 TShip_BuildFullPathTo }
procedure TShip.BuildFullPathTo(Destination: TPointF);
begin
  ClearMovementPath;
  if MovementSpeed < 0.001 then Exit;
  AppendStarAvoidingPath(Destination, UnlimitedPathNodes);
end;
{ @end $5B9B54 }

{ @routine $5B9B9C TShip_BuildPlanetLandingPath }
procedure TShip.BuildPlanetLandingPath;
var
  Planet: TPlanet;
  Steps: Integer;
  Destination: TPointF;
begin
  ClearMovementPath;
  if MovementSpeed < 0.001 then Exit;
  if Order <> soLanding then Exit;
  Planet := OrderTarget as TPlanet;
  Steps := 0;
  while True do
  begin
    Inc(Steps, 200);
    if Steps > 10000 then Break;
    Destination := Planet.PredictPosition(Steps);
    AppendStarAvoidingPath(Destination, Steps);
    if MovementPath.ActiveTail = nil then Break;
    if PointDistanceSquared(MovementPath.ActiveTail.Position, Destination) < MovementSpeed * MovementSpeed then
    begin
      MovementPath.ActiveTail.Position := Destination;
      Break;
    end;
  end;
end;
{ @end $5B9B9C }

{ @routine $5B9C58 TShip_BuildOrderMovementPath }
procedure TShip.BuildOrderMovementPath(MaximumNodes: Integer);
var
  Planet: TPlanet;
  Hole: THole;
  Point: TPointF;
  Ship: TShip;
  Steps: Integer;
  Angle, Distance, Radius: Single;
  Node: PSPathNode;
begin
  MovementDirection := WrapHeadingDegrees(MovementDirection);
  ClearMovementPath;
  if MovementSpeed < 0.001 then Exit;
  if PlayerStar = CurrentStar then Steps := 200 else Steps := 10;
  if (Order = soLanding) and (OrderTarget is TShip) then
  begin
    Ship := OrderTarget as TShip;
    Point := Ship.Position;
    if PointDistanceSquared(Point, Position) > Sqr(200.0) then
    begin
      Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, Ship.Id + Seed));
      Distance := 100;
      Point.X := Point.X + Sin(Angle) * Distance;
      Point.Y := Point.Y + -Cos(Angle) * Distance;
      AppendStarAvoidingPathWithTurnPadding(Point, MaximumNodes);
    end
    else
    begin
      AppendStarAvoidingPathWithTurnPadding(AddPointsF(Point, OrderDestination), MaximumNodes);
      if MovementPath.ActiveHead = nil then
      begin
        OrderDestination := MakePointF(RandomIntRange(-5, 5), RandomIntRange(-5, 5));
        AppendStarAvoidingPathWithTurnPadding(AddPointsF(Point, OrderDestination), MaximumNodes);
      end;
    end;
  end
  else if Order = soLanding then
  begin
    Planet := OrderTarget as TPlanet;
    Point := Planet.PredictPosition(Steps);
    Angle := HeadingDegreesToRadians(WrapHeadingDegrees(PointBearingDegrees(Planet.GetPosition, Position) + SeededRandomIntRange(-20, 20, Seed + Planet.GenerationSeed)));
    Distance := Abs(Planet.GenerationSeed + Seed + CurrentStar.GenerationSeed) mod Planet.GraphicRadius;
    if Self = Player then Distance := Distance * 0.4 + Distance * 0.1
    else Distance := Distance * 0.6 + Distance * 0.1;
    if PointDistanceSquared(Planet.GetPosition, Position) > 62500 then Distance := Distance + Planet.GraphicRadius * 1.5;
    Point.X := Point.X + Sin(Angle) * Distance;
    Point.Y := Point.Y + -Cos(Angle) * Distance;
    if (Position.X <> Point.X) or (Position.Y <> Point.Y) then AppendStarAvoidingPathWithTurnPadding(Point, MaximumNodes);
  end
  else if Order = soEnterBlackHole then
  begin
    if OrderStateData = BlackHoleExitFlightState then AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes)
    else
    begin
      Hole := OrderTarget as THole;
      if OrderStateData shr BlackHoleDirectionShift = 0 then Point := Hole.Position1 else Point := Hole.Position2;
      if PointDistanceSquared(Point, Position) > Sqr(200.0) then
      begin
        Angle := HeadingDegreesToRadians(WrapHeadingDegrees(PointBearingDegrees(Point, Position) + SeededRandomIntRange(-20, 20, Hole.Id + Seed)));
        Distance := 100;
        Point.X := Point.X + Sin(Angle) * Distance;
        Point.Y := Point.Y + -Cos(Angle) * Distance;
        AppendStarAvoidingPathWithTurnPadding(Point, MaximumNodes);
      end
      else AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes);
    end;
  end
  else if Order = soFollowShip then
  begin
    Ship := OrderTarget as TShip;
    Radius := CalculateFollowRadius;
    if Ship.MovementPath.ActiveHead = nil then
    begin
      AppendStarAvoidingPathWithTurnPadding(PointBehindHeading(Ship.Position, Ship.MovementDirection, Radius, Abs(Ship.Seed + Seed)), MaximumNodes);
      if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position else OrderDestination := Position;
    end
    else begin
    if Ship.MovementPath.NodeCount <= Steps then
    begin
      AppendStarAvoidingPathWithTurnPadding(PointBehindHeading(Ship.MovementPath.ActiveTail.Position, Ship.MovementPath.ActiveTail.Heading, Radius, Abs(Ship.Seed + Seed)), MaximumNodes);
      if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position else OrderDestination := Position;
    end
    else
    begin
      Node := (Ship).MovementPath.GetFollowingNode(
        (Ship).MovementPath.ActiveHead, Steps - 1);
      AppendStarAvoidingPathWithTurnPadding(PointBehindHeading(Node.Position, Node.Heading, Radius, Abs(Ship.Seed + Seed)), MaximumNodes);
      if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position else OrderDestination := Position;
    end;
  end
  end
  else if Order = soJump then
  begin
    Radius := CurrentStar.ComputeMapDiameter / 2 - 400;
    Radius := Radius * Radius;
    if Position.X * Position.X + Position.Y * Position.Y > Radius then
    begin
      if Abs(HeadingDifferenceDegrees(PointBearingDegrees(CurrentStar.Position, (OrderTarget as TStar).Position), PointBearingDegrees(MakePointF(0, 0), Position))) <= 5 then
      begin
        Angle := Abs(HeadingDifferenceDegrees(MovementDirection, RadiansToHeadingDegrees(ArcTan2(-Position.X, Position.Y))));
        if (((Angle >= 125) and (Speed > 200)) or (Angle >= 175)) and
          ((MaximumNodes > 400) or (PickupTargets = nil) or (PickupTargets.Count <= 0)) then
        begin
          if (Angle < 175) and (Speed >= 200) and (PlayerStar = CurrentStar) then
          begin
            Distance := 1 / Sqrt(Position.X * Position.X + Position.Y * Position.Y);
            Point.X := Position.X + Position.X * Distance * 10000;
            Point.Y := Position.Y + Position.Y * Distance * 10000;
            AppendTurningPath(Point, False, MaximumNodes);
          end;
          AppendHyperspaceTransitionPath(1);
          if MovementPath.ActiveTail <> nil then OrderDestination := MovementPath.ActiveTail.Position else OrderDestination := Position;
        end
        else
        begin
          Distance := 1 / Sqrt(Position.X * Position.X + Position.Y * Position.Y);
          OrderDestination.X := Position.X + Position.X * Distance * Max(250, Speed * 0.25);
          OrderDestination.Y := Position.Y + Position.Y * Distance * Max(250, Speed * 0.25);
          AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes);
        end;
      end
      else AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes);
    end
    else AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes);
  end
  else if (Order = soMove) or (Order = soJump) or (Order = soTakeoff) then
    AppendStarAvoidingPathWithTurnPadding(OrderDestination, MaximumNodes);
end;
{ @end $5B9C58 }

{ @routine $5BA618 TShip_AppendPathToWithTurnPadding }
procedure TShip.AppendPathToWithTurnPadding(Destination: TPointF; MaximumNodes: Integer);
var
  Step: Single;
begin
  AppendTurningPath(Destination, False, MaximumNodes);
  AppendStraightPath(Destination, MaximumNodes);
  if (PlayerStar = CurrentStar) and (MovementPath.NodeCount < 200) and
    ((Player.CurrentPlanet = nil) or ((Player.CurrentPlanet <> nil) and (Player.Order = soTakeoff))) then
    MovementPath.ResampleBezierRange(MovementPath.ActiveHead, MovementPath.ActiveTail, 200);
  if PlayerStar = CurrentStar then Step := MovementSpeed else Step := MovementSpeedPerTurn;
  if MovementPath.ActiveHead <> nil then
  begin
    if PointDistanceSquared(MovementPath.ActiveTail.Position, Destination) < Step * Step then
      MovementPath.ActiveTail.Position := Destination;
  end;
end;
{ @end $5BA618 }

{ @routine $5BA708 TShip_AppendPathTo }
procedure TShip.AppendPathTo(Destination: TPointF; MaximumNodes: Integer);
var
  Step: Single;
begin
  AppendTurningPath(Destination, False, MaximumNodes);
  AppendStraightPath(Destination, MaximumNodes);
  if PlayerStar = CurrentStar then Step := MovementSpeed else Step := MovementSpeedPerTurn;
  if MovementPath.ActiveHead <> nil then
  begin
    if PointDistanceSquared(MovementPath.ActiveTail.Position, Destination) < Step * Step then
      MovementPath.ActiveTail.Position := Destination;
  end;
end;
{ @end $5BA708 }

{ @routine $5BA79C TShip_AppendStarAvoidingPathWithTurnPadding }
procedure TShip.AppendStarAvoidingPathWithTurnPadding(Destination: TPointF; MaximumNodes: Integer);
var
  Step: Single;
begin
  AppendStarAvoidingPath(Destination, MaximumNodes);
  if (PlayerStar = CurrentStar) and (MovementPath.NodeCount < 200) and
    ((Player.CurrentPlanet = nil) or ((Player.CurrentPlanet <> nil) and (Player.Order = soTakeoff))) then
    MovementPath.ResampleBezierRange(MovementPath.ActiveHead, MovementPath.ActiveTail, 200);
  if PlayerStar = CurrentStar then Step := MovementSpeed else Step := MovementSpeedPerTurn;
  if MovementPath.ActiveHead <> nil then
  begin
    if PointDistanceSquared(MovementPath.ActiveTail.Position, Destination) < Step * Step then
      MovementPath.ActiveTail.Position := Destination;
  end;
end;
{ @end $5BA79C }

{ @routine $5BA878 TShip_AppendTurningPath }
procedure TShip.AppendTurningPath(Destination: TPointF; AvoidStar: Boolean; MaximumNodes: Integer);
var
  Node: PSPathNode;
  Point, Output: TPointF;
  TurnStep, Step, Angle, TargetAngle, Difference, TurnSign, TangentStep: Double;
  PreviousRadiusSquared, MiddleRadiusSquared, RadiusSquared: Double;
  StartRadialAngle, EndRadialAngle, ArcStart, ArcEnd: Single;
begin
  if MovementPath.ActiveTail = nil then
  begin
    Point := Position;
    Angle := MovementDirection;
  end
  else
  begin
    Point := MovementPath.ActiveTail.Position;
    Angle := MovementPath.ActiveTail.Heading;
  end;
  if (Point.X = Destination.X) and (Point.Y = Destination.Y) then Exit;
  if PlayerStar = CurrentStar then begin
    TurnStep := MovementTurnRate;
    Step := MovementSpeed;
  end else begin
    TurnStep := MovementTurnRatePerTurn;
    Step := MovementSpeedPerTurn;
  end;
  if (Order = soTakeoff) or ((Order = soEnterBlackHole) and (OrderStateData = BlackHoleExitFlightState)) then
  begin
    Step := Step / 2;
    TurnStep := TurnStep / 2;
  end;
  // The native code compares squared distance with the unsquared step here.
  if PointDistanceSquared(Point, Destination) < Step then
  begin
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Point;
    Node.Heading := Angle;
    Exit;
  end;
  TargetAngle := RadiansToHeadingDegrees(ArcTan2(-(Point.X - Destination.X), Point.Y - Destination.Y));
  TurnSign := HeadingDifferenceDegrees(Angle, TargetAngle);
  if Abs(TurnSign) < TurnStep then Exit;
  if AvoidStar then
  begin
    StartRadialAngle := RadiansToHeadingDegrees(ArcTan2(Point.X, -Point.Y));
    EndRadialAngle := RadiansToHeadingDegrees(ArcTan2(Destination.X, -Destination.Y));
    if HeadingDifferenceDegrees(StartRadialAngle, EndRadialAngle) <= 0 then
    begin
      ArcStart := RadiansToHeadingDegrees(ArcTan2(-Point.X, Point.Y));
      ArcEnd := RadiansToHeadingDegrees(ArcTan2(Destination.X - Point.X, -(Destination.Y - Point.Y)));
      if HeadingWithinArc(ArcStart, Angle, ArcEnd) then TurnSign := 1 else TurnSign := -1;
    end
    else
    begin
      ArcStart := RadiansToHeadingDegrees(ArcTan2(-Point.X, Point.Y));
      ArcEnd := RadiansToHeadingDegrees(ArcTan2(Destination.X - Point.X, -(Destination.Y - Point.Y)));
      if HeadingWithinArc(ArcStart, Angle, ArcEnd) then TurnSign := -1 else TurnSign := 1;
    end;
  end;
  MiddleRadiusSquared := -1;
  RadiusSquared := -1;
  TangentStep := CalculateTangentArcOffset(Point, Destination, Angle, TurnStep);
  if TangentStep < Step then Step := TangentStep;
  while (Point.X <> Destination.X) or (Point.Y <> Destination.Y) do
  begin
    if AvoidStar then
    begin
      PreviousRadiusSquared := MiddleRadiusSquared;
      MiddleRadiusSquared := RadiusSquared;
      RadiusSquared := Point.X * Point.X + Point.Y * Point.Y;
      if (PreviousRadiusSquared <> -1) and (PreviousRadiusSquared < MiddleRadiusSquared) and (RadiusSquared < MiddleRadiusSquared) then Break;
    end;
    TargetAngle := RadiansToHeadingDegrees(ArcTan2(-(Point.X - Destination.X), Point.Y - Destination.Y));
    Difference := HeadingDifferenceDegrees(Angle, TargetAngle);
    if Abs(Difference) <= TurnStep then Break;
    if TurnSign > 0 then Angle := WrapHeadingDegrees(Angle + TurnStep)
    else Angle := WrapHeadingDegrees(Angle - TurnStep);
    Point.X := Point.X + Sin(HeadingDegreesToRadians(Angle)) * Step;
    Point.Y := Point.Y - Cos(HeadingDegreesToRadians(Angle)) * Step;
    if (Point.X - Destination.X) * (Point.X - Destination.X) + (Point.Y - Destination.Y) * (Point.Y - Destination.Y) <= Step * Step then
      Point := Destination;
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Point;
    Node.Heading := Angle;
    if MovementPath.NodeCount >= MaximumNodes then Break;
  end;
end;
{ @end $5BA878 }

{ @routine $5BADB8 TShip_AppendStraightPath }
procedure TShip.AppendStraightPath(Destination: TPointF; MaximumNodes: Integer);
var
  UseY: Boolean;
  Distance, Travelled, Slope, Scale, Origin, Heading: Double;
  Output: TPointF;
  Point: TPointF;
  Node: PSPathNode;
  Step: Double;
begin
  if MovementPath.ActiveTail = nil then Point := Position else Point := MovementPath.ActiveTail.Position;
  if (Point.X = Destination.X) and (Point.Y = Destination.Y) then Exit;
  if PlayerStar = CurrentStar then Step := MovementSpeed else Step := MovementSpeedPerTurn;
  if (Order = soTakeoff) or ((Order = soEnterBlackHole) and (OrderStateData = BlackHoleExitFlightState)) then Step := Min(2, Step / 2);
  Heading := RadiansToHeadingDegrees(ArcTan2(-(Point.X - Destination.X), Point.Y - Destination.Y));
  if Abs(Point.X - Destination.X) < Abs(Point.Y - Destination.Y) then UseY := True else UseY := False;
  Distance := Sqrt((Point.X - Destination.X) * (Point.X - Destination.X) + (Point.Y - Destination.Y) * (Point.Y - Destination.Y));
  if UseY then
  begin
    Slope := (Destination.X - Point.X) / (Destination.Y - Point.Y);
    Scale := 1 / Sqrt(Slope * Slope + 1);
    if Destination.Y - Point.Y < 0 then Scale := -Scale;
    Origin := Point.Y;
  end
  else
  begin
    Slope := (Destination.Y - Point.Y) / (Destination.X - Point.X);
    Scale := 1 / Sqrt(Slope * Slope + 1);
    if Destination.X - Point.X < 0 then Scale := -Scale;
    Origin := Point.X;
  end;
  Travelled := Step;
  if Travelled >= Distance then
  begin
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Destination;
    Node.Heading := Heading;
    Exit;
  end;
  while Travelled < Distance do
  begin
    if UseY then
    begin
      Output.Y := Origin + Travelled * Scale;
      Output.X := Point.X + (Output.Y - Point.Y) * Slope;
    end
    else
    begin
      Output.X := Origin + Travelled * Scale;
      Output.Y := Point.Y + (Output.X - Point.X) * Slope;
    end;
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Output;
    Node.Heading := Heading;
    if MovementPath.NodeCount >= MaximumNodes then Break;
    Travelled := Travelled + Step;
  end;
end;
{ @end $5BADB8 }

{ @routine $5BB0D4 TShip_AppendHyperspaceTransitionPath }
procedure TShip.AppendHyperspaceTransitionPath(Direction: Single);
var
  Point: TPointF;
  Heading, Speed, Increment, SinHeading, CosHeading, Minimum, Maximum: Single;
  Count, I: Integer;
  Node: PSPathNode;
begin
  I := 0;
  if MovementPath.ActiveTail = nil then
  begin
    Point := Position;
    Heading := MovementDirection;
  end
  else
  begin
    Point := MovementPath.ActiveTail.Position;
    Heading := MovementPath.ActiveTail.Heading;
    if PlayerStar = CurrentStar then I := Min(100, MovementPath.NodeCount mod 200);
  end;
  if PlayerStar = CurrentStar then begin
    Count := 200;
    Minimum := MovementSpeed;
  end else begin
    Count := 10;
    Minimum := MovementSpeedPerTurn;
  end;
  Maximum := 5000 / (Count - I);
  if Direction > 0 then
  begin
    Speed := Minimum;
    Increment := (Maximum - Minimum) / (Count - I);
  end
  else
  begin
    Speed := Maximum;
    Increment := -((Maximum - Minimum) / (Count - I));
  end;
  SinHeading := Sin(HeadingDegreesToRadians(Heading));
  CosHeading := Cos(HeadingDegreesToRadians(Heading));
  Speed := Speed + Increment;
  while (Speed > Minimum) and (Speed < Maximum) do
  begin
    Point.X := Point.X + SinHeading * Speed;
    Point.Y := Point.Y - CosHeading * Speed;
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Point;
    Node.Heading := Heading;
    Speed := Speed + Increment;
  end;
end;
{ @end $5BB0D4 }

{ @routine $5BB270 TShip_AppendStarAvoidingPath }
procedure TShip.AppendStarAvoidingPath(Destination: TPointF; MaximumNodes: Integer);
var
  Point: TPointF;
  Radius: Double;
  StartTangent, OtherStartTangent, EndTangent, OtherEndTangent, PreviousTangent: TPointF;
begin
  if MovementPath.ActiveTail = nil then Point := Position else Point := MovementPath.ActiveTail.Position;
  if PlayerStar = CurrentStar then;
  Radius := CurrentStar.SafeRadius;
  Point := PushPointOutsideCircleBand(Point, Radius, 2);
  if not SegmentCrossesOriginCircle(Point, Destination, Radius) then
  begin
    if MaximumNodes < 20 then AppendPathTo(Destination, MaximumNodes)
    else AppendPathToWithTurnPadding(Destination, MaximumNodes);
  end
  else
  begin
    CircleTangentPoints(Point, Radius, StartTangent, OtherStartTangent);
    CircleTangentPoints(Destination, Radius, EndTangent, OtherEndTangent);
    if PointDistanceSquared(StartTangent, OtherEndTangent) < PointDistanceSquared(OtherStartTangent, EndTangent) then
      EndTangent := OtherEndTangent
    else StartTangent := OtherStartTangent;
    if Point.X * Point.X + Point.Y * Point.Y < (Radius * 2) * (Radius * 2) then
    begin
      AppendTurningPath(StartTangent, True, MaximumNodes);
      if MovementPath.NodeCount >= MaximumNodes then Exit;
      if MovementPath.ActiveTail = nil then Point := Position else Point := MovementPath.ActiveTail.Position;
      Point := PushPointOutsideCircleBand(Point, Radius, 2);
      if not SegmentCrossesOriginCircle(Point, Destination, Radius) then
      begin
        AppendPathTo(Destination, MaximumNodes);
        Exit;
      end;
      if Round(Point.X * Point.X + Point.Y * Point.Y) < Round(Radius * Radius) then
      begin
        if MaximumNodes < 20 then AppendPathTo(Destination, MaximumNodes)
        else AppendPathToWithTurnPadding(Destination, MaximumNodes);
        Exit;
      end;
      PreviousTangent := StartTangent;
      CircleTangentPoints(Point, Radius, StartTangent, OtherStartTangent);
      CircleTangentPoints(Destination, Radius, EndTangent, OtherEndTangent);
      if PointDistanceSquared(StartTangent, PreviousTangent) > PointDistanceSquared(OtherStartTangent, PreviousTangent) then
        StartTangent := OtherStartTangent;
      if PointDistanceSquared(StartTangent, OtherEndTangent) < PointDistanceSquared(StartTangent, EndTangent) then
        EndTangent := OtherEndTangent;
      AppendPathTo(StartTangent, MaximumNodes);
      if MovementPath.NodeCount >= MaximumNodes then Exit;
    end
    else
    begin
      AppendPathTo(StartTangent, MaximumNodes);
      if MovementPath.NodeCount >= MaximumNodes then Exit;
    end;
    AppendCircularDetour(EndTangent, MaximumNodes, Radius);
    if MovementPath.NodeCount >= MaximumNodes then Exit;
    AppendStraightPath(Destination, MaximumNodes);
  end;
end;
{ @end $5BB270 }

{ @routine $5BB600 TShip_AppendCircularDetour }
procedure TShip.AppendCircularDetour(Destination: TPointF; MaximumNodes: Integer; Radius: Double);
var
  Node: PSPathNode;
  Point: TPointF;
  FromHeading, Heading, ToHeading, Step, Difference, DistancePerStep: Double;
begin
  if MovementPath.ActiveTail = nil then Point := Position else Point := MovementPath.ActiveTail.Position;
  FromHeading := RadiansToHeadingDegrees(ArcTan2(Point.X, -Point.Y));
  ToHeading := RadiansToHeadingDegrees(ArcTan2(Destination.X, -Destination.Y));
  if CurrentStar = PlayerStar then DistancePerStep := MovementSpeed else DistancePerStep := MovementSpeedPerTurn;
  Step := DistancePerStep * 180 / (3.1415926 * Radius);
  Difference := HeadingDifferenceDegrees(FromHeading, ToHeading);
  if Difference < 0 then Step := -Step;
  if Abs(Difference) <= 5 then
  begin
    AppendPathTo(Destination, MaximumNodes);
    Exit;
  end;
  while FromHeading <> ToHeading do
  begin
    FromHeading := FromHeading + Step;
    if FromHeading < 0 then FromHeading := 360 + FromHeading;
    if FromHeading >= 360 then FromHeading := FromHeading - 360;
    if Abs(HeadingDifferenceDegrees(FromHeading, ToHeading)) < Abs(Step) then FromHeading := ToHeading;
    Point.X := Sin(HeadingDegreesToRadians(FromHeading)) * Radius;
    Point.Y := -Cos(HeadingDegreesToRadians(FromHeading)) * Radius;
    if Step < 0 then Heading := FromHeading - 90 else Heading := FromHeading + 90;
    if Heading < 0 then Heading := 360 + Heading;
    if Heading >= 360 then Heading := Heading - 360;
    MovementPath.AppendNode;
    Node := MovementPath.ActiveTail;
    Node.Position := Point;
    Node.Heading := Heading;
    if MovementPath.NodeCount >= MaximumNodes then Break;
  end;
end;
{ @end $5BB600 }

{ @routine $5BB89C TShip_ClearMovementPath }
procedure TShip.ClearMovementPath;
begin
  MovementPath.Clear;
end;
{ @end $5BB89C }

{ @routine $5BB8A8 TShip_GetSlotCountForItemType }
function TShip.GetSlotCountForItemType(ItemType: TItemType): Integer;
begin
  if IsWeaponItemType(ItemType) then Result := 5 else Result := 1;
end;
{ @end $5BB8A8 }

{ @routine $5BB8C4 TShip_ReassignActiveItemSlots }
procedure TShip.ReassignActiveItemSlots(ItemType: TItemType);
var Used: Cardinal; Count, I, J, Slot: Integer; Item: TEquipment;
begin
  Used := 0;
  Count := GetSlotCountForItemType(ItemType);
  for I := 0 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    if Item.EquippedFlag and
      (((ItemType = Item.ItemType) and not IsWeaponItemType(ItemType)) or
        (IsWeaponItemType(ItemType) and IsWeaponItemType(Item.ItemType))) then begin
        Slot := Item.AssignedSlotData and $7F;
        if (Slot < 0) or (Slot >= Count) or ((Used shr Slot) and 1 = 1) then begin
          Item.EquippedFlag := False;
          for J := 0 to Count - 1 do
            if (Used shr J) and 1 = 0 then begin
              Item.AssignedSlotData := (Item.AssignedSlotData and $80) or J;
              Used := Used or (1 shl J);
              Item.EquippedFlag := True;
              Break;
            end;
        end else Used := Used or (1 shl (Item.AssignedSlotData and $7F));
      end;
  end;
end;
{ @end $5BB8C4 }

{ @routine $5BB9D0 TShip_RefreshAssignedItemSlots }
procedure TShip.RefreshAssignedItemSlots;
begin
  ReassignActiveItemSlots(t_FuelTanks);
  ReassignActiveItemSlots(t_Engine);
  ReassignActiveItemSlots(t_Radar);
  ReassignActiveItemSlots(t_Scaner);
  ReassignActiveItemSlots(t_RepairRobot);
  ReassignActiveItemSlots(t_CargoHook);
  ReassignActiveItemSlots(t_DefGenerator);
  ReassignActiveItemSlots(WeaponCategoryItemType);
  RefreshInactiveItemSlotAssignments;
end;
{ @end $5BB9D0 }

{ @routine $5BBA24 TShip_FindEquippedItemInSlot }
function TShip.FindEquippedItemInSlot(ItemType: TItemType; SlotIndex: Integer): TEquipment;
var I: Integer; Item: TEquipment;
begin
  for I := 0 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    if (Item.EquippedFlag) and
      (((ItemType = Item.ItemType) and not IsWeaponItemType(ItemType)) or
      (IsWeaponItemType(ItemType) and IsWeaponItemType(Item.ItemType))) and
      (Integer(Item.AssignedSlotData) and $7F = SlotIndex) then begin
      Result := Item;
      Exit;
    end;
  end;
  Result := nil;
end;
{ @end $5BBA24 }

{ @routine $5BBAA4 TShip_RefreshInactiveItemSlotAssignments }
procedure TShip.RefreshInactiveItemSlotAssignments;
var
  I, Count: Integer;
  Item: TEquipment;
begin
  Count := Inventory.Count;
  for I := Count - 1 downto 0 do begin
    Item := Inventory[I];
    if not Item.EquippedFlag then
      if CountUnequippedItemsInSlot(Item.AssignedSlotData and $7F) > 1 then
        Item.AssignedSlotData := FindFreeUnequippedSlot or (Item.AssignedSlotData and $80);
  end;
end;
{ @end $5BBAA4 }

{ @routine $5BBB00 TShip_CountUnequippedItemsInSlot }
function TShip.CountUnequippedItemsInSlot(SlotIndex: Integer): Integer;
var I, Count, Found: Integer; Item: TEquipment;
begin
  Found := 0;
  Count := Inventory.Count;
  for I := 0 to Count - 1 do begin
    Item := Inventory[I];
    if (not Item.EquippedFlag) and (Integer(Item.AssignedSlotData and $7F) = SlotIndex) then Inc(Found);
  end;
  Result := Found;
end;
{ @end $5BBB00 }

{ @routine $5BBB4C TShip_FindFreeUnequippedSlot }
function TShip.FindFreeUnequippedSlot: Integer;
var SlotIndex: Integer;
begin
  SlotIndex := 0;
  while CountUnequippedItemsInSlot(SlotIndex) > 0 do Inc(SlotIndex);
  Result := SlotIndex;
end;
{ @end $5BBB4C }

{ @routine $5BBB68 TShip_UseArtefact }
function TShip.UseArtefact(Item: TArtefact): Boolean;
var
  Other: TArtefact;
  I, J, Summoned: Integer;
  Star: TStar;
  TotalStrength: Single;
  Ship: TShip;
begin
  if Item.ItemType in [t_ArtefactHull..t_ArtefactAntigrav] then begin
    if FindEquippedArtefact(Item.ItemType, Other, True) then begin
      if Item = Other then begin
        Item.Unequip;
        Result := False;
        Exit;
      end;
      Other.Unequip;
      Item.Equip;
    end else Item.Equip;
    RefreshDerivedStats;
    Result := True;
    Exit;
  end;
  if Item.ItemType = t_ArtefactTranclucator then begin
    Artefacts.Delete(Artefacts.IndexOf(Item));
    Item.Position := Position;
    QueueMovingItemDrop(Item, 1);
    RefreshDerivedStats;
    Result := True;
    Exit;
  end;
  if Item.ItemType = t_ArtefactTransmitter then
    if (Item as TArtefactTransmitter).Charges > 0 then begin
      Summoned := 0;
      TotalStrength := 0;
      for I := 1 to Galaxy.Stars.Count - 1 do begin
        Star := CurrentStar.StarDistances[I].Star as TStar;
        if Star.ControlFaction = sfKlissan then begin
          if Star.Battle or IsFinalScenarioActive then Continue;
          for J := 0 to Star.Ships.Count - NextRandomIntRange(3, 5, RandomState) do begin
            Ship := Star.Ships[J];
            if Ship.OwnerId = oiKling then begin
              if not (Ship.Order in [soNone,soMove]) then Continue;
              Ship.OrderJump(CurrentStar, True);
              Inc(Summoned);
              TotalStrength := TotalStrength + Ship.StrengthInBestRanger;
            end;
          end;
          if (NextRandomIntRange(12, 16, RandomState) < Summoned) or ((Summoned > 10) and (TotalStrength > 10)) then Break;
        end;
      end;
      Dec((Item as TArtefactTransmitter).Charges, Min((Item as TArtefactTransmitter).Charges, NextRandomIntRange(35, 70, RandomState)));
      Result := True;
      Exit;
    end;
  Result := False;
end;
{ @end $5BBB68 }

{ @routine $5BBDA8 TShip_HasArtefact }
function TShip.HasArtefact(Kind: TItemType): Boolean;
var I: Integer; Item: TArtefact;
begin
  Result := False;
  for I := 0 to Artefacts.Count - 1 do begin
    Item := Artefacts[I];
    if Kind = Item.ItemType then begin
      Result := True;
      Exit;
    end;
  end;
end;
{ @end $5BBDA8 }

{ @routine $5BBDEC TShip_HasActiveArtefact }
function TShip.HasActiveArtefact(Kind: TItemType): Boolean;
var I: Integer; Item: TArtefact;
begin
  Result := False;
  for I := 0 to Artefacts.Count - 1 do begin
    Item := Artefacts[I];
    if (Kind = Item.ItemType) and not Item.BrokenFlag and Item.EquippedFlag then begin
      Result := True;
      Exit;
    end;
  end;
end;
{ @end $5BBDEC }

{ @routine $5BBE3C TShip_FindEquippedArtefact }
function TShip.FindEquippedArtefact(Kind: TItemType; var Item: TArtefact; RequireWorking: Boolean): Boolean;
var I: Integer;
begin
  Result := False;
  for I := 0 to Artefacts.Count - 1 do begin
    Item := Artefacts[I];
    if (Item.ItemType = Kind) and (not RequireWorking or not Item.BrokenFlag) and Item.EquippedFlag then begin
      Result := True;
      Exit;
    end;
  end;
  Item := nil;
end;
{ @end $5BBE3C }

{ @routine $5BBEB4 TShip_ApplyNanoArtefactRepair }
procedure TShip.ApplyNanoArtefactRepair;
var Attempts: Integer; Item: TEquipment;
begin
  if Inventory.Count < 2 then RaiseWideMessage('Not equipments in ship' + GetName);
  Attempts := 0;
  Item := nil;
  case Integer(Item) of 0: ; end;
  repeat
    Inc(Attempts);
    if Attempts > 30 then Exit;
    Item := Inventory[SeededRandomIntRange(1, Inventory.Count - 1, Integer(Galaxy.GenerationSeed) + Galaxy.CurrentTurn + Attempts)];
  until (Item.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) and (Item.ConditionPercent <= 60);
  Item.ConditionPercent := Item.ConditionPercent + 5 / OwnerInfo[Item.OwnerId].FuelPriceFactor;
  if Item.ConditionPercent > 100 then Item.ConditionPercent := 100;
  if (Item.ConditionPercent > 0) and Item.BrokenFlag then begin
    Item.BrokenFlag := False;
    if Self = Player then
      AddOrUpdatePlayerBubble(pmShip, Galaxy.CurrentTurn,
        FormatText1(LocalizedText('Items.ArtefactNano.RepairItem'), HighlightColorTag, '<Name>', Item.GetDisplayName), '').TargetIds[0] := Id;
  end;

end;
{ @end $5BBEB4 }

{ @routine $5BC128 TShip_IsOutsideExtortionRange }
function TShip.IsOutsideExtortionRange(Ship: TShip): Boolean;
begin
  Result := Max(GetRadarRange * GetRadarRange, 250000) < PointDistanceSquared(Position, Ship.Position);
end;
{ @end $5BC128 }

{ @routine $5BC178 TShip_LookupTalkText }
function TShip.LookupTalkText(const Path: WideString): WideString;
var Count, I: Integer; Variants: array[0..9] of WideString;

begin
  Count := 0;
  Variants[Count] := LocalizedText(Path);
  if Variants[Count] <> '' then Inc(Count);
  I := 1;
  repeat
    Variants[Count] := LocalizedText(Path + IntToStr(Count));
    if Variants[Count] <> '' then Inc(Count);
    Inc(I);
  until I > 9;
  if Count = 0 then
  begin
    Result := 'String: ' + WrapTextInColor(Path, HighlightColorTag) + ' is unavailable';
    Exit;
  end;

  if Count = 1 then Result := Variants[0]
  else
  begin
    Count := SeededRandomIntRange(0, Count - 1, (Galaxy.CurrentTurn + Integer(Seed)) div 10);
    Result := Variants[Count];
  end;
  if HomePlanet <> nil then Result := ReplaceColoredToken(Result, '<HomePlanet>', HomePlanet.Name, HighlightColorTag);
  Result := ReplaceColoredToken(Result, '<Ship>', GetName, HighlightColorTag);
  Result := ReplaceColoredToken(Result, '<FullShip>', GetFullName(' '), HighlightColorTag);
end;
{ @end $5BC178 }

{ @routine $5BC450 TShip_RequestPlayerDialogue }
function TShip.RequestPlayerDialogue: Boolean;
begin
  if ExitScreenLoop or not Player.InNormalSpace or (Player.CurrentStar <> CurrentStar) or
    (TurnCalculationPhase = 2) or (TurnCalculationPhase = 4) or (TurnCalculationPhase = 6) then
  begin
    Result := False;
    Exit;
  end;
  TalkShip := Self;
  TalkPlanet := nil;
  TalkScripted := True;
  ResetEvent(TalkCompletedEvent);
  SetEvent(TalkRequestEvent);
  if WaitForSingleObject(TalkCompletedEvent, INFINITE) <> WAIT_OBJECT_0 then
  begin
    Result := False;
    TalkScripted := False;
    Exit;
  end;
  TalkScripted := False;
  PlayerStar.PlayerInteractionOccurred := True;
  Sleep(10);
  Result := True;
end;
{ @end $5BC450 }

{ @routine $5BC510 TShip_ShowPlayerDialogue }
function TShip.ShowPlayerDialogue(Kind: Byte; const Text: WideString; Amount: Integer): Byte;
begin
  TalkScriptedKind := Kind;
  if Amount > 0 then TalkScriptedAmount := Amount;
  TalkScriptedAccepted := False;
  ScriptedTalkText := Text;
  if not RequestPlayerDialogue then Result := 0
  else Result := Byte(TalkScriptedAccepted);
end;
{ @end $5BC510 }

{ @routine $5BC560 TShip_NotifyMoneyDemand }
procedure TShip.NotifyMoneyDemand(OtherShip: TShip; Response: WideString; Amount: Integer);
var Header, Request: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  Header := HighlightColorTag + GetFullName(' ') + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + OtherShip.GetFullName(' ') + ColorEndTag;
  Request := '- ' + ReplaceColoredToken(LookupTalkText('Talk.Money.Send'), '<Money>', IntToStr(Amount), HighlightColorTag);
  Response := '- ' + Response;
  with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
    TargetIds[0] := Self.Id;
    TargetIds[1] := OtherShip.Id;
  end;
end;
{ @end $5BC560 }

{ @routine $5BC800 TShip_NotifyCargoDemand }
procedure TShip.NotifyCargoDemand(OtherShip: TShip; Response: WideString);
var Header, Request: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  Header := HighlightColorTag + GetFullName(' ') + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + OtherShip.GetFullName(' ') + ColorEndTag;
  Request := '- ' + WrapTextInColor(LookupTalkText('Talk.Goods.Send'), '');
  Response := '- ' + Response;
  with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
    TargetIds[0] := Self.Id;
    TargetIds[1] := OtherShip.Id;
  end;
end;
{ @end $5BC800 }

{ @routine $5BCA54 TShip_NotifyFearCargoDrop }
procedure TShip.NotifyFearCargoDrop(OtherShip: TShip);
const FullNameSeparator = WideString(' ');
var
  Header: WideString;
  RadarSquared: Integer;
  Request: WideString;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  begin
    Request := LookupVisibleTalkText('Talk.DropGoodsInFear.Drop');
    ReplaceTextToken(Request, '<ShipBad>', OtherShip.GetName, HighlightColorTag);
    ReplaceTextToken(Request, '<FullShipBad>',
      OtherShip.GetFullName(FullNameSeparator), HighlightColorTag);
    ReplaceTextToken(Request, '<Star>', CurrentStar.Name, HighlightColorTag);
    Header := HighlightColorTag + GetFullName(FullNameSeparator) + ColorEndTag + ':';
    Request := '- ' + Request;
    with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request, '') do begin
      TargetIds[0] := Self.Id;
      TargetIds[1] := OtherShip.Id;
    end;
  end;
end;
{ @end $5BCA54 }

{ @routine $5BCCF8 TShip_NotifyTruceOffer }
procedure TShip.NotifyTruceOffer(OtherShip: TShip; Response: WideString; Amount: Integer);
var Header, Request: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  Header := HighlightColorTag + GetFullName(' ') + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + OtherShip.GetFullName(' ') + ColorEndTag;
  Request := '- ' + ReplaceColoredToken(LookupTalkText('Talk.Truce.' + GetTypeNameKey + 'Send'), '<Money>', IntToStr(Amount), HighlightColorTag);
  Response := '- ' + Response;
  with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
    TargetIds[0] := Self.Id;
    TargetIds[1] := OtherShip.Id;
  end;
end;
{ @end $5BCCF8 }

{ @routine $5BCFC0 TShip_NotifyAttackRequest }
procedure TShip.NotifyAttackRequest(OtherShip: TShip; Response: WideString; Target: TShip);
var Header, Request: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  Header := HighlightColorTag + GetFullName(' ') + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + OtherShip.GetFullName(' ') + ColorEndTag;
  Request := '- ' + ReplaceColoredToken(LookupTalkText('Talk.Attack.' + GetTypeNameKey + 'Send'), '<Target>', Target.GetFullName(' '), HighlightColorTag);
  Response := '- ' + Response;
  with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
    TargetIds[0] := Self.Id;
    TargetIds[1] := OtherShip.Id;
    TargetIds[2] := Target.Id;
  end;
end;
{ @end $5BCFC0 }

{ @routine $5BD288 TShip_NotifyPartnershipOffer }
procedure TShip.NotifyPartnershipOffer(OtherShip: TShip; Response: WideString; Amount: Integer);
var Header, Request: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace then Exit;
  RadarSquared := Sqr(Player.GetRadarRange);
  if not ((RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
    (RadarSquared >= PointDistanceSquared(OtherShip.Position, Player.Position))) then Exit;
  Header := HighlightColorTag + GetFullName(' ') + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + OtherShip.GetFullName(' ') + ColorEndTag;
  Request := '- ' + FormatText1(LookupTalkText('Talk.Partner.Send'), HighlightColorTag, '<Money>', IntToStr(Amount));
  Response := '- ' + Response;
  with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
    TargetIds[0] := Self.Id;
    TargetIds[1] := OtherShip.Id;
  end;
end;
{ @end $5BD288 }

{ @routine $5BD530 TShip_NotifyPartnerBreak }
procedure TShip.NotifyPartnerBreak(Leader: TShip);
const FullNameSeparator = WideString(' ');
var Header, Request, Response: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar = CurrentStar) and Player.InNormalSpace then begin
    if (Player = Leader) and not PlayerAutomaticControl then begin
      ShowPlayerDialogue(5, LookupTalkText('Talk.Partner.MateBreak'), 0);
    end else begin
      RadarSquared := Sqr(Player.GetRadarRange);
      if (RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
        (RadarSquared >= PointDistanceSquared(Leader.Position, Player.Position)) then
        begin
          Header := HighlightColorTag + GetFullName(FullNameSeparator) + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + Leader.GetFullName(FullNameSeparator) + ColorEndTag;
          Request := '- ' + LookupTalkText('Talk.Partner.MateBreak');
          Response := '- ' + LookupTalkText('Talk.Partner.AnswerLiderBreak');
          with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
            TargetIds[0] := Self.Id;
            TargetIds[1] := Leader.Id;
          end;
        end;
    end;
  end;
end;
{ @end $5BD530 }

{ @routine $5BD7FC TShip_NotifyPartnerRebellion }
procedure TShip.NotifyPartnerRebellion(Leader: TShip);
const FullNameSeparator = WideString(' ');
var Header, Request, Response: WideString; RadarSquared: Integer;
begin
  if (Player.CurrentStar = CurrentStar) and Player.InNormalSpace then begin
    if (Player = Leader) and not PlayerAutomaticControl then begin
      ShowPlayerDialogue(6, LookupTalkText('Talk.Partner.MateTheEnd'), 0);
    end else begin
      RadarSquared := Sqr(Player.GetRadarRange);
      if (RadarSquared >= PointDistanceSquared(Position, Player.Position)) or
        (RadarSquared >= PointDistanceSquared(Leader.Position, Player.Position)) then
        begin
          Header := HighlightColorTag + GetFullName(FullNameSeparator) + ColorEndTag + LookupTalkText('Talk.To') + HighlightColorTag + Leader.GetFullName(FullNameSeparator) + ColorEndTag;
          Request := '- ' + LookupTalkText('Talk.Partner.MateTheEnd');
          Response := '- ' + LookupTalkText('Talk.Partner.AnswerLiderTheEnd');
          with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, Header + #13#10 + Request + #13#10 + Response, '') do begin
            TargetIds[0] := Self.Id;
            TargetIds[1] := Leader.Id;
          end;
        end;
    end;
  end;
end;
{ @end $5BD7FC }

{ @routine $5BDACC TShip_ShowMessageToPlayer }
procedure TShip.ShowMessageToPlayer(Text: WideString);
begin
  begin
    TurnsSinceLastShipMessage := 0;
    with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn,
      WrapTextInColor(GetFullName(' '), HighlightColorTag) + #13#10 + ' ' + #13#10 + Text, '') do
    begin
      TargetIds[0] := Id;
      TargetIds[1] := Player.Id;
    end;
  end;
end;
{ @end $5BDACC }

{ @routine $5BDBD0 TShip_CalculatePartnershipMonths }
function TShip.CalculatePartnershipMonths(Amount: Integer; Relation: Byte): Integer;
begin
  if Amount < Wealth / 45 then begin Result := 0; Exit; end;
  Result := Round(RemapClamped(Amount, Wealth / 45, Wealth / 8, 5, 36) *
    RemapClamped(Relation, 50, 100, 0.7, 1.5));
end;
{ @end $5BDBD0 }

{ @routine $5BDC8C TShip_GetGreetingText }
function TShip.GetGreetingText: WideString;
var Key: WideString;
begin
  if Self is TTranclucator then Key := 'Talk.Tranclucator.Greeting'
  else if Player = PartnerShip then Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'Partner'
  else if Self is TNormalShip then
  begin
    if (LiberationGroup <> nil) and (GetRelationLevelToShip(Player) > rlHostile) and
      ((LiberationGroup as TGroup).Route[LiberationGroupRouteIndex].Kind = Order) then
    begin
      Result := (LiberationGroup as TGroup).GetShipGreeting(Self);
      if Result <> '' then Exit;
    end;
    Result := (Self as TNormalShip).SelectSituationalMessage(False);
    if Result <> '' then Exit;
    case GetRelationLevelToShip(Player) of
      rlHostile: Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'War';
      rlBad: Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'Bad';
      rlNormal: Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'Normal';
      rlGood: Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'Good';
      rlExcellent: Key := 'ShipGreetings.Standart.' + GetTypeNameKey + 'Best';
    end;
  end;
  Result := LookupTalkText(Key);
end;
{ @end $5BDC8C }

{ @routine $5BDFA8 TShip_InitializeScriptStateOrders }
procedure TShip.InitializeScriptStateOrders;
var
  Binding: TScriptShip;
begin
  Binding := ScriptShip as TScriptShip;
  Binding.EndState := False;
  ApplyScriptStateOrders;
  UpdateScriptStateCompletionAndPickups;
end;
{ @end $5BDFA8 }

{ @routine $5BDFD0 TShip_ApplyScriptStateOrders }
procedure TShip.ApplyScriptStateOrders;
var
  Binding, OtherBinding: TScriptShip;
  FollowTarget: TShip;
  WeaponTotal, WeaponIndex, BindingIndex, BindingCount, GroupIndex, GroupCount: Integer;
  Weapon: TWeapon;
  Distance, BestDistance: Single;
  State: TScriptState;
  Place: TScriptPlace;
  ScriptItem: TScriptItem;
begin
  Binding := ScriptShip as TScriptShip;
  State := Binding.State;

  if InHyperspace then Exit;
  if State.StateKind = sskIdle then OrderNone
  else if State.StateKind = sskMoveToPlace then
  begin
    Place := TScriptPlace(State.TargetValue);
    if Place.PlaceKind = spkDockedPlanet then
    begin
      if IsOnPlanet and (TPlanet(Place.TargetValue) = CurrentPlanet) then OrderNone
      else if IsOnPlanet then OrderTakeoff
      else OrderLanding(TObject(Place.TargetValue), False);
    end
    else if Place.PlaceKind = spkScriptItem then
    begin
      ScriptItem := TScriptItem(Place.TargetValue);
      if ScriptItem = nil then OrderNone
      else if CurrentStar.Items.IndexOf(ScriptItem.Item) < 0 then OrderNone
      else if IsOnPlanet then OrderTakeoff
      else OrderMove(Place.GetRandomPoint((Seed + CurrentStar.GenerationSeed) * Galaxy.CurrentTurn), False);
    end
    else if Place.PlaceKind = spkGroupCentroid then
    begin
      if IsOnPlanet then OrderTakeoff
      else OrderMove(Place.GetRandomPoint((Seed + CurrentStar.GenerationSeed) * Galaxy.CurrentTurn), False);
    end
    else if IsOnPlanet then OrderTakeoff
    else OrderMove(Place.GetRandomPoint((Seed + CurrentStar.GenerationSeed) * Galaxy.CurrentTurn), False);
  end
  else if State.StateKind = sskFollowGroup then
  begin
    if IsOnPlanet then OrderTakeoff
    else
    begin
      FollowTarget := FindScriptFollowTarget;
      if FollowTarget = nil then OrderNone
      else OrderFollowShip(FollowTarget, fmNear, False);
    end;
  end
  else if State.StateKind = sskJumpToStar then
  begin
    if IsOnPlanet then OrderTakeoff
    else if InNormalSpace then OrderJump(TStar(State.TargetValue), False);
  end
  else if State.StateKind = sskLandOnPlanet then
  begin
    if IsOnPlanet then
    begin
      if TPlanet(State.TargetValue) = CurrentPlanet then OrderNone
      else OrderTakeoff;
    end
    else OrderLanding(TObject(State.TargetValue), False);
  end;
  if (State.EnemyGroupIndices <> nil) and (WeaponCount > 0) and InNormalSpace then
  begin
    WeaponTotal := WeaponCount;
    BindingCount := Binding.Script.Ships.Count;
    GroupCount := High(State.EnemyGroupIndices) + 1;
    for WeaponIndex := 1 to WeaponTotal do
    begin
      Weapon := Weapons[WeaponIndex - 1];
      Weapon.Target := nil;
      if not Weapon.BrokenFlag then
      begin
        BestDistance := 1E15;
        for BindingIndex := 0 to BindingCount - 1 do
        begin
          OtherBinding := TScriptShip(Binding.Script.Ships[BindingIndex]);
          if not ((CurrentStar = OtherBinding.Ship.CurrentStar) and OtherBinding.Ship.InNormalSpace) then Continue;
          for GroupIndex := 0 to GroupCount - 1 do
            if State.EnemyGroupIndices[GroupIndex] = OtherBinding.GroupIndex then Break;
          if GroupIndex < GroupCount then
          begin
            Distance := PointDistanceSquared(Position, OtherBinding.Ship.Position);
            if (Sqr(Weapon.Range) >= Distance) and (Distance < BestDistance) then
            begin
              BestDistance := Distance;
              Weapon.Target := OtherBinding.Ship;
            end;
          end;
        end;
      end;
    end;
  end
  else for WeaponIndex := 1 to WeaponCount do Weapons[WeaponIndex - 1].Target := nil;
end;
{ @end $5BDFD0 }

{ @routine $5BE424 TShip_UpdateScriptStateCompletionAndPickups }
procedure TShip.UpdateScriptStateCompletionAndPickups;
var
  Binding: TScriptShip;
  State: TScriptState;
  I: Integer;
  Item: TItem;
begin
  Binding := ScriptShip as TScriptShip;
  State := Binding.State;
  if State.StateKind = sskIdle then Binding.EndState := True
  else if State.StateKind = sskMoveToPlace then Binding.EndState := TScriptPlace(State.TargetValue).ShipInPlace(Self)
  else if State.StateKind = sskFollowGroup then Binding.EndState := FindScriptFollowTarget = nil
  else if State.StateKind = sskJumpToStar then
  begin
    if InHyperspace then Binding.EndState := False
    else Binding.EndState := CurrentStar = TStar(State.TargetValue);
  end
  else if State.StateKind = sskLandOnPlanet then Binding.EndState := IsOnPlanet and (CurrentPlanet = TPlanet(State.TargetValue));
  if InNormalSpace and (CargoHook <> nil) and not CargoHook.BrokenFlag then
  begin
    if (State.PickupItem <> nil) and (State.PickupItem.Item <> nil) then
    begin
      Item := State.PickupItem.Item;
      { Uses a fixed 150-unit radius for the explicit script pickup. }
      if (CurrentStar.Items.IndexOf(Item) >= 0) and
        (PointDistanceSquared(Item.Position, Position) <= 22500) then QueuePickupItem(Item);
    end;
    if State.PickUpNearbyItems then
      for I := 0 to CurrentStar.Items.Count - 1 do
      begin
        Item := TItem(CurrentStar.Items[I]);
        if CanReplaceCargoForItem(Item) and CanPickupItemNow(Item) then QueuePickupItem(Item);
      end;
  end;
end;
{ @end $5BE424 }

{ @routine $5BE57C TShip_ScriptNextDay }
procedure TShip.ScriptNextDay;
var Binding: TScriptShip;
begin
  Binding := ScriptShip as TScriptShip;
  UpdateScriptStateCompletionAndPickups;
  Binding.Script.RunShipState(Binding);
  if ScriptShip <> nil then ApplyScriptStateOrders;
end;
{ @end $5BE57C }

{ @routine $5BE5B8 TShip_FindScriptFollowTarget }
function TShip.FindScriptFollowTarget: TShip;
var
  Binding: TScriptShip;
  I, Count: Integer;
  Other: TScriptShip;
  State: TScriptState;
begin
  Binding := ScriptShip as TScriptShip;
  State := Binding.State;
  Count := Binding.Script.Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Other := Binding.Script.Ships[I];
    if (State.TargetValue = Cardinal(Other.GroupIndex)) and (Other.Ship.CurrentStar = CurrentStar) then
    begin
      Result := Other.Ship;
      Exit;
    end;
  end;
  Result := nil;
end;
{ @end $5BE5B8 }

{ @routine $5BE620 TShip_GainExperience }
procedure TShip.GainExperience(Amount: Integer);
begin
  Inc(TotalExperience, Amount);
  Inc(FreeExperience, Amount);
end;
{ @end $5BE620 }

{ @routine $5BE630 TShip_RemoveExperience }
procedure TShip.RemoveExperience(Amount: Integer);
begin
  Dec(TotalExperience, Min(Amount, TotalExperience));
  Dec(FreeExperience, Min(Amount, FreeExperience));
end;
{ @end $5BE630 }

{ @routine $5BE660 TShip_DepositCarriedNodes }
procedure TShip.DepositCarriedNodes;
var I: Integer; Item: TItem;
begin
  for I := Inventory.Count - 1 downto 1 do begin
    Item := Inventory[I];
    if Item.ItemType = t_Protoplasm then begin
      Inc(NodeReserve, Item.Weight);
      GainExperience(Item.Weight);
      if Self = Player then Player.UnresolvedCounter1F4 := 0;
      Inventory.Delete(I);
      Item.Free;
    end;
  end;
  RefreshDerivedStats;
end;
{ @end $5BE660 }

{ @routine $5BE6D8 TShip_TrainSkill }
function TShip.TrainSkill(Skill: TSkill): Boolean;
begin
  if (BaseSkills[Skill] < 5) and
    (SkillTrainingCosts[BaseSkills[Skill] + 1, Skill] <= FreeExperience) then begin
    Inc(BaseSkills[Skill]);
    Dec(FreeExperience, SkillTrainingCosts[BaseSkills[Skill], Skill]);
    Result := True;
  end else Result := False;
end;
{ @end $5BE6D8 }

{ @routine $5BE738 TShip_CanTrainSkill }
function TShip.CanTrainSkill(Skill: TSkill): Boolean;
begin
  Result := (BaseSkills[Skill] < 5) and
    (SkillTrainingCosts[BaseSkills[Skill] + 1, Skill] <= FreeExperience);
end;
{ @end $5BE738 }

{ @routine $5BE774 TShip_GetRelativeStrengthCategory }
function TShip.GetRelativeStrengthCategory: TStandardCount;
var
  Percent: TPercent;
begin
  Result := scZero;
  if StrengthInBestRanger < 1 then Percent := Round(RemapClamped(StrengthInBestRanger, 0.1, 1, 0, 50))
  else Percent := Round(RemapClamped(StrengthInBestRanger, 1, 10, 50, 100));
  case Percent of
    0..20: Result := scMini;
    21..40: Result := scSmall;
    41..60: Result := scAverage;
    61..80: Result := scBig;
    81..100: Result := scHuge;
  else RaiseWideMessage('function TPlayer.StrengthInStandartCnt:TStandartCnt;');
  end;
end;
{ @end $5BE774 }

{ @routine $5BE8AC TShip_GetHullConditionCategory }
function TShip.GetHullConditionCategory: TStandardCount;
begin
  Result := scZero;
  case Integer(Round(RemapClamped(Hull.HullPoints, 0, Hull.Weight, 0, 100))) of
    0..20: Result := scMini;
    21..50: Result := scSmall;
    51..70: Result := scAverage;
    71..90: Result := scBig;
    91..100: Result := scHuge;
  else RaiseWideMessage('function TPlayer.StructureInStandartCnt:TStandartCnt;');
  end;
end;
{ @end $5BE8AC }

{ @routine $5BE9A0 TShip_GetRangerRatingBand }
function TShip.GetRangerRatingBand: TStandardCount;
begin
  Result := scZero;
  if ShipType <> t_Ranger then Exit;
  case Integer(Round(RemapClamped(Galaxy.Rangers.Count - (Self as TRanger).PlaceInRating,
    0, Galaxy.Rangers.Count - 1, 0, 100))) of
    0..10: Result := scMini;
    11..40: Result := scSmall;
    41..60: Result := scAverage;
    61..90: Result := scBig;
    91..100: Result := scHuge;
  else RaiseWideMessage('function TShip.RatingInStandartCnt:TStandartCnt;');
  end;
end;
{ @end $5BE9A0 }

end.

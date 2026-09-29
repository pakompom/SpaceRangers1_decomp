unit aConst;
// Unit bracket (inferred): CODE 0x00611594..0x00613D9B; inclusive evidence, not full bounds.
// Game constants, item sizing and localized text.
interface

type
  // Script constants t_Food..t_UselessItem. No item class uses t_Artefact.
  TItemType = (
    t_Food = 0, t_Medicine = 1, t_Technics = 2, t_Luxury = 3, t_Minerals = 4,
    t_Alcohol = 5, t_Arms = 6, t_Narcotics = 7, t_Artefact = 8, t_ArtefactHull = 9,
    t_ArtefactFuel = 10, t_ArtefactSpeed = 11, t_ArtefactPower = 12, t_ArtefactRadar = 13, t_ArtefactScaner = 14,
    t_ArtefactDroid = 15, t_ArtefactNano = 16, t_ArtefactHook = 17, t_ArtefactDef = 18, t_ArtefactAnalyzer = 19,
    t_ArtefactMiniExpl = 20, t_ArtefactAntigrav = 21, t_ArtefactTransmitter = 22, t_ArtefactBomb = 23, t_ArtefactTranclucator = 24,
    t_Hull = 25, t_FuelTanks = 26, t_Engine = 27, t_Radar = 28, t_Scaner = 29,
    t_RepairRobot = 30, t_CargoHook = 31, t_DefGenerator = 32, t_Weapon1 = 33, t_Weapon2 = 34,
    t_Weapon3 = 35, t_Weapon4 = 36, t_Weapon5 = 37, t_Weapon6 = 38, t_Weapon7 = 39,
    t_Weapon8 = 40, t_Weapon9 = 41, t_Weapon10 = 42, t_Weapon11 = 43, t_Weapon12 = 44,
    t_Weapon13 = 45, t_Weapon14 = 46, t_Weapon15 = 47, t_Protoplasm = 48, t_UselessItem = 49
  ); // @size $01
  TGoodsIndex = t_Food..t_Narcotics;
const
  // SR1 weapon names for the script's t_Weapon1..15.
  t_PhotonGun = t_Weapon1;
  t_IndustrialLaser = t_Weapon2;
  t_ZipGun = t_Weapon3;
  t_GravitonBeamer = t_Weapon4;
  t_Retractor = t_Weapon5;
  t_KellersPhaser = t_Weapon6;
  t_AeonicBlaster = t_Weapon7;
  t_XDefibrillator = t_Weapon8;
  t_SubmesonicGun = t_Weapon9;
  t_FieldAnnihilator = t_Weapon10;
  t_TachionCleaver = t_Weapon11;
  t_VortexProjector = t_Weapon12;
  t_AbsoluteMatrix = t_Weapon13;
  t_HellWave = t_Weapon14;
  t_EyesOfMachpella = t_Weapon15;
  // Stands for any weapon in the equipment-slot APIs.
  WeaponCategoryItemType = t_PhotonGun;

type
  TItemTypeMask = set of TItemType; // @size $07
  // Script constants t_Kling..t_SB, with descriptive names for the stations t_RC..t_SB.
  TShipType = (t_Kling = 0, t_Ranger = 1, t_Transport = 2, t_Pirate = 3, t_Warrior = 4, t_Tranclucator = 5,
    t_RangerCenter = 6, t_PirateBase = 7, t_MilitaryBase = 8, t_ScientificBase = 9); // @size $01
  TShipTypeMask = set of TShipType; // @size $02
  // Ship kinds in the greeting ShipType filters.
  TGreetingShipCategory = (gscTransport = 0, gscLiner = 1, gscDiplomat = 2, gscRanger = 3, gscPirate = 4,
    gscWarrior = 5, gscKling = 6); // @size $01
  TGreetingShipCategories = set of TGreetingShipCategory; // @size $01
  TItemSizeFactors = array[1..5] of Single;
  PItemSizeFactors = ^TItemSizeFactors;
  TPercent = 0..100; // @size $01
  TNonRangerRelation = 0..100; // @size $01
  // Owner of a planet or ship; for an item, the race that made it.
  TOwnerId = (oiMaloc = 0, oiPeleng = 1, oiPeople = 2, oiFei = 3, oiGaal = 4, oiKling = 5, oiNone = 6); // @size $01
  // Coalition race of a planet or pilot; unlike the owner, it survives Klissan occupation.
  TRaceId = (raMaloc = 0, raPeleng = 1, raPeople = 2, raFei = 3, raGaal = 4); // @size $01
  TRaceSet = set of TRaceId; // @size $01
  TRangerCareer = (rcTrader = 0, rcPirate = 1, rcWarrior = 2); // @size $01
  TRangerCareerSet = set of TRangerCareer; // @size $01
  TRangerCareerValues = array[TRangerCareer] of Byte;
  // Script constants ReWar..ReBest.
  TRelationLevel = (rlHostile = 0, rlBad = 1, rlNormal = 2, rlGood = 3, rlExcellent = 4); // @size $01
  TRelationLevels = set of TRelationLevel; // @size $01
  TShipStatistic = (ssShipsKilled = 0, ssPiratesKilled = 1, ssKlissansKilled = 2, ssSystemsLiberated = 3); // @size $01
  // Machpella endgame state, the script's ScenarioState.
  TScenarioState = (scenNone = 0, scenAllianceAgainstRachekhan = 1, scenMachpellaFled = 2,
    scenPeaceRachekhanAtLarge = 3, scenPeaceRachekhanDestroyed = 4); // @size $04
  TRelationChangeMode = (rcmCapAt = 0, rcmRaiseTo = 1, rcmIncrease = 2, rcmDecrease = 3, rcmDecreaseWithFloor20 = 4); // @size $01
  // Native TStandartCnt.
  TStandardCount = (scZero = 0, scMini = 1, scSmall = 2, scAverage = 3, scBig = 4, scHuge = 5); // @size $01
  TStandardCounts = set of TStandardCount; // @size $01
  TPlanetEconomy = (peAgriculture = 0, peMixed = 1, peIndustrial = 2); // @size $01
  TPlanetEconomies = set of TPlanetEconomy; // @size $01
  TPlanetGovernment = (pgAnarchy = 0, pgDictatorship = 1, pgMonarchy = 2, pgRepublic = 3, pgDemocracy = 4); // @size $01
  TPlanetGovernments = set of TPlanetGovernment; // @size $01
  TQuestType = (qtSendLetter = 0, qtKillShip = 1, qtPlanetQuest = 2, qtDefendSystem = 3, qtDefendShip = 4); // @size $01
  TQuestTuning = record // @size $0C
    RewardCapitalPercent: Byte; // @offset $00
    BaseDuration: Integer; // @offset $04
    BaseRewardMoney: Integer; // @offset $08
  end;
  // ShipToHullType codes; htStation is any TRuins.
  THullType = (htRanger = 0, htWarrior = 1, htPirate = 2, htTransport = 3, htLiner = 4, htDiplomat = 5,
    htMakhpella = 6, htEgemon = 7, htNondus = 8, htKatauri = 9, htRoggit = 10, htMutenok = 11,
    htTranclucator = 12, htStation = 13); // @size $01
  THullShipTypeMask = set of THullType; // @size $02
  TTransportType = (ttTransport = 0, ttLiner = 1, ttDiplomat = 2); // @size $01
const
  // Makes SpawnTransport roll the transport type.
  RandomTransportHullType = htRanger;
type
  TGovernmentGoodsFactors = packed record // @size $18
    PriceFactor: Double; // @offset $00
    StockFactor: Double; // @offset $08
    Reserved10: array[0..7] of Byte; // @offset $10 Unresolved native data.
  end;
  TPlanetRaceGoodsRule = packed record // @size $18
    PriceFactor: Double; // @offset $00
    StockFactor: Double; // @offset $08
    Legal: Boolean; // @offset $10 Read by ship purchases and sales.
  end;
  TPlanetRaceMarket = packed record // @size $E8
    InventionProgressScale: Single; // @offset $00
    InitialInventionBoostCount: Integer; // @offset $04 Planet generation $5C1155.
    Goods: array[TGoodsIndex] of TPlanetRaceGoodsRule; // @offset $08
    GovernmentRollThresholds: array[0..4] of Byte; // @offset $C8 Indexed by Ord(TPlanetGovernment).
    RevolutionChance: Single; // @offset $D0 Used by $5C3748.
    FriendlyRelationScale: Single; // @offset $D4 Transport relation to another transport.
    PirateRelationFactor: Single; // @offset $D8 Transport relation to a pirate.
    UnknownRelationFactor: Single; // @offset $DC Native third relation factor.
    MaximumPirateRelation: Byte; // @offset $E0 Planet relation cap (35–80), $5C6448.
  end;
  TWeaponDamageMode = (wmHullDamage = 0, wmEngineOutputLoss = 1, wmEquipmentWear = 2); // @size $01
  TWeaponInfo = record // @size $44
    RequiredTechLevel: Byte; // @offset $00 Checked by ship weapon purchases.
    PriceFactor: Single; // @offset $04
    MinDamage: Byte; // @offset $08
    MaxDamage: Byte; // @offset $09
    Weight: Integer; // @offset $0C
    Range: Integer; // @offset $10
    ShotSpeedPercent: Integer; // @offset $14 Subtracted from 100% for turn shot timing.
    SizeInvention: TInventionTrack; // @offset $18
    RangeInvention: TInventionTrack; // @offset $19
    Mode: TWeaponDamageMode; // @offset $1A
    SplashRadius: Single; // @offset $1C Used by the Submesonic Gun and Field Annihilator in TStar.NextDay.
    MineralDivisor: Single; // @offset $20 Divides asteroid and natural-goods mineral yield.
    DamageLevelFactors: array[TTechLevel] of Single; // @offset $24
  end;
type
  TOwnerSet = set of TOwnerId; // @size $01
  TAwardType = (atForLiberationSystem = 0, atForAccomplishment = 1, atForSecretMission = 2, atForCowardice = 3,
    atForPerfidy = 4); // @size $01
  TAwardTypeMask = set of TAwardType; // @size $01
  TSkill = (skAccuracy = 0, skMobility = 1, skTechnical = 2, skTrader = 3, skCharm = 4, skLeadership = 5); // @size $01
  TSkillLevel = 0..5; // @size $01
  TTechLevel = 1..8; // @size $01
var
  IntegrityDataBegin: Cardinal = 0; // @addr $61899C
  DialogueLinePrefix: WideString = '    '; // @addr $6189A0
  GalaxyStarCount: Integer = 50; // @addr $6189A4
type
  TDifLevelInfo = packed record // @size $44
    CareerExperienceFactor: Single; // @offset $00
    ArtefactFactor: Single; // @offset $04 Also divides the player starting hull weight in $51308C.
    KlissanHullFactor: Single; // @offset $08 Read by TKling.InitGenerated $5443C4.
    PlayerCombatEquipmentWearFactor: Single; // @offset $0C Scales hull-hit and equipment-weapon wear in $5AE85C.
    InventionProgressScale: Single; // @offset $10 Planet research update $5C5080.
    DisplayName: WideString; // @offset $14
    StartingMoneyFactor: Single; // @offset $18
    HomeSystemGraceFactor: Single; // @offset $1C Delays home-system attacks ($5478AC); also scales remains prices ($5DB4C8).
    StartingMoney: Integer; // @offset $20 Initial player money passed by $60645C.
    StartingHullCapacityBonus: Integer; // @offset $24 Added to starting hull weight and hull points by $51308C.
    InitialCommunicatorResearch: Byte; // @offset $28
    CommunicatorResearchDecayPercent: Byte; // @offset $29 Daily research slows by this percentage every 90 turns.
    NodeDepositGraceFactor: Single; // @offset $2C Scales the initial and recurring node-deposit grace periods.
    InitialKlissanOccupationPercent: Byte; // @offset $30
    LiberationGroupInterval: Integer; // @offset $34
    MotherShipHullFactor: Single; // @offset $38 Read by TKling.InitMotherShip $543F6C.
    MarketPriceSpreadReduction: Single; // @offset $3C Narrows market bounds by a fraction of the lower half-spread.
    HoleCreationRandomMaximum: Integer; // @offset $40 Inclusive upper bound for the daily black-hole roll.
  end;
  TDifficulty = (dfEasy = 0, dfNormal = 1, dfHard = 2, dfExpert = 3); // @size $01
var
  DifficultyModifiers: array[TDifficulty] of TDifLevelInfo = (
    (
      CareerExperienceFactor: 0.7;
      ArtefactFactor: 0.85;
      KlissanHullFactor: 0.85;
      PlayerCombatEquipmentWearFactor: 0.5;
      InventionProgressScale: 1.1;
      DisplayName: '';
      StartingMoneyFactor: 1.4;
      HomeSystemGraceFactor: 1.3;
      StartingMoney: 8000;
      StartingHullCapacityBonus: 30;
      InitialCommunicatorResearch: 15;
      CommunicatorResearchDecayPercent: 7;
      NodeDepositGraceFactor: 1.5;
      InitialKlissanOccupationPercent: 45;
      LiberationGroupInterval: 23;
      MotherShipHullFactor: 0.8;
      MarketPriceSpreadReduction: -0.2;
      HoleCreationRandomMaximum: 80
    ),
    (
      CareerExperienceFactor: 1.0;
      ArtefactFactor: 1.0;
      KlissanHullFactor: 1.0;
      PlayerCombatEquipmentWearFactor: 0.9;
      InventionProgressScale: 1.0;
      DisplayName: '';
      StartingMoneyFactor: 1.0;
      HomeSystemGraceFactor: 1.0;
      StartingMoney: 2000;
      StartingHullCapacityBonus: 10;
      InitialCommunicatorResearch: 10;
      CommunicatorResearchDecayPercent: 10;
      NodeDepositGraceFactor: 1.0;
      InitialKlissanOccupationPercent: 55;
      LiberationGroupInterval: 25;
      MotherShipHullFactor: 1.0;
      MarketPriceSpreadReduction: 0.0;
      HoleCreationRandomMaximum: 100
    ),
    (
      CareerExperienceFactor: 1.2;
      ArtefactFactor: 1.1;
      KlissanHullFactor: 1.15;
      PlayerCombatEquipmentWearFactor: 1.3;
      InventionProgressScale: 0.9;
      DisplayName: '';
      StartingMoneyFactor: 0.7;
      HomeSystemGraceFactor: 0.7;
      StartingMoney: 1000;
      StartingHullCapacityBonus: 5;
      InitialCommunicatorResearch: 7;
      CommunicatorResearchDecayPercent: 13;
      NodeDepositGraceFactor: 0.8;
      InitialKlissanOccupationPercent: 65;
      LiberationGroupInterval: 33;
      MotherShipHullFactor: 1.3;
      MarketPriceSpreadReduction: 0.1;
      HoleCreationRandomMaximum: 150
    ),
    (
      CareerExperienceFactor: 1.4;
      ArtefactFactor: 1.15;
      KlissanHullFactor: 1.3;
      PlayerCombatEquipmentWearFactor: 1.8;
      InventionProgressScale: 0.75;
      DisplayName: '';
      StartingMoneyFactor: 0.3;
      HomeSystemGraceFactor: 0.5;
      StartingMoney: 500;
      StartingHullCapacityBonus: 0;
      InitialCommunicatorResearch: 5;
      CommunicatorResearchDecayPercent: 15;
      NodeDepositGraceFactor: 0.7;
      InitialKlissanOccupationPercent: 80;
      LiberationGroupInterval: 38;
      MotherShipHullFactor: 1.6;
      MarketPriceSpreadReduction: 0.15;
      HoleCreationRandomMaximum: 200
    )
  ); // @addr $6189A8
type
  TEconomyInfo = packed record // @size $0C
    InternalName: WideString; // @offset $00
    DisplayName: WideString; // @offset $04
    InventionProgressScale: Single; // @offset $08
  end;
  TRelationTypeInfo = packed record // @size $0C
    InternalName: WideString; // @offset $00
    DisplayName: WideString; // @offset $04 Initialized by $611594.
    Reserved08: array[0..3] of Byte; // @offset $08 Unresolved native data.
  end;
var
  RelationInfo: array[TRelationLevel] of TRelationTypeInfo = (
    (InternalName: 'War'; DisplayName: 'Враждебное'; Reserved08: (0, 0, 0, 0)),
    (InternalName: 'Bad'; DisplayName: 'Плохое'; Reserved08: (10, 0, 0, 0)),
    (InternalName: 'Normal'; DisplayName: 'Нормальное'; Reserved08: (30, 0, 0, 0)),
    (InternalName: 'Good'; DisplayName: 'Хорошее'; Reserved08: (60, 0, 0, 0)),
    (InternalName: 'Best'; DisplayName: 'Отличное'; Reserved08: (80, 0, 0, 0))
  ); // @addr $618AB8
  PlanetEconomyInfo: array[TPlanetEconomy] of TEconomyInfo = (
    (InternalName: 'Agriculture'; DisplayName: 'Сельскохозяйственная'; InventionProgressScale: 0.699999988079071),
    (InternalName: 'Mixed'; DisplayName: 'Смешанная'; InventionProgressScale: 1.0),
    (InternalName: 'Industrial'; DisplayName: 'Индустриальная'; InventionProgressScale: 1.399999976158142)
  ); // @addr $618AF4
type
  TShipTypeInfo = record // @size $04
    InternalName: WideString; // @offset $00
  end;
var
  ShipTypeInfo: array[TShipType] of TShipTypeInfo = (
    (InternalName: 'Kling'),
    (InternalName: 'Ranger'),
    (InternalName: 'Transport'),
    (InternalName: 'Pirate'),
    (InternalName: 'Warrior'),
    (InternalName: 'Tranclucator'),
    (InternalName: 'RC'),
    (InternalName: 'PB'),
    (InternalName: 'WB'),
    (InternalName: 'SB')
  ); // @addr $618B18
type
  TStatusInfo = packed record // @size $28
    Name: WideString; // @offset $00
    MinimumWealthToAverageRatio: Double; // @offset $08
    MinimumWealthToBestRatio: Double; // @offset $10
    MinimumStrengthToAverageRatio: Double; // @offset $18
    MinimumStrengthToBestRatio: Double; // @offset $20
  end;
var
  CareerTuning: array[TRangerCareer] of TStatusInfo = (
    (Name: 'Торгос'; MinimumWealthToAverageRatio: 1.5; MinimumWealthToBestRatio: 0.4; MinimumStrengthToAverageRatio: 0.9; MinimumStrengthToBestRatio: 0.3),
    (Name: 'Пиратос'; MinimumWealthToAverageRatio: 0.9; MinimumWealthToBestRatio: 0.35; MinimumStrengthToAverageRatio: 1.2; MinimumStrengthToBestRatio: 0.4),
    (Name: 'Воинос'; MinimumWealthToAverageRatio: 0.8; MinimumWealthToBestRatio: 0.25; MinimumStrengthToAverageRatio: 1.3; MinimumStrengthToBestRatio: 0.5)
  ); // @addr $618B40
  CareerNames: array[TRangerCareer] of WideString = (
    'Trader',
    'Pirate',
    'Warrior'
  ); // @addr $618BB8
type
  TTransportTypeInfo = record // @size $04
    DisplayName: WideString; // @offset $00
  end;
var
  TransportTypeInfo: array[TTransportType] of TTransportTypeInfo = (
    (DisplayName: 'Транспорт'),
    (DisplayName: 'Пассажирский лайнер'),
    (DisplayName: 'Дипломат')
  ); // @addr $618BC4
type
  // English ShipType.Kling names.
  TKlingType = (ktMakhpella = 0, ktEgemon = 1, ktNondus = 2, ktKatauri = 3, ktRoggit = 4, ktMutenok = 5); // @size $01
  TKlingTypeInfo = packed record // @size $20
    DisplayName: WideString; // @offset $00 Initialized by $611594.
    SystemCountLimit: Byte; // @offset $04 SpawnWeightedKlissan compares the current count before reinforcement.
    Reserved05: array[0..2] of Byte; // @offset $05 Unresolved native data.
    MoneyFactor: Double; // @offset $08 Multiplies the richest ranger's wealth in $5443C4.
    StrengthCap: Double; // @offset $10 Relative to the strongest ranger; generation can remove weapons/shield.
    NodeBase: Word; // @offset $18 Randomized to 0.5..1.5 times this amount in $5443C4.
    RankPoints: Word; // @offset $1A Unseen ranger progression samples between the smallest and largest Klissan rewards.
  end;
var
  KlissanInfo: array[TKlingType] of TKlingTypeInfo = (
    (DisplayName: 'Матка'; SystemCountLimit: 1; Reserved05: (0, 0, 0); MoneyFactor: 10.0; StrengthCap: 10.0; NodeBase: 100; RankPoints: 250),
    (DisplayName: 'Эгемон'; SystemCountLimit: 1; Reserved05: (10, 0, 0); MoneyFactor: 0.7; StrengthCap: 0.95; NodeBase: 100; RankPoints: 48),
    (DisplayName: 'Нондус'; SystemCountLimit: 2; Reserved05: (15, 0, 0); MoneyFactor: 0.6; StrengthCap: 0.8; NodeBase: 50; RankPoints: 24),
    (DisplayName: 'Мончик'; SystemCountLimit: 3; Reserved05: (20, 0, 0); MoneyFactor: 0.5; StrengthCap: 0.6; NodeBase: 30; RankPoints: 12),
    (DisplayName: 'Мутенок'; SystemCountLimit: 4; Reserved05: (25, 0, 0); MoneyFactor: 0.3; StrengthCap: 0.3; NodeBase: 15; RankPoints: 6),
    (DisplayName: 'Мент'; SystemCountLimit: 8; Reserved05: (30, 0, 0); MoneyFactor: 0.2; StrengthCap: 0.25; NodeBase: 10; RankPoints: 3)
  ); // @addr $618BD0
  KlissanFleetStrengthThresholds: array[0..3] of Double = (2.0, 2.2, 2.6, 3.0); // @addr $618C90 Indexed by constellation HomeDistanceTier; native 2, 2.2, 2.6, 3.
  NonNegotiatingShipTypes: TShipTypeMask = [t_Kling, t_Tranclucator..t_ScientificBase]; // @addr $618CB0
  GoodsNames: array[TItemType] of WideString = (
    'Продовольствие',
    'Медидикаменты',
    'Техника',
    'Роскошь',
    'Минералы',
    'Алкоголь',
    'Оружие',
    'Наркотики',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Артефакт',
    'Корпус',
    'Топливные баки',
    'Двигатель',
    'Радар',
    'Сканер',
    'Ремонтный дроид',
    'Захват',
    'Генератор защиты',
    'Фотонная пушка',
    'Промышленный лазер',
    'Разрывное орудие',
    'Гравитонный лучемет',
    'Ретрактор',
    'Фазер Келлера',
    'Эонический бластер',
    'Х-дефибриллятор',
    'Субмезонная пушка',
    'Аннигилятор поля',
    'Тахионный резец',
    'Прожектор вихря',
    'Абсолютная матрица',
    'Адская волна',
    'Глаза Махпелы',
    'Протоплазма',
    'Бесполезные вещи'
  ); // @addr $618CB4 Native managed-data table $613AA8..$613C30 has 50 entries; item actions also index equipment kinds.
  ItemTypeNames: array[TItemType] of WideString = (
    'Food',
    'Medicine',
    'Technics',
    'Luxury',
    'Minerals',
    'Alcohol',
    'Arms',
    'Narcotics',
    'Artefact',
    'ArtefactHull',
    'ArtefactFuel',
    'ArtefactSpeed',
    'ArtefactPower',
    'ArtefactRadar',
    'ArtefactScaner',
    'ArtefactDroid',
    'ArtefactNano',
    'ArtefactHook',
    'ArtefactDef',
    'ArtefactAnalyzer',
    'ArtefactMiniExpl',
    'ArtefactAntigrav',
    'ArtefactTransmitter',
    'ArtefactBomb',
    'ArtefactTranclucator',
    'Hull',
    'FuelTanks',
    'Engine',
    'Radar',
    'Scaner',
    'RepairRobot',
    'CargoHook',
    'DefGenerator',
    'W1',
    'W2',
    'W3',
    'W4',
    'W5',
    'W6',
    'W7',
    'W8',
    'W9',
    'W10',
    'W11',
    'W12',
    'W13',
    'W14',
    'W15',
    'Protoplasm',
    'UselessItem'
  ); // @addr $618D7C Finalizer $6134A6 clears exactly 50 entries; the trade masks follow at $618E44.
  TransportTradeGoods: TItemTypeMask = [t_Food..t_Narcotics]; // @addr $618E44
  LinerTradeGoods: TItemTypeMask = [t_Food..t_Luxury, t_Alcohol, t_Narcotics]; // @addr $618E4C
  DiplomatTradeGoods: TItemTypeMask = [t_Technics, t_Luxury, t_Alcohol..t_Narcotics]; // @addr $618E54
  PiratePriorityPickupTypes: TItemTypeMask = [t_Technics, t_Luxury, t_Alcohol..t_Narcotics]; // @addr $618E5C Bypass the pirate travel/value cutoff.
  ArtefactItemTypes: TItemTypeMask = [t_ArtefactHull..t_ArtefactTranclucator]; // @addr $618E64
  DirectEquipmentTypes: TItemTypeMask = [t_Hull..t_DefGenerator]; // @addr $618E6C
  OptionalEquipmentTypes: TItemTypeMask = [t_Radar, t_Scaner]; // @addr $618E74 Preferred for liquidation when overloaded.
  ExclusiveEquipmentTypes: TItemTypeMask = [t_Hull..t_Engine, t_CargoHook]; // @addr $618E7C
  SlottedEquipmentTypes: TItemTypeMask = [t_FuelTanks..t_EyesOfMachpella]; // @addr $618E84
  RewardEquipmentTypes: TItemTypeMask = [t_FuelTanks..t_DefGenerator]; // @addr $618E8C
  WeaponItemTypes: TItemTypeMask = [t_PhotonGun..t_EyesOfMachpella]; // @addr $618E94
  StandardWeaponTypes: TItemTypeMask = [t_PhotonGun..t_VortexProjector]; // @addr $618E9C
  DeferredDropWeaponTypes: TItemTypeMask = [t_Retractor, t_XDefibrillator, t_AbsoluteMatrix]; // @addr $618EA4 Excluded while the selected drop is a standard weapon.
  HeavyWeaponTypes: TItemTypeMask = [t_AbsoluteMatrix..t_EyesOfMachpella]; // @addr $618EAC

  AIPreservedArtefactTypes: TItemTypeMask = []; // @addr $618EB4 Empty in the native initial data.
  RepairableEquipmentTypes: TItemTypeMask = [t_FuelTanks..t_EyesOfMachpella]; // @addr $618EBC
  RepairableArtefactTypes: TItemTypeMask = [t_ArtefactHull..t_ArtefactAntigrav]; // @addr $618EC4
  ImprovableEquipmentTypes: TItemTypeMask = [t_Hull..t_VortexProjector]; // @addr $618ECC Filter used by TShip.ImproveMostValuableEquipment.
type
  TGoodsInfo = packed record // @size $24
    InternalName: WideString; // @offset $00
    DisplayName: WideString; // @offset $04
    BaseStock: Integer; // @offset $08
    MinPrice: Integer; // @offset $0C
    BasePrice: Integer; // @offset $10
    MaxPrice: Integer; // @offset $14
    EconomyPriceFactors: array[TPlanetEconomy] of Single; // @offset $18 Planet market update multiplies prices by this factor.
  end;
var
  GoodsMarket: array[TGoodsIndex] of TGoodsInfo = (
    (InternalName: 'Food'; DisplayName: 'Продовольствие'; BaseStock: 300; MinPrice: 11; BasePrice: 15; MaxPrice: 19; EconomyPriceFactors: (0.8500000238418579, 1.0, 1.149999976158142)),
    (InternalName: 'Medicine'; DisplayName: 'Медикаменты'; BaseStock: 160; MinPrice: 15; BasePrice: 20; MaxPrice: 25; EconomyPriceFactors: (0.8999999761581421, 1.0, 1.100000023841858)),
    (InternalName: 'Technics'; DisplayName: 'Техника'; BaseStock: 100; MinPrice: 31; BasePrice: 40; MaxPrice: 49; EconomyPriceFactors: (1.149999976158142, 1.0, 0.8500000238418579)),
    (InternalName: 'Luxury'; DisplayName: 'Роскошь'; BaseStock: 60; MinPrice: 80; BasePrice: 100; MaxPrice: 120; EconomyPriceFactors: (1.0, 1.100000023841858, 0.949999988079071)),
    (InternalName: 'Minerals'; DisplayName: 'Минералы'; BaseStock: 250; MinPrice: 4; BasePrice: 6; MaxPrice: 8; EconomyPriceFactors: (0.8500000238418579, 1.0, 1.149999976158142)),
    (InternalName: 'Alcohol'; DisplayName: 'Алкоголь'; BaseStock: 120; MinPrice: 14; BasePrice: 20; MaxPrice: 26; EconomyPriceFactors: (0.800000011920929, 1.0, 1.2000000476837158)),
    (InternalName: 'Arms'; DisplayName: 'Оружие'; BaseStock: 70; MinPrice: 38; BasePrice: 50; MaxPrice: 62; EconomyPriceFactors: (1.149999976158142, 1.0, 0.8500000238418579)),
    (InternalName: 'Narcotics'; DisplayName: 'Наркотики'; BaseStock: 30; MinPrice: 130; BasePrice: 180; MaxPrice: 230; EconomyPriceFactors: (0.8999999761581421, 1.0, 1.100000023841858))
  ); // @addr $618ED4
  QuestTuning: array[TQuestType] of TQuestTuning = (
    (RewardCapitalPercent: 8; BaseDuration: 40; BaseRewardMoney: 1200),
    (RewardCapitalPercent: 15; BaseDuration: 80; BaseRewardMoney: 3000),
    (RewardCapitalPercent: 11; BaseDuration: 50; BaseRewardMoney: 2100),
    (RewardCapitalPercent: 11; BaseDuration: 50; BaseRewardMoney: 1800),
    (RewardCapitalPercent: 9; BaseDuration: 50; BaseRewardMoney: 1600)
  ); // @addr $618FF4
  HullArmorByLevel: array[TTechLevel] of Byte = (1, 3, 5, 7, 9, 11, 13, 15); // @addr $619030
  FuelCapacityByLevel: array[TTechLevel] of Byte = (15, 19, 23, 27, 31, 34, 37, 40); // @addr $619038
  EngineSpeedByLevel: array[TTechLevel] of Word = (400, 450, 500, 600, 700, 800, 900, 1000); // @addr $619040
  RadarRangeByLevel: array[TTechLevel] of Word = (1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000); // @addr $619050
  RepairPointsByLevel: array[TTechLevel] of Byte = (5, 10, 15, 20, 30, 40, 50, 60); // @addr $619060
  CargoHookPowerByLevel: array[TTechLevel] of Word = (40, 50, 60, 80, 90, 100, 150, 500); // @addr $619068
  DefenseFactorByLevel: array[TTechLevel] of Single = (0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6); // @addr $619078
  ItemSizeFactors: TItemSizeFactors = (2.0, 1.5, 1.0, 0.7, 0.5); // @addr $619098
  WeaponRangeFactors: array[1..5] of Single = (0.9, 0.95, 1.0, 1.05, 1.1); // @addr $6190AC
type
  // A subrange because native code indexes the tracks with byte counters.
  TInventionTrack = 0..39; // @size $01
const
  invHullSize = 0;
  invHull = 1;
  invFuelTanksSize = 2;
  invFuelTanks = 3;
  invEngineSize = 4;
  invEngineSpeed = 5;
  invRadarSize = 6;
  invRadarRange = 7;
  invScannerSize = 8;
  invScanner = 9;
  invRepairRobotSize = 10;
  invRepairRobot = 11;
  invCargoHookSize = 12;
  invCargoHook = 13;
  invDefGeneratorSize = 14;
  invTechLevel = 15;
  invPhotonGunSize = 16;
  invPhotonGunRange = 17;
  invIndustrialLaserSize = 18;
  invIndustrialLaserRange = 19;
  invZipGunSize = 20;
  invZipGunRange = 21;
  invGravitonBeamerSize = 22;
  invGravitonBeamerRange = 23;
  invRetractorSize = 24;
  invRetractorRange = 25;
  invKellersPhaserSize = 26;
  invKellersPhaserRange = 27;
  invAeonicBlasterSize = 28;
  invAeonicBlasterRange = 29;
  invXDefibrillatorSize = 30;
  invXDefibrillatorRange = 31;
  invSubmesonicGunSize = 32;
  invSubmesonicGunRange = 33;
  invFieldAnnihilatorSize = 34;
  invFieldAnnihilatorRange = 35;
  invTachionCleaverSize = 36;
  invTachionCleaverRange = 37;
  invVortexProjectorSize = 38;
  invVortexProjectorRange = 39;
type
  tInventionInfo = packed record // @size $08
    DisplayName: WideString; // @offset $00
    MaximumLevel: Byte; // @offset $04 Research percentage step is 100 / MaximumLevel.
    InitialLevel: Byte; // @offset $05 Initial 40-entry research state.
    RequiredMainTechLevel: Byte; // @offset $06 Checked against InventionLevels[invTechLevel].
  end;
var
  PlanetInventionInfo: array[TInventionTrack] of tInventionInfo = (
    (DisplayName: 'Размер корпуса корабля'; MaximumLevel: 5; InitialLevel: 5; RequiredMainTechLevel: 1),
    (DisplayName: 'Корпус корабля'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер топливных баков'; MaximumLevel: 5; InitialLevel: 3; RequiredMainTechLevel: 1),
    (DisplayName: 'Тип топливных баков'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер двигателя'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Скорость двигателя'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер радара'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Радиус действия радара'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер сканера'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Тип сканера'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер дроида'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Тип дроида'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер устройства захвата'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Тип захвата'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер защитного генератора'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Технологический уровень'; MaximumLevel: 8; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер фотонной пушки'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Радиус стрельбы фотонной пушки'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер промышленного лазера'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Радиус стрельбы промышленного лазера'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 1),
    (DisplayName: 'Размер разрывного орудия'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 2),
    (DisplayName: 'Радиус стрельбы разрывного орудия'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 2),
    (DisplayName: 'Размер гравитонный лучемет '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 3),
    (DisplayName: 'Радиус гравитонный лучемет '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 3),
    (DisplayName: 'Размер ретрактора'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 4),
    (DisplayName: 'Радиус действия ретрактора'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 4),
    (DisplayName: 'Размер Фазер Келлера '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 5),
    (DisplayName: 'Радиус стрельбы Фазер Келлера '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 5),
    (DisplayName: 'Размер Эонический бластер '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 6),
    (DisplayName: 'Радиус стрельбы Эонический бластер '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 6),
    (DisplayName: 'Размер Х-дефибриллятор '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 6),
    (DisplayName: 'Радиус стрельбы Х-дефибриллятор '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 6),
    (DisplayName: 'Размер субмезонной пушки'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 7),
    (DisplayName: 'Радиус стрельбы субмезонной пушки'; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 7),
    (DisplayName: 'Размер Аннигилятор поля '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 7),
    (DisplayName: 'Радиус действия Аннигилятор поля '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 7),
    (DisplayName: 'Размер Тахионный резец '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 8),
    (DisplayName: 'Радиус действия Тахионный резец '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 8),
    (DisplayName: 'Размер Прожектор вихря '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 8),
    (DisplayName: 'Радиус действия Прожектор вихря '; MaximumLevel: 5; InitialLevel: 1; RequiredMainTechLevel: 8)
  ); // @addr $6190C0
  WeaponInfo: array[t_PhotonGun..t_EyesOfMachpella] of TWeaponInfo = (
    (
      RequiredTechLevel: 1;
      PriceFactor: 1.0;
      MinDamage: 5;
      MaxDamage: 15;
      Weight: 20;
      Range: 260;
      ShotSpeedPercent: 0;
      SizeInvention: invPhotonGunSize;
      RangeInvention: invPhotonGunRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 2.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.5, 1.7, 2.0, 2.5)
    ),
    (
      RequiredTechLevel: 1;
      PriceFactor: 1.5;
      MinDamage: 10;
      MaxDamage: 15;
      Weight: 30;
      Range: 300;
      ShotSpeedPercent: 10;
      SizeInvention: invIndustrialLaserSize;
      RangeInvention: invIndustrialLaserRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 1.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.4, 1.6, 1.9, 2.3)
    ),
    (
      RequiredTechLevel: 2;
      PriceFactor: 2.5;
      MinDamage: 15;
      MaxDamage: 25;
      Weight: 40;
      Range: 240;
      ShotSpeedPercent: 15;
      SizeInvention: invZipGunSize;
      RangeInvention: invZipGunRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 5.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.6, 2.1)
    ),
    (
      RequiredTechLevel: 3;
      PriceFactor: 3.5;
      MinDamage: 8;
      MaxDamage: 24;
      Weight: 50;
      Range: 350;
      ShotSpeedPercent: 40;
      SizeInvention: invGravitonBeamerSize;
      RangeInvention: invGravitonBeamerRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 4.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.5, 2.0)
    ),
    (
      RequiredTechLevel: 4;
      PriceFactor: 3.0;
      MinDamage: 5;
      MaxDamage: 10;
      Weight: 30;
      Range: 380;
      ShotSpeedPercent: 25;
      SizeInvention: invRetractorSize;
      RangeInvention: invRetractorRange;
      Mode: wmEngineOutputLoss;
      SplashRadius: 0.0;
      MineralDivisor: 3.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.4, 1.5)
    ),
    (
      RequiredTechLevel: 5;
      PriceFactor: 5.5;
      MinDamage: 20;
      MaxDamage: 30;
      Weight: 50;
      Range: 220;
      ShotSpeedPercent: 77;
      SizeInvention: invKellersPhaserSize;
      RangeInvention: invKellersPhaserRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.5, 1.8)
    ),
    (
      RequiredTechLevel: 6;
      PriceFactor: 9.5;
      MinDamage: 10;
      MaxDamage: 40;
      Weight: 60;
      Range: 340;
      ShotSpeedPercent: 60;
      SizeInvention: invAeonicBlasterSize;
      RangeInvention: invAeonicBlasterRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 5.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.5, 1.7)
    ),
    (
      RequiredTechLevel: 6;
      PriceFactor: 7.0;
      MinDamage: 5;
      MaxDamage: 15;
      Weight: 30;
      Range: 300;
      ShotSpeedPercent: 35;
      SizeInvention: invXDefibrillatorSize;
      RangeInvention: invXDefibrillatorRange;
      Mode: wmEquipmentWear;
      SplashRadius: 0.0;
      MineralDivisor: 4.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4)
    ),
    (
      RequiredTechLevel: 7;
      PriceFactor: 15.0;
      MinDamage: 20;
      MaxDamage: 50;
      Weight: 80;
      Range: 280;
      ShotSpeedPercent: 70;
      SizeInvention: invSubmesonicGunSize;
      RangeInvention: invSubmesonicGunRange;
      Mode: wmHullDamage;
      SplashRadius: 100.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4)
    ),
    (
      RequiredTechLevel: 7;
      PriceFactor: 25.0;
      MinDamage: 30;
      MaxDamage: 40;
      Weight: 90;
      Range: 320;
      ShotSpeedPercent: 10;
      SizeInvention: invFieldAnnihilatorSize;
      RangeInvention: invFieldAnnihilatorRange;
      Mode: wmHullDamage;
      SplashRadius: 100.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4)
    ),
    (
      RequiredTechLevel: 8;
      PriceFactor: 38.0;
      MinDamage: 25;
      MaxDamage: 50;
      Weight: 110;
      Range: 380;
      ShotSpeedPercent: 80;
      SizeInvention: invTachionCleaverSize;
      RangeInvention: invTachionCleaverRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 4.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4)
    ),
    (
      RequiredTechLevel: 8;
      PriceFactor: 48.0;
      MinDamage: 40;
      MaxDamage: 60;
      Weight: 130;
      Range: 320;
      ShotSpeedPercent: 90;
      SizeInvention: invVortexProjectorSize;
      RangeInvention: invVortexProjectorRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 2.0;
      DamageLevelFactors: (1.0, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4)
    ),
    (
      RequiredTechLevel: 5;
      PriceFactor: 5.0;
      MinDamage: 3;
      MaxDamage: 10;
      Weight: 100;
      Range: 280;
      ShotSpeedPercent: 10;
      SizeInvention: invVortexProjectorSize;
      RangeInvention: invVortexProjectorRange;
      Mode: wmEquipmentWear;
      SplashRadius: 0.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.1, 1.2, 1.3, 1.4, 1.6, 1.8, 2.0)
    ),
    (
      RequiredTechLevel: 6;
      PriceFactor: 6.0;
      MinDamage: 10;
      MaxDamage: 20;
      Weight: 120;
      Range: 330;
      ShotSpeedPercent: 95;
      SizeInvention: invVortexProjectorSize;
      RangeInvention: invVortexProjectorRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.2, 1.4, 1.6, 1.8, 2.1, 2.5, 3.3)
    ),
    (
      RequiredTechLevel: 7;
      PriceFactor: 7.0;
      MinDamage: 13;
      MaxDamage: 25;
      Weight: 90;
      Range: 420;
      ShotSpeedPercent: 100;
      SizeInvention: invVortexProjectorSize;
      RangeInvention: invVortexProjectorRange;
      Mode: wmHullDamage;
      SplashRadius: 0.0;
      MineralDivisor: 6.0;
      DamageLevelFactors: (1.0, 1.2, 1.4, 1.6, 1.8, 2.1, 2.8, 3.5)
    )
  ); // @addr $619200
type
  TOwnerInfo = packed record // @size $18
    InternalName: WideString; // @offset $00
    DisplayName: WideString; // @offset $04
    FuelPriceFactor: Single; // @offset $08 Also scales equipment generation, wear and nano repair.
    FearThresholdScale: Single; // @offset $0C Transport ransom and combat decisions.
    Reserved10: array[0..3] of Byte; // @offset $10 Unresolved native data.
    ColorTag: WideString; // @offset $14 Used by the native galaxy map owner-colored names.
  end;
  TGovermentInfo = packed record // @size $E0
    InternalName: WideString; // @offset $00
    DisplayName: WideString; // @offset $04
    RevolutionRelationDelta: array[TRangerCareer] of ShortInt; // @offset $08 Read by TriggerGovernmentRevolution $5C3380.
    QuestOfferProbabilities: array[TQuestType] of Single; // @offset $0C
    Goods: array[TGoodsIndex] of TGovernmentGoodsFactors; // @offset $20
  end;
var
  OwnerInfo: array[TOwnerId] of TOwnerInfo = (
    (InternalName: 'Maloc'; DisplayName: 'Малоки'; FuelPriceFactor: 0.699999988079071; FearThresholdScale: 0.800000011920929; Reserved10: (255, 0, 0, 0); ColorTag: '<color=255,000,000>'),
    (InternalName: 'Peleng'; DisplayName: 'Пеленги'; FuelPriceFactor: 0.8999999761581421; FearThresholdScale: 0.8999999761581421; Reserved10: (255, 0, 255, 0); ColorTag: '<color=000,255,000>'),
    (InternalName: 'People'; DisplayName: 'Люди'; FuelPriceFactor: 1.0; FearThresholdScale: 1.0; Reserved10: (0, 0, 255, 0); ColorTag: '<color=000,148,255>'),
    (InternalName: 'Fei'; DisplayName: 'Фэй'; FuelPriceFactor: 1.149999976158142; FearThresholdScale: 1.2999999523162842; Reserved10: (128, 0, 128, 0); ColorTag: '<color=255,147,241>'),
    (InternalName: 'Gaal'; DisplayName: 'Гаал'; FuelPriceFactor: 1.2999999523162842; FearThresholdScale: 1.2000000476837158; Reserved10: (255, 255, 0, 0); ColorTag: '<color=237,247,062>'),
    (InternalName: 'Kling'; DisplayName: 'Клисаны'; FuelPriceFactor: 1.0; FearThresholdScale: 1.0; Reserved10: (255, 255, 255, 0); ColorTag: '<color=097,167,190>'),
    (InternalName: 'None'; DisplayName: 'Неизвестно'; FuelPriceFactor: 1.0; FearThresholdScale: 1.0; Reserved10: (255, 255, 255, 0); ColorTag: '<color=255,000,255>')
  ); // @addr $6195FC
  CoalitionOwners: TOwnerSet = [oiMaloc..oiGaal]; // @addr $6196A4 Native owner-set test in TStar.LoadFromBuffer.
  OwnerRelations: array[TOwnerId, TOwnerId] of Byte = (
    (100, 80, 70, 40, 60, 0, 0),
    (70, 100, 70, 30, 40, 0, 0),
    (50, 40, 100, 70, 90, 0, 0),
    (40, 30, 80, 100, 70, 0, 0),
    (70, 70, 80, 90, 100, 0, 0),
    (0, 0, 0, 0, 0, 100, 0),
    (0, 0, 0, 0, 0, 0, 100)
  ); // @addr $6196A8 Transport generation and relations.

procedure InitializeGameplayConfig; // @addr $611594

function ShipToHullType(Ship: TObject): THullType; // @addr $612A18

function GetAverageItemSize(ItemType: TItemType): Integer; // @addr $6123B4
function LocalizedText(const Path: WideString): WideString; // @addr $612B48
function LocalizedColorText(const Path: WideString): WideString; // @addr $612D74
procedure ExpandLocalizedTextMarkup(var Text: WideString); // @addr $613004

function PickLocalizedTextVariant(const Path: WideString; SeedOffset: Integer): WideString; // @addr $6131E8

function IsKnownOwnerName(const Name: WideString): Boolean; // @addr $611DA0

function MatchesOwnerName(OwnerId: TOwnerId; const Name: WideString): Boolean; // @addr $611EA0

function PickRandomEquipmentOwner(RandomValue: Dword): TOwnerId; // @addr $611F08

function OwnerFromInternalName(const Tag: WideString): TOwnerId; // @addr $611CC8

function OwnerToRace(OwnerId: TOwnerId): TRaceId; // @addr $611A28

function RaceToOwner(RaceId: TRaceId): TOwnerId; // @addr $611A98

function GetOwnerDamageColor(OwnerId: TOwnerId): Cardinal; // @addr $611B0C

function OwnerToSys(OwnerId: TOwnerId): WideString; // @addr $611BC8

function SysToReward(const Name: WideString): TAwardType; // @addr $611F68
function MatchesCareerName(Career: TRangerCareer; const Name: WideString): Boolean; // @addr $611F1C

function GetWeaponResourceName(ItemType: TItemType): WideString; // @addr $6120F8
function IsWeaponItemType(ItemType: TItemType): Boolean; // @addr $6120F0

function IsFinalScenarioActive: Boolean; // @addr $611A14

function StandardToItemTechLevel(ItemType: TItemType; StandardLevel: ShortInt; Seed: Cardinal): Integer; // @addr $6127B4

procedure GetItemSizeBounds(ItemType: TItemType; SizeClass: TStandardCount; var Minimum, Maximum: Integer); // @addr $612540 @note "scZero gives the full size range."

function GenerateItemSize(ItemType: TItemType; SizeClass: TStandardCount; Seed: Cardinal): Integer; // @addr $6126D0 @note "scZero gives the minimum size, like the lower end of scMini."

function GetCommunicatorCost: Integer; // @addr $612B34

// Native protection interval: includes the constant tables below this address.
var
  PlanetRaceMarket: array[TRaceId] of TPlanetRaceMarket = (
    (
      InventionProgressScale: 0.85;
      InitialInventionBoostCount: 5;
      Goods: (
        (PriceFactor: 0.85; StockFactor: 1.1; Legal: True),
        (PriceFactor: 1.1; StockFactor: 1.1; Legal: True),
        (PriceFactor: 1.15; StockFactor: 0.5; Legal: True),
        (PriceFactor: 0.85; StockFactor: 0.4; Legal: False),
        (PriceFactor: 0.87; StockFactor: 0.7; Legal: True),
        (PriceFactor: 1.1; StockFactor: 0.1; Legal: False),
        (PriceFactor: 1.2; StockFactor: 0.5; Legal: True),
        (PriceFactor: 0.8; StockFactor: 0.2; Legal: False)
      );
      GovernmentRollThresholds: (5, 25, 75, 90, 100);
      RevolutionChance: 0.002;
      FriendlyRelationScale: 0.7;
      PirateRelationFactor: 1.1;
      UnknownRelationFactor: 1.5;
      MaximumPirateRelation: 60
    ),
    (
      InventionProgressScale: 0.95;
      InitialInventionBoostCount: 6;
      Goods: (
        (PriceFactor: 0.95; StockFactor: 1.2; Legal: True),
        (PriceFactor: 1.05; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.07; StockFactor: 0.9; Legal: True),
        (PriceFactor: 1.15; StockFactor: 1.2; Legal: True),
        (PriceFactor: 0.95; StockFactor: 0.8; Legal: True),
        (PriceFactor: 1.05; StockFactor: 1.1; Legal: True),
        (PriceFactor: 1.1; StockFactor: 0.8; Legal: True),
        (PriceFactor: 0.95; StockFactor: 0.6; Legal: True)
      );
      GovernmentRollThresholds: (20, 40, 70, 85, 100);
      RevolutionChance: 0.006;
      FriendlyRelationScale: 1.1;
      PirateRelationFactor: 1.5;
      UnknownRelationFactor: 0.8;
      MaximumPirateRelation: 80
    ),
    (
      InventionProgressScale: 1.0;
      InitialInventionBoostCount: 7;
      Goods: (
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.5; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.0; StockFactor: 0.8; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: True),
        (PriceFactor: 1.0; StockFactor: 1.0; Legal: False)
      );
      GovernmentRollThresholds: (10, 30, 50, 70, 100);
      RevolutionChance: 0.004;
      FriendlyRelationScale: 1.0;
      PirateRelationFactor: 0.9;
      UnknownRelationFactor: 1.2;
      MaximumPirateRelation: 45
    ),
    (
      InventionProgressScale: 1.1;
      InitialInventionBoostCount: 8;
      Goods: (
        (PriceFactor: 1.05; StockFactor: 0.7; Legal: True),
        (PriceFactor: 0.85; StockFactor: 0.9; Legal: True),
        (PriceFactor: 0.87; StockFactor: 1.4; Legal: True),
        (PriceFactor: 1.0; StockFactor: 0.8; Legal: True),
        (PriceFactor: 1.15; StockFactor: 0.5; Legal: True),
        (PriceFactor: 1.15; StockFactor: 0.4; Legal: False),
        (PriceFactor: 0.9; StockFactor: 0.4; Legal: False),
        (PriceFactor: 1.1; StockFactor: 0.5; Legal: False)
      );
      GovernmentRollThresholds: (1, 6, 16, 60, 100);
      RevolutionChance: 0.003;
      FriendlyRelationScale: 1.1;
      PirateRelationFactor: 0.7;
      UnknownRelationFactor: 1.0;
      MaximumPirateRelation: 35
    ),
    (
      InventionProgressScale: 1.15;
      InitialInventionBoostCount: 9;
      Goods: (
        (PriceFactor: 1.1; StockFactor: 0.5; Legal: True),
        (PriceFactor: 0.8; StockFactor: 0.5; Legal: True),
        (PriceFactor: 0.8; StockFactor: 0.8; Legal: True),
        (PriceFactor: 0.85; StockFactor: 0.5; Legal: True),
        (PriceFactor: 1.1; StockFactor: 0.3; Legal: True),
        (PriceFactor: 0.9; StockFactor: 0.3; Legal: True),
        (PriceFactor: 0.84; StockFactor: 0.1; Legal: False),
        (PriceFactor: 1.15; StockFactor: 0.4; Legal: False)
      );
      GovernmentRollThresholds: (5, 8, 28, 60, 100);
      RevolutionChance: 0.002;
      FriendlyRelationScale: 1.3;
      PirateRelationFactor: 0.6;
      UnknownRelationFactor: 0.9;
      MaximumPirateRelation: 35
    )
  ); // @addr $6196DC
  PlanetEquipmentOfferQuotas: array[TRaceId, 0..8] of Integer = (
    (1, 1, 2, 1, 1, 1, 1, 2, 6),
    (1, 1, 2, 2, 1, 2, 1, 2, 5),
    (1, 1, 2, 1, 2, 1, 1, 2, 5),
    (1, 1, 2, 1, 1, 2, 1, 1, 4),
    (1, 1, 2, 1, 2, 1, 2, 2, 4)
  ); // @addr $619B64 Target counts for hull, fuel, engine, radar, scanner, robot, hook, shield and weapons.

var
  RangerCenterEquipmentQuotas: array[t_Hull..WeaponCategoryItemType] of Integer = (1, 1, 1, 1, 1, 2, 1, 2, 3); // @addr $619C18
  PirateBaseEquipmentQuotas: array[t_Hull..WeaponCategoryItemType] of Integer = (1, 1, 2, 1, 2, 1, 2, 1, 5); // @addr $619C3C
  MilitaryBaseEquipmentQuotas: array[t_Hull..WeaponCategoryItemType] of Integer = (1, 1, 1, 1, 1, 2, 1, 2, 4); // @addr $619C60
  ScienceBaseEquipmentQuotas: array[t_Hull..WeaponCategoryItemType] of Integer = (1, 1, 1, 1, 1, 1, 1, 1, 3); // @addr $619C84
  RangerCenterGoodsFactors: array[TGoodsIndex] of TPlanetRaceGoodsRule = (
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.15; Legal: True),
    (PriceFactor: 0.8; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 0.5; StockFactor: 0.01; Legal: False)
  ); // @addr $619CA8
  PirateBaseGoodsFactors: array[TGoodsIndex] of TPlanetRaceGoodsRule = (
    (PriceFactor: 0.9; StockFactor: 0.15; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.2; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 0.8; StockFactor: 0.15; Legal: True),
    (PriceFactor: 0.9; StockFactor: 0.1; Legal: True),
    (PriceFactor: 0.9; StockFactor: 0.3; Legal: True),
    (PriceFactor: 0.9; StockFactor: 0.2; Legal: True)
  ); // @addr $619D68 Station price/stock factors, native stride $18.
  MilitaryBaseGoodsFactors: array[TGoodsIndex] of TPlanetRaceGoodsRule = (
    (PriceFactor: 1.1; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 0.4; StockFactor: 0.1; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: False),
    (PriceFactor: 0.8; StockFactor: 0.3; Legal: True),
    (PriceFactor: 0.5; StockFactor: 0.01; Legal: False)
  ); // @addr $619E28 Station price/stock factors, native stride $18.
  ScienceBaseGoodsFactors: array[TGoodsIndex] of TPlanetRaceGoodsRule = (
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 0.8; StockFactor: 0.1; Legal: True),
    (PriceFactor: 0.8; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.0; StockFactor: 0.05; Legal: True),
    (PriceFactor: 1.1; StockFactor: 0.05; Legal: False),
    (PriceFactor: 1.0; StockFactor: 0.1; Legal: True),
    (PriceFactor: 0.5; StockFactor: 0.01; Legal: False)
  ); // @addr $619EE8 Station price/stock factors, native stride $18.
  PlanetGovernmentMarket: array[TPlanetGovernment] of TGovermentInfo = (
    (InternalName: 'Anarchy'; DisplayName: 'Анархия'; RevolutionRelationDelta: (-30, 30, 0); QuestOfferProbabilities: (0.20000000298023224, 0.8999999761581421, 0.800000011920929, 0.10000000149011612, 0.30000001192092896); Goods: ((PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.8; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.8; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.9; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)))),
    (InternalName: 'Dictatorship'; DisplayName: 'Диктатура'; RevolutionRelationDelta: (-40, 20, 20); QuestOfferProbabilities: (0.20000000298023224, 0.8999999761581421, 0.800000011920929, 0.20000000298023224, 0.5); Goods: ((PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.9; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.9; StockFactor: 0.9; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.9; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 0.9; StockFactor: 0.9; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)))),
    (InternalName: 'Monarchy'; DisplayName: 'Монархия'; RevolutionRelationDelta: (-10, 0, 10); QuestOfferProbabilities: (0.20000000298023224, 0.6000000238418579, 0.800000011920929, 0.5, 0.800000011920929); Goods: ((PriceFactor: 1.0; StockFactor: 0.9; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)))),
    (InternalName: 'Republic'; DisplayName: 'Республика'; RevolutionRelationDelta: (10, -20, 0); QuestOfferProbabilities: (0.20000000298023224, 0.30000001192092896, 0.800000011920929, 0.8999999761581421, 0.8999999761581421); Goods: ((PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 0.7; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)))),
    (InternalName: 'Democracy'; DisplayName: 'Демократия'; RevolutionRelationDelta: (15, -30, 0); QuestOfferProbabilities: (0.20000000298023224, 0.30000001192092896, 0.800000011920929, 0.8999999761581421, 0.8999999761581421); Goods: ((PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 1.0; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.8; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.0; StockFactor: 0.5; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0)), (PriceFactor: 1.1; StockFactor: 0.6; Reserved10: (1, 0, 0, 0, 0, 0, 0, 0))))
  ); // @addr $619FA8
type
  TCoalitionRank = (crRookie = 0, crCadet = 1, crPilot = 2, crWingman = 3, crLeader = 4, crAce = 5, crCommander = 6); // @size $01
  TCoalitionRanks = set of TCoalitionRank; // @size $01
  TRewardInfo = packed record // @size $0C
    AwardId: Byte; // @offset $00
    Name: WideString; // @offset $04
    Text: WideString; // @offset $08
  end;
var
  CoalitionAwardConfigNames: array[TAwardType] of WideString = (
    'ForLiberationSystem',
    'ForAccomplishment',
    'ForSecretMission',
    'ForCowardice',
    'ForPerfidy'
  ); // @addr $61A408
  CoalitionRankNames: array[TCoalitionRank] of WideString = (
    'Rookie',
    'Cadet',
    'Pilot',
    'Wingman',
    'Leader',
    'Ace',
    'Commander'
  ); // @addr $61A41C
  CoalitionRankPointThresholds: array[TCoalitionRank] of Word = (100, 250, 450, 700, 1000, 1500, 0); // @addr $61A438 Zero threshold at the maximum rank.
  SkillConfigNames: array[TSkill] of WideString = (
    'sAccuracy',
    'sMobility',
    'sTechnical',
    'sTrader',
    'sCharm',
    'sLeadership'
  ); // @addr $61A448 Used by scanner skill descriptions $58069C.
  SkillTrainingCosts: array[TSkillLevel, TSkill] of Word = (
    (0, 0, 0, 0, 0, 0),
    (160, 160, 140, 140, 120, 120),
    (320, 320, 280, 280, 240, 240),
    (480, 480, 420, 420, 360, 360),
    (640, 640, 560, 560, 480, 480),
    (800, 800, 700, 700, 600, 600)
  ); // @addr $61A460
  SkillEffectValues: array[TSkillLevel, TSkill] of Word = (
    (0, 0, 0, 40, 0, 0),
    (20, 20, 10, 50, 10, 1),
    (40, 40, 20, 60, 20, 2),
    (60, 60, 30, 70, 30, 3),
    (80, 80, 40, 80, 40, 4),
    (100, 100, 50, 90, 50, 5)
  ); // @addr $61A4A8 Level-major; column 3 is the resale percentage.
  StandardCountNames: array[TStandardCount] of WideString = (
    'Zero',
    'Mini',
    'Small',
    'Average',
    'Big',
    'Huge'
  ); // @addr $61A4F0
  WealthDemandScales: array[TStandardCount] of Single = (0.0, 0.01, 0.0125, 0.016666668, 0.02, 0.025); // @addr $61A508
  IntegrityDataEnd: Cardinal = 0; // @addr $61A520
  MinimumShipMass: Integer; // @addr $61D0F8 Initialized to Round(500 * ItemSizeFactors[5] * 2).
  MaximumShipMass: Integer; // @addr $61D0FC Initialized to Round(500 * ItemSizeFactors[1] * 2).
  InitialGoodsMarket: array[TGoodsIndex] of TGoodsInfo; // @addr $61D100 Snapshot made by $611594.

implementation

// @unit-initialization $613D88
// @unit-finalization $6133CC

uses aRanger, aWarrior, aPirate, aTransport, aKling, aTranclucator, aRuins, SysUtils, EC_Str, GR_Main, Globals, GlobalsV, aMyFunction, aGalaxy, aPlayer;
{ @routine $611594 InitializeGameplayConfig }
procedure InitializeGameplayConfig;
var
  Difficulty: TDifficulty; Klissan: TKlingType; Government: TPlanetGovernment; Economy: TPlanetEconomy; GoodsIndex: TGoodsIndex;
  Owner: TOwnerId;
  Relation: TRelationLevel;
  Career: TRangerCareer;
begin
  MinimumShipMass := Round(500 * ItemSizeFactors[5] * 2);
  MaximumShipMass := Round(500 * ItemSizeFactors[1] * 2);
  for GoodsIndex := t_Food to t_Narcotics do
    GoodsNames[GoodsIndex] := LocalizedText('Items.Goods.Name.' + IntToStr(Ord(GoodsIndex) + 1));
  for GoodsIndex := t_Food to t_Narcotics do
    GoodsMarket[GoodsIndex].DisplayName := GoodsNames[GoodsIndex];
  for Government := pgAnarchy to pgDemocracy do
    PlanetGovernmentMarket[Government].DisplayName := LocalizedText('Goverment.Type.' + IntToStr(Ord(Government)));
  for Relation := Low(TRelationLevel) to High(TRelationLevel) do
    RelationInfo[Relation].DisplayName := LocalizedText('Relations.Type.' + IntToStr(Ord(Relation)));
  for Difficulty := dfEasy to dfExpert do
    DifficultyModifiers[Difficulty].DisplayName := LocalizedText('DifLevel.Name.' + IntToStr(Ord(Difficulty)));
  for Klissan := ktMakhpella to ktMutenok do
    KlissanInfo[Klissan].DisplayName := LookupLocalizedTextByKey('ShipType.Kling.' + IntToStr(Ord(Klissan)));
  for Owner := oiMaloc to oiNone do
    OwnerInfo[Owner].DisplayName := LookupLocalizedTextByKey('Race.Name.' + OwnerInfo[Owner].InternalName);
  for Economy := peAgriculture to peIndustrial do
    PlanetEconomyInfo[Economy].DisplayName := LookupLocalizedTextByKey('Economy.Name.' + IntToStr(Ord(Economy)));
  for Career := Low(TRangerCareer) to High(TRangerCareer) do
    CareerTuning[Career].Name := LookupLocalizedTextByKey('RangerInfo.Type.' + CareerNames[Career]);
  for GoodsIndex := t_Food to t_Narcotics do
    InitialGoodsMarket[GoodsIndex] := GoodsMarket[GoodsIndex];
end;
{ @end $611594 }

{ @routine $611A14 IsFinalScenarioActive }
function IsFinalScenarioActive: Boolean;
begin
  Result := ScenarioState in [scenPeaceRachekhanAtLarge, scenPeaceRachekhanDestroyed];
end;
{ @end $611A14 }

{ @routine $611A28 OwnerToRace }
function OwnerToRace(OwnerId: TOwnerId): TRaceId;
begin
  case OwnerId of
    oiMaloc: Result := raMaloc;
    oiPeleng: Result := raPeleng;
    oiPeople: Result := raPeople;
    oiFei: Result := raFei;
    oiGaal: Result := raGaal;
  else
    begin
      raise Exception.Create('Получить расу невозможно');
      Result := raMaloc;
    end;
  end;
end;
{ @end $611A28 }

{ @routine $611A98 RaceToOwner }
function RaceToOwner(RaceId: TRaceId): TOwnerId;
begin
  case RaceId of
    raMaloc: Result := oiMaloc;
    raPeleng: Result := oiPeleng;
    raPeople: Result := oiPeople;
    raFei: Result := oiFei;
    raGaal: Result := oiGaal;
  else
    begin
      raise Exception.Create('Получить владельца невозможно');
      Result := oiMaloc;
    end;
  end;
end;
{ @end $611A98 }

{ @routine $611B0C GetOwnerDamageColor }
function GetOwnerDamageColor(OwnerId: TOwnerId): Cardinal;
begin
  case OwnerId of
    oiMaloc: Result := CurrentPixelFormat.PackRgbBytes(255, 0, 0);
    oiPeleng: Result := CurrentPixelFormat.PackRgbBytes(0, 255, 0);
    oiPeople: Result := CurrentPixelFormat.PackRgbBytes(0, 71, 234);
    oiFei: Result := CurrentPixelFormat.PackRgbBytes(255, 147, 241);
    oiGaal: Result := CurrentPixelFormat.PackRgbBytes(237, 247, 62);
    oiKling: Result := CurrentPixelFormat.PackRgbBytes(97, 167, 190);
  else Result := CurrentPixelFormat.PackRgbBytes(255, 0, 255);
  end;
end;
{ @end $611B0C }

{ @routine $611BC8 OwnerToSys }
function OwnerToSys(OwnerId: TOwnerId): WideString;
begin
  case OwnerId of
    oiMaloc: Result := 'Maloc';
    oiPeleng: Result := 'Peleng';
    oiPeople: Result := 'People';
    oiFei: Result := 'Fei';
    oiGaal: Result := 'Gaal';
    oiKling: Result := 'Kling';
  else Result := 'None';
  end;
end;
{ @end $611BC8 }

{ @routine $611CC8 OwnerFromInternalName }
function OwnerFromInternalName(const Tag: WideString): TOwnerId;
begin
  if Tag = 'Maloc' then Result := oiMaloc
  else if Tag = 'Peleng' then Result := oiPeleng
  else if Tag = 'People' then Result := oiPeople
  else if Tag = 'Fei' then Result := oiFei
  else if Tag = 'Gaal' then Result := oiGaal
  else if Tag = 'Kling' then Result := oiKling
  else Result := oiNone;
end;
{ @end $611CC8 }

{ @routine $611DA0 IsKnownOwnerName }
function IsKnownOwnerName(const Name: WideString): Boolean;
begin
  Result := False;
  if not Result then Result := Name = 'Maloc';
  if not Result then Result := Name = 'Peleng';
  if not Result then Result := Name = 'People';
  if not Result then Result := Name = 'Fei';
  if not Result then Result := Name = 'Gaal';
  if not Result then Result := Name = 'Kling';
  if not Result then Result := Name = 'None';
end;
{ @end $611DA0 }

{ @routine $611EA0 MatchesOwnerName }
function MatchesOwnerName(OwnerId: TOwnerId; const Name: WideString): Boolean;
begin
  Result := not IsKnownOwnerName(Name) or (Name = OwnerToSys(OwnerId));
end;
{ @end $611EA0 }

{ @routine $611F08 PickRandomEquipmentOwner }
function PickRandomEquipmentOwner(RandomValue: Dword): TOwnerId;
begin
  Result := TOwnerId(SeededRandomIntRange(Ord(oiMaloc), Ord(oiGaal), RandomValue));
end;
{ @end $611F08 }

{ @routine $611F1C MatchesCareerName }
function MatchesCareerName(Career: TRangerCareer; const Name: WideString): Boolean;
var I: TRangerCareer;
begin
  Result := True;
  for I := Low(TRangerCareer) to High(TRangerCareer) do
    if CareerNames[I] = Name then begin
      if CareerNames[Career] <> Name then Result := False;
      Break;
    end;
end;
{ @end $611F1C }

{ @routine $611F68 SysToReward }
function SysToReward(const Name: WideString): TAwardType;
begin
  if Name = 'ForLiberationSystem' then Result := atForLiberationSystem
  else if Name = 'ForAccomplishment' then Result := atForAccomplishment
  else if Name = 'ForSecretMission' then Result := atForSecretMission
  else if Name = 'ForCowardice' then Result := atForCowardice
  else if Name = 'ForPerfidy' then Result := atForPerfidy
  else begin RaiseWideMessage('function SysToReward(Reward:WideString):TReward'); Result := atForPerfidy; end;
end;
{ @end $611F68 }

{ @routine $6120F0 IsWeaponItemType }
function IsWeaponItemType(ItemType: TItemType): Boolean;
begin
  Result := ItemType in [t_PhotonGun..t_EyesOfMachpella];
end;
{ @end $6120F0 }

{ @routine $6120F8 GetWeaponResourceName }
function GetWeaponResourceName(ItemType: TItemType): WideString;
begin
  if ItemType = t_PhotonGun then begin Result := 'Weapon.0'; Exit; end
  else if ItemType = t_IndustrialLaser then Result := 'Weapon.1'
  else if ItemType = t_ZipGun then Result := 'Weapon.2'
  else if ItemType = t_GravitonBeamer then Result := 'Weapon.3'
  else if ItemType = t_Retractor then Result := 'Weapon.4'
  else if ItemType = t_KellersPhaser then Result := 'Weapon.5'
  else if ItemType = t_AeonicBlaster then Result := 'Weapon.6'
  else if ItemType = t_XDefibrillator then Result := 'Weapon.7'
  else if ItemType = t_SubmesonicGun then Result := 'Weapon.8'
  else if ItemType = t_FieldAnnihilator then Result := 'Weapon.9'
  else if ItemType = t_TachionCleaver then Result := 'Weapon.10'
  else if ItemType = t_VortexProjector then Result := 'Weapon.11'
  else if ItemType = t_AbsoluteMatrix then Result := 'Weapon.12'
  else if ItemType = t_HellWave then Result := 'Weapon.13'
  else if ItemType = t_EyesOfMachpella then Result := 'Weapon.14'
  else raise Exception.Create('Error');
end;
{ @end $6120F8 }

{ @routine $6123B4 GetAverageItemSize }
function GetAverageItemSize(ItemType: TItemType): Integer;
begin
  case ItemType of
    t_ArtefactHull: Result := 22;
    t_ArtefactFuel: Result := 25;
    t_ArtefactSpeed: Result := 35;
    t_ArtefactPower: Result := 16;
    t_ArtefactRadar: Result := 12;
    t_ArtefactScaner: Result := 10;
    t_ArtefactDroid: Result := 22;
    t_ArtefactNano: Result := 24;
    t_ArtefactHook: Result := 10;
    t_ArtefactDef: Result := 14;
    t_ArtefactAnalyzer: Result := 5;
    t_ArtefactMiniExpl: Result := 20;
    t_ArtefactAntigrav: Result := 40;
    t_ArtefactTransmitter: Result := 3;
    t_ArtefactBomb: Result := 5;
    t_ArtefactTranclucator: Result := 60;
    t_Hull: Result := 500;
    t_FuelTanks: Result := 40;
    t_Engine: Result := 40;
    t_Radar: Result := 30;
    t_Scaner: Result := 30;
    t_RepairRobot: Result := 40;
    t_CargoHook: Result := 40;
    t_DefGenerator: Result := 40;
    t_PhotonGun..t_EyesOfMachpella: Result := WeaponInfo[ItemType].Weight;
  else
    begin
      Exception.Create('Error ItemAverageSize'); // Native constructs the exception without raising it.
      Result := 0;
    end;
  end;
end;
{ @end $6123B4 }

{ @routine $612540 GetItemSizeBounds }
procedure GetItemSizeBounds(ItemType: TItemType; SizeClass: TStandardCount; var Minimum, Maximum: Integer);
begin
  case SizeClass of
    scMini:
    begin
      Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[5]);
      Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[4]);
    end;
    scSmall:
    begin
      Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[5]);
      Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[3]);
    end;
    scAverage:
    begin
      Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[4]);
      Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[2]);
    end;
    scBig:
    begin
      Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[3]);
      Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[1]);
    end;
    scHuge:
    begin
      Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[2]);
      Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[1]);
    end;
  else
    Minimum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[5]);
    Maximum := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[1]);
  end;
end;
{ @end $612540 }

{ @routine $6126D0 GenerateItemSize }
function GenerateItemSize(ItemType: TItemType; SizeClass: TStandardCount; Seed: Cardinal): Integer;
var
  RoundedUpper: Integer;
  Lower, Upper: Integer;
begin
  // Ord comparisons match native.
  if Ord(SizeClass) = Ord(scZero) then Lower := 0 else Lower := Ord(SizeClass) - 1;
  if Ord(SizeClass) = Ord(scHuge) then Upper := Ord(SizeClass) else Upper := Ord(SizeClass) + 1;
  Lower := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[Round(RemapClampedAlternate(Lower, 1, 5, 5, 1))]);
  RoundedUpper := Round(GetAverageItemSize(ItemType) * ItemSizeFactors[Round(RemapClampedAlternate(Upper, 1, 5, 5, 1))]);
  Result := SeededRandomIntRange(Lower, RoundedUpper, Seed);
end;
{ @end $6126D0 }

{ @routine $6127B4 StandardToItemTechLevel }
// Seed is unused.
function StandardToItemTechLevel(ItemType: TItemType; StandardLevel: ShortInt; Seed: Cardinal): Integer;
begin
  case ItemType of
    t_FuelTanks: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_Engine: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_Radar: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_Scaner: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_RepairRobot: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_CargoHook: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_DefGenerator: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
    t_PhotonGun..t_EyesOfMachpella: Result := Round(RemapClamped(StandardLevel, 1, 5, 1, 8));
  else
    Exception.Create('Error StandartToRealItemTypeInit'); // Native constructs the exception without raising it.
    Result := 0;
  end;
end;
{ @end $6127B4 }

{ @routine $612A18 ShipToHullType }
function ShipToHullType(Ship: TObject): THullType;
begin
  Result := htRanger;
  if Ship is TRanger then Result := htRanger
  else if Ship is TWarrior then Result := htWarrior
  else if Ship is TPirate then Result := htPirate
  else if Ship is TTransport then begin
    if TTransport(Ship).TransportType = ttTransport then Result := htTransport
    else if TTransport(Ship).TransportType = ttLiner then Result := htLiner
    else Result := htDiplomat;
  end else if Ship is TKling then begin
    if TKling(Ship).KlingType = ktMakhpella then Result := htMakhpella
    else if TKling(Ship).KlingType = ktEgemon then Result := htEgemon
    else if TKling(Ship).KlingType = ktNondus then Result := htNondus
    else if TKling(Ship).KlingType = ktKatauri then Result := htKatauri
    else if TKling(Ship).KlingType = ktRoggit then Result := htRoggit
    else Result := htMutenok;
  end else if Ship is TTranclucator then Result := htTranclucator
  else if Ship is TRuins then Result := htStation
  else RaiseWideMessage('ShipToSShipType');
end;
{ @end $612A18 }

{ @routine $612B34 GetCommunicatorCost }
function GetCommunicatorCost: Integer;
begin
  Result := Galaxy.ComputeScaledAverageMoney(oiPeople) * 5;
end;
{ @end $612B34 }

{ @routine $612B48 LocalizedText }
function LocalizedText(const Path: WideString): WideString;
var
  I, Count: Integer;
begin
  Result := '';
  Count := LanguageDataConfig.CountParamsByPath(Path);
  for I := 0 to Count - 1 do
  begin
    if Result <> '' then Result := Result + #13#10;
    Result := Result + LanguageDataConfig.GetParamByPath(Path + ':' + IntToStr(I));
  end;
  if FindTextPosW('<', Result) > 0 then
  begin
    Result := ReplaceAllWideString(Result, '<br>', #13#10);
    Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    if Player <> nil then
      Result := ReplaceAllWideString(Result, '<Player>', HighlightColorTag + Player.Name + ColorEndTag);
  end;
end;
{ @end $612B48 }

{ @routine $612D74 LocalizedColorText }
function LocalizedColorText(const Path: WideString): WideString;
var
  I, Count: Integer;
begin
  Result := '';
  Count := LanguageDataConfig.CountParamsByPath(Path);
  for I := 0 to Count - 1 do
  begin
    if Result <> '' then Result := Result + #13#10;
    Result := Result + LanguageDataConfig.GetParamByPath(Path + ':' + IntToStr(I));
  end;
  if FindTextPosW('<', Result) > 0 then
  begin
    Result := ReplaceAllWideString(Result, '<br>', #13#10);
    Result := ReplaceAllWideString(Result, '<ll>', #13#10' '#13#10);
    if Player <> nil then
      Result := ReplaceAllWideString(Result, '<Player>', HighlightColorTag + Player.Name + ColorEndTag);
    Result := ReplaceAllWideString(Result, '<clr>', HighlightColorTag);
    Result := ReplaceAllWideString(Result, '<clrEnd>', ColorEndTag);
  end;
end;
{ @end $612D74 }

{ @routine $613004 ExpandLocalizedTextMarkup }
procedure ExpandLocalizedTextMarkup(var Text: WideString);
begin
  if FindTextPosW('<', Text) > 0 then
  begin
    Text := ReplaceAllWideString(Text, '<br>', #13#10);
    Text := ReplaceAllWideString(Text, '<ll>', #13#10' '#13#10);
    if Player <> nil then
      Text := ReplaceAllWideString(Text, '<Player>', HighlightColorTag + Player.Name + ColorEndTag);
    Text := ReplaceAllWideString(Text, '<clr>', HighlightColorTag);
    Text := ReplaceAllWideString(Text, '<clrEnd>', ColorEndTag);
  end;
end;
{ @end $613004 }

{ @routine $6131E8 PickLocalizedTextVariant }
function PickLocalizedTextVariant(const Path: WideString; SeedOffset: Integer): WideString;
var
  Count, I: Integer;
  Variants: array[0..9] of WideString;
begin
  Count := 0;
  Variants[Count] := LocalizedText(Path);
  if Variants[Count] <> '' then Inc(Count);
  I := 1;
  repeat
    Variants[Count] := LocalizedColorText(Path + IntToStr(Count));
    if Variants[Count] <> '' then Inc(Count);
    Inc(I);
  until I > 9;
  if Count = 0 then
    Result := 'String: ' + WrapTextInColor(Path, HighlightColorTag) + ' is unavailable'
  else if Count = 1 then Result := Variants[0]
  else
  begin
    Count := SeededRandomIntRange(0, Count - 1, (Galaxy.CurrentTurn + SeedOffset) div 10);
    Result := Variants[Count];
  end;
end;
{ @end $6131E8 }

end.

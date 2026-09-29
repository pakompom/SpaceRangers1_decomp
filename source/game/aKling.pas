unit aKling;
// Unit bracket (inferred): CODE 0x00543E5C..0x00548287; inclusive evidence, not full bounds.
// Klissan ship: native VMT $543E5C, 436-byte instance.
interface
uses aShip, aPlanet, aGalaxy, EC_Buf;
type
  TKling = class(TShip) // @size $1B4
  public
    procedure InitGenerated(Kind: TKlingType; Planet: TPlanet); // @addr $5443C4
    procedure NextDay; override; // @addr $5472AC
    function JumpToReinforcedStar: Boolean; // @addr $547784
    procedure DispatchFleetToAttack; // @addr $5478AC
    procedure AssignWeaponTargetsInStar; // @addr $547C68
    procedure TrainInitialSkills; // @addr $5481F4
    procedure InitMotherShip; // @addr $543F6C
    function LandOnRandomFriendlyPlanet(Absolute: Boolean): Boolean; // @addr $5476C8
    procedure MoveToRandomPlanetOrbit; // @addr $547850
    KlingType: TKlingType; // @offset $1B0 Save/load $547258/$547280 and sprite selection $5B1684.
    destructor Destroy; override; // @addr $543F44
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $547258
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $547280
    procedure ResolveLoadedReferences; override; // @addr $5472A4
    function GetName: WideString; override; // @addr $547B80
    function GetFullName(const Separator: WideString): WideString; override; // @addr $547B94
    function GetTypeNameKey: WideString; override; // @addr $547BE8
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $547C0C
    function GetHomeStar: TStar; override; // @addr $547B7C
    function GetDominantCareer: TRangerCareer; override; // @addr $547C10
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $547C14
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $547C18
    procedure RefuelAtLocation; override; // @addr $547C1C
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $547B20
    procedure BuildReachablePlanetQueue; override; // @addr $547714
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $547778
    procedure SelectEnemyShipInStar; override; // @addr $547FB0
    procedure EngageEnemyShip; override; // @addr $5480CC
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $547C38
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $547C3C
    procedure ReactToAttack(Attacker: TShip); override; // @addr $547C40
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $547C2C
    function RecomputeFearState: Boolean; override; // @addr $547C50
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $547C54
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $547C58
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $547C5C
    procedure BuyInitialEquipment; override; // @addr $547B18
    procedure UpgradeEquipmentAtLocation; override; // @addr $547B1C
    procedure ProcessCombatDialogue; override; // @addr $54813C
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $548140
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $548144
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $548150
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $548154
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $548160
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $54816C
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $5481B0
  end;
var
  KlingMotherShip: TShip; // @addr $61CFAC Direct accesses in $5472AC/$5478AC establish aKling ownership.
var
  KlissanSpawnPlanet: TPlanet; // @addr $61CFB0

implementation

// @unit-initialization $548280
// @unit-finalization $548250

uses aScript, aAsteroid, GlobalsV, Classes, aRanger, aItem, aConst, aMyFunction, Globals, SE_Ship2, Math, SysUtils;

{ @routine $543F44 TKling_Destroy }
destructor TKling.Destroy;
begin
  inherited Destroy;
end;
{ @end $543F44 }

{ @routine $543F6C TKling_InitMotherShip }
procedure TKling.InitMotherShip;
begin
  ShipType := t_Kling;
  OwnerId := oiKling;
  KlingType := ktMakhpella;
  SetMoney(MaxInt);
  Position.X := 0;
  Position.Y := 0;
  CurrentStar := Player.CurrentStar.StarDistances[Galaxy.Stars.Count - 1].Star as TStar;
  CurrentStar.Ships.Add(Self);
  HomePlanet := nil;
  CurrentPlanet := nil;
  Inc(CurrentStar.ShipTypeCounts[t_Kling]);
  Name := KlissanInfo[KlingType].DisplayName;
  if Player <> nil then GainExperience(12600);
  Graphic := TShip2SE.CreateEmpty;
  KlissanRenderTemplates[Ord(KlingType)].SpaceObject.CopyTo(Graphic);
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(200);
  CollisionRadius := 74;
  CreateAndEquipHull(True, RoundAndTruncateToTens(NextRandomFloatRange(0.9, 1.1, RandomState) *
    (2500 * DifficultyModifiers[Galaxy.Difficulty].MotherShipHullFactor)), 8, oiKling);
  CreateAndEquipFuelTanks(True, 100, 8, oiKling);
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 8, oiKling);
  CreateAndEquipWeapon(t_EyesOfMachpella, True, Round(WeaponInfo[t_EyesOfMachpella].Weight * ItemSizeFactors[5]), 8, oiKling);
  CreateAndEquipWeapon(t_HellWave, True, Round(WeaponInfo[t_HellWave].Weight * ItemSizeFactors[5]), 8, oiKling);
  CreateAndEquipWeapon(t_AbsoluteMatrix, True, Round(WeaponInfo[t_AbsoluteMatrix].Weight * ItemSizeFactors[5]), 8, oiKling);
  CreateAndEquipWeapon(t_AbsoluteMatrix, True, Round(WeaponInfo[t_AbsoluteMatrix].Weight * ItemSizeFactors[5]), 8, oiKling);
  if Galaxy.Difficulty > dfNormal then CreateAndEquipWeapon(t_EyesOfMachpella, True, Round(WeaponInfo[t_EyesOfMachpella].Weight * ItemSizeFactors[5]), 8, oiKling);
  CreateAndEquipDefGenerator(True, Round(40 * ItemSizeFactors[5]), 8, oiKling);
  CreateAndEquipRepairRobot(True, Round(40 * ItemSizeFactors[5]), Round(RemapClamped(Ord(Galaxy.Difficulty), 0, 3, 4, 8)), OwnerId);
  RefreshDerivedStats;
  if DefGenerator <> nil then
    case Galaxy.Difficulty of
      dfNormal: DefGenerator.Improve(ikMinor);
      dfHard: DefGenerator.Improve(ikMedium);
      dfExpert: DefGenerator.Improve(ikMajor);
    end;
  if Speed = 0 then raise Exception.Create('Клинг выпустился со скоростью 0');
end;
{ @end $543F6C }

{ @routine $5443C4 TKling_InitGenerated }
procedure TKling.InitGenerated(Kind: TKlingType; Planet: TPlanet);
var
  HullCap, FuelCap, EngineCap, RadarCap, ScannerCap, HookCap, ShieldCap, RobotCap: Byte;
  BestRanger: TRanger;
  I: Integer;
  Item: TEquipment;

  // @nested $5442E0 RandomSize
  function RandomSize(Value: Single): Integer; // @addr $5442E0
  begin
    Result := NextRandomIntRange(Round(Value * 0.8), Round(Value * 1.2), RandomState);
  end;

  // @nested $544330 RandomLevel
  function RandomLevel(LowLevel, HighLevel: Integer): Integer; // @addr $544330
  begin
    Result := Round(RemapClamped(Galaxy.TechLevel, 2, 8, LowLevel, HighLevel));
    Result := Max(Min(Result + NextRandomIntRange(-2, 1, RandomState), HighLevel), LowLevel);
  end;

begin
  ShipType := t_Kling;
  OwnerId := oiKling;
  KlingType := Kind;
  SetMoney(Round(Galaxy.MaxRangerWealth * KlissanInfo[Kind].MoneyFactor));
  NodeReserve := Round((NextRandomUnitFloat(RandomState) + 0.5) * KlissanInfo[Kind].NodeBase);
  case KlingType of
    ktMakhpella: ; // The mother ship has a separate initializer.
    ktEgemon..ktMutenok: begin
      CurrentStar := Planet.CurrentStar;
      CurrentStar.Ships.Add(Self);
      HomePlanet := nil;
      CurrentPlanet := Planet;
    end;
  end;
  Inc(CurrentStar.ShipTypeCounts[t_Kling]);
  Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Kling').GetParamValue(
    NextRandomIntRange(0, LanguageDataConfig.GetBlock('ShipName').GetBlock('Kling').GetParamCount - 1, RandomState)) +
    ' ' + '-' + IntToStr(Id mod 100 + 1) + '-';
  if Player <> nil then GainExperience(Round(RemapClampedAlternate(Ord(KlingType), 0, 5,
    RemapClamped(Galaxy.TechLevel, 3, 8, 2520, 12600), 840)));
  TrainInitialSkills;
  Graphic := TShip2SE.CreateEmpty;
  KlissanRenderTemplates[Ord(KlingType)].SpaceObject.CopyTo(Graphic);
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(200);
  CollisionRadius := 32;
  BestRanger := Galaxy.StrongestRanger as TRanger;
  // Equipment caps follow the strongest ranger; the hull retains its full level.
  if BestRanger = nil then begin
    HullCap := NextRandomIntRange(1, 4, RandomState);
    FuelCap := NextRandomIntRange(1, 4, RandomState);
    EngineCap := NextRandomIntRange(1, 4, RandomState);
    RadarCap := NextRandomIntRange(1, 4, RandomState);
    ScannerCap := NextRandomIntRange(1, 4, RandomState);
    HookCap := NextRandomIntRange(1, 4, RandomState);
    ShieldCap := NextRandomIntRange(1, 4, RandomState);
    RobotCap := NextRandomIntRange(1, 4, RandomState);
  end else begin
    HullCap := BestRanger.Hull.TechLevel;
    if BestRanger.FuelTanks <> nil then FuelCap := Min(4, BestRanger.FuelTanks.TechLevel)
    else FuelCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.Engine <> nil then EngineCap := Min(4, BestRanger.Engine.TechLevel)
    else EngineCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.Radar <> nil then RadarCap := Min(4, BestRanger.Radar.TechLevel)
    else RadarCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.Scanner <> nil then ScannerCap := Min(4, BestRanger.Scanner.TechLevel)
    else ScannerCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.CargoHook <> nil then HookCap := Min(4, BestRanger.CargoHook.TechLevel)
    else HookCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.DefGenerator <> nil then ShieldCap := Min(4, BestRanger.DefGenerator.TechLevel)
    else ShieldCap := NextRandomIntRange(1, 4, RandomState);
    if BestRanger.RepairRobot <> nil then RobotCap := Min(4, BestRanger.RepairRobot.TechLevel)
    else RobotCap := NextRandomIntRange(1, 4, RandomState);
  end;
  case KlingType of
    ktEgemon: CreateAndEquipHull(True, RandomSize(RemapClamped(Galaxy.TechLevel, 4, 8, 900, 1300) *
      DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor), Min(HullCap, RandomLevel(1, 8)), oiKling);
    ktNondus: CreateAndEquipHull(True, RandomSize(RemapClamped(Galaxy.TechLevel, 4, 8, 500, 800) *
      DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor), Min(HullCap, RandomLevel(1, 8)), oiKling);
    ktKatauri: CreateAndEquipHull(True, RandomSize(RemapClamped(Galaxy.TechLevel, 4, 8, 300, 600) *
      DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor), Min(HullCap, RandomLevel(1, 8)), oiKling);
    ktRoggit: CreateAndEquipHull(True, RandomSize(RemapClamped(Galaxy.TechLevel, 4, 8, 200, 300) *
      DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor), Min(HullCap, RandomLevel(1, 7)), oiKling);
    ktMutenok: CreateAndEquipHull(True, RandomSize(RemapClamped(Galaxy.TechLevel, 4, 8, 120, 180) *
      DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor), Min(HullCap, RandomLevel(1, 6)), oiKling);
  end;
  if (NextRandomIntRange(1, 3, RandomState) = 1) and (Galaxy.WarDeltaWin > 0) then Hull.Improve(ikAny)
  else if Galaxy.CurrentTurn > 11000 then Inc(Hull.Armor, SeededRandomIntRange(3, 15, 271 * Id));
  case KlingType of
    ktEgemon: CreateAndEquipFuelTanks(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 40),
      Min(FuelCap, RandomLevel(1, 6)), oiKling);
    ktNondus: CreateAndEquipFuelTanks(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 40),
      Min(FuelCap, RandomLevel(1, 5)), oiKling);
    ktKatauri: CreateAndEquipFuelTanks(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(FuelCap, RandomLevel(1, 4)), oiKling);
    ktRoggit: CreateAndEquipFuelTanks(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(FuelCap, RandomLevel(1, 3)), oiKling);
    ktMutenok: CreateAndEquipFuelTanks(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 40),
      Min(FuelCap, RandomLevel(1, 2)), oiKling);
  end;
  if (NextRandomIntRange(1, 3, RandomState) = 1) and (Galaxy.WarDeltaWin > 0) then FuelTanks.Improve(ikAny);
  case KlingType of
    ktEgemon: CreateAndEquipEngine(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 40),
      Min(EngineCap, RandomLevel(1, 8)), oiKling);
    ktNondus: CreateAndEquipEngine(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 40),
      Min(EngineCap, RandomLevel(1, 7)), oiKling);
    ktKatauri: CreateAndEquipEngine(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(EngineCap, RandomLevel(1, 7)), oiKling);
    ktRoggit: CreateAndEquipEngine(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(EngineCap, RandomLevel(1, 6)), oiKling);
    ktMutenok: CreateAndEquipEngine(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 40),
      Min(EngineCap, RandomLevel(1, 6)), oiKling);
  end;
  if (NextRandomIntRange(1, 3, RandomState) = 1) and (Galaxy.WarDeltaWin > 0) then Engine.Improve(ikAny)
  else if Galaxy.CurrentTurn > 11000 then Engine.Improve(ikMajor);
  if NextRandomUnitFloat(RandomState) > 0.5 then
  case KlingType of
    ktEgemon: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRadar(True, RandomSize(ItemSizeFactors[RandomInt(1, 2)] * 30),
      Min(RadarCap, RandomLevel(1, 8)), oiKling);
    ktNondus: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRadar(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 30),
      Min(RadarCap, RandomLevel(1, 7)), oiKling);
    ktKatauri: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRadar(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 30),
      Min(RadarCap, RandomLevel(1, 6)), oiKling);
    ktRoggit: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRadar(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 30),
      Min(RadarCap, RandomLevel(1, 5)), oiKling);
    ktMutenok: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRadar(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 30),
      Min(RadarCap, RandomLevel(1, 4)), oiKling);
  end;
  if (Radar <> nil) and (Galaxy.WarDeltaWin > 0) and (NextRandomIntRange(1, 3, RandomState) = 1) then Radar.Improve(ikAny);
  if (Radar <> nil) and (NextRandomUnitFloat(RandomState) > 0.5) then
  case KlingType of
    ktEgemon: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipScanner(True, RandomSize(ItemSizeFactors[RandomInt(1, 2)] * 30),
      Min(ScannerCap, RandomLevel(1, 8)), oiKling);
    ktNondus: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipScanner(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 30),
      Min(ScannerCap, RandomLevel(1, 7)), oiKling);
    ktKatauri: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipScanner(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 30),
      Min(ScannerCap, RandomLevel(1, 6)), oiKling);
    ktRoggit: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipScanner(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 30),
      Min(ScannerCap, RandomLevel(1, 5)), oiKling);
    ktMutenok: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipScanner(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 30),
      Min(ScannerCap, RandomLevel(1, 4)), oiKling);
  end;
  if (Scanner <> nil) and (Galaxy.WarDeltaWin > 0) and (NextRandomIntRange(1, 3, RandomState) = 1) then Scanner.Improve(ikAny);
  case KlingType of
    ktEgemon: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipCargoHook(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 40),
      Min(HookCap, RandomLevel(1, 8)), oiKling);
    ktNondus: if NextRandomUnitFloat(RandomState) > 0.6 then CreateAndEquipCargoHook(True, RandomSize(ItemSizeFactors[RandomInt(2, 3)] * 40),
      Min(HookCap, RandomLevel(1, 7)), oiKling);
    ktKatauri: if NextRandomUnitFloat(RandomState) > 0.7 then CreateAndEquipCargoHook(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 40),
      Min(HookCap, RandomLevel(1, 6)), oiKling);
    ktRoggit: if NextRandomUnitFloat(RandomState) > 0.8 then CreateAndEquipCargoHook(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(HookCap, RandomLevel(1, 5)), oiKling);
    ktMutenok: if NextRandomUnitFloat(RandomState) > 0.9 then CreateAndEquipCargoHook(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 40),
      Min(HookCap, RandomLevel(1, 4)), oiKling);
  end;
  if (CargoHook <> nil) and (Galaxy.WarDeltaWin > 0) and (NextRandomIntRange(1, 3, RandomState) = 1) then CargoHook.Improve(ikAny);
  case KlingType of
    ktEgemon: CreateAndEquipDefGenerator(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 40),
      Min(ShieldCap, RandomLevel(1, 8)), oiKling);
    ktNondus: CreateAndEquipDefGenerator(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 40),
      Min(ShieldCap, RandomLevel(1, 8)), oiKling);
    ktKatauri: CreateAndEquipDefGenerator(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(ShieldCap, RandomLevel(1, 7)), oiKling);
    ktRoggit: CreateAndEquipDefGenerator(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(ShieldCap, RandomLevel(1, 6)), oiKling);
    ktMutenok: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipDefGenerator(True, RandomSize(ItemSizeFactors[RandomInt(5, 5)] * 40),
      Min(ShieldCap, RandomLevel(1, 5)), oiKling);
  end;
  if (DefGenerator <> nil) and (Galaxy.WarDeltaWin > 0) and (NextRandomIntRange(1, 3, RandomState) = 1) then DefGenerator.Improve(ikAny);
  case KlingType of
    ktEgemon: CreateAndEquipRepairRobot(True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * 40),
      Min(RobotCap, RandomLevel(1, 8)), OwnerId);
    ktNondus: CreateAndEquipRepairRobot(True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * 40),
      Min(RobotCap, RandomLevel(1, 6)), OwnerId);
    ktKatauri: CreateAndEquipRepairRobot(True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * 40),
      Min(RobotCap, RandomLevel(1, 5)), OwnerId);
    ktRoggit: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRepairRobot(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 40),
      Min(RobotCap, RandomLevel(1, 5)), OwnerId);
    ktMutenok: if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipRepairRobot(True, RandomSize(ItemSizeFactors[RandomInt(4, 5)] * 40),
      Min(RobotCap, RandomLevel(1, 3)), OwnerId);
  end;
  if (RepairRobot <> nil) and (Galaxy.WarDeltaWin > 0) and (NextRandomIntRange(1, 3, RandomState) = 1) then RepairRobot.Improve(ikAny);
  case KlingType of
    ktEgemon: begin
      CreateAndEquipWeapon(t_EyesOfMachpella, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_EyesOfMachpella].Weight), RandomLevel(1, 8), oiKling);
      if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_HellWave, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_HellWave].Weight), RandomLevel(1, 8), oiKling)
      else CreateAndEquipWeapon(t_AbsoluteMatrix, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_AbsoluteMatrix].Weight), RandomLevel(1, 8), oiKling);
      if (Galaxy.TechLevel >= 6) and (NextRandomUnitFloat(RandomState) > 0.5) then CreateAndEquipWeapon(t_AbsoluteMatrix, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_AbsoluteMatrix].Weight), RandomLevel(1, 8), oiKling)
      else CreateAndEquipWeapon(t_GravitonBeamer, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_GravitonBeamer].Weight), RandomLevel(3, 8), oiKling);
      if (Galaxy.TechLevel >= 7) and (NextRandomUnitFloat(RandomState) > 0.5) then CreateAndEquipWeapon(t_VortexProjector, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_VortexProjector].Weight), RandomLevel(1, 8), oiKling);
      if (Galaxy.TechLevel >= 6) and (NextRandomUnitFloat(RandomState) > 0.5) then CreateAndEquipWeapon(t_TachionCleaver, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_TachionCleaver].Weight), RandomLevel(1, 8), oiKling);
    end;
    ktNondus: begin
      if NextRandomUnitFloat(RandomState) > 0.8 then CreateAndEquipWeapon(t_EyesOfMachpella, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_EyesOfMachpella].Weight), RandomLevel(1, 8), oiKling)
      else CreateAndEquipWeapon(t_HellWave, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_HellWave].Weight), RandomLevel(1, 8), oiKling);
      if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_AbsoluteMatrix, True, RandomSize(ItemSizeFactors[RandomInt(1, 4)] * WeaponInfo[t_AbsoluteMatrix].Weight), RandomLevel(1, 8), oiKling);
      if Galaxy.TechLevel >= 7 then begin
        if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_XDefibrillator, True, RandomSize(ItemSizeFactors[RandomInt(2, 3)] * WeaponInfo[t_XDefibrillator].Weight), RandomLevel(1, 8), oiKling)
        else CreateAndEquipWeapon(t_AeonicBlaster, True, RandomSize(ItemSizeFactors[RandomInt(1, 3)] * WeaponInfo[t_AeonicBlaster].Weight), RandomLevel(1, 8), oiKling);
        if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_FieldAnnihilator, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_FieldAnnihilator].Weight), RandomLevel(1, 8), oiKling);
      end else CreateAndEquipWeapon(t_GravitonBeamer, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_GravitonBeamer].Weight), RandomLevel(1, 8), oiKling);
    end;
    ktKatauri: begin
      if NextRandomUnitFloat(RandomState) > 0.8 then CreateAndEquipWeapon(t_EyesOfMachpella, True, RandomSize(ItemSizeFactors[RandomInt(3, 5)] * WeaponInfo[t_EyesOfMachpella].Weight), RandomLevel(1, 7), oiKling);
      if Galaxy.TechLevel >= 6 then begin
        if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_KellersPhaser, True, RandomSize(ItemSizeFactors[RandomInt(2, 3)] * WeaponInfo[t_KellersPhaser].Weight), RandomLevel(1, 8), oiKling)
        else CreateAndEquipWeapon(t_XDefibrillator, True, RandomSize(ItemSizeFactors[RandomInt(2, 3)] * WeaponInfo[t_XDefibrillator].Weight), RandomLevel(1, 8), oiKling);
      end else begin
        if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_GravitonBeamer, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_GravitonBeamer].Weight), RandomLevel(1, 8), oiKling)
        else CreateAndEquipWeapon(t_ZipGun, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_ZipGun].Weight), RandomLevel(1, 8), oiKling);
      end;
      if NextRandomUnitFloat(RandomState) > 0.5 then CreateAndEquipWeapon(t_Retractor, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_Retractor].Weight), RandomLevel(1, 8), oiKling)
      else CreateAndEquipWeapon(t_GravitonBeamer, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_GravitonBeamer].Weight), RandomLevel(1, 8), oiKling);
      if (Galaxy.TechLevel > 5) and (NextRandomUnitFloat(RandomState) > 0.5) then CreateAndEquipWeapon(t_TachionCleaver, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_TachionCleaver].Weight), RandomLevel(1, 8), oiKling);
    end;
    ktRoggit: begin
      if NextRandomUnitFloat(RandomState) > 0.5 then begin
        CreateAndEquipWeapon(t_GravitonBeamer, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_GravitonBeamer].Weight), RandomLevel(1, 8), oiKling);
        CreateAndEquipWeapon(t_IndustrialLaser, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_IndustrialLaser].Weight), RandomLevel(1, 8), oiKling);
      end else begin
        CreateAndEquipWeapon(t_PhotonGun, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_PhotonGun].Weight), RandomLevel(1, 8), oiKling);
        CreateAndEquipWeapon(t_KellersPhaser, True, RandomSize(ItemSizeFactors[RandomInt(2, 4)] * WeaponInfo[t_KellersPhaser].Weight), RandomLevel(1, 8), oiKling);
      end;
      if (Galaxy.TechLevel > 5) and (NextRandomUnitFloat(RandomState) > 0.8) then CreateAndEquipWeapon(t_AeonicBlaster, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_AeonicBlaster].Weight), RandomLevel(1, 8), oiKling)
      else if NextRandomUnitFloat(RandomState) > 0.8 then CreateAndEquipWeapon(t_ZipGun, True, RandomSize(ItemSizeFactors[RandomInt(2, 5)] * WeaponInfo[t_ZipGun].Weight), RandomLevel(1, 8), oiKling);
    end;
    ktMutenok: begin
      if NextRandomUnitFloat(RandomState) > 0.5 then begin
        CreateAndEquipWeapon(t_PhotonGun, True, RandomSize(ItemSizeFactors[RandomInt(3, 4)] * WeaponInfo[t_PhotonGun].Weight), RandomLevel(1, 8), oiKling);
        CreateAndEquipWeapon(t_IndustrialLaser, True, RandomSize(ItemSizeFactors[RandomInt(1, 4)] * WeaponInfo[t_IndustrialLaser].Weight), RandomLevel(1, 8), oiKling);
      end else begin
        CreateAndEquipWeapon(t_PhotonGun, True, RandomSize(ItemSizeFactors[RandomInt(3, 5)] * WeaponInfo[t_PhotonGun].Weight), RandomLevel(1, 8), oiKling);
        CreateAndEquipWeapon(t_KellersPhaser, True, RandomSize(ItemSizeFactors[RandomInt(3, 5)] * WeaponInfo[t_KellersPhaser].Weight), RandomLevel(1, 8), oiKling);
      end;
      if (Galaxy.TechLevel > 6) and (NextRandomUnitFloat(RandomState) > 0.7) then CreateAndEquipWeapon(t_AeonicBlaster, True, RandomSize(ItemSizeFactors[RandomInt(3, 5)] * WeaponInfo[t_AeonicBlaster].Weight), RandomLevel(1, 8), oiKling);
    end;
  end;
  if GetCargoFreeSpace < 0 then begin
    if ((Player <> nil) and (Player.StrengthInBestRanger > 0.9)) or
      (NextRandomIntRange(10, 40, RandomState) > (Galaxy.GetFactionControlPercent(sfKlissan))) or
      (Abs(GetCargoFreeSpace) < 50) then Inc(Hull.Weight, Abs(GetCargoFreeSpace));
    Hull.HullPoints := Hull.Weight;
  end;
  if GetCargoFreeSpace < 0 then begin
    if CountEquippedWeapons > 2 then LiquidateInventoryItem(Weapons[GetHeaviestWeaponIndex - 1]);
    if GetCargoFreeSpace < 0 then begin
      if CargoHook <> nil then LiquidateInventoryItem(CargoHook);
      if GetCargoFreeSpace < 0 then begin
        if Scanner <> nil then LiquidateInventoryItem(Scanner);
        if (CountEquippedWeapons > 2) and (NextRandomUnitFloat(RandomState) > 0.5) then
          LiquidateInventoryItem(Weapons[GetHeaviestWeaponIndex - 1]);
        if GetCargoFreeSpace < 0 then begin
          if DefGenerator <> nil then LiquidateInventoryItem(DefGenerator);
          if GetCargoFreeSpace < 0 then begin
            if RepairRobot <> nil then LiquidateInventoryItem(RepairRobot);
            if GetCargoFreeSpace < 0 then begin
              if Radar <> nil then LiquidateInventoryItem(Radar);
              if GetCargoFreeSpace < 0 then begin
                if CountEquippedWeapons > 1 then LiquidateInventoryItem(Weapons[GetHeaviestWeaponIndex - 1]);
                if GetCargoFreeSpace < 0 then Inc(Hull.Weight, Abs(GetCargoFreeSpace));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  RefreshDerivedStats;
  if (NextRandomIntRange(10, 80, RandomState) > (Galaxy.GetFactionControlPercent(sfKlissan))) or
    (Galaxy.CurrentTurn < 11000) then
    if DefGenerator <> nil then
      case Galaxy.Difficulty of
        dfNormal: DefGenerator.Improve(ikMinor);
        dfHard: DefGenerator.Improve(ikMedium);
        dfExpert: DefGenerator.Improve(ikMajor);
      end;
  if (NextRandomIntRange(30, 100, RandomState) < (Galaxy.GetFactionControlPercent(sfKlissan))) and
    (Galaxy.CurrentTurn < 11000) and (Galaxy.WarDeltaWin < 5) and
    (StrengthInBestRanger > KlissanInfo[KlingType].StrengthCap) then begin
    if WeaponCount > 2 then LiquidateInventoryItem(Weapons[GetHeaviestWeaponIndex - 1]);
    if StrengthInBestRanger > KlissanInfo[KlingType].StrengthCap * 2 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor then
      if (Galaxy.GetFactionControlPercent(sfKlissan)) > 20 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor then begin
        if WeaponCount > 2 then LiquidateInventoryItem(Weapons[GetHeaviestWeaponIndex - 1]);
        if StrengthInBestRanger > KlissanInfo[KlingType].StrengthCap * 2 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor then
          if (Galaxy.GetFactionControlPercent(sfKlissan)) > 20 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor then
            if DefGenerator <> nil then LiquidateInventoryItem(DefGenerator);
      end;
  end;
  if (Galaxy.CurrentTurn > 11000) or (Galaxy.WarDeltaWin > 5) or (NextRandomIntRange(1, 4, RandomState) = 1) then
    for I := 1 to WeaponCount do
      if (Galaxy.CurrentTurn > 11000) or (NextRandomIntRange(1, 4, RandomState) = 1) then Weapons[I - 1].Improve(ikAny);
  for I := 1 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    Item.ConditionPercent := NextRandomIntRange(5, 100, RandomState);
  end;
  RefreshDerivedStats;
end;
{ @end $5443C4 }

{ @routine $547258 TKling_SaveToBuffer }
procedure TKling.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(KlingType)));
end;
{ @end $547258 }

{ @routine $547280 TKling_LoadFromBuffer }
procedure TKling.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  WriteByteValue(Buffer.GetByte, KlingType);
end;
{ @end $547280 }

{ @routine $5472A4 TKling_ResolveLoadedReferences }
procedure TKling.ResolveLoadedReferences;
begin
  inherited ResolveLoadedReferences;
end;
{ @end $5472A4 }

{ @routine $5472AC TKling_NextDay }
procedure TKling.NextDay;
var I: Integer;
begin
  if (Galaxy.CurrentTurn + Integer(Seed)) mod 100 = 0 then CalculateStrength;
  inherited NextDay;
  if ScriptShip <> nil then begin
    ScriptNextDay;
    if (KlingType <> ktMakhpella) and (ScriptShip <> nil) then Exit;
  end;
  if InNormalSpace and (KlingType = ktMakhpella) and (ScenarioState in [scenAllianceAgainstRachekhan..scenPeaceRachekhanAtLarge]) then begin
    for I := 0 to Galaxy.Holes.Count - 1 do
      if THole(Galaxy.Holes[I]).HoleType = bhkMachpella then
        if THole(Galaxy.Holes[I]).Star1 = CurrentStar then OrderEnterBlackHole(Galaxy.Holes[I], True, False)
        else OrderEnterBlackHole(Galaxy.Holes[I], False, False);
    if ScenarioState = scenMachpellaFled then AssignWeaponTargetsInStar
    else for I := 1 to WeaponCount do Weapons[I - 1].Target := nil;
    Exit;
  end;
  case KlingType of
    ktMakhpella: begin
      // Native code evaluates this condition but discards its result before the repair branch.
      if (Player.CurrentStar = CurrentStar) or (CurrentStar.ShipTypeCounts[t_Kling] < 10) then ;
      if CurrentStar.ShipTypeCounts[t_Kling] = CurrentStar.Ships.Count then begin
        RepairBrokenEquipmentAtLocation;
        Hull.HullPoints := Hull.Weight;
        RefuelAtLocation;
        RefreshDerivedStats;
      end else if Player.CurrentStar <> CurrentStar then begin
        RepairBrokenEquipmentAtLocation;
        Hull.HullPoints := Max(Hull.HullPoints, Hull.Weight div 2);
        RefuelAtLocation;
      end;
      if InNormalSpace then begin
        if not OrderAbsolute then begin
          if ((CurrentStar.ShipTypeCounts[t_Kling] >= 10) or
            (CurrentStar.SumBestRangerRelativeStrength([t_Kling]) > KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier])) and
            ((Galaxy.CurrentTurn mod NextRandomIntRange(2, 7, RandomState) = 0) or (Galaxy.WarDeltaWin > 4)) and
            (CurrentStar.ControlFaction in [sfKlissan]) and not CurrentStar.Battle and
            (CurrentStar.ShipTypeCounts[t_Kling] = CurrentStar.Ships.Count) then DispatchFleetToAttack;
          if (DaysSincePlayerSeen > 3) and
            ((Galaxy.CurrentTurn + Integer(Seed)) mod (10 - Ord(Galaxy.Difficulty)) = 0) and
            (CurrentStar.ShipTypeCounts[t_Kling] >= 1) then JumpToReinforcedStar;
          if Order = soNone then MoveToRandomPlanetOrbit;
        end;
        AssignWeaponTargetsInStar;
        if Player.CurrentStar = CurrentStar then begin
          SelectEnemyShipInStar;
          EngageEnemyShip;
        end;
      end;
    end;
    ktEgemon..ktMutenok: begin
      if ScenarioState in [scenAllianceAgainstRachekhan] then begin ClearWeaponTargets(nil); OrderNone; Exit; end;
      if IsFinalScenarioActive then begin
        if CurrentPlanet <> nil then OrderTakeoff
        else if InNormalSpace then begin ClearWeaponTargets(nil); DestroyKind := 1; end;
      end else if CurrentPlanet <> nil then begin
        RepairBrokenEquipmentAtLocation;
        RefuelAtLocation;
        RefreshDerivedStats;
        OrderTakeoff;
      end else if DockedTo = KlingMotherShip then OrderTakeoff
      else if InNormalSpace then begin
        AssignWeaponTargetsInStar;
        if not OrderAbsolute or not (OrderTarget is TShip) then begin
          SelectEnemyShipInStar;
          EngageEnemyShip;
          if (Order = soNone) and HasHullDamageOrBrokenEquippedItems then LandOnRandomFriendlyPlanet(False);
          if Order = soNone then MoveToRandomPlanetOrbit;
        end;
      end;
    end;
  end;
end;
{ @end $5472AC }

{ @routine $5476C8 TKling_LandOnRandomFriendlyPlanet }
function TKling.LandOnRandomFriendlyPlanet(Absolute: Boolean): Boolean;
begin
  BuildReachablePlanetQueue;
  if PlanetQueue.Count > 0 then begin
    OrderLanding(PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)], Absolute);
    Result := True;
  end else Result := False;
end;
{ @end $5476C8 }

{ @routine $547714 TKling_BuildReachablePlanetQueue }
procedure TKling.BuildReachablePlanetQueue;
var I: Integer; Planet: TPlanet;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if Speed <> 0 then
    for I := 0 to CurrentStar.Planets.Count - 1 do begin
      Planet := CurrentStar.Planets[I];
      if Planet.OwnerId = oiKling then PlanetQueue.Add(Planet);
    end;
end;
{ @end $547714 }

{ @routine $547778 TKling_CanQueueReachablePlanet }
function TKling.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId = oiKling;
end;
{ @end $547778 }

{ @routine $547784 TKling_JumpToReinforcedStar }
function TKling.JumpToReinforcedStar: Boolean;
var I, Index: Integer; Star: TStar;
begin
  Result := False;
  Index := Galaxy.Stars.IndexOf(CurrentStar);
  for I := 1 to Galaxy.Stars.Count - 1 do begin
    IncrementWrapped(Index, 0, Galaxy.Stars.Count - 1);
    Star := Galaxy.Stars[Index];
    if not IsStarProtectedByScript(Star) and
      ((Star.ShipTypeCounts[t_Kling] >= 10) or
       (Star.SumBestRangerRelativeStrength([t_Kling]) >= KlissanFleetStrengthThresholds[Star.Constellation.HomeDistanceTier])) and
      (Star.ShipTypeCounts[t_Kling] >= 6) and (Star.ControlFaction in [sfKlissan]) and not Star.Battle then begin
      OrderJump(Star, True);
      Result := True;
      Exit;
    end;
  end;
end;
{ @end $547784 }

{ @routine $547850 TKling_MoveToRandomPlanetOrbit }
procedure TKling.MoveToRandomPlanetOrbit;
var Orbit: TPolarPoint;
begin
  Orbit := TPlanet(CurrentStar.Planets[0]).Orbit;
  Orbit.AngleDegrees := NextRandomIntRange(0, 359, RandomState);
  OrderMove(PolarToPoint(Orbit), False);
end;
{ @end $547850 }

{ @routine $5478AC TKling_DispatchFleetToAttack }
procedure TKling.DispatchFleetToAttack;
var I, J, Score, BestScore: Integer; Star, BestStar: TStar; Ship: TShip;
begin
  BestScore := MaxInt;
  BestStar := nil;
  for I := 1 to Galaxy.Stars.Count - 1 do begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if (Star.ControlFaction in [sfKlissan]) and not Star.Battle then Continue;
    if Star.Battle and (Star.ShipTypeCounts[t_Kling] > 4) then Continue;
    if IsStarProtectedByScript(Star) then Continue;
    Score := 0;
    for J := 1 to Galaxy.Stars.Count - 1 do begin
      if (Star.StarDistances[J].Star as TStar).ControlFaction in [sfKlissan] then Inc(Score, Star.StarDistances[J].Distance)
      else if (Star.StarDistances[J].Star as TStar).Battle then Inc(Score, 2 * Star.StarDistances[J].Distance);
    end;
    Score := Round(RemapClamped(Star.CountShipsByTypeMask([t_Ranger..t_Tranclucator]), 1, 10, 1, 5) * Score);
    Score := Round(NextRandomFloatRange(1, 3, RandomState) * Score);
    if Star = Player.HomePlanet.CurrentStar then begin
      if Galaxy.GetFactionControlPercent(sfCoalition) > 30 then Score := MaxInt - 1
      else if Galaxy.CurrentTurn < 800 * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor + 200 then Score := MaxInt - 1;
    end;
    if Score < BestScore then begin
      BestScore := Score;
      BestStar := Star;
    end;
  end;
  if BestStar <> nil then
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if not Ship.OrderAbsolute and (Ship.OwnerId = oiKling) and Ship.InNormalSpace and (Ship <> KlingMotherShip) then
        Ship.OrderJump(BestStar, True);
    end;
end;
{ @end $5478AC }

{ @routine $547B18 TKling_BuyInitialEquipment }
procedure TKling.BuyInitialEquipment;
begin

end;
{ @end $547B18 }

{ @routine $547B1C TKling_UpgradeEquipmentAtLocation }
procedure TKling.UpgradeEquipmentAtLocation;
begin

end;
{ @end $547B1C }

{ @routine $547B20 TKling_RepairBrokenEquipmentAtLocation }
procedure TKling.RepairBrokenEquipmentAtLocation;
var I: Integer; Item: TEquipment;
begin
  Hull.HullPoints := Hull.Weight;
  for I := 1 to Inventory.Count - 1 do begin
    Item := Inventory[I];
    if Item.BrokenFlag or (Item.ConditionPercent < 10) then Item.Repair;
  end;
end;
{ @end $547B20 }

{ @routine $547B7C TKling_GetHomeStar }
function TKling.GetHomeStar: TStar;
begin
  Result := nil;
end;
{ @end $547B7C }

{ @routine $547B80 TKling_GetName }
function TKling.GetName: WideString;
begin
  Result := Name;
end;
{ @end $547B80 }

{ @routine $547B94 TKling_GetFullName }
function TKling.GetFullName(const Separator: WideString): WideString;
begin
  if KlingType = ktMakhpella then Result := KlissanInfo[KlingType].DisplayName
  else Result := KlissanInfo[KlingType].DisplayName + Separator + Name;
end;
{ @end $547B94 }

{ @routine $547BE8 TKling_GetTypeNameKey }
function TKling.GetTypeNameKey: WideString;
begin
  Result := 'Kling';
end;
{ @end $547BE8 }

{ @routine $547C0C TKling_GetGreetingShipCategory }
function TKling.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscKling;
end;
{ @end $547C0C }

{ @routine $547C10 TKling_GetDominantCareer }
function TKling.GetDominantCareer: TRangerCareer;
begin
  Result := rcWarrior;
end;
{ @end $547C10 }

{ @routine $547C14 TKling_GetStrengthScaledPirateStatus }
function TKling.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 100;
end;
{ @end $547C14 }

{ @routine $547C18 TKling_GetDesiredCargoFreeSpace }
function TKling.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
end;
{ @end $547C18 }

{ @routine $547C1C TKling_RefuelAtLocation }
procedure TKling.RefuelAtLocation;
begin
  FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $547C1C }

{ @routine $547C2C TKling_RelationToNonRanger }
function TKling.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if Ship.OwnerId = oiKling then Result := 100 else Result := 0;
end;
{ @end $547C2C }

{ @routine $547C38 TKling_RelationToRanger }
function TKling.RelationToRanger(Ranger: TObject): Byte;
begin
  Result := 0;
end;
{ @end $547C38 }

{ @routine $547C3C TKling_ChangeRelationToRanger }
procedure TKling.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
begin

end;
{ @end $547C3C }

{ @routine $547C40 TKling_ReactToAttack }
procedure TKling.ReactToAttack(Attacker: TShip);
begin
  if Attacker.OwnerId <> oiKling then EnemyShip := Attacker;
end;
{ @end $547C40 }

{ @routine $547C50 TKling_RecomputeFearState }
function TKling.RecomputeFearState: Boolean;
begin
  Result := False;
end;
{ @end $547C50 }

{ @routine $547C54 TKling_AcceptsRansomDemandFrom }
function TKling.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := False;
end;
{ @end $547C54 }

{ @routine $547C58 TKling_TrustsAttackRequester }
function TKling.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := False;
end;
{ @end $547C58 }

{ @routine $547C5C TKling_EvaluateAllyRelationAndStrength }
function TKling.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := Ship.OwnerId = OwnerId;
end;
{ @end $547C5C }

{ @routine $547C68 TKling_AssignWeaponTargetsInStar }
procedure TKling.AssignWeaponTargetsInStar;
var
  I, J, Assigned: Integer;
  Ship: TShip;
  Weapon: TWeapon;
  Item: TItem;
  Asteroid: TAsteroid;
  Distance: Single;
begin
  for I := 1 to WeaponCount do begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  Assigned := 0;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    for J := 1 to WeaponCount do begin
      Weapon := Weapons[J - 1];
      if not ((not Weapon.HasSpecialDamageMode and (Weapon.Target = nil) and not Weapon.BrokenFlag) and
        (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, EnemyShip.Position))) then Continue;
      Weapon.Target := EnemyShip;
      Inc(Assigned);
      if Assigned = WeaponCount then Exit;
    end;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.InNormalSpace and (RelationToNonRanger(Ship) <= 50) then
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position))) then Continue;
        Weapon.Target := Ship;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
      end;
  end;
  for I := 0 to CurrentStar.Items.Count - 1 do begin
    Item := CurrentStar.Items[I];
    if Item.ScriptItem = nil then
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Item.Position))) then Continue;
        Weapon.Target := Item;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
        Break;
      end;
  end;
  if Player.CurrentStar = CurrentStar then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do begin
      Asteroid := CurrentStar.Asteroids[I];
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance <= AsteroidTargetRangeSquared then
        for J := 1 to WeaponCount do begin
          Weapon := Weapons[J - 1];
          // As in the native transport AI, asteroid targeting may overwrite a target.
          if not ((not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag) and
            (Weapon.Range * Weapon.Range >= Distance)) then Continue;
          Weapon.Target := Asteroid;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
          Break;
        end;
    end;
end;
{ @end $547C68 }

{ @routine $547FB0 TKling_SelectEnemyShipInStar }
procedure TKling.SelectEnemyShipInStar;
var I: Integer; Ship: TShip; Distance, BestDistance: Double;
begin
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace and
    (Speed >= PointDistance(Position, EnemyShip.Position)) then Exit;
  if UsableWeaponCount = 0 then Exit;
  EnemyShip := nil;
  BestDistance := 100000;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if (Ship.OwnerId <> oiKling) and Ship.InNormalSpace then begin
      Distance := PointDistance(Position, Ship.Position);
      if (EnemyShip <> nil) and (Ship.ShipType in [t_RangerCenter..t_ScientificBase]) and not (EnemyShip.ShipType in [t_RangerCenter..t_ScientificBase]) then Continue;
      if NextRandomFloatRange(0.3, 3, RandomState) * BestDistance > Distance then begin
        EnemyShip := Ship;
        BestDistance := Distance;
      end;
    end;
  end;
end;
{ @end $547FB0 }

{ @routine $5480CC TKling_EngageEnemyShip }
procedure TKling.EngageEnemyShip;
begin
  if Order = soFollowShip then OrderNone;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then begin
    if EnemyShip.InNormalSpace then OrderFollowShip(EnemyShip, fmMinWeaponRange, False)
    else if EnemyShip.CurrentPlanet <> nil then OrderMove(EnemyShip.CurrentPlanet.GetPosition, False);
  end;
end;
{ @end $5480CC }

{ @routine $54813C TKling_ProcessCombatDialogue }
procedure TKling.ProcessCombatDialogue;
begin

end;
{ @end $54813C }

{ @routine $548140 TKling_ReactToExtortionDemand }
procedure TKling.ReactToExtortionDemand(Ranger: TObject);
begin

end;
{ @end $548140 }

{ @routine $548144 TKling_BuildMoneyExtortionResponse }
function TKling.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
begin
  Result := False;
end;
{ @end $548144 }

{ @routine $548150 TKling_BuildCargoExtortionResponse }
function TKling.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
begin
  Result := False;
end;
{ @end $548150 }

{ @routine $548154 TKling_BuildTrucePaymentResponse }
function TKling.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
begin
  Result := False;
end;
{ @end $548154 }

{ @routine $548160 TKling_BuildAttackRequestResponse }
function TKling.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
begin
  Result := False;
end;
{ @end $548160 }

{ @routine $54816C TKling_AcceptPartnershipOffer }
function TKling.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $54816C }

{ @routine $5481B0 TKling_BuildPartnershipOfferResponse }
function TKling.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $5481B0 }

{ @routine $5481F4 TKling_TrainInitialSkills }
procedure TKling.TrainInitialSkills;
begin
  if FreeExperience <> 0 then
    repeat
    until not TrainSkill(skMobility) and not TrainSkill(skAccuracy) and not TrainSkill(skLeadership) and
      not TrainSkill(skTechnical) and not TrainSkill(skTrader) and not TrainSkill(skCharm);
end;
{ @end $5481F4 }

end.

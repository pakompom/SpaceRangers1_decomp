unit aRanger;
// Unit bracket (inferred): CODE 0x00597D1C..0x005A6167; inclusive evidence, not full bounds.
interface
// Save/load $5988D8/$598AE8 and quest cleanup in Destroy $597E0C.
uses aNormalShip, Classes, aPlanet, aShip, EC_Buf, aGalaxy, aConst;
type
  TQuest = packed record // @size $20
    QuestType: TQuestType; // @offset $00
    QuestNumber: Word; // @offset $02
    Planet: TPlanet; // @offset $04
    DeadlineTurn: Integer; // @offset $08
    RewardMoney: Integer; // @offset $0C
    ObjectiveTarget: TObject; // @offset $10 Planet, ship or item; resolved after loading.
    Successful: Boolean; // @offset $14
    Description: WideString; // @offset $18
    CompletionText: WideString; // @offset $1C
  end;
  TPlayerOldQuest = packed record // @size $0C
    Planet: TPlanet; // @offset $00
    Description: WideString; // @offset $04
    Successful: Boolean; // @offset $08
    QuestType: TQuestType; // @offset $09
    QuestNumber: Word; // @offset $0A
  end;
  PPlayerOldQuest = ^TPlayerOldQuest;
  PQuest = ^TQuest;

  TRanger = class(TNormalShip) // @size $1EC @methodorder source
  public
    procedure InitializeAtPlanet(Planet: TPlanet; InitialMoney: Integer); virtual; // @addr $59800C @slot $98
    function GetTypeNameKey: WideString; override; // @addr $599A64
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $59B6A4
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $59CB08
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $59CCC4
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $59D3BC
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $59F21C
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $59F338
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $59F96C
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $59FD00
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $5A0150
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $5A05E0
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $5A0990
    procedure SelectEnemyShipInStar; override; // @addr $59ECA4
    procedure EngageEnemyShip; override; // @addr $59F06C
    procedure TrainSkillsAutomatically; override; // @addr $5A0B48
    procedure ProcessCombatDialogue; override; // @addr $59F160
    procedure NextDay; override; // @addr $598E34
    procedure AssignWeaponTargetsInStar; // @addr $59E8F8
    procedure CheckForPartnershipBreakup; // @addr $59DB00
    procedure TryRecruitWingman; // @addr $59D86C
    procedure TryOfferRansomToPursuer; // @addr $59D158
    function ProcessPrisonAndHostileCheck: Boolean; // @addr $59E0A8
    procedure BuyProfitableGoods; // @addr $59C17C
    procedure SelectIdleFreeFlightDestination(UnusedMode: Byte); // @addr $59B6B0
    function TryOrderTravelToShipTypeLocation(ShipType: TShipType): Boolean; // @addr $59BA40
    procedure SelectAlternateReachableDestination; // @addr $59BECC
    procedure SimulateUnseenProgression; // @addr $59A1E0
    function GetEquipmentCashReserve: Integer; // @addr $59A090
    function CountWingmen: Integer; // @addr $59A0D4 Only entries in Galaxy.Rangers count.
    function NeedsStrengthCatchup: Boolean; // @addr $59A11C
    procedure BuyInitialEquipment; override; // @addr $59C4FC
    procedure UpgradeEquipmentAtLocation; override; // @addr $59C684
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $59CA94
    procedure SellCargoGoods; // @addr $59C0FC
    procedure ChangeShipRelations(Scope: TObject; Mode: TRelationChangeMode; Amount: Byte; ShipTypes: THullShipTypeMask; Owners: TOwnerSet); // @addr $59E2A0
    procedure ChangePlanetRelations(Scope: TObject; Mode: TRelationChangeMode; Amount: Byte; Owners: TOwnerSet); // @addr $59E448
    function GlobalRelationsShips(Scope: TObject; ShipTypes: THullShipTypeMask; Owners: TOwnerSet): Byte; // @addr $59E658
    function GlobalRelationsPlanets(Scope: TObject; Owners: TOwnerSet): Byte; // @addr $59E7C4
    function GetObjectInfoText(Instance: TObject): WideString; // @addr $599E48
    procedure SelectNearestReachableDestination; // @addr $59BB84
    function ProcessPendingPlayerFollowTargeting: Boolean; // @addr $59989C
    PlaceInRating: Word; // @offset $1D0 Read as Word by CollectLiberationRewards $5A6684.
    CareerStatus: array[TRangerCareer] of TPercent; // @offset $1D2
    EminentProgress: array[TRangerCareer] of Byte; // @offset $1D5
    PendingCareerActivity: array[TRangerCareer] of Byte; // @offset $1D8
    PreferredCareer: TRangerCareer; // @offset $1DB
    Aggression: Byte; // @offset $1DC
    Quests: TList; // @offset $1E0 Owns PQuest records; finalized and disposed explicitly.
    PrisonTermRemaining: Byte; // @offset $1E4
    LastDockedNonPlanetLocation: TShip; // @offset $1E8

    function GetHomeStar: TStar; override; // @addr $59998C
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $599A8C
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $599D80
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $599DC0
    function GetEstimatedMemoryUsage: Integer; override; // @addr $59A054
    procedure RefuelAtLocation; override; // @addr $59A1A0
    function OrderBestQueuedTradePlanet: Boolean; // @addr $59B304
    function SelectRandomPlanetFromQueue: TPlanet; // @addr $59B57C
    procedure BuildReachablePlanetQueue; override; // @addr $59B5B0
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $59DC98
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $59DCB0
    function GetName: WideString; override; // @addr $599994
    function GetFullName(const Separator: WideString): WideString; override; // @addr $5999A8
    function GetDominantCareer: TRangerCareer; override; // @addr $599A90
    function GetCareerSimilarity(Values: TRangerCareerValues): TPercent; // @addr $599ADC @ida "TPercent __userpurge $name@<al>(TRanger *Self@<eax>, unsigned int Values@<^0>);"
    function GetCharacterName: WideString; // @addr $599B4C
    function HasQuestOfType(QuestType: TQuestType): Boolean; // @addr $5A603C
    procedure HalveAllRangerEminentProgress(Career: TRangerCareer); // @addr $59B29C
    function SelectBestTradePlanetFromQueue: TPlanet; // @addr $59B338
    function FindBestQueuedSellPlanetProfitScore(Good: TGoodsIndex; var BestPlanet: TPlanet; UnitCost: Double): Byte; // @addr $59C354
    function GenerateQuestOffer(var Quest: TQuest; var ResponseText: WideString): Boolean; // @addr $5A26A0
    procedure TryTurnInQuests; // @addr $5A1544
    procedure ArchiveQuest(Index: Integer); // @addr $5A1580
    function TryTurnInAnyQuest(var ResponseText: WideString): Boolean; // @addr $5A1608
    procedure RefreshPlayerQuestTargets; // @addr $5A6078
    function NeedsWealthCatchup: Boolean; // @addr $59A15C
    function TryTurnInQuest(Index: Integer; var ResponseText: WideString): Boolean; // @addr $5A1A88
    procedure ProcessCareerActivityAndEminentProgress; // @addr $59ABD0
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $59CC90
    procedure ReactToAttack(Attacker: TShip); override; // @addr $59CDB0
    function RecomputeFearState: Boolean; override; // @addr $59CE20
    procedure ApplyExtortionReputationPenalty(Victim: TShip); // @addr $59D688
    procedure ApplyIllegalGoodsTradeRelationsPenalty(TotalTradeValue: Integer); // @addr $59C44C
    procedure AddTraderCareerActivity(Amount: Byte); // @addr $59A9E4
    procedure AddPirateCareerActivity(Amount: Byte); // @addr $59AA00
    procedure AddWarriorCareerActivity(Amount: Byte); // @addr $59AA1C
    procedure ClearPendingCareerActivity; // @addr $59AA38
    procedure ProcessQuestTimersAndOutcomes; // @addr $5A10D8
    function BuildQuestText(Quest: TQuest; Completion: Boolean): WideString; // @addr $5A4828
    procedure PublishQuestStatus(Quest: PQuest; Outcome: Integer); // @addr $5A54C8
    procedure UpdateRelationsAfterShipKill(Victim: TShip); // @addr $59D438
    procedure ProcessShipDestructionQuests(Ship: TShip); // @addr $5A5AA4
    destructor Destroy; override; // @addr $597E0C
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5988D8
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $598AE8
    procedure ResolveLoadedReferences; override; // @addr $598CEC
  end;
var
  PendingPlayerFollowTarget: TShip = nil; // @addr $6188C8
  PlayerAutomaticControl: Boolean = False; // @addr $6188CC Direct accesses in $59989C establish aRanger ownership.
  PlayerEquipmentChanged: Boolean = False; // @addr $6188D0 Direct write in NextDay; also set when player equipment breaks.
  PlayerOldQuests: TList; // @addr $61D044

implementation

// @unit-initialization $5A6160
// @unit-finalization $5A6130

uses EC_Struct, SE_Ship2, aItem, aMyFunction, SysUtils, Math, Globals, GR_Main, EC_Str, aPlayer, aArtifact, aTransport, GlobalsV, aRuins, aKling, aGroup, aTranclucator, aWarrior;

{ @routine $597E0C TRanger_Destroy }
destructor TRanger.Destroy;
var
  I, J, RangerIndex: Integer;
  Planet: TPlanet;
  Quest: PQuest;
  OldQuest: PPlayerOldQuest;
  Star: TStar;
  Ship: TShip;
begin
  Dec(HomePlanet.HomeRangerCount);
  if Quests <> nil then
    for I := Quests.Count - 1 downto 0 do
    begin
      Quest := PQuest(Quests[I]);
      Quests.Delete(I);
      Dispose(Quest);
    end;
  if Player = Self then
  begin
    for I := PlayerOldQuests.Count - 1 downto 0 do
    begin
      OldQuest := PPlayerOldQuest(PlayerOldQuests[I]);
      PlayerOldQuests.Delete(I);
      Dispose(OldQuest);
    end;
    PlayerOldQuests.Clear;
  end;
  RangerIndex := Galaxy.Rangers.IndexOf(Self);
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if Ship.ShipType in [t_Ranger..t_Pirate, t_RangerCenter..t_ScientificBase] then
        if Ship <> Self then Ship.RangerRelations.Delete(RangerIndex);
    end;
  end;
  for I := 0 to Galaxy.Planets.Count - 1 do
  begin
    Planet := TPlanet(Galaxy.Planets[I]);
    Planet.RangerRelations.Delete(RangerIndex);
  end;
  Galaxy.Rangers.Delete(RangerIndex);
  if Galaxy.WealthiestRanger = Self then Galaxy.RefreshRangerWealthStats;
  if Galaxy.StrongestRanger = Self then Galaxy.RefreshRangerStrengthStats;
  Galaxy.RefreshRangerRatingPlaces;
  inherited Destroy;
end;
{ @end $597E0C }

{ @routine $59800C TRanger_InitializeAtPlanet }
procedure TRanger.InitializeAtPlanet(Planet: TPlanet; InitialMoney: Integer);
var OtherPlanet: TPlanet; Star: TStar; Ship: TShip; Ranger: TRanger;
  Index, I, J, LastIndex, FirstIndex: Integer;
  OwnerName: WideString; Duplicate: Boolean;
begin
  if (PlayerHomeRanger = nil) and (Player <> nil) and (Player.HomePlanet = Planet) and (Self <> Player) then
    PlayerHomeRanger := Self;
  HomePlanet := Planet;
  CurrentPlanet := HomePlanet;
  CurrentStar := CurrentPlanet.CurrentStar;
  CurrentStar.Ships.Add(Self);
  ShipType := t_Ranger;
  OwnerId := HomePlanet.OwnerId;
  SetMoney(InitialMoney);
  Aggression := SeededRandomIntRange(0, 100, Seed * Cardinal(Galaxy.CurrentTurn));
  LastDockedPlanet := nil;
  LastDockedNonPlanetLocation := nil;
  if Self <> Player then begin
  case NextRandomIntRange(0, 100, RandomState) of
    0..29: PreferredCareer := rcTrader;
    30..39: PreferredCareer := rcPirate;
    40..100: PreferredCareer := rcWarrior;
  end;
  case PreferredCareer of
    rcTrader:
    begin
      CareerStatus[rcTrader] := 90;
      CareerStatus[rcPirate] := 5;
      CareerStatus[rcWarrior] := 5;
      EminentProgress[rcTrader] := 90;
      EminentProgress[rcPirate] := 0;
      EminentProgress[rcWarrior] := 0;
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skMobility]);
      Inc(BaseSkills[skTechnical]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTechnical]);
      Inc(BaseSkills[skTrader]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTrader]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skCharm]);
    end;
    rcPirate:
    begin
      CareerStatus[rcTrader] := 30;
      CareerStatus[rcPirate] := 40;
      CareerStatus[rcWarrior] := 30;
      EminentProgress[rcTrader] := 0;
      EminentProgress[rcPirate] := 70;
      EminentProgress[rcWarrior] := 0;
      Inc(BaseSkills[skAccuracy]);
      Inc(BaseSkills[skAccuracy]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skMobility]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skMobility]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTrader]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTrader]);
      Inc(BaseSkills[skCharm]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skCharm]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skLeadership]);
    end;
    rcWarrior:
    begin
      CareerStatus[rcTrader] := 30;
      CareerStatus[rcPirate] := 30;
      CareerStatus[rcWarrior] := 40;
      EminentProgress[rcTrader] := 0;
      EminentProgress[rcPirate] := 0;
      EminentProgress[rcWarrior] := 90;
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skMobility]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skMobility]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTrader]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skAccuracy]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTechnical]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skTechnical]);
      if NextRandomUnitFloat(RandomState) < 0.5 then Inc(BaseSkills[skLeadership]);
      if NextRandomUnitFloat(RandomState) < 0.2 then Inc(BaseSkills[skLeadership]);
    end;
  end;
  end else begin
    EminentProgress[rcTrader] := 0;
    EminentProgress[rcPirate] := 0;
    EminentProgress[rcWarrior] := 0;
  end;
  ClearPendingCareerActivity;
  OwnerName := OwnerToSys(OwnerId);
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('ShipName').GetBlock('Ranger').GetBlock(OwnerName).GetParamCount - 1;
  Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
  for I := FirstIndex to LastIndex do begin
    Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Ranger').GetBlock(OwnerName).GetParamValue(Index);
    Duplicate := False;
    for J := 0 to Galaxy.Rangers.Count - 1 do begin
      Ranger := Galaxy.Rangers[J];
      if (Ranger <> Self) and (Ranger.Name = Name) then begin
        Duplicate := True;
        Break;
      end;
    end;
    if not Duplicate then Break;
    IncrementWrapped(Index, FirstIndex, LastIndex);
    if I = LastIndex then Name := Name + ' 2';
  end;
  Graphic := TShip2SE.CreateEmpty;
  ShipRenderTemplates[Planet.OwnerId, 0].SpaceObject.CopyTo(Graphic);
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(0);
  CollisionRadius := 32;
  CreateAndEquipHull(True, Round(500 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipEngine(True, Round(ItemSizeFactors[NextRandomIntRange(1, 2, RandomState)] * 40), NextRandomIntRange(1, 2, RandomState), OwnerId);
  CreateAndEquipCargoHook(True, 40, NextRandomIntRange(1, 2, RandomState), OwnerId);
  CreateAndEquipWeapon(t_PhotonGun, True, WeaponInfo[t_PhotonGun].Weight, 1, OwnerId);
  CreateAndEquipRadar(True, Round(ItemSizeFactors[NextRandomIntRange(2, 4, RandomState)] * 30), 1, OwnerId);
  RefreshDerivedStats;
  BuyInitialEquipment;
  for Index := 0 to Galaxy.Planets.Count - 1 do begin
    OtherPlanet := Galaxy.Planets[Index];
    OtherPlanet.RangerRelations.Add(Pointer(OwnerRelations[RaceToOwner(OtherPlanet.RaceId), OwnerId]));
  end;
  Galaxy.Rangers.Add(Self);
  for Index := 0 to Galaxy.Stars.Count - 1 do begin
    Star := Galaxy.Stars[Index];
    for I := 0 to Star.Ships.Count - 1 do begin
      Ship := Star.Ships[I];
      if (Ship.ShipType in [t_Ranger..t_Pirate, t_RangerCenter..t_ScientificBase]) and (Ship <> Self) then
        Ship.RangerRelations.Add(Pointer(OwnerRelations[Ship.OwnerId, OwnerId]));
    end;
  end;
  for Index := 0 to Galaxy.Rangers.Count - 1 do begin
    Ranger := Galaxy.Rangers[Index];
    RangerRelations.Add(Pointer(OwnerRelations[OwnerId, Ranger.OwnerId]));
  end;
  Galaxy.RefreshRangerRatingPlaces;
  Quests := TObjectList.Create;
  PrisonTermRemaining := 0;
end;
{ @end $59800C }

{ @routine $5988D8 TRanger_SaveToBuffer }
procedure TRanger.SaveToBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Quest: PQuest;
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(CareerStatus[rcTrader]));
  Buffer.AddAnsiChar(AnsiChar(CareerStatus[rcPirate]));
  Buffer.AddAnsiChar(AnsiChar(CareerStatus[rcWarrior]));
  Buffer.AddAnsiChar(AnsiChar(EminentProgress[rcTrader]));
  Buffer.AddAnsiChar(AnsiChar(EminentProgress[rcPirate]));
  Buffer.AddAnsiChar(AnsiChar(EminentProgress[rcWarrior]));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(PreferredCareer)));
  Buffer.AddAnsiChar(AnsiChar(Aggression));
  Count := Quests.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Quest := PQuest(Quests[I]);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Quest.QuestType)));
    Buffer.AddWideChar(WideChar(Quest.QuestNumber));
    Buffer.AddIntegerValue(Quest.DeadlineTurn);
    Buffer.AddIntegerValue(Quest.RewardMoney);
    if Quest.Planet = nil then Buffer.AddDWord(0) else Buffer.AddDWord(Quest.Planet.Id);
    if Quest.ObjectiveTarget is TPlanet then Buffer.AddDWord((Quest.ObjectiveTarget as TPlanet).Id)
    else if Quest.ObjectiveTarget is TShip then Buffer.AddDWord((Quest.ObjectiveTarget as TShip).Id)
    else if Quest.ObjectiveTarget is TArtefact then Buffer.AddDWord((Quest.ObjectiveTarget as TArtefact).Id)
    else Buffer.AddDWord(0);
    Buffer.AddBoolean(Quest.Successful);
    Buffer.AddWideStringZ(Quest.Description);
    Buffer.AddWideStringZ(Quest.CompletionText);
  end;
  Buffer.AddAnsiChar(AnsiChar(PendingCareerActivity[rcTrader]));
  Buffer.AddAnsiChar(AnsiChar(PendingCareerActivity[rcPirate]));
  Buffer.AddAnsiChar(AnsiChar(PendingCareerActivity[rcWarrior]));
  Buffer.AddAnsiChar(AnsiChar(PrisonTermRemaining));
  if LastDockedNonPlanetLocation = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(LastDockedNonPlanetLocation.Id);
end;
{ @end $5988D8 }

{ @routine $598AE8 TRanger_LoadFromBuffer }
procedure TRanger.LoadFromBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Quest: PQuest;
begin
  inherited LoadFromBuffer(Buffer);
  CareerStatus[rcTrader] := Buffer.GetByte;
  CareerStatus[rcPirate] := Buffer.GetByte;
  CareerStatus[rcWarrior] := Buffer.GetByte;
  EminentProgress[rcTrader] := Buffer.GetByte;
  EminentProgress[rcPirate] := Buffer.GetByte;
  EminentProgress[rcWarrior] := Buffer.GetByte;
  WriteByteValue(Buffer.GetByte, PreferredCareer);
  Aggression := Buffer.GetByte;
  { Native loading uses the custom list; fresh initialization uses TList. }
  Quests := TObjectList.Create;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err in FQuests load');
  for I := 0 to Count - 1 do
  begin
    New(Quest);
    Quests.Add(Quest);
    WriteByteValue(Buffer.GetByte, Quest.QuestType);
    Quest.QuestNumber := Buffer.GetWord;
    Quest.DeadlineTurn := Buffer.GetInt32;
    Quest.RewardMoney := Buffer.GetInt32;
    Quest.Planet := TPlanet(Buffer.GetUInt32);
    Quest.ObjectiveTarget := TObject(Buffer.GetUInt32);
    Quest.Successful := Buffer.GetBoolean;
    Quest.Description := Buffer.ReadWideString;
    Quest.CompletionText := Buffer.ReadWideString;
  end;
  PendingCareerActivity[rcTrader] := Buffer.GetByte;
  PendingCareerActivity[rcPirate] := Buffer.GetByte;
  PendingCareerActivity[rcWarrior] := Buffer.GetByte;
  PrisonTermRemaining := Buffer.GetByte;
  LastDockedNonPlanetLocation := TShip(Buffer.GetUInt32);
end;
{ @end $598AE8 }

{ @routine $598CEC TRanger_ResolveLoadedReferences }
procedure TRanger.ResolveLoadedReferences;
var I, Count: Integer; Quest: PQuest;
begin
  inherited ResolveLoadedReferences;
  Count := Quests.Count;
  for I := 0 to Count - 1 do
  begin
    Quest := Quests[I];
    Quest.Planet := Galaxy.IdToPlanet(Cardinal(Quest.Planet)) as TPlanet;
    case Quest.QuestType of
      qtSendLetter: Quest.ObjectiveTarget := Galaxy.IdToPlanet(Cardinal(Quest.ObjectiveTarget)) as TPlanet;
      qtKillShip: Quest.ObjectiveTarget := Galaxy.IdToShip(Cardinal(Quest.ObjectiveTarget), True) as TShip;
      qtPlanetQuest: Quest.ObjectiveTarget := Galaxy.IdToPlanet(Cardinal(Quest.ObjectiveTarget)) as TPlanet;
      qtDefendSystem: Quest.ObjectiveTarget := Galaxy.IdToPlanet(Cardinal(Quest.ObjectiveTarget)) as TPlanet;
      qtDefendShip: Quest.ObjectiveTarget := Galaxy.IdToShip(Cardinal(Quest.ObjectiveTarget), True) as TShip;
    end;
  end;
  LastDockedNonPlanetLocation := Galaxy.IdToShip(Cardinal(LastDockedNonPlanetLocation), True) as TShip;
end;
{ @end $598CEC }

{ @routine $598E34 TRanger_NextDay }
procedure TRanger.NextDay;
var
  I: Integer;
  Location: TPlanet;
begin
  inherited NextDay;
  ProcessCareerActivityAndEminentProgress;
  ProcessQuestTimersAndOutcomes;
  if (KlingMotherShip <> nil) and (KlingMotherShip.CurrentStar = CurrentStar) and InNormalSpace and
    (ScenarioState = scenAllianceAgainstRachekhan) and ((Self = Player) or (PartnerShip = Player)) then
  begin
    if Self = Player then PendingPlayerFollowTarget := nil;
    for I := 0 to Galaxy.Holes.Count - 1 do
      if THole(Galaxy.Holes[I]).HoleType = bhkMachpella then
        if THole(Galaxy.Holes[I]).Star1 = CurrentStar then
          OrderEnterBlackHole(THole(Galaxy.Holes[I]), True, False)
        else OrderEnterBlackHole(THole(Galaxy.Holes[I]), False, False);
    for I := 1 to WeaponCount do Weapons[I - 1].Target := nil;
  end
  else
  begin
    if (KlingMotherShip <> nil) and (Self = Player) and InNormalSpace and
      (KlingMotherShip.CurrentStar = CurrentStar) and IsKlingMotherShipFollowActive then
    begin
      OrderFollowShip(KlingMotherShip, fmNear, False);
      Exit;
    end;
    if Self = Player then
    begin
      PlayerEquipmentChanged := False;
      if not ProcessPendingPlayerFollowTargeting then Exit;
    end;
    if ScriptShip <> nil then
    begin
      ScriptNextDay;
      if ScriptShip <> nil then Exit;
    end;
    if CurrentPlanet <> nil then
    begin
      TryTurnInQuests;
      if not ProcessPrisonAndHostileCheck then
      begin
        RefuelAtLocation;
        RepairBrokenEquipmentAtLocation;
        OptimizeInventory;
        BuildReachablePlanetQueue;
        SellCargoGoods;
        RefuelAtLocation;
        if not RepairHullAtLocation then
        begin
          UpgradeEquipmentAtLocation;
          if not ScanForCollectableItems and NeedsWealthCatchup and (CountWingmen = 0) and (PartnerShip = nil) then BuyProfitableGoods;
          if Self <> Player then SimulateUnseenProgression;
          TrainSkillsAutomatically;
          OrderTakeoff;
        end;
      end;
      Exit;
    end;
    if DockedTo <> nil then
    begin
      case DockedTo.ShipType of
        t_RangerCenter: begin DepositCarriedNodes; TrainSkillsAutomatically; end;
        t_MilitaryBase: TryPromoteRank;
      end;
      if Self <> Player then SimulateUnseenProgression;
      RepairBrokenEquipmentAtLocation;
      OptimizeInventory;
      BuildReachablePlanetQueue;
      SellCargoGoods;
      RefuelAtLocation;
      if not RepairHullAtLocation then
      begin
        RepairBrokenEquipmentAtLocation;
        OrderTakeoff;
      end;
      Exit;
    end;
    if not InNormalSpace then Exit;
    if (Self <> Player) and ((Integer(Seed) + Galaxy.CurrentTurn) mod 53 = 0) then SimulateUnseenProgression;
    BuildReachablePlanetQueue;
    if RecomputeFearState then TryOfferRansomToPursuer;
    AssignWeaponTargetsInStar;
    CheckForPartnershipBreakup;
    TryRecruitWingman;
    if PartnerShip <> nil then
    begin
      if not InFear then
      begin
        if ((OrderTarget = PartnerShip) or (OrderTarget = PartnerShip.OrderTarget)) and OrderAbsolute and
          ((OrderTarget = PartnerShip) or not (Order in [soNone, soMove])) then
        begin
          TryCollectBestFloatingItem(0);
          if TryMirrorPartnerTravelOrders then Exit;
        end;
      end
      else if (Order in [soLanding, soJump]) and ((OrderTarget = PartnerShip.OrderTarget) or (EstimateOrderTravelTurns < 4)) then Exit;
    end;
    if (EnemyShip <> nil) and (OrderTarget = EnemyShip) and (EnemyShip.CurrentPlanet <> nil) and
      (NextRandomUnitFloat(RandomState) < 0.2) then OrderNone;
    ProcessCombatDialogue;
    if InFear then
    begin
      if PartnerShip <> nil then
      begin
        if PartnerShip.CurrentStar = CurrentStar then
        begin
          if not OrderAbsolute then SelectAlternateReachableDestination;
        end
        else if PartnerShip.CurrentStar.ControlFaction = sfCoalition then
        begin
          if (PartnerShip.Order = soJump) and (PartnerShip.OrderTarget is TStar) and
            (PartnerShip.OrderTarget <> CurrentStar) and (PartnerShip.OrderTarget <> PartnerShip.CurrentStar) and
            ((PartnerShip.OrderTarget as TStar).ControlFaction = sfCoalition) then
          begin
            OrderJump(PartnerShip.OrderTarget as TStar, True);
            Exit;
          end;
          OrderJump(PartnerShip.CurrentStar, True);
          Exit;
        end;
        { Native repeats this selection after the same-star branch. }
        SelectAlternateReachableDestination;
      end
      else
      begin
        SelectAlternateReachableDestination;
        if GetCarriedNodeCount > 0 then TryOrderTravelToShipTypeLocation(t_RangerCenter);
        { Native assumes the Klissan mothership exists here. }
        if (KlingMotherShip.CurrentStar = CurrentStar) and (Aggression < 40) then NavigateToEscapePlanet(True);
        if (Order <> soLanding) and (Order <> soJump) then EngageEnemyShip
        else if (EstimateOrderTravelTurns > 4) and (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and
          (EnemyShip.ShipType in [t_Ranger, t_Pirate]) and (EnemyShip.EstimateOrderTravelTurns < 3) and
          (NextRandomUnitFloat(RandomState) < 0.2) and ((Integer(Seed) + Galaxy.CurrentTurn) mod 2 = 0) then
          if JettisonCargoGoodsTowardTargetValue(Max(200, Galaxy.ComputeScaledMiniMoney(OwnerId) div 2)) then NotifyFearCargoDrop(EnemyShip);
      end;
    end
    else
    begin
      if PartnerShip <> nil then
      begin
        if (PartnerShip.CurrentStar = CurrentStar) and (PartnerShip.Order in [soNone, soMove]) then TryCollectBestFloatingItem(2)
        else TryCollectBestFloatingItem(0);
      end
      else TryCollectBestFloatingItem(50);
      if PartnerShip <> nil then
      begin
        if PartnerShip.CurrentStar = CurrentStar then
        begin
          if (PartnerShip.EnemyShip <> nil) and
            ((PartnerShip.OrderTarget = PartnerShip.EnemyShip) or (PartnerShip.EnemyShip.OrderTarget = PartnerShip)) then
          begin
            EnemyShip := PartnerShip.EnemyShip;
            EngageEnemyShip;
          end
          else if (EnemyShip <> nil) and EnemyShip.InNormalSpace and (PartnerShip.OrderTarget is TShip) and
            (PartnerShip.GetRelationLevelToShip(PartnerShip.OrderTarget as TShip) = rlHostile) and
            (PartnerShip.GetRelationLevelToShip(EnemyShip) = rlHostile) then EngageEnemyShip;
        end;
      end
      else if not OrderAbsolute then
      begin
        SelectEnemyShipInStar;
        EngageEnemyShip;
      end;
      if PartnerShip <> nil then
      begin
        if (Order = soFollowShip) and (OrderTarget <> PartnerShip) and (GetRelationLevelToShip(OrderTarget as TShip) <> rlHostile) then OrderNone;
        if (Order = soNone) and HasCargoGoods and (GetDesiredCargoFreeSpace > CargoFreeSpace) then SelectNearestReachableDestination;
        if Order = soNone then
          if (Hull.Weight - GetDesiredCargoFreeSpace < GetCarriedItemWeight) or
            ((GetHullIntegrityPercent < 70) and HasHullDamageOrBrokenEquippedItems) then SelectNearestReachableDestination;
        if (Order = soNone) and HasInactiveDirectEquipment and (GetDesiredCargoFreeSpace > CargoFreeSpace) then SelectNearestReachableDestination;
        if (Order = soNone) or (OrderTarget = PartnerShip) or ((Order = soJump) and not OrderAbsolute) then TryMirrorPartnerTravelOrders;
        if (Order = soNone) and CanRefuel then SelectNearestReachableDestination;
        if (Order = soNone) and (GetCarriedNodeCount > 0) then TryOrderTravelToShipTypeLocation(t_RangerCenter);
        if (Order = soNone) and CanPromoteRank then TryOrderTravelToShipTypeLocation(t_MilitaryBase);
      end
      else
      begin
        if (Order = soNone) and (GetCarriedNodeCount > 0) then TryOrderTravelToShipTypeLocation(t_RangerCenter);
        if (Order = soNone) and CanPromoteRank then TryOrderTravelToShipTypeLocation(t_MilitaryBase);
        if (Order = soNone) and HasCargoGoods and (GetDesiredCargoFreeSpace > CargoFreeSpace) then
          if NeedsWealthCatchup then OrderBestQueuedTradePlanet
          else SelectNearestReachableDestination;
        if Order = soNone then
          if (Hull.Weight - GetDesiredCargoFreeSpace < GetCarriedItemWeight) or
            HasHullDamageOrBrokenEquippedItems or CanRefuel then SelectNearestReachableDestination;
        if (Order = soNone) and HasInactiveDirectEquipment and (GetDesiredCargoFreeSpace > CargoFreeSpace) then SelectNearestReachableDestination;
      end;
      if (Order = soNone) and not InFear then SelectIdleFreeFlightDestination(0);
      if Order = soNone then
      begin
        Location := SelectBestTradePlanetFromQueue;
        if (Location = nil) and (Hull.HullPoints < Hull.Weight) then Location := SelectRandomPlanetFromQueue;
        if Location <> nil then
          if CurrentStar = Location.CurrentStar then OrderLanding(Location, False)
          else OrderJump(Location.CurrentStar, False);
      end;
    end;
    if Order = soNone then NavigateToEscapePlanet(False);
    if Order = soNone then OrderRandomFreeFlightMove;
  end;
end;
{ @end $598E34 }

{ @routine $59989C TRanger_ProcessPendingPlayerFollowTargeting }
function TRanger.ProcessPendingPlayerFollowTargeting: Boolean;
var I: Integer; Weapon: TWeapon;
begin
  if PlayerAutomaticControl then begin
    Result := True;
    RefreshEquipmentSlots;
    Exit;
  end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar <> CurrentStar) then EnemyShip := nil;
  if PendingPlayerFollowTarget <> nil then begin
    if PendingPlayerFollowTarget.InNormalSpace and InNormalSpace and
      (PendingPlayerFollowTarget.CurrentStar = CurrentStar) then begin
      OrderFollowShip(PendingPlayerFollowTarget, fmMinWeaponRange, False);
      for I := 1 to WeaponCount do begin
        Weapon := Weapons[I - 1];
        if not Weapon.BrokenFlag and (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, PendingPlayerFollowTarget.Position)) then
          Weapon.Target := PendingPlayerFollowTarget
        else Weapon.Target := nil;
      end;
    end else PendingPlayerFollowTarget := nil;
  end;
  Result := False;
end;
{ @end $59989C }

{ @routine $59998C TRanger_GetHomeStar }
function TRanger.GetHomeStar: TStar;
begin
  Result := HomePlanet.CurrentStar;
end;
{ @end $59998C }

{ @routine $599994 TRanger_GetName }
function TRanger.GetName: WideString;
begin
  Result := Name;
end;
{ @end $599994 }

{ @routine $5999A8 TRanger_GetFullName }
function TRanger.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.' + OwnerToSys(OwnerId) + '.' + GetTypeNameKey) + Separator + Name;
end;
{ @end $5999A8 }

{ @routine $599A64 TRanger_GetTypeNameKey }
function TRanger.GetTypeNameKey: WideString;
begin
  Result := 'Ranger';
end;
{ @end $599A64 }

{ @routine $599A8C TRanger_GetGreetingShipCategory }
function TRanger.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscRanger;
end;
{ @end $599A8C }

{ @routine $599A90 TRanger_GetDominantCareer }
function TRanger.GetDominantCareer: TRangerCareer;
var
  Maximum: Integer;
begin
  Maximum := Max(Max(CareerStatus[rcTrader], CareerStatus[rcPirate]), CareerStatus[rcWarrior]);
  if CareerStatus[rcTrader] = Maximum then Result := rcTrader
  else if CareerStatus[rcPirate] = Maximum then Result := rcPirate
  else Result := rcWarrior;
end;
{ @end $599A90 }

{ @routine $599ADC TRanger_GetCareerSimilarity }
function TRanger.GetCareerSimilarity(Values: TRangerCareerValues): TPercent;
var
  TraderSimilarity, PirateSimilarity, WarriorSimilarity: Integer;
begin
  TraderSimilarity := 100 - Abs(CareerStatus[rcTrader] - Values[rcTrader]);
  PirateSimilarity := 100 - Abs(CareerStatus[rcPirate] - Values[rcPirate]);
  WarriorSimilarity := 100 - Abs(CareerStatus[rcWarrior] - Values[rcWarrior]);
  Result := (TraderSimilarity + PirateSimilarity + WarriorSimilarity) div 3;
end;
{ @end $599ADC }

{ @routine $599B4C TRanger_GetCharacterName }
function TRanger.GetCharacterName: WideString;
var
  I, Best: Integer;
  Values: TRangerCareerValues;
  Text: WideString;
begin
  Best := 0;
  Result := 'Error in CharacterName';
  for I := 0 to LanguageDataConfig.GetBlock('ShipCharacter').GetParamCount - 1 do
  begin
    Text := LanguageDataConfig.GetBlock('ShipCharacter').GetParamValue(I);
    Values[rcTrader] := StrToInt(TrimWideString(ExtractDelimitedPartW(Text, 0, ',')));
    Values[rcPirate] := StrToInt(TrimWideString(ExtractDelimitedPartW(Text, 1, ',')));
    Values[rcWarrior] := StrToInt(TrimWideString(ExtractDelimitedPartW(Text, 2, ',')));
    if GetCareerSimilarity(Values) > Best then
    begin
      Best := GetCareerSimilarity(Values);
      Result := TrimWideString(ExtractDelimitedPartW(Text, 3, ','));
    end;
  end;
end;
{ @end $599B4C }

{ @routine $599D80 TRanger_GetStrengthScaledPirateStatus }
function TRanger.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := Round(RemapClamped(CareerStatus[rcPirate] * StrengthInBestRanger, 0.0, 100.0, 0.0, 100.0));
end;
{ @end $599D80 }

{ @routine $599DC0 TRanger_GetDesiredCargoFreeSpace }
function TRanger.GetDesiredCargoFreeSpace: Integer;
begin
  case PreferredCareer of
    rcTrader: Result := Trunc(Hull.Weight * 0.15) + 30;
    rcPirate: Result := Trunc(Hull.Weight * 0.1) + 40;
    rcWarrior: Result := Trunc(Hull.Weight * 0.1) + 30;
  else Result := 50;
  end;
end;
{ @end $599DC0 }

{ @routine $599E48 TRanger_GetObjectInfoText }
function TRanger.GetObjectInfoText(Instance: TObject): WideString;
begin
  if Instance is TStar then Result := (Instance as TStar).Name
  else if Instance is TPlanet then Result := (Instance as TPlanet).GetInfoText
  else if Instance is TItem then
  begin
    if GetRadarRange < PointDistance(Position, (Instance as TItem).Position) then
      Result := (Instance as TItem).GetSmallInfoText
    else Result := (Instance as TItem).GetFullInfoText;
  end
  else if Instance is TShip then
  begin
    if GetRadarRange < PointDistance(Position, (Instance as TShip).Position) then
      Result := (Instance as TShip).GetName
    else Result := (Instance as TShip).GetSpaceInfoText;
  end
  else if Instance is TAsteroid then
  begin
    if GetRadarRange < PointDistance(Position, (Instance as TAsteroid).Position) then
      Result := (Instance as TAsteroid).GetDisplayName
    else Result := (Instance as TAsteroid).GetInfoText;
  end
  else Result := 'unknown object';
end;
{ @end $599E48 }

{ @routine $59A054 TRanger_GetEstimatedMemoryUsage }
function TRanger.GetEstimatedMemoryUsage: Integer;
begin
  Result := inherited GetEstimatedMemoryUsage;
  Result := Result + RangerRelations.InstanceSize + RangerRelations.Count * 4;
  Result := Result + Length(Name) * SizeOf(WideChar);
end;
{ @end $59A054 }

{ @routine $59A090 TRanger_GetEquipmentCashReserve }
function TRanger.GetEquipmentCashReserve: Integer;
begin
  case PreferredCareer of
    rcTrader: Result := Wealth div 5;
    rcPirate: Result := Wealth div 7;
    rcWarrior: Result := Wealth div 10;
  else Result := Wealth div 10;
  end;
end;
{ @end $59A090 }

{ @routine $59A0D4 TRanger_CountWingmen }
function TRanger.CountWingmen: Integer;
var I, Count: Integer; Ranger: TRanger;
begin
  Count := 0;
  for I := 0 to Galaxy.Rangers.Count - 1 do begin
    Ranger := Galaxy.Rangers[I];
    if (Ranger <> Self) and (Self = Ranger.PartnerShip) then Inc(Count);
  end;
  Result := Count;
end;
{ @end $59A0D4 }

{ @routine $59A11C TRanger_NeedsStrengthCatchup }
function TRanger.NeedsStrengthCatchup: Boolean;
begin
  Result := (Strength / Galaxy.AverageRangerStrength < CareerTuning[PreferredCareer].MinimumStrengthToAverageRatio) or
    (StrengthInBestRanger < CareerTuning[PreferredCareer].MinimumStrengthToBestRatio);
end;
{ @end $59A11C }

{ @routine $59A15C TRanger_NeedsWealthCatchup }
function TRanger.NeedsWealthCatchup: Boolean;
begin
  Result := (Wealth / Galaxy.AverageRangerCapital < CareerTuning[PreferredCareer].MinimumWealthToAverageRatio) or
    (WealthInBestRanger < CareerTuning[PreferredCareer].MinimumWealthToBestRatio);
end;
{ @end $59A15C }

{ @routine $59A1A0 TRanger_RefuelAtLocation }
procedure TRanger.RefuelAtLocation;
begin
  if (GetFullRefuelCost > 0) and (GetFullRefuelCost <= Money) then
  begin
    SetMoney(Money - GetFullRefuelCost);
    FuelTanks.Fuel := FuelTanks.Capacity;
  end;
end;
{ @end $59A1A0 }

{ @routine $59A1E0 TRanger_SimulateUnseenProgression }
procedure TRanger.SimulateUnseenProgression;
var Award: Byte; StoredAward: PByte;
begin
  if DaysSincePlayerSeen < 50 / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor then Exit;
  if Player = nil then Exit;
  if IsFinalScenarioActive then Exit;
  if NextRandomUnitFloat(RandomState) < 0.05 then TryPromoteRank;
  if (Money < 50000) and (NextRandomUnitFloat(RandomState) < 0.6) and
    (NextRandomFloatRange(0, 1, RandomState) > WealthInBestRanger) then
    case Round(Player.WealthInBestRanger * 100) of
      0..20: SetMoney(Money + Galaxy.ComputeScaledSmallMoney(oiPeople));
      21..40: SetMoney(Money + Galaxy.ComputeScaledAverageMoney(oiPeople));
      41..60: SetMoney(Money + Galaxy.ComputeScaledAverageMoney(oiPeople));
      61..90: SetMoney(Money + Galaxy.ComputeScaledBigMoney(oiPeople));
      91..100: SetMoney(Money + Galaxy.ComputeScaledHugeMoney(oiPeople));
    end;
  if (NextRandomUnitFloat(RandomState) < 0.05) and (NeedsStrengthCatchup or (NextRandomUnitFloat(RandomState) < 0.3)) then begin
    if (NextRandomFloatRange(0, 0.7, RandomState) > WealthInBestRanger) and (Money < 25000) then
      SetMoney(Money + Galaxy.ComputeScaledAverageMoney(oiPeople))
    else ImproveMostValuableEquipment;
  end;
  if ((CurrentStar.ShipTypeCounts[t_Kling] > 0) and (NextRandomUnitFloat(RandomState) < 0.2)) or
    ((Galaxy.CurrentTurn < 200) and (NextRandomUnitFloat(RandomState) < 0.3)) then begin
    Inc(ScriptStatistics[ssShipsKilled]);
    Inc(ScriptStatistics[ssKlissansKilled]);
    Inc(CurrentSystemKillCount);
    AddRankPoints(NextRandomIntRange(KlissanInfo[ktMutenok].RankPoints, KlissanInfo[ktEgemon].RankPoints, RandomState));
    AddWarriorCareerActivity(4);
  end else if (NextRandomUnitFloat(RandomState) < 0.2) and
    ((GetDominantCareer <> rcPirate) or (NextRandomUnitFloat(RandomState) < 0.2)) then begin
    Inc(ScriptStatistics[ssShipsKilled]);
    Inc(ScriptStatistics[ssPiratesKilled]);
    AddRankPoints(10);
    if NextRandomUnitFloat(RandomState) < 0.2 then begin
      Inc(ScriptStatistics[ssShipsKilled]);
      Inc(ScriptStatistics[ssPiratesKilled]);
      AddRankPoints(10);
    end;
    AddWarriorCareerActivity(2);
  end else if (NextRandomUnitFloat(RandomState) < 0.2) and
    ((GetDominantCareer = rcPirate) or (NextRandomUnitFloat(RandomState) < 0.2)) then begin
    Inc(ScriptStatistics[ssShipsKilled]);
    if PreferredCareer = rcPirate then AddPirateCareerActivity(2) else AddPirateCareerActivity(1);
  end;
  if NextRandomUnitFloat(RandomState) < 0.07 then begin
    case Round(RemapClamped(Player.PlaceInRating, 1, Galaxy.Rangers.Count, 0, 100)) of
      0..20: GainExperience(NextRandomIntRange(25, 100, RandomState));
      21..40: GainExperience(NextRandomIntRange(25, 70, RandomState));
      41..60: GainExperience(NextRandomIntRange(25, 70, RandomState));
      61..80: GainExperience(NextRandomIntRange(25, 70, RandomState));
      81..100: GainExperience(NextRandomIntRange(25, 70, RandomState));
    end;
    if CurrentStar.ShipTypeCounts[t_Kling] > 0 then GainExperience(NextRandomIntRange(25, 70, RandomState));
  end;
  if (Rank < crAce) and (Succ(Rank) < Player.Rank) and (NextRandomUnitFloat(RandomState) < 0.05) then begin
    AddRankPoints(NextRandomIntRange(2, 20, RandomState));
    Inc(ScriptStatistics[ssShipsKilled]);
    Inc(ScriptStatistics[ssPiratesKilled]);
    Inc(ScriptStatistics[ssShipsKilled]);
    Inc(ScriptStatistics[ssPiratesKilled]);
  end;
  if CurrentPlanet <> nil then begin
    if ((Player.AwardIds <> nil) and ((AwardIds = nil) or (Player.AwardIds.Count > AwardIds.Count)) and
        (NextRandomUnitFloat(RandomState) < 0.1)) or
      ((Player.AwardIds <> nil) and ((AwardIds = nil) or (Player.AwardIds.Count + 5 > AwardIds.Count)) and
        (NextRandomUnitFloat(RandomState) < 0.004)) or
      ((Player.AwardIds = nil) and ((AwardIds = nil) or (AwardIds.Count < 4)) and
        (NextRandomUnitFloat(RandomState) < 0.004)) then begin
      case GetDominantCareer of
        rcTrader: Award := SelectAward(CurrentPlanet.OwnerId, [atForSecretMission,atForCowardice]);
        rcPirate: Award := SelectAward(CurrentPlanet.OwnerId, [atForSecretMission,atForCowardice,atForPerfidy]);
        rcWarrior: Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment,atForSecretMission]);
      else Award := 255;
      end;
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      New(StoredAward);
      AwardIds.Add(StoredAward);
      StoredAward^ := Award;
    end;
    if (Galaxy.TechLevel > 3) and (NextRandomUnitFloat(RandomState) < 0.1) then
      if ((Player.StrengthInBestRanger > 0.9) and (StrengthInBestRanger < 0.7)) or
        (StrengthInBestRanger < 0.3) then GenerateExtraWeapon;
  end;
end;
{ @end $59A1E0 }

{ @routine $59A9E4 TRanger_AddTraderCareerActivity }
procedure TRanger.AddTraderCareerActivity(Amount: Byte);
begin
  // Drops increments that would reach or exceed 100.
  if PendingCareerActivity[rcTrader] + Amount < 100 then
    Inc(PendingCareerActivity[rcTrader], Amount);
end;
{ @end $59A9E4 }

{ @routine $59AA00 TRanger_AddPirateCareerActivity }
procedure TRanger.AddPirateCareerActivity(Amount: Byte);
begin
  // Drops increments that would reach or exceed 100.
  if PendingCareerActivity[rcPirate] + Amount < 100 then
    Inc(PendingCareerActivity[rcPirate], Amount);
end;
{ @end $59AA00 }

{ @routine $59AA1C TRanger_AddWarriorCareerActivity }
procedure TRanger.AddWarriorCareerActivity(Amount: Byte);
begin
  // Drops increments that would reach or exceed 100.
  if PendingCareerActivity[rcWarrior] + Amount < 100 then
    Inc(PendingCareerActivity[rcWarrior], Amount);
end;
{ @end $59AA1C }

{ @routine $59AA38 TRanger_ClearPendingCareerActivity }
procedure TRanger.ClearPendingCareerActivity;
begin
  PendingCareerActivity[rcTrader] := 0;
  PendingCareerActivity[rcPirate] := 0;
  PendingCareerActivity[rcWarrior] := 0;
end;
{ @end $59AA38 }

{ @routine $59ABD0 TRanger_ProcessCareerActivityAndEminentProgress }
procedure TRanger.ProcessCareerActivityAndEminentProgress;
var
  Delta: Integer;
  Text: WideString;
  Amount: Integer;
  // @nested $59AA50 IncreaseRangerCareerAxis
  procedure IncreaseRangerCareerAxis(var Selected, OtherA, OtherB: TPercent; Amount: Integer); // @addr $59AA50 @calls "0x0059AC74 0x0059ACCA 0x0059AE05 0x0059AE5B 0x0059AF96 0x0059AFEC" @note "Raises Selected up to 100 and proportionally reduces the other axes when needed."
  var
    Smaller, Larger: ^TPercent;
    SmallReduction, LargeReduction: Integer;
  begin
    if Selected + Amount >= 100 then
    begin
      Selected := 100;
      OtherA := 0;
      OtherB := 0;
    end
    else
    begin
      if OtherA >= OtherB then
      begin
        Smaller := @OtherB;
        Larger := @OtherA;
      end
      else
      begin
        Smaller := @OtherA;
        Larger := @OtherB;
      end;
      SmallReduction := Round(Amount / (Smaller^ + Larger^) * Smaller^);
      LargeReduction := Round(Amount / (Smaller^ + Larger^) * Larger^);
      if SmallReduction + LargeReduction > Amount then Dec(LargeReduction);
      if SmallReduction + LargeReduction < Amount then Inc(SmallReduction);
      if SmallReduction > Smaller^ then RaiseWideMessage('deltaMin>min');
      if LargeReduction > Larger^ then RaiseWideMessage('deltaMax>max');
      if SmallReduction + LargeReduction <> Amount then RaiseWideMessage('deltaMin+deltaMax<>delta');
      Inc(Selected, Amount);
      Dec(Smaller^, SmallReduction);
      Dec(Larger^, LargeReduction);
    end;
  end;

begin
  if (Player <> Self) and ((Galaxy.EminentCareerShips[rcTrader] = Self) or (Galaxy.EminentCareerShips[rcPirate] = Self) or (Galaxy.EminentCareerShips[rcWarrior] = Self)) then
  begin
    ClearPendingCareerActivity;
    Exit;
  end;
  if PendingCareerActivity[rcTrader] > 0 then
  begin
    Delta := PendingCareerActivity[rcTrader];
    if Delta mod 2 <> 0 then Inc(Delta);
    Delta := Min(8, Delta);
    Delta := Delta div 2;
    IncreaseRangerCareerAxis(CareerStatus[rcTrader], CareerStatus[rcPirate], CareerStatus[rcWarrior], Delta);
    if (Galaxy.EminentCareerShips[rcTrader] <> Self) then
    begin
      if EminentProgress[rcTrader] + Delta * 2 >= 100 then
      begin
        if CareerStatus[rcTrader] < 60 then IncreaseRangerCareerAxis(CareerStatus[rcTrader], CareerStatus[rcPirate], CareerStatus[rcWarrior], (60 - CareerStatus[rcTrader]) div 2 + 1);
        Amount := RoundAndTruncateToTens(NextRandomIntRange(25, 50, RandomState) / DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor);
        Text := FormatText2(PickLocalizedTextVariant('GalaxyNews.EminentRangers.EminentTrader', Seed * Cardinal(Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Name, '<Points>', IntToStr(Amount));
        if Player = Self then Galaxy.AddPlanetNewsWithPlayerBubble(Text)
        else Galaxy.AddPlanetNews(gnGeneral, Text);
        EminentProgress[rcTrader] := 0;
        HalveAllRangerEminentProgress(rcTrader);
        GainExperience(Amount);
        Galaxy.EminentCareerShips[rcTrader] := Self;
      end
      else Inc(EminentProgress[rcTrader], Delta * 2);
    end;
  end;
  if PendingCareerActivity[rcPirate] > 0 then
  begin
    Delta := PendingCareerActivity[rcPirate];
    if Delta mod 2 <> 0 then Inc(Delta);
    Delta := Min(8, Delta);
    Delta := Delta div 2;
    IncreaseRangerCareerAxis(CareerStatus[rcPirate], CareerStatus[rcTrader], CareerStatus[rcWarrior], Delta);
    if (Galaxy.EminentCareerShips[rcPirate] <> Self) then
    begin
      if EminentProgress[rcPirate] + Delta * 2 >= 100 then
      begin
        if CareerStatus[rcPirate] < 60 then IncreaseRangerCareerAxis(CareerStatus[rcPirate], CareerStatus[rcTrader], CareerStatus[rcWarrior], (60 - CareerStatus[rcPirate]) div 2 + 1);
        Amount := RoundAndTruncateToTens(NextRandomIntRange(50, 100, RandomState) * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor);
        Text := FormatText2(PickLocalizedTextVariant('GalaxyNews.EminentRangers.EminentPirate', Seed * Cardinal(Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Name, '<Points>', IntToStr(Amount));
        if Player = Self then Galaxy.AddPlanetNewsWithPlayerBubble(Text)
        else Galaxy.AddPlanetNews(gnGeneral, Text);
        EminentProgress[rcPirate] := 0;
        HalveAllRangerEminentProgress(rcPirate);
        RemoveExperience(Amount);
        Galaxy.EminentCareerShips[rcPirate] := Self;
      end
      else Inc(EminentProgress[rcPirate], Delta * 2);
    end;
  end;
  if PendingCareerActivity[rcWarrior] > 0 then
  begin
    Delta := PendingCareerActivity[rcWarrior];
    if Delta mod 2 <> 0 then Inc(Delta);
    Delta := Min(8, Delta);
    Delta := Delta div 2;
    IncreaseRangerCareerAxis(CareerStatus[rcWarrior], CareerStatus[rcTrader], CareerStatus[rcPirate], Delta);
    if (Galaxy.EminentCareerShips[rcWarrior] <> Self) then
    begin
      if EminentProgress[rcWarrior] + Delta * 2 >= 100 then
      begin
        if CareerStatus[rcWarrior] < 60 then IncreaseRangerCareerAxis(CareerStatus[rcWarrior], CareerStatus[rcTrader], CareerStatus[rcPirate], (60 - CareerStatus[rcWarrior]) div 2 + 1);
        Amount := RoundAndTruncateToTens(NextRandomIntRange(50, 100, RandomState) / DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor);
        Text := FormatText2(PickLocalizedTextVariant('GalaxyNews.EminentRangers.EminentWarrior', Seed * Cardinal(Galaxy.CurrentTurn div 10)),
          HighlightColorTag, '<Name>', Name, '<Points>', IntToStr(Amount));
        if Player = Self then Galaxy.AddPlanetNewsWithPlayerBubble(Text)
        else Galaxy.AddPlanetNews(gnGeneral, Text);
        EminentProgress[rcWarrior] := 0;
        HalveAllRangerEminentProgress(rcWarrior);
        GainExperience(Amount);
        Galaxy.EminentCareerShips[rcWarrior] := Self;
      end
      else Inc(EminentProgress[rcWarrior], Delta * 2);
    end;
  end;
  ClearPendingCareerActivity;
end;
{ @end $59ABD0 }

{ @routine $59B29C TRanger_HalveAllRangerEminentProgress }
procedure TRanger.HalveAllRangerEminentProgress(Career: TRangerCareer);
var
  I: Integer;
  Ranger: TRanger;
begin
  for I := 0 to Galaxy.Rangers.Count - 1 do
  begin
    Ranger := TRanger(Galaxy.Rangers[I]);
    Ranger.EminentProgress[Career] := Round(Ranger.EminentProgress[Career] * 0.5);
  end;
end;
{ @end $59B29C }

{ @routine $59B304 TRanger_OrderBestQueuedTradePlanet }
function TRanger.OrderBestQueuedTradePlanet: Boolean;
var
  Planet: TPlanet;
begin
  Planet := SelectBestTradePlanetFromQueue;
  if Planet <> nil then
  begin
    if CurrentStar = Planet.CurrentStar then OrderLanding(Planet, False)
    else OrderJump(Planet.CurrentStar, False);
    Result := True;
  end
  else Result := False;
end;
{ @end $59B304 }

{ @routine $59B338 TRanger_SelectBestTradePlanetFromQueue }
function TRanger.SelectBestTradePlanetFromQueue: TPlanet;
var
  Good: TGoodsIndex;
  BestScore, Profit, PurchaseProfit: Single;
  I: Integer;
  BestPlanet, Planet: TPlanet;
begin
  BestScore := 0;
  BestPlanet := nil;
  for I := 0 to PlanetQueue.Count - 1 do
  begin
    Planet := TPlanet(PlanetQueue[I]);
    if Planet.IsCoalitionOwned then
    begin
      Profit := 0;
      PurchaseProfit := 1;
      for Good := t_Food to t_Narcotics do
      begin
        if CargoGoods[Good].Count > 0 then
        begin
          if Planet.Goods[Good].BaseSalePrice > GetAverageCargoCost(Good) then
            Profit := Profit + (Planet.Goods[Good].BaseSalePrice - GetAverageCargoCost(Good)) * CargoGoods[Good].Count;
        end
        else if Planet.Goods[Good].PurchasePrice < GoodsMarket[Good].BasePrice * 0.7 then
          PurchaseProfit := PurchaseProfit + Min(Money div Planet.Goods[Good].PurchasePrice, Min(CargoFreeSpace, Planet.Goods[Good].Count)) *
            (GoodsMarket[Good].BasePrice - Planet.Goods[Good].PurchasePrice);
      end;
      Profit := Profit + Min(Profit, PurchaseProfit);
      Profit := Profit - RemapClamped(CurrentStar.ThreatLevel, 0, 100, 0, 0.5) * Profit;
      Profit := Profit - RemapClamped(CurrentStar.TrafficLevel, 50, 100, 0, 0.8) * Profit;
      if Planet.CurrentStar = CurrentStar then Profit := 1.6 * Profit;
      if Profit > BestScore then
      begin
        BestScore := Profit;
        BestPlanet := Planet;
      end;
    end;
  end;
  Result := BestPlanet;
  if BestPlanet = nil then begin end;
end;
{ @end $59B338 }

{ @routine $59B57C TRanger_SelectRandomPlanetFromQueue }
function TRanger.SelectRandomPlanetFromQueue: TPlanet;
begin
  if PlanetQueue.Count > 0 then Result := TPlanet(PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)])
  else Result := nil;
end;
{ @end $59B57C }

{ @routine $59B5B0 TRanger_BuildReachablePlanetQueue }
procedure TRanger.BuildReachablePlanetQueue;
var
  I, J: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if Speed = 0 then Exit;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if (I > 0) and (CurrentStar.StarDistances[I].Distance > JumpRange) then Break;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Planet.IsCoalitionOwned and CanQueueReachablePlanet(Planet) and (Planet <> LastDockedPlanet) then
        PlanetQueue.Add(Planet);
    end;
  end;
end;
{ @end $59B5B0 }

{ @routine $59B6A4 TRanger_CanQueueReachablePlanet }
function TRanger.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId <> oiKling;
end;
{ @end $59B6A4 }

{ @routine $59B6B0 TRanger_SelectIdleFreeFlightDestination }
procedure TRanger.SelectIdleFreeFlightDestination(UnusedMode: Byte);
const
  CoalitionShipTypes = [t_Ranger..t_Tranclucator];
  DominatorShipType = [t_Kling];
var
  I, CareerThreshold: Integer;
  Star, NextStar: TStar;
  Good: TGoodsIndex;
  EnemyStrength, FriendlyStrength: Single;
  ShipCount: Integer;
begin
  for Good := t_Food to t_Narcotics do
    if CargoGoods[Good].Count > 0 then Exit;
  if CargoHook = nil then Exit;
  if Hull.Weight > Hull.HullPoints then Exit;
  case PreferredCareer of
    rcTrader: CareerThreshold := 3;
    rcPirate: CareerThreshold := 1;
    rcWarrior: CareerThreshold := 0;
  else CareerThreshold := 0;
  end;
  if UnusedMode = 0 then;
  NextStar := nil;
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if CurrentStar.StarDistances[I].Distance > JumpRange then Break;
    if not ((KlingMotherShip.CurrentStar <> Star) or
      ((Aggression >= 20) and ((Star.CountShipsByTypeMask(CoalitionShipTypes) <= 6) or (NextRandomUnitFloat(RandomState) >= 0.95)) and
      not AcceptsRansomDemandFrom(KlingMotherShip) and ((Star.ControlFaction = sfCoalition) or (FuelTanks.Fuel div 2 >= CurrentStar.StarDistances[I].Distance)))) then Continue;
    if Star.Ships.Count > 20 then Continue;
    ShipCount := Star.CountShipsByTypeMask(CoalitionShipTypes);
    FriendlyStrength := Star.SumBestRangerRelativeStrength(CoalitionShipTypes);
    EnemyStrength := Star.SumBestRangerRelativeStrength(DominatorShipType);
    if (Star.ControlFaction = sfKlissan) and
      (((FuelTanks.Fuel div 2 > CurrentStar.StarDistances[I].Distance) and (ShipCount > 0)) or
      ((ShipCount > 4) and (ShipCount > Star.ShipTypeCounts[t_Kling]) and (FriendlyStrength > EnemyStrength))) then
    begin
      if Star.Battle then
      begin
        OrderJump(Star, False);
        Exit;
      end;
      if NextStar = nil then NextStar := Star;
    end;
    if (Star.ControlFaction = sfKlissan) and (FriendlyStrength + StrengthInBestRanger + 2 > EnemyStrength) and
      (FuelTanks.Fuel div 2 > CurrentStar.StarDistances[I].Distance) then
    begin
      if FriendlyStrength + StrengthInBestRanger > EnemyStrength then
      begin
        OrderJump(Star, False);
        Exit;
      end;
      if NextStar = nil then NextStar := Star;
    end;
    if Star.Battle and (Star.ControlFaction = sfCoalition) and
      ((Star.Ships.Count div 2 > Star.ShipTypeCounts[t_Kling]) or (ShipCount > CareerThreshold + 4) or
      (FuelTanks.Fuel div 2 > CurrentStar.StarDistances[I].Distance) or (FriendlyStrength + StrengthInBestRanger > EnemyStrength)) then
    begin
      OrderJump(Star, False);
      Exit;
    end;
  end;
  if NextStar = nil then
    for I := 1 to Galaxy.Stars.Count - 1 do
    begin
      Star := CurrentStar.StarDistances[I].Star as TStar;
      if (Star.ControlFaction <> sfCoalition) and (Star.CountShipsByTypeMask(CoalitionShipTypes) <= 12) and
        ((KlingMotherShip.CurrentStar <> Star) or ((Aggression >= 30) and (Star.CountShipsByTypeMask(CoalitionShipTypes) <= 6))) then
      begin
        NextStar := FindNextStarTowardDestination(Star, True);
        if NextStar <> nil then Break;
      end;
    end;
  if NextStar <> nil then OrderJump(NextStar, False);
end;
{ @end $59B6B0 }

{ @routine $59BA40 TRanger_TryOrderTravelToShipTypeLocation }
function TRanger.TryOrderTravelToShipTypeLocation(ShipType: TShipType): Boolean;
var
  I, J: Integer;
  Current, Star: TStar;
  Ship: TShip;
begin
  if CurrentStar.ShipTypeCounts[ShipType] > 0 then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if (Ship.ShipType = ShipType) and Ship.InNormalSpace then
      begin
        OrderLanding(Ship, True);
        Result := True;
        Exit;
      end;
    end;
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    Current := CurrentStar;
    Star := Current.StarDistances[I].Star as TStar;
    if (Star.ShipTypeCounts[ShipType] <> 0) and (Star.ShipTypeCounts[t_Ranger] <= 13) then
    begin
      if CurrentStar.StarDistances[I].Distance > Engine.JumpRange then Break;
      { Native scans the current system here, even though Star is a remote candidate. }
      for J := 0 to Current.Ships.Count - 1 do
      begin
        Ship := TShip(CurrentStar.Ships[J]);
        if (Ship.ShipType = ShipType) and Ship.InNormalSpace then
        begin
          OrderJump(Star, True);
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
  Result := False;
end;
{ @end $59BA40 }

{ @routine $59BB84 TRanger_SelectNearestReachableDestination }
procedure TRanger.SelectNearestReachableDestination;
var
  I: Integer;
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
  CurrentTurns, Turns: Integer;
  BestTarget: TObject;
  BestTurns: Integer;
begin
  if PartnerShip <> nil then
  begin
    if PartnerShip.CurrentStar = CurrentStar then
    begin
      if (Order = soLanding) and (PartnerShip.OrderTarget = OrderTarget) then Exit;
      if PartnerShip.Order = soLanding then
      begin
        if CanRefuel or (HasCargoGoods and (GetDesiredCargoFreeSpace > CargoFreeSpace)) or
          (PartnerShip.OrderTarget is TShip) or (Hull.Weight - GetDesiredCargoFreeSpace < GetCarriedItemWeight) or
          (GetHullIntegrityPercent < 70) or HasHullDamageOrBrokenEquippedItems then
        begin
          OrderLanding(PartnerShip.OrderTarget, True);
          Exit;
        end;
      end
      else if PartnerShip.Order = soJump then
      begin
        Star := PartnerShip.OrderTarget as TStar;
        if Star.ControlFaction = sfCoalition then
        begin
          OrderJump(Star, False);
          Exit;
        end;
      end;
    end
    else
    begin
      if (PartnerShip.Order = soJump) and (PartnerShip.OrderTarget is TStar) and (PartnerShip.OrderTarget <> CurrentStar) then
        OrderJump(PartnerShip.OrderTarget as TStar, True)
      else OrderJump(PartnerShip.CurrentStar, True);
      Exit;
    end;
  end;
  if Order in [soLanding, soJump, soEnterBlackHole] then
  begin
    CurrentTurns := EstimateOrderTravelTurns;
    BestTarget := OrderTarget;
    BestTurns := CurrentTurns;
  end
  else
  begin
    CurrentTurns := 1000;
    BestTarget := nil;
    BestTurns := CurrentTurns;
  end;
  for I := 0 to CurrentStar.Planets.Count - 1 do
  begin
    Planet := TPlanet(CurrentStar.Planets[I]);
    if CanQueueReachablePlanet(Planet) and Planet.IsCoalitionOwned then
    begin
      Turns := EstimateTravelTurnsToObject(Planet);
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Planet;
      end;
    end;
  end;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(CurrentStar.Ships[I]);
    if Ship.ShipType in [t_RangerCenter..t_ScientificBase] then
    begin
      Turns := EstimateTravelTurnsToObject(Ship);
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Ship;
      end;
    end;
  end;
  if not (BestTarget is TPlanet) and not (BestTarget is TShip) then
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    if CurrentStar.StarDistances[I].Distance > JumpRange then Break;
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if Star.ControlFaction <> sfKlissan then
    begin
      Turns := EstimateTravelTurnsToObject(Star);
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Star;
      end;
    end;
  end;
  if (BestTarget <> nil) and (BestTarget <> OrderTarget) then
    if BestTarget is TPlanet then OrderLanding(BestTarget, False)
    else if BestTarget is TShip then OrderLanding(BestTarget, False)
    else if BestTarget is TStar then OrderJump(BestTarget as TStar, False);
end;
{ @end $59BB84 }

{ @routine $59BECC TRanger_SelectAlternateReachableDestination }
procedure TRanger.SelectAlternateReachableDestination;
var
  I: Integer;
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
  CurrentTurns, Turns: Integer;
  BestTarget: TObject;
  BestTurns, LeavingBonus: Integer;
begin
  if Order in [soLanding, soJump, soEnterBlackHole] then
  begin
    CurrentTurns := EstimateOrderTravelTurns;
    BestTarget := OrderTarget;
    BestTurns := CurrentTurns;
  end
  else
  begin
    CurrentTurns := 1000;
    BestTarget := nil;
    BestTurns := CurrentTurns;
  end;
  for I := 0 to CurrentStar.Planets.Count - 1 do
  begin
    Planet := TPlanet(CurrentStar.Planets[I]);
    if (Planet <> LastDockedPlanet) and CanQueueReachablePlanet(Planet) and Planet.IsCoalitionOwned then
    begin
      Turns := EstimateTravelTurnsToObject(Planet);
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Planet;
      end;
    end;
  end;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(CurrentStar.Ships[I]);
    if (Ship <> LastDockedNonPlanetLocation) and (Ship.ShipType in [t_RangerCenter..t_ScientificBase]) then
    begin
      Turns := EstimateTravelTurnsToObject(Ship);
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Ship;
      end;
    end;
  end;
  LeavingBonus := 0;
  if (GetHullIntegrityPercent > 70) and (((LastDockedNonPlanetLocation <> nil) and (LastDockedNonPlanetLocation.CurrentStar = CurrentStar)) or
    ((LastDockedPlanet <> nil) and (LastDockedPlanet.CurrentStar = CurrentStar))) then Inc(LeavingBonus, 10);
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    if CurrentStar.StarDistances[I].Distance > JumpRange then Break;
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if Star.ControlFaction <> sfKlissan then
    begin
      Turns := EstimateTravelTurnsToObject(Star) - LeavingBonus;
      if BestTurns > Turns then
      begin
        BestTurns := Turns;
        BestTarget := Star;
      end;
    end;
  end;
  if (BestTarget <> nil) and (BestTarget <> OrderTarget) then
    if BestTarget is TPlanet then OrderLanding(BestTarget, False)
    else if BestTarget is TShip then
    begin
      if not (BestTarget is TRuins) and not (BestTarget is TRuins) then;
      OrderLanding(BestTarget, False);
    end
    else if BestTarget is TStar then OrderJump(BestTarget as TStar, False);
end;
{ @end $59BECC }

{ @routine $59C0FC TRanger_SellCargoGoods }
procedure TRanger.SellCargoGoods;
var Good: TGoodsIndex; AverageCost: Single; BestPlanet: TPlanet;
begin
  for Good := t_Food to t_Narcotics do
    if CargoGoods[Good].Count <> 0 then begin
      AverageCost := GetAverageCargoCost(Good);
      if (GetLocationGoodsEntry(Good).BaseSalePrice > AverageCost) or
        (FindBestQueuedSellPlanetProfitScore(Good, BestPlanet, AverageCost) < 80) or not NeedsWealthCatchup then
        SellGoodsToLocation(Good, CargoGoods[Good].Count);
    end;
  RefreshDerivedStats;
end;
{ @end $59C0FC }

{ @routine $59C17C TRanger_BuyProfitableGoods }
procedure TRanger.BuyProfitableGoods;
var
  BestGood, Good: TGoodsIndex;
  Count: Integer;
  KeepBuying: Boolean;
  BestRatio: Double;
  BestPlanet: TPlanet;
begin
  KeepBuying := True;
  while (Money > 0) and KeepBuying do
  begin
    BestRatio := 0;
    BestGood := t_Food;
    for Good := t_Food to t_Narcotics do
      if (CurrentPlanet.Goods[Good].Count > 0) and
        (CurrentPlanet.Goods[Good].PurchasePrice < GoodsMarket[Good].BasePrice * 1.1) and
          (GoodsMarket[Good].BasePrice / CurrentPlanet.Goods[Good].PurchasePrice > BestRatio) and
          (FindBestQueuedSellPlanetProfitScore(Good, BestPlanet, CurrentPlanet.Goods[Good].PurchasePrice) > 50) then
              if Min(CargoFreeSpace, CurrentPlanet.Goods[Good].Count) * CurrentPlanet.Goods[Good].PurchasePrice > Min(Money * 0.2, Wealth * 0.05) then
              begin
                BestRatio := GoodsMarket[Good].BasePrice / GetLocationGoodsEntry(Good).PurchasePrice;
                BestGood := Good;
              end;
    if BestRatio > 0 then
    begin
      Count := Min(Trunc(Money / CurrentPlanet.Goods[BestGood].PurchasePrice), CargoFreeSpace);
      if Count > 0 then
      begin
        Count := Min(CurrentPlanet.Goods[BestGood].Count, Count);
        BuyGoodsFromLocation(BestGood, Count);
      end
      else KeepBuying := False;
    end
    else KeepBuying := False;
    RefreshDerivedStats;
  end;
end;
{ @end $59C17C }

{ @routine $59C354 TRanger_FindBestQueuedSellPlanetProfitScore }
function TRanger.FindBestQueuedSellPlanetProfitScore(Good: TGoodsIndex; var BestPlanet: TPlanet; UnitCost: Double): Byte;
var
  I: Integer;
  Planet: TPlanet;
  Score: Double;
begin
  Result := 0;
  for I := 1 to PlanetQueue.Count - 1 do
  begin
    Planet := TPlanet(PlanetQueue[I]);
    if Planet.CurrentStar = CurrentStar then
      Score := RemapClamped(Planet.Goods[Good].BaseSalePrice / UnitCost, 1, 1.4, 0, 100)
    else
      Score := RemapClamped(Planet.Goods[Good].BaseSalePrice / UnitCost, 1, 2, 0, 100);
    if Result < Score then
    begin
      BestPlanet := Planet;
      Result := Round(Score);
    end;
  end;
end;
{ @end $59C354 }

{ @routine $59C44C TRanger_ApplyIllegalGoodsTradeRelationsPenalty }
procedure TRanger.ApplyIllegalGoodsTradeRelationsPenalty(TotalTradeValue: Integer);
begin
  if CurrentPlanet <> nil then begin
    CurrentPlanet.ChangeRelationToRanger(Self, -Round(RemapClamped(TotalTradeValue,
      Galaxy.AverageRangerCapital div 30, Galaxy.AverageRangerCapital div 7, 20, 70)));
    if Player = Self then AddPirateCareerActivity(4)
    else AddPirateCareerActivity(2);
  end;
end;
{ @end $59C44C }

{ @routine $59C4FC TRanger_BuyInitialEquipment }
procedure TRanger.BuyInitialEquipment;
var Reserve: Integer;
begin
  Reserve := GetEquipmentCashReserve;
  if Reserve > Money then Exit;
  SetMoney(Money - Reserve);
  case PreferredCareer of
    rcTrader: BuyHullUpgrade(scBig);
    rcPirate: BuyHullUpgrade(scZero);
    rcWarrior: BuyHullUpgrade(scBig);
  end;
  case PreferredCareer of
    rcTrader: BuyCargoHookUpgrade(scZero);
    rcPirate: begin
      BuyCargoHookUpgrade(scBig);
      if CargoHook = nil then BuyCargoHookUpgrade(scAverage);
    end;
    rcWarrior: begin
      BuyCargoHookUpgrade(scBig);
      if CargoHook = nil then BuyCargoHookUpgrade(scAverage);
    end;
  end;
  case PreferredCareer of
    rcTrader: BuyWeaponUpgrade(scZero);
    rcPirate: begin BuyWeaponUpgrade(scZero); BuyWeaponUpgrade(scAverage); BuyWeaponUpgrade(scBig); end;
    rcWarrior: begin BuyWeaponUpgrade(scAverage); BuyWeaponUpgrade(scBig); end;
  end;
  case PreferredCareer of
    rcTrader: BuyEngineUpgrade(scZero);
    rcPirate: BuyEngineUpgrade(scSmall);
    rcWarrior: BuyEngineUpgrade(scAverage);
  end;
  if WeaponCount = 0 then BuyWeaponUpgrade(scAverage);
  if CargoHook = nil then BuyCargoHookUpgrade(scAverage);
  BuyFuelTanksUpgrade(scAverage);
  BuyScannerUpgrade(scSmall);
  BuyRadarUpgrade(scSmall);
  BuyRepairRobotUpgrade(scAverage);
  BuyDefGeneratorUpgrade(scSmall);
  SetMoney(Money + Reserve);
end;
{ @end $59C4FC }

{ @routine $59C684 TRanger_UpgradeEquipmentAtLocation }
procedure TRanger.UpgradeEquipmentAtLocation;
var Reserve: Integer;
begin
  Reserve := GetEquipmentCashReserve;
  if (Reserve + 100 > Money) and (WeaponCount > 1) then Exit;
  SetMoney(Money - Reserve);
  if RecomputeFearState and (Self <> Player) and (CurrentPlanet <> nil) then begin
    SetMoney(Money + Reserve);
    Reserve := 0;
    if Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId) > Money then
      SetMoney(Money + Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId));
    BuyHullUpgrade(scZero);
    BuyWeaponUpgrade(scBig);
    BuyWeaponUpgrade(scZero);
    BuyRepairRobotUpgrade(scZero);
    BuyDefGeneratorUpgrade(scZero);
  end;
  case PreferredCareer of
    rcTrader: begin
      if CargoHook = nil then begin
        BuyCargoHookUpgrade(scBig);
        if CargoHook = nil then begin
          SetMoney(Money + Reserve);
          if Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId) > Money then
            SetMoney(Money + Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId));
          Reserve := 0;
          BuyCargoHookUpgrade(scZero);
        end;
      end;
      if WeaponCount = 0 then BuyWeaponUpgrade(scSmall);
      if NeedsStrengthCatchup then BuyWeaponUpgrade(scAverage);
      BuyCargoHookUpgrade(scAverage);
      BuyEngineUpgrade(scSmall);
      BuyHullUpgrade(scBig);
      if DefGenerator = nil then BuyDefGeneratorUpgrade(scSmall) else BuyDefGeneratorUpgrade(scBig);
      BuyRepairRobotUpgrade(scBig);
      BuyFuelTanksUpgrade(scBig);
      if (WeaponCount > 1) or (Radar = nil) then BuyRadarUpgrade(scBig);
      if WeaponCount > 2 then BuyScannerUpgrade(scBig);
      BuyWeaponUpgrade(scAverage);
    end;
    rcPirate: begin
      if CargoHook = nil then begin
        BuyCargoHookUpgrade(scBig);
        if CargoHook = nil then begin
          SetMoney(Money + Reserve);
          if Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId) > Money then
            SetMoney(Money + Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId));
          Reserve := 0;
          BuyCargoHookUpgrade(scZero);
        end;
      end;
      if NeedsStrengthCatchup then BuyWeaponUpgrade(scAverage);
      BuyEngineUpgrade(scBig);
      BuyCargoHookUpgrade(scAverage);
      BuyHullUpgrade(scSmall);
      if DefGenerator = nil then BuyDefGeneratorUpgrade(scSmall) else BuyDefGeneratorUpgrade(scBig);
      BuyRepairRobotUpgrade(scSmall);
      BuyFuelTanksUpgrade(scSmall);
      if (WeaponCount > 1) or (Radar = nil) then BuyRadarUpgrade(scBig);
      if WeaponCount > 2 then BuyScannerUpgrade(scBig);
      BuyWeaponUpgrade(scBig);
    end;
    rcWarrior: begin
      if CargoHook = nil then begin
        BuyCargoHookUpgrade(scBig);
        if CargoHook = nil then begin
          SetMoney(Money + Reserve);
          if Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId) > Money then
            SetMoney(Money + Galaxy.ComputeScaledBigMoney(CurrentPlanet.OwnerId));
          Reserve := 0;
          BuyCargoHookUpgrade(scZero);
        end;
      end;
      if NeedsStrengthCatchup then BuyWeaponUpgrade(scAverage);
      BuyCargoHookUpgrade(scAverage);
      BuyEngineUpgrade(scSmall);
      BuyHullUpgrade(scAverage);
      BuyWeaponUpgrade(scAverage);
      if DefGenerator = nil then BuyDefGeneratorUpgrade(scSmall) else BuyDefGeneratorUpgrade(scBig);
      BuyRepairRobotUpgrade(scAverage);
      BuyFuelTanksUpgrade(scAverage);
      if (WeaponCount > 1) or (Radar = nil) then BuyRadarUpgrade(scAverage);
      if WeaponCount > 2 then BuyScannerUpgrade(scBig);
    end;
  end;
  SetMoney(Money + Reserve);
end;
{ @end $59C684 }
{ @routine $59CA94 TRanger_RepairBrokenEquipmentAtLocation }
procedure TRanger.RepairBrokenEquipmentAtLocation;
var I, Cost: Integer; Equipment: TEquipment;
begin
  for I := Inventory.Count - 1 downto 0 do begin
    Equipment := Inventory[I];
    if (Equipment.BrokenFlag or (Equipment.ConditionPercent < 50)) and Equipment.EquippedFlag then begin
      Cost := Equipment.CalculateRepairCost;
      if Cost < Money then SetMoney(Money - Cost);
      // Native NPC repair still succeeds when the ship cannot afford it.
      if Self <> Player then Equipment.Repair;
    end;
  end;
end;
{ @end $59CA94 }

{ @routine $59CB08 TRanger_RelationToNonRanger }
function TRanger.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if (EnemyShip = Ship) or (Ship.EnemyShip = Self) then Result := 0
  else
    case Ship.ShipType of
      t_Ranger: if Ship <> Self then Result := RelationToRanger(Ship) else Result := 100;
      t_Transport: if PreferredCareer = rcTrader then Result := 90
         else if PreferredCareer = rcWarrior then Result := OwnerRelations[OwnerId, Ship.OwnerId]
         else Result := OwnerRelations[OwnerId, Ship.OwnerId] shr 1;
      t_Pirate: if PreferredCareer = rcPirate then Result := OwnerRelations[OwnerId, Ship.OwnerId]
         else Result := OwnerRelations[OwnerId, Ship.OwnerId] shr 1;
      t_Warrior: Result := (Ship as TWarrior).HomePlanet.GetRangerRelationByIndex(Galaxy.Rangers.IndexOf(Self));
      t_Kling: Result := 0;
      t_Tranclucator: if (Ship as TTranclucator).OwnerShip <> nil then Result := RelationToNonRanger((Ship as TTranclucator).OwnerShip)
         else Result := 100;
      t_RangerCenter..t_ScientificBase: Result := 100;
    else Result := 50;
    end;
end;
{ @end $59CB08 }

{ @routine $59CC90 TRanger_RelationToRanger }
function TRanger.RelationToRanger(Ranger: TObject): Byte;
begin
  Result := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
end;
{ @end $59CC90 }

{ @routine $59CCC4 TRanger_ChangeRelationToRanger }
procedure TRanger.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
var Relation: Byte; Value: Integer;
begin
  Relation := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  { Charisma also increases the magnitude of negative changes. }
  if TShip(Ranger).BaseSkills[skCharm] > 0 then Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.2));
  Value := Relation + Amount;
  if Value < 0 then Relation := 0
  else if Value > 100 then Relation := 100
  else Relation := Value;
  { The breakup check reads the old relation: the new value is stored last. }
  if (Ranger = PartnerShip) and (Relation <= 30) then CheckForPartnershipBreakup;
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then EnemyShip := TShip(Ranger);
  RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $59CCC4 }

{ @routine $59CDB0 TRanger_ReactToAttack }
procedure TRanger.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.ShipType = t_Ranger then
    ChangeRelationToRanger(Attacker, Round(RemapClamped(Hull.HullPoints, Hull.Weight * 0.5, Hull.Weight, -80, -20)));
end;
{ @end $59CDB0 }

{ @routine $59CE20 TRanger_RecomputeFearState }
function TRanger.RecomputeFearState: Boolean;
var
  I, AttackerCount: Integer;
  Ship: TShip;
  HullThreshold, Threat: Double;
begin
  if (CurrentPlanet <> nil) or (DockedTo <> nil) then
  begin
    Result := (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and (EnemyShip.Strength > Strength);
    InFear := Result;
    Exit;
  end;
  Result := ((1 - RemapClamped(Aggression, 0, 100, 0.7, 0.9)) * Hull.Weight > Hull.HullPoints) or
    ((EnemyShip <> nil) and ((EnemyShip.OrderTarget = Self) or (Player = EnemyShip)) and AcceptsRansomDemandFrom(EnemyShip));
  if not Result then
  begin
    Threat := 0;
    AttackerCount := 0;
    HullThreshold := RemapClamped(Hull.HullPoints, 50, Hull.Weight, 0, 3);
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if Ship.InNormalSpace and (Ship <> Self) then
      begin
        if Ship = EnemyShip then
        begin
          Threat := Threat + Ship.ChanceToWin(Self);
          Inc(AttackerCount);
        end
        else if ((((Ship.EnemyShip = Self) and (Ship.OrderTarget = Self)) or (Ship.OwnerId = oiKling)) and
          (PointDistanceSquared(Position, Ship.Position) < 1440000)) or
          ((Ship.RelationToNonRanger(Self) < 10) and (PointDistanceSquared(Position, Ship.Position) < 360000)) then
        begin
          Inc(AttackerCount);
          Threat := Threat + Ship.ChanceToWin(Self);
          if (EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar) or EnemyShip.IsOutsideStarSpace then EnemyShip := Ship
          else if (EnemyShip <> Ship) and (OrderTarget <> EnemyShip) then
            if PointDistanceSquared(EnemyShip.Position, Position) > PointDistanceSquared(Ship.Position, Position) then EnemyShip := Ship;
        end;
      end;
    end;
    if Threat + (AttackerCount - 1) * Threat * 0.3 > HullThreshold + RemapClamped(Aggression, 0, 100, 0, 1) then Result := True;
  end;
  if (Player = PartnerShip) and (GetHullIntegrityPercent > 20) and (Player.CurrentStar = CurrentStar) and
    Player.InNormalSpace and OrderAbsolute then Result := False;
  InFear := Result;
end;
{ @end $59CE20 }

{ @routine $59D158 TRanger_TryOfferRansomToPursuer }
procedure TRanger.TryOfferRansomToPursuer;
var
  Text: WideString;
  Amount: Integer;
  MaximumOffer, MinimumOffer: Single;
  Accepted: Boolean;
  OtherShip: TShip;
begin
  if InNormalSpace and (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and (EnemyShip.TruceShip <> Self) and
    (Money > 100) and not CanEscapePursuer(EnemyShip) and not (EnemyShip.ShipType in NonNegotiatingShipTypes) then
    if (PointDistanceSquared(Position, EnemyShip.Position) <= EnemyShip.GetMaxWeaponRange * EnemyShip.GetMaxWeaponRange) and
      (((Integer(Cardinal(Galaxy.CurrentTurn) * EnemyShip.Id) mod 3 = 0) and (NextRandomUnitFloat(RandomState) > 0.2)) or
      (GetHullIntegrityPercent < 20)) then
    begin
      MaximumOffer := Min(Money, GetWealthScaledAmount(scMini));
      MinimumOffer := Min(Money, (GetWealthScaledAmount(scBig) + EnemyShip.GetWealthScaledAmount(scBig)) * 0.5);
      Amount := Round(Max(100, RemapClampedAlternate(Hull.HullPoints, 0, Hull.Weight, MinimumOffer, MaximumOffer)));
      OtherShip := EnemyShip;
      Accepted := OtherShip.BuildTrucePaymentResponse(Self, Text, Amount);
      if (Player <> OtherShip) and (Player.CurrentStar = CurrentStar) then NotifyTruceOffer(OtherShip, Text, Amount);
      if Accepted and RecomputeFearState then TryOfferRansomToPursuer;
    end;
end;
{ @end $59D158 }

{ @routine $59D3BC TRanger_AcceptsRansomDemandFrom }
function TRanger.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := ((GetHullIntegrityPercent < 80) and (ChanceToWin(Ship) + Aggression * 0.005 < 1)) or (ChanceToWin(Ship) < 0.2);
end;
{ @end $59D3BC }

{ @routine $59D438 TRanger_UpdateRelationsAfterShipKill }
procedure TRanger.UpdateRelationsAfterShipKill(Victim: TShip);
var
  I, J, LastStar: Integer;
  Factor: Single; // Native rounds the distance and owner factors after each scaling step.
  Star: TStar;
  Ship: TShip;
  Planet: TPlanet;
begin
  if Victim.HasScriptBindings then Exit;
  if Player = Self then LastStar := Galaxy.Stars.Count - 1
  else LastStar := Galaxy.Stars.Count div 3;
  for I := 0 to LastStar do
  begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if (Star.ControlFaction in [sfKlissan]) and not Star.Battle then Continue;
    Factor := RemapClampedAlternate(I, 0, LastStar, 0.5, 0.05);
    if Victim.OwnerId = oiKling then Factor := 0.05 * Factor
    else if Player <> Self then Factor := 0.1 * Factor;
    for J := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[J]);
      if not (Ship.ShipType in [t_Ranger..t_Pirate]) then Continue;
      Ship.ChangeRelationToRanger(Self, Round((50 - (Ship.RelationToNonRanger(Victim))) * Factor));
    end;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Planet.IsCoalitionOwned then
        Planet.ChangeRelationToRanger(Self, Round((50 - (Planet.RelationToShip(Victim))) * Factor));
    end;
  end;
  if (Victim.HomePlanet <> nil) and Victim.HomePlanet.IsCoalitionOwned then
    Victim.HomePlanet.ChangeRelationToRanger(Self,
      Round((50 - Victim.HomePlanet.RelationToShip(Victim)) / 2));
end;
{ @end $59D438 }

{ @routine $59D688 TRanger_ApplyExtortionReputationPenalty }
procedure TRanger.ApplyExtortionReputationPenalty(Victim: TShip);
var
  I, J, LastStar, Activity: Integer;
  Effect: Single;
  Star: TStar;
  Planet: TPlanet;
  Ship: TShip;
begin
  if Player = Self then Activity := 8 else Activity := 1;
  AddPirateCareerActivity(Activity);
  LastStar := Galaxy.Stars.Count div 3;
  for I := 0 to LastStar do
  begin
    Star := CurrentStar.StarDistances[I].Star as TStar;
    if (not (Star.ControlFaction in [sfKlissan])) or Star.Battle then
    begin
      Effect := RemapClampedAlternate(I, 0, LastStar, 0.3, 0.05);
      if Player <> Self then Effect := 0.1 * Effect;
      for J := 0 to Star.Ships.Count - 1 do
      begin
        Ship := TShip(Star.Ships[J]);
        if (Ship.ShipType in [t_Ranger..t_Pirate]) and ((I <> 0) or ((Ship <> Self) and (Ship <> Victim))) then
          Ship.ChangeRelationToRanger(Self, Round((50 - (Ship.RelationToNonRanger(Victim))) * Effect));
      end;
      for J := 0 to Star.Planets.Count - 1 do
      begin
        Planet := TPlanet(Star.Planets[J]);
        if Planet.IsCoalitionOwned then
          Planet.ChangeRelationToRanger(Self, Round((50 - (Planet.RelationToShip(Victim))) * Effect));
      end;
    end;
  end;
end;
{ @end $59D688 }

{ @routine $59D86C TRanger_TryRecruitWingman }
procedure TRanger.TryRecruitWingman;
var
  I, Offers, MaxDistance, Amount: Integer;
  Ship: TShip;
  Ranger: TRanger;
  Text: WideString;
begin
  if (Integer(BaseSkills[skLeadership]) > CountWingmen) and (PartnerShip = nil) and
    (Wealth div 20 <= Money) and (Wealth >= Galaxy.AverageRangerCapital * 1.1) and
    (Strength >= 1.1 * Galaxy.AverageRangerStrength) then
  begin
    MaxDistance := Max(GetRadarRange * GetRadarRange, 250000);
    Offers := 0;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if Ship.ShipType = t_Ranger then
      begin
        Ranger := Ship as TRanger;
        if (Ranger <> Self) and (Ranger <> EnemyShip) and (Ranger.EnemyShip <> Self) and Ranger.InNormalSpace and
          (Player <> Ranger) and (MaxDistance >= PointDistanceSquared(Position, Ranger.Position)) and
          (Ranger.RelationToNonRanger(Self) >= 30) and ((NextRandomUnitFloat(RandomState) <= 0.5) or (Rank >= Ranger.Rank)) then
        begin
          Amount := Round(Money * 0.7);
          if not Ranger.BuildPartnershipOfferResponse(Self, Text, Amount) and (NextRandomUnitFloat(RandomState) > 0.1) then Continue;
          if (Ranger.AcceptPartnershipOffer(Self, Text, Amount) or (NextRandomUnitFloat(RandomState) > 0.8)) and
            (Player.CurrentStar = CurrentStar) then
          begin
            NotifyPartnershipOffer(Ship, Text, Amount);
            Break;
          end;
          Inc(Offers);
          if Offers = 3 then Break;
        end;
      end;
    end;
  end;
end;
{ @end $59D86C }

{ @routine $59DB00 TRanger_CheckForPartnershipBreakup }
procedure TRanger.CheckForPartnershipBreakup;
var Leader: TShip;
begin
  if PartnerShip = nil then Exit;
  if PartnershipDaysRemaining < 1 then
  begin
    if (CurrentStar = PartnerShip.CurrentStar) and InNormalSpace and PartnerShip.InNormalSpace and
      (PointDistanceSquared(Position, PartnerShip.Position) <= Max(GetRadarRange * GetRadarRange, 250000)) then
    begin
      Leader := PartnerShip;
      if (Order = soFollowShip) and (OrderTarget = PartnerShip) then OrderNone;
      PartnerShip := nil;
      NotifyPartnerRebellion(Leader);
    end;
  end
  else if RelationToNonRanger(PartnerShip) < 30 then
  begin
    if (CurrentStar = PartnerShip.CurrentStar) and InNormalSpace and PartnerShip.InNormalSpace and
      (PointDistanceSquared(Position, PartnerShip.Position) <= Max(GetRadarRange * GetRadarRange, 250000)) then
    begin
      Leader := PartnerShip;
      if (Order = soFollowShip) and (OrderTarget = PartnerShip) then OrderNone;
      PartnerShip := nil;
      NotifyPartnerBreak(Leader);
    end;
  end;
end;
{ @end $59DB00 }

{ @routine $59DC98 TRanger_TrustsAttackRequester }
function TRanger.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := RelationToNonRanger(Ship) >= 30;
end;
{ @end $59DC98 }

{ @routine $59DCB0 TRanger_EvaluateAllyRelationAndStrength }
function TRanger.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := (RelationToNonRanger(Ship)) +
    RemapClamped(Ship.Strength, 0.9 * Strength, Strength * 3.0, 0.0, 100.0) > 120.0;
end;
{ @end $59DCB0 }
{ @routine $59E0A8 TRanger_ProcessPrisonAndHostileCheck }
function TRanger.ProcessPrisonAndHostileCheck: Boolean;
var I: Integer; Warrior: TShip;
  // @nested $59DD38 Imprison
  procedure Imprison; // @addr $59DD38
  var I: Integer; Ship: TShip; Text: WideString;
  begin
    PrisonTermRemaining := Round(RemapClamped(CareerStatus[rcPirate], 0, 100, 61, 140));
    CurrentPlanet.ChangeRelationToRanger(Self, 80);
    ChangePlanetRelations(nil, rcmRaiseTo, 45, CoalitionOwners);
    Result := True;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := CurrentStar.Ships[I];
      if (Ship.ShipType = t_Warrior) and (Self = Ship.EnemyShip) then
      begin
        Ship.EnemyShip := nil;
        if Self = Ship.OrderTarget then Ship.OrderNone;
      end;
    end;
    Text := PickLocalizedTextVariant('GalaxyNews.GoToPrison.' + GetTypeNameKey, Seed + Cardinal(Galaxy.CurrentTurn div 10));
    ReplaceTextToken(Text, '<Star>', CurrentStar.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<Planet>', CurrentPlanet.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<Month>', IntToStr(PrisonTermRemaining div 30), HighlightColorTag);
    ReplaceTextToken(Text, '<Name>', GetName, HighlightColorTag);
    ReplaceTextToken(Text, '<FullName>', GetFullName(' '), HighlightColorTag);
    if (Player.CurrentStar = CurrentStar) and Player.InNormalSpace then Galaxy.AddPlanetNewsWithPlayerBubble(Text)
    else Galaxy.AddPlanetNews(gnGeneral, Text);
  end;
begin
  Result := False;
  if CurrentPlanet <> nil then
  begin
    if PrisonTermRemaining > 0 then
    begin
      if CurrentStar.Battle then
      begin
        PrisonTermRemaining := 0;
        Result := False;
      end
      else
      begin
        Dec(PrisonTermRemaining);
        if PrisonTermRemaining = 0 then Result := False else Result := True;
      end;
    end
    else if CurrentPlanet.GetRelationLevelToShip(Self) = rlHostile then Imprison
    else
      for I := 0 to CurrentPlanet.Warriors.Count - 1 do
      begin
        Warrior := CurrentPlanet.Warriors[I];
        if Warrior.EnemyShip = Self then
        begin
          Imprison;
          Break;
        end;
      end;
  end;
end;
{ @end $59E0A8 }

{ @routine $59E2A0 TRanger_ChangeShipRelations }
procedure TRanger.ChangeShipRelations(Scope: TObject; Mode: TRelationChangeMode; Amount: Byte; ShipTypes: THullShipTypeMask; Owners: TOwnerSet);
var Previous: Byte; Ship: TShip; RangerIndex, I, J: Integer; Star: TStar;
  // @nested $59E170 ApplyToShip
  procedure ApplyToShip; // @addr $59E170
  begin
    case Mode of
      rcmCapAt: if Previous > Amount then Ship.RangerRelations[RangerIndex] := Pointer(Amount);
      rcmRaiseTo: if Previous < Amount then Ship.RangerRelations[RangerIndex] := Pointer(Amount);
      rcmIncrease: Ship.ChangeRelationToRanger(Self, Amount);
      rcmDecrease: Ship.ChangeRelationToRanger(Self, -Amount);
      rcmDecreaseWithFloor20: if Previous > 20 then
        if Previous - Amount < 20 then Ship.RangerRelations[RangerIndex] := Pointer(20)
        else Ship.ChangeRelationToRanger(Self, -Amount);
    end;
    Exit;
  end;
begin
  RangerIndex := Galaxy.Rangers.IndexOf(Self);
  if Scope is TShip then begin
    Ship := Scope as TShip;
    if (ShipToHullType(Ship) in ShipTypes) and (Ship.OwnerId in Owners) then begin
      Previous := Byte(Ship.RangerRelations[RangerIndex]);
      ApplyToShip;
    end;
  end
  else for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := Galaxy.Stars[I];
    if Scope is TConstellation then
      if (Scope as TConstellation) <> Star.Constellation then Continue;
    if Scope is TStar then
      if (Scope as TStar) <> Star then Continue;
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := Star.Ships[J];
      if (ShipToHullType(Ship) in ShipTypes) and (Ship.OwnerId in Owners) and
        (Ship.RangerRelations.Count >= 1) then begin
        Previous := Byte(Ship.RangerRelations[RangerIndex]);
        ApplyToShip;
      end;
    end;
  end;
end;
{ @end $59E2A0 }

{ @routine $59E448 TRanger_ChangePlanetRelations }
procedure TRanger.ChangePlanetRelations(Scope: TObject; Mode: TRelationChangeMode; Amount: Byte; Owners: TOwnerSet);
var
  I, J, RangerIndex: Integer;
  Star: TStar;
  Planet: TPlanet;
  Previous: TPercent;
begin
  RangerIndex := Galaxy.Rangers.IndexOf(Self);
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if Scope is TConstellation then
      if (Scope as TConstellation) <> Star.Constellation then Continue;
    if Scope is TStar then
      if (Scope as TStar) <> Star then Continue;
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if not (Planet.OwnerId in Owners) or not Planet.IsCoalitionOwned then Continue;
      if (Scope is TPlanet) and ((Scope as TPlanet) <> Planet) then Continue;
      Previous := TPercent(Planet.RangerRelations[RangerIndex]);
      case Mode of
        rcmCapAt: if Previous > Amount then Planet.RangerRelations[RangerIndex] := Pointer(Amount);
        rcmRaiseTo: if Previous < Amount then Planet.RangerRelations[RangerIndex] := Pointer(Amount);
        rcmIncrease: Planet.ChangeRelationToRanger(Self, Amount);
        rcmDecrease: Planet.ChangeRelationToRanger(Self, -Amount);
        rcmDecreaseWithFloor20:
          if Previous > 20 then
            if Previous - Amount < 20 then Planet.RangerRelations[RangerIndex] := Pointer(20)
            else Planet.ChangeRelationToRanger(Self, -Amount);
      end;
    end;
  end;
end;
{ @end $59E448 }

{ @routine $59E658 TRanger_GlobalRelationsShips }
function TRanger.GlobalRelationsShips(Scope: TObject; ShipTypes: THullShipTypeMask; Owners: TOwnerSet): Byte;
var I, J, RangerIndex, Total, Count: Integer; Star: TStar; Ship: TShip; Previous: Integer;
begin
  if Scope is TShip then begin
    Result := (Scope as TShip).RelationToRanger(Self);
    Exit;
  end;
  RangerIndex := Galaxy.Rangers.IndexOf(Self);
  Total := 0;
  Count := 0;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := Galaxy.Stars[I];
    if Scope is TConstellation then
      if (Scope as TConstellation) <> Star.Constellation then Continue;
    if Scope is TStar then
      if (Scope as TStar) <> Star then Continue;
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := Star.Ships[J];
      if (ShipToHullType(Ship) in ShipTypes) and (Ship.OwnerId in Owners) then begin
        Inc(Count);
        Previous := TPercent(Ship.RangerRelations[RangerIndex]);
        Inc(Total, Previous);
      end;
    end;
  end;
  if Count <> 0 then Result := Total div Count else Result := 50;
end;
{ @end $59E658 }

{ @routine $59E7C4 TRanger_GlobalRelationsPlanets }
function TRanger.GlobalRelationsPlanets(Scope: TObject; Owners: TOwnerSet): Byte;
var I, J, RangerIndex, Total, Count: Integer; Star: TStar; Planet: TPlanet; Previous: Integer;
begin
  RangerIndex := Galaxy.Rangers.IndexOf(Self);
  Total := 0;
  Count := 0;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := Galaxy.Stars[I];
    if Scope is TConstellation then
      if (Scope as TConstellation) <> Star.Constellation then Continue;
    if Scope is TStar then
      if (Scope as TStar) <> Star then Continue;
    for J := 0 to Star.Planets.Count - 1 do begin
      Planet := Star.Planets[J];
      if (Planet.OwnerId in Owners) and Planet.IsCoalitionOwned then begin
        Inc(Count);
        Previous := TPercent(Planet.RangerRelations[RangerIndex]);
        Inc(Total, Previous);
      end;
    end;
  end;
  if Count <> 0 then Result := Total div Count else Result := 50;
end;
{ @end $59E7C4 }

{ @routine $59E8F8 TRanger_AssignWeaponTargetsInStar }
procedure TRanger.AssignWeaponTargetsInStar;
var
  I, J, AssignedCount: Integer;
  Ship: TShip;
  Weapon: TWeapon;
  Asteroid: TAsteroid;
  Distance: Single;
begin
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  AssignedCount := 0;
  if CurrentStar.Battle then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if not ((Ship.OwnerId = oiKling) and Ship.InNormalSpace) then Continue;
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (PointDistanceSquared(Position, Ship.Position) <= Weapon.Range * Weapon.Range)) then Continue;
        Weapon.Target := Ship;
        Inc(AssignedCount);
        if WeaponCount = AssignedCount then Exit;
      end;
    end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
  begin
    for J := 1 to WeaponCount do
    begin
      Weapon := Weapons[J - 1];
      if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
        (PointDistanceSquared(Position, EnemyShip.Position) <= Weapon.Range * Weapon.Range)) then Continue;
      Weapon.Target := EnemyShip;
      Inc(AssignedCount);
      if WeaponCount = AssignedCount then Exit;
    end;
  end;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(CurrentStar.Ships[I]);
    if not Ship.IsOutsideStarSpace and (Ship <> Self) and ((RelationToNonRanger(Ship) < 10) or (Ship = EnemyShip) or (Ship.EnemyShip = Self)) and
      ((Ship.LiberationGroup = nil) or ((Ship.LiberationGroup as TGroup).GroupKind <> 0)) and (TruceShip <> Ship) then
    begin
      { Native can replace an existing weapon target in this pass. }
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        if not ((not Weapon.BrokenFlag) and
          (PointDistanceSquared(Position, Ship.Position) <= Weapon.Range * Weapon.Range)) then Continue;
        Weapon.Target := Ship;
        Inc(AssignedCount);
        if WeaponCount = AssignedCount then Exit;
      end;
    end;
  end;
  if (CargoHook <> nil) and not CargoHook.BrokenFlag and not OrderAbsolute then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do
    begin
      Asteroid := TAsteroid(CurrentStar.Asteroids[I]);
      if Asteroid.MineralCount > CargoFreeSpace then Continue;
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance <= AsteroidTargetRangeSquared then
      begin
        for J := 1 to WeaponCount do
        begin
          Weapon := Weapons[J - 1];
          if not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag and
            (Weapon.Range * Weapon.Range >= Distance) then
          begin
            Weapon.Target := Asteroid;
            Inc(AssignedCount);
            if WeaponCount = AssignedCount then Exit;
            Break;
          end;
        end;
      end;
    end;
end;
{ @end $59E8F8 }

{ @routine $59ECA4 TRanger_SelectEnemyShipInStar }
procedure TRanger.SelectEnemyShipInStar;
var
  I: Integer;
  Ship, PreviousEnemy: TShip;
  Chance, BestChance: Double;
begin
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then Exit;
  if UsableWeaponCount = 0 then Exit;
  if (PartnerShip <> nil) and (PartnerShip.EnemyShip <> nil) and
    ((PartnerShip.EnemyShip = PartnerShip.OrderTarget) or (PartnerShip = PartnerShip.EnemyShip.OrderTarget)) then
  begin
    EnemyShip := PartnerShip.EnemyShip;
    Exit;
  end;
  if (PreferredCareer = rcPirate) and (Player.QuestTargetDefendShip <> nil) and
    (Player.QuestTargetDefendShip.CurrentStar = CurrentStar) and
    (Self <> Player.QuestTargetDefendShip) and Player.QuestTargetDefendShip.InNormalSpace and
    (Player.QuestTargetDefendShip <> TruceShip) and
    (Player.QuestTargetDefendShip.ScriptShip = nil) then
  begin
    EnemyShip := Player.QuestTargetDefendShip;
    AssignWeaponTargetsInStar;
    Exit;
  end;
  PreviousEnemy := EnemyShip;
  EnemyShip := nil;
  BestChance := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := CurrentStar.Ships[I];
    if (Ship = Self) or Ship.IsOutsideStarSpace or (Ship = TruceShip) or (Ship.ScriptShip <> nil) or
      ((Ship.LiberationGroup <> nil) and ((Ship.LiberationGroup as TGroup).GroupKind = 0)) then Continue;
    Chance := ChanceToWin(Ship);
    if Ship.OwnerId = oiKling then
    begin
      if (Chance < BestChance) and (NextRandomUnitFloat(RandomState) > 0.5) then Continue;
    end
    else
    begin
      if (Chance < BestChance) or ((Chance < 0.3) and (StrengthInBestRanger < 0.8)) then Continue;
      if (PreferredCareer = rcPirate) and (GetDesiredCargoFreeSpace <= CargoFreeSpace) and (CargoHook <> nil) then
      begin
        if RelationToNonRanger(Ship) > NextRandomIntRange(0, 30, RandomState) + 60 then Continue;
        if (RelationToNonRanger(Ship) >= 60) and ((Aggression * 0.01 + Chance < 2) or (NextRandomUnitFloat(RandomState) > 0.2)) then Continue;
      end
      else if CurrentStar.Battle or (RelationToNonRanger(Ship) >= 10) then Continue;
      if ((Chance < 1) and not IsTargetStillPursuable(Ship)) or
        ((Ship.ShipType = t_Ranger) and (Chance < 0.9) and (Ship <> Player)) then Continue;
    end;
    EnemyShip := Ship;
    BestChance := Chance;
  end;
  if EnemyShip <> nil then
  begin
    if not IsOutsideExtortionRange(EnemyShip) then Exit;
    if not TryExtortShip(EnemyShip) then
    begin
      AssignWeaponTargetsInStar;
      Exit;
    end;
  end;
  EnemyShip := PreviousEnemy;
end;
{ @end $59ECA4 }

{ @routine $59F06C TRanger_EngageEnemyShip }
procedure TRanger.EngageEnemyShip;
begin
  if Order = soFollowShip then OrderNone;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) then
    if EnemyShip.InNormalSpace then
    begin
      OrderFollowShip(EnemyShip, fmMinWeaponRange, False);
      if ChanceToWin(EnemyShip) < 0.8 then RequestAlliesAttackShip(EnemyShip);
    end
    else if (ChanceToWin(EnemyShip) > 3) and (GetHullIntegrityPercent > 70) and (EnemyShip.GetHullIntegrityPercent > 70) then
    begin
      if EnemyShip.CurrentPlanet <> nil then OrderMove(EnemyShip.CurrentPlanet.GetPosition, False)
      else if EnemyShip.DockedTo <> nil then OrderMove(EnemyShip.DockedTo.Position, False);
    end;
end;
{ @end $59F06C }

{ @routine $59F160 TRanger_ProcessCombatDialogue }
procedure TRanger.ProcessCombatDialogue;
begin
  if (EnemyShip <> nil) and (OrderTarget = EnemyShip) and ((Integer(Seed) + Galaxy.CurrentTurn) mod 4 = 0) and
    not AcceptsRansomDemandFrom(EnemyShip) then TryExtortShip(EnemyShip);
  if (EnemyShip <> nil) and (OrderTarget = EnemyShip) and ((Integer(Seed) + Galaxy.CurrentTurn) mod 6 = 0) and
    (ChanceToWin(EnemyShip) < 1.1) and (GetHullIntegrityPercent > 30) then RequestAlliesAttackShip(EnemyShip);
end;
{ @end $59F160 }

{ @routine $59F21C TRanger_ReactToExtortionDemand }
procedure TRanger.ReactToExtortionDemand(Ranger: TObject);
begin
  if (Ranger = Player) or (NextRandomUnitFloat(RandomState) < 0.05) then
  begin
    ChangeRelationToRanger(Ranger, -15);
    HomePlanet.ChangeRelationToRanger(Ranger, -5);
    (Ranger as TRanger).AddPirateCareerActivity(2);
  end;
end;
{ @end $59F21C }

{ @routine $59F338 TRanger_BuildMoneyExtortionResponse }
function TRanger.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
// @nested $59F288 AcceptMoneyDemand
  procedure AcceptMoneyDemand; // @addr $59F288
  begin
    AddTraderCareerActivity(4);
    OtherShip.SetMoney(OtherShip.Money + DemandedAmount);
    SetMoney(Money - DemandedAmount);
    OtherShip.TruceWithShip(Self);
    if OtherShip = Player then LastPlayerExtortionTurn := Galaxy.CurrentTurn;
    if OtherShip is TRanger then (OtherShip as TRanger).ApplyExtortionReputationPenalty(Self);
  end;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if ((Player <> OtherShip) or PlayerAutomaticControl) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if (Player = Self) and not PlayerAutomaticControl then
  begin
    if OtherShip.ShowPlayerDialogue(1, FormatText1(LookupTalkText('Talk.Money.Send'), HighlightColorTag, '<Money>', IntToStr(DemandedAmount)), DemandedAmount) <> 0 then
    begin
      AcceptMoneyDemand;
      Result := True;
    end;
  end
  else if (OtherShip.TruceShip = Self) or ((Player = OtherShip) and (LastPlayerExtortionTurn + 30 > Galaxy.CurrentTurn)) then Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'LongDistance')
  else if DemandedAmount > RemapClampedAlternate(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scBig), GetWealthScaledAmount(scSmall)) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'SumIsVeryBig')
  else if Money < DemandedAmount then Response := LookupVisibleTalkText('Talk.Money.AnswerNotMoney')
  else begin
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'Ok');
    AcceptMoneyDemand;
    Result := True;
  end;
end;
{ @end $59F338 }

{ @routine $59F96C TRanger_BuildCargoExtortionResponse }
function TRanger.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
// @nested $59F7DC AcceptCargoDemand
  procedure AcceptCargoDemand; // @addr $59F7DC
  var Good: TGoodsIndex; Pass, Count, TotalValue, LowValue, HighValue: Integer; Enough: Boolean; Divisor: Single;
  begin
    AddTraderCareerActivity(4);
    TotalValue := 0;
    Enough := False;
    LowValue := GetWealthScaledAmount(scMini);
    HighValue := GetWealthScaledAmount(scBig);
    for Pass := 1 to 3 do begin
      for Good := t_Food to t_Narcotics do
        if CargoGoods[Good].Count > 0 then begin
          Divisor := RemapClamped(CargoGoods[Good].Count * GoodsMarket[Good].BasePrice, LowValue, HighValue, 2, 8);
          Count := Max(1, Round(CargoGoods[Good].Count / Divisor));
          Inc(TotalValue, Count * GoodsMarket[Good].BasePrice);
          DropGoodsIntoSpace(Good, Count);
          if TotalValue > HighValue then begin Enough := True; Break; end;
        end;
      if Enough then Break;
    end;
    OtherShip.TruceWithShip(Self);
    if OtherShip = Player then LastPlayerExtortionTurn := Galaxy.CurrentTurn;
    OtherShip.OrderMove(Position, True);
    if OtherShip is TRanger then (OtherShip as TRanger).ApplyExtortionReputationPenalty(Self);
  end;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if ((Player <> OtherShip) or PlayerAutomaticControl) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if (Player = Self) and not PlayerAutomaticControl then
  begin
    if OtherShip.ShowPlayerDialogue(2, LookupTalkText('Talk.Goods.Send'), 0) <> 0 then
    begin
      AcceptCargoDemand;
      Result := True;
    end;
  end
  else if (OtherShip.TruceShip = Self) or ((Player = OtherShip) and (LastPlayerExtortionTurn + 30 > Galaxy.CurrentTurn)) then Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'LongDistance')
  else if not HasCargoGoods then Response := LookupVisibleTalkText('Talk.Goods.AnswerNotGoods')
  else begin
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'Ok');
    AcceptCargoDemand;
    Result := True;
  end;
end;
{ @end $59F96C }

{ @routine $59FD00 TRanger_BuildTrucePaymentResponse }
function TRanger.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
  // @nested $59FCB4 AcceptTrucePayment
  procedure AcceptTrucePayment; // @addr $59FCB4
  begin
    OtherShip.SetMoney(OtherShip.Money - OfferedAmount);
    SetMoney(Money + OfferedAmount);
    TruceWithShip(OtherShip);
  end;
begin
  Result := False;
  if OtherShip is TRanger then (OtherShip as TRanger).AddTraderCareerActivity(1);
  if (Player = Self) and not PlayerAutomaticControl then
  begin
    if Cardinal(ReservedMessageCounter) < 7 then Exit;
    if OtherShip.ShowPlayerDialogue(3, FormatText1(LookupTalkText('Talk.Truce.' + OtherShip.GetTypeNameKey + 'Send'),
      HighlightColorTag, '<Money>', IntToStr(OfferedAmount)), 0) <> 0 then
    begin
      AcceptTrucePayment;
      Result := True;
    end;
  end
  else if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact')
  else if RecomputeFearState or ((ChanceToWin(OtherShip) < 1) and (GetHullIntegrityPercent < 40)) or (ChanceToWin(OtherShip) < 0.25) or
    (OfferedAmount > RemapClamped(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scMini), GetWealthScaledAmount(scAverage))) then
  begin
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'Ok');
    AcceptTrucePayment;
    Result := True;
  end
  else Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'No');
end;
{ @end $59FD00 }

{ @routine $5A0150 TRanger_BuildAttackRequestResponse }
function TRanger.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
  // @nested $5A0080 AcceptAttackRequest
  procedure AcceptAttackRequest; // @addr $5A0080
  begin
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Ok');
    SetJointAttackTarget(Requester, Target);
    Result := True;
  end;
begin
  Result := False;
  if Requester is TRanger then
  begin
    if Target.ShipType in [t_Ranger..t_Pirate] then Target.ChangeRelationToRanger(Requester, -20);
    if (Target.OwnerId = oiKling) or (Target.ShipType = t_Pirate) then (Requester as TRanger).AddWarriorCareerActivity(1)
    else (Requester as TRanger).AddPirateCareerActivity(8);
  end;
  if (Player = Self) and not PlayerAutomaticControl then
  begin
    if Requester.ShowPlayerDialogue(4, FormatText1(LookupTalkText('Talk.Attack.' + Requester.GetTypeNameKey + 'Send'),
      HighlightColorTag, '<Target>', Target.GetName), 0) <> 0 then
    begin
      SetJointAttackTarget(Requester, Target);
      Result := True;
    end;
  end
  else if (PartnerShip = Requester) or ((OrderTarget = Target) and (GetRelationLevelToShip(Target) = rlHostile)) then AcceptAttackRequest
  else if TruceShip = Target then Response := FormatText1(LookupVisibleTalkText('Talk.Attack.WeAlreadyHavePact'), HighlightColorTag, '<Target>', Target.GetName)
  else if ((RelationToNonRanger(Target) >= 80) or ((RelationToNonRanger(Target) >= 30) and (PreferredCareer <> rcPirate))) and (PartnerShip <> Requester) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriends')
  else if AcceptsRansomDemandFrom(Target) or InFear then Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Fear')
  else if not TrustsAttackRequester(Requester) then Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Suspect')
  else if HasLockedOrFollowOrder and (PartnerShip <> Requester) then Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'HaveBusiness')
  else AcceptAttackRequest;
end;
{ @end $5A0150 }

{ @routine $5A05E0 TRanger_BuildPartnershipOfferResponse }
function TRanger.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  if RelationToNonRanger(OtherShip) < 45 then Response := LookupVisibleTalkText('Talk.Partner.Suspect')
  else if PartnerShip <> nil then
    Response := FormatText1(LookupVisibleTalkText('Talk.Partner.AlreadyHavePartner'), HighlightColorTag, '<Partner>', (PartnerShip as TRanger).Name)
  else if CountWingmen > 0 then Response := LookupVisibleTalkText('Talk.Partner.ILeader')
  else if (OtherShip is TRanger) and (OtherShip.BaseSkills[skLeadership] <= (OtherShip as TRanger).CountWingmen) then
    Response := LookupVisibleTalkText('Talk.Partner.NeedLeadership')
  else if (OtherShip is TNormalShip) and ((OtherShip as TNormalShip).Rank < Rank) then
    Response := LookupVisibleTalkText('Talk.Partner.YouNeedInMoreRank')
  else if CalculatePartnershipMonths(PaymentAmount, RelationToNonRanger(OtherShip)) = 0 then Response := LookupVisibleTalkText('Talk.Partner.SmallMoney')
  else Result := True;
  Response := FormatText1(Response, HighlightColorTag, '<Ranger>', (OtherShip as TRanger).Name);
end;
{ @end $5A05E0 }

{ @routine $5A0990 TRanger_AcceptPartnershipOffer }
function TRanger.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  if BuildPartnershipOfferResponse(OtherShip, Response, PaymentAmount) then
  begin
    PartnershipDaysRemaining := 30 * CalculatePartnershipMonths(PaymentAmount, RelationToNonRanger(OtherShip));
    Response := FormatText2(LookupVisibleTalkText('Talk.Partner.Ok'), HighlightColorTag,
      '<Month>', IntToStr(CalculatePartnershipMonths(PaymentAmount, RelationToNonRanger(OtherShip))), '<Ranger>', (OtherShip as TRanger).Name);
    PartnerShip := OtherShip;
    Result := True;
    SetMoney(Money + PaymentAmount);
    OtherShip.SetMoney(OtherShip.Money - PaymentAmount);
  end
  else Result := False;
end;
{ @end $5A0990 }

{ @routine $5A0B48 TRanger_TrainSkillsAutomatically }
procedure TRanger.TrainSkillsAutomatically;
begin
  if FreeExperience < 50 then Exit;
  { Each successful attempt recursively trains again before resuming this pass. }
  case PreferredCareer of
    rcTrader: begin
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTrader) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTechnical) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.12) and TrainSkill(skCharm) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skMobility) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.05) and TrainSkill(skMobility) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.05) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and ((Galaxy.AverageRangerCapital * 4 < Wealth) or (BaseSkills[skTrader] > Cardinal(BaseSkills[skLeadership]) + 2)) and TrainSkill(skLeadership) then TrainSkillsAutomatically;
    end;
    rcPirate: begin
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTechnical) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skTechnical) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTrader) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skMobility) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and ((Galaxy.AverageRangerCapital * 2 < Wealth) or (BaseSkills[skTrader] > Cardinal(BaseSkills[skLeadership]) + 2)) and TrainSkill(skLeadership) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skCharm) then TrainSkillsAutomatically;
    end;
    rcWarrior: begin
      if (NextRandomUnitFloat(RandomState) < 0.2) and ((Galaxy.AverageRangerCapital * 2 < Wealth) or (BaseSkills[skTrader] > Cardinal(BaseSkills[skLeadership]) + 2)) and TrainSkill(skLeadership) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skMobility) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skMobility) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skAccuracy) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTechnical) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.2) and TrainSkill(skTrader) then TrainSkillsAutomatically;
      if (NextRandomUnitFloat(RandomState) < 0.15) and TrainSkill(skCharm) then TrainSkillsAutomatically;
    end;
  end;
end;
{ @end $5A0B48 }

{ @routine $5A10D8 TRanger_ProcessQuestTimersAndOutcomes }
procedure TRanger.ProcessQuestTimersAndOutcomes;
var
  I: Integer;
  Quest: PQuest;
  Text: WideString;
begin
  for I := Quests.Count - 1 downto 0 do
  begin
    Quest := PQuest(Quests[I]);
    if Galaxy.CurrentTurn = Quest.DeadlineTurn then
    begin
      if (Quest.QuestType in [qtSendLetter, qtKillShip, qtPlanetQuest]) and not Quest.Successful then
      begin
        if (Quest.QuestType <> qtPlanetQuest) or (CurrentScreenId <> screenPlanetQuest) or
          not (Quest.ObjectiveTarget is TPlanet) or (Player.CurrentPlanet <> (Quest.ObjectiveTarget as TPlanet)) then
        begin
          PublishQuestStatus(Quest, -1);
          Quest.Planet.SetRelationLevelToRanger(Self, rlBad);
          Text := PickLocalizedTextVariant('GalaxyNews.Quest.Failure.Time', Seed * Cardinal(Galaxy.CurrentTurn div 10));
          ReplaceTextToken(Text, '<Quest>', Quest.Description, HighlightColorTag);
          ReplaceTextToken(Text, '<Planet>', Quest.Planet.Name, HighlightColorTag);
          ReplaceTextToken(Text, '<Star>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
          ReplaceTextToken(Text, '<Relation>', Quest.Planet.GetRelationLevelTextToShip(Self), HighlightColorTag);
          AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
          ArchiveQuest(I);
        end;
      end
      else if (Quest.QuestType in [qtDefendSystem, qtDefendShip]) and not Quest.Successful then
      begin
        PublishQuestStatus(Quest, 1);
        Quest.Successful := True;
        RefreshPlayerQuestTargets;
        case Quest.QuestType of
        qtDefendSystem:
        begin
          Text := PickLocalizedTextVariant('GalaxyNews.Quest.Successful.DefSystem', Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn div 10));
          ReplaceTextToken(Text, '<Star>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
        end;
        qtDefendShip:
        begin
          Text := PickLocalizedTextVariant('GalaxyNews.Quest.Successful.DefShip', Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn div 10));
          ReplaceTextToken(Text, '<Ship>', (Quest.ObjectiveTarget as TShip).GetName, HighlightColorTag);
        end;
        end;
        ReplaceTextToken(Text, '<Player>', Player.Name, HighlightColorTag);
        ReplaceTextToken(Text, '<Planet>', Quest.Planet.Name, HighlightColorTag);
        AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
      end;
    end
    else PublishQuestStatus(Quest, 0);
  end;
end;
{ @end $5A10D8 }

{ @routine $5A1544 TRanger_TryTurnInQuests }
procedure TRanger.TryTurnInQuests;
var
  Text: WideString;
begin
  TryTurnInAnyQuest(Text);
end;
{ @end $5A1544 }

{ @routine $5A1580 TRanger_ArchiveQuest }
procedure TRanger.ArchiveQuest(Index: Integer);
var
  OldQuest: PPlayerOldQuest;
  Quest: PQuest;
begin
  Quest := PQuest(Quests[Index]);
  if Player = Self then
  begin
    New(OldQuest);
    OldQuest.QuestType := Quest.QuestType;
    OldQuest.QuestNumber := Quest.QuestNumber;
    OldQuest.Planet := Quest.Planet;
    OldQuest.Description := Quest.Description;
    OldQuest.Successful := Quest.Successful;
    PlayerOldQuests.Add(OldQuest);
  end;
  Quests.Delete(Index);
  Dispose(Quest);
  RefreshPlayerQuestTargets;
end;
{ @end $5A1580 }

{ @routine $5A1608 TRanger_TryTurnInAnyQuest }
function TRanger.TryTurnInAnyQuest(var ResponseText: WideString): Boolean;
var
  I: Integer;
begin
  Result := False;
  ResponseText := '';
  for I := 0 to Quests.Count - 1 do
    if TryTurnInQuest(I, ResponseText) then
    begin
      Result := True;
      Exit;
    end;
end;
{ @end $5A1608 }

{ @routine $5A1A88 TRanger_TryTurnInQuest }
function TRanger.TryTurnInQuest(Index: Integer; var ResponseText: WideString): Boolean;
var
  Quest: PQuest;
  Award: Byte;
  AwardWeight, ExperienceWeight, ArtefactWeight: Single;
  RewardKind, Quantity: Integer;
  AwardEntry: PByte;
  RewardItem: TArtefact;
  RewardText: WideString;
  // @nested $5A1650 ConsumeQuestDeliveryItem
  function ConsumeQuestDeliveryItem: Boolean; // @addr $5A1650 @note "Removes/frees matching delivery cargo; true also when this planet quest requires no item."
  var I: Integer; Item: TItem;
  begin
    for I := 1 to Inventory.Count - 1 do begin
      Item := Inventory[I];
      if Item.ItemType = t_UselessItem then begin
        if ((Quest.QuestType = qtSendLetter) and
          (LocalizedColorText('Quest.SendLetter.' + IntToStr(Quest.QuestNumber) + '.SysName') = (Item as TUselessItem).ConfigBlockName)) or
          ((Quest.QuestType = qtPlanetQuest) and
          (LocalizedColorText('PlanetQuest.ItemForPlanetQuest.' + IntToStr(Quest.QuestNumber)) = (Item as TUselessItem).ConfigBlockName)) then begin
          Inventory.Delete(I);
          Item.Free;
          RefreshDerivedStats;
          Result := True;
          Exit;
        end;
      end;
    end;
    if (Quest.QuestType = qtPlanetQuest) and
      ((LookupLocalizedTextByKey('PlanetQuest.ItemForPlanetQuest.' + IntToStr(Quest.QuestNumber)) = 'None') or
       (LookupLocalizedTextByKey('PlanetQuest.ItemForPlanetQuest.' + IntToStr(Quest.QuestNumber)) = '')) then Result := True else Result := False;
  end;
  // @nested $5A193C FinalizeSuccessfulQuestTurnIn
  procedure FinalizeSuccessfulQuestTurnIn; // @addr $5A193C
  begin
    PublishQuestStatus(Quest, 1);
    if Self = Player then
    begin
      ReplaceTextToken(ResponseText, '<Ranger>', Name, HighlightColorTag);
      ReplaceTextToken(ResponseText, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
    end;
    ArchiveQuest(Index);
    RefreshPlayerQuestTargets;
    CurrentPlanet.ChangeRelationToRanger(Self, Max(0, 70 - (CurrentPlanet.RelationToShip(Self))));
  end;
begin
  Result := False;
  Quest := Quests[Index];
  case Quest.QuestType of
    qtSendLetter:
      if ((Quest.ObjectiveTarget as TPlanet) = CurrentPlanet) and ConsumeQuestDeliveryItem then
      begin
        Result := True;
        Quest.Successful := True;
        SetMoney(Money + Quest.RewardMoney);
        ResponseText := Quest.CompletionText;
        RewardText := LookupLocalizedTextOrEmpty('Quest.SendLetter.' + IntToStr(Quest.QuestNumber) + '.GovernmentAward');
      end;
    qtKillShip:
      if (Quest.Planet = CurrentPlanet) and Quest.Successful then
      begin
        Result := True;
        SetMoney(Money + Quest.RewardMoney);
        ResponseText := Quest.CompletionText;
        RewardText := LookupLocalizedTextOrEmpty('Quest.KillShip.' + IntToStr(Quest.QuestNumber) + '.GovernmentAward');
      end;
    qtPlanetQuest:
      if (Quest.Planet = CurrentPlanet) and (Quest.Successful or ConsumeQuestDeliveryItem) then
      begin
        Result := True;
        { Does not set Quest.Successful here, even after consuming the item. }
        SetMoney(Money + Quest.RewardMoney);
        ResponseText := Quest.CompletionText;
        RewardText := 'Reward,Points,Artefact';
        if CurrentPlanet.RaceId = raPeleng then RewardText := '';
      end;
    qtDefendSystem:
      if (Quest.Planet = CurrentPlanet) and Quest.Successful then
      begin
        Result := True;
        SetMoney(Money + Quest.RewardMoney);
        ResponseText := Quest.CompletionText;
        RewardText := LookupLocalizedTextOrEmpty('Quest.DefSystem.' + IntToStr(Quest.QuestNumber) + '.GovernmentAward');
      end;
    qtDefendShip:
      if (Quest.Planet = CurrentPlanet) and Quest.Successful then
      begin
        Result := True;
        SetMoney(Money + Quest.RewardMoney);
        ResponseText := Quest.CompletionText;
        RewardText := LookupLocalizedTextOrEmpty('Quest.DefShip.' + IntToStr(Quest.QuestNumber) + '.GovernmentAward');
      end;
  end;
  if not Result then Exit;
  AwardWeight := FindTextPosW('Reward', RewardText);
  ExperienceWeight := FindTextPosW('Points', RewardText);
  ArtefactWeight := FindTextPosW('Artefact', RewardText);
  if AwardWeight > 0 then
    if AwardIds = nil then AwardWeight := 80
    else AwardWeight := RemapClampedAlternate(AwardIds.Count, 0, 15, 80, 10);
  if ExperienceWeight > 0 then ExperienceWeight := RemapClamped(PlaceInRating, 1, Galaxy.Rangers.Count, 5, 80);
  if ArtefactWeight > 0 then ArtefactWeight := RemapClampedAlternate(Artefacts.Count, 0, 10, 80, 10);
  if (AwardWeight = 0) and (ExperienceWeight = 0) and (ArtefactWeight = 0) then
  begin
    FinalizeSuccessfulQuestTurnIn;
    Exit;
  end;
  if AwardWeight > 0 then AwardWeight := AwardWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 33 + 667);
  if ExperienceWeight > 0 then ExperienceWeight := ExperienceWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 41 + 767);
  if ArtefactWeight > 0 then ArtefactWeight := ArtefactWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 57 + 967);
  { Strict comparisons: a tie between the greatest weights gives no extra reward. }
  if (AwardWeight > 0) and (AwardWeight > Max(ExperienceWeight, ArtefactWeight)) then RewardKind := 1
  else if (ExperienceWeight > 0) and (ExperienceWeight > Max(AwardWeight, ArtefactWeight)) then RewardKind := 2
  else if (ArtefactWeight > 0) and (ArtefactWeight > Max(AwardWeight, ExperienceWeight)) then RewardKind := 3
  else
  begin
    FinalizeSuccessfulQuestTurnIn;
    Exit;
  end;
  case RewardKind of
    1: begin
      Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment, atForSecretMission]);
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      GetMem(AwardEntry, 1);
      AwardIds.Add(AwardEntry);
      AwardEntry^ := Award;
      if Player = Self then
      begin
        ResponseText := ResponseText + #13#10 + LocalizedColorText('PlanetCongratulations.Quest.AddReward');
        ReplaceTextToken(ResponseText, '<Reward>', GetAwardInfo(Award).Name, HighlightColorTag);
      end
      else ResponseText := '';
    end;
    2: begin
      Quantity := SeededRandomIntRange(25, 70, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div 100);
      GainExperience(Quantity);
      if Player = Self then
      begin
        ResponseText := ResponseText + #13#10 + LocalizedColorText('PlanetCongratulations.Quest.AddPoints');
        ReplaceTextToken(ResponseText, '<Points>', IntToStr(Quantity), HighlightColorTag);
      end
      else ResponseText := '';
    end;
    3: begin
      RewardItem := CreateRandomArtefact((Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div 100 + 767, CurrentPlanet.OwnerId) as TArtefact;
      if RewardItem is TArtefactTranclucator then ((RewardItem as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Self;
      { Native adds to the player's list even when another ranger turns in the quest. }
      Player.Artefacts.Add(RewardItem);
      if Player = Self then
      begin
        ResponseText := ResponseText + #13#10 + LocalizedColorText('PlanetCongratulations.Quest.AddArtefact') + #13#10 + RewardItem.GetDescriptionText;
        ReplaceTextToken(ResponseText, '<Artefact>', RewardItem.GetDisplayName, HighlightColorTag);
      end
      else ResponseText := '';
    end;
  end;
  if Player = Self then
  begin
    ReplaceTextToken(ResponseText, '<Star>', CurrentPlanet.CurrentStar.Name, HighlightColorTag);
    ReplaceTextToken(ResponseText, '<Planet>', CurrentPlanet.Name, HighlightColorTag);
  end;
  FinalizeSuccessfulQuestTurnIn;
end;
{ @end $5A1A88 }

{ @routine $5A26A0 TRanger_GenerateQuestOffer }
function TRanger.GenerateQuestOffer(var Quest: TQuest; var ResponseText: WideString): Boolean;
var
  I, J, K, Attempts, Interval, QuestNumber, MaximumQuest: Integer;
  Star: TStar;
  Planet: TPlanet;
  Target, DefendedShip: TShip;
  TextQuest: TQuestGameContent;
  Found: Boolean;
  ShipTypes: WideString;
begin
  Result := False;
  ResponseText := '';
  for I := 0 to Quests.Count - 1 do begin
    if PQuest(Quests[I]).Planet = CurrentPlanet then begin
      ResponseText := LocalizedColorText('FormGov.DontQuest.YouHaveQuest');
      Exit;
    end;
  end;
  if CurrentPlanet.GetRelationLevelToShip(Self) < rlGood then begin
    ResponseText := LocalizedColorText('FormGov.DontQuest.Distrust');
    Exit;
  end;
  if CurrentPlanet.CurrentStar.Battle then begin
    ResponseText := LocalizedColorText('FormGov.DontQuest.KlingInSystem');
    Exit;
  end;
  Interval := 10;
  if FractionalQuotient(CurrentPlanet.GenerationSeed, Galaxy.CurrentTurn + 100) < 1.5 then
  begin
    if not HasQuestOfType(qtSendLetter) then
      if FractionalQuotient(CurrentPlanet.GenerationSeed, (Galaxy.CurrentTurn + 111) div Interval) < PlanetGovernmentMarket[CurrentPlanet.Government].QuestOfferProbabilities[qtSendLetter] then begin
        Attempts := 0;
        repeat
          Inc(Attempts);
          I := SeededRandomIntRange((Galaxy).Stars.Count div 6, Galaxy.Stars.Count div 3, (Attempts + Galaxy.CurrentTurn) div Interval);
          Star := CurrentStar.StarDistances[I].Star as TStar;
          if Star.ShipTypeCounts[t_Kling] <= 0 then
            for J := 0 to Star.Planets.Count - 1 do begin
              Planet := Star.Planets[J];
              if Planet.IsCoalitionOwned and Planet.CurrentStar.Constellation.Visible then begin
                MaximumQuest := StrToInt(AnsiString(LanguageDataConfig.GetParamByPath('Quest.SendLetter.Count'))) - 1;
                QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval);
                Found := False;
                for K := 0 to MaximumQuest do begin
                  if MatchesOwnerName(CurrentPlanet.OwnerId, LookupLocalizedTextByKey('Quest.SendLetter.' + IntToStr(QuestNumber) + '.FromRace')) and
                    MatchesOwnerName(Planet.OwnerId, LookupLocalizedTextByKey('Quest.SendLetter.' + IntToStr(QuestNumber) + '.ToRace')) and
                    not Galaxy.HasPlayerQuestHistory(qtSendLetter, QuestNumber) and
                    MatchesCareerName(GetDominantCareer, LookupLocalizedTextByKey('Quest.SendLetter.' + IntToStr(QuestNumber) + '.Status')) then begin
                    Found := True;
                    Break;
                  end;
                  QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval + 37 * K);
                end;
                if not Found then Continue;
                Quest.QuestType := qtSendLetter;
                Quest.Planet := CurrentPlanet;
                Quest.Successful := False;
                Quest.DeadlineTurn := QuestTuning[Quest.QuestType].BaseDuration + 15 * (CurrentStar.StarDistances[I].Distance div 20 + 1);
                Quest.DeadlineTurn := Galaxy.CurrentTurn + Round(Quest.DeadlineTurn / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
                Quest.RewardMoney := QuestTuning[Quest.QuestType].BaseRewardMoney + Round(QuestTuning[Quest.QuestType].RewardCapitalPercent * Min(Galaxy.AverageRangerCapital * 0.01, Player.Wealth * 0.01));
                Quest.RewardMoney := Round(Quest.RewardMoney * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor);
                Quest.ObjectiveTarget := Planet;
                Quest.QuestNumber := QuestNumber;
                Quest.CompletionText := LocalizedColorText('Quest.SendLetter.' + IntToStr(QuestNumber) + '.Status');
                RefreshPlayerQuestTargets;
                Result := True;
                Exit;
              end;
            end;
        until Attempts > 20;
      end;
    if not HasQuestOfType(qtKillShip) and (Galaxy.CurrentTurn > 565) then
      if FractionalQuotient(CurrentPlanet.GenerationSeed, (Galaxy.CurrentTurn + 222) div Interval) < PlanetGovernmentMarket[CurrentPlanet.Government].QuestOfferProbabilities[qtKillShip] then
        for I := Min(20, Galaxy.Stars.Count - 1) downto 1 do begin
          Star := CurrentStar.StarDistances[I].Star as TStar;
          if Star.Constellation.Visible then
            for J := 0 to Star.Ships.Count - 1 do begin
              Target := Star.Ships[J];
              if (Target.ShipType in [t_Ranger..t_Pirate]) and (Target <> Self) and (Target.ScriptShip = nil) then
                if Target.Hull.HullPoints >= Target.Hull.Weight / 1.5 then begin
                  case Target.ShipType of
                    t_Ranger: begin
                      if (CurrentPlanet.GetRelationLevelToShip(Target) > rlBad) then Continue;
                    end;
                    t_Transport: begin
                      case (Target as TTransport).TransportType of
                        ttTransport: if (CurrentPlanet.GetRelationLevelToShip(Target) > rlNormal) and (Target.GetTurnSeedFraction(10) < 0.99) then Continue;
                        ttLiner: if (CurrentPlanet.GetRelationLevelToShip(Target) > rlNormal) and (Target.GetTurnSeedFraction(10) < 0.99) then Continue;
                        ttDiplomat: if (CurrentPlanet.GetRelationLevelToShip(Target) > rlNormal) and (Target.GetTurnSeedFraction(10) < 0.99) then Continue;
                      end;
                    end;
                    t_Pirate: begin
                      if ((CurrentPlanet.GetRelationLevelToShip(Target) > rlNormal) and (Target.GetTurnSeedFraction(10) < 0.99)) then Continue;
                    end;
                  end;
                  MaximumQuest := StrToInt(AnsiString(LanguageDataConfig.GetParamByPath('Quest.KillShip.Count'))) - 1;
                  QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval);
                  Found := False;
                  for K := 0 to MaximumQuest do begin
                    if MatchesOwnerName(CurrentPlanet.OwnerId, LookupLocalizedTextByKey('Quest.KillShip.' + IntToStr(QuestNumber) + '.PlanetRace')) and
                      MatchesOwnerName(Target.OwnerId, LookupLocalizedTextByKey('Quest.KillShip.' + IntToStr(QuestNumber) + '.ShipRace')) and
                      not Galaxy.HasPlayerQuestHistory(qtKillShip, QuestNumber) and
                      MatchesCareerName(GetDominantCareer, LookupLocalizedTextByKey('Quest.KillShip.' + IntToStr(QuestNumber) + '.Status')) then begin
                      ShipTypes := LookupLocalizedTextByKey('Quest.KillShip.' + IntToStr(QuestNumber) + '.ShipType');
                      case Target.ShipType of
                        t_Ranger: begin
                          if ShipTypes = 'Ranger' then Found := True;
                        end;
                        t_Transport: begin
                          case (Target as TTransport).TransportType of
                            ttTransport: if ShipTypes = 'Transport' then Found := True;
                            ttLiner: if ShipTypes = 'Liner' then Found := True;
                            ttDiplomat: if ShipTypes = 'Diplomat' then Found := True;
                          end;
                        end;
                        t_Pirate: begin
                          if ShipTypes = 'Pirate' then Found := True;
                        end;
                      end;
                      if ShipTypes = 'Any' then Found := True;
                      if Found then Break;
                    end;
                    QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval + 47 * K);
                  end;
                  if not Found then Continue;
                  Quest.QuestType := qtKillShip;
                  Quest.Planet := CurrentPlanet;
                  Quest.Successful := False;
                  Quest.DeadlineTurn := QuestTuning[Quest.QuestType].BaseDuration + Round(RemapClamped(Target.Wealth, Player.Wealth div 2, 2 * Player.Wealth, 0, 30) + PointDistance(CurrentStar.Position, Target.CurrentStar.Position));
                  Quest.DeadlineTurn := Galaxy.CurrentTurn + Round(Quest.DeadlineTurn / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
                  Quest.RewardMoney := QuestTuning[Quest.QuestType].BaseRewardMoney + Round((QuestTuning[Quest.QuestType].RewardCapitalPercent * Min(Galaxy.AverageRangerCapital * 0.01, Player.Wealth * 0.01)) * RemapClamped(Target.Wealth, Player.Wealth div 2, 2 * Player.Wealth, 0.8, 1.2));
                  Quest.RewardMoney := Round(Quest.RewardMoney * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor);
                  Quest.ObjectiveTarget := Target;
                  Quest.QuestNumber := QuestNumber;
                  Result := True;
                  RefreshPlayerQuestTargets;
                  Exit;
                end;
            end;
        end;
    if not HasQuestOfType(qtPlanetQuest) then
      if FractionalQuotient(CurrentPlanet.GenerationSeed, (Galaxy.CurrentTurn + 333) div Interval) < PlanetGovernmentMarket[CurrentPlanet.Government].QuestOfferProbabilities[qtPlanetQuest] + 1 then
        for I := 10 to Galaxy.Stars.Count - 1 do begin
          Star := CurrentStar.StarDistances[I].Star as TStar;
          if (Star.ShipTypeCounts[t_Kling] <= 0) and Star.Constellation.Visible then
            for J := 0 to Star.Planets.Count - 1 do begin
              Planet := Star.Planets[J];
              if (Planet.OwnerId <> oiKling) and (Planet.TextQuestId <> -1) and
                (LanguageDataConfig.GetBlockByPath('PlanetQuest.PlanetQuest').CountParams(IntToStr(Planet.TextQuestId)) > 0) then begin
                TextQuest := TQuestGameContent.Create;
                TextQuest.LoadQuest(Planet.TextQuestId);
                if (
                  (((CurrentPlanet.RaceId = raMaloc) and (0 in TextQuest.IssuerRaceMask)) or
                  ((CurrentPlanet.RaceId = raPeleng) and (1 in TextQuest.IssuerRaceMask)) or
                  ((CurrentPlanet.RaceId = raPeople) and (2 in TextQuest.IssuerRaceMask)) or
                  ((CurrentPlanet.RaceId = raFei) and (3 in TextQuest.IssuerRaceMask)) or
                  ((CurrentPlanet.RaceId = raGaal) and (4 in TextQuest.IssuerRaceMask))) and
                  (((Planet.OwnerId = oiNone) and (6 in TextQuest.TargetOwnerMask)) or
                  ((0 in TextQuest.TargetOwnerMask) and (Planet.OwnerId = oiMaloc)) or
                  ((1 in TextQuest.TargetOwnerMask) and (Planet.OwnerId = oiPeleng)) or
                  ((2 in TextQuest.TargetOwnerMask) and (Planet.OwnerId = oiPeople)) or
                  ((3 in TextQuest.TargetOwnerMask) and (Planet.OwnerId = oiFei)) or
                  ((4 in TextQuest.TargetOwnerMask) and (Planet.OwnerId = oiGaal)) or ((TextQuest.TargetOwnerMask = []) and (CurrentPlanet.OwnerId = Planet.OwnerId))) and
                  not Galaxy.HasPlayerQuestHistory(qtPlanetQuest, Planet.TextQuestId) and
                  (((0 in TextQuest.PlayerCareerMask) and (GetDominantCareer = rcTrader)) or
                  ((1 in TextQuest.PlayerCareerMask) and (GetDominantCareer = rcPirate)) or
                  ((2 in TextQuest.PlayerCareerMask) and (GetDominantCareer = rcWarrior))) and
                  (((0 in TextQuest.PlayerRaceMask) and (OwnerId = oiMaloc)) or
                  ((1 in TextQuest.PlayerRaceMask) and (OwnerId = oiPeleng)) or
                  ((2 in TextQuest.PlayerRaceMask) and (OwnerId = oiPeople)) or
                  ((3 in TextQuest.PlayerRaceMask) and (OwnerId = oiFei)) or
                  ((4 in TextQuest.PlayerRaceMask) and (OwnerId = oiGaal)) or ((TextQuest.PlayerRaceMask = []) and (CurrentPlanet.OwnerId = Player.OwnerId))) and
                  ((TextQuest.Difficulty < 90) or (Galaxy.Difficulty > dfNormal))) then begin
                  Quest.QuestType := qtPlanetQuest;
                  Quest.Planet := CurrentPlanet;
                  Quest.Successful := False;
                  Quest.DeadlineTurn := 15 * (CurrentStar.StarDistances[I].Distance div 20 + 1);
                  if not TextQuest.CompleteOnFinish then Quest.DeadlineTurn := Quest.DeadlineTurn * 2;
                  Quest.DeadlineTurn := Quest.DeadlineTurn + QuestTuning[Quest.QuestType].BaseDuration;
                  Quest.DeadlineTurn := Galaxy.CurrentTurn + Round(Quest.DeadlineTurn / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
                  Quest.RewardMoney := QuestTuning[Quest.QuestType].BaseRewardMoney + Round((QuestTuning[Quest.QuestType].RewardCapitalPercent * Min(Galaxy.AverageRangerCapital * 0.01, Player.Wealth * 0.01)) * RemapClamped(TextQuest.Difficulty, 50, 100, 1, 2.1));
                  Quest.RewardMoney := Round(Quest.RewardMoney * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor);
                  Quest.ObjectiveTarget := Planet;
                  Quest.QuestNumber := Planet.TextQuestId;
                  Result := True;
                  RefreshPlayerQuestTargets;
                  TextQuest.Free;
                  Exit;
                end;
                TextQuest.Free;
              end;
            end;
        end;
    if not HasQuestOfType(qtDefendSystem) and (CurrentStar.ShipTypeCounts[t_Kling] = 0) then
      if FractionalQuotient(CurrentPlanet.GenerationSeed, (Galaxy.CurrentTurn + 444) div Interval) < PlanetGovernmentMarket[CurrentPlanet.Government].QuestOfferProbabilities[qtDefendSystem] then
        for I := 0 to CurrentStar.Ships.Count - 1 do begin
          if (Self).CurrentStar.ShipTypeCounts[t_Pirate] < 2 then Break;
          Target := CurrentStar.Ships[I];
          if (CurrentStar.ShipTypeCounts[t_Pirate] >= 3) or ((Target.ShipType = t_Pirate) and (Target.OrderTarget is TTransport)) then begin
            MaximumQuest := StrToInt(AnsiString(LanguageDataConfig.GetParamByPath('Quest.DefSystem.Count'))) - 1;
            QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval);
            Found := False;
            for K := 0 to MaximumQuest do begin
              if MatchesOwnerName(CurrentPlanet.OwnerId, LookupLocalizedTextByKey('Quest.DefSystem.' + IntToStr(QuestNumber) + '.PlanetRace')) and
                not Galaxy.HasPlayerQuestHistory(qtDefendSystem, QuestNumber) and
                MatchesCareerName(GetDominantCareer, LookupLocalizedTextByKey('Quest.DefSystem.' + IntToStr(QuestNumber) + '.Status')) then begin
                Found := True;
                Break;
              end;
              QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval + 57 * K);
            end;
            if not Found then Continue;
            Quest.QuestType := qtDefendSystem;
            Quest.Planet := CurrentPlanet;
            Quest.Successful := False;
            Quest.DeadlineTurn := QuestTuning[Quest.QuestType].BaseDuration + SeededRandomIntRange(-10, 10, CurrentPlanet.GenerationSeed);
            Quest.DeadlineTurn := Galaxy.CurrentTurn + Round(Quest.DeadlineTurn * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
            Quest.RewardMoney := QuestTuning[Quest.QuestType].BaseRewardMoney + Round(QuestTuning[Quest.QuestType].RewardCapitalPercent * Min(Galaxy.AverageRangerCapital * 0.01, Player.Wealth * 0.01));
            Quest.RewardMoney := Round(Quest.RewardMoney * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor);
            Quest.ObjectiveTarget := CurrentPlanet;
            Quest.QuestNumber := QuestNumber;
            Result := True;
            RefreshPlayerQuestTargets;
            Exit;
          end;
        end;
    if not HasQuestOfType(qtDefendShip) then
      if FractionalQuotient(CurrentPlanet.GenerationSeed, (Galaxy.CurrentTurn + 555) div Interval) < PlanetGovernmentMarket[CurrentPlanet.Government].QuestOfferProbabilities[qtDefendShip] then
        for I := 0 to Min(20, Galaxy.Stars.Count - 1) do begin
          Star := CurrentStar.StarDistances[I].Star as TStar;
          if (Star.ShipTypeCounts[t_Kling] <= 0) and (Star.ShipTypeCounts[t_Pirate] >= 2) then
            for J := 0 to Star.Ships.Count - 1 do begin
              Target := Star.Ships[J];
              if Player <> Target then begin
                DefendedShip := Target;
                if Target.EnemyShip <> nil then
                  if (Target.EnemyShip.OrderTarget = Target) and
                    ((CurrentPlanet = DefendedShip.HomePlanet) and (CurrentPlanet.OwnerId = DefendedShip.OwnerId) and
                    (CurrentPlanet.GetRelationLevelToShip(DefendedShip) >= rlGood)) and (DefendedShip <> Self) and
                    (DefendedShip.Order <> soJump) and (DefendedShip.ScriptShip = nil) then
                    if DefendedShip.Hull.HullPoints >= DefendedShip.Hull.Weight * 0.9 then begin
                      MaximumQuest := StrToInt(AnsiString(LanguageDataConfig.GetParamByPath('Quest.DefShip.Count'))) - 1;
                      QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval);
                      Found := False;
                      for K := 0 to MaximumQuest do begin
                        if MatchesOwnerName(CurrentPlanet.OwnerId, LookupLocalizedTextByKey('Quest.DefShip.' + IntToStr(QuestNumber) + '.PlanetRace')) and
                          not Galaxy.HasPlayerQuestHistory(qtDefendShip, QuestNumber) and
                          MatchesCareerName(GetDominantCareer, LookupLocalizedTextByKey('Quest.DefShip.' + IntToStr(QuestNumber) + '.Status')) then
                          if ((I = 0) and (LookupLocalizedTextByKey('Quest.DefShip.' + IntToStr(QuestNumber) + '.InThisSystem') = 'Yes')) or
                            ((I > 0) and (LookupLocalizedTextByKey('Quest.DefShip.' + IntToStr(QuestNumber) + '.InThisSystem') = 'No')) then begin
                            ShipTypes := LookupLocalizedTextByKey('Quest.DefShip.' + IntToStr(QuestNumber) + '.ShipType');
                            case DefendedShip.ShipType of
                              t_Ranger: begin
                                if ShipTypes = 'Ranger' then Found := True;
                              end;
                              t_Transport: begin
                                case (DefendedShip as TTransport).TransportType of
                                  ttTransport: if ShipTypes = 'Transport' then Found := True;
                                  ttLiner: if ShipTypes = 'Liner' then Found := True;
                                  ttDiplomat: if ShipTypes = 'Diplomat' then Found := True;
                                end;
                              end;
                              t_Pirate: begin
                                if ShipTypes = 'Pirate' then Found := True;
                              end;
                            end;
                            if ShipTypes = 'Any' then Found := True;
                            if Found then Break;
                          end;
                        QuestNumber := SeededRandomIntRange(0, MaximumQuest, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div Interval + 67 * K);
                      end;
                      if not Found then Continue;
                      Quest.QuestType := qtDefendShip;
                      Quest.Planet := CurrentPlanet;
                      Quest.Successful := False;
                      Quest.DeadlineTurn := QuestTuning[Quest.QuestType].BaseDuration + SeededRandomIntRange(-10, 10, CurrentPlanet.GenerationSeed);
                      Quest.DeadlineTurn := Galaxy.CurrentTurn + Round(Quest.DeadlineTurn * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
                      Quest.RewardMoney := QuestTuning[Quest.QuestType].BaseRewardMoney + Round(QuestTuning[Quest.QuestType].RewardCapitalPercent * Min(Galaxy.AverageRangerCapital * 0.01, Player.Wealth * 0.01));
                      Quest.RewardMoney := Round(Quest.RewardMoney * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor);
                      Quest.ObjectiveTarget := DefendedShip;
                      Quest.QuestNumber := QuestNumber;
                      Result := True;
                      RefreshPlayerQuestTargets;
                      Exit;
                    end;
              end;
            end;
        end;
  end;
  ResponseText := LocalizedColorText('FormGov.DontQuest.WeDontHaveQuest');
end;
{ @end $5A26A0 }

{ @routine $5A4828 TRanger_BuildQuestText }
function TRanger.BuildQuestText(Quest: TQuest; Completion: Boolean): WideString;
const FullNameSeparator = WideString(' ');
var Text, Suffix: WideString; TextQuest: TQuestGameContent;
begin
  case Quest.QuestType of
    qtSendLetter: begin
      if Completion then Suffix := '.End'
      else Suffix := '.Start';
      Text := LocalizedColorText('Quest.SendLetter.' + IntToStr(Quest.QuestNumber) + Suffix);
      ReplaceTextToken(Text, '<ToPlanet>', (Quest.ObjectiveTarget as TPlanet).Name, HighlightColorTag);
      ReplaceTextToken(Text, '<ToStar>', (Quest.ObjectiveTarget as TPlanet).CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<Parsec>', IntToStr(Round(PointDistance((Quest.ObjectiveTarget as TPlanet).CurrentStar.Position, CurrentPlanet.CurrentStar.Position))), HighlightColorTag);
      ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Quest.DeadlineTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
      ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
      Result := Text;
    end;
    qtKillShip: begin
      if Completion then Suffix := '.End'
      else Suffix := '.Start';
      Text := LocalizedColorText('Quest.KillShip.' + IntToStr(Quest.QuestNumber) + Suffix);
      ReplaceTextToken(Text, '<InStar>', (Quest.ObjectiveTarget as TShip).CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Quest.DeadlineTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
      ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<Ship>', (Quest.ObjectiveTarget as TShip).GetName, HighlightColorTag);
      ReplaceTextToken(Text, '<FullShip>', (Quest.ObjectiveTarget as TShip).GetFullName(FullNameSeparator), HighlightColorTag);
      Result := Text;
    end;
    qtPlanetQuest: begin
      TextQuest := TQuestGameContent.Create;
      TextQuest.LoadQuest(Quest.QuestNumber);
      if Completion then Text := TextQuest.QuestSuccessGovMessageText.Text
      else Text := TextQuest.QuestDescriptionText.Text;
      ReplaceTextToken(Text, '<Ranger>', Player.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<ToPlanet>', (Quest.ObjectiveTarget as TPlanet).Name, HighlightColorTag);
      ReplaceTextToken(Text, '<ToStar>', (Quest.ObjectiveTarget as TPlanet).CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<Parsec>', IntToStr(Round(PointDistance(Quest.Planet.CurrentStar.Position, (Quest.ObjectiveTarget as TPlanet).CurrentStar.Position))), HighlightColorTag);
      ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Quest.DeadlineTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
      ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
      ExpandLocalizedTextMarkup(Text);
      TextQuest.Free;
      Result := Text;
    end;
    qtDefendSystem: begin
      if Completion then Suffix := '.End'
      else Suffix := '.Start';
      Text := LocalizedColorText('Quest.DefSystem.' + IntToStr(Quest.QuestNumber) + Suffix);
      ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Quest.DeadlineTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
      ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
      Result := Text;
    end;
    qtDefendShip: begin
      if Completion then Suffix := '.End'
      else Suffix := '.Start';
      Text := LocalizedColorText('Quest.DefShip.' + IntToStr(Quest.QuestNumber) + Suffix);
      ReplaceTextToken(Text, '<Date>', Galaxy.FormatTurnDate(Quest.DeadlineTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn), HighlightColorTag);
      ReplaceTextToken(Text, '<Money>', IntToStr(Quest.RewardMoney), HighlightColorTag);
      ReplaceTextToken(Text, '<FromPlanet>', Quest.Planet.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<FromStar>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<InStar>', (Quest.ObjectiveTarget as TShip).CurrentStar.Name, HighlightColorTag);
      ReplaceTextToken(Text, '<Ship>', (Quest.ObjectiveTarget as TShip).GetName, HighlightColorTag);
      ReplaceTextToken(Text, '<FullShip>', (Quest.ObjectiveTarget as TShip).GetFullName(FullNameSeparator), HighlightColorTag);
      Result := Text;
    end;
  end;
end;
{ @end $5A4828 }

{ @routine $5A54C8 TRanger_PublishQuestStatus }
procedure TRanger.PublishQuestStatus(Quest: PQuest; Outcome: Integer);
var Text: WideString;
begin
  Text := '';
  if Outcome = 0 then begin
    if Quest.Successful then
      Text := Text + WrapTextInColor(LocalizedColorText('Quest.Info.CurQuests.Accepted'), HighlightColorTag) + #13#10
    else begin
      Text := Text + WrapTextInColor(LocalizedColorText('Quest.Info.CurQuests.NotAccepted'), HighlightColorTag) + #13#10;
      Text := Text + FormatText1(LocalizedColorText('Quest.Info.CountDay'), HighlightColorTag, '<Day>', IntToStr(Quest.DeadlineTurn - Galaxy.CurrentTurn)) + #13#10;
    end;
  end
  else if Outcome > 0 then
    Text := Text + WrapTextInColor(LocalizedColorText('Quest.Info.OldQuests.Accepted'), GreenColorTag) + #13#10
  else Text := Text + WrapTextInColor(LocalizedColorText('Quest.Info.OldQuests.NotAccepted'), RedColorTag) + #13#10;
  Text := Text + FormatText2(LocalizedColorText('Quest.Info.FromPlanet'), HighlightColorTag, '<Planet>', Quest.Planet.Name,
    '<System>', Quest.Planet.CurrentStar.Name) + #13#10;
  Text := Text + #13#10 + ' ' + #13#10 + Quest.Description;
  if Outcome = 0 then
    AddOrUpdatePlayerBubble(pmQuestNormal, Galaxy.CurrentTurn, Text, 'ZP_' + IntToStr(Cardinal(Quest.Planet.Id)) + '_' + IntToStr(Quest.QuestNumber))
  else if Outcome > 0 then
    AddOrUpdatePlayerBubble(pmQuestOk, Galaxy.CurrentTurn, Text, 'ZP_' + IntToStr(Cardinal(Quest.Planet.Id)) + '_' + IntToStr(Quest.QuestNumber))
  else AddOrUpdatePlayerBubble(pmQuestCancel, Galaxy.CurrentTurn, Text, 'ZP_' + IntToStr(Cardinal(Quest.Planet.Id)) + '_' + IntToStr(Quest.QuestNumber));
end;
{ @end $5A54C8 }

{ @routine $5A5AA4 TRanger_ProcessShipDestructionQuests }
procedure TRanger.ProcessShipDestructionQuests(Ship: TShip);
const FullNameSeparator = WideString(' ');
var
  I, J: Integer;
  Ranger: TRanger;
  Quest: PQuest;
  Text: WideString;
begin
  for I := 0 to Galaxy.Rangers.Count - 1 do
  begin
    Ranger := TRanger(Galaxy.Rangers[I]);
    for J := Ranger.Quests.Count - 1 downto 0 do
    begin
      Quest := PQuest(Ranger.Quests[J]);
      if (Ship is TTransport) and not Quest.Successful and
        (Quest.QuestType = qtDefendSystem) and (Ship.CurrentStar = Quest.Planet.CurrentStar) then
      begin
          Quest.Planet.SetRelationLevelToRanger(Ranger, rlBad);
          if Player = Ranger then
          begin
            Text := PickLocalizedTextVariant('GalaxyNews.Quest.Failure.DeadShipInDefSystem', Seed * Cardinal(Galaxy.CurrentTurn div 10));
            ReplaceTextToken(Text, '<Ship>', Ship.GetFullName(FullNameSeparator), HighlightColorTag);
            ReplaceTextToken(Text, '<Planet>', Quest.Planet.Name, HighlightColorTag);
            ReplaceTextToken(Text, '<Star>', Quest.Planet.CurrentStar.Name, HighlightColorTag);
            ReplaceTextToken(Text, '<Relation>', Quest.Planet.GetRelationLevelTextToShip(Ranger), HighlightColorTag);
            AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
          end;
        { The original calls these on Self, even while iterating another ranger's quests. }
        PublishQuestStatus(Quest, -1);
        ArchiveQuest(J);
      end;
      { Native continues reading Quest after archiving it. }
      if (Ship.ShipType in [t_Ranger..t_Pirate]) and (Quest.QuestType = qtDefendShip) and (Ship = Quest.ObjectiveTarget) then
      begin
        begin
          Quest.Planet.SetRelationLevelToRanger(Ranger, rlBad);
          if Player = Ranger then
          begin
            Text := PickLocalizedTextVariant('GalaxyNews.Quest.Failure.DeadDefShip', Seed * Cardinal(Galaxy.CurrentTurn div 10));
            ReplaceTextToken(Text, '<Ship>', Ship.GetFullName(FullNameSeparator), HighlightColorTag);
            ReplaceTextToken(Text, '<Planet>', Quest.Planet.Name, HighlightColorTag);
            ReplaceTextToken(Text, '<Star>', Ship.CurrentStar.Name, HighlightColorTag);
            ReplaceTextToken(Text, '<Relation>', Quest.Planet.GetRelationLevelTextToShip(Ranger), HighlightColorTag);
            AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
          end;
          PublishQuestStatus(Quest, -1);
          ArchiveQuest(J);
        end;
      end;
    end;
    for J := 0 to Ranger.Quests.Count - 1 do
    begin
      Quest := PQuest(Ranger.Quests[J]);
      if not Quest.Successful and (Quest.QuestType = qtKillShip) and (Ship = Quest.ObjectiveTarget) then
      begin
        if Player = Ranger then
        begin
          Text := PickLocalizedTextVariant('GalaxyNews.Quest.Successful.KillShip', Galaxy.GenerationSeed * Cardinal(Galaxy.CurrentTurn div 10));
          ReplaceTextToken(Text, '<Ship>', Ship.GetFullName(FullNameSeparator), HighlightColorTag);
          ReplaceTextToken(Text, '<Planet>', Quest.Planet.Name, HighlightColorTag);
          AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, Text, '');
        end;
        Quest.Successful := True;
        PublishQuestStatus(Quest, 0);
        Quest.ObjectiveTarget := nil;
        RefreshPlayerQuestTargets;
        Break;
      end;
    end;
  end;
end;
{ @end $5A5AA4 }

{ @routine $5A603C TRanger_HasQuestOfType }
function TRanger.HasQuestOfType(QuestType: TQuestType): Boolean;
var
  I: Integer;
  Quest: PQuest;
begin
  for I := 0 to Quests.Count - 1 do
  begin
    Quest := PQuest(Quests[I]);
    if Quest.QuestType = QuestType then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
{ @end $5A603C }

{ @routine $5A6078 TRanger_RefreshPlayerQuestTargets }
procedure TRanger.RefreshPlayerQuestTargets;
var
  I: Integer;
  Quest: PQuest;
begin
  if Player <> Self then Exit;
  Player.QuestTargetKillShip := nil;
  Player.QuestTargetDefendShip := nil;
  Player.QuestTargetDefendPlanet := nil;
  for I := 0 to Player.Quests.Count - 1 do
  begin
    Quest := PQuest(Player.Quests[I]);
    if not Quest.Successful then
      case Quest.QuestType of
        qtKillShip: Player.QuestTargetKillShip := Quest.ObjectiveTarget as TShip;
        qtDefendShip: Player.QuestTargetDefendShip := Quest.ObjectiveTarget as TShip;
        qtDefendSystem: Player.QuestTargetDefendPlanet := TPlanet(Quest.ObjectiveTarget);
      end;
  end;
end;
{ @end $5A6078 }

end.

unit aTransport;
// Unit bracket (inferred): CODE 0x005942CC..0x00597CCF; inclusive evidence, not full bounds.
interface
uses aNormalShip, aShip, aPlanet, aGalaxy, EC_Buf;
type
  TTransport = class(TNormalShip) // @size $1D4 @methodorder source Native VMT $5942CC.
  public
    TransportType: TTransportType; // @offset $1D0 Save/load $5949A8/$5949D0; name and cargo policy consumers.

    destructor Destroy; override; // @addr $5943BC
    procedure InitGenerated(Planet: TPlanet; InitialMoney: Integer; SubType: TTransportType); // @addr $5943F4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5949A8
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5949D0
    procedure ResolveLoadedReferences; override; // @addr $5949F4
    procedure NextDay; override; // @addr $5949FC
    function SelectRepairOrTradePlanet: TPlanet; // @addr $594C50
    function SelectTradePlanet: TPlanet; // @addr $594C74
    procedure BuildReachablePlanetQueue; override; // @addr $594CA8
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $594E10
    procedure ProcessTrading; // @addr $594E1C
    procedure BuyInitialEquipment; override; // @addr $595144
    procedure UpgradeEquipmentAtLocation; override; // @addr $5952BC
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $5954DC
    function GetHomeStar: TStar; override; // @addr $595528
    function GetName: WideString; override; // @addr $595530
    function GetFullName(const Separator: WideString): WideString; override; // @addr $595544
    function GetTypeNameKey: WideString; override; // @addr $595600
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $595680
    function GetDominantCareer: TRangerCareer; override; // @addr $595698
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $59569C
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $5956A0
    function GetEquipmentCashReserve: Integer; // @addr $595720 Held back during purchases at $595144/$5952BC, then restored.
    procedure RefuelAtLocation; override; // @addr $595764
    procedure ProcessUnseenProgression; // @addr $595778
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $595970
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $595B00
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $595B34
    procedure ReactToAttack(Attacker: TShip); override; // @addr $595C0C
    function RecomputeFearState: Boolean; override; // @addr $595C2C
    procedure TryOfferRansomToPursuer; // @addr $595E54
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $5960B8
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $596124
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $59613C
    procedure AssignWeaponTargetsInStar; // @addr $5961C4
    procedure SelectEnemyShipInStar; override; // @addr $5965DC
    procedure EngageEnemyShip; override; // @addr $596680
    procedure ProcessCombatDialogue; override; // @addr $5966F8
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $596768
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $596878
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $596D78
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $597070
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $5973AC
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $597714
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $597758
    procedure TrainSkillsAutomatically; override; // @addr $59779C
  end;
implementation

// @unit-initialization $597CC8
// @unit-finalization $597C98

uses Classes, aItem, aMyFunction, aConst, aRanger, aPlayer, aTranclucator, GlobalsV, Globals, Math, GR_Main, SE_Ship2, EC_Struct, aAsteroid;

{ @routine $5943BC TTransport_Destroy }
destructor TTransport.Destroy;
begin
  Dec(HomePlanet.HomeTransportCount);
  Dec(Galaxy.TransportCount);
  inherited Destroy;
end;
{ @end $5943BC }

{ @routine $5943F4 TTransport_InitGenerated }
procedure TTransport.InitGenerated(Planet: TPlanet; InitialMoney: Integer; SubType: TTransportType);
var Index, Attempt, I, J, LastIndex, FirstIndex: Integer;
  Star: TStar; Ship: TShip; Ranger: TRanger; OwnerName: WideString;
  Duplicate: Boolean; Good: TGoodsIndex;
begin
  Inc(Galaxy.TransportCount);
  HomePlanet := Planet;
  CurrentPlanet := HomePlanet;
  CurrentStar := CurrentPlanet.CurrentStar;
  CurrentStar.Ships.Add(Self);
  OwnerId := HomePlanet.OwnerId;
  SetMoney(InitialMoney);
  ShipType := t_Transport;
  TransportType := SubType;
  // Always replaces the supplied subtype with a random subtype.
  case NextRandomIntRange(0, 100, RandomState) of
    0..45: TransportType := ttTransport;
    46..79: TransportType := ttLiner;
    80..100: TransportType := ttDiplomat;
  end;
  OwnerName := OwnerToSys(OwnerId);
  FirstIndex := 0;
  LastIndex := LanguageDataConfig.GetBlock('ShipName').GetBlock('Transport').GetBlock(OwnerName).GetParamCount - 1;
  Index := NextRandomIntRange(FirstIndex, LastIndex, RandomState);
  for Attempt := FirstIndex to LastIndex do begin
    Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Transport').GetBlock(OwnerName).GetParamValue(Index);
    Duplicate := False;
    for I := 0 to Galaxy.Stars.Count - 1 do begin
      Star := Galaxy.Stars[I];
      for J := 0 to Star.Ships.Count - 1 do begin
        Ship := Star.Ships[J];
        if (Ship <> Self) and (Ship.ShipType = t_Transport) and ((Ship as TTransport).Name = Name) then begin
          Duplicate := True;
          Break;
        end;
      end;
    end;
    if not Duplicate then Break;
    IncrementWrapped(Index, FirstIndex, LastIndex);
    if Attempt = LastIndex then Name := Name + ' 2';
  end;
  for Good := t_Food to t_Narcotics do begin CargoGoods[Good].Count := 0; CargoGoods[Good].TotalCost := 0; end;
  if Player <> nil then begin
    Rank := TCoalitionRank(NextRandomIntRange(0, Ord(Player.Rank), RandomState));
    if Rank > crWingman then Rank := crWingman;
    AddRankPoints(NextRandomIntRange(0, CoalitionRankPointThresholds[Rank] div 2, RandomState));
    GainExperience(Round(RemapClamped(Ord(Rank), 0, 3, 1260, 2520)));
  end;
  Graphic := TShip2SE.CreateEmpty;
  case TransportType of
    ttTransport: ShipRenderTemplates[HomePlanet.OwnerId, 3].SpaceObject.CopyTo(Graphic);
    ttLiner: ShipRenderTemplates[HomePlanet.OwnerId, 4].SpaceObject.CopyTo(Graphic);
    ttDiplomat: ShipRenderTemplates[HomePlanet.OwnerId, 5].SpaceObject.CopyTo(Graphic);
  end;
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(0);
  CollisionRadius := 32;
  Index := 5;
  case TransportType of ttTransport: Index := 3; ttLiner: Index := 4; ttDiplomat: Index := 5; end;
  CreateAndEquipHull(True, Round(500 * ItemSizeFactors[Index]), 1, OwnerId);
  CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
  if NextRandomIntRange(1, 10, RandomState) > 9 then
    CreateAndEquipCargoHook(True, 40, NextRandomIntRange(1, 1, RandomState), OwnerId);
  CreateAndEquipWeapon(t_PhotonGun, True, WeaponInfo[t_PhotonGun].Weight, 1, OwnerId);
  CreateAndEquipRadar(True, Round(ItemSizeFactors[NextRandomIntRange(2, 4, RandomState)] * 30), 1, OwnerId);
  RefreshDerivedStats;
  BuyInitialEquipment;
  for Index := 0 to Galaxy.Rangers.Count - 1 do begin
    Ranger := Galaxy.Rangers[Index];
    RangerRelations.Add(Pointer(OwnerRelations[OwnerId, Ranger.OwnerId]));
  end;
end;
{ @end $5943F4 }

{ @routine $5949A8 TTransport_SaveToBuffer }
procedure TTransport.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(TransportType)));
end;
{ @end $5949A8 }

{ @routine $5949D0 TTransport_LoadFromBuffer }
procedure TTransport.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  WriteByteValue(Buffer.GetByte, TransportType);
end;
{ @end $5949D0 }

{ @routine $5949F4 TTransport_ResolveLoadedReferences }
procedure TTransport.ResolveLoadedReferences;
begin
  inherited ResolveLoadedReferences;
end;
{ @end $5949F4 }

{ @routine $5949FC TTransport_NextDay }
procedure TTransport.NextDay;
var Planet: TPlanet; Destination: TPointF;
begin
  inherited NextDay;
  if ScriptShip <> nil then begin
    ScriptNextDay;
    if ScriptShip <> nil then Exit;
  end;
  if CurrentPlanet <> nil then begin
    RepairBrokenEquipmentAtLocation;
    OptimizeInventory;
    RefuelAtLocation;
    if RepairHullAtLocation then Exit;
    ProcessTrading;
    UpgradeEquipmentAtLocation;
    ProcessUnseenProgression;
    TrainSkillsAutomatically;
    OrderTakeoff;
  end else if InNormalSpace then begin
    BuildReachablePlanetQueue;
    if RecomputeFearState then TryOfferRansomToPursuer;
    ProcessCombatDialogue;
    AssignWeaponTargetsInStar;
    if not InFear then begin
      SelectEnemyShipInStar;
      EngageEnemyShip;
    end else begin
      if (Order <> soLanding) and (Order <> soJump) then NavigateToEscapePlanet(True);
      if (Order in [soLanding,soJump]) and (EstimateOrderTravelTurns > 4) and
        (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and
        (EnemyShip.ShipType in [t_Ranger,t_Pirate]) and (EnemyShip.EstimateOrderTravelTurns < 3) and
        (NextRandomUnitFloat(RandomState) < 0.2) and ((Galaxy.CurrentTurn + Integer(Seed)) mod 2 = 0) then
        if JettisonCargoGoodsTowardTargetValue(Max(200, Galaxy.ComputeScaledMiniMoney(OwnerId) div 2)) then
          NotifyFearCargoDrop(EnemyShip);
    end;
    if Order = soNone then begin
      Planet := SelectRepairOrTradePlanet;
      if Planet = nil then begin
        Destination.X := NextRandomIntRange(-2000, 2000, RandomState);
        Destination.Y := NextRandomIntRange(-2000, 2000, RandomState);
        OrderMove(Destination, False);
      end else if Planet.CurrentStar = CurrentStar then OrderLanding(Planet, False)
      else OrderJump(Planet.CurrentStar, False);
    end;
  end;
end;
{ @end $5949FC }

{ @routine $594C50 TTransport_SelectRepairOrTradePlanet }
function TTransport.SelectRepairOrTradePlanet: TPlanet;
begin
  if HasHullDamageOrBrokenEquippedItems then Result := NavigateToQueuedPlanet(False) else Result := SelectTradePlanet;
end;
{ @end $594C50 }

{ @routine $594C74 TTransport_SelectTradePlanet }
function TTransport.SelectTradePlanet: TPlanet;
begin
  if PlanetQueue.Count > 0 then
    Result := PlanetQueue[NextRandomIntRange(0, PlanetQueue.Count - 1, RandomState)]
  else Result := nil;
end;
{ @end $594C74 }

{ @routine $594CA8 TTransport_BuildReachablePlanetQueue }
procedure TTransport.BuildReachablePlanetQueue;
var I, J: Integer; Planet: TPlanet; Star: TStar;
begin
  ClearPlanetQueue;
  PlanetQueue := TList.Create;
  if (HomePlanet <> LastDockedPlanet) and
    (JumpRange >= PointDistance(HomePlanet.CurrentStar.Position, CurrentStar.Position)) and
    (Hull.HullPoints > Hull.Weight * 0.5) and HomePlanet.IsCoalitionOwned then
    PlanetQueue.Add(HomePlanet)
  else
    for I := 0 to Galaxy.Stars.Count - 1 do begin
      Star := CurrentStar.StarDistances[I].Star as TStar;
      if (I > 0) and (CurrentStar.StarDistances[I].Distance > JumpRange) then Break;
      if (Star.Ships.Count > 15) and (PlanetQueue.Count > 0) then Continue;
      if Star.ControlFaction = sfKlissan then Continue;
      for J := 0 to Star.Planets.Count - 1 do begin
        Planet := Star.Planets[J];
        if Planet.IsCoalitionOwned and (Planet <> LastDockedPlanet) and
          ((I = 0) or (LastDockedPlanet.CurrentStar = CurrentStar)) then
          PlanetQueue.Add(Planet);
      end;
    end;
end;
{ @end $594CA8 }

{ @routine $594E10 TTransport_CanQueueReachablePlanet }
function TTransport.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := Planet.OwnerId <> oiKling;
end;
{ @end $594E10 }

{ @routine $594E1C TTransport_ProcessTrading }
procedure TTransport.ProcessTrading;
var Good: TGoodsIndex; Quantity: Integer;
begin
  case TransportType of
  ttTransport:
    for Good := t_Food to t_Narcotics do begin
      if (Good in TransportTradeGoods) and (CurrentPlanet.Goods[Good].Count > 0) and
        (CurrentPlanet.Goods[Good].PurchasePrice < GoodsMarket[Good].BasePrice) and (CargoFreeSpace > 0) then begin
        Quantity := Min(Trunc(Money / CurrentPlanet.Goods[Good].PurchasePrice), CargoFreeSpace);
        Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
        BuyGoodsFromLocation(Good, Quantity);
      end
      else if CargoGoods[Good].Count > 0 then
        if (CurrentPlanet.Goods[TGoodsIndex(Good)].BaseSalePrice > GetAverageCargoCost(Good)) or (NextRandomUnitFloat(RandomState) < 0.2) then
          SellGoodsToLocation(Good, CargoGoods[Good].Count);
    end;
  ttLiner:
    for Good := t_Food to t_Narcotics do begin
      if (Good in LinerTradeGoods) and (CurrentPlanet.Goods[Good].Count > 0) and
        (CurrentPlanet.Goods[Good].PurchasePrice < GoodsMarket[Good].BasePrice) and (CargoFreeSpace > 0) then begin
        Quantity := Min(Trunc(Money / CurrentPlanet.Goods[Good].PurchasePrice), CargoFreeSpace);
        Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
        BuyGoodsFromLocation(Good, Quantity);
      end
      else if CargoGoods[Good].Count > 0 then
        if (CurrentPlanet.Goods[TGoodsIndex(Good)].BaseSalePrice > GetAverageCargoCost(Good)) or (NextRandomUnitFloat(RandomState) < 0.2) then
          SellGoodsToLocation(Good, CargoGoods[Good].Count);
    end;
  ttDiplomat:
    for Good := t_Food to t_Narcotics do begin
      if (Good in DiplomatTradeGoods) and (CurrentPlanet.Goods[Good].Count > 0) and
        (CurrentPlanet.Goods[Good].PurchasePrice < GoodsMarket[Good].BasePrice) and (CargoFreeSpace > 0) then begin
        Quantity := Min(Trunc(Money / CurrentPlanet.Goods[Good].PurchasePrice), CargoFreeSpace);
        Quantity := Min(Quantity, CurrentPlanet.Goods[Good].Count);
        BuyGoodsFromLocation(Good, Quantity);
      end
      else if CargoGoods[Good].Count > 0 then
        if (CurrentPlanet.Goods[TGoodsIndex(Good)].BaseSalePrice > GetAverageCargoCost(Good)) or (NextRandomUnitFloat(RandomState) < 0.2) then
          SellGoodsToLocation(Good, CargoGoods[Good].Count);
    end;
  end;
end;
{ @end $594E1C }

{ @routine $595144 TTransport_BuyInitialEquipment }
procedure TTransport.BuyInitialEquipment;
var Reserve: Integer;
begin
  Reserve := GetEquipmentCashReserve;
  if Reserve > Money then Exit;
  SetMoney(Money - Reserve);
  case TransportType of
    ttTransport: if NextRandomUnitFloat(RandomState) < 0.9 then BuyHullUpgrade(scBig) else BuyHullUpgrade(scAverage);
    ttLiner: if NextRandomUnitFloat(RandomState) < 0.9 then BuyHullUpgrade(scAverage) else BuyHullUpgrade(scSmall);
    ttDiplomat: BuyHullUpgrade(scSmall);
  end;
  BuyRadarUpgrade(scZero);
  if NextRandomUnitFloat(RandomState) < 0.3 then BuyFuelTanksUpgrade(scZero);
  case TransportType of
    ttTransport: BuyWeaponUpgrade(scBig);
    ttLiner: BuyWeaponUpgrade(scAverage);
    ttDiplomat: BuyWeaponUpgrade(scSmall);
  end;
  if WeaponCount = 0 then BuyWeaponUpgrade(scZero);
  if NextRandomUnitFloat(RandomState) < 0.2 then BuyRepairRobotUpgrade(scZero);
  BuyEngineUpgrade(scZero);
  BuyScannerUpgrade(scZero);
  BuyDefGeneratorUpgrade(scZero);
  SetMoney(Money + Reserve);
end;
{ @end $595144 }

{ @routine $5952BC TTransport_UpgradeEquipmentAtLocation }
procedure TTransport.UpgradeEquipmentAtLocation;
var Reserve: Integer;
begin
  Reserve := GetEquipmentCashReserve;
  if Reserve > Money then Exit;
  SetMoney(Money - Reserve);
  case TransportType of
    ttTransport: begin
      BuyHullUpgrade(scBig);
      if StrengthInAverageRanger < 0.3 then BuyRepairRobotUpgrade(scBig);
      BuyRadarUpgrade(scBig);
      if Radar <> nil then BuyScannerUpgrade(scZero);
      if StrengthInAverageRanger < 0.1 then BuyDefGeneratorUpgrade(scBig);
      BuyFuelTanksUpgrade(scBig);
      BuyEngineUpgrade(scZero);
      if StrengthInAverageRanger < 0.2 then BuyWeaponUpgrade(scZero);
    end;
    ttLiner: begin
      BuyHullUpgrade(scAverage);
      if StrengthInAverageRanger < 0.2 then BuyDefGeneratorUpgrade(scZero);
      BuyRadarUpgrade(scZero);
      if Radar <> nil then BuyScannerUpgrade(scZero);
      if StrengthInAverageRanger < 0.2 then BuyRepairRobotUpgrade(scZero);
      BuyEngineUpgrade(scZero);
      BuyFuelTanksUpgrade(scZero);
      if StrengthInAverageRanger < 0.2 then BuyWeaponUpgrade(scAverage);
    end;
    ttDiplomat: begin
      BuyEngineUpgrade(scZero);
      if StrengthInAverageRanger < 0.4 then BuyDefGeneratorUpgrade(scSmall);
      BuyRadarUpgrade(scSmall);
      if Radar <> nil then BuyScannerUpgrade(scSmall);
      if StrengthInAverageRanger < 0.4 then BuyRepairRobotUpgrade(scSmall);
      BuyFuelTanksUpgrade(scSmall);
      BuyHullUpgrade(scSmall);
      if StrengthInAverageRanger < 0.3 then BuyWeaponUpgrade(scSmall);
    end;
  end;
  SetMoney(Money + Reserve);
end;
{ @end $5952BC }

{ @routine $5954DC TTransport_RepairBrokenEquipmentAtLocation }
procedure TTransport.RepairBrokenEquipmentAtLocation;
var I: Integer; Equipment: TEquipment;
begin
  for I := 0 to Inventory.Count - 1 do begin
    Equipment := Inventory[I];
    if Equipment.BrokenFlag or (Equipment.ConditionPercent < 20) then Equipment.Repair;
  end;
end;
{ @end $5954DC }

{ @routine $595528 TTransport_GetHomeStar }
function TTransport.GetHomeStar: TStar;
begin
  Result := HomePlanet.CurrentStar;
end;
{ @end $595528 }

{ @routine $595530 TTransport_GetName }
function TTransport.GetName: WideString;
begin
  Result := Name;
end;
{ @end $595530 }

{ @routine $595544 TTransport_GetFullName }
function TTransport.GetFullName(const Separator: WideString): WideString;
begin
  Result := LocalizedText('ShipType.' + OwnerToSys(OwnerId) + '.' + GetTypeNameKey) + Separator + Name;
end;
{ @end $595544 }

{ @routine $595600 TTransport_GetTypeNameKey }
function TTransport.GetTypeNameKey: WideString;
begin
  case TransportType of
    ttTransport: Result := 'Transport';
    ttLiner: Result := 'Liner';
    ttDiplomat: Result := 'Diplomat';
  end;
end;
{ @end $595600 }

{ @routine $595680 TTransport_GetGreetingShipCategory }
function TTransport.GetGreetingShipCategory: TGreetingShipCategory;
begin
  case TransportType of
    ttTransport: Result := gscTransport;
    ttLiner: Result := gscLiner;
  else Result := gscDiplomat;
  end;
end;
{ @end $595680 }

{ @routine $595698 TTransport_GetDominantCareer }
function TTransport.GetDominantCareer: TRangerCareer;
begin
  Result := rcTrader;
end;
{ @end $595698 }

{ @routine $59569C TTransport_GetStrengthScaledPirateStatus }
function TTransport.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 0;
end;
{ @end $59569C }

{ @routine $5956A0 TTransport_GetDesiredCargoFreeSpace }
function TTransport.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
  case TransportType of
    ttTransport: Result := Trunc(Hull.Weight * 0.3);
    ttLiner: Result := Integer(Trunc(Hull.Weight * 0.1)) + 30;
    ttDiplomat: Result := Integer(Trunc(Hull.Weight * 0.1)) + 10;
  end;
end;
{ @end $5956A0 }

{ @routine $595720 TTransport_GetEquipmentCashReserve }
function TTransport.GetEquipmentCashReserve: Integer;
begin
  case TransportType of
    ttTransport: Result := Wealth div 5;
    ttLiner: Result := Wealth div 7;
    ttDiplomat: Result := Wealth div 10;
  else Result := Wealth div 10;
  end;
end;
{ @end $595720 }

{ @routine $595764 TTransport_RefuelAtLocation }
procedure TTransport.RefuelAtLocation;
begin
  if FuelTanks <> nil then FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $595764 }

{ @routine $595778 TTransport_ProcessUnseenProgression }
procedure TTransport.ProcessUnseenProgression;
var Award: Byte; StoredAward: PByte;
begin
  if (DaysSincePlayerSeen >= 60) and (Player <> nil) then begin
    if NextRandomUnitFloat(RandomState) < 0.06 then
      GainExperience(SeededRandomIntRange(25, 70, Seed + Cardinal(Galaxy.CurrentTurn div 59) + 789));
    if (Player.Rank > Rank) and (NextRandomUnitFloat(RandomState) < 0.03) and (Rank < crLeader) then begin
      AddRankPoints(NextRandomIntRange(10, 20, RandomState));
      TryPromoteRank;
    end;
    if NextRandomUnitFloat(RandomState) < 0.01 then begin
      case TransportType of
        ttTransport: Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment,atForCowardice]);
        ttLiner: Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment]);
        ttDiplomat: Award := SelectAward(CurrentPlanet.OwnerId, [atForAccomplishment..atForPerfidy]);
      else Award := 255;
      end;
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      New(StoredAward);
      AwardIds.Add(StoredAward);
      StoredAward^ := Award;
    end;
  end;
end;
{ @end $595778 }

{ @routine $595970 TTransport_RelationToNonRanger }
function TTransport.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
var Value: Integer;
begin
  if (Ship = EnemyShip) or (Self = Ship.EnemyShip) then begin Result := 0; Exit; end;
  case Ship.ShipType of
    t_Ranger: Result := RelationToRanger(Ship);
    t_Transport: begin
      Value := Round((0.7 * PlanetRaceMarket[OwnerToRace(OwnerId)].FriendlyRelationScale) *
        OwnerRelations[OwnerId, Ship.OwnerId]);
      if Value > 100 then Value := 100;
      Result := Value;
    end;
    t_Pirate: begin
      Value := Round((0.5 * PlanetRaceMarket[OwnerToRace(OwnerId)].PirateRelationFactor) *
        OwnerRelations[OwnerId, Ship.OwnerId]);
      // Reversed clamp is native: the computed relation always becomes 20.
      Value := Min(20, Max(Value, 70));
      Result := Value;
    end;
    t_Warrior: Result := 100;
    t_Kling: Result := 0;
    t_Tranclucator: if (Ship as TTranclucator).OwnerShip <> nil then
      Result := RelationToNonRanger((Ship as TTranclucator).OwnerShip)
      else Result := 100;
    t_RangerCenter..t_ScientificBase: Result := 100;
  else Result := 50;
  end;
end;
{ @end $595970 }

{ @routine $595B00 TTransport_RelationToRanger }
function TTransport.RelationToRanger(Ranger: TObject): Byte;
begin Result := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]); end;
{ @end $595B00 }

{ @routine $595B34 TTransport_ChangeRelationToRanger }
procedure TTransport.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
var Relation: Byte; Value: Integer;
begin
  Relation := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  // Charisma increases negative changes too.
  if TShip(Ranger).BaseSkills[skCharm] > 0 then
    Inc(Amount, Round(TShip(Ranger).BaseSkills[skCharm] * Amount * 0.2));
  Value := Amount + Relation;
  if Value < 0 then Relation := 0
  else if Value > 100 then Relation := 100
  else Relation := Value;
  if (Relation < 10) and ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar)) then
    EnemyShip := TShip(Ranger);
  RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $595B34 }

{ @routine $595C0C TTransport_ReactToAttack }
procedure TTransport.ReactToAttack(Attacker: TShip);
begin
  EnemyShip := Attacker;
  if Attacker.ShipType = t_Ranger then ChangeRelationToRanger(Attacker, -10);
end;
{ @end $595C0C }

{ @routine $595C2C TTransport_RecomputeFearState }
function TTransport.RecomputeFearState: Boolean;
var Ship: TShip; I, EnemyCount: Integer; Tolerance, Threat: Double;
begin
  Result := (Hull.HullPoints < Hull.Weight * 0.2) or ((EnemyShip <> nil) and
    ((EnemyShip.OrderTarget = Self) or (Player = EnemyShip)) and AcceptsRansomDemandFrom(EnemyShip));
  if not Result then begin
    Threat := 0;
    EnemyCount := 0;
    Tolerance := RemapClamped(Hull.HullPoints, 50, Hull.Weight, 0, 3);
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if Ship.InNormalSpace and (Ship <> Self) then begin
        if Ship = EnemyShip then begin
          Threat := Ship.ChanceToWin(Self) + Threat;
          Inc(EnemyCount);
        end else if ((Ship.EnemyShip = Self) and (Ship.OrderTarget = Self)) or
          ((Ship.RelationToNonRanger(Self) < 10) and (PointDistanceSquared(Position, Ship.Position) < 250000)) then begin
          Threat := Ship.ChanceToWin(Self) + Threat;
          if (EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar) or EnemyShip.IsOutsideStarSpace then EnemyShip := Ship
          else if (EnemyShip <> Ship) and (OrderTarget <> EnemyShip) then
            if PointDistanceSquared(EnemyShip.Position, Position) > PointDistanceSquared(Ship.Position, Position) then EnemyShip := Ship;
        end;
      end;
    end;
    if (EnemyCount - 1) * Threat * 0.5 + Threat > Tolerance then Result := True;
  end;
  InFear := Result;
end;
{ @end $595C2C }

{ @routine $595E54 TTransport_TryOfferRansomToPursuer }
procedure TTransport.TryOfferRansomToPursuer;
var Response: WideString; Amount: Integer; LowOffer, HighOffer: Single;
  Accepted: Boolean; Ship: TShip;
begin
  if InNormalSpace and (EnemyShip <> nil) and (EnemyShip.OrderTarget = Self) and (EnemyShip.TruceShip <> Self) and
    (Money > 100) and not CanEscapePursuer(EnemyShip) and not (EnemyShip.ShipType in NonNegotiatingShipTypes) and
    (EnemyShip.GetMaxWeaponRange * EnemyShip.GetMaxWeaponRange >= PointDistanceSquared(Position, EnemyShip.Position)) and
    (((Galaxy.CurrentTurn * Integer(EnemyShip.Id) mod 3 = 0) and (NextRandomUnitFloat(RandomState) > 0.2)) or (GetHullIntegrityPercent < 20)) then begin
    LowOffer := Min(Money, GetWealthScaledAmount(scMini));
    HighOffer := Min(Money, (GetWealthScaledAmount(scBig) + EnemyShip.GetWealthScaledAmount(scBig)) * 0.5);
    Amount := Round(Max(100, RemapClampedAlternate(Hull.HullPoints, 0, Hull.Weight, HighOffer, LowOffer)));
    Ship := EnemyShip;
    Accepted := Ship.BuildTrucePaymentResponse(Self, Response, Amount);
    if (Ship <> Player) and (Player.CurrentStar = CurrentStar) then NotifyTruceOffer(Ship, Response, Amount);
    if Accepted and RecomputeFearState then TryOfferRansomToPursuer;
  end;
end;
{ @end $595E54 }
{ @routine $5960B8 TTransport_AcceptsRansomDemandFrom }
function TTransport.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := (Hull.Weight * 0.5 * OwnerInfo[OwnerId].FearThresholdScale > Hull.HullPoints) and
    (ChanceToWin(Ship) - OwnerInfo[OwnerId].FearThresholdScale < 0);
end;
{ @end $5960B8 }

{ @routine $596124 TTransport_TrustsAttackRequester }
function TTransport.TrustsAttackRequester(Ship: TShip): Boolean;
begin Result := RelationToNonRanger(Ship) >= 30; end;
{ @end $596124 }

{ @routine $59613C TTransport_EvaluateAllyRelationAndStrength }
function TTransport.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := (RelationToNonRanger(Ship)) +
    RemapClamped(Ship.Strength, 0.9 * Strength, Strength * 3, 0, 100) > 110;
end;
{ @end $59613C }
{ @routine $5961C4 TTransport_AssignWeaponTargetsInStar }
procedure TTransport.AssignWeaponTargetsInStar;
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
  if CurrentStar.Battle then
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if not ((Ship.OwnerId = oiKling) and Ship.InNormalSpace) then Continue;
      for J := 1 to WeaponCount do begin
        Weapon := Weapons[J - 1];
        if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
          (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Ship.Position))) then Continue;
        Weapon.Target := Ship;
        Inc(Assigned);
        if Assigned = WeaponCount then Exit;
      end;
    end;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    for J := 1 to WeaponCount do begin
      Weapon := Weapons[J - 1];
      if not (((Weapon.Target = nil) and not Weapon.BrokenFlag) and
        (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, EnemyShip.Position))) then Continue;
      Weapon.Target := EnemyShip;
      Inc(Assigned);
      if Assigned = WeaponCount then Exit;
    end;
  if Player.CurrentStar = CurrentStar then
    for I := 0 to CurrentStar.Asteroids.Count - 1 do begin
      Asteroid := CurrentStar.Asteroids[I];
      Distance := PointDistanceSquared(Position, Asteroid.Position);
      if Distance <= AsteroidTargetRangeSquared then
        for J := 1 to WeaponCount do begin
          Weapon := Weapons[J - 1];
          // Native asteroid targeting can overwrite an existing assignment.
          if not ((not Weapon.HasSpecialDamageMode and not Weapon.BrokenFlag and
            (Weapon.Range * Weapon.Range >= Distance))) then Continue;
          Weapon.Target := Asteroid;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
          Break;
        end;
    end;
  if CurrentStar.Items.Count > 7 then
    for I := 0 to CurrentStar.Items.Count - 1 do begin
      Item := CurrentStar.Items[I];
      if (Item.ScriptItem = nil) and ((Item.ItemType = t_Minerals) or (CurrentStar.Items.Count >= 15)) and
        ((Player.CurrentStar <> CurrentStar) or not Player.InNormalSpace or (GetRelationLevelToShip(Player) <= rlBad) or
        (PointDistance(Player.Position, Item.Position) >= 800) or
        ((NextRandomUnitFloat(RandomState) <= 0.1) and (PointDistance(Player.Position, Item.Position) >= 200))) then
        for J := 1 to WeaponCount do begin
          Weapon := Weapons[J - 1];
          if not ((not Weapon.HasSpecialDamageMode and (Weapon.Target = nil) and not Weapon.BrokenFlag) and
            (Weapon.Range * Weapon.Range >= PointDistanceSquared(Position, Item.Position))) then Continue;
          Weapon.Target := Item;
          Inc(Assigned);
          if Assigned = WeaponCount then Exit;
          Break;
        end;
    end;
end;
{ @end $5961C4 }

{ @routine $5965DC TTransport_SelectEnemyShipInStar }
procedure TTransport.SelectEnemyShipInStar;
var I: Integer; Ship: TShip;
begin
  if ((EnemyShip = nil) or (EnemyShip.CurrentStar <> CurrentStar) or (EnemyShip.OwnerId = oiKling)) and
    (UsableWeaponCount <> 0) and (CurrentStar.ControlFaction <> sfCoalition) then
    for I := 0 to CurrentStar.Ships.Count - 1 do begin
      Ship := CurrentStar.Ships[I];
      if (Ship.OwnerId = oiKling) and Ship.InNormalSpace then begin
        if ChanceToWin(Ship) - OwnerInfo[OwnerId].FearThresholdScale > 0 then begin
          EnemyShip := Ship;
          Break;
        end;
        EnemyShip := Ship;
      end;
    end;
end;
{ @end $5965DC }

{ @routine $596680 TTransport_EngageEnemyShip }
procedure TTransport.EngageEnemyShip;
begin
  if Order = soFollowShip then OrderNone;
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then begin
    OrderFollowShip(EnemyShip, fmMinWeaponRange, False);
    if ChanceToWin(EnemyShip) < 0.9 then RequestAlliesAttackShip(EnemyShip);
  end;
end;
{ @end $596680 }

{ @routine $5966F8 TTransport_ProcessCombatDialogue }
procedure TTransport.ProcessCombatDialogue;
begin
  if (EnemyShip <> nil) and (OrderTarget = EnemyShip) and (Integer(Seed + Cardinal(Galaxy.CurrentTurn)) mod 7 = 0) and
    (ChanceToWin(EnemyShip) < 1.3) and (GetHullIntegrityPercent > 30) then RequestAlliesAttackShip(EnemyShip);
end;
{ @end $5966F8 }

{ @routine $596768 TTransport_ReactToExtortionDemand }
procedure TTransport.ReactToExtortionDemand(Ranger: TObject);
begin
  if (Player = Ranger) or (NextRandomUnitFloat(RandomState) < 0.05) then begin
    ChangeRelationToRanger(Ranger, -15);
    HomePlanet.ChangeRelationToRanger(Ranger, -2);
    (Ranger as TRanger).AddPirateCareerActivity(2);
  end;
end;
{ @end $596768 }

{ @routine $596878 TTransport_BuildMoneyExtortionResponse }
function TTransport.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
  // @nested $5967D4 PayDemand
  procedure PayDemand; // @addr $5967D4
  begin
    OtherShip.SetMoney(OtherShip.Money + DemandedAmount);
    SetMoney(Money - DemandedAmount);
    OtherShip.TruceWithShip(Self);
    if OtherShip = Player then LastPlayerExtortionTurn := Galaxy.CurrentTurn;
    if OtherShip is TRanger then (OtherShip as TRanger).ApplyExtortionReputationPenalty(Self);
  end;
begin
  Result := False;
  if OtherShip is TRanger then ReactToExtortionDemand(OtherShip);
  if (Player <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Money.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'LongDistance')
  else if DemandedAmount > RemapClampedAlternate(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scBig), GetWealthScaledAmount(scSmall)) then
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'SumIsVeryBig')
  else if Money < DemandedAmount then Response := LookupVisibleTalkText('Talk.Money.AnswerNotMoney')
  else begin
    Response := LookupVisibleTalkText('Talk.Money.' + GetTypeNameKey + 'Ok');
    PayDemand;
    Result := True;
  end;
end;
{ @end $596878 }

{ @routine $596D78 TTransport_BuildCargoExtortionResponse }
function TTransport.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
  // @nested $596BF8 DropDemand
  procedure DropDemand; // @addr $596BF8
  var Good: TGoodsIndex; Pass, Count, TotalValue, LowValue, HighValue: Integer; Enough: Boolean; Divisor: Single;
  begin
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
  if (Player <> OtherShip) and ((EnemyShip = nil) or (CurrentStar <> EnemyShip.CurrentStar)) then EnemyShip := OtherShip;
  if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Goods.WeAlreadyHavePact')
  else if not AcceptsRansomDemandFrom(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'No')
  else if CanEscapePursuer(OtherShip) then Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'LongDistance')
  else if not HasCargoGoods then Response := LookupVisibleTalkText('Talk.Goods.AnswerNotGoods')
  else begin
    Response := LookupVisibleTalkText('Talk.Goods.' + GetTypeNameKey + 'Ok');
    DropDemand;
    Result := True;
  end;
end;
{ @end $596D78 }

{ @routine $597070 TTransport_BuildTrucePaymentResponse }
function TTransport.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
  // @nested $597024 AcceptPayment
  procedure AcceptPayment; // @addr $597024
  begin
    OtherShip.SetMoney(OtherShip.Money - OfferedAmount);
    SetMoney(Money + OfferedAmount);
    TruceWithShip(OtherShip);
  end;
begin
  Result := False;
  if OtherShip is TRanger then (OtherShip as TRanger).AddTraderCareerActivity(1);
  if OtherShip.TruceShip = Self then Response := LookupVisibleTalkText('Talk.Truce.WeAlreadyHavePact')
  else if RecomputeFearState or ((ChanceToWin(OtherShip) < 1) and (GetHullIntegrityPercent < 40)) or (ChanceToWin(OtherShip) < 0.2) or
    (OfferedAmount > RemapClamped(GetWinChancePercent(OtherShip), 0, 100, GetWealthScaledAmount(scMini), GetWealthScaledAmount(scBig))) then begin
    Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'Ok');
    AcceptPayment;
    Result := True;
  end else Response := LookupVisibleTalkText('Talk.Truce.' + GetTypeNameKey + 'No');
end;
{ @end $597070 }

{ @routine $5973AC TTransport_BuildAttackRequestResponse }
function TTransport.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
  // @nested $5972DC AcceptRequest
  procedure AcceptRequest; // @addr $5972DC
  begin
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Ok');
    SetJointAttackTarget(Requester, Target);
    Result := True;
  end;
begin
  Result := False;
  if Requester is TRanger then begin
    if Target.ShipType in [t_Ranger..t_Pirate] then Target.ChangeRelationToRanger(Requester, -20);
    if (Target.OwnerId = oiKling) or (Target.ShipType = t_Pirate) then
      (Requester as TRanger).AddWarriorCareerActivity(1)
    else (Requester as TRanger).AddPirateCareerActivity(8);
  end;
  if (OrderTarget = Target) and (GetRelationLevelToShip(Target) = rlHostile) then AcceptRequest
  else if TruceShip = Target then
    Response := ReplaceColoredToken(LookupVisibleTalkText('Talk.Attack.WeAlreadyHavePact'), '<Target>', Target.GetName, '')
  else if RelationToNonRanger(Target) >= 30 then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'WeFriends')
  else if not TrustsAttackRequester(Requester) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Suspect')
  else if InFear or AcceptsRansomDemandFrom(Target) then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'Fear')
  else if HasLockedOrFollowOrder then
    Response := LookupVisibleTalkText('Talk.Attack.' + GetTypeNameKey + 'HaveBusiness')
  else AcceptRequest;
end;
{ @end $5973AC }

{ @routine $597714 TTransport_AcceptPartnershipOffer }
function TTransport.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin Result := False; Response := 'Not supporting'; end;
{ @end $597714 }

{ @routine $597758 TTransport_BuildPartnershipOfferResponse }
function TTransport.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin Result := False; Response := 'Not supporting'; end;
{ @end $597758 }

{ @routine $59779C TTransport_TrainSkillsAutomatically }
procedure TTransport.TrainSkillsAutomatically;
begin
  if FreeExperience < 50 then Exit;
  case TransportType of
    ttTransport: begin
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skTrader);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTrader);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTrader);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTechnical);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.05 then TrainSkill(skLeadership);
    end;
    ttLiner: begin
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skTrader);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skTechnical);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTrader);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.05 then TrainSkill(skLeadership);
    end;
    ttDiplomat: begin
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skCharm);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.35 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skMobility);
      if NextRandomUnitFloat(RandomState) < 0.25 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skAccuracy);
      if NextRandomUnitFloat(RandomState) < 0.05 then TrainSkill(skLeadership);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTechnical);
      if NextRandomUnitFloat(RandomState) < 0.15 then TrainSkill(skTrader);
    end;
  end;
end;
{ @end $59779C }

end.

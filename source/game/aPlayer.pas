unit aPlayer;
// Unit bracket (inferred): CODE 0x00512C08..0x005155CF; inclusive evidence, not full bounds.
interface
// Create $512CF8, Destroy $512D78 and save/load $512E68/$512F34.
uses aRanger, Classes, aPlanet, aItem, EC_Buf, aShip;
type
  TStorageEntry = packed record // @size $08
    Planet: TPlanet; // @offset $00 Borrowed; serialized as a planet ID.
    Item: TItem; // @offset $04 Owned; destructor frees it before disposing the record.
  end;
  PStorageEntry = ^TStorageEntry;

  TPlayer = class(TRanger) // @size $214
  public
    procedure NextDay; override; // @addr $5149BC
    procedure RechargeTransmittersFromKlissan(Ship: TShip); // @addr $514BAC Uses global Player, even if Self differs.
    procedure ProcessFinalScenarioWithdrawal; // @addr $514AA4
    function CountPartnersInNormalSpace: Byte; // @addr $514D60
    function CanRepairArtefactsAtLocation: Boolean; // @addr $514B94
    procedure RefreshStorageMessage; // @addr $5151A8
    procedure ResetCounterAfterNodeDeposit; // @addr $514DB0
    function CountStoredItemUnits(Planet: TPlanet; Kind: TItemType): Integer; // @addr $514CDC
    function GetShipRatingComparison(Ship: TShip): TStandardCount; // @addr $514DBC Native compares ship experience against player rating place.
    function GetShipRankComparison(Ship: TShip): TStandardCount; // @addr $514F08
    function GetShipStrengthComparison(Ship: TShip): TStandardCount; // @addr $515000
    InPrison: Boolean; // @offset $1F0
    HaveCommunicator: Boolean; // @offset $1F1
    HaveHyperspaceLocator: Boolean; // @offset $1F2 Awarded in the military-base promotion greeting; serialized after HaveCommunicator.
    UnresolvedCounter1F4: Integer; // @offset $1F4 Reset by Create; serialized before arcade kill counters.
    HyperspaceKillCount: Integer; // @offset $1F8
    BlackHoleKillCount: Integer; // @offset $1FC
    ScriptShipBindings: TList; // @offset $200
    QuestTargetKillShip: TShip; // @offset $204
    QuestTargetDefendShip: TShip; // @offset $208
    QuestTargetDefendPlanet: TPlanet; // @offset $20C
    StorageEntries: TList; // @offset $210 Owns PStorageEntry records.

    constructor Create; // @addr $512CF8
    destructor Destroy; override; // @addr $512D78
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $512E68
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $512F34
    procedure InitializeAtPlanet(Planet: TPlanet; InitialMoney: Integer); override; // @addr $51308C Fifteen race/career loadouts.
    procedure ResolveLoadedReferences; override; // @addr $51303C
  end;
var Player: TPlayer; // @addr $61CF64

implementation

// @unit-initialization $5155C8
// @unit-finalization $515598

uses Globals, Math, aKling, aScript, aGalaxy, aMyFunction, aNormalShip, GR_Main, GlobalsV, SysUtils, aConst;

{ @routine $512CF8 TPlayer_Create }
constructor TPlayer.Create;
begin
  inherited Create;
  StorageEntries := TList.Create;
  HaveCommunicator := False;
  HaveHyperspaceLocator := False;
  UnresolvedCounter1F4 := 0;
  ScriptShipBindings := TList.Create;
  HyperspaceKillCount := 0;
  BlackHoleKillCount := 0;
end;
{ @end $512CF8 }

{ @routine $512D78 TPlayer_Destroy }
destructor TPlayer.Destroy;
var I: Integer; Entry: PStorageEntry;
begin
  if ScriptShipBindings <> nil then
  begin
    while ScriptShipBindings.Count > 0 do
      TScriptShip(ScriptShipBindings[0]).Script.UnbindShip(Self);
    ScriptShipBindings.Clear;
    ScriptShipBindings.Free;
    ScriptShipBindings := nil;
  end;
  if StorageEntries <> nil then
  begin
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if Entry <> nil then
      begin
        if Entry.Item <> nil then
        begin
          Entry.Item.Free;
          Entry.Item := nil;
        end;
        Dispose(Entry);
        StorageEntries[I] := nil;
      end;
    end;
    StorageEntries.Clear;
    StorageEntries.Free;
    StorageEntries := nil;
  end;
  inherited Destroy;
end;
{ @end $512D78 }

{ @routine $512E68 TPlayer_SaveToBuffer }
procedure TPlayer.SaveToBuffer(Buffer: TBufEC);
var I: Integer; Entry: PStorageEntry;
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddBoolean(InPrison);
  Buffer.AddBoolean(HaveCommunicator);
  Buffer.AddBoolean(HaveHyperspaceLocator);
  Buffer.AddIntegerValue(UnresolvedCounter1F4);
  Buffer.AddIntegerValue(HyperspaceKillCount);
  Buffer.AddIntegerValue(BlackHoleKillCount);
  Buffer.AddIntegerValue(StorageEntries.Count);
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    Buffer.AddDWord(Entry.Planet.Id);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Entry.Item.ItemType)));
    Entry.Item.SaveToBuffer(Buffer);
  end;
end;
{ @end $512E68 }

{ @routine $512F34 TPlayer_LoadFromBuffer }
procedure TPlayer.LoadFromBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Entry: PStorageEntry;
  Kind: TItemType;
begin
  inherited LoadFromBuffer(Buffer);
  InPrison := Buffer.GetBoolean;
  HaveCommunicator := Buffer.GetBoolean;
  HaveHyperspaceLocator := Buffer.GetBoolean;
  UnresolvedCounter1F4 := Buffer.GetInt32;
  HyperspaceKillCount := Buffer.GetInt32;
  BlackHoleKillCount := Buffer.GetInt32;
  if LoadedSaveVersion >= 8 then
  begin
    Count := Buffer.GetInt32;
    if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
    for I := 0 to Count - 1 do
    begin
      New(Entry);
      Entry.Planet := TPlanet(Buffer.GetUInt32);
      WriteByteValue(Buffer.GetByte, Kind);
      Entry.Item := CreateItemByType(Kind);
      StorageEntries.Add(Entry);
      Entry.Item.LoadFromBuffer(Buffer);
    end;
  end;
  PlayerName := Name;
  RefreshPlayerQuestTargets;
end;
{ @end $512F34 }

{ @routine $51303C TPlayer_ResolveLoadedReferences }
procedure TPlayer.ResolveLoadedReferences;
var I: Integer; Entry: PStorageEntry;
begin
  inherited ResolveLoadedReferences;
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    Entry.Planet := TPlanet(Galaxy.IdToPlanet(Cardinal(Entry.Planet)));
    Entry.Item.ClearReferences;
  end;
end;
{ @end $51303C }

{ @routine $51308C TPlayer_InitializeAtPlanet }
procedure TPlayer.InitializeAtPlanet(Planet: TPlanet; InitialMoney: Integer);
var I: Integer; Item: TObject;
begin
  inherited InitializeAtPlanet(Planet, InitialMoney);
  for I := Inventory.Count - 1 downto 0 do begin
    Item := Inventory[I];
    Inventory.Delete(I);
    Item.Free;
  end;
  WeaponCount := 0;
  // Three careers per race. The inherited equipment cache remains until the
  // replacement loadout has been created.
  case Ord(OwnerId) * 3 + (Ord(PreferredCareer) + 1) of
    1:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 1.2, 1.6) * InitialMoney));
      ChangePlanetRelations(nil, rcmRaiseTo, 90, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
      Inc(BaseSkills[skTrader]);
      Inc(BaseSkills[skMobility]);
      CreateAndEquipHull(True, 260, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[1]), 2, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipWeapon(t_ZipGun, True, Round(WeaponInfo[t_ZipGun].Weight * ItemSizeFactors[2]), 1, OwnerId);
      RefreshDerivedStats;
    end;
    2:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, 1, [oiFei, oiGaal]);
      Inc(BaseSkills[skAccuracy]);
      Inc(BaseSkills[skMobility]);
      Inc(BaseSkills[skTechnical]);
      CreateAndEquipHull(True, 310, 2, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, oiFei);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 2, oiGaal);
      CreateAndEquipRepairRobot(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[2]), 3, OwnerId);
      CreateAndEquipWeapon(t_ZipGun, True, Round(WeaponInfo[t_ZipGun].Weight * ItemSizeFactors[2]), 3, OwnerId);
      RefreshDerivedStats;
    end;
    3:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.1, 0.3) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(30, 40, RandomState), [oiMaloc]);
      Inc(BaseSkills[skAccuracy], 2);
      Inc(BaseSkills[skMobility]);
      CreateAndEquipHull(True, 270, 3, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 3, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[3]), 4, OwnerId);
      RefreshDerivedStats;
    end;
    4:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 1.7, 2.0) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(5, 15, RandomState), [oiMaloc, oiFei]);
      Inc(BaseSkills[skTrader]);
      CreateAndEquipHull(True, 250, 2, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, oiFei);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[3]), 1, oiGaal);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[3]), 2, OwnerId);
      RefreshDerivedStats;
    end;
    5:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmDecreaseWithFloor20, NextRandomIntRange(50, 60, RandomState), [oiMaloc, oiPeople, oiFei, oiGaal]);
      Inc(BaseSkills[skMobility], 2);
      CreateAndEquipHull(True, 270, 3, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 3, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[2]), 1, OwnerId);
      Inc(CargoGoods[t_Narcotics].Count, SeededRandomIntRange(6, 9, Galaxy.RandomState));
      Inc(CargoGoods[t_Narcotics].TotalCost, CargoGoods[t_Narcotics].Count * GetLocationGoodsEntry(t_Narcotics)^.PurchasePrice);
      RefreshDerivedStats;
    end;
    6:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 1.8, 3.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, 50, [oiPeleng]);
      Inc(BaseSkills[skCharm]);
      CreateAndEquipHull(True, 290, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[1]), 4, OwnerId);
      CreateAndEquipScanner(True, Round(30 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipWeapon(t_ZipGun, True, Round(WeaponInfo[t_ZipGun].Weight * ItemSizeFactors[3]), 2, OwnerId);
      RefreshDerivedStats;
    end;
    7:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmRaiseTo, NextRandomIntRange(70, 80, RandomState), [oiPeleng, oiPeople, oiFei, oiGaal]);
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(15, 20, RandomState), [oiMaloc]);
      Inc(BaseSkills[skTrader]);
      Inc(BaseSkills[skTechnical]);
      CreateAndEquipHull(True, 270, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipScanner(True, Round(30 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[3]), 2, OwnerId);
      Inc(CargoGoods[t_Luxury].Count, SeededRandomIntRange(4, 6, Galaxy.RandomState));
      Inc(CargoGoods[t_Luxury].TotalCost, CargoGoods[t_Luxury].Count * GetLocationGoodsEntry(t_Luxury)^.PurchasePrice);
      RefreshDerivedStats;
    end;
    8:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 1.8, 2.5) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(5, 15, RandomState), [oiFei, oiGaal]);
      Inc(BaseSkills[skTechnical], 2);
      CreateAndEquipHull(True, 260, 1, OwnerId);
      Hull.HullPoints := RoundAndTruncateToTens(RandomFloatRange(0.5, 0.7) * Hull.HullPoints);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 2, oiFei);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 1, oiGaal);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_GravitonBeamer, True, Round(WeaponInfo[t_GravitonBeamer].Weight * ItemSizeFactors[3]), 2, oiGaal);
      RefreshDerivedStats;
    end;
    9:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.6, 0.8) * InitialMoney));
      ChangePlanetRelations(nil, rcmRaiseTo, 70, [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
      Inc(BaseSkills[skLeadership], 2);
      CreateAndEquipHull(True, 290, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 3, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[4]), 1, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[3]), 4, OwnerId);
      RefreshDerivedStats;
    end;
    10:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.5) * InitialMoney));
      Inc(BaseSkills[skTechnical], 2);
      Inc(BaseSkills[skTrader]);
      Inc(BaseSkills[skCharm]);
      CreateAndEquipHull(True, 320, 1, OwnerId);
      Hull.HullPoints := RoundAndTruncateToTens(RandomFloatRange(0.2, 0.4) * Hull.HullPoints);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[4]), 2, OwnerId);
      FuelTanks.ConditionPercent := NextRandomIntRange(10, 40, RandomState);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[3]), 2, OwnerId);
      Engine.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[3]), 1, OwnerId);
      Radar.ConditionPercent := NextRandomIntRange(10, 50, RandomState);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CargoHook.ConditionPercent := NextRandomIntRange(20, 80, RandomState);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[3]), 1, OwnerId);
      Weapons[0].ConditionPercent := NextRandomIntRange(10, 75, RandomState);
      // Native uses the wrong weapon's weight.
      CreateAndEquipWeapon(t_ZipGun, True, Round(WeaponInfo[t_GravitonBeamer].Weight * ItemSizeFactors[4]), 1, OwnerId);
      Weapons[1].ConditionPercent := NextRandomIntRange(0, 15, RandomState);
      RefreshDerivedStats;
    end;
    11:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.4, 0.8) * InitialMoney));
      ChangePlanetRelations(nil, rcmDecrease, NextRandomIntRange(50, 60, RandomState), [oiMaloc, oiPeople, oiGaal]);
      ChangePlanetRelations(nil, rcmDecrease, NextRandomIntRange(60, 70, RandomState), [oiFei]);
      ChangePlanetRelations(nil, rcmRaiseTo, NextRandomIntRange(80, 90, RandomState), [oiPeleng]);
      Inc(BaseSkills[skLeadership]);
      CreateAndEquipHull(True, 280, 2, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 2, oiGaal);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[1]), 3, OwnerId);
      Inc(CargoGoods[t_Narcotics].Count, NextRandomIntRange(15, 25, RandomState));
      Inc(CargoGoods[t_Narcotics].TotalCost, CargoGoods[t_Narcotics].Count * GetLocationGoodsEntry(t_Narcotics)^.PurchasePrice);
      RefreshDerivedStats;
    end;
    12:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.8, 1.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmRaiseTo, 85, [oiMaloc, oiPeople, oiFei, oiGaal]);
      ChangePlanetRelations(nil, rcmCapAt, 5, [oiPeleng]);
      Inc(BaseSkills[skTechnical]);
      CreateAndEquipHull(True, 290, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 2, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[1]), 2, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 3, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_GravitonBeamer, True, Round(WeaponInfo[t_GravitonBeamer].Weight * ItemSizeFactors[2]), 1, OwnerId);
      RefreshDerivedStats;
    end;
    13:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 1.0, 1.2) * InitialMoney));
      ChangePlanetRelations(nil, rcmCapAt, NextRandomIntRange(5, 15, RandomState), [oiFei]);
      Inc(BaseSkills[skTrader]);
      CreateAndEquipHull(True, 270, 2, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 1, OwnerId);
      Inc(CargoGoods[t_Medicine].Count, NextRandomIntRange(24, 47, RandomState));
      Inc(CargoGoods[t_Medicine].TotalCost, CargoGoods[t_Medicine].Count * GetLocationGoodsEntry(t_Medicine)^.PurchasePrice);
      RefreshDerivedStats;
    end;
    14:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.9, 1.5) * InitialMoney));
      ChangePlanetRelations(nil, rcmDecrease, NextRandomIntRange(60, 70, RandomState), [oiMaloc, oiPeople, oiFei]);
      ChangePlanetRelations(nil, rcmDecreaseWithFloor20, NextRandomIntRange(40, 60, RandomState), [oiPeleng, oiGaal]);
      Inc(BaseSkills[skAccuracy], 2);
      Inc(BaseSkills[skMobility], 2);
      CreateAndEquipHull(True, 280, 1, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 2, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[2]), 2, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 1, OwnerId);
      CreateAndEquipWeapon(t_IndustrialLaser, True, Round(WeaponInfo[t_IndustrialLaser].Weight * ItemSizeFactors[2]), 1, OwnerId);
      RefreshDerivedStats;
    end;
    15:
    begin
      SetMoney(RoundAndTruncateToTens(SeededRandomFloatRange(Galaxy.GenerationSeed, 0.3, 0.4) * InitialMoney));
      ChangePlanetRelations(nil, rcmRaiseTo, NextRandomIntRange(65, 95, RandomState), [oiMaloc, oiPeleng, oiPeople, oiFei, oiGaal]);
      Inc(BaseSkills[skCharm], 4);
      Inc(BaseSkills[skLeadership], 2);
      CreateAndEquipHull(True, 250, 2, OwnerId);
      CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[5]), 1, OwnerId);
      CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[1]), 1, OwnerId);
      CreateAndEquipCargoHook(True, Round(40 * ItemSizeFactors[3]), 1, OwnerId);
      CreateAndEquipWeapon(t_PhotonGun, True, Round(WeaponInfo[t_PhotonGun].Weight * ItemSizeFactors[2]), 1, OwnerId);
      RefreshDerivedStats;
    end;
  end;
  Hull.Weight := RoundAndTruncateToTens(Hull.Weight / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  RefreshDerivedStats;
  while CargoFreeSpace < 20 / DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor do begin
    Inc(Hull.Weight, 10);
    RefreshDerivedStats;
  end;
  Inc(Hull.Weight, DifficultyModifiers[Galaxy.Difficulty].StartingHullCapacityBonus);
  Hull.HullPoints := Hull.Weight;
  RefreshDerivedStats;
  Player.RefreshAssignedItemSlots;
end;
{ @end $51308C }

{ @routine $5149BC TPlayer_NextDay }
procedure TPlayer.NextDay;
var I: Integer; Ship: TShip; Item: TEquipment;
begin
  inherited NextDay;
  if Money < 0 then SetMoney(0)
  else if Money > 100000000 then SetMoney(100000000);
  if InNormalSpace then
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if Ship.InNormalSpace then Ship.DaysSincePlayerSeen := 0;
    end;
  for I := 0 to Inventory.Count - 1 do
  begin
    Item := TEquipment(Inventory[I]);
    if (Item.ItemType = t_Engine) and not Item.EquippedFlag then
    begin
      if (Item as TEngine).OutputPercent + 10 > 100 then (Item as TEngine).OutputPercent := 100
      else Inc((Item as TEngine).OutputPercent, 10);
    end;
  end;
end;
{ @end $5149BC }

{ @routine $514AA4 TPlayer_ProcessFinalScenarioWithdrawal }
procedure TPlayer.ProcessFinalScenarioWithdrawal;
var I, J: Integer; Star: TStar; Planet: TPlanet; Ship: TShip;
begin
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Planet.OwnerId = oiKling then Planet.OwnerId := RaceToOwner(Planet.RaceId);
    end;
    if Star.ControlFaction = sfKlissan then Star.ControlFaction := sfCoalition;
    if Star.Battle then Star.Battle := False;
    for J := Star.Ships.Count - 1 downto 0 do
    begin
      Ship := TShip(Star.Ships[J]);
      if (Ship.OwnerId = oiKling) and Ship.InNormalSpace then
      begin
        Ship.ClearWeaponTargets(nil);
        Ship.OrderMove(Star.Position, False);
      end;
    end;
  end;
  // Native still tests this result after the withdrawal loop.
  if Player.InNormalSpace then begin end;
end;
{ @end $514AA4 }

{ @routine $514B94 TPlayer_CanRepairArtefactsAtLocation }
function TPlayer.CanRepairArtefactsAtLocation: Boolean;
begin
  Result := (DockedTo <> nil) and (DockedTo.ShipType in [t_PirateBase, t_ScientificBase]);
end;
{ @end $514B94 }

{ @routine $514BAC TPlayer_RechargeTransmittersFromKlissan }
procedure TPlayer.RechargeTransmittersFromKlissan(Ship: TShip);
var I: Integer; Item: TItem;
begin
  if (Ship as TKling).KlingType in [ktKatauri..ktMutenok] then Exit;
  for I := 0 to Player.Artefacts.Count - 1 do
  begin
    Item := TItem(Player.Artefacts[I]);
    if Item.ItemType = t_ArtefactTransmitter then
      (Item as TArtefactTransmitter).Charges := Min(100, Round((Item as TArtefactTransmitter).Charges +
        RemapClampedAlternate(PointDistance(Player.Position, Ship.Position), 100, 1000, 5, 0) *
        RemapClampedAlternate(Ord((Ship as TKling).KlingType), 1, 5, 5, 1)));
  end;
end;
{ @end $514BAC }

{ @routine $514CDC TPlayer_CountStoredItemUnits }
function TPlayer.CountStoredItemUnits(Planet: TPlanet; Kind: TItemType): Integer;
var
  I: Integer;
  Entry: PStorageEntry;
  UnusedManaged: WideString;
begin
  Result := 0;
  for I := 0 to StorageEntries.Count - 1 do
  begin
    Entry := StorageEntries[I];
    if (Planet = nil) or (Planet = Entry.Planet) then
      if Entry.Item.ItemType = Kind then Inc(Result, Entry.Item.Weight);
  end;
end;
{ @end $514CDC }

{ @routine $514D60 TPlayer_CountPartnersInNormalSpace }
function TPlayer.CountPartnersInNormalSpace: Byte;
var I: Integer; Ship: TShip;
begin
  Result := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := TShip(CurrentStar.Ships[I]);
    if (Ship.PartnerShip = Self) and Ship.InNormalSpace then Inc(Result);
  end;
end;
{ @end $514D60 }

{ @routine $514DB0 TPlayer_ResetCounterAfterNodeDeposit }
procedure TPlayer.ResetCounterAfterNodeDeposit;
begin
  UnresolvedCounter1F4 := 0;
end;
{ @end $514DB0 }

{ @routine $514DBC TPlayer_GetShipRatingComparison }
function TPlayer.GetShipRatingComparison(Ship: TShip): TStandardCount;
begin
  Result := scZero;
  if Ship.ShipType <> t_Ranger then Exit;
  begin
    Galaxy.RefreshRangerRatingPlaces;
    with Ship as TRanger do
      case Round(RemapClamped(TotalExperience, Player.PlaceInRating / 3,
        3 * Player.PlaceInRating, 0, 100)) of
        0..20: Result := scMini;
        21..40: Result := scSmall;
        41..60: Result := scAverage;
        61..80: Result := scBig;
        81..100: Result := scHuge;
      else RaiseWideMessage('Ошибка в рейтинге корабля в сравнении с игроком');
      end;
  end;
end;
{ @end $514DBC }

{ @routine $514F08 TPlayer_GetShipRankComparison }
function TPlayer.GetShipRankComparison(Ship: TShip): TStandardCount;
var Normal: TNormalShip;
begin
  Result := scZero;
  if Ship is TNormalShip then begin
    Normal := Ship as TNormalShip;
    case Ord(Normal.Rank) - Ord(Player.Rank) of
      -7..-2: Result := scMini;
      -1: Result := scSmall;
      0: Result := scAverage;
      1: Result := scBig;
      2..7: Result := scHuge;
    else RaiseWideMessage('Ошибка в ранк корабля в сравнении с игроком');
    end;
  end;
end;
{ @end $514F08 }

{ @routine $515000 TPlayer_GetShipStrengthComparison }
function TPlayer.GetShipStrengthComparison(Ship: TShip): TStandardCount;
begin
  Result := scZero;
  case Integer(Round(RemapClamped(Ship.Strength, Player.Strength / 3, Player.Strength * 3, 0, 100))) of
    0..20: Result := scMini;
    21..40: Result := scSmall;
    41..60: Result := scAverage;
    61..80: Result := scBig;
    81..100: Result := scHuge;
  else RaiseWideMessage('Ошибка в сила корабля в сравнении с игроком');
  end;
end;
{ @end $515000 }

{ @routine $5151A8 TPlayer_RefreshStorageMessage }
procedure TPlayer.RefreshStorageMessage;
var I, J: Integer; Planet: TPlanet; Text: WideString; Entry: PStorageEntry;

  // @nested $5150F8 CompareStorageEntries
  function CompareStorageEntries(First, Second: PStorageEntry): Integer; // @addr $5150F8
  begin
    if First.Planet.CurrentStar.Id < Second.Planet.CurrentStar.Id then begin Result := -1; Exit; end
    else if First.Planet.CurrentStar.Id >
      Second.Planet.CurrentStar.Id then begin Result := 1; Exit; end;
    if First.Planet.Id < Second.Planet.Id then begin Result := -1; Exit; end
    else if First.Planet.Id > Second.Planet.Id then begin Result := 1; Exit; end;
    if Integer(First.Item.ItemType) < Integer(Second.Item.ItemType) then begin Result := -1; Exit; end
    else if Integer(First.Item.ItemType) >
      Integer(Second.Item.ItemType) then begin Result := 1; Exit; end;
    if First.Item.Cost < Second.Item.Cost then begin Result := -1; Exit; end
    else if First.Item.Cost > Second.Item.Cost then begin Result := 1; Exit; end
    else Result := 0;
  end;

begin
  for I := 0 to StorageEntries.Count - 2 do
    for J := I + 1 to StorageEntries.Count - 1 do
      if CompareStorageEntries(StorageEntries[I], StorageEntries[J]) > 0 then
      begin
        Entry := StorageEntries[I];
        StorageEntries[I] := StorageEntries[J];
        StorageEntries[J] := Entry;
      end;
  if StorageEntries.Count <= 0 then
  begin
    if FindPlayerBubbleByKey('sys_storage') <> nil then
      AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, LocalizedText('FormGov.Storage.Empty'), 'sys_storage');
  end
  else
  begin
    Planet := nil;
    Text := WrapTextInColor(LocalizedText('FormGov.Storage.Main'), GreenColorTag) +
      #13#10 + '---------------------------' + #13#10;
    for I := 0 to StorageEntries.Count - 1 do
    begin
      Entry := StorageEntries[I];
      if Planet <> Entry.Planet then
      begin
        if Text <> '' then Text := Text + ' ' + #13#10;
        Text := Text + WrapTextInColor(Entry.Planet.GetFullName(' ') + ':', HighlightColorTag) + #13#10;
      end;
      Planet := Entry.Planet;
      Text := Text + '- ' + Entry.Item.GetDisplayName + ' [' +
        WrapTextInColor(IntToStr(Entry.Item.Weight), GreenColorTag) + ']' + #13#10;
    end;
    AddOrUpdatePlayerBubble(pmUser, Galaxy.CurrentTurn, Text, 'sys_storage');
  end;
end;
{ @end $5151A8 }

end.

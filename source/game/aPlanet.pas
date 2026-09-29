unit aPlanet;
// Unit bracket (inferred): CODE 0x005BF4A0..0x005C8C8B; inclusive evidence, not full bounds.
interface
// Create $5BF6FC / Destroy $5BF7BC and SaveToBuffer $5C1A68.
uses aItem, EC_Struct, Classes, aConst, aGalaxy, aMyFunction, SE_Planet, SE_Sputnik, aEFilm, EC_Buf;
type
  // VMT $5BF4A0. Save/load embeds the scene state and a separate orbit angle.
  TSputnik = class(TObjectEx) // @size $10
  public
    Id: Cardinal; // @offset $04
    Graphic: TSputnikSE; // @offset $08 Owned; freed directly by Destroy.
    FilmObject: TEFilmObj; // @offset $0C Borrowed from the turn film.
    constructor Create; // @addr $5BF560
    destructor Destroy; override; // @addr $5BF5AC
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5BF5E4
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5BF630
  end;
  TPlanetGoodsEntry = packed record // @size $10
    Count: Integer; // @offset $00
    PriceState: Single; // @offset $04
    PurchasePrice: Integer; // @offset $08
    BaseSalePrice: Integer; // @offset $0C
  end;
  PPlanetGoodsEntry = ^TPlanetGoodsEntry;
  TPlanet = class(TObjectEx) // @size $158
  public
    function GetCivilInfoText: WideString; // @addr $5C65A8
    function GetFullName(Separator: WideString): WideString; // @addr $5C491C
    function GetRelationLevelToShip(Ship: TObject): TRelationLevel; // @addr $5C6538
    function FindUnchartedNeighborConstellation: TObject; // @addr $5C4E08
    procedure CollectScriptDialogChoices(Choices: TStringsEC); // @addr $5C4814
    function GetNativeRaceName: WideString; // @addr $5C4D3C
    function GetGovernmentName: WideString; // @addr $5C4D14
    function GetInfoText: WideString; // @addr $5C49C0
    function HasHostileShipsInSystem: Boolean; // @addr $5C68B8
    procedure RefreshEquipmentShopInventory; // @addr $5C6908
    function RequestDialog: Boolean; // @addr $5C2D9C Native leaves TalkScripted set, including failed waits.
    procedure HandleAsteroidCollision(Asteroid: TObject); // @addr $5C4810 Empty; the caller passes the colliding TAsteroid.
    procedure NextDay; // @addr $5C2370
    procedure UpdateMarketState; // @addr $5C2E38
    function BuildGovernmentGreeting: WideString; // @addr $5C7834
    function CalculateBasePopulation: Integer; // @addr $5C4D68
    function CountPlanetsOfSameRace: Integer; // @addr $5C4DA0 Counts uninhabited planets separately.
    procedure BoostInventionLevels(Count: Integer); // @addr $5C4EF4
    function SpawnRanger: TObject; // @addr $5C52F8
    function SpawnTransport(Kind: THullType): TObject; // @addr $5C53B0
    function SpawnPirate: TObject; // @addr $5C5464
    function SpawnWarrior: TObject; // @addr $5C54E4
    function SpawnWeightedKlissan: TObject; // @addr $5C5664
    function SpawnKlissan(Kind: TKlingType): TObject; // @addr $5C5AAC
    function CalculateEquipmentShopTargetCount: Integer; // @addr $5C70C0
    function CountEquipmentShopItemsInBucket(ItemType: TItemType): Integer; // @addr $5C7180
    function RemoveSimilarEquipmentShopItem(Item: TEquipment): Boolean; // @addr $5C71DC
    procedure AdvanceInventionProgress; // @addr $5C5080
    procedure SelectCurrentInvention; // @addr $5C4F1C
    procedure InitializeFilmState(StepIndex: Integer; RecordFilm: Boolean); // @addr $5C2ABC
    procedure AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean); // @addr $5C2C34
    procedure InitGenerated(Star: TStar; TotalPlanets, Inhabited: Integer); // @addr $5BF870
    Id: Cardinal; // @offset $04
    GenerationSeed: Cardinal; // @offset $08
    RandomState: Cardinal; // @offset $0C
    SpriteTemplateIndex: Integer; // @offset $10 Template de-duplication in InitGenerated.
    Name: WideString; // @offset $14
    CurrentStar: TStar; // @offset $18
    Orbit: TPolarPoint; // @offset $20 Degrees/radius; GetPosition passes the complete record to PolarToPoint.
    ReservedSaveValue: Integer; // @offset $30 Serialized by SaveToBuffer/LoadFromBuffer.
    Radius: Integer; // @offset $34 Native star map-diameter calculation $5FC2F4.
    OrbitalVelocity: Double; // @offset $38 Serialized as Single.
    InventionLevels: array[TInventionTrack] of Byte; // @offset $40
    CurrentInvention: TInventionTrack; // @offset $68
    CurrentInventionPoints: Single; // @offset $6C
    ResearchLevelPercent: Byte; // @offset $70
    ResearchLevelStep: Byte; // @offset $71
    Population: Integer; // @offset $74
    Economy: TPlanetEconomy; // @offset $78
    Money: Integer; // @offset $7C
    OwnerId: TOwnerId; // @offset $80
    IsCoalitionOwned: Boolean; // @offset $81
    RaceId: TRaceId; // @offset $82
    Government: TPlanetGovernment; // @offset $83
    UnresolvedValue84: Byte; // @offset $84 Read through ReadByteValue and saved at $5C1A68.
    Goods: array[TGoodsIndex] of TPlanetGoodsEntry; // @offset $8C
    GoodsScarcityTicks: array[TGoodsIndex] of Byte; // @offset $10C
    GoodsSurplusTicks: array[TGoodsIndex] of Byte; // @offset $114
    TextQuestId: Integer; // @offset $11C
    RangerRelations: TObjectList; // @offset $120 Immediate relation scores; native destructor empties but leaks the list.
    EquipmentShop: TObjectList; // @offset $124 Owns TItem stock.
    Warriors: TObjectList; // @offset $128 Garrison roster.
    HomeRangerCount: Integer; // @offset $12C
    HomeTransportCount: Integer; // @offset $130
    HomePirateCount: Integer; // @offset $134 Decremented by TPirate.Destroy $58F3D0.
    HomeWarriorCount: Integer; // @offset $138 Decremented by TWarrior.Destroy $4E1934.
    HomeKlissanCount: Integer; // @offset $13C Incremented by SpawnKlissan $5C5AAC.
    GraphicRadius: Integer; // @offset $140
    Graphic: TPlanetSE; // @offset $144 Owned.
    Satellites: TObjectList; // @offset $148 Owns TSputnik entries.
    LastFilmPosition: TPoint; // @offset $14C Integer position used to suppress unchanged film commands.
    FilmObject: TEFilmObj; // @offset $154 Borrowed from PrimaryFilm.

    function GetRangerRelationByIndex(Index: Integer): Integer; // @addr $5C6134
    procedure ChangeRelationToRanger(Ranger: TObject; Delta: Integer); // @addr $5C62B0
    procedure TriggerGovernmentRevolution; // @addr $5C3380
    procedure TryTriggerEconomicEvent; // @addr $5C3748
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5C1A68
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5C1E48
    procedure ResolveLoadedReferences; // @addr $5C230C
    procedure InitKlissanSpawnProxy(Star: TStar); // @addr $5C1A38
    function PredictPosition(StepsAhead: Integer): TPointF; // @addr $5C2D54
    procedure UpdateOwnerFlags; // @addr $5C2E14
    procedure StartGoodsDecay(Enabled: Boolean; GoodsMask: TItemTypeMask); // @addr $5C7490 @ida "void __usercall $name(TPlanet *Self@<eax>, bool Enabled@<dl>, TItemTypeMask *GoodsMask@<ecx>);"
    procedure StartGoodsUpsurge(Enabled: Boolean; GoodsMask: TItemTypeMask); // @addr $5C75B0 @ida "void __usercall $name(TPlanet *Self@<eax>, bool Enabled@<dl>, TItemTypeMask *GoodsMask@<ecx>);"
    function GetRelationLevelTextToShip(Ship: TObject): WideString; // @addr $5C6578
    procedure SetRelationLevelToRanger(Ranger: TObject; Level: TRelationLevel); // @addr $5C6150
    function RelationToShip(Ship: TObject): TNonRangerRelation; // @addr $5C6388
    function GetPosition: TPointF; // @addr $5C49AC
    function FindNearestPlanetByOwnerMask(OwnerMask: TOwnerSet): TObject; // @addr $5C4E68
    function GenerateShipForScriptGroup(Group: TObject): TObject; // @addr $5C5AE0
    constructor Create; // @addr $5BF6FC
    destructor Destroy; override; // @addr $5BF7BC
  end;
var
  EconomicEventChance: Integer = 4; // @addr $6188E8

implementation

// @unit-initialization $5C8C84
// @unit-finalization $5C8C54

uses Windows, aTransport, aPirate, aWarrior, aKling, aPlayer, EC_BlockPar, Math, aRanger, EC_Str, Globals, aShip, aItem, SysUtils, SE_Process, aConst, GlobalsV, aScript;

{ @routine $5BF560 TSputnik_Create }
constructor TSputnik.Create;
begin
  inherited Create;
  Id := Galaxy.NextSputnikId;
  Inc(Galaxy.NextSputnikId);
end;
{ @end $5BF560 }

{ @routine $5BF5AC TSputnik_Destroy }
destructor TSputnik.Destroy;
begin
  if Graphic <> nil then begin Graphic.Free; Graphic := nil; end;
  inherited Destroy;
end;
{ @end $5BF5AC }

{ @routine $5BF5E4 TSputnik_SaveToBuffer }
procedure TSputnik.SaveToBuffer(Buffer: TBufEC);
var State: TBufEC;
begin
  Buffer.AddDWord(Id);
  Buffer.AddWideStringZ(Graphic.GraphKey);
  State := Graphic.BuildStateBuffer;
  Buffer.AddBuffer(State);
  State.Free;
  Buffer.AddSingle(Graphic.OrbitAngle);
end;
{ @end $5BF5E4 }

{ @routine $5BF630 TSputnik_LoadFromBuffer }
procedure TSputnik.LoadFromBuffer(Buffer: TBufEC);
var State: TBufEC;
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextSputnikId <= Id then Galaxy.NextSputnikId := Id + 1;
  Graphic := TSputnikSE.Create(Buffer.ReadWideString, Classes.Point(0, 0));
  State := TBufEC.Create;
  Buffer.ReadLengthPrefixedBuffer(State);
  Graphic.LoadStateBuffer(State);
  State.Free;
  Graphic.OrbitAngle := Buffer.GetSingle;
end;
{ @end $5BF630 }

{ @routine $5BF6FC TPlanet_Create }
constructor TPlanet.Create;
begin
  inherited Create;
  Id := Galaxy.NextPlanetId;
  Inc(Galaxy.NextPlanetId);
  GenerationSeed := NextRandomIntRange(100000, MaxInt, Galaxy.RandomState);
  RandomState := GenerationSeed;
  Warriors := TObjectList.Create;
  RangerRelations := TObjectList.Create;
  EquipmentShop := TObjectList.Create;
  Satellites := TObjectList.Create;
  Graphic := nil;
end;
{ @end $5BF6FC }

{ @routine $5BF7BC TPlanet_Destroy }
destructor TPlanet.Destroy;
var I: Integer;
begin
  Satellites.Free;
  Warriors.Free;
  if Self <> KlissanSpawnPlanet then
    Galaxy.Planets.Delete(Galaxy.Planets.IndexOf(Self));
  // Native behavior: delete the immediate scores but do not free the list.
  for I := RangerRelations.Count - 1 downto 0 do RangerRelations.Delete(I);
  if Graphic <> nil then
  begin
    Graphic.Free;
    Graphic := nil;
  end;
  EquipmentShop.Free;
  EquipmentShop := nil;
  inherited Destroy;
end;
{ @end $5BF7BC }

{ @routine $5BF870 TPlanet_InitGenerated }
procedure TPlanet.InitGenerated(Star: TStar; TotalPlanets, Inhabited: Integer);
var
  OtherPlanet, PreviousPlanet: TPlanet;
  Invention: Byte; Good: TGoodsIndex;
  Quantity, Count, I, Part, LeastOwnerPlanetCount, ExistingRing: Integer;
  PreviousExtent, SatelliteRadius, UnusedRadius, MinOrbitRadius, MaxOrbitRadius: Double;
  ItemOwner, OwnerLoop: TOwnerId;
  BlockName: WideString;
  Satellite: TSputnik;
  SatelliteCount: Integer;
  SatelliteConfig: TBlockParEC;
  Item: TEquipment;
  ItemType, WeaponType: TItemType;
  GovernmentRoll: Byte;
  WeaponKind: Integer;
  TemplateAvailable, AllowRing, IsSolar: Boolean;
begin
  CurrentStar := Star;
  if Inhabited = 0 then IsSolar := True
  else IsSolar := False;
  if IsSolar then
  begin
    RaceId := raPeople;
    Name := LanguageDataConfig.GetBlock('PlanetName').GetBlock('Solar').GetParamValue(Star.Planets.Count);
    OrbitalVelocity := (NextRandomIntRange(1, 1, RandomState) * 2 - 1) * (4.5 - Star.Planets.Count / 2);
    Orbit.AngleDegrees := NextRandomIntRange(0, 359, RandomState);
    GraphicRadius := PlanetSpaceTemplates[Star.Planets.Count].Radius;
    Graphic := TPlanetSE.CreateEmpty;
    PlanetSpaceTemplates[Star.Planets.Count].SpaceObject.CopyTo(Graphic);
    Radius := GraphicRadius;
    Graphic.SetPosition(PolarToPoint(Orbit));
    Graphic.SetRotationTimerInterval(SeededRandomIntRange(60, 100, Star.Planets.Count * 3 + 47));
    Graphic.SetSurfaceMapStep(-1);
    Graphic.OrbitalVelocity := OrbitalVelocity;
    case Star.Planets.Count of
      0:
        begin
          Orbit.Radius := Radius + Star.SystemRadius + 175;
          OwnerId := oiNone;
          Government := pgAnarchy;
          Economy := peAgriculture;
        end;
      1:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200;
          OwnerId := oiPeople;
          Government := pgDemocracy;
          Economy := peAgriculture;
          Population := CalculateBasePopulation;
        end;
      2:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200;
          OwnerId := oiPeople;
          Government := pgDemocracy;
          Economy := peIndustrial;
          Population := 1000000;
          Satellite := TSputnik.Create;
          Satellites.Add(Satellite);
          MinOrbitRadius := Round(Radius * 1.3);
          Satellite.Graphic := TSputnikSE.Create('Sputnik.Moon', Classes.Point(0, 0));
          Satellite.Graphic.DepthOrder := 0;
          Satellite.Graphic.OrbitCenter := GetPosition;
          Satellite.Graphic.OrbitRadius := MinOrbitRadius;
          Satellite.Graphic.OrbitAngle := 180;
          Satellite.Graphic.OrbitAngleStep := 1.1;
          Satellite.Graphic.OrbitTimerInterval := 30;
          Satellite.Graphic.OrbitInclination := 70;
          Satellite.Graphic.OrbitRotation := 250;
          Satellite.Graphic.MinDisplayRadius := Round(GeneratedSatelliteBaseRadius * 1.2);
          Satellite.Graphic.MaxDisplayRadius := Round(GeneratedSatelliteBaseRadius * 1.5);
          Satellite.Graphic.RotationTimerInterval := 25;
          Satellite.Graphic.SurfaceMapStep := 1;
        end;
      3:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200 +
            Round(200 - RemapClamped(Star.Planets.Count, 1, 6, 0, 200));
          OwnerId := oiPeople;
          Government := pgDictatorship;
          Economy := peIndustrial;
          Population := 100000;
          SatelliteCount := 2;
          for I := 0 to SatelliteCount - 1 do
          begin
            Satellite := TSputnik.Create;
            Satellites.Add(Satellite);
            MinOrbitRadius := Round(Radius * 1.3);
            MaxOrbitRadius := Radius * 2;
            Satellite.Graphic := TSputnikSE.Create('Sputnik.Mars' + IntToStr(I), Classes.Point(0, 0));
            Satellite.Graphic.DepthOrder := I;
            Satellite.Graphic.OrbitCenter := GetPosition;
            Satellite.Graphic.OrbitRadius := Round(RemapClamped(I, 0, 3, MinOrbitRadius, MaxOrbitRadius));
            Satellite.Graphic.OrbitAngle := NextRandomIntRange(0, 360, RandomState);
            Satellite.Graphic.OrbitAngleStep := 1 + NextRandomUnitFloat(RandomState);
            Satellite.Graphic.OrbitTimerInterval := 30;
            Satellite.Graphic.OrbitInclination := NextRandomIntRange(50, 120, RandomState);
            Satellite.Graphic.OrbitRotation := NextRandomIntRange(200, 350, RandomState);
            Satellite.Graphic.MinDisplayRadius := GeneratedSatelliteBaseRadius;
            Satellite.Graphic.MaxDisplayRadius := Round(Satellite.Graphic.MinDisplayRadius * 1.5);
            Satellite.Graphic.RotationTimerInterval := 25;
            Satellite.Graphic.SurfaceMapStep := 1;
          end;
        end;
      4:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200 +
            Round(200 - RemapClamped(Star.Planets.Count, 1, 6, 0, 200));
          OwnerId := oiNone;
          Government := pgAnarchy;
          Economy := peAgriculture;
          SatelliteCount := 4;
          for I := 0 to SatelliteCount - 1 do
          begin
            Satellite := TSputnik.Create;
            Satellites.Add(Satellite);
            MinOrbitRadius := Round(Radius * 1.3);
            MaxOrbitRadius := Radius * 2;
            Satellite.Graphic := TSputnikSE.Create('Sputnik.' +
              GameDataConfig.GetBlockByPath('SE.Sputnik').GetBlockNameByIndex(NextRandomIntRange(0,
                GameDataConfig.GetBlockByPath('SE.Sputnik').GetBlockCount - 1, RandomState)), Classes.Point(0, 0));
            Satellite.Graphic.DepthOrder := I;
            Satellite.Graphic.OrbitCenter := GetPosition;
            Satellite.Graphic.OrbitRadius := Round(RemapClamped(I, 0, 3, MinOrbitRadius, MaxOrbitRadius));
            Satellite.Graphic.OrbitAngle := NextRandomIntRange(0, 360, RandomState);
            Satellite.Graphic.OrbitAngleStep := 1 + NextRandomUnitFloat(RandomState);
            Satellite.Graphic.OrbitTimerInterval := NextRandomIntRange(30, 35, RandomState);
            Satellite.Graphic.OrbitInclination := NextRandomIntRange(50, 120, RandomState);
            Satellite.Graphic.OrbitRotation := NextRandomIntRange(200, 350, RandomState);
            Satellite.Graphic.MinDisplayRadius := GeneratedSatelliteBaseRadius;
            Satellite.Graphic.MaxDisplayRadius := Round(RemapClamped(NextRandomUnitFloat(RandomState) / 1,
              0, 1, Satellite.Graphic.MinDisplayRadius * 1.3,
              Min(MaximumSatelliteTemplateRadius, Satellite.Graphic.MinDisplayRadius * 2)));
            Satellite.Graphic.RotationTimerInterval := 25;
            Satellite.Graphic.SurfaceMapStep := 1;
          end;
        end;
      5:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200 +
            Round(200 - RemapClamped(Star.Planets.Count, 1, 6, 0, 200));
          OwnerId := oiNone;
          Government := pgRepublic;
          Economy := peMixed;
          Population := 120000;
          Graphic.SetRingKind(22);
        end;
      6:
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200 +
            Round(200 - RemapClamped(Star.Planets.Count, 1, 6, 0, 200));
          OwnerId := oiNone;
          Government := pgAnarchy;
          Economy := peAgriculture;
          SatelliteCount := 1;
          for I := 0 to SatelliteCount - 1 do
          begin
            Satellite := TSputnik.Create;
            Satellites.Add(Satellite);
            MinOrbitRadius := Round(Radius * 1.3);
            MaxOrbitRadius := Radius * 2;
            Satellite.Graphic := TSputnikSE.Create('Sputnik.' +
              GameDataConfig.GetBlockByPath('SE.Sputnik').GetBlockNameByIndex(NextRandomIntRange(0,
                GameDataConfig.GetBlockByPath('SE.Sputnik').GetBlockCount - 1, RandomState)), Classes.Point(0, 0));
            Satellite.Graphic.DepthOrder := I;
            Satellite.Graphic.OrbitCenter := GetPosition;
            Satellite.Graphic.OrbitRadius := Round(RemapClamped(I, 0, 3, MinOrbitRadius, MaxOrbitRadius));
            Satellite.Graphic.OrbitAngle := NextRandomIntRange(0, 360, RandomState);
            Satellite.Graphic.OrbitAngleStep := 1 + NextRandomUnitFloat(RandomState);
            Satellite.Graphic.OrbitTimerInterval := 30;
            Satellite.Graphic.OrbitInclination := NextRandomIntRange(50, 120, RandomState);
            Satellite.Graphic.OrbitRotation := NextRandomIntRange(1, 359, RandomState);
            Satellite.Graphic.MinDisplayRadius := GeneratedSatelliteBaseRadius;
            Satellite.Graphic.MaxDisplayRadius := Round(RemapClamped(NextRandomUnitFloat(RandomState) / 1,
              0, 1, MaximumSatelliteTemplateRadius / 2, MaximumSatelliteTemplateRadius));
            Satellite.Graphic.RotationTimerInterval := 25;
            Satellite.Graphic.SurfaceMapStep := 1;
          end;
        end;
    end;
  end
  else
  begin
      Count := 0;
      for I := 0 to Star.Planets.Count - 1 do
      begin
        PreviousPlanet := TPlanet(Star.Planets[I]);
        if PreviousPlanet.OwnerId <> oiNone then Inc(Count);
      end;
      if Inhabited = Count then OwnerId := oiNone
      else if (TotalPlanets - Star.Planets.Count <= Inhabited - Count) or
              (NextRandomUnitFloat(RandomState) < 0.7) or
              ((aGalaxy.Galaxy.Stars.IndexOf(Star) < 5) and (Star.Planets.Count = 0)) then
      begin
        case aGalaxy.Galaxy.FindConstellationIndexForStar(CurrentStar) of
          0, 5: begin OwnerId := oiMaloc; RaceId := raMaloc; end;
          1, 6: begin OwnerId := oiPeleng; RaceId := raPeleng; end;
          2, 7: begin OwnerId := oiPeople; RaceId := raPeople; end;
          3, 8: begin OwnerId := oiFei; RaceId := raFei; end;
          4, 9: begin OwnerId := oiGaal; RaceId := raGaal; end;
        else
          case NextRandomIntRange(0, 4, RandomState) of
            0: begin OwnerId := oiMaloc; RaceId := raMaloc; end;
            1: begin OwnerId := oiPeleng; RaceId := raPeleng; end;
            2: begin OwnerId := oiPeople; RaceId := raPeople; end;
            3: begin OwnerId := oiFei; RaceId := raFei; end;
            4: begin OwnerId := oiGaal; RaceId := raGaal; end;
          end;
        end;
        if ((Count > 0) or (aGalaxy.Galaxy.FindConstellationIndexForStar(CurrentStar) > 4)) and
           ((NextRandomUnitFloat(RandomState) < 0.2) or (aGalaxy.Galaxy.FindConstellationIndexForStar(CurrentStar) > 9)) and
           (aGalaxy.Galaxy.Stars.IndexOf(Star) > 4) then
        begin
          ItemOwner := oiMaloc;
          LeastOwnerPlanetCount := 10000;
          for OwnerLoop := oiMaloc to oiGaal do
          begin
            if (CurrentStar.CountDistinctInhabitedPlanetOwners = 2) and
               (CurrentStar.CountPlanetsByOwner(OwnerLoop) = 0) then Continue;
            Count := 0;
            for I := 0 to aGalaxy.Galaxy.Planets.Count - 1 do
            begin
              PreviousPlanet := TPlanet(aGalaxy.Galaxy.Planets[I]);
              if PreviousPlanet.OwnerId = OwnerLoop then Inc(Count);
            end;
            if LeastOwnerPlanetCount > Count then
            begin
              LeastOwnerPlanetCount := Count;
              ItemOwner := OwnerLoop;
            end;
          end;
          OwnerId := ItemOwner;
          RaceId := OwnerToRace(ItemOwner);
        end;
      end
      else OwnerId := oiNone;
    BlockName := OwnerToSys(OwnerId);
    Quantity := CountPlanetsOfSameRace;
    Name := LanguageDataConfig.GetBlock('PlanetName').GetBlock(BlockName).GetParamValue(Quantity);
      Count := High(PlanetSpaceTemplates) + 1;
      Part := 0;
      Quantity := NextRandomIntRange(7, Count - 1, RandomState);
      while True do
      begin
        TemplateAvailable := True;
        Inc(Part);
        IncrementWrapped(Quantity, 7, Count - 1);
        if CountPlanetsOfSameRace = 0 then
        begin
          if PlanetSpaceTemplates[Quantity].Radius > 80 then Continue;
        end
        else if (CountPlanetsOfSameRace = 1) and (OwnerId <> oiNone) then
        begin
          if PlanetSpaceTemplates[Quantity].Radius < 100 then Continue;
        end
        else if Star.Planets.Count > 0 then
        begin
          PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
          if Abs(PlanetSpaceTemplates[Quantity].Radius - PreviousPlanet.Radius) < 11 then Continue;
        end;
        if Part < Count then
          for I := 0 to aGalaxy.Galaxy.Planets.Count - 1 do
          begin
            OtherPlanet := TPlanet(aGalaxy.Galaxy.Planets[I]);
            if (OtherPlanet.SpriteTemplateIndex = Quantity) and ((OtherPlanet.CurrentStar = Star) or
               (PointDistanceSquared(OtherPlanet.CurrentStar.Position, Star.Position) < 2500)) then
            begin
              TemplateAvailable := False;
              Break;
            end;
          end;
        if TemplateAvailable then Break;
      end;
      SpriteTemplateIndex := Quantity;
      GraphicRadius := PlanetSpaceTemplates[Quantity].Radius;
      Graphic := TPlanetSE.CreateEmpty;
      PlanetSpaceTemplates[Quantity].SpaceObject.CopyTo(Graphic);
        AllowRing := True;
      ExistingRing := 0;
      for I := 0 to Star.Planets.Count - 1 do begin
        PreviousPlanet := Star.Planets[I];
        if PreviousPlanet.Graphic.RingKind > 0 then begin
          if ExistingRing > 0 then AllowRing := False;
          ExistingRing := PreviousPlanet.Graphic.RingKind;
        end;
      end;
      if AllowRing and (NextRandomIntRange(0, 100, RandomState) < 80) and not IsSolar then begin
        if (NextRandomUnitFloat(RandomState) < 0.2) and (GraphicRadius > 90) then begin
          if not (ExistingRing in [20..21]) then Graphic.SetRingKind(NextRandomIntRange(20, 21, RandomState) + 1);
        end else if (OwnerId <> oiNone) and (GraphicRadius > 70) then
          if not (ExistingRing in [1..7]) then Graphic.SetRingKind(NextRandomIntRange(1, 7, RandomState));
      end else Graphic.SetRingKind(0);
      Radius := GraphicRadius;
      if Star.Planets.Count = 0 then Orbit.Radius := Radius + Star.SystemRadius + 350
      else
      begin
        PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
        Orbit.Radius := PreviousPlanet.Orbit.Radius + PreviousPlanet.Radius + Radius + 200 +
          Round(200 - RemapClamped(Star.Planets.Count, 1, 6, 0, 200));
      end;
      OrbitalVelocity := (NextRandomIntRange(0, 1, RandomState) * 2 - 1) * (4.5 - Star.Planets.Count / 2);
      Orbit.AngleDegrees := NextRandomIntRange(0, 359, RandomState);
      Graphic.SetPosition(PolarToPoint(Orbit));
      Graphic.SetRotationTimerInterval(NextRandomIntRange(60, 100, RandomState));
      Graphic.SetSurfaceMapStep(NextRandomIntRange(0, 1, RandomState) * 2 - 1);
      Graphic.OrbitalVelocity := OrbitalVelocity;
      SatelliteConfig := GameDataConfig.GetBlockByPath('SE.Sputnik');
      if Graphic.RingKind = 0 then MinOrbitRadius := Round(Radius * 1.3)
      else MinOrbitRadius := Round(Radius * 1.5);
      MaxOrbitRadius := Radius * 2;
      if Graphic.RingKind = 0 then SatelliteCount := NextRandomIntRange(1, 4, RandomState)
      else if Graphic.RingKind < 20 then SatelliteCount := NextRandomIntRange(0, 4, RandomState)
      else SatelliteCount := 0;
      if Star.Planets.Count > 0 then
      begin
        PreviousPlanet := TPlanet(Star.Planets[Star.Planets.Count - 1]);
        if PreviousPlanet.Satellites.Count > 0 then
        begin
          if Graphic.RingKind > 0 then SatelliteCount := 0
          else if OwnerId = oiNone then SatelliteCount := 0
          else SatelliteCount := Min(SatelliteCount, 1);
        end;
      end;
      PreviousExtent := 0;
      if SatelliteCount > 0 then
      for I := 0 to SatelliteCount - 1 do
      begin
        if SatelliteCount = 1 then SatelliteRadius := MinOrbitRadius
        else SatelliteRadius := Round(RemapClamped(I, 0, 3, MinOrbitRadius, MaxOrbitRadius));
        if (I <= 0) or (SatelliteRadius >= PreviousExtent) then
        begin
          Satellite := TSputnik.Create;
          Satellites.Add(Satellite);
          Satellite.Graphic := TSputnikSE.Create('Sputnik.' +
            SatelliteConfig.GetBlockNameByIndex(NextRandomIntRange(0, SatelliteConfig.GetBlockCount - 1, RandomState)),
            Classes.Point(0, 0));
          Satellite.Graphic.DepthOrder := I;
          Satellite.Graphic.OrbitCenter := GetPosition;
          if SatelliteCount = 1 then Satellite.Graphic.OrbitRadius := MinOrbitRadius
          else Satellite.Graphic.OrbitRadius := Round(RemapClamped(I, 0, 3, MinOrbitRadius, MaxOrbitRadius));
          Satellite.Graphic.OrbitAngle := NextRandomIntRange(0, 360, RandomState);
          Satellite.Graphic.OrbitAngleStep := 1 + NextRandomUnitFloat(RandomState);
          Satellite.Graphic.OrbitTimerInterval := NextRandomIntRange(28, 35, RandomState);
          Satellite.Graphic.OrbitInclination := NextRandomIntRange(50, 120, RandomState);
          Satellite.Graphic.OrbitRotation := NextRandomIntRange(200, 350, RandomState);
          Satellite.Graphic.MinDisplayRadius := Round(RemapClamped(NextRandomUnitFloat(RandomState) / SatelliteCount,
            0, 1, GeneratedSatelliteBaseRadius, GeneratedSatelliteBaseRadius * 2));
          Satellite.Graphic.MaxDisplayRadius := Round(RemapClamped(NextRandomUnitFloat(RandomState) / 1,
            0, 1, Satellite.Graphic.MinDisplayRadius * 1.3,
            Min(MaximumSatelliteTemplateRadius, Satellite.Graphic.MinDisplayRadius * 2)));
          PreviousExtent := Satellite.Graphic.OrbitRadius + Satellite.Graphic.MaxDisplayRadius div 2;
          Satellite.Graphic.RotationTimerInterval := 25;
          Satellite.Graphic.SurfaceMapStep := ((I mod 2) * 2 - 1) * 2;
        end;
      end;
    GovernmentRoll := NextRandomIntRange(0, 100, RandomState);
    // Reuses the invention loop byte, as native does.
    for Invention := Ord(pgDemocracy) downto Ord(pgAnarchy) do
      if GovernmentRoll >= aConst.PlanetRaceMarket[RaceId].GovernmentRollThresholds[Invention] then
      begin
        Government := TPlanetGovernment(Invention);
        Break;
      end;
    case NextRandomIntRange(0, 2, RandomState) of
      0: Economy := peAgriculture;
      1: Economy := peMixed;
      2: Economy := peIndustrial;
    end;
    Population := CalculateBasePopulation;
  end;
  for Invention := invHullSize to invVortexProjectorRange do InventionLevels[Invention] := PlanetInventionInfo[Invention].InitialLevel;
  CurrentInvention := invHull;
  CurrentInventionPoints := 0;
  ResearchLevelPercent := 30;
  BoostInventionLevels(aConst.PlanetRaceMarket[RaceId].InitialInventionBoostCount);
  ResearchLevelPercent := NextRandomIntRange(20, 40, RandomState);
  ResearchLevelStep := NextRandomIntRange(5, 10, RandomState);
  for Good := t_Food to t_Narcotics do
  begin
    Goods[Good].Count := NextRandomIntRange(GoodsMarket[Good].BaseStock div 2, GoodsMarket[Good].BaseStock, RandomState);
    Goods[Good].PriceState := GoodsMarket[Good].BasePrice;
    Goods[Good].PurchasePrice := Round(Goods[Good].PriceState);
    Goods[Good].BaseSalePrice := Round(Goods[Good].PriceState * 0.98 - 1);
    GoodsScarcityTicks[Good] := 0;
    GoodsSurplusTicks[Good] := 0;
  end;
  TextQuestId := -1;
  Money := Round(RemapClamped(Radius, 60, 100, 10000, 100000));
  HomeRangerCount := 0;
  HomeTransportCount := 0;
  HomePirateCount := 0;
  HomeWarriorCount := 0;
  HomeKlissanCount := 0;
  for ItemType := t_Hull to WeaponCategoryItemType do
    case ItemType of
      t_Hull:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := THull.Create;
          EquipmentShop.Add(Item);
          (Item as THull).Init(False,
            NextRandomIntRange(Round(500 * ItemSizeFactors[5]), Round(500 * ItemSizeFactors[4]), RandomState),
            NextRandomIntRange(1, InventionLevels[invHull], RandomState), OwnerId);
        end;
      t_FuelTanks:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TFuelTanks.Create;
          EquipmentShop.Add(Item);
          (Item as TFuelTanks).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invFuelTanks], RandomState), OwnerId);
        end;
      t_Engine:
        for I := 1 to NextRandomIntRange(1, 3, RandomState) do begin
          Item := TEngine.Create;
          EquipmentShop.Add(Item);
          (Item as TEngine).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invEngineSpeed], RandomState), OwnerId);
        end;
      t_Radar:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TRadar.Create;
          EquipmentShop.Add(Item);
          (Item as TRadar).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invRadarRange], RandomState), OwnerId);
        end;
      t_Scaner:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TScaner.Create;
          EquipmentShop.Add(Item);
          (Item as TScaner).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invScanner], RandomState), OwnerId);
        end;
      t_RepairRobot:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TRepairRobot.Create;
          EquipmentShop.Add(Item);
          (Item as TRepairRobot).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invRepairRobot], RandomState), OwnerId);
        end;
      t_CargoHook:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TCargoHook.Create;
          EquipmentShop.Add(Item);
          (Item as TCargoHook).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invCargoHook], RandomState), OwnerId);
        end;
      t_DefGenerator:
        for I := 1 to NextRandomIntRange(1, 2, RandomState) do begin
          Item := TDefGenerator.Create;
          EquipmentShop.Add(Item);
          (Item as TDefGenerator).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invTechLevel], RandomState), OwnerId);
        end;
      WeaponCategoryItemType:
        for I := 1 to NextRandomIntRange(2, InventionLevels[invTechLevel] + 2, RandomState) do begin
          Item := TWeapon.Create;
          EquipmentShop.Add(Item);
          repeat
            WeaponKind := NextRandomIntRange(0, 14, RandomState) + Ord(t_PhotonGun);
            WriteByteValue(WeaponKind, WeaponType);
          until (WeaponInfo[WeaponType].RequiredTechLevel <= InventionLevels[invTechLevel]) and not (WeaponType in HeavyWeaponTypes);
          (Item as TWeapon).Init(WeaponType, False,
            NextRandomIntRange(Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[5]),
              Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(1, InventionLevels[invTechLevel], RandomState), OwnerId);
        end;
    end;
  UpdateOwnerFlags;
end;
{ @end $5BF870 }

{ @routine $5C1A38 TPlanet_InitKlissanSpawnProxy }
procedure TPlanet.InitKlissanSpawnProxy(Star: TStar);
var Invention: TInventionTrack;
begin
  CurrentStar := Star;
  OwnerId := oiKling;
  for Invention := invHullSize to invVortexProjectorRange do InventionLevels[Invention] := PlanetInventionInfo[Invention].MaximumLevel;
end;
{ @end $5C1A38 }

{ @routine $5C1A68 TPlanet_SaveToBuffer }
procedure TPlanet.SaveToBuffer(Buffer: TBufEC);
var
  Track: TInventionTrack; Kind: TGoodsIndex;
  i, Count: Integer;
  Ship: TShip;
  Satellite: TSputnik;
  Item: TItem;
begin
  Buffer.AddDWord(Self.Id);
  Buffer.AddIntegerValue(Self.GenerationSeed);
  Buffer.AddDWord(Self.RandomState);
  Buffer.AddWideStringZ(Self.Name);
  Buffer.AddSingle(Self.Orbit.AngleDegrees);
  Buffer.AddSingle(Self.Orbit.Radius);
  Buffer.AddSingle(Self.OrbitalVelocity);
  Buffer.AddIntegerValue(Self.ReservedSaveValue);
  Buffer.AddIntegerValue(Self.Radius);
  for Track := invHullSize to invVortexProjectorRange do Buffer.AddAnsiChar(AnsiChar(Self.InventionLevels[Track]));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.CurrentInvention)));
  Buffer.AddSingle(Self.CurrentInventionPoints);
  Buffer.AddAnsiChar(AnsiChar(Self.ResearchLevelPercent));
  Buffer.AddAnsiChar(AnsiChar(Self.ResearchLevelStep));
  Buffer.AddDWord(Self.Population);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.Economy)));
  Buffer.AddDWord(Self.Money);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.OwnerId)));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.RaceId)));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.Government)));
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Self.UnresolvedValue84)));
  for Kind := t_Food to t_Narcotics do
  begin
    Buffer.AddIntegerValue(Self.Goods[Kind].Count);
    Buffer.AddSingle(Self.Goods[Kind].PriceState);
    Buffer.AddIntegerValue(Self.Goods[Kind].PurchasePrice);
    Buffer.AddIntegerValue(Self.Goods[Kind].BaseSalePrice);
    Buffer.AddAnsiChar(AnsiChar(Self.GoodsScarcityTicks[Kind]));
    Buffer.AddAnsiChar(AnsiChar(Self.GoodsSurplusTicks[Kind]));
  end;
  Count := Self.RangerRelations.Count;
  Buffer.AddWideChar(WideChar(Count));
  for i := 0 to Count - 1 do Buffer.AddAnsiChar(AnsiChar(Self.RangerRelations[i]));
  Count := Self.EquipmentShop.Count;
  Buffer.AddWideChar(WideChar(Count));
  for i := 0 to Count - 1 do
  begin
    Item := TItem(Self.EquipmentShop[i]);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Item.ItemType)));
    Item.SaveToBuffer(Buffer);
  end;
  Count := 0;
  for i := 0 to Self.Warriors.Count - 1 do
  begin
    Ship := TShip(Self.Warriors[i]);
    if Ship.CurrentStar.Ships.IndexOf(Ship) < 0 then Inc(Count);
  end;
  Buffer.AddWideChar(WideChar(Count));
  Count := Self.Warriors.Count;
  for i := 0 to Count - 1 do
  begin
    Ship := TShip(Self.Warriors[i]);
    if Ship.CurrentStar.Ships.IndexOf(Ship) < 0 then
    begin
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Ship.ShipType)));
      Ship.SaveToBuffer(Buffer);
    end;
  end;
  Buffer.AddWideChar(WideChar(Self.HomeRangerCount));
  Buffer.AddWideChar(WideChar(Self.HomeTransportCount));
  Buffer.AddWideChar(WideChar(Self.HomePirateCount));
  Buffer.AddWideChar(WideChar(Self.HomeWarriorCount));
  Buffer.AddWideChar(WideChar(Self.HomeKlissanCount));
  Buffer.AddWideChar(WideChar(Self.GraphicRadius));
  Buffer.AddWideStringZ(Self.Graphic.GraphKey);
  Buffer.AddWideChar(WideChar(Self.Graphic.RotationTimerInterval));
  Buffer.AddIntegerValue(Self.Graphic.SurfaceMapStep);
  Buffer.AddAnsiChar(AnsiChar(Self.Graphic.RingKind));
  Buffer.AddIntegerValue(Self.TextQuestId);
  Count := Self.Satellites.Count;
  Buffer.AddWideChar(WideChar(Count));
  for i := 0 to Count - 1 do
  begin
    Satellite := TSputnik(Self.Satellites[i]);
    Satellite.SaveToBuffer(Buffer);
  end;
end;
{ @end $5C1A68 }

{ @routine $5C1E48 TPlanet_LoadFromBuffer }
procedure TPlanet.LoadFromBuffer(Buffer: TBufEC);
var
  Track: TInventionTrack;
  Item: TItem;
  Kind: TItemType;
  I: Integer;
  Count: Integer;
  Ship: TShip;
  ShipKind: TShipType;
  Satellite: TSputnik;
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextPlanetId <= Id then Galaxy.NextPlanetId := Id + 1;
  GenerationSeed := Buffer.GetInt32;
  RandomState := Buffer.GetUInt32;
  Name := Buffer.ReadWideString;
  Orbit.AngleDegrees := Buffer.GetSingle;
  Orbit.Radius := Buffer.GetSingle;
  OrbitalVelocity := Buffer.GetSingle;
  ReservedSaveValue := Buffer.GetInt32;
  Radius := Buffer.GetInt32;
  for Track := invHullSize to invVortexProjectorRange do InventionLevels[Track] := Buffer.GetByte;
  WriteByteValue(Buffer.GetByte, CurrentInvention);
  CurrentInventionPoints := Buffer.GetSingle;
  ResearchLevelPercent := Buffer.GetByte;
  ResearchLevelStep := Buffer.GetByte;
  Population := Buffer.GetUInt32;
  WriteByteValue(Buffer.GetByte, Economy);
  Money := Buffer.GetUInt32;
  WriteByteValue(Buffer.GetByte, OwnerId);
  WriteByteValue(Buffer.GetByte, RaceId);
  WriteByteValue(Buffer.GetByte, Government);
  WriteByteValue(Buffer.GetByte, UnresolvedValue84);
  for Kind := t_Food to t_Narcotics do begin
    Goods[Kind].Count := Buffer.GetInt32;
    Goods[Kind].PriceState := Buffer.GetSingle;
    Goods[Kind].PurchasePrice := Buffer.GetInt32;
    Goods[Kind].BaseSalePrice := Buffer.GetInt32;
    if LoadedSaveVersion >= 9 then begin
      GoodsScarcityTicks[Kind] := Buffer.GetByte;
      GoodsSurplusTicks[Kind] := Buffer.GetByte;
    end else begin
      GoodsScarcityTicks[Kind] := 0;
      GoodsSurplusTicks[Kind] := 0;
    end;
  end;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do RangerRelations.Add(Pointer(Buffer.GetByte));
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do begin
    WriteByteValue(Buffer.GetByte, Kind);
    Item := CreateItemByType(Kind);
    EquipmentShop.Add(Item);
    Item.LoadFromBuffer(Buffer);
  end;
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err');
  for I := 0 to Count - 1 do begin
    WriteByteValue(Buffer.GetByte, ShipKind);
    Ship := CreateShipByType(ShipKind);
    Warriors.Add(Ship);
    Ship.CurrentStar := CurrentStar;
    Ship.LoadFromBuffer(Buffer);
  end;
  HomeRangerCount := Buffer.GetWord;
  HomeTransportCount := Buffer.GetWord;
  HomePirateCount := Buffer.GetWord;
  HomeWarriorCount := Buffer.GetWord;
  HomeKlissanCount := Buffer.GetWord;
  GraphicRadius := Buffer.GetWord;
  Graphic := CreateSpaceObjectByName('Planet', Buffer.ReadWideString, Classes.Point(0, 0)) as TPlanetSE;
  Graphic.SetPosition(PolarToPoint(Orbit));
  Graphic.SetRotationTimerInterval(Buffer.GetWord);
  Graphic.SetSurfaceMapStep(Buffer.GetInt32);
  Graphic.OrbitalVelocity := OrbitalVelocity;
  Graphic.SetRingKind(Buffer.GetByte);
  TextQuestId := Buffer.GetInt32;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do begin
    Satellite := TSputnik.Create;
    Satellite.LoadFromBuffer(Buffer);
    Satellites.Add(Satellite);
  end;
end;
{ @end $5C1E48 }

{ @routine $5C230C TPlanet_ResolveLoadedReferences }
procedure TPlanet.ResolveLoadedReferences;
var
  I, Count: Integer;
  Item: TItem;
begin
  Count := EquipmentShop.Count;
  for I := 0 to Count - 1 do begin
    Item := EquipmentShop[I];
    Item.ClearReferences;
  end;
  Count := Warriors.Count;
  for I := 0 to Count - 1 do begin
    TShip(Warriors[I]).ResolveLoadedReferences;
  end;
  UpdateOwnerFlags;
end;
{ @end $5C230C }

{ @routine $5C2370 TPlanet_NextDay }
procedure TPlanet.NextDay;
var I, Index: Integer; ItemType: TGoodsIndex; Ship: TShip;
begin
  try
    case OwnerId of
      oiMaloc..oiGaal: begin
        if Population > CalculateBasePopulation then Inc(Population, 300)
        else Inc(Population, Trunc(Population * 0.02));
        TryTriggerEconomicEvent;
        UpdateMarketState;
        Inc(Money, Trunc(Population * 0.001));
        if (Galaxy.Rangers.Count < 43) and (CurrentStar.ShipTypeCounts[t_Ranger] < 1) and
          (Galaxy.Rangers.Count < Galaxy.CountStarsByFaction(sfCoalition) * 1.5) and
          (NextRandomUnitFloat(RandomState) < 0.04) then SpawnRanger;
        if (CurrentStar.CountShipsByTypeMask([t_Kling..t_ScientificBase]) < 7) and
          (9 * Galaxy.CountStarsByFaction(sfCoalition) > Galaxy.TransportCount) and
          (NextRandomUnitFloat(RandomState) < 0.05) and (HomeTransportCount < 2) then SpawnTransport(RandomTransportHullType);
        if (CurrentStar.ShipTypeCounts[t_Pirate] < 2) and (Galaxy.CountStarsByFaction(sfCoalition) > Galaxy.PirateCount) then
          if Sqr(PlanetRaceMarket[RaceId].PirateRelationFactor / 10) > NextRandomUnitFloat(RandomState) then SpawnPirate;
        if (HomeWarriorCount < RemapClamped(Radius, 60, 100, 1, 3)) and
          (NextRandomUnitFloat(RandomState) < 0.01) then SpawnWarrior;
        AdvanceInventionProgress;
        RefreshEquipmentShopInventory;
        if HasHostileShipsInSystem then begin
          for I := 0 to Warriors.Count - 1 do begin
            Ship := Warriors[I];
            if Self = Ship.CurrentPlanet then begin
              if CurrentStar.Ships.IndexOf(Ship) = -1 then CurrentStar.Ships.Add(Ship);
              if not Ship.RepairHullAtLocation then Ship.OrderTakeoff;
            end;
          end;
        end else begin
          for I := 0 to Warriors.Count - 1 do begin
            Ship := Warriors[I];
            if (Ship.ScriptShip = nil) and (Ship.LiberationGroup = nil) and (Self = Ship.CurrentPlanet) then begin
              Index := CurrentStar.Ships.IndexOf(Ship);
              if Index >= 0 then begin
                CurrentStar.Ships.Delete(Index);
                Ship.EnemyShip := nil;
                Ship.TruceShip := nil;
                Ship.PartnerShip := nil;
              end else if NextRandomUnitFloat(RandomState) < 0.005 then begin
                Ship.RefreshDerivedStats;
                if (Ship.Wealth < Galaxy.MaxRangerWealth * 0.3) or (0.7 > Ship.StrengthInAverageRanger) then begin
                  if NextRandomUnitFloat(RandomState) < 0.8 then
                    Ship.SetMoney(Ship.Money + Max(1000, Min(10000, Galaxy.MaxRangerWealth div 5)))
                  else Ship.SetMoney(Ship.Money + Max(2000, Min(10000, Galaxy.MaxRangerWealth div 2)));
                end;
                Ship.UpgradeEquipmentAtLocation;
              end;
            end;
          end;
        end;
      end;
      oiKling: begin
        if IsFinalScenarioActive then Exit;
        for ItemType := t_Food to t_Narcotics do Goods[ItemType].Count := 0;
        Money := 0;
        if NextRandomUnitFloat(RandomState) < 0.7 then AdvanceInventionProgress;
        if NextRandomUnitFloat(RandomState) < 0.2 then RefreshEquipmentShopInventory;
        if CurrentStar.ShipTypeCounts[t_Kling] < 10 then begin
          if ((RemapClamped(Galaxy.GetFactionControlPercent(sfCoalition), 0, 100, 1, 4) *
              0.07 * DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor > NextRandomUnitFloat(RandomState)) and
              (CurrentStar.DaysSinceLastNpcShipSpawn > 7)) or
            ((CurrentStar.ShipTypeCounts[t_Kling] = 0) and not CurrentStar.Battle) or
            ((Galaxy.CurrentTurn > 11000) and (CurrentStar.ShipTypeCounts[t_Kling] < 10) and
              (((CurrentStar.DaysSinceLastNpcShipSpawn > 3) and (NextRandomUnitFloat(RandomState) < 0.33)) or
                (CurrentStar.DaysSincePlayerVisit > 20))) or
            ((Galaxy.WarDeltaWin > 6) and (CurrentStar.DaysSinceLastNpcShipSpawn > 2) and
              (NextRandomUnitFloat(RandomState) < 0.3)) then begin
            if (CurrentStar.SumBestRangerRelativeStrength([t_Kling]) < KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier] *
                DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor) or
              (CurrentStar.ShipTypeCounts[t_Kling] < 6) or
              ((CurrentStar.ShipTypeCounts[t_Kling] < 10) and (Galaxy.GetFactionControlPercent(sfKlissan) < 10)) then SpawnWeightedKlissan;
          end;
        end;
        if HasHostileShipsInSystem then begin
          for I := 0 to CurrentStar.Ships.Count - 1 do begin
            Ship := CurrentStar.Ships[I];
            if Self = Ship.CurrentPlanet then Ship.OrderTakeoff;
          end;
        end;
      end;
    end;
  except
    raise Exception.Create('Ошибка в procedure TPlanet.NextDay');
  end;
  if Galaxy.MaxRangerWealth = 0 then raise Exception.Create('need money');
end;
{ @end $5C2370 }

{ @routine $5C2ABC TPlanet_InitializeFilmState }
procedure TPlanet.InitializeFilmState(StepIndex: Integer; RecordFilm: Boolean);
var Satellite: TSputnik; Index, Count: Integer;
begin
  LastFilmPosition := TruncatePointF(GetPosition);
  if RecordFilm then begin
    FilmObject := PrimaryFilm.AddObject(Id, Graphic);
    PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, GetPosition);
    PrimaryFilm.SetPlanetState(StepIndex, FilmObject, Graphic.RotationTimerInterval,
      Graphic.SurfaceMapStep, Round(OrbitalVelocity * 1000), Graphic.RingKind, OwnerId);
    PrimaryFilm.AttachObject(StepIndex, FilmObject);
    Count := Satellites.Count;
    for Index := 0 to Count - 1 do begin
      Satellite := Satellites[Index];
      Satellite.FilmObject := PrimaryFilm.AddObject(Satellite.Id, Satellite.Graphic);
      PrimaryFilm.SetObjectOrbitCenter(StepIndex, Satellite.FilmObject, GetPosition);
      PrimaryFilm.SetObjectStateBuffer(StepIndex, Satellite.FilmObject, Satellite.Graphic.BuildStateBuffer);
      PrimaryFilm.AttachObject(StepIndex, Satellite.FilmObject);
    end;
  end;
end;
{ @end $5C2ABC }

{ @routine $5C2C34 TPlanet_AdvanceOrbitStep }
procedure TPlanet.AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean);
var Point: TPoint; Satellite: TSputnik; Index, Count: Integer;
begin
  if PlayerStar = CurrentStar then Orbit.AngleDegrees := 0.005 * OrbitalVelocity + Orbit.AngleDegrees
  else Orbit.AngleDegrees := 0.1 * OrbitalVelocity + Orbit.AngleDegrees;
  if RecordFilm then begin
    Point := TruncatePointF(GetPosition);
    if (LastFilmPosition.X <> Point.X) or (LastFilmPosition.Y <> Point.Y) then begin
      PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, PointToPointF(Point));
      LastFilmPosition := Point;
      Count := Satellites.Count;
    for Index := 0 to Count - 1 do begin
        Satellite := Satellites[Index];
        PrimaryFilm.SetObjectOrbitCenter(StepIndex, Satellite.FilmObject, PointToPointF(Point));
      end;
    end;
  end;
end;
{ @end $5C2C34 }
{ @routine $5C2D54 TPlanet_PredictPosition }
function TPlanet.PredictPosition(StepsAhead: Integer): TPointF;
var Polar: TPolarPoint;
begin
  Polar.Radius := Orbit.Radius;
  Polar.AngleDegrees := StepsAhead * (OrbitalVelocity * 0.005) + Orbit.AngleDegrees;
  Result := PolarToPoint(Polar);
end;
{ @end $5C2D54 }

{ @routine $5C2D9C TPlanet_RequestDialog }
function TPlanet.RequestDialog: Boolean;
begin
  if ExitScreenLoop or not Player.InNormalSpace then begin Result := False; Exit; end;
  TalkShip := nil;
  TalkPlanet := Self;
  TalkScripted := True;
  ResetEvent(TalkCompletedEvent);
  SetEvent(TalkRequestEvent);
  if WaitForSingleObject(TalkCompletedEvent, INFINITE) <> WAIT_OBJECT_0 then
  begin Result := False; Exit; end;
  Sleep(10);
  Result := True;
end;
{ @end $5C2D9C }

{ @routine $5C2E14 TPlanet_UpdateOwnerFlags }
procedure TPlanet.UpdateOwnerFlags;
begin
  IsCoalitionOwned := OwnerId in CoalitionOwners;
end;
{ @end $5C2E14 }

{ @routine $5C2E38 TPlanet_UpdateMarketState }
procedure TPlanet.UpdateMarketState;
var
  // TItemType, not TGoodsIndex: the [ItemType] set constructors must match native.
  ItemType: TItemType;
  TargetPrice, PriceStep: Single;
  TargetStock, StockStep, StoredUnits: Integer;
begin
  for ItemType := t_Food to t_Narcotics do
  begin
    if GoodsScarcityTicks[ItemType] > 0 then
      StartGoodsDecay(False, [ItemType]);
    if GoodsSurplusTicks[ItemType] > 0 then
      StartGoodsUpsurge(False, [ItemType]);
    StoredUnits := Player.CountStoredItemUnits(Self, ItemType);
    if Self = Player.CurrentPlanet then
      Inc(StoredUnits, Player.CargoGoods[ItemType].Count);
    TargetStock := System.Round(aConst.GoodsMarket[ItemType].BaseStock *
      aConst.PlanetRaceMarket[RaceId].Goods[ItemType].StockFactor *
      aConst.PlanetGovernmentMarket[Government].Goods[ItemType].StockFactor *
      RemapClamped(Radius, 60, 100, 0.5, 1.5));
    TargetPrice := aConst.GoodsMarket[ItemType].BasePrice *
      aConst.PlanetRaceMarket[RaceId].Goods[ItemType].PriceFactor *
      aConst.PlanetGovernmentMarket[Government].Goods[ItemType].PriceFactor * aConst.GoodsMarket[ItemType].EconomyPriceFactors[Economy];
    if Goods[ItemType].Count + StoredUnits < TargetStock then
      TargetPrice := TargetPrice / RemapClamped(Goods[ItemType].Count + StoredUnits, TargetStock * 0.1, TargetStock, 0.8, 1)
    else
      TargetPrice := TargetPrice / RemapClamped(Goods[ItemType].Count + StoredUnits, TargetStock, TargetStock * 3, 1, 1.2);
    if aConst.GoodsMarket[ItemType].MinPrice < TargetPrice then
      TargetPrice := Min(TargetPrice, aConst.GoodsMarket[ItemType].MaxPrice + 1)
    else
      TargetPrice := Max(TargetPrice, aConst.GoodsMarket[ItemType].MinPrice - 1);
    if Goods[ItemType].PriceState - TargetPrice >= 0 then
      PriceStep := TargetPrice * NextRandomFloatRange(0.005, 0.008, RandomState)
    else
      PriceStep := -TargetPrice * NextRandomFloatRange(0.005, 0.008, RandomState);
    case NextRandomIntRange(1, 100, RandomState) of
      1..70: Goods[ItemType].PriceState := Goods[ItemType].PriceState - PriceStep;
      71..90: ;
    else Goods[ItemType].PriceState := Goods[ItemType].PriceState + PriceStep;
    end;
    if aConst.GoodsMarket[ItemType].MinPrice div 2 > Goods[ItemType].PriceState then
      Goods[ItemType].PriceState := aConst.GoodsMarket[ItemType].MinPrice div 2
    else if aConst.GoodsMarket[ItemType].MaxPrice * 2 < Goods[ItemType].PriceState then
      Goods[ItemType].PriceState := aConst.GoodsMarket[ItemType].MaxPrice * 2;
    Goods[ItemType].PurchasePrice := Max(2, System.Round(Goods[ItemType].PriceState));
    Goods[ItemType].BaseSalePrice := Max(Goods[ItemType].PurchasePrice div 2 + 1,
      System.Round(Goods[ItemType].PriceState * RemapClampedAlternate(Goods[ItemType].Count + StoredUnits, TargetStock, TargetStock * 2.2, 0.99, 0.5) - 1));
    if Goods[ItemType].Count + StoredUnits - TargetStock >= 0 then
      StockStep := System.Round(TargetStock * NextRandomFloatRange(0.0025, 0.005, RandomState) + NextRandomUnitFloat(RandomState))
    else
      StockStep := System.Round(-TargetStock * NextRandomFloatRange(0.0025, 0.005, RandomState) - NextRandomUnitFloat(RandomState));
    case NextRandomIntRange(1, 100, RandomState) of
      1..20: Dec(Goods[ItemType].Count, StockStep);
      21..95: ;
    else Inc(Goods[ItemType].Count, StockStep);
    end;
    if Goods[ItemType].Count < 0 then Goods[ItemType].Count := 0;
  end;
end;
{ @end $5C2E38 }

{ @routine $5C3380 TPlanet_TriggerGovernmentRevolution }
procedure TPlanet.TriggerGovernmentRevolution;
var
  NewGovernment, Candidate: TPlanetGovernment;
  i, Attempts, Roll: Integer;
  Ranger: TRanger;
  ItemType: TItemType;
  GoodsMask: TItemTypeMask;
  NewsType: TGalaxyNewsKind;
begin
  NewGovernment := Government;
  Attempts := 0;
  NewsType := gnRevolutionAnarchy;
  repeat
    Roll := NextRandomIntRange(0, 100, RandomState);
    for Candidate := pgDemocracy downto pgAnarchy do
      if aConst.PlanetRaceMarket[RaceId].GovernmentRollThresholds[Ord(Candidate)] <= Roll then
      begin
        NewGovernment := Candidate;
        case NewGovernment of
          pgAnarchy: NewsType := gnRevolutionAnarchy;
          pgDictatorship: NewsType := gnRevolutionDictatorship;
          pgMonarchy: NewsType := gnRevolutionMonarchy;
          pgRepublic: NewsType := gnRevolutionRepublic;
          pgDemocracy: NewsType := gnRevolutionDemocracy;
        end;
        Break;
      end;
    Inc(Attempts);
    if Attempts > 100 then Exit;
    // Native discards this duplicate-news check.
    if CurrentStar.Constellation.Visible and
      (aGalaxy.Galaxy.CountPlanetNewsByType(NewsType) > 0) then ;
  until Candidate <> NewGovernment;
  Government := NewGovernment;
  for i := 0 to aGalaxy.Galaxy.Rangers.Count - 1 do
  begin
    Ranger := TRanger(aGalaxy.Galaxy.Rangers[i]);
      ChangeRelationToRanger(Ranger, aConst.PlanetGovernmentMarket[Government].RevolutionRelationDelta[Ranger.GetDominantCareer]);
  end;
  if CurrentStar.Constellation.Visible then
    // Native always records the Anarchy kind.
    aGalaxy.Galaxy.AddPlanetNews(gnRevolutionAnarchy, FormatText2(
      PickLocalizedTextVariant('GalaxyNews.Planet.Revolution.' + SysUtils.IntToStr(Ord(Government)),
        (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
      HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  case Candidate of
    pgAnarchy: StartGoodsDecay(True, [t_Food, t_Medicine, t_Technics, t_Arms]);
    pgDictatorship: StartGoodsDecay(True, [t_Food, t_Medicine, t_Arms]);
    pgMonarchy:
      begin
        GoodsMask := [t_Food];
        for ItemType := t_Medicine to t_Narcotics do
          if aConst.GoodsMarket[ItemType].BasePrice > Goods[ItemType].PriceState then
            Include(GoodsMask, ItemType);
        StartGoodsUpsurge(True, GoodsMask);
      end;
    pgRepublic:
      begin
        StartGoodsDecay(True, [t_Minerals]);
        StartGoodsUpsurge(True, [t_Technics, t_Arms]);
      end;
    pgDemocracy:
      begin
        StartGoodsDecay(True, [t_Luxury, t_Minerals]);
        StartGoodsUpsurge(True, [t_Technics, t_Arms]);
      end;
  end;
end;
{ @end $5C3380 }

{ @routine $5C3748 TPlanet_TryTriggerEconomicEvent }
procedure TPlanet.TryTriggerEconomicEvent;
begin
  if CurrentStar.Constellation.Visible and (aGalaxy.Galaxy.PlanetNews.Count >= 9) then Exit;
  if CurrentStar.ShipTypeCounts[t_Kling] > 0 then Exit;
  if (Integer(GenerationSeed) + aGalaxy.Galaxy.CurrentTurn) mod 30 <> 0 then Exit;
  if CurrentStar.DaysSincePlayerVisit < 30 then Exit;
  if SeededRandomFloatRange(Cardinal(TGalaxy(aGalaxy.Galaxy).CurrentTurn) * GenerationSeed * 1017, 0, 1) <
    aConst.PlanetRaceMarket[RaceId].RevolutionChance then
  begin
    TriggerGovernmentRevolution;
    Exit;
  end;
  if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1117) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnMineralDeposit) = 0)) and
    (Economy in [peMixed, peIndustrial]) then
  begin
    StartGoodsDecay(True, [t_Technics]);
    StartGoodsUpsurge(True, [t_Minerals]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnMineralDeposit, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.MineralDeposit',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
    Exit;
  end;
  if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1127) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedMineral) = 0)) and
    (Economy in [peIndustrial]) then
  begin
    StartGoodsDecay(True, [t_Minerals]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedMineral, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedMineral',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
    Exit;
  end;
  if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1217) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyArms) = 0)) and
    (Economy in [peMixed, peIndustrial]) and
    (OwnerId in [oiMaloc, oiPeople, oiFei]) then
  begin
    StartGoodsDecay(True, [t_Technics]);
    StartGoodsUpsurge(True, [t_Arms]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyArms, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyArms',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
    Exit;
  end;
  if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1227) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedArms) = 0)) and
    (Economy in [peMixed]) and
    (OwnerId in [oiMaloc..oiPeople]) then
  begin
    StartGoodsDecay(True, [t_Arms]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedArms, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedArms',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1237) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedArms) = 0)) and
    (Economy in [peMixed]) and
    (OwnerId in [oiMaloc..oiFei]) and
    (Government in [pgDemocracy]) then
  begin
    StartGoodsDecay(True, [t_Arms]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedArms, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedArmsForRevolution',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1317) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyTechnics) = 0)) and
    (Economy in [peMixed, peIndustrial]) and
    (OwnerId in [oiPeople..oiGaal]) then
  begin
    StartGoodsUpsurge(True, [t_Technics, t_Arms]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyTechnics, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyTechnics',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1417) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyFood) = 0)) and
    (Economy in [peAgriculture, peMixed]) then
  begin
    StartGoodsUpsurge(True, [t_Food]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyFood, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyFood',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1427) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyFood) = 0)) and
    (Economy in [peAgriculture]) then
  begin
    StartGoodsUpsurge(True, [t_Food]);
    StartGoodsDecay(True, [t_Technics]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyFood, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyFoodNeedTechnics',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1437) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedFood) = 0)) and
    (Economy in [peAgriculture, peMixed, peIndustrial]) and
    (OwnerId in [oiMaloc..oiFei]) then
  begin
    StartGoodsDecay(True, [t_Food, t_Medicine, t_Narcotics]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedFood, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedFood',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1517) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyMedicine) = 0)) and
    (Economy in [peMixed]) and
    (OwnerId in [oiPeople..oiGaal]) then
  begin
    StartGoodsUpsurge(True, [t_Medicine]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyMedicine, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyMedicine',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1617) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyLuxury) = 0)) and
    (Economy in [peAgriculture, peMixed, peIndustrial]) and
    (OwnerId in [oiPeleng..oiGaal]) then
  begin
    StartGoodsUpsurge(True, [t_Luxury]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyLuxury, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyLuxury',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1717) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedLuxury) = 0)) and
    (Economy in [peAgriculture, peMixed]) and
    (OwnerId in [oiPeople..oiGaal]) then
  begin
    StartGoodsDecay(True, [t_Luxury]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedLuxury, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedLuxury',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1817) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnManyAlcohol) = 0)) and
    (Economy in [peAgriculture, peMixed]) and
    (OwnerId in [oiPeleng..oiPeople]) then
  begin
    StartGoodsUpsurge(True, [t_Alcohol]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnManyAlcohol, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.ManyAlcohol',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end
  else if (SeededRandomIntRange(0, 100,
    Cardinal(aGalaxy.Galaxy.CurrentTurn) * GenerationSeed * 1917) < EconomicEventChance) and
    (not CurrentStar.Constellation.Visible or (aGalaxy.Galaxy.CountPlanetNewsByType(gnNeedAlcohol) = 0)) and
    (Economy in [peMixed, peIndustrial]) and
    (OwnerId in [oiPeople,oiGaal]) then
  begin
    StartGoodsDecay(True, [t_Alcohol]);
    if CurrentStar.Constellation.Visible then
      aGalaxy.Galaxy.AddPlanetNews(gnNeedAlcohol, FormatText2(
        PickLocalizedTextVariant('GalaxyNews.Planet.NeedAlcohol',
          (aGalaxy.Galaxy.CurrentTurn div 10) * Integer(GenerationSeed)),
        HighlightColorTag, '<Star>', CurrentStar.Name, '<Planet>', Name));
  end;
end;
{ @end $5C3748 }

{ @routine $5C4810 TPlanet_HandleAsteroidCollision }
procedure TPlanet.HandleAsteroidCollision(Asteroid: TObject);
begin
end;
{ @end $5C4810 }

{ @routine $5C4814 TPlanet_CollectScriptDialogChoices }
procedure TPlanet.CollectScriptDialogChoices(Choices: TStringsEC);
var
  i, j, k: Integer;
  Script: TScript;
  Star: TScriptStar;
begin
  Choices.Clear;
  for i := 0 to aGalaxy.Galaxy.Scripts.Count - 1 do
  begin
    Script := aGalaxy.Galaxy.Scripts[i];
    for j := 0 to Script.Stars.Count - 1 do
    begin
      Star := Script.Stars[j];
      for k := 0 to High(Star.Planets) do
        if (Star.Planets[k].Planet = Self) and (Star.Planets[k].DefinitionText <> '') then
        begin
          Choices.Add(Star.Planets[k].DefinitionText);
          Choices.SetDataAt(Choices.GetCount - 1, Script);
        end;
    end;
  end;
end;
{ @end $5C4814 }

{ @routine $5C491C TPlanet_GetFullName }
function TPlanet.GetFullName(Separator: WideString): WideString;
begin
  Result := LocalizedText('Planet.Name') + Separator + Name;
end;
{ @end $5C491C }

{ @routine $5C49AC TPlanet_GetPosition }
function TPlanet.GetPosition: TPointF;
begin
  Result := PolarToPoint(Orbit);
end;
{ @end $5C49AC }

{ @routine $5C49C0 TPlanet_GetInfoText }
function TPlanet.GetInfoText: WideString;
var Text: WideString;
begin
  case OwnerId of
    oiMaloc..oiGaal: Text := LocalizedText('Planet.Civil.Info.TextAboutPlanet');
    oiKling: Text := LocalizedText('Planet.Kling.Info.TextAboutPlanet');
    oiNone: Text := LocalizedText('Planet.NotCivil.Info.TextAboutPlanet');
  end;
  ReplaceTextToken(Text, '<Planet>', Name, HighlightColorTag);
  ReplaceTextToken(Text, '<Star>', CurrentStar.Name, HighlightColorTag);
  ReplaceTextToken(Text, '<Race>', GetNativeRaceName, HighlightColorTag);
  ReplaceTextToken(Text, '<Population>', WideString(IntToStr(Round(Population / 1000))), HighlightColorTag);
  ReplaceTextToken(Text, '<Economy>', aConst.PlanetEconomyInfo[Economy].DisplayName, HighlightColorTag);
  ReplaceTextToken(Text, '<Goverment>', GetGovernmentName, HighlightColorTag);
  ReplaceTextToken(Text, '<Relation>', GetRelationLevelTextToShip(Player), HighlightColorTag);
  Result := Text;
end;
{ @end $5C49C0 }

{ @routine $5C4D14 TPlanet_GetGovernmentName }
function TPlanet.GetGovernmentName: WideString;
begin
  Result := aConst.PlanetGovernmentMarket[Government].DisplayName;
end;
{ @end $5C4D14 }

{ @routine $5C4D3C TPlanet_GetNativeRaceName }
function TPlanet.GetNativeRaceName: WideString;
begin
  Result := aConst.OwnerInfo[RaceToOwner(RaceId)].DisplayName;
end;
{ @end $5C4D3C }

{ @routine $5C4D68 TPlanet_CalculateBasePopulation }
function TPlanet.CalculateBasePopulation: Integer;
begin
  Result := Round(RemapClamped(Radius, 60, 100, 100000, 1000000));
end;
{ @end $5C4D68 }

{ @routine $5C4DA0 TPlanet_CountPlanetsOfSameRace }
function TPlanet.CountPlanetsOfSameRace: Integer;
var I: Integer; Planet: TPlanet;
begin
  Result := 0;
  for I := 0 to Galaxy.Planets.Count - 1 do begin
    Planet := Galaxy.Planets[I];
    if OwnerId = oiNone then begin
      if Planet.OwnerId = OwnerId then Inc(Result);
    end else if (Planet.OwnerId <> oiNone) and (RaceId = Planet.RaceId) then Inc(Result);
  end;
end;
{ @end $5C4DA0 }

{ @routine $5C4E08 TPlanet_FindUnchartedNeighborConstellation }
function TPlanet.FindUnchartedNeighborConstellation: TObject;
var I: Integer; Constellation: TConstellation;
begin
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if Constellation.SharesOutlineSegment(CurrentStar.Constellation) then
      if not Constellation.Visible then begin Result := Constellation; Exit; end;
  end;
  Result := nil;
end;
{ @end $5C4E08 }

{ @routine $5C4E68 TPlanet_FindNearestPlanetByOwnerMask }
function TPlanet.FindNearestPlanetByOwnerMask(OwnerMask: TOwnerSet): TObject;
var
  i, j: Integer;
  Star: TStar;
  Planet: TPlanet;
begin
  for i := 0 to aGalaxy.Galaxy.Stars.Count - 1 do
  begin
    Star := CurrentStar.StarDistances[i].Star as TStar;
    for j := 0 to Star.Planets.Count - 1 do
    begin
      Planet := Star.Planets[j];
      if Planet.OwnerId in OwnerMask then
      begin
        Result := Planet;
        Exit;
      end;
    end;
  end;
  Result := nil;
end;
{ @end $5C4E68 }

{ @routine $5C4EF4 TPlanet_BoostInventionLevels }
procedure TPlanet.BoostInventionLevels(Count: Integer);
var I: Integer;
begin
  for I := 1 to Count do begin
    Inc(InventionLevels[CurrentInvention]);
    CurrentInventionPoints := 0;
    SelectCurrentInvention;
  end;
end;
{ @end $5C4EF4 }

{ @routine $5C4F1C TPlanet_SelectCurrentInvention }
procedure TPlanet.SelectCurrentInvention;
var
  Track: TInventionTrack;
  Chance: Double;
  Found: Boolean;
  i, Index: Integer;
begin
  Found := False;
  Chance := 0.03;
  repeat
    Index := NextRandomIntRange(0, 39, RandomState);
    for i := 0 to 39 do
    begin
      IncrementWrapped(Index, 0, 39);
      Track := Index;
      if (ResearchLevelPercent > System.Round(InventionLevels[Track] * (100 / aConst.PlanetInventionInfo[Track].MaximumLevel))) and
        (aConst.PlanetInventionInfo[Track].RequiredMainTechLevel <= InventionLevels[invTechLevel]) and
        (InventionLevels[Track] <= InventionLevels[invTechLevel]) and
        (NextRandomUnitFloat(RandomState) <= Chance) then
      begin
        CurrentInvention := Track;
        Found := True;
        Break;
      end;
    end;
    Chance := Chance + 0.03;
    if Chance > 1.2 then
      raise Exception.Create('R большой - проблемы с открытием науки');
  until Found;
end;
{ @end $5C4F1C }

{ @routine $5C5080 TPlanet_AdvanceInventionProgress }
procedure TPlanet.AdvanceInventionProgress;
var
  Track: TInventionTrack;
  Average, Progress: Double;
  Complete, CompleteAfterAdvance, RaiseCeiling: Boolean;
  Count: Integer;
begin
  Complete := True;
  for Track := invHullSize to invVortexProjectorRange do
    if InventionLevels[Track] < PlanetInventionInfo[Track].MaximumLevel then Complete := False;
  if Complete then Exit
  else
  begin
    Progress := RemapClamped(Radius, 60, 100, 0.8, 1.2) *
      (PlanetEconomyInfo[Economy].InventionProgressScale * PlanetRaceMarket[RaceId].InventionProgressScale);
    Progress := Progress * DifficultyModifiers[Galaxy.Difficulty].InventionProgressScale;
    CurrentInventionPoints := CurrentInventionPoints + Progress;
    if CurrentInventionPoints > 90 then
    begin
      Inc(InventionLevels[CurrentInvention]);
      CurrentInventionPoints := 0;
      CompleteAfterAdvance := True;
      for Track := invHullSize to invVortexProjectorRange do
        if InventionLevels[Track] < PlanetInventionInfo[Track].MaximumLevel then CompleteAfterAdvance := False;
      if CompleteAfterAdvance then Exit;
      RaiseCeiling := True;
      repeat
        for Track := invHullSize to invVortexProjectorRange do
          if (ResearchLevelPercent > System.Round(InventionLevels[Track] * (100 / PlanetInventionInfo[Track].MaximumLevel))) and
            (InventionLevels[invTechLevel] >= aConst.PlanetInventionInfo[Track].RequiredMainTechLevel) and
            (InventionLevels[Track] <= InventionLevels[invTechLevel]) then RaiseCeiling := False;
        if not RaiseCeiling then
        begin
          Average := 0;
          Count := 0;
          for Track := invHullSize to invVortexProjectorRange do
            if not (Track in [invHullSize, invFuelTanksSize, invEngineSize, invRadarSize, invScannerSize, invRepairRobotSize, invCargoHookSize, invDefGeneratorSize, invPhotonGunSize, invIndustrialLaserSize, invZipGunSize, invGravitonBeamerSize, invRetractorSize, invKellersPhaserSize, invAeonicBlasterSize, invXDefibrillatorSize, invSubmesonicGunSize, invFieldAnnihilatorSize, invTachionCleaverSize, invVortexProjectorSize]) and
              (aConst.PlanetInventionInfo[Track].RequiredMainTechLevel <= InventionLevels[invTechLevel]) then
            begin
              Average := Average + InventionLevels[Track] * (100 / PlanetInventionInfo[Track].MaximumLevel);
              Inc(Count);
            end;
          if Count = 0 then Count := 1;
          Average := Average / Count;
          if ResearchLevelPercent < Average then RaiseCeiling := True;
        end;
        if RaiseCeiling then
          if ResearchLevelPercent + ResearchLevelStep < 100 then
            ResearchLevelPercent := ResearchLevelPercent + ResearchLevelStep
          else ResearchLevelPercent := 100;
      until not RaiseCeiling;
      SelectCurrentInvention;
    end;
  end;
end;
{ @end $5C5080 }

{ @routine $5C52F8 TPlanet_SpawnRanger }
function TPlanet.SpawnRanger: TObject;
var Ranger: TRanger; Budget: Integer;
begin
  Ranger := TRanger.Create;
  Inc(HomeRangerCount);
  if Galaxy.CurrentTurn < 200 then Budget := Galaxy.MaxRangerWealth
  else Budget := Min(Galaxy.AverageRangerCapital,
    Round(RemapClamped(NextRandomUnitFloat(RandomState), 0, 1, 0.4, 0.6) * Galaxy.MaxRangerWealth));
  if Budget > 500000 then Budget := 500000;
  Ranger.InitializeAtPlanet(Self, Budget);
  Result := Ranger;
  CurrentStar.DaysSinceLastNpcShipSpawn := 0;
end;
{ @end $5C52F8 }

{ @routine $5C53B0 TPlanet_SpawnTransport }
function TPlanet.SpawnTransport(Kind: THullType): TObject;
var Budget: Integer; Transport: TTransport; SubType: TTransportType;
begin
  Transport := TTransport.Create;
  Inc(HomeTransportCount);
  Budget := Round(RemapClamped(NextRandomUnitFloat(RandomState), 0, 1, 0.2, 0.4) * Galaxy.MaxRangerWealth);
  if Budget > 600000 then Budget := 600000;
  if Kind = RandomTransportHullType then SubType := TTransportType(NextRandomIntRange(0, 2, RandomState))
  else if Kind = htTransport then SubType := ttTransport
  else if Kind = htLiner then SubType := ttLiner
  else SubType := ttDiplomat;
  Transport.InitGenerated(Self, Budget, SubType);
  Result := Transport;
  CurrentStar.DaysSinceLastNpcShipSpawn := 0;
end;
{ @end $5C53B0 }

{ @routine $5C5464 TPlanet_SpawnPirate }
function TPlanet.SpawnPirate: TObject;
var Budget: Integer; Pirate: TPirate;
begin
  Pirate := TPirate.Create;
  Inc(HomePirateCount);
  Budget := Round(RemapClamped(NextRandomUnitFloat(RandomState), 0, 1, 0.3, 0.5) * Galaxy.MaxRangerWealth);
  if Budget > 800000 then Budget := 800000;
  Pirate.InitGenerated(Self, Budget);
  Result := Pirate;
  CurrentStar.DaysSinceLastNpcShipSpawn := 0;
end;
{ @end $5C5464 }

{ @routine $5C54E4 TPlanet_SpawnWarrior }
function TPlanet.SpawnWarrior: TObject;
var Budget: Integer; Warrior: TWarrior;
begin
  Warrior := TWarrior.Create;
  Inc(HomeWarriorCount);
  Budget := Round(RemapClamped(NextRandomUnitFloat(RandomState), 0, 1, 0.3, 0.5) * Galaxy.MaxRangerWealth);
  Budget := Round(RemapClamped(Galaxy.GetFactionControlPercent(sfKlissan), 0, 100, Budget * 0.7, Budget * 1.2));
  if NextRandomUnitFloat(RandomState) > 0.2 then
    Budget := Round(RemapClampedAlternate(Galaxy.WarDeltaWin, -5, 5, Budget * 2, Budget * 0.5));
  if Budget > 900000 then Budget := 900000;
  Warrior.InitGenerated(Self, Budget);
  Result := Warrior;
  CurrentStar.DaysSinceLastNpcShipSpawn := 0;
end;
{ @end $5C54E4 }

{ @routine $5C5664 TPlanet_SpawnWeightedKlissan }
function TPlanet.SpawnWeightedKlissan: TObject;
var
  Kind1Count, Kind2Count, Kind3Count, Kind4Count: Integer;
  I, Roll: Integer;
  Ship: TShip;
  Selected: TObject;
begin
  Kind1Count := 0;
  Kind2Count := 0;
  Kind3Count := 0;
  Kind4Count := 0;
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.ShipType = t_Kling then
      case (Ship as TKling).KlingType of
        ktEgemon: Inc(Kind1Count);
        ktNondus: Inc(Kind2Count);
        ktKatauri: Inc(Kind3Count);
        ktRoggit: Inc(Kind4Count);
      end;
  end;
  Selected := nil;
  while True do begin
    Roll := NextRandomIntRange(0, 100, RandomState);
    if (Galaxy.GetFactionControlPercent(sfKlissan) < 15) and (NextRandomUnitFloat(RandomState) < 0.2) then Roll := Roll div 2;
    if (CurrentStar.Constellation.HomeDistanceTier = 3) and (NextRandomUnitFloat(RandomState) < 0.2) then Roll := Roll div 2;
    case Roll of
      0..5: begin
        if (((Galaxy.GetFactionControlPercent(sfKlissan) < 20) or (NextRandomUnitFloat(RandomState) < 0.02)) and (Kind1Count < 2)) or
          ((Galaxy.GetFactionControlPercent(sfKlissan) < 10) and (Kind1Count < 3) and (NextRandomUnitFloat(RandomState) < 0.05)) then begin
          Selected := SpawnKlissan(ktEgemon);
          Break;
        end;
        Roll := NextRandomIntRange(0, 100, RandomState);
        if (Roll >= (Galaxy.GetFactionControlPercent(sfKlissan))) and
          (KlissanInfo[ktEgemon].SystemCountLimit > Kind1Count) and
          ((CurrentStar.SumBestRangerRelativeStrength([t_Kling]) + KlissanInfo[ktEgemon].StrengthCap <
            KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier] * DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor) or
           (Galaxy.WarDeltaWin > 3) or (NextRandomUnitFloat(RandomState) < 0.02)) then begin
          Selected := SpawnKlissan(ktEgemon);
          Break;
        end;
      end;
      6..15: if (KlissanInfo[ktNondus].SystemCountLimit > Kind2Count) and
          ((CurrentStar.SumBestRangerRelativeStrength([t_Kling]) + KlissanInfo[ktNondus].StrengthCap <
            KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier] * DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor) or
           (Galaxy.WarDeltaWin > 3) or (NextRandomUnitFloat(RandomState) < 0.02)) then begin
        Selected := SpawnKlissan(ktNondus);
        Break;
      end;
      16..35: if (KlissanInfo[ktKatauri].SystemCountLimit > Kind3Count) and
          ((CurrentStar.SumBestRangerRelativeStrength([t_Kling]) + KlissanInfo[ktKatauri].StrengthCap <
            KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier] * DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor) or
           (Galaxy.WarDeltaWin > 2) or (NextRandomUnitFloat(RandomState) < 0.02)) then begin
        Selected := SpawnKlissan(ktKatauri);
        Break;
      end;
      36..60: if (KlissanInfo[ktRoggit].SystemCountLimit > Kind4Count) and
          (CurrentStar.SumBestRangerRelativeStrength([t_Kling]) + KlissanInfo[ktRoggit].StrengthCap <
            KlissanFleetStrengthThresholds[CurrentStar.Constellation.HomeDistanceTier] * DifficultyModifiers[Galaxy.Difficulty].KlissanHullFactor) then begin
        Selected := SpawnKlissan(ktRoggit);
        Break;
      end;
      61..100: begin
        Selected := SpawnKlissan(ktMutenok);
        Break;
      end;
    end;
  end;
  Result := Selected;
end;
{ @end $5C5664 }

{ @routine $5C5AAC TPlanet_SpawnKlissan }
function TPlanet.SpawnKlissan(Kind: TKlingType): TObject;
var Ship: TKling;
begin
  Ship := TKling.Create;
  Inc(HomeKlissanCount);
  Ship.InitGenerated(Kind, Self);
  Result := Ship;
  CurrentStar.DaysSinceLastNpcShipSpawn := 0;
end;
{ @end $5C5AAC }

{ @routine $5C5AE0 TPlanet_GenerateShipForScriptGroup }
function TPlanet.GenerateShipForScriptGroup(Group: TObject): TObject;
var Rules: TScriptGroup; Ship: TShip; Owner, SelectedOwner, OldOwner: TOwnerId; Kind, SelectedKind: THullType; I, J: Integer;
begin
  Rules := Group as TScriptGroup;
  if OwnerId in Rules.OwnerMask then SelectedOwner := OwnerId
  else begin
    SelectedOwner := oiMaloc;
    for Owner := oiMaloc to oiNone do
      if Owner in Rules.OwnerMask then begin
        SelectedOwner := Owner;
        if NextRandomUnitFloat(RandomState) < 0.5 then Break;
      end;
  end;
  SelectedKind := htRanger;
  for Kind := htRanger to htStation do
    if Kind in Rules.ShipTypeMask then begin
      SelectedKind := Kind;
      if NextRandomUnitFloat(RandomState) < 0.2 then Break;
    end;
  if OwnerId <> SelectedOwner then begin
    OldOwner := OwnerId;
    OwnerId := SelectedOwner;
  end else OldOwner := OwnerId;
  case SelectedKind of
    htRanger: Ship := SpawnRanger as TShip;
    htWarrior: Ship := SpawnWarrior as TShip;
    htPirate: Ship := SpawnPirate as TShip;
    htTransport..htDiplomat: Ship := SpawnTransport(SelectedKind) as TShip;
    htMakhpella: Ship := SpawnKlissan(ktMakhpella) as TShip;
    htEgemon: Ship := SpawnKlissan(ktEgemon) as TShip;
    htNondus: Ship := SpawnKlissan(ktNondus) as TShip;
    htKatauri: Ship := SpawnKlissan(ktKatauri) as TShip;
    htRoggit: Ship := SpawnKlissan(ktRoggit) as TShip;
    htMutenok: Ship := SpawnKlissan(ktMutenok) as TShip;
  else Ship := nil;
  end;
  if Ship <> nil then
    for I := 0 to 10 do begin
      Inc(Money, Galaxy.ComputeScaledSmallMoney(OwnerId));
      if Rules.MinCargoHookLevel > 0 then begin
        if (Ship.CargoHook <> nil) and (Ship.CargoHook.TechLevel >= Rules.MinCargoHookLevel) then
          Ship.LiquidateInventoryItem(Ship.CargoHook);
        Ship.CreateAndEquipCargoHook(True, 40, Rules.MinCargoHookLevel, OwnerId);
        Ship.RefreshDerivedStats;
      end;
      if Rules.MinSpeed > Ship.Speed then Ship.BuyEngineUpgrade(scBig);
      if (Rules.MinStrength > Ship.StrengthInBestRanger) and (Rules.WeaponRequirement = 1) then Ship.BuyWeaponUpgrade(scZero);
      if (Rules.MinStrength > Ship.StrengthInBestRanger) and (Rules.WeaponRequirement = 1) then Ship.BuyWeaponUpgrade(scBig);
      if (Rules.MaxStrength < Ship.StrengthInBestRanger) and (Rules.WeaponRequirement = 1) then
        if Ship.CountEquippedWeapons > 1 then Ship.LiquidateInventoryItem(Ship.Weapons[0]);
      if (Rules.MaxStrength < Ship.StrengthInBestRanger) and (Rules.WeaponRequirement = 1) and
        (Ship.DefGenerator <> nil) then Ship.LiquidateInventoryItem(Ship.DefGenerator);
      if (Rules.WeaponRequirement = 2) and (Ship.WeaponCount > 0) then
        for J := Ship.WeaponCount downto 1 do Ship.LiquidateInventoryItem(Ship.Weapons[J - 1]);
    end;
  if (Ship <> nil) and (Ship.GetCargoFreeSpace < Rules.MinFreeCargoSpace) then begin
      Inc(Ship.Hull.Weight, Rules.MinFreeCargoSpace - Ship.CargoFreeSpace);
      Ship.Hull.HullPoints := Ship.Hull.Weight;
      Ship.RefreshDerivedStats;
    end;
  if (Ship <> nil) and (Ship is TRanger) then begin
    // Native tests the complemented status byte against the configured range.
    if (not (Ship as TRanger).CareerStatus[rcTrader]) in [Rules.MinTraderStatus..Rules.MaxTraderStatus] then begin
      (Ship as TRanger).CareerStatus[rcTrader] := (Rules.MinTraderStatus + Rules.MaxTraderStatus) div 2;
      (Ship as TRanger).CareerStatus[rcPirate] := (100 - (Ship as TRanger).CareerStatus[rcTrader]) div 2;
      (Ship as TRanger).CareerStatus[rcWarrior] := 100 - (Ship as TRanger).CareerStatus[rcTrader] - (Ship as TRanger).CareerStatus[rcPirate];
    end;
    if (not (Ship as TRanger).CareerStatus[rcPirate]) in [Rules.MinPirateStatus..Rules.MaxPirateStatus] then begin
      (Ship as TRanger).CareerStatus[rcPirate] := (Rules.MinPirateStatus + Rules.MaxPirateStatus) div 2;
      (Ship as TRanger).CareerStatus[rcTrader] := (100 - (Ship as TRanger).CareerStatus[rcPirate]) div 2;
      (Ship as TRanger).CareerStatus[rcWarrior] := 100 - (Ship as TRanger).CareerStatus[rcPirate] - (Ship as TRanger).CareerStatus[rcTrader];
    end;
    if (not (Ship as TRanger).CareerStatus[rcWarrior]) in [Rules.MinWarriorStatus..Rules.MaxWarriorStatus] then begin
      (Ship as TRanger).CareerStatus[rcWarrior] := (Rules.MinWarriorStatus + Rules.MaxWarriorStatus) div 2;
      (Ship as TRanger).CareerStatus[rcTrader] := (100 - (Ship as TRanger).CareerStatus[rcWarrior]) div 2;
      (Ship as TRanger).CareerStatus[rcPirate] := 100 - (Ship as TRanger).CareerStatus[rcWarrior] - (Ship as TRanger).CareerStatus[rcTrader];
    end;
  end;
  if OwnerId <> OldOwner then begin
    OwnerId := OldOwner;
    Ship.HomePlanet := FindNearestPlanetByOwnerMask([Ship.OwnerId]) as TPlanet;
    if Ship.HomePlanet = nil then Ship.HomePlanet := Self;
  end;
  Result := Ship;
end;
{ @end $5C5AE0 }

{ @routine $5C6134 TPlanet_GetRangerRelationByIndex }
function TPlanet.GetRangerRelationByIndex(Index: Integer): Integer;
begin
  Result := TPercent(RangerRelations[Index]);
end;
{ @end $5C6134 }

{ @routine $5C6150 TPlanet_SetRelationLevelToRanger }
procedure TPlanet.SetRelationLevelToRanger(Ranger: TObject; Level: TRelationLevel);
begin
  case Level of
    rlHostile: RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(5);
    rlBad: RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(20);
    rlNormal: RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(45);
    rlGood: RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(70);
    rlExcellent: RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(90);
  else
    RangerRelations[aGalaxy.Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(5);
  end;
end;
{ @end $5C6150 }

{ @routine $5C62B0 TPlanet_ChangeRelationToRanger }
procedure TPlanet.ChangeRelationToRanger(Ranger: TObject; Delta: Integer);
var Relation: Byte;
begin
  Relation := Byte(RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)]);
  // Applies charisma to penalties as well as improvements.
  if (Ranger as TRanger).BaseSkills[skCharm] > 0 then
    Inc(Delta, Round((Ranger as TRanger).BaseSkills[skCharm] * Delta * 0.2));
  if Relation + Delta in [0..100] then Inc(Relation, Delta)
  else if Relation + Delta > 100 then Relation := 100
  else Relation := 0;
  RangerRelations[Galaxy.Rangers.IndexOf(Ranger as TRanger)] := Pointer(Relation);
end;
{ @end $5C62B0 }

{ @routine $5C6388 TPlanet_RelationToShip }
function TPlanet.RelationToShip(Ship: TObject): TNonRangerRelation;
begin
  Result := 0;
  if OwnerId in [oiMaloc..oiGaal] then
  begin
    case (Ship as TShip).ShipType of
      t_Ranger: Result := GetRangerRelationByIndex(Galaxy.Rangers.IndexOf(Ship as TRanger));
      t_Transport: Result := OwnerRelations[OwnerId, (Ship as TTransport).OwnerId];
      t_Pirate: Result := Max(30, Min(PlanetRaceMarket[RaceId].MaximumPirateRelation,
        Round(OwnerRelations[OwnerId, (Ship as TPirate).OwnerId] * PlanetRaceMarket[RaceId].PirateRelationFactor)));
      t_Warrior: Result := 100;
      t_Kling: Result := 0;
      t_Tranclucator: if (Ship as TTranclucator).OwnerShip <> nil then
           Result := RelationToShip((Ship as TTranclucator).OwnerShip)
         else Result := 100;
      t_RangerCenter..t_ScientificBase: Result := 100;
    end;
  end
  else if OwnerId = oiKling then
  begin
    if (Ship as TShip).ShipType in [t_Kling] then Result := 100 else Result := 0;
  end
  else if OwnerId = oiNone then Result := 100;
end;
{ @end $5C6388 }

{ @routine $5C6538 TPlanet_GetRelationLevelToShip }
function TPlanet.GetRelationLevelToShip(Ship: TObject): TRelationLevel;
begin
  case RelationToShip(Ship) of
    0..9: Result := rlHostile;
    10..29: Result := rlBad;
    30..59: Result := rlNormal;
    60..79: Result := rlGood;
    80..100: Result := rlExcellent;
  else Result := rlNormal;
  end;
end;
{ @end $5C6538 }

{ @routine $5C6578 TPlanet_GetRelationLevelTextToShip }
function TPlanet.GetRelationLevelTextToShip(Ship: TObject): WideString;
begin
  Result := aConst.RelationInfo[GetRelationLevelToShip(Ship)].DisplayName;
end;
{ @end $5C6578 }

{ @routine $5C65A8 TPlanet_GetCivilInfoText }
function TPlanet.GetCivilInfoText: WideString;
var Text: WideString;
begin
  Text := LocalizedText('Planet.Civil.Info.TextAboutPlanet');
  ReplaceTextToken(Text, '<Planet>', Name, HighlightColorTag);
  ReplaceTextToken(Text, '<Star>', CurrentStar.Name, HighlightColorTag);
  ReplaceTextToken(Text, '<Race>', GetNativeRaceName, HighlightColorTag);
  ReplaceTextToken(Text, '<Population>', WideString(IntToStr(Round(Population / 1000))), HighlightColorTag);
  ReplaceTextToken(Text, '<Economy>', PlanetEconomyInfo[Economy].DisplayName, HighlightColorTag);
  ReplaceTextToken(Text, '<Goverment>', GetGovernmentName, HighlightColorTag);
  ReplaceTextToken(Text, '<Relation>', GetRelationLevelTextToShip(Player), HighlightColorTag);
  if GetRelationLevelToShip(Player) <= rlBad then Text := Text + #13#10 + LocalizedText('Planet.Civil.Info.BadDopInfo');
  Result := Text;
end;
{ @end $5C65A8 }

{ @routine $5C68B8 TPlanet_HasHostileShipsInSystem }
function TPlanet.HasHostileShipsInSystem: Boolean;
var I: Integer; Ship: TShip;
begin
  for I := 0 to CurrentStar.Ships.Count - 1 do begin
    Ship := CurrentStar.Ships[I];
    if Ship.InNormalSpace and (RelationToShip(Ship) < 10) then begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
{ @end $5C68B8 }

{ @routine $5C6908 TPlanet_RefreshEquipmentShopInventory }
procedure TPlanet.RefreshEquipmentShopInventory;
var
  Index, Attempts, MinimumHull, MaximumHull, WeaponKind: Integer;
  Item: TEquipment;
  ItemType, WeaponType: TItemType;
begin
  if (Galaxy.CurrentTurn + Integer(GenerationSeed)) mod 7 = 0 then begin
    if (CalculateEquipmentShopTargetCount <= EquipmentShop.Count) and
      (SeededRandomUnitFloat(Galaxy.CurrentTurn + Integer(GenerationSeed) + 17) < 0.5) then begin
      Index := SeededRandomIntRange(0, EquipmentShop.Count - 1, Galaxy.CurrentTurn * GenerationSeed);
      Item := EquipmentShop[Index];
      if Item.ScriptItem = nil then begin
        EquipmentShop.Delete(Index);
        Item.Free;
      end;
    end;
    if ((CalculateEquipmentShopTargetCount >= EquipmentShop.Count) and
      (SeededRandomUnitFloat(Galaxy.CurrentTurn) < 0.5)) or
      (NextRandomIntRange(1, 100, RandomState) < 30) then begin
      Attempts := 0;
      repeat
        Inc(Attempts);
        ItemType := TItemType(SeededRandomIntRange(Ord(t_Hull), Ord(t_ZipGun), Galaxy.CurrentTurn * GenerationSeed * 175 + Attempts));
      // Native bug: rolls up to t_ZipGun, past the race's nine quotas.
      until (Attempts > 30) or
        (CountEquipmentShopItemsInBucket(ItemType) < PlanetEquipmentOfferQuotas[RaceId][Ord(ItemType) - Ord(t_Hull)]);
      case ItemType of
        t_Hull: begin
          if Player <> nil then begin
            MinimumHull := Player.Hull.Weight - 100;
            MaximumHull := Player.Hull.Weight + 100;
          end else begin
            MinimumHull := 250;
            MaximumHull := 300;
          end;
          Item := THull.Create;
          EquipmentShop.Add(Item);
          (Item as THull).Init(False,
            NextRandomIntRange(Max(MinimumHull, Round(500 * ItemSizeFactors[5])),
              Min(MaximumHull, Round(ItemSizeFactors[Galaxy.ScaleByTechLevel(4, 1)] * 500)), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invHull] div 2 - 1), InventionLevels[invHull], RandomState), RaceToOwner(RaceId));
        end;
        t_FuelTanks: begin
          Item := TFuelTanks.Create;
          EquipmentShop.Add(Item);
          (Item as TFuelTanks).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invFuelTanks] div 2 - 1), InventionLevels[invFuelTanks], RandomState), RaceToOwner(RaceId));
        end;
        t_Engine: begin
          Item := TEngine.Create;
          EquipmentShop.Add(Item);
          (Item as TEngine).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invEngineSpeed] div 2 - 1), InventionLevels[invEngineSpeed], RandomState), RaceToOwner(RaceId));
        end;
        t_Radar: begin
          Item := TRadar.Create;
          EquipmentShop.Add(Item);
          (Item as TRadar).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invRadarRange] div 2 - 1), InventionLevels[invRadarRange], RandomState), RaceToOwner(RaceId));
        end;
        t_Scaner: begin
          Item := TScaner.Create;
          EquipmentShop.Add(Item);
          (Item as TScaner).Init(False,
            NextRandomIntRange(Round(30 * ItemSizeFactors[5]), Round(30 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invScanner] div 2 - 1), InventionLevels[invScanner], RandomState), RaceToOwner(RaceId));
        end;
        t_RepairRobot: begin
          Item := TRepairRobot.Create;
          EquipmentShop.Add(Item);
          (Item as TRepairRobot).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invRepairRobot] div 2 - 1), InventionLevels[invRepairRobot], RandomState), RaceToOwner(RaceId));
        end;
        t_CargoHook: begin
          Item := TCargoHook.Create;
          EquipmentShop.Add(Item);
          (Item as TCargoHook).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invCargoHook] div 2 - 1), InventionLevels[invCargoHook], RandomState), RaceToOwner(RaceId));
        end;
        t_DefGenerator: begin
          Item := TDefGenerator.Create;
          EquipmentShop.Add(Item);
          (Item as TDefGenerator).Init(False,
            NextRandomIntRange(Round(40 * ItemSizeFactors[5]), Round(40 * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invTechLevel] div 2 - 1), InventionLevels[invTechLevel], RandomState), RaceToOwner(RaceId));
        end;
        t_PhotonGun..t_ZipGun: begin
          Item := TWeapon.Create;
          EquipmentShop.Add(Item);
          repeat
            WeaponKind := NextRandomIntRange(0, 14, RandomState) + Ord(t_PhotonGun);
            WriteByteValue(WeaponKind, WeaponType);
          until (WeaponInfo[WeaponType].RequiredTechLevel <= InventionLevels[invTechLevel]) and not (WeaponType in HeavyWeaponTypes);
          (Item as TWeapon).Init(WeaponType, False,
            NextRandomIntRange(Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[5]),
              Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[1]), RandomState),
            NextRandomIntRange(Max(1, InventionLevels[invTechLevel] div 2), InventionLevels[invTechLevel], RandomState), RaceToOwner(RaceId));
        end;
      else Item := nil;
      end;
      if Item <> nil then begin
        RemoveSimilarEquipmentShopItem(Item);
        case NextRandomIntRange(0, 100, RandomState) of
          0..5: Item.Improve(ikMinor);
          6..7: Item.Improve(ikMedium);
        end;
      end;
    end;
  end;
end;
{ @end $5C6908 }

{ @routine $5C70C0 TPlanet_CalculateEquipmentShopTargetCount }
function TPlanet.CalculateEquipmentShopTargetCount: Integer;
var Count: Integer; ItemType: TItemType;
begin
  Count := 0;
  for ItemType := t_Hull to WeaponCategoryItemType do Count := Count + PlanetEquipmentOfferQuotas[RaceId][Ord(ItemType) - Ord(t_Hull)];
  Result := Round(RemapClamped(Population, 100000, 1000000, 0.5, 1.3) * Count) +
    SeededRandomIntRange(-2, 2, (GenerationSeed - Galaxy.CurrentTurn) * 1011011);
  case Economy of
    peAgriculture: Dec(Result, 2);
    peIndustrial: Inc(Result, 2);
  end;
  Result := Max(10, Min(Result, 30));
end;
{ @end $5C70C0 }

{ @routine $5C7180 TPlanet_CountEquipmentShopItemsInBucket }
function TPlanet.CountEquipmentShopItemsInBucket(ItemType: TItemType): Integer;
var I, Count: Integer; Item: TItem;
begin
  Count := 0;
  for I := 0 to EquipmentShop.Count - 1 do begin
    Item := EquipmentShop[I];
    if (ItemType = Item.ItemType) or ((Item.ItemType in WeaponItemTypes) and (ItemType = WeaponCategoryItemType)) then Inc(Count);
  end;
  Result := Count;
end;
{ @end $5C7180 }

{ @routine $5C71DC TPlanet_RemoveSimilarEquipmentShopItem }
function TPlanet.RemoveSimilarEquipmentShopItem(Item: TEquipment): Boolean;
var
  I, Index: Integer;
  Candidate: TEquipment;
begin
  Result := False;
  Index := NextRandomIntRange(0, EquipmentShop.Count - 1, RandomState);
  for I := 0 to EquipmentShop.Count - 1 do begin
    IncrementWrapped(Index, 0, EquipmentShop.Count - 1);
    Candidate := EquipmentShop[Index];
    if (Item.ItemType <> Candidate.ItemType) or (Candidate = Item) or
      (Candidate.ScriptItem <> nil) then Continue;
    case Candidate.ItemType of
      t_Hull: if (Candidate as THull).TechLevel = (Item as THull).TechLevel then Result := True;
      t_FuelTanks: if (Candidate as TFuelTanks).TechLevel = (Item as TFuelTanks).TechLevel then Result := True;
      t_Engine: if (Candidate as TEngine).TechLevel = (Item as TEngine).TechLevel then Result := True;
      t_Radar: if (Candidate as TRadar).TechLevel = (Item as TRadar).TechLevel then Result := True;
      t_Scaner: if (Candidate as TScaner).TechLevel = (Item as TScaner).TechLevel then Result := True;
      t_RepairRobot: if (Candidate as TRepairRobot).TechLevel = (Item as TRepairRobot).TechLevel then Result := True;
      t_CargoHook: if (Candidate as TCargoHook).TechLevel = (Item as TCargoHook).TechLevel then Result := True;
      t_DefGenerator: if (Candidate as TDefGenerator).TechLevel = (Item as TDefGenerator).TechLevel then Result := True;
      t_PhotonGun..t_EyesOfMachpella: if (Item.ItemType = Candidate.ItemType) and
        ((Candidate as TWeapon).TechLevel = (Item as TWeapon).TechLevel) then Result := True;
    end;
    if Result then begin
      EquipmentShop.Delete(Index);
      Candidate.Free;
      Exit;
    end;
  end;
end;
{ @end $5C71DC }

{ @routine $5C7490 TPlanet_StartGoodsDecay }
procedure TPlanet.StartGoodsDecay(Enabled: Boolean; GoodsMask: TItemTypeMask);
var Kind: TGoodsIndex;
begin
  for Kind := t_Food to t_Narcotics do
    if Kind in GoodsMask then
    begin
      Goods[Kind].PriceState := GoodsMarket[Kind].MaxPrice;
      Goods[Kind].Count := Min(Goods[Kind].Count, GoodsMarket[Kind].BaseStock div 10);
      Goods[Kind].PurchasePrice := Round(Goods[Kind].PriceState);
      Goods[Kind].BaseSalePrice := Max(1, Round(Goods[Kind].PriceState * 0.98 - 1));
      if Enabled then
        GoodsScarcityTicks[Kind] := Round(30 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor)
      else if GoodsScarcityTicks[Kind] > 0 then Dec(GoodsScarcityTicks[Kind]);
    end;
end;
{ @end $5C7490 }

{ @routine $5C75B0 TPlanet_StartGoodsUpsurge }
procedure TPlanet.StartGoodsUpsurge(Enabled: Boolean; GoodsMask: TItemTypeMask);
var Kind: TGoodsIndex;
begin
  for Kind := t_Food to t_Narcotics do
    if Kind in GoodsMask then
    begin
      Goods[Kind].PriceState := GoodsMarket[Kind].MinPrice;
      Goods[Kind].Count := Min(Goods[Kind].Count + GoodsMarket[Kind].BaseStock div 5, GoodsMarket[Kind].BaseStock * 3);
      Goods[Kind].PurchasePrice := Round(Goods[Kind].PriceState);
      Goods[Kind].BaseSalePrice := Max(1, Round(Goods[Kind].PriceState * 0.98 - 1));
      if Enabled then
        GoodsSurplusTicks[Kind] := Round(30 * DifficultyModifiers[Galaxy.Difficulty].CareerExperienceFactor)
      else if GoodsSurplusTicks[Kind] > 0 then Dec(GoodsSurplusTicks[Kind]);
    end;
end;
{ @end $5C75B0 }
{ @routine $5C7834 TPlanet_BuildGovernmentGreeting }
function TPlanet.BuildGovernmentGreeting: WideString;
var
  Rules: array of TGovGreetingsInfo;
  HighIndex: Integer;
  SwapA, SwapB: TGovGreetingsInfo;
  UnusedText, Greeting: WideString;
  NearStarIndex, I, Minimum, RuleIndex, BestPriority, Priority: Integer;
  Good: TItemType;
  Rejected, FoundPlanet: Boolean;
  Star: TStar;
  Planet: TPlanet;
  ShipType: TShipType;
  CountMask: set of 0..15;
  Attempt: Integer;

  // @nested $5C76F4 PrepareRules
  procedure PrepareRules; // @addr $5C76F4
  var
    I, J: Integer;
  begin
    SetLength(Rules, GovernmentGreetingCount);
    for I := 0 to HighIndex - 1 do Rules[I] := GovernmentGreetingDefinitions[I];
    for I := 0 to HighIndex div 2 do
    begin
      J := SeededRandomIntRange(0, HighIndex, Id + 7 * I + aGalaxy.Galaxy.CurrentTurn div 7);
      SwapA := Rules[J];
      SwapB := Rules[I];
      Rules[I] := SwapA;
      Rules[J] := SwapB;
    end;
  end;

begin
  Result := '';
  UnusedText := '';
  BestPriority := -1;
  Priority := -1;
  Minimum := 0;
  HighIndex := GovernmentGreetingCount - 1;
  PrepareRules;
  RuleIndex := SeededRandomIntRange(0, HighIndex, (Integer(Id) * aGalaxy.Galaxy.CurrentTurn) div 20);
  for Attempt := 0 to HighIndex do
  begin
    Greeting := '';
    IncrementWrapped(RuleIndex, Minimum, HighIndex);
    if BestPriority > 0 then
    begin
      Priority := Rules[RuleIndex].Priority;
      if Priority * SeededRandomIntRange(1, 100, Id + RuleIndex * (aGalaxy.Galaxy.CurrentTurn div 20)) <
        BestPriority * SeededRandomIntRange(1, 100, Id + RuleIndex * (aGalaxy.Galaxy.CurrentTurn div 20) * 3) then Continue;
    end;
    if (Rules[RuleIndex].PlayerRace <> []) and not (Player.OwnerId in Rules[RuleIndex].PlayerRace) then Continue;
    if (Rules[RuleIndex].PlayerStatus <> []) and not (Player.GetDominantCareer in Rules[RuleIndex].PlayerStatus) then Continue;
    if (Rules[RuleIndex].PlayerRating <> []) and not (Player.GetRangerRatingBand in Rules[RuleIndex].PlayerRating) then Continue;
    if (Rules[RuleIndex].PlayerRank <> []) and not (Player.Rank in Rules[RuleIndex].PlayerRank) then Continue;
    Good := GreetingSelectionNoGoods;
    if Rules[RuleIndex].Goods <> GreetingDefinitionNoGoods then Good := Rules[RuleIndex].Goods;
    Greeting := LocalizedColorText('GovGreetings.' + Rules[RuleIndex].Name + '.Text');
    if (Rules[RuleIndex].CurPlanetRace <> []) and not (OwnerId in Rules[RuleIndex].CurPlanetRace) then Continue;

    if Rules[RuleIndex].CurPlanetRaceIsPlayerRace <> gcAny then
    begin
      if (Rules[RuleIndex].CurPlanetRaceIsPlayerRace = gcYes) and (OwnerId <> Player.OwnerId) then Continue;
      if (Rules[RuleIndex].CurPlanetRaceIsPlayerRace = gcNo) and (OwnerId = Player.OwnerId) then Continue;
    end;
    if (Rules[RuleIndex].CurPlanetRelations <> [])
      and not (GetRelationLevelToShip(Player) in Rules[RuleIndex].CurPlanetRelations) then Continue;
    if Good <> GreetingSelectionNoGoods then
    begin

      if (Rules[RuleIndex].CurPlanetGoodsCnt <> [])
        and not (aGalaxy.Galaxy.ClassifyGoodsQuantity(Goods[Good].Count, Good) in Rules[RuleIndex].CurPlanetGoodsCnt) then Continue;
      if (Rules[RuleIndex].CurPlanetGoodsSale <> [])
        and not (aGalaxy.Galaxy.ClassifyGoodsPrice(Goods[Good].PurchasePrice, Good) in Rules[RuleIndex].CurPlanetGoodsSale) then Continue;
      if (Rules[RuleIndex].CurPlanetGoodsBuy <> [])
        and not (aGalaxy.Galaxy.ClassifyGoodsPrice(Goods[Good].BaseSalePrice, Good) in Rules[RuleIndex].CurPlanetGoodsBuy) then Continue;
    end;
    if (Rules[RuleIndex].CurPlanetEconomy <> []) and not (Economy in Rules[RuleIndex].CurPlanetEconomy) then Continue;
    if (Rules[RuleIndex].CurPlanetGovernment <> []) and not (Government in Rules[RuleIndex].CurPlanetGovernment) then Continue;
    Rejected := False;
    for ShipType := t_Kling to t_Warrior do
    begin
      case ShipType of
        t_Kling: CountMask := Rules[RuleIndex].KlingInCurStar;
        t_Ranger: CountMask := Rules[RuleIndex].RangerInCurStar;
        t_Pirate: CountMask := Rules[RuleIndex].PirateInCurStar;
        t_Warrior: CountMask := Rules[RuleIndex].WarriorInCurStar;
        t_Transport: CountMask := Rules[RuleIndex].TransportInCurStar;
        else RaiseWideMessage('function TPlanet.GovGreeting:WideString;');
      end;
      if CountMask <> [] then
      begin
        if not (Min(10, CurrentStar.ShipTypeCounts[ShipType]) in CountMask) then
        begin
          Rejected := True;
          Break;
        end;
      end;
    end;
    if Rejected then Continue;
    if Rules[RuleIndex].CurStarInBattle <> gcAny then
    begin
      if (Rules[RuleIndex].CurStarInBattle = gcYes) and (not (CurrentStar.Battle)) then Continue;
      if (Rules[RuleIndex].CurStarInBattle = gcNo) and (CurrentStar.Battle) then Continue;
    end;

    if Rules[RuleIndex].ToPlanetRace <> [] then
    begin
      FoundPlanet := False;
      for NearStarIndex := 0 to 7 do
      begin
        Star := CurrentStar.StarDistances[NearStarIndex].Star as TStar;
        if not Star.Constellation.Visible then Continue;
        if Rules[RuleIndex].ToPlanetInCurStar <> gcAny then
        begin
          if (Rules[RuleIndex].ToPlanetInCurStar = gcYes) and (CurrentStar <> Star) then Continue;
          if (Rules[RuleIndex].ToPlanetInCurStar = gcNo) and (CurrentStar = Star) then Continue;
        end;
        Rejected := False;
        for ShipType := t_Kling to t_Warrior do
        begin
          case ShipType of
            t_Kling: CountMask := Rules[RuleIndex].KlingInToStar;
            t_Ranger: CountMask := Rules[RuleIndex].RangerInToStar;
            t_Pirate: CountMask := Rules[RuleIndex].PirateInToStar;
            t_Warrior: CountMask := Rules[RuleIndex].WarriorInToStar;
            t_Transport: CountMask := Rules[RuleIndex].TransportInToStar;
            else RaiseWideMessage('function TPlanet.GovGreeting:WideString;');
          end;
          if CountMask <> [] then
          begin
            if not (Min(10, Star.ShipTypeCounts[ShipType]) in CountMask) then
            begin
              Rejected := True;
              Break;
            end;
          end;
        end;
        if Rejected then Continue;
        if Rules[RuleIndex].ToStarControlByKling <> gcAny then
        begin
          if (Rules[RuleIndex].ToStarControlByKling = gcYes) and (Star.ControlFaction <> sfKlissan) then Continue;
          if (Rules[RuleIndex].ToStarControlByKling = gcNo) and (Star.ControlFaction = sfKlissan) then Continue;
        end;
        if Rules[RuleIndex].ToStarInBattle <> gcAny then
        begin
          if (Rules[RuleIndex].ToStarInBattle = gcYes) and (not Boolean(Star.Battle)) then Continue;
          if (Rules[RuleIndex].ToStarInBattle = gcNo) and (Boolean(Star.Battle)) then Continue;
        end;
        for I := 0 to Star.Planets.Count - 1 do
        begin
          Planet := TPlanet(Star.Planets[I]);
          if Planet = Self then Continue;
          if not (Planet.OwnerId in Rules[RuleIndex].ToPlanetRace) then Continue;
          if Rules[RuleIndex].ToPlanetRaceIsPlayerRace <> gcAny then
          begin
            if (Rules[RuleIndex].ToPlanetRaceIsPlayerRace = gcYes) and (Player.OwnerId <> Planet.OwnerId) then Continue;
            if (Rules[RuleIndex].ToPlanetRaceIsPlayerRace = gcNo) and (Player.OwnerId = Planet.OwnerId) then Continue;
          end;
          if Rules[RuleIndex].ToPlanetRaceIsCurPlanetRace <> gcAny then
          begin
            if (Rules[RuleIndex].ToPlanetRaceIsCurPlanetRace = gcYes) and (OwnerId <> Planet.OwnerId) then Continue;
            if (Rules[RuleIndex].ToPlanetRaceIsCurPlanetRace = gcNo) and (OwnerId = Planet.OwnerId) then Continue;
          end;
          if Rules[RuleIndex].ToPlanetRelations <> [] then
          begin
            if not (Planet.GetRelationLevelToShip(Player) in Rules[RuleIndex].ToPlanetRelations) then Continue;
          end;
          if Good <> GreetingSelectionNoGoods then
          begin

            if (Rules[RuleIndex].ToPlanetGoodsCnt <> [])
              and not (aGalaxy.Galaxy.ClassifyGoodsQuantity(Planet.Goods[Good].Count, Good) in Rules[RuleIndex].ToPlanetGoodsCnt) then Continue;
            if (Rules[RuleIndex].ToPlanetGoodsSale <> [])
              and not (aGalaxy.Galaxy.ClassifyGoodsPrice(Planet.Goods[Good].PurchasePrice, Good) in Rules[RuleIndex].ToPlanetGoodsSale) then Continue;
            if (Rules[RuleIndex].ToPlanetGoodsBuy <> [])
              and not (aGalaxy.Galaxy.ClassifyGoodsPrice(Planet.Goods[Good].BaseSalePrice, Good) in Rules[RuleIndex].ToPlanetGoodsBuy) then Continue;
          end;
          if (Rules[RuleIndex].ToPlanetEconomy <> []) and not (Planet.Economy in Rules[RuleIndex].ToPlanetEconomy) then Continue;
          if (Rules[RuleIndex].ToPlanetGovernment <> []) and not (Planet.Government in Rules[RuleIndex].ToPlanetGovernment) then Continue;
          Greeting := ReplaceColoredToken(Greeting, '<ToPlanet>', Planet.Name, HighlightColorTag);
          Greeting := ReplaceColoredToken(Greeting, '<ToStar>', Planet.CurrentStar.Name, HighlightColorTag);
          if Good <> GreetingSelectionNoGoods then
          begin
            Greeting := ReplaceColoredToken(Greeting, '<ToPlanetGoodsCnt>', WideString(IntToStr(Planet.Goods[Good].Count)), HighlightColorTag);
            Greeting := ReplaceColoredToken(Greeting, '<ToPlanetGoodsSale>', WideString(IntToStr(Planet.Goods[Good].PurchasePrice)), HighlightColorTag);
            Greeting := ReplaceColoredToken(Greeting, '<ToPlanetGoodsBuy>', WideString(IntToStr(Planet.Goods[Good].BaseSalePrice)), HighlightColorTag);
          end;
          FoundPlanet := True;
          Break;
        end;
        if FoundPlanet then Break;
      end;
      if not FoundPlanet then Continue;
    end;
    if Greeting <> '' then
    begin
      Result := Greeting;
      Result := ReplaceColoredToken(Result, '<PlayerRank>', Player.GetRankName, HighlightColorTag);
      Result := ReplaceColoredToken(Result, '<CurPlanet>', Name, HighlightColorTag);
      Result := ReplaceColoredToken(Result, '<CurStar>', CurrentStar.Name, HighlightColorTag);
      if Good <> GreetingSelectionNoGoods then
      begin
        Result := ReplaceColoredToken(Result, '<CurPlanetGoodsCnt>', WideString(IntToStr(Goods[Good].Count)), HighlightColorTag);
        Result := ReplaceColoredToken(Result, '<CurPlanetGoodsSale>', WideString(IntToStr(Goods[Good].PurchasePrice)), HighlightColorTag);
        Result := ReplaceColoredToken(Result, '<CurPlanetGoodsBuy>', WideString(IntToStr(Goods[Good].BaseSalePrice)), HighlightColorTag);
      end;
      if Priority = -1 then BestPriority := Rules[RuleIndex].Priority
      else BestPriority := Priority;
      if BestPriority >= 50 then Exit;
    end;
  end;
end;
{ @end $5C7834 }

end.

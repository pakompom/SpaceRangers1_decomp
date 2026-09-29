unit aNormalShip;
// Unit bracket (inferred): CODE 0x005A6168..0x005AA9CF; inclusive evidence, not full bounds.
interface
// Create $5A6258 and save/load $5A6334/$5A63FC establish the complete extension.
uses aShip, aPlanet, EC_Buf, aConst, aGalaxy;
type
  TNormalShip = class(TShip) // @size $1CC
  public
    procedure TrainSkillsAutomatically; virtual; abstract; // @slot $94 Added by TNormalShip; station descendants use their own slot $94.
    function SelectAward(Owner: TOwnerId; Kinds: TAwardTypeMask): Byte; // @addr $5A75D4
    function GetRankName: WideString; // @addr $5A79D8
    function GetRankLongName: WideString; // @addr $5A7A68
    function GetRankDescription: WideString; // @addr $5A7B00
    function GetNextRankName: WideString; // @addr $5A7B90
    function GetRankPointsToNextRank: Word; // @addr $5A7C20
    procedure RecordShipKill(Victim: TShip); // @addr $5A6F10
    procedure AddRankPoints(Amount: Word); // @addr $5A7C60
    function TryPromoteRank: Boolean; // @addr $5A7C84
    function CanPromoteRank: Boolean; // @addr $5A7CB4
    procedure UpdateRelationsForNearbyCombat; // @addr $5A7464 Nearby rangers attacking a friend incur a penalty; attacks on an enemy can improve relations.
    function GetAwardInfo(AwardId: Byte): TRewardInfo; // @addr $5A789C
    function SelectSituationalMessage(Automatic: Boolean): WideString; // @addr $5A7E30
    LastDockedPlanet: TPlanet; // @offset $1B0
    ScriptStatistics: array[TShipStatistic] of Word; // @offset $1B4 Script.ShipStatistic $52DCBC.
    CurrentSystemKillCount: Word; // @offset $1BC
    PendingLiberationCeremonyPlanet: TPlanet; // @offset $1C0
    Rank: TCoalitionRank; // @offset $1C4
    RankPoints: Word; // @offset $1C6
    LastPlayerExtortionTurn: Integer; // @offset $1C8 Present in save versions 8 and later.

    function CollectLiberationRewards: WideString; // @addr $5A6684
    procedure NextDay; override; // @addr $5A6504
    constructor Create; // @addr $5A6258
    destructor Destroy; override; // @addr $5A62E4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5A6334
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5A63FC
    procedure ResolveLoadedReferences; override; // @addr $5A64B0
  end;
procedure ProcessSystemLiberationRewards(SourceShip: TNormalShip; Star: TStar); // @addr $5A7188 SourceShip supplies the news-variant seed.

implementation

// @unit-initialization $5AA9C8
// @unit-finalization $5AA998

uses aKling, aPirate, aTranclucator, aItem, EC_Str, Classes, Math, aRanger, GR_Main, SysUtils, Globals, aGalaxy, aMyFunction, GlobalsV, aPlayer;

{ @routine $5A6258 TNormalShip_Create }
constructor TNormalShip.Create;
begin
  inherited Create;
  ScriptStatistics[ssShipsKilled] := 0;
  ScriptStatistics[ssPiratesKilled] := 0;
  ScriptStatistics[ssKlissansKilled] := 0;
  ScriptStatistics[ssSystemsLiberated] := 0;
  CurrentSystemKillCount := 0;
  PendingLiberationCeremonyPlanet := nil;
  Rank := crRookie;
  RankPoints := 0;
  LastDockedPlanet := nil;
  LastPlayerExtortionTurn := 0;
end;
{ @end $5A6258 }

{ @routine $5A62E4 TNormalShip_Destroy }
destructor TNormalShip.Destroy;
var Career: TRangerCareer;
begin
  for Career := Low(TRangerCareer) to High(TRangerCareer) do
    if Galaxy.EminentCareerShips[Career] = Self then Galaxy.EminentCareerShips[Career] := nil;
  inherited Destroy;
end;
{ @end $5A62E4 }

{ @routine $5A6334 TNormalShip_SaveToBuffer }
procedure TNormalShip.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddWideChar(WideChar(ScriptStatistics[ssShipsKilled]));
  Buffer.AddWideChar(WideChar(ScriptStatistics[ssPiratesKilled]));
  Buffer.AddWideChar(WideChar(ScriptStatistics[ssKlissansKilled]));
  Buffer.AddWideChar(WideChar(ScriptStatistics[ssSystemsLiberated]));
  Buffer.AddWideChar(WideChar(CurrentSystemKillCount));
  if PendingLiberationCeremonyPlanet = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(PendingLiberationCeremonyPlanet.Id);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Rank)));
  Buffer.AddWideChar(WideChar(RankPoints));
  if LastDockedPlanet = nil then Buffer.AddDWord(0)
  else Buffer.AddDWord(LastDockedPlanet.Id);
  Buffer.AddIntegerValue(LastPlayerExtortionTurn);
end;
{ @end $5A6334 }

{ @routine $5A63FC TNormalShip_LoadFromBuffer }
procedure TNormalShip.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  ScriptStatistics[ssShipsKilled] := Buffer.GetWord;
  ScriptStatistics[ssPiratesKilled] := Buffer.GetWord;
  ScriptStatistics[ssKlissansKilled] := Buffer.GetWord;
  ScriptStatistics[ssSystemsLiberated] := Buffer.GetWord;
  CurrentSystemKillCount := Buffer.GetWord;
  PendingLiberationCeremonyPlanet := TPlanet(Buffer.GetUInt32);
  WriteByteValue(Buffer.GetByte, Rank);
  RankPoints := Buffer.GetWord;
  LastDockedPlanet := TPlanet(Buffer.GetUInt32);
  if LoadedSaveVersion >= 8 then LastPlayerExtortionTurn := Buffer.GetInt32
  else LastPlayerExtortionTurn := 0;
end;
{ @end $5A63FC }

{ @routine $5A64B0 TNormalShip_ResolveLoadedReferences }
procedure TNormalShip.ResolveLoadedReferences;
begin
  inherited ResolveLoadedReferences;
  PendingLiberationCeremonyPlanet := Galaxy.IdToPlanet(Cardinal(PendingLiberationCeremonyPlanet)) as TPlanet;
  LastDockedPlanet := Galaxy.IdToPlanet(Cardinal(LastDockedPlanet)) as TPlanet;
end;
{ @end $5A64B0 }

{ @routine $5A6504 TNormalShip_NextDay }
procedure TNormalShip.NextDay;
var MessageText: WideString;
begin
  inherited NextDay;
  if InHyperspace then CurrentSystemKillCount := 0;
  if (Self = Player) and not Player.ProcessPendingPlayerFollowTargeting then Exit;
  if (CurrentPlanet <> nil) and (CurrentPlanet = PendingLiberationCeremonyPlanet) then CollectLiberationRewards;
  RecomputeFearState;
  if (Player.CurrentStar = CurrentStar) and (Order <> soNone) and PlayerStarDayPrepared and
    (TurnsSinceLastShipMessage > 5) and ((Galaxy.CurrentTurn * Integer(Seed)) mod 7 = 0) and
    InNormalSpace and Player.InNormalSpace and (GetRadarRange > PointDistance(Position, Player.Position)) and
    not PlayerAutomaticControl and not Player.ProcessPendingPlayerFollowTargeting and
    (ScriptShip = nil) and (LiberationGroup = nil) then begin
    MessageText := SelectSituationalMessage(True);
    if MessageText <> '' then ShowMessageToPlayer(MessageText);
  end;
  UpdateRelationsForNearbyCombat;
end;
{ @end $5A6504 }

{ @routine $5A6684 TNormalShip_CollectLiberationRewards }
function TNormalShip.CollectLiberationRewards: WideString;
var
  Award: Byte;
  AwardWeight, ExperienceWeight, ArtefactWeight: Single;
  RewardKind, Quantity: Integer;
  AwardEntry: PByte;
  RewardItem: TArtefact;
begin
  if AwardIds = nil then AwardWeight := 80
  else AwardWeight := RemapClampedAlternate(AwardIds.Count, 0, 15, 80, 10);
  if Self is TRanger then
    ExperienceWeight := RemapClamped((Self as TRanger).PlaceInRating, 1, Galaxy.Rangers.Count, 0, 80)
  else ExperienceWeight := 0;
  if Self is TPlayer then ArtefactWeight := RemapClampedAlternate(Artefacts.Count, 0, 5, 80, 20)
  else ArtefactWeight := 0;
  if (AwardWeight = 0) and (ExperienceWeight = 0) and (ArtefactWeight = 0) then AwardWeight := 1;
  if AwardWeight > 0 then AwardWeight := AwardWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 100 + 1667);
  if ExperienceWeight > 0 then ExperienceWeight := ExperienceWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 100 + 197673);
  if ArtefactWeight > 0 then ArtefactWeight := ArtefactWeight * SeededRandomIntRange(5, 25, CurrentPlanet.GenerationSeed + Galaxy.CurrentTurn div 100 + 719671);
  if (AwardWeight > 0) and (AwardWeight >= Max(ExperienceWeight, ArtefactWeight)) then RewardKind := 1
  else if (ExperienceWeight > 0) and (ExperienceWeight >= Max(AwardWeight, ArtefactWeight)) then RewardKind := 2
  else if (ArtefactWeight > 0) and (ArtefactWeight >= Max(AwardWeight, ExperienceWeight)) then RewardKind := 3
  else
  begin
    RaiseWideMessage('CongratulationsLiberator');
    RewardKind := 0;
  end;
  if Player = Self then
    Result := LocalizedColorText('PlanetCongratulations.LiberationStar.' + OwnerToSys(CurrentPlanet.OwnerId) + 'Text')
  else Result := '';
  case RewardKind of
    1: begin
      Award := SelectAward(CurrentPlanet.OwnerId, [atForLiberationSystem, atForAccomplishment]);
      if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
      if AwardIds = nil then AwardIds := TList.Create;
      GetMem(AwardEntry, 1);
      AwardIds.Add(AwardEntry);
      AwardEntry^ := Award;
      if Player = Self then
      begin
        Result := Result + #13#10 + LocalizedColorText('PlanetCongratulations.LiberationStar.AddReward');
        ReplaceTextToken(Result, '<Reward>', GetAwardInfo(Award).Name, HighlightColorTag);
      end
      else Result := '';
    end;
    2: begin
      Quantity := SeededRandomIntRange(25, 70, (Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div 100);
      GainExperience(Quantity);
      if Player = Self then
      begin
        Result := Result + #13#10 + LocalizedColorText('PlanetCongratulations.LiberationStar.AddPoints');
        ReplaceTextToken(Result, '<Points>', IntToStr(Quantity), HighlightColorTag);
      end
      else Result := '';
    end;
    3: begin
      RewardItem := CreateRandomArtefact((Integer(CurrentPlanet.GenerationSeed) + Galaxy.CurrentTurn) div 100 + 767, CurrentPlanet.OwnerId) as TArtefact;
      if RewardItem is TArtefactTranclucator then ((RewardItem as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Self;
      Artefacts.Add(RewardItem);
      if Player = Self then
      begin
        Result := Result + #13#10 + LocalizedColorText('PlanetCongratulations.LiberationStar.AddArtefact') + #13#10 + RewardItem.GetDescriptionText;
        ReplaceTextToken(Result, '<Artefact>', RewardItem.GetDisplayName, HighlightColorTag);
      end
      else Result := '';
    end;
  end;
  if Player = Self then
  begin
    ReplaceTextToken(Result, '<Star>', CurrentPlanet.CurrentStar.Name, HighlightColorTag);
    ReplaceTextToken(Result, '<Planet>', CurrentPlanet.Name, HighlightColorTag);
  end;
  PendingLiberationCeremonyPlanet := nil;
end;
{ @end $5A6684 }

{ @routine $5A6F10 TNormalShip_RecordShipKill }
procedure TNormalShip.RecordShipKill(Victim: TShip);
var Activity: Integer;
begin
  Inc(ScriptStatistics[ssShipsKilled]);
  if (Victim.ShipType = t_Transport) and (Self is TRanger) then
  begin
    if Self = Player then Activity := 4 else Activity := 1;
    (Self as TRanger).AddPirateCareerActivity(Activity);
  end
  else if (Victim is TRanger) and (Self is TRanger) then
  begin
    if (Victim as TRanger).GetDominantCareer = rcPirate then
    begin
      AddRankPoints(10);
      (Self as TRanger).AddWarriorCareerActivity(4);
    end
    else
    begin
      if Self = Player then Activity := 8 else Activity := 2;
      (Self as TRanger).AddPirateCareerActivity(Activity);
    end;
  end
  else if Victim is TPirate then
  begin
    Inc(ScriptStatistics[ssPiratesKilled]);
    if Self is TRanger then
    begin
      AddRankPoints(10);
      (Self as TRanger).AddWarriorCareerActivity(4);
    end;
  end
  else if Victim is TKling then
  begin
    Inc(ScriptStatistics[ssKlissansKilled]);
    Inc(CurrentSystemKillCount);
    AddRankPoints(KlissanInfo[(Victim as TKling).KlingType].RankPoints);
    if Self is TRanger then
    begin
      if Self = Player then Activity := 4 else Activity := 8;
      (Self as TRanger).AddWarriorCareerActivity(Activity);
      if Self = Player then Player.ResetCounterAfterNodeDeposit;
      if (PartnerShip <> nil) and (PartnerShip is TNormalShip) and
        (PartnerShip.CurrentStar = CurrentStar) and PartnerShip.InNormalSpace then
      begin
        (PartnerShip as TNormalShip).AddRankPoints((KlissanInfo[(Victim as TKling).KlingType].RankPoints shr 1) + 1);
        if Player = PartnerShip then
        begin
          Player.ResetCounterAfterNodeDeposit;
          if Player.CurrentSystemKillCount = 0 then Inc(Player.CurrentSystemKillCount);
        end;
      end;
    end;
  end;
end;
{ @end $5A6F10 }

{ @routine $5A7188 ProcessSystemLiberationRewards }
procedure ProcessSystemLiberationRewards(SourceShip: TNormalShip; Star: TStar);
var I, J: Integer; Ship: TShip; Normal: TNormalShip; CeremonyPlanet, Planet: TPlanet; Text: WideString;
begin
  CeremonyPlanet := Star.FindFirstInhabitedPlanet as TPlanet;
  for I := 0 to Star.Ships.Count - 1 do begin
    Ship := Star.Ships[I];
    if Ship is TNormalShip then begin
      Normal := Ship as TNormalShip;
      if (Normal.CurrentSystemKillCount > 0) or ((Ship <> Player) and (Ship.DaysSincePlayerSeen > 1) and
        (Normal.ScriptStatistics[ssKlissansKilled] > Normal.ScriptStatistics[ssSystemsLiberated])) then begin
        Normal.CurrentSystemKillCount := 0;
        if Normal = Player then Player.ResetCounterAfterNodeDeposit;
        Inc(Normal.ScriptStatistics[ssSystemsLiberated]);
        Normal.PendingLiberationCeremonyPlanet := CeremonyPlanet;
        Normal.AddRankPoints(30);
        if Ship is TRanger then
          for J := 0 to Star.Planets.Count - 1 do begin
            Planet := Star.Planets[J];
            if Planet.IsCoalitionOwned then Planet.ChangeRelationToRanger(Ship, 100);
          end;
        if Ship.InNormalSpace and ((Ship <> Player) or PlayerAutomaticControl) then Ship.OrderLanding(CeremonyPlanet, True);
      end;
    end;
  end;
  Text := FormatText3(PickLocalizedTextVariant('GalaxyNews.Globals.LiberationSystem',
    (Galaxy.CurrentTurn div 10) * SourceShip.Seed), HighlightColorTag, '<Star>', Star.Name,
    '<Sector>', Star.Constellation.GetName, '<Planet>', CeremonyPlanet.Name);
  Galaxy.AddPlanetNewsWithPlayerBubble(Text);
end;
{ @end $5A7188 }

{ @routine $5A7464 TNormalShip_UpdateRelationsForNearbyCombat }
procedure TNormalShip.UpdateRelationsForNearbyCombat;
var
  I: Integer;
  Ship, Target: TShip;
  Ranger: TRanger;
  Change: Boolean;
begin
  if not InNormalSpace or (Player = Self) then Exit;
  for I := 0 to CurrentStar.Ships.Count - 1 do
  begin
    Ship := CurrentStar.Ships[I];
    if not (Ship is TRanger) or (Ship = Self) or not Ship.InNormalSpace then Continue;
    begin
      Ranger := Ship as TRanger;
      if not (Ranger.OrderTarget is TShip) or
        (Ranger.OrderTarget <> Ranger.EnemyShip) then Continue;
      begin
        Target := Ranger.OrderTarget as TShip;
        if GetRelationLevelToShip(Target) = rlExcellent then
        begin
          if (Player = Ship) or (NextRandomUnitFloat(RandomState) <= 0.1) then
          begin
            Change := (Target.OrderTarget <> Ranger) and
              (Target.GetRelationLevelToShip(Ranger) = rlHostile);
            if Change then ChangeRelationToRanger(Ranger, -2);
          end;
        end
        else if GetRelationLevelToShip(Target) = rlHostile then
        begin
          Change := Target.GetRelationLevelToShip(Ranger) = rlHostile;
          if Change then ChangeRelationToRanger(Ranger, 2);
        end;
      end;
    end;
  end;
end;
{ @end $5A7464 }

{ @routine $5A75D4 TNormalShip_SelectAward }
function TNormalShip.SelectAward(Owner: TOwnerId; Kinds: TAwardTypeMask): Byte;
var I, Count: Integer; Candidates: TList; Award: PByte;
begin
  Candidates := TList.Create;
  Count := StrToInt(LookupLocalizedTextByKey('Reward.Count')) - 1;
  for I := 0 to Count do
    if MatchesOwnerName(Owner, LookupLocalizedTextByKey('Reward.' + IntToStr(I) + '.Race')) and
      (SysToReward(LookupLocalizedTextByKey('Reward.' + IntToStr(I) + '.Type')) in Kinds) and
      MatchesCareerName(GetDominantCareer, LookupLocalizedTextByKey('Reward.' + IntToStr(I) + '.Status')) then begin
      New(Award);
      Award^ := I;
      Candidates.Add(Award);
    end;
  if Candidates.Count > 0 then begin
    Award := Candidates[SeededRandomIntRange(0, Candidates.Count - 1, (Integer(Seed) + Galaxy.CurrentTurn) div 101)];
    Result := Award^;
  end else Result := 255;
  for I := Candidates.Count - 1 downto 0 do begin
    Award := Candidates[I];
    Candidates.Delete(I);
    Dispose(Award);
  end;
  Candidates.Free;
end;
{ @end $5A75D4 }

{ @routine $5A789C TNormalShip_GetAwardInfo }
function TNormalShip.GetAwardInfo(AwardId: Byte): TRewardInfo;
begin
  Result.AwardId := AwardId;
  Result.Name := LookupLocalizedTextByKey('Reward.' + IntToStr(AwardId) + '.Name');
  Result.Text := LookupLocalizedTextByKey('Reward.' + IntToStr(AwardId) + '.Text');
end;
{ @end $5A789C }

{ @routine $5A79D8 TNormalShip_GetRankName }
function TNormalShip.GetRankName: WideString;
begin
  Result := LocalizedText('Rank.' + CoalitionRankNames[Rank] + '.Name');
end;
{ @end $5A79D8 }

{ @routine $5A7A68 TNormalShip_GetRankLongName }
function TNormalShip.GetRankLongName: WideString;
begin
  Result := LocalizedText('Rank.' + CoalitionRankNames[Rank] + '.NameBig');
end;
{ @end $5A7A68 }

{ @routine $5A7B00 TNormalShip_GetRankDescription }
function TNormalShip.GetRankDescription: WideString;
begin
  Result := LocalizedColorText('Rank.' + CoalitionRankNames[Rank] + '.Text');
end;
{ @end $5A7B00 }

{ @routine $5A7B90 TNormalShip_GetNextRankName }
function TNormalShip.GetNextRankName: WideString;
begin
  Result := LocalizedText('Rank.' + CoalitionRankNames[Succ(Rank)] + '.Name');
end;
{ @end $5A7B90 }

{ @routine $5A7C20 TNormalShip_GetRankPointsToNextRank }
function TNormalShip.GetRankPointsToNextRank: Word;
begin
  if (Rank < crCommander) and (CoalitionRankPointThresholds[Rank] > RankPoints) then
    Result := CoalitionRankPointThresholds[Rank] - RankPoints
  else Result := 0;
end;
{ @end $5A7C20 }

{ @routine $5A7C60 TNormalShip_AddRankPoints }
procedure TNormalShip.AddRankPoints(Amount: Word);
begin
  Inc(RankPoints, Min(Amount, GetRankPointsToNextRank));
end;
{ @end $5A7C60 }

{ @routine $5A7C84 TNormalShip_TryPromoteRank }
function TNormalShip.TryPromoteRank: Boolean;
begin
  if (Rank < crCommander) and (GetRankPointsToNextRank = 0) then
  begin
    Inc(Rank);
    RankPoints := 0;
    Result := True;
  end
  else Result := False;
end;
{ @end $5A7C84 }

{ @routine $5A7CB4 TNormalShip_CanPromoteRank }
function TNormalShip.CanPromoteRank: Boolean;
begin
  Result := (Rank < crCommander) and (GetRankPointsToNextRank = 0);
end;
{ @end $5A7CB4 }

{ @routine $5A7E30 TNormalShip_SelectSituationalMessage }
function TNormalShip.SelectSituationalMessage(Automatic: Boolean): WideString;
const FullNameSeparator = WideString(' ');
var
  Definitions: array of TShipGreetingsInfo;
  LastIndex: Integer;
  SwapA, SwapB: TShipGreetingsInfo;
  ItemTypes, MessageText, BestText: WideString;
  I, J, Count, Minimum, EntryIndex, BestPriority, CandidatePriority: Integer;
  Good: TItemType;
  Rejected: Boolean;
  Planet: TPlanet;
  Item: TItem;
  ShipKind: TShipType;
  LastPlanet: TPlanet;
  CountMask: TGreetingCountMask;
  Other: TShip;
  // @nested $5A7CF8 ShuffleDefinitions
  procedure ShuffleDefinitions; // @addr $5A7CF8 @note "Copies definitions and swaps the first half against deterministic random positions."
  var I, OtherIndex: Integer;
  begin
    SetLength(Definitions, ShipGreetingCount);
    // Leaves the last allocated entry empty before shuffling.
    for I := 0 to LastIndex - 1 do Definitions[I] := ShipGreetingDefinitions[I];
    for I := 0 to LastIndex div 2 do begin
      OtherIndex := SeededRandomIntRange(0, LastIndex, Seed + 7 * I);
      SwapA := Definitions[OtherIndex];
      SwapB := Definitions[I];
      Definitions[I] := SwapA;
      Definitions[OtherIndex] := SwapB;
    end;
  end;
begin
  BestText := '';
  if PartnerShip = Player then begin Result := ''; Exit; end;
  begin
    ItemTypes := '';
    BestPriority := -1;
    CandidatePriority := -1;
    Minimum := 0;
    LastIndex := ShipGreetingCount - 1;
    ShuffleDefinitions;
    EntryIndex := SeededRandomIntRange(0, LastIndex, Integer(Seed * Cardinal(Galaxy.CurrentTurn)) div 20);
    for I := 0 to LastIndex do begin
      MessageText := '';
      IncrementWrapped(EntryIndex, Minimum, LastIndex);
      if BestPriority > 0 then begin
        CandidatePriority := Definitions[EntryIndex].Priority;
        if CandidatePriority * SeededRandomIntRange(1, 100, Seed + EntryIndex * (Galaxy.CurrentTurn div 20)) <
          BestPriority * SeededRandomIntRange(1, 100, Seed + EntryIndex * (Galaxy.CurrentTurn div 20) * 3) then Continue;
      end;
      if LastDockedPlanet <> nil then LastPlanet := LastDockedPlanet else LastPlanet := nil;
      Good := GreetingSelectionNoGoods;
      if Definitions[EntryIndex].Goods <> GreetingDefinitionNoGoods then Good := Definitions[EntryIndex].Goods;
      if Definitions[EntryIndex].AutoTalk <> gcAny then begin
        if Automatic then begin
          if Definitions[EntryIndex].AutoTalk = gcNo then Continue;
        end else if Definitions[EntryIndex].AutoTalk = gcYes then Continue;
      end;
      if Definitions[EntryIndex].FlyType = gfAny then MessageText := LocalizedColorText('ShipGreetings.' + Definitions[EntryIndex].Name + '.Text')
      else begin
        if Definitions[EntryIndex].FlyType = gfToPlanet then begin
          if not (OrderTarget is TPlanet) then Continue;
          Planet := (Self).OrderTarget as TPlanet;
          if Planet.OwnerId in [oiKling, oiNone] then Continue;
          if (Definitions[EntryIndex].ToPlanetRace <> []) and not (Planet.OwnerId in Definitions[EntryIndex].ToPlanetRace) then Continue;
          if (Definitions[EntryIndex].ToPlanetRelations <> [])
            and not (Planet.GetRelationLevelToShip(Player) in Definitions[EntryIndex].ToPlanetRelations) then Continue;
          if Good <> GreetingSelectionNoGoods then begin
            if (Definitions[EntryIndex].ToPlanetGoodsCnt <> [])
              and not (Galaxy.ClassifyGoodsQuantity(Planet.Goods[Good].Count, Good) in Definitions[EntryIndex].ToPlanetGoodsCnt) then Continue;
            if (Definitions[EntryIndex].ToPlanetGoodsSale <> [])
              and not (Galaxy.ClassifyGoodsPrice(Planet.Goods[Good].PurchasePrice, Good) in Definitions[EntryIndex].ToPlanetGoodsSale) then Continue;
            if (Definitions[EntryIndex].ToPlanetGoodsBuy <> [])
              and not (Galaxy.ClassifyGoodsPrice(Planet.Goods[Good].BaseSalePrice, Good) in Definitions[EntryIndex].ToPlanetGoodsBuy) then Continue;
          end;
          if (Definitions[EntryIndex].ToPlanetIsHomePlanet <> gcAny) and (((Definitions[EntryIndex].ToPlanetIsHomePlanet = gcYes)
            and (not ((HomePlanet = Planet) and (Planet.OwnerId = OwnerId))))
            or ((Definitions[EntryIndex].ToPlanetIsHomePlanet = gcNo) and (HomePlanet = Planet))) then Continue;
          if (Definitions[EntryIndex].ToPlanetRaceIsShipRace <> gcAny)
            and (((Definitions[EntryIndex].ToPlanetRaceIsShipRace = gcYes) and (Planet.OwnerId <> OwnerId))
            or ((Definitions[EntryIndex].ToPlanetRaceIsShipRace = gcNo) and (Planet.OwnerId = OwnerId))) then Continue;
          if (Definitions[EntryIndex].ToPlanetRaceIsPlayerRace <> gcAny)
            and (((Definitions[EntryIndex].ToPlanetRaceIsPlayerRace = gcYes) and (Planet.OwnerId <> Player.OwnerId))
            or ((Definitions[EntryIndex].ToPlanetRaceIsPlayerRace = gcNo) and (Planet.OwnerId = Player.OwnerId))) then Continue;
          if (Definitions[EntryIndex].ToPlanetEconomy <> [])
            and not (Planet.Economy in Definitions[EntryIndex].ToPlanetEconomy) then Continue;
          if (Definitions[EntryIndex].ToPlanetGovernment <> [])
            and not (Planet.Government in Definitions[EntryIndex].ToPlanetGovernment) then Continue;
          if (Definitions[EntryIndex].ToPlanetIsLastPlanet <> gcAny) and (((Definitions[EntryIndex].ToPlanetIsLastPlanet = gcYes)
            and (LastPlanet <> Planet)) or ((Definitions[EntryIndex].ToPlanetIsLastPlanet = gcNo) and (LastPlanet = Planet))) then Continue;
          if Definitions[EntryIndex].ToPlanetRaceIsLastPlanetRace <> gcAny then begin
            if (((Definitions[EntryIndex].ToPlanetRaceIsLastPlanetRace = gcYes) and (Planet.OwnerId <> LastPlanet.OwnerId))
              or ((Definitions[EntryIndex].ToPlanetRaceIsLastPlanetRace = gcNo) and (Planet.OwnerId = LastPlanet.OwnerId))) then Continue;
          end;
          MessageText := LocalizedColorText('ShipGreetings.' + Definitions[EntryIndex].Name + '.Text');
          MessageText := ReplaceColoredToken(MessageText, '<ToPlanet>', Planet.Name, HighlightColorTag);
          if Good <> GreetingSelectionNoGoods then begin
            MessageText := ReplaceColoredToken(MessageText, '<ToPlanetGoodsSale>', IntToStr(Planet.Goods[Good].PurchasePrice), HighlightColorTag);
            MessageText := ReplaceColoredToken(MessageText, '<ToPlanetGoodsBuy>', IntToStr(Planet.Goods[Good].BaseSalePrice), HighlightColorTag);
          end;
        end else if Definitions[EntryIndex].FlyType = gfToStar then begin
          if not (OrderTarget is TStar) then Continue;
          if Definitions[EntryIndex].HomePlanetInToStar <> gcAny then begin
            if (((Definitions[EntryIndex].HomePlanetInToStar = gcYes)
              and (HomePlanet.CurrentStar <> OrderTarget)) or ((Definitions[EntryIndex].HomePlanetInToStar = gcNo)
              and (HomePlanet.CurrentStar = OrderTarget))) then Continue;
          end;
          if (Definitions[EntryIndex].HomePlanetInCurStar <> gcAny) and (((Definitions[EntryIndex].HomePlanetInCurStar = gcYes)
            and (HomePlanet.CurrentStar <> CurrentStar)) or ((Definitions[EntryIndex].HomePlanetInCurStar = gcNo)
            and (HomePlanet.CurrentStar = CurrentStar))) then Continue;
          Rejected := False;
          for ShipKind := t_Kling to t_Warrior do begin
            case ShipKind of
              t_Kling: CountMask := Definitions[EntryIndex].KlingInToStar;
              t_Ranger: CountMask := Definitions[EntryIndex].RangerInToStar;
              t_Pirate: CountMask := Definitions[EntryIndex].PirateInToStar;
              t_Warrior: CountMask := Definitions[EntryIndex].WarriorInToStar;
              t_Transport: CountMask := Definitions[EntryIndex].TransportInToStar;
            end;
            if CountMask <> [] then begin
              Count := Min(10, (OrderTarget as TStar).ShipTypeCounts[ShipKind]);
              if not (Cardinal(Count) in CountMask) then begin Rejected := True; Break; end;
            end;
          end;
          if Rejected then Continue;
          if Definitions[EntryIndex].ToStarControlByKling <> gcAny then begin
            if (((Definitions[EntryIndex].ToStarControlByKling = gcYes) and (not ((OrderTarget as TStar).ControlFaction = sfKlissan)))
              or ((Definitions[EntryIndex].ToStarControlByKling = gcNo) and ((OrderTarget as TStar).ControlFaction = sfKlissan))) then Continue;
          end;
          if (Definitions[EntryIndex].ToStarInBattle <> gcAny) and (((Definitions[EntryIndex].ToStarInBattle = gcYes)
            and (not ((OrderTarget as TStar).Battle))) or ((Definitions[EntryIndex].ToStarInBattle = gcNo)
            and ((OrderTarget as TStar).Battle))) then Continue;
          MessageText := LocalizedColorText('ShipGreetings.' + Definitions[EntryIndex].Name + '.Text');
          MessageText := ReplaceColoredToken(MessageText, '<ToStar>', (OrderTarget as TStar).Name, HighlightColorTag);
        end else if Definitions[EntryIndex].FlyType = gfToItem then begin
          if (Order <> soMove) or not OrderAbsolute then Continue;
          Rejected := False;
          Item := nil;
          for J := 0 to CurrentStar.Items.Count - 1 do begin
            Item := CurrentStar.Items[J];
            // Native accepts either matching coordinate, rather than requiring both.
            if (GetPickupApproachPosition(Item.Position).X = OrderDestination.X) or
              (GetPickupApproachPosition(Item.Position).Y = OrderDestination.Y) then begin
              ItemTypes := Definitions[EntryIndex].ItemType;
              if (ItemTypes = '') or (ItemTypes = 'Any') or (FindTextPosW(Item.GetCategoryConfigName, ItemTypes) <> 0) then begin
                if (Definitions[EntryIndex].ShipNeedInItem <> gcAny) and
                  (((Definitions[EntryIndex].ShipNeedInItem = gcYes) and not CanReplaceCargoForItem(Item)) or
                  ((Definitions[EntryIndex].ShipNeedInItem = gcNo) and CanReplaceCargoForItem(Item))) then Continue;
                Rejected := True;
                Break;
              end;
            end;
          end;
          if not Rejected then Continue;
          MessageText := LocalizedColorText('ShipGreetings.' + Definitions[EntryIndex].Name + '.Text');
          MessageText := ReplaceColoredToken(MessageText, '<Item>', Item.GetDisplayName, HighlightColorTag);
        end else if Definitions[EntryIndex].FlyType = gfToShip then begin
          if not (OrderTarget is TShip) then Continue;
          if (Definitions[EntryIndex].ToShipType <> [])
            and not ((OrderTarget as TShip).GetGreetingShipCategory in Definitions[EntryIndex].ToShipType) then Continue;
          if (Definitions[EntryIndex].ToShipRace <> [])
            and not ((OrderTarget as TShip).OwnerId in Definitions[EntryIndex].ToShipRace) then Continue;
          if (Definitions[EntryIndex].ToShipInPlanet <> gcAny) and (((Definitions[EntryIndex].ToShipInPlanet = gcYes)
            and (not ((OrderTarget as TShip).CurrentPlanet <> nil))) or ((Definitions[EntryIndex].ToShipInPlanet = gcNo)
            and ((OrderTarget as TShip).CurrentPlanet <> nil))) then Continue;
          if (Definitions[EntryIndex].ToShipBad <> gcAny) and (((Definitions[EntryIndex].ToShipBad = gcYes)
            and (not ((OrderTarget as TShip).EnemyShip = Self))) or ((Definitions[EntryIndex].ToShipBad = gcNo)
            and ((OrderTarget as TShip).EnemyShip = Self))) then Continue;
          MessageText := LocalizedColorText('ShipGreetings.' + Definitions[EntryIndex].Name + '.Text');
          MessageText := ReplaceColoredToken(MessageText, '<ToShip>', (OrderTarget as TShip).GetName, HighlightColorTag);
          MessageText := ReplaceColoredToken(MessageText, '<ToFullShip>', (OrderTarget as TShip).GetFullName(FullNameSeparator), HighlightColorTag);
          if (OrderTarget as TShip).CurrentPlanet <> nil then begin
            MessageText := ReplaceColoredToken(MessageText, '<ToShipInPlanet>', (OrderTarget as TShip).CurrentPlanet.GetFullName(' '), HighlightColorTag);
          end;
        end;
      end;
      if (Definitions[EntryIndex].ShipType <> []) and not (GetGreetingShipCategory in Definitions[EntryIndex].ShipType) then Continue;
      if (Definitions[EntryIndex].Relations <> [])
        and not (GetRelationLevelToShip(Player) in Definitions[EntryIndex].Relations) then Continue;
      if (Definitions[EntryIndex].ShipRace <> []) and not (OwnerId in Definitions[EntryIndex].ShipRace) then Continue;
      if ((Definitions[EntryIndex].PlayerRace <> []) and not (Player.OwnerId in Definitions[EntryIndex].PlayerRace)) then Continue;
      if Definitions[EntryIndex].ShipRaceIsPlayerRace <> gcAny then begin
        if (((Definitions[EntryIndex].ShipRaceIsPlayerRace = gcYes)
          and (Player.OwnerId <> OwnerId)) or ((Definitions[EntryIndex].ShipRaceIsPlayerRace = gcNo)
          and (Player.OwnerId = OwnerId))) then Continue;
      end;
      if Definitions[EntryIndex].PlayerAttackGoodShip <> gcAny then begin
        if Player.OrderTarget is TShip then begin
          Other := (Player).OrderTarget as TShip;
          if (Other.OrderTarget <> Player) and
            (GetRelationLevelToShip(Other) = rlExcellent) and (Other.GetRelationLevelToShip(Player) = rlHostile) then Rejected := True else Rejected := False;
        end else Rejected := False;
        if Definitions[EntryIndex].PlayerAttackGoodShip = gcNo then
        if Rejected then Continue;
        if (Definitions[EntryIndex].PlayerAttackGoodShip = gcYes) and not Rejected then Continue;
        if Rejected then begin
          MessageText := ReplaceColoredToken(MessageText, '<FullShipGood>', (Player.OrderTarget as TShip).GetFullName(FullNameSeparator), '');
        end;
      end;
      if (Definitions[EntryIndex].InFear <> gcAny) and (((Definitions[EntryIndex].InFear = gcYes) and (not (InFear)))
        or ((Definitions[EntryIndex].InFear = gcNo) and (InFear))) then Continue;
      if Definitions[EntryIndex].ShipBadFlyToShip <> gcAny then begin
        Rejected := IsEnemyPursuingSelf;
        if (((Definitions[EntryIndex].ShipBadFlyToShip = gcYes) and (not (Rejected)))
          or ((Definitions[EntryIndex].ShipBadFlyToShip = gcNo) and (Rejected))) then Continue;
      end;
      // Native rule filters assume EnemyShip exists when an enemy mask is set.
      if (Definitions[EntryIndex].ShipBadType <> [])
        and not (EnemyShip.GetGreetingShipCategory in Definitions[EntryIndex].ShipBadType) then Continue;
      if ((Definitions[EntryIndex].ShipBadRace <> []) and not (EnemyShip.OwnerId in Definitions[EntryIndex].ShipBadRace)) then Continue;
      if Definitions[EntryIndex].ShipFlyToPlayer <> gcAny then begin
        if (((Definitions[EntryIndex].ShipFlyToPlayer = gcYes)
          and (OrderTarget <> Player)) or ((Definitions[EntryIndex].ShipFlyToPlayer = gcNo) and (OrderTarget = Player))) then Continue;
      end;
      if (Definitions[EntryIndex].PlayerFlyToShip <> gcAny) and (((Definitions[EntryIndex].PlayerFlyToShip = gcYes)
        and (Player.OrderTarget <> Self)) or ((Definitions[EntryIndex].PlayerFlyToShip = gcNo) and (Player.OrderTarget = Self))) then Continue;
      if (Definitions[EntryIndex].PlayerIsShipBad <> gcAny) and (((Definitions[EntryIndex].PlayerIsShipBad = gcYes)
        and (EnemyShip <> Player)) or ((Definitions[EntryIndex].PlayerIsShipBad = gcNo) and (EnemyShip = Player))) then Continue;
      if Definitions[EntryIndex].ShipTurnBeforeEndOrder <> [] then begin
        Count := Min(10, EstimateOrderTravelTurns);
        if not (Cardinal(Count) in Definitions[EntryIndex].ShipTurnBeforeEndOrder) then Continue;
      end;
      if Definitions[EntryIndex].PlayerTurnBeforeEndOrder <> [] then begin
        Count := Min(10, Player.EstimateOrderTravelTurns);
        if not (Cardinal(Count) in Definitions[EntryIndex].PlayerTurnBeforeEndOrder) then Continue;
      end;
      if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace
        and (Definitions[EntryIndex].ShipBadTurnBeforeEndOrder <> []) then begin
        Count := Min(10, EnemyShip.EstimateOrderTravelTurns);
        if not (Cardinal(Count) in Definitions[EntryIndex].ShipBadTurnBeforeEndOrder) then Continue;
      end;
      if (Self is TRanger) and (Definitions[EntryIndex].ShipStatus <> [])
        and not ((Self as TRanger).GetDominantCareer in Definitions[EntryIndex].ShipStatus) then Continue;
      if (Definitions[EntryIndex].PlayerStatus <> [])
        and not (Player.GetDominantCareer in Definitions[EntryIndex].PlayerStatus) then Continue;
      if (Definitions[EntryIndex].ShipStrength <> [])
        and not (GetRelativeStrengthCategory in Definitions[EntryIndex].ShipStrength) then Continue;
      if (Definitions[EntryIndex].PlayerStrength <> [])
        and not (Player.GetRelativeStrengthCategory in Definitions[EntryIndex].PlayerStrength) then Continue;
      if (Definitions[EntryIndex].ShipStructure <> []) and not (GetHullConditionCategory in Definitions[EntryIndex].ShipStructure) then Continue;
      if (Definitions[EntryIndex].PlayerStructure <> [])
        and not (Player.GetHullConditionCategory in Definitions[EntryIndex].PlayerStructure) then Continue;
      if (Self is TRanger) and (Definitions[EntryIndex].ShipRating <> [])
        and not (GetRangerRatingBand in Definitions[EntryIndex].ShipRating) then Continue;
      if (Definitions[EntryIndex].PlayerRating <> []) and not (Player.GetRangerRatingBand in Definitions[EntryIndex].PlayerRating) then Continue;
      if (Definitions[EntryIndex].ShipRank <> []) and not (Rank in Definitions[EntryIndex].ShipRank) then Continue;
      if (Definitions[EntryIndex].PlayerRank <> []) and not (Player.Rank in Definitions[EntryIndex].PlayerRank) then Continue;
      if (Self is TRanger) and (Definitions[EntryIndex].RatingShipWithPlayer <> [])
        and not (Player.GetShipRatingComparison(Self) in Definitions[EntryIndex].RatingShipWithPlayer) then Continue;
      if (Definitions[EntryIndex].RankShipWithPlayer <> [])
        and not (Player.GetShipRankComparison(Self) in Definitions[EntryIndex].RankShipWithPlayer) then Continue;
      if (Definitions[EntryIndex].StrengthShipWithPlayer <> [])
        and not (Player.GetShipStrengthComparison(Self) in Definitions[EntryIndex].StrengthShipWithPlayer) then Continue;
      if Good <> GreetingSelectionNoGoods then begin
        if (Definitions[EntryIndex].ShipGoodsCnt <> [])
          and not (Galaxy.ClassifyGoodsQuantity(CargoGoods[Good].Count, Good) in Definitions[EntryIndex].ShipGoodsCnt) then Continue;
        if (Definitions[EntryIndex].PlayerGoodsCnt <> [])
          and not (Galaxy.ClassifyGoodsQuantity(Player.CargoGoods[Good].Count, Good) in Definitions[EntryIndex].PlayerGoodsCnt) then Continue;
        if (Definitions[EntryIndex].ShipHaveGoods <> gcAny) and (((Definitions[EntryIndex].ShipHaveGoods = gcYes)
          and (CargoGoods[Good].Count = 0)) or ((Definitions[EntryIndex].ShipHaveGoods = gcNo) and (CargoGoods[Good].Count > 0))) then Continue;
        if (Definitions[EntryIndex].PlayerHaveGoods <> gcAny) and (((Definitions[EntryIndex].PlayerHaveGoods = gcYes)
          and (Player.CargoGoods[Good].Count = 0)) or ((Definitions[EntryIndex].PlayerHaveGoods = gcNo)
          and (Player.CargoGoods[Good].Count > 0))) then Continue;
      end;
      if (Definitions[EntryIndex].ShipGoodsTypeCnt <> [])
        and not (CountCargoGoodsTypes in Definitions[EntryIndex].ShipGoodsTypeCnt) then Continue;
      if (Definitions[EntryIndex].PlayerGoodsTypeCnt <> [])
        and not (Player.CountCargoGoodsTypes in Definitions[EntryIndex].PlayerGoodsTypeCnt) then Continue;
      if (Definitions[EntryIndex].ShipMayScanPlayer <> gcAny) and (((Definitions[EntryIndex].ShipMayScanPlayer = gcYes)
        and (not (CanResolveObjectWithScanner(Player) and (GetRadarRange > 0))))
        or ((Definitions[EntryIndex].ShipMayScanPlayer = gcNo) and (CanResolveObjectWithScanner(Player) and (GetRadarRange > 0)))) then Continue;
      Rejected := False;
      for ShipKind := t_Kling to t_Warrior do begin
        case ShipKind of
          t_Kling: CountMask := Definitions[EntryIndex].KlingInCurStar;
          t_Ranger: CountMask := Definitions[EntryIndex].RangerInCurStar;
          t_Pirate: CountMask := Definitions[EntryIndex].PirateInCurStar;
          t_Warrior: CountMask := Definitions[EntryIndex].WarriorInCurStar;
          t_Transport: CountMask := Definitions[EntryIndex].TransportInCurStar;
        end;
        if CountMask <> [] then begin
          Count := Min(10, CurrentStar.ShipTypeCounts[ShipKind]);
          if not (Cardinal(Count) in CountMask) then begin Rejected := True; Break; end;
        end;
      end;
      if Rejected then Continue;
      if Definitions[EntryIndex].LastPlanetRace <> [] then begin
        if LastPlanet = nil then Continue;
        if not (LastPlanet.OwnerId in Definitions[EntryIndex].LastPlanetRace) then Continue;
        if (Definitions[EntryIndex].LastPlanetRelations <> [])
          and not (LastPlanet.GetRelationLevelToShip(Player) in Definitions[EntryIndex].LastPlanetRelations) then Continue;
        if Good <> GreetingSelectionNoGoods then begin
          if (Definitions[EntryIndex].LastPlanetGoodsCnt <> [])
            and not (Galaxy.ClassifyGoodsQuantity(LastPlanet.Goods[Good].Count, Good) in Definitions[EntryIndex].LastPlanetGoodsCnt) then Continue;
          if (Definitions[EntryIndex].LastPlanetGoodsSale <> [])
            and not (Galaxy.ClassifyGoodsPrice(LastPlanet.Goods[Good].PurchasePrice, Good) in Definitions[EntryIndex].LastPlanetGoodsSale) then Continue;
          if (Definitions[EntryIndex].LastPlanetGoodsBuy <> [])
            and not (Galaxy.ClassifyGoodsPrice(LastPlanet.Goods[Good].BaseSalePrice, Good) in Definitions[EntryIndex].LastPlanetGoodsBuy) then Continue;
        end;
        if (Definitions[EntryIndex].LastPlanetIsHomePlanet <> gcAny) and (((Definitions[EntryIndex].LastPlanetIsHomePlanet = gcYes)
          and (not ((LastPlanet = HomePlanet) and (LastPlanet.OwnerId = OwnerId))))
          or ((Definitions[EntryIndex].LastPlanetIsHomePlanet = gcNo) and (LastPlanet = HomePlanet))) then Continue;
        if Definitions[EntryIndex].LastPlanetRaceIsShipRace <> gcAny then begin
          if (((Definitions[EntryIndex].LastPlanetRaceIsShipRace = gcYes) and (LastPlanet.OwnerId <> OwnerId))
            or ((Definitions[EntryIndex].LastPlanetRaceIsShipRace = gcNo) and (LastPlanet.OwnerId = OwnerId))) then Continue;
        end;
        if Definitions[EntryIndex].LastPlanetRaceIsPlayerRace <> gcAny then begin
          if (((Definitions[EntryIndex].LastPlanetRaceIsPlayerRace = gcYes) and (LastPlanet.OwnerId <> Player.OwnerId))
            or ((Definitions[EntryIndex].LastPlanetRaceIsPlayerRace = gcNo) and (LastPlanet.OwnerId = Player.OwnerId))) then Continue;
        end;
        if (Definitions[EntryIndex].LastPlanetEconomy <> [])
          and not (LastPlanet.Economy in Definitions[EntryIndex].LastPlanetEconomy) then Continue;
        if ((Definitions[EntryIndex].LastPlanetGovernment <> [])
          and not (LastPlanet.Government in Definitions[EntryIndex].LastPlanetGovernment)) then Continue;
        if Definitions[EntryIndex].LastPlanetInCurStar <> gcAny then begin
          if (((Definitions[EntryIndex].LastPlanetInCurStar = gcYes)
            and (LastPlanet.CurrentStar <> CurrentStar)) or ((Definitions[EntryIndex].LastPlanetInCurStar = gcNo)
            and (LastPlanet.CurrentStar = CurrentStar))) then Continue;
        end;
        if Definitions[EntryIndex].LastPlanetDistToShipInTurn <> [] then begin
          Count := Min(10, EstimateTravelTurnsToPlanet(LastPlanet));
          if Count = -1 then Continue;
          if not (Cardinal(Count) in Definitions[EntryIndex].LastPlanetDistToShipInTurn) then Continue;
        end;
        if LastPlanet.CurrentStar <> CurrentStar then begin
          Rejected := False;
          for ShipKind := t_Kling to t_Warrior do begin
            case ShipKind of
              t_Kling: CountMask := Definitions[EntryIndex].KlingInLastPlanetStar;
              t_Ranger: CountMask := Definitions[EntryIndex].RangerInLastPlanetStar;
              t_Pirate: CountMask := Definitions[EntryIndex].PirateInLastPlanetStar;
              t_Warrior: CountMask := Definitions[EntryIndex].WarriorInLastPlanetStar;
              t_Transport: CountMask := Definitions[EntryIndex].TransportInLastPlanetStar;
            end;
            if CountMask <> [] then begin
              Count := Min(10, LastPlanet.CurrentStar.ShipTypeCounts[ShipKind]);
              if not (Cardinal(Count) in CountMask) then begin Rejected := True; Break; end;
            end;
          end;
          if Rejected then Continue;
        end;
        MessageText := ReplaceColoredToken(MessageText, '<LastPlanet>', LastPlanet.Name, HighlightColorTag);
        MessageText := ReplaceColoredToken(MessageText, '<LastPlanetStar>', LastPlanet.CurrentStar.Name, HighlightColorTag);
        if Good <> GreetingSelectionNoGoods then begin
          MessageText := ReplaceColoredToken(MessageText, '<LastPlanetGoodsSale>', IntToStr(LastPlanet.Goods[Good].PurchasePrice), HighlightColorTag);
          MessageText := ReplaceColoredToken(MessageText, '<LastPlanetGoodsBuy>', IntToStr(LastPlanet.Goods[TGoodsIndex(Good)].BaseSalePrice), HighlightColorTag);
        end;
      end;
      if MessageText <> '' then begin
        MessageText := ReplaceColoredToken(MessageText, '<Ship>', GetName, HighlightColorTag);
        MessageText := ReplaceColoredToken(MessageText, '<FullShip>', GetFullName(FullNameSeparator), HighlightColorTag);
        Other := EnemyShip;
        if Other <> nil then begin
          MessageText := ReplaceColoredToken(MessageText, '<ShipBad>', Other.GetName, HighlightColorTag);
          MessageText := ReplaceColoredToken(MessageText, '<FullShipBad>', EnemyShip.GetFullName(FullNameSeparator), HighlightColorTag);
        end;
        MessageText := ReplaceColoredToken(MessageText, '<ShipRank>', GetRankName, HighlightColorTag);
        MessageText := ReplaceColoredToken(MessageText, '<PlayerRank>', Player.GetRankName, HighlightColorTag);
        MessageText := ReplaceColoredToken(MessageText, '<CurStar>', CurrentStar.Name, HighlightColorTag);
        Planet := HomePlanet;
        if Planet <> nil then begin
          MessageText := ReplaceColoredToken(MessageText, '<HomePlanet>', Planet.Name, HighlightColorTag);
          // Native uses <HomePlanet> again for the star substitution.
          MessageText := ReplaceColoredToken(MessageText, '<HomePlanet>', HomePlanet.CurrentStar.Name, HighlightColorTag);
        end;
        BestText := MessageText;
        if CandidatePriority = -1 then BestPriority := Definitions[EntryIndex].Priority else BestPriority := CandidatePriority;
        if BestPriority >= 50 then Break;
      end;
    end;
    Result := BestText;
  end;
end;
{ @end $5A7E30 }

end.

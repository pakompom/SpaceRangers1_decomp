unit aScriptFun;
// Unit bracket (inferred): CODE 0x0052B838..0x00535CE3; inclusive evidence, not full bounds.
// Script API, named from its native registration table.

interface

uses EC_Expression;

procedure SF_GRun(av: array of TVarEC; code: TCodeEC); // @addr $52B838
procedure SF_GCntRun(av: array of TVarEC; code: TCodeEC); // @addr $52B860
procedure SF_GLastTurnRun(av: array of TVarEC; code: TCodeEC); // @addr $52B95C
procedure SF_GAllCntRun(av: array of TVarEC; code: TCodeEC); // @addr $52BA90
procedure SF_StatusPlayer(av: array of TVarEC; code: TCodeEC); // @addr $52C220
procedure SF_AddPlanetNews(av: array of TVarEC; code: TCodeEC); // @addr $52BB30
procedure SF_AutoBattle(av: array of TVarEC; code: TCodeEC); // @addr $52BBD8
procedure SF_GetOwner(av: array of TVarEC; code: TCodeEC); // @addr $52BC44
procedure SF_GiveReward(av: array of TVarEC; code: TCodeEC); // @addr $52BCB8
procedure SF_Rnd(av: array of TVarEC; code: TCodeEC); // @addr $52C0F0
procedure SF_GameDateTxtByTurn(av: array of TVarEC; code: TCodeEC); // @addr $52C174
procedure SF_Id(av: array of TVarEC; code: TCodeEC); // @addr $52C27C
procedure SF_SetName(av: array of TVarEC; code: TCodeEC); // @addr $52C500
procedure SF_UseTranclucator(av: array of TVarEC; code: TCodeEC); // @addr $52C5A8
procedure SF_HullDamage(av: array of TVarEC; code: TCodeEC); // @addr $52C668
procedure SF_Hitpoints(av: array of TVarEC; code: TCodeEC); // @addr $52C6FC
procedure SF_Hit(av: array of TVarEC; code: TCodeEC); // @addr $52C770
procedure SF_ChangeGlobalRelationsShips(av: array of TVarEC; code: TCodeEC); // @addr $52C80C
procedure SF_ChangeGlobalRelationsPlanets(av: array of TVarEC; code: TCodeEC); // @addr $52C97C
procedure SF_GlobalRelationsShips(av: array of TVarEC; code: TCodeEC); // @addr $52CABC
procedure SF_GlobalRelationsPlanets(av: array of TVarEC; code: TCodeEC); // @addr $52CBE0
procedure SF_SetRelationGroup(av: array of TVarEC; code: TCodeEC); // @addr $52CCE8
procedure SF_SetRelationPlanet(av: array of TVarEC; code: TCodeEC); // @addr $52CD74
procedure SF_GetRelationPlanet(av: array of TVarEC; code: TCodeEC); // @addr $52CE00
procedure SF_CurTurn(av: array of TVarEC; code: TCodeEC); // @addr $52CE8C
procedure SF_ShipType(av: array of TVarEC; code: TCodeEC); // @addr $52CEBC
procedure SF_ConName(av: array of TVarEC; code: TCodeEC); // @addr $52CF64
procedure SF_StarName(av: array of TVarEC; code: TCodeEC); // @addr $52D074
procedure SF_PlanetName(av: array of TVarEC; code: TCodeEC); // @addr $52D0E4
procedure SF_PlanetSetGoods(av: array of TVarEC; code: TCodeEC); // @addr $52D154
procedure SF_ShipName(av: array of TVarEC; code: TCodeEC); // @addr $52D274
procedure SF_StarToCon(av: array of TVarEC; code: TCodeEC); // @addr $52D31C
procedure SF_ConNear(av: array of TVarEC; code: TCodeEC); // @addr $52D38C
procedure SF_ConStars(av: array of TVarEC; code: TCodeEC); // @addr $52D468
procedure SF_ConStar(av: array of TVarEC; code: TCodeEC); // @addr $52D4D8
procedure SF_GalaxyStars(av: array of TVarEC; code: TCodeEC); // @addr $52D578
procedure SF_GalaxyStar(av: array of TVarEC; code: TCodeEC); // @addr $52D5AC
procedure SF_StarAngleBetween(av: array of TVarEC; code: TCodeEC); // @addr $52D64C
procedure SF_FindPlanet(av: array of TVarEC; code: TCodeEC); // @addr $52D74C
procedure SF_IsPlayer(av: array of TVarEC; code: TCodeEC); // @addr $52E524
procedure SF_GroupCount(av: array of TVarEC; code: TCodeEC); // @addr $52E59C
procedure SF_GroupIn(av: array of TVarEC; code: TCodeEC); // @addr $52E654
procedure SF_CountIn(av: array of TVarEC; code: TCodeEC); // @addr $52E828
procedure SF_ChangeState(av: array of TVarEC; code: TCodeEC); // @addr $52EB74
procedure SF_NearestGroup(av: array of TVarEC; code: TCodeEC); // @addr $52EA28
procedure SF_StarAngle(av: array of TVarEC; code: TCodeEC); // @addr $52EC38
procedure SF_NewsAdd(av: array of TVarEC; code: TCodeEC); // @addr $52ECC4
procedure SF_MsgAdd(av: array of TVarEC; code: TCodeEC); // @addr $52ED70
procedure SF_Ether(av: array of TVarEC; code: TCodeEC); // @addr $52EEC0
procedure SF_EtherState(av: array of TVarEC; code: TCodeEC); // @addr $52F0C4
procedure SF_ConChangeRelationToRanger(av: array of TVarEC; code: TCodeEC); // @addr $52F17C
procedure SF_GetData(av: array of TVarEC; code: TCodeEC); // @addr $52F278
procedure SF_SetData(av: array of TVarEC; code: TCodeEC); // @addr $52F2E8
procedure SF_ShipData(av: array of TVarEC; code: TCodeEC); // @addr $52F3A0
procedure SF_Format(av: array of TVarEC; code: TCodeEC); // @addr $52F410
procedure SF_Dialog(av: array of TVarEC; code: TCodeEC); // @addr $52F558
procedure SF_DText(av: array of TVarEC; code: TCodeEC); // @addr $52F760
procedure SF_DAdd(av: array of TVarEC; code: TCodeEC); // @addr $52F870
procedure SF_DChange(av: array of TVarEC; code: TCodeEC); // @addr $5305B0
procedure SF_DAnswer(av: array of TVarEC; code: TCodeEC); // @addr $52F8E0
procedure SF_Player(av: array of TVarEC; code: TCodeEC); // @addr $53061C
procedure SF_ItemExist(av: array of TVarEC; code: TCodeEC); // @addr $53064C
procedure SF_ItemIn(av: array of TVarEC; code: TCodeEC); // @addr $5306CC
procedure SF_ItemCost(av: array of TVarEC; code: TCodeEC); // @addr $53093C
procedure SF_ItemCount(av: array of TVarEC; code: TCodeEC); // @addr $5309C4
procedure SF_DropItem(av: array of TVarEC; code: TCodeEC); // @addr $52BE10
procedure SF_DropScriptItem(av: array of TVarEC; code: TCodeEC); // @addr $52BF70
procedure SF_DeleteEquipment(av: array of TVarEC; code: TCodeEC); // @addr $52C024
procedure SF_DecayGoods(av: array of TVarEC; code: TCodeEC); // @addr $530AB4
procedure SF_UpsurgeGoods(av: array of TVarEC; code: TCodeEC); // @addr $530BBC
procedure SF_GoodsAdd(av: array of TVarEC; code: TCodeEC); // @addr $530CC4
procedure SF_GoodsCount(av: array of TVarEC; code: TCodeEC); // @addr $530E28
procedure SF_ShipGoods(av: array of TVarEC; code: TCodeEC); // @addr $530F28
procedure SF_GoodsDrop(av: array of TVarEC; code: TCodeEC); // @addr $531034
procedure SF_UselessItemCreate(av: array of TVarEC; code: TCodeEC); // @addr $5312E4
procedure SF_GoodsSellPrice(av: array of TVarEC; code: TCodeEC); // @addr $5314BC
procedure SF_CountTurn(av: array of TVarEC; code: TCodeEC); // @addr $5315C8
procedure SF_ShipSetBad(av: array of TVarEC; code: TCodeEC); // @addr $5319A8
procedure SF_GroupSetBad(av: array of TVarEC; code: TCodeEC); // @addr $531A2C
procedure SF_ShipSetPartner(av: array of TVarEC; code: TCodeEC); // @addr $531AEC
procedure SF_ShipJoin(av: array of TVarEC; code: TCodeEC); // @addr $531B80
procedure SF_ShipOut(av: array of TVarEC; code: TCodeEC); // @addr $531C38
procedure SF_ShipInScript(av: array of TVarEC; code: TCodeEC); // @addr $531C84
procedure SF_ShipInCurScript(av: array of TVarEC; code: TCodeEC); // @addr $531D0C
procedure SF_ShipInNormalSpace(av: array of TVarEC; code: TCodeEC); // @addr $531DA4
procedure SF_ShipInHole(av: array of TVarEC; code: TCodeEC); // @addr $531E2C
procedure SF_ShipIsTakeoff(av: array of TVarEC; code: TCodeEC); // @addr $531EB8
procedure SF_ShipCntWeapon(av: array of TVarEC; code: TCodeEC); // @addr $531F40
procedure SF_ShipGroup(av: array of TVarEC; code: TCodeEC); // @addr $531FB8
procedure SF_ShipSpeed(av: array of TVarEC; code: TCodeEC); // @addr $532034
procedure SF_ShipCanJump(av: array of TVarEC; code: TCodeEC); // @addr $52DAA8
procedure SF_ShipInStar(av: array of TVarEC; code: TCodeEC); // @addr $52DBA0
procedure SF_ShipInPlanet(av: array of TVarEC; code: TCodeEC); // @addr $52DC2C
procedure SF_ShipStatistic(av: array of TVarEC; code: TCodeEC); // @addr $52DCBC
procedure SF_ShipMoney(av: array of TVarEC; code: TCodeEC); // @addr $52DDF0
procedure SF_ShipFuel(av: array of TVarEC; code: TCodeEC); // @addr $52DE8C
procedure SF_ShipStrengthInBestRanger(av: array of TVarEC; code: TCodeEC); // @addr $52DF50
procedure SF_ShipStrengthInAverageRanger(av: array of TVarEC; code: TCodeEC); // @addr $52DFD4
procedure SF_ShipFind(av: array of TVarEC; code: TCodeEC); // @addr $52E12C
procedure SF_RangerStatus(av: array of TVarEC; code: TCodeEC); // @addr $52E058
procedure SF_GalaxyMoney(av: array of TVarEC; code: TCodeEC); // @addr $52C36C
procedure SF_ShipDestroy(av: array of TVarEC; code: TCodeEC); // @addr $52E1F4
procedure SF_ItemDestroy(av: array of TVarEC; code: TCodeEC); // @addr $52E284
procedure SF_RangersCapital(av: array of TVarEC; code: TCodeEC); // @addr $52E304
procedure SF_GroupToShip(av: array of TVarEC; code: TCodeEC); // @addr $52E334
procedure SF_OrderLanding(av: array of TVarEC; code: TCodeEC); // @addr $52E494
procedure SF_OrderJump(av: array of TVarEC; code: TCodeEC); // @addr $52E408
procedure SF_GroupIs(av: array of TVarEC; code: TCodeEC); // @addr $5320A4
procedure SF_StateIs(av: array of TVarEC; code: TCodeEC); // @addr $53215C
procedure SF_Dist(av: array of TVarEC; code: TCodeEC); // @addr $532268
procedure SF_Dist2Star(av: array of TVarEC; code: TCodeEC); // @addr $5324D8
procedure SF_BuyPirate(av: array of TVarEC; code: TCodeEC); // @addr $532560
procedure SF_BuyTransport(av: array of TVarEC; code: TCodeEC); // @addr $5325C8
procedure SF_Name(av: array of TVarEC; code: TCodeEC); // @addr $53264C
procedure SF_ShortName(av: array of TVarEC; code: TCodeEC); // @addr $5327BC
procedure SF_FirstGiveMoney(av: array of TVarEC; code: TCodeEC); // @addr $53297C
procedure SF_ScenarioState(av: array of TVarEC; code: TCodeEC); // @addr $5329D0
procedure SF_HaveCommunicator(av: array of TVarEC; code: TCodeEC); // @addr $532A18
procedure SF_HoleMamaCreate(av: array of TVarEC; code: TCodeEC); // @addr $532A4C
procedure SF_HoleCreate(av: array of TVarEC; code: TCodeEC); // @addr $532D84
procedure SF_SkipGreeting(av: array of TVarEC; code: TCodeEC); // @addr $532FA8
procedure SF_Sound(av: array of TVarEC; code: TCodeEC); // @addr $532FD4
procedure SF_Tips(av: array of TVarEC; code: TCodeEC); // @addr $533074
procedure SF_CT(av: array of TVarEC; code: TCodeEC); // @addr $5330D8
procedure SF_SFT(av: array of TVarEC; code: TCodeEC); // @addr $5332A4

procedure InitializeScriptBuiltinsAndConstants(Scope: TVarArrayEC); // @addr $533350

implementation

// @unit-initialization $535CDC
// @unit-finalization $535CAC

uses aEFilm, aKling, fEquipmentShop, Classes, SysUtils, Math, EC_Str, EC_Struct, aScript, aShip, aPlayer, aPlanet, aGalaxy, aItem, Globals, GlobalsV, GR_Main, GR_Sound, aMyFunction, aNormalShip, aRanger, aConst, fRuinsTalk, fTalk, fGov;

{ @routine $52B838 SF_GRun }
procedure SF_GRun(av: array of TVarEC; code: TCodeEC);
begin
  ScriptTemplateStartRequested := True;
end;
{ @end $52B838 }

{ @routine $52B860 SF_GCntRun }
procedure SF_GCntRun(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_GCntRun');
  Index := FindScriptTemplateIndex(av[1].GetString);
  if Index < 0 then raise Exception.Create('Error.Script.NotFound SF_GCntRun');
  av[0].SetInt(TScriptTemplUnit(ScriptTemplates[Index]).UseCount);
end;
{ @end $52B860 }

{ @routine $52B95C SF_GLastTurnRun }
procedure SF_GLastTurnRun(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script SF_GCntRun');
  Index := FindScriptTemplateIndex(av[1].GetString);
  if Index < 0 then raise Exception.Create('Error.Script.NotFound SF_GLastTurnRun');
  if (High(av) >= 2) and (TScriptTemplUnit(ScriptTemplates[Index]).UseCount < 1) then
    av[0].SetInt(av[2].GetInt)
  else
    av[0].SetInt(TScriptTemplUnit(ScriptTemplates[Index]).LastTurn);
end;
{ @end $52B95C }

{ @routine $52BA90 SF_GAllCntRun }
procedure SF_GAllCntRun(av: array of TVarEC; code: TCodeEC);
var
  Count, ClassId, I: Integer;
begin
  if High(av) >= 1 then
  begin
    ClassId := av[1].GetInt;
    Count := 0;
    for I := 0 to Galaxy.Scripts.Count - 1 do
      if TScript(Galaxy.Scripts[I]).ClassId = ClassId then Inc(Count);
    av[0].SetInt(Count);
  end
  else av[0].SetInt(Galaxy.Scripts.Count);
end;
{ @end $52BA90 }

{ @routine $52BB30 SF_AddPlanetNews }
procedure SF_AddPlanetNews(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script AddPlanetNews');
  Galaxy.AddPlanetNews(gnGeneral, av[1].GetString);
end;
{ @end $52BB30 }

{ @routine $52BBD8 SF_AutoBattle }
procedure SF_AutoBattle(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script AutoBattle');
  PendingPlayerFollowTarget := TShip(av[1].GetDword);
end;
{ @end $52BBD8 }

{ @routine $52BC44 SF_GetOwner }
procedure SF_GetOwner(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Owner: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_GetOwner');
  Ship := TShip(av[1].GetDword);
  Owner := Ord(Ship.OwnerId);
  av[0].SetInt(Owner);
end;
{ @end $52BC44 }

{ @routine $52BCB8 SF_GiveReward }
procedure SF_GiveReward(av: array of TVarEC; code: TCodeEC);
var Ship: TShip; Owner: TOwnerId; Kind: TAwardType; Award: Integer; AwardId: PByte;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script SF_GiveReward');
  Ship := TShip(av[1].GetDword);
  if not (Ship is TRanger) then raise Exception.Create('Error.Script SF_GiveReward');
  Owner := TOwnerId(av[2].GetInt);
  Kind := TAwardType(av[3].GetInt);
  Award := (Ship as TRanger).SelectAward(Owner, [Kind]);
  if Award = 255 then RaiseWideMessage('Error RewardNumber=255');
  if Ship.AwardIds = nil then Ship.AwardIds := TList.Create;
  New(AwardId);
  Ship.AwardIds.Add(AwardId);
  AwardId^ := Award;
end;
{ @end $52BCB8 }

{ @routine $52BE10 SF_DropItem }
procedure SF_DropItem(av: array of TVarEC; code: TCodeEC);
var Ship: TShip; Item: TEquipment; Kind: TItemType; I: Integer;
    Found, Equipped: Boolean; Binding: TScriptItem;
begin
  Found := False;
  if High(av) < 2 then raise Exception.Create('Error.Script SF_DropItem');
  Equipped := False;
  // Native reads the equipment flag only when the binding argument is absent.
  if High(av) = 3 then Equipped := Boolean(av[3].GetInt);
  Ship := TShip(av[1].GetDword);
  Kind := TItemType(av[2].GetInt);
  for I := 0 to Ship.Inventory.Count - 1 do
  begin
    Item := TEquipment(Ship.Inventory[I]);
    if (Item.ItemType = Kind) and (Item.EquippedFlag = Equipped) then
    begin
      if High(av) >= 4 then
      begin
        Binding := TScriptItem(av[4].GetDword);
        if Binding.Item <> nil then Binding.Item.ScriptItem := nil;
        Binding.Item := Item;
        Item.ScriptItem := Binding;
      end;
      Ship.DropItemIntoStar(Item);
      Found := True;
      Break;
    end;
  end;
  if not Found then raise Exception.Create('Error.Script SF_DropItem - item not found');
end;
{ @end $52BE10 }

{ @routine $52BF70 SF_DropScriptItem }
procedure SF_DropScriptItem(av: array of TVarEC; code: TCodeEC);
var Ship: TShip; Binding: TScriptItem;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script DropScriptItem');
  Ship := TShip(av[1].GetDword);
  Binding := TScriptItem(av[2].GetDword);
  if (Binding.Item <> nil) and
    ((Ship.Inventory.IndexOf(Binding.Item) >= 0) or (Ship.Artefacts.IndexOf(Binding.Item) >= 0)) and
    Ship.InNormalSpace then Ship.DropItemIntoStar(Binding.Item);
end;
{ @end $52BF70 }

{ @routine $52C024 SF_DeleteEquipment }
procedure SF_DeleteEquipment(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  I: Integer;
  Kind: TItemType;
  Item: TItem;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script SF_DeleteEquipment');
  Ship := TShip(av[1].GetDword);
  I := 0;
  Kind := TItemType(av[2].GetInt);
  while I < Ship.Inventory.Count do
  begin
    Item := TItem(Ship.Inventory[I]);
    if (Item.ScriptItem = nil) and (Item.ItemType = Kind) then
    begin
      Ship.Inventory.Delete(I);
      Item.Free;
    end
    else Inc(I);
  end;
  Ship.RefreshEquipmentSlots;
  Ship.RefreshDerivedStats;
end;
{ @end $52C024 }

{ @routine $52C0F0 SF_Rnd }
procedure SF_Rnd(av: array of TVarEC; code: TCodeEC);
var
  LowValue, HighValue: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script Rnd');
  LowValue := av[1].GetInt;
  HighValue := av[2].GetInt;
  av[0].SetInt(LowValue + Random(HighValue - LowValue));
end;
{ @end $52C0F0 }

{ @routine $52C174 SF_GameDateTxtByTurn }
procedure SF_GameDateTxtByTurn(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script GameDateTxtByTurn');
  av[0].SetString(FormatGameTurnDate(av[1].GetInt));
end;
{ @end $52C174 }

{ @routine $52C220 SF_StatusPlayer }
procedure SF_StatusPlayer(av: array of TVarEC; code: TCodeEC);
begin
  case Player.GetDominantCareer of
    rcTrader: av[0].SetInt(1);
    rcWarrior: av[0].SetInt(0);
    rcPirate: av[0].SetInt(-1);
  end;
end;
{ @end $52C220 }

{ @routine $52C27C SF_Id }
procedure SF_Id(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_Id');
  Obj := TObject(av[1].GetDword);
  if Obj is TShip then av[0].SetDword(TShip(Obj).Id)
  else if Obj is TPlanet then av[0].SetDword(TPlanet(Obj).Id)
  else if Obj is TStar then av[0].SetDword(TStar(Obj).Id)
  else raise Exception.Create('Error.Script SF_Id 2');
end;
{ @end $52C27C }

{ @routine $52C36C SF_GalaxyMoney }
procedure SF_GalaxyMoney(av: array of TVarEC; code: TCodeEC);
var Owner: TOwnerId;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script SF_GalaxyMoney');
  Owner := oiPeople;
  if High(av) >= 2 then
    case av[2].GetInt of
      0: Owner := oiMaloc;
      1: Owner := oiPeleng;
      2: Owner := oiPeople;
      3: Owner := oiFei;
      4: Owner := oiGaal;
      5: Owner := oiKling;
    else raise Exception.Create('Error.Script SF_GalaxyMoney');
    end;
  case av[1].GetInt of
    0: av[0].SetInt(Galaxy.ComputeScaledMiniMoney(Owner));
    1: av[0].SetInt(Galaxy.ComputeScaledSmallMoney(Owner));
    2: av[0].SetInt(Galaxy.ComputeScaledAverageMoney(Owner));
    3: av[0].SetInt(Galaxy.ComputeScaledBigMoney(Owner));
    4: av[0].SetInt(Galaxy.ComputeScaledHugeMoney(Owner));
  else raise Exception.Create('Error.Script SF_GalaxyMoney');
  end;
end;
{ @end $52C36C }

{ @routine $52C500 SF_SetName }
procedure SF_SetName(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script SF_SetName');
  Ship := TShip(av[1].GetDword);
  Ship.Name := av[2].GetString;
end;
{ @end $52C500 }

{ @routine $52C5A8 SF_UseTranclucator }
procedure SF_UseTranclucator(av: array of TVarEC; code: TCodeEC);
var Ship: TShip; Item: TArtefact; I: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_UseTranclucator');
  Ship := TShip(av[1].GetDword);
  for I := 0 to Ship.Artefacts.Count - 1 do
  begin
    Item := TArtefact(Ship.Artefacts[I]);
    if (Item.ItemType = t_ArtefactTranclucator) and not Item.BrokenFlag then
      Ship.UseArtefact(Item as TArtefactTranclucator);
  end;
end;
{ @end $52C5A8 }

{ @routine $52C668 SF_HullDamage }
procedure SF_HullDamage(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script HullDamage');
  with TShip(av[1].GetDword) do
    av[0].SetInt(100 - Round(Hull.HullPoints / Hull.Weight * 100));
end;
{ @end $52C668 }

{ @routine $52C6FC SF_Hitpoints }
procedure SF_Hitpoints(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script Hitpoints');
  av[0].SetInt(TShip(av[1].GetDword).Hull.HullPoints);
end;
{ @end $52C6FC }

{ @routine $52C770 SF_Hit }
procedure SF_Hit(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Binding: TScriptShip;
begin
  if High(av) < 1 then Ship := CurrentScript.CurrentShip
  else Ship := TShip(av[1].GetDword);
  if Ship = nil then Exit;
  begin
    Binding := GetScriptShipBindingForContext(Ship, CurrentScript);
    if High(av) < 2 then av[0].SetInt(Ord(Binding.Hit or Binding.HitPlayer))
    else if av[2].GetInt <> 0 then av[0].SetInt(Ord(Binding.HitPlayer))
    else av[0].SetInt(Ord(Binding.Hit));
  end;
end;
{ @end $52C770 }

{ @routine $52C80C SF_ChangeGlobalRelationsShips }
{$Q+}
procedure SF_ChangeGlobalRelationsShips(av: array of TVarEC; code: TCodeEC);
var
  Ranger: TObject;
  Scope: TObject;
  RawShipTypes: Cardinal;
  ShipTypes: THullShipTypeMask;
  Mode: TRelationChangeMode;
  Owners: TOwnerSet;
begin
  if High(av) <> 6 then raise Exception.Create('Error.Script ChangeGlobalRelationsShips');
  if av[1].GetDword = 0 then Exit;
  Ranger := TObject(av[1].GetDword);
  if (Ranger <> nil) and (Ranger is TRanger) then
  begin
    if (av[2].GetDword > 0) and (av[2].GetDword < $FF) then
      Scope := TScriptConstellation(CurrentScript.Constellations[av[2].GetDword]).Constellation
    else if av[2].GetDword <> 0 then Scope := TObject(av[2].GetDword)
    else Scope := nil;
    case av[3].GetDword of
      0: Mode := rcmCapAt;
      1: Mode := rcmRaiseTo;
      2: Mode := rcmIncrease;
      3: Mode := rcmDecrease;
    else Mode := rcmCapAt;
    end;
    RawShipTypes := av[5].GetDword;
    ShipTypes := THullShipTypeMask(Word(RawShipTypes));
    WriteByteValue(av[6].GetDword, Owners);
    TRanger(Ranger).ChangeShipRelations(Scope, Mode, av[4].GetInt, ShipTypes, Owners);
  end;
end;
{$Q-}
{ @end $52C80C }

{ @routine $52C97C SF_ChangeGlobalRelationsPlanets }
procedure SF_ChangeGlobalRelationsPlanets(av: array of TVarEC; code: TCodeEC);
var
  Ranger: TObject;
  Scope: TObject;
  Mode: TRelationChangeMode;
  Owners: TOwnerSet;
begin
  if High(av) <> 5 then raise Exception.Create('Error.Script ChangeGlobalRelationsPlanets');
  Ranger := TObject(av[1].GetDword);
  if (Ranger <> nil) and (Ranger is TRanger) then
  begin
    if (av[2].GetDword > 0) and (av[2].GetDword < $FF) then
      Scope := TScriptConstellation(CurrentScript.Constellations[av[2].GetDword]).Constellation
    else if av[2].GetDword <> 0 then Scope := TObject(av[2].GetDword)
    else Scope := nil;
    case av[3].GetDword of
      0: Mode := rcmCapAt;
      1: Mode := rcmRaiseTo;
      2: Mode := rcmIncrease;
    else Mode := rcmCapAt;
    end;
    WriteByteValue(av[5].GetDword, Owners);
    TRanger(Ranger).ChangePlanetRelations(Scope, Mode, av[4].GetInt, Owners);
  end;
end;
{ @end $52C97C }

{ @routine $52CABC SF_GlobalRelationsShips }
{$Q+}
procedure SF_GlobalRelationsShips(av: array of TVarEC; code: TCodeEC);
var
  Ranger: TObject;
  Scope: TObject;
  RawShipTypes: Cardinal;
  ShipTypes: THullShipTypeMask;
  Owners: TOwnerSet;
begin
  if High(av) <> 4 then raise Exception.Create('Error.Script GlobalRelationsShips');
  Ranger := TObject(av[1].GetDword);
  if (Ranger <> nil) and (Ranger is TRanger) then
  begin
    if (av[2].GetDword > 0) and (av[2].GetDword < $FF) then
      Scope := TScriptConstellation(CurrentScript.Constellations[av[2].GetDword]).Constellation
    else if av[2].GetDword <> 0 then Scope := TObject(av[2].GetDword)
    else Scope := nil;
    RawShipTypes := av[3].GetDword;
    ShipTypes := THullShipTypeMask(Word(RawShipTypes));
    WriteByteValue(av[4].GetDword, Owners);
    av[0].SetInt(TRanger(Ranger).GlobalRelationsShips(Scope, ShipTypes, Owners));
  end;
end;
{$Q-}
{ @end $52CABC }

{ @routine $52CBE0 SF_GlobalRelationsPlanets }
procedure SF_GlobalRelationsPlanets(av: array of TVarEC; code: TCodeEC);
var
  Ranger: TObject;
  Scope: TObject;
  Owners: TOwnerSet;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script GlobalRelationsPlanets');
  Ranger := TObject(av[1].GetDword);
  if (Ranger <> nil) and (Ranger is TRanger) then
  begin
    if (av[2].GetDword > 0) and (av[2].GetDword < $FF) then
      Scope := TScriptConstellation(CurrentScript.Constellations[av[2].GetDword]).Constellation
    else if av[2].GetDword <> 0 then Scope := TObject(av[2].GetDword)
    else Scope := nil;
    WriteByteValue(av[3].GetDword, Owners);
    av[0].SetInt(TRanger(Ranger).GlobalRelationsPlanets(Scope, Owners));
  end;
end;
{ @end $52CBE0 }

{ @routine $52CCE8 SF_SetRelationGroup }
procedure SF_SetRelationGroup(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script SetRelationGroup');
  CurrentScript.SetGroupRelation(av[1].GetInt, av[2].GetInt, TRelationLevel(av[3].GetInt));
end;
{ @end $52CCE8 }

{ @routine $52CD74 SF_SetRelationPlanet }
procedure SF_SetRelationPlanet(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script SetRelationPlanet');
  CurrentScript.SetPlanetRelation(av[2].GetInt, TPlanet(av[1].GetDword), TRelationLevel(av[3].GetInt));
end;
{ @end $52CD74 }

{ @routine $52CE00 SF_GetRelationPlanet }
procedure SF_GetRelationPlanet(av: array of TVarEC; code: TCodeEC);
var
  Planet: TPlanet;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script GetRelationPlanet');
  Planet := TPlanet(av[1].GetDword);
  av[0].SetDword(Planet.RelationToShip(Pointer(av[2].GetDword)));
end;
{ @end $52CE00 }

{ @routine $52CE8C SF_CurTurn }
procedure SF_CurTurn(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Galaxy.CurrentTurn);
end;
{ @end $52CE8C }

{ @routine $52CEBC SF_ShipType }
procedure SF_ShipType(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipType');
  Ship := TShip(av[1].GetDword);
  av[0].SetString(Ship.GetTypeNameKey);
end;
{ @end $52CEBC }

{ @routine $52CF64 SF_ConName }
procedure SF_ConName(av: array of TVarEC; code: TCodeEC);
var
  Constellation: TConstellation;
  Star: TStar;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ConName');
  Constellation := TConstellation(av[1].GetDword);
  Star := TStar(Constellation.Stars[0]);
  av[0].SetString(IntToStr(Constellation.Id) + '(' + Star.Name + ')');
end;
{ @end $52CF64 }

{ @routine $52D074 SF_StarName }
procedure SF_StarName(av: array of TVarEC; code: TCodeEC);
var
  Obj: TStar;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script StarName');
  Obj := TStar(av[1].GetDword);
  av[0].SetString(Obj.Name);
end;
{ @end $52D074 }

{ @routine $52D0E4 SF_PlanetName }
procedure SF_PlanetName(av: array of TVarEC; code: TCodeEC);
var
  Obj: TPlanet;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script PlanetName');
  Obj := TPlanet(av[1].GetDword);
  av[0].SetString(Obj.Name);
end;
{ @end $52D0E4 }

{ @routine $52D154 SF_PlanetSetGoods }
procedure SF_PlanetSetGoods(av: array of TVarEC; code: TCodeEC);
var Kind: TGoodsIndex; Value: Integer;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script PlanetSetGoods');
  Value := av[2].GetInt;
  if Value = 0 then Kind := t_Food
  else if Value = 1 then Kind := t_Medicine
  else if Value = 2 then Kind := t_Technics
  else if Value = 3 then Kind := t_Luxury
  else if Value = 4 then Kind := t_Minerals
  else if Value = 5 then Kind := t_Alcohol
  else if Value = 6 then Kind := t_Arms
  else if Value = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script PlanetSetGoods 1');
  TPlanet(av[1].GetDword).Goods[Kind].Count := av[3].GetInt;
end;
{ @end $52D154 }

{ @routine $52D274 SF_ShipName }
procedure SF_ShipName(av: array of TVarEC; code: TCodeEC);
var
  Obj: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipName');
  Obj := TShip(av[1].GetDword);
  av[0].SetString(Obj.GetName);
end;
{ @end $52D274 }

{ @routine $52D31C SF_StarToCon }
procedure SF_StarToCon(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script StarToCon');
  av[0].SetDword(Cardinal(TStar(av[1].GetDword).Constellation));
end;
{ @end $52D31C }

{ @routine $52D38C SF_ConNear }
procedure SF_ConNear(av: array of TVarEC; code: TCodeEC);
var
  I, Count, J, ArgCount: Integer;
  Constellation, Neighbor, Candidate: TConstellation;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script ConNear');
  Constellation := TConstellation(av[1].GetDword);
  Count := Constellation.AdjacentConstellations.Count;
  ArgCount := High(av) - 1;
  for I := 0 to Count - 1 do
  begin
    Neighbor := TConstellation(Constellation.AdjacentConstellations[I]);
    for J := 0 to ArgCount - 1 do
    begin
      Candidate := TConstellation(av[2 + J].GetDword);
      if Neighbor = Candidate then
      begin
        av[0].SetInt(1);
        Exit;
      end;
    end;
  end;
  av[0].SetInt(0);
end;
{ @end $52D38C }

{ @routine $52D468 SF_ConStars }
procedure SF_ConStars(av: array of TVarEC; code: TCodeEC);
var
  Constellation: TConstellation;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ConStars');
  Constellation := TConstellation(av[1].GetDword);
  av[0].SetInt(Constellation.Stars.Count);
end;
{ @end $52D468 }

{ @routine $52D4D8 SF_ConStar }
procedure SF_ConStar(av: array of TVarEC; code: TCodeEC);
var
  Constellation: TConstellation;
  Index: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ConStar');
  Constellation := TConstellation(av[1].GetDword);
  Index := av[2].GetInt;
  if (Index < 0) or (Index >= Constellation.Stars.Count) then av[0].SetDword(0)
  else av[0].SetDword(Cardinal(Constellation.Stars[Index]));
end;
{ @end $52D4D8 }

{ @routine $52D578 SF_GalaxyStars }
procedure SF_GalaxyStars(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Galaxy.Stars.Count);
end;
{ @end $52D578 }

{ @routine $52D5AC SF_GalaxyStar }
procedure SF_GalaxyStar(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script GalaxyStar');
  Index := av[1].GetInt;
  if (Index < 0) or (Index >= Galaxy.Stars.Count) then av[0].SetDword(0)
  else av[0].SetDword(Cardinal(Galaxy.Stars[Index]));
end;
{ @end $52D5AC }

{ @routine $52D64C SF_StarAngleBetween }
procedure SF_StarAngleBetween(av: array of TVarEC; code: TCodeEC);
var
  Star1, CenterStar, Star2: TStar;
  MinAngle, MaxAngle, Angle: Single;
begin
  if High(av) <> 5 then raise Exception.Create('Error.Script StarAngleBetween');
  Star1 := TStar(av[1].GetDword);
  CenterStar := TStar(av[2].GetDword);
  Star2 := TStar(av[3].GetDword);
  MinAngle := av[4].GetFloat;
  MaxAngle := av[5].GetFloat;
  Angle := Abs(HeadingDifferenceDegrees(PointBearingDegrees(CenterStar.Position, Star1.Position),
    PointBearingDegrees(CenterStar.Position, Star2.Position)));
  if (Angle >= MinAngle) and (Angle <= MaxAngle) then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $52D64C }

{ @routine $52D74C SF_FindPlanet }
procedure SF_FindPlanet(av: array of TVarEC; code: TCodeEC);
var
  Star: TStar;
  Planet: TPlanet;
  Filters, Filter: WideString;
  MinFraction, MaxFraction: Single;
  I, Count, J, FilterCount: Integer;
  Planets: TList;
begin
  if High(av) <> 4 then raise Exception.Create('Error.Script FindPlanet');
  Star := TStar(av[1].GetDword);
  Filters := av[2].GetString;
  MinFraction := av[3].GetFloat / 100;
  MaxFraction := av[4].GetFloat / 100;
  Planets := TList.Create;
  Count := Star.Planets.Count;
  FilterCount := CountDelimitedPartsW(Filters, ',');
  for I := 0 to Count - 1 do
  begin
    Planet := TPlanet(Star.Planets[I]);
    for J := 0 to FilterCount - 1 do
    begin
      Filter := ExtractDelimitedPartW(Filters, J, ',');
      if (Filter = 'NotMaloc') and (Planet.OwnerId = oiMaloc) then Break
      else if (Filter = 'NotPeleng') and (Planet.OwnerId = oiPeleng) then Break
      else if (Filter = 'NotPeople') and (Planet.OwnerId = oiPeople) then Break
      else if (Filter = 'NotFei') and (Planet.OwnerId = oiFei) then Break
      else if (Filter = 'NotGaal') and (Planet.OwnerId = oiGaal) then Break
      else if (Filter = 'NotKling') and (Planet.OwnerId = oiKling) then Break
      else if (Filter = 'NotNone') and (Planet.OwnerId = oiNone) then Break;
    end;
    if J < FilterCount then Continue;
    Planets.Add(Planet);
  end;
  if Planets.Count < 1 then
  begin
    av[0].SetDword(0);
    Planets.Free;
    Exit;
  end;

  begin
    I := Round((Planets.Count - 1) * MinFraction);
    J := Round((Planets.Count - 1) * MaxFraction);
    I := I + SeededRandomIntRange(0, J - I, Galaxy.CurrentTurn * Galaxy.GenerationSeed);
    av[0].SetDword(Cardinal(Planets[I]));
  end;
  Planets.Free;
end;
{ @end $52D74C }

{ @routine $52DAA8 SF_ShipCanJump }
procedure SF_ShipCanJump(av: array of TVarEC; code: TCodeEC);
var
  FromStar, ToStar: TStar;
  I, Count: Integer;
  Ship: TShip;
begin
  if High(av) < 3 then raise Exception.Create('Error.Script CanJump');
  Count := High(av) - 1;
  Ship := TShip(av[1].GetDword);
  for I := 0 to Count - 2 do
  begin
    FromStar := TStar(av[2 + I].GetDword);
    ToStar := TStar(av[I + 2 + 1].GetDword);
    if PointDistance(ToStar.Position, FromStar.Position) > Min(Ship.FuelTanks.Capacity, Ship.Engine.JumpRange) then
    begin
      av[0].SetInt(0);
      Exit;
    end;
  end;
  av[0].SetInt(1);
end;
{ @end $52DAA8 }

{ @routine $52DBA0 SF_ShipInStar }
procedure SF_ShipInStar(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ShipInStar');
  if TShip(av[1].GetDword).CurrentStar = TStar(av[2].GetDword) then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $52DBA0 }

{ @routine $52DC2C SF_ShipInPlanet }
procedure SF_ShipInPlanet(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ShipInPlanet');
  if TShip(av[1].GetDword).CurrentPlanet = TPlanet(av[2].GetDword) then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $52DC2C }

{ @routine $52DCBC SF_ShipStatistic }
procedure SF_ShipStatistic(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ShipStatistic');
  Obj := TObject(av[1].GetDword);
  if not (Obj is TNormalShip) then raise Exception.Create('Error.Script ShipStatistic');
  case av[2].GetInt of
    0: av[0].SetInt((Obj as TNormalShip).ScriptStatistics[ssShipsKilled]);
    1: av[0].SetInt((Obj as TNormalShip).ScriptStatistics[ssPiratesKilled]);
    2: av[0].SetInt((Obj as TNormalShip).ScriptStatistics[ssKlissansKilled]);
    3: av[0].SetInt((Obj as TNormalShip).ScriptStatistics[ssSystemsLiberated]);
  else raise Exception.Create('Error.Script ShipStatistic');
  end;
end;
{ @end $52DCBC }

{ @routine $52DDF0 SF_ShipMoney }
procedure SF_ShipMoney(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script ShipMoney');
  Ship := TShip(av[1].GetDword);
  av[0].SetInt(Ship.Money);
  if High(av) >= 2 then
  begin
    Ship.SetMoney(av[2].GetInt);
    if Ship.Money < 0 then Ship.SetMoney(0);
  end;
end;
{ @end $52DDF0 }

{ @routine $52DE8C SF_ShipFuel }
procedure SF_ShipFuel(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script ShipMoney');
  Ship := TShip(av[1].GetDword);
  if (Ship = nil) or (Ship.FuelTanks = nil) then av[0].SetInt(0)
  else av[0].SetInt(Ship.FuelTanks.Fuel);
  if (High(av) >= 2) and (Ship.FuelTanks <> nil) then
  begin
    Ship.FuelTanks.Fuel := av[2].GetInt;
    if Ship.FuelTanks.Fuel < 0 then Ship.FuelTanks.Fuel := 0;
  end;
end;
{ @end $52DE8C }

{ @routine $52DF50 SF_ShipStrengthInBestRanger }
procedure SF_ShipStrengthInBestRanger(av: array of TVarEC; code: TCodeEC);
var Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipStrengthInBestRanger');
  Ship := TShip(av[1].GetDword);
  av[0].SetFloat(Ship.StrengthInBestRanger);
end;
{ @end $52DF50 }

{ @routine $52DFD4 SF_ShipStrengthInAverageRanger }
procedure SF_ShipStrengthInAverageRanger(av: array of TVarEC; code: TCodeEC);
var Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipStrength');
  Ship := TShip(av[1].GetDword);
  av[0].SetFloat(Ship.Strength / Galaxy.AverageRangerStrength);
end;
{ @end $52DFD4 }

{ @routine $52E058 SF_RangerStatus }
procedure SF_RangerStatus(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script RangerStatus');
  Obj := TObject(av[1].GetDword);
  if not (Obj is TRanger) then raise Exception.Create('Error.Script RangerStatus 2');
  av[0].SetInt(Ord((Obj as TRanger).GetDominantCareer));
end;
{ @end $52E058 }

{ @routine $52E12C SF_ShipFind }
procedure SF_ShipFind(av: array of TVarEC; code: TCodeEC);
var
  Kind: TShipType;
  I: Integer;
  Star: TStar;
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipStrength');
  av[0].SetDword(0);
  if Player <> nil then
  begin
    Kind := TShipType(av[1].GetInt);
    Star := Player.CurrentStar;
    for I := 0 to Star.Ships.Count - 1 do
    begin
      Ship := TShip(Star.Ships[I]);
      if Ship.ShipType = Kind then
      begin
        av[0].SetDword(Cardinal(Ship));
        Exit;
      end;
    end;
  end;
end;
{ @end $52E12C }

{ @routine $52E1F4 SF_ShipDestroy }
procedure SF_ShipDestroy(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) < 1 then raise Exception.Create('Error.Script ShipDestroy');
  if High(av) <= 1 then TShip(av[1].GetDword).DestroyKind := 1
  else TShip(av[1].GetDword).DestroyKind := av[2].GetInt;
end;
{ @end $52E1F4 }

{ @routine $52E284 SF_ItemDestroy }
procedure SF_ItemDestroy(av: array of TVarEC; code: TCodeEC);
var
  Item: TScriptItem;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ItemDestroy');
  Item := TScriptItem(av[1].GetDword);
  if Item.Item <> nil then Item.Item.DestroyFlag := av[2].GetInt;
end;
{ @end $52E284 }

{ @routine $52E304 SF_RangersCapital }
procedure SF_RangersCapital(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Galaxy.AverageRangerCapital);
end;
{ @end $52E304 }

{ @routine $52E334 SF_GroupToShip }
procedure SF_GroupToShip(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
  Binding: TScriptShip;
  I, GroupIndex: Integer;
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_GroupToShip');
  GroupIndex := av[1].GetInt;
  Ship := nil;
  Count := CurrentScript.Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip(CurrentScript.Ships[I]);
    if Binding.GroupIndex = GroupIndex then
    begin
      Ship := Binding.Ship;
      if Ship <> Player then
      begin
        av[0].SetDword(Cardinal(Ship));
        Exit;
      end;
    end;
  end;
  av[0].SetDword(Cardinal(Ship));
end;
{ @end $52E334 }

{ @routine $52E408 SF_OrderJump }
procedure SF_OrderJump(av: array of TVarEC; code: TCodeEC);
var AbsoluteOrder: Boolean;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script OrderJump');
  AbsoluteOrder := False;
  if High(av) >= 3 then AbsoluteOrder := Boolean(av[3].GetInt);
  TShip(av[1].GetDword).OrderJump(TStar(av[2].GetDword), AbsoluteOrder);
end;
{ @end $52E408 }

{ @routine $52E494 SF_OrderLanding }
procedure SF_OrderLanding(av: array of TVarEC; code: TCodeEC);
var AbsoluteOrder: Boolean;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script OrderLanding');
  AbsoluteOrder := False;
  if High(av) >= 3 then AbsoluteOrder := Boolean(av[3].GetInt);
  TShip(av[1].GetDword).OrderLanding(TObject(av[2].GetDword), AbsoluteOrder);
end;
{ @end $52E494 }

{ @routine $52E524 SF_IsPlayer }
procedure SF_IsPlayer(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script IsPlayer');
  Ship := TShip(av[1].GetDword);
  av[0].SetInt(Ord(Player = Ship));
end;
{ @end $52E524 }

{ @routine $52E59C SF_GroupCount }
procedure SF_GroupCount(av: array of TVarEC; code: TCodeEC);
var
  Binding: TScriptShip;
  I, ShipCount, GroupIndex, Count: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script GroupCount');
  GroupIndex := av[1].GetInt;
  Count := 0;
  ShipCount := CurrentScript.Ships.Count;
  for I := 0 to ShipCount - 1 do
  begin
    Binding := TScriptShip(CurrentScript.Ships[I]);
    if Binding.GroupIndex = GroupIndex then Inc(Count);
  end;
  av[0].SetInt(Count);
end;
{ @end $52E59C }

{ @routine $52E654 SF_GroupIn }
procedure SF_GroupIn(av: array of TVarEC; code: TCodeEC);
var
  GroupIndex: Integer;
  Location: TObject;
  I, Count: Integer;
  Binding: TScriptShip;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script GroupIn');
  GroupIndex := av[1].GetInt;
  Location := TObject(av[2].GetDword);
  if Location is TStar then
  begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and (Binding.Ship.CurrentStar <> Location) then
      begin
        av[0].SetInt(0);
        Exit;
      end;
    end;
  end
  else if Location is TPlanet then
  begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and (not Binding.Ship.IsOnPlanet or (Binding.Ship.CurrentPlanet <> Location)) then
      begin
        av[0].SetInt(0);
        Exit;
      end;
    end;
  end
  else if Location is TScriptPlace then
  begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and (not TScriptPlace(Location).ShipInPlace(Binding.Ship)) then
      begin
        av[0].SetInt(0);
        Exit;
      end;
    end;
  end;
  av[0].SetInt(1);
end;
{ @end $52E654 }

{ @routine $52E828 SF_CountIn }
procedure SF_CountIn(av: array of TVarEC; code: TCodeEC);
var
  GroupIndex: Integer;
  Location: TObject;
  I, Count, FoundCount: Integer;
  Binding: TScriptShip;
begin
  if (High(av) < 1) or (High(av) > 2) then raise Exception.Create('Error.Script CountIn');
  GroupIndex := av[1].GetInt;
  FoundCount := 0;
  if High(av) = 1 then
  begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if Binding.GroupIndex = GroupIndex then Inc(FoundCount);
    end;
  end
  else
  begin
    Location := TObject(av[2].GetDword);
    if Location is TStar then
    begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and (Binding.Ship.CurrentStar = Location) then Inc(FoundCount);
    end;
    end
    else if Location is TPlanet then
    begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and Binding.Ship.IsOnPlanet and (Binding.Ship.CurrentPlanet = Location) then Inc(FoundCount);
    end;
    end
    else if Location is TScriptPlace then
    begin
    Count := CurrentScript.Ships.Count;
    for I := 0 to Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      if (Binding.GroupIndex = GroupIndex) and TScriptPlace(Location).ShipInPlace(Binding.Ship) then Inc(FoundCount);
    end;
    end;
  end;
  av[0].SetInt(FoundCount);
end;
{ @end $52E828 }

{ @routine $52EA28 SF_NearestGroup }
procedure SF_NearestGroup(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Binding: TScriptShip;
  I, ShipCount, J, GroupCount, GroupIndex: Integer;
  Distance, BestDistance: Single;
begin
  if High(av) < 3 then raise Exception.Create('Error.Script NearestGroup');
  Ship := TShip(av[1].GetDword);
  GroupIndex := av[2].GetInt;
  BestDistance := 1e15;
  ShipCount := CurrentScript.Ships.Count;
  GroupCount := High(av) - 1;
  for I := 0 to ShipCount - 1 do
  begin
    Binding := TScriptShip(CurrentScript.Ships[I]);
    for J := 0 to GroupCount - 1 do
      if av[2 + J].GetInt = Binding.GroupIndex then Break;
    if (J < GroupCount) and (Binding.Ship.CurrentStar = Ship.CurrentStar) and
      Binding.Ship.InNormalSpace then
    begin
      Distance := PointDistanceSquared(Ship.Position, Binding.Ship.Position);
      if Distance < BestDistance then
      begin
        BestDistance := Distance;
        GroupIndex := Binding.GroupIndex;
      end;
    end;
  end;
  av[0].SetInt(GroupIndex);
end;
{ @end $52EA28 }

{ @routine $52EB74 SF_ChangeState }
procedure SF_ChangeState(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) < 1 then raise Exception.Create('Error.Script ChangeState');
  if High(av) >= 2 then CurrentScript.ChangeState(GetScriptShipBindingForContext(TShip(av[2].GetDword), CurrentScript), av[1].GetInt)
  else CurrentScript.ChangeState(GetScriptShipBindingForContext(CurrentScript.CurrentShip, CurrentScript), av[1].GetInt);
end;
{ @end $52EB74 }

{ @routine $52EC38 SF_StarAngle }
procedure SF_StarAngle(av: array of TVarEC; code: TCodeEC);
var
  First, Second: TStar;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script StarAngle');
  First := TStar(av[1].GetDword);
  Second := TStar(av[2].GetDword);
  av[0].SetFloat(PointBearingDegrees(First.Position, Second.Position));
end;
{ @end $52EC38 }

{ @routine $52ECC4 SF_NewsAdd }
procedure SF_NewsAdd(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script NewsAdd');
  AddOrUpdatePlayerBubble(pmGalaxy, Galaxy.CurrentTurn, av[1].GetString, '');
end;
{ @end $52ECC4 }

{ @routine $52ED70 SF_MsgAdd }
procedure SF_MsgAdd(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Binding: TScriptShip;
  GroupIndex, I, Count: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script NewsAdd');
  Ship := nil;
  GroupIndex := av[2].GetInt;
  Count := CurrentScript.Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip(CurrentScript.Ships[I]);
    if GroupIndex = Binding.GroupIndex then
    begin
      Ship := Binding.Ship;
      Break;
    end;
  end;
  if (Ship = nil) or Player.InHyperspace or (Player.CurrentStar <> Ship.CurrentStar) then
    av[0].SetInt(0)
  else
  begin
    with AddOrUpdatePlayerBubble(pmEther, Galaxy.CurrentTurn, av[1].GetString, '') do
      TargetIds[0] := Ship.Id;
    av[0].SetInt(1);
  end;
end;
{ @end $52ED70 }

{ @routine $52EEC0 SF_Ether }
procedure SF_Ether(av: array of TVarEC; code: TCodeEC);
var Key: WideString; Kind: TPlayerMessageKind; Ship: TShip; Message: TMessagePlayer;
begin
  if High(av) < 3 then raise Exception.Create('Error.Script Ether');
  Ship := nil;
  if High(av) >= 4 then
  begin
    Ship := TShip(av[4].GetDword);
    if Ship = nil then begin av[0].SetInt(0); Exit; end;
  end;
  Kind := TPlayerMessageKind(av[1].GetInt);
  Key := av[2].GetString;
  if (Kind <> pmQuestNormal) and (Kind <> pmQuestOk) and (Kind <> pmQuestCancel) then
  begin
    if (Key <> '') and (CurrentScript.Ether.FindIndex(Key) >= 0) then
    begin av[0].SetInt(0); Exit; end;
    if (Ship <> nil) and
      (not Player.InNormalSpace or (Player.CurrentStar <> Ship.CurrentStar) or not Ship.InNormalSpace) then
    begin av[0].SetInt(0); Exit; end;
    CurrentScript.Ether.Add(Key, 0);
  end;
  if Kind = pmQuestNormal then
    if Key <> '' then CurrentScript.EtherIds.Add(Key);
  Message := AddOrUpdatePlayerBubble(Kind, Galaxy.CurrentTurn, av[3].GetString, Key);
  if Ship <> nil then Message.TargetIds[0] := Ship.Id;
  if High(av) >= 5 then Message.TargetIds[1] := TShip(av[5].GetDword).Id;
  if High(av) >= 6 then Message.TargetIds[2] := TShip(av[6].GetDword).Id;
  av[0].SetInt(1);
end;
{ @end $52EEC0 }

{ @routine $52F0C4 SF_EtherState }
procedure SF_EtherState(av: array of TVarEC; code: TCodeEC);
var
  MessageEntry: TMessagePlayer;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script EtherState');
  MessageEntry := FindPlayerBubbleByKey(av[1].GetString);
  if MessageEntry = nil then av[0].SetInt(-1) else av[0].SetInt(Ord(MessageEntry.Kind));
end;
{ @end $52F0C4 }

{ @routine $52F17C SF_ConChangeRelationToRanger }
procedure SF_ConChangeRelationToRanger(av: array of TVarEC; code: TCodeEC);
var
  Ranger: TRanger;
  Sector: TConstellation;
  Amount: Integer;
  Star: TStar;
  Planet: TPlanet;
  StarIndex, PlanetIndex, StarCount, PlanetCount: Integer;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script ConChangeRelationToRanger');
  Sector := TConstellation(av[1].GetDword);
  Ranger := TRanger(av[2].GetDword);
  Amount := av[3].GetInt;
  // The native loop stops before the constellation's last star.
  StarCount := Sector.Stars.Count - 1;
  for StarIndex := 0 to StarCount - 1 do
  begin
    Star := TStar(Sector.Stars[StarIndex]);
    PlanetCount := Star.Planets.Count;
    for PlanetIndex := 0 to PlanetCount - 1 do
    begin
      Planet := TPlanet(Star.Planets[PlanetIndex]);
      if Planet.OwnerId <> oiNone then Planet.ChangeRelationToRanger(Ranger, Amount);
    end;
  end;
end;
{ @end $52F17C }

{ @routine $52F278 SF_GetData }
procedure SF_GetData(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
  Ship: TShip;
begin
  Index := 0;
  Ship := CurrentScript.CurrentShip;
  if High(av) >= 1 then Index := av[1].GetInt;
  if High(av) >= 2 then Ship := TShip(av[2].GetDword);
  av[0].SetDword(GetScriptShipBindingForContext(Ship, CurrentScript).Data[Index]);
end;
{ @end $52F278 }

{ @routine $52F2E8 SF_SetData }
procedure SF_SetData(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
  Ship: TShip;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script SetData');
  Index := 0;
  Ship := CurrentScript.CurrentShip;
  if High(av) >= 2 then Index := av[2].GetInt;
  if High(av) >= 3 then Ship := TShip(av[3].GetDword);
  GetScriptShipBindingForContext(Ship, CurrentScript).Data[Index] := av[1].GetDword;
end;
{ @end $52F2E8 }

{ @routine $52F3A0 SF_ShipData }
procedure SF_ShipData(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetDword(GetScriptShipBindingForContext(CurrentScript.CurrentShip, CurrentScript).Data[0]);
  if High(av) >= 1 then
    GetScriptShipBindingForContext(CurrentScript.CurrentShip, CurrentScript).Data[0] := av[1].GetDword;
end;
{ @end $52F3A0 }

{ @routine $52F410 SF_Format }
procedure SF_Format(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
  I, Count: Integer;
begin
  if High(av) < 1 then raise Exception.Create('Error.Script Format');
  Text := av[1].GetString;
  Count := (Length(av) - 2) div 2;
  for I := 0 to Count - 1 do
    Text := ReplaceAllWideString(Text, av[2 + I * 2].GetString, WrapTextInColor(av[2 + I * 2 + 1].GetString, HighlightColorTag));
  av[0].SetString(Text);
end;
{ @end $52F410 }

{ @routine $52F558 SF_Dialog }
procedure SF_Dialog(av: array of TVarEC; code: TCodeEC);
var I, J, Count, ShipCount: Integer; Obj, Target: TObject; Binding: TScriptShip;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script Dialog');
  Count := Length(av) - 2;
  for I := 0 to Count - 1 do
  begin
    Obj := TObject(av[2 + I].GetDword);
    if Cardinal(Obj) < $100 then
    begin
      ShipCount := CurrentScript.Ships.Count;
      for J := 0 to ShipCount - 1 do
      begin
        Binding := TScriptShip(CurrentScript.Ships[J]);
        if (Binding.GroupIndex = Integer(Obj)) and (Player <> Binding.Ship) then
        begin
          ScriptDialogIndex := -1;
          CurrentScript.CallDialog(av[1].GetInt);
          if (ScriptDialogIndex >= 0) and Binding.Ship.RequestPlayerDialogue then
          begin av[0].SetInt(1); Exit; end;
        end;
      end;
    end
    else
    begin
      Target := Obj;
      if Target is TShip then
      begin
        ScriptDialogIndex := -1;
        CurrentScript.CallDialog(av[1].GetInt);
        if (ScriptDialogIndex >= 0) and TShip(Target).RequestPlayerDialogue then
        begin av[0].SetInt(1); Exit; end;
      end
      else if Target is TPlanet then
      begin
        ScriptDialogIndex := -1;
        CurrentScript.CallDialog(av[1].GetInt);
        if (ScriptDialogIndex >= 0) and TPlanet(Target).RequestDialog then
        begin av[0].SetInt(1); Exit; end;
      end;
    end;
  end;
  av[0].SetInt(0);
end;
{ @end $52F558 }

{ @routine $52F760 SF_DText }
procedure SF_DText(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script DText');
  if Player.IsDockedToShip then RuinsTalkScreen.DialogText := av[1].GetString
  else if not Player.IsOnPlanet then TalkScreen.DialogText := av[1].GetString
  else GovernmentScreen.DialogText := av[1].GetString;
end;
{ @end $52F760 }

{ @routine $52F870 SF_DAdd }
procedure SF_DAdd(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script DAdd');
  CurrentScript.BuildDialogAnswer(av[1].GetInt);
end;
{ @end $52F870 }

{ @routine $52F8E0 SF_DAnswer }
procedure SF_DAnswer(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script DAnswer');
  if Player.IsDockedToShip then
  begin
    if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'takeoff' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        RuinsTalkScreen.AddScriptTakeoffChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        RuinsTalkScreen.AddScriptTakeoffChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'exit' then RuinsTalkScreen.ContinueScriptDialog
    else if LowerCase(AnsiString(av[1].GetString)) = 'main' then RuinsTalkScreen.ContinueScriptDialog
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'exit_news' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        RuinsTalkScreen.AddScriptNewsExitChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        RuinsTalkScreen.AddScriptNewsExitChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'exit_end' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        RuinsTalkScreen.AddScriptGameEndChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        RuinsTalkScreen.AddScriptGameEndChoice('');
    end
    else RuinsTalkScreen.AddChoice('- ' + av[1].GetString, CurrentScript.CurrentAnswer, RuinsTalkScreen.RunScriptAnswer);
  end
  else if not Player.IsOnPlanet then
  begin
    if (ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'exit') or (ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'takeoff') then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        TalkScreen.AddScriptExitChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        TalkScreen.AddScriptExitChoice('');
    end
    else if LowerCase(AnsiString(av[1].GetString)) = 'main' then TalkScreen.BuildBuiltinChoices
    else TalkScreen.AddChoice('- ' + av[1].GetString, CurrentScript.CurrentAnswer, TalkScreen.RunScriptAnswer);
  end
  else
  begin
    if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'takeoff' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        GovernmentScreen.AddScriptTakeoffChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        GovernmentScreen.AddScriptTakeoffChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'planet' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        GovernmentScreen.AddScriptPlanetChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        GovernmentScreen.AddScriptPlanetChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'goods' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        GovernmentScreen.AddScriptGoodsChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        GovernmentScreen.AddScriptGoodsChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'shop' then
    begin
      Count := CountDelimitedPartsW(av[1].GetString, '~');
      if Count > 1 then
        GovernmentScreen.AddScriptShopChoice(ExtractDelimitedRangeW(av[1].GetString, 1, Count - 1, '~'))
      else
        GovernmentScreen.AddScriptShopChoice('');
    end
    else if ExtractDelimitedPartW(LowerCase(AnsiString(av[1].GetString)), 0, '~') = 'exit' then GovernmentScreen.ContinueScriptDialog
    else if LowerCase(AnsiString(av[1].GetString)) = 'main' then GovernmentScreen.ContinueScriptDialog
    else GovernmentScreen.AddChoice('- ' + av[1].GetString, CurrentScript.CurrentAnswer, GovernmentScreen.RunScriptAnswer);
  end;
end;
{ @end $52F8E0 }

{ @routine $5305B0 SF_DChange }
procedure SF_DChange(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script DChange');
  ScriptDialogIndex := av[1].GetInt;
end;
{ @end $5305B0 }

{ @routine $53061C SF_Player }
procedure SF_Player(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetDword(Cardinal(Player));
end;
{ @end $53061C }

{ @routine $53064C SF_ItemExist }
procedure SF_ItemExist(av: array of TVarEC; code: TCodeEC);
var
  Item: TScriptItem;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ItemExist');
  Item := TScriptItem(av[1].GetDword);
  if Item.Item = nil then av[0].SetInt(0) else av[0].SetInt(1);
end;
{ @end $53064C }

{ @routine $5306CC SF_ItemIn }
procedure SF_ItemIn(av: array of TVarEC; code: TCodeEC);
var Item: TScriptItem; Obj: TObject; Ship: TShip; Planet: TPlanet; Star: TStar;
    Binding: TScriptShip; I: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ItemInStar');
  Item := TScriptItem(av[1].GetDword);
  if Item.Item = nil then begin av[0].SetInt(0); Exit; end;
  Obj := TObject(av[2].GetDword);
  if Cardinal(Obj) < $100 then
  begin
    for I := 0 to CurrentScript.Ships.Count - 1 do
    begin
      Binding := TScriptShip(CurrentScript.Ships[I]);
      // Ignores the supplied group and excludes inventory index zero.
      if (Binding.Ship.Inventory.IndexOf(Item.Item) > 0) or
        (Binding.Ship.Artefacts.IndexOf(Item.Item) > 0) then
      begin av[0].SetInt(1); Exit; end;
    end;
    av[0].SetInt(0);
  end
  else if Obj is TStar then
  begin
    Star := Obj as TStar;
    if Star.Items.IndexOf(Item.Item) < 0 then av[0].SetInt(0)
    else av[0].SetInt(1);
  end
  else if Obj is TShip then
  begin
    Ship := Obj as TShip;
    if (Ship.Inventory.IndexOf(Item.Item) < 0) and (Ship.Artefacts.IndexOf(Item.Item) < 0) then
      av[0].SetInt(0)
    else av[0].SetInt(1);
  end
  else if Obj is TPlanet then
  begin
    Planet := Obj as TPlanet;
    if (Player.CurrentPlanet = Planet) and (TemporaryShopSlots <> nil) then
    begin
      if FindShopSlotByItem(Item.Item) = nil then av[0].SetInt(0) else av[0].SetInt(1);
    end
    else if Planet.EquipmentShop.IndexOf(Item.Item) < 0 then av[0].SetInt(0)
    else av[0].SetInt(1);
  end;
end;
{ @end $5306CC }

{ @routine $53093C SF_ItemCost }
procedure SF_ItemCost(av: array of TVarEC; code: TCodeEC);
var
  Item: TScriptItem;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SF_ItemCost');
  Item := TScriptItem(av[1].GetDword);
  if Item.Item = nil then av[0].SetInt(0)
  else av[0].SetInt(Item.Item.Cost);
end;
{ @end $53093C }

{ @routine $5309C4 SF_ItemCount }
procedure SF_ItemCount(av: array of TVarEC; code: TCodeEC);
var
  Kind: TItemType;
  Ship: TShip;
  I, Count: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script SF_ItemCount');
  Ship := TShip(av[1].GetDword);
  Kind := TItemType(av[2].GetInt);
  Count := 0;
  for I := 0 to Ship.Inventory.Count - 1 do
    if TItem(Ship.Inventory[I]).ItemType = Kind then Inc(Count);
  for I := 0 to Ship.Artefacts.Count - 1 do
    if TItem(Ship.Artefacts[I]).ItemType = Kind then Inc(Count);
  av[0].SetInt(Count);
end;
{ @end $5309C4 }

{ @routine $530AB4 SF_DecayGoods }
procedure SF_DecayGoods(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
  Kind: TItemType;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script DecayGoods');
  Index := av[2].GetInt;
  if Index = 0 then Kind := t_Food
  else if Index = 1 then Kind := t_Medicine
  else if Index = 2 then Kind := t_Technics
  else if Index = 3 then Kind := t_Luxury
  else if Index = 4 then Kind := t_Minerals
  else if Index = 5 then Kind := t_Alcohol
  else if Index = 6 then Kind := t_Arms
  else if Index = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script DecayGoods 1');
  TPlanet(av[1].GetDword).StartGoodsDecay(True, [Kind]);
end;
{ @end $530AB4 }

{ @routine $530BBC SF_UpsurgeGoods }
procedure SF_UpsurgeGoods(av: array of TVarEC; code: TCodeEC);
var
  Index: Integer;
  Kind: TItemType;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script DecayGoods');
  Index := av[2].GetInt;
  if Index = 0 then Kind := t_Food
  else if Index = 1 then Kind := t_Medicine
  else if Index = 2 then Kind := t_Technics
  else if Index = 3 then Kind := t_Luxury
  else if Index = 4 then Kind := t_Minerals
  else if Index = 5 then Kind := t_Alcohol
  else if Index = 6 then Kind := t_Arms
  else if Index = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script UpsurgeGoods 1');
  TPlanet(av[1].GetDword).StartGoodsUpsurge(True, [Kind]);
end;
{ @end $530BBC }

{ @routine $530CC4 SF_GoodsAdd }
procedure SF_GoodsAdd(av: array of TVarEC; code: TCodeEC);
var
  KindIndex: Integer;
  Kind: TItemType;
  Obj: TObject;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script GoodsAdd');
  KindIndex := av[2].GetInt;
  if KindIndex = 0 then Kind := t_Food
  else if KindIndex = 1 then Kind := t_Medicine
  else if KindIndex = 2 then Kind := t_Technics
  else if KindIndex = 3 then Kind := t_Luxury
  else if KindIndex = 4 then Kind := t_Minerals
  else if KindIndex = 5 then Kind := t_Alcohol
  else if KindIndex = 6 then Kind := t_Arms
  else if KindIndex = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script UpsurgeGoods 1');
  Obj := TObject(av[1].GetDword);
  if Obj is TPlanet then
  begin
    with TPlanet(Obj).Goods[Kind] do
    begin
      Inc(Count, av[3].GetInt);
      av[0].SetInt(Count);
    end;
  end
  else if Obj is TShip then
  begin
    with TShip(Obj).CargoGoods[Kind] do
    begin
      Inc(Count, av[3].GetInt);
      av[0].SetInt(Count);
    end;
  end;
end;
{ @end $530CC4 }

{ @routine $530E28 SF_GoodsCount }
procedure SF_GoodsCount(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Kind, Count: Integer;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script GoodsCount');
  Ship := TShip(av[1].GetDword);
  Kind := av[2].GetInt;
  if Kind = 0 then Count := Ship.CargoGoods[t_Food].Count
  else if Kind = 1 then Count := Ship.CargoGoods[t_Medicine].Count
  else if Kind = 2 then Count := Ship.CargoGoods[t_Technics].Count
  else if Kind = 3 then Count := Ship.CargoGoods[t_Luxury].Count
  else if Kind = 4 then Count := Ship.CargoGoods[t_Minerals].Count
  else if Kind = 5 then Count := Ship.CargoGoods[t_Alcohol].Count
  else if Kind = 6 then Count := Ship.CargoGoods[t_Arms].Count
  else if Kind = 7 then Count := Ship.CargoGoods[t_Narcotics].Count
  else raise Exception.Create('Error.Script GoodsCount 1');
  av[0].SetInt(Count);
end;
{ @end $530E28 }

{ @routine $530F28 SF_ShipGoods }
procedure SF_ShipGoods(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Kind, Count: Integer;
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script ShipGoods');
  Ship := TShip(av[1].GetDword);
  Kind := av[2].GetInt;
  Count := av[3].GetInt;
  case Kind of
    0: Inc(Ship.CargoGoods[t_Food].Count, Count);
    1: Inc(Ship.CargoGoods[t_Medicine].Count, Count);
    2: Inc(Ship.CargoGoods[t_Technics].Count, Count);
    3: Inc(Ship.CargoGoods[t_Luxury].Count, Count);
    4: Inc(Ship.CargoGoods[t_Minerals].Count, Count);
    5: Inc(Ship.CargoGoods[t_Alcohol].Count, Count);
    6: Inc(Ship.CargoGoods[t_Arms].Count, Count);
    7: Inc(Ship.CargoGoods[t_Narcotics].Count, Count);
  else raise Exception.Create('Error.Script ShipGoods 1');
  end;
end;
{ @end $530F28 }

{ @routine $531034 SF_GoodsDrop }
procedure SF_GoodsDrop(av: array of TVarEC; code: TCodeEC);
var Ship: TShip; Goods: TGoods; Item: TItem; Kind: TItemType; Count: Integer;
    Angle: Single; Star: TStar; Binding: TScriptItem;
begin
  if High(av) < 3 then raise Exception.Create('Error.Script GoodsDrop');
  Ship := TShip(av[1].GetDword);
  Count := av[2].GetInt;
  if Count = 0 then Kind := t_Food
  else if Count = 1 then Kind := t_Medicine
  else if Count = 2 then Kind := t_Technics
  else if Count = 3 then Kind := t_Luxury
  else if Count = 4 then Kind := t_Minerals
  else if Count = 5 then Kind := t_Alcohol
  else if Count = 6 then Kind := t_Arms
  else if Count = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script GoodsDrop 1');
  Count := Min(Ship.CargoGoods[Kind].Count, av[3].GetInt);
  if Count < 1 then begin av[0].SetInt(0); Exit; end;
  if Ship <> Player then
  begin
    Ship.DropGoodsIntoSpace(Kind, Count);
    Item := PMovingDropItemEntry(Ship.CurrentStar.MovingDropItems[Ship.CurrentStar.MovingDropItems.Count - 1]).Payload as TItem;
  end
  else
  begin
    SoundManager.PlaySound('Sound.Drop');
    Dec(Ship.CargoGoods[Kind].Count, Count);
    Star := Player.CurrentStar;
    Goods := TGoods.Create;
    Goods.Init(Kind, Count);
    Star.Items.Add(Goods);
    Angle := SeededRandomIntRange(0, 360, Player.CurrentStar.GenerationSeed * Cardinal(Galaxy.CurrentTurn) * ReadByteValue(Kind)) * Pi / 180;
    Goods.Position.X := Sin(Angle) * 100 + Player.Position.X;
    Goods.Position.Y := Player.Position.Y - Cos(Angle) * 100;
    Goods.GetGraphObject.SetPosition(Goods.Position);
    Item := Goods;
  end;
  if High(av) >= 4 then
  begin
    Binding := TScriptItem(av[4].GetDword);
    if Binding.Item <> nil then Binding.Item.ScriptItem := nil;
    Binding.Item := Item;
    Item.ScriptItem := Binding;
  end;
  av[0].SetInt(1);
end;
{ @end $531034 }

{ @routine $5312E4 SF_UselessItemCreate }
procedure SF_UselessItemCreate(av: array of TVarEC; code: TCodeEC);
var Item: TItem; Binding: TScriptItem; Place: TScriptPlace; Angle: Single;
begin
  if High(av) < 3 then raise Exception.Create('Error.Script UselessItemCreate');
  Item := TUselessItem.Create;
  (Item as TUselessItem).Init(av[1].GetString, 0);
  Binding := TScriptItem(av[2].GetDword);
  if Binding.Item <> nil then Binding.Item.ScriptItem := nil;
  Binding.Item := Item;
  Item.ScriptItem := Binding;
  Place := TScriptPlace(av[3].GetDword);
  if (Place.PlaceKind <> spkPolar) and (Place.PlaceKind <> spkPlanetPosition) and (Place.PlaceKind <> spkStarDirection) and
    (Place.PlaceKind <> spkGroupCentroid) then RaiseWideMessage('Error.Script UselessItemCreate place');
  Place.OriginStar.Items.Add(Item);
  Item.Position := Place.GetPoint;
  Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 359, Item.Id * Place.OriginStar.GenerationSeed));
  Item.Position.X := Sin(Angle) * Place.Radius + Item.Position.X;
  Item.Position.Y := Item.Position.Y - Cos(Angle) * Place.Radius;
end;
{ @end $5312E4 }

{ @routine $5314BC SF_GoodsSellPrice }
procedure SF_GoodsSellPrice(av: array of TVarEC; code: TCodeEC);
var Planet: TPlanet; Kind: TItemType; Value: Integer;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script GoodsSellPrice');
  Planet := TPlanet(av[1].GetDword);
  Value := av[2].GetInt;
  if Value = 0 then Kind := t_Food
  else if Value = 1 then Kind := t_Medicine
  else if Value = 2 then Kind := t_Technics
  else if Value = 3 then Kind := t_Luxury
  else if Value = 4 then Kind := t_Minerals
  else if Value = 5 then Kind := t_Alcohol
  else if Value = 6 then Kind := t_Arms
  else if Value = 7 then Kind := t_Narcotics
  else raise Exception.Create('Error.Script GoodsSellPrice 1');
  av[0].SetInt(Planet.Goods[Kind].BaseSalePrice);
end;
{ @end $5314BC }

{ @routine $5315C8 SF_CountTurn }
procedure SF_CountTurn(av: array of TVarEC; code: TCodeEC);
var
  Ship, OtherShip: TShip;
  Turns: Integer;
  Obj: TObject;
  Planet: TPlanet;
  Place: TScriptPlace;
  Landed: Boolean;
  Position: TPointF;
  Star: TStar;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script CountTurn');
  Turns := 0;
  Ship := TShip(av[1].GetDword);
  Obj := TObject(av[2].GetDword);
  if Obj is TScriptPlace then
  begin
    Place := Obj as TScriptPlace;
    if (Place.PlaceKind = spkPlanetPosition) or (Place.PlaceKind = spkDockedPlanet) then
    begin
      Planet := TObject(Place.TargetValue) as TPlanet;
      Position := Planet.GetPosition;
    end
    else
    begin
      Planet := nil;
      Position := Place.GetPoint;
    end;
    Landed := Place.PlaceKind = spkDockedPlanet;
    Star := Place.OriginStar;
  end
  else if Obj is TPlanet then
  begin
    Planet := Obj as TPlanet;
    Landed := False;
    Position := Planet.GetPosition;
    Star := Planet.CurrentStar;
  end
  else if Obj is TShip then
  begin
    Landed := False;
    Planet := nil;
    OtherShip := Obj as TShip;
    while OtherShip.DockedTo <> nil do OtherShip := OtherShip.DockedTo;
    if OtherShip.CurrentPlanet <> nil then
    begin
      Planet := OtherShip.CurrentPlanet;
      Landed := True;
      Position := Planet.GetPosition;
      Star := Planet.CurrentStar;
    end
    else
    begin
      Position := OtherShip.Position;
      Star := OtherShip.CurrentStar;
      if OtherShip.InHyperspace then Position := OtherShip.GetArrivalPosition(OtherShip.TransitOriginStar);
    end;
  end
  else raise Exception.Create('Error.Script CountTurn 1');
  if (Ship.CurrentPlanet = Planet) and Landed then
  begin
    av[0].SetInt(0);
    Exit;
  end;
  if Ship.CurrentPlanet <> nil then Inc(Turns);
  if Landed then Inc(Turns);
  if (Ship.CurrentPlanet <> nil) and (Ship.CurrentPlanet = Planet) then
  begin
    av[0].SetInt(Turns);
    Exit;
  end;
  if Star = Ship.CurrentStar then
  begin
    if Ship.CurrentPlanet = nil then Inc(Turns, Ceil(PointDistance(Position, Ship.Position) / Max(1, Ship.Speed)))
    else Inc(Turns, Ceil(PointDistance(Position, Ship.CurrentPlanet.GetPosition) / Max(1, Ship.Speed)));
  end
  else
  begin
    if Ship.CurrentPlanet = nil then Inc(Turns, Ceil(PointDistance(Ship.GetJumpDeparturePoint(Star), Ship.Position) / Max(1, Ship.Speed)))
    else Inc(Turns, Ceil(PointDistance(Ship.GetJumpDeparturePoint(Star), Ship.CurrentPlanet.GetPosition) / Max(1, Ship.Speed)));
    Inc(Turns, Ship.CalculateJumpTravelDays(Ship.CurrentStar, Star));
    Inc(Turns, Ceil(PointDistance(Position, Ship.GetArrivalPosition(Star)) / Max(1, Ship.Speed)));
  end;
  av[0].SetInt(Turns);
end;
{ @end $5315C8 }

{ @routine $5319A8 SF_ShipSetBad }
procedure SF_ShipSetBad(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script ShipSetBad');
  if av[1].GetDword <> 0 then TShip(av[1].GetDword).EnemyShip := TShip(av[2].GetDword);
end;
{ @end $5319A8 }

{ @routine $531A2C SF_GroupSetBad }
procedure SF_GroupSetBad(av: array of TVarEC; code: TCodeEC);
var
  GroupIndex, I, Count: Integer;
  Binding: TScriptShip;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script GroupSetBad');
  GroupIndex := av[1].GetInt;
  Count := CurrentScript.Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip(CurrentScript.Ships[I]);
    if Binding.GroupIndex = GroupIndex then Binding.Ship.EnemyShip := TShip(av[2].GetDword);
  end;
end;
{ @end $531A2C }

{ @routine $531AEC SF_ShipSetPartner }
procedure SF_ShipSetPartner(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 3 then raise Exception.Create('Error.Script ShipSetPartner');
  TShip(av[1].GetDword).PartnerShip := TShip(av[2].GetDword);
  TShip(av[1].GetDword).PartnershipDaysRemaining := av[3].GetInt;
end;
{ @end $531AEC }

{ @routine $531B80 SF_ShipJoin }
procedure SF_ShipJoin(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
  Binding: TScriptShip;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script ShipAdd');
  Ship := TShip(av[2].GetDword);
  CurrentScript.BindShip(av[1].GetInt, Ship);
  Binding := GetScriptShipBindingForContext(Ship, CurrentScript);
  if High(av) <> 3 then
    CurrentScript.ChangeState(Binding, TScriptGroup(Binding.Script.Groups[Binding.GroupIndex]).InitialStateIndex);
end;
{ @end $531B80 }

{ @routine $531C38 SF_ShipOut }
procedure SF_ShipOut(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) < 1 then Ship := CurrentScript.CurrentShip else Ship := TShip(av[1].GetDword);
  if Ship <> nil then CurrentScript.UnbindShip(Ship);
end;
{ @end $531C38 }

{ @routine $531C84 SF_ShipInScript }
procedure SF_ShipInScript(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipInScript');
  if TShip(av[1].GetDword).HasScriptBindings then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $531C84 }

{ @routine $531D0C SF_ShipInCurScript }
procedure SF_ShipInCurScript(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipInScript');
  if GetScriptShipBindingForContext(TShip(av[1].GetDword), CurrentScript).Script = CurrentScript then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $531D0C }

{ @routine $531DA4 SF_ShipInNormalSpace }
procedure SF_ShipInNormalSpace(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipInScript');
  if TShip(av[1].GetDword).InNormalSpace then av[0].SetInt(1)
  else av[0].SetInt(0);
end;
{ @end $531DA4 }

{ @routine $531E2C SF_ShipInHole }
procedure SF_ShipInHole(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipInHole');
  Ship := TShip(av[1].GetDword);
  if Ship.InHyperspace and (Ship.Order = soEnterBlackHole) then av[0].SetInt(1) else av[0].SetInt(0);
end;
{ @end $531E2C }

{ @routine $531EB8 SF_ShipIsTakeoff }
procedure SF_ShipIsTakeoff(av: array of TVarEC; code: TCodeEC);
var
  Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipIsTakeoff');
  Ship := TShip(av[1].GetDword);
  if Ship.Order = soTakeoff then av[0].SetInt(1) else av[0].SetInt(0);
end;
{ @end $531EB8 }

{ @routine $531F40 SF_ShipCntWeapon }
procedure SF_ShipCntWeapon(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script WeaponCount');
  av[0].SetInt(TShip(av[1].GetDword).WeaponCount);
end;
{ @end $531F40 }
{ @routine $531FB8 SF_ShipGroup }
procedure SF_ShipGroup(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipGroup');
  av[0].SetInt(GetScriptShipBindingForContext(TShip(av[1].GetDword), CurrentScript).GroupIndex);
end;
{ @end $531FB8 }

{ @routine $532034 SF_ShipSpeed }
procedure SF_ShipSpeed(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script ShipSpeed');
  av[0].SetInt(TShip(av[1].GetDword).Speed);
end;
{ @end $532034 }

{ @routine $5320A4 SF_GroupIs }
procedure SF_GroupIs(av: array of TVarEC; code: TCodeEC);
var
  I, Count, GroupIndex: Integer;
  Binding: TScriptShip;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script GroupIs');
  Binding := GetScriptShipBindingForContext(TShip(av[1].GetDword), CurrentScript);
  GroupIndex := Binding.GroupIndex;
  Count := Length(av) - 2;
  for I := 0 to Count - 1 do
    if av[2 + I].GetInt = GroupIndex then
    begin
      av[0].SetInt(1);
      Exit;
    end;
  av[0].SetInt(0);
end;
{ @end $5320A4 }

{ @routine $53215C SF_StateIs }
procedure SF_StateIs(av: array of TVarEC; code: TCodeEC);
var
  I, Count: Integer;
  State: TScriptState;
begin
  if High(av) < 2 then raise Exception.Create('Error.Script StateIs');
  State := GetScriptShipBindingForContext(TShip(av[1].GetDword), CurrentScript).State;
  if State = nil then
  begin
    av[0].SetInt(0);
    Exit;
  end;
  begin
    Count := Length(av) - 2;
    for I := 0 to Count - 1 do
      if State.Name = av[2 + I].GetString then
      begin
        av[0].SetInt(1);
        Exit;
      end;
  end;
  av[0].SetInt(0);
end;
{ @end $53215C }

{ @routine $532268 SF_Dist }
procedure SF_Dist(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
  Point1, Point2: TPointF;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script Dist');
  Obj := TObject(av[1].GetDword);
  if Obj is TShip then Point1 := (Obj as TShip).Position
  else if Obj is TScriptPlace then Point1 := (Obj as TScriptPlace).GetPoint
  // The original repeats this type check.
  else if Obj is TScriptPlace then Point1 := (Obj as TScriptPlace).GetPoint
  else if Obj is TPlanet then Point1 := (Obj as TPlanet).GetPosition
  else if Obj is TStar then Point1 := (Obj as TStar).Position
  else raise Exception.Create('Error.Script Dist 1');
  Obj := TObject(av[2].GetDword);
  if Obj is TShip then Point2 := (Obj as TShip).Position
  else if Obj is TScriptPlace then Point2 := (Obj as TScriptPlace).GetPoint
  else if Obj is TPlanet then Point2 := (Obj as TPlanet).GetPosition
  else if Obj is TStar then Point2 := (Obj as TStar).Position
  else raise Exception.Create('Error.Script Dist 2');
  av[0].SetInt(Round(PointDistance(Point1, Point2)));
end;
{ @end $532268 }

{ @routine $5324D8 SF_Dist2Star }
procedure SF_Dist2Star(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script DistStar');
  av[0].SetFloat(PointDistanceSquared(TStar(av[1].GetDword).Position, TStar(av[2].GetDword).Position));
end;
{ @end $5324D8 }

{ @routine $532560 SF_BuyPirate }
procedure SF_BuyPirate(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script BuyPirate');
  TPlanet(av[1].GetDword).SpawnPirate;
end;
{ @end $532560 }

{ @routine $5325C8 SF_BuyTransport }
procedure SF_BuyTransport(av: array of TVarEC; code: TCodeEC);
var Ship: TShip;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script BuyTransport');
  Ship := TPlanet(av[1].GetDword).SpawnTransport(RandomTransportHullType) as TShip;
  av[0].SetDword(Cardinal(Ship));
end;
{ @end $5325C8 }

{ @routine $53264C SF_Name }
procedure SF_Name(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script Name');
  Obj := TObject(av[1].GetDword);
  if Obj is TStar then av[0].SetString(TStar(Obj).Name)
  else if Obj is TPlanet then av[0].SetString(TPlanet(Obj).Name)
  else if Obj is TShip then av[0].SetString(TShip(Obj).GetFullName(' '))
  else if Obj is TScriptItem then
  begin
    if TScriptItem(Obj).Item = nil then av[0].SetString('NameError')
    else av[0].SetString(TScriptItem(Obj).Item.GetDisplayName);
  end
  else av[0].SetString('NameError');
end;
{ @end $53264C }

{ @routine $5327BC SF_ShortName }
procedure SF_ShortName(av: array of TVarEC; code: TCodeEC);
var
  Obj: TObject;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script Name');
  Obj := TObject(av[1].GetDword);
  if Obj is TStar then av[0].SetString(TStar(Obj).Name)
  else if Obj is TPlanet then av[0].SetString(TPlanet(Obj).Name)
  else if Obj is TShip then av[0].SetString(HighlightColorTag + TShip(Obj).GetName + ColorEndTag)
  else if Obj is TScriptItem then
  begin
    if TScriptItem(Obj).Item = nil then av[0].SetString('NameError')
    else av[0].SetString(TScriptItem(Obj).Item.GetDisplayName);
  end
  else av[0].SetString('NameError');
end;
{ @end $5327BC }

{ @routine $53297C SF_FirstGiveMoney }
procedure SF_FirstGiveMoney(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Round(300 * DifficultyModifiers[Galaxy.Difficulty].StartingMoneyFactor));
end;
{ @end $53297C }

{ @routine $5329D0 SF_ScenarioState }
procedure SF_ScenarioState(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Integer(ScenarioState));
  if High(av) >= 1 then ScenarioState := TScenarioState(av[1].GetInt);
end;
{ @end $5329D0 }

{ @routine $532A18 SF_HaveCommunicator }
procedure SF_HaveCommunicator(av: array of TVarEC; code: TCodeEC);
begin
  av[0].SetInt(Ord(Player.HaveCommunicator));
end;
{ @end $532A18 }

{ @routine $532A4C SF_HoleMamaCreate }
procedure SF_HoleMamaCreate(av: array of TVarEC; code: TCodeEC);
var Angle, Scale: Single; Hole: THole; I: Integer; Film: TEFilmObj;
begin
  Hole := THole.Create;
  Hole.InitializeGraphic;
  Hole.Graphic.SetState(1);
  Hole.Star1 := KlingMotherShip.CurrentStar;
  Hole.Position1.X := KlingMotherShip.Position.X - Player.Position.X;
  Hole.Position1.Y := KlingMotherShip.Position.Y - Player.Position.Y;
  Scale := 1 / Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
  Hole.Position2.X := Hole.Position1.X * Scale;
  Hole.Position2.Y := Hole.Position1.Y * Scale;
  Hole.Position1.X := KlingMotherShip.Position.X + Hole.Position2.X * 200;
  Hole.Position1.Y := KlingMotherShip.Position.Y + Hole.Position2.Y * 200;
  Scale := Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
  if Scale < KlingMotherShip.CurrentStar.SafeRadius then
  begin
    Hole.Position1.X := KlingMotherShip.Position.X - Hole.Position2.Y * 200;
    Hole.Position1.Y := KlingMotherShip.Position.Y + Hole.Position2.X * 200;
    Scale := Sqrt(Sqr(Hole.Position1.X) + Sqr(Hole.Position1.Y));
    if Scale < KlingMotherShip.CurrentStar.SafeRadius then
    begin
      Hole.Position1.X := KlingMotherShip.Position.X + Hole.Position2.Y * 200;
      Hole.Position1.Y := KlingMotherShip.Position.Y - Hole.Position2.X * 200;
    end;
  end;
  Hole.Star2 := nil;
  Angle := 1E20;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Scale := PointDistanceSquared(KlingMotherShip.CurrentStar.Position, TStar(Galaxy.Stars[I]).Position);
    if (Scale > 5) and (Scale < Angle) then
    begin
      Angle := Scale;
      Hole.Star2 := TStar(Galaxy.Stars[I]);
    end;
  end;
  Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 359, Galaxy.RandomState));
  Scale := SeededRandomIntRange(1000, 2000, Galaxy.RandomState);
  Hole.Position2 := MakePointF(Sin(Angle) * Scale, -Cos(Angle) * Scale);
  Hole.CreatedTurn := Galaxy.CurrentTurn;
  Hole.HoleType := bhkMachpella;
  Galaxy.Holes.Add(Hole);
  if StarPreparationFlag then
  begin
    Film := PrimaryFilm.AddObject(Hole.Id, Hole.Graphic, 0, 0);
    PrimaryFilm.SetObjectPosition(0, Film, Hole.Position1);
    PrimaryFilm.SetHoleState(0, Film, 1);
    PrimaryFilm.AttachObject(0, Film);
  end;
end;
{ @end $532A4C }

{ @routine $532D84 SF_HoleCreate }
procedure SF_HoleCreate(av: array of TVarEC; code: TCodeEC);
var Hole: THole; Angle: Single; Place: TScriptPlace;
begin
  if High(av) <> 2 then raise Exception.Create('Error.Script HoleCreate');
  Hole := THole.Create;
  Hole.InitializeGraphic;
  Hole.Graphic.SetState(1);
  Hole.CreatedTurn := Galaxy.CurrentTurn;
  Hole.HoleType := bhkOrdinary;
  Place := TScriptPlace(av[1].GetDword);
  if (Place.PlaceKind <> spkPolar) and (Place.PlaceKind <> spkPlanetPosition) and (Place.PlaceKind <> spkStarDirection) and
    (Place.PlaceKind <> spkGroupCentroid) then RaiseWideMessage('Error.Script HoleCreate place 1');
  Hole.Star1 := Place.OriginStar;
  Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 359, Hole.Id * Hole.Star1.GenerationSeed));
  Hole.Position1 := Place.GetPoint;
  Hole.Position1.X := Sin(Angle) * Place.Radius + Hole.Position1.X;
  Hole.Position1.Y := Hole.Position1.Y - Cos(Angle) * Place.Radius;
  Place := TScriptPlace(av[2].GetDword);
  // Both native error strings say "place 1".
  if (Place.PlaceKind <> spkPolar) and (Place.PlaceKind <> spkPlanetPosition) and (Place.PlaceKind <> spkStarDirection) and
    (Place.PlaceKind <> spkGroupCentroid) then RaiseWideMessage('Error.Script HoleCreate place 1');
  Hole.Star2 := Place.OriginStar;
  Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 359, Hole.Id * Hole.Star2.GenerationSeed));
  Hole.Position2 := Place.GetPoint;
  Hole.Position2.X := Sin(Angle) * Place.Radius + Hole.Position2.X;
  Hole.Position2.Y := Hole.Position2.Y - Cos(Angle) * Place.Radius;
  Galaxy.Holes.Add(Hole);
end;
{ @end $532D84 }

{ @routine $532FA8 SF_SkipGreeting }
procedure SF_SkipGreeting(av: array of TVarEC; code: TCodeEC);
begin
  CurrentScript.SkipGreeting := True;
end;
{ @end $532FA8 }

{ @routine $532FD4 SF_Sound }
procedure SF_Sound(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script Sound');
  SoundManager.PlaySound(av[1].GetString);
end;
{ @end $532FD4 }

{ @routine $533074 SF_Tips }
procedure SF_Tips(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script Tips');
  ShowPlayerTipOnce(av[1].GetInt);
end;
{ @end $533074 }

{ @routine $5330D8 SF_CT }
procedure SF_CT(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script CT');
  Text := LocalizedText(av[1].GetString);
  if FindTextOffsetW(Text, '<') >= 0 then
  begin
    Text := ReplaceAllWideString(Text, '<br>', #13#10);
    if Player <> nil then Text := ReplaceAllWideString(Text, '<PlayerFull>', WrapTextInColor(Player.GetFullName(' '), HighlightColorTag));
  end;
  av[0].SetString(ReplaceAllWideString(Text, #13#10' ', #13#10));
end;
{ @end $5330D8 }

{ @routine $5332A4 SF_SFT }
procedure SF_SFT(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then raise Exception.Create('Error.Script SFT');
  AppendLogLineThreadSafe(AnsiString(av[1].GetString));
end;
{ @end $5332A4 }

{ @routine $533350 InitializeScriptBuiltinsAndConstants }
procedure InitializeScriptBuiltinsAndConstants(Scope: TVarArrayEC);
begin
  RegisterExpressionBuiltins(Scope);
  Scope.Add('GRun', vkExternFun).SetExternFun(@SF_GRun);
  Scope.Add('GCntRun', vkExternFun).SetExternFun(@SF_GCntRun);
  Scope.Add('GLastTurnRun', vkExternFun).SetExternFun(@SF_GLastTurnRun);
  Scope.Add('GAllCntRun', vkExternFun).SetExternFun(@SF_GAllCntRun);
  Scope.Add('StatusPlayer', vkExternFun).SetExternFun(@SF_StatusPlayer);
  Scope.Add('AddPlanetNews', vkExternFun).SetExternFun(@SF_AddPlanetNews);
  Scope.Add('AutoBattle', vkExternFun).SetExternFun(@SF_AutoBattle);
  Scope.Add('GetOwner', vkExternFun).SetExternFun(@SF_GetOwner);
  Scope.Add('GiveReward', vkExternFun).SetExternFun(@SF_GiveReward);
  Scope.Add('Rnd', vkExternFun).SetExternFun(@SF_Rnd);
  Scope.Add('GameDateTxtByTurn', vkExternFun).SetExternFun(@SF_GameDateTxtByTurn);
  Scope.Add('Id', vkExternFun).SetExternFun(@SF_Id);
  Scope.Add('SetName', vkExternFun).SetExternFun(@SF_SetName);
  Scope.Add('UseTranclucator', vkExternFun).SetExternFun(@SF_UseTranclucator);
  Scope.Add('HullDamage', vkExternFun).SetExternFun(@SF_HullDamage);
  Scope.Add('Hitpoints', vkExternFun).SetExternFun(@SF_Hitpoints);
  Scope.Add('Hit', vkExternFun).SetExternFun(@SF_Hit);
  Scope.Add('ChangeGlobalRelationsShips', vkExternFun).SetExternFun(@SF_ChangeGlobalRelationsShips);
  Scope.Add('ChangeGlobalRelationsPlanets', vkExternFun).SetExternFun(@SF_ChangeGlobalRelationsPlanets);
  Scope.Add('GlobalRelationsShips', vkExternFun).SetExternFun(@SF_GlobalRelationsShips);
  Scope.Add('GlobalRelationsPlanets', vkExternFun).SetExternFun(@SF_GlobalRelationsPlanets);
  Scope.Add('SetRelationGroup', vkExternFun).SetExternFun(@SF_SetRelationGroup);
  Scope.Add('SetRelationPlanet', vkExternFun).SetExternFun(@SF_SetRelationPlanet);
  Scope.Add('GetRelationPlanet', vkExternFun).SetExternFun(@SF_GetRelationPlanet);
  Scope.Add('CurTurn', vkExternFun).SetExternFun(@SF_CurTurn);
  Scope.Add('ShipType', vkExternFun).SetExternFun(@SF_ShipType);
  Scope.Add('ConName', vkExternFun).SetExternFun(@SF_ConName);
  Scope.Add('StarName', vkExternFun).SetExternFun(@SF_StarName);
  Scope.Add('PlanetName', vkExternFun).SetExternFun(@SF_PlanetName);
  Scope.Add('PlanetSetGoods', vkExternFun).SetExternFun(@SF_PlanetSetGoods);
  Scope.Add('ShipName', vkExternFun).SetExternFun(@SF_ShipName);
  Scope.Add('StarToCon', vkExternFun).SetExternFun(@SF_StarToCon);
  Scope.Add('ConNear', vkExternFun).SetExternFun(@SF_ConNear);
  Scope.Add('ConStars', vkExternFun).SetExternFun(@SF_ConStars);
  Scope.Add('ConStar', vkExternFun).SetExternFun(@SF_ConStar);
  Scope.Add('GalaxyStars', vkExternFun).SetExternFun(@SF_GalaxyStars);
  Scope.Add('GalaxyStar', vkExternFun).SetExternFun(@SF_GalaxyStar);
  Scope.Add('StarAngleBetween', vkExternFun).SetExternFun(@SF_StarAngleBetween);
  Scope.Add('FindPlanet', vkExternFun).SetExternFun(@SF_FindPlanet);
  Scope.Add('IsPlayer', vkExternFun).SetExternFun(@SF_IsPlayer);
  Scope.Add('GroupCount', vkExternFun).SetExternFun(@SF_GroupCount);
  Scope.Add('GroupIn', vkExternFun).SetExternFun(@SF_GroupIn);
  Scope.Add('CountIn', vkExternFun).SetExternFun(@SF_CountIn);
  Scope.Add('ChangeState', vkExternFun).SetExternFun(@SF_ChangeState);
  Scope.Add('NearestGroup', vkExternFun).SetExternFun(@SF_NearestGroup);
  Scope.Add('StarAngle', vkExternFun).SetExternFun(@SF_StarAngle);
  Scope.Add('NewsAdd', vkExternFun).SetExternFun(@SF_NewsAdd);
  Scope.Add('MsgAdd', vkExternFun).SetExternFun(@SF_MsgAdd);
  Scope.Add('Ether', vkExternFun).SetExternFun(@SF_Ether);
  Scope.Add('EtherState', vkExternFun).SetExternFun(@SF_EtherState);
  Scope.Add('ConChangeRelationToRanger', vkExternFun).SetExternFun(@SF_ConChangeRelationToRanger);
  Scope.Add('GetData', vkExternFun).SetExternFun(@SF_GetData);
  Scope.Add('SetData', vkExternFun).SetExternFun(@SF_SetData);
  Scope.Add('ShipData', vkExternFun).SetExternFun(@SF_ShipData);
  Scope.Add('Format', vkExternFun).SetExternFun(@SF_Format);
  Scope.Add('Dialog', vkExternFun).SetExternFun(@SF_Dialog);
  Scope.Add('DText', vkExternFun).SetExternFun(@SF_DText);
  Scope.Add('DAdd', vkExternFun).SetExternFun(@SF_DAdd);
  Scope.Add('DChange', vkExternFun).SetExternFun(@SF_DChange);
  Scope.Add('DAnswer', vkExternFun).SetExternFun(@SF_DAnswer);
  Scope.Add('Player', vkExternFun).SetExternFun(@SF_Player);
  Scope.Add('ItemExist', vkExternFun).SetExternFun(@SF_ItemExist);
  Scope.Add('ItemIn', vkExternFun).SetExternFun(@SF_ItemIn);
  Scope.Add('ItemCost', vkExternFun).SetExternFun(@SF_ItemCost);
  Scope.Add('ItemCount', vkExternFun).SetExternFun(@SF_ItemCount);
  Scope.Add('DropItem', vkExternFun).SetExternFun(@SF_DropItem);
  Scope.Add('DropScriptItem', vkExternFun).SetExternFun(@SF_DropScriptItem);
  Scope.Add('DeleteEquipment', vkExternFun).SetExternFun(@SF_DeleteEquipment);
  Scope.Add('DecayGoods', vkExternFun).SetExternFun(@SF_DecayGoods);
  Scope.Add('UpsurgeGoods', vkExternFun).SetExternFun(@SF_UpsurgeGoods);
  Scope.Add('GoodsAdd', vkExternFun).SetExternFun(@SF_GoodsAdd);
  Scope.Add('GoodsCount', vkExternFun).SetExternFun(@SF_GoodsCount);
  Scope.Add('ShipGoods', vkExternFun).SetExternFun(@SF_ShipGoods);
  Scope.Add('GoodsDrop', vkExternFun).SetExternFun(@SF_GoodsDrop);
  Scope.Add('UselessItemCreate', vkExternFun).SetExternFun(@SF_UselessItemCreate);
  Scope.Add('GoodsSellPrice', vkExternFun).SetExternFun(@SF_GoodsSellPrice);
  Scope.Add('CountTurn', vkExternFun).SetExternFun(@SF_CountTurn);
  Scope.Add('ShipSetBad', vkExternFun).SetExternFun(@SF_ShipSetBad);
  Scope.Add('GroupSetBad', vkExternFun).SetExternFun(@SF_GroupSetBad);
  Scope.Add('ShipSetPartner', vkExternFun).SetExternFun(@SF_ShipSetPartner);
  Scope.Add('ShipJoin', vkExternFun).SetExternFun(@SF_ShipJoin);
  Scope.Add('ShipOut', vkExternFun).SetExternFun(@SF_ShipOut);
  Scope.Add('ShipInScript', vkExternFun).SetExternFun(@SF_ShipInScript);
  Scope.Add('ShipInCurScript', vkExternFun).SetExternFun(@SF_ShipInCurScript);
  Scope.Add('ShipInNormalSpace', vkExternFun).SetExternFun(@SF_ShipInNormalSpace);
  Scope.Add('ShipInHole', vkExternFun).SetExternFun(@SF_ShipInHole);
  Scope.Add('ShipIsTakeoff', vkExternFun).SetExternFun(@SF_ShipIsTakeoff);
  Scope.Add('ShipCntWeapon', vkExternFun).SetExternFun(@SF_ShipCntWeapon);
  Scope.Add('ShipGroup', vkExternFun).SetExternFun(@SF_ShipGroup);
  Scope.Add('ShipSpeed', vkExternFun).SetExternFun(@SF_ShipSpeed);
  Scope.Add('ShipCanJump', vkExternFun).SetExternFun(@SF_ShipCanJump);
  Scope.Add('ShipInStar', vkExternFun).SetExternFun(@SF_ShipInStar);
  Scope.Add('ShipInPlanet', vkExternFun).SetExternFun(@SF_ShipInPlanet);
  Scope.Add('ShipStatistic', vkExternFun).SetExternFun(@SF_ShipStatistic);
  Scope.Add('ShipMoney', vkExternFun).SetExternFun(@SF_ShipMoney);
  Scope.Add('ShipFuel', vkExternFun).SetExternFun(@SF_ShipFuel);
  Scope.Add('ShipStrengthInBestRanger', vkExternFun).SetExternFun(@SF_ShipStrengthInBestRanger);
  Scope.Add('ShipStrengthInAverageRanger', vkExternFun).SetExternFun(@SF_ShipStrengthInAverageRanger);
  Scope.Add('ShipFind', vkExternFun).SetExternFun(@SF_ShipFind);
  Scope.Add('RangerStatus', vkExternFun).SetExternFun(@SF_RangerStatus);
  Scope.Add('GalaxyMoney', vkExternFun).SetExternFun(@SF_GalaxyMoney);
  Scope.Add('ShipDestroy', vkExternFun).SetExternFun(@SF_ShipDestroy);
  Scope.Add('ItemDestroy', vkExternFun).SetExternFun(@SF_ItemDestroy);
  Scope.Add('RangersCapital', vkExternFun).SetExternFun(@SF_RangersCapital);
  Scope.Add('GroupToShip', vkExternFun).SetExternFun(@SF_GroupToShip);
  Scope.Add('OrderLanding', vkExternFun).SetExternFun(@SF_OrderLanding);
  Scope.Add('OrderJump', vkExternFun).SetExternFun(@SF_OrderJump);
  Scope.Add('GroupIs', vkExternFun).SetExternFun(@SF_GroupIs);
  Scope.Add('StateIs', vkExternFun).SetExternFun(@SF_StateIs);
  Scope.Add('Dist', vkExternFun).SetExternFun(@SF_Dist);
  Scope.Add('Dist2Star', vkExternFun).SetExternFun(@SF_Dist2Star);
  Scope.Add('BuyPirate', vkExternFun).SetExternFun(@SF_BuyPirate);
  Scope.Add('BuyTransport', vkExternFun).SetExternFun(@SF_BuyTransport);
  Scope.Add('Name', vkExternFun).SetExternFun(@SF_Name);
  Scope.Add('ShortName', vkExternFun).SetExternFun(@SF_ShortName);
  Scope.Add('FirstGiveMoney', vkExternFun).SetExternFun(@SF_FirstGiveMoney);
  Scope.Add('ScenarioState', vkExternFun).SetExternFun(@SF_ScenarioState);
  Scope.Add('HaveCommunicator', vkExternFun).SetExternFun(@SF_HaveCommunicator);
  Scope.Add('HoleMamaCreate', vkExternFun).SetExternFun(@SF_HoleMamaCreate);
  Scope.Add('HoleCreate', vkExternFun).SetExternFun(@SF_HoleCreate);
  Scope.Add('SkipGreeting', vkExternFun).SetExternFun(@SF_SkipGreeting);
  Scope.Add('Sound', vkExternFun).SetExternFun(@SF_Sound);
  Scope.Add('Tips', vkExternFun).SetExternFun(@SF_Tips);
  Scope.Add('CT', vkExternFun).SetExternFun(@SF_CT);
  Scope.Add('SFT', vkExternFun).SetExternFun(@SF_SFT);
  Scope.Add('UselessItem', vkInt).SetInt(49);
  Scope.Add('ForLiberationSystem', vkInt).SetInt(0);
  Scope.Add('ForAccomplishment', vkInt).SetInt(1);
  Scope.Add('ForSecretMission', vkInt).SetInt(2);
  Scope.Add('ForCowardice', vkInt).SetInt(3);
  Scope.Add('ForPerfidy', vkInt).SetInt(4);
  Scope.Add('Maloc', vkInt).SetInt(0);
  Scope.Add('Peleng', vkInt).SetInt(1);
  Scope.Add('People', vkInt).SetInt(2);
  Scope.Add('Fei', vkInt).SetInt(3);
  Scope.Add('Gaal', vkInt).SetInt(4);
  Scope.Add('Kling', vkInt).SetInt(5);
  Scope.Add('None', vkInt).SetInt(6);
  Scope.Add('t_Food', vkInt).SetInt(0);
  Scope.Add('t_Medicine', vkInt).SetInt(1);
  Scope.Add('t_Technics', vkInt).SetInt(2);
  Scope.Add('t_Luxury', vkInt).SetInt(3);
  Scope.Add('t_Minerals', vkInt).SetInt(4);
  Scope.Add('t_Alcohol', vkInt).SetInt(5);
  Scope.Add('t_Arms', vkInt).SetInt(6);
  Scope.Add('t_Narcotics', vkInt).SetInt(7);
  Scope.Add('t_ArtefactHull', vkInt).SetInt(9);
  Scope.Add('t_ArtefactFuel', vkInt).SetInt(10);
  Scope.Add('t_ArtefactSpeed', vkInt).SetInt(11);
  Scope.Add('t_ArtefactPower', vkInt).SetInt(12);
  Scope.Add('t_ArtefactRadar', vkInt).SetInt(13);
  Scope.Add('t_ArtefactScaner', vkInt).SetInt(14);
  Scope.Add('t_ArtefactDroid', vkInt).SetInt(15);
  Scope.Add('t_ArtefactNano', vkInt).SetInt(16);
  Scope.Add('t_ArtefactHook', vkInt).SetInt(17);
  Scope.Add('t_ArtefactDef', vkInt).SetInt(18);
  Scope.Add('t_ArtefactAnalyzer', vkInt).SetInt(19);
  Scope.Add('t_ArtefactMiniExpl', vkInt).SetInt(20);
  Scope.Add('t_ArtefactAntigrav', vkInt).SetInt(21);
  Scope.Add('t_ArtefactTransmitter', vkInt).SetInt(22);
  Scope.Add('t_ArtefactBomb', vkInt).SetInt(23);
  Scope.Add('t_ArtefactTranclucator', vkInt).SetInt(24);
  Scope.Add('t_Hull', vkInt).SetInt(25);
  Scope.Add('t_FuelTanks', vkInt).SetInt(26);
  Scope.Add('t_Engine', vkInt).SetInt(27);
  Scope.Add('t_Radar', vkInt).SetInt(28);
  Scope.Add('t_Scaner', vkInt).SetInt(29);
  Scope.Add('t_RepairRobot', vkInt).SetInt(30);
  Scope.Add('t_CargoHook', vkInt).SetInt(31);
  Scope.Add('t_DefGenerator', vkInt).SetInt(32);
  Scope.Add('t_Weapon1', vkInt).SetInt(33);
  Scope.Add('t_Weapon2', vkInt).SetInt(34);
  Scope.Add('t_Weapon3', vkInt).SetInt(35);
  Scope.Add('t_Weapon4', vkInt).SetInt(36);
  Scope.Add('t_Weapon5', vkInt).SetInt(37);
  Scope.Add('t_Weapon6', vkInt).SetInt(38);
  Scope.Add('t_Weapon7', vkInt).SetInt(39);
  Scope.Add('t_Weapon8', vkInt).SetInt(40);
  Scope.Add('t_Weapon9', vkInt).SetInt(41);
  Scope.Add('t_Weapon10', vkInt).SetInt(42);
  Scope.Add('t_Weapon11', vkInt).SetInt(43);
  Scope.Add('t_Weapon12', vkInt).SetInt(44);
  Scope.Add('t_Weapon13', vkInt).SetInt(45);
  Scope.Add('t_Weapon14', vkInt).SetInt(46);
  Scope.Add('t_Weapon15', vkInt).SetInt(47);
  Scope.Add('t_Protoplasm', vkInt).SetInt(48);
  Scope.Add('t_UselessItem', vkInt).SetInt(49);
  Scope.Add('ReWar', vkInt).SetInt(0);
  Scope.Add('ReBad', vkInt).SetInt(1);
  Scope.Add('ReNormal', vkInt).SetInt(2);
  Scope.Add('ReGood', vkInt).SetInt(3);
  Scope.Add('ReBest', vkInt).SetInt(4);
  Scope.Add('Trader', vkInt).SetInt(0);
  Scope.Add('Pirate', vkInt).SetInt(1);
  Scope.Add('Warrior', vkInt).SetInt(2);
  Scope.Add('t_Kling', vkInt).SetInt(0);
  Scope.Add('t_Ranger', vkInt).SetInt(1);
  Scope.Add('t_Transport', vkInt).SetInt(2);
  Scope.Add('t_Pirate', vkInt).SetInt(3);
  Scope.Add('t_Warrior', vkInt).SetInt(4);
  Scope.Add('t_Tranclucator', vkInt).SetInt(5);
  Scope.Add('t_RC', vkInt).SetInt(6);
  Scope.Add('t_PB', vkInt).SetInt(7);
  Scope.Add('t_WB', vkInt).SetInt(8);
  Scope.Add('t_SB', vkInt).SetInt(9);
end;
{ @end $533350 }

end.

unit CheatCode;
// Unit bracket (inferred): CODE 0x005E2B90..0x005E4FE3; inclusive evidence, not full bounds.
// Every command pays a turn cooldown.
interface

function TryUseCheat(Points: Integer; const Name: WideString): Boolean; // @addr $5E2B90
procedure CheatRepair; // @addr $5E2F3C
procedure CheatKlissanmax; // @addr $5E307C
procedure CheatKlissancall; // @addr $5E3138
procedure CheatRangerpoints; // @addr $5E3248
procedure CheatNextrank; // @addr $5E32E0
procedure CheatCoolweapon; // @addr $5E3380
procedure CheatLowcostweapon; // @addr $5E34C4
procedure CheatBomb; // @addr $5E3640
procedure CheatArtefact; // @addr $5E3748
procedure CheatMoney; // @addr $5E3B84
procedure CheatDrop; // @addr $5E3CD0
procedure CheatPacking; // @addr $5E3E2C
procedure CheatKlissanitem; // @addr $5E3F0C
procedure CheatWeaponstrength; // @addr $5E4098
procedure CheatTenbomb; // @addr $5E4344
procedure CheatRndbase; // @addr $5E4498
procedure CheatMapsector; // @addr $5E46B4
procedure CheatHugemoney; // @addr $5E4790
procedure CheatPelengsurprise; // @addr $5E48DC
procedure CheatSuperhull; // @addr $5E49F0
procedure CheatBoom; // @addr $5E4AC0
procedure CheatHaterangers; // @addr $5E4B70
procedure CheatPirates; // @addr $5E4C44
procedure HandleDebugKey(Key: Word); // @addr $5E4D44

var
  CheatCodes: array[0..22] of WideString = (
    'REPAIR', 'KLISSANMAX', 'KLISSANCALL', 'RANGERPOINTS', 'NEXTRANK',
    'COOLWEAPON', 'LOWCOSTWEAPON', 'BOMB', 'ARTEFACT', 'MONEY', 'DROP',
    'PACKING', 'KLISSANITEM', 'WEAPONSTRENGTH', '10BOMB', 'RNDBASE',
    'OPENMAPSECTOR', 'HUGEMONEY', 'PELENGSURPRISE', 'SUPERHULL', 'BOOM',
    'HATERANGERS', 'PIRATES'); // @addr $618900
  CheatCandidateIndex: Integer = 0; // @addr $61895C
  CheatPrefixLength: Integer = 0; // @addr $618960

implementation
// @unit-initialization $5E4FD0
// @unit-finalization $5E4ECC
uses SysUtils, Math, Classes, EC_Struct, aMyFunction, aConst, aGalaxy, aPlanet,
  aShip, aPlayer, aRanger, aKling, aItem, aRuins, aRuinsRC, aRuinsPB, aRuinsWB,
  aRuinsSB, Globals, GlobalsV, GR_Main, GI_MessageLoop, GI_MessageBox,
  fStarMap, fRuinsTalk, fEquipmentShop, fPlanet, fPlanetNO, fGoodsShop, fInfo,
  fPanelMain, SE_Process, ab_Global, ab_Ship;

{ @routine $5E2B90 TryUseCheat }
function TryUseCheat(Points: Integer; const Name: WideString): Boolean;
var
  Text: WideString;
begin
  if Galaxy = nil then
  begin
    Result := False;
    Exit;
  end;
  Text := LocalizedColorText('Cheat.Info');
  ReplaceTextToken(Text, '<Name>', Name, HighlightColorTag);
  ReplaceTextToken(Text, '<CheatPoints>', IntToStr(Points), HighlightColorTag);
  if Points > Galaxy.CurrentTurn - Galaxy.LastCheatTurn then
  begin
    Text := Text + #13#10 + LocalizedColorText('Cheat.DayWait');
    ReplaceTextToken(Text, '<CurPoints>',
      IntToStr(Galaxy.CurrentTurn - Galaxy.LastCheatTurn), HighlightColorTag);
    ReplaceTextToken(Text, '<Day>',
      IntToStr(Points - (Galaxy.CurrentTurn - Galaxy.LastCheatTurn)), HighlightColorTag);
    ShowMessageBoxGI(RegisteredScreens[CurrentScreenId] as TMessageLoopGI, Text, mbgCancel);
    (RegisteredScreens[CurrentScreenId] as TMessageLoopGI).Present;
    Result := False;
    Exit;
  end;
  begin
    Inc(Galaxy.TotalCheatPoints, Points);
    Galaxy.LastCheatTurn := Galaxy.CurrentTurn;
    Text := Text + #13#10 + LocalizedColorText('Cheat.Ok');
    ReplaceTextToken(Text, '<AllPoints>', IntToStr(Galaxy.TotalCheatPoints), HighlightColorTag);
    ShowMessageBoxGI(RegisteredScreens[CurrentScreenId] as TMessageLoopGI, Text, mbgCancel);
    (RegisteredScreens[CurrentScreenId] as TMessageLoopGI).Present;
    Result := True;
  end;
end;
{ @end $5E2B90 }

{ @routine $5E2F3C CheatRepair }
procedure CheatRepair;
var I: Integer; Item: TEquipment;
begin
  if (Galaxy = nil) or (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) or
    (Player = nil) or not Player.InNormalSpace or
    (PointDistance(Player.Position, MakePointF(0, 0)) > Player.CurrentStar.DamageRadius) then Exit;
  if not TryUseCheat(40, 'Repair') then Exit;
  for I := 0 to Player.Inventory.Count - 1 do begin
    Item := TEquipment(Player.Inventory[I]);
    if (Item.ItemType = t_Hull) or (Item.EquippedFlag and (Item.ConditionPercent < 90)) then Item.Repair;
  end;
  for I := 0 to Player.Artefacts.Count - 1 do begin
    Item := TEquipment(Player.Artefacts[I]);
    if Item.EquippedFlag and (Item.ConditionPercent < 90) then Item.Repair;
  end;
end;
{ @end $5E2F3C }

{ @routine $5E307C CheatKlissanmax }
procedure CheatKlissanmax;
var I, PlanetIndex: Integer; Star: TStar; Planet: TPlanet;
begin
  if (Galaxy = nil) or (Player = nil) then Exit;
  if not TryUseCheat(20, 'KlissanMax') then Exit;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := TStar(Galaxy.Stars[I]);
    if Star.ControlFaction = sfKlissan then begin
      PlanetIndex := -1;
      while True do begin
        if Star.ShipTypeCounts[t_Kling] >= 12 then Break;
        Planet := nil;
        case Integer(Planet) of 0: ; end;
        repeat
          Inc(PlanetIndex);
          if PlanetIndex >= Star.Planets.Count then PlanetIndex := 0;
          Planet := TPlanet(Star.Planets[PlanetIndex]);
        until Planet.OwnerId <> oiNone;
        Planet.SpawnWeightedKlissan;
      end;
    end;
  end;
end;
{ @end $5E307C }

{ @routine $5E3138 CheatKlissancall }
procedure CheatKlissancall;
var I, J, Sent: Integer; Star: TStar; Ship: TShip;
begin
  if (Galaxy = nil) or (Player = nil) then Exit;
  if not TryUseCheat(20, 'KlissanCall') then Exit;
  Sent := 0;
  for I := 1 to Galaxy.Stars.Count - 1 do begin
    Star := Player.CurrentStar.StarDistances[I].Star as TStar;
    if (Star.ControlFaction <> sfKlissan) or Star.Battle or IsFinalScenarioActive then Continue;
    for J := 0 to Star.Ships.Count - 3 do begin
      Ship := TShip(Star.Ships[J]);
      if (Ship.OwnerId = oiKling) and (Ship.Order = soNone) then begin
        Ship.OrderJump(Player.CurrentStar, True);
        Inc(Sent);
      end;
    end;
    if Sent > 20 then Break;
  end;
end;
{ @end $5E3138 }

{ @routine $5E3248 CheatRangerpoints }
procedure CheatRangerpoints;
begin
  if (Galaxy = nil) or (CurrentScreenId = screenShip) or (Player = nil) or
    not Player.IsDockedToShip or (Player.DockedTo.ShipType <> t_RangerCenter) or (Player.FreeExperience >= 1000) then Exit;
  if not TryUseCheat(150, 'RangerPoints') then Exit;
  Player.GainExperience(1000);
end;
{ @end $5E3248 }

{ @routine $5E32E0 CheatNextrank }
procedure CheatNextrank;
begin
  if (Galaxy = nil) or (CurrentScreenId = screenShip) or (Player = nil) or
    not Player.IsDockedToShip or (Player.DockedTo.ShipType <> t_MilitaryBase) or (Player.Rank = crCommander) then Exit;
  if not TryUseCheat(90, 'NextRank') then Exit;
  Inc(Player.RankPoints, Player.GetRankPointsToNextRank);
  if CurrentScreenId = screenRuinsTalk then begin
    RuinsTalkScreen.ShowGreeting;
    RuinsTalkScreen.RestartTextPresentation;
  end;
end;
{ @end $5E32E0 }

{ @routine $5E3380 CheatCoolweapon }
procedure CheatCoolweapon;
var Item: TItem;
begin
  if (Galaxy = nil) or (CurrentScreenId = screenShip) or (Player = nil) or not Player.IsOnPlanet then Exit;
  if not TryUseCheat(100, 'CoolWeapon') then Exit;
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  Item := TWeapon.Create;
  Player.CurrentPlanet.EquipmentShop.Add(Item);
  (Item as TWeapon).Init(TItemType(RandomIntRange(Ord(t_SubmesonicGun), Ord(t_VortexProjector))), False, RandomIntRange(50, 100),
    RandomIntRange(4, 8), RaceToOwner(Player.CurrentPlanet.RaceId));
  (Item as TWeapon).Improve(ikAny);
  BuildTemporaryShopSlotGrid;
  if CurrentScreenId = screenEquipmentShop then begin
    EquipmentShopScreen.BuildGoodsControls;
    EquipmentShopScreen.UpdateScrollButtons;
  end;
end;
{ @end $5E3380 }

{ @routine $5E34C4 CheatLowcostweapon }
procedure CheatLowcostweapon;
var Item: TItem;
begin
  if (Galaxy = nil) or (CurrentScreenId = screenShip) or (Player = nil) or not Player.IsOnPlanet then Exit;
  if not TryUseCheat(20, 'LowCostWeapon') then Exit;
  RestoreTemporaryShopStock;
  ClearTemporaryShopSlots;
  Item := TWeapon.Create;
  Player.CurrentPlanet.EquipmentShop.Add(Item);
  (Item as TWeapon).Init(TItemType(RandomIntRange(Ord(t_PhotonGun), Ord(t_VortexProjector))), False, RandomIntRange(14, 200),
    RandomIntRange(1, 8), RaceToOwner(Player.CurrentPlanet.RaceId));
  (Item as TWeapon).Cost := RandomIntRange(1, 10);
  if (Item as TWeapon).Weight > 100 then (Item as TWeapon).Improve(ikMajor);
  BuildTemporaryShopSlotGrid;
  if CurrentScreenId = screenEquipmentShop then begin
    EquipmentShopScreen.BuildGoodsControls;
    EquipmentShopScreen.UpdateScrollButtons;
  end;
end;
{ @end $5E34C4 }

{ @routine $5E3640 CheatBomb }
procedure CheatBomb;
var Item: TItem;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  if not TryUseCheat(60, 'Bomb') then Exit;
  Item := TArtefactBomb.Create;
  (Item as TArtefactBomb).Init(Player.HomePlanet.OwnerId);
  Player.Artefacts.Add(Item);
  Item := TArtefactBomb.Create;
  (Item as TArtefactBomb).Init(Player.HomePlanet.OwnerId);
  Player.Artefacts.Add(Item);
  Player.RefreshDerivedStats;
  StarMapScreen.PanelController.RefreshMoneyAndCargo;
end;
{ @end $5E3640 }

{ @routine $5E3748 CheatArtefact }
procedure CheatArtefact;
var Item: TItem;
begin
  if (Galaxy = nil) or (Player = nil) or (CurrentScreenId <> screenArcadeBattle) then Exit;
  if not TryUseCheat(40, 'Artefact') then Exit;
  Item := nil;
  case RandomIntRange(0, 15) of
    0: begin
      Item := TArtefactHull.Create;
      (Item as TArtefactHull).Init(Player.HomePlanet.OwnerId);
    end;
    1: begin
      Item := TArtefactFuel.Create;
      (Item as TArtefactFuel).Init(Player.HomePlanet.OwnerId);
    end;
    2: begin
      Item := TArtefactSpeed.Create;
      (Item as TArtefactSpeed).Init(Player.HomePlanet.OwnerId);
    end;
    3: begin
      Item := TArtefactPower.Create;
      (Item as TArtefactPower).Init(Player.HomePlanet.OwnerId);
    end;
    4: begin
      Item := TArtefactRadar.Create;
      (Item as TArtefactRadar).Init(Player.HomePlanet.OwnerId);
    end;
    5: begin
      Item := TArtefactScaner.Create;
      (Item as TArtefactScaner).Init(Player.HomePlanet.OwnerId);
    end;
    6: begin
      Item := TArtefactDroid.Create;
      (Item as TArtefactDroid).Init(Player.HomePlanet.OwnerId);
    end;
    7: begin
      Item := TArtefactNano.Create;
      (Item as TArtefactNano).Init(Player.HomePlanet.OwnerId);
    end;
    8: begin
      Item := TArtefactHook.Create;
      (Item as TArtefactHook).Init(Player.HomePlanet.OwnerId);
    end;
    9: begin
      Item := TArtefactDef.Create;
      (Item as TArtefactDef).Init(Player.HomePlanet.OwnerId);
    end;
    10: begin
      Item := TArtefactAnalyzer.Create;
      (Item as TArtefactAnalyzer).Init(Player.HomePlanet.OwnerId);
    end;
    11: begin
      Item := TArtefactMiniExpl.Create;
      (Item as TArtefactMiniExpl).Init(Player.HomePlanet.OwnerId);
    end;
    12: begin
      Item := TArtefactAntigrav.Create;
      (Item as TArtefactAntigrav).Init(Player.HomePlanet.OwnerId);
    end;
    13: begin
      Item := TArtefactTransmitter.Create;
      (Item as TArtefactTransmitter).Init(Player.HomePlanet.OwnerId);
    end;
    14: begin
      Item := TArtefactBomb.Create;
      (Item as TArtefactBomb).Init(Player.HomePlanet.OwnerId);
    end;
    15: begin
      Item := TArtefactTranclucator.Create;
      (Item as TArtefactTranclucator).Init(Player.HomePlanet.OwnerId, Player, nil);
    end;
  end;
  Player.Artefacts.Add(Item);
  Player.RefreshDerivedStats;
end;
{ @end $5E3748 }

{ @routine $5E3B84 CheatMoney }
procedure CheatMoney;
begin
  if (Galaxy = nil) or (Player = nil) or (Player.Money >= 10000) then Exit;
  if not ((Player.InNormalSpace and (CurrentScreenId = screenStarMap) and (StarMapScreen.Mode = 1)) or
    (CurrentScreenId = screenPlanet) or (CurrentScreenId = screenPlanetNO) or (CurrentScreenId = screenGoodsShop) or (CurrentScreenId = screenEquipmentShop)) then Exit;
  if not TryUseCheat(40, 'Money') then Exit;
  Player.SetMoney(Player.Money + 10000);
  if CurrentScreenId = screenStarMap then StarMapScreen.PanelController.RefreshMoneyAndCargo
  else if CurrentScreenId = screenPlanet then PlanetScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenPlanetNO then UninhabitedPlanetScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenGoodsShop then begin
    GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
    GoodsShopScreen.RefreshGoodsDisplay;
    GoodsShopScreen.ResetTradeSelection;
  end else if CurrentScreenId = screenEquipmentShop then EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo;
end;
{ @end $5E3B84 }

{ @routine $5E3CD0 CheatDrop }
procedure CheatDrop;
var I: Integer; Ship, Nearest: TShip; Item: TEquipment; Distance, NearestDistance: Single;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  NearestDistance := 1.0e30;
  Nearest := nil;
  for I := 0 to Player.CurrentStar.Ships.Count - 1 do begin
    Ship := TShip(Player.CurrentStar.Ships[I]);
    if (Ship <> Player) and (Ship <> KlingMotherShip) and (Ship.ShipType in [t_Kling..t_Warrior]) then begin
      Distance := PointDistanceSquared(Ship.Position, Player.Position);
      if Distance < NearestDistance then begin
        NearestDistance := Distance;
        Nearest := Ship;
      end;
    end;
  end;
  if Nearest = nil then Exit;
  Ship := Nearest;
  if not TryUseCheat(60, 'Drop') then Exit;
  for I := Ship.Inventory.Count - 1 downto 0 do begin
    Item := TEquipment(Ship.Inventory[I]);
    if (Item.ItemType <> t_Hull) and ((Item.ItemType <> t_Engine) or not Item.EquippedFlag) and
      ((Item.ItemType <> t_FuelTanks) or not Item.EquippedFlag) then Ship.DropCarriedItemAsMovingLoot(Item);
  end;
  Ship.RefreshDerivedStats;
end;
{ @end $5E3CD0 }

{ @routine $5E3E2C CheatPacking }
procedure CheatPacking;
var I: Integer; Item: TItem;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  if not TryUseCheat(300, 'Paking') then Exit;
  // The native loop starts at one and the displayed name is misspelled.
  for I := 1 to Player.Inventory.Count - 1 do begin
    Item := TItem(Player.Inventory[I]);
    if Item.ItemType <> t_Hull then Item.Weight := Max(1, Item.Weight div 2);
  end;
  Player.RefreshDerivedStats;
  StarMapScreen.PanelController.RefreshMoneyAndCargo;
end;
{ @end $5E3E2C }

{ @routine $5E3F0C CheatKlissanitem }
procedure CheatKlissanitem;
var Item: TItem;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsDockedToShip or
    (CurrentScreenId = screenShip) or (Player.DockedTo.ShipType <> t_ScientificBase) then Exit;
  if not TryUseCheat(160, 'KlissanItem') then Exit;
  Item := TWeapon.Create;
  Player.Inventory.Add(Item);
  (Item as TWeapon).Init(TItemType(RandomIntRange(Ord(t_AbsoluteMatrix), Ord(t_EyesOfMachpella))), False, RandomIntRange(77, 200), RandomIntRange(1, 8), oiKling);
  Player.RefreshDerivedStats;
  // Native refreshes the star-map panel for the station screen.
  if CurrentScreenId = screenRuinsTalk then StarMapScreen.PanelController.RefreshMoneyAndCargo
  else if CurrentScreenId = screenGoodsShop then begin
    GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
    GoodsShopScreen.RefreshGoodsDisplay;
    GoodsShopScreen.ResetTradeSelection;
  end else if CurrentScreenId = screenEquipmentShop then EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenInfo then InfoScreen.MainPanel.RefreshMoneyAndCargo;
end;
{ @end $5E3F0C }

{ @routine $5E4098 CheatWeaponstrength }
procedure CheatWeaponstrength;
var I, J, W: Integer; Star: TStar; Ship: TShip;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsDockedToShip or
    (CurrentScreenId = screenShip) or (Player.DockedTo.ShipType <> t_PirateBase) then Exit;
  if not TryUseCheat(200, 'WeaponStrength') then Exit;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := TStar(Galaxy.Stars[I]);
    for J := 0 to Star.Ships.Count - 1 do begin
      Ship := TShip(Star.Ships[J]);
      if (Ship.ShipType <> t_Kling) and not (Ship.ShipType in [t_Tranclucator..t_ScientificBase]) then begin
        if not ((Ship.ShipType = t_Pirate) or (Ship = Player) or
          ((Ship.ShipType = t_Ranger) and ((Ship as TRanger).PreferredCareer = rcPirate))) then begin
          if Ship.PartnerShip <> Player then Ship.ChangeRelationToRanger(Player, -60);
        end else begin
          for W := 1 to Ship.WeaponCount do begin
            Ship.Weapons[W - 1].MaxDamage := Min(255, Ship.Weapons[W - 1].MaxDamage + RandomIntRange(10, 20));
            if Ship <> Player then Ship.ChangeRelationToRanger(Player, 50);
          end;
          Ship.RefreshDerivedStats;
        end;
      end;
    end;
  end;
  Player.CareerStatus[rcPirate] := 100;
  Player.ChangePlanetRelations(nil, rcmDecrease, 60, [oiMaloc, oiPeople, oiFei, oiGaal]);
  // Native refreshes the star-map panel for the station screen.
  if CurrentScreenId = screenRuinsTalk then StarMapScreen.PanelController.RefreshMoneyAndCargo
  else if CurrentScreenId = screenGoodsShop then begin
    GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
    GoodsShopScreen.RefreshGoodsDisplay;
    GoodsShopScreen.ResetTradeSelection;
  end else if CurrentScreenId = screenEquipmentShop then EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenInfo then InfoScreen.MainPanel.RefreshMoneyAndCargo;
end;
{ @end $5E4098 }

{ @routine $5E4344 CheatTenbomb }
procedure CheatTenbomb;
var I: Integer; Item: TItem; Radius, Angle: Single;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  if not TryUseCheat(140, '10Bomb') then Exit;
  for I := 1 to 10 do begin
    Item := TArtefactBomb.Create;
    (Item as TArtefactBomb).Init(Player.HomePlanet.OwnerId);
    Radius := RandomIntRange(300, 700);
    Angle := HeadingDegreesToRadians(RandomIntRange(0, 360));
    Item.Position.X := Player.Position.X + Sin(Angle) * Radius;
    Item.Position.Y := Player.Position.Y - Cos(Angle) * Radius;
    Player.CurrentStar.Items.Add(Item);
    Item.GetGraphObject.AttachToSpace(SpaceProcess.Space);
    Item.DestroyFlag := 2;
  end;
end;
{ @end $5E4344 }

{ @routine $5E4498 CheatRndbase }
procedure CheatRndbase;
var I: Integer; Ship: TShip; Station: TRuins; Kinds: TShipTypeMask;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsOnPlanet then Exit;
  Kinds := [t_RangerCenter..t_ScientificBase];
  for I := 0 to Player.CurrentStar.Ships.Count - 1 do begin
    Ship := TShip(Player.CurrentStar.Ships[I]);
    if Ship is TRuins then Exclude(Kinds, Ship.ShipType);
  end;
  I := 0;
  if not (t_RangerCenter in Kinds) then Inc(I);
  if not (t_PirateBase in Kinds) then Inc(I);
  if not (t_MilitaryBase in Kinds) then Inc(I);
  if not (t_ScientificBase in Kinds) then Inc(I);
  if I >= 3 then Exit;
  if not TryUseCheat(30, 'RndBase') then Exit;
  I := RandomIntRange(0, 3 - I);
  // Native decrements every nonzero choice, even for an unavailable station type.
  if I <> 0 then Dec(I)
  else if t_RangerCenter in Kinds then begin
    Station := TRC.Create;
    (Station as TRC).Init(Player.CurrentStar);
    Exit;
  end;
  if I <> 0 then Dec(I)
  else if t_PirateBase in Kinds then begin
    Station := TPB.Create;
    (Station as TPB).Init(Player.CurrentStar);
    Exit;
  end;
  if I <> 0 then Dec(I)
  else if t_MilitaryBase in Kinds then begin
    Station := TWB.Create;
    (Station as TWB).Init(Player.CurrentStar);
    Exit;
  end;
  if I <> 0 then Dec(I)
  else if t_ScientificBase in Kinds then begin
    Station := TSB.Create;
    (Station as TSB).Init(Player.CurrentStar);
    Exit;
  end;
end;
{ @end $5E4498 }

{ @routine $5E46B4 CheatMapsector }
procedure CheatMapsector;
var I: Integer; Constellation: TConstellation;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsDockedToShip or
    (CurrentScreenId = screenShip) or (Player.DockedTo.ShipType <> t_PirateBase) then Exit;
  I := 0;
  // Native first looks for a visible sector, then selects an invisible one.
  // This can loop indefinitely when all sectors are already visible.
  while I < Galaxy.Constellations.Count do begin
    if TConstellation(Galaxy.Constellations[I]).Visible then Break;
    Inc(I);
  end;
  if I >= Galaxy.Constellations.Count then Exit;
  if not TryUseCheat(20, 'OpenMapSector') then Exit;
  repeat
    Constellation := TConstellation(Galaxy.Constellations[RandomIntRange(0, Galaxy.Constellations.Count - 1)]);
  until not Constellation.Visible;
  Constellation.Visible := True;
end;
{ @end $5E46B4 }

{ @routine $5E4790 CheatHugemoney }
procedure CheatHugemoney;
begin
  if (Galaxy = nil) or (Player = nil) or (Player.Money >= 1000000) then Exit;
  if not ((Player.InNormalSpace and (CurrentScreenId = screenStarMap) and (StarMapScreen.Mode = 1)) or
    (CurrentScreenId = screenPlanet) or (CurrentScreenId = screenPlanetNO) or (CurrentScreenId = screenGoodsShop) or (CurrentScreenId = screenEquipmentShop)) then Exit;
  if not TryUseCheat(300, 'HugeMoney') then Exit;
  // Native sets 100,000 despite accepting any balance below 1,000,000.
  Player.SetMoney(100000);
  if CurrentScreenId = screenStarMap then StarMapScreen.PanelController.RefreshMoneyAndCargo
  else if CurrentScreenId = screenPlanet then PlanetScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenPlanetNO then UninhabitedPlanetScreen.MainPanel.RefreshMoneyAndCargo
  else if CurrentScreenId = screenGoodsShop then begin
    GoodsShopScreen.MainPanel.RefreshMoneyAndCargo;
    GoodsShopScreen.RefreshGoodsDisplay;
    GoodsShopScreen.ResetTradeSelection;
  end else if CurrentScreenId = screenEquipmentShop then EquipmentShopScreen.MainPanel.RefreshMoneyAndCargo;
end;
{ @end $5E4790 }

{ @routine $5E48DC CheatPelengsurprise }
procedure CheatPelengsurprise;
var I: Integer; Item: TItem;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsOnPlanet or
    (Player.CurrentPlanet.OwnerId <> oiPeleng) or (CurrentScreenId = screenShip) then Exit;
  if not TryUseCheat(100, 'PelengSurprise') then Exit;
  for I := 0 to TemporaryShopSlots.Count - 1 do begin
    Item := TShopSlot(TemporaryShopSlots[I]).Item;
    if (Item <> nil) and (Item is TWeapon) then (Item as TWeapon).Range := 2 * (Item as TWeapon).Range;
  end;
  Player.ChangePlanetRelations(nil, rcmDecrease, 50, [oiMaloc, oiPeople, oiFei, oiGaal]);
end;
{ @end $5E48DC }

{ @routine $5E49F0 CheatSuperhull }
procedure CheatSuperhull;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  if not TryUseCheat(250, 'SuperHull') then Exit;
  Player.Hull.Weight := Min(2000, Round(Player.Hull.Weight * 1.3));
  Player.Hull.HullPoints := Player.Hull.Weight;
  Player.RefreshDerivedStats;
  StarMapScreen.PanelController.RefreshMoneyAndCargo;
end;
{ @end $5E49F0 }

{ @routine $5E4AC0 CheatBoom }
procedure CheatBoom;
var I: Integer;
begin
  if (Galaxy = nil) or (Player = nil) or (CurrentScreenId <> screenArcadeBattle) or
    (ArcadeViewMode <> avmSpace) or (BossArcadeShip <> nil) then Exit;
  if not TryUseCheat(30, 'Boom') then Exit;
  for I := 0 to PlayerArcadeShip.Enemies.Count - 1 do
    TabShip(PlayerArcadeShip.Enemies[I]).ApplyDamage(TabShip(PlayerArcadeShip.Enemies[I]).Health, nil, False);
end;
{ @end $5E4AC0 }

{ @routine $5E4B70 CheatHaterangers }
procedure CheatHaterangers;
var I: Integer; Ranger: TObject;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.InNormalSpace or
    (CurrentScreenId <> screenStarMap) or (StarMapScreen.Mode <> 1) then Exit;
  if not TryUseCheat(10, 'HateRangers') then Exit;
  for I := 0 to Galaxy.Rangers.Count - 1 do begin
    Ranger := TObject(Galaxy.Rangers[I]);
    (Ranger as TRanger).ChangeShipRelations(nil, rcmDecrease, 80, [htPirate..htDiplomat], [oiMaloc..oiNone]);
  end;
end;
{ @end $5E4B70 }

{ @routine $5E4C44 CheatPirates }
procedure CheatPirates;
var I, Attempts: Integer; Star: TStar; Planet: TPlanet;
begin
  if (Galaxy = nil) or (Player = nil) or not Player.IsDockedToShip or
    (CurrentScreenId = screenShip) or (Player.DockedTo.ShipType <> t_PirateBase) then Exit;
  if not TryUseCheat(100, 'Pirates') then Exit;
  for I := 0 to Galaxy.Stars.Count - 1 do begin
    Star := TStar(Galaxy.Stars[I]);
    if Star.ControlFaction = sfKlissan then Continue;
    for Attempts := 1 to 6 do begin
      Planet := TPlanet(Star.Planets[RandomIntRange(0, Star.Planets.Count - 1)]);
      if Planet.OwnerId in CoalitionOwners then begin
        Planet.SpawnPirate;
        Break;
      end;
    end;
  end;
end;
{ @end $5E4C44 }

{ @routine $5E4D44 HandleDebugKey }
procedure HandleDebugKey(Key: Word);
begin

  repeat
    if CheatCandidateIndex > 22 then begin
      CheatCandidateIndex := 0;
      CheatPrefixLength := 0;
      Exit;
    end;
    if Length(CheatCodes[CheatCandidateIndex]) >= CheatPrefixLength + 1 then
      if Key = Word(CheatCodes[CheatCandidateIndex][CheatPrefixLength + 1]) then Break;
    Inc(CheatCandidateIndex);
  until False;
  Inc(CheatPrefixLength);
  if Length(CheatCodes[CheatCandidateIndex]) = CheatPrefixLength then begin
    case CheatCandidateIndex of
      0: CheatRepair;
      1: CheatKlissanmax;
      2: CheatKlissancall;
      3: CheatRangerpoints;
      4: CheatNextrank;
      5: CheatCoolweapon;
      6: CheatLowcostweapon;
      7: CheatBomb;
      8: CheatArtefact;
      9: CheatMoney;
      10: CheatDrop;
      11: CheatPacking;
      12: CheatKlissanitem;
      13: CheatWeaponstrength;
      14: CheatTenbomb;
      15: CheatRndbase;
      16: CheatMapsector;
      17: CheatHugemoney;
      18: CheatPelengsurprise;
      19: CheatSuperhull;
      20: CheatBoom;
      21: CheatHaterangers;
      22: CheatPirates;
    end;
    CheatCandidateIndex := 0;
    CheatPrefixLength := 0;
  end;
end;
{ @end $5E4D44 }

end.

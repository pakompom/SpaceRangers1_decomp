unit fCommand;
// Unit bracket (inferred): CODE 0x005529E8..0x00555BF3; inclusive evidence, not full bounds.
// Native startup entry 253 ($5529E8..$555BF4) owns the debug dispatcher.
interface
uses DebugMsg;
procedure DebugGiveEquipment(Command: TDebugCommand); // @addr $5541EC
procedure DebugImproveTravelEquipment(Command: TDebugCommand); // @addr $554570
procedure DebugGiveWeapons(Command: TDebugCommand); // @addr $55477C
procedure DebugGiveArtefacts(Command: TDebugCommand); // @addr $554908
procedure DebugGiveRandomAward(Command: TDebugCommand); // @addr $5555FC
procedure DebugGiveExperience(Command: TDebugCommand); // @addr $555680
procedure DebugDamageEquipment(Command: TDebugCommand); // @addr $555B50
procedure DebugSetAllPlanetRelations(Command: TDebugCommand); // @addr $5558D0
procedure DebugPlanetRelation(Command: TDebugCommand); // @addr $5556E8
procedure DebugDumpStarSeeds(Command: TDebugCommand); // @addr $5559DC
procedure DebugRunTurns(Command: TDebugCommand); // @addr $555480
procedure DebugDumpScriptState(Command: TDebugCommand); // @addr $554D38
procedure HandleRuntimeDebugCommand; // @addr $5529E8
const
  RuntimeDebugCommandNames = 'help hitpoints money ships holes PlayerNextDayInAutoPilot GiveRank PortionInDiapasonInvert Give Cool Weapon Artefact Script GBpShip Map NextDay Reward Point Relation CoolFly TestRnd BrokenItems RelationAllPlanetToMax';
implementation

// @unit-initialization $555BEC
// @unit-finalization $555BBC

uses Classes, GI_MessageLoop, Windows, SysUtils, Math, MMSystem, EC_Cache, EC_CacheGAI, EC_Str, EC_BlockPar,
  GR_Main, Globals, GlobalsV, GI_Main, GI_Image, GI_GAI, GI_XviD,
  ab_Object, aGalaxy, aPlanet, aShip, aPlayer, SE_Gate, aMyFunction, aItem, aConst, ThreadCalc, aScript, EC_Expression, aRanger, aAsteroid;

{ @routine $5529E8 HandleRuntimeDebugCommand }
procedure HandleRuntimeDebugCommand;
var
  Command: TDebugCommand;
  Text: WideString;
  OldValue, Index: Integer;
  Ship: TShip;
  Hole: THole;
  Weapon: TWeapon;
begin
  Command := DCGet(RuntimeDebugCommandNames);
  try
    if Command <> nil then
    begin
      if Galaxy <> nil then
      begin
        Galaxy.RestoreProtectedState;
        Galaxy.IntegrityChecksumPending := False;
      end;
      case DCNameI(Command) of
        0:
        begin
          AnswerDebugText(Command, 'help - Помощь'#13#10);
          AnswerDebugText(Command, 'hitpoints [ship_id] value'#13#10);
          AnswerDebugText(Command, 'money [ship_id] value'#13#10);
          AnswerDebugText(Command, 'ships корабли в тек системе'#13#10);
          AnswerDebugText(Command, 'holes'#13#10);
          AnswerDebugText(Command, 'PlayerNextDayInAutoPilot [ship_id] корабль игрока делает NextDay на автопилоте если не указан другой ship_id'#13#10);
          AnswerDebugText(Command, 'GiveRank [1..7]- ранк с указанием номера 0-стереть, по умолчанию-дать очки до следующего'#13#10);
          AnswerDebugText(Command, 'PortionInDiapasonInvert x,a,b,toB,fromA '#13#10);
          AnswerDebugText(Command, 'Give All,None,Pelengator,Communicator'#13#10);
          AnswerDebugText(Command, 'Cool'#13#10);
          AnswerDebugText(Command, 'Weapon'#13#10);
          AnswerDebugText(Command, 'Artefact'#13#10);
          AnswerDebugText(Command, 'Script'#13#10);
          AnswerDebugText(Command, 'GBpShip ship_id'#13#10);
          AnswerDebugText(Command, 'Map'#13#10);
          AnswerDebugText(Command, 'NextDay cnt'#13#10);
          AnswerDebugText(Command, 'BrokenItems [Proc]'#13#10);
          AnswerDebugText(Command, 'Reward'#13#10);
          AnswerDebugText(Command, 'Point [N]'#13#10);
          AnswerDebugText(Command, 'Relation [0..100]'#13#10);
          AnswerDebugText(Command, 'RelationAllPlanetToMax [0..100]'#13#10);
          AnswerDebugText(Command, 'CoolFly'#13#10);
          AnswerDebugText(Command, 'TestRnd'#13#10);
        end;
        1:
          if DCCnt(Command) < 1 then AnswerDebugText(Command, 'hitpoints [ship_id] value'#13#10)
          else if Galaxy <> nil then
          begin
            if (DCCnt(Command) = 1) and (Player <> nil) then
            begin
              OldValue := Player.Hull.HullPoints;
              Player.Hull.HullPoints := DCInt(Command);
              if Player.Hull.HullPoints < 1 then Player.Hull.HullPoints := 1;
              if Player.Hull.HullPoints > Player.Hull.Weight then Player.Hull.HullPoints := Player.Hull.Weight;
              AnswerDebugText(Command, 'ok old=' + IntToStr(OldValue) + ' new=' + IntToStr(Player.Hull.HullPoints));
            end
            else
            begin
              Ship := Galaxy.IdToShip(DCInt(Command), True) as TShip;
              if Ship <> nil then
              begin
                // Native reads Player for the old value and the
                // upper-bound test, even when editing another ship.
                OldValue := Player.Hull.HullPoints;
                Ship.Hull.HullPoints := DCInt(Command);
                if Ship.Hull.HullPoints < 1 then Ship.Hull.HullPoints := 1;
                if Ship.Hull.HullPoints > Player.Hull.Weight then Ship.Hull.HullPoints := Ship.Hull.Weight;
                AnswerDebugText(Command, 'ok old=' + IntToStr(OldValue) + ' new=' + IntToStr(Ship.Hull.HullPoints));
              end;
            end;
          end;
        2:
          if DCCnt(Command) < 1 then AnswerDebugText(Command, 'money [ship_id] value'#13#10)
          else if Galaxy <> nil then
          begin
            if (DCCnt(Command) = 1) and (Player <> nil) then
            begin
              OldValue := Player.Money;
              Player.SetMoney(Max(0, DCInt(Command)));
              AnswerDebugText(Command, 'ok old=' + IntToStr(OldValue) + ' new=' + IntToStr(Player.Money));
            end
            else
            begin
              Ship := Galaxy.IdToShip(DCInt(Command), True) as TShip;
              if Ship <> nil then
              begin
                // The other-ship branch logs Player's old money and does not clamp.
                OldValue := Player.Money;
                Ship.SetMoney(DCInt(Command));
                AnswerDebugText(Command, 'ok old=' + IntToStr(OldValue) + ' new=' + IntToStr(Ship.Money));
              end;
            end;
          end;
        3:
          if PlayerStar <> nil then
            for Index := 0 to PlayerStar.Ships.Count - 1 do
            begin
              Ship := PlayerStar.Ships[Index];
              AnswerDebugWideText(Command, AlignDebugColumn(WideString(IntToStr(Int64(Ship.Id))), 5, 1, ' ') + ' ');
              AnswerDebugWideText(Command, AlignDebugColumn(Ship.Name, 20, -1, ' ') + ' ');
              AnswerDebugWideText(Command, AlignDebugColumn(WideString(IntToStr(Ship.Money)), 10, 1, ' '));
              AnswerDebugText(Command, #13#10);
            end;
        4:
          if Galaxy <> nil then
            for Index := 0 to Galaxy.Holes.Count - 1 do
            begin
              Hole := Galaxy.Holes[Index];
              AnswerDebugWideText(Command, AlignDebugColumn(WideString(IntToStr(Int64(Hole.Id))), 5, 1, ' ') + ' ');
              AnswerDebugWideText(Command, AlignDebugColumn(Hole.Star1.Name, 20, -1, ' ') + ' ');
              AnswerDebugWideText(Command, AlignDebugColumn(Hole.Star2.Name, 20, -1, ' ') + ' ');
              AnswerDebugWideText(Command, AlignDebugColumn(WideString(IntToStr(Integer(Hole.HoleType))), 10, 1, ' '));
              AnswerDebugText(Command, #13#10);
            end;
        5:
        begin
          PlayerAutomaticControl := True;
          Player.NextDay;
          PlayerAutomaticControl := False;
          for Index := 1 to Player.WeaponCount do
          begin
            Weapon := Player.Weapons[Index - 1];
            if Weapon.Target = nil then
              AnswerDebugWideText(Command, WideString(IntToStr(Index) + ' ') + Weapon.GetDisplayName + ' - не нацелено ' + #13#10)
            else
              AnswerDebugWideText(Command, WideString(IntToStr(Index) + ' ') + Weapon.GetDisplayName + ' - нацелено! ' + #13#10);
            if Weapon.Target is TAsteroid then
              AnswerDebugWideText(Command, WideString(IntToStr(Index) + ' ') + Weapon.GetDisplayName + ' - нацелено на астероид! ' + #13#10);
          end;
        end;
        6:
          if DCCnt(Command) = 0 then
          begin
            if Player.Rank = crCommander then AnswerDebugWideText(Command, 'Вы уже ' + Player.GetRankName + ' Больше званий не бывает' + #13#10)
            else if Player.GetRankPointsToNextRank > 0 then
            begin
              AnswerDebugText(Command, 'Добавлено очков летчика: ' + IntToStr(Player.GetRankPointsToNextRank) + #13#10);
              Player.AddRankPoints(Player.GetRankPointsToNextRank);
            end
            else AnswerDebugText(Command, 'У вас уже хватает очков для присвоения очередного звания'#13#10);
          end
          else
          begin
            OldValue := DCInt(Command);
            if OldValue = 0 then
            begin
              Player.Rank := crRookie;
              AnswerDebugWideText(Command, 'Вы понижены до звания: ' + Player.GetRankName + ':-) ' + #13#10);
            end
            else
            begin
              for Index := 1 to OldValue do
                if Player.Rank < crCommander then
                begin
                  Player.AddRankPoints(Player.GetRankPointsToNextRank);
                  Player.TryPromoteRank;
                end;
              AnswerDebugWideText(Command, 'Теперь ваше звание: ' + Player.GetRankName + '!' + #13#10);
            end;
          end;
        7:
          if DCCnt(Command) = 5 then
            AnswerDebugText(Command, 'Получилось: ' + FloatToStr(RemapClampedAlternate(DCFloat(Command), DCFloat(Command), DCFloat(Command), DCFloat(Command), DCFloat(Command))) + #13#10)
          else AnswerDebugText(Command, 'Параметров должно быть 5!'#13#10);
        8:
          if DCCnt(Command) = 0 then AnswerDebugText(Command, 'Ну и что тебе дать любезный? All,Pelengator,Communicator ?'#13#10)
          else for Index := 1 to DCCnt(Command) do
          begin
            Text := WideString(DCStrW(Command));
            if Text = 'All' then
            begin
              Player.HaveCommunicator := True;
              Player.HaveHyperspaceLocator := True;
              AnswerDebugText(Command, 'Получил коммуникатор и пеленгатор'#13#10);
            end
            else if Text = 'None' then
            begin
              Player.HaveCommunicator := False;
              Player.HaveHyperspaceLocator := False;
              AnswerDebugText(Command, 'Все забрали :-)'#13#10);
            end
            else if Text = 'Pelengator' then
            begin
              Player.HaveHyperspaceLocator := True;
              AnswerDebugText(Command, 'Получил пеленгатор'#13#10);
            end
            else if Text = 'Communicator' then
            begin
              Player.HaveCommunicator := True;
              AnswerDebugText(Command, 'Получил коммуникатор'#13#10);
            end
            else AnswerDebugWideText(Command, Text + ' - Это бред!' + #13#10);
          end;
        9: DebugGiveEquipment(Command);
        10: DebugGiveWeapons(Command);
        11: DebugGiveArtefacts(Command);
        12: DebugDumpScriptState(Command);
        13:
        begin
          DebugSelectedShipId := DCInt(Command);
          Ship := Galaxy.IdToShip(DebugSelectedShipId, True) as TShip;
          AnswerDebugWideText(Command, 'Выбран корабль: ' + Ship.GetName);
        end;
        14:
        begin
          for Index := 0 to Galaxy.Constellations.Count - 1 do TConstellation(Galaxy.Constellations[Index]).Visible := True;
          AnswerDebugText(Command, 'Открыли карту!');
        end;
        15: DebugRunTurns(Command);
        16: DebugGiveRandomAward(Command);
        17: DebugGiveExperience(Command);
        18: DebugPlanetRelation(Command);
        19: DebugImproveTravelEquipment(Command);
        20: DebugDumpStarSeeds(Command);
        21: DebugDamageEquipment(Command);
        22: DebugSetAllPlanetRelations(Command);
      end;
    end;
  finally
    DCFree(Command);
  end;
end;
{ @end $5529E8 }

{ @routine $5541EC DebugGiveEquipment }
procedure DebugGiveEquipment(Command: TDebugCommand);
var Weapon: TWeapon; SizeFactors: PItemSizeFactors;
begin
  SizeFactors := @ItemSizeFactors;
  if Player <> nil then
  begin
    Player.Hull.Init(True, Round(500 * SizeFactors^[1]), 8, Player.OwnerId);
    Player.Hull.Cost := 1000;
    Player.Hull.TechLevel := 1;
    if Player.FuelTanks <> nil then
      Player.FuelTanks.Init(True, Round(40 * SizeFactors^[1]), 8, Player.OwnerId)
    else Player.CreateAndEquipFuelTanks(True, Round(40 * SizeFactors^[1]), 8, Player.OwnerId);
    Player.FuelTanks.Cost := 1000;
    Player.FuelTanks.TechLevel := 1;
    if Player.Engine <> nil then
      Player.Engine.Init(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipEngine(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.Engine.Cost := 1000;
    Player.Engine.TechLevel := 1;
    if Player.Radar <> nil then
      Player.Radar.Init(True, Round(30 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipRadar(True, Round(30 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.Radar.Cost := 1000;
    Player.Radar.TechLevel := 1;
    if Player.Scanner <> nil then
      Player.Scanner.Init(True, Round(30 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipScanner(True, Round(30 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.Scanner.Cost := 1000;
    Player.Scanner.TechLevel := 1;
    if Player.RepairRobot <> nil then
      Player.RepairRobot.Init(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipRepairRobot(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.RepairRobot.Cost := 1000;
    Player.RepairRobot.TechLevel := 1;
    if Player.CargoHook <> nil then
      Player.CargoHook.Init(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipCargoHook(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.CargoHook.Cost := 1000;
    Player.CargoHook.TechLevel := 1;
    if Player.DefGenerator <> nil then
      Player.DefGenerator.Init(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipDefGenerator(True, Round(40 * SizeFactors^[5]), 8, Player.OwnerId);
    Player.DefGenerator.Cost := 1000;
    Player.DefGenerator.TechLevel := 1;
    if Player.WeaponCount < 5 then
    begin
      Weapon := Player.CreateAndEquipWeapon(t_TachionCleaver, True, Round(WeaponInfo[t_TachionCleaver].Weight * SizeFactors^[5]), 8, Player.OwnerId);
      Weapon.MinDamage := 255;
      Weapon.MaxDamage := 255;
      Weapon.Cost := 1000;
      Weapon.TechLevel := 1;
    end;
    Player.RefreshGraphicSize;
    Player.RefreshDerivedStats;
    AnswerDebugText(Command, 'ok');
  end;
end;
{ @end $5541EC }

{ @routine $554570 DebugImproveTravelEquipment }
procedure DebugImproveTravelEquipment(Command: TDebugCommand);
begin
  if Player <> nil then
  begin
    Player.Hull.HullPoints := Player.Hull.Weight;
    if Player.FuelTanks <> nil then
      Player.FuelTanks.Init(True, Round(40 * ItemSizeFactors[1]), 8, Player.OwnerId)
    else Player.CreateAndEquipFuelTanks(True, Round(40 * ItemSizeFactors[1]), 8, Player.OwnerId);
    Player.FuelTanks.Cost := 1000;
    Player.FuelTanks.TechLevel := 1;
    if Player.Engine <> nil then
      Player.Engine.Init(True, Round(40 * ItemSizeFactors[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[5]), 8, Player.OwnerId);
    Player.Engine.Cost := 1000;
    Player.Engine.TechLevel := 1;
    Player.Engine.JumpRange := 130;
    if Player.Radar <> nil then
      Player.Radar.Init(True, Round(30 * ItemSizeFactors[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipRadar(True, Round(30 * ItemSizeFactors[5]), 8, Player.OwnerId);
    Player.Radar.Cost := 1000;
    Player.Radar.TechLevel := 1;
    if Player.Scanner <> nil then
      Player.Scanner.Init(True, Round(30 * ItemSizeFactors[5]), 8, Player.OwnerId)
    else Player.CreateAndEquipScanner(True, Round(30 * ItemSizeFactors[5]), 8, Player.OwnerId);
    Player.Scanner.Cost := 1000;
    Player.Scanner.TechLevel := 1;
    AnswerDebugText(Command, 'Круто далеко летаем');
  end;
end;
{ @end $554570 }

{ @routine $55477C DebugGiveWeapons }
procedure DebugGiveWeapons(Command: TDebugCommand);
begin
  if Player <> nil then
  begin
    Player.CreateAndEquipScanner(False, Round(30 * ItemSizeFactors[5]), 8, oiNone);
    Player.CreateAndEquipWeapon(t_PhotonGun, False, 1, 8, oiNone);
    Player.CreateAndEquipWeapon(t_IndustrialLaser, False, 1, 8, oiNone);
    Player.CreateAndEquipWeapon(t_ZipGun, False, 1, 8, oiNone);
    Player.CreateAndEquipWeapon(t_GravitonBeamer, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_Retractor, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_KellersPhaser, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_AeonicBlaster, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_XDefibrillator, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_SubmesonicGun, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_FieldAnnihilator, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_TachionCleaver, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_VortexProjector, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_AbsoluteMatrix, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_HellWave, False, 1, 8, Player.OwnerId);
    Player.CreateAndEquipWeapon(t_EyesOfMachpella, False, 1, 8, Player.OwnerId);
    Player.RefreshDerivedStats;
    AnswerDebugText(Command, 'ok');
  end;
end;
{ @end $55477C }

{ @routine $554908 DebugGiveArtefacts }
procedure DebugGiveArtefacts(Command: TDebugCommand);
var Artefact: TArtefact;
begin
  if Player <> nil then
  begin
    Artefact := TArtefactHull.Create;
    (Artefact as TArtefactHull).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactFuel.Create;
    (Artefact as TArtefactFuel).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactSpeed.Create;
    (Artefact as TArtefactSpeed).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactPower.Create;
    (Artefact as TArtefactPower).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactRadar.Create;
    (Artefact as TArtefactRadar).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactScaner.Create;
    (Artefact as TArtefactScaner).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactDroid.Create;
    (Artefact as TArtefactDroid).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactNano.Create;
    (Artefact as TArtefactNano).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactHook.Create;
    (Artefact as TArtefactHook).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactDef.Create;
    (Artefact as TArtefactDef).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactAnalyzer.Create;
    (Artefact as TArtefactAnalyzer).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactMiniExpl.Create;
    (Artefact as TArtefactMiniExpl).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactAntigrav.Create;
    (Artefact as TArtefactAntigrav).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact.Equip;
    Artefact := TArtefactTransmitter.Create;
    (Artefact as TArtefactTransmitter).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact := TArtefactBomb.Create;
    (Artefact as TArtefactBomb).Init(Player.HomePlanet.OwnerId);
    Player.Artefacts.Add(Artefact);
    Artefact := TArtefactTranclucator.Create;
    (Artefact as TArtefactTranclucator).Init(Player.HomePlanet.OwnerId, Player, nil);
    Player.Artefacts.Add(Artefact);
    AnswerDebugText(Command, 'ok');
  end;
end;
{ @end $554908 }

{ @routine $554D38 DebugDumpScriptState }
procedure DebugDumpScriptState(Command: TDebugCommand);
var
  Index, SubIndex, EntryIndex: Integer;
  Template: TScriptTemplUnit;
  Script: TScript;
  ScriptStar: TScriptStar;
  Group: TScriptGroup;
  Binding: TScriptShip;
begin
  if Galaxy = nil then Exit;
  AnswerDebugText(Command, '--- State ----------------'#13#10);
  AnswerDebugWideText(Command,
    AlignDebugColumn('Name', 20, 0, ' ') + ' | ' +
    AlignDebugColumn('CntUse', 10, 0, ' ') + ' | ' +
    AlignDebugColumn('LastTurn', 10, 0, ' ') + ' | ' +
    AlignDebugColumn('RunScript', 10, 0, ' ') + #13#10);
  for Index := 0 to ScriptTemplates.Count - 1 do
  begin
    Template := ScriptTemplates[Index];
    AnswerDebugWideText(Command,
      AlignDebugColumn(Template.Name, 20, -1, ' ') + ' | ' +
      AlignDebugColumn(WideString(IntToStr(Template.UseCount)), 10, 0, ' ') + ' | ' +
      AlignDebugColumn(WideString(IntToStr(Template.LastTurn)), 10, 0, ' ') + ' | ' +
      AlignDebugColumn(WideString(IntToStr(Template.ActiveScriptIndex)), 10, 0, ' ') + #13#10);
  end;
  AnswerDebugText(Command, '--- Global var -----------'#13#10);
  for Index := 0 to SharedScriptVariables.Count - 1 do
    AnswerDebugWideText(Command, SharedScriptVariables.GetItem(Index).Name + '=' + SharedScriptVariables.GetItem(Index).GetString + #13#10);
  for Index := 0 to Galaxy.Scripts.Count - 1 do
  begin
    Script := Galaxy.Scripts[Index];
    AnswerDebugWideText(Command, '--- ' + Script.ScriptFileName + ' -----------' + #13#10);
    AnswerDebugText(Command, '    --- Var ---'#13#10);
    for SubIndex := 0 to Script.InitCode.LocalVar.Count - 1 do
      AnswerDebugWideText(Command, '    ' + Script.InitCode.LocalVar.GetItem(SubIndex).Name + '=' + Script.InitCode.LocalVar.GetItem(SubIndex).GetString + #13#10);
    AnswerDebugText(Command, '    --- System ---'#13#10);
    for SubIndex := 0 to Script.Stars.Count - 1 do
    begin
      ScriptStar := Script.Stars[SubIndex];
      AnswerDebugWideText(Command, '    ' + ScriptStar.Name + ' (' + ScriptStar.Star.Name + ')' + #13#10);
      for EntryIndex := 0 to High(ScriptStar.Planets) do
        AnswerDebugWideText(Command, '        ' + ScriptStar.Planets[EntryIndex].Name + ' (' + ScriptStar.Planets[EntryIndex].Planet.Name + ')' + #13#10);
    end;
    AnswerDebugText(Command, '    --- Ships ---'#13#10);
    for SubIndex := 0 to Script.Groups.Count - 1 do
    begin
      Group := Script.Groups[SubIndex];
      AnswerDebugWideText(Command, '    ' + Group.Name + #13#10);
      for EntryIndex := 0 to Script.Ships.Count - 1 do
      begin
        Binding := Script.Ships[EntryIndex];
        if Binding.GroupIndex = SubIndex then
        begin
          AnswerDebugWideText(Command, '        ' + Binding.Ship.GetName);
          if Binding.State <> nil then AnswerDebugWideText(Command, '    State=' + Binding.State.Name);
          AnswerDebugText(Command, #13#10);
        end;
      end;
    end;
  end;
end;
{ @end $554D38 }

{ @routine $555480 DebugRunTurns }
procedure DebugRunTurns(Command: TDebugCommand);
var Index, Count: Integer; StartedAt: Int64;
begin
  if DCCnt(Command) >= 1 then
  begin
    Count := DCInt(Command);
    StartedAt := ReadPerformanceCounter;
    for Index := 1 to Count do
    begin
      RestoreTemporaryShopStock;
      ProcessPlayerStarTurnSynchronously;
      ProcessGalaxyTurnSynchronously;
      BuildTemporaryShopSlotGrid;
    end;
    AnswerDebugText(Command, IntToStr(Count) + ' turns = ' + FloatToStr((ReadPerformanceCounter - StartedAt) / CounterFrequency) + ' s');
    for Index := 0 to Galaxy.Constellations.Count - 1 do
      TConstellation(Galaxy.Constellations[Index]).Visible := True;
    if Player.CurrentPlanet <> nil then
      Player.CurrentPlanet.RangerRelations[Galaxy.Rangers.IndexOf(Player)] := Pointer(100);
  end;
end;
{ @end $555480 }

{ @routine $5555FC DebugGiveRandomAward }
procedure DebugGiveRandomAward(Command: TDebugCommand);
var Award: PByte;
begin
  if Player <> nil then
  begin
    New(Award);
    Award^ := RandomIntRange(0, 27);
    if Player.AwardIds = nil then Player.AwardIds := TList.Create;
    Player.AwardIds.Add(Award);
    AnswerDebugText(Command, 'Ok');
  end;
end;
{ @end $5555FC }

{ @routine $555680 DebugGiveExperience }
procedure DebugGiveExperience(Command: TDebugCommand);
begin
  if Player <> nil then
  begin
    if DCCnt(Command) < 1 then Player.GainExperience(10)
    else Player.GainExperience(DCInt(Command));
    AnswerDebugText(Command, 'Очки добавлены');
  end;
end;
{ @end $555680 }

{ @routine $5556E8 DebugPlanetRelation }
procedure DebugPlanetRelation(Command: TDebugCommand);
begin
  if (Player = nil) or (Player.CurrentPlanet = nil) then Exit;
  if DCCnt(Command) < 1 then
    AnswerDebugWideText(Command, WideString('Отношение к планете равно :' + IntToStr(Player.CurrentPlanet.RelationToShip(Player)) + '% ') + Player.CurrentPlanet.GetRelationLevelTextToShip(Player))
  else
  begin
    Player.CurrentPlanet.RangerRelations[Galaxy.Rangers.IndexOf(Player)] := Pointer(DCInt(Command));
    AnswerDebugWideText(Command, WideString('Отношение к планете изменилось до :' + IntToStr(Player.CurrentPlanet.RelationToShip(Player)) + '% ') + Player.CurrentPlanet.GetRelationLevelTextToShip(Player));
  end;
end;
{ @end $5556E8 }

{ @routine $5558D0 DebugSetAllPlanetRelations }
procedure DebugSetAllPlanetRelations(Command: TDebugCommand);
begin
  if Player <> nil then
  begin
    // Native tests the argument count, not the supplied relation value.
    if not (DCCnt(Command) in [0..100]) then AnswerDebugText(Command, 'Число от 0 до 100')
    else
    begin
      Player.ChangePlanetRelations(nil, rcmRaiseTo, DCInt(Command), [oiMaloc..oiGaal]);
      AnswerDebugText(Command, 'Отношение к планете изменилось до :' + IntToStr(DCInt(Command)) + '% ');
    end;
  end;
end;
{ @end $5558D0 }
{ @routine $5559DC DebugDumpStarSeeds }
procedure DebugDumpStarSeeds(Command: TDebugCommand);
var Index: Integer; Star: TStar;
begin
  for Index := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := Galaxy.Stars[Index];
    AnswerDebugText(Command, Format('%s(Star.FRnd)   mod 2 = %d    mod 3 = %d   mod 4 = %d'#13#10,
      [AlignDebugColumn(WideString(IntToStr(Integer(Star.GenerationSeed))), 14, 1, ' '),
       Integer(Star.GenerationSeed) mod 2, Integer(Star.GenerationSeed) mod 3, Integer(Star.GenerationSeed) mod 4]));
  end;
end;
{ @end $5559DC }
{ @routine $555B50 DebugDamageEquipment }
procedure DebugDamageEquipment(Command: TDebugCommand);
var Amount: Integer;
begin
  if DCCnt(Command) < 1 then Amount := NextRandomIntRange(10, 30, Player.RandomState)
  else Amount := DCInt(Command);
  Player.DegradeEquipmentFromDamage(Amount);
  if Player.FuelTanks <> nil then Dec(Player.FuelTanks.Fuel, 20);
end;
{ @end $555B50 }
end.

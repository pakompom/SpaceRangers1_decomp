unit fGameSettings;
// Unit bracket (inferred): CODE 0x00604D34..0x00606D9F; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, EC_Thread, Types;
type
  TfGameSettings = class(TMessageLoopGI) // @size $B8
  public
    PlayerRace: TRaceId; // @offset $B0
    Difficulty: TDifficulty; // @offset $B1
    HoveredRace: Byte; // @offset $B2 Only ever set to 6; no race selection reads it.
    AlternateRaces: array[0..3] of TRaceId; // @offset $B3
    NameWasEdited: Boolean; // @offset $B7
    procedure MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $6052BC
    procedure PlayerNameMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $6052E4
    procedure RaceClicked(Sender: TObjectGI); // @addr $605334
    procedure StartGame(Sender: TObjectGI); // @addr $605908
    procedure ReturnToMenu(Sender: TObjectGI); // @addr $6059C8
    procedure SelectCareer(Value: TRangerCareer); // @addr $6059DC
    function GetCareer: TRangerCareer; // @addr $605C98
    procedure CareerClicked(Sender: TObjectGI); // @addr $605D68
    procedure SelectDifficulty(Value: TDifficulty); // @addr $605E18
    procedure DifficultyClicked(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $605F64
    procedure GeneratePlayerName; // @addr $606038
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $606164
    procedure ShowHelp(Sender: TObjectGI; Show: Boolean); // @addr $606244
    procedure DifficultyMouseEnter(Sender: TObjectGI); // @addr $6062A8
    procedure DifficultyMouseLeave(Sender: TObjectGI); // @addr $6062B0
    procedure SelectMusic; override; // @addr $6062B8
    procedure UpdateCharacterInfo(Sender: TObjectGI); // @addr $6062DC
    procedure OnOpen; override; // @addr $604E38
    procedure SelectRace(Value: TRaceId); // @addr $605358
  end;
  TThreadCreateNewGame = class(TThreadEC) // @size $38
  public
    PlayerRace: TRaceId; // @offset $2C
    Difficulty: TDifficulty; // @offset $2D
    CaptainName: WideString; // @offset $30
    PreferredCareer: TRangerCareer; // @offset $34
    procedure Execute; override; // @addr $60645C @slot $00
  end;
const
  RaceUpperOffsets: array[TRaceId] of Integer = (-1, 3, -7, -4, -6); // @addr $618970
  RaceLowerOffsets: array[TRaceId] of Integer = (1, 6, 6, 4, 6); // @addr $618984

implementation

// @unit-initialization $606D98
// @unit-finalization $606D68

uses Classes, aGalaxy, aPlanet, aRanger, aPlayer, aKling, aRuins, aRuinsRC,
  aRuinsSB, aRuinsPB, aRuinsWB, aConst, aMyFunction, aScript, aCalc, GlobalsV, GR_Main, fIntroduction, GI_Image, GI_Edit, GI_Label, GI_GraphButton,
  GI_GAI, GI_Main, EC_Str, EC_Struct, SysUtils, Windows, GR_Music, Globals, fFilmFile;

{ @routine $604E38 TfGameSettings_OnOpen }
procedure TfGameSettings.OnOpen;
begin
  GetByName('LabelHelp').SetActive(False);
  NameWasEdited := False;
  GetByName('MainPanel').KeyDownCallback := MainPanelKeyDown;
  AlternateRaces[0] := raMaloc;
  AlternateRaces[1] := raPeleng;
  AlternateRaces[2] := raFei;
  AlternateRaces[3] := raGaal;
  PlayerRace := raPeople;
  HoveredRace := 6;
  GetByName('MainPanel').MouseMoveCallback := MainPanelMouseMove;
  GetByName('MainPanel').LeftButtonDownCallback := PlayerNameMouseDown;
  with GetByName('MoralTrader') as TGraphButtonGI do begin
    UpCallback := CareerClicked;
    HelpCallback := ShowHelp;
  end;
  with GetByName('MoralPirate') as TGraphButtonGI do begin
    UpCallback := CareerClicked;
    HelpCallback := ShowHelp;
  end;
  with GetByName('MoralWarrior') as TGraphButtonGI do begin
    UpCallback := CareerClicked;
    HelpCallback := ShowHelp;
  end;
  (GetByName('MoralTrader') as TGraphButtonGI).DownCallback := CareerClicked;
  (GetByName('MoralPirate') as TGraphButtonGI).DownCallback := CareerClicked;
  (GetByName('MoralWarrior') as TGraphButtonGI).DownCallback := CareerClicked;
  with GetByName('Level0') as TLabelGI do begin
    LeftButtonDownCallback := DifficultyClicked;
    MouseEnterCallback := DifficultyMouseEnter;
    MouseLeaveCallback := DifficultyMouseLeave;
  end;
  with GetByName('Level1') as TLabelGI do begin
    LeftButtonDownCallback := DifficultyClicked;
    MouseEnterCallback := DifficultyMouseEnter;
    MouseLeaveCallback := DifficultyMouseLeave;
  end;
  with GetByName('Level2') as TLabelGI do begin
    LeftButtonDownCallback := DifficultyClicked;
    MouseEnterCallback := DifficultyMouseEnter;
    MouseLeaveCallback := DifficultyMouseLeave;
  end;
  with GetByName('Level3') as TLabelGI do begin
    LeftButtonDownCallback := DifficultyClicked;
    MouseEnterCallback := DifficultyMouseEnter;
    MouseLeaveCallback := DifficultyMouseLeave;
  end;
  with GetByName('Ok') as TGraphButtonGI do begin
    UpCallback := StartGame;
    HelpCallback := ShowHelp;
  end;
  with GetByName('Cancel') as TGraphButtonGI do begin
    UpCallback := ReturnToMenu;
    HelpCallback := ShowHelp;
  end;
  with GetByName('PlayerName') as TEditGI do begin
    ChangedCallback := UpdateCharacterInfo;
    MaxLength := 13;
  end;
  SelectCareer(rcTrader);
  SelectDifficulty(dfNormal);
  SelectRace(raPeople);
end;
{ @end $604E38 }

{ @routine $6052BC TfGameSettings_MainPanelMouseMove }
procedure TfGameSettings.MainPanelMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var Race: Byte;
begin
  Race := 6;
  if HoveredRace <> Race then HoveredRace := Race;
end;
{ @end $6052BC }

{ @routine $6052E4 TfGameSettings_PlayerNameMouseDown }
procedure TfGameSettings.PlayerNameMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  SetFocusedControl(GetByName('PlayerName'));
end;
{ @end $6052E4 }

{ @routine $605334 TfGameSettings_RaceClicked }
procedure TfGameSettings.RaceClicked(Sender: TObjectGI);
var Race: TRaceId;
begin
  Race := AlternateRaces[Sender.UserValue];
  AlternateRaces[Sender.UserValue] := PlayerRace;
  SelectRace(Race);
end;
{ @end $605334 }

{ @routine $605358 TfGameSettings_SelectRace }
procedure TfGameSettings.SelectRace(Value: TRaceId);
var I: Integer; Race: TRaceId; Path: WideString;
begin
  for I := 0 to 3 do begin
    with GetByName('i' + IntToStr(I)) as TImageGI do begin
      SetImagePath('GI,Bm.FormGameSet.' + GiResourceSuffix + 'i' + OwnerInfo[RaceToOwner(AlternateRaces[I])].InternalName);
      SetImageKindX(ikxCenter);
      SetImageKindY(ikyCenter);
      if I <> 3 then SetOrigin(Classes.Point(0, GiScalePixels(RaceUpperOffsets[AlternateRaces[I]])))
      else SetOrigin(Classes.Point(0, GiScalePixels(RaceLowerOffsets[AlternateRaces[I]])));
    end;
    with GetByName('R' + IntToStr(I)) as TGraphButtonGI do begin
      UserValue := I;
      DownCallback := RaceClicked;
      if I <> 3 then Path := 'GI,Bm.FormGameSet.' + GiResourceSuffix + 'up' + IntToStr(Ord(AlternateRaces[I]))
      else Path := 'GI,Bm.FormGameSet.' + GiResourceSuffix + 'down' + IntToStr(Ord(AlternateRaces[I]));
      SetImageNormalPath(Path + 'n');
      SetImageNormalActivePath(Path + 'a');
      SetImageDownPath(Path + 'n');
      HelpCallback := ShowHelp;
    end;
  end;
  PlayerRace := Value;
  with GetByName('i4') as TImageGI do begin
    SetImagePath('GI,Bm.FormGameSet.' + GiResourceSuffix + 'i' + OwnerInfo[RaceToOwner(PlayerRace)].InternalName);
    SetImageKindX(ikxCenter);
    SetImageKindY(ikyCenter);
  end;
  for Race := raMaloc to raGaal do
    with GetByName('Anim' + OwnerInfo[RaceToOwner(Race)].InternalName) as TgaiGI do
      if Race = PlayerRace then begin
        SetActive(True);
        RestartPlayback;
      end else begin
        StopAutoPlayback;
        SetActive(False);
      end;
  if not NameWasEdited then GeneratePlayerName;
  SetFocusedControl(GetByName('PlayerName'));
  with GetByName('PlayerName') as TEditGI do SetCaretPosition(Length(Text));
  UpdateCharacterInfo(nil);
  with GetByName('LabelRace') as TLabelGI do
    SetText(WrapTextInColor(LowerCaseWideString(LookupLocalizedTextByKey('Race.Name.' + OwnerInfo[RaceToOwner(PlayerRace)].InternalName)), HighlightColorTag));
end;
{ @end $605358 }

{ @routine $605908 TfGameSettings_StartGame }
procedure TfGameSettings.StartGame(Sender: TObjectGI);
begin
  FilmHistory.Clear;
  // Native inverted guard: a live previous worker is not freed here.
  if NewGameGenerationThread = nil then begin
    NewGameGenerationThread.Free;
    NewGameGenerationThread := nil;
  end;
  NewGameGenerationThread := TThreadCreateNewGame.Create;
  NewGameGenerationThread.PlayerRace := PlayerRace;
  NewGameGenerationThread.PreferredCareer := GetCareer;
  NewGameGenerationThread.Difficulty := Difficulty;
  NewGameGenerationThread.CaptainName := (GetByName('PlayerName') as TEditGI).Text;
  NewGameGenerationThread.SetPriority(2);
  NewGameGenerationThread.Start;
  RequestedScreenId := screenIntroduction;
  RequestClose(1);
end;
{ @end $605908 }

{ @routine $6059C8 TfGameSettings_ReturnToMenu }
procedure TfGameSettings.ReturnToMenu(Sender: TObjectGI);
begin
  RequestedScreenId := screenMainMenu;
  RequestClose(1);
end;
{ @end $6059C8 }

{ @routine $6059DC TfGameSettings_SelectCareer }
procedure TfGameSettings.SelectCareer(Value: TRangerCareer);
begin
  (GetByName('MoralTrader') as TGraphButtonGI).SetDown(Value = rcTrader);
  (GetByName('MoralPirate') as TGraphButtonGI).SetDown(Value = rcPirate);
  (GetByName('MoralWarrior') as TGraphButtonGI).SetDown(Value = rcWarrior);
  with GetByName('LabelMoral') as TLabelGI do begin
    if Value = rcTrader then SetText(WrapTextInColor(LowerCaseWideString(LookupLocalizedTextByKey('RangerInfo.Type.Trader')), HighlightColorTag))
    else if Value = rcWarrior then SetText(WrapTextInColor(LowerCaseWideString(LookupLocalizedTextByKey('RangerInfo.Type.Warrior')), HighlightColorTag))
    else if Value = rcPirate then SetText(WrapTextInColor(LowerCaseWideString(LookupLocalizedTextByKey('RangerInfo.Type.Pirate')), HighlightColorTag));
  end;
  UpdateCharacterInfo(nil);
end;
{ @end $6059DC }

{ @routine $605C98 TfGameSettings_GetCareer }
function TfGameSettings.GetCareer: TRangerCareer;
begin
  Result := rcTrader;
  if (GetByName('MoralTrader') as TGraphButtonGI).Down then Result := rcTrader
  else if (GetByName('MoralPirate') as TGraphButtonGI).Down then Result := rcPirate
  else if (GetByName('MoralWarrior') as TGraphButtonGI).Down then Result := rcWarrior;
end;
{ @end $605C98 }

{ @routine $605D68 TfGameSettings_CareerClicked }
procedure TfGameSettings.CareerClicked(Sender: TObjectGI);
begin
  if Sender.ControlName = 'MoralTrader' then SelectCareer(rcTrader)
  else if Sender.ControlName = 'MoralPirate' then SelectCareer(rcPirate)
  else if Sender.ControlName = 'MoralWarrior' then SelectCareer(rcWarrior);
end;
{ @end $605D68 }

{ @routine $605E18 TfGameSettings_SelectDifficulty }
procedure TfGameSettings.SelectDifficulty(Value: TDifficulty);
var
  LabelControl: TLabelGI;
  ImageControl: TObjectGI;
  SelectedValue: TDifficulty;
begin
  SelectedValue := Value;
  Difficulty := SelectedValue;
  if SelectedValue = dfEasy then LabelControl := GetByName('Level0') as TLabelGI
  else if SelectedValue = dfNormal then LabelControl := GetByName('Level1') as TLabelGI
  else if SelectedValue = dfHard then LabelControl := GetByName('Level2') as TLabelGI
  else if SelectedValue = dfExpert then LabelControl := GetByName('Level3') as TLabelGI
  else raise Exception.Create('Level not support');
  ImageControl := GetByName('ImageLevel');
  ImageControl.SetPosition(LabelControl.LocalPosition);
  ImageControl.SetSize(LabelControl.ClientSize);
end;
{ @end $605E18 }

{ @routine $605F64 TfGameSettings_DifficultyClicked }
procedure TfGameSettings.DifficultyClicked(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if Sender.ControlName = 'Level0' then SelectDifficulty(dfEasy)
  else if Sender.ControlName = 'Level1' then SelectDifficulty(dfNormal)
  else if Sender.ControlName = 'Level2' then SelectDifficulty(dfHard)
  else if Sender.ControlName = 'Level3' then SelectDifficulty(dfExpert);
end;
{ @end $605F64 }

{ @routine $606038 TfGameSettings_GeneratePlayerName }
procedure TfGameSettings.GeneratePlayerName;
var RaceName, Name: WideString; Index: Integer;
begin
  RaceName := OwnerToSys(RaceToOwner(PlayerRace));
  repeat
    Index := RandomIntRange(0, LanguageDataConfig.GetBlock('ShipName').GetBlock('Ranger').GetBlock(RaceName).GetParamCount - 1);
    Name := LanguageDataConfig.GetBlock('ShipName').GetBlock('Ranger').GetBlock(RaceName).GetParamValue(Index);
    (GetByName('PlayerName') as TEditGI).SetText(Name);
  until Length(Name) <= 13;
end;
{ @end $606038 }

{ @routine $606164 TfGameSettings_MainPanelKeyDown }
procedure TfGameSettings.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if not IsVirtualKeyDown(VK_CONTROL) and not IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) then
    if Key = VK_RETURN then StartGame(nil)
    else if Key = VK_ESCAPE then ReturnToMenu(nil)
    else if Key = VK_F1 then SelectRace(raMaloc)
    else if Key = VK_F2 then SelectRace(raPeleng)
    else if Key = VK_F3 then SelectRace(raPeople)
    else if Key = VK_F4 then SelectRace(raFei)
    else if Key = VK_F5 then SelectRace(raGaal)
    else if Key = VK_F6 then SelectCareer(rcTrader)
    else if Key = VK_F7 then SelectCareer(rcWarrior)
    else if Key = VK_F8 then SelectCareer(rcPirate);
end;
{ @end $606164 }

{ @routine $606244 TfGameSettings_ShowHelp }
procedure TfGameSettings.ShowHelp(Sender: TObjectGI; Show: Boolean);
var LabelControl: TLabelGI;
begin
  LabelControl := GetByName('LabelHelp') as TLabelGI;
  if Sender.HelpText = '' then Show := False;
  LabelControl.SetActive(Show);
  LabelControl.SetText(Sender.HelpText);
end;
{ @end $606244 }

{ @routine $6062A8 TfGameSettings_DifficultyMouseEnter }
procedure TfGameSettings.DifficultyMouseEnter(Sender: TObjectGI);
begin
  ShowHelp(Sender, True);
end;
{ @end $6062A8 }

{ @routine $6062B0 TfGameSettings_DifficultyMouseLeave }
procedure TfGameSettings.DifficultyMouseLeave(Sender: TObjectGI);
begin
  ShowHelp(Sender, False);
end;
{ @end $6062B0 }

{ @routine $6062B8 TfGameSettings_SelectMusic }
procedure TfGameSettings.SelectMusic;
begin
  MusicManager.PlayCategory('Base');
end;
{ @end $6062B8 }

{ @routine $6062DC TfGameSettings_UpdateCharacterInfo }
procedure TfGameSettings.UpdateCharacterInfo(Sender: TObjectGI);
var Text: WideString;
begin
  Text := LocalizedColorText('FormGameSet.' + OwnerInfo[RaceToOwner(PlayerRace)].InternalName + '.' + CareerNames[GetCareer]);
  ReplaceTextToken(Text, '<Name>', (GetByName('PlayerName') as TEditGI).Text, HighlightColorTag);
  (GetByName('Info') as TLabelGI).SetText(Text);
  if Sender <> nil then NameWasEdited := True;
end;
{ @end $6062DC }

{ @routine $60645C TThreadCreateNewGame_Execute }
procedure TThreadCreateNewGame.Execute;
var I, J, Count: Integer; Star: TStar; Planet: TPlanet; Ranger: TRanger;
  Constellation: TConstellation; Station: TRuins;
begin
  try
    NewGameGenerationStage := 1;
    Galaxy := TGalaxy.Create;
    Galaxy.Difficulty := Difficulty;
    Galaxy.InitializeCampaignState;
    PlayerStar := nil;
    for I := 1 to GalaxyStarCount do begin
      Star := TStar.Create;
      Galaxy.Stars.Add(Star);
    end;
    Galaxy.GenerateGalaxyLayout(PlayerRace);
    for I := 0 to Galaxy.Stars.Count - 1 do begin
      Star := Galaxy.Stars[I];
      Star.GenerateSystemContents;
    end;
    Galaxy.RefreshTechLevel;
    NewGameGenerationStage := 2;
    Galaxy.RebuildAllStarDistances;
    Player := TPlayer.Create;
    Count := 0;
    for I := 0 to Galaxy.Planets.Count - 1 do begin
      Planet := Galaxy.Planets[I];
      if RaceToOwner(PlayerRace) = Planet.OwnerId then begin
        Inc(Count);
        // Skips the first planet with the selected owner.
        if Count = 1 then Continue;
        PlayerStar := Planet.CurrentStar;
        Player.PreferredCareer := PreferredCareer;
        case Player.PreferredCareer of
          rcTrader: begin
            Player.CareerStatus[rcTrader] := NextRandomIntRange(60, 90, Galaxy.RandomState);
            Player.CareerStatus[rcPirate] := (100 - Player.CareerStatus[rcTrader]) div NextRandomIntRange(2, 3, Galaxy.RandomState);
            Player.CareerStatus[rcWarrior] := 100 - Player.CareerStatus[rcTrader] - Player.CareerStatus[rcPirate];
          end;
          rcPirate: begin
            Player.CareerStatus[rcPirate] := NextRandomIntRange(70, 90, Galaxy.RandomState);
            Player.CareerStatus[rcTrader] := (100 - Player.CareerStatus[rcPirate]) div NextRandomIntRange(2, 3, Galaxy.RandomState);
            Player.CareerStatus[rcWarrior] := 100 - Player.CareerStatus[rcPirate] - Player.CareerStatus[rcTrader];
          end;
          rcWarrior: begin
            Player.CareerStatus[rcWarrior] := NextRandomIntRange(70, 90, Galaxy.RandomState);
            Player.CareerStatus[rcPirate] := (100 - Player.CareerStatus[rcWarrior]) div NextRandomIntRange(2, 3, Galaxy.RandomState);
            Player.CareerStatus[rcTrader] := 100 - Player.CareerStatus[rcWarrior] - Player.CareerStatus[rcPirate];
          end;
        end;
        Player.InitializeAtPlanet(Planet, DifficultyModifiers[Difficulty].StartingMoney);
        Player.HomePlanet.ChangeRelationToRanger(Player, 100);
        Player.Name := CaptainName;
        PlayerOldQuests := TObjectList.Create;
        Break;
      end;
    end;
    Globals.PlayerName := CaptainName;
    Galaxy.RefreshRangerWealthStats;
    Galaxy.RefreshRangerStrengthStats;
    Star := Player.CurrentStar.StarDistances[Galaxy.Stars.Count - 1].Star as TStar;
    Galaxy.CreateKlissanSpawnProxy(Star);
    KlingMotherShip := TKling.Create;
    TKling(KlingMotherShip).InitMotherShip;
    Count := Round(Galaxy.Stars.Count / 100 * DifficultyModifiers[Galaxy.Difficulty].InitialKlissanOccupationPercent);
    for I := 0 to Count do begin
      Star := KlingMotherShip.CurrentStar.StarDistances[I].Star as TStar;
      if (Star.Constellation <> Player.CurrentStar.Constellation) and
        ((Galaxy.Constellations.IndexOf(Star.Constellation) >= 5) or (NextRandomUnitFloat(Galaxy.RandomState) >= 0.4)) and
        ((I < Count div 2) or (NextRandomUnitFloat(Galaxy.RandomState) < 0.8)) then Star.ControlFaction := sfKlissan;
    end;
    Galaxy.AssignTextQuestsToPlanets;
    Galaxy.InitializeConstellationDistanceTiers;
    for I := 0 to Galaxy.Constellations.Count - 1 do begin
      Constellation := Galaxy.Constellations[I];
      if Constellation.SharesOutlineSegment(Player.HomePlanet.CurrentStar.Constellation) then Constellation.Visible := True
      else Constellation.Visible := False;
    end;
    for I := 0 to Galaxy.Planets.Count - 1 do begin
      Planet := Galaxy.Planets[I];
      if Planet.IsCoalitionOwned and (Planet.CurrentStar.ControlFaction = sfKlissan) then begin
        Planet.OwnerId := oiKling;
        Planet.UpdateOwnerFlags;
      end;
      case Planet.OwnerId of
        oiMaloc..oiGaal: begin
          Planet.SpawnTransport(RandomTransportHullType);
          Planet.SpawnTransport(RandomTransportHullType);
          Planet.SpawnWarrior;
          if Galaxy.Rangers.Count < Galaxy.CountStarsByFaction(sfCoalition) * 1.5 then Planet.SpawnRanger;
          Galaxy.RefreshRangerStrengthStats;
        end;
        oiKling: begin
          while (Planet.CurrentStar.ShipTypeCounts[t_Kling] < 10) and
            ((Planet.CurrentStar.SumBestRangerRelativeStrength([t_Kling]) < KlissanFleetStrengthThresholds[Planet.CurrentStar.Constellation.HomeDistanceTier]) or
             (Planet.CurrentStar.ShipTypeCounts[t_Kling] < 8)) do Planet.SpawnWeightedKlissan;
        end;
      end;
    end;
    Station := TRC.Create;
    (Station as TRC).Init(Player.CurrentStar);
    Station := TSB.Create;
    (Station as TSB).Init(Player.CurrentStar);
    Station := TPB.Create;
    (Station as TPB).Init(Player.CurrentStar.StarDistances[1].Star as TStar);
    Station := TWB.Create;
    (Station as TWB).Init(Player.CurrentStar.StarDistances[0].Star as TStar);
    for I := 1 to Galaxy.Rangers.Count - 1 do begin
      Ranger := Galaxy.Rangers[I];
      for J := 1 to Round(RemapClamped(NextRandomIntRange(0, 1000, Ranger.RandomState), 0, 1000, 10, 50)) do Ranger.SimulateUnseenProgression;
    end;
    TryStartScriptByName(Player.CurrentStar, Player.CurrentPlanet, 'MS_First');
    NewGameGenerationStage := 3;
    Galaxy.AppendScoreIntegritySnapshot;
    CalculateGalaxyTurnAndWait;
    for I := 1 to 200 do begin
      CalculatePlayerStarTurnAndWait;
      CalculateGalaxyTurnAndWait;
    end;
  except
    AppendLogLineThreadSafe('Galaxy create exception');
  end;
end;
{ @end $60645C }

end.

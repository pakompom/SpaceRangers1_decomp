unit ThreadCalc;
// Unit bracket (inferred): CODE 0x005E237C..0x005E291F; inclusive evidence, not full bounds.
// Turn worker and synchronous entry points. Exceptions are logged and swallowed.
interface
uses EC_Thread;
type
  TTurnCalculationJob = (tcjGalaxy = 1, tcjPlayerStar = 2, tcjPreparePlayerStar = 3); // @size $04
  TThreadCalc = class(TThreadEC) // @size $30
  public
    Job: TTurnCalculationJob; // @offset $2C
    procedure Execute; override; // @addr $5E2468
  end;
procedure StartGalaxyTurnCalculation; // @addr $5E23D8
procedure StartPlayerStarTurnCalculation; // @addr $5E23F4
procedure StartPlayerStarPreparation; // @addr $5E2410
function IsTurnCalculationRunning: Boolean; // @addr $5E242C
procedure WaitForTurnCalculation; // @addr $5E2448
procedure ProcessGalaxyTurnSynchronously; // @addr $5E2728
procedure ProcessPlayerStarTurnSynchronously; // @addr $5E27A4
implementation

// @unit-initialization $5E2918
// @unit-finalization $5E28E8

uses Globals, Windows, MMSystem, GR_Main, aGalaxy, aPlayer, aRanger, aCalc;

{ @routine $5E23D8 StartGalaxyTurnCalculation }
procedure StartGalaxyTurnCalculation;
begin
  TurnCalculationThread.Job := tcjGalaxy;
  TurnCalculationThread.Start;
end;
{ @end $5E23D8 }

{ @routine $5E23F4 StartPlayerStarTurnCalculation }
procedure StartPlayerStarTurnCalculation;
begin
  TurnCalculationThread.Job := tcjPlayerStar;
  TurnCalculationThread.Start;
end;
{ @end $5E23F4 }

{ @routine $5E2410 StartPlayerStarPreparation }
procedure StartPlayerStarPreparation;
begin
  TurnCalculationThread.Job := tcjPreparePlayerStar;
  TurnCalculationThread.Start;
end;
{ @end $5E2410 }

{ @routine $5E242C IsTurnCalculationRunning }
function IsTurnCalculationRunning: Boolean;
begin
  if TurnCalculationThread = nil then Result := False
  else Result := TurnCalculationThread.IsRunning;
end;
{ @end $5E242C }

{ @routine $5E2448 WaitForTurnCalculation }
procedure WaitForTurnCalculation;
begin
  if TurnCalculationThread.IsRunning then TurnCalculationThread.WaitForIdle(INFINITE);
end;
{ @end $5E2448 }

{ @routine $5E2468 TThreadCalc_Execute }
procedure TThreadCalc.Execute;
var StartTick, EndTick: Cardinal;
begin
  if Job = tcjGalaxy then
  begin
    TurnCalculationPhase := 1;
    try
      if (Player <> nil) and Player.InNormalSpace then
      begin
        StartTick := timeGetTime;
        Galaxy.NextDay;
        EndTick := timeGetTime;
        if EndTick - StartTick < 400 then SysUtils.Sleep(400 - (EndTick - StartTick));
      end
      else Galaxy.NextDay;
    except
      AppendLogLineThreadSafe('ThreadCalc exception 1');
    end;
    TurnCalculationPhase := 2;
  end
  else if Job = tcjPlayerStar then
  begin
    TurnCalculationPhase := 3;
    try
      if not PlayerStarDayPrepared then PrimaryFilm.Clear;
      PlayerStar.NextDay(Player.InNormalSpace or
        (PlayerAutomaticControl and ((ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive) and
          ((Player.CurrentPlanet <> nil) or (Player.DockedTo <> nil))) or
        ((Player.Order = soTakeoff) and ((Player.CurrentPlanet <> nil) or (Player.DockedTo <> nil))) or
        (Player.InHyperspace and (Cardinal(Player.OrderStateData and TravelDaysMask) <= 1)));
      Galaxy.CompleteDay;
      Galaxy.TransferShipsInTransit;
      PlayerStarDayPrepared := False;
      if ShipDatabaseLoggingEnabled then Galaxy.AppendShipDatabaseLog;
    except
      AppendLogLineThreadSafe('ThreadCalc exception 2');
    end;
    TurnCalculationPhase := 4;
  end
  else
  begin
    TurnCalculationPhase := 5;
    PlayerStarDayPrepared := True;
    try
      PrimaryFilm.Clear;
      PlayerStar.PrepareNextDay;
    except
      AppendLogLineThreadSafe('ThreadCalc exception 3');
    end;
    TurnCalculationPhase := 6;
  end;
end;
{ @end $5E2468 }

{ @routine $5E2728 ProcessGalaxyTurnSynchronously }
procedure ProcessGalaxyTurnSynchronously;
begin
  TurnCalculationPhase := 1;
  try
    Galaxy.NextDay;
  except
    AppendLogLineThreadSafe('ThreadCalc exception 1');
  end;
  TurnCalculationPhase := 2;
end;
{ @end $5E2728 }

{ @routine $5E27A4 ProcessPlayerStarTurnSynchronously }
procedure ProcessPlayerStarTurnSynchronously;
begin
  TurnCalculationPhase := 3;
  try
    if not PlayerStarDayPrepared then PrimaryFilm.Clear;
    PlayerStar.NextDay(Player.InNormalSpace or
      (PlayerAutomaticControl and ((ScenarioState = scenAllianceAgainstRachekhan) or IsKlingMotherShipFollowActive) and
        ((Player.CurrentPlanet <> nil) or (Player.DockedTo <> nil))) or
      ((Player.Order = soTakeoff) and ((Player.CurrentPlanet <> nil) or (Player.DockedTo <> nil))) or
      (Player.InHyperspace and (Cardinal(Player.OrderStateData and TravelDaysMask) <= 1)));
    Galaxy.CompleteDay;
    Galaxy.TransferShipsInTransit;
    PlayerStarDayPrepared := False;
    if ShipDatabaseLoggingEnabled then Galaxy.AppendShipDatabaseLog;
  except
    AppendLogLineThreadSafe('ThreadCalc exception 2');
  end;
  TurnCalculationPhase := 4;
end;
{ @end $5E27A4 }

end.

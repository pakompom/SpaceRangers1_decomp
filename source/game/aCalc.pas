unit aCalc;
// Unit bracket (inferred): CODE 0x004D7890..0x004D7907; inclusive evidence, not full bounds.
// Turn-calculation UI interface.
interface
function IsTurnCalculationRunningUI: Boolean; // @addr $4D7898
var TurnCalculationPhase: Integer; // @addr $61C9C0
procedure QueueGalaxyTurnCalculation; // @addr $4D78AC
procedure QueuePlayerStarTurnCalculation; // @addr $4D78C0
procedure CalculateGalaxyTurnAndWait; // @addr $4D78A0
procedure CalculatePlayerStarTurnAndWait; // @addr $4D78B4
procedure WaitForTurnCalculationUI; // @addr $4D7890
procedure QueuePlayerStarPreparation; // @addr $4D78C8
implementation

// @unit-initialization $4D7900
// @unit-finalization $4D78D0

uses ThreadCalc;

{ @routine $4D7890 WaitForTurnCalculationUI }
procedure WaitForTurnCalculationUI;
begin
  ThreadCalc.WaitForTurnCalculation;
end;
{ @end $4D7890 }

{ @routine $4D7898 IsTurnCalculationRunningUI }
function IsTurnCalculationRunningUI: Boolean;
begin
  Result := ThreadCalc.IsTurnCalculationRunning;
end;
{ @end $4D7898 }

{ @routine $4D78A0 CalculateGalaxyTurnAndWait }
procedure CalculateGalaxyTurnAndWait;
begin
  ThreadCalc.StartGalaxyTurnCalculation;
  ThreadCalc.WaitForTurnCalculation;
end;
{ @end $4D78A0 }

{ @routine $4D78AC QueueGalaxyTurnCalculation }
procedure QueueGalaxyTurnCalculation;
begin
  ThreadCalc.StartGalaxyTurnCalculation;
end;
{ @end $4D78AC }

{ @routine $4D78B4 CalculatePlayerStarTurnAndWait }
procedure CalculatePlayerStarTurnAndWait;
begin
  ThreadCalc.StartPlayerStarTurnCalculation;
  ThreadCalc.WaitForTurnCalculation;
end;
{ @end $4D78B4 }

{ @routine $4D78C0 QueuePlayerStarTurnCalculation }
procedure QueuePlayerStarTurnCalculation;
begin
  ThreadCalc.StartPlayerStarTurnCalculation;
end;
{ @end $4D78C0 }

{ @routine $4D78C8 QueuePlayerStarPreparation }
procedure QueuePlayerStarPreparation;
begin
  ThreadCalc.StartPlayerStarPreparation;
end;
{ @end $4D78C8 }

end.

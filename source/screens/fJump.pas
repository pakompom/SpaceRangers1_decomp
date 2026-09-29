unit fJump;
// Unit bracket (inferred): CODE 0x00559C48..0x0055A2AB; inclusive evidence, not full bounds.
// Travel advances turn calculation before loading the destination's assets.
interface
uses GI_MessageLoop;
type
  TfJump = class(TMessageLoopGI) // @size $BC
  public
    TransitionTimer: TCallbackTimerIdGI; // @offset $B0
    LoadingStarted: Boolean; // @offset $B4
    NoPendingLoads: Boolean; // @offset $B5
    Progress: Single; // @offset $B8
    procedure OnOpen; override; // @addr $559CCC
    procedure OnClose; override; // @addr $559E08
    procedure AdvanceTravel(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $559E28
    procedure AdvanceLoading(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $559FC8
    procedure SetProgress(Value: Single); // @addr $55A188
    procedure SelectMusic; override; // @addr $55A270
  end;
implementation
// @unit-initialization $55A2A4
// @unit-finalization $55A274
uses SysUtils, Classes, Math, EC_Struct, GR_Main, GI_Main, GI_Image, Globals, GlobalsV,
  aPlayer, aShip, aGalaxy, aCalc, aScript, aMyFunction, fLoad, fStarMap;

{ @routine $559CCC TfJump_OnOpen }
procedure TfJump.OnOpen;
begin
  RunStarTransitionScript(Player.CurrentStar, 2);
  LoadingStarted := False;
  NoPendingLoads := False;
  TransitionTimer := ScheduleCallbackTimer(20, 20, AdvanceTravel);
  (GetByName('ImageBG') as TImageGI).SetImagePath('Bm.SI.' + GiResourceSuffix + 'gj' + IntToStr(RandomIntRange(0, 2)));
  Progress := 0;
  SetProgress(0);
  Present;
end;
{ @end $559CCC }

{ @routine $559E08 TfJump_OnClose }
procedure TfJump.OnClose;
begin
  if TransitionTimer <> 0 then
  begin
    CancelCallbackTimer(TransitionTimer);
    TransitionTimer := 0;
  end;
end;
{ @end $559E08 }

{ @routine $559E28 TfJump_AdvanceTravel }
procedure TfJump.AdvanceTravel(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var PreviousStar: TStar;
begin
  Progress := Progress + 0.008;
  if Progress > 0.49 then Progress := 0.5;
  SetProgress(Progress);
  if IsTurnCalculationRunningUI or (TurnCalculationPhase = 1) or (TurnCalculationPhase = 3) then Exit;
  if TurnCalculationPhase = 2 then
  begin
    QueuePlayerStarTurnCalculation;
  end
  else
  begin
    if not ((Player.Order = soJump) or (Player.Order = soEnterBlackHole)) or
      ((Player.Order = soEnterBlackHole) and (Player.OrderStateData = BlackHoleExitFlightState)) then
    begin
      QueueGalaxyTurnCalculation;
      StarMapScreen.SetMapCenterManually(TruncatePointF(Player.Position));
      StarMapScreen.ResumeMode := 2;
      AdvanceLoading(0, 0);
      Exit;
    end;
    Galaxy.ClearJumpGates;
    PreviousStar := PlayerStar;
    PlayerStar := Player.CurrentStar;
    PlayerStar.RebuildShipMovementPaths;
    PreviousStar.RebuildShipMovementPaths;
    if (Cardinal(Player.OrderStateData) and TravelDaysMask) = 1 then
    begin
      PruneExpiredPersistentPlayerMessages;
      RunStarTransitionScript(Player.CurrentStar, 3);
    end;
    Galaxy.GenerateSpaceBackground;
    QueueGalaxyTurnCalculation;
    Present;
  end;
end;
{ @end $559E28 }

{ @routine $559FC8 TfJump_AdvanceLoading }
procedure TfJump.AdvanceLoading(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Loads: TList;
begin
  if not LoadingStarted then
  begin
    LoadingStarted := True;
    if TransitionTimer <> 0 then
    begin
      CancelCallbackTimer(TransitionTimer);
      TransitionTimer := 0;
    end;
    Loads := TList.Create;
    QueueSpaceLoadingAssets(Loads, RootUiObject);
    if Loads.Count > 0 then
    begin
      CacheLoader.SetPendingLoads(Loads, True);
      TransitionTimer := ScheduleCallbackTimer(20, 20, AdvanceLoading);
    end
    else
    begin
      TransitionTimer := ScheduleCallbackTimer(20, 20, AdvanceLoading);
      NoPendingLoads := True;
      Loads.Free;
    end;
  end
  else
  begin
    if NoPendingLoads then Progress := Progress + 0.008
    else Progress := Min(Progress + 0.008, CacheLoader.CompletedLoadCount / CacheLoader.TotalLoadCount * 0.5 + 0.5);
    if Progress > 0.99 then Progress := 1;
    SetProgress(Progress);
    if (NoPendingLoads or not CacheLoader.IsRunning) and (Progress >= 1) then
    begin
      if TransitionTimer <> 0 then
      begin
        CancelCallbackTimer(TransitionTimer);
        TransitionTimer := 0;
      end;
      RequestedScreenId := screenStarMap;
      RequestClose(1);
    end;
  end;
end;
{ @end $559FC8 }

{ @routine $55A188 TfJump_SetProgress }
procedure TfJump.SetProgress(Value: Single);
var X: Integer;
begin
  X := Round(Cardinal(GameScreenWidth) * Value);
  with GetByName('PBmin') do
  begin
    SetActive(GameScreenWidth - X > 0);
    if Active then
    begin
      SetPosition(Classes.Point(X, LocalPosition.Y));
      SetSize(Classes.Point(GameScreenWidth - X, ClientSize.Y));
    end;
  end;
  with GetByName('PBmax') do
  begin
    SetActive(X > 0);
    if Active then SetSize(Classes.Point(X, ClientSize.Y));
  end;
end;
{ @end $55A188 }

{ @routine $55A270 TfJump_SelectMusic }
procedure TfJump.SelectMusic;
begin
end;
{ @end $55A270 }
end.

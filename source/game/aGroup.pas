unit aGroup;
// Unit bracket (inferred): CODE 0x004E0B14..0x004E1843; inclusive evidence, not full bounds.
// Native VMT $4E0B30; Create, SaveToBuffer and LoadFromBuffer establish the layout.
interface
uses Classes, EC_Buf, EC_Struct, aGalaxy, aShip;
type
  TGroupRouteOrder = record // @size $14
    Kind: TShipOrder; // @offset $00
    Target: TObject; // @offset $04 Object ID until ResolveLoadedReferences.
    Destination: TPointF; // @offset $08
    WaitMode: Byte; // @offset $10
  end;
  TGroup = class(TObjectEx) // @size $1C
  public
    function FindCentralMemberStar: TStar; // @addr $4E1754 Chooses a member's current star minimizing summed rounded distances to all galaxy planets.
    function GetShipGreeting(Ship: TShip): WideString; // @addr $4E1618
    CreatedTurn: Integer; // @offset $04 Serialized as Word.
    GenerationSeed: Cardinal; // @offset $08
    RandomState: Cardinal; // @offset $0C
    GroupKind: Byte; // @offset $10 Only kind zero is handled by Disband; other meanings unresolved.
    Ships: TList; // @offset $14 Borrowed TShip entries; Destroy frees the list.
    Route: array of TGroupRouteOrder; // @offset $18 Owned dynamic array; object references are borrowed.
    constructor Create; // @addr $4E0B98
    destructor Destroy; override; // @addr $4E0C40
    procedure Save(Buffer: TBufEC); // @addr $4E0C78
    procedure Load(Buffer: TBufEC); // @addr $4E0E20
    procedure ResolveLoadedReferences; // @addr $4E0F98
    procedure AddShip(Ship: TShip); // @addr $4E113C
    procedure NextDay; // @addr $4E1160
    procedure Disband; // @addr $4E119C
    procedure BuildLiberationOrders; // @addr $4E11F8
    procedure AdvanceRouteForShips; // @addr $4E15C8
    function AreShipsAssembled: Boolean; // @addr $4E1548 Requires a nonempty list; native code reads Ships[0] first.
  end;
implementation

// @unit-initialization $4E183C
// @unit-finalization $4E180C

uses SysUtils, aPlanet, aMyFunction, aConst;

{ @routine $4E0B98 TGroup_Create }
constructor TGroup.Create;
begin
  inherited Create;
  CreatedTurn := Galaxy.CurrentTurn;
  GenerationSeed := SeededRandomIntRange(100000, MaxInt, Galaxy.GenerationSeed * Galaxy.CurrentTurn);
  RandomState := GenerationSeed;
  Ships := TList.Create;
  SetLength(Route, 0);
  Route := nil;
end;
{ @end $4E0B98 }

{ @routine $4E0C40 TGroup_Destroy }
destructor TGroup.Destroy;
begin
  if Ships <> nil then begin Ships.Free; Ships := nil; end;
  inherited Destroy;
end;
{ @end $4E0C40 }

{ @routine $4E0C78 TGroup_Save }
procedure TGroup.Save(Buffer: TBufEC);
var I, Count: Integer; Ship: TShip; Order: TGroupRouteOrder;
begin
  Buffer.AddWideChar(WideChar(CreatedTurn));
  Buffer.AddDWord(GenerationSeed);
  Buffer.AddDWord(RandomState);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(GroupKind)));
  Count := Ships.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin Ship := Ships[I]; Buffer.AddDWord(Ship.Id); end;
  Count := Length(Route);
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do begin
    Order := Route[I];
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Order.Kind)));
    if Order.Kind = soJump then Buffer.AddDWord((Order.Target as TStar).Id)
    else if Order.Kind = soEnterBlackHole then Buffer.AddDWord((Order.Target as THole).Id)
    else if Order.Kind = soLanding then
    begin
      if Order.Target is TShip then Buffer.AddDWord(Cardinal((Order.Target as TShip).Id) or $80000000)
      else Buffer.AddDWord((Order.Target as TPlanet).Id);
    end
    else if Order.Kind = soFollowShip then Buffer.AddDWord((Order.Target as TShip).Id)
    else Buffer.AddDWord(0);
    Buffer.AddSingle(Order.Destination.X);
    Buffer.AddSingle(Order.Destination.Y);
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Order.WaitMode)));
  end;
end;
{ @end $4E0C78 }

{ @routine $4E0E20 TGroup_Load }
procedure TGroup.Load(Buffer: TBufEC);
var I, Count: Integer;
begin
  CreatedTurn := Buffer.GetWord;
  GenerationSeed := Buffer.GetUInt32;
  RandomState := Buffer.GetUInt32;
  WriteByteValue(Buffer.GetByte, GroupKind);
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err TGroup.Load FShips');
  for I := 0 to Count - 1 do Ships.Add(Pointer(Buffer.GetUInt32));
  Count := Buffer.GetWord;
  if (Count < 0) or (Count > 10000) then raise EAbort.Create('Err TGroup.Load FOrders');
  SetLength(Route, Count);
  for I := 0 to Count - 1 do begin
    WriteByteValue(Buffer.GetByte, Route[I].Kind);
    Route[I].Target := TObject(Buffer.GetUInt32);
    Route[I].Destination.X := Buffer.GetSingle;
    Route[I].Destination.Y := Buffer.GetSingle;
    WriteByteValue(Buffer.GetByte, Route[I].WaitMode);
  end;
end;
{ @end $4E0E20 }

{ @routine $4E0F98 TGroup_ResolveLoadedReferences }
procedure TGroup.ResolveLoadedReferences;
var I: Integer; Ship: TShip;
begin
  for I := 0 to Ships.Count - 1 do begin
    Ships[I] := Galaxy.IdToShip(Cardinal(Ships[I]), True) as TShip;
    Ship := Ships[I];
    Ship.LiberationGroup := Self;
  end;
  for I := 0 to Length(Route) - 1 do begin
    if Route[I].Kind = soJump then Route[I].Target := Galaxy.IdToStar(Cardinal(Route[I].Target)) as TStar
    else if Route[I].Kind = soEnterBlackHole then Route[I].Target := Galaxy.IdToHole(Cardinal(Route[I].Target)) as THole
    else if Route[I].Kind = soLanding then
    begin
      if Cardinal(Route[I].Target) and $80000000 = $80000000 then
        Route[I].Target := Galaxy.IdToShip(Cardinal(Route[I].Target) and $7FFFFFFF, True) as TShip
      else Route[I].Target := Galaxy.IdToPlanet(Cardinal(Route[I].Target)) as TPlanet;
    end
    else if Route[I].Kind = soFollowShip then Route[I].Target := Galaxy.IdToShip(Cardinal(Route[I].Target), True) as TShip
    else Route[I].Target := nil;
  end;
end;
{ @end $4E0F98 }

{ @routine $4E113C TGroup_AddShip }
procedure TGroup.AddShip(Ship: TShip);
begin
  Ships.Add(Ship);
  Ship.LiberationGroup := Self;
  Ship.LiberationGroupRouteIndex := 0;
end;
{ @end $4E113C }

{ @routine $4E1160 TGroup_NextDay }
procedure TGroup.NextDay;
begin
  if Ships.Count = 0 then begin
    Galaxy.LiberationGroups.Delete(Galaxy.LiberationGroups.IndexOf(Self));
    Free;
  end;
end;
{ @end $4E1160 }

{ @routine $4E119C TGroup_Disband }
procedure TGroup.Disband;
var I: Integer; Ship: TShip;
begin
  case GroupKind of
    0:
    begin
      for I := Ships.Count - 1 downto 0 do
      begin
        Ship := Ships[I];
        Ship.LeaveLiberationGroup;
      end;
      Galaxy.LiberationGroups.Delete(Galaxy.LiberationGroups.IndexOf(Self));
      Free;
    end;
  end;
end;
{ @end $4E119C }

{ @routine $4E11F8 TGroup_BuildLiberationOrders }
procedure TGroup.BuildLiberationOrders;
var Planet: TPlanet; Text: WideString; TargetStar, AssemblyStar: TStar; Attempts: Integer;
begin
  case GroupKind of
  0: begin
    TargetStar := Galaxy.SelectStarForLiberationAttack(FindCentralMemberStar);
    Attempts := 0;
    while (TargetStar = nil) or TargetStar.HasLiberationGroupOrder do
    begin
      if Attempts > 10 then
      begin
        Disband;
        Exit;
      end;
      TargetStar := Galaxy.SelectStarForLiberationAttack(FindCentralMemberStar);
      Inc(Attempts);
    end;
    SetLength(Route, 4);
    AssemblyStar := TargetStar.FindNearestStarByFaction(sfCoalition, False);
    if (AssemblyStar = nil) or (PointDistance(AssemblyStar.Position, TargetStar.Position) > 28) then
    begin
      Disband;
      Exit;
    end;
    with Route[0] do begin Kind := soJump; Target := AssemblyStar; WaitMode := 0; end;
    Planet := AssemblyStar.FindFirstInhabitedPlanet as TPlanet;
    if Planet = nil then
    begin
      Disband;
      Exit;
    end;
    with Route[1] do begin Kind := soLanding; Target := Planet; WaitMode := 0; end;
    with Route[2] do
    begin
      Kind := soMove;
      Target := nil;
      Destination := AssemblyStar.GetBoundaryPointTowardStar(TargetStar);
      WaitMode := 2;
    end;
    with Route[3] do begin Kind := soJump; Target := TargetStar; WaitMode := 0; end;
    Text := PickLocalizedTextVariant('GalaxyNews.Group.WarriorLiberator.Create', RandomState * (Galaxy.CurrentTurn div 10));
    ReplaceTextToken(Text, '<StarNormal>', AssemblyStar.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<StarEnemy>', TargetStar.Name, HighlightColorTag);
    ReplaceTextToken(Text, '<SectorNormal>', AssemblyStar.Constellation.GetName, HighlightColorTag);
    ReplaceTextToken(Text, '<SectorEnemy>', TargetStar.Constellation.GetName, HighlightColorTag);
    if Galaxy.CountPlanetNewsByType(gnWarriorLiberatorGroup) = 0 then Galaxy.AddPlanetNews(gnWarriorLiberatorGroup, Text);
  end;
  end;
end;
{ @end $4E11F8 }

{ @routine $4E1548 TGroup_AreShipsAssembled }
function TGroup.AreShipsAssembled: Boolean;
var I, OrderIndex: Integer; Ship: TShip;
begin
  Ship := Ships[0];
  OrderIndex := Ship.LiberationGroupRouteIndex;
  for I := 0 to Ships.Count - 1 do begin
    Ship := Ships[I];
    if (Ship.LiberationGroupRouteIndex <> OrderIndex) or not (Ship.Order in [soNone, soMove]) or
      (PointDistanceSquared(Ship.Position, Route[OrderIndex].Destination) > 300 * 300) then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;
{ @end $4E1548 }

{ @routine $4E15C8 TGroup_AdvanceRouteForShips }
procedure TGroup.AdvanceRouteForShips;
var I: Integer; Ship: TShip;
begin
  for I := Ships.Count - 1 downto 0 do begin
    Ship := Ships[I];
    Inc(Ship.LiberationGroupRouteIndex);
    if Ship.LiberationGroupRouteIndex >= Length(Route) then Ship.LeaveLiberationGroup
    else Ship.ProcessLiberationGroupRoute;
  end;
end;
{ @end $4E15C8 }

{ @routine $4E1618 TGroup_GetShipGreeting }
function TGroup.GetShipGreeting(Ship: TShip): WideString;
var Star: TStar;
begin
  Result := '';
  case GroupKind of
    0: if Ship.LiberationGroupRouteIndex <> 0 then
    begin
      Star := Route[3].Target as TStar;
      Result := FormatText1(PickLocalizedTextVariant('ShipGreetings.Group.WarriorLiberator',
        NextRandomIntRange(100, 1000, RandomState)), HighlightColorTag, '<StarEnemy>', Star.Name);
    end;
  end;
end;
{ @end $4E1618 }

{ @routine $4E1754 TGroup_FindCentralMemberStar }
function TGroup.FindCentralMemberStar: TStar;
var I, J, Distance, BestDistance: Integer; Ship: TShip; Planet: TPlanet;
begin
  Result := nil;
  BestDistance := MaxInt;
  for I := Ships.Count - 1 downto 0 do begin
    Ship := Ships[I];
    Distance := 0;
    for J := 0 to Galaxy.Planets.Count - 1 do begin
      Planet := Galaxy.Planets[J];
      Inc(Distance, Round(PointDistance(Ship.CurrentStar.Position, Planet.CurrentStar.Position)));
    end;
    if BestDistance > Distance then begin Result := Ship.CurrentStar; BestDistance := Distance; end;
  end;
end;
{ @end $4E1754 }

end.

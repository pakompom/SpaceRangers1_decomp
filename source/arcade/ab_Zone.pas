unit ab_Zone;
// Unit bracket (inferred): CODE 0x0050EA30..0x00510453; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Struct, GI_PolyLine, GI_Tail, ab_Global, ab_WorldImage, ab_WorldLine;

type
  TabZoneWorldLines = array of PabWorldLine;
  PabZone = ^TabZone;
  TabZone = record // @size $90
    Prev: PabZone; // @offset $00
    Next: PabZone; // @offset $04
    RouteIndex: Integer; // @offset $08
    Longitude: Double; // @offset $10
    PolarAngle: Double; // @offset $18
    RadiusDegrees: Double; // @offset $20
    Radius: Double; // @offset $28
    Position: TVector3D; // @offset $30
    RouteDistance: Double; // @offset $48
    Routes: TList; // @offset $50
    WorldLines: array of PabWorldLine; // @offset $54
    WorldImage: PabWorldImage; // @offset $58
    Name: WideString; // @offset $5C
    BarrierHealth: Integer; // @offset $60  Initial wall health for kinds 5..8; TfAB.EnterCurrentSpace ($54E7DC).
    GravityStrength: Integer; // @offset $64  Signed attraction/repulsion strength.
    DamagePerTick: Integer; // @offset $68  Negative values heal.
    BonusFlags: Cardinal; // @offset $6C Low eight bits select bonuses; bit 31 conceals the bonus icon.
    BonusRespawnClass: Integer; // @offset $70 Selects a min/max pair in BonusRespawnSeconds (three intervals).
    NextBonusTick: Integer; // @offset $74 -1 while a spawned bonus is present.
    Kind: Integer; // @offset $78 Values below 5 participate in route tables.
    Segments: array[0..3] of PPolyLineSegmentGI; // @offset $7C
  end;

  PabZoneLink = ^TabZoneLink;
  TabZoneLink = record // @size $28
    Prev: PabZoneLink; // @offset $00
    Next: PabZoneLink; // @offset $04
    First: PabZone; // @offset $08
    Last: PabZone; // @offset $0C
    Distance: Double; // @offset $10
    BarrierLinkMode: Integer; // @offset $18  Mode 1 creates collidable links between compatible barrier zones ($54E7DC).
    WorldLine: PabWorldLine; // @offset $1C
    Segments: array[0..1] of PPolyLineSegmentGI; // @offset $20
  end;

procedure ab_Zone_Clear; // @addr $50EA4C
function ab_Zone_Add: PabZone; // @addr $50EA80
procedure ab_Zone_Delete(Zone: PabZone); // @addr $50EB20
procedure ab_Zone_UpdatePosition(Zone: PabZone); // @addr $50EC1C
procedure ab_Zone_UpdateImages(Zone: PabZone); // @addr $50ECB4
procedure ab_Zone_ClearImages; // @addr $50F034
procedure ab_Zone_ClearSegments(Zone: PabZone); // @addr $50F2C0
function ab_Zone_CountKind(Kind: Integer): Integer; // @addr $50F374
procedure ab_ZoneLink_Clear; // @addr $50F3F0
function ab_ZoneLink_Add: PabZoneLink; // @addr $50F424
procedure ab_ZoneLink_Delete(Link: PabZoneLink); // @addr $50F4C8
procedure ab_ZoneLink_UpdateDistance(Link: PabZoneLink); // @addr $50F540
procedure ab_ZoneLink_ClearImages; // @addr $50F618
procedure ab_ZoneLink_ClearSegments(Link: PabZoneLink); // @addr $50F89C
procedure ab_Zone_Load(Buffer: TBufEC); // @addr $50FC6C
function ab_Zone_RandomKind(Kind: Integer): PabZone; // @addr $50FD94
function ab_Zone_RandomPosition(Zone: PabZone): TSphericalBearingState; // @addr $50FDB4
function ab_Zone_FindContainingOrNearest(Longitude, PolarAngle: Double; var Nearest: PabZone): Boolean; // @addr $50FE28
function ab_Zone_FindNearestOutside(Longitude, PolarAngle: Double): PabZone; // @addr $50FECC
function ab_Zone_FindNearestEnabled(Longitude, PolarAngle: Double): PabZone; // @addr $50FF58
function ab_Zone_IsInsideKind10(Longitude, PolarAngle: Double): Boolean; // @addr $50FFF4

procedure ab_Zone_BuildRoutes(Zone: PabZone); // @addr $5101A0
procedure ab_Zone_BuildAllRoutes; // @addr $5101F0
function ab_Zone_GetRoute(Source, Target: PabZone): PabZone; // @addr $51021C
function ab_Zone_IsHeadingInside(Source: TSphericalBearingState; Zone: PabZone; var BearingDelta, AngularRadius: Double): Boolean; // @addr $510234
function ab_Zone_FindReachableRouteZone(Source: PabZone): PabZone; // @addr $5102E0
function ab_Zone_RandomRoute(Source: PabZone; Steps: Integer): PabZone; // @addr $510398

var
  ZoneHeap: Cardinal = 0; // @addr $61871C
  FirstZone: PabZone = nil; // @addr $618720
  LastZone: PabZone = nil; // @addr $618724
  SelectedZone: PabZone = nil; // @addr $618728
  ZoneLinkHeap: Cardinal = 0; // @addr $61872C
  FirstZoneLink: PabZoneLink = nil; // @addr $618730
  LastZoneLink: PabZoneLink = nil; // @addr $618734
  SelectedZoneLink: PabZoneLink = nil; // @addr $618738

function ab_Zone_Get(Index: Integer): PabZone; // @addr $50F3B0

function ab_Zone_GetKind(Kind, Index: Integer): PabZone; // @addr $50F3CC

function ab_Zone_FindRoute(Source, Target: PabZone): PabZone; // @addr $5100D0

procedure ab_Zone_UpdateAllPositions; // @addr $50EC98
procedure ab_Zone_UpdateAllImages; // @addr $50F018
procedure ab_ZoneLink_UpdateAllDistances; // @addr $50F584
procedure ab_ZoneLink_UpdateAllImages; // @addr $50F5FC
function ab_Zone_Count: Integer; // @addr $50F35C
function ab_ZoneLink_Count: Integer; // @addr $50FBB0
function ab_Zone_IndexOf(Target: PabZone): Integer; // @addr $50F390
function ab_Zone_FindAtAngles(Longitude, PolarAngle: Double): PabZone; // @addr $50F2F4
procedure ab_ZoneLink_UpdateImages(Link: PabZoneLink); // @addr $50F5A0
function ab_ZoneLink_Find(First, Last: PabZone): PabZoneLink; // @addr $50F8D0
procedure ab_Zone_Save(Buffer: TBufEC); // @addr $50FBC8

procedure ab_Zone_DrawSelection(Entry: PabZone); // @addr $50F0A0
procedure ab_ZoneLink_DrawSelection(Entry: PabZoneLink); // @addr $50F640

function ab_ZoneLink_FindAtAngles(Longitude, PolarAngle: Double): PabZoneLink; // @addr $50FA44

implementation

// @unit-initialization $51044C
// @unit-finalization $51041C

uses Windows, SysUtils, Math, EC_Mem, GR_Main, Globals, aMyFunction, ab_StopLine;

{ @routine $50EA4C ab_Zone_Clear }
procedure ab_Zone_Clear;
begin
  while FirstZone <> nil do ab_Zone_Delete(LastZone);
  if ZoneHeap <> 0 then
  begin
    HeapDestroy(ZoneHeap);
    ZoneHeap := 0;
  end;
end;
{ @end $50EA4C }

{ @routine $50EA80 ab_Zone_Add }
function ab_Zone_Add: PabZone;
var
  Entry: PabZone;
begin
  if ZoneHeap = 0 then
  begin
    ZoneHeap := HeapCreate(1, $8000, 0);
    if ZoneHeap = 0 then raise Exception.Create('ab_Zone_Add.HeapCreate');
  end;
  Entry := AllocClearFromHeapEC(ZoneHeap, SizeOf(TabZone));
  if LastZone <> nil then LastZone.Next := Entry;
  Entry.Prev := LastZone;
  Entry.Next := nil;
  LastZone := Entry;
  if FirstZone = nil then FirstZone := Entry;
  Result := Entry;
end;
{ @end $50EA80 }

{ @routine $50EB20 ab_Zone_Delete }
procedure ab_Zone_Delete(Zone: PabZone);
var
  Index: Integer;
  Link, NextLink: PabZoneLink;
begin
  if Zone.Prev <> nil then Zone.Prev.Next := Zone.Next;
  if Zone.Next <> nil then Zone.Next.Prev := Zone.Prev;
  if LastZone = Zone then LastZone := Zone.Prev;
  if FirstZone = Zone then FirstZone := Zone.Next;
  Link := FirstZoneLink;
  while Link <> nil do
  begin
    NextLink := Link;
    Link := Link.Next;
    if (NextLink.First = Zone) or (NextLink.Last = Zone) then ab_ZoneLink_Delete(NextLink);
  end;
  if Zone.WorldLines <> nil then
  begin
    for Index := 0 to High(Zone.WorldLines) do
      if Zone.WorldLines[Index] <> nil then
      begin
        ab_WorldLine_Delete(Zone.WorldLines[Index]);
        Zone.WorldLines[Index] := nil;
      end;
    Zone.WorldLines := nil;
  end;
  if Zone.WorldImage <> nil then
  begin
    ab_WorldImage_Delete(Zone.WorldImage);
    Zone.WorldImage := nil;
  end;
  ab_Zone_ClearSegments(Zone);
  if Zone.Routes <> nil then
  begin
    Zone.Routes.Free;
    Zone.Routes := nil;
  end;
  if SelectedZone = Zone then SelectedZone := nil;
  Zone.WorldImage := nil;
  Zone.Name := '';
  if ZoneHeap <> 0 then FreeFromHeapEC(ZoneHeap, Zone);
end;
{ @end $50EB20 }

{ @routine $50EC1C ab_Zone_UpdatePosition }
procedure ab_Zone_UpdatePosition(Zone: PabZone);
begin
  Zone.Radius := Pi * SphereRadius * Zone.RadiusDegrees / 180;
  Zone.Position := SphericalToVector3D(HeadingDegreesToRadians(Zone.Longitude), HeadingDegreesToRadians(Zone.PolarAngle), SphereRadius);
end;
{ @end $50EC1C }

{ @routine $50EC98 ab_Zone_UpdateAllPositions }
procedure ab_Zone_UpdateAllPositions;
var Entry: PabZone;
begin
  Entry := FirstZone;
  while Entry <> nil do begin
    ab_Zone_UpdatePosition(Entry);
    Entry := Entry.Next;
  end;
end;
{ @end $50EC98 }

{ @routine $50ECB4 ab_Zone_UpdateImages }
procedure ab_Zone_UpdateImages(Zone: PabZone);
var
  Index: Integer;
  Bearing, Step: Double;
  Color: Cardinal;
  Last, First: TVector3D;
  FirstState, LastState: TSphericalBearingState;
begin
  if Zone.Kind = 1 then Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255)
  else if Zone.Kind = 2 then Color := CurrentPixelFormat.PackRgbBytes(255, 0, 0)
  else if Zone.Kind = 3 then Color := CurrentPixelFormat.PackRgbBytes(0, 255, 0)
  else if Zone.Kind = 4 then Color := CurrentPixelFormat.PackRgbBytes(0, 0, 255)
  else if Zone.Kind = 5 then Color := CurrentPixelFormat.PackRgbBytes(0, 155, 155)
  else if Zone.Kind = 6 then Color := CurrentPixelFormat.PackRgbBytes(0, 255, 255)
  else if Zone.Kind = 20 then Color := CurrentPixelFormat.PackRgbBytes(255, 255, 0)
  else Color := CurrentPixelFormat.PackRgbBytes(200, 200, 0);
  if Zone.WorldLines = nil then
  begin
    SetLength(Zone.WorldLines, 32);
    for Index := 0 to High(Zone.WorldLines) do Zone.WorldLines[Index] := nil;
  end;
  for Index := 0 to High(Zone.WorldLines) do
    if Zone.WorldLines[Index] = nil then
      Zone.WorldLines[Index] := ab_WorldLine_Create(MakeVector3D(0, 0, 0), MakeVector3D(0, 0, 0), 1, Color, 0, False);
  Step := 360 / ((High(Zone.WorldLines) + 1) - 1);
  Bearing := -Step;
  FirstState := AdvanceSphericalStateOnCurrentSphere(MakeSphericalBearingState(Zone.Longitude, Zone.PolarAngle, Bearing), Zone.Radius);
  First := SphericalToVector3D(HeadingDegreesToRadians(FirstState.LongitudeDegrees), HeadingDegreesToRadians(FirstState.PolarAngleDegrees), SphereRadius);
  for Index := 0 to High(Zone.WorldLines) do
  begin
    Bearing := Bearing + Step;
    LastState := AdvanceSphericalStateOnCurrentSphere(MakeSphericalBearingState(Zone.Longitude, Zone.PolarAngle, Bearing), Zone.Radius);
    Last := SphericalToVector3D(HeadingDegreesToRadians(LastState.LongitudeDegrees), HeadingDegreesToRadians(LastState.PolarAngleDegrees), SphereRadius);
    ab_WorldLine_Set(Zone.WorldLines[Index], First, Last, 1, Color, 0, False);
    First := Last;
  end;
  if Zone.Kind <> 20 then
  begin
    if Zone.WorldImage = nil then
      Zone.WorldImage := ab_WorldImage_Create(Zone.Position, 'GI,Bm.PI.Path4', '', False)
    else
      ab_WorldImage_Set(Zone.WorldImage, Zone.Position, 'GI,Bm.PI.Path4', '');
  end;
end;
{ @end $50ECB4 }

{ @routine $50F018 ab_Zone_UpdateAllImages }
procedure ab_Zone_UpdateAllImages;
var Entry: PabZone;
begin
  Entry := FirstZone;
  while Entry <> nil do begin
    ab_Zone_UpdateImages(Entry);
    Entry := Entry.Next;
  end;
end;
{ @end $50F018 }

{ @routine $50F034 ab_Zone_ClearImages }
procedure ab_Zone_ClearImages;
var
  Zone: PabZone;
  Index: Integer;
begin
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.WorldLines <> nil then
    begin
      for Index := 0 to High(Zone.WorldLines) do
        if Zone.WorldLines[Index] <> nil then
        begin
          ab_WorldLine_Delete(Zone.WorldLines[Index]);
          Zone.WorldLines[Index] := nil;
        end;
      Zone.WorldLines := nil;
    end;
    if Zone.WorldImage <> nil then
    begin
      ab_WorldImage_Delete(Zone.WorldImage);
      Zone.WorldImage := nil;
    end;
    Zone := Zone.Next;
  end;
end;
{ @end $50F034 }

{ @routine $50F0A0 ab_Zone_DrawSelection }
procedure ab_Zone_DrawSelection(Entry: PabZone);
var Center: TPoint; Position: TVector3D; I, Radius: Integer;
begin
  for I := 0 to 3 do
    if Entry.Segments[I] = nil then begin
      Entry.Segments[I] := ArcadeBattleScreen.WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0),
        CurrentPixelFormat.PackRgbBytes(255, 0, 0));
      Entry.Segments[I].Animated := True;
    end;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Entry.Position);
  Center.X := Round(Position.X);
  Center.Y := Round(Position.Y);
  Radius := 10;
  Entry.Segments[0].First := Classes.Point(Center.X - Radius, Center.Y - Radius);
  Entry.Segments[0].Last := Classes.Point(Center.X + Radius, Center.Y - Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[0]);
  Entry.Segments[1].First := Classes.Point(Center.X + Radius, Center.Y - Radius);
  Entry.Segments[1].Last := Classes.Point(Center.X + Radius, Center.Y + Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[1]);
  Entry.Segments[2].First := Classes.Point(Center.X + Radius, Center.Y + Radius);
  Entry.Segments[2].Last := Classes.Point(Center.X - Radius, Center.Y + Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[2]);
  Entry.Segments[3].First := Classes.Point(Center.X - Radius, Center.Y + Radius);
  Entry.Segments[3].Last := Classes.Point(Center.X - Radius, Center.Y - Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[3]);
end;
{ @end $50F0A0 }

{ @routine $50F2C0 ab_Zone_ClearSegments }
procedure ab_Zone_ClearSegments(Zone: PabZone);
var
  Index: Integer;
begin
  for Index := 0 to 3 do
    if Zone.Segments[Index] <> nil then
    begin
      ArcadeBattleScreen.WorldLines.RetireSegment(Zone.Segments[Index]);
      Zone.Segments[Index] := nil;
    end;
end;
{ @end $50F2C0 }

{ @routine $50F2F4 ab_Zone_FindAtAngles }
function ab_Zone_FindAtAngles(Longitude, PolarAngle: Double): PabZone;
var Entry: PabZone; Bearing, Distance: Double;
begin
  Entry := FirstZone;
  while Entry <> nil do begin
    ComputeSphericalBearingAndDistance(Entry.Longitude, Entry.PolarAngle,
      0, Longitude, PolarAngle, SphereRadius, Bearing, Distance);
    if Distance < 15 then begin
      Result := Entry;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $50F2F4 }

{ @routine $50F35C ab_Zone_Count }
function ab_Zone_Count: Integer;
var Entry: PabZone;
begin
  Result := 0;
  Entry := FirstZone;
  while Entry <> nil do begin
    Inc(Result);
    Entry := Entry.Next;
  end;
end;
{ @end $50F35C }

{ @routine $50F374 ab_Zone_CountKind }
function ab_Zone_CountKind(Kind: Integer): Integer;
var
  Zone: PabZone;
begin
  Result := 0;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.Kind = Kind then Inc(Result);
    Zone := Zone.Next;
  end;
end;
{ @end $50F374 }

{ @routine $50F390 ab_Zone_IndexOf }
function ab_Zone_IndexOf(Target: PabZone): Integer;
var Entry: PabZone;
begin
  Result := 0;
  Entry := FirstZone;
  while Entry <> nil do begin
    if Entry = Target then Exit;
    Inc(Result);
    Entry := Entry.Next;
  end;
  Result := -1;
end;
{ @end $50F390 }

{ @routine $50F3B0 ab_Zone_Get }
function ab_Zone_Get(Index: Integer): PabZone;
var
  Zone: PabZone;
begin
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Index = 0 then
    begin
      Result := Zone;
      Exit;
    end;
    Dec(Index);
    Zone := Zone.Next;
  end;
  Result := nil;
end;
{ @end $50F3B0 }

{ @routine $50F3CC ab_Zone_GetKind }
function ab_Zone_GetKind(Kind, Index: Integer): PabZone;
var
  Zone: PabZone;
begin
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.Kind = Kind then
    begin
      if Index = 0 then
      begin
        Result := Zone;
        Exit;
      end;
      Dec(Index);
    end;
    Zone := Zone.Next;
  end;
  Result := nil;
end;
{ @end $50F3CC }

{ @routine $50F3F0 ab_ZoneLink_Clear }
procedure ab_ZoneLink_Clear;
begin
  while FirstZoneLink <> nil do ab_ZoneLink_Delete(LastZoneLink);
  if ZoneLinkHeap <> 0 then
  begin
    HeapDestroy(ZoneLinkHeap);
    ZoneLinkHeap := 0;
  end;
end;
{ @end $50F3F0 }

{ @routine $50F424 ab_ZoneLink_Add }
function ab_ZoneLink_Add: PabZoneLink;
var
  Entry: PabZoneLink;
begin
  if ZoneLinkHeap = 0 then
  begin
    ZoneLinkHeap := HeapCreate(1, $8000, 0);
    if ZoneLinkHeap = 0 then raise Exception.Create('ab_ZoneLink_Add.HeapCreate');
  end;
  Entry := AllocClearFromHeapEC(ZoneLinkHeap, SizeOf(TabZoneLink));
  if LastZoneLink <> nil then LastZoneLink.Next := Entry;
  Entry.Prev := LastZoneLink;
  Entry.Next := nil;
  LastZoneLink := Entry;
  if FirstZoneLink = nil then FirstZoneLink := Entry;
  Result := Entry;
end;
{ @end $50F424 }

{ @routine $50F4C8 ab_ZoneLink_Delete }
procedure ab_ZoneLink_Delete(Link: PabZoneLink);
begin
  if Link.Prev <> nil then Link.Prev.Next := Link.Next;
  if Link.Next <> nil then Link.Next.Prev := Link.Prev;
  if LastZoneLink = Link then LastZoneLink := Link.Prev;
  if FirstZoneLink = Link then FirstZoneLink := Link.Next;
  if Link.WorldLine <> nil then
  begin
    ab_WorldLine_Delete(Link.WorldLine);
    Link.WorldLine := nil;
  end;
  ab_ZoneLink_ClearSegments(Link);
  if SelectedZoneLink = Link then SelectedZoneLink := nil;
  if ZoneLinkHeap <> 0 then FreeFromHeapEC(ZoneLinkHeap, Link);
end;
{ @end $50F4C8 }

{ @routine $50F540 ab_ZoneLink_UpdateDistance }
procedure ab_ZoneLink_UpdateDistance(Link: PabZoneLink);
var
  Bearing: Double;
begin
  ComputeSphericalBearingAndDistance(Link.First.Longitude, Link.First.PolarAngle, 0, Link.Last.Longitude, Link.Last.PolarAngle, SphereRadius, Bearing, Link.Distance);
end;
{ @end $50F540 }

{ @routine $50F584 ab_ZoneLink_UpdateAllDistances }
procedure ab_ZoneLink_UpdateAllDistances;
var Entry: PabZoneLink;
begin
  Entry := FirstZoneLink;
  while Entry <> nil do begin
    ab_ZoneLink_UpdateDistance(Entry);
    Entry := Entry.Next;
  end;
end;
{ @end $50F584 }

{ @routine $50F5A0 ab_ZoneLink_UpdateImages }
procedure ab_ZoneLink_UpdateImages(Link: PabZoneLink);
var Color: Cardinal;
begin
  Color := CurrentPixelFormat.PackRgbBytes(200, 200, 0);
  if Link.WorldLine = nil then
    Link.WorldLine := ab_WorldLine_Create(Link.First.Position, Link.Last.Position, 1, Color, 0, False)
  else ab_WorldLine_Set(Link.WorldLine, Link.First.Position, Link.Last.Position, 1, Color, 0, False);
end;
{ @end $50F5A0 }

{ @routine $50F5FC ab_ZoneLink_UpdateAllImages }
procedure ab_ZoneLink_UpdateAllImages;
var Entry: PabZoneLink;
begin
  Entry := FirstZoneLink;
  while Entry <> nil do begin
    ab_ZoneLink_UpdateImages(Entry);
    Entry := Entry.Next;
  end;
end;
{ @end $50F5FC }

{ @routine $50F618 ab_ZoneLink_ClearImages }
procedure ab_ZoneLink_ClearImages;
var
  Link: PabZoneLink;
begin
  Link := FirstZoneLink;
  while Link <> nil do
  begin
    if Link.WorldLine <> nil then
    begin
      ab_WorldLine_Delete(Link.WorldLine);
      Link.WorldLine := nil;
    end;
    Link := Link.Next;
  end;
end;
{ @end $50F618 }

{ @routine $50F640 ab_ZoneLink_DrawSelection }
procedure ab_ZoneLink_DrawSelection(Entry: PabZoneLink);
var
  Scale: Double;
  First, Last: TVector3D;
  Offset: TVector3D;
  I: Integer;
begin
  with Offset do begin
    // Also writes index 2, past a zone link's $28-byte allocation.
    for I := 0 to 2 do
      if Entry.Segments[I] = nil then begin
        Entry.Segments[I] := ArcadeBattleScreen.WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0),
          CurrentPixelFormat.PackRgbBytes(255, 0, 0));
        Entry.Segments[I].Animated := True;
      end;
    First := ProjectPointByMatrix(SphereProjectionMatrix, Entry.First.Position);
    Last := ProjectPointByMatrix(SphereProjectionMatrix, Entry.Last.Position);
    X := Last.X - First.X;
    Y := Last.Y - First.Y;
    Scale := 1 / Sqrt(Sqr(X) + Sqr(Y)) * 3;
    X := X * Scale;
    Y := Y * Scale;
    First.X := Round(First.X);
    First.Y := Round(First.Y);
    Last.X := Round(Last.X);
    Last.Y := Round(Last.Y);
    Entry.Segments[0].First := Classes.Point(Round(First.X - Y), Round(First.Y + X));
    Entry.Segments[0].Last := Classes.Point(Round(Last.X - Y), Round(Last.Y + X));
    ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[0]);
    Entry.Segments[1].First := Classes.Point(Round(First.X + Y), Round(First.Y - X));
    Entry.Segments[1].Last := Classes.Point(Round(Last.X + Y), Round(Last.Y - X));
    ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Entry.Segments[1]);
  end;
end;
{ @end $50F640 }

{ @routine $50F89C ab_ZoneLink_ClearSegments }
procedure ab_ZoneLink_ClearSegments(Link: PabZoneLink);
var
  Index: Integer;
begin
  for Index := 0 to 1 do
    if Link.Segments[Index] <> nil then
    begin
      ArcadeBattleScreen.WorldLines.RetireSegment(Link.Segments[Index]);
      Link.Segments[Index] := nil;
    end;
end;
{ @end $50F89C }

{ @routine $50F8D0 ab_ZoneLink_Find }
function ab_ZoneLink_Find(First, Last: PabZone): PabZoneLink;
var Entry: PabZoneLink;
begin
  Entry := FirstZoneLink;
  while Entry <> nil do begin
    if (First = Entry.First) and (Last = Entry.Last) then begin
      Result := Entry;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $50F8D0 }

{ @routine $50FA44 ab_ZoneLink_FindAtAngles }
function ab_ZoneLink_FindAtAngles(Longitude, PolarAngle: Double): PabZoneLink;
var
  InverseLengthSquared, SegmentLength, LengthSquared: Double;
  First, Last, Position: TVector3D;
  Entry: PabZoneLink;

  // @nested $50F8F4 ProjectionWithinSegment
  function ProjectionWithinSegment(First, Last, Point: TVector3D): Boolean; // @addr $50F8F4 @calls "0x0050FB4E"
  var Fraction, ProjectedX, ProjectedY: Double;
  begin
    with First do begin
      Fraction := ((Y - Point.Y) * (Y - Last.Y) - (X - Point.X) * (Last.X - X)) * InverseLengthSquared;
      ProjectedX := (Last.X - X) * Fraction + X;
      ProjectedY := (Last.Y - Y) * Fraction + Y;
      Result := (Min(X, Last.X) <= ProjectedX) and (Max(X, Last.X) >= ProjectedX) and
        (Min(Y, Last.Y) <= ProjectedY) and (Max(Y, Last.Y) >= ProjectedY);
    end;
  end;

  // @nested $50F9D8 SignedDistanceToLine
  function SignedDistanceToLine(First, Last, Point: TVector3D): Double; // @addr $50F9D8 @calls "0x0050FB6E"
  var Cross: Double;
  begin
    with First do begin
      Cross := (Y - Point.Y) * (Last.X - X) - (X - Point.X) * (Last.Y - Y);
      Result := Cross * InverseLengthSquared * SegmentLength;
    end;
  end;

begin
  Position := SphericalToVector3D(HeadingDegreesToRadians(Longitude), HeadingDegreesToRadians(PolarAngle), SphereRadius);
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
  Entry := FirstZoneLink;
  while Entry <> nil do begin
    First := ProjectPointByMatrix(SphereProjectionMatrix, Entry.First.Position);
    Last := ProjectPointByMatrix(SphereProjectionMatrix, Entry.Last.Position);
    if not IsDepthBeforeSphereHorizon(First.Z) or not IsDepthBeforeSphereHorizon(Last.Z) then begin
      Entry := Entry.Next;
      Continue;
    end;
    LengthSquared := Sqr(First.X - Last.X) + Sqr(First.Y - Last.Y);
    if LengthSquared <= 0.0001 then begin
      Entry := Entry.Next;
      Continue;
    end;
    InverseLengthSquared := 1 / LengthSquared;
    if not ProjectionWithinSegment(First, Last, Position) then begin
      Entry := Entry.Next;
      Continue;
    end;
    SegmentLength := Sqrt(LengthSquared);
    if Abs(SignedDistanceToLine(First, Last, Position)) < 4 then begin
      Result := Entry;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $50FA44 }

{ @routine $50FBB0 ab_ZoneLink_Count }
function ab_ZoneLink_Count: Integer;
var Entry: PabZoneLink;
begin
  Result := 0;
  Entry := FirstZoneLink;
  while Entry <> nil do begin
    Inc(Result);
    Entry := Entry.Next;
  end;
end;
{ @end $50FBB0 }

{ @routine $50FBC8 ab_Zone_Save }
procedure ab_Zone_Save(Buffer: TBufEC);
var Entry: PabZone; Link: PabZoneLink;
begin
  Buffer.AddIntegerValue(ab_Zone_Count);
  Entry := FirstZone;
  while Entry <> nil do begin
    Buffer.AddSingle(Entry.Longitude);
    Buffer.AddSingle(Entry.PolarAngle);
    Buffer.AddSingle(Entry.RadiusDegrees);
    Buffer.AddIntegerValue(Entry.Kind);
    Entry := Entry.Next;
  end;
  Buffer.AddIntegerValue(ab_ZoneLink_Count);
  Link := FirstZoneLink;
  while Link <> nil do begin
    Buffer.AddIntegerValue(ab_Zone_IndexOf(Link.First));
    Buffer.AddIntegerValue(ab_Zone_IndexOf(Link.Last));
    Link := Link.Next;
  end;
end;
{ @end $50FBC8 }

{ @routine $50FC6C ab_Zone_Load }
procedure ab_Zone_Load(Buffer: TBufEC);
var
  Index, Count: Integer;
  Zone: PabZone;
  Link: PabZoneLink;
begin
  ab_ZoneLink_Clear;
  ab_Zone_Clear;
  Count := Buffer.GetInt32;
  for Index := 0 to Count - 1 do
  begin
    Zone := ab_Zone_Add;
    Zone.Longitude := Buffer.GetSingle;
    Zone.PolarAngle := Buffer.GetSingle;
    Zone.RadiusDegrees := Buffer.GetSingle;
    Zone.Kind := Buffer.GetInt32;
    Zone.Name := Buffer.ReadWideString;
    Zone.BarrierHealth := Buffer.GetInt32;
    Zone.GravityStrength := Buffer.GetInt32;
    Zone.DamagePerTick := Buffer.GetInt32;
    Zone.BonusFlags := Buffer.GetUInt32;
    Zone.BonusRespawnClass := Buffer.GetInt32;
    ab_Zone_UpdatePosition(Zone);
  end;
  Count := Buffer.GetInt32;
  for Index := 0 to Count - 1 do
  begin
    Link := ab_ZoneLink_Add;
    Link.First := ab_Zone_Get(Buffer.GetInt32);
    Link.Last := ab_Zone_Get(Buffer.GetInt32);
    Link.BarrierLinkMode := Buffer.GetInt32;
    ab_ZoneLink_UpdateDistance(Link);
  end;
end;
{ @end $50FC6C }

{ @routine $50FD94 ab_Zone_RandomKind }
function ab_Zone_RandomKind(Kind: Integer): PabZone;
begin
  Result := ab_Zone_GetKind(Kind, RandomIntRange(0, ab_Zone_CountKind(Kind) - 1));
end;
{ @end $50FD94 }

{ @routine $50FDB4 ab_Zone_RandomPosition }
function ab_Zone_RandomPosition(Zone: PabZone): TSphericalBearingState;
begin
  Result := AdvanceSphericalStateOnCurrentSphere(MakeSphericalBearingState(Zone.Longitude, Zone.PolarAngle, RandomIntRange(0, 360)), Random * Zone.Radius / 2 + Zone.Radius / 4);
end;
{ @end $50FDB4 }

{ @routine $50FE28 ab_Zone_FindContainingOrNearest }
function ab_Zone_FindContainingOrNearest(Longitude, PolarAngle: Double; var Nearest: PabZone): Boolean;
var
  Zone: PabZone;
  Distance, BestDistance: Double;
begin
  Result := False;
  Nearest := nil;
  if FirstZone <> nil then
  begin
    BestDistance := 1e20;
    Zone := FirstZone;
    while Zone <> nil do
    begin
      if Zone.Kind < 5 then
      begin
        ComputeSphericalDistance(Distance, Zone.Longitude, Zone.PolarAngle, 0, Longitude, PolarAngle, SphereRadius);
        if Distance < Zone.Radius then
        begin
          Result := True;
          Nearest := Zone;
          Exit;
        end;
        if Distance - Zone.Radius < BestDistance then
        begin
          BestDistance := Distance - Zone.Radius;
          Nearest := Zone;
        end;
      end;
      Zone := Zone.Next;
    end;
  end;
end;
{ @end $50FE28 }

{ @routine $50FECC ab_Zone_FindNearestOutside }
function ab_Zone_FindNearestOutside(Longitude, PolarAngle: Double): PabZone;
var
  Zone: PabZone;
  Distance, BestDistance: Double;
begin
  BestDistance := 1e20;
  Result := nil;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.Kind <= 1 then
    begin
      ComputeSphericalDistance(Distance, Zone.Longitude, Zone.PolarAngle, 0, Longitude, PolarAngle, SphereRadius);
      if (Distance > Zone.Radius) and (Distance < BestDistance) then
      begin
        BestDistance := Distance;
        Result := Zone;
      end;
    end;
    Zone := Zone.Next;
  end;
end;
{ @end $50FECC }

{ @routine $50FF58 ab_Zone_FindNearestEnabled }
function ab_Zone_FindNearestEnabled(Longitude, PolarAngle: Double): PabZone;
var
  Zone: PabZone;
  Bearing, Distance, BestDistance: Double;
begin
  Result := nil;
  if FirstZone <> nil then
  begin
    BestDistance := 1e20;
    Zone := FirstZone;
    while Zone <> nil do
    begin
      if Zone.GravityStrength <> 0 then
      begin
        ComputeSphericalBearingAndDistance(Zone.Longitude, Zone.PolarAngle, 0, Longitude, PolarAngle, SphereRadius, Bearing, Distance);
        if Distance < Zone.Radius then
        begin
          Result := Zone;
          Exit;
        end;
        if Distance - Zone.Radius < BestDistance then
        begin
          BestDistance := Distance - Zone.Radius;
          Result := Zone;
        end;
      end;
      Zone := Zone.Next;
    end;
  end;
end;
{ @end $50FF58 }

{ @routine $50FFF4 ab_Zone_IsInsideKind10 }
function ab_Zone_IsInsideKind10(Longitude, PolarAngle: Double): Boolean;
var
  Zone: PabZone;
  Distance: Double;
begin
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.Kind = 10 then
    begin
      ComputeSphericalDistance(Distance, Zone.Longitude, Zone.PolarAngle, 0, Longitude, PolarAngle, SphereRadius);
      if Distance < Zone.Radius then
      begin
        Result := True;
        Exit;
      end;
    end;
    Zone := Zone.Next;
  end;
  Result := False;
end;
{ @end $50FFF4 }

{ @routine $5100D0 ab_Zone_FindRoute }
function ab_Zone_FindRoute(Source, Target: PabZone): PabZone;
var
  Zone: PabZone;
  Link: PabZoneLink;
  BestDistance: Double;

  // @nested $510058 PropagateZoneDistances
  procedure PropagateZoneDistances(Zone: PabZone); // @addr $510058
  var
    Link: PabZoneLink;
  begin
    Link := FirstZoneLink;
    while Link <> nil do
    begin
      if Link.First = Zone then
      begin
        if Zone.RouteDistance + Link.Distance < Link.Last.RouteDistance then
        begin
          Link.Last.RouteDistance := Zone.RouteDistance + Link.Distance;
          PropagateZoneDistances(Link.Last);
        end;
      end
      else if Link.Last = Zone then
        if Zone.RouteDistance + Link.Distance < Link.First.RouteDistance then
        begin
          Link.First.RouteDistance := Zone.RouteDistance + Link.Distance;
          PropagateZoneDistances(Link.First);
        end;
      Link := Link.Next;
    end;
  end;

begin
  if (FirstZone = LastZone) or (FirstZoneLink = nil) or (Source = Target) then
  begin
    Result := nil;
    Exit;
  end;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    Zone.RouteDistance := 1e20;
    Zone := Zone.Next;
  end;
  Target.RouteDistance := 0;
  PropagateZoneDistances(Target);
  Result := nil;
  BestDistance := 1e20;
  Link := FirstZoneLink;
  while Link <> nil do
  begin
    if Link.First = Source then
    begin
      if Link.Last.RouteDistance < BestDistance then
      begin
        BestDistance := Link.Last.RouteDistance;
        Result := Link.Last;
      end;
    end
    else if Link.Last = Source then
      if Link.First.RouteDistance < BestDistance then
      begin
        BestDistance := Link.First.RouteDistance;
        Result := Link.First;
      end;
    Link := Link.Next;
  end;
end;
{ @end $5100D0 }

{ @routine $5101A0 ab_Zone_BuildRoutes }
procedure ab_Zone_BuildRoutes(Zone: PabZone);
var
  Target: PabZone;
begin
  if Zone.Routes = nil then Zone.Routes := TList.Create;
  Zone.Routes.Clear;
  Target := FirstZone;
  while Target <> nil do
  begin
    if Target.Kind < 5 then Zone.Routes.Add(ab_Zone_FindRoute(Zone, Target));
    Target := Target.Next;
  end;
end;
{ @end $5101A0 }

{ @routine $5101F0 ab_Zone_BuildAllRoutes }
procedure ab_Zone_BuildAllRoutes;
var
  Zone: PabZone;
  Index: Integer;
begin
  Index := 0;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if Zone.Kind < 5 then
    begin
      Zone.RouteIndex := Index;
      ab_Zone_BuildRoutes(Zone);
      Inc(Index);
    end;
    Zone := Zone.Next;
  end;
end;
{ @end $5101F0 }

{ @routine $51021C ab_Zone_GetRoute }
function ab_Zone_GetRoute(Source, Target: PabZone): PabZone;
begin
  if Target.Kind >= 5 then Result := nil
  else Result := Source.Routes[Target.RouteIndex];
end;
{ @end $51021C }

{ @routine $510234 ab_Zone_IsHeadingInside }
function ab_Zone_IsHeadingInside(Source: TSphericalBearingState; Zone: PabZone; var BearingDelta, AngularRadius: Double): Boolean;
var
  Bearing, Distance: Double;
begin
  ComputeSphericalBearingAndDistance(Source.LongitudeDegrees, Source.PolarAngleDegrees, Source.BearingDegrees, Zone.Longitude, Zone.PolarAngle, SphereRadius, Bearing, Distance);
  if Zone.Radius >= Distance then
  begin
    Result := True;
    BearingDelta := 0;
    Exit;
  end;
  AngularRadius := RadiansToHeadingDegrees(Math.ArcSin(Zone.Radius / Distance));
  Result := Abs(Bearing) < AngularRadius;
  BearingDelta := Bearing;
end;
{ @end $510234 }

{ @routine $5102E0 ab_Zone_FindReachableRouteZone }
function ab_Zone_FindReachableRouteZone(Source: PabZone): PabZone;
var
  Zone: PabZone;
  BestDistance, Distance: Double;
begin
  if Source.Kind < 5 then
  begin
    Result := Source;
    Exit;
  end;
  Result := nil;
  BestDistance := 1e20;
  Zone := FirstZone;
  while Zone <> nil do
  begin
    if (Zone <> Source) and (Zone.Kind < 5) then
    begin
      ComputeSphericalDistance(Distance, Source.Longitude, Source.PolarAngle, 0, Zone.Longitude, Zone.PolarAngle, SphereRadius);
      if (Distance < BestDistance) and not ab_StopLine_IsBlocked(Source.Longitude, Source.PolarAngle, Zone.Longitude, Zone.PolarAngle) then
      begin
        Result := Zone;
        BestDistance := Distance;
      end;
    end;
    Zone := Zone.Next;
  end;
end;
{ @end $5102E0 }

{ @routine $510398 ab_Zone_RandomRoute }
function ab_Zone_RandomRoute(Source: PabZone; Steps: Integer): PabZone;
var
  Current, Candidate: PabZone;
  Attempts: Integer;
begin
  Result := nil;
  if (Source.Routes = nil) or (Source.Routes.Count < 1) then Exit;
  Current := Source;
  while Steps > 0 do
  begin
    Dec(Steps);
    Attempts := 5;
    while Attempts > 0 do
    begin
      Dec(Attempts);
      Candidate := Current.Routes[RandomIntRange(0, Current.Routes.Count - 1)];
      if Candidate <> nil then
        if (Candidate.Routes <> nil) and (Candidate.Routes.Count >= 1) and (Candidate <> Source) and (Candidate <> Current) then
        begin
          Current := Candidate;
          Break;
        end;
    end;
    if Attempts <= 0 then Exit;
  end;
  Result := Current;
end;
{ @end $510398 }

end.

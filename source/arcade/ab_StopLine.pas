unit ab_StopLine;
// Unit bracket (inferred): CODE 0x00510458..0x00512167; inclusive evidence, not full bounds.

interface

uses ab_Obj3D, EC_Buf, EC_Struct, GI_PolyLine, GI_Tail, ab_Global, ab_WorldImage, ab_WorldLine;

type
  PabStopPoint = ^TabStopPoint;
  TabStopPoint = record // @size $70
    Prev: PabStopPoint; // @offset $00
    Next: PabStopPoint; // @offset $04
    Longitude: Double; // @offset $08
    PolarAngle: Double; // @offset $10
    Radius: Single; // @offset $18
    Position: TVector3D; // @offset $20
    ScreenX: Integer; // @offset $38
    ScreenY: Integer; // @offset $3C
    Projected: Boolean; // @offset $40
    Kind: Integer; // @offset $44  Set to 1 by the latitude-ring builder; wider meaning unresolved.
    WorldImage: PabWorldImage; // @offset $48
    Selected: Boolean; // @offset $50 Editor selection marker.
    Segments: array[0..3] of PPolyLineSegmentGI; // @offset $54
  end;
  TabStopPointArray = array of PabStopPoint;

  PabStopLine = ^TabStopLine;
  TabStopLine = record // @size $34
    Prev: PabStopLine; // @offset $00
    Next: PabStopLine; // @offset $04
    NextCollision: PabStopLine; // @offset $08
    UserValue: Integer; // @offset $0C
    First: PabStopPoint; // @offset $10
    Last: PabStopPoint; // @offset $14
    FirstColor: PCardinal; // @offset $18
    LastColor: PCardinal; // @offset $1C
    WorldLine: PabWorldLine; // @offset $20
    Collidable: Boolean; // @offset $24
    Visible: Boolean; // @offset $25
    Segments: array[0..1] of PPolyLineSegmentGI; // @offset $28
  end;

procedure ab_StopPoint_DrawSelection(Point: PabStopPoint); // @addr $510804
procedure ab_StopPoint_Clear; // @addr $51049C
function ab_StopPoint_Add: PabStopPoint; // @addr $510518 @note "Allocates and links a node owned by the world list."
procedure ab_StopPoint_Delete(Point: PabStopPoint); // @addr $5105C8
procedure ab_StopPoint_UpdatePosition(Point: PabStopPoint); // @addr $510664 @note "Nil updates every point."
procedure ab_StopPoint_ClearImages; // @addr $5107DC
procedure ab_StopPoint_ClearSegments(Point: PabStopPoint); // @addr $510A10
procedure ab_StopPoint_BuildIndex; // @addr $510AAC
procedure ab_StopPoint_ClearIndex; // @addr $510AF0
function ab_StopPoint_Count: Integer; // @addr $510B04
procedure ab_StopLine_Clear; // @addr $510BE4
function ab_StopLine_Add: PabStopLine; // @addr $510C18 @note "Allocates and links a node owned by the world list."
procedure ab_StopLine_Delete(Line: PabStopLine); // @addr $510CC8
procedure ab_StopLine_AddLatitude(PolarAngle, Step: Double); // @addr $510D40
procedure ab_StopLine_UpdateWorldLines; // @addr $510DEC
procedure ab_StopLine_UpdateColors; // @addr $510E7C
procedure ab_StopLine_ClearSegments(Line: PabStopLine); // @addr $511100
procedure ab_StopLine_PrepareCollision(Line: PabStopLine); // @addr $511134 @note "Empty in this native version."
procedure ab_StopLine_BuildCollisionList; // @addr $511138
function ab_StopLine_ReflectMovement(Source, Target: TSphericalBearingState; var HeadingDelta, Speed, UnusedResult: Double): Boolean; // @addr $51157C
procedure ab_StopLine_GetDistances(Source: TSphericalBearingState; var ForwardDistance, BackwardDistance: Double); // @addr $511B50
function ab_StopLine_IsBlocked(SourceLongitude, SourcePolarAngle, TargetLongitude, TargetPolarAngle: Double): Boolean; // @addr $511F10
procedure ab_StopLine_Load(Buffer: TBufEC); // @addr $512030

var
  StopPointHeap: Cardinal = 0; // @addr $61873C
  FirstStopPoint: PabStopPoint = nil; // @addr $618740
  LastStopPoint: PabStopPoint = nil; // @addr $618744
  SelectedStopPoint: PabStopPoint = nil; // @addr $618748
  StopLineHeap: Cardinal = 0; // @addr $61874C
  FirstStopLine: PabStopLine = nil; // @addr $618750
  LastStopLine: PabStopLine = nil; // @addr $618754
  SelectedStopLine: PabStopLine = nil; // @addr $618758
  FirstCollisionLine: PabStopLine = nil; // @addr $61875C
  StopPointIndex: array of PabStopPoint; // @addr $61CF50
  StopPointMeshes: array of TabObj3D; // @addr $61CF54 Owned auxiliary objects; retained update uses element 0 without a length guard.

function ab_StopLine_Count: Integer; // @addr $511F84
function ab_StopPoint_IndexOf(Target: PabStopPoint): Integer; // @addr $510B1C
function ab_StopPoint_FindAtAngles(Longitude, PolarAngle: Double): PabStopPoint; // @addr $510A44
procedure ab_StopLine_Save(Buffer: TBufEC); // @addr $511F9C
procedure ab_StopPoint_UpdateImages; // @addr $510714
procedure ab_StopPoint_UpdateVertices; // @addr $510B3C

procedure ab_StopLine_DrawSelection(Entry: PabStopLine); // @addr $510EA4

function ab_StopLine_FindAtAngles(Longitude, PolarAngle: Double): PabStopLine; // @addr $5112CC

implementation

// @unit-initialization $512160
// @unit-finalization $512110

uses Windows, SysUtils, Math, EC_Mem, Globals, GR_Main, Classes, aMyFunction;

{ @routine $51049C ab_StopPoint_Clear }
procedure ab_StopPoint_Clear;
var Index: Integer;
begin
  ab_StopPoint_ClearIndex;
  while FirstStopPoint <> nil do ab_StopPoint_Delete(LastStopPoint);
  if StopPointMeshes <> nil then begin
    for Index := 0 to High(StopPointMeshes) do
      if StopPointMeshes[Index] <> nil then begin
        ab_Obj3D_Delete(StopPointMeshes[Index]);
        StopPointMeshes[Index] := nil;
      end;
    StopPointMeshes := nil;
  end;
  if StopPointHeap <> 0 then
  begin
    HeapDestroy(StopPointHeap);
    StopPointHeap := 0;
  end;
end;
{ @end $51049C }

{ @routine $510518 ab_StopPoint_Add }
function ab_StopPoint_Add: PabStopPoint;
var
  Entry: PabStopPoint;
begin
  if StopPointHeap = 0 then
  begin
    StopPointHeap := HeapCreate(1, $8000, 0);
    if StopPointHeap = 0 then raise Exception.Create('ab_StopPoint_Add.HeapCreate');
  end;
  Entry := AllocClearFromHeapEC(StopPointHeap, SizeOf(TabStopPoint));
  Entry.Radius := SphereRadius;
  if LastStopPoint <> nil then LastStopPoint.Next := Entry;
  Entry.Prev := LastStopPoint;
  Entry.Next := nil;
  LastStopPoint := Entry;
  if FirstStopPoint = nil then FirstStopPoint := Entry;
  Result := Entry;
end;
{ @end $510518 }

{ @routine $5105C8 ab_StopPoint_Delete }
procedure ab_StopPoint_Delete(Point: PabStopPoint);
var
  Line, NextLine: PabStopLine;
begin
  if Point.Prev <> nil then Point.Prev.Next := Point.Next;
  if Point.Next <> nil then Point.Next.Prev := Point.Prev;
  if LastStopPoint = Point then LastStopPoint := Point.Prev;
  if FirstStopPoint = Point then FirstStopPoint := Point.Next;
  Line := FirstStopLine;
  while Line <> nil do
  begin
    NextLine := Line;
    Line := Line.Next;
    if (NextLine.First = Point) or (NextLine.Last = Point) then ab_StopLine_Delete(NextLine);
  end;
  if Point.WorldImage <> nil then
  begin
    ab_WorldImage_Delete(Point.WorldImage);
    Point.WorldImage := nil;
  end;
  ab_StopPoint_ClearSegments(Point);
  if SelectedStopPoint = Point then SelectedStopPoint := nil;
  if StopPointHeap <> 0 then FreeFromHeapEC(StopPointHeap, Point);
end;
{ @end $5105C8 }

{ @routine $510664 ab_StopPoint_UpdatePosition }
procedure ab_StopPoint_UpdatePosition(Point: PabStopPoint);
begin
  if Point = nil then
  begin
    Point := FirstStopPoint;
    while Point <> nil do
    begin
      Point.Position := SphericalToVector3D(HeadingDegreesToRadians(Point.Longitude), HeadingDegreesToRadians(Point.PolarAngle), Point.Radius);
      Point := Point.Next;
    end;
  end
  else Point.Position := SphericalToVector3D(HeadingDegreesToRadians(Point.Longitude), HeadingDegreesToRadians(Point.PolarAngle), Point.Radius);
end;
{ @end $510664 }

{ @routine $510714 ab_StopPoint_UpdateImages }
procedure ab_StopPoint_UpdateImages;
var FrontPath, BackPath: WideString; Entry: PabStopPoint;
begin
  FrontPath := 'GI,Bm.AB.2StopPoint0_f';
  BackPath := '';
  Entry := FirstStopPoint;
  while Entry <> nil do begin
    if Entry.Kind = 1 then begin
      if Entry.WorldImage = nil then
        Entry.WorldImage := ab_WorldImage_Create(Entry.Position, FrontPath, BackPath, False)
      else ab_WorldImage_Set(Entry.WorldImage, Entry.Position, FrontPath, BackPath);
    end;
    Entry := Entry.Next;
  end;
end;
{ @end $510714 }

{ @routine $5107DC ab_StopPoint_ClearImages }
procedure ab_StopPoint_ClearImages;
var
  Point: PabStopPoint;
begin
  Point := FirstStopPoint;
  while Point <> nil do
  begin
    if Point.WorldImage <> nil then
    begin
      ab_WorldImage_Delete(Point.WorldImage);
      Point.WorldImage := nil;
    end;
    Point := Point.Next;
  end;
end;
{ @end $5107DC }

{ @routine $510804 ab_StopPoint_DrawSelection }
procedure ab_StopPoint_DrawSelection(Point: PabStopPoint);
var Center: TPoint; Position: TVector3D; I, Radius: Integer;
begin
  for I := 0 to 3 do
    if Point.Segments[I] = nil then begin
      Point.Segments[I] := ArcadeBattleScreen.WorldLines.AddLine(Classes.Point(0, 0), Classes.Point(0, 0),
        CurrentPixelFormat.PackRgbBytes(255, 0, 0));
      Point.Segments[I].Animated := True;
    end;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Point.Position);
  Center.X := Round(Position.X);
  Center.Y := Round(Position.Y);
  Radius := 10;
  Point.Segments[0].First := Classes.Point(Center.X - Radius, Center.Y - Radius);
  Point.Segments[0].Last := Classes.Point(Center.X + Radius, Center.Y - Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Point.Segments[0]);
  Point.Segments[1].First := Classes.Point(Center.X + Radius, Center.Y - Radius);
  Point.Segments[1].Last := Classes.Point(Center.X + Radius, Center.Y + Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Point.Segments[1]);
  Point.Segments[2].First := Classes.Point(Center.X + Radius, Center.Y + Radius);
  Point.Segments[2].Last := Classes.Point(Center.X - Radius, Center.Y + Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Point.Segments[2]);
  Point.Segments[3].First := Classes.Point(Center.X - Radius, Center.Y + Radius);
  Point.Segments[3].Last := Classes.Point(Center.X - Radius, Center.Y - Radius);
  ArcadeBattleScreen.WorldLines.UpdateSegmentLength(Point.Segments[3]);
end;
{ @end $510804 }

{ @routine $510A10 ab_StopPoint_ClearSegments }
procedure ab_StopPoint_ClearSegments(Point: PabStopPoint);
var
  Index: Integer;
begin
  for Index := 0 to 3 do
    if Point.Segments[Index] <> nil then
    begin
      ArcadeBattleScreen.WorldLines.RetireSegment(Point.Segments[Index]);
      Point.Segments[Index] := nil;
    end;
end;
{ @end $510A10 }

{ @routine $510A44 ab_StopPoint_FindAtAngles }
function ab_StopPoint_FindAtAngles(Longitude, PolarAngle: Double): PabStopPoint;
var Entry: PabStopPoint; Bearing, Distance: Double;
begin
  Entry := FirstStopPoint;
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
{ @end $510A44 }

{ @routine $510AAC ab_StopPoint_BuildIndex }
procedure ab_StopPoint_BuildIndex;
var
  Index, Count: Integer;
  Point: PabStopPoint;
begin
  ab_StopPoint_ClearIndex;
  Count := ab_StopPoint_Count;
  SetLength(StopPointIndex, Count);
  Index := 0;
  Point := FirstStopPoint;
  while Point <> nil do
  begin
    StopPointIndex[Index] := Point;
    Inc(Index);
    Point := Point.Next;
  end;
end;
{ @end $510AAC }

{ @routine $510AF0 ab_StopPoint_ClearIndex }
procedure ab_StopPoint_ClearIndex;
begin
  StopPointIndex := nil;
end;
{ @end $510AF0 }

{ @routine $510B04 ab_StopPoint_Count }
function ab_StopPoint_Count: Integer;
var
  Point: PabStopPoint;
begin
  Result := 0;
  Point := FirstStopPoint;
  while Point <> nil do
  begin
    Inc(Result);
    Point := Point.Next;
  end;
end;
{ @end $510B04 }

{ @routine $510B1C ab_StopPoint_IndexOf }
function ab_StopPoint_IndexOf(Target: PabStopPoint): Integer;
var Entry: PabStopPoint;
begin
  Result := 0;
  Entry := FirstStopPoint;
  while Entry <> nil do begin
    if Entry = Target then Exit;
    Inc(Result);
    Entry := Entry.Next;
  end;
  Result := -1;
end;
{ @end $510B1C }

{ @routine $510B3C ab_StopPoint_UpdateVertices }
procedure ab_StopPoint_UpdateVertices;
var Position: TVector3D; Vertex: PabVertex3D; Point: PabStopPoint;
begin
  with Position do begin
    StopPointMeshes[0].LockVertices;
    Vertex := StopPointMeshes[0].GetVertex(0);
    Point := FirstStopPoint;
    while Point <> nil do begin
      Position := ProjectPointByMatrix(SphereProjectionMatrix, Point.Position);
      Vertex.X := Cardinal(GameScreenWidth) / 2 + X;
      Vertex.Y := Cardinal(GameScreenHeight) / 2 + Y;
      Vertex.Z := Z;
      Inc(Vertex);
      Point := Point.Next;
    end;
    StopPointMeshes[0].UnlockVertices;
  end;
end;
{ @end $510B3C }

{ @routine $510BE4 ab_StopLine_Clear }
procedure ab_StopLine_Clear;
begin
  while FirstStopLine <> nil do ab_StopLine_Delete(LastStopLine);
  if StopLineHeap <> 0 then
  begin
    HeapDestroy(StopLineHeap);
    StopLineHeap := 0;
  end;
end;
{ @end $510BE4 }

{ @routine $510C18 ab_StopLine_Add }
function ab_StopLine_Add: PabStopLine;
var
  Entry: PabStopLine;
begin
  if StopLineHeap = 0 then
  begin
    StopLineHeap := HeapCreate(1, $8000, 0);
    if StopLineHeap = 0 then raise Exception.Create('ab_StopLine_Add.HeapCreate');
  end;
  Entry := AllocClearFromHeapEC(StopLineHeap, SizeOf(TabStopLine));
  if LastStopLine <> nil then LastStopLine.Next := Entry;
  Entry.Prev := LastStopLine;
  Entry.Next := nil;
  LastStopLine := Entry;
  if FirstStopLine = nil then FirstStopLine := Entry;
  Entry.Collidable := True;
  Entry.Visible := True;
  Entry.UserValue := 0;
  Result := Entry;
end;
{ @end $510C18 }

{ @routine $510CC8 ab_StopLine_Delete }
procedure ab_StopLine_Delete(Line: PabStopLine);
begin
  if Line.Prev <> nil then Line.Prev.Next := Line.Next;
  if Line.Next <> nil then Line.Next.Prev := Line.Prev;
  if LastStopLine = Line then LastStopLine := Line.Prev;
  if FirstStopLine = Line then FirstStopLine := Line.Next;
  if Line.WorldLine <> nil then
  begin
    ab_WorldLine_Delete(Line.WorldLine);
    Line.WorldLine := nil;
  end;
  ab_StopLine_ClearSegments(Line);
  if SelectedStopLine = Line then SelectedStopLine := nil;
  if StopLineHeap <> 0 then FreeFromHeapEC(StopLineHeap, Line);
end;
{ @end $510CC8 }

{ @routine $510D40 ab_StopLine_AddLatitude }
procedure ab_StopLine_AddLatitude(PolarAngle, Step: Double);
var
  Longitude: Double;
  Line: PabStopLine;
  Point, Previous, First: PabStopPoint;
begin
  First := ab_StopPoint_Add;
  First.Longitude := 0;
  First.PolarAngle := PolarAngle;
  First.Kind := 1;
  ab_StopPoint_UpdatePosition(First);
  Previous := First;
  Longitude := Step;
  while Longitude < 360 do
  begin
    Point := ab_StopPoint_Add;
    Point.Longitude := Longitude;
    Point.PolarAngle := PolarAngle;
    Point.Kind := 1;
    ab_StopPoint_UpdatePosition(Point);
    Line := ab_StopLine_Add;
    Line.First := Previous;
    Line.Last := Point;
    Previous := Point;
    Longitude := Longitude + Step;
  end;
  Line := ab_StopLine_Add;
  Line.First := Previous;
  Line.Last := First;
end;
{ @end $510D40 }

{ @routine $510DEC ab_StopLine_UpdateWorldLines }
procedure ab_StopLine_UpdateWorldLines;
var
  Line: PabStopLine;
begin
  Line := FirstStopLine;
  while Line <> nil do
  begin
    if Line.Visible then
    begin
      if Line.WorldLine = nil then
      begin
        Line.WorldLine := ab_WorldLine_Create(Line.First.Position, Line.Last.Position, 4, Line.FirstColor^, $80FFFFFF, False);
        Line.WorldLine.FrontEndColor := Line.LastColor^;
        Line.WorldLine.BackEndColor := $80FFFFFF;
      end
      else
      begin
        ab_WorldLine_Set(Line.WorldLine, Line.First.Position, Line.Last.Position, 4, Line.FirstColor^, $80FFFFFF, False);
        Line.WorldLine.FrontEndColor := Line.LastColor^;
        Line.WorldLine.BackEndColor := $80FFFFFF;
      end;
    end;
    Line := Line.Next;
  end;
end;
{ @end $510DEC }

{ @routine $510E7C ab_StopLine_UpdateColors }
procedure ab_StopLine_UpdateColors;
var
  Line: PabStopLine;
begin
  Line := FirstStopLine;
  while Line <> nil do
  begin
    if Line.WorldLine <> nil then
    begin
      Line.WorldLine.FrontColor := Line.FirstColor^;
      Line.WorldLine.FrontEndColor := Line.LastColor^;
    end;
    Line := Line.Next;
  end;
end;
{ @end $510E7C }

{ @routine $510EA4 ab_StopLine_DrawSelection }
procedure ab_StopLine_DrawSelection(Entry: PabStopLine);
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
{ @end $510EA4 }

{ @routine $511100 ab_StopLine_ClearSegments }
procedure ab_StopLine_ClearSegments(Line: PabStopLine);
var
  Index: Integer;
begin
  for Index := 0 to 1 do
    if Line.Segments[Index] <> nil then
    begin
      ArcadeBattleScreen.WorldLines.RetireSegment(Line.Segments[Index]);
      Line.Segments[Index] := nil;
    end;
end;
{ @end $511100 }

{ @routine $511134 ab_StopLine_PrepareCollision }
procedure ab_StopLine_PrepareCollision(Line: PabStopLine);
begin
end;
{ @end $511134 }

{ @routine $511138 ab_StopLine_BuildCollisionList }
procedure ab_StopLine_BuildCollisionList;
var
  Line, Previous: PabStopLine;
begin
  Previous := nil;
  FirstCollisionLine := nil;
  Line := FirstStopLine;
  while Line <> nil do
  begin
    ab_StopLine_PrepareCollision(Line);
    Line.NextCollision := nil;
    if Line.Collidable then
    begin
      if Previous = nil then FirstCollisionLine := Line
      else Previous.NextCollision := Line;
      Previous := Line;
    end;
    Line := Line.Next;
  end;
end;
{ @end $511138 }

{ @routine $5112CC ab_StopLine_FindAtAngles }
function ab_StopLine_FindAtAngles(Longitude, PolarAngle: Double): PabStopLine;
var
  InverseLengthSquared, SegmentLength, LengthSquared: Double;
  First, Last, Position: TVector3D;
  Entry: PabStopLine;

  // @nested $51117C ProjectionWithinSegment
  function ProjectionWithinSegment(First, Last, Point: TVector3D): Boolean; // @addr $51117C @calls "0x005113D6"
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

  // @nested $511260 SignedDistanceToLine
  function SignedDistanceToLine(First, Last, Point: TVector3D): Double; // @addr $511260 @calls "0x005113F6"
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
  Entry := FirstStopLine;
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
{ @end $5112CC }

{ @routine $51157C ab_StopLine_ReflectMovement }
function ab_StopLine_ReflectMovement(Source, Target: TSphericalBearingState; var HeadingDelta, Speed, UnusedResult: Double): Boolean;
var
  InverseLengthSquared, LineLength: Single;
  Line: PabStopLine;
  Factor, CenterDepth, FirstT, SecondT, OriginalHeading, Distance: Double;
  LengthSquared: Single;
  Matrix: TMatrix4D;
  Normal, A, B, Direction, Movement: TVector3D;

  // @nested $511438 IntersectCollisionParameters
  function IntersectCollisionParameters(A, B, C, D: TVector3D; var FirstT, SecondT: Double): Boolean; // @addr $511438 @calls "0x005118BA"
  begin
    FirstT := (B.X - A.X) * (D.Y - C.Y) - (B.Y - A.Y) * (D.X - C.X);
    if FirstT = 0 then
    begin
      Result := False;
      Exit;
    end;
    FirstT := 1 / FirstT;
    SecondT := ((A.Y - C.Y) * (B.X - A.X) - (A.X - C.X) * (B.Y - A.Y)) * FirstT;
    FirstT := ((A.Y - C.Y) * (D.X - C.X) - (A.X - C.X) * (D.Y - C.Y)) * FirstT;
    Result := True;
  end;

  // @nested $511510 CollisionLineDistance
  function CollisionLineDistance(A, B, Point: TVector3D): Double; // @addr $511510 @calls "0x00511841"
  var
    Cross: Double;
  begin
    Cross := (A.Y - Point.Y) * (B.X - A.X) - (A.X - Point.X) * (B.Y - A.Y);
    Result := Cross * InverseLengthSquared * LineLength;
  end;

begin
  Result := False;
  if FirstStopLine = nil then Exit;
  UnusedResult := 0;
  A := SphericalToVector3D(HeadingDegreesToRadians(Source.LongitudeDegrees),
    HeadingDegreesToRadians(Source.PolarAngleDegrees), SphereCameraDistance);
  B := MakeVector3D(0, 0, 0);
  Direction := SphericalToVector3D(HeadingDegreesToRadians(Source.LongitudeDegrees),
    HeadingDegreesToRadians(WrapHeadingDegrees(Source.PolarAngleDegrees + 90)), SphereCameraDistance);
  Matrix := BuildLookAtMatrix(A, B, Direction);
  Movement := SphericalToVector3D(HeadingDegreesToRadians(Target.LongitudeDegrees),
    HeadingDegreesToRadians(Target.PolarAngleDegrees), SphereRadius);
  Movement := ProjectPointByMatrix(Matrix, Movement);
  OriginalHeading := RadiansToHeadingDegrees(Math.ArcTan2(Movement.X, -Movement.Y));
  A := MakeVector3D(0, 0, 0);
  A := ProjectPointByMatrix(Matrix, A);
  CenterDepth := A.Z;
  Line := FirstCollisionLine;
  while Line <> nil do
  begin
    A := ProjectPointByMatrix(Matrix, Line.First.Position);
    B := ProjectPointByMatrix(Matrix, Line.Last.Position);
    if not ((A.Z < CenterDepth) and (B.Z < CenterDepth)) then
    begin
      Line := Line.NextCollision;
      Continue;
    end;
    Direction.X := B.X - A.X;
    Direction.Y := B.Y - A.Y;
    LengthSquared := Sqr(Direction.X) + Sqr(Direction.Y);
    LineLength := Sqrt(LengthSquared);
    InverseLengthSquared := 1 / LengthSquared;
    Distance := Abs(CollisionLineDistance(A, B, MakeVector3D(0, 0, 0)));
    if Distance > 11 then
    begin
      Line := Line.NextCollision;
      Continue;
    end;
    Factor := 1 / LineLength;
    Direction.X := Direction.X * Factor;
    Direction.Y := Direction.Y * Factor;
    if not IntersectCollisionParameters(A, B, MakeVector3D(0, 0, 0), Movement, FirstT, SecondT) then
    begin
      Line := Line.NextCollision;
      Continue;
    end;
    if not ((FirstT >= -0.0001) and (FirstT <= 1.0001)) then
    begin
      Line := Line.NextCollision;
      Continue;
    end;
    if SecondT < 0 then
    begin
      Line := Line.NextCollision;
      Continue;
    end;
    Normal.X := -Direction.Y;
    Normal.Y := Direction.X;
    Factor := -Movement.X * Normal.X + -Movement.Y * Normal.Y;
    Movement.X := (Normal.X * Factor * 2 + Movement.X) * 0.8;
    Movement.Y := (Normal.Y * Factor * 2 + Movement.Y) * 0.8;
    Result := True;
    Break;
    Line := Line.NextCollision;
  end;
  if Result then
  begin
    HeadingDelta := HeadingDifferenceDegrees(OriginalHeading,
      RadiansToHeadingDegrees(Math.ArcTan2(Movement.X, -Movement.Y)));
    Speed := Sqrt(Sqr(Movement.X) + Sqr(Movement.Y));
  end;
end;
{ @end $51157C }

{ @routine $511B50 ab_StopLine_GetDistances }
procedure ab_StopLine_GetDistances(Source: TSphericalBearingState; var ForwardDistance, BackwardDistance: Double);
var
  CenterDepth: Double;
  Line: PabStopLine;
  Matrix, View, Rotation: TMatrix4D;
  A, B, Hit: TVector3D;

  // @nested $511A50 IntersectCollisionLines
  function IntersectCollisionLines(A, B, C, D: TVector3D; var Hit: TVector3D): Boolean; // @addr $511A50 @calls "0x00511DBF"
  var
    DX1, DY1, DX2, DY2, Denominator: Double;
  begin
    DX1 := B.X - A.X;
    DY1 := B.Y - A.Y;
    DX2 := D.X - C.X;
    DY2 := D.Y - C.Y;
    Denominator := DY1 * DX2 - DY2 * DX1;
    if Denominator = 0 then
    begin
      Result := False;
      Exit;
    end;
    Hit.X := ((C.Y - A.Y) * DX1 * DX2 + DY1 * DX2 * A.X - DY2 * DX1 * C.X) / Denominator;
    if DX1 <> 0 then Hit.Y := (Hit.X - A.X) * DY1 / DX1 + A.Y
    else Hit.Y := (Hit.X - C.X) * DY2 / DX2 + C.Y;
    Result := True;
  end;

begin
  ForwardDistance := 1e20;
  BackwardDistance := 1e20;
  if FirstStopLine <> nil then
  begin
    A := SphericalToVector3D(HeadingDegreesToRadians(Source.LongitudeDegrees), HeadingDegreesToRadians(Source.PolarAngleDegrees), SphereCameraDistance);
    B := MakeVector3D(0, 0, 0);
    Hit := SphericalToVector3D(HeadingDegreesToRadians(Source.LongitudeDegrees), HeadingDegreesToRadians(Source.PolarAngleDegrees + 90), SphereCameraDistance);
    View := BuildLookAtMatrix(A, B, Hit);
    Rotation := BuildZAxisRotationMatrix(HeadingDegreesToRadians(Source.BearingDegrees));
    Matrix := MultiplyMatrix4D(Rotation, View);
    A := MakeVector3D(0, 0, 0);
    A := ProjectPointByMatrix(Matrix, A);
    CenterDepth := A.Z;
    Line := FirstCollisionLine;
    while Line <> nil do
    begin
      A := ProjectPointByMatrix(Matrix, Line.First.Position);
      B := ProjectPointByMatrix(Matrix, Line.Last.Position);
      if not ((A.Z < CenterDepth) and (B.Z < CenterDepth)) then
      begin
        Line := Line.NextCollision;
        Continue;
      end;
      if not (((A.X >= 0) or (B.X >= 0)) and ((A.X <= 0) or (B.X <= 0))) then
      begin
        Line := Line.NextCollision;
        Continue;
      end;
      if not IntersectCollisionLines(A, B, MakeVector3D(0, 0, 0), MakeVector3D(0, 1, 0), Hit) then
      begin
        Line := Line.NextCollision;
        Continue;
      end;
      if Hit.Y <= 0 then
        if -Hit.Y < ForwardDistance then ForwardDistance := -Hit.Y;
      if Hit.Y >= 0 then
        if BackwardDistance > Hit.Y then BackwardDistance := Hit.Y;
      Line := Line.NextCollision;
    end;
    if (ForwardDistance < 1e15) and (ForwardDistance <> 0) then
      ForwardDistance := RadiansToHeadingDegrees(Math.ArcSin(ForwardDistance / SphereRadius)) * (Pi * SphereRadius / 180);
    if (BackwardDistance < 1e15) and (BackwardDistance <> 0) then
      BackwardDistance := RadiansToHeadingDegrees(Math.ArcSin(BackwardDistance / SphereRadius)) * (Pi * SphereRadius / 180);
  end;
end;
{ @end $511B50 }

{ @routine $511F10 ab_StopLine_IsBlocked }
function ab_StopLine_IsBlocked(SourceLongitude, SourcePolarAngle, TargetLongitude, TargetPolarAngle: Double): Boolean;
var
  BearingDelta, Distance, ForwardDistance, BackwardDistance: Double;
begin
  ComputeSphericalBearingAndDistance(SourceLongitude, SourcePolarAngle, 0, TargetLongitude, TargetPolarAngle, SphereRadius, BearingDelta, Distance);
  ab_StopLine_GetDistances(MakeSphericalBearingState(SourceLongitude, SourcePolarAngle, BearingDelta), ForwardDistance, BackwardDistance);
  Result := ForwardDistance < Distance;
end;
{ @end $511F10 }

{ @routine $511F84 ab_StopLine_Count }
function ab_StopLine_Count: Integer;
var Entry: PabStopLine;
begin
  Result := 0;
  Entry := FirstStopLine;
  while Entry <> nil do begin
    Inc(Result);
    Entry := Entry.Next;
  end;
end;
{ @end $511F84 }

{ @routine $511F9C ab_StopLine_Save }
procedure ab_StopLine_Save(Buffer: TBufEC);
var Entry: PabStopPoint; Link: PabStopLine;
begin
  Buffer.AddIntegerValue(ab_StopPoint_Count);
  Entry := FirstStopPoint;
  while Entry <> nil do begin
    Buffer.AddSingle(Entry.Longitude);
    Buffer.AddSingle(Entry.PolarAngle);
    Buffer.AddIntegerValue(Entry.Kind);
    Entry := Entry.Next;
  end;
  Buffer.AddIntegerValue(ab_StopLine_Count);
  Link := FirstStopLine;
  while Link <> nil do begin
    Buffer.AddIntegerValue(ab_StopPoint_IndexOf(Link.First));
    Buffer.AddIntegerValue(ab_StopPoint_IndexOf(Link.Last));
    Link := Link.Next;
  end;
end;
{ @end $511F9C }

{ @routine $512030 ab_StopLine_Load }
procedure ab_StopLine_Load(Buffer: TBufEC);
var
  Index, Count, FirstIndex, LastIndex: Integer;
  Point: PabStopPoint;
  Line: PabStopLine;
begin
  ab_StopLine_Clear;
  ab_StopPoint_Clear;
  Count := Buffer.GetInt32;
  for Index := 0 to Count - 1 do
  begin
    Point := ab_StopPoint_Add;
    Point.Longitude := Buffer.GetSingle;
    Point.PolarAngle := Buffer.GetSingle;
    Point.Radius := Buffer.GetSingle;
    ab_StopPoint_UpdatePosition(Point);
  end;
  ab_StopPoint_BuildIndex;
  Count := Buffer.GetInt32;
  for Index := 0 to Count - 1 do
  begin
    Line := ab_StopLine_Add;
    FirstIndex := Buffer.GetInt32;
    LastIndex := Buffer.GetInt32;
    Line.First := StopPointIndex[FirstIndex];
    Line.Last := StopPointIndex[LastIndex];
    Line.Visible := Buffer.GetBoolean;
    Line.Collidable := Buffer.GetBoolean;
    if Line.Visible then
    begin
      Line.FirstColor := PCardinal(PAnsiChar(ArcadeMapColorBuffer.Data) + Buffer.GetInt32);
      Line.LastColor := PCardinal(PAnsiChar(ArcadeMapColorBuffer.Data) + Buffer.GetInt32);
    end;
  end;
end;
{ @end $512030 }

end.

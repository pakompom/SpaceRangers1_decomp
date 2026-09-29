unit aVector;
// Unit bracket (inferred): CODE 0x004CE3B0..0x004CFE1B; inclusive evidence, not full bounds.
// Inferred aVector ownership: the contiguous 2D geometry/polygon contribution
// used by galaxy geometry; native PACKAGEINFO visits aVector in the model graph.

interface
uses Classes, EC_Struct, Types;
type
  TRectF = record // @size $10
    Left: Single; // @offset $00
    Top: Single; // @offset $04
    Right: Single; // @offset $08
    Bottom: Single; // @offset $0C
  end;

  TPolygonEdge = record // @size $1C
    First: TPointF; // @offset $00
    Last: TPointF; // @offset $08
    // The remaining twelve bytes are not initialized by edge extraction.
  end;
  PPolygonEdge = ^TPolygonEdge;

  TPolygon2D = class(TObject) // @size $3C
  public
    Next: TPolygon2D; // @offset $04
    Previous: TPolygon2D; // @offset $08
    Points: TList; // @offset $0C  Owns PPointF entries.
    GroupId: Integer; // @offset $10
    Unknown14: Integer; // @offset $14  Reset to -1; other meaning unresolved.
    Extent: TPointF; // @offset $18
    CachedArea: Single; // @offset $20
    AreaValid: Boolean; // @offset $24
    Bounds: TRectF; // @offset $28
    Flag39: Boolean; // @offset $39  Cleared on geometry changes; other meaning unresolved.
    constructor Create; // @addr $4CED2C
    constructor CreateTriangle(A, B, C: TPointF); // @addr $4CEDCC
    destructor Destroy; override; // @addr $4CEE98
    procedure Clear; // @addr $4CEECC
    procedure SetRectangle(Rect: TRect); // @addr $4CEF58
    procedure TakePoints(NewPoints: TList); // @addr $4CF080 @note "Takes ownership of the list and its PPointF entries."
    procedure SetTriangle(A, B, C: TPointF); // @addr $4CF0AC
    procedure RecalculateBounds; // @addr $4CF14C
    procedure InsertAfter(Polygon: TPolygon2D); // @addr $4CF23C
    procedure SplitChainByLine(A, B, C: Single); // @addr $4CF254
    procedure SplitChainByPoints(First, Last: TPointF); // @addr $4CF554
    function ExtractFollowingGroup(Id: Integer): TPolygon2D; // @addr $4CF5A0
    function ContainsPoint(Point: TPointF): Boolean; // @addr $4CF604
    function ChainContainsPoint(Point: TPointF): Boolean; // @addr $4CF6C4
    function FindContainingPolygon(Point: TPointF): TPolygon2D; // @addr $4CF6F8
    function AssignGroupAtPoint(Point: TPointF; Id: Integer): Boolean; // @addr $4CF728
    function ExtractBoundaryEdges: TList; // @addr $4CF760
    function MergeUnsharedEdges(First, Second: TList): TList; // @addr $4CF79C @note "Consumes both lists and frees their edge records."
    function ExtractEdges: TList; // @addr $4CF9AC @note "Caller owns the list and its PPolygonEdge entries."
    procedure ResetChainGroups; // @addr $4CFA44
    function GetChainItem(Index: Integer): TPolygon2D; // @addr $4CFA74
    function GetArea: Single; // @addr $4CFA88 @note "The first uncached call fills CachedArea but returns zero; later calls return the cache."
    function GetChainArea: Single; // @addr $4CFBF8
    function IntersectsPolygon(Polygon: TPolygon2D): Boolean; // @addr $4CFC20
    function IntersectsEdge(Edge: PPolygonEdge): Boolean; // @addr $4CFC90
    function IntersectsSegment(First, Last: TPointF): Boolean; // @addr $4CFD2C
    function ChainSelfIntersects: Boolean; // @addr $4CFD70
    function IntersectsChain(Polygon: TPolygon2D): Boolean; // @addr $4CFDA8
    procedure Append(Polygon: TPolygon2D); // @addr $4CF220 @note "Appends at the tail and sets Polygon.Previous; requires nonnil Polygon."
    function CountChain: Integer; // @addr $4CFA60 @note "Includes Self; nil returns zero."
  end;

function PerpendicularVector(Point: TPointF): TPointF; // @addr $4CE408
function DotProductF(Left, Right: TPointF): Single; // @addr $4CE428
function VectorLengthF(Point: TPointF): Single; // @addr $4CE45C
function IsRightOfDirectedLine(Point, Origin, Direction: TPointF): Boolean; // @addr $4CE484
function IsLeftOfDirectedLine(Point, Origin, Direction: TPointF): Boolean; // @addr $4CE4FC
function MakeVectorF(X, Y: Single): TPointF; // @addr $4CE574
function VectorBetweenPoints(First, Last: TPointF): TPointF; // @addr $4CE588
procedure GetLineEquation(First, Last: TPointF; var A, B, C: Single); // @addr $4CE5B8
function IntersectLinesF(First1, Last1, First2, Last2: TPointF): TPointF; // @addr $4CE654
function IntersectSegmentWithLine(First, Last: TPointF; A, B, C: Single; var Intersection: TPointF): Boolean; // @addr $4CE73C
function IntersectSegmentWithDirectedLine(First, Last, LineFirst, LineLast: TPointF; var Intersection: TPointF): Boolean; // @addr $4CE85C
function IntersectSegmentsF(First1, Last1, First2, Last2: TPointF; var Intersection: TPointF): Boolean; // @addr $4CE8E8
function MakeRectF(Left, Top, Right, Bottom: Single): TRectF; // @addr $4CE950
function RectFromPointsF(First, Last: TPointF): TRectF; // @addr $4CE970
function PointsNearlyEqualF(First, Last: TPointF): Boolean; // @addr $4CE9A4
function SegmentsNearlyEqualF(First1, Last1, First2, Last2: TPointF): Boolean; // @addr $4CEA00
function ScalarsNearlyEqualF(First, Last: Single): Boolean; // @addr $4CEA70
function PointDistanceF(First, Last: TPointF): Single; // @addr $4CEAA0
function PointSegmentDistanceF(First, Last, Point: TPointF): Single; // @addr $4CEADC
function ClassifyPointToSegment(First, Last, Point: TPointF): Integer; // @addr $4CEBBC

implementation

// @unit-initialization $4CFE14
// @unit-finalization $4CFDE4

uses SysUtils;

{ @routine $4CE408 PerpendicularVector }
function PerpendicularVector(Point: TPointF): TPointF;
begin
  Result.X := -Point.Y;
  Result.Y := Point.X;
end;
{ @end $4CE408 }

{ @routine $4CE428 DotProductF }
function DotProductF(Left, Right: TPointF): Single;
begin
  Result := Left.X * Right.X + Left.Y * Right.Y;
end;
{ @end $4CE428 }

{ @routine $4CE45C VectorLengthF }
function VectorLengthF(Point: TPointF): Single;
begin
  Result := Sqrt(DotProductF(Point, Point));
end;
{ @end $4CE45C }

{ @routine $4CE484 IsRightOfDirectedLine }
function IsRightOfDirectedLine(Point, Origin, Direction: TPointF): Boolean;
var Normal, Offset: TPointF;
begin
  Normal := PerpendicularVector(Direction);
  Offset := MakeVectorF(Point.X - Origin.X, Point.Y - Origin.Y);
  if DotProductF(Offset, Normal) < 0 then Result := True
  else Result := False;
end;
{ @end $4CE484 }

{ @routine $4CE4FC IsLeftOfDirectedLine }
function IsLeftOfDirectedLine(Point, Origin, Direction: TPointF): Boolean;
var Normal, Offset: TPointF;
begin
  Normal := PerpendicularVector(Direction);
  Offset := MakeVectorF(Point.X - Origin.X, Point.Y - Origin.Y);
  if DotProductF(Offset, Normal) > 0 then Result := True
  else Result := False;
end;
{ @end $4CE4FC }

{ @routine $4CE574 MakeVectorF }
function MakeVectorF(X, Y: Single): TPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;
{ @end $4CE574 }

{ @routine $4CE588 VectorBetweenPoints }
function VectorBetweenPoints(First, Last: TPointF): TPointF;
begin
  Result.X := Last.X - First.X;
  Result.Y := Last.Y - First.Y;
end;
{ @end $4CE588 }

{ @routine $4CE5B8 GetLineEquation }
procedure GetLineEquation(First, Last: TPointF; var A, B, C: Single);
begin
  if Abs(First.X - Last.X) < Abs(First.Y - Last.Y) then
  begin
    A := 1;
    B := (First.X - Last.X) * A / (Last.Y - First.Y);
    C := -A * First.X - B * First.Y;
  end
  else
  begin
    B := 1;
    A := (First.Y - Last.Y) * B / (Last.X - First.X);
    C := -A * First.X - B * First.Y;
  end;
end;
{ @end $4CE5B8 }

{ @routine $4CE654 IntersectLinesF }
function IntersectLinesF(First1, Last1, First2, Last2: TPointF): TPointF;
var A1, B1, C1, A2, B2, C2: Single;
begin
  GetLineEquation(First1, Last1, A1, B1, C1);
  GetLineEquation(First2, Last2, A2, B2, C2);
  if A2 * B1 - A1 * B2 = 0 then Result.X := 1e20
  else Result.X := (B2 * C1 - B1 * C2) / (A2 * B1 - A1 * B2);
  if A1 * B2 - A2 * B1 = 0 then Result.Y := 1e20
  else Result.Y := (A2 * C1 - A1 * C2) / (A1 * B2 - A2 * B1);
end;
{ @end $4CE654 }

{ @routine $4CE73C IntersectSegmentWithLine }
function IntersectSegmentWithLine(First, Last: TPointF; A, B, C: Single; var Intersection: TPointF): Boolean;
var LineA, LineB, LineC: Single; Point: TPointF;
begin
  GetLineEquation(First, Last, LineA, LineB, LineC);
  Result := False;
  if (Abs(LineA - A) < 0.0001) and (Abs(LineB - B) < 0.0001) then Exit;
  Point.X := (B * LineC - LineB * C) / (A * LineB - LineA * B);
  Point.Y := (A * LineC - LineA * C) / (LineA * B - A * LineB);
  if (DotProductF(VectorBetweenPoints(Point, First), VectorBetweenPoints(Point, Last)) < 0)
    or PointsNearlyEqualF(Point, First) or PointsNearlyEqualF(Point, Last) then
  begin
    Result := True;
    Intersection := Point;
  end;
end;
{ @end $4CE73C }

{ @routine $4CE85C IntersectSegmentWithDirectedLine }
function IntersectSegmentWithDirectedLine(First, Last, LineFirst, LineLast: TPointF; var Intersection: TPointF): Boolean;
var Direction: TPointF;
begin
  Direction := VectorBetweenPoints(LineFirst, LineLast);
  if IsLeftOfDirectedLine(First, LineFirst, Direction) <> IsLeftOfDirectedLine(Last, LineFirst, Direction) then
  begin
    Intersection := IntersectLinesF(First, Last, LineFirst, LineLast);
    Result := True;
  end
  else Result := False;
end;
{ @end $4CE85C }

{ @routine $4CE8E8 IntersectSegmentsF }
function IntersectSegmentsF(First1, Last1, First2, Last2: TPointF; var Intersection: TPointF): Boolean;
begin
  Result := True;
  if not IntersectSegmentWithDirectedLine(First1, Last1, First2, Last2, Intersection)
    or not IntersectSegmentWithDirectedLine(First2, Last2, First1, Last1, Intersection) then Result := False;
end;
{ @end $4CE8E8 }

{ @routine $4CE950 MakeRectF }
function MakeRectF(Left, Top, Right, Bottom: Single): TRectF;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Right;
  Result.Bottom := Bottom;
end;
{ @end $4CE950 }

{ @routine $4CE970 RectFromPointsF }
function RectFromPointsF(First, Last: TPointF): TRectF;
begin
  Result.Left := First.X;
  Result.Top := First.Y;
  Result.Right := Last.X;
  Result.Bottom := Last.Y;
end;
{ @end $4CE970 }

{ @routine $4CE9A4 PointsNearlyEqualF }
function PointsNearlyEqualF(First, Last: TPointF): Boolean;
begin
  if (Abs(First.X - Last.X) < 0.1) and (Abs(First.Y - Last.Y) < 0.1) then Result := True
  else Result := False;
end;
{ @end $4CE9A4 }

{ @routine $4CEA00 SegmentsNearlyEqualF }
function SegmentsNearlyEqualF(First1, Last1, First2, Last2: TPointF): Boolean;
begin
  if (PointsNearlyEqualF(First1, First2) and PointsNearlyEqualF(Last1, Last2))
    or (PointsNearlyEqualF(First1, Last2) and PointsNearlyEqualF(Last1, First2)) then Result := True
  else Result := False;
end;
{ @end $4CEA00 }

{ @routine $4CEA70 ScalarsNearlyEqualF }
function ScalarsNearlyEqualF(First, Last: Single): Boolean;
begin
  if Abs(First - Last) < 0.1 then Result := True
  else Result := False;
end;
{ @end $4CEA70 }

{ @routine $4CEAA0 PointDistanceF }
function PointDistanceF(First, Last: TPointF): Single;
begin
  Result := VectorLengthF(VectorBetweenPoints(First, Last));
end;
{ @end $4CEAA0 }

{ @routine $4CEADC PointSegmentDistanceF }
function PointSegmentDistanceF(First, Last, Point: TPointF): Single;
var Normal, Intersection: TPointF; FirstDistance, LastDistance: Single;
begin
  Normal := PerpendicularVector(VectorBetweenPoints(First, Last));
  if IntersectSegmentWithDirectedLine(First, Last, Point, MakePointF(Point.X + Normal.X, Point.Y + Normal.Y), Intersection) then
    Result := PointDistanceF(Point, Intersection)
  else
  begin
    FirstDistance := PointDistanceF(First, Point);
    LastDistance := PointDistanceF(Last, Point);
    if FirstDistance > LastDistance then Result := LastDistance
    else Result := FirstDistance;
  end;
end;
{ @end $4CEADC }

{ @routine $4CEBBC ClassifyPointToSegment }
function ClassifyPointToSegment(First, Last, Point: TPointF): Integer;
var Direction, Offset: TPointF; Cross: Single;
begin
  Direction := MakePointF(Last.X - First.X, Last.Y - First.Y);
  Offset := MakePointF(Point.X - First.X, Point.Y - First.Y);
  Cross := Direction.X * Offset.Y - Direction.Y * Offset.X;
  if Cross > 0 then Result := 1
  else if Cross < 0 then Result := 2
  else if (Direction.X * Offset.X < 0) or (Direction.Y * Offset.Y < 0) then Result := 3
  else if Sqrt(Direction.X * Direction.X + Direction.Y * Direction.Y) < Sqrt(Offset.X * Offset.X + Offset.Y * Offset.Y) then Result := 4
  else if (First.X = Point.X) and (First.Y = Point.Y) then Result := 6
  else if (Last.X = Point.X) and (Last.Y = Point.Y) then Result := 7
  else Result := 5;
end;
{ @end $4CEBBC }

{ @routine $4CED2C TPolygon2D_Create }
constructor TPolygon2D.Create;
begin
  Next := nil;
  Previous := nil;
  AreaValid := False;
  Flag39 := False;
  CachedArea := 0;
  Points := TList.Create;
  GroupId := -1;
  Unknown14 := -1;
  Extent := MakePointF(0, 0);
  Bounds := MakeRectF(0, 0, 0, 0);
end;
{ @end $4CED2C }

{ @routine $4CEDCC TPolygon2D_CreateTriangle }
constructor TPolygon2D.CreateTriangle(A, B, C: TPointF);
begin
  Next := nil;
  Previous := nil;
  AreaValid := False;
  Flag39 := False;
  CachedArea := 0;
  Points := TList.Create;
  GroupId := -1;
  Unknown14 := -1;
  Extent := MakePointF(0, 0);
  Bounds := MakeRectF(0, 0, 0, 0);
  SetTriangle(A, B, C);
end;
{ @end $4CEDCC }

{ @routine $4CEE98 TPolygon2D_Destroy }
destructor TPolygon2D.Destroy;
begin
  Clear;
  Points.Free;
  if Next <> nil then Next.Free;
end;
{ @end $4CEE98 }

{ @routine $4CEECC TPolygon2D_Clear }
procedure TPolygon2D.Clear;
var Index: Integer; Point: PPointF;
begin
  for Index := 0 to Points.Count - 1 do
  begin
    Point := Points[Index];
    Dispose(Point);
  end;
  Points.Clear;
  GroupId := -1;
  Unknown14 := -1;
  Extent := MakePointF(0, 0);
  Bounds := MakeRectF(0, 0, 0, 0);
  AreaValid := False;
  Flag39 := False;
end;
{ @end $4CEECC }

{ @routine $4CEF58 TPolygon2D_SetRectangle }
procedure TPolygon2D.SetRectangle(Rect: TRect);
var Point: PPointF;
begin
  Clear;
  GetMem(Point, SizeOf(TPointF));
  Point.X := Rect.Left;
  Point.Y := Rect.Top;
  Points.Add(Point);
  GetMem(Point, SizeOf(TPointF));
  Point.X := Rect.Right;
  Point.Y := Rect.Top;
  Points.Add(Point);
  GetMem(Point, SizeOf(TPointF));
  Point.X := Rect.Right;
  Point.Y := Rect.Bottom;
  Points.Add(Point);
  GetMem(Point, SizeOf(TPointF));
  Point.X := Rect.Left;
  Point.Y := Rect.Bottom;
  Points.Add(Point);
  Bounds := MakeRectF(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
  Extent := MakePointF(Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
  AreaValid := False;
  Flag39 := False;
end;
{ @end $4CEF58 }

{ @routine $4CF080 TPolygon2D_TakePoints }
procedure TPolygon2D.TakePoints(NewPoints: TList);
begin
  Clear;
  Points.Free;
  Points := NewPoints;
  AreaValid := False;
  Flag39 := False;
  RecalculateBounds;
end;
{ @end $4CF080 }

{ @routine $4CF0AC TPolygon2D_SetTriangle }
procedure TPolygon2D.SetTriangle(A, B, C: TPointF);
var Point: PPointF;
begin
  Clear;
  GetMem(Point, SizeOf(TPointF));
  Point.X := A.X;
  Point.Y := A.Y;
  Points.Add(Point);
  GetMem(Point, SizeOf(TPointF));
  Point.X := B.X;
  Point.Y := B.Y;
  Points.Add(Point);
  GetMem(Point, SizeOf(TPointF));
  Point.X := C.X;
  Point.Y := C.Y;
  Points.Add(Point);
  AreaValid := False;
  Flag39 := False;
  RecalculateBounds;
end;
{ @end $4CF0AC }

{ @routine $4CF14C TPolygon2D_RecalculateBounds }
procedure TPolygon2D.RecalculateBounds;
var Index: Integer; Point: PPointF;
begin
  if Points.Count = 0 then Exit;
  Point := Points[0];
  Bounds := RectFromPointsF(Point^, Point^);
  for Index := 0 to Points.Count - 1 do
  begin
    Point := Points[Index];
    if Point.X < Bounds.Left then Bounds.Left := Point.X;
    if Point.X > Bounds.Right then Bounds.Right := Point.X;
    if Point.Y < Bounds.Top then Bounds.Top := Point.Y;
    if Point.Y > Bounds.Bottom then Bounds.Bottom := Point.Y;
  end;
  Extent := MakePointF(Bounds.Right - Bounds.Left, Bounds.Bottom - Bounds.Top);
  GetArea;
end;
{ @end $4CF14C }

{ @routine $4CF220 TPolygon2D_Append }
procedure TPolygon2D.Append(Polygon: TPolygon2D);
var Tail: TPolygon2D;
begin
  if Next = nil then
  begin
    Next := Polygon;
    Polygon.Previous := Self;
  end
  else
  begin
    Tail := Self;
    while Tail.Next <> nil do Tail := Tail.Next;
    Tail.Append(Polygon);
  end;
end;
{ @end $4CF220 }

{ @routine $4CF23C TPolygon2D_InsertAfter }
procedure TPolygon2D.InsertAfter(Polygon: TPolygon2D);
begin
  Polygon.Previous := Self;
  Polygon.Next := Next;
  if Next <> nil then Next.Previous := Polygon;
  Next := Polygon;
end;
{ @end $4CF23C }

{ @routine $4CF254 TPolygon2D_SplitChainByLine }
procedure TPolygon2D.SplitChainByLine(A, B, C: Single);
var
  Index: Integer;
  Point, Last: PPointF;
  FirstIndex, LastIndex: Integer;
  FirstIntersection, LastIntersection, Intersection: TPointF;
  NewPolygon, Following: TPolygon2D;
  FirstPoints, LastPoints: TList;
  Current: TPolygon2D;
begin
  Current := Self;
  while Current <> nil do
  begin
    FirstIndex := -1;
    LastIndex := -1;
    for Index := 0 to Current.Points.Count - 1 do
    begin
      Point := Current.Points[Index];
      if Index = Current.Points.Count - 1 then Last := Current.Points[0]
      else Last := Current.Points[Index + 1];
      if IntersectSegmentWithLine(Point^, Last^, A, B, C, Intersection)
        and not PointsNearlyEqualF(Last^, Intersection) then
      begin
        if FirstIndex = -1 then
        begin
          FirstIndex := Index;
          FirstIntersection := Intersection;
        end
        else if LastIndex = -1 then
        begin
          LastIndex := Index;
          LastIntersection := Intersection;
        end
        else
          raise Exception.Create('Глюк! Линия пересекает полигон в трех точках');
      end;
    end;
    if (FirstIndex > -1) and (LastIndex > -1) then
    begin
      NewPolygon := TPolygon2D.Create;
      FirstPoints := TList.Create;
      for Index := 0 to FirstIndex do
      begin
        Point := Current.Points[Index];
        FirstPoints.Add(Point);
      end;
      Last := Current.Points[FirstIndex];
      if not PointsNearlyEqualF(Last^, FirstIntersection) then
      begin
        GetMem(Point, SizeOf(TPointF));
        Point.X := FirstIntersection.X;
        Point.Y := FirstIntersection.Y;
        FirstPoints.Add(Point);
      end;
      GetMem(Point, SizeOf(TPointF));
      Point.X := LastIntersection.X;
      Point.Y := LastIntersection.Y;
      FirstPoints.Add(Point);
      for Index := LastIndex + 1 to Current.Points.Count - 1 do
      begin
        Point := Current.Points[Index];
        FirstPoints.Add(Point);
      end;
      LastPoints := TList.Create;
      Last := Current.Points[LastIndex];
      if not PointsNearlyEqualF(LastIntersection, Last^) then
      begin
        GetMem(Point, SizeOf(TPointF));
        Point.X := LastIntersection.X;
        Point.Y := LastIntersection.Y;
        LastPoints.Add(Point);
      end;
      GetMem(Point, SizeOf(TPointF));
      Point.X := FirstIntersection.X;
      Point.Y := FirstIntersection.Y;
      LastPoints.Add(Point);
      for Index := FirstIndex + 1 to LastIndex do
      begin
        Point := Current.Points[Index];
        LastPoints.Add(Point);
      end;
      NewPolygon.TakePoints(FirstPoints);
      NewPolygon.GroupId := GroupId;
      NewPolygon.Flag39 := False;
      Current.Points.Free;
      Current.Points := LastPoints;
      Current.RecalculateBounds;
      Current.AreaValid := False;
      Current.Flag39 := False;
      Following := Current.Next;
      Current.InsertAfter(NewPolygon);
      Current := Following;
    end
    else Current := Current.Next;
  end;
end;
{ @end $4CF254 }

{ @routine $4CF554 TPolygon2D_SplitChainByPoints }
procedure TPolygon2D.SplitChainByPoints(First, Last: TPointF);
var A, B, C: Single;
begin
  GetLineEquation(First, Last, A, B, C);
  SplitChainByLine(A, B, C);
end;
{ @end $4CF554 }

{ @routine $4CF5A0 TPolygon2D_ExtractFollowingGroup }
function TPolygon2D.ExtractFollowingGroup(Id: Integer): TPolygon2D;
var Head, Current, Removed: TPolygon2D;
begin
  Flag39 := False;
  AreaValid := False;
  Head := nil;
  Current := Next;
  while Current <> nil do
  begin
    if Current.GroupId = Id then
    begin
      Removed := Current;
      Current := Current.Next;
      if Removed.Previous <> nil then Removed.Previous.Next := Removed.Next;
      if Removed.Next <> nil then Removed.Next.Previous := Removed.Previous;
      Removed.Next := nil;
      Removed.Previous := nil;
      if Head = nil then Head := Removed
      else Head.Append(Removed);
    end
    else Current := Current.Next;
  end;
  Result := Head;
end;
{ @end $4CF5A0 }

{ @routine $4CF604 TPolygon2D_ContainsPoint }
function TPolygon2D.ContainsPoint(Point: TPointF): Boolean;
var Index: Integer; First, Last: PPointF;
begin
  Result := False;
  if (Point.X >= Bounds.Left) and (Point.X <= Bounds.Right)
    and (Point.Y >= Bounds.Top) and (Point.Y <= Bounds.Bottom) then
  begin
    for Index := 0 to Points.Count - 1 do
    begin
      First := Points[Index];
      if Index = Points.Count - 1 then Last := Points[0]
      else Last := Points[Index + 1];
      if IsRightOfDirectedLine(Point, First^, VectorBetweenPoints(First^, Last^)) then Exit;
    end;
    Result := True;
  end;
end;
{ @end $4CF604 }

{ @routine $4CF6C4 TPolygon2D_ChainContainsPoint }
function TPolygon2D.ChainContainsPoint(Point: TPointF): Boolean;
var Polygon: TPolygon2D;
begin
  Result := True;
  Polygon := Self;
  while Polygon <> nil do
  begin
    if Polygon.ContainsPoint(Point) then Exit;
    Polygon := Polygon.Next;
  end;
  Result := False;
end;
{ @end $4CF6C4 }

{ @routine $4CF6F8 TPolygon2D_FindContainingPolygon }
function TPolygon2D.FindContainingPolygon(Point: TPointF): TPolygon2D;
var Polygon: TPolygon2D;
begin
  Polygon := Self;
  while Polygon <> nil do
  begin
    if Polygon.ContainsPoint(Point) then Break;
    Polygon := Polygon.Next;
  end;
  Result := Polygon;
end;
{ @end $4CF6F8 }

{ @routine $4CF728 TPolygon2D_AssignGroupAtPoint }
function TPolygon2D.AssignGroupAtPoint(Point: TPointF; Id: Integer): Boolean;
var Polygon: TPolygon2D;
begin
  Result := False;
  Polygon := FindContainingPolygon(Point);
  if Polygon <> nil then
  begin
    if Polygon.GroupId = Id then Result := True;
    if Polygon.GroupId = -1 then
    begin
      Result := True;
      Polygon.GroupId := Id;
    end;
  end;
end;
{ @end $4CF728 }

{ @routine $4CF760 TPolygon2D_ExtractBoundaryEdges }
function TPolygon2D.ExtractBoundaryEdges: TList;
var Edges, Boundary: TList; Polygon: TPolygon2D;
begin
  Boundary := TList.Create;
  Polygon := Self;
  while Polygon <> nil do
  begin
    Edges := Polygon.ExtractEdges;
    Boundary := MergeUnsharedEdges(Boundary, Edges);
    Polygon := Polygon.Next;
  end;
  Result := Boundary;
end;
{ @end $4CF760 }

{ @routine $4CF79C TPolygon2D_MergeUnsharedEdges }
function TPolygon2D.MergeUnsharedEdges(First, Second: TList): TList;
var Index, OtherIndex: Integer; Source, Edge: PPolygonEdge; Edges: TList; Found: Boolean;
begin
  Edges := TList.Create;
  for Index := 0 to First.Count - 1 do
  begin
    Source := First[Index];
    Found := False;
    for OtherIndex := 0 to Second.Count - 1 do
    begin
      Edge := Second[OtherIndex];
      if SegmentsNearlyEqualF(Source.First, Source.Last, Edge.First, Edge.Last) then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      GetMem(Edge, SizeOf(TPolygonEdge));
      Edge.First := Source.First;
      Edge.Last := Source.Last;
      Edges.Add(Edge);
    end;
  end;
  for Index := 0 to Second.Count - 1 do
  begin
    Source := Second[Index];
    Found := False;
    for OtherIndex := 0 to First.Count - 1 do
    begin
      Edge := First[OtherIndex];
      if SegmentsNearlyEqualF(Source.First, Source.Last, Edge.First, Edge.Last) then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      GetMem(Edge, SizeOf(TPolygonEdge));
      Edge.First := Source.First;
      Edge.Last := Source.Last;
      Edges.Add(Edge);
    end;
  end;
  for Index := 0 to First.Count - 1 do
  begin
    Source := First[Index];
    Dispose(Source);
  end;
  for Index := 0 to Second.Count - 1 do
  begin
    Source := Second[Index];
    Dispose(Source);
  end;
  First.Free;
  Second.Free;
  Result := Edges;
end;
{ @end $4CF79C }

{ @routine $4CF9AC TPolygon2D_ExtractEdges }
function TPolygon2D.ExtractEdges: TList;
var Edges: TList; Edge: PPolygonEdge; First, Last: PPointF; Index: Integer;
begin
  Edges := TList.Create;
  for Index := 0 to Points.Count - 1 do
  begin
    First := Points[Index];
    if Index = Points.Count - 1 then Last := Points[0]
    else Last := Points[Index + 1];
    GetMem(Edge, SizeOf(TPolygonEdge));
    Edge.First := First^;
    Edge.Last := Last^;
    Edges.Add(Edge);
  end;
  Result := Edges;
end;
{ @end $4CF9AC }

{ @routine $4CFA44 TPolygon2D_ResetChainGroups }
procedure TPolygon2D.ResetChainGroups;
var Polygon: TPolygon2D;
begin
  Polygon := Self;
  while Polygon <> nil do
  begin
    Polygon.GroupId := -1;
    Polygon.Unknown14 := -1;
    Polygon := Polygon.Next;
  end;
end;
{ @end $4CFA44 }

{ @routine $4CFA60 TPolygon2D_CountChain }
function TPolygon2D.CountChain: Integer;
var Polygon: TPolygon2D;
begin
  Result := 0;
  Polygon := Self;
  while Polygon <> nil do
  begin
    Inc(Result);
    Polygon := Polygon.Next;
  end;
end;
{ @end $4CFA60 }

{ @routine $4CFA74 TPolygon2D_GetChainItem }
function TPolygon2D.GetChainItem(Index: Integer): TPolygon2D;
var Polygon: TPolygon2D;
begin
  Polygon := Self;
  while Polygon <> nil do
  begin
    if Index <= 0 then Break;
    Dec(Index);
    Polygon := Polygon.Next;
  end;
  Result := Polygon;
end;
{ @end $4CFA74 }

{ @routine $4CFA88 TPolygon2D_GetArea }
function TPolygon2D.GetArea: Single;
var Index: Integer; TriangleFirst, Middle, Last: PPointF; A, B, C, Height, Square: Single;
begin
  if AreaValid then Result := CachedArea
  else
  begin
    Result := 0;
    CachedArea := 0;
    if Points.Count >= 3 then
    begin
      TriangleFirst := Points[0];
      for Index := 1 to Points.Count - 2 do
      begin
        with Points do Middle := Items[Index];
        Last := Points[Index + 1];
        A := PointDistanceF(TriangleFirst^, Middle^);
        B := PointDistanceF(TriangleFirst^, Last^);
        C := PointDistanceF(Middle^, Last^);
        if A = 0 then A := 1;
        Square := A * A + B * B - C * C;
        if Square < 0 then Square := 0.01;
        Square := B * B - Sqr(Square) / (4 * A * A);
        if Square < 0 then Square := 0.01;
        Height := Sqrt(Square);
        CachedArea := 0.5 * Height * A + CachedArea;
      end;
      AreaValid := True;
    end;
  end;
end;
{ @end $4CFA88 }

{ @routine $4CFBF8 TPolygon2D_GetChainArea }
function TPolygon2D.GetChainArea: Single;
var Polygon: TPolygon2D;
begin
  Result := 0;
  Polygon := Self;
  while Polygon <> nil do
  begin
    Result := Polygon.GetArea + Result;
    Polygon := Polygon.Next;
  end;
end;
{ @end $4CFBF8 }

{ @routine $4CFC20 TPolygon2D_IntersectsPolygon }
function TPolygon2D.IntersectsPolygon(Polygon: TPolygon2D): Boolean;
var Index: Integer; First, Last: PPointF;
begin
  for Index := 0 to Points.Count - 1 do
  begin
    First := Points[Index];
    if Index = Points.Count - 1 then Last := Points[0]
    else Last := Points[Index + 1];
    if Polygon.IntersectsSegment(First^, Last^) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
{ @end $4CFC20 }

{ @routine $4CFC90 TPolygon2D_IntersectsEdge }
function TPolygon2D.IntersectsEdge(Edge: PPolygonEdge): Boolean;
var Index: Integer; First, Last: PPointF; Intersection: TPointF;
begin
  for Index := 0 to Points.Count - 1 do
  begin
    First := Points[Index];
    if Index = Points.Count - 1 then Last := Points[0]
    else Last := Points[Index + 1];
    if IntersectSegmentsF(First^, Last^, Edge.First, Edge.Last, Intersection)
      and not PointsNearlyEqualF(First^, Intersection) and not PointsNearlyEqualF(Last^, Intersection) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;
{ @end $4CFC90 }

{ @routine $4CFD2C TPolygon2D_IntersectsSegment }
function TPolygon2D.IntersectsSegment(First, Last: TPointF): Boolean;
var Edge: TPolygonEdge;
begin
  Edge.First := First;
  Edge.Last := Last;
  Result := IntersectsEdge(@Edge);
end;
{ @end $4CFD2C }

{ @routine $4CFD70 TPolygon2D_ChainSelfIntersects }
function TPolygon2D.ChainSelfIntersects: Boolean;
var First, Last: TPolygon2D;
begin
  First := Self;
  while First <> nil do
  begin
    Last := First.Next;
    while Last <> nil do
    begin
      if (First <> Last) and First.IntersectsPolygon(Last) then
      begin
        Result := True;
        Exit;
      end;
      Last := Last.Next;
    end;
    First := First.Next;
  end;
  Result := False;
end;
{ @end $4CFD70 }

{ @routine $4CFDA8 TPolygon2D_IntersectsChain }
function TPolygon2D.IntersectsChain(Polygon: TPolygon2D): Boolean;
var First, Last: TPolygon2D;
begin
  First := Self;
  while First <> nil do
  begin
    Last := Polygon;
    while Last <> nil do
    begin
      if (First <> Last) and First.IntersectsPolygon(Last) then
      begin
        Result := True;
        Exit;
      end;
      Last := Last.Next;
    end;
    First := First.Next;
  end;
  Result := False;
end;
{ @end $4CFDA8 }

end.

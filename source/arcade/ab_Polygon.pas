unit ab_Polygon;
// Unit bracket (inferred): CODE 0x004FBA88..0x004FC657; inclusive evidence, not full bounds.

interface

uses EC_Buf, EC_Struct, ab_StopLine;

type
  TabPolygonVertex = record // @size $08
    Point: PabStopPoint; // @offset $00
    Color: PCardinal; // @offset $04
  end;
  PabPolygon = ^TabPolygon;
  TabPolygon = record // @size $34
    Prev: PabPolygon; // @offset $00
    Next: PabPolygon; // @offset $04
    Vertices: array[0..2] of TabPolygonVertex; // @offset $08
    LegacyMapValue: Integer; // @offset $20 Written only by the retained legacy editor serializer.
    EditorColor: Cardinal; // @offset $24
    EditorColorKind: Integer; // @offset $28 Debug Q/W/E/R tags 0..3.
    MapValue30: Integer; // @offset $30  Serialized value; meaning not yet established.
  end;
  PabPolygonGroup = ^TabOptGroup;
  TabOptGroup = record // @size $68
    Polygons: array of PabPolygon; // @offset $00
    Corners: array[0..3] of TVector3D; // @offset $08
  end;
  PabPolygonCell = ^TabOptUnit;
  TabOptUnit = record // @size $08
    Points: array of PabStopPoint; // @offset $00
    Groups: array of PabPolygonGroup; // @offset $04
  end;

function ab_Polygon_FindByPoint(Point: PabStopPoint): PabPolygon; // @addr $4FBBCC
procedure ab_Polygon_DrawVisible; // @addr $4FC3B8
procedure ab_Polygon_Save(Buffer: TBufEC); // @addr $4FC4A4
procedure ab_Polygon_Clear; // @addr $4FBB84
function ab_Polygon_Count: Integer; // @addr $4FBBB4
procedure ab_Polygon_ClearVisibility; // @addr $4FBBF4
procedure ab_Polygon_LoadVisibility(Buffer: TBufEC); // @addr $4FBCAC
procedure ab_Polygon_SelectVisibilityCell; // @addr $4FC010
procedure ab_Polygon_ProjectVisiblePoints; // @addr $4FC0A8
procedure ab_Polygon_QueueUpdateRects; // @addr $4FC134
procedure ab_Polygon_Load(Buffer: TBufEC); // @addr $4FC54C

var
  FirstPolygon: PabPolygon = nil; // @addr $6186E8
  LastPolygon: PabPolygon = nil; // @addr $6186EC
  PolygonStorage: PabPolygon; // @addr $61CF18
  PolygonGroups: array of TabOptGroup; // @addr $61CF1C
  PolygonCells: array of TabOptUnit; // @addr $61CF20
  LongitudeCellCount: Integer; // @addr $61CF24
  PolarCellCount: Integer; // @addr $61CF28
  CurrentPolygonCell: PabPolygonCell; // @addr $61CF2C

implementation

// @unit-initialization $4FC650
// @unit-finalization $4FC600

uses Classes, EC_Mem, GI_Tail, ab_Global, GR_Main, Globals;

{ @routine $4FBB84 ab_Polygon_Clear }
procedure ab_Polygon_Clear;
begin
  ab_Polygon_ClearVisibility;
  if PolygonStorage <> nil then
  begin
    FreeEC(PolygonStorage);
    PolygonStorage := nil;
  end;
  FirstPolygon := nil;
  LastPolygon := nil;
end;
{ @end $4FBB84 }

{ @routine $4FBBB4 ab_Polygon_Count }
function ab_Polygon_Count: Integer;
var
  Polygon: PabPolygon;
begin
  Result := 0;
  Polygon := FirstPolygon;
  while Polygon <> nil do
  begin
    Inc(Result);
    Polygon := Polygon.Next;
  end;
end;
{ @end $4FBBB4 }

{ @routine $4FBBCC ab_Polygon_FindByPoint }
function ab_Polygon_FindByPoint(Point: PabStopPoint): PabPolygon;
var Polygon: PabPolygon; Index: Integer;
begin
  Polygon := FirstPolygon;
  while Polygon <> nil do begin
    for Index := 0 to 2 do
      if Polygon.Vertices[Index].Point = Point then begin
        Result := Polygon;
        Exit;
      end;
    Polygon := Polygon.Next;
  end;
  Result := nil;
end;
{ @end $4FBBCC }

{ @routine $4FBBF4 ab_Polygon_ClearVisibility }
procedure ab_Polygon_ClearVisibility;
var
  Index: Integer;
begin
  for Index := 0 to High(PolygonCells) do
  begin
    PolygonCells[Index].Points := nil;
    PolygonCells[Index].Groups := nil;
  end;
  for Index := 0 to High(PolygonGroups) do PolygonGroups[Index].Polygons := nil;
  PolygonGroups := nil;
  PolygonCells := nil;
  CurrentPolygonCell := nil;
end;
{ @end $4FBBF4 }

{ @routine $4FBCAC ab_Polygon_LoadVisibility }
procedure ab_Polygon_LoadVisibility(Buffer: TBufEC);
var
  Index, ItemIndex, Count: Integer;
  Polygons: array of PabPolygon;
  Polygon: PabPolygon;
  Cursor: Pointer;
  PointIndex: Integer;
  Group: PabPolygonGroup;
begin
  ab_Polygon_ClearVisibility;
  Count := ab_Polygon_Count;
  SetLength(Polygons, Count);
  Index := 0;
  Polygon := FirstPolygon;
  while Polygon <> nil do
  begin
    Polygons[Index] := Polygon;
    Inc(Index);
    Polygon := Polygon.Next;
  end;
  LongitudeCellCount := Buffer.GetInt32;
  PolarCellCount := Buffer.GetInt32;
  SetLength(PolygonCells, LongitudeCellCount * PolarCellCount);
  SetLength(PolygonGroups, Buffer.GetInt32);
  for Index := 0 to High(PolygonGroups) do
  begin
    Group := @PolygonGroups[Index];
    Count := Buffer.GetWord;
    SetLength(Group.Polygons, Count);
    Cursor := Pointer(PAnsiChar(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to High(Group.Polygons) do
    begin
      Group.Polygons[ItemIndex] := Polygons[PWord(Cursor)^];
      Cursor := Pointer(PAnsiChar(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
    Cursor := Pointer(PAnsiChar(Buffer.Data) + Buffer.Position);
    Group.Corners[0].X := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[0].Y := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[0].Z := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[1].X := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[1].Y := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[1].Z := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[2].X := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[2].Y := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[2].Z := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[3].X := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[3].Y := PSingle(Cursor)^;
    Inc(Integer(Cursor), 4);
    Group.Corners[3].Z := PSingle(Cursor)^;
    Buffer.SetPosition(Buffer.Position + 48);
  end;
  for Index := 0 to LongitudeCellCount * PolarCellCount - 1 do
  begin
    CurrentPolygonCell := @PolygonCells[Index];
    Count := Buffer.GetWord;
    SetLength(CurrentPolygonCell.Points, Count);
    Cursor := Pointer(PAnsiChar(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to Count - 1 do
    begin
      PointIndex := PWord(Cursor)^;
      CurrentPolygonCell.Points[ItemIndex] := StopPointIndex[PointIndex];
      Cursor := Pointer(PAnsiChar(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
    Count := Buffer.GetWord;
    SetLength(CurrentPolygonCell.Groups, Count);
    Cursor := Pointer(PAnsiChar(Buffer.Data) + Buffer.Position);
    for ItemIndex := 0 to Count - 1 do
    begin
      CurrentPolygonCell.Groups[ItemIndex] := @PolygonGroups[PWord(Cursor)^];
      Cursor := Pointer(PAnsiChar(Cursor) + 2);
    end;
    Buffer.SetPosition(Buffer.Position + Count * 2);
  end;
  Polygons := nil;
  CurrentPolygonCell := nil;
end;
{ @end $4FBCAC }

{ @routine $4FC010 ab_Polygon_SelectVisibilityCell }
procedure ab_Polygon_SelectVisibilityCell;
var
  LongitudeIndex, PolarIndex: Integer;
begin
  LongitudeIndex := Round(SphereViewState.LongitudeDegrees / 360 * LongitudeCellCount);
  if LongitudeIndex >= LongitudeCellCount then LongitudeIndex := 0;
  PolarIndex := Round(SphereViewState.PolarAngleDegrees / 180 * (PolarCellCount - 1));
  if PolarIndex >= PolarCellCount then RaiseWideMessage('ab_OptCur');
  CurrentPolygonCell := @PolygonCells[LongitudeIndex * PolarCellCount + PolarIndex];
end;
{ @end $4FC010 }

{ @routine $4FC0A8 ab_Polygon_ProjectVisiblePoints }
procedure ab_Polygon_ProjectVisiblePoints;
var
  Index, Count: Integer;
  Point: PabStopPoint;
  Projected: TVector3D;
begin
  if CurrentPolygonCell = nil then Exit;
  if CurrentPolygonCell.Points = nil then Exit;
  Count := High(CurrentPolygonCell.Points) + 1;
  for Index := 0 to Count - 1 do
  begin
    Point := CurrentPolygonCell.Points[Index];
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Point.Position);
    Point.Projected := True;
    Point.ScreenX := ArcadeBattleScreen.WorldCenterX + Round(Projected.X);
    Point.ScreenY := ArcadeBattleScreen.WorldCenterY + Round(Projected.Y);
  end;
end;
{ @end $4FC0A8 }

{ @routine $4FC134 ab_Polygon_QueueUpdateRects }
procedure ab_Polygon_QueueUpdateRects;
var
  Index, Count: Integer;
  Group: PabPolygonGroup;
  MinX, MaxX, MinY, MaxY: Double;
  CenterX, CenterY: Integer;
  Projected: TVector3D;
begin
  if CurrentPolygonCell = nil then Exit;
  if CurrentPolygonCell.Groups = nil then Exit;
  CenterX := ArcadeBattleScreen.WorldCenterX;
  CenterY := ArcadeBattleScreen.WorldCenterY;
  Count := High(CurrentPolygonCell.Groups) + 1;
  for Index := 0 to Count - 1 do
  begin
    Group := CurrentPolygonCell.Groups[Index];
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[0]);
    MinX := Projected.X;
    MaxX := Projected.X;
    MinY := Projected.Y;
    MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[1]);
    if Projected.X < MinX then MinX := Projected.X
    else if Projected.X > MaxX then MaxX := Projected.X;
    if Projected.Y < MinY then MinY := Projected.Y
    else if Projected.Y > MaxY then MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[2]);
    if Projected.X < MinX then MinX := Projected.X
    else if Projected.X > MaxX then MaxX := Projected.X;
    if Projected.Y < MinY then MinY := Projected.Y
    else if Projected.Y > MaxY then MaxY := Projected.Y;
    Projected := ProjectPointByMatrix(SphereProjectionMatrix, Group.Corners[3]);
    if Projected.X < MinX then MinX := Projected.X
    else if Projected.X > MaxX then MaxX := Projected.X;
    if Projected.Y < MinY then MinY := Projected.Y
    else if Projected.Y > MaxY then MaxY := Projected.Y;
    ArcadeBattleScreen.QueueUpdateRect(Classes.Rect(CenterX + Round(MinX), CenterY + Round(MinY), CenterX + Round(MaxX) + 1, CenterY + Round(MaxY) + 1));
  end;
end;
{ @end $4FC134 }

{ @routine $4FC3B8 ab_Polygon_DrawVisible }
procedure ab_Polygon_DrawVisible;
var GroupIndex, PolygonIndex, Count: Integer; Group: PabPolygonGroup; Polygon: PabPolygon;
begin
  if (CurrentPolygonCell <> nil) and (CurrentPolygonCell.Groups <> nil) then begin
    Count := High(CurrentPolygonCell.Groups) + 1;
    for GroupIndex := 0 to Count - 1 do begin
      Group := CurrentPolygonCell.Groups[GroupIndex];
      Count := High(Group.Polygons) + 1;
      for PolygonIndex := 0 to Count - 1 do begin
        Polygon := Group.Polygons[PolygonIndex];
        TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
          Polygon.Vertices[0].Point.ScreenX, Polygon.Vertices[0].Point.ScreenY, Polygon.Vertices[0].Color^,
          Polygon.Vertices[1].Point.ScreenX, Polygon.Vertices[1].Point.ScreenY, Polygon.Vertices[1].Color^,
          Polygon.Vertices[2].Point.ScreenX, Polygon.Vertices[2].Point.ScreenY, Polygon.Vertices[2].Color^,
          @GameScreenRect);
      end;
    end;
  end;
end;
{ @end $4FC3B8 }

{ @routine $4FC4A4 ab_Polygon_Save }
procedure ab_Polygon_Save(Buffer: TBufEC);
var Polygon: PabPolygon; Index: Integer;
begin
  // This dormant editor serializer retains the old color-and-index format;
  // ab_Polygon_Load consumes the newer map-value-and-vertex-color format.
  Buffer.AddIntegerValue(ab_Polygon_Count);
  Polygon := FirstPolygon;
  while Polygon <> nil do begin
    Buffer.AddIntegerValue(Polygon.LegacyMapValue);
    Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackRed(Polygon.EditorColor)));
    Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackGreen(Polygon.EditorColor)));
    Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackBlue(Polygon.EditorColor)));
    Buffer.AddIntegerValue(Polygon.EditorColorKind);
    Buffer.AddIntegerValue(3);
    for Index := 0 to 2 do Buffer.AddIntegerValue(ab_StopPoint_IndexOf(Polygon.Vertices[Index].Point));
    Polygon := Polygon.Next;
  end;
end;
{ @end $4FC4A4 }

{ @routine $4FC54C ab_Polygon_Load }
procedure ab_Polygon_Load(Buffer: TBufEC);
var
  Index, Count, Vertex: Integer;
  Polygon: PabPolygon;
begin
  ab_Polygon_Clear;
  Count := Buffer.GetInt32;
  if Count < 1 then Exit;
  PolygonStorage := AllocClearEC(Count * SizeOf(TabPolygon));
  Polygon := PolygonStorage;
  for Index := 0 to Count - 1 do
  begin
    if LastPolygon <> nil then LastPolygon.Next := Polygon;
    Polygon.Prev := LastPolygon;
    Polygon.Next := nil;
    LastPolygon := Polygon;
    if FirstPolygon = nil then FirstPolygon := Polygon;
    Polygon.MapValue30 := Buffer.GetInt32;
    for Vertex := 0 to 2 do
    begin
      Polygon.Vertices[Vertex].Point := StopPointIndex[Buffer.GetInt32];
      Polygon.Vertices[Vertex].Color := Pointer(PAnsiChar(ArcadeMapColorBuffer.Data) + Buffer.GetInt32);
    end;
    Polygon := Pointer(PAnsiChar(Polygon) + SizeOf(TabPolygon));
  end;
end;
{ @end $4FC54C }

end.

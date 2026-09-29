unit fGalaxy2;
// Unit bracket (inferred): CODE 0x0055A2AC..0x0055E1EB; inclusive evidence, not full bounds.
// Galaxy navigation and star information.
interface
uses GI_PolyLine, Classes, EC_Struct, GI_GAI, GI_GraphBuf, GI_GraphButton, GI_Image, GI_Label, GI_MessageLoop, GI_Panel, Types, aGalaxy;
type
  TfGalaxy2 = class(TMessageLoopGI) // @size $F0
  public
    ParentLoop: TMessageLoopGI; // @offset $B0
    MapPanel: TPanelGI; // @offset $B4
    ViewMode: Byte; // @offset $B8
    HideBuffer: TGraphBufGI; // @offset $BC
    MapPixelBounds: TRect; // @offset $C0
    GalaxyOrigin: TPointF; // @offset $D0
    GalaxyExtent: TPointF; // @offset $D8
    SelectedJumpStar: TStar; // @offset $E0
    RouteStars: TList; // @offset $E4
    StarLinks: TPolyLineGI; // @offset $E8
    StarInfoHideTimer: TCallbackTimerIdGI; // @offset $EC
    destructor Destroy; override; // @addr $55A37C
    procedure OnOpen; override; // @addr $55A4C4
    procedure OnClose; override; // @addr $55B858
    procedure ProcessCallbackTimers; override; // @addr $55E0C0
    procedure SelectMusic; override; // @addr $55DF28
    procedure InitializeLayout; override; // @addr $55A3B8
    function GalaxyPointToMapPoint(Point: TPointF): TPoint; // @addr $55BAB8
    function GalaxyDistanceToMapDistance(Distance: Double): Integer; // @addr $55BB34
    procedure ConfigureReadOnlyMap; // @addr $55C440
    procedure ConfigureJumpSelection; // @addr $55C508
    procedure ShowStarInfo(Star: TStar); // @addr $55CCCC
    procedure HideStarInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $55CAE8
    procedure CloseClicked(Sender: TObjectGI); // @addr $55B8F0
    procedure JumpClicked(Sender: TObjectGI); // @addr $55CAF0
    procedure MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $55B90C
    procedure MainPanelMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55B9A8
    procedure MapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55C6F8
    procedure MapLeftButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55C720
    procedure MapRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55C93C
    procedure MapButtonUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55CA68
    procedure MapDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $55CAC0
    procedure RebuildJumpPath; // @addr $55BB64
    procedure ClearJumpPath; // @addr $55C3D0
    procedure ClearReadOnlyMapCallbacks; // @addr $55C4E4
    procedure ClearJumpSelectionCallbacks; // @addr $55C67C
    function MapPointToGalaxyPoint(Point: TPoint): TPointF; // @addr $55BA38
    constructor Create; // @addr $55A334
  end;
function RunGalaxyMap(ParentLoop: TMessageLoopGI): Boolean; // @addr $55E0F0
implementation

// @unit-initialization $55E1E4
// @unit-finalization $55E1B4

uses Globals, GlobalsV, GR_Main, GR_GraphBuf, GI_Main, Windows, SysUtils, Math, aPlayer, aItem, aMyFunction, aConst, EC_Str, GR_Music, aPlanet, fStarMap, GI_MessageBox, aShip, aVector, GI_Circle, GI_Window, GI_GI, SE_Star, SE_Planet, SE_Ruins, aRuins, EC_BlockPar;
{ @routine $55A334 TfGalaxy2_Create }
constructor TfGalaxy2.Create;
begin
  inherited Create;
  RouteStars := TList.Create;
end;
{ @end $55A334 }

{ @routine $55A37C TfGalaxy2_Destroy }
destructor TfGalaxy2.Destroy;
begin
  if RouteStars <> nil then
  begin
    RouteStars.Free;
    RouteStars := nil;
  end;
  inherited Destroy;
end;
{ @end $55A37C }

{ @routine $55A3B8 TfGalaxy2_InitializeLayout }
procedure TfGalaxy2.InitializeLayout;
begin
  inherited InitializeLayout;
  with GetByName('MainPanel') do
  begin
    KeyDownCallback := MainPanelKeyDown;
    LeftButtonUpCallback := MainPanelMouseUp;
  end;
  (GetByName('ButExit') as TGraphButtonGI).UpCallback := CloseClicked;
  MapPanel := GetByName('Map') as TPanelGI;
  HideBuffer := GetByName('HideBuf') as TGraphBufGI;
end;
{ @end $55A3B8 }

{ @routine $55A4C4 TfGalaxy2_OnOpen }
procedure TfGalaxy2.OnOpen;
var
  I, J, K: Integer;
  Polygon: TPolygon2D;
  Constellation: TConstellation;
  Segment: PMapLineSegment;
  Points: array of TPoint;
  Maximum: TPointF;
  Vertex: PPointF;
  First, Second: TPoint;
  StarImageCount: Integer;
  Block: TBlockParEC;
  Star: TStar;
  StarImage, BattleRing: TgaiGI;
  NameLabel: TLabelGI;
  Text, ColoredName: WideString;
  Planet: TPlanet;
  OwnerId: TOwnerId;
  HoleImage: TImageGI;
  BufferOffset: TPoint;
  SelectedHole: THole;
begin
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  RouteStars.Clear;
  Points := nil;
  HideBuffer.LoadBitmapPathAsRgba('Bm.FormGalaxy.' + GiResourceSuffix + 'img?RGBA');
  if GiResourceVariant = 2 then MapPixelBounds := Classes.Rect(50, 50, 974, 718)
  else MapPixelBounds := Classes.Rect(39, 39, 761, 561);
  MapPixelBounds.TopLeft := Classes.Point(0, 0);
  MapPixelBounds.BottomRight := MapPanel.ClientSize;
  BufferOffset := HalfPoint(SubtractPoints(Classes.Point(HideBuffer.GraphBuf.Width, HideBuffer.GraphBuf.Height), MapPanel.ClientSize));
  GalaxyOrigin := MakePointF(1.0e20, 1.0e20);
  Maximum := MakePointF(-1.0e20, -1.0e20);
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    for J := 0 to Constellation.OutlinePolygons.CountChain - 1 do
    begin
      Polygon := Constellation.OutlinePolygons.GetChainItem(J);
      for K := 0 to Polygon.Points.Count - 1 do
      begin
        Vertex := PPointF(Polygon.Points[K]);
        GalaxyOrigin.X := Min(GalaxyOrigin.X, Vertex.X);
        GalaxyOrigin.Y := Min(GalaxyOrigin.Y, Vertex.Y);
        Maximum.X := Max(Maximum.X, Vertex.X);
        Maximum.Y := Max(Maximum.Y, Vertex.Y);
      end;
    end;
  end;
  GalaxyExtent.X := Maximum.X - GalaxyOrigin.X;
  GalaxyExtent.Y := Maximum.Y - GalaxyOrigin.Y;
  StarLinks := TPolyLineGI.Create(MapPanel);
  StarLinks.SetDepth(10);
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if Constellation.Visible then
      for J := 0 to Constellation.OutlinePolygons.CountChain - 1 do
      begin
        Polygon := Constellation.OutlinePolygons.GetChainItem(J);
        SetLength(Points, Polygon.Points.Count);
        for K := 0 to Polygon.Points.Count - 1 do
        begin
          Vertex := PPointF(Polygon.Points[K]);
          Points[K] := AddPoints(GalaxyPointToMapPoint(Vertex^), BufferOffset);
        end;
        HideBuffer.GraphBuf.FillPolygon32(Points, 0);
      end;
    if not Constellation.Visible then
      for J := 0 to Constellation.OutlineSegments.Count - 1 do
      begin
        Segment := PMapLineSegment(Constellation.OutlineSegments[J]);
        First := AddPoints(GalaxyPointToMapPoint(Segment.StartPoint), BufferOffset);
        Second := AddPoints(GalaxyPointToMapPoint(Segment.EndPoint), BufferOffset);
        HideBuffer.GraphBuf.DrawLine32(First, Second, $FF008080);
      end;
    if Constellation.Visible then
      for J := 0 to Constellation.StarLinks.Count - 1 do
      begin
        Segment := PMapLineSegment(Constellation.StarLinks[J]);
        StarLinks.AddParentLine(GalaxyPointToMapPoint(Segment.StartPoint), GalaxyPointToMapPoint(Segment.EndPoint), CurrentPixelFormat.PackNormalizedRgb(0.3, 0.7, 1), Constellation.Id).Animated := True;
      end;
  end;
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    if Constellation.Visible then
      for J := 0 to Constellation.OutlineSegments.Count - 1 do
      begin
        Segment := PMapLineSegment(Constellation.OutlineSegments[J]);
        if Galaxy.CountVisibleConstellationsWithBoundaryPoints(Segment.StartPoint, Segment.EndPoint) <= 1 then
          HideBuffer.GraphBuf.DrawLine32(AddPoints(GalaxyPointToMapPoint(Segment.StartPoint), BufferOffset), AddPoints(GalaxyPointToMapPoint(Segment.EndPoint), BufferOffset), $FFFFFF00)
        else
          HideBuffer.GraphBuf.DrawLine32(AddPoints(GalaxyPointToMapPoint(Segment.StartPoint), BufferOffset), AddPoints(GalaxyPointToMapPoint(Segment.EndPoint), BufferOffset), $FF000090);
      end;
  end;
  for I := 0 to Galaxy.Constellations.Count - 1 do
  begin
    Constellation := TConstellation(Galaxy.Constellations[I]);
    begin
      if not Constellation.Visible then
      begin
        First := GalaxyPointToMapPoint(Constellation.CalculateLabelPosition);
        NameLabel := TLabelGI.Create(MapPanel);
        NameLabel.SetFontName(NormalFontName);
        NameLabel.SetDepth(100);
        NameLabel.SetTextAlignX(taxCenter);
        NameLabel.SetTextAlignY(tayCenter);
        NameLabel.SetPositionModeW(False);
        NameLabel.SetSize(Classes.Point(200, 40));
        NameLabel.SetPosition(Classes.Point(First.X - 100, First.Y - 20));
        NameLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes($DB, $DA, $9C));
        NameLabel.SetTextBorderWidth(1);
        NameLabel.SetTextBorderColor(CurrentPixelFormat.PackRgbBytes(0, 0, 0));
        if GiResourceVariant = 1 then NameLabel.SetShadowOffset(2)
        else NameLabel.SetShadowOffset(3);
        NameLabel.SetText(Constellation.GetName);
      end
      else
      begin
        First := GalaxyPointToMapPoint(Constellation.CalculateLabelPosition);
        NameLabel := TLabelGI.Create(MapPanel);
        NameLabel.SetFontName(NormalFontName);
        NameLabel.SetDepth(1000);
        NameLabel.SetTextAlignX(taxCenter);
        NameLabel.SetTextAlignY(tayCenter);
        NameLabel.SetPositionModeW(False);
        NameLabel.SetSize(Classes.Point(200, 40));
        NameLabel.SetPosition(Classes.Point(First.X - 100, First.Y - 20));
        NameLabel.SetTextColor(CurrentPixelFormat.PackRgbBytes($5C, $4D, $4D));
        NameLabel.SetText(Constellation.GetName);
      end;
    end;
  end;
  StarLinks.SetPositionModeW(False);
  StarLinks.SetActive(True);
  Block := GameDataConfig.GetBlock('GalaxyStar');
  StarImageCount := Block.GetParamCount;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if not (Star.IsConstellationVisible and Star.Constellation.Visible) then Continue;
    StarImage := TgaiGI.Create(MapPanel);
    StarImage.SetImagePath(Block.GetParamValue(Integer(Star.GenerationSeed) mod StarImageCount));
    StarImage.SetSize(StarImage.GetContentSize);
    StarImage.SetOrigin(HalfPoint(StarImage.ClientSize));
    StarImage.SetPosition(GalaxyPointToMapPoint(Star.Position));
    StarImage.SetDepth(5);
    StarImage.SetPositionModeW(True);
    StarImage.SequenceIndex := 0;
    StarImage.UpdateAutoGeometry;
    StarImage.SetSequenceFrame(RandomIntRange(0, StarImage.SequenceFrameCount - 1));
    StarImage.SetName('gs_' + IntToStr(Star.Id));
    StarImage.UserValue := 1;
    StarImage.RestartPlayback;
    NameLabel := TLabelGI.Create(MapPanel);
    NameLabel.SetFontName(HitPointFontName);
    NameLabel.SetDepth(6);
    NameLabel.SetSize(Classes.Point(200, 20));
    NameLabel.SetTextAlignX(taxCenter);
    NameLabel.SetTextAlignY(tayTop);
    NameLabel.SetPosition(Classes.Point(StarImage.LocalPosition.X - NameLabel.ClientSize.X div 2,
      StarImage.LocalPosition.Y + StarImage.ClientSize.Y div 2 - 5));
    NameLabel.SetPositionModeW(False);
    Planet := TPlanet(Star.Planets[0]);
    for J := 0 to Star.Planets.Count - 1 do
    begin
      Planet := TPlanet(Star.Planets[J]);
      if Planet.OwnerId <> oiNone then Break;
    end;
    Text := Star.Name;
    ColoredName := '';
    J := 1;
    K := Length(Star.Name) div Star.CountDistinctInhabitedPlanetOwners;
    ColoredName := ColoredName + WrapTextInColor(Copy(Text, 1, K), OwnerInfo[Planet.OwnerId].ColorTag);
    Delete(Text, 1, K);
    if Text <> '' then
      for OwnerId := oiMaloc to oiKling do
        if (Star.CountPlanetsByOwner(OwnerId) > 0) and (Planet.OwnerId <> OwnerId) then
        begin
          K := Length(Star.Name) div Star.CountDistinctInhabitedPlanetOwners;
          Inc(J);
          if J = Star.CountDistinctInhabitedPlanetOwners then K := Length(Text);
          ColoredName := ColoredName + WrapTextInColor(Copy(Text, 1, K), OwnerInfo[OwnerId].ColorTag);
          Delete(Text, 1, K);
        end;
    NameLabel.SetText(ColoredName);
    if Star.Battle then
    begin
      BattleRing := TgaiGI.Create(MapPanel);
      BattleRing.SetImagePath('Bm.FormGalaxy.War1');
      BattleRing.SetSize(BattleRing.GetContentSize);
      BattleRing.SetOrigin(Classes.Point(BattleRing.ClientSize.X div 2, BattleRing.ClientSize.Y div 2));
      BattleRing.SetPosition(AddPoints(GalaxyPointToMapPoint(Star.Position), Classes.Point(BattleRing.ClientSize.X div 2 + 3, -BattleRing.ClientSize.Y div 2 - 3)));
      BattleRing.SetDepth(3);
      BattleRing.SetPositionModeW(True);
      BattleRing.SequenceIndex := 0;
      BattleRing.UpdateAutoGeometry;
      BattleRing.RestartPlayback;
    end;
    SelectedHole := nil;
    for J := 0 to Galaxy.Holes.Count - 1 do
    begin
      SelectedHole := THole(Galaxy.Holes[J]);
      if SelectedHole.Star1 = Star then Break;
      SelectedHole := nil;
    end;
    if SelectedHole <> nil then
    begin
      HoleImage := TImageGI.Create(MapPanel);
      HoleImage.SetImagePath('GI,Bm.FormGalaxy.BlackHole');
      HoleImage.SetSize(HoleImage.GetContentSize);
      HoleImage.SetOrigin(Classes.Point(HoleImage.ClientSize.X div 2, HoleImage.ClientSize.Y div 2));
      HoleImage.SetPosition(AddPoints(GalaxyPointToMapPoint(Star.Position), Classes.Point(HoleImage.ClientSize.X div 2 + 3, HoleImage.ClientSize.Y div 2 + 3)));
      HoleImage.SetDepth(3);
      HoleImage.SetPositionModeW(True);
    end;
  end;
  with GetByName('PathCurPos') as TgaiGI do
  begin
    SetPosition(GalaxyPointToMapPoint(Player.CurrentStar.Position));
    SetOrigin(HalfPoint(ClientSize));
    SetActive(True);
    RestartPlayback;
  end;
  Points := nil;
  with GetByName('JampMaxShr') as TCircleGI do
  begin
    SetCenter(GalaxyPointToMapPoint(Player.CurrentStar.Position));
    if Player.FuelTanks = nil then SetRadius(1)
    else SetRadius(GalaxyDistanceToMapDistance(Player.JumpRange));
  end;
  with GetByName('JampMaxColor') as TCircleGI do
  begin
    SetCenter(ToAbsolutePoint(GalaxyPointToMapPoint(Player.CurrentStar.Position)));
    if Player.FuelTanks = nil then SetRadius(1)
    else SetRadius(GalaxyDistanceToMapDistance(Player.JumpRange));
  end;
  if ViewMode = 1 then ConfigureReadOnlyMap
  else if ViewMode = 2 then ConfigureJumpSelection;
  ShowStarInfo(nil);
end;
{ @end $55A4C4 }

{ @routine $55B858 TfGalaxy2_OnClose }
procedure TfGalaxy2.OnClose;
begin
  if StarInfoHideTimer <> 0 then
  begin
    CancelCallbackTimer(StarInfoHideTimer);
    StarInfoHideTimer := 0;
  end;
  ClearJumpPath;
  if ViewMode = 2 then ClearJumpSelectionCallbacks
  else if ViewMode = 1 then ClearReadOnlyMapCallbacks;
  GetByName('InfoStarPanel').FreeOwnedChildren;
  MapPanel.FreeOwnedChildren;
  HideBuffer.ClearOwnedBuffer;
  AuxRenderBuffer.Clear;
end;
{ @end $55B858 }

{ @routine $55B8F0 TfGalaxy2_CloseClicked }
procedure TfGalaxy2.CloseClicked(Sender: TObjectGI);
begin
  RequestedScreenId := GalaxyReturnScreenId;
  RequestClose(1);
end;
{ @end $55B8F0 }

{ @routine $55B90C TfGalaxy2_MainPanelKeyDown }
procedure TfGalaxy2.MainPanelKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or
    IsVirtualKeyDown(VK_MENU) then Exit;
  if Key = 77 then CloseClicked(nil)
  else if (Key = VK_RETURN) or (Key = 74) then
  begin
    if not (GetByName('ButJump') as TGraphButtonGI).Disabled then JumpClicked(nil);
  end
  else if Key = VK_ESCAPE then CloseClicked(nil);
end;
{ @end $55B90C }

{ @routine $55B9A8 TfGalaxy2_MainPanelMouseUp }
procedure TfGalaxy2.MainPanelMouseUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if not (GetByName('ImagePanel') as TImageGI).HitTestPixel(Point) and
    not GetByName('HideBuf').ContainsPoint(Point) then CloseClicked(nil);
end;
{ @end $55B9A8 }

{ @routine $55BA38 TfGalaxy2_MapPointToGalaxyPoint }
function TfGalaxy2.MapPointToGalaxyPoint(Point: TPoint): TPointF;
begin
  Result.X := (Point.X - MapPixelBounds.Left) / (MapPixelBounds.Right - MapPixelBounds.Left + 1) * GalaxyExtent.X + GalaxyOrigin.X;
  Result.Y := (Point.Y - MapPixelBounds.Top) / (MapPixelBounds.Bottom - MapPixelBounds.Top + 1) * GalaxyExtent.Y + GalaxyOrigin.Y;
end;
{ @end $55BA38 }

{ @routine $55BAB8 TfGalaxy2_GalaxyPointToMapPoint }
function TfGalaxy2.GalaxyPointToMapPoint(Point: TPointF): TPoint;
begin
  Result.X := Round((Point.X - GalaxyOrigin.X) / GalaxyExtent.X * (MapPixelBounds.Right - MapPixelBounds.Left + 1)) + MapPixelBounds.Left;
  Result.Y := Round((Point.Y - GalaxyOrigin.Y) / GalaxyExtent.Y * (MapPixelBounds.Bottom - MapPixelBounds.Top + 1)) + MapPixelBounds.Top;
end;
{ @end $55BAB8 }

{ @routine $55BB34 TfGalaxy2_GalaxyDistanceToMapDistance }
function TfGalaxy2.GalaxyDistanceToMapDistance(Distance: Double): Integer;
begin
  Result := Round(Distance / GalaxyExtent.X * (MapPixelBounds.Right - MapPixelBounds.Left + 1));
end;
{ @end $55BB34 }

{ @routine $55BB64 TfGalaxy2_RebuildJumpPath }
procedure TfGalaxy2.RebuildJumpPath;
var
  I, TotalDistance: Integer;
  ImageSize: TPoint;
  First, Second, DotPoint: TPointF;
  DotImage: TImageGI;
  Length, Distance, Slope, Step, Origin: Double;
  UseY: Boolean;
begin
  ClearJumpPath;
  with GetByName('PathCurPos') as TgaiGI do
  begin
    SetPosition(GalaxyPointToMapPoint(Player.CurrentStar.Position));
    SetOrigin(HalfPoint(ClientSize));
    SetActive(True);
    RestartPlayback;
  end;
  (GetByName('Distance') as TLabelGI).SetText('');
  if (Player.CurrentStar <> SelectedJumpStar) and (SelectedJumpStar <> nil) then
  begin
    with GetByName('PathDesPos') as TgaiGI do
    begin
      SetPosition(GalaxyPointToMapPoint(SelectedJumpStar.Position));
      SetOrigin(HalfPoint(ClientSize));
      SetActive(True);
      RestartPlayback;
    end;
    First := PointToPointF(GalaxyPointToMapPoint(SelectedJumpStar.Position));
    Second := PointToPointF(GalaxyPointToMapPoint(Player.CurrentStar.Position));
    if Abs(First.X - Second.X) < Abs(First.Y - Second.Y) then UseY := True else UseY := False;
    Length := Sqrt((First.X - Second.X) * (First.X - Second.X) + (First.Y - Second.Y) * (First.Y - Second.Y));
    if UseY then
    begin
      Slope := (Second.X - First.X) / (Second.Y - First.Y);
      Step := 1 / Sqrt(Slope * Slope + 1);
      if Second.Y - First.Y < 0 then Step := -Step;
      Origin := First.Y;
    end
    else
    begin
      Slope := (Second.Y - First.Y) / (Second.X - First.X);
      Step := 1 / Sqrt(Slope * Slope + 1);
      if Second.X - First.X < 0 then Step := -Step;
      Origin := First.X;
    end;
    Distance := 0;
    while Distance < Length do
    begin
      if UseY then
      begin
        DotPoint.Y := Distance * Step + Origin;
        DotPoint.X := (DotPoint.Y - First.Y) * Slope + First.X;
      end
      else
      begin
        DotPoint.X := Distance * Step + Origin;
        DotPoint.Y := (DotPoint.X - First.X) * Slope + First.Y;
      end;
      DotImage := TImageGI.Create(MapPanel);
      DotImage.SetDepth(1);
      DotImage.SetPosition(TruncatePointF(DotPoint));
      DotImage.SetPositionModeW(True);
      DotImage.SetImagePath('GI,Bm.PI.Path1');
      ImageSize := DotImage.GetContentSize;
      DotImage.SetOrigin(Classes.Point(ImageSize.X div 2, ImageSize.Y div 2));
      DotImage.SetSize(ImageSize);
      Distance := Distance + 10;
    end;

    First := PointToPointF(GalaxyPointToMapPoint(SelectedJumpStar.Position));
    for I := 0 to RouteStars.Count - 1 do
    begin
      Second := PointToPointF(GalaxyPointToMapPoint(TStar(RouteStars[I]).Position));
      if Abs(First.X - Second.X) < Abs(First.Y - Second.Y) then UseY := True else UseY := False;
      Length := Sqrt((First.X - Second.X) * (First.X - Second.X) + (First.Y - Second.Y) * (First.Y - Second.Y));
      if UseY then
      begin
        Slope := (Second.X - First.X) / (Second.Y - First.Y);
        Step := 1 / Sqrt(Slope * Slope + 1);
        if Second.Y - First.Y < 0 then Step := -Step;
        Origin := First.Y;
      end
      else
      begin
        Slope := (Second.Y - First.Y) / (Second.X - First.X);
        Step := 1 / Sqrt(Slope * Slope + 1);
        if Second.X - First.X < 0 then Step := -Step;
        Origin := First.X;
      end;
      Distance := 0;
      while Distance < Length do
      begin
        if UseY then
        begin
          DotPoint.Y := Distance * Step + Origin;
          DotPoint.X := (DotPoint.Y - First.Y) * Slope + First.X;
        end
        else
        begin
          DotPoint.X := Distance * Step + Origin;
          DotPoint.Y := (DotPoint.X - First.X) * Slope + First.Y;
        end;
        DotImage := TImageGI.Create(MapPanel);
        DotImage.SetDepth(1);
        DotImage.SetPosition(TruncatePointF(DotPoint));
        DotImage.SetPositionModeW(True);
        DotImage.SetImagePath('GI,Bm.PI.Path2');
        ImageSize := DotImage.GetContentSize;
        DotImage.SetOrigin(Classes.Point(ImageSize.X div 2, ImageSize.Y div 2));
        DotImage.SetSize(ImageSize);
        Distance := Distance + 10;
      end;
      First := Second;
    end;
    if RouteStars.Count <= 0 then
    begin
      First := SelectedJumpStar.Position;
      Second := Player.CurrentStar.Position;
      with GetByName('Distance') as TLabelGI do
      begin
        ImageSize := GalaxyPointToMapPoint(SelectedJumpStar.Position);
        SetPosition(Classes.Point(ImageSize.X + 15, ImageSize.Y - ClientSize.Y div 2));
        SetText(IntToStr(Round(Sqrt(Sqr(First.X - Second.X) + Sqr(First.Y - Second.Y)))));
      end;
    end
    else
    begin
      First := Player.CurrentStar.Position;
      Second := SelectedJumpStar.Position;
      TotalDistance := Round(Sqrt(Sqr(First.X - Second.X) + Sqr(First.Y - Second.Y)));
      First := Second;
      for I := 0 to RouteStars.Count - 1 do
      begin
        Second := TStar(RouteStars[I]).Position;
        TotalDistance := TotalDistance + Round(Sqrt(Sqr(First.X - Second.X) + Sqr(First.Y - Second.Y)));
        First := Second;
      end;
      with GetByName('Distance') as TLabelGI do
      begin
        ImageSize := GalaxyPointToMapPoint(First);
        SetPosition(Classes.Point(ImageSize.X + 15, ImageSize.Y - ClientSize.Y div 2));
        SetText(IntToStr(TotalDistance));
      end;
    end;
  end;
end;
{ @end $55BB64 }

{ @routine $55C3D0 TfGalaxy2_ClearJumpPath }
procedure TfGalaxy2.ClearJumpPath;
var Control, Current: TObjectGI;
begin
  Control := MapPanel.FirstChild;
  while Control <> nil do
  begin
    Current := Control;
    Control := Control.NextSibling;
    if Current.Depth = 1.0 then
    begin
      Current.SetActive(False);
      Current.Free;
    end;
  end;
  GetByName('PathDesPos').SetActive(False);
end;
{ @end $55C3D0 }

{ @routine $55C440 TfGalaxy2_ConfigureReadOnlyMap }
procedure TfGalaxy2.ConfigureReadOnlyMap;
begin
  (GetByName('ButJump') as TGraphButtonGI).SetDisabled(True);
  MapPanel.LeftButtonDownCallback := MapLeftButtonDown;
  MapPanel.LeftButtonUpCallback := MapButtonUp;
  MapPanel.MouseMoveCallback := MapMouseMove;
  MapPanel.RightButtonDownCallback := MapRightButtonDown;
  MapPanel.RightButtonUpCallback := MapButtonUp;
  SelectedJumpStar := Player.CurrentStar;
  RebuildJumpPath;
end;
{ @end $55C440 }

{ @routine $55C4E4 TfGalaxy2_ClearReadOnlyMapCallbacks }
procedure TfGalaxy2.ClearReadOnlyMapCallbacks;
begin
  MapPanel.LeftButtonDownCallback := nil;
  MapPanel.MouseMoveCallback := nil;
end;
{ @end $55C4E4 }

{ @routine $55C508 TfGalaxy2_ConfigureJumpSelection }
procedure TfGalaxy2.ConfigureJumpSelection;
begin
  MapPanel.LeftButtonDownCallback := MapLeftButtonDown;
  MapPanel.LeftButtonUpCallback := MapButtonUp;
  MapPanel.MouseMoveCallback := MapMouseMove;
  MapPanel.RightButtonDownCallback := MapRightButtonDown;
  MapPanel.RightButtonUpCallback := MapButtonUp;
  (GetByName('ButJump') as TGraphButtonGI).SetDisabled(False);
  (GetByName('ButJump') as TGraphButtonGI).UpCallback := JumpClicked;
  MapPanel.LeftButtonDoubleClickCallback := MapDoubleClick;
  if (Player.Order = soJump) and (Player.OrderTarget is TStar) then SelectedJumpStar := Player.OrderTarget as TStar
  else SelectedJumpStar := Player.CurrentStar;
  RebuildJumpPath;
  (GetByName('ButJump') as TGraphButtonGI).SetDisabled((SelectedJumpStar = nil) or (Player.CurrentStar = SelectedJumpStar) or (ViewMode = 1));
end;
{ @end $55C508 }

{ @routine $55C67C TfGalaxy2_ClearJumpSelectionCallbacks }
procedure TfGalaxy2.ClearJumpSelectionCallbacks;
begin
  ClearJumpPath;
  MapPanel.LeftButtonDownCallback := nil;
  (GetByName('ButJump') as TGraphButtonGI).DownCallback := nil;
  MapPanel.MouseMoveCallback := nil;
  MapPanel.LeftButtonDoubleClickCallback := nil;
end;
{ @end $55C67C }

{ @routine $55C6F8 TfGalaxy2_MapMouseMove }
procedure TfGalaxy2.MapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if Sender.IsOccludedAtPoint(Point) then Exit;
end;
{ @end $55C6F8 }

{ @routine $55C720 TfGalaxy2_MapLeftButtonDown }
procedure TfGalaxy2.MapLeftButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Selected, Star: TStar;
  GalaxyPoint: TPointF;
  BestDistance, Distance: Double;
  I: Integer;
begin
  MapRightButtonDown(Sender, KeyState, Point);
  if Sender.IsOccludedAtPoint(Point) then Exit;
  Point := MapPanel.ToLocalPoint(Point);
  GalaxyPoint := MapPointToGalaxyPoint(Point);
  Selected := nil;
  BestDistance := 1.0e20;
  for I := 0 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if not Star.Constellation.Visible then Continue;
    Distance := (Star.Position.X - GalaxyPoint.X) * (Star.Position.X - GalaxyPoint.X) + (Star.Position.Y - GalaxyPoint.Y) * (Star.Position.Y - GalaxyPoint.Y);
    if Distance < BestDistance then
    begin
      Selected := Star;
      BestDistance := Distance;
    end;
  end;
  if (SelectedJumpStar <> nil) and (Player.CurrentStar <> SelectedJumpStar) and
    (IsVirtualKeyDown(VK_CONTROL) or IsVirtualKeyDown(VK_SHIFT) or IsVirtualKeyDown(VK_MENU)) then
  begin
    if BestDistance < 100 then
    begin
      if (RouteStars.Count < 1) or (RouteStars[RouteStars.Count - 1] <> Selected) then
      begin
        RouteStars.Add(Selected);
        RebuildJumpPath;
      end;
    end;
  end
  else
  begin
    RouteStars.Clear;
    if BestDistance < 100 then SelectedJumpStar := Selected
    else SelectedJumpStar := Player.CurrentStar;
    RebuildJumpPath;
    (GetByName('ButJump') as TGraphButtonGI).SetDisabled((SelectedJumpStar = nil) or (Player.CurrentStar = SelectedJumpStar) or (ViewMode = 1));
  end;
end;
{ @end $55C720 }

{ @routine $55C93C TfGalaxy2_MapRightButtonDown }
procedure TfGalaxy2.MapRightButtonDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Selected, Star: TStar;
  GalaxyPoint: TPointF;
  BestDistance, Distance: Double;
  I: Integer;
begin
  if Sender.IsOccludedAtPoint(Point) then Exit;
  Point := MapPanel.ToLocalPoint(Point);
  GalaxyPoint := MapPointToGalaxyPoint(Point);
  Selected := TStar(Galaxy.Stars[0]);
  BestDistance := (Selected.Position.X - GalaxyPoint.X) * (Selected.Position.X - GalaxyPoint.X) + (Selected.Position.Y - GalaxyPoint.Y) * (Selected.Position.Y - GalaxyPoint.Y);
  for I := 1 to Galaxy.Stars.Count - 1 do
  begin
    Star := TStar(Galaxy.Stars[I]);
    if not Star.Constellation.Visible then Continue;
    Distance := (Star.Position.X - GalaxyPoint.X) * (Star.Position.X - GalaxyPoint.X) + (Star.Position.Y - GalaxyPoint.Y) * (Star.Position.Y - GalaxyPoint.Y);
    if Distance < BestDistance then
    begin
      Selected := Star;
      BestDistance := Distance;
    end;
  end;
  if BestDistance >= 100 then Selected := nil;
  ShowStarInfo(Selected);
end;
{ @end $55C93C }

{ @routine $55CA68 TfGalaxy2_MapButtonUp }
procedure TfGalaxy2.MapButtonUp(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if StarInfoHideTimer <> 0 then
  begin
    CancelCallbackTimer(StarInfoHideTimer);
    StarInfoHideTimer := 0;
  end;
  StarInfoHideTimer := ScheduleCallbackTimer(50, 50, HideStarInfo, 0);
end;
{ @end $55CA68 }
{ @routine $55CAC0 TfGalaxy2_MapDoubleClick }
procedure TfGalaxy2.MapDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if ViewMode = 2 then
    JumpClicked(nil);
end;
{ @end $55CAC0 }

{ @routine $55CAE8 TfGalaxy2_HideStarInfo }
procedure TfGalaxy2.HideStarInfo(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  ShowStarInfo(nil);
end;
{ @end $55CAE8 }

{ @routine $55CAF0 TfGalaxy2_JumpClicked }
procedure TfGalaxy2.JumpClicked(Sender: TObjectGI);
var First, Second: TPointF;
begin
  if (Player.CurrentStar = SelectedJumpStar) or (SelectedJumpStar = nil) then Exit;
  if not Player.HasPositiveSpeed then Exit;
  First := SelectedJumpStar.Position;
  Second := Player.CurrentStar.Position;
  if Player.JumpRange < Round(Sqrt(Sqr(First.X - Second.X) + Sqr(First.Y - Second.Y))) then
  begin
    Player.OrderNone;
    ShowMessageBoxGI(Self, FormatText1(LocalizedText('FormGalaxy.NeedFuelOrEngine'), HighlightColorTag, '<Star>', SelectedJumpStar.Name), mbgCancel);
    Exit;
  end;
  PendingPlayerFollowTarget := nil;
  Player.OrderJump(SelectedJumpStar, False);
  SpaceViewPosition := Player.Position;
  RequestedScreenId := screenStarMap;
  RequestClose(1);
end;
{ @end $55CAF0 }

{ @routine $55CCCC TfGalaxy2_ShowStarInfo }
procedure TfGalaxy2.ShowStarInfo(Star: TStar);
var
  InfoPanel: TWindowGI;
  Panel: TPanelGI;
  Objects: TList;
  I, J, RowHeight, RowX, WindowX: Integer;
  IconInset: Cardinal;
  Distance: Single;
  OwnerId: TOwnerId;
begin
  if StarInfoHideTimer <> 0 then
  begin
    CancelCallbackTimer(StarInfoHideTimer);
    StarInfoHideTimer := 0;
  end;
  if RawObjectInfo then
  begin
    InfoPanel := TWindowGI(GetByName('Info'));
    with TLabelGI(GetByName('InfoText')) do
    begin
      if Star = nil then begin InfoPanel.SetActive(False); Exit; end;
      InfoPanel.SetActive(True);
      SetText(Star.GetRawInfoText);
      InfoPanel.SetSize(Classes.Point(ClientSize.X + InfoPanel.WorkSubRect.Left + InfoPanel.WorkSubRect.Right,
        ClientSize.Y + InfoPanel.WorkSubRect.Top + InfoPanel.WorkSubRect.Bottom));
      InfoPanel.UpdateAutoGeometry;
      SetPosition(Classes.Point(InfoPanel.WorkSubRect.Left, InfoPanel.WorkSubRect.Top));
    end;
  end
  else
  begin
    InfoPanel := TWindowGI(GetByName('InfoStar'));
    if Star = nil then begin InfoPanel.SetActive(False); Exit; end;
    InfoPanel.SetActive(True);
      (GetByName('InfoStarName') as TLabelGI).SetText(WrapTextInColor(Star.Name, GreenColorTag));
      with GetByName('InfoStarImage') as TGraphBufGI do
      begin
        SourceHasPerPixelAlpha := True;
        LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW(TStarSE(Star.Graphic).StaticImagePath, 1, ','), GraphBuf);
        if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
          GraphBuf.RescaleBilinearRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)))
        else GraphBuf.RescaleBilinearRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y);
        SetImageKindX(ikxCenter);
        SetImageKindY(ikyCenter);
      end;
      Panel := GetByName('InfoStarPanel') as TPanelGI;
      Panel.FreeOwnedChildren;
      Objects := TList.Create;
      for I := 0 to Star.Planets.Count - 1 do Objects.Add(Star.Planets[I]);
      for I := 0 to Star.Ships.Count - 1 do
        if TObject(Star.Ships[I]) is TRuins then
        begin
          Distance := PointDistanceSquared(TShip(Star.Ships[I]).Position, MakePointF(0, 0));
          J := 0;
          while J < Objects.Count do
          begin
            if TObject(Objects[J]) is TPlanet then
            begin
              if PointDistanceSquared(TPlanet(Objects[J]).GetPosition, MakePointF(0, 0)) > Distance then Break;
            end
            else if PointDistanceSquared(TShip(Objects[J]).Position, MakePointF(0, 0)) > Distance then Break;
            Inc(J);
          end;
          Objects.Insert(J, Star.Ships[I]);
        end;
      RowHeight := GiScalePixels(20);
      for I := 0 to Objects.Count - 1 do
      begin
        with TLabelGI.Create(Panel) do
        begin
          SetFontName(HitPointFontName);
          SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
          SetSize(Classes.Point(Panel.ClientSize.X div 2 + 15, RowHeight));
          SetPosition(Classes.Point(0, RowHeight * I));
          SetWordWrapEnabled(False);
          SetTextAlignX(taxRight);
          SetTextAlignY(tayCenterEx);
          if TObject(Objects[I]) is TPlanet then
          begin
            SetText(TPlanet(Objects[I]).Name);
            if (TObject(Objects[I]) as TPlanet).OwnerId in CoalitionOwners then
              case (TObject(Objects[I]) as TPlanet).GetRelationLevelToShip(Player) of
                rlHostile: SetText(GetText);
                rlBad: SetText(GetText);
                rlNormal: SetText(GetText);
                rlGood: SetText(GetText);
                rlExcellent: SetText(GetText);
              else SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 230));
              end
            else if (TObject(Objects[I]) as TPlanet).OwnerId = oiKling then SetText(GetText)
            else SetText(GetText);
          end
          else SetText(TShip(Objects[I]).Name);
        end;
        with TGraphBufGI.Create(Panel) do
        begin
          IconInset := 0;
          if TObject(Objects[I]) is TPlanet then
          begin
            if (TObject(Objects[I]) as TPlanet).Radius < 70 then IconInset := 4
            else if (TObject(Objects[I]) as TPlanet).Radius < 80 then IconInset := 3
            else if (TObject(Objects[I]) as TPlanet).Radius < 90 then IconInset := 2
            else if (TObject(Objects[I]) as TPlanet).Radius < 100 then IconInset := 1
            else IconInset := 0;
          end;
          SourceHasPerPixelAlpha := True;
          SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + 1 + (IconInset shr 1), RowHeight * I + 1 + (IconInset shr 1)));
          SetSize(Classes.Point(RowHeight - 2 - IconInset, RowHeight - 2 - IconInset));
          if TObject(Objects[I]) is TPlanet then
          begin
            TPlanetSE(TPlanet(Objects[I]).Graphic).RenderToBuffer(Self, GraphBuf, True);
            GraphBuf.RescaleRgba(ClientSize.X, ClientSize.Y, 5);
          end
          else
          begin
            LoadGiByPathIntoGraphBuf(ExtractDelimitedPartW((TShip(Objects[I]).Graphic as TRuinsSE).StaticImagePath, 1, ','), GraphBuf);
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
          end;
          SetImageKindX(ikxCenter);
          SetImageKindY(ikyCenter);
        end;
        if TObject(Objects[I]) is TPlanet then OwnerId := TPlanet(Objects[I]).OwnerId
        else OwnerId := TShip(Objects[I]).OwnerId;
        if OwnerId in [oiMaloc..oiKling] then
          with TGraphBufGI.Create(Panel) do
          begin
            SourceHasPerPixelAlpha := True;
            LoadBitmapPathAsRgba(ExtractDelimitedPartW(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[OwnerId].InternalName), 1, ',') + '?RGBA');
            SetPosition(Classes.Point(Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1, RowHeight * I + 1));
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            if Cardinal(GraphBuf.Width) >= Cardinal(GraphBuf.Height) then
              GraphBuf.RescaleRgba(ClientSize.X, Round(ClientSize.X / Cardinal(GraphBuf.Width) * Cardinal(GraphBuf.Height)), 5)
            else GraphBuf.RescaleRgba(Round(ClientSize.Y / Cardinal(GraphBuf.Height) * Cardinal(GraphBuf.Width)), ClientSize.Y, 5);
            SetImageKindX(ikxCenter);
            SetImageKindY(ikyCenter);
          end;
        if (TObject(Objects[I]) is TPlanet) and ((TObject(Objects[I]) as TPlanet).OwnerId in CoalitionOwners) then
        begin
          RowX := Panel.ClientSize.X div 2 + 15 + 5 + RowHeight + 5 + 1;
          with TImageGI.Create(Panel) do
          begin
            case (TObject(Objects[I]) as TPlanet).GetRelationLevelToShip(Player) of
              rlHostile: SetImagePath('GI,Bm.FormGalaxy.Face4');
              rlBad: SetImagePath('GI,Bm.FormGalaxy.Face3');
              rlNormal: SetImagePath('GI,Bm.FormGalaxy.Face2');
              rlGood: SetImagePath('GI,Bm.FormGalaxy.Face1');
              rlExcellent: SetImagePath('GI,Bm.FormGalaxy.Face0');
            else SetImagePath('GI,Bm.FormGalaxy.Face2');
            end;
            SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
            SetPosition(Classes.Point(RowX + RowHeight + 2, RowHeight * I + 1));
          end;
          RowX := RowX + RowHeight + 2;
          if (TObject(Objects[I]) as TPlanet).Economy in [peAgriculture, peIndustrial] then
            with TImageGI.Create(Panel) do
            begin
              case (TObject(Objects[I]) as TPlanet).Economy of
                peAgriculture: SetImagePath('GI,Bm.FormGalaxy.EconAgrar');
                peIndustrial: SetImagePath('GI,Bm.FormGalaxy.EconIndustr');
              end;
              SetSize(Classes.Point(RowHeight - 2, RowHeight - 2));
              SetPosition(Classes.Point(RowX + RowHeight, RowHeight * I + 1));
            end;
        end;
      end;
      Panel.SetSize(Classes.Point(Panel.ClientSize.X, Objects.Count * RowHeight));
      InfoPanel.SetSize(Classes.Point(InfoPanel.ClientSize.X, Panel.LocalPosition.Y + Objects.Count * RowHeight + GiScalePixels(30)));
      InfoPanel.UpdateAutoGeometry;
      Objects.Free;
  end;
  for I := 0 to 3 do
  begin
    if I = 0 then
      InfoPanel.SetPosition(AddPoints(MapPanel.ToAbsolutePoint(GalaxyPointToMapPoint(Star.Position)), Classes.Point(-InfoPanel.ClientSize.X - GiScalePixels(50), -InfoPanel.ClientSize.Y - GiScalePixels(50))))
    else if I = 1 then
      InfoPanel.SetPosition(AddPoints(MapPanel.ToAbsolutePoint(GalaxyPointToMapPoint(Star.Position)), Classes.Point(GiScalePixels(50), -InfoPanel.ClientSize.Y - GiScalePixels(50))))
    else if I = 2 then
      InfoPanel.SetPosition(AddPoints(MapPanel.ToAbsolutePoint(GalaxyPointToMapPoint(Star.Position)), Classes.Point(GiScalePixels(50), GiScalePixels(50))))
    else
      InfoPanel.SetPosition(AddPoints(MapPanel.ToAbsolutePoint(GalaxyPointToMapPoint(Star.Position)), Classes.Point(-InfoPanel.ClientSize.X - GiScalePixels(50), GiScalePixels(50))));
    WindowX := InfoPanel.LocalPosition.X;
    if (WindowX >= 0) and (InfoPanel.LocalPosition.Y >= 0) and
      (GameScreenWidth - GiScalePixels(100) >= WindowX + InfoPanel.ClientSize.X) and
      (GameScreenHeight - GiScalePixels(100) >= InfoPanel.LocalPosition.Y + InfoPanel.ClientSize.Y) then Break;
  end;
end;
{ @end $55CCCC }

{ @routine $55DF28 TfGalaxy2_SelectMusic }
procedure TfGalaxy2.SelectMusic;
begin
  if Player = nil then MusicManager.PlayCategory('Base')
  else if Player.IsOnPlanet then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.CurrentPlanet.OwnerId].InternalName);
  end
  else if Player.IsDockedToShip then
  begin
    if not MusicInPlanet then MusicManager.RequestFadeOut
    else MusicManager.PlayCategory('Nation.' + OwnerInfo[Player.DockedTo.OwnerId].InternalName);
  end
  else if Player.InNormalSpace then
  begin
    if MusicInSpace then MusicManager.PlayCategory('StarMap') else MusicManager.RequestFadeOut;
  end;
end;
{ @end $55DF28 }
{ @routine $55E0C0 TfGalaxy2_ProcessCallbackTimers }
procedure TfGalaxy2.ProcessCallbackTimers;
begin
  inherited ProcessCallbackTimers;
  if (ParentLoop <> nil) and (ParentLoop.ExitCode <> 0) and (ExitCode = 0) then RequestClose(2);
end;
{ @end $55E0C0 }

{ @routine $55E0F0 RunGalaxyMap }
function RunGalaxyMap(ParentLoop: TMessageLoopGI): Boolean;
var State: TCursorStateGI;
begin
  ParentLoop.RootUiObject.NativeHook50;
  ParentLoop.CaptureCursorState(@State);
  ParentLoop.SetCursorActive(False);
  ParentLoop.DrawQueuedUpdateRects;
  GalaxyMapScreen.ParentLoop := ParentLoop;
  if GalaxyMapScreen.Run = 1 then Result := True else Result := False;
  GalaxyMapScreen.ParentLoop := nil;
  ParentLoop.InvalidateViewport;
  ParentLoop.RestoreCursorState(@State);
  ParentLoop.UpdateCursorPosition;
  ParentLoop.RootUiObject.NativeHook48;
end;
{ @end $55E0F0 }

end.

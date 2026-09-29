unit SE_Planet;
// Unit bracket (inferred): CODE 0x00606DA0..0x00608DBB; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_AlphaImage, GI_GAI, GI_Image, GI_MessageLoop, GI_Planet, GR_GraphBuf, SE_Space, Types;

type
  PPlanetMapOrbitPoint = ^TPlanetMapOrbitPoint;
  TPlanetMapOrbitPoint = packed record // @size $0C
    Position: TPoint; // @offset $00
    PixelOffset: Integer; // @offset $08  Byte offset in the minimap's 16-bit pixel buffer.
  end;

  PPlanetCollisionCircle = ^TPlanetCollisionCircle;
  TPlanetCollisionCircle = packed record // @size $18
    Next: PPlanetCollisionCircle; // @offset $00
    Prev: PPlanetCollisionCircle; // @offset $04
    Position: TPointF; // @offset $08
    Radius: Single; // @offset $10
    RadiusSquared: Single; // @offset $14
  end;

  TPlanetSE = class(TObjectSE) // @size $A4
  public
    ImagePath: WideString; // @offset $48
    ImageOrigin: TPoint; // @offset $4C
    SurfaceMapOffset: Integer; // @offset $54
    LightAngle: Byte; // @offset $58  A full turn has 256 steps.
    RotationTimerInterval: Cardinal; // @offset $5C  Milliseconds before conversion to space ticks; saved as a Word by TPlanet.
    SurfaceMapStep: Integer; // @offset $60
    MinimapImagePath: WideString; // @offset $64
    MinimapImageOrigin: TPoint; // @offset $68
    OrbitalVelocity: Double; // @offset $70
    Radius: Integer; // @offset $78
    RingKind: Byte; // @offset $7C  PlanetRing resource selector; 0 disables rings. Kinds 1/4/5 also select animation families.
    Civilized: Boolean; // @offset $7D Film playback sets this from MinimapOwner <> oiNone.
    PlanetControl: TPlanetGI; // @offset $80
    RingControl1: TImageGI; // @offset $84
    RingControl2: TImageGI; // @offset $88
    MinimapControl: TAlphaImageGI; // @offset $8C
    RotationTimer: PSpaceTimerSE; // @offset $90
    MapOrbitPointCount: Integer; // @offset $94
    MapOrbitPoints: PPlanetMapOrbitPoint; // @offset $98  Owned raw allocation.
    CollisionCircle: PPlanetCollisionCircle; // @offset $9C
    MinimapOwner: TOwnerId; // @offset $A0 Selects the Bm.Planet.M.<owner> minimap icon.

    procedure CopyTo(Destination: TObjectSE); override; // @addr $606E6C @slot $00 @note "Destination must be a TPlanetSE. Copies configuration, not attached controls/timers."
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $606EF8
    procedure DetachFromSpace; override; // @addr $607238
    procedure RebuildRings; // @addr $6072F8
    procedure SetMinimapOwner(Owner: TOwnerId); // @addr $6077A8
    procedure SetPosition(APosition: TPointF); override; // @addr $607868
    procedure SetSurfaceMapOffset(Value: Integer); // @addr $607970
    procedure SetLightAngle(Value: Byte); // @addr $607994
    procedure SetRotationTimerInterval(Value: Cardinal); // @addr $6079B8
    procedure SetSurfaceMapStep(Value: Integer); // @addr $607A04
    procedure SetRingKind(Kind: Byte); // @addr $607A08 @note "Does nothing for ruins; rebuilds rings when attached to space."
    procedure UpdateLightAngleFromStar; // @addr $607A24
    procedure AdvanceRotationTimer(Timer: PSpaceTimerSE; UserData: Integer); // @addr $607ABC
    function HitTestCursor: Boolean; override; // @addr $607AC8
    procedure DrawMap; override; // @addr $607AE8
    procedure RenderToBuffer(Screen: TMessageLoopGI; Buffer: TGraphBufGR; SmallPreview: Boolean); // @addr $6084E4 @note "Always creates a temporary planet renderer; SmallPreview uses the satellite mask at radius 25."
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $6088E0
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $608A74
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $608C50
  end;

function AllocatePlanetCollisionCircle: PPlanetCollisionCircle; // @addr $608D28 @note "Links a new entry at the head; only links are initialized."
procedure FreePlanetCollisionCircle(Entry: PPlanetCollisionCircle); // @addr $608D50

var
  FirstPlanetCollisionCircle: PPlanetCollisionCircle = nil; // @addr $618998

implementation

// @unit-initialization $608DB4
// @unit-finalization $608D84

uses SysUtils, Math, EC_Str, SE_Star, GlobalsV, Globals, GR_Main, GI_Main, aConst, aMyFunction, EC_Mem, EC_Cache, EC_CacheBitmap, Windows, SE_Process;

{ @routine $606E6C TPlanetSE_CopyTo }
procedure TPlanetSE.CopyTo(Destination: TObjectSE);
begin
  inherited CopyTo(Destination);
  with Destination as TPlanetSE do
  begin
    ImagePath := Self.ImagePath;
    ImageOrigin := Self.ImageOrigin;
    SurfaceMapOffset := Self.SurfaceMapOffset;
    LightAngle := Self.LightAngle;
    RotationTimerInterval := Self.RotationTimerInterval;
    SurfaceMapStep := Self.SurfaceMapStep;
    MinimapImagePath := Self.MinimapImagePath;
    MinimapImageOrigin := Self.MinimapImageOrigin;
    OrbitalVelocity := Self.OrbitalVelocity;
    Radius := Self.Radius;
    RingKind := Self.RingKind;
    MinimapOwner := Self.MinimapOwner;
  end;
end;
{ @end $606E6C }

{ @routine $606EF8 TPlanetSE_AttachToSpace }
procedure TPlanetSE.AttachToSpace(ASpace: TSpaceSE);
var
  Template: TPlanetTempl;
  Index, Count: Integer;
begin
  if not IsAttachedToSpace then
  begin
  if Civilized then ConfigureLoopSound('Planet.Civil') else ConfigureLoopSound('Planet.NotCivil');
  if Civilized then ConfigureRandomSound('Planet.Civil') else ConfigureRandomSound('Planet.NotCivil');
  inherited AttachToSpace(ASpace);
    Template := nil;
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      Template := PlanetRenderTemplates[Index];
      if Template.Radius = Radius then Break;
    end;
    if Template = nil then raise Exception.Create('Error');
    PlanetControl := TPlanetGI.Create(Space.MapPanel);
    PlanetControl.SetPositionModeW(True);
    PlanetControl.SetDepthByName(DepthExpression);
    PlanetControl.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
    PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
    PlanetControl.SetOrigin(ImageOrigin);
    if GameScreenWidth = 1024 then
      PlanetControl.SetImageWithRadius(Template.MaskName, ImagePath, Template.LightName, Radius)
    else PlanetControl.SetImageWithRadius(Template.SmallMaskName, ImagePath, Template.SmallLightName, Radius);
    PlanetControl.SetLightAngle(LightAngle);
    MinimapControl := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapControl.SetPositionModeW(True);
    MinimapControl.SetDepthByName(DepthExpression);
    MinimapControl.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
    MinimapControl.SetOrigin(MinimapImageOrigin);
    MinimapControl.SetImagePath('Bm.Planet.M.' + OwnerInfo[MinimapOwner].InternalName);
    MinimapControl.SetSize(MinimapControl.GetContentSize);
    UpdateLightAngleFromStar;
    CollisionCircle := AllocatePlanetCollisionCircle;
    CollisionCircle.Position.X := Position.X;
    CollisionCircle.Position.Y := Position.Y;
    CollisionCircle.Radius := Radius;
    RebuildRings;
    RotationTimer := Space.CreateTimer(0, RotationTimerInterval, AdvanceRotationTimer, 0);
  end;
end;
{ @end $606EF8 }

{ @routine $607238 TPlanetSE_DetachFromSpace }
procedure TPlanetSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
    FreePlanetCollisionCircle(CollisionCircle);
    CollisionCircle := nil;
    if MapOrbitPoints <> nil then
    begin
      FreeEC(MapOrbitPoints);
      MapOrbitPoints := nil;
    end;
    if RotationTimer <> nil then
    begin
      Space.DeleteTimer(RotationTimer);
      RotationTimer := nil;
    end;
    Space.MapPanel.FreeOwnedChild(PlanetControl);
    PlanetControl := nil;
    if RingControl1 <> nil then
    begin
      RingControl1.Free;
      RingControl1 := nil;
    end;
    if RingControl2 <> nil then
    begin
      RingControl2.Free;
      RingControl2 := nil;
    end;
    if MinimapControl <> nil then
    begin
      MinimapControl.Free;
      MinimapControl := nil;
    end;
  inherited DetachFromSpace;
end;
{ @end $607238 }

{ @routine $6072F8 TPlanetSE_RebuildRings }
procedure TPlanetSE.RebuildRings;
var
  Path: WideString;
  Center, Offset: TPoint;
  Bounds, FirstBounds, SecondBounds: TRect;
begin
  if RingControl1 <> nil then
  begin
    RingControl1.Free;
    RingControl1 := nil;
  end;
  if RingControl2 <> nil then
  begin
    RingControl2.Free;
    RingControl2 := nil;
  end;
  if RingKind <> 0 then
  begin
    Path := 'GI,Bm.PlanetRing.' + GiResourceSuffix + 'r';
    if RingKind - 1 < 10 then Path := Path + '0';
    Path := Path + IntToStr(RingKind - 1) + '_';
    if RingKind >= 20 then Path := Path + '0'
    else if Radius = 100 then Path := Path + '0'
    else if Radius = 90 then Path := Path + '1'
    else if Radius = 80 then Path := Path + '2'
    else if Radius = 70 then Path := Path + '3'
    else if Radius = 60 then Path := Path + '4'
    else RaiseWideMessage('TPlanetSE.CreateRing');
    RingControl1 := TImageGI.Create(Space.MapPanel);
    RingControl1.SetPositionModeW(True);
    RingControl1.SetDepth(PlanetControl.Depth - 0.01);
    RingControl1.SetImagePath(Path + '_1');
    RingControl1.SetSize(RingControl1.GetContentSize);
    RingControl1.SetPosition(PlanetControl.LocalPosition);
    RingControl2 := TImageGI.Create(Space.MapPanel);
    RingControl2.SetPositionModeW(True);
    RingControl2.SetDepth(PlanetControl.Depth + 0.01);
    RingControl2.SetImagePath(Path + '_2');
    RingControl2.SetSize(RingControl2.GetContentSize);
    RingControl2.SetPosition(PlanetControl.LocalPosition);
    FirstBounds.TopLeft := RingControl1.GetContentOrigin;
    FirstBounds.BottomRight := AddPoints(FirstBounds.TopLeft, RingControl1.ClientSize);
    SecondBounds.TopLeft := RingControl2.GetContentOrigin;
    SecondBounds.BottomRight := AddPoints(SecondBounds.TopLeft, RingControl2.ClientSize);
    Windows.UnionRect(Bounds, FirstBounds, SecondBounds);
    Center := Classes.Point((Bounds.Right + Bounds.Left) div 2, (Bounds.Bottom + Bounds.Top) div 2);
    Offset := Classes.Point(0, Bounds.Right div 2 - Bounds.Bottom div 2);
    if RingKind = 21 then Inc(Offset.Y, GiScalePixels(30))
    else if RingKind = 22 then Inc(Offset.Y, GiScalePixels(20));
    RingControl1.SetOrigin(SubtractPoints(SubtractPoints(Center, FirstBounds.TopLeft), Offset));
    RingControl2.SetOrigin(SubtractPoints(SubtractPoints(Center, SecondBounds.TopLeft), Offset));
  end;
end;
{ @end $6072F8 }

{ @routine $6077A8 TPlanetSE_SetMinimapOwner }
procedure TPlanetSE.SetMinimapOwner(Owner: TOwnerId);
begin
  if MinimapOwner <> Owner then
  begin
  MinimapOwner := Owner;
  if MinimapControl <> nil then
  begin
      MinimapControl.SetImagePath('Bm.Planet.M.' + OwnerInfo[MinimapOwner].InternalName);
    MinimapControl.SetSize(MinimapControl.GetContentSize);
  end;
  end;
end;
{ @end $6077A8 }

{ @routine $607868 TPlanetSE_SetPosition }
procedure TPlanetSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
    if CollisionCircle <> nil then
    begin
      CollisionCircle.Position.X := Position.X;
      CollisionCircle.Position.Y := Position.Y;
      CollisionCircle.Radius := Radius;
      CollisionCircle.RadiusSquared := Radius * Radius;
    end;
    UpdateLightAngleFromStar;
    if IsAttachedToSpace then
    begin
      PlanetControl.SetPosition(Classes.Point(Round(APosition.X), Round(APosition.Y)));
      MinimapControl.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
      if RingControl1 <> nil then RingControl1.SetPosition(PlanetControl.LocalPosition);
      if RingControl2 <> nil then RingControl2.SetPosition(PlanetControl.LocalPosition);
  end;
end;
{ @end $607868 }

{ @routine $607970 TPlanetSE_SetSurfaceMapOffset }
procedure TPlanetSE.SetSurfaceMapOffset(Value: Integer);
begin
  SurfaceMapOffset := Value;
  if IsAttachedToSpace then PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
end;
{ @end $607970 }

{ @routine $607994 TPlanetSE_SetLightAngle }
procedure TPlanetSE.SetLightAngle(Value: Byte);
begin
  LightAngle := Value;
  if IsAttachedToSpace then PlanetControl.SetLightAngle(LightAngle);
end;
{ @end $607994 }

{ @routine $6079B8 TPlanetSE_SetRotationTimerInterval }
procedure TPlanetSE.SetRotationTimerInterval(Value: Cardinal);
begin
  RotationTimerInterval := Value;
  if IsAttachedToSpace then
  begin
    if RotationTimer <> nil then
    begin
      Space.DeleteTimer(RotationTimer);
      RotationTimer := nil;
    end;
    RotationTimer := Space.CreateTimer(0, RotationTimerInterval, AdvanceRotationTimer, 0);
  end;
end;
{ @end $6079B8 }

{ @routine $607A04 TPlanetSE_SetSurfaceMapStep }
procedure TPlanetSE.SetSurfaceMapStep(Value: Integer);
begin
  SurfaceMapStep := Value;
end;
{ @end $607A04 }

{ @routine $607A08 TPlanetSE_SetRingKind }
procedure TPlanetSE.SetRingKind(Kind: Byte);
begin
  RingKind := Kind;
  if IsAttachedToSpace then RebuildRings;
end;
{ @end $607A08 }

{ @routine $607A24 TPlanetSE_UpdateLightAngleFromStar }
procedure TPlanetSE.UpdateLightAngleFromStar;
var
  Obj: TObjectSE;
begin
  if IsAttachedToSpace then
  begin
    Obj := Space.FirstObject;
    while Obj <> nil do
    begin
      if Obj is TStarSE then
      begin
        SetLightAngle(Trunc(ArcTan2(-(Position.X - Obj.Position.X), Position.Y - Obj.Position.Y) * 180 / 3.1415926 * 256 / 360));
        Break;
      end;
      Obj := Obj.Next;
    end;
  end;
end;
{ @end $607A24 }

{ @routine $607ABC TPlanetSE_AdvanceRotationTimer }
procedure TPlanetSE.AdvanceRotationTimer(Timer: PSpaceTimerSE; UserData: Integer);
begin
  SetSurfaceMapOffset(SurfaceMapOffset + SurfaceMapStep);
end;
{ @end $607ABC }

{ @routine $607AC8 TPlanetSE_HitTestCursor }
function TPlanetSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then
  begin
    Result := False;
    Exit;
  end;
  Result := PlanetControl.HitTestCursor;
end;
{ @end $607AC8 }

{ @routine $607AE8 TPlanetSE_DrawMap }
procedure TPlanetSE.DrawMap;
var
  Capacity, Index, X, Y, CenterX, CenterY: Integer;
  ProjectedXi, ProjectedYi, Decision, OrbitRadius, Pitch: Integer;
  ProjectedX, ProjectedY: Single;
  Dest, P0, P1, P2, P3, P4, P5, P6, P7: PPlanetMapOrbitPoint;
  Pixels, Scratch: Pointer;
  OctantCount: Integer;
  Intensity, IntensityStep: Single;
begin
  with Space.Process as TProcessSE do
  begin
    if RadarRange <= 0 then Exit;
      Pixels := RenderScratchBuffer.Pixels;
      Pitch := RenderScratchBuffer.PitchBytes;
      ProjectedX := Position.X * Self.Space.MinimapScale;
      ProjectedY := Position.Y * Self.Space.MinimapScale;
      ProjectedXi := Round(ProjectedX);
      ProjectedYi := Round(ProjectedY);
      if MapOrbitPoints = nil then
      begin
        Capacity := RenderScratchBuffer.Width shr 1;
        Scratch := AllocEC(Capacity * 8 * SizeOf(TPlanetMapOrbitPoint));
        OrbitRadius := Round(Sqrt(ProjectedXi * ProjectedXi + ProjectedYi * ProjectedYi));
        CenterX := RenderScratchBuffer.Width shr 1;
        CenterY := RenderScratchBuffer.Height shr 1;
        Decision := 3 - 2 * OrbitRadius;
        X := 0;
        Y := OrbitRadius - 1;
        P0 := Scratch;
        P1 := AddPointerOffset(P0, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P2 := AddPointerOffset(P1, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P3 := AddPointerOffset(P2, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P4 := AddPointerOffset(P3, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P5 := AddPointerOffset(P4, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P6 := AddPointerOffset(P5, Capacity * SizeOf(TPlanetMapOrbitPoint));
        P7 := AddPointerOffset(P6, Capacity * SizeOf(TPlanetMapOrbitPoint));
        OctantCount := 0;
        repeat
          P0.Position.X := CenterX + X;
          P0.Position.Y := CenterY - Y;
          P0 := AddPointerOffset(P0, SizeOf(TPlanetMapOrbitPoint));
          P1.Position.X := CenterX + Y;
          P1.Position.Y := CenterY - X;
          P1 := AddPointerOffset(P1, SizeOf(TPlanetMapOrbitPoint));
          P2.Position.X := CenterX + Y;
          P2.Position.Y := CenterY + X;
          P2 := AddPointerOffset(P2, SizeOf(TPlanetMapOrbitPoint));
          P3.Position.X := CenterX + X;
          P3.Position.Y := CenterY + Y;
          P3 := AddPointerOffset(P3, SizeOf(TPlanetMapOrbitPoint));
          P4.Position.X := CenterX - X;
          P4.Position.Y := CenterY + Y;
          P4 := AddPointerOffset(P4, SizeOf(TPlanetMapOrbitPoint));
          P5.Position.X := CenterX - Y;
          P5.Position.Y := CenterY + X;
          P5 := AddPointerOffset(P5, SizeOf(TPlanetMapOrbitPoint));
          P6.Position.X := CenterX - Y;
          P6.Position.Y := CenterY - X;
          P6 := AddPointerOffset(P6, SizeOf(TPlanetMapOrbitPoint));
          P7.Position.X := CenterX - X;
          P7.Position.Y := CenterY - Y;
          P7 := AddPointerOffset(P7, SizeOf(TPlanetMapOrbitPoint));
          Inc(OctantCount);
          if Decision < 0 then
            Decision := 4 * X + Decision + 6
          else
          begin
            Decision := 4 * (X - Y) + Decision + 10;
            Dec(Y);
          end;
          Inc(X);
        until X > Y;
        MapOrbitPointCount := OctantCount * 8;
        MapOrbitPoints := AllocEC(MapOrbitPointCount * SizeOf(TPlanetMapOrbitPoint));
        Dest := MapOrbitPoints;
        P0 := Scratch;
        P1 := AddPointerOffset(Scratch, Capacity * SizeOf(TPlanetMapOrbitPoint) + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint));
        P2 := AddPointerOffset(Scratch, Capacity * 2 * SizeOf(TPlanetMapOrbitPoint));
        P3 := AddPointerOffset(Scratch, Capacity * 3 * SizeOf(TPlanetMapOrbitPoint) + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint));
        P4 := AddPointerOffset(Scratch, Capacity * 4 * SizeOf(TPlanetMapOrbitPoint));
        P5 := AddPointerOffset(Scratch, Capacity * 5 * SizeOf(TPlanetMapOrbitPoint) + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint));
        P6 := AddPointerOffset(Scratch, Capacity * 6 * SizeOf(TPlanetMapOrbitPoint));
        P7 := AddPointerOffset(Scratch, Capacity * 7 * SizeOf(TPlanetMapOrbitPoint) + (OctantCount - 1) * SizeOf(TPlanetMapOrbitPoint));
        X := -10000;
        Y := -10000;
        { Native octant traversal suppresses duplicates at the joins. }
        for Index := 0 to OctantCount - 1 do
        begin
          if (P0.Position.X <> X) or (P0.Position.Y <> Y) then
          begin
            Dest.Position.X := P0.Position.X;
            Dest.Position.Y := P0.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P0 := AddPointerOffset(P0, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P1.Position.X <> X) or (P1.Position.Y <> Y) then
          begin
            Dest.Position.X := P1.Position.X;
            Dest.Position.Y := P1.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P1 := AddPointerOffset(P1, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P2.Position.X <> X) or (P2.Position.Y <> Y) then
          begin
            Dest.Position.X := P2.Position.X;
            Dest.Position.Y := P2.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P2 := AddPointerOffset(P2, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P3.Position.X <> X) or (P3.Position.Y <> Y) then
          begin
            Dest.Position.X := P3.Position.X;
            Dest.Position.Y := P3.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P3 := AddPointerOffset(P3, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P4.Position.X <> X) or (P4.Position.Y <> Y) then
          begin
            Dest.Position.X := P4.Position.X;
            Dest.Position.Y := P4.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P4 := AddPointerOffset(P4, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P5.Position.X <> X) or (P5.Position.Y <> Y) then
          begin
            Dest.Position.X := P5.Position.X;
            Dest.Position.Y := P5.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P5 := AddPointerOffset(P5, -SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P6.Position.X <> X) or (P6.Position.Y <> Y) then
          begin
            Dest.Position.X := P6.Position.X;
            Dest.Position.Y := P6.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P6 := AddPointerOffset(P6, SizeOf(TPlanetMapOrbitPoint));
        end;
        for Index := 0 to OctantCount - 1 do
        begin
          if (P7.Position.X <> X) or (P7.Position.Y <> Y) then
          begin
            Dest.Position.X := P7.Position.X;
            Dest.Position.Y := P7.Position.Y;
            Dest.PixelOffset := 2 * Dest.Position.X + Dest.Position.Y * Pitch;
            X := Dest.Position.X;
            Y := Dest.Position.Y;
            Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
          end
          else Dec(MapOrbitPointCount);
          P7 := AddPointerOffset(P7, -SizeOf(TPlanetMapOrbitPoint));
        end;
        FreeEC(Scratch);
      end;
      Index := Round(RadiansToHeadingDegrees(ArcTan2(ProjectedX, -ProjectedY)) / 360 * (MapOrbitPointCount - 1));
      Dest := AddPointerOffset(MapOrbitPoints, Index * SizeOf(TPlanetMapOrbitPoint));
      Intensity := 255;
      IntensityStep := -510 / MapOrbitPointCount;
      while Intensity > 0 do
      begin
        BlendPixel16(AddPointerOffset(Pixels, Dest.PixelOffset),
          ReadWordEC(AddPointerOffset(InterfaceBlendPalette, Round(Intensity) * 2)), Round(Intensity));
        if OrbitalVelocity > 0 then
        begin
          Dec(Index);
          if Index < 0 then
          begin
            Index := MapOrbitPointCount - 1;
            Dest := AddPointerOffset(MapOrbitPoints, Index * SizeOf(TPlanetMapOrbitPoint));
          end
          else Dest := AddPointerOffset(Dest, -SizeOf(TPlanetMapOrbitPoint));
        end
        else
        begin
          Inc(Index);
          if Index >= MapOrbitPointCount then
          begin
            Index := 0;
            Dest := MapOrbitPoints;
          end
          else Dest := AddPointerOffset(Dest, SizeOf(TPlanetMapOrbitPoint));
        end;
        Intensity := Intensity + IntensityStep;
      end;
      MinimapControl.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
end;
{ @end $607AE8 }

{ @routine $6084E4 TPlanetSE_RenderToBuffer }
procedure TPlanetSE.RenderToBuffer(Screen: TMessageLoopGI; Buffer: TGraphBufGR; SmallPreview: Boolean);
var
  NativePixels, DestPixels, MaskPixels: Pointer;
  Diameter: Integer;
  Template: TPlanetTempl;
  Planet: TPlanetGI;
  Index, Count, TemplateIndex: Integer;
  SavedBuffer: TGraphBufGR;
  Control: TCBitmapControlEC;
  Bitmap: TCBitmapEC;
  RenderRadius: Integer;
  SatelliteTemplate: TSputnikTempl;
  TempBuffer: TGraphBufGR;
begin
  SatelliteTemplate := nil;
  Template := nil;
  if not SmallPreview then
  begin
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      Template := PlanetRenderTemplates[Index];
      if Radius = Template.Radius then Break;
    end;
    if Template = nil then raise Exception.Create('Error');
  end;
  if SmallPreview then RenderRadius := 25 else RenderRadius := (Radius * 2) div 2;
  Diameter := RenderRadius * 2;
  if Diameter < 1 then raise Exception.Create('Error');
  Planet := TPlanetGI.Create(Screen.ContentPanel);
  Planet.SetPositionModeW(False);
  Planet.SetPosition(Classes.Point(RenderRadius + 1, RenderRadius + 1));
  Planet.SetSurfaceMapOffset(0);
  Planet.SetOrigin(Classes.Point(RenderRadius, RenderRadius));
  if SmallPreview then
  begin
    TemplateIndex := RenderRadius * 2 - MinimumSatelliteTemplateRadius;
    SatelliteTemplate := SatelliteRenderTemplates[TemplateIndex];
    Planet.SetImageFromTemplate(SatelliteTemplate.MaskName, ImagePath, SatelliteTemplate.Radius);
  end
  else Planet.SetImageWithRadius(Template.MaskName, ImagePath, Template.LightName, RenderRadius);
  Planet.SetLightAngle(224);
  Planet.HitTestBounds := Classes.Rect(-1, -1, Diameter, Diameter);
  Control := TCBitmapControlEC.Create;
  GlobalCache.ResetControl(Control);
  if SmallPreview then Control.SetCacheKey(ExtractDelimitedPartW(SatelliteTemplate.MaskName, 0, '?') + '?RGBA')
  else Control.SetCacheKey(Template.MaskName + '?RGBA');
  Bitmap := AcquireOrCreateBitmap(Control);
  TempBuffer := TGraphBufGR.Create;
  TempBuffer.AllocateNativePitch(Diameter, Diameter, Diameter * 2);
  TempBuffer.ClearPixels;
  Buffer.AllocateRgba(Diameter + 4, Diameter + 4, (Diameter + 4) * 4);
  Buffer.ClearPixels;
  SavedBuffer := ScreenRenderBuffer;
  ScreenRenderBuffer := TempBuffer;
  Planet.Draw(Classes.Rect(0, 0, Diameter, Diameter));
  ScreenRenderBuffer := SavedBuffer;
  Planet.Free;
  NativePixels := TempBuffer.Pixels;
  DestPixels := AddPointerOffset(Buffer.Pixels, Buffer.PitchBytes * 2 + 8);
  MaskPixels := Bitmap.Bitmap.Pixels;
  // Handwritten native loops ($6087C7/$60881E), with a two-pixel RGBA border.
  if CurrentPixelFormat.TotalChannelBits = 16 then
  asm
    pushad
    mov esi, NativePixels
    mov edi, DestPixels
    mov edx, MaskPixels
    mov ecx, Diameter
    mov ebx, Diameter
  @@Pixel565:
    mov ax, [esi]
    shl eax, 3
    and eax, $F8
    mov [edi], al
    mov ax, [esi]
    shr eax, 3
    and eax, $FC
    mov [edi + 1], al
    mov ax, [esi]
    shr eax, 8
    and eax, $F8
    mov [edi + 2], al
    mov al, [edx + 3]
    mov [edi + 3], al
    add esi, 2
    add edi, 4
    add edx, 4
    dec ecx
    jnz @@Pixel565
    mov ecx, Diameter
    add edi, 16
    dec ebx
    jnz @@Pixel565
    popad
  end
  else
  asm
    pushad
    mov esi, NativePixels
    mov edi, DestPixels
    mov edx, MaskPixels
    mov ecx, Diameter
    mov ebx, Diameter
  @@Pixel555:
    mov ax, [esi]
    shl eax, 3
    and eax, $F8
    mov [edi], al
    mov ax, [esi]
    shr eax, 2
    and eax, $F8
    mov [edi + 1], al
    mov ax, [esi]
    shr eax, 7
    and eax, $F8
    mov [edi + 2], al
    mov al, [edx + 3]
    mov [edi + 3], al
    add esi, 2
    add edi, 4
    add edx, 4
    dec ecx
    jnz @@Pixel555
    mov ecx, Diameter
    add edi, 16
    dec ebx
    jnz @@Pixel555
    popad
  end;
  TempBuffer.Free;
  Control.Release;
  Control.Free;
end;
{ @end $6084E4 }

{ @routine $6088E0 TPlanetSE_LoadTemplate }
procedure TPlanetSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  RotationTimerInterval := 100;
  SurfaceMapStep := -1;
  ImagePath := Block.GetParam('Image');
  MinimapImagePath := Block.GetParam('ImageMap');
  ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
  MinimapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
  Radius := StrToInt(Block.GetParam('Radius'));
end;
{ @end $6088E0 }

{ @routine $608A74 TPlanetSE_ApplyConfig }
procedure TPlanetSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('SmeMap') > 0 then SetSurfaceMapOffset(StrToInt(Block.GetParam('SmeMap')));
  if Block.CountParams('AngleLight') > 0 then SetLightAngle(StrToInt(Block.GetParam('AngleLight')));
  if Block.CountParams('SpeedRotate') > 0 then SetRotationTimerInterval(StrToInt(Block.GetParam('SpeedRotate')));
  if Block.CountParams('StepRotate') > 0 then SetSurfaceMapStep(StrToInt(Block.GetParam('StepRotate')));
end;
{ @end $608A74 }
{ @routine $608C50 TPlanetSE_QueueImageLoad }
procedure TPlanetSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TPlanetTempl;
  Index, Count: Integer;
begin
    Template := nil;
    Count := PlanetRenderTemplates.Count;
    for Index := 0 to Count - 1 do
    begin
      Template := PlanetRenderTemplates[Index];
      if Template.Radius = Radius then Break;
    end;
    if Template = nil then raise Exception.Create('Error');
    with TPlanetGI.Create(Owner) do
    begin
      SetImageWithRadius(Template.SmallMaskName, Self.ImagePath, Template.SmallLightName, Self.Radius);
      QueueImageLoad(PendingLoads);
      Free;
    end;
    with TAlphaImageGI.Create(Owner) do
    begin
      SetImagePath(Self.MinimapImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
end;
{ @end $608C50 }

{ @routine $608D28 AllocatePlanetCollisionCircle }
function AllocatePlanetCollisionCircle: PPlanetCollisionCircle;
var
  Entry: PPlanetCollisionCircle;
begin
  New(Entry);
  Entry.Next := FirstPlanetCollisionCircle;
  Entry.Prev := nil;
  if Entry.Next <> nil then Entry.Next.Prev := Entry;
  FirstPlanetCollisionCircle := Entry;
  Result := Entry;
end;
{ @end $608D28 }
{ @routine $608D50 FreePlanetCollisionCircle }
procedure FreePlanetCollisionCircle(Entry: PPlanetCollisionCircle);
begin
  if Entry.Next <> nil then Entry.Next.Prev := Entry.Prev;
  if Entry.Prev <> nil then Entry.Prev.Next := Entry.Next;
  if Entry = FirstPlanetCollisionCircle then FirstPlanetCollisionCircle := Entry.Next;
  Dispose(Entry);
end;
{ @end $608D50 }

end.

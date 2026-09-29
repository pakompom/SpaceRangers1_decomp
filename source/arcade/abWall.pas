unit abWall;
// Unit bracket (inferred): CODE 0x004F9590..0x004F9CDB; inclusive evidence, not full bounds.
// Grouped by TabWall's native VMT; original unit boundary unresolved.

interface

uses Classes, GI_MessageLoop, ab_Object, ab_Hit, ab_StopLine, ab_WorldImage, ab_Zone;

type
  TabWall = class(TabHit) // @size $C0
  public
    Zone: PabZone; // @offset $B0
    WorldImage: PabWorldImage; // @offset $B4
    DirectionFrameCount: Integer; // @offset $B8
    StopPoint: PabStopPoint; // @offset $BC
    constructor Create; // @addr $4F95F8
    destructor Destroy; override; // @addr $4F9660
    procedure BindZone(Value: PabZone); // @addr $4F969C
    procedure AttachVisual; // @addr $4F9824 @note "Empty in this native version; called after arena wall setup."
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $4F9828
    procedure ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean); override; // @addr $4F982C
    procedure UpdateState; override; // @addr $4F98F8
    procedure Advance; override; // @addr $4F9900
    procedure UpdateVisuals; override; // @addr $4F9974
  end;

function ab_Wall_FindZone(Zone: PabZone): TabWall; // @addr $4F9A90
procedure ab_Wall_BuildBarrierImages; // @addr $4F9B20

var
  BarrierColor: Cardinal = 822062080; // @addr $6186D0
  BarrierHaloColors: array[0..1] of Cardinal = (1090509568, 553626624); // @addr $6186D4

implementation

// @unit-initialization $4F9CD4
// @unit-finalization $4F9CA4

uses Math, EC_Str, EC_Struct, GI_Tail, ab_Global, GR_Main;

{ @routine $4F95F8 TabWall_Create }
constructor TabWall.Create;
begin
  inherited Create;
  TurnSpeedScale := 1;
  DisruptUntilTick := 0;
  Health := 200;
  MaxHealth := 200;
  WallCollisionEnabled := True;
end;
{ @end $4F95F8 }

{ @routine $4F9660 TabWall_Destroy }
destructor TabWall.Destroy;
begin
  if WorldImage <> nil then
  begin
    ab_WorldImage_Delete(WorldImage);
    WorldImage := nil;
  end;
  inherited Destroy;
end;
{ @end $4F9660 }

{ @routine $4F969C TabWall_BindZone }
procedure TabWall.BindZone(Value: PabZone);
begin
  Zone := Value;
  if Value.Name <> '' then
  begin
    WorldImage := ab_WorldImage_Create(MakeVector3D(0, 0, 0),
      'GAI,Bm.ABWall.' + GiResourceSuffix + '.' + Value.Name, '', True);
    ab_WorldImage_SetDepth(WorldImage, WorldImageFrontDepth, WorldImageBackDepth);
    DirectionFrameCount := CountDelimitedPartsW(Value.Name, '_');
    DirectionFrameCount := ExtractDigitsToIntW(ExtractDelimitedPartW(Value.Name, DirectionFrameCount - 1, '_'));
  end;
  DirectionFrameCount := 32; // Native overwrites the parsed count above.
  EffectOriginSpread := GiScalePixels(20);
  Mass := 10;
  State.PolarAngleDegrees := 0;
  State.BearingDegrees := 0;
  CollisionRadius := 11;
  ZoneRadius := Value.Radius;
end;
{ @end $4F969C }

{ @routine $4F9824 TabWall_AttachVisual }
procedure TabWall.AttachVisual;
begin
end;
{ @end $4F9824 }

{ @routine $4F9828 TabWall_QueueImageLoad }
procedure TabWall.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
end;
{ @end $4F9828 }

{ @routine $4F982C TabWall_ApplyDamage }
procedure TabWall.ApplyDamage(Amount: Integer; Source: TabObject; Disrupt: Boolean);
var
  Line, Next, Auxiliary: PabStopLine;
  Changed: Boolean;
begin
  if Health > 0 then
  begin
    inherited ApplyDamage(Amount, Source, Disrupt);
    if (Health <= 0) and (StopPoint <> nil) then
    begin
      Changed := False;
      Line := FirstStopLine;
      while Line <> nil do
      begin
        // The first endpoint bypasses the Collidable test in the native code.
        if (StopPoint = Line.First) or ((StopPoint = Line.Last) and Line.Collidable) then
        begin
          Line.Collidable := False;
          Changed := True;
          Next := FirstStopLine;
          while Next <> nil do
          begin
            Auxiliary := Next;
            Next := Next.Next;
            if PabStopLine(Auxiliary.UserValue) = Line then ab_StopLine_Delete(Auxiliary);
          end;
        end;
        Line := Line.Next;
      end;
      if Changed then ab_StopLine_BuildCollisionList;
    end;
    if Health <= 0 then
    begin
      Zone.DamagePerTick := 0;
      Zone.GravityStrength := 0;
    end;
  end;
end;
{ @end $4F982C }

{ @routine $4F98F8 TabWall_UpdateState }
procedure TabWall.UpdateState;
begin
  inherited UpdateState;
end;
{ @end $4F98F8 }

{ @routine $4F9900 TabWall_Advance }
procedure TabWall.Advance;
begin
  if Health = 0 then
  begin
    Velocity := MakePointF(0, 0);
    Thrust := 0;
    if WorldImage <> nil then
    begin
      ab_WorldImage_Delete(WorldImage);
      WorldImage := nil;
    end;
  end
  else if WorldImage <> nil then
    ab_WorldImage_SetPosition(WorldImage, GetWorldPosition);
end;
{ @end $4F9900 }

{ @routine $4F9974 TabWall_UpdateVisuals }
procedure TabWall.UpdateVisuals;
var
  Frame: Integer;
  Value: Single;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  if (WorldImage <> nil) and (WorldImage.Image.GaiImageControl <> nil) then
  begin
    Position := GetWorldPosition;
    Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
    Value := RadiansToHeadingDegrees(ArcTan2(Position.X, -Position.Y));
    Frame := Round(Value / 360 * DirectionFrameCount);
    if Frame >= DirectionFrameCount then Frame := 0;
    Value := Sqrt(Sqr(Position.X) + Sqr(Position.Y)) / SphereProjectedRadius;
    Inc(Frame, Round((WorldImage.Image.GaiImageControl.SequenceFrameCount / DirectionFrameCount - 1) * Value) * DirectionFrameCount);
    WorldImage.Image.GaiImageControl.SetSequenceFrame(Frame);
  end;
end;
{ @end $4F9974 }

{ @routine $4F9A90 ab_Wall_FindZone }
function ab_Wall_FindZone(Zone: PabZone): TabWall;
var
  Obj: TabObject;
begin
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if (Obj is TabWall) and (TabWall(Obj).Zone = Zone) then
    begin
      Result := Obj as TabWall;
      Exit;
    end;
    Obj := Obj.Next;
  end;
  Result := nil;
end;
{ @end $4F9A90 }

{ @routine $4F9B20 ab_Wall_BuildBarrierImages }
procedure ab_Wall_BuildBarrierImages;
var
  Line, ImageLine: PabStopLine;
  First, Last: PabStopPoint;
  Index: Integer;

  // @nested $4F9AD8 FindStopPoint
  function FindStopPoint(Point: PabStopPoint): TabWall; // @addr $4F9AD8 @calls "$4F9B4E,$4F9B61"
  var
    Obj: TabObject;
  begin
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if (Obj is TabWall) and (TabWall(Obj).StopPoint = Point) then
      begin
        Result := Obj as TabWall;
        Exit;
      end;
      Obj := Obj.Next;
    end;
    Result := nil;
  end;

begin
  Line := FirstStopLine;
  while Line <> nil do
  begin
    if Line.Collidable and (FindStopPoint(Line.First) <> nil) and (FindStopPoint(Line.Last) <> nil) then
    begin
      ImageLine := ab_StopLine_Add;
      ImageLine.UserValue := Integer(Line);
      ImageLine.First := Line.First;
      ImageLine.Last := Line.Last;
      ImageLine.FirstColor := @BarrierColor;
      ImageLine.LastColor := @BarrierColor;
      ImageLine.Collidable := False;
      ImageLine.Visible := True;
      for Index := 0 to 1 do
      begin
        First := ab_StopPoint_Add;
        First.Radius := (Index + 1) * 20 + SphereRadius;
        First.Longitude := ImageLine.First.Longitude;
        First.PolarAngle := ImageLine.First.PolarAngle;
        First.Kind := 1;
        ab_StopPoint_UpdatePosition(First);
        Last := ab_StopPoint_Add;
        Last.Radius := (Index + 1) * 20 + SphereRadius;
        Last.Longitude := ImageLine.Last.Longitude;
        Last.PolarAngle := ImageLine.Last.PolarAngle;
        Last.Kind := 1;
        ab_StopPoint_UpdatePosition(Last);
        ImageLine := ab_StopLine_Add;
        ImageLine.UserValue := Integer(Line);
        ImageLine.First := First;
        ImageLine.Last := Last;
        ImageLine.FirstColor := @BarrierHaloColors[Index];
        ImageLine.LastColor := @BarrierHaloColors[Index];
        ImageLine.Collidable := False;
        ImageLine.Visible := True;
      end;
    end;
    Line := Line.Next;
  end;
end;
{ @end $4F9B20 }

end.

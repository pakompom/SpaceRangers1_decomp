unit ab_W14;
// Unit bracket (inferred): CODE 0x004F4BD4..0x004F502B; inclusive evidence, not full bounds.

interface

uses EC_Struct, GI_Tail, ab_Global, ab_Object, ab_WorldImage;

type
  TabW14 = class(TabObject) // @size $A0
  public
    Damage: Integer; // @offset $90
    Image: PabWorldImage; // @offset $94
    Phase: Integer; // @offset $98
    ExpireTick: Integer; // @offset $9C
    constructor Create; // @addr $4F4C3C
    destructor Destroy; override; // @addr $4F4CA8
    procedure Launch(Owner: TabObject; Amount: Integer; Angle: Single); // @addr $4F4CE4
    procedure Advance; override; // @addr $4F4DD4
    procedure UpdateVisuals; override; // @addr $4F4F68
  end;

implementation

// @unit-initialization $4F5024
// @unit-finalization $4F4FF4

uses GlobalsV, ab_Ship;

{ @routine $4F4C3C TabW14_Create }
constructor TabW14.Create;
begin
  inherited Create;
  MaxSpeed := 25;
  Mass := 1;
  Thrust := 1.5;
  CollisionRadius := 5;
  Collidable := True;
end;
{ @end $4F4C3C }

{ @routine $4F4CA8 TabW14_Destroy }
destructor TabW14.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;
{ @end $4F4CA8 }

{ @routine $4F4CE4 TabW14_Launch }
procedure TabW14.Launch(Owner: TabObject; Amount: Integer; Angle: Single);
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 150;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w14_f', 'GAI,Bm.AB.w14_s', True);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;
{ @end $4F4CE4 }

{ @routine $4F4DD4 TabW14_Advance }
procedure TabW14.Advance;
var
  Collision: TabObject;
begin
  inherited Advance;
  if Phase <> 1 then ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if Phase <> 1 then
  begin
    Collision := FindCollision;
    if (Collision <> nil) and (SourceObject <> nil) and (Collision is TabShip) and
      (TabShip(SourceObject).Enemies.IndexOf(Collision) < 0) then Collision := nil
    else if Collision = SourceObject then Collision := nil
    else if Collision is TabW14 then Collision := nil;
  end;
  { Native launch sets ExpireTick, but flight expires by half-circumference. }
  if ((DistanceTravelled > Pi * SphereRadius) or (Collision <> nil)) and (Phase <> 1) then
  begin
    if Collision <> nil then Collision.ApplyDamage(Damage, SourceObject, False);
    Phase := 1;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w14a_f', 'GAI,Bm.AB.w14a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if Phase = 1 then DeletionPending := Image.Finished;
end;
{ @end $4F4DD4 }

{ @routine $4F4F68 TabW14_UpdateVisuals }
procedure TabW14.UpdateVisuals;
var
  Frame: Integer;
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  if Phase = 0 then
  begin
    Position := GetWorldPosition;
    Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
    Frame := Round(GetProjectedHeading(Position) / 360 * Image.Image.GaiImageControl.SequenceFrameCount);
    if Frame >= Image.Image.GaiImageControl.SequenceFrameCount then Frame := 0;
    Image.Image.GaiImageControl.SetSequenceFrame(Frame);
  end;
end;
{ @end $4F4F68 }

end.

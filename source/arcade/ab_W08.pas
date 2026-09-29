unit ab_W08;
// Unit bracket (inferred): CODE 0x004F2674..0x004F2C13; inclusive evidence, not full bounds.

interface

uses EC_Struct, GI_Tail, ab_Global, ab_Object, ab_WorldImage;

type
  TabW08 = class(TabObject) // @size $A4
  public
    Damage: Integer; // @offset $90
    Image: PabWorldImage; // @offset $94
    Exploding: Boolean; // @offset $98
    Generation: Integer; // @offset $9C
    ExpireTick: Integer; // @offset $A0
    constructor Create; // @addr $4F26DC
    destructor Destroy; override; // @addr $4F2748
    procedure Launch(Owner: TabObject; Amount: Integer; Angle: Single; AGeneration: Integer; Origin: TabObject); // @addr $4F2784
    procedure Advance; override; // @addr $4F2950
    procedure UpdateVisuals; override; // @addr $4F2BD4
  end;

implementation

// @unit-initialization $4F2C0C
// @unit-finalization $4F2BDC

uses ab_Ship, GlobalsV, aMyFunction;

{ @routine $4F26DC TabW08_Create }
constructor TabW08.Create;
begin
  inherited Create;
  MaxSpeed := 100;
  Mass := 1;
  Thrust := 0.8;
  CollisionRadius := 5;
  Collidable := False;
end;
{ @end $4F26DC }

{ @routine $4F2748 TabW08_Destroy }
destructor TabW08.Destroy;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  inherited Destroy;
end;
{ @end $4F2748 }

{ @routine $4F2784 TabW08_Launch }
procedure TabW08.Launch(Owner: TabObject; Amount: Integer; Angle: Single; AGeneration: Integer; Origin: TabObject);
begin
  SourceObject := Owner;
  Damage := Amount;
  if Origin <> nil then State := Origin.State
  else State := Owner.State;
  State.BearingDegrees := WrapHeadingDegrees(State.BearingDegrees + Angle);
  // Requires Owner even when Origin supplies the launch state.
  Velocity := Owner.Velocity;
  Generation := AGeneration;
  if Generation = 0 then ExpireTick := ArcadeTickCount + 30
  else ExpireTick := ArcadeTickCount + 15;
  if Generation = 0 then
  begin
    Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w08_f', 'GAI,Bm.AB.w08_s', False);
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  end
  else
  begin
    Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w08b_f', 'GAI,Bm.AB.w08b_s', False);
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
  end;
end;
{ @end $4F2784 }

{ @routine $4F2950 TabW08_Advance }
procedure TabW08.Advance;
var
  Collision: TabObject;
  Child: TabW08;
begin
  inherited Advance;
  if not Exploding then ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 200) and (Collision = SourceObject) then Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and not Exploding then
  begin
    if Collision <> nil then Collision.ApplyDamage(Damage, SourceObject, False)
    else if Generation <= 1 then
    begin
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(SourceObject as TabShip, Damage div 3, RandomIntRange(0, 360), Generation + 1, Self);
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(SourceObject as TabShip, Damage div 3, RandomIntRange(0, 360), Generation + 1, Self);
      Child := TabW08.Create;
      ab_Object_Add(Child);
      Child.Launch(SourceObject as TabShip, Damage div 3, RandomIntRange(0, 360), Generation + 1, Self);
    end;
    Exploding := True;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w08a_f', 'GAI,Bm.AB.w08a_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if Exploding then DeletionPending := Image.Finished;
end;
{ @end $4F2950 }

{ @routine $4F2BD4 TabW08_UpdateVisuals }
procedure TabW08.UpdateVisuals;
begin
  inherited UpdateVisuals;
end;
{ @end $4F2BD4 }

end.

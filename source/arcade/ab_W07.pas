unit ab_W07;
// Unit bracket (inferred): CODE 0x004F2038..0x004F2673; inclusive evidence, not full bounds.

interface

uses Classes, EC_Struct, GI_Tail, ab_Global, ab_Object, ab_WorldImage;

type
  TabW07 = class(TabObject) // @size $AC
  public
    Damage: Integer; // @offset $90
    Image: PabWorldImage; // @offset $94
    Exploding: Boolean; // @offset $98
    TrailDistance: Single; // @offset $9C
    ExpireTick: Integer; // @offset $A0
    TurnSpeed: Single; // @offset $A4
    TrailImages: TList; // @offset $A8
    constructor Create; // @addr $4F20A0
    destructor Destroy; override; // @addr $4F2128
    procedure Launch(Owner: TabObject; Amount: Integer; Offset: Single); // @addr $4F21A8
    procedure Advance; override; // @addr $4F2304
    procedure UpdateVisuals; override; // @addr $4F24EC
  end;

implementation

// @unit-initialization $4F266C
// @unit-finalization $4F263C

uses ab_Ship, GlobalsV;

{ @routine $4F20A0 TabW07_Create }
constructor TabW07.Create;
begin
  inherited Create;
  MaxSpeed := 12;
  TurnSpeed := 10;
  Mass := 1;
  Thrust := 0.7;
  CollisionRadius := 1;
  Collidable := True;
  TrailImages := TList.Create;
end;
{ @end $4F20A0 }

{ @routine $4F2128 TabW07_Destroy }
destructor TabW07.Destroy;
var
  Index: Integer;
begin
  if Image <> nil then
  begin
    ab_WorldImage_Delete(Image);
    Image := nil;
  end;
  if TrailImages <> nil then
  begin
    for Index := 0 to TrailImages.Count - 1 do ab_WorldImage_Delete(TrailImages[Index]);
    TrailImages.Free;
    TrailImages := nil;
  end;
  inherited Destroy;
end;
{ @end $4F2128 }

{ @routine $4F21A8 TabW07_Launch }
procedure TabW07.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
var
  Heading, HeadingDelta: Double;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 300;
  if Offset <> 0 then
  begin
    Heading := WrapHeadingDegrees(State.BearingDegrees + 90);
    HeadingDelta := HeadingDifferenceDegrees(Heading, State.BearingDegrees);
    AdvanceSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, Heading, SphereRadius, Offset);
    State.BearingDegrees := WrapHeadingDegrees(Heading + HeadingDelta);
  end;
  TrailDistance := 0;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w07_f', 'GAI,Bm.AB.w07_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;
{ @end $4F21A8 }

{ @routine $4F2304 TabW07_Advance }
procedure TabW07.Advance;
var
  Collision: TabObject;
  Enemy: TabShip;
begin
  inherited Advance;
  if not Exploding then ab_WorldImage_SetPosition(Image, GetWorldPosition);
  if DistanceTravelled > 400 then MaxSpeed := 5;
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if (DistanceTravelled < 400) and (Collision = SourceObject) then Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and not Exploding then
  begin
    if Collision <> nil then Collision.ApplyDamage(Damage, SourceObject, False);
    Exploding := True;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w07b_f', 'GAI,Bm.AB.w07b_s');
    ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
    ab_WorldImage_SetLooping(Image, False);
  end
  else if not Exploding and (Collision = nil) then
  begin
    if SourceObject <> nil then
    begin
      Enemy := SourceObject as TabShip;
      Enemy := Enemy.FindNearestEnemy(Self);
      if Enemy <> nil then
        with BearingAndDistanceTo(Enemy) do
        begin
          if BearingDeltaDegrees < -TurnSpeed then BearingDeltaDegrees := -TurnSpeed
          else if BearingDeltaDegrees > TurnSpeed then BearingDeltaDegrees := TurnSpeed;
          State.BearingDegrees := State.BearingDegrees + BearingDeltaDegrees;
        end;
    end;
  end
  else if Exploding then DeletionPending := Image.Finished;
end;
{ @end $4F2304 }

{ @routine $4F24EC TabW07_UpdateVisuals }
procedure TabW07.UpdateVisuals;
var
  Entry: PabWorldImage;
  Index: Integer;
begin
  inherited UpdateVisuals;
  if not Exploding and (DistanceTravelled > TrailDistance) then
  begin
    TrailDistance := 0;
    Entry := nil;
    for Index := 0 to TrailImages.Count - 1 do
    begin
      Entry := TrailImages[Index];
      if Entry.Finished then Break;
      Entry := nil;
    end;
    if Entry = nil then
    begin
      Entry := ab_WorldImage_Create(GetWorldPosition, 'GAI,Bm.AB.w07a_f', 'GAI,Bm.AB.w07a_s', False);
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
      TrailImages.Add(Entry);
    end
    else
    begin
      ab_WorldImage_Set(Entry, GetWorldPosition, 'GAI,Bm.AB.w07a_f', 'GAI,Bm.AB.w07a_s');
      ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
      ab_WorldImage_SetLooping(Entry, False);
    end;
  end;
end;
{ @end $4F24EC }

end.

unit ab_W11;
// Unit bracket (inferred): CODE 0x004F3A08..0x004F40AF; inclusive evidence, not full bounds.

interface

uses Classes, EC_Struct, GI_Tail, ab_Global, ab_Object, ab_WorldImage;

type
  TabW11 = class(TabObject) // @size $C4
  public
    Damage: Integer; // @offset $90
    Image: PabWorldImage; // @offset $94
    Exploding: Boolean; // @offset $98
    LastTrailPosition: TVector3D; // @offset $A0
    ExpireTick: Integer; // @offset $B8
    TurnSpeed: Single; // @offset $BC
    TrailImages: TList; // @offset $C0
    destructor Destroy; override; // @addr $4F3AF8
    procedure Launch(Owner: TabObject; Amount: Integer; Offset: Single); // @addr $4F3B78
    procedure Advance; override; // @addr $4F3CE8
    procedure UpdateVisuals; override; // @addr $4F3EA0
    constructor Create; // @addr $4F3A70
  end;

implementation

// @unit-initialization $4F40A8
// @unit-finalization $4F4078

uses ab_Ship, GlobalsV;

{ @routine $4F3A70 TabW11_Create }
constructor TabW11.Create;
begin
  inherited Create;
  MaxSpeed := 40;
  TurnSpeed := 0.2;
  Mass := 1;
  Thrust := 0.8;
  CollisionRadius := 5;
  Collidable := False;
  TrailImages := TList.Create;
end;
{ @end $4F3A70 }

{ @routine $4F3AF8 TabW11_Destroy }
destructor TabW11.Destroy;
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
{ @end $4F3AF8 }

{ @routine $4F3B78 TabW11_Launch }
procedure TabW11.Launch(Owner: TabObject; Amount: Integer; Offset: Single);
var
  Heading, HeadingDelta: Double;
begin
  SourceObject := Owner;
  Damage := Amount;
  State := Owner.State;
  LastTrailPosition := GetWorldPosition;
  Velocity := Owner.Velocity;
  ExpireTick := ArcadeTickCount + 70;
  if Offset <> 0 then
  begin
    Heading := WrapHeadingDegrees(State.BearingDegrees + 90);
    HeadingDelta := HeadingDifferenceDegrees(Heading, State.BearingDegrees);
    AdvanceSphericalBearingState(State.LongitudeDegrees, State.PolarAngleDegrees, Heading, SphereRadius, Offset);
    State.BearingDegrees := WrapHeadingDegrees(Heading + HeadingDelta);
  end;
  Image := ab_WorldImage_Create(MakeVector3D(0, 0, 0), 'GAI,Bm.AB.w11_f', 'GAI,Bm.AB.w11_s', False);
  ab_WorldImage_SetDepth(Image, HitFrontDepth, HitBackDepth);
end;
{ @end $4F3B78 }

{ @routine $4F3CE8 TabW11_Advance }
procedure TabW11.Advance;
var
  Collision: TabObject;
  Enemy: TabShip;
begin
  inherited Advance;
  if not Exploding then ab_WorldImage_SetPosition(Image, GetWorldPosition);
  Collision := nil;
  if not Exploding then
  begin
    Collision := FindCollision;
    if Collision = SourceObject then Collision := nil;
  end;
  if ((ArcadeTickCount > ExpireTick) or (Collision <> nil)) and not Exploding then
  begin
    if Collision <> nil then Collision.ApplyDamage(Damage, SourceObject, False);
    Exploding := True;
    ab_WorldImage_Set(Image, GetWorldPosition, 'GAI,Bm.AB.w11b_f', 'GAI,Bm.AB.w11b_s');
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
{ @end $4F3CE8 }

{ @routine $4F3EA0 TabW11_UpdateVisuals }
procedure TabW11.UpdateVisuals;
var
  Entry: PabWorldImage;
  Index, Sample: Integer;
  Position, TrailPosition, Delta: TVector3D;
begin
  inherited UpdateVisuals;
  if not Exploding then
  begin
    Position := GetWorldPosition;
    Delta.X := -(LastTrailPosition.X - Position.X) / 4;
    Delta.Y := -(LastTrailPosition.Y - Position.Y) / 4;
    Delta.Z := -(LastTrailPosition.Z - Position.Z) / 4;
    for Sample := 0 to 3 do
    begin
      Entry := nil;
      for Index := 0 to TrailImages.Count - 1 do
      begin
        Entry := TrailImages[Index];
        if Entry.Finished then Break;
        Entry := nil;
      end;
      TrailPosition := MakeVector3D(Sample * Delta.X + Position.X, Sample * Delta.Y + Position.Y, Sample * Delta.Z + Position.Z);
      if Entry = nil then
      begin
        Entry := ab_WorldImage_Create(TrailPosition, 'GAI,Bm.AB.w11a_f', 'GAI,Bm.AB.w11a_s', False);
        ab_WorldImage_SetLooping(Entry, False);
        ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
        TrailImages.Add(Entry);
      end
      else
      begin
        ab_WorldImage_Set(Entry, TrailPosition, 'GAI,Bm.AB.w11a_f', 'GAI,Bm.AB.w11a_s');
        ab_WorldImage_SetDepth(Entry, HitFrontDepth, HitBackDepth);
        ab_WorldImage_SetLooping(Entry, False);
      end;
    end;
    LastTrailPosition := Position;
  end;
end;
{ @end $4F3EA0 }

end.

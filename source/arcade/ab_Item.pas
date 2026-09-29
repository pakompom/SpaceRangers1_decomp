unit ab_Item;
// Unit bracket (inferred): CODE 0x005095C4..0x0050A17B; inclusive evidence, not full bounds.
// TabItem VMT and helpers: $5573B4..$547240; original unit boundary unresolved.

interface

uses aItem, ab_Object, ab_Zone, SE_Space, SE_Container;

type
  TabItem = class(TabObject) // @size $A4
  public
    Item: TItem; // @offset $90  Campaign equipment; nil for arena bonuses.
    BonusKind: Integer; // @offset $94  -1 for equipment; otherwise index into the eight ship bonus timers.
    HiddenBonus: Boolean; // @offset $98  Uses the unknown-bonus image.
    Visual: TContainerSE; // @offset $9C
    SpawnZone: PabZone; // @offset $A0
    constructor Create; // @addr $50962C
    destructor Destroy; override; // @addr $5096B0
    procedure SetBonus(Kind: Integer; Hidden: Boolean; Zone: PabZone); // @addr $50975C
    procedure AttachVisual; // @addr $5098A0
    procedure DetachVisual; // @addr $5098E8
    procedure UpdateState; override; // @addr $509918
    procedure Advance; override; // @addr $509920
    procedure UpdateVisuals; override; // @addr $509928
    procedure SetItem(Value: TItem); // @addr $509748
  end;

procedure ab_Item_Update; // @addr $509A44
procedure ab_Item_Drop(Origin: TabObject; Item: TItem; MinDistance, MaxDistance: Integer); // @addr $509E08
function ab_Item_FindNearestBonus(Origin: PabZone): TabItem; // @addr $509EFC
function ab_Item_FindBonusRoute(Origin: PabZone; var Zone: PabZone): TabItem; // @addr $509FA4
function ab_Item_FindRepairRoute(Origin: PabZone; var Zone: PabZone): TabItem; // @addr $50A08C

implementation

// @unit-initialization $50A174
// @unit-finalization $50A144

uses Windows, Classes, SysUtils, EC_Struct, GI_Tail, ab_Global, SE_Process, ab_MainForm, ab_ShipAI, aMyFunction, ab_Ship, GR_Main, GR_Sound, Globals, GlobalsV;

{ @routine $50962C TabItem_Create }
constructor TabItem.Create;
begin
  inherited Create;
  BonusKind := -1;
  HiddenBonus := False;
  WallCollisionEnabled := False;
  MaxSpeed := 0;
  SpeedScale := 0;
  Mass := 10;
  State.PolarAngleDegrees := 0;
  State.BearingDegrees := 0;
  CollisionRadius := 0;
  Collidable := False;
end;
{ @end $50962C }

{ @routine $5096B0 TabItem_Destroy }
destructor TabItem.Destroy;
var
  Obj: TabObject;
  Ship: TabShipAI;
begin
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if Obj is TabShipAI then
    begin
      Ship := Obj as TabShipAI;
      if Ship.TargetBonus = Self then Ship.TargetBonus := nil;
    end;
    Obj := Obj.Next;
  end;
  if Item <> nil then
  begin
    Item.Free;
    Item := nil;
  end;
  if Visual <> nil then
  begin
    Visual.Free;
    Visual := nil;
  end;
  inherited Destroy;
end;
{ @end $5096B0 }

{ @routine $509748 TabItem_SetItem }
procedure TabItem.SetItem(Value: TItem);
begin
  BonusKind := -1;
  Item := Value;
end;
{ @end $509748 }

{ @routine $50975C TabItem_SetBonus }
procedure TabItem.SetBonus(Kind: Integer; Hidden: Boolean; Zone: PabZone);
begin
  BonusKind := Kind;
  HiddenBonus := Hidden;
  SpawnZone := Zone;
  if HiddenBonus then Visual := CreateSpaceObjectByName('Container', 'ItemAB.Unknown', Classes.Point(0, 0)) as TContainerSE
  else Visual := CreateSpaceObjectByName('Container', 'ItemAB.' + IntToStr(Kind), Classes.Point(0, 0)) as TContainerSE;
end;
{ @end $50975C }

{ @routine $5098A0 TabItem_AttachVisual }
procedure TabItem.AttachVisual;
begin
  if Item <> nil then
  begin
    Item.GetGraphObject.AttachToSpace(ArcadeSpaceProcess.Space);
    Exit;
  end;
  if Visual <> nil then Visual.AttachToSpace(ArcadeSpaceProcess.Space);
end;
{ @end $5098A0 }

{ @routine $5098E8 TabItem_DetachVisual }
procedure TabItem.DetachVisual;
begin
  if Item <> nil then
  begin
    Item.GetGraphObject.DetachFromSpace;
    Exit;
  end;
  if Visual <> nil then Visual.DetachFromSpace;
end;
{ @end $5098E8 }

{ @routine $509918 TabItem_UpdateState }
procedure TabItem.UpdateState;
begin
  inherited UpdateState;
end;
{ @end $509918 }

{ @routine $509920 TabItem_Advance }
procedure TabItem.Advance;
begin
  inherited Advance;
end;
{ @end $509920 }

{ @routine $509928 TabItem_UpdateVisuals }
procedure TabItem.UpdateVisuals;
var
  Position: TVector3D;
begin
  inherited UpdateVisuals;
  Position := GetWorldPosition;
  Position := ProjectPointByMatrix(SphereProjectionMatrix, Position);
  if Item <> nil then
  begin
    Item.GetGraphObject.SetPosition(MakePointF(Position.X, Position.Y));
    if not IsDepthBeforeSphereHorizon(Position.Z) then DetachVisual
    else
    begin
      AttachVisual;
      Item.GetGraphObject.SetDepth(ItemFrontDepth);
    end;
  end
  else if Visual <> nil then
  begin
    Visual.SetPosition(MakePointF(Position.X, Position.Y));
    if not IsDepthBeforeSphereHorizon(Position.Z) then DetachVisual
    else
    begin
      AttachVisual;
      Visual.SetDepth(ItemFrontDepth);
    end;
  end;
end;
{ @end $509928 }

{ @routine $509A44 ab_Item_Update }
procedure ab_Item_Update;
var
  Zone: PabZone;
  Bonus: TabItem;
  Index, Count: Integer;
  Distance: Single;
  NextObj, Obj, Ship: TabObject;
  Kinds: array[0..7] of Integer;
begin
  if PlayerArcadeShip <> nil then
    if PlayerArcadeShip.Enemies.Count > 0 then
    begin
      Zone := FirstZone;
      while Zone <> nil do
      begin
        if ((Zone.BonusFlags and ArcadeBonusKindMask) <> 0) and (Zone.NextBonusTick >= 0) and (Zone.NextBonusTick <= ArcadeTickCount) then
        begin
          Zone.NextBonusTick := -1;
          Count := 0;
          for Index := Low(Kinds) to High(Kinds) do
            if (Zone.BonusFlags and (1 shl Index)) <> 0 then
            begin
              Kinds[Count] := Index;
              Inc(Count);
            end;
          Bonus := TabItem.Create;
          Bonus.SetBonus(Kinds[RandomIntRange(0, Count - 1)], (Zone.BonusFlags and ArcadeHiddenBonusFlag) <> 0, Zone);
          Bonus.State.LongitudeDegrees := Zone.Longitude;
          Bonus.State.PolarAngleDegrees := Zone.PolarAngle;
          Bonus.State.BearingDegrees := RandomIntRange(0, 359);
          Distance := 0;
          AdvanceSphericalBearingState(Bonus.State.LongitudeDegrees, Bonus.State.PolarAngleDegrees,
            Bonus.State.BearingDegrees, SphereRadius, Distance);
          Bonus.AttachVisual;
          ab_Object_Add(Bonus);
        end;
        Zone := Zone.Next;
      end;
    end;
  NextObj := FirstArcadeObject;
  while NextObj <> nil do
  begin
    Obj := NextObj;
    NextObj := NextObj.Next;
    if Obj is TabItem then
    begin
      Bonus := TabItem(Obj);
      if Bonus.BonusKind >= 0 then
      begin
        Ship := FirstArcadeObject;
        while Ship <> nil do
        begin
          if (Ship is TabShip) and (Ship.DistanceTo(Bonus) < 60) then
          begin
            Bonus.Visual.DetachFromSpace;
            Bonus.SpawnZone.NextBonusTick := ArcadeTickCount + 20 * RandomIntRange(
              BonusRespawnSeconds[Bonus.SpawnZone.BonusRespawnClass * 2], BonusRespawnSeconds[Bonus.SpawnZone.BonusRespawnClass * 2 + 1]);
            if (Bonus.BonusKind = abkInvisibility) and (TabShip(Ship).BonusTicks[Bonus.BonusKind] <= 0) then TabShip(Ship).RevealTicks := 0;
            TabShip(Ship).BonusTicks[Bonus.BonusKind] := 20 * BonusDurationSeconds[Bonus.BonusKind];
            if PlayerArcadeShip = TabShip(Ship) then SoundManager.PlaySound(ArcadeItemSounds[Bonus.BonusKind]);
            ab_Object_Delete(Bonus);
            Break;
          end;
          Ship := Ship.Next;
        end;
      end;
    end;
  end;
  if IsVirtualKeyDown(VK_MENU) and (PlayerArcadeShip <> nil) and (PlayerArcadeShip.Health > 0) and
    (Player <> nil) and (Player.CargoHook <> nil) and not Player.CargoHook.BrokenFlag then
  begin
    NextObj := FirstArcadeObject;
    while NextObj <> nil do
    begin
      Obj := NextObj;
      NextObj := NextObj.Next;
      if Obj is TabItem then
        if ((Obj as TabItem).Item <> nil) and
          ((Obj as TabItem).Item.Weight <= Player.CargoFreeSpace) and
          (PlayerArcadeShip.DistanceTo(Obj) < CargoPickupDistance) and
          ((Player.CargoHook.PickupPower + 15 * (Ord(Player.HasActiveArtefact(t_ArtefactHook)))) >= (Obj as TabItem).Item.Weight) then
        begin
          ArcadeBattleScreen.PickUpItem(Obj as TabItem);
          ArcadeBattleScreen.CancelCargoPickup;
        end;
    end;
  end;
end;
{ @end $509A44 }

{ @routine $509E08 ab_Item_Drop }
procedure ab_Item_Drop(Origin: TabObject; Item: TItem; MinDistance, MaxDistance: Integer);
var
  Dropped: TabItem;
  Attempt: Integer;
  Distance, Bearing: Double;
  Obj: TabObject;
begin
  Dropped := TabItem.Create;
  Dropped.SetItem(Item);
  for Attempt := 0 to 10 do
  begin
    Distance := RandomIntRange(MinDistance, MaxDistance);
    Bearing := RandomIntRange(0, 359);
    Dropped.State := Origin.State;
    Dropped.State.BearingDegrees := Bearing;
    AdvanceSphericalBearingState(Dropped.State.LongitudeDegrees, Dropped.State.PolarAngleDegrees,
      Dropped.State.BearingDegrees, SphereRadius, Distance);
    Obj := FirstArcadeObject;
    while Obj <> nil do
    begin
      if (Obj is TabItem) and (Obj.DistanceTo(Dropped) < 20) then Break;
      Obj := Obj.Next;
    end;
    if Obj = nil then Break;
  end;
  ab_Object_Add(Dropped);
  Dropped.AttachVisual;
end;
{ @end $509E08 }

{ @routine $509EFC ab_Item_FindNearestBonus }
function ab_Item_FindNearestBonus(Origin: PabZone): TabItem;
var
  Obj: TabItem;
  Distance, BestDistance: Double;
begin
  Result := nil;
  BestDistance := 1E20;
  Obj := TabItem(FirstArcadeObject);
  while Obj <> nil do
  begin
    if TabObject(Obj) is TabItem then
      case Obj.BonusKind of
        abkRegeneration, abkSpeed, abkDamage..abkInvisibility:
          begin
            ComputeSphericalDistance(Distance, Origin.Longitude, Origin.PolarAngle,
              0, Obj.State.LongitudeDegrees, Obj.State.PolarAngleDegrees, SphereRadius);
            if Distance < BestDistance then
            begin
              BestDistance := Distance;
              Result := Obj;
            end;
          end;
      end;
    Obj := TabItem(Obj.Next);
  end;
end;
{ @end $509EFC }

{ @routine $509FA4 ab_Item_FindBonusRoute }
function ab_Item_FindBonusRoute(Origin: PabZone; var Zone: PabZone): TabItem;
var
  Obj: TabItem;
  Distance, BestDistance: Double;
  Route: PabZone;
begin
  Result := nil;
  Zone := nil;
  BestDistance := 1E20;
  Obj := TabItem(FirstArcadeObject);
  while Obj <> nil do
  begin
    if TabObject(Obj) is TabItem then
      case Obj.BonusKind of
        abkRegeneration, abkSpeed, abkDamage..abkInvisibility:
          begin
            ComputeSphericalDistance(Distance, Origin.Longitude, Origin.PolarAngle,
              0, Obj.State.LongitudeDegrees, Obj.State.PolarAngleDegrees, SphereRadius);
            if Distance < BestDistance then
            begin
              Route := ab_Zone_FindReachableRouteZone(Obj.SpawnZone);
              if Route <> nil then
                if RandomIntRange(0, 2) = 0 then
                begin
                  Zone := Route;
                  BestDistance := Distance;
                  Result := Obj;
                end;
            end;
          end;
      end;
    Obj := TabItem(Obj.Next);
  end;
end;
{ @end $509FA4 }

{ @routine $50A08C ab_Item_FindRepairRoute }
function ab_Item_FindRepairRoute(Origin: PabZone; var Zone: PabZone): TabItem;
var
  Obj: TabObject;
  Distance, BestDistance: Double;
  Route: PabZone;
begin
  Result := nil;
  Zone := nil;
  BestDistance := 1E20;
  Obj := FirstArcadeObject;
  while Obj <> nil do
  begin
    if (Obj is TabItem) and (TabItem(Obj).BonusKind in [abkRegeneration]) then
    begin
      ComputeSphericalDistance(Distance, Origin.Longitude, Origin.PolarAngle,
        0, Obj.State.LongitudeDegrees, Obj.State.PolarAngleDegrees, SphereRadius);
      if Distance < BestDistance then
      begin
        Route := ab_Zone_FindReachableRouteZone(TabItem(Obj).SpawnZone);
        if Route <> nil then
        begin
          Zone := Route;
          BestDistance := Distance;
          Result := TabItem(Obj);
        end;
      end;
    end;
    Obj := Obj.Next;
  end;
end;
{ @end $50A08C }

end.

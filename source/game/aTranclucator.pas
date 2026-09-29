unit aTranclucator;
// Unit bracket (inferred): CODE 0x004D799C..0x004D897B; inclusive evidence, not full bounds.

interface

uses EC_Buf, aGalaxy, aPlanet, aShip;

type
  TTranclucator = class(TShip) // @size $1B8
  public
    procedure UpgradeEquipmentAtLocation; override; // @addr $4D81EC Native empty override.
    procedure BuyInitialEquipment; override; // @addr $4D81E8 Native empty override.
    procedure InitializeForOwner(AOwnerShip: TShip; Owner: TOwnerId); // @addr $4D7AB4
    function CanFollowOwnerInCurrentStar: Boolean; // @addr $4D819C
    OwnerShip: TShip; // @offset $1B0
    FollowOwner: Boolean; // @offset $1B4 Cleared with OwnerShip by TShip.Destroy.

    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $4D7F74 @slot $0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $4D7FB4 @slot $4
    procedure ResolveLoadedReferences; override; // @addr $4D7FE0 @slot $8
    function GetName: WideString; override; // @addr $4D805C @slot $10
    function GetFullName(const Separator: WideString): WideString; override; // @addr $4D807C @slot $14
    function GetTypeNameKey: WideString; override; // @addr $4D8154 @slot $18
    function GetGreetingShipCategory: TGreetingShipCategory; override; // @addr $4D8188 @slot $1C
    function GetHomeStar: TStar; override; // @addr $4D8190 @slot $20
    function GetDominantCareer: TRangerCareer; override; // @addr $4D818C @slot $24 @note "Always rcWarrior."
    function GetStrengthScaledPirateStatus: TPercent; override; // @addr $4D8194 @slot $28
    function GetDesiredCargoFreeSpace: Integer; override; // @addr $4D8198 @slot $2C
    procedure RefuelAtLocation; override; // @addr $4D81D8 @slot $34
    procedure RepairBrokenEquipmentAtLocation; override; // @addr $4D81F0 @slot $38
    procedure BuildReachablePlanetQueue; override; // @addr $4D8320 @slot $3C
    function CanQueueReachablePlanet(Planet: TPlanet): Boolean; override; // @addr $4D8324 @slot $40
    procedure SelectEnemyShipInStar; override; // @addr $4D8690 @slot $44
    procedure EngageEnemyShip; override; // @addr $4D869C @slot $48
    function RelationToRanger(Ranger: TObject): Byte; override; // @addr $4D86E4 @slot $4C
    procedure ChangeRelationToRanger(Ranger: TObject; Amount: Integer); override; // @addr $4D86EC @slot $50
    procedure ReactToAttack(Attacker: TShip); override; // @addr $4D86F0 @slot $54
    function RelationToNonRanger(Ship: TShip): TNonRangerRelation; override; // @addr $4D86A0 @slot $58
    function RecomputeFearState: Boolean; override; // @addr $4D8700 @slot $5C
    function AcceptsRansomDemandFrom(Ship: TShip): Boolean; override; // @addr $4D8704 @slot $60
    function TrustsAttackRequester(Ship: TShip): Boolean; override; // @addr $4D8708 @slot $64
    function EvaluateAllyRelationAndStrength(Ship: TShip): Boolean; override; // @addr $4D8714 @slot $68
    procedure ProcessCombatDialogue; override; // @addr $4D8720 @slot $74
    procedure ReactToExtortionDemand(Ranger: TObject); override; // @addr $4D8724 @slot $78
    function BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean; override; // @addr $4D8728 @slot $7C
    function BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean; override; // @addr $4D8774 @slot $80
    function BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean; override; // @addr $4D87B8 @slot $84
    function BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean; override; // @addr $4D8804 @slot $88
    function AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $4D88BC @slot $8C
    function BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean; override; // @addr $4D8900 @slot $90
    procedure NextDay; override; // @addr $4D8014
    procedure UpdateFreeFlightOrder; // @addr $4D8240
    procedure AssignWeaponTargetsInStar; // @addr $4D8328
    destructor Destroy; override; // @addr $4D7A8C
  end;

implementation

// @unit-initialization $4D8974
// @unit-finalization $4D8944

uses SysUtils, GR_Main, aItem, Classes, EC_Struct, SE_Process, SE_Ship2, aMyFunction, aConst;

{ @routine $4D7A8C TTranclucator_Destroy }
destructor TTranclucator.Destroy;
begin
  inherited Destroy;
end;
{ @end $4D7A8C }

{ @routine $4D7AB4 TTranclucator_InitializeForOwner }
procedure TTranclucator.InitializeForOwner(AOwnerShip: TShip; Owner: TOwnerId);
var WeaponType: TItemType;
begin
  ShipType := t_Tranclucator;
  if AOwnerShip <> nil then
  begin
    OwnerShip := AOwnerShip;
    OwnerId := AOwnerShip.OwnerId;
    CurrentStar := AOwnerShip.CurrentStar;
    CurrentStar.Ships.Add(Self);
  end
  else
  begin
    OwnerShip := nil;
    OwnerId := Owner;
    CurrentStar := nil;
  end;
  HomePlanet := nil;
  CurrentPlanet := nil;
  Position := MakePointF(0, 0);
  MovementDirection := 0;
  Name := WideString(IntToStr(Int64(Id)));
  Graphic := CreateSpaceObjectByName('Ship2', 'Ship.Tranclucator', Classes.Point(0, 0)) as TShip2SE;
  Graphic.SetPosition(Position);
  Graphic.SetAngle(HeadingDegreesToByte(MovementDirection));
  Graphic.SetAlpha(255);
  CollisionRadius := 32;
  CreateAndEquipHull(True, Round(RemapClamped(Galaxy.TechLevel, 3, 8, 200, 400)), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 4, 8)), OwnerId).Cost := 500;
  CreateAndEquipFuelTanks(True, 1, 1, OwnerId).Cost := 25;
  CreateAndEquipEngine(True, Round(40 * ItemSizeFactors[5]), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 2, 6)), OwnerId).Cost := 250;
  WeaponType := TItemType(Ord(t_PhotonGun) + Round(RemapClamped(Galaxy.TechLevel, 4, 8, 0, 10)));
  CreateAndEquipWeapon(WeaponType, True, Round(WeaponInfo[WeaponType].Weight * ItemSizeFactors[5]), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 2, 6)), OwnerId).Cost := 250;
  CreateAndEquipWeapon(Succ(WeaponType), True, Round(WeaponInfo[Succ(WeaponType)].Weight * ItemSizeFactors[5]), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 1, 6)), OwnerId).Cost := 250;
  CreateAndEquipDefGenerator(True, Round(40 * ItemSizeFactors[5]), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 2, 7)), OwnerId).Cost := 250;
  CreateAndEquipRepairRobot(True, Round(40 * ItemSizeFactors[5]), Round(RemapClamped(Galaxy.TechLevel, 3, 8, 3, 6)), OwnerId).Cost := 250;
  if GetCargoFreeSpace < 0 then Inc(Hull.Weight, Abs(GetCargoFreeSpace));
  RefreshDerivedStats;
end;
{ @end $4D7AB4 }

{ @routine $4D7F74 TTranclucator_SaveToBuffer }
procedure TTranclucator.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  if OwnerShip = nil then Buffer.AddDword(0) else Buffer.AddDword(OwnerShip.Id);
  Buffer.AddBoolean(FollowOwner);
end;
{ @end $4D7F74 }

{ @routine $4D7FB4 TTranclucator_LoadFromBuffer }
procedure TTranclucator.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  OwnerShip := TShip(Buffer.GetUInt32);
  FollowOwner := Buffer.GetBoolean;
end;
{ @end $4D7FB4 }

{ @routine $4D7FE0 TTranclucator_ResolveLoadedReferences }
procedure TTranclucator.ResolveLoadedReferences;
begin
  inherited ResolveLoadedReferences;
  OwnerShip := Galaxy.IdToShip(Cardinal(OwnerShip), True) as TShip;
end;
{ @end $4D7FE0 }

{ @routine $4D8014 TTranclucator_NextDay }
procedure TTranclucator.NextDay;
begin
  inherited NextDay;
  if FollowOwner and (OwnerShip <> nil) then OrderFollowShip(OwnerShip, fmNear, False)
  else if not OrderAbsolute then UpdateFreeFlightOrder;
  AssignWeaponTargetsInStar;
end;
{ @end $4D8014 }

{ @routine $4D805C TTranclucator_GetName }
function TTranclucator.GetName: WideString;
begin
  Result := GetFullName(' ');
end;
{ @end $4D805C }

{ @routine $4D807C TTranclucator_GetFullName }
function TTranclucator.GetFullName(const Separator: WideString): WideString;
begin
  Result := LookupLocalizedTextByKey('Items.ArtefactTranclucator.Name') + '-' + WideString(IntToStr(Id));
end;
{ @end $4D807C }

{ @routine $4D8154 TTranclucator_GetTypeNameKey }
function TTranclucator.GetTypeNameKey: WideString;
begin
  Result := 'Tranclucator';
end;
{ @end $4D8154 }

{ @routine $4D8188 TTranclucator_GetGreetingShipCategory }
function TTranclucator.GetGreetingShipCategory: TGreetingShipCategory;
begin
  Result := gscTransport;
end;
{ @end $4D8188 }

{ @routine $4D818C TTranclucator_GetDominantCareer }
function TTranclucator.GetDominantCareer: TRangerCareer;
begin
  Result := rcWarrior;
end;
{ @end $4D818C }

{ @routine $4D8190 TTranclucator_GetHomeStar }
function TTranclucator.GetHomeStar: TStar;
begin
  Result := nil;
end;
{ @end $4D8190 }

{ @routine $4D8194 TTranclucator_GetStrengthScaledPirateStatus }
function TTranclucator.GetStrengthScaledPirateStatus: TPercent;
begin
  Result := 100;
end;
{ @end $4D8194 }

{ @routine $4D8198 TTranclucator_GetDesiredCargoFreeSpace }
function TTranclucator.GetDesiredCargoFreeSpace: Integer;
begin
  Result := 0;
end;
{ @end $4D8198 }

{ @routine $4D819C TTranclucator_CanFollowOwnerInCurrentStar }
function TTranclucator.CanFollowOwnerInCurrentStar: Boolean;
begin
  Result := FollowOwner and (OwnerShip <> nil) and
    (OwnerShip.CurrentStar = CurrentStar) and OwnerShip.InNormalSpace;
end;
{ @end $4D819C }

{ @routine $4D81D8 TTranclucator_RefuelAtLocation }
procedure TTranclucator.RefuelAtLocation;
begin
  FuelTanks.Fuel := FuelTanks.Capacity;
end;
{ @end $4D81D8 }

{ @routine $4D81E8 TTranclucator_BuyInitialEquipment }
procedure TTranclucator.BuyInitialEquipment;
begin
end;
{ @end $4D81E8 }

{ @routine $4D81EC TTranclucator_UpgradeEquipmentAtLocation }
procedure TTranclucator.UpgradeEquipmentAtLocation;
begin
end;
{ @end $4D81EC }

{ @routine $4D81F0 TTranclucator_RepairBrokenEquipmentAtLocation }
procedure TTranclucator.RepairBrokenEquipmentAtLocation;
var I: Integer;
    Equipment: TEquipment;
begin
  // Skips inventory slot zero.
  for I := 1 to Inventory.Count - 1 do
  begin
    Equipment := TEquipment(Inventory[I]);
    if Equipment.BrokenFlag or (Equipment.ConditionPercent < 10) then Equipment.Repair;
  end;
end;
{ @end $4D81F0 }

{ @routine $4D8240 TTranclucator_UpdateFreeFlightOrder }
procedure TTranclucator.UpdateFreeFlightOrder;
begin
  if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
    OrderFollowShip(EnemyShip, fmMinWeaponRange, False)
  else if (OwnerShip <> nil) and (OwnerShip.CurrentStar = CurrentStar) and OwnerShip.InNormalSpace then
  begin
    with OwnerShip do
      if (Order = soFollowShip) and (EnemyShip = OrderTarget) and (EnemyShip <> Self) then
        Self.OrderFollowShip(EnemyShip, fmMinWeaponRange, False)
      else Self.OrderFollowShip(OwnerShip, fmNear, False);
  end
  else if (OwnerShip <> nil) and (OwnerShip.CurrentStar = CurrentStar) and (OwnerShip.CurrentPlanet <> nil) then
    OrderMove(OwnerShip.CurrentPlanet.GetPosition, False)
  else OrderRandomFreeFlightMove;
end;
{ @end $4D8240 }

{ @routine $4D8320 TTranclucator_BuildReachablePlanetQueue }
procedure TTranclucator.BuildReachablePlanetQueue;
begin

end;
{ @end $4D8320 }

{ @routine $4D8324 TTranclucator_CanQueueReachablePlanet }
function TTranclucator.CanQueueReachablePlanet(Planet: TPlanet): Boolean;
begin
  Result := False;
end;
{ @end $4D8324 }

{ @routine $4D8328 TTranclucator_AssignWeaponTargetsInStar }
procedure TTranclucator.AssignWeaponTargetsInStar;
var I, J, AssignedCount: Integer;
    Ship: TShip;
    Weapon: TWeapon;
    Distance: Double;
begin
  for I := 1 to WeaponCount do
  begin
    Weapon := Weapons[I - 1];
    Weapon.Target := nil;
  end;
  AssignedCount := 0;
  if OwnerShip <> nil then
  begin
    if (OwnerShip <> nil) and (OwnerShip.EnemyShip <> nil) and
      (OwnerShip.EnemyShip <> Self) and
      (OwnerShip.EnemyShip.CurrentStar = CurrentStar) and OwnerShip.EnemyShip.InNormalSpace then
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        if (Weapon.Target = nil) and not Weapon.BrokenFlag and
          (PointDistanceSquared(Position, OwnerShip.EnemyShip.Position) <= Weapon.Range * Weapon.Range) then
        begin
          Weapon.Target := OwnerShip.EnemyShip;
          Inc(AssignedCount);
          if WeaponCount = AssignedCount then Exit;
        end;
      end;
    if (EnemyShip <> nil) and (EnemyShip.CurrentStar = CurrentStar) and EnemyShip.InNormalSpace then
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        if (Weapon.Target = nil) and not Weapon.BrokenFlag and
          (PointDistanceSquared(Position, EnemyShip.Position) <= Weapon.Range * Weapon.Range) then
        begin
          Weapon.Target := EnemyShip;
          Inc(AssignedCount);
          if WeaponCount = AssignedCount then Exit;
        end;
      end;
    if CurrentStar.Battle then
      for I := 0 to CurrentStar.Ships.Count - 1 do
      begin
        Ship := TShip(CurrentStar.Ships[I]);
        if (Ship.OwnerId = oiKling) and Ship.InNormalSpace then
        begin
          Distance := PointDistance(Position, Ship.Position);
          for J := 1 to WeaponCount do
          begin
            Weapon := Weapons[J - 1];
            if (Weapon.Target = nil) and not Weapon.BrokenFlag and (Weapon.Range >= Distance) then
            begin
              Weapon.Target := Ship;
              Inc(AssignedCount);
              if WeaponCount = AssignedCount then Exit;
            end;
          end;
        end;
      end;
    for I := 0 to CurrentStar.Ships.Count - 1 do
    begin
      Ship := TShip(CurrentStar.Ships[I]);
      if not (Ship.InNormalSpace and (Ship <> Self) and (Ship.EnemyShip <> OwnerShip) and
        ((RelationToNonRanger(Ship) < 10) or (Ship = EnemyShip) or (Ship.EnemyShip = Self))) then Continue;
      for J := 1 to WeaponCount do
      begin
        Weapon := Weapons[J - 1];
        // Unlike the earlier passes, this can overwrite a target and count it again.
        if not Weapon.BrokenFlag and
          (PointDistanceSquared(Position, Ship.Position) <= Weapon.Range * Weapon.Range) then
        begin
          Weapon.Target := Ship;
          Inc(AssignedCount);
          if WeaponCount = AssignedCount then Exit;
        end;
      end;
    end;
  end;
end;
{ @end $4D8328 }

{ @routine $4D8690 TTranclucator_SelectEnemyShipInStar }
procedure TTranclucator.SelectEnemyShipInStar;
begin
  EnemyShip := nil;
end;
{ @end $4D8690 }

{ @routine $4D869C TTranclucator_EngageEnemyShip }
procedure TTranclucator.EngageEnemyShip;
begin

end;
{ @end $4D869C }

{ @routine $4D86A0 TTranclucator_RelationToNonRanger }
function TTranclucator.RelationToNonRanger(Ship: TShip): TNonRangerRelation;
begin
  if (Ship = EnemyShip) or (Self = Ship.EnemyShip) then Result := 0
  else if OwnerShip <> nil then Result := OwnerShip.RelationToNonRanger(Ship)
  else case Ship.ShipType of
    t_Ranger..t_Warrior, t_RangerCenter..t_PirateBase: Result := 100;
    t_Kling, t_Tranclucator: Result := 0;
  else Result := 50;
  end;
end;
{ @end $4D86A0 }

{ @routine $4D86E4 TTranclucator_RelationToRanger }
function TTranclucator.RelationToRanger(Ranger: TObject): Byte;
begin
  Result := RelationToNonRanger(TShip(Ranger));
end;
{ @end $4D86E4 }

{ @routine $4D86EC TTranclucator_ChangeRelationToRanger }
procedure TTranclucator.ChangeRelationToRanger(Ranger: TObject; Amount: Integer);
begin

end;
{ @end $4D86EC }

{ @routine $4D86F0 TTranclucator_ReactToAttack }
procedure TTranclucator.ReactToAttack(Attacker: TShip);
begin
  if OwnerShip <> Attacker then EnemyShip := Attacker;
end;
{ @end $4D86F0 }

{ @routine $4D8700 TTranclucator_RecomputeFearState }
function TTranclucator.RecomputeFearState: Boolean;
begin
  Result := False;
end;
{ @end $4D8700 }

{ @routine $4D8704 TTranclucator_AcceptsRansomDemandFrom }
function TTranclucator.AcceptsRansomDemandFrom(Ship: TShip): Boolean;
begin
  Result := False;
end;
{ @end $4D8704 }

{ @routine $4D8708 TTranclucator_TrustsAttackRequester }
function TTranclucator.TrustsAttackRequester(Ship: TShip): Boolean;
begin
  Result := Ship = OwnerShip;
end;
{ @end $4D8708 }

{ @routine $4D8714 TTranclucator_EvaluateAllyRelationAndStrength }
function TTranclucator.EvaluateAllyRelationAndStrength(Ship: TShip): Boolean;
begin
  Result := Ship = OwnerShip;
end;
{ @end $4D8714 }

{ @routine $4D8720 TTranclucator_ProcessCombatDialogue }
procedure TTranclucator.ProcessCombatDialogue;
begin

end;
{ @end $4D8720 }

{ @routine $4D8724 TTranclucator_ReactToExtortionDemand }
procedure TTranclucator.ReactToExtortionDemand(Ranger: TObject);
begin

end;
{ @end $4D8724 }

{ @routine $4D8728 TTranclucator_BuildMoneyExtortionResponse }
function TTranclucator.BuildMoneyExtortionResponse(OtherShip: TShip; var Response: WideString; DemandedAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $4D8728 }

{ @routine $4D8774 TTranclucator_BuildCargoExtortionResponse }
function TTranclucator.BuildCargoExtortionResponse(OtherShip: TShip; var Response: WideString): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $4D8774 }

{ @routine $4D87B8 TTranclucator_BuildTrucePaymentResponse }
function TTranclucator.BuildTrucePaymentResponse(OtherShip: TShip; var Response: WideString; OfferedAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Talk not supporting';
end;
{ @end $4D87B8 }

{ @routine $4D8804 TTranclucator_BuildAttackRequestResponse }
function TTranclucator.BuildAttackRequestResponse(Requester: TShip; var Response: WideString; Target: TShip): Boolean;
begin
  Result := True;
  Response := LookupVisibleTalkText('Talk.Tranclucator.Attack.Ok');
  SetJointAttackTarget(Requester, Target);
  FollowOwner := False;
end;
{ @end $4D8804 }

{ @routine $4D88BC TTranclucator_AcceptPartnershipOffer }
function TTranclucator.AcceptPartnershipOffer(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $4D88BC }

{ @routine $4D8900 TTranclucator_BuildPartnershipOfferResponse }
function TTranclucator.BuildPartnershipOfferResponse(OtherShip: TShip; var Response: WideString; PaymentAmount: Integer): Boolean;
begin
  Result := False;
  Response := 'Not supporting';
end;
{ @end $4D8900 }

end.

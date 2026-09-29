unit ab_Space;
// Unit bracket (inferred): CODE 0x0050BAD8..0x0050EA2B; inclusive evidence, not full bounds.

interface

uses Classes, EC_Struct, GI_GAI, Types;

type
  TabSpace = class(TObjectEx) // @size $6C
  public
    Prev: TabSpace; // @offset $04
    Next: TabSpace; // @offset $08
    GridPosition: TPoint; // @offset $0C
    MapPosition: TPoint; // @offset $14
    ArenaSize: Single; // @offset $1C Displayed by TfAB.ShowSpaceInfo.
    IncomingCount: Integer; // @offset $20
    OutgoingCount: Integer; // @offset $24
    Color28: Cardinal; // @offset $28 Map rendering color.
    Color2C: Cardinal; // @offset $2C
    Color30: Cardinal; // @offset $30
    Color34: Cardinal; // @offset $34
    AppearanceIndex: Integer; // @offset $38 Six difficulty/visual variants, each with six palette entries.
    MapPath: WideString; // @offset $3C Arena resource path.
    BoundaryKind: Integer; // @offset $40 1 for the synthetic start/end nodes.
    PortalSlotCount: Integer; // @offset $44 Used by exit-index shuffling.
    Danger: Double; // @offset $48 Local encounter difficulty, used for danger text, visuals and rewards.
    ApproachDanger: Double; // @offset $50 Minimum accumulated predecessor danger, followed by graph pruning.
    RouteCost: Double; // @offset $58 Temporary reverse-search cost for the selected route.
    Objects: TList; // @offset $60 Owned objects associated with this space.
    ImageActive: Boolean; // @offset $64
    Image: TgaiGI; // @offset $68
    constructor Create; // @addr $50BB40
    destructor Destroy; override; // @addr $50BBB4
    procedure UpdateVisuals; // @addr $50BBFC Empty native update hook.
    procedure Update; // @addr $50BEB0
    procedure ClearVisuals; // @addr $50BBF4
    procedure ClearImage; // @addr $50BE94
    procedure ClearObjects; // @addr $50BEB8
    procedure UpdateApproachDanger; // @addr $50DD58
    procedure PruneApproachDanger; // @addr $50DD90 Native instance receiver is unused; visits the complete graph.
    function GetDangerText: WideString; // @addr $50DE20
    procedure CreateImage; // @addr $50BC00
    procedure PopulateFinalEncounter; // @addr $50D3E0
    procedure PopulateObjects; // @addr $50BEEC
    procedure PopulateHoleEncounter; // @addr $50CA5C
    procedure RecountLinks; // @addr $50E114
  end;

  PabSpaceLink = ^TabSpaceLink;
  TabSpaceLink = record // @size $6C Allocation size at $55E2E8.
    Prev: PabSpaceLink; // @offset $00
    Next: PabSpaceLink; // @offset $04
    First: TabSpace; // @offset $08
    Last: TabSpace; // @offset $0C
    ExitIndex: Integer; // @offset $10
    Points: array[0..10] of TPoint; // @offset $14 Arrow outline and halo geometry.
  end;

procedure ab_Space_UpdateApproachDanger; // @addr $50E144
procedure ab_Space_CreateImages; // @addr $50E06C
procedure ab_Space_ClearImages; // @addr $50E088
procedure ab_SpaceLink_Invalidate; // @addr $50E274
procedure ab_SpaceLink_BuildGeometry; // @addr $50E350
procedure ab_SpaceLink_Draw; // @addr $50E7CC
procedure ab_SpaceLink_ClearImages; // @addr $50E7B8
procedure ab_Space_Clear; // @addr $50DF88
function ab_Space_Add: TabSpace; // @addr $50DFC0
procedure ab_Space_Delete(Space: TabSpace); // @addr $50E000
procedure ab_Space_RecountLinks; // @addr $50E0F8
procedure ab_SpaceLink_Clear; // @addr $50E178
function ab_SpaceLink_Add: PabSpaceLink; // @addr $50E190
procedure ab_SpaceLink_Delete(Link: PabSpaceLink); // @addr $50E1D0
procedure ab_SpaceLink_Connect(First, Last: TabSpace); // @addr $50E210

var
  FirstArcadeSpace: TabSpace = nil; // @addr $6186F8
  LastArcadeSpace: TabSpace = nil; // @addr $6186FC
  CurrentArcadeSpace: TabSpace = nil; // @addr $618700
  NextArcadeSpace: TabSpace = nil; // @addr $618704 Destination selected before entering a space.
  StartArcadeSpace: TabSpace = nil; // @addr $618708
  EndArcadeSpace: TabSpace = nil; // @addr $61870C
  HoveredArcadeSpace: TabSpace = nil; // @addr $618710
  FirstArcadeSpaceLink: PabSpaceLink = nil; // @addr $618714
  LastArcadeSpaceLink: PabSpaceLink = nil; // @addr $618718

procedure ab_Space_Update; // @addr $50E0A8

var

function ab_Space_Find(GridPosition: TPoint): TabSpace; // @addr $50E0C4

function ab_SpaceLink_Find(First, Last: TabSpace): PabSpaceLink; // @addr $50E224

function ab_SpaceLink_FindExit(Space: TabSpace; ExitIndex: Integer): PabSpaceLink; // @addr $50E250

var
  ArcadeFinalEncounter: Boolean; // @addr $61CF44 Final boss is present in the current arcade space.

implementation

// @unit-initialization $50EA24
// @unit-finalization $50E9F4

uses aConst, SysUtils, Math, EC_Mem, GR_Main, Globals, GI_Tail, ab_Global, aMyFunction, aItem, aPlayer, aGalaxy, ab_W, ab_Ship, ab_ShipAI, ab_Item, ab_MainForm;

{ @routine $50BB40 TabSpace_Create }
constructor TabSpace.Create;
begin
  inherited Create;
  Color28 := CurrentPixelFormat.PackRgbBytes(255, 255, 0);
  Color2C := CurrentPixelFormat.PackRgbBytes(155, 155, 0);
  Objects := TList.Create;
  ImageActive := False;
end;
{ @end $50BB40 }

{ @routine $50BBB4 TabSpace_Destroy }
destructor TabSpace.Destroy;
begin
  ClearVisuals;
  ClearObjects;
  Objects.Free;
  Objects := nil;
  inherited Destroy;
end;
{ @end $50BBB4 }

{ @routine $50BBF4 TabSpace_ClearVisuals }
procedure TabSpace.ClearVisuals;
begin
  ClearImage;
end;
{ @end $50BBF4 }

{ @routine $50BBFC TabSpace_UpdateVisuals }
procedure TabSpace.UpdateVisuals;
begin
end;
{ @end $50BBFC }

{ @routine $50BC00 TabSpace_CreateImage }
procedure TabSpace.CreateImage;
begin
  ImageActive := True;
  if (Image = nil) and (Self <> StartArcadeSpace) and (Self <> EndArcadeSpace) then
  begin
    Image := TgaiGI.Create(ArcadeBattleScreen.WorldPanel);
    Image.SetDepth(30);
    if Danger <= 0 then
      Image.SetImagePath('Bm.ABClot.' + GiResourceSuffix + '0_' + IntToStr(RandomIntRange(0, 1)))
    else if Danger + ApproachDanger < ArcadeHighDangerThreshold then
      Image.SetImagePath('Bm.ABClot.' + GiResourceSuffix + '1_' + IntToStr(RandomIntRange(0, 3)))
    else
      Image.SetImagePath('Bm.ABClot.' + GiResourceSuffix + '2_' + IntToStr(RandomIntRange(0, 1)));
    Image.SetSize(Image.GetContentSize);
    Image.SetOrigin(HalfPoint(Image.ClientSize));
    Image.SequenceIndex := 0;
    Image.UpdateAutoGeometry;
    Image.SetSequenceFrame(RandomIntRange(0, Image.SequenceFrameCount - 1));
    Image.SetActive(True);
    Image.RestartPlayback;
  end;
end;
{ @end $50BC00 }

{ @routine $50BE94 TabSpace_ClearImage }
procedure TabSpace.ClearImage;
begin
  if Image <> nil then
  begin
    Image.Free;
    Image := nil;
  end;
  ImageActive := False;
end;
{ @end $50BE94 }

{ @routine $50BEB0 TabSpace_Update }
procedure TabSpace.Update;
begin
  UpdateVisuals;
end;
{ @end $50BEB0 }

{ @routine $50BEB8 TabSpace_ClearObjects }
procedure TabSpace.ClearObjects;
var
  Index: Integer;
begin
  for Index := 0 to Objects.Count - 1 do TObject(Objects[Index]).Free;
  Objects.Clear;
end;
{ @end $50BEB8 }

{ @routine $50BEEC TabSpace_PopulateObjects }
procedure TabSpace.PopulateObjects;
var
  Ship: TabShipAI;
  Index, Count, MineralBudget, Minimum, Maximum, Kind, VisualIndex, Hitpoints: Integer;
  Item: TItem;
  ArcadeItem: TabItem;
  Scale: Single;
begin
  ClearObjects;
  if Player = nil then Exit;
  case Integer(Round(Danger)) of
    0: if ArcadeBattleScreen.RandomRange(0, 100) > 90 then Count := ArcadeBattleScreen.RandomRange(1, 2) else Count := 0;
    1..20: if ArcadeBattleScreen.RandomRange(0, 100) > 80 then Count := ArcadeBattleScreen.RandomRange(2, 3) else Count := 0;
    21..30: if ArcadeBattleScreen.RandomRange(0, 100) > 50 then Count := ArcadeBattleScreen.RandomRange(2, 3) else Count := 0;
    31..60: if ArcadeBattleScreen.RandomRange(0, 100) > 10 then Count := ArcadeBattleScreen.RandomRange(2, 4) else Count := 0;
    61..90: if ArcadeBattleScreen.RandomRange(0, 100) > 5 then Count := ArcadeBattleScreen.RandomRange(2, 5) else Count := 0;
    91..100: Count := ArcadeBattleScreen.RandomRange(4, 5);
  else Count := ArcadeBattleScreen.RandomRange(4, 5);
  end;
  if Count > 0 then
    if ArcadeBattleScreen.RandomRange(0, 100) < RemapClamped(Player.HyperspaceKillCount, 20, 300, 0, 90) then Count := 0;
  if Player.HyperspaceKillCount < 4 / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor then Count := Min(Count, 2)
  else if Player.HyperspaceKillCount < 10 / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor then Count := Min(Count, 3);
  if Player.HyperspaceKillCount = 0 then Count := 1;
  Minimum := Round(RemapClamped(Galaxy.TechLevel, 3, 8, 0, 6));
  Maximum := Round(RemapClamped(Galaxy.TechLevel, 3, 8, 5, 11));
  VisualIndex := ArcadeBattleScreen.RandomRange(1, 5);
  for Index := 0 to Count - 1 do
  begin
    Ship := TabShipAI.Create;
    case Player.HyperspaceKillCount of
      0: Scale := 0.2;
      1..4: Scale := RemapClamped(Player.HyperspaceKillCount, 1, 4, 0.3, 0.5);
      5..12: Scale := RemapClamped(Player.HyperspaceKillCount, 5, 12, 0.5, 0.8);
      13..30: Scale := RemapClamped(Player.HyperspaceKillCount, 13, 30, 0.8, 1);
      31..80: Scale := RemapClamped(Player.HyperspaceKillCount, 31, 80, 1, 1.3);
    else Scale := RemapClamped(Player.HyperspaceKillCount, 81, 100, 1.3, 1.6);
    end;
    Scale := RemapClamped(Danger, 0, 100, 0.8, 1.2) * Scale;
    Scale := RemapClamped(Player.Wealth, Galaxy.AverageRangerCapital / 2, Galaxy.MaxRangerWealth, 0.8, 1.1) * Scale;
    Scale := RemapClamped(Player.StrengthInBestRanger, 0.2, 1, 0.5, 1.2) * Scale;
    Scale := Scale * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    if Index = 0 then Scale := ArcadeBattleScreen.RandomFloat(1, 1.3) * Scale
    else if Index = 1 then Scale := ArcadeBattleScreen.RandomFloat(0.6, 0.8) * Scale
    else Scale := ArcadeBattleScreen.RandomFloat(0.2, 0.5) * Scale;
    Hitpoints := Round(Max(150, Min(Player.Hull.Weight * 1.2, 525 * Scale)));
    Ship.CreateShipVisual('Ship.HS.' + IntToStr(IncrementWrapped(VisualIndex, 1, 5)), Round(RemapClamped(Hitpoints, 150, 900, 50, 80)));
    Ship.MaxHealth := Hitpoints;
    Ship.Health := Hitpoints;
    Ship.MaxSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 7, 5);
    Ship.MaxSpeed := Ship.MaxSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.TurnSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 3, 2);
    Ship.TurnSpeed := Ship.TurnSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.Thrust := 0;
    Ship.WeaponCount := 0;
    Kind := ArcadeBattleScreen.RandomRange(Minimum, Maximum);
    Ship.AddWeapon(Kind);
    if Index = 0 then
    begin
      Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      if (Player.StrengthInBestRanger > 0.9) or (Player.WealthInBestRanger > 0.9) then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    end;
    if (Player.StrengthInBestRanger > 0.7) or (Player.WealthInBestRanger > 0.7) then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    if ArcadeBattleScreen.RandomRange(0, Round(Danger)) < Danger then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    Ship.PrimaryWeapon := 0;
    Ship.EncounterTag := 1;
    Objects.Add(Ship);
  end;
  Kind := 0;
  MineralBudget := Min(CargoHookPowerByLevel[8], Player.Wealth div 40 div GoodsMarket[t_Minerals].BasePrice);
  MineralBudget := Round(RemapClamped(Danger + ApproachDanger, 0, 250, 0.2, 1.2) * MineralBudget);
  MineralBudget := Round(RemapClamped(Count, 0, 4, 0.8, 1.2) * MineralBudget);
  for Index := 1 to 8 do
  begin
    Item := TGoods.Create;
    with Item as TGoods do
    begin
      Count := Min(Round(ArcadeBattleScreen.RandomFloat(0.6, 1.3) * CargoHookPowerByLevel[Galaxy.TechLevel]), ArcadeBattleScreen.RandomRange(MineralBudget div 8, MineralBudget div 2)) + 1;
      Inc(Kind, Count);
      Init(t_Minerals, Count);
      NaturalFlag := True;
    end;
    ArcadeItem := TabItem.Create;
    ArcadeItem.SetItem(Item);
    Objects.Add(ArcadeItem);
    if Kind > MineralBudget then Break;
  end;
end;
{ @end $50BEEC }

{ @routine $50CA5C TabSpace_PopulateHoleEncounter }
procedure TabSpace.PopulateHoleEncounter;
var
  Item: TItem;
  ArcadeItem: TabItem;
  Index, Count, MineralBudget, Minimum, Maximum, Kind, VisualIndex, Hitpoints: Integer;
  Ship: TabShipAI;
  Scale: Single;
begin
  if Player = nil then Exit;
  Count := ArcadeBattleScreen.RandomRange(2, 4);
  Count := Min(5, Count + Round(RemapClamped(Galaxy.TechLevel, 4, 8, 0, 2)));
  if Player.BlackHoleKillCount = 0 then Count := 1
  else if Player.BlackHoleKillCount < 5 / DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor then Count := Min(Count, 2);
  Minimum := Round(RemapClamped(Galaxy.RefreshTechLevel, 3, 8, 0, 6));
  Maximum := Round(RemapClamped(Galaxy.RefreshTechLevel, 3, 8, 6, 11));
  VisualIndex := ArcadeBattleScreen.RandomRange(0, 2);
  for Index := 0 to Count - 1 do
  begin
    Ship := TabShipAI.Create;
    case Player.BlackHoleKillCount of
      0: Scale := 0.1;
      1..5: Scale := RemapClamped(Player.BlackHoleKillCount, 1, 5, 0.5, 0.6);
      6..12: Scale := RemapClamped(Player.BlackHoleKillCount, 6, 12, 0.6, 0.8);
      13..23: Scale := RemapClamped(Player.BlackHoleKillCount, 13, 23, 0.8, 1);
      24..40: Scale := RemapClamped(Player.BlackHoleKillCount, 24, 40, 1, 1.3);
    else Scale := RemapClamped(Player.BlackHoleKillCount, 41, 100, 1.3, 1.6);
    end;
    Scale := Scale * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Scale := RemapClamped(Player.Wealth, Galaxy.AverageRangerCapital / 2, Galaxy.MaxRangerWealth, 0.8, 1.1) * Scale;
    Scale := RemapClamped(Player.StrengthInBestRanger, 0.2, 1, 0.5, 1.1) * Scale;
    if Index = 0 then Scale := ArcadeBattleScreen.RandomFloat(1, 1.3) * Scale
    else if Index = 1 then Scale := ArcadeBattleScreen.RandomFloat(0.6, 0.8) * Scale
    else Scale := ArcadeBattleScreen.RandomFloat(0.2, 0.4) * Scale;
    if Player.BlackHoleKillCount = 0 then Hitpoints := 150
    else Hitpoints := Round(Max(150, Min(Player.Hull.Weight * 1.2, 525 * Scale)));
    Ship.CreateShipVisual('Ship.X.' + IntToStr(IncrementWrapped(VisualIndex, 0, 2)), Round(RemapClamped(Hitpoints, 150, 900, 50, 80)));
    Ship.MaxHealth := Hitpoints;
    Ship.Health := Hitpoints;
    Ship.MaxSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 7, 5);
    Ship.MaxSpeed := RemapClamped(Player.BlackHoleKillCount, 0, 30, 0.6, 1) * Ship.MaxSpeed;
    Ship.MaxSpeed := Ship.MaxSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.TurnSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 4, 3);
    Ship.TurnSpeed := RemapClamped(Player.BlackHoleKillCount, 0, 30, 0.6, 1) * Ship.TurnSpeed;
    Ship.TurnSpeed := Ship.TurnSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.Thrust := 0;
    Ship.WeaponCount := 0;
    Kind := ArcadeBattleScreen.RandomRange(Minimum, Maximum);
    Ship.AddWeapon(Kind);
    Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    if Index = 0 then
    begin
      Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      if ((Player.BlackHoleKillCount > 0) and (Player.StrengthInBestRanger > 0.9)) or (Player.WealthInBestRanger > 0.9) then
        Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    end;
    if Player.BlackHoleKillCount > 0 then
    begin
      if (Player.StrengthInBestRanger > 0.7) or (Player.WealthInBestRanger > 0.7) then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      if ArcadeBattleScreen.RandomRange(0, Round(Danger)) < Danger then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    end;
    Ship.PrimaryWeapon := 0;
    Ship.EncounterTag := 1;
    Objects.Add(Ship);
  end;
  Kind := 0;
  MineralBudget := Min(CargoHookPowerByLevel[8], Player.Wealth div 40 div GoodsMarket[t_Minerals].BasePrice);
  MineralBudget := Round(RemapClamped(Count, 2, 4, 0.8, 1.2) * MineralBudget);
  for Index := 1 to 8 do
  begin
    Item := TGoods.Create;
    with Item as TGoods do
    begin
      Count := Min(Round(ArcadeBattleScreen.RandomFloat(0.6, 1.3) * CargoHookPowerByLevel[Galaxy.TechLevel]), ArcadeBattleScreen.RandomRange(MineralBudget div 8, MineralBudget div 2)) + 1;
      Inc(Kind, Count);
      Init(t_Minerals, Count);
      NaturalFlag := True;
    end;
    ArcadeItem := TabItem.Create;
    ArcadeItem.SetItem(Item);
    Objects.Add(ArcadeItem);
    if Kind > MineralBudget then Break;
  end;
end;
{ @end $50CA5C }

{ @routine $50D3E0 TabSpace_PopulateFinalEncounter }
procedure TabSpace.PopulateFinalEncounter;
var
  Ship: TabShipAI;
  I, Minimum, Maximum, Kind, VisualIndex: Integer;
begin
  Ship := TabShipAI.Create;
  Ship.CreateShipVisual('Ship.Kling.K0', 128);
  Ship.MaxHealth := KlingMotherShip.Hull.Weight;
  Ship.Health := Round(RemapClamped(Player.BlackHoleKillCount + Player.HyperspaceKillCount, 20, 200, 500, 1500));
  Ship.Health := Round(Ship.Health * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Ship.MaxSpeed := 5;
  Ship.MaxSpeed := Ship.MaxSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
  Ship.TurnSpeed := 2;
  Ship.TurnSpeed := Ship.TurnSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
  Ship.Thrust := 0;
  Ship.WeaponCount := KlingMotherShip.WeaponCount;
  for I := 0 to KlingMotherShip.WeaponCount - 1 do
    ab_Weapon_Initialize(@Ship.Weapons[I], KlingMotherShip.Weapons[I].ItemType);
  Ship.PrimaryWeapon := 0;
  Ship.EncounterTag := 1;
  Objects.Add(Ship);
  BossArcadeShip := Ship;
  for I := 0 to 1 do
  begin
    Ship := TabShipAI.Create;
    if I = 0 then
      Ship.CreateShipVisual('Ship.Kling.K' + IntToStr(ArcadeBattleScreen.RandomRange(1, 1)), ArcadeBattleScreen.RandomRange(100, 100))
    else
      Ship.CreateShipVisual('Ship.Kling.K' + IntToStr(ArcadeBattleScreen.RandomRange(3, 3)), ArcadeBattleScreen.RandomRange(50, 50));
    if ScenarioState = scenAllianceAgainstRachekhan then
    begin
      if I = 0 then Ship.Health := BossArcadeShip.Health div 2
      else Ship.Health := BossArcadeShip.Health div 4;
    end
    else
    begin
      if I = 0 then Ship.Health := BossArcadeShip.Health div 2
      else Ship.Health := BossArcadeShip.Health div 4;
    end;
    Ship.MaxHealth := Ship.Health;
    Ship.MaxSpeed := 7;
    Ship.MaxSpeed := Ship.MaxSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.TurnSpeed := 4;
    Ship.TurnSpeed := Ship.TurnSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
    Ship.Thrust := 0;
    Ship.WeaponCount := 0;
    if I = 0 then begin Minimum := 8; Maximum := 13; end
    else begin Minimum := 5; Maximum := 10; end;
    Kind := ArcadeBattleScreen.RandomRange(Minimum, Maximum);
    Ship.AddWeapon(Kind);
    Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
    Ship.PrimaryWeapon := 0;
    Ship.EncounterTag := 1;
    Objects.Add(Ship);
  end;
  if ScenarioState = scenAllianceAgainstRachekhan then
  begin
    Ship := TabShipAI.Create;
    Ship.CreateShipVisual('Ship.HS.0', 100);
    Ship.Health := 6000;
    Ship.MaxHealth := 6000;
    Ship.MaxSpeed := 4;
    Ship.TurnSpeed := 1.5;
    Ship.Thrust := 0;
    Ship.WeaponCount := 5;
    ab_Weapon_Initialize(@Ship.Weapons[0], t_Retractor);
    ab_Weapon_Initialize(@Ship.Weapons[1], t_SubmesonicGun);
    ab_Weapon_Initialize(@Ship.Weapons[2], t_FieldAnnihilator);
    ab_Weapon_Initialize(@Ship.Weapons[3], t_TachionCleaver);
    ab_Weapon_Initialize(@Ship.Weapons[4], t_VortexProjector);
    Ship.PrimaryWeapon := 0;
    Ship.EncounterTag := 2;
    Objects.Add(Ship);
    AlliedArcadeFlagship := Ship;
    Minimum := 5;
    Maximum := 11;
    VisualIndex := ArcadeBattleScreen.RandomRange(1, 5);
    for I := 0 to 3 do
    begin
      Ship := TabShipAI.Create;
      Ship.CreateShipVisual('Ship.HS.' + IntToStr(IncrementWrapped(VisualIndex, 1, 5)), ArcadeBattleScreen.RandomRange(50, 80));
      Ship.MaxHealth := Round(RemapClamped(Ship.VisualDiameter, 50, 80, 150, 900));
      if I = 0 then
        Ship.MaxHealth := Max(Ship.MaxHealth, Round(RemapClamped(Galaxy.RefreshTechLevel, 3, 8, 1.5, 2.5) * Player.Hull.Weight))
      else
        Ship.MaxHealth := Min(Ship.MaxHealth, Round(RemapClamped(Galaxy.RefreshTechLevel, 3, 8, 1.5, 2) * Player.Hull.Weight));
      Ship.MaxHealth := Round(Ship.MaxHealth * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
      Ship.Health := Ship.MaxHealth;
      Ship.MaxSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 12, 10) + I;
      Ship.MaxSpeed := Ship.MaxSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
      Ship.TurnSpeed := RemapClampedAlternate(Ship.VisualDiameter, 50, 80, 5, 3) + I;
      Ship.TurnSpeed := Ship.TurnSpeed * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor;
      Ship.Thrust := 0;
      Ship.WeaponCount := 0;
      Kind := ArcadeBattleScreen.RandomRange(Minimum, Maximum);
      if I = 0 then Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      Ship.AddWeapon(IncrementWrapped(Kind, Minimum, Maximum));
      Ship.PrimaryWeapon := 0;
      Ship.EncounterTag := 2;
      Objects.Add(Ship);
    end;
  end;
end;
{ @end $50D3E0 }

{ @routine $50DD58 TabSpace_UpdateApproachDanger }
procedure TabSpace.UpdateApproachDanger;

  // @nested $50DCC4 FindApproachDanger
  function FindApproachDanger(Space: TabSpace; Accumulated: Single): Single; // @addr $50DCC4
  var
    Link: PabSpaceLink;
    Candidate: Single;
  begin
    Link := FirstArcadeSpaceLink;
    while Link <> nil do
    begin
      if (Link.Last = Space) and (Link.First.Danger <= 0) then
      begin
        Result := Accumulated;
        Exit;
      end;
      Link := Link.Next;
    end;
    Result := 1E20;
    Link := FirstArcadeSpaceLink;
    while Link <> nil do
    begin
      if Link.Last = Space then
      begin
        Candidate := FindApproachDanger(Link.First, Accumulated + Link.First.Danger);
        if Candidate < Result then Result := Candidate;
      end;
      Link := Link.Next;
    end;
  end;

begin
  if Danger <= 0 then
  begin
    ApproachDanger := 0;
    Exit;
  end;
  ApproachDanger := FindApproachDanger(Self, 0);
end;
{ @end $50DD58 }

{ @routine $50DD90 TabSpace_PruneApproachDanger }
procedure TabSpace.PruneApproachDanger;
var
  Changed: Boolean;
  Link: PabSpaceLink;
  Space: TabSpace;
begin
  Changed := True;
  while Changed do
  begin
    Changed := False;
    Space := FirstArcadeSpace;
    while Space <> nil do
    begin
      if Space.ApproachDanger > 0 then
      begin
        Link := FirstArcadeSpaceLink;
        while Link <> nil do
        begin
          if (Link.First = Space) and (Link.Last.ApproachDanger > 0) then Break;
          Link := Link.Next;
        end;
        if Link <> nil then
        begin
          Link := FirstArcadeSpaceLink;
          while Link <> nil do
          begin
            if (Link.Last = Space) and (Link.First.ApproachDanger > 0) then Break;
            Link := Link.Next;
          end;
          if Link = nil then
          begin
            Space.ApproachDanger := 0;
            Changed := True;
          end;
        end;
      end;
      Space := Space.Next;
    end;
  end;
end;
{ @end $50DD90 }

{ @routine $50DE20 TabSpace_GetDangerText }
function TabSpace.GetDangerText: WideString;
begin
  if Danger = 0 then Result := LocalizedColorText('FormAB.DangerMini')
  else if Danger < 40 then Result := LocalizedColorText('FormAB.DangerSmall')
  else if Danger < 70 then Result := LocalizedColorText('FormAB.DangerAverage')
  else if Danger < 90 then Result := LocalizedColorText('FormAB.DangerBig')
  else Result := LocalizedColorText('FormAB.DangerHuge');
end;
{ @end $50DE20 }

{ @routine $50DF88 ab_Space_Clear }
procedure ab_Space_Clear;
begin
  ab_SpaceLink_Clear;
  while FirstArcadeSpace <> nil do ab_Space_Delete(LastArcadeSpace);
  CurrentArcadeSpace := nil;
  NextArcadeSpace := nil;
  StartArcadeSpace := nil;
  EndArcadeSpace := nil;
end;
{ @end $50DF88 }

{ @routine $50DFC0 ab_Space_Add }
function ab_Space_Add: TabSpace;
var
  Space: TabSpace;
begin
  Space := TabSpace.Create;
  if LastArcadeSpace <> nil then LastArcadeSpace.Next := Space;
  Space.Prev := LastArcadeSpace;
  Space.Next := nil;
  LastArcadeSpace := Space;
  if FirstArcadeSpace = nil then FirstArcadeSpace := Space;
  Result := Space;
end;
{ @end $50DFC0 }

{ @routine $50E000 ab_Space_Delete }
procedure ab_Space_Delete(Space: TabSpace);
var
  Link, Removing: PabSpaceLink;
begin
  if Space.Prev <> nil then Space.Prev.Next := Space.Next;
  if Space.Next <> nil then Space.Next.Prev := Space.Prev;
  if LastArcadeSpace = Space then LastArcadeSpace := Space.Prev;
  if FirstArcadeSpace = Space then FirstArcadeSpace := Space.Next;
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    Removing := Link;
    Link := Link.Next;
    if (Removing.First = Space) or (Removing.Last = Space) then
      ab_SpaceLink_Delete(Removing);
  end;
  Space.Free;
end;
{ @end $50E000 }

{ @routine $50E06C ab_Space_CreateImages }
procedure ab_Space_CreateImages;
var
  Space: TabSpace;
begin
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.CreateImage;
    Space := Space.Next;
  end;
end;
{ @end $50E06C }

{ @routine $50E088 ab_Space_ClearImages }
procedure ab_Space_ClearImages;
var
  Space: TabSpace;
begin
  ab_SpaceLink_ClearImages;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.ClearImage;
    Space := Space.Next;
  end;
end;
{ @end $50E088 }

{ @routine $50E0A8 ab_Space_Update }
procedure ab_Space_Update;
var
  Space: TabSpace;
begin
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.Update;
    Space := Space.Next;
  end;
end;
{ @end $50E0A8 }

{ @routine $50E0C4 ab_Space_Find }
function ab_Space_Find(GridPosition: TPoint): TabSpace;
var
  Space: TabSpace;
begin
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    if (Space.GridPosition.X = GridPosition.X) and (Space.GridPosition.Y = GridPosition.Y) then
    begin
      Result := Space;
      Exit;
    end;
    Space := Space.Next;
  end;
  Result := nil;
end;
{ @end $50E0C4 }

{ @routine $50E0F8 ab_Space_RecountLinks }
procedure ab_Space_RecountLinks;
var
  Space: TabSpace;
begin
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.RecountLinks;
    Space := Space.Next;
  end;
end;
{ @end $50E0F8 }

{ @routine $50E114 TabSpace_RecountLinks }
procedure TabSpace.RecountLinks;
var
  Link: PabSpaceLink;
begin
  IncomingCount := 0;
  OutgoingCount := 0;
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    if Link.First = Self then Inc(OutgoingCount)
    else if Link.Last = Self then Inc(IncomingCount);
    Link := Link.Next;
  end;
end;
{ @end $50E114 }

{ @routine $50E144 ab_Space_UpdateApproachDanger }
procedure ab_Space_UpdateApproachDanger;
var
  Space: TabSpace;
begin
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.UpdateApproachDanger;
    Space := Space.Next;
  end;
  Space := FirstArcadeSpace;
  while Space <> nil do
  begin
    Space.PruneApproachDanger;
    Space := Space.Next;
  end;
end;
{ @end $50E144 }

{ @routine $50E178 ab_SpaceLink_Clear }
procedure ab_SpaceLink_Clear;
begin
  while FirstArcadeSpaceLink <> nil do ab_SpaceLink_Delete(LastArcadeSpaceLink);
end;
{ @end $50E178 }

{ @routine $50E190 ab_SpaceLink_Add }
function ab_SpaceLink_Add: PabSpaceLink;
var
  Link: PabSpaceLink;
begin
  Link := AllocClearEC(SizeOf(TabSpaceLink));
  if LastArcadeSpaceLink <> nil then LastArcadeSpaceLink.Next := Link;
  Link.Prev := LastArcadeSpaceLink;
  Link.Next := nil;
  LastArcadeSpaceLink := Link;
  if FirstArcadeSpaceLink = nil then FirstArcadeSpaceLink := Link;
  Result := Link;
end;
{ @end $50E190 }

{ @routine $50E1D0 ab_SpaceLink_Delete }
procedure ab_SpaceLink_Delete(Link: PabSpaceLink);
begin
  if Link.Prev <> nil then Link.Prev.Next := Link.Next;
  if Link.Next <> nil then Link.Next.Prev := Link.Prev;
  if LastArcadeSpaceLink = Link then LastArcadeSpaceLink := Link.Prev;
  if FirstArcadeSpaceLink = Link then FirstArcadeSpaceLink := Link.Next;
  FreeEC(Link);
end;
{ @end $50E1D0 }

{ @routine $50E210 ab_SpaceLink_Connect }
procedure ab_SpaceLink_Connect(First, Last: TabSpace);
var
  Link: PabSpaceLink;
begin
  Link := ab_SpaceLink_Add;
  Link.First := First;
  Link.Last := Last;
end;
{ @end $50E210 }

{ @routine $50E224 ab_SpaceLink_Find }
function ab_SpaceLink_Find(First, Last: TabSpace): PabSpaceLink;
var
  Link: PabSpaceLink;
begin
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    if ((Link.First = First) and (Link.Last = Last)) or
       ((Link.First = Last) and (Link.Last = First)) then
    begin
      Result := Link;
      Exit;
    end;
    Link := Link.Next;
  end;
  Result := nil;
end;
{ @end $50E224 }

{ @routine $50E250 ab_SpaceLink_FindExit }
function ab_SpaceLink_FindExit(Space: TabSpace; ExitIndex: Integer): PabSpaceLink;
var Link: PabSpaceLink;
begin
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    if (Link.First = Space) and (Link.ExitIndex = ExitIndex) then
    begin
      Result := Link;
      Exit;
    end;
    Link := Link.Next;
  end;
  Result := nil;
end;
{ @end $50E250 }

{ @routine $50E274 ab_SpaceLink_Invalidate }
procedure ab_SpaceLink_Invalidate;
var Offset: TPoint; Bounds: TRect; Link: PabSpaceLink; Index: Integer;
begin
  with Bounds, Offset do begin
    X := ArcadeBattleScreen.WorldCenterX - ArcadeMapViewPosition.X;
    Y := ArcadeBattleScreen.WorldCenterY - ArcadeMapViewPosition.Y;
    Link := FirstArcadeSpaceLink;
    while Link <> nil do begin
      Left := 1000000000;
      Right := -1000000000;
      Top := 1000000000;
      Bottom := -1000000000;
      for Index := 0 to 10 do begin
        Left := Min(Left, Link.Points[Index].X);
        Top := Min(Top, Link.Points[Index].Y);
        Right := Max(Right, Link.Points[Index].X);
        Bottom := Max(Bottom, Link.Points[Index].Y);
      end;
      Inc(Left, X);
      Inc(Top, Y);
      Inc(Right, X);
      Inc(Bottom, Y);
      ArcadeBattleScreen.QueueUpdateRect(Bounds);
      Link := Link.Next;
    end;
  end;
end;
{ @end $50E274 }

{ @routine $50E350 ab_SpaceLink_BuildGeometry }
procedure ab_SpaceLink_BuildGeometry;
var
  First, Last, Direction, Width: TPointF;
  InverseLength, ArrowLength: Single;
  Link: PabSpaceLink;
begin
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    First := PointToPointF(Link.First.MapPosition);
    Last := PointToPointF(Link.Last.MapPosition);
    Direction.X := Last.X - First.X;
    Direction.Y := Last.Y - First.Y;
    InverseLength := 1 / Sqrt(Sqr(Direction.X) + Sqr(Direction.Y));
    Direction.X := Direction.X * InverseLength;
    Direction.Y := Direction.Y * InverseLength;
    ArrowLength := GiScalePixels(ArcadeMapNodeRadius) * 0.5;
    First.X := GiScalePixels(ArcadeMapNodeRadius) * Direction.X * 1.1 + First.X;
    First.Y := GiScalePixels(ArcadeMapNodeRadius) * Direction.Y * 1.1 + First.Y;
    Last.X := Last.X - (GiScalePixels(ArcadeMapNodeRadius) * 1.1 + ArrowLength) * Direction.X;
    Last.Y := Last.Y - (GiScalePixels(ArcadeMapNodeRadius) * 1.1 + ArrowLength) * Direction.Y;
    Width.X := GiScalePixels(7) * Direction.X;
    Width.Y := GiScalePixels(7) * Direction.Y;
    Link.Points[0] := Classes.Point(Round(First.X - Width.Y), Round(First.Y + Width.X));
    Link.Points[1] := Classes.Point(Round(First.X + Width.Y), Round(First.Y - Width.X));
    Link.Points[2] := Classes.Point(Round(Last.X + Width.Y - Direction.X * 2), Round(Last.Y - Width.X - Direction.Y * 2));
    Link.Points[3] := Classes.Point(Round(Last.X - Width.Y - Direction.X * 2), Round(Last.Y + Width.X - Direction.Y * 2));
    Link.Points[7] := Classes.Point(Round(First.X - 0.7 * Width.Y), Round(0.7 * Width.X + First.Y));
    Link.Points[8] := Classes.Point(Round(0.7 * Width.Y + First.X), Round(First.Y - 0.7 * Width.X));
    Link.Points[9] := Classes.Point(Round(0.7 * Width.Y + Last.X - Direction.X * 2), Round(Last.Y - 0.7 * Width.X - Direction.Y * 2));
    Link.Points[10] := Classes.Point(Round(Last.X - 0.7 * Width.Y - Direction.X * 2), Round(0.7 * Width.X + Last.Y - Direction.Y * 2));
    Width.X := Direction.X * ArrowLength * 0.4;
    Width.Y := Direction.Y * ArrowLength * 0.4;
    Link.Points[4] := Classes.Point(Round(Last.X - Width.Y), Round(Last.Y + Width.X));
    Link.Points[5] := Classes.Point(Round(Direction.X * ArrowLength + Last.X), Round(Direction.Y * ArrowLength + Last.Y));
    Link.Points[6] := Classes.Point(Round(Last.X + Width.Y), Round(Last.Y - Width.X));
    Link := Link.Next;
  end;
end;
{ @end $50E350 }

{ @routine $50E7B8 ab_SpaceLink_ClearImages }
procedure ab_SpaceLink_ClearImages;
var
  Link: PabSpaceLink;
begin
  Link := FirstArcadeSpaceLink;
  while Link <> nil do Link := Link.Next;
end;
{ @end $50E7B8 }

{ @routine $50E7CC ab_SpaceLink_Draw }
procedure ab_SpaceLink_Draw;
var
  Link: PabSpaceLink;
  ColorOffset: Integer;
  Offset: TPoint;
begin
  Offset.X := ArcadeBattleScreen.WorldCenterX - ArcadeMapViewPosition.X;
  Offset.Y := ArcadeBattleScreen.WorldCenterY - ArcadeMapViewPosition.Y;
  Link := FirstArcadeSpaceLink;
  while Link <> nil do
  begin
    ColorOffset := Link.Last.AppearanceIndex * 6;
    DrawGradientLine16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Link.Points[7].X + Offset.X, Link.Points[7].Y + Offset.Y, $40FFFFFF,
      Link.Points[10].X + Offset.X, Link.Points[10].Y + Offset.Y, $C0FFFFFF, GameScreenRect);
    DrawGradientLine16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Link.Points[8].X + Offset.X, Link.Points[8].Y + Offset.Y, $40FFFFFF,
      Link.Points[9].X + Offset.X, Link.Points[9].Y + Offset.Y, $C0FFFFFF, GameScreenRect);
    TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Link.Points[0].X + Offset.X, Link.Points[0].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 3],
      Link.Points[1].X + Offset.X, Link.Points[1].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 3],
      Link.Points[2].X + Offset.X, Link.Points[2].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 2], @GameScreenRect);
    TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Link.Points[2].X + Offset.X, Link.Points[2].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 2],
      Link.Points[3].X + Offset.X, Link.Points[3].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 2],
      Link.Points[0].X + Offset.X, Link.Points[0].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 3], @GameScreenRect);
    TriangleRasterizer16(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      Link.Points[4].X + Offset.X, Link.Points[4].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 1],
      Link.Points[5].X + Offset.X, Link.Points[5].Y + Offset.Y, ArcadeMapPalette[ColorOffset],
      Link.Points[6].X + Offset.X, Link.Points[6].Y + Offset.Y, ArcadeMapPalette[ColorOffset + 1], @GameScreenRect);
    Link := Link.Next;
  end;
end;
{ @end $50E7CC }
end.

unit aAsteroid;
// Unit bracket (inferred): CODE 0x005C8C8C..0x005C97EB; inclusive evidence, not full bounds.
// Native VMT $5C8C8C; load $5C8F34, motion $5C9314 and turn-film $5C9090 witnesses.

interface

uses EC_Buf, EC_Struct, SE_Space, SE_Asteroid, aEFilm, aGalaxy;

type
  TAsteroid = class(TObjectEx) // @size $3C
  public
    function GetDisplayName: WideString; // @addr $5C94F8
    function GetInfoText: WideString; // @addr $5C95DC
    procedure PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean); // @addr $5C9090
    procedure AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean); // @addr $5C90E0
    procedure InitializeAtStar(Star: TStar); // @addr $5C8D68
    Id: Cardinal; // @offset $04
    CurrentStar: TStar; // @offset $08
    Position: TPointF; // @offset $0C  World coordinates: PhysicsPosition multiplied by 6e-9.
    PhysicsPosition: TPointF; // @offset $14
    Velocity: TPointF; // @offset $1C  In the physics coordinate system.
    Mass: Single; // @offset $24
    GravityForceFactor: Single; // @offset $28  G * Mass * 2e30.
    InverseMass: Single; // @offset $2C
    MineralCount: Integer; // @offset $30
    GraphObject: TAsteroidSE; // @offset $34  Owned; the scene object is freed directly.
    FilmObject: TEFilmObj; // @offset $38  Borrowed from the film.

    constructor Create; // @addr $5C8CE4
    destructor Destroy; override; // @addr $5C8D30
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5C8ED8
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5C8F34 @note "Caller sets CurrentStar. Requires an unassigned GraphObject."
    procedure RespawnIfOutsideSystem; // @addr $5C9060
    procedure Respawn; // @addr $5C912C @note "Keeps the ID and visual."
    procedure IntegrateMotion(TimeScale: Single); // @addr $5C9314
    procedure WritePredictedPositions(Positions: PPointF; Count: Integer); // @addr $5C944C @note "Writes Count future positions at TimeScale=1, excluding the current position, then restores the live motion state. Caller supplies Count * 8 bytes."
  end;

const
  AsteroidGravitationalConstant: Single = 6.672041391597716e-11; // @addr $6188EC

implementation
// @unit-initialization $5C97E4
// @unit-finalization $5C97B4

uses EC_BlockPar, GR_Main, Globals, SE_Process, SysUtils, EC_Str, aConst, Math, aMyFunction, Classes, SE_Asteroid, EC_Mem;

const
  AsteroidCentralMass = 2e30 - 137438953472.0;
  AsteroidInverseScaleSquared = 27777777777777777.78;
  AsteroidWorldScale = 5.9999999999999999993e-9;

{ @routine $5C8CE4 TAsteroid_Create }
constructor TAsteroid.Create;
begin
  inherited Create;
  Id := Galaxy.NextAsteroidId;
  Inc(Galaxy.NextAsteroidId);
end;
{ @end $5C8CE4 }

{ @routine $5C8D30 TAsteroid_Destroy }
destructor TAsteroid.Destroy;
begin
  if GraphObject <> nil then begin GraphObject.Free; GraphObject := nil; end;
  inherited Destroy;
end;
{ @end $5C8D30 }

{ @routine $5C8D68 TAsteroid_InitializeAtStar }
procedure TAsteroid.InitializeAtStar(Star: TStar);
var
  GraphKey: WideString;
  I, J, BlockCount, AsteroidCount: Integer;
  Config: TBlockParEC;
begin
  CurrentStar := Star;
  Config := GameDataConfig.GetBlockByPath('SE.Asteroid');
  BlockCount := Config.GetBlockCount;
  AsteroidCount := CurrentStar.Asteroids.Count;
  for I := 0 to 10 do begin
    GraphKey := 'Asteroid.' + Config.GetBlockNameByIndex(SeededRandomIntRange(0, BlockCount - 1,
      Galaxy.GenerationSeed * (Id + Cardinal(I)) * 713));
    J := 0;
    while J < AsteroidCount do begin
      if TAsteroid(CurrentStar.Asteroids[J]).GraphObject.GraphKey = GraphKey then Break;
      Inc(J);
    end;
    if J >= AsteroidCount then Break;
  end;
  GraphObject := CreateSpaceObjectByName('Asteroid', GraphKey, Classes.Point(0, 0)) as TAsteroidSE;
  Respawn;
end;
{ @end $5C8D68 }

{ @routine $5C8ED8 TAsteroid_SaveToBuffer }
procedure TAsteroid.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddWideStringZ(GraphObject.GraphKey);
  Buffer.AddSingle(PhysicsPosition.X);
  Buffer.AddSingle(PhysicsPosition.Y);
  Buffer.AddSingle(Velocity.X);
  Buffer.AddSingle(Velocity.Y);
  Buffer.AddSingle(Mass);
  Buffer.AddIntegerValue(MineralCount);
end;
{ @end $5C8ED8 }

{ @routine $5C8F34 TAsteroid_LoadFromBuffer }
procedure TAsteroid.LoadFromBuffer(Buffer: TBufEC);
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextAsteroidId <= Id then Galaxy.NextAsteroidId := Id + 1;
  GraphObject := TAsteroidSE.Create(Buffer.ReadWideString, Classes.Point(0, 0));
  PhysicsPosition.X := Buffer.GetSingle;
  PhysicsPosition.Y := Buffer.GetSingle;
  Velocity.X := Buffer.GetSingle;
  Velocity.Y := Buffer.GetSingle;
  Mass := Buffer.GetSingle;
  InverseMass := 1 / Mass;
  GravityForceFactor := AsteroidGravitationalConstant * Mass * AsteroidCentralMass;
  MineralCount := Buffer.GetInt32;
  Position.X := PhysicsPosition.X * AsteroidWorldScale;
  Position.Y := PhysicsPosition.Y * AsteroidWorldScale;
end;
{ @end $5C8F34 }

{ @routine $5C9060 TAsteroid_RespawnIfOutsideSystem }
procedure TAsteroid.RespawnIfOutsideSystem;
begin
  if Position.X * Position.X + Position.Y * Position.Y > Sqr(CurrentStar.MapDiameter) then Respawn;
end;
{ @end $5C9060 }

{ @routine $5C9090 TAsteroid_PrepareTurnMovement }
procedure TAsteroid.PrepareTurnMovement(StartStepIndex: Integer; RecordFilm: Boolean);
begin
  if RecordFilm then begin
    FilmObject := PrimaryFilm.AddObject(Id, GraphObject, 0, 0);
    PrimaryFilm.SetObjectPosition(StartStepIndex, FilmObject, Position);
    PrimaryFilm.AttachObject(StartStepIndex, FilmObject);
  end;
end;
{ @end $5C9090 }

{ @routine $5C90E0 TAsteroid_AdvanceOrbitStep }
procedure TAsteroid.AdvanceOrbitStep(StepIndex: Integer; RecordFilm: Boolean);
begin
  if PlayerStar = CurrentStar then IntegrateMotion(1) else IntegrateMotion(20);
  if RecordFilm then PrimaryFilm.SetObjectPosition(StepIndex, FilmObject, Position);
end;
{ @end $5C90E0 }

{ @routine $5C912C TAsteroid_Respawn }
procedure TAsteroid.Respawn;
var
  Angle, Radius, Speed, Reserved: Single; // Native reserves one additional scalar slot.
begin
  Mass := 1000000;
  InverseMass := 1 / Mass;
  GravityForceFactor := AsteroidGravitationalConstant * Mass * AsteroidCentralMass;
  Angle := HeadingDegreesToRadians(NextRandomIntRange(0, 360, CurrentStar.RandomState));
  Radius := CurrentStar.MapDiameter / 2 + 800 + 2000;
  Radius := Radius + NextRandomIntRange(0, 1000, CurrentStar.RandomState);
  Position.X := Sin(Angle) * Radius;
  Position.Y := -Cos(Angle) * Radius;
  PhysicsPosition.X := Position.X * (1 / AsteroidWorldScale);
  PhysicsPosition.Y := Position.Y * (1 / AsteroidWorldScale);
  Speed := NextRandomIntRange(0, 3000, CurrentStar.RandomState) + 7000;
  Angle := ArcTan2(0.0 - Position.X, -(0.0 - Position.Y));
  Angle := Angle + HeadingDegreesToRadians(NextRandomIntRange(-10, 10, CurrentStar.RandomState) + 25) *
    (2 * NextRandomIntRange(0, 1, CurrentStar.RandomState) - 1);
  Velocity.X := Sin(Angle) * Speed;
  Velocity.Y := -Cos(Angle) * Speed;
  MineralCount := NextRandomIntRange(20, 99, CurrentStar.RandomState);
end;
{ @end $5C912C }

{ @routine $5C9314 TAsteroid_IntegrateMotion }
procedure TAsteroid.IntegrateMotion(TimeScale: Single);
var
  ControlWord: Word;
  DistanceSquared, One, InverseDistance, ForceY, ForceX, DeltaY, DeltaX, AccelY, AccelX, Force: Single;
begin
  One := 1;
  DeltaX := 0.0 - Position.X;
  DeltaY := 0.0 - Position.Y;
  DistanceSquared := DeltaX * DeltaX + DeltaY * DeltaY;
  // Native sets single precision and never restores the FPU control word.
  asm
    FSTCW ControlWord
    AND ControlWord, $FCFF
    FLDCW ControlWord
    FLD DistanceSquared
    FSQRT
    FDIVR One
    FSTP InverseDistance
  end;
  if DistanceSquared < 10000 then DistanceSquared := 10000;
  Force := GravityForceFactor / (DistanceSquared * AsteroidInverseScaleSquared);
  ForceX := DeltaX * InverseDistance * Force;
  ForceY := DeltaY * InverseDistance * Force;
  AccelX := ForceX * InverseMass;
  AccelY := ForceY * InverseMass;
  Velocity.X := Velocity.X + AccelX * TimeScale * 19968;
  Velocity.Y := Velocity.Y + AccelY * TimeScale * 19968;
  PhysicsPosition.X := PhysicsPosition.X + Velocity.X * TimeScale * 19968;
  PhysicsPosition.Y := PhysicsPosition.Y + Velocity.Y * TimeScale * 19968;
  Position.X := PhysicsPosition.X * AsteroidWorldScale;
  Position.Y := PhysicsPosition.Y * AsteroidWorldScale;
end;
{ @end $5C9314 }

{ @routine $5C944C TAsteroid_WritePredictedPositions }
procedure TAsteroid.WritePredictedPositions(Positions: PPointF; Count: Integer);
var
  SavedPosition, SavedPhysicsPosition, SavedVelocity: TPointF;
  Index: Integer;
begin
  SavedPosition := Position;
  SavedPhysicsPosition := PhysicsPosition;
  SavedVelocity := Velocity;
  for Index := 0 to Count - 1 do
  begin
    IntegrateMotion(1);
    WriteSingleEC(Positions, Position.X);
    Positions := AddPointerOffset(Positions, 4);
    WriteSingleEC(Positions, Position.Y);
    Positions := AddPointerOffset(Positions, 4);
  end;
  Position := SavedPosition;
  PhysicsPosition := SavedPhysicsPosition;
  Velocity := SavedVelocity;
end;
{ @end $5C944C }

{ @routine $5C94F8 TAsteroid_GetDisplayName }
function TAsteroid.GetDisplayName: WideString;
begin
  Result := LocalizedText('Asteroid.Name');
  ReplaceTextToken(Result, '<Number>', IntToStr(Id), HighlightColorTag);
end;
{ @end $5C94F8 }

{ @routine $5C95DC TAsteroid_GetInfoText }
function TAsteroid.GetInfoText: WideString;
var Speed: Single;
begin
  Result := LocalizedText('Asteroid.Text');
  ReplaceTextToken(Result, '<Number>', IntToStr(Id), HighlightColorTag);
  Speed := Sqrt(Sqr(Velocity.X) + Sqr(Velocity.Y));
  Speed := Speed * 200 * 19968 * AsteroidWorldScale;
  ReplaceTextToken(Result, '<Speed>', IntToStr(Round(Speed)), HighlightColorTag);
  ReplaceTextToken(Result, '<Count>', IntToStr(MineralCount), HighlightColorTag);
end;
{ @end $5C95DC }

end.

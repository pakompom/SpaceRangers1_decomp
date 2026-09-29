unit ab_Global;
// Unit bracket (inferred): CODE 0x004DE478..0x004DFC13; inclusive evidence, not full bounds.
// Spherical geometry and matrix operations.
// Native PACKAGEINFO visits ab_Global from the arcade geometry family.

interface

uses EC_Struct, EC_Buf, Types;

const
  // BonusTicks order from TabShip.ApplyDamage ($5093D8), UpdateState ($513418)
  // and Advance ($513754); shared with map bonus flags and pickup handling.
  abkRegeneration = 0;
  abkSpeed = 1;
  abkSlow = 2;
  abkWeaponLock = 3;
  abkDamage = 4;
  abkRecharge = 5;
  abkShield = 6;
  abkInvisibility = 7;

  ArcadeBonusKindMask = $FF;
  ArcadeHiddenBonusFlag = $80000000;

type
  TArcadeViewMode = (avmSpace = 0, avmToMap = 1, avmMap = 2, avmToSpace = 3, avmMachpellaDialog = 4, avmExit = 5); // @size $04
  // Column-major storage: Matrix[Column][Row].
  TMatrix4D = array[0..3] of array[0..3] of Double; // @size $80

  TSphericalBearingState = record // @size $18
    LongitudeDegrees: Double; // @offset $00
    PolarAngleDegrees: Double; // @offset $08
    BearingDegrees: Double; // @offset $10
    // Polar angle is measured from -Y: 0 at -Y, 90 at the equator, 180 at +Y.
    // Longitude zero points toward -Z; positive longitude turns toward +X.
  end;

  TSphericalBearingDistance = record // @size $10
    BearingDeltaDegrees: Double; // @offset $00
    Distance: Double; // @offset $08
  end;

function MakeSphericalBearingState(LongitudeDegrees, PolarAngleDegrees, BearingDegrees: Double): TSphericalBearingState; // @addr $4DE478
function SphericalToVector3D(LongitudeRadians, PolarAngleRadians, Radius: Double): TVector3D; // @addr $4DE4A4
procedure VectorToSphericalAngles(Vector: TVector3D; var LongitudeDegrees, PolarAngleDegrees: Double); // @addr $4DE508 @note "Requires a nonzero vector."
procedure AdvanceSphericalBearingState(var LongitudeDegrees, PolarAngleDegrees, BearingDegrees: Double; SphereRadius, ArcDistance: Double); // @addr $4DE5B8 @note "Negative distance moves backward. Longitude and bearing pass through Single precision when wrapped."
function AdvanceSphericalStateOnCurrentSphere(Source: TSphericalBearingState; ArcDistance: Double): TSphericalBearingState; // @addr $4DE8FC
function AdvanceSphericalStateAlongBearing(Source: TSphericalBearingState; TravelBearingDegrees, ArcDistance: Double): TSphericalBearingState; // @addr $4DE944 @note "Uses the current sphere radius; preserves the body's bearing relative to travel."
function AdvanceSphericalStateAndTravelBearing(Source: TSphericalBearingState; var TravelBearingDegrees: Double; ArcDistance: Double): TSphericalBearingState; // @addr $4DE9BC @note "Uses the current sphere radius; updates travel bearing and preserves the body's bearing relative to it."
procedure ComputeSphericalBearingAndDistance(SourceLongitudeDegrees, SourcePolarAngleDegrees, SourceBearingDegrees, TargetLongitudeDegrees, TargetPolarAngleDegrees, SphereRadius: Double; var BearingDeltaDegrees, Distance: Double); // @addr $4DEA38 @note "Bearing is relative to SourceBearingDegrees; coincident points return zero bearing delta and distance."
procedure ComputeSphericalDistance(var Distance: Double; SourceLongitudeDegrees, SourcePolarAngleDegrees, UnusedSourceBearingDegrees, TargetLongitudeDegrees, TargetPolarAngleDegrees, SphereRadius: Double); // @addr $4DEC74
function GetSphericalBearingAndDistance(Source, Target: TSphericalBearingState): TSphericalBearingDistance; // @addr $4DEDA0 @note "Uses the current sphere radius; ignores Target.BearingDegrees."
procedure UpdateSphereProjectionMetrics; // @addr $4DEE08 @note "Uses the shared sphere radius, camera distance, field of view and projection scale."
function IsDepthBeforeSphereHorizon(ProjectedDepth: Double): Boolean; // @addr $4DF0C8 @note "Compares against the horizon depth set by UpdateSphereProjectionMetrics."

function NormalizeVector3D(const Source: TVector3D): TVector3D; // @addr $4DF0E0 @note "Requires a nonzero vector."
function CrossProduct3D(const A, B: TVector3D): TVector3D; // @addr $4DF130
function DotProduct3D(const A, B: TVector3D): Double; // @addr $4DF164

procedure ClearMatrix4D(var Matrix: TMatrix4D); // @addr $4DF188
procedure SetIdentityMatrix4D(var Matrix: TMatrix4D); // @addr $4DF1B0
function BuildZAxisRotationMatrix(AngleRadians: Double): TMatrix4D; // @addr $4DF240 @ida "void __userpurge $name(TMatrix4D *Result@<eax>, double AngleRadians@<^0>);" @note "Rotates clockwise in the XY plane for positive angles."
function BuildPerspectiveProjectionMatrix(NearPlane, FarPlane, FovRadians, ProjectionScale: Double): TMatrix4D; // @addr $4DF29C @ida "void __userpurge $name(TMatrix4D *Result@<eax>, double NearPlane@<^24>, double FarPlane@<^16>, double FovRadians@<^8>, double ProjectionScale@<^0>);" @note "Uses the same scale for X and Y; projects NearPlane to depth 0 and FarPlane to depth 1."
function BuildLookAtMatrix(const CameraPos, TargetPos, UpVector: TVector3D): TMatrix4D; // @addr $4DF32C @ida "void __userpurge $name(const TVector3D *CameraPos@<eax>, const TVector3D *TargetPos@<edx>, const TVector3D *UpVector@<ecx>, TMatrix4D *Result@<^0>);" @note "CameraPos must differ from TargetPos; UpVector must not be parallel to the viewing direction."
function InvertMatrix4D(const Matrix: TMatrix4D): TMatrix4D; // @addr $4DF87C @ida "void __usercall $name(const TMatrix4D *Matrix@<eax>, TMatrix4D *Result@<edx>);" @note "Does not report singularity; zero pivots are replaced by 1e-20."
function MultiplyMatrix4D(const Left, Right: TMatrix4D): TMatrix4D; // @addr $4DF920 @ida "void __usercall $name(const TMatrix4D *Left@<eax>, const TMatrix4D *Right@<edx>, TMatrix4D *Result@<ecx>);"
function ProjectPointByMatrix(const Matrix: TMatrix4D; const Source: TVector3D): TVector3D; // @addr $4DF9A0 @note "Includes perspective division; homogeneous W must be nonzero."

var
  ArcadeSpaceProcess: TProcessSE = nil; // @addr $618438
  ArcadeEditorMapVersion: Cardinal = 1; // @addr $61843C Version written by the retained editor save path.
  SphereRadius: Double = 1000; // @addr $618440
  SphereCameraDistance: Double = 2300; // @addr $618448
  SphereNearCameraOffset: Double = 1300.0; // @addr $618450
  SphereFarCameraOffset: Double = 20000.0; // @addr $618458
  SphereFieldOfView: Double = 88; // @addr $618460
  CameraFollowStep: Double = 14.0; // @addr $618468
  CameraLookAheadDistance: Double = 0.0; // @addr $618470
  PlayerDriftTurnStep: Single = 1.8; // @addr $618478
  PlayerInitialTurnSpeed: Single = 3.3; // @addr $61847C
  PlayerFastTurnSpeed: Single = 2.5; // @addr $618480
  PlayerSlowTurnSpeed: Single = 3.8; // @addr $618484
  SphereLowSpeedDrag: Single = 0.007; // @addr $618488
  SphereHighSpeedDrag: Single = 0.18; // @addr $61848C
  ArcadeMapNodeRadius: Integer = 60; // @addr $618490
  ArcadeMapPanMargin: Integer = 200; // @addr $618494
  ArcadeEditorMode: Boolean = False; // @addr $618498
  ArcadeViewMode: TArcadeViewMode = avmSpace; // @addr $61849C
  ArcadePathStep: Single = 4.0; // @addr $6184A0
  ArcadePathArcStep: Single = 4.0; // @addr $6184A4
  SphereProjectedRadius: Single = 1; // @addr $6184A8
  SphereNearHorizonDepth: Single = -1; // @addr $6184AC
  SphereHorizonDepth: Single = 0; // @addr $6184B0
  SphereFarHorizonDepth: Single = 1; // @addr $6184B4
  ShipFrontDepth: Single = 20.0; // @addr $6184B8
  ShipBackDepth: Single = 30.0; // @addr $6184BC
  ItemFrontDepth: Single = 21; // @addr $6184C0
  HitFrontDepth: Single = 19; // @addr $6184C4
  HitBackDepth: Single = 29; // @addr $6184C8
  WorldImageFrontDepth: Single = 22; // @addr $6184CC
  WorldImageBackDepth: Single = 28; // @addr $6184D0
  ExplosionFrontDepth: Single = 18; // @addr $6184D4
  ExplosionBackDepth: Single = 28; // @addr $6184D8
  ArcadeMapPalette: array[0..35] of Cardinal = (
    4280855552,
    2150149120,
    3223890944,
    2665472,
    3223890944,
    3238002687,
    4278205695,
    2147499263,
    3221241087,
    15615,
    3221241087,
    3238002687,
    4294967040,
    2164260608,
    3238002432,
    16776960,
    3238002432,
    3238002687,
    4294944310,
    2164237878,
    3237979702,
    16754230,
    3237979702,
    3238002687,
    4291297280,
    2160590848,
    3234332672,
    13107200,
    3234332672,
    3238002687,
    4289069099,
    2158362667,
    3232104491,
    10879019,
    3232104491,
    3238002687
  ); // @addr $6184DC
  BonusRespawnSeconds: array[0..5] of Integer = (40, 60, 80, 100, 100, 150); // @addr $61856C
  BonusDurationSeconds: array[0..7] of Integer = (12, 50, 40, 50, 40, 50, 60, 60); // @addr $618584
  RegenerationHealthPerTick: Integer = 1; // @addr $6185A4
  SpeedBonusScale: Single = 1.2; // @addr $6185A8
  SpeedPenaltyScale: Single = 0.7; // @addr $6185AC
  WeaponDamageBonusScale: Single = 1.5; // @addr $6185B0
  AmmoRechargeBonusScale: Single = 2; // @addr $6185B4
  ShieldDamageScale: Single = 0.4; // @addr $6185B8
  OtherInvisibleAlpha: Single = 0.2; // @addr $6185BC
  PlayerInvisibleAlpha: Single = 0.5; // @addr $6185C0
  RevealAfterFiringMs: Integer = 5500; // @addr $6185C4
  WeaponSwitchDelayMs: Integer = 1200; // @addr $6185C8
  ArcadeHighDangerThreshold: Single = 70; // @addr $6185CC
  ManualCargoPickupDistance: Single = 200.0; // @addr $6185D0 Item-info pickup ring and cursor threshold.
  CargoPickupDistance: Single = 80.0; // @addr $6185D4
  ArcadeTickCount: Integer; // @addr $61C9E4
  ArcadeFrameCount: Integer; // @addr $61C9E8
  ArcadeMapVersion: Cardinal; // @addr $61C9EC Second dword of the abwm map header.
  SphereViewState: TSphericalBearingState; // @addr $61C9F0 Visibility-cell selection uses longitude and polar angle.
  SphereViewMatrix: TMatrix4D; // @addr $61CA08
  SpherePerspectiveMatrix: TMatrix4D; // @addr $61CA88

var
  SphereProjectionMatrix: TMatrix4D; // @addr $61CB08
  ArcadeMapViewPosition: TPoint; // @addr $61CB88
  ArcadeMapCenter: TPoint; // @addr $61CB90
  ArcadeMapBounds: TRect; // @addr $61CB98
  ArcadeGridMode: Integer; // @addr $61CBA8

function TryIntersectRayWithSphere(RayOrigin, RayPointOnRay, SphereCenter: TVector3D; SphereRadius: Double; var HitPoint: TVector3D): Boolean; // @addr $4DFA20 @note "Ray points must differ. Rejects tangency. May write HitPoint on false; true requires forward distance greater than 0.001."

var
  ArcadeMapColorBuffer: TBufEC; // @addr $61CBAC
  ArcadeAutopilotEnabled: Boolean; // @addr $61CBB0
  ArcadeEnemiesDefeated: Boolean; // @addr $61CBB1

var
  ArcadeLastInputTick: Integer; // @addr $61CBB4

implementation

// @unit-initialization $4DFC0C
// @unit-finalization $4DFBDC

uses Math, aMyFunction, GR_Main;

{ @routine $4DE478 MakeSphericalBearingState }
function MakeSphericalBearingState(LongitudeDegrees, PolarAngleDegrees, BearingDegrees: Double): TSphericalBearingState;
begin
  Result.LongitudeDegrees := LongitudeDegrees;
  Result.PolarAngleDegrees := PolarAngleDegrees;
  Result.BearingDegrees := BearingDegrees;
end;
{ @end $4DE478 }

{ @routine $4DE4A4 SphericalToVector3D }
function SphericalToVector3D(LongitudeRadians, PolarAngleRadians, Radius: Double): TVector3D;
var V: TVector3D;
begin
  V.X := Sin(PolarAngleRadians) * Radius;
  V.Y := -Cos(PolarAngleRadians) * Radius;
  V.Z := 0;
  Result.X := Sin(LongitudeRadians) * V.X;
  Result.Y := V.Y;
  Result.Z := -Cos(LongitudeRadians) * V.X;
end;
{ @end $4DE4A4 }

{ @routine $4DE508 VectorToSphericalAngles }
procedure VectorToSphericalAngles(Vector: TVector3D; var LongitudeDegrees, PolarAngleDegrees: Double);
var Radius: Double;
begin
  Radius := Sqrt(Sqr(Vector.X) + Sqr(Vector.Y) + Sqr(Vector.Z));
  PolarAngleDegrees := RadiansToHeadingDegrees(ArcCos(-Vector.Y / Radius));
  LongitudeDegrees := RadiansToHeadingDegrees(Pi - ArcTan2(Vector.X, Vector.Z));
end;
{ @end $4DE508 }

{ @routine $4DE5B8 AdvanceSphericalBearingState }
procedure AdvanceSphericalBearingState(var LongitudeDegrees, PolarAngleDegrees, BearingDegrees: Double; SphereRadius, ArcDistance: Double);
var ArcAngle, NewPolar, OldPolar, LongitudeDelta, OldBearing, NewBearing, InvSin, Value: Double;
    Reverse: Boolean;
begin
  if ArcDistance < 0 then
  begin
    Reverse := True;
    ArcDistance := -ArcDistance;
    BearingDegrees := WrapHeadingDegrees(BearingDegrees + 180);
  end
  else Reverse := False;
  OldBearing := HeadingDegreesToRadians(BearingDegrees);
  ArcAngle := ArcDistance / (2 * Pi * SphereRadius) * Pi * 2;
  OldPolar := HeadingDegreesToRadians(PolarAngleDegrees);
  NewPolar := ArcCos(Cos(OldPolar) * Cos(ArcAngle) + Sin(OldPolar) * Sin(ArcAngle) * Cos(OldBearing));
  if NewPolar < 0.00001 then InvSin := 99999999
  else InvSin := 1 / Sin(NewPolar);
  Value := (Sin(OldPolar) * Cos(ArcAngle) - Cos(OldPolar) * Sin(ArcAngle) * Cos(OldBearing)) * InvSin;
  if Value < -1 then Value := -1
  else if Value > 1 then Value := 1;
  LongitudeDelta := ArcCos(Value);
  Value := (Sin(ArcAngle) * Cos(OldPolar) - Cos(ArcAngle) * Sin(OldPolar) * Cos(OldBearing)) * InvSin;
  if Value < -1 then Value := -1
  else if Value > 1 then Value := 1;
  NewBearing := ArcCos(Value);
  if BearingDegrees > 180 then
  begin
    BearingDegrees := WrapHeadingDegrees(RadiansToHeadingDegrees(Pi + NewBearing));
    LongitudeDegrees := WrapHeadingDegrees(LongitudeDegrees - RadiansToHeadingDegrees(LongitudeDelta));
  end
  else
  begin
    BearingDegrees := WrapHeadingDegrees(RadiansToHeadingDegrees(Pi - NewBearing));
    LongitudeDegrees := WrapHeadingDegrees(LongitudeDegrees + RadiansToHeadingDegrees(LongitudeDelta));
  end;
  PolarAngleDegrees := RadiansToHeadingDegrees(NewPolar);
  if Reverse then BearingDegrees := WrapHeadingDegrees(BearingDegrees + 180);
end;
{ @end $4DE5B8 }

{ @routine $4DE8FC AdvanceSphericalStateOnCurrentSphere }
function AdvanceSphericalStateOnCurrentSphere(Source: TSphericalBearingState; ArcDistance: Double): TSphericalBearingState;
begin
  Result := Source;
  AdvanceSphericalBearingState(Result.LongitudeDegrees, Result.PolarAngleDegrees, Result.BearingDegrees, SphereRadius, ArcDistance);
end;
{ @end $4DE8FC }

{ @routine $4DE944 AdvanceSphericalStateAlongBearing }
function AdvanceSphericalStateAlongBearing(Source: TSphericalBearingState; TravelBearingDegrees, ArcDistance: Double): TSphericalBearingState;
var RelativeBearing: Double;
begin
  Result := Source;
  RelativeBearing := HeadingDifferenceDegrees(TravelBearingDegrees, Result.BearingDegrees);
  AdvanceSphericalBearingState(Result.LongitudeDegrees, Result.PolarAngleDegrees, TravelBearingDegrees, SphereRadius, ArcDistance);
  Result.BearingDegrees := WrapHeadingDegrees(TravelBearingDegrees + RelativeBearing);
end;
{ @end $4DE944 }

{ @routine $4DE9BC AdvanceSphericalStateAndTravelBearing }
function AdvanceSphericalStateAndTravelBearing(Source: TSphericalBearingState; var TravelBearingDegrees: Double; ArcDistance: Double): TSphericalBearingState;
var RelativeBearing: Double;
begin
  Result := Source;
  RelativeBearing := HeadingDifferenceDegrees(TravelBearingDegrees, Result.BearingDegrees);
  AdvanceSphericalBearingState(Result.LongitudeDegrees, Result.PolarAngleDegrees, TravelBearingDegrees, SphereRadius, ArcDistance);
  Result.BearingDegrees := WrapHeadingDegrees(TravelBearingDegrees + RelativeBearing);
end;
{ @end $4DE9BC }

{ @routine $4DEA38 ComputeSphericalBearingAndDistance }
procedure ComputeSphericalBearingAndDistance(SourceLongitudeDegrees, SourcePolarAngleDegrees, SourceBearingDegrees, TargetLongitudeDegrees, TargetPolarAngleDegrees, SphereRadius: Double; var BearingDeltaDegrees, Distance: Double);
var ArcAngle, TargetPolar, SourcePolar, LongitudeDelta, Bearing, Value: Double;
begin
  TargetPolar := HeadingDegreesToRadians(TargetPolarAngleDegrees);
  SourcePolar := HeadingDegreesToRadians(SourcePolarAngleDegrees);
  LongitudeDelta := HeadingDegreesToRadians(WrapHeadingDegrees(TargetLongitudeDegrees - SourceLongitudeDegrees));
  Value := Cos(TargetPolar) * Cos(SourcePolar) + Sin(TargetPolar) * Sin(SourcePolar) * Cos(LongitudeDelta);
  if Value < -1 then Value := -1
  else if Value > 1 then Value := 1;
  ArcAngle := ArcCos(Value);
  Distance := ArcAngle / (2 * Pi) * 2 * Pi * SphereRadius;
  if ArcAngle = 0 then
  begin
    BearingDeltaDegrees := 0;
    Exit;
  end;
  Value := (Sin(SourcePolar) * Cos(TargetPolar) - Cos(SourcePolar) * Sin(TargetPolar) * Cos(LongitudeDelta)) / Sin(ArcAngle);
  if Value < -1 then Value := -1
  else if Value > 1 then Value := 1;
  Bearing := ArcCos(Value);
  if HeadingDifferenceDegrees(SourceLongitudeDegrees, TargetLongitudeDegrees) < 0 then Bearing := -Bearing;
  BearingDeltaDegrees := HeadingDifferenceDegrees(SourceBearingDegrees, RadiansToHeadingDegrees(Bearing));
end;
{ @end $4DEA38 }

{ @routine $4DEC74 ComputeSphericalDistance }
procedure ComputeSphericalDistance(var Distance: Double; SourceLongitudeDegrees, SourcePolarAngleDegrees, UnusedSourceBearingDegrees, TargetLongitudeDegrees, TargetPolarAngleDegrees, SphereRadius: Double);
var ArcAngle, TargetPolar, SourcePolar, LongitudeDelta, Value: Double;
begin
  TargetPolar := HeadingDegreesToRadians(TargetPolarAngleDegrees);
  SourcePolar := HeadingDegreesToRadians(SourcePolarAngleDegrees);
  LongitudeDelta := HeadingDegreesToRadians(WrapHeadingDegrees(TargetLongitudeDegrees - SourceLongitudeDegrees));
  Value := Cos(TargetPolar) * Cos(SourcePolar) + Sin(TargetPolar) * Sin(SourcePolar) * Cos(LongitudeDelta);
  if Value < -1 then Value := -1
  else if Value > 1 then Value := 1;
  ArcAngle := ArcCos(Value);
  Distance := ArcAngle / (2 * Pi) * 2 * Pi * SphereRadius;
end;
{ @end $4DEC74 }

{ @routine $4DEDA0 GetSphericalBearingAndDistance }
function GetSphericalBearingAndDistance(Source, Target: TSphericalBearingState): TSphericalBearingDistance;
begin
  ComputeSphericalBearingAndDistance(Source.LongitudeDegrees, Source.PolarAngleDegrees, Source.BearingDegrees,
    Target.LongitudeDegrees, Target.PolarAngleDegrees, SphereRadius, Result.BearingDeltaDegrees, Result.Distance);
end;
{ @end $4DEDA0 }

{ @routine $4DEE08 UpdateSphereProjectionMetrics }
procedure UpdateSphereProjectionMetrics;
var Angle: Double;
    V, Target, Up: TVector3D;
    View, Projection, Combined: TMatrix4D;
begin
  V := MakeVector3D(0, 0, SphereCameraDistance);
  Target := MakeVector3D(0, 0, 0);
  Up := MakeVector3D(0, 1, 0);
  View := BuildLookAtMatrix(V, Target, Up);
  Projection := BuildPerspectiveProjectionMatrix(SphereCameraDistance - SphereRadius - 100,
    SphereCameraDistance + SphereRadius + 100, HeadingDegreesToRadians(SphereFieldOfView), Cardinal(GameScreenWidth));
  Combined := MultiplyMatrix4D(Projection, View);
  Angle := 90 - (90 - RadiansToHeadingDegrees(ArcSin(SphereRadius / SphereCameraDistance)));
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereHorizonDepth := V.Z;
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle - 15)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereNearHorizonDepth := V.Z;
  V := MakeVector3D(0, 0, Sin(HeadingDegreesToRadians(Angle + 15)) * SphereRadius);
  V := ProjectPointByMatrix(Combined, V);
  SphereFarHorizonDepth := V.Z;
  V := MakeVector3D(SphereRadius, 0, 0);
  V := ProjectPointByMatrix(Combined, V);
  SphereProjectedRadius := Max(Abs(V.X), Abs(V.Y));
end;
{ @end $4DEE08 }

{ @routine $4DF0C8 IsDepthBeforeSphereHorizon }
function IsDepthBeforeSphereHorizon(ProjectedDepth: Double): Boolean;
begin
  Result := ProjectedDepth < SphereHorizonDepth;
end;
{ @end $4DF0C8 }

{ @routine $4DF0E0 NormalizeVector3D }
function NormalizeVector3D(const Source: TVector3D): TVector3D;
var Scale: Double;
begin
  Scale := 1.0 / Sqrt(Source.X * Source.X + Source.Y * Source.Y + Source.Z * Source.Z);
  Result.X := Source.X * Scale;
  Result.Y := Source.Y * Scale;
  Result.Z := Source.Z * Scale;
end;
{ @end $4DF0E0 }

{ @routine $4DF130 CrossProduct3D }
function CrossProduct3D(const A, B: TVector3D): TVector3D;
begin
  Result.X := A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.Z * B.X - A.X * B.Z;
  Result.Z := A.X * B.Y - A.Y * B.X;
end;
{ @end $4DF130 }

{ @routine $4DF164 DotProduct3D }
function DotProduct3D(const A, B: TVector3D): Double;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;
{ @end $4DF164 }

{ @routine $4DF188 ClearMatrix4D }
procedure ClearMatrix4D(var Matrix: TMatrix4D);
var I, J: Integer;
begin
  for I := 0 to 3 do
    for J := 0 to 3 do Matrix[I, J] := 0;
end;
{ @end $4DF188 }

{ @routine $4DF1B0 SetIdentityMatrix4D }
procedure SetIdentityMatrix4D(var Matrix: TMatrix4D);
begin
  Matrix[0, 0] := 1; Matrix[1, 0] := 0; Matrix[2, 0] := 0; Matrix[3, 0] := 0;
  Matrix[0, 1] := 0; Matrix[1, 1] := 1; Matrix[2, 1] := 0; Matrix[3, 1] := 0;
  Matrix[0, 2] := 0; Matrix[1, 2] := 0; Matrix[2, 2] := 1; Matrix[3, 2] := 0;
  Matrix[0, 3] := 0; Matrix[1, 3] := 0; Matrix[2, 3] := 0; Matrix[3, 3] := 1;
end;
{ @end $4DF1B0 }

{ @routine $4DF240 BuildZAxisRotationMatrix }
function BuildZAxisRotationMatrix(AngleRadians: Double): TMatrix4D;
var C, S: Double;
begin
  C := Cos(AngleRadians);
  S := Sin(AngleRadians);
  SetIdentityMatrix4D(Result);
  Result[0, 0] := C;
  Result[1, 1] := C;
  Result[0, 1] := -S;
  Result[1, 0] := S;
end;
{ @end $4DF240 }

{ @routine $4DF29C BuildPerspectiveProjectionMatrix }
function BuildPerspectiveProjectionMatrix(NearPlane, FarPlane, FovRadians, ProjectionScale: Double): TMatrix4D;
var C, S, Q: Double;
begin
  C := Cos(FovRadians * 0.5);
  S := Sin(FovRadians * 0.5);
  Q := S / (1.0 - NearPlane / FarPlane);
  ClearMatrix4D(Result);
  Result[0, 0] := C * ProjectionScale;
  Result[1, 1] := C * ProjectionScale;
  Result[2, 2] := Q;
  Result[3, 2] := -Q * NearPlane;
  Result[2, 3] := S;
end;
{ @end $4DF29C }

{ @routine $4DF32C BuildLookAtMatrix }
function BuildLookAtMatrix(const CameraPos, TargetPos, UpVector: TVector3D): TMatrix4D;
var Forward, Right, Up: TVector3D;
begin
  SetIdentityMatrix4D(Result);
  Forward := MakeVector3D(TargetPos.X - CameraPos.X, TargetPos.Y - CameraPos.Y, TargetPos.Z - CameraPos.Z);
  Forward := NormalizeVector3D(Forward);
  Right := CrossProduct3D(UpVector, Forward);
  Up := CrossProduct3D(Forward, Right);
  Right := NormalizeVector3D(Right);
  Up := NormalizeVector3D(Up);
  Result[0, 0] := Right.X; Result[1, 0] := Right.Y; Result[2, 0] := Right.Z;
  Result[0, 1] := Up.X; Result[1, 1] := Up.Y; Result[2, 1] := Up.Z;
  Result[0, 2] := Forward.X; Result[1, 2] := Forward.Y; Result[2, 2] := Forward.Z;
  Result[3, 0] := -DotProduct3D(Right, CameraPos);
  Result[3, 1] := -DotProduct3D(Up, CameraPos);
  Result[3, 2] := -DotProduct3D(Forward, CameraPos);
end;
{ @end $4DF32C }

{ @routine $4DF87C InvertMatrix4D }
function InvertMatrix4D(const Matrix: TMatrix4D): TMatrix4D;
var Permutations: array[0..3] of Integer;
    Solution: array[0..3] of Double;
    I, J: Integer;
    PermutationSign: Double;
    Factors: TMatrix4D;

  // @nested $4DF484 SolveMatrix4DLuSystem
  procedure SolveMatrix4DLuSystem(const Factors: TMatrix4D); // @addr $4DF484
  var I, J, FirstNonzero, Pivot: Integer;
      Sum: Double;
  begin
    FirstNonzero := -1;
    for I := 0 to 3 do
    begin
      Pivot := Permutations[I];
      Sum := Solution[Pivot];
      Solution[Pivot] := Solution[I];
      if FirstNonzero >= 0 then
        for J := FirstNonzero to I - 1 do Sum := Sum - Factors[I, J] * Solution[J]
      else if Sum <> 0 then FirstNonzero := I;
      Solution[I] := Sum;
    end;
    for I := 3 downto 0 do
    begin
      Sum := Solution[I];
      for J := I + 1 to 3 do Sum := Sum - Factors[I, J] * Solution[J];
      Solution[I] := Sum / Factors[I, I];
    end;
  end;

  // @nested $4DF5CC DecomposeMatrix4DLu
  procedure DecomposeMatrix4DLu(var Matrix: TMatrix4D; var PermutationSign: Double); // @addr $4DF5CC
  var Big, Temp, Sum, Magnitude: Double;
      I, Pivot, J, K: Integer;
      Scales: array[0..3] of Double;
  begin
    PermutationSign := 1;
    for I := 0 to 3 do
    begin
      Big := 0;
      for J := 0 to 3 do
      begin
        Magnitude := Abs(Matrix[I, J]);
        if Magnitude > Big then Big := Magnitude;
      end;
      Scales[I] := 1 / Big;
    end;
    for J := 0 to 3 do
    begin
      I := 0;
      while I < J do
      begin
        Sum := Matrix[I, J];
        K := 0;
        while K < I do
        begin
          Sum := Sum - Matrix[I, K] * Matrix[K, J];
          Inc(K);
        end;
        Matrix[I, J] := Sum;
        Inc(I);
      end;
      Pivot := 0;
      Big := 0;
      for I := J to 3 do
      begin
        Sum := Matrix[I, J];
        K := 0;
        while K < J do
        begin
          Sum := Sum - Matrix[I, K] * Matrix[K, J];
          Inc(K);
        end;
        Matrix[I, J] := Sum;
        Temp := Abs(Sum) * Scales[I];
        if Temp >= Big then
        begin
          Big := Temp;
          Pivot := I;
        end;
      end;
      if J <> Pivot then
      begin
        for K := 0 to 3 do
        begin
          Temp := Matrix[Pivot, K];
          Matrix[Pivot, K] := Matrix[J, K];
          Matrix[J, K] := Temp;
        end;
        PermutationSign := -PermutationSign;
        Scales[Pivot] := Scales[J];
      end;
      Permutations[J] := Pivot;
      if Matrix[J, J] = 0 then Matrix[J, J] := 1E-20;
      if J <> 3 then
      begin
        Temp := 1 / Matrix[J, J];
        for I := J + 1 to 3 do Matrix[I, J] := Matrix[I, J] * Temp;
      end;
    end;
  end;

begin
  Factors := Matrix;
  DecomposeMatrix4DLu(Factors, PermutationSign);
  for J := 0 to 3 do
  begin
    for I := 0 to 3 do Solution[I] := 0;
    Solution[J] := 1;
    SolveMatrix4DLuSystem(Factors);
    for I := 0 to 3 do Result[I, J] := Solution[I];
  end;
end;
{ @end $4DF87C }

{ @routine $4DF920 MultiplyMatrix4D }
function MultiplyMatrix4D(const Left, Right: TMatrix4D): TMatrix4D;
var I, J, K: Integer;
begin
  ClearMatrix4D(Result);
  for I := 0 to 3 do
    for J := 0 to 3 do
      for K := 0 to 3 do
        Result[I, J] := Result[I, J] + Left[K, J] * Right[I, K];
end;
{ @end $4DF920 }

{ @routine $4DF9A0 ProjectPointByMatrix }
function ProjectPointByMatrix(const Matrix: TMatrix4D; const Source: TVector3D): TVector3D;
// Handwritten native x87: no frame and no intermediate stores.
asm
  push ebx
  push edx
  push ecx
  mov ebx, edx
  mov edx, eax
  mov ecx, ecx
  fld qword ptr [ebx+$10]
  fld qword ptr [ebx+$08]
  fld qword ptr [ebx]
  fld qword ptr [edx+$18]
  fmul st, st(1)
  fld qword ptr [edx+$38]
  fmul st, st(3)
  faddp st(1), st
  fld qword ptr [edx+$58]
  fmul st, st(4)
  faddp st(1), st
  fadd qword ptr [edx+$78]
  fld1
  fdivrp st(1), st
  fld qword ptr [edx]
  fmul st, st(2)
  fld qword ptr [edx+$20]
  fmul st, st(4)
  faddp st(1), st
  fld qword ptr [edx+$40]
  fmul st, st(5)
  faddp st(1), st
  fadd qword ptr [edx+$60]
  fmul st, st(1)
  fstp qword ptr [ecx]
  fld qword ptr [edx+$08]
  fmul st, st(2)
  fld qword ptr [edx+$28]
  fmul st, st(4)
  faddp st(1), st
  fld qword ptr [edx+$48]
  fmul st, st(5)
  faddp st(1), st
  fadd qword ptr [edx+$68]
  fmul st, st(1)
  fstp qword ptr [ecx+$08]
  fld qword ptr [edx+$10]
  fmulp st(2), st
  fld qword ptr [edx+$30]
  fmulp st(3), st
  fld qword ptr [edx+$50]
  fmulp st(4), st
  fxch st(3)
  fadd qword ptr [edx+$70]
  faddp st(1), st
  faddp st(1), st
  fmulp st(1), st
  fstp qword ptr [ecx+$10]
  pop ecx
  pop edx
  pop ebx
end;
{ @end $4DF9A0 }

{ @routine $4DFA20 TryIntersectRayWithSphere }
function TryIntersectRayWithSphere(RayOrigin, RayPointOnRay, SphereCenter: TVector3D; SphereRadius: Double; var HitPoint: TVector3D): Boolean;
var T, OtherT, Projection, Discriminant, DistanceSquared: Double;
    Direction, CenterDelta: TVector3D;
begin
  Direction.X := RayPointOnRay.X - RayOrigin.X;
  Direction.Y := RayPointOnRay.Y - RayOrigin.Y;
  Direction.Z := RayPointOnRay.Z - RayOrigin.Z;
  T := 1 / Sqrt(Direction.X * Direction.X + Direction.Y * Direction.Y + Direction.Z * Direction.Z);
  Direction.X := Direction.X * T;
  Direction.Y := Direction.Y * T;
  Direction.Z := Direction.Z * T;
  CenterDelta.X := SphereCenter.X - RayOrigin.X;
  CenterDelta.Y := SphereCenter.Y - RayOrigin.Y;
  CenterDelta.Z := SphereCenter.Z - RayOrigin.Z;
  DistanceSquared := CenterDelta.X * CenterDelta.X + CenterDelta.Y * CenterDelta.Y + CenterDelta.Z * CenterDelta.Z;
  Projection := CenterDelta.X * Direction.X + CenterDelta.Y * Direction.Y + CenterDelta.Z * Direction.Z;
  Discriminant := Sqr(SphereRadius) - DistanceSquared + Projection * Projection;
  if Discriminant <= 0 then
  begin
    Result := False;
    Exit;
  end;
  Discriminant := Sqrt(Discriminant);
  if Projection < Discriminant then
  begin
    T := Projection + Discriminant;
    OtherT := Projection - Discriminant;
  end
  else
  begin
    T := Projection - Discriminant;
    OtherT := Projection + Discriminant;
  end;
  if Abs(T) < 0.001 then T := OtherT;
  HitPoint.X := Direction.X * T + RayOrigin.X;
  HitPoint.Y := Direction.Y * T + RayOrigin.Y;
  HitPoint.Z := Direction.Z * T + RayOrigin.Z;
  Result := T > 0.001;
end;
{ @end $4DFA20 }

end.

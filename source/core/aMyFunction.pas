unit aMyFunction;
// Unit bracket (inferred): CODE 0x004C3E8C..0x004C556F; inclusive evidence, not full bounds.

interface

uses EC_Struct, Classes, Types;

type
  TPolarPoint = record // @size $10  Natural Double alignment is visible in TPlanet.PredictPosition locals.
    AngleDegrees: Double; // @offset $00  Clockwise from the negative Y axis.
    Radius: Double; // @offset $08
  end;

  TPolarRadiansPoint = packed record // @size $10
    AngleRadians: Double; // @offset $00
    Radius: Double; // @offset $08
  end;

type
  TObjectList = class(TList) // @size $14
  public
    destructor Destroy; override; // @addr $4C3EF4
    procedure FreeItems; // @addr $4C3F20 @note "Inherited Clear/Delete do not free objects."
  end;

// Integer ranges include both endpoints and accept either endpoint order.
// Seeded helpers read the supplied seed; Next helpers advance it.
function RandomIntRange(BoundA, BoundB: Integer): Integer; // @addr $4C3F5C @note "Accepts either endpoint order."
function SeededRandomIntRange(BoundA, BoundB: Integer; Seed: Cardinal): Integer; // @addr $4C3F84
function SeededRandomUnitFloat(Seed: Cardinal): Single; // @addr $4C3FB0
function RandomFloatRange(BoundA, BoundB: Double): Double; // @addr $4C3FE4 @note "Endpoints are quantized as Trunc(bound*1000+1)/1000; results have 0.001 resolution."
function SeededRandomFloatRange(Seed: Cardinal; BoundA, BoundB: Double): Double; // @addr $4C403C
function StepRandomSeed(Seed: Cardinal): Cardinal; // @addr $4C4098
function AdvanceRandomSeed(var Seed: Cardinal): Cardinal; // @addr $4C40A4
function NextRandomIntRange(BoundA, BoundB: Integer; var Seed: Cardinal): Integer; // @addr $4C40C8
function NextRandomFloatRange(BoundA, BoundB: Double; var Seed: Cardinal): Double; // @addr $4C4110
function NextRandomUnitFloat(var Seed: Cardinal): Double; // @addr $4C4188
function RemapClamped(Value, InMin, InMax, OutMin, OutMax: Double): Double; // @addr $4C4F38

function RoundAndTruncateToTens(Value: Double): Integer; // @addr $4C41F8 @note "Round(Value), then signed integer division by ten and multiplication by ten."

function FactorialProduct(Bound: Double): Extended; // @addr $4C4DD4 Multiplies Double factors 2, 3, ... up to Bound into an Extended accumulator.

function PointDistanceSquared(PointA, PointB: TPointF): Single; // @addr $4C4E40
function PolarToPoint(Polar: TPolarPoint): TPointF; // @addr $4C42C4 @note "Copies the 16-byte input; X = sin(angle)*radius, Y = -cos(angle)*radius."
function PointDistance(PointA, PointB: TPointF): Double; // @addr $4C4E90
function RadiansToHeadingDegrees(Angle: Double): Double; // @addr $4C4348 @note "Adds 360 only once for negative angles; does not fully normalize arbitrary inputs."
function HeadingDegreesToRadians(Angle: Double): Double; // @addr $4C4394 @note "Subtracts 360 only once for angles above 180; does not fully normalize arbitrary inputs."
function PointBearingDegrees(PointA, PointB: TPointF): Double; // @addr $4C43E0 @note "Bearing from A to B: zero points upward and angles increase clockwise in screen coordinates."
function HeadingDifferenceDegrees(FromHeading, ToHeading: Double): Double; // @addr $4C4434 @note "Signed shortest turn from FromHeading to ToHeading; requires headings normalized to [0,360)."
function WrapHeadingDegrees(Angle: Single): Single; // @addr $4C44A0 @note "Repeatedly adds or subtracts 360 to reach [0,360); requires a finite value small enough for Single-precision steps to change it."

// Markup color tags used with the formatting family below.
const
  HighlightColorTag = '<color=255,245,80>';
  ColorEndTag = '</color>';
  GreenColorTag = '<color=0,255,0>';
  YellowColorTag = '<color=254,217,7>';
  RedColorTag = '<color=255,0,0>';

// Original unit ownership of this formatting family (aMyFunction/MessageText) is unresolved.
// ColorTag is a complete opening tag; empty disables coloring. Replacements are
// case-sensitive and append </color> even when the replacement text is empty.
procedure ReplaceTextToken(var Text: WideString; Token, Replacement, ColorTag: WideString); // @addr $4C4FF8
function ReplaceColoredToken(Text, Token, Replacement, ColorTag: WideString): WideString; // @addr $4C50BC
function FormatText1(Text, ColorTag, Token, Replacement: WideString): WideString; // @addr $4C5178
// Multiple replacements run in order, including matches in text inserted earlier.
function FormatText2(Text, ColorTag, Token1, Replacement1, Token2, Replacement2: WideString): WideString; // @addr $4C5234
function FormatText3(Text, ColorTag, Token1, Replacement1, Token2, Replacement2, Token3, Replacement3: WideString): WideString; // @addr $4C5338
function WrapTextInColor(Text, ColorTag: WideString): WideString; // @addr $4C5478 @note "An empty color tag leaves Text unchanged."

function DecrementWrappedValue(Value, Minimum, Maximum: Integer): Integer; // @addr $4C5528 Returns a decremented value, wrapping below Minimum to Maximum. Value is passed by value.
function IncrementWrapped(var Value: Integer; Minimum, Maximum: Integer): Integer; // @addr $4C5514 @note "Increments Value, or resets it to Minimum when Value + 1 exceeds Maximum; returns the updated value."

function FractionalQuotient(Numerator, Denominator: Integer): Double; // @addr $4C41C8
function PointFromRadiusAngle(Radius, Angle: Single): TPointF; // @addr $4C4218 @note "Angle is in radians, measured from the positive X axis."
function OffsetPointByRadiusAngle(Origin: TPointF; Radius, Angle: Single): TPointF; // @addr $4C4238
function RotateAndTranslatePoint(Point, Translation: TPointF; Angle: Single): TPointF; // @addr $4C4270
function HeadingDegreesToByte(Angle: Double): Byte; // @addr $4C42FC
function ByteToHeadingDegrees(Angle: Byte): Double; // @addr $4C4320
function HeadingWithinArc(ArcStart, Heading, ArcEnd: Single): Boolean; // @addr $4C44F4
function RotatePointQuarterTurn(Center, Point: TPointF): TPointF; // @addr $4C4664
function IntersectLines(A1, A2, B1, B2: TPointF; out Intersection: TPointF): Boolean; // @addr $4C469C
function CalculateTangentArcOffset(StartPoint, EndPoint: TPointF; Heading, Angle: Double): Double; // @addr $4C4B84 @note "Returns sin(Angle) times the radius of the circle through the endpoints tangent to Heading at StartPoint; angles are degrees."
procedure CircleTangentPoints(Point: TPointF; Radius: Single; out LeftPoint, RightPoint: TPointF); // @addr $4C4CA4
function PointBehindHeading(Origin: TPointF; Heading, Distance: Double; Seed: Cardinal): TPointF; // @addr $4C4D54 @note "Seed selects a heading offset in [90,269] degrees without advancing."
function IntegerPointDistancePlusOne(PointA, PointB: TPoint): Integer; // @addr $4C4EE0

const
  PolarDegreesToRadians: Single = 0.01745329238474369049; // @addr $61840C

function SegmentIntersectsRectEdges(StartPoint, EndPoint, TopLeft, BottomRight: TPointF; out Intersection: TPointF): Boolean; // @addr $4C477C @note "Tests top, bottom, left, then right; returns the first edge hit, not the nearest. Corners must be ordered."

// A second native copy has identical instructions; its original name is unknown.
function RemapClampedAlternate(Value, InMin, InMax, OutMin, OutMax: Double): Double; // @addr $4C4F98

function ReadByteValue(var Value): Byte; // @addr $4C4F30 @note "Reads the first byte of an ordinal field."
procedure WriteByteValue(Value: Byte; var Destination); // @addr $4C4F34 @note "Writes the first byte of an ordinal field."

function PushPointOutsideCircleBand(Point: TPointF; Radius, Margin: Single): TPointF; // @addr $4C45F4 @note "Within Margin of Radius, scales Point to Radius+Margin; otherwise returns Point."

function SegmentCrossesOriginCircle(StartPoint, EndPoint: TPointF; Radius: Single): Boolean; // @addr $4C4954 @note "Requires both endpoints outside and segment length at least the start's distance from the origin."

function RayIntersectsOriginCircle(StartPoint, ThroughPoint: TPointF; out Intersection: TPointF; Radius: Single): Boolean; // @addr $4C4A30 @note "Normalizes the ray direction, rejects tangencies, and returns whether the selected intersection is ahead of StartPoint. No segment-length bound."

implementation

// @unit-initialization $4C5568
// @unit-finalization $4C5538

uses EC_Str, Math;

{ @routine $4C3EF4 TObjectList_Destroy }
destructor TObjectList.Destroy;
begin
  FreeItems;
  inherited Destroy;
end;
{ @end $4C3EF4 }

{ @routine $4C3F20 TObjectList_FreeItems }
procedure TObjectList.FreeItems;
var
  i: Integer;
  Item: TObject;
begin
  for i := Count - 1 downto 0 do
    if TObject(List^[i]) <> nil then
    begin
      Item := TObject(List^[i]);
      Delete(i);
      Item.Free;
    end;
  Clear;
end;
{ @end $4C3F20 }

{ @routine $4C3F5C RandomIntRange }
function RandomIntRange(BoundA, BoundB: Integer): Integer;
begin
  if BoundA <= BoundB then Result := Random(BoundB - BoundA + 1) + BoundA
  else Result := Random(BoundA - BoundB + 1) + BoundB;
end;
{ @end $4C3F5C }

{ @routine $4C3F84 SeededRandomIntRange }
function SeededRandomIntRange(BoundA, BoundB: Integer; Seed: Cardinal): Integer;
begin
  if BoundA < BoundB then Result := Seed mod Cardinal(BoundB - BoundA + 1) + BoundA
  else Result := Seed mod Cardinal(BoundA - BoundB + 1) + BoundB;
end;
{ @end $4C3F84 }

{ @routine $4C3FB0 SeededRandomUnitFloat }
function SeededRandomUnitFloat(Seed: Cardinal): Single;
begin
  Result := SeededRandomIntRange(1, 1000, Seed) / 1000;
end;
{ @end $4C3FB0 }

{ @routine $4C3FE4 RandomFloatRange }
function RandomFloatRange(BoundA, BoundB: Double): Double;
begin
  Result := RandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1)) / 1000;
end;
{ @end $4C3FE4 }

{ @routine $4C403C SeededRandomFloatRange }
function SeededRandomFloatRange(Seed: Cardinal; BoundA, BoundB: Double): Double;
begin
  Result := SeededRandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1), Seed) / 1000;
end;
{ @end $4C403C }

{ @routine $4C4098 StepRandomSeed }
function StepRandomSeed(Seed: Cardinal): Cardinal;
begin
  Result := Seed * 7981 + 567;
end;
{ @end $4C4098 }

{ @routine $4C40A4 AdvanceRandomSeed }
function AdvanceRandomSeed(var Seed: Cardinal): Cardinal;

begin

    Seed := Seed * 7981 + 567 + Seed div 7981;

    Result := Seed;
end;
{ @end $4C40A4 }

{ @routine $4C40C8 NextRandomIntRange }
function NextRandomIntRange(BoundA, BoundB: Integer; var Seed: Cardinal): Integer;

begin

    Seed := Seed * 7981 + 567 + Seed div 7981;

    if BoundA < BoundB then Result := Seed mod Cardinal(BoundB - BoundA + 1) + BoundA
    else Result := Seed mod Cardinal(BoundA - BoundB + 1) + BoundB;
end;
{ @end $4C40C8 }

{ @routine $4C4110 NextRandomFloatRange }
function NextRandomFloatRange(BoundA, BoundB: Double; var Seed: Cardinal): Double;

begin

    Seed := Seed * 7981 + 567 + Seed div 7931;

    Result := SeededRandomIntRange(Trunc(BoundA * 1000 + 1), Trunc(BoundB * 1000 + 1), Seed) / 1000;
end;
{ @end $4C4110 }

{ @routine $4C4188 NextRandomUnitFloat }
function NextRandomUnitFloat(var Seed: Cardinal): Double;

begin

    Seed := Seed * 7981 + 5671;

    Result := Frac(Seed / 10011001);
end;
{ @end $4C4188 }

{ @routine $4C41C8 FractionalQuotient }
function FractionalQuotient(Numerator, Denominator: Integer): Double;
begin
  Result := Frac(Numerator / Denominator);
end;
{ @end $4C41C8 }

{ @routine $4C41F8 RoundAndTruncateToTens }
function RoundAndTruncateToTens(Value: Double): Integer;
begin
  Result := (Round(Value) div 10) * 10;
end;
{ @end $4C41F8 }

{ @routine $4C4218 PointFromRadiusAngle }
function PointFromRadiusAngle(Radius, Angle: Single): TPointF;
begin
  asm
  fld Angle
  fsincos
  mov eax, Result
  fld Radius
  fmul st(1), st(0)
  fmulp st(2), st(0)
  fstp [eax].TPointF.X
  fstp [eax].TPointF.Y
  end;
end;
{ @end $4C4218 }

{ @routine $4C4238 OffsetPointByRadiusAngle }
function OffsetPointByRadiusAngle(Origin: TPointF; Radius, Angle: Single): TPointF;
begin
  asm
  fld Angle
  fsincos
  mov eax, Result
  fld Radius
  fmul st(1), st(0)
  fmulp st(2), st(0)
  fld Origin.X
  faddp st(1), st(0)
  fstp [eax].TPointF.X
  fld Origin.Y
  faddp st(1), st(0)
  fstp [eax].TPointF.Y
  end;
end;
{ @end $4C4238 }

{ @routine $4C4270 RotateAndTranslatePoint }
function RotateAndTranslatePoint(Point, Translation: TPointF; Angle: Single): TPointF;
begin
  asm
  fld Angle
  fsincos
  fxch st(1)
  mov eax, Result
  fld Point.X
  fmul st(0), st(2)
  fld Point.Y
  fmul st(0), st(2)
  fchs
  faddp st(1), st(0)
  fld Translation.X
  faddp st(1), st(0)
  fstp [eax].TPointF.X
  fld Point.Y
  fmulp st(2), st(0)
  fld Point.X
  fmulp st(1), st(0)
  faddp st(1), st(0)
  fld Translation.Y
  faddp st(1), st(0)
  fstp [eax].TPointF.Y
  end;
end;
{ @end $4C4270 }

{ @routine $4C42C4 PolarToPoint }
function PolarToPoint(Polar: TPolarPoint): TPointF;
begin
  asm
  fld Polar.AngleDegrees
  fld PolarDegreesToRadians
  fmulp st(1), st(0)
  fsincos
  mov eax, Result
  fld Polar.Radius
  fmul st(1), st(0)
  fmulp st(2), st(0)
  fchs
  fstp [eax].TPointF.Y
  fstp [eax].TPointF.X
  end;
end;
{ @end $4C42C4 }

{ @routine $4C42FC HeadingDegreesToByte }
function HeadingDegreesToByte(Angle: Double): Byte;
begin
  Result := Round(Angle * 256 / 360);
end;
{ @end $4C42FC }

{ @routine $4C4320 ByteToHeadingDegrees }
function ByteToHeadingDegrees(Angle: Byte): Double;
begin
  Result := Angle * (360 / 256);
end;
{ @end $4C4320 }

{ @routine $4C4348 RadiansToHeadingDegrees }
function RadiansToHeadingDegrees(Angle: Double): Double;
begin
  Result := Angle * (180 / 3.1415926);
  if Result < 0 then Result := 360 + Result;
end;
{ @end $4C4348 }

{ @routine $4C4394 HeadingDegreesToRadians }
function HeadingDegreesToRadians(Angle: Double): Double;
begin
  if Angle > 180 then Angle := Angle - 360;
  Result := Angle * (3.1415926 / 180);
end;
{ @end $4C4394 }

{ @routine $4C43E0 PointBearingDegrees }
function PointBearingDegrees(PointA, PointB: TPointF): Double;
begin
  Result := RadiansToHeadingDegrees(ArcTan2(PointB.X - PointA.X, -(PointB.Y - PointA.Y)));
end;
{ @end $4C43E0 }

{ @routine $4C4434 HeadingDifferenceDegrees }
function HeadingDifferenceDegrees(FromHeading, ToHeading: Double): Double;
begin
  Result := ToHeading - FromHeading;
  if FromHeading < 180 then
  begin
    if Result > 180 then Result := Result - 360;
  end
  else if Result < -180 then Result := 360 + Result;
end;
{ @end $4C4434 }

{ @routine $4C44A0 WrapHeadingDegrees }
function WrapHeadingDegrees(Angle: Single): Single;
begin
  while Angle >= 360 do Angle := Angle - 360;
  while Angle < 0 do Angle := 360 + Angle;
  Result := Angle;
end;
{ @end $4C44A0 }

{ @routine $4C44F4 HeadingWithinArc }
function HeadingWithinArc(ArcStart, Heading, ArcEnd: Single): Boolean;
var A, B: Single;
begin
  A := HeadingDifferenceDegrees(ArcStart, Heading);
  B := HeadingDifferenceDegrees(ArcStart, ArcEnd);
  if ((A < 0) and (B > 0)) or ((A > 0) and (B < 0)) then
  begin
    Result := False;
    Exit;
  end;
  A := HeadingDifferenceDegrees(ArcEnd, Heading);
  B := HeadingDifferenceDegrees(ArcEnd, ArcStart);
  if ((A < 0) and (B > 0)) or ((A > 0) and (B < 0)) then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;
{ @end $4C44F4 }

{ @routine $4C45F4 PushPointOutsideCircleBand }
function PushPointOutsideCircleBand(Point: TPointF; Radius, Margin: Single): TPointF;
var Distance: Single;
begin
  Distance := Sqrt(Point.X * Point.X + Point.Y * Point.Y);
  if Abs(Radius - Distance) <= Margin then
  begin
    Result.X := (Point.X / Distance) * (Radius + Margin);
    Result.Y := (Point.Y / Distance) * (Radius + Margin);
  end
  else Result := Point;
end;
{ @end $4C45F4 }

{ @routine $4C4664 RotatePointQuarterTurn }
function RotatePointQuarterTurn(Center, Point: TPointF): TPointF;
begin
  Result.X := Center.X - (Point.Y - Center.Y);
  Result.Y := Point.X - Center.X + Center.Y;
end;
{ @end $4C4664 }

{ @routine $4C469C IntersectLines }
function IntersectLines(A1, A2, B1, B2: TPointF; out Intersection: TPointF): Boolean;
var AX, AY, BX, BY, Divisor: Double;
begin
  AX := A2.X - A1.X;
  AY := A2.Y - A1.Y;
  BX := B2.X - B1.X;
  BY := B2.Y - B1.Y;
  Divisor := AY * BX - BY * AX;
  if Divisor = 0 then
  begin
    Result := False;
    Exit;
  end;
  Intersection.X := ((B1.Y - A1.Y) * AX * BX + AY * BX * A1.X - BY * AX * B1.X) / Divisor;
  if AX <> 0 then Intersection.Y := (Intersection.X - A1.X) * AY / AX + A1.Y
  else Intersection.Y := (Intersection.X - B1.X) * BY / BX + B1.Y;
  Result := True;
end;
{ @end $4C469C }

{ @routine $4C477C SegmentIntersectsRectEdges }
function SegmentIntersectsRectEdges(StartPoint, EndPoint, TopLeft, BottomRight: TPointF; out Intersection: TPointF): Boolean;
var A, B: TPointF;
begin
  A.X := TopLeft.X;
  A.Y := TopLeft.Y;
  B.X := BottomRight.X;
  B.Y := TopLeft.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.X >= A.X) and (Intersection.X <= B.X) and
      (Intersection.Y >= Min(StartPoint.Y, EndPoint.Y)) and
      (Intersection.Y <= Max(StartPoint.Y, EndPoint.Y)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := TopLeft.X;
  A.Y := BottomRight.Y;
  B.X := BottomRight.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.X >= A.X) and (Intersection.X <= B.X) and
      (Intersection.Y >= Min(StartPoint.Y, EndPoint.Y)) and
      (Intersection.Y <= Max(StartPoint.Y, EndPoint.Y)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := TopLeft.X;
  A.Y := TopLeft.Y;
  B.X := TopLeft.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.Y >= A.Y) and (Intersection.Y <= B.Y) and
      (Intersection.X >= Min(StartPoint.X, EndPoint.X)) and
      (Intersection.X <= Max(StartPoint.X, EndPoint.X)) then
    begin
      Result := True;
      Exit;
    end;
  A.X := BottomRight.X;
  A.Y := TopLeft.Y;
  B.X := BottomRight.X;
  B.Y := BottomRight.Y;
  if IntersectLines(StartPoint, EndPoint, A, B, Intersection) then
    if (Intersection.Y >= A.Y) and (Intersection.Y <= B.Y) and
      (Intersection.X >= Min(StartPoint.X, EndPoint.X)) and
      (Intersection.X <= Max(StartPoint.X, EndPoint.X)) then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;
{ @end $4C477C }

{ @routine $4C4954 SegmentCrossesOriginCircle }
function SegmentCrossesOriginCircle(StartPoint, EndPoint: TPointF; Radius: Single): Boolean;
var Delta: TPointF;
  StartDistanceSquared, Projection, LengthSquared, RadiusSquared: Single;
begin
  Result := False;
  RadiusSquared := Radius * Radius;
  StartDistanceSquared := StartPoint.X * StartPoint.X + StartPoint.Y * StartPoint.Y;
  if StartDistanceSquared < RadiusSquared then Exit;
  if EndPoint.X * EndPoint.X + EndPoint.Y * EndPoint.Y < RadiusSquared then Exit;
  Delta.X := EndPoint.X - StartPoint.X;
  Delta.Y := EndPoint.Y - StartPoint.Y;
  LengthSquared := Delta.X * Delta.X + Delta.Y * Delta.Y;
  if LengthSquared < StartDistanceSquared then Exit;
  Projection := (-StartPoint.X * Delta.X - StartPoint.Y * Delta.Y) / Sqrt(LengthSquared);
  if Projection < 0 then Result := False
  else Result := StartDistanceSquared - Projection * Projection < Radius * Radius;
end;
{ @end $4C4954 }

{ @routine $4C4A30 RayIntersectsOriginCircle }
function RayIntersectsOriginCircle(StartPoint, ThroughPoint: TPointF; out Intersection: TPointF; Radius: Single): Boolean;
var DX, DY, T1, T2, CX, CY, Projection, Discriminant, CenterDistanceSquared: Single;
begin
  DX := ThroughPoint.X - StartPoint.X;
  DY := ThroughPoint.Y - StartPoint.Y;
  T1 := 1 / Sqrt(DX * DX + DY * DY);
  DX := DX * T1;
  DY := DY * T1;
  CX := -StartPoint.X;
  CY := -StartPoint.Y;
  CenterDistanceSquared := CX * CX + CY * CY;
  Projection := CX * DX + CY * DY;
  Discriminant := Sqr(Radius) - CenterDistanceSquared + Projection * Projection;
  if Discriminant <= 0 then
  begin
    Result := False;
    Exit;
  end;
  Discriminant := Sqrt(Discriminant);
  if Projection < Discriminant then
  begin
    T1 := Projection + Discriminant;
    T2 := Projection - Discriminant;
  end
  else
  begin
    T1 := Projection - Discriminant;
    T2 := Projection + Discriminant;
  end;
  if Abs(T1) < 0.001 then T1 := T2;
  Intersection.X := DX * T1 + StartPoint.X;
  Intersection.Y := DY * T1 + StartPoint.Y;
  Result := T1 > 0.001;
end;
{ @end $4C4A30 }

{ @routine $4C4B84 CalculateTangentArcOffset }
function CalculateTangentArcOffset(StartPoint, EndPoint: TPointF; Heading, Angle: Double): Double;
var
  Center, Normal, Midpoint: TPointF;
  Radians, Radius, CentralAngle: Double;
begin
  Radians := HeadingDegreesToRadians(Heading);
  Normal.X := Sin(Radians) * 100 + StartPoint.X;
  Normal.Y := StartPoint.Y - Cos(Radians) * 100;
  Normal := RotatePointQuarterTurn(StartPoint, Normal);
  Midpoint.X := (StartPoint.X + EndPoint.X) / 2;
  Midpoint.Y := (StartPoint.Y + EndPoint.Y) / 2;
  if not IntersectLines(StartPoint, Normal, Midpoint, RotatePointQuarterTurn(Midpoint, StartPoint), Center) then
  begin
    Result := 0;
    Exit;
  end;
  Radius := PointDistance(StartPoint, Center);
  CentralAngle := 180 - (90 - Angle) * 2;
  Result := Sin(HeadingDegreesToRadians(CentralAngle / 2)) * Radius;
end;
{ @end $4C4B84 }

{ @routine $4C4CA4 CircleTangentPoints }
procedure CircleTangentPoints(Point: TPointF; Radius: Single; out LeftPoint, RightPoint: TPointF);
var Angle, Spread, Distance: Single;
begin
  Distance := Sqrt(Point.X * Point.X + Point.Y * Point.Y);
  Spread := ArcCos(Radius / Distance);
  Angle := ArcTan2(Point.X, -Point.Y);
  LeftPoint.X := Sin(Angle + Spread) * Radius;
  LeftPoint.Y := -Cos(Angle + Spread) * Radius;
  RightPoint.X := Sin(Angle - Spread) * Radius;
  RightPoint.Y := -Cos(Angle - Spread) * Radius;
end;
{ @end $4C4CA4 }

{ @routine $4C4D54 PointBehindHeading }
function PointBehindHeading(Origin: TPointF; Heading, Distance: Double; Seed: Cardinal): TPointF;
begin
  Heading := HeadingDegreesToRadians(WrapHeadingDegrees(Heading + 180 + (Integer(Seed mod 180) - 90)));
  Result.X := Sin(Heading) * Distance + Origin.X;
  Result.Y := Origin.Y - Cos(Heading) * Distance;
end;
{ @end $4C4D54 }

{ @routine $4C4DD4 FactorialProduct }
function FactorialProduct(Bound: Double): Extended;
var Factor: Double; Product: Extended;
begin
  Product := 1;
  Factor := 2;
  while Factor <= Bound do
  begin
    Product := Product * Factor;
    Factor := Factor + 1;
  end;
  Result := Product;
end;
{ @end $4C4DD4 }

{ @routine $4C4E40 PointDistanceSquared }
function PointDistanceSquared(PointA, PointB: TPointF): Single;
var X, Y: Single;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := X * X + Y * Y;
end;
{ @end $4C4E40 }

{ @routine $4C4E90 PointDistance }
function PointDistance(PointA, PointB: TPointF): Double;
var X, Y: Single;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := Sqrt(X * X + Y * Y);
end;
{ @end $4C4E90 }

{ @routine $4C4EE0 IntegerPointDistancePlusOne }
function IntegerPointDistancePlusOne(PointA, PointB: TPoint): Integer;
var X, Y: Integer;
begin
  X := PointA.X - PointB.X;
  Y := PointA.Y - PointB.Y;
  Result := Trunc(Sqrt(X * X + Y * Y) + 1);
end;
{ @end $4C4EE0 }

{ @routine $4C4F30 ReadByteValue }
function ReadByteValue(var Value): Byte;
begin
  Result := Byte(Value);
end;
{ @end $4C4F30 }

{ @routine $4C4F34 WriteByteValue }
procedure WriteByteValue(Value: Byte; var Destination);
begin
  Byte(Destination) := Value;
end;
{ @end $4C4F34 }

{ @routine $4C4F38 RemapClamped }
function RemapClamped(Value: Double; InMin: Double; InMax: Double; OutMin: Double; OutMax: Double): Double;
begin
  if Value <= InMin then
  begin
    Result := OutMin;
    Exit;
  end
  else if Value >= InMax then
  begin
    Result := OutMax;
    Exit;
  end
  else
  begin
    Result := ((((Value - InMin) / (InMax - InMin)) * (OutMax - OutMin)) + OutMin);
    Exit;
  end;
end;
{ @end $4C4F38 }

{ @routine $4C4F98 RemapClampedAlternate }
function RemapClampedAlternate(Value: Double; InMin: Double; InMax: Double; OutMin: Double; OutMax: Double): Double;
begin
  if Value <= InMin then
  begin
    Result := OutMin;
    Exit;
  end
  else if Value >= InMax then
  begin
    Result := OutMax;
    Exit;
  end
  else
  begin
    Result := ((((Value - InMin) / (InMax - InMin)) * (OutMax - OutMin)) + OutMin);
    Exit;
  end;
end;
{ @end $4C4F98 }

{ @routine $4C4FF8 ReplaceTextToken }
procedure ReplaceTextToken(var Text: WideString; Token, Replacement, ColorTag: WideString);
begin
  if ColorTag <> '' then Replacement := ColorTag + Replacement + ColorEndTag;
  Text := ReplaceAllWideString(Text, Token, Replacement);
end;
{ @end $4C4FF8 }

{ @routine $4C50BC ReplaceColoredToken }
function ReplaceColoredToken(Text, Token, Replacement, ColorTag: WideString): WideString;
begin
  if ColorTag <> '' then Replacement := ColorTag + Replacement + ColorEndTag;
  Result := ReplaceAllWideString(Text, Token, Replacement);
end;
{ @end $4C50BC }

{ @routine $4C5178 FormatText1 }
function FormatText1(Text, ColorTag, Token, Replacement: WideString): WideString;
begin
  if ColorTag <> '' then Replacement := ColorTag + Replacement + ColorEndTag;
  Result := ReplaceAllWideString(Text, Token, Replacement);
end;
{ @end $4C5178 }

{ @routine $4C5234 FormatText2 }
function FormatText2(Text, ColorTag, Token1, Replacement1, Token2, Replacement2: WideString): WideString;
begin
  if ColorTag <> '' then
  begin
    Replacement1 := ColorTag + Replacement1 + ColorEndTag;
    Replacement2 := ColorTag + Replacement2 + ColorEndTag;
  end;
  Result := ReplaceAllWideString(ReplaceAllWideString(Text, Token1, Replacement1), Token2, Replacement2);
end;
{ @end $4C5234 }

{ @routine $4C5338 FormatText3 }
function FormatText3(Text, ColorTag, Token1, Replacement1, Token2, Replacement2, Token3, Replacement3: WideString): WideString;
begin
  if ColorTag <> '' then
  begin
    Replacement1 := ColorTag + Replacement1 + ColorEndTag;
    Replacement2 := ColorTag + Replacement2 + ColorEndTag;
    Replacement3 := ColorTag + Replacement3 + ColorEndTag;
  end;
  Result := ReplaceAllWideString(ReplaceAllWideString(ReplaceAllWideString(Text, Token1, Replacement1), Token2, Replacement2), Token3, Replacement3);
end;
{ @end $4C5338 }

{ @routine $4C5478 WrapTextInColor }
function WrapTextInColor(Text, ColorTag: WideString): WideString;
begin
  if ColorTag <> '' then Result := ColorTag + Text + ColorEndTag
  else Result := Text;
end;
{ @end $4C5478 }

{ @routine $4C5514 IncrementWrapped }
function IncrementWrapped(var Value: Integer; Minimum, Maximum: Integer): Integer;
begin
  if Value + 1 > Maximum then Value := Minimum
  else Inc(Value);
  Result := Value;
end;
{ @end $4C5514 }

{ @routine $4C5528 DecrementWrappedValue }
function DecrementWrappedValue(Value, Minimum, Maximum: Integer): Integer;
begin
  if Value - 1 < Minimum then Value := Maximum
  else Dec(Value);
  Result := Value;
end;
{ @end $4C5528 }

end.

unit EC_Struct;
// Unit bracket (inferred): CODE 0x00455D44..0x0045609F; inclusive evidence, not full bounds.
// Native routines $455DC4..$456064.

interface

uses Types;

type
  TPointF = record // @size $08
    X: Single; // @offset $00
    Y: Single; // @offset $04
  end;
  PPointF = ^TPointF;

  TVector3D = record // @size $18
    X: Double; // @offset $00
    Y: Double; // @offset $08
    Z: Double; // @offset $10
  end;

  TObjectEx = class // @size $04
  public
    constructor Create; // @addr $00456008
    destructor Destroy; override; // @addr $00456040
  end;

function MakeVector3D(X, Y, Z: Double): TVector3D; // @addr $00455DD8
function MakePointF(X, Y: Single): TPointF; // @addr $00455DC4
function TruncatePointF(Point: TPointF): TPoint; // @addr $00455E04 @note "Truncates each coordinate toward zero."
function RoundPointF(Point: TPointF): TPoint; // @addr $455E30
function PointToPointF(Point: TPoint): TPointF; // @addr $00455E5C
function HalfPoint(Point: TPoint): TPoint; // @addr $00455E7C @note "Integer division rounds toward zero."
function AddPoints(Left, Right: TPoint): TPoint; // @addr $00455EA8
function SubtractPoints(Left, Right: TPoint): TPoint; // @addr $00455ED8
function HalfPointF(Point: TPointF): TPointF; // @addr $455F08
function AddPointsF(Left, Right: TPointF): TPointF; // @addr $455F38
function SubtractPointsF(Left, Right: TPointF): TPointF; // @addr $455F68
function IntersectRects(out Intersection: TRect; const First, Second: TRect): Boolean; // @addr $00455F98 @note "Returns false without writing Intersection when the rectangles do not overlap."

var
  StartupCleanupObject: TObject; // @addr $61BCBC Unused cleanup slot.

implementation

// @unit-initialization $456098
// @unit-finalization $456068

{ @routine $455DC4 MakePointF }
function MakePointF(X, Y: Single): TPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;
{ @end $455DC4 }

{ @routine $455DD8 MakeVector3D }
function MakeVector3D(X, Y, Z: Double): TVector3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;
{ @end $455DD8 }

{ @routine $455E04 TruncatePointF }
function TruncatePointF(Point: TPointF): TPoint;
begin
  Result.X := Trunc(Point.X);
  Result.Y := Trunc(Point.Y);
end;
{ @end $455E04 }

{ @routine $455E30 RoundPointF }
function RoundPointF(Point: TPointF): TPoint;
begin
  Result.X := Round(Point.X);
  Result.Y := Round(Point.Y);
end;
{ @end $455E30 }

{ @routine $455E5C PointToPointF }
function PointToPointF(Point: TPoint): TPointF;
begin
  Result.X := Point.X;
  Result.Y := Point.Y;
end;
{ @end $455E5C }

{ @routine $455E7C HalfPoint }
function HalfPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X div 2;
  Result.Y := Point.Y div 2;
end;
{ @end $455E7C }

{ @routine $455EA8 AddPoints }
function AddPoints(Left, Right: TPoint): TPoint;
begin
  Result.X := Left.X + Right.X;
  Result.Y := Left.Y + Right.Y;
end;
{ @end $455EA8 }

{ @routine $455ED8 SubtractPoints }
function SubtractPoints(Left, Right: TPoint): TPoint;
begin
  Result.X := Left.X - Right.X;
  Result.Y := Left.Y - Right.Y;
end;
{ @end $455ED8 }

{ @routine $455F08 HalfPointF }
function HalfPointF(Point: TPointF): TPointF;
begin
  Result.X := Point.X / 2;
  Result.Y := Point.Y / 2;
end;
{ @end $455F08 }

{ @routine $455F38 AddPointsF }
function AddPointsF(Left, Right: TPointF): TPointF;
begin
  Result.X := Left.X + Right.X;
  Result.Y := Left.Y + Right.Y;
end;
{ @end $455F38 }

{ @routine $455F68 SubtractPointsF }
function SubtractPointsF(Left, Right: TPointF): TPointF;
begin
  Result.X := Left.X - Right.X;
  Result.Y := Left.Y - Right.Y;
end;
{ @end $455F68 }

{ @routine $455F98 IntersectRects }
function IntersectRects(out Intersection: TRect; const First, Second: TRect): Boolean;
// Handwritten native assembly; Intersection is untouched on failure, even when aliased.
asm
  PUSH ESI
  PUSH EDI
  PUSH ECX
  PUSH EBX
  MOV ESI, EDX
  MOV EDI, ECX
  MOV EBX, EAX
  MOV EAX, [EDI].TRect.Left
  CMP EAX, [ESI].TRect.Right
  JGE @@Empty
  MOV EAX, [EDI].TRect.Right
  CMP EAX, [ESI].TRect.Left
  JLE @@Empty
  MOV EAX, [EDI].TRect.Top
  CMP EAX, [ESI].TRect.Bottom
  JGE @@Empty
  MOV EAX, [EDI].TRect.Bottom
  CMP EAX, [ESI].TRect.Top
  JLE @@Empty
  MOV EAX, [EDI].TRect.Left
  MOV ECX, [ESI].TRect.Left
  CMP EAX, ECX
  JGE @@Left
  MOV EAX, ECX
@@Left:
  MOV [EBX].TRect.Left, EAX
  MOV EAX, [EDI].TRect.Right
  MOV ECX, [ESI].TRect.Right
  CMP EAX, ECX
  JLE @@Right
  MOV EAX, ECX
@@Right:
  MOV [EBX].TRect.Right, EAX
  MOV EAX, [EDI].TRect.Top
  MOV ECX, [ESI].TRect.Top
  CMP EAX, ECX
  JGE @@Top
  MOV EAX, ECX
@@Top:
  MOV [EBX].TRect.Top, EAX
  MOV EAX, [EDI].TRect.Bottom
  MOV ECX, [ESI].TRect.Bottom
  CMP EAX, ECX
  JLE @@Bottom
  MOV EAX, ECX
@@Bottom:
  MOV [EBX].TRect.Bottom, EAX
  XOR EAX, EAX
  INC EAX
  JMP @@Done
@@Empty:
  XOR EAX, EAX
@@Done:
  POP EBX
  POP ECX
  POP EDI
  POP ESI
end;
{ @end $455F98 }

{ @routine $456008 TObjectEx_Create }
constructor TObjectEx.Create;
begin
  inherited Create;
end;
{ @end $456008 }

{ @routine $456040 TObjectEx_Destroy }
destructor TObjectEx.Destroy;
begin
  inherited Destroy;
end;
{ @end $456040 }

end.

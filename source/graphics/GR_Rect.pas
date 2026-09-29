unit GR_Rect;
// Unit bracket (inferred): CODE 0x00468930..0x00468FFB; inclusive evidence, not full bounds.

interface

uses EC_Struct, Types;

type
  TRectGR = class(TObject) // @size $1C
  public
    Prev: TRectGR; // @offset $04
    Next: TRectGR; // @offset $08
    Bounds: TRect; // @offset $0C

    constructor Create; // @addr $4689E0
    destructor Destroy; override; // @addr $468A18
  end;

  TArrayRectGR = class(TObjectEx) // @size $0C
  public
    FirstRect: TRectGR; // @offset $04
    LastRect: TRectGR; // @offset $08

    constructor Create; // @addr $468A40
    destructor Destroy; override; // @addr $468A78
    procedure Clear; // @addr $468AA4
    function AllocateRectNode: TRectGR; // @addr $468ACC
    procedure RemoveRectNode(RectNode: TRectGR); // @addr $468B00
    procedure AddRect(Rect: TRect); // @addr $468B3C @note "Maintains nonoverlapping coverage."
    procedure InsertRectFragment(Left, Top, Right, Bottom: Integer); // @addr $468BD8
    procedure AddScreenClippedRect(Rect: TRect; UnusedPoint1, UnusedPoint2: TPoint; UnusedValue: Integer); // @addr $468F80
  end;

implementation

// @unit-initialization $468FF4
// @unit-finalization $468FC4

uses GR_Main;

{ @routine $4689E0 TRectGR_Create }
constructor TRectGR.Create;
begin
  inherited Create;
end;
{ @end $4689E0 }

{ @routine $468A18 TRectGR_Destroy }
destructor TRectGR.Destroy;
begin
  inherited Destroy;
end;
{ @end $468A18 }

{ @routine $468A40 TArrayRectGR_Create }
constructor TArrayRectGR.Create;
begin
  inherited Create;
end;
{ @end $468A40 }

{ @routine $468A78 TArrayRectGR_Destroy }
destructor TArrayRectGR.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $468A78 }

{ @routine $468AA4 TArrayRectGR_Clear }
procedure TArrayRectGR.Clear;
var
  Node, Removed: TRectGR;
begin
  Node := FirstRect;
  while Node <> nil do
  begin
    Removed := Node;
    Node := Node.Next;
    Removed.Free;
  end;
  FirstRect := nil;
  LastRect := nil;
end;
{ @end $468AA4 }

{ @routine $468ACC TArrayRectGR_AllocateRectNode }
function TArrayRectGR.AllocateRectNode: TRectGR;
var
  Node: TRectGR;
begin
  Node := TRectGR.Create;
  if LastRect <> nil then
    LastRect.Next := Node;
  Node.Prev := LastRect;
  Node.Next := nil;
  LastRect := Node;
  if FirstRect = nil then
    FirstRect := Node;
  Result := Node;
end;
{ @end $468ACC }

{ @routine $468B00 TArrayRectGR_RemoveRectNode }
procedure TArrayRectGR.RemoveRectNode(RectNode: TRectGR);
begin
  if RectNode.Prev <> nil then
    RectNode.Prev.Next := RectNode.Next;
  if RectNode.Next <> nil then
    RectNode.Next.Prev := RectNode.Prev;
  if LastRect = RectNode then
    LastRect := RectNode.Prev;
  if FirstRect = RectNode then
    FirstRect := RectNode.Next;
  RectNode.Free;
end;
{ @end $468B00 }

{ @routine $468B3C TArrayRectGR_AddRect }
procedure TArrayRectGR.AddRect(Rect: TRect);
var
  Node, Removed: TRectGR;
begin
  Node := LastRect;
  while Node <> nil do
  begin
    with Node.Bounds do
      if (Rect.Left >= Left) and (Rect.Right <= Right) and
         (Rect.Top >= Top) and (Rect.Bottom <= Bottom) then
        Exit;
    Node := Node.Prev;
  end;
  Node := LastRect;
  while Node <> nil do
  begin
    with Node.Bounds do
      if (Left >= Rect.Left) and (Right <= Rect.Right) and
         (Top >= Rect.Top) and (Bottom <= Rect.Bottom) then
      begin
        Removed := Node;
        Node := Node.Prev;
        RemoveRectNode(Removed);
      end
      else
        Node := Node.Prev;
  end;
  InsertRectFragment(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
end;
{ @end $468B3C }

{ @routine $468BD8 TArrayRectGR_InsertRectFragment }
procedure TArrayRectGR.InsertRectFragment(Left, Top, Right, Bottom: Integer);
var
  Node: TRectGR;
  OutsideEdges: Integer;
  ExistingLeft, ExistingTop, ExistingRight, ExistingBottom: Integer;
begin
  Node := LastRect;
  while Node <> nil do
  begin
    ExistingLeft := Node.Bounds.Left;
    ExistingRight := Node.Bounds.Right;
    ExistingTop := Node.Bounds.Top;
    ExistingBottom := Node.Bounds.Bottom;
    if (Left >= ExistingLeft) and (Right <= ExistingRight) and
       (Top >= ExistingTop) and (Bottom <= ExistingBottom) then
      Exit;
    if (Left < ExistingRight) and (Right > ExistingLeft) and
       (Top < ExistingBottom) and (Bottom > ExistingTop) then
      Break;
    Node := Node.Prev;
  end;
  if Node = nil then
  begin
    Node := AllocateRectNode;
    Node.Bounds.Left := Left;
    Node.Bounds.Top := Top;
    Node.Bounds.Right := Right;
    Node.Bounds.Bottom := Bottom;
    Exit;
  end;
  OutsideEdges := 0;
  if Left < ExistingLeft then OutsideEdges := OutsideEdges or 1;
  if Right > ExistingRight then OutsideEdges := OutsideEdges or 8;
  if Top < ExistingTop then OutsideEdges := OutsideEdges or 16;
  if Bottom > ExistingBottom then OutsideEdges := OutsideEdges or 128;
  if OutsideEdges = 1 then
  begin
    InsertRectFragment(Left, Top, ExistingLeft, Bottom);
  end
  else if OutsideEdges = 8 then
  begin
    InsertRectFragment(ExistingRight, Top, Right, Bottom);
  end
  else if OutsideEdges = 16 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
  end
  else if OutsideEdges = 128 then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if OutsideEdges = 9 then
  begin
    InsertRectFragment(Left, Top, ExistingLeft, Bottom);
    InsertRectFragment(ExistingRight, Top, Right, Bottom);
  end
  else if OutsideEdges = 144 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if OutsideEdges = 17 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, Bottom);
  end
  else if OutsideEdges = 24 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(ExistingRight, ExistingTop, Right, Bottom);
  end
  else if OutsideEdges = 129 then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(Left, Top, ExistingLeft, ExistingBottom);
  end
  else if OutsideEdges = 136 then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(ExistingRight, Top, Right, ExistingBottom);
  end
  else if OutsideEdges = 145 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, ExistingBottom);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if OutsideEdges = 152 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(ExistingRight, ExistingTop, Right, ExistingBottom);
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
  end
  else if OutsideEdges = 25 then
  begin
    InsertRectFragment(Left, Top, Right, ExistingTop);
    InsertRectFragment(Left, ExistingTop, ExistingLeft, Bottom);
    InsertRectFragment(ExistingRight, ExistingTop, Right, Bottom);
  end
  else if OutsideEdges = 137 then
  begin
    InsertRectFragment(Left, ExistingBottom, Right, Bottom);
    InsertRectFragment(Left, Top, ExistingLeft, ExistingBottom);
    InsertRectFragment(ExistingRight, Top, Right, ExistingBottom);
  end;
end;
{ @end $468BD8 }

{ @routine $468F80 TArrayRectGR_AddScreenClippedRect }
procedure TArrayRectGR.AddScreenClippedRect(Rect: TRect; UnusedPoint1, UnusedPoint2: TPoint; UnusedValue: Integer);
var
  Clipped: TRect;
begin
  if IntersectRects(Clipped, Rect, GameScreenRect) then
    AddRect(Clipped);
end;
{ @end $468F80 }

end.

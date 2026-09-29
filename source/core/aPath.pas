unit aPath;
// Unit bracket (inferred): CODE 0x005BEB00..0x005BF49F; inclusive evidence, not full bounds.

interface

uses EC_Struct, SyncObjs;

type
  PSPathNode = ^TSPathNode;
  TSPathNode = packed record // @size $14
    Prev: PSPathNode; // @offset $00
    Next: PSPathNode; // @offset $04
    Position: TPointF; // @offset $08
    Heading: Single; // @offset $10
  end;

  TSPath = class(TObject) // @size $18
  public
    ActiveHead: PSPathNode; // @offset $04
    ActiveTail: PSPathNode; // @offset $08
    FreeHead: PSPathNode; // @offset $0C
    FreeTail: PSPathNode; // @offset $10
    NodeCount: Integer; // @offset $14  Active nodes only.

    constructor Create; // @addr $5BECA0
    destructor Destroy; override; // @addr $5BECDC
    procedure AllocateNodeUnit; // @addr $5BED7C @note "Acquires 24 nodes from the shared pool; raises on allocation failure."
    function PopFreeNode: PSPathNode; // @addr $5BEEA0 @note "Increments NodeCount without linking into the active list. May allocate; payload is uninitialized."
    procedure AppendNode; // @addr $5BEF94 @note "New node is ActiveTail; payload is uninitialized."
    procedure AppendWaypoint(Position: TPointF; Heading: Single); // @addr $5BEFC0
    function InsertNodeBefore(Node: PSPathNode): PSPathNode; // @addr $5BF014 @note "Nil appends. Payload is uninitialized."
    procedure RemoveNode(Node: PSPathNode); // @addr $5BEEC8 @note "Node must belong to this path; it is recycled."
    procedure RemoveNodeRange(FirstNode, LastNode: PSPathNode); // @addr $5BEF1C @note "Inclusive range must be ordered and belong to this path; nodes are recycled."
    procedure Clear; // @addr $5BEF84 @note "Recycles active nodes into this path's free list."
    function GetFollowingNode(Node: PSPathNode; SkipCount: Integer): PSPathNode; // @addr $5BF050 @note "Starts at Node.Next; nonpositive SkipCount selects that immediate successor. Node must be non-nil."
    function FindNearestFollowingNode(Node: PSPathNode; Position: TPointF): PSPathNode; // @addr $5BF06C @note "Excludes Node itself, which must be non-nil. Ties keep the earlier node."
    procedure ResampleBezierRange(FirstNode, LastNode: PSPathNode; SampleCount: Integer); // @addr $5BF114 @note "Uses the inclusive nodes as Bezier controls, unwraps headings, inserts samples and recycles the controls."
    function CountNodeRangeInclusive(FirstNode, LastNode: PSPathNode): Integer; // @addr $5BF0C4 @note "Returns zero for nil endpoints or when LastNode is not reachable from FirstNode."
  end;

var
  PathNodeHeap: Cardinal = 0; // @addr $6188D8
  PathPoolHead: PSPathNode = nil; // @addr $6188DC
  PathPoolTail: PSPathNode = nil; // @addr $6188E0
  PathPoolLock: TCriticalSection = nil; // @addr $6188E4

procedure InitializePathNodePool; // @addr $5BEB54
procedure FinalizePathNodePool; // @addr $5BEC44

implementation

// @unit-initialization $5BF498
// @unit-finalization $5BF468

uses EC_Mem, GR_Main, Math, SysUtils, Windows;

var
  PathInitialBlock: Pointer; // @addr $61D058
  PathPoolFreeCount: Integer; // @addr $61D05C

{ @routine $5BEB54 InitializePathNodePool }
procedure InitializePathNodePool;
var Index: Integer; Node, Prev: PSPathNode;
begin
  PathPoolLock := TCriticalSection.Create;
  PathPoolFreeCount := 100000;
  PathNodeHeap := HeapCreate(0, 16, 0);
  PathInitialBlock := HeapAlloc(PathNodeHeap, 0, PathPoolFreeCount * SizeOf(TSPathNode));
  if PathInitialBlock = nil then raise Exception.Create('Error: HeapAlloc');
  ZeroMemory(PathInitialBlock, PathPoolFreeCount * SizeOf(TSPathNode));
  Node := PathInitialBlock; PathPoolHead := Node; Prev := nil;
  for Index := 0 to PathPoolFreeCount - 1 do
  begin
    Node.Prev := Prev;
    Node.Next := AddPointerOffset(Node, SizeOf(TSPathNode));
    Prev := Node; Node := AddPointerOffset(Node, SizeOf(TSPathNode));
  end;
  PathPoolTail := Prev; PathPoolTail.Next := nil;
end;
{ @end $5BEB54 }

{ @routine $5BEC44 FinalizePathNodePool }
procedure FinalizePathNodePool;
begin
  if PathInitialBlock <> nil then
  begin
    HeapFree(PathNodeHeap, 0, PathInitialBlock); PathInitialBlock := nil;
  end;
  if PathNodeHeap <> 0 then
  begin
    HeapDestroy(PathNodeHeap); PathNodeHeap := 0;
  end;
  if PathPoolLock <> nil then
  begin
    PathPoolLock.Free; PathPoolLock := nil;
  end;
end;
{ @end $5BEC44 }

{ @routine $5BECA0 TSPath_Create }
constructor TSPath.Create;
begin
  inherited Create;
  AllocateNodeUnit;
end;
{ @end $5BECA0 }

{ @routine $5BECDC TSPath_Destroy }
destructor TSPath.Destroy;
begin
  Clear;
  PathPoolLock.Enter;
  Inc(PathPoolFreeCount, CountNodeRangeInclusive(FreeHead, FreeTail));
  if PathPoolTail <> nil then PathPoolTail.Next := FreeHead;
  FreeHead.Prev := PathPoolTail;
  FreeTail.Next := nil; PathPoolTail := FreeTail;
  if PathPoolHead = nil then PathPoolHead := FreeHead;
  PathPoolLock.Leave;
  FreeHead := nil; FreeTail := nil; NodeCount := 0;
  inherited Destroy;
end;
{ @end $5BECDC }

{ @routine $5BED7C TSPath_AllocateNodeUnit }
procedure TSPath.AllocateNodeUnit;
var Index: Integer; First, Last: PSPathNode; Count: Integer;
begin
  Count := 24;
  PathPoolLock.Enter;
  if Count >= PathPoolFreeCount then
    begin
      PathPoolLock.Leave;
      raise Exception.Create('Error: Path.AllocUnit  UnitCount=' + IntToStr(Count));
    end;
  First := PathPoolHead; Last := PathPoolHead;
  for Index := 1 to Count - 1 do Last := Last.Next;
  PathPoolHead := Last.Next; PathPoolHead.Prev := nil;
  Dec(PathPoolFreeCount, Count);
  PathPoolLock.Leave;
  if FreeTail <> nil then FreeTail.Next := First;
  First.Prev := FreeTail; Last.Next := nil; FreeTail := Last;
  if FreeHead = nil then FreeHead := First;
end;
{ @end $5BED7C }

{ @routine $5BEEA0 TSPath_PopFreeNode }
function TSPath.PopFreeNode: PSPathNode;
var Node: PSPathNode;
begin
  if (FreeHead = FreeTail) or (FreeHead = nil) then AllocateNodeUnit;
  Node := FreeHead; Node.Next.Prev := nil;
  FreeHead := Node.Next; Inc(NodeCount);
  Result := Node;
end;
{ @end $5BEEA0 }

{ @routine $5BEEC8 TSPath_RemoveNode }
procedure TSPath.RemoveNode(Node: PSPathNode);
begin
  if Node.Prev <> nil then Node.Prev.Next := Node.Next;
  if Node.Next <> nil then Node.Next.Prev := Node.Prev;
  if ActiveTail = Node then ActiveTail := Node.Prev;
  if ActiveHead = Node then ActiveHead := Node.Next;
  if FreeTail <> nil then FreeTail.Next := Node;
  Node.Prev := FreeTail; Node.Next := nil; FreeTail := Node;
  if FreeHead = nil then FreeHead := Node;
  Dec(NodeCount);
end;
{ @end $5BEEC8 }

{ @routine $5BEF1C TSPath_RemoveNodeRange }
procedure TSPath.RemoveNodeRange(FirstNode, LastNode: PSPathNode);
begin
  Dec(NodeCount, CountNodeRangeInclusive(FirstNode, LastNode));
  if FirstNode.Prev <> nil then FirstNode.Prev.Next := LastNode.Next;
  if LastNode.Next <> nil then LastNode.Next.Prev := FirstNode.Prev;
  if LastNode = ActiveTail then ActiveTail := FirstNode.Prev;
  if FirstNode = ActiveHead then ActiveHead := LastNode.Next;
  if FreeTail <> nil then FreeTail.Next := FirstNode;
  FirstNode.Prev := FreeTail; LastNode.Next := nil; FreeTail := LastNode;
  if FreeHead = nil then FreeHead := FirstNode;
end;
{ @end $5BEF1C }

{ @routine $5BEF84 TSPath_Clear }
procedure TSPath.Clear;
begin
  if ActiveHead <> nil then RemoveNodeRange(ActiveHead, ActiveTail);
end;
{ @end $5BEF84 }

{ @routine $5BEF94 TSPath_AppendNode }
procedure TSPath.AppendNode;
var Node: PSPathNode;
begin
  Node := PopFreeNode;
  if ActiveTail <> nil then ActiveTail.Next := Node;
  Node.Prev := ActiveTail; Node.Next := nil; ActiveTail := Node;
  if ActiveHead = nil then ActiveHead := Node;
end;
{ @end $5BEF94 }

{ @routine $5BEFC0 TSPath_AppendWaypoint }
procedure TSPath.AppendWaypoint(Position: TPointF; Heading: Single);
var Node: PSPathNode;
begin
  Node := PopFreeNode;
  if ActiveTail <> nil then ActiveTail.Next := Node;
  Node.Prev := ActiveTail; Node.Next := nil; ActiveTail := Node;
  if ActiveHead = nil then ActiveHead := Node;
  Node.Position := Position; Node.Heading := Heading;
end;
{ @end $5BEFC0 }

{ @routine $5BF014 TSPath_InsertNodeBefore }
function TSPath.InsertNodeBefore(Node: PSPathNode): PSPathNode;
begin
  if Node = nil then
  begin
    AppendNode; Result := ActiveTail; Exit;
  end;
  Result := PopFreeNode;
  Result.Prev := Node.Prev;
  Result.Next := Node;
  if Node.Prev <> nil then Node.Prev.Next := Result;
  Node.Prev := Result;
  if Node = ActiveHead then ActiveHead := Result;
end;
{ @end $5BF014 }

{ @routine $5BF050 TSPath_GetFollowingNode }
function TSPath.GetFollowingNode(Node: PSPathNode; SkipCount: Integer): PSPathNode;
begin
  Node := Node.Next;
  while Node <> nil do
  begin
    if SkipCount <= 0 then begin Result := Node; Exit; end;
    Dec(SkipCount); Node := Node.Next;
  end;
  Result := nil;
end;
{ @end $5BF050 }

{ @routine $5BF06C TSPath_FindNearestFollowingNode }
function TSPath.FindNearestFollowingNode(Node: PSPathNode; Position: TPointF): PSPathNode;
var BestDistance, Distance: Single;
begin
  Result := nil; BestDistance := 1.0e20;
  Node := Node.Next;
  while Node <> nil do
  begin
    Distance := PointDistanceSquared(Node.Position, Position);
    if Distance < BestDistance then begin Result := Node; BestDistance := Distance; end;
    Node := Node.Next;
  end;
end;
{ @end $5BF06C }

{ @routine $5BF0C4 TSPath_CountNodeRangeInclusive }
function TSPath.CountNodeRangeInclusive(FirstNode, LastNode: PSPathNode): Integer;
var Count: Integer; Node: PSPathNode;
begin
  if (FirstNode = nil) or (LastNode = nil) then begin Result := 0; Exit; end;
  Count := 1; Node := FirstNode;
  while (Node <> nil) and (Node <> LastNode) do begin Inc(Count); Node := Node.Next; end;
  if Node = nil then begin Result := 0; Exit; end;
  Result := Count;
end;
{ @end $5BF0C4 }

{ @routine $5BF114 TSPath_ResampleBezierRange }
procedure TSPath.ResampleBezierRange(FirstNode, LastNode: PSPathNode; SampleCount: Integer);
var
  Coefficients: array of Double;
  Count: Integer;
  Node, NewNode, AfterNode: PSPathNode;
  Index, Sample: Integer;
  Heading, Weight, X, Y, Angle, T: Double;
  FactorialTotal, TPower, InvRemaining, RemainingPower: Extended;
begin
  Count := CountNodeRangeInclusive(FirstNode, LastNode);
  if Count < 2 then Exit;
  if SampleCount < 2 then Exit;
  AfterNode := LastNode.Next;
  SetLength(Coefficients, Count);
  // Uses Extended factorial products, whose rounding and overflow differ from a recurrence.
  FactorialTotal := FactorialProduct(Count - 1);
  for Index := 0 to Count - 1 do
    Coefficients[Index] := FactorialTotal /
      (FactorialProduct(Index) * FactorialProduct(Count - 1 - Index));
  Heading := FirstNode.Heading;
  Node := LastNode;
  while Node <> FirstNode do
  begin
    Node.Heading := HeadingDifferenceDegrees(Node.Prev.Heading, Node.Heading);
    Node := Node.Prev;
  end;
  FirstNode.Heading := 0;
  Node := FirstNode;
  while Node <> LastNode do
  begin
    Heading := Heading + Node.Heading; Node.Heading := Heading; Node := Node.Next;
  end;
  Heading := Heading + LastNode.Heading; LastNode.Heading := Heading;
  T := 0;
  for Sample := 0 to SampleCount - 1 do
  begin
    X := 0; Y := 0; Angle := 0;
    Node := FirstNode; Index := 0;
    TPower := 1;
    InvRemaining := 1 / (1 - T);
    RemainingPower := Power(1 - T, Count - 1 - Index);
    while Node <> LastNode do
    begin
      Weight := TPower * Coefficients[Index] * RemainingPower;
      X := X + Weight * Node.Position.X;
      Y := Y + Weight * Node.Position.Y;
      Angle := Angle + Weight * Node.Heading;
      Inc(Index);
      TPower := TPower * T;
      RemainingPower := RemainingPower * InvRemaining;
      Node := Node.Next;
    end;
    Weight := TPower * Coefficients[Index];
    X := X + Weight * Node.Position.X;
    Y := Y + Weight * Node.Position.Y;
    Angle := Angle + Weight * Node.Heading;
    NewNode := InsertNodeBefore(AfterNode);
    NewNode.Position.X := X; NewNode.Position.Y := Y;
    NewNode.Heading := WrapHeadingDegrees(Angle);
    T := T + 1 / (SampleCount - 1);
  end;
  if AfterNode = nil then NewNode := ActiveTail else NewNode := AfterNode.Prev;
  NewNode.Position := LastNode.Position; NewNode.Heading := LastNode.Heading;
  RemoveNodeRange(FirstNode, LastNode);
  Coefficients := nil;
end;
{ @end $5BF114 }

end.

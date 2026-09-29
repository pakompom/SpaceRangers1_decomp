unit SE_Meteorite;
// Unit bracket (inferred): CODE 0x0060DF44..0x0060E6E3; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, EC_Struct, GI_GAI, SE_Space, Types;

type
  TMeteoriteSE = class(TObjectSE) // @size $60
  public
    ImagePath: WideString; // @offset $48
    TimerInterval: Integer; // @offset $4C
    Speed: Single; // @offset $50
    Angle: Single; // @offset $54 Radians, zero points upward.
    Animation: TgaiGI; // @offset $58
    MoveTimer: PSpaceTimerSE; // @offset $5C

    constructor Create(GraphKey: WideString; UnusedPosition: TPoint); // @addr $60E00C
    destructor Destroy; override; // @addr $60E094
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $60E0BC
    procedure DetachFromSpace; override; // @addr $60E1BC
    procedure SetPosition(APosition: TPointF); override; // @addr $60E1FC
    function IsNearView(Point: TPointF): Boolean; // @addr $60E240
    procedure PlaceRandomly; // @addr $60E2DC
    procedure RestartOutsideView; // @addr $60E354
    procedure AdvanceMotion(Timer: PSpaceTimerSE; UserData: Integer); // @addr $60E4D0
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $60E580
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $60E6A4
  end;

implementation

// @unit-initialization $60E6DC
// @unit-finalization $60E6AC

uses Math, GlobalsV, GR_Main, GI_Main, EC_Str, aMyFunction, SE_Process;

{ @routine $60E00C TMeteoriteSE_Create }
constructor TMeteoriteSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
end;
{ @end $60E00C }

{ @routine $60E094 TMeteoriteSE_Destroy }
destructor TMeteoriteSE.Destroy;
begin
  inherited Destroy;
end;
{ @end $60E094 }

{ @routine $60E0BC TMeteoriteSE_AttachToSpace }
procedure TMeteoriteSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  ConfigureLoopSound('Comet');
  ConfigureRandomSound('Comet');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  Animation.SetImagePath(ImagePath);
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPosition(TruncatePointF(Position));
  Animation.SetPositionModeW(True);
  Animation.SequenceIndex := 0;
  Animation.UpdateAutoGeometry;
  Animation.RestartPlayback;
  PlaceRandomly;
  MoveTimer := Space.CreateTimer(TimerInterval, TimerInterval, AdvanceMotion, 0);
end;
{ @end $60E0BC }

{ @routine $60E1BC TMeteoriteSE_DetachFromSpace }
procedure TMeteoriteSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  if MoveTimer <> nil then
  begin
    Space.DeleteTimer(MoveTimer);
    MoveTimer := nil;
  end;
  if Animation <> nil then
  begin
    Animation.Free;
    Animation := nil;
  end;
  inherited DetachFromSpace;
end;
{ @end $60E1BC }

{ @routine $60E1FC TMeteoriteSE_SetPosition }
procedure TMeteoriteSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then Animation.SetPosition(TruncatePointF(APosition));
end;
{ @end $60E1FC }

{ @routine $60E240 TMeteoriteSE_IsNearView }
function TMeteoriteSE.IsNearView(Point: TPointF): Boolean;
var Width, Height: Single;
begin
  Width := Cardinal(GameScreenWidth);
  Height := Cardinal(GameScreenHeight);
  Result := (SpaceViewPosition.X - Width < Point.X) and
    (SpaceViewPosition.X + Width > Point.X) and
    (SpaceViewPosition.Y - Height < Point.Y) and
    (SpaceViewPosition.Y + Height > Point.Y);
end;
{ @end $60E240 }

{ @routine $60E2DC TMeteoriteSE_PlaceRandomly }
procedure TMeteoriteSE.PlaceRandomly;
var
  Radius: Single;
  Bound: Integer;
begin
  if Space = nil then Exit;
  Radius := TProcessSE(Space.Process).SystemRadius;
  Bound := Round(Radius);
  SetPosition(MakePointF(RandomIntRange(-Bound, Bound), RandomIntRange(-Bound, Bound)));
end;
{ @end $60E2DC }

{ @routine $60E354 TMeteoriteSE_RestartOutsideView }
procedure TMeteoriteSE.RestartOutsideView;
var
  Radius: Single;
  Bound: Integer;
  StartPoint, EndPoint, Intersection: TPointF;
begin
  if Space = nil then Exit;
  Radius := TProcessSE(Space.Process).SystemRadius;
  repeat
    Bound := Round(Radius);
    EndPoint := MakePointF(RandomIntRange(-Bound, Bound),
      RandomIntRange(-Bound, Bound));
    StartPoint := MakePointF(EndPoint.X + Sin(Pi + Angle) * (Radius * 4),
      EndPoint.Y - Cos(Pi + Angle) * (Radius * 4));
  until SegmentIntersectsRectEdges(StartPoint, EndPoint,
    MakePointF(-Radius * 1.2, -Radius * 1.2),
    MakePointF(1.2 * Radius, 1.2 * Radius), Intersection) and
    not IsNearView(Intersection);
  SetPosition(Intersection);
end;
{ @end $60E354 }

{ @routine $60E4D0 TMeteoriteSE_AdvanceMotion }
procedure TMeteoriteSE.AdvanceMotion(Timer: PSpaceTimerSE; UserData: Integer);
var Limit: Single;
begin
  SetPosition(MakePointF(Position.X + Sin(Angle) * Speed, Position.Y - Cos(Angle) * Speed));
  Limit := TProcessSE(Space.Process).SystemRadius * 1.3;
  if ((-Limit > Position.X) or (Position.X > Limit) or (-Limit > Position.Y) or (Position.Y > Limit)) and
    not IsNearView(Position) then RestartOutsideView;
end;
{ @end $60E4D0 }

{ @routine $60E580 TMeteoriteSE_LoadTemplate }
procedure TMeteoriteSE.LoadTemplate(Block: TBlockParEC);
var Range: TPointF;
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  TimerInterval := ExtractDigitsToIntW(Block.GetParam('Time'));
  Range := GetFloatPointGI(Block.GetParam('Speed'));
  Speed := RandomFloatRange(Range.X, Range.Y);
  Angle := HeadingDegreesToRadians(ExtractDecimalToSingleW(Block.GetParam('Angle')));
end;
{ @end $60E580 }

{ @routine $60E6A4 TMeteoriteSE_ApplyConfig }
procedure TMeteoriteSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $60E6A4 }

end.

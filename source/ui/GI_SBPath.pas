unit GI_SBPath;
// Unit bracket (inferred): CODE 0x0047C468..0x0047CD97; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_Image, GI_MessageLoop, Types;

type
  TSBPathPointsGI = array of TPoint;
  TSBPathGI = class(TObjectGI) // @size $128
  public
    PointCount: Integer; // @offset $100
    Points: array of TPoint; // @offset $104
    Minimum: Integer; // @offset $108
    Maximum: Integer; // @offset $10C
    Position: Integer; // @offset $110
    Dragging: Boolean; // @offset $114
    ThumbImage: TImageGI; // @offset $118
    HitRadius: Integer; // @offset $11C
    ChangeCallback: TObjectNotifyEventGI; // @offset $120
    constructor Create(Owner: TObjectGI); // @addr $47C5A8
    destructor Destroy; override; // @addr $47C61C
    procedure Clear; override; // @addr $47C644
    procedure SetImagePath(Path: WideString); // @addr $47C674
    procedure SetPositionValue(Value: Integer); // @addr $47C710
    procedure UpdateThumbPosition; // @addr $47C760
    function PositionFromPointIndex(Index: Integer): Integer; // @addr $47C7E8
    function FindClosestPoint(Point: TPoint; var DistanceSquared: Integer): Integer; // @addr $47C848
    procedure OnActivate; override; // @addr $47C8CC
    procedure OnDeactivate; override; // @addr $47C8E0
    procedure OnMouseEnter; override; // @addr $47C8F4
    procedure OnMouseLeave; override; // @addr $47C8FC
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $47C904
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $47C9C4
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $47C99C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47CA5C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47CA88
    procedure LoadPathProperties(Block: TBlockParEC); // @addr $47CAA4
  end;

implementation

// @unit-initialization $47CD90
// @unit-finalization $47CD60

uses Classes, SysUtils, GI_Main;

{ @routine $47C5A8 TSBPathGI_Create }
constructor TSBPathGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ThumbImage := TImageGI.Create(Self);
  Minimum := 0;
  Maximum := 100;
  Position := 0;
  HitRadius := 40;
  UpdateThumbPosition;
end;
{ @end $47C5A8 }

{ @routine $47C61C TSBPathGI_Destroy }
destructor TSBPathGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $47C61C }

{ @routine $47C644 TSBPathGI_Clear }
procedure TSBPathGI.Clear;
begin
  PointCount := 0;
  Points := nil;
  ThumbImage.Clear;
  inherited Clear;
end;
{ @end $47C644 }

{ @routine $47C674 TSBPathGI_SetImagePath }
procedure TSBPathGI.SetImagePath(Path: WideString);
begin
  ThumbImage.SetImagePath(Path);
  ThumbImage.SetSize(ThumbImage.GetContentSize);
  ThumbImage.SetOrigin(Classes.Point(ThumbImage.ClientSize.X div 2, ThumbImage.ClientSize.Y div 2));
end;
{ @end $47C674 }

{ @routine $47C710 TSBPathGI_SetPositionValue }
procedure TSBPathGI.SetPositionValue(Value: Integer);
begin
  if Position = Value then Exit;
  if Value < Minimum then Value := Minimum;
  if Value > Maximum then Value := Maximum;
  if Position = Value then Exit;
  Position := Value;
  UpdateThumbPosition;
  if Assigned(ChangeCallback) then ChangeCallback(Self);
end;
{ @end $47C710 }

{ @routine $47C760 TSBPathGI_UpdateThumbPosition }
procedure TSBPathGI.UpdateThumbPosition;
begin
  if PointCount < 1 then Exit;
  if Maximum - Minimum < 1 then ThumbImage.SetPosition(Points[0])
  else ThumbImage.SetPosition(Points[Round((Position - Minimum) / (Maximum - Minimum) * (PointCount - 1))]);
end;
{ @end $47C760 }

{ @routine $47C7E8 TSBPathGI_PositionFromPointIndex }
function TSBPathGI.PositionFromPointIndex(Index: Integer): Integer;
begin
  if PointCount < 2 then Result := Minimum
  else Result := Round(Index / (PointCount - 1) * (Maximum - Minimum) + Minimum);
end;
{ @end $47C7E8 }

{ @routine $47C848 TSBPathGI_FindClosestPoint }
function TSBPathGI.FindClosestPoint(Point: TPoint; var DistanceSquared: Integer): Integer;
var BestDistance, BestIndex, Distance, I: Integer;
begin
  BestDistance := 99999999;
  BestIndex := -1;
  for I := 0 to PointCount - 1 do
  begin
    Distance := Sqr(Point.X - Points[I].X) + Sqr(Point.Y - Points[I].Y);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      BestIndex := I;
    end;
  end;
  DistanceSquared := BestDistance;
  Result := BestIndex;
end;
{ @end $47C848 }

{ @routine $47C8CC TSBPathGI_OnActivate }
procedure TSBPathGI.OnActivate;
begin
  inherited OnActivate;
  Dragging := False;
end;
{ @end $47C8CC }

{ @routine $47C8E0 TSBPathGI_OnDeactivate }
procedure TSBPathGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Dragging := False;
end;
{ @end $47C8E0 }

{ @routine $47C8F4 TSBPathGI_OnMouseEnter }
procedure TSBPathGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;
{ @end $47C8F4 }

{ @routine $47C8FC TSBPathGI_OnMouseLeave }
procedure TSBPathGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
end;
{ @end $47C8FC }

{ @routine $47C904 TSBPathGI_ProcessLeftButtonDown }
procedure TSBPathGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var Index, Distance: Integer;
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if PointCount < 1 then Exit;
  Index := FindClosestPoint(ToLocalPoint(Point), Distance);
  if Sqr(HitRadius) > Distance then
  begin
    Position := PositionFromPointIndex(Index);
    UpdateThumbPosition;
    Dragging := True;
    if Assigned(ChangeCallback) then ChangeCallback(Self);
  end else Dragging := False;
end;
{ @end $47C904 }

{ @routine $47C99C TSBPathGI_ProcessLeftButtonUp }
procedure TSBPathGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  Dragging := False;
end;
{ @end $47C99C }

{ @routine $47C9C4 TSBPathGI_ProcessMouseMove }
procedure TSBPathGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var Index, Distance: Integer;
begin
  inherited ProcessMouseMove(KeyState, LocalPosition);
  if not Dragging then Exit;
  Index := FindClosestPoint(ToLocalPoint(Point), Distance);
  if Sqr(HitRadius) > Distance then
  begin
    Position := PositionFromPointIndex(Index);
    UpdateThumbPosition;
    Dragging := True;
    if Assigned(ChangeCallback) then ChangeCallback(Self);
  end else Dragging := False;
end;
{ @end $47C9C4 }

{ @routine $47CA5C TSBPathGI_LoadFromConfigPath }
procedure TSBPathGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadPathProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $47CA5C }

{ @routine $47CA88 TSBPathGI_LoadFromBlock }
procedure TSBPathGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadPathProperties(Block);
end;
{ @end $47CA88 }

{ @routine $47CAA4 TSBPathGI_LoadPathProperties }
procedure TSBPathGI.LoadPathProperties(Block: TBlockParEC);
var Path: TBlockParEC; I: Integer;
begin
  if Block.CountBlocks('Path') > 0 then
  begin
    Points := nil;
    Path := Block.GetBlock('Path');
    PointCount := Path.GetParamCount;
    SetLength(Points, PointCount);
    for I := 0 to PointCount - 1 do Points[I] := GetPointGI(Path.GetParamValue(I));
  end;
  if Block.CountParams('Image') > 0 then SetImagePath(Block.GetParam('Image'));
  if Block.CountParams('Min') > 0 then Minimum := StrToInt(Block.GetParam('Min'));
  if Block.CountParams('Max') > 0 then Maximum := StrToInt(Block.GetParam('Max'));
  if Minimum > Maximum then Minimum := Maximum;
  if Block.CountParams('Position') > 0 then SetPositionValue(StrToInt(Block.GetParam('Position')));
  if Block.CountParams('RadiusHit') > 0 then HitRadius := StrToInt(Block.GetParam('RadiusHit'));
  UpdateThumbPosition;
end;
{ @end $47CAA4 }

end.

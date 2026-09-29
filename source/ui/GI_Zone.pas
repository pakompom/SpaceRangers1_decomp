unit GI_Zone;
// Unit bracket (inferred): CODE 0x00486688..0x00486D2F; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, Types;

type
  TZoneKindGI = (zkRect = 0, zkCircle = 1); // @size 1
  TZoneGI = class(TObjectGI) // @size $128
  public
    Kind: TZoneKindGI; // @offset $100
    CursorInside: Boolean; // @offset $101
    EnterCallback: TObjectNotifyEventGI; // @offset $108
    LeaveCallback: TObjectNotifyEventGI; // @offset $110
    ZoneMouseDownCallback: TObjectMouseEventGI; // @offset $118
    ZoneMouseUpCallback: TObjectMouseEventGI; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $486794
    destructor Destroy; override; // @addr $4867CC
    procedure Invalidate; override; // @addr $486804 Native no-op: hit zones do not draw.
    function HitTest(Point: TPoint): Boolean; // @addr $486808 @note "Circle mode ignores Active and HitTestDisabled."
    procedure OnActivate; override; // @addr $4868D0 @note "May invoke cursor enter/leave callbacks."
    procedure OnDeactivate; override; // @addr $48694C
    procedure OnMouseEnter; override; // @addr $486980
    procedure OnMouseLeave; override; // @addr $4869FC
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $486A30
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $486AB0
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $486B4C Native calls inherited ProcessLeftButtonDown before the zone's up callback.
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $486BE8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $486C14
    procedure LoadZoneProperties(Block: TBlockParEC); // @addr $486C30
    procedure UpdateAutoGeometry; override; // @addr $486CF0
    procedure SetKind(Value: TZoneKindGI); // @addr $4867F4
  end;

implementation

// @unit-initialization $486D28
// @unit-finalization $486CF8

uses EC_Struct, Math, GR_Main;

{ @routine $486794 TZoneGI_Create }
constructor TZoneGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;
{ @end $486794 }

{ @routine $4867CC TZoneGI_Destroy }
destructor TZoneGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $4867CC }

{ @routine $4867F4 TZoneGI_SetKind }
procedure TZoneGI.SetKind(Value: TZoneKindGI);
begin
  if Kind <> Value then Kind := Value;
end;
{ @end $4867F4 }

{ @routine $486804 TZoneGI_Invalidate }
procedure TZoneGI.Invalidate;
begin
end;
{ @end $486804 }

{ @routine $486808 TZoneGI_HitTest }
function TZoneGI.HitTest(Point: TPoint): Boolean;
begin
  Result := False;
  if Kind = zkRect then Result := ContainsPoint(Point)
  else if Kind = zkCircle then
  begin
    Result := Sqr(Min(HitTestBounds.Right - HitTestBounds.Left, HitTestBounds.Bottom - HitTestBounds.Top) / 2) >= PointDistanceSquared(MakePointF((HitTestBounds.Left + HitTestBounds.Right) div 2,
      (HitTestBounds.Top + HitTestBounds.Bottom) div 2), PointToPointF(Point));
  end;
end;
{ @end $486808 }

{ @routine $4868D0 TZoneGI_OnActivate }
procedure TZoneGI.OnActivate;
begin
  inherited OnActivate;
  if HitTest(MessageLoop.GetCursorPoint) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $4868D0 }

{ @routine $48694C TZoneGI_OnDeactivate }
procedure TZoneGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if CursorInside then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $48694C }

{ @routine $486980 TZoneGI_OnMouseEnter }
procedure TZoneGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if HitTest(MessageLoop.GetCursorPoint) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $486980 }

{ @routine $4869FC TZoneGI_OnMouseLeave }
procedure TZoneGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if CursorInside then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $4869FC }

{ @routine $486A30 TZoneGI_ProcessMouseMove }
procedure TZoneGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessMouseMove(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then EnterCallback(Self);
    end;
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $486A30 }

{ @routine $486AB0 TZoneGI_ProcessLeftButtonDown }
procedure TZoneGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then EnterCallback(Self);
    end;
    if Assigned(ZoneMouseDownCallback) then ZoneMouseDownCallback(Self, KeyState, Point);
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $486AB0 }

{ @routine $486B4C TZoneGI_ProcessLeftButtonUp }
procedure TZoneGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if HitTest(Point) then
  begin
    if not CursorInside then
    begin
      CursorInside := True;
      if Assigned(EnterCallback) then EnterCallback(Self);
    end;
    if Assigned(ZoneMouseUpCallback) then ZoneMouseUpCallback(Self, KeyState, Point);
  end
  else if CursorInside = True then
  begin
    CursorInside := False;
    if Assigned(LeaveCallback) then LeaveCallback(Self);
  end;
end;
{ @end $486B4C }

{ @routine $486BE8 TZoneGI_LoadFromConfigPath }
procedure TZoneGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadZoneProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $486BE8 }

{ @routine $486C14 TZoneGI_LoadFromBlock }
procedure TZoneGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadZoneProperties(Block);
end;
{ @end $486C14 }

{ @routine $486C30 TZoneGI_LoadZoneProperties }
procedure TZoneGI.LoadZoneProperties(Block: TBlockParEC);
var
  Value: WideString;
begin
  if Block.CountParams('Kind') > 0 then
  begin
    Value := Block.GetParam('Kind');
    if Value = 'Rect' then SetKind(zkRect)
    else if Value = 'Circle' then SetKind(zkCircle);
  end;
end;
{ @end $486C30 }

{ @routine $486CF0 TZoneGI_UpdateAutoGeometry }
procedure TZoneGI.UpdateAutoGeometry;
begin
  inherited UpdateAutoGeometry;
end;
{ @end $486CF0 }

end.

unit GI_Panel;
// Unit bracket (inferred): CODE 0x00469034..0x00469CDB; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, Types;

type
  TPanelScrollTypeGI = (pstSimple = 0, pstAll = 1, pstObj = 2, pstView = 3); // @size 1

  TPanelGI = class(TObjectGI) // @size $118
  public
    DragScrollingEnabled: Boolean; // @offset $100
    ScrollType: TPanelScrollTypeGI; // @offset $101
    Dragging: Boolean; // @offset $102
    LastDragPoint: TPoint; // @offset $103
    ScrollChangedCallback: TObjectNotifyEventGI; // @offset $110

    procedure Clear; override; // @addr $4691BC
    function GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint; override; // @addr $4691E8 @note "Only ModeW children are affected by scrolling."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4698FC
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $4696B8
    procedure OnMouseEnter; override; // @addr $469798
    procedure OnMouseLeave; override; // @addr $4697AC
    procedure OnActivate; override; // @addr $4696A4
    procedure ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $469804
    procedure ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $469894
    function ToLocalPoint(Point: TPoint): TPoint; override; // @addr $469230
    function ToAbsolutePoint(Point: TPoint): TPoint; override; // @addr $46925C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $469A5C
    procedure SetScrollOffset(Offset: TPoint); virtual; // @addr $4692B4 @slot $B8
    constructor Create(Owner: TObjectGI); // @addr $469148
    destructor Destroy; override; // @addr $469194
    procedure SetDragScrollingEnabled(Value: Boolean); // @addr $469288
    function GetVisibleContentRect: TRect; // @addr $469590
    procedure ScrollRectIntoView(Rect: TRect); // @addr $4695B4
  end;

implementation

// @unit-initialization $469CD4
// @unit-finalization $469CA4

uses Classes, EC_Str, GI_Main, GR_Main, SysUtils, EC_OKGF;

{ @routine $469148 TPanelGI_Create }
constructor TPanelGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  SkipOwnQueuedDraw := 1;
  DragScrollingEnabled := False;
  ScrollType := pstAll;
end;
{ @end $469148 }

{ @routine $469194 TPanelGI_Destroy }
destructor TPanelGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $469194 }

{ @routine $4691BC TPanelGI_Clear }
procedure TPanelGI.Clear;
begin
  inherited Clear;
  ScrollOffset.X := 0;
  ScrollOffset.Y := 0;
  Dragging := False;
  DragScrollingEnabled := False;
  ScrollType := pstAll;
end;
{ @end $4691BC }

{ @routine $4691E8 TPanelGI_GetChildAbsolutePosition }
function TPanelGI.GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint;
begin
  if not ModeW then
  begin
    Result.X := AbsolutePosition.X + LocalPosition.X;
    Result.Y := AbsolutePosition.Y + LocalPosition.Y;
  end
  else
  begin
    Result.X := AbsolutePosition.X + LocalPosition.X - ScrollOffset.X;
    Result.Y := AbsolutePosition.Y + LocalPosition.Y - ScrollOffset.Y;
  end;
end;
{ @end $4691E8 }

{ @routine $469230 TPanelGI_ToLocalPoint }
function TPanelGI.ToLocalPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X - AbsolutePosition.X + ScrollOffset.X;
  Result.Y := Point.Y - AbsolutePosition.Y + ScrollOffset.Y;
end;
{ @end $469230 }

{ @routine $46925C TPanelGI_ToAbsolutePoint }
function TPanelGI.ToAbsolutePoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X + AbsolutePosition.X - ScrollOffset.X;
  Result.Y := Point.Y + AbsolutePosition.Y - ScrollOffset.Y;
end;
{ @end $46925C }

{ @routine $469288 TPanelGI_SetDragScrollingEnabled }
procedure TPanelGI.SetDragScrollingEnabled(Value: Boolean);
begin
  if Value <> DragScrollingEnabled then
  begin
    DragScrollingEnabled := Value;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $469288 }

{ @routine $4692B4 TPanelGI_SetScrollOffset }
procedure TPanelGI.SetScrollOffset(Offset: TPoint);
var Child: TObjectGI; Delta: TPoint; DestRect, SourceRect: TRect;
begin
  if (ScrollOffset.X = Offset.X) and (ScrollOffset.Y = Offset.Y) then Exit;
  if ScrollType = pstSimple then
  begin
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
  end
  else if ScrollType = pstAll then
  begin
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end
  else if ScrollType = pstObj then
  begin
    MessageLoop.RegionDrawPending := True;
    MessageLoop.InvalidateMouseViewControls;
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.PositionModeW then Child.Invalidate;
      Child := Child.NextSibling;
    end;
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.PositionModeW then Child.Invalidate;
      Child := Child.NextSibling;
    end;
  end
  else if ScrollType = pstView then
  begin
    Delta.X := ScrollOffset.X - Offset.X;
    Delta.Y := ScrollOffset.Y - Offset.Y;
    if (Abs(Delta.X) > ClientSize.X div 2) or (Abs(Delta.Y) > ClientSize.Y div 2) then
    begin
      ScrollOffset := Offset;
      UpdateAbsolutePosition;
      UpdateSubtreeHitBounds;
      Invalidate;
      Exit;
    end;
    MessageLoop.DrawQueuedUpdateRects;
    ScrollOffset := Offset;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    MessageLoop.RootUiObject.InvalidateScrollOverlap(HitTestBounds, Delta, Self);
    DestRect := GetLocalBounds;
    SourceRect := DestRect;
    if Delta.X > 0 then
    begin
      InvalidateRect(Classes.Rect(DestRect.Left, DestRect.Top, DestRect.Left + Delta.X, DestRect.Bottom));
      Inc(DestRect.Left, Delta.X);
      Dec(SourceRect.Right, Delta.X);
    end
    else if Delta.X < 0 then
    begin
      InvalidateRect(Classes.Rect(DestRect.Right + Delta.X, DestRect.Top, DestRect.Right, DestRect.Bottom));
      Inc(DestRect.Right, Delta.X);
      Dec(SourceRect.Left, Delta.X);
    end;
    if Delta.Y > 0 then
    begin
      InvalidateRect(Classes.Rect(DestRect.Left, DestRect.Top, DestRect.Right, DestRect.Top + Delta.Y));
      Inc(DestRect.Top, Delta.Y);
      Dec(SourceRect.Bottom, Delta.Y);
    end
    else if Delta.Y < 0 then
    begin
      InvalidateRect(Classes.Rect(DestRect.Left, DestRect.Bottom + Delta.Y, DestRect.Right, DestRect.Bottom));
      Inc(DestRect.Bottom, Delta.Y);
      Dec(SourceRect.Top, Delta.Y);
    end;
    OKGR_CopySingleBuf_XY_XY_WORD(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      DestRect.Left, DestRect.Top, SourceRect.Left, SourceRect.Top,
      SourceRect.Right - SourceRect.Left, SourceRect.Bottom - SourceRect.Top);
  end;
end;
{ @end $4692B4 }

{ @routine $469590 TPanelGI_GetVisibleContentRect }
function TPanelGI.GetVisibleContentRect: TRect;
begin
  Result.Left := ScrollOffset.X - OriginPoint.X;
  Result.Top := ScrollOffset.Y - OriginPoint.Y;
  Result.Right := Result.Left + ClientSize.X;
  Result.Bottom := Result.Top + ClientSize.Y;
end;
{ @end $469590 }

{ @routine $4695B4 TPanelGI_ScrollRectIntoView }
procedure TPanelGI.ScrollRectIntoView(Rect: TRect);
var Offset: TPoint; Visible: TRect;
begin
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Bottom > Visible.Bottom then
  begin
    Offset.Y := Rect.Bottom - (Visible.Bottom - Visible.Top);
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Top < Visible.Top then
  begin
    Offset.Y := Rect.Top;
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Right > Visible.Right then
  begin
    Offset.X := Rect.Right - (Visible.Right - Visible.Left);
    SetScrollOffset(Offset);
  end;
  Offset := ScrollOffset;
  Visible := GetVisibleContentRect;
  if Rect.Left < Visible.Left then
  begin
    Offset.X := Rect.Left;
    SetScrollOffset(Offset);
  end;
end;
{ @end $4695B4 }

{ @routine $4696A4 TPanelGI_OnActivate }
procedure TPanelGI.OnActivate;
begin
  inherited OnActivate;
  Dragging := False;
end;
{ @end $4696A4 }

{ @routine $4696B8 TPanelGI_ProcessMouseMove }
procedure TPanelGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);

begin
  inherited ProcessMouseMove(KeyState, Point);
  if Dragging = True then
    if (Point.X <> LastDragPoint.X) or (Point.Y <> LastDragPoint.Y) then
    begin
      if MessageLoop.IsCursorImageSelected('Main') then MessageLoop.SetCursorByName('Scroll');

      SetScrollOffset(Classes.Point(ScrollOffset.X + LastDragPoint.X - Point.X,
        ScrollOffset.Y + LastDragPoint.Y - Point.Y));
      LastDragPoint := Point;
      if Assigned(ScrollChangedCallback) then ScrollChangedCallback(Self);
    end;
end;
{ @end $4696B8 }

{ @routine $469798 TPanelGI_OnMouseEnter }
procedure TPanelGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  Dragging := False;
end;
{ @end $469798 }

{ @routine $4697AC TPanelGI_OnMouseLeave }
procedure TPanelGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  Dragging := False;
  if MessageLoop.IsCursorImageSelected('Scroll') then MessageLoop.SetCursorByName('Main');
end;
{ @end $4697AC }

{ @routine $469804 TPanelGI_ProcessRightButtonDown }
procedure TPanelGI.ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessRightButtonDown(KeyState, Point);
  if not IsOccludedAtPoint(Point) and (DragScrollingEnabled = True) then
  begin
    Dragging := True;
    LastDragPoint := Point;
    if MessageLoop.IsCursorImageSelected('Main') then MessageLoop.SetCursorByName('Scroll');
  end;
end;
{ @end $469804 }

{ @routine $469894 TPanelGI_ProcessRightButtonUp }
procedure TPanelGI.ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessRightButtonUp(KeyState, Point);
  Dragging := False;
  if MessageLoop.IsCursorImageSelected('Scroll') then MessageLoop.SetCursorByName('Main');
end;
{ @end $469894 }

{ @routine $4698FC TPanelGI_LoadFromConfigPath }
procedure TPanelGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('CenterWorld') > 0 then
  begin
    Text := Block.GetParam('CenterWorld');
    ScrollOffset.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ScrollOffset.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('MoveWorld') > 0 then DragScrollingEnabled := ParseEnabledNameGI(Block.GetParam('MoveWorld'));
end;
{ @end $4698FC }

{ @routine $469A5C TPanelGI_LoadFromBlock }
procedure TPanelGI.LoadFromBlock(Block: TBlockParEC);
var Text: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('CenterWorld') > 0 then
  begin
    Text := Block.GetParam('CenterWorld');
    ScrollOffset.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ScrollOffset.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('MoveWorld') > 0 then
    if TrimWideString(Block.GetParam('MoveWorld')) = 'True' then DragScrollingEnabled := True;
  if Block.CountParams('TypeScroll') > 0 then
  begin
    Text := Block.GetParam('TypeScroll');
    if Text = 'Simple' then ScrollType := pstSimple
    else if Text = 'All' then ScrollType := pstAll
    else if Text = 'Obj' then ScrollType := pstObj
    else if Text = 'View' then ScrollType := pstView;
  end;
end;
{ @end $469A5C }

end.

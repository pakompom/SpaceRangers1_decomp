unit GI_PanelScrollBar;
// Unit bracket (inferred): CODE 0x0047AABC..0x0047B833; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, GI_Panel, GI_ScrollBar, Types;

type
  TPanelScrollBarGI = class(TPanelGI) // @size $144
  public
    HorizontalScrollBar: TScrollBarGI; // @offset $118
    VerticalScrollBar: TScrollBarGI; // @offset $11C
    AutoHorizontalPlacement: Boolean; // @offset $120
    AutoVerticalPlacement: Boolean; // @offset $121
    HorizontalScrollBarRect: TRect; // @offset $122
    VerticalScrollBarRect: TRect; // @offset $132
    ScrollbarsOutside: Boolean; // @offset $142
    UnlimitedWorld: Boolean; // @offset $143

    constructor Create(Owner: TObjectGI); // @addr $47ABD8
    destructor Destroy; override; // @addr $47AD60 @note "Frees both scrollbars, including when parented outside this panel."
    procedure Clear; override; // @addr $47ADB4
    procedure SetVerticalScrollBarConfigPath(Path: WideString); // @addr $47ADE4
    procedure SetHorizontalScrollbarEnabled(Value: Boolean); // @addr $47AE34
    procedure SetVerticalScrollbarEnabled(Value: Boolean); // @addr $47AE5C
    procedure SetScrollbarsOutside(Value: Boolean); // @addr $47AE84 @note "The panel retains ownership of scrollbars parented outside it."
    procedure SetUnlimitedWorldEnabled(Value: Boolean); // @addr $47AF38
    procedure SetSize(Size: TPoint); override; // @addr $47AF50
    procedure SetOrigin(Origin: TPoint); override; // @addr $47AF78
    procedure SetScrollOffset(Offset: TPoint); override; // @addr $47AFA0
    procedure SetDepth(NewDepth: Double); override; // @addr $47AFE4
    procedure UpdateScrollbarPlacement; // @addr $47B028
    procedure UpdateScrollRanges; // @addr $47B234 @note "Only active PositionModeW children contribute; scrollbars are excluded."
    procedure ScrollbarPositionChanged(Sender: TObjectGI); // @addr $47B330
    procedure PanelScrollChanged(Sender: TObjectGI); // @addr $47B368 @note "Clamps the panel back to scrollbar positions when UnlimitedWorld is false."
    procedure ScrollbarDestroyed(Sender: TObjectGI); // @addr $47B3C4
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $47B3E8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47B414
    procedure LoadScrollbarPanelProperties(Block: TBlockParEC); // @addr $47B430
  end;

implementation

// @unit-initialization $47B82C
// @unit-finalization $47B7FC

uses Classes, EC_Str, EC_Struct, GI_Main, GR_Main;

{ @routine $47ABD8 TPanelScrollBarGI_Create }
constructor TPanelScrollBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HorizontalScrollBar := TScrollBarGI.Create(Self);
  HorizontalScrollBar.UserValue := -1;
  VerticalScrollBar := TScrollBarGI.Create(Self);
  VerticalScrollBar.UserValue := -1;
  HorizontalScrollBar.DestroyNotify := ScrollbarDestroyed;
  VerticalScrollBar.DestroyNotify := ScrollbarDestroyed;
  HorizontalScrollBar.SetActive(False);
  HorizontalScrollBar.SetOrientation(1);
  HorizontalScrollBar.SetKindCalcMode(1);
  VerticalScrollBar.SetActive(False);
  VerticalScrollBar.SetOrientation(2);
  VerticalScrollBar.SetKindCalcMode(1);
  HorizontalScrollBar.SetDepth(-1E30);
  VerticalScrollBar.SetDepth(-1E30);
  HorizontalScrollBar.PositionChangedCallback := ScrollbarPositionChanged;
  VerticalScrollBar.PositionChangedCallback := ScrollbarPositionChanged;
  AutoHorizontalPlacement := True;
  AutoVerticalPlacement := True;
  ScrollbarsOutside := False;
  UnlimitedWorld := True;
  ScrollChangedCallback := PanelScrollChanged;
end;
{ @end $47ABD8 }

{ @routine $47AD60 TPanelScrollBarGI_Destroy }
destructor TPanelScrollBarGI.Destroy;
begin
  if HorizontalScrollBar <> nil then
  begin
    HorizontalScrollBar.Free;
    HorizontalScrollBar := nil;
  end;
  if VerticalScrollBar <> nil then
  begin
    VerticalScrollBar.Free;
    VerticalScrollBar := nil;
  end;
  inherited Destroy;
end;
{ @end $47AD60 }

{ @routine $47ADB4 TPanelScrollBarGI_Clear }
procedure TPanelScrollBarGI.Clear;
begin
  inherited Clear;
  if (HorizontalScrollBar <> nil) and (VerticalScrollBar <> nil) then SetScrollbarsOutside(False);
  UnlimitedWorld := True;
end;
{ @end $47ADB4 }

{ @routine $47ADE4 TPanelScrollBarGI_SetVerticalScrollBarConfigPath }
procedure TPanelScrollBarGI.SetVerticalScrollBarConfigPath(Path: WideString);
begin
  VerticalScrollBar.SetConfigPath(Path);
end;
{ @end $47ADE4 }

{ @routine $47AE34 TPanelScrollBarGI_SetHorizontalScrollbarEnabled }
procedure TPanelScrollBarGI.SetHorizontalScrollbarEnabled(Value: Boolean);
begin
  HorizontalScrollBar.SetActive(Value);
  if Value = True then HorizontalScrollBar.UpdateSizeForOrientation;
end;
{ @end $47AE34 }

{ @routine $47AE5C TPanelScrollBarGI_SetVerticalScrollbarEnabled }
procedure TPanelScrollBarGI.SetVerticalScrollbarEnabled(Value: Boolean);
begin
  VerticalScrollBar.SetActive(Value);
  if Value = True then VerticalScrollBar.UpdateSizeForOrientation;
end;
{ @end $47AE5C }

{ @routine $47AE84 TPanelScrollBarGI_SetScrollbarsOutside }
procedure TPanelScrollBarGI.SetScrollbarsOutside(Value: Boolean);
begin
  if Value <> ScrollbarsOutside then
  begin
    ScrollbarsOutside := Value;
    if not ScrollbarsOutside then
    begin
      HorizontalScrollBar.Reparent(Self);
      VerticalScrollBar.Reparent(Self);
      HorizontalScrollBar.SetDepth(-1E30);
      VerticalScrollBar.SetDepth(-1E30);
    end
    else
    begin
      HorizontalScrollBar.Reparent(Parent);
      VerticalScrollBar.Reparent(Parent);
      HorizontalScrollBar.SetDepth(Depth);
      VerticalScrollBar.SetDepth(Depth);
    end;
    UpdateScrollbarPlacement;
    Invalidate;
  end;
end;
{ @end $47AE84 }

{ @routine $47AF38 TPanelScrollBarGI_SetUnlimitedWorldEnabled }
procedure TPanelScrollBarGI.SetUnlimitedWorldEnabled(Value: Boolean);
begin
  if Value <> UnlimitedWorld then
  begin
    UnlimitedWorld := Value;
    Invalidate;
  end;
end;
{ @end $47AF38 }

{ @routine $47AF50 TPanelScrollBarGI_SetSize }
procedure TPanelScrollBarGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateScrollbarPlacement;
end;
{ @end $47AF50 }

{ @routine $47AF78 TPanelScrollBarGI_SetOrigin }
procedure TPanelScrollBarGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  UpdateScrollbarPlacement;
end;
{ @end $47AF78 }

{ @routine $47AFA0 TPanelScrollBarGI_SetScrollOffset }
procedure TPanelScrollBarGI.SetScrollOffset(Offset: TPoint);
begin
  inherited SetScrollOffset(Offset);
  if HorizontalScrollBar <> nil then HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  if VerticalScrollBar <> nil then VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
end;
{ @end $47AFA0 }

{ @routine $47AFE4 TPanelScrollBarGI_SetDepth }
procedure TPanelScrollBarGI.SetDepth(NewDepth: Double);
begin
  inherited SetDepth(NewDepth);
  if ScrollbarsOutside then
  begin
    HorizontalScrollBar.SetDepth(NewDepth);
    VerticalScrollBar.SetDepth(NewDepth);
  end;
end;
{ @end $47AFE4 }

{ @routine $47B028 TPanelScrollBarGI_UpdateScrollbarPlacement }
procedure TPanelScrollBarGI.UpdateScrollbarPlacement;
begin
  if not ScrollbarsOutside then
  begin
    if AutoHorizontalPlacement then
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(Classes.Point(0, ClientSize.Y - HorizontalScrollBar.ClientSize.Y));
      HorizontalScrollBar.SetSize(Classes.Point(ClientSize.X - VerticalScrollBar.ClientSize.X, HorizontalScrollBar.ClientSize.Y));
    end
    else
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(HorizontalScrollBarRect.TopLeft);
      HorizontalScrollBar.SetSize(SubtractPoints(HorizontalScrollBarRect.BottomRight, HorizontalScrollBarRect.TopLeft));
    end;
    if AutoVerticalPlacement then
    begin
      TObjectGI(VerticalScrollBar).SetPosition(Classes.Point(ClientSize.X - VerticalScrollBar.ClientSize.X, 0));
      VerticalScrollBar.SetSize(Classes.Point(VerticalScrollBar.ClientSize.X, ClientSize.Y - HorizontalScrollBar.ClientSize.Y));
    end
    else
    begin
      TObjectGI(VerticalScrollBar).SetPosition(VerticalScrollBarRect.TopLeft);
      VerticalScrollBar.SetSize(SubtractPoints(VerticalScrollBarRect.BottomRight, VerticalScrollBarRect.TopLeft));
    end;
  end
  else
  begin
    if AutoHorizontalPlacement then
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(Classes.Point(LocalPosition.X, LocalPosition.Y + ClientSize.Y));
      HorizontalScrollBar.SetSize(Classes.Point(ClientSize.X, HorizontalScrollBar.ClientSize.Y));
    end
    else
    begin
      TObjectGI(HorizontalScrollBar).SetPosition(HorizontalScrollBarRect.TopLeft);
      HorizontalScrollBar.SetSize(SubtractPoints(HorizontalScrollBarRect.BottomRight, HorizontalScrollBarRect.TopLeft));
    end;
    if AutoVerticalPlacement then
    begin
      TObjectGI(VerticalScrollBar).SetPosition(Classes.Point(LocalPosition.X + ClientSize.X, LocalPosition.Y));
      VerticalScrollBar.SetSize(Classes.Point(VerticalScrollBar.ClientSize.X, ClientSize.Y));
    end
    else
    begin
      TObjectGI(VerticalScrollBar).SetPosition(VerticalScrollBarRect.TopLeft);
      VerticalScrollBar.SetSize(SubtractPoints(VerticalScrollBarRect.BottomRight, VerticalScrollBarRect.TopLeft));
    end;
  end;
end;
{ @end $47B028 }

{ @routine $47B234 TPanelScrollBarGI_UpdateScrollRanges }
procedure TPanelScrollBarGI.UpdateScrollRanges;
var Child: TObjectGI; Bounds, ChildBounds: TRect;
begin
  if not Active then Exit;
  Bounds.Left := $7FFFFFF0;
  Bounds.Top := $7FFFFFF0;
  Bounds.Right := -$7FFFFFF0;
  Bounds.Bottom := -$7FFFFFF0;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child <> HorizontalScrollBar) and (Child <> VerticalScrollBar) and
      (Child.PositionModeW = True) and (Child.Active = True) then
    begin
      ChildBounds := Child.GetLocalBounds;
      if ChildBounds.Left < Bounds.Left then Bounds.Left := ChildBounds.Left;
      if ChildBounds.Top < Bounds.Top then Bounds.Top := ChildBounds.Top;
      if ChildBounds.Right > Bounds.Right then Bounds.Right := ChildBounds.Right;
      if ChildBounds.Bottom > Bounds.Bottom then Bounds.Bottom := ChildBounds.Bottom;
    end;
    Child := Child.NextSibling;
  end;
  if HorizontalScrollBar <> nil then
  begin
    HorizontalScrollBar.SetRange(Bounds.Left, Bounds.Right - 1);
    HorizontalScrollBar.SetPageSize(ClientSize.X);
    HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  end;
  if VerticalScrollBar <> nil then
  begin
    VerticalScrollBar.SetRange(Bounds.Top, Bounds.Bottom - 1);
    VerticalScrollBar.SetPageSize(ClientSize.Y);
    VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
  end;
end;
{ @end $47B234 }

{ @routine $47B330 TPanelScrollBarGI_ScrollbarPositionChanged }
procedure TPanelScrollBarGI.ScrollbarPositionChanged(Sender: TObjectGI);
begin
  SetScrollOffset(Classes.Point(HorizontalScrollBar.Position, VerticalScrollBar.Position));
end;
{ @end $47B330 }

{ @routine $47B368 TPanelScrollBarGI_PanelScrollChanged }
procedure TPanelScrollBarGI.PanelScrollChanged(Sender: TObjectGI);
begin
  HorizontalScrollBar.SetPositionInternal(ScrollOffset.X);
  VerticalScrollBar.SetPositionInternal(ScrollOffset.Y);
  if not UnlimitedWorld then SetScrollOffset(Classes.Point(HorizontalScrollBar.Position, VerticalScrollBar.Position));
end;
{ @end $47B368 }

{ @routine $47B3C4 TPanelScrollBarGI_ScrollbarDestroyed }
procedure TPanelScrollBarGI.ScrollbarDestroyed(Sender: TObjectGI);
begin
  if HorizontalScrollBar = Sender then HorizontalScrollBar := nil;
  if VerticalScrollBar = Sender then VerticalScrollBar := nil;
end;
{ @end $47B3C4 }

{ @routine $47B3E8 TPanelScrollBarGI_LoadFromConfigPath }
procedure TPanelScrollBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadScrollbarPanelProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $47B3E8 }

{ @routine $47B414 TPanelScrollBarGI_LoadFromBlock }
procedure TPanelScrollBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadScrollbarPanelProperties(Block);
end;
{ @end $47B414 }

{ @routine $47B430 TPanelScrollBarGI_LoadScrollbarPanelProperties }
procedure TPanelScrollBarGI.LoadScrollbarPanelProperties(Block: TBlockParEC);
begin
  if Block.CountParams('StyleBarX') > 0 then HorizontalScrollBar.SetConfigPath(Block.GetParam('StyleBarX'));
  if Block.CountParams('StyleBarY') > 0 then VerticalScrollBar.SetConfigPath(Block.GetParam('StyleBarY'));
  if Block.CountParams('ActiveBarX') > 0 then
  begin
    if Block.GetParam('ActiveBarX') = 'True' then SetHorizontalScrollbarEnabled(True)
    else SetHorizontalScrollbarEnabled(False);
  end;
  if Block.CountParams('ActiveBarY') > 0 then
  begin
    if Block.GetParam('ActiveBarY') = 'True' then SetVerticalScrollbarEnabled(True)
    else SetVerticalScrollbarEnabled(False);
  end;
  if Block.CountParams('ExternalSB') > 0 then
  begin
    if TrimWideString(Block.GetParam('ExternalSB')) = 'True' then SetScrollbarsOutside(True)
    else SetScrollbarsOutside(False);
  end;
  if Block.CountParams('UnlimitedWorld') > 0 then
  begin
    if TrimWideString(Block.GetParam('UnlimitedWorld')) = 'True' then SetUnlimitedWorldEnabled(True)
    else SetUnlimitedWorldEnabled(False);
  end;
  if Block.CountParams('PosAutoBarX') > 0 then AutoHorizontalPlacement := ParseEnabledNameGI(Block.GetParam('PosAutoBarX'));
  if Block.CountParams('PosAutoBarY') > 0 then AutoVerticalPlacement := ParseEnabledNameGI(Block.GetParam('PosAutoBarY'));
  if Block.CountParams('RectBarX') > 0 then HorizontalScrollBarRect := GetRectGI(Block.GetParam('RectBarX'));
  if Block.CountParams('RectBarY') > 0 then VerticalScrollBarRect := GetRectGI(Block.GetParam('RectBarY'));
  UpdateScrollbarPlacement;
  UpdateScrollRanges;
end;
{ @end $47B430 }

end.

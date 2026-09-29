unit GI_PlanetButton;
// Unit bracket (inferred): CODE 0x0048C030..0x0048C51F; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_Label, GI_MessageLoop, GI_Panel, GI_Planet, Types;

type
  TPlanetButtonGI = class(TPanelGI) // @size $124
  public
    NormalPlanet: TPlanetGI; // @offset $118
    HoverPlanet: TPlanetGI; // @offset $11C
    TextLabel: TLabelGI; // @offset $120

    constructor Create(Owner: TObjectGI); // @addr $48C148
    destructor Destroy; override; // @addr $48C200
    procedure Clear; override; // @addr $48C248 @note "The native implementation is empty; it does not reset panel or child state."
    procedure OnMouseEnter; override; // @addr $48C24C
    procedure OnMouseLeave; override; // @addr $48C274
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $48C29C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48C2D0
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48C2D8
  end;

implementation

// @unit-initialization $48C518
// @unit-finalization $48C4E8

{ @routine $48C148 TPlanetButtonGI_Create }
constructor TPlanetButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  NormalPlanet := TPlanetGI.Create(Self);
  NormalPlanet.SetDepth(2);
  HoverPlanet := TPlanetGI.Create(Self);
  HoverPlanet.SetDepth(2);
  HoverPlanet.SetActive(False);
  TextLabel := TLabelGI.Create(Self);
  TextLabel.SetDepth(1);
end;
{ @end $48C148 }

{ @routine $48C200 TPlanetButtonGI_Destroy }
destructor TPlanetButtonGI.Destroy;
begin
  NormalPlanet.Free;
  HoverPlanet.Free;
  TextLabel.Free;
  inherited Destroy;
end;
{ @end $48C200 }

{ @routine $48C248 TPlanetButtonGI_Clear }
procedure TPlanetButtonGI.Clear;
begin

end;
{ @end $48C248 }

{ @routine $48C24C TPlanetButtonGI_OnMouseEnter }
procedure TPlanetButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  NormalPlanet.SetActive(False);
  HoverPlanet.SetActive(True);
end;
{ @end $48C24C }

{ @routine $48C274 TPlanetButtonGI_OnMouseLeave }
procedure TPlanetButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  NormalPlanet.SetActive(True);
  HoverPlanet.SetActive(False);
end;
{ @end $48C274 }

{ @routine $48C29C TPlanetButtonGI_ProcessLeftButtonDown }
procedure TPlanetButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  DispatchNamedEvent(1, Point.X, Point.Y);
end;
{ @end $48C29C }

{ @routine $48C2D0 TPlanetButtonGI_LoadFromConfigPath }
procedure TPlanetButtonGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
end;
{ @end $48C2D0 }

{ @routine $48C2D8 TPlanetButtonGI_LoadFromBlock }
procedure TPlanetButtonGI.LoadFromBlock(Block: TBlockParEC);
begin
  TextLabel.SetActive(False);
  inherited LoadFromBlock(Block);
  NormalPlanet.SetImage(Block.GetParam('PN_Mask'), Block.GetParam('PN_Image'), Block.GetParam('PN_ImageLight'));
  SetSize(NormalPlanet.ClientSize);
  HoverPlanet.SetImage(Block.GetParam('PN_Mask'), Block.GetParam('PA_Image'), Block.GetParam('PA_ImageLight'));
  if Block.CountParams('Font') > 0 then TextLabel.SetFontName(Block.GetParam('Font'));
  if Block.CountParams('Text') > 0 then
  begin
    TextLabel.SetText(Block.GetParam('Text'));
    TextLabel.SetActive(True);
    TextLabel.SetSize(ClientSize);
  end;
end;
{ @end $48C2D8 }

end.

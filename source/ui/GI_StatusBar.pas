unit GI_StatusBar;
// Unit bracket (inferred): CODE 0x004895AC..0x00489E5F; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_Image, GI_MessageLoop, GI_Panel, Types;

type
  TStatusBarGI = class(TPanelGI) // @size $13C
  public
    Minimum: Double; // @offset $118
    Maximum: Double; // @offset $120
    Value: Double; // @offset $128
    LeftImage: TImageGI; // @offset $130
    CenterImage: TImageGI; // @offset $134
    RightImage: TImageGI; // @offset $138

    constructor Create(Owner: TObjectGI); // @addr $4896C4
    destructor Destroy; override; // @addr $4897DC
    procedure Clear; override; // @addr $489824
    procedure SetRange(MinValue, MaxValue: Double); // @addr $48984C @note "If MinValue exceeds MaxValue, lowers MinValue to MaxValue. Does not clamp the stored Value."
    procedure SetValue(NewValue: Double); // @addr $4898C0
    procedure SetSize(Size: TPoint); override; // @addr $48993C
    procedure UpdateImageLayout; // @addr $48996C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $489BFC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $489C28
    procedure LoadStatusProperties(Block: TBlockParEC); // @addr $489C44
  end;

implementation

// @unit-initialization $489E58
// @unit-finalization $489E28

uses Classes, EC_Str, GI_Main;

{ @routine $4896C4 TStatusBarGI_Create }
constructor TStatusBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  LeftImage := TImageGI.Create(Self);
  CenterImage := TImageGI.Create(Self);
  RightImage := TImageGI.Create(Self);
  LeftImage.SetDepth(1);
  LeftImage.SetImageKindX(ikxLeft);
  LeftImage.SetImageKindY(ikyCenter);
  CenterImage.SetDepth(1);
  CenterImage.SetImageKindX(ikxLeftFill);
  CenterImage.SetImageKindY(ikyCenter);
  RightImage.SetDepth(1);
  RightImage.SetImageKindX(ikxLeft);
  RightImage.SetImageKindY(ikyCenter);
  Minimum := 0;
  Maximum := 100;
end;
{ @end $4896C4 }

{ @routine $4897DC TStatusBarGI_Destroy }
destructor TStatusBarGI.Destroy;
begin
  LeftImage.Free;
  CenterImage.Free;
  RightImage.Free;
  inherited Destroy;
end;
{ @end $4897DC }

{ @routine $489824 TStatusBarGI_Clear }
procedure TStatusBarGI.Clear;
begin
  Minimum := 0;
  Maximum := 100;
  inherited Clear;
end;
{ @end $489824 }

{ @routine $48984C TStatusBarGI_SetRange }
procedure TStatusBarGI.SetRange(MinValue, MaxValue: Double);
begin
  if MinValue > MaxValue then MinValue := MaxValue;
  if (MinValue <> Minimum) or (MaxValue <> Maximum) then
  begin
    Minimum := MinValue;
    Maximum := MaxValue;
    UpdateImageLayout;
    Invalidate;
  end;
end;
{ @end $48984C }

{ @routine $4898C0 TStatusBarGI_SetValue }
procedure TStatusBarGI.SetValue(NewValue: Double);
begin
  if NewValue < Minimum then NewValue := Minimum;
  if NewValue > Maximum then NewValue := Maximum;
  if NewValue <> Value then
  begin
    Value := NewValue;
    UpdateImageLayout;
    Invalidate;
  end;
end;
{ @end $4898C0 }

{ @routine $48993C TStatusBarGI_SetSize }
procedure TStatusBarGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateImageLayout;
  Invalidate;
end;
{ @end $48993C }

{ @routine $48996C TStatusBarGI_UpdateImageLayout }
procedure TStatusBarGI.UpdateImageLayout;
var Width: Integer;
begin
  if Maximum - Minimum = 0 then Width := 0
  else Width := Round((Value - Minimum) / (Maximum - Minimum) * ClientSize.X);
  if Minimum = Value then
  begin
    LeftImage.SetSize(Classes.Point(0, ClientSize.Y));
    CenterImage.SetSize(Classes.Point(0, ClientSize.Y));
    RightImage.SetSize(Classes.Point(0, ClientSize.Y));
  end
  else if LeftImage.GetContentSize.X + RightImage.GetContentSize.X >= Width then
  begin
    LeftImage.SetSize(Classes.Point(LeftImage.GetContentSize.X, ClientSize.Y));
    CenterImage.SetSize(Classes.Point(0, ClientSize.Y));
    RightImage.SetSize(Classes.Point(RightImage.GetContentSize.X, ClientSize.Y));
    LeftImage.SetPosition(Classes.Point(0, 0));
    CenterImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
    RightImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
  end
  else
  begin
    LeftImage.SetSize(Classes.Point(LeftImage.GetContentSize.X, ClientSize.Y));
    CenterImage.SetSize(Classes.Point(Width - LeftImage.ClientSize.X - RightImage.ClientSize.X, ClientSize.Y));
    RightImage.SetSize(Classes.Point(RightImage.GetContentSize.X, ClientSize.Y));
    LeftImage.SetPosition(Classes.Point(0, 0));
    CenterImage.SetPosition(Classes.Point(LeftImage.ClientSize.X, 0));
    RightImage.SetPosition(Classes.Point(LeftImage.ClientSize.X + CenterImage.ClientSize.X, 0));
    CenterImage.SetImageKindX(ikxLeftFill);
  end;
end;
{ @end $48996C }

{ @routine $489BFC TStatusBarGI_LoadFromConfigPath }
procedure TStatusBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadStatusProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $489BFC }

{ @routine $489C28 TStatusBarGI_LoadFromBlock }
procedure TStatusBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadStatusProperties(Block);
end;
{ @end $489C28 }

{ @routine $489C44 TStatusBarGI_LoadStatusProperties }
procedure TStatusBarGI.LoadStatusProperties(Block: TBlockParEC);
begin
  if Block.CountParams('ImageLeft') > 0 then LeftImage.SetImagePath(Block.GetParam('ImageLeft'));
  if Block.CountParams('ImageMiddle') > 0 then CenterImage.SetImagePath(Block.GetParam('ImageMiddle'));
  if Block.CountParams('ImageRight') > 0 then RightImage.SetImagePath(Block.GetParam('ImageRight'));
  if (Block.CountParams('Min') > 0) and (Block.CountParams('Max') > 0) then
    SetRange(ExtractDecimalToSingleW(Block.GetParam('Min')), ExtractDecimalToSingleW(Block.GetParam('Max')));
  if Block.CountParams('Cur') > 0 then SetValue(ExtractDecimalToSingleW(Block.GetParam('Cur')));
  UpdateImageLayout;
end;
{ @end $489C44 }

end.

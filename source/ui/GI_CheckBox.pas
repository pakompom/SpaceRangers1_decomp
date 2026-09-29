unit GI_CheckBox;
// Unit bracket (inferred): CODE 0x0048C520..0x0048CBBB; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, GI_TransImage, Types;

type
  TCheckBoxGI = class(TObjectGI) // @size $118
  public
    CheckedImage: TTransImageGI; // @offset $100
    UncheckedImage: TTransImageGI; // @offset $104
    Checked: Boolean; // @offset $108
    ChangedCallback: TObjectNotifyEventGI; // @offset $110

    constructor Create(Owner: TObjectGI); // @addr $48C630
    destructor Destroy; override; // @addr $48C6E8
    procedure Clear; override; // @addr $48C724 @note "Only resets Checked; preserves child images and inherited state."
    procedure SetConfigPath(const Path: WideString); override; // @addr $48C72C
    procedure SetSize(Size: TPoint); override; // @addr $48C74C
    procedure RefreshStateImages; // @addr $48C7FC
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $48C974
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48C9F8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48CAC4
  end;

implementation

// @unit-initialization $48CBB4
// @unit-finalization $48CB84

uses Classes, EC_Str, GI_Main;

{ @routine $48C630 TCheckBoxGI_Create }
constructor TCheckBoxGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  CheckedImage := TTransImageGI.Create(Self);
  CheckedImage.SetImageKindX(ikxCenter);
  CheckedImage.SetImageKindY(ikyCenter);
  CheckedImage.SetActive(False);
  UncheckedImage := TTransImageGI.Create(Self);
  UncheckedImage.SetImageKindX(ikxCenter);
  UncheckedImage.SetImageKindY(ikyCenter);
  UncheckedImage.SetActive(True);
  Checked := False;
end;
{ @end $48C630 }

{ @routine $48C6E8 TCheckBoxGI_Destroy }
destructor TCheckBoxGI.Destroy;
begin
  CheckedImage.Free;
  UncheckedImage.Free;
  inherited Destroy;
end;
{ @end $48C6E8 }

{ @routine $48C724 TCheckBoxGI_Clear }
procedure TCheckBoxGI.Clear;
begin
  Checked := False;
end;
{ @end $48C724 }

{ @routine $48C72C TCheckBoxGI_SetConfigPath }
procedure TCheckBoxGI.SetConfigPath(const Path: WideString);
begin
  inherited SetConfigPath(Path);
  RefreshStateImages;
  Invalidate;
end;
{ @end $48C72C }

{ @routine $48C74C TCheckBoxGI_SetSize }
procedure TCheckBoxGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  CheckedImage.SetPosition(Classes.Point(Size.X div 2 - CheckedImage.ClientSize.X div 2, Size.Y div 2 - CheckedImage.ClientSize.Y div 2));
  UncheckedImage.SetPosition(Classes.Point(Size.X div 2 - UncheckedImage.ClientSize.X div 2, Size.Y div 2 - UncheckedImage.ClientSize.Y div 2));
end;
{ @end $48C74C }

{ @routine $48C7FC TCheckBoxGI_RefreshStateImages }
procedure TCheckBoxGI.RefreshStateImages;
begin
  CheckedImage.SetImagePath(ConfigPath + '.IChecked');
  CheckedImage.SetSize(CheckedImage.GetContentSize);
  UncheckedImage.SetImagePath(ConfigPath + '.IUnchecked');
  UncheckedImage.SetSize(UncheckedImage.GetContentSize);
  CheckedImage.SetPosition(Classes.Point(ClientSize.X div 2 - CheckedImage.ClientSize.X div 2, ClientSize.Y div 2 - CheckedImage.ClientSize.Y div 2));
  UncheckedImage.SetPosition(Classes.Point(ClientSize.X div 2 - UncheckedImage.ClientSize.X div 2, ClientSize.Y div 2 - UncheckedImage.ClientSize.Y div 2));
end;
{ @end $48C7FC }

{ @routine $48C974 TCheckBoxGI_ProcessLeftButtonDown }
procedure TCheckBoxGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Checked = True then
  begin
    Checked := False;
    CheckedImage.SetActive(False);
    UncheckedImage.SetActive(True);
  end
  else
  begin
    Checked := True;
    CheckedImage.SetActive(True);
    UncheckedImage.SetActive(False);
  end;
  if Assigned(ChangedCallback) then ChangedCallback(Self);
end;
{ @end $48C974 }

{ @routine $48C9F8 TCheckBoxGI_LoadFromConfigPath }
procedure TCheckBoxGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Checked') > 0 then
    if TrimWideString(Block.GetParam('Checked')) = 'True' then Checked := True
    else Checked := False;
end;
{ @end $48C9F8 }

{ @routine $48CAC4 TCheckBoxGI_LoadFromBlock }
procedure TCheckBoxGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  if Block.CountParams('Checked') > 0 then
    if TrimWideString(Block.GetParam('Checked')) = 'True' then Checked := True
    else Checked := False;
  RefreshStateImages;
end;
{ @end $48CAC4 }

end.

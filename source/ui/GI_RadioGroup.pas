unit GI_RadioGroup;
// Unit bracket (inferred): CODE 0x0048CBBC..0x0048D227; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, Types;

type
  TRadioGroupGI = class(TObjectGI) // @size $108
  public
    procedure Clear; override; // @addr $48CD30 Native empty override.
    SelectionChangedCallback: TObjectNotifyEventGI; // @offset $100

    constructor Create(Owner: TObjectGI); // @addr $48CCD0
    destructor Destroy; override; // @addr $48CD08
    procedure SetConfigPath(const Path: WideString); override; // @addr $48CD34
    procedure SetSize(Size: TPoint); override; // @addr $48CD54
    procedure AddItem(Name: WideString; Position: TPoint); // @addr $48CD6C
    procedure RefreshItemImages; // @addr $48CE50
    procedure ClearSelection; // @addr $48CF2C
    procedure SelectItem(Name: WideString); // @addr $48CF5C
    procedure ItemClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint); // @addr $48CFFC
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48D03C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48D044
  end;

implementation

// @unit-initialization $48D220
// @unit-finalization $48D1F0

uses Classes, SysUtils, EC_Str, GI_TransImage;

{ @routine $48CCD0 TRadioGroupGI_Create }
constructor TRadioGroupGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;
{ @end $48CCD0 }

{ @routine $48CD08 TRadioGroupGI_Destroy }
destructor TRadioGroupGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $48CD08 }

{ @routine $48CD30 TRadioGroupGI_Clear }
procedure TRadioGroupGI.Clear;
begin
end;
{ @end $48CD30 }

{ @routine $48CD34 TRadioGroupGI_SetConfigPath }
procedure TRadioGroupGI.SetConfigPath(const Path: WideString);
begin
  inherited SetConfigPath(Path);
  RefreshItemImages;
  Invalidate;
end;
{ @end $48CD34 }

{ @routine $48CD54 TRadioGroupGI_SetSize }
procedure TRadioGroupGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
end;
{ @end $48CD54 }

{ @routine $48CD6C TRadioGroupGI_AddItem }
procedure TRadioGroupGI.AddItem(Name: WideString; Position: TPoint);
var Image: TTransImageGI;
begin
  Image := TTransImageGI.Create(Self);
  Image.SetPosition(Position);
  Image.SetName(Name);
  Image.UserValue := 0;
  Image.SetActive(True);
  Image.LeftButtonDownCallback := ItemClick;
  Image := TTransImageGI.Create(Self);
  Image.SetPosition(Position);
  Image.SetName(Name);
  Image.UserValue := 1;
  Image.SetActive(False);
  Image.LeftButtonDownCallback := ItemClick;
  RefreshItemImages;
end;
{ @end $48CD6C }

{ @routine $48CE50 TRadioGroupGI_RefreshItemImages }
procedure TRadioGroupGI.RefreshItemImages;
var Item: TObjectGI;
begin
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.UserValue = 0 then (Item as TTransImageGI).SetImagePath(ConfigPath + '.IUnchecked')
    else (Item as TTransImageGI).SetImagePath(ConfigPath + '.IChecked');
    Item := Item.NextSibling;
  end;
end;
{ @end $48CE50 }

{ @routine $48CF2C TRadioGroupGI_ClearSelection }
procedure TRadioGroupGI.ClearSelection;
var Item: TObjectGI;
begin
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.UserValue = 0 then Item.SetActive(True)
    else Item.SetActive(False);
    Item := Item.NextSibling;
  end;
end;
{ @end $48CF2C }

{ @routine $48CF5C TRadioGroupGI_SelectItem }
procedure TRadioGroupGI.SelectItem(Name: WideString);
var Item: TObjectGI;
begin
  ClearSelection;
  Item := FirstChild;
  while Item <> nil do
  begin
    if Item.ControlName = Name then
    begin
      if Item.UserValue = 0 then Item.SetActive(False)
      else Item.SetActive(True);
    end
    else
    begin
      if Item.UserValue = 0 then Item.SetActive(True)
      else Item.SetActive(False);
    end;
    Item := Item.NextSibling;
  end;
end;
{ @end $48CF5C }

{ @routine $48CFFC TRadioGroupGI_ItemClick }
procedure TRadioGroupGI.ItemClick(Sender: TObjectGI; MouseState: Cardinal; Point: TPoint);
begin
  SelectItem(Sender.ControlName);
  if Assigned(SelectionChangedCallback) then SelectionChangedCallback(Self);
end;
{ @end $48CFFC }

{ @routine $48D03C TRadioGroupGI_LoadFromConfigPath }
procedure TRadioGroupGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
end;
{ @end $48D03C }

{ @routine $48D044 TRadioGroupGI_LoadFromBlock }
procedure TRadioGroupGI.LoadFromBlock(Block: TBlockParEC);
var
  Items: TBlockParEC;
  Index, Count: Integer;
  Text: WideString;
begin
  inherited LoadFromBlock(Block);
  if Block.CountBlocks('RadioButton') > 0 then
  begin
    Items := Block.GetBlock('RadioButton');
    Count := Items.GetParamCount;
    for Index := 0 to Count - 1 do
    begin
      Text := Items.GetParamValue(Index);
      AddItem(Items.GetParamName(Index), Classes.Point(
        StrToInt(AnsiString(ExtractDelimitedPartW(Text, 0, ','))),
        StrToInt(AnsiString(ExtractDelimitedPartW(Text, 1, ',')))));
    end;
  end;
  if Block.CountParams('Checked') > 0 then SelectItem(TrimWideString(Block.GetParam('Checked')));
end;
{ @end $48D044 }

end.

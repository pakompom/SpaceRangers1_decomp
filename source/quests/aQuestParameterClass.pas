unit aQuestParameterClass;
// Unit bracket (inferred): CODE 0x004D1954..0x004D221B; inclusive evidence, not full bounds.
// Field layouts follow the native protection traversals at $5E98EC and $5EB564.
interface
uses EC_Buf, aQuestParViewStringClass, aArtifactTextFieldClass, aQuestValueListClass, aQuestCPDiapClass;
type
  TQuestOutcome = (qoNone = 0, qoFailure = 1, qoSuccess = 2, qoDeath = 3); // @size $04
  TQuestParameter = class(TObject) // @size $5C
  public
    procedure LoadLegacyV4FromReader(Reader: TBufEC); // @addr $4D1DAC
    procedure LoadLegacyV3FromReader(Reader: TBufEC); // @addr $4D1CE8
    procedure LoadLegacyV2FromReader(Reader: TBufEC); // @addr $4D1C28
    procedure LoadLegacyV1FromReader(Reader: TBufEC); // @addr $4D1B70
    procedure LoadLegacyV0FromReader(Reader: TBufEC); // @addr $4D1A70
    function GetDisplayText(Value: Integer): WideString; // @addr $4D19B0
    procedure Reset(Index: Integer); // @addr $4D201C
    destructor Destroy; override; // @addr $4D1FA0
    constructor Create(Index: Integer); // @addr $4D1E5C
    MinValue: Integer; // @offset $4
    MaxValue: Integer; // @offset $8
    Value: Integer; // @offset $C
    NameText: TTextField; // @offset $10
    ValueText: TTextField; // @offset $14
    CriticalText: TTextField; // @offset $18
    CriticalOutcome: TQuestOutcome; // @offset $1C
    Hidden: Boolean; // @offset $20
    ShowWhenZero: Boolean; // @offset $21
    CriticalAtMinimum: Boolean; // @offset $22
    Enabled: Boolean; // @offset $23
    IsMoney: Boolean; // @offset $24
    ViewStrings: array[1..10] of TQuestParWiewString; // @offset $28
    ViewStringCount: Integer; // @offset $50
    InitialValues: TValuesList; // @offset $54
    InitialRange: TQuestCPDiapazone; // @offset $58
  end;
implementation

// @unit-initialization $4D2214
// @unit-finalization $4D21E4

uses EC_Str, SysUtils;

{ @routine $4D19B0 TQuestParameter_GetDisplayText }
function TQuestParameter.GetDisplayText(Value: Integer): WideString;
var
  I: Integer;
  Found: Boolean;
  SelectedText: WideString;
begin
  Found := False;
  for I := 1 to ViewStringCount do
  begin
    if (ViewStrings[I].MinValue > Value) or (ViewStrings[I].MaxValue < Value) then Continue;
    SelectedText := SysUtils.Trim(ViewStrings[I].Text.Text);
    Found := True;
    Break;
  end;
  if not Found then
  begin
    if ViewStrings[ViewStringCount].MaxValue < Value then SelectedText := ViewStrings[ViewStringCount].Text.Text
    else SelectedText := ViewStrings[1].Text.Text;
  end;
  Result := SelectedText;
end;
{ @end $4D19B0 }

{ @routine $4D1A70 TQuestParameter_LoadLegacyV0FromReader }
procedure TQuestParameter.LoadLegacyV0FromReader(Reader: TBufEC);
begin
  IsMoney := False;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  ValueText.LoadTextLinesFromReader(Reader);
  ViewStrings[1].MinValue := MinValue;
  ViewStrings[1].MaxValue := MaxValue;
  ViewStrings[1].Text.Text := TrimWideString(ValueText.Text);
  ViewStringCount := 1;
  CriticalText.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;
{ @end $4D1A70 }

{ @routine $4D1B70 TQuestParameter_LoadLegacyV1FromReader }
procedure TQuestParameter.LoadLegacyV1FromReader(Reader: TBufEC);
var I: Integer;
begin
  IsMoney := False;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  NameText.LoadTextLinesFromReader(Reader);
  for I := 1 to ViewStringCount do ViewStrings[I].LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;
{ @end $4D1B70 }

{ @routine $4D1C28 TQuestParameter_LoadLegacyV2FromReader }
procedure TQuestParameter.LoadLegacyV2FromReader(Reader: TBufEC);
var I: Integer;
begin
  IsMoney := False;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  for I := 1 to ViewStringCount do ViewStrings[I].LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
  InitialRange.Clear;
  InitialRange.AddRange(Value, Value);
end;
{ @end $4D1C28 }

{ @routine $4D1CE8 TQuestParameter_LoadLegacyV3FromReader }
procedure TQuestParameter.LoadLegacyV3FromReader(Reader: TBufEC);
var I: Integer;
begin
  IsMoney := False;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  for I := 1 to ViewStringCount do ViewStrings[I].LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
  InitialValues.LoadFromReader(Reader);
  InitialRange.LoadFromValues(InitialValues);
  InitialValues.Clear;
end;
{ @end $4D1CE8 }

{ @routine $4D1DAC TQuestParameter_LoadLegacyV4FromReader }
procedure TQuestParameter.LoadLegacyV4FromReader(Reader: TBufEC);
var I: Integer;
begin
  IsMoney := False;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Value := Reader.GetInt32;
  CriticalOutcome := TQuestOutcome(Reader.GetInt32);
  Hidden := Reader.GetBoolean;
  ShowWhenZero := Reader.GetBoolean;
  CriticalAtMinimum := Reader.GetBoolean;
  Enabled := Reader.GetBoolean;
  ViewStringCount := Reader.GetInt32;
  IsMoney := Reader.GetBoolean;
  NameText.LoadTextLinesFromReader(Reader);
  for I := 1 to ViewStringCount do ViewStrings[I].LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
  InitialRange.LoadFromReader(Reader);
end;
{ @end $4D1DAC }

{ @routine $4D1E5C TQuestParameter_Create }
constructor TQuestParameter.Create(Index: Integer);
var I: Integer;
begin
  inherited Create;
  for I := 1 to 10 do ViewStrings[I] := TQuestParWiewString.Create('Имя присвоенное при создании ' + IntToStr(Index));
  NameText := TTextField.Create;
  ValueText := TTextField.Create;
  CriticalText := TTextField.Create;
  InitialValues := TValuesList.Create;
  InitialRange := TQuestCPDiapazone.Create;
  Reset(Index);
end;
{ @end $4D1E5C }

{ @routine $4D1FA0 TQuestParameter_Destroy }
destructor TQuestParameter.Destroy;
begin
  if NameText <> nil then begin NameText.Free; NameText := nil; end;
  if ValueText <> nil then begin ValueText.Free; ValueText := nil; end;
  if CriticalText <> nil then begin CriticalText.Free; CriticalText := nil; end;
  if InitialValues <> nil then begin InitialValues.Free; InitialValues := nil; end;
  if InitialRange <> nil then begin InitialRange.Free; InitialRange := nil; end;
  // Native omits the ten ViewStrings objects.
  inherited Destroy;
end;
{ @end $4D1FA0 }

{ @routine $4D201C TQuestParameter_Reset }
procedure TQuestParameter.Reset(Index: Integer);
var I: Integer;
begin
  IsMoney := False;
  Enabled := False;
  Hidden := False;
  ShowWhenZero := True;
  CriticalAtMinimum := True;
  MinValue := 0;
  MaxValue := 1;
  InitialValues.Clear;
  InitialRange.Clear;
  ViewStringCount := 1;
  for I := 1 to 10 do ViewStrings[I].Text.Text := 'Параметр номер ' + IntToStr(Index) + ': <>';
  ViewStrings[1].MinValue := MinValue;
  ViewStrings[1].MaxValue := MaxValue;
  Value := 0;
  CriticalOutcome := qoNone;
  NameText.Text := 'Параметр номер ' + IntToStr(Index);
  ValueText.Text := 'Параметр номер ' + IntToStr(Index) + ': <>';
  CriticalText.Text := 'Сообщение достижения критического значения параметром ' + IntToStr(Index);
end;
{ @end $4D201C }

end.

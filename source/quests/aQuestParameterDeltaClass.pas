unit aQuestParameterDeltaClass;
// Unit bracket (inferred): CODE 0x004D0830..0x004D0BE7; inclusive evidence, not full bounds.
// Field layouts follow the native protection traversals at $5E98EC and $5EB564.
interface
uses EC_Buf, aArtifactTextFieldClass, aQuestValueListClass;
type
  TParameterVisibilityChange = (pvcUnchanged = 0, pvcShow = 1, pvcHide = 2); // @size $04
  TQuestParameterDelta = class(TObject) // @size $30
  public
    procedure LoadLegacyV3FromReader(Reader: TBufEC); // @addr $4D0894
    procedure LoadLegacyV2FromReader(Reader: TBufEC); // @addr $4D0928
    procedure LoadLegacyV1FromReader(Reader: TBufEC); // @addr $4D09A8
    procedure LoadLegacyV0FromReader(Reader: TBufEC); // @addr $4D0A1C
    procedure Reset; // @addr $4D0B58
    destructor Destroy; override; // @addr $4D0AEC
    constructor Create(Index: Integer); // @addr $4D0A74
    ValueConstraint: TValuesList; // @offset $4
    MultipleConstraint: TValuesList; // @offset $8
    RequiredBits: Integer; // @offset $C
    MinValue: Integer; // @offset $10
    MaxValue: Integer; // @offset $14
    ChangeValue: Integer; // @offset $18
    ChangeByPercent: Boolean; // @offset $1C
    SetValue: Boolean; // @offset $1D
    UseExpression: Boolean; // @offset $1E
    ExpressionText: TTextField; // @offset $20
    CriticalText: TTextField; // @offset $24
    VisibilityChange: TParameterVisibilityChange; // @offset $28
    LegacyFlag: Boolean; // @offset $2C
  end;
implementation

// @unit-initialization $4D0BE0
// @unit-finalization $4D0BB0

{ @routine $4D0894 TQuestParameterDelta_LoadLegacyV3FromReader }
procedure TQuestParameterDelta.LoadLegacyV3FromReader(Reader: TBufEC);
begin
  Reset;
  RequiredBits := Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  SetValue := Reader.GetBoolean;
  UseExpression := Reader.GetBoolean;
  ExpressionText.LoadTextLinesFromReader(Reader);
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D0894 }

{ @routine $4D0928 TQuestParameterDelta_LoadLegacyV2FromReader }
procedure TQuestParameterDelta.LoadLegacyV2FromReader(Reader: TBufEC);
begin
  Reset;
  RequiredBits := Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  SetValue := Reader.GetBoolean;
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D0928 }

{ @routine $4D09A8 TQuestParameterDelta_LoadLegacyV1FromReader }
procedure TQuestParameterDelta.LoadLegacyV1FromReader(Reader: TBufEC);
begin
  Reset;
  RequiredBits := Reader.GetInt32;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  ValueConstraint.LoadFromReader(Reader);
  MultipleConstraint.LoadFromReader(Reader);
  CriticalText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D09A8 }

{ @routine $4D0A1C TQuestParameterDelta_LoadLegacyV0FromReader }
procedure TQuestParameterDelta.LoadLegacyV0FromReader(Reader: TBufEC);
begin
  Reset;
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  ChangeValue := Reader.GetInt32;
  VisibilityChange := TParameterVisibilityChange(Reader.GetInt32);
  LegacyFlag := Reader.GetBoolean;
  ChangeByPercent := Reader.GetBoolean;
  CriticalText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D0A1C }

{ @routine $4D0A74 TQuestParameterDelta_Create }
constructor TQuestParameterDelta.Create(Index: Integer);
begin
  inherited Create;
  CriticalText := TTextField.Create;
  ValueConstraint := TValuesList.Create;
  MultipleConstraint := TValuesList.Create;
  ExpressionText := TTextField.Create;
  Reset;
end;
{ @end $4D0A74 }

{ @routine $4D0AEC TQuestParameterDelta_Destroy }
destructor TQuestParameterDelta.Destroy;
begin
  if CriticalText <> nil then begin CriticalText.Free; CriticalText := nil; end;
  if ValueConstraint <> nil then begin ValueConstraint.Free; ValueConstraint := nil; end;
  if MultipleConstraint <> nil then begin MultipleConstraint.Free; MultipleConstraint := nil; end;
  if ExpressionText <> nil then begin ExpressionText.Free; ExpressionText := nil; end;
  inherited Destroy;
end;
{ @end $4D0AEC }

{ @routine $4D0B58 TQuestParameterDelta_Reset }
procedure TQuestParameterDelta.Reset;
begin
  RequiredBits := 0;
  MinValue := 0;
  MaxValue := 1;
  ChangeValue := 0;
  VisibilityChange := pvcUnchanged;
  CriticalText.Text := '';
  LegacyFlag := False;
  ChangeByPercent := False;
  SetValue := False;
  UseExpression := False;
  ValueConstraint.Clear;
  MultipleConstraint.Clear;
  ExpressionText.Text := '';
end;
{ @end $4D0B58 }

end.

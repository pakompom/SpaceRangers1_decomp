unit aArtifactPathClass;
// Unit bracket (inferred): CODE 0x004D7184..0x004D788F; inclusive evidence, not full bounds.
// Field layouts follow the native protection traversals at $5E98EC and $5EB564.
interface
uses EC_Buf, aArtifactTextFieldClass, aQuestParameterDeltaClass;
type
  TPath = class(TObject) // @size $1A0
  public
    procedure LoadLegacyV8FromReader(Reader: TBufEC); // @addr $4D77B4
    procedure LoadLegacyV7FromReader(Reader: TBufEC); // @addr $4D7710
    procedure LoadLegacyV6FromReader(Reader: TBufEC); // @addr $4D7678
    procedure LoadLegacyV5FromReader(Reader: TBufEC); // @addr $4D75E8
    procedure LoadLegacyV4FromReader(Reader: TBufEC); // @addr $4D7558
    procedure LoadLegacyV3FromReader(Reader: TBufEC); // @addr $4D74E0
    procedure LoadLegacyV2FromReader(Reader: TBufEC); // @addr $4D7468
    procedure LoadLegacyV1FromReader(Reader: TBufEC); // @addr $4D73F8
    procedure LoadLegacyV0FromReader(Reader: TBufEC); // @addr $4D7394
    constructor Create(Index, FromId, ToId, Unused1, Unused2, Unused3, Unused4, Unused5, Unused6: Integer); // @addr $4D7278 @note "The final six stack dwords are ignored; their original types and grouping remain unresolved."
    destructor Destroy; override; // @addr $4D731C
    procedure Reset; // @addr $4D7204
    Priority: Double; // @offset $8
    IsAutomatic: Boolean; // @offset $10
    AlwaysShow: Boolean; // @offset $11
    UnresolvedValue14: Integer; // @offset $14
    DisplayOrder: Integer; // @offset $18
    Id: Integer; // @offset $1C
    TraversalLimit: Integer; // @offset $20
    FromLocationId: Integer; // @offset $24
    ToLocationId: Integer; // @offset $28
    ChoiceText: TTextField; // @offset $2C
    TransitionText: TTextField; // @offset $30
    ConditionExpression: TTextField; // @offset $34
    ParameterChanges: array[1..48] of TQuestParameterDelta; // @offset $38
  end;
implementation

// @unit-initialization $4D7888
// @unit-finalization $4D7858

{ @routine $4D7204 TPath_Reset }
procedure TPath.Reset;
var I: Integer;
begin
  UnresolvedValue14 := 0;
  DisplayOrder := 5;
  Priority := 1;
  TraversalLimit := 1;
  Id := 0;
  FromLocationId := 0;
  ToLocationId := 0;
  ChoiceText.Text := '';
  TransitionText.Text := '';
  ConditionExpression.Text := '';
  for I := 1 to 48 do ParameterChanges[I].Reset;
  IsAutomatic := True;
  AlwaysShow := False;
end;
{ @end $4D7204 }

{ @routine $4D7278 TPath_Create }
constructor TPath.Create(Index, FromId, ToId, Unused1, Unused2, Unused3, Unused4, Unused5, Unused6: Integer);
var I: Integer;
begin
  inherited Create;
  ChoiceText := TTextField.Create;
  TransitionText := TTextField.Create;
  ConditionExpression := TTextField.Create;
  for I := 1 to 48 do ParameterChanges[I] := TQuestParameterDelta.Create(I);
  Reset;
  Id := Index;
  ToLocationId := ToId;
  FromLocationId := FromId;
end;
{ @end $4D7278 }

{ @routine $4D731C TPath_Destroy }
destructor TPath.Destroy;
var I: Integer;
begin
  if ChoiceText <> nil then begin ChoiceText.Free; ChoiceText := nil; end;
  if TransitionText <> nil then begin TransitionText.Free; TransitionText := nil; end;
  if ConditionExpression <> nil then begin ConditionExpression.Free; ConditionExpression := nil; end;
  for I := 1 to 48 do begin
    if ParameterChanges[I] <> nil then begin ParameterChanges[I].Free; ParameterChanges[I] := nil; end;
  end;
  inherited Destroy;
end;
{ @end $4D731C }

{ @routine $4D7394 TPath_LoadLegacyV0FromReader }
procedure TPath.LoadLegacyV0FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D7394 }

{ @routine $4D73F8 TPath_LoadLegacyV1FromReader }
procedure TPath.LoadLegacyV1FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D73F8 }

{ @routine $4D7468 TPath_LoadLegacyV2FromReader }
procedure TPath.LoadLegacyV2FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D7468 }

{ @routine $4D74E0 TPath_LoadLegacyV3FromReader }
procedure TPath.LoadLegacyV3FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D74E0 }

{ @routine $4D7558 TPath_LoadLegacyV4FromReader }
procedure TPath.LoadLegacyV4FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  UnresolvedValue14 := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for I := 1 to 12 do ParameterChanges[I].LoadLegacyV1FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D7558 }

{ @routine $4D75E8 TPath_LoadLegacyV5FromReader }
procedure TPath.LoadLegacyV5FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  UnresolvedValue14 := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for I := 1 to 12 do ParameterChanges[I].LoadLegacyV2FromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D75E8 }

{ @routine $4D7678 TPath_LoadLegacyV6FromReader }
procedure TPath.LoadLegacyV6FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  UnresolvedValue14 := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  for I := 1 to 24 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  ConditionExpression.LoadTextLinesFromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D7678 }

{ @routine $4D7710 TPath_LoadLegacyV7FromReader }
procedure TPath.LoadLegacyV7FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  UnresolvedValue14 := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  for I := 1 to 24 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  ConditionExpression.LoadTextLinesFromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D7710 }

{ @routine $4D77B4 TPath_LoadLegacyV8FromReader }
procedure TPath.LoadLegacyV8FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Priority := Reader.GetDouble;
  UnresolvedValue14 := Reader.GetInt32;
  Id := Reader.GetInt32;
  FromLocationId := Reader.GetInt32;
  ToLocationId := Reader.GetInt32;
  IsAutomatic := Reader.GetBoolean;
  AlwaysShow := Reader.GetBoolean;
  TraversalLimit := Reader.GetInt32;
  DisplayOrder := Reader.GetInt32;
  for I := 1 to 48 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  ConditionExpression.LoadTextLinesFromReader(Reader);
  ChoiceText.LoadTextLinesFromReader(Reader);
  TransitionText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D77B4 }

end.

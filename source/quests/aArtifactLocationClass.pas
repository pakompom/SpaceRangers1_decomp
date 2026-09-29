unit aArtifactLocationClass;
// Unit bracket (inferred): CODE 0x004D66A4..0x004D7183; inclusive evidence, not full bounds.
// Field layouts follow the native protection traversals at $5E98EC and $5EB564.
interface
uses EC_Buf, aArtifactTextFieldClass, aQuestParameterDeltaClass, aQuestCalcParseClass;
type
  TLocation = class(TObject) // @size $11C
  public
    procedure LoadLegacyV6FromReader(Reader: TBufEC); // @addr $4D6B1C
    procedure LoadLegacyV5FromReader(Reader: TBufEC); // @addr $4D6C00
    procedure LoadLegacyV4FromReader(Reader: TBufEC); // @addr $4D6CE4
    procedure LoadLegacyV3FromReader(Reader: TBufEC); // @addr $4D6DBC
    procedure LoadLegacyV2FromReader(Reader: TBufEC); // @addr $4D6E80
    procedure LoadLegacyV1FromReader(Reader: TBufEC); // @addr $4D6F44
    procedure LoadLegacyV0FromReader(Reader: TBufEC); // @addr $4D7048
    destructor Destroy; override; // @addr $4D6A84
    constructor Create(Index: Integer); // @addr $4D69D8
    procedure SelectEvent(var Parameters: TQuestParameterValues); // @addr $4D67D8
    procedure Reset; // @addr $4D6730
    EditorX: Integer; // @offset $04
    EditorY: Integer; // @offset $08
    Days: Integer; // @offset $C
    Id: Integer; // @offset $10
    UnresolvedText14: TTextField; // @offset $14
    SelectedEventText: TTextField; // @offset $18
    EventTexts: array[1..10] of TTextField; // @offset $1C
    UseEventExpression: Boolean; // @offset $44
    NextEventIndex: Integer; // @offset $48
    EventExpression: TTextField; // @offset $4C
    IsEmpty: Boolean; // @offset $50
    UnresolvedFlag51: Boolean; // @offset $51
    UnresolvedFlag52: Boolean; // @offset $52
    ParameterChanges: array[1..48] of TQuestParameterDelta; // @offset $54
    IsDeath: Boolean; // @offset $114
    UnresolvedFlag115: Boolean; // @offset $115
    IsStart: Boolean; // @offset $116
    IsSuccess: Boolean; // @offset $117
    IsFailure: Boolean; // @offset $118
  end;
implementation
// @unit-initialization $4D717C
// @unit-finalization $4D714C
uses EC_Str;

{ @routine $4D6730 TLocation_Reset }
procedure TLocation.Reset;
var I: Integer;
begin
  EditorX := 100;
  EditorY := 100;
  IsEmpty := False;
  Days := 0;
  for I := 1 to 48 do ParameterChanges[I].Reset;
  for I := 1 to 10 do EventTexts[I].ClearText;
  UseEventExpression := False;
  NextEventIndex := 1;
  EventExpression.ClearText;
  IsFailure := False;
  UnresolvedFlag51 := False;
  UnresolvedFlag52 := False;
  IsDeath := False;
  Id := 0;
  UnresolvedText14.ClearText;
  UnresolvedText14.Text := '';
  SelectedEventText.ClearText;
  SelectedEventText.Text := '';
  IsStart := False;
  IsSuccess := False;
end;
{ @end $4D6730 }

{ @routine $4D67D8 TLocation_SelectEvent }
procedure TLocation.SelectEvent(var Parameters: TQuestParameterValues);
var
  Found: Boolean;
  I, Attempts: Integer;
  Text: WideString;
  Calc: TQuestCalcParse;
  Valid: Boolean;
begin
  Found := False;
  if UseEventExpression then begin
    Valid := True;
    Calc := TQuestCalcParse.Create;
    Calc.Prepare(EventExpression.Text, 1);
    if Calc.HasError or Calc.UsesDefaultParameter then Valid := False;
    if Valid then begin
      Calc.Evaluate(Parameters);
      if Calc.EvaluationError then Valid := False;
    end;
    if Valid then
      if (Calc.ResultValue > 10) or (Calc.ResultValue < 1) then Valid := False;
    if Valid then
      if TrimWideString(EventTexts[Calc.ResultValue].Text) = '' then Valid := False;
    if Valid then Text := TrimWideString(EventTexts[Calc.ResultValue].Text);
    Calc.Destroy;
    if not Valid then begin
      Attempts := 0;
      while not Found do begin
        I := Random(10) + 1;
        Text := TrimWideString(EventTexts[I].Text);
        if Text <> '' then begin
          Found := True;
          SelectedEventText.Text := Text;
        end else Inc(Attempts);
        if Attempts > 20 then begin
          Text := '';
          Found := True;
        end;
      end;
    end;
  end else begin
    I := NextEventIndex;
    Attempts := 0;
    while not Found do begin
      Text := TrimWideString(EventTexts[I].Text);
      if Text <> '' then begin
        Found := True;
        SelectedEventText.Text := Text;
        NextEventIndex := I + 1;
        if NextEventIndex > 10 then NextEventIndex := 1;
      end else Inc(Attempts);
      Inc(I);
      if I > 10 then I := 1;
      if Attempts > 10 then begin
        Text := '';
        Found := True;
        NextEventIndex := I;
      end;
    end;
  end;
  SelectedEventText.Text := Text;
end;
{ @end $4D67D8 }

{ @routine $4D69D8 TLocation_Create }
constructor TLocation.Create(Index: Integer);
var I: Integer;
begin
  inherited Create;
  for I := 1 to 10 do EventTexts[I] := TTextField.Create;
  Id := Index;
  SelectedEventText := TTextField.Create;
  UnresolvedText14 := TTextField.Create;
  EventExpression := TTextField.Create;
  for I := 1 to 48 do ParameterChanges[I] := TQuestParameterDelta.Create(I);
end;
{ @end $4D69D8 }

{ @routine $4D6A84 TLocation_Destroy }
destructor TLocation.Destroy;
var I: Integer;
begin
  for I := 1 to 10 do begin
    if EventTexts[I] <> nil then begin EventTexts[I].Free; EventTexts[I] := nil; end;
  end;
  if SelectedEventText <> nil then begin SelectedEventText.Free; SelectedEventText := nil; end;
  if UnresolvedText14 <> nil then begin UnresolvedText14.Free; UnresolvedText14 := nil; end;
  if EventExpression <> nil then begin EventExpression.Free; EventExpression := nil; end;
  for I := 1 to 48 do begin
    if ParameterChanges[I] <> nil then begin ParameterChanges[I].Free; ParameterChanges[I] := nil; end;
  end;
  inherited Destroy;
end;
{ @end $4D6A84 }

{ @routine $4D6B1C TLocation_LoadLegacyV6FromReader }
procedure TLocation.LoadLegacyV6FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for I := 1 to 48 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  for I := 1 to 10 do EventTexts[I].LoadTextLinesFromReader(Reader);
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
  EventExpression.LoadTextLinesFromReader(Reader);
  SelectedEventText.Text := '';
end;
{ @end $4D6B1C }

{ @routine $4D6C00 TLocation_LoadLegacyV5FromReader }
procedure TLocation.LoadLegacyV5FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for I := 1 to 24 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  for I := 1 to 10 do EventTexts[I].LoadTextLinesFromReader(Reader);
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
  EventExpression.LoadTextLinesFromReader(Reader);
  SelectedEventText.Text := '';
end;
{ @end $4D6C00 }

{ @routine $4D6CE4 TLocation_LoadLegacyV4FromReader }
procedure TLocation.LoadLegacyV4FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  IsEmpty := Reader.GetBoolean;
  for I := 1 to 24 do ParameterChanges[I].LoadLegacyV3FromReader(Reader);
  for I := 1 to 10 do EventTexts[I].LoadTextLinesFromReader(Reader);
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
  SelectedEventText.Text := '';
end;
{ @end $4D6CE4 }

{ @routine $4D6DBC TLocation_LoadLegacyV3FromReader }
procedure TLocation.LoadLegacyV3FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for I := 1 to 12 do ParameterChanges[I].LoadLegacyV2FromReader(Reader);
  for I := 1 to 10 do EventTexts[I].LoadTextLinesFromReader(Reader);
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D6DBC }

{ @routine $4D6E80 TLocation_LoadLegacyV2FromReader }
procedure TLocation.LoadLegacyV2FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  Days := Reader.GetInt32;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for I := 1 to 12 do ParameterChanges[I].LoadLegacyV1FromReader(Reader);
  for I := 1 to 10 do EventTexts[I].LoadTextLinesFromReader(Reader);
  UseEventExpression := Reader.GetBoolean;
  NextEventIndex := Reader.GetInt32;
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
end;
{ @end $4D6E80 }

{ @routine $4D6F44 TLocation_LoadLegacyV1FromReader }
procedure TLocation.LoadLegacyV1FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  UseEventExpression := False;
  NextEventIndex := 1;
  Days := 0;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
  for I := 1 to 10 do EventTexts[I].Text := '';
  EventTexts[1].Text := TrimWideString(SelectedEventText.Text);
end;
{ @end $4D6F44 }

{ @routine $4D7048 TLocation_LoadLegacyV0FromReader }
procedure TLocation.LoadLegacyV0FromReader(Reader: TBufEC);
var I: Integer;
begin
  Reset;
  UseEventExpression := False;
  NextEventIndex := 1;
  Days := 0;
  EditorX := Reader.GetInt32;
  EditorY := Reader.GetInt32;
  Id := Reader.GetInt32;
  IsStart := Reader.GetBoolean;
  IsSuccess := Reader.GetBoolean;
  IsFailure := Reader.GetBoolean;
  IsDeath := Reader.GetBoolean;
  for I := 1 to 9 do ParameterChanges[I].LoadLegacyV0FromReader(Reader);
  UnresolvedText14.LoadTextLinesFromReader(Reader);
  SelectedEventText.LoadTextLinesFromReader(Reader);
  for I := 1 to 10 do EventTexts[I].Text := '';
  EventTexts[1].Text := TrimWideString(SelectedEventText.Text);
end;
{ @end $4D7048 }

end.

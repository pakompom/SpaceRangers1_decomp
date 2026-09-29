unit aQuestCPDiapClass;
// Unit bracket (inferred): CODE 0x004D0D74..0x004D1953; inclusive evidence, not full bounds.

interface

uses aQuestValueListClass, EC_Buf, EC_Struct;

type
  TQuestCPDiapazone = class(TObject) // @size $10
  public
    procedure LoadFromValues(var Source: TValuesList); // @addr $4D13B8
    procedure LoadFromReader(Reader: TBufEC); // @addr $4D0E40
    // Owned Delphi dynamic arrays, indexed 0..RangeCount-1; inclusive bounds.
    RangeStarts: array of Int64; // @offset $04
    RangeEnds: array of Int64; // @offset $08
    RangeCount: Integer; // @offset $0C

    constructor Create; // @addr $4D1438
    destructor Destroy; override; // @addr $4D1474
    procedure Clear; // @addr $4D149C
    procedure LoadFromText(Text: AnsiString); // @addr $4D1710 @note "Accepts internal [ahb;c] notation. Endpoints beyond +/-200000000 can widen intervals."
    procedure Assign(var Source: TQuestCPDiapazone); // @addr $4D1334
    procedure Append(var Source: TQuestCPDiapazone); // @addr $4D14DC @note "Preserves overlapping and duplicate ranges."
    procedure AddRange(MinValue, MaxValue: Int64); // @addr $4D1584 @note "Swaps reversed bounds; does not merge ranges."
    procedure AddValue(Value: Extended); // @addr $4D162C @note "Truncates to Int64; caught conversion errors preserve existing ranges."
    function GetMinimum: Int64; // @addr $4D0EB4 @note "Requires at least one range."
    function GetMaximum: Int64; // @addr $4D0F24 @note "Requires at least one range."
    function Contains(Value: Extended): Boolean; // @addr $4D1178 @note "Rounds with System.Round first."
    function GetRandomValue: Extended; // @addr $4D0FC0 @note "Zero when empty. Sampling weights overlaps repeatedly; lengths and results are 32-bit."
    function ToText: AnsiString; // @addr $4D11E4 @note "Uses [ahb;c] and signed low 32-bit endpoints; empty output is '['."
  end;

implementation

// @unit-initialization $4D194C
// @unit-finalization $4D191C

uses aArtifactTextFieldClass, EC_Str, SysUtils;

{ @routine $4D0E40 TQuestCPDiapazone_LoadFromReader }
procedure TQuestCPDiapazone.LoadFromReader(Reader: TBufEC);
var Field: TTextField;
begin
  Field := TTextField.Create;
  Field.LoadTextLinesFromReader(Reader);
  LoadFromText(AnsiString(Field.Text));
  Field.Destroy;
end;
{ @end $4D0E40 }

{ @routine $4D0EB4 TQuestCPDiapazone_GetMinimum }
function TQuestCPDiapazone.GetMinimum: Int64;
var
  i: Integer;
  Bound: Int64;
begin
  Bound := RangeStarts[0];
  for i := 0 to RangeCount - 1 do
    if RangeStarts[i] <= Bound then Bound := RangeStarts[i];
  Result := Bound;
end;
{ @end $4D0EB4 }

{ @routine $4D0F24 TQuestCPDiapazone_GetMaximum }
function TQuestCPDiapazone.GetMaximum: Int64;
var
  i: Integer;
  Bound: Int64;
begin
  Bound := RangeEnds[0];
  for i := 0 to RangeCount - 1 do
    if RangeEnds[i] >= Bound then Bound := RangeEnds[i];
  Result := Bound;
end;
{ @end $4D0F24 }

{ @routine $4D0FC0 TQuestCPDiapazone_GetRandomValue }
function TQuestCPDiapazone.GetRandomValue: Extended;
var
  i, RandomValue: Integer;
  Value: Extended;
  Ends, Starts: array of Int64;
begin
    SetLength(Ends, RangeCount);
    SetLength(Starts, RangeCount);
    RandomValue := 0;
    for i := 0 to RangeCount - 1 do
    begin
      Starts[i] := RandomValue;
      Ends[i] := RangeEnds[i] - RangeStarts[i] + Starts[i];
      RandomValue := RandomValue + RangeEnds[i] - RangeStarts[i] + 1;
    end;
    RandomValue := System.Random(RandomValue);
    Value := 0;
    // Native scan includes RangeCount and draws again within the selected range.
    for i := 0 to RangeCount do
      if (RandomValue >= Starts[i]) and (RandomValue <= Ends[i]) then
      begin
        Value := System.Random(RangeEnds[i] - RangeStarts[i] + 1) + RangeStarts[i];
        Break;
      end;
  Result := Value;
end;
{ @end $4D0FC0 }

{ @routine $4D1178 TQuestCPDiapazone_Contains }
function TQuestCPDiapazone.Contains(Value: Extended): Boolean;
var
  i: Integer;
  Rounded: Int64;
begin
  Rounded := System.Round(Value);
  Result := False;
  for i := 0 to RangeCount - 1 do
    if (RangeStarts[i] <= Rounded) and (RangeEnds[i] >= Rounded) then
    begin Result := True; Break end;
end;
{ @end $4D1178 }

{ @routine $4D11E4 TQuestCPDiapazone_ToText }
function TQuestCPDiapazone.ToText: AnsiString;
var
  i: Integer;
  Text: AnsiString;
begin
  Text := '[';
  for i := 0 to RangeCount - 1 do
  begin
    if RangeStarts[i] = RangeEnds[i] then Text := Text + IntToStr(RangeStarts[i])
    else Text := Text + IntToStr(RangeStarts[i]) + 'h' + IntToStr(RangeEnds[i]);
    if i < RangeCount - 1 then Text := Text + ';'
    else Text := Text + ']';
  end;
  Result := Text;
end;
{ @end $4D11E4 }

{ @routine $4D1334 TQuestCPDiapazone_Assign }
procedure TQuestCPDiapazone.Assign(var Source: TQuestCPDiapazone);
var
  i: Integer;
begin
  RangeCount := Source.RangeCount;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  for i := 0 to RangeCount - 1 do
  begin
    RangeStarts[i] := Source.RangeStarts[i];
    RangeEnds[i] := Source.RangeEnds[i];
  end;
end;
{ @end $4D1334 }

{ @routine $4D13B8 TQuestCPDiapazone_LoadFromValues }
procedure TQuestCPDiapazone.LoadFromValues(var Source: TValuesList);
var I: Integer;
begin
  RangeCount := Source.Count;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  for I := 0 to RangeCount - 1 do begin
    RangeStarts[I] := Source.Values[I + 1];
    RangeEnds[I] := Source.Values[I + 1];
  end;
end;
{ @end $4D13B8 }

{ @routine $4D1438 TQuestCPDiapazone_Create }
constructor TQuestCPDiapazone.Create;
begin
  inherited Create;
  Clear;
end;
{ @end $4D1438 }

{ @routine $4D1474 TQuestCPDiapazone_Destroy }
destructor TQuestCPDiapazone.Destroy;
begin
  inherited Destroy;
end;
{ @end $4D1474 }

{ @routine $4D149C TQuestCPDiapazone_Clear }
procedure TQuestCPDiapazone.Clear;
begin
  RangeCount := 0;
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
end;
{ @end $4D149C }

{ @routine $4D14DC TQuestCPDiapazone_Append }
procedure TQuestCPDiapazone.Append(var Source: TQuestCPDiapazone);
var
  i: Integer;
begin
  if Source.RangeCount > 0 then
  begin
    SetLength(RangeStarts, RangeCount + Source.RangeCount);
    SetLength(RangeEnds, RangeCount + Source.RangeCount);
    for i := 0 to Source.RangeCount - 1 do
    begin
      RangeStarts[RangeCount + i] := Source.RangeStarts[i];
      RangeEnds[RangeCount + i] := Source.RangeEnds[i];
    end;
    RangeCount := RangeCount + Source.RangeCount;
  end;
end;
{ @end $4D14DC }

{ @routine $4D1584 TQuestCPDiapazone_AddRange }
procedure TQuestCPDiapazone.AddRange(MinValue, MaxValue: Int64);
var
  Temporary: Int64;
begin
  Inc(RangeCount);
  SetLength(RangeStarts, RangeCount);
  SetLength(RangeEnds, RangeCount);
  if MinValue > MaxValue then
  begin
    Temporary := MinValue;
    MinValue := MaxValue;
    MaxValue := Temporary;
  end;
  RangeStarts[RangeCount - 1] := MinValue;
  RangeEnds[RangeCount - 1] := MaxValue;
end;
{ @end $4D1584 }

{ @routine $4D162C TQuestCPDiapazone_AddValue }
procedure TQuestCPDiapazone.AddValue(Value: Extended);
var
  IntegerValue: Int64;
  Failed: Boolean;
begin
  IntegerValue := 0;
  Failed := False;
  try
    IntegerValue := Trunc(Value);
  except
    on EMathError do Failed := True;
  end;
  if not Failed then
  begin
    Inc(RangeCount);
    SetLength(RangeStarts, RangeCount);
    SetLength(RangeEnds, RangeCount);
    RangeStarts[RangeCount - 1] := IntegerValue;
    RangeEnds[RangeCount - 1] := IntegerValue;
  end;
end;
{ @end $4D162C }

{ @routine $4D1710 TQuestCPDiapazone_LoadFromText }
procedure TQuestCPDiapazone.LoadFromText(Text: AnsiString);
var
  i, Count: Integer;
  Value, Minimum, Maximum: Int64;
  NumberText: AnsiString;
  Failed: Boolean;
begin
  Clear;
  Count := Length(Text);
    i := 1;
    NumberText := '';
    Minimum := 200000000;
    Maximum := -200000000;
    Failed := False;
    while i <= Count do
    begin
      if ((Text[i] >= '0') and (Text[i] <= '9')) or (Text[i] = '-') then
      begin
        NumberText := NumberText + Text[i];
        Inc(i);
      end
      else if (Text[i] = 'h') or (Text[i] = ';') or (Text[i] = ']') then
      begin
        Value := 0;
        try
          Value := StrToInt(NumberText);
        except
          on EMathError do Failed := True;
          on EConvertError do Failed := True;
        end;
        if not Failed then
        begin
          if Minimum > Value then Minimum := Value;
          if Maximum < Value then Maximum := Value;
        end;
        Failed := False;
        NumberText := '';
        if (Text[i] = ';') or (Text[i] = ']') then
        begin
          AddRange(Minimum, Maximum);
          Minimum := 200000000;
          Maximum := -200000000;
          NumberText := '';
        end;
        Inc(i);
      end
      else Inc(i);
    end;
end;
{ @end $4D1710 }

end.

unit aQuestCPVarClass;
// Unit bracket (inferred): CODE 0x004D6384..0x004D66A3; inclusive evidence, not full bounds.
{$X-}

interface

uses aQuestCPDiapClass, EC_Struct;

type
  TCPValueKind = (cpvkRange = 0, cpvkFloat = 1); // @size $01

  TQuestCPVariant = class(TObject) // @size $14
  public
    Range: TQuestCPDiapazone; // @offset $04  Owned for every ValueKind.
    FloatValue: Extended; // @offset $08
    ValueKind: TCPValueKind; // @offset $12

    constructor Create; // @addr $4D63E0
    destructor Destroy; override; // @addr $4D642C
    procedure Reset; // @addr $4D6464 @note "Resets to floating zero; retains the range object."
    procedure Assign(Source: TQuestCPVariant); // @addr $4D6484 @note "Deep-copies the range."
    function TryLoadFromText(Text: AnsiString): Boolean; // @addr $4D64B4 @note "Comma decimals use Single precision; uppercase E is ignored. Ranges require h, not '..'. Failure preserves the value; empty text becomes zero."
    function HasNumericChars(var Text: AnsiString; TextLength: Integer): Boolean; // @addr $4D65E0 @note "Permits digits, comma and uppercase E; not a syntax check."
    // Numeric conversions resample ranges; unknown tags return zero.
    function AsExtended: Extended; // @addr $4D6620
  end;

implementation

// @unit-initialization $4D669C
// @unit-finalization $4D666C

uses EC_Str;

{ @routine $4D63E0 TQuestCPVariant_Create }
constructor TQuestCPVariant.Create;
begin
  inherited Create;
  Range := TQuestCPDiapazone.Create;
  Reset;
end;
{ @end $4D63E0 }

{ @routine $4D642C TQuestCPVariant_Destroy }
destructor TQuestCPVariant.Destroy;
begin
  if Range <> nil then
  begin
    Range.Free;
    Range := nil;
  end;
  inherited Destroy;
end;
{ @end $4D642C }

{ @routine $4D6464 TQuestCPVariant_Reset }
procedure TQuestCPVariant.Reset;
begin
  FloatValue := 0;
  Range.Clear;
  ValueKind := cpvkFloat;
end;
{ @end $4D6464 }

{ @routine $4D6484 TQuestCPVariant_Assign }
procedure TQuestCPVariant.Assign(Source: TQuestCPVariant);
begin
  Range.Assign(Source.Range);
  FloatValue := Source.FloatValue;
  ValueKind := Source.ValueKind;
end;
{ @end $4D6484 }

{ @routine $4D64B4 TQuestCPVariant_TryLoadFromText }
function TQuestCPVariant.TryLoadFromText(Text: AnsiString): Boolean;
var
  i, Count: Integer;
begin
  TryLoadFromText := False;
  Count := Length(Text);
  if Count = 0 then Text := '0';
  if HasNumericChars(Text, Count) then
  begin
    ValueKind := cpvkFloat;
    Range.Clear;
    FloatValue := ParseDecimalToSingleW(Text);
    TryLoadFromText := True;
  end
  else if (Count > 1) and (Text[1] = '[') and (Text[Count] = ']') then
  begin
    for i := 1 to Count do
    begin
      case Text[i] of
        '[', ']', 'h', ';', '-': Continue;
        '0'..'9': Continue;
      end;
      TryLoadFromText := False;
      Exit;
    end;
    ValueKind := cpvkRange;
    with Range do LoadFromText(Text);
    FloatValue := 0;
    TryLoadFromText := True;
  end;
end;
{ @end $4D64B4 }

{ @routine $4D65E0 TQuestCPVariant_HasNumericChars }
function TQuestCPVariant.HasNumericChars(var Text: AnsiString; TextLength: Integer): Boolean;
var
  i: Integer;
begin
  HasNumericChars := True;
  for i := 1 to TextLength do
    if ((Text[i] < '0') or (Text[i] > '9')) and (Text[i] <> ',') and (Text[i] <> '.') and (Text[i] <> 'E') then
    begin HasNumericChars := False; Break end;
end;
{ @end $4D65E0 }

{ @routine $4D6620 TQuestCPVariant_AsExtended }
function TQuestCPVariant.AsExtended: Extended;
begin
  AsExtended := 0;
  if ValueKind = cpvkRange then AsExtended := Range.GetRandomValue;
  if ValueKind = cpvkFloat then AsExtended := FloatValue;
end;
{ @end $4D6620 }

end.

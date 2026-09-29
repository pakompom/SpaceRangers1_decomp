unit aQuestCalcParseClass;
// Unit bracket (inferred): CODE 0x004D221C..0x004D6383; inclusive evidence, not full bounds.

// Quest expression preprocessing.

interface

uses Classes, aQuestCPVarClass;

type
  TQuestParameterValues = array[1..48] of Integer;

  TQuestCalcParse = class(TObject) // @size $1C
  public
    SourceText: AnsiString; // @offset $04
    Expression: AnsiString; // @offset $08  Internal tokens; parameters not yet substituted.
    ResultValue: Integer; // @offset $0C
    ResetValue10: Integer; // @offset $10  Reset to zero; purpose remains unresolved.
    UsesDefaultParameter: Boolean; // @offset $14  Processed text was empty or exactly the fallback [pN].
    SourceWasChanged: Boolean; // @offset $15  Compared against the readable form, not internal tokens.
    UnbalancedParentheses: Boolean; // @offset $16
    InvalidNumericLiteral: Boolean; // @offset $17  EConvertError during preparation.
    InvalidParameterReference: Boolean; // @offset $18
    InvalidRangeLiteral: Boolean; // @offset $19
    EvaluationError: Boolean; // @offset $1A
    HasError: Boolean; // @offset $1B  Also set for empty parentheses.

    procedure Evaluate(var Parameters: TQuestParameterValues); // @addr $4D585C
    function EvaluateExpression(Text: AnsiString): TQuestCPVariant; // @addr $4D53F0
    constructor Create; // @addr $4D5D64
    destructor Destroy; override; // @addr $4D5DA0
    procedure Reset; // @addr $4D5DC8

    // External spellings -> internal tokens: div f, mod g, in #,
    // to $, or |, and &, <> e, >= c, <= b, .. h, and decimal dot -> comma.
    function NormalizeTokens(var Text: AnsiString): AnsiString; // @addr $4D2C7C @note "Text is read-only despite var. Uses ANSI lowercase and boundary-free substitutions; always wraps the result in parentheses."
    function FormatTokens(var Text: AnsiString): AnsiString; // @addr $4D3104 @note "Text is read-only despite var. Removes at most one enclosing parenthesis pair; leaves outer whitespace."
    // Lower ranks bind tighter; -1 means not an operator.
    // 1: / f g; 2: *; 3: -; 4: +; 5: $; 6: #;
    // 7: < > = b c e; 8: &; 9: |.
    function GetOperatorRank(Token: AnsiChar): Integer; // @addr $4D348C
    function CollapseOperatorRun(var Text: AnsiString): AnsiString; // @addr $4D35A4 @note "Requires a nonempty operator run. Minus parity controls the sign; ties choose the leftmost weakest operator."
    function NormalizeParameterReference(Text: AnsiString): AnsiString; // @addr $4D48A4 @note "Uses only the first three digits; zero/missing digits produce [err]. Does not check parameter-list bounds."
    function FindTopLevelOperator(var Text: AnsiString; TextLength: Integer): Integer; // @addr $4D5368 @note "One-based; zero when absent. Rightmost ties give left associativity. Delimiter balance is unchecked."
    function HasBalancedParenthesesInSlice(var Text: AnsiString; FirstIndex, LastIndex: Integer): Boolean; // @addr $4D5E08 @note "One-based inclusive bounds, unchecked. Empty slices pass; square brackets are ignored."
    function HasBalancedParentheses(var Text: AnsiString): Boolean; // @addr $4D5FC0 @note "Empty text passes."

    procedure Prepare(Text: AnsiString; DefaultParameterIndex: Integer); // @addr $4D5B54 @note "Resets state; stores Expression even on error. Empty input becomes (), not the default parameter."
    function NormalizeFragments(var Text: AnsiString): AnsiString; // @addr $4D36F8 @note "Square brackets do not nest. An unmatched opening bracket discards the rest."
    function NormalizeScalarFragment(Text: AnsiString): AnsiString; // @addr $4D3884 @note "Silently discards unsupported characters, including decimal dots; call NormalizeTokens first."
    function NormalizeBracketFragment(Text: AnsiString): AnsiString; // @addr $4D480C @note "Any lowercase p selects parameter parsing, even outside the [pN] form."
    function NormalizeRangeLiteral(Text: AnsiString): AnsiString; // @addr $4D49F4 @note "Requires internal h notation, not '..'. Empty or rejected input yields [err]; existing errors remain set."
    function InsertImplicitMultiplication(Text: AnsiString): AnsiString; // @addr $4D4CD8
    function ClampNumericLiterals(Text: AnsiString): AnsiString; // @addr $4D5FE0 @note "Nonzero limits: 0.0001..999999999. Comma literals retry with dots after EConvertError, then use locale-dependent FloatToStr; integers use StrToInt/IntToStr. Drops trailing numbers; conversion errors set flags and leave the caller's result storage unchanged."

    // Parameters: borrowed fixed array of 48 integers; [pN] is one-based.
    function SubstituteParameters(var Parameters: TQuestParameterValues): AnsiString; // @addr $4D5E54 @note "Unmatched references remain unchanged; negative values are parenthesized."

    // Native numeric operators use floating values; ranges keep inclusive Int64 bounds.
    procedure ApplyAdd(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2294
    procedure ApplySubtract(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D22D4
    procedure ApplyMultiply(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2314
    procedure ApplyLessThan(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2844
    procedure ApplyGreaterThan(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D28A4
    procedure ApplyLessOrEqual(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2904
    procedure ApplyGreaterOrEqual(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2964
    procedure ApplyEqual(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D29C4
    procedure ApplyNotEqual(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2A24
    procedure ApplyDivide(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2354
    procedure ApplyIntDivide(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2414
    procedure ApplyModulo(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D24E0
    procedure ApplyRange(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D262C
    procedure ApplyMembership(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D26E4
    procedure ApplyAnd(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2A84
    procedure ApplyOr(var Left, Right, OutValue: TQuestCPVariant); // @addr $4D2B80
  end;

function ReplaceQuestText(Text, Pattern, Replacement: AnsiString): AnsiString; // @addr $4D5A1C

implementation

// @unit-initialization $4D637C
// @unit-finalization $4D634C

uses aQuestCPDiapClass, SysUtils;

{ @routine $4D2294 TQuestCalcParse_ApplyAdd }
procedure TQuestCalcParse.ApplyAdd(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  OutValue.FloatValue := Left.AsExtended + Right.AsExtended;
end;
{ @end $4D2294 }

{ @routine $4D22D4 TQuestCalcParse_ApplySubtract }
procedure TQuestCalcParse.ApplySubtract(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  OutValue.FloatValue := Left.AsExtended - Right.AsExtended;
end;
{ @end $4D22D4 }

{ @routine $4D2314 TQuestCalcParse_ApplyMultiply }
procedure TQuestCalcParse.ApplyMultiply(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  OutValue.FloatValue := Left.AsExtended * Right.AsExtended;
end;
{ @end $4D2314 }

{ @routine $4D2354 TQuestCalcParse_ApplyDivide }
procedure TQuestCalcParse.ApplyDivide(var Left, Right, OutValue: TQuestCPVariant);
var A, B: Extended;
begin
  OutValue.Reset;
  A := Left.AsExtended;
  B := Right.AsExtended;
  if B = 0 then
  begin
    if A < 0 then OutValue.FloatValue := -2000000000
    else OutValue.FloatValue := 2000000000;
  end
  else
  begin
    try OutValue.FloatValue := A / B;
    except on EDivByZero do ; end;
  end;
end;
{ @end $4D2354 }

{ @routine $4D2414 TQuestCalcParse_ApplyIntDivide }
procedure TQuestCalcParse.ApplyIntDivide(var Left, Right, OutValue: TQuestCPVariant);
var A, B: Extended;
begin
  OutValue.Reset;
  A := Left.AsExtended;
  B := Right.AsExtended;
  if B = 0 then
  begin
    if A < 0 then OutValue.FloatValue := -2000000000
    else OutValue.FloatValue := 2000000000;
  end
  else
  begin
    try OutValue.FloatValue := Trunc(A / B);
    except on EDivByZero do ; end;
  end;
end;
{ @end $4D2414 }

{ @routine $4D24E0 TQuestCalcParse_ApplyModulo }
procedure TQuestCalcParse.ApplyModulo(var Left, Right, OutValue: TQuestCPVariant);
var A, B: Extended;
    Negative: Boolean;
begin
  OutValue.Reset;
  A := Left.AsExtended;
  Negative := False;
  B := Trunc(Right.AsExtended);
  if B = 0 then
  begin
    if A < 0 then OutValue.FloatValue := -2000000000
    else OutValue.FloatValue := 2000000000;
  end
  else
  begin
    try
      if B < 0 then B := B * -1;
      if A < 0 then begin A := A * -1; Negative := True end;
      OutValue.FloatValue := Trunc(A - Trunc(A / B) * B);
      if Negative then OutValue.FloatValue := OutValue.FloatValue * -1;
    except on EDivByZero do ; end;
  end;
end;
{ @end $4D24E0 }

{ @routine $4D262C TQuestCalcParse_ApplyRange }
procedure TQuestCalcParse.ApplyRange(var Left, Right, OutValue: TQuestCPVariant);
var Minimum, Maximum: Int64;
begin
  OutValue.Reset;
  Maximum := 0;
  Minimum := 0;
  if Left.ValueKind = cpvkFloat then Minimum := Round(Left.FloatValue);
  if Left.ValueKind = cpvkRange then Minimum := Left.Range.GetMinimum;
  if Right.ValueKind = cpvkFloat then Maximum := Round(Right.FloatValue);
  if Right.ValueKind = cpvkRange then Maximum := Right.Range.GetMaximum;
  OutValue.ValueKind := cpvkRange;
  OutValue.Range.AddRange(Minimum, Maximum);
end;
{ @end $4D262C }

{ @routine $4D26E4 TQuestCalcParse_ApplyMembership }
procedure TQuestCalcParse.ApplyMembership(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
  begin
    if Left.FloatValue = Right.FloatValue then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkFloat) then
  begin
    if Left.Range.Contains(Right.FloatValue) then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end
  else if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkRange) then
  begin
    if Right.Range.Contains(Left.FloatValue) then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end
  else if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    if Right.Range.Contains(Left.AsExtended) then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end;
end;
{ @end $4D26E4 }

{ @routine $4D2844 TQuestCalcParse_ApplyLessThan }
procedure TQuestCalcParse.ApplyLessThan(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended < Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D2844 }

{ @routine $4D28A4 TQuestCalcParse_ApplyGreaterThan }
procedure TQuestCalcParse.ApplyGreaterThan(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended > Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D28A4 }

{ @routine $4D2904 TQuestCalcParse_ApplyLessOrEqual }
procedure TQuestCalcParse.ApplyLessOrEqual(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended <= Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D2904 }

{ @routine $4D2964 TQuestCalcParse_ApplyGreaterOrEqual }
procedure TQuestCalcParse.ApplyGreaterOrEqual(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended >= Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D2964 }

{ @routine $4D29C4 TQuestCalcParse_ApplyEqual }
procedure TQuestCalcParse.ApplyEqual(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended = Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D29C4 }

{ @routine $4D2A24 TQuestCalcParse_ApplyNotEqual }
procedure TQuestCalcParse.ApplyNotEqual(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if Left.AsExtended <> Right.AsExtended then OutValue.FloatValue := 1
  else OutValue.FloatValue := 0;
end;
{ @end $4D2A24 }

{ @routine $4D2A84 TQuestCalcParse_ApplyAnd }
procedure TQuestCalcParse.ApplyAnd(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
  begin
    if (Left.FloatValue <> 0) and (Right.FloatValue <> 0) then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end;
  if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Left);
    OutValue.Range.Append(Right.Range);
  end;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Right);
    OutValue.Range.AddValue(Left.FloatValue);
  end;
  if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkFloat) then
  begin
    OutValue.Assign(Left);
    OutValue.Range.AddValue(Right.FloatValue);
  end;
end;
{ @end $4D2A84 }

{ @routine $4D2B80 TQuestCalcParse_ApplyOr }
procedure TQuestCalcParse.ApplyOr(var Left, Right, OutValue: TQuestCPVariant);
begin
  OutValue.Reset;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkFloat) then
  begin
    if (Left.FloatValue <> 0) or (Right.FloatValue <> 0) then OutValue.FloatValue := 1
    else OutValue.FloatValue := 0;
  end;
  if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Left);
    OutValue.Range.Append(Right.Range);
  end;
  if (Left.ValueKind = cpvkFloat) and (Right.ValueKind = cpvkRange) then
  begin
    OutValue.Assign(Right);
    OutValue.Range.AddValue(Left.FloatValue);
  end;
  if (Left.ValueKind = cpvkRange) and (Right.ValueKind = cpvkFloat) then
  begin
    OutValue.Assign(Left);
    OutValue.Range.AddValue(Right.FloatValue);
  end;
end;
{ @end $4D2B80 }

{ @routine $4D2C7C TQuestCalcParse_NormalizeTokens }
function TQuestCalcParse.NormalizeTokens(var Text: AnsiString): AnsiString;
var
  Previous, Current: AnsiString;
  Index: Integer;
begin
  Current := SysUtils.LowerCase(Text);
  repeat
    Previous := Current;
    Current := ReplaceQuestText(Current, 'div', 'f');
    Current := ReplaceQuestText(Current, 'mod', 'g');
    Current := ReplaceQuestText(Current, 'in', '#');
    Current := ReplaceQuestText(Current, 'to', '$');
    Current := ReplaceQuestText(Current, 'or', '|');
    Current := ReplaceQuestText(Current, 'and', '&');
    Current := ReplaceQuestText(Current, '<>', 'e');
    Current := ReplaceQuestText(Current, '>=', 'c');
    Current := ReplaceQuestText(Current, '<=', 'b');
    Current := ReplaceQuestText(Current, '..', 'h');
    Current := ReplaceQuestText(Current, '.', ',');
    Current := ReplaceQuestText(Current, ' ', '');
    Current := ReplaceQuestText(Current, 'd', '');
    Current := ReplaceQuestText(Current, 'm', '');
    Current := ReplaceQuestText(Current, 'o', '');
    Current := ReplaceQuestText(Current, 't', '');
    Current := ReplaceQuestText(Current, 'i', '');
    Current := ReplaceQuestText(Current, 'a', '');
    Current := ReplaceQuestText(Current, 'n', '');
    Current := ReplaceQuestText(Current, 'd', '');
  until Current = Previous;
  Result := '(' + Previous + ')';
end;
{ @end $4D2C7C }

{ @routine $4D3104 TQuestCalcParse_FormatTokens }
function TQuestCalcParse.FormatTokens(var Text: AnsiString): AnsiString;
var
  Previous, Current, Inner: AnsiString;
  Count, i: Integer;
begin
  Current := SysUtils.LowerCase(Text);
  repeat
    Previous := Current;
  Current := ReplaceQuestText(Current, '$', ' to ');
  Current := ReplaceQuestText(Current, '#', ' in ');
  Current := ReplaceQuestText(Current, '|', ' or ');
  Current := ReplaceQuestText(Current, '&', ' and ');
  Current := ReplaceQuestText(Current, 'e', '<>');
  Current := ReplaceQuestText(Current, 'c', '>=');
  Current := ReplaceQuestText(Current, 'b', '<=');
  Current := ReplaceQuestText(Current, 'f', ' div ');
  Current := ReplaceQuestText(Current, 'g', ' mod ');
  Current := ReplaceQuestText(Current, 'h', '..');
    Current := ReplaceQuestText(Current, '(0-', '(-');
  until Current = Previous;
  Count := Length(Current);
  Inner := '';
  if (Count >= 2) and (Current[1] = '(') and (Current[Count] = ')') then
  begin
    for i := 2 to Count - 1 do Inner := Inner + Current[i];
    if HasBalancedParenthesesInSlice(Current, 2, Count - 1) then Previous := Inner;
  end;
  Result := Previous;
end;
{ @end $4D3104 }

{ @routine $4D348C TQuestCalcParse_GetOperatorRank }
function TQuestCalcParse.GetOperatorRank(Token: AnsiChar): Integer;
var
  Rank: Integer;
begin
  Rank := -1;
  case Token of
    '/': Rank := 1;
    'f': Rank := 1;
    'g': Rank := 1;
    '*': Rank := 2;
    '-': Rank := 3;
    '+': Rank := 4;
    '$': Rank := 5;
    '#': Rank := 6;
    'c': Rank := 7;
    'b': Rank := 7;
    'e': Rank := 7;
    '>': Rank := 7;
    '<': Rank := 7;
    '=': Rank := 7;
    '&': Rank := 8;
    '|': Rank := 9;
  end;
  Result := Rank;
end;
{ @end $4D348C }

{ @routine $4D35A4 TQuestCalcParse_CollapseOperatorRun }
function TQuestCalcParse.CollapseOperatorRun(var Text: AnsiString): AnsiString;
var
  i, MinusCount, PlusCount, Count: Integer;
  Operators: AnsiString;
begin
  Count := Length(Text);
  MinusCount := 0;
  PlusCount := 0;
  for i := 1 to Count do
  begin
    if Text[i] = '-' then Inc(MinusCount);
    if Text[i] = '+' then Inc(PlusCount);
  end;
  Operators := ReplaceQuestText(Text, '-', '');
  Operators := ReplaceQuestText(Operators, '+', '');
  if MinusCount mod 2 = 1 then Operators := Operators + '-'
  else if (PlusCount > 0) or (MinusCount > 0) then Operators := Operators + '+';
  Count := Length(Operators);
  MinusCount := 0;
  PlusCount := 0;
  for i := Count downto 1 do
    if GetOperatorRank(Operators[i]) >= MinusCount then
    begin
      PlusCount := i;
      MinusCount := GetOperatorRank(Operators[i]);
    end;
  Result := Operators[PlusCount];
end;
{ @end $4D35A4 }

{ @routine $4D36F8 TQuestCalcParse_NormalizeFragments }
function TQuestCalcParse.NormalizeFragments(var Text: AnsiString): AnsiString;
var
  Index, Count: Integer;
  Fragment, Output: AnsiString;
  Outside: Boolean;
begin
  Output := '';
  Index := 1;
  Count := Length(Text);
  Fragment := '';
  Outside := True;
  while Index <= Count do
  begin
    if Outside then
    begin
      if Text[Index] = '[' then
      begin
        Output := Output + NormalizeScalarFragment(Fragment);
        Fragment := '[';
        Outside := False;
        Inc(Index);
        Continue;
      end
      else if Text[Index] <> '[' then
      begin
        Fragment := Fragment + Text[Index];
        Inc(Index);
        if Index > Count then Output := Output + NormalizeScalarFragment(Fragment);
        Continue;
      end;
    end;
    if not Outside then
    begin
      if (Index > Count) or (Text[Index] = ']') then
      begin
        Output := Output + NormalizeBracketFragment(Fragment + ']');
        Fragment := '';
        Outside := True;
      end
      else Fragment := Fragment + Text[Index];
      Inc(Index);
    end;
  end;
  Result := Output;
end;
{ @end $4D36F8 }

{ @routine $4D3884 TQuestCalcParse_NormalizeScalarFragment }
function TQuestCalcParse.NormalizeScalarFragment(Text: AnsiString): AnsiString;
var
  Previous, Working, Output: AnsiString;
  i, Count: Integer;
begin
  Previous := '';
  Count := Length(Text);
  for i := 1 to Count do
  begin
    case Text[i] of
      '+': ;
      '-': ;
      '*': ;
      '/': ;
      '#': ;
      '$': ;
      'c': ;
      'b': ;
      'e': ;
      'f': ;
      'g': ;
      '=': ;
      '>': ;
      '<': ;
      '&': ;
      '|': ;
      '0'..'9': ;
      ',': ;
      '(': ;
      ')': ;
    else Continue;
    end;
    Previous := Previous + Text[i];
  end;
  Text := Previous;
  repeat
    Previous := Text;
    Working := Text;
    repeat
      Text := Working;
      Working := ReplaceQuestText(Working, ')(', ')*(');
      Working := ReplaceQuestText(Working, '()', '');
      Working := ReplaceQuestText(Working, '.', ',');
      Working := ReplaceQuestText(Working, ',,', ',');
      Working := ReplaceQuestText(Working, '(,', '(0,');
      Working := ReplaceQuestText(Working, '),', ')*0,');
      Working := ReplaceQuestText(Working, ')0', ')*0');
      Working := ReplaceQuestText(Working, ')1', ')*1');
      Working := ReplaceQuestText(Working, ')2', ')*2');
      Working := ReplaceQuestText(Working, ')3', ')*3');
      Working := ReplaceQuestText(Working, ')4', ')*4');
      Working := ReplaceQuestText(Working, ')5', ')*5');
      Working := ReplaceQuestText(Working, ')6', ')*6');
      Working := ReplaceQuestText(Working, ')7', ')*7');
      Working := ReplaceQuestText(Working, ')8', ')*8');
      Working := ReplaceQuestText(Working, ')9', ')*9');
      Working := ReplaceQuestText(Working, ',(', ',*(');
      Working := ReplaceQuestText(Working, '0(', '0*(');
      Working := ReplaceQuestText(Working, '1(', '1*(');
      Working := ReplaceQuestText(Working, '2(', '2*(');
      Working := ReplaceQuestText(Working, '3(', '3*(');
      Working := ReplaceQuestText(Working, '4(', '4*(');
      Working := ReplaceQuestText(Working, '5(', '5*(');
      Working := ReplaceQuestText(Working, '6(', '6*(');
      Working := ReplaceQuestText(Working, '7(', '7*(');
      Working := ReplaceQuestText(Working, '8(', '8*(');
      Working := ReplaceQuestText(Working, '9(', '9*(');
    until Text = Working;
    Count := Length(Text);
    Working := '';
    Output := '';
    i := 1;
    while i <= Count do
    begin
      if (GetOperatorRank(Text[i]) > 0) and (i <= Count) then
      begin
        Working := '';
        while (GetOperatorRank(Text[i]) > 0) and (i <= Count) do
        begin
          Working := Working + Text[i];
          Inc(i);
        end;
        Output := Output + CollapseOperatorRun(Working);
      end;
      if GetOperatorRank(Text[i]) < 0 then
      begin
        Working := '';
        while (GetOperatorRank(Text[i]) < 0) and (i <= Count) do
        begin
          Working := Working + Text[i];
          Inc(i);
        end;
        Output := Output + Working;
      end;
    end;
    Text := Output;
    Working := Text;
    repeat
      Text := Working;
      Working := ReplaceQuestText(Working, '(+', '(');
      Working := ReplaceQuestText(Working, '(*', '(');
      Working := ReplaceQuestText(Working, '(/', '(');
      Working := ReplaceQuestText(Working, '(&', '(');
      Working := ReplaceQuestText(Working, '(|', '(');
      Working := ReplaceQuestText(Working, '(#', '(');
      Working := ReplaceQuestText(Working, '($', '(');
      Working := ReplaceQuestText(Working, '(c', '(');
      Working := ReplaceQuestText(Working, '(b', '(');
      Working := ReplaceQuestText(Working, '(e', '(');
      Working := ReplaceQuestText(Working, '(f', '(');
      Working := ReplaceQuestText(Working, '(g', '(');
      Working := ReplaceQuestText(Working, '(<', '(');
      Working := ReplaceQuestText(Working, '(>', '(');
      Working := ReplaceQuestText(Working, '(=', '(');
      Working := ReplaceQuestText(Working, '-)', ')');
      Working := ReplaceQuestText(Working, '+)', ')');
      Working := ReplaceQuestText(Working, '*)', ')');
      Working := ReplaceQuestText(Working, '/)', ')');
      Working := ReplaceQuestText(Working, '&)', ')');
      Working := ReplaceQuestText(Working, '|)', ')');
      Working := ReplaceQuestText(Working, '$)', ')');
      Working := ReplaceQuestText(Working, '#)', ')');
      Working := ReplaceQuestText(Working, 'c)', ')');
      Working := ReplaceQuestText(Working, 'b)', ')');
      Working := ReplaceQuestText(Working, 'e)', ')');
      Working := ReplaceQuestText(Working, 'f)', ')');
      Working := ReplaceQuestText(Working, 'g)', ')');
      Working := ReplaceQuestText(Working, '>)', ')');
      Working := ReplaceQuestText(Working, '<)', ')');
      Working := ReplaceQuestText(Working, '=)', ')');
      Working := ReplaceQuestText(Working, '()', '');
      Working := ReplaceQuestText(Working, ')(', ')*(');
    until Text = Working;
  until Previous = Text;
  Result := Text;
end;
{ @end $4D3884 }

{ @routine $4D480C TQuestCalcParse_NormalizeBracketFragment }
function TQuestCalcParse.NormalizeBracketFragment(Text: AnsiString): AnsiString;
begin
  if ReplaceQuestText(Text, 'p', '') <> Text then
    Result := NormalizeParameterReference(Text)
  else Result := NormalizeRangeLiteral(Text);
end;
{ @end $4D480C }

{ @routine $4D48A4 TQuestCalcParse_NormalizeParameterReference }
function TQuestCalcParse.NormalizeParameterReference(Text: AnsiString): AnsiString;
var
  Count, i: Integer;
  Digits: AnsiString;
begin
  Count := Length(Text);
  Digits := '';
  for i := 1 to Count do
  begin
    if Length(Digits) > 2 then Break;
    if (Text[i] >= '0') and (Text[i] <= '9') then Digits := Digits + Text[i];
  end;
  i := StrToInt('0' + Digits);
  if (i > 0) and (i < 49) then Result := '[p' + IntToStr(i) + ']'
  else
  begin
    Result := '[err]';
    InvalidParameterReference := True;
    HasError := True;
  end;
end;
{ @end $4D48A4 }

{ @routine $4D49F4 TQuestCalcParse_NormalizeRangeLiteral }
function TQuestCalcParse.NormalizeRangeLiteral(Text: AnsiString): AnsiString;
var
  i, Count: Integer;
  Clean: AnsiString;
  Range: TQuestCPDiapazone;
begin
  Clean := '';
  Count := Length(Text);
  for i := 1 to Count do
  begin
    case Text[i] of
      '[', ']': ;
      '0'..'9', '-', 'h', ';': Clean := Clean + Text[i];
    end;
  end;
  Text := ';' + Clean + ';';
  Clean := Text;
  repeat
    Text := Clean;
    Clean := ReplaceQuestText(Clean, '--', '');
    Clean := ReplaceQuestText(Clean, ';;', ';');
    Clean := ReplaceQuestText(Clean, 'h;', ';');
    Clean := ReplaceQuestText(Clean, ';h', ';');
    Clean := ReplaceQuestText(Clean, '-;', ';');
    Clean := ReplaceQuestText(Clean, '-h', 'h');
    Clean := ReplaceQuestText(Clean, 'hh', 'h');
  until Text = Clean;
  if (Clean <> ';') and (Length(Text) > 0) then
  begin
    Text[1] := '[';
    i := Length(Text);
    Text[i] := ']';
    Range := TQuestCPDiapazone.Create;
    Range.LoadFromText(Text);
    Text := Range.ToText;
    Range.Destroy;
    Result := Text;
  end
  else
  begin
    Result := '[err]';
    InvalidRangeLiteral := True;
    HasError := True;
  end;
end;
{ @end $4D49F4 }

{ @routine $4D4CD8 TQuestCalcParse_InsertImplicitMultiplication }
function TQuestCalcParse.InsertImplicitMultiplication(Text: AnsiString): AnsiString;
var
  Current: AnsiString;
begin
  Current := Text;
  repeat
    Text := Current;
    Current := ReplaceQuestText(Current, '-,', '-0,');
    Current := ReplaceQuestText(Current, ')[', ')*[');
    Current := ReplaceQuestText(Current, '](', ']*(');
    Current := ReplaceQuestText(Current, ')(', ')*(');
    Current := ReplaceQuestText(Current, '][', ']*[');
    Current := ReplaceQuestText(Current, '],', ']*0,');
    Current := ReplaceQuestText(Current, ']0', ']*0');
    Current := ReplaceQuestText(Current, ']1', ']*1');
    Current := ReplaceQuestText(Current, ']2', ']*2');
    Current := ReplaceQuestText(Current, ']3', ']*3');
    Current := ReplaceQuestText(Current, ']4', ']*4');
    Current := ReplaceQuestText(Current, ']5', ']*5');
    Current := ReplaceQuestText(Current, ']6', ']*6');
    Current := ReplaceQuestText(Current, ']7', ']*7');
    Current := ReplaceQuestText(Current, ']8', ']*8');
    Current := ReplaceQuestText(Current, ']9', ']*9');
    Current := ReplaceQuestText(Current, ',[', ',*[');
    Current := ReplaceQuestText(Current, '0[', '0*[');
    Current := ReplaceQuestText(Current, '1[', '1*[');
    Current := ReplaceQuestText(Current, '2[', '2*[');
    Current := ReplaceQuestText(Current, '3[', '3*[');
    Current := ReplaceQuestText(Current, '4[', '4*[');
    Current := ReplaceQuestText(Current, '5[', '5*[');
    Current := ReplaceQuestText(Current, '6[', '6*[');
    Current := ReplaceQuestText(Current, '7[', '7*[');
    Current := ReplaceQuestText(Current, '8[', '8*[');
    Current := ReplaceQuestText(Current, '9[', '9*[');
  until Text = Current;
  Result := Text;
end;
{ @end $4D4CD8 }

{ @routine $4D5368 TQuestCalcParse_FindTopLevelOperator }
function TQuestCalcParse.FindTopLevelOperator(var Text: AnsiString; TextLength: Integer): Integer;
var
  Rank, BestRank, BestIndex, i, BracketDepth, ParenthesisDepth: Integer;
begin
  BestRank := 0;
  BestIndex := 0;
  BracketDepth := 0;
  ParenthesisDepth := 0;
  for i := 1 to TextLength do
  begin
    if Text[i] = '(' then Inc(ParenthesisDepth);
    if Text[i] = '[' then Inc(BracketDepth);
    if Text[i] = ')' then Dec(ParenthesisDepth);
    if Text[i] = ']' then Dec(BracketDepth);
    if (ParenthesisDepth = 0) and (BracketDepth = 0) then
    begin
      Rank := GetOperatorRank(Text[i]);
      if BestRank <= Rank then
      begin
        BestRank := Rank;
        BestIndex := i;
      end;
    end;
  end;
  Result := BestIndex;
end;
{ @end $4D5368 }

{ @routine $4D53F0 TQuestCalcParse_EvaluateExpression }
function TQuestCalcParse.EvaluateExpression(Text: AnsiString): TQuestCPVariant;
var
  Count: Integer;
  Inner, LeftText, RightText: AnsiString;
  i, Index: Integer;
  Left, Right, Value: TQuestCPVariant;
begin
  Value := TQuestCPVariant.Create;
  Left := TQuestCPVariant.Create;
  Right := TQuestCPVariant.Create;
  if not EvaluationError then
  begin
    Count := Length(Text);
    if not Value.TryLoadFromText(Text) then
    begin
      if (Text[1] = '(') and (Text[Count] = ')') and HasBalancedParenthesesInSlice(Text, 2, Count - 1) then
      begin
        Inner := '';
        for i := 2 to Count - 1 do Inner := Inner + Text[i];
        Value.Assign(EvaluateExpression(Inner));
      end
      else
      begin
        Index := FindTopLevelOperator(Text, Count);
        if Index < 1 then EvaluationError := True
        else
        begin
          LeftText := '';
          for i := 1 to Index - 1 do LeftText := LeftText + Text[i];
          RightText := '';
          for i := Index + 1 to Count do RightText := RightText + Text[i];
          Right.Assign(EvaluateExpression(RightText));
          if not EvaluationError then
          begin
            Left.Assign(EvaluateExpression(LeftText));
            if not EvaluationError then
              try
                  if Text[Index] = '+' then ApplyAdd(Left, Right, Value)
                  else if Text[Index] = '-' then ApplySubtract(Left, Right, Value)
                  else if Text[Index] = '*' then ApplyMultiply(Left, Right, Value)
                  else if Text[Index] = '/' then ApplyDivide(Left, Right, Value)
                  else if Text[Index] = 'f' then ApplyIntDivide(Left, Right, Value)
                  else if Text[Index] = 'g' then ApplyModulo(Left, Right, Value)
                  else if Text[Index] = '$' then ApplyRange(Left, Right, Value)
                  else if Text[Index] = '#' then ApplyMembership(Left, Right, Value)
                  else if Text[Index] = '>' then ApplyGreaterThan(Left, Right, Value)
                  else if Text[Index] = '<' then ApplyLessThan(Left, Right, Value)
                  else if Text[Index] = 'c' then ApplyGreaterOrEqual(Left, Right, Value)
                  else if Text[Index] = 'b' then ApplyLessOrEqual(Left, Right, Value)
                  else if Text[Index] = 'e' then ApplyNotEqual(Left, Right, Value)
                  else if Text[Index] = '=' then ApplyEqual(Left, Right, Value)
                  else if Text[Index] = '&' then ApplyAnd(Left, Right, Value)
                  else if Text[Index] = '|' then ApplyOr(Left, Right, Value);
              except
                  on EMathError do
                  begin
                    EvaluationError := True;
                    HasError := True;
                  end;
                  on EInvalidOp do
                  begin
                    EvaluationError := True;
                    HasError := True;
                  end;
                  on EOverflow do
                  begin
                    EvaluationError := True;
                    HasError := True;
                  end;
                  on EZeroDivide do
                  begin
                    EvaluationError := True;
                    HasError := True;
                  end;
              end;
          end;
        end;
      end;
    end;
  end;
  Result := TQuestCPVariant.Create;
  Result.Assign(Value);
  Value.Destroy;
  Right.Destroy;
  Left.Destroy;
end;
{ @end $4D53F0 }

{ @routine $4D585C TQuestCalcParse_Evaluate }
procedure TQuestCalcParse.Evaluate(var Parameters: TQuestParameterValues);
var Value: TQuestCPVariant; Number: Extended;
begin
  Value := TQuestCPVariant.Create;
  // Native allocates Value even when HasError was already set and skips freeing it on that path.
  if not HasError then
  begin
    Value.Assign(EvaluateExpression('(' + SubstituteParameters(Parameters) + ')'));
    Number := Value.AsExtended;
    Value.Destroy;
    if Number < -2000000000 then Number := -2000000000;
    if Number > 2000000000 then Number := 2000000000;
    try
      ResultValue := Round(Number + 0.00000000001);
    except
      on EInvalidOp do
      begin
        EvaluationError := True;
        HasError := True;
        ResultValue := 0;
      end;
    end;
    if (ResultValue < 0) and (Number > 0) then
    begin
      EvaluationError := True;
      HasError := True;
      ResultValue := 0;
    end;
    if EvaluationError then HasError := True;
  end;
end;
{ @end $4D585C }

{ @routine $4D5A1C ReplaceQuestText }
function ReplaceQuestText(Text, Pattern, Replacement: AnsiString): AnsiString;
var TextLength, PatternLength, i, j: Integer;
begin
  Result := '';
  TextLength := Length(Text);
  PatternLength := Length(Pattern);
  if (TextLength < PatternLength) or (TextLength < 1) or (PatternLength < 1) then
  begin Result := Text; Exit end;
  i := 0;
  while i <= TextLength - PatternLength do
  begin
    j := 0;
    while j < PatternLength do
    begin
      if PAnsiChar(Pointer(Text))[i + j] <> PAnsiChar(Pointer(Pattern))[j] then Break;
      Inc(j);
    end;
    if j >= PatternLength then
    begin
      Result := Result + Replacement;
      Inc(i, PatternLength);
    end
    else
    begin
      Result := Result + PAnsiChar(Pointer(Text))[i];
      Inc(i);
    end;
  end;
  if i < TextLength then Result := Result + Copy(Text, i + 1, TextLength - i);
end;
{ @end $4D5A1C }

{ @routine $4D5B54 TQuestCalcParse_Prepare }
procedure TQuestCalcParse.Prepare(Text: AnsiString; DefaultParameterIndex: Integer);
var
  Count, i: Integer;
  Readable: AnsiString;
begin
  Reset;
  SourceText := Text;
  Text := NormalizeTokens(Text);
  Text := NormalizeFragments(Text);
  Text := InsertImplicitMultiplication(Text);
  Text := ClampNumericLiterals(Text);
  UnbalancedParentheses := not HasBalancedParentheses(Text);
  if UnbalancedParentheses then HasError := True;
  Readable := Text;
  if not HasError then
  begin
    Count := Length(Text);
    if (Count >= 2) and (Text[1] = '(') and (Text[Count] = ')') and
      HasBalancedParenthesesInSlice(Text, 2, Count - 1) then
    begin
      Readable := '';
      for i := 2 to Count - 1 do Readable := Readable + Text[i];
    end;
  end;
  if SourceText <> FormatTokens(Readable) then SourceWasChanged := True;
  if (Text = '') or (Text = '[p' + IntToStr(DefaultParameterIndex) + ']') then
  begin
    UsesDefaultParameter := True;
    Text := '[p' + IntToStr(DefaultParameterIndex) + ']';
  end;
  Expression := Text;
end;
{ @end $4D5B54 }

{ @routine $4D5D64 TQuestCalcParse_Create }
constructor TQuestCalcParse.Create;
begin
  inherited Create;
  Reset;
end;
{ @end $4D5D64 }

{ @routine $4D5DA0 TQuestCalcParse_Destroy }
destructor TQuestCalcParse.Destroy;
begin
  inherited Destroy;
end;
{ @end $4D5DA0 }

{ @routine $4D5DC8 TQuestCalcParse_Reset }
procedure TQuestCalcParse.Reset;
begin
  SourceText := '';
  Expression := '';
  ResultValue := 0;
  ResetValue10 := 0;
  SourceWasChanged := False;
  UnbalancedParentheses := False;
  InvalidNumericLiteral := False;
  InvalidParameterReference := False;
  InvalidRangeLiteral := False;
  EvaluationError := False;
  UsesDefaultParameter := False;
  HasError := False;
end;
{ @end $4D5DC8 }

{ @routine $4D5E08 TQuestCalcParse_HasBalancedParenthesesInSlice }
function TQuestCalcParse.HasBalancedParenthesesInSlice(var Text: AnsiString; FirstIndex, LastIndex: Integer): Boolean;
var
  Depth, i: Integer;
  Balanced: Boolean;
begin
  Depth := 0;
  Balanced := True;
  for i := FirstIndex to LastIndex do
  begin
    if Text[i] = '(' then Inc(Depth);
    if Text[i] = ')' then Dec(Depth);
    if Depth < 0 then
    begin
      Balanced := False;
      Break;
    end;
  end;
  if Depth <> 0 then Balanced := False;
  Result := Balanced;
end;
{ @end $4D5E08 }

{ @routine $4D5E54 TQuestCalcParse_SubstituteParameters }
function TQuestCalcParse.SubstituteParameters(var Parameters: TQuestParameterValues): AnsiString;
var
  i: Integer;
  Text: AnsiString;

begin
  Text := Expression;
  for i := 1 to 48 do
  begin
    if Parameters[i] < 0 then
      Text := ReplaceQuestText(Text, '[p' + IntToStr(i) + ']', '(0' + IntToStr(Parameters[i]) + ')')
    else Text := ReplaceQuestText(Text, '[p' + IntToStr(i) + ']', IntToStr(Parameters[i]));
  end;
  Result := Text;
end;
{ @end $4D5E54 }

{ @routine $4D5FC0 TQuestCalcParse_HasBalancedParentheses }
function TQuestCalcParse.HasBalancedParentheses(var Text: AnsiString): Boolean;
var
  Balanced: Boolean;
begin
  Balanced := HasBalancedParenthesesInSlice(Text, 1, Length(Text));
  Result := Balanced;
end;
{ @end $4D5FC0 }

{ @routine $4D5FE0 TQuestCalcParse_ClampNumericLiterals }
function TQuestCalcParse.ClampNumericLiterals(Text: AnsiString): AnsiString;
var
  Index, Count, IntegerValue: Integer;
  Value: Extended;
  Digits, Output: AnsiString;
begin
  Index := 1;
  Count := Length(Text);
  Digits := '';
  Output := '';
  Value := 0;
  IntegerValue := 0;
  while Index <= Count do
  begin
    if ((Text[Index] >= '0') and (Text[Index] <= '9')) or (Text[Index] = ',') then
      Digits := Digits + AnsiString(Text[Index])
    else if Digits <> '' then
    begin
      if ReplaceQuestText(Digits, ',', '') <> Digits then
      begin
        try
          Value := SysUtils.StrToFloat(Digits);
        except
          on EConvertError do
          begin
            try
              Digits := ReplaceQuestText(Digits, ',', '.');
              Value := SysUtils.StrToFloat(Digits);
            except
              on EConvertError do
              begin
                HasError := True;
                InvalidNumericLiteral := True;
                Exit;
              end;
            end;
          end;
        end;
        if Value > 999999999 then Value := 999999999;
        if (Value < 0.0001) and (Value <> 0) then Value := 0.0001;
        Output := Output + SysUtils.FloatToStr(Value) + AnsiString(Text[Index]);
        Digits := '';
      end
      else
      begin
        try
          IntegerValue := SysUtils.StrToInt(Digits);
        except
          on EConvertError do
          begin
            HasError := True;
            InvalidNumericLiteral := True;
            Exit;
          end;
        end;
        if IntegerValue > 999999999 then IntegerValue := 999999999;
        Output := Output + SysUtils.IntToStr(IntegerValue) + AnsiString(Text[Index]);
        Digits := '';
      end;
    end
    else Output := Output + AnsiString(Text[Index]);
    Inc(Index);
  end;
  Result := Output;
end;
{ @end $4D5FE0 }

end.

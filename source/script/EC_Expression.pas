unit EC_Expression;
// Unit bracket (inferred): CODE 0x00456574..0x00464DE3; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, SysUtils, Windows;

type
  ExceptionExpressionEC = class;
  TVarEC = class;
  TVarArrayEC = class;
  TCodeAnalyzerUnitEC = class;
  TCodeAnalyzerEC = class;
  TExpressionInstrEC = class;
  TExpressionVarEC = class;
  TExpressionEC = class;
  TCodeUnitEC = class;
  TCodeProcessEC = class;
  TCodeEC = class;
  TCompilerUnitEC = class;
  TCompilerEC = class;
  TScriptDebugState = class;

  ExceptionExpressionEC = class(Exception) // @size $0C
  end;

  TLibrarySignature = array of Dword;

  TVarKind = (vkEmpty = 0, vkInt = 1, vkDword = 2, vkFloat = 3,
    vkString = 4, vkExternFun = 5, vkLibraryFun = 6, vkFunction = 7,
    vkClass = 8, vkArray = 9, vkRef = 10); // @size $1

  // DLL signature words use a separate numbering from TVarKind.
  TLibraryValueKind = (lvVoid = 0, lvInt = 1, lvDword = 2,
    lvString = 3); // @size $4

  TCodeTokenKind = (ctNewline = 0, ctOpenParen = 1, ctCloseParen = 2,
    ctOpenBrace = 3, ctCloseBrace = 4, ctOpenBracket = 5, ctCloseBracket = 6,
    ctBlockCommentStart = 7, ctBlockCommentEnd = 8, ctLineComment = 9,
    ctDot = 10, ctArrow = 11, ctAdd = 12, ctSubtract = 13,
    ctMultiply = 14, ctDivide = 15, ctModulo = 16, ctBitAnd = 17,
    ctBitOr = 18, ctBitXor = 19, ctBitNot = 20, ctAnd = 21,
    ctOr = 22, ctNot = 23, ctShiftLeft = 24, ctShiftRight = 25,
    ctAssign = 26, ctEqual = 27, ctNotEqual = 28, ctLess = 29,
    ctGreater = 30, ctLessEqual = 31, ctGreaterEqual = 32,
    ctSemicolon = 33, ctColon = 34, ctComma = 35, ctWhitespace = 36,
    ctStringLiteral = 37, ctText = 38); // @size $1

  TCompilerUnitKind = (cuIntLiteral = 0, cuDwordLiteral = 1,
    cuFloatLiteral = 2, cuStringLiteral = 3, cuBinaryOperator = 4,
    cuUnaryOperator = 5, cuOpenParen = 6, cuCloseParen = 7,
    cuOpenBracket = 8, cuCloseBracket = 9, cuName = 10, cuCall = 11,
    cuIndex = 12, cuVariable = 13, cuComma = 14, cuAssignment = 15); // @size $1

  TExpressionOpcode = (eoNegate = 0, eoAdd = 1, eoSubtract = 2,
    eoMultiply = 3, eoDivide = 4, eoModulo = 5, eoBitAnd = 6,
    eoBitOr = 7, eoBitXor = 8, eoBitNot = 9, eoAnd = 10, eoOr = 11,
    eoNot = 12, eoShiftLeft = 13, eoShiftRight = 14, eoLess = 15,
    eoGreater = 16, eoEqual = 17, eoNotEqual = 18, eoLessEqual = 19,
    eoGreaterEqual = 20, eoAssign = 21, eoCall = 22, eoIndex = 23); // @size $1

  TExpressionVarKind = (evNamed = 0, evOwned = 1, evIndexed = 2); // @size $1

  TCodeOpcode = (coLabel = 0, coExpression = 1, coBranchFalse = 2,
    coJump = 3, coExit = 4, coPushHandler = 5, coPopHandler = 6,
    coThrow = 7); // @size $1

  PCodeAnalyzerUnitEC = ^TCodeAnalyzerUnitEC;

  TVarEC = class(TObject) // @size $3C
  public
    Name: WideString; // @offset $04
    Kind: TVarKind; // @offset $08
    IntValue: Integer; // @offset $0C
    DwordValue: Dword; // @offset $10
    FloatValue: Double; // @offset $18
    StringValue: WideString; // @offset $20
    ExternFunValue: Pointer; // @offset $24
    // Delphi dynamic array: TLibraryValueKind return kind, native address,
    // then TLibraryValueKind argument kinds. Address word is not an enum.
    LibraryFunData: array of Dword; // @offset $28
    FunctionValue: TCodeEC; // @offset $2C
    ClassValue: TCodeEC; // @offset $30
    ArrayValue: TVarArrayEC; // @offset $34
    RefValue: TVarEC; // @offset $38

    function GetInt: Integer; // @addr $4581F4
    function GetDword: Dword; // @addr $45829C @note "Reference cells delegate to GetInt, then reinterpret its bits."
    function GetFloat: Double; // @addr $458344
    function GetExternFun: Pointer; // @addr $4585A8
    function GetFunction: TCodeEC; // @addr $458648
    function GetClass: TCodeEC; // @addr $4586E8 @note "Reference cells delegate to GetFunction in the native code."
    function GetArray: TVarArrayEC; // @addr $458788
    function Resolve: TVarEC; // @addr $459054 @note "May return nil."
    function RealVType: TVarKind; // @addr $458054 @note "Raises for an unresolved reference."
    function IsTrue: Boolean; // @addr $45B9D4
    procedure ResetKind(NewKind: TVarKind); // @addr $457FC8
    procedure AssignFrom(Source: TVarEC); // @addr $458108
    procedure Assume(Source: TVarEC); // @addr $45B558 @note "Assigns through references, converting to the destination kind."
    procedure SetInt(Value: Integer); // @addr $458828
    procedure SetDword(Value: Dword); // @addr $45893C @note "Reference cells delegate to SetInt with the same bits."
    procedure SetExternFun(Value: Pointer); // @addr $458C74
    procedure SetFunction(Value: TCodeEC); // @addr $458D40 @note "Native leaves empty and function cells unchanged; other kinds clear their payload or delegate through a reference."
    procedure SetRef(Value: TVarEC); // @addr $458F94

    procedure OMinus(Value: TVarEC); // @addr $45B1C4
    procedure OBitNot(Value: TVarEC); // @addr $45B318
    procedure ONot(Value: TVarEC); // @addr $45B420
    procedure OAdd(Left, Right: TVarEC); // @addr $4594D4
    procedure OSub(Left, Right: TVarEC); // @addr $459670
    procedure OMul(Left, Right: TVarEC); // @addr $45980C
    procedure ODiv(Left, Right: TVarEC); // @addr $4599A8
    procedure OMod(Left, Right: TVarEC); // @addr $459B50
    procedure OBitAnd(Left, Right: TVarEC); // @addr $459CAC
    procedure OBitOr(Left, Right: TVarEC); // @addr $459E08
    procedure OBitXor(Left, Right: TVarEC); // @addr $459F64
    procedure OAnd(Left, Right: TVarEC); // @addr $45A0C0
    procedure OOr(Left, Right: TVarEC); // @addr $45A238
    procedure OShl(Left, Right: TVarEC); // @addr $45A3B0
    procedure OShr(Left, Right: TVarEC); // @addr $45A508
    procedure OEqual(Left, Right: TVarEC); // @addr $45A660
    procedure ONotEqual(Left, Right: TVarEC); // @addr $45A844
    procedure OLess(Left, Right: TVarEC); // @addr $45AA2C
    procedure OMore(Left, Right: TVarEC); // @addr $45AC10
    procedure OLessEqual(Left, Right: TVarEC); // @addr $45ADF4
    procedure OMoreEqual(Left, Right: TVarEC); // @addr $45AFDC

    constructor Create(InitialKind: TVarKind); // @addr $4575E0
    destructor Destroy; override; // @addr $457638

    function IsEmpty: Boolean; // @addr $4581EC @note "Tests this cell's tag without dereferencing."
    function GetString: WideString; // @addr $458460 @note "Library cells return their import specification string."
    procedure ConvertToKind(NewKind: TVarKind); // @addr $45767C @note "Preserves the value where conversion is supported; ResetKind discards it."
    procedure SetFloat(Value: Double); // @addr $458A5C
    procedure SetString(const Value: WideString); // @addr $458B90 @note "Assigns through references and converts to an existing destination kind; an empty cell becomes a string."
    procedure SetClass(Value: TCodeEC); // @addr $458DFC @note "Value is borrowed; vkRef assignment uses the function-value setter."
    procedure SetArray(Value: TVarArrayEC); // @addr $458EC8 @note "Value is borrowed; follows references."
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $45BB04 @note "Serializes scalar and string payloads; the array branch is empty."
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $45BB84
    function LessThan(Other: TVarEC): Boolean; // @addr $45B71C
    function GreaterThan(Other: TVarEC): Boolean; // @addr $45B878
    procedure PackAnsiString; // @addr $459064 @note "Stores ANSI bytes inside StringValue's UTF-16 allocation."
    procedure UnpackAnsiString; // @addr $459110 @note "Non-string cells are converted to string without unpacking."
    procedure CreateArray(Dimensions: array of Integer); // @addr $4593FC @note "Requires at least one dimension."
    procedure FreeArray; // @addr $4594A4 @note "Frees nested arrays; retains vkArray with a nil pointer."
    procedure ResizeArray(Count, Dimension: Integer); // @addr $459450 @note "Nonpositive Count frees the array; positive Count resizes only when Dimension <= 0."
  end;

  TVarArrayEC = class(TObject) // @size $10
  public
    Count: Integer; // @offset $04
    Data: PVarEC; // @offset $08
    NameOrder: ^Integer; // @offset $0C

    procedure Clear; // @addr $45BD00
    procedure CopyFrom(Source: TVarArrayEC); // @addr $45BD30
    function GetItem(Index: Integer): TVarEC; // @addr $45BEE0
    function GetItemNE(Index: Integer): TVarEC; // @addr $45BF04 @note "Returns nil for an out-of-range index."
    function GetVar(const Name: WideString): TVarEC; // @addr $45BF18
    function GetVarNE(const Name: WideString): TVarEC; // @addr $45BFC0 @note "Returns nil when absent."
    function Add(const Name: WideString; Kind: TVarKind): TVarEC; // @addr $45C214

    constructor Create; // @addr $45BC58
    destructor Destroy; override; // @addr $45BC90

    procedure ClearStorage; // @addr $45BCBC @note "Does not free cells; use Clear for owned entries."
    function FindNameInsertionIndex(const Name: WideString): Integer; // @addr $45BDF0
    procedure SetNameOrderIndex(Index, DataIndex: Integer); // @addr $45BE70 @note "Does not validate either index."
    function GetNameOrderIndex(Index: Integer): Integer; // @addr $45BE84
    function GetItemByNameOrder(Index: Integer): TVarEC; // @addr $45BE94
    function FindNameOrderForDataIndex(DataIndex: Integer): Integer; // @addr $45BEAC
    procedure SetItem(Index: Integer; Value: TVarEC); // @addr $45BEF0 @note "Does not validate Index, free the old cell, or update NameOrder."
    procedure AddItem(Value: TVarEC); // @addr $45C110 @note "Takes ownership of Value."
    procedure Delete(Index: Integer); // @addr $45C048 @note "Frees the cell; ignores invalid indexes."
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $45C280
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $45C2B8 @note "Clears existing cells before reading."
    procedure AppendFromBuffer(Buffer: TBufEC); // @addr $45C300
  end;

  TCodeAnalyzerUnitEC = class(TObject) // @size $1C
  public
    Prev: TCodeAnalyzerUnitEC; // @offset $04
    Next: TCodeAnalyzerUnitEC; // @offset $08
    TokenKind: TCodeTokenKind; // @offset $0C
    SourceStart: Integer; // @offset $10
    SourceLength: Integer; // @offset $14
    Text: WideString; // @offset $18
  end;

  TCodeAnalyzerEC = class(TObject) // @size $14
  public
    FirstFree: TCodeAnalyzerUnitEC; // @offset $04
    LastFree: TCodeAnalyzerUnitEC; // @offset $08
    First: TCodeAnalyzerUnitEC; // @offset $0C
    Last: TCodeAnalyzerUnitEC; // @offset $10
    constructor Create; // @addr $45C344
    destructor Destroy; override; // @addr $45C37C
    procedure Clear; // @addr $45C3A8 @note "Also frees pooled nodes."
    procedure ReserveTokens(Count: Integer); // @addr $45C3F0
    function AcquireToken: TCodeAnalyzerUnitEC; // @addr $45C430
    procedure RecycleToken(Token: TCodeAnalyzerUnitEC); // @addr $45C47C
    procedure ClearTokens; // @addr $45C4A0 @note "Retains token storage for reuse."
    function AddToken: TCodeAnalyzerUnitEC; // @addr $45C4B8
    procedure DeleteToken(Token: TCodeAnalyzerUnitEC); // @addr $45C4E8
    procedure AppendText(Text: WideString; SourceOffset, NewlineOffset: Integer); // @addr $45C520 @note "NewlineOffset is added to the source-position base at each newline."
    procedure Tokenize(Text: WideString; NewlineOffset: Integer = 0); // @addr $45DA38 @note "Replaces existing tokens; source offsets start at zero."
    function ValidateDelimiters: WideString; // @addr $45DABC @note "Returns an empty string on success."
    procedure RemoveWhitespace; // @addr $45DD54
    procedure RemoveNewlines; // @addr $45DD7C
    procedure RemoveComments; // @addr $45DDA4 @note "Supports nested block comments."
  end;

  TScriptIncludeResolver = function(SourceContext: Pointer; const Name: WideString;
    InsertSource: Boolean; var IncludedContext: Pointer; Analyzer: TCodeAnalyzerEC): Integer;
  TExpressionCallback = procedure(av: array of TVarEC; Code: TCodeEC);
  PVarEC = ^TVarEC;

  TExpressionInstrEC = class(TObject) // @size $10
  public
    Opcode: TExpressionOpcode; // @offset $04
    OperandCount: Integer; // @offset $08
    // Indices into TExpressionEC.Variables: destination first, then sources.
    // eoCall uses destination, callee, arguments; eoIndex uses destination, array, indices.
    Operands: array of Integer; // @offset $0C

    procedure CopyFrom(Source: TExpressionInstrEC); // @addr $45DF7C

    destructor Destroy; override; // @addr $45DE24
  end;

  TExpressionVarEC = class(TObject) // @size $14
  public
    Kind: TExpressionVarKind; // @offset $04
    Name: WideString; // @offset $08
    MemberPath: array of WideString; // @offset $0C
    Value: TVarEC; // @offset $10

    procedure CopyFrom(Source: TExpressionVarEC); // @addr $45E024
    function Resolve(InitialKind: TVarKind): TVarEC; // @addr $45E240 @note "Only evOwned slots allocate values."

    destructor Destroy; override; // @addr $45DFDC

    function SplitMemberPath: Boolean; // @addr $45E0C8 @note "Replaces Name with its root component. Always returns true."
    function GetFullName: WideString; // @addr $45E1EC
  end;

  TExpressionEC = class(TObject) // @size $1C
  public
    VariableCount: Integer; // @offset $04
    Variables: ^TExpressionVarEC; // @offset $08
    InstructionCount: Integer; // @offset $0C
    Instructions: ^TExpressionInstrEC; // @offset $10
    SharedInstructions: Boolean; // @offset $14
    ResultIndex: Integer; // @offset $18

    procedure Clear; // @addr $45E48C
    procedure CopyFrom(Source: TExpressionEC); // @addr $45E4C8
    procedure CopyFromFast(Source: TExpressionEC); // @addr $45E544 @note "Borrows Source's instruction array."
    function GetVariable(Index: Integer): TExpressionVarEC; cdecl; // @addr $45E670 @ida "TExpressionVarEC *__cdecl $name(TExpressionEC *Self, int Index);"
    function GetInstruction(Index: Integer): TExpressionInstrEC; cdecl; // @addr $45E774 @ida "TExpressionInstrEC *__cdecl $name(TExpressionEC *Self, int Index);"
    procedure Link(Scope: TVarArrayEC); // @addr $45F70C
    procedure Evaluate(Process: TCodeProcessEC; Code: TCodeEC; DebugContext: TScriptDebugState); // @addr $45F778
    function GetResult: TVarEC; // @addr $460504

    constructor Create; // @addr $45E428
    destructor Destroy; override; // @addr $45E460

    function AddVariable: Integer; // @addr $45E5A0 @note "Returns a zero-based index; the new slot starts with zero-initialized evNamed kind."
    procedure DeleteVariable(Index: Integer); // @addr $45E604
    procedure SetVariable(Index: Integer; Value: TExpressionVarEC); cdecl; // @addr $45E688 @ida "void __cdecl $name(TExpressionEC *Self, int Index, TExpressionVarEC *Value);"
    function AddInstruction: Integer; // @addr $45E6A4
    procedure DeleteInstruction(Index: Integer); // @addr $45E708
    procedure SetInstruction(Index: Integer; Value: TExpressionInstrEC); cdecl; // @addr $45E78C @ida "void __cdecl $name(TExpressionEC *Self, int Index, TExpressionInstrEC *Value);"
    function Compile(Analyzer: TCodeAnalyzerEC; CompilationContext: Pointer; FirstToken, EndToken: TCodeAnalyzerUnitEC; NextToken: PCodeAnalyzerUnitEC): WideString; // @addr $45E7A8 @note "EndToken is exclusive; nil FirstToken starts at Analyzer.First. NextToken may be nil. Clears the previous expression before compiling."
  end;

  TCodeUnitEC = class(TObject) // @size $2C
  public
    Prev: TCodeUnitEC; // @offset $04
    Next: TCodeUnitEC; // @offset $08
    Opcode: TCodeOpcode; // @offset $0C
    Expression: TExpressionEC; // @offset $10
    Target: TCodeUnitEC; // @offset $14
    ExceptionVar: TVarEC; // @offset $18
    SourceStart: Integer; // @offset $1C
    SourceLength: Integer; // @offset $20
    SourceContext: Pointer; // @offset $24  Compiler-supplied source/debug identity.
    Breakpoint: Boolean; // @offset $28

    destructor Destroy; override; // @addr $4608CC
  end;

  TCodeProcessEC = class(TObject) // @size $0C
  public
    Handlers: TList; // @offset $04
    Exceptions: TList; // @offset $08

    procedure Clear; // @addr $4609A0
    procedure PushHandler(Code: TCodeEC; Handler: TCodeUnitEC); // @addr $460A24
    procedure PopHandler; // @addr $460A50
    function GetHandler: PCodeExceptionHandler; // @addr $460A8C
    procedure PushException(Value: TVarEC); // @addr $460AA4
    procedure PopException; // @addr $460AF0 @note "Does not free the exception value; the caller assumes ownership."
    function GetException: PVarEC; // @addr $460B2C

    constructor Create; // @addr $460904
    destructor Destroy; override; // @addr $460958
  end;

  TCodeEC = class(TObject) // @size $24
  public
    Parent: TCodeEC; // @offset $04
    IsClassDefinition: Boolean; // @offset $08
    Name: WideString; // @offset $0C
    First: TCodeUnitEC; // @offset $10
    Last: TCodeUnitEC; // @offset $14
    LocalVar: TVarArrayEC; // @offset $18
    Process: TCodeProcessEC; // @offset $1C
    DebugContext: TScriptDebugState; // @offset $20

    procedure Clear; // @addr $460BBC
    procedure CopyFrom(Source: TCodeEC); // @addr $460BDC
    procedure CopyFromFast(Source: TCodeEC); // @addr $460CA8 @note "Expression instructions remain shared with Source."
    function FindVar(Name: WideString): TVarEC; // @addr $460D88
    procedure DeleteCodeUnit(CodeUnit: TCodeUnitEC); // @addr $460E28
    function AddCodeUnit: TCodeUnitEC; // @addr $460E64
    procedure LinkAll(Scope: TVarArrayEC); // @addr $4631B0
    procedure Run(Process: TCodeProcessEC); // @addr $46328C
    procedure RunDebug(Process: TCodeProcessEC; DebugContext: TScriptDebugState); // @addr $4633EC

    constructor Create; // @addr $460B44
    destructor Destroy; override; // @addr $460B88

    function InsertCodeUnitBefore(BeforeUnit: TCodeUnitEC): TCodeUnitEC; // @addr $460E98 @note "Inserts before BeforeUnit; nil appends."
    function Compile(Analyzer: TCodeAnalyzerEC; SourceContext: Pointer; IncludeResolver: TScriptIncludeResolver; FirstToken: TCodeAnalyzerUnitEC; NextToken: PCodeAnalyzerUnitEC; CompilationContext: Pointer): WideString; // @addr $460EDC @note "NextToken may be nil."
    function CompileBlock(Analyzer: TCodeAnalyzerEC; SourceContext: Pointer; IncludeResolver: TScriptIncludeResolver; Token: TCodeAnalyzerUnitEC; BeforeUnit: TCodeUnitEC; NextToken, StatementEnd: PCodeAnalyzerUnitEC; BreakTarget, ContinueTarget: TCodeUnitEC; CompilationContext: Pointer): WideString; // @addr $461388
    procedure LinkLocalScopes; // @addr $463240
  end;

  TCodeExceptionHandler = packed record // @size $08
    Code: TCodeEC; // @offset $00
    Handler: TCodeUnitEC; // @offset $04
  end;
  PCodeExceptionHandler = ^TCodeExceptionHandler;

  TCompilerUnitEC = class(TObject) // @size $30
  public
    Prev: TCompilerUnitEC; // @offset $04
    Next: TCompilerUnitEC; // @offset $08
    Kind: TCompilerUnitKind; // @offset $0C
    OperatorToken: TCodeTokenKind; // @offset $0D
    Text: WideString; // @offset $10
    VariableIndex: Integer; // @offset $14
    IntValue: Integer; // @offset $18
    DwordValue: Dword; // @offset $1C
    FloatValue: Double; // @offset $20
    SourceStart: Integer; // @offset $28
    SourceLength: Integer; // @offset $2C
  end;

  TCompilerEC = class(TObject) // @size $0C
  public
    First: TCompilerUnitEC; // @offset $04
    Last: TCompilerUnitEC; // @offset $08
    constructor Create; // @addr $460564
    destructor Destroy; override; // @addr $46059C
    procedure Clear; // @addr $4605C8
    function AddUnit: TCompilerUnitEC; // @addr $4605E0
    procedure DeleteUnit(UnitNode: TCompilerUnitEC); // @addr $460614
    function FindReducibleOperator: TCompilerUnitEC; // @addr $460650 @note "Returns nil when no operator qualifies."
    function FindReducibleIndex: TCompilerUnitEC; // @addr $460854
    function FindReducibleCall: TCompilerUnitEC; // @addr $460890
  end;

  TScriptDebugState = class(TObject) // @partial
  public
    Paused: Boolean; // @offset $04
    StopEvent: Dword; // @offset $08
    ResumeEvent: Dword; // @offset $0C
    StepMode: Byte; // @offset $10
    CurrentUnit: TCodeUnitEC; // @offset $14
    CurrentCode: TCodeEC; // @offset $18
  end;

procedure FreeScriptArrayTree(Values: TVarArrayEC); // @addr $459184 @note "Requires an acyclic ownership tree."
procedure GrowScriptArray(Values: TVarArrayEC; Dimensions: array of Integer; DimensionIndex: Integer); // @addr $4591D0 @note "Does not shrink or resize existing children."
procedure ResizeScriptArray(Values: TVarArrayEC; Count: Integer); // @addr $45930C @note "Shrinks the outer dimension; the native growth branch retains the existing dimensions."
procedure RegisterExpressionBuiltins(Scope: TVarArrayEC); // @addr $4647D8

function CompareScriptNames(Left, Right: PWideChar): Integer; cdecl; // @addr $456B44 @note "Case-sensitive ordinal comparison; accepts nil and returns -1, 0 or 1."
function TrimScriptString(Text: WideString): WideString; // @addr $456B9C
function ScriptStringToInt(Text: WideString): Integer; // @addr $456C80 @note "Collects decimal digits while ignoring other characters; negative only for a leading minus."
function ScriptFloatToString(Value: Double): WideString; // @addr $456D50 @note "Uses a dot decimal separator."
function ScriptDwordToHex(Value: Dword): WideString; // @addr $456DC0
function ScriptStringToFloat(Text: WideString): Double; // @addr $456E58 @note "Ignores nonnumeric characters; not a strict literal validator."
function IsScriptIntegerText(Text: WideString): Boolean; // @addr $456F7C @note "Also accepts empty text and a lone minus."
function IsNonIntegerScriptText(Text: WideString): Boolean; // @addr $456FFC
function TryReadFloatLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Double): Boolean; // @addr $4570D8 @note "Requires a decimal point and fractional digits; supports an exponent suffix. Token advances only on success; Value may change on failure."
function TryReadIntegerLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Integer): Boolean; // @addr $4573A4
function TryReadStringLiteral(var Token: TCodeAnalyzerUnitEC; var Value: WideString): Boolean; // @addr $457404
function TryReadDwordLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Dword): Boolean; // @addr $457430 @note "Reads h/H hexadecimal and b/B binary suffixes. Token advances only on success; Value may change on failure."
function TryReadMemberName(var Token: TCodeAnalyzerUnitEC; var Name: WideString): Boolean; // @addr $45754C @note "Requires a nonnil initial Token."

// Native expression callbacks: av[0] is the script result; code is the caller.
procedure EF_Min(av: array of TVarEC; code: TCodeEC); // @addr $463620
procedure EF_Max(av: array of TVarEC; code: TCodeEC); // @addr $463690
procedure EF_NewArray(av: array of TVarEC; code: TCodeEC); // @addr $463728
procedure EF_ArrayChange(av: array of TVarEC; code: TCodeEC); // @addr $463824
procedure EF_Free(av: array of TVarEC; code: TCodeEC); // @addr $463870
procedure EF_Count(av: array of TVarEC; code: TCodeEC); // @addr $4638BC
procedure EF_Copy(av: array of TVarEC; code: TCodeEC); // @addr $463958
procedure EF_Abs(av: array of TVarEC; code: TCodeEC); // @addr $4639A4
procedure EF_ArcTan(av: array of TVarEC; code: TCodeEC); // @addr $463A08
procedure EF_Exp(av: array of TVarEC; code: TCodeEC); // @addr $463A4C
procedure EF_Ln(av: array of TVarEC; code: TCodeEC); // @addr $463A90
procedure EF_Round(av: array of TVarEC; code: TCodeEC); // @addr $463AD4
procedure EF_Sin(av: array of TVarEC; code: TCodeEC); // @addr $463B34
procedure EF_Cos(av: array of TVarEC; code: TCodeEC); // @addr $463B78
procedure EF_Sqr(av: array of TVarEC; code: TCodeEC); // @addr $463BBC
procedure EF_Sqrt(av: array of TVarEC; code: TCodeEC); // @addr $463C2C
procedure EF_Frac(av: array of TVarEC; code: TCodeEC); // @addr $463C6C
procedure EF_Int(av: array of TVarEC; code: TCodeEC); // @addr $463CB0
procedure EF_Ord(av: array of TVarEC; code: TCodeEC); // @addr $463CF0
procedure EF_Rnd(av: array of TVarEC; code: TCodeEC); // @addr $463D68
procedure EF_Randomize(av: array of TVarEC; code: TCodeEC); // @addr $463DA8
procedure EF_RandSeed(av: array of TVarEC; code: TCodeEC); // @addr $463DCC
procedure EF_SubStr(av: array of TVarEC; code: TCodeEC); // @addr $463E18
procedure EF_FindSubStr(av: array of TVarEC; code: TCodeEC); // @addr $463EFC
procedure EF_Trim(av: array of TVarEC; code: TCodeEC); // @addr $464018
procedure EF_ToAnsi(av: array of TVarEC; code: TCodeEC); // @addr $464094
procedure EF_ToUnicode(av: array of TVarEC; code: TCodeEC); // @addr $464108
procedure EF_LowerCase(av: array of TVarEC; code: TCodeEC); // @addr $46417C
procedure EF_UpperCase(av: array of TVarEC; code: TCodeEC); // @addr $4642A8
procedure EF_LoadLibrary(av: array of TVarEC; code: TCodeEC); // @addr $4643D4
procedure EF_FreeLibrary(av: array of TVarEC; code: TCodeEC); // @addr $464460
procedure EF_LibraryFunction(av: array of TVarEC; code: TCodeEC); // @addr $46449C @note "av[1..3] are the module handle, return-kind name and export name; later arguments name parameter kinds."
procedure EF_New(av: array of TVarEC; code: TCodeEC); // @addr $4646CC @note "Looks up class definitions in the root scope; the instance shares their expression instructions."
procedure EF_Delete(av: array of TVarEC; code: TCodeEC); // @addr $464790 @note "Also resets av[1]."

procedure InitInstr(Instruction: TExpressionInstrEC; Token: TCodeTokenKind); // @addr $45DE58 @note "Sets Opcode only. Accepts arithmetic, logical and comparison tokens; other tokens raise."

function FormatScriptError(Code, Position: Integer): WideString; // @addr $45704C @note "Encodes error code and source position as a comma-separated decimal pair."

const
  ScriptHexDigits: array[0..15] of WideChar = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'); // @addr $617EF8

implementation

// @unit-initialization $464DDC
// @unit-finalization $464DAC

uses Math;

{ @routine $456B44 CompareScriptNames }
// Native assembly comparison; characters compare unsigned.
function CompareScriptNames(Left, Right: PWideChar): Integer; cdecl;
asm
  PUSH ESI
  PUSH EDI
  PUSH EBX
  PUSH EDX
  MOV ESI, Left
  MOV EDI, Right
  TEST ESI, ESI
  JNZ @@LeftPresent
  MOV EAX, -1
  TEST EDI, EDI
  JNZ @@Done
  XOR EAX, EAX
  JMP @@Done
@@LeftPresent:
  TEST EDI, EDI
  JNZ @@Compare
  MOV EAX, 1
  JMP @@Done
@@Compare:
  MOV BX, [ESI]
  MOV DX, [EDI]
  ADD ESI, 2
  ADD EDI, 2
  CMP BX, DX
  JNZ @@Different
  XOR EAX, EAX
  TEST DX, DX
  JNZ @@Compare
  JMP @@Done
@@Different:
  MOV EAX, 1
  JA @@Done
  MOV EAX, -1
@@Done:
  POP EDX
  POP EBX
  POP EDI
  POP ESI
end;
{ @end $456B44 }

{ @routine $456B9C TrimScriptString }
function TrimScriptString(Text: WideString): WideString;
var
  C, Count, First, Last: Integer;
begin
  Count := Length(Text);
  First := 0;
  while First < Count do
  begin
    C := Ord(Text[First + 1]);
    if (C = Ord(' ')) or (C = 9) or (C = 13) or (C = 10) or (C = 0) then Inc(First)
    else Break;
  end;
  if First >= Count then
  begin
    Result := '';
    Exit;
  end;
  Last := Count - 1;
  while Last >= 0 do
  begin
    C := Ord(Text[Last + 1]);
    if (C = Ord(' ')) or (C = 9) or (C = 13) or (C = 10) or (C = 0) then Dec(Last)
    else Break;
  end;
  if Last < First then
  begin
    Result := '';
    Exit;
  end;
  SetLength(Result, Last - First + 1);
  Result := Copy(Text, First + 1, Last - First + 1);
end;
{ @end $456B9C }

{ @routine $456C80 ScriptStringToInt }
function ScriptStringToInt(Text: WideString): Integer;
var
  Count, i, Sign: Integer;
begin
  Result := 0;
  Count := Length(Text);
  Sign := 1;
  for i := 1 to Count do
    if (Integer(Text[i]) >= Ord('0')) and (Integer(Text[i]) <= Ord('9')) then Result := StrToInt(Text[i]) + Result * 10
    else if (Text[i] = '-') and (i = 1) then Sign := Sign * -1;
  Result := Sign * Result;
end;
{ @end $456C80 }

{ @routine $456D50 ScriptFloatToString }
function ScriptFloatToString(Value: Double): WideString;
var
  SavedSeparator: AnsiChar;
begin
  SavedSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  Result := FloatToStr(Value);
  DecimalSeparator := SavedSeparator;
end;
{ @end $456D50 }

{ @routine $456DC0 ScriptDwordToHex }
function ScriptDwordToHex(Value: Dword): WideString;
begin
  Result := '';
  while Value <> 0 do
  begin
    Result := ScriptHexDigits[Value - (Value div 16) shl 4] + Result;
    Value := Value div 16;
  end;
  if Result = '' then Result := '0';
end;
{ @end $456DC0 }

{ @routine $456E58 ScriptStringToFloat }
function ScriptStringToFloat(Text: WideString): Double;
var
  i, Count: Integer;
  Value, Divisor: Double;
  C: Integer;
begin
  Count := Length(Text);
  if Count < 1 then
  begin
    Result := 0;
    Exit;
  end;
  Value := 0;
  for i := 0 to Count - 1 do
  begin
    C := Ord(Text[i + 1]);
    if (C >= Ord('0')) and (C <= Ord('9')) then Value := Value * 10 + (C - Ord('0'))
    else if C = Ord('.') then Break;
  end;
  Inc(i);
  Divisor := 10;
  while i < Count do
  begin
    C := Ord(Text[i + 1]);
    if (C >= Ord('0')) and (C <= Ord('9')) then
    begin
      Value := (C - Ord('0')) / Divisor + Value;
      Divisor := Divisor * 10;
    end;
    Inc(i);
  end;
  for i := 0 to Count - 1 do
    if Integer(Text[i + 1]) = Ord('-') then
    begin
      Value := -Value;
      Break;
    end;
  Result := Value;
end;
{ @end $456E58 }

{ @routine $456F7C IsScriptIntegerText }
function IsScriptIntegerText(Text: WideString): Boolean;
var
  i, Count: Integer;
begin
  Count := Length(Text);
  for i := 0 to Count - 1 do
    if ((Text[i + 1] < '0') or (Text[i + 1] > '9')) and
      ((Text[i + 1] <> '-') or (i > 0)) then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;
{ @end $456F7C }

{ @routine $456FFC IsNonIntegerScriptText }
function IsNonIntegerScriptText(Text: WideString): Boolean;
begin
  Result := not IsScriptIntegerText(Text);
end;
{ @end $456FFC }

{ @routine $45704C FormatScriptError }
function FormatScriptError(Code, Position: Integer): WideString;
begin
  Result := IntToStr(Code) + ',' + IntToStr(Position);
end;
{ @end $45704C }

{ @routine $4570D8 TryReadFloatLiteral }
function TryReadFloatLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Double): Boolean;
var
  Sign, Fraction, Exponent: Double;
  Current: TCodeAnalyzerUnitEC;
  C: WideChar;
  i, Count: Integer;
  ExponentText: WideString;
begin
  Current := Token;
  Result := False;
  Sign := 1;
  if Current = nil then Exit;
  if Current.TokenKind = ctSubtract then
  begin
    Sign := -1;
    Current := Current.Next;
    if Current = nil then Exit;
  end;
  if Current.TokenKind <> ctText then Exit;
  if not IsScriptIntegerText(Current.Text) then Exit;
  Value := ScriptStringToInt(Current.Text);
  Current := Current.Next;
  if Current = nil then Exit;
  if Current.TokenKind <> ctDot then Exit;
  Current := Current.Next;
  if Current = nil then Exit;
  if Current.TokenKind <> ctText then Exit;
  Count := Length(Current.Text);
  Fraction := 0;
  i := 0;
  while i < Count do
  begin
    C := Current.Text[i + 1];
    if (C >= '0') and (C <= '9') then Fraction := Fraction * 10 + (Ord(C) - Ord('0'))
    else if (C = 'e') or (C = 'E') then Break
    else Exit;
    Inc(i);
  end;
  if i < 1 then Exit;
  Value := Fraction / Power(10, i) + Value;
  Exponent := 0;
  if Count - 1 > i then
  begin
    ExponentText := Copy(Current.Text, i + 2, Count - i - 1);
    if not IsScriptIntegerText(ExponentText) then Exit;
    Exponent := ScriptStringToInt(ExponentText);
    Current := Current.Next;
  end
  else if i = Count - 1 then
  begin
    Current := Current.Next;
    if Current = nil then Exit;
    if Pointer(Current.Next) = nil then Exit;
    if Current.Next.TokenKind <> ctText then Exit;
    if not IsScriptIntegerText((Current).Next.Text) then Exit;
    if Current.TokenKind = ctSubtract then Exponent := -ScriptStringToInt(Current.Next.Text)
    else if Current.TokenKind = ctAdd then Exponent := ScriptStringToInt(Current.Next.Text)
    else Exit;
    Current := Current.Next.Next;
  end
  else Current := Current.Next;
  if Exponent > 0 then Value := Power(10, Exponent) * Value
  else if Exponent < 0 then Value := Value / Power(10, -Exponent);
  Value := Value * Sign;
  Token := Current;
  Result := True;
end;
{ @end $4570D8 }

{ @routine $4573A4 TryReadIntegerLiteral }
function TryReadIntegerLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Integer): Boolean;
var
  Sign: Integer;
  Current: TCodeAnalyzerUnitEC;
begin
  Current := Token;
  Result := False;
  Sign := 1;
  if Current = nil then Exit;
  if Current.TokenKind = ctSubtract then
  begin
    Sign := -1;
    Current := Current.Next;
    if Current = nil then Exit;
  end;
  if Current.TokenKind <> ctText then Exit;
  if not IsScriptIntegerText(Current.Text) then Exit;
  Value := ScriptStringToInt(Current.Text);
  Current := Current.Next;
  Value := Sign * Value;
  Token := Current;
  Result := True;
end;
{ @end $4573A4 }

{ @routine $457404 TryReadStringLiteral }
function TryReadStringLiteral(var Token: TCodeAnalyzerUnitEC; var Value: WideString): Boolean;
var
  Current: TCodeAnalyzerUnitEC;
begin
  Current := Token;
  Result := False;
  if Current = nil then Exit;
  if Current.TokenKind <> ctStringLiteral then Exit;
  Value := Current.Text;
  Current := Current.Next;
  Token := Current;
  Result := True;
end;
{ @end $457404 }

{ @routine $457430 TryReadDwordLiteral }
function TryReadDwordLiteral(var Token: TCodeAnalyzerUnitEC; out Value: Dword): Boolean;
var
  Current: TCodeAnalyzerUnitEC;
  C: WideChar;
  Count, i: Integer;
begin
  Value := 0;
  Current := Token;
  Result := False;
  if Current = nil then Exit;
  if Current.TokenKind <> ctText then Exit;
  Count := Length(Current.Text);
  if Count < 2 then Exit;
  C := Current.Text[Count];
  if (C = 'h') or (C = 'H') then
    for i := 0 to Count - 2 do
    begin
      C := Current.Text[i + 1];
      if (C >= '0') and (C <= '9') then Value := Value * 16 + Dword(Ord(C) - Ord('0'))
      else if (C >= 'a') and (C <= 'f') then Value := Value * 16 + Dword(Ord(C) + 10 - Ord('a'))
      else if (C >= 'A') and (C <= 'F') then Value := Value * 16 + Dword(Ord(C) + 10 - Ord('A'))
      else Exit;
    end
  else if (C = 'b') or (C = 'B') then
    for i := 0 to Count - 2 do
    begin
      C := Current.Text[i + 1];
      if (C >= '0') and (C <= '1') then Value := Value * 2 + Dword(Ord(C) - Ord('0'))
      else Exit;
    end
  else Exit;
  Current := Current.Next;
  Token := Current;
  Result := True;
end;
{ @end $457430 }

{ @routine $45754C TryReadMemberName }
function TryReadMemberName(var Token: TCodeAnalyzerUnitEC; var Name: WideString): Boolean;
begin
  Name := '';
  while (Token.TokenKind = ctText) and IsNonIntegerScriptText(Token.Text) do
  begin
    Name := Name + Token.Text;
    Token := Token.Next;
    if (Token = nil) or (Token.TokenKind <> ctDot) then Break;
    Name := Name + '.';
    Token := Token.Next;
    if (Token = nil) or (Token.TokenKind <> ctText) or not IsNonIntegerScriptText(Token.Text) then
    begin
      Name := '';
      Break;
    end;
  end;
  Result := Name <> '';
end;
{ @end $45754C }

{ @routine $4575E0 TVarEC_Create }
constructor TVarEC.Create(InitialKind: TVarKind);
begin
  inherited Create;
  Kind := InitialKind;
  if InitialKind = vkFunction then FunctionValue := TCodeEC.Create;
end;
{ @end $4575E0 }

{ @routine $457638 TVarEC_Destroy }
destructor TVarEC.Destroy;
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  LibraryFunData := nil;
  inherited Destroy;
end;
{ @end $457638 }

{ @routine $45767C TVarEC_ConvertToKind }
procedure TVarEC.ConvertToKind(NewKind: TVarKind);
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  // Each supported conversion is checked explicitly. In particular, dword ->
  // float is rejected, and dword -> array/ref clears ExternFunValue instead.
  if NewKind = vkInt then
  begin
        if Kind = vkEmpty then IntValue := 0
        else if Kind = vkInt then begin end
        else if Kind = vkDword then IntValue := Integer(DwordValue)
        else if Kind = vkFloat then IntValue := Trunc(FloatValue)
        else if Kind = vkString then IntValue := ScriptStringToInt(StringValue)
        else if Kind = vkExternFun then IntValue := 0
        else if Kind = vkLibraryFun then IntValue := 0
        else if Kind = vkClass then IntValue := 0
        else if Kind = vkArray then IntValue := 0
        else if Kind = vkRef then IntValue := 0
        else raise ExceptionExpressionEC.Create('Type error');
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkDword then
  begin
        if Kind = vkEmpty then DwordValue := 0
        else if Kind = vkInt then DwordValue := Dword(IntValue)
        else if Kind = vkDword then begin end
        else if Kind = vkFloat then DwordValue := Dword(Trunc(FloatValue))
        else if Kind = vkString then DwordValue := Dword(ScriptStringToInt(StringValue))
        else if Kind = vkExternFun then DwordValue := 0
        else if Kind = vkLibraryFun then DwordValue := 0
        else if Kind = vkClass then DwordValue := 0
        else if Kind = vkArray then DwordValue := 0
        else if Kind = vkRef then DwordValue := 0
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkFloat then
  begin
        if Kind = vkEmpty then FloatValue := 0
        else if Kind = vkInt then FloatValue := IntValue
        else if Kind = vkFloat then begin end
        else if Kind = vkString then FloatValue := ScriptStringToFloat(StringValue)
        else if Kind = vkExternFun then FloatValue := 0
        else if Kind = vkLibraryFun then FloatValue := 0
        else if Kind = vkClass then FloatValue := 0
        else if Kind = vkArray then FloatValue := 0
        else if Kind = vkRef then FloatValue := 0
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkString then
  begin
        if Kind = vkEmpty then StringValue := ''
        else if Kind = vkInt then StringValue := IntToStr(IntValue)
        else if Kind = vkDword then StringValue := IntToStr(Int64(DwordValue))
        else if Kind = vkFloat then StringValue := ScriptFloatToString(FloatValue)
        else if Kind = vkString then begin end
        else if Kind = vkExternFun then StringValue := ''
        else if Kind = vkLibraryFun then StringValue := ''
        else if Kind = vkClass then StringValue := ''
        else if Kind = vkArray then StringValue := ''
        else if Kind = vkRef then StringValue := ''
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkExternFun then
  begin
        if Kind = vkEmpty then ExternFunValue := nil
        else if Kind = vkInt then ExternFunValue := nil
        else if Kind = vkDword then ExternFunValue := nil
        else if Kind = vkFloat then ExternFunValue := nil
        else if Kind = vkString then ExternFunValue := nil
        else if Kind = vkExternFun then begin end
        else if Kind = vkLibraryFun then ExternFunValue := nil
        else if Kind = vkClass then ExternFunValue := nil
        else if Kind = vkArray then ExternFunValue := nil
        else if Kind = vkRef then ExternFunValue := nil
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkLibraryFun then
  begin
        if Kind = vkEmpty then LibraryFunData := nil
        else if Kind = vkInt then LibraryFunData := nil
        else if Kind = vkDword then LibraryFunData := nil
        else if Kind = vkFloat then LibraryFunData := nil
        else if Kind = vkString then LibraryFunData := nil
        else if Kind = vkExternFun then LibraryFunData := nil
        else if Kind = vkLibraryFun then begin end
        else if Kind = vkClass then LibraryFunData := nil
        else if Kind = vkArray then LibraryFunData := nil
        else if Kind = vkRef then LibraryFunData := nil
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkFunction then
  begin
        if Kind = vkEmpty then FunctionValue := nil
        else if Kind = vkInt then FunctionValue := nil
        else if Kind = vkDword then FunctionValue := nil
        else if Kind = vkFloat then FunctionValue := nil
        else if Kind = vkString then FunctionValue := nil
        else if Kind = vkExternFun then FunctionValue := nil
        else if Kind = vkLibraryFun then FunctionValue := nil
        else if Kind = vkFunction then FunctionValue := nil
        else if Kind = vkClass then FunctionValue := nil
        else if Kind = vkArray then FunctionValue := nil
        else if Kind = vkRef then FunctionValue := nil
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := TCodeEC.Create;
        ClassValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkClass then
  begin
        if Kind = vkEmpty then ClassValue := nil
        else if Kind = vkInt then ClassValue := nil
        else if Kind = vkDword then ClassValue := nil
        else if Kind = vkFloat then ClassValue := nil
        else if Kind = vkString then ClassValue := nil
        else if Kind = vkExternFun then ClassValue := nil
        else if Kind = vkLibraryFun then ClassValue := nil
        else if Kind = vkFunction then ClassValue := nil
        else if Kind = vkClass then begin end
        else if Kind = vkArray then ClassValue := nil
        else if Kind = vkRef then ClassValue := nil
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ArrayValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkArray then
  begin
        if Kind = vkEmpty then ArrayValue := nil
        else if Kind = vkInt then ArrayValue := nil
        else if Kind = vkDword then ExternFunValue := nil
        else if Kind = vkFloat then ArrayValue := nil
        else if Kind = vkString then ArrayValue := nil
        else if Kind = vkExternFun then ArrayValue := nil
        else if Kind = vkLibraryFun then ArrayValue := nil
        else if Kind = vkClass then ArrayValue := nil
        else if Kind = vkArray then begin end
        else if Kind = vkRef then ArrayValue := nil
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        RefValue := nil;
  end
  else if NewKind = vkRef then
  begin
        if Kind = vkEmpty then RefValue := nil
        else if Kind = vkInt then RefValue := nil
        else if Kind = vkDword then ExternFunValue := nil
        else if Kind = vkFloat then RefValue := nil
        else if Kind = vkString then RefValue := nil
        else if Kind = vkExternFun then RefValue := nil
        else if Kind = vkLibraryFun then RefValue := nil
        else if Kind = vkClass then RefValue := nil
        else if Kind = vkArray then RefValue := nil
        else if Kind = vkRef then begin end
        else raise ExceptionExpressionEC.Create('Type error');
        IntValue := 0;
        DwordValue := 0;
        FloatValue := 0;
        StringValue := '';
        ExternFunValue := nil;
        LibraryFunData := nil;
        FunctionValue := nil;
        ClassValue := nil;
        ArrayValue := nil;
  end;
  Kind := NewKind;
end;
{ @end $45767C }

{ @routine $457FC8 TVarEC_ResetKind }
procedure TVarEC.ResetKind(NewKind: TVarKind);
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.ResetKind(NewKind);
  end
  else
  begin
    Kind := NewKind;
    IntValue := 0;
    DwordValue := 0;
    FloatValue := 0;
    StringValue := '';
    ExternFunValue := nil;
    LibraryFunData := nil;
    FunctionValue := nil;
    ClassValue := nil;
    ArrayValue := nil;
    RefValue := nil;
    if NewKind = vkFunction then FunctionValue := TCodeEC.Create;
  end;
end;
{ @end $457FC8 }

{ @routine $458054 TVarEC_RealVType }
function TVarEC.RealVType: TVarKind;
var
  Value: TVarEC;
begin
  Value := Resolve;
  if Value = nil then raise ExceptionExpressionEC.Create('Undefined ref. Name=' + Name);
  Result := Value.Kind;
end;
{ @end $458054 }

{ @routine $458108 TVarEC_AssignFrom }
procedure TVarEC.AssignFrom(Source: TVarEC);
var
  i: Integer;
begin
  if FunctionValue <> nil then
  begin
    FunctionValue.Free;
    FunctionValue := nil;
  end;
  Name := Source.Name;
  Kind := Source.Kind;
  IntValue := Source.IntValue;
  DwordValue := Source.DwordValue;
  FloatValue := Source.FloatValue;
  StringValue := Source.StringValue;
  ExternFunValue := Source.ExternFunValue;
  ClassValue := Source.ClassValue;
  ArrayValue := Source.ArrayValue;
  RefValue := Source.RefValue;
  LibraryFunData := nil;
  if Source.LibraryFunData <> nil then
  begin
    SetLength(LibraryFunData, High(Source.LibraryFunData) + 1);
    for i := 0 to High(LibraryFunData) do LibraryFunData[i] := Source.LibraryFunData[i];
  end;
  FunctionValue := nil;
  if Source.FunctionValue <> nil then
  begin
    FunctionValue := TCodeEC.Create;
    FunctionValue.CopyFrom(Source.FunctionValue);
  end;
end;
{ @end $458108 }

{ @routine $4581EC TVarEC_IsEmpty }
function TVarEC.IsEmpty: Boolean;
begin
  Result := Kind = vkEmpty;
end;
{ @end $4581EC }

{ @routine $4581F4 TVarEC_GetInt }
function TVarEC.GetInt: Integer;
begin
  if Kind = vkEmpty then Result := 0
  else if Kind = vkInt then Result := IntValue
  else if Kind = vkDword then Result := Integer(DwordValue)
  else if Kind = vkFloat then Result := Trunc(FloatValue)
  else if Kind = vkString then Result := ScriptStringToInt(StringValue)
  else if Kind = vkExternFun then Result := 0
  else if Kind = vkLibraryFun then Result := 0
  else if Kind = vkFunction then Result := 0
  else if Kind = vkClass then Result := 0
  else if Kind = vkArray then Result := 0
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := 0
    else Result := RefValue.GetInt;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $4581F4 }

{ @routine $45829C TVarEC_GetDword }
function TVarEC.GetDword: Dword;
begin
  if Kind = vkEmpty then Result := 0
  else if Kind = vkInt then Result := Dword(IntValue)
  else if Kind = vkDword then Result := DwordValue
  else if Kind = vkFloat then Result := Dword(Trunc(FloatValue))
  else if Kind = vkString then Result := Dword(ScriptStringToInt(StringValue))
  else if Kind = vkExternFun then Result := 0
  else if Kind = vkLibraryFun then Result := 0
  else if Kind = vkFunction then Result := 0
  else if Kind = vkClass then Result := 0
  else if Kind = vkArray then Result := 0
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := 0
    else Result := RefValue.GetInt;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $45829C }

{ @routine $458344 TVarEC_GetFloat }
function TVarEC.GetFloat: Double;
begin
  if Kind = vkEmpty then Result := 0
  else if Kind = vkInt then Result := IntValue
  else if Kind = vkDword then Result := DwordValue
  else if Kind = vkFloat then Result := FloatValue
  else if Kind = vkString then Result := ScriptStringToFloat(StringValue)
  else if Kind = vkExternFun then Result := 0
  else if Kind = vkLibraryFun then Result := 0
  else if Kind = vkFunction then Result := 0
  else if Kind = vkClass then Result := 0
  else if Kind = vkArray then Result := 0
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := 0
    else Result := RefValue.GetFloat;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $458344 }

{ @routine $458460 TVarEC_GetString }
function TVarEC.GetString: WideString;
begin
  if Kind = vkEmpty then Result := ''
  else if Kind = vkInt then Result := IntToStr(IntValue)
  else if Kind = vkDword then Result := IntToStr(Int64(DwordValue))
  else if Kind = vkFloat then Result := ScriptFloatToString(FloatValue)
  else if Kind = vkString then Result := StringValue
  else if Kind = vkExternFun then Result := ''
  else if Kind = vkLibraryFun then Result := ''
  else if Kind = vkFunction then Result := ''
  else if Kind = vkClass then Result := ''
  else if Kind = vkArray then Result := ''
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := ''
    else Result := RefValue.GetString;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $458460 }

{ @routine $4585A8 TVarEC_GetExternFun }
function TVarEC.GetExternFun: Pointer;
begin
  if Kind = vkEmpty then Result := nil
  else if Kind = vkInt then Result := nil
  else if Kind = vkDword then Result := nil
  else if Kind = vkFloat then Result := nil
  else if Kind = vkString then Result := nil
  else if Kind = vkExternFun then Result := ExternFunValue
  else if Kind = vkLibraryFun then Result := nil
  else if Kind = vkFunction then Result := nil
  else if Kind = vkClass then Result := nil
  else if Kind = vkArray then Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := nil
    else Result := RefValue.GetExternFun;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $4585A8 }

{ @routine $458648 TVarEC_GetFunction }
function TVarEC.GetFunction: TCodeEC;
begin
  if Kind = vkEmpty then Result := nil
  else if Kind = vkInt then Result := nil
  else if Kind = vkDword then Result := nil
  else if Kind = vkFloat then Result := nil
  else if Kind = vkString then Result := nil
  else if Kind = vkExternFun then Result := nil
  else if Kind = vkLibraryFun then Result := nil
  else if Kind = vkFunction then Result := FunctionValue
  else if Kind = vkClass then Result := nil
  else if Kind = vkArray then Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := nil
    else Result := RefValue.GetFunction;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $458648 }

{ @routine $4586E8 TVarEC_GetClass }
function TVarEC.GetClass: TCodeEC;
begin
  if Kind = vkEmpty then Result := nil
  else if Kind = vkInt then Result := nil
  else if Kind = vkDword then Result := nil
  else if Kind = vkFloat then Result := nil
  else if Kind = vkString then Result := nil
  else if Kind = vkExternFun then Result := nil
  else if Kind = vkLibraryFun then Result := nil
  else if Kind = vkFunction then Result := nil
  else if Kind = vkClass then Result := ClassValue
  else if Kind = vkArray then Result := nil
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := nil
    else Result := RefValue.GetFunction;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $4586E8 }

{ @routine $458788 TVarEC_GetArray }
function TVarEC.GetArray: TVarArrayEC;
begin
  if Kind = vkEmpty then Result := nil
  else if Kind = vkInt then Result := nil
  else if Kind = vkDword then Result := nil
  else if Kind = vkFloat then Result := nil
  else if Kind = vkString then Result := nil
  else if Kind = vkExternFun then Result := nil
  else if Kind = vkLibraryFun then Result := nil
  else if Kind = vkFunction then Result := nil
  else if Kind = vkClass then Result := nil
  else if Kind = vkArray then Result := ArrayValue
  else if Kind = vkRef then
  begin
    if RefValue = nil then Result := nil
    else Result := RefValue.GetArray;
  end
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $458788 }

{ @routine $458828 TVarEC_SetInt }
procedure TVarEC.SetInt(Value: Integer);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkInt);
    IntValue := Value;
  end
  else if Kind = vkInt then
    IntValue := Value
  else if Kind = vkDword then
    DwordValue := Dword(Value)
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := IntToStr(Value)
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetInt(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458828 }

{ @routine $45893C TVarEC_SetDword }
procedure TVarEC.SetDword(Value: Dword);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkInt);
    IntValue := Integer(Value);
  end
  else if Kind = vkInt then
    IntValue := Integer(Value)
  else if Kind = vkDword then
    DwordValue := Value
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := IntToStr(Int64(Value))
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetInt(Integer(Value))
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $45893C }

{ @routine $458A5C TVarEC_SetFloat }
procedure TVarEC.SetFloat(Value: Double);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkFloat);
    FloatValue := Value;
  end
  else if Kind = vkInt then
    IntValue := Trunc(Value)
  else if Kind = vkDword then
    DwordValue := Dword(Trunc(Value))
  else if Kind = vkFloat then
    FloatValue := Value
  else if Kind = vkString then
    StringValue := ScriptFloatToString(Value)
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetFloat(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458A5C }

{ @routine $458B90 TVarEC_SetString }
procedure TVarEC.SetString(const Value: WideString);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkString);
    StringValue := Value;
  end
  else if Kind = vkInt then
    IntValue := ScriptStringToInt(Value)
  else if Kind = vkDword then
    DwordValue := Dword(ScriptStringToInt(Value))
  else if Kind = vkFloat then
    FloatValue := ScriptStringToFloat(Value)
  else if Kind = vkString then
    StringValue := Value
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetString(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458B90 }

{ @routine $458C74 TVarEC_SetExternFun }
procedure TVarEC.SetExternFun(Value: Pointer);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkExternFun);
    ExternFunValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := Value
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetExternFun(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458C74 }

{ @routine $458D40 TVarEC_SetFunction }
procedure TVarEC.SetFunction(Value: TCodeEC);
begin
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetFunction(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458D40 }

{ @routine $458DFC TVarEC_SetClass }
procedure TVarEC.SetClass(Value: TCodeEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkClass);
    ClassValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := Value
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetFunction(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458DFC }

{ @routine $458EC8 TVarEC_SetArray }
procedure TVarEC.SetArray(Value: TVarArrayEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkArray);
    ArrayValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := Value
  else if Kind = vkRef then
  begin
    if RefValue <> nil then RefValue.SetArray(Value)
    else raise ExceptionExpressionEC.Create('Type error');
  end;
end;
{ @end $458EC8 }

{ @routine $458F94 TVarEC_SetRef }
procedure TVarEC.SetRef(Value: TVarEC);
begin
  if Kind = vkEmpty then
  begin
    ResetKind(vkRef);
    RefValue := Value;
  end
  else if Kind = vkInt then
    IntValue := 0
  else if Kind = vkDword then
    DwordValue := 0
  else if Kind = vkFloat then
    FloatValue := 0
  else if Kind = vkString then
    StringValue := ''
  else if Kind = vkExternFun then
    ExternFunValue := nil
  else if Kind = vkLibraryFun then
    LibraryFunData := nil
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
    ClassValue := nil
  else if Kind = vkArray then
    ArrayValue := nil
  else if Kind = vkRef then
    RefValue := Value
  else raise ExceptionExpressionEC.Create('Type error');
end;
{ @end $458F94 }

{ @routine $459054 TVarEC_Resolve }
function TVarEC.Resolve: TVarEC;
begin
  Result := Self;
  while (Result <> nil) and (Result.Kind = vkRef) do Result := Result.RefValue;
end;
{ @end $459054 }

{ @routine $459064 TVarEC_PackAnsiString }
procedure TVarEC.PackAnsiString;
var
  Text: AnsiString;
  i, Count: Integer;
  Dest: PAnsiChar;
begin
  ConvertToKind(vkString);
  Count := Length(StringValue);
  if Count > 0 then
  begin
    Text := StringValue;
    Dest := PAnsiChar(PWideChar(StringValue));
    for i := 0 to Count - 1 + 1 do
    begin
      Dest^ := Text[i + 1];
      Inc(Dest);
    end;
    if Odd(Count) then SetLength(StringValue, (Count shr 1) + 1)
    else SetLength(StringValue, Count shr 1);
  end;
end;
{ @end $459064 }

{ @routine $459110 TVarEC_UnpackAnsiString }
procedure TVarEC.UnpackAnsiString;
var
  Text: AnsiString;
  Count: Integer;
begin
  if Kind <> vkString then ConvertToKind(vkString)
  else
  begin
    Count := Length(StringValue);
    if Count > 0 then
    begin
      Text := PAnsiChar(PWideChar(StringValue));
      StringValue := Text;
    end;
  end;
end;
{ @end $459110 }

{ @routine $459184 FreeScriptArrayTree }
procedure FreeScriptArrayTree(Values: TVarArrayEC);
var
  i, Count: Integer;
  Item: TVarEC;
begin
  Count := Values.Count;
  for i := 0 to Count - 1 do
  begin
    Item := Values.GetItem(i);
    if (Item.Kind = vkArray) and (Item.GetArray <> nil) then
    begin
      FreeScriptArrayTree(Item.GetArray);
    end;
  end;
  Values.Free;
end;
{ @end $459184 }

{ @routine $4591D0 GrowScriptArray }
procedure GrowScriptArray(Values: TVarArrayEC; Dimensions: array of Integer; DimensionIndex: Integer);
var
  i, Count: Integer;
  Item: TVarEC;
begin
  { Native appends Count entries, including when Values is nonempty. }
  Count := Dimensions[DimensionIndex];
  if High(Dimensions) = DimensionIndex then
  begin
    for i := 0 to Count - 1 do Values.Add('', vkEmpty);
  end
  else
  begin
    for i := 0 to Count - 1 do
    begin
      Item := Values.Add('', vkArray);
      Item.SetArray(TVarArrayEC.Create);
      GrowScriptArray(Item.GetArray, Dimensions, DimensionIndex + 1);
    end;
  end;
end;
{ @end $4591D0 }

{ @routine $45930C ResizeScriptArray }
procedure ResizeScriptArray(Values: TVarArrayEC; Count: Integer);
var
  i, OldCount: Integer;
  Item: TVarEC;
  Dimensions: array of Integer;

  // @nested $459294 CollectScriptArrayDimensions
  procedure CollectScriptArrayDimensions(Values: TVarArrayEC); // @addr $459294 @note "Nested in ResizeScriptArray; collects dimensions by following each first child."
  begin
    SetLength(Dimensions, High(Dimensions) + 1 + 1);
    Dimensions[High(Dimensions)] := Values.Count;
    if (Values.Count > 0) and (Values.GetItem(0).RealVType = vkArray) then
      CollectScriptArrayDimensions(Values.GetItem(0).GetArray);
  end;

begin
  OldCount := Values.Count;
  if Count = OldCount then Exit;
  if Count < OldCount then
  begin
    for i := Count to OldCount - 1 do
    begin
      Item := Values.GetItem(i);
      if (Item.Kind = vkArray) and (Item.GetArray <> nil) then FreeScriptArrayTree(Item.GetArray);
    end;
    for i := OldCount - 1 downto Count do Values.Delete(i);
  end
  else
  begin
    Dimensions := nil;
    CollectScriptArrayDimensions(Values);
    // Native growth keeps the collected dimensions, ignoring the larger Count.
    GrowScriptArray(Values, Dimensions, 0);
  end;
end;
{ @end $45930C }

{ @routine $4593FC TVarEC_CreateArray }
procedure TVarEC.CreateArray(Dimensions: array of Integer);
begin
  ResetKind(vkArray);
  ArrayValue := TVarArrayEC.Create;
  GrowScriptArray(ArrayValue, Dimensions, 0);
end;
{ @end $4593FC }

{ @routine $459450 TVarEC_ResizeArray }
procedure TVarEC.ResizeArray(Count, Dimension: Integer);
begin
  if RealVType = vkArray then
  begin
    if Count <= 0 then FreeArray
    else if Dimension <= 0 then
    begin
      if GetArray = nil then CreateArray([Count])
      else ResizeScriptArray(GetArray, Count);
    end;
  end;
end;
{ @end $459450 }

{ @routine $4594A4 TVarEC_FreeArray }
procedure TVarEC.FreeArray;
begin
  if (RealVType = vkArray) and (GetArray <> nil) then
  begin
    FreeScriptArrayTree(GetArray);
    SetArray(nil);
  end;
end;
{ @end $4594A4 }

{ @routine $4594D4 TVarEC_OAdd }
procedure TVarEC.OAdd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt + Right.GetInt);
      vkDword: SetDword(Left.GetDword + Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat + Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OAdd');
    end;
  end;
end;
{ @end $4594D4 }

{ @routine $459670 TVarEC_OSub }
procedure TVarEC.OSub(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt - Right.GetInt);
      vkDword: SetDword(Left.GetDword - Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat - Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OSub');
    end;
  end;
end;
{ @end $459670 }

{ @routine $45980C TVarEC_OMul }
procedure TVarEC.OMul(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt * Right.GetInt);
      vkDword: SetDword(Left.GetDword * Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat * Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OMul');
    end;
  end;
end;
{ @end $45980C }

{ @routine $4599A8 TVarEC_ODiv }
procedure TVarEC.ODiv(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt div Right.GetInt);
      vkDword: SetDword(Left.GetDword div Right.GetDword);
      vkFloat: SetFloat(Left.GetFloat / Right.GetFloat);
      vkString: SetString(Left.GetString + Right.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('ODiv');
    end;
  end;
end;
{ @end $4599A8 }

{ @routine $459B50 TVarEC_OMod }
procedure TVarEC.OMod(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt mod Right.GetInt);
      vkDword: SetDword(Left.GetDword mod Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) mod Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OMod');
    end;
  end;
end;
{ @end $459B50 }

{ @routine $459CAC TVarEC_OBitAnd }
procedure TVarEC.OBitAnd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt and Right.GetInt);
      vkDword: SetDword(Left.GetDword and Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) and Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OBitAnd');
    end;
  end;
end;
{ @end $459CAC }

{ @routine $459E08 TVarEC_OBitOr }
procedure TVarEC.OBitOr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt or Right.GetInt);
      vkDword: SetDword(Left.GetDword or Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) or Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OBitAnd');
    end;
  end;
end;
{ @end $459E08 }

{ @routine $459F64 TVarEC_OBitXor }
procedure TVarEC.OBitXor(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt xor Right.GetInt);
      vkDword: SetDword(Left.GetDword xor Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) xor Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OBitXor');
    end;
  end;
end;
{ @end $459F64 }

{ @routine $45A0C0 TVarEC_OAnd }
procedure TVarEC.OAnd(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord((Left.GetInt <> 0) and (Right.GetInt <> 0)));
      vkDword: SetDword(Ord((Left.GetDword <> 0) and (Right.GetDword <> 0)));
      vkFloat: SetFloat(Integer((Left.GetFloat <> 0) and (Right.GetFloat <> 0)));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OAnd');
    end;
  end;
end;
{ @end $45A0C0 }

{ @routine $45A238 TVarEC_OOr }
procedure TVarEC.OOr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord((Left.GetInt <> 0) or (Right.GetInt <> 0)));
      vkDword: SetDword(Ord((Left.GetDword <> 0) or (Right.GetDword <> 0)));
      vkFloat: SetFloat(Integer((Left.GetFloat <> 0) or (Right.GetFloat <> 0)));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OAnd');
    end;
  end;
end;
{ @end $45A238 }

{ @routine $45A3B0 TVarEC_OShl }
procedure TVarEC.OShl(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt shl Right.GetInt);
      vkDword: SetDword(Left.GetDword shl Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) shl Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OXor');
    end;
  end;
end;
{ @end $45A3B0 }

{ @routine $45A508 TVarEC_OShr }
procedure TVarEC.OShr(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Left.GetInt shr Right.GetInt);
      vkDword: SetDword(Left.GetDword shr Right.GetDword);
      vkFloat: SetFloat(Trunc(Left.GetFloat) shr Trunc(Right.GetFloat));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OXor');
    end;
  end;
end;
{ @end $45A508 }

{ @routine $45A660 TVarEC_OEqual }
procedure TVarEC.OEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt = Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword = Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat = Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString = Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OEqual');
    end;
  end;
end;
{ @end $45A660 }

{ @routine $45A844 TVarEC_ONotEqual }
procedure TVarEC.ONotEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt <> Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword <> Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat <> Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString <> Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('ONotEqual');
    end;
  end;
end;
{ @end $45A844 }

{ @routine $45AA2C TVarEC_OLess }
procedure TVarEC.OLess(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt < Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword < Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat < Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString < Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OLess');
    end;
  end;
end;
{ @end $45AA2C }

{ @routine $45AC10 TVarEC_OMore }
procedure TVarEC.OMore(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt > Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword > Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat > Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString > Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OMore');
    end;
  end;
end;
{ @end $45AC10 }

{ @routine $45ADF4 TVarEC_OLessEqual }
procedure TVarEC.OLessEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt <= Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword <= Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat <= Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString <= Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OLessEqual');
    end;
  end;
end;
{ @end $45ADF4 }

{ @routine $45AFDC TVarEC_OMoreEqual }
procedure TVarEC.OMoreEqual(Left, Right: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Left.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Left.RealVType of
      vkInt: SetInt(Ord(Left.GetInt >= Right.GetInt));
      vkDword: SetDword(Ord(Left.GetDword >= Right.GetDword));
      vkFloat: SetFloat(Integer(Left.GetFloat >= Right.GetFloat));
      vkString: SetString(IntToStr(Ord(Left.GetString >= Right.GetString)));
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OMoreEqual');
    end;
  end;
end;
{ @end $45AFDC }

{ @routine $45B1C4 TVarEC_OMinus }
procedure TVarEC.OMinus(Value: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(-Value.GetInt);
      vkDword: SetDword(Dword(-Integer(Value.GetDword)));
      vkFloat: SetFloat(-Value.GetFloat);
      vkString: SetString(Value.GetString);
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OMinus');
    end;
  end;
end;
{ @end $45B1C4 }

{ @routine $45B318 TVarEC_OBitNot }
procedure TVarEC.OBitNot(Value: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(not Value.GetInt);
      vkDword: SetDword(not Value.GetDword);
      vkFloat: SetFloat(0);
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('OBitNot');
    end;
  end;
end;
{ @end $45B318 }

{ @routine $45B420 TVarEC_ONot }
procedure TVarEC.ONot(Value: TVarEC);
begin
  if RealVType = vkEmpty then ResetKind(Value.RealVType);
  if RealVType <> vkEmpty then
  begin
    case Value.RealVType of
      vkInt: SetInt(Ord(Value.GetInt = 0));
      vkDword: SetDword(Ord(Value.GetInt = 0));
      vkFloat: SetFloat(Integer(Value.GetFloat = 0));
      vkString: SetString('');
      vkExternFun: SetExternFun(nil);
      vkFunction: SetFunction(nil);
      vkClass: SetClass(nil);
      vkArray: SetArray(nil);
    else raise ExceptionExpressionEC.Create('ONot');
    end;
  end;
end;
{ @end $45B420 }

{ @routine $45B558 TVarEC_Assume }
procedure TVarEC.Assume(Source: TVarEC);
var
  Dest: TVarEC;
  i: Integer;
begin
  Dest := Self;
  if Kind = vkRef then
  begin
    Dest := Resolve;
    if Dest = nil then Exit;
  end;
  if Dest.Kind = vkEmpty then Dest.ResetKind(Source.RealVType);
  if Dest.Kind = vkEmpty then
  begin
  end
  else if Dest.Kind = vkInt then Dest.SetInt(Source.GetInt)
  else if Dest.Kind = vkDword then Dest.SetDword(Source.GetDword)
  else if Dest.Kind = vkFloat then Dest.SetFloat(Source.GetFloat)
  else if Dest.Kind = vkString then Dest.SetString(Source.GetString)
  else if Dest.Kind = vkExternFun then Dest.SetExternFun(Source.GetExternFun)
  else if Dest.Kind = vkLibraryFun then
  begin
    Dest.LibraryFunData := nil;
    if Source.LibraryFunData <> nil then
    begin
      SetLength(Dest.LibraryFunData, High(Source.LibraryFunData) + 1);
      for i := 0 to High(Dest.LibraryFunData) do Dest.LibraryFunData[i] := Source.LibraryFunData[i];
    end;
  end
  else if Dest.Kind = vkFunction then Dest.SetFunction(Source.GetFunction)
  else if Dest.Kind = vkClass then Dest.SetClass(Source.GetClass)
  else if Dest.Kind = vkArray then Dest.SetArray(Source.GetArray)
  else raise ExceptionExpressionEC.Create('OAssume');
end;
{ @end $45B558 }

{ @routine $45B71C TVarEC_LessThan }
function TVarEC.LessThan(Other: TVarEC): Boolean;
begin
  case RealVType of
    vkEmpty: Result := IsEmpty < Other.IsEmpty;
    vkInt: Result := GetInt < Other.GetInt;
    vkDword: Result := GetDword < Other.GetDword;
    vkFloat: Result := GetFloat < Other.GetFloat;
    vkString: Result := GetString < Other.GetString;
    vkExternFun: Result := False;
    vkFunction: Result := False;
    vkClass: Result := False;
    vkArray: Result := False;
  else raise ExceptionExpressionEC.Create('Less');
  end;
end;
{ @end $45B71C }

{ @routine $45B878 TVarEC_GreaterThan }
function TVarEC.GreaterThan(Other: TVarEC): Boolean;
begin
  case RealVType of
    vkEmpty: Result := IsEmpty > Other.IsEmpty;
    vkInt: Result := GetInt > Other.GetInt;
    vkDword: Result := GetDword > Other.GetDword;
    vkFloat: Result := GetFloat > Other.GetFloat;
    vkString: Result := GetString > Other.GetString;
    vkExternFun: Result := False;
    vkFunction: Result := False;
    vkClass: Result := False;
    vkArray: Result := False;
  else raise ExceptionExpressionEC.Create('More');
  end;
end;
{ @end $45B878 }

{ @routine $45B9D4 TVarEC_IsTrue }
function TVarEC.IsTrue: Boolean;
begin
  case RealVType of
    vkEmpty: Result := False;
    vkInt: Result := GetInt <> 0;
    vkDword: Result := GetDword <> 0;
    vkFloat: Result := GetFloat <> 0;
    vkString: Result := GetString <> '';
    vkExternFun: Result := False;
    vkLibraryFun: Result := Resolve.LibraryFunData <> nil;
    vkFunction: Result := False;
    vkClass: Result := GetClass <> nil;
    vkArray: Result := False;
  else raise ExceptionExpressionEC.Create('IsTrue');
  end;
end;
{ @end $45B9D4 }

{ @routine $45BB04 TVarEC_SaveToBuffer }
procedure TVarEC.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddWideStringZ(Name);
  Buffer.AddAnsiChar(AnsiChar(Kind));
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
  begin
    Buffer.AddIntegerValue(IntValue);
  end
  else if Kind = vkDword then
  begin
    Buffer.AddDWord(DwordValue);
  end
  else if Kind = vkFloat then
  begin
    Buffer.AddDouble(FloatValue);
  end
  else if Kind = vkString then
  begin
    Buffer.AddWideStringZ(StringValue);
  end
  else if Kind = vkExternFun then
  begin
  end
  else if Kind = vkLibraryFun then
  begin
  end
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
  begin
  end
  else if Kind = vkArray then
  begin
  end
  else if Kind = vkRef then
  begin
  end;
end;
{ @end $45BB04 }

{ @routine $45BB84 TVarEC_LoadFromBuffer }
procedure TVarEC.LoadFromBuffer(Buffer: TBufEC);
begin
  Name := Buffer.ReadWideString;
  ResetKind(TVarKind(Buffer.GetByte));
  if Kind = vkEmpty then
  begin
  end
  else if Kind = vkInt then
  begin
    IntValue := Buffer.GetInt32;
  end
  else if Kind = vkDword then
  begin
    DwordValue := Buffer.GetUInt32;
  end
  else if Kind = vkFloat then
  begin
    FloatValue := Buffer.GetDouble;
  end
  else if Kind = vkString then
  begin
    StringValue := Buffer.ReadWideString;
  end
  else if Kind = vkExternFun then
  begin
  end
  else if Kind = vkLibraryFun then
  begin
  end
  else if Kind = vkFunction then
  begin
  end
  else if Kind = vkClass then
  begin
  end
  else if Kind = vkArray then
  begin
  end
  else if Kind = vkRef then
  begin
  end;
end;
{ @end $45BB84 }

{ @routine $45BC58 TVarArrayEC_Create }
constructor TVarArrayEC.Create;
begin
  inherited Create;
end;
{ @end $45BC58 }

{ @routine $45BC90 TVarArrayEC_Destroy }
destructor TVarArrayEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $45BC90 }

{ @routine $45BCBC TVarArrayEC_ClearStorage }
procedure TVarArrayEC.ClearStorage;
begin
  if Data <> nil then
  begin
    HeapFree(GetProcessHeap, 0, Data);
    Data := nil;
  end;
  if NameOrder <> nil then
  begin
    HeapFree(GetProcessHeap, 0, NameOrder);
    NameOrder := nil;
  end;
  Count := 0;
end;
{ @end $45BCBC }

{ @routine $45BD00 TVarArrayEC_Clear }
procedure TVarArrayEC.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    GetItem(i).Free;
  end;
  ClearStorage;
end;
{ @end $45BD00 }

{ @routine $45BD30 TVarArrayEC_CopyFrom }
procedure TVarArrayEC.CopyFrom(Source: TVarArrayEC);
var
  Item, SourceItem: TVarEC;
  i: Integer;
begin
  Clear;
  Count := Source.Count;
  if Count < 1 then Exit;
  Data := HeapAlloc(GetProcessHeap, 0, Count * SizeOf(TVarEC));
  NameOrder := HeapAlloc(GetProcessHeap, 0, Count * SizeOf(Integer));
  CopyMemory(NameOrder, Source.NameOrder, Count * SizeOf(Integer));
  for i := 0 to Count - 1 do
  begin
    SourceItem := Source.GetItem(i);
    Item := TVarEC.Create(vkEmpty);
    SetItem(i, Item);
    Item.Name := SourceItem.Name;
    Item.AssignFrom(SourceItem);
  end;
end;
{ @end $45BD30 }

{ @routine $45BDF0 TVarArrayEC_FindNameInsertionIndex }
function TVarArrayEC.FindNameInsertionIndex(const Name: WideString): Integer;
var
  Low, High, Middle, Comparison: Integer;
  Item: TVarEC;
begin
  if Count <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  Low := 0;
  High := Count - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Item := GetItemByNameOrder(Middle);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := Middle;
      Exit;
    end;
    if Comparison < 0 then High := Middle - 1
    else Low := Middle + 1;
  until High < Low;
  if Comparison < 0 then Result := Middle
  else Result := Middle + 1;
end;
{ @end $45BDF0 }

{ @routine $45BE70 TVarArrayEC_SetNameOrderIndex }
procedure TVarArrayEC.SetNameOrderIndex(Index: Integer; DataIndex: Integer);
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TVarArrayEC.NameOrder
  MOV EBX, DataIndex
  MOV [EAX], EBX
  POP EBX
  POP EAX
end;
{ @end $45BE70 }

{ @routine $45BE84 TVarArrayEC_GetNameOrderIndex }
function TVarArrayEC.GetNameOrderIndex(Index: Integer): Integer;
asm
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TVarArrayEC.NameOrder
  MOV EAX, [EAX]
  POP EBX
end;
{ @end $45BE84 }

{ @routine $45BE94 TVarArrayEC_GetItemByNameOrder }
function TVarArrayEC.GetItemByNameOrder(Index: Integer): TVarEC;
asm
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TVarArrayEC.NameOrder
  MOV EAX, [EAX]
  MOV EBX, [EBX].TVarArrayEC.Data
  MOV EAX, [EBX + EAX * 4]
  POP EBX
end;
{ @end $45BE94 }

{ @routine $45BEAC TVarArrayEC_FindNameOrderForDataIndex }
function TVarArrayEC.FindNameOrderForDataIndex(DataIndex: Integer): Integer;
asm
  PUSH EBX
  PUSH ECX
  PUSH EDX
  PUSH ESI
  MOV EBX, DataIndex
  MOV EAX, Self
  MOV ECX, [EAX].TVarArrayEC.Count
  XOR EDX, EDX
  MOV ESI, [EAX].TVarArrayEC.NameOrder
  MOV EAX, -1
  TEST ECX, ECX
  JZ @@Done
@@Next:
  MOV EAX, [ESI]
  CMP EAX, EBX
  JZ @@Found
  ADD ESI, 4
  INC EDX
  DEC ECX
  JNZ @@Next
  MOV EAX, -1
  JMP @@Done
@@Found:
  MOV EAX, EDX
@@Done:
  POP ESI
  POP EDX
  POP ECX
  POP EBX
end;
{ @end $45BEAC }

{ @routine $45BEE0 TVarArrayEC_GetItem }
function TVarArrayEC.GetItem(Index: Integer): TVarEC;
asm
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TVarArrayEC.Data
  MOV EAX, [EAX]
  POP EBX
end;
{ @end $45BEE0 }

{ @routine $45BEF0 TVarArrayEC_SetItem }
procedure TVarArrayEC.SetItem(Index: Integer; Value: TVarEC);
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TVarArrayEC.Data
  MOV EBX, Value
  MOV [EAX], EBX
  POP EBX
  POP EAX
end;
{ @end $45BEF0 }

{ @routine $45BF04 TVarArrayEC_GetItemNE }
function TVarArrayEC.GetItemNE(Index: Integer): TVarEC;
begin
  if (Index < 0) or (Index >= Count) then Result := nil
  else Result := GetItem(Index);
end;
{ @end $45BF04 }

{ @routine $45BF18 TVarArrayEC_GetVar }
function TVarArrayEC.GetVar(const Name: WideString): TVarEC;
begin
  Result := GetVarNE(Name);
  if Result = nil then raise ExceptionExpressionEC.Create('Var not found:' + Name);
end;
{ @end $45BF18 }

{ @routine $45BFC0 TVarArrayEC_GetVarNE }
function TVarArrayEC.GetVarNE(const Name: WideString): TVarEC;
var
  Low, High, Middle, Comparison: Integer;
  Item: TVarEC;
begin
  if Count < 1 then
  begin
    Result := nil;
    Exit;
  end;
  Low := 0;
  High := Count - 1;
  repeat
    Middle := (High - Low) div 2 + Low;
    Item := GetItemByNameOrder(Middle);
    Comparison := CompareScriptNames(PWideChar(Name), PWideChar(Item.Name));
    if Comparison = 0 then
    begin
      Result := GetItem(GetNameOrderIndex(Middle));
      Exit;
    end;
    if Comparison < 0 then High := Middle - 1
    else Low := Middle + 1;
  until High < Low;
  Result := nil;
end;
{ @end $45BFC0 }

{ @routine $45C048 TVarArrayEC_Delete }
procedure TVarArrayEC.Delete(Index: Integer);
var
  i, NameIndex, DataIndex: Integer;
  Item: TVarEC;
begin
  if (Index < 0) or (Index >= Count) or (Count < 1) then Exit;
  Item := GetItem(Index);
  if Item <> nil then Item.Free;
  NameIndex := FindNameOrderForDataIndex(Index);
  for i := NameIndex to Count - 2 do SetNameOrderIndex(i, GetNameOrderIndex(i + 1));
  for i := Index to Count - 2 do SetItem(i, GetItem(i + 1));
  Dec(Count);
  for i := 0 to Count - 1 do
  begin
    DataIndex := GetNameOrderIndex(i);
    if DataIndex > Index then SetNameOrderIndex(i, DataIndex - 1);
  end;
  if Count < 1 then Clear;
end;
{ @end $45C048 }

{ @routine $45C110 TVarArrayEC_AddItem }
procedure TVarArrayEC.AddItem(Value: TVarEC);
var
  i, InsertionIndex: Integer;
begin
  if Data = nil then Data := HeapAlloc(GetProcessHeap, 0, (Count + 1) * SizeOf(TVarEC))
  else Data := HeapReAlloc(GetProcessHeap, 0, Data, (Count + 1) * SizeOf(TVarEC));
  SetItem(Count, Value);
  InsertionIndex := FindNameInsertionIndex(Value.Name);
  if InsertionIndex >= Count then
  begin
    Inc(Count);
    if NameOrder = nil then NameOrder := HeapAlloc(GetProcessHeap, 0, Count * SizeOf(Integer))
    else NameOrder := HeapReAlloc(GetProcessHeap, 0, NameOrder, Count * SizeOf(Integer));
    SetNameOrderIndex(Count - 1, Count - 1);
  end
  else
  begin
    Inc(Count);
    NameOrder := HeapReAlloc(GetProcessHeap, 0, NameOrder, Count * SizeOf(Integer));
    for i := Count - 1 downto InsertionIndex + 1 do SetNameOrderIndex(i, GetNameOrderIndex(i - 1));
    SetNameOrderIndex(InsertionIndex, Count - 1);
  end;
end;
{ @end $45C110 }

{ @routine $45C214 TVarArrayEC_Add }
function TVarArrayEC.Add(const Name: WideString; Kind: TVarKind): TVarEC;
var
  Item: TVarEC;
begin
  Item := TVarEC.Create(Kind);
  Item.Name := Name;
  try
    AddItem(Item);
  except
    Item.Free;
    raise;
  end;
  Result := Item;
end;
{ @end $45C214 }

{ @routine $45C280 TVarArrayEC_SaveToBuffer }
procedure TVarArrayEC.SaveToBuffer(Buffer: TBufEC);
var
  i: Integer;
begin
  Buffer.AddIntegerValue(Count);
  for i := 0 to Count - 1 do GetItem(i).SaveToBuffer(Buffer);
end;
{ @end $45C280 }

{ @routine $45C2B8 TVarArrayEC_LoadFromBuffer }
procedure TVarArrayEC.LoadFromBuffer(Buffer: TBufEC);
var
  ItemCount, i: Integer;
  Item: TVarEC;
begin
  Clear;
  ItemCount := Buffer.GetInt32;
  for i := 0 to ItemCount - 1 do
  begin
    Item := TVarEC.Create(vkEmpty);
    Item.LoadFromBuffer(Buffer);
    AddItem(Item);
  end;
end;
{ @end $45C2B8 }

{ @routine $45C300 TVarArrayEC_AppendFromBuffer }
procedure TVarArrayEC.AppendFromBuffer(Buffer: TBufEC);
var
  ItemCount, i: Integer;
  Item: TVarEC;
begin
  ItemCount := Buffer.GetInt32;
  for i := 0 to ItemCount - 1 do
  begin
    Item := TVarEC.Create(vkEmpty);
    Item.LoadFromBuffer(Buffer);
    AddItem(Item);
  end;
end;
{ @end $45C300 }

{ @routine $45C344 TCodeAnalyzerEC_Create }
constructor TCodeAnalyzerEC.Create;
begin
  inherited Create;
end;
{ @end $45C344 }

{ @routine $45C37C TCodeAnalyzerEC_Destroy }
destructor TCodeAnalyzerEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $45C37C }

{ @routine $45C3A8 TCodeAnalyzerEC_Clear }
procedure TCodeAnalyzerEC.Clear;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    Previous.Free;
  end;
  First := nil;
  Last := nil;
  Token := FirstFree;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    Previous.Free;
  end;
  FirstFree := nil;
  LastFree := nil;
end;
{ @end $45C3A8 }

{ @routine $45C3F0 TCodeAnalyzerEC_ReserveTokens }
procedure TCodeAnalyzerEC.ReserveTokens(Count: Integer);
var
  Token: TCodeAnalyzerUnitEC;
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    Token := TCodeAnalyzerUnitEC.Create;
    if LastFree <> nil then LastFree.Next := Token;
    Token.Prev := LastFree;
    Token.Next := nil;
    LastFree := Token;
    if FirstFree = nil then FirstFree := Token;
  end;
end;
{ @end $45C3F0 }

{ @routine $45C430 TCodeAnalyzerEC_AcquireToken }
function TCodeAnalyzerEC.AcquireToken: TCodeAnalyzerUnitEC;
var
  Token: TCodeAnalyzerUnitEC;
begin
  if FirstFree = nil then ReserveTokens(64);
  Token := LastFree;
  if Token.Prev <> nil then Token.Prev.Next := Token.Next;
  if Token.Next <> nil then Token.Next.Prev := Token.Prev;
  if LastFree = Token then LastFree := Token.Prev;
  if FirstFree = Token then FirstFree := Token.Next;
  Result := Token;
end;
{ @end $45C430 }

{ @routine $45C47C TCodeAnalyzerEC_RecycleToken }
procedure TCodeAnalyzerEC.RecycleToken(Token: TCodeAnalyzerUnitEC);
begin
  if LastFree <> nil then LastFree.Next := Token;
  Token.Prev := LastFree;
  Token.Next := nil;
  LastFree := Token;
  if FirstFree = nil then FirstFree := Token;
end;
{ @end $45C47C }

{ @routine $45C4A0 TCodeAnalyzerEC_ClearTokens }
procedure TCodeAnalyzerEC.ClearTokens;
begin
  while First <> nil do DeleteToken(Last);
end;
{ @end $45C4A0 }

{ @routine $45C4B8 TCodeAnalyzerEC_AddToken }
function TCodeAnalyzerEC.AddToken: TCodeAnalyzerUnitEC;
var
  Token: TCodeAnalyzerUnitEC;
begin
  Token := AcquireToken;
  if Last <> nil then Last.Next := Token;
  Token.Prev := Last;
  Token.Next := nil;
  Last := Token;
  if First = nil then First := Token;
  Result := Token;
end;
{ @end $45C4B8 }

{ @routine $45C4E8 TCodeAnalyzerEC_DeleteToken }
procedure TCodeAnalyzerEC.DeleteToken(Token: TCodeAnalyzerUnitEC);
begin
  if Token.Prev <> nil then Token.Prev.Next := Token.Next;
  if Token.Next <> nil then Token.Next.Prev := Token.Prev;
  if Last = Token then Last := Token.Prev;
  if First = Token then First := Token.Next;
  RecycleToken(Token);
end;
{ @end $45C4E8 }

{ @routine $45C520 TCodeAnalyzerEC_AppendText }
procedure TCodeAnalyzerEC.AppendText(Text: WideString; SourceOffset, NewlineOffset: Integer);
var
  C: WideChar;
  Index: Integer;
  Token: TCodeAnalyzerUnitEC;
  TextLength, QuoteStart, RunStart, RunLength, HexValue, HexDigits: Integer;

begin
  TextLength := Length(Text);
  QuoteStart := -1;
  RunStart := -1;
  RunLength := 0;
  Index := 0;
  while Index < TextLength do
  begin
    C := Text[Index + 1];
    if QuoteStart = -1 then
    begin
      if (C = '(') then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctOpenParen;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = ')') then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctCloseParen;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '{' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctOpenBrace;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '}' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctCloseBrace;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '[' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctOpenBracket;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = ']' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctCloseBracket;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = '/') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '*') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBlockCommentStart;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '*') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '/') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBlockCommentEnd;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '/') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '/') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctLineComment;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if C = '.' then
      begin
        // The native tokenizer counts a dot as two source characters.
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctDot;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
      end
      else if (C = '-') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '>') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctArrow;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '&') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '&') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctAnd;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '|') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '|') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctOr;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if C = '+' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctAdd;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '-' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctSubtract;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '*' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctMultiply;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '/' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctDivide;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '%' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctModulo;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '&' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBitAnd;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '|' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBitOr;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '^' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBitXor;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '~' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctBitNot;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = '!') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctNotEqual;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if C = '!' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctNot;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = '<') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '<') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctShiftLeft;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '>') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '>') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctShiftRight;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '=') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctEqual;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if C = '=' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctAssign;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = '<') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctLessEqual;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if (C = '>') and (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '=') then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctGreaterEqual;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 2;
        end;
        Inc(Index);
      end
      else if C = '<' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctLess;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = '>' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctGreater;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = ';' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctSemicolon;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = ':' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctColon;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if C = ',' then
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctComma;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end
      else if (C = ' ') or (C = #9) then
      begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
        RunStart := -1;
        if (Last = nil) or ((Last <> nil) and (Last.TokenKind <> ctWhitespace)) then
        begin
          begin
          Token := AddToken;
          Token.TokenKind := ctWhitespace;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end;
        end
        else Inc(Last.SourceLength);
      end
      else if (C = #13) or (C = #10) then
      begin
        begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
          RunStart := -1;
          Token := AddToken;
          Token.TokenKind := ctNewline;
          Token.SourceStart := Index + SourceOffset;
          Token.SourceLength := 1;
        end;
        Inc(SourceOffset, NewlineOffset);
        if (Index + 1 < TextLength) and ((Text[(Index + 1) + 1] = #13) or
          (Text[(Index + 1) + 1] = #10)) then
        begin
          Inc(Index);
          Inc(Token.SourceLength);
        end;
      end
      // Either quote closes the native string, regardless of its opener.
      else if (C = '"') or (C = '''') then
      begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
            Inc(Last.SourceLength, RunLength);
          end;
        end;
        Token := AddToken;
        Token.TokenKind := ctStringLiteral;
        QuoteStart := Index;
        Last.SourceStart := Index + SourceOffset;
        Last.SourceLength := 2;
        Last.Text := '';
        RunStart := Index + 1;
        RunLength := 0;
      end
      else if C > ' ' then
      begin
        if (Last = nil) or (Last.TokenKind <> ctText) then
        begin
          Token := AddToken;
          Token.TokenKind := ctText;
          Last.SourceStart := Index + SourceOffset;
          Last.SourceLength := 0;
          Last.Text := '';
          RunStart := Index;
          RunLength := 1;
        end
        else Inc(RunLength);
      end;
    end
    else if Last.TokenKind = ctStringLiteral then
    begin
      Inc(RunLength);
      if C = '\' then
      begin
        if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '\') then
        begin
          begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
          Last.Text := Last.Text + C;
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '"') then
        begin
          begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
          Last.Text := Last.Text + '"';
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = '''') then
        begin
          begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
          Last.Text := Last.Text + '''';
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = 'n') then
        begin
          begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
          Last.Text := Last.Text + #13#10;
          Inc(Last.SourceLength, 2);
          Inc(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end
        else if (Index + 1 < TextLength) and (Text[(Index + 1) + 1] = 'x') then
        begin
          begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
          Inc(Last.SourceLength, 2);
          Inc(Index, 2);
          HexValue := 0;
          HexDigits := 0;
          while (Index < TextLength) and (HexDigits < 4) do
          begin
            C := Text[Index + 1];
            if (C >= '0') and (C <= '9') then HexValue := HexValue * 16 + Ord(C) - Ord('0')
            else if (C >= 'a') and (C <= 'f') then HexValue := HexValue * 16 + Ord(C) - Ord('a') + 10
            else if (C >= 'A') and (C <= 'F') then HexValue := HexValue * 16 + Ord(C) - Ord('A') + 10
            else Break;
            Inc(HexDigits);
            Inc(Last.SourceLength);
            Inc(Index);
          end;
          Last.Text := Last.Text + WideChar(HexValue);
          Dec(Index);
          RunStart := Index + 1;
          RunLength := 0;
        end;
      end
      // Either quote closes the native string, regardless of its opener.
      else if (C = '"') or (C = '''') then
      begin
        begin
          if (RunStart >= 0) and (RunLength > 0) then
          begin
            Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength - 1);
            Inc(Last.SourceLength, RunLength - 1);
          end;
        end;
        RunStart := -1;
        QuoteStart := -1;
      end;
    end;
    Inc(Index);
  end;
  if (RunStart >= 0) and (RunLength > 0) then
  begin
    Last.Text := Last.Text + Copy(Text, RunStart + 1, RunLength);
  end;
end;
{ @end $45C520 }

{ @routine $45DA38 TCodeAnalyzerEC_Tokenize }
procedure TCodeAnalyzerEC.Tokenize(Text: WideString; NewlineOffset: Integer);
begin
  ClearTokens;
  AppendText(Text, 0, NewlineOffset);
end;
{ @end $45DA38 }

{ @routine $45DABC TCodeAnalyzerEC_ValidateDelimiters }
function TCodeAnalyzerEC.ValidateDelimiters: WideString;
var
  Depth, OpenCount, CloseCount: Integer;
  Token: TCodeAnalyzerUnitEC;
  Stack: array of Byte;
begin
  Result := '';
  OpenCount := 0;
  CloseCount := 0;
  Token := First;
  while Token <> nil do
  begin
    if (Token.TokenKind = ctOpenParen) or (Token.TokenKind = ctOpenBrace) or
      (Token.TokenKind = ctOpenBracket) or (Token.TokenKind = ctBlockCommentStart) then Inc(OpenCount);
    if (Token.TokenKind = ctCloseParen) or (Token.TokenKind = ctCloseBrace) or
      (Token.TokenKind = ctCloseBracket) or (Token.TokenKind = ctBlockCommentEnd) then Inc(CloseCount);
    Token := Token.Next;
  end;
  if OpenCount <> CloseCount then
  begin
    Token := Last;
    Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
    Exit;
  end;
  if OpenCount < 1 then Exit;
  SetLength(Stack, OpenCount);
  try
    Depth := 0;
    Token := First;
    while Token <> nil do
    begin
      if Token.TokenKind = ctOpenParen then
      begin
        Stack[Depth] := 1;
        Inc(Depth);
      end
      else if Token.TokenKind = ctOpenBrace then
      begin
        Stack[Depth] := 2;
        Inc(Depth);
      end
      else if Token.TokenKind = ctOpenBracket then
      begin
        Stack[Depth] := 3;
        Inc(Depth);
      end
      else if Token.TokenKind = ctBlockCommentStart then
      begin
        Stack[Depth] := 4;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseParen then
      begin
        // Native checks total openings here, not the current stack depth.
        if (OpenCount < 1) or (Stack[Depth - 1] <> 1) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctCloseBrace then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 2) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctCloseBracket then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 3) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end
      else if Token.TokenKind = ctBlockCommentEnd then
      begin
        if (OpenCount < 1) or (Stack[Depth - 1] <> 4) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Stack := nil;
          Exit;
        end;
        Dec(Depth);
      end;
      Token := Token.Next;
    end;
    if Depth > 0 then
    begin
      Token := Last;
      Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
      Stack := nil;
      Exit;
    end;
  except
    Stack := nil;
    raise;
  end;
  Stack := nil;
end;
{ @end $45DABC }

{ @routine $45DD54 TCodeAnalyzerEC_RemoveWhitespace }
procedure TCodeAnalyzerEC.RemoveWhitespace;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if Previous.TokenKind = ctWhitespace then DeleteToken(Previous);
  end;
end;
{ @end $45DD54 }

{ @routine $45DD7C TCodeAnalyzerEC_RemoveNewlines }
procedure TCodeAnalyzerEC.RemoveNewlines;
var
  Token, Previous: TCodeAnalyzerUnitEC;
begin
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if Previous.TokenKind = ctNewline then DeleteToken(Previous);
  end;
end;
{ @end $45DD7C }

{ @routine $45DDA4 TCodeAnalyzerEC_RemoveComments }
procedure TCodeAnalyzerEC.RemoveComments;
var
  Token, Previous: TCodeAnalyzerUnitEC;
  LineComment: Boolean;
  CommentDepth: Integer;
begin
  LineComment := False;
  CommentDepth := 0;
  Token := First;
  while Token <> nil do
  begin
    Previous := Token;
    Token := Token.Next;
    if not LineComment and (CommentDepth = 0) then
    begin
      if Previous.TokenKind = ctBlockCommentStart then
      begin
        CommentDepth := 1;
        DeleteToken(Previous);
      end
      else if Previous.TokenKind = ctLineComment then
      begin
        LineComment := True;
        DeleteToken(Previous);
      end;
    end
    else
    begin
      if (CommentDepth <> 0) and (Previous.TokenKind = ctBlockCommentStart) then Inc(CommentDepth)
      else if LineComment and (Previous.TokenKind = ctNewline) then LineComment := False
      else if (CommentDepth <> 0) and (Previous.TokenKind = ctBlockCommentEnd) then Dec(CommentDepth);
      DeleteToken(Previous);
    end;
  end;
end;
{ @end $45DDA4 }

{ @routine $45DE24 TExpressionInstrEC_Destroy }
destructor TExpressionInstrEC.Destroy;
begin
  Operands := nil;
  inherited Destroy;
end;
{ @end $45DE24 }

{ @routine $45DE58 InitInstr }
procedure InitInstr(Instruction: TExpressionInstrEC; Token: TCodeTokenKind);
begin
  if Token = ctAdd then Instruction.Opcode := eoAdd
  else if Token = ctSubtract then Instruction.Opcode := eoSubtract
  else if Token = ctMultiply then Instruction.Opcode := eoMultiply
  else if Token = ctDivide then Instruction.Opcode := eoDivide
  else if Token = ctModulo then Instruction.Opcode := eoModulo
  else if Token = ctBitAnd then Instruction.Opcode := eoBitAnd
  else if Token = ctBitOr then Instruction.Opcode := eoBitOr
  else if Token = ctBitXor then Instruction.Opcode := eoBitXor
  else if Token = ctBitNot then Instruction.Opcode := eoBitNot
  else if Token = ctAnd then Instruction.Opcode := eoAnd
  else if Token = ctOr then Instruction.Opcode := eoOr
  else if Token = ctNot then Instruction.Opcode := eoNot
  else if Token = ctShiftLeft then Instruction.Opcode := eoShiftLeft
  else if Token = ctShiftRight then Instruction.Opcode := eoShiftRight
  else if Token = ctEqual then Instruction.Opcode := eoEqual
  else if Token = ctNotEqual then Instruction.Opcode := eoNotEqual
  else if Token = ctLess then Instruction.Opcode := eoLess
  else if Token = ctGreater then Instruction.Opcode := eoGreater
  else if Token = ctLessEqual then Instruction.Opcode := eoLessEqual
  else if Token = ctGreaterEqual then Instruction.Opcode := eoGreaterEqual
  else raise ExceptionExpressionEC.Create('InitInstr');
end;
{ @end $45DE58 }

{ @routine $45DF7C TExpressionInstrEC_CopyFrom }
procedure TExpressionInstrEC.CopyFrom(Source: TExpressionInstrEC);
var i: Integer;
begin
  Opcode := Source.Opcode;
  OperandCount := Source.OperandCount;
  Operands := nil;
  if Source.Operands <> nil then
  begin
    SetLength(Operands, OperandCount);
    for i := 0 to OperandCount - 1 do Operands[i] := Source.Operands[i];
  end;
end;
{ @end $45DF7C }

{ @routine $45DFDC TExpressionVarEC_Destroy }
destructor TExpressionVarEC.Destroy;
begin
  if Kind = evOwned then Value.Free;
  Value := nil;
  MemberPath := nil;
  inherited Destroy;
end;
{ @end $45DFDC }

{ @routine $45E024 TExpressionVarEC_CopyFrom }
procedure TExpressionVarEC.CopyFrom(Source: TExpressionVarEC);
var i, Count: Integer;
begin
  Name := Source.Name;
  Kind := Source.Kind;
  Value := nil;
  if Kind = evNamed then Value := Source.Value
  else if (Kind = evOwned) and (Source.Value <> nil) then
  begin
    Value := TVarEC.Create(vkEmpty);
    Value.AssignFrom(Source.Value);
  end;
  if Source.MemberPath <> nil then
  begin
    Count := High(Source.MemberPath) + 1;
    SetLength(MemberPath, Count);
    for i := 0 to Count - 1 do MemberPath[i] := Source.MemberPath[i];
  end;
end;
{ @end $45E024 }

{ @routine $45E0C8 TExpressionVarEC_SplitMemberPath }
function TExpressionVarEC.SplitMemberPath: Boolean;
var
  Start, Stop, Count, i, Parts: Integer;
  Text: WideString;
begin
  Result := True;
  Text := Name;
  Count := Length(Text);
  Start := 0;
  Stop := Start;
  while Stop < Count do
  begin
    if Text[Stop + 1] = '.' then Break;
    Inc(Stop);
  end;
  if Stop >= Count then Exit;
  Name := Copy(Text, Start + 1, Stop - Start);
  Parts := 1;
  for i := Stop + 1 to Count - 1 do
    if Text[i + 1] = '.' then Inc(Parts);
  SetLength(MemberPath, Parts);
  i := 0;
  while Stop + 1 < Count do
  begin
    Start := Stop + 1;
    Stop := Start;
    while Stop < Count do
    begin
      if Text[Stop + 1] = '.' then Break;
      Inc(Stop);
    end;
    MemberPath[i] := Copy(Text, Start + 1, Stop - Start);
    Inc(i);
  end;
  Result := True;
end;
{ @end $45E0C8 }

{ @routine $45E1EC TExpressionVarEC_GetFullName }
function TExpressionVarEC.GetFullName: WideString;
var i: Integer;
begin
  Result := Name;
  if MemberPath <> nil then
    for i := 0 to High(MemberPath) do Result := Result + '.' + MemberPath[i];
end;
{ @end $45E1EC }

{ @routine $45E240 TExpressionVarEC_Resolve }
function TExpressionVarEC.Resolve(InitialKind: TVarKind): TVarEC;
var i: Integer;
begin
  if Value <> nil then
  begin
    if MemberPath = nil then Result := Value
    else
    begin
      Result := Value;
      i := 0;
      while i <= High(MemberPath) do
      begin
        if Result.RealVType = vkClass then Result := Result.GetClass.FindVar(MemberPath[i])
        else if Result.RealVType = vkFunction then Result := Result.GetFunction.FindVar(MemberPath[i])
        else raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
        if Result = nil then raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
        Inc(i);
      end;
    end;
  end
  else
  begin
    if Kind = evOwned then Value := TVarEC.Create(InitialKind)
    else raise ExceptionExpressionEC.Create('Not link var :' + GetFullName);
    Result := Value;
  end;
end;
{ @end $45E240 }

{ @routine $45E428 TExpressionEC_Create }
constructor TExpressionEC.Create;
begin
  inherited Create;
end;
{ @end $45E428 }

{ @routine $45E460 TExpressionEC_Destroy }
destructor TExpressionEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $45E460 }

{ @routine $45E48C TExpressionEC_Clear }
procedure TExpressionEC.Clear;
begin
  while VariableCount > 0 do DeleteVariable(VariableCount - 1);
  if not SharedInstructions then
    while InstructionCount > 0 do DeleteInstruction(InstructionCount - 1);
  ResultIndex := -1;
  SharedInstructions := False;
end;
{ @end $45E48C }

{ @routine $45E4C8 TExpressionEC_CopyFrom }
procedure TExpressionEC.CopyFrom(Source: TExpressionEC);
var i: Integer;
begin
  Clear;
  for i := 0 to Source.VariableCount - 1 do GetVariable(AddVariable).CopyFrom(Source.GetVariable(i));
  for i := 0 to Source.InstructionCount - 1 do GetInstruction(AddInstruction).CopyFrom(Source.GetInstruction(i));
  ResultIndex := Source.ResultIndex;
end;
{ @end $45E4C8 }

{ @routine $45E544 TExpressionEC_CopyFromFast }
procedure TExpressionEC.CopyFromFast(Source: TExpressionEC);
var i: Integer;
begin
  Clear;
  for i := 0 to Source.VariableCount - 1 do GetVariable(AddVariable).CopyFrom(Source.GetVariable(i));
  InstructionCount := Source.InstructionCount;
  Instructions := Source.Instructions;
  SharedInstructions := True;
  ResultIndex := Source.ResultIndex;
end;
{ @end $45E544 }

{ @routine $45E5A0 TExpressionEC_AddVariable }
function TExpressionEC.AddVariable: Integer;
begin
  Inc(VariableCount);
  if Variables = nil then Variables := HeapAlloc(GetProcessHeap, 0, VariableCount * SizeOf(TExpressionVarEC))
  else Variables := HeapReAlloc(GetProcessHeap, 0, Variables, VariableCount * SizeOf(TExpressionVarEC));
  SetVariable(VariableCount - 1, TExpressionVarEC.Create);
  Result := VariableCount - 1;
end;
{ @end $45E5A0 }

{ @routine $45E604 TExpressionEC_DeleteVariable }
procedure TExpressionEC.DeleteVariable(Index: Integer);
var i: Integer;
begin
  if (Index < 0) or (Index >= VariableCount) then Exit;
  GetVariable(Index).Free;
  for i := Index to VariableCount - 2 do SetVariable(i, GetVariable(i + 1));
  Dec(VariableCount);
  if VariableCount <= 0 then
  begin
    HeapFree(GetProcessHeap, 0, Variables);
    Variables := nil;
  end;
end;
{ @end $45E604 }

{ @routine $45E670 TExpressionEC_GetVariable }
function TExpressionEC.GetVariable(Index: Integer): TExpressionVarEC; cdecl;
asm
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TExpressionEC.Variables
  MOV EAX, [EAX]
  POP EBX
end;
{ @end $45E670 }

{ @routine $45E688 TExpressionEC_SetVariable }
procedure TExpressionEC.SetVariable(Index: Integer; Value: TExpressionVarEC); cdecl;
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TExpressionEC.Variables
  MOV EBX, Value
  MOV [EAX], EBX
  POP EBX
  POP EAX
end;
{ @end $45E688 }

{ @routine $45E6A4 TExpressionEC_AddInstruction }
function TExpressionEC.AddInstruction: Integer;
begin
  Inc(InstructionCount);
  if Instructions = nil then Instructions := HeapAlloc(GetProcessHeap, 0, InstructionCount * SizeOf(TExpressionInstrEC))
  else Instructions := HeapReAlloc(GetProcessHeap, 0, Instructions, InstructionCount * SizeOf(TExpressionInstrEC));
  SetInstruction(InstructionCount - 1, TExpressionInstrEC.Create);
  Result := InstructionCount - 1;
end;
{ @end $45E6A4 }

{ @routine $45E708 TExpressionEC_DeleteInstruction }
procedure TExpressionEC.DeleteInstruction(Index: Integer);
var i: Integer;
begin
  if (Index < 0) or (Index >= InstructionCount) then Exit;
  GetInstruction(Index).Free;
  for i := Index to InstructionCount - 2 do SetInstruction(i, GetInstruction(i + 1));
  Dec(InstructionCount);
  if InstructionCount <= 0 then
  begin
    HeapFree(GetProcessHeap, 0, Instructions);
    Instructions := nil;
  end;
end;
{ @end $45E708 }

{ @routine $45E774 TExpressionEC_GetInstruction }
function TExpressionEC.GetInstruction(Index: Integer): TExpressionInstrEC; cdecl;
asm
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TExpressionEC.Instructions
  MOV EAX, [EAX]
  POP EBX
end;
{ @end $45E774 }

{ @routine $45E78C TExpressionEC_SetInstruction }
procedure TExpressionEC.SetInstruction(Index: Integer; Value: TExpressionInstrEC); cdecl;
asm
  PUSH EAX
  PUSH EBX
  MOV EBX, Self
  MOV EAX, Index
  SHL EAX, 2
  ADD EAX, [EBX].TExpressionEC.Instructions
  MOV EBX, Value
  MOV [EAX], EBX
  POP EBX
  POP EAX
end;
{ @end $45E78C }

{ @routine $45E7A8 TExpressionEC_Compile }
function TExpressionEC.Compile(Analyzer: TCodeAnalyzerEC; CompilationContext: Pointer; FirstToken, EndToken: TCodeAnalyzerUnitEC; NextToken: PCodeAnalyzerUnitEC): WideString;
var
  Token, Next: TCodeAnalyzerUnitEC;
  Compiler: TCompilerEC;
  Item, Reduced, Closing: TCompilerUnitEC;
  ResultSlot, Depth, ArgumentCount, OperandIndex: Integer;
  Slot: TExpressionVarEC;
  Instruction: TExpressionInstrEC;
  IntValue: Integer;
  DwordValue: Dword;
  FloatValue: Double;
  Text: WideString;
begin
  Clear;
  Result := '';
  if FirstToken = nil then FirstToken := Analyzer.First;
  if FirstToken = nil then
  begin
    Result := FormatScriptError(0, 0);
    Exit;
  end;
  Compiler := TCompilerEC.Create;
  Depth := 0;
  Token := FirstToken;
  while Token <> EndToken do
  begin
    if (Token.TokenKind <> ctBlockCommentStart) and (Token.TokenKind <> ctLineComment) then
    begin
      if Token.TokenKind = ctStringLiteral then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuStringLiteral;
        Item.Text := Token.Text;
      end
      else if Token.TokenKind = ctComma then
      begin
        if Depth <= 0 then Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuComma;
      end
      else if Token.TokenKind = ctAssign then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuAssignment;
      end
      else if Token.TokenKind = ctOpenParen then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuOpenParen;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseParen then
      begin
        Dec(Depth);
        if Depth < 0 then Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuCloseParen;
      end
      else if Token.TokenKind = ctOpenBracket then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuOpenBracket;
        Inc(Depth);
      end
      else if Token.TokenKind = ctCloseBracket then
      begin
        Dec(Depth);
        if Depth < 0 then Break;
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuCloseBracket;
      end
      else if Token.TokenKind = ctAssign then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuAssignment;
      end
      else if (Token.TokenKind = ctBitNot) or (Token.TokenKind = ctNot) then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuUnaryOperator;
        Item.OperatorToken := Token.TokenKind;
      end
      else if ((Token.TokenKind = ctAdd) or (Token.TokenKind = ctSubtract) or (Token.TokenKind = ctMultiply)
    or (Token.TokenKind = ctDivide) or (Token.TokenKind = ctModulo) or (Token.TokenKind = ctSubtract)
    or (Token.TokenKind = ctBitAnd) or (Token.TokenKind = ctBitOr) or (Token.TokenKind = ctBitXor)
    or (Token.TokenKind = ctAnd) or (Token.TokenKind = ctOr) or (Token.TokenKind = ctShiftLeft)
    or (Token.TokenKind = ctShiftRight) or (Token.TokenKind = ctEqual) or (Token.TokenKind = ctNotEqual)
    or (Token.TokenKind = ctLess) or (Token.TokenKind = ctGreater) or (Token.TokenKind = ctLessEqual)
    or (Token.TokenKind = ctGreaterEqual)) then
      begin
        Item := Compiler.AddUnit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.SourceLength;
        Item.Kind := cuBinaryOperator;
        Item.OperatorToken := Token.TokenKind;
      end
      else if Token.TokenKind = ctText then
      begin
        Next := Token;
        if TryReadFloatLiteral(Next, FloatValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then Item.SourceLength := Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuFloatLiteral;
          Item.FloatValue := FloatValue;
          Token := Next;
          Continue;
        end
        else if TryReadDwordLiteral(Next, DwordValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then Item.SourceLength := Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuDwordLiteral;
          Item.DwordValue := DwordValue;
          Token := Next;
          Continue;
        end
        else if TryReadIntegerLiteral(Next, IntValue) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then Item.SourceLength := Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuIntLiteral;
          Item.IntValue := IntValue;
          Token := Next;
          Continue;
        end
        else if TryReadStringLiteral(Next, Text) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then Item.SourceLength := Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuStringLiteral;
          Item.Text := Text;
          Token := Next;
          Continue;
        end
        else if TryReadMemberName(Next, Text) then
        begin
          Item := Compiler.AddUnit;
          Item.SourceStart := Token.SourceStart;
          if Next = nil then Item.SourceLength := Analyzer.Last.SourceStart + Analyzer.Last.SourceLength - Token.SourceStart
          else Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Token.SourceStart;
          Item.Kind := cuName;
          Item.Text := Text;
          Token := Next;
          Continue;
        end
        else
        begin
          begin Result := FormatScriptError(0, Token.SourceStart); Compiler.Free; end;
          Exit;
        end;
      end
      else
      begin
        if Token.TokenKind = ctSemicolon then Break;
        if (Token.TokenKind <> ctNewline) and (Token.TokenKind <> ctWhitespace) then
        begin
          begin Result := FormatScriptError(0, Token.SourceStart); Compiler.Free; end;
          Exit;
        end;
      end;
    end;
    Token := Token.Next;
  end;
  if NextToken <> nil then NextToken^ := Token;
  Depth := 0;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if (Item.Kind = cuOpenParen) and (Item.Prev <> nil) and (Item.Prev.Kind = cuName) then
    begin
      Item.Kind := cuCall;
      Item.Text := Item.Prev.Text;
      Compiler.DeleteUnit(Item.Prev);
      Inc(Depth);
    end
    else if Item.Kind = cuOpenBracket then
    begin
      if (Item.Prev <> nil) and (Item.Prev.Kind = cuName) then
      begin
        Item.Kind := cuIndex;
        Item.Text := Item.Prev.Text;
        Compiler.DeleteUnit(Item.Prev);
        Inc(Depth);
      end
      else
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end
    else if Item.Kind = cuOpenParen then Inc(Depth)
    else if Item.Kind = cuCloseParen then Dec(Depth)
    else if Item.Kind = cuCloseBracket then Dec(Depth);
    Item := Item.Next;
  end;
  if Depth <> 0 then
  begin
    if Token = nil then Token := Analyzer.Last;
    begin Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength); Compiler.Free; end;
    Exit;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if (Item.Kind = cuBinaryOperator) and (Item.OperatorToken = ctSubtract) and
      (Item.Next <> nil) and ((Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuFloatLiteral)) then
    begin
      if ((Item.Prev = nil) or ((Item.Prev.Kind <> cuIntLiteral) and (Item.Prev.Kind <> cuDwordLiteral) and
    (Item.Prev.Kind <> cuFloatLiteral) and (Item.Prev.Kind <> cuCloseParen) and
    (Item.Prev.Kind <> cuCloseBracket) and (Item.Prev.Kind <> cuName))) then
      begin
        Item := Item.Next;
        Compiler.DeleteUnit(Item.Prev);
        Item.IntValue := -Item.IntValue;
        Item.FloatValue := -Item.FloatValue;
      end;
    end
    else if (Item.Kind = cuBinaryOperator) and (Item.OperatorToken = ctSubtract) and
      (Item.Next <> nil) and ((Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuDwordLiteral) or
      (Item.Next.Kind = cuFloatLiteral) or (Item.Next.Kind = cuOpenParen) or (Item.Next.Kind = cuCall) or
      (Item.Next.Kind = cuIndex) or (Item.Next.Kind = cuName)) then
    begin
      if ((Item.Prev = nil) or ((Item.Prev.Kind <> cuIntLiteral) and (Item.Prev.Kind <> cuDwordLiteral) and
    (Item.Prev.Kind <> cuFloatLiteral) and (Item.Prev.Kind <> cuCloseParen) and
    (Item.Prev.Kind <> cuCloseBracket) and (Item.Prev.Kind <> cuName))) then Item.Kind := cuUnaryOperator;
    end;
    Item := Item.Next;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if Item.Kind = cuBinaryOperator then
    begin
      if ((Item.Prev = nil) or (Item.Next = nil) or
    not ((Item.Prev.Kind = cuName) or (Item.Prev.Kind = cuIntLiteral) or (Item.Prev.Kind = cuDwordLiteral)
      or (Item.Prev.Kind = cuFloatLiteral) or (Item.Prev.Kind = cuStringLiteral)
      or (Item.Prev.Kind = cuCloseParen) or (Item.Prev.Kind = cuCloseBracket)) or
    not ((Item.Next.Kind = cuName) or (Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuDwordLiteral)
      or (Item.Next.Kind = cuFloatLiteral) or (Item.Next.Kind = cuStringLiteral) or (Item.Next.Kind = cuOpenParen)
      or (Item.Next.Kind = cuCall) or (Item.Next.Kind = cuIndex) or (Item.Next.Kind = cuUnaryOperator))) then
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end
    else if Item.Kind = cuAssignment then
    begin
      if ((Item.Prev = nil) or (Item.Next = nil) or
    not ((Item.Prev.Kind = cuName) or (Item.Prev.Kind = cuCloseBracket)) or
    not ((Item.Next.Kind = cuName) or (Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuDwordLiteral)
      or (Item.Next.Kind = cuFloatLiteral) or (Item.Next.Kind = cuStringLiteral) or (Item.Next.Kind = cuOpenParen)
      or (Item.Next.Kind = cuCall) or (Item.Next.Kind = cuIndex) or (Item.Next.Kind = cuUnaryOperator))) then
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end
    else if Item.Kind = cuUnaryOperator then
    begin
      if (Item.Next = nil) or
    not ((Item.Next.Kind = cuName) or (Item.Next.Kind = cuIntLiteral) or (Item.Next.Kind = cuDwordLiteral)
      or (Item.Next.Kind = cuFloatLiteral) or (Item.Next.Kind = cuStringLiteral) or (Item.Next.Kind = cuOpenParen)
      or (Item.Next.Kind = cuCall) or (Item.Next.Kind = cuIndex) or (Item.Next.Kind = cuUnaryOperator)) then
    begin
      begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
      Exit;
    end;
    end;
    Item := Item.Next;
  end;
  Item := Compiler.First;
  while Item <> nil do
  begin
    if Item.Kind = cuIntLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkInt);
      Slot.Value.SetInt(Item.IntValue);
    end
    else if Item.Kind = cuDwordLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkDword);
      Slot.Value.SetDword(Item.DwordValue);
    end
    else if Item.Kind = cuFloatLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkFloat);
      Slot.Value.SetFloat(Item.FloatValue);
    end
    else if Item.Kind = cuStringLiteral then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evOwned;
      Slot.Value := TVarEC.Create(vkString);
      Slot.Value.SetString(Item.Text);
    end
    else if Item.Kind = cuName then
    begin
      Item.Kind := cuVariable;
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end
    else if Item.Kind = cuCall then
    begin
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end
    else if Item.Kind = cuIndex then
    begin
      Item.VariableIndex := AddVariable;
      Slot := GetVariable(Item.VariableIndex);
      Slot.Kind := evNamed;
      Slot.Name := Item.Text;
      if not Slot.SplitMemberPath then
      begin
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
      end;
    end;
    Item := Item.Next;
  end;
  if Compiler.First = nil then
  begin
    begin Result := FormatScriptError(0, 0); Compiler.Free; end;
    Exit;
  end;
  while Compiler.First.Next <> nil do
  begin
    Item := Compiler.FindReducibleIndex;
    if Item = nil then Item := Compiler.FindReducibleCall;
    if Item = nil then Item := Compiler.FindReducibleOperator;
    if Item = nil then
    begin
      Clear;
      if Compiler.First = nil then Result := 'Unknown error'
      else Result := FormatScriptError(0, Compiler.First.SourceStart);
      Compiler.Free;
      Exit;
      raise ExceptionExpressionEC.Create('Unknown error');
    end;
    if (Item.Kind = cuCall) or (Item.Kind = cuIndex) then
    begin
      ArgumentCount := 0;
      Closing := Item.Next;
      while Closing <> nil do
      begin
        if Closing.Kind = cuVariable then Inc(ArgumentCount)
        else if (Closing.Kind = cuCloseParen) or (Closing.Kind = cuCloseBracket) then Break;
        Closing := Closing.Next;
      end;
      if (Item.Kind = cuIndex) and (ArgumentCount < 1) then
      begin
        Clear;
        begin Result := FormatScriptError(0, Item.SourceStart); Compiler.Free; end;
        Exit;
        raise ExceptionExpressionEC.Create('Unknown error');
      end;
      ResultSlot := AddVariable;
      if Item.Kind = cuCall then GetVariable(ResultSlot).Kind := evOwned
      else GetVariable(ResultSlot).Kind := evIndexed;
      Instruction := GetInstruction(AddInstruction);
      if Item.Kind = cuCall then Instruction.Opcode := eoCall
      else Instruction.Opcode := eoIndex;
      Instruction.OperandCount := ArgumentCount + 2;
      SetLength(Instruction.Operands, ArgumentCount + 2);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.VariableIndex;
      OperandIndex := 2;
      Reduced := Item.Next;
      while Reduced <> nil do
      begin
        if Reduced.Kind = cuVariable then
        begin
          Instruction.Operands[OperandIndex] := Reduced.VariableIndex;
          Inc(OperandIndex);
        end
        else if (Reduced.Kind = cuCloseParen) or (Reduced.Kind = cuCloseBracket) then Break;
        Reduced := Reduced.Next;
      end;
      Item.Kind := cuVariable;
      Item.Text := '';
      Item.VariableIndex := ResultSlot;
      Reduced := Item;
      while Closing <> Reduced do
      begin
        Item := Closing;
        Closing := Closing.Prev;
        Compiler.DeleteUnit(Item);
      end;
    end
    else if Item.Kind = cuUnaryOperator then
    begin
      ResultSlot := AddVariable;
      GetVariable(ResultSlot).Kind := evOwned;
      Instruction := GetInstruction(AddInstruction);
      if Item.OperatorToken = ctSubtract then Instruction.Opcode := eoNegate
      else InitInstr(Instruction, Item.OperatorToken);
      Instruction.OperandCount := 2;
      SetLength(Instruction.Operands, 2);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.Next.VariableIndex;
      Item.Next.VariableIndex := ResultSlot;
      Reduced := Item.Next;
      Compiler.DeleteUnit(Item);
    end
    else if Item.Kind = cuAssignment then
    begin
      Instruction := GetInstruction(AddInstruction);
      Instruction.Opcode := eoAssign;
      Instruction.OperandCount := 2;
      SetLength(Instruction.Operands, 2);
      Instruction.Operands[0] := Item.Prev.VariableIndex;
      Instruction.Operands[1] := Item.Next.VariableIndex;
      Reduced := Item.Prev;
      Compiler.DeleteUnit(Item.Next);
      Compiler.DeleteUnit(Item);
    end
    else
    begin
      ResultSlot := AddVariable;
      GetVariable(ResultSlot).Kind := evOwned;
      Instruction := GetInstruction(AddInstruction);
      InitInstr(Instruction, Item.OperatorToken);
      Instruction.OperandCount := 3;
      SetLength(Instruction.Operands, 3);
      Instruction.Operands[0] := ResultSlot;
      Instruction.Operands[1] := Item.Prev.VariableIndex;
      Instruction.Operands[2] := Item.Next.VariableIndex;
      Item.Prev.VariableIndex := ResultSlot;
      Reduced := Item.Prev;
      Compiler.DeleteUnit(Item.Next);
      Compiler.DeleteUnit(Item);
    end;
    while (Reduced <> nil) and (Reduced.Prev <> nil) and (Reduced.Prev.Kind = cuOpenParen) and
      (Reduced.Next <> nil) and (Reduced.Next.Kind = cuCloseParen) do
    begin
      Compiler.DeleteUnit(Reduced.Prev);
      Compiler.DeleteUnit(Reduced.Next);
    end;
  end;
  ResultIndex := Compiler.First.VariableIndex;
  Compiler.Free;
end;
{ @end $45E7A8 }

{ @routine $45F70C TExpressionEC_Link }
procedure TExpressionEC.Link(Scope: TVarArrayEC);
var
  i: Integer;
  Slot: TExpressionVarEC;
  Found: TVarEC;
begin
  for i := 0 to VariableCount - 1 do
  begin
    Slot := GetVariable(i);
      if Slot.Kind = evNamed then
      begin
        Found := Scope.GetVarNE(Slot.Name);
        if Found <> nil then Slot.Value := Found;
      end;
  end;
end;
{ @end $45F70C }

{ @routine $45F778 TExpressionEC_Evaluate }
procedure TExpressionEC.Evaluate(Process: TCodeProcessEC; Code: TCodeEC; DebugContext: TScriptDebugState);
var
  LibraryWord: Dword;
  i, j: Integer;
  Instruction: TExpressionInstrEC;
  Dest, Left, Right: TExpressionVarEC;
  Arguments: array of TVarEC;
  Value, IndexValue, Callee, Argument: TVarEC;
  Invocation: TCodeEC;
  ResultKind: TVarKind;
begin
  i := 0;
  while i < VariableCount do
  begin
    Dest := GetVariable(i);
    if Dest.Kind = evIndexed then Dest.Value := nil;
    Inc(i);
  end;
  i := 0;
  while i < InstructionCount do
  begin
    Instruction := GetInstruction(i);
    if (Instruction.Opcode = eoNegate) or (Instruction.Opcode = eoBitNot) or
      (Instruction.Opcode = eoNot) then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      case Instruction.Opcode of
        eoNegate: Dest.Resolve(Left.Value.RealVType).OMinus(Left.Resolve(vkEmpty));
        eoBitNot: Dest.Resolve(Left.Value.RealVType).OBitNot(Left.Resolve(vkEmpty));
        eoNot: Dest.Resolve(Left.Value.RealVType).ONot(Left.Resolve(vkEmpty));
      end;
    end
    else if (Instruction.Opcode <> eoCall) and (Instruction.Opcode <> eoAssign) and
      (Instruction.Opcode <> eoIndex) then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Right := GetVariable(Instruction.Operands[2]);
      ResultKind := vkEmpty;
      if (Dest.Value = nil) and (Dest.Kind = evOwned) then
      begin
        if (Instruction.Opcode = eoAdd) or (Instruction.Opcode = eoSubtract) or
          (Instruction.Opcode = eoMultiply) or (Instruction.Opcode = eoDivide) then
          ResultKind := Left.Resolve(vkEmpty).RealVType
        else ResultKind := vkInt;
      end;
      case Instruction.Opcode of
        eoAdd: Dest.Resolve(ResultKind).OAdd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoSubtract: Dest.Resolve(ResultKind).OSub(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoMultiply: Dest.Resolve(ResultKind).OMul(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoDivide: Dest.Resolve(ResultKind).ODiv(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoModulo: Dest.Resolve(ResultKind).OMod(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitAnd: Dest.Resolve(ResultKind).OBitAnd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitOr: Dest.Resolve(ResultKind).OBitOr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoBitXor: Dest.Resolve(ResultKind).OBitXor(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoAnd: Dest.Resolve(ResultKind).OAnd(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoOr: Dest.Resolve(ResultKind).OOr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoShiftLeft: Dest.Resolve(ResultKind).OShl(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoShiftRight: Dest.Resolve(ResultKind).OShr(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoEqual: Dest.Resolve(ResultKind).OEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoNotEqual: Dest.Resolve(ResultKind).ONotEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoLess: Dest.Resolve(ResultKind).OLess(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoGreater: Dest.Resolve(ResultKind).OMore(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoLessEqual: Dest.Resolve(ResultKind).OLessEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
        eoGreaterEqual: Dest.Resolve(ResultKind).OMoreEqual(Left.Resolve(vkEmpty), Right.Resolve(vkEmpty));
      end;
    end
    else if Instruction.Opcode = eoAssign then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Dest.Resolve(vkEmpty).Assume(Left.Resolve(vkEmpty));
    end
    else if Instruction.Opcode = eoIndex then
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Value := Left.Resolve(vkEmpty);
      if Value.RealVType <> vkArray then
        raise ExceptionExpressionEC.Create('Not array:' + Left.Name);
      for j := 2 to Instruction.OperandCount - 1 do
      begin
        Right := GetVariable(Instruction.Operands[j]);
        IndexValue := Right.Resolve(vkEmpty);
        if IndexValue.RealVType = vkString then
        begin
          Value := Value.GetArray.GetVarNE(IndexValue.GetString);
          if Value = nil then
            raise ExceptionExpressionEC.Create('Error array. index=' + Right.Value.GetString);
        end
        else
        begin
          Value := Value.GetArray.GetItemNE(IndexValue.GetInt);
          if Value = nil then
            raise ExceptionExpressionEC.Create('Error array. index=' + IntToStr(Right.Value.GetInt));
        end;
        if (j <> Instruction.OperandCount - 1) and (Value.RealVType <> vkArray) then
          raise ExceptionExpressionEC.Create('Error array:' + Left.Name);
      end;
      Dest.Value := Value;
    end
    else
    begin
      Dest := GetVariable(Instruction.Operands[0]);
      Left := GetVariable(Instruction.Operands[1]);
      Dest.Resolve(vkEmpty);
      Callee := Left.Resolve(vkEmpty);
      if Callee.RealVType = vkLibraryFun then
      begin
        Value := Callee.Resolve;
        if High(Value.LibraryFunData) + 1 - 2 <> Instruction.OperandCount - 2 then
          raise ExceptionExpressionEC.Create('Count variable : ' + Left.Name);
        for j := Instruction.OperandCount - 2 - 1 downto 0 do
        begin
          Argument := GetVariable(Instruction.Operands[j + 2]).Resolve(vkEmpty);
          case TLibraryValueKind(Value.LibraryFunData[2 + j]) of
            lvInt: LibraryWord := Argument.GetInt;
            lvDword: LibraryWord := Argument.GetDword;
            lvString:
              begin
                IndexValue := Argument.Resolve;
                if IndexValue.Kind <> vkString then
                  raise ExceptionExpressionEC.Create('Variable not string');
                if Length(IndexValue.StringValue) <= 0 then LibraryWord := 0
                else LibraryWord := Dword(PWideChar(IndexValue.StringValue));
              end;
          else
            LibraryWord := 0;
          end;
          // The imported function consumes its dynamically constructed argument stack.
          asm
            push LibraryWord
          end;
        end;
        LibraryWord := Value.LibraryFunData[1];
        asm
          call LibraryWord
          mov LibraryWord, eax
        end;
        if Value.LibraryFunData[0] = 1 then Dest.Value.SetInt(LibraryWord)
        else if Value.LibraryFunData[0] = 2 then Dest.Value.SetDword(LibraryWord);
      end
      else if Callee.RealVType = vkExternFun then
      begin
        SetLength(Arguments, Instruction.OperandCount - 1);
        Arguments[0] := Dest.Value;
        Dest.Value.ResetKind(vkEmpty);
        for j := 2 to Instruction.OperandCount - 1 do
        begin
          Argument := GetVariable(Instruction.Operands[j]).Resolve(vkEmpty);
          Arguments[j - 1] := Argument;
        end;
        if Code <> nil then
        begin
          Code.Process := Process;
          Code.DebugContext := DebugContext;
        end;
        TExpressionCallback(Callee.GetExternFun())(Arguments, Code);
      end
      else if Callee.RealVType = vkFunction then
      begin
        if Callee.GetFunction.LocalVar.GetVar('funBaseVarCount').GetInt < Instruction.OperandCount - 2 then
          raise ExceptionExpressionEC.Create('Count var error. fun:' + Left.Name);
        Invocation := TCodeEC.Create;
        Invocation.Parent := Callee.GetFunction;
        Invocation.CopyFromFast(Callee.GetFunction);
        for j := 2 to Instruction.OperandCount - 1 do
        begin
          Argument := GetVariable(Instruction.Operands[j]).Resolve(vkEmpty);
          if Invocation.LocalVar.GetItem(j - 2).Kind = vkRef then
            Invocation.LocalVar.GetItem(j - 2).SetRef(Argument)
          else Invocation.LocalVar.GetItem(j - 2).Assume(Argument);
        end;
        try
          Invocation.LocalVar.GetVar('result').SetRef(Dest.Value);
          if DebugContext = nil then Invocation.Run(Process)
          else Invocation.RunDebug(Process, DebugContext);
        except
          Invocation.Free;
          raise;
        end;
        Invocation.Free;
      end
      else raise ExceptionExpressionEC.Create('Not fun:' + Left.Name);
    end;
    Inc(i);
  end;
end;
{ @end $45F778 }

{ @routine $460504 TExpressionEC_GetResult }
function TExpressionEC.GetResult: TVarEC;
begin
  if (ResultIndex < 0) or (GetVariable(ResultIndex).Value = nil) then
    raise ExceptionExpressionEC.Create('Not link var return');
  Result := GetVariable(ResultIndex).Value;
end;
{ @end $460504 }

{ @routine $460564 TCompilerEC_Create }
constructor TCompilerEC.Create;
begin
  inherited Create;
end;
{ @end $460564 }

{ @routine $46059C TCompilerEC_Destroy }
destructor TCompilerEC.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $46059C }

{ @routine $4605C8 TCompilerEC_Clear }
procedure TCompilerEC.Clear;
begin
  while First <> nil do DeleteUnit(Last);
end;
{ @end $4605C8 }

{ @routine $4605E0 TCompilerEC_AddUnit }
function TCompilerEC.AddUnit: TCompilerUnitEC;
var
  Item: TCompilerUnitEC;
begin
  Item := TCompilerUnitEC.Create;
  if Last <> nil then Last.Next := Item;
  Item.Prev := Last;
  Item.Next := nil;
  Last := Item;
  if First = nil then First := Item;
  Result := Item;
end;
{ @end $4605E0 }

{ @routine $460614 TCompilerEC_DeleteUnit }
procedure TCompilerEC.DeleteUnit(UnitNode: TCompilerUnitEC);
begin
  if UnitNode.Prev <> nil then UnitNode.Prev.Next := UnitNode.Next;
  if UnitNode.Next <> nil then UnitNode.Next.Prev := UnitNode.Prev;
  if Last = UnitNode then Last := UnitNode.Prev;
  if First = UnitNode then First := UnitNode.Next;
  UnitNode.Free;
end;
{ @end $460614 }

{ @routine $460650 TCompilerEC_FindReducibleOperator }
function TCompilerEC.FindReducibleOperator: TCompilerUnitEC;
var
  i: Integer;
  Item, Following: TCompilerUnitEC;
  Candidates: array[0..10] of TCompilerUnitEC;
begin
  for i := 0 to 10 do Candidates[i] := nil;
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuUnaryOperator then
    begin
      if (Item.Next <> nil) and (Item.Next.Kind = cuVariable) and (Candidates[0] = nil) then Candidates[0] := Item;
    end
    else if Item.Kind = cuBinaryOperator then
    begin
      if (Item.Prev.Kind = cuVariable) and (Item.Next.Kind = cuVariable) then
      begin
        Following := Item.Next.Next;
        while Following <> nil do
        begin
          if (Following.Kind = cuOpenParen) or (Following.Kind = cuOpenBracket) or
            (Following.Kind = cuCall) then Break;
          if (Following.Kind = cuCloseParen) or (Following.Kind = cuCloseBracket) then Break;
          Following := Following.Next;
        end;
        if (Following = nil) or ((Following.Kind <> cuOpenParen) and
          (Following.Kind <> cuOpenBracket) and (Following.Kind <> cuCall)) then
        begin
          if (Item.OperatorToken = ctMultiply) or (Item.OperatorToken = ctDivide) or
            (Item.OperatorToken = ctModulo) then
          begin
            if Candidates[1] = nil then Candidates[1] := Item;
          end
          else if (Item.OperatorToken = ctAdd) or (Item.OperatorToken = ctSubtract) then
          begin
            if Candidates[2] = nil then Candidates[2] := Item;
          end
          else if (Item.OperatorToken = ctShiftLeft) or (Item.OperatorToken = ctShiftRight) then
          begin
            if Candidates[3] = nil then Candidates[3] := Item;
          end
          else if (Item.OperatorToken = ctEqual) or (Item.OperatorToken = ctNotEqual) or
            (Item.OperatorToken = ctLess) or (Item.OperatorToken = ctGreater) or
            (Item.OperatorToken = ctLessEqual) or (Item.OperatorToken = ctGreaterEqual) then
          begin
            if Candidates[4] = nil then Candidates[4] := Item;
          end
          else if Item.OperatorToken = ctBitAnd then
          begin
            if Candidates[5] = nil then Candidates[5] := Item;
          end
          else if Item.OperatorToken = ctBitXor then
          begin
            if Candidates[6] = nil then Candidates[6] := Item;
          end
          else if Item.OperatorToken = ctBitOr then
          begin
            if Candidates[7] = nil then Candidates[7] := Item;
          end
          else if Item.OperatorToken = ctAnd then
          begin
            if Candidates[8] = nil then Candidates[8] := Item;
          end
          else if Item.OperatorToken = ctOr then
          begin
            if Candidates[9] = nil then Candidates[9] := Item;
          end;
        end;
      end;
    end
    else if Item.Kind = cuAssignment then
    begin
      if (Item.Prev.Kind = cuVariable) and (Item.Next.Kind = cuVariable) and
        (Candidates[10] = nil) then Candidates[10] := Item;
    end;
    Item := Item.Next;
  end;
  for i := 0 to 10 do
    if Candidates[i] <> nil then
    begin
      Result := Candidates[i];
      Exit;
    end;
  Result := nil;
end;
{ @end $460650 }

{ @routine $460854 TCompilerEC_FindReducibleIndex }
function TCompilerEC.FindReducibleIndex: TCompilerUnitEC;
var
  Item, Following: TCompilerUnitEC;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuIndex then
    begin
      Following := Item.Next;
      while Following <> nil do
      begin
        if Following.Kind = cuCloseBracket then
        begin
          Result := Item;
          Exit;
        end;
        if (Following.Kind <> cuComma) and (Following.Kind <> cuVariable) then Break;
        Following := Following.Next;
      end;
    end;
    Item := Item.Next;
  end;
  Result := nil;
end;
{ @end $460854 }

{ @routine $460890 TCompilerEC_FindReducibleCall }
function TCompilerEC.FindReducibleCall: TCompilerUnitEC;
var
  Item, Following: TCompilerUnitEC;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Kind = cuCall then
    begin
      Following := Item.Next;
      while Following <> nil do
      begin
        if Following.Kind = cuCloseParen then
        begin
          Result := Item;
          Exit;
        end;
        if (Following.Kind <> cuComma) and (Following.Kind <> cuVariable) then Break;
        Following := Following.Next;
      end;
    end;
    Item := Item.Next;
  end;
  Result := nil;
end;
{ @end $460890 }

{ @routine $4608CC TCodeUnitEC_Destroy }
destructor TCodeUnitEC.Destroy;
begin
  if Expression <> nil then
  begin
    Expression.Free;
    Expression := nil;
  end;
  inherited Destroy;
end;
{ @end $4608CC }

{ @routine $460904 TCodeProcessEC_Create }
constructor TCodeProcessEC.Create;
begin
  inherited Create;
  Handlers := TList.Create;
  Exceptions := TList.Create;
end;
{ @end $460904 }

{ @routine $460958 TCodeProcessEC_Destroy }
destructor TCodeProcessEC.Destroy;
begin
  Clear;
  Handlers.Free;
  Handlers := nil;
  Exceptions.Free;
  Exceptions := nil;
  inherited Destroy;
end;
{ @end $460958 }

{ @routine $4609A0 TCodeProcessEC_Clear }
procedure TCodeProcessEC.Clear;
var
  Handler: PCodeExceptionHandler;
  Value: PVarEC;
  i: Integer;
begin
  for i := 0 to Handlers.Count - 1 do
  begin
    Handler := Handlers[i];
    HeapFree(GetProcessHeap, 0, Handler);
  end;
  Handlers.Clear;
  for i := 0 to Exceptions.Count - 1 do
  begin
    Value := Exceptions[i];
    if Value^ <> nil then
    begin
      Value^.Free;
      Value^ := nil;
    end;
    HeapFree(GetProcessHeap, 0, Value);
  end;
  Exceptions.Clear;
end;
{ @end $4609A0 }

{ @routine $460A24 TCodeProcessEC_PushHandler }
procedure TCodeProcessEC.PushHandler(Code: TCodeEC; Handler: TCodeUnitEC);
var Entry: PCodeExceptionHandler;
begin
  Entry := HeapAlloc(GetProcessHeap, 0, SizeOf(TCodeExceptionHandler));
  Entry.Code := Code;
  Entry.Handler := Handler;
  Handlers.Add(Entry);
end;
{ @end $460A24 }

{ @routine $460A50 TCodeProcessEC_PopHandler }
procedure TCodeProcessEC.PopHandler;
var
  Entry: PCodeExceptionHandler;
  Count: Integer;
begin
  Count := Handlers.Count;
  if Count < 1 then Exit;
  Entry := Handlers[Count - 1];
  HeapFree(GetProcessHeap, 0, Entry);
  Handlers.Delete(Count - 1);
end;
{ @end $460A50 }

{ @routine $460A8C TCodeProcessEC_GetHandler }
function TCodeProcessEC.GetHandler: PCodeExceptionHandler;
var Count: Integer;
begin
  Count := Handlers.Count;
  if Count < 1 then Result := nil
  else Result := Handlers[Count - 1];
end;
{ @end $460A8C }

{ @routine $460AA4 TCodeProcessEC_PushException }
procedure TCodeProcessEC.PushException(Value: TVarEC);
var Entry: PVarEC;
begin
  Entry := HeapAlloc(GetProcessHeap, 0, SizeOf(TVarEC));
  Entry^ := TVarEC.Create(Value.RealVType);
  Entry^.Assume(Value);
  Exceptions.Add(Entry);
end;
{ @end $460AA4 }

{ @routine $460AF0 TCodeProcessEC_PopException }
procedure TCodeProcessEC.PopException;
var
  Entry: PVarEC;
  Count: Integer;
begin
  Count := Exceptions.Count;
  if Count < 1 then Exit;
  Entry := Exceptions[Count - 1];
  HeapFree(GetProcessHeap, 0, Entry);
  Exceptions.Delete(Count - 1);
end;
{ @end $460AF0 }

{ @routine $460B2C TCodeProcessEC_GetException }
function TCodeProcessEC.GetException: PVarEC;
var Count: Integer;
begin
  Count := Exceptions.Count;
  if Count < 1 then Result := nil
  else Result := Exceptions[Count - 1];
end;
{ @end $460B2C }

{ @routine $460B44 TCodeEC_Create }
constructor TCodeEC.Create;
begin
  inherited Create;
  LocalVar := TVarArrayEC.Create;
end;
{ @end $460B44 }

{ @routine $460B88 TCodeEC_Destroy }
destructor TCodeEC.Destroy;
begin
  Clear;
  LocalVar.Free;
  inherited Destroy;
end;
{ @end $460B88 }

{ @routine $460BBC TCodeEC_Clear }
procedure TCodeEC.Clear;
begin
  while First <> nil do DeleteCodeUnit(Last);
  LocalVar.Clear;
end;
{ @end $460BBC }

{ @routine $460BDC TCodeEC_CopyFrom }
procedure TCodeEC.CopyFrom(Source: TCodeEC);
var
  Dest, Src, DestTarget, SrcTarget: TCodeUnitEC;
begin
  Clear;
  IsClassDefinition := Source.IsClassDefinition;
  Name := Source.Name;
  Parent := Parent;
  Src := Source.First;
  while Src <> nil do
  begin
    Dest := AddCodeUnit;
    Dest.Opcode := Src.Opcode;
    Dest.SourceStart := Src.SourceStart;
    Dest.SourceLength := Src.SourceLength;
    Dest.SourceContext := Src.SourceContext;
    Dest.Target := Src.Target;
    Dest.Breakpoint := Src.Breakpoint;
    Dest.Expression := nil;
    if Src.Expression <> nil then
    begin
      Dest.Expression := TExpressionEC.Create;
      Dest.Expression.CopyFrom(Src.Expression);
    end;
    Src := Src.Next;
  end;
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.Target <> nil then
    begin
      SrcTarget := Source.First;
      DestTarget := First;
      while SrcTarget <> nil do
      begin
        if Src.Target = SrcTarget then Dest.Target := DestTarget;
        SrcTarget := SrcTarget.Next;
        DestTarget := DestTarget.Next;
      end;
    end;
    Src := Src.Next;
    Dest := Dest.Next;
  end;
  LocalVar.CopyFrom(Source.LocalVar);
end;
{ @end $460BDC }

{ @routine $460CA8 TCodeEC_CopyFromFast }
procedure TCodeEC.CopyFromFast(Source: TCodeEC);
var
  Dest, Src, DestTarget, SrcTarget: TCodeUnitEC;
begin
  Clear;
  Src := Source.First;
  while Src <> nil do
  begin
    Dest := AddCodeUnit;
    Dest.Opcode := Src.Opcode;
    Dest.SourceStart := Src.SourceStart;
    Dest.SourceLength := Src.SourceLength;
    Dest.SourceContext := Src.SourceContext;
    Dest.Target := Src.Target;
    Dest.Breakpoint := Src.Breakpoint;
    Dest.Expression := nil;
    if Src.Expression <> nil then
    begin
      Dest.Expression := TExpressionEC.Create;
      Dest.Expression.CopyFromFast(Src.Expression);
    end;
    Src := Src.Next;
  end;
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.Target <> nil then
    begin
      SrcTarget := Source.First;
      DestTarget := First;
      while SrcTarget <> nil do
      begin
        if Src.Target = SrcTarget then Dest.Target := DestTarget;
        SrcTarget := SrcTarget.Next;
        DestTarget := DestTarget.Next;
      end;
    end;
    Src := Src.Next;
    Dest := Dest.Next;
  end;
  LocalVar.CopyFrom(Source.LocalVar);
  Src := Source.First;
  Dest := First;
  while Src <> nil do
  begin
    if Src.ExceptionVar <> nil then Dest.ExceptionVar := LocalVar.GetVarNE(Src.ExceptionVar.Name);
    Src := Src.Next;
    Dest := Dest.Next;
  end;
end;
{ @end $460CA8 }

{ @routine $460D88 TCodeEC_FindVar }
function TCodeEC.FindVar(Name: WideString): TVarEC;
var
  Item: TVarEC;
  i: Integer;
begin
  Result := LocalVar.GetVarNE(Name);
  if Result <> nil then Exit
  else
    for i := 0 to LocalVar.Count - 1 do
    begin
      Item := LocalVar.GetItem(i);
      if (Item.Kind = vkFunction) and Item.FunctionValue.IsClassDefinition then
      begin
        Result := Item.FunctionValue.FindVar(Name);
        if Result <> nil then Exit;
      end;
    end;
end;
{ @end $460D88 }

{ @routine $460E28 TCodeEC_DeleteCodeUnit }
procedure TCodeEC.DeleteCodeUnit(CodeUnit: TCodeUnitEC);
begin
  if CodeUnit.Prev <> nil then CodeUnit.Prev.Next := CodeUnit.Next;
  if CodeUnit.Next <> nil then CodeUnit.Next.Prev := CodeUnit.Prev;
  if Last = CodeUnit then Last := CodeUnit.Prev;
  if First = CodeUnit then First := CodeUnit.Next;
  CodeUnit.Free;
end;
{ @end $460E28 }

{ @routine $460E64 TCodeEC_AddCodeUnit }
function TCodeEC.AddCodeUnit: TCodeUnitEC;
var Item: TCodeUnitEC;
begin
  Item := TCodeUnitEC.Create;
  if Last <> nil then Last.Next := Item;
  Item.Prev := Last;
  Item.Next := nil;
  Last := Item;
  if First = nil then First := Item;
  Result := Item;
end;
{ @end $460E64 }

{ @routine $460E98 TCodeEC_InsertCodeUnitBefore }
function TCodeEC.InsertCodeUnitBefore(BeforeUnit: TCodeUnitEC): TCodeUnitEC;
var Item: TCodeUnitEC;
begin
  if BeforeUnit = nil then
  begin
    Result := AddCodeUnit;
    Exit;
  end;
  Item := TCodeUnitEC.Create;
  Item.Prev := BeforeUnit.Prev;
  Item.Next := BeforeUnit;
  if BeforeUnit.Prev <> nil then BeforeUnit.Prev.Next := Item;
  BeforeUnit.Prev := Item;
  if First = BeforeUnit then First := Item;
  Result := Item;
end;
{ @end $460E98 }

{ @routine $460EDC TCodeEC_Compile }
function TCodeEC.Compile(Analyzer: TCodeAnalyzerEC; SourceContext: Pointer; IncludeResolver: TScriptIncludeResolver; FirstToken: TCodeAnalyzerUnitEC; NextToken: PCodeAnalyzerUnitEC; CompilationContext: Pointer): WideString;
begin
  Result := '';
  if FirstToken = nil then FirstToken := Analyzer.First;
  Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, FirstToken, nil, NextToken, nil, nil, nil, CompilationContext);
end;
{ @end $460EDC }

{ @routine $461388 TCodeEC_CompileBlock }
function TCodeEC.CompileBlock(Analyzer: TCodeAnalyzerEC; SourceContext: Pointer; IncludeResolver: TScriptIncludeResolver; Token: TCodeAnalyzerUnitEC; BeforeUnit: TCodeUnitEC; NextToken, StatementEnd: PCodeAnalyzerUnitEC; BreakTarget, ContinueTarget: TCodeUnitEC; CompilationContext: Pointer): WideString;
var
  Included: TCodeAnalyzerEC;
  IncludedContext: Pointer;
  Next: TCodeAnalyzerUnitEC;
  Keyword: WideString;
  Item, LoopStart, StepStart, EndLabel, Branch: TCodeUnitEC;
  Depth: Integer;
  Value, BaseValue: TVarEC;
  Definition: TCodeEC;
  ParameterCount: Integer;
  FloatValue: Double;
  DwordValue: Dword;
  IntValue: Integer;
  Text: WideString;
  InsertSource: Boolean;
  Lookahead: TCodeAnalyzerUnitEC;

  // @nested $460F30 AddScriptLocal
  procedure AddScriptLocal(TypeName, Name: WideString); // @addr $460F30
  begin
    if TypeName = 'unknown' then LocalVar.Add(Name, vkEmpty)
    else if TypeName = 'int' then LocalVar.Add(Name, vkInt)
    else if TypeName = 'dword' then LocalVar.Add(Name, vkDword)
    else if TypeName = 'float' then LocalVar.Add(Name, vkFloat)
    else if TypeName = 'str' then LocalVar.Add(Name, vkString)
    else if TypeName = 'ref' then LocalVar.Add(Name, vkRef)
    else if TypeName = 'array' then LocalVar.Add(Name, vkArray);
  end;

  // @nested $4610EC IsScriptLocalDeclaration
  function IsScriptLocalDeclaration(Token: TCodeAnalyzerUnitEC): Boolean; // @addr $4610EC
  begin
    Result := (Token <> nil) and (Token.Next <> nil) and
      (Token.Next.TokenKind = ctText) and (Token.TokenKind = ctText) and
      ((Token.Text = 'unknown') or (Token.Text = 'int') or (Token.Text = 'dword') or
       (Token.Text = 'float') or (Token.Text = 'str') or (Token.Text = 'ref') or
       (Token.Text = 'array')) and IsNonIntegerScriptText(Token.Next.Text);
  end;

  // @nested $4611F8 CompileScriptLocals
  function CompileScriptLocals(var Token: TCodeAnalyzerUnitEC): WideString; // @addr $4611F8
  var
    Item: TCodeUnitEC;
    Next: TCodeAnalyzerUnitEC;
    TypeName: WideString;
  begin
    Result := '';
    TypeName := Token.Text;
    Token := Token.Next;
    while (Token.TokenKind = ctText) and IsNonIntegerScriptText(Token.Text) do
    begin
      if LocalVar.GetVarNE(Token.Text) <> nil then
      begin
        Result := FormatScriptError(0, Token.SourceStart);
        Exit;
      end;
      AddScriptLocal(TypeName, Token.Text);
      if Token.Next = nil then
      begin
        Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
        Exit;
      end;
      Token := Token.Next;
      if Token.TokenKind = ctComma then
      begin
        Token := Token.Next;
        Continue;
      end
      else if Token.TokenKind = ctAssign then
      begin
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExpression;
        Item.Expression := TExpressionEC.Create;
        Item.SourceStart := Token.Prev.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        { Native reads the outer compilation-context argument at [frame+$0C]. }
        Result := Item.Expression.Compile(Analyzer, CompilationContext, Token.Prev, nil, @Next);
        if Result <> '' then Exit;
        Item.SourceLength := Next.Prev.SourceStart + Next.Prev.SourceLength - Item.SourceStart;
        Token := Next;
        if Token.TokenKind = ctComma then Token := Token.Next;
      end;
    end;
  end;

begin
  Result := '';
  Depth := 0;
  while Token <> nil do
  begin
    if Token.TokenKind = ctText then
    begin
      Keyword := LowerCase(AnsiString(Token.Text));
      if IsScriptLocalDeclaration(Token) then
      begin
        Result := CompileScriptLocals(Token);
        if Result <> '' then Exit;
        if Token.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        Token := Token.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end;
      if Keyword = 'if' then
      begin
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := EndLabel.SourceStart;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        while True do
        begin
          if Token.Next = nil then
          begin
            Result := FormatScriptError(0, Token.SourceStart);
            Exit;
          end;
          Lookahead := Token.Next;
          if (Lookahead.TokenKind <> ctOpenParen) or (Lookahead.Next = nil) then
          begin
            Result := FormatScriptError(0, Lookahead.SourceStart);
            Exit;
          end;
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coBranchFalse;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          Item.Expression := TExpressionEC.Create;
          Result := Item.Expression.Compile(Analyzer, CompilationContext, Token.Next.Next, nil, @Next);
          if Result <> '' then Exit;
          if Next = nil then
          begin
            Result := FormatScriptError(0, Token.SourceStart);
            Exit;
          end;
          if Next.TokenKind <> ctCloseParen then
          begin
            Result := FormatScriptError(0, Next.SourceStart);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
          Branch := Item;
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coJump;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          LoopStart := Item;
          if Token.TokenKind = ctSemicolon then Token := Token.Next
          else
          begin
            Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Token, LoopStart,
              NextToken, @Token, BreakTarget, ContinueTarget, CompilationContext);
            if Result <> '' then Exit;
          end;
          if Token = nil then Exit;
          if Token.TokenKind <> ctText then Break;
          Keyword := LowerCase(AnsiString(Token.Text));
          if Keyword <> 'else' then Break;
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coLabel;
          Item.SourceStart := 0;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Branch.Target := Item;
          Lookahead := Token.Next;
          if Lookahead <> nil then
            if (Lookahead.TokenKind = ctText) and
              (LowerCase(AnsiString(Lookahead.Text)) = 'if') then
            begin
              Token := Token.Next;
              Continue;
            end;
          if Token.Next = nil then
          begin
            Result := FormatScriptError(0, Token.SourceStart);
            Exit;
          end;
          Lookahead := Token.Next;
          if Lookahead.TokenKind = ctSemicolon then Continue;
          Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Lookahead, EndLabel,
            NextToken, @Token, BreakTarget, ContinueTarget, CompilationContext);
          if Result <> '' then Exit;
          if (StatementEnd <> nil) and (Depth = 0) then
          begin
            StatementEnd^ := Token;
            Exit;
          end;
          Break;
        end;
        Continue;
      end;
      if Keyword = 'while' then
      begin
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := EndLabel.SourceStart;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        Lookahead := Token.Next;
        if (Lookahead.TokenKind <> ctOpenParen) or (Lookahead.Next = nil) then
        begin
          Result := FormatScriptError(0, Lookahead.SourceStart);
          Exit;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coBranchFalse;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := EndLabel;
        Item.Expression := TExpressionEC.Create;
        Result := Item.Expression.Compile(Analyzer, CompilationContext, Token.Next.Next, nil, @Next);
        if Result <> '' then Exit;
        if Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        if Next.TokenKind <> ctCloseParen then
        begin
          Result := FormatScriptError(0, Next.SourceStart);
          Exit;
        end;
        Token := Next.Next;
        Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
        LoopStart := Item;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := LoopStart;
        if Token.TokenKind = ctSemicolon then Token := Token.Next
        else
        begin
          Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Token, Item,
            NextToken, @Token, EndLabel, LoopStart, CompilationContext);
          if Result <> '' then Exit;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'for' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        Lookahead := Token.Next;
        if Lookahead.TokenKind <> ctOpenParen then
        begin
          Result := FormatScriptError(0, Lookahead.SourceStart);
          Exit;
        end;
        Lookahead := Token.Next;
        if Lookahead.Next = nil then
        begin
          Result := FormatScriptError(0, Lookahead.SourceStart + Lookahead.SourceLength);
          Exit;
        end;
        Token := Token.Next.Next;
        if Token.TokenKind <> ctSemicolon then
        begin
          if IsScriptLocalDeclaration(Token) then
          begin
            Result := CompileScriptLocals(Token);
            if Result <> '' then Exit;
          end
          else
          begin
            while True do
            begin
              Item := InsertCodeUnitBefore(BeforeUnit);
              Item.Opcode := coExpression;
              Item.SourceStart := Token.SourceStart;
              Item.SourceLength := 0;
              Item.SourceContext := SourceContext;
              Item.Expression := TExpressionEC.Create;
              Result := Item.Expression.Compile(Analyzer, CompilationContext, Token, nil, @Next);
              if Result <> '' then Exit;
              if Next = nil then
              begin
                Result := FormatScriptError(0, Token.SourceStart);
                Exit;
              end;
              Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
              if Next.TokenKind = ctSemicolon then
              begin
                Token := Next;
                Break;
              end
              else if Next.TokenKind = ctComma then Token := Next.Next
              else
              begin
                Result := FormatScriptError(0, Next.SourceStart);
                Exit;
              end;
            end;
          end;
        end;
        if Token.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        Token := Token.Next;
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := EndLabel.SourceStart;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if Token.TokenKind = ctSemicolon then
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coLabel;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Token := Token.Next;
        end
        else
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coBranchFalse;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
          Item.Expression := TExpressionEC.Create;
          Result := Item.Expression.Compile(Analyzer, CompilationContext, Token, nil, @Next);
          if Result <> '' then Exit;
          if Next = nil then
          begin
            Result := FormatScriptError(0, Token.SourceStart);
            Exit;
          end;
          if Next.TokenKind <> ctSemicolon then
          begin
            Result := FormatScriptError(0, Next.SourceStart);
            Exit;
          end;
          if Next.Next = nil then
          begin
            Result := FormatScriptError(0, Next.SourceStart + Next.SourceLength);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.Prev.SourceStart - Item.SourceStart + (Next).Prev.SourceLength;
        end;
        LoopStart := Item;
        Item := InsertCodeUnitBefore(LoopStart);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := LoopStart;
        StepStart := nil;
        if Token.TokenKind = ctCloseParen then
        begin
          Item := InsertCodeUnitBefore(LoopStart);
          Item.Opcode := coLabel;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          StepStart := Item;
          Token := Token.Next;
        end
        else
        begin
          while True do
          begin
            Item := InsertCodeUnitBefore(LoopStart);
            Item.Opcode := coExpression;
            Item.SourceStart := Token.SourceStart;
            Item.SourceLength := 0;
            Item.SourceContext := SourceContext;
            Item.Expression := TExpressionEC.Create;
            Result := Item.Expression.Compile(Analyzer, CompilationContext, Token, nil, @Next);
            if Result <> '' then Exit;
            if Next = nil then
            begin
              Result := FormatScriptError(0, Token.SourceStart);
              Exit;
            end;
            Item.SourceLength := Next.Prev.SourceStart - Item.SourceStart + Next.Prev.SourceLength;
            if StepStart = nil then StepStart := Item;
            if Next.TokenKind = ctCloseParen then
            begin
              Token := Next.Next;
              Break;
            end
            else if Next.TokenKind = ctComma then Token := Next.Next
            else
            begin
              Result := FormatScriptError(0, Next.SourceStart);
              Exit;
            end;
          end;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Item.Target := StepStart;
        if Token.TokenKind = ctSemicolon then Token := Token.Next
        else
        begin
          Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Token, Item,
            NextToken, @Token, EndLabel, StepStart, CompilationContext);
          if Result <> '' then Exit;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'break' then
      begin
        if (BreakTarget = nil) or (Token.Next = nil) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end
        else
        begin
          Item := InsertCodeUnitBefore(BeforeUnit);
          Item.Opcode := coJump;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
          Item.SourceContext := SourceContext;
          Item.Target := BreakTarget;
          Token := Token.Next.Next;
          if (StatementEnd <> nil) and (Depth = 0) then
          begin
            StatementEnd^ := Token;
            Exit;
          end;
          Continue;
        end;
      end
      else if Keyword = 'continue' then
      begin
        if (ContinueTarget = nil) or (Token.Next = nil) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coJump;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
        Item.SourceContext := SourceContext;
        Item.Target := ContinueTarget;
        Token := Token.Next.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'exit' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.Next.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExit;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
        Item.SourceContext := SourceContext;
        Token := Token.Next.Next;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if (Keyword = '#include') or (Keyword = '#insert') then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.Next.TokenKind <> ctStringLiteral then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        if not Assigned(IncludeResolver) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        InsertSource := Keyword = '#insert';
        Included := TCodeAnalyzerEC.Create;
        IntValue := IncludeResolver(SourceContext, Token.Next.Text, InsertSource, IncludedContext, Included);
        if (IntValue = 2) or (IntValue = 3) then
        begin
          Included.Free;
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        if IntValue = 0 then
        begin
          Text := Included.ValidateDelimiters;
          if Text <> '' then
          begin
            Included.Free;
            Result := FormatScriptError(0, Token.Next.SourceStart);
            Exit;
          end;
          Result := CompileBlock(Included, IncludedContext, IncludeResolver, Included.First, BeforeUnit,
            nil, nil, nil, nil, CompilationContext);
          if Result <> '' then
          begin
            Included.Free;
            Exit;
          end;
        end;
        Included.Free;
        Token := Token.Next.Next;
        Continue;
      end
      else if Keyword = 'function' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if (Token.Next.TokenKind <> ctText) or not IsNonIntegerScriptText(Token.Next.Text) or
          (Token.Next.Next = nil) then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        if (Token.Next.Next.TokenKind <> ctOpenParen) or (Token.Next.Next.Next = nil) then
        begin
          Result := FormatScriptError(0, Token.Next.Next.SourceStart);
          Exit;
        end;
        Value := LocalVar.Add(Token.Next.Text, vkFunction);
        Definition := Value.GetFunction;
        Definition.Parent := Self;
        Next := Token.Next.Next.Next;
        while (Next <> nil) and (Next.TokenKind = ctText) and IsNonIntegerScriptText(Next.Text) do
        begin
          Keyword := LowerCase(AnsiString(Next.Text));
          if (Keyword = 'unknown') or (Keyword = 'int') or (Keyword = 'dword') or
            (Keyword = 'float') or (Keyword = 'str') or (Keyword = 'ref') or (Keyword = 'array') then
            Next := Next.Next
          else Keyword := 'unknown';
          if (Next = nil) or (Next.TokenKind <> ctText) or not IsNonIntegerScriptText(Next.Text) then Break;
          Value := nil;
          if Keyword = 'unknown' then Value := Definition.LocalVar.Add(Next.Text, vkEmpty)
          else if Keyword = 'int' then Value := Definition.LocalVar.Add(Next.Text, vkInt)
          else if Keyword = 'dword' then Value := Definition.LocalVar.Add(Next.Text, vkDword)
          else if Keyword = 'float' then Value := Definition.LocalVar.Add(Next.Text, vkFloat)
          else if Keyword = 'str' then Value := Definition.LocalVar.Add(Next.Text, vkString)
          else if Keyword = 'ref' then Value := Definition.LocalVar.Add(Next.Text, vkRef)
          else if Keyword = 'array' then Value := Definition.LocalVar.Add(Next.Text, vkArray);
          Next := Next.Next;
          if Next = nil then
          begin
            Result := FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength);
            Exit;
          end;
          if (Keyword <> 'ref') and (Next.TokenKind = ctAssign) then
          begin
            if Next.Next = nil then
            begin
              Result := FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength);
              Exit;
            end;
            Next := Next.Next;
            if TryReadFloatLiteral(Next, FloatValue) then Value.SetFloat(FloatValue)
            else if TryReadDwordLiteral(Next, DwordValue) then Value.SetDword(DwordValue)
            else if TryReadIntegerLiteral(Next, IntValue) then Value.SetInt(IntValue)
            else if TryReadStringLiteral(Next, Text) then Value.SetString(Text)
            else
            begin
              Result := FormatScriptError(0, Next.SourceStart);
              Exit;
            end;
          end;
          if (Next = nil) or (Next.TokenKind <> ctComma) then Break;
          Next := Next.Next;
        end;
        if (Next = nil) or (Next.TokenKind <> ctCloseParen) then
        begin
          Result := FormatScriptError(0, Token.Next.Next.Next.SourceStart);
          Exit;
        end;
        Token := Next.Next;
        if Token = nil then
        begin
          Result := FormatScriptError(0, Next.SourceStart);
          Exit;
        end;
        if (Token.TokenKind <> ctOpenBrace) or (Token.Next = nil) then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        ParameterCount := Definition.LocalVar.Count;
        Definition.LocalVar.Add('funBaseVarCount', vkInt).SetInt(ParameterCount);
        Definition.LocalVar.Add('result', vkRef);
        Next := nil;
        Result := Definition.Compile(Analyzer, SourceContext, IncludeResolver, Token.Next, @Next, CompilationContext);
        if Result <> '' then Exit;
        if Next = nil then
        begin
          Result := FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength);
          Exit;
        end;
        if Next.TokenKind <> ctCloseBrace then
        begin
          Result := FormatScriptError(0, Next.SourceStart);
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end
      else if Keyword = 'class' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if (Token.Next.TokenKind <> ctText) or not IsNonIntegerScriptText(Token.Next.Text) then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        if Token.Next.Next = nil then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart + Token.Next.SourceLength);
          Exit;
        end;
        Value := LocalVar.Add(Token.Next.Text, vkFunction);
        Definition := Value.GetFunction;
        Definition.Parent := Self;
        Definition.IsClassDefinition := True;
        Definition.Name := Token.Next.Text;
        Token := Token.Next.Next;
        if Token.TokenKind = ctColon then
        begin
          Token := Token.Next;
          while True do
          begin
            if Token.TokenKind <> ctText then Break;
            BaseValue := LocalVar.GetVarNE(Token.Text);
            if (BaseValue = nil) or (BaseValue.RealVType <> vkFunction) then
            begin
              Result := FormatScriptError(0, Token.SourceStart);
              Exit;
            end;
            Definition.LocalVar.Add(Token.Text, vkFunction).GetFunction.CopyFrom(BaseValue.GetFunction);
            Token := Token.Next;
            if Token.TokenKind <> ctComma then Break;
            Token := Token.Next;
          end;
        end;
        if Token.TokenKind <> ctOpenBrace then
        begin
          Result := FormatScriptError(0, Token.SourceStart);
          Exit;
        end;
        Next := nil;
        Result := Definition.Compile(Analyzer, SourceContext, IncludeResolver, Token.Next, @Next, Definition);
        if Result <> '' then Exit;
        if Next = nil then
        begin
          Result := FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength);
          Exit;
        end;
        if Next.TokenKind <> ctCloseBrace then
        begin
          Result := FormatScriptError(0, Next.SourceStart);
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end
      else if Keyword = 'try' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.Next.TokenKind <> ctOpenBrace then
        begin
          Result := FormatScriptError(0, Token.Next.SourceStart);
          Exit;
        end;
        LoopStart := InsertCodeUnitBefore(BeforeUnit);
        LoopStart.Opcode := coPushHandler;
        LoopStart.SourceStart := Token.SourceStart;
        LoopStart.SourceLength := 0;
        LoopStart.SourceContext := SourceContext;
        Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Token.Next, BeforeUnit,
          NextToken, @Token, nil, nil, CompilationContext);
        if Result <> '' then Exit;
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coPopHandler;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        if Token = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.TokenKind <> ctText then
        begin
          Result := FormatScriptError(1001, Token.SourceStart);
          Exit;
        end;
        if (Token.Text <> 'catch') and (Token.Text <> 'finally') then
        begin
          Result := FormatScriptError(1001, Token.SourceStart);
          Exit;
        end;
        if Token.Next = nil then
        begin
          Result := FormatScriptError(1001, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.Text = 'catch' then IntValue := 0
        else IntValue := 1;
        Token := Token.Next;
        Value := nil;
        if Token.TokenKind = ctOpenParen then
        begin
          if Token.Next = nil then
          begin
            Result := FormatScriptError(1001, Token.SourceStart + Token.SourceLength);
            Exit;
          end;
          Token := Token.Next;
          if Token.TokenKind <> ctText then
          begin
            Result := FormatScriptError(1001, Token.SourceStart);
            Exit;
          end;
          Value := LocalVar.Add(Token.Text, vkEmpty);
          if Token.Next = nil then
          begin
            Result := FormatScriptError(1001, Token.SourceStart + Token.SourceLength);
            Exit;
          end;
          Token := Token.Next;
          if Token.TokenKind <> ctCloseParen then
          begin
            Result := FormatScriptError(1001, Token.SourceStart);
            Exit;
          end;
          if Token.Next = nil then
          begin
            Result := FormatScriptError(1001, Token.SourceStart + Token.SourceLength);
            Exit;
          end;
          Token := Token.Next;
        end;
        if Token.TokenKind <> ctOpenBrace then
        begin
          Result := FormatScriptError(1001, Token.SourceStart);
          Exit;
        end;
        EndLabel := InsertCodeUnitBefore(BeforeUnit);
        EndLabel.Opcode := coLabel;
        EndLabel.SourceStart := EndLabel.SourceStart;
        EndLabel.SourceLength := 0;
        EndLabel.SourceContext := SourceContext;
        if IntValue = 0 then
        begin
          Item := InsertCodeUnitBefore(EndLabel);
          Item.Opcode := coJump;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
          Item.Target := EndLabel;
        end;
        Item := InsertCodeUnitBefore(EndLabel);
        Item.Opcode := coLabel;
        Item.SourceStart := Item.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        LoopStart.Target := Item;
        Item.ExceptionVar := Value;
        Item := EndLabel;
        if IntValue = 1 then
        begin
          Item := InsertCodeUnitBefore(Item);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := 0;
          Item.SourceContext := SourceContext;
        end;
        Result := CompileBlock(Analyzer, SourceContext, IncludeResolver, Token, Item,
          NextToken, @Token, nil, nil, CompilationContext);
        if Result <> '' then Exit;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else if Keyword = 'throw' then
      begin
        if Token.Next = nil then
        begin
          Result := FormatScriptError(0, Token.SourceStart + Token.SourceLength);
          Exit;
        end;
        if Token.Next.TokenKind = ctSemicolon then
        begin
          Item := InsertCodeUnitBefore(BeforeUnit);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
          Item.SourceContext := SourceContext;
          Token := Token.Next.Next;
        end
        else
        begin
          Item := InsertCodeUnitBefore(BeforeUnit);
          Item.Opcode := coThrow;
          Item.SourceStart := Token.SourceStart;
          Item.SourceLength := Token.Next.SourceStart - Token.SourceStart + Token.Next.SourceLength;
          Item.SourceContext := SourceContext;
          Item.Expression := TExpressionEC.Create;
          Result := Item.Expression.Compile(Analyzer, CompilationContext, Token.Next, nil, @Next);
          if Result <> '' then Exit;
          if Next = nil then
          begin
            Result := FormatScriptError(0, Token.SourceStart);
            Exit;
          end;
          if Next.TokenKind <> ctSemicolon then
          begin
            Result := FormatScriptError(0, Next.SourceStart);
            Exit;
          end;
          Token := Next.Next;
          Item.SourceLength := Next.SourceStart - Item.SourceStart + Next.SourceLength;
        end;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Token;
          Exit;
        end;
        Continue;
      end
      else
      begin
        Item := InsertCodeUnitBefore(BeforeUnit);
        Item.Opcode := coExpression;
        Item.Expression := TExpressionEC.Create;
        Item.SourceStart := Token.SourceStart;
        Item.SourceLength := 0;
        Item.SourceContext := SourceContext;
        Result := Item.Expression.Compile(Analyzer, CompilationContext, Token, nil, @Next);
        if Result <> '' then Exit;
        if Next = nil then
        begin
          Result := FormatScriptError(0, Analyzer.Last.SourceStart + Analyzer.Last.SourceLength);
          Exit;
        end;
        if Next.TokenKind <> ctSemicolon then
        begin
          Result := FormatScriptError(0, Next.SourceStart);
          Exit;
        end;
        Item.SourceLength := Next.SourceStart + Next.SourceLength - Item.SourceStart;
        if (StatementEnd <> nil) and (Depth = 0) then
        begin
          StatementEnd^ := Next.Next;
          Exit;
        end;
        Token := Next.Next;
        Continue;
      end;
    end
    else if Token.TokenKind = ctOpenBrace then Inc(Depth)
    else if Token.TokenKind = ctCloseBrace then
    begin
      Dec(Depth);
      if (StatementEnd <> nil) and (Depth = 0) then
      begin
        StatementEnd^ := Token.Next;
        Exit;
      end;
      if Depth = -1 then
      begin
        if NextToken <> nil then NextToken^ := Token;
        Exit;
      end;
    end
    else
    begin
      Result := FormatScriptError(0, Token.SourceStart);
      Exit;
    end;
    if Token = nil then Exit;
    Token := Token.Next;
  end;
end;
{ @end $461388 }

{ @routine $4631B0 TCodeEC_LinkAll }
procedure TCodeEC.LinkAll(Scope: TVarArrayEC);
var
  Item: TCodeUnitEC;
  i: Integer;
begin
  Item := First;
  while Item <> nil do
  begin
    if Item.Expression <> nil then Item.Expression.Link(Scope);
    Item := Item.Next;
  end;
  for i := 0 to LocalVar.Count - 1 do
  begin
    with LocalVar.GetItem(i) do
    begin
      if (Kind = vkFunction) and (GetFunction <> nil) then
        GetFunction.LinkAll(Scope)
      else if Kind = vkClass then
      begin
        if GetClass <> nil then GetClass.LinkAll(Scope);
      end;
    end;
  end;
end;
{ @end $4631B0 }

{ @routine $463240 TCodeEC_LinkLocalScopes }
procedure TCodeEC.LinkLocalScopes;
var
  i: Integer;
begin
  for i := 0 to LocalVar.Count - 1 do
    with LocalVar.GetItem(i) do
      if (Kind = vkFunction) and (Pointer(FunctionValue) <> nil) and FunctionValue.IsClassDefinition then
        FunctionValue.LinkLocalScopes;
  LinkAll(LocalVar);
end;
{ @end $463240 }

{ @routine $46328C TCodeEC_Run }
procedure TCodeEC.Run(Process: TCodeProcessEC);
var
  Item: TCodeUnitEC;
  Handler: PCodeExceptionHandler;
  Pending: PVarEC;
  Caught: TVarEC;
begin
  LinkAll(LocalVar);
  Caught := nil;
  Item := First;
  while Item <> nil do
  begin
    if Item.Opcode = coExpression then
    begin
        Item.Expression.Evaluate(Process, Self, nil);
    end
    else if Item.Opcode = coJump then
    begin
      Item := Item.Target;
      Continue;
    end
    else if Item.Opcode = coBranchFalse then
    begin
        Item.Expression.Evaluate(Process, Self, nil);
      if not Item.Expression.GetResult.IsTrue then
      begin
        Item := Item.Target;
        Continue;
      end;
    end
    else if Item.Opcode = coExit then
    begin
      while True do
      begin
        Handler := Process.GetHandler;
        if (Handler = nil) or (Handler.Code <> Self) then Break;
        Process.PopHandler;
      end;
      Break;
    end
    else if Item.Opcode = coPushHandler then Process.PushHandler(Self, Item.Target)
    else if Item.Opcode = coPopHandler then Process.PopHandler
    else if Item.Opcode = coThrow then
    begin
      if Item.Expression <> nil then
      begin
        Item.Expression.Evaluate(Process, Self, nil);
        Process.PushException(Item.Expression.GetResult);
      end
      else if Caught <> nil then
      begin
        Process.PushException(Caught);
        Caught := nil;
      end;
    end;
    Pending := Process.GetException;
    if Pending <> nil then
    begin
      Handler := Process.GetHandler;
      if Handler <> nil then
      begin
        if Handler.Code <> Self then Break;
        Item := Handler.Handler;
        Caught := Pending^;
        Pending^ := nil;
        if Item.ExceptionVar <> nil then Item.ExceptionVar.Assume(Caught);
        Process.PopHandler;
        Process.PopException;
        Continue;
      end
      ;
    end;
    Item := Item.Next;
  end;
  if Caught <> nil then Caught.Free;
end;
{ @end $46328C }

{ @routine $4633EC TCodeEC_RunDebug }
procedure TCodeEC.RunDebug(Process: TCodeProcessEC; DebugContext: TScriptDebugState);
var
  Item: TCodeUnitEC;
  Events: array[0..1] of Dword;
  WaitResult: Dword;
  Handler: PCodeExceptionHandler;
  Pending: PVarEC;
  Caught: TVarEC;
begin
  LinkAll(LocalVar);
  Caught := nil;
  Events[0] := DebugContext.StopEvent;
  Events[1] := DebugContext.ResumeEvent;
  Item := First;
  while Item <> nil do
  begin
    WaitResult := WaitForSingleObject(DebugContext.StopEvent, 0);
    if (WaitResult = WAIT_FAILED) or (WaitResult = WAIT_OBJECT_0) or
      (WaitResult = WAIT_ABANDONED_0) then Break;
    if (DebugContext.Paused and (Item.SourceLength > 0)) or Item.Breakpoint then
    begin
      DebugContext.CurrentUnit := Item;
      ResetEvent(DebugContext.ResumeEvent);
      WaitResult := WaitForMultipleObjects(Length(Events), @Events, False, INFINITE);
      if (WaitResult = WAIT_FAILED) or (WaitResult = WAIT_OBJECT_0) or
        ((WaitResult >= WAIT_ABANDONED_0) and (WaitResult < WAIT_ABANDONED_0 + Length(Events))) then Break;
      DebugContext.CurrentCode := Self;
      if DebugContext.StepMode = 1 then DebugContext.Paused := True;
    end;
    if Item.Opcode = coExpression then
    begin
        Item.Expression.Evaluate(Process, Self, DebugContext);
    end
    else if Item.Opcode = coJump then
    begin
      Item := Item.Target;
      Continue;
    end
    else if Item.Opcode = coBranchFalse then
    begin
        Item.Expression.Evaluate(Process, Self, DebugContext);
      if not Item.Expression.GetResult.IsTrue then
      begin
        Item := Item.Target;
        Continue;
      end;
    end
    else if Item.Opcode = coExit then
    begin
      while True do
      begin
        Handler := Process.GetHandler;
        if (Handler = nil) or (Handler.Code <> Self) then Break;
        Process.PopHandler;
      end;
      Break;
    end
    else if Item.Opcode = coPushHandler then Process.PushHandler(Self, Item.Target)
    else if Item.Opcode = coPopHandler then Process.PopHandler
    else if Item.Opcode = coThrow then
    begin
      if Item.Expression <> nil then
      begin
        Item.Expression.Evaluate(Process, Self, nil);
        Process.PushException(Item.Expression.GetResult);
      end
      else if Caught <> nil then
      begin
        Process.PushException(Caught);
        Caught := nil;
      end;
    end;
    Pending := Process.GetException;
    if Pending <> nil then
    begin
      Handler := Process.GetHandler;
      if Handler <> nil then
      begin
        if Handler.Code <> Self then Break;
        Item := Handler.Handler;
        Caught := Pending^;
        Pending^ := nil;
        if Item.ExceptionVar <> nil then Item.ExceptionVar.Assume(Caught);
        Process.PopHandler;
        Process.PopException;
        Continue;
      end
      else Break;
    end;
    if (DebugContext.StepMode = 2) and (DebugContext.CurrentCode = Self) then
      DebugContext.Paused := True;
    Item := Item.Next;
  end;
  if ((DebugContext.StepMode = 2) or (DebugContext.StepMode = 3)) and
    (DebugContext.CurrentCode = Self) then DebugContext.Paused := True;
  if Caught <> nil then Caught.Free;
end;
{ @end $4633EC }

{ @routine $463620 EF_Min }
procedure EF_Min(av: array of TVarEC; code: TCodeEC);
var i, Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].Assume(av[1]);
  for i := 2 to Count - 1 do
    if av[i].LessThan(av[0]) then
    begin
      av[0].ResetKind(av[i].RealVType);
      av[0].Assume(av[i]);
    end;
end;
{ @end $463620 }

{ @routine $463690 EF_Max }
procedure EF_Max(av: array of TVarEC; code: TCodeEC);
var i, Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].Assume(av[1]);
  for i := 2 to Count - 1 do
    if av[i].GreaterThan(av[0]) then
    begin
      av[0].ResetKind(av[i].RealVType);
      av[0].Assume(av[i]);
    end;
end;
{ @end $463690 }

{ @routine $463728 EF_NewArray }
procedure EF_NewArray(av: array of TVarEC; code: TCodeEC);
var
  i, Count: Integer;
  Dimensions: array of Integer;
begin
  Count := High(av) + 1;
  av[0].ResetKind(vkArray);
  if Count < 2 then Exit;
  Dec(Count);
  SetLength(Dimensions, Count);
  for i := 0 to Count - 1 do
  begin
    if (av[i + 1].RealVType <> vkInt) or (av[i + 1].GetInt < 1) then
    begin
      Dimensions := nil;
      Exit;
    end;
    Dimensions[i] := av[i + 1].GetInt;
  end;
  av[0].CreateArray(Dimensions);
  Dimensions := nil;
end;
{ @end $463728 }

{ @routine $463824 EF_ArrayChange }
procedure EF_ArrayChange(av: array of TVarEC; code: TCodeEC);
var
  Dimension: Integer;
begin
  if High(av) < 2 then Exit;
  Dimension := 0;
  if High(av) >= 3 then Dimension := av[3].GetInt;
  av[1].ResizeArray(av[2].GetInt, Dimension);
end;
{ @end $463824 }

{ @routine $463870 EF_Free }
procedure EF_Free(av: array of TVarEC; code: TCodeEC);
var
  Count, i: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 1 then Exit;
  av[0].Assume(av[1]);
  for i := 0 to Count - 1 do av[i + 1].FreeArray;
end;
{ @end $463870 }

{ @routine $4638BC EF_Count }
procedure EF_Count(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 1 then Exit;
  if av[1].RealVType = vkArray then av[0].SetInt(av[1].GetArray.Count);
  if av[1].RealVType = vkString then av[0].SetInt(Length(av[1].GetString));
end;
{ @end $4638BC }

{ @routine $463958 EF_Copy }
procedure EF_Copy(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1 - 1;
  if Count < 2 then Exit;
  av[1].ResetKind(av[2].RealVType);
  av[1].Assume(av[2]);
end;
{ @end $463958 }

{ @routine $4639A4 EF_Abs }
procedure EF_Abs(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  if av[1].RealVType = vkInt then av[0].SetInt(Abs(av[1].GetInt))
  else av[0].SetFloat(Abs(av[1].GetFloat));
end;
{ @end $4639A4 }

{ @routine $463A08 EF_ArcTan }
procedure EF_ArcTan(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(ArcTan(av[1].GetFloat));
end;
{ @end $463A08 }

{ @routine $463A4C EF_Exp }
procedure EF_Exp(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Exp(av[1].GetFloat));
end;
{ @end $463A4C }

{ @routine $463A90 EF_Ln }
procedure EF_Ln(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Ln(av[1].GetFloat));
end;
{ @end $463A90 }

{ @routine $463AD4 EF_Round }
procedure EF_Round(av: array of TVarEC; code: TCodeEC);
var Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  if av[1].RealVType = vkFloat then av[0].SetInt(Round(av[1].GetFloat))
  else av[0].SetInt(av[1].GetInt);
end;
{ @end $463AD4 }

{ @routine $463B34 EF_Sin }
procedure EF_Sin(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Sin(av[1].GetFloat));
end;
{ @end $463B34 }

{ @routine $463B78 EF_Cos }
procedure EF_Cos(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Cos(av[1].GetFloat));
end;
{ @end $463B78 }

{ @routine $463BBC EF_Sqr }
procedure EF_Sqr(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  if av[1].RealVType = vkInt then av[0].SetInt(av[1].GetInt * av[1].GetInt)
  else av[0].SetFloat(Sqr(av[1].GetFloat));
end;
{ @end $463BBC }

{ @routine $463C2C EF_Sqrt }
procedure EF_Sqrt(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Sqrt(av[1].GetFloat));
end;
{ @end $463C2C }

{ @routine $463C6C EF_Frac }
procedure EF_Frac(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetFloat(Frac(av[1].GetFloat));
end;
{ @end $463C6C }

{ @routine $463CB0 EF_Int }
procedure EF_Int(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetInt(Trunc(av[1].GetFloat));
end;
{ @end $463CB0 }

{ @routine $463CF0 EF_Ord }
procedure EF_Ord(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
begin
  if High(av) < 1 then Exit;
  Text := av[1].GetString;
  if Length(Text) > 0 then av[0].SetInt(Ord(Text[1]));
end;
{ @end $463CF0 }

{ @routine $463D68 EF_Rnd }
procedure EF_Rnd(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetInt(Random(av[1].GetInt));
end;
{ @end $463D68 }

{ @routine $463DA8 EF_Randomize }
procedure EF_Randomize(av: array of TVarEC; code: TCodeEC);
begin
  Randomize;
end;
{ @end $463DA8 }

{ @routine $463DCC EF_RandSeed }
procedure EF_RandSeed(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 1 then Exit;
  av[0].SetInt(RandSeed);
  if Count >= 2 then RandSeed := av[1].GetInt;
end;
{ @end $463DCC }

{ @routine $463E18 EF_SubStr }
procedure EF_SubStr(av: array of TVarEC; code: TCodeEC);
var
  Count, Start, Size, TextLength: Integer;
begin
  Count := High(av) + 1;
  if Count < 3 then Exit;
  TextLength := Length(av[1].GetString);
  Start := av[2].GetInt;
  if Count >= 4 then Size := av[3].GetInt else Size := 1999999999;
  if (Start < 0) or (Start >= TextLength) then
  begin
    av[0].SetString('');
    Exit;
  end;
  if Start + Size > TextLength then Size := TextLength - Start;
  av[0].SetString(Copy(av[1].GetString, Start + 1, Size));
end;
{ @end $463E18 }

{ @routine $463EFC EF_FindSubStr }
procedure EF_FindSubStr(av: array of TVarEC; code: TCodeEC);
var
  Start, TextLength, SearchLength: Integer;
  Text, Search: WideString;
begin
  if High(av) < 2 then Exit;
  Text := av[1].GetString;
  Search := av[2].GetString;
  Start := 0;
  if High(av) >= 3 then Start := av[3].GetInt;
  TextLength := Length(Text);
  SearchLength := Length(Search);
  if TextLength - Start < SearchLength then
  begin
    av[0].SetInt(-1);
    Exit;
  end;
  if (TextLength < 1) and (SearchLength < 1) then
  begin
    av[0].SetInt(-1);
    Exit;
  end;
  while Start <= TextLength - SearchLength do
  begin
    if CompareMem(Pointer(PAnsiChar(Text) + Start * SizeOf(WideChar)), PWideChar(Search), SearchLength * 2) then
    begin
      av[0].SetInt(Start);
      Exit;
    end;
    Inc(Start);
  end;
  av[0].SetInt(-1);
end;
{ @end $463EFC }

{ @routine $464018 EF_Trim }
procedure EF_Trim(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetString(TrimScriptString(av[1].GetString));
end;
{ @end $464018 }

{ @routine $464094 EF_ToAnsi }
procedure EF_ToAnsi(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetString(av[1].GetString);
  av[0].PackAnsiString;
end;
{ @end $464094 }

{ @routine $464108 EF_ToUnicode }
procedure EF_ToUnicode(av: array of TVarEC; code: TCodeEC);
var
  Count: Integer;
begin
  Count := High(av) + 1;
  if Count < 2 then Exit;
  av[0].SetString(av[1].GetString);
  av[0].UnpackAnsiString;
end;
{ @end $464108 }

{ @routine $46417C EF_LowerCase }
procedure EF_LowerCase(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
  AnsiText: AnsiString;
  Start, Count: Integer;
begin
  if High(av) < 1 then Exit;
  Text := av[1].GetString;
  Start := 0;
  if High(av) >= 2 then Start := av[2].GetInt;
  if High(av) >= 3 then Count := av[3].GetInt else Count := Length(Text) - Start;
  if (Start < 0) or (Start + Count > Length(Text)) or (Count < 1) then
  begin
    av[0].SetString(Text);
    Exit;
  end;
  if GetVersion < $80000000 then
  begin
    CharLowerBuffW(PWideChar(Text) + Start, Count);
    av[0].SetString(Text);
  end
  else
  begin
    AnsiText := Text;
    CharLowerBuffA(PAnsiChar(Cardinal(PAnsiChar(AnsiText)) + Cardinal(Start)), Count);
    av[0].SetString(AnsiText);
  end;
end;
{ @end $46417C }

{ @routine $4642A8 EF_UpperCase }
procedure EF_UpperCase(av: array of TVarEC; code: TCodeEC);
var
  Text: WideString;
  AnsiText: AnsiString;
  Start, Count: Integer;
begin
  if High(av) < 1 then Exit;
  Text := av[1].GetString;
  Start := 0;
  if High(av) >= 2 then Start := av[2].GetInt;
  if High(av) >= 3 then Count := av[3].GetInt else Count := Length(Text) - Start;
  if (Start < 0) or (Start + Count > Length(Text)) or (Count < 1) then
  begin
    av[0].SetString(Text);
    Exit;
  end;
  if GetVersion < $80000000 then
  begin
    CharUpperBuffW(PWideChar(Text) + Start, Count);
    av[0].SetString(Text);
  end
  else
  begin
    AnsiText := Text;
    // Native ANSI fallback lowercases even for UpperCase.
    CharLowerBuffA(PAnsiChar(Cardinal(PAnsiChar(AnsiText)) + Cardinal(Start)), Count);
    av[0].SetString(AnsiText);
  end;
end;
{ @end $4642A8 }

{ @routine $4643D4 EF_LoadLibrary }
procedure EF_LoadLibrary(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then Exit;
  av[0].SetDword(LoadLibrary(PAnsiChar(AnsiString(av[1].GetString))));
end;
{ @end $4643D4 }

{ @routine $464460 EF_FreeLibrary }
procedure EF_FreeLibrary(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then Exit;
  av[0].SetInt(Integer(FreeLibrary(av[1].GetDword)));
end;
{ @end $464460 }

{ @routine $46449C EF_LibraryFunction }
procedure EF_LibraryFunction(av: array of TVarEC; code: TCodeEC);
var
  i: Integer;
  Proc: Pointer;
  KindName: WideString;
begin
  if High(av) < 3 then Exit;
  Proc := GetProcAddress(av[1].GetDword, PAnsiChar(AnsiString(av[3].GetString)));
  if Proc = nil then
  begin
    av[0].SetInt(0);
    Exit;
  end;
  av[0].ConvertToKind(vkLibraryFun);
  SetLength(av[0].LibraryFunData, 2 + High(av) - 3);
  if av[2].GetString = 'int' then av[0].LibraryFunData[0] := 1
  else if av[2].GetString = 'dword' then av[0].LibraryFunData[0] := 2
  else av[0].LibraryFunData[0] := 0;
  av[0].LibraryFunData[1] := Dword(Proc);
  for i := 0 to High(av) - 3 - 1 do
  begin
    KindName := av[4 + i].GetString;
    if KindName = 'int' then av[0].LibraryFunData[2 + i] := 1
    else if KindName = 'dword' then av[0].LibraryFunData[2 + i] := 2
    else if KindName = 'str' then av[0].LibraryFunData[2 + i] := 3
    else raise ExceptionExpressionEC.Create('LibraryFunction. Unknown type');
  end;
end;
{ @end $46449C }

{ @routine $4646CC EF_New }
procedure EF_New(av: array of TVarEC; code: TCodeEC);
var
  Found: TVarEC;
  Definition, Instance: TCodeEC;
begin
  if High(av) <> 1 then Exit;
  if code = nil then Exit;
  while (code <> nil) and (code.Parent <> nil) do code := code.Parent;
  Found := code.LocalVar.GetVar(av[1].GetString);
  if Found.RealVType = vkFunction then
  begin
    Definition := Found.GetFunction;
    if not Definition.IsClassDefinition then Exit;
    Instance := TCodeEC.Create;
    Instance.CopyFromFast(Definition);
    Instance.LinkLocalScopes;
    av[0].SetClass(Instance);
  end;
end;
{ @end $4646CC }

{ @routine $464790 EF_Delete }
procedure EF_Delete(av: array of TVarEC; code: TCodeEC);
begin
  if High(av) <> 1 then Exit;
  if av[1].RealVType = vkClass then
  begin
    av[1].GetClass.Free;
    av[1].ResetKind(vkEmpty);
  end;
end;
{ @end $464790 }

{ @routine $4647D8 RegisterExpressionBuiltins }
procedure RegisterExpressionBuiltins(Scope: TVarArrayEC);
begin
  Scope.Add('pi', vkFloat).SetFloat(Pi);
  Scope.Add('min', vkExternFun).SetExternFun(@EF_Min);
  Scope.Add('max', vkExternFun).SetExternFun(@EF_Max);
  Scope.Add('newarray', vkExternFun).SetExternFun(@EF_NewArray);
  Scope.Add('arraychange', vkExternFun).SetExternFun(@EF_ArrayChange);
  Scope.Add('free', vkExternFun).SetExternFun(@EF_Free);
  Scope.Add('count', vkExternFun).SetExternFun(@EF_Count);
  Scope.Add('copy', vkExternFun).SetExternFun(@EF_Copy);
  Scope.Add('abs', vkExternFun).SetExternFun(@EF_Abs);
  Scope.Add('arctan', vkExternFun).SetExternFun(@EF_ArcTan);
  Scope.Add('exp', vkExternFun).SetExternFun(@EF_Exp);
  Scope.Add('ln', vkExternFun).SetExternFun(@EF_Ln);
  Scope.Add('round', vkExternFun).SetExternFun(@EF_Round);
  Scope.Add('sin', vkExternFun).SetExternFun(@EF_Sin);
  Scope.Add('cos', vkExternFun).SetExternFun(@EF_Cos);
  Scope.Add('sqr', vkExternFun).SetExternFun(@EF_Sqr);
  Scope.Add('sqrt', vkExternFun).SetExternFun(@EF_Sqrt);
  Scope.Add('frac', vkExternFun).SetExternFun(@EF_Frac);
  Scope.Add('int', vkExternFun).SetExternFun(@EF_Int);
  Scope.Add('ord', vkExternFun).SetExternFun(@EF_Ord);
  Scope.Add('rnd', vkExternFun).SetExternFun(@EF_Rnd);
  Scope.Add('randomize', vkExternFun).SetExternFun(@EF_Randomize);
  Scope.Add('randseed', vkExternFun).SetExternFun(@EF_RandSeed);
  Scope.Add('substr', vkExternFun).SetExternFun(@EF_SubStr);
  Scope.Add('findsubstr', vkExternFun).SetExternFun(@EF_FindSubStr);
  Scope.Add('trim', vkExternFun).SetExternFun(@EF_Trim);
  Scope.Add('toansi', vkExternFun).SetExternFun(@EF_ToAnsi);
  Scope.Add('tounicode', vkExternFun).SetExternFun(@EF_ToUnicode);
  Scope.Add('lowercase', vkExternFun).SetExternFun(@EF_LowerCase);
  Scope.Add('uppercase', vkExternFun).SetExternFun(@EF_UpperCase);
  Scope.Add('loadlibrary', vkExternFun).SetExternFun(@EF_LoadLibrary);
  Scope.Add('freelibrary', vkExternFun).SetExternFun(@EF_FreeLibrary);
  Scope.Add('libraryfunction', vkExternFun).SetExternFun(@EF_LibraryFunction);
  Scope.Add('new', vkExternFun).SetExternFun(@EF_New);
  Scope.Add('delete', vkExternFun).SetExternFun(@EF_Delete);
end;
{ @end $4647D8 }

end.

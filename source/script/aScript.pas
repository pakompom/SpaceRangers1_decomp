unit aScript;
// Unit bracket (inferred): CODE 0x00535D38..0x0053D1FF; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Buf, EC_Ether, EC_Expression, EC_Str, EC_Struct, EC_Thread, Windows, aGalaxy, aItem, aMyFunction, aPlanet, aShip, Globals;

const
  // Serialized PlaceKind IDs, decoded by TScriptPlace.GetPoint ($5375F8)
  // and ShipInPlace ($5378DC). Keep the stored field as a 32-bit integer.
  spkPolar = 0;
  spkPlanetPosition = 1;
  spkDockedPlanet = 2;
  spkStarDirection = 3;
  spkScriptItem = 4;
  spkGroupCentroid = 5;
  spkCoordinates = 6;

  // Shared script-state IDs, used by the loader and TShip script-order dispatcher.
  sskIdle = 0;
  sskMoveToPlace = 1;
  sskFollowGroup = 2;
  sskJumpToStar = 3;
  sskLandOnPlanet = 4;
  sskNormalAI = 5;

type

  TScriptEconomyMask = set of TPlanetEconomy; // @size $01
  TScriptGovernmentMask = set of TPlanetGovernment; // @size $01

  TScriptStar = class;
  TScriptConstellation = class;
  TScriptShip = class;
  TScriptPlace = class;
  TScriptItem = class;
  TScriptGroup = class;
  TScriptState = class;
  TScriptDialog = class;
  TScriptDialogMsg = class;
  TScriptDialogAnswer = class;
  TScript = class;

  PScriptStarConstraint = ^TScriptStarConstraint;
  TScriptStarConstraint = packed record // @size $20
    OtherStar: TScriptStar; // @offset $00
    RelativeBearingDegrees: Integer; // @offset $04
    MinDistance: Integer; // @offset $08
    MaxDistance: Integer; // @offset $0C
    ConstraintValue10: Integer; // @offset $10
    ConstraintValue14: Integer; // @offset $14
    MaxBearingDeviationPercent: Integer; // @offset $18
    RequireBlackHole: Boolean; // @offset $1C
  end;

  PScriptPlanetBinding = ^TScriptPlanet;
  PScriptShipRequirement = ^TScriptShipOtb;

  TScriptGroupRelation = packed record // @size $18
    Group1: Integer; // @offset $00
    Group2: Integer; // @offset $04
    Relation1To2: Integer; // @offset $08  5 leaves the relation unchanged.
    Relation2To1: Integer; // @offset $0C  5 leaves the relation unchanged.
    MinCombatBalance: Single; // @offset $10
    MaxCombatBalance: Single; // @offset $14
  end;

  TScriptPlanet = packed record // @size $18
    Name: WideString; // @offset $00
    RaceMask: TRaceSet; // @offset $04
    OwnerMask: TOwnerSet; // @offset $05
    EconomyMask: TScriptEconomyMask; // @offset $06
    GovernmentMask: TScriptGovernmentMask; // @offset $07
    MinOrbitPercent: Integer; // @offset $08
    MaxOrbitPercent: Integer; // @offset $0C
    DefinitionText: WideString; // @offset $10  Planet dialog choice text; CollectScriptDialogChoices attaches the owning TScript as its data.
    Planet: TPlanet; // @offset $14
  end;

  TScriptShipOtb = packed record // @size $50
    Count: Integer; // @offset $0
    OwnerMask: TOwnerSet; // @offset $4
    ShipTypeMask: THullShipTypeMask; // @offset $5
    PlayerOnly: Boolean; // @offset $7
    MinSpeed: Integer; // @offset $8
    MaxSpeed: Integer; // @offset $C
    WeaponRequirement: Integer; // @offset $10  1 requires weapons; 2 requires none.
    MinCargoHookLevel: Integer; // @offset $14
    MinFreeCargoSpace: Integer; // @offset $18
    RequirementValue1C: Integer; // @offset $1C
    RequirementValue20: Integer; // @offset $20
    MinTraderStatus: Integer; // @offset $24
    MaxTraderStatus: Integer; // @offset $28
    MinWarriorStatus: Integer; // @offset $2C
    MaxWarriorStatus: Integer; // @offset $30
    MinPirateStatus: Integer; // @offset $34
    MaxPirateStatus: Integer; // @offset $38
    RequirementValue3C: Integer; // @offset $3C
    RequirementValue40: Integer; // @offset $40
    MinStrength: Single; // @offset $44
    MaxStrength: Single; // @offset $48
    StationNames: WideString; // @offset $4C
  end;

  TScriptStar = class(TObjectEx) // @size $20
  public
    Name: WideString; // @offset $04
    ConstellationIndex: Integer; // @offset $08
    LegacyFilter: Boolean; // @offset $0C
    RejectHostilePresence: Boolean; // @offset $0D
    ProtectStar: Boolean; // @offset $0E
    Constraints: array of TScriptStarConstraint; // @offset $10
    Planets: array of TScriptPlanet; // @offset $14
    ShipRequirements: array of TScriptShipOtb; // @offset $18
    Star: TStar; // @offset $1C

    constructor Create; // @addr $537400
    destructor Destroy; override; // @addr $537460
  end;

  TScriptConstellation = class(TObjectEx) // @size $8
  public
    Constellation: TConstellation; // @offset $04

    constructor Create; // @addr $5374B0
    destructor Destroy; override; // @addr $5374E8
  end;

  TScriptShip = class(TObjectEx) // @size $28
  public
    Script: TScript; // @offset $04
    GroupIndex: Integer; // @offset $08
    Ship: TShip; // @offset $0C  Borrowed; destruction invalidates the backlink.
    Data: array[0..3] of Dword; // @offset $10
    State: TScriptState; // @offset $20
    EndState: Boolean; // @offset $24
    Hit: Boolean; // @offset $25
    HitPlayer: Boolean; // @offset $26
    function GetGroup: TScriptGroup; // @addr $537584

    constructor Create; // @addr $537510
    destructor Destroy; override; // @addr $537548
  end;

  TScriptPlace = class(TObjectEx) // @size $2C
  public
    Script: TScript; // @offset $04
    Name: WideString; // @offset $08
    OriginVarName: WideString; // @offset $0C
    OriginStar: TStar; // @offset $10
    PlaceKind: Integer; // @offset $14  spk* serialized place ID.
    AngleOffset: Single; // @offset $18
    DistanceScale: Single; // @offset $1C
    Radius: Integer; // @offset $20
    TargetVarName: WideString; // @offset $24
    TargetValue: Dword; // @offset $28  Kinds 1/2: TPlanet; 3: TStar; 4: TScriptItem; 5: group index; 6: TVarEC for X.
    function GetPoint: TPointF; // @addr $5375F8
    function GetRandomPoint(Seed: Cardinal): TPointF; // @addr $537850
    function ShipInPlace(Ship: TShip): Boolean; // @addr $5378DC @note "Kind 2 requires docking at the bound planet; other kinds require normal space."

    constructor Create; // @addr $537598
    destructor Destroy; override; // @addr $5375D0
  end;

  TScriptItemKind = (sikEquipment = 0, sikWeapon = 1, sikGoods = 2, sikArtefact = 3, sikUselessItem = 4, sikNone = 5); // @size $04
  TScriptItem = class(TObjectEx) // @size $2C
  public
    Name: WideString; // @offset $04
    LocationVarName: WideString; // @offset $08  Group index, planet, or place variable.
    DefinitionKind: TScriptItemKind; // @offset $0C
    DefinitionType: Integer; // @offset $10  Kind-dependent definition index, not a native TItemType.
    Weight: Integer; // @offset $14
    Level: Integer; // @offset $18
    DefinitionValue1C: Integer; // @offset $1C Read from the definition; not consulted by LoadFromBuffer item creation.
    OwnerId: TOwnerId; // @offset $20
    ConfigName: WideString; // @offset $24 TUselessItem configuration key for sikUselessItem.
    Item: TItem; // @offset $28  Borrowed; destruction invalidates the backlink.

    constructor Create; // @addr $537934
    destructor Destroy; override; // @addr $53796C
  end;

  TScriptGroup = class(TObjectEx) // @size $7C
  public
    Name: WideString; // @offset $4
    PlanetVarName: WideString; // @offset $8
    Planet: TPlanet; // @offset $C
    InitialStateIndex: Integer; // @offset $10
    OwnerMask: TOwnerSet; // @offset $14
    ShipTypeMask: THullShipTypeMask; // @offset $15
    MinCount: Integer; // @offset $18
    MaxCount: Integer; // @offset $1C
    MinSpeed: Integer; // @offset $20
    MaxSpeed: Integer; // @offset $24
    WeaponRequirement: Integer; // @offset $28
    MinCargoHookLevel: Integer; // @offset $2C
    MinFreeCargoSpace: Integer; // @offset $30
    RequirementValue34: Integer; // @offset $34
    IncludePlayer: Boolean; // @offset $38
    StationNames: WideString; // @offset $3C
    RequirementValue40: Integer; // @offset $40
    RequirementValue44: Integer; // @offset $44
    RequirementValue48: Integer; // @offset $48
    RequirementValue4C: Integer; // @offset $4C
    MinStrength: Single; // @offset $50
    MaxStrength: Single; // @offset $54
    MinTraderStatus: Integer; // @offset $58
    MaxTraderStatus: Integer; // @offset $5C
    MinWarriorStatus: Integer; // @offset $60
    MaxWarriorStatus: Integer; // @offset $64
    MinPirateStatus: Integer; // @offset $68
    MaxPirateStatus: Integer; // @offset $6C
    MaxDistanceFromPlanet: Integer; // @offset $70
    DialogVariableName: WideString; // @offset $74 Resolved in InitCode.LocalVar before the station greeting.
    Ships: TList; // @offset $78

    constructor Create; // @addr $5379A4
    destructor Destroy; override; // @addr $5379DC
  end;

  TScriptState = class(TObjectEx) // @size $40
  public
    Name: WideString; // @offset $04
    StateKind: Integer; // @offset $08  ssk* serialized state ID.
    TargetVarName: WideString; // @offset $0C
    TargetValue: Dword; // @offset $10  Place, star, planet, or group index according to StateKind.
    EnemyGroupNames: array of WideString; // @offset $14
    EnemyGroupIndices: array of Integer; // @offset $18
    PickupItemVarName: WideString; // @offset $1C
    PickupItem: TScriptItem; // @offset $20
    PickUpNearbyItems: Boolean; // @offset $24
    AuxiliaryText: WideString; // @offset $28  Variable name or compiled source; precise role unresolved.
    AuxiliaryCode: TCodeEC; // @offset $2C  Owned when AuxiliaryText is compiled.
    OnActionText: WideString; // @offset $30
    ActionCode: TCodeEC; // @offset $34  Owned.
    EntryCode: TCodeEC; // @offset $38
    StateCode: TCodeEC; // @offset $3C
    // EntryCode runs before CurShip/EndState refresh; StateCode sees the new context.

    constructor Create; // @addr $537A14
    destructor Destroy; override; // @addr $537A58
  end;

  TScriptDialog = class(TObjectEx) // @size $C
  public
    Name: WideString; // @offset $04
    Code: TCodeEC; // @offset $08

    constructor Create; // @addr $537AE0
    destructor Destroy; override; // @addr $537B24
  end;

  TScriptDialogMsg = class(TObjectEx) // @size $C
  public
    Name: WideString; // @offset $04
    Code: TCodeEC; // @offset $08

    constructor Create; // @addr $537B5C
    destructor Destroy; override; // @addr $537BA0
  end;

  TScriptDialogAnswer = class(TObjectEx) // @size $10
  public
    Name: WideString; // @offset $04
    AnswerCode: TCodeEC; // @offset $08
    ActionCode: TCodeEC; // @offset $0C

    constructor Create; // @addr $537BD8
    destructor Destroy; override; // @addr $537C2C
  end;

  TScript = class(TObjectEx) // @size $5C
  public
    ClassId: Integer; // @offset $4  Script.GAllCntRun filter.
    ScriptFileName: WideString; // @offset $8
    Constellations: TList; // @offset $C  Owns TScriptConstellation entries.
    Stars: TList; // @offset $10  Owns TScriptStar entries.
    Places: TList; // @offset $14  Owns TScriptPlace entries.
    Items: TList; // @offset $18  Owns TScriptItem wrappers, not their live items.
    Groups: TList; // @offset $1C  Owns TScriptGroup entries.
    Ships: TList; // @offset $20  Owns TScriptShip bindings, not ships.
    States: TList; // @offset $24  Owns TScriptState entries.
    Dialogs: TList; // @offset $28  Owns TScriptDialog entries.
    DialogMessages: TList; // @offset $2C  Owns TScriptDialogMsg entries.
    DialogAnswers: TList; // @offset $30  Owns TScriptDialogAnswer entries.
    InitCode: TCodeEC; // @offset $34
    TurnCode: TCodeEC; // @offset $38
    Ether: TEther; // @offset $3C  Owned script-local named integer store; created, cleared and freed with the script.
    CurrentShip: TShip; // @offset $40
    CurrentDialog: Integer; // @offset $44
    CurrentAnswer: Integer; // @offset $48  -1 outside answer generation.
    SkipGreeting: Boolean; // @offset $4C
    GroupRelations: array of TScriptGroupRelation; // @offset $50
    AnchorPlanet: TPlanet; // @offset $54  Optional first planet binding when starting a script.
    EtherIds: TStringsEC; // @offset $58
    procedure Clear; // @addr $537EA4 @note "Frees owned entries but retains list and code containers."
    procedure PublishShipContext(Binding: TScriptShip); // @addr $5380B0 @note "Changes the global CurrentScript context."
    function GetStar(Name: WideString): TScriptStar; // @addr $538124 @note "Raises when absent."
    function GetPlanetBinding(Name: WideString): PScriptPlanetBinding; // @addr $538230 @note "Raises when absent."
    function GetItem(Name: WideString): TScriptItem; // @addr $538378 @note "Raises when absent."
    procedure RunTurnCode; // @addr $5384A8
    procedure RunShipState(Binding: TScriptShip); // @addr $538480
    procedure CallDialog(Index: Integer); // @addr $5384BC
    procedure CallDialogMessage(Index: Integer); // @addr $53852C
    procedure ExecuteDialogAnswer(Index: Integer); // @addr $538608
    procedure BindShip(GroupIndex: Integer; Ship: TShip); // @addr $53867C @note "The player may have multiple script bindings; ordinary ships have one."
    procedure UnbindShip(Ship: TShip); // @addr $538700
    procedure ChangeState(Binding: TScriptShip; StateIndex: Integer); // @addr $5387A8
    procedure SetPlanetRelation(Group: Integer; Planet: TPlanet; Level: TRelationLevel); // @addr $5388D0
    procedure BuildDialogAnswer(Index: Integer); // @addr $538594
    procedure SetGroupRelation(SourceGroup, TargetGroup: Integer; Level: TRelationLevel); // @addr $53881C
    function TryBindStars(StarIndex: Integer): Boolean; // @addr $538938 @note "Recursively assigns remaining stars and their planets; earlier star bindings must already exist."
    function LoadFromBuffer(Buffer: TBufEC; AnchorStar: TStar; FirstPlanet: TPlanet; CreateObjects: Boolean): Boolean; // @addr $53935C @note "Accepts script-definition versions 5 through 8."
    function LoadFromFile(FileName: WideString; AnchorStar: TStar; FirstPlanet: TPlanet; CreateObjects: Boolean): Boolean; // @addr $53C6E0
    procedure LoadState(Buffer: TBufEC); // @addr $53CC08
    procedure SaveState(Buffer: TBufEC); // @addr $53C7C0 @note "Compiled instructions are excluded."
    procedure ResolveLoadedReferences; // @addr $53D040 @note "Resolves saved ship IDs and restores ship, place, and state bindings after LoadState."

    constructor Create; // @addr $537C74
    destructor Destroy; override; // @addr $537D7C
  end;

function DecodeScriptRaceMask(Value: Cardinal): TRaceSet; // @addr $536864
function DecodeScriptOwnerMask(Value: Cardinal): TOwnerSet; // @addr $536924
function DecodeScriptEconomyMask(Value: Cardinal): TScriptEconomyMask; // @addr $536A4C
function DecodeScriptGovernmentMask(Value: Cardinal): TScriptGovernmentMask; // @addr $536AD0
function DecodeScriptShipTypeMask(Value: Cardinal): THullShipTypeMask; // @addr $536B90
function DecodeScriptItemOwner(Value: Cardinal): TOwnerId; // @addr $536D38
function DecodeScriptRelationLevel(Value: Cardinal): TRelationLevel; // @addr $536D70
function ScriptShipMatchesType(Ship: TShip; ShipTypeMask: THullShipTypeMask; StationNames: WideString): Boolean; // @addr $536DA0
function CollectScriptCandidateShips(Star: TStar): TList; // @addr $536F18
function FindScriptGroupCandidate(Candidates: TList; Group: TScriptGroup): TShip; // @addr $5371A0
var
  CurrentScript: TScript; // @addr $61CF90
  ScriptFunctionScope: TVarArrayEC; // @addr $61CF94
  ScriptProcess: TCodeProcessEC; // @addr $61CF98

procedure InitializeScriptEngine; // @addr $536318
procedure FinalizeScriptEngine; // @addr $536358
function IsStarProtectedByScript(Star: TStar): Boolean; // @addr $5367DC

function ScriptDefinitionBit(Value: Cardinal; BitIndex: Integer): Boolean; // @addr $53685C

function GetScriptShipBindingForContext(Ship: TShip; Script: TScript): TScriptShip; // @addr $5373A4

function TryStartScriptByName(AnchorStar: TStar; AnchorPlanet: TPlanet; Name: WideString): Boolean; // @addr $536474
function TryStartScriptInstanceFromTemplate(AnchorStar: TStar; AnchorPlanet: TPlanet; TemplateIndex: Integer): Boolean; // @addr $5364D8

procedure CompileScriptTemplateCondition(TemplateIndex: Integer); // @addr $536598

procedure RunStarTransitionScript(Star: TStar; Takeoff: Integer); // @addr $536390

implementation
// @unit-initialization $53D1F8
// @unit-finalization $53D1C8
uses aRuins, aKling, EC_Cache, SysUtils, EC_CacheBuf, aConst, GR_Main, Math, GI_MessageLoop, aTranclucator, aRanger, aPlayer, aGalaxy, aShip, aItem, aWarrior, aScriptFun, GlobalsV;

{ @routine $536318 InitializeScriptEngine }
procedure InitializeScriptEngine;
begin
  ScriptProcess := TCodeProcessEC.Create;
  CurrentScript := nil;
  ScriptFunctionScope := TVarArrayEC.Create;
  RegisterExpressionBuiltins(ScriptFunctionScope);
  InitializeScriptBuiltinsAndConstants(ScriptFunctionScope);
end;
{ @end $536318 }

{ @routine $536358 FinalizeScriptEngine }
procedure FinalizeScriptEngine;
begin
  if ScriptFunctionScope <> nil then
  begin
    ScriptFunctionScope.Free;
    ScriptFunctionScope := nil;
  end;
  if ScriptProcess <> nil then
  begin
    ScriptProcess.Free;
    ScriptProcess := nil;
  end;
end;
{ @end $536358 }

{ @routine $536390 RunStarTransitionScript }
procedure RunStarTransitionScript(Star: TStar; Takeoff: Integer);
var Templates: TList; I: Integer; Template: TScriptTemplUnit;
begin
  SharedScriptVariables.GetVar('GRunFrom').SetInt(Takeoff);
  SharedScriptVariables.GetVar('GRunStar').SetDword(Cardinal(Star));
  Templates := TList.Create;
  CollectInactiveScriptTemplates(Templates);
  for I := 0 to Templates.Count - 1 do
  begin
    Template := Templates[I];
    ScriptTemplateStartRequested := False;
    Template.ConditionCode.Run(ScriptProcess);
    if ScriptTemplateStartRequested then TryStartScriptInstanceFromTemplate(Star, nil, ScriptTemplates.IndexOf(Template));
  end;
  Templates.Free;
end;
{ @end $536390 }

{ @routine $536474 TryStartScriptByName }
function TryStartScriptByName(AnchorStar: TStar; AnchorPlanet: TPlanet; Name: WideString): Boolean;
var Index: Integer;
begin
  Index := FindScriptTemplateIndex(Name);
  if Index < 0 then Result := False
  else Result := TryStartScriptInstanceFromTemplate(AnchorStar, AnchorPlanet, Index);
end;
{ @end $536474 }

{ @routine $5364D8 TryStartScriptInstanceFromTemplate }
function TryStartScriptInstanceFromTemplate(AnchorStar: TStar; AnchorPlanet: TPlanet; TemplateIndex: Integer): Boolean;
var
  Template: TScriptTemplUnit;
  Script: TScript;
  Index: Integer;
begin
  Template := TScriptTemplUnit(ScriptTemplates[TemplateIndex]);
  Script := TScript.Create;
  Galaxy.Scripts.Add(Script);
  Template.ActiveScriptIndex := Galaxy.Scripts.Count - 1;
  Script.ClassId := Template.ConfigValue;
  if Script.LoadFromFile(Template.FileName, AnchorStar, AnchorPlanet, True) then
  begin
    Template.LastTurn := Galaxy.CurrentTurn;
    Inc(Template.UseCount);
    Result := True;
  end
  else
  begin
    Index := Galaxy.Scripts.IndexOf(Script);
    if Index >= 0 then
    begin
      Galaxy.Scripts.Delete(Index);
      Script.Free;
    end;
    Template.ActiveScriptIndex := -1;
    Result := False;
  end;
end;
{ @end $5364D8 }

{ @routine $536598 CompileScriptTemplateCondition }
procedure CompileScriptTemplateCondition(TemplateIndex: Integer);
var
  Template: TScriptTemplUnit;
  Control: TCBufControlEC;
  CachedBuffer: TCBufEC;
  Buffer: TBufEC;
  Analyzer: TCodeAnalyzerEC;
  ErrorText: WideString;
  Version: Cardinal;
begin
  Template := TScriptTemplUnit(ScriptTemplates[TemplateIndex]);
  Control := nil;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(Template.FileName);
    CachedBuffer := AcquireOrCreateBuffer(Control);
    Buffer := CachedBuffer.Buffer;
    Version := Buffer.GetUInt32;
    if Version <> 5 then
    begin
      RaiseWideMessage('Script file incorrect version');
      Exit;
    end;
    Buffer.GetUInt32;
    GlobalScriptVariables.AppendFromBuffer(Buffer);
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := Template.ConditionCode.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('ScriptFirstLoad.Compiler. Error=' + ErrorText);
    Template.ConditionCode.LocalVar.Add('GScriptName', vkString).SetString(Template.Name);
  finally
    if Control <> nil then
    begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $536598 }

{ @routine $5367DC IsStarProtectedByScript }
function IsStarProtectedByScript(Star: TStar): Boolean;
var
  I, J: Integer;
  Script: TScript;
  Binding: TScriptStar;
begin
  for I := 0 to Galaxy.Scripts.Count - 1 do
  begin
    Script := TScript(Galaxy.Scripts[I]);
    for J := 0 to Script.Stars.Count - 1 do
    begin
      Binding := TScriptStar(Script.Stars[J]);
      if Binding.ProtectStar and (Binding.Star = Star) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
  Result := False;
end;
{ @end $5367DC }

{ @routine $53685C ScriptDefinitionBit }
function ScriptDefinitionBit(Value: Cardinal; BitIndex: Integer): Boolean;
begin
  Result := Boolean((Value shr BitIndex) and 1);
end;
{ @end $53685C }

{ @routine $536864 DecodeScriptRaceMask }
function DecodeScriptRaceMask(Value: Cardinal): TRaceSet;
begin
  if not ScriptDefinitionBit(Value, 0) then
  begin
    Result := [raMaloc..raGaal];
    Exit;
  end;
  Result := [];
  if ScriptDefinitionBit(Value, 1) then Result := Result + [raMaloc];
  if ScriptDefinitionBit(Value, 2) then Result := Result + [raPeleng];
  if ScriptDefinitionBit(Value, 3) then Result := Result + [raPeople];
  if ScriptDefinitionBit(Value, 4) then Result := Result + [raFei];
  if ScriptDefinitionBit(Value, 5) then Result := Result + [raGaal];
end;
{ @end $536864 }

{ @routine $536924 DecodeScriptOwnerMask }
function DecodeScriptOwnerMask(Value: Cardinal): TOwnerSet;
begin
  if not ScriptDefinitionBit(Value, 0) then
  begin
    Result := [oiMaloc..oiNone];
    Exit;
  end;
  Result := [];
  if ScriptDefinitionBit(Value, 1) then Result := Result + [oiMaloc];
  if ScriptDefinitionBit(Value, 2) then Result := Result + [oiPeleng];
  if ScriptDefinitionBit(Value, 3) then Result := Result + [oiPeople];
  if ScriptDefinitionBit(Value, 4) then Result := Result + [oiFei];
  if ScriptDefinitionBit(Value, 5) then Result := Result + [oiGaal];
  if ScriptDefinitionBit(Value, 6) then Result := Result + [oiKling];
  if ScriptDefinitionBit(Value, 7) then Result := Result + [oiNone];
  if ScriptDefinitionBit(Value, 8) then Result := Result + [Player.OwnerId];
end;
{ @end $536924 }

{ @routine $536A4C DecodeScriptEconomyMask }
function DecodeScriptEconomyMask(Value: Cardinal): TScriptEconomyMask;
begin
  if not ScriptDefinitionBit(Value, 0) then
  begin
    Result := [peAgriculture..peIndustrial];
    Exit;
  end;
  Result := [];
  if ScriptDefinitionBit(Value, 1) then Result := Result + [peAgriculture];
  if ScriptDefinitionBit(Value, 2) then Result := Result + [peIndustrial];
  if ScriptDefinitionBit(Value, 3) then Result := Result + [peMixed];
end;
{ @end $536A4C }

{ @routine $536AD0 DecodeScriptGovernmentMask }
function DecodeScriptGovernmentMask(Value: Cardinal): TScriptGovernmentMask;
begin
  if not ScriptDefinitionBit(Value, 0) then
  begin
    Result := [pgAnarchy..pgDemocracy];
    Exit;
  end;
  Result := [];
  if ScriptDefinitionBit(Value, 1) then Result := Result + [pgAnarchy];
  if ScriptDefinitionBit(Value, 2) then Result := Result + [pgDictatorship];
  if ScriptDefinitionBit(Value, 3) then Result := Result + [pgMonarchy];
  if ScriptDefinitionBit(Value, 4) then Result := Result + [pgRepublic];
  if ScriptDefinitionBit(Value, 5) then Result := Result + [pgDemocracy];
end;
{ @end $536AD0 }

{ @routine $536B90 DecodeScriptShipTypeMask }
function DecodeScriptShipTypeMask(Value: Cardinal): THullShipTypeMask;
begin
  if not ScriptDefinitionBit(Value, 0) then
  begin
    Result := [htRanger..htRoggit,htTranclucator,htStation];
    Exit;
  end;
  Result := [];
  if ScriptDefinitionBit(Value, 1) then Result := Result + [htRanger];
  if ScriptDefinitionBit(Value, 2) then Result := Result + [htWarrior];
  if ScriptDefinitionBit(Value, 3) then Result := Result + [htPirate];
  if ScriptDefinitionBit(Value, 4) then Result := Result + [htTransport];
  if ScriptDefinitionBit(Value, 5) then Result := Result + [htLiner];
  if ScriptDefinitionBit(Value, 6) then Result := Result + [htDiplomat];
  if ScriptDefinitionBit(Value, 7) then Result := Result + [htMakhpella];
  if ScriptDefinitionBit(Value, 8) then Result := Result + [htEgemon];
  if ScriptDefinitionBit(Value, 9) then Result := Result + [htNondus];
  if ScriptDefinitionBit(Value, 10) then Result := Result + [htKatauri];
  if ScriptDefinitionBit(Value, 11) then Result := Result + [htRoggit];
  if ScriptDefinitionBit(Value, 12) then Result := Result + [htTranclucator];
end;
{ @end $536B90 }

{ @routine $536D38 DecodeScriptItemOwner }
function DecodeScriptItemOwner(Value: Cardinal): TOwnerId;
begin
  if Value = 0 then Result := oiMaloc
  else if Value = 1 then Result := oiPeleng
  else if Value = 2 then Result := oiPeople
  else if Value = 3 then Result := oiFei
  else if Value = 4 then Result := oiGaal
  else if Value = 5 then Result := oiKling
  else Result := oiNone;
end;
{ @end $536D38 }

{ @routine $536D70 DecodeScriptRelationLevel }
function DecodeScriptRelationLevel(Value: Cardinal): TRelationLevel;
begin
  if Value = 0 then Result := rlHostile
  else if Value = 1 then Result := rlBad
  else if Value = 2 then Result := rlNormal
  else if Value = 3 then Result := rlGood
  else if Value = 4 then Result := rlExcellent
  else Result := rlHostile;
end;
{ @end $536D70 }

{ @routine $536DA0 ScriptShipMatchesType }
function ScriptShipMatchesType(Ship: TShip; ShipTypeMask: THullShipTypeMask; StationNames: WideString): Boolean;
var
  Name: WideString;
  I, Count: Integer;
begin
  Result := False;
  if not (ShipToHullType(Ship) in ShipTypeMask) then Exit;
  if (Ship is TRuins) and (htStation in ShipTypeMask) then begin
    Name := '';
    if Ship.ShipType = t_PirateBase then Name := 'PB'
    else if Ship.ShipType = t_RangerCenter then Name := 'RC'
    else if Ship.ShipType = t_MilitaryBase then Name := 'WB'
    else if Ship.ShipType = t_ScientificBase then Name := 'SB';
    if Name = '' then Exit;
    Count := CountDelimitedPartsW(StationNames, ',');
    I := 0;
    while I < Count do begin
      if ExtractDelimitedPartW(StationNames, I, ',') = Name then Break;
      Inc(I);
    end;
    if I >= Count then Exit;
  end;
  Result := True;
end;
{ @end $536DA0 }

{ @routine $536F18 CollectScriptCandidateShips }
function CollectScriptCandidateShips(Star: TStar): TList;
var
  Ship, OtherShip: TShip;
  Planet: TPlanet;
  Candidates: TList;
  I, J, K, ShipCount: Integer;
begin
  Candidates := TList.Create;
  ShipCount := Star.Ships.Count;
  for I := 0 to ShipCount - 1 do begin
    Ship := TShip(Star.Ships[I]);
    if Ship.LiberationGroup <> nil then Continue;
    if Ship.ScriptShip <> nil then Continue;
    if (Ship <> Player) and Ship.InHyperspace then Continue;
    if (Ship <> Player) and (Ship <> KlingMotherShip) and not (Ship is TRuins) and
      (Ship.EnemyShip <> nil) and (Ship.EnemyShip.CurrentStar = Ship.CurrentStar) then Continue;
    if (Ship <> Player) and (Ship <> KlingMotherShip) and not (Ship is TRuins) and
      (Ship.PartnerShip <> nil) then Continue;
    if (Ship <> Player) and (Ship <> KlingMotherShip) and not (Ship is TRuins) and
      (Ship.Hull.HullPoints < Ship.Hull.Weight div 2) then Continue;
    // Excludes even the player inside this radius; only the mother ship is exempt.
    if (Ship <> KlingMotherShip) and Ship.InNormalSpace and
      (Sqr(Star.SafeRadius) > PointDistanceSquared(Ship.Position, MakePointF(0, 0))) then Continue;
    if (Ship <> KlingMotherShip) and (Ship <> Player) then begin
      for J := 0 to ShipCount - 1 do begin
        OtherShip := TShip(Star.Ships[J]);
        if OtherShip = Ship then Continue;
        if (Ship = OtherShip.EnemyShip) or (Ship = OtherShip.PartnerShip) then Break;
      end;
      if J < ShipCount then Continue;
    end;
    Candidates.Add(Ship);
  end;
  for K := 0 to Star.Planets.Count - 1 do begin
    Planet := TPlanet(Star.Planets[K]);
    ShipCount := Planet.Warriors.Count;
    for I := 0 to ShipCount - 1 do begin
      Ship := TShip(Planet.Warriors[I]);
      if Ship.ScriptShip <> nil then Continue;
      if Candidates.IndexOf(Ship) >= 0 then Continue;
      if Ship.Hull.HullPoints < Ship.Hull.Weight div 2 then Continue;
      Candidates.Add(Ship);
    end;
  end;
  Result := Candidates;
end;
{ @end $536F18 }

{ @routine $5371A0 FindScriptGroupCandidate }
function FindScriptGroupCandidate(Candidates: TList; Group: TScriptGroup): TShip;
var
  I: Integer;
  Ship: TShip;
  Point: TPointF;
  DistanceSquared: Single;
begin
  for I := 0 to Candidates.Count - 1 do
  begin
    Ship := TShip(Candidates[I]);
    if Ship.LiberationGroup <> nil then Continue;
    if not (Ship.OwnerId in Group.OwnerMask) then Continue;
    if not ScriptShipMatchesType(Ship, Group.ShipTypeMask, Group.StationNames) then Continue;
    if Player = Ship then Continue;
    if (Ship <> KlingMotherShip) and
      ((Ship.Speed < Group.MinSpeed) or (Ship.Speed > Group.MaxSpeed)) then Continue;
    if (Group.WeaponRequirement = 1) and (Ship.WeaponCount <= 0) then Continue;
    if (Group.WeaponRequirement = 2) and (Ship.WeaponCount > 0) then Continue;
    if Group.MinCargoHookLevel > 0 then
    begin
      if Ship.CargoHook = nil then Continue;
      if Ship.CargoHook.GetLevel + 1 < Group.MinCargoHookLevel then Continue;
    end;
    if Ship.CargoFreeSpace < Group.MinFreeCargoSpace then Continue;
    if Ship is TRanger then
    begin
      if (TRanger(Ship).CareerStatus[rcTrader] < Group.MinTraderStatus) or
        (TRanger(Ship).CareerStatus[rcTrader] > Group.MaxTraderStatus) then Continue;
      if (TRanger(Ship).CareerStatus[rcWarrior] < Group.MinWarriorStatus) or
        (TRanger(Ship).CareerStatus[rcWarrior] > Group.MaxWarriorStatus) then Continue;
      if (TRanger(Ship).CareerStatus[rcPirate] < Group.MinPirateStatus) or
        (TRanger(Ship).CareerStatus[rcPirate] > Group.MaxPirateStatus) then Continue;
    end;
    if (Group.MaxDistanceFromPlanet < 10000) and (Ship.CurrentPlanet <> Group.Planet) then
    begin
      Point := Group.Planet.GetPosition;
      if Ship.CurrentPlanet <> nil then DistanceSquared := PointDistanceSquared(Point, Ship.CurrentPlanet.GetPosition)
      else DistanceSquared := PointDistanceSquared(Point, Ship.Position);
      if DistanceSquared > Sqr(Group.MaxDistanceFromPlanet) then Continue;
    end;
    if (Group.MinStrength <> 0) or (Group.MaxStrength <> 0) then
    begin
      if Ship.StrengthInBestRanger < Group.MinStrength then Continue;
      if Ship.StrengthInBestRanger > Group.MaxStrength then Continue;
    end;
    Result := Ship;
    Exit;
  end;
  Result := nil;
end;
{ @end $5371A0 }

{ @routine $5373A4 GetScriptShipBindingForContext }
function GetScriptShipBindingForContext(Ship: TShip; Script: TScript): TScriptShip;
var
  I: Integer;
begin
  Result := nil;
  if Ship is TPlayer then
  begin
    for I := 0 to TPlayer(Ship).ScriptShipBindings.Count - 1 do
    begin
      Result := TScriptShip(TPlayer(Ship).ScriptShipBindings[I]);
      if Result.Script = Script then Break;
      Result := nil;
    end;
  end
  else Result := TScriptShip(Ship.ScriptShip);
end;
{ @end $5373A4 }

{ @routine $537400 TScriptStar_Create }
constructor TScriptStar.Create;
begin
  inherited Create;
  Constraints := nil;
  Planets := nil;
  ShipRequirements := nil;
end;
{ @end $537400 }

{ @routine $537460 TScriptStar_Destroy }
destructor TScriptStar.Destroy;
begin
  ShipRequirements := nil;
  Planets := nil;
  Constraints := nil;
  inherited Destroy;
end;
{ @end $537460 }

{ @routine $5374B0 TScriptConstellation_Create }
constructor TScriptConstellation.Create;
begin
  inherited Create;
end;
{ @end $5374B0 }

{ @routine $5374E8 TScriptConstellation_Destroy }
destructor TScriptConstellation.Destroy;
begin
  inherited Destroy;
end;
{ @end $5374E8 }

{ @routine $537510 TScriptShip_Create }
constructor TScriptShip.Create;
begin
  inherited Create;
end;
{ @end $537510 }

{ @routine $537548 TScriptShip_Destroy }
destructor TScriptShip.Destroy;
begin
  if Ship <> nil then
  begin
    Ship.ScriptShip := nil;
    Ship := nil;
  end;
  inherited Destroy;
end;
{ @end $537548 }

{ @routine $537584 TScriptShip_GetGroup }
function TScriptShip.GetGroup: TScriptGroup;
begin
  Result := TScriptGroup(Script.Groups[GroupIndex]);
end;
{ @end $537584 }

{ @routine $537598 TScriptPlace_Create }
constructor TScriptPlace.Create;
begin
  inherited Create;
end;
{ @end $537598 }

{ @routine $5375D0 TScriptPlace_Destroy }
destructor TScriptPlace.Destroy;
begin
  inherited Destroy;
end;
{ @end $5375D0 }
{ @routine $5375F8 TScriptPlace_GetPoint }
function TScriptPlace.GetPoint: TPointF;
var
  Distance, Angle: Single;
  I, Count: Integer;
  Binding: TScriptShip;
  Center: TPointF;
begin
  if PlaceKind = spkPolar then
  begin
    Angle := HeadingDegreesToRadians(AngleOffset);
    Distance := OriginStar.MapDiameter / 2 * DistanceScale;
    Result.X := System.Sin(Angle) * Distance;
    Result.Y := System.Cos(Angle) * -Distance;
  end
  else if PlaceKind = spkPlanetPosition then Result := TPlanet(TargetValue).GetPosition
  else if PlaceKind = spkDockedPlanet then Result := MakePointF(0, 0)
  else if PlaceKind = spkStarDirection then
  begin
    Angle := HeadingDegreesToRadians(WrapHeadingDegrees(PointBearingDegrees(OriginStar.Position, TStar(TargetValue).Position) + AngleOffset));
    Distance := OriginStar.MapDiameter / 2 * DistanceScale;
    Result.X := System.Sin(Angle) * Distance;
    Result.Y := System.Cos(Angle) * -Distance;
  end
  else if PlaceKind = spkScriptItem then
  begin
    if TScriptItem(TargetValue).Item = nil then Result := MakePointF(0, 0)
    else Result := TScriptItem(TargetValue).Item.Position;
  end
  else if PlaceKind = spkGroupCentroid then
  begin
    Count := 0;
    Center := MakePointF(0, 0);
    for I := 0 to Script.Ships.Count - 1 do
    begin
      Binding := TScriptShip(Script.Ships[I]);
      if Binding.GroupIndex = Integer(TargetValue) then
      begin
        Center := AddPointsF(Center, Binding.Ship.Position);
        Inc(Count);
      end;
    end;
    if Count < 1 then Result := MakePointF(0, 0)
    else
    begin
      Center.X := Center.X / Count;
      Center.Y := Center.Y / Count;
      Angle := HeadingDegreesToRadians(WrapHeadingDegrees(PointBearingDegrees(Center, MakePointF(0, 0)) + AngleOffset));
      Distance := OriginStar.MapDiameter / 2 * DistanceScale;
      Result.X := System.Sin(Angle) * Distance + Center.X;
      Result.Y := Center.Y - System.Cos(Angle) * Distance;
    end;
  end;
end;
{ @end $5375F8 }

{ @routine $537850 TScriptPlace_GetRandomPoint }
function TScriptPlace.GetRandomPoint(Seed: Cardinal): TPointF;
var
  Angle: Single;
begin
  Result := GetPoint;
  if Radius <> 0 then
  begin
    Angle := HeadingDegreesToRadians(SeededRandomIntRange(0, 360, Seed));
    Result.X := Result.X + System.Sin(Angle) * (Radius * 0.9);
    Result.Y := Result.Y + -System.Cos(Angle) * (Radius * 0.9);
  end;
end;
{ @end $537850 }

{ @routine $5378DC TScriptPlace_ShipInPlace }
function TScriptPlace.ShipInPlace(Ship: TShip): Boolean;
begin
  if PlaceKind = spkDockedPlanet then Result := Ship.CurrentPlanet = TPlanet(TargetValue)
  else
  begin
    if not Ship.InNormalSpace then Result := False
    else Result := PointDistanceSquared(GetPoint, Ship.Position) <= Sqr(Radius);
  end;
end;
{ @end $5378DC }

{ @routine $537934 TScriptItem_Create }
constructor TScriptItem.Create;
begin
  inherited Create;
end;
{ @end $537934 }

{ @routine $53796C TScriptItem_Destroy }
destructor TScriptItem.Destroy;
begin
  if Item <> nil then
  begin
    Item.ScriptItem := nil;
    Item := nil;
  end;
  inherited Destroy;
end;
{ @end $53796C }

{ @routine $5379A4 TScriptGroup_Create }
constructor TScriptGroup.Create;
begin
  inherited Create;
end;
{ @end $5379A4 }

{ @routine $5379DC TScriptGroup_Destroy }
destructor TScriptGroup.Destroy;
begin
  if Ships <> nil then
  begin
    Ships.Free;
    Ships := nil;
  end;
  inherited Destroy;
end;
{ @end $5379DC }

{ @routine $537A14 TScriptState_Create }
constructor TScriptState.Create;
begin
  inherited Create;
  StateCode := TCodeEC.Create;
end;
{ @end $537A14 }

{ @routine $537A58 TScriptState_Destroy }
destructor TScriptState.Destroy;
begin
  EnemyGroupNames := nil;
  EnemyGroupIndices := nil;
  if StateCode <> nil then
  begin
    StateCode.Free;
    StateCode := nil;
  end;
  if AuxiliaryCode <> nil then
  begin
    AuxiliaryCode.Free;
    AuxiliaryCode := nil;
  end;
  if ActionCode <> nil then
  begin
    ActionCode.Free;
    ActionCode := nil;
  end;
  if EntryCode <> nil then
  begin
    EntryCode.Free;
    EntryCode := nil;
  end;
  inherited Destroy;
end;
{ @end $537A58 }

{ @routine $537AE0 TScriptDialog_Create }
constructor TScriptDialog.Create;
begin
  inherited Create;
  Code := TCodeEC.Create;
end;
{ @end $537AE0 }

{ @routine $537B24 TScriptDialog_Destroy }
destructor TScriptDialog.Destroy;
begin
  if Code <> nil then
  begin
    Code.Free;
    Code := nil;
  end;
  inherited Destroy;
end;
{ @end $537B24 }

{ @routine $537B5C TScriptDialogMsg_Create }
constructor TScriptDialogMsg.Create;
begin
  inherited Create;
  Code := TCodeEC.Create;
end;
{ @end $537B5C }

{ @routine $537BA0 TScriptDialogMsg_Destroy }
destructor TScriptDialogMsg.Destroy;
begin
  if Code <> nil then
  begin
    Code.Free;
    Code := nil;
  end;
  inherited Destroy;
end;
{ @end $537BA0 }

{ @routine $537BD8 TScriptDialogAnswer_Create }
constructor TScriptDialogAnswer.Create;
begin
  inherited Create;
  AnswerCode := TCodeEC.Create;
  ActionCode := TCodeEC.Create;
end;
{ @end $537BD8 }

{ @routine $537C2C TScriptDialogAnswer_Destroy }
destructor TScriptDialogAnswer.Destroy;
begin
  if AnswerCode <> nil then
  begin
    AnswerCode.Free;
    AnswerCode := nil;
  end;
  if ActionCode <> nil then
  begin
    ActionCode.Free;
    ActionCode := nil;
  end;
  inherited Destroy;
end;
{ @end $537C2C }

{ @routine $537C74 TScript_Create }
constructor TScript.Create;
begin
  inherited Create;
  InitCode := TCodeEC.Create;
  TurnCode := TCodeEC.Create;
  Constellations := TList.Create;
  Stars := TList.Create;
  Places := TList.Create;
  Items := TList.Create;
  Groups := TList.Create;
  Ships := TList.Create;
  States := TList.Create;
  Dialogs := TList.Create;
  DialogMessages := TList.Create;
  DialogAnswers := TList.Create;
  Ether := TEther.Create;
  EtherIds := TStringsEC.Create;
end;
{ @end $537C74 }

{ @routine $537D7C TScript_Destroy }
destructor TScript.Destroy;
begin
  Clear;
  if Constellations <> nil then
  begin
    Constellations.Free;
    Constellations := nil;
  end;
  if Groups <> nil then
  begin
    Groups.Free;
    Groups := nil;
  end;
  if Items <> nil then
  begin
    Items.Free;
    Items := nil;
  end;
  if Places <> nil then
  begin
    Places.Free;
    Places := nil;
  end;
  if Stars <> nil then
  begin
    Stars.Free;
    Stars := nil;
  end;
  if States <> nil then
  begin
    States.Free;
    States := nil;
  end;
  if Ships <> nil then
  begin
    Ships.Free;
    Ships := nil;
  end;
  if Dialogs <> nil then
  begin
    Dialogs.Free;
    Dialogs := nil;
  end;
  if DialogMessages <> nil then
  begin
    DialogMessages.Free;
    DialogMessages := nil;
  end;
  if DialogAnswers <> nil then
  begin
    DialogAnswers.Free;
    DialogAnswers := nil;
  end;
  if TurnCode <> nil then
  begin
    TurnCode.Free;
    TurnCode := nil;
  end;
  if InitCode <> nil then
  begin
    InitCode.Free;
    InitCode := nil;
  end;
  if Ether <> nil then
  begin
    Ether.Free;
    Ether := nil;
  end;
  if EtherIds <> nil then
  begin
    EtherIds.Free;
    EtherIds := nil;
  end;
  GroupRelations := nil;
  inherited Destroy;
end;
{ @end $537D7C }

{ @routine $537EA4 TScript_Clear }
procedure TScript.Clear;
var
  I: Integer;
  StateCount: Integer;
  State: TScriptState;
  Binding: TScriptShip;
  Dialog: TScriptDialog;
begin
  if States <> nil then
  begin
    StateCount := States.Count;
    for I := 0 to StateCount - 1 do
    begin
      State := TScriptState(States[I]);
      State.Free;
    end;
    States.Clear;
  end;
  if Groups <> nil then
  begin
    for I := 0 to Groups.Count - 1 do TObject(Groups[I]).Free;
    Groups.Clear;
  end;
  if Items <> nil then
  begin
    for I := 0 to Items.Count - 1 do TObject(Items[I]).Free;
    Items.Clear;
  end;
  if Places <> nil then
  begin
    for I := 0 to Places.Count - 1 do TObject(Places[I]).Free;
    Places.Clear;
  end;
  if Stars <> nil then
  begin
    for I := 0 to Stars.Count - 1 do TObject(Stars[I]).Free;
    Stars.Clear;
  end;
  if Constellations <> nil then
  begin
    for I := 0 to Constellations.Count - 1 do TObject(Constellations[I]).Free;
    Constellations.Clear;
  end;
  if Ships <> nil then
  begin
    for I := 0 to Ships.Count - 1 do
    begin
      Binding := TScriptShip(Ships[I]);
      Binding.Free;
    end;
    Ships.Clear;
  end;
  if Dialogs <> nil then
  begin
    for I := 0 to Dialogs.Count - 1 do
    begin
      Dialog := TScriptDialog(Dialogs[I]);
      Dialog.Free;
    end;
    Dialogs.Clear;
  end;
  if DialogMessages <> nil then
  begin
    for I := 0 to DialogMessages.Count - 1 do TObject(DialogMessages[I]).Free;
    DialogMessages.Clear;
  end;
  if DialogAnswers <> nil then
  begin
    for I := 0 to DialogAnswers.Count - 1 do TObject(DialogAnswers[I]).Free;
    DialogAnswers.Clear;
  end;
  if Ether <> nil then Ether.Clear;
  if InitCode <> nil then InitCode.Clear;
  if TurnCode <> nil then TurnCode.Clear;
  if EtherIds <> nil then EtherIds.Clear;
  GroupRelations := nil;
end;
{ @end $537EA4 }

{ @routine $5380B0 TScript_PublishShipContext }
procedure TScript.PublishShipContext(Binding: TScriptShip);
begin
  CurrentShip := Binding.Ship;
  CurrentScript := Self;
  InitCode.LocalVar.GetVar('EndState').SetInt(Ord(Binding.EndState));
  { Native rereads Binding.Ship after GetVar, rather than using CurrentShip. }
  InitCode.LocalVar.GetVar('CurShip').SetDword(Cardinal(Binding.Ship));
end;
{ @end $5380B0 }

{ @routine $538124 TScript_GetStar }
function TScript.GetStar(Name: WideString): TScriptStar;
var
  I, Count: Integer;
  Star: TScriptStar;
begin
  Count := Stars.Count;
  for I := 0 to Count - 1 do
  begin
    Star := TScriptStar(Stars[I]);
    if Name = Star.Name then
    begin
      Result := Star;
      Exit;
    end;
  end;
  raise Exception.Create(AnsiString('Error.Script. Not found star =' + Name));
end;
{ @end $538124 }

{ @routine $538230 TScript_GetPlanetBinding }
function TScript.GetPlanetBinding(Name: WideString): PScriptPlanetBinding;
var
  I, Count, J: Integer;
  Star: TScriptStar;
begin
  Count := Stars.Count;
  for I := 0 to Count - 1 do
  begin
    Star := TScriptStar(Stars[I]);
    if Star.Planets <> nil then
      for J := 0 to High(Star.Planets) do
        if Name = Star.Planets[J].Name then
        begin
          Result := @Star.Planets[J];
          Exit;
        end;
  end;
  raise Exception.Create(AnsiString('Error.Script. Not found planet =' + Name));
end;
{ @end $538230 }

{ @routine $538378 TScript_GetItem }
function TScript.GetItem(Name: WideString): TScriptItem;
var
  Item: TScriptItem;
  I: Integer;
begin
  for I := 0 to Items.Count - 1 do
  begin
    Item := TScriptItem(Items[I]);
    if Item.Name = Name then
    begin
      Result := Item;
      Exit;
    end;
  end;
  raise Exception.Create(AnsiString('Error.Script. Not found item =' + Name));
end;
{ @end $538378 }

{ @routine $538480 TScript_RunShipState }
procedure TScript.RunShipState(Binding: TScriptShip);
begin
  if Binding.State.StateCode <> nil then
  begin
    PublishShipContext(Binding);
    Binding.State.StateCode.Run(ScriptProcess);
  end;
end;
{ @end $538480 }

{ @routine $5384A8 TScript_RunTurnCode }
procedure TScript.RunTurnCode;
begin
  CurrentScript := Self;
  TurnCode.Run(ScriptProcess);
end;
{ @end $5384A8 }

{ @routine $5384BC TScript_CallDialog }
procedure TScript.CallDialog(Index: Integer);
begin
  if (Index < 0) or (Index >= Dialogs.Count) then raise Exception.Create('Error.Script.CallDialog');
  CurrentScript := Self;
  CurrentDialog := Index;
  SkipGreeting := False;
  TScriptDialog(Dialogs[Index]).Code.Run(ScriptProcess);
end;
{ @end $5384BC }

{ @routine $53852C TScript_CallDialogMessage }
procedure TScript.CallDialogMessage(Index: Integer);
begin
  if (Index < 0) or (Index >= DialogMessages.Count) then raise Exception.Create('Error.Script.CallDialogMsg');

  TScriptDialogMsg(DialogMessages[Index]).Code.Run(ScriptProcess);
end;
{ @end $53852C }

{ @routine $538594 TScript_BuildDialogAnswer }
procedure TScript.BuildDialogAnswer(Index: Integer);
begin
  if (Index < 0) or (Index >= DialogAnswers.Count) then raise Exception.Create('Error.Script.CallDialogAnswerAnswer');
  CurrentAnswer := Index;
  TScriptDialogAnswer(DialogAnswers[Index]).AnswerCode.Run(ScriptProcess);
end;
{ @end $538594 }

{ @routine $538608 TScript_ExecuteDialogAnswer }
procedure TScript.ExecuteDialogAnswer(Index: Integer);
begin
  if (Index < 0) or (Index >= DialogAnswers.Count) then raise Exception.Create('Error.Script.CallDialogAnswerAnswer');
  CurrentAnswer := Index;
  TScriptDialogAnswer(DialogAnswers[Index]).ActionCode.Run(ScriptProcess);
end;
{ @end $538608 }

{ @routine $53867C TScript_BindShip }
procedure TScript.BindShip(GroupIndex: Integer; Ship: TShip);
var
  Binding: TScriptShip;
begin
  Binding := TScriptShip.Create;
  Ships.Add(Binding);
  Binding.GroupIndex := GroupIndex;
  Binding.Script := Self;
  Binding.Ship := Ship;
  if Ship is TPlayer then TPlayer(Ship).ScriptShipBindings.Add(Binding)
  else Ship.ScriptShip := Binding;
  if Ship is TWarrior then
    if Ship.CurrentStar.Ships.IndexOf(Ship) = -1 then
      Ship.CurrentStar.Ships.Add(Ship);
end;
{ @end $53867C }

{ @routine $538700 TScript_UnbindShip }
procedure TScript.UnbindShip(Ship: TShip);
var
  I, Index: Integer;
  Binding: TScriptShip;
begin
  if Ship is TPlayer then
  begin
    I := 0;
    while I < TPlayer(Ship).ScriptShipBindings.Count do
    begin
      Index := Ships.IndexOf(TPlayer(Ship).ScriptShipBindings[I]);
      if Index >= 0 then
      begin
        Binding := TScriptShip(Ships[Index]);
        Binding.Free;
        Ships.Delete(Index);
        TPlayer(Ship).ScriptShipBindings.Delete(I);
      end
      else Inc(I);
    end;
  end
  else
  begin
    Index := Ships.IndexOf(Ship.ScriptShip);
    if Index >= 0 then
    begin
      Binding := TScriptShip(Ships[Index]);
      Binding.Free;
      Ships.Delete(Index);
    end;
    Ship.ScriptShip := nil;
  end;
end;
{ @end $538700 }

{ @routine $5387A8 TScript_ChangeState }
procedure TScript.ChangeState(Binding: TScriptShip; StateIndex: Integer);
begin
  if (Binding <> nil) and not (Binding.Ship is TPlayer) then
  begin
    Binding.State := TScriptState(States[StateIndex]);
    if Binding.State.EntryCode <> nil then Binding.State.EntryCode.Run(ScriptProcess);
    Binding.Ship.InitializeScriptStateOrders;
    if Binding.State.StateCode <> nil then
    begin
      PublishShipContext(Binding);
      Binding.State.StateCode.Run(ScriptProcess);
    end;
  end;
end;
{ @end $5387A8 }

{ @routine $53881C TScript_SetGroupRelation }
procedure TScript.SetGroupRelation(SourceGroup, TargetGroup: Integer; Level: TRelationLevel);
var
  Source, Target: TScriptShip;
  I, J: Integer;
begin
  if SourceGroup = TargetGroup then Exit;
  for I := 0 to Ships.Count - 1 do
  begin
    Source := TScriptShip(Ships[I]);
    if Source.GroupIndex = SourceGroup then
      for J := 0 to Ships.Count - 1 do
      begin
        Target := TScriptShip(Ships[J]);
        if (Target.GroupIndex = TargetGroup) and (Target.Ship is TRanger) then
          Source.Ship.SetStoredRangerRelationLevel(TRanger(Target.Ship), Level);
      end;
  end;
end;
{ @end $53881C }

{ @routine $5388D0 TScript_SetPlanetRelation }
procedure TScript.SetPlanetRelation(Group: Integer; Planet: TPlanet; Level: TRelationLevel);
var
  Binding: TScriptShip;
  I: Integer;
begin
  for I := 0 to Ships.Count - 1 do
  begin
    Binding := TScriptShip(Ships[I]);
    if (Binding.GroupIndex = Group) and (Binding.Ship is TRanger) then
      Planet.SetRelationLevelToRanger(TRanger(Binding.Ship), Level);
  end;
end;
{ @end $5388D0 }

{ @routine $538938 TScript_TryBindStars }
function TScript.TryBindStars(StarIndex: Integer): Boolean;
var
  Binding: TScriptStar;
  Star: TStar;
  J, K, I, WorkValue, DistanceSquared: Integer;
  Bearing: Single;
  Candidates: TList;
  Hole: THole;
  ConstellationBinding: TScriptConstellation;
  Constellation: TConstellation;
  MinOrbitSquared: Single;
  MaxOrbitSquared: Single;
  OrbitSquared: Single;
  Planet: TPlanet;
  Requirement: PScriptShipRequirement;
  Indent: WideString;
  Constraint: TScriptStarConstraint;
begin
  Indent := '';
  for J := 0 to StarIndex - 1 do Indent := Indent + '    ';
  Result := False;
  Binding := TScriptStar(Stars[StarIndex]);
  Star := Binding.Star;
  if (Binding.LegacyFilter <> Star.LegacySystemKind) or
    (Binding.RejectHostilePresence and Star.HasHostilePresenceForScriptBinding) then Exit;
  if StarIndex < 2 then Bearing := 0
  else Bearing := PointBearingDegrees(TScriptStar(Stars[0]).Star.Position, TScriptStar(Stars[1]).Star.Position);
  for J := 0 to High(Binding.Constraints) do
  begin
    Constraint := Binding.Constraints[J];
    with Constraint do
    begin
      if RequireBlackHole then
      begin
        WorkValue := Galaxy.Holes.Count;
        K := 0;
        while K < WorkValue do
        begin
          Hole := THole(Galaxy.Holes[K]);
          if (Hole.Star1 = Star) and (Hole.Star2 = OtherStar.Star) then Break;
          if (Hole.Star1 = OtherStar.Star) and (Hole.Star2 = Star) then Break;
          Inc(K);
        end;
        if K >= WorkValue then Exit;
      end;
      if not Binding.LegacyFilter and not OtherStar.LegacyFilter then
      begin
        if (MinDistance > 0) or (MaxDistance < 150) then
        begin
          DistanceSquared := Round(PointDistanceSquared(Star.Position, OtherStar.Star.Position));
          if (DistanceSquared < Sqr(MinDistance)) or (DistanceSquared > Sqr(MaxDistance)) then Exit;
        end;
        if (StarIndex >= 2) and (MaxBearingDeviationPercent < 100) then
        begin
          // Native narrows Round to 32 bits before the signed comparison.
          DistanceSquared := Round(Abs(HeadingDifferenceDegrees(WrapHeadingDegrees(PointBearingDegrees(OtherStar.Star.Position, Star.Position) + Bearing), RelativeBearingDegrees)) / 180 * 100);
          if DistanceSquared > MaxBearingDeviationPercent then Exit;
        end;
      end;
    end;
  end;
  if Binding.Planets <> nil then
  begin
    WorkValue := High(Binding.Planets) + 1;
    for K := 0 to WorkValue - 1 do
    begin
      if (StarIndex = 0) and (K = 0) and (AnchorPlanet <> nil) then
      begin
        Binding.Planets[0].Planet := AnchorPlanet;
        Continue;
      end;
      MinOrbitSquared := Sqr(Binding.Planets[K].MinOrbitPercent / 100 * (Star.MapDiameter / 2));
      MaxOrbitSquared := Sqr(Binding.Planets[K].MaxOrbitPercent / 100 * (Star.MapDiameter / 2));
      Binding.Planets[K].Planet := nil;
      for J := 0 to Star.Planets.Count - 1 do
      begin
        Planet := TPlanet(Star.Planets[J]);
        if not (Planet.RaceId in Binding.Planets[K].RaceMask) then Continue;
        if not (Planet.OwnerId in Binding.Planets[K].OwnerMask) then Continue;
        if not (Planet.Economy in Binding.Planets[K].EconomyMask) then Continue;
        if not (Planet.Government in Binding.Planets[K].GovernmentMask) then Continue;
        I := 0;
        while I < K do
        begin
          if Binding.Planets[I].Planet = Planet then Break;
          Inc(I);
        end;
        if I < K then Continue;
        OrbitSquared := PointDistanceSquared(Planet.GetPosition, MakePointF(0, 0));
        if OrbitSquared < MinOrbitSquared then Continue;
        // Native search stops at the first eligible orbit beyond the upper bound.
        if OrbitSquared > MaxOrbitSquared then Break;
        Binding.Planets[K].Planet := Planet;
        Break;
      end;
      if Binding.Planets[K].Planet = nil then Exit;
    end;
  end;
  if Binding.ShipRequirements <> nil then
  begin
    Candidates := CollectScriptCandidateShips(Star);
    WorkValue := High(Binding.ShipRequirements) + 1;
    // The original early rejection leaves Candidates allocated here.
    if Candidates.Count < WorkValue then Exit;
    for K := 0 to WorkValue - 1 do
    begin
      Requirement := @Binding.ShipRequirements[K];
      for J := 0 to Requirement.Count - 1 do
      begin
        I := 0;
        while I < Candidates.Count do
        begin
          WorkValue := Integer(Candidates[I]);
          Inc(I);
          if TShip(WorkValue).LiberationGroup <> nil then Continue;
          if not (TShip(WorkValue).OwnerId in Requirement.OwnerMask) then Continue;
          if not ScriptShipMatchesType(TShip(WorkValue), Requirement.ShipTypeMask, Requirement.StationNames) then Continue;
          if Requirement.PlayerOnly and (WorkValue <> Integer(Player)) then Continue;
          if TShip(WorkValue).Speed < Requirement.MinSpeed then Continue;
          if TShip(WorkValue).Speed > Requirement.MaxSpeed then Continue;
          if (Requirement.WeaponRequirement = 1) and (TShip(WorkValue).WeaponCount <= 0) then Continue;
          if (Requirement.WeaponRequirement = 2) and (TShip(WorkValue).WeaponCount > 0) then Continue;
          if Requirement.MinCargoHookLevel > 0 then
          begin
            if TShip(WorkValue).CargoHook = nil then Continue;
            if TShip(WorkValue).CargoHook.GetLevel + 1 < Requirement.MinCargoHookLevel then Continue;
          end;
          if TShip(WorkValue).CargoFreeSpace < Requirement.MinFreeCargoSpace then Continue;
          if TShip(WorkValue) is TRanger then
          begin
            if TRanger(TShip(WorkValue)).CareerStatus[rcTrader] < Requirement.MinTraderStatus then Continue;
            if TRanger(TShip(WorkValue)).CareerStatus[rcTrader] > Requirement.MaxTraderStatus then Continue;
            if TRanger(TShip(WorkValue)).CareerStatus[rcWarrior] < Requirement.MinWarriorStatus then Continue;
            if TRanger(TShip(WorkValue)).CareerStatus[rcWarrior] > Requirement.MaxWarriorStatus then Continue;
            if TRanger(TShip(WorkValue)).CareerStatus[rcPirate] < Requirement.MinPirateStatus then Continue;
            if TRanger(TShip(WorkValue)).CareerStatus[rcPirate] > Requirement.MaxPirateStatus then Continue;
          end;
          if (Requirement.MinStrength <> 0) or (Requirement.MaxStrength <> 0) then
          begin
            if TShip(WorkValue).StrengthInBestRanger < Requirement.MinStrength then Continue;
            if TShip(WorkValue).StrengthInBestRanger > Requirement.MaxStrength then Continue;
          end;
          Dec(I);
          Break;
        end;
        if I >= Candidates.Count then
        begin
          Candidates.Free;
          Exit;
        end;
        Candidates.Delete(I);
      end;
    end;
    Candidates.Free;
  end;
  Inc(StarIndex);
  if StarIndex >= Stars.Count then
  begin
    Result := True;
    Exit;
  end;
  Binding := TScriptStar(Stars[StarIndex]);
  if Binding.LegacyFilter then
  begin
    WorkValue := Galaxy.Stars.Count - 1;
    for K := 0 to WorkValue - 1 do
    begin
      Star := TStar(Galaxy.Stars[K]);
      if not Star.LegacySystemKind or (Binding.RejectHostilePresence and Star.HasHostilePresenceForScriptBinding) then Continue;
      J := 0;
      while J < StarIndex do
      begin
        if TScriptStar(Stars[J]).Star = Star then Break;
        Inc(J);
      end;
      if J < StarIndex then Continue;
      Binding.Star := Star;
      Result := TryBindStars(StarIndex);
      if Result then Exit;
    end;
  end
  else   if Binding.ConstellationIndex = -1 then
  begin
    WorkValue := Galaxy.Stars.Count - 1;
    for K := 0 to WorkValue - 1 do
    begin
      Star := TStar(Galaxy.Stars[K]);
      if Star.LegacySystemKind or (Binding.RejectHostilePresence and Star.HasHostilePresenceForScriptBinding) then Continue;
      J := 0;
      while J < StarIndex do
      begin
        if TScriptStar(Stars[J]).Star = Star then Break;
        Inc(J);
      end;
      if J < StarIndex then Continue;
      Binding.Star := Star;
      Result := TryBindStars(StarIndex);
      if Result then Exit;
    end;
  end
  else if (Binding.ConstellationIndex >= 0) and
    (TScriptConstellation(Constellations[Binding.ConstellationIndex]).Constellation = nil) then
  begin
    WorkValue := Galaxy.Stars.Count - 1;
    for K := 0 to WorkValue - 1 do
    begin
      Star := TStar(Galaxy.Stars[K]);
      if Star.LegacySystemKind or (Binding.RejectHostilePresence and Star.HasHostilePresenceForScriptBinding) then Continue;
      J := 0;
      while J < StarIndex do
      begin
        if TScriptStar(Stars[J]).Star = Star then Break;
        Inc(J);
      end;
      if J < StarIndex then Continue;
      J := 0;
      while J < Constellations.Count do
      begin
        ConstellationBinding := TScriptConstellation(Constellations[J]);
        if ConstellationBinding.Constellation <> nil then
          if ConstellationBinding.Constellation = Star.Constellation then Break;
        Inc(J);
      end;
      if J < Constellations.Count then Continue;
      ConstellationBinding := TScriptConstellation(Constellations[Binding.ConstellationIndex]);
      ConstellationBinding.Constellation := Star.Constellation;
      Binding.Star := Star;
      Result := TryBindStars(StarIndex);
      if Result then Exit;
      ConstellationBinding.Constellation := nil;
    end;
  end
  else if Binding.ConstellationIndex >= 0 then
  begin
    if TScriptConstellation(Constellations[Binding.ConstellationIndex]).Constellation <> nil then
    begin
      Constellation := TScriptConstellation(Constellations[Binding.ConstellationIndex]).Constellation;
      WorkValue := Constellation.Stars.Count - 1;
      for K := 0 to WorkValue - 1 do
      begin
        Star := TStar(Constellation.Stars[K]);
        if Star.LegacySystemKind or (Binding.RejectHostilePresence and Star.HasHostilePresenceForScriptBinding) then Continue;
        J := 0;
        while J < StarIndex do
        begin
          if TScriptStar(Stars[J]).Star = Star then Break;
          Inc(J);
        end;
        if J < StarIndex then Continue;
        Binding.Star := Star;
        Result := TryBindStars(StarIndex);
        if Result then Exit;
      end;
    end;
  end;
  Result := False;
end;
{ @end $538938 }

{ @routine $53935C TScript_LoadFromBuffer }
function TScript.LoadFromBuffer(Buffer: TBufEC; AnchorStar: TStar; FirstPlanet: TPlanet; CreateObjects: Boolean): Boolean;
var
  Candidates: TList;
  I, Count, J, SubCount, K: Integer;
  Balance, Radius: Single;
  Text, ErrorText: WideString;
  Constellation: TScriptConstellation;
  Star: TScriptStar;
  PlanetBinding: PScriptPlanetBinding;
  Place: TScriptPlace;
  ScriptItem: TScriptItem;
  Group: TScriptGroup;
  Ship: TShip;
  State: TScriptState;
  Binding: TScriptShip;
  Dialog: TScriptDialog;
  DialogMessage: TScriptDialogMsg;
  DialogAnswer: TScriptDialogAnswer;
  Analyzer: TCodeAnalyzerEC;
  Item, OtherItem: TItem;
  Planet: TPlanet;

begin
  Clear;
  AnchorPlanet := FirstPlanet;
  Result := False;
  if Buffer.GetUInt32 <> 5 then
  begin
    RaiseWideMessage('Script file incorrect version');
    Exit;
  end;
  Buffer.SetPosition(Buffer.GetWord);
  CurrentScript := Self;
  InitCode.LocalVar.AppendFromBuffer(Buffer);
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Constellation := TScriptConstellation.Create;
    Constellations.Add(Constellation);
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Star := TScriptStar.Create;
    Stars.Add(Star);
    Star.Name := Buffer.ReadWideString;
    Star.ConstellationIndex := Buffer.GetInt32;
    Star.LegacyFilter := Buffer.GetBoolean;
    Star.RejectHostilePresence := Buffer.GetBoolean;
    Star.ProtectStar := Buffer.GetBoolean;
    SubCount := Buffer.GetInt32;
    if SubCount > 0 then
    begin
      SetLength(Star.Constraints, SubCount);
      for J := 0 to SubCount - 1 do
      begin
        Star.Constraints[J].OtherStar := TScriptStar(Stars[Buffer.GetInt32]);
        Star.Constraints[J].RelativeBearingDegrees := Buffer.GetInt32;
        Star.Constraints[J].MinDistance := Buffer.GetInt32;
        Star.Constraints[J].MaxDistance := Buffer.GetInt32;
        Star.Constraints[J].ConstraintValue10 := Buffer.GetInt32;
        Star.Constraints[J].ConstraintValue14 := Buffer.GetInt32;
        Star.Constraints[J].MaxBearingDeviationPercent := Buffer.GetInt32;
        Star.Constraints[J].RequireBlackHole := Buffer.GetBoolean;
      end;
    end;
    SubCount := Buffer.GetInt32;
    if SubCount > 0 then
    begin
      SetLength(Star.Planets, SubCount);
      for J := 0 to SubCount - 1 do
      begin
        Star.Planets[J].Name := Buffer.ReadWideString;
        Star.Planets[J].RaceMask := DecodeScriptRaceMask(Buffer.GetUInt32);
        Star.Planets[J].OwnerMask := DecodeScriptOwnerMask(Buffer.GetUInt32);
        Star.Planets[J].EconomyMask := DecodeScriptEconomyMask(Buffer.GetUInt32);
        Star.Planets[J].GovernmentMask := DecodeScriptGovernmentMask(Buffer.GetUInt32);
        Star.Planets[J].MinOrbitPercent := Buffer.GetInt32;
        Star.Planets[J].MaxOrbitPercent := Buffer.GetInt32;
        Star.Planets[J].DefinitionText := Buffer.ReadWideString;
      end;
    end;
    SubCount := Buffer.GetInt32;
    if SubCount > 0 then
    begin
      SetLength(Star.ShipRequirements, SubCount);
      for J := 0 to SubCount - 1 do
      begin
        Star.ShipRequirements[J].Count := Buffer.GetInt32;
        Star.ShipRequirements[J].OwnerMask := DecodeScriptOwnerMask(Buffer.GetUInt32);
        Star.ShipRequirements[J].ShipTypeMask := DecodeScriptShipTypeMask(Buffer.GetUInt32);
        Star.ShipRequirements[J].PlayerOnly := Buffer.GetBoolean;
        Star.ShipRequirements[J].MinSpeed := Buffer.GetInt32;
        Star.ShipRequirements[J].MaxSpeed := Buffer.GetInt32;
        Star.ShipRequirements[J].WeaponRequirement := Buffer.GetInt32;
        Star.ShipRequirements[J].MinCargoHookLevel := Buffer.GetInt32;
        Star.ShipRequirements[J].MinFreeCargoSpace := Buffer.GetInt32;
        Star.ShipRequirements[J].RequirementValue1C := Buffer.GetInt32;
        Star.ShipRequirements[J].RequirementValue20 := Buffer.GetInt32;
        Star.ShipRequirements[J].MinTraderStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].MaxTraderStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].MinWarriorStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].MaxWarriorStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].MinPirateStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].MaxPirateStatus := Buffer.GetInt32;
        Star.ShipRequirements[J].RequirementValue3C := Buffer.GetInt32;
        Star.ShipRequirements[J].RequirementValue40 := Buffer.GetInt32;
        Star.ShipRequirements[J].MinStrength := Buffer.GetSingle;
        Star.ShipRequirements[J].MaxStrength := Buffer.GetSingle;
        Star.ShipRequirements[J].StationNames := TrimWideString(Buffer.ReadWideString);
        if Star.ShipRequirements[J].StationNames <> '' then Star.ShipRequirements[J].ShipTypeMask := Star.ShipRequirements[J].ShipTypeMask + [htStation];
      end;
    end;
  end;
  if CreateObjects then
  begin
    Star := TScriptStar(Stars[0]);
    Star.Star := AnchorStar;
    if Star.ConstellationIndex >= 0 then
    begin
      Constellation := TScriptConstellation(Constellations[Star.ConstellationIndex]);
      Constellation.Constellation := AnchorStar.Constellation;
    end;
    if not TryBindStars(0) then Exit;
    for I := 0 to Stars.Count - 1 do
    begin
      Star := TScriptStar(Stars[I]);
      InitCode.LocalVar.GetVar(Star.Name).SetDword(Cardinal(Star.Star));
      if Star.Planets <> nil then
        for J := 0 to High(Star.Planets) do
        begin
          PlanetBinding := @Star.Planets[J];
          InitCode.LocalVar.GetVar(PlanetBinding.Name).SetDword(Cardinal(PlanetBinding.Planet));
        end;
    end;
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Place := TScriptPlace.Create;
    Places.Add(Place);
    Place.Script := Self;
    Place.Name := Buffer.ReadWideString;
    Place.OriginVarName := Buffer.ReadWideString;
    Place.PlaceKind := Buffer.GetInt32;
    if Place.PlaceKind = spkPolar then
    begin
      Place.AngleOffset := Buffer.GetSingle;
      Place.DistanceScale := Buffer.GetSingle;
      Place.Radius := Buffer.GetInt32;
    end
    else if Place.PlaceKind = spkPlanetPosition then
    begin
      Place.TargetVarName := Buffer.ReadWideString;
      Place.Radius := Buffer.GetInt32;
    end
    else if Place.PlaceKind = spkDockedPlanet then Place.TargetVarName := Buffer.ReadWideString
    else if Place.PlaceKind = spkStarDirection then
    begin
      Place.TargetVarName := Buffer.ReadWideString;
      Place.DistanceScale := Buffer.GetSingle;
      Place.Radius := Buffer.GetInt32;
      Place.AngleOffset := Buffer.GetSingle;
    end
    else if Place.PlaceKind = spkScriptItem then
    begin
      Place.TargetVarName := Buffer.ReadWideString;
      Place.Radius := Buffer.GetInt32;
    end
    else if Place.PlaceKind = spkGroupCentroid then
    begin
      Place.TargetVarName := Buffer.ReadWideString;
      Place.DistanceScale := Buffer.GetSingle;
      Place.Radius := Buffer.GetInt32;
      Place.AngleOffset := Buffer.GetSingle;
    end
    else RaiseWideMessage('Script.Place.Type');
    if CreateObjects then InitCode.LocalVar.GetVar(Place.Name).SetDword(Cardinal(Place));
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    ScriptItem := TScriptItem.Create;
    Items.Add(ScriptItem);
    ScriptItem.Name := Buffer.ReadWideString;
    ScriptItem.LocationVarName := Buffer.ReadWideString;
    ScriptItem.DefinitionKind := TScriptItemKind(Buffer.GetInt32);
    ScriptItem.DefinitionType := Buffer.GetInt32;
    ScriptItem.Weight := Buffer.GetInt32;
    ScriptItem.Level := Buffer.GetInt32;
    ScriptItem.DefinitionValue1C := Buffer.GetInt32;
    ScriptItem.OwnerId := DecodeScriptItemOwner(Buffer.GetInt32);
    ScriptItem.ConfigName := Buffer.ReadWideString;
    InitCode.LocalVar.GetVar(ScriptItem.Name).SetDword(Cardinal(ScriptItem));
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Group := TScriptGroup.Create;
    Groups.Add(Group);
    Group.Name := Buffer.ReadWideString;
    Group.PlanetVarName := Buffer.ReadWideString;
    Group.InitialStateIndex := Buffer.GetInt32;
    Group.OwnerMask := DecodeScriptOwnerMask(Buffer.GetUInt32);
    Group.ShipTypeMask := DecodeScriptShipTypeMask(Buffer.GetUInt32);
    Group.MinCount := Buffer.GetInt32;
    Group.MaxCount := Buffer.GetInt32;
    Group.MinSpeed := Buffer.GetInt32;
    Group.MaxSpeed := Buffer.GetInt32;
    Group.WeaponRequirement := Buffer.GetInt32;
    Group.MinCargoHookLevel := Buffer.GetInt32;
    Group.MinFreeCargoSpace := Buffer.GetInt32;
    Group.RequirementValue34 := Buffer.GetInt32;
    Group.IncludePlayer := Buffer.GetBoolean;
    Group.RequirementValue40 := Buffer.GetInt32;
    Group.RequirementValue44 := Buffer.GetInt32;
    Group.RequirementValue48 := Buffer.GetInt32;
    Group.RequirementValue4C := Buffer.GetInt32;
    Group.MinTraderStatus := Buffer.GetInt32;
    Group.MaxTraderStatus := Buffer.GetInt32;
    Group.MinWarriorStatus := Buffer.GetInt32;
    Group.MaxWarriorStatus := Buffer.GetInt32;
    Group.MinPirateStatus := Buffer.GetInt32;
    Group.MaxPirateStatus := Buffer.GetInt32;
    Group.MaxDistanceFromPlanet := Buffer.GetInt32;
    Group.DialogVariableName := Buffer.ReadWideString;
    Group.MinStrength := Buffer.GetSingle;
    Group.MaxStrength := Buffer.GetSingle;
    Group.StationNames := TrimWideString(Buffer.ReadWideString);
    if Group.StationNames <> '' then Group.ShipTypeMask := Group.ShipTypeMask + [htStation];
  end;
  Count := Buffer.GetInt32;
  if Count > 0 then
  begin
    SetLength(GroupRelations, Count);
    for I := 0 to Count - 1 do
    begin
      GroupRelations[I].Group1 := Buffer.GetInt32;
      GroupRelations[I].Group2 := Buffer.GetInt32;
      GroupRelations[I].Relation1To2 := Buffer.GetInt32;
      GroupRelations[I].Relation2To1 := Buffer.GetInt32;
      GroupRelations[I].MinCombatBalance := Buffer.GetSingle;
      GroupRelations[I].MaxCombatBalance := Buffer.GetSingle;
    end;
  end;
  if CreateObjects then
  begin
    for I := 0 to Groups.Count - 1 do
    begin
      Group := TScriptGroup(Groups[I]);
      Group.Ships := TList.Create;
      Group.Planet := TPlanet(InitCode.LocalVar.GetVar(Group.PlanetVarName).GetDword);
      Candidates := CollectScriptCandidateShips(Group.Planet.CurrentStar);
      SubCount := Group.MinCount;
      if Group.IncludePlayer then Dec(SubCount);
      for J := 0 to SubCount - 1 do
      begin
        Ship := FindScriptGroupCandidate(Candidates, Group);
        if Ship = nil then
        begin
          Ship := Group.Planet.GenerateShipForScriptGroup(Group) as TShip;
          if Ship = nil then
          begin
            Candidates.Free;
            Exit;
          end;
        end;
        BindShip(I, Ship);
        Group.Ships.Add(Ship);
        if Candidates.IndexOf(Ship) >= 0 then Candidates.Delete(Candidates.IndexOf(Ship));
      end;
      if Group.IncludePlayer then BindShip(I, Player);
      Candidates.Free;
    end;
    while True do
    begin
      I := 0;
      Group := nil;
      while I <= High(GroupRelations) do
      begin
        if (GroupRelations[I].MinCombatBalance > 0) or (GroupRelations[I].MaxCombatBalance < 1000) then
        begin
          Balance := CompareShipGroupsStrength(TScriptGroup(Groups[GroupRelations[I].Group1]).Ships,
            TScriptGroup(Groups[GroupRelations[I].Group2]).Ships);
          if Balance < GroupRelations[I].MinCombatBalance then
          begin
            Group := TScriptGroup(Groups[GroupRelations[I].Group1]);
            if Group.Ships.Count < Group.MaxCount then Break;
          end
          else if Balance > GroupRelations[I].MaxCombatBalance then
          begin
            Group := TScriptGroup(Groups[GroupRelations[I].Group2]);
            if Group.Ships.Count < Group.MaxCount then Break;
          end;
          Group := nil;
        end;
        Inc(I);
      end;
      if Group = nil then Break;
      Candidates := CollectScriptCandidateShips(Group.Planet.CurrentStar);
      Ship := FindScriptGroupCandidate(Candidates, Group);
      if Ship = nil then
      begin
        Ship := Group.Planet.GenerateShipForScriptGroup(Group) as TShip;
        if Ship = nil then
        begin
          Candidates.Free;
          Exit;
        end;
      end;
      BindShip(Groups.IndexOf(Group), Ship);
      Group.Ships.Add(Ship);
      Candidates.Free;
    end;
    for I := 0 to High(GroupRelations) do
      if (GroupRelations[I].MinCombatBalance > 0) or (GroupRelations[I].MaxCombatBalance < 1000) then
      begin
        Balance := CompareShipGroupsStrength(TScriptGroup(Groups[GroupRelations[I].Group1]).Ships,
          TScriptGroup(Groups[GroupRelations[I].Group2]).Ships);
        if (Balance < GroupRelations[I].MinCombatBalance) or (Balance > GroupRelations[I].MaxCombatBalance) then Exit;
      end;
  end;
  if CreateObjects then
    for I := 0 to High(GroupRelations) do
    begin
      if GroupRelations[I].Relation1To2 <> 5 then
        SetGroupRelation(GroupRelations[I].Group1, GroupRelations[I].Group2, DecodeScriptRelationLevel(GroupRelations[I].Relation1To2));
      if GroupRelations[I].Relation2To1 <> 5 then
        SetGroupRelation(GroupRelations[I].Group2, GroupRelations[I].Group1, DecodeScriptRelationLevel(GroupRelations[I].Relation2To1));
    end;
  Analyzer := TCodeAnalyzerEC.Create;
  Analyzer.Tokenize(Buffer.ReadWideString);
  Analyzer.RemoveComments;
  Analyzer.RemoveNewlines;
  Analyzer.RemoveWhitespace;
  Analyzer.ValidateDelimiters;
  ErrorText := InitCode.Compile(Analyzer, nil, nil, nil, nil, nil);
  Analyzer.Free;
  if ErrorText <> '' then RaiseWideMessage('CodeInit.Compiler. Error=' + ErrorText);
  InitCode.LocalVar.Add('EndState', vkInt).SetInt(0);
  InitCode.LocalVar.Add('CurShip', vkDword).SetInt(0);
  InitCode.LinkAll(ScriptFunctionScope);
  InitCode.LinkAll(SharedScriptVariables);
  if CreateObjects then InitCode.Run(ScriptProcess);
  Analyzer := TCodeAnalyzerEC.Create;
  Analyzer.Tokenize(Buffer.ReadWideString);
  Analyzer.RemoveComments;
  Analyzer.RemoveNewlines;
  Analyzer.RemoveWhitespace;
  Analyzer.ValidateDelimiters;
  ErrorText := TurnCode.Compile(Analyzer, nil, nil, nil, nil, nil);
  Analyzer.Free;
  if ErrorText <> '' then RaiseWideMessage('CodeTurn.Compiler. Error=' + ErrorText);
  TurnCode.LinkAll(ScriptFunctionScope);
  TurnCode.LinkAll(SharedScriptVariables);
  TurnCode.LinkAll(InitCode.LocalVar);
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    State := TScriptState.Create;
    States.Add(State);
    State.Name := Buffer.ReadWideString;
    State.StateKind := Buffer.GetInt32;
    if State.StateKind <> sskIdle then State.TargetVarName := Buffer.ReadWideString;
    SubCount := Buffer.GetInt32;
    if SubCount > 0 then
    begin
      SetLength(State.EnemyGroupNames, SubCount);
      SetLength(State.EnemyGroupIndices, SubCount);
      for J := 0 to SubCount - 1 do State.EnemyGroupNames[J] := Buffer.ReadWideString;
    end;
    State.PickupItemVarName := Buffer.ReadWideString;
    if State.PickupItemVarName <> '' then State.PickupItem := TScriptItem(InitCode.LocalVar.GetVar(State.PickupItemVarName).GetDword);
    State.PickUpNearbyItems := Buffer.GetBoolean;
    State.AuxiliaryText := Buffer.ReadWideString;
    if (State.AuxiliaryText <> '') and (InitCode.LocalVar.GetVarNE(State.AuxiliaryText) = nil) then
    begin
      State.AuxiliaryCode := TCodeEC.Create;
      Analyzer := TCodeAnalyzerEC.Create;
      Analyzer.Tokenize(State.AuxiliaryText);
      Analyzer.RemoveComments;
      Analyzer.RemoveNewlines;
      Analyzer.RemoveWhitespace;
      Analyzer.ValidateDelimiters;
      ErrorText := State.AuxiliaryCode.Compile(Analyzer, nil, nil, nil, nil, nil);
      Analyzer.Free;
      if ErrorText <> '' then RaiseWideMessage('StateCodeText.Compiler. Error=' + ErrorText + ' State=' + State.Name);
      State.AuxiliaryCode.LinkAll(ScriptFunctionScope);
      State.AuxiliaryCode.LinkAll(SharedScriptVariables);
      State.AuxiliaryCode.LinkAll(InitCode.LocalVar);
    end;
    State.OnActionText := Buffer.ReadWideString;
    if (State.OnActionText <> '') and (InitCode.LocalVar.GetVarNE(State.OnActionText) = nil) then
    begin
      State.ActionCode := TCodeEC.Create;
      Analyzer := TCodeAnalyzerEC.Create;
      Analyzer.Tokenize(State.OnActionText);
      Analyzer.RemoveComments;
      Analyzer.RemoveNewlines;
      Analyzer.RemoveWhitespace;
      Analyzer.ValidateDelimiters;
      ErrorText := State.ActionCode.Compile(Analyzer, nil, nil, nil, nil, nil);
      Analyzer.Free;
      if ErrorText <> '' then RaiseWideMessage('StateCodeText.Compiler. Error=' + ErrorText + ' State=' + State.Name);
      State.ActionCode.LinkAll(ScriptFunctionScope);
      State.ActionCode.LinkAll(SharedScriptVariables);
      State.ActionCode.LinkAll(InitCode.LocalVar);
    end;
    Text := Buffer.ReadWideString;
    if Text <> '' then
    begin
      State.EntryCode := TCodeEC.Create;
      Analyzer := TCodeAnalyzerEC.Create;
      Analyzer.Tokenize(Text);
      Analyzer.RemoveComments;
      Analyzer.RemoveNewlines;
      Analyzer.RemoveWhitespace;
      Analyzer.ValidateDelimiters;
      ErrorText := State.EntryCode.Compile(Analyzer, nil, nil, nil, nil, nil);
      Analyzer.Free;
      if ErrorText <> '' then RaiseWideMessage('StateCodeEther.Compiler. Error=' + ErrorText + ' State=' + State.Name);
      State.EntryCode.LinkAll(ScriptFunctionScope);
      State.EntryCode.LinkAll(SharedScriptVariables);
      State.EntryCode.LinkAll(InitCode.LocalVar);
    end;
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := State.StateCode.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('StateTurn.Compiler. Error=' + ErrorText + ' State=' + State.Name);
    State.StateCode.LinkAll(ScriptFunctionScope);
    State.StateCode.LinkAll(SharedScriptVariables);
    State.StateCode.LinkAll(InitCode.LocalVar);
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Dialog := TScriptDialog.Create;
    Dialogs.Add(Dialog);
    Dialog.Name := Buffer.ReadWideString;
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := Dialog.Code.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('Dialog.Code.Compiler. Error=' + ErrorText + ' State=' + Dialog.Name);
    Dialog.Code.LinkAll(ScriptFunctionScope);
    Dialog.Code.LinkAll(SharedScriptVariables);
    Dialog.Code.LinkAll(InitCode.LocalVar);
    InitCode.LocalVar.GetVar(Dialog.Name).SetInt(I);
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    DialogMessage := TScriptDialogMsg.Create;
    DialogMessages.Add(DialogMessage);
    DialogMessage.Name := Buffer.ReadWideString;
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := DialogMessage.Code.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('DialogMsg.Code.Compiler. Error=' + ErrorText + ' State=' + DialogMessage.Name);
    DialogMessage.Code.LinkAll(ScriptFunctionScope);
    DialogMessage.Code.LinkAll(SharedScriptVariables);
    DialogMessage.Code.LinkAll(InitCode.LocalVar);
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    DialogAnswer := TScriptDialogAnswer.Create;
    DialogAnswers.Add(DialogAnswer);
    DialogAnswer.Name := Buffer.ReadWideString;
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := DialogAnswer.AnswerCode.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('DialogAnswer.CodeAnswer.Compiler. Error=' + ErrorText + ' State=' + DialogAnswer.Name);
    DialogAnswer.AnswerCode.LinkAll(ScriptFunctionScope);
    DialogAnswer.AnswerCode.LinkAll(SharedScriptVariables);
    DialogAnswer.AnswerCode.LinkAll(InitCode.LocalVar);
    Analyzer := TCodeAnalyzerEC.Create;
    Analyzer.Tokenize(Buffer.ReadWideString);
    Analyzer.RemoveComments;
    Analyzer.RemoveNewlines;
    Analyzer.RemoveWhitespace;
    Analyzer.ValidateDelimiters;
    ErrorText := DialogAnswer.ActionCode.Compile(Analyzer, nil, nil, nil, nil, nil);
    Analyzer.Free;
    if ErrorText <> '' then RaiseWideMessage('DialogAnswer.Code.Compiler. Error=' + ErrorText + ' State=' + DialogAnswer.Name);
    DialogAnswer.ActionCode.LinkAll(ScriptFunctionScope);
    DialogAnswer.ActionCode.LinkAll(SharedScriptVariables);
    DialogAnswer.ActionCode.LinkAll(InitCode.LocalVar);
  end;
  if CreateObjects then
  begin
    for I := 0 to States.Count - 1 do
    begin
      State := TScriptState(States[I]);
      if State.TargetVarName <> '' then State.TargetValue := InitCode.LocalVar.GetVar(State.TargetVarName).GetDword;
      if State.EnemyGroupIndices <> nil then
        for J := 0 to High(State.EnemyGroupIndices) do
          State.EnemyGroupIndices[J] := InitCode.LocalVar.GetVar(State.EnemyGroupNames[J]).GetInt;
    end;
    for I := 0 to Places.Count - 1 do
    begin
      Place := TScriptPlace(Places[I]);
      if Place.OriginVarName <> '' then Place.OriginStar := TStar(InitCode.LocalVar.GetVar(Place.OriginVarName).GetDword);
      if Place.TargetVarName <> '' then Place.TargetValue := InitCode.LocalVar.GetVar(Place.TargetVarName).GetDword;
    end;
    for I := 0 to Items.Count - 1 do
    begin
      ScriptItem := TScriptItem(Items[I]);
      Item := nil;
      if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 0) then
      begin
        Item := TFuelTanks.Create;
        (Item as TFuelTanks).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 1) then
      begin
        Item := TEngine.Create;
        (Item as TEngine).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 2) then
      begin
        Item := TRadar.Create;
        (Item as TRadar).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 3) then
      begin
        Item := TScaner.Create;
        (Item as TScaner).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 4) then
      begin
        Item := TRepairRobot.Create;
        (Item as TRepairRobot).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 5) then
      begin
        Item := TCargoHook.Create;
        (Item as TCargoHook).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikEquipment) and (ScriptItem.DefinitionType = 6) then
      begin
        Item := TDefGenerator.Create;
        (Item as TDefGenerator).Init(False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if ScriptItem.DefinitionKind = sikEquipment then RaiseWideMessage('Script unknow item type')
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 0) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_PhotonGun, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 1) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_IndustrialLaser, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 2) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_ZipGun, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 3) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_GravitonBeamer, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 4) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_Retractor, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 5) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_KellersPhaser, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 6) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_AeonicBlaster, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 7) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_XDefibrillator, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 8) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_SubmesonicGun, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 9) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_FieldAnnihilator, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 10) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_TachionCleaver, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 11) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_VortexProjector, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 12) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_AbsoluteMatrix, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 13) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_HellWave, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikWeapon) and (ScriptItem.DefinitionType = 14) then
      begin
        Item := TWeapon.Create;
        (Item as TWeapon).Init(t_EyesOfMachpella, False, ScriptItem.Weight, ScriptItem.Level, ScriptItem.OwnerId);
      end
      else if ScriptItem.DefinitionKind = sikWeapon then RaiseWideMessage('Script unknow item type')
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 0) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Food, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 1) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Medicine, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 2) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Technics, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 3) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Luxury, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 4) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Minerals, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 5) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Minerals, ScriptItem.Weight);
        (Item as TGoods).NaturalFlag := True;
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 6) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Alcohol, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 7) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Arms, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 8) then
      begin
        Item := TGoods.Create;
        (Item as TGoods).Init(t_Narcotics, ScriptItem.Weight);
      end
      else if (ScriptItem.DefinitionKind = sikGoods) and (ScriptItem.DefinitionType = 9) then RaiseWideMessage('Script. Protoplasm not support')
      else if ScriptItem.DefinitionKind = sikGoods then RaiseWideMessage('Script unknow item type')
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 0) then
      begin
        Item := TArtefactHull.Create;
        (Item as TArtefactHull).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 1) then
      begin
        Item := TArtefactFuel.Create;
        (Item as TArtefactFuel).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 2) then
      begin
        Item := TArtefactSpeed.Create;
        (Item as TArtefactSpeed).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 3) then
      begin
        Item := TArtefactPower.Create;
        (Item as TArtefactPower).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 4) then
      begin
        Item := TArtefactRadar.Create;
        (Item as TArtefactRadar).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 5) then
      begin
        Item := TArtefactScaner.Create;
        (Item as TArtefactScaner).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 6) then
      begin
        Item := TArtefactDroid.Create;
        (Item as TArtefactDroid).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 7) then
      begin
        Item := TArtefactNano.Create;
        (Item as TArtefactNano).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 8) then
      begin
        Item := TArtefactHook.Create;
        (Item as TArtefactHook).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 9) then
      begin
        Item := TArtefactDef.Create;
        (Item as TArtefactDef).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 10) then
      begin
        Item := TArtefactAnalyzer.Create;
        (Item as TArtefactAnalyzer).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 11) then
      begin
        Item := TArtefactMiniExpl.Create;
        (Item as TArtefactMiniExpl).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 12) then
      begin
        Item := TArtefactAntigrav.Create;
        (Item as TArtefactAntigrav).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 13) then
      begin
        Item := TArtefactTransmitter.Create;
        (Item as TArtefactTransmitter).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 14) then
      begin
        Item := TArtefactBomb.Create;
        (Item as TArtefactBomb).Init(ScriptItem.OwnerId);
      end
      else if (ScriptItem.DefinitionKind = sikArtefact) and (ScriptItem.DefinitionType = 15) then
      begin
        Item := TArtefactTranclucator.Create;
        (Item as TArtefactTranclucator).Init(ScriptItem.OwnerId, nil, nil);
      end
      else if ScriptItem.DefinitionKind = sikArtefact then RaiseWideMessage('Script unknow item type')
      else if ScriptItem.DefinitionKind = sikUselessItem then
      begin
        Item := TUselessItem.Create;
        (Item as TUselessItem).Init(ScriptItem.ConfigName, 0);
      end
      else if ScriptItem.DefinitionKind = sikNone then Continue
      else RaiseWideMessage('Script unknow item type');
      Item.ScriptItem := ScriptItem;
      if InitCode.LocalVar.GetVar(ScriptItem.LocationVarName).GetDword < 255 then
      begin
        Group := TScriptGroup(Groups[InitCode.LocalVar.GetVar(ScriptItem.LocationVarName).GetDword]);
        J := 0;
        while J < Group.Ships.Count do
        begin
          Ship := TShip(Group.Ships[J]);
          if Ship.CargoFreeSpace >= Item.Weight then Break;
          Inc(J);
        end;
        if J < Group.Ships.Count then
        begin
          Ship := TShip(Group.Ships[J]);
          if Item is TGoods then
          begin
            Inc(Ship.CargoGoods[Item.ItemType].Count, TGoods(Item).Quantity);
            Item.Free;
            Item := nil;
          end
          else if Item is TArtefact then
          begin
            Ship.Artefacts.Add(Item);
            if Item is TArtefactTranclucator then
              ((Item as TArtefactTranclucator).Ship as TTranclucator).OwnerShip := Ship;
          end
          else
          begin
            Ship.Inventory.Add(Item);
            Ship.EquipItem(Item as TEquipment);
          end;
          Ship.RefreshDerivedStats;
        end
        else if Item is TGoods then
        begin
          for J := 0 to Group.Ships.Count - 1 do
          begin
            Ship := TShip(Group.Ships[J]);
            if Ship.CargoFreeSpace < TGoods(Item).Quantity then
            begin
              Inc(Ship.CargoGoods[Item.ItemType].Count, Ship.CargoFreeSpace);
              // Native code adds free space to the remaining quantity here.
              Inc(TGoods(Item).Quantity, Ship.CargoFreeSpace);
              Ship.RefreshDerivedStats;
            end
            else
            begin
              Inc(Ship.CargoGoods[Item.ItemType].Count, TGoods(Item).Quantity);
              TGoods(Item).Quantity := 0;
              Ship.RefreshDerivedStats;
              Break;
            end;
          end;
          if TGoods(Item).Quantity > 0 then
          begin
            Ship := TShip(Group.Ships[0]);
            Inc(Ship.CargoGoods[Item.ItemType].Count, TGoods(Item).Quantity);
          end;
          Item.Free;
          Item := nil;
        end
        else
        begin
          Ship := TShip(Group.Ships[0]);
          if Item is TArtefact then Ship.Artefacts.Add(Item)
          else
          begin
            Ship.Inventory.Add(Item);
            Ship.EquipItem(Item as TEquipment);
          end;
          Ship.RefreshDerivedStats;
        end;
      end
      else if TObject(InitCode.LocalVar.GetVar(ScriptItem.LocationVarName).GetDword) is TPlanet then
      begin
        Planet := TPlanet(InitCode.LocalVar.GetVar(ScriptItem.LocationVarName).GetDword);
        Planet.EquipmentShop.Add(Item);
      end
      else
      begin
        Place := TScriptPlace(InitCode.LocalVar.GetVar(ScriptItem.LocationVarName).GetDword);
        if (Place.PlaceKind <> spkPolar) and (Place.PlaceKind <> spkPlanetPosition) and (Place.PlaceKind <> spkStarDirection) and (Place.PlaceKind <> spkGroupCentroid) then RaiseWideMessage('Script error place type');
        Item.Position := Place.GetPoint;
        for K := 0 to 3 do
        begin
          SubCount := Place.OriginStar.Items.Count;
          J := 0;
          while J < SubCount do
          begin
            OtherItem := TItem(Place.OriginStar.Items[J]);
            if PointDistanceSquared(Item.Position, OtherItem.Position) < 16 - 2 * K then Break;
            Inc(J);
          end;
          if J >= SubCount then Break;
          Balance := HeadingDegreesToRadians(SeededRandomIntRange(0, 360,
            Galaxy.GenerationSeed * Galaxy.CurrentTurn * (I + K + 1)));
          Radius := SeededRandomIntRange(0, Place.Radius,
            Galaxy.GenerationSeed * Galaxy.CurrentTurn * (I + K + 1 + 457) * 341);
          Item.Position := Place.GetPoint;
          Item.Position.X := Item.Position.X + Sin(Balance) * Radius;
          Item.Position.Y := Item.Position.Y - Cos(Balance) * Radius;
        end;
        Place.OriginStar.Items.Add(Item);
      end;
      ScriptItem.Item := Item;
    end;
    for I := 0 to Ships.Count - 1 do
    begin
      Binding := TScriptShip(Ships[I]);
      ChangeState(Binding, TScriptGroup(Groups[Binding.GroupIndex]).InitialStateIndex);
    end;
    for I := 0 to Stars.Count - 1 do
    begin
      Star := TScriptStar(Stars[I]);
      if Star.ProtectStar then Galaxy.CancelEnemyJumpsToStar(Star.Star);
    end;
  end;
  Result := True;
end;
{ @end $53935C }

{ @routine $53C6E0 TScript_LoadFromFile }
function TScript.LoadFromFile(FileName: WideString; AnchorStar: TStar; FirstPlanet: TPlanet; CreateObjects: Boolean): Boolean;
var
  Control: TCBufControlEC;
  CachedBuffer: TCBufEC;
begin
  Control := nil;
  ScriptFileName := FileName;
  try
    Control := TCBufControlEC.Create;
    GlobalCache.ResetControl(Control);
    Control.SetCacheKey(FileName);
    CachedBuffer := AcquireOrCreateBuffer(Control);
    Result := LoadFromBuffer(CachedBuffer.Buffer, AnchorStar, FirstPlanet, CreateObjects);
  finally
    if Control <> nil then begin
      Control.Release;
      Control.Free;
    end;
  end;
end;
{ @end $53C6E0 }

{ @routine $53C7C0 TScript_SaveState }
procedure TScript.SaveState(Buffer: TBufEC);
var
  I, J, Count: Integer;
  Binding: TScriptShip;
  Cell: TVarEC;
  Kind: TVarKind;
  Star: TScriptStar;
  ScriptItem: TScriptItem;
begin
  Buffer.AddWideStringZ(ScriptFileName);
  Ether.SaveToBuffer(Buffer);
  Count := InitCode.LocalVar.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Cell := InitCode.LocalVar.GetItem(I);
    Kind := Cell.Kind;
    if Kind = vkEmpty then
    begin
      Buffer.AddWideStringZ(Cell.Name);
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
    end
    else if Kind = vkInt then
    begin
      Buffer.AddWideStringZ(Cell.Name);
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
      Buffer.AddIntegerValue(Cell.GetInt);
    end
    else if Kind = vkDword then
    begin
      Buffer.AddWideStringZ(Cell.Name);
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
      Buffer.AddDWord(Cell.GetDword);
    end
    else if Kind = vkFloat then
    begin
      Buffer.AddWideStringZ(Cell.Name);
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
      Buffer.AddDouble(Cell.GetFloat);
    end
    else if Kind = vkString then
    begin
      Buffer.AddWideStringZ(Cell.Name);
      Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Kind)));
      Buffer.AddWideStringZ(Cell.GetString);
    end
    else raise Exception.Create('Error. Script. Unknown variable format.');
  end;
  Buffer.AddIntegerValue(Stars.Count);
  for I := 0 to Stars.Count - 1 do
  begin
    Star := TScriptStar(Stars[I]);
    Buffer.AddWideStringZ(Star.Name);
    Buffer.AddDWord(Star.Star.Id);
    if Star.Planets = nil then Buffer.AddIntegerValue(0)
    else
    begin
      Buffer.AddIntegerValue(High(Star.Planets) + 1);
      for J := 0 to High(Star.Planets) do
      begin
        Buffer.AddWideStringZ(Star.Planets[J].Name);
        Buffer.AddDWord(Star.Planets[J].Planet.Id);
      end;
    end;
    Buffer.AddIntegerValue(0);
  end;
  Buffer.AddIntegerValue(Items.Count);
  for I := 0 to Items.Count - 1 do
  begin
    ScriptItem := TScriptItem(Items[I]);
    Buffer.AddWideStringZ(ScriptItem.Name);
    if ScriptItem.Item = nil then Buffer.AddDWord(0)
    else Buffer.AddDWord(ScriptItem.Item.Id);
  end;
  Count := Ships.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip(Ships[I]);
    Buffer.AddIntegerValue(Binding.GroupIndex);
    Buffer.AddDWord(Binding.Ship.Id);
    Buffer.AddDWord(Binding.Data[0]);
    Buffer.AddDWord(Binding.Data[1]);
    Buffer.AddDWord(Binding.Data[2]);
    Buffer.AddDWord(Binding.Data[3]);
    Buffer.AddIntegerValue(States.IndexOf(Binding.State));
    Buffer.AddBoolean(Binding.Hit);
    Buffer.AddBoolean(Binding.HitPlayer);
  end;
  Buffer.AddWideChar(WideChar(EtherIds.GetCount));
  for I := 0 to EtherIds.GetCount - 1 do Buffer.AddWideStringZ(EtherIds.GetTextAt(I));
end;
{ @end $53C7C0 }

{ @routine $53CC08 TScript_LoadState }
procedure TScript.LoadState(Buffer: TBufEC);
var
  I, J, Count, SubCount, StateIndex: Integer;
  Binding: TScriptShip;
  Name: WideString;
  Cell: TVarEC;
  Kind: TVarKind;
  Star: TScriptStar;
  PlanetBinding: PScriptPlanetBinding;
  ScriptItem: TScriptItem;
begin
  if not LoadFromFile(Buffer.ReadWideString, nil, nil, False) then
    raise Exception.Create('Error. Script.GameLoad');
  Ether.LoadFromBuffer(Buffer);
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Name := Buffer.ReadWideString;
    Cell := InitCode.LocalVar.GetVarNE(Name);
    if Cell = nil then raise Exception.Create('Error.Script.GameLoad variable not found');
    WriteByteValue(Buffer.GetByte, Kind);
    if Kind = vkEmpty then begin end
    else if Kind = vkInt then Cell.SetInt(Buffer.GetInt32)
    else if Kind = vkDword then Cell.SetDword(Buffer.GetUInt32)
    else if Kind = vkFloat then Cell.SetFloat(Buffer.GetDouble)
    else if Kind = vkString then Cell.SetString(Buffer.ReadWideString)
    else raise Exception.Create('Error. Script. Unknown variable format.');
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Name := Buffer.ReadWideString;
    Star := GetStar(Name);
    Star.Star := Galaxy.IdToStar(Buffer.GetUInt32) as TStar;
    InitCode.LocalVar.GetVar(Star.Name).SetDword(Cardinal(Star.Star));
    SubCount := Buffer.GetInt32;
    for J := 0 to SubCount - 1 do
    begin
      Name := Buffer.ReadWideString;
      PlanetBinding := GetPlanetBinding(Name);
      PlanetBinding.Planet := Galaxy.IdToPlanet(Buffer.GetUInt32) as TPlanet;
      InitCode.LocalVar.GetVar(PlanetBinding.Name).SetDword(Cardinal(PlanetBinding.Planet));
    end;
    Buffer.GetInt32;
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    Name := Buffer.ReadWideString;
    ScriptItem := GetItem(Name);
    InitCode.LocalVar.GetVar(Name).SetDword(Cardinal(ScriptItem));
    ScriptItem.Item := Galaxy.IdToItem(Buffer.GetUInt32) as TItem;
    if ScriptItem.Item <> nil then ScriptItem.Item.ScriptItem := ScriptItem;
  end;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip.Create;
    Ships.Add(Binding);
    Binding.Script := Self;
    Binding.GroupIndex := Buffer.GetInt32;
    Binding.Ship := TShip(Buffer.GetUInt32);
    Binding.Data[0] := Buffer.GetUInt32;
    Binding.Data[1] := Buffer.GetUInt32;
    Binding.Data[2] := Buffer.GetUInt32;
    Binding.Data[3] := Buffer.GetUInt32;
    StateIndex := Buffer.GetInt32;
    if StateIndex >= 0 then Binding.State := TScriptState(States[StateIndex])
    else Binding.State := nil;
    Binding.Hit := Buffer.GetBoolean;
    Binding.HitPlayer := Buffer.GetBoolean;
  end;
  EtherIds.Clear;
  if LoadedSaveVersion >= 6 then
  begin
    Count := Buffer.GetWord;
    for I := 0 to Count - 1 do EtherIds.Add(Buffer.ReadWideString);
  end;
end;
{ @end $53CC08 }

{ @routine $53D040 TScript_ResolveLoadedReferences }
procedure TScript.ResolveLoadedReferences;
var
  I, J, Count: Integer;
  Binding: TScriptShip;
  State: TScriptState;
  Place: TScriptPlace;
begin
  Count := Ships.Count;
  for I := 0 to Count - 1 do
  begin
    Binding := TScriptShip(Ships[I]);
    Binding.Ship := TObject(Galaxy.IdToShip(Cardinal(Binding.Ship), True)) as TShip;
    if Binding.Ship is TPlayer then TPlayer(Binding.Ship).ScriptShipBindings.Add(Binding)
    else Binding.Ship.ScriptShip := Binding;
  end;
  for I := 0 to Places.Count - 1 do
  begin
    Place := TScriptPlace(Places[I]);
    InitCode.LocalVar.GetVar(Place.Name).SetDword(Cardinal(Place));
    if Place.OriginVarName <> '' then Place.OriginStar := TStar(InitCode.LocalVar.GetVar(Place.OriginVarName).GetDword);
    if Place.TargetVarName <> '' then Place.TargetValue := InitCode.LocalVar.GetVar(Place.TargetVarName).GetDword;
  end;
  for I := 0 to States.Count - 1 do
  begin
    State := TScriptState(States[I]);
    if State.TargetVarName <> '' then State.TargetValue := InitCode.LocalVar.GetVar(State.TargetVarName).GetDword;
    if State.EnemyGroupIndices <> nil then
      for J := 0 to High(State.EnemyGroupIndices) do
        State.EnemyGroupIndices[J] := InitCode.LocalVar.GetVar(State.EnemyGroupNames[J]).GetInt;
  end;
end;
{ @end $53D040 }

end.

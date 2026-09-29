unit aEFilm;
// Unit bracket (inferred): CODE 0x005FDB64..0x005FF9FB; inclusive evidence, not full bounds.

interface

uses Classes, EC_Buf, EC_Str, EC_Struct, SE_Process, SE_Space, Types, aEObjInfo;

const
  // Native serialized tags. Kind remains Byte so unknown values stay representable.
  efcSetObjectPosition = 0;
  efcSetObjectOrbitCenter = 1;
  efcSetObjectAlpha = 2;
  efcSetObjectAngle = 3;
  efcAdvanceObject = 4; // No recovered writer; playback calls TObjectSE.Advance.
  efcAdvanceObjects = 5;
  efcSetPlanetState = 6;
  efcSetShipSize = 7;
  efcSetWeaponHit = 8;
  efcSetWeaponEndpoints = 9;
  efcSetDestructionEffect = 10;
  efcAttachObject = 11;
  efcDetachObject = 12;
  efcReleaseObject = 13;
  efcReleaseWeaponEffects = 14;
  efcSetViewCenter = 15;
  efcSetRadarCenter = 16;
  efcSetCameraAnchor = 17;
  efcOpenGate = 18;
  efcCloseGate = 19;
  efcSetGateState = 20;
  efcSetHoleState = 21;
  efcSetObjectText = 22;
  efcSetObjectStateBuffer = 23;
  efcBeginTrailingEffects = 24; // Playback barrier; ExecuteCommand has no action for this tag.
  efcPlayPickupSound = 25;

  FilmNullObjectIndex = 65535; // Serialized nil; -1 separately means an unlisted object.

type
  TEFilmObj = class(TObject) // @size $1C
  public
    Prev: TEFilmObj; // @offset $4
    Next: TEFilmObj; // @offset $8
    ObjectId: Cardinal; // @offset $C
    SceneObject: TObjectSE; // @offset $10  Borrowed scene reference; nil after deserialization.
    KindName: WideString; // @offset $14
    GraphKey: WideString; // @offset $18
  end;

  PEFilmCommand = ^TEFilmCommand;
  TEFilmCommand = packed record // @size $20
    Prev: PEFilmCommand; // @offset $0
    Next: PEFilmCommand; // @offset $4
    Kind: Byte; // @offset $8  efc* tag; payload is interpreted through the command views below.
    StepIndex: Integer; // @offset $C
    Payload: array[0..15] of Byte; // @offset $10
  end;

  PEFilmObjectCommand = ^TEFilmObjectCommand;
  TEFilmObjectCommand = packed record // @size $20 Scalar object-command payload view.
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Value: Integer; // @offset $14
    ExtraValue: Integer; // @offset $18
    Flags: Integer; // @offset $1C
  end;

  PEFilmVectorCommand = ^TEFilmVectorCommand;
  TEFilmVectorCommand = packed record // @size $20
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Position: TPointF; // @offset $14
    ForceMovement: Boolean; // @offset $1C
  end;

  PEFilmSizeCommand = ^TEFilmSizeCommand;
  TEFilmSizeCommand = packed record // @size $20
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Size: TPoint; // @offset $14
  end;

  PEFilmByteCommand = ^TEFilmByteCommand;
  TEFilmByteCommand = packed record // @size $20
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Value: Byte; // @offset $14
  end;

  PEFilmHitCommand = ^TEFilmHitCommand;
  TEFilmHitCommand = packed record // @size $20
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Color: Word; // @offset $14
    Damage: Integer; // @offset $18
    Destroyed: Boolean; // @offset $1C
    PlaySound: Boolean; // @offset $1D
  end;

  PEFilmEndpointsCommand = ^TEFilmEndpointsCommand;
  TEFilmEndpointsCommand = packed record // @size $20
    Kind: Byte; // @offset $8
    StepIndex: Integer; // @offset $C
    Obj: TEFilmObj; // @offset $10
    Source: TEFilmObj; // @offset $14
    Target: TEFilmObj; // @offset $18
  end;

  PEFilmCameraEvent = ^TEFilmCameraEvent;
  TEFilmCameraEvent = packed record // @size $18
    StepIndex: Integer; // @offset $0
    Priority: Integer; // @offset $4
    StartPosition: TPointF; // @offset $8
    EndPosition: TPointF; // @offset $10
  end;

  PEFilmCameraEventArray = ^TEFilmCameraEventArray;
  TEFilmCameraEventArray = array[0..0] of TEFilmCameraEvent;
  TEFilmCameraEvents = array of TEFilmCameraEvent;

  TEFilm = class(TObjectEx) // @size $5C
  public
    FirstObject: TEFilmObj; // @offset $4
    LastObject: TEFilmObj; // @offset $8
    FirstCommand: PEFilmCommand; // @offset $C
    LastCommand: PEFilmCommand; // @offset $10
    FirstFreeCommand: PEFilmCommand; // @offset $14
    LastFreeCommand: PEFilmCommand; // @offset $18
    CameraEvents: array of TEFilmCameraEvent; // @offset $1C
    CameraEventCount: Integer; // @offset $20
    StringTable: TStringsEC; // @offset $24
    DataBuffers: TList; // @offset $28  Owned TBufEC entries.
    SystemProcessName: WideString; // @offset $2C
    MapDiameter: Integer; // @offset $30
    RadarRange: Integer; // @offset $34
    Turn: Integer; // @offset $38  Stored by TFilmFile, outside this film's serialized payload.
    PlayerCombatRecorded: Boolean; // @offset $3C  Set from RecordFilm and the star player-combat flag.
    StarGenerationSeed: Cardinal; // @offset $40
    InitialActivity: Integer; // @offset $44  Activity categories used to select film playback speed.
    FinalActivity: Integer; // @offset $48
    CameraAnchor: TPointF; // @offset $4C
    ForceCameraMovement: Boolean; // @offset $54
    ObjectInfo: TObject; // @offset $58 Native callers cast this snapshot to TEObjInfo.

    constructor Create; // @addr $5FDC64
    destructor Destroy; override; // @addr $5FDCC8
    procedure Clear; // @addr $5FDD58
    procedure ReserveCameraEventSlot; // @addr $5FDDC0 Grows capacity and advances the used count without writing the new slot.
    procedure RemoveObject(Obj: TEFilmObj); // @addr $5FDEA8
    function ObjectCount: Integer; // @addr $5FDEE4
    function FindObjectIndex(Obj: TEFilmObj): Integer; // @addr $5FDF44 Nil maps to 65535; an absent non-nil object maps to -1.
    procedure GrowCommandPool(Count: Integer); // @addr $5FE044
    procedure RecycleCommands(First, Last: PEFilmCommand); // @addr $5FE080 Moves an inclusive linked range to the free list.
    procedure AppendCommand(Command: PEFilmCommand); // @addr $5FE0D4
    procedure InsertCommand(Before, Command: PEFilmCommand); // @addr $5FE0F8 Nil Before appends.
    function AddCommand(StepIndex: Integer): PEFilmCommand; // @addr $5FE174 Stable insertion by step index.
    function CommandCount: Integer; // @addr $5FE1D8
    function AllocateObject: TEFilmObj; // @addr $5FDE74 @note "Appends an object owned by this film."
    function ObjToNom(Obj: TEFilmObj): Integer; // @addr $5FDEF8 @note "Zero-based list index; nil maps to 65535. Raises for an object outside this film."
    function NomToObj(Index: Integer): TEFilmObj; // @addr $5FDF6C @note "Returns a borrowed object. Index 65535 maps to nil; other missing indexes raise."
    function FindObject(const KindName, GraphKey: WideString; ObjectId: Cardinal): TEFilmObj; // @addr $5FDFCC @note "Matches all three keys; returns a borrowed object or nil."
    function FindObjectById(const KindName: WideString; ObjectId: Cardinal): TEFilmObj; // @addr $5FE014
    function ContainsObject(Obj: TEFilmObj): Boolean; // @addr $5FDFB4
    function AllocateCommand: PEFilmCommand; // @addr $5FE13C @note "Returns a zeroed pooled command without linking it into the command list."
    function AddObject(ObjectId: Cardinal; SceneObject: TObjectSE; Unused1: Integer = 0; Unused2: Integer = 0): TEFilmObj; // @addr $5FE1EC @note "Stores SceneObject and copies its class name and graph key. Both stack arguments are unused."
    procedure AddCameraEvent(AStepIndex: Integer; AStartPosition, AEndPosition: TPointF; APriority: Integer); // @addr $5FDDF4
    procedure SetObjectPosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF); // @addr $5FE25C
    procedure SetWeaponHit(StepIndex: Integer; Obj: TEFilmObj; Color: Word; Damage: Integer; Destroyed, PlaySound: Boolean); // @addr $5FE454
    procedure SetWeaponEndpoints(StepIndex: Integer; Obj, Source, Target: TEFilmObj); // @addr $5FE4B0 @note "Source and Target may be nil; Obj must exist."
    procedure AttachObject(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE520
    procedure DetachObject(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE55C
    procedure SetObjectText(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString); // @addr $5FE6A4
    procedure SetObjectAlpha(StepIndex: Integer; Obj: TEFilmObj; Alpha: Byte); // @addr $5FE2F0
    procedure SetObjectAngle(StepIndex: Integer; Obj: TEFilmObj; Angle: Byte); // @addr $5FE338
    procedure SetViewCenter(StepIndex: Integer; Position: TPointF); // @addr $5FE5B8
    procedure SetRadarCenter(StepIndex: Integer; Position: TPointF); // @addr $5FE5E0
    procedure SetCameraAnchor(StepIndex: Integer; Position: TPointF; ForceMovement: Boolean); // @addr $5FE608
    procedure OpenGate(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE63C
    procedure SetGateState(StepIndex: Integer; Obj: TEFilmObj; State: Integer); // @addr $5FE664
    procedure AdvanceObjects(StepIndex: Integer); // @addr $5FE380
    procedure SetDestructionEffect(StepIndex: Integer; Obj: TEFilmObj; Effect: Integer); // @addr $5FE500
    procedure ReleaseObject(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE598
    procedure ReleaseWeaponEffects(StepIndex: Integer); // @addr $5FE5AC
    procedure CloseGate(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE650
    procedure SetHoleState(StepIndex: Integer; Obj: TEFilmObj; State: Integer); // @addr $5FE684
    procedure BeginTrailingEffects(StepIndex: Integer); // @addr $5FE714
    procedure PlayPickupSound(StepIndex: Integer; Obj: TEFilmObj); // @addr $5FE720

    procedure SetObjectOrbitCenter(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF); // @addr $5FE2BC
    procedure SetPlanetState(StepIndex: Integer; Obj: TEFilmObj; RotationInterval, SurfaceMapStep: Integer; ScaleThousandths: Word; RingKind: Byte; Owner: TOwnerId); // @addr $5FE38C Scale is decoded as a signed 16-bit value divided by 1000 during playback.
    procedure SetShipSize(StepIndex: Integer; Obj: TEFilmObj; Size: TPoint); // @addr $5FE3F4
    procedure SetObjectStateBuffer(StepIndex: Integer; Obj: TEFilmObj; Buffer: TBufEC); // @addr $5FE6DC Transfers ownership of Buffer to the film.

    procedure ExecuteCommand(Process: TProcessSE; Command: PEFilmCommand; ReplayMode: Boolean); // @addr $5FE734
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $5FEC6C @note "Clears Buffer. Serializes object identities and commands, excluding live scene references and Turn."
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5FF29C @note "Clears the film and rewinds Buffer before reading. Scene objects are recreated separately."
  end;

const

implementation

// @unit-initialization $5FF9F4
// @unit-finalization $5FF9C4

uses Windows, SysUtils, EC_Mem, GR_Main, GR_GraphBuf, aMyFunction,
  SE_Planet, SE_Ship2, SE_Weapon, SE_Gate, SE_Hole, Globals, GlobalsV, aPlayer, fFilm, fStarMap, GR_Sound;

{ @routine $5FDC64 TEFilm_Create }
constructor TEFilm.Create;
begin
  inherited Create;
  StringTable := TStringsEC.Create;
  DataBuffers := TList.Create;
  ObjectInfo := TEObjInfo.Create;
end;
{ @end $5FDC64 }

{ @routine $5FDCC8 TEFilm_Destroy }
destructor TEFilm.Destroy;
var NextCommand, Command: PEFilmCommand;
begin
  Clear;
  NextCommand := FirstFreeCommand;
  while NextCommand <> nil do
  begin
    Command := NextCommand;
    NextCommand := NextCommand.Next;
    FreeEC(Command);
  end;
  FirstFreeCommand := nil;
  LastFreeCommand := nil;
  if StringTable <> nil then begin StringTable.Free; StringTable := nil end;
  if DataBuffers <> nil then begin DataBuffers.Free; DataBuffers := nil end;
  if ObjectInfo <> nil then begin ObjectInfo.Free; ObjectInfo := nil end;
  CameraEvents := nil;
  inherited Destroy;
end;
{ @end $5FDCC8 }

{ @routine $5FDD58 TEFilm_Clear }
procedure TEFilm.Clear;
var I, Count: Integer; Obj: TObject;
begin
  if FirstCommand <> nil then RecycleCommands(FirstCommand, LastCommand);
  while FirstObject <> nil do RemoveObject(LastObject);
  StringTable.Clear;
  Count := DataBuffers.Count;
  for I := 0 to Count - 1 do
  begin
    Obj := TObject(DataBuffers[I]);
    Obj.Free;
  end;
  DataBuffers.Clear;
  CameraEventCount := 0;
end;
{ @end $5FDD58 }

{ @routine $5FDDC0 TEFilm_ReserveCameraEventSlot }
procedure TEFilm.ReserveCameraEventSlot;
begin
  if CameraEventCount >= High(CameraEvents) then SetLength(CameraEvents, CameraEventCount + 30);
  Inc(CameraEventCount);
end;
{ @end $5FDDC0 }

{ @routine $5FDDF4 TEFilm_AddCameraEvent }
procedure TEFilm.AddCameraEvent(AStepIndex: Integer; AStartPosition, AEndPosition: TPointF; APriority: Integer);
begin
  if CameraEventCount >= High(CameraEvents) then SetLength(CameraEvents, CameraEventCount + 30);
  with CameraEvents[CameraEventCount] do
  begin
    StepIndex := AStepIndex;
    Priority := APriority;
    StartPosition := AStartPosition;
    EndPosition := AEndPosition;
  end;
  Inc(CameraEventCount);
end;
{ @end $5FDDF4 }

{ @routine $5FDE74 TEFilm_AllocateObject }
function TEFilm.AllocateObject: TEFilmObj;
var Obj: TEFilmObj;
begin
  Obj := TEFilmObj.Create;
  if LastObject <> nil then LastObject.Next := Obj;
  Obj.Prev := LastObject;
  Obj.Next := nil;
  LastObject := Obj;
  if FirstObject = nil then FirstObject := Obj;
  Result := Obj;
end;
{ @end $5FDE74 }

{ @routine $5FDEA8 TEFilm_RemoveObject }
procedure TEFilm.RemoveObject(Obj: TEFilmObj);
begin
  if Obj.Prev <> nil then Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then Obj.Next.Prev := Obj.Prev;
  if LastObject = Obj then LastObject := Obj.Prev;
  if FirstObject = Obj then FirstObject := Obj.Next;
  Obj.Free;
end;
{ @end $5FDEA8 }

{ @routine $5FDEE4 TEFilm_ObjectCount }
function TEFilm.ObjectCount: Integer;
var Count: Integer; Entry: TEFilmObj;
begin
  Count := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
end;
{ @end $5FDEE4 }

{ @routine $5FDEF8 TEFilm_ObjToNom }
function TEFilm.ObjToNom(Obj: TEFilmObj): Integer;
var Index: Integer; Entry: TEFilmObj;
begin
  if Obj = nil then begin Result := FilmNullObjectIndex; Exit end;
  Index := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry = Obj then begin Result := Index; Exit end;
    Inc(Index);
    Entry := Entry.Next;
  end;
  raise Exception.Create('Error');
  Result := -1;
end;
{ @end $5FDEF8 }

{ @routine $5FDF44 TEFilm_FindObjectIndex }
function TEFilm.FindObjectIndex(Obj: TEFilmObj): Integer;
var Index: Integer; Entry: TEFilmObj;
begin
  if Obj = nil then begin Result := FilmNullObjectIndex; Exit end;
  Index := 0;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Entry = Obj then begin Result := Index; Exit end;
    Inc(Index);
    Entry := Entry.Next;
  end;
  Result := -1;
end;
{ @end $5FDF44 }

{ @routine $5FDF6C TEFilm_NomToObj }
function TEFilm.NomToObj(Index: Integer): TEFilmObj;
var Entry: TEFilmObj;
begin
  if Index = FilmNullObjectIndex then begin Result := nil; Exit end;
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Index = 0 then begin Result := Entry; Exit end;
    Dec(Index);
    Entry := Entry.Next;
  end;
  raise Exception.Create('Error');
  Result := nil;
end;
{ @end $5FDF6C }

{ @routine $5FDFB4 TEFilm_ContainsObject }
function TEFilm.ContainsObject(Obj: TEFilmObj): Boolean;
var Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if Obj = Entry then begin Result := True; Exit; end;
    Entry := Entry.Next;
  end;
  Result := False;
end;
{ @end $5FDFB4 }

{ @routine $5FDFCC TEFilm_FindObject }
function TEFilm.FindObject(const KindName, GraphKey: WideString; ObjectId: Cardinal): TEFilmObj;
var Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if (Entry.ObjectId = ObjectId) and (Entry.KindName = KindName) and (Entry.GraphKey = GraphKey) then
    begin Result := Entry; Exit end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $5FDFCC }

{ @routine $5FE014 TEFilm_FindObjectById }
function TEFilm.FindObjectById(const KindName: WideString; ObjectId: Cardinal): TEFilmObj;
var
  Entry: TEFilmObj;
begin
  Entry := FirstObject;
  while Entry <> nil do
  begin
    if (Entry.ObjectId = ObjectId) and (Entry.KindName = KindName) then
    begin
      Result := Entry;
      Exit;
    end;
    Entry := Entry.Next;
  end;
  Result := nil;
end;
{ @end $5FE014 }

{ @routine $5FE044 TEFilm_GrowCommandPool }
procedure TEFilm.GrowCommandPool(Count: Integer);
var Command: PEFilmCommand;
begin
  while Count > 0 do
  begin
    Command := AllocEC(SizeOf(TEFilmCommand));
    if LastFreeCommand <> nil then LastFreeCommand.Next := Command;
    Command.Prev := LastFreeCommand;
    Command.Next := nil;
    LastFreeCommand := Command;
    if FirstFreeCommand = nil then FirstFreeCommand := Command;
    Dec(Count);
  end;
end;
{ @end $5FE044 }

{ @routine $5FE080 TEFilm_RecycleCommands }
procedure TEFilm.RecycleCommands(First, Last: PEFilmCommand);
begin
  if First.Prev <> nil then First.Prev.Next := Last.Next;
  if Last.Next <> nil then Last.Next.Prev := First.Prev;
  if Last = LastCommand then LastCommand := First.Prev;
  if First = FirstCommand then FirstCommand := Last.Next;
  if LastFreeCommand <> nil then LastFreeCommand.Next := First;
  First.Prev := LastFreeCommand;
  Last.Next := nil;
  LastFreeCommand := Last;
  if FirstFreeCommand = nil then FirstFreeCommand := First;
end;
{ @end $5FE080 }

{ @routine $5FE0D4 TEFilm_AppendCommand }
procedure TEFilm.AppendCommand(Command: PEFilmCommand);
begin
  if LastCommand <> nil then LastCommand.Next := Command;
  Command.Prev := LastCommand;
  Command.Next := nil;
  LastCommand := Command;
  if FirstCommand = nil then FirstCommand := Command;
end;
{ @end $5FE0D4 }

{ @routine $5FE0F8 TEFilm_InsertCommand }
procedure TEFilm.InsertCommand(Before, Command: PEFilmCommand);
begin
  if Before <> nil then
  begin
    Command.Prev := Before.Prev;
    Command.Next := Before;
    if Before.Prev <> nil then Before.Prev.Next := Command;
    Before.Prev := Command;
    if Before = FirstCommand then FirstCommand := Command;
  end
  else
  begin
    if LastCommand <> nil then LastCommand.Next := Command;
    Command.Prev := LastCommand;
    Command.Next := nil;
    LastCommand := Command;
    if FirstCommand = nil then FirstCommand := Command;
  end;
end;
{ @end $5FE0F8 }

{ @routine $5FE13C TEFilm_AllocateCommand }
function TEFilm.AllocateCommand: PEFilmCommand;
var Command: PEFilmCommand;
begin
  if FirstFreeCommand = LastFreeCommand then GrowCommandPool(500);
  Command := FirstFreeCommand;
  Command.Next.Prev := nil;
  FirstFreeCommand := Command.Next;
  ZeroMemory(Command, SizeOf(TEFilmCommand));
  Result := Command;
end;
{ @end $5FE13C }

{ @routine $5FE174 TEFilm_AddCommand }
function TEFilm.AddCommand(StepIndex: Integer): PEFilmCommand;
var Command, Entry: PEFilmCommand;
begin
  Command := AllocateCommand;
  Command.StepIndex := StepIndex;
  if (LastCommand = nil) or (LastCommand.StepIndex <= StepIndex) then
  begin
    AppendCommand(Command);
    Result := Command;
  end
  else
  begin
    Entry := FirstCommand;
    while Entry <> nil do
    begin
      if Entry.StepIndex > StepIndex then
      begin
        InsertCommand(Entry, Command);
        Break;
      end;
      Entry := Entry.Next;
    end;
    if Entry = nil then AppendCommand(Command);
    Result := Command;
  end;
end;
{ @end $5FE174 }

{ @routine $5FE1D8 TEFilm_CommandCount }
function TEFilm.CommandCount: Integer;
var Count: Integer; Entry: PEFilmCommand;
begin
  Count := 0;
  Entry := FirstCommand;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
end;
{ @end $5FE1D8 }

{ @routine $5FE1EC TEFilm_AddObject }
function TEFilm.AddObject(ObjectId: Cardinal; SceneObject: TObjectSE; Unused1, Unused2: Integer): TEFilmObj;
var Obj: TEFilmObj;
begin
  Obj := AllocateObject;
  Obj.ObjectId := ObjectId;
  Obj.SceneObject := SceneObject;
  Obj.KindName := ClassSEtoName(SceneObject);
  Obj.GraphKey := SceneObject.GraphKey;
  Result := Obj;
end;
{ @end $5FE1EC }

{ @routine $5FE25C TEFilm_SetObjectPosition }
procedure TEFilm.SetObjectPosition(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectPosition;
  TEFilmVectorCommand(Command^).Obj := Obj;
  TEFilmVectorCommand(Command^).Position := Position;
end;
{ @end $5FE25C }

{ @routine $5FE2BC TEFilm_SetObjectOrbitCenter }
procedure TEFilm.SetObjectOrbitCenter(StepIndex: Integer; Obj: TEFilmObj; Position: TPointF);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectOrbitCenter;
  TEFilmVectorCommand(Command^).Obj := Obj;
  TEFilmVectorCommand(Command^).Position := Position;
end;
{ @end $5FE2BC }

{ @routine $5FE2F0 TEFilm_SetObjectAlpha }
procedure TEFilm.SetObjectAlpha(StepIndex: Integer; Obj: TEFilmObj; Alpha: Byte);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectAlpha;
  TEFilmByteCommand(Command^).Obj := Obj;
  TEFilmByteCommand(Command^).Value := Alpha;
end;
{ @end $5FE2F0 }

{ @routine $5FE338 TEFilm_SetObjectAngle }
procedure TEFilm.SetObjectAngle(StepIndex: Integer; Obj: TEFilmObj; Angle: Byte);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectAngle;
  TEFilmByteCommand(Command^).Obj := Obj;
  TEFilmByteCommand(Command^).Value := Angle;
end;
{ @end $5FE338 }

{ @routine $5FE380 TEFilm_AdvanceObjects }
procedure TEFilm.AdvanceObjects(StepIndex: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcAdvanceObjects;
end;
{ @end $5FE380 }

{ @routine $5FE38C TEFilm_SetPlanetState }
procedure TEFilm.SetPlanetState(StepIndex: Integer; Obj: TEFilmObj; RotationInterval, SurfaceMapStep: Integer; ScaleThousandths: Word; RingKind: Byte; Owner: TOwnerId);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetPlanetState;
  TEFilmObjectCommand(Command^).Obj := Obj;
  TEFilmObjectCommand(Command^).Value := (Integer(RingKind) shl 24) or RotationInterval;
  TEFilmObjectCommand(Command^).ExtraValue := SurfaceMapStep;
  TEFilmObjectCommand(Command^).Flags := ScaleThousandths or (Ord(Owner) shl 24);
end;
{ @end $5FE38C }

{ @routine $5FE3F4 TEFilm_SetShipSize }
procedure TEFilm.SetShipSize(StepIndex: Integer; Obj: TEFilmObj; Size: TPoint);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetShipSize;
  TEFilmSizeCommand(Command^).Obj := Obj;
  TEFilmSizeCommand(Command^).Size := Size;
end;
{ @end $5FE3F4 }

{ @routine $5FE454 TEFilm_SetWeaponHit }
procedure TEFilm.SetWeaponHit(StepIndex: Integer; Obj: TEFilmObj; Color: Word; Damage: Integer; Destroyed, PlaySound: Boolean);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetWeaponHit;
  TEFilmHitCommand(Command^).Obj := Obj;
  TEFilmHitCommand(Command^).Color := Color;
  TEFilmHitCommand(Command^).Damage := Damage;
  TEFilmHitCommand(Command^).Destroyed := Destroyed;
  TEFilmHitCommand(Command^).PlaySound := PlaySound;
end;
{ @end $5FE454 }

{ @routine $5FE4B0 TEFilm_SetWeaponEndpoints }
procedure TEFilm.SetWeaponEndpoints(StepIndex: Integer; Obj, Source, Target: TEFilmObj);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetWeaponEndpoints;
  TEFilmEndpointsCommand(Command^).Obj := Obj;
  TEFilmEndpointsCommand(Command^).Source := Source;
  TEFilmEndpointsCommand(Command^).Target := Target;
end;
{ @end $5FE4B0 }

{ @routine $5FE500 TEFilm_SetDestructionEffect }
procedure TEFilm.SetDestructionEffect(StepIndex: Integer; Obj: TEFilmObj; Effect: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetDestructionEffect;
  TEFilmObjectCommand(Command^).Obj := Obj;
  TEFilmObjectCommand(Command^).Value := Effect;
end;
{ @end $5FE500 }

{ @routine $5FE520 TEFilm_AttachObject }
procedure TEFilm.AttachObject(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcAttachObject;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE520 }

{ @routine $5FE55C TEFilm_DetachObject }
procedure TEFilm.DetachObject(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  if Obj = nil then raise Exception.Create('obj=nil');
  Command := AddCommand(StepIndex);
  Command.Kind := efcDetachObject;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE55C }

{ @routine $5FE598 TEFilm_ReleaseObject }
procedure TEFilm.ReleaseObject(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcReleaseObject;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE598 }

{ @routine $5FE5AC TEFilm_ReleaseWeaponEffects }
procedure TEFilm.ReleaseWeaponEffects(StepIndex: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcReleaseWeaponEffects;
end;
{ @end $5FE5AC }

{ @routine $5FE5B8 TEFilm_SetViewCenter }
procedure TEFilm.SetViewCenter(StepIndex: Integer; Position: TPointF);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetViewCenter;
  TEFilmVectorCommand(Command^).Position := Position;
end;
{ @end $5FE5B8 }

{ @routine $5FE5E0 TEFilm_SetRadarCenter }
procedure TEFilm.SetRadarCenter(StepIndex: Integer; Position: TPointF);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetRadarCenter;
  TEFilmVectorCommand(Command^).Position := Position;
end;
{ @end $5FE5E0 }

{ @routine $5FE608 TEFilm_SetCameraAnchor }
procedure TEFilm.SetCameraAnchor(StepIndex: Integer; Position: TPointF; ForceMovement: Boolean);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetCameraAnchor;
  TEFilmVectorCommand(Command^).Position := Position;
  TEFilmVectorCommand(Command^).ForceMovement := ForceMovement;
end;
{ @end $5FE608 }

{ @routine $5FE63C TEFilm_OpenGate }
procedure TEFilm.OpenGate(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcOpenGate;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE63C }

{ @routine $5FE650 TEFilm_CloseGate }
procedure TEFilm.CloseGate(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcCloseGate;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE650 }

{ @routine $5FE664 TEFilm_SetGateState }
procedure TEFilm.SetGateState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetGateState;
  TEFilmObjectCommand(Command^).Obj := Obj;
  TEFilmObjectCommand(Command^).Value := State;
end;
{ @end $5FE664 }

{ @routine $5FE684 TEFilm_SetHoleState }
procedure TEFilm.SetHoleState(StepIndex: Integer; Obj: TEFilmObj; State: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetHoleState;
  TEFilmObjectCommand(Command^).Obj := Obj;
  TEFilmObjectCommand(Command^).Value := State;
end;
{ @end $5FE684 }

{ @routine $5FE6A4 TEFilm_SetObjectText }
procedure TEFilm.SetObjectText(StepIndex: Integer; Obj: TEFilmObj; const Text: WideString);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectText;
  TEFilmObjectCommand(Command^).Obj := Obj;
  StringTable.Add(Text);
  TEFilmObjectCommand(Command^).Value := StringTable.GetCount - 1;
end;
{ @end $5FE6A4 }

{ @routine $5FE6DC TEFilm_SetObjectStateBuffer }
procedure TEFilm.SetObjectStateBuffer(StepIndex: Integer; Obj: TEFilmObj; Buffer: TBufEC);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcSetObjectStateBuffer;
  TEFilmObjectCommand(Command^).Obj := Obj;
  DataBuffers.Add(Buffer);
  TEFilmObjectCommand(Command^).Value := DataBuffers.Count - 1;
end;
{ @end $5FE6DC }

{ @routine $5FE714 TEFilm_BeginTrailingEffects }
procedure TEFilm.BeginTrailingEffects(StepIndex: Integer);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcBeginTrailingEffects;
end;
{ @end $5FE714 }

{ @routine $5FE720 TEFilm_PlayPickupSound }
procedure TEFilm.PlayPickupSound(StepIndex: Integer; Obj: TEFilmObj);
var Command: PEFilmCommand;
begin
  Command := AddCommand(StepIndex);
  Command.Kind := efcPlayPickupSound;
  TEFilmObjectCommand(Command^).Obj := Obj;
end;
{ @end $5FE720 }

{ @routine $5FE734 TEFilm_ExecuteCommand }
procedure TEFilm.ExecuteCommand(Process: TProcessSE; Command: PEFilmCommand; ReplayMode: Boolean);
var Obj: TEFilmObj; Source, Target: TObjectSE;
begin
  // Uses the global SpaceProcess, and most commands require a live object.
  case Command.Kind of
    efcSetObjectPosition:
      TEFilmObjectCommand(Command^).Obj.SceneObject.SetPosition(TEFilmVectorCommand(Command^).Position);
    efcSetObjectOrbitCenter:
      TEFilmObjectCommand(Command^).Obj.SceneObject.SetOrbitCenter(TEFilmVectorCommand(Command^).Position);
    efcSetObjectAlpha:
      TEFilmObjectCommand(Command^).Obj.SceneObject.SetAlpha(TEFilmByteCommand(Command^).Value);
    efcSetObjectAngle:
      TEFilmObjectCommand(Command^).Obj.SceneObject.SetAngle(TEFilmByteCommand(Command^).Value);
    efcAdvanceObject:
      TEFilmObjectCommand(Command^).Obj.SceneObject.Advance;
    efcAdvanceObjects:
      begin
        Obj := Self.FirstObject;
        while Obj <> nil do
        begin
          if Obj.SceneObject <> nil then Obj.SceneObject.Advance;
          Obj := Obj.Next;
        end;
      end;
    efcSetPlanetState:
      begin
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).SetRotationTimerInterval(TEFilmObjectCommand(Command^).Value and $FFFFFF);
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).SetRingKind(TEFilmObjectCommand(Command^).Value shr 24);
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).SetSurfaceMapStep(TEFilmObjectCommand(Command^).ExtraValue);
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).OrbitalVelocity := SmallInt(TEFilmObjectCommand(Command^).Flags and $FFFF) / 1000;
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).SetMinimapOwner(TOwnerId(TEFilmObjectCommand(Command^).Flags shr 24));
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).Civilized := (TEFilmObjectCommand(Command^).Obj.SceneObject as TPlanetSE).MinimapOwner <> oiNone;
      end;
    efcSetShipSize:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TShip2SE).SetSize(TEFilmSizeCommand(Command^).Size);
    efcSetWeaponHit:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TWeaponSE).SetHit(TEFilmHitCommand(Command^).Color, TEFilmHitCommand(Command^).Damage, TEFilmHitCommand(Command^).Destroyed, TEFilmHitCommand(Command^).PlaySound);
    efcSetWeaponEndpoints:
      begin
        Source := nil;
        if TEFilmEndpointsCommand(Command^).Source <> nil then Source := TEFilmEndpointsCommand(Command^).Source.SceneObject;
        Target := nil;
        if TEFilmEndpointsCommand(Command^).Target <> nil then Target := TEFilmEndpointsCommand(Command^).Target.SceneObject;
        (TEFilmObjectCommand(Command^).Obj.SceneObject as TWeaponSE).SetEndpoints(Source, Target);
      end;
    efcSetDestructionEffect:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TWeaponSE).DestructionEffect := TEFilmObjectCommand(Command^).Value;
    efcAttachObject:
      begin
        if TEFilmObjectCommand(Command^).Obj.SceneObject is TShip2SE then
          TShip2SE(TEFilmObjectCommand(Command^).Obj.SceneObject).SetTailsActive((ShipTail = 2) or
            ((ShipTail = 1) and (Player <> nil) and (TEFilmObjectCommand(Command^).Obj.ObjectId = Player.Id)));
        TEFilmObjectCommand(Command^).Obj.SceneObject.AttachToSpace(SpaceProcess.Space);
      end;
    efcDetachObject:
      TEFilmObjectCommand(Command^).Obj.SceneObject.DetachFromSpace;
    efcReleaseObject:
      if TEFilmObjectCommand(Command^).Obj.SceneObject <> nil then
      begin
        TEFilmObjectCommand(Command^).Obj.SceneObject.DetachFromSpace;
        TEFilmObjectCommand(Command^).Obj.SceneObject.Free;
        TEFilmObjectCommand(Command^).Obj.SceneObject := nil;
      end;
    efcReleaseWeaponEffects:
      begin
        Obj := Self.FirstObject;
        while Obj <> nil do
        begin
          if (Obj.SceneObject <> nil) and (Obj.SceneObject is TWeaponSE) then
          begin
            TWeaponSE(Obj.SceneObject).DetachFromSpace;
            Obj.SceneObject.Free;
            Obj.SceneObject := nil;
          end;
          Obj := Obj.Next;
        end;
      end;
    efcSetViewCenter:
      if ReplayMode then FilmScreen.FollowViewOffset(TruncatePointF(TEFilmVectorCommand(Command^).Position))
      else StarMapScreen.SetMapCenter(TruncatePointF(TEFilmVectorCommand(Command^).Position));
    efcSetRadarCenter:
      begin
        if ReplayMode then FilmScreen.CameraTarget := TEFilmVectorCommand(Command^).Position;
        SpaceProcess.RadarCenter := TEFilmVectorCommand(Command^).Position;
      end;
    efcSetCameraAnchor:
      begin
        CameraAnchor := TEFilmVectorCommand(Command^).Position;
        ForceCameraMovement := TEFilmVectorCommand(Command^).ForceMovement;
      end;
    efcOpenGate:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TGateSE).Open;
    efcCloseGate:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TGateSE).Close;
    efcSetGateState:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as TGateSE).SetState(TEFilmObjectCommand(Command^).Value);
    efcSetHoleState:
      (TEFilmObjectCommand(Command^).Obj.SceneObject as THoleSE).SetState(TEFilmObjectCommand(Command^).Value);
    efcSetObjectText:
      TEFilmObjectCommand(Command^).Obj.SceneObject.SetText(StringTable.GetTextAt(TEFilmObjectCommand(Command^).Value));
    efcSetObjectStateBuffer:
      TEFilmObjectCommand(Command^).Obj.SceneObject.LoadStateBuffer(TBufEC(DataBuffers[TEFilmObjectCommand(Command^).Value]));
    efcPlayPickupSound:
      if (TEFilmObjectCommand(Command^).Obj <> nil) and (TEFilmObjectCommand(Command^).Obj.SceneObject <> nil) and
        SoundInSpaceEnabled and SpaceProcess.Space.ContainsMapPoint(TEFilmObjectCommand(Command^).Obj.SceneObject.Position) then
        SoundManager.PlaySound('Sound.Take');
  end;
end;
{ @end $5FE734 }

{ @routine $5FEC6C TEFilm_SaveToBuffer }
procedure TEFilm.SaveToBuffer(Buffer: TBufEC);
var
  Obj: TEFilmObj;
  Command: PEFilmCommand;
  I, Count: Integer;
  Data: TBufEC;
  ObjectIndex: Integer;
begin
  Buffer.Clear;
  Buffer.AddWideStringZ(SystemProcessName);
  Buffer.AddIntegerValue(MaxInt);
  Buffer.AddIntegerValue(1);
  Buffer.AddIntegerValue(MapDiameter);
  Buffer.AddIntegerValue(RadarRange);
  Buffer.AddBoolean(PlayerCombatRecorded);
  Buffer.AddDWord(StarGenerationSeed);
  Buffer.AddDWord(InitialActivity);
  Buffer.AddDWord(FinalActivity);
  Buffer.AddSingle(CameraAnchor.X);
  Buffer.AddSingle(CameraAnchor.Y);
  Count := StringTable.GetCount;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do Buffer.AddWideStringZ(StringTable.GetTextAt(I));
  Count := DataBuffers.Count;
  Buffer.AddWideChar(WideChar(Count));
  for I := 0 to Count - 1 do
  begin
    Data := TBufEC(DataBuffers[I]);
    Buffer.AddBuffer(Data);
  end;
  Buffer.AddWideChar(WideChar(ObjectCount));
  Obj := FirstObject;
  while Obj <> nil do
  begin
    Buffer.AddDWord(Obj.ObjectId);
    Buffer.AddWideStringZ(Obj.KindName);
    Buffer.AddWideStringZ(Obj.GraphKey);
    Obj := Obj.Next;
  end;
  Buffer.AddDWord(CommandCount);
  Command := FirstCommand;
  while Command <> nil do
  begin
    Buffer.AddAnsiChar(AnsiChar(ReadByteValue(Command.Kind)));
    Buffer.AddWideChar(WideChar(Command.StepIndex));
    if Command.Kind = efcSetObjectPosition then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetObjectOrbitCenter then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetObjectAlpha then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmByteCommand(Command).Value));
    end
    else if Command.Kind = efcSetObjectAngle then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmByteCommand(Command).Value));
    end
    else if Command.Kind = efcAdvanceObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcAdvanceObjects then
    begin
    end
    else if Command.Kind = efcSetPlanetState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).ExtraValue);
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Flags);
    end
    else if Command.Kind = efcSetShipSize then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddWideChar(WideChar(PEFilmSizeCommand(Command).Size.X));
      Buffer.AddWideChar(WideChar(PEFilmSizeCommand(Command).Size.Y));
    end
    else if Command.Kind = efcSetWeaponHit then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackRed(PEFilmHitCommand(Command).Color)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackGreen(PEFilmHitCommand(Command).Color)));
      Buffer.AddAnsiChar(AnsiChar(CurrentPixelFormat.UnpackBlue(PEFilmHitCommand(Command).Color)));
      Buffer.AddIntegerValue(PEFilmHitCommand(Command).Damage);
      Buffer.AddBoolean(PEFilmHitCommand(Command).Destroyed);
      Buffer.AddBoolean(PEFilmHitCommand(Command).PlaySound);
    end
    else if Command.Kind = efcSetWeaponEndpoints then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      ObjectIndex := FindObjectIndex(PEFilmEndpointsCommand(Command).Source);
      if ObjectIndex = -1 then
      begin
        ObjectIndex := FilmNullObjectIndex;
        PEFilmEndpointsCommand(Command).Source := nil;
      end;
      Buffer.AddWideChar(WideChar(ObjectIndex));
      ObjectIndex := FindObjectIndex(PEFilmEndpointsCommand(Command).Target);
      if ObjectIndex = -1 then
      begin
        ObjectIndex := FilmNullObjectIndex;
        PEFilmEndpointsCommand(Command).Target := nil;
      end;
      Buffer.AddWideChar(WideChar(ObjectIndex));
    end
    else if Command.Kind = efcSetDestructionEffect then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddAnsiChar(AnsiChar(PEFilmObjectCommand(Command).Value));
    end
    else if Command.Kind = efcAttachObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcDetachObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcReleaseObject then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcReleaseWeaponEffects then
    begin
    end
    else if Command.Kind = efcSetViewCenter then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetRadarCenter then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
    end
    else if Command.Kind = efcSetCameraAnchor then
    begin
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.X);
      Buffer.AddSingle(PEFilmVectorCommand(Command).Position.Y);
      Buffer.AddBoolean(PEFilmVectorCommand(Command).ForceMovement);
    end
    else if Command.Kind = efcOpenGate then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcCloseGate then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end
    else if Command.Kind = efcSetGateState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetHoleState then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddBoolean(Boolean(PEFilmObjectCommand(Command).Value));
    end
    else if Command.Kind = efcSetObjectText then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcSetObjectStateBuffer then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
      Buffer.AddIntegerValue(PEFilmObjectCommand(Command).Value);
    end
    else if Command.Kind = efcBeginTrailingEffects then
    begin
    end
    else if Command.Kind = efcPlayPickupSound then
    begin
      Buffer.AddWideChar(WideChar(ObjToNom(PEFilmObjectCommand(Command).Obj)));
    end;
    Command := Command.Next;
  end;
  Buffer.AddIntegerValue(CameraEventCount);
  for I := 0 to CameraEventCount - 1 do
    with CameraEvents[I] do
    begin
      Buffer.AddIntegerValue(StepIndex);
      Buffer.AddIntegerValue(Priority);
      Buffer.AddSingle(StartPosition.X);
      Buffer.AddSingle(StartPosition.Y);
      Buffer.AddSingle(EndPosition.X);
      Buffer.AddSingle(EndPosition.Y);
    end;
  (ObjectInfo as TEObjInfo).SaveToBuffer(Buffer);
end;
{ @end $5FEC6C }

{ @routine $5FF29C TEFilm_LoadFromBuffer }
procedure TEFilm.LoadFromBuffer(Buffer: TBufEC);
var
  I, Count: Integer;
  Obj: TEFilmObj;
  Command: PEFilmCommand;
  Red, Green, Blue: Byte;
  Data: TBufEC;
  Version: Integer;
begin
  Version := 0;
  Clear;
  Buffer.SetPosition(0);
  SystemProcessName := Buffer.ReadWideString;
  MapDiameter := Buffer.GetInt32;
  if MapDiameter = MaxInt then
  begin
    Version := Buffer.GetInt32;
    MapDiameter := Buffer.GetInt32;
  end;
  RadarRange := Buffer.GetInt32;
  PlayerCombatRecorded := Buffer.GetBoolean;
  StarGenerationSeed := Buffer.GetUInt32;
  InitialActivity := Buffer.GetUInt32;
  FinalActivity := Buffer.GetUInt32;
  CameraAnchor.X := Buffer.GetSingle;
  CameraAnchor.Y := Buffer.GetSingle;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do StringTable.Add(Buffer.ReadWideString);
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Data := TBufEC.Create;
    Buffer.ReadLengthPrefixedBuffer(Data);
    DataBuffers.Add(Data);
  end;
  Count := Buffer.GetWord;
  for I := 0 to Count - 1 do
  begin
    Obj := AllocateObject;
    Obj.ObjectId := Buffer.GetUInt32;
    Obj.KindName := Buffer.ReadWideString;
    Obj.GraphKey := Buffer.ReadWideString;
    Obj.SceneObject := nil;
  end;
  Count := Buffer.GetUInt32;
  for I := 0 to Count - 1 do
  begin
    Command := AllocateCommand;
    AppendCommand(Command);
    WriteByteValue(Buffer.GetByte, Command.Kind);
    Command.StepIndex := Buffer.GetWord;
    if Command.Kind = efcSetObjectPosition then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetObjectOrbitCenter then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetObjectAlpha then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmByteCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcSetObjectAngle then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmByteCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcAdvanceObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcAdvanceObjects then
    begin
    end
    else if Command.Kind = efcSetPlanetState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
      PEFilmObjectCommand(Command).ExtraValue := Buffer.GetInt32;
      PEFilmObjectCommand(Command).Flags := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetShipSize then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmSizeCommand(Command).Size.X := Buffer.GetWord;
      PEFilmSizeCommand(Command).Size.Y := Buffer.GetWord;
    end
    else if Command.Kind = efcSetWeaponHit then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      Red := Buffer.GetByte;
      Green := Buffer.GetByte;
      Blue := Buffer.GetByte;
      PEFilmHitCommand(Command).Color := CurrentPixelFormat.PackRgbBytes(Red, Green, Blue);
      PEFilmHitCommand(Command).Damage := Buffer.GetInt32;
      PEFilmHitCommand(Command).Destroyed := Buffer.GetBoolean;
      PEFilmHitCommand(Command).PlaySound := Buffer.GetBoolean;
    end
    else if Command.Kind = efcSetWeaponEndpoints then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmEndpointsCommand(Command).Source := NomToObj(Buffer.GetWord);
      PEFilmEndpointsCommand(Command).Target := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcSetDestructionEffect then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetByte;
    end
    else if Command.Kind = efcAttachObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcDetachObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcReleaseObject then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcReleaseWeaponEffects then
    begin
    end
    else if Command.Kind = efcSetViewCenter then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetRadarCenter then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
    end
    else if Command.Kind = efcSetCameraAnchor then
    begin
      PEFilmVectorCommand(Command).Position.X := Buffer.GetSingle;
      PEFilmVectorCommand(Command).Position.Y := Buffer.GetSingle;
      PEFilmVectorCommand(Command).ForceMovement := Buffer.GetBoolean;
    end
    else if Command.Kind = efcOpenGate then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcCloseGate then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end
    else if Command.Kind = efcSetGateState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetHoleState then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Ord(Buffer.GetBoolean);
    end
    else if Command.Kind = efcSetObjectText then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcSetObjectStateBuffer then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
      PEFilmObjectCommand(Command).Value := Buffer.GetInt32;
    end
    else if Command.Kind = efcBeginTrailingEffects then
    begin
    end
    else if Command.Kind = efcPlayPickupSound then
    begin
      PEFilmObjectCommand(Command).Obj := NomToObj(Buffer.GetWord);
    end;
  end;
  Count := Buffer.GetInt32;
  for I := 0 to Count - 1 do
  begin
    ReserveCameraEventSlot;
    with CameraEvents[CameraEventCount - 1] do
    begin
      StepIndex := Buffer.GetInt32;
      Priority := Buffer.GetInt32;
      StartPosition.X := Buffer.GetSingle;
      StartPosition.Y := Buffer.GetSingle;
      EndPosition.X := Buffer.GetSingle;
      EndPosition.Y := Buffer.GetSingle;
    end;
  end;
  if Version > 0 then (ObjectInfo as TEObjInfo).LoadFromBuffer(Buffer)
  else (ObjectInfo as TEObjInfo).Clear;
end;
{ @end $5FF29C }

end.

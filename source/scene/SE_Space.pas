unit SE_Space;
// Unit bracket (inferred): CODE 0x00613D9C..0x0061558B; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Buf, EC_Struct, GI_Circle, GI_GI, GI_MessageLoop, GI_Panel,
  GR_Sound, SE_SoundRnd, GI_Frame, GI_StarField, GI_StarFieldM, GI_StarFieldImg, GI_SpaceImg, Types;

type
  TSpaceSE = class;
  TSpaceScrollEventSE = procedure of object;

  TObjectSE = class(TObjectEx) // @size $48 @methodorder source
  public
    Prev: TObjectSE; // @offset $04
    Next: TObjectSE; // @offset $08
    ProcessPrev: TObjectSE; // @offset $0C
    ProcessNext: TObjectSE; // @offset $10
    Space: TSpaceSE; // @offset $14
    GraphKey: WideString; // @offset $18
    Size: TPoint; // @offset $1C
    Position: TPointF; // @offset $24
    DepthExpression: WideString; // @offset $2C
    SoundLoopPath: WideString; // @offset $30
    SoundGroup: Integer; // @offset $34
    LoopSound: TSoundBufferControl; // @offset $38
    RandomSound: TSoundRndSE; // @offset $3C
    RandomSoundGroup: Integer; // @offset $40
    NextSoundTime: Cardinal; // @offset $44

    constructor CreateEmpty; // @addr $613EC8
    constructor Create(const AGraphKey: WideString; UnusedPosition: TPoint); // @addr $613F00 @note "UnusedPosition is copied but does not initialize Position."
    destructor Destroy; override; // @addr $613FBC
    procedure CopyTo(Destination: TObjectSE); virtual; // @addr $614058 @slot $00 @note "Copies graph key, size, position and depth expression only."
    property ObjPrev: TObjectSE read Prev write Prev;
    property ObjNext: TObjectSE read Next write Next;
    property PObjPrev: TObjectSE read ProcessPrev write ProcessPrev;
    property PObjNext: TObjectSE read ProcessNext write ProcessNext;
    property SpaceOwner: TSpaceSE read Space;
    procedure AttachToSpace(ASpace: TSpaceSE); virtual; // @addr $614090 @slot $04
    procedure DetachFromSpace; virtual; // @addr $6140D0 @slot $08
    function IsAttachedToSpace: Boolean; // @addr $614100
    property TypeO: WideString read GraphKey;
    procedure SetPosition(APosition: TPointF); virtual; // @addr $61410C @slot $0C
    property Pos: TPointF read Position write SetPosition;
    procedure SetDepth(Value: Single); virtual; // @addr $61412C @slot $10
    function GetDepth: Single; virtual; // @addr $614134 @slot $14
    property DepthValue: Single read GetDepth write SetDepth;
    procedure SetOrbitCenter(Center: TPointF); virtual; // @addr $614140 @slot $18
    function GetOrbitCenter: TPointF; virtual; // @addr $614144 @slot $1C @note "Subclasses interpret this point differently: Sputnik returns the orbit center, Ship2 returns scaled dimensions."
    property OrbitCenter: TPointF read GetOrbitCenter write SetOrbitCenter;
    function GetAlpha: Byte; virtual; // @addr $614154 @slot $20
    procedure SetAlpha(Value: Byte); virtual; // @addr $614158 @slot $24
    property Alpha: Byte read GetAlpha write SetAlpha;
    function GetAngle: Byte; virtual; // @addr $61415C @slot $28 @note "Base returns zero; TGateSE returns its stored angle."
    procedure SetAngle(Value: Byte); virtual; // @addr $614160 @slot $2C
    property Angle: Byte read GetAngle write SetAngle;
    function GetText: WideString; virtual; // @addr $614164 @slot $30 @note "Base returns empty; TGateSE overrides it with the label text."
    procedure SetText(const Value: WideString); virtual; // @addr $614170 @slot $34
    property Text: WideString read GetText write SetText;
    function BuildStateBuffer: TBufEC; virtual; // @addr $614174 @slot $38
    procedure LoadStateBuffer(Buffer: TBufEC); virtual; // @addr $614178 @slot $3C
    procedure Advance; virtual; // @addr $61417C @slot $40
    procedure SetSize(Value: TPoint); virtual; // @addr $6142CC @slot $44
    property ObjectSize: TPoint read Size write SetSize;
    function HitTestCursor: Boolean; virtual; // @addr $6142EC @slot $48
    procedure DrawMap; virtual; // @addr $6142F0 @slot $4C
    procedure ConfigureLoopSound(const Name: WideString); // @addr $6142F4
    property LoopSoundName: WideString write ConfigureLoopSound;
    procedure ConfigureRandomSound(const Name: WideString); // @addr $614474
    property RandomSoundName: WideString write ConfigureRandomSound;
    procedure LoadTemplate(Block: TBlockParEC); virtual; // @addr $6144C0 @slot $50
    procedure ApplyConfig(Block: TBlockParEC); virtual; // @addr $6145C8 @slot $54
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); virtual; // @addr $6146A4 @slot $58
  end;

  PSpaceTimerSE = ^TSpaceTimerSE;
  TSpaceTimerEventSE = procedure(Timer: PSpaceTimerSE; UserData: Integer) of object;
  TSpaceTimerSE = packed record // @size $20
    Prev: PSpaceTimerSE; // @offset $00
    Next: PSpaceTimerSE; // @offset $04
    TicksRemaining: Integer; // @offset $08
    RepeatTicks: Integer; // @offset $0C
    Callback: TSpaceTimerEventSE; // @offset $10
    UserData: Integer; // @offset $18
  end;

  TSpaceSE = class(TObject) // @size $68
  public
    FirstObject: TObjectSE; // @offset $04
    LastObject: TObjectSE; // @offset $08
    FirstTimer: PSpaceTimerSE; // @offset $0C
    LastTimer: PSpaceTimerSE; // @offset $10
    NextTimerToProcess: PSpaceTimerSE; // @offset $14
    MinimapScale: Double; // @offset $18
    MapPanel: TPanelGI; // @offset $20
    MinimapControl: TObjectGI; // @offset $24
    MinimapViewportFrame: TFrameGI; // @offset $28
    Screen: TMessageLoopGI; // @offset $2C
    MinimapBackground: TgiGI; // @offset $30
    MinimapRangeShade: TCircleGI; // @offset $34
    MinimapRangeCircle: TCircleGI; // @offset $38
    StarField: TStarFieldGI; // @offset $3C
    StarFieldM: TStarFieldMGI; // @offset $40
    SpaceImages: TSpaceImgGI; // @offset $44
    StarFieldImages: TStarFieldImgGI; // @offset $48
    MinimapDragging: Boolean; // @offset $4C
    Process: TObject; // @offset $50 Native consumers cast this generic owner to TProcessSE.
    ScrollChangedCallback: TSpaceScrollEventSE; // @offset $58
    PathPoints: PPointF; // @offset $60  Owned copy, not a Delphi dynamic array.
    PathPointCount: Integer; // @offset $64

    constructor Create(AMapPanel: TPanelGI; AScreen: TMessageLoopGI); // @addr $6146A8
    destructor Destroy; override; // @addr $6149E0 @note "Requires all timers to have been removed."
    procedure LinkObject(Obj: TObjectSE); // @addr $614A88 @note "Only changes list links; does not retain Obj or set Obj.Space."
    procedure UnlinkObject(Obj: TObjectSE); // @addr $614AAC @note "Does not release Obj or clear its links."
    procedure DeleteTimer(Timer: PSpaceTimerSE); // @addr $614B64 @note "Raises if Timer is NextTimerToProcess."
    function CreateTimer(DelayMs, RepeatMs: Integer; Callback: TSpaceTimerEventSE; UserData: Integer): PSpaceTimerSE; // @addr $614AE0 @note "Converts milliseconds to ticks by rounding division by 18. Callback receives Context, Timer, UserData in Delphi registers. Zero delay still waits for AdvanceTimers."
    procedure AdvanceTimers; // @addr $614BC8
    procedure AdvanceObjects; // @addr $614C08
    procedure ClearPath; // @addr $614C20
    procedure SetPath(Points: PPointF; Count: Integer); // @addr $614C3C @note "Copies Count points. A nonpositive count clears the path."
    procedure CreateMinimapViewport; // @addr $6150EC
    procedure FreeMinimapViewport; // @addr $6151C4
    procedure MinimapMouseEnter(Sender: TObjectGI); // @addr $615410
    procedure MinimapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $6152F4
    procedure MinimapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $615418
    procedure DrawMinimap; // @addr $614C7C
    function ContainsMapPoint(Point: TPointF): Boolean; // @addr $615508
    procedure MapScrollChanged(Sender: TObjectGI); // @addr $6151DC
  end;

implementation

// @unit-initialization $615584
// @unit-finalization $615554

uses SE_Weapon, fStarMap, fFilm, GI_GraphButton, Windows, Windows, SysUtils, MMSystem, EC_Str, GR_Main, Globals, GlobalsV, aMyFunction, SE_Process, SE_Anim, SE_BGObj, SE_StarsField, SE_Container, SE_Asteroid, SE_Star, SE_Hole, SE_Ruins, SE_Meteorite, SE_Laser, EC_Mem, GI_Main, GR_GraphBuf, SE_Planet;

{ @routine $613EC8 TObjectSE_CreateEmpty }
constructor TObjectSE.CreateEmpty;
begin
  inherited Create;
end;
{ @end $613EC8 }

{ @routine $613F00 TObjectSE_Create }
constructor TObjectSE.Create(const AGraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create;
  GraphKey := AGraphKey;
  // Uses the complete key, including any comma-delimited suffix.
  LoadTemplate(GameDataConfig.GetBlockByPath('SE.' + AGraphKey));
end;
{ @end $613F00 }

{ @routine $613FBC TObjectSE_Destroy }
destructor TObjectSE.Destroy;
var
  Obj: TObjectSE;
begin
  DetachFromSpace;
  if (GetCurrentThreadId = MainRuntimeThreadId) and
    (SpaceProcess <> nil) and (SpaceProcess.Space <> nil) then
  begin
    Obj := SpaceProcess.Space.FirstObject;
    while Obj <> nil do
    begin
      if Obj is TWeaponSE then
        if Obj.IsAttachedToSpace then
          if (TWeaponSE(Obj).SourceObject = Self) or
            (TWeaponSE(Obj).TargetObject = Self) then Obj.DetachFromSpace;
      Obj := Obj.Next;
    end;
  end;
  inherited Destroy;
end;
{ @end $613FBC }

{ @routine $614058 TObjectSE_CopyTo }
procedure TObjectSE.CopyTo(Destination: TObjectSE);
begin
  Destination.GraphKey := GraphKey;
  Destination.Size := Size;
  Destination.Position := Position;
  Destination.DepthExpression := DepthExpression;
end;
{ @end $614058 }

{ @routine $614090 TObjectSE_AttachToSpace }
procedure TObjectSE.AttachToSpace(ASpace: TSpaceSE);
begin
  ASpace.LinkObject(Self);
  Space := ASpace;
  if SoundLoopPath <> '' then
  begin
    LoopSound := TSoundBufferControl.Create;
    LoopSound.Configure(SoundLoopPath, SoundGroup);
  end;
end;
{ @end $614090 }

{ @routine $6140D0 TObjectSE_DetachFromSpace }
procedure TObjectSE.DetachFromSpace;
begin
  if LoopSound <> nil then
  begin
    LoopSound.Free;
    LoopSound := nil;
  end;
  if IsAttachedToSpace then
  begin
    Space.UnlinkObject(Self);
    Space := nil;
  end;
end;
{ @end $6140D0 }

{ @routine $614100 TObjectSE_IsAttachedToSpace }
function TObjectSE.IsAttachedToSpace: Boolean;
begin
  if Space = nil then Result := False else Result := True;
end;
{ @end $614100 }

{ @routine $61410C TObjectSE_SetPosition }
procedure TObjectSE.SetPosition(APosition: TPointF);
begin
  Position := APosition;
end;
{ @end $61410C }

{ @routine $61412C TObjectSE_SetDepth }
procedure TObjectSE.SetDepth(Value: Single);
begin

end;
{ @end $61412C }

{ @routine $614134 TObjectSE_GetDepth }
function TObjectSE.GetDepth: Single;
begin
  Result := 0;
end;
{ @end $614134 }

{ @routine $614140 TObjectSE_SetOrbitCenter }
procedure TObjectSE.SetOrbitCenter(Center: TPointF);
begin

end;
{ @end $614140 }

{ @routine $614144 TObjectSE_GetOrbitCenter }
function TObjectSE.GetOrbitCenter: TPointF;
begin
  Result := MakePointF(0, 0);
end;
{ @end $614144 }

{ @routine $614154 TObjectSE_GetAlpha }
function TObjectSE.GetAlpha: Byte;
begin
  Result := 0;
end;
{ @end $614154 }

{ @routine $614158 TObjectSE_SetAlpha }
procedure TObjectSE.SetAlpha(Value: Byte);
begin

end;
{ @end $614158 }

{ @routine $61415C TObjectSE_GetAngle }
function TObjectSE.GetAngle: Byte;
begin
  Result := 0;
end;
{ @end $61415C }

{ @routine $614160 TObjectSE_SetAngle }
procedure TObjectSE.SetAngle(Value: Byte);
begin

end;
{ @end $614160 }

{ @routine $614164 TObjectSE_GetText }
function TObjectSE.GetText: WideString;
begin
  Result := '';
end;
{ @end $614164 }

{ @routine $614170 TObjectSE_SetText }
procedure TObjectSE.SetText(const Value: WideString);
begin

end;
{ @end $614170 }

{ @routine $614174 TObjectSE_BuildStateBuffer }
function TObjectSE.BuildStateBuffer: TBufEC;
begin
  Result := nil;
end;
{ @end $614174 }

{ @routine $614178 TObjectSE_LoadStateBuffer }
procedure TObjectSE.LoadStateBuffer(Buffer: TBufEC);
begin

end;
{ @end $614178 }

{ @routine $61417C TObjectSE_Advance }
procedure TObjectSE.Advance;
var
  Distance: Single;
  Now: Cardinal;
begin
  if IsAttachedToSpace then
  begin
    if LoopSound <> nil then
    begin
      Distance := PointDistance(Position, SpaceViewPosition) / (Cardinal(GameScreenHeight) / 2);
      if Distance > 1 then LoopSound.SetVolume(0)
      else LoopSound.SetVolume((1 - Distance) * 0.5 + 0.5);
    end;
    if RandomSound <> nil then
      if RandomSoundGroup >= 0 then
      begin
        Now := timeGetTime;
        if Now > NextSoundTime then
        begin
          NextSoundTime := RandomIntRange(RandomSound.Groups[RandomSoundGroup].NextTimeMin,
            RandomSound.Groups[RandomSoundGroup].NextTimeMax) + Integer(Now);
          if Space.ContainsMapPoint(Position) then
            SoundManager.PlayEffect(RandomSound.SelectSound(RandomSoundGroup),
              RandomSound.Groups[RandomSoundGroup].Group);
        end;
      end;
  end;
end;
{ @end $61417C }

{ @routine $6142CC TObjectSE_SetSize }
procedure TObjectSE.SetSize(Value: TPoint);
begin
  Size := Value;
end;
{ @end $6142CC }

{ @routine $6142EC TObjectSE_HitTestCursor }
function TObjectSE.HitTestCursor: Boolean;
begin
  Result := False;
end;
{ @end $6142EC }

{ @routine $6142F0 TObjectSE_DrawMap }
procedure TObjectSE.DrawMap;
begin

end;
{ @end $6142F0 }

{ @routine $6142F4 TObjectSE_ConfigureLoopSound }
procedure TObjectSE.ConfigureLoopSound(const Name: WideString);
var
  Block: TBlockParEC;
  Count, Index, Weight: Integer;
begin
  Block := GameDataConfig.GetBlockByPath('SE.Sound.Loop.' + Name);
  Weight := 0;
  Count := Block.GetParamCount;
  if Count >= 1 then
  begin
    for Index := 0 to Count - 1 do Inc(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
    Weight := RandomIntRange(0, Weight - 1);
    for Index := 0 to Count - 1 do
    begin
      Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
      if Weight < 0 then
      begin
        SoundLoopPath := Block.GetParamValue(Index);
        SoundGroup := ExtractDigitsToIntW(ExtractDelimitedPartW(SoundLoopPath, 0, ','));
        SoundLoopPath := ExtractDelimitedPartW(SoundLoopPath, 1, ',');
        Exit;
      end;
    end;
  end;
  SoundLoopPath := '';
  SoundGroup := 0;
end;
{ @end $6142F4 }

{ @routine $614474 TObjectSE_ConfigureRandomSound }
procedure TObjectSE.ConfigureRandomSound(const Name: WideString);
begin
  RandomSound := FindRandomSound(Name, RandomSoundGroup);
  if RandomSoundGroup >= 0 then
    NextSoundTime := timeGetTime + RandomIntRange(RandomSound.Groups[RandomSoundGroup].NextTimeMin,
      RandomSound.Groups[RandomSoundGroup].NextTimeMax);
end;
{ @end $614474 }

{ @routine $6144C0 TObjectSE_LoadTemplate }
procedure TObjectSE.LoadTemplate(Block: TBlockParEC);
begin
  if Block.CountParams('PosZ') > 0 then DepthExpression := Block.GetParam('PosZ');
  if Block.CountParams('SoundLoop') > 0 then SoundLoopPath := Block.GetParam('SoundLoop');
  if Block.CountParams('SoundGroup') > 0 then SoundGroup := ExtractDigitsToIntW(Block.GetParam('SoundGroup'));
end;
{ @end $6144C0 }

{ @routine $6145C8 TObjectSE_ApplyConfig }
procedure TObjectSE.ApplyConfig(Block: TBlockParEC);
var
  Text: WideString;
begin
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    SetPosition(MakePointF(ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 0, ',')),
      ExtractDecimalToSingleW(ExtractDelimitedPartW(Text, 1, ','))));
  end;
end;
{ @end $6145C8 }

{ @routine $6146A4 TObjectSE_QueueImageLoad }
procedure TObjectSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin

end;
{ @end $6146A4 }

{ @routine $6146A8 TSpaceSE_Create }
constructor TSpaceSE.Create(AMapPanel: TPanelGI; AScreen: TMessageLoopGI);
begin
  inherited Create;
  MapPanel := AMapPanel;
  Screen := AScreen;
  MinimapScale := 0.125;
  MinimapViewportFrame := nil;
  MinimapRangeShade := TCircleGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapRangeShade do
  begin
    SetKind(ckShrLight);
    SetPosition(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetOrigin(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
    SetShrLightInner(0);
    SetShrLightOuter(1);
  end;
  MinimapRangeCircle := TCircleGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapRangeCircle do
  begin
    SetKind(ckCircle);
    SetPosition(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetOrigin(Classes.Point(RenderScratchBuffer.Width shr 1, RenderScratchBuffer.Height shr 1));
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  MinimapBackground := TgiGI.Create(SpaceObjectUiLoop.ContentPanel);
  with MinimapBackground do
  begin
    SetImagePath('Bm.PanelSpace.' + GiResourceSuffix + 'RadarT');
    SetSize(Classes.Point(RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  StarField := TStarFieldGI(Screen.FindControlByPath('StarField'));
  StarFieldM := TStarFieldMGI(Screen.FindControlByPath('StarFieldM'));
  SpaceImages := TSpaceImgGI(Screen.FindControlByPath('SpaceImg'));
  StarFieldImages := TStarFieldImgGI(Screen.FindControlByPath('StarFieldImg'));
end;
{ @end $6146A8 }

{ @routine $6149E0 TSpaceSE_Destroy }
destructor TSpaceSE.Destroy;
begin
  ClearPath;
  MinimapRangeShade.Free;
  MinimapRangeShade := nil;
  MinimapRangeCircle.Free;
  MinimapRangeCircle := nil;
  MinimapBackground.Free;
  MinimapBackground := nil;
  StarField := nil;
  StarFieldM := nil;
  SpaceImages := nil;
  StarFieldImages := nil;
  while FirstObject <> nil do LastObject.DetachFromSpace;
  MapPanel := nil;
  if FirstTimer <> nil then raise Exception.Create('Error');
  inherited Destroy;
end;
{ @end $6149E0 }

{ @routine $614A88 TSpaceSE_LinkObject }
procedure TSpaceSE.LinkObject(Obj: TObjectSE);
begin
  if LastObject <> nil then LastObject.Next := Obj;
  Obj.Prev := LastObject;
  Obj.Next := nil;
  LastObject := Obj;
  if FirstObject = nil then FirstObject := Obj;
end;
{ @end $614A88 }

{ @routine $614AAC TSpaceSE_UnlinkObject }
procedure TSpaceSE.UnlinkObject(Obj: TObjectSE);
begin
  if Obj.Prev <> nil then Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then Obj.Next.Prev := Obj.Prev;
  if LastObject = Obj then LastObject := Obj.Prev;
  if FirstObject = Obj then FirstObject := Obj.Next;
end;
{ @end $614AAC }

{ @routine $614AE0 TSpaceSE_CreateTimer }
function TSpaceSE.CreateTimer(DelayMs, RepeatMs: Integer; Callback: TSpaceTimerEventSE; UserData: Integer): PSpaceTimerSE;
var
  Timer: PSpaceTimerSE;
begin
  Timer := AllocEC(SizeOf(TSpaceTimerSE));
  if LastTimer <> nil then LastTimer.Next := Timer;
  Timer.Prev := LastTimer;
  Timer.Next := nil;
  LastTimer := Timer;
  if FirstTimer = nil then FirstTimer := Timer;
  Timer.TicksRemaining := Round(DelayMs / 18);
  Timer.RepeatTicks := Round(RepeatMs / 18);
  Timer.Callback := Callback;
  Timer.UserData := UserData;
  Result := Timer;
end;
{ @end $614AE0 }

{ @routine $614B64 TSpaceSE_DeleteTimer }
procedure TSpaceSE.DeleteTimer(Timer: PSpaceTimerSE);
var
  Entry: PSpaceTimerSE;
begin
  Entry := Timer;
  if NextTimerToProcess = Entry then raise Exception.Create('Error');
  if Entry.Prev <> nil then Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then Entry.Next.Prev := Entry.Prev;
  if LastTimer = Entry then LastTimer := Entry.Prev;
  if FirstTimer = Entry then FirstTimer := Entry.Next;
  FreeEC(Entry);
end;
{ @end $614B64 }

{ @routine $614BC8 TSpaceSE_AdvanceTimers }
procedure TSpaceSE.AdvanceTimers;
var
  Timer: PSpaceTimerSE;
begin
  NextTimerToProcess := FirstTimer;
  while NextTimerToProcess <> nil do
  begin
    Timer := NextTimerToProcess;
    NextTimerToProcess := NextTimerToProcess.Next;
    Dec(Timer.TicksRemaining);
    if Timer.TicksRemaining <= 0 then
    begin
      Timer.TicksRemaining := Timer.RepeatTicks;
      Timer.Callback(Timer, Timer.UserData);
    end;
  end;
  NextTimerToProcess := nil;
end;
{ @end $614BC8 }

{ @routine $614C08 TSpaceSE_AdvanceObjects }
procedure TSpaceSE.AdvanceObjects;
var
  Obj: TObjectSE;
begin
  Obj := FirstObject;
  while Obj <> nil do
  begin
    Obj.Advance;
    Obj := Obj.Next;
  end;
end;
{ @end $614C08 }

{ @routine $614C20 TSpaceSE_ClearPath }
procedure TSpaceSE.ClearPath;
begin
  if PathPoints <> nil then
  begin
    FreeEC(PathPoints);
    PathPoints := nil;
  end;
  PathPointCount := 0;
end;
{ @end $614C20 }

{ @routine $614C3C TSpaceSE_SetPath }
procedure TSpaceSE.SetPath(Points: PPointF; Count: Integer);
begin
  ClearPath;
  if Count < 1 then Exit;
  PathPointCount := Count;
  PathPoints := AllocEC(Count * SizeOf(TPointF));
  CopyMemory(PathPoints, Points, Count * SizeOf(TPointF));
end;
{ @end $614C3C }

{ @routine $614C7C TSpaceSE_DrawMinimap }
procedure TSpaceSE.DrawMinimap;
var
  Obj: TObjectSE;
  SavedBuffer: TGraphBufGR;
  CurrentProcess: TProcessSE;
  Coordinate: PSingle;
  Index, X1, Y1, X2, Y2, CenterX, CenterY: Integer;
  Color, PreviousColor: Cardinal;
  Gradient: Single;
  Clip: TRect;
begin
  SavedBuffer := ScreenRenderBuffer;
  ScreenRenderBuffer := RenderScratchBuffer;
  CurrentProcess := Process as TProcessSE;
  Clip := Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
  MinimapBackground.HitTestBounds := Clip;
  MinimapBackground.Draw(Clip);
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if Obj is TStarSE then Obj.DrawMap;
    Obj := Obj.Next;
  end;
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if Obj is TPlanetSE then Obj.DrawMap;
    Obj := Obj.Next;
  end;
  Obj := FirstObject;
  while Obj <> nil do
  begin
    if not (Obj is TStarSE) then
      if not (Obj is TPlanetSE) then Obj.DrawMap;
    Obj := Obj.Next;
  end;
  if PathPoints <> nil then
  begin
    CenterX := RenderScratchBuffer.Width shr 1;
    CenterY := RenderScratchBuffer.Height shr 1;
    Coordinate := Pointer(PathPoints);
    X1 := CenterX + Round(Coordinate^ * MinimapScale);
    Coordinate := Pointer(PAnsiChar(Coordinate) + SizeOf(Single));
    Y1 := CenterY + Round(Coordinate^ * MinimapScale);
    Coordinate := Pointer(PAnsiChar(Coordinate) + SizeOf(Single));
    Gradient := 0;
    PreviousColor := PackArgbFloats(1 - 0.8 * Gradient, 1, Gradient, 0);
    for Index := 1 to PathPointCount - 1 do
    begin
      X2 := CenterX + Round(Coordinate^ * MinimapScale);
      Coordinate := Pointer(PAnsiChar(Coordinate) + SizeOf(Single));
      Y2 := CenterY + Round(Coordinate^ * MinimapScale);
      Coordinate := Pointer(PAnsiChar(Coordinate) + SizeOf(Single));
      Gradient := (Index mod 200) / 199;
      Color := PackArgbFloats(1 - 0.8 * Gradient, 1, Gradient, 0);
      DrawGradientLine16Clipped(RenderScratchBuffer.Pixels, RenderScratchBuffer.PitchBytes,
        X1, Y1, PreviousColor, X2, Y2, Color, Clip);
      PreviousColor := Color;
      X1 := X2;
      Y1 := Y2;
    end;
  end;
  if CurrentProcess.RadarRange > 0 then
  begin
    MinimapRangeShade.SetCenter(Classes.Point((RenderScratchBuffer.Width shr 1) + Round(CurrentProcess.RadarCenter.X * MinimapScale),
      (RenderScratchBuffer.Height shr 1) + Round(CurrentProcess.RadarCenter.Y * MinimapScale)));
    MinimapRangeShade.SetRadius(Round(CurrentProcess.ActionRange * MinimapScale));
    MinimapRangeShade.HitTestBounds := Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
    MinimapRangeShade.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
    MinimapRangeCircle.SetCenter(Classes.Point((RenderScratchBuffer.Width shr 1) + Round(CurrentProcess.RadarCenter.X * MinimapScale),
      (RenderScratchBuffer.Height shr 1) + Round(CurrentProcess.RadarCenter.Y * MinimapScale)));
    MinimapRangeCircle.SetRadius(Round(CurrentProcess.ActionRange * MinimapScale));
    MinimapRangeCircle.SetColor(CurrentProcess.ActionColor);
    MinimapRangeCircle.HitTestBounds := Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height);
    MinimapRangeCircle.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  end;
  MinimapViewportFrame.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
  ScreenRenderBuffer := SavedBuffer;
end;
{ @end $614C7C }

{ @routine $6150EC TSpaceSE_CreateMinimapViewport }
procedure TSpaceSE.CreateMinimapViewport;
var
  Width, Height: Integer;
begin
  FreeMinimapViewport;
  MinimapViewportFrame := TFrameGI.Create(SpaceObjectUiLoop.ContentPanel);
  MinimapViewportFrame.SetDepth(-99999);
  MinimapViewportFrame.SetKind(fkRect);
  MinimapViewportFrame.SetColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
  Width := Round(MapPanel.ClientSize.X * MinimapScale);
  Height := Round(MapPanel.ClientSize.Y * MinimapScale);
  MinimapViewportFrame.SetSize(Classes.Point(Width, Height));
  MinimapViewportFrame.SetOrigin(Classes.Point(Width div 2, Height div 2));
  MapPanel.ScrollChangedCallback := MapScrollChanged;
  MapScrollChanged(nil);
end;
{ @end $6150EC }

{ @routine $6151C4 TSpaceSE_FreeMinimapViewport }
procedure TSpaceSE.FreeMinimapViewport;
begin
  if MinimapViewportFrame <> nil then
  begin
    MinimapViewportFrame.Free;
    MinimapViewportFrame := nil;
  end;
end;
{ @end $6151C4 }

{ @routine $6151DC TSpaceSE_MapScrollChanged }
procedure TSpaceSE.MapScrollChanged(Sender: TObjectGI);
begin
  if Sender = MapPanel then FilmCameraFollow := False;
  if MinimapViewportFrame <> nil then
    MinimapViewportFrame.SetPosition(Classes.Point(Round(MapPanel.ScrollOffset.X * MinimapScale),
      Round(MapPanel.ScrollOffset.Y * MinimapScale)));
  if StarField <> nil then StarField.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if (WindDensity >= 1) and (StarFieldM <> nil) then
    StarFieldM.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if SpaceImages <> nil then SpaceImages.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if (WindDensity >= 2) and (StarFieldImages <> nil) then
    StarFieldImages.SetViewPosition(PointToPointF(MapPanel.ScrollOffset));
  if Assigned(ScrollChangedCallback) then ScrollChangedCallback;
  (Process as TProcessSE).UpdateViewRect;
  SpaceViewPosition := PointToPointF(MapPanel.ScrollOffset);
end;
{ @end $6151DC }

{ @routine $6152F4 TSpaceSE_MinimapMouseDown }
procedure TSpaceSE.MinimapMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Local: TPoint;
  Child: TObjectGI;
begin
  MinimapDragging := False;
  if Sender.IsOccludedAtPoint(Point) then Exit;
  if Screen = StarMapScreen then
  begin
    if StarMapScreen.CenterShipButton.HitTest(Point) then Exit;
    Child := StarMapScreen.SecondaryPartnerPanel.FirstChild;
    while Child <> nil do
    begin
      if (Child as TGraphButtonGI).HitTest(Point) then Exit;
      Child := Child.NextSibling;
    end;
  end;
  if Screen = FilmScreen then
    if FilmScreen.CenterShipButton.HitTest(Point) then Exit;
  MinimapDragging := True;
  FilmCameraFollow := False;
  Local := Sender.ToLocalPoint(Point);
  MapPanel.SetScrollOffset(Classes.Point(Round(Local.X / MinimapScale), Round(Local.Y / MinimapScale)));
  MapScrollChanged(nil);
  MinimapFrameCounter := 0;
end;
{ @end $6152F4 }

{ @routine $615410 TSpaceSE_MinimapMouseEnter }
procedure TSpaceSE.MinimapMouseEnter(Sender: TObjectGI);
begin
  MinimapDragging := False;
end;
{ @end $615410 }

{ @routine $615418 TSpaceSE_MinimapMouseMove }
procedure TSpaceSE.MinimapMouseMove(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var
  Local: TPoint;

begin
  if MinimapDragging then
  begin
    if (Integer(KeyState and MK_LBUTTON) <> MK_LBUTTON) and ((KeyState and MK_RBUTTON) <> MK_RBUTTON) then Exit;
    if Sender.IsOccludedAtPoint(Point) then Exit;
    if StarMapScreen = Screen then
      if StarMapScreen.CenterShipButton.HitTest(Point) then Exit;
    if FilmScreen = Screen then
      if FilmScreen.CenterShipButton.HitTest(Point) then Exit;
    Local := Sender.ToLocalPoint(Point);
    MapPanel.SetScrollOffset(Classes.Point(Round(Local.X / MinimapScale), Round(Local.Y / MinimapScale)));
    MapScrollChanged(nil);
    MinimapFrameCounter := 0;
  end;
end;
{ @end $615418 }

{ @routine $615508 TSpaceSE_ContainsMapPoint }
function TSpaceSE.ContainsMapPoint(Point: TPointF): Boolean;
begin
  if MapPanel = nil then Result := False
  else Result := MapPanel.ContainsPoint(MapPanel.ToAbsolutePoint(TruncatePointF(Point)));
end;
{ @end $615508 }

end.

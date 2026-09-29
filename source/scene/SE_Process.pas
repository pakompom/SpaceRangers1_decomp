unit SE_Process;
// Unit bracket (inferred): CODE 0x0060E6E4..0x0060F84B; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_MessageLoop, GI_Panel, SE_Space, Types;

type
  TProcessSE = class(TObject) // @size $50 @methodorder source
  public
    Space: TSpaceSE; // @offset $04
    FirstObject: TObjectSE; // @offset $08
    LastObject: TObjectSE; // @offset $0C
    RetainedObjects: TList; // @offset $10  Scene object references.
    BackgroundTimer: PSpaceTimerSE; // @offset $14
    PreviousViewRect: TRect; // @offset $18
    ViewRect: TRect; // @offset $28
    RadarCenter: TPointF; // @offset $38
    RadarRange: Integer; // @offset $40
    ActionRange: Integer; // @offset $44
    ActionColor: Cardinal; // @offset $48
    SystemRadius: Integer; // @offset $4C

    constructor Create(const ConfigName: WideString); // @addr $60E74C
    destructor Destroy; override; // @addr $60E7FC
    function IsSpaceOpen: Boolean; // @addr $60E99C
    procedure PopulateAmbientObjects(Radius: Integer); // @addr $60E9A8
    procedure StartBackgroundEffects; // @addr $60EE2C
    procedure StopBackgroundEffects; // @addr $60EEA0
    procedure AdvanceBackgroundEffects(Timer: PSpaceTimerSE; UserData: Integer); // @addr $60EEF4
    function SelectBackgroundAnimation: WideString; // @addr $60F040
    procedure UpdateViewRect; // @addr $60F010
    procedure AddObject(Obj: TObjectSE); // @addr $60E858 @note "Links Obj into the process list; does not attach it to Space."
    procedure RemoveObject(Obj: TObjectSE); // @addr $60E87C @note "Unlinks Obj from the process list."
    procedure OpenSpace(MapPanel: TPanelGI; Screen: TMessageLoopGI); virtual; // @addr $60E8B0 @slot $00
    procedure BindMinimap(Control: TObjectGI); virtual; // @addr $60E900 @slot $04
    procedure CloseSpace; virtual; // @addr $60E970 @slot $08
    procedure LoadFromBlock(Block: TBlockParEC); virtual; // @addr $60F130 @slot $0C
  end;

function CreateSpaceObjectByName(const ClassName, GraphKey: WideString; UnusedPosition: TPoint): TObjectSE; // @addr $60F25C @note "Film-tag factory; copies the eight-byte point and forwards it to the selected constructor. Returns nil for an unknown case-sensitive tag."
function ClassSEtoName(Obj: TObjectSE): WideString; // @addr $60F54C @note "Returns the film type tag; raises for an unsupported scene class."

implementation

// @unit-initialization $60F844
// @unit-finalization $60F814

uses SE_Comet, SE_Angel, SE_Meteorite, aGalaxy, SE_Star, SE_StarsField, SE_Planet, SE_Sputnik, SE_Asteroid, SE_Hole, SE_Ruins, SE_Ship2, SE_Container, SE_Laser, SE_Anim, SE_BGObj, SE_Weapon, SE_Gate, Windows, SysUtils, Math, GR_Main, GlobalsV, Globals, aMyFunction, EC_Str, GI_Main;

{ @routine $60E74C TProcessSE_Create }
constructor TProcessSE.Create(const ConfigName: WideString);
begin
  inherited Create;
  LoadFromBlock(GameDataConfig.GetBlockByPath('SE.' + ConfigName));
  RetainedObjects := TList.Create;
end;
{ @end $60E74C }

{ @routine $60E7FC TProcessSE_Destroy }
destructor TProcessSE.Destroy;
var
  Obj: TObjectSE;
begin
  CloseSpace;
  while FirstObject <> nil do
  begin
    Obj := LastObject;
    RemoveObject(Obj);
    Obj.Free;
  end;
  if RetainedObjects <> nil then
  begin
    RetainedObjects.Free;
    RetainedObjects := nil;
  end;
  inherited Destroy;
end;
{ @end $60E7FC }

{ @routine $60E858 TProcessSE_AddObject }
procedure TProcessSE.AddObject(Obj: TObjectSE);
begin
  if LastObject <> nil then LastObject.ProcessNext := Obj;
  Obj.ProcessPrev := LastObject;
  Obj.ProcessNext := nil;
  LastObject := Obj;
  if FirstObject = nil then FirstObject := Obj;
end;
{ @end $60E858 }

{ @routine $60E87C TProcessSE_RemoveObject }
procedure TProcessSE.RemoveObject(Obj: TObjectSE);
begin
  if Obj.ProcessPrev <> nil then Obj.ProcessPrev.ProcessNext := Obj.ProcessNext;
  if Obj.ProcessNext <> nil then Obj.ProcessNext.ProcessPrev := Obj.ProcessPrev;
  if LastObject = Obj then LastObject := Obj.ProcessPrev;
  if FirstObject = Obj then FirstObject := Obj.ProcessNext;
end;
{ @end $60E87C }

{ @routine $60E8B0 TProcessSE_OpenSpace }
procedure TProcessSE.OpenSpace(MapPanel: TPanelGI; Screen: TMessageLoopGI);
var
  Obj: TObjectSE;
begin
  if not IsSpaceOpen then
  begin
    Space := TSpaceSE.Create(MapPanel, Screen);
    Space.Process := Self;
    Obj := FirstObject;
    while Obj <> nil do
    begin
      Obj.AttachToSpace(Space);
      Obj := Obj.ProcessNext;
    end;
    StartBackgroundEffects;
  end;
end;
{ @end $60E8B0 }

{ @routine $60E900 TProcessSE_BindMinimap }
procedure TProcessSE.BindMinimap(Control: TObjectGI);
begin
  if IsSpaceOpen then
  begin
    Space.MinimapControl := Control;
    Space.MinimapControl.LeftButtonDownCallback := Space.MinimapMouseDown;
    Space.MinimapControl.RightButtonDownCallback := Space.MinimapMouseDown;
    Space.MinimapControl.MouseEnterCallback := Space.MinimapMouseEnter;
    Space.MinimapControl.MouseMoveCallback := Space.MinimapMouseMove;
    Space.CreateMinimapViewport;
  end;
end;
{ @end $60E900 }

{ @routine $60E970 TProcessSE_CloseSpace }
procedure TProcessSE.CloseSpace;
begin
  if IsSpaceOpen then
  begin
    StopBackgroundEffects;
    Space.FreeMinimapViewport;
    Space.Free;
    Space := nil;
  end;
end;
{ @end $60E970 }

{ @routine $60E99C TProcessSE_IsSpaceOpen }
function TProcessSE.IsSpaceOpen: Boolean;
begin
  if Space = nil then Result := False else Result := True;
end;
{ @end $60E99C }

{ @routine $60E9A8 TProcessSE_PopulateAmbientObjects }
procedure TProcessSE.PopulateAmbientObjects(Radius: Integer);
var
  Block: TBlockParEC;
  Count, Index, BlockCount, BlockIndex: Integer;
  MinRadius, MaxRadius, Diameter: Integer;
  CountRange: TPoint;
  NextObj, Obj: TObjectSE;
begin
  Count := 0;
  NextObj := FirstObject;
  while NextObj <> nil do
  begin
    Obj := NextObj;
    NextObj := NextObj.ProcessNext;
    if (Obj is TCometSE) or (Obj is TAngelSE) or (Obj is TMeteoriteSE) then
    begin
      RemoveObject(Obj);
      Obj.DetachFromSpace;
      Obj.Free;
    end;
  end;
  MinRadius := TStar(Galaxy.Stars[0]).MapDiameter;
  MaxRadius := MinRadius;
  for Index := 1 to Galaxy.Stars.Count - 1 do
  begin
    Diameter := TStar(Galaxy.Stars[Index]).MapDiameter;
    MinRadius := Min(MinRadius, Diameter);
    MaxRadius := Max(MaxRadius, Diameter);
  end;
  MinRadius := MinRadius div 2;
  MaxRadius := MaxRadius div 2;
  Block := GameDataConfig.GetBlockByPath('SE.Anim.BGO_HS.Objects');
  if CometDensity > 0 then
  begin
    CountRange.X := 15;
    CountRange.Y := 30;
    if Block.CountParams('CometCount') > 0 then
      CountRange := GetPointGI(Block.GetParam('CometCount'));
    if CometDensity = 1 then Count := CountRange.X else Count := CountRange.Y;
    Count := Round(RemapClamped(Radius, MinRadius, MaxRadius, 0.5, 2.0) * Count);
    for Index := 1 to Count do
      AddObject(TCometSE.Create('Anim.BGO_HS.Comet', Classes.Point(0, 0)));
  end;
  // Keeps the comet count when AngelCount is absent.
  if Block.CountParams('AngelCount') > 0 then
  begin
    CountRange := GetPointGI(Block.GetParam('AngelCount'));
    Count := RandomIntRange(CountRange.X, CountRange.Y);
  end;
  for Index := 1 to Count do
    AddObject(TAngelSE.Create('Anim.BGO_HS.Angel', Classes.Point(0, 0)));
  CountRange := GetPointGI(GameDataConfig.GetParamByPath('SE.Anim.BGO_HS.Objects.MeteoriteCount'));
  Count := RandomIntRange(CountRange.X, CountRange.Y);
  Block := GameDataConfig.GetBlockByPath('SE.Meteorite');
  BlockCount := Block.GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    BlockIndex := RandomIntRange(0, BlockCount - 1);
    AddObject(TMeteoriteSE.Create('Meteorite.' + Block.GetBlockNameByIndex(BlockIndex), Classes.Point(0, 0)));
  end;
end;
{ @end $60E9A8 }

{ @routine $60EE2C TProcessSE_StartBackgroundEffects }
procedure TProcessSE.StartBackgroundEffects;
begin
  StopBackgroundEffects;
  if IsSpaceOpen then
  begin
    ViewRect := Classes.Rect(-100001, -100001, -100000, -100000);
    UpdateViewRect;
    BackgroundTimer := Space.CreateTimer(BGOTime, BGOTime, AdvanceBackgroundEffects, 0);
  end;
end;
{ @end $60EE2C }

{ @routine $60EEA0 TProcessSE_StopBackgroundEffects }
procedure TProcessSE.StopBackgroundEffects;
var
  Obj: TObjectSE;
  Index: Integer;
begin
  if IsSpaceOpen then
  begin
    for Index := 0 to RetainedObjects.Count - 1 do
    begin
      Obj := RetainedObjects[Index];
      Obj.Free;
        end;
    RetainedObjects.Clear;
    if BackgroundTimer <> nil then
    begin
      Space.DeleteTimer(BackgroundTimer);
      BackgroundTimer := nil;
    end;
  end;
end;
{ @end $60EEA0 }

{ @routine $60EEF4 TProcessSE_AdvanceBackgroundEffects }
procedure TProcessSE.AdvanceBackgroundEffects(Timer: PSpaceTimerSE; UserData: Integer);
var
  Obj: TObjectSE;
  Index: Integer;
  Position: TPointF;
begin
  Index := 0;
  while Index < RetainedObjects.Count do
  begin
    Obj := RetainedObjects[Index];
    if not Obj.IsAttachedToSpace then
    begin
      RetainedObjects.Delete(Index);
      Obj.Free;
    end
    else Inc(Index);
  end;
  if BGOCount <= RetainedObjects.Count then Exit;
  if RandomIntRange(0, BGOCount - 1) < RetainedObjects.Count - 1 then Exit;
  begin
    Obj := TAnimSE.Create(SelectBackgroundAnimation, Classes.Point(0, 0));
    Position.X := RandomIntRange(ViewRect.Left, ViewRect.Right);
    Position.Y := RandomIntRange(ViewRect.Top, ViewRect.Bottom);
    Obj.SetPosition(Position);
    Obj.AttachToSpace(Space);
    RetainedObjects.Add(Obj);
  end;
end;
{ @end $60EEF4 }

{ @routine $60F010 TProcessSE_UpdateViewRect }
procedure TProcessSE.UpdateViewRect;
begin
  PreviousViewRect := ViewRect;
  ViewRect := Space.MapPanel.GetVisibleContentRect;
end;
{ @end $60F010 }

{ @routine $60F040 TProcessSE_SelectBackgroundAnimation }
function TProcessSE.SelectBackgroundAnimation: WideString;
var
  Block: TBlockParEC;
  Index, Count, Weight: Integer;
begin
  Block := GameDataConfig.GetBlockByPath('SE.BGO');
  Count := Block.GetParamCount;
  Weight := 0;
  for Index := 0 to Count - 1 do Inc(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  Weight := RandomIntRange(0, Weight - 1);
  Index := 0;
  Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  while Weight >= 0 do
  begin
    Inc(Index);
    Dec(Weight, ExtractDigitsToIntW(Block.GetParamName(Index)));
  end;
  Result := Block.GetParamValue(Index);
end;
{ @end $60F040 }

{ @routine $60F130 TProcessSE_LoadFromBlock }
procedure TProcessSE.LoadFromBlock(Block: TBlockParEC);
var
  Obj: TObjectSE;
  Objects: TBlockParEC;
  Count, Index: Integer;
begin
  Objects := Block.GetBlockByPath('Objects');
  Count := Objects.GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    Obj := CreateSpaceObjectByName(Objects.GetBlockNameByIndex(Index),
      Objects.GetBlockByIndex(Index).GetParam('Type'),
      GetPointGI(Objects.GetBlockByIndex(Index).GetParam('Size')));
    if Obj <> nil then
    begin
      AddObject(Obj);
      Obj.ApplyConfig(Objects.GetBlockByIndex(Index));
    end;
  end;
end;
{ @end $60F130 }

{ @routine $60F25C CreateSpaceObjectByName }
function CreateSpaceObjectByName(const ClassName, GraphKey: WideString; UnusedPosition: TPoint): TObjectSE;
begin
  if ClassName = 'Star' then Result := TStarSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'StarsField' then Result := TStarsFieldSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Planet' then Result := TPlanetSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Sputnik' then Result := TSputnikSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Asteroid' then Result := TAsteroidSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Hole' then Result := THoleSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Ruins' then Result := TRuinsSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Ship2' then Result := TShip2SE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Container' then Result := TContainerSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Laser' then Result := TLaserSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Anim' then Result := TAnimSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'BGObj' then Result := TBGObjSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Weapon' then Result := TWeaponSE.Create(GraphKey, UnusedPosition)
  else if ClassName = 'Gate' then Result := TGateSE.Create(GraphKey, UnusedPosition)
  else Result := nil;
end;
{ @end $60F25C }

{ @routine $60F54C ClassSEtoName }
function ClassSEtoName(Obj: TObjectSE): WideString;
begin
  if Obj is TStarSE then Result := 'Star'
  else if Obj is TPlanetSE then Result := 'Planet'
  else if Obj is TSputnikSE then Result := 'Sputnik'
  else if Obj is TAsteroidSE then Result := 'Asteroid'
  else if Obj is THoleSE then Result := 'Hole'
  else if Obj is TRuinsSE then Result := 'Ruins'
  else if Obj is TShip2SE then Result := 'Ship2'
  else if Obj is TContainerSE then Result := 'Container'
  else if Obj is TLaserSE then Result := 'Laser'
  else if Obj is TAnimSE then Result := 'Anim'
  else if Obj is TBGObjSE then Result := 'BGObj'
  else if Obj is TWeaponSE then Result := 'Weapon'
  else if Obj is TGateSE then Result := 'Gate'
  else raise Exception.Create('Error');
end;
{ @end $60F54C }

end.

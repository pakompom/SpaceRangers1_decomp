unit SE_Sputnik;
// Unit bracket (inferred): CODE 0x005D0D88..0x005D1537; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Buf, EC_Struct, GI_MessageLoop, GI_Planet, SE_Space;

type
  TSputnikSE = class(TObjectSE) // @size $B0
  public
    ImagePath: WideString; // @offset $48
    DepthOrder: Integer; // @offset $4C  Serialized as a byte; separates overlapping satellites in front of/behind the planet.
    OrbitCenter: TPointF; // @offset $50
    OrbitInclination: Single; // @offset $58  Degrees.
    OrbitRotation: Single; // @offset $5C  Degrees in the display plane.
    OrbitAngleStep: Single; // @offset $60
    OrbitTimerInterval: Cardinal; // @offset $64
    OrbitRadius: Single; // @offset $68
    MinDisplayRadius: Integer; // @offset $6C
    MaxDisplayRadius: Integer; // @offset $70
    RotationTimerInterval: Cardinal; // @offset $74
    SurfaceMapStep: Integer; // @offset $78
    OrbitAngle: Single; // @offset $7C  Saved separately by TSputnik.SaveToBuffer.
    SurfaceMapOffset: Integer; // @offset $80
    DisplayRadius: Integer; // @offset $84
    LightAngle: Byte; // @offset $88  A full turn has 256 steps.
    InclinationCos: Single; // @offset $8C
    InclinationSin: Single; // @offset $90
    RotationCos: Single; // @offset $94
    RotationSin: Single; // @offset $98
    MinOrbitDepth: Single; // @offset $9C
    MaxOrbitDepth: Single; // @offset $A0
    PlanetControl: TPlanetGI; // @offset $A4  Owned while attached.
    OrbitTimer: TCallbackTimerIdGI; // @offset $A8
    RotationTimer: TCallbackTimerIdGI; // @offset $AC

    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $5D0E50 @note "Does nothing when satellite graphics are disabled."
    procedure DetachFromSpace; override; // @addr $5D0F30
    procedure SetOrbitCenter(Center: TPointF); override; // @addr $5D0F98 @slot $18
    function GetOrbitCenter: TPointF; override; // @addr $5D0FBC @slot $1C
    function BuildStateBuffer: TBufEC; override; // @addr $5D0FC8 @slot $38 @note "Returns a new buffer owned by the caller; excludes OrbitAngle."
    procedure LoadStateBuffer(Buffer: TBufEC); override; // @addr $5D1044 @slot $3C @note "Rewinds Buffer to zero and rebuilds the orbit transform and display position."
    procedure RebuildOrbitTransform; // @addr $5D10D4
    procedure UpdateOrbitDisplay; // @addr $5D1160 @note "Requires a nonzero depth range when attached; updates position, apparent radius and drawing depth."
    procedure AdvanceOrbitTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5D13F8
    procedure AdvanceRotationTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $5D141C
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $5D1438
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $5D14A8
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $5D14B0
  end;

implementation

// @unit-initialization $5D1530
// @unit-finalization $5D1500

uses Math, GlobalsV, Globals, GR_Main, aMyFunction, Types;
{ @routine $5D0E50 TSputnikSE_AttachToSpace }
procedure TSputnikSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not SputnikShow then Exit;
  if IsAttachedToSpace then Exit;
  inherited AttachToSpace(ASpace);
  PlanetControl := TPlanetGI.Create(Space.MapPanel);
  PlanetControl.SetPositionModeW(True);
  PlanetControl.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
  PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
  RebuildOrbitTransform;
  UpdateOrbitDisplay;
  OrbitTimer := Space.Screen.ScheduleCallbackTimer(OrbitTimerInterval, OrbitTimerInterval, AdvanceOrbitTimer);
  RotationTimer := Space.Screen.ScheduleCallbackTimer(RotationTimerInterval, RotationTimerInterval, AdvanceRotationTimer);
end;
{ @end $5D0E50 }

{ @routine $5D0F30 TSputnikSE_DetachFromSpace }
procedure TSputnikSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  if OrbitTimer <> 0 then
  begin
    Space.Screen.CancelCallbackTimer(OrbitTimer);
    OrbitTimer := 0;
  end;
  if RotationTimer <> 0 then
  begin
    Space.Screen.CancelCallbackTimer(RotationTimer);
    RotationTimer := 0;
  end;
  PlanetControl.Free;
  PlanetControl := nil;
  inherited DetachFromSpace;
end;
{ @end $5D0F30 }

{ @routine $5D0F98 TSputnikSE_SetOrbitCenter }
procedure TSputnikSE.SetOrbitCenter(Center: TPointF);
begin
  OrbitCenter := Center;
  UpdateOrbitDisplay;
end;
{ @end $5D0F98 }

{ @routine $5D0FBC TSputnikSE_GetOrbitCenter }
function TSputnikSE.GetOrbitCenter: TPointF;
begin
  Result := OrbitCenter;
end;
{ @end $5D0FBC }

{ @routine $5D0FC8 TSputnikSE_BuildStateBuffer }
function TSputnikSE.BuildStateBuffer: TBufEC;
var
  Buffer: TBufEC;
begin
  Buffer := TBufEC.Create;
  Buffer.AddAnsiChar(AnsiChar(DepthOrder));
  Buffer.AddSingle(OrbitInclination);
  Buffer.AddSingle(OrbitRotation);
  Buffer.AddSingle(OrbitAngleStep);
  Buffer.AddDWord(OrbitTimerInterval);
  Buffer.AddSingle(OrbitRadius);
  Buffer.AddIntegerValue(MinDisplayRadius);
  Buffer.AddIntegerValue(MaxDisplayRadius);
  Buffer.AddDWord(RotationTimerInterval);
  Buffer.AddIntegerValue(SurfaceMapStep);
  Result := Buffer;
end;
{ @end $5D0FC8 }

{ @routine $5D1044 TSputnikSE_LoadStateBuffer }
procedure TSputnikSE.LoadStateBuffer(Buffer: TBufEC);
begin
  Buffer.SetPosition(0);
  DepthOrder := Buffer.GetByte;
  OrbitInclination := Buffer.GetSingle;
  OrbitRotation := Buffer.GetSingle;
  OrbitAngleStep := Buffer.GetSingle;
  OrbitTimerInterval := Buffer.GetUInt32;
  OrbitRadius := Buffer.GetSingle;
  MinDisplayRadius := Buffer.GetInt32;
  MaxDisplayRadius := Buffer.GetInt32;
  RotationTimerInterval := Buffer.GetUInt32;
  SurfaceMapStep := Buffer.GetInt32;
  RebuildOrbitTransform;
  UpdateOrbitDisplay;
end;
{ @end $5D1044 }

{ @routine $5D10D4 TSputnikSE_RebuildOrbitTransform }
procedure TSputnikSE.RebuildOrbitTransform;
var
  Angle: Single;
begin
  Angle := HeadingDegreesToRadians(OrbitRotation);
  RotationCos := Cos(Angle);
  RotationSin := Sin(Angle);
  Angle := HeadingDegreesToRadians(OrbitInclination);
  InclinationCos := Cos(Angle);
  InclinationSin := Sin(Angle);
  MaxOrbitDepth := Abs(-InclinationSin * OrbitRadius);
  MinOrbitDepth := -MaxOrbitDepth;
end;
{ @end $5D10D4 }

{ @routine $5D1160 TSputnikSE_UpdateOrbitDisplay }
procedure TSputnikSE.UpdateOrbitDisplay;
var
  X, Y, Z, Angle, OrbitX, OrbitY: Single;
  Template: TSputnikTempl;
  TemplateIndex: Integer;
begin
  if not IsAttachedToSpace then Exit;
  Angle := HeadingDegreesToRadians(OrbitAngle);
  OrbitX := Sin(Angle) * OrbitRadius;
  OrbitY := Cos(Angle) * -OrbitRadius;
  X := InclinationCos * RotationCos * OrbitX + -RotationSin * OrbitY + OrbitCenter.X;
  Y := InclinationCos * RotationSin * OrbitX + OrbitY * RotationCos + OrbitCenter.Y;
  Z := -InclinationSin * OrbitX;
  Position := MakePointF(X, Y);
  DisplayRadius := Round((Z - MinOrbitDepth) / (MaxOrbitDepth - MinOrbitDepth) * (MaxDisplayRadius - MinDisplayRadius) + MinDisplayRadius);
  if DisplayRadius < MinDisplayRadius then DisplayRadius := MinDisplayRadius
  else if DisplayRadius > MaxDisplayRadius then DisplayRadius := MaxDisplayRadius;
  if GameScreenWidth = 800 then DisplayRadius := Round(DisplayRadius * 800 / 1024);
  LightAngle := Round(ArcTan2(-Position.X, Position.Y) * 180 / 3.1415926 * 256 / 360);
  TemplateIndex := DisplayRadius - MinimumSatelliteTemplateRadius;
  Template := SatelliteRenderTemplates[TemplateIndex];
  PlanetControl.SetImageFromTemplate(Template.MaskName, ImagePath, Template.Radius);
  PlanetControl.SetLightAngle(LightAngle);
  PlanetControl.SetPosition(TruncatePointF(Position));
  PlanetControl.SetOrigin(Classes.Point(Template.Radius, Template.Radius));
  if Z < 0 then PlanetControl.SetDepth(DepthOrder + PlanetDepth + 1)
  else PlanetControl.SetDepth(PlanetDepth - DepthOrder - 1);
end;
{ @end $5D1160 }

{ @routine $5D13F8 TSputnikSE_AdvanceOrbitTimer }
procedure TSputnikSE.AdvanceOrbitTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  OrbitAngle := WrapHeadingDegrees(OrbitAngle + OrbitAngleStep);
  UpdateOrbitDisplay;
end;
{ @end $5D13F8 }

{ @routine $5D141C TSputnikSE_AdvanceRotationTimer }
procedure TSputnikSE.AdvanceRotationTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  SurfaceMapOffset := SurfaceMapOffset + SurfaceMapStep;
  PlanetControl.SetSurfaceMapOffset(SurfaceMapOffset);
end;
{ @end $5D141C }

{ @routine $5D1438 TSputnikSE_LoadTemplate }
procedure TSputnikSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
end;
{ @end $5D1438 }

{ @routine $5D14A8 TSputnikSE_ApplyConfig }
procedure TSputnikSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $5D14A8 }

{ @routine $5D14B0 TSputnikSE_QueueImageLoad }
procedure TSputnikSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Template: TSputnikTempl;
begin
  Template := SatelliteRenderTemplates[0];
  with TPlanetGI.Create(Owner) do
  begin
    SetImageFromTemplate(Template.MaskName, Self.ImagePath, Template.Radius);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;
{ @end $5D14B0 }

end.

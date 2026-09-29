unit GI_PSSubmesonicCannon;
// Unit bracket (inferred): CODE 0x004A15E8..0x004A286F; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PSubmesonicCannonParticle = ^TSubmesonicCannonParticle;
  TSubmesonicCannonParticle = record // @size $2C
    Prev: PSubmesonicCannonParticle; // @offset $0
    Next: PSubmesonicCannonParticle; // @offset $4
    Position: TPointF; // @offset $08
    Color: Word; // @offset $10
    SavedPixel: Word; // @offset $12
    Velocity: TPointF; // @offset $14
    Alpha: Byte; // @offset $1C
    RadialVelocity: TPointF; // @offset $20
    Kind: Byte; // @offset $28
  end;
  TPSSubmesonicCannonGI = class(TPSWeaponGI) // @size $140
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PSubmesonicCannonParticle; // @offset $114
    LastParticle: PSubmesonicCannonParticle; // @offset $118
    FrameDirty: Byte; // @offset $11C
    TimerInterval: Integer; // @offset $120
    CallbackTimer: TCallbackTimerIdGI; // @offset $124
    Color1: Word; // @offset $128
    EmissionIndex: Integer; // @offset $12C
    ProjectionBounds: TRect; // @offset $130 Native projection rectangle, independently read by both bounds methods.

    procedure Draw(ClipRect: TRect); override; // @addr $4A2174
    procedure EmitRing(CenterX, CenterY, Radius: Integer; ParticleColor: Word; Alpha: Byte; RadialSpeed, TravelSpeed: Double; Count: Integer; Kind: Byte); // @addr $4A1E9C
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $4A2094
    constructor Create(Owner: TObjectGI); // @addr $4A1714
    destructor Destroy; override; // @addr $4A17B4
    procedure SetPosition(Position: TPoint); override; // @addr $4A17E0
    procedure SetTargetPoint(Point: TPoint); override; // @addr $4A1818
    procedure SetHalfWidth(Value: Integer); // @addr $4A1858
    procedure SetTimerInterval(Value: Integer); // @addr $4A186C
    procedure RestartTimer; // @addr $4A1880
    procedure CancelTimer; // @addr $4A1884
    procedure SetActive(Enabled: Boolean); override; // @addr $4A18A8
    procedure UpdateProjectionBounds; // @addr $4A18D4
    procedure UpdateHitTestBounds; override; // @addr $4A1B58
    function GetLocalBounds: TRect; override; // @addr $4A1B8C
    function AddParticle: PSubmesonicCannonParticle; // @addr $4A1BBC
    procedure InvalidateRect(Rect: TRect); override; // @addr $4A1BFC
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4A1CB8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4A1CE4
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $4A1D00
    function IsFinished: Boolean; override; // @addr $4A2168
  end;

implementation

// @unit-initialization $4A2868
// @unit-finalization $4A2838

uses GR_GraphBuf, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $4A1714 TPSSubmesonicCannonGI_Create }
constructor TPSSubmesonicCannonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  TimerInterval := 50;
  HalfWidth := 2;
  RemainingTicks := 50;
  EmissionIndex := 0;
  FrameDirty := 0;
  UpdateProjectionBounds;
  RestartTimer;
  Color1 := CurrentPixelFormat.PackNormalizedRgb(1, 0.2, 0.2);
end;
{ @end $4A1714 }

{ @routine $4A17B4 TPSSubmesonicCannonGI_Destroy }
destructor TPSSubmesonicCannonGI.Destroy;
begin
  CancelTimer;
  inherited Destroy;
end;
{ @end $4A17B4 }

{ @routine $4A17E0 TPSSubmesonicCannonGI_SetPosition }
procedure TPSSubmesonicCannonGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $4A17E0 }

{ @routine $4A1818 TPSSubmesonicCannonGI_SetTargetPoint }
procedure TPSSubmesonicCannonGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A1818 }

{ @routine $4A1858 TPSSubmesonicCannonGI_SetHalfWidth }
procedure TPSSubmesonicCannonGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $4A1858 }

{ @routine $4A186C TPSSubmesonicCannonGI_SetTimerInterval }
procedure TPSSubmesonicCannonGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $4A186C }

{ @routine $4A1880 TPSSubmesonicCannonGI_RestartTimer }
procedure TPSSubmesonicCannonGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $4A1880 }

{ @routine $4A1884 TPSSubmesonicCannonGI_CancelTimer }
procedure TPSSubmesonicCannonGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $4A1884 }

{ @routine $4A18A8 TPSSubmesonicCannonGI_SetActive }
procedure TPSSubmesonicCannonGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
  end;
end;
{ @end $4A18A8 }

{ @routine $4A18D4 TPSSubmesonicCannonGI_UpdateProjectionBounds }
procedure TPSSubmesonicCannonGI.UpdateProjectionBounds;
var
  Angle, Sine, Cosine, Distance, A, B, C, D: Single;
  DY: Integer;
begin
  DY := -(TargetPoint.Y - LocalPosition.Y);
  if DY = 0 then Inc(DY);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, DY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
  A := (-HalfWidth - 48) * Cosine - -Distance * Sine;
  B := (HalfWidth + 48) * Cosine - -Distance * Sine;
  C := (-HalfWidth - 48) * Cosine;
  D := (HalfWidth + 48) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth - 48) * Sine + -Distance * Cosine;
  B := (HalfWidth + 48) * Sine + -Distance * Cosine;
  C := (-HalfWidth - 48) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth + 48) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;
{ @end $4A18D4 }

{ @routine $4A1B58 TPSSubmesonicCannonGI_UpdateHitTestBounds }
procedure TPSSubmesonicCannonGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $4A1B58 }

{ @routine $4A1B8C TPSSubmesonicCannonGI_GetLocalBounds }
function TPSSubmesonicCannonGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $4A1B8C }

{ @routine $4A1BBC TPSSubmesonicCannonGI_AddParticle }
function TPSSubmesonicCannonGI.AddParticle: PSubmesonicCannonParticle;
var Particle: PSubmesonicCannonParticle;
begin
  Particle := AllocEC(SizeOf(TSubmesonicCannonParticle));
  if LastParticle <> nil then LastParticle.Next := Particle;
  Particle.Prev := LastParticle;
  Particle.Next := nil;
  LastParticle := Particle;
  if FirstParticle = nil then FirstParticle := Particle;
  Result := Particle;
end;
{ @end $4A1BBC }

{ @routine $4A1BFC TPSSubmesonicCannonGI_InvalidateRect }
procedure TPSSubmesonicCannonGI.InvalidateRect(Rect: TRect);
var Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(HitTestBounds,
    Parent.ToAbsolutePoint(LocalPosition), Parent.ToAbsolutePoint(TargetPoint), HalfWidth);
  with Parent.ToAbsolutePoint(TargetPoint) do begin
    Rect.Left := X - 48;
    Rect.Right := X + 48;
    Rect.Top := Y - 48;
    Rect.Bottom := Y + 48;
  end;
  if IntersectRects(Intersection, Rect, GameScreenRect) then MessageLoop.QueueUpdateRect(Intersection);
end;
{ @end $4A1BFC }

{ @routine $4A1CB8 TPSSubmesonicCannonGI_LoadFromConfigPath }
procedure TPSSubmesonicCannonGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4A1CB8 }

{ @routine $4A1CE4 TPSSubmesonicCannonGI_LoadFromBlock }
procedure TPSSubmesonicCannonGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $4A1CE4 }

{ @routine $4A1D00 TPSSubmesonicCannonGI_LoadEffectProperties }
procedure TPSSubmesonicCannonGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color1') > 0 then Color1 := GetColorGI(Block.GetParam('Color1'));
end;
{ @end $4A1D00 }

{ @routine $4A1E9C TPSSubmesonicCannonGI_EmitRing }
procedure TPSSubmesonicCannonGI.EmitRing(CenterX, CenterY, Radius: Integer; ParticleColor: Word; Alpha: Byte; RadialSpeed, TravelSpeed: Double; Count: Integer; Kind: Byte);
var
  Angle: Single;
  PreviousSin, CurrentSin, PreviousCos, CurrentCos: Double;
  Particle: PSubmesonicCannonParticle;
  I: Integer;
begin
  Angle := 0;
  PreviousSin := 0;
  PreviousCos := 1;
  while Angle < 2 * Pi do
  begin
    Angle := Angle + Pi / 8;
    CurrentSin := Sin(Angle);
    CurrentCos := Cos(Angle);
    for I := 0 to Count - 1 do
    begin
      Particle := AddParticle;
      Particle.Position := MakePointF(((CurrentCos - PreviousCos) * I / Count + PreviousCos) * Radius + CenterX,
        ((CurrentSin - PreviousSin) * I / Count + PreviousSin) * Radius + CenterY);
      Particle.Color := ParticleColor;
      Particle.Alpha := Alpha;
      Particle.RadialVelocity := MakePointF(((CurrentCos - PreviousCos) * I / Count + PreviousCos) * RadialSpeed,
        ((CurrentSin - PreviousSin) * I / Count + PreviousSin) * RadialSpeed);
      Particle.Velocity := MakePointF(((CurrentCos - PreviousCos) * I / Count + PreviousCos) * TravelSpeed,
        ((CurrentSin - PreviousSin) * I / Count + PreviousSin) * TravelSpeed);
      Particle.Kind := Kind;
    end;
    PreviousSin := CurrentSin;
    PreviousCos := CurrentCos;
  end;
end;
{ @end $4A1E9C }

{ @routine $4A2094 TPSSubmesonicCannonGI_Advance }
procedure TPSSubmesonicCannonGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Current, Particle: PSubmesonicCannonParticle;
begin
  Invalidate;
  if EmissionIndex >= 9 then
  begin
    Current := FirstParticle;
    while Current <> nil do
    begin
      Particle := Current;
      Current := Current.Next;
      case Particle.Kind of
      1: begin
        Particle.Position.X := Particle.Position.X + Particle.RadialVelocity.X;
        Particle.Position.Y := Particle.Position.Y + Particle.RadialVelocity.Y;
        if (RemainingTicks < 25) and (Particle.Alpha > 5) then Dec(Particle.Alpha, 6);
      end;
      end;
    end;
  end;
  if EmissionIndex < 9 then
    EmitRing(0, 0, EmissionIndex, Color1, 160 - (Abs(EmissionIndex - 4) shl 7) div 4, 1.5, (-EmissionIndex + 4) / 2, 14, 1);
  Inc(EmissionIndex);
  Dec(RemainingTicks);
  FrameDirty := 1;
end;
{ @end $4A2094 }

{ @routine $4A2168 TPSSubmesonicCannonGI_IsFinished }
function TPSSubmesonicCannonGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $4A2168 }

{ @routine $4A2174 TPSSubmesonicCannonGI_Draw }
procedure TPSSubmesonicCannonGI.Draw(ClipRect: TRect);
var
  Particle: PSubmesonicCannonParticle;
  X, Y, OriginX, OriginY: Integer;
begin
  OriginX := AbsolutePosition.X + TargetPoint.X - LocalPosition.X;
  OriginY := AbsolutePosition.Y + TargetPoint.Y - LocalPosition.Y;
  if FrameDirty <> 0 then
  begin
    FrameDirty := 0;
    Particle := FirstParticle;
    while Particle <> nil do
    begin
      X := OriginX + Round(Particle.Position.X + Particle.Velocity.X);
      Y := OriginY + Round(Particle.Position.Y + Particle.Velocity.Y);
      Particle.SavedPixel := ScreenRenderBuffer.GetPixel16Checked(X, Y);
      Particle := Particle.Next;
    end;
  end;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    X := OriginX + Round(Particle.Position.X);
    Y := OriginY + Round(Particle.Position.Y);
    if (X >= ClipRect.Left) and (X < ClipRect.Right) and (Y >= ClipRect.Top) and (Y < ClipRect.Bottom) then
    begin
      ScreenRenderBuffer.SetPixel16(X, Y, Particle.SavedPixel);
      ScreenRenderBuffer.BlendPixel16(X, Y, Particle.Color, Particle.Alpha);
    end;
    Particle := Particle.Next;
  end;
  OriginX := AbsolutePosition.X;
  OriginY := AbsolutePosition.Y;
  X := TargetPoint.X - LocalPosition.X;
  Y := TargetPoint.Y - LocalPosition.Y;
  if EmissionIndex < 9 then
  begin
    if Abs(X) > Abs(Y) then
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX, OriginY - 1, OriginX + X div 4, OriginY + Y div 4 - 1, Color1, 32, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX, OriginY + 1, OriginX + X div 4, OriginY + Y div 4 + 1, Color1, 32, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX, OriginY, OriginX + X div 4, OriginY + Y div 4, Color1, 90, ClipRect);
    end
    else
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX - 1, OriginY, OriginX + X div 4 - 1, OriginY + Y div 4 - 1, Color1, 32, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + 1, OriginY, OriginX + X div 4 + 1, OriginY + Y div 4 - 1, Color1, 32, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX, OriginY, OriginX + X div 4, OriginY + Y div 4, Color1, 90, ClipRect);
    end;
    if Abs(X) > Abs(Y) then
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 4, OriginY - 1 + Y div 4, OriginX + X div 2, OriginY + Y div 2 - 1, Color1, 64, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 4, OriginY + 1 + Y div 4, OriginX + X div 2, OriginY + Y div 2 + 1, Color1, 64, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 4, OriginY + Y div 4, OriginX + X div 2, OriginY + Y div 2, Color1, 150, ClipRect);
    end
    else
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX - 1 + X div 4, OriginY + Y div 4, OriginX + X div 2 - 1, OriginY + Y div 2 - 1, Color1, 64, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + 1 + X div 4, OriginY + Y div 4, OriginX + X div 2 + 1, OriginY + Y div 2 - 1, Color1, 64, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 4, OriginY + Y div 4, OriginX + X div 2, OriginY + Y div 2, Color1, 150, ClipRect);
    end;
    if Abs(X) > Abs(Y) then
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 2, OriginY - 1 + Y div 2, OriginX + X, OriginY + Y - 1, Color1, 96, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 2, OriginY + 1 + Y div 2, OriginX + X, OriginY + Y + 1, Color1, 96, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 2, OriginY + Y div 2, OriginX + X, OriginY + Y, Color1, 212, ClipRect);
    end
    else
    begin
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX - 1 + X div 2, OriginY + Y div 2, OriginX + X - 1, OriginY + Y - 1, Color1, 96, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + 1 + X div 2, OriginY + Y div 2, OriginX + X + 1, OriginY + Y - 1, Color1, 96, ClipRect);
      ScreenRenderBuffer.DrawAlphaLine16Clipped(OriginX + X div 2, OriginY + Y div 2, OriginX + X, OriginY + Y, Color1, 212, ClipRect);
    end;
  end;
end;
{ @end $4A2174 }

end.

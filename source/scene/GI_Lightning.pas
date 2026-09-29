unit GI_Lightning;
// Unit bracket (inferred): CODE 0x0049D400..0x0049ECD7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, GI_PSWeapon, EC_Struct, EC_BlockPar, Types;

type
  PLightningParticle = ^TLightningParticle;
  TLightningParticle = record // @size $48
    Prev: PLightningParticle; // @offset $0
    Next: PLightningParticle; // @offset $4
    StartPoint: TPointF; // @offset $08
    EndPoint: TPointF; // @offset $10
    Kind: Integer; // @offset $18
    Color: Word; // @offset $1C
    DarkColor: Word; // @offset $1E
    Alpha: Byte; // @offset $20
    InitialDistance: Integer; // @offset $24
    RemainingDistance: Integer; // @offset $28
    BranchChance: Integer; // @offset $2C
    Width: Integer; // @offset $30
    Lifetime: Integer; // @offset $34
    StartVelocity: TPointF; // @offset $38
    EndVelocity: TPointF; // @offset $40
  end;
  TPSLightningGI = class(TPSWeaponGI) // @size $158
  public
    HalfWidth: Integer; // @offset $110 Used by native projection geometry.
    FirstParticle: PLightningParticle; // @offset $114
    LastParticle: PLightningParticle; // @offset $118
    EmissionDelay: Integer; // @offset $11C
    TimerInterval: Integer; // @offset $120
    CallbackTimer: TCallbackTimerIdGI; // @offset $124
    PendingSparkSteps: Word; // @offset $128
    Color: Word; // @offset $12A
    DarkColor: Word; // @offset $12C
    ProjectionBounds: TRect; // @offset $12E Native projection rectangle, independently read by both bounds methods.
    Phase: Single; // @offset $140
    LengthScale: Double; // @offset $148
    OriginalLength: Double; // @offset $150

    procedure Draw(ClipRect: TRect); override; // @addr $49E6B0
    procedure FindDarkestDirection(X, Y: Integer; var DX, DY: Double); // @addr $49E1D4
    procedure AdvanceImpactSparks; // @addr $49E404
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); override; // @addr $49DD90
    constructor Create(Owner: TObjectGI); // @addr $49D524
    destructor Destroy; override; // @addr $49D618
    procedure SetPosition(Position: TPoint); override; // @addr $49D644
    procedure SetTargetPoint(Point: TPoint); override; // @addr $49D67C
    procedure SetHalfWidth(Value: Integer); // @addr $49D6BC
    procedure SetTimerInterval(Value: Integer); // @addr $49D6D0
    procedure RestartTimer; // @addr $49D6E4
    procedure CancelTimer; // @addr $49D6E8
    procedure SetActive(Enabled: Boolean); override; // @addr $49D70C
    procedure UpdateProjectionBounds; // @addr $49D738
    procedure UpdateHitTestBounds; override; // @addr $49D9BC
    function GetLocalBounds: TRect; override; // @addr $49D9F0
    function AddParticle: PLightningParticle; // @addr $49DA20
    procedure RemoveParticle(Particle: PLightningParticle); // @addr $49DA60
    procedure InvalidateRect(Rect: TRect); override; // @addr $49DAA8
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49DB64
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49DB90
    procedure LoadEffectProperties(Block: TBlockParEC); // @addr $49DBAC
    function IsFinished: Boolean; override; // @addr $49E6A4
  end;

implementation

// @unit-initialization $49ECD0
// @unit-finalization $49ECA0

uses GR_GraphBuf, Math, SysUtils, EC_Mem, GI_Main, GR_Main;

{ @routine $49D524 TPSLightningGI_Create }
constructor TPSLightningGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  EmissionDelay := 0;
  TimerInterval := 50;
  RemainingTicks := 60;
  HalfWidth := 6;
  LengthScale := 1;
  OriginalLength := 1;
  UpdateProjectionBounds;
  RestartTimer;
  Color := CurrentPixelFormat.PackNormalizedRgb(0.9, 0.7, 1);
  DarkColor := CurrentPixelFormat.PackNormalizedRgb(0.25, 0.15, 0.6);
  Phase := 0;
end;
{ @end $49D524 }

{ @routine $49D618 TPSLightningGI_Destroy }
destructor TPSLightningGI.Destroy;
begin
  CancelTimer;
  inherited Destroy;
end;
{ @end $49D618 }

{ @routine $49D644 TPSLightningGI_SetPosition }
procedure TPSLightningGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X <> Position.X) or (LocalPosition.Y <> Position.Y) then begin
    inherited SetPosition(Position);
    UpdateProjectionBounds;
  end;
end;
{ @end $49D644 }

{ @routine $49D67C TPSLightningGI_SetTargetPoint }
procedure TPSLightningGI.SetTargetPoint(Point: TPoint);
begin
  if (TargetPoint.X <> Point.X) or (TargetPoint.Y <> Point.Y) then begin
    TargetPoint := Point;
    UpdateProjectionBounds;
  end;
end;
{ @end $49D67C }

{ @routine $49D6BC TPSLightningGI_SetHalfWidth }
procedure TPSLightningGI.SetHalfWidth(Value: Integer);
begin
  if Value <> HalfWidth then begin
    HalfWidth := Value;
    UpdateProjectionBounds;
  end;
end;
{ @end $49D6BC }

{ @routine $49D6D0 TPSLightningGI_SetTimerInterval }
procedure TPSLightningGI.SetTimerInterval(Value: Integer);
begin
  if Value <> TimerInterval then begin TimerInterval := Value; RestartTimer; end;
end;
{ @end $49D6D0 }

{ @routine $49D6E4 TPSLightningGI_RestartTimer }
procedure TPSLightningGI.RestartTimer;
begin
  // Empty in the shipped effect.
end;
{ @end $49D6E4 }

{ @routine $49D6E8 TPSLightningGI_CancelTimer }
procedure TPSLightningGI.CancelTimer;
begin
  if CallbackTimer <> 0 then begin MessageLoop.CancelCallbackTimer(CallbackTimer); CallbackTimer := 0; end;
end;
{ @end $49D6E8 }

{ @routine $49D70C TPSLightningGI_SetActive }
procedure TPSLightningGI.SetActive(Enabled: Boolean);
begin
  if Enabled <> Active then begin
    inherited SetActive(Enabled);
    if Enabled = True then RestartTimer else CancelTimer;
  end;
end;
{ @end $49D70C }

{ @routine $49D738 TPSLightningGI_UpdateProjectionBounds }
procedure TPSLightningGI.UpdateProjectionBounds;
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
  A := (-HalfWidth - 16) * Cosine - -Distance * Sine;
  B := (HalfWidth + 16) * Cosine - -Distance * Sine;
  C := (-HalfWidth - 16) * Cosine;
  D := (HalfWidth + 16) * Cosine;
  ProjectionBounds.Left := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Right := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
  A := (-HalfWidth - 16) * Sine + -Distance * Cosine;
  B := (HalfWidth + 16) * Sine + -Distance * Cosine;
  C := (-HalfWidth - 16) * Sine;
  // Native uses Cosine for this final corner as well.
  D := (HalfWidth + 16) * Cosine;
  ProjectionBounds.Top := Floor(Math.Min(Math.Min(Math.Min(A, B), C), D));
  ProjectionBounds.Bottom := Ceil(Math.Max(Math.Max(Math.Max(A, B), C), D));
end;
{ @end $49D738 }

{ @routine $49D9BC TPSLightningGI_UpdateHitTestBounds }
procedure TPSLightningGI.UpdateHitTestBounds;
begin
  HitTestBounds.Left := ProjectionBounds.Left + AbsolutePosition.X;
  HitTestBounds.Top := ProjectionBounds.Top + AbsolutePosition.Y;
  HitTestBounds.Right := ProjectionBounds.Right + AbsolutePosition.X;
  HitTestBounds.Bottom := ProjectionBounds.Bottom + AbsolutePosition.Y;
end;
{ @end $49D9BC }

{ @routine $49D9F0 TPSLightningGI_GetLocalBounds }
function TPSLightningGI.GetLocalBounds: TRect;
begin
  Result.Left := ProjectionBounds.Left + LocalPosition.X;
  Result.Top := ProjectionBounds.Top + LocalPosition.Y;
  Result.Right := ProjectionBounds.Right + LocalPosition.X;
  Result.Bottom := ProjectionBounds.Bottom + LocalPosition.Y;
end;
{ @end $49D9F0 }

{ @routine $49DA20 TPSLightningGI_AddParticle }
function TPSLightningGI.AddParticle: PLightningParticle;
var Particle: PLightningParticle;
begin
  Particle := AllocEC(SizeOf(TLightningParticle));
  if FirstParticle <> nil then FirstParticle.Prev := Particle;
  Particle.Prev := nil;
  Particle.Next := FirstParticle;
  FirstParticle := Particle;
  if LastParticle = nil then LastParticle := Particle;
  Result := Particle;
end;
{ @end $49DA20 }

{ @routine $49DA60 TPSLightningGI_RemoveParticle }
procedure TPSLightningGI.RemoveParticle(Particle: PLightningParticle);
begin
  if Particle <> nil then begin
  if Particle.Prev <> nil then Particle.Prev.Next := Particle.Next;
  if Particle.Next <> nil then Particle.Next.Prev := Particle.Prev;
  if LastParticle = Particle then LastParticle := Particle.Prev;
  if FirstParticle = Particle then FirstParticle := Particle.Next;
  FreeEC(Particle);
  end;
end;
{ @end $49DA60 }

{ @routine $49DAA8 TPSLightningGI_InvalidateRect }
procedure TPSLightningGI.InvalidateRect(Rect: TRect);
var Intersection: TRect;
begin
  MessageLoop.UpdateRects.AddScreenClippedRect(HitTestBounds,
    Parent.ToAbsolutePoint(LocalPosition), Parent.ToAbsolutePoint(TargetPoint), HalfWidth);
  with Parent.ToAbsolutePoint(TargetPoint) do begin
    Rect.Left := X - 24;
    Rect.Right := X + 24;
    Rect.Top := Y - 24;
    Rect.Bottom := Y + 24;
  end;
  if IntersectRects(Intersection, Rect, GameScreenRect) then MessageLoop.QueueUpdateRect(Intersection);
end;
{ @end $49DAA8 }

{ @routine $49DB64 TPSLightningGI_LoadFromConfigPath }
procedure TPSLightningGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadEffectProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49DB64 }

{ @routine $49DB90 TPSLightningGI_LoadFromBlock }
procedure TPSLightningGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadEffectProperties(Block);
end;
{ @end $49DB90 }

{ @routine $49DBAC TPSLightningGI_LoadEffectProperties }
procedure TPSLightningGI.LoadEffectProperties(Block: TBlockParEC);
begin
  if Block.CountParams('MaxRadius') > 0 then SetHalfWidth(StrToInt(AnsiString(Block.GetParam('MaxRadius'))));
  if Block.CountParams('PosDes') > 0 then SetTargetPoint(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('TimeTakt') > 0 then SetTimerInterval(StrToInt(AnsiString(Block.GetParam('TimeTakt'))));
  if Block.CountParams('Color') > 0 then Color := GetColorGI(Block.GetParam('Color'));
  if Block.CountParams('DarkColor') > 0 then DarkColor := GetColorGI(Block.GetParam('DarkColor'));
end;
{ @end $49DBAC }

{ @routine $49DD90 TPSLightningGI_Advance }
procedure TPSLightningGI.Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Current, Particle, Added: PLightningParticle;
  Distance: Single;
  I: Integer;
  SavedColor, SavedDarkColor: Word;
  Kind: Integer;
begin
  Invalidate;
  if EmissionDelay > 0 then Dec(EmissionDelay);
  if (FirstParticle = nil) and (EmissionDelay = 0) and (RemainingTicks > 16) then
  begin
    Distance := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y));
    OriginalLength := Distance;
    if OriginalLength = 0 then OriginalLength := 1;
    LengthScale := 1;
    Current := AddParticle;
    Current.StartPoint := MakePointF(0, 0);
    Current.EndPoint := MakePointF(0, 0);
    Current.Kind := 1;
    Current.Color := Color;
    Current.DarkColor := DarkColor;
    Current.Alpha := 48;
    Current.InitialDistance := Trunc(Distance + 20);
    Current.RemainingDistance := Current.InitialDistance;
    Current.BranchChance := 0;
    Current.Width := 3;
  end
  else
  begin
    Distance := OriginalLength;
    LengthScale := Sqrt(Sqr(TargetPoint.X - LocalPosition.X) + Sqr(TargetPoint.Y - LocalPosition.Y)) / OriginalLength;
    Current := FirstParticle;
    while Current <> nil do
    begin
      Particle := Current;
      Current := Current.Next;
      Kind := Particle.Kind;
      if Kind = 1 then begin
        I := 0;
        while I < 4 do
        begin
          Added := AddParticle;
          Added.Kind := 2;
          Added.Color := Particle.Color;
          Added.DarkColor := Particle.DarkColor;
          Added.Alpha := Particle.Alpha;
          Added.StartPoint := Particle.StartPoint;
          if Particle.Width > 1 then Added.Width := Particle.Width - 1 else Added.Width := 1;
          Particle.EndPoint := MakePointF(Random(HalfWidth * 2) - HalfWidth, Random(16) + (Particle.EndPoint.Y + 16));
          Inc(Particle.BranchChance, 2);
          Added.EndPoint := Particle.EndPoint;
          Particle.RemainingDistance := Trunc(Particle.RemainingDistance - Particle.EndPoint.Y + Particle.StartPoint.Y);
          Particle.StartPoint := Particle.EndPoint;
          if Particle.Alpha < 187 then Inc(Particle.Alpha, 25) else Particle.Alpha := 212;
          if (Particle.StartPoint.Y > Distance) or (Particle.RemainingDistance < 0) then
          begin
            Particle.Kind := 2;
            if Particle.StartPoint.Y > Distance then
            begin
              Added.EndPoint := MakePointF(0, Distance);
              SavedColor := Particle.Color;
              SavedDarkColor := Particle.DarkColor;
              Added := AddParticle;
              Added.StartPoint := MakePointF(0, 0);
              Added.Color := SavedColor;
              Added.DarkColor := SavedDarkColor;
              Added.Alpha := 192;
              Added.StartVelocity := MakePointF(0, 0);
              Added.Kind := 3;
              Added.Lifetime := 20;
            end;
            Particle := nil;
          end;
          if (Particle <> nil) and (Random(100) > 94 - Particle.BranchChance) then
          begin
            Added := AddParticle;
            Added.Kind := 1;
            Added.Color := Particle.Color;
            Added.DarkColor := Particle.DarkColor;
            Added.Alpha := 212;
            Added.StartPoint := Particle.StartPoint;
            Added.EndPoint := Particle.EndPoint;
            Added.InitialDistance := Random((Particle.InitialDistance shr 1) - 16) + 16;
            Added.RemainingDistance := Added.InitialDistance;
            Added.BranchChance := Particle.BranchChance shr 1;
            if Particle.Width > 1 then Added.Width := Particle.Width - 1 else Added.Width := 1;
            Particle.BranchChance := 0;
          end;
          if Particle = nil then Break;
          Inc(I);
        end;
      end
      else if (Kind = 2) and (RemainingTicks < 16) then RemoveParticle(Particle);
    end;
    Inc(PendingSparkSteps);
    Phase := Phase + Pi / 8;
  end;
  Dec(RemainingTicks);
end;
{ @end $49DD90 }

{ @routine $49E1D4 TPSLightningGI_FindDarkestDirection }
procedure TPSLightningGI.FindDarkestDirection(X, Y: Integer; var DX, DY: Double);
var Best, Brightness: Integer; AllSame: Boolean;
begin
  Best := 95;
  DX := 0;
  DY := 0;
  AllSame := True;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X - 1, Y));
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := -0.925;
    DY := 0;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := -0.925;
    DY := -0.925;
  end;
  // The native upward probe repeats the upper-left pixel.
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X - 1, Y - 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := 0;
    DY := -0.925;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X + 1, Y - 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := 0.925;
    DY := -0.925;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X + 1, Y));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := 0.925;
    DY := 0;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X + 1, Y + 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := 0.925;
    DY := 0.925;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X, Y + 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := 0;
    DY := 0.925;
  end;
  Brightness := Integer(ScreenRenderBuffer.GetBrightness16(X - 1, Y + 1));
  if Brightness <> Best then AllSame := False;
  if Brightness < Best then
  begin
    Best := Brightness;
    DX := -0.925;
    DY := 0.925;
  end;
  if AllSame then begin DX := 0; DY := 0; end;
end;
{ @end $49E1D4 }

{ @routine $49E404 TPSLightningGI_AdvanceImpactSparks }
procedure TPSLightningGI.AdvanceImpactSparks;
var
  OriginX, OriginY: Integer;
  Current, Particle, Added: PLightningParticle;
  I: Integer;
  Angle: Single;
  DX, DY: Double;
  Kind, X, Y: Integer;
begin
  OriginX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  OriginY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  Current := FirstParticle;
  while Current <> nil do
  begin
    Particle := Current;
    Current := Current.Next;
    Kind := Particle.Kind;
    if Kind = 3 then
    begin
      for I := 0 to 0 do
      begin
        Angle := Random(12) * Pi / 6;
        Added := AddParticle;
        Added.StartPoint := MakePointF(0, 0);
        Added.EndPoint := MakePointF(Sin(Angle) * 3, Cos(Angle) * 3);
        Added.Color := Particle.Color;
        Added.DarkColor := Particle.DarkColor;
        Added.Width := 1;
        Added.Alpha := Particle.Alpha;
        Added.StartVelocity := MakePointF(Sin(Angle) * 1.85, Cos(Angle) * 1.85);
        Added.EndVelocity := MakePointF(Sin(Angle) * 1.85, Cos(Angle) * 1.85);
        Added.Kind := 4;
        Added.Lifetime := 12;
      end;
      Dec(Particle.Lifetime);
      if (Particle.Lifetime = 0) or (RemainingTicks < 9) then RemoveParticle(Particle);
    end
    else if Kind = 4 then
    begin
      if Particle.Alpha > 96 then Dec(Particle.Alpha, 4);
      Particle.StartPoint.X := Particle.StartPoint.X + Particle.StartVelocity.X;
      Particle.StartPoint.Y := Particle.StartPoint.Y + Particle.StartVelocity.Y;
      Particle.EndPoint.X := Particle.EndPoint.X + Particle.EndVelocity.X;
      Particle.EndPoint.Y := Particle.EndPoint.Y + Particle.EndVelocity.Y;
      X := Round(OriginX + Particle.StartPoint.X);
      Y := Round(OriginY + Particle.StartPoint.Y);
      FindDarkestDirection(X, Y, DX, DY);
      Particle.EndVelocity := Particle.StartVelocity;
      Particle.StartVelocity.X := Particle.StartVelocity.X + DX;
      Particle.StartVelocity.Y := Particle.StartVelocity.Y + DY;
      Dec(Particle.Lifetime);
      if Particle.Lifetime = 0 then RemoveParticle(Particle);
    end;
  end;
end;
{ @end $49E404 }

{ @routine $49E6A4 TPSLightningGI_IsFinished }
function TPSLightningGI.IsFinished: Boolean;
begin
  Result := RemainingTicks <= 0;
end;
{ @end $49E6A4 }

{ @routine $49E6B0 TPSLightningGI_Draw }
procedure TPSLightningGI.Draw(ClipRect: TRect);
var
  Particle: PLightningParticle;
  Angle, Sine, Cosine, StartX, StartY, EndX, EndY: Single;
  X1, Y1, X2, Y2, OriginX, OriginY: Integer;
  DY, I, Kind: Integer;
begin
  DY := -(TargetPoint.Y - LocalPosition.Y);
  if DY = 0 then Inc(DY);
  Angle := ArcTan2(TargetPoint.X - LocalPosition.X, DY);
  Sine := Sin(Angle);
  Cosine := Cos(Angle);
  OriginX := TargetPoint.X - LocalPosition.X + AbsolutePosition.X;
  OriginY := TargetPoint.Y - LocalPosition.Y + AbsolutePosition.Y;
  if (ClipRect.Left <= OriginX) and (ClipRect.Right > OriginX) and
     (ClipRect.Top <= OriginY) and (ClipRect.Bottom > OriginY) then
  begin
    for I := 1 to PendingSparkSteps do AdvanceImpactSparks;
    PendingSparkSteps := 0;
  end;
  DY := -20;
  while DY < 20 do
  begin
    ScreenRenderBuffer.ShiftBand16(OriginX - 20 - 1 + Abs(DY), OriginY + DY,
      2 * (21 - Abs(DY)), 2, Trunc(Sin(DY * Pi / 8 + Phase) * 6), ClipRect);
    Inc(DY, 2);
  end;
  Particle := FirstParticle;
  while Particle <> nil do
  begin
    Kind := Particle.Kind;
    case Kind of
    4: begin
      X1 := Trunc(Particle.StartPoint.X) + OriginX;
      Y1 := Trunc(Particle.StartPoint.Y) + OriginY;
      X2 := Trunc(Particle.EndPoint.X) + OriginX;
      Y2 := Trunc(Particle.EndPoint.Y) + OriginY;
      if Abs(X1 - X2) > Abs(Y2 - Y1) then
      begin
        for I := 1 to Particle.Width do
        begin
          // Native impact sparks have only the positive-Y dark outline.
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1, Y1 + I, X2, Y2 + I, Particle.DarkColor, Particle.Alpha, ClipRect);
        end;
        for I := -(Particle.Width shr 1) to -(Particle.Width shr 1) + Particle.Width - 1 do
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1, Y1 + I, X2, Y2 + I, Particle.Color, Particle.Alpha, ClipRect);
      end
      else
      begin
        for I := 1 to Particle.Width do
        begin
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 - I, Y1, X2 - I, Y2, Particle.DarkColor, Particle.Alpha, ClipRect);
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 + I, Y1, X2 + I, Y2, Particle.DarkColor, Particle.Alpha, ClipRect);
        end;
        for I := -(Particle.Width shr 1) to -(Particle.Width shr 1) + Particle.Width - 1 do
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 + I, Y1, X2 + I, Y2, Particle.Color, Particle.Alpha, ClipRect);
      end;
    end;
    else if Kind = 2 then
    begin
      StartX := Particle.StartPoint.X * LengthScale;
      StartY := -Particle.StartPoint.Y * LengthScale;
      EndX := Particle.EndPoint.X * LengthScale;
      EndY := -Particle.EndPoint.Y * LengthScale;
      X1 := Round(StartX * Cosine - StartY * Sine + AbsolutePosition.X);
      Y1 := Round(StartX * Sine + StartY * Cosine + AbsolutePosition.Y);
      X2 := Round(EndX * Cosine - EndY * Sine + AbsolutePosition.X);
      Y2 := Round(EndX * Sine + EndY * Cosine + AbsolutePosition.Y);
      if Abs(X1 - X2) > Abs(Y2 - Y1) then
      begin
        for I := 1 to Particle.Width do
        begin
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1, Y1 - I, X2, Y2 - I, Particle.DarkColor, Particle.Alpha, ClipRect);
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1, Y1 + I, X2, Y2 + I, Particle.DarkColor, Particle.Alpha, ClipRect);
        end;
        for I := -(Particle.Width shr 1) to -(Particle.Width shr 1) + Particle.Width - 1 do
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1, Y1 + I, X2, Y2 + I, Particle.Color, Particle.Alpha, ClipRect);
      end
      else
      begin
        for I := 1 to Particle.Width do
        begin
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 - I, Y1, X2 - I, Y2, Particle.DarkColor, Particle.Alpha, ClipRect);
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 + I, Y1, X2 + I, Y2, Particle.DarkColor, Particle.Alpha, ClipRect);
        end;
        for I := -(Particle.Width shr 1) to -(Particle.Width shr 1) + Particle.Width - 1 do
          ScreenRenderBuffer.DrawAlphaLine16Clipped(X1 + I, Y1, X2 + I, Y2, Particle.Color, Particle.Alpha, ClipRect);
      end;
    end;
    end;
    Particle := Particle.Next;
  end;
end;
{ @end $49E6B0 }

end.

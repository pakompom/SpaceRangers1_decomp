unit SE_Ship2;
// Unit bracket (inferred): CODE 0x00608DBC..0x0060AF4B; inclusive evidence, not full bounds.
// Ship rendering and animation.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_AlphaImage, GI_MessageLoop, GI_RotateImage5,
  GI_Tail, SE_Space, Types;

type
  TShip2AnimSE = class(TObject) // @size $1C
  public
    Prev: TShip2AnimSE; // @offset $04
    Next: TShip2AnimSE; // @offset $08
    Weight: Integer; // @offset $0C
    FrameCount: Integer; // @offset $10
    Frames: Pointer; // @offset $14 Owned 32-bit frame indices, accessed through EC_Mem.
    Delays: Pointer; // @offset $18 Owned 32-bit delays.
    destructor Destroy; override; // @addr $608EEC
    procedure Clear; // @addr $608F18
    procedure Load(Specification: WideString); // @addr $608F4C
  end;

  TShip2SE = class(TObjectSE) // @size $E4 @fieldpadding explicit @methodorder source
  public
    ImageSize: TPoint; // @offset $48
    ImageScale: TPointF; // @offset $50
    ImageOrigin: TPoint; // @offset $58
    ImageCenter: TPointF; // @offset $60
    Angle: Byte; // @offset $68
    Alpha: Byte; // @offset $69
    MinimapImagePath: WideString; // @offset $6C
    MinimapImageOrigin: TPoint; // @offset $70
    StateIntervalMs: Integer; // @offset $78
    ImagePath: WideString; // @offset $7C
    ReducedImagePath: WideString; // @offset $80
    FirstTailOrigin: TPointF; // @offset $84
    SecondTailOrigin: TPointF; // @offset $8C
    TailEmitIntervalMs: Cardinal; // @offset $94
    Image: TRotateImage5GI; // @offset $98
    MinimapImage: TAlphaImageGI; // @offset $9C
    FirstTail: TTailGI; // @offset $A0
    SecondTail: TTailGI; // @offset $A4
    SharedAnimations: Boolean; // @offset $A8
    FirstAnimation: TShip2AnimSE; // @offset $AC
    LastAnimation: TShip2AnimSE; // @offset $B0
    FirstReducedAnimation: TShip2AnimSE; // @offset $B4
    LastReducedAnimation: TShip2AnimSE; // @offset $B8
    CurrentAnimation: TShip2AnimSE; // @offset $BC
    NextAnimation: TShip2AnimSE; // @offset $C0
    CurrentFrameIndex: Integer; // @offset $C4
    AnimationTimer: TCallbackTimerIdGI; // @offset $C8
    StateTimer: TCallbackTimerIdGI; // @offset $CC
    TotalAnimationWeight: Integer; // @offset $D0
    TotalReducedAnimationWeight: Integer; // @offset $D4
    TailsActive: Boolean; // @offset $D8
    Use3D: Boolean; // @offset $D9
    Mesh: TObject; // @offset $DC Native callers check TabObj3D with an as cast.
    UploadedFrameIndex: Integer; // @offset $E0

    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $609344
    procedure DetachFromSpace; override; // @addr $6098E8
    procedure CopyTo(Destination: TObjectSE); override; // @addr $60922C
    procedure SetPosition(APosition: TPointF); override; // @addr $609A24
    procedure SetDepth(Value: Single); override; // @addr $609B2C
    function GetDepth: Single; override; // @addr $609B48
    function GetOrbitCenter: TPointF; override; // @addr $609DB0
    function GetAlpha: Byte; override; // @addr $609D5C
    procedure SetAlpha(Value: Byte); override; // @addr $609D60
    function GetAngle: Byte; override; // @addr $609B5C
    procedure SetAngle(Value: Byte); override; // @addr $609B60
    procedure SetSize(Value: TPoint); override; // @addr $6099DC
    function HitTestCursor: Boolean; override; // @addr $609FD0
    procedure DrawMap; override; // @addr $60A378
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $60A8B0
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $60AE00
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $60AE9C
    destructor Destroy; override; // @addr $6091A8
    procedure OffsetTailsAlongHeading(Distance: Single); // @addr $609C38
    procedure OffsetTails(Delta: TPointF); // @addr $609CF8
    procedure SetTailsEmitting(Value: Boolean); // @addr $609D30
    function ScaleImagePoint(Point: TPointF): TPointF; // @addr $609DC4
    function ImagePointToWorld(Point: TPointF): TPointF; // @addr $609DF0
    function GetTargetPoint(Heading: Byte; Seed: Integer): TPointF; // @addr $609EA0
    function AddAnimation: TShip2AnimSE; // @addr $60A004
    procedure DeleteAnimation(Animation: TShip2AnimSE); // @addr $60A048
    function AddReducedAnimation: TShip2AnimSE; // @addr $60A090
    procedure DeleteReducedAnimation(Animation: TShip2AnimSE); // @addr $60A0D4
    procedure StartAnimationTimer; // @addr $60A11C
    procedure StopAnimationTimer; // @addr $60A16C
    procedure StartStateTimer; // @addr $60A190
    procedure StopStateTimer; // @addr $60A1C0
    procedure AdvanceAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $60A1E4
    procedure SelectNextAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $60A2EC
    procedure SetTailsActive(Value: Boolean); // @addr $6099A8
    procedure Draw3D; // @addr $60A404
  end;

implementation

// @unit-initialization $60AF44
// @unit-finalization $60AF14

uses Math, SysUtils, aMyFunction, EC_Str, EC_Mem, GI_Main, Globals, GlobalsV, GR_Main, SE_Process, aPlayer, ab_Obj3D, ab_Tex, EC_OKGF, GR_GraphBuf;

{ @routine $608EEC TShip2AnimSE_Destroy }
destructor TShip2AnimSE.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $608EEC }

{ @routine $608F18 TShip2AnimSE_Clear }
procedure TShip2AnimSE.Clear;
begin
  if Frames <> nil then begin FreeEC(Frames); Frames := nil; end;
  if Delays <> nil then begin FreeEC(Delays); Delays := nil; end;
  Weight := 1;
  FrameCount := 0;
end;
{ @end $608F18 }

{ @routine $608F4C TShip2AnimSE_Load }
procedure TShip2AnimSE.Load(Specification: WideString);
var
  Index, RangeCount, FrameOffset, Count, Delay, First, Last: Integer;
  RangeText: WideString;
begin
  Clear;
  Index := CountDelimitedPartsW(Specification, ',');
  if Index < 3 then raise Exception.Create('Error');
  Weight := ExtractDigitsToIntW(ExtractDelimitedPartW(Specification, 0, ','));
  Specification := ExtractDelimitedRangeW(Specification, 1, Index - 1, ',');
  RangeCount := (CountDelimitedPartsW(Specification, '[]') - 1) div 2;
  for Index := 0 to RangeCount - 1 do
  begin
    RangeText := ExtractDelimitedPartW(Specification, Index * 2 + 1, '[]');
    Delay := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 0, ',-'));
    First := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 1, ',-'));
    Last := ExtractDigitsToIntW(ExtractDelimitedPartW(RangeText, 2, ',-'));
    Count := Abs(First - Last) + 1;
    Inc(FrameCount, Count);
    Frames := ReAllocREC(Frames, FrameCount * 4);
    Delays := ReAllocREC(Delays, FrameCount * 4);
    for FrameOffset := 0 to Count - 1 do
    begin
      WriteInt32EC(AddPointerOffset(Frames, (FrameCount - Count + FrameOffset) * 4), First);
      WriteInt32EC(AddPointerOffset(Delays, (FrameCount - Count + FrameOffset) * 4), Delay);
      if First < Last then Inc(First) else Dec(First);
    end;
  end;
end;
{ @end $608F4C }

{ @routine $6091A8 TShip2SE_Destroy }
destructor TShip2SE.Destroy;
begin
  StopStateTimer;
  StopAnimationTimer;
  CurrentAnimation := nil;
  NextAnimation := nil;
  if not SharedAnimations then
  begin
    while FirstAnimation <> nil do DeleteAnimation(LastAnimation);
    while FirstReducedAnimation <> nil do DeleteReducedAnimation(LastReducedAnimation);
  end;
  SharedAnimations := False;
  inherited Destroy;
end;
{ @end $6091A8 }

{ @routine $60922C TShip2SE_CopyTo }
procedure TShip2SE.CopyTo(Destination: TObjectSE);
var Ship: TShip2SE;
begin
  inherited CopyTo(Destination);
  Ship := Destination as TShip2SE;
  Ship.ImagePath := ImagePath;
  Ship.ReducedImagePath := ReducedImagePath;
  Ship.ImageSize := ImageSize;
  Ship.ImageScale := ImageScale;
  Ship.ImageOrigin := ImageOrigin;
  Ship.ImageCenter := ImageCenter;
  Ship.Angle := Angle;
  Ship.Alpha := Alpha;
  Ship.MinimapImagePath := MinimapImagePath;
  Ship.MinimapImageOrigin := MinimapImageOrigin;
  Ship.StateIntervalMs := StateIntervalMs;
  Ship.SharedAnimations := True;
  Ship.FirstAnimation := FirstAnimation;
  Ship.LastAnimation := LastAnimation;
  Ship.FirstReducedAnimation := FirstReducedAnimation;
  Ship.LastReducedAnimation := LastReducedAnimation;
  Ship.TotalAnimationWeight := TotalAnimationWeight;
  Ship.TotalReducedAnimationWeight := TotalReducedAnimationWeight;
  Ship.FirstTailOrigin := FirstTailOrigin;
  Ship.SecondTailOrigin := SecondTailOrigin;
end;
{ @end $60922C }

{ @routine $609344 TShip2SE_AttachToSpace }
procedure TShip2SE.AttachToSpace(ASpace: TSpaceSE);
var
  Object3D: TabObj3D;
  Batch: PabIndexBatch3D;
begin
  if not IsAttachedToSpace then
  begin
    ConfigureLoopSound('Ship');
    ConfigureRandomSound('Ship');
    inherited AttachToSpace(ASpace);
    Image := TRotateImage5GI.Create(Space.MapPanel);
    Image.SetPositionModeW(True);
    Image.SetDepthByName(DepthExpression);
    Image.SetPosition(Classes.Point(Trunc(Position.X), Trunc(Position.Y)));
    Image.SetAngle(Angle);
    Image.SetAlpha(Alpha);
    MinimapImage := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.GetContentSize));
    if AnimShipFull then CurrentAnimation := FirstAnimation else CurrentAnimation := FirstReducedAnimation;
    NextAnimation := CurrentAnimation;
    CurrentFrameIndex := 0;
    if AnimShipFull then Image.SetImage(ImagePath, Size, RoundPointF(GetOrbitCenter))
    else Image.SetImage(ReducedImagePath, Size, RoundPointF(GetOrbitCenter));
    Image.SetFrameIndex(ReadIntegerEC(AddPointerOffset(CurrentAnimation.Frames, CurrentFrameIndex * 4)));
    if Use3D then
    begin
      Mesh := ab_Obj3D_Add;
      Object3D := Mesh as TabObj3D;
      Object3D.Visible := False;
      Object3D.AllocateVertices(4);
      Batch := Object3D.AddIndexBatch(4, 6, '');
      Batch.Indices[0] := 0;
      Batch.Indices[1] := 1;
      Batch.Indices[2] := 3;
      Batch.Indices[3] := 1;
      Batch.Indices[4] := 2;
      Batch.Indices[5] := 3;
      Batch.PrimitiveCount := 2;
      Object3D.LockVertices;
      Object3D.GetVertex(0)^ := MakeArcadeVertex3D($FFFFFFFF, 0, 0, 0, 0, 0);
      Object3D.GetVertex(1)^ := MakeArcadeVertex3D($FFFFFFFF, 0, 0, 0, 1, 0);
      Object3D.GetVertex(2)^ := MakeArcadeVertex3D($FFFFFFFF, 0, 0, 0, 1, 1);
      Object3D.GetVertex(3)^ := MakeArcadeVertex3D($FFFFFFFF, 0, 0, 0, 0, 1);
      Object3D.UnlockVertices;
      Batch.Texture := ab_Tex_Add;
      Batch.Texture.AllocateRgba(128, 128);
      Batch.Texture.ReferenceCount := 1;
      UploadedFrameIndex := -1;
    end;
    if TailsActive then
    begin
      if FirstTailOrigin.Y > 0 then
      begin
        FirstTail := TTailGI.Create(Space.MapPanel);
        if TailEmitIntervalMs > 0 then FirstTail.EmitIntervalMs := TailEmitIntervalMs;
        FirstTail.SetSize(Classes.Point(1000000, 1000000));
        FirstTail.SetOrigin(HalfPoint(FirstTail.ClientSize));
        FirstTail.SetDepthByName('Tail');
        FirstTail.SetPositionModeW(True);
        FirstTail.SetImagePath('Bm.Tail.00');
        FirstTail.SetEmitting(Alpha = 255);
      end;
      if SecondTailOrigin.Y > 0 then
      begin
        SecondTail := TTailGI.Create(Space.MapPanel);
        if TailEmitIntervalMs > 0 then SecondTail.EmitIntervalMs := TailEmitIntervalMs;
        SecondTail.SetSize(Classes.Point(1000000, 1000000));
        SecondTail.SetOrigin(HalfPoint(SecondTail.ClientSize));
        SecondTail.SetDepthByName('Tail');
        SecondTail.SetPositionModeW(True);
        SecondTail.SetImagePath('Bm.Tail.00');
        SecondTail.SetEmitting(Alpha = 255);
      end;
    end;
    StartAnimationTimer;
    StartStateTimer;
  end;
end;
{ @end $609344 }

{ @routine $6098E8 TShip2SE_DetachFromSpace }
procedure TShip2SE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    StopStateTimer;
    StopAnimationTimer;
    CurrentAnimation := nil;
    NextAnimation := nil;
    Image.SetActive(False);
    Image.Free;
    Image := nil;
    MinimapImage.Free;
    MinimapImage := nil;
    if FirstTail <> nil then
    begin
      FirstTail.Free;
      FirstTail := nil;
    end;
    if SecondTail <> nil then
    begin
      SecondTail.Free;
      SecondTail := nil;
    end;
    if Mesh <> nil then
    begin
      ab_Obj3D_Delete(Mesh as TabObj3D);
      Mesh := nil;
    end;
    inherited DetachFromSpace;
  end;
end;
{ @end $6098E8 }

{ @routine $6099A8 TShip2SE_SetTailsActive }
procedure TShip2SE.SetTailsActive(Value: Boolean);
begin
  TailsActive := Value;
  if FirstTail <> nil then FirstTail.SetActive(Value);
  if SecondTail <> nil then SecondTail.SetActive(Value);
end;
{ @end $6099A8 }

{ @routine $6099DC TShip2SE_SetSize }
procedure TShip2SE.SetSize(Value: TPoint);
begin
  if (Size.X <> Value.X) or (Size.Y <> Value.Y) then
  begin
    inherited SetSize(Value);
    ImageScale.X := Size.X / ImageSize.X;
    ImageScale.Y := Size.Y / ImageSize.Y;
  end;
end;
{ @end $6099DC }

{ @routine $609A24 TShip2SE_SetPosition }
procedure TShip2SE.SetPosition(APosition: TPointF);
var
  PixelPosition: TPoint;
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    PixelPosition := Classes.Point(Trunc(APosition.X), Trunc(APosition.Y));
    Image.SetPosition(PixelPosition);
    MinimapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
    if FirstTail <> nil then FirstTail.EmitterPosition := ImagePointToWorld(FirstTailOrigin);
    if SecondTail <> nil then SecondTail.EmitterPosition := ImagePointToWorld(SecondTailOrigin);
  end;
end;
{ @end $609A24 }

{ @routine $609B2C TShip2SE_SetDepth }
procedure TShip2SE.SetDepth(Value: Single);
begin
  Image.SetDepth(Value);
end;
{ @end $609B2C }

{ @routine $609B48 TShip2SE_GetDepth }
function TShip2SE.GetDepth: Single;
begin
  Result := Image.Depth;
end;
{ @end $609B48 }

{ @routine $609B5C TShip2SE_GetAngle }
function TShip2SE.GetAngle: Byte;
begin
  Result := Angle;
end;
{ @end $609B5C }

{ @routine $609B60 TShip2SE_SetAngle }
procedure TShip2SE.SetAngle(Value: Byte);
var Velocity: TPointF;
begin
  Angle := Value;
  if IsAttachedToSpace then
  begin
    Image.SetAngle(Angle);
    if (FirstTail <> nil) or (SecondTail <> nil) then
    begin
      Velocity.X := 0;
      Velocity.Y := 0;
      if FirstTail <> nil then
      begin
        FirstTail.EmitterPosition := ImagePointToWorld(FirstTailOrigin);
        FirstTail.SegmentVelocity := Velocity;
      end;
      if SecondTail <> nil then
      begin
        SecondTail.EmitterPosition := ImagePointToWorld(SecondTailOrigin);
        SecondTail.SegmentVelocity := Velocity;
      end;
    end;
  end;
end;
{ @end $609B60 }

{ @routine $609C38 TShip2SE_OffsetTailsAlongHeading }
procedure TShip2SE.OffsetTailsAlongHeading(Distance: Single);
var
  Radians: Single;
  Delta: TPointF;
begin
  if IsAttachedToSpace and ((FirstTail <> nil) or (SecondTail <> nil)) then
  begin
    Radians := GetAngle / 256 * (2 * Pi) + Pi;
    Delta.X := Sin(Radians) * Distance;
    Delta.Y := Cos(Radians) * -Distance;
    if FirstTail <> nil then FirstTail.OffsetSegments(Delta);
    if SecondTail <> nil then SecondTail.OffsetSegments(Delta);
  end;
end;
{ @end $609C38 }

{ @routine $609CF8 TShip2SE_OffsetTails }
procedure TShip2SE.OffsetTails(Delta: TPointF);
begin
  if FirstTail <> nil then FirstTail.OffsetSegments(Delta);
  if SecondTail <> nil then SecondTail.OffsetSegments(Delta);
end;
{ @end $609CF8 }

{ @routine $609D30 TShip2SE_SetTailsEmitting }
procedure TShip2SE.SetTailsEmitting(Value: Boolean);
begin
  if FirstTail <> nil then FirstTail.SetEmitting(Value);
  if SecondTail <> nil then SecondTail.SetEmitting(Value);
end;
{ @end $609D30 }

{ @routine $609D5C TShip2SE_GetAlpha }
function TShip2SE.GetAlpha: Byte;
begin
  Result := Alpha;
end;
{ @end $609D5C }

{ @routine $609D60 TShip2SE_SetAlpha }
procedure TShip2SE.SetAlpha(Value: Byte);
begin
  Alpha := Value;
  if IsAttachedToSpace then
  begin
    Image.SetAlpha(Alpha);
    if FirstTail <> nil then FirstTail.SetEmitting(Alpha = 255);
    if SecondTail <> nil then SecondTail.SetEmitting(Alpha = 255);
  end;
end;
{ @end $609D60 }

{ @routine $609DB0 TShip2SE_GetOrbitCenter }
function TShip2SE.GetOrbitCenter: TPointF;
begin
  Result.X := ImageOrigin.X * ImageScale.X;
  Result.Y := ImageOrigin.Y * ImageScale.Y;
end;
{ @end $609DB0 }

{ @routine $609DC4 TShip2SE_ScaleImagePoint }
function TShip2SE.ScaleImagePoint(Point: TPointF): TPointF;
begin
  Result.X := (Point.X - ImageOrigin.X) * ImageScale.X;
  Result.Y := (Point.Y - ImageOrigin.Y) * ImageScale.Y;
end;
{ @end $609DC4 }

{ @routine $609DF0 TShip2SE_ImagePointToWorld }
function TShip2SE.ImagePointToWorld(Point: TPointF): TPointF;
var
  Radians, Sine, Cosine: Double;
begin
  Point := ScaleImagePoint(Point);
  Radians := Angle / 256 * 6.2831852;
  Sine := Sin(Radians);
  Cosine := Cos(Radians);
  Result.X := Point.X * Cosine - Point.Y * Sine + Position.X;
  Result.Y := Point.X * Sine + Point.Y * Cosine + Position.Y;
end;
{ @end $609DF0 }

{ @routine $609EA0 TShip2SE_GetTargetPoint }
function TShip2SE.GetTargetPoint(Heading: Byte; Seed: Integer): TPointF;
var
  Radians, Sine, Cosine: Double;
  Point: TPointF;
begin
  Point := ScaleImagePoint(MakePointF(Seed mod Round(Size.X * 0.9), (Seed * 45452 + 3247) mod Round(Size.Y * 0.9)));
  Point.X := Point.X * 0.3;
  Point.Y := Point.Y * 0.3;
  Radians := Heading / 256 * 6.2831852;
  Sine := Sin(Radians);
  Cosine := Cos(Radians);
  Result.X := Point.X * Cosine - Point.Y * Sine + Position.X;
  Result.Y := Point.X * Sine + Point.Y * Cosine + Position.Y;
end;
{ @end $609EA0 }

{ @routine $609FD0 TShip2SE_HitTestCursor }
function TShip2SE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then Result := False
  else Result := Image.HitTestPixel(Image.MessageLoop.GetCursorPoint);
end;
{ @end $609FD0 }

{ @routine $60A004 TShip2SE_AddAnimation }
function TShip2SE.AddAnimation: TShip2AnimSE;
var
  Animation: TShip2AnimSE;
begin
  Animation := TShip2AnimSE.Create;
  if LastAnimation <> nil then LastAnimation.Next := Animation;
  Animation.Prev := LastAnimation;
  Animation.Next := nil;
  LastAnimation := Animation;
  if FirstAnimation = nil then FirstAnimation := Animation;
  Result := Animation;
end;
{ @end $60A004 }

{ @routine $60A048 TShip2SE_DeleteAnimation }
procedure TShip2SE.DeleteAnimation(Animation: TShip2AnimSE);
begin
  if Animation.Prev <> nil then Animation.Prev.Next := Animation.Next;
  if Animation.Next <> nil then Animation.Next.Prev := Animation.Prev;
  if LastAnimation = Animation then LastAnimation := Animation.Prev;
  if FirstAnimation = Animation then FirstAnimation := Animation.Next;
  Animation.Free;
end;
{ @end $60A048 }

{ @routine $60A090 TShip2SE_AddReducedAnimation }
function TShip2SE.AddReducedAnimation: TShip2AnimSE;
var
  Animation: TShip2AnimSE;
begin
  Animation := TShip2AnimSE.Create;
  if LastReducedAnimation <> nil then LastReducedAnimation.Next := Animation;
  Animation.Prev := LastReducedAnimation;
  Animation.Next := nil;
  LastReducedAnimation := Animation;
  if FirstReducedAnimation = nil then FirstReducedAnimation := Animation;
  Result := Animation;
end;
{ @end $60A090 }

{ @routine $60A0D4 TShip2SE_DeleteReducedAnimation }
procedure TShip2SE.DeleteReducedAnimation(Animation: TShip2AnimSE);
begin
  if Animation.Prev <> nil then Animation.Prev.Next := Animation.Next;
  if Animation.Next <> nil then Animation.Next.Prev := Animation.Prev;
  if LastReducedAnimation = Animation then LastReducedAnimation := Animation.Prev;
  if FirstReducedAnimation = Animation then FirstReducedAnimation := Animation.Next;
  Animation.Free;
end;
{ @end $60A0D4 }

{ @routine $60A11C TShip2SE_StartAnimationTimer }
procedure TShip2SE.StartAnimationTimer;
var
  Delay: Integer;
begin
  StopAnimationTimer;
  Delay := ReadIntegerEC(AddPointerOffset(CurrentAnimation.Delays, CurrentFrameIndex * 4));
  AnimationTimer := Space.Screen.ScheduleCallbackTimer(Delay, Delay, AdvanceAnimation);
end;
{ @end $60A11C }

{ @routine $60A16C TShip2SE_StopAnimationTimer }
procedure TShip2SE.StopAnimationTimer;
begin
  if AnimationTimer <> 0 then
  begin
    Space.Screen.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
end;
{ @end $60A16C }

{ @routine $60A190 TShip2SE_StartStateTimer }
procedure TShip2SE.StartStateTimer;
begin
  StopStateTimer;
  StateTimer := Space.Screen.ScheduleCallbackTimer(StateIntervalMs, StateIntervalMs, SelectNextAnimation);
end;
{ @end $60A190 }

{ @routine $60A1C0 TShip2SE_StopStateTimer }
procedure TShip2SE.StopStateTimer;
begin
  if StateTimer <> 0 then
  begin
    Space.Screen.CancelCallbackTimer(StateTimer);
    StateTimer := 0;
  end;
end;
{ @end $60A1C0 }

{ @routine $60A1E4 TShip2SE_AdvanceAnimation }
procedure TShip2SE.AdvanceAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(CurrentFrameIndex);
  if CurrentAnimation.FrameCount > CurrentFrameIndex then
  begin
    Image.SetFrameIndex(ReadIntegerEC(AddPointerOffset(CurrentAnimation.Frames, CurrentFrameIndex * 4)));
    StartAnimationTimer;
    Exit;
  end;
  CurrentFrameIndex := 0;
  if AnimShipFull then
  begin
    if CurrentAnimation = LastAnimation then CurrentAnimation := FirstAnimation
    else CurrentAnimation := NextAnimation;
    NextAnimation := FirstAnimation;
  end
  else
  begin
    if CurrentAnimation = LastReducedAnimation then CurrentAnimation := FirstReducedAnimation
    else CurrentAnimation := NextAnimation;
    NextAnimation := FirstReducedAnimation;
  end;
  Image.SetFrameIndex(ReadIntegerEC(AddPointerOffset(CurrentAnimation.Frames, CurrentFrameIndex * 4)));
  StartAnimationTimer;
end;
{ @end $60A1E4 }

{ @routine $60A2EC TShip2SE_SelectNextAnimation }
procedure TShip2SE.SelectNextAnimation(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var
  Weight: Integer;
  Animation: TShip2AnimSE;
begin
  if AnimShipFull then
  begin
    if NextAnimation = LastAnimation then Exit;
    Weight := Random(TotalAnimationWeight);
    Animation := FirstAnimation;
    while Animation <> nil do
    begin
      if Weight < Animation.Weight then
      begin
        NextAnimation := Animation;
        Exit;
      end;
      Dec(Weight, Animation.Weight);
      Animation := Animation.Next;
    end;
  end
  else
  begin
    if NextAnimation = LastReducedAnimation then Exit;
    Weight := Random(TotalReducedAnimationWeight);
    Animation := FirstReducedAnimation;
    while Animation <> nil do
    begin
      if Weight < Animation.Weight then
      begin
        NextAnimation := Animation;
        Exit;
      end;
      Dec(Weight, Animation.Weight);
      Animation := Animation.Next;
    end;
  end;
end;
{ @end $60A2EC }

{ @routine $60A378 TShip2SE_DrawMap }
procedure TShip2SE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if (PointDistanceSquared(Position, CurrentProcess.RadarCenter) < Sqr(CurrentProcess.RadarRange)) or
     ((Player <> nil) and (Player.Graphic = Self)) then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $60A378 }

{ @routine $60A404 TShip2SE_Draw3D }
procedure TShip2SE.Draw3D;
var
  SinAngle, CosAngle: Single;
  Pixels: Pointer;
  Palette: PColorRGBA;
  Corner0, Corner1, Corner2, Corner3: record X, Y, Z: Single; end;
  Object3D: TabObj3D;
begin
  if Mesh <> nil then
  begin
    Object3D := Mesh as TabObj3D;
    // Uploads only while the saved index is negative, even after a frame change.
    if (Image.FrameIndex <> Cardinal(UploadedFrameIndex)) and (UploadedFrameIndex < 0) then
    begin
      UploadedFrameIndex := Image.FrameIndex;
      Object3D.LastBatch.Texture.Lock;
      Image.AcquireRenderedFrame(Pixels, Palette);
      OKGR_PalCopySwap_XY_XY_DWORD(Object3D.LastBatch.Texture.Pixels,
        Object3D.LastBatch.Texture.PitchBytes, 0, 0, Pixels, 128, 0, 0, Palette, 128, 128);
      Image.ReleaseRenderedFrame;
      Object3D.LastBatch.Texture.Unlock;
    end;
    Corner0.X := -Size.X / 2;
    Corner0.Y := -Size.Y / 2;
    Corner0.Z := 0;
    Corner1.X := Size.X / 2;
    Corner1.Y := -Size.Y / 2;
    Corner1.Z := 0;
    Corner2.X := Size.X / 2;
    Corner2.Y := Size.Y / 2;
    Corner2.Z := 0;
    Corner3.X := -Size.X / 2;
    Corner3.Y := Size.Y / 2;
    Corner3.Z := 0;
    SinAngle := Sin(-Integer(Angle) * 2 * Pi / 256);
    CosAngle := Cos(2 * -Integer(Angle) * Pi / 256);
    Object3D.LockVertices;
    Object3D.GetVertex(0)^ := MakeArcadeVertex3D((Alpha shl 24) or $FFFFFF,
      CosAngle * Corner0.X + SinAngle * Corner0.Y + Position.X + Cardinal(GameScreenWidth) / 2,
      -SinAngle * Corner0.X + CosAngle * Corner0.Y + Position.Y + Cardinal(GameScreenHeight) / 2,
      Corner0.Z, 0, 0);
    Object3D.GetVertex(1)^ := MakeArcadeVertex3D((Alpha shl 24) or $FFFFFF,
      CosAngle * Corner1.X + SinAngle * Corner1.Y + Position.X + Cardinal(GameScreenWidth) / 2,
      -SinAngle * Corner1.X + CosAngle * Corner1.Y + Position.Y + Cardinal(GameScreenHeight) / 2,
      Corner1.Z, 1, 0);
    Object3D.GetVertex(2)^ := MakeArcadeVertex3D((Alpha shl 24) or $FFFFFF,
      CosAngle * Corner2.X + SinAngle * Corner2.Y + Position.X + Cardinal(GameScreenWidth) / 2,
      -SinAngle * Corner2.X + CosAngle * Corner2.Y + Position.Y + Cardinal(GameScreenHeight) / 2,
      Corner2.Z, 1, 1);
    Object3D.GetVertex(3)^ := MakeArcadeVertex3D((Alpha shl 24) or $FFFFFF,
      CosAngle * Corner3.X + SinAngle * Corner3.Y + Position.X + Cardinal(GameScreenWidth) / 2,
      -SinAngle * Corner3.X + CosAngle * Corner3.Y + Position.Y + Cardinal(GameScreenHeight) / 2,
      Corner3.Z, 0, 1);
    Object3D.UnlockVertices;
    Object3D.Draw;
  end;
end;
{ @end $60A404 }

{ @routine $60A8B0 TShip2SE_LoadTemplate }
procedure TShip2SE.LoadTemplate(Block: TBlockParEC);
var
  AnimBlock: TBlockParEC;
  Index: Integer;
  Animation, ReducedAnimation: TShip2AnimSE;
begin
  inherited LoadTemplate(Block);
  SharedAnimations := False;
  SetAngle(0);
  SetAlpha(255);
  ImagePath := Block.GetParam('Image');
  ReducedImagePath := Block.GetParam('ImageS');
  MinimapImagePath := Block.GetParam('ImageMap');
  ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
  MinimapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
  ImageSize := GetPointGI(Block.GetParam('SizeImage'));
  ImageCenter := PointToPointF(GetPointGI(Block.GetParam('SmeCenterImage')));
  FirstTailOrigin := MakePointF(0, 0);
  SecondTailOrigin := MakePointF(0, 0);
  if Block.CountParams('Tail1') > 0 then FirstTailOrigin := PointToPointF(GetPointGI(Block.GetParam('Tail1')));
  if Block.CountParams('Tail2') > 0 then SecondTailOrigin := PointToPointF(GetPointGI(Block.GetParam('Tail2')));
  StateIntervalMs := StrToInt(Block.GetParam('StateTime'));
  AnimBlock := Block.GetBlock('Anim');
  with AddAnimation do
  begin
    Load(AnimBlock.GetParam('Normal'));
    TotalAnimationWeight := Weight;
  end;
  Index := 0;
  while AnimBlock.CountParams(IntToStr(Index)) > 0 do
  begin
    Animation := AddAnimation;
    Animation.Load(AnimBlock.GetParam(IntToStr(Index)));
    Inc(TotalAnimationWeight, Animation.Weight);
    Inc(Index);
  end;
  AnimBlock := Block.GetBlock('AnimS');
  with AddReducedAnimation do
  begin
    Load(AnimBlock.GetParam('Normal'));
    TotalReducedAnimationWeight := Weight;
  end;
  Index := 0;
  while AnimBlock.CountParams(IntToStr(Index)) > 0 do
  begin
    ReducedAnimation := AddReducedAnimation;
    ReducedAnimation.Load(AnimBlock.GetParam(IntToStr(Index)));
    Inc(TotalReducedAnimationWeight, ReducedAnimation.Weight);
    Inc(Index);
  end;
  SetSize(Classes.Point(64, 64));
end;
{ @end $60A8B0 }

{ @routine $60AE00 TShip2SE_ApplyConfig }
procedure TShip2SE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('Angle') > 0 then SetAngle(StrToInt(Block.GetParam('Angle')));
end;
{ @end $60AE00 }

{ @routine $60AE9C TShip2SE_QueueImageLoad }
procedure TShip2SE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  MainImage: TRotateImage5GI;
  MapImage: TAlphaImageGI;
begin
  MainImage := TRotateImage5GI.Create(Owner);
  if AnimShipFull then MainImage.QueueImagePath(PendingLoads, ImagePath)
  else MainImage.QueueImagePath(PendingLoads, ReducedImagePath);
  MainImage.Free;
  MapImage := TAlphaImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;
{ @end $60AE9C }

end.

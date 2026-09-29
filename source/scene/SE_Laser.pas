unit SE_Laser;
// Unit bracket (inferred): CODE 0x004CDAF4..0x004CE3AF; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Str, EC_Struct, GI_MessageLoop, GI_RotateImage2, SE_Space, Types;

type
  TLaserSE = class(TObjectSE) // @size $74
  public
    FrameImages: TStringsEC; // @offset $48
    FrameInterval: Cardinal; // @offset $4C
    TargetPosition: TPointF; // @offset $50
    SegmentSize: Integer; // @offset $58 Template RadiusUnit; used as sprite dimensions and beam spacing.
    Segments: TList; // @offset $5C Owned rotated image controls while attached.
    FrameIndex: Integer; // @offset $60
    AnimationTimer: TCallbackTimerIdGI; // @offset $64
    ManualAnimation: Boolean; // @offset $68
    EndPosition: TPointF; // @offset $6C Rebuilt endpoint after the final segment.
    destructor Destroy; override; // @addr $4CDBA8
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $4CDBE0
    procedure DetachFromSpace; override; // @addr $4CDC04
    procedure SetPosition(APosition: TPointF); override; // @addr $4CDC24
    procedure RebuildSegments; // @addr $4CDC54
    procedure ClearSegments; // @addr $4CDE9C
    procedure UpdateSegmentImages; // @addr $4CDEF0
    procedure StartAnimationTimer; // @addr $4CDFC0
    procedure StopAnimationTimer; // @addr $4CDFF4
    procedure AdvanceAnimationTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4CE014
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $4CE040
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $4CE1BC
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $4CE2AC
  end;

implementation

// @unit-initialization $4CE3A8
// @unit-finalization $4CE378

uses SysUtils, Math, GI_Main;
{ @routine $4CDBA8 TLaserSE_Destroy }
destructor TLaserSE.Destroy;
begin
  if FrameImages <> nil then
  begin
    FrameImages.Free;
    FrameImages := nil;
  end;
  inherited Destroy;
end;
{ @end $4CDBA8 }

{ @routine $4CDBE0 TLaserSE_AttachToSpace }
procedure TLaserSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    inherited AttachToSpace(ASpace);
    RebuildSegments;
  end;
end;
{ @end $4CDBE0 }

{ @routine $4CDC04 TLaserSE_DetachFromSpace }
procedure TLaserSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    ClearSegments;
    inherited DetachFromSpace;
  end;
end;
{ @end $4CDC04 }

{ @routine $4CDC24 TLaserSE_SetPosition }
procedure TLaserSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then RebuildSegments;
end;
{ @end $4CDC24 }

{ @routine $4CDC54 TLaserSE_RebuildSegments }
procedure TLaserSE.RebuildSegments;
var
  Segment: TRotateImage2GI;
  Angle, AngleSin, AngleCos, Distance, BeamLength: Double;
  ImageAngle: Integer;
begin
  ClearSegments;
  Angle := ArcTan2(TargetPosition.X - Position.X, -(TargetPosition.Y - Position.Y));
  AngleSin := Sin(Angle);
  AngleCos := Cos(Angle);
  ImageAngle := Round(Angle / 3.1415926 * 127) and $FF;
  Distance := SegmentSize / 2;
  BeamLength := Sqrt(Sqr(TargetPosition.X - Position.X) + Sqr(TargetPosition.Y - Position.Y));
  Segments := TList.Create;
  Segment := nil;
  while Distance < BeamLength do
  begin
    Segment := TRotateImage2GI.Create(Space.MapPanel);
    Segment.SetPositionModeW(True);
    Segment.SetDepthByName(DepthExpression);
    EndPosition := MakePointF(AngleSin * Distance + Position.X, Position.Y - AngleCos * Distance);
    Segment.SetPosition(TruncatePointF(EndPosition));
    Segment.SetAngle(ImageAngle);
    Segment.SetAlpha(192);
    Segment.SetImage(FrameImages.GetTextAt(0), Classes.Point(SegmentSize, SegmentSize), Classes.Point(SegmentSize div 2, SegmentSize div 2));
    Segments.Add(Segment);
    Distance := Distance + SegmentSize - 4;
  end;
  if Segment <> nil then begin end;
  EndPosition := MakePointF(SegmentSize / 2 * AngleSin + EndPosition.X, EndPosition.Y - SegmentSize / 2 * AngleCos);
  FrameIndex := 0;
  UpdateSegmentImages;
  StartAnimationTimer;
end;
{ @end $4CDC54 }

{ @routine $4CDE9C TLaserSE_ClearSegments }
procedure TLaserSE.ClearSegments;
var
  Index: Integer;
  Segment: TObjectGI;
begin
  StopAnimationTimer;
  if Segments <> nil then
  begin
    for Index := 0 to Segments.Count - 1 do
    begin
      Segment := Segments[Index];
      Segment.SetActive(False);
      Space.MapPanel.FreeOwnedChild(Segment);
    end;
    Segments.Free;
    { The native routine leaves the freed list pointer unchanged. }
  end;
end;
{ @end $4CDE9C }

{ @routine $4CDEF0 TLaserSE_UpdateSegmentImages }
procedure TLaserSE.UpdateSegmentImages;
var
  Index: Integer;
  Segment: TRotateImage2GI;
begin
  if (Segments <> nil) and (FrameIndex >= 0) and (FrameImages <> nil) and (FrameIndex < FrameImages.GetCount) then
    for Index := 0 to Segments.Count - 1 do
    begin
      Segment := Segments[Index];
      Segment.SetImage(FrameImages.GetTextAt(FrameIndex), Classes.Point(SegmentSize, SegmentSize), Classes.Point(SegmentSize div 2, SegmentSize div 2));
    end;
end;
{ @end $4CDEF0 }

{ @routine $4CDFC0 TLaserSE_StartAnimationTimer }
procedure TLaserSE.StartAnimationTimer;
begin
  StopAnimationTimer;
  if not ManualAnimation then
    AnimationTimer := Space.Screen.ScheduleCallbackTimer(FrameInterval, FrameInterval, AdvanceAnimationTimer);
end;
{ @end $4CDFC0 }

{ @routine $4CDFF4 TLaserSE_StopAnimationTimer }
procedure TLaserSE.StopAnimationTimer;
begin
  if AnimationTimer <> 0 then
  begin
    Space.Screen.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
end;
{ @end $4CDFF4 }

{ @routine $4CE014 TLaserSE_AdvanceAnimationTimer }
procedure TLaserSE.AdvanceAnimationTimer(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(FrameIndex);
  if FrameIndex < FrameImages.GetCount then UpdateSegmentImages
  else
  begin
    FrameIndex := 0;
    UpdateSegmentImages;
  end;
end;
{ @end $4CE014 }

{ @routine $4CE040 TLaserSE_LoadTemplate }
procedure TLaserSE.LoadTemplate(Block: TBlockParEC);
var
  Index: Integer;
begin
  inherited LoadTemplate(Block);
  if FrameImages <> nil then
  begin
    FrameImages.Free;
    FrameImages := nil;
  end;
  FrameImages := TStringsEC.Create;
  FrameInterval := SysUtils.StrToInt(AnsiString(Block.GetParam('Time')));
  Index := 0;
  while Block.CountParams(IntToStr(Index)) > 0 do
  begin
    FrameImages.Add(TrimWideString(Block.GetParam(IntToStr(Index))));
    Inc(Index);
  end;
  SegmentSize := SysUtils.StrToInt(AnsiString(Block.GetParam('RadiusUnit')));
end;
{ @end $4CE040 }

{ @routine $4CE1BC TLaserSE_ApplyConfig }
procedure TLaserSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('PosDes') > 0 then TargetPosition := PointToPointF(GetPointGI(Block.GetParam('PosDes')));
  if Block.CountParams('ManualAnim') > 0 then ManualAnimation := ParseEnabledNameGI(Block.GetParam('ManualAnim'));
end;
{ @end $4CE1BC }

{ @routine $4CE2AC TLaserSE_QueueImageLoad }
procedure TLaserSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Index, Count: Integer;
  Segment: TRotateImage2GI;
begin
  Segment := TRotateImage2GI.Create(Owner);
  Count := FrameImages.GetCount;
  for Index := 0 to Count - 1 do
  begin
    Segment.SetImage(FrameImages.GetTextAt(Index), Classes.Point(SegmentSize, SegmentSize), Classes.Point(SegmentSize div 2, SegmentSize div 2));
    Segment.QueueImageLoad(PendingLoads);
  end;
  Segment.Free;
end;
{ @end $4CE2AC }

end.

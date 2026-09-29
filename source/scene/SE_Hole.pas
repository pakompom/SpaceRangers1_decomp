unit SE_Hole;
// Unit bracket (inferred): CODE 0x005FF9FC..0x006000E7; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_GAI, GI_Image, GI_MessageLoop, SE_Space, Types;

type
  THoleSE = class(TObjectSE) // @size $64
  public
    ImagePath: WideString; // @offset $48 Animation resource used by star-map information thumbnails.
    OpenImagePath: WideString; // @offset $4C
    MapImagePath: WideString; // @offset $50
    Animation: TgaiGI; // @offset $54
    MapImage: TImageGI; // @offset $58
    SavedSequenceFrameIndex: Integer; // @offset $5C
    State: Integer; // @offset $60
    procedure AnimationComplete(Sender: TObjectGI); // @addr $5FFEE8
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $5FFAD0
    procedure DetachFromSpace; override; // @addr $5FFC8C
    procedure SetPosition(APosition: TPointF); override; // @addr $5FFCF8
    procedure DrawMap; override; // @addr $5FFD7C
    function HitTestCursor: Boolean; override; // @addr $5FFDEC
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $5FFE08
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $5FFEE0
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $600020
    procedure SetState(Value: Integer); // @addr $5FFCD4 Preserves state 1 when asked to reset an attached effect to state 0.
  end;

implementation

// @unit-initialization $6000E0
// @unit-finalization $6000B0

uses Globals, GR_Main, GI_Main, EC_Str, SE_Process;

{ @routine $5FFAD0 THoleSE_AttachToSpace }
procedure THoleSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  ConfigureLoopSound('Hole');
  ConfigureRandomSound('Hole');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  if State = 1 then Animation.SetImagePath(OpenImagePath)
  else Animation.SetImagePath(ImagePath);
  Animation.CycleCompleteCallback := AnimationComplete;
  Animation.SetSize(Animation.GetContentSize);
  Animation.SetOrigin(HalfPoint(Animation.ClientSize));
  Animation.SetDepthByName(DepthExpression);
  Animation.SetPosition(TruncatePointF(Position));
  Animation.SetPositionModeW(True);
  Animation.SequenceIndex := 0;
  Animation.UpdateAutoGeometry;
  Animation.SetSequenceFrame(SavedSequenceFrameIndex);
  Animation.RestartPlayback;
  MapImage := TImageGI.Create(SpaceObjectUiLoop.ContentPanel);
  MapImage.SetPositionModeW(True);
  MapImage.SetDepthByName(DepthExpression);
  MapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
  MapImage.SetImagePath(MapImagePath);
  MapImage.SetSize(MapImage.GetContentSize);
  MapImage.SetOrigin(HalfPoint(MapImage.GetContentSize));
end;
{ @end $5FFAD0 }

{ @routine $5FFC8C THoleSE_DetachFromSpace }
procedure THoleSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  if Animation <> nil then
  begin
    SavedSequenceFrameIndex := Animation.SequenceFrame;
    Animation.Free;
    Animation := nil;
  end;
  if MapImage <> nil then
  begin
    MapImage.Free;
    MapImage := nil;
  end;
  inherited DetachFromSpace;
end;
{ @end $5FFC8C }

{ @routine $5FFCD4 THoleSE_SetState }
procedure THoleSE.SetState(Value: Integer);
begin
  if (State = 1) and (Value = 0) and IsAttachedToSpace then Exit;
  State := Value;
end;
{ @end $5FFCD4 }

{ @routine $5FFCF8 THoleSE_SetPosition }
procedure THoleSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    Animation.SetPosition(TruncatePointF(APosition));
    MapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
  end;
end;
{ @end $5FFCF8 }

{ @routine $5FFD7C THoleSE_DrawMap }
procedure THoleSE.DrawMap;
begin
  with Space.Process as TProcessSE do
    if PointDistanceSquared(Self.Position, RadarCenter) < Sqr(RadarRange) then
      MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $5FFD7C }

{ @routine $5FFDEC THoleSE_HitTestCursor }
function THoleSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then Result := False
  else Result := Animation.HitTestCursor;
end;
{ @end $5FFDEC }

{ @routine $5FFE08 THoleSE_LoadTemplate }
procedure THoleSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  OpenImagePath := Block.GetParam('ImageO');
  MapImagePath := Block.GetParam('ImageMap');
end;
{ @end $5FFE08 }

{ @routine $5FFEE0 THoleSE_ApplyConfig }
procedure THoleSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $5FFEE0 }

{ @routine $5FFEE8 THoleSE_AnimationComplete }
procedure THoleSE.AnimationComplete(Sender: TObjectGI);
begin
  if State = 1 then
  begin
    Animation.SetImagePath(ImagePath);
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetSequenceFrame(0);
    Animation.RestartPlayback;
  end
  else if State = 2 then
  begin
    if Animation.GetImagePath = OpenImagePath then DetachFromSpace
    else
    begin
      Animation.SetImagePath(OpenImagePath);
      Animation.SetSize(Animation.GetContentSize);
      Animation.SetOrigin(HalfPoint(Animation.ClientSize));
      Animation.SequenceIndex := 1;
      Animation.UpdateAutoGeometry;
      Animation.SetSequenceFrame(0);
      Animation.RestartPlayback;
    end;
  end;
end;
{ @end $5FFEE8 }

{ @routine $600020 THoleSE_QueueImageLoad }
procedure THoleSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  with TgaiGI.Create(Owner) do
  begin
    SetImagePath(Self.ImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
  with TgaiGI.Create(Owner) do
  begin
    SetImagePath(Self.OpenImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
  with TImageGI.Create(Owner) do
  begin
    SetImagePath(MapImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;
{ @end $600020 }

end.

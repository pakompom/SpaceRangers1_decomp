unit SE_Asteroid;
// Unit bracket (inferred): CODE 0x005C97EC..0x005C9D23; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_GAI, GI_Image, GI_MessageLoop, SE_Space;

type
  TAsteroidSE = class(TObjectSE) // @size $5C
  public
    ImagePath: WideString; // @offset $48
    MapImagePath: WideString; // @offset $4C
    Animation: TgaiGI; // @offset $50
    MapImage: TImageGI; // @offset $54
    SavedSequenceFrameIndex: Integer; // @offset $58

    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $5C98BC
    procedure DetachFromSpace; override; // @addr $5C9A58
    procedure SetPosition(APosition: TPointF); override; // @addr $5C9AA0
    function GetSequenceFrameIndex: Integer; // @addr $5C9B24
    procedure SetSequenceFrameIndex(FrameIndex: Integer); // @addr $5C9B38
    function HitTestCursor: Boolean; override; // @addr $5C9BBC
    procedure DrawMap; override; // @addr $5C9B4C @note "Requires an attached space."
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $5C9BD8
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $5C9C80
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $5C9C88
  end;

implementation

// @unit-initialization $5C9D1C
// @unit-finalization $5C9CEC

uses Globals, GR_Main, GI_Main, SE_Process;
{ @routine $5C98BC TAsteroidSE_AttachToSpace }
procedure TAsteroidSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  ConfigureLoopSound('Comet');
  ConfigureRandomSound('Comet');
  inherited AttachToSpace(ASpace);
  Animation := TgaiGI.Create(Space.MapPanel);
  Animation.SetImagePath(ImagePath);
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
{ @end $5C98BC }

{ @routine $5C9A58 TAsteroidSE_DetachFromSpace }
procedure TAsteroidSE.DetachFromSpace;
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
{ @end $5C9A58 }

{ @routine $5C9AA0 TAsteroidSE_SetPosition }
procedure TAsteroidSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    Animation.SetPosition(TruncatePointF(APosition));
    MapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
  end;
end;
{ @end $5C9AA0 }

{ @routine $5C9B24 TAsteroidSE_GetSequenceFrameIndex }
function TAsteroidSE.GetSequenceFrameIndex: Integer;
begin
  if Animation = nil then Result := SavedSequenceFrameIndex
  else Result := Animation.SequenceFrame;
end;
{ @end $5C9B24 }

{ @routine $5C9B38 TAsteroidSE_SetSequenceFrameIndex }
procedure TAsteroidSE.SetSequenceFrameIndex(FrameIndex: Integer);
begin
  SavedSequenceFrameIndex := FrameIndex;
  if Animation <> nil then Animation.SetSequenceFrame(FrameIndex);
end;
{ @end $5C9B38 }

{ @routine $5C9B4C TAsteroidSE_DrawMap }
procedure TAsteroidSE.DrawMap;
begin
  with Space.Process as TProcessSE do
    if PointDistanceSquared(Self.Position, RadarCenter) < Sqr(RadarRange) then
      MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $5C9B4C }

{ @routine $5C9BBC TAsteroidSE_HitTestCursor }
function TAsteroidSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then Result := False
  else Result := Animation.HitTestCursor;
end;
{ @end $5C9BBC }

{ @routine $5C9BD8 TAsteroidSE_LoadTemplate }
procedure TAsteroidSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  MapImagePath := Block.GetParam('ImageMap');
end;
{ @end $5C9BD8 }

{ @routine $5C9C80 TAsteroidSE_ApplyConfig }
procedure TAsteroidSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $5C9C80 }

{ @routine $5C9C88 TAsteroidSE_QueueImageLoad }
procedure TAsteroidSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  with TgaiGI.Create(Owner) do
  begin
    SetImagePath(Self.ImagePath);
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
{ @end $5C9C88 }

end.

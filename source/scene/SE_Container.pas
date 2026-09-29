unit SE_Container;
// Unit bracket (inferred): CODE 0x0060AF4C..0x0060B4C3; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_AlphaImage, GI_GAI, GI_MessageLoop, SE_Space, Types;

type
  TContainerSE = class(TObjectSE) // @size $58
  public
    ImagePath: WideString; // @offset $48
    MinimapImagePath: WideString; // @offset $4C
    Animation: TgaiGI; // @offset $50
    MinimapImage: TAlphaImageGI; // @offset $54
    procedure CopyTo(Destination: TObjectSE); override; // @addr $60B01C
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $60B064
    procedure DetachFromSpace; override; // @addr $60B1F0
    procedure SetPosition(APosition: TPointF); override; // @addr $60B22C
    procedure SetDepth(Value: Single); override; // @addr $60B2B0
    function GetDepth: Single; override; // @addr $60B2CC
    function HitTestCursor: Boolean; override; // @addr $60B2DC
    procedure DrawMap; override; // @addr $60B2F8
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $60B368
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $60B428
  end;

implementation

// @unit-initialization $60B4BC
// @unit-finalization $60B48C

uses aMyFunction, Globals, GR_Main, SE_Process;

{ @routine $60B01C TContainerSE_CopyTo }
procedure TContainerSE.CopyTo(Destination: TObjectSE);
begin
  inherited CopyTo(Destination);
  (Destination as TContainerSE).ImagePath := ImagePath;
  (Destination as TContainerSE).MinimapImagePath := MinimapImagePath;
end;
{ @end $60B01C }

{ @routine $60B064 TContainerSE_AttachToSpace }
procedure TContainerSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    ConfigureLoopSound('Container');
    ConfigureRandomSound('Container');
    inherited AttachToSpace(ASpace);
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(ImagePath);
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    { Restarts at the sequence's initial frame without drawing a random one. }
    Animation.RestartPlayback;
    MinimapImage := TAlphaImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.ClientSize));
  end;
end;
{ @end $60B064 }

{ @routine $60B1F0 TContainerSE_DetachFromSpace }
procedure TContainerSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
    begin
      Animation.Free;
      Animation := nil;
    end;
    if MinimapImage <> nil then
    begin
      MinimapImage.Free;
      MinimapImage := nil;
    end;
    inherited DetachFromSpace;
  end;
end;
{ @end $60B1F0 }

{ @routine $60B22C TContainerSE_SetPosition }
procedure TContainerSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    Animation.SetPosition(TruncatePointF(APosition));
    MinimapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
  end;
end;
{ @end $60B22C }

{ @routine $60B2B0 TContainerSE_SetDepth }
procedure TContainerSE.SetDepth(Value: Single);
begin
  Animation.SetDepth(Value);
end;
{ @end $60B2B0 }

{ @routine $60B2CC TContainerSE_GetDepth }
function TContainerSE.GetDepth: Single;
begin
  Result := Animation.Depth;
end;
{ @end $60B2CC }

{ @routine $60B2DC TContainerSE_HitTestCursor }
function TContainerSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then Result := False
  else Result := Animation.HitTestCursor;
end;
{ @end $60B2DC }

{ @routine $60B2F8 TContainerSE_DrawMap }
procedure TContainerSE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if PointDistanceSquared(Position, CurrentProcess.RadarCenter) < Sqr(CurrentProcess.RadarRange) then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $60B2F8 }

{ @routine $60B368 TContainerSE_LoadTemplate }
procedure TContainerSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam(GiResourceSuffix + 'Image');
  MinimapImagePath := Block.GetParam('ImageMap');
end;
{ @end $60B368 }

{ @routine $60B428 TContainerSE_QueueImageLoad }
procedure TContainerSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Image: TgaiGI;
  MapImage: TAlphaImageGI;
begin
  Image := TgaiGI.Create(Owner);
  Image.SetImagePath(ImagePath);
  Image.QueueImageLoad(PendingLoads);
  Image.Free;
  MapImage := TAlphaImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;
{ @end $60B428 }

end.

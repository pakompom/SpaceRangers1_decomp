unit SE_Star;
// Unit bracket (inferred): CODE 0x006000E8..0x0060083B; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_GAI, GI_Image, GI_gi, GI_MessageLoop, SE_Space, Types;

type
  TStarSE = class(TObjectSE) // @size $74 Used for the first minimap drawing pass.
  public
    AnimationPath: WideString; // @offset $48
    StaticImagePath: WideString; // @offset $4C Used by TfAB.ShowSpaceInfo for the star thumbnail.
    ImageOrigin: TPoint; // @offset $50 Loaded from SmeImage; drawing centers the control instead.
    MapImagePath: WideString; // @offset $58
    MapImageOrigin: TPoint; // @offset $5C
    StaticImage: TImageGI; // @offset $64
    Animation: TgaiGI; // @offset $68 Native Terron transformation installs its cycle callback here.
    MapImage: TgiGI; // @offset $6C
    SavedSequenceFrameIndex: Integer; // @offset $70
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $6001BC
    procedure DetachFromSpace; override; // @addr $600468
    procedure SetPosition(APosition: TPointF); override; // @addr $6004C0
    function GetSequenceFrameIndex: Integer; // @addr $600568
    procedure SetSequenceFrameIndex(FrameIndex: Integer); // @addr $60057C
    function HitTestCursor: Boolean; override; // @addr $600590
    procedure DrawMap; override; // @addr $6005C8
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $600604
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $600768
  end;

implementation

// @unit-initialization $600834
// @unit-finalization $600804

uses SysUtils, GlobalsV, Globals, GR_Main, GI_Main, EC_Str;
{ @routine $6001BC TStarSE_AttachToSpace }
procedure TStarSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  ConfigureLoopSound('Star');
  ConfigureRandomSound('Star');
  inherited AttachToSpace(ASpace);
  if not AnimStar then
  begin
    StaticImage := TImageGI.Create(Space.MapPanel);
    StaticImage.SetImagePath(StaticImagePath);
    StaticImage.SetPositionModeW(True);
    StaticImage.SetDepthByName(DepthExpression);
    StaticImage.SetPosition(TruncatePointF(Position));
    StaticImage.SetSize(StaticImage.GetContentSize);
    StaticImage.SetOrigin(HalfPoint(StaticImage.ClientSize));
  end
  else
  begin
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(AnimationPath);
    Animation.LoadFrameSequenceFromText('[65,0-' + IntToStr(Animation.GetMainImageFrameCount - 1) + ']');
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetSize(Animation.GetContentSize);
    Animation.SetOrigin(HalfPoint(Animation.ClientSize));
    Animation.SetSequenceFrame(SavedSequenceFrameIndex);
    Animation.RestartPlayback;
  end;
  MapImage := TgiGI.Create(SpaceObjectUiLoop.ContentPanel);
  MapImage.SetPositionModeW(True);
  MapImage.SetDepthByName(DepthExpression);
  MapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
  MapImage.SetOrigin(MapImageOrigin);
  MapImage.SetImagePath(MapImagePath);
  MapImage.SetSize(MapImage.GetContentSize);
end;
{ @end $6001BC }

{ @routine $600468 TStarSE_DetachFromSpace }
procedure TStarSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  if Animation <> nil then
  begin
    SavedSequenceFrameIndex := Animation.SequenceFrame;
    Animation.Free;
    Animation := nil;
  end;
  if StaticImage <> nil then
  begin
    StaticImage.Free;
    StaticImage := nil;
  end;
  if MapImage <> nil then
  begin
    MapImage.Free;
    MapImage := nil;
  end;
  inherited DetachFromSpace;
end;
{ @end $600468 }

{ @routine $6004C0 TStarSE_SetPosition }
procedure TStarSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    if StaticImage <> nil then StaticImage.SetPosition(TruncatePointF(APosition));
    if Animation <> nil then Animation.SetPosition(TruncatePointF(APosition));
    MapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
  end;
end;
{ @end $6004C0 }

{ @routine $600568 TStarSE_GetSequenceFrameIndex }
function TStarSE.GetSequenceFrameIndex: Integer;
begin
  if Animation = nil then Result := SavedSequenceFrameIndex
  else Result := Animation.SequenceFrame;
end;
{ @end $600568 }

{ @routine $60057C TStarSE_SetSequenceFrameIndex }
procedure TStarSE.SetSequenceFrameIndex(FrameIndex: Integer);
begin
  SavedSequenceFrameIndex := FrameIndex;
  if Animation <> nil then Animation.SetSequenceFrame(FrameIndex);
end;
{ @end $60057C }

{ @routine $600590 TStarSE_HitTestCursor }
function TStarSE.HitTestCursor: Boolean;
begin
  Result := False;
  if not IsAttachedToSpace then
  begin
    Result := False;
    Exit;
  end;
  if StaticImage <> nil then Result := StaticImage.HitTestCursor;
  if Animation <> nil then Result := Animation.HitTestCursor;
end;
{ @end $600590 }

{ @routine $6005C8 TStarSE_DrawMap }
procedure TStarSE.DrawMap;
begin
  MapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $6005C8 }

{ @routine $600604 TStarSE_LoadTemplate }
procedure TStarSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  StaticImagePath := Block.GetParam('Image');
  AnimationPath := Block.GetParam('Anim');
  MapImagePath := Block.GetParam('ImageMap');
  ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
  MapImageOrigin := GetPointGI(Block.GetParam('SmeImageMap'));
end;
{ @end $600604 }

{ @routine $600768 TStarSE_QueueImageLoad }
procedure TStarSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  if not AnimStar then
    with TImageGI.Create(Owner) do
    begin
      SetImagePath(StaticImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end
  else
    with TgaiGI.Create(Owner) do
    begin
      SetImagePath(AnimationPath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
  with TgiGI.Create(Owner) do
  begin
    SetImagePath(MapImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;
{ @end $600768 }

end.

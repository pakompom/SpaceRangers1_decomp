unit SE_Ruins;
// Unit bracket (inferred): CODE 0x00593BC0..0x005942CB; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_GAI, GI_Image, GI_MessageLoop, SE_Space, Types;

type
  TRuinsSE = class(TObjectSE) // @size $64
  public
    ImagePath: WideString; // @offset $48
    StaticImagePath: WideString; // @offset $4C
    MinimapImagePath: WideString; // @offset $50
    Animation: TgaiGI; // @offset $54
    StaticImage: TImageGI; // @offset $58
    MinimapImage: TImageGI; // @offset $5C
    FrameIndex: Integer; // @offset $60
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $593C94
    procedure DetachFromSpace; override; // @addr $593F64
    procedure SetPosition(APosition: TPointF); override; // @addr $593FC4
    procedure DrawMap; override; // @addr $59406C
    function HitTestCursor: Boolean; override; // @addr $5940C0
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $594118
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $5941F0
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $5941F8
  end;

implementation

// @unit-initialization $5942C4
// @unit-finalization $594294

uses Math, SysUtils, EC_Str, Globals, GlobalsV, GR_Main, SE_Process;

{ @routine $593C94 TRuinsSE_AttachToSpace }
procedure TRuinsSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    ConfigureLoopSound('Ruins.' + ExtractDelimitedPartW(ImagePath, CountDelimitedPartsW(ImagePath, '.') - 1, '.'));
    ConfigureRandomSound('Ruins.' + ExtractDelimitedPartW(ImagePath, CountDelimitedPartsW(ImagePath, '.') - 1, '.'));
    inherited AttachToSpace(ASpace);
    if AnimShipFull then
    begin
      Animation := TgaiGI.Create(Space.MapPanel);
      Animation.SetImagePath(ImagePath);
      Animation.SetSize(Animation.GetContentSize);
      Animation.SetOrigin(HalfPoint(Animation.ClientSize));
      Animation.SetDepthByName(DepthExpression);
      Animation.SetPosition(TruncatePointF(Position));
      Animation.SetPositionModeW(True);
      Animation.SequenceIndex := 0;
      Animation.UpdateAutoGeometry;
      Animation.SetSequenceFrame(FrameIndex);
      Animation.RestartPlayback;
    end
    else
    begin
      StaticImage := TImageGI.Create(Space.MapPanel);
      StaticImage.SetImagePath(StaticImagePath);
      StaticImage.SetSize(StaticImage.GetContentSize);
      StaticImage.SetOrigin(HalfPoint(StaticImage.ClientSize));
      StaticImage.SetDepthByName(DepthExpression);
      StaticImage.SetPosition(TruncatePointF(Position));
      StaticImage.SetPositionModeW(True);
    end;
    MinimapImage := TImageGI.Create(SpaceObjectUiLoop.ContentPanel);
    MinimapImage.SetPositionModeW(True);
    MinimapImage.SetDepthByName(DepthExpression);
    MinimapImage.SetPosition(TruncatePointF(MakePointF(Position.X * Space.MinimapScale, Position.Y * Space.MinimapScale)));
    MinimapImage.SetImagePath(MinimapImagePath);
    MinimapImage.SetSize(MinimapImage.GetContentSize);
    MinimapImage.SetOrigin(HalfPoint(MinimapImage.ClientSize));
  end;
end;
{ @end $593C94 }

{ @routine $593F64 TRuinsSE_DetachFromSpace }
procedure TRuinsSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    if Animation <> nil then
    begin
      FrameIndex := Animation.SequenceFrame;
      Animation.Free;
      Animation := nil;
    end;
    if StaticImage <> nil then
    begin
      StaticImage.SetActive(False);
    StaticImage.Free;
      StaticImage := nil;
    end;
    if MinimapImage <> nil then
    begin
      MinimapImage.Free;
      MinimapImage := nil;
    end;
    inherited DetachFromSpace;
  end;
end;
{ @end $593F64 }

{ @routine $593FC4 TRuinsSE_SetPosition }
procedure TRuinsSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then
  begin
    if StaticImage <> nil then StaticImage.SetPosition(TruncatePointF(APosition));
    if Animation <> nil then Animation.SetPosition(TruncatePointF(APosition));
    MinimapImage.SetPosition(TruncatePointF(MakePointF(APosition.X * Space.MinimapScale, APosition.Y * Space.MinimapScale)));
  end;
end;
{ @end $593FC4 }

{ @routine $59406C TRuinsSE_DrawMap }
procedure TRuinsSE.DrawMap;
var
  CurrentProcess: TProcessSE;
begin
  CurrentProcess := Space.Process as TProcessSE;
  if CurrentProcess.RadarRange > 0 then
    MinimapImage.Draw(Classes.Rect(0, 0, RenderScratchBuffer.Width, RenderScratchBuffer.Height));
end;
{ @end $59406C }

{ @routine $5940C0 TRuinsSE_HitTestCursor }
function TRuinsSE.HitTestCursor: Boolean;
begin
  Result := False;
  if IsAttachedToSpace then
  begin
    if Animation <> nil then Result := Animation.HitTestPixel(Animation.MessageLoop.GetCursorPoint)
    else if StaticImage <> nil then Result := StaticImage.HitTestPixel(StaticImage.MessageLoop.GetCursorPoint);
  end;
end;
{ @end $5940C0 }

{ @routine $594118 TRuinsSE_LoadTemplate }
procedure TRuinsSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  StaticImagePath := Block.GetParam('ImageI');
  MinimapImagePath := Block.GetParam('ImageMap');
end;
{ @end $594118 }

{ @routine $5941F0 TRuinsSE_ApplyConfig }
procedure TRuinsSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $5941F0 }

{ @routine $5941F8 TRuinsSE_QueueImageLoad }
procedure TRuinsSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Anim: TgaiGI;
  Image, MapImage: TImageGI;
begin
  if AnimShipFull then
  begin
    Anim := TgaiGI.Create(Owner);
    Anim.SetImagePath(ImagePath);
    Anim.QueueImageLoad(PendingLoads);
    Anim.Free;
  end
  else
  begin
    Image := TImageGI.Create(Owner);
    Image.SetImagePath(StaticImagePath);
    Image.QueueImageLoad(PendingLoads);
    Image.Free;
  end;
  MapImage := TImageGI.Create(Owner);
  MapImage.SetImagePath(MinimapImagePath);
  MapImage.QueueImageLoad(PendingLoads);
  MapImage.Free;
end;
{ @end $5941F8 }

end.

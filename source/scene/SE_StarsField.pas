unit SE_StarsField;
// Unit bracket (inferred): CODE 0x0060B4C4..0x0060B7D7; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_MessageLoop, GI_SimpleImage, GI_InfiniteImage, SE_Space, Types;

type
  TStarsFieldSE = class(TObjectSE) // @size $54

  public
    ImagePath: WideString; // @offset $48
    InfiniteImage: TInfiniteImageGI; // @offset $4C
    StaticImage: TSimpleImageGI; // @offset $50
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $60B58C
    procedure DetachFromSpace; override; // @addr $60B680
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $60B6C8
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $60B738
  end;

implementation

// @unit-initialization $60B7D0
// @unit-finalization $60B7A0

uses GlobalsV, GI_Image;
{ @routine $60B58C TStarsFieldSE_AttachToSpace }
procedure TStarsFieldSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  inherited AttachToSpace(ASpace);
  if StaticBackground then
  begin
    StaticImage := TSimpleImageGI.Create(Space.MapPanel);
    StaticImage.SetDepthByName(DepthExpression);
    StaticImage.SetPositionModeW(False);
    StaticImage.SetImageKindX(ikxLeftFill);
    StaticImage.SetImageKindY(ikyTopFill);
    StaticImage.SetPosition(Classes.Point(-Space.MapPanel.OriginPoint.X, -Space.MapPanel.OriginPoint.Y));
    StaticImage.SetSize(Classes.Point(Space.MapPanel.ClientSize.X, Space.MapPanel.ClientSize.Y));
    StaticImage.SetImagePath(ImagePath);
  end
  else
  begin
    InfiniteImage := TInfiniteImageGI.Create(Space.MapPanel);
    InfiniteImage.SetDepthByName(DepthExpression);
    InfiniteImage.SetPositionModeW(True);
    InfiniteImage.SetImagePath(ImagePath);
  end;
end;
{ @end $60B58C }

{ @routine $60B680 TStarsFieldSE_DetachFromSpace }
procedure TStarsFieldSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  if InfiniteImage <> nil then
  begin
    Space.MapPanel.FreeOwnedChild(InfiniteImage);
    InfiniteImage := nil;
  end;
  if StaticImage <> nil then
  begin
    Space.MapPanel.FreeOwnedChild(StaticImage);
    StaticImage := nil;
  end;
  inherited DetachFromSpace;
end;
{ @end $60B680 }

{ @routine $60B6C8 TStarsFieldSE_LoadTemplate }
procedure TStarsFieldSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
end;
{ @end $60B6C8 }

{ @routine $60B738 TStarsFieldSE_QueueImageLoad }
procedure TStarsFieldSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  if StaticBackground then
    with TSimpleImageGI.Create(Owner) do
    begin
      SetImagePath(Self.ImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end
  else
    with TInfiniteImageGI.Create(Owner) do
    begin
      SetImagePath(Self.ImagePath);
      QueueImageLoad(PendingLoads);
      Free;
    end;
end;
{ @end $60B738 }

end.

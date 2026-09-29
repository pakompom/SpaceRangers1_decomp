unit SE_BGObj;
// Unit bracket (inferred): CODE 0x0060B7D8..0x0060BABF; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_MessageLoop, GI_Image, SE_Space, Types;

type
  TBGObjSE = class(TObjectSE) // @size $54

  public
    ImagePath: WideString; // @offset $48
    Radius: Single; // @offset $4C Loaded but not used by this scene unit.
    Image: TImageGI; // @offset $50
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $60B89C
    procedure DetachFromSpace; override; // @addr $60B920
    procedure SetPosition(APosition: TPointF); override; // @addr $60B94C
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $60B990
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $60BA54
  end;

implementation

// @unit-initialization $60BAB8
// @unit-finalization $60BA88

uses EC_Str, GI_Main, SysUtils;
{ @routine $60B89C TBGObjSE_AttachToSpace }
procedure TBGObjSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  inherited AttachToSpace(ASpace);
  Image := TImageGI.Create(Space.MapPanel);
  Image.SetPositionModeW(True);
  Image.SetDepthByName(DepthExpression);
  Image.SetPosition(TruncatePointF(Position));
  Image.SetImagePath(ImagePath);
  Image.SetSize(Image.GetContentSize);
end;
{ @end $60B89C }

{ @routine $60B920 TBGObjSE_DetachFromSpace }
procedure TBGObjSE.DetachFromSpace;
begin
  if not IsAttachedToSpace then Exit;
  Space.MapPanel.FreeOwnedChild(Image);
  Image := nil;
  inherited DetachFromSpace;
end;
{ @end $60B920 }

{ @routine $60B94C TBGObjSE_SetPosition }
procedure TBGObjSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then Image.SetPosition(TruncatePointF(APosition));
end;
{ @end $60B94C }

{ @routine $60B990 TBGObjSE_LoadTemplate }
procedure TBGObjSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  Radius := SysUtils.StrToInt(AnsiString(Block.GetParam('Radius')));
end;
{ @end $60B990 }

{ @routine $60BA54 TBGObjSE_QueueImageLoad }
procedure TBGObjSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
begin
  with TImageGI.Create(Owner) do
  begin
    SetImagePath(Self.ImagePath);
    QueueImageLoad(PendingLoads);
    Free;
  end;
end;
{ @end $60BA54 }

end.

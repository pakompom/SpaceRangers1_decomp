unit SE_Anim;
// Unit bracket (inferred): CODE 0x004CBF68..0x004CC42B; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, EC_Struct, GI_GAI, GI_MessageLoop, SE_Space, Types;

type
  TAnimationFinishedEventSE = procedure(Sender: TObject) of object;
  TAnimSE = class(TObjectSE) // @size $68
  public
    ImagePath: WideString; // @offset $48
    ImageOrigin: TPoint; // @offset $4C
    LoopAnimation: Boolean; // @offset $54
    Animation: TgaiGI; // @offset $58
    FinishedCallback: TAnimationFinishedEventSE; // @offset $60 Native event code/data; $5C is padding.
    destructor Destroy; override; // @addr $4CC02C
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $4CC054
    procedure DetachFromSpace; override; // @addr $4CC110
    procedure SetPosition(APosition: TPointF); override; // @addr $4CC140
    procedure AnimationCycleComplete(Sender: TObjectGI); // @addr $4CC184
    function HitTestCursor: Boolean; override; // @addr $4CC1A8
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $4CC1C4
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $4CC2D8
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $4CC3C0
  end;

implementation

// @unit-initialization $4CC424
// @unit-finalization $4CC3F4

uses GI_Main;

{ @routine $4CC02C TAnimSE_Destroy }
destructor TAnimSE.Destroy;
begin
  inherited Destroy;
end;
{ @end $4CC02C }

{ @routine $4CC054 TAnimSE_AttachToSpace }
procedure TAnimSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if not IsAttachedToSpace then
  begin
    inherited AttachToSpace(ASpace);
    Animation := TgaiGI.Create(Space.MapPanel);
    Animation.SetImagePath(ImagePath);
    Animation.SequenceIndex := 0;
    Animation.UpdateAutoGeometry;
    Animation.SetPositionModeW(True);
    Animation.SetDepthByName(DepthExpression);
    Animation.SetPosition(TruncatePointF(Position));
    Animation.SetOrigin(ImageOrigin);
    Animation.SetSize(Animation.GetContentSize);
    Animation.CycleCompleteCallback := AnimationCycleComplete;
    Animation.RestartPlayback;
  end;
end;
{ @end $4CC054 }

{ @routine $4CC110 TAnimSE_DetachFromSpace }
procedure TAnimSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    Animation.SetActive(False);
    Animation.Free;
    Animation := nil;
    inherited DetachFromSpace;
  end;
end;
{ @end $4CC110 }

{ @routine $4CC140 TAnimSE_SetPosition }
procedure TAnimSE.SetPosition(APosition: TPointF);
begin
  inherited SetPosition(APosition);
  if IsAttachedToSpace then Animation.SetPosition(TruncatePointF(Position));
end;
{ @end $4CC140 }

{ @routine $4CC184 TAnimSE_AnimationCycleComplete }
procedure TAnimSE.AnimationCycleComplete(Sender: TObjectGI);
begin
  if not LoopAnimation then
  begin
    DetachFromSpace;
    if Assigned(FinishedCallback) then FinishedCallback(Self);
  end;
end;
{ @end $4CC184 }

{ @routine $4CC1A8 TAnimSE_HitTestCursor }
function TAnimSE.HitTestCursor: Boolean;
begin
  if not IsAttachedToSpace then Result := False
  else Result := Animation.HitTestCursor;
end;
{ @end $4CC1A8 }

{ @routine $4CC1C4 TAnimSE_LoadTemplate }
procedure TAnimSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  ImagePath := Block.GetParam('Image');
  if Block.CountParams('LoopAnim') > 0 then LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'));
  if Block.CountParams('SmeImage') > 0 then ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
end;
{ @end $4CC1C4 }

{ @routine $4CC2D8 TAnimSE_ApplyConfig }
procedure TAnimSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
  if Block.CountParams('LoopAnim') > 0 then LoopAnimation := ParseEnabledNameGI(Block.GetParam('LoopAnim'));
  if Block.CountParams('SmeImage') > 0 then ImageOrigin := GetPointGI(Block.GetParam('SmeImage'));
end;
{ @end $4CC2D8 }

{ @routine $4CC3C0 TAnimSE_QueueImageLoad }
procedure TAnimSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var
  Image: TgaiGI;
begin
  Image := TgaiGI.Create(Owner);
  Image.SetImagePath(ImagePath);
  Image.QueueImageLoad(PendingLoads);
  Image.Free;
end;
{ @end $4CC3C0 }

end.

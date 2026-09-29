unit GI_Image;
// Unit bracket (inferred): CODE 0x0046F79C..0x004705DB; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_GAI, GI_MessageLoop, GI_Main, GI_AImage, GI_AlphaImage, GI_GI, GI_TransImage, GI_SimpleImage, GI_GraphBuf, Classes, Types;

type
  TImageGI = class(TObjectGI) // @size $124
  public
    SimpleImageControl: TSimpleImageGI; // @offset $100
    TransImageControl: TTransImageGI; // @offset $104
    AlphaImageControl: TAlphaImageGI; // @offset $108
    GiImageControl: TgiGI; // @offset $10C
    AnimImageControl: TAImageGI; // @offset $110
    GaiImageControl: TgaiGI; // @offset $114
    GraphBufControl: TGraphBufGI; // @offset $118
    ImagePath: WideString; // @offset $11C
    AutoUpdateFlags: Cardinal; // @offset $120

    procedure Clear; override; // @addr $46F91C
    procedure SetSize(Size: TPoint); override; // @addr $4700F4
    procedure SetOrigin(Origin: TPoint); override; // @addr $470198
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $47054C @note "GI and GraphBuf children are skipped."
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $470320
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $47034C
    procedure UpdateAutoGeometry; override; // @addr $4704EC @note "Auto-geometry bit 0 uses content origin; bit 1 uses content size."
    constructor Create(Owner: TObjectGI); // @addr $46F8BC
    destructor Destroy; override; // @addr $46F8F4
    procedure SetImagePath(Path: WideString); // @addr $46F924 @note "Empty paths remove the child; unknown modes raise."
    function GetImagePath: WideString; // @addr $46FEAC
    function GetContentSize: TPoint; // @addr $46FEC4
    function GetContentOrigin: TPoint; // @addr $46FF88 @note "Only GI children supply an origin; other kinds return (0,0)."
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $46FFB4
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $470038
    procedure SetHalfAlpha(Value: Boolean); // @addr $4700BC @note "Only affects Simple, Trans and Anim children."
    function HitTestPixel(Point: TPoint): Boolean; // @addr $47025C @note "Returns false for kinds other than Alpha, Anim, GI and GAI."
    function GetVisualCenter: TPoint; // @addr $4702C4 @note "Only GI and GraphBuf write the result; other kinds leave it untouched."
    procedure RestartPlayback; // @addr $4702F8
    procedure StopPlayback; // @addr $47030C
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $470368
  end;

implementation

// @unit-initialization $4705D4
// @unit-finalization $4705A4

uses SysUtils, EC_Str, GR_Main;

{ @routine $46F8BC TImageGI_Create }
constructor TImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
end;
{ @end $46F8BC }

{ @routine $46F8F4 TImageGI_Destroy }
destructor TImageGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $46F8F4 }

{ @routine $46F91C TImageGI_Clear }
procedure TImageGI.Clear;
begin
  inherited Clear;
end;
{ @end $46F91C }

{ @routine $46F924 TImageGI_SetImagePath }
procedure TImageGI.SetImagePath(Path: WideString);
var Mode: WideString;
begin
  if ImagePath <> Path then
  begin
    if SimpleImageControl <> nil then
    begin
      FreeOwnedChild(SimpleImageControl);
      SimpleImageControl := nil;
    end;
    if TransImageControl <> nil then
    begin
      FreeOwnedChild(TransImageControl);
      TransImageControl := nil;
    end;
    if AlphaImageControl <> nil then
    begin
      FreeOwnedChild(AlphaImageControl);
      AlphaImageControl := nil;
    end;
    if GiImageControl <> nil then
    begin
      FreeOwnedChild(GiImageControl);
      GiImageControl := nil;
    end;
    if AnimImageControl <> nil then
    begin
      FreeOwnedChild(AnimImageControl);
      AnimImageControl := nil;
    end;
    if GaiImageControl <> nil then
    begin
      FreeOwnedChild(GaiImageControl);
      GaiImageControl := nil;
    end;
    if GraphBufControl <> nil then
    begin
      FreeOwnedChild(GraphBufControl);
      GraphBufControl := nil;
    end;
    if Path = '' then
    begin
      ImagePath := '';
      Invalidate;
    end
    else
    begin
      ImagePath := Path;
      Mode := ExtractNextDelimitedPartW(Path, ',');
      if Mode = 'GraphBuf' then
      begin
        GraphBufControl := TGraphBufGI.Create(Self);
        GraphBufControl.SetSize(ClientSize);
        GraphBufControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Path = '' then
      begin
        SimpleImageControl := TSimpleImageGI.Create(Self);
        SimpleImageControl.SetImagePath(Mode);
        SimpleImageControl.SetSize(ClientSize);
        SimpleImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Simple' then
      begin
        SimpleImageControl := TSimpleImageGI.Create(Self);
        SimpleImageControl.SetImagePath(Path);
        SimpleImageControl.SetSize(ClientSize);
        SimpleImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Trans' then
      begin
        TransImageControl := TTransImageGI.Create(Self);
        TransImageControl.SetImagePath(Path);
        TransImageControl.SetSize(ClientSize);
        TransImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Alpha' then
      begin
        AlphaImageControl := TAlphaImageGI.Create(Self);
        AlphaImageControl.SetImagePath(Path);
        AlphaImageControl.SetSize(ClientSize);
        AlphaImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'GI' then
      begin
        GiImageControl := TgiGI.Create(Self);
        GiImageControl.SetImagePath(Path);
        GiImageControl.SetSize(ClientSize);
        GiImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'Anim' then
      begin
        AnimImageControl := TAImageGI.Create(Self);
        AnimImageControl.SetConfigPath(Path);
        AnimImageControl.SetSize(ClientSize);
        AnimImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
      end
      else if Mode = 'GAI' then
      begin
        GaiImageControl := TgaiGI.Create(Self);
        GaiImageControl.SetImagePath(Path);
        GaiImageControl.SetSize(ClientSize);
        GaiImageControl.SetPosition(Classes.Point(-OriginPoint.X, -OriginPoint.Y));
        if GaiImageControl.GetSequenceCount > 0 then
        begin
          GaiImageControl.SequenceIndex := 0;
          GaiImageControl.UpdateAutoGeometry;
          GaiImageControl.RestartPlayback;
        end;
      end
      else raise Exception.Create('TImageGI.SetImage. Path=' + Path);
    end;
  end;
end;
{ @end $46F924 }

{ @routine $46FEAC TImageGI_GetImagePath }
function TImageGI.GetImagePath: WideString;
begin
  Result := ImagePath;
end;
{ @end $46FEAC }

{ @routine $46FEC4 TImageGI_GetContentSize }
function TImageGI.GetContentSize: TPoint;
begin
  if SimpleImageControl <> nil then Result := SimpleImageControl.GetContentSize
  else if TransImageControl <> nil then Result := TransImageControl.GetContentSize
  else if AlphaImageControl <> nil then Result := AlphaImageControl.GetContentSize
  else if GiImageControl <> nil then Result := GiImageControl.GetContentSize
  else if AnimImageControl <> nil then Result := AnimImageControl.GetContentSize
  else if GaiImageControl <> nil then Result := GaiImageControl.GetContentSize
  else if GraphBufControl <> nil then Result := Classes.Point(GraphBufControl.GraphBuf.Width, GraphBufControl.GraphBuf.Height)
  else Result := Classes.Point(0, 0);
end;
{ @end $46FEC4 }

{ @routine $46FF88 TImageGI_GetContentOrigin }
function TImageGI.GetContentOrigin: TPoint;
begin
  if GiImageControl <> nil then Result := GiImageControl.GetContentOrigin
  else Result := Classes.Point(0, 0);
end;
{ @end $46FF88 }

{ @routine $46FFB4 TImageGI_SetImageKindX }
procedure TImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if SimpleImageControl <> nil then SimpleImageControl.SetImageKindX(Value)
  else if TransImageControl <> nil then TransImageControl.SetImageKindX(Value)
  else if AlphaImageControl <> nil then AlphaImageControl.SetImageKindX(Value)
  else if GiImageControl <> nil then GiImageControl.SetImageKindX(Value)
  else if AnimImageControl <> nil then AnimImageControl.SetImageKindX(Value)
  else if GaiImageControl <> nil then GaiImageControl.SetImageKindX(Value)
  else if GraphBufControl <> nil then GraphBufControl.SetImageKindX(Value);
end;
{ @end $46FFB4 }

{ @routine $470038 TImageGI_SetImageKindY }
procedure TImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if SimpleImageControl <> nil then SimpleImageControl.SetImageKindY(Value)
  else if TransImageControl <> nil then TransImageControl.SetImageKindY(Value)
  else if AlphaImageControl <> nil then AlphaImageControl.SetImageKindY(Value)
  else if GiImageControl <> nil then GiImageControl.SetImageKindY(Value)
  else if AnimImageControl <> nil then AnimImageControl.SetImageKindY(Value)
  else if GaiImageControl <> nil then GaiImageControl.SetImageKindY(Value)
  else if GraphBufControl <> nil then GraphBufControl.SetImageKindY(Value);
end;
{ @end $470038 }

{ @routine $4700BC TImageGI_SetHalfAlpha }
procedure TImageGI.SetHalfAlpha(Value: Boolean);
begin
  if SimpleImageControl <> nil then SimpleImageControl.SetHalfAlpha(Value)
  else if TransImageControl <> nil then TransImageControl.SetHalfAlpha(Value)
  else if AnimImageControl <> nil then AnimImageControl.SetHalfAlpha(Value);
end;
{ @end $4700BC }

{ @routine $4700F4 TImageGI_SetSize }
procedure TImageGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if SimpleImageControl <> nil then SimpleImageControl.SetSize(Size)
  else if TransImageControl <> nil then TransImageControl.SetSize(Size)
  else if AlphaImageControl <> nil then AlphaImageControl.SetSize(Size)
  else if GiImageControl <> nil then GiImageControl.SetSize(Size)
  else if AnimImageControl <> nil then AnimImageControl.SetSize(Size)
  else if GaiImageControl <> nil then GaiImageControl.SetSize(Size)
  else if GraphBufControl <> nil then GraphBufControl.SetSize(Size);
end;
{ @end $4700F4 }

{ @routine $470198 TImageGI_SetOrigin }
procedure TImageGI.SetOrigin(Origin: TPoint);
var Position: TPoint;
begin
  inherited SetOrigin(Origin);
  Position.X := -Origin.X;
  Position.Y := -Origin.Y;
  if SimpleImageControl <> nil then SimpleImageControl.SetPosition(Position)
  else if TransImageControl <> nil then TransImageControl.SetPosition(Position)
  else if AlphaImageControl <> nil then AlphaImageControl.SetPosition(Position)
  else if GiImageControl <> nil then GiImageControl.SetPosition(Position)
  else if AnimImageControl <> nil then AnimImageControl.SetPosition(Position)
  else if GaiImageControl <> nil then GaiImageControl.SetPosition(Position)
  else if GraphBufControl <> nil then GraphBufControl.SetPosition(Position);
end;
{ @end $470198 }

{ @routine $47025C TImageGI_HitTestPixel }
function TImageGI.HitTestPixel(Point: TPoint): Boolean;
begin
  if AlphaImageControl <> nil then Result := AlphaImageControl.HitTestPixel(Point)
  else if AnimImageControl <> nil then Result := AnimImageControl.HitTest(Point)
  else if GiImageControl <> nil then Result := GiImageControl.HitTestPixel(Point)
  else if GaiImageControl <> nil then Result := GaiImageControl.HitTestPixel(Point)
  else Result := False;
end;
{ @end $47025C }

{ @routine $4702C4 TImageGI_GetVisualCenter }
function TImageGI.GetVisualCenter: TPoint;
begin
  if GiImageControl <> nil then Result := GiImageControl.GetVisualCenter
  else if GraphBufControl <> nil then Result := GraphBufControl.GetVisualCenter;
end;
{ @end $4702C4 }

{ @routine $4702F8 TImageGI_RestartPlayback }
procedure TImageGI.RestartPlayback;
begin
  if GaiImageControl <> nil then GaiImageControl.RestartPlayback;
end;
{ @end $4702F8 }

{ @routine $47030C TImageGI_StopPlayback }
procedure TImageGI.StopPlayback;
begin
  if GaiImageControl <> nil then GaiImageControl.StopAutoPlayback;
end;
{ @end $47030C }

{ @routine $470320 TImageGI_LoadFromConfigPath }
procedure TImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $470320 }

{ @routine $47034C TImageGI_LoadFromBlock }
procedure TImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;
{ @end $47034C }

{ @routine $470368 TImageGI_LoadImageProperties }
procedure TImageGI.LoadImageProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then SetImagePath(Block.GetParam('Image'));
  if Block.CountParams('KindX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('HalfAlpha') > 0 then SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
  if Block.CountParams('Auto') > 0 then AutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
end;
{ @end $470368 }

{ @routine $4704EC TImageGI_UpdateAutoGeometry }
procedure TImageGI.UpdateAutoGeometry;
begin
  if (AutoUpdateFlags and agfPosition) = agfPosition then SetPosition(Parent.ToLocalPoint(GetContentOrigin));
  if (AutoUpdateFlags and agfSize) = agfSize then SetSize(GetContentSize);
end;
{ @end $4704EC }

{ @routine $47054C TImageGI_QueueImageLoad }
procedure TImageGI.QueueImageLoad(PendingLoads: TList);
begin
  if SimpleImageControl <> nil then SimpleImageControl.QueueImageLoad(PendingLoads)
  else if TransImageControl <> nil then TransImageControl.QueueImageLoad(PendingLoads)
  else if AlphaImageControl <> nil then AlphaImageControl.QueueImageLoad(PendingLoads)
  else if AnimImageControl <> nil then AnimImageControl.QueueImageLoad(PendingLoads)
  else if GaiImageControl <> nil then GaiImageControl.QueueImageLoad(PendingLoads);
end;
{ @end $47054C }

end.

unit SE_Gate;
// Unit bracket (inferred): CODE 0x004CD018..0x004CDAF3; inclusive evidence, not full bounds.

interface

uses SE_Space, Types, Classes, EC_BlockPar, GI_MessageLoop, GI_RotateImage2, GI_Label, EC_Str;

type
  TGateSE = class(TObjectSE) // @size $88 @methodorder source
  public
    Angle: Byte; // @offset $48
    State: Integer; // @offset $4C
    StateStep: Integer; // @offset $50
    LabelText: WideString; // @offset $54
    Image: TRotateImage2GI; // @offset $58
    TextLabel: TLabelGI; // @offset $5C
    TextRed: Single; // @offset $60
    TextGreen: Single; // @offset $64
    TextBlue: Single; // @offset $68
    TickCount: Integer; // @offset $6C
    OpenFrames: TStringsEC; // @offset $70
    OpenFrameTime: Integer; // @offset $74
    NormalFrames: TStringsEC; // @offset $78
    NormalFrameTime: Integer; // @offset $7C
    CloseFrames: TStringsEC; // @offset $80
    CloseFrameTime: Integer; // @offset $84
    constructor Create(GraphKey: WideString; UnusedPosition: TPoint); // @addr $4CD0DC
    destructor Destroy; override; // @addr $4CD180
    procedure AttachToSpace(ASpace: TSpaceSE); override; // @addr $4CD1E0
    procedure DetachFromSpace; override; // @addr $4CD37C
    procedure Advance; override; // @addr $4CD7BC
    procedure LoadTemplate(Block: TBlockParEC); override; // @addr $4CD7E8
    procedure ApplyConfig(Block: TBlockParEC); override; // @addr $4CD9AC
    procedure QueueImageLoad(PendingLoads: TList; Owner: TObjectGI); override; // @addr $4CD9B4
    procedure Open; // @addr $4CD434 Changes idle state 0 to opening state 1.
    procedure Close; // @addr $4CD460 Changes open state 2 to closing state 3.
    procedure SetState(Value: Integer); // @addr $4CD48C Resets StateStep and rebuilds attached graphics.
    procedure RebuildStateGraphics; // @addr $4CD4AC
    procedure AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer); // @addr $4CD740
    procedure LoadFrames(Block: TBlockParEC; Frames: TStringsEC; var FrameTime: Integer); // @addr $4CD8B8
    function GetAngle: Byte; override; // @addr $4CD3C8
    procedure SetAngle(Value: Byte); override; // @addr $4CD3CC
    function GetText: WideString; override; // @addr $4CD3F0
    procedure SetText(const Value: WideString); override; // @addr $4CD404
  end;

implementation

// @unit-initialization $4CDAEC
// @unit-finalization $4CDABC

uses GlobalsV, GR_Main, GI_Main, SysUtils;

{ @routine $4CD0DC TGateSE_Create }
constructor TGateSE.Create(GraphKey: WideString; UnusedPosition: TPoint);
begin
  inherited Create(GraphKey, UnusedPosition);
  State := 0;
  TextRed := 1;
  TextGreen := 1;
  TextBlue := 1;
end;
{ @end $4CD0DC }

{ @routine $4CD180 TGateSE_Destroy }
destructor TGateSE.Destroy;
begin
  if OpenFrames <> nil then begin OpenFrames.Free; OpenFrames := nil; end;
  if NormalFrames <> nil then begin NormalFrames.Free; NormalFrames := nil; end;
  if CloseFrames <> nil then begin CloseFrames.Free; CloseFrames := nil; end;
  inherited Destroy;
end;
{ @end $4CD180 }

{ @routine $4CD1E0 TGateSE_AttachToSpace }
procedure TGateSE.AttachToSpace(ASpace: TSpaceSE);
begin
  if IsAttachedToSpace then Exit;
  ConfigureLoopSound('Gate');
  ConfigureRandomSound('Gate');
  inherited AttachToSpace(ASpace);
  TickCount := 0;
  Image := TRotateImage2GI.Create(Space.MapPanel);
  Image.SetPositionModeW(True);
  Image.SetDepthByName(DepthExpression);
  Image.SetPosition(Classes.Point(Round(Position.X), Round(Position.Y)));
  Image.SetAngle(Angle + 128);
  Image.SetAlpha(255);
  TextLabel := TLabelGI.Create(Space.MapPanel);
  TextLabel.SetActive(False);
  TextLabel.SetFontName(HitPointFontName);
  TextLabel.SetPositionModeW(True);
  TextLabel.SetDepthByName(DepthExpression);
  TextLabel.SetSize(Classes.Point(150, 20));
  TextLabel.SetPosition(Classes.Point(Round(Position.X - TextLabel.ClientSize.X / 2), Round(Position.Y + 50)));
  TextLabel.SetText(LabelText);
  TextLabel.SetWordWrapEnabled(False);
  TextLabel.SetTextAlignX(taxCenter);
  TextLabel.SetTextAlignY(tayAuto);
  if State = 1 then begin end
  else if State = 2 then begin end
  else if State = 3 then begin end;
  RebuildStateGraphics;
end;
{ @end $4CD1E0 }

{ @routine $4CD37C TGateSE_DetachFromSpace }
procedure TGateSE.DetachFromSpace;
begin
  if IsAttachedToSpace then
  begin
    Image.SetActive(False);
    Image.Free;
    Image := nil;
    if TextLabel <> nil then
    begin
      TextLabel.SetActive(False);
      TextLabel.Free;
      TextLabel := nil;
    end;
    inherited DetachFromSpace;
  end;
end;
{ @end $4CD37C }

{ @routine $4CD3C8 TGateSE_GetAngle }
function TGateSE.GetAngle: Byte;
begin
  Result := Angle;
end;
{ @end $4CD3C8 }

{ @routine $4CD3CC TGateSE_SetAngle }
procedure TGateSE.SetAngle(Value: Byte);
begin
  Angle := Value;
  if IsAttachedToSpace then Image.SetAngle(Angle + 128);
end;
{ @end $4CD3CC }

{ @routine $4CD3F0 TGateSE_GetText }
function TGateSE.GetText: WideString;
begin
  Result := LabelText;
end;
{ @end $4CD3F0 }

{ @routine $4CD404 TGateSE_SetText }
procedure TGateSE.SetText(const Value: WideString);
begin
  LabelText := Value;
  if IsAttachedToSpace then
    if TextLabel <> nil then TextLabel.SetText(LabelText);
end;
{ @end $4CD404 }

{ @routine $4CD434 TGateSE_Open }
procedure TGateSE.Open;
begin
  if State = 0 then
  begin
    State := 1;
    StateStep := 0;
    if IsAttachedToSpace then RebuildStateGraphics;
  end;
end;
{ @end $4CD434 }

{ @routine $4CD460 TGateSE_Close }
procedure TGateSE.Close;
begin
  if State = 2 then
  begin
    State := 3;
    StateStep := 0;
    if IsAttachedToSpace then RebuildStateGraphics;
  end;
end;
{ @end $4CD460 }

{ @routine $4CD48C TGateSE_SetState }
procedure TGateSE.SetState(Value: Integer);
begin
  State := Value;
  StateStep := 0;
  if IsAttachedToSpace then RebuildStateGraphics;
end;
{ @end $4CD48C }

{ @routine $4CD4AC TGateSE_RebuildStateGraphics }
procedure TGateSE.RebuildStateGraphics;
begin
  if State = 0 then
  begin
    Image.SetActive(False);
    if TextLabel <> nil then TextLabel.SetActive(False);
  end
  else if State = 1 then
  begin
    if (StateStep >= 0) and (StateStep < OpenFrames.GetCount) then
    begin
      Image.SetImage(OpenFrames.GetTextAt(StateStep), Classes.Point(100, 100), Classes.Point(50, 50));
      Image.SetActive(True);
      if TextLabel <> nil then TextLabel.SetActive(False);
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then TextLabel.SetActive(False);
    end;
  end
  else if State = 2 then
  begin
    if (StateStep >= 0) and (StateStep < NormalFrames.GetCount) then
    begin
      Image.SetImage(NormalFrames.GetTextAt(StateStep), Classes.Point(100, 100), Classes.Point(50, 50));
      Image.SetActive(True);
      if TextLabel <> nil then
      begin
        TextLabel.SetTextColor(CurrentPixelFormat.PackNormalizedRgb(TextRed, TextGreen, TextBlue));
        TextLabel.SetActive(True);
      end;
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then TextLabel.SetActive(False);
    end;
  end
  else if State = 3 then
  begin
    if (StateStep >= 0) and (StateStep < CloseFrames.GetCount) then
    begin
      Image.SetImage(CloseFrames.GetTextAt(StateStep), Classes.Point(100, 100), Classes.Point(50, 50));
      Image.SetActive(True);
      if TextLabel <> nil then TextLabel.SetActive(False);
    end
    else
    begin
      Image.SetActive(False);
      if TextLabel <> nil then TextLabel.SetActive(False);
    end;
  end;
end;
{ @end $4CD4AC }

{ @routine $4CD740 TGateSE_AdvanceAnimation }
procedure TGateSE.AdvanceAnimation(UnusedTimer: Pointer; UnusedData: Integer);
begin
  Inc(StateStep);
  if State = 0 then Exit
  else if State = 1 then
  begin
    if OpenFrames.GetCount <= StateStep then
    begin
      State := 2;
      StateStep := 0;
    end;
    RebuildStateGraphics;
  end
  else if State = 2 then
  begin
    if NormalFrames.GetCount <= StateStep then
    begin
      StateStep := 0;
    end;
    RebuildStateGraphics;
  end
  else if State = 3 then
  begin
    if CloseFrames.GetCount <= StateStep then
    begin
      State := 0;
      StateStep := 0;
    end;
    RebuildStateGraphics;
  end;
end;
{ @end $4CD740 }

{ @routine $4CD7BC TGateSE_Advance }
procedure TGateSE.Advance;
begin
  inherited Advance;
  Inc(TickCount);
  if TickCount mod 3 = 0 then AdvanceAnimation(nil, 0);
end;
{ @end $4CD7BC }

{ @routine $4CD7E8 TGateSE_LoadTemplate }
procedure TGateSE.LoadTemplate(Block: TBlockParEC);
begin
  inherited LoadTemplate(Block);
  OpenFrames := TStringsEC.Create;
  LoadFrames(Block.GetBlock('Open'), OpenFrames, OpenFrameTime);
  NormalFrames := TStringsEC.Create;
  LoadFrames(Block.GetBlock('Normal'), NormalFrames, NormalFrameTime);
  CloseFrames := TStringsEC.Create;
  LoadFrames(Block.GetBlock('Close'), CloseFrames, CloseFrameTime);
end;
{ @end $4CD7E8 }

{ @routine $4CD8B8 TGateSE_LoadFrames }
procedure TGateSE.LoadFrames(Block: TBlockParEC; Frames: TStringsEC; var FrameTime: Integer);
var Index: Integer;
begin
  FrameTime := ExtractDigitsToIntW(Block.GetParam('Time'));
  Index := 0;
  while Block.CountParams(IntToStr(Index)) > 0 do begin
    Frames.Add(TrimWideString(Block.GetParam(IntToStr(Index))));
    Inc(Index);
  end;
end;
{ @end $4CD8B8 }

{ @routine $4CD9AC TGateSE_ApplyConfig }
procedure TGateSE.ApplyConfig(Block: TBlockParEC);
begin
  inherited ApplyConfig(Block);
end;
{ @end $4CD9AC }

{ @routine $4CD9B4 TGateSE_QueueImageLoad }
procedure TGateSE.QueueImageLoad(PendingLoads: TList; Owner: TObjectGI);
var Index: Integer; Loader: TRotateImage2GI;
begin
  Loader := TRotateImage2GI.Create(Owner);
  for Index := 0 to OpenFrames.GetCount - 1 do Loader.QueueImagePath(PendingLoads, OpenFrames.GetTextAt(Index));
  for Index := 0 to NormalFrames.GetCount - 1 do Loader.QueueImagePath(PendingLoads, NormalFrames.GetTextAt(Index));
  for Index := 0 to CloseFrames.GetCount - 1 do Loader.QueueImagePath(PendingLoads, CloseFrames.GetTextAt(Index));
  Loader.Free;
end;
{ @end $4CD9B4 }

end.

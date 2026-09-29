unit GI_Frame;
// Unit bracket (inferred): CODE 0x0048D540..0x0048DB33; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, Types;

type
  TFrameKindGI = (fkHide=0, fkRect=1); // @size $01
  TFrameGI = class(TObjectGI) // @size $110
  public
    Kind: TFrameKindGI; // @offset $100
    Color: Cardinal; // @offset $104
    FillColor: Cardinal; // @offset $108
    Fill: Boolean; // @offset $10C
    FillAlpha: Byte; // @offset $10D

    constructor Create(Owner: TObjectGI); // @addr $48D650
    destructor Destroy; override; // @addr $48D69C
    procedure Draw(ClipRect: TRect); override; // @addr $48D930
    procedure Clear; override; // @addr $48D6C4 @note "Preserves fill and color fields."
    procedure SetKind(Value: TFrameKindGI); // @addr $48D6D4
    procedure SetColor(Value: Cardinal); // @addr $48D6EC
    procedure SetFillColor(Value: Cardinal); // @addr $48D704
    procedure SetFillAlpha(Value: Byte); // @addr $48D734
    procedure SetFill(Value: Boolean); // @addr $48D71C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48D74C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48D778
    procedure LoadFrameProperties(Block: TBlockParEC); // @addr $48D794
  end;

implementation

// @unit-initialization $48DB2C
// @unit-finalization $48DAFC

uses Classes, EC_OKGF, EC_Mem, GI_Main, GR_Main;

{ @routine $48D650 TFrameGI_Create }
constructor TFrameGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := fkHide;
  Fill := False;
  FillAlpha := 255;
end;
{ @end $48D650 }

{ @routine $48D69C TFrameGI_Destroy }
destructor TFrameGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $48D69C }

{ @routine $48D6C4 TFrameGI_Clear }
procedure TFrameGI.Clear;
begin
  Kind := fkHide;
  inherited Clear;
end;
{ @end $48D6C4 }

{ @routine $48D6D4 TFrameGI_SetKind }
procedure TFrameGI.SetKind(Value: TFrameKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    Invalidate;
  end;
end;
{ @end $48D6D4 }

{ @routine $48D6EC TFrameGI_SetColor }
procedure TFrameGI.SetColor(Value: Cardinal);
begin
  if Color <> Value then
  begin
    Color := Value;
    Invalidate;
  end;
end;
{ @end $48D6EC }

{ @routine $48D704 TFrameGI_SetFillColor }
procedure TFrameGI.SetFillColor(Value: Cardinal);
begin
  if FillColor <> Value then
  begin
    FillColor := Value;
    Invalidate;
  end;
end;
{ @end $48D704 }

{ @routine $48D71C TFrameGI_SetFill }
procedure TFrameGI.SetFill(Value: Boolean);
begin
  if Fill <> Value then
  begin
    Fill := Value;
    Invalidate;
  end;
end;
{ @end $48D71C }

{ @routine $48D734 TFrameGI_SetFillAlpha }
procedure TFrameGI.SetFillAlpha(Value: Byte);
begin
  if Value <> FillAlpha then
  begin
    FillAlpha := Value;
    Invalidate;
  end;
end;
{ @end $48D734 }

{ @routine $48D74C TFrameGI_LoadFromConfigPath }
procedure TFrameGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadFrameProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $48D74C }

{ @routine $48D778 TFrameGI_LoadFromBlock }
procedure TFrameGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadFrameProperties(Block);
end;
{ @end $48D778 }

{ @routine $48D794 TFrameGI_LoadFrameProperties }
procedure TFrameGI.LoadFrameProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Kind') > 0 then
  begin
    if Block.GetParam('Kind') = 'Hide' then Kind := fkHide
    else if Block.GetParam('Kind') = 'Rect' then Kind := fkRect;
  end;
  if Block.CountParams('Color') > 0 then SetColor(GetColorGI(Block.GetParam('Color')));
  if Block.CountParams('ColorFill') > 0 then SetFillColor(GetColorGI(Block.GetParam('ColorFill')));
  if Block.CountParams('Fill') > 0 then SetFill(ParseEnabledNameGI(Block.GetParam('Fill')));
end;
{ @end $48D794 }

{ @routine $48D930 TFrameGI_Draw }
procedure TFrameGI.Draw(ClipRect: TRect);
begin
  if Fill then
    if FillAlpha = 255 then
      OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2),
        ScreenRenderBuffer.PitchBytes, ClipRect.Right - ClipRect.Left,
        ClipRect.Bottom - ClipRect.Top, Word(FillColor))
    else
      ScreenRenderBuffer.DrawAlphaTrapezium16(HitTestBounds.Left, HitTestBounds.Right,
        HitTestBounds.Top, HitTestBounds.Left, HitTestBounds.Right, HitTestBounds.Bottom,
        Word(FillColor), 64, ClipRect);
  if Kind = fkRect then
  begin
    ScreenRenderBuffer.DrawLine16Clipped(Point(HitTestBounds.Left, HitTestBounds.Top),
      Point(HitTestBounds.Right - 1, HitTestBounds.Top), Color, ClipRect);
    ScreenRenderBuffer.DrawLine16Clipped(Point(HitTestBounds.Left, HitTestBounds.Bottom - 1),
      Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1), Color, ClipRect);
    ScreenRenderBuffer.DrawLine16Clipped(Point(HitTestBounds.Left, HitTestBounds.Top),
      Point(HitTestBounds.Left, HitTestBounds.Bottom - 1), Color, ClipRect);
    ScreenRenderBuffer.DrawLine16Clipped(Point(HitTestBounds.Right - 1, HitTestBounds.Top),
      Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1), Color, ClipRect);
  end;
end;
{ @end $48D930 }

end.

unit GI_Circle;
// Unit bracket (inferred): CODE 0x004903EC..0x004910C7; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, GR_GraphBuf, Types;

type
  TCircleKindGI = (ckSimple=0, ckCircle=1, ckFill=2, ckShrLight=3, ckMulLight=4); // @size $01
  TCircleGI = class(TObjectGI) // @size $120
  public
    Kind: TCircleKindGI; // @offset $100
    Color: Cardinal; // @offset $104
    FillColor: Cardinal; // @offset $108
    Center: TPoint; // @offset $10C
    Radius: Integer; // @offset $114
    ShrLightInner: Byte; // @offset $118
    ShrLightOuter: Byte; // @offset $119
    LightBufferDirty: Boolean; // @offset $11A
    LightBuffer: TGraphBufGR; // @offset $11C

    constructor Create(Owner: TObjectGI); // @addr $4904FC
    destructor Destroy; override; // @addr $4905B4
    procedure Clear; override; // @addr $4905DC
    procedure SetKind(Value: TCircleKindGI); // @addr $490680
    procedure SetColor(Value: Cardinal); // @addr $4906E8
    procedure SetFillColor(Value: Cardinal); // @addr $490700
    procedure SetCenter(Value: TPoint); // @addr $490718
    procedure SetRadius(Value: Integer); // @addr $490764
    procedure SetShrLightInner(Value: Byte); // @addr $490784
    procedure SetShrLightOuter(Value: Byte); // @addr $4907A4
    procedure SetSize(Size: TPoint); override; // @addr $4907C4
    procedure SetActive(Enabled: Boolean); override; // @addr $4907EC
    procedure OnActivate; override; // @addr $490820
    procedure OnDeactivate; override; // @addr $490834
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $490850
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $49087C
    procedure LoadShapeProperties(Block: TBlockParEC); // @addr $490898
    procedure Draw(ClipRect: TRect); override; // @addr $490C0C
  end;

implementation

// @unit-initialization $4910C0
// @unit-finalization $491090

uses EC_OKGF, GR_Main, GI_Main, EC_Mem, Classes, SysUtils, Math;

{ @routine $4904FC TCircleGI_Create }
constructor TCircleGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := ckSimple;
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  FillColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  Center := Classes.Point(0, 0);
  Radius := 10;
  ShrLightInner := 1;
  ShrLightOuter := 0;
  LightBufferDirty := True;
end;
{ @end $4904FC }

{ @routine $4905B4 TCircleGI_Destroy }
destructor TCircleGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $4905B4 }

{ @routine $4905DC TCircleGI_Clear }
procedure TCircleGI.Clear;
begin
  Kind := ckSimple;
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  FillColor := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  Center := Classes.Point(0, 0);
  Radius := 10;
  ShrLightInner := 1;
  ShrLightOuter := 0;
  LightBufferDirty := True;
  if LightBuffer <> nil then
  begin
    LightBuffer.Free;
    LightBuffer := nil;
  end;
  inherited Clear;
end;
{ @end $4905DC }

{ @routine $490680 TCircleGI_SetKind }
procedure TCircleGI.SetKind(Value: TCircleKindGI);
begin
  if Value <> Kind then
  begin
    Kind := Value;
    if (Kind = ckShrLight) or (Kind = ckMulLight) then
    begin
      if LightBuffer = nil then LightBuffer := TGraphBufGR.Create;
    end
    else
      if LightBuffer <> nil then
      begin
        LightBuffer.Free;
        LightBuffer := nil;
      end;
    LightBufferDirty := True;
    Invalidate;
  end;
end;
{ @end $490680 }

{ @routine $4906E8 TCircleGI_SetColor }
procedure TCircleGI.SetColor(Value: Cardinal);
begin
  if Color <> Value then
  begin
    Color := Value;
    Invalidate;
  end;
end;
{ @end $4906E8 }

{ @routine $490700 TCircleGI_SetFillColor }
procedure TCircleGI.SetFillColor(Value: Cardinal);
begin
  if FillColor <> Value then
  begin
    FillColor := Value;
    Invalidate;
  end;
end;
{ @end $490700 }

{ @routine $490718 TCircleGI_SetCenter }
procedure TCircleGI.SetCenter(Value: TPoint);
begin
  if (Center.X <> Value.X) or (Center.Y <> Value.Y) then
  begin
    Center := Value;
    LightBufferDirty := True;
    Invalidate;
  end;
end;
{ @end $490718 }

{ @routine $490764 TCircleGI_SetRadius }
procedure TCircleGI.SetRadius(Value: Integer);
begin
  if Radius <> Value then
  begin
    Radius := Value;
    LightBufferDirty := True;
    Invalidate;
  end;
end;
{ @end $490764 }

{ @routine $490784 TCircleGI_SetShrLightInner }
procedure TCircleGI.SetShrLightInner(Value: Byte);
begin
  if ShrLightInner <> Value then
  begin
    ShrLightInner := Value;
    LightBufferDirty := True;
    Invalidate;
  end;
end;
{ @end $490784 }

{ @routine $4907A4 TCircleGI_SetShrLightOuter }
procedure TCircleGI.SetShrLightOuter(Value: Byte);
begin
  if ShrLightOuter <> Value then
  begin
    ShrLightOuter := Value;
    LightBufferDirty := True;
    Invalidate;
  end;
end;
{ @end $4907A4 }

{ @routine $4907C4 TCircleGI_SetSize }
procedure TCircleGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  LightBufferDirty := True;
end;
{ @end $4907C4 }

{ @routine $4907EC TCircleGI_SetActive }
procedure TCircleGI.SetActive(Enabled: Boolean);
begin
  inherited SetActive(Enabled);
  if (not Active) and ((Kind = ckShrLight) or (Kind = ckMulLight)) and (LightBuffer <> nil) then LightBuffer.Clear;
end;
{ @end $4907EC }

{ @routine $490820 TCircleGI_OnActivate }
procedure TCircleGI.OnActivate;
begin
  inherited OnActivate;
  LightBufferDirty := True;
end;
{ @end $490820 }

{ @routine $490834 TCircleGI_OnDeactivate }
procedure TCircleGI.OnDeactivate;
begin
  inherited OnDeactivate;
  if LightBuffer <> nil then LightBuffer.Clear;
end;
{ @end $490834 }

{ @routine $490850 TCircleGI_LoadFromConfigPath }
procedure TCircleGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadShapeProperties(Block);
end;
{ @end $490850 }

{ @routine $49087C TCircleGI_LoadFromBlock }
procedure TCircleGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadShapeProperties(Block);
end;
{ @end $49087C }

{ @routine $490898 TCircleGI_LoadShapeProperties }
procedure TCircleGI.LoadShapeProperties(Block: TBlockParEC);
var Text: WideString;
begin
  if Block.CountParams('Kind') > 0 then
  begin
    Text := Block.GetParam('Kind');
    if Text = 'Simple' then SetKind(ckSimple)
    else if Text = 'Circle' then SetKind(ckCircle)
    else if Text = 'Fill' then SetKind(ckFill)
    else if Text = 'ShrLight' then SetKind(ckShrLight)
    else if Text = 'MulLight' then SetKind(ckMulLight);
  end;
  if Block.CountParams('Color') > 0 then SetColor(GetColorGI(Block.GetParam('Color')));
  if Block.CountParams('ColorFill') > 0 then SetFillColor(GetColorGI(Block.GetParam('ColorFill')));
  if Block.CountParams('Radius') > 0 then SetRadius(StrToInt(Block.GetParam('Radius')));
  if Block.CountParams('Center') > 0 then SetCenter(GetPointGI(Block.GetParam('Center')));
  if Block.CountParams('ShrLightInner') > 0 then SetShrLightInner(StrToInt(Block.GetParam('ShrLightInner')));
  if Block.CountParams('ShrLightOuter') > 0 then SetShrLightOuter(StrToInt(Block.GetParam('ShrLightOuter')));
end;
{ @end $490898 }

{ @routine $490C0C TCircleGI_Draw }
procedure TCircleGI.Draw(ClipRect: TRect);
var R: Integer; Bounds: TRect;
begin
  if Kind = ckSimple then
  begin
    R := Min(HitTestBounds.Bottom - HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left) div 2;
    if R > 0 then
      ScreenRenderBuffer.DrawCircleOutline16(Classes.Point(
        (HitTestBounds.Bottom + HitTestBounds.Top) div 2,
        (HitTestBounds.Right + HitTestBounds.Left) div 2), R, Color, ClipRect);
  end
  else if Kind = ckCircle then
  begin
    if Radius > 0 then
      ScreenRenderBuffer.DrawCircleOutline16(Center, Radius, Color, ClipRect);
  end
  else if Kind = ckFill then
  begin
    R := Min(HitTestBounds.Bottom - HitTestBounds.Top, HitTestBounds.Right - HitTestBounds.Left) div 2;
    if R > 0 then
      ScreenRenderBuffer.DrawCircle16(Classes.Point(
        (HitTestBounds.Bottom + HitTestBounds.Top) div 2,
        (HitTestBounds.Right + HitTestBounds.Left) div 2), R, Color, FillColor, ClipRect);
  end
  else if Kind = ckShrLight then
  begin
    begin
      if (LightBufferDirty = True) or (LightBuffer.Pixels = nil) then
      begin
        LightBuffer.AllocateGrayscale(ClientSize.X, ClientSize.Y);
        LightBuffer.FillPixels(ShrLightOuter);
        if Radius > 0 then
        begin
          Bounds.Left := 0;
          Bounds.Top := 0;
          Bounds.Right := ClientSize.X;
          Bounds.Bottom := ClientSize.Y;
          LightBuffer.DrawCircle8(Center, Radius, ShrLightInner, ShrLightInner, Bounds);
        end;
        LightBufferDirty := False;
      end;
      if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGR_ShrLightMask_16(AddPointerOffset(ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
        AddPointerOffset(LightBuffer.Pixels, (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes +
          (ClipRect.Left - HitTestBounds.Left)), LightBuffer.PitchBytes,
        ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top)
      else
      OKGR_ShrLightMask_15(AddPointerOffset(ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
        AddPointerOffset(LightBuffer.Pixels, (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes +
          (ClipRect.Left - HitTestBounds.Left)), LightBuffer.PitchBytes,
        ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
    end;
  end
  else if Kind = ckMulLight then
  begin
    begin
      if (LightBufferDirty = True) or (LightBuffer.Pixels = nil) then
      begin
        LightBuffer.AllocateGrayscale(ClientSize.X, ClientSize.Y);
        LightBuffer.FillPixels(ShrLightOuter);
        if Radius > 0 then
        begin
          Bounds.Left := 0;
          Bounds.Top := 0;
          Bounds.Right := ClientSize.X;
          Bounds.Bottom := ClientSize.Y;
          LightBuffer.DrawCircle8(Center, Radius, ShrLightInner, ShrLightInner, Bounds);
        end;
        LightBufferDirty := False;
      end;
      if CurrentPixelFormat.TotalChannelBits = 16 then
      OKGR_MulLightMask_16(AddPointerOffset(ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
        AddPointerOffset(LightBuffer.Pixels, (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes +
          (ClipRect.Left - HitTestBounds.Left)), LightBuffer.PitchBytes,
        ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top)
      else
      OKGR_MulLightMask_15(AddPointerOffset(ScreenRenderBuffer.Pixels,
        ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
        AddPointerOffset(LightBuffer.Pixels, (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes +
          (ClipRect.Left - HitTestBounds.Left)), LightBuffer.PitchBytes,
        ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
    end;
  end;
end;
{ @end $490C0C }

end.

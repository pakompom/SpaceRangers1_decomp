unit GI_ShrLight;
// Unit bracket (inferred): CODE 0x004910C8..0x0049164F; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, GR_GraphBuf, Types;

type
  TShrLightKindGI = (slkAll=0, slkBuffer=1); // @size $01
  TShrLightGI = class(TObjectGI) // @size $10C
  public
    Kind: TShrLightKindGI; // @offset $100
    LightShift: Integer; // @offset $104
    LightBuffer: TGraphBufGR; // @offset $108 Owned grayscale mask when Kind=slkBuffer.
    constructor Create(Owner: TObjectGI); // @addr $4911D8
    destructor Destroy; override; // @addr $491220
    procedure Clear; override; // @addr $49125C
    procedure SetKind(Value: TShrLightKindGI); // @addr $491290
    procedure SetSize(Size: TPoint); override; // @addr $491314
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $49135C
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $491388
    procedure LoadLightProperties(Block: TBlockParEC); // @addr $4913A4
    procedure Draw(ClipRect: TRect); override; // @addr $4914C0
    procedure SetLightShift(Value: Integer); // @addr $4912FC
  end;

implementation

// @unit-initialization $491648
// @unit-finalization $491618

uses EC_OKGF, EC_Mem, GR_Main, SysUtils;

{ @routine $4911D8 TShrLightGI_Create }
constructor TShrLightGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := slkAll;
  LightShift := 1;
end;
{ @end $4911D8 }

{ @routine $491220 TShrLightGI_Destroy }
destructor TShrLightGI.Destroy;
begin
  if LightBuffer <> nil then
  begin
    LightBuffer.Free;
    LightBuffer := nil;
  end;
  inherited Destroy;
end;
{ @end $491220 }

{ @routine $49125C TShrLightGI_Clear }
procedure TShrLightGI.Clear;
begin
  if LightBuffer <> nil then
  begin
    LightBuffer.Free;
    LightBuffer := nil;
  end;
  Kind := slkAll;
  LightShift := 1;
  inherited Clear;
end;
{ @end $49125C }

{ @routine $491290 TShrLightGI_SetKind }
procedure TShrLightGI.SetKind(Value: TShrLightKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    if Kind = slkBuffer then
    begin
      LightBuffer := TGraphBufGR.Create;
      LightBuffer.AllocateGrayscale(ClientSize.X, ClientSize.Y);
      LightBuffer.FillPixels(0);
    end
    else if LightBuffer <> nil then
    begin
      LightBuffer.Free;
      LightBuffer := nil;
    end;
    Invalidate;
  end;
end;
{ @end $491290 }

{ @routine $4912FC TShrLightGI_SetLightShift }
procedure TShrLightGI.SetLightShift(Value: Integer);
begin
  if LightShift <> Value then
  begin
    LightShift := Value;
    Invalidate;
  end;
end;
{ @end $4912FC }

{ @routine $491314 TShrLightGI_SetSize }
procedure TShrLightGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if Kind = slkBuffer then
  begin
    LightBuffer.AllocateGrayscale(Size.X, Size.Y);
    LightBuffer.FillPixels(0);
  end;
end;
{ @end $491314 }

{ @routine $49135C TShrLightGI_LoadFromConfigPath }
procedure TShrLightGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadLightProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $49135C }

{ @routine $491388 TShrLightGI_LoadFromBlock }
procedure TShrLightGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadLightProperties(Block);
end;
{ @end $491388 }

{ @routine $4913A4 TShrLightGI_LoadLightProperties }
procedure TShrLightGI.LoadLightProperties(Block: TBlockParEC);
var Text: WideString;
begin
  if Block.CountParams('ShrLight') > 0 then
    SetLightShift(StrToInt(AnsiString(Block.GetParam('ShrLight'))));
  if Block.CountParams('Kind') > 0 then
  begin
    Text := Block.GetParam('Kind');
    if Text = 'All' then SetKind(slkAll)
    else if Text = 'Buf' then SetKind(slkBuffer);
  end;
end;
{ @end $4913A4 }

{ @routine $4914C0 TShrLightGI_Draw }
procedure TShrLightGI.Draw(ClipRect: TRect);
var Alpha: Integer;
begin
  if Kind = slkBuffer then
  begin
    if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGR_ShrLightMask_16(AddPointerOffset(ScreenRenderBuffer.Pixels,
      ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
      AddPointerOffset(LightBuffer.Pixels,
        (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes + (ClipRect.Left - HitTestBounds.Left)),
      LightBuffer.PitchBytes, ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top)
    else
    OKGR_ShrLightMask_15(AddPointerOffset(ScreenRenderBuffer.Pixels,
      ScreenRenderBuffer.PitchBytes * ClipRect.Top + ClipRect.Left * 2), ScreenRenderBuffer.PitchBytes,
      AddPointerOffset(LightBuffer.Pixels,
        (ClipRect.Top - HitTestBounds.Top) * LightBuffer.PitchBytes + (ClipRect.Left - HitTestBounds.Left)),
      LightBuffer.PitchBytes, ClipRect.Right - ClipRect.Left, ClipRect.Bottom - ClipRect.Top);
  end
  else if Kind = slkAll then ScreenRenderBuffer.ShiftLight16(LightShift, ClipRect);
end;
{ @end $4914C0 }

end.

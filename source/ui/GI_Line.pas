unit GI_Line;
// Unit bracket (inferred): CODE 0x0048D228..0x0048D53F; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_MessageLoop, Types;

type
  TLineGI = class(TObjectGI) // @size $104
  public
    Color: Cardinal; // @offset $100

    constructor Create(Owner: TObjectGI); // @addr $48D334
    destructor Destroy; override; // @addr $48D384
    procedure Clear; override; // @addr $48D3AC
    procedure SetColor(Value: Cardinal); // @addr $48D3D4
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $48D3EC
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $48D418
    procedure LoadLineProperties(Block: TBlockParEC); // @addr $48D434
    procedure Draw(ClipRect: TRect); override; // @addr $48D4AC
  end;

implementation

// @unit-initialization $48D538
// @unit-finalization $48D508

uses Classes, GI_Main, GR_Main;

{ @routine $48D334 TLineGI_Create }
constructor TLineGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
end;
{ @end $48D334 }

{ @routine $48D384 TLineGI_Destroy }
destructor TLineGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $48D384 }

{ @routine $48D3AC TLineGI_Clear }
procedure TLineGI.Clear;
begin
  Color := CurrentPixelFormat.PackRgbBytes(255, 255, 255);
  inherited Clear;
end;
{ @end $48D3AC }

{ @routine $48D3D4 TLineGI_SetColor }
procedure TLineGI.SetColor(Value: Cardinal);
begin
  if Color <> Value then
  begin
    Color := Value;
    Invalidate;
  end;
end;
{ @end $48D3D4 }

{ @routine $48D3EC TLineGI_LoadFromConfigPath }
procedure TLineGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC;
begin
  inherited LoadFromConfigPath(Path);
  Block := UiStyleConfig.GetBlockByPath(Path);
  LoadLineProperties(Block);
end;
{ @end $48D3EC }

{ @routine $48D418 TLineGI_LoadFromBlock }
procedure TLineGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadLineProperties(Block);
end;
{ @end $48D418 }

{ @routine $48D434 TLineGI_LoadLineProperties }
procedure TLineGI.LoadLineProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Color') > 0 then Color := GetColorGI(Block.GetParam('Color'));
end;
{ @end $48D434 }

{ @routine $48D4AC TLineGI_Draw }
procedure TLineGI.Draw(ClipRect: TRect);
begin
    ScreenRenderBuffer.DrawLine16Clipped(Classes.Point(HitTestBounds.Left, HitTestBounds.Top),
      Classes.Point(HitTestBounds.Right - 1, HitTestBounds.Bottom - 1), Color, ClipRect);
end;
{ @end $48D4AC }

end.

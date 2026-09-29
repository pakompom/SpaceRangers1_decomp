unit GI_avi;
// Unit bracket (inferred): CODE 0x00481054..0x00481747; inclusive evidence, not full bounds.
// AVI control, native startup entry 143. Playback uses the OKGF decoder.
interface
uses GI_MessageLoop, GI_Main, EC_BlockPar, Types;

type
  TaviGI = class(TObjectGI) // @size $120
  public
    FrameWidth: Integer; // @offset $100
    FrameHeight: Integer; // @offset $104
    FrameCount: Integer; // @offset $108
    FramesPerSecond: Single; // @offset $10C
    Decoder: Pointer; // @offset $110
    ImageKindX: TImageKindXGI; // @offset $114
    ImageKindY: TImageKindYGI; // @offset $115
    FrameTimer: TCallbackTimerIdGI; // @offset $118
    FrameIndex: Integer; // @offset $11C
    constructor Create(Owner: TObjectGI); // @addr $481160
    destructor Destroy; override; // @addr $4811A4
    procedure Clear; override; // @addr $4811D0 @note "Preserves the open decoder and timer."
    procedure ImageOpen(const FileName: WideString); // @addr $4811D8
    procedure ImageClose; // @addr $4812A4
    procedure AdvanceFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4812CC
    procedure StartPlayback; // @addr $4812F4
    procedure StopPlayback; // @addr $481350
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $481374
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4813A0
    procedure LoadVideoProperties(Block: TBlockParEC); // @addr $4813BC
    procedure Draw(ClipRect: TRect); override; // @addr $481430 @note "CenterFill is unsupported on both axes in the native control."
    procedure DrawFrameClipped(Pixels: Pointer; Pitch, X, Y: Integer; Clip: TRect); // @addr $4815D4
  end;

implementation

// @unit-initialization $481740
// @unit-finalization $481710

uses SysUtils, Math, GR_Main;

{ @routine $481160 TaviGI_Create }
constructor TaviGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
end;
{ @end $481160 }

{ @routine $4811A4 TaviGI_Destroy }
destructor TaviGI.Destroy;
begin
  ImageClose;
  inherited Destroy;
end;
{ @end $4811A4 }

{ @routine $4811D0 TaviGI_Clear }
procedure TaviGI.Clear;
begin
  inherited Clear;
end;
{ @end $4811D0 }

{ @routine $4811D8 TaviGI_ImageOpen }
procedure TaviGI.ImageOpen(const FileName: WideString);
var AnsiFileName: AnsiString;
begin
  ImageClose;
  AnsiFileName := AnsiString(FileName);
  Decoder := OKGF_AVI_Open(PAnsiChar(AnsiFileName), FrameWidth, FrameHeight, FrameCount, FramesPerSecond);
  if Decoder = nil then raise Exception.Create('Error open AVI file.');
  FrameIndex := 0;
  StartPlayback;
end;
{ @end $4811D8 }

{ @routine $4812A4 TaviGI_ImageClose }
procedure TaviGI.ImageClose;
begin
  StopPlayback;
  if Decoder <> nil then
  begin
    OKGF_AVI_Close(Decoder);
    Decoder := nil;
  end;
end;
{ @end $4812A4 }

{ @routine $4812CC TaviGI_AdvanceFrame }
procedure TaviGI.AdvanceFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  Inc(FrameIndex);
  if FrameIndex >= FrameCount then FrameIndex := 0;
  Invalidate;
end;
{ @end $4812CC }

{ @routine $4812F4 TaviGI_StartPlayback }
procedure TaviGI.StartPlayback;
begin
  StopPlayback;
  FrameTimer := MessageLoop.ScheduleCallbackTimer(Ceil(1000 / FramesPerSecond),
    Ceil(1000 / FramesPerSecond), AdvanceFrame, 0);
end;
{ @end $4812F4 }

{ @routine $481350 TaviGI_StopPlayback }
procedure TaviGI.StopPlayback;
begin
  if FrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := 0;
  end;
end;
{ @end $481350 }

{ @routine $481374 TaviGI_LoadFromConfigPath }
procedure TaviGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadVideoProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $481374 }

{ @routine $4813A0 TaviGI_LoadFromBlock }
procedure TaviGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadVideoProperties(Block);
end;
{ @end $4813A0 }

{ @routine $4813BC TaviGI_LoadVideoProperties }
procedure TaviGI.LoadVideoProperties(Block: TBlockParEC);
begin
  if Block.CountParams('File') > 0 then ImageOpen(Block.GetParam('File'));
end;
{ @end $4813BC }

{ @routine $481430 TaviGI_Draw }
procedure TaviGI.Draw(ClipRect: TRect);
var Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
begin
  if Decoder = nil then Exit;
  Width := FrameWidth;
  Height := FrameHeight;
  if ImageKindX = ikxLeftFill then
  begin
    Left := HitTestBounds.Left;
    Right := HitTestBounds.Right;
  end
  else if ImageKindX = ikxRightFill then
  begin
    Right := HitTestBounds.Right;
    Left := Right;
    while Left > ClipRect.Left do Dec(Left, Width);
  end
  else if ImageKindX = ikxLeft then
  begin
    Left := HitTestBounds.Left;
    Right := Left + Width;
  end
  else if ImageKindX = ikxRight then
  begin
    Right := HitTestBounds.Right;
    Left := Right - Width;
  end
  else if ImageKindX = ikxCenter then
  begin
    Left := (HitTestBounds.Right - HitTestBounds.Left) div 2 + HitTestBounds.Left - Width div 2;
    Right := Left + Width;
  end
  else begin Exit; end;
  if ImageKindY = ikyTopFill then
  begin
    Top := HitTestBounds.Top;
    Bottom := HitTestBounds.Bottom;
  end
  else if ImageKindY = ikyBottomFill then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom;
    while Top > ClipRect.Top do Dec(Top, Height);
  end
  else if ImageKindY = ikyTop then
  begin
    Top := HitTestBounds.Top;
    Bottom := Top + Height;
  end
  else if ImageKindY = ikyBottom then
  begin
    Bottom := HitTestBounds.Bottom;
    Top := Bottom - Height;
  end
  else if ImageKindY = ikyCenter then
  begin
    Top := (HitTestBounds.Bottom - HitTestBounds.Top) div 2 + HitTestBounds.Top - Height div 2;
    Bottom := Top + Height;
  end
  else begin Exit; end;
  begin
  Y := Top;
  while Y < Bottom do
  begin
    X := Left;
    while X < Right do
    begin
      DrawFrameClipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, ClipRect);
      Inc(X, Width);
    end;
    Inc(Y, Height);
  end;
  end;
end;
{ @end $481430 }

{ @routine $4815D4 TaviGI_DrawFrameClipped }
procedure TaviGI.DrawFrameClipped(Pixels: Pointer; Pitch, X, Y: Integer; Clip: TRect);
var SourceX, SourceY, Width, Height: Integer;
begin
  if (X >= Clip.Right) or (Y >= Clip.Bottom) or
    (X + FrameWidth - 1 < Clip.Left) or (Y + FrameHeight - 1 < Clip.Top) then Exit;
  SourceX := 0;
  SourceY := 0;
  Width := FrameWidth;
  Height := FrameHeight;
  if (Width) + X - 1 >= Clip.Right then Dec(Width, (X) + Width - 1 - (Clip.Right - 1));
  if Y + Height - 1 >= Clip.Bottom then Dec(Height, (Y) + Height - 1 - (Clip.Bottom - 1));
  if X < Clip.Left then
  begin
    SourceX := Clip.Left - X;
    Dec(Width, SourceX);
    X := Clip.Left;
  end;
  if Y < Clip.Top then
  begin
    SourceY := Clip.Top - Y;
    Dec(Height, SourceY);
    Y := Clip.Top;
  end;
  if CurrentPixelFormat.TotalChannelBits = 16 then
    OKGF_AVI_Draw_16(Decoder, FrameIndex, SourceX, SourceY, Pixels, Pitch, X, Y, Width, Height)
  else
    OKGF_AVI_Draw_15(Decoder, FrameIndex, SourceX, SourceY, Pixels, Pitch, X, Y, Width, Height);
end;
{ @end $4815D4 }

end.

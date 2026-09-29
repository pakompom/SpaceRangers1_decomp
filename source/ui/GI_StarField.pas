unit GI_StarField;
// Unit bracket (inferred): CODE 0x00491650..0x00492453; inclusive evidence, not full bounds.

interface

uses EC_Struct, GI_Panel, GI_MessageLoop, EC_CacheGAI, EC_BlockPar, Types;

type
  TStarFieldPoint = record // @size $14
    X: Single; // @offset $00
    Y: Single; // @offset $04
    Depth: Single; // @offset $08
    InverseDepth: Single; // @offset $0C
    Color: Word; // @offset $10
  end;
  PStarFieldPoint = ^TStarFieldPoint;

  TStarFieldPixel = record // @size $08
    ByteOffset: Integer; // @offset $00
    Color: Word; // @offset $04
    SavedPixel: Word; // @offset $06
  end;
  PStarFieldPixel = ^TStarFieldPixel;

  TStarFieldList = class(TObject) // @size $10
  public
    Points: PStarFieldPoint; // @offset $04
    Count: Integer; // @offset $08
    Capacity: Integer; // @offset $0C
    constructor Create; // @addr $4917C4
    destructor Destroy; override; // @addr $4917FC
    procedure Clear; // @addr $491828
    function AllocatePoint: PStarFieldPoint; // @addr $491848 @note "Grows by 100 when incremented Count reaches Capacity."
    procedure AddPoint(AX, AY, ADepth: Single; AColor: Integer); // @addr $491888 @note "Depth must be nonzero; retains the low 16 bits of Color."
  end;

  TStarFieldGI = class(TPanelGI) // @size $168
  public
    BackgroundCache: TCGaiControlEC; // @offset $118
    Stars: TStarFieldList; // @offset $11C
    ViewPosition: TPointF; // @offset $120
    Unknown150: Integer; // @offset $128
    ViewDirty: Boolean; // @offset $12C
    Pixels: PStarFieldPixel; // @offset $130
    PixelCapacity: Integer; // @offset $134
    PixelCount: Integer; // @offset $138
    PreviousPixels: PStarFieldPixel; // @offset $13C
    PreviousPixelCount: Integer; // @offset $140
    BackgroundScale: Single; // @offset $144
    PreviousBackgroundBounds: TRect; // @offset $148
    BackgroundBounds: TRect; // @offset $158

    constructor Create(Owner: TObjectGI); // @addr $4918C4
    destructor Destroy; override; // @addr $491958
    procedure SetBackgroundImage(const Path: WideString); // @addr $4919EC
    procedure GrowPixelBuffers; // @addr $491A18
    procedure RebuildProjectedPixels; // @addr $491A58
    procedure SetViewPosition(Position: TPointF); // @addr $491B64
    procedure SetSize(Size: TPoint); override; // @addr $491BC4
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $491C04
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $491C30
    procedure LoadStarFieldProperties(Block: TBlockParEC); // @addr $491C4C
    procedure UpdateBackgroundBounds; // @addr $491CC4 @note "Updates GlobalsV.SkipSavedPixelRestore from the background rectangle change."
    procedure ErasePreviousFrame; override; // @addr $491E0C
    procedure DrawBackground(ClipRect: TRect); // @addr $491EDC
    procedure PrepareFrameDraw; override; // @addr $492224
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $492290
    procedure Invalidate; override; // @addr $491CC0 @note "Empty in native code."
    procedure Draw(ClipRect: TRect); override; // @addr $4922C8 @note "Draws all projected pixels, ignoring ClipRect."
    procedure CommitFrameDraw; override; // @addr $492318
    procedure ClearProjectedPixels; // @addr $491A0C
    procedure MarkViewDirty; // @addr $491BFC
  end;

implementation

// @unit-initialization $49244C
// @unit-finalization $49241C

uses EC_OKGF, EC_Mem, EC_Cache, GR_Main, GR_Gi, GR_GraphBuf, Classes, SysUtils, Windows;

{ @routine $4917C4 TStarFieldList_Create }
constructor TStarFieldList.Create;
begin
  inherited Create;
end;
{ @end $4917C4 }

{ @routine $4917FC TStarFieldList_Destroy }
destructor TStarFieldList.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4917FC }

{ @routine $491828 TStarFieldList_Clear }
procedure TStarFieldList.Clear;
begin
  if Points <> nil then
  begin
    FreeEC(Points);
    Points := nil;
  end;
  Capacity := 0;
  Count := 0;
end;
{ @end $491828 }

{ @routine $491848 TStarFieldList_AllocatePoint }
function TStarFieldList.AllocatePoint: PStarFieldPoint;
begin
  Inc(Count);
  if Count >= Capacity then
  begin
    Inc(Capacity, 100);
    Points := ReAllocREC(Points, Capacity * SizeOf(TStarFieldPoint));
  end;
  Result := AddPointerOffset(Points, (Count - 1) * SizeOf(TStarFieldPoint));
end;
{ @end $491848 }

{ @routine $491888 TStarFieldList_AddPoint }
procedure TStarFieldList.AddPoint(AX, AY, ADepth: Single; AColor: Integer);
begin
  with AllocatePoint^ do
  begin
    X := AX;
    Y := AY;
    Depth := ADepth;
    InverseDepth := 1.0 / ADepth;
    Color := AColor;
  end;
end;
{ @end $491888 }

{ @routine $4918C4 TStarFieldGI_Create }
constructor TStarFieldGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  BackgroundCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(BackgroundCache);
  Stars := TStarFieldList.Create;
  ViewDirty := True;
  MessageLoop.RegionDrawControl := Self;
  Unknown150 := 0;
  BackgroundScale := 8.0;
end;
{ @end $4918C4 }

{ @routine $491958 TStarFieldGI_Destroy }
destructor TStarFieldGI.Destroy;
begin
  MessageLoop.RegionDrawControl := nil;
  Stars.Free;
  if Pixels <> nil then
  begin
    FreeEC(Pixels);
    Pixels := nil;
  end;
  PixelCount := 0;
  PixelCapacity := 0;
  if PreviousPixels <> nil then
  begin
    FreeEC(PreviousPixels);
    PreviousPixels := nil;
  end;
  PreviousPixelCount := 0;
  BackgroundCache.Free;
  BackgroundCache := nil;
  inherited Destroy;
end;
{ @end $491958 }

{ @routine $4919EC TStarFieldGI_SetBackgroundImage }
procedure TStarFieldGI.SetBackgroundImage(const Path: WideString);
begin
  inherited Invalidate;
  BackgroundCache.SetCacheKey(Path);
end;
{ @end $4919EC }

{ @routine $491A0C TStarFieldGI_ClearProjectedPixels }
procedure TStarFieldGI.ClearProjectedPixels;
begin
  PixelCount := 0;
end;
{ @end $491A0C }

{ @routine $491A18 TStarFieldGI_GrowPixelBuffers }
procedure TStarFieldGI.GrowPixelBuffers;
begin
  Inc(PixelCapacity, 64);
  Pixels := ReAllocREC(Pixels, PixelCapacity * SizeOf(TStarFieldPixel));
  PreviousPixels := ReAllocREC(PreviousPixels, PixelCapacity * SizeOf(TStarFieldPixel));
end;
{ @end $491A18 }

{ @routine $491A58 TStarFieldGI_RebuildProjectedPixels }
procedure TStarFieldGI.RebuildProjectedPixels;
var
  Point: PStarFieldPoint;
  Pixel: PStarFieldPixel;
  Position: TPoint;
  Left, Top, Right, Bottom, I, Pitch: Integer;
begin
  ClearProjectedPixels;
  Pitch := ScreenRenderBuffer.PitchBytes;
  Left := HitTestBounds.Left;
  Top := HitTestBounds.Top;
  Right := HitTestBounds.Right;
  Bottom := HitTestBounds.Bottom;
  Point := Stars.Points;
  for I := 0 to Stars.Count - 1 do
  begin
    Position.X := Integer(Round((Point.X - ViewPosition.X) * Point.InverseDepth)) + AbsolutePosition.X;
    Position.Y := Integer(Round((Point.Y - ViewPosition.Y) * Point.InverseDepth)) + AbsolutePosition.Y;
    if (Position.X >= Left) and (Position.X < Right) and (Position.Y >= Top) and (Position.Y < Bottom) then
    begin
      Inc(PixelCount);
      if PixelCount > PixelCapacity then GrowPixelBuffers;
      Pixel := AddPointerOffset(Pixels, (PixelCount - 1) * SizeOf(TStarFieldPixel));
      Pixel.ByteOffset := Position.X * 2 + Position.Y * Pitch;
      Pixel.Color := Point.Color;
    end;
    Point := AddPointerOffset(Point, SizeOf(TStarFieldPoint));
  end;
end;
{ @end $491A58 }

{ @routine $491B64 TStarFieldGI_SetViewPosition }
procedure TStarFieldGI.SetViewPosition(Position: TPointF);
begin
  if (ViewPosition.X <> Position.X) or (ViewPosition.Y <> Position.Y) then
  begin
    Invalidate;
    ViewPosition := Position;
    ViewDirty := True;
    Invalidate;
  end;
end;
{ @end $491B64 }

{ @routine $491BC4 TStarFieldGI_SetSize }
procedure TStarFieldGI.SetSize(Size: TPoint);
begin
  if (ClientSize.X <> Size.X) or (ClientSize.Y <> Size.Y) then
  begin
    inherited SetSize(Size);
    ViewDirty := True;
  end;
end;
{ @end $491BC4 }

{ @routine $491BFC TStarFieldGI_MarkViewDirty }
procedure TStarFieldGI.MarkViewDirty;
begin
  ViewDirty := True;
end;
{ @end $491BFC }

{ @routine $491C04 TStarFieldGI_LoadFromConfigPath }
procedure TStarFieldGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadStarFieldProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $491C04 }

{ @routine $491C30 TStarFieldGI_LoadFromBlock }
procedure TStarFieldGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadStarFieldProperties(Block);
end;
{ @end $491C30 }

{ @routine $491C4C TStarFieldGI_LoadStarFieldProperties }
procedure TStarFieldGI.LoadStarFieldProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then SetBackgroundImage(Block.GetParam('Image'));
end;
{ @end $491C4C }

{ @routine $491CC0 TStarFieldGI_Invalidate }
procedure TStarFieldGI.Invalidate;
begin
end;
{ @end $491CC0 }

{ @routine $491CC4 TStarFieldGI_UpdateBackgroundBounds }
procedure TStarFieldGI.UpdateBackgroundBounds;
var Data: TCGaiEC; X, Y, Width, Height: Integer; Bounds: TRect;
begin
  SkipSavedPixelRestore := False;
  if BGImage then
    if BackgroundCache.CacheKey <> '' then
    begin
      SkipSavedPixelRestore := True;
      Data := AcquireCachedGai(BackgroundCache);
      try
        Bounds := Data.GetBoundsRect;
      finally
        BackgroundCache.Release;
      end;
      Width := Bounds.Right - Bounds.Left;
      Height := Bounds.Bottom - Bounds.Top;
      X := Integer(Round((0.0 - ViewPosition.X) / BackgroundScale)) + AbsolutePosition.X - Width div 2;
      Y := Integer(Round((0.0 - ViewPosition.Y) / BackgroundScale)) + AbsolutePosition.Y - Height div 2;
      Bounds.Left := X;
      Bounds.Top := Y;
      Bounds.Right := X + Width;
      Bounds.Bottom := Y + Height;
      BackgroundBounds := Bounds;
      SkipSavedPixelRestore := not CompareMem(@BackgroundBounds, @PreviousBackgroundBounds, SizeOf(TRect));
    end;
end;
{ @end $491CC4 }

{ @routine $491E0C TStarFieldGI_ErasePreviousFrame }
procedure TStarFieldGI.ErasePreviousFrame;
var Pixel: PStarFieldPixel; Buffer: Pointer; I: Integer;
begin
  if ViewDirty then
  begin
    RebuildProjectedPixels;
    ViewDirty := False;
  end;
  begin
    Buffer := ScreenRenderBuffer.Pixels;
    if not SkipSavedPixelRestore then
    begin
      if (not BGImage) or (BackgroundCache.CacheKey = '') then
      begin
        Pixel := PreviousPixels;
        for I := 0 to PreviousPixelCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), 0);
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end
      else
      begin
        Pixel := PreviousPixels;
        for I := 0 to PreviousPixelCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), Pixel.SavedPixel);
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end;
    end;
  end;
end;
{ @end $491E0C }

{ @routine $491EDC TStarFieldGI_DrawBackground }
procedure TStarFieldGI.DrawBackground(ClipRect: TRect);
var
  I, X, Y, Width, Height: Integer;
  Data: TCGaiEC;
  Frame: TgiGR;
  Intersection, Bounds: TRect;
begin
  if (not BGImage) or (BackgroundCache.CacheKey = '') or
    (BackgroundBounds.Top >= ClipRect.Bottom) or (BackgroundBounds.Bottom <= ClipRect.Top) or
    (BackgroundBounds.Left >= ClipRect.Right) or (BackgroundBounds.Right <= ClipRect.Left) then
  begin
    X := ClipRect.Left;
    Y := ClipRect.Top;
    Width := ClipRect.Right - X;
    Height := ClipRect.Bottom - Y;
    OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes * Y + X * 2), ScreenRenderBuffer.PitchBytes, Width, Height, 0);
  end
  else
  begin
    if BackgroundBounds.Top > ClipRect.Top then
    begin
      X := ClipRect.Left;
      Y := ClipRect.Top;
      Width := ClipRect.Right - ClipRect.Left;
      Height := BackgroundBounds.Top - ClipRect.Top;
      OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes * Y + X * 2), ScreenRenderBuffer.PitchBytes, Width, Height, 0);
    end;
    if BackgroundBounds.Bottom < ClipRect.Bottom then
    begin
      X := ClipRect.Left;
      Y := BackgroundBounds.Bottom;
      Width := ClipRect.Right - ClipRect.Left;
      Height := ClipRect.Bottom - BackgroundBounds.Bottom;
      OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes * Y + X * 2), ScreenRenderBuffer.PitchBytes, Width, Height, 0);
    end;
    if BackgroundBounds.Left > ClipRect.Left then
    begin
      X := ClipRect.Left;
      Y := BackgroundBounds.Top;
      if Y < ClipRect.Top then Y := ClipRect.Top;
      Width := BackgroundBounds.Left - ClipRect.Left;
      Height := BackgroundBounds.Bottom;
      if Height > ClipRect.Bottom then Height := ClipRect.Bottom;
      Height := Height - Y;
      OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes * Y + X * 2), ScreenRenderBuffer.PitchBytes, Width, Height, 0);
    end;
    if BackgroundBounds.Right < ClipRect.Right then
    begin
      X := BackgroundBounds.Right;
      Y := BackgroundBounds.Top;
      if Y < ClipRect.Top then Y := ClipRect.Top;
      Width := ClipRect.Right - BackgroundBounds.Right;
      Height := BackgroundBounds.Bottom;
      if Height > ClipRect.Bottom then Height := ClipRect.Bottom;
      Height := Height - Y;
      OKGR_Fill_WORD(AddPointerOffset(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes * Y + X * 2), ScreenRenderBuffer.PitchBytes, Width, Height, 0);
    end;
    Data := AcquireCachedGai(BackgroundCache);
    try
      for I := 0 to Data.GetFrameCount - 1 do
      begin
        Frame := Data.LoadFrameGi(I);
        Bounds := Frame.GetBoundsRect;
        Inc(Bounds.Left, BackgroundBounds.Left);
        Inc(Bounds.Top, BackgroundBounds.Top);
        Inc(Bounds.Right, BackgroundBounds.Left);
        Inc(Bounds.Bottom, BackgroundBounds.Top);
        if IntersectRects(Intersection, ClipRect, Bounds) then
        begin
          Frame.DrawToGraphBuf(ScreenRenderBuffer, Bounds.Left, Bounds.Top, Intersection, 0);
        end;
      end;
    finally
      BackgroundCache.Release;
    end;
  end;
end;
{ @end $491EDC }

{ @routine $492224 TStarFieldGI_PrepareFrameDraw }
procedure TStarFieldGI.PrepareFrameDraw;
var Pixel: PStarFieldPixel; I: Integer; Buffer: Pointer;
begin
  if BGImage then
      if BackgroundCache.CacheKey <> '' then
      begin
        Buffer := ScreenRenderBuffer.Pixels;
        Pixel := Pixels;
        for I := 0 to PixelCount - 1 do
        begin
          Pixel.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset));
          Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
        end;
      end;
end;
{ @end $492224 }

{ @routine $492290 TStarFieldGI_DrawUpdateRects }
procedure TStarFieldGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $492290 }

{ @routine $4922C8 TStarFieldGI_Draw }
procedure TStarFieldGI.Draw(ClipRect: TRect);
var Pixel: PStarFieldPixel; Buffer: Pointer; I: Integer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pixel := Pixels;
  for I := 0 to PixelCount - 1 do
  begin
    WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), Pixel.Color);
    Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
  end;
end;
{ @end $4922C8 }

{ @routine $492318 TStarFieldGI_CommitFrameDraw }
procedure TStarFieldGI.CommitFrameDraw;
var Pixel: PStarFieldPixel; I: Integer; Source, Dest: Pointer;
begin
  if not SkipSavedPixelRestore then
  begin
    Source := ScreenRenderBuffer.Pixels;
    Dest := ScreenPresentBuffer.Pixels;
    Pixel := PreviousPixels;
    for I := 0 to PreviousPixelCount - 1 do
    begin
      WriteWordEC(AddPointerOffset(Dest, Pixel.ByteOffset), ReadWordEC(AddPointerOffset(Source, Pixel.ByteOffset)));
      Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
    end;
    Pixel := Pixels;
    for I := 0 to PixelCount - 1 do
    begin
      WriteWordEC(AddPointerOffset(Dest, Pixel.ByteOffset), ReadWordEC(AddPointerOffset(Source, Pixel.ByteOffset)));
      Pixel := AddPointerOffset(Pixel, SizeOf(TStarFieldPixel));
    end;
  end;
  PreviousPixelCount := PixelCount;
  CopyMemory(PreviousPixels, Pixels, PreviousPixelCount * SizeOf(TStarFieldPixel));
  PreviousBackgroundBounds := BackgroundBounds;
end;
{ @end $492318 }

end.

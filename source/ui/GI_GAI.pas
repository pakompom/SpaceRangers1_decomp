unit GI_GAI;
// Unit bracket (inferred): CODE 0x004705DC..0x00472C1B; inclusive evidence, not full bounds.

interface

uses Types, GR_GraphBuf, GI_Main, EC_CacheGI, EC_CacheGAI, EC_BlockPar, Classes, GI_MessageLoop;

type
  TgaiGI = class(TObjectGI) // @size $150 @fieldpadding explicit @methodorder source
  public
    procedure Clear; override; // @addr $470890 @note "Preserves animation state."
    procedure SetSize(Size: TPoint); override; // @addr $470D08
    procedure SetActive(Value: Boolean); override; // @addr $47158C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $471644
    procedure OnDeactivate; override; // @addr $471604
    procedure Invalidate; override; // @addr $471D38
    procedure Draw(ClipRect: TRect); override; // @addr $472204
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $471670
    procedure UpdateAutoGeometry; override; // @addr $471A58 @note "Also rebuilds frame tables when SequenceIndex is nonnegative."

    MainImageCache: TCGaiControlEC; // @offset $100
    FirstFrameImageCache: TCGiControlEC; // @offset $104
    AutoFrameTimer: TCallbackTimerIdGI; // @offset $108
    ImageKindX: TImageKindXGI; // @offset $10C
    ImageKindY: TImageKindYGI; // @offset $10D
    // Playback position is within the selected sequence, not the source image.
    SequenceFrame: Integer; // @offset $110
    SequenceFrameCount: Integer; // @offset $114
    SequenceFrameIndexTable: ^Integer; // @offset $118
    SequenceFrameDelayTable: ^Integer; // @offset $11C
    SequenceIndex: Integer; // @offset $120
    UsesPlaybackBuffer: Boolean; // @offset $124
    CachedPlaybackGraphBuf: TGraphBufGR; // @offset $128
    LastCachedFrameIndex: Integer; // @offset $12C
    TransparentColor: Cardinal; // @offset $130
    CycleCompleteCallback: TObjectNotifyEventGI; // @offset $138
    FrameAdvancedCallback: TObjectNotifyEventGI; // @offset $140
    SkipImageUpdateRect: Boolean; // @offset $148
    StopPlaybackRequested: Boolean; // @offset $149
    FirstFrameOnly: Boolean; // @offset $14A
    AutoUpdateFlags: Cardinal; // @offset $14C

    constructor Create(Owner: TObjectGI); // @addr $4706E8
    destructor Destroy; override; // @addr $4707D0
    procedure SetImagePath(const ImagePath: WideString); // @addr $470898 @note "Resets sequence position even when the key is unchanged."
    function GetImagePath: WideString; // @addr $4708EC
    procedure SetFirstFrameImagePath(const ImagePath: WideString); // @addr $470908
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $472B30
    procedure SetSequenceFrame(FrameInSequence: Integer); // @addr $470988 @note "Does not validate the index."
    function GetMainImageFrameCount: Integer; // @addr $4709F4 @note "Returns zero in FirstFrameOnly mode."
    procedure StopAutoPlayback; // @addr $470A60
    procedure RestartPlayback; // @addr $470A88 @note "Does not reset frame position; single-frame sequences remain timer-free."
    function GetContentSize: TPoint; // @addr $470AF0
    function GetContentOrigin: TPoint; // @addr $470BD8
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $470CD8
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $470CF0
    procedure ClearFrameSequence; // @addr $470D20
    procedure LoadFrameSequenceFromText(const FrameSpec: WideString); // @addr $470D74 @note "Accepts ascending and descending ranges; changes the playback timer unless stopped."
    function GetSequenceCount: Integer; // @addr $470F90
    function GetSequenceFrameSourceIndex(FrameInSequence: Integer): Integer; // @addr $470FFC @note "Does not validate the index."
    procedure SetFrameDelay(FrameInSequence, DelayMs: Integer); // @addr $471024 @note "Does not validate the index."
    function GetFrameDelay(FrameInSequence: Integer): Integer; // @addr $471050 @note "Does not validate the index."
    function HitTestPixel(Point: TPoint): Boolean; // @addr $471078 @note "Black pixels do not count as hits; composed playback may require an existing composition buffer."
    procedure LoadAnimationProperties(Block: TBlockParEC); // @addr $47168C
    procedure AdvanceAutoFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $471C54
    procedure PreloadImages; // @addr $472AEC
    procedure AdvanceToSequenceFrame(FrameInSequence: Integer; ForwardOnly: Boolean); // @addr $4709B4
  end;

var
  GaiFrameHeap: Cardinal = 0; // @addr $617F18

procedure LoadGaiFrameToGraphBuf(const Path: WideString; GraphBuf: TGraphBufGR; Seed: Cardinal); // @addr $472B3C

implementation

// @unit-initialization $472C14
// @unit-finalization $472BE4

uses GR_Sound, EC_Struct, GR_gi, GR_Main, EC_Cache, EC_Str, EC_Mem, SysUtils, Windows, aMyFunction;

{ @routine $4706E8 TgaiGI_Create }
constructor TgaiGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  if GaiFrameHeap = 0 then
  begin
    GaiFrameHeap := HeapCreate(0, $8000, 0);
    if GaiFrameHeap = 0 then raise Exception.Create('TgaiGI.HeapCreate');
  end;
  MainImageCache := TCGaiControlEC.Create;
  GlobalCache.ResetControl(MainImageCache);
  ImageKindX := ikxCenter;
  ImageKindY := ikyCenter;
  StopPlaybackRequested := False;
  SequenceIndex := -1;
  TransparentColor := 0;
  SkipImageUpdateRect := False;
end;
{ @end $4706E8 }

{ @routine $4707D0 TgaiGI_Destroy }
destructor TgaiGI.Destroy;
begin
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
  MainImageCache.Free;
  MainImageCache := nil;
  if FirstFrameImageCache <> nil then
  begin
    FirstFrameImageCache.Free;
    FirstFrameImageCache := nil;
  end;
  if SequenceFrameIndexTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameIndexTable);
    SequenceFrameIndexTable := nil;
  end;
  if SequenceFrameDelayTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameDelayTable);
    SequenceFrameDelayTable := nil;
  end;
  inherited Destroy;
end;
{ @end $4707D0 }

{ @routine $470890 TgaiGI_Clear }
procedure TgaiGI.Clear;
begin
  inherited Clear;
end;
{ @end $470890 }

{ @routine $470898 TgaiGI_SetImagePath }
procedure TgaiGI.SetImagePath(const ImagePath: WideString);
begin
  SequenceFrame := 0;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if MainImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    MainImageCache.SetCacheKey(ImagePath);
  end;
end;
{ @end $470898 }

{ @routine $4708EC TgaiGI_GetImagePath }
function TgaiGI.GetImagePath: WideString;
begin
  Result := MainImageCache.CacheKey;
end;
{ @end $4708EC }

{ @routine $470908 TgaiGI_SetFirstFrameImagePath }
procedure TgaiGI.SetFirstFrameImagePath(const ImagePath: WideString);
begin
  SequenceFrame := 0;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  if FirstFrameImageCache = nil then
  begin
    FirstFrameImageCache := TCGiControlEC.Create;
    GlobalCache.ResetControl(FirstFrameImageCache);
  end;
  if FirstFrameImageCache.CacheKey <> ImagePath then
  begin
    Invalidate;
    FirstFrameImageCache.SetCacheKey(ImagePath);
  end;
end;
{ @end $470908 }

{ @routine $470988 TgaiGI_SetSequenceFrame }
procedure TgaiGI.SetSequenceFrame(FrameInSequence: Integer);
begin
  SequenceFrame := FrameInSequence;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  Invalidate;
end;
{ @end $470988 }

{ @routine $4709B4 TgaiGI_AdvanceToSequenceFrame }
procedure TgaiGI.AdvanceToSequenceFrame(FrameInSequence: Integer; ForwardOnly: Boolean);
begin
  if (FrameInSequence <> SequenceFrame) and not ((SequenceFrame >= Integer(FrameInSequence)) and ForwardOnly) then
  begin
    SequenceFrame := FrameInSequence;
    if (SequenceFrame < 0) or (SequenceFrame >= SequenceFrameCount) then SequenceFrame := 0;
    Invalidate;
  end;
end;
{ @end $4709B4 }

{ @routine $4709F4 TgaiGI_GetMainImageFrameCount }
function TgaiGI.GetMainImageFrameCount: Integer;
var Image: TCGaiEC;
begin
  if FirstFrameOnly then
  begin
    Result := 0;
    Exit;
  end;
  Image := AcquireCachedGai(MainImageCache);
  try
    Result := Image.GetFrameCount;
  finally
    MainImageCache.Release;
  end;
end;
{ @end $4709F4 }

{ @routine $470A60 TgaiGI_StopAutoPlayback }
procedure TgaiGI.StopAutoPlayback;
begin
  StopPlaybackRequested := True;
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
end;
{ @end $470A60 }

{ @routine $470A88 TgaiGI_RestartPlayback }
procedure TgaiGI.RestartPlayback;
var Delay: Integer;
begin
  StopPlaybackRequested := False;
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
  if (SequenceFrameCount > 1) and (GetMainImageFrameCount > 1) then
  begin
    Delay := GetFrameDelay(SequenceFrame);
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(Delay, Delay, AdvanceAutoFrame);
  end;
end;
{ @end $470A88 }

{ @routine $470AF0 TgaiGI_GetContentSize }
function TgaiGI.GetContentSize: TPoint;
var Image: TCGaiEC; First: TCGiEC;
begin
  if MainImageCache.CacheKey = '' then
  begin
    Result := Classes.Point(0, 0);
    Exit;
  end;
  if not FirstFrameOnly then
  begin
    Image := AcquireCachedGai(MainImageCache);
    try
      Result := Image.GetCanvasSize;
    finally
      MainImageCache.Release;
    end;
  end
  else if FirstFrameImageCache <> nil then
  begin
    First := AcquireCachedGi(FirstFrameImageCache);
    try
      Result := First.Image.GetContentSize;
    finally
      FirstFrameImageCache.Release;
    end;
  end
  else Result := Classes.Point(0, 0);
end;
{ @end $470AF0 }

{ @routine $470BD8 TgaiGI_GetContentOrigin }
function TgaiGI.GetContentOrigin: TPoint;
var Image: TCGaiEC; First: TCGiEC;
begin
  if MainImageCache.CacheKey = '' then
  begin
    Result := Classes.Point(0, 0);
    Exit;
  end;
  if not FirstFrameOnly then
  begin
    Image := AcquireCachedGai(MainImageCache);
    try
      Result := Image.GetBoundsRect.TopLeft;
    finally
      MainImageCache.Release;
    end;
  end
  else if FirstFrameImageCache <> nil then
  begin
    First := AcquireCachedGi(FirstFrameImageCache);
    try
      Result := First.Image.GetBoundsRect.TopLeft;
    finally
      FirstFrameImageCache.Release;
    end;
  end
  else Result := Classes.Point(0, 0);
end;
{ @end $470BD8 }

{ @routine $470CD8 TgaiGI_SetImageKindX }
procedure TgaiGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    Invalidate;
  end;
end;
{ @end $470CD8 }

{ @routine $470CF0 TgaiGI_SetImageKindY }
procedure TgaiGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    Invalidate;
  end;
end;
{ @end $470CF0 }

{ @routine $470D08 TgaiGI_SetSize }
procedure TgaiGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
end;
{ @end $470D08 }

{ @routine $470D20 TgaiGI_ClearFrameSequence }
procedure TgaiGI.ClearFrameSequence;
begin
  if SequenceFrameIndexTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameIndexTable);
    SequenceFrameIndexTable := nil;
  end;
  if SequenceFrameDelayTable <> nil then
  begin
    FreeFromHeapEC(GaiFrameHeap, SequenceFrameDelayTable);
    SequenceFrameDelayTable := nil;
  end;
  SequenceFrame := 0;
  SequenceFrameCount := 0;
end;
{ @end $470D20 }

{ @routine $470D74 TgaiGI_LoadFrameSequenceFromText }
procedure TgaiGI.LoadFrameSequenceFromText(const FrameSpec: WideString);
var Part: WideString; Index, Count, Offset, RangeCount, Delay, First, Last, TimerDelay: Integer;
begin
  ClearFrameSequence;
  Count := (CountDelimitedPartsW(FrameSpec, '[]') - 1) div 2;
  for Index := 0 to Count - 1 do
  begin
    Part := ExtractDelimitedPartW(FrameSpec, Index * 2 + 1, '[]');
    Delay := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 0, ',-'));
    First := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 1, ',-'));
    Last := ExtractDigitsToIntW(ExtractDelimitedPartW(Part, 2, ',-'));
    RangeCount := Abs(First - Last) + 1;
    Inc(SequenceFrameCount, RangeCount);
    SequenceFrameIndexTable := ReAllocFromHeapREC(GaiFrameHeap, SequenceFrameIndexTable, SequenceFrameCount * SizeOf(Integer));
    SequenceFrameDelayTable := ReAllocFromHeapREC(GaiFrameHeap, SequenceFrameDelayTable, SequenceFrameCount * SizeOf(Integer));
    for Offset := 0 to RangeCount - 1 do
    begin
      WriteInt32EC(AddPointerOffset(SequenceFrameIndexTable, (SequenceFrameCount - RangeCount + Offset) * SizeOf(Integer)), First);
      WriteInt32EC(AddPointerOffset(SequenceFrameDelayTable, (SequenceFrameCount - RangeCount + Offset) * SizeOf(Integer)), Delay);
      if First < Last then Inc(First) else Dec(First);
    end;
  end;
  if not StopPlaybackRequested then
  begin
    TimerDelay := GetFrameDelay(SequenceFrame);
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(TimerDelay, TimerDelay, AdvanceAutoFrame);
  end;
end;
{ @end $470D74 }

{ @routine $470F90 TgaiGI_GetSequenceCount }
function TgaiGI.GetSequenceCount: Integer;
var Image: TCGaiEC;
begin
  if FirstFrameOnly then
  begin
    Result := 0;
    Exit;
  end;
  Image := AcquireCachedGai(MainImageCache);
  try
    Result := Image.GetSequenceCount;
  finally
    MainImageCache.Release;
  end;
end;
{ @end $470F90 }

{ @routine $470FFC TgaiGI_GetSequenceFrameSourceIndex }
function TgaiGI.GetSequenceFrameSourceIndex(FrameInSequence: Integer): Integer;
begin
  Result := ReadIntegerEC(AddPointerOffset(SequenceFrameIndexTable, FrameInSequence * SizeOf(Integer)));
end;
{ @end $470FFC }

{ @routine $471024 TgaiGI_SetFrameDelay }
procedure TgaiGI.SetFrameDelay(FrameInSequence, DelayMs: Integer);
begin
  WriteInt32EC(AddPointerOffset(SequenceFrameDelayTable, FrameInSequence * SizeOf(Integer)), DelayMs);
end;
{ @end $471024 }

{ @routine $471050 TgaiGI_GetFrameDelay }
function TgaiGI.GetFrameDelay(FrameInSequence: Integer): Integer;
begin
  Result := ReadIntegerEC(AddPointerOffset(SequenceFrameDelayTable, FrameInSequence * SizeOf(Integer)));
end;
{ @end $471050 }

{ @routine $471078 TgaiGI_HitTestPixel }
function TgaiGI.HitTestPixel(Point: TPoint): Boolean;
var
  Image: TCGaiEC;
  First: TCGiEC;
  Width, Height, Left, Right, X, Top, Bottom, Y: Integer;
  Pixel: Cardinal;
  Pixels: Pointer;
  Buffer: TGraphBufGR;
  Frame: TgiGR;
  Clip, Bounds, FirstBounds: TRect;
begin
  Pixel := 0;
  Clip.Left := Point.X;
  Clip.Top := Point.Y;
  Clip.Right := Point.X + 1;
  Clip.Bottom := Point.Y + 1;
  Image := nil;
  First := nil;
  try
    if not FirstFrameOnly then Image := AcquireCachedGai(MainImageCache);
    if FirstFrameImageCache <> nil then First := AcquireCachedGi(FirstFrameImageCache);
    if Image <> nil then
    begin
      Width := Image.GetCanvasSize.X;
      Height := Image.GetCanvasSize.Y;
      if First <> nil then
      begin
        FirstBounds := First.Image.GetBoundsRect;
        UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
        if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then RaiseWideMessage('TgaiGI.Draw Pos-Size');
        Width := FirstBounds.Right - FirstBounds.Left;
        Height := FirstBounds.Bottom - FirstBounds.Top;
        if First.Image.GetFormat <> 0 then RaiseWideMessage('TgaiGI.Draw Format gi not 0');
      end;
    end
    else if First <> nil then
    begin
      FirstBounds := First.Image.GetBoundsRect;
      Width := FirstBounds.Right - FirstBounds.Left;
      Height := FirstBounds.Bottom - FirstBounds.Top;
      if First.Image.GetFormat <> 0 then RaiseWideMessage('TgaiGI.Draw Format gi not 0');
    end
    else
    begin
      Width := 0;
      Height := 0;
    end;
    if ImageKindX = ikxLeftFill then
    begin
      Left := HitTestBounds.Left;
      Right := HitTestBounds.Right;
    end
    else if ImageKindX = ikxRightFill then
    begin
      Right := HitTestBounds.Right;
      Left := Right;
      while Left > Clip.Left do Dec(Left, Width);
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
    else begin Result := False; Exit; end;
    if ImageKindY = ikyTopFill then
    begin
      Top := HitTestBounds.Top;
      Bottom := HitTestBounds.Bottom;
    end
    else if ImageKindY = ikyBottomFill then
    begin
      Bottom := HitTestBounds.Bottom;
      Top := Bottom;
      while Top > Clip.Top do Dec(Top, Height);
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
    else begin Result := False; Exit; end;
    Pixels := AddPointerOffset(@Pixel, -(ScreenRenderBuffer.PitchBytes * Point.Y + Point.X * SizeOf(Word)));
    Buffer := TGraphBufGR.Create;
    Buffer.AttachPixels(1, 1, ScreenRenderBuffer.PitchBytes, Pixels);
    if Image <> nil then Bounds := Image.GetBoundsRect;
    if (Image <> nil) and (not Image.HasPlaybackFlags) then
    begin
      Y := Top;
      while Y < Bottom do
      begin
        X := Left;
        while X < Right do
        begin
          Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(SequenceFrame));
          Frame.DrawToGraphBuf(Buffer, X + Frame.GetBoundsRect.Left - Bounds.Left, Y + Frame.GetBoundsRect.Top - Bounds.Top, Clip, 0);
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end
    else if (FirstFrameImageCache <> nil) and (CachedPlaybackGraphBuf <> nil) and
      (CachedPlaybackGraphBuf.Width = Width) and (CachedPlaybackGraphBuf.Height = Height) then
    begin
      Y := Top;
      while Y < Bottom do
      begin
        X := Left;
        while X < Right do
        begin
          DrawAlphaGraphBuffer16Clipped(Buffer.Pixels, Buffer.PitchBytes, X, Y, CachedPlaybackGraphBuf, Clip);
          Inc(X, Width);
        end;
        Inc(Y, Height);
      end;
    end;
    Buffer.Free;
  finally
    if Image <> nil then MainImageCache.Release;
    if First <> nil then FirstFrameImageCache.Release;
  end;
  Result := Pixel <> 0;
end;
{ @end $471078 }

{ @routine $47158C TgaiGI_SetActive }
procedure TgaiGI.SetActive(Value: Boolean);
begin
  if Active <> Value then
  begin
    inherited SetActive(Value);
    if not Value then
    begin
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
      Active := True;
      inherited Invalidate;
      Active := False;
    end
    else
    begin
      if not StopPlaybackRequested then RestartPlayback;
      inherited Invalidate;
    end;
  end;
end;
{ @end $47158C }

{ @routine $471604 TgaiGI_OnDeactivate }
procedure TgaiGI.OnDeactivate;
begin
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
  if CachedPlaybackGraphBuf <> nil then
  begin
    CachedPlaybackGraphBuf.Free;
    CachedPlaybackGraphBuf := nil;
  end;
  inherited OnDeactivate;
end;
{ @end $471604 }

{ @routine $471644 TgaiGI_LoadFromConfigPath }
procedure TgaiGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadAnimationProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $471644 }

{ @routine $471670 TgaiGI_LoadFromBlock }
procedure TgaiGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadAnimationProperties(Block);
end;
{ @end $471670 }

{ @routine $47168C TgaiGI_LoadAnimationProperties }
procedure TgaiGI.LoadAnimationProperties(Block: TBlockParEC);
begin
  if Block.CountParams('Image') > 0 then MainImageCache.SetCacheKey(Block.GetParam('Image'));
  if Block.CountParams('ImageFirst') > 0 then SetFirstFrameImagePath(Block.GetParam('ImageFirst'));
  if Block.CountParams('KindX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('KindX')));
  if Block.CountParams('KindY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('KindY')));
  if Block.CountParams('AlignX') > 0 then SetImageKindX(ParseImageKindXName(Block.GetParam('AlignX')));
  if Block.CountParams('AlignY') > 0 then SetImageKindY(ParseImageKindYName(Block.GetParam('AlignY')));
  if Block.CountParams('PBuf') > 0 then UsesPlaybackBuffer := ParseEnabledNameGI(Block.GetParam('PBuf'));
  if Block.CountParams('Stop') > 0 then StopPlaybackRequested := ParseEnabledNameGI(Block.GetParam('Stop'));
  if Block.CountParams('Frame') > 0 then LoadFrameSequenceFromText(Block.GetParam('Frame'));
  if Block.CountParams('FrameLoad') > 0 then SequenceIndex := StrToInt(Block.GetParam('FrameLoad'));
  if Block.CountParams('Auto') > 0 then AutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
  if Block.CountParams('TransColor') > 0 then TransparentColor := GetColorGI(Block.GetParam('TransColor'));
  if Block.CountParams('SkipImageUpdateRect') > 0 then SkipImageUpdateRect := ParseEnabledNameGI(Block.GetParam('SkipImageUpdateRect'));
end;
{ @end $47168C }

{ @routine $471A58 TgaiGI_UpdateAutoGeometry }
procedure TgaiGI.UpdateAutoGeometry;
var Image: TCGaiEC;
begin
  if (AutoUpdateFlags and agfPosition) = agfPosition then SetPosition(Parent.ToLocalPoint(GetContentOrigin));
  if (AutoUpdateFlags and agfSize) = agfSize then SetSize(GetContentSize);
  if SequenceIndex >= 0 then
  begin
    ClearFrameSequence;
    if (not FirstFrameOnly) and (MainImageCache <> nil) and (MainImageCache.CacheKey <> '') then
    begin
      Image := AcquireCachedGai(MainImageCache);
      try
        if (SequenceIndex < 0) or (SequenceIndex >= Image.GetSequenceCount) then
          raise Exception.Create('TgaiGI.AfterLoad. Anim not found.');
        SequenceFrameCount := Image.GetSequenceFrameCount(SequenceIndex);
        SequenceFrameIndexTable := ReAllocFromHeapREC(GaiFrameHeap, SequenceFrameIndexTable, SequenceFrameCount * SizeOf(Integer));
        SequenceFrameDelayTable := ReAllocFromHeapREC(GaiFrameHeap, SequenceFrameDelayTable, SequenceFrameCount * SizeOf(Integer));
        Image.FillSequenceFrameIndexTable(SequenceIndex, SequenceFrameIndexTable, SizeOf(Integer));
        Image.FillSequenceFrameDelayTable(SequenceIndex, SequenceFrameDelayTable, SizeOf(Integer));
      finally
        MainImageCache.Release;
      end;
    end;
  end;
end;
{ @end $471A58 }

{ @routine $471C54 TgaiGI_AdvanceAutoFrame }
procedure TgaiGI.AdvanceAutoFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Wrapped: Boolean; Delay: Integer;
begin
  Wrapped := False;
  Inc(SequenceFrame);
  if Assigned(FrameAdvancedCallback) then FrameAdvancedCallback(Self);
  if SequenceFrame >= SequenceFrameCount then
  begin
    SequenceFrame := 0;
    Wrapped := True;
  end;
  if StopPlaybackRequested then
  begin
  if AutoFrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AutoFrameTimer);
    AutoFrameTimer := 0;
  end;
  end
  else if AutoFrameTimer = 0 then
  begin
    Delay := GetFrameDelay(SequenceFrame);
    AutoFrameTimer := MessageLoop.ScheduleCallbackTimer(Delay, Delay, AdvanceAutoFrame);
  end
  else
  begin
    Delay := GetFrameDelay(SequenceFrame);
    MessageLoop.UpdateCallbackTimer(AutoFrameTimer, Delay, Delay);
  end;
  Invalidate;
  if Wrapped then
  begin
    if Assigned(CycleCompleteCallback) then CycleCompleteCallback(Self);
  end;
end;
{ @end $471C54 }

{ @routine $471D38 TgaiGI_Invalidate }
procedure TgaiGI.Invalidate;
var Image: TCGaiEC; First: TCGiEC; Width, Height, Left, Right, X, Top, Bottom, Y, FrameIndex, RectIndex, RectCount: Integer; Frame: TgiGR; Bounds, FirstBounds, Rect, Clip, FrameBounds: TRect;
begin
  if not Active then Exit;
  if (not SkipImageUpdateRect) and (FirstFrameImageCache <> nil) and (not FirstFrameOnly) and UsesPlaybackBuffer then
  begin
  if (CachedPlaybackGraphBuf = nil) or (LastCachedFrameIndex < 0) or (SequenceFrame < LastCachedFrameIndex) then
  begin
    inherited Invalidate;
    Exit;
  end;
  if SequenceFrame <= LastCachedFrameIndex then Exit;
  Image := nil;
  First := nil;
  Clip := HitTestBounds;
  try
    Image := AcquireCachedGai(MainImageCache);
    First := AcquireCachedGi(FirstFrameImageCache);
    FirstBounds := First.Image.GetBoundsRect;
    UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
    if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then RaiseWideMessage('TgaiGI.Update Pos-Size');
    Width := FirstBounds.Right - FirstBounds.Left;
    Height := FirstBounds.Bottom - FirstBounds.Top;
    if First.Image.GetFormat <> 0 then RaiseWideMessage('TgaiGI.Update Format gi not 0');
  if ImageKindX = ikxLeftFill then
  begin
    Left := HitTestBounds.Left;
    Right := HitTestBounds.Right;
  end
  else if ImageKindX = ikxRightFill then
  begin
    Right := HitTestBounds.Right;
    Left := Right;
    while Left > Clip.Left do Dec(Left, Width);
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
    while Top > Clip.Top do Dec(Top, Height);
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
    Bounds := Image.GetBoundsRect;
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        FrameIndex := LastCachedFrameIndex + 1;
        if FrameIndex > SequenceFrame then FrameIndex := 0;
        while FrameIndex <= SequenceFrame do
        begin
          Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
          if Frame <> nil then
          begin
            FrameBounds := Frame.GetBoundsRect;
            RectCount := Frame.GetClipRectCount;
            if RectCount < 1 then
            begin
              inherited Invalidate;
              Exit;
            end;
            for RectIndex := 0 to RectCount - 1 do
            begin
              Rect := Frame.GetClipRect(RectIndex);
              Rect.Left := X + Rect.Left + (FrameBounds.Left - Bounds.Left);
              Rect.Top := Y + Rect.Top + (FrameBounds.Top - Bounds.Top);
              Rect.Right := X + Rect.Right + (FrameBounds.Left - Bounds.Left);
              Rect.Bottom := Y + Rect.Bottom + (FrameBounds.Top - Bounds.Top);
              MessageLoop.QueueUpdateRect(Rect);
            end;
          end;
          Inc(FrameIndex);
        end;
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
  finally
    if Image <> nil then MainImageCache.Release;
    if First <> nil then FirstFrameImageCache.Release;
  end;
  end
  else inherited Invalidate;
end;
{ @end $471D38 }

{ @routine $472204 TgaiGI_Draw }
procedure TgaiGI.Draw(ClipRect: TRect);
var Image: TCGaiEC; First: TCGiEC; Width, Height, Left, Right, X, Top, Bottom, Y, FrameIndex, FrameCount: Integer;
  Frame: TgiGR; Bounds, FirstBounds: TRect;
begin
  if SequenceFrame < 0 then Exit;
  if SequenceFrame >= SequenceFrameCount then Exit;
  if MainImageCache.CacheKey = '' then Exit;
  Image := nil;
  First := nil;
  try
    if not FirstFrameOnly then Image := AcquireCachedGai(MainImageCache);
    if FirstFrameImageCache <> nil then First := AcquireCachedGi(FirstFrameImageCache);
    if Image <> nil then
    begin
      Width := Image.GetCanvasSize.X;
      Height := Image.GetCanvasSize.Y;
      if First <> nil then
      begin
        FirstBounds := First.Image.GetBoundsRect;
        UnionRect(Bounds, Image.GetBoundsRect, FirstBounds);
        if not CompareMem(@Bounds, @FirstBounds, SizeOf(TRect)) then RaiseWideMessage('TgaiGI.Draw Pos-Size');
        Width := FirstBounds.Right - FirstBounds.Left;
        Height := FirstBounds.Bottom - FirstBounds.Top;
        if First.Image.GetFormat <> 0 then RaiseWideMessage('TgaiGI.Draw Format gi not 0');
      end;
    end
    else if First <> nil then
    begin
      FirstBounds := First.Image.GetBoundsRect;
      Width := FirstBounds.Right - FirstBounds.Left;
      Height := FirstBounds.Bottom - FirstBounds.Top;
      if First.Image.GetFormat <> 0 then RaiseWideMessage('TgaiGI.Draw Format gi not 0');
    end
    else
    begin
      Width := 0;
      Height := 0;
    end;
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
    if Image <> nil then Bounds := Image.GetBoundsRect
    else if First <> nil then Bounds := First.Image.GetBoundsRect;
    if (Image <> nil) and (not Image.HasPlaybackFlags) then
    begin
      begin
    Y := Top;
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(SequenceFrame));
        Frame.DrawToGraphBuf(ScreenRenderBuffer, X + Frame.GetBoundsRect.Left - Bounds.Left, Y + Frame.GetBoundsRect.Top - Bounds.Top, ClipRect, 0);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
      end;
    end
    else if (Image <> nil) and (not UsesPlaybackBuffer) then
    begin
      Y := Top;
      begin
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        FrameCount := GetSequenceFrameSourceIndex(SequenceFrame);
        for FrameIndex := 0 to FrameCount - 1 do
        begin
          Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
          Frame.DrawToGraphBuf(ScreenRenderBuffer, X + Frame.GetBoundsRect.Left - Bounds.Left, Y + Frame.GetBoundsRect.Top - Bounds.Top, ClipRect, 0);
        end;
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
      end;
    end
    else
    begin
      if FirstFrameImageCache <> nil then
      begin
        if (CachedPlaybackGraphBuf = nil) or (CachedPlaybackGraphBuf.Width <> Width) or (CachedPlaybackGraphBuf.Height <> Height) then
        begin
          LastCachedFrameIndex := -1;
          if CachedPlaybackGraphBuf = nil then CachedPlaybackGraphBuf := TGraphBufGR.Create;
          CachedPlaybackGraphBuf.AllocateRgba(Width, Height, Width * 4);
        end;
        if LastCachedFrameIndex <> SequenceFrame then
        begin
          FrameIndex := LastCachedFrameIndex + 1;
          if FrameIndex > SequenceFrame then FrameIndex := 0;
          if FrameIndex = 0 then
            CopyMemory(CachedPlaybackGraphBuf.Pixels,
              AddPointerOffset(First.Image.Data, First.Image.GetPlane(0).DataOffset),
              CachedPlaybackGraphBuf.PitchBytes * CachedPlaybackGraphBuf.Height);
          if Image <> nil then
          begin
            while FrameIndex <= SequenceFrame do
            begin
              Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
              if Frame <> nil then
                Frame.DrawToGraphBuf(CachedPlaybackGraphBuf, Frame.GetBoundsRect.Left - Bounds.Left, Frame.GetBoundsRect.Top - Bounds.Top, Classes.Rect(0, 0, CachedPlaybackGraphBuf.Width, CachedPlaybackGraphBuf.Height), 0);
              Inc(FrameIndex);
            end;
          end;
          LastCachedFrameIndex := SequenceFrame;
        end;
        Y := Top;
        begin
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        DrawAlphaGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, CachedPlaybackGraphBuf, ClipRect);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
        end;
      end
      else if Image <> nil then
      begin
        if (CachedPlaybackGraphBuf = nil) or (CachedPlaybackGraphBuf.Width <> Width) or (CachedPlaybackGraphBuf.Height <> Height) then
        begin
          LastCachedFrameIndex := -1;
          if CachedPlaybackGraphBuf = nil then CachedPlaybackGraphBuf := TGraphBufGR.Create;
          CachedPlaybackGraphBuf.AllocateNative(Width, Height);
        end;
        if LastCachedFrameIndex <> SequenceFrame then
        begin
          FrameIndex := LastCachedFrameIndex + 1;
          if FrameIndex > SequenceFrame then FrameIndex := 0;
          if FrameIndex = 0 then CachedPlaybackGraphBuf.FillPixels16(TransparentColor);
          while FrameIndex <= SequenceFrame do
          begin
            Frame := Image.LoadFrameGi(GetSequenceFrameSourceIndex(FrameIndex));
            if Frame <> nil then
            begin
              Frame.DrawToGraphBuf(CachedPlaybackGraphBuf, Frame.GetBoundsRect.Left - Bounds.Left, Frame.GetBoundsRect.Top - Bounds.Top, Classes.Rect(0, 0, CachedPlaybackGraphBuf.Width, CachedPlaybackGraphBuf.Height), 0);
            end;
            Inc(FrameIndex);
          end;
          LastCachedFrameIndex := SequenceFrame;
        end;
        Y := Top;
        begin
    while Y < Bottom do
    begin
      X := Left;
      while X < Right do
      begin
        CopyTransparentGraphBuffer16Clipped(ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes, X, Y, CachedPlaybackGraphBuf, ClipRect, TransparentColor);
        Inc(X, Width);
      end;
      Inc(Y, Height);
    end;
        end;
      end;
    end;
  finally
    if Image <> nil then MainImageCache.Release;
    if First <> nil then FirstFrameImageCache.Release;
  end;
end;
{ @end $472204 }

{ @routine $472AEC TgaiGI_PreloadImages }
procedure TgaiGI.PreloadImages;
begin
  if (MainImageCache <> nil) and not FirstFrameOnly then
  begin
    AcquireCachedGai(MainImageCache);
    MainImageCache.Release;
  end;
  if FirstFrameImageCache <> nil then
  begin
    AcquireCachedGi(FirstFrameImageCache);
    FirstFrameImageCache.Release;
  end;
end;
{ @end $472AEC }

{ @routine $472B30 TgaiGI_QueueImageLoad }
procedure TgaiGI.QueueImageLoad(PendingLoads: TList);
begin
  MainImageCache.QueueLoadIfMissing(PendingLoads);
end;
{ @end $472B30 }

{ @routine $472B3C LoadGaiFrameToGraphBuf }
procedure LoadGaiFrameToGraphBuf(const Path: WideString; GraphBuf: TGraphBufGR; Seed: Cardinal);
var
  Control: TCacheControlEC;
  Gai: TCGaiEC;
  FrameIndex: Integer;
begin
  Control := TCGaiControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(Path);
  Gai := AcquireCachedGai(Control);
  try
    FrameIndex := 0;
    if Seed <> 0 then FrameIndex := SeededRandomIntRange(0, Gai.GetFrameCount - 1, Seed);
    Gai.LoadFrameGi(FrameIndex).DecodeToGraphBuf(GraphBuf);
  finally
    Control.Release;
  end;
  Control.Free;
end;
{ @end $472B3C }

end.

unit GI_GraphButton;
// Unit bracket (inferred): CODE 0x004845F4..0x00486687; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_Image, GI_Label, GI_Main, GI_MessageLoop, Types;

type
  TGraphButtonKindGI = (gbkNormal = 0, gbkFix = 1, gbkDisable = 2, gbkFixDisable = 3); // @size 1
  TGraphButtonHitKindGI = (gbhRect = 0, gbhGraph = 1, gbhImageHit = 2); // @size 1

  TGraphButtonGI = class(TObjectGI) // @size $194
  public
    Kind: TGraphButtonKindGI; // @offset $100
    HitKind: TGraphButtonHitKindGI; // @offset $101
    Down: Boolean; // @offset $102
    Disabled: Boolean; // @offset $103
    Hover: Boolean; // @offset $104
    DownCallback: TObjectNotifyEventGI; // @offset $108
    UpCallback: TObjectNotifyEventGI; // @offset $110
    ImageNormal: TImageGI; // @offset $118
    ImageNormalActive: TImageGI; // @offset $11C
    ImageDown: TImageGI; // @offset $120
    ImageDownActive: TImageGI; // @offset $124
    ImageDisabled: TImageGI; // @offset $128
    ImageDisabledActive: TImageGI; // @offset $12C
    ImageHit: TImageGI; // @offset $130
    CaptionLabel: TLabelGI; // @offset $134
    NormalOffset: TPoint; // @offset $138
    NormalActiveOffset: TPoint; // @offset $140
    DownOffset: TPoint; // @offset $148
    DownActiveOffset: TPoint; // @offset $150
    DisabledOffset: TPoint; // @offset $158
    DisabledActiveOffset: TPoint; // @offset $160
    HitOffset: TPoint; // @offset $168
    EnterSound: WideString; // @offset $170
    LeaveSound: WideString; // @offset $174
    ClickSound: WideString; // @offset $178
    CaptionOffsets: TRect; // @offset $17C // Left/Top for normal, Right/Bottom for down.
    // Color order: normal, normal-active, down, down-active, disabled, disabled-active.
    ImageAutoUpdateFlags: Cardinal; // @offset $18C
    UpOnlyDown: Boolean; // @offset $190

    procedure Clear; override; // @addr $4847A0
    procedure SetSize(Size: TPoint); override; // @addr $4852E8
    procedure SetOrigin(Origin: TPoint); override; // @addr $485310
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $485768
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $485448
    procedure OnMouseEnter; override; // @addr $4853A0
    procedure OnMouseLeave; override; // @addr $4853A8
    procedure OnActivate; override; // @addr $485338
    procedure OnDeactivate; override; // @addr $48537C
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $485578
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $485694
    procedure ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint); override; // @addr $485738
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $485794
    procedure UpdateAutoGeometry; override; // @addr $486274
    constructor Create(Owner: TObjectGI); // @addr $48472C
    destructor Destroy; override; // @addr $484778
    procedure SetCaptionFontName(const FontName: WideString); // @addr $48486C
    procedure SetCaption(const Text: WideString); // @addr $4848F8
    procedure SetCaptionColor(Value: Cardinal); // @addr $484984
    procedure SetImageNormalPath(const Path: WideString); // @addr $484A10
    procedure SetImageNormalActivePath(const Path: WideString); // @addr $484A90
    procedure SetImageDownPath(const Path: WideString); // @addr $484B10
    procedure SetImageDownActivePath(const Path: WideString); // @addr $484B90
    procedure SetImageDisabledPath(const Path: WideString); // @addr $484C10
    procedure SetImageDisabledActivePath(const Path: WideString); // @addr $484C90
    procedure SetImageHitPath(const Path: WideString); // @addr $484D10
    procedure SetKind(Value: TGraphButtonKindGI); // @addr $484D74
    function HitTest(Point: TPoint): Boolean; // @addr $484D88 @note "Graph mode accepts a hit on any state image, including inactive states."
    procedure SetDown(Value: Boolean); // @addr $484E68
    procedure SetDisabled(Value: Boolean); // @addr $484E7C
    procedure SetHovered(Value: Boolean); // @addr $484E90
    function GetMaxStateImageSize: TPoint; // @addr $484EA4 @note "Native code compares an uninitialized temporary size when the first state image is absent."
    procedure UpdateStateVisuals; // @addr $484FF8
    procedure UpdateStateImagePlacement; // @addr $48521C
    procedure LoadButtonProperties(Block: TBlockParEC); // @addr $4857B0 @note "Configured state-image positions are absolute; stored positions are relative to this control."
  end;

implementation

// @unit-initialization $486680
// @unit-finalization $486650

uses Classes, EC_Str, EC_Struct, GR_Main, GR_Sound, Math, Windows;

{ @routine $48472C TGraphButtonGI_Create }
constructor TGraphButtonGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Kind := gbkNormal;
  HitKind := gbhRect;
  UpOnlyDown := False;
end;
{ @end $48472C }

{ @routine $484778 TGraphButtonGI_Destroy }
destructor TGraphButtonGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $484778 }

{ @routine $4847A0 TGraphButtonGI_Clear }
procedure TGraphButtonGI.Clear;
begin
  Kind := gbkNormal;
  if ImageNormal <> nil then
  begin
    ImageNormal.Free;
    ImageNormal := nil;
  end;
  if ImageNormalActive <> nil then
  begin
    ImageNormalActive.Free;
    ImageNormalActive := nil;
  end;
  if ImageDown <> nil then
  begin
    ImageDown.Free;
    ImageDown := nil;
  end;
  if ImageDownActive <> nil then
  begin
    ImageDownActive.Free;
    ImageDownActive := nil;
  end;
  if ImageDisabled <> nil then
  begin
    ImageDisabled.Free;
    ImageDisabled := nil;
  end;
  if ImageDisabledActive <> nil then
  begin
    ImageDisabledActive.Free;
    ImageDisabledActive := nil;
  end;
  if ImageHit <> nil then
  begin
    ImageHit.Free;
    ImageHit := nil;
  end;
  if CaptionLabel <> nil then
  begin
    CaptionLabel.Free;
    CaptionLabel := nil;
  end;
  inherited Clear;
end;
{ @end $4847A0 }

{ @routine $48486C TGraphButtonGI_SetCaptionFontName }
procedure TGraphButtonGI.SetCaptionFontName(const FontName: WideString);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(taxCenter);
    CaptionLabel.SetTextAlignY(tayCenterEx);
  end;
  CaptionLabel.SetFontName(FontName);
end;
{ @end $48486C }

{ @routine $4848F8 TGraphButtonGI_SetCaption }
procedure TGraphButtonGI.SetCaption(const Text: WideString);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(taxCenter);
    CaptionLabel.SetTextAlignY(tayCenterEx);
  end;
  CaptionLabel.SetText(Text);
end;
{ @end $4848F8 }

{ @routine $484984 TGraphButtonGI_SetCaptionColor }
procedure TGraphButtonGI.SetCaptionColor(Value: Cardinal);
begin
  if CaptionLabel = nil then
  begin
    CaptionLabel := TLabelGI.Create(Self);
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
    CaptionLabel.SetDepth(-9999);
    CaptionLabel.SetTextAlignX(taxCenter);
    CaptionLabel.SetTextAlignY(tayCenterEx);
  end;
  CaptionLabel.SetTextColor(Value);
end;
{ @end $484984 }

{ @routine $484A10 TGraphButtonGI_SetImageNormalPath }
procedure TGraphButtonGI.SetImageNormalPath(const Path: WideString);
begin
  if ImageNormal = nil then ImageNormal := TImageGI.Create(Self);
  ImageNormal.SetDepth(1);
  ImageNormal.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageNormal.SetImagePath(Path);
  ImageNormal.SetSize(ImageNormal.GetContentSize);
  ImageNormal.SetPosition(NormalOffset);
end;
{ @end $484A10 }

{ @routine $484A90 TGraphButtonGI_SetImageNormalActivePath }
procedure TGraphButtonGI.SetImageNormalActivePath(const Path: WideString);
begin
  if ImageNormalActive = nil then ImageNormalActive := TImageGI.Create(Self);
  ImageNormalActive.SetDepth(1);
  ImageNormalActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageNormalActive.SetImagePath(Path);
  ImageNormalActive.SetSize(ImageNormalActive.GetContentSize);
  ImageNormalActive.SetPosition(NormalActiveOffset);
end;
{ @end $484A90 }

{ @routine $484B10 TGraphButtonGI_SetImageDownPath }
procedure TGraphButtonGI.SetImageDownPath(const Path: WideString);
begin
  if ImageDown = nil then ImageDown := TImageGI.Create(Self);
  ImageDown.SetDepth(1);
  ImageDown.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDown.SetImagePath(Path);
  ImageDown.SetSize(ImageDown.GetContentSize);
  ImageDown.SetPosition(DownOffset);
end;
{ @end $484B10 }

{ @routine $484B90 TGraphButtonGI_SetImageDownActivePath }
procedure TGraphButtonGI.SetImageDownActivePath(const Path: WideString);
begin
  if ImageDownActive = nil then ImageDownActive := TImageGI.Create(Self);
  ImageDownActive.SetDepth(1);
  ImageDownActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDownActive.SetImagePath(Path);
  ImageDownActive.SetSize(ImageDownActive.GetContentSize);
  ImageDownActive.SetPosition(DownActiveOffset);
end;
{ @end $484B90 }

{ @routine $484C10 TGraphButtonGI_SetImageDisabledPath }
procedure TGraphButtonGI.SetImageDisabledPath(const Path: WideString);
begin
  if ImageDisabled = nil then ImageDisabled := TImageGI.Create(Self);
  ImageDisabled.SetDepth(1);
  ImageDisabled.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDisabled.SetImagePath(Path);
  ImageDisabled.SetSize(ImageDisabled.GetContentSize);
  ImageDisabled.SetPosition(DisabledOffset);
end;
{ @end $484C10 }

{ @routine $484C90 TGraphButtonGI_SetImageDisabledActivePath }
procedure TGraphButtonGI.SetImageDisabledActivePath(const Path: WideString);
begin
  if ImageDisabledActive = nil then ImageDisabledActive := TImageGI.Create(Self);
  ImageDisabledActive.SetDepth(1);
  ImageDisabledActive.AutoUpdateFlags := ImageAutoUpdateFlags;
  ImageDisabledActive.SetImagePath(Path);
  ImageDisabledActive.SetSize(ImageDisabledActive.GetContentSize);
  ImageDisabledActive.SetPosition(DisabledActiveOffset);
end;
{ @end $484C90 }

{ @routine $484D10 TGraphButtonGI_SetImageHitPath }
procedure TGraphButtonGI.SetImageHitPath(const Path: WideString);
begin
  if ImageHit = nil then ImageHit := TImageGI.Create(Self);
  ImageHit.SetImagePath(Path);
  ImageHit.SetSize(ImageHit.GetContentSize);
  ImageHit.SetPosition(HitOffset);
end;
{ @end $484D10 }

{ @routine $484D74 TGraphButtonGI_SetKind }
procedure TGraphButtonGI.SetKind(Value: TGraphButtonKindGI);
begin
  if Kind <> Value then
  begin
    Kind := Value;
    UpdateStateVisuals;
  end;
end;
{ @end $484D74 }

{ @routine $484D88 TGraphButtonGI_HitTest }
function TGraphButtonGI.HitTest(Point: TPoint): Boolean;
begin
  Result := False;
  if HitKind = gbhRect then Result := ContainsPoint(Point)
  else if HitKind = gbhGraph then
  begin
    if ImageNormal <> nil then Result := ImageNormal.HitTestPixel(Point);
    if Result then Exit;
    if ImageNormalActive <> nil then Result := ImageNormalActive.HitTestPixel(Point);
    if Result then Exit;
    if ImageDown <> nil then Result := ImageDown.HitTestPixel(Point);
    if Result then Exit;
    if ImageDownActive <> nil then Result := ImageDownActive.HitTestPixel(Point);
    if Result then Exit;
    if ImageDisabled <> nil then Result := ImageDisabled.HitTestPixel(Point);
    if Result then Exit;
    if ImageDisabledActive <> nil then Result := ImageDisabledActive.HitTestPixel(Point);
    if Result then Exit;
  end
  else if HitKind = gbhImageHit then
  begin
    if ImageHit <> nil then Result := ImageHit.HitTestPixel(Point);
  end;
end;
{ @end $484D88 }

{ @routine $484E68 TGraphButtonGI_SetDown }
procedure TGraphButtonGI.SetDown(Value: Boolean);
begin
  if Down <> Value then
  begin
    Down := Value;
    UpdateStateVisuals;
  end;
end;
{ @end $484E68 }

{ @routine $484E7C TGraphButtonGI_SetDisabled }
procedure TGraphButtonGI.SetDisabled(Value: Boolean);
begin
  if Disabled <> Value then
  begin
    Disabled := Value;
    UpdateStateVisuals;
  end;
end;
{ @end $484E7C }

{ @routine $484E90 TGraphButtonGI_SetHovered }
procedure TGraphButtonGI.SetHovered(Value: Boolean);
begin
  if Value <> Hover then
  begin
    Hover := Value;
    UpdateStateVisuals;
  end;
end;
{ @end $484E90 }

{ @routine $484EA4 TGraphButtonGI_GetMaxStateImageSize }
function TGraphButtonGI.GetMaxStateImageSize: TPoint;
var Size: TPoint;
begin
  Result.X := 0;
  Result.Y := 0;
  // Native comparisons are unconditional, including before Size is initialized.
  if ImageNormal <> nil then Size := ImageNormal.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageNormalActive <> nil then Size := ImageNormalActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDown <> nil then Size := ImageDown.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDownActive <> nil then Size := ImageDownActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDisabled <> nil then Size := ImageDisabled.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageDisabledActive <> nil then Size := ImageDisabledActive.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
  if ImageHit <> nil then Size := ImageHit.GetContentSize;
  Result.X := Max(Result.X, Size.X);
  Result.Y := Max(Result.Y, Size.Y);
end;
{ @end $484EA4 }

{ @routine $484FF8 TGraphButtonGI_UpdateStateVisuals }
procedure TGraphButtonGI.UpdateStateVisuals;
begin
  if ImageNormal <> nil then ImageNormal.SetActive(False);
  if ImageNormalActive <> nil then ImageNormalActive.SetActive(False);
  if ImageDown <> nil then ImageDown.SetActive(False);
  if ImageDownActive <> nil then ImageDownActive.SetActive(False);
  if ImageDisabled <> nil then ImageDisabled.SetActive(False);
  if ImageDisabledActive <> nil then ImageDisabledActive.SetActive(False);
  if ImageHit <> nil then ImageHit.SetActive(False);
  if Disabled and ((Kind = gbkDisable) or (Kind = gbkFixDisable)) then
  begin
    if Hover then
    begin
      if ImageDisabledActive <> nil then ImageDisabledActive.SetActive(True)
      else if ImageDisabled <> nil then ImageDisabled.SetActive(True);
    end
    else if ImageDisabled <> nil then ImageDisabled.SetActive(True);
  end
  else
  begin
    if Down then
    begin
      if Hover then
      begin
        if ImageDownActive <> nil then ImageDownActive.SetActive(True)
        else if ImageDown <> nil then ImageDown.SetActive(True);
      end
      else if ImageDown <> nil then ImageDown.SetActive(True);
    end
    else
    begin
      if Hover then
      begin
        if ImageNormalActive <> nil then ImageNormalActive.SetActive(True)
        else if ImageNormal <> nil then ImageNormal.SetActive(True);
      end
      else if ImageNormal <> nil then ImageNormal.SetActive(True);
    end;
  end;
  if CaptionLabel <> nil then
  begin
    if not Down then CaptionLabel.SetPosition(CaptionOffsets.TopLeft)
    else CaptionLabel.SetPosition(CaptionOffsets.BottomRight);
  end;
  if ImageNormal <> nil then
    if ImageNormal.Active then ImageNormal.RestartPlayback;
  if ImageNormalActive <> nil then
    if ImageNormalActive.Active then ImageNormalActive.RestartPlayback;
  if ImageDown <> nil then
    if ImageDown.Active then ImageDown.RestartPlayback;
  if ImageDownActive <> nil then
    if ImageDownActive.Active then ImageDownActive.RestartPlayback;
  if ImageDisabled <> nil then
    if ImageDisabled.Active then ImageDisabled.RestartPlayback;
  if ImageDisabledActive <> nil then
    if ImageDisabledActive.Active then ImageDisabledActive.RestartPlayback;
  Invalidate;
end;
{ @end $484FF8 }

{ @routine $48521C TGraphButtonGI_UpdateStateImagePlacement }
procedure TGraphButtonGI.UpdateStateImagePlacement;
begin
  if ImageNormal <> nil then ImageNormal.SetPosition(NormalOffset);
  if ImageNormalActive <> nil then ImageNormalActive.SetPosition(NormalActiveOffset);
  if ImageDown <> nil then ImageDown.SetPosition(DownOffset);
  if ImageDownActive <> nil then ImageDownActive.SetPosition(DownActiveOffset);
  if ImageDisabled <> nil then ImageDisabled.SetPosition(DisabledOffset);
  if ImageDisabledActive <> nil then ImageDisabledActive.SetPosition(DisabledActiveOffset);
  if ImageHit <> nil then ImageHit.SetPosition(HitOffset);
  if CaptionLabel <> nil then
  begin
    CaptionLabel.SetPosition(Classes.Point(0, 0));
    CaptionLabel.SetSize(ClientSize);
  end;
end;
{ @end $48521C }

{ @routine $4852E8 TGraphButtonGI_SetSize }
procedure TGraphButtonGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  UpdateStateImagePlacement;
end;
{ @end $4852E8 }

{ @routine $485310 TGraphButtonGI_SetOrigin }
procedure TGraphButtonGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  UpdateStateImagePlacement;
end;
{ @end $485310 }

{ @routine $485338 TGraphButtonGI_OnActivate }
procedure TGraphButtonGI.OnActivate;
begin
  inherited OnActivate;
  if HitTestCursor then Hover := True else Hover := False;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then Down := False;
  UpdateStateVisuals;
end;
{ @end $485338 }

{ @routine $48537C TGraphButtonGI_OnDeactivate }
procedure TGraphButtonGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Hover := False;
  Down := False;
  UpdateStateVisuals;
end;
{ @end $48537C }

{ @routine $4853A0 TGraphButtonGI_OnMouseEnter }
procedure TGraphButtonGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;
{ @end $4853A0 }

{ @routine $4853A8 TGraphButtonGI_OnMouseLeave }
procedure TGraphButtonGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
    if Down then begin Down := False; if Assigned(UpCallback) then UpCallback(Self); end;
  if Hover then
    if (LeaveSound <> '') and not Disabled then SoundManager.PlaySound(LeaveSound);
  if Hover and Assigned(HelpCallback) then HelpCallback(Self, False);
  Hover := False;
  UpdateStateVisuals;
end;
{ @end $4853A8 }

{ @routine $485448 TGraphButtonGI_ProcessMouseMove }
procedure TGraphButtonGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  if MouseBlockingTest and IsOccludedAtPoint(AbsolutePosition) then Exit;
  if HitTest(Point) then
  begin
    if not Hover then
      if (EnterSound <> '') and not Disabled then SoundManager.PlaySound(EnterSound);
    if not Hover then
      if Assigned(HelpCallback) then HelpCallback(Self, True);
    Hover := True;
    UpdateStateVisuals;
  end
  else
  begin
    if (Kind = gbkNormal) or (Kind = gbkDisable) then
      if Down then begin Down := False; if Assigned(UpCallback) then UpCallback(Self); end;
    if Hover then
      if (LeaveSound <> '') and not Disabled then SoundManager.PlaySound(LeaveSound);
    if Hover and Assigned(HelpCallback) then HelpCallback(Self, False);
    Hover := False;
    UpdateStateVisuals;
  end;
end;
{ @end $485448 }

{ @routine $485578 TGraphButtonGI_ProcessLeftButtonDown }
procedure TGraphButtonGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if IsOccludedAtPoint(Point) then Exit;
  if not HitTest(Point) then Exit;
  if ((Kind = gbkDisable) or (Kind = gbkFixDisable)) and (Disabled = True) then Exit;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
  begin
    Down := True;
    if ClickSound <> '' then SoundManager.PlaySound(ClickSound);
    if Assigned(DownCallback) then
    begin
      DownCallback(Self);
    end;
  end
  else
  begin
    if Down then
    begin
      Down := False;
      if Assigned(UpCallback) then
      begin
        UpCallback(Self);
      end;
    end
    else
    begin
      Down := True;
      if ClickSound <> '' then SoundManager.PlaySound(ClickSound);
      if Assigned(DownCallback) then
      begin
        DownCallback(Self);
      end;
    end;
  end;
  UpdateStateVisuals;
end;
{ @end $485578 }

{ @routine $485694 TGraphButtonGI_ProcessLeftButtonUp }
procedure TGraphButtonGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
var WasDown: Boolean;
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if IsOccludedAtPoint(Point) then Exit;
  if not HitTest(Point) then Exit;
  if ((Kind = gbkDisable) or (Kind = gbkFixDisable)) and (Disabled = True) then Exit;
  if (Kind = gbkNormal) or (Kind = gbkDisable) then
  begin
    WasDown := Down;
    Down := False;
    if Assigned(UpCallback) and MessageLoop.ConsumeTimerTickChange then
    begin
      if not (UpOnlyDown and not WasDown) then UpCallback(Self);
    end;
    UpdateStateVisuals;
  end;
end;
{ @end $485694 }

{ @routine $485738 TGraphButtonGI_ProcessLeftButtonDoubleClick }
procedure TGraphButtonGI.ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonDoubleClick(KeyState, Point);
  ProcessLeftButtonDown(KeyState, Point);
end;
{ @end $485738 }

{ @routine $485768 TGraphButtonGI_LoadFromConfigPath }
procedure TGraphButtonGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadButtonProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $485768 }

{ @routine $485794 TGraphButtonGI_LoadFromBlock }
procedure TGraphButtonGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadButtonProperties(Block);
end;
{ @end $485794 }

{ @routine $4857B0 TGraphButtonGI_LoadButtonProperties }
procedure TGraphButtonGI.LoadButtonProperties(Block: TBlockParEC);
var Text: WideString;
begin
  if Block.CountParams('Font') > 0 then SetCaptionFontName(Block.GetParam('Font'));
  if Block.CountParams('Caption') > 0 then
  begin
    Text := Block.GetParam('Caption');
    SetCaption(Text);
    if LanguageDataConfig.CountParamsByPath(Text) > 0 then
      SetCaption(LanguageDataConfig.GetParamByPath(Text));
  end;
  if Block.CountParams('CaptionColor') > 0 then SetCaptionColor(GetColorGI(Block.GetParam('CaptionColor')));
  if Block.CountParams('Kind') > 0 then
  begin
    Text := Block.GetParam('Kind');
    if Text = 'Normal' then SetKind(gbkNormal)
    else if Text = 'Fix' then SetKind(gbkFix)
    else if Text = 'Disable' then SetKind(gbkDisable)
    else if Text = 'FixDisable' then SetKind(gbkFixDisable);
  end;
  if Block.CountParams('Auto') > 0 then ImageAutoUpdateFlags := ParseAutoGeometryFlagsGI(Block.GetParam('Auto'));
  if Block.CountParams('KindHit') > 0 then
  begin
    Text := Block.GetParam('KindHit');
    if Text = 'Rect' then HitKind := gbhRect
    else if Text = 'Graph' then HitKind := gbhGraph
    else if Text = 'ImageHit' then HitKind := gbhImageHit;
  end;
  if Block.CountParams('ImageNormal') > 0 then SetImageNormalPath(Block.GetParam('ImageNormal'));
  if Block.CountParams('ImageNormalA') > 0 then SetImageNormalActivePath(Block.GetParam('ImageNormalA'));
  if Block.CountParams('ImageDown') > 0 then SetImageDownPath(Block.GetParam('ImageDown'));
  if Block.CountParams('ImageDownA') > 0 then SetImageDownActivePath(Block.GetParam('ImageDownA'));
  if Block.CountParams('ImageDisable') > 0 then SetImageDisabledPath(Block.GetParam('ImageDisable'));
  if Block.CountParams('ImageDisableA') > 0 then SetImageDisabledActivePath(Block.GetParam('ImageDisableA'));
  if Block.CountParams('ImageHit') > 0 then SetImageHitPath(Block.GetParam('ImageHit'));
  if Block.CountParams('ImageNormal_Pos') > 0 then NormalOffset := GetPointGI(Block.GetParam('ImageNormal_Pos'))
  else NormalOffset := LocalPosition;
  if Block.CountParams('ImageNormalA_Pos') > 0 then NormalActiveOffset := GetPointGI(Block.GetParam('ImageNormalA_Pos'))
  else NormalActiveOffset := LocalPosition;
  if Block.CountParams('ImageDown_Pos') > 0 then DownOffset := GetPointGI(Block.GetParam('ImageDown_Pos'))
  else DownOffset := LocalPosition;
  if Block.CountParams('ImageDownA_Pos') > 0 then DownActiveOffset := GetPointGI(Block.GetParam('ImageDownA_Pos'))
  else DownActiveOffset := LocalPosition;
  if Block.CountParams('ImageDisable_Pos') > 0 then DisabledOffset := GetPointGI(Block.GetParam('ImageDisable_Pos'))
  else DisabledOffset := LocalPosition;
  if Block.CountParams('ImageDisableA_Pos') > 0 then DisabledActiveOffset := GetPointGI(Block.GetParam('ImageDisableA_Pos'))
  else DisabledActiveOffset := LocalPosition;
  if Block.CountParams('ImageHit_Pos') > 0 then HitOffset := GetPointGI(Block.GetParam('ImageHit_Pos'))
  else HitOffset := LocalPosition;
  NormalOffset := SubtractPoints(NormalOffset, LocalPosition);
  NormalActiveOffset := SubtractPoints(NormalActiveOffset, LocalPosition);
  DownOffset := SubtractPoints(DownOffset, LocalPosition);
  DownActiveOffset := SubtractPoints(DownActiveOffset, LocalPosition);
  DisabledOffset := SubtractPoints(DisabledOffset, LocalPosition);
  DisabledActiveOffset := SubtractPoints(DisabledActiveOffset, LocalPosition);
  HitOffset := SubtractPoints(HitOffset, LocalPosition);
  if Block.CountParams('Disable') > 0 then SetDisabled(ParseEnabledNameGI(Block.GetParam('Disable')));
  if Block.CountParams('Down') > 0 then SetDown(ParseEnabledNameGI(Block.GetParam('Down')));
  if Block.CountParams('SoundEnter') > 0 then EnterSound := Block.GetParam('SoundEnter');
  if Block.CountParams('SoundLeave') > 0 then LeaveSound := Block.GetParam('SoundLeave');
  if Block.CountParams('SoundClick') > 0 then ClickSound := Block.GetParam('SoundClick');
  if Block.CountParams('CaptionSme') > 0 then CaptionOffsets := GetRectGI(Block.GetParam('CaptionSme'));
  UpdateStateImagePlacement;
end;
{ @end $4857B0 }

{ @routine $486274 TGraphButtonGI_UpdateAutoGeometry }
procedure TGraphButtonGI.UpdateAutoGeometry;
var Bounds, ImageBounds: TRect;
begin
  if ImageAutoUpdateFlags <> 0 then
  begin
    Bounds.Left := 0;
    Bounds.Top := 0;
    Bounds.Right := 0;
    Bounds.Bottom := 0;
    if ImageNormal <> nil then
    begin
      ImageBounds.TopLeft := ImageNormal.GetContentOrigin;
      ImageBounds.BottomRight := ImageNormal.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      Bounds := ImageBounds;
    end;
    if ImageNormalActive <> nil then
    begin
      ImageBounds.TopLeft := ImageNormalActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageNormalActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then Bounds := ImageBounds
      else Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDown <> nil then
    begin
      ImageBounds.TopLeft := ImageDown.GetContentOrigin;
      ImageBounds.BottomRight := ImageDown.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then Bounds := ImageBounds
      else Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDownActive <> nil then
    begin
      ImageBounds.TopLeft := ImageDownActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageDownActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then Bounds := ImageBounds
      else Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDisabled <> nil then
    begin
      ImageBounds.TopLeft := ImageDisabled.GetContentOrigin;
      ImageBounds.BottomRight := ImageDisabled.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then Bounds := ImageBounds
      else Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if ImageDisabledActive <> nil then
    begin
      ImageBounds.TopLeft := ImageDisabledActive.GetContentOrigin;
      ImageBounds.BottomRight := ImageDisabledActive.GetContentSize;
      ImageBounds.BottomRight := AddPoints(ImageBounds.TopLeft, ImageBounds.BottomRight);
      if Bounds.Right - Bounds.Left < 1 then Bounds := ImageBounds
      else Windows.UnionRect(Bounds, Bounds, ImageBounds);
    end;
    if (ImageAutoUpdateFlags and agfPosition) = agfPosition then SetPosition(Parent.ToLocalPoint(Bounds.TopLeft));
    if (ImageAutoUpdateFlags and agfSize) = agfSize then SetSize(SubtractPoints(Bounds.BottomRight, Bounds.TopLeft));
  end;
  inherited UpdateAutoGeometry;
end;
{ @end $486274 }

end.

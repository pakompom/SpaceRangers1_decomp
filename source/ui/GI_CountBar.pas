unit GI_CountBar;
// Unit bracket (inferred): CODE 0x00488728..0x004895AB; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_GraphButton, GI_Image, GI_MessageLoop, Types;

type
  TCountBarGI = class(TObjectGI) // @size $134
  public
    Minimum: Integer; // @offset $100
    Maximum: Integer; // @offset $104
    Position: Integer; // @offset $108
    Orientation: Integer; // @offset $10C
    Step: Integer; // @offset $110
    DecreaseButton: TGraphButtonGI; // @offset $114
    IncreaseButton: TGraphButtonGI; // @offset $118
    AfterThumbImage: TImageGI; // @offset $11C
    BeforeThumbImage: TImageGI; // @offset $120
    ThumbButton: TGraphButtonGI; // @offset $124
    PositionChangedCallback: TObjectNotifyEventGI; // @offset $128
    RepeatTimer: TCallbackTimerIdGI; // @offset $130

    constructor Create(Owner: TObjectGI); // @addr $488838
    destructor Destroy; override; // @addr $48896C
    procedure SetRange(MinValue, MaxValue: Integer); // @addr $488A20
    procedure SetPositionInternal(Value: Integer); // @addr $488A8C @note "Clamps without invoking PositionChangedCallback."
    procedure SetPosition(Value: Integer); reintroduce; // @addr $488ADC @note "Notifies only while Active and when the requested value differs from the previous position."
    procedure UpdateLayout; // @addr $488B44
    procedure AutoRepeat(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $488D50
    procedure DecreasePressed(Sender: TObjectGI); // @addr $488DBC
    procedure IncreasePressed(Sender: TObjectGI); // @addr $488E10
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $488E64
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); override; // @addr $488FA4
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $489118
    procedure OnMouseEnter; override; // @addr $488F94
    procedure OnMouseLeave; override; // @addr $488F9C
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $489154
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $489180
    procedure LoadCountBarProperties(Block: TBlockParEC); // @addr $48919C
  end;

implementation

// @unit-initialization $4895A4
// @unit-finalization $489574

uses Classes, EC_Struct, GI_Main;

{ @routine $488838 TCountBarGI_Create }
constructor TCountBarGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Orientation := 1;
  Minimum := 0;
  Maximum := 100;
  Position := 0;
  Step := 1;
  DecreaseButton := TGraphButtonGI.Create(Self);
  IncreaseButton := TGraphButtonGI.Create(Self);
  AfterThumbImage := TImageGI.Create(Self);
  BeforeThumbImage := TImageGI.Create(Self);
  ThumbButton := TGraphButtonGI.Create(Self);
  DecreaseButton.DownCallback := DecreasePressed;
  IncreaseButton.DownCallback := IncreasePressed;
  AfterThumbImage.SetImageKindX(ikxLeftFill);
  AfterThumbImage.SetImageKindY(ikyTopFill);
  BeforeThumbImage.SetImageKindX(ikxLeftFill);
  BeforeThumbImage.SetImageKindY(ikyTopFill);
  ThumbButton.SetKind(gbkFix);
end;
{ @end $488838 }

{ @routine $48896C TCountBarGI_Destroy }
destructor TCountBarGI.Destroy;
begin
  if DecreaseButton <> nil then
  begin
    DecreaseButton.Free;
    DecreaseButton := nil;
  end;
  if IncreaseButton <> nil then
  begin
    IncreaseButton.Free;
    IncreaseButton := nil;
  end;
  if AfterThumbImage <> nil then
  begin
    AfterThumbImage.Free;
    AfterThumbImage := nil;
  end;
  if BeforeThumbImage <> nil then
  begin
    BeforeThumbImage.Free;
    BeforeThumbImage := nil;
  end;
  if ThumbButton <> nil then
  begin
    ThumbButton.Free;
    ThumbButton := nil;
  end;
  if RepeatTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := 0;
  end;
  inherited Destroy;
end;
{ @end $48896C }

{ @routine $488A20 TCountBarGI_SetRange }
procedure TCountBarGI.SetRange(MinValue, MaxValue: Integer);
begin
  if (Maximum <> MaxValue) or (Minimum <> MinValue) then
  begin
    if MinValue > MaxValue then MinValue := MaxValue;
    Minimum := MinValue;
    Maximum := MaxValue;
    if Position < Minimum then SetPositionInternal(Minimum);
    if Position > Maximum then SetPositionInternal(Maximum);
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
    end;
  end;
end;
{ @end $488A20 }

{ @routine $488A8C TCountBarGI_SetPositionInternal }
procedure TCountBarGI.SetPositionInternal(Value: Integer);
begin
  if Position <> Value then
  begin
    Position := Value;
    if Position < Minimum then Position := Minimum;
    if Position > Maximum then Position := Maximum;
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
    end;
  end;
end;
{ @end $488A8C }

{ @routine $488ADC TCountBarGI_SetPosition }
procedure TCountBarGI.SetPosition(Value: Integer);
begin
  if Position <> Value then
  begin
    Position := Value;
    if Position < Minimum then Position := Minimum;
    if Position > Maximum then Position := Maximum;
    if Active = True then
    begin
      UpdateLayout;
      Invalidate;
      if Assigned(PositionChangedCallback) then PositionChangedCallback(Self);
    end;
  end;
end;
{ @end $488ADC }

{ @routine $488B44 TCountBarGI_UpdateLayout }
procedure TCountBarGI.UpdateLayout;
var
  TrackWidth, ThumbLeft, ThumbRight: Integer;
  ThumbSize, IncreaseSize, DecreaseSize: TPoint;
begin
  if Orientation = 1 then
  begin
    ThumbSize := ThumbButton.GetMaxStateImageSize;
    DecreaseSize := DecreaseButton.GetMaxStateImageSize;
    IncreaseSize := IncreaseButton.GetMaxStateImageSize;
    TrackWidth := ClientSize.X - ThumbSize.X - IncreaseSize.X - DecreaseSize.X;
    if Maximum - Minimum = 0 then ThumbLeft := IncreaseSize.X
    else ThumbLeft := Integer(Round(TrackWidth * (Position - Minimum) / (Maximum - Minimum))) - ThumbSize.X div 2 + IncreaseSize.X + ThumbSize.X div 2;
    ThumbRight := ThumbLeft + ThumbSize.X;
    DecreaseButton.SetPosition(Classes.Point(0, 0));
    DecreaseButton.SetSize(DecreaseSize);
    IncreaseButton.SetPosition(Classes.Point(ClientSize.X - IncreaseSize.X, 0));
    IncreaseButton.SetSize(IncreaseSize);
    BeforeThumbImage.SetPosition(Classes.Point(DecreaseSize.X, 0));
    BeforeThumbImage.SetSize(Classes.Point(ThumbLeft - DecreaseSize.X, AfterThumbImage.GetContentSize.Y));
    AfterThumbImage.SetPosition(Classes.Point(ThumbRight, 0));
    AfterThumbImage.SetSize(Classes.Point(ClientSize.X - ThumbRight - IncreaseSize.X, BeforeThumbImage.GetContentSize.Y));
    ThumbButton.SetPosition(Classes.Point(ThumbLeft, 0));
    ThumbButton.SetSize(Classes.Point(ThumbRight - ThumbLeft, ThumbSize.Y));
    AfterThumbImage.SetImageKindX(ikxRightFill);
    BeforeThumbImage.SetImageKindX(ikxLeftFill);
  end;
end;
{ @end $488B44 }

{ @routine $488D50 TCountBarGI_AutoRepeat }
procedure TCountBarGI.AutoRepeat(Timer: TCallbackTimerIdGI; UserData: Cardinal);
begin
  if DecreaseButton.Down then SetPosition(Position - Step)
  else if IncreaseButton.Down then SetPosition(Position + Step)
  else
  if RepeatTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := 0;
  end;
end;
{ @end $488D50 }

{ @routine $488DBC TCountBarGI_DecreasePressed }
procedure TCountBarGI.DecreasePressed(Sender: TObjectGI);
begin
  SetPosition(Position - Step);
  if RepeatTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := 0;
  end;
  RepeatTimer := MessageLoop.ScheduleCallbackTimer(300, 50, AutoRepeat);
end;
{ @end $488DBC }

{ @routine $488E10 TCountBarGI_IncreasePressed }
procedure TCountBarGI.IncreasePressed(Sender: TObjectGI);
begin
  SetPosition(Position + Step);
  if RepeatTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(RepeatTimer);
    RepeatTimer := 0;
  end;
  RepeatTimer := MessageLoop.ScheduleCallbackTimer(300, 50, AutoRepeat);
end;
{ @end $488E10 }

{ @routine $488E64 TCountBarGI_ProcessMouseMove }
procedure TCountBarGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var TrackStart, TrackEnd: Integer;
begin
  inherited ProcessMouseMove(KeyState, Point);
  Point := ToLocalPoint(Point);
  if ThumbButton.Down and (Orientation = 1) then
  begin
    TrackStart := DecreaseButton.GetMaxStateImageSize.X + ThumbButton.GetMaxStateImageSize.X div 2;
    TrackEnd := ClientSize.X - IncreaseButton.GetMaxStateImageSize.X -
      (ThumbButton.GetMaxStateImageSize.X - ThumbButton.GetMaxStateImageSize.X div 2);
      if Maximum - Minimum = 0 then SetPosition(Minimum)
      else SetPosition(Integer(Round((Point.X - TrackStart) / (TrackEnd - TrackStart) * (Maximum - Minimum))) + Minimum);
  end;
end;
{ @end $488E64 }

{ @routine $488F94 TCountBarGI_OnMouseEnter }
procedure TCountBarGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
end;
{ @end $488F94 }

{ @routine $488F9C TCountBarGI_OnMouseLeave }
procedure TCountBarGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
end;
{ @end $488F9C }

{ @routine $488FA4 TCountBarGI_ProcessLeftButtonDown }
procedure TCountBarGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var TrackStart, TrackEnd: Integer;
begin
  inherited ProcessLeftButtonDown(KeyState, Point);
  if Active then MessageLoop.SetFocusedControl(Self);
  Point := ToLocalPoint(Point);
  if Orientation = 1 then
  begin
    TrackStart := DecreaseButton.GetMaxStateImageSize.X + ThumbButton.GetMaxStateImageSize.X div 2;
    TrackEnd := ClientSize.X - IncreaseButton.GetMaxStateImageSize.X -
      (ThumbButton.GetMaxStateImageSize.X - ThumbButton.GetMaxStateImageSize.X div 2);
    if (Point.X >= DecreaseButton.GetMaxStateImageSize.X) and
      (Point.X <= ClientSize.X - IncreaseButton.GetMaxStateImageSize.X) then
    begin
      if Maximum - Minimum = 0 then SetPosition(Minimum)
      else SetPosition(Integer(Round((Point.X - TrackStart) / (TrackEnd - TrackStart) * (Maximum - Minimum))) + Minimum);
      ThumbButton.SetDown(True);
    end;
  end;
end;
{ @end $488FA4 }

{ @routine $489118 TCountBarGI_ProcessLeftButtonUp }
procedure TCountBarGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  ThumbButton.SetDown(False);
  if MessageLoop.FocusedControl = Self then MessageLoop.SetFocusedControl(nil);
end;
{ @end $489118 }

{ @routine $489154 TCountBarGI_LoadFromConfigPath }
procedure TCountBarGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadCountBarProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $489154 }

{ @routine $489180 TCountBarGI_LoadFromBlock }
procedure TCountBarGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadCountBarProperties(Block);
end;
{ @end $489180 }

{ @routine $48919C TCountBarGI_LoadCountBarProperties }
procedure TCountBarGI.LoadCountBarProperties(Block: TBlockParEC);
begin
  if Block.CountParams('ImageDecNormal') > 0 then DecreaseButton.SetImageNormalPath(Block.GetParam('ImageDecNormal'));
  if Block.CountParams('ImageDecNormalA') > 0 then DecreaseButton.SetImageNormalActivePath(Block.GetParam('ImageDecNormalA'));
  if Block.CountParams('ImageDecDown') > 0 then DecreaseButton.SetImageDownPath(Block.GetParam('ImageDecDown'));
  if Block.CountParams('ImageIncNormal') > 0 then IncreaseButton.SetImageNormalPath(Block.GetParam('ImageIncNormal'));
  if Block.CountParams('ImageIncNormalA') > 0 then IncreaseButton.SetImageNormalActivePath(Block.GetParam('ImageIncNormalA'));
  if Block.CountParams('ImageIncDown') > 0 then IncreaseButton.SetImageDownPath(Block.GetParam('ImageIncDown'));
  if Block.CountParams('ImageTrackMin') > 0 then AfterThumbImage.SetImagePath(Block.GetParam('ImageTrackMin'));
  if Block.CountParams('ImageTrackMax') > 0 then BeforeThumbImage.SetImagePath(Block.GetParam('ImageTrackMax'));
  if Block.CountParams('ImageTrackPolNormal') > 0 then ThumbButton.SetImageNormalPath(Block.GetParam('ImageTrackPolNormal'));
  if Block.CountParams('ImageTrackPolNormalA') > 0 then ThumbButton.SetImageNormalActivePath(Block.GetParam('ImageTrackPolNormalA'));
  if Block.CountParams('ImageTrackPolDown') > 0 then ThumbButton.SetImageDownPath(Block.GetParam('ImageTrackPolDown'));
  UpdateLayout;
end;
{ @end $48919C }

end.

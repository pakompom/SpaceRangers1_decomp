unit GI_AImage;
// Unit bracket (inferred): CODE 0x00472C1C..0x004732DF; inclusive evidence, not full bounds.

interface

uses Classes, EC_BlockPar, GI_Main, GI_MessageLoop, Types;

type
  TAImageGI = class(TObjectGI) // @size $10C
  public
    FrameTimer: TCallbackTimerIdGI; // @offset $100
    ImageKindX: TImageKindXGI; // @offset $104
    ImageKindY: TImageKindYGI; // @offset $105
    HalfAlpha: Boolean; // @offset $106
    CurrentFrame: TObjectGI; // @offset $108

    constructor Create(Owner: TObjectGI); // @addr $472D2C
    destructor Destroy; override; // @addr $472D68
    procedure Clear; override; // @addr $472D90 @note "Does not call inherited Clear."
    function GetContentSize: TPoint; // @addr $472DC0 @note "Returns the componentwise maximum size over child frames."
    procedure SetImageKindX(Value: TImageKindXGI); // @addr $472E44
    procedure SetImageKindY(Value: TImageKindYGI); // @addr $472E7C
    procedure SetHalfAlpha(Value: Boolean); // @addr $472EB4
    procedure SetSize(Size: TPoint); override; // @addr $472EEC
    procedure AdvanceFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $472F28
    function HitTest(Point: TPoint): Boolean; // @addr $472FD8 @note "Uses rectangular child bounds, regardless of transparent pixels."
    procedure OnActivate; override; // @addr $473000
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $473018
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $473044
    procedure LoadAnimationProperties(Block: TBlockParEC); // @addr $473060 @note "Numeric parameter names supply frame delays; values select child images."
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $47326C
  end;

implementation

// @unit-initialization $4732D8
// @unit-finalization $4732A8

uses GI_Image, EC_Str, SysUtils;

{ @routine $472D2C TAImageGI_Create }
constructor TAImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  HalfAlpha := False;
end;
{ @end $472D2C }

{ @routine $472D68 TAImageGI_Destroy }
destructor TAImageGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $472D68 }

{ @routine $472D90 TAImageGI_Clear }
procedure TAImageGI.Clear;
begin
  HalfAlpha := False;
  if FrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := 0;
  end;
  CurrentFrame := nil;
end;
{ @end $472D90 }

{ @routine $472DC0 TAImageGI_GetContentSize }
function TAImageGI.GetContentSize: TPoint;
var Frame: TImageGI; Size: TPoint;
begin
  Result := Classes.Point(0, 0);
  Frame := FirstChild as TImageGI;
  if Frame <> nil then
  begin
    Result := Frame.GetContentSize;
    Frame := Frame.NextSibling as TImageGI;
  end;
  while Frame <> nil do
  begin
    Size := Frame.GetContentSize;
    if Result.X < Size.X then Result.X := Size.X;
    if Result.Y < Size.Y then Result.Y := Size.Y;
    Frame := Frame.NextSibling as TImageGI;
  end;
end;
{ @end $472DC0 }

{ @routine $472E44 TAImageGI_SetImageKindX }
procedure TAImageGI.SetImageKindX(Value: TImageKindXGI);
begin
  if ImageKindX <> Value then
  begin
    ImageKindX := Value;
    if CurrentFrame <> nil then (CurrentFrame as TImageGI).SetImageKindX(Value);
  end;
end;
{ @end $472E44 }

{ @routine $472E7C TAImageGI_SetImageKindY }
procedure TAImageGI.SetImageKindY(Value: TImageKindYGI);
begin
  if ImageKindY <> Value then
  begin
    ImageKindY := Value;
    if CurrentFrame <> nil then (CurrentFrame as TImageGI).SetImageKindY(Value);
  end;
end;
{ @end $472E7C }

{ @routine $472EB4 TAImageGI_SetHalfAlpha }
procedure TAImageGI.SetHalfAlpha(Value: Boolean);
begin
  if HalfAlpha <> Value then
  begin
    HalfAlpha := Value;
    if CurrentFrame <> nil then (CurrentFrame as TImageGI).SetHalfAlpha(Value);
  end;
end;
{ @end $472EB4 }

{ @routine $472EEC TAImageGI_SetSize }
procedure TAImageGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  if CurrentFrame <> nil then (CurrentFrame as TImageGI).SetSize(Size);
end;
{ @end $472EEC }

{ @routine $472F28 TAImageGI_AdvanceFrame }
procedure TAImageGI.AdvanceFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Previous, Next: TImageGI;
begin
  Previous := TImageGI(UserData);
  Next := Previous.NextSibling as TImageGI;
  if Next = nil then Next := FirstChild as TImageGI;
  MessageLoop.CancelCallbackTimer(FrameTimer);
  FrameTimer := MessageLoop.ScheduleCallbackTimer(Next.UserValue, $FFFFFF, AdvanceFrame, Cardinal(Next));
  Previous.SetActive(False);
  Next.SetActive(True);
  Next.SetOrigin(OriginPoint);
  Next.SetSize(ClientSize);
  Next.SetImageKindX(ImageKindX);
  Next.SetImageKindY(ImageKindY);
  Next.SetHalfAlpha(HalfAlpha);
  CurrentFrame := Next;
end;
{ @end $472F28 }

{ @routine $472FD8 TAImageGI_HitTest }
function TAImageGI.HitTest(Point: TPoint): Boolean;
begin
  if CurrentFrame = nil then Result := False
  else Result := CurrentFrame.ContainsPoint(Point);
end;
{ @end $472FD8 }

{ @routine $473000 TAImageGI_OnActivate }
procedure TAImageGI.OnActivate;
begin
  inherited OnActivate;
  AdvanceFrame(0, Cardinal(FirstChild));
end;
{ @end $473000 }

{ @routine $473018 TAImageGI_LoadFromConfigPath }
procedure TAImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadAnimationProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $473018 }

{ @routine $473044 TAImageGI_LoadFromBlock }
procedure TAImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadAnimationProperties(Block);
end;
{ @end $473044 }

{ @routine $473060 TAImageGI_LoadAnimationProperties }
procedure TAImageGI.LoadAnimationProperties(Block: TBlockParEC);
var Count, Index: Integer; HaveFrame: Boolean; Frame, First: TImageGI;
begin
  HaveFrame := False;
  Count := Block.GetParamCount;
  for Index := 0 to Count - 1 do
    if IsIntegerTextW(Block.GetParamName(Index)) then
    begin
      if not HaveFrame then FreeOwnedChildren;
      Frame := TImageGI.Create(Self);
      Frame.UserValue := StrToInt(Block.GetParamName(Index));
      Frame.SetDepth(Count + 1 - Index);
      Frame.SetImagePath(Block.GetParamValue(Index));
      if HaveFrame then Frame.SetActive(False);
      HaveFrame := True;
    end;
  CurrentFrame := nil;
  if FrameTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(FrameTimer);
    FrameTimer := 0;
  end;
  First := FirstChild as TImageGI;
  if First <> nil then
  begin
    FrameTimer := MessageLoop.ScheduleCallbackTimer(First.UserValue, $FFFFFF, AdvanceFrame, Cardinal(First));
    First.SetSize(ClientSize);
    First.SetImageKindX(ImageKindX);
    First.SetImageKindY(ImageKindY);
    CurrentFrame := First;
  end;
  if Block.CountParams('HalfAlpha') > 0 then SetHalfAlpha(ParseEnabledNameGI(Block.GetParam('HalfAlpha')));
end;
{ @end $473060 }

{ @routine $47326C TAImageGI_QueueImageLoad }
procedure TAImageGI.QueueImageLoad(PendingLoads: TList);
var Frame: TImageGI;
begin
  Frame := FirstChild as TImageGI;
  while Frame <> nil do
  begin
    Frame.QueueImageLoad(PendingLoads);
    Frame := Frame.NextSibling as TImageGI;
  end;
end;
{ @end $47326C }

end.

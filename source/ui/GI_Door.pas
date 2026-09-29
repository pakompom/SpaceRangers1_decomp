unit GI_Door;
// Unit bracket (inferred): CODE 0x004824B0..0x00482A43; inclusive evidence, not full bounds.

interface

uses EC_BlockPar, GI_GAI, GI_MessageLoop, Types;

type
  TDoorGI = class(TObjectGI) // @size $118
  public
    procedure Clear; override; // @addr $482648 Native empty override.
    Image: TgaiGI; // @offset $100
    FrameStep: Integer; // @offset $104
    StepTimer: TCallbackTimerIdGI; // @offset $108
    StepTime: Integer; // @offset $10C
    ClickCallback: TObjectNotifyEventGI; // @offset $110
    constructor Create(Owner: TObjectGI); // @addr $4825BC
    destructor Destroy; override; // @addr $482608
    procedure SetStepTime(Value: Integer); // @addr $48264C
    procedure SetSize(Size: TPoint); override; // @addr $48266C
    procedure StartStepTimer; // @addr $482698
    procedure StopStepTimer; // @addr $4826D0
    procedure StepFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $4826F4
    procedure OnActivate; override; // @addr $482758
    procedure OnDeactivate; override; // @addr $482778
    procedure OnMouseEnter; override; // @addr $482798
    procedure OnMouseLeave; override; // @addr $4827D4
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); override; // @addr $482810
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); override; // @addr $482874
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $4828C8
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4828F4
    procedure LoadDoorProperties(Block: TBlockParEC); // @addr $482910
  end;

implementation

// @unit-initialization $482A3C
// @unit-finalization $482A0C

uses EC_OKGF, SysUtils, GI_Main;

{ @routine $4825BC TDoorGI_Create }
constructor TDoorGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Image := TgaiGI.Create(Self);
end;
{ @end $4825BC }

{ @routine $482608 TDoorGI_Destroy }
destructor TDoorGI.Destroy;
begin
  StopStepTimer;
  Image.Free;
  Image := nil;
  inherited Destroy;
end;
{ @end $482608 }

{ @routine $482648 TDoorGI_Clear }
procedure TDoorGI.Clear;
begin
end;
{ @end $482648 }

{ @routine $48264C TDoorGI_SetStepTime }
procedure TDoorGI.SetStepTime(Value: Integer);
begin
  if StepTime <> Value then
  begin
    StepTime := Value;
    if FrameStep <> 0 then StartStepTimer;
  end;
end;
{ @end $48264C }

{ @routine $48266C TDoorGI_SetSize }
procedure TDoorGI.SetSize(Size: TPoint);
begin
  inherited SetSize(Size);
  Image.SetSize(Size);
end;
{ @end $48266C }

{ @routine $482698 TDoorGI_StartStepTimer }
procedure TDoorGI.StartStepTimer;
begin
  if FrameStep <> 0 then
  begin
    StopStepTimer;
    StepTimer := MessageLoop.ScheduleCallbackTimer(StepTime, StepTime, StepFrame);
  end;
end;
{ @end $482698 }

{ @routine $4826D0 TDoorGI_StopStepTimer }
procedure TDoorGI.StopStepTimer;
begin
  if StepTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(StepTimer);
    StepTimer := 0;
  end;
end;
{ @end $4826D0 }

{ @routine $4826F4 TDoorGI_StepFrame }
procedure TDoorGI.StepFrame(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Frame: Integer;
begin
  Frame := Image.SequenceFrame + FrameStep;
  if Frame <= 0 then
  begin
    Image.SetSequenceFrame(0);
    StopStepTimer;
    FrameStep := 0;
  end else if Frame >= Image.SequenceFrameCount - 1 then
  begin
    Image.SetSequenceFrame(Image.SequenceFrameCount - 1);
    StopStepTimer;
    FrameStep := 0;
  end else Image.SetSequenceFrame(Frame);
end;
{ @end $4826F4 }

{ @routine $482758 TDoorGI_OnActivate }
procedure TDoorGI.OnActivate;
begin
  inherited OnActivate;
  Image.SetSequenceFrame(0);
  StopStepTimer;
end;
{ @end $482758 }

{ @routine $482778 TDoorGI_OnDeactivate }
procedure TDoorGI.OnDeactivate;
begin
  inherited OnDeactivate;
  Image.SetSequenceFrame(0);
  StopStepTimer;
end;
{ @end $482778 }

{ @routine $482798 TDoorGI_OnMouseEnter }
procedure TDoorGI.OnMouseEnter;
begin
  inherited OnMouseEnter;
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
  begin
    FrameStep := 1;
    StartStepTimer;
  end;
end;
{ @end $482798 }

{ @routine $4827D4 TDoorGI_OnMouseLeave }
procedure TDoorGI.OnMouseLeave;
begin
  inherited OnMouseLeave;
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
  begin
    FrameStep := -1;
    StartStepTimer;
  end;
end;
{ @end $4827D4 }

{ @routine $482810 TDoorGI_ProcessMouseMove }
procedure TDoorGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessMouseMove(KeyState, Point);
  if IsOccludedAtPoint(Point) then
  begin
    FrameStep := -1;
    if StepTimer = 0 then StartStepTimer;
  end else
  begin
    FrameStep := 1;
    if StepTimer = 0 then StartStepTimer;
  end;
end;
{ @end $482810 }

{ @routine $482874 TDoorGI_ProcessLeftButtonUp }
procedure TDoorGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
begin
  inherited ProcessLeftButtonUp(KeyState, Point);
  if not IsOccludedAtPoint(MessageLoop.GetCursorPoint) then
    if Assigned(ClickCallback) then ClickCallback(Self);
end;
{ @end $482874 }

{ @routine $4828C8 TDoorGI_LoadFromConfigPath }
procedure TDoorGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadDoorProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $4828C8 }

{ @routine $4828F4 TDoorGI_LoadFromBlock }
procedure TDoorGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadDoorProperties(Block);
end;
{ @end $4828F4 }

{ @routine $482910 TDoorGI_LoadDoorProperties }
procedure TDoorGI.LoadDoorProperties(Block: TBlockParEC);
begin
  FrameStep := 0;
  if Block.CountParams('StepTime') > 0 then SetStepTime(StrToInt(Block.GetParam('StepTime')));
  if Block.CountParams('Image') > 0 then
  begin
    Image.SetImagePath(Block.GetParam('Image'));
    Image.SequenceIndex := 0;
    Image.UpdateAutoGeometry;
  end;
end;
{ @end $482910 }

end.

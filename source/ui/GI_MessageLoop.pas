unit GI_MessageLoop;
// Unit bracket (inferred): CODE 0x004A8860..0x004AD247; inclusive evidence, not full bounds.

interface

uses SysUtils, GR_Rect, Classes, EC_BlockPar, EC_Str, EC_Struct, Types;

type
  TCursorStateGI = packed record // @size $18
    ImagePath: WideString; // @offset $00
    Active: Boolean; // @offset $04
    HotSpot: TPoint; // @offset $05
    Position: TPoint; // @offset $0D
  end;
  // Native VMT $4A88AC lies in GI_MessageLoop; caught by ProcessWindowMessage.
  ExceptionBreakMessageGI = class(EAbort) // @size $0C
  end;

  TDialogChoiceEventGI = procedure(Value: Integer) of object;
  TObjectNotifyEventGI = procedure(Sender: TObjectGI) of object;
  TObjectMouseEventGI = procedure(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint) of object;
  TObjectHelpEventGI = procedure(Sender: TObjectGI; Visible: Boolean) of object;
  TObjectKeyEventGI = procedure(Sender: TObjectGI; Key: Cardinal) of object;

  TObjectGI = class;
  TFormSoundGroup = class;
  TMessageLoopGI = class;

  // Mouse-event slots follow the native WM_* dispatcher at $4AB738.
  TObjectGI = class(TObjectEx) // @size $100 @methodorder source
  public
    FirstChild: TObjectGI; // @offset $04
    LastChild: TObjectGI; // @offset $08
    PrevSibling: TObjectGI; // @offset $0C
    NextSibling: TObjectGI; // @offset $10
    Parent: TObjectGI; // @offset $14
    MessageLoop: TMessageLoopGI; // @offset $18
    LocalPosition: TPoint; // @offset $1C
    ClientSize: TPoint; // @offset $24
    OriginPoint: TPoint; // @offset $2C
    Depth: Double; // @offset $38
    PositionModeW: Boolean; // @offset $40
    Active: Boolean; // @offset $41
    ConfigPath: WideString; // @offset $44
    ScrollOffset: TPoint; // @offset $48  Copied as one point by panel scrolling.
    SkipOwnQueuedDraw: Integer; // @offset $50  Nonzero skips this object's queued draw, after visiting children.
    HitTestBounds: TRect; // @offset $54
    AbsolutePosition: TPoint; // @offset $64
    ControlName: WideString; // @offset $6C
    HelpText: WideString; // @offset $70
    HelpCallback: TObjectHelpEventGI; // @offset $78
    MouseInside: Boolean; // @offset $80
    MouseBlocking: Boolean; // @offset $81
    MouseBlockingTest: Boolean; // @offset $82
    ScrollUpdate: Boolean; // @offset $83  Controls panel invalidation during scrolling; loaded from ScrollUpdate.
    UserValue: Integer; // @offset $84  Grid cells pack column/row here; decorations use -1.
    UserIndex: Integer; // @offset $88 Usage unresolved.
    UserData: Integer; // @offset $8C Usage unresolved.
    UserState: Integer; // @offset $90 Usage unresolved.
    MouseMoveCallback: TObjectMouseEventGI; // @offset $98
    LeftButtonDownCallback: TObjectMouseEventGI; // @offset $A0
    LeftButtonUpCallback: TObjectMouseEventGI; // @offset $A8
    RightButtonDownCallback: TObjectMouseEventGI; // @offset $B0
    RightButtonUpCallback: TObjectMouseEventGI; // @offset $B8
    LeftButtonDoubleClickCallback: TObjectMouseEventGI; // @offset $C0
    MouseEnterCallback: TObjectNotifyEventGI; // @offset $C8
    MouseLeaveCallback: TObjectNotifyEventGI; // @offset $D0
    ActivateCallback: TObjectNotifyEventGI; // @offset $D8
    DeactivateCallback: TObjectNotifyEventGI; // @offset $E0
    DestroyNotify: TObjectNotifyEventGI; // @offset $E8
    KeyDownCallback: TObjectKeyEventGI; // @offset $F0
    KeyUpCallback: TObjectKeyEventGI; // @offset $F8

    constructor Create(Owner: TObjectGI); // @addr $4A8B30
    destructor Destroy; override; // @addr $4A8B90
    procedure FreeOwnedChildren; // @addr $4A8C04
    procedure Clear; virtual; // @addr $4A8C1C @slot $0 @note "Does not free children."
    property ML: TMessageLoopGI read MessageLoop;
    procedure AttachOwnedChild(Child: TObjectGI); // @addr $4A8C6C @note "Takes ownership; caller must detach an existing parent. Descendants' MessageLoop values are unchanged."
    procedure InsertOwnedChildBefore(BeforeChild, Child: TObjectGI); // @addr $4A8C98
    procedure InsertOwnedChildByDepth(Child: TObjectGI; NewDepth: Double); // @addr $4A8CD0 @note "Inserts in descending Depth order."
    procedure FreeOwnedChild(Child: TObjectGI); // @addr $4A8D20
    procedure UnlinkOwnedChild(Child: TObjectGI); // @addr $4A8D34 @note "Leaves sibling pointers and MessageLoop unchanged."
    property Obj_First: TObjectGI read FirstChild;
    property Obj_Last: TObjectGI read LastChild;
    property Obj_Next: TObjectGI read NextSibling;
    property Obj_Prev: TObjectGI read PrevSibling;
    property Obj_Parent: TObjectGI read Parent;
    procedure Reparent(NewParent: TObjectGI); // @addr $4A8D6C @note "Preserves Depth."
    procedure SetMouseViewUpdates(Enabled: Boolean); // @addr $4A8D90
    property MVUpdate: Boolean write SetMouseViewUpdates;
    procedure UpdateAbsolutePosition; // @addr $4A8DAC @note "Updates this control and recurses through active children."
    function GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint; virtual; // @addr $4A8E04 @slot $4 @note "Base implementation ignores ModeW."
    procedure UpdateHitTestBounds; virtual; // @addr $4A8E30 @slot $8
    procedure UpdateSubtreeHitBounds; // @addr $4A8E70 @note "Updates this control's hit-test rectangle and recurses through active children."
    function OffsetChildRect(Rect: TRect; ModeW: Boolean): TRect; // @addr $4A8E98 @note "Adds LocalPosition and subtracts ScrollOffset when ModeW is set."
    procedure SetPosition(Position: TPoint); virtual; // @addr $4A8F0C @slot $C
    property Pos: TPoint read LocalPosition write SetPosition;
    procedure SetDepth(NewDepth: Double); virtual; // @addr $4A8F78 @slot $10 @note "Does nothing without Parent."
    property PosZd: Double read Depth write SetDepth;
    procedure SetDepthByName(const Name: WideString); virtual; // @addr $4A8FE4 @slot $14
    property PosZ: WideString write SetDepthByName;
    procedure SetSize(Size: TPoint); virtual; // @addr $4A906C @slot $18
    property ObjectSize: TPoint read ClientSize write SetSize;
    procedure SetOrigin(Origin: TPoint); virtual; // @addr $4A90D8 @slot $1C
    property Sme: TPoint read OriginPoint write SetOrigin;
    procedure SetPositionModeW(Enabled: Boolean); // @addr $4A9144
    property World: Boolean read PositionModeW write SetPositionModeW;
    procedure SetConfigPath(const Path: WideString); virtual; // @addr $4A9184 @slot $20 @note "Virtual loading sees the previous ConfigPath."
    property Style: WideString read ConfigPath write SetConfigPath;
    function GetLocalBounds: TRect; virtual; // @addr $4A91A0 @slot $24
    procedure SetName(const Name: WideString); // @addr $4A91CC
    property Name: WideString read ControlName write SetName;
    property HintText: WideString read HelpText write HelpText;
    property OnHint: TObjectHelpEventGI read HelpCallback write HelpCallback;
    procedure SetActive(Enabled: Boolean); virtual; // @addr $4A91E0 @slot $28
    property IsActive: Boolean read Active write SetActive;
    property BlocksMouse: Boolean read MouseBlocking write MouseBlocking;
    property TestMouseBlocking: Boolean read MouseBlockingTest write MouseBlockingTest;
    function FindDeepestChildAtPoint(Point: TPoint): TObjectGI; // @addr $4A922C @note "Returns Self when no child contains Point."
    function IsOccludedAtPoint(Point: TPoint): Boolean; // @addr $4A926C
    property DataUser: Integer read UserValue write UserValue;
    property DataUser2: Integer read UserIndex write UserIndex;
    property DataUser3: Integer read UserData write UserData;
    property DataUser4: Integer read UserState write UserState;
    procedure QueueImageLoad(PendingLoads: TList); virtual; // @addr $4A929C @slot $2C
    procedure LoadFromConfigPath(const Path: WideString); virtual; // @addr $4A9B94 @slot $30
    procedure ProcessMouseMove(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A92A0 @slot $34
    procedure OnMouseEnter; virtual; // @addr $4A9358 @slot $38
    procedure OnMouseLeave; virtual; // @addr $4A93AC @slot $3C
    function FindByNameRecursive(const Name: WideString): TObjectGI; // @addr $4A97A0 @note "Case-sensitive; includes Self. Duplicate names resolve in child-list order."
    procedure DispatchNamedEvent(EventKind, Param1, Param2: Integer); // @addr $4A9820
    procedure InvalidateChildren(IncludePanels: Boolean); // @addr $4A9914
    function InvalidateScrollOverlap(Rect: TRect; Delta: TPoint; StartControl: TObjectGI): TObjectGI; // @addr $4A995C @note "Walks active panel subtrees until StartControl, then invalidates affected controls by moving them out and back. Rect is passed through but unused."
    procedure OnActivate; virtual; // @addr $4A9424 @slot $40
    procedure NativeHook48; virtual; // @addr $4A945C @slot $44 @note "Purpose unresolved; the base hook visits children whose Active flag equals True."
    procedure OnDeactivate; virtual; // @addr $4A947C @slot $48
    procedure NativeHook50; virtual; // @addr $4A94B4 @slot $4C @note "Purpose unresolved; the base hook visits children whose Active flag equals True."
    procedure ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A94D4 @slot $50
    procedure ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A9534 @slot $54
    procedure ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A9594 @slot $58
    procedure ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A95F4 @slot $5C
    procedure ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint); virtual; // @addr $4A9654 @slot $60
    procedure BroadcastKeyDown(Key: Cardinal); virtual; // @addr $4A96B4 @slot $64
    procedure BroadcastKeyUp(Key: Cardinal); virtual; // @addr $4A96F0 @slot $68
    procedure OnFocusGained; virtual; // @addr $4A972C @slot $6C
    procedure OnFocusLost; virtual; // @addr $4A9730 @slot $70
    procedure ProcessKeyDown(Key: Integer); virtual; // @addr $4A9734 @slot $74
    procedure ProcessCharacter(Character: WideChar); virtual; // @addr $4A9738 @slot $78
    procedure OnCaretBlink; virtual; // @addr $4A973C @slot $7C @note "Called on the focused control when CaretBlinkOn changes."
    property FunMouseMove: TObjectMouseEventGI read MouseMoveCallback write MouseMoveCallback;
    property FunMouseLDown: TObjectMouseEventGI read LeftButtonDownCallback write LeftButtonDownCallback;
    property FunMouseLUp: TObjectMouseEventGI read LeftButtonUpCallback write LeftButtonUpCallback;
    property FunMouseRDown: TObjectMouseEventGI read RightButtonDownCallback write RightButtonDownCallback;
    property FunMouseRUp: TObjectMouseEventGI read RightButtonUpCallback write RightButtonUpCallback;
    property FunMouseLDbl: TObjectMouseEventGI read LeftButtonDoubleClickCallback write LeftButtonDoubleClickCallback;
    property FunMouseEnter: TObjectNotifyEventGI read MouseEnterCallback write MouseEnterCallback;
    property FunMouseLeave: TObjectNotifyEventGI read MouseLeaveCallback write MouseLeaveCallback;
    property FunActivate: TObjectNotifyEventGI read ActivateCallback write ActivateCallback;
    property FunDeActivate: TObjectNotifyEventGI read DeactivateCallback write DeactivateCallback;
    property FunObjDestroy: TObjectNotifyEventGI read DestroyNotify write DestroyNotify;
    property FunKeyDown: TObjectKeyEventGI read KeyDownCallback write KeyDownCallback;
    property FunKeyUp: TObjectKeyEventGI read KeyUpCallback write KeyUpCallback;
    function ContainsPoint(Point: TPoint): Boolean; // @addr $4A9740 @note "Requires Active and enabled hit testing; right and bottom edges are exclusive."
    function HitTestCursor: Boolean; // @addr $4A9780
    function ToLocalPoint(Point: TPoint): TPoint; virtual; // @addr $4A97D8 @slot $80
    function ToAbsolutePoint(Point: TPoint): TPoint; virtual; // @addr $4A97FC @slot $84
    procedure InvalidateRect(Rect: TRect); virtual; // @addr $4A9854 @slot $88
    procedure Invalidate; virtual; // @addr $4A98DC @slot $8C
    procedure Draw(ClipRect: TRect); virtual; // @addr $4A9A1C @slot $90 @note "Suppressed while PendingRedraw is set."
    procedure DrawUpdateRects(ClipRect: TRect); virtual; // @addr $4A9A74 @slot $94
    procedure CommitFrameDraw; virtual; // @addr $4A9AFC @slot $98 @note "After a successful frame; derived controls retain state needed to erase their previous drawing."
    procedure ErasePreviousFrame; virtual; // @addr $4A9B20 @slot $9C @note "Before queued drawing; derived controls restore their saved background pixels."
    procedure NativeHookB0; virtual; // @addr $4A9B44 @slot $A0 @note "Purpose unresolved; the base hook visits active children."
    procedure PrepareFrameDraw; virtual; // @addr $4A9B68 @slot $A4 @note "Before DrawUpdateRects; derived controls capture backgrounds or prepare geometry."
    procedure PrepareRegionDraw(ClipRect: TRect); virtual; // @addr $4A9B8C @slot $A8 @note "Empty base hook called before queued drawing for RegionDrawControl."
    procedure NativeHookBC(Rect: TRect); virtual; // @addr $4A9B90 @slot $AC @note "Empty base hook; purpose unresolved."
    procedure LoadFromBlock(Block: TBlockParEC); virtual; // @addr $4AA0A0 @slot $B0
    procedure UpdateAutoGeometry; virtual; // @addr $4AA608 @slot $B4
  end;

  PCursorStateGI = ^TCursorStateGI;
  TFormSoundGroup = class(TObjectEx) // @size $1C
  public
    Section: Integer; // @offset $04
    MinDelayMs: Integer; // @offset $08
    MaxDelayMs: Integer; // @offset $0C
    NextPlayTick: Cardinal; // @offset $10
    TotalWeight: Integer; // @offset $14
    Sounds: TStringsEC; // @offset $18
    // Each string is a sound name; its Data slot stores an integer weight.

    constructor Create; // @addr $4AA624
    destructor Destroy; override; // @addr $4AA668
    procedure Clear; // @addr $4AA6A4 @note "Preserves timing fields and TotalWeight."
    procedure LoadFromBlock(Block: TBlockParEC); // @addr $4AA6B8 @note "Numeric parameter names are weights; their values are sound names."
    procedure ScheduleNextPlayback; // @addr $4AA884
    procedure PlayIfDue; // @addr $4AA8A4
  end;

  TCallbackTimerIdGI = Cardinal;
  PCallbackTimerGI = ^TCallbackTimerGI;
  TCallbackTimerEventGI = procedure(Timer: TCallbackTimerIdGI; UserData: Cardinal) of object;
  TCallbackTimerGI = packed record // @size $20
    Callback: TCallbackTimerEventGI; // @offset $00
    UserData: Cardinal; // @offset $08
    RepeatMs: Cardinal; // @offset $0C
    DueTick: Cardinal; // @offset $10
    Prev: PCallbackTimerGI; // @offset $14
    Next: PCallbackTimerGI; // @offset $18
    // The final dword is not initialized or read by the timer list routines.
  end;

  TSavedLineGI = record // @size $18
    First: TPoint; // @offset $00
    Last: TPoint; // @offset $08
    Pixels: Pointer; // @offset $10
    Heap: Cardinal; // @offset $14
  end;
  TSavedLinesGI = array of TSavedLineGI;

  TMessageLoopGI = class(TObjectEx) // @size $B0
  public
    DebugControl: TObjectGI; // @offset $04  Layout inspector selection; confirmed by mouse dispatch at $4AB738.
    StatusLabel: TObjectGI; // @offset $08
    RootUiObject: TObjectGI; // @offset $0C
    ContentPanel: TObjectGI; // @offset $10
    BackgroundPanel: TObjectGI; // @offset $14
    OverlayPanel: TObjectGI; // @offset $18
    CursorControl: TObjectGI; // @offset $1C
    FocusedControl: TObjectGI; // @offset $20
    HelpLabel: TObjectGI; // @offset $24
    RegionDrawControl: TObjectGI; // @offset $28
    MouseViewUpdateControls: TList; // @offset $2C
    RegionDrawPending: Boolean; // @offset $30
    CursorImagePath: WideString; // @offset $34
    ViewportRect: TRect; // @offset $38
    UpdateRectsEnabled: Boolean; // @offset $48
    UpdateRects: TArrayRectGR; // @offset $4C
    ExitCode: Integer; // @offset $50
    CaretBlinkOn: Boolean; // @offset $54
    TimerTick: Cardinal; // @offset $58
    FirstTimer: PCallbackTimerGI; // @offset $5C
    LastTimer: PCallbackTimerGI; // @offset $60
    NextTimerToProcess: PCallbackTimerGI; // @offset $64
    LastObservedTimerTick: Cardinal; // @offset $68
    SavedPixels16: Pointer; // @offset $6C  Eight-byte entries: byte offset, then a pixel word in a dword slot.
    SavedPixelCount16: Integer; // @offset $70
    SavedPixelCapacity16: Integer; // @offset $74
    SecondaryPixelBuffer: Pointer; // @offset $78  Dword byte offsets; ResetSecondaryPixelCount copies the corresponding pixel words to ScreenPresentBuffer.
    SecondaryPixelCount: Integer; // @offset $7C
    SecondaryPixelCapacity: Integer; // @offset $80
    SavedLines: array of TSavedLineGI; // @offset $84
    SavedLineCount: Integer; // @offset $88
    PendingRedraw: Boolean; // @offset $8C
    ContinuousLoop: Boolean; // @offset $8D
    FramesPerSecond: Integer; // @offset $90
    PlayTransitionSounds: Boolean; // @offset $94
    OpenSoundName: WideString; // @offset $98
    CloseSoundName: WideString; // @offset $9C
    SoundSection: Integer; // @offset $A0
    SoundGroupList: TList; // @offset $A4
    TransientControl: TObjectGI; // @offset $A8  Demo text window, freed when Run/RunContinuous finishes.
    TransientData: TObject; // @offset $AC  Demo text label, freed before TransientControl.

    function Run: Integer; virtual; // @addr $4AACB4 @slot $0
    function RunContinuous: Integer; virtual; // @addr $4AB258 @slot $4 @note "Sleeps 1 ms per frame, caps elapsed draw ticks at 200 and updates FPS once per second."
    procedure AdvanceTimerTick; virtual; // @addr $4AB69C @slot $8
    procedure DrawFrame; virtual; // @addr $4AB6EC @slot $C
    procedure Present; virtual; // @addr $4AB708 @slot $10
    procedure ProcessNamedControlEvent(ControlName: WideString; EventKind, Param1, Param2: Integer); virtual; // @addr $4AC23C @slot $14
    procedure OnOpen; virtual; // @addr $4AC268 @slot $18
    procedure OnClose; virtual; // @addr $4AC26C @slot $1C
    procedure ProcessCallbackTimers; virtual; // @addr $4AC270 @slot $20 @note "May wait for a timer or Windows message; zero RepeatMs still repeats."
    procedure SelectMusic; virtual; // @addr $4AC304 @slot $24
    procedure ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer); virtual; // @addr $4ACA60 @slot $28
    procedure InitializeLayout; virtual; // @addr $4AD204 @slot $2C
    constructor Create; // @addr $4AA944
    destructor Destroy; override; // @addr $4AA9B4
    procedure ResetRuntime; // @addr $4AAA04 @note "Frees the root tree and cancels callback timers."
    procedure ClearUpdateRects; // @addr $4AAA80
    procedure QueueUpdateRect(Rect: TRect); // @addr $4AAA8C @note "Clips to GameScreenRect; does nothing when update rectangles are disabled."
    procedure InvalidateViewport; // @addr $4AAACC
    function FindMouseViewUpdateControl(Control: TObjectGI): Integer; // @addr $4AAB00
    procedure AddMouseViewUpdateControl(Control: TObjectGI); // @addr $4AAB38 @note "Duplicates are ignored."
    procedure RemoveMouseViewUpdateControl(Control: TObjectGI); // @addr $4AAB58
    procedure InvalidateMouseViewControls; // @addr $4AAB74
    procedure DrawQueuedUpdateRects; // @addr $4AABA4 @note "Leaves queued rectangles in place."
    procedure DrawQueuedControlRects; // @addr $4AABEC @note "Sets PendingRedraw and traverses queued drawing through the root tree."
    procedure FinishQueuedDraw; // @addr $4AAC34
    procedure CommitFrameDraw; // @addr $4AAC90
    procedure ErasePreviousFrame; // @addr $4AAC9C
    procedure PrepareFrameDraw; // @addr $4AACA8
    function ProcessUiIteration: Boolean; // @addr $4AB140
    procedure ProcessWindowMessage(Message, WParam: Cardinal; LParam: Integer); // @addr $4AB738 @note "Dispatches mouse/keyboard messages, deferred UI code and layout-inspector keys. Mouse coordinates are unsigned words; wheel delta is signed."
    procedure ReplayFormTransition; // @addr $4ABE74 @note "Skips queued input until the next matching form record, except for the game-load and load screens."
    procedure RequestClose(Code: Integer); // @addr $4AC134
    function GetByName(const Name: WideString): TObjectGI; // @addr $4AC138 @note "Search is limited to ContentPanel; raises when absent."
    function FindControlByPath(const Path: WideString): TObjectGI; // @addr $4AC200 @note "Each component may match a descendant, not just a direct child. Returns nil when absent."
    procedure SetFocusedControl(Control: TObjectGI); // @addr $4AC20C
    function ScheduleCallbackTimer(DelayMs, RepeatMs: Cardinal; Callback: TCallbackTimerEventGI; UserData: Cardinal = 0): TCallbackTimerIdGI; // @addr $4AC308 @note "Computes DueTick from the stored TimerTick, not a new clock sample."
    procedure CancelCallbackTimer(Timer: TCallbackTimerIdGI); // @addr $4AC378
    procedure UpdateCallbackTimer(Timer: TCallbackTimerIdGI; DelayMs, RepeatMs: Cardinal); // @addr $4AC3C0
    procedure ReinsertCallbackTimer(Timer: TCallbackTimerIdGI); // @addr $4AC3E8
    procedure RefreshTimerTick; // @addr $4AC474
    procedure SetCursorImage(const ImagePath: WideString; HotSpot: TPoint); // @addr $4AC484
    procedure SetCursorByName(const Name: WideString); // @addr $4AC4C4
    function IsCursorImageSelected(const RegisteredName: WideString): Boolean; // @addr $4AC4E0 @note "Ignores cursor activity; registered names with the same image path compare equal."
    function IsCursorActive: Boolean; // @addr $4AC500
    procedure SetCursorActive(Enabled: Boolean); // @addr $4AC508
    procedure CaptureCursorState(State: PCursorStateGI); // @addr $4AC51C @note "Writes caller-owned state; its WideString must be initialized."
    procedure RestoreCursorState(State: PCursorStateGI); // @addr $4AC558 @note "Reads caller-owned state through a pointer. Always uses the image cursor."
    procedure UpdateCursorPosition; // @addr $4AC584 @note "Moves the image cursor to the system mouse position, converted to client coordinates in windowed mode."
    function GetCursorPoint: TPoint; // @addr $4AC5B8 @note "Returns CursorControl's local position."
    procedure SetSystemCursorPosition(Point: TPoint); // @addr $4AC5C8 @note "Uses screen coordinates."
    function ConsumeTimerTickChange: Boolean; // @addr $4AC5E8 @note "Returns true once for each changed TimerTick."
    function QueryPointOcclusionState(Point: TPoint; IgnoreControl, StartControl: TObjectGI): Integer; // @addr $4AC5FC @note "Starts at RootUiObject when StartControl is nil; returns 1 for a blocker, -1 for IgnoreControl, or 0 for no hit."
    procedure FreeSavedPixels16; // @addr $4AC684
    procedure SavePixel16(ByteOffset: Integer; Color: Word); // @addr $4AC6A4
    procedure RestoreSavedPixels16; // @addr $4AC710 @note "Contains a native handwritten PUSHAD/POPAD loop at $4AC738..$4AC754."
    procedure FreeSecondaryPixelBuffer; // @addr $4AC760
    procedure QueuePixelPresent(ByteOffset: Integer); // @addr $4AC784
    procedure ResetSecondaryPixelCount; // @addr $4AC7D4
    procedure FreeSavedLines; // @addr $4AC834 @note "Frees every allocated array slot, including slots beyond SavedLineCount."
    procedure AddSavedLine(First, Last: TPoint; Pixels: Pointer); // @addr $4AC88C @note "Takes the pixel allocation; records the process heap."
    procedure RestoreSavedLines; // @addr $4AC954
    procedure ResetSavedLineCount; // @addr $4AC9D0 Copies saved line regions to the presentation buffer before resetting.
    procedure ShowTransientText(Position: TPoint; const Text: WideString); // @addr $4ACA68
    procedure ClearTransientControl; // @addr $4ACD10
    procedure InvalidateTransientControl; // @addr $4ACD58 @note "Temporarily enables queued invalidation; an exception leaves it enabled."
    procedure InitializeDefaults; // @addr $4ACD80
    procedure InitializeFromConfig(ConfigRoot: TBlockParEC; const ScreenName: WideString; UnusedFlag: Boolean); // @addr $4ACF38
  end;

var

implementation

// @unit-initialization $4AD240
// @unit-finalization $4AD210

uses GI_GAI, GI_Main, EC_Mem, MMSystem, Windows, Messages, GR_Main, GR_Demo, SysUtils, aMyFunction, GR_Sound, GI_Cursor, GI_Label, GI_Panel, GlobalsV, EC_OKGF, GI_GraphBuf, GI_Window;

{ @routine $4A8B30 TObjectGI_Create }
constructor TObjectGI.Create(Owner: TObjectGI);
begin
  inherited Create;
  Active := True;
  MouseBlocking := False;
  MouseBlockingTest := True;
  ScrollUpdate := False;
  if Owner <> nil then Owner.AttachOwnedChild(Self);
end;
{ @end $4A8B30 }

{ @routine $4A8B90 TObjectGI_Destroy }
destructor TObjectGI.Destroy;
begin
    MessageLoop.RemoveMouseViewUpdateControl(Self);
    if MessageLoop.FocusedControl = Self then MessageLoop.SetFocusedControl(nil);
  Clear;
  FreeOwnedChildren;
  if Parent <> nil then Parent.UnlinkOwnedChild(Self);
  if Assigned(DestroyNotify) then DestroyNotify(Self);
  inherited Destroy;
end;
{ @end $4A8B90 }

{ @routine $4A8C04 TObjectGI_FreeOwnedChildren }
procedure TObjectGI.FreeOwnedChildren;
begin
  while LastChild <> nil do FreeOwnedChild(FirstChild);
end;
{ @end $4A8C04 }

{ @routine $4A8C1C TObjectGI_Clear }
procedure TObjectGI.Clear;
begin
  LocalPosition.X := 0;
  LocalPosition.Y := 0;
  ClientSize.X := 0;
  ClientSize.Y := 0;
  OriginPoint.X := 0;
  OriginPoint.Y := 0;
  Depth := 0;
  PositionModeW := False;
  Active := True;
  ConfigPath := '';
  MouseBlocking := False;
  MouseBlockingTest := True;
  ScrollUpdate := False;
end;
{ @end $4A8C1C }

{ @routine $4A8C6C TObjectGI_AttachOwnedChild }
procedure TObjectGI.AttachOwnedChild(Child: TObjectGI);
begin
  if LastChild <> nil then LastChild.NextSibling := Child;
  Child.PrevSibling := LastChild;
  Child.NextSibling := nil;
  LastChild := Child;
  if FirstChild = nil then FirstChild := Child;
  Child.Parent := Self;
  Child.MessageLoop := MessageLoop;
end;
{ @end $4A8C6C }

{ @routine $4A8C98 TObjectGI_InsertOwnedChildBefore }
procedure TObjectGI.InsertOwnedChildBefore(BeforeChild, Child: TObjectGI);
begin
  if BeforeChild <> nil then
  begin
    Child.PrevSibling := BeforeChild.PrevSibling;
    Child.NextSibling := BeforeChild;
    if BeforeChild.PrevSibling <> nil then BeforeChild.PrevSibling.NextSibling := Child;
    BeforeChild.PrevSibling := Child;
    if FirstChild = BeforeChild then FirstChild := Child;
    Child.Parent := Self;
    Child.MessageLoop := MessageLoop;
  end
  else AttachOwnedChild(Child);
end;
{ @end $4A8C98 }

{ @routine $4A8CD0 TObjectGI_InsertOwnedChildByDepth }
procedure TObjectGI.InsertOwnedChildByDepth(Child: TObjectGI; NewDepth: Double);
var BeforeChild: TObjectGI;
begin
  Child.Depth := NewDepth;
  BeforeChild := FirstChild;
  while BeforeChild <> nil do
  begin
    if BeforeChild.Depth <= NewDepth then
    begin
      InsertOwnedChildBefore(BeforeChild, Child);
      Break;
    end;
    BeforeChild := BeforeChild.NextSibling;
  end;
  if BeforeChild = nil then AttachOwnedChild(Child);
end;
{ @end $4A8CD0 }

{ @routine $4A8D20 TObjectGI_FreeOwnedChild }
procedure TObjectGI.FreeOwnedChild(Child: TObjectGI);
begin
  UnlinkOwnedChild(Child);
  Child.Free;
end;
{ @end $4A8D20 }

{ @routine $4A8D34 TObjectGI_UnlinkOwnedChild }
procedure TObjectGI.UnlinkOwnedChild(Child: TObjectGI);
begin
  if Child.PrevSibling <> nil then Child.PrevSibling.NextSibling := Child.NextSibling;
  if Child.NextSibling <> nil then Child.NextSibling.PrevSibling := Child.PrevSibling;
  if LastChild = Child then LastChild := Child.PrevSibling;
  if FirstChild = Child then FirstChild := Child.NextSibling;
  Child.Parent := nil;
end;
{ @end $4A8D34 }

{ @routine $4A8D6C TObjectGI_Reparent }
procedure TObjectGI.Reparent(NewParent: TObjectGI);
begin
  Parent.UnlinkOwnedChild(Self);
  NewParent.InsertOwnedChildByDepth(Self, Depth);
end;
{ @end $4A8D6C }

{ @routine $4A8D90 TObjectGI_SetMouseViewUpdates }
procedure TObjectGI.SetMouseViewUpdates(Enabled: Boolean);
begin
  if Enabled = True then MessageLoop.AddMouseViewUpdateControl(Self)
  else MessageLoop.RemoveMouseViewUpdateControl(Self);
end;
{ @end $4A8D90 }

{ @routine $4A8DAC TObjectGI_UpdateAbsolutePosition }
procedure TObjectGI.UpdateAbsolutePosition;
var Child: TObjectGI;
begin
  if Parent <> nil then
    AbsolutePosition := Parent.GetChildAbsolutePosition(LocalPosition, PositionModeW)
  else
  begin
    AbsolutePosition.X := LocalPosition.X;
    AbsolutePosition.Y := LocalPosition.Y;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.UpdateAbsolutePosition;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A8DAC }

{ @routine $4A8E04 TObjectGI_GetChildAbsolutePosition }
function TObjectGI.GetChildAbsolutePosition(LocalPosition: TPoint; ModeW: Boolean): TPoint;
begin
  Result.X := AbsolutePosition.X + LocalPosition.X;
  Result.Y := AbsolutePosition.Y + LocalPosition.Y;
end;
{ @end $4A8E04 }

{ @routine $4A8E30 TObjectGI_UpdateHitTestBounds }
procedure TObjectGI.UpdateHitTestBounds;
begin
  HitTestBounds := Classes.Rect(AbsolutePosition.X - OriginPoint.X, AbsolutePosition.Y - OriginPoint.Y,
    AbsolutePosition.X - OriginPoint.X + ClientSize.X, AbsolutePosition.Y - OriginPoint.Y + ClientSize.Y);
end;
{ @end $4A8E30 }

{ @routine $4A8E70 TObjectGI_UpdateSubtreeHitBounds }
procedure TObjectGI.UpdateSubtreeHitBounds;
var Child: TObjectGI;
begin
  UpdateHitTestBounds;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.UpdateSubtreeHitBounds;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A8E70 }

{ @routine $4A8E98 TObjectGI_OffsetChildRect }
function TObjectGI.OffsetChildRect(Rect: TRect; ModeW: Boolean): TRect;
begin
  if not ModeW then
  begin
    Result.Left := LocalPosition.X + Rect.Left;
    Result.Top := LocalPosition.Y + Rect.Top;
    Result.Right := LocalPosition.X + Rect.Right;
    Result.Bottom := LocalPosition.Y + Rect.Bottom;
  end
  else
  begin
    Result.Left := LocalPosition.X + Rect.Left - ScrollOffset.X;
    Result.Top := LocalPosition.Y + Rect.Top - ScrollOffset.Y;
    Result.Right := LocalPosition.X + Rect.Right - ScrollOffset.X;
    Result.Bottom := LocalPosition.Y + Rect.Bottom - ScrollOffset.Y;
  end;
end;
{ @end $4A8E98 }

{ @routine $4A8F0C TObjectGI_SetPosition }
procedure TObjectGI.SetPosition(Position: TPoint);
begin
  if (LocalPosition.X = Position.X) and (LocalPosition.Y = Position.Y) then Exit;
  if not Active then LocalPosition := Position
  else
  begin
    Invalidate;
    LocalPosition := Position;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4A8F0C }

{ @routine $4A8F78 TObjectGI_SetDepth }
procedure TObjectGI.SetDepth(NewDepth: Double);
begin
  if Depth = NewDepth then Exit;
  if Parent = nil then Exit;
  if PrevSibling <> nil then PrevSibling.NextSibling := NextSibling;
  if NextSibling <> nil then NextSibling.PrevSibling := PrevSibling;
  if Parent.LastChild = Self then Parent.LastChild := PrevSibling;
  if Parent.FirstChild = Self then Parent.FirstChild := NextSibling;
  Parent.InsertOwnedChildByDepth(Self, NewDepth);
  Invalidate;
end;
{ @end $4A8F78 }

{ @routine $4A8FE4 TObjectGI_SetDepthByName }
procedure TObjectGI.SetDepthByName(const Name: WideString);
var Value: WideString;
begin
  Value := UiDepthConfig.GetParamOrMarker(Name);
  if Value <> '' then SetDepth(ExtractDecimalToSingleW(Value))
  else SetDepth(ExtractDecimalToSingleW(Name));
end;
{ @end $4A8FE4 }

{ @routine $4A906C TObjectGI_SetSize }
procedure TObjectGI.SetSize(Size: TPoint);
begin
  if (ClientSize.X = Size.X) and (ClientSize.Y = Size.Y) then Exit;
  if not Active then ClientSize := Size
  else
  begin
    Invalidate;
    ClientSize := Size;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4A906C }

{ @routine $4A90D8 TObjectGI_SetOrigin }
procedure TObjectGI.SetOrigin(Origin: TPoint);
begin
  if (OriginPoint.X = Origin.X) and (OriginPoint.Y = Origin.Y) then Exit;
  if not Active then OriginPoint := Origin
  else
  begin
    Invalidate;
    OriginPoint := Origin;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4A90D8 }

{ @routine $4A9144 TObjectGI_SetPositionModeW }
procedure TObjectGI.SetPositionModeW(Enabled: Boolean);
begin
  if PositionModeW = Enabled then Exit;
  if not Active then PositionModeW := Enabled
  else
  begin
    Invalidate;
    PositionModeW := Enabled;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
  end;
end;
{ @end $4A9144 }

{ @routine $4A9184 TObjectGI_SetConfigPath }
procedure TObjectGI.SetConfigPath(const Path: WideString);
begin
  LoadFromConfigPath(Path);
  ConfigPath := Path;
end;
{ @end $4A9184 }

{ @routine $4A91A0 TObjectGI_GetLocalBounds }
function TObjectGI.GetLocalBounds: TRect;
begin
  Result.Left := LocalPosition.X - OriginPoint.X;
  Result.Top := LocalPosition.Y - OriginPoint.Y;
  Result.Right := LocalPosition.X - OriginPoint.X + ClientSize.X;
  Result.Bottom := LocalPosition.Y - OriginPoint.Y + ClientSize.Y;
end;
{ @end $4A91A0 }

{ @routine $4A91CC TObjectGI_SetName }
procedure TObjectGI.SetName(const Name: WideString);
begin
  ControlName := Name;
end;
{ @end $4A91CC }

{ @routine $4A91E0 TObjectGI_SetActive }
procedure TObjectGI.SetActive(Enabled: Boolean);
begin
  if Active = Enabled then Exit;
  if Enabled = True then
  begin
    Active := Enabled;
    UpdateAbsolutePosition;
    UpdateSubtreeHitBounds;
    Invalidate;
    OnActivate;
  end
  else
  begin
    Invalidate;
    Active := Enabled;
    OnDeactivate;
  end;
end;
{ @end $4A91E0 }

{ @routine $4A922C TObjectGI_FindDeepestChildAtPoint }
function TObjectGI.FindDeepestChildAtPoint(Point: TPoint): TObjectGI;
var Child: TObjectGI;
begin
  Child := LastChild;
  while Child <> nil do
  begin
    if Child.ContainsPoint(Point) then
    begin
      Result := Child.FindDeepestChildAtPoint(Point);
      Exit;
    end;
    Child := Child.PrevSibling;
  end;
  Result := Self;
end;
{ @end $4A922C }

{ @routine $4A926C TObjectGI_IsOccludedAtPoint }
function TObjectGI.IsOccludedAtPoint(Point: TPoint): Boolean;
begin
  if MessageLoop.QueryPointOcclusionState(Point, Self, nil) = 1 then Result := True
  else Result := False;
end;
{ @end $4A926C }

{ @routine $4A929C TObjectGI_QueueImageLoad }
procedure TObjectGI.QueueImageLoad(PendingLoads: TList);
begin
end;
{ @end $4A929C }

{ @routine $4A92A0 TObjectGI_ProcessMouseMove }
procedure TObjectGI.ProcessMouseMove(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(MouseMoveCallback) then MouseMoveCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and not Child.ContainsPoint(Point) and (Child.MouseInside = True) then
      Child.OnMouseLeave;
    Child := Child.NextSibling;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then
    begin
      if not Child.MouseInside then Child.OnMouseEnter;
      Child.ProcessMouseMove(KeyState, Point);
      DispatchNamedEvent(3, Point.X, Point.Y);
    end;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A92A0 }

{ @routine $4A9358 TObjectGI_OnMouseEnter }
procedure TObjectGI.OnMouseEnter;
begin
  if Assigned(MouseEnterCallback) then MouseEnterCallback(Self);
  MouseInside := True;
  if (HelpText <> '') and (MessageLoop.HelpLabel <> nil) then (MessageLoop.HelpLabel as TLabelGI).SetText(HelpText);
end;
{ @end $4A9358 }

{ @routine $4A93AC TObjectGI_OnMouseLeave }
procedure TObjectGI.OnMouseLeave;
var Child: TObjectGI;
begin
  if Assigned(MouseLeaveCallback) then MouseLeaveCallback(Self);
  MouseInside := False;
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and (Child.MouseInside = True) then Child.OnMouseLeave;
    Child := Child.NextSibling;
  end;
  if (HelpText <> '') and (MessageLoop.HelpLabel <> nil) then
    (MessageLoop.HelpLabel as TLabelGI).SetText('');
end;
{ @end $4A93AC }

{ @routine $4A9424 TObjectGI_OnActivate }
procedure TObjectGI.OnActivate;
var Child: TObjectGI;
begin
  if Assigned(ActivateCallback) then ActivateCallback(Self);
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.OnActivate;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9424 }

{ @routine $4A945C TObjectGI_NativeHook48 }
procedure TObjectGI.NativeHook48;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.NativeHook48;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A945C }

{ @routine $4A947C TObjectGI_OnDeactivate }
procedure TObjectGI.OnDeactivate;
var Child: TObjectGI;
begin
  if Assigned(DeactivateCallback) then DeactivateCallback(Self);
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.OnDeactivate;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A947C }

{ @routine $4A94B4 TObjectGI_NativeHook50 }
procedure TObjectGI.NativeHook50;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active = True then Child.NativeHook50;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A94B4 }

{ @routine $4A94D4 TObjectGI_ProcessLeftButtonDown }
procedure TObjectGI.ProcessLeftButtonDown(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(LeftButtonDownCallback) then LeftButtonDownCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then Child.ProcessLeftButtonDown(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A94D4 }

{ @routine $4A9534 TObjectGI_ProcessLeftButtonUp }
procedure TObjectGI.ProcessLeftButtonUp(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(LeftButtonUpCallback) then LeftButtonUpCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then Child.ProcessLeftButtonUp(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9534 }

{ @routine $4A9594 TObjectGI_ProcessRightButtonDown }
procedure TObjectGI.ProcessRightButtonDown(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(RightButtonDownCallback) then RightButtonDownCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then Child.ProcessRightButtonDown(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9594 }

{ @routine $4A95F4 TObjectGI_ProcessRightButtonUp }
procedure TObjectGI.ProcessRightButtonUp(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(RightButtonUpCallback) then RightButtonUpCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then Child.ProcessRightButtonUp(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A95F4 }

{ @routine $4A9654 TObjectGI_ProcessLeftButtonDoubleClick }
procedure TObjectGI.ProcessLeftButtonDoubleClick(KeyState: Cardinal; Point: TPoint);
var Child: TObjectGI;
begin
  if Assigned(LeftButtonDoubleClickCallback) then LeftButtonDoubleClickCallback(Self, KeyState, Point);
  Child := FirstChild;
  while Child <> nil do
  begin
    if (Child.Active = True) and Child.ContainsPoint(Point) then Child.ProcessLeftButtonDoubleClick(KeyState, Point);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9654 }

{ @routine $4A96B4 TObjectGI_BroadcastKeyDown }
procedure TObjectGI.BroadcastKeyDown(Key: Cardinal);
var Child: TObjectGI;
begin
  if Assigned(KeyDownCallback) then KeyDownCallback(Self, Key);
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.BroadcastKeyDown(Key);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A96B4 }

{ @routine $4A96F0 TObjectGI_BroadcastKeyUp }
procedure TObjectGI.BroadcastKeyUp(Key: Cardinal);
var Child: TObjectGI;
begin
  if Assigned(KeyUpCallback) then KeyUpCallback(Self, Key);
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.BroadcastKeyUp(Key);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A96F0 }

{ @routine $4A972C TObjectGI_OnFocusGained }
procedure TObjectGI.OnFocusGained;
begin
end;
{ @end $4A972C }

{ @routine $4A9730 TObjectGI_OnFocusLost }
procedure TObjectGI.OnFocusLost;
begin
end;
{ @end $4A9730 }

{ @routine $4A9734 TObjectGI_ProcessKeyDown }
procedure TObjectGI.ProcessKeyDown(Key: Integer);
begin
end;
{ @end $4A9734 }

{ @routine $4A9738 TObjectGI_ProcessCharacter }
procedure TObjectGI.ProcessCharacter(Character: WideChar);
begin
end;
{ @end $4A9738 }

{ @routine $4A973C TObjectGI_OnCaretBlink }
procedure TObjectGI.OnCaretBlink;
begin
end;
{ @end $4A973C }

{ @routine $4A9740 TObjectGI_ContainsPoint }
function TObjectGI.ContainsPoint(Point: TPoint): Boolean;
begin
  if not Active then
  begin
    Result := False;
    Exit;
  end;
  if (Point.X >= HitTestBounds.Left) and (Point.Y >= HitTestBounds.Top) and
    (Point.X < HitTestBounds.Right) and (Point.Y < HitTestBounds.Bottom) then Result := True
  else Result := False;
end;
{ @end $4A9740 }

{ @routine $4A9780 TObjectGI_HitTestCursor }
function TObjectGI.HitTestCursor: Boolean;
begin
  Result := ContainsPoint(MessageLoop.GetCursorPoint);
end;
{ @end $4A9780 }

{ @routine $4A97A0 TObjectGI_FindByNameRecursive }
function TObjectGI.FindByNameRecursive(const Name: WideString): TObjectGI;
var Child, Found: TObjectGI;
begin
  if ControlName = Name then
  begin
    Result := Self;
    Exit;
  end;
  Child := FirstChild;
  while Child <> nil do
  begin
    Found := Child.FindByNameRecursive(Name);
    if Found <> nil then
    begin
      Result := Found;
      Exit;
    end;
    Child := Child.NextSibling;
  end;
  Result := nil;
end;
{ @end $4A97A0 }

{ @routine $4A97D8 TObjectGI_ToLocalPoint }
function TObjectGI.ToLocalPoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X - AbsolutePosition.X;
  Result.Y := Point.Y - AbsolutePosition.Y;
end;
{ @end $4A97D8 }

{ @routine $4A97FC TObjectGI_ToAbsolutePoint }
function TObjectGI.ToAbsolutePoint(Point: TPoint): TPoint;
begin
  Result.X := Point.X + AbsolutePosition.X;
  Result.Y := Point.Y + AbsolutePosition.Y;
end;
{ @end $4A97FC }

{ @routine $4A9820 TObjectGI_DispatchNamedEvent }
procedure TObjectGI.DispatchNamedEvent(EventKind, Param1, Param2: Integer);
begin
  if Length(ControlName) > 0 then MessageLoop.ProcessNamedControlEvent(ControlName, EventKind, Param1, Param2);
end;
{ @end $4A9820 }

{ @routine $4A9854 TObjectGI_InvalidateRect }
procedure TObjectGI.InvalidateRect(Rect: TRect);
var Intersection, First, Second: TRect;
begin
  if Active <> True then Exit;
  if Parent = nil then MessageLoop.QueueUpdateRect(Rect)
  else
  begin
    First := Parent.OffsetChildRect(Rect, PositionModeW);
    Second := Parent.OffsetChildRect(GetLocalBounds, PositionModeW);
    if IntersectRects(Intersection, First, Second) then Parent.InvalidateRect(Intersection);
  end;
end;
{ @end $4A9854 }

{ @routine $4A98DC TObjectGI_Invalidate }
procedure TObjectGI.Invalidate;
begin
  if MessageLoop.UpdateRectsEnabled and (Parent <> nil) and (Active = True) then
    InvalidateRect(GetLocalBounds);
end;
{ @end $4A98DC }

{ @routine $4A9914 TObjectGI_InvalidateChildren }
procedure TObjectGI.InvalidateChildren(IncludePanels: Boolean);
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then
    begin
      if not IncludePanels and (Child is TPanelGI) then Child.InvalidateChildren(IncludePanels)
      else Child.Invalidate;
    end;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9914 }

{ @routine $4A995C TObjectGI_InvalidateScrollOverlap }
function TObjectGI.InvalidateScrollOverlap(Rect: TRect; Delta: TPoint; StartControl: TObjectGI): TObjectGI;
var Child: TObjectGI;
begin
  Result := StartControl;
  if Self = Result then Result := nil;
  if (Self is TPanelGI) and not ScrollUpdate then
  begin
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.Active then Result := Child.InvalidateScrollOverlap(Rect, Delta, Result);
      Child := Child.NextSibling;
    end;
  end
  else if (Result = nil) and (not PositionModeW or ScrollUpdate) then
  begin
    SetPosition(Classes.Point(LocalPosition.X + Delta.X, LocalPosition.Y + Delta.Y));
    SetPosition(Classes.Point(LocalPosition.X - Delta.X, LocalPosition.Y - Delta.Y));
  end;
end;
{ @end $4A995C }

{ @routine $4A9A1C TObjectGI_Draw }
procedure TObjectGI.Draw(ClipRect: TRect);
var Child: TObjectGI; Intersection: TRect;
begin
  if MessageLoop.PendingRedraw then Exit;
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active and IntersectRects(Intersection, ClipRect, Child.HitTestBounds) then
      Child.Draw(Intersection);
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9A1C }

{ @routine $4A9A74 TObjectGI_DrawUpdateRects }
procedure TObjectGI.DrawUpdateRects(ClipRect: TRect);
var Child: TObjectGI;
    RectNode: TRectGR;
    DrawRect, Intersection: TRect;
begin
  if IntersectRects(Intersection, ClipRect, HitTestBounds) then
  begin
    Child := FirstChild;
    while Child <> nil do
    begin
      if Child.Active then Child.DrawUpdateRects(Intersection);
      Child := Child.NextSibling;
    end;
    if SkipOwnQueuedDraw = 0 then
    begin
      RectNode := MessageLoop.UpdateRects.FirstRect;
      while RectNode <> nil do
      begin
        if IntersectRects(DrawRect, RectNode.Bounds, Intersection) then Draw(DrawRect);
        RectNode := RectNode.Next;
      end;
    end;
  end;
end;
{ @end $4A9A74 }

{ @routine $4A9AFC TObjectGI_CommitFrameDraw }
procedure TObjectGI.CommitFrameDraw;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then Child.CommitFrameDraw;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9AFC }

{ @routine $4A9B20 TObjectGI_ErasePreviousFrame }
procedure TObjectGI.ErasePreviousFrame;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then Child.ErasePreviousFrame;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9B20 }

{ @routine $4A9B44 TObjectGI_NativeHookB0 }
procedure TObjectGI.NativeHookB0;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then Child.NativeHookB0;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9B44 }

{ @routine $4A9B68 TObjectGI_PrepareFrameDraw }
procedure TObjectGI.PrepareFrameDraw;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    if Child.Active then Child.PrepareFrameDraw;
    Child := Child.NextSibling;
  end;
end;
{ @end $4A9B68 }

{ @routine $4A9B8C TObjectGI_PrepareRegionDraw }
procedure TObjectGI.PrepareRegionDraw(ClipRect: TRect);
begin
end;
{ @end $4A9B8C }

{ @routine $4A9B90 TObjectGI_NativeHookBC }
procedure TObjectGI.NativeHookBC(Rect: TRect);
begin
end;
{ @end $4A9B90 }

{ @routine $4A9B94 TObjectGI_LoadFromConfigPath }
procedure TObjectGI.LoadFromConfigPath(const Path: WideString);
var Block: TBlockParEC; Text: WideString; Count: Integer;
begin
  Block := UiStyleConfig.GetBlockByPath(Path);
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    Count := CountDelimitedPartsW(Text, ',');
    if Count >= 2 then
    begin
      LocalPosition.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
      LocalPosition.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    end;
    if Count >= 3 then SetDepthByName(ExtractDelimitedPartW(Text, 2, ','));
    if Count >= 4 then
      if TrimWideString(ExtractDelimitedPartW(Text, 3, ',')) = 'w' then PositionModeW := True;
  end;
  if Block.CountParams('PosZ') > 0 then SetDepthByName(Block.GetParam('PosZ'));
  if Block.CountParams('Size') > 0 then
  begin
    Text := Block.GetParam('Size');
    ClientSize.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    ClientSize.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('Sme') > 0 then
  begin
    Text := Block.GetParam('Sme');
    OriginPoint.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
    OriginPoint.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  end;
  if Block.CountParams('Name') > 0 then ControlName := TrimWideString(Block.GetParam('Name'));
  if Block.CountParams('Help') > 0 then HelpText := LookupLocalizedTextByKey(TrimWideString(Block.GetParam('Help')));
  if Block.CountParams('Active') > 0 then
    if TrimWideString(Block.GetParam('Active')) = 'False' then Active := False;
  if Block.CountParams('MouseBlocking') > 0 then MouseBlocking := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlocking')));
  if Block.CountParams('MouseBlockingTest') > 0 then MouseBlockingTest := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlockingTest')));
  if Block.CountParams('MVUpdate') > 0 then SetMouseViewUpdates(ParseEnabledNameGI(TrimWideString(Block.GetParam('MVUpdate'))));
end;
{ @end $4A9B94 }

{ @routine $4AA0A0 TObjectGI_LoadFromBlock }
procedure TObjectGI.LoadFromBlock(Block: TBlockParEC);
var Count, Index: Integer;
    Child: TObjectGI;
    Text: WideString;
begin
  Clear;
  Count := Block.GetBlockCount;
  for Index := 0 to Count - 1 do
  begin
    Child := CreateControlByName(Block.GetBlockNameByIndex(Index), Self);
    if Child <> nil then Child.LoadFromBlock(Block.GetBlockByIndex(Index));
  end;
  Depth := -1;
  SetDepth(0);
  if Block.CountParams('Style') > 0 then SetConfigPath(Block.GetParam('Style'));
  if Block.CountParams('Pos') > 0 then
  begin
    Text := Block.GetParam('Pos');
    Count := CountDelimitedPartsW(Text, ',');
    if Count >= 2 then
    begin
      LocalPosition.X := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
      LocalPosition.Y := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
    end;
    if Count >= 3 then SetDepthByName(ExtractDelimitedPartW(Text, 2, ','));
    if Count >= 4 then
      if TrimWideString(ExtractDelimitedPartW(Text, 3, ',')) = 'w' then PositionModeW := True;
  end;
  if Block.CountParams('PosZ') > 0 then SetDepthByName(Block.GetParam('PosZ'));
  if Block.CountParams('Size') > 0 then SetSize(GetPointGI(Block.GetParam('Size')));
  if Block.CountParams('Sme') > 0 then SetOrigin(GetPointGI(Block.GetParam('Sme')));
  ControlName := '';
  if Block.CountParams('Name') > 0 then ControlName := TrimWideString(Block.GetParam('Name'));
  if Block.CountParams('Help') > 0 then HelpText := LookupLocalizedTextByKey(TrimWideString(Block.GetParam('Help')));
  Active := True;
  if Block.CountParams('Active') > 0 then
    if TrimWideString(Block.GetParam('Active')) = 'False' then Active := False;
  if Block.CountParams('MouseBlocking') > 0 then MouseBlocking := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlocking')));
  if Block.CountParams('MouseBlockingTest') > 0 then MouseBlockingTest := ParseEnabledNameGI(TrimWideString(Block.GetParam('MouseBlockingTest')));
  if Block.CountParams('ScrollUpdate') > 0 then ScrollUpdate := ParseEnabledNameGI(TrimWideString(Block.GetParam('ScrollUpdate')));
  if Block.CountParams('MVUpdate') > 0 then SetMouseViewUpdates(ParseEnabledNameGI(TrimWideString(Block.GetParam('MVUpdate'))));
end;
{ @end $4AA0A0 }

{ @routine $4AA608 TObjectGI_UpdateAutoGeometry }
procedure TObjectGI.UpdateAutoGeometry;
var Child: TObjectGI;
begin
  Child := FirstChild;
  while Child <> nil do
  begin
    Child.UpdateAutoGeometry;
    Child := Child.NextSibling;
  end;
end;
{ @end $4AA608 }

{ @routine $4AA624 TFormSoundGroup_Create }
constructor TFormSoundGroup.Create;
begin
  inherited Create;
  Sounds := TStringsEC.Create;
end;
{ @end $4AA624 }

{ @routine $4AA668 TFormSoundGroup_Destroy }
destructor TFormSoundGroup.Destroy;
begin
  Clear;
  Sounds.Free;
  Sounds := nil;
  inherited Destroy;
end;
{ @end $4AA668 }

{ @routine $4AA6A4 TFormSoundGroup_Clear }
procedure TFormSoundGroup.Clear;
begin
  Sounds.Clear;
  Section := 0;
end;
{ @end $4AA6A4 }

{ @routine $4AA6B8 TFormSoundGroup_LoadFromBlock }
procedure TFormSoundGroup.LoadFromBlock(Block: TBlockParEC);
var
  Text: WideString;
  Index, Count: Integer;
begin
  Clear;
  TotalWeight := 0;
  Text := Block.GetParam('NextTime');
  MinDelayMs := StrToInt(ExtractDelimitedPartW(Text, 0, ',-'));
  MaxDelayMs := StrToInt(ExtractDelimitedPartW(Text, 1, ',-'));
  if Block.CountParams('Section') > 0 then
    Section := StrToInt(Block.GetParam('Section'));
  Count := Block.GetParamCount;
  for Index := 0 to Count - 1 do
  begin
    Text := Block.GetParamName(Index);
    if not IsIntegerTextW(Text) then Continue;
    Sounds.Add(Block.GetParamValue(Index));
    Sounds.SetDataAt(Sounds.GetCount - 1, Pointer(ExtractDigitsToIntW(Text)));
    TotalWeight := TotalWeight + ExtractDigitsToIntW(Text);
  end;
end;
{ @end $4AA6B8 }

{ @routine $4AA884 TFormSoundGroup_ScheduleNextPlayback }
procedure TFormSoundGroup.ScheduleNextPlayback;
begin
  NextPlayTick := Cardinal(RandomIntRange(MinDelayMs, MaxDelayMs)) + timeGetTime;
end;
{ @end $4AA884 }

{ @routine $4AA8A4 TFormSoundGroup_PlayIfDue }
procedure TFormSoundGroup.PlayIfDue;
var Weight: Integer;
begin
  if timeGetTime > NextPlayTick then
  begin
    ScheduleNextPlayback;
    Weight := RandomIntRange(0, TotalWeight - 1);
    Sounds.First;
    while not Sounds.IsAtEnd do
    begin
      Weight := Weight - Integer(Sounds.GetCurrentData);
      if Weight < 0 then Break;
      Sounds.Next;
    end;
    SoundManager.PlaySound(Sounds.GetCurrentText);
  end;
end;
{ @end $4AA8A4 }

{ @routine $4AA944 TMessageLoopGI_Create }
constructor TMessageLoopGI.Create;
begin
  inherited Create;
  UpdateRects := TArrayRectGR.Create;
  MouseViewUpdateControls := TList.Create;
  UpdateRectsEnabled := True;
  SoundGroupList := TList.Create;
  PlayTransitionSounds := True;
end;
{ @end $4AA944 }

{ @routine $4AA9B4 TMessageLoopGI_Destroy }
destructor TMessageLoopGI.Destroy;
begin
  ResetRuntime;
  UpdateRects.Free;
  MouseViewUpdateControls.Free;
  SoundGroupList.Free;
  SoundGroupList := nil;
  inherited Destroy;
end;
{ @end $4AA9B4 }

{ @routine $4AAA04 TMessageLoopGI_ResetRuntime }
procedure TMessageLoopGI.ResetRuntime;
var Index: Integer; Item: TObject;
begin
  FreeSecondaryPixelBuffer;
  FreeSavedLines;
  if SoundGroupList <> nil then
  begin
    for Index := 0 to SoundGroupList.Count - 1 do
    begin
      Item := SoundGroupList[Index];
      Item.Free;
    end;
    SoundGroupList.Clear;
  end;
  if RootUiObject <> nil then
  begin
    RootUiObject.Free;
    RootUiObject := nil;
  end;
  CursorControl := nil;
  FocusedControl := nil;
  while FirstTimer <> nil do CancelCallbackTimer(Cardinal(LastTimer));
end;
{ @end $4AAA04 }

{ @routine $4AAA80 TMessageLoopGI_ClearUpdateRects }
procedure TMessageLoopGI.ClearUpdateRects;
begin
  UpdateRects.Clear;
end;
{ @end $4AAA80 }

{ @routine $4AAA8C TMessageLoopGI_QueueUpdateRect }
procedure TMessageLoopGI.QueueUpdateRect(Rect: TRect);
var Intersection: TRect;
begin
  if UpdateRectsEnabled then
    if IntersectRects(Intersection, Rect, GameScreenRect) then UpdateRects.AddRect(Intersection);
end;
{ @end $4AAA8C }

{ @routine $4AAACC TMessageLoopGI_InvalidateViewport }
procedure TMessageLoopGI.InvalidateViewport;
begin
  QueueUpdateRect(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $4AAACC }

{ @routine $4AAB00 TMessageLoopGI_FindMouseViewUpdateControl }
function TMessageLoopGI.FindMouseViewUpdateControl(Control: TObjectGI): Integer;
var Index, Count: Integer;
begin
  Count := MouseViewUpdateControls.Count;
  for Index := 0 to Count - 1 do
    if MouseViewUpdateControls[Index] = Control then
    begin
      Result := Index;
      Exit;
    end;
  Result := -1;
end;
{ @end $4AAB00 }

{ @routine $4AAB38 TMessageLoopGI_AddMouseViewUpdateControl }
procedure TMessageLoopGI.AddMouseViewUpdateControl(Control: TObjectGI);
begin
  if FindMouseViewUpdateControl(Control) < 0 then MouseViewUpdateControls.Add(Control);
end;
{ @end $4AAB38 }

{ @routine $4AAB58 TMessageLoopGI_RemoveMouseViewUpdateControl }
procedure TMessageLoopGI.RemoveMouseViewUpdateControl(Control: TObjectGI);
var Index: Integer;
begin
  Index := FindMouseViewUpdateControl(Control);
  if Index >= 0 then MouseViewUpdateControls.Delete(Index);
end;
{ @end $4AAB58 }

{ @routine $4AAB74 TMessageLoopGI_InvalidateMouseViewControls }
procedure TMessageLoopGI.InvalidateMouseViewControls;
var Count, Index: Integer; Control: TObjectGI;
begin
  Count := MouseViewUpdateControls.Count;
  for Index := 0 to Count - 1 do
  begin
    Control := MouseViewUpdateControls[Index];
    Control.Invalidate;
  end;
end;
{ @end $4AAB74 }

{ @routine $4AABA4 TMessageLoopGI_DrawQueuedUpdateRects }
procedure TMessageLoopGI.DrawQueuedUpdateRects;
var RectNode: TRectGR;
begin
  if RegionDrawPending and (RegionDrawControl <> nil) then
    RegionDrawControl.PrepareRegionDraw(RegionDrawControl.HitTestBounds);
  PendingRedraw := False;
  RectNode := UpdateRects.FirstRect;
  while RectNode <> nil do
  begin
    RootUiObject.Draw(RectNode.Bounds);
    RectNode := RectNode.Next;
  end;
end;
{ @end $4AABA4 }

{ @routine $4AABEC TMessageLoopGI_DrawQueuedControlRects }
procedure TMessageLoopGI.DrawQueuedControlRects;
begin
  if UpdateRects.FirstRect <> nil then
  begin
    PendingRedraw := True;
    RootUiObject.DrawUpdateRects(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
  end;
end;
{ @end $4AABEC }

{ @routine $4AAC34 TMessageLoopGI_FinishQueuedDraw }
procedure TMessageLoopGI.FinishQueuedDraw;
var RectNode: TRectGR;
begin
  if (PresentationOverrideBuffer = nil) and (VideoOverlaySurface = nil) then
  begin
    if RegionDrawPending and (RegionDrawControl <> nil) then RegionDrawControl.NativeHookBC(RegionDrawControl.HitTestBounds);
    RectNode := UpdateRects.FirstRect;
    while RectNode <> nil do
    begin
      PresentScreenRect(RectNode.Bounds);
      RectNode := RectNode.Next;
    end;
    ClearUpdateRects;
    RegionDrawPending := False;
  end;
end;
{ @end $4AAC34 }

{ @routine $4AAC90 TMessageLoopGI_CommitFrameDraw }
procedure TMessageLoopGI.CommitFrameDraw;
begin
  RootUiObject.CommitFrameDraw;
end;
{ @end $4AAC90 }

{ @routine $4AAC9C TMessageLoopGI_ErasePreviousFrame }
procedure TMessageLoopGI.ErasePreviousFrame;
begin
  RootUiObject.ErasePreviousFrame;
end;
{ @end $4AAC9C }

{ @routine $4AACA8 TMessageLoopGI_PrepareFrameDraw }
procedure TMessageLoopGI.PrepareFrameDraw;
begin
  RootUiObject.PrepareFrameDraw;
end;
{ @end $4AACA8 }

{ @routine $4AACB4 TMessageLoopGI_Run }
function TMessageLoopGI.Run: Integer;
var
  LastCaretTick: Cardinal;
  Point: TPoint;
  FirstIteration: Boolean;
  Index: Integer;
  Tick, RecordingTime: Cardinal;
  Background: TGraphBufGI;
begin
  ExitCode := 0;
  ContinuousLoop := False;
  FreeSecondaryPixelBuffer;
  FreeSavedLines;
  FreeSavedPixels16;
  SetCursorByName('Main');
  GetCursorPos(Point);
  if WindowedRendering then ScreenToClient(MainWindowHandle, Point);
  CursorControl.SetPosition(Point);
  SetCursorActive(True);
  TimerTick := timeGetTime;
  OnOpen;
  RootUiObject.UpdateAbsolutePosition;
  RootUiObject.UpdateSubtreeHitBounds;
  QueueUpdateRect(ViewportRect);
  LastCaretTick := 0;
  CaretBlinkOn := False;
  with RootUiObject do OnActivate;
  if (ViewportRect.Right - ViewportRect.Left < GameScreenWidth) or
     (ViewportRect.Bottom - ViewportRect.Top < GameScreenHeight) then
  begin
    Background := TGraphBufGI.Create(BackgroundPanel);
    Background.SetDepth(1.0E30);
    Background.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
    Background.AllocateBuffer(GameScreenWidth, GameScreenHeight);
    Background.CopyScreenRectToBuffer(
      Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight),
      Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
  end;
  FirstIteration := True;
  for Index := 0 to SoundGroupList.Count - 1 do
    TFormSoundGroup(SoundGroupList[Index]).ScheduleNextPlayback;
  if PlayTransitionSounds and (OpenSoundName <> '') then
    SoundManager.PlaySound(OpenSoundName);
  while (WinMessage(ProcessWindowMessage) <> 0) and (ExitCode = 0) do
  begin
    Tick := timeGetTime;
    if Tick - LastCaretTick > 200 then
    begin
      LastCaretTick := Tick;
      if CaretBlinkOn = True then CaretBlinkOn := False else CaretBlinkOn := True;
      if FocusedControl <> nil then FocusedControl.OnCaretBlink;
    end;
    if VideoOverlaySurface = nil then
    begin
      if PresentationOverrideBuffer <> nil then DrawPresentationOverride
      else if UpdateRects.FirstRect <> nil then
      begin
        DrawQueuedUpdateRects;
        if not BeginFramePresentation then
        begin
          RequestedScreenId := screenNone;
          RestartScreenId := FormToId(Self);
          Break;
        end;
        FinishQueuedDraw;
        EndFramePresentation;
      end;
    end;
    if RecordingFrames then
    begin
      RecordingTime := timeGetTime;
      CaptureRecordingFrame;
      RecordingTime := timeGetTime - RecordingTime;
      Inc(TimerTick, RecordingTime);
      NextTimerToProcess := FirstTimer;
      while NextTimerToProcess <> nil do
      begin
        Inc(NextTimerToProcess.DueTick, RecordingTime);
        NextTimerToProcess := NextTimerToProcess.Next;
      end;
    end;
    if MusicEnabled and not MusicManager.HasSelectedMusic then
    begin
      MusicManager.HasSelectedMusic;
      SelectMusic;
    end;
    ProcessCallbackTimers;
    for Index := 0 to SoundGroupList.Count - 1 do
      if (TFormSoundGroup(SoundGroupList[Index]).Section = 0) or
         (TFormSoundGroup(SoundGroupList[Index]).Section = SoundSection) then
        TFormSoundGroup(SoundGroupList[Index]).PlayIfDue;
    if FirstIteration and DemoRecording and (ClassName <> 'TfLoad') then
    begin
      Demo.AddFormStart(ClassName);
      DemoLastEventTick := timeGetTime;
    end;
    if DemoPlaying and FirstIteration then
    begin
      DemoLastEventTick := timeGetTime;
      ReplayFormTransition;
    end;
    FirstIteration := False;
  end;
  RootUiObject.OnDeactivate;
  SetCursorActive(False);
  if PlayTransitionSounds and (CloseSoundName <> '') then
    SoundManager.PlaySound(CloseSoundName);
  ClearTransientControl;
  OnClose;
  FreeSavedPixels16;
  FreeSecondaryPixelBuffer;
  FreeSavedLines;
  Result := ExitCode;
end;
{ @end $4AACB4 }

{ @routine $4AB140 TMessageLoopGI_ProcessUiIteration }
function TMessageLoopGI.ProcessUiIteration: Boolean;
var RecordingTime: Cardinal; Index: Integer;
begin
  if (WinMessage(ProcessWindowMessage) = 0) or (ExitCode <> 0) then
  begin
    Result := True;
    Exit;
  end;
  if UpdateRects.FirstRect <> nil then
  begin
    DrawQueuedUpdateRects;
    if not BeginFramePresentation then
    begin
      Result := True;
      Exit;
    end;
    FinishQueuedDraw;
    EndFramePresentation;
  end;
  if RecordingFrames then
  begin
    RecordingTime := timeGetTime;
    CaptureRecordingFrame;
    RecordingTime := timeGetTime - RecordingTime;
    Inc(TimerTick, RecordingTime);
    NextTimerToProcess := FirstTimer;
    while NextTimerToProcess <> nil do
    begin
      Inc(NextTimerToProcess.DueTick, RecordingTime);
      NextTimerToProcess := NextTimerToProcess.Next;
    end;
  end;
  if MusicEnabled and not MusicManager.HasSelectedMusic then
  begin
    MusicManager.HasSelectedMusic;
    SelectMusic;
  end;
  ProcessCallbackTimers;
  for Index := 0 to SoundGroupList.Count - 1 do
    if (TFormSoundGroup(SoundGroupList[Index]).Section = 0) or
       (TFormSoundGroup(SoundGroupList[Index]).Section = SoundSection) then
      TFormSoundGroup(SoundGroupList[Index]).PlayIfDue;
  Result := False;
end;
{ @end $4AB140 }

{ @routine $4AB258 TMessageLoopGI_RunContinuous }
function TMessageLoopGI.RunContinuous: Integer;
var
  Point: TPoint;
  ProcessingTime, CarryTicks, LastFpsTick: Cardinal;
  FrameCount: Integer;
  FirstIteration: Boolean;
  FrameTime, RecordingTime: Cardinal;
  Index: Integer;
begin
  ExitCode := 0;
  ContinuousLoop := True;
  FreeSecondaryPixelBuffer;
  FreeSavedPixels16;
  FreeSavedLines;
  SetCursorByName('Main');
  GetCursorPos(Point);
  if WindowedRendering then ScreenToClient(MainWindowHandle, Point);
  CursorControl.SetPosition(Point);
  SetCursorActive(True);
  TimerTick := 0;
  OnOpen;
  RootUiObject.UpdateAbsolutePosition;
  RootUiObject.UpdateSubtreeHitBounds;
  QueueUpdateRect(ViewportRect);
  CaretBlinkOn := False;
  RootUiObject.OnActivate;
  DrawFrame;
  LastFpsTick := timeGetTime;
  FrameCount := 0;
  CarryTicks := 0;
  FirstIteration := True;
  for Index := 0 to SoundGroupList.Count - 1 do
    TFormSoundGroup(SoundGroupList[Index]).ScheduleNextPlayback;
  if PlayTransitionSounds and (OpenSoundName <> '') then
    SoundManager.PlaySound(OpenSoundName);
  while (WinMessage(ProcessWindowMessage) <> 0) and (ExitCode = 0) do
  begin
    FrameTime := timeGetTime;
    DrawFrame;
    SysUtils.Sleep(1);
    FrameTime := timeGetTime - FrameTime;
    if FrameTime > 200 then FrameTime := 200;
    if RecordingFrames then
    begin
      RecordingTime := timeGetTime;
      CaptureRecordingFrame;
      RecordingTime := timeGetTime - RecordingTime;
      Inc(LastFpsTick, RecordingTime);
    end;
    ProcessingTime := timeGetTime;
    Inc(FrameCount);
    if timeGetTime - LastFpsTick > 1000 then
    begin
      FramesPerSecond := FrameCount;
      LastFpsTick := timeGetTime;
      FrameCount := 0;
      if ShowFPS then
        (GetByName('FPS') as TLabelGI).SetText('FPS: ' + IntToStr(FramesPerSecond));
    end;
    for Index := 0 to Integer(CarryTicks + FrameTime) - 1 do AdvanceTimerTick;
    for Index := 0 to SoundGroupList.Count - 1 do
      if (TFormSoundGroup(SoundGroupList[Index]).Section = 0) or
         (TFormSoundGroup(SoundGroupList[Index]).Section = SoundSection) then
        TFormSoundGroup(SoundGroupList[Index]).PlayIfDue;
    if MusicEnabled and not MusicManager.HasSelectedMusic then
    begin
      MusicManager.HasSelectedMusic;
      SelectMusic;
    end;
    ProcessingTime := timeGetTime - ProcessingTime;
    CarryTicks := ProcessingTime;
    if CarryTicks > 200 then CarryTicks := 0;
    if FirstIteration and DemoRecording and (ClassName <> 'TfLoad') then
    begin
      Demo.AddFormStart(ClassName);
      DemoLastEventTick := timeGetTime;
    end;
    if DemoPlaying and FirstIteration then
    begin
      DemoLastEventTick := timeGetTime;
      ReplayFormTransition;
    end;
    FirstIteration := False;
  end;
  RootUiObject.OnDeactivate;
  SetCursorActive(False);
  if PlayTransitionSounds and (CloseSoundName <> '') then
    SoundManager.PlaySound(CloseSoundName);
  ClearTransientControl;
  OnClose;
  FreeSavedPixels16;
  FreeSecondaryPixelBuffer;
  FreeSavedLines;
  Result := ExitCode;
end;
{ @end $4AB258 }

{ @routine $4AB69C TMessageLoopGI_AdvanceTimerTick }
procedure TMessageLoopGI.AdvanceTimerTick;
var Timer: PCallbackTimerGI; CallbackTimer: TCallbackTimerIdGI;
begin
  Inc(TimerTick);
  NextTimerToProcess := FirstTimer;
  while NextTimerToProcess <> nil do
  begin
    if NextTimerToProcess.DueTick > TimerTick then Break;
    Timer := NextTimerToProcess;
    NextTimerToProcess := NextTimerToProcess.Next;
    Timer.DueTick := TimerTick + Timer.RepeatMs;
    CallbackTimer := Cardinal(Timer);
    ReinsertCallbackTimer(CallbackTimer);
    Timer.Callback(CallbackTimer, Timer.UserData);
  end;
  NextTimerToProcess := nil;
end;
{ @end $4AB69C }

{ @routine $4AB6EC TMessageLoopGI_DrawFrame }
procedure TMessageLoopGI.DrawFrame;
begin
  if UpdateRects.FirstRect <> nil then
  begin
    DrawQueuedUpdateRects;
    FinishQueuedDraw;
  end;
end;
{ @end $4AB6EC }

{ @routine $4AB708 TMessageLoopGI_Present }
procedure TMessageLoopGI.Present;
begin
  if ContinuousLoop then
  begin
    FullFrameRedrawRequested := True;
    DrawFrame;
  end
  else
  begin
    DrawQueuedUpdateRects;
    FinishQueuedDraw;
  end;
end;
{ @end $4AB708 }

{ @routine $4AB738 TMessageLoopGI_ProcessWindowMessage }
procedure TMessageLoopGI.ProcessWindowMessage(Message, WParam: Cardinal; LParam: Integer);
var
  Point: TPoint;
  MoveStep: Integer;
  CharacterBuffer: array[0..4] of WideChar;
begin
  try
    if Message = WM_MOUSEMOVE then
    begin
      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if CursorControl.Active = True then (CursorControl as TCursorGI).SetPosition(Point);

      if FocusedControl <> nil then FocusedControl.ProcessMouseMove(WParam, Point);

      if RootUiObject.ContainsPoint(Point) then
      begin
        if not RootUiObject.MouseInside then
        begin

          RootUiObject.OnMouseEnter;
        end;
        RootUiObject.ProcessMouseMove(WParam, Point);
      end
      else if RootUiObject.MouseInside = True then
      begin

        RootUiObject.OnMouseLeave;
      end;
    end
    else if Message = WM_MOUSEWHEEL then
    begin

      ProcessMouseWheel(Word(WParam), Classes.Point(Word(LParam), HiWord(LParam)), SmallInt(HiWord(WParam)));
    end
    else if Message = WM_LBUTTONDOWN then
    begin

      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if RootUiObject.ContainsPoint(Point) then
      begin

        RootUiObject.ProcessLeftButtonDown(WParam, Point);
      end;
    end
    else if Message = WM_LBUTTONUP then
    begin

      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if FocusedControl <> nil then
      begin

        FocusedControl.ProcessLeftButtonUp(WParam, Point);
      end;
      if RootUiObject.ContainsPoint(Point) then
      begin

        RootUiObject.ProcessLeftButtonUp(WParam, Point);
      end;
    end
    else if Message = WM_RBUTTONDOWN then
    begin

      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if RootUiObject.ContainsPoint(Point) then
      begin

        RootUiObject.ProcessRightButtonDown(WParam, Point);
      end;
      if StatusLabel.Active then
      begin

        if (DebugControl = nil) or (DebugControl.Parent = ContentPanel) or not DebugControl.ContainsPoint(Point) then
          DebugControl := ContentPanel.FindDeepestChildAtPoint(Point)
        else DebugControl := DebugControl.Parent;

        (StatusLabel as TLabelGI).SetText(DebugControl.ControlName + ' (' + DebugControl.ClassName + ') Pos=' +
          IntToStr(DebugControl.LocalPosition.X) + ',' + IntToStr(DebugControl.LocalPosition.Y));
      end;
    end
    else if Message = WM_RBUTTONUP then
    begin

      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if RootUiObject.ContainsPoint(Point) then
      begin

        RootUiObject.ProcessRightButtonUp(WParam, Point);
      end;
    end
    else if Message = WM_LBUTTONDBLCLK then
    begin

      Point := Classes.Point(Word(LParam), HiWord(LParam));
      if RootUiObject.ContainsPoint(Point) then
      begin

        RootUiObject.ProcessLeftButtonDoubleClick(WParam, Point);
      end;
    end
    else if Message = WM_CHAR then
    begin

      if (WParam >= Ord(' ')) and (FocusedControl <> nil) and
        (MultiByteToWideChar(CP_ACP, 8 {MB_ERR_INVALID_CHARS}, PAnsiChar(@WParam), 1, CharacterBuffer, 4) <> 0) then
      begin

        FocusedControl.ProcessCharacter(CharacterBuffer[0]);
      end;
    end
    else if (Message = WM_KEYDOWN) or ((Message = WM_SYSKEYDOWN) and
      (WParam in [VK_MENU, VK_LEFT..VK_DOWN])) then
    begin

      RootUiObject.BroadcastKeyDown(WParam);
      if FocusedControl <> nil then
      begin

        FocusedControl.ProcessKeyDown(WParam);
      end;

      if IsVirtualKeyDown(VK_CONTROL) and IsVirtualKeyDown(VK_SHIFT) and not IsVirtualKeyDown(VK_MENU) and Assigned(DebugKeyCallback) then
        DebugKeyCallback(Word(WParam));

      if (WParam = Ord('M')) and IsVirtualKeyDown(VK_CONTROL) and IsVirtualKeyDown(VK_SHIFT) and IsVirtualKeyDown(VK_MENU) then
        StatusLabel.SetActive(not StatusLabel.Active);

      if StatusLabel.Active and (DebugControl <> nil) then
      begin

        if GetAsyncKeyState(VK_CONTROL) and $8000 = $8000 then MoveStep := 10 else MoveStep := 1;

        if WParam = VK_UP then DebugControl.SetPosition(Classes.Point(DebugControl.LocalPosition.X, DebugControl.LocalPosition.Y - MoveStep))
        else if WParam = VK_DOWN then DebugControl.SetPosition(Classes.Point(DebugControl.LocalPosition.X, DebugControl.LocalPosition.Y + MoveStep))
        else if WParam = VK_LEFT then DebugControl.SetPosition(Classes.Point(DebugControl.LocalPosition.X - MoveStep, DebugControl.LocalPosition.Y))
        else if WParam = VK_RIGHT then DebugControl.SetPosition(Classes.Point(DebugControl.LocalPosition.X + MoveStep, DebugControl.LocalPosition.Y));

        (StatusLabel as TLabelGI).SetText(DebugControl.ControlName + ' (' + DebugControl.ClassName + ') Pos=' +
          IntToStr(DebugControl.LocalPosition.X) + ',' + IntToStr(DebugControl.LocalPosition.Y));
      end
      else if StatusLabel.Active and (DebugControl = nil) then
      begin

        (StatusLabel as TLabelGI).SetText('Not object');
      end;
    end
    else if (Message = WM_KEYUP) or ((Message = WM_SYSKEYUP) and
      (WParam in [VK_MENU, VK_LEFT..VK_DOWN])) then
    begin

      RootUiObject.BroadcastKeyUp(WParam);
    end
    else if Message = WM_PAINT then
    begin

      InvalidateViewport;
    end;

  except
    on E: ExceptionBreakMessageGI do;
  end;
end;
{ @end $4AB738 }

{ @routine $4ABE74 TMessageLoopGI_ReplayFormTransition }
procedure TMessageLoopGI.ReplayFormTransition;
var
  Text: WideString;
  TimeDelta, KeyState: Cardinal;
  Position: TPoint;
  Kind: TDemoEventKind;
begin
  if (FormToId(Self) = screenGameLoad) or (FormToId(Self) = screenLoad) then Exit;
  while True do
  begin
    Kind := Demo.PeekKind;
    if Kind = dekFormStart then
    begin
      Demo.GetFormStart(Text);
      if Text <> ClassName then
        raise Exception.Create('TMessageLoopGI.DemoPlay mismatch forms <2> ' +
          Text + '<>' + ClassName);
      Break;
    end
    else if Kind = dekMouseMove then Demo.GetMouseMove(TimeDelta, Position, KeyState)
    else if Kind = dekMouseLDown then Demo.GetMouseLDown(TimeDelta, Position, KeyState)
    else if Kind = dekMouseLUp then Demo.GetMouseLUp(TimeDelta, Position, KeyState)
    else if Kind = dekMouseRDown then Demo.GetMouseRDown(TimeDelta, Position, KeyState)
    else if Kind = dekMouseRUp then Demo.GetMouseRUp(TimeDelta, Position, KeyState)
    else if Kind = dekSpacePos then Demo.GetSpacePos(TimeDelta, Position)
    else if Kind = dekState then Demo.GetState(TimeDelta, Text, Position)
    else if Kind = dekEnd then Break
    else raise Exception.Create('TMessageLoopGI.DemoPlay mismatch forms <1>');
  end;
end;
{ @end $4ABE74 }

{ @routine $4AC134 TMessageLoopGI_RequestClose }
procedure TMessageLoopGI.RequestClose(Code: Integer);
begin
  ExitCode := Code;
end;
{ @end $4AC134 }

{ @routine $4AC138 TMessageLoopGI_GetByName }
function TMessageLoopGI.GetByName(const Name: WideString): TObjectGI;
begin
  Result := ContentPanel.FindByNameRecursive(Name);
  if Result = nil then raise Exception.Create('TMessageLoopGI.GetByName. Name=' + Name);
end;
{ @end $4AC138 }

{ @routine $4AC200 TMessageLoopGI_FindControlByPath }
function TMessageLoopGI.FindControlByPath(const Path: WideString): TObjectGI;
begin
  Result := ContentPanel.FindByNameRecursive(Path);
end;
{ @end $4AC200 }

{ @routine $4AC20C TMessageLoopGI_SetFocusedControl }
procedure TMessageLoopGI.SetFocusedControl(Control: TObjectGI);
begin
  if FocusedControl = Control then Exit;
  if FocusedControl <> nil then FocusedControl.OnFocusLost;
  FocusedControl := Control;
  if FocusedControl <> nil then FocusedControl.OnFocusGained;
end;
{ @end $4AC20C }

{ @routine $4AC23C TMessageLoopGI_ProcessNamedControlEvent }
procedure TMessageLoopGI.ProcessNamedControlEvent(ControlName: WideString; EventKind, Param1, Param2: Integer);
begin
end;
{ @end $4AC23C }

{ @routine $4AC268 TMessageLoopGI_OnOpen }
procedure TMessageLoopGI.OnOpen;
begin
end;
{ @end $4AC268 }

{ @routine $4AC26C TMessageLoopGI_OnClose }
procedure TMessageLoopGI.OnClose;
begin
end;
{ @end $4AC26C }

{ @routine $4AC270 TMessageLoopGI_ProcessCallbackTimers }
procedure TMessageLoopGI.ProcessCallbackTimers;
var
  NowTick: Cardinal;
  Timer: PCallbackTimerGI;
  CallbackTimer: TCallbackTimerIdGI;
  WaitMs: Integer;
  Handle: THandle;
begin
  NowTick := timeGetTime;
  if FirstTimer <> nil then
  begin
    WaitMs := Integer(FirstTimer.DueTick - NowTick);
    if WaitMs > 0 then
    begin
      Handle := 0;
      MsgWaitForMultipleObjects(0, Handle, False, WaitMs, $1FF);
      NowTick := timeGetTime;
    end;
  end;
  NextTimerToProcess := FirstTimer;
  while NextTimerToProcess <> nil do
  begin
    if NextTimerToProcess.DueTick > NowTick then Break;
    Timer := NextTimerToProcess;
    NextTimerToProcess := NextTimerToProcess.Next;
    Timer.DueTick := NowTick + Timer.RepeatMs;
    CallbackTimer := Cardinal(Timer);
    ReinsertCallbackTimer(CallbackTimer);
    Timer.Callback(CallbackTimer, Timer.UserData);
  end;
  NextTimerToProcess := nil;
  TimerTick := NowTick;
end;
{ @end $4AC270 }

{ @routine $4AC304 TMessageLoopGI_SelectMusic }
procedure TMessageLoopGI.SelectMusic;
begin
end;
{ @end $4AC304 }

{ @routine $4AC308 TMessageLoopGI_ScheduleCallbackTimer }
function TMessageLoopGI.ScheduleCallbackTimer(DelayMs, RepeatMs: Cardinal; Callback: TCallbackTimerEventGI; UserData: Cardinal): TCallbackTimerIdGI;
var Timer: PCallbackTimerGI;
begin
  Timer := AllocEC(SizeOf(TCallbackTimerGI));
  if LastTimer <> nil then LastTimer.Next := Timer;
  Timer.Prev := LastTimer;
  Timer.Next := nil;
  LastTimer := Timer;
  if FirstTimer = nil then FirstTimer := Timer;
  Timer.DueTick := DelayMs + TimerTick;
  Timer.RepeatMs := RepeatMs;
  Timer.UserData := UserData;
  Timer.Callback := Callback;
  ReinsertCallbackTimer(Cardinal(Timer));
  Result := Cardinal(Timer);
end;
{ @end $4AC308 }

{ @routine $4AC378 TMessageLoopGI_CancelCallbackTimer }
procedure TMessageLoopGI.CancelCallbackTimer(Timer: TCallbackTimerIdGI);
var Current: PCallbackTimerGI;
begin
  Current := PCallbackTimerGI(Timer);
  if NextTimerToProcess = Current then NextTimerToProcess := NextTimerToProcess.Next;
  if Current.Prev <> nil then Current.Prev.Next := Current.Next;
  if Current.Next <> nil then Current.Next.Prev := Current.Prev;
  if LastTimer = Current then LastTimer := Current.Prev;
  if FirstTimer = Current then FirstTimer := Current.Next;
  FreeEC(Current);
end;
{ @end $4AC378 }

{ @routine $4AC3C0 TMessageLoopGI_UpdateCallbackTimer }
procedure TMessageLoopGI.UpdateCallbackTimer(Timer: TCallbackTimerIdGI; DelayMs, RepeatMs: Cardinal);
var Current: PCallbackTimerGI;
begin
  Current := PCallbackTimerGI(Timer);
  if (TimerTick + DelayMs = Current.DueTick) and (Current.RepeatMs = RepeatMs) then Exit;
  Current.DueTick := TimerTick + DelayMs;
  Current.RepeatMs := RepeatMs;
  ReinsertCallbackTimer(Cardinal(Current));
end;
{ @end $4AC3C0 }

{ @routine $4AC3E8 TMessageLoopGI_ReinsertCallbackTimer }
procedure TMessageLoopGI.ReinsertCallbackTimer(Timer: TCallbackTimerIdGI);
var Current, Before: PCallbackTimerGI;
begin
  Current := PCallbackTimerGI(Timer);
  if Current.Prev <> nil then Current.Prev.Next := Current.Next;
  if Current.Next <> nil then Current.Next.Prev := Current.Prev;
  if LastTimer = Current then LastTimer := Current.Prev;
  if FirstTimer = Current then FirstTimer := Current.Next;
  Before := FirstTimer;
  while Before <> nil do
  begin
    if Current.DueTick <= Before.DueTick then
    begin
      Current.Prev := Before.Prev;
      Current.Next := Before;
      if Before.Prev <> nil then Before.Prev.Next := Current;
      Before.Prev := Current;
      if FirstTimer = Before then FirstTimer := Current;
      Exit;
    end;
    Before := Before.Next;
  end;
  if LastTimer <> nil then LastTimer.Next := Current;
  Current.Prev := LastTimer;
  Current.Next := nil;
  LastTimer := Current;
  if FirstTimer = nil then FirstTimer := Current;
end;
{ @end $4AC3E8 }

{ @routine $4AC474 TMessageLoopGI_RefreshTimerTick }
procedure TMessageLoopGI.RefreshTimerTick;
begin
  TimerTick := timeGetTime;
end;
{ @end $4AC474 }

{ @routine $4AC484 TMessageLoopGI_SetCursorImage }
procedure TMessageLoopGI.SetCursorImage(const ImagePath: WideString; HotSpot: TPoint);
begin
    (CursorControl as TCursorGI).SetImagePath(ImagePath);
    CursorControl.SetOrigin(HotSpot);
    CursorImagePath := ImagePath;
end;
{ @end $4AC484 }

{ @routine $4AC4C4 TMessageLoopGI_SetCursorByName }
procedure TMessageLoopGI.SetCursorByName(const Name: WideString);
var Cursor: TCursorUnit;
begin
    Cursor := FindCursorByName(Name);
    SetCursorImage(Cursor.ImagePath, Cursor.HotSpot);
end;
{ @end $4AC4C4 }

{ @routine $4AC4E0 TMessageLoopGI_IsCursorImageSelected }
function TMessageLoopGI.IsCursorImageSelected(const RegisteredName: WideString): Boolean;
var Cursor: TCursorUnit;
begin
  Cursor := FindCursorByName(RegisteredName);
  Result := Cursor.ImagePath = CursorImagePath;
end;
{ @end $4AC4E0 }

{ @routine $4AC500 TMessageLoopGI_IsCursorActive }
function TMessageLoopGI.IsCursorActive: Boolean;
begin
  Result := CursorControl.Active;
end;
{ @end $4AC500 }

{ @routine $4AC508 TMessageLoopGI_SetCursorActive }
procedure TMessageLoopGI.SetCursorActive(Enabled: Boolean);
begin
  if CursorControl.Active <> Enabled then CursorControl.SetActive(Enabled);
end;
{ @end $4AC508 }

{ @routine $4AC51C TMessageLoopGI_CaptureCursorState }
procedure TMessageLoopGI.CaptureCursorState(State: PCursorStateGI);
begin
  State^.ImagePath := CursorImagePath;
  State^.Active := IsCursorActive;
  State^.HotSpot := CursorControl.OriginPoint;
  State^.Position := CursorControl.LocalPosition;
end;
{ @end $4AC51C }

{ @routine $4AC558 TMessageLoopGI_RestoreCursorState }
procedure TMessageLoopGI.RestoreCursorState(State: PCursorStateGI);
begin
    SetCursorImage(State^.ImagePath, State^.HotSpot);
    SetCursorActive(State^.Active);
    CursorControl.SetPosition(State^.Position);
end;
{ @end $4AC558 }

{ @routine $4AC584 TMessageLoopGI_UpdateCursorPosition }
procedure TMessageLoopGI.UpdateCursorPosition;
var Point: TPoint;
begin
  GetCursorPos(Point);
  if WindowedRendering then ScreenToClient(MainWindowHandle, Point);
  CursorControl.SetPosition(Point);
end;
{ @end $4AC584 }

{ @routine $4AC5B8 TMessageLoopGI_GetCursorPoint }
function TMessageLoopGI.GetCursorPoint: TPoint;
begin
  Result := CursorControl.LocalPosition;
end;
{ @end $4AC5B8 }

{ @routine $4AC5C8 TMessageLoopGI_SetSystemCursorPosition }
procedure TMessageLoopGI.SetSystemCursorPosition(Point: TPoint);
begin
  SetCursorPos(Point.X, Point.Y);
end;
{ @end $4AC5C8 }

{ @routine $4AC5E8 TMessageLoopGI_ConsumeTimerTickChange }
function TMessageLoopGI.ConsumeTimerTickChange: Boolean;
begin
  if LastObservedTimerTick = TimerTick then
  begin
    Result := False;
    Exit;
  end;
  LastObservedTimerTick := TimerTick;
  Result := True;
end;
{ @end $4AC5E8 }

{ @routine $4AC5FC TMessageLoopGI_QueryPointOcclusionState }
function TMessageLoopGI.QueryPointOcclusionState(Point: TPoint; IgnoreControl, StartControl: TObjectGI): Integer;
var Child: TObjectGI;
begin
  if StartControl = nil then StartControl := RootUiObject;
  if ((StartControl.Parent <> nil) and StartControl.ContainsPoint(Point)) or (StartControl.Parent = nil) then
  begin
    Child := StartControl.LastChild;
    while Child <> nil do
    begin
      Result := QueryPointOcclusionState(Point, IgnoreControl, Child);
      if Result <> 0 then Exit;
      Child := Child.PrevSibling;
    end;
    if StartControl.MouseBlocking and (StartControl <> IgnoreControl) then
    begin
      Result := 1;
      Exit;
    end;
  end;
  if StartControl = IgnoreControl then Result := -1
  else Result := 0;
end;
{ @end $4AC5FC }

{ @routine $4AC684 TMessageLoopGI_FreeSavedPixels16 }
procedure TMessageLoopGI.FreeSavedPixels16;
begin
  if SavedPixels16 <> nil then
  begin
    FreeEC(SavedPixels16);
    SavedPixels16 := nil;
  end;
  SavedPixelCount16 := 0;
  SavedPixelCapacity16 := 0;
end;
{ @end $4AC684 }

{ @routine $4AC6A4 TMessageLoopGI_SavePixel16 }
procedure TMessageLoopGI.SavePixel16(ByteOffset: Integer; Color: Word);
begin
  if SavedPixelCount16 = SavedPixelCapacity16 then begin
    Inc(SavedPixelCapacity16, 100);
    SavedPixels16 := ReAllocREC(SavedPixels16, SavedPixelCapacity16 * 8);
  end;
  WriteInt32EC(AddPointerOffset(SavedPixels16, SavedPixelCount16 * 8), ByteOffset);
  WriteWordEC(AddPointerOffset(SavedPixels16, SavedPixelCount16 * 8 + 4), Color);
  Inc(SavedPixelCount16);
end;
{ @end $4AC6A4 }

{ @routine $4AC710 TMessageLoopGI_RestoreSavedPixels16 }
procedure TMessageLoopGI.RestoreSavedPixels16;
var Entries, Pixels: Pointer; Count: Integer;
begin
  if SavedPixelCount16 < 1 then Exit;
  Pixels := ScreenRenderBuffer.Pixels;
  Count := SavedPixelCount16;
  Entries := SavedPixels16;
  // Native handwritten block: PUSHAD/POPAD and the compact eight-byte-entry loop.
  asm
    pushad
    mov edi, Entries
    mov esi, Pixels
    mov ecx, Count
  @@NextPixel:
    mov ebx, [edi]
    add edi, 4
    mov ax, [edi]
    add edi, 4
    mov [esi+ebx], ax
    dec ecx
    jnz @@NextPixel
    popad
  end;
  SavedPixelCount16 := 0;
end;
{ @end $4AC710 }

{ @routine $4AC760 TMessageLoopGI_FreeSecondaryPixelBuffer }
procedure TMessageLoopGI.FreeSecondaryPixelBuffer;
begin
  if SecondaryPixelBuffer <> nil then
  begin
    FreeEC(SecondaryPixelBuffer);
    SecondaryPixelBuffer := nil;
  end;
  SecondaryPixelCount := 0;
  SecondaryPixelCapacity := 0;
end;
{ @end $4AC760 }

{ @routine $4AC784 TMessageLoopGI_QueuePixelPresent }
procedure TMessageLoopGI.QueuePixelPresent(ByteOffset: Integer);
begin
  if SecondaryPixelCount = SecondaryPixelCapacity then begin
    Inc(SecondaryPixelCapacity, 100);
    SecondaryPixelBuffer := ReAllocREC(SecondaryPixelBuffer, SecondaryPixelCapacity * 4);
  end;
  WriteInt32EC(AddPointerOffset(SecondaryPixelBuffer, SecondaryPixelCount * 4), ByteOffset);
  Inc(SecondaryPixelCount);
end;
{ @end $4AC784 }

{ @routine $4AC7D4 TMessageLoopGI_ResetSecondaryPixelCount }
procedure TMessageLoopGI.ResetSecondaryPixelCount;
var SourcePixels, DestPixels: Pointer; Count: Integer; Entries: Pointer;
begin
  if SecondaryPixelCount < 1 then Exit;
  SourcePixels := ScreenRenderBuffer.Pixels;
  DestPixels := ScreenPresentBuffer.Pixels;
  Count := SecondaryPixelCount;
  Entries := SecondaryPixelBuffer;
  { Native handwritten word-copy loop, $4AC809..$4AC826. }
  asm
    pushad
    mov edi, SourcePixels
    mov esi, DestPixels
    mov ecx, Count
    mov ebx, Entries
  @@NextPixel:
    mov edx, [ebx]
    mov ax, [edi+edx]
    mov [esi+edx], ax
    add ebx, 4
    dec ecx
    jnz @@NextPixel
    popad
  end;
  SecondaryPixelCount := 0;
end;
{ @end $4AC7D4 }

{ @routine $4AC834 TMessageLoopGI_FreeSavedLines }
procedure TMessageLoopGI.FreeSavedLines;
var Index: Integer;
begin
  for Index := 0 to High(SavedLines) do
    FreeFromHeapEC(SavedLines[Index].Heap, SavedLines[Index].Pixels);
  SavedLines := nil;
  SavedLineCount := 0;
end;
{ @end $4AC834 }

{ @routine $4AC88C TMessageLoopGI_AddSavedLine }
procedure TMessageLoopGI.AddSavedLine(First, Last: TPoint; Pixels: Pointer);
begin
  if SavedLineCount = High(SavedLines) + 1 then SetLength(SavedLines, SavedLineCount + 100);
  SavedLines[SavedLineCount].First := First;
  SavedLines[SavedLineCount].Last := Last;
  SavedLines[SavedLineCount].Pixels := Pixels;
  SavedLines[SavedLineCount].Heap := GetProcessHeap;
  Inc(SavedLineCount);
end;
{ @end $4AC88C }

{ @routine $4AC954 TMessageLoopGI_RestoreSavedLines }
procedure TMessageLoopGI.RestoreSavedLines;
var
  Index: Integer;
begin
  if SkipSavedPixelRestore then Exit;
  for Index := 0 to SavedLineCount - 1 do
    OKGR_Line_CopyFromBuf_WORD(SavedLines[Index].Pixels,
      ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      SavedLines[Index].First.X, SavedLines[Index].First.Y,
      SavedLines[Index].Last.X, SavedLines[Index].Last.Y);
end;
{ @end $4AC954 }

{ @routine $4AC9D0 TMessageLoopGI_ResetSavedLineCount }
procedure TMessageLoopGI.ResetSavedLineCount;
var
  Index: Integer;
begin
  if SkipSavedPixelRestore then Exit;
  for Index := 0 to SavedLineCount - 1 do
    OKGR_Line_Copy_WORD(ScreenPresentBuffer.Pixels, ScreenPresentBuffer.PitchBytes,
      ScreenRenderBuffer.Pixels, ScreenRenderBuffer.PitchBytes,
      SavedLines[Index].First.X, SavedLines[Index].First.Y,
      SavedLines[Index].Last.X, SavedLines[Index].Last.Y);
  SavedLineCount := 0;
end;
{ @end $4AC9D0 }

{ @routine $4ACA60 TMessageLoopGI_ProcessMouseWheel }
procedure TMessageLoopGI.ProcessMouseWheel(KeyState: Cardinal; Point: TPoint; Delta: Integer);
begin
end;
{ @end $4ACA60 }

{ @routine $4ACA68 TMessageLoopGI_ShowTransientText }
procedure TMessageLoopGI.ShowTransientText(Position: TPoint; const Text: WideString);
var LabelControl: TLabelGI; HalfSize: TPoint;
begin
  ClearTransientControl;
  TransientControl := TWindowGI.Create(OverlayPanel);
  TransientControl.SetDepth(-1.0E29);
  if GiResourceVariant = 1 then TransientControl.SetConfigPath('Style.Window.1Normal2')
  else TransientControl.SetConfigPath('Style.Window.2Normal2');
  TransientControl.SetMouseViewUpdates(True);
  TransientData := TLabelGI.Create(TransientControl);
  LabelControl := TransientData as TLabelGI;
  LabelControl.SetFontName(HitPointFontName);
  LabelControl.SetText(Text);
  LabelControl.SetPosition(Classes.Point(10, 10));
  LabelControl.SetSize(Classes.Point(280, 100));
  LabelControl.SetWordWrapEnabled(True);
  LabelControl.SetTextAlignX(taxAuto);
  LabelControl.SetTextAlignY(tayAuto);
  LabelControl.SetTextColor(CurrentPixelFormat.PackRgbBytes(255, 255, 255));
  TransientControl.SetSize(AddPoints(AddPoints(LabelControl.ClientSize, Classes.Point(0, 30)), Classes.Point(30, 30)));
  TransientControl.UpdateAutoGeometry;
  HalfSize := HalfPoint(TransientControl.ClientSize);
  LabelControl.SetPosition(SubtractPoints(HalfSize, HalfPoint(LabelControl.ClientSize)));
  TransientControl.SetPosition(Classes.Point(
    Round((GameScreenWidth - 2 * HalfSize.X) * (Position.X / 100)),
    Round((GameScreenHeight - 2 * HalfSize.Y) * (Position.Y / 100))));
  InvalidateTransientControl;
end;
{ @end $4ACA68 }

{ @routine $4ACD10 TMessageLoopGI_ClearTransientControl }
procedure TMessageLoopGI.ClearTransientControl;
begin
  InvalidateTransientControl;
  if TransientData <> nil then
  begin
    TransientData.Free;
    TransientData := nil;
  end;
  if TransientControl <> nil then
  begin
    TransientControl.SetActive(False);
    TransientControl.Free;
    TransientControl := nil;
  end;
end;
{ @end $4ACD10 }

{ @routine $4ACD58 TMessageLoopGI_InvalidateTransientControl }
procedure TMessageLoopGI.InvalidateTransientControl;
var WasEnabled: Boolean;
begin
  if TransientControl <> nil then
  begin
    WasEnabled := UpdateRectsEnabled;
    UpdateRectsEnabled := True;
    TransientControl.Invalidate;
    UpdateRectsEnabled := WasEnabled;
  end;
end;
{ @end $4ACD58 }

{ @routine $4ACD80 TMessageLoopGI_InitializeDefaults }
procedure TMessageLoopGI.InitializeDefaults;
begin
  RootUiObject := CreateControlByName('Panel', nil);
  RootUiObject.MessageLoop := Self;
  RootUiObject.SetPosition(Classes.Point(0, 0));
  RootUiObject.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  BackgroundPanel := CreateControlByName('Panel', RootUiObject);
  BackgroundPanel.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  BackgroundPanel.SetDepth(1);
  ContentPanel := CreateControlByName('Panel', RootUiObject);
  ContentPanel.SetDepth(0);
  OverlayPanel := CreateControlByName('Panel', RootUiObject);
  OverlayPanel.SetSize(Classes.Point(GameScreenWidth, GameScreenHeight));
  OverlayPanel.SetDepth(-1);
  StatusLabel := TLabelGI.Create(OverlayPanel);
  with StatusLabel as TLabelGI do
  begin
    SetActive(False);
    SetFontName(HitPointFontName);
    SetDepth(-1E29);
    SetPosition(Classes.Point(5, 5));
    SetSize(Classes.Point(400, 20));
    SetTextAlignX(taxLeft);
    SetTextAlignY(tayCenterEx);
  end;
  CursorControl := TCursorGI.Create(OverlayPanel);
  CursorControl.SetDepth(-1E30);
end;
{ @end $4ACD80 }

{ @routine $4ACF38 TMessageLoopGI_InitializeFromConfig }
procedure TMessageLoopGI.InitializeFromConfig(ConfigRoot: TBlockParEC; const ScreenName: WideString; UnusedFlag: Boolean);
var
  ScreenBlock, SoundBlock: TBlockParEC;
  Text: WideString;
  Index, Count: Integer;
  Group: TFormSoundGroup;
begin
  ResetRuntime;
  InitializeDefaults;
  ScreenBlock := ConfigRoot.GetBlockByPath(ScreenName);
  Text := ScreenBlock.GetParam('Border');
  ViewportRect.Left := StrToInt(ExtractDelimitedPartW(Text, 0, ','));
  ViewportRect.Top := StrToInt(ExtractDelimitedPartW(Text, 1, ','));
  ViewportRect.Right := StrToInt(ExtractDelimitedPartW(Text, 2, ','));
  ViewportRect.Bottom := StrToInt(ExtractDelimitedPartW(Text, 3, ','));
  if ScreenBlock.CountBlocks('Sound') > 0 then
  begin
    SoundBlock := ScreenBlock.GetBlock('Sound');
    if SoundBlock.CountParams('Open') > 0 then OpenSoundName := SoundBlock.GetParam('Open');
    if SoundBlock.CountParams('Close') > 0 then CloseSoundName := SoundBlock.GetParam('Close');
    Count := SoundBlock.GetBlockCount;
    for Index := 0 to Count - 1 do
    begin
      Group := TFormSoundGroup.Create;
      SoundGroupList.Add(Group);
      Group.LoadFromBlock(SoundBlock.GetBlockByIndex(Index));
    end;
  end;
  ContentPanel.LoadFromBlock(ScreenBlock.GetBlockByPath('Panel'));
  RootUiObject.UpdateAbsolutePosition;
  RootUiObject.UpdateSubtreeHitBounds;
  QueueUpdateRect(ViewportRect);
end;
{ @end $4ACF38 }

{ @routine $4AD204 TMessageLoopGI_InitializeLayout }
procedure TMessageLoopGI.InitializeLayout;
begin
  RootUiObject.UpdateAutoGeometry;
end;
{ @end $4AD204 }

end.

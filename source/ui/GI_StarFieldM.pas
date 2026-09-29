unit GI_StarFieldM;
// Unit bracket (inferred): CODE 0x00492454..0x004931A3; inclusive evidence, not full bounds.

interface

uses EC_Struct, GI_MessageLoop, GI_Panel, Types;

type
  TMovingStarPalette = array[0..31] of Word;
  TMovingStarColorTable = array[0..15] of TMovingStarPalette;
  PMovingStarColorTable = ^TMovingStarColorTable;

  TMovingStarPixel = record // @size $44
    ByteOffset: Integer; // @offset $00
    PreviousByteOffset: Integer; // @offset $04
    SavedPixel: Word; // @offset $08
    Position: TPointF; // @offset $0C
    Velocity: TPointF; // @offset $14
    Acceleration: TPointF; // @offset $1C
    Direction: TPointF; // @offset $24
    PixelPosition: TPoint; // @offset $2C
    PaletteIndex: Integer; // @offset $34
    Color: Word; // @offset $38
    ColorPosition: Single; // @offset $3C
    ColorStep: Single; // @offset $40
  end;
  PMovingStarPixel = ^TMovingStarPixel;

  TStarFieldMGI = class(TPanelGI) // @size $150
  public
    Stars: PMovingStarPixel; // @offset $118
    StarCount: Integer; // @offset $11C
    Capacity: Integer; // @offset $120
    FocusPoint: TPointF; // @offset $124
    ViewPosition: TPointF; // @offset $12C
    TargetHeading: Single; // @offset $134
    CurrentHeading: Single; // @offset $138
    TargetFocusDistance: Single; // @offset $13C
    CurrentFocusDistance: Single; // @offset $140
    MotionTicks: Integer; // @offset $144
    AnimationTimer: TCallbackTimerIdGI; // @offset $148
    ColorTable: PMovingStarColorTable; // @offset $14C Owns sixteen rows of 32 RGB words; initialization currently selects row zero.

    constructor Create(Owner: TObjectGI); // @addr $49256C
    destructor Destroy; override; // @addr $4926C0
    procedure OnActivate; override; // @addr $492720
    procedure ClearStars; // @addr $492788
    procedure GrowStars; // @addr $4927B4
    function AllocateStar: PMovingStarPixel; // @addr $4927FC
    procedure InitializeStar(Star: PMovingStarPixel); // @addr $492838
    procedure SeedStars; // @addr $4929D0
    procedure AdvanceStars; // @addr $492A1C
    procedure RedirectStars; // @addr $492B14
    procedure AnimateStars(Timer: TCallbackTimerIdGI; UserData: Cardinal); // @addr $492BF0
    procedure SetViewPosition(Position: TPointF); // @addr $492E14
    procedure ErasePreviousFrame; override; // @addr $492F2C
    procedure PrepareFrameDraw; override; // @addr $492FD4
    procedure OnDeactivate; override; // @addr $492764
    procedure Invalidate; override; // @addr $492F28
    procedure DrawUpdateRects(ClipRect: TRect); override; // @addr $493040
    procedure Draw(ClipRect: TRect); override; // @addr $493078
    procedure CommitFrameDraw; override; // @addr $4930C8
  end;

implementation

// @unit-initialization $49319C
// @unit-finalization $49316C

uses Classes, EC_Mem, aMyFunction, Math, GR_Main;

{ @routine $49256C TStarFieldMGI_Create }
constructor TStarFieldMGI.Create(Owner: TObjectGI);
var I, J: Integer;
begin
  inherited Create(Owner);
  FocusPoint := MakePointF(Cardinal(GameScreenWidth) / 2, Cardinal(GameScreenHeight) / 2);
  ColorTable := AllocEC(SizeOf(ColorTable^));
  for I := Low(ColorTable^) to High(ColorTable^) do
    for J := Low(TMovingStarPalette) to High(TMovingStarPalette) do
      WriteWordEC(AddPointerOffset(ColorTable, I * Length(ColorTable^[I]) * SizeOf(Word) + J * SizeOf(Word)),
        CurrentPixelFormat.PackNormalizedRgb(Random * 0.5 + 0.5, Random * 0.5 + 0.5, Random * 0.5 + 0.5));
  SeedStars;
end;
{ @end $49256C }

{ @routine $4926C0 TStarFieldMGI_Destroy }
destructor TStarFieldMGI.Destroy;
begin
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
  if ColorTable <> nil then
  begin
    FreeEC(ColorTable);
    ColorTable := nil;
  end;
  ClearStars;
  inherited Destroy;
end;
{ @end $4926C0 }

{ @routine $492720 TStarFieldMGI_OnActivate }
procedure TStarFieldMGI.OnActivate;
begin
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
  AnimationTimer := MessageLoop.ScheduleCallbackTimer(50, 50, AnimateStars);
end;
{ @end $492720 }

{ @routine $492764 TStarFieldMGI_OnDeactivate }
procedure TStarFieldMGI.OnDeactivate;
begin
  if AnimationTimer <> 0 then
  begin
    MessageLoop.CancelCallbackTimer(AnimationTimer);
    AnimationTimer := 0;
  end;
end;
{ @end $492764 }

{ @routine $492788 TStarFieldMGI_ClearStars }
procedure TStarFieldMGI.ClearStars;
begin
  if Stars <> nil then
  begin
    FreeEC(Stars);
    Stars := nil;
  end;
  StarCount := 0;
  Capacity := 0;
end;
{ @end $492788 }

{ @routine $4927B4 TStarFieldMGI_GrowStars }
procedure TStarFieldMGI.GrowStars;
var Tail: Pointer;
begin
  Inc(Capacity, 64);
  Stars := ReAllocREC(Stars, SizeOf(TMovingStarPixel) * Capacity);
  Tail := AddPointerOffset(Stars, SizeOf(TMovingStarPixel) * (Capacity - 64));
  Windows.ZeroMemory(Tail, SizeOf(TMovingStarPixel) * 64);
end;
{ @end $4927B4 }

{ @routine $4927FC TStarFieldMGI_AllocateStar }
function TStarFieldMGI.AllocateStar: PMovingStarPixel;
begin
  Inc(StarCount);
  if StarCount > Capacity then GrowStars;
  Result := AddPointerOffset(Stars, SizeOf(TMovingStarPixel) * (StarCount - 1));
end;
{ @end $4927FC }

{ @routine $492838 TStarFieldMGI_InitializeStar }
procedure TStarFieldMGI.InitializeStar(Star: PMovingStarPixel);
var Angle, DX, DY, Speed, Factor: Single;
begin
  Star.Position.X := Random * (Cardinal(GameScreenWidth) - 1);
  Star.Position.Y := Random * (Cardinal(GameScreenHeight) - 1);
  Star.PixelPosition.X := Round(Star.Position.X);
  Star.PixelPosition.Y := Round(Star.Position.Y);
  Factor := Random;
  Angle := ArcTan2(Star.Position.X - FocusPoint.X, -(Star.Position.Y - FocusPoint.Y));
  DX := Sin(Angle);
  DY := -Cos(Angle);
  Star.Direction.X := DX;
  Star.Direction.Y := DY;
  Speed := 0.5 * Factor + 0.1;
  Star.Velocity.X := DX * Speed;
  Star.Velocity.Y := DY * Speed;
  Speed := 0.3 * Factor + 0.1;
  Star.Acceleration.X := DX * Speed;
  Star.Acceleration.Y := DY * Speed;
  Star.ColorPosition := 0;
  Star.ColorStep := 4 * Factor + 2;
  Star.PaletteIndex := 0;
  Star.Color := ReadWordEC(AddPointerOffset(ColorTable, Star.PaletteIndex * Length(ColorTable^[0]) * SizeOf(Word) + Round(Star.ColorPosition) * SizeOf(Word)));
end;
{ @end $492838 }

{ @routine $4929D0 TStarFieldMGI_SeedStars }
procedure TStarFieldMGI.SeedStars;
var I, Count: Integer; Star: PMovingStarPixel;
begin
  Count := 50;
  if GameScreenWidth = 800 then Count := Round(Count * 0.6103515625);
  for I := 0 to Count - 1 do
  begin
    Star := AllocateStar;
    InitializeStar(Star);
  end;
end;
{ @end $4929D0 }

{ @routine $492A1C TStarFieldMGI_AdvanceStars }
procedure TStarFieldMGI.AdvanceStars;
var Star: PMovingStarPixel; I, X, Y: Integer;
begin
  Star := Stars;
  for I := 0 to StarCount - 1 do
  begin
    Star.Velocity.X := Star.Velocity.X + Star.Acceleration.X;
    Star.Velocity.Y := Star.Velocity.Y + Star.Acceleration.Y;
    Star.Position.X := Star.Position.X + Star.Velocity.X;
    Star.Position.Y := Star.Position.Y + Star.Velocity.Y;
    X := Round(Star.Position.X);
    Y := Round(Star.Position.Y);
    Star.PixelPosition.X := X;
    Star.PixelPosition.Y := Y;
    if (X < HitTestBounds.Left) or (X >= HitTestBounds.Right) or
      (Y < HitTestBounds.Top) or (Y >= HitTestBounds.Bottom) then InitializeStar(Star);
    if Star.ColorPosition < High(TMovingStarPalette) then
    begin
      Star.ColorPosition := Star.ColorPosition + Star.ColorStep;
      if Star.ColorPosition > High(TMovingStarPalette) then
      begin
        Star.ColorPosition := High(TMovingStarPalette);
        Star.ColorStep := 0;
      end;
      Star.Color := ReadWordEC(AddPointerOffset(ColorTable, Star.PaletteIndex * Length(ColorTable^[0]) * SizeOf(Word) + Round(Star.ColorPosition) * SizeOf(Word)));
    end;
    Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
  end;
end;
{ @end $492A1C }

{ @routine $492B14 TStarFieldMGI_RedirectStars }
procedure TStarFieldMGI.RedirectStars;
var Star: PMovingStarPixel; I: Integer; Distance, Speed: Single; Direction: TPointF;
begin
  Star := Stars;
  for I := 0 to StarCount - 1 do
  begin
    Direction.X := Star.Position.X - FocusPoint.X;
    Direction.Y := Star.Position.Y - FocusPoint.Y;
    Distance := Sqrt(Direction.X * Direction.X + Direction.Y * Direction.Y);
    Direction.X := Direction.X / Distance;
    Direction.Y := Direction.Y / Distance;
    Star.Direction.X := Direction.X;
    Star.Direction.Y := Direction.Y;
    Speed := Sqrt(Star.Velocity.X * Star.Velocity.X + Star.Velocity.Y * Star.Velocity.Y);
    Star.Velocity.X := Speed * Direction.X;
    Star.Velocity.Y := Speed * Direction.Y;
    Speed := Sqrt(Star.Acceleration.X * Star.Acceleration.X + Star.Acceleration.Y * Star.Acceleration.Y);
    Star.Acceleration.X := Speed * Direction.X;
    Star.Acceleration.Y := Speed * Direction.Y;
    Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
  end;
end;
{ @end $492B14 }

{ @routine $492BF0 TStarFieldMGI_AnimateStars }
procedure TStarFieldMGI.AnimateStars(Timer: TCallbackTimerIdGI; UserData: Cardinal);
var Delta: Single;
begin
  if StarCount > 0 then
  begin
    Dec(MotionTicks);
    if MotionTicks < 0 then
    begin
      TargetFocusDistance := 0;
      MotionTicks := 0;
    end;
    if (TargetHeading <> CurrentHeading) or (TargetFocusDistance <> CurrentFocusDistance) then
    begin
      Delta := HeadingDifferenceDegrees(CurrentHeading, TargetHeading);
      if Abs(Delta) <= 15 then CurrentHeading := TargetHeading
      else
      begin
        if Delta < 0 then CurrentHeading := WrapHeadingDegrees(CurrentHeading - 15)
        else if Delta > 0 then CurrentHeading := WrapHeadingDegrees(CurrentHeading + 15);
      end;
      if TargetFocusDistance < CurrentFocusDistance then
        CurrentFocusDistance := Max(TargetFocusDistance, CurrentFocusDistance - 90)
      else if TargetFocusDistance > CurrentFocusDistance then
        CurrentFocusDistance := Min(TargetFocusDistance, CurrentFocusDistance + 60);
      FocusPoint.X := Sin(HeadingDegreesToRadians(CurrentHeading)) * CurrentFocusDistance + Cardinal(GameScreenWidth) / 2;
      FocusPoint.Y := Cardinal(GameScreenHeight) / 2 - Cos(HeadingDegreesToRadians(CurrentHeading)) * CurrentFocusDistance;
      RedirectStars;
    end;
    AdvanceStars;
    Invalidate;
  end;
end;
{ @end $492BF0 }

{ @routine $492E14 TStarFieldMGI_SetViewPosition }
procedure TStarFieldMGI.SetViewPosition(Position: TPointF);
var DX, DY: Single;
begin
  DX := Position.X - ViewPosition.X;
  DY := Position.Y - ViewPosition.Y;
  if DY * DY + DX * DX >= 25 then
  begin
    if (DX <> 0) or (DY <> 0) then
    begin
      TargetHeading := RadiansToHeadingDegrees(ArcTan2(DX, -DY));
      if CurrentFocusDistance = 0 then CurrentFocusDistance := TargetFocusDistance;
      if GameScreenWidth = 1024 then TargetFocusDistance := 1800
      else TargetFocusDistance := 1230;
      MotionTicks := 5;
      RedirectStars;
    end;
    ViewPosition := Position;
  end;
end;
{ @end $492E14 }

{ @routine $492F28 TStarFieldMGI_Invalidate }
procedure TStarFieldMGI.Invalidate;
begin
end;
{ @end $492F28 }

{ @routine $492F2C TStarFieldMGI_ErasePreviousFrame }
procedure TStarFieldMGI.ErasePreviousFrame;
var Star: PMovingStarPixel; Buffer: Pointer; I: Integer;
begin
  begin
    Buffer := ScreenRenderBuffer.Pixels;
    if not SkipSavedPixelRestore then
    begin
      if not BGImage then
      begin
        Star := Stars;
        for I := 0 to StarCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Star.PreviousByteOffset), 0);
          Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
        end;
      end
      else
      begin
        Star := Stars;
        for I := 0 to StarCount - 1 do
        begin
          WriteWordEC(AddPointerOffset(Buffer, Star.PreviousByteOffset), Star.SavedPixel);
          Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
        end;
      end;
    end;
  end;
end;
{ @end $492F2C }

{ @routine $492FD4 TStarFieldMGI_PrepareFrameDraw }
procedure TStarFieldMGI.PrepareFrameDraw;
var Star: PMovingStarPixel; I: Integer; Buffer: Pointer;
begin
  begin
    Buffer := ScreenRenderBuffer.Pixels;
    Star := Stars;
    for I := 0 to StarCount - 1 do
    begin
      Star.ByteOffset := Star.PixelPosition.X * 2 + Star.PixelPosition.Y * ScreenRenderBuffer.PitchBytes;
      if BGImage then Star.SavedPixel := ReadWordEC(AddPointerOffset(Buffer, Star.ByteOffset));
      Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
    end;
  end;
end;
{ @end $492FD4 }

{ @routine $493040 TStarFieldMGI_DrawUpdateRects }
procedure TStarFieldMGI.DrawUpdateRects(ClipRect: TRect);
begin
  Draw(Classes.Rect(0, 0, GameScreenWidth, GameScreenHeight));
end;
{ @end $493040 }

{ @routine $493078 TStarFieldMGI_Draw }
procedure TStarFieldMGI.Draw(ClipRect: TRect);
var Pixel: PMovingStarPixel; I: Integer; Buffer: Pointer;
begin
  Buffer := ScreenRenderBuffer.Pixels;
  Pixel := Stars;
  for I := 0 to StarCount - 1 do
  begin
    WriteWordEC(AddPointerOffset(Buffer, Pixel.ByteOffset), Pixel.Color);
    Pixel := AddPointerOffset(Pixel, SizeOf(TMovingStarPixel));
  end;
end;
{ @end $493078 }

{ @routine $4930C8 TStarFieldMGI_CommitFrameDraw }
procedure TStarFieldMGI.CommitFrameDraw;
var Star: PMovingStarPixel; I: Integer; Source, Dest: Pointer;
begin
  Source := ScreenRenderBuffer.Pixels;
  Dest := ScreenPresentBuffer.Pixels;
  Star := Stars;
  for I := 0 to StarCount - 1 do
  begin
    if not SkipSavedPixelRestore then
      WriteWordEC(AddPointerOffset(Dest, Star.PreviousByteOffset), ReadWordEC(AddPointerOffset(Source, Star.PreviousByteOffset)));
    WriteWordEC(AddPointerOffset(Dest, Star.ByteOffset), ReadWordEC(AddPointerOffset(Source, Star.ByteOffset)));
    Star.PreviousByteOffset := Star.ByteOffset;
    Star := AddPointerOffset(Star, SizeOf(TMovingStarPixel));
  end;
end;
{ @end $4930C8 }

end.

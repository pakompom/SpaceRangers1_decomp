unit GI_PSWeapon;
// Unit bracket (inferred): CODE 0x004959D0..0x00495BA3; inclusive evidence, not full bounds.
// Projectile timing base.

interface

uses GI_MessageLoop, Types;

type
  TPSWeaponGI = class(TObjectGI) // @size $110
  public
    TargetPoint: TPoint; // @offset $100
    RemainingTicks: Integer; // @offset $108
    LifetimeTicks: Integer; // @offset $10C

    constructor Create(Owner: TObjectGI); // @addr $495AF0
    procedure SetTargetPoint(Point: TPoint); virtual; abstract; // @slot $B8
    procedure Advance(Timer: TCallbackTimerIdGI; UserData: Cardinal); virtual; abstract; // @slot $BC
    function IsFinished: Boolean; virtual; // @addr $495B40 @slot $C0
    function GetElapsedTicks: Integer; virtual; // @addr $495B5C @slot $C4 @note "Returns LifetimeTicks minus RemainingTicks without clamping."
  end;

implementation

// @unit-initialization $495B9C
// @unit-finalization $495B6C

uses GR_Main;

{ @routine $495AF0 TPSWeaponGI_Create }
constructor TPSWeaponGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  LifetimeTicks := 65;
  RemainingTicks := LifetimeTicks;
end;
{ @end $495AF0 }

{ @routine $495B40 TPSWeaponGI_IsFinished }
function TPSWeaponGI.IsFinished: Boolean;
begin
  // Advances the base projectile lifetime when checking completion.
  if RemainingTicks > 0 then Dec(RemainingTicks);
  Result := RemainingTicks <= 0;
end;
{ @end $495B40 }

{ @routine $495B5C TPSWeaponGI_GetElapsedTicks }
function TPSWeaponGI.GetElapsedTicks: Integer;
begin
  Result := LifetimeTicks - RemainingTicks;
end;
{ @end $495B5C }

end.

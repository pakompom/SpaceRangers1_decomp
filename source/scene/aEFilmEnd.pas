unit aEFilmEnd;
// Unit bracket (inferred): CODE 0x00561778..0x00561A6F; inclusive evidence, not full bounds.

interface

uses EC_Struct, SE_Space, aEFilm;

type
  PEFilmEndEntry = ^TEFilmEndEntry;
  TEFilmEndEntry = packed record // @size $14
    Prev: PEFilmEndEntry; // @offset $00
    Next: PEFilmEndEntry; // @offset $04
    SceneObject: TObjectSE; // @offset $08
    RelatedObject1: TObjectSE; // @offset $0C
    RelatedObject2: TObjectSE; // @offset $10
  end;

  TEFilmEnd = class(TObjectEx) // @size $0C
  public
    FirstEntry: PEFilmEndEntry; // @offset $04
    LastEntry: PEFilmEndEntry; // @offset $08

    constructor Create; // @addr $5617D0
    destructor Destroy; override; // @addr $561808
    procedure Clear; // @addr $561834
    function AppendEntry: PEFilmEndEntry; // @addr $56184C
    procedure RemoveEntry(Entry: PEFilmEndEntry); // @addr $56188C @note "Detaches and releases all three retained scene references, then frees Entry."
    procedure TakeTrailingEffects(Film: TEFilm); // @addr $561910 @note "Transfers selected scene references from Film. Requires its 0x18 command marker."
    procedure AdvanceEffects; // @addr $5619B4
  end;

var

implementation

// @unit-initialization $561A68
// @unit-finalization $561A38

uses EC_Mem, SE_Weapon;

{ @routine $5617D0 TEFilmEnd_Create }
constructor TEFilmEnd.Create;
begin inherited Create end;
{ @end $5617D0 }

{ @routine $561808 TEFilmEnd_Destroy }
destructor TEFilmEnd.Destroy;
begin Clear; inherited Destroy end;
{ @end $561808 }

{ @routine $561834 TEFilmEnd_Clear }
procedure TEFilmEnd.Clear;
begin while FirstEntry <> nil do RemoveEntry(LastEntry) end;
{ @end $561834 }

{ @routine $56184C TEFilmEnd_AppendEntry }
function TEFilmEnd.AppendEntry: PEFilmEndEntry;
var Entry: PEFilmEndEntry;
begin
  Entry := AllocEC(SizeOf(TEFilmEndEntry));
  if LastEntry <> nil then LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then FirstEntry := Entry;
  Entry.SceneObject := nil;
  Entry.RelatedObject1 := nil;
  Entry.RelatedObject2 := nil;
  Result := Entry;
end;
{ @end $56184C }

{ @routine $56188C TEFilmEnd_RemoveEntry }
procedure TEFilmEnd.RemoveEntry(Entry: PEFilmEndEntry);
begin
  if Entry.Prev <> nil then Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then LastEntry := Entry.Prev;
  if FirstEntry = Entry then FirstEntry := Entry.Next;
  if Entry.SceneObject <> nil then
  begin TWeaponSE(Entry.SceneObject).DetachFromSpace; Entry.SceneObject.Free; Entry.SceneObject := nil end;
  if Entry.RelatedObject1 <> nil then
  begin Entry.RelatedObject1.DetachFromSpace; Entry.RelatedObject1.Free; Entry.RelatedObject1 := nil end;
  if Entry.RelatedObject2 <> nil then
  begin Entry.RelatedObject2.DetachFromSpace; Entry.RelatedObject2.Free; Entry.RelatedObject2 := nil end;
  FreeEC(Entry);
end;
{ @end $56188C }

{ @routine $561910 TEFilmEnd_TakeTrailingEffects }
procedure TEFilmEnd.TakeTrailingEffects(Film: TEFilm);
var
  Command, FirstTrailing: PEFilmCommand;
  Obj: TEFilmObj;
  Entry: PEFilmEndEntry;
  Weapon: TWeaponSE;
begin
  FirstTrailing := Film.LastCommand;
  while FirstTrailing <> nil do
  begin
    if FirstTrailing.Kind = efcBeginTrailingEffects then Break;
    FirstTrailing := FirstTrailing.Prev;
  end;
  FirstTrailing := FirstTrailing.Next;
  Obj := Film.FirstObject;
  while Obj <> nil do
  begin
    if Obj.SceneObject is TWeaponSE then
    begin
      Weapon := Obj.SceneObject as TWeaponSE;
      Entry := AppendEntry;
      Entry.SceneObject := Weapon;
      if Weapon.TargetDestroyed then
      begin
        Command := FirstTrailing;
        while Command <> nil do
        begin
          if (Command.Kind = efcReleaseObject) and (TEFilmObjectCommand(Command^).Obj <> nil) and
            (TEFilmObjectCommand(Command^).Obj.SceneObject = Weapon.TargetObject) then
          begin
            Entry.RelatedObject1 := TEFilmObjectCommand(Command^).Obj.SceneObject;
            TEFilmObjectCommand(Command^).Obj.SceneObject := nil;
            Break;
          end;
          Command := Command.Next;
        end;
      end;
      Obj.SceneObject := nil;
    end;
    Obj := Obj.Next;
  end;
end;
{ @end $561910 }

{ @routine $5619B4 TEFilmEnd_AdvanceEffects }
procedure TEFilmEnd.AdvanceEffects;
var NextEntry, Entry: PEFilmEndEntry;
begin
  NextEntry := FirstEntry;
  while NextEntry <> nil do
  begin
    Entry := NextEntry;
    NextEntry := NextEntry.Next;
    Entry.SceneObject.Advance;
    if not Entry.SceneObject.IsAttachedToSpace then
    begin
      Entry.SceneObject.DetachFromSpace;
      Entry.SceneObject.Free; Entry.SceneObject := nil;
      if Entry.RelatedObject1 <> nil then
      begin
        Entry.RelatedObject1.DetachFromSpace;
        Entry.RelatedObject1.Free; Entry.RelatedObject1 := nil;
      end;
      if Entry.RelatedObject2 <> nil then
      begin
        Entry.RelatedObject2.DetachFromSpace;
        Entry.RelatedObject2.Free; Entry.RelatedObject2 := nil;
      end;
      RemoveEntry(Entry);
    end;
  end;
end;
{ @end $5619B4 }

end.

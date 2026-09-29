unit fFilmFile;
// Unit bracket (inferred): CODE 0x0054E514..0x0054E8FB; inclusive evidence, not full bounds.

interface

uses aEFilm, EC_Buf, EC_Struct, SyncObjs;

type
  PFilmHistoryEntry = ^TFilmHistoryEntry;
  TFilmHistoryEntry = packed record // @size $10
    Prev: PFilmHistoryEntry; // @offset $00
    Next: PFilmHistoryEntry; // @offset $04
    Turn: Integer; // @offset $08
    Buffer: TBufEC; // @offset $0C  Owned serialized TEFilm, excluding Turn.
  end;

  TFilmFile = class(TObjectEx) // @size $10
  public
    FirstEntry: PFilmHistoryEntry; // @offset $04
    LastEntry: PFilmHistoryEntry; // @offset $08
    Lock: TCriticalSection; // @offset $0C

    constructor Create; // @addr $54E56C
    destructor Destroy; override; // @addr $54E5B0
    procedure Clear; // @addr $54E5F0
    function AppendEntry: PFilmHistoryEntry; // @addr $54E618 @note "Caller holds Lock. Appends a zeroed entry owned by this history."
    procedure RemoveEntry(Entry: PFilmHistoryEntry); // @addr $54E648 @note "Caller holds Lock. Unlinks Entry and frees its buffer and storage."
    function GetCount: Integer; // @addr $54E694
    function GetEntry(Index: Integer): PFilmHistoryEntry; // @addr $54E6C0 @note "Zero-based insertion order. Returns a borrowed entry after releasing Lock; raises for an invalid index."
    procedure AddFilm(Film: TEFilm); // @addr $54E720 @note "Copies Film into a new buffer. Evicts entries with the lowest Turn until below CountFilmSave, which must be positive."
    procedure DeleteEntry(Entry: PFilmHistoryEntry); // @addr $54E7E0 @note "Locks and removes an entry belonging to this history."
    procedure LoadFilm(Entry: PFilmHistoryEntry; Film: TEFilm); // @addr $54E804 @note "Replaces Film's contents but does not set Film.Turn; caller copies Entry.Turn. Rewinds the stored buffer afterward."
    procedure SaveEntryToBuffer(Entry: PFilmHistoryEntry; Buffer: TBufEC); // @addr $54E840 @note "Clears Buffer, then writes Turn and the length-prefixed film payload."
    procedure LoadEntryFromBuffer(Buffer: TBufEC); // @addr $54E878 @note "Appends without enforcing CountFilmSave. Reads from the current buffer position."
  end;

implementation

// @unit-initialization $54E8F4
// @unit-finalization $54E8C4

uses EC_Mem, Globals, GlobalsV, SysUtils;

{ @routine $54E56C TFilmFile_Create }
constructor TFilmFile.Create;
begin
  inherited Create;
  Lock := TCriticalSection.Create;
end;
{ @end $54E56C }

{ @routine $54E5B0 TFilmFile_Destroy }
destructor TFilmFile.Destroy;
begin
  Clear;
  if Lock <> nil then
  begin
    Lock.Free;
    Lock := nil;
  end;
  inherited Destroy;
end;
{ @end $54E5B0 }

{ @routine $54E5F0 TFilmFile_Clear }
procedure TFilmFile.Clear;
begin
  Lock.Enter;
  while FirstEntry <> nil do RemoveEntry(LastEntry);
  Lock.Leave;
end;
{ @end $54E5F0 }

{ @routine $54E618 TFilmFile_AppendEntry }
function TFilmFile.AppendEntry: PFilmHistoryEntry;
var Entry: PFilmHistoryEntry;
begin
  Entry := AllocClearEC(SizeOf(TFilmHistoryEntry));
  if LastEntry <> nil then LastEntry.Next := Entry;
  Entry.Prev := LastEntry;
  Entry.Next := nil;
  LastEntry := Entry;
  if FirstEntry = nil then FirstEntry := Entry;
  Result := Entry;
end;
{ @end $54E618 }

{ @routine $54E648 TFilmFile_RemoveEntry }
procedure TFilmFile.RemoveEntry(Entry: PFilmHistoryEntry);
begin
  if Entry.Prev <> nil then Entry.Prev.Next := Entry.Next;
  if Entry.Next <> nil then Entry.Next.Prev := Entry.Prev;
  if LastEntry = Entry then LastEntry := Entry.Prev;
  if FirstEntry = Entry then FirstEntry := Entry.Next;
  if Entry.Buffer <> nil then
  begin
    Entry.Buffer.Free;
    Entry.Buffer := nil;
  end;
  FreeEC(Entry);
end;
{ @end $54E648 }

{ @routine $54E694 TFilmFile_GetCount }
function TFilmFile.GetCount: Integer;
var
  Entry: PFilmHistoryEntry;
  Count: Integer;
begin
  Lock.Enter;
  Count := 0;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    Inc(Count);
    Entry := Entry.Next;
  end;
  Result := Count;
  Lock.Leave;
end;
{ @end $54E694 }

{ @routine $54E6C0 TFilmFile_GetEntry }
function TFilmFile.GetEntry(Index: Integer): PFilmHistoryEntry;
var Entry: PFilmHistoryEntry;
begin
  Lock.Enter;
  Entry := FirstEntry;
  while Entry <> nil do
  begin
    if Index = 0 then
    begin
      Result := Entry;
      Lock.Leave;
      Exit;
    end;
    Dec(Index);
    Entry := Entry.Next;
  end;
  Lock.Leave;
  raise Exception.Create('Error');
end;
{ @end $54E6C0 }

{ @routine $54E720 TFilmFile_AddFilm }
procedure TFilmFile.AddFilm(Film: TEFilm);
var
  Entry, Oldest: PFilmHistoryEntry;
  Turn: Integer;
  Buffer: TBufEC;
begin
  Lock.Enter;
  while GetCount >= CountFilmSave do
  begin
    Oldest := FirstEntry;
    Turn := Oldest.Turn;
    Entry := Oldest.Next;
    while Entry <> nil do
    begin
      if Entry.Turn < Turn then
      begin
        Turn := Entry.Turn;
        Oldest := Entry;
      end;
      Entry := Entry.Next;
    end;
    DeleteEntry(Oldest);
  end;
  Buffer := TBufEC.Create;
  Film.SaveToBuffer(Buffer);
  Buffer.SetPosition(0);
  if Buffer.DataSize < 1 then
  begin
    Lock.Leave;
    raise Exception.Create('Error');
  end;
  Entry := AppendEntry;
  Entry.Turn := Film.Turn;
  Entry.Buffer := Buffer;
  Lock.Leave;
end;
{ @end $54E720 }

{ @routine $54E7E0 TFilmFile_DeleteEntry }
procedure TFilmFile.DeleteEntry(Entry: PFilmHistoryEntry);
begin
  Lock.Enter;
  RemoveEntry(Entry);
  Lock.Leave;
end;
{ @end $54E7E0 }

{ @routine $54E804 TFilmFile_LoadFilm }
procedure TFilmFile.LoadFilm(Entry: PFilmHistoryEntry; Film: TEFilm);
begin
  Lock.Enter;
  Entry.Buffer.SetPosition(0);
  Film.LoadFromBuffer(Entry.Buffer);
  Entry.Buffer.SetPosition(0);
  Lock.Leave;
end;
{ @end $54E804 }

{ @routine $54E840 TFilmFile_SaveEntryToBuffer }
procedure TFilmFile.SaveEntryToBuffer(Entry: PFilmHistoryEntry; Buffer: TBufEC);
begin
  Buffer.Clear;
  Lock.Enter;
  Buffer.AddIntegerValue(Entry.Turn);
  Buffer.AddBuffer(Entry.Buffer);
  Lock.Leave;
end;
{ @end $54E840 }

{ @routine $54E878 TFilmFile_LoadEntryFromBuffer }
procedure TFilmFile.LoadEntryFromBuffer(Buffer: TBufEC);
var Entry: PFilmHistoryEntry;
begin
  Lock.Enter;
  Entry := AppendEntry;
  Entry.Turn := Buffer.GetInt32;
  Entry.Buffer := TBufEC.Create;
  Buffer.ReadLengthPrefixedBuffer(Entry.Buffer);
  Lock.Leave;
end;
{ @end $54E878 }

end.

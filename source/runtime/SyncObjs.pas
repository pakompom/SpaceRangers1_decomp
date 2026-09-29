unit SyncObjs;
// Unit bracket (inferred): CODE 0x00426B08..0x00426CAB; inclusive evidence, not full bounds.
// Declaration-only Delphi 7 critical section; implementations come from the DCU.
interface
type
  TCriticalSection = class(TObject) // @size $1C
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;
implementation
end.

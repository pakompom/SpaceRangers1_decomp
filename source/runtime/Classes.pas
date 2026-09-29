unit Classes;
// Unit bracket (inferred): CODE 0x00412094..0x0041B869; inclusive evidence, not full bounds.
// Declaration-only Delphi 7 view; implementations come from Classes.dcu.
interface
type
  TPointerList = array[0..$7FFFFFE] of Pointer;
  PPointerList = ^TPointerList;
  TList = class(TObject) // @size $10
  public
    List: PPointerList; // @offset $04
    Count: Integer; // @offset $08
    Capacity: Integer; // @offset $0C
    destructor Destroy; override;
    procedure Grow; virtual; // @slot $00
    procedure Notify(Item: Pointer; Action: Byte); virtual; // @slot $04
    procedure Clear; virtual; // @slot $08
    function Add(Item: Pointer): Integer;
    procedure Delete(Index: Integer);
    function Get(Index: Integer): Pointer;
    procedure Put(Index: Integer; Item: Pointer);
    function IndexOf(Item: Pointer): Integer;
    procedure Insert(Index: Integer; Item: Pointer);
    function Remove(Item: Pointer): Integer;
    property Items[Index: Integer]: Pointer read Get write Put; default;
  end;
implementation
end.

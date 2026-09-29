unit Types;
// Unit bracket (inferred): CODE 0x00406B38..0x00406BAF; inclusive evidence, not full bounds.

// Declaration-only view of the RTL records used by EC_Struct.
// Compiled builds use Types.dcu; native field accesses verify these layouts.
interface

type
  TPoint = packed record // @size $08
    X: Integer; // @offset $00
    Y: Integer; // @offset $04
  end;
  TRect = packed record // @size $10
    Left: Integer; // @offset $00
    Top: Integer; // @offset $04
    Right: Integer; // @offset $08
    Bottom: Integer; // @offset $0C
  end;

implementation
end.

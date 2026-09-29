unit EC_OKGF;
// Unit bracket (inferred): CODE 0x004ADB28..0x004ADB67; inclusive evidence, not full bounds.
interface
uses Types;

type
  POkgfRect = ^TRect;
  TOkgfImageKind = (oikUnknown = 0, oikBmp = 1, oikIndexedBmp = 2,
    oikJpeg = 3, oikPng = 4, oikIndexedPsd = 5, oikGrayscalePsd = 6,
    oikRgbPsd = 7, oikCmykPsd = 8); // @size $04

  TOkgfReadContext = packed record // @size $20
    CodecContext: Pointer; // @offset $00
    ImageKind: TOkgfImageKind; // @offset $04
    Width: Integer; // @offset $08
    Height: Integer; // @offset $0C
    PaletteCount: Integer; // @offset $10
    SourceData: Pointer; // @offset $14
    SourceSize: Integer; // @offset $18
    OwnsSource: Integer; // @offset $1C
  end;
  POkgfReadContext = ^TOkgfReadContext;

// Package block decompression uses the cdecl okgf.dll export.
function OKGF_ZLib_UnCompress2(Dest: Pointer; DestCapacity: Integer; Source: Pointer; SourceSize: Integer): Integer; cdecl;
  external 'okgf.dll' name 'OKGF_ZLib_UnCompress2'; // @addr $4ADB28

implementation

// @unit-initialization $4ADB60
// @unit-finalization $4ADB30

end.

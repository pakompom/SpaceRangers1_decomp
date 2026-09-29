unit SysUtils;
// Unit bracket (inferred): CODE 0x00407CDC..0x0040E4B8; inclusive evidence, not full bounds.
// Declaration-only Delphi 7 runtime view.
interface
type
  Exception = class(TObject) // @size $0C
  public
    Message: AnsiString; // @offset $04
    constructor Create(Message: AnsiString);
  end;
  EAbort = class(Exception) // @size $0C
  end;
procedure Abort; // @addr $40C3E0
function IntToStr(Value: Integer): AnsiString; // @addr $408D20
function StrToInt(Value: AnsiString): Integer; // @addr $408E5C
function StrToFloat(const Value: AnsiString): Extended; // @addr $40A298
function Trim(const Text: WideString): WideString; // @addr $408BEC
function TrimRight(const Text: WideString): WideString; // @addr $408C3C
procedure Sleep(Milliseconds: Cardinal); stdcall; external 'kernel32.dll' name 'Sleep'; // @addr $40D944
var
  DecimalSeparator: AnsiChar; // @addr $61B683
function FileExists(const FileName: AnsiString): Boolean; // @addr $409208

function DirectoryExists(const Directory: AnsiString): Boolean; // @addr $409218
function CreateDir(const Directory: AnsiString): Boolean; // @addr $409428

implementation
end.

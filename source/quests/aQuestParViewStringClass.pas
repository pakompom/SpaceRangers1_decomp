unit aQuestParViewStringClass;
// Unit bracket (inferred): CODE 0x004D0BE8..0x004D0D6F; inclusive evidence, not full bounds.
interface
uses EC_Buf, aArtifactTextFieldClass;
type
  TQuestParWiewString = class(TObject) // @size $10
  public
    destructor Destroy; override; // @addr $4D0D00
    constructor Create(InitialText: WideString); // @addr $4D0C70
    procedure LoadFromReader(Reader: TBufEC); // @addr $4D0C48
    MinValue: Integer; // @offset $4
    MaxValue: Integer; // @offset $8
    Text: TTextField; // @offset $C
  end;
implementation

// @unit-initialization $4D0D68
// @unit-finalization $4D0D38

{ @routine $4D0C48 TQuestParWiewString_LoadFromReader }
procedure TQuestParWiewString.LoadFromReader(Reader: TBufEC);
begin
  MinValue := Reader.GetInt32;
  MaxValue := Reader.GetInt32;
  Text.LoadTextLinesFromReader(Reader);
end;
{ @end $4D0C48 }

{ @routine $4D0C70 TQuestParWiewString_Create }
constructor TQuestParWiewString.Create(InitialText: WideString);
begin
  inherited Create;
  Text := TTextField.Create;
  Text.Text := InitialText;
end;
{ @end $4D0C70 }

{ @routine $4D0D00 TQuestParWiewString_Destroy }
destructor TQuestParWiewString.Destroy;
begin
  if Text <> nil then begin Text.Free; Text := nil; end;
  inherited Destroy;
end;
{ @end $4D0D00 }

end.

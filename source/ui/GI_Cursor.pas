unit GI_Cursor;
// Unit bracket (inferred): CODE 0x004A858C..0x004A883B; inclusive evidence, not full bounds.

interface

uses GI_Image, GI_MessageLoop, Types;

type
  TCursorGI = class(TObjectGI) // @size $104
  public
    ImageControl: TImageGI; // @offset $100
    constructor Create(Owner: TObjectGI); // @addr $4A869C
    destructor Destroy; override; // @addr $4A86EC
    procedure Clear; override; // @addr $4A8714 @note "Clears the retained image child."
    procedure SetImagePath(const Path: WideString); // @addr $4A8720
    procedure SetActive(Enabled: Boolean); override; // @addr $4A8770
    procedure SetOrigin(Origin: TPoint); override; // @addr $4A87A4
    procedure Draw(ClipRect: TRect); override; // @addr $4A87E8
  end;

implementation

// @unit-initialization $4A8834
// @unit-finalization $4A8804

uses Classes;

{ @routine $4A869C TCursorGI_Create }
constructor TCursorGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  ImageControl := TImageGI.Create(Self);
  Active := False;
end;
{ @end $4A869C }

{ @routine $4A86EC TCursorGI_Destroy }
destructor TCursorGI.Destroy;
begin
  inherited Destroy;
end;
{ @end $4A86EC }

{ @routine $4A8714 TCursorGI_Clear }
procedure TCursorGI.Clear;
begin
  ImageControl.Clear;
end;
{ @end $4A8714 }

{ @routine $4A8720 TCursorGI_SetImagePath }
procedure TCursorGI.SetImagePath(const Path: WideString);
begin
  Clear;
  ImageControl.SetImagePath(Path);
  SetSize(ImageControl.GetContentSize);
  ImageControl.SetSize(ClientSize);
  ImageControl.RestartPlayback;
end;
{ @end $4A8720 }

{ @routine $4A8770 TCursorGI_SetActive }
procedure TCursorGI.SetActive(Enabled: Boolean);
begin
  Invalidate;
  inherited SetActive(Enabled);
  ImageControl.SetActive(Enabled);
  ImageControl.RestartPlayback;
end;
{ @end $4A8770 }

{ @routine $4A87A4 TCursorGI_SetOrigin }
procedure TCursorGI.SetOrigin(Origin: TPoint);
begin
  inherited SetOrigin(Origin);
  ImageControl.SetPosition(Classes.Point(-Origin.X, -Origin.Y));
end;
{ @end $4A87A4 }

{ @routine $4A87E8 TCursorGI_Draw }
procedure TCursorGI.Draw(ClipRect: TRect);
begin
  inherited Draw(ClipRect);
end;
{ @end $4A87E8 }

end.

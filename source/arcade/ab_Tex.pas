unit ab_Tex;
// Unit bracket (inferred): CODE 0x004DFC14..0x004E03D7; inclusive evidence, not full bounds.
// Direct3D 8 texture cache. TabTex VMT at $4DFC14 and the native
// startup window $4DFC14..$4E03D8 establish the PACKAGEINFO unit ab_Tex.
interface
uses EC_Struct, GR_DirectX3D8;
type
  TabTex = class(TObjectEx) // @size $20
  public
    Prev: TabTex; // @offset $04
    Next: TabTex; // @offset $08
    ReferenceCount: Integer; // @offset $0C
    ImagePath: WideString; // @offset $10
    Texture: IDirect3DTexture8; // @offset $14
    Pixels: Pointer; // @offset $18 Borrowed from Lock; remains stored after Unlock.
    PitchBytes: Integer; // @offset $1C
    constructor Create; // @addr $4DFC84
    destructor Destroy; override; // @addr $4DFCBC
    procedure Clear; // @addr $4DFCE8
    procedure Lock; // @addr $4DFCFC
    procedure Unlock; // @addr $4DFD50
    procedure AllocateRgba(Width, Height: Integer); // @addr $4DFD5C
    procedure Load(Image: WideString); // @addr $4DFDB8
  end;
function ab_Tex_Add: TabTex; // @addr $4E0294
procedure ab_Tex_Delete(Texture: TabTex); // @addr $4E02D4
function AcquireArcadeTexture(Image: WideString): TabTex; // @addr $4E0318
procedure ReleaseArcadeTexture(Texture: TabTex); // @addr $4E0390
var
  FirstArcadeTexture: TabTex = nil; // @addr $6185D8
  LastArcadeTexture: TabTex = nil; // @addr $6185DC
implementation

// @unit-initialization $4E03D0
// @unit-finalization $4E03A0

uses GR_Main, EC_Cache, EC_CacheGI, GR_gi, Windows;

{ @routine $4DFC84 TabTex_Create }
constructor TabTex.Create;
begin
  inherited Create;
end;
{ @end $4DFC84 }

{ @routine $4DFCBC TabTex_Destroy }
destructor TabTex.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $4DFCBC }

{ @routine $4DFCE8 TabTex_Clear }
procedure TabTex.Clear;
begin
  Texture := nil;
  ReferenceCount := 0;
end;
{ @end $4DFCE8 }

{ @routine $4DFCFC TabTex_Lock }
procedure TabTex.Lock;
var Locked: TD3DLockedRect8;
begin
  if Texture.LockRect(0, Locked, nil, 0) <> 0 then RaiseWideMessage('Tex.Lock');
  Pixels := Locked.Bits;
  PitchBytes := Locked.Pitch;
end;
{ @end $4DFCFC }

{ @routine $4DFD50 TabTex_Unlock }
procedure TabTex.Unlock;
begin
  Texture.UnlockRect(0);
end;
{ @end $4DFD50 }

{ @routine $4DFD5C TabTex_AllocateRgba }
procedure TabTex.AllocateRgba(Width, Height: Integer);
begin
  if Direct3D8Device.CreateTexture(Width, Height, 1, 0, 21, 1, Texture) <> 0 then
    RaiseWideMessage('CreateTexture');
end;
{ @end $4DFD5C }

{ @routine $4DFDB8 TabTex_Load }
procedure TabTex.Load(Image: WideString);
var
  Control: TCGiControlEC;
  CachedImage: TCGiEC;
  Locked: TD3DLockedRect8;
  Width, Height, Pitch, Row, Column: Integer;
  Dest, Source: Pointer;
begin
  Clear;
  ImagePath := Image;
  Control := TCGiControlEC.Create;
  GlobalCache.ResetControl(Control);
  Control.SetCacheKey(Image);
  CachedImage := nil;
  try
    CachedImage := AcquireCachedGi(Control);
    Width := CachedImage.Image.GetContentSize.X;
    Height := CachedImage.Image.GetContentSize.Y;
    if CachedImage.Image.GetFormat <> 0 then RaiseWideMessage('Incorrect format texture 1');
    if (CachedImage.Image.Header.RedMask = $FF0000) and
      (CachedImage.Image.Header.GreenMask = $FF00) and
      (CachedImage.Image.Header.BlueMask = $FF) and
      (CachedImage.Image.Header.AlphaMask = $0) then
    begin
      if Direct3D8Device.CreateTexture(Width, Height, 0, 0, 20, 0, Texture) <> 0 then
        RaiseWideMessage('CreateTexture');
      if Texture.LockRect(0, Locked, nil, 0) <> 0 then RaiseWideMessage('Tex.Lock');
      Dest := Locked.Bits;
      Pitch := Locked.Pitch;
      Source := Pointer(Integer(CachedImage.Image.Data) + CachedImage.Image.GetPlane(0).DataOffset);
      for Row := 0 to Height - 1 do
      begin
        for Column := 0 to Width - 1 do
        begin
          PByte(Integer(Dest) + 0)^ := PByte(Integer(Source) + 0)^;
          PByte(Integer(Dest) + 1)^ := PByte(Integer(Source) + 1)^;
          PByte(Integer(Dest) + 2)^ := PByte(Integer(Source) + 2)^;
          Dest := Pointer(Integer(Dest) + 3);
          Source := Pointer(Integer(Source) + 3);
        end;
        // Native row padding subtracts Height, including for nonsquare images.
        Dest := Pointer(Integer(Dest) + (Pitch - Height * 3));
      end;
      Texture.UnlockRect(0);
    end
    else if (CachedImage.Image.Header.RedMask = $FF0000) and
      (CachedImage.Image.Header.GreenMask = $FF00) and
      (CachedImage.Image.Header.BlueMask = $FF) and
      (CachedImage.Image.Header.AlphaMask = $FF000000) then
    begin
      if Direct3D8Device.CreateTexture(Width, Height, 1, 0, 21, 1, Texture) <> 0 then
        RaiseWideMessage('CreateTexture');
      if Texture.LockRect(0, Locked, nil, 0) <> 0 then RaiseWideMessage('Tex.Lock');
      Dest := Locked.Bits;
      Pitch := Locked.Pitch;
      Source := Pointer(Integer(CachedImage.Image.Data) + CachedImage.Image.GetPlane(0).DataOffset);
      for Row := 0 to Height - 1 do
      begin
        for Column := 0 to Width - 1 do
        begin
          PCardinal(Dest)^ := PCardinal(Source)^;
          Dest := Pointer(Integer(Dest) + 4);
          Source := Pointer(Integer(Source) + 4);
        end;
        // Native row padding subtracts Height, including for nonsquare images.
        Dest := Pointer(Integer(Dest) + (Pitch - Height * 4));
      end;
      Texture.UnlockRect(0);
    end
    else if (CachedImage.Image.Header.RedMask = $F800) and
      (CachedImage.Image.Header.GreenMask = $7E0) and
      (CachedImage.Image.Header.BlueMask = $1F) and
      (CachedImage.Image.Header.AlphaMask = $0) then
    begin
      if Direct3D8Device.CreateTexture(Width, Height, 0, 0, 23, 0, Texture) <> 0 then
        RaiseWideMessage('CreateTexture');
      if Texture.LockRect(0, Locked, nil, 0) <> 0 then RaiseWideMessage('Tex.Lock');
      Dest := Locked.Bits;
      Pitch := Locked.Pitch;
      Source := Pointer(Integer(CachedImage.Image.Data) + CachedImage.Image.GetPlane(0).DataOffset);
      for Row := 0 to Height - 1 do
      begin
        for Column := 0 to Width - 1 do
        begin
          PWord(Dest)^ := PWord(Source)^;
          Dest := Pointer(Integer(Dest) + 2);
          Source := Pointer(Integer(Source) + 2);
        end;
        // Native row padding subtracts Height, including for nonsquare images.
        Dest := Pointer(Integer(Dest) + (Pitch - Height * 2));
      end;
      Texture.UnlockRect(0);
    end
    else RaiseWideMessage('Incorrect format texture 2');
  finally
    if CachedImage <> nil then Control.Release;
    Control.Free;
  end;
end;
{ @end $4DFDB8 }

{ @routine $4E0294 ab_Tex_Add }
function ab_Tex_Add: TabTex;
begin
  Result := TabTex.Create;
  if LastArcadeTexture <> nil then LastArcadeTexture.Next := Result;
  Result.Prev := LastArcadeTexture;
  Result.Next := nil;
  LastArcadeTexture := Result;
  if FirstArcadeTexture = nil then FirstArcadeTexture := Result;
end;
{ @end $4E0294 }

{ @routine $4E02D4 ab_Tex_Delete }
procedure ab_Tex_Delete(Texture: TabTex);
begin
  if Texture.Prev <> nil then Texture.Prev.Next := Texture.Next;
  if Texture.Next <> nil then Texture.Next.Prev := Texture.Prev;
  if Texture = LastArcadeTexture then LastArcadeTexture := Texture.Prev;
  if Texture = FirstArcadeTexture then FirstArcadeTexture := Texture.Next;
  Texture.Free;
end;
{ @end $4E02D4 }

{ @routine $4E0318 AcquireArcadeTexture }
function AcquireArcadeTexture(Image: WideString): TabTex;
begin
  Result := FirstArcadeTexture;
  while Result <> nil do
  begin
    if Result.ImagePath = Image then
    begin
      Inc(Result.ReferenceCount);
      Exit;
    end;
    Result := Result.Next;
  end;
  Result := ab_Tex_Add;
  Result.Load(Image);
  Inc(Result.ReferenceCount);
end;
{ @end $4E0318 }

{ @routine $4E0390 ReleaseArcadeTexture }
procedure ReleaseArcadeTexture(Texture: TabTex);
begin
  Dec(Texture.ReferenceCount);
  if Texture.ReferenceCount <= 0 then ab_Tex_Delete(Texture);
end;
{ @end $4E0390 }

end.

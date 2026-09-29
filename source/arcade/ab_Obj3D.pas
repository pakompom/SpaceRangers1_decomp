unit ab_Obj3D;
// Unit bracket (inferred): CODE 0x004E03DC..0x004E0B0F; inclusive evidence, not full bounds.
// Auxiliary Direct3D objects. Arena cleanup releases this shared list.
interface
uses EC_Struct, GR_DirectX3D8, ab_Tex;
type
  PabVertex3D = ^TabVertex3D;
  TabVertex3D = packed record // @size $1C
    X: Single; // @offset $00
    Y: Single; // @offset $04
    Z: Single; // @offset $08
    RHW: Single; // @offset $0C
    Color: Cardinal; // @offset $10
    U: Single; // @offset $14
    V: Single; // @offset $18
  end;
  PabIndexBatch3D = ^TabIndexBatch3D;
  TabIndexBatch3D = record // @size $20
    Prev: PabIndexBatch3D; // @offset $00
    Next: PabIndexBatch3D; // @offset $04
    IndexCount: Integer; // @offset $08
    Indices: array of Integer; // @offset $0C Native upload truncates each index to Word.
    StartIndex: Integer; // @offset $10
    PrimitiveType: Integer; // @offset $14
    PrimitiveCount: Integer; // @offset $18
    Texture: TabTex; // @offset $1C Shared reference.
  end;
  TabObj3D = class(TObjectEx) // @size $2C
  public
    Prev: TabObj3D; // @offset $04
    Next: TabObj3D; // @offset $08
    VertexBuffer: IDirect3DVertexBuffer8; // @offset $0C
    VertexCount: Integer; // @offset $10
    VertexData: PabVertex3D; // @offset $14
    LockCount: Integer; // @offset $18
    FirstBatch: PabIndexBatch3D; // @offset $1C
    LastBatch: PabIndexBatch3D; // @offset $20
    IndexBuffer: IDirect3DIndexBuffer8; // @offset $24
    IndicesDirty: Boolean; // @offset $28
    Visible: Boolean; // @offset $29
    constructor Create; // @addr $4E0490
    destructor Destroy; override; // @addr $4E04CC
    procedure ClearVertexBuffer; // @addr $4E0508
    procedure AllocateVertices(Count: Integer); // @addr $4E0524
    procedure LockVertices; // @addr $4E05A4
    procedure UnlockVertices; // @addr $4E05F8 @note "An unmatched unlock at zero decrements LockCount to -1."
    function AddIndexBatch(PrimitiveType, IndexCount: Integer; Image: WideString): PabIndexBatch3D; // @addr $4E06C0
    procedure UploadIndices; // @addr $4E0764
    function GetVertex(Index: Integer): PabVertex3D; // @addr $4E0614
    procedure ClearBatches; // @addr $4E0620
    function AddBatch: PabIndexBatch3D; // @addr $4E0638
    procedure DeleteBatch(Batch: PabIndexBatch3D); // @addr $4E0668
    procedure ClearIndexBuffer; // @addr $4E0754
    procedure Draw; // @addr $4E08A8
  end;
function MakeArcadeVertex3D(Color: Cardinal; X, Y, Z, U, V: Single): TabVertex3D; // @addr $4E09E8
procedure ab_Obj3D_Clear; // @addr $4E0A18
function ab_Obj3D_Add: TabObj3D; // @addr $4E0A30
procedure ab_Obj3D_Delete(Obj: TabObj3D); // @addr $4E0A70
procedure ab_Obj3D_Draw; // @addr $4E0AB4
var
  FirstArcadeObject3D: TabObj3D = nil; // @addr $6185E0
  LastArcadeObject3D: TabObj3D = nil; // @addr $6185E4
implementation

// @unit-initialization $4E0B08
// @unit-finalization $4E0AD8

uses EC_Mem, GR_Main, Windows;

{ @routine $4E0490 TabObj3D_Create }
constructor TabObj3D.Create;
begin
  inherited Create;
  Visible := True;
end;
{ @end $4E0490 }

{ @routine $4E04CC TabObj3D_Destroy }
destructor TabObj3D.Destroy;
begin
  ClearBatches;
  ClearIndexBuffer;
  ClearVertexBuffer;
  inherited Destroy;
end;
{ @end $4E04CC }

{ @routine $4E0508 TabObj3D_ClearVertexBuffer }
procedure TabObj3D.ClearVertexBuffer;
begin
  VertexBuffer := nil;
  VertexCount := 0;
  LockCount := 0;
  VertexData := nil;
end;
{ @end $4E0508 }

{ @routine $4E0524 TabObj3D_AllocateVertices }
procedure TabObj3D.AllocateVertices(Count: Integer);
begin
  if VertexBuffer = nil then
    if Direct3D8Device.CreateVertexBuffer(Count * SizeOf(TabVertex3D), 0, $144, 0, VertexBuffer) <> 0 then
      RaiseWideMessage('TabObj3D.CreateVertexBuffer');
  VertexCount := Count;
end;
{ @end $4E0524 }

{ @routine $4E05A4 TabObj3D_LockVertices }
procedure TabObj3D.LockVertices;
begin
  if LockCount = 0 then
    if VertexBuffer.Lock(0, VertexCount * SizeOf(TabVertex3D), PByte(VertexData), 0) <> 0 then
      RaiseWideMessage('TabObj3D.Lock');
  Inc(LockCount);
end;
{ @end $4E05A4 }

{ @routine $4E05F8 TabObj3D_UnlockVertices }
procedure TabObj3D.UnlockVertices;
begin
  if LockCount >= 0 then
  begin
    Dec(LockCount);
    if LockCount = 0 then VertexBuffer.Unlock;
  end;
end;
{ @end $4E05F8 }

{ @routine $4E0614 TabObj3D_GetVertex }
function TabObj3D.GetVertex(Index: Integer): PabVertex3D;
begin
  Result := Pointer(PAnsiChar(VertexData) + Index * SizeOf(TabVertex3D));
end;
{ @end $4E0614 }

{ @routine $4E0620 TabObj3D_ClearBatches }
procedure TabObj3D.ClearBatches;
begin
  while FirstBatch <> nil do DeleteBatch(LastBatch);
end;
{ @end $4E0620 }

{ @routine $4E0638 TabObj3D_AddBatch }
function TabObj3D.AddBatch: PabIndexBatch3D;
begin
  Result := AllocClearEC(SizeOf(TabIndexBatch3D));
  if LastBatch <> nil then LastBatch.Next := Result;
  Result.Prev := LastBatch;
  Result.Next := nil;
  LastBatch := Result;
  if FirstBatch = nil then FirstBatch := Result;
end;
{ @end $4E0638 }

{ @routine $4E0668 TabObj3D_DeleteBatch }
procedure TabObj3D.DeleteBatch(Batch: PabIndexBatch3D);
begin
  if Batch.Prev <> nil then Batch.Prev.Next := Batch.Next;
  if Batch.Next <> nil then Batch.Next.Prev := Batch.Prev;
  if Batch = LastBatch then LastBatch := Batch.Prev;
  if Batch = FirstBatch then FirstBatch := Batch.Next;
  Batch.Indices := nil;
  if Batch.Texture <> nil then
  begin
    ReleaseArcadeTexture(Batch.Texture);
    Batch.Texture := nil;
  end;
  FreeEC(Batch);
end;
{ @end $4E0668 }

{ @routine $4E06C0 TabObj3D_AddIndexBatch }
function TabObj3D.AddIndexBatch(PrimitiveType, IndexCount: Integer; Image: WideString): PabIndexBatch3D;
begin
  Result := AddBatch;
  SetLength(Result.Indices, IndexCount);
  Result.PrimitiveType := PrimitiveType;
  Result.IndexCount := IndexCount;
  Result.PrimitiveCount := 0;
  if Image <> '' then Result.Texture := AcquireArcadeTexture(Image);
  IndicesDirty := True;
end;
{ @end $4E06C0 }

{ @routine $4E0754 TabObj3D_ClearIndexBuffer }
procedure TabObj3D.ClearIndexBuffer;
begin
  IndexBuffer := nil;
end;
{ @end $4E0754 }

{ @routine $4E0764 TabObj3D_UploadIndices }
procedure TabObj3D.UploadIndices;
var
  Dest: Pointer;
  Count, Index, StartIndex: Integer;
  Batch: PabIndexBatch3D;
begin
  ClearIndexBuffer;
  Count := 0;
  Batch := FirstBatch;
  while Batch <> nil do
  begin
    Inc(Count, Batch.IndexCount);
    Batch := Batch.Next;
  end;
  if Count <= 0 then Exit;
  if Direct3D8Device.CreateIndexBuffer(Count * 2, 8, 101, 1, IndexBuffer) <> 0 then
    RaiseWideMessage('TabObj3D CreateIndexBuffer');
  if IndexBuffer.Lock(0, Count * 2, PByte(Dest), 0) <> 0 then RaiseWideMessage('TabObj3D Index.Look');
  StartIndex := 0;
  Batch := FirstBatch;
  while Batch <> nil do
  begin
    Batch.StartIndex := StartIndex;
    for Index := 0 to Batch.IndexCount - 1 do
    begin
      PWord(Dest)^ := Word(Batch.Indices[Index]);
      Inc(StartIndex);
      Dest := Pointer(Cardinal(Dest) + 2);
    end;
    Batch := Batch.Next;
  end;
  IndexBuffer.Unlock;
  IndicesDirty := False;
end;
{ @end $4E0764 }

{ @routine $4E08A8 TabObj3D_Draw }
procedure TabObj3D.Draw;
var Batch: PabIndexBatch3D;
begin
  if IndicesDirty then UploadIndices;
  if (VertexBuffer <> nil) and (IndexBuffer <> nil) then
  begin
    Direct3D8Device.SetStreamSource(0, VertexBuffer, SizeOf(TabVertex3D));
    Direct3D8Device.SetIndices(IndexBuffer, 0);
    Direct3D8Device.SetVertexShader($144);
    Batch := FirstBatch;
    while Batch <> nil do
    begin
      if Batch.Texture <> nil then
      begin
        Direct3D8Device.SetTexture(0, Batch.Texture.Texture);
        Direct3D8Device.SetTextureStageState(0, 1, 2);
        Direct3D8Device.SetTextureStageState(0, 2, 2);
        Direct3D8Device.SetTextureStageState(0, 4, 4);
        Direct3D8Device.SetTextureStageState(0, 5, 2);
        Direct3D8Device.SetTextureStageState(0, 6, 0);
      end
      else Direct3D8Device.SetTexture(0, nil);
      // Native passes NumVertices=1 even for batches referencing several vertices.
      if Direct3D8Device.DrawIndexedPrimitive(Batch.PrimitiveType, 0, 1, Batch.StartIndex, Batch.PrimitiveCount) <> 0 then
        RaiseWideMessage('TabObj3D Draw');
      Batch := Batch.Next;
    end;
  end;
end;
{ @end $4E08A8 }

{ @routine $4E09E8 MakeArcadeVertex3D }
function MakeArcadeVertex3D(Color: Cardinal; X, Y, Z, U, V: Single): TabVertex3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.RHW := 1;
  Result.U := U;
  Result.V := V;
  Result.Color := Color;
end;
{ @end $4E09E8 }

{ @routine $4E0A18 ab_Obj3D_Clear }
procedure ab_Obj3D_Clear;
begin
  while FirstArcadeObject3D <> nil do ab_Obj3D_Delete(LastArcadeObject3D);
end;
{ @end $4E0A18 }

{ @routine $4E0A30 ab_Obj3D_Add }
function ab_Obj3D_Add: TabObj3D;
begin
  Result := TabObj3D.Create;
  if LastArcadeObject3D <> nil then LastArcadeObject3D.Next := Result;
  Result.Prev := LastArcadeObject3D;
  Result.Next := nil;
  LastArcadeObject3D := Result;
  if FirstArcadeObject3D = nil then FirstArcadeObject3D := Result;
end;
{ @end $4E0A30 }

{ @routine $4E0A70 ab_Obj3D_Delete }
procedure ab_Obj3D_Delete(Obj: TabObj3D);
begin
  if Obj.Prev <> nil then Obj.Prev.Next := Obj.Next;
  if Obj.Next <> nil then Obj.Next.Prev := Obj.Prev;
  if Obj = LastArcadeObject3D then LastArcadeObject3D := Obj.Prev;
  if Obj = FirstArcadeObject3D then FirstArcadeObject3D := Obj.Next;
  Obj.Free;
end;
{ @end $4E0A70 }

{ @routine $4E0AB4 ab_Obj3D_Draw }
procedure ab_Obj3D_Draw;
var Obj: TabObj3D;
begin
  Obj := FirstArcadeObject3D;
  while Obj <> nil do
  begin
    if Obj.Visible then Obj.Draw;
    Obj := Obj.Next;
  end;
end;
{ @end $4E0AB4 }

end.

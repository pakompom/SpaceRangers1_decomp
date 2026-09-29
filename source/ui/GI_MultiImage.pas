unit GI_MultiImage;
// Unit bracket (inferred): CODE 0x00481748..0x004824AF; inclusive evidence, not full bounds.

interface

uses GI_MessageLoop, EC_CacheGI, EC_BlockPar, Classes, Types;

type
  TMultiImageUnitGI = class;
  TMultiImageColGI = class;
  TMultiImageRowGI = class;

  TMultiImageUnitGI = class(TObject) // @size $28
  public
    Prev: TMultiImageUnitGI; // @offset $04
    Next: TMultiImageUnitGI; // @offset $08
    PrevInColumn: TMultiImageUnitGI; // @offset $0C
    NextInColumn: TMultiImageUnitGI; // @offset $10
    Column: TMultiImageColGI; // @offset $14
    ImageIndex: Integer; // @offset $18
    Position: TPoint; // @offset $1C
    UserData: Pointer; // @offset $24 Borrowed application data; TfAB stores a path-node pointer.
  end;

  TMultiImageColGI = class(TObject) // @size $1C
  public
    Prev: TMultiImageColGI; // @offset $04
    Next: TMultiImageColGI; // @offset $08
    First: TMultiImageUnitGI; // @offset $0C
    Last: TMultiImageUnitGI; // @offset $10
    Row: TMultiImageRowGI; // @offset $14
    Index: Integer; // @offset $18
  end;

  TMultiImageRowGI = class(TObject) // @size $18
  public
    Prev: TMultiImageRowGI; // @offset $04
    Next: TMultiImageRowGI; // @offset $08
    First: TMultiImageColGI; // @offset $0C
    Last: TMultiImageColGI; // @offset $10
    Index: Integer; // @offset $14
  end;

  TMultiImageImageGI = class(TObject) // @size $18
  public
    ImageCache: TCGiControlEC; // @offset $04
    Bounds: TRect; // @offset $08
    constructor Create; // @addr $4819DC
    destructor Destroy; override; // @addr $481A34
    procedure SetImage(Path: WideString); // @addr $481A68
  end;

  TMultiImageGI = class(TObjectGI) // @size $118
  public
    FirstUnit: TMultiImageUnitGI; // @offset $100
    LastUnit: TMultiImageUnitGI; // @offset $104
    FirstRow: TMultiImageRowGI; // @offset $108
    LastRow: TMultiImageRowGI; // @offset $10C
    CellSize: Integer; // @offset $110
    Images: TList; // @offset $114
    constructor Create(Owner: TObjectGI); // @addr $481B58
    destructor Destroy; override; // @addr $481BAC
    procedure Clear; override; // @addr $481BF4
    function AddUnit: TMultiImageUnitGI; // @addr $481C10
    procedure RemoveUnit(Item: TMultiImageUnitGI); // @addr $481C54
    procedure ClearUnits; // @addr $481CAC
    procedure UnlinkUnitFromColumn(Item: TMultiImageUnitGI); // @addr $481CD0 @note "Prunes empty columns and rows."
    procedure ClearSpatialIndex; // @addr $481DB4 @note "Preserves units and clears their spatial links."
    function GetOrCreateRow(Index: Integer): TMultiImageRowGI; // @addr $481E20
    function GetOrCreateColumn(Row: TMultiImageRowGI; Index: Integer): TMultiImageColGI; // @addr $481EB4
    procedure SetUnitPosition(Item: TMultiImageUnitGI; Position: TPoint); // @addr $481F34 @note "Native early-out compares the control's Position, not the item's old position. CellSize must be nonzero."
    procedure ClearImages; // @addr $481FD0
    function AddImage(Path: WideString): Integer; // @addr $482010
    procedure LoadFromConfigPath(const Path: WideString); override; // @addr $482088
    procedure LoadFromBlock(Block: TBlockParEC); override; // @addr $4820B4
    procedure LoadImageProperties(Block: TBlockParEC); // @addr $4820D0 @note "Empty in native code."
    procedure Invalidate; override; // @addr $4820D4
    procedure Draw(ClipRect: TRect); override; // @addr $482240
    procedure QueueImageLoad(PendingLoads: TList); override; // @addr $48243C
  end;

implementation

// @unit-initialization $4824A8
// @unit-finalization $482478

uses EC_Cache, EC_Struct, GR_Main;

{ @routine $4819DC TMultiImageImageGI_Create }
constructor TMultiImageImageGI.Create;
begin
  inherited Create;
  ImageCache := TCGiControlEC.Create;
  GlobalCache.ResetControl(ImageCache);
end;
{ @end $4819DC }

{ @routine $481A34 TMultiImageImageGI_Destroy }
destructor TMultiImageImageGI.Destroy;
begin
  ImageCache.Free;
  ImageCache := nil;
  inherited Destroy;
end;
{ @end $481A34 }

{ @routine $481A68 TMultiImageImageGI_SetImage }
procedure TMultiImageImageGI.SetImage(Path: WideString);
var Data: TCGiEC; Size: TPoint;
begin
  if ImageCache.CacheKey <> Path then
  begin
    ImageCache.SetCacheKey(Path);
    Data := AcquireCachedGi(ImageCache);
    try
      Size := Data.Image.GetContentSize;
    finally
      ImageCache.Release;
    end;
    Bounds.Left := -Size.X div 2;
    Bounds.Top := -Size.Y div 2;
    Bounds.Right := Bounds.Left + Size.X;
    Bounds.Bottom := Bounds.Top + Size.Y;
  end;
end;
{ @end $481A68 }

{ @routine $481B58 TMultiImageGI_Create }
constructor TMultiImageGI.Create(Owner: TObjectGI);
begin
  inherited Create(Owner);
  Images := TList.Create;
  CellSize := 128;
end;
{ @end $481B58 }

{ @routine $481BAC TMultiImageGI_Destroy }
destructor TMultiImageGI.Destroy;
begin
  ClearImages;
  ClearUnits;
  Images.Free;
  Images := nil;
  inherited Destroy;
end;
{ @end $481BAC }

{ @routine $481BF4 TMultiImageGI_Clear }
procedure TMultiImageGI.Clear;
begin
  ClearImages;
  ClearUnits;
  inherited Clear;
end;
{ @end $481BF4 }

{ @routine $481C10 TMultiImageGI_AddUnit }
function TMultiImageGI.AddUnit: TMultiImageUnitGI;
var Item: TMultiImageUnitGI;
begin
  Item := TMultiImageUnitGI.Create;
  if LastUnit <> nil then LastUnit.Next := Item;
  Item.Prev := LastUnit;
  Item.Next := nil;
  LastUnit := Item;
  if FirstUnit = nil then FirstUnit := Item;
  Result := Item;
end;
{ @end $481C10 }

{ @routine $481C54 TMultiImageGI_RemoveUnit }
procedure TMultiImageGI.RemoveUnit(Item: TMultiImageUnitGI);
begin
  UnlinkUnitFromColumn(Item);
  if Item.Prev <> nil then Item.Prev.Next := Item.Next;
  if Item.Next <> nil then Item.Next.Prev := Item.Prev;
  if LastUnit = Item then LastUnit := Item.Prev;
  if FirstUnit = Item then FirstUnit := Item.Next;
  Item.Free;
end;
{ @end $481C54 }

{ @routine $481CAC TMultiImageGI_ClearUnits }
procedure TMultiImageGI.ClearUnits;
begin
  ClearSpatialIndex;
  while FirstUnit <> nil do RemoveUnit(LastUnit);
end;
{ @end $481CAC }

{ @routine $481CD0 TMultiImageGI_UnlinkUnitFromColumn }
procedure TMultiImageGI.UnlinkUnitFromColumn(Item: TMultiImageUnitGI);
var Column: TMultiImageColGI; Row: TMultiImageRowGI;
begin
  if Item.Column <> nil then
  begin
    Column := Item.Column;
    if Item.PrevInColumn <> nil then Item.PrevInColumn.NextInColumn := Item.NextInColumn;
    if Item.NextInColumn <> nil then Item.NextInColumn.PrevInColumn := Item.PrevInColumn;
    if Column.Last = Item then Column.Last := Item.PrevInColumn;
    if Column.First = Item then Column.First := Item.NextInColumn;
    Item.PrevInColumn := nil;
    Item.NextInColumn := nil;
    if Column.Last <> nil then begin Item.Column := nil; Exit; end
    else
    begin
      Row := Item.Column.Row;
      Item.Column := nil;
      if Column.Prev <> nil then Column.Prev.Next := Column.Next;
      if Column.Next <> nil then Column.Next.Prev := Column.Prev;
      if Row.Last = Column then Row.Last := Column.Prev;
      if Row.First = Column then Row.First := Column.Next;
      Column.Free;
      if Row.Last = nil then
      begin
        if Row.Prev <> nil then Row.Prev.Next := Row.Next;
        if Row.Next <> nil then Row.Next.Prev := Row.Prev;
        if LastRow = Row then LastRow := Row.Prev;
        if FirstRow = Row then FirstRow := Row.Next;
        Row.Free;
      end;
    end;
  end;
end;
{ @end $481CD0 }

{ @routine $481DB4 TMultiImageGI_ClearSpatialIndex }
procedure TMultiImageGI.ClearSpatialIndex;
var Row, OldRow: TMultiImageRowGI; Column, OldColumn: TMultiImageColGI; Item: TMultiImageUnitGI;
begin
  Row := FirstRow;
  while Row <> nil do
  begin
    OldRow := Row;
    Row := Row.Next;
    Column := OldRow.First;
    while Column <> nil do
    begin
      OldColumn := Column;
      Column := Column.Next;
      OldColumn.Free;
    end;
    OldRow.Free;
  end;
  FirstRow := nil;
  LastRow := nil;
  Item := FirstUnit;
  while Item <> nil do
  begin
    Item.Column := nil;
    Item.PrevInColumn := nil;
    Item.NextInColumn := nil;
    Item := Item.Next;
  end;
end;
{ @end $481DB4 }

{ @routine $481E20 TMultiImageGI_GetOrCreateRow }
function TMultiImageGI.GetOrCreateRow(Index: Integer): TMultiImageRowGI;
var Row: TMultiImageRowGI;
begin
  Row := FirstRow;
  while Row <> nil do
  begin
    if Row.Index = Index then
    begin
      Result := Row;
      Exit;
    end;
    if Row.Index > Index then Break;
    Row := Row.Next;
  end;
  Result := TMultiImageRowGI.Create;
  Result.Index := Index;
  if Row = nil then
  begin
    if LastRow <> nil then LastRow.Next := Result;
    Result.Prev := LastRow;
    Result.Next := nil;
    LastRow := Result;
    if FirstRow = nil then FirstRow := Result;
  end
  else
  begin
    Result.Prev := Row.Prev;
    Result.Next := Row;
    if Row.Prev <> nil then Row.Prev.Next := Result;
    Row.Prev := Result;
    if FirstRow = Row then FirstRow := Result;
  end;
end;
{ @end $481E20 }

{ @routine $481EB4 TMultiImageGI_GetOrCreateColumn }
function TMultiImageGI.GetOrCreateColumn(Row: TMultiImageRowGI; Index: Integer): TMultiImageColGI;
var Column: TMultiImageColGI;
begin
  Column := Row.First;
  while Column <> nil do
  begin
    if Column.Index = Index then
    begin
      Result := Column;
      Exit;
    end;
    if Column.Index > Index then Break;
    Column := Column.Next;
  end;
  Result := TMultiImageColGI.Create;
  Result.Row := Row;
  Result.Index := Index;
  if Column = nil then
  begin
    if Row.Last <> nil then Row.Last.Next := Result;
    Result.Prev := Row.Last;
    Result.Next := nil;
    Row.Last := Result;
    if Row.First = nil then Row.First := Result;
  end
  else
  begin
    Result.Prev := Column.Prev;
    Result.Next := Column;
    if Column.Prev <> nil then Column.Prev.Next := Result;
    Column.Prev := Result;
    if Row.First = Column then Row.First := Result;
  end;
end;
{ @end $481EB4 }

{ @routine $481F34 TMultiImageGI_SetUnitPosition }
procedure TMultiImageGI.SetUnitPosition(Item: TMultiImageUnitGI; Position: TPoint);
var Column: TMultiImageColGI;
begin
  if not ((Item.Column = nil) or (Self.LocalPosition.X <> Position.X) or
    (Self.LocalPosition.Y <> Position.Y)) then Exit;
  Item.Position := Position;
  Column := GetOrCreateColumn(GetOrCreateRow(Position.Y div Self.CellSize), Position.X div Self.CellSize);
  if Item.Column = Column then Exit;
  UnlinkUnitFromColumn(Item);
  Item.Column := Column;
  if Column.Last <> nil then Column.Last.NextInColumn := Item;
  Item.PrevInColumn := Column.Last;
  Item.NextInColumn := nil;
  Column.Last := Item;
  if Column.First = nil then Column.First := Item;
end;
{ @end $481F34 }

{ @routine $481FD0 TMultiImageGI_ClearImages }
procedure TMultiImageGI.ClearImages;
var Image: TMultiImageImageGI; I: Integer;
begin
  if Images <> nil then
  begin
    for I := 0 to Images.Count - 1 do
    begin
      Image := TMultiImageImageGI(Images[I]);
      Image.Free;
    end;
    Images.Clear;
  end;
end;
{ @end $481FD0 }

{ @routine $482010 TMultiImageGI_AddImage }
function TMultiImageGI.AddImage(Path: WideString): Integer;
var Image: TMultiImageImageGI;
begin
  Image := TMultiImageImageGI.Create;
  Image.SetImage(Path);
  Images.Add(Image);
  Result := Images.Count - 1;
end;
{ @end $482010 }

{ @routine $482088 TMultiImageGI_LoadFromConfigPath }
procedure TMultiImageGI.LoadFromConfigPath(const Path: WideString);
begin
  inherited LoadFromConfigPath(Path);
  LoadImageProperties(UiStyleConfig.GetBlockByPath(Path));
end;
{ @end $482088 }

{ @routine $4820B4 TMultiImageGI_LoadFromBlock }
procedure TMultiImageGI.LoadFromBlock(Block: TBlockParEC);
begin
  inherited LoadFromBlock(Block);
  LoadImageProperties(Block);
end;
{ @end $4820B4 }

{ @routine $4820D0 TMultiImageGI_LoadImageProperties }
procedure TMultiImageGI.LoadImageProperties(Block: TBlockParEC);
begin
end;
{ @end $4820D0 }

{ @routine $4820D4 TMultiImageGI_Invalidate }
procedure TMultiImageGI.Invalidate;
var
  MinColumn, MaxColumn, MinRow, MaxRow, Size: Integer;
  Row: TMultiImageRowGI;
  Column: TMultiImageColGI;
  Item: TMultiImageUnitGI;
  Position: TPoint;
  Image: TMultiImageImageGI;
  ScreenBounds: TRect;
begin
  if not MessageLoop.UpdateRectsEnabled then Exit;
  if not Active then Exit;
  if IntersectRects(ScreenBounds, HitTestBounds, GameScreenRect) then
  begin
    Dec(ScreenBounds.Left, AbsolutePosition.X);
    Dec(ScreenBounds.Top, AbsolutePosition.Y);
    Dec(ScreenBounds.Right, AbsolutePosition.X);
    Dec(ScreenBounds.Bottom, AbsolutePosition.Y);
    Size := CellSize;
    MinColumn := ScreenBounds.Left div Size - 1;
    MaxColumn := (ScreenBounds.Right - 1) div Size + 1;
    MinRow := ScreenBounds.Top div Size - 1;
    MaxRow := (ScreenBounds.Bottom - 1) div Size + 1;
    Row := FirstRow;
    while Row <> nil do
    begin
      if (Row.Index >= MinRow) and (Row.Index <= MaxRow) then
      begin
        Column := Row.First;
        while Column <> nil do
        begin
          if (Column.Index >= MinColumn) and (Column.Index <= MaxColumn) then
          begin
            Item := Column.First;
            while Item <> nil do
            begin
              Position.X := AbsolutePosition.X + Item.Position.X;
              Position.Y := AbsolutePosition.Y + Item.Position.Y;
              Image := TMultiImageImageGI(Images[Item.ImageIndex]);
              with Image do
              begin
                ScreenBounds.Left := Position.X + Bounds.Left;
                ScreenBounds.Top := Position.Y + Bounds.Top;
                ScreenBounds.Right := Position.X + Bounds.Right;
                ScreenBounds.Bottom := Position.Y + Bounds.Bottom;
              end;
              MessageLoop.QueueUpdateRect(ScreenBounds);
              Item := Item.NextInColumn;
            end;
          end
          else if Column.Index > MaxColumn then Break;
          Column := Column.Next;
        end;
      end
      else if Row.Index > MaxRow then Break;
      Row := Row.Next;
    end;
  end;
end;
{ @end $4820D4 }

{ @routine $482240 TMultiImageGI_Draw }
procedure TMultiImageGI.Draw(ClipRect: TRect);
var
  Row: TMultiImageRowGI;
  Column: TMultiImageColGI;
  Item: TMultiImageUnitGI;
  MinColumn, MaxColumn, MinRow, MaxRow: Integer;
  Position: TPoint;
  Image: TMultiImageImageGI;
  Data: TCGiEC;
  Bounds, Intersection: TRect;
begin
  Bounds.Left := ClipRect.Left - AbsolutePosition.X;
  Bounds.Top := ClipRect.Top - AbsolutePosition.Y;
  Bounds.Right := ClipRect.Right - AbsolutePosition.X;
  Bounds.Bottom := ClipRect.Bottom - AbsolutePosition.Y;
  MinColumn := Bounds.Left div CellSize - 1;
  MaxColumn := (Bounds.Right - 1) div CellSize + 1;
  MinRow := Bounds.Top div CellSize - 1;
  MaxRow := (Bounds.Bottom - 1) div CellSize + 1;
  Row := FirstRow;
  while Row <> nil do
  begin
    if (Row.Index >= MinRow) and (Row.Index <= MaxRow) then
    begin
      Column := Row.First;
      while Column <> nil do
      begin
        if (Column.Index >= MinColumn) and (Column.Index <= MaxColumn) then
        begin
          Item := Column.First;
          while Item <> nil do
          begin
            Position.X := AbsolutePosition.X + Item.Position.X;
            Position.Y := AbsolutePosition.Y + Item.Position.Y;
            Image := TMultiImageImageGI(Images[Item.ImageIndex]);
            Bounds.Left := Image.Bounds.Left + Position.X;
            Bounds.Top := Image.Bounds.Top + Position.Y;
            Bounds.Right := Image.Bounds.Right + Position.X;
            Bounds.Bottom := Image.Bounds.Bottom + Position.Y;
            if IntersectRects(Intersection, Bounds, ClipRect) then
            begin
              Data := AcquireCachedGi(Image.ImageCache);
              try

                  Data.Image.DrawToGraphBuf(ScreenRenderBuffer, Bounds.Left, Bounds.Top, ClipRect, 0);
              finally
                Image.ImageCache.Release;
              end;
            end;
            Item := Item.NextInColumn;
          end;
        end
        else if Column.Index > MaxColumn then Break;
        Column := Column.Next;
      end;
    end
    else if Row.Index > MaxRow then Break;
    Row := Row.Next;
  end;
end;
{ @end $482240 }
{ @routine $48243C TMultiImageGI_QueueImageLoad }
procedure TMultiImageGI.QueueImageLoad(PendingLoads: TList);
var Image: TMultiImageImageGI; I: Integer;
begin
  for I := 0 to Images.Count - 1 do
  begin
    Image := TMultiImageImageGI(Images[I]);
    Image.ImageCache.QueueLoadIfMissing(PendingLoads);
  end;
end;
{ @end $48243C }
end.

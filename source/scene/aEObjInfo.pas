unit aEObjInfo;
// Unit bracket (inferred): CODE 0x0056440C..0x00565703; inclusive evidence, not full bounds.

interface

uses EC_Struct, EC_Buf, aGalaxy;

type
  PEPlanetInfo = ^TEOTPlanet;
  TEOTPlanet = record // @size $14
    Id: Cardinal; // @offset $00
    Name: WideString; // @offset $04
    OwnerId: TOwnerId; // @offset $08
    RaceId: TRaceId; // @offset $09
    Population: Integer; // @offset $0C
    Economy: TPlanetEconomy; // @offset $10
    Government: TPlanetGovernment; // @offset $11
    Relation: TRelationLevel; // @offset $12
  end;
  PEShipInfo = ^TEOTShip;
  TEOTShip = record // @size $30
    Id: Cardinal; // @offset $00
    Name: WideString; // @offset $04
    FullName: WideString; // @offset $08
    OwnerId: TOwnerId; // @offset $0C
    TypeName: WideString; // @offset $10
    Speed: Integer; // @offset $14
    HullCapacity: Integer; // @offset $18
    HullPoints: Integer; // @offset $1C
    DefenseText: WideString; // @offset $20
    Relation: TRelationLevel; // @offset $24
    WinChance: Integer; // @offset $28
    PortraitImage: WideString; // @offset $2C
  end;
  PEItemInfo = ^TEOTItem;
  TEOTItem = record // @size $28
    Id: Cardinal; // @offset $00
    Name: WideString; // @offset $04
    ImagePath: WideString; // @offset $08
    ItemType: TItemType; // @offset $0C
    InfoText: WideString; // @offset $10
    Weight: Integer; // @offset $14
    Cost: Integer; // @offset $18
    OwnerId: TOwnerId; // @offset $1C
    ConditionPercent: Double; // @offset $20
  end;
  PEAsteroidInfo = ^TEOTAsteroid;
  TEOTAsteroid = record // @size $0C
    Id: Cardinal; // @offset $00
    Name: WideString; // @offset $04
    InfoText: WideString; // @offset $08
  end;
  TEObjInfo = class(TObjectEx) // @size $1C
  public
    StarName: WideString; // @offset $04
    StarRadius: Integer; // @offset $08
    Planets: array of TEOTPlanet; // @offset $0C
    Ships: array of TEOTShip; // @offset $10
    Items: array of TEOTItem; // @offset $14
    Asteroids: array of TEOTAsteroid; // @offset $18

    constructor Create; // @addr $564520
    destructor Destroy; override; // @addr $564558
    procedure LoadFromStar(Star: TStar); // @addr $5645D0
    procedure Clear; // @addr $564584
    function FindPlanet(ObjectId: Cardinal): PEPlanetInfo; // @addr $564F1C Borrowed pointer into the snapshot array.
    function FindItem(ObjectId: Cardinal): PEItemInfo; // @addr $564F90 Borrowed pointer into the snapshot array.
    function FindShip(ObjectId: Cardinal): PEShipInfo; // @addr $564F54 Borrowed pointer into the snapshot array.
    function FindAsteroid(ObjectId: Cardinal): PEAsteroidInfo; // @addr $564FC8 Borrowed pointer into the snapshot array.
    procedure SaveToBuffer(Buffer: TBufEC); // @addr $565000 Appends the current snapshot; doubles are serialized as singles.
    procedure LoadFromBuffer(Buffer: TBufEC); // @addr $5652B0
  end;

implementation

// @unit-initialization $5656FC
// @unit-finalization $5656CC

uses SysUtils, aPlanet, aShip, aRanger, aRuins, aItem, aAsteroid, aConst, Globals, aMyFunction, GR_Main, EC_Str;

{ @routine $564520 TEObjInfo_Create }
constructor TEObjInfo.Create;
begin
  inherited Create;
end;
{ @end $564520 }

{ @routine $564558 TEObjInfo_Destroy }
destructor TEObjInfo.Destroy;
begin
  Clear;
  inherited Destroy;
end;
{ @end $564558 }

{ @routine $564584 TEObjInfo_Clear }
procedure TEObjInfo.Clear;
begin
  StarName := '';
  StarRadius := 0;
  Planets := nil;
  Ships := nil;
  Items := nil;
  Asteroids := nil;
end;
{ @end $564584 }

{ @routine $5645D0 TEObjInfo_LoadFromStar }
procedure TEObjInfo.LoadFromStar(Star: TStar);
var
  Index: Integer;
  Planet: TPlanet;
  Ship: TShip;
  Item: TItem;
  Asteroid: TAsteroid;
begin
  StarName := Star.Name;
  StarRadius := Star.Radius;
  SetLength(Planets, Star.Planets.Count);
  for Index := 0 to Star.Planets.Count - 1 do
  begin
    Planet := Star.Planets[Index];
    Planets[Index].Id := Planet.Id;
    Planets[Index].Name := Planet.Name;
    Planets[Index].OwnerId := Planet.OwnerId;
    Planets[Index].RaceId := Planet.RaceId;
    Planets[Index].Population := Planet.Population;
    Planets[Index].Economy := Planet.Economy;
    Planets[Index].Government := Planet.Government;
    Planets[Index].Relation := Planet.GetRelationLevelToShip(Player);
  end;
  SetLength(Ships, Star.Ships.Count);
  for Index := 0 to Star.Ships.Count - 1 do
  begin
    Ship := Star.Ships[Index];
    Ships[Index].Id := Ship.Id;
    Ships[Index].Name := Ship.Name;
    if Player <> Ship then
    begin
      Ships[Index].FullName := WrapTextInColor(Ship.GetFullName(' '), GreenColorTag);
      if (Ship is TRanger) and ((Ship as TRanger).PartnerShip = Player) then
        Ships[Index].FullName := Ships[(Cardinal(Index))].FullName + #13#10 + WrapTextInColor(LookupLocalizedTextByKey('FormInfo.Partner'), HighlightColorTag);
    end
    else Ships[Index].FullName := WrapTextInColor(Ship.GetFullName(' '), GreenColorTag);
    Ships[Index * 1].OwnerId := Ship.OwnerId;
    if Ship is TRuins then Ships[Index].TypeName := ''
    else if Ship is TRanger then Ships[Index].TypeName := (Ship as TRanger).GetCharacterName
    else Ships[Index].TypeName := Ship.GetLocalizedTypeName;
    Ships[(Cardinal(Index))].Speed := Ship.CalculateSpeed;
    Ships[Index].HullCapacity := Ship.Hull.Weight;
    // The film carries an over-capacity value when the scanner cannot resolve hull points.
    if Player.CanResolveObjectWithScanner(Ship) or (Player = Ship) then
      Ships[Index].HullPoints := Ship.Hull.HullPoints
    else Ships[Index].HullPoints := Ship.Hull.Weight + 1;
    Ships[Index].DefenseText := IntToStr(Ship.GetDefensePercent) + '%';
    if Player.CanResolveObjectWithScanner(Ship) or (Player = Ship) then
      Ships[Index].DefenseText := Ships[Index].DefenseText + ' + ' + WrapTextInColor(IntToStr((Ship).Hull.Armor + 5 * (Ord((Ship).HasActiveArtefact(t_ArtefactHull)))), HighlightColorTag);
    Ships[Index].Relation := Ship.GetRelationLevelToShip(Player);
    if (Player <> Ship) and not (Ship is TRuins) and Player.HasActiveArtefact(t_ArtefactAnalyzer) and Player.CanResolveObjectWithScanner(Ship) then
      Ships[Index].WinChance := Player.GetWinChancePercent(Ship)
    else Ships[Index].WinChance := -1;
    Ships[Index].PortraitImage := Ship.GetShipPortraitImagePath;
  end;
  SetLength(Items, Star.Items.Count);
  for Index := 0 to Star.Items.Count - 1 do
  begin
    Item := Star.Items[Index];
    Items[Index].Id := Item.Id;
    Items[Index].ItemType := Item.ItemType;
    Items[Index].Weight := Item.Weight;
    Items[Index].Cost := Item.Cost;
    if Item.ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes) then
      Items[Index].ConditionPercent := (Item as TEquipment).ConditionPercent
    else Items[Index].ConditionPercent := 100;
    if Item is TGoods then
    begin
      Items[Index].ImagePath := 'GI,' + GetItemTypeBitmapPath(Item.ItemType);
      Items[Index].Name := WrapTextInColor(GoodsNames[Item.ItemType], GreenColorTag);
      Items[Index].InfoText := LocalizedText('Items.Goods.Text.' + IntToStr(Ord(Item.ItemType) + 1));
      Items[Index].OwnerId := oiNone;
    end
    else
    begin
      Items[Index].ImagePath := 'GI,' + Item.GetBitmapResourceName + 's';
      Items[Index].Name := WrapTextInColor(Item.GetDisplayName, GreenColorTag);
      Items[Index].InfoText := Item.GetInfoText(HighlightColorTag);
      Items[Index].OwnerId := Item.OwnerId;
    end;
  end;
  SetLength(Asteroids, Star.Asteroids.Count);
  for Index := 0 to Star.Asteroids.Count - 1 do
  begin
    Asteroid := Star.Asteroids[Index];
    Asteroids[Index].Id := Asteroid.Id;
    Asteroids[Index].Name := Asteroid.GetDisplayName;
    Asteroids[Index].InfoText := Asteroid.GetInfoText;
  end;
end;
{ @end $5645D0 }

{ @routine $564F1C TEObjInfo_FindPlanet }
function TEObjInfo.FindPlanet(ObjectId: Cardinal): PEPlanetInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Planets) do
    if Planets[Index].Id = ObjectId then
    begin
      Result := @Planets[Index];
      Exit;
    end;
  Result := nil;
end;
{ @end $564F1C }

{ @routine $564F54 TEObjInfo_FindShip }
function TEObjInfo.FindShip(ObjectId: Cardinal): PEShipInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Ships) do
    if Ships[Index].Id = ObjectId then
    begin
      Result := @Ships[Index];
      Exit;
    end;
  Result := nil;
end;
{ @end $564F54 }

{ @routine $564F90 TEObjInfo_FindItem }
function TEObjInfo.FindItem(ObjectId: Cardinal): PEItemInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Items) do
    if Items[Index].Id = ObjectId then
    begin
      Result := @Items[Index];
      Exit;
    end;
  Result := nil;
end;
{ @end $564F90 }

{ @routine $564FC8 TEObjInfo_FindAsteroid }
function TEObjInfo.FindAsteroid(ObjectId: Cardinal): PEAsteroidInfo;
var
  Index: Integer;
begin
  for Index := 0 to High(Asteroids) do
    if Asteroids[Index].Id = ObjectId then
    begin
      Result := @Asteroids[Index];
      Exit;
    end;
  Result := nil;
end;
{ @end $564FC8 }

{ @routine $565000 TEObjInfo_SaveToBuffer }
procedure TEObjInfo.SaveToBuffer(Buffer: TBufEC);
var
  Index: Integer;
begin
  Buffer.AddWideStringZ(StarName);
  Buffer.AddIntegerValue(StarRadius);
  Buffer.AddAnsiChar(AnsiChar(High(Planets) + 1));
  for Index := 0 to High(Planets) do
  begin
    Buffer.AddDWord(Planets[Index].Id);
    Buffer.AddWideStringZ(Planets[Index].Name);
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].OwnerId));
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].RaceId));
    Buffer.AddIntegerValue(Planets[Index].Population);
    Buffer.AddAnsiChar(AnsiChar(Ord(Planets[Index].Economy)));
    Buffer.AddAnsiChar(AnsiChar(Ord(Planets[Index].Government)));
    Buffer.AddAnsiChar(AnsiChar(Planets[Index].Relation));
  end;
  Buffer.AddWideChar(WideChar(High(Ships) + 1));
  for Index := 0 to High(Ships) do
  begin
    Buffer.AddDWord(Ships[Index].Id);
    Buffer.AddWideStringZ(Ships[Index].Name);
    Buffer.AddWideStringZ(Ships[Index].FullName);
    Buffer.AddAnsiChar(AnsiChar(Ships[Index].OwnerId));
    Buffer.AddWideStringZ(Ships[Index].TypeName);
    Buffer.AddIntegerValue(Ships[Index].Speed);
    Buffer.AddIntegerValue(Ships[Index].HullCapacity);
    Buffer.AddIntegerValue(Ships[Index].HullPoints);
    Buffer.AddWideStringZ(Ships[Index].DefenseText);
    Buffer.AddAnsiChar(AnsiChar(Ships[Index].Relation));
    Buffer.AddIntegerValue(Ships[Index].WinChance);
    Buffer.AddWideStringZ(Ships[Index].PortraitImage);
  end;
  Buffer.AddWideChar(WideChar(High(Items) + 1));
  for Index := 0 to High(Items) do
  begin
    Buffer.AddDWord(Items[Index].Id);
    Buffer.AddWideStringZ(Items[Index].Name);
    Buffer.AddWideStringZ(Items[Index].ImagePath);
    Buffer.AddAnsiChar(AnsiChar(Items[Index].ItemType));
    Buffer.AddWideStringZ(Items[Index].InfoText);
    Buffer.AddIntegerValue(Items[Index].Weight);
    Buffer.AddIntegerValue(Items[Index].Cost);
    Buffer.AddAnsiChar(AnsiChar(Items[Index].OwnerId));
    Buffer.AddSingle(Items[Index].ConditionPercent);
  end;
  Buffer.AddWideChar(WideChar(High(Asteroids) + 1));
  for Index := 0 to High(Asteroids) do
  begin
    Buffer.AddDWord(Asteroids[Index].Id);
    Buffer.AddWideStringZ(Asteroids[Index].Name);
    Buffer.AddWideStringZ(Asteroids[Index].InfoText);
  end;

end;
{ @end $565000 }

{ @routine $5652B0 TEObjInfo_LoadFromBuffer }
procedure TEObjInfo.LoadFromBuffer(Buffer: TBufEC);
var
  Count, Index: Integer;
begin
  Clear;
  StarName := Buffer.ReadWideString;
  StarRadius := Buffer.GetInt32;
  Count := Buffer.GetByte;
  SetLength(Planets, Count);
  for Index := 0 to Count - 1 do
  begin
    Planets[Index].Id := Buffer.GetUInt32;
    Planets[Index].Name := Buffer.ReadWideString;
    Planets[Index].OwnerId := TOwnerId(Buffer.GetByte);
    Planets[Index].RaceId := TRaceId(Buffer.GetByte);
    Planets[Index].Population := Buffer.GetInt32;
    Planets[Index].Economy := TPlanetEconomy(Buffer.GetByte);
    Planets[Index].Government := TPlanetGovernment(Buffer.GetByte);
    Planets[Index].Relation := TRelationLevel(Buffer.GetByte);
  end;
  Count := Buffer.GetWord;
  SetLength(Ships, Count);
  for Index := 0 to Count - 1 do
  begin
    Ships[Index].Id := Buffer.GetUInt32;
    Ships[Index].Name := Buffer.ReadWideString;
    Ships[Index].FullName := Buffer.ReadWideString;
    Ships[Index].OwnerId := TOwnerId(Buffer.GetByte);
    Ships[Index].TypeName := Buffer.ReadWideString;
    Ships[Index].Speed := Buffer.GetInt32;
    Ships[Index].HullCapacity := Buffer.GetInt32;
    Ships[Index].HullPoints := Buffer.GetInt32;
    Ships[Index].DefenseText := Buffer.ReadWideString;
    Ships[Index].Relation := TRelationLevel(Buffer.GetByte);
    Ships[Index].WinChance := Buffer.GetInt32;
    Ships[Index].PortraitImage := Buffer.ReadWideString;
  end;
  Count := Buffer.GetWord;
  SetLength(Items, Count);
  for Index := 0 to Count - 1 do
  begin
    Items[Index].Id := Buffer.GetUInt32;
    Items[Index].Name := Buffer.ReadWideString;
    Items[Index].ImagePath := Buffer.ReadWideString;
    Items[Index].ItemType := TItemType(Buffer.GetByte);
    Items[Index].InfoText := Buffer.ReadWideString;
    Items[Index].Weight := Buffer.GetInt32;
    Items[Index].Cost := Buffer.GetInt32;
    Items[Index].OwnerId := TOwnerId(Buffer.GetByte);
    Items[Index].ConditionPercent := Buffer.GetSingle;
  end;
  Count := Buffer.GetWord;
  SetLength(Asteroids, Count);
  for Index := 0 to Count - 1 do
  begin
    Asteroids[Index].Id := Buffer.GetUInt32;
    Asteroids[Index].Name := Buffer.ReadWideString;
    Asteroids[Index].InfoText := Buffer.ReadWideString;
  end;

end;
{ @end $5652B0 }

end.

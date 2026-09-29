unit aPacket;
// Unit bracket (inferred): CODE 0x004B03D0..0x004B05AB; inclusive evidence, not full bounds.
// Package startup. Loose files precede configured archives.
interface
function InitializePackageCollection: Boolean; // @addr $4B03D0
function LoadConfiguredPackages: Boolean; // @addr $4B0440
procedure FinalizePackageCollection; // @addr $4B0524
implementation

// @unit-initialization $4B05A4
// @unit-finalization $4B0574

uses EC_HsFile, EC_BlockPar, GR_Main, SyncObjs;

{ @routine $4B03D0 InitializePackageCollection }
function InitializePackageCollection: Boolean;
var Pack: TPackFileEC;
begin
  PackageFileLock := TCriticalSection.Create;
  Result := True;
  PackageCollection := nil;
  PackageCollection := TPackCollectionEC.Create;
  Pack := TPackFileEC.Create;
  Pack.UseLooseFiles := True;
  Pack.SetPackagePath('');
  PackageCollection.AddPackToFront(Pack);
  PackageCollection.OpenAllPackages;
end;
{ @end $4B03D0 }

{ @routine $4B0440 LoadConfiguredPackages }
function LoadConfiguredPackages: Boolean;
var Block: TBlockParEC; Index: Integer; Pack: TPackFileEC;
begin
  PackageCollection.CloseAllPackages;
  Block := InstallConfig.GetBlock('Packages');
  for Index := 0 to Block.GetParamCount - 1 do
  begin
    Pack := TPackFileEC.Create;
    Pack.SetPackagePath(AnsiString(Block.GetParamValue(Index)));
    PackageCollection.AddPackToBack(Pack);
  end;
  Result := PackageCollection.OpenAllPackages;
end;
{ @end $4B0440 }

{ @routine $4B0524 FinalizePackageCollection }
procedure FinalizePackageCollection;
begin
  PackageCollection.CloseAllPackages;
  PackageCollection.Clear(True);
  PackageCollection.Free;
  PackageCollection := nil;
  if PackageFileLock <> nil then
  begin
    PackageFileLock.Free;
    PackageFileLock := nil;
  end;
end;
{ @end $4B0524 }
end.

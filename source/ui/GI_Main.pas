unit GI_Main;
// Unit bracket (inferred): CODE 0x004A68F4..0x004A858B; inclusive evidence, not full bounds.
// Configuration helpers.

// Configuration helper placement in GI_Main is inferred; no explicit unit RTTI was recovered here.

interface

uses GI_MessageLoop, SysUtils, Types, EC_Struct;

const
  // ParseAutoGeometryFlagsGI maps the native configuration names pos / size.
  agfPosition = $01;
  agfSize = $02;

type
  TImageKindXGI = (ikxLeftFill=0, ikxCenterFill=1, ikxRightFill=2, ikxLeft=3, ikxCenter=4, ikxRight=5); // @size $01
  TImageKindYGI = (ikyTopFill=0, ikyCenterFill=1, ikyBottomFill=2, ikyTop=3, ikyCenter=4, ikyBottom=5); // @size $01
  TTextAlignXGI = (taxLeft=0, taxCenter=1, taxRight=2, taxAuto=3); // @size $01
  TTextAlignYGI = (tayTop=0, tayCenter=1, tayCenterEx=2, tayBottom=3, tayAuto=4); // @size $01

procedure BreakUiMessage; // @addr $4A8520 @note "Sets the shared exception-log-copy suppression flag and raises ExceptionBreakMessageGI. Placement in GI_Main is inferred."

function CreateControlByName(Name: WideString; Owner: TObjectGI): TObjectGI; // @addr $4A68F4 @note "Exact type-name lookup; returns nil for unknown names. Placement in GI_Main is inferred from its configuration-helper region."

function ParseImageKindXName(Name: WideString): TImageKindXGI; // @addr $4A776C @note "Exact spelling required; unknown names raise."
function ParseImageKindYName(Name: WideString): TImageKindYGI; // @addr $4A791C @note "Exact spelling required; unknown names raise."
function ParseTextAlignXName(Name: WideString): TTextAlignXGI; // @addr $4A7ACC
function ParseTextAlignYName(Name: WideString): TTextAlignYGI; // @addr $4A7C18
function ParseEnabledNameGI(Name: WideString): Boolean; // @addr $4A7D90 @note "True only for Yes, yes, True, true, TRUE or 1."
function GetColorGI(ColorText: WideString): Cardinal; // @addr $4A7E84 @note "At least three comma-separated components are required; only their low bytes are used."
function GetPointGI(PointText: WideString): TPoint; // @addr $4A8014

function ParseAutoGeometryFlagsGI(Values: WideString): Integer; // @addr $4A843C @note "Comma-separated pos and size names, trimmed and case-insensitive; unknown names are ignored. Placement in GI_Main is inferred."

function GetFloatPointGI(PointText: WideString): TPointF; // @addr $4A8158
function GetRectGI(RectText: WideString): TRect; // @addr $4A8280

implementation

// @unit-initialization $4A8584
// @unit-finalization $4A8554

uses EC_Str, Classes, GR_Main, GI_PlanetButton, GI_avi, GI_XviD, GI_PSRay, GI_PSRay2, GI_PSRocket, GI_PSLaser, GI_HeavyLaser, GI_LaserCannonRay, GI_Lightning, GI_PSEyes, GI_PSWind, GI_PSSubmesonicCannon, GI_PSDefibrillator, GI_PSPhaser, GI_PSWeapon01, GI_PSWeapon02, GI_PSWeapon06, GI_PSWeapon08, GI_PSWeapon09, GI_PSWeapon13, EC_Struct, GI_AImage, GI_AlphaImage, GI_CheckBox, GI_Circle, GI_CountBar, GI_Door, GI_Edit, GI_Frame, GI_GAI, GI_GAIFile, GI_GI, GI_GraphBuf, GI_GraphButton, GI_Grid, GI_Image, GI_InfiniteImage, GI_Label, GI_Line, GI_MultiImage, GI_Panel, GI_PanelScrollBar, GI_Planet, GI_PolyLine, GI_RadioGroup, GI_RotateImage, GI_RotateImage2, GI_RotateImage5, GI_SBPath, GI_ScrollBar, GI_ShrLight, GI_SimpleButton, GI_SimpleImage, GI_SpaceCircle, GI_SpaceImg, GI_StarField, GI_StarFieldImg, GI_StarFieldM, GI_StatusBar, GI_TextButton, GI_TransImage, GI_Window, GI_Zone, System;

{ @routine $4A68F4 CreateControlByName }
function CreateControlByName(Name: WideString; Owner: TObjectGI): TObjectGI;
begin
  if Name = 'Panel' then Result := TPanelGI.Create(Owner)
  else if Name = 'PanelScrollBar' then Result := TPanelScrollBarGI.Create(Owner)
  else if Name = 'Window' then Result := TWindowGI.Create(Owner)
  else if Name = 'SimpleImage' then Result := TSimpleImageGI.Create(Owner)
  else if Name = 'TransImage' then Result := TTransImageGI.Create(Owner)
  else if Name = 'AlphaImage' then Result := TAlphaImageGI.Create(Owner)
  else if Name = 'RotateImage' then Result := TRotateImageGI.Create(Owner)
  else if Name = 'RotateImage2' then Result := TRotateImage2GI.Create(Owner)
  else if Name = 'RotateImage5' then Result := TRotateImage5GI.Create(Owner)
  else if Name = 'Image' then Result := TImageGI.Create(Owner)
  else if Name = 'InfiniteImage' then Result := TInfiniteImageGI.Create(Owner)
  else if Name = 'AImage' then Result := TAImageGI.Create(Owner)
  else if Name = 'GI' then Result := TgiGI.Create(Owner)
  else if Name = 'GAI' then Result := TgaiGI.Create(Owner)
  else if Name = 'GAIFile' then Result := TGAIFileGI.Create(Owner)
  else if Name = 'AVI' then Result := TaviGI.Create(Owner)
  else if Name = 'MultiImage' then Result := TMultiImageGI.Create(Owner)
  else if Name = 'Door' then Result := TDoorGI.Create(Owner)
  else if Name = 'SimpleButton' then Result := TSimpleButtonGI.Create(Owner)
  else if Name = 'TextButton' then Result := TTextButtonGI.Create(Owner)
  else if Name = 'GraphButton' then Result := TGraphButtonGI.Create(Owner)
  else if Name = 'Zone' then Result := TZoneGI.Create(Owner)
  else if Name = 'Label' then Result := TLabelGI.Create(Owner)
  else if Name = 'Edit' then Result := TEditGI.Create(Owner)
  else if Name = 'ScrollBar' then Result := TScrollBarGI.Create(Owner)
  else if Name = 'CountBar' then Result := TCountBarGI.Create(Owner)
  else if Name = 'SBPath' then Result := TSBPathGI.Create(Owner)
  else if Name = 'StatusBar' then Result := TStatusBarGI.Create(Owner)
  else if Name = 'Planet' then Result := TPlanetGI.Create(Owner)
  else if Name = 'PlanetButton' then Result := TPlanetButtonGI.Create(Owner)
  else if Name = 'CheckBox' then Result := TCheckBoxGI.Create(Owner)
  else if Name = 'RadioGroup' then Result := TRadioGroupGI.Create(Owner)
  else if Name = 'Grid' then Result := TGridGI.Create(Owner)
  else if Name = 'Line' then Result := TLineGI.Create(Owner)
  else if Name = 'Circle' then Result := TCircleGI.Create(Owner)
  else if Name = 'Frame' then Result := TFrameGI.Create(Owner)
  else if Name = 'ShrLight' then Result := TShrLightGI.Create(Owner)
  else if Name = 'GraphBuf' then Result := TGraphBufGI.Create(Owner)
  else if Name = 'StarField' then Result := TStarFieldGI.Create(Owner)
  else if Name = 'StarFieldM' then Result := TStarFieldMGI.Create(Owner)
  else if Name = 'StarFieldImg' then Result := TStarFieldImgGI.Create(Owner)
  else if Name = 'SpaceCircle' then Result := TSpaceCircleGI.Create(Owner)
  else if Name = 'SpaceImg' then Result := TSpaceImgGI.Create(Owner)
  else if Name = 'PSRay' then Result := TPSRayGI.Create(Owner)
  else if Name = 'PSRailRay' then Result := TPSRailRayGI.Create(Owner)
  else if Name = 'PSDoubleWhirl' then Result := TPSRailRayGI.Create(Owner)
  else if Name = 'PSBlueWhirl' then Result := TPSBlueWhirlGI.Create(Owner)
  else if Name = 'PSGreenWhirl' then Result := TPSGreenWhirlGI.Create(Owner)
  else if Name = 'PSRocket' then Result := TPSRocketGI.Create(Owner)
  else if Name = 'PSLaser' then Result := TPSLaserGI.Create(Owner)
  else if Name = 'PSHeavyLaser' then Result := TPSHeavyLaserGI.Create(Owner)
  else if Name = 'PSLaserCannonRay' then Result := TPSLaserCannonRayGI.Create(Owner)
  else if Name = 'PSLightning' then Result := TPSLightningGI.Create(Owner)
  else if Name = 'PSMachpelaEyes' then Result := TPSEyesGI.Create(Owner)
  else if Name = 'PSRetractor' then Result := TPSWindGI.Create(Owner)
  else if Name = 'PSSubmesonicCannon' then Result := TPSSubmesonicCannonGI.Create(Owner)
  else if Name = 'PSDefibrillator' then Result := TPSDefibrillatorGI.Create(Owner)
  else if Name = 'PSPhaser' then Result := TPSPhaserGI.Create(Owner)
  else if Name = 'PolyLine' then Result := TPolyLineGI.Create(Owner)
  else if Name = 'XviD' then Result := TxvidGI.Create(Owner)
  else Result := nil;
end;
{ @end $4A68F4 }

{ @routine $4A776C ParseImageKindXName }
function ParseImageKindXName(Name: WideString): TImageKindXGI;
begin
  if Name = 'LeftFill' then Result := ikxLeftFill
  else if Name = 'CenterFill' then Result := ikxCenterFill
  else if Name = 'RightFill' then Result := ikxRightFill
  else if Name = 'Left' then Result := ikxLeft
  else if Name = 'Center' then Result := ikxCenter
  else if Name = 'Right' then Result := ikxRight
  else raise Exception.Create('GetITDXbyNameGI. name=' + Name);
end;
{ @end $4A776C }

{ @routine $4A791C ParseImageKindYName }
function ParseImageKindYName(Name: WideString): TImageKindYGI;
begin
  if Name = 'TopFill' then Result := ikyTopFill
  else if Name = 'CenterFill' then Result := ikyCenterFill
  else if Name = 'BottomFill' then Result := ikyBottomFill
  else if Name = 'Top' then Result := ikyTop
  else if Name = 'Center' then Result := ikyCenter
  else if Name = 'Bottom' then Result := ikyBottom
  else raise Exception.Create('GetITDYbyNameGI. name=' + Name);
end;
{ @end $4A791C }

{ @routine $4A7ACC ParseTextAlignXName }
function ParseTextAlignXName(Name: WideString): TTextAlignXGI;
begin
  if Name = 'Left' then Result := taxLeft
  else if Name = 'Center' then Result := taxCenter
  else if Name = 'Right' then Result := taxRight
  else if Name = 'Auto' then Result := taxAuto
  else raise Exception.Create('GetTTAXbyNameGI. name=' + Name);
end;
{ @end $4A7ACC }

{ @routine $4A7C18 ParseTextAlignYName }
function ParseTextAlignYName(Name: WideString): TTextAlignYGI;
begin
  if Name = 'Top' then Result := tayTop
  else if Name = 'Center' then Result := tayCenter
  else if Name = 'CenterEx' then Result := tayCenterEx
  else if Name = 'Bottom' then Result := tayBottom
  else if Name = 'Auto' then Result := tayAuto
  else raise Exception.Create('GetTTAYbyNameGI. name=' + Name);
end;
{ @end $4A7C18 }

{ @routine $4A7D90 ParseEnabledNameGI }
function ParseEnabledNameGI(Name: WideString): Boolean;
begin
  if (Name = 'Yes') or (Name = 'yes') or (Name = 'True') or
    (Name = 'true') or (Name = 'TRUE') or (Name = '1') then
    Result := True
  else Result := False;
end;
{ @end $4A7D90 }

{ @routine $4A7E84 GetColorGI }
function GetColorGI(ColorText: WideString): Cardinal;
begin
  if CountDelimitedPartsW(ColorText, ',') < 3 then
    raise Exception.Create('GetColorGI. color=' + ColorText);
  Result := CurrentPixelFormat.PackRgbBytes(
    StrToInt(ExtractDelimitedPartW(ColorText, 0, ',')),
    StrToInt(ExtractDelimitedPartW(ColorText, 1, ',')),
    StrToInt(ExtractDelimitedPartW(ColorText, 2, ',')));
end;
{ @end $4A7E84 }

{ @routine $4A8014 GetPointGI }
function GetPointGI(PointText: WideString): TPoint;
begin
  if CountDelimitedPartsW(PointText, ',') < 2 then
    raise Exception.Create('GetPointGI. tstr=' + PointText);
  Result := Classes.Point(StrToInt(ExtractDelimitedPartW(PointText, 0, ',')),
    StrToInt(ExtractDelimitedPartW(PointText, 1, ',')));
end;
{ @end $4A8014 }

{ @routine $4A8158 GetFloatPointGI }
function GetFloatPointGI(PointText: WideString): TPointF;
begin
  if CountDelimitedPartsW(PointText, ',') < 2 then
    raise Exception.Create('GetFloatPointGI. tstr=' + PointText);
  Result := MakePointF(ExtractDecimalToSingleW(ExtractDelimitedPartW(PointText, 0, ',')),
    ExtractDecimalToSingleW(ExtractDelimitedPartW(PointText, 1, ',')));
end;
{ @end $4A8158 }

{ @routine $4A8280 GetRectGI }
function GetRectGI(RectText: WideString): TRect;
begin
  if CountDelimitedPartsW(RectText, ',') < 4 then
    raise Exception.Create('GetRectGI. tstr=' + RectText);
  Result.Left := StrToInt(ExtractDelimitedPartW(RectText, 0, ','));
  Result.Top := StrToInt(ExtractDelimitedPartW(RectText, 1, ','));
  Result.Right := StrToInt(ExtractDelimitedPartW(RectText, 2, ','));
  Result.Bottom := StrToInt(ExtractDelimitedPartW(RectText, 3, ','));
end;
{ @end $4A8280 }

{ @routine $4A843C ParseAutoGeometryFlagsGI }
function ParseAutoGeometryFlagsGI(Values: WideString): Integer;
var Index, Count, Flags: Integer; Part: WideString;
begin
  Flags := 0;
  Count := CountDelimitedPartsW(Values, ',');
  for Index := 0 to Count - 1 do
  begin
    Part := LowerCaseWideString(TrimWideString(ExtractDelimitedPartW(Values, Index, ',')));
    if Part = 'pos' then Flags := Flags or agfPosition
    else if Part = 'size' then Flags := Flags or agfSize;
  end;
  Result := Flags;
end;
{ @end $4A843C }

{ @routine $4A8520 BreakUiMessage }
procedure BreakUiMessage;
begin
  SuppressExceptionLogCopy := True;
  raise ExceptionBreakMessageGI.Create('No error');
end;
{ @end $4A8520 }

end.

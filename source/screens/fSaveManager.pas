unit fSaveManager;
// Unit bracket (inferred): CODE 0x0054FB24..0x005529E7; inclusive evidence, not full bounds.
interface
uses GI_MessageLoop, Types;
type
  TSaveManagerMode = (smmLoad, smmSave); // @size $01
  TSMSlot = record // @size $28
    FileName: AnsiString; // @offset $00 Empty means the slot is unavailable.
    DisplayName: WideString; // @offset $04
    Turn: Integer; // @offset $08
    Money: Integer; // @offset $0C
    PilotName: WideString; // @offset $10
    RaceName: WideString; // @offset $14
    LastWriteTime: Int64; // @offset $18 Raw FILETIME, compared as a signed Int64 by the native sorter.
    RecencyRank: Integer; // @offset $20 Zero is newest; -1 when the header was rejected.
  end;
  TfSaveManager = class(TMessageLoopGI) // @size $270
  public
    constructor Create; // @addr $54FBC0
    SelectedSlot: Integer; // @offset $B0
    Slots: array[0..10] of TSMSlot; // @offset $B8 Ten manual slots followed by autosave.

    function GetSaveSlotPath(Slot: Integer): AnsiString; // @addr $552670
    destructor Destroy; override; // @addr $54FC00
    procedure OnOpen; override; // @addr $54FC28
    procedure OnClose; override; // @addr $550AB8
    procedure RefreshSlot(SlotIndex: Integer; ShowCurrentPlayer: Boolean); // @addr $550B40
    procedure CloseClicked(Sender: TObjectGI); // @addr $551680
    procedure LoadClicked(Sender: TObjectGI); // @addr $55169C
    procedure SaveClicked(Sender: TObjectGI); // @addr $5517B8
    procedure DeleteClicked(Sender: TObjectGI); // @addr $5519C8
    procedure SlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $551AC4
    procedure SlotDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint); // @addr $551B04
    procedure SlotKeyDown(Sender: TObjectGI; Key: Cardinal); // @addr $551B34
    procedure SelectSlot(SlotIndex: Integer); // @addr $551C70
    procedure ClearSlotSelection(SlotIndex: Integer); // @addr $551FDC
    procedure ScanSaveFiles; // @addr $552208
    function IsSlotEmpty(SlotIndex: Integer): Boolean; // @addr $552658
    function FindNewestSlot: Integer; // @addr $552730
    procedure RefreshAllSlots; // @addr $552764
    function ReadSaveVersion(FileName: AnsiString): Integer; // @addr $552770
    procedure LoadSavePreview(FileName: AnsiString); // @addr $552818
    procedure SelectMusic; override; // @addr $5529AC
  end;

implementation

// @unit-initialization $5529E0
// @unit-finalization $5529B0

uses Classes, SysUtils, Windows, Math, GI_Main, GI_Panel, GI_PanelScrollBar, GI_Image, GI_GraphBuf,
  GI_GraphButton, GI_Edit, GI_Label, GI_MessageBox, GR_Main, GR_GraphBuf, EC_File, EC_Buf,
  EC_Str, aConst, aMyFunction, aPlayer, aShip, aGalaxy, aSaveLoad, Globals, GlobalsV;
{ @routine $54FBC0 TfSaveManager_Create }
constructor TfSaveManager.Create;
begin
  inherited Create;
  SelectedSlot := -1;
end;
{ @end $54FBC0 }

{ @routine $54FC00 TfSaveManager_Destroy }
destructor TfSaveManager.Destroy;
begin inherited Destroy; end;
{ @end $54FC00 }

{ @routine $54FC28 TfSaveManager_OnOpen }
procedure TfSaveManager.OnOpen;
var Panel: TPanelGI; ScrollPanel: TPanelScrollBarGI; I: Integer;
begin
  inherited OnOpen;
  if not DirectoryExists('Save') then CreateDir('Save');
  if AuxRenderBuffer.Pixels = nil then CaptureScreenBackground;
  (GetByName('BGBuf') as TGraphBufGI).GraphBuf.AttachPixels(AuxRenderBuffer.Width, AuxRenderBuffer.Height, AuxRenderBuffer.PitchBytes, AuxRenderBuffer.Pixels);
  ScanSaveFiles;
  if SelectedSlot < 0 then SelectedSlot := FindNewestSlot;
  (GetByName('ButCancel') as TGraphButtonGI).UpCallback := CloseClicked;
  with GetByName('ButLoad') as TGraphButtonGI do begin SetActive(SaveManagerMode = smmLoad); UpCallback := LoadClicked; end;
  with GetByName('ButSave') as TGraphButtonGI do begin SetActive(SaveManagerMode = smmSave); UpCallback := SaveClicked; end;
  with GetByName('ButDelete') as TGraphButtonGI do begin UpCallback := DeleteClicked; SetActive(False); end;
  with GetByName('GameImage') as TGraphBufGI do begin GraphBuf.Clear; Invalidate; end;
  GetByName('CaptionLoad').SetActive(SaveManagerMode = smmLoad);
  GetByName('CaptionSave').SetActive(SaveManagerMode = smmSave);
  ScrollPanel := GetByName('PanelSlot') as TPanelScrollBarGI;
  ScrollPanel.KeyDownCallback := SlotKeyDown;
  for I := 0 to 10 do begin
    Panel := TPanelGI.Create(ScrollPanel);
    if GiResourceVariant = 1 then begin Panel.SetPosition(Point(0, 42 * I)); Panel.SetSize(Point(ScrollPanel.ClientSize.X, 42)); end
    else begin Panel.SetPosition(Point(0, 55 * I)); Panel.SetSize(Point(ScrollPanel.ClientSize.X, 55)); end;
    Panel.SetName('Slot' + IntToStr(I));
    Panel.SetPositionModeW(True);
    Panel.LeftButtonDownCallback := SlotMouseDown;
    Panel.LeftButtonDoubleClickCallback := SlotDoubleClick;
    with TImageGI.Create(Panel) do begin
      SetPosition(Point(0, 0)); SetSize(Panel.ClientSize); SetDepthByName('99');
      SetImagePath('GI,Bm.FormSave.' + GiResourceSuffix + 'N');
      SetImageKindX(ikxLeftFill); SetImageKindY(ikyTopFill);
      SetName('Slot' + IntToStr(I) + 'BG'); SetActive(not IsSlotEmpty(I));
    end;
    if (SaveManagerMode = smmLoad) or (I = 10) then begin
      with TLabelGI.Create(Panel) do begin
        if GiResourceVariant = 1 then begin SetPosition(Point(80, 4)); SetSize(Point(335, 16)); end
        else begin SetPosition(Point(103, 6)); SetSize(Point(429, 21)); end;
        SetDepthByName('98'); SetFontName(HitPointFontName); SetTextAlignX(taxLeft); SetTextAlignY(tayCenterEx);
        SetName('Slot' + IntToStr(I) + 'Edit');
        if I = 10 then SetText(LookupLocalizedTextByKey('FormSaveManager.AutoSave'))
        else if IsSlotEmpty(I) then SetText('') else SetText(Slots[I].DisplayName);
      end;
    end else begin
      with TEditGI.Create(Panel) do begin
        if GiResourceVariant = 1 then begin SetPosition(Point(80, 4)); SetSize(Point(335, 16)); end
        else begin SetPosition(Point(103, 5)); SetSize(Point(429, 21)); end;
        SetDepthByName('98'); SetFontName(HitPointFontName);
        SetName('Slot' + IntToStr(I) + 'Edit'); MaxLength := 55;
        if I = 10 then SetText(LookupLocalizedTextByKey('FormSaveManager.AutoSave'))
        else if IsSlotEmpty(I) then SetText('') else SetText(Slots[I].DisplayName);
      end;
    end;
    with TLabelGI.Create(Panel) do begin
      if GiResourceVariant = 1 then begin SetPosition(Point(1, 1)); SetSize(Point(29, 42)); end
      else begin SetPosition(Point(1, 1)); SetSize(Point(37, 54)); end;
      SetDepthByName('98'); SetFontName(HitPointFontName); SetTextAlignX(taxCenter); SetTextAlignY(tayCenterEx);
      SetText(IntToStr(I + 1));
    end;
    with TImageGI.Create(Panel) do begin
      SetDepthByName('98');
      if GiResourceVariant = 1 then begin SetPosition(Point(33, 5)); SetSize(Point(36, 33)); end
      else begin SetPosition(Point(41, 5)); SetSize(Point(47, 46)); end;
      SetActive(False); SetName('Slot' + IntToStr(I) + 'Emblem');
    end;
    with TLabelGI.Create(Panel) do begin
      if GiResourceVariant = 1 then begin SetPosition(Point(73, 22)); SetSize(Point(113, 16)); end
      else begin SetPosition(Point(93, 30)); SetSize(Point(145, 21)); end;
      SetDepthByName('98'); SetFontName(HitPointFontName); SetTextAlignX(taxCenter); SetTextAlignY(tayCenterEx);
      SetName('Slot' + IntToStr(I) + 'Captain');
    end;
    with TLabelGI.Create(Panel) do begin
      if GiResourceVariant = 1 then begin SetPosition(Point(197, 22)); SetSize(Point(122, 16)); end
      else begin SetPosition(Point(252, 30)); SetSize(Point(156, 21)); end;
      SetDepthByName('98'); SetFontName(HitPointFontName); SetTextAlignX(taxCenter); SetTextAlignY(tayCenterEx);
      SetName('Slot' + IntToStr(I) + 'Turn');
    end;
    with TLabelGI.Create(Panel) do begin
      if GiResourceVariant = 1 then begin SetPosition(Point(348, 22)); SetSize(Point(66, 16)); end
      else begin SetPosition(Point(446, 30)); SetSize(Point(85, 21)); end;
      SetDepthByName('98'); SetFontName(HitPointFontName); SetTextAlignX(taxCenter); SetTextAlignY(tayCenterEx);
      SetName('Slot' + IntToStr(I) + 'Money');
    end;
    RefreshSlot(I, False);
  end;
  ScrollPanel.UpdateScrollRanges;
  if (SelectedSlot = 10) and (SaveManagerMode <> smmLoad) then SelectedSlot := -1;
  if SelectedSlot >= 0 then SelectSlot(SelectedSlot);
end;
{ @end $54FC28 }

{ @routine $550AB8 TfSaveManager_OnClose }
procedure TfSaveManager.OnClose;
begin
  (GetByName('PanelSlot') as TPanelScrollBarGI).FreeOwnedChildren;
  (GetByName('GameImage') as TGraphBufGI).GraphBuf.Clear;
  AuxRenderBuffer.Clear;
  inherited OnClose;
end;
{ @end $550AB8 }

{ @routine $550B40 TfSaveManager_RefreshSlot }
procedure TfSaveManager.RefreshSlot(SlotIndex: Integer; ShowCurrentPlayer: Boolean);
begin
  if not ShowCurrentPlayer then begin
    if IsSlotEmpty(SlotIndex) then begin
      if SlotIndex = 10 then (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI).SetText('')
      else if SaveManagerMode = smmLoad then (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI).SetText('')
      else (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TEditGI).SetText('');
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI).SetText('');
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI).SetText('');
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI).SetText('');
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Emblem') as TImageGI).SetActive(False);
    end else begin
      if SlotIndex = 10 then (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI).SetText(LookupLocalizedTextByKey('FormSaveManager.AutoSave'))
      else if SaveManagerMode = smmLoad then (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI).SetText(Slots[SlotIndex].DisplayName)
      else (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TEditGI).SetText(Slots[SlotIndex].DisplayName);
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI).SetText(Slots[SlotIndex].PilotName);
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI).SetText(FormatGameTurnDate(Slots[SlotIndex].Turn));
      (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI).SetText(IntToStr(Slots[SlotIndex].Money));
      with GetByName('Slot' + IntToStr(SlotIndex) + 'Emblem') as TImageGI do begin
        SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + Slots[SlotIndex].RaceName));
        SetImageKindX(ikxCenter); SetImageKindY(ikyCenter); SetActive(True);
      end;
    end;
  end else begin
    if SlotIndex = 10 then (GetByName('Slot' + IntToStr(SlotIndex) + 'Edit') as TLabelGI).SetText(LookupLocalizedTextByKey('FormSaveManager.AutoSave'));
    (GetByName('Slot' + IntToStr(SlotIndex) + 'Captain') as TLabelGI).SetText(Player.Name);
    (GetByName('Slot' + IntToStr(SlotIndex) + 'Turn') as TLabelGI).SetText(FormatGameTurnDate(Galaxy.CurrentTurn));
    (GetByName('Slot' + IntToStr(SlotIndex) + 'Money') as TLabelGI).SetText(IntToStr(Player.Money));
    with GetByName('Slot' + IntToStr(SlotIndex) + 'Emblem') as TImageGI do begin
      SetImagePath(GameDataConfig.GetParamByPath('Race.Emblem.' + GiResourceSuffix + OwnerInfo[oiNone].InternalName));
      SetImageKindX(ikxCenter); SetImageKindY(ikyCenter); SetActive(True);
    end;
  end;
end;
{ @end $550B40 }

{ @routine $551680 TfSaveManager_CloseClicked }
procedure TfSaveManager.CloseClicked(Sender: TObjectGI);
begin
  RequestedScreenId := SaveManagerReturnScreenId;
  RequestClose(1);
end;
{ @end $551680 }

{ @routine $55169C TfSaveManager_LoadClicked }
procedure TfSaveManager.LoadClicked(Sender: TObjectGI);
begin
  if SelectedSlot < 0 then Exit;
  if not IsSlotEmpty(SelectedSlot) and (ReadSaveVersion(Slots[SelectedSlot].FileName) < 6) then begin
    ShowMessageBoxGI(TMessageLoopGI(GetRegisteredScreenLoop(CurrentScreenId)), LanguageDataConfig.GetParamByPath('FormSaveManager.LoadError'), mbgCancel);
    Exit;
  end;
  if not IsSlotEmpty(SelectedSlot) then begin
    PendingLoadFileName := Slots[SelectedSlot].FileName;
    RequestedScreenId := screenGameLoad;
    RequestClose(1);
  end;
end;
{ @end $55169C }

{ @routine $5517B8 TfSaveManager_SaveClicked }
procedure TfSaveManager.SaveClicked(Sender: TObjectGI);
var Saved: Boolean;
begin
  if SelectedSlot < 0 then Exit;
  if SelectedSlot = 10 then Saved := SaveGameToFile(GetSaveSlotPath(SelectedSlot), '')
  else if IsSlotEmpty(SelectedSlot) then Saved := SaveGameToFile(GetSaveSlotPath(SelectedSlot), (GetByName('Slot' + IntToStr(SelectedSlot) + 'Edit') as TEditGI).Text)
  else Saved := SaveGameToFile(Slots[SelectedSlot].FileName, (GetByName('Slot' + IntToStr(SelectedSlot) + 'Edit') as TEditGI).Text);
  if Saved then CloseClicked(Sender)
  else ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormSaveManager.SaveError'), mbgOK);
end;
{ @end $5517B8 }

{ @routine $5519C8 TfSaveManager_DeleteClicked }
procedure TfSaveManager.DeleteClicked(Sender: TObjectGI);
begin
  if SelectedSlot < 0 then Exit;
  if IsSlotEmpty(SelectedSlot) then Exit;
  if ShowMessageBoxGI(Self, LanguageDataConfig.GetParamByPath('FormSaveManager.QueryDelete'), mbgOK or mbgCancel) = mbgResultOK then begin
    SysUtils.DeleteFile(Slots[SelectedSlot].FileName);
    Slots[SelectedSlot].FileName := '';
    SelectSlot(SelectedSlot);
    ScanSaveFiles;
    RefreshAllSlots;
  end;
end;
{ @end $5519C8 }

{ @routine $551AC4 TfSaveManager_SlotMouseDown }
procedure TfSaveManager.SlotMouseDown(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
var SlotIndex: Integer;
begin
  SlotIndex := ExtractDigitsToIntW(Sender.ControlName);
  if (SaveManagerMode = smmLoad) or (SlotIndex <> 10) then SelectSlot(SlotIndex);
end;
{ @end $551AC4 }

{ @routine $551B04 TfSaveManager_SlotDoubleClick }
procedure TfSaveManager.SlotDoubleClick(Sender: TObjectGI; KeyState: Cardinal; Point: TPoint);
begin
  if SaveManagerMode = smmSave then SaveClicked(Sender) else LoadClicked(Sender);
end;
{ @end $551B04 }

{ @routine $551B34 TfSaveManager_SlotKeyDown }
procedure TfSaveManager.SlotKeyDown(Sender: TObjectGI; Key: Cardinal);
begin
  if Key = VK_DOWN then begin
    if SelectedSlot < 0 then SelectSlot(0)
    else if ((SaveManagerMode <> smmLoad) or (SelectedSlot < 10)) and
      ((SaveManagerMode = smmLoad) or (SelectedSlot < 9)) then SelectSlot(SelectedSlot + 1);
  end else if Key = VK_UP then begin
    // Native up from no selection chooses autosave even in save mode.
    if SelectedSlot < 0 then SelectSlot(10)
    else if SelectedSlot <> 0 then SelectSlot(SelectedSlot - 1);
  end else if (Key = VK_HOME) or (Key = VK_PRIOR) then begin
    if SelectedSlot <> 0 then SelectSlot(0);
  end else if (Key = VK_END) or (Key = VK_NEXT) then begin
    if (SaveManagerMode = smmLoad) and (SelectedSlot <> 10) then SelectSlot(10)
    else if (SaveManagerMode <> smmLoad) and (SelectedSlot <> 9) then SelectSlot(9);
  end else if (Key = VK_DELETE) and (SaveManagerMode = smmLoad) then DeleteClicked(nil)
  else if Key = VK_ESCAPE then CloseClicked(Sender)
  else if Key = VK_RETURN then begin
    if SaveManagerMode = smmSave then SaveClicked(Sender) else LoadClicked(Sender);
  end;
end;
{ @end $551B34 }

{ @routine $551C70 TfSaveManager_SelectSlot }
procedure TfSaveManager.SelectSlot(SlotIndex: Integer);
var ScrollPanel: TPanelScrollBarGI;
begin
  ClearSlotSelection(SelectedSlot);
  SelectedSlot := SlotIndex;
  if SelectedSlot >= 0 then begin
    ScrollPanel := GetByName('PanelSlot') as TPanelScrollBarGI;
    with GetByName('Slot' + IntToStr(SlotIndex)) as TPanelGI do begin
      SetDepthByName('-1');
      ScrollPanel.ScrollRectIntoView(GetLocalBounds);
    end;
    with GetByName('Slot' + IntToStr(SlotIndex) + 'BG') as TImageGI do begin
      if IsSlotEmpty(SlotIndex) and (SaveManagerMode = smmLoad) then
        SetImagePath('GI,Bm.FormSave.' + GiResourceSuffix + 'E')
      else SetImagePath('GI,Bm.FormSave.' + GiResourceSuffix + 'A');
      SetImageKindX(ikxLeftFill);
      SetImageKindY(ikyTopFill);
      SetActive(True);
    end;
    if SaveManagerMode = smmSave then SetFocusedControl(GetByName('Slot' + IntToStr(SlotIndex) + 'Edit'));
    RefreshSlot(SlotIndex, SaveManagerMode = smmSave);
    if not IsSlotEmpty(SlotIndex) then LoadSavePreview(Slots[SlotIndex].FileName)
    else begin
      with GetByName('GameImage') as TGraphBufGI do begin GraphBuf.Clear; Invalidate; end;
    end;
    GetByName('ButDelete').SetActive(not IsSlotEmpty(SlotIndex));
  end;
end;
{ @end $551C70 }

{ @routine $551FDC TfSaveManager_ClearSlotSelection }
procedure TfSaveManager.ClearSlotSelection(SlotIndex: Integer);
begin
  if SlotIndex >= 0 then begin
    (GetByName('Slot' + IntToStr(SlotIndex)) as TPanelGI).SetDepthByName('0');
    if SaveManagerMode = smmSave then GetByName('Slot' + IntToStr(SlotIndex) + 'Edit').MessageLoop.SetFocusedControl(nil);
    with GetByName('Slot' + IntToStr(SlotIndex) + 'BG') as TImageGI do begin
      SetImagePath('GI,Bm.FormSave.' + GiResourceSuffix + 'N');
      SetImageKindX(ikxLeftFill);
      SetImageKindY(ikyTopFill);
      SetActive(not IsSlotEmpty(SlotIndex));
    end;
    RefreshSlot(SlotIndex, False);
  end;
end;
{ @end $551FDC }

{ @routine $552208 TfSaveManager_ScanSaveFiles }
procedure TfSaveManager.ScanSaveFiles;
var
  I, J, Swap: Integer;
  FileObject: TFileEC;
  Count: Integer;
  FileInformation: TByHandleFileInformation;
  Order: array[0..10] of Integer;
  Handle: THandle;
begin
  Count := 0;
  FileObject := TFileEC.Create;
  for I := 0 to 10 do begin
    FileObject.SetFileName(GetSaveSlotPath(I));
    try
      Slots[I].DisplayName := '';
      Slots[I].FileName := '';
      Slots[I].RecencyRank := -1;
      if not FileObject.TryAcquireReadHandle then begin SuppressExceptionLogCopy := True; raise EAbort.Create('Err'); end;
      if FileObject.ReadWideString <> 'RSG' then begin SuppressExceptionLogCopy := True; raise EAbort.Create('Err'); end;
      if ExtractDigitsToIntW(FileObject.ReadWideString) > 10 then begin SuppressExceptionLogCopy := True; raise EAbort.Create('Err'); end;
      Slots[I].DisplayName := FileObject.ReadWideString;
      Slots[I].Turn := StrToInt(AnsiString(FileObject.ReadWideString));
      Slots[I].Money := StrToInt(AnsiString(FileObject.ReadWideString));
      Slots[I].PilotName := FileObject.ReadWideString;
      Slots[I].RaceName := FileObject.ReadWideString;
      if FileObject.ReadWideString <> 'EZ' then begin SuppressExceptionLogCopy := True; raise EAbort.Create('Err'); end;
      Slots[I].FileName := AnsiString(FileObject.GetFileName);
      FileObject.ReleaseHandle;
      Handle := CreateFile(PAnsiChar(GetSaveSlotPath(I)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
      GetFileInformationByHandle(Handle, FileInformation);
      Slots[I].LastWriteTime := Int64(FileInformation.ftLastWriteTime.dwLowDateTime) or (Int64(FileInformation.ftLastWriteTime.dwHighDateTime) shl 32);
      CloseHandle(Handle);
      Order[Count] := I;
      Inc(Count);
    except
      // Native ignores malformed/unreadable headers without resetting the file here.
    end;
  end;
  FileObject.Free;
  for I := 0 to Count - 2 do
    for J := I + 1 to Count - 1 do
      if Slots[Order[I]].LastWriteTime < Slots[Order[J]].LastWriteTime then begin
        Swap := Order[I]; Order[I] := Order[J]; Order[J] := Swap;
      end;
  for I := 0 to Count - 1 do Slots[Order[I]].RecencyRank := I;
end;
{ @end $552208 }

{ @routine $552658 TfSaveManager_IsSlotEmpty }
function TfSaveManager.IsSlotEmpty(SlotIndex: Integer): Boolean;
begin
  Result := Slots[SlotIndex].FileName = '';
end;
{ @end $552658 }

{ @routine $552670 TfSaveManager_GetSaveSlotPath }
function TfSaveManager.GetSaveSlotPath(Slot: Integer): AnsiString;
begin
  if Slot < 10 then Result := 'Save\0' + IntToStr(Slot) + '.sav'
  else Result := 'Save\' + IntToStr(Slot) + '.sav';
end;
{ @end $552670 }

{ @routine $552730 TfSaveManager_FindNewestSlot }
function TfSaveManager.FindNewestSlot: Integer;
var I: Integer;
begin
  Result := -1;
  for I := 0 to 10 do
    if not IsSlotEmpty(I) and (Slots[I].RecencyRank = 0) then begin Result := I; Exit; end;
end;
{ @end $552730 }

{ @routine $552764 TfSaveManager_RefreshAllSlots }
procedure TfSaveManager.RefreshAllSlots;
var I: Integer;
begin
  for I := 0 to 10 do begin end;
end;
{ @end $552764 }

{ @routine $552770 TfSaveManager_ReadSaveVersion }
function TfSaveManager.ReadSaveVersion(FileName: AnsiString): Integer;
var FileObject: TFileEC;
begin
  FileObject := TFileEC.Create;
  FileObject.SetFileName(FileName);
  FileObject.AcquireReadHandle;
  FileObject.TryAcquireReadHandle;
  FileObject.ReadWideString;
  Result := ExtractDigitsToIntW(FileObject.ReadWideString);
  FileObject.ReleaseHandle;
  FileObject.Free;
end;
{ @end $552770 }

{ @routine $552818 TfSaveManager_LoadSavePreview }
procedure TfSaveManager.LoadSavePreview(FileName: AnsiString);
var Image: TGraphBufGI; FileObject: TFileEC; Buffer: TBufEC; Size: Integer;
begin
  Image := GetByName('GameImage') as TGraphBufGI;
  Image.GraphBuf.Clear;
  Image.Invalidate;
  FileObject := TFileEC.Create;
  Buffer := TBufEC.Create;
  FileObject.SetFileName(FileName);
  FileObject.AcquireReadHandle;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadWideString;
  FileObject.ReadBuffer(@Size, SizeOf(Size));
  if Size > 0 then begin
    Buffer.SetSize(Size);
    FileObject.ReadBuffer(Buffer.Data, Size);
  end;
  FileObject.ReleaseHandle;
  if Size > 0 then begin
    Image.GraphBuf.LoadFromBuffer(Buffer);
    Image.GraphBuf.RescaleRgb(Image.ClientSize.X, Image.ClientSize.Y);
    Image.GraphBuf.ConvertRgbTo565;
  end;
  FileObject.Free;
  Buffer.Free;
end;
{ @end $552818 }

{ @routine $5529AC TfSaveManager_SelectMusic }
procedure TfSaveManager.SelectMusic;
begin end;
{ @end $5529AC }

end.

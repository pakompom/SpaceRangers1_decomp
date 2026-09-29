unit aItem;
// Unit bracket (inferred): CODE 0x005D1538..0x005E148F; inclusive evidence, not full bounds.
interface
uses aConst, EC_Struct, EC_Buf, SE_Space, SE_Container, aEFilm;
type
  TImprovementKind = (ikMinor, ikMedium, ikMajor, ikAny); // @size $1
  // Saved tag for TWeapon.Target.
  TWeaponTargetKind = (wtkNone = 0, wtkShip = 1, wtkItem = 2, wtkAsteroid = 3); // @size $01
  TItem = class;
  TEquipment = class;
  THull = class;
  TFuelTanks = class;
  TEngine = class;
  TRadar = class;
  TScaner = class;
  TRepairRobot = class;
  TCargoHook = class;
  TDefGenerator = class;
  TWeapon = class;

  TItem = class(TObjectEx) // @size $34
  public
    GraphObject: TContainerSE; // @offset $4
    Id: Integer; // @offset $8
    ItemType: TItemType; // @offset $C
    Position: TPointF; // @offset $10
    Weight: Integer; // @offset $18
    OwnerId: TOwnerId; // @offset $1C
    Cost: Integer; // @offset $20
    NameOverride: WideString; // @offset $24
    FilmObject: TEFilmObj; // @offset $28
    ScriptItem: TObject; // @offset $2C
    DestroyFlag: Integer; // @offset $30
    function GetCategoryConfigName: WideString; // @addr $5D2A30
    procedure SaveToBuffer(Buffer: TBufEC); virtual; // @addr $5D27A4 @slot $0
    procedure LoadFromBuffer(Buffer: TBufEC); virtual; // @addr $5D2838 @slot $4
    procedure ClearReferences; virtual; // @addr $5D290C @slot $8
    function GetDisplayName: WideString; virtual; abstract; // @slot $C
    function GetShortName: WideString; virtual; // @addr $5D2E1C @slot $10
    function GetInfoText(ColorTag: WideString): WideString; virtual; // @addr $5D2E28 @slot $14
    function GetDescriptionText: WideString; virtual; abstract; // @slot $18
    function GetFullInfoText: WideString; virtual; abstract; // @slot $1C
    function IsBetterThan(Other: TItem): Boolean; virtual; abstract; // @slot $20
    function GetBitmapResourceName: WideString; virtual; abstract; // @slot $24
    constructor Create; // @addr $5D26F4
    function CalculateResaleValue(TradingSkill: TSkillLevel): Integer; // @addr $5D2948
    destructor Destroy; override; // @addr $5D2748
    function GetSmallInfoText: WideString; // @addr $5D2910
    function GetConditionAdjustedCost: Integer; // @addr $5D29F4
    function GetGraphObject: TContainerSE; // @addr $5D2E5C
    function CreateGraphObject: TContainerSE; // @addr $5D2E84
    procedure ReleaseGraphObject; // @addr $5D3718
  end;

  TEquipment = class(TItem) // @size $48
  public
    function NeedsRepair: Boolean; // @addr $5D37D8
    EquippedFlag: Boolean; // @offset $34
    ConditionPercent: Double; // @offset $38
    BrokenFlag: Boolean; // @offset $40
    AssignedSlotData: Cardinal; // @offset $44
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D3730
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D3774
    procedure Equip; // @addr $5D37B4
    procedure Unequip; // @addr $5D37BC
    procedure Repair; virtual; // @addr $5D37C4 @slot $28
    function CalculateRepairCost: Integer; // @addr $5D3858
    procedure Improve(Kind: TImprovementKind); virtual; // @addr $5D42C0 @slot $2C
    function CalculateImprovementCost(Kind: TImprovementKind): Integer; virtual; // @addr $5D42C4 @slot $30
    function HasStandardStats: Boolean; virtual; // @addr $5D4374 @slot $34
    function GetLevel: Integer; // @addr $5D41A8
    function GetConditionText: WideString; // @addr $5D3AC0
    function GetBrokenInBattleText: WideString; // @addr $5D3E58
    function GetBrokenInUseText: WideString; // @addr $5D4004
  end;

  THull = class(TEquipment) // @size $50
  public
    procedure Init(Equipped: Boolean; Capacity: Word; Level: TTechLevel; Owner: TOwnerId); // @addr $5D4378
    function CalculateGeneratedCost: Integer; // @addr $5D44E0
    HullPoints: Integer; // @offset $48
    TechLevel: TTechLevel; // @offset $4C
    Armor: Byte; // @offset $4D
    function GetDisplayName: WideString; override; // @addr $5D45BC
    function GetShortName: WideString; override; // @addr $5D46D8
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D4738
    function GetDescriptionText: WideString; override; // @addr $5D4A1C
    function GetFullInfoText: WideString; override; // @addr $5D4ABC
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D45B8
    function GetBitmapResourceName: WideString; override; // @addr $5D4C38
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D43D0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D4404
    function CalculateGeneratedArmor: Byte; // @addr $5D4438
    function HasStandardStats: Boolean; override; // @addr $5D45A4
    procedure Repair; override; // @addr $5D44F4
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D4508
  end;

  TFuelTanks = class(TEquipment) // @size $54
  public
    TechLevel: TTechLevel; // @offset $48
    Fuel: Integer; // @offset $4C
    Capacity: Byte; // @offset $50
    function GetDisplayName: WideString; override; // @addr $5D4FE8
    function GetShortName: WideString; override; // @addr $5D5160
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D51D8
    function GetDescriptionText: WideString; override; // @addr $5D546C
    function GetFullInfoText: WideString; override; // @addr $5D5590
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D4FB0
    function GetBitmapResourceName: WideString; override; // @addr $5D570C
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D4D38
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D4D6C
    function CalculateGeneratedCapacity: Byte; // @addr $5D4DA0
    function HasStandardStats: Boolean; override; // @addr $5D4F9C
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D4E98
    function CalculateGeneratedCost: Integer; // @addr $5D4E84
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D4CDC
  end;

  TEngine = class(TEquipment) // @size $54
  public
    TechLevel: TTechLevel; // @offset $48
    Speed: Integer; // @offset $4C
    JumpRange: Byte; // @offset $50
    OutputPercent: TPercent; // @offset $51
    function GetDisplayName: WideString; override; // @addr $5D5C70
    function GetShortName: WideString; override; // @addr $5D5DD8
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D5E4C
    function GetDescriptionText: WideString; override; // @addr $5D6188
    function GetFullInfoText: WideString; override; // @addr $5D62A4
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D5C38
    function GetBitmapResourceName: WideString; override; // @addr $5D6420
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D587C
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D58B8
    function CalculateGeneratedSpeed: Integer; // @addr $5D58FC
    function CalculateGeneratedJumpRange: Byte; // @addr $5D590C
    function HasStandardStats: Boolean; override; // @addr $5D5C14
    function CalculateGeneratedCost: Integer; // @addr $5D5A04
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D581C
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D5A14
  end;

  TRadar = class(TEquipment) // @size $50
  public
    TechLevel: TTechLevel; // @offset $48
    Range: Integer; // @offset $4C
    function GetDisplayName: WideString; override; // @addr $5D6864
    function GetShortName: WideString; override; // @addr $5D69C8
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D6A38
    function GetDescriptionText: WideString; override; // @addr $5D6C58
    function GetFullInfoText: WideString; override; // @addr $5D6D74
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D682C
    function GetBitmapResourceName: WideString; override; // @addr $5D6EF0
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D657C
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D65A4
    function CalculateGeneratedRange: Integer; // @addr $5D65D0
    function HasStandardStats: Boolean; override; // @addr $5D6818
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D66A8
    function CalculateGeneratedCost: Integer; // @addr $5D6698
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D6528
  end;

  TScaner = class(TEquipment) // @size $4C
  public
    TechLevel: TTechLevel; // @offset $48
    ScanPower: Byte; // @offset $49
    function GetDisplayName: WideString; override; // @addr $5D7328
    function GetShortName: WideString; override; // @addr $5D7490
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D7504
    function GetDescriptionText: WideString; override; // @addr $5D772C
    function GetFullInfoText: WideString; override; // @addr $5D7848
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D72F0
    function GetBitmapResourceName: WideString; override; // @addr $5D79C4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D7044
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D706C
    function CalculateGeneratedScanPower: Integer; // @addr $5D7094
    function HasStandardStats: Boolean; override; // @addr $5D72D8
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D7180
    function CalculateGeneratedCost: Integer; // @addr $5D716C
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D6FF0
  end;

  TRepairRobot = class(TEquipment) // @size $4C
  public
    TechLevel: TTechLevel; // @offset $48
    RepairPoints: Byte; // @offset $49
    function GetDisplayName: WideString; override; // @addr $5D7DF0
    function GetShortName: WideString; override; // @addr $5D7F70
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D7FEC
    function GetDescriptionText: WideString; override; // @addr $5D824C
    function GetFullInfoText: WideString; override; // @addr $5D8370
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D7DB8
    function GetBitmapResourceName: WideString; override; // @addr $5D84EC
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D7B20
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D7B48
    function CalculateGeneratedRepairPoints: Byte; // @addr $5D7B70
    function HasStandardStats: Boolean; override; // @addr $5D7DA4
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D7C4C
    function CalculateGeneratedCost: Integer; // @addr $5D7C38
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D7ACC
  end;

  TCargoHook = class(TEquipment) // @size $50
  public
    TechLevel: TTechLevel; // @offset $48
    PickupPower: Integer; // @offset $4C
    function GetDisplayName: WideString; override; // @addr $5D891C
    function GetShortName: WideString; override; // @addr $5D8A94
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D8B0C
    function GetDescriptionText: WideString; override; // @addr $5D8D44
    function GetFullInfoText: WideString; override; // @addr $5D8E68
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D88E4
    function GetBitmapResourceName: WideString; override; // @addr $5D8FE4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D8658
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D8680
    function CalculateGeneratedPickupPower: Integer; // @addr $5D86AC
    function HasStandardStats: Boolean; override; // @addr $5D88D0
    function CalculateGeneratedCost: Integer; // @addr $5D8774
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D8604
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D8784
  end;

  TDefGenerator = class(TEquipment) // @size $50
  public
    procedure Improve(Kind: TImprovementKind); override; // @addr $5D92B8
    TechLevel: TTechLevel; // @offset $48
    DamageFactor: Single; // @offset $4C
    function GetDisplayName: WideString; override; // @addr $5D947C
    function GetShortName: WideString; override; // @addr $5D9604
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5D9684
    function GetDescriptionText: WideString; override; // @addr $5D9900
    function GetFullInfoText: WideString; override; // @addr $5D9A28
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5D9444
    function GetBitmapResourceName: WideString; override; // @addr $5D9BA4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D9158
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D9180
    function CalculateGeneratedDamageFactor: Single; // @addr $5D91A8
    function HasStandardStats: Boolean; override; // @addr $5D942C
    procedure Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D90F4
  end;

  TWeapon = class(TEquipment) // @size $5C
  public
    destructor Destroy; override; // @addr $5D9CC4
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5D9D6C
    procedure ClearReferences; override; // @addr $5D9EC4 Resolves serialized ship, item and asteroid target IDs.
    procedure Improve(Kind: TImprovementKind); override; // @addr $5DA174
    TechLevel: TTechLevel; // @offset $48
    Range: Integer; // @offset $4C
    MinDamage: Byte; // @offset $50
    MaxDamage: Byte; // @offset $51
    Target: TObject; // @offset $54
    LoadedTargetKind: TWeaponTargetKind; // @offset $58
    function GetShotDelayFactor: Double; // @addr $5DAC74
    function DealsHullDamage: Boolean; // @addr $5DACB8
    function HasSpecialDamageMode: Boolean; // @addr $5DACD8
    function GetDisplayName: WideString; override; // @addr $5DA5EC
    function GetShortName: WideString; override; // @addr $5DA618
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DA6D0
    function GetDescriptionText: WideString; override; // @addr $5DAA50
    function GetFullInfoText: WideString; override; // @addr $5DAAF8
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5DA55C
    function GetBitmapResourceName: WideString; override; // @addr $5DACF8
    function CalculateGeneratedMinDamage: Integer; // @addr $5D9F3C
    function CalculateGeneratedMaxDamage: Integer; // @addr $5D9F80
    function CalculateGeneratedRange: Integer; // @addr $5D9FC4
    function HasStandardStats: Boolean; override; // @addr $5DA534
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5D9E64
    procedure Init(Kind: TItemType; Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId); // @addr $5D9CEC
  end;

function CalculateGeneratedFuelCapacity(Weight: Cardinal; Level: Integer): Integer; // @addr $5D4DB4

function GetGeneratedDefenseDamageFactor(Level: TTechLevel): Double; // @addr $5D91C0

function DefenseDamageFactorToPercent(Factor: Double): TPercent; // @addr $5D91DC

function CalculateGeneratedFuelTanksCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5D4DFC

function CalculateGeneratedEngineCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer; // @addr $5D594C

function CalculateGeneratedRadarCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer; // @addr $5D65E0

function CalculateGeneratedScanerCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5D70B4

function CalculateGeneratedRepairRobotCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5D7B80

function CalculateGeneratedCargoHookCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer; // @addr $5D86BC

function CalculateGeneratedDefGeneratorCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5D9200

type
  TGoods = class(TItem) // @size $3C
  public
    Quantity: Integer; // @offset $34
    NaturalFlag: Boolean; // @offset $38
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DADA0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DADC8
    function GetDisplayName: WideString; override; // @addr $5DAE28
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DAE64
    function GetDescriptionText: WideString; override; // @addr $5DAF4C
    function GetFullInfoText: WideString; override; // @addr $5DAFF0
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5DADF0
    function GetBitmapResourceName: WideString; override; // @addr $5DB09C
    procedure Init(Kind: TGoodsIndex; Quantity: Integer); // @addr $5DAD78
  end;

type
  TProtoplasm = class(TEquipment) // @size $50
  public
    procedure Init(Count: Integer; Drop: Byte); // @addr $5DB11C
    Quantity: Integer; // @offset $48
    DropFlag: Byte; // @offset $4C
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DB148
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DB170
    function GetDisplayName: WideString; override; // @addr $5DB1D0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DB230
    function GetDescriptionText: WideString; override; // @addr $5DB298
    function GetFullInfoText: WideString; override; // @addr $5DB2EC
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5DB198
    function GetBitmapResourceName: WideString; override; // @addr $5DB398
  end;

type
  TUselessItem = class(TEquipment) // @size $4C
  public
    ConfigBlockName: WideString; // @offset $48
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DB848
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DB864
    function GetDisplayName: WideString; override; // @addr $5DB8C4
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DB9B4
    function GetDescriptionText: WideString; override; // @addr $5DBA8C
    function GetFullInfoText: WideString; override; // @addr $5DBB74
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5DB8C0
    function GetBitmapResourceName: WideString; override; // @addr $5DBCF0
    procedure Init(ConfigName: WideString; Seed: Integer); // @addr $5DB4C8
  end;

type
  TArtefact = class(TEquipment) // @size $48
  public
    function IsBetterThan(Other: TItem): Boolean; override; // @addr $5DC08C
    function GetBitmapResourceName: WideString; override; // @addr $5DC004
    constructor Create; // @addr $5DBFC8
  end;

type
  TArtefactHull = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DC1F0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DC1F8
    function GetDisplayName: WideString; override; // @addr $5DC200
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DC264
    function GetDescriptionText: WideString; override; // @addr $5DC304
    function GetFullInfoText: WideString; override; // @addr $5DC35C
    function GetBitmapResourceName: WideString; override; // @addr $5DC4D8
    procedure Init(Owner: TOwnerId); // @addr $5DC090
  end;

type
  TArtefactFuel = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DC6C0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DC6C8
    function GetDisplayName: WideString; override; // @addr $5DC6D0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DC734
    function GetDescriptionText: WideString; override; // @addr $5DC7D4
    function GetFullInfoText: WideString; override; // @addr $5DC82C
    function GetBitmapResourceName: WideString; override; // @addr $5DC9A8
    procedure Init(Owner: TOwnerId); // @addr $5DC560
  end;

type
  TArtefactSpeed = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DCB90
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DCB98
    function GetDisplayName: WideString; override; // @addr $5DCBA0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DCC08
    function GetDescriptionText: WideString; override; // @addr $5DCCAC
    function GetFullInfoText: WideString; override; // @addr $5DCD04
    function GetBitmapResourceName: WideString; override; // @addr $5DCE80
    procedure Init(Owner: TOwnerId); // @addr $5DCA30
  end;

type
  TArtefactPower = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DD068
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DD070
    function GetDisplayName: WideString; override; // @addr $5DD078
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DD138
    function GetDescriptionText: WideString; override; // @addr $5DD0E0
    function GetFullInfoText: WideString; override; // @addr $5DD1DC
    function GetBitmapResourceName: WideString; override; // @addr $5DD358
    procedure Init(Owner: TOwnerId); // @addr $5DCF08
  end;

type
  TArtefactRadar = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DD540
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DD548
    function GetDisplayName: WideString; override; // @addr $5DD550
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DD5B8
    function GetDescriptionText: WideString; override; // @addr $5DD65C
    function GetFullInfoText: WideString; override; // @addr $5DD6B4
    function GetBitmapResourceName: WideString; override; // @addr $5DD830
    procedure Init(Owner: TOwnerId); // @addr $5DD3E0
  end;

type
  TArtefactScaner = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DDA18
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DDA20
    function GetDisplayName: WideString; override; // @addr $5DDA28
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DDA90
    function GetDescriptionText: WideString; override; // @addr $5DDB34
    function GetFullInfoText: WideString; override; // @addr $5DDB90
    function GetBitmapResourceName: WideString; override; // @addr $5DDD0C
    procedure Init(Owner: TOwnerId); // @addr $5DD8B8
  end;

type
  TArtefactDroid = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DDEF8
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DDF00
    function GetDisplayName: WideString; override; // @addr $5DDF08
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DDF70
    function GetDescriptionText: WideString; override; // @addr $5DE014
    function GetFullInfoText: WideString; override; // @addr $5DE06C
    function GetBitmapResourceName: WideString; override; // @addr $5DE1E8
    procedure Init(Owner: TOwnerId); // @addr $5DDD98
  end;

type
  TArtefactNano = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DE3D0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DE3D8
    function GetDisplayName: WideString; override; // @addr $5DE3E0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DE444
    function GetDescriptionText: WideString; override; // @addr $5DE4E4
    function GetFullInfoText: WideString; override; // @addr $5DE53C
    function GetBitmapResourceName: WideString; override; // @addr $5DE6B8
    procedure Init(Owner: TOwnerId); // @addr $5DE270
  end;

type
  TArtefactHook = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DE8A0
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DE8A8
    function GetDisplayName: WideString; override; // @addr $5DE8B0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DE914
    function GetDescriptionText: WideString; override; // @addr $5DE9B4
    function GetFullInfoText: WideString; override; // @addr $5DEA0C
    function GetBitmapResourceName: WideString; override; // @addr $5DEB88
    procedure Init(Owner: TOwnerId); // @addr $5DE740
  end;

type
  TArtefactDef = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DED70
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DED78
    function GetDisplayName: WideString; override; // @addr $5DED80
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DEDE4
    function GetDescriptionText: WideString; override; // @addr $5DEE84
    function GetFullInfoText: WideString; override; // @addr $5DEED8
    function GetBitmapResourceName: WideString; override; // @addr $5DF054
    procedure Init(Owner: TOwnerId); // @addr $5DEC10
  end;

type
  TArtefactAnalyzer = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DF238
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DF240
    function GetDisplayName: WideString; override; // @addr $5DF248
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DF2B4
    function GetDescriptionText: WideString; override; // @addr $5DF35C
    function GetFullInfoText: WideString; override; // @addr $5DF3BC
    function GetBitmapResourceName: WideString; override; // @addr $5DF538
    procedure Init(Owner: TOwnerId); // @addr $5DF0D8
  end;

type
  TArtefactMiniExpl = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DF728
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DF730
    function GetDisplayName: WideString; override; // @addr $5DF738
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DF7A4
    function GetDescriptionText: WideString; override; // @addr $5DF84C
    function GetFullInfoText: WideString; override; // @addr $5DF8AC
    function GetBitmapResourceName: WideString; override; // @addr $5DFA28
    procedure Init(Owner: TOwnerId); // @addr $5DF5C8
  end;

type
  TArtefactAntigrav = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5DFC18
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5DFC20
    function GetDisplayName: WideString; override; // @addr $5DFC28
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5DFC94
    function GetDescriptionText: WideString; override; // @addr $5DFD3C
    function GetFullInfoText: WideString; override; // @addr $5DFD9C
    function GetBitmapResourceName: WideString; override; // @addr $5DFF18
    procedure Init(Owner: TOwnerId); // @addr $5DFAB8
  end;

type
  TArtefactTransmitter = class(TArtefact) // @size $4C
  public
    Charges: Integer; // @offset $48
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5E0108
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5E0124
    function GetDisplayName: WideString; override; // @addr $5E0140
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5E01B4
    function GetDescriptionText: WideString; override; // @addr $5E02C0
    function GetFullInfoText: WideString; override; // @addr $5E0324
    function GetBitmapResourceName: WideString; override; // @addr $5E04A0
    procedure Init(Owner: TOwnerId); // @addr $5DFFA8
  end;

type
  TArtefactBomb = class(TArtefact) // @size $48
  public
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5E0690
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5E0698
    function GetDisplayName: WideString; override; // @addr $5E06A0
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5E0704
    function GetDescriptionText: WideString; override; // @addr $5E07A4
    function GetFullInfoText: WideString; override; // @addr $5E07FC
    function GetBitmapResourceName: WideString; override; // @addr $5E0978
    procedure Init(Owner: TOwnerId); // @addr $5E0534
  end;

type
  TArtefactTranclucator = class(TArtefact) // @size $4C
  public
    destructor Destroy; override; // @addr $5E0A00
    Ship: TObject; // @offset $48
    procedure SaveToBuffer(Buffer: TBufEC); override; // @addr $5E0C04
    procedure LoadFromBuffer(Buffer: TBufEC); override; // @addr $5E0C2C
    procedure ClearReferences; override; // @addr $5E0C68
    function GetDisplayName: WideString; override; // @addr $5E0C88
    function GetInfoText(ColorTag: WideString): WideString; override; // @addr $5E0D9C
    function GetDescriptionText: WideString; override; // @addr $5E0E4C
    function GetFullInfoText: WideString; override; // @addr $5E0EB4
    function GetBitmapResourceName: WideString; override; // @addr $5E1030
    procedure Init(Owner: TOwnerId; OwnerShip, ExistingShip: TObject); // @addr $5E0A38
  end;

function CalculateGeneratedWeaponCost(ItemType: TItemType; Weight, Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5DA030

function CalculateGeneratedHullCost(Capacity, Level: Cardinal; Owner: TOwnerId): Integer; // @addr $5D4448

function CreateRandomArtefact(Seed: Cardinal; Owner: TOwnerId): TItem; // @addr $5DBDF4
function CreateItemByType(Kind: TItemType): TItem; // @addr $5E10C8 @note "Unsupported kinds allocate an exception without raising and return nil."

function GetItemTypeBitmapPath(Kind: TItemType): WideString; // @addr $5E13DC
implementation
// @unit-initialization $5E1488
// @unit-finalization $5E1458
uses Classes, SE_Container, Math, SysUtils, EC_Str, GR_Main, aMyFunction, Globals, aGalaxy, aPlayer, aShip, aTranclucator, aScript, aAsteroid, EC_Data;

{ @routine $5D26F4 TItem_Create }
constructor TItem.Create;
begin
  inherited Create;
  Id := Galaxy.NextItemId;
  NameOverride := '';
  Inc(Galaxy.NextItemId);
end;
{ @end $5D26F4 }

{ @routine $5D2748 TItem_Destroy }
destructor TItem.Destroy;
begin
  Id := 0;
  if ScriptItem <> nil then begin
    (ScriptItem as TScriptItem).Item := nil;
    ScriptItem := nil;
  end;
  if GraphObject <> nil then begin
    GraphObject.Free;
    GraphObject := nil;
  end;
  inherited Destroy;
end;
{ @end $5D2748 }

{ @routine $5D27A4 TItem_SaveToBuffer }
procedure TItem.SaveToBuffer(Buffer: TBufEC);
begin
  Buffer.AddDWord(Id);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(ItemType)));
  Buffer.AddSingle(Position.X);
  Buffer.AddSingle(Position.Y);
  Buffer.AddIntegerValue(Weight);
  Buffer.AddAnsiChar(AnsiChar(ReadByteValue(OwnerId)));
  Buffer.AddDWord(Cost);
  Buffer.AddIntegerValue(DestroyFlag);
  if NameOverride = '' then Buffer.AddBoolean(False)
  else begin Buffer.AddBoolean(True); Buffer.AddWideStringZ(NameOverride); end;
end;
{ @end $5D27A4 }

{ @routine $5D2838 TItem_LoadFromBuffer }
procedure TItem.LoadFromBuffer(Buffer: TBufEC);
begin
  Id := Buffer.GetUInt32;
  if Galaxy.NextItemId <= Cardinal(Id) then Galaxy.NextItemId := Id + 1;
  WriteByteValue(Buffer.GetByte, ItemType);
  Position.X := Buffer.GetSingle;
  Position.Y := Buffer.GetSingle;
  Weight := Buffer.GetInt32;
  WriteByteValue(Buffer.GetByte, OwnerId);
  Cost := Buffer.GetUInt32;
  DestroyFlag := Buffer.GetInt32;
  if Buffer.GetBoolean then NameOverride := Buffer.ReadWideString;
end;
{ @end $5D2838 }

{ @routine $5D290C TItem_ClearReferences }
procedure TItem.ClearReferences;
begin

end;
{ @end $5D290C }

{ @routine $5D2910 TItem_GetSmallInfoText }
function TItem.GetSmallInfoText: WideString;
begin
  Result := LookupLocalizedTextByKey('Items.SmallInfo');
end;
{ @end $5D2910 }

{ @routine $5D2948 TItem_CalculateResaleValue }
function TItem.CalculateResaleValue(TradingSkill: TSkillLevel): Integer;
begin
  if Self is TEquipment then
    Result := Max(1, Round((Cost - (Self as TEquipment).CalculateRepairCost) * 0.01 * SkillEffectValues[TradingSkill, skTrader]))
  else Result := Round(Cost * 0.01 * SkillEffectValues[TradingSkill, skTrader]);
end;
{ @end $5D2948 }

{ @routine $5D29F4 TItem_GetConditionAdjustedCost }
function TItem.GetConditionAdjustedCost: Integer;
begin
  if Self is TEquipment then Result := Max(1, Cost - (Self as TEquipment).CalculateRepairCost)
  else Result := Cost;
end;
{ @end $5D29F4 }

{ @routine $5D2A30 TItem_GetCategoryConfigName }
function TItem.GetCategoryConfigName: WideString;
begin
  if ItemType = t_Hull then begin Result := 'Hull'; Exit; end;
  if ItemType = t_FuelTanks then Result := 'FuelTanks'
  else if ItemType = t_Engine then Result := 'Engine'
  else if ItemType = t_Radar then Result := 'Radar'
  else if ItemType = t_Scaner then Result := 'Scaner'
  else if ItemType = t_RepairRobot then Result := 'RepairRobot'
  else if ItemType = t_CargoHook then Result := 'CargoHook'
  else if ItemType = t_DefGenerator then Result := 'DefGenerator'
  else if ItemType in WeaponItemTypes then Result := 'Weapon'
  else if ItemType = t_Food then Result := 'Food'
  else if ItemType = t_Medicine then Result := 'Medicine'
  else if ItemType = t_Technics then Result := 'Technics'
  else if ItemType = t_Luxury then Result := 'Luxury'
  else if ItemType = t_Minerals then Result := 'Minerals'
  else if ItemType = t_Alcohol then Result := 'Alcohol'
  else if ItemType = t_Arms then Result := 'Arms'
  else if ItemType = t_Narcotics then Result := 'Narcotics'
  else if ItemType = t_Protoplasm then Result := 'Protoplasm'
  else if ItemType = t_UselessItem then Result := 'UselessItem'
  else if ItemType in ArtefactItemTypes then Result := 'Artefact'
  else begin
    RaiseWideMessage('function TItem.SysName:WideString');
    Result := 'CargoHook';
  end;
end;
{ @end $5D2A30 }

{ @routine $5D2E1C TItem_GetShortName }
function TItem.GetShortName: WideString;
begin
  Result := '';
end;
{ @end $5D2E1C }

{ @routine $5D2E28 TItem_GetInfoText }
function TItem.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := '';
end;
{ @end $5D2E28 }

{ @routine $5D2E5C TItem_GetGraphObject }
function TItem.GetGraphObject: TContainerSE;
begin
  if GraphObject = nil then
  begin
    GraphObject := CreateGraphObject;
    GraphObject.SetPosition(Position);
  end;
  Result := GraphObject;
end;
{ @end $5D2E5C }

{ @routine $5D2E84 TItem_CreateGraphObject }
function TItem.CreateGraphObject: TContainerSE;
begin
  if Self is TArtefactBomb then Result := CreateSpaceObjectByName('Container', 'Item.Bomb', Classes.Point(0, 0)) as TContainerSE
  else if (Self is TUselessItem) and (GameDataConfig.GetBlockByPath('SE.Item').CountBlocks(TUselessItem(Self).ConfigBlockName) > 0) and (OwnerId <> oiKling) then
    Result := CreateSpaceObjectByName('Container', 'Item.' + TUselessItem(Self).ConfigBlockName, Classes.Point(0, 0)) as TContainerSE
  else if (Self is TGoods) and (Self as TGoods).NaturalFlag then
  begin
    if Weight <= 29 then Result := CreateSpaceObjectByName('Container', 'Item.m0_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 59 then Result := CreateSpaceObjectByName('Container', 'Item.m1_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else Result := CreateSpaceObjectByName('Container', 'Item.m2_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE;
  end
  else if (Self is TProtoplasm) and ((Self as TProtoplasm).DropFlag <> 0) then
  begin
    if Weight <= 29 then Result := CreateSpaceObjectByName('Container', 'Item.p0_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 59 then Result := CreateSpaceObjectByName('Container', 'Item.p1_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else Result := CreateSpaceObjectByName('Container', 'Item.p2_' + IntToStr(SeededRandomIntRange(0, 2, Id * 25457)), Classes.Point(0, 0)) as TContainerSE;
  end
  else if OwnerId <> oiKling then
  begin
    if Weight <= 29 then Result := CreateSpaceObjectByName('Container', 'Item.c0_' + IntToStr(SeededRandomIntRange(0, 7, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 59 then Result := CreateSpaceObjectByName('Container', 'Item.c1_' + IntToStr(SeededRandomIntRange(0, 7, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 99 then Result := CreateSpaceObjectByName('Container', 'Item.c2_' + IntToStr(SeededRandomIntRange(0, 7, Id * 25457)), Classes.Point(0, 0)) as TContainerSE
    else Result := CreateSpaceObjectByName('Container', 'Item.c3_' + IntToStr(SeededRandomIntRange(0, 7, Id * 25457)), Classes.Point(0, 0)) as TContainerSE;
  end
  else
  begin
    if Weight <= 29 then Result := CreateSpaceObjectByName('Container', 'Item.k0', Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 59 then Result := CreateSpaceObjectByName('Container', 'Item.k1', Classes.Point(0, 0)) as TContainerSE
    else if Weight <= 99 then Result := CreateSpaceObjectByName('Container', 'Item.k2', Classes.Point(0, 0)) as TContainerSE
    else Result := CreateSpaceObjectByName('Container', 'Item.k3', Classes.Point(0, 0)) as TContainerSE;
  end;
end;
{ @end $5D2E84 }

{ @routine $5D3718 TItem_ReleaseGraphObject }
procedure TItem.ReleaseGraphObject;
begin
  if GraphObject <> nil then
  begin
    GraphObject.Free;
    GraphObject := nil;
  end;
end;
{ @end $5D3718 }

{ @routine $5D3730 TEquipment_SaveToBuffer }
procedure TEquipment.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddBoolean(EquippedFlag);
  Buffer.AddSingle(ConditionPercent);
  Buffer.AddBoolean(BrokenFlag);
  Buffer.AddAnsiChar(AnsiChar(AssignedSlotData));
end;
{ @end $5D3730 }

{ @routine $5D3774 TEquipment_LoadFromBuffer }
procedure TEquipment.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  EquippedFlag := Buffer.GetBoolean;
  ConditionPercent := Buffer.GetSingle;
  BrokenFlag := Buffer.GetBoolean;
  AssignedSlotData := Buffer.GetByte;
end;
{ @end $5D3774 }

{ @routine $5D37B4 TEquipment_Equip }
procedure TEquipment.Equip;
begin
  EquippedFlag := True;
end;
{ @end $5D37B4 }

{ @routine $5D37BC TEquipment_Unequip }
procedure TEquipment.Unequip;
begin
  EquippedFlag := False;
end;
{ @end $5D37BC }

{ @routine $5D37C4 TEquipment_Repair }
procedure TEquipment.Repair;
begin
  ConditionPercent := 100;
  BrokenFlag := False;
end;
{ @end $5D37C4 }

{ @routine $5D37D8 TEquipment_NeedsRepair }
function TEquipment.NeedsRepair: Boolean;
begin
  if ItemType = t_Hull then Result := (Self as THull).HullPoints < (Self as THull).Weight
  else Result := (ItemType in (RepairableEquipmentTypes + RepairableArtefactTypes)) and (ConditionPercent < 90);
end;
{ @end $5D37D8 }

{ @routine $5D3858 TEquipment_CalculateRepairCost }
function TEquipment.CalculateRepairCost: Integer;
var DamagePercent: Double;
begin
  if ItemType = t_Protoplasm then
  begin
    Result := 0;
    Exit;
  end;
  if ItemType = t_Hull then
  begin
    Result := 0;
    if (Self as THull).Weight - (Self as THull).HullPoints <> 0 then
    begin
      DamagePercent := 100 / (Self as THull).Weight * ((Self as THull).Weight - (Self as THull).HullPoints);
      Result := RoundAndTruncateToTens((Cost div 40) / 100 * DamagePercent + 10);
    end;
  end
  else if ItemType in RepairableEquipmentTypes then
  begin
    if ConditionPercent = 100 then Result := 0
    else Result := RoundAndTruncateToTens((100 - Round(ConditionPercent)) * ((Cost div 10) / 100) + Cost div 20 + 10);
    if BrokenFlag then Result := Round(Result * 1.3);
  end
  else if ItemType in RepairableArtefactTypes then
  begin
    if ConditionPercent = 100 then Result := 0
    else Result := RoundAndTruncateToTens((100 - Round(ConditionPercent)) * ((Cost div 5) / 100) + Cost div 10 + 10);
    if BrokenFlag then Result := Round(Result * 1.3);
    Result := Result * 2;
  end
  else Result := 0;
end;

{ @end $5D3858 }

{ @routine $5D3AC0 TEquipment_GetConditionText }
function TEquipment.GetConditionText: WideString;
begin
  if BrokenFlag then
  begin
    case ItemType of
      t_FuelTanks..t_DefGenerator: Result := WrapTextInColor(#13#10 + LocalizedText('Items.' + ItemTypeNames[ItemType] + '.Broken'), RedColorTag);
      t_PhotonGun..t_EyesOfMachpella: Result := WrapTextInColor(#13#10 + LocalizedText('Items.Weapon.Broken'), RedColorTag);
      t_ArtefactHull..t_ArtefactTransmitter: Result := WrapTextInColor(#13#10 + LocalizedText('Items.' + ItemTypeNames[ItemType] + '.Broken'), RedColorTag);
    else Result := '';
    end;
  end
  else if Self is TArtefact then
  begin
    if (ItemType = t_ArtefactTransmitter) and ((Self as TArtefactTransmitter).Charges = 0) then
      Result := WrapTextInColor(#13#10 + LocalizedText('Items.' + ItemTypeNames[ItemType] + '.Broken'), YellowColorTag)
    else Result := '';
  end
  else if ConditionPercent < 20 then Result := WrapTextInColor(#13#10 + LocalizedText('Items.Equpments.SmallDuration'), YellowColorTag)
  else if ConditionPercent < 50 then Result := WrapTextInColor(#13#10 + LocalizedText('Items.Equpments.AverageDuration'), '')
  else Result := '';
end;
{ @end $5D3AC0 }

{ @routine $5D3E58 TEquipment_GetBrokenInBattleText }
function TEquipment.GetBrokenInBattleText: WideString;
begin
  case ItemType of
    t_FuelTanks..t_DefGenerator: Result := LocalizedText('Items.' + ItemTypeNames[ItemType] + '.BrokenInBattle');
    t_PhotonGun..t_EyesOfMachpella: Result := FormatText1(LocalizedText('Items.Weapon.BrokenInBattle'), HighlightColorTag, '<Name>', GetDisplayName);
    t_ArtefactHull..t_ArtefactAntigrav: Result := LocalizedText('Items.' + ItemTypeNames[ItemType] + '.BrokenInBattle');
  else Result := '';
  end;
end;
{ @end $5D3E58 }

{ @routine $5D4004 TEquipment_GetBrokenInUseText }
function TEquipment.GetBrokenInUseText: WideString;
begin
  case ItemType of
    t_FuelTanks..t_DefGenerator: Result := LocalizedText('Items.' + ItemTypeNames[ItemType] + '.BrokenInUse');
    t_PhotonGun..t_EyesOfMachpella: Result := FormatText1(LocalizedText('Items.Weapon.BrokenInUse'), HighlightColorTag, '<Name>', GetDisplayName);
    t_ArtefactHull..t_ArtefactAntigrav: Result := LocalizedText('Items.' + ItemTypeNames[ItemType] + '.BrokenInUse');
  else Result := '';
  end;
end;
{ @end $5D4004 }

{ @routine $5D41A8 TEquipment_GetLevel }
function TEquipment.GetLevel: Integer;
begin
  case ItemType of
    t_Hull: Result := (Self as THull).TechLevel - 1;
    t_FuelTanks: Result := (Self as TFuelTanks).TechLevel - 1;
    t_Engine: Result := (Self as TEngine).TechLevel - 1;
    t_Radar: Result := (Self as TRadar).TechLevel - 1;
    t_Scaner: Result := (Self as TScaner).TechLevel - 1;
    t_RepairRobot: Result := (Self as TRepairRobot).TechLevel - 1;
    t_CargoHook: Result := (Self as TCargoHook).TechLevel - 1;
    t_DefGenerator: Result := (Self as TDefGenerator).TechLevel - 1;
    t_PhotonGun..t_EyesOfMachpella: Result := (Self as TWeapon).TechLevel - 1;
  else Result := 0;
  end;
end;
{ @end $5D41A8 }

{ @routine $5D42C0 TEquipment_Improve }
procedure TEquipment.Improve(Kind: TImprovementKind);
begin
end;
{ @end $5D42C0 }

{ @routine $5D42C4 TEquipment_CalculateImprovementCost }
function TEquipment.CalculateImprovementCost(Kind: TImprovementKind): Integer;
begin
  case Kind of
    ikMinor: Result := RoundAndTruncateToTens(Cost * 0.3);
    ikMedium: Result := RoundAndTruncateToTens(Cost * 0.6);
    ikMajor: Result := RoundAndTruncateToTens(Cost * 1.2);
  else
    RaiseWideMessage('Косяк в улучшении');
    Result := 0;
  end;
end;
{ @end $5D42C4 }

{ @routine $5D4374 TEquipment_HasStandardStats }
function TEquipment.HasStandardStats: Boolean;
begin
  Result := True;
end;
{ @end $5D4374 }

{ @routine $5D4378 THull_Init }
procedure THull.Init(Equipped: Boolean; Capacity: Word; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_Hull;
  if Equipped then Equip else Unequip;
  Weight := Capacity;
  HullPoints := Capacity;
  TechLevel := Level;
  OwnerId := Owner;
  Armor := CalculateGeneratedArmor;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D4378 }

{ @routine $5D43D0 THull_SaveToBuffer }
procedure THull.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddWideChar(WideChar(HullPoints));
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddAnsiChar(AnsiChar(Armor));
end;
{ @end $5D43D0 }

{ @routine $5D4404 THull_LoadFromBuffer }
procedure THull.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  HullPoints := Buffer.GetWord;
  TechLevel := Buffer.GetByte;
  Armor := Buffer.GetByte;
end;
{ @end $5D4404 }

{ @routine $5D4438 THull_CalculateGeneratedArmor }
function THull.CalculateGeneratedArmor: Byte;
begin
  Result := HullArmorByLevel[TechLevel];
end;
{ @end $5D4438 }

{ @routine $5D4448 CalculateGeneratedHullCost }
function CalculateGeneratedHullCost(Capacity, Level: Cardinal; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 4) * RemapClamped(Capacity, 250, 1000, 1, 50) * 500);
end;
{ @end $5D4448 }

{ @routine $5D44E0 THull_CalculateGeneratedCost }
function THull.CalculateGeneratedCost: Integer;
begin Result := CalculateGeneratedHullCost(Weight, TechLevel, OwnerId); end;
{ @end $5D44E0 }

{ @routine $5D44F4 THull_Repair }
procedure THull.Repair;
begin
  inherited Repair;
  HullPoints := Weight;
end;
{ @end $5D44F4 }

{ @routine $5D4508 THull_Improve }
procedure THull.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: Inc(Armor, SeededRandomIntRange(1, 3, Id * 254571));
    ikMedium: Inc(Armor, SeededRandomIntRange(2, 5, Id * 254571));
    ikMajor: Inc(Armor, SeededRandomIntRange(4, 7, Id * 254571));
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D4508 }

{ @routine $5D45A4 THull_HasStandardStats }
function THull.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedArmor = Armor;
end;
{ @end $5D45A4 }

{ @routine $5D45B8 THull_IsBetterThan }
function THull.IsBetterThan(Other: TItem): Boolean;
begin
  Result := False;
end;
{ @end $5D45B8 }

{ @routine $5D45BC THull_GetDisplayName }
function THull.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else begin
    TypeName := LocalizedText('Items.Hull.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.Hull.Name'), '<Type>', TypeName, '');
  end;
end;
{ @end $5D45BC }

{ @routine $5D46D8 THull_GetShortName }
function THull.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.Hull.ShortName');
end;
{ @end $5D46D8 }

{ @routine $5D4738 THull_GetInfoText }
function THull.GetInfoText(ColorTag: WideString): WideString;
var Text, HealthColor: WideString;
begin
  Text := LocalizedText('Items.Hull.Text');
  if HullPoints <= Weight / 2 then HealthColor := YellowColorTag
  else HealthColor := ColorTag;
  ReplaceTextToken(Text, '<Size>', IntToStr(HullPoints), HealthColor);
  ReplaceTextToken(Text, '<MaxSize>', IntToStr(Weight), ColorTag);
  if HasStandardStats then ReplaceTextToken(Text, '<HitProtect>', IntToStr(Armor), ColorTag)
  else ReplaceTextToken(Text, '<HitProtect>', IntToStr(CalculateGeneratedArmor) +
    WrapTextInColor('+' + IntToStr(Armor - CalculateGeneratedArmor), GreenColorTag), ColorTag);
  Result := Text;
end;
{ @end $5D4738 }

{ @routine $5D4A1C THull_GetDescriptionText }
function THull.GetDescriptionText: WideString;
begin
  Result := LocalizedText('Items.Hull.Description.' + IntToStr(TechLevel));
end;
{ @end $5D4A1C }

{ @routine $5D4ABC THull_GetFullInfoText }
function THull.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D4ABC }

{ @routine $5D4C38 THull_GetBitmapResourceName }
function THull.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'Hull' + OwnerInfo[OwnerId].InternalName + '_';
end;
{ @end $5D4C38 }

{ @routine $5D4CDC TFuelTanks_Init }
procedure TFuelTanks.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_FuelTanks;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  Capacity := CalculateGeneratedCapacity;
  Fuel := Capacity;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D4CDC }

{ @routine $5D4D38 TFuelTanks_SaveToBuffer }
procedure TFuelTanks.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddWideChar(WideChar(Fuel));
  Buffer.AddAnsiChar(AnsiChar(Capacity));
end;
{ @end $5D4D38 }

{ @routine $5D4D6C TFuelTanks_LoadFromBuffer }
procedure TFuelTanks.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  Fuel := Buffer.GetWord;
  Capacity := Buffer.GetByte;
end;
{ @end $5D4D6C }

{ @routine $5D4DA0 TFuelTanks_CalculateGeneratedCapacity }
function TFuelTanks.CalculateGeneratedCapacity: Byte;
begin
  Result := CalculateGeneratedFuelCapacity(Weight, TechLevel);
end;
{ @end $5D4DA0 }

{ @routine $5D4DB4 CalculateGeneratedFuelCapacity }
function CalculateGeneratedFuelCapacity(Weight: Cardinal; Level: Integer): Integer;
begin
  Result := Round(Weight / 40 * 20 + FuelCapacityByLevel[Level]);
end;
{ @end $5D4DB4 }

{ @routine $5D4DFC CalculateGeneratedFuelTanksCost }
function CalculateGeneratedFuelTanksCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(Weight / 40 * RemapClamped(Level, 1, 8, 1, 32) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D4DFC }

{ @routine $5D4E84 TFuelTanks_CalculateGeneratedCost }
function TFuelTanks.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedFuelTanksCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D4E84 }

{ @routine $5D4E98 TFuelTanks_Improve }
procedure TFuelTanks.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: Capacity := Round(Capacity * SeededRandomFloatRange(Id * 254571, 0.05, 0.1)) + Capacity + 1;
    ikMedium: Capacity := Round(Capacity * SeededRandomFloatRange(Id * 254571, 0.1, 0.15)) + Capacity + 3;
    ikMajor: Capacity := Round(Capacity * SeededRandomFloatRange(Id * 254571, 0.15, 0.2)) + Capacity + 5;
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D4E98 }

{ @routine $5D4F9C TFuelTanks_HasStandardStats }
function TFuelTanks.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedCapacity = Capacity;
end;
{ @end $5D4F9C }

{ @routine $5D4FB0 TFuelTanks_IsBetterThan }
function TFuelTanks.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TFuelTanks then Result := (Other as TFuelTanks).Cost < Cost
  else Result := False;
end;
{ @end $5D4FB0 }

{ @routine $5D4FE8 TFuelTanks_GetDisplayName }
function TFuelTanks.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.FuelTanks.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.FuelTanks.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.FuelTanks.KlingName');
end;
{ @end $5D4FE8 }

{ @routine $5D5160 TFuelTanks_GetShortName }
function TFuelTanks.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.FuelTanks.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D5160 }

{ @routine $5D51D8 TFuelTanks_GetInfoText }
function TFuelTanks.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.FuelTanks.Text')
  else Text := LocalizedText('Items.FuelTanks.KlingText');
  ReplaceTextToken(Text, '<Fuel>', IntToStr(Fuel), ColorTag);
  if HasStandardStats then ReplaceTextToken(Text, '<Capacity>', IntToStr(Capacity), ColorTag)
  else ReplaceTextToken(Text, '<Capacity>', IntToStr(CalculateGeneratedCapacity) + WrapTextInColor('+' + IntToStr(Capacity - CalculateGeneratedCapacity), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D51D8 }

{ @routine $5D546C TFuelTanks_GetDescriptionText }
function TFuelTanks.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.FuelTanks.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.FuelTanks.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D546C }

{ @routine $5D5590 TFuelTanks_GetFullInfoText }
function TFuelTanks.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D5590 }

{ @routine $5D570C TFuelTanks_GetBitmapResourceName }
function TFuelTanks.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'FuelTanks' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'FuelTanksKling0';
end;
{ @end $5D570C }

{ @routine $5D581C TEngine_Init }
procedure TEngine.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_Engine;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  Speed := CalculateGeneratedSpeed;
  JumpRange := CalculateGeneratedJumpRange;
  OutputPercent := 100;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D581C }

{ @routine $5D587C TEngine_SaveToBuffer }
procedure TEngine.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddWideChar(WideChar(Speed));
  Buffer.AddAnsiChar(AnsiChar(JumpRange));
  Buffer.AddAnsiChar(AnsiChar(OutputPercent));
end;
{ @end $5D587C }

{ @routine $5D58B8 TEngine_LoadFromBuffer }
procedure TEngine.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  Speed := Buffer.GetWord;
  JumpRange := Buffer.GetByte;
  OutputPercent := Buffer.GetByte;
  ItemType := t_Engine;
end;
{ @end $5D58B8 }

{ @routine $5D58FC TEngine_CalculateGeneratedSpeed }
function TEngine.CalculateGeneratedSpeed: Integer;
begin
  Result := EngineSpeedByLevel[TechLevel];
end;
{ @end $5D58FC }

{ @routine $5D590C TEngine_CalculateGeneratedJumpRange }
function TEngine.CalculateGeneratedJumpRange: Byte;
begin
  Result := Round(EngineSpeedByLevel[TechLevel] * 0.05 + 1);
end;
{ @end $5D590C }

{ @routine $5D594C CalculateGeneratedEngineCost }
function CalculateGeneratedEngineCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(40 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D594C }

{ @routine $5D5A04 TEngine_CalculateGeneratedCost }
function TEngine.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedEngineCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D5A04 }

{ @routine $5D5A14 TEngine_Improve }
procedure TEngine.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  if SeededRandomUnitFloat(Galaxy.CurrentTurn * (Ord(Kind) + 1) * Id) < 0.5 then
    case Kind of
      ikMinor: Inc(Speed, RoundAndTruncateToTens(Speed * SeededRandomFloatRange(Id * 374571, 0.05, 0.01) + SeededRandomIntRange(10, 30, Id * 254571)));
      ikMedium: Inc(Speed, RoundAndTruncateToTens(Speed * SeededRandomFloatRange(Id * 374571, 0.05, 0.01) + SeededRandomIntRange(30, 60, Id * 254571)));
      ikMajor: Inc(Speed, RoundAndTruncateToTens(Speed * SeededRandomFloatRange(Id * 374571, 0.05, 0.01) + SeededRandomIntRange(50, 80, Id * 254571)));
    end
  else
    case Kind of
      ikMinor: Inc(JumpRange, SeededRandomIntRange(1, 4, Id * 254571));
      ikMedium: Inc(JumpRange, SeededRandomIntRange(3, 6, Id * 254571));
      ikMajor: Inc(JumpRange, SeededRandomIntRange(5, 9, Id * 254571));
    end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D5A14 }

{ @routine $5D5C14 TEngine_HasStandardStats }
function TEngine.HasStandardStats: Boolean;
begin
  Result := (CalculateGeneratedSpeed = Speed) and (CalculateGeneratedJumpRange = JumpRange);
end;
{ @end $5D5C14 }

{ @routine $5D5C38 TEngine_IsBetterThan }
function TEngine.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TEngine then Result := (Other as TEngine).Cost < Cost
  else Result := False;
end;
{ @end $5D5C38 }

{ @routine $5D5C70 TEngine_GetDisplayName }
function TEngine.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.Engine.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.Engine.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.Engine.KlingName');
end;
{ @end $5D5C70 }

{ @routine $5D5DD8 TEngine_GetShortName }
function TEngine.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.Engine.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D5DD8 }

{ @routine $5D5E4C TEngine_GetInfoText }
function TEngine.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.Engine.Text')
  else Text := LocalizedText('Items.Engine.KlingText');
  if Speed = CalculateGeneratedSpeed then ReplaceTextToken(Text, '<Speed>', IntToStr(Speed), ColorTag)
  else ReplaceTextToken(Text, '<Speed>', IntToStr(CalculateGeneratedSpeed) + WrapTextInColor('+' + IntToStr(Speed - CalculateGeneratedSpeed), GreenColorTag), ColorTag);
  if JumpRange = CalculateGeneratedJumpRange then ReplaceTextToken(Text, '<Parsec>', IntToStr(JumpRange), ColorTag)
  else ReplaceTextToken(Text, '<Parsec>', IntToStr(CalculateGeneratedJumpRange) + WrapTextInColor('+' + IntToStr(JumpRange - CalculateGeneratedJumpRange), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D5E4C }

{ @routine $5D6188 TEngine_GetDescriptionText }
function TEngine.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.Engine.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.Engine.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D6188 }

{ @routine $5D62A4 TEngine_GetFullInfoText }
function TEngine.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D62A4 }

{ @routine $5D6420 TEngine_GetBitmapResourceName }
function TEngine.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'Engine' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'EngineKling0';
end;
{ @end $5D6420 }

{ @routine $5D6528 TRadar_Init }
procedure TRadar.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_Radar;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  Range := CalculateGeneratedRange;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D6528 }

{ @routine $5D657C TRadar_SaveToBuffer }
procedure TRadar.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddWideChar(WideChar(Range));
end;
{ @end $5D657C }

{ @routine $5D65A4 TRadar_LoadFromBuffer }
procedure TRadar.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  Range := Buffer.GetWord;
end;
{ @end $5D65A4 }

{ @routine $5D65D0 TRadar_CalculateGeneratedRange }
function TRadar.CalculateGeneratedRange: Integer;
begin
  Result := RadarRangeByLevel[TechLevel];
end;
{ @end $5D65D0 }

{ @routine $5D65E0 CalculateGeneratedRadarCost }
function CalculateGeneratedRadarCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(30 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D65E0 }

{ @routine $5D6698 TRadar_CalculateGeneratedCost }
function TRadar.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedRadarCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D6698 }

{ @routine $5D66A8 TRadar_Improve }
procedure TRadar.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.05, 0.1) + SeededRandomIntRange(100, 200, Id * 254571)));
    ikMedium: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.05, 0.1) + SeededRandomIntRange(300, 400, Id * 254571)));
    ikMajor: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.05, 0.1) + SeededRandomIntRange(400, 500, Id * 254571)));
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D66A8 }

{ @routine $5D6818 TRadar_HasStandardStats }
function TRadar.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedRange = Range;
end;
{ @end $5D6818 }

{ @routine $5D682C TRadar_IsBetterThan }
function TRadar.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TRadar then Result := (Other as TRadar).Cost < Cost
  else Result := False;
end;
{ @end $5D682C }

{ @routine $5D6864 TRadar_GetDisplayName }
function TRadar.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.Radar.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.Radar.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.Radar.KlingName');
end;
{ @end $5D6864 }

{ @routine $5D69C8 TRadar_GetShortName }
function TRadar.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.Radar.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D69C8 }

{ @routine $5D6A38 TRadar_GetInfoText }
function TRadar.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.Radar.Text')
  else Text := LocalizedText('Items.Radar.KlingText');
  if HasStandardStats then ReplaceTextToken(Text, '<Radius>', IntToStr(Range), ColorTag)
  else ReplaceTextToken(Text, '<Radius>', IntToStr(CalculateGeneratedRange) + WrapTextInColor('+' + IntToStr(Range - CalculateGeneratedRange), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D6A38 }

{ @routine $5D6C58 TRadar_GetDescriptionText }
function TRadar.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.Radar.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.Radar.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D6C58 }

{ @routine $5D6D74 TRadar_GetFullInfoText }
function TRadar.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D6D74 }

{ @routine $5D6EF0 TRadar_GetBitmapResourceName }
function TRadar.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'Radar' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'RadarKling0';
end;
{ @end $5D6EF0 }

{ @routine $5D6FF0 TScaner_Init }
procedure TScaner.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_Scaner;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  ScanPower := CalculateGeneratedScanPower;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D6FF0 }

{ @routine $5D7044 TScaner_SaveToBuffer }
procedure TScaner.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddAnsiChar(AnsiChar(ScanPower));
end;
{ @end $5D7044 }

{ @routine $5D706C TScaner_LoadFromBuffer }
procedure TScaner.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  ScanPower := Buffer.GetByte;
end;
{ @end $5D706C }

{ @routine $5D7094 TScaner_CalculateGeneratedScanPower }
function TScaner.CalculateGeneratedScanPower: Integer;
begin
  Result := (DefenseDamageFactorToPercent(GetGeneratedDefenseDamageFactor(TechLevel))) + 1;
end;
{ @end $5D7094 }

{ @routine $5D70B4 CalculateGeneratedScanerCost }
function CalculateGeneratedScanerCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(30 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D70B4 }

{ @routine $5D716C TScaner_CalculateGeneratedCost }
function TScaner.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedScanerCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D716C }

{ @routine $5D7180 TScaner_Improve }
procedure TScaner.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: ScanPower := ScanPower + Round(ScanPower * SeededRandomFloatRange(Id * 254571, 0.05, 0.1)) + SeededRandomIntRange(1, 3, Id * 354571);
    ikMedium: ScanPower := ScanPower + Round(ScanPower * SeededRandomFloatRange(Id * 254571, 0.05, 0.1)) + SeededRandomIntRange(3, 5, Id * 354571);
    ikMajor: ScanPower := ScanPower + Round(ScanPower * SeededRandomFloatRange(Id * 254571, 0.05, 0.1)) + SeededRandomIntRange(5, 7, Id * 354571);
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D7180 }

{ @routine $5D72D8 TScaner_HasStandardStats }
function TScaner.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedScanPower = ScanPower;
end;
{ @end $5D72D8 }

{ @routine $5D72F0 TScaner_IsBetterThan }
function TScaner.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TScaner then Result := (Other as TScaner).Cost < Cost
  else Result := False;
end;
{ @end $5D72F0 }

{ @routine $5D7328 TScaner_GetDisplayName }
function TScaner.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.Scaner.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.Scaner.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.Scaner.KlingName');
end;
{ @end $5D7328 }

{ @routine $5D7490 TScaner_GetShortName }
function TScaner.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.Scaner.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D7490 }

{ @routine $5D7504 TScaner_GetInfoText }
function TScaner.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.Scaner.Text')
  else Text := LocalizedText('Items.Scaner.KlingText');
  if HasStandardStats then ReplaceTextToken(Text, '<Percent>', IntToStr(ScanPower), ColorTag)
  else ReplaceTextToken(Text, '<Percent>', IntToStr(CalculateGeneratedScanPower) + WrapTextInColor('+' + IntToStr(ScanPower - CalculateGeneratedScanPower), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D7504 }

{ @routine $5D772C TScaner_GetDescriptionText }
function TScaner.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.Scaner.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.Scaner.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D772C }

{ @routine $5D7848 TScaner_GetFullInfoText }
function TScaner.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D7848 }

{ @routine $5D79C4 TScaner_GetBitmapResourceName }
function TScaner.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'Scaner' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'ScanerKling0';
end;
{ @end $5D79C4 }

{ @routine $5D7ACC TRepairRobot_Init }
procedure TRepairRobot.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_RepairRobot;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  RepairPoints := CalculateGeneratedRepairPoints;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D7ACC }

{ @routine $5D7B20 TRepairRobot_SaveToBuffer }
procedure TRepairRobot.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddAnsiChar(AnsiChar(RepairPoints));
end;
{ @end $5D7B20 }

{ @routine $5D7B48 TRepairRobot_LoadFromBuffer }
procedure TRepairRobot.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  RepairPoints := Buffer.GetByte;
end;
{ @end $5D7B48 }

{ @routine $5D7B70 TRepairRobot_CalculateGeneratedRepairPoints }
function TRepairRobot.CalculateGeneratedRepairPoints: Byte;
begin
  Result := RepairPointsByLevel[TechLevel];
end;
{ @end $5D7B70 }

{ @routine $5D7B80 CalculateGeneratedRepairRobotCost }
function CalculateGeneratedRepairRobotCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(40 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D7B80 }

{ @routine $5D7C38 TRepairRobot_CalculateGeneratedCost }
function TRepairRobot.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedRepairRobotCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D7C38 }

{ @routine $5D7C4C TRepairRobot_Improve }
procedure TRepairRobot.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: RepairPoints := RepairPoints + Round(RepairPoints * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)) + SeededRandomIntRange(1, 4, Id * 354571);
    ikMedium: RepairPoints := RepairPoints + Round(RepairPoints * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)) + SeededRandomIntRange(4, 7, Id * 354571);
    ikMajor: RepairPoints := RepairPoints + Round(RepairPoints * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)) + SeededRandomIntRange(7, 10, Id * 354571);
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D7C4C }

{ @routine $5D7DA4 TRepairRobot_HasStandardStats }
function TRepairRobot.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedRepairPoints = RepairPoints;
end;
{ @end $5D7DA4 }

{ @routine $5D7DB8 TRepairRobot_IsBetterThan }
function TRepairRobot.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TRepairRobot then Result := (Other as TRepairRobot).Cost < Cost
  else Result := False;
end;
{ @end $5D7DB8 }

{ @routine $5D7DF0 TRepairRobot_GetDisplayName }
function TRepairRobot.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.RepairRobot.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.RepairRobot.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.RepairRobot.KlingName');
end;
{ @end $5D7DF0 }

{ @routine $5D7F70 TRepairRobot_GetShortName }
function TRepairRobot.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.RepairRobot.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D7F70 }

{ @routine $5D7FEC TRepairRobot_GetInfoText }
function TRepairRobot.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.RepairRobot.Text')
  else Text := LocalizedText('Items.RepairRobot.KlingText');
  if HasStandardStats then ReplaceTextToken(Text, '<RecoverHitPoints>', IntToStr(RepairPoints), ColorTag)
  else ReplaceTextToken(Text, '<RecoverHitPoints>', IntToStr(CalculateGeneratedRepairPoints) + WrapTextInColor('+' + IntToStr(RepairPoints - CalculateGeneratedRepairPoints), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D7FEC }

{ @routine $5D824C TRepairRobot_GetDescriptionText }
function TRepairRobot.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.RepairRobot.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.RepairRobot.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D824C }

{ @routine $5D8370 TRepairRobot_GetFullInfoText }
function TRepairRobot.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D8370 }

{ @routine $5D84EC TRepairRobot_GetBitmapResourceName }
function TRepairRobot.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'RepairRobot' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'RepairRobotKling0';
end;
{ @end $5D84EC }

{ @routine $5D8604 TCargoHook_Init }
procedure TCargoHook.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_CargoHook;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  PickupPower := CalculateGeneratedPickupPower;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedCost;
end;
{ @end $5D8604 }

{ @routine $5D8658 TCargoHook_SaveToBuffer }
procedure TCargoHook.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddWideChar(WideChar(PickupPower));
end;
{ @end $5D8658 }

{ @routine $5D8680 TCargoHook_LoadFromBuffer }
procedure TCargoHook.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  PickupPower := Buffer.GetWord;
end;
{ @end $5D8680 }

{ @routine $5D86AC TCargoHook_CalculateGeneratedPickupPower }
function TCargoHook.CalculateGeneratedPickupPower: Integer;
begin
  Result := CargoHookPowerByLevel[TechLevel];
end;
{ @end $5D86AC }

{ @routine $5D86BC CalculateGeneratedCargoHookCost }
function CalculateGeneratedCargoHookCost(Weight: Cardinal; Level: TTechLevel; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(40 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D86BC }

{ @routine $5D8774 TCargoHook_CalculateGeneratedCost }
function TCargoHook.CalculateGeneratedCost: Integer;
begin
  Result := CalculateGeneratedCargoHookCost(Weight, TechLevel, OwnerId);
end;
{ @end $5D8774 }

{ @routine $5D8784 TCargoHook_Improve }
procedure TCargoHook.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: PickupPower := SeededRandomIntRange(5, 10, Id * 354571) + (PickupPower + Round(PickupPower * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)));
    ikMedium: PickupPower := SeededRandomIntRange(10, 15, Id * 354571) + (PickupPower + Round(PickupPower * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)));
    ikMajor: PickupPower := SeededRandomIntRange(15, 20, Id * 354571) + (PickupPower + Round(PickupPower * SeededRandomFloatRange(Id * 254571, 0.07, 0.12)));
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D8784 }

{ @routine $5D88D0 TCargoHook_HasStandardStats }
function TCargoHook.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedPickupPower = PickupPower;
end;
{ @end $5D88D0 }

{ @routine $5D88E4 TCargoHook_IsBetterThan }
function TCargoHook.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TCargoHook then Result := (Other as TCargoHook).Cost < Cost
  else Result := False;
end;
{ @end $5D88E4 }

{ @routine $5D891C TCargoHook_GetDisplayName }
function TCargoHook.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.CargoHook.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.CargoHook.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.CargoHook.KlingName');
end;
{ @end $5D891C }

{ @routine $5D8A94 TCargoHook_GetShortName }
function TCargoHook.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.CargoHook.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D8A94 }

{ @routine $5D8B0C TCargoHook_GetInfoText }
function TCargoHook.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.CargoHook.Text')
  else Text := LocalizedText('Items.CargoHook.KlingText');
  if HasStandardStats then ReplaceTextToken(Text, '<PickUpSize>', IntToStr(PickupPower), ColorTag)
  else ReplaceTextToken(Text, '<PickUpSize>', IntToStr(CalculateGeneratedPickupPower) + WrapTextInColor('+' + IntToStr(PickupPower - CalculateGeneratedPickupPower), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D8B0C }

{ @routine $5D8D44 TCargoHook_GetDescriptionText }
function TCargoHook.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.CargoHook.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.CargoHook.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D8D44 }

{ @routine $5D8E68 TCargoHook_GetFullInfoText }
function TCargoHook.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D8E68 }

{ @routine $5D8FE4 TCargoHook_GetBitmapResourceName }
function TCargoHook.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'CargoHook' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'CargoHookKling0';
end;
{ @end $5D8FE4 }

{ @routine $5D90F4 TDefGenerator_Init }
procedure TDefGenerator.Init(Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  ItemType := t_DefGenerator;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  DamageFactor := CalculateGeneratedDamageFactor;
  OwnerId := Owner;
  Repair;
  Cost := CalculateGeneratedDefGeneratorCost(Weight, Level, Owner);
end;
{ @end $5D90F4 }

{ @routine $5D9158 TDefGenerator_SaveToBuffer }
procedure TDefGenerator.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddSingle(DamageFactor);
end;
{ @end $5D9158 }

{ @routine $5D9180 TDefGenerator_LoadFromBuffer }
procedure TDefGenerator.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  DamageFactor := Buffer.GetSingle;
end;
{ @end $5D9180 }

{ @routine $5D91A8 TDefGenerator_CalculateGeneratedDamageFactor }
function TDefGenerator.CalculateGeneratedDamageFactor: Single;
begin
  Result := DefenseFactorByLevel[TechLevel];
end;
{ @end $5D91A8 }

{ @routine $5D91C0 GetGeneratedDefenseDamageFactor }
function GetGeneratedDefenseDamageFactor(Level: TTechLevel): Double;
begin
  Result := DefenseFactorByLevel[Level];
end;
{ @end $5D91C0 }

{ @routine $5D91DC DefenseDamageFactorToPercent }
function DefenseDamageFactorToPercent(Factor: Double): TPercent;
begin
  Result := Round((1 - Factor) * 100);
end;
{ @end $5D91DC }

{ @routine $5D9200 CalculateGeneratedDefGeneratorCost }
function CalculateGeneratedDefGeneratorCost(Weight: Cardinal; Level: Cardinal; Owner: TOwnerId): Integer;
begin
  Result := RoundAndTruncateToTens(RemapClamped(Level, 1, 8, 1, 32) * RemapClamped(40 / Weight, 0.5, 2, 1, 2) * 500 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5D9200 }

{ @routine $5D92B8 TDefGenerator_Improve }
procedure TDefGenerator.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  case Kind of
    ikMinor: DamageFactor := DamageFactor - (1 - DamageFactor) * SeededRandomFloatRange(Id * 354571, 0.08, 0.12) - SeededRandomFloatRange(Id * 254573, 0.02, 0.03);
    ikMedium: DamageFactor := DamageFactor - (1 - DamageFactor) * SeededRandomFloatRange(Id * 354572, 0.08, 0.12) - SeededRandomFloatRange(Id * 254572, 0.03, 0.05);
    ikMajor: DamageFactor := DamageFactor - (1 - DamageFactor) * SeededRandomFloatRange(Id * 354573, 0.08, 0.12) - SeededRandomFloatRange(Id * 254571, 0.05, 0.06);
  end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5D92B8 }

{ @routine $5D942C TDefGenerator_HasStandardStats }
function TDefGenerator.HasStandardStats: Boolean;
begin
  Result := CalculateGeneratedDamageFactor = DamageFactor;
end;
{ @end $5D942C }

{ @routine $5D9444 TDefGenerator_IsBetterThan }
function TDefGenerator.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TDefGenerator then Result := (Other as TDefGenerator).Cost < Cost
  else Result := False;
end;
{ @end $5D9444 }

{ @routine $5D947C TDefGenerator_GetDisplayName }
function TDefGenerator.GetDisplayName: WideString;
var TypeName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then
  begin
    TypeName := LocalizedText('Items.DefGenerator.Type.' + IntToStr(TechLevel));
    Result := ReplaceColoredToken(LocalizedText('Items.DefGenerator.Name'), '<Type>', TypeName, '');
  end
  else Result := LocalizedText('Items.DefGenerator.KlingName');
end;
{ @end $5D947C }

{ @routine $5D9604 TDefGenerator_GetShortName }
function TDefGenerator.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if OwnerId <> oiKling then Result := LocalizedText('Items.DefGenerator.ShortName')
  else Result := GetDisplayName;
end;
{ @end $5D9604 }

{ @routine $5D9684 TDefGenerator_GetInfoText }
function TDefGenerator.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  if OwnerId <> oiKling then Text := LocalizedText('Items.DefGenerator.Text')
  else Text := LocalizedText('Items.DefGenerator.KlingText');
  if HasStandardStats then ReplaceTextToken(Text, '<Percent>', IntToStr(DefenseDamageFactorToPercent(DamageFactor)), ColorTag)
  else ReplaceTextToken(Text, '<Percent>', IntToStr(DefenseDamageFactorToPercent(CalculateGeneratedDamageFactor)) + WrapTextInColor('+' + IntToStr((DefenseDamageFactorToPercent(DamageFactor)) - (DefenseDamageFactorToPercent(CalculateGeneratedDamageFactor))), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5D9684 }

{ @routine $5D9900 TDefGenerator_GetDescriptionText }
function TDefGenerator.GetDescriptionText: WideString;
begin
  if OwnerId <> oiKling then Result := LocalizedText('Items.DefGenerator.Description.' + IntToStr(TechLevel))
  else Result := LocalizedText('Items.DefGenerator.KlingDescription.' + IntToStr(TechLevel));
end;
{ @end $5D9900 }

{ @routine $5D9A28 TDefGenerator_GetFullInfoText }
function TDefGenerator.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5D9A28 }

{ @routine $5D9BA4 TDefGenerator_GetBitmapResourceName }
function TDefGenerator.GetBitmapResourceName: WideString;
begin
  if OwnerId <> oiKling then Result := 'Bm.Items.' + GiResourceSuffix + 'DefGenerator' + IntToStr(GetLevel)
  else Result := 'Bm.Items.' + GiResourceSuffix + 'DefGeneratorKling0';
end;
{ @end $5D9BA4 }

{ @routine $5D9CC4 TWeapon_Destroy }
destructor TWeapon.Destroy;
begin
  inherited Destroy;
end;
{ @end $5D9CC4 }

{ @routine $5D9CEC TWeapon_Init }
procedure TWeapon.Init(Kind: TItemType; Equipped: Boolean; Weight: Integer; Level: TTechLevel; Owner: TOwnerId);
begin
  Target := nil;
  ItemType := Kind;
  if Equipped then Equip else Unequip;
  Self.Weight := Weight;
  TechLevel := Level;
  Range := CalculateGeneratedRange;
  MinDamage := CalculateGeneratedMinDamage;
  MaxDamage := CalculateGeneratedMaxDamage;
  OwnerId := Owner;
  Repair;
  { Native uses the incoming Kind/Level, not fields reread after the calls. }
  Cost := CalculateGeneratedWeaponCost(Kind, Weight, Level, Owner);
end;
{ @end $5D9CEC }

{ @routine $5D9D6C TWeapon_SaveToBuffer }
procedure TWeapon.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddAnsiChar(AnsiChar(TechLevel));
  Buffer.AddWideChar(WideChar(Range));
  Buffer.AddAnsiChar(AnsiChar(MinDamage));
  Buffer.AddAnsiChar(AnsiChar(MaxDamage));
  if Target = nil then Buffer.AddAnsiChar(AnsiChar(wtkNone))
  else if Target is TShip then begin
    Buffer.AddAnsiChar(AnsiChar(wtkShip));
    Buffer.AddDWord((Target as TShip).Id);
  end else if Target is TItem then begin
    Buffer.AddAnsiChar(AnsiChar(wtkItem));
    Buffer.AddDWord((Target as TItem).Id);
  end else if Target is TAsteroid then begin
    Buffer.AddAnsiChar(AnsiChar(wtkAsteroid));
    Buffer.AddDWord((Target as TAsteroid).Id);
  end else Buffer.AddAnsiChar(AnsiChar(wtkNone));
end;
{ @end $5D9D6C }

{ @routine $5D9E64 TWeapon_LoadFromBuffer }
procedure TWeapon.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  TechLevel := Buffer.GetByte;
  Range := Buffer.GetWord;
  MinDamage := Buffer.GetByte;
  MaxDamage := Buffer.GetByte;
  LoadedTargetKind := TWeaponTargetKind(Buffer.GetByte);
  if LoadedTargetKind = wtkNone then Target := nil
  else Target := TObject(Buffer.GetUInt32);
end;
{ @end $5D9E64 }

{ @routine $5D9EC4 TWeapon_ClearReferences }
procedure TWeapon.ClearReferences;
begin
  inherited ClearReferences;
  if LoadedTargetKind = wtkShip then Target := Galaxy.IdToShip(Cardinal(Target), True) as TShip
  else if LoadedTargetKind = wtkItem then Target := Galaxy.IdToItem(Cardinal(Target)) as TItem
  else if LoadedTargetKind = wtkAsteroid then Target := Galaxy.IdToAsteroid(Cardinal(Target)) as TAsteroid;
end;
{ @end $5D9EC4 }

{ @routine $5D9F3C TWeapon_CalculateGeneratedMinDamage }
function TWeapon.CalculateGeneratedMinDamage: Integer;
begin
  Result := Round(WeaponInfo[ItemType].MinDamage * WeaponInfo[ItemType].DamageLevelFactors[TechLevel]);
end;
{ @end $5D9F3C }

{ @routine $5D9F80 TWeapon_CalculateGeneratedMaxDamage }
function TWeapon.CalculateGeneratedMaxDamage: Integer;
begin
  Result := Round(WeaponInfo[ItemType].MaxDamage * WeaponInfo[ItemType].DamageLevelFactors[TechLevel]);
end;
{ @end $5D9F80 }

{ @routine $5D9FC4 TWeapon_CalculateGeneratedRange }
function TWeapon.CalculateGeneratedRange: Integer;
begin
  Result := Round(WeaponRangeFactors[Round(RemapClamped(TechLevel, 1, 8, 1, 5))] * WeaponInfo[ItemType].Range);
end;
{ @end $5D9FC4 }

{ @routine $5DA030 CalculateGeneratedWeaponCost }
function CalculateGeneratedWeaponCost(ItemType: TItemType; Weight, Level: Cardinal; Owner: TOwnerId): Integer;
var Factor: Single;
begin
  if ItemType in HeavyWeaponTypes then
    Factor := WeaponInfo[ItemType].PriceFactor * RemapClamped(Level, 1, 8, 5, 20)
  else Factor := WeaponInfo[ItemType].PriceFactor * RemapClamped(Level, 1, 8, 1, 2);
  Result := RoundAndTruncateToTens(Factor * RemapClamped(WeaponInfo[ItemType].Weight / Weight, 0.5, 2, 1, 2) * 250 * OwnerInfo[Owner].FuelPriceFactor);
end;
{ @end $5DA030 }

{ @routine $5DA174 TWeapon_Improve }
procedure TWeapon.Improve(Kind: TImprovementKind);
begin
  if Kind = ikAny then Kind := TImprovementKind(SeededRandomIntRange(0, 2, Galaxy.CurrentTurn * Id));
  if SeededRandomUnitFloat(Galaxy.CurrentTurn * (Ord(Kind) + 1) * Id) < 0.5 then
    case Kind of
      ikMinor: MaxDamage := MaxDamage + Round(MaxDamage * SeededRandomFloatRange(Id * 276247, 0.07, 0.12) + WeaponInfo[ItemType].MaxDamage * SeededRandomFloatRange(Id * 976247, 0.1, 0.2)) + 1;
      ikMedium: MaxDamage := MaxDamage + Round(MaxDamage * SeededRandomFloatRange(Id * 276247, 0.07, 0.12) + WeaponInfo[ItemType].MaxDamage * SeededRandomFloatRange(Id * 976247, 0.2, 0.3)) + 2;
      ikMajor: MaxDamage := MaxDamage + Round(MaxDamage * SeededRandomFloatRange(Id * 276247, 0.07, 0.12) + WeaponInfo[ItemType].MaxDamage * SeededRandomFloatRange(Id * 976247, 0.3, 0.4)) + 3;
    end
  else
    case Kind of
      ikMinor: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.04, 0.07) + WeaponInfo[ItemType].Range * SeededRandomFloatRange(Id * 976247, 0.03, 0.06)));
      ikMedium: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.04, 0.07) + WeaponInfo[ItemType].Range * SeededRandomFloatRange(Id * 976247, 0.06, 0.08)));
      ikMajor: Inc(Range, RoundAndTruncateToTens(Range * SeededRandomFloatRange(Id * 354571, 0.04, 0.07) + WeaponInfo[ItemType].Range * SeededRandomFloatRange(Id * 976247, 0.08, 0.11)));
    end;
  Inc(Cost, CalculateImprovementCost(Kind) div 2);
end;
{ @end $5DA174 }

{ @routine $5DA534 TWeapon_HasStandardStats }
function TWeapon.HasStandardStats: Boolean;
begin
  Result := (CalculateGeneratedMaxDamage = MaxDamage) and (CalculateGeneratedRange = Range);
end;
{ @end $5DA534 }

{ @routine $5DA55C TWeapon_IsBetterThan }
function TWeapon.IsBetterThan(Other: TItem): Boolean;
var OtherWeapon: TWeapon;
begin
  if Other is TWeapon then
  begin
    OtherWeapon := Other as TWeapon;
    Result := (OtherWeapon.Cost < Cost) and (WeaponInfo[ItemType].Mode = WeaponInfo[OtherWeapon.ItemType].Mode);
  end
  else if Other.ItemType in ExclusiveEquipmentTypes then Result := False
  else Result := Cost > Other.Cost;
end;
{ @end $5DA55C }

{ @routine $5DA5EC TWeapon_GetDisplayName }
function TWeapon.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := GetShortName;
end;
{ @end $5DA5EC }

{ @routine $5DA618 TWeapon_GetShortName }
function TWeapon.GetShortName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.Weapon.Name.' + IntToStr(Ord(ItemType) - Ord(t_PhotonGun) + 1));
end;
{ @end $5DA618 }

{ @routine $5DA6D0 TWeapon_GetInfoText }
function TWeapon.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  Text := LocalizedText('Items.Weapon.Text.' + IntToStr(Ord(ItemType) - Ord(t_PhotonGun) + 1));
  ReplaceTextToken(Text, '<MinDamage>', IntToStr(CalculateGeneratedMinDamage), ColorTag);
  if MaxDamage = CalculateGeneratedMaxDamage then ReplaceTextToken(Text, '<MaxDamage>', IntToStr(MaxDamage), ColorTag)
  else ReplaceTextToken(Text, '<MaxDamage>', IntToStr(CalculateGeneratedMaxDamage) + WrapTextInColor('+' + IntToStr(MaxDamage - CalculateGeneratedMaxDamage), GreenColorTag), ColorTag);
  if Range = CalculateGeneratedRange then ReplaceTextToken(Text, '<Radius>', IntToStr(Range), ColorTag)
  else ReplaceTextToken(Text, '<Radius>', IntToStr(CalculateGeneratedRange) + WrapTextInColor('+' + IntToStr(Range - CalculateGeneratedRange), GreenColorTag), ColorTag);
  Result := Text + GetConditionText;
end;
{ @end $5DA6D0 }

{ @routine $5DAA50 TWeapon_GetDescriptionText }
function TWeapon.GetDescriptionText: WideString;
begin
  Result := LocalizedText('Items.TWeapon.Description.' + IntToStr(Ord(ItemType) - Ord(t_PhotonGun) + 1));
end;
{ @end $5DAA50 }

{ @routine $5DAAF8 TWeapon_GetFullInfoText }
function TWeapon.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;

{ @end $5DAAF8 }

{ @routine $5DAC74 TWeapon_GetShotDelayFactor }
function TWeapon.GetShotDelayFactor: Double;
begin
  Result := 1 - WeaponInfo[ItemType].ShotSpeedPercent * 0.01;
end;
{ @end $5DAC74 }

{ @routine $5DACB8 TWeapon_DealsHullDamage }
function TWeapon.DealsHullDamage: Boolean;
begin
  Result := WeaponInfo[ItemType].Mode = wmHullDamage;
end;
{ @end $5DACB8 }

{ @routine $5DACD8 TWeapon_HasSpecialDamageMode }
function TWeapon.HasSpecialDamageMode: Boolean;
begin
  Result := WeaponInfo[ItemType].Mode <> wmHullDamage;
end;
{ @end $5DACD8 }

{ @routine $5DACF8 TWeapon_GetBitmapResourceName }
function TWeapon.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + ItemTypeNames[ItemType];
end;
{ @end $5DACF8 }

{ @routine $5DAD78 TGoods_Init }
procedure TGoods.Init(Kind: TGoodsIndex; Quantity: Integer);
begin
  ItemType := Kind;
  Self.Quantity := Quantity;
  Weight := Quantity;
  Cost := Self.Quantity * GoodsMarket[ItemType].BasePrice;
  NaturalFlag := False;
end;
{ @end $5DAD78 }

{ @routine $5DADA0 TGoods_SaveToBuffer }
procedure TGoods.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddIntegerValue(Quantity);
  Buffer.AddBoolean(Boolean(NaturalFlag));
end;
{ @end $5DADA0 }

{ @routine $5DADC8 TGoods_LoadFromBuffer }
procedure TGoods.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  Quantity := Buffer.GetInt32;
  NaturalFlag := Buffer.GetBoolean;
end;
{ @end $5DADC8 }

{ @routine $5DADF0 TGoods_IsBetterThan }
function TGoods.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TGoods then Result := (Other as TGoods).Cost < Cost
  else Result := False;
end;
{ @end $5DADF0 }

{ @routine $5DAE28 TGoods_GetDisplayName }
function TGoods.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := GoodsMarket[ItemType].DisplayName;
end;

{ @end $5DAE28 }

{ @routine $5DAE64 TGoods_GetInfoText }
function TGoods.GetInfoText(ColorTag: WideString): WideString;
var Text: WideString;
begin
  Text := LocalizedText('Items.Goods.Text' + IntToStr(Ord(ItemType) + 1));
  Result := WrapTextInColor(GetDisplayName, ColorTag) + Text;
end;

{ @end $5DAE64 }

{ @routine $5DAF4C TGoods_GetDescriptionText }
function TGoods.GetDescriptionText: WideString;
begin
  Result := LocalizedText('Items.Goods.Description.' + IntToStr(Ord(ItemType) + 1));
end;

{ @end $5DAF4C }

{ @routine $5DAFF0 TGoods_GetFullInfoText }
function TGoods.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(GetDisplayName) + #13#10 + 'V ' + IntToStr(Weight);
end;
{ @end $5DAFF0 }

{ @routine $5DB09C TGoods_GetBitmapResourceName }
function TGoods.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + ItemTypeNames[ItemType];
end;
{ @end $5DB09C }

{ @routine $5DB11C TProtoplasm_Init }
procedure TProtoplasm.Init(Count: Integer; Drop: Byte);
begin
  ItemType := t_Protoplasm;
  Quantity := Count;
  Weight := Count;
  Cost := Count * 10;
  OwnerId := oiKling;
  DropFlag := Drop;
  EquippedFlag := False;
  ConditionPercent := 0;
  BrokenFlag := True;
end;
{ @end $5DB11C }

{ @routine $5DB148 TProtoplasm_SaveToBuffer }
procedure TProtoplasm.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddIntegerValue(Quantity);
  Buffer.AddBoolean(Boolean(DropFlag));
end;
{ @end $5DB148 }

{ @routine $5DB170 TProtoplasm_LoadFromBuffer }
procedure TProtoplasm.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  Quantity := Buffer.GetInt32;
  DropFlag := Byte(Buffer.GetBoolean);
end;
{ @end $5DB170 }

{ @routine $5DB198 TProtoplasm_IsBetterThan }
function TProtoplasm.IsBetterThan(Other: TItem): Boolean;
begin
  if Other is TProtoplasm then Result := (Other as TProtoplasm).Cost < Cost
  else Result := False;
end;
{ @end $5DB198 }

{ @routine $5DB1D0 TProtoplasm_GetDisplayName }
function TProtoplasm.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.Protoplasm.Name');
end;
{ @end $5DB1D0 }

{ @routine $5DB230 TProtoplasm_GetInfoText }
function TProtoplasm.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedText('Items.Protoplasm.Text');
end;
{ @end $5DB230 }

{ @routine $5DB298 TProtoplasm_GetDescriptionText }
function TProtoplasm.GetDescriptionText: WideString;
begin
  Result := LocalizedText('Items.Protoplasm.Description');
end;
{ @end $5DB298 }

{ @routine $5DB2EC TProtoplasm_GetFullInfoText }
function TProtoplasm.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(GetDisplayName) + #13#10 + 'V ' + IntToStr(Weight);
end;
{ @end $5DB2EC }

{ @routine $5DB398 TProtoplasm_GetBitmapResourceName }
function TProtoplasm.GetBitmapResourceName: WideString;
begin
  if Weight <= 29 then Result := 'Bm.Items.' + GiResourceSuffix + 'Protoplasm0_'
  else if Weight <= 59 then Result := 'Bm.Items.' + GiResourceSuffix + 'Protoplasm1_'
  else Result := 'Bm.Items.' + GiResourceSuffix + 'Protoplasm2_';
end;
{ @end $5DB398 }

{ @routine $5DB4C8 TUselessItem_Init }
procedure TUselessItem.Init(ConfigName: WideString; Seed: Integer);
var BaseValue: Integer;
begin
  ItemType := t_UselessItem;
  if ConfigName = 'Remains' then
    ConfigBlockName := 'Remains_' + IntToStr(SeededRandomIntRange(0, UselessItemRemainsCount - 1, Seed))
  else ConfigBlockName := ConfigName;
  OwnerId := OwnerFromInternalName(LookupLocalizedTextByKey('UselessItems.' + ConfigBlockName + '.Owner'));
  BaseValue := StrToInt(AnsiString(LookupLocalizedTextByKey('UselessItems.' + ConfigBlockName + '.Size')));
  Weight := BaseValue;
  Weight := Round(SeededRandomIntRange(0, BaseValue, Id * 71621723) * RemapClamped(Galaxy.TechLevel, 4, 8, 0.5, 3) + BaseValue);
  BaseValue := Round(Galaxy.ResolveMoneySizeTag(LookupLocalizedTextByKey('UselessItems.' + ConfigBlockName + '.Cost'), oiPeople) *
    SeededRandomFloatRange(Id * 13567157, 0.5, 1.2));
  Cost := BaseValue;
  Cost := RoundAndTruncateToTens(SeededRandomIntRange(150, 200, Id * 13567157) * RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) *
    RemapClamped(Weight, 10, 100, 1, 6) * DifficultyModifiers[Galaxy.Difficulty].HomeSystemGraceFactor + BaseValue);
end;
{ @end $5DB4C8 }

{ @routine $5DB848 TUselessItem_SaveToBuffer }
procedure TUselessItem.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddWideStringZ(ConfigBlockName);
end;
{ @end $5DB848 }

{ @routine $5DB864 TUselessItem_LoadFromBuffer }
procedure TUselessItem.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  ConfigBlockName := Buffer.ReadWideString;
end;
{ @end $5DB864 }

{ @routine $5DB8C0 TUselessItem_IsBetterThan }
function TUselessItem.IsBetterThan(Other: TItem): Boolean;
begin
  Result := False;
end;
{ @end $5DB8C0 }

{ @routine $5DB8C4 TUselessItem_GetDisplayName }
function TUselessItem.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if LanguageDataConfig.GetBlock('UselessItems').CountBlocks(ConfigBlockName) <= 0 then Result := ''
  else Result := LocalizedText('UselessItems.' + ConfigBlockName + '.Name');
end;
{ @end $5DB8C4 }

{ @routine $5DB9B4 TUselessItem_GetInfoText }
function TUselessItem.GetInfoText(ColorTag: WideString): WideString;
begin
  if LanguageDataConfig.GetBlock('UselessItems').CountBlocks(ConfigBlockName) <= 0 then Result := ''
  else Result := LocalizedText('UselessItems.' + ConfigBlockName + '.Text');
end;
{ @end $5DB9B4 }

{ @routine $5DBA8C TUselessItem_GetDescriptionText }
function TUselessItem.GetDescriptionText: WideString;
begin
  if LanguageDataConfig.GetBlock('UselessItems').CountBlocks(ConfigBlockName) <= 0 then Result := ''
  else Result := LocalizedText('UselessItems.' + ConfigBlockName + '.Description');
end;
{ @end $5DBA8C }

{ @routine $5DBB74 TUselessItem_GetFullInfoText }
function TUselessItem.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;

{ @end $5DBB74 }

{ @routine $5DBCF0 TUselessItem_GetBitmapResourceName }
function TUselessItem.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.ItemsUseless.' + GiResourceSuffix + ConfigBlockName + '_';
  if not RootResourceData.HasFileEntry(Result + 's') then
    Result := 'Bm.ItemsUseless.' + GiResourceSuffix + 'Usl_FishCont_';
end;
{ @end $5DBCF0 }

{ @routine $5DBDF4 CreateRandomArtefact }
function CreateRandomArtefact(Seed: Cardinal; Owner: TOwnerId): TItem;
begin
  Result := nil;
  case TItemType(SeededRandomIntRange(Ord(t_ArtefactHull), Ord(t_ArtefactTranclucator), Seed)) of
    t_ArtefactHull: begin
      Result := CreateItemByType(t_ArtefactHull);
      TArtefactHull(Result).Init(Owner);
    end;
    t_ArtefactFuel: begin
      Result := CreateItemByType(t_ArtefactFuel);
      TArtefactFuel(Result).Init(Owner);
    end;
    t_ArtefactSpeed: begin
      Result := CreateItemByType(t_ArtefactSpeed);
      TArtefactSpeed(Result).Init(Owner);
    end;
    t_ArtefactPower: begin
      Result := CreateItemByType(t_ArtefactPower);
      TArtefactPower(Result).Init(Owner);
    end;
    t_ArtefactRadar: begin
      Result := CreateItemByType(t_ArtefactRadar);
      TArtefactRadar(Result).Init(Owner);
    end;
    t_ArtefactScaner: begin
      Result := CreateItemByType(t_ArtefactScaner);
      TArtefactScaner(Result).Init(Owner);
    end;
    t_ArtefactDroid: begin
      Result := CreateItemByType(t_ArtefactDroid);
      TArtefactDroid(Result).Init(Owner);
    end;
    t_ArtefactNano: begin
      Result := CreateItemByType(t_ArtefactNano);
      TArtefactNano(Result).Init(Owner);
    end;
    t_ArtefactHook: begin
      Result := CreateItemByType(t_ArtefactHook);
      TArtefactHook(Result).Init(Owner);
    end;
    t_ArtefactDef: begin
      Result := CreateItemByType(t_ArtefactDef);
      TArtefactDef(Result).Init(Owner);
    end;
    t_ArtefactAnalyzer: begin
      Result := CreateItemByType(t_ArtefactAnalyzer);
      TArtefactAnalyzer(Result).Init(Owner);
    end;
    t_ArtefactMiniExpl: begin
      Result := CreateItemByType(t_ArtefactMiniExpl);
      TArtefactMiniExpl(Result).Init(Owner);
    end;
    t_ArtefactAntigrav: begin
      Result := CreateItemByType(t_ArtefactAntigrav);
      TArtefactAntigrav(Result).Init(Owner);
    end;
    t_ArtefactTransmitter: begin
      Result := CreateItemByType(t_ArtefactTransmitter);
      TArtefactTransmitter(Result).Init(Owner);
    end;
    t_ArtefactBomb: begin
      Result := CreateItemByType(t_ArtefactBomb);
      TArtefactBomb(Result).Init(Owner);
    end;
    t_ArtefactTranclucator: begin
      Result := CreateItemByType(t_ArtefactTranclucator);
      TArtefactTranclucator(Result).Init(Owner, nil, nil);
    end;
  end;
end;
{ @end $5DBDF4 }

{ @routine $5DBFC8 TArtefact_Create }
constructor TArtefact.Create;
begin
  inherited Create;
  Repair;
end;
{ @end $5DBFC8 }

{ @routine $5DC004 TArtefact_GetBitmapResourceName }
function TArtefact.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'Artifact_';
end;
{ @end $5DC004 }

{ @routine $5DC08C TArtefact_IsBetterThan }
function TArtefact.IsBetterThan(Other: TItem): Boolean;
begin
  Result := True;
end;
{ @end $5DC08C }

{ @routine $5DC090 TArtefactHull_Init }
procedure TArtefactHull.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactHull;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 5, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1500, 3000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DC090 }

{ @routine $5DC1F0 TArtefactHull_SaveToBuffer }
procedure TArtefactHull.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DC1F0 }

{ @routine $5DC1F8 TArtefactHull_LoadFromBuffer }
procedure TArtefactHull.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DC1F8 }

{ @routine $5DC200 TArtefactHull_GetDisplayName }
function TArtefactHull.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactHull.Name');
end;
{ @end $5DC200 }

{ @routine $5DC264 TArtefactHull_GetInfoText }
function TArtefactHull.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactHull.Text') + GetConditionText;
end;
{ @end $5DC264 }

{ @routine $5DC304 TArtefactHull_GetDescriptionText }
function TArtefactHull.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactHull.Description');
end;
{ @end $5DC304 }

{ @routine $5DC35C TArtefactHull_GetFullInfoText }
function TArtefactHull.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DC35C }

{ @routine $5DC4D8 TArtefactHull_GetBitmapResourceName }
function TArtefactHull.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtHull_';
end;
{ @end $5DC4D8 }

{ @routine $5DC560 TArtefactFuel_Init }
procedure TArtefactFuel.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactFuel;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 5, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1500, 3000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DC560 }

{ @routine $5DC6C0 TArtefactFuel_SaveToBuffer }
procedure TArtefactFuel.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DC6C0 }

{ @routine $5DC6C8 TArtefactFuel_LoadFromBuffer }
procedure TArtefactFuel.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DC6C8 }

{ @routine $5DC6D0 TArtefactFuel_GetDisplayName }
function TArtefactFuel.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactFuel.Name');
end;
{ @end $5DC6D0 }

{ @routine $5DC734 TArtefactFuel_GetInfoText }
function TArtefactFuel.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactFuel.Text') + GetConditionText;
end;
{ @end $5DC734 }

{ @routine $5DC7D4 TArtefactFuel_GetDescriptionText }
function TArtefactFuel.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactFuel.Description');
end;
{ @end $5DC7D4 }

{ @routine $5DC82C TArtefactFuel_GetFullInfoText }
function TArtefactFuel.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DC82C }

{ @routine $5DC9A8 TArtefactFuel_GetBitmapResourceName }
function TArtefactFuel.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtFuel_';
end;
{ @end $5DC9A8 }

{ @routine $5DCA30 TArtefactSpeed_Init }
procedure TArtefactSpeed.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactSpeed;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 5, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(2000, 3000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DCA30 }

{ @routine $5DCB90 TArtefactSpeed_SaveToBuffer }
procedure TArtefactSpeed.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DCB90 }

{ @routine $5DCB98 TArtefactSpeed_LoadFromBuffer }
procedure TArtefactSpeed.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DCB98 }

{ @routine $5DCBA0 TArtefactSpeed_GetDisplayName }
function TArtefactSpeed.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactSpeed.Name');
end;
{ @end $5DCBA0 }

{ @routine $5DCC08 TArtefactSpeed_GetInfoText }
function TArtefactSpeed.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactSpeed.Text') + GetConditionText;
end;
{ @end $5DCC08 }

{ @routine $5DCCAC TArtefactSpeed_GetDescriptionText }
function TArtefactSpeed.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactSpeed.Description');
end;
{ @end $5DCCAC }

{ @routine $5DCD04 TArtefactSpeed_GetFullInfoText }
function TArtefactSpeed.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DCD04 }

{ @routine $5DCE80 TArtefactSpeed_GetBitmapResourceName }
function TArtefactSpeed.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtSpeed_';
end;
{ @end $5DCE80 }

{ @routine $5DCF08 TArtefactPower_Init }
procedure TArtefactPower.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactPower;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 5, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1000, 2000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DCF08 }

{ @routine $5DD068 TArtefactPower_SaveToBuffer }
procedure TArtefactPower.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DD068 }

{ @routine $5DD070 TArtefactPower_LoadFromBuffer }
procedure TArtefactPower.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DD070 }

{ @routine $5DD078 TArtefactPower_GetDisplayName }
function TArtefactPower.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactPower.Name');
end;
{ @end $5DD078 }

{ @routine $5DD0E0 TArtefactPower_GetDescriptionText }
function TArtefactPower.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactPower.Description');
end;
{ @end $5DD0E0 }

{ @routine $5DD138 TArtefactPower_GetInfoText }
function TArtefactPower.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactPower.Text') + GetConditionText;
end;
{ @end $5DD138 }

{ @routine $5DD1DC TArtefactPower_GetFullInfoText }
function TArtefactPower.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DD1DC }

{ @routine $5DD358 TArtefactPower_GetBitmapResourceName }
function TArtefactPower.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtPower_';
end;
{ @end $5DD358 }

{ @routine $5DD3E0 TArtefactRadar_Init }
procedure TArtefactRadar.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactRadar;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 3, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1000, 1500, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DD3E0 }

{ @routine $5DD540 TArtefactRadar_SaveToBuffer }
procedure TArtefactRadar.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DD540 }

{ @routine $5DD548 TArtefactRadar_LoadFromBuffer }
procedure TArtefactRadar.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DD548 }

{ @routine $5DD550 TArtefactRadar_GetDisplayName }
function TArtefactRadar.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactRadar.Name');
end;
{ @end $5DD550 }

{ @routine $5DD5B8 TArtefactRadar_GetInfoText }
function TArtefactRadar.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactRadar.Text') + GetConditionText;
end;
{ @end $5DD5B8 }

{ @routine $5DD65C TArtefactRadar_GetDescriptionText }
function TArtefactRadar.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactRadar.Description');
end;
{ @end $5DD65C }

{ @routine $5DD6B4 TArtefactRadar_GetFullInfoText }
function TArtefactRadar.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DD6B4 }

{ @routine $5DD830 TArtefactRadar_GetBitmapResourceName }
function TArtefactRadar.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtRadar_';
end;
{ @end $5DD830 }

{ @routine $5DD8B8 TArtefactScaner_Init }
procedure TArtefactScaner.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactScaner;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 2, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(500, 1000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DD8B8 }

{ @routine $5DDA18 TArtefactScaner_SaveToBuffer }
procedure TArtefactScaner.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DDA18 }

{ @routine $5DDA20 TArtefactScaner_LoadFromBuffer }
procedure TArtefactScaner.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DDA20 }

{ @routine $5DDA28 TArtefactScaner_GetDisplayName }
function TArtefactScaner.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactScaner.Name');
end;
{ @end $5DDA28 }

{ @routine $5DDA90 TArtefactScaner_GetInfoText }
function TArtefactScaner.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactScaner.Text') + GetConditionText;
end;
{ @end $5DDA90 }

{ @routine $5DDB34 TArtefactScaner_GetDescriptionText }
function TArtefactScaner.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactScaner.Description');
end;
{ @end $5DDB34 }

{ @routine $5DDB90 TArtefactScaner_GetFullInfoText }
function TArtefactScaner.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DDB90 }

{ @routine $5DDD0C TArtefactScaner_GetBitmapResourceName }
function TArtefactScaner.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtScaner_';
end;
{ @end $5DDD0C }

{ @routine $5DDD98 TArtefactDroid_Init }
procedure TArtefactDroid.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactDroid;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 4, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1500, 3000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DDD98 }

{ @routine $5DDEF8 TArtefactDroid_SaveToBuffer }
procedure TArtefactDroid.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DDEF8 }

{ @routine $5DDF00 TArtefactDroid_LoadFromBuffer }
procedure TArtefactDroid.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DDF00 }

{ @routine $5DDF08 TArtefactDroid_GetDisplayName }
function TArtefactDroid.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactDroid.Name');
end;
{ @end $5DDF08 }

{ @routine $5DDF70 TArtefactDroid_GetInfoText }
function TArtefactDroid.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactDroid.Text') + GetConditionText;
end;
{ @end $5DDF70 }

{ @routine $5DE014 TArtefactDroid_GetDescriptionText }
function TArtefactDroid.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactDroid.Description');
end;
{ @end $5DE014 }

{ @routine $5DE06C TArtefactDroid_GetFullInfoText }
function TArtefactDroid.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DE06C }

{ @routine $5DE1E8 TArtefactDroid_GetBitmapResourceName }
function TArtefactDroid.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtDroid_';
end;
{ @end $5DE1E8 }

{ @routine $5DE270 TArtefactNano_Init }
procedure TArtefactNano.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactNano;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 5) * SeededRandomIntRange(1, 4, Id * 391847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 2) * SeededRandomIntRange(2000, 4000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DE270 }

{ @routine $5DE3D0 TArtefactNano_SaveToBuffer }
procedure TArtefactNano.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DE3D0 }

{ @routine $5DE3D8 TArtefactNano_LoadFromBuffer }
procedure TArtefactNano.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DE3D8 }

{ @routine $5DE3E0 TArtefactNano_GetDisplayName }
function TArtefactNano.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactNano.Name');
end;
{ @end $5DE3E0 }

{ @routine $5DE444 TArtefactNano_GetInfoText }
function TArtefactNano.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactNano.Text') + GetConditionText;
end;
{ @end $5DE444 }

{ @routine $5DE4E4 TArtefactNano_GetDescriptionText }
function TArtefactNano.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactNano.Description');
end;
{ @end $5DE4E4 }

{ @routine $5DE53C TArtefactNano_GetFullInfoText }
function TArtefactNano.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DE53C }

{ @routine $5DE6B8 TArtefactNano_GetBitmapResourceName }
function TArtefactNano.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtNano_';
end;
{ @end $5DE6B8 }

{ @routine $5DE740 TArtefactHook_Init }
procedure TArtefactHook.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactHook;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 3, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1000, 2000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DE740 }

{ @routine $5DE8A0 TArtefactHook_SaveToBuffer }
procedure TArtefactHook.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DE8A0 }

{ @routine $5DE8A8 TArtefactHook_LoadFromBuffer }
procedure TArtefactHook.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DE8A8 }

{ @routine $5DE8B0 TArtefactHook_GetDisplayName }
function TArtefactHook.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactHook.Name');
end;
{ @end $5DE8B0 }

{ @routine $5DE914 TArtefactHook_GetInfoText }
function TArtefactHook.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactHook.Text') + GetConditionText;
end;
{ @end $5DE914 }

{ @routine $5DE9B4 TArtefactHook_GetDescriptionText }
function TArtefactHook.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactHook.Description');
end;
{ @end $5DE9B4 }

{ @routine $5DEA0C TArtefactHook_GetFullInfoText }
function TArtefactHook.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DEA0C }

{ @routine $5DEB88 TArtefactHook_GetBitmapResourceName }
function TArtefactHook.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtHook_';
end;
{ @end $5DEB88 }

{ @routine $5DEC10 TArtefactDef_Init }
procedure TArtefactDef.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactDef;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 5, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1500, 2500, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DEC10 }

{ @routine $5DED70 TArtefactDef_SaveToBuffer }
procedure TArtefactDef.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DED70 }

{ @routine $5DED78 TArtefactDef_LoadFromBuffer }
procedure TArtefactDef.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DED78 }

{ @routine $5DED80 TArtefactDef_GetDisplayName }
function TArtefactDef.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactDef.Name');
end;
{ @end $5DED80 }

{ @routine $5DEDE4 TArtefactDef_GetInfoText }
function TArtefactDef.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactDef.Text') + GetConditionText;
end;
{ @end $5DEDE4 }

{ @routine $5DEE84 TArtefactDef_GetDescriptionText }
function TArtefactDef.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactDef.Description');
end;
{ @end $5DEE84 }

{ @routine $5DEED8 TArtefactDef_GetFullInfoText }
function TArtefactDef.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DEED8 }

{ @routine $5DF054 TArtefactDef_GetBitmapResourceName }
function TArtefactDef.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtDef_';
end;
{ @end $5DF054 }

{ @routine $5DF0D8 TArtefactAnalyzer_Init }
procedure TArtefactAnalyzer.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactAnalyzer;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 2, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 2) * SeededRandomIntRange(1000, 2000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DF0D8 }

{ @routine $5DF238 TArtefactAnalyzer_SaveToBuffer }
procedure TArtefactAnalyzer.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DF238 }

{ @routine $5DF240 TArtefactAnalyzer_LoadFromBuffer }
procedure TArtefactAnalyzer.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DF240 }

{ @routine $5DF248 TArtefactAnalyzer_GetDisplayName }
function TArtefactAnalyzer.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactAnalyzer.Name');
end;
{ @end $5DF248 }

{ @routine $5DF2B4 TArtefactAnalyzer_GetInfoText }
function TArtefactAnalyzer.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactAnalyzer.Text') + GetConditionText;
end;
{ @end $5DF2B4 }

{ @routine $5DF35C TArtefactAnalyzer_GetDescriptionText }
function TArtefactAnalyzer.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactAnalyzer.Description');
end;
{ @end $5DF35C }

{ @routine $5DF3BC TArtefactAnalyzer_GetFullInfoText }
function TArtefactAnalyzer.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DF3BC }

{ @routine $5DF538 TArtefactAnalyzer_GetBitmapResourceName }
function TArtefactAnalyzer.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtAnalyzer_';
end;
{ @end $5DF538 }

{ @routine $5DF5C8 TArtefactMiniExpl_Init }
procedure TArtefactMiniExpl.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactMiniExpl;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 3, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 2) * SeededRandomIntRange(1500, 3000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DF5C8 }

{ @routine $5DF728 TArtefactMiniExpl_SaveToBuffer }
procedure TArtefactMiniExpl.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DF728 }

{ @routine $5DF730 TArtefactMiniExpl_LoadFromBuffer }
procedure TArtefactMiniExpl.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DF730 }

{ @routine $5DF738 TArtefactMiniExpl_GetDisplayName }
function TArtefactMiniExpl.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactMiniExpl.Name');
end;
{ @end $5DF738 }

{ @routine $5DF7A4 TArtefactMiniExpl_GetInfoText }
function TArtefactMiniExpl.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactMiniExpl.Text') + GetConditionText;
end;
{ @end $5DF7A4 }

{ @routine $5DF84C TArtefactMiniExpl_GetDescriptionText }
function TArtefactMiniExpl.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactMiniExpl.Description');
end;
{ @end $5DF84C }

{ @routine $5DF8AC TArtefactMiniExpl_GetFullInfoText }
function TArtefactMiniExpl.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DF8AC }

{ @routine $5DFA28 TArtefactMiniExpl_GetBitmapResourceName }
function TArtefactMiniExpl.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtMiniExpl_';
end;
{ @end $5DFA28 }

{ @routine $5DFAB8 TArtefactAntigrav_Init }
procedure TArtefactAntigrav.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactAntigrav;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 4) * SeededRandomIntRange(1, 3, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1000, 2500, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  EquippedFlag := False;
end;
{ @end $5DFAB8 }

{ @routine $5DFC18 TArtefactAntigrav_SaveToBuffer }
procedure TArtefactAntigrav.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5DFC18 }

{ @routine $5DFC20 TArtefactAntigrav_LoadFromBuffer }
procedure TArtefactAntigrav.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5DFC20 }

{ @routine $5DFC28 TArtefactAntigrav_GetDisplayName }
function TArtefactAntigrav.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactAntigrav.Name');
end;
{ @end $5DFC28 }

{ @routine $5DFC94 TArtefactAntigrav_GetInfoText }
function TArtefactAntigrav.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactAntigrav.Text') + GetConditionText;
end;
{ @end $5DFC94 }

{ @routine $5DFD3C TArtefactAntigrav_GetDescriptionText }
function TArtefactAntigrav.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactAntigrav.Description');
end;
{ @end $5DFD3C }

{ @routine $5DFD9C TArtefactAntigrav_GetFullInfoText }
function TArtefactAntigrav.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5DFD9C }

{ @routine $5DFF18 TArtefactAntigrav_GetBitmapResourceName }
function TArtefactAntigrav.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtAntigrav_';
end;
{ @end $5DFF18 }

{ @routine $5DFFA8 TArtefactTransmitter_Init }
procedure TArtefactTransmitter.Init(Owner: TOwnerId);
begin
  Charges := 100;
  ItemType := t_ArtefactTransmitter;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 3) * SeededRandomIntRange(1, 2, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(500, 1500, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
end;
{ @end $5DFFA8 }

{ @routine $5E0108 TArtefactTransmitter_SaveToBuffer }
procedure TArtefactTransmitter.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  Buffer.AddIntegerValue(Charges);
end;
{ @end $5E0108 }

{ @routine $5E0124 TArtefactTransmitter_LoadFromBuffer }
procedure TArtefactTransmitter.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  Charges := Buffer.GetInt32;
end;
{ @end $5E0124 }

{ @routine $5E0140 TArtefactTransmitter_GetDisplayName }
function TArtefactTransmitter.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactTransmitter.Name');
end;
{ @end $5E0140 }

{ @routine $5E01B4 TArtefactTransmitter_GetInfoText }
function TArtefactTransmitter.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactTransmitter.Text') + GetConditionText;
  ReplaceTextToken(Result, '<Power>', IntToStr(Max(0, Charges)), ColorTag);
end;
{ @end $5E01B4 }

{ @routine $5E02C0 TArtefactTransmitter_GetDescriptionText }
function TArtefactTransmitter.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactTransmitter.Description');
end;
{ @end $5E02C0 }

{ @routine $5E0324 TArtefactTransmitter_GetFullInfoText }
function TArtefactTransmitter.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5E0324 }

{ @routine $5E04A0 TArtefactTransmitter_GetBitmapResourceName }
function TArtefactTransmitter.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtTransmitter_';
end;
{ @end $5E04A0 }

{ @routine $5E0534 TArtefactBomb_Init }
procedure TArtefactBomb.Init(Owner: TOwnerId);
begin
  ItemType := t_ArtefactBomb;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 6) * SeededRandomIntRange(1, 2, Id * 317847)));
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 2) * SeededRandomIntRange(1000, 2000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
end;
{ @end $5E0534 }

{ @routine $5E0690 TArtefactBomb_SaveToBuffer }
procedure TArtefactBomb.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
end;
{ @end $5E0690 }

{ @routine $5E0698 TArtefactBomb_LoadFromBuffer }
procedure TArtefactBomb.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
end;
{ @end $5E0698 }

{ @routine $5E06A0 TArtefactBomb_GetDisplayName }
function TArtefactBomb.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else Result := LocalizedText('Items.ArtefactBomb.Name');
end;
{ @end $5E06A0 }

{ @routine $5E0704 TArtefactBomb_GetInfoText }
function TArtefactBomb.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactBomb.Text') + GetConditionText;
end;
{ @end $5E0704 }

{ @routine $5E07A4 TArtefactBomb_GetDescriptionText }
function TArtefactBomb.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactBomb.Description');
end;
{ @end $5E07A4 }

{ @routine $5E07FC TArtefactBomb_GetFullInfoText }
function TArtefactBomb.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5E07FC }

{ @routine $5E0978 TArtefactBomb_GetBitmapResourceName }
function TArtefactBomb.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtBomb_';
end;
{ @end $5E0978 }

{ @routine $5E0A00 TArtefactTranclucator_Destroy }
destructor TArtefactTranclucator.Destroy;
begin
  if Ship <> nil then begin
    Ship.Free;
    Ship := nil;
  end;
  inherited Destroy;
end;
{ @end $5E0A00 }

{ @routine $5E0A38 TArtefactTranclucator_Init }
procedure TArtefactTranclucator.Init(Owner: TOwnerId; OwnerShip, ExistingShip: TObject);
var Drone: TTranclucator;
begin
  ItemType := t_ArtefactTranclucator;
  OwnerId := Owner;
  Weight := GetAverageItemSize(ItemType);
  if Player <> nil then
    Inc(Weight, Round(RemapClamped(Player.Hull.Weight, 375, 1000, 1, 4) * SeededRandomIntRange(1, 3, Id * 317847)));
  Ship := ExistingShip;
  if Ship = nil then
  begin
    Ship := TTranclucator.Create;
    Drone := Ship as TTranclucator;
    Drone.InitializeForOwner(OwnerShip as TShip, Owner);
    if OwnerShip <> nil then
    begin
      Drone.CurrentStar.Ships.Delete(Drone.CurrentStar.Ships.IndexOf(Drone));
      Drone.CurrentStar := nil;
    end;
  end;
  Cost := RoundAndTruncateToTens(RemapClamped(Galaxy.TechLevel, 4, 8, 1, 3) * SeededRandomIntRange(1000, 2000, Id + 135671));
  Weight := Round(Weight * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
  Cost := RoundAndTruncateToTens(Cost * DifficultyModifiers[Galaxy.Difficulty].ArtefactFactor);
end;
{ @end $5E0A38 }

{ @routine $5E0C04 TArtefactTranclucator_SaveToBuffer }
procedure TArtefactTranclucator.SaveToBuffer(Buffer: TBufEC);
begin
  inherited SaveToBuffer(Buffer);
  (Ship as TTranclucator).SaveToBuffer(Buffer);
end;
{ @end $5E0C04 }

{ @routine $5E0C2C TArtefactTranclucator_LoadFromBuffer }
procedure TArtefactTranclucator.LoadFromBuffer(Buffer: TBufEC);
begin
  inherited LoadFromBuffer(Buffer);
  Ship := TTranclucator.Create;
  (Ship as TTranclucator).LoadFromBuffer(Buffer);
end;
{ @end $5E0C2C }

{ @routine $5E0C68 TArtefactTranclucator_ClearReferences }
procedure TArtefactTranclucator.ClearReferences;
begin
  inherited ClearReferences;
  (Ship as TTranclucator).ResolveLoadedReferences;
end;
{ @end $5E0C68 }

{ @routine $5E0C88 TArtefactTranclucator_GetDisplayName }
function TArtefactTranclucator.GetDisplayName: WideString;
begin
  if NameOverride <> '' then Result := NameOverride
  else if Ship <> nil then
    Result := LocalizedText('Items.ArtefactTranclucator.Name') + '-' + IntToStr((Ship as TShip).Id)
  else Result := LocalizedText('Items.ArtefactTranclucator.Name');
end;
{ @end $5E0C88 }

{ @routine $5E0D9C TArtefactTranclucator_GetInfoText }
function TArtefactTranclucator.GetInfoText(ColorTag: WideString): WideString;
begin
  Result := LocalizedColorText('Items.ArtefactTranclucator.Text') + GetConditionText;
end;
{ @end $5E0D9C }

{ @routine $5E0E4C TArtefactTranclucator_GetDescriptionText }
function TArtefactTranclucator.GetDescriptionText: WideString;
begin
  Result := LocalizedColorText('Items.ArtefactTranclucator.Description');
end;
{ @end $5E0E4C }

{ @routine $5E0EB4 TArtefactTranclucator_GetFullInfoText }
function TArtefactTranclucator.GetFullInfoText: WideString;
begin
  Result := UpperCaseWideString(WrapTextInColor(GetDisplayName, HighlightColorTag)) + #13#10 +
    GetInfoText(HighlightColorTag) + #13#10 + 'V ' + IntToStr(Weight) + ' / ' +
    LowerCaseWideString(OwnerInfo[OwnerId].DisplayName) + ' / ' + IntToStr(Cost) + ' cr';
end;
{ @end $5E0EB4 }

{ @routine $5E1030 TArtefactTranclucator_GetBitmapResourceName }
function TArtefactTranclucator.GetBitmapResourceName: WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + 'ArtTranclucator_';
end;
{ @end $5E1030 }

{ @routine $5E10C8 CreateItemByType }
function CreateItemByType(Kind: TItemType): TItem;
begin
  Result := nil;
  case Kind of
    t_Food..t_Narcotics: Result := TGoods.Create;
    t_ArtefactHull: Result := TArtefactHull.Create;
    t_ArtefactFuel: Result := TArtefactFuel.Create;
    t_ArtefactSpeed: Result := TArtefactSpeed.Create;
    t_ArtefactPower: Result := TArtefactPower.Create;
    t_ArtefactRadar: Result := TArtefactRadar.Create;
    t_ArtefactScaner: Result := TArtefactScaner.Create;
    t_ArtefactDroid: Result := TArtefactDroid.Create;
    t_ArtefactNano: Result := TArtefactNano.Create;
    t_ArtefactHook: Result := TArtefactHook.Create;
    t_ArtefactDef: Result := TArtefactDef.Create;
    t_ArtefactAnalyzer: Result := TArtefactAnalyzer.Create;
    t_ArtefactMiniExpl: Result := TArtefactMiniExpl.Create;
    t_ArtefactAntigrav: Result := TArtefactAntigrav.Create;
    t_ArtefactTransmitter: Result := TArtefactTransmitter.Create;
    t_ArtefactBomb: Result := TArtefactBomb.Create;
    t_ArtefactTranclucator: Result := TArtefactTranclucator.Create;
    t_Hull: Result := THull.Create;
    t_FuelTanks: Result := TFuelTanks.Create;
    t_Engine: Result := TEngine.Create;
    t_Radar: Result := TRadar.Create;
    t_Scaner: Result := TScaner.Create;
    t_RepairRobot: Result := TRepairRobot.Create;
    t_CargoHook: Result := TCargoHook.Create;
    t_DefGenerator: Result := TDefGenerator.Create;
    t_PhotonGun..t_EyesOfMachpella: Result := TWeapon.Create;
    t_Protoplasm: Result := TProtoplasm.Create;
    t_UselessItem: Result := TUselessItem.Create;
  else
    Exception.Create('Error CreateItemByType'); // Native does not raise or free it.
  end;
end;
{ @end $5E10C8 }

{ @routine $5E13DC GetItemTypeBitmapPath }
function GetItemTypeBitmapPath(Kind: TItemType): WideString;
begin
  Result := 'Bm.Items.' + GiResourceSuffix + ItemTypeNames[Kind];
end;
{ @end $5E13DC }

end.

// Introspection slot for the psi lab
class X2StrategyElement_IntrospectionSlots extends X2StrategyElement_DefaultStaffSlots config(ClassHighlander);

var config bool IntrospectionForced4slot;
var config int IntrospectionUpgradePower;
var config int IntrospectionUpgradeCost;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate>  Templates;
    local X2StaffSlotTemplate    SlotTemplate;

    `LOG("ClassHighlander : CreateTemplates bPsiLabIntro=" $ class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro);

    if (class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro) {
        SlotTemplate = CreateIntrospectionSlotTemplate();
        `LOG("ClassHighlander : SlotTemplate DataName=" $ SlotTemplate.DataName);
        Templates.AddItem(SlotTemplate);
        Templates.AddItem(CreateIntrospectionUpgradeTemplate());
    }

    return Templates;
}

static function X2StaffSlotTemplate CreateIntrospectionSlotTemplate()
{
    local X2StaffSlotTemplate Template;

    Template = CreateStaffSlotTemplate('IntrospectionStaffSlot');
	//Template.strImage				  = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab_SecondCell";
    Template.bSoldierSlot             = true;
    Template.bRequireConfirmToEmpty   = true;
    Template.bPreventFilledPopup      = true;
    Template.UIStaffSlotClass         = class'UIFacility_IntrospectionSlot';
    Template.AssociatedProjectClass   = class'XComGameState_HeadquartersProject_Introspection';
    Template.GetNameDisplayStringFn   = GetIntrospectionSlotName;
    Template.GetBonusDisplayStringFn  = GetIntrospectionSlotBonusDisplayString;
    Template.GetSkillDisplayStringFn  = GetIntrospectionSlotSkillDisplayString;
    Template.FillFn                   = FillIntrospectionSlot;
    Template.EmptyStopProjectFn       = EmptyIntrospectionSlot;
    Template.IsUnitValidForSlotFn     = IsUnitValidForIntrospectionSlot;
	Template.GetValidUnitsForSlotFn   = GetValidUnitsForIntrospectionSlot;
    Template.MatineeSlotName          = "Soldier";

    return Template;
}

static function X2FacilityUpgradeTemplate CreateIntrospectionUpgradeTemplate()
{
    local X2FacilityUpgradeTemplate Template;
    local ArtifactCost              Resources;

    `CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'ClassHighlander_IntrospectionUnlock');

    Template.PointsToComplete = 0;
    Template.MaxBuild         = 1;
    Template.iPower           = default.IntrospectionUpgradePower; // configurable
    //Template.UpkeepCost       = 30;
    Template.strImage         = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab_SecondCell";
    Template.DisplayName      = class'UIFacility_IntrospectionSlot'.default.strUpgradeSlotName;
    Template.Summary          = class'UIFacility_IntrospectionSlot'.default.strUpgradeSlotSummary;
    Template.OnUpgradeAddedFn = OnUpgradeAdded_IntrospectionSlot;

    Resources.ItemTemplateName = 'Supplies';
    Resources.Quantity         = default.IntrospectionUpgradeCost; // configurable
    Template.Cost.ResourceCosts.AddItem(Resources);

    return Template;
}


static function string GetIntrospectionSlotName(XComGameState_StaffSlot SlotState)
{
    local XComGameState_Unit UnitState;
    local string             UnitName;

    if (SlotState.IsLocked())
        return SlotState.GetMyTemplate().LockedText;

    if (SlotState.IsSlotFilled()) {
        UnitState = SlotState.GetAssignedStaff();
        if (UnitState != none) {
            UnitName = SlotState.GetMyTemplate().FilledText;
            UnitName = Repl(UnitName, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
            return UnitName;
        }
    }

    return SlotState.GetMyTemplate().EmptyText;
}

static function string GetIntrospectionSlotBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
    if (SlotState.IsLocked())       return "";
    if (SlotState.IsSlotFilled())   return SlotState.GetMyTemplate().BonusText;

    return SlotState.GetMyTemplate().BonusEmptyText;
}

static function string GetIntrospectionSlotSkillDisplayString(XComGameState_StaffSlot SlotState)
{
    `LOG("ClassHighlander : BonusDefaultText='" $ SlotState.GetMyTemplate().BonusDefaultText $ "'");

    return SlotState.GetMyTemplate().BonusDefaultText;
}

static function FillIntrospectionSlot(
    XComGameState NewGameState,
    StateObjectReference SlotRef,
    StaffUnitInfo UnitInfo,
    optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProject_Introspection ProjectState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

 	ProjectState = XComGameState_HeadquartersProject_Introspection(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProject_Introspection'));
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

    `LOG("ClassHighlander : Introspection started for " $ NewUnitState.GetFullName());
}

static function EmptyIntrospectionSlot(StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot                         SlotState;
	local XComGameState_HeadquartersXCom                  XComHQ;
	local XComGameState_HeadquartersProject_Introspection Project;
    local XComGameState_Unit                              UnitState;
	local XComGameState									  NewGameState;

	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ClassHighlander Introspection Cancel");

    XComHQ = XComGameState_HeadquartersXCom(
        NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom',
        XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom')).ObjectID)
    );

    // Find and cancel the project
	Project = GetIntroProject(XComHQ, SlotState.GetAssignedStaffRef());
	if (Project != none) {
		XComHQ.Projects.RemoveItem(Project.GetReference());
        NewGameState.PurgeGameStateForObjectID(Project.ObjectID);
        `LOG("ClassHighlander : Introspection project canceled.");
	}

	UnitState = SlotState.GetAssignedStaff(); //in case they're still in there

	if (UnitState != none) {
	    UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
        UnitState.SetStatus(eStatus_Active);
	}

	SlotState = XComGameState_StaffSlot(NewGameState.ModifyStateObject(class'XComGameState_StaffSlot', SlotState.ObjectID));
    SlotState.EmptySlot(NewGameState);
    `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

    `LOG("ClassHighlander : Introspection canceled.");
}

static function bool IsUnitValidForIntrospectionSlot(
    XComGameState_StaffSlot SlotState,
    StaffUnitInfo UnitInfo)
{
    local XComGameState_Unit UnitState;
    local X2SoldierClassTemplate ClassTemplate;

	// Basic check (staffability, soldier type, etc.)
    if (!class'X2StrategyElement_DefaultStaffSlots'.static.IsUnitValidForSlotDefault(SlotState, UnitInfo))
        return false;

    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (UnitState == none) return false;
    //if (!UnitState.IsSoldier()) return false;
    //if (UnitState.GetStatus() != eStatus_Active) return false;

	ClassTemplate = UnitState.GetSoldierClassTemplate();
	
    // Only soldier with allowed awcabilities and active
    if (ClassTemplate == none) return false;
    if (UnitState.GetStatus() != eStatus_Active) return false;
    if (!ClassTemplate.bAllowAWCAbilities) return false;

    //if (!UnitState.bRolledForAWCAbility) return false;

    return true;
}

static function array<StaffUnitInfo> GetValidUnitsForIntrospectionSlot(
    XComGameState_StaffSlot SlotState)
{
    local XComGameStateHistory              History;
    local XComGameState_HeadquartersXCom    XComHQ;
    local XComGameState_Unit                UnitState;
    local StaffUnitInfo                     UnitInfo;
    local array<StaffUnitInfo>              ValidUnits;
    local int                               i;

    History = `XCOMHISTORY;
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

    for (i = 0; i < XComHQ.Crew.Length; i++) {
        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
        if (UnitState == none) continue;

        UnitInfo.UnitRef = UnitState.GetReference();

        if (SlotState.ValidUnitForSlot(UnitInfo)) {
            ValidUnits.AddItem(UnitInfo);
        }
    }

    `LOG("ClassHighlander : GetValidUnitsForIntrospectionSlot -> " $ ValidUnits.Length $ " soldat(s) valide(s).");

    return ValidUnits;
}

static function XComGameState_HeadquartersProject_Introspection GetIntroProject(XComGameState_HeadquartersXCom XComHQ, StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProject_Introspection Project;

	for (idx = 0; idx < XComHQ.Projects.Length; idx++) {
		Project = XComGameState_HeadquartersProject_Introspection(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if (Project != none) {
			if (UnitRef == Project.ProjectFocus) {
				return Project;
			}
		}
	}

	return none;
}

static function OnUpgradeAdded_IntrospectionSlot(
    XComGameState NewGameState,
    XComGameState_FacilityUpgrade Upgrade,
    XComGameState_FacilityXCom Facility)
{
    local XComGameState_StaffSlot       SlotState;
    local XComGameState_FacilityXCom    FacilityState;
    local int                           i;

    FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', Facility.ObjectID));
    if (FacilityState == none) return;

    for (i = 0; i < FacilityState.StaffSlots.Length; i++) {
        SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(FacilityState.StaffSlots[i].ObjectID));
        if (SlotState == none)        continue;
        if (!SlotState.IsLocked())    continue;

        // Unlock ONLY our Introspection slot
        if (SlotState.GetMyTemplateName() == 'IntrospectionStaffSlot' && SlotState.IsLocked()) {
            SlotState = XComGameState_StaffSlot(NewGameState.ModifyStateObject(class'XComGameState_StaffSlot', SlotState.ObjectID));
            SlotState.UnlockSlot();
            `LOG("ClassHighlander : Slot IntrospectionStaffSlot unlocked.");
            return;
        }
    }

    `LOG("ClassHighlander [WARN] : No IntrospectionStaffSlot locked found.");
}
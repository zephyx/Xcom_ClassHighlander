// This project will allow soldier to reset their xcom row
class XComGameState_HeadquartersProject_Introspection extends XComGameState_HeadquartersProject config(ClassHighlander);

var localized string strIntrospectionCompleteLabel;
var localized string strIntrospectionEventLabel;
var localized string strIntrospectionPausedLabel;

var config bool bPsiLabIntro;
var config int  IntrospectionDays;
var config int  IntrospectionMeldCost;
var config int  IntrospectionSuppliesCost;

function string GetProjectDisplayName()
{
    local XComGameState_Unit UnitState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
    if (UnitState != none) {
        return "Introspection" @ "-" @ UnitState.GetName(eNameType_RankFull);
    }

    return "Introspection";
}

function string GetDisplayImage()
{
    local XComGameState_Unit UnitState;
    UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
    if (UnitState != none && UnitState.GetSoldierClassTemplate() != none) {
        return UnitState.GetSoldierClassTemplate().IconImage;
    }

    return "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab";
}

function bool CanBeDisplayedInQueue()
{
    return true;
}

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory              History;
	local XComGameState_GameTime            TimeState;
	local XComGameState_Unit                UnitState;
	local XComGameState_HeadquartersXCom    XComHQ;
	local StrategyCost                      Cost;
	local array<StrategyCostScalar>         CostScalars;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility

	// Pay the cost
    XComHQ = XComGameState_HeadquartersXCom(
        NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom',
            XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(
                class'XComGameState_HeadquartersXCom')).ObjectID)
    );
    Cost = GetIntrospectionCost();
    CostScalars.Length = 0;
    XComHQ.PayStrategyCost(NewGameState, Cost, CostScalars);

    UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
    UnitState.SetStatus(eStatus_Training);

	ProjectPointsRemaining = default.IntrospectionDays * 24;
    InitialProjectPoints = ProjectPointsRemaining;

    `LOG("ClassHighlander ProjectPointsRemaining " $ ProjectPointsRemaining);

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none) {
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime)) {
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if (MakingProgress()) {
		SetProjectedCompletionDateTime(StartDateTime);
	} else {
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

//---------------------------------------------------------------------------------------
// Reroll abilities and Remove the project
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQ;
	local XComGameState_Unit Unit; //the veteran who was teaching everyone
	local XComGameState_Unit UpdatedUnit; //the veteran who is done teaching everyone
	local XComGameState UpdateState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_HeadquartersProject_Introspection ProjectState;
	local XComGameState_StaffSlot StaffSlotState;

	`LOG("ClassHighlander Introspection : Project completed");

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));

	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("ClassHighlander Introspection Complete");
	UpdateState = History.CreateNewGameState(true, ChangeContainer);
	UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));

	if (UpdatedUnit != none) {
        ResetXComRow(UpdatedUnit, UpdateState);
        UpdatedUnit.SetStatus(eStatus_Active);
        `LOG("ClassHighlander Introspection : XCom row reset for " $ UpdatedUnit.GetFullName());
    }

	ProjectState = XComGameState_HeadquartersProject_Introspection(`XCOMHISTORY.GetGameStateForObjectID(GetReference().ObjectID));
	if (ProjectState != none) {
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none) {
			NewXComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			UpdateState.AddStateObject(NewXComHQ);
			NewXComHQ.Projects.RemoveItem(ProjectState.GetReference());
			UpdateState.RemoveStateObject(ProjectState.ObjectID);
		}

		// Remove the soldier from the staff slot
		StaffSlotState = UpdatedUnit.GetStaffSlot();
		if (StaffSlotState != none) {
			StaffSlotState = XComGameState_StaffSlot(UpdateState.ModifyStateObject(class'XComGameState_StaffSlot', StaffSlotState.ObjectID));
			StaffSlotState.EmptySlot(UpdateState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(UpdateState);

	//UIIntrospectionComplete(ProjectFocus);

	`HQPRES.NotifyBanner(ProjectCompleteNotification, class'UIUtilities_Image'.const.EventQueue_Staff, strIntrospectionCompleteLabel, Unit.GetName(eNameType_RankFull), eUIState_Good);
}

static function ResetXComRow(XComGameState_Unit UnitState, XComGameState NewGameState)
{
    local X2SoldierClassTemplate         ClassTemplate;
    local array<SoldierClassAbilitySlot> AllAbilitySlots;
    local SoldierClassAbilitySlot        AbilitySlot;
    local SoldierClassAbilityType        EmptyAbility;
    local SCATProgression                ProgressionInfo;
    local array<SCATProgression>         ProgressionToKeep;
    local array<SoldierClassRandomAbilityDeck> RandomDecks;
    local int                            Rank, Branch, APRefund, DeckIndex, RandIndex;

    ClassTemplate = UnitState.GetSoldierClassTemplate();
    if (ClassTemplate == none) return;

    APRefund = 0;

    // I) : Give back AP from bought XCom row abilities et remove them from m_SoldierProgressionAbilties
    foreach UnitState.m_SoldierProgressionAbilties(ProgressionInfo) {
        Rank   = ProgressionInfo.iRank;
        Branch = ProgressionInfo.iBranch;

        if (Rank >= ClassTemplate.GetMaxConfiguredRank()) continue;

        AllAbilitySlots = ClassTemplate.GetAbilitySlots(Rank);
        if (Branch >= AllAbilitySlots.Length) { ProgressionToKeep.AddItem(ProgressionInfo); continue; }

        AbilitySlot = AllAbilitySlots[Branch];

        if (AbilitySlot.RandomDeckName != '') {
            // This is a XCom row perk → give back AP
            APRefund += GetXComRowAbilityCost(UnitState, Rank, Branch);
            `LOG("ClassHighlander : AWC bought Rank=" $ Rank $ " Branch=" $ Branch $ " RandomDeck=" $ AbilitySlot.RandomDeckName);
        } else {
            ProgressionToKeep.AddItem(ProgressionInfo);
        }
    }

	UnitState.SetSoldierProgression(ProgressionToKeep);
    
    UnitState.SetSoldierProgression(ProgressionToKeep);
    UnitState.AbilityPoints      += APRefund;
    UnitState.SpentAbilityPoints -= APRefund;
    if (UnitState.SpentAbilityPoints < 0) UnitState.SpentAbilityPoints = 0;

    // II) : empty the RandomDeck slots in AbilityTree
    for (Rank = 0; Rank < UnitState.AbilityTree.Length; Rank++) {
        if (Rank >= ClassTemplate.GetMaxConfiguredRank()) continue;

        AllAbilitySlots = ClassTemplate.GetAbilitySlots(Rank);

        for (Branch = 0; Branch < AllAbilitySlots.Length; Branch++) {
            if (Branch >= UnitState.AbilityTree[Rank].Abilities.Length) break;

            AbilitySlot = AllAbilitySlots[Branch];
            if (AbilitySlot.RandomDeckName != '') {
                UnitState.AbilityTree[Rank].Abilities[Branch] = EmptyAbility;
                `LOG("ClassHighlander : AWC Perk emptied Rank=" $ Rank $ " Branch=" $ Branch);
            }
        }
    }

    // III) : re-roll
    RandomDecks = ClassTemplate.RandomAbilityDecks;

    for (Rank = 0; Rank < UnitState.AbilityTree.Length; Rank++) {
        if (Rank >= ClassTemplate.GetMaxConfiguredRank()) continue;

        AllAbilitySlots = ClassTemplate.GetAbilitySlots(Rank);

        for (Branch = 0; Branch < AllAbilitySlots.Length; Branch++) {
            if (Branch >= UnitState.AbilityTree[Rank].Abilities.Length) break;

            AbilitySlot = AllAbilitySlots[Branch];
            if (AbilitySlot.RandomDeckName == '') continue;

            DeckIndex = RandomDecks.Find('DeckName', AbilitySlot.RandomDeckName);
            if (DeckIndex == INDEX_NONE) continue;
            if (RandomDecks[DeckIndex].Abilities.Length == 0) continue;

            // Draw randomly an ability from the deck
            RandIndex = Rand(RandomDecks[DeckIndex].Abilities.Length);
            UnitState.AbilityTree[Rank].Abilities[Branch] = RandomDecks[DeckIndex].Abilities[RandIndex];

            // Remove the ability from the local deck in order to avoid duplicates
            RandomDecks[DeckIndex].Abilities.Remove(RandIndex, 1);

            `LOG("ClassHighlander : New AWC perk Rank=" $ Rank $ " Branch=" $ Branch $ " Ability=" $ UnitState.AbilityTree[Rank].Abilities[Branch].AbilityName);
        }
    }

    UnitState.bRolledForAWCAbility = true;

    `LOG("ClassHighlander : Reset XCom row end. AP gave back=" $ APRefund);
}

// Calculate the AP cost of an XCom row ability
static function int GetXComRowAbilityCost(XComGameState_Unit UnitState, int Rank, int Branch)
{
    local X2SoldierClassTemplate         ClassTemplate;
    local array<SoldierClassAbilitySlot> AllSlots;

    ClassTemplate = UnitState.GetSoldierClassTemplate();
    if (ClassTemplate == none) return 0;

    AllSlots = ClassTemplate.GetAbilitySlots(Rank);
    if (Branch >= AllSlots.Length) return 0;

    // Check if this is really an XCom row perk (random deck)
    if (AllSlots[Branch].RandomDeckName == '') return 0;

    // Standard cost for this rank
    if (Rank >= class'X2StrategyGameRulesetDataStructures'.default.AbilityPointCosts.Length)
        return 0;

    return class'X2StrategyGameRulesetDataStructures'.default.AbilityPointCosts[Rank];
}

static function StrategyCost GetIntrospectionCost()
{
    local StrategyCost      Cost;
    local ArtifactCost      ResourceCost;

    `LOG("ClassHighlander : MELD COST=" $ default.IntrospectionMeldCost $ " Supplies=" $ default.IntrospectionSuppliesCost);

    if (class'ClassHighlander_Utils'.static.IsModActive('MeldForLWOTC')
     || class'ClassHighlander_Utils'.static.IsModActive('PexM_Meld_Standalone')
     || class'ClassHighlander_Utils'.static.IsModActive('PsionicsExMachina'))
    {
        ResourceCost.ItemTemplateName = 'InertMeld';
        ResourceCost.Quantity         = default.IntrospectionMeldCost;
    }
    else
    {
        ResourceCost.ItemTemplateName = 'Supplies';
        ResourceCost.Quantity         = default.IntrospectionSuppliesCost;
    }

    Cost.ResourceCosts.AddItem(ResourceCost);
    return Cost;
}

/*
function UIIntrospectionComplete(StateObjectReference UnitRef)
{
	local XComHQPresentationLayer HQPres;
	local DynamicPropertySet PropertySet;
	HQPres = `HQPres;

	`LOG("ClassHighlander Introspection : Project completed Popup");

	//HQPres.BuildUIAlert(PropertySet, 'eAlert_RM_WeaponTrainingComplete', TrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_IntrospectionComplete', 'UIAlert_Introspection', NewIntrospectionCompleteCB, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Unreal2DSounds_FoundryComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	HQPres.QueueDynamicPopup(PropertySet);
}

static function NewIntrospectionCompleteCB(name eAction, out DynamicPropertySet AlertData, optional bool isInstant = false)
{
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPres;

	if (!HQPres.m_kAvengerHUD.Movie.Stack.HasInstanceOf(class'UIArmory_MainMenu')) // If we are already observing the soldier that was trained, just close the popup
	{
		`GAME.GetGeoscape().Resume();
	}
}*/

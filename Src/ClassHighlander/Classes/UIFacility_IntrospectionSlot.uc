class UIFacility_IntrospectionSlot extends UIFacility_StaffSlot config(ClassHighlander) dependson(UIPersonnel);

var localized string strIntrospectionDialogTitle;
var localized string strIntrospectionDialogText;
var localized string strIntrospectionNotEnoughResourcesTitle;
var localized string strIntrospectionNotEnoughResourcesText;
var localized string strStopIntrospectionDialogTitle;
var localized string strStopIntrospectionDialogText;
var localized string strUpgradeSlotName;
var localized string strUpgradeSlotSummary;
var localized string strUpgradeFacilityName;


simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);

	return self;
}

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string StopRemovingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty()) {
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		UnitState = StaffSlot.GetAssignedStaff();

		StopRemovingText = strStopIntrospectionDialogText;
		StopRemovingText = Repl(StopRemovingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

		ConfirmEmptyProjectSlotPopup(strStopIntrospectionDialogTitle, StopRemovingText);
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
		
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.IntValue0 = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionDays;
	LocTag.IntValue1 = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionMeldCost;
	LocTag.IntValue2 = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionSuppliesCost;

	DialogData.strText = `XEXPAND.ExpandString(strIntrospectionDialogText);

	`LOG("ClassHighlander : MELD COST 2=" $ LocTag.IntValue1 $ " Supplies=" $ LocTag.IntValue2);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = IntrospectionDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = strIntrospectionDialogTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function IntrospectionDialogCallback(Name eAction, UICallbackData xUserData)
{
	local XComGameState_StaffSlot               SlotState;
    local UICallbackData_StateObjectReference   CallbackData;
    local StaffUnitInfo                         UnitInfo;
    local StrategyCost                          Cost;
    local array<StrategyCostScalar>             CostScalars;
    local TDialogueBoxData                      DialogData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == 'eUIAction_Accept') {
	    // Check resources BEFORE launching the project
        Cost = class'XComGameState_HeadquartersProject_Introspection'.static.GetIntrospectionCost();
        CostScalars.Length = 0;

        if (!`XCOMHQ.CanAffordAllStrategyCosts(Cost, CostScalars))
        {
            // Not enough resources -> display a message and cancel
            DialogData.eType     = eDialog_Alert;
            DialogData.strTitle  = strIntrospectionNotEnoughResourcesTitle;
            DialogData.strText   = `XEXPAND.ExpandString(strIntrospectionNotEnoughResourcesText);
            DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOk;
            Movie.Pres.UIRaiseDialog(DialogData);
            return;
        }

		SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
        if (SlotState != none) {
            UnitInfo.UnitRef = CallbackData.ObjectRef;
            SlotState.FillSlot(UnitInfo);
            `XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
        }

		// Refresh delayed - wait the game state to be ready before refreshing UI
        SetTimer(0.1f, false, 'DelayedUpdateData');
	}
}

simulated function DelayedUpdateData()
{
    UpdateData();
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}

//---------------------------------------------------------------------------------------
//  FILE:    UIAlert_IntrospectionComplete.uc
//  AUTHOR:  RealityMachina (using Long War Studio's Officer Pack as a base) modified by zephyx
//  PURPOSE: Customized UI Alert for Veteran training 
//
//---------------------------------------------------------------------------------------
class UIAlert_IntrospectionComplete extends UIAlert;

var localized string m_strTraitLabel;
var localized string m_strIntrospectionCompleteLabel;

//override for UIAlert child to trigger specific Alert built in this class
simulated function BuildAlert()
{
	BindLibraryItem();
	BuildIntrospectionCompleteAlert(m_strIntrospectionCompleteLabel);
}

//New Alert building function
simulated function BuildIntrospectionCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local XComGameState_ResistanceFaction FactionState;
	local string ClassIcon, ClassName, RankName;
	if (LibraryPanel == none) {
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));
	
	FactionState = UnitState.GetResistanceFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	//Set icons before hiding the button.
	Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	
	//bsg-crobinson (5.17.17): Buttons need to be in a different area for this screen
	Button1.OnSizeRealized = OnTrainingButtonRealized;
	Button2.OnSizeRealized = OnTrainingButtonRealized;
	//bsg-crobinson (5.17.17): end

	// Hide "View Soldier" button if player is on top of avenger, prevents ui state stack issues
	if (Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion')) {
		Button1.Hide(); 
		Button1.DisableNavigation();
	}

	if (FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());
}

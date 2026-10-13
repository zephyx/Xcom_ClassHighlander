//---------------------------------------------------------------------------------------
//  FILE:   ClassHighlander_MCMScreen.uc
//  PURPOSE: The ClassHighlander page of the Mod Config Menu. Only created by UIScreenListener_CH_MCM when MCM's options screen exists.
//           - Every label ends with "(?)": MCM has no icon, the description is the hover tooltip of the whole row; it also gives the mod's ini value.
//           - A "*" in a label means the value is read when the game starts (templates): the change applies at the next launch.
//           - Save: only what the player CHANGED is stored (ClassHighlander_MCMSettings.StoreValue: a value equal to XComClassHighlander.ini goes back to
//             "follows the ini"), then the file is written once and the values are applied at once.
//           - Reset: every widget goes back to the ini value; saving then erases the player's choices. Cancel changes nothing.
//           - Fallback classes: one spinner per selectable class (not multiplayer-only, NumInDeck > 0 like the promotion pool, plus the classes already in the ini's
//             FallbackClass; Rookie and PsiOperative excluded): Unique / Soft fallback / Hard fallback. There must always be one fallback class: a change that would
//             leave none is undone (FallbackChanged) and explained in a dialog.
//---------------------------------------------------------------------------------------
class ClassHighlander_MCMScreen extends Object;

const HELP_MARK = " (?)";
const LOC_SECTION = "ClassHighlander_MCMScreen";

var localized string TabName, PageTitle, GroupClasses, GroupIntrospection, NoteRestart, TipModDefault, TipOn, TipOff;
var localized string GroupFallback, FallbackHelpLabel, FallbackHelpTip, ModeUnique, ModeSoft, ModeHard, TipClassId, NoFallbackTitle, NoFallbackText;

// One entry per widget, parallel arrays (a struct of one class cannot be used from another in ModBuddy's compile order).
var array<name> OptKeys;
var array<MCM_API_Checkbox> OptChecks;      // none for a slider
var array<MCM_API_Slider> OptSliders;       // none for a checkbox
var array<int> OptInitial;                  // the value the widget had when the page was built / last saved

// The fallback class spinners (parallel arrays). Modes: 0 = unique, 1 = soft fallback, 2 = hard fallback.
var array<name> FbClasses;
var array<MCM_API_Spinner> FbSpinners;
var array<int> FbCurrent;                   // the mode the spinner has (the last one accepted)
var array<int> FbInitial;                   // the mode when the page was built / last saved

var UIScreen OptionsScreen;                 // MCM's options screen, to raise the dialog on

event OnInit(UIScreen Screen)
{
	local MCM_API MCMScreen;

	MCMScreen = MCM_API(Screen);
	if (MCMScreen != none)
	{
		OptionsScreen = Screen;
		MCMScreen.RegisterClientMod(1, 0, ClientModCallback);
		`LOG("ClassHighlander : MCM page registered on" @ Screen.Class);
	}
}

// Called each time the player opens MCM: the widget lists are rebuilt.
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	OptKeys.Length = 0;
	OptChecks.Length = 0;
	OptSliders.Length = 0;
	OptInitial.Length = 0;
	FbClasses.Length = 0;
	FbSpinners.Length = 0;
	FbCurrent.Length = 0;
	FbInitial.Length = 0;

	Page = ConfigAPI.NewSettingsPage(TabName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('CH_Classes', GroupClasses);
	AddCheck(Group, 'bMultiplePsiSoldiers', true);

	BuildFallbackGroup(Page);

	Group = Page.AddGroup('CH_Introspection', GroupIntrospection);
	AddCheck(Group, 'bPsiLabIntro', true);
	AddCheck(Group, 'IntrospectionForced4slot', true);
	AddSlider(Group, 'IntrospectionDays', 1, 30, 1, false);
	AddSlider(Group, 'IntrospectionMeldCost', 0, 100, 1, false);
	AddSlider(Group, 'IntrospectionSuppliesCost', 0, 500, 5, false);
	AddSlider(Group, 'IntrospectionUpgradePower', -10, 10, 1, true);
	AddSlider(Group, 'IntrospectionUpgradeCost', 0, 500, 10, true);

	Page.ShowSettings();
}

// The "Fallback classes" group: one spinner per selectable class, sorted by name.
simulated function BuildFallbackGroup(MCM_API_SettingsPage Page)
{
	local MCM_API_SettingsGroup Group;
	local MCM_API_Spinner SpinnerWidget;
	local array<name> Names;
	local array<string> Titles;
	local int i, Mode;

	Group = Page.AddGroup('CH_Fallback', GroupFallback);
	Group.AddLabel('CH_FallbackHelp', FallbackHelpLabel $ HELP_MARK, FallbackHelpTip);

	BuildClassList(Names, Titles);

	for (i = 0; i < Names.Length; ++i)
	{
		Mode = class'ClassHighlander_Utils'.static.IsHardFallback(Names[i]) ? 2 : (class'ClassHighlander_Utils'.static.IsSoftFallback(Names[i]) ? 1 : 0);

		SpinnerWidget = Group.AddSpinner(name("CH_FB_" $ Names[i]), Titles[i] $ HELP_MARK,
			TipClassId @ Names[i] $ "\n" $ TipModDefault @ ModeLabel(class'ClassHighlander_MCMSettings'.static.GetIniFallbackMode(Names[i])),
			GetModeLabels(), ModeLabel(Mode), , FallbackChanged);

		FbClasses.AddItem(Names[i]);
		FbSpinners.AddItem(SpinnerWidget);
		FbCurrent.AddItem(Mode);
		FbInitial.AddItem(Mode);
	}
}

// The classes a fallback mode can be chosen for, sorted by display name: real soldier classes (not multiplayer-only) of the random pool (NumInDeck > 0, the same
// criterion as the promotion pool, which leaves out the faction heroes, the Sparks, the MECs...) plus those the ini already lists as fallback (a hard fallback like
// PR_Mercenary may be outside the pool). Rookie and PsiOperative (own option) are left out.
simulated function BuildClassList(out array<name> Names, out array<string> Titles)
{
	local X2SoldierClassTemplateManager Mgr;
	local X2DataTemplate DataTemplate;
	local X2SoldierClassTemplate ClassTemplate;
	local array<name> Listed;
	local string Title;
	local int i, Position;

	Listed = class'ClassHighlander_MCMSettings'.static.GetIniFallbackNames();
	Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach Mgr.IterateTemplates(DataTemplate, none)
	{
		ClassTemplate = X2SoldierClassTemplate(DataTemplate);
		if (ClassTemplate == none || ClassTemplate.bMultiplayerOnly)
			continue;
		if (ClassTemplate.DataName == 'Rookie' || ClassTemplate.DataName == 'PsiOperative')
			continue;
		if (ClassTemplate.NumInDeck <= 0 && Listed.Find(ClassTemplate.DataName) == INDEX_NONE)
			continue;

		Title = ClassTemplate.DisplayName;
		if (Title == "")
			Title = string(ClassTemplate.DataName);

		Position = Titles.Length;
		for (i = 0; i < Titles.Length; ++i)
		{
			if (Caps(Titles[i]) > Caps(Title))
			{
				Position = i;
				break;
			}
		}

		Names.InsertItem(Position, ClassTemplate.DataName);
		Titles.InsertItem(Position, Title);
	}
}

simulated function array<string> GetModeLabels()
{
	local array<string> Labels;

	Labels.AddItem(ModeUnique);
	Labels.AddItem(ModeSoft);
	Labels.AddItem(ModeHard);

	return Labels;
}

simulated function string ModeLabel(int Mode)
{
	return Mode == 2 ? ModeHard : (Mode == 1 ? ModeSoft : ModeUnique);
}

simulated function int ModeFromLabel(string Label)
{
	return Label == ModeHard ? 2 : (Label == ModeSoft ? 1 : 0);
}

// A spinner changed (only fired by the player). The mod needs at least one fallback class: if this change leaves none, it is undone and a dialog says why.
simulated function FallbackChanged(MCM_API_Setting Setting, string NewValue)
{
	local int i, Index, Previous, Count;

	Index = INDEX_NONE;
	for (i = 0; i < FbSpinners.Length; ++i)
	{
		if (FbSpinners[i].GetName() == Setting.GetName())
		{
			Index = i;
			break;
		}
	}

	if (Index == INDEX_NONE)
		return;

	Previous = FbCurrent[Index];
	FbCurrent[Index] = ModeFromLabel(NewValue);

	for (i = 0; i < FbCurrent.Length; ++i)
	{
		if (FbCurrent[i] != 0)
			++Count;
	}

	if (Count == 0)
	{
		FbCurrent[Index] = Previous;
		FbSpinners[Index].SetValue(ModeLabel(Previous), true);
		RaiseNoFallbackDialog();
	}
}

simulated function RaiseNoFallbackDialog()
{
	local TDialogueBoxData DialogData;

	if (OptionsScreen == none || OptionsScreen.Movie == none || OptionsScreen.Movie.Pres == none)
		return;

	DialogData.eType     = eDialog_Alert;
	DialogData.strTitle  = NoFallbackTitle;
	DialogData.strText   = NoFallbackText;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOk;

	OptionsScreen.Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function AddCheck(MCM_API_SettingsGroup Group, name Key, bool bRestart)
{
	local MCM_API_Checkbox CheckWidget;
	local int Current;

	Current = class'ClassHighlander_MCMSettings'.static.GetCurrent(Key);
	CheckWidget = Group.AddCheckbox(name("CH_" $ Key), GetLabel(Key, bRestart), GetTip(Key, bRestart, true), Current != 0);

	OptKeys.AddItem(Key);
	OptChecks.AddItem(CheckWidget);
	OptSliders.AddItem(none);
	OptInitial.AddItem(Current);
}

// The bounds are widened to include a current value outside of them (an ini edited by hand).
simulated function AddSlider(MCM_API_SettingsGroup Group, name Key, int SliderMin, int SliderMax, int SliderStep, bool bRestart)
{
	local MCM_API_Slider SliderWidget;
	local int Current;

	Current = class'ClassHighlander_MCMSettings'.static.GetCurrent(Key);
	SliderWidget = Group.AddSlider(name("CH_" $ Key), GetLabel(Key, bRestart), GetTip(Key, bRestart, false),
		float(Min(SliderMin, Current)), float(Max(SliderMax, Current)), float(SliderStep), float(Current));
	SliderWidget.SetValueDisplayFilter(FormatWhole);

	OptKeys.AddItem(Key);
	OptChecks.AddItem(none);
	OptSliders.AddItem(SliderWidget);
	OptInitial.AddItem(Current);
}

simulated function string GetLabel(name Key, bool bRestart)
{
	return Localize(LOC_SECTION, string(Key) $ "_Label", "ClassHighlander") $ (bRestart ? " *" : "") $ HELP_MARK;
}

// The description, then "Mod default: X" (the ini value, ignoring what the player chose) and, for a template value, the restart note.
simulated function string GetTip(name Key, bool bRestart, bool bBool)
{
	local string Tip, IniText;
	local int IniValue;

	IniValue = class'ClassHighlander_MCMSettings'.static.GetIni(Key);
	IniText = bBool ? (IniValue != 0 ? TipOn : TipOff) : string(IniValue);

	Tip = Localize(LOC_SECTION, string(Key) $ "_Tip", "ClassHighlander") $ "\n" $ TipModDefault @ IniText;
	if (bRestart)
		Tip $= "\n" $ NoteRestart;

	return Tip;
}

simulated function string FormatWhole(float Value)
{
	return string(Round(Value));
}

// Stores what the player changed, writes the file once, then applies the values.
simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	local int i, Value;

	for (i = 0; i < OptKeys.Length; ++i)
	{
		if (OptChecks[i] != none)
			Value = OptChecks[i].GetValue() ? 1 : 0;
		else
			Value = Round(OptSliders[i].GetValue());

		if (Value == OptInitial[i])
			continue;

		class'ClassHighlander_MCMSettings'.static.StoreValue(OptKeys[i], Value);
		OptInitial[i] = Value;
	}

	for (i = 0; i < FbSpinners.Length; ++i)
	{
		Value = ModeFromLabel(FbSpinners[i].GetValue());
		if (Value == FbInitial[i])
			continue;

		class'ClassHighlander_MCMSettings'.static.StoreValue(class'ClassHighlander_MCMSettings'.static.GetFallbackKey(FbClasses[i]), Value);
		FbInitial[i] = Value;
	}

	class'ClassHighlander_MCMSettings'.static.Commit();
	class'ClassHighlander_MCMSettings'.static.ApplyOverrides();
	// If none of the fallback classes is valid in this game, a replacement is picked again (as at the start of the game).
	class'X2DownloadableContentInfo_ClassHighlander'.static.ValidateAndSetFallbackClass();
	`LOG("ClassHighlander : MCM settings saved.");
}

// Every widget back to the ini value (saving then erases the player's choices).
simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	local int i, IniValue;

	for (i = 0; i < OptKeys.Length; ++i)
	{
		IniValue = class'ClassHighlander_MCMSettings'.static.GetIni(OptKeys[i]);
		if (OptChecks[i] != none)
			OptChecks[i].SetValue(IniValue != 0, true);
		else
			OptSliders[i].SetValue(float(IniValue), true);
	}

	for (i = 0; i < FbSpinners.Length; ++i)
	{
		FbCurrent[i] = class'ClassHighlander_MCMSettings'.static.GetIniFallbackMode(FbClasses[i]);
		FbSpinners[i].SetValue(ModeLabel(FbCurrent[i]), true);
	}
}

class UIScreenListener_ChooseClass_CH extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    local UIChooseClass ChooseScreen;

    ChooseScreen = UIChooseClass(Screen);
    if (ChooseScreen == none) return;

    FilterOccupiedClasses(ChooseScreen);
}

event OnReceiveFocus(UIScreen Screen)
{
    local UIChooseClass ChooseScreen;

    ChooseScreen = UIChooseClass(Screen);
    if (ChooseScreen == none) return;

    FilterOccupiedClasses(ChooseScreen);
}

// Fallback hiding classes that would have not been properly excluded before.
private function FilterOccupiedClasses(UIChooseClass Screen)
{
    local array<name>			LockedClasses;
    local bool			        HasAvailableClasses;
    local UIPanel				Item;
    local int					i, HiddenCount;
    local name					ClassName;
	local EClassCheckContext	checkType;

	// GTS
	if (Screen.Class.Name == 'UIChooseClass') {
		checkType = eClassCheck_GTS;
	} else {
		checkType = eClassCheck_Promotion;
	}

    LockedClasses = class'ClassHighlander_Utils'.static.GetAllLockedClasses(checkType);
    HasAvailableClasses = class'ClassHighlander_Utils'.static.HasAvailableClasses(checkType);

    if (LockedClasses.Length == 0)          return;
    if (Screen.m_arrClasses.Length == 0)    return;
    if (Screen.List.ItemCount == 0)         return;

    for (i = Screen.m_arrClasses.Length - 1; i >= 0; i--) {
        if (Screen.m_arrClasses[i] == none) continue;
        ClassName = Screen.m_arrClasses[i].DataName;

        // class available
        if (LockedClasses.Find(ClassName) == INDEX_NONE) continue;
        // no class available but this class is a fallback
        if (!HasAvailableClasses && class'ClassHighlander_Utils'.static.IsAnyFallback(ClassName)) continue;

        // otherwise hide this class
        Item = Screen.List.GetItem(i);
        if (Item != none) {
            Item.Hide();
            HiddenCount++;
            `LOG("ClassHighlander [fallback UI] : Hide -> " $ ClassName);
        }
    }

    if (HiddenCount > 0)
        Screen.List.RealizeItems();
}

defaultproperties
{
    ScreenClass = none;
}
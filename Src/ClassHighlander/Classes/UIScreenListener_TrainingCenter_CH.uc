class UIScreenListener_TrainingCenter_CH extends UIScreenListener;

var localized string strNoMECClassAvailableTitle;
var localized string strNoMECClassAvailableText;

event OnInit(UIScreen Screen)
{
	local UISimpleCommodityScreen   CommodityScreen;
	local array<string>             LockedTitles;
	local bool                      bItemAvailable;
	local int                       j, k;
	local string                    ItemTitle;
	local bool                      bTitleLocked;
	local TDialogueBoxData			DialogData;

    //This allow us to prevent the fallback MEC class to be displayed: no class is available
    if (Screen.Class.Name == 'UIChooseMEC') {
		`LOG("ClassHighlander TC : UIChooseMEC detected.");

		LockedTitles = class'ClassHighlander_Utils'.default.PendingLockedMECTitles;
		class'ClassHighlander_Utils'.default.PendingLockedMECTitles.Length = 0;

		if (LockedTitles.Length == 0) return;

		CommodityScreen = UISimpleCommodityScreen(Screen);
		if (CommodityScreen == none || CommodityScreen.arrItems.Length == 0) return;

		bItemAvailable = false;
		for (j = 0; j < CommodityScreen.arrItems.Length; j++) {
			ItemTitle = CommodityScreen.arrItems[j].Title;
			bTitleLocked = false;

			for (k = 0; k < LockedTitles.Length; k++) {
				if (InStr(ItemTitle, LockedTitles[k]) != INDEX_NONE) {
					bTitleLocked = true;
					break;
				}
			}

			if (!bTitleLocked) {
				bItemAvailable = true;
				break;
			}
		}

		if (!bItemAvailable) {
			`LOG("ClassHighlander TC MEC : No class available -> close the screen with a message.");
			
			DialogData.eType     = eDialog_Normal;
			DialogData.strTitle  = strNoMECClassAvailableTitle;
			DialogData.strText   = strNoMECClassAvailableText;
			DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOk;

			Screen.CloseScreen();
			`HQPRES.UIRaiseDialog(DialogData);
		}
		return;
	}
}

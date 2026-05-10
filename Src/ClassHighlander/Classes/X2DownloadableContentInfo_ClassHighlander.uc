class X2DownloadableContentInfo_ClassHighlander extends X2DownloadableContentInfo;

static event InstallNewCampaign(XComGameState StartState)
{
    RegisterEvents();
}

static event OnLoadedSavedGame()
{
    RegisterEvents();
}

static event OnLoadedSavedGameToStrategy()
{
    RegisterEvents();
	AddNewStaffSlotsPsiChamber();
    DisplayAlertFallbackMissing();
}

static event OnPostMission()
{
    RegisterEvents();
    DisplayAlertFallbackMissing();
}

// Just after the game templates loading
static event OnPostTemplatesCreated()
{
    local X2StrategyElementTemplateManager  StratMgr;
    local X2FacilityTemplate                FacilityTemplate;

    // Check the fallback class is really available, otherwise pick a new one.
    ValidateAndSetFallbackClass();

    if (!class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro) {
        `LOG("ClassHighlander : bPsiLabIntro=false -> skip.");
        return;
    }

    StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

    // Link the introspection upgrade to psi chamber
    FacilityTemplate = X2FacilityTemplate(StratMgr.FindStrategyElementTemplate('PsiChamber'));
    if (FacilityTemplate != none) {
        `LOG("ClassHighlander : PsiChamber Upgrades=" $ FacilityTemplate.Upgrades.Length);
    }

    if (FacilityTemplate != none && FacilityTemplate.Upgrades.Find('ClassHighlander_IntrospectionUnlock') == INDEX_NONE) {
        FacilityTemplate.Upgrades.AddItem('ClassHighlander_IntrospectionUnlock');
        `LOG("ClassHighlander : Upgrade ClassHighlander_IntrospectionUnlock added to PsiChamber.");
    }
}

static function ValidateAndSetFallbackClass()
{
    local X2SoldierClassTemplateManager Mgr;
    local X2SoldierClassTemplate        ClassTemplate;
    local array<X2SoldierClassTemplate> AllTemplates;
    local X2SoldierClassTemplate        FallbackCandidate;
    local name                          ConfiguredFallback;
    local int                           i;

    ConfiguredFallback = class'ClassHighlander_Utils'.default.FallbackClass;

    // Check if the configured fallback class exists
    Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
    ClassTemplate = Mgr.FindSoldierClassTemplate(ConfiguredFallback);

    if (ClassTemplate != none) {
        `LOG("ClassHighlander : Fallback class '" $ ConfiguredFallback $ "' validated.");
        return;
    }

    `LOG("ClassHighlander [WARN] : Fallback class '" $ ConfiguredFallback
        $ "' not found ! Search a new one...");

    AllTemplates = Mgr.GetAllSoldierClassTemplates();
    FallbackCandidate = none;

    for (i = 0; i < AllTemplates.Length; i++) {
        ClassTemplate = AllTemplates[i];
        if (ClassTemplate == none)                   continue;
        //if (ClassTemplate.NumInDeck <= 0)            continue;
        if (ClassTemplate.NumInForcedDeck <= 0)      continue;
        if (ClassTemplate.bMultiplayerOnly)           continue;

        // Exclude long war classes (id starting by a "LW_")
        if (Left(string(ClassTemplate.DataName), 3) == "LW_") continue;

        FallbackCandidate = ClassTemplate;
        break; // Pick the first one
    }

    if (FallbackCandidate == none) {
        `LOG("ClassHighlander [ERROR] : No fallback found !");
        return;
    }

    // Update the fallback class at runtime
    class'ClassHighlander_Utils'.default.FallbackClassReplaced = ConfiguredFallback;
    class'ClassHighlander_Utils'.default.FallbackClass = FallbackCandidate.DataName;
    class'ClassHighlander_Utils'.default.bFallbackClassInvalid = true;

    `LOG("ClassHighlander : Fallback class replaced by '"
        $ FallbackCandidate.DataName $ "'.");

    `Redscreen(
        "ClassHighlander WARNING: The configured fallback class '"
        $ string(ConfiguredFallback)
        $ "' was not found in the game. It has been replaced by '"
        $ string(FallbackCandidate.DataName)
        $ "' for this session. Please update FallbackClass in XComClassHighlander.ini."
    );
}

// Register all needed events
static function RegisterEvents()
{
    local Object ListenerObj;
    local XComGameState_HeadquartersXCom XComHQ;

    XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

    if (XComHQ == none) {
        `LOG("ClassHighlander [WARN] : XComHQ not found.");
        return;
    }

    ListenerObj = XComHQ;

	// Default soldier promotion without ChooseMyClass
	`XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'FirstPromotionOverrideClass');
	`XEVENTMGR.RegisterForEvent(
		ListenerObj, 
		'FirstPromotionOverrideClass',
		OnFirstPromotionOverrideClass, 
		ELD_Immediate, 
		50
	);

    // GTS training / ChooseMyClass
    `XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'ValidateGTSClassTraining');
	`XEVENTMGR.RegisterForEvent(
        ListenerObj,
        'ValidateGTSClassTraining',
        OnValidateGTSClassTraining,
        ELD_Immediate,
        50
    );

	// Training MEC Troopers
	`XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'FinalizeMecTrooperClasses');
	`XEVENTMGR.RegisterForEvent(
		ListenerObj, 
		'FinalizeMecTrooperClasses',
		OnFinalizeMecTrooperClasses, 
		ELD_Immediate, 
		50
	);

	// Black Market monthly refreshing
    `XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'BlackMarketGoodsReset');
    `XEVENTMGR.RegisterForEvent(
        ListenerObj,
        'BlackMarketGoodsReset',
        OnBlackMarketGoodsReset,
        ELD_Immediate, 
		50
    );

    // Missions reward generation
	`XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'RewardUnitGenerated');
	`XEVENTMGR.RegisterForEvent(
		ListenerObj, 
		'RewardUnitGenerated',
		OnRewardUnitGenerated, 
		ELD_Immediate, 
		50
	);

    // Soldier status display
	`XEVENTMGR.UnRegisterFromEvent(ListenerObj, 'OverridePersonnelStatus');
    `XEVENTMGR.RegisterForEvent(
        ListenerObj,
        'OverridePersonnelStatus',
        OnOverridePersonnelStatus,
        ELD_Immediate,
        50
    );
}

// Default promotion
static function EventListenerReturn OnFirstPromotionOverrideClass(
    Object EventData,
    Object EventSource,
    XComGameState NewGameState,
    Name EventID,
    Object CallbackData)
{
    local XComLWTuple               Tuple;
    local XComGameState_Unit        UnitState;
    local array<name>               LockedClasses;
    local array<name>               AvailableClasses;
    local X2SoldierClassTemplateManager Mgr;
    local X2DataTemplate            DataTemplate;
    local X2SoldierClassTemplate    ClassTemplate;
    local name                      AssignedClass;

    Tuple = XComLWTuple(EventData);
    if (Tuple == none || Tuple.Data.Length < 1) return ELR_NoInterrupt;
    if (Tuple.Data[0].kind != XComLWTVName)     return ELR_NoInterrupt;

    UnitState = XComGameState_Unit(EventSource);
    if (UnitState == none) return ELR_NoInterrupt;

	// Don't modify the class if we use respecSoldier (soldier is not a rookie)
	if (UnitState.GetRank() > 0) {
		`LOG("ClassHighlander Promo : Ignored (probably respecSoldier)");
		return ELR_NoInterrupt;
	}

    AssignedClass = Tuple.Data[0].n;

    LockedClasses = class'ClassHighlander_Utils'.static.GetAllLockedClasses(eClassCheck_Promotion);

    // If the chosen class is available, do nothing
    if (AssignedClass == '' || LockedClasses.Find(AssignedClass) == INDEX_NONE)
        return ELR_NoInterrupt;

    `LOG("ClassHighlander Promo : Locked class -> " $ AssignedClass);

    // Retrieve available classes for promotion
    Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
    foreach Mgr.IterateTemplates(DataTemplate, none) {
        ClassTemplate = X2SoldierClassTemplate(DataTemplate);
        if (ClassTemplate == none)                                                          continue;
        if (ClassTemplate.bMultiplayerOnly)                                                 continue;
        if (ClassTemplate.DataName == class'ClassHighlander_Utils'.default.FallbackClass)   continue;
        if (ClassTemplate.NumInDeck <= 0)                                                   continue;
        if (LockedClasses.Find(ClassTemplate.DataName) != INDEX_NONE)                       continue;

        AvailableClasses.AddItem(ClassTemplate.DataName);
    }

    if (AvailableClasses.Length > 0) {
        Tuple.Data[0].n = AvailableClasses[Rand(AvailableClasses.Length)];
        `LOG("ClassHighlander Promo : Replaced by -> " $ Tuple.Data[0].n);
    }
    else
    {
        // No more available class ? fallback class (by default => PR_Mercenary)
        Tuple.Data[0].n = class'ClassHighlander_Utils'.default.FallbackClass;
        `LOG("ClassHighlander Promo : No available class -> Fallback class (PR_Mercenary ?).");
    }

    return ELR_NoInterrupt;
}

// Handler : Promotion / GTS
static function EventListenerReturn OnValidateGTSClassTraining(
    Object EventData,
    Object EventSource,
    XComGameState GameState,
    Name EventID,
    Object CallbackData)
{
    local XComLWTuple            Tuple;
    local X2SoldierClassTemplate ClassTemplate;
	local EClassCheckContext	 checkType;

	Tuple = XComLWTuple(EventData);
    
    if (Tuple == none || Tuple.Data.Length < 2) return ELR_NoInterrupt;
    if (!Tuple.Data[0].b)                       return ELR_NoInterrupt;

    ClassTemplate = X2SoldierClassTemplate(Tuple.Data[1].o);
    if (ClassTemplate == none) return ELR_NoInterrupt;

	if (EventSource.Class.Name == 'UIChooseClass') {
		checkType = eClassCheck_GTS;
	} else {
		checkType = eClassCheck_Promotion;
	}

    // If this is the fallback class : allowed only if there is no available class
    if (ClassTemplate.DataName == class'ClassHighlander_Utils'.default.FallbackClass) {
        if (!class'ClassHighlander_Utils'.static.HasAvailableClasses(checkType)) {
            `LOG("ClassHighlander : Empty pool -> allow the fallback class.");
            // Keep Data[0].b = true ? The FallbackClass is put inside the pool
        } else {
            // Some classes are still available ? Exclude the fallback class
            Tuple.Data[0].b = false;

			`LOG("ClassHighlander : Class allowed -> " $ ClassTemplate.DataName);

        }
        return ELR_NoInterrupt;
    }

    // Other classes : Exclude if locked
    if (class'ClassHighlander_Utils'.static.IsClassLocked(ClassTemplate.DataName, checkType))
    {
        //`LOG("ClassHighlander : Exclude from pool promo/GTS -> " $ ClassTemplate.DataName);
        Tuple.Data[0].b = false;
    } else {
		//`LOG("ClassHighlander : Add pool promo/GTS -> " $ ClassTemplate.DataName);
	}

    return ELR_NoInterrupt;
}

static function EventListenerReturn OnFinalizeMecTrooperClasses(
    Object EventData,
    Object EventSource,
    XComGameState GameState,
    Name EventID,
    Object CallbackData)
{
    local XComLWTuple                   Tuple;
    local array<name>                   LockedClasses;
    local array<name>                   FilteredClasses;
    local array<name>                   RemovedClasses;
    local X2SoldierClassTemplateManager Mgr;
    local X2SoldierClassTemplate        ClassTemplate;
    local name                          ClassName;
    local int                           RemovedCount;

    Tuple = XComLWTuple(EventData);
    if (Tuple == none || Tuple.Data.Length < 1)     return ELR_NoInterrupt;
    if (Tuple.Data[0].kind != XComLWTVArrayNames)   return ELR_NoInterrupt;

	// Reset the check locked titles
    class'ClassHighlander_Utils'.default.PendingLockedMECTitles.Length = 0;

	// Don't set eClassCheck_GTS otherwise MEC classes will be excluded and it won't works properly
    LockedClasses = class'ClassHighlander_Utils'.static.GetAllLockedClasses(eClassCheck_promotion);
	if (LockedClasses.Length == 0) return ELR_NoInterrupt;

    // Filter the MEC classes display name
    foreach Tuple.Data[0].an(ClassName) {
        if (LockedClasses.Find(ClassName) == INDEX_NONE) {
            FilteredClasses.AddItem(ClassName);
        } else {
			RemovedClasses.AddItem(ClassName);
            RemovedCount++;
            `LOG("ClassHighlander MEC : Exclude -> " $ ClassName);
        }
    }

    if (RemovedCount > 0) {
        Tuple.Data[0].an = FilteredClasses;

        `LOG("ClassHighlander MEC : " $ RemovedCount $ " MEC class(es) excluded.");

		// Store excluded classes displayName for OnInit comparison
        Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
        foreach RemovedClasses(ClassName) {
            ClassTemplate = Mgr.FindSoldierClassTemplate(ClassName);
            if (ClassTemplate != none && ClassTemplate.DisplayName != "") {
                class'ClassHighlander_Utils'.default.PendingLockedMECTitles.AddItem(ClassTemplate.DisplayName);
                `LOG("ClassHighlander MEC : Title locked memorized -> " $ ClassTemplate.DisplayName);
            }
        }
    }

    return ELR_NoInterrupt;
}

static function EventListenerReturn OnBlackMarketGoodsReset(
    Object EventData,
    Object EventSource,
    XComGameState NewGameState,
    Name EventID,
    Object CallbackData)
{
    local XComGameState_BlackMarket BMState;

    BMState = XComGameState_BlackMarket(EventData);
    if (BMState == none) return ELR_NoInterrupt;

    BMState = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BMState.ObjectID));

    FilterAndReplaceBlackMarketItems(BMState, NewGameState);

    return ELR_NoInterrupt;
}

// Replace unavailable classes if needed
static function FilterAndReplaceBlackMarketItems(
    XComGameState_BlackMarket   BMState,
    XComGameState               NewGameState)
{
    local XComGameState_Reward      RewardState;
    local array<name>               LockedClasses;
    local array<int>                SlotsToReplace;
    local array<StrategyCost>       RemovedCosts;  // Keep the old costs
    local name                      ClassName;
    local int                       i;

    LockedClasses = class'ClassHighlander_Utils'.static.GetAllLockedClasses(eClassCheck_BlackMarket);
    if (LockedClasses.Length == 0) return;

    for (i = 0; i < BMState.ForSaleItems.Length; i++) {
        RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(BMState.ForSaleItems[i].RewardRef.ObjectID));
        if (RewardState == none) continue;

        ClassName = class'ClassHighlander_Utils'.static.GetClassFromReward(RewardState);
        if (ClassName == '') continue;

        if (LockedClasses.Find(ClassName) != INDEX_NONE) {
            `LOG("ClassHighlander BM : Slot to replace -> " $ ClassName);
            RemovedCosts[i] = BMState.ForSaleItems[i].Cost;
            SlotsToReplace.AddItem(i);
        }
    }

    if (SlotsToReplace.Length > 0) {
        ReplaceBlackMarketSlots(BMState, NewGameState, SlotsToReplace, LockedClasses, RemovedCosts);
    }
}

static function ReplaceBlackMarketSlots(
    XComGameState_BlackMarket   BMState,
    XComGameState               NewGameState,
    array<int>                  SlotsToReplace,
    array<name>                 LockedClasses,
    array<StrategyCost>         RemovedCosts)
{
    local X2StrategyElementTemplateManager  StratMgr;
    local X2RewardTemplate                  SoldierRewardTemplate;
    local XComGameState_Reward              NewRewardState;
    local Commodity                         NewItem, EmptyItem;
    local array<name>                       AlreadyInBM;
    local int                               i, Attempts;
    local name                              NewClassName;

    StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
    SoldierRewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Soldier'));

    if (SoldierRewardTemplate == none)
        return;

    // Collect existing (After filter)
    for (i = 0; i < BMState.ForSaleItems.Length; i++) {
        NewClassName = class'ClassHighlander_Utils'.static.GetClassFromReward( XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(BMState.ForSaleItems[i].RewardRef.ObjectID)));

        if (NewClassName != '' && AlreadyInBM.Find(NewClassName) == INDEX_NONE)
            AlreadyInBM.AddItem(NewClassName);
    }

    // Replace SLOT BY SLOT
    for (i = 0; i < SlotsToReplace.Length; i++) {
        Attempts = 0;

        while (Attempts < 100) {
            Attempts++;

            NewRewardState = SoldierRewardTemplate.CreateInstanceFromTemplate(NewGameState);
            NewRewardState.GenerateReward(NewGameState, , BMState.Region);

            NewClassName = class'ClassHighlander_Utils'.static.GetClassFromReward(NewRewardState);

            if (NewClassName == '')                             continue;
            if (LockedClasses.Find(NewClassName) != INDEX_NONE) continue;
            if (AlreadyInBM.Find(NewClassName) != INDEX_NONE)   continue;

            NewItem = EmptyItem;
            NewItem.RewardRef       = NewRewardState.GetReference();
            NewItem.Title           = NewRewardState.GetRewardString();
            NewItem.Desc            = NewRewardState.GetBlackMarketString();
            NewItem.Image           = NewRewardState.GetRewardImage();
            NewItem.Cost            = BMState.ForSaleItems[SlotsToReplace[i]].Cost; //Original cost
            NewItem.CostScalars     = BMState.GoodsCostScalars;
            NewItem.DiscountPercent = BMState.GoodsCostPercentDiscount;

            BMState.ForSaleItems[SlotsToReplace[i]] = NewItem;
            AlreadyInBM.AddItem(NewClassName);

            `LOG("ClassHighlander BM : Replace slot " $ SlotsToReplace[i] $ " -> " $ NewClassName);

            break;
        }
    }
}

static function EventListenerReturn OnRewardUnitGenerated(
    Object EventData,
    Object EventSource,
    XComGameState GameState,
    Name EventID,
    Object CallbackData)
{

    local XComGameState_Unit            UnitState;
    local array<name>                   LockedClasses;
    local array<name>                   AvailableClasses;
    local X2SoldierClassTemplateManager ClassMgr;
    local X2DataTemplate                DataTemplate;
    local X2SoldierClassTemplate        ClassTemplate;
    local name                          CurrentClass;
    local name                          NewClassName;

    UnitState = XComGameState_Unit(EventData);
    if (UnitState == none)      return ELR_NoInterrupt;
    if (!UnitState.IsSoldier()) return ELR_NoInterrupt;

    CurrentClass = UnitState.GetSoldierClassTemplateName();
    if (CurrentClass == '' || CurrentClass == 'None' || CurrentClass == 'Rookie')
        return ELR_NoInterrupt;

    LockedClasses = class'ClassHighlander_Utils'.static.GetAllLockedClasses(eClassCheck_MissionReward);
    if (LockedClasses.Find(CurrentClass) == INDEX_NONE)
        return ELR_NoInterrupt;

    `LOG("ClassHighlander Reward : Unavailable class -> " $ CurrentClass);

    // Check the available classes
    ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
    foreach ClassMgr.IterateTemplates(DataTemplate, none) {
        ClassTemplate = X2SoldierClassTemplate(DataTemplate);
        if (ClassTemplate == none)                                     continue;
        if (ClassTemplate.NumInDeck <= 0)                              continue;
        if (ClassTemplate.bMultiplayerOnly)                            continue;
        if (LockedClasses.Find(ClassTemplate.DataName) != INDEX_NONE)  continue;
        AvailableClasses.AddItem(ClassTemplate.DataName);
    }

    `LOG("ClassHighlander Reward : " $ AvailableClasses.Length $ " available classes.");

	//If 4 or more classes still available = change class otherwise set it to fallback class
    if (AvailableClasses.Length >= 4)
    {
        NewClassName = AvailableClasses[Rand(AvailableClasses.Length)];
        `LOG("ClassHighlander Reward : Replaced by -> " $ NewClassName);
    }
    else
    {
        NewClassName = class'ClassHighlander_Utils'.default.FallbackClass;
        `LOG("ClassHighlander Reward : Less than 3 classes available -> Fallback class (PR_Mercenary ?).");
    }

    UnitState.SetSoldierClassTemplate(NewClassName);
	
    return ELR_NoInterrupt;
}

static function EventListenerReturn OnOverridePersonnelStatus(
    Object EventData,
    Object EventSource,
    XComGameState GameState,
    Name EventID,
    Object CallbackData)
{
    local XComGameState_Unit                                Unit;
    local XComGameState_HeadquartersProject_Introspection   IntrospectionProject;
    local XComGameState_HeadquartersXCom                    XComHQ;
    local XComLWTuple                                       Tuple;
    local X2StaffSlotTemplate                               IntrospectionSlotTemplate;
    local X2StrategyElementTemplateManager                  StratMgr;
    local StateObjectReference                              ProjectRef;
    local int                                               iDays;

    Tuple = XComLWTuple(EventData);
    if (Tuple == none) return ELR_NoInterrupt;

    Unit = XComGameState_Unit(EventSource);
    if (Unit == none) return ELR_NoInterrupt;

    XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    if (XComHQ == none) return ELR_NoInterrupt;

    // Search if the soldier is training in active HQ project
    foreach XComHQ.Projects(ProjectRef) {
        IntrospectionProject = XComGameState_HeadquartersProject_Introspection(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));
        if (IntrospectionProject == none) continue;

        if (IntrospectionProject.ProjectFocus == Unit.GetReference()) {
            StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
            IntrospectionSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('IntrospectionStaffSlot'));

            iDays = FCeil(float(IntrospectionProject.GetCurrentNumHoursRemaining()) / 24.0);

            Tuple.Data[0].s = class'UIUtilities_Text'.static.GetColoredText(
                IntrospectionSlotTemplate != none ? IntrospectionSlotTemplate.BonusText : "Reflecting",
                eUIState_Warning
            );
            Tuple.Data[1].i = eUIState_Warning;
            Tuple.Data[2].s = class'UIUtilities_Text'.static.GetDaysString(iDays);
            Tuple.Data[3].s = string(iDays);

            return ELR_NoInterrupt;
        }
    }

    return ELR_NoInterrupt;
}

static function AddNewStaffSlotsPsiChamber()
{
    local XComGameState_HeadquartersXCom    XComHQ;
    local XComGameState_FacilityXCom        FacilityState;
    local X2FacilityTemplate                FacilityTemplate;
    local X2StaffSlotTemplate               StaffSlotTemplate;
    local X2StrategyElementTemplateManager  StratMgr;
    local XComGameState_StaffSlot           StaffSlotState;
    local XComGameState_StaffSlot           ExistingSlot;
    local StaffSlotDefinition               IntrospectionSlotDef;
    local XComGameState                     NewGameState;
    local bool                              bIntrospectionInDefs;
    local bool                              bIntrospectionInGameState;
    local bool                              DidChange;
    local int                               i;
    local X2FacilityUpgradeTemplate         UpgradeTemplate;
    local int                               UpgradeIdx;

    local int LockedSlotsUpToPos3;
    local int UpgradeLockedCount;

    if (!class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro)
        return;

    XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

    FacilityState = XComHQ.GetFacilityByName('PsiChamber');
    if (FacilityState == none) {
        `LOG("ClassHighlander PsiChamber : Facility non trouvée.");
        return;
    }

    StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
    FacilityTemplate = FacilityState.GetMyTemplate();

    // Check if IntrospectionStaffSlot is in StaffSlotDefs (erased by some other mod?)
    bIntrospectionInDefs = false;
    for (i = 0; i < FacilityTemplate.StaffSlotDefs.Length; i++) {
        if (FacilityTemplate.StaffSlotDefs[i].StaffSlotTemplateName == 'IntrospectionStaffSlot') {
            bIntrospectionInDefs = true;
            break;
        }
    }

    // I) If the slot is not there, add it (and remove some slot if forced in 4th position)
    if (!bIntrospectionInDefs)
    {
        //If we want to force our slot in 4th position, remove any slot at or after the 4th.
        if (class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionForced4slot) {
            // Delete slots and their upgrades > 3rd pos
            if (FacilityTemplate.StaffSlotDefs.Length > 3) {
                if (FacilityTemplate.StaffSlotDefs[3].bStartsLocked) {
                    // Count the slots locked until the 3rd position
                    LockedSlotsUpToPos3 = 0;
                    for (i = 0; i <= 3 && i < FacilityTemplate.StaffSlotDefs.Length; i++) {
                        if (FacilityTemplate.StaffSlotDefs[i].bStartsLocked)
                            LockedSlotsUpToPos3++;
                    }

                    if (LockedSlotsUpToPos3 > 0) {
                        // Find the LockedSlotsUpToPos3-rd upgrade
                        UpgradeLockedCount = 0;
                        for (UpgradeIdx = 0; UpgradeIdx < FacilityTemplate.Upgrades.Length; UpgradeIdx++) {
                            UpgradeTemplate = X2FacilityUpgradeTemplate(
                                StratMgr.FindStrategyElementTemplate(FacilityTemplate.Upgrades[UpgradeIdx])
                            );
                            if (UpgradeTemplate == none) continue;

                            UpgradeLockedCount++;
                            if (UpgradeLockedCount == LockedSlotsUpToPos3)
                            {
                                `LOG("ClassHighlander : Remove upgrade from pos 3+ -> " $ FacilityTemplate.Upgrades[UpgradeIdx]);
                                FacilityTemplate.Upgrades.Remove(UpgradeIdx, 1);
                                break;
                            }
                        }
                    }
                }

                FacilityTemplate.StaffSlotDefs.Length = 3;
            }

            `LOG("ClassHighlander : IntrospectionForced4slot -> StaffSlotDefs truncated at 3.");
        }

        // Add our slot to the end, no matter how many slot already exists
        IntrospectionSlotDef.StaffSlotTemplateName = 'IntrospectionStaffSlot';
        IntrospectionSlotDef.bStartsLocked         = true;
        FacilityTemplate.StaffSlotDefs.AddItem(IntrospectionSlotDef);
        `LOG("ClassHighlander : IntrospectionStaffSlot added to StaffSlotDefs (index "
            $ (FacilityTemplate.StaffSlotDefs.Length - 1) $ ").");
    }

    // II) : check if the game state already have our slot
    bIntrospectionInGameState = false;
    for (i = 0; i < FacilityState.StaffSlots.Length; i++) {
        ExistingSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(FacilityState.StaffSlots[i].ObjectID));
        if (ExistingSlot != none && ExistingSlot.GetMyTemplateName() == 'IntrospectionStaffSlot') {
            bIntrospectionInGameState = true;
            break;
        }
    }

    if (bIntrospectionInGameState) {
        `LOG("ClassHighlander PsiChamber : Introspection Slot already present in game state.");
        return;
    }

    // III) : create the game state slot
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ClassHighlander -- PsiChamber Introspection Slot");

    FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));

    StaffSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('IntrospectionStaffSlot'));
    if (StaffSlotTemplate == none) {
        `LOG("ClassHighlander [WARN] : IntrospectionStaffSlot template not found.");
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
        return;
    }

    StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
    StaffSlotState.Facility = FacilityState.GetReference();
    StaffSlotState.LockSlot();
    FacilityState.StaffSlots.AddItem(StaffSlotState.GetReference());

    DidChange = true;
    `LOG("ClassHighlander PsiChamber : Slot Introspection created and added (locked).");

    if (DidChange) {
        `GAMERULES.SubmitGameState(NewGameState);
        `LOG("ClassHighlander PsiChamber : Game state submitted.");
    } else {
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
}

static function DisplayAlertFallbackMissing()
{
    local TDialogueBoxData  DialogData;
    local XGParamTag        LocTag;

    // We have checked at the start of the game in OnPostTemplatesCreated if the fallback class was valid.
    // If it was not, display an alert to the user
    if (class'ClassHighlander_Utils'.default.bFallbackClassInvalid) {
        LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
        LocTag.StrValue0 = string(class'ClassHighlander_Utils'.default.FallbackClassReplaced);
        LocTag.StrValue1 = string(class'ClassHighlander_Utils'.default.FallbackClass);

        DialogData.eType     = eDialog_Alert;
        DialogData.strTitle  = class'ClassHighlander_Utils'.default.strFallbackWarningTitle;
        DialogData.strText   = `XEXPAND.ExpandString(class'ClassHighlander_Utils'.default.strFallbackWarningText);
        DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOk;

        `HQPRES.UIRaiseDialog(DialogData);

        // Reset le flag pour ne plus afficher le message après la 1ère fois
        class'ClassHighlander_Utils'.default.bFallbackClassInvalid = false;
    }
}

//Display the introspection project timeline in geoscape
static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
    local XComGameStateHistory                            History;
    local XComGameState_HeadquartersXCom                  XComHQ;
    local XComGameState_HeadquartersProject_Introspection Project;
    local XComGameState_Unit                              UnitState;
    local HQEvent                                         kEvent;
    local StateObjectReference                            ProjectRef;
    local bool                                            bAdded;

    History = `XCOMHISTORY;
    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    if (XComHQ == none) return false;

    foreach XComHQ.Projects(ProjectRef)
    {
        Project = XComGameState_HeadquartersProject_Introspection(History.GetGameStateForObjectID(ProjectRef.ObjectID));
        if (Project == none) continue;

        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Project.ProjectFocus.ObjectID));
        if (UnitState == none) continue;

        kEvent.Data = class'XComGameState_HeadquartersProject_Introspection'.default.strIntrospectionEventLabel @ " - " @ UnitState.GetName(eNameType_RankFull);
        kEvent.Hours     = Project.GetCurrentNumHoursRemaining();
        kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;

        if (kEvent.Hours < 0)
            kEvent.Data = class'XComGameState_HeadquartersProject_Introspection'.default.strIntrospectionPausedLabel @ ":" @ kEvent.Data;

        arrEvents.AddItem(kEvent);
        bAdded = true;
    }

    return bAdded;
}
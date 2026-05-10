class ClassHighlander_Utils extends Object config(ClassHighlander);

// Memorize the MEC classes name displayed which are forbidden (no access to class id in UI)
var config array<string> PendingLockedMECTitles;
// The fallback class used when no class is available anymore
var config name FallbackClass;
// True if config fallback class has not been found in game.
var config bool bFallbackClassInvalid;
// Fallback class previously set in config if it is not found
var config name FallbackClassReplaced;

var localized string strFallbackWarningTitle;
var localized string strFallbackWarningText;
var localized string strFallbackWarningAccept;

enum EClassCheckContext
{
    eClassCheck_Promotion,
    eClassCheck_GTS,
    eClassCheck_BlackMarket,
    eClassCheck_MissionReward
};

// Classes already in roster
static function array<name> GetOccupiedClasses()
{
    local XComGameStateHistory              History;
    local XComGameState_HeadquartersXCom    XComHQ;
    local XComGameState_Unit                UnitState;
    local array<name>                       OccupiedClasses;
    local name                              SoldierClassName;
    local int                               i;

    History = `XCOMHISTORY;

    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

    if (XComHQ == none) {
        `LOG("ClassHighlander [WARN] : XComGameState_HeadquartersXCom not found.");
        return OccupiedClasses;
    }

    for (i = 0; i < XComHQ.Crew.Length; i++) {
        UnitState = XComGameState_Unit(
            History.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID)
        );

        if (UnitState == none)          continue;
        if (!UnitState.IsSoldier())     continue;
        if (UnitState.IsDead())         continue;

        SoldierClassName = UnitState.GetSoldierClassTemplateName();

        if (SoldierClassName == ''
         || SoldierClassName == 'None'
         || SoldierClassName == 'Rookie')
            continue;

        if (OccupiedClasses.Find(SoldierClassName) == INDEX_NONE) {
			OccupiedClasses.AddItem(SoldierClassName);
		}            
    }

    return OccupiedClasses;
}

// Classes already training in GTS
static function array<name> GetGTSQueuedClasses()
{
    local XComGameStateHistory								History;
    local XComGameState_HeadquartersXCom					XComHQ;
    local XComGameState_HeadquartersProjectTrainRookie		TrainProject;
    local XComGameState_HeadquartersProjectAugmentSoldier   AugmentProject;
    local array<name>                                       QueuedClasses;
    local name                                              ClassName;
    local int												i;

    History = `XCOMHISTORY;

    XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    if (XComHQ == none) return QueuedClasses;

    for (i = 0; i < XComHQ.Projects.Length; i++) {
		// Check if the mod TedMECTroopersForLWOTC is active
		if (class'XComGameState_HeadquartersProjectAugmentSoldier' != none) {
			// Add the MEC classes currently training
			AugmentProject = XComGameState_HeadquartersProjectAugmentSoldier(History.GetGameStateForObjectID(XComHQ.Projects[i].ObjectID));

			if (AugmentProject != none) {
				ClassName = AugmentProject.ClassName;
				if (ClassName != '' && ClassName != 'None' && QueuedClasses.Find(ClassName) == INDEX_NONE) {
					QueuedClasses.AddItem(ClassName);
				}
				continue; // No need to check in normal GTS
			}
		}

        //The normal GTS training
        TrainProject = XComGameState_HeadquartersProjectTrainRookie(History.GetGameStateForObjectID(XComHQ.Projects[i].ObjectID));

        if (TrainProject == none)                   continue;
        if (TrainProject.NewClassName == '')        continue;
        if (TrainProject.NewClassName == 'None')    continue;

        if (QueuedClasses.Find(TrainProject.NewClassName) == INDEX_NONE) {
            QueuedClasses.AddItem(TrainProject.NewClassName);
        }
    }

    return QueuedClasses;
}

 // Classes already set as mission reward
static function array<name> GetMissionRewardClasses()
{
    local XComGameStateHistory          History;
    local XComGameState_MissionSite     MissionSite;
    local XComGameState_Reward          RewardState;
    local XComGameState_Unit            RewardUnit;
    local array<name>                   RewardClasses;
    local name                          ClassName;
    local int                           i;

    History = `XCOMHISTORY;

    // Check all active missions
    foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionSite) {
        if (MissionSite.bRemoved) continue; // Mission plus jouable
        //if (!MissionSite.Available)     continue;

        for (i = 0; i < MissionSite.Rewards.Length; i++) {
            RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionSite.Rewards[i].ObjectID));
            if (RewardState == none) continue;

            // Les récompenses soldat ont un RewardUnit associé
            RewardUnit = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
            if (RewardUnit == none)         continue;
            if (!RewardUnit.IsSoldier())    continue;

            ClassName = RewardUnit.GetSoldierClassTemplateName();
            if (ClassName == '' || ClassName == 'None' || ClassName == 'Rookie') continue;

            if (RewardClasses.Find(ClassName) == INDEX_NONE) {
                RewardClasses.AddItem(ClassName);
                `LOG("ClassHighlander : Class locked as mission reward -> " $ ClassName);
            }
        }
    }

    return RewardClasses;
}

 // Classes already sold by black market
static function array<name> GetBlackMarketClasses()
{
	local XComGameStateHistory      History;
    local XComGameState_BlackMarket BM;
    local XComGameState_Reward      RewardState;
    local XComGameState_Unit        UnitState;
    local array<name>               Result;
    local int                       i;
    local name                      ClassName;

    History = `XCOMHISTORY;

    BM = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
    if (BM == none) return Result;

    for (i = 0; i < BM.ForSaleItems.Length; i++) {
        RewardState = XComGameState_Reward(History.GetGameStateForObjectID(BM.ForSaleItems[i].RewardRef.ObjectID));
        if (RewardState == none) continue;

        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
        if (UnitState == none)      continue;
        if (!UnitState.IsSoldier()) continue;

        ClassName = UnitState.GetSoldierClassTemplateName();
        if (ClassName == '' || ClassName == 'None' || ClassName == 'Rookie') continue;

        if (Result.Find(ClassName) == INDEX_NONE) {
            Result.AddItem(ClassName);
        }
    }

    return Result;
}

// List of all locked classes from all sources
static function array<name> GetAllLockedClasses(EClassCheckContext Context)
{
    local array<name> Locked;
    local array<name> GTSTrained, MissionRewards, BlackMarket;
    local name        ClassName;

    Locked = GetOccupiedClasses();
    MissionRewards = GetMissionRewardClasses();
	BlackMarket = GetBlackMarketClasses();
	GTSTrained = GetGTSQueuedClasses();

	//Special fallback class, always excluded, except if we see later there is no class available, in this case use it.
	Locked.AddItem(class'ClassHighlander_Utils'.default.FallbackClass);

	// GTS queue: lock all classes trained in GTS
	foreach GTSTrained(ClassName)  {
		if (Locked.Find(ClassName) == INDEX_NONE)
            Locked.AddItem(ClassName);
	}

    // Missions: lock all class in mission reward
    foreach MissionRewards(ClassName) {
        if (Locked.Find(ClassName) == INDEX_NONE)
            Locked.AddItem(ClassName);
    }

    // Black Market: lock all classes sold in black market
	foreach BlackMarket(ClassName) {
        if (Locked.Find(ClassName) == INDEX_NONE)
            Locked.AddItem(ClassName);
    }

	// In GTS context: exclude all MEC classes: keep only the human non-MEC, non-Spark, non-Psi
    if (Context == eClassCheck_GTS)
        Locked = FilterForGTSContext(Locked);

    return Locked;
}

//Remove the GTS forbidden classes from the locked classes (we need to match only the GTS allowed classes for this lock list)
static function array<name> FilterForGTSContext(array<name> Classes)
{
    local X2SoldierClassTemplateManager Mgr;
    local X2SoldierClassTemplate        ClassTemplate;
    local array<name>                   Filtered;
    local name                          ClassName;

    Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

    foreach Classes(ClassName) {
        ClassTemplate = Mgr.FindSoldierClassTemplate(ClassName);
        if (ClassTemplate == none) continue;

        // FallbackClass is always locked by default
        if (ClassName == class'ClassHighlander_Utils'.default.FallbackClass) {
            Filtered.AddItem(ClassName);
            continue;
        }

        // Only classes with NumInForcedDeck > 0 (no semi-heroic) inside the GTS pool.
        if (ClassTemplate.NumInForcedDeck > 0) {
            Filtered.AddItem(ClassName);
        }
    }

    return Filtered;
}

// Check if there is at least 1 class available for the provided context
static function bool HasAvailableClasses(EClassCheckContext Context)
{
    local array<name>                   LockedClasses;
    local X2SoldierClassTemplateManager Mgr;
    local X2DataTemplate                DataTemplate;
    local X2SoldierClassTemplate        ClassTemplate;

    LockedClasses = GetAllLockedClasses(Context);
    Mgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

    foreach Mgr.IterateTemplates(DataTemplate, none) {
        ClassTemplate = X2SoldierClassTemplate(DataTemplate);
        if (ClassTemplate == none)                                                          continue;
        if (ClassTemplate.bMultiplayerOnly)                                                 continue;
        if (ClassTemplate.DataName == class'ClassHighlander_Utils'.default.FallbackClass)   continue;
        if (LockedClasses.Find(ClassTemplate.DataName) != INDEX_NONE)                       continue;

        // Don't check not normal soldier classes
        if (ClassTemplate.NumInDeck <= 0)       continue;
        // In GTS, don't check the not GTS allowed classes
		if (Context == eClassCheck_GTS && ClassTemplate.NumInForcedDeck <= 0) continue;

        return true;
    }

    `LOG("ClassHighlander : No class available (Context=" $ Context $ ").");
    return false;
}

// Return the class name of a soldier reward, or '' if not a soldier
static function name GetClassFromReward(XComGameState_Reward RewardState)
{
    local XComGameState_Unit RewardUnit;
    local name               ClassName;

    if (RewardState == none) return '';

    RewardUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

    if (RewardUnit == none)      return '';
    if (!RewardUnit.IsSoldier()) return '';

    ClassName = RewardUnit.GetSoldierClassTemplateName();

    if (ClassName == 'None' || ClassName == 'Rookie') return '';

    return ClassName;
}

////// Helpers //////
static function bool IsClassLocked(name ClassName, EClassCheckContext Context)
{
    local array<name> Locked;
    Locked = GetAllLockedClasses(Context);
    return Locked.Find(ClassName) != INDEX_NONE;
}

static function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;
    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) {
        if (EventManager.GetDLCNames(Index) == ModName)
            return true;
    }
    return false;
}
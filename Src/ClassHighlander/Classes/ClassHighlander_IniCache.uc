//---------------------------------------------------------------------------------------
//  FILE:   ClassHighlander_IniCache.uc
//  PURPOSE: The values XComClassHighlander.ini gives, remembered by ClassHighlander_MCMSettings before the player's values are written into the class defaults.
//           The variables are "config" only because UnrealScript refuses to write the defaults of a non-config property; StaticSaveConfig() is NEVER called on
//           this class, so nothing here is ever written to a file (and it is kept apart from ClassHighlander_MCMSettings, which IS saved).
//---------------------------------------------------------------------------------------
class ClassHighlander_IniCache extends Object config(ClassHighlanderIniCache);

var config bool bCached;
var config bool MultiplePsiSoldiers, PsiLabIntro, Forced4slot;
var config int  Days, MeldCost, SuppliesCost, UpgradePower, UpgradeCost;
var config string FallbackClass;

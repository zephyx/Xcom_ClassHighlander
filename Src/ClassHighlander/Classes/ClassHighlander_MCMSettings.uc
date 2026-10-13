//---------------------------------------------------------------------------------------
//  FILE:   ClassHighlander_MCMSettings.uc
//  PURPOSE: What the player changed in the Mod Config Menu page (ClassHighlander_MCMScreen), and ONLY that.
//           config(ClassHighlanderMCM) is a file the mod does not ship (XComClassHighlanderMCM.ini, created in the player's config folder when he saves),
//           so XComClassHighlander.ini (shipped, overwritten by every Workshop update) stays the single source of the defaults: a value the player did not touch
//           follows the ini, a value he changed stays. A value saved equal to the ini is not stored (StoreValue).
//           StaticSaveConfig() is only ever called on THIS class: never on a class using config(ClassHighlander), which would freeze the old defaults
//           in the player's config folder.
//           Nothing here refers to Mod Config Menu: without it the list is simply empty and ApplyOverrides writes the ini values back (a no-op).
//---------------------------------------------------------------------------------------
class ClassHighlander_MCMSettings extends Object config(ClassHighlanderMCM);

const FALLBACK_PREFIX = "FB_";

struct MCMOverride
{
	var name OverrideKey;
	var int OverrideValue;      // a bool is stored as 0 / 1
};

var config array<MCMOverride> Overrides;

// The options of the MCM page, in display order. The names are those of the config variables.
static final function array<name> GetKeys()
{
	local array<name> Keys;

	Keys.AddItem('bMultiplePsiSoldiers');
	Keys.AddItem('bPsiLabIntro');
	Keys.AddItem('IntrospectionForced4slot');
	Keys.AddItem('IntrospectionDays');
	Keys.AddItem('IntrospectionMeldCost');
	Keys.AddItem('IntrospectionSuppliesCost');
	Keys.AddItem('IntrospectionUpgradePower');
	Keys.AddItem('IntrospectionUpgradeCost');

	return Keys;
}

// The value the game uses right now (the player's, once ApplyOverrides ran).
static final function int GetCurrent(name Key)
{
	switch (Key)
	{
		case 'bMultiplePsiSoldiers':        return class'ClassHighlander_Utils'.default.bMultiplePsiSoldiers ? 1 : 0;
		case 'bPsiLabIntro':                return class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro ? 1 : 0;
		case 'IntrospectionForced4slot':    return class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionForced4slot ? 1 : 0;
		case 'IntrospectionDays':           return class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionDays;
		case 'IntrospectionMeldCost':       return class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionMeldCost;
		case 'IntrospectionSuppliesCost':   return class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionSuppliesCost;
		case 'IntrospectionUpgradePower':   return class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradePower;
		case 'IntrospectionUpgradeCost':    return class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradeCost;
	}

	return 0;
}

static final function SetCurrent(name Key, int Value)
{
	switch (Key)
	{
		case 'bMultiplePsiSoldiers':        class'ClassHighlander_Utils'.default.bMultiplePsiSoldiers = (Value != 0); break;
		case 'bPsiLabIntro':                class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro = (Value != 0); break;
		case 'IntrospectionForced4slot':    class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionForced4slot = (Value != 0); break;
		case 'IntrospectionDays':           class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionDays = Value; break;
		case 'IntrospectionMeldCost':       class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionMeldCost = Value; break;
		case 'IntrospectionSuppliesCost':   class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionSuppliesCost = Value; break;
		case 'IntrospectionUpgradePower':   class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradePower = Value; break;
		case 'IntrospectionUpgradeCost':    class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradeCost = Value; break;
	}
}

// Remembers the ini values the first time, before anything is overwritten (in ClassHighlander_IniCache, which is never saved).
static final function CacheIni()
{
	if (class'ClassHighlander_IniCache'.default.bCached)
		return;

	class'ClassHighlander_IniCache'.default.MultiplePsiSoldiers = class'ClassHighlander_Utils'.default.bMultiplePsiSoldiers;
	class'ClassHighlander_IniCache'.default.PsiLabIntro         = class'XComGameState_HeadquartersProject_Introspection'.default.bPsiLabIntro;
	class'ClassHighlander_IniCache'.default.Forced4slot         = class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionForced4slot;
	class'ClassHighlander_IniCache'.default.Days                = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionDays;
	class'ClassHighlander_IniCache'.default.MeldCost            = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionMeldCost;
	class'ClassHighlander_IniCache'.default.SuppliesCost        = class'XComGameState_HeadquartersProject_Introspection'.default.IntrospectionSuppliesCost;
	class'ClassHighlander_IniCache'.default.UpgradePower        = class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradePower;
	class'ClassHighlander_IniCache'.default.UpgradeCost         = class'X2StrategyElement_IntrospectionSlots'.default.IntrospectionUpgradeCost;
	class'ClassHighlander_IniCache'.default.FallbackClass       = class'ClassHighlander_Utils'.default.FallbackClass;
	class'ClassHighlander_IniCache'.default.bCached = true;
}

// The value XComClassHighlander.ini gives, whatever the player chose.
static final function int GetIni(name Key)
{
	CacheIni();

	switch (Key)
	{
		case 'bMultiplePsiSoldiers':        return class'ClassHighlander_IniCache'.default.MultiplePsiSoldiers ? 1 : 0;
		case 'bPsiLabIntro':                return class'ClassHighlander_IniCache'.default.PsiLabIntro ? 1 : 0;
		case 'IntrospectionForced4slot':    return class'ClassHighlander_IniCache'.default.Forced4slot ? 1 : 0;
		case 'IntrospectionDays':           return class'ClassHighlander_IniCache'.default.Days;
		case 'IntrospectionMeldCost':       return class'ClassHighlander_IniCache'.default.MeldCost;
		case 'IntrospectionSuppliesCost':   return class'ClassHighlander_IniCache'.default.SuppliesCost;
		case 'IntrospectionUpgradePower':   return class'ClassHighlander_IniCache'.default.UpgradePower;
		case 'IntrospectionUpgradeCost':    return class'ClassHighlander_IniCache'.default.UpgradeCost;
	}

	if (IsFallbackKey(Key))
		return GetIniFallbackMode(GetFallbackClassName(Key));

	return 0;
}

//---------------------------------------------------------------------------------------
// Fallback classes. The player's choice for a class is stored under the key FB_<ClassName>, as a mode: 0 = unique (not in FallbackClass),
// 1 = soft fallback ({Class}), 2 = hard fallback (Class). BuildFallbackString rebuilds the FallbackClass string from the ini's one + these differences.
//---------------------------------------------------------------------------------------
static final function name GetFallbackKey(name ClassName)
{
	return name(FALLBACK_PREFIX $ ClassName);
}

static final function bool IsFallbackKey(name Key)
{
	return Left(string(Key), Len(FALLBACK_PREFIX)) == FALLBACK_PREFIX;
}

static final function name GetFallbackClassName(name Key)
{
	return name(Mid(string(Key), Len(FALLBACK_PREFIX)));
}

// Splits a FallbackClass string: the class names and their modes (1 = {soft}, 2 = hard).
static final function ParseFallback(string Raw, out array<name> Names, out array<int> Modes)
{
	local array<string> Parts;
	local string Entry;
	local int i;

	Names.Length = 0;
	Modes.Length = 0;

	Parts = SplitString(Raw, ",");
	for (i = 0; i < Parts.Length; ++i)
	{
		Entry = Parts[i];
		Entry -= " ";
		if (Entry == "")
			continue;

		if (Left(Entry, 1) == "{" && Right(Entry, 1) == "}")
		{
			Names.AddItem(name(Mid(Entry, 1, Len(Entry) - 2)));
			Modes.AddItem(1);
		}
		else
		{
			Names.AddItem(name(Entry));
			Modes.AddItem(2);
		}
	}
}

// The mode XComClassHighlander.ini gives a class (0 when it is not in FallbackClass).
static final function int GetIniFallbackMode(name ClassName)
{
	local array<name> Names;
	local array<int> Modes;
	local int Index;

	CacheIni();

	ParseFallback(class'ClassHighlander_IniCache'.default.FallbackClass, Names, Modes);
	Index = Names.Find(ClassName);

	return Index == INDEX_NONE ? 0 : Modes[Index];
}

static final function array<name> GetIniFallbackNames()
{
	local array<name> Names;
	local array<int> Modes;

	CacheIni();

	ParseFallback(class'ClassHighlander_IniCache'.default.FallbackClass, Names, Modes);

	return Names;
}

// The ini's FallbackClass with the player's differences applied (a class set to unique leaves the list, another one joins it or changes mode).
// Never empty: the mod needs at least one fallback class, so a list emptied by hand-edited overrides gives the ini's one back.
static final function string BuildFallbackString()
{
	local array<name> Names;
	local array<int> Modes;
	local string Key, Result;
	local name ClassName;
	local int i, Index, Mode;

	CacheIni();

	ParseFallback(class'ClassHighlander_IniCache'.default.FallbackClass, Names, Modes);

	for (i = 0; i < default.Overrides.Length; ++i)
	{
		if (!IsFallbackKey(default.Overrides[i].OverrideKey))
			continue;

		ClassName = GetFallbackClassName(default.Overrides[i].OverrideKey);
		Mode = default.Overrides[i].OverrideValue;
		Index = Names.Find(ClassName);

		if (Mode == 0)
		{
			if (Index != INDEX_NONE)
			{
				Names.Remove(Index, 1);
				Modes.Remove(Index, 1);
			}
		}
		else if (Index != INDEX_NONE)
		{
			Modes[Index] = Mode;
		}
		else
		{
			Names.AddItem(ClassName);
			Modes.AddItem(Mode);
		}
	}

	if (Names.Length == 0)
		return class'ClassHighlander_IniCache'.default.FallbackClass;

	for (i = 0; i < Names.Length; ++i)
	{
		Key = string(Names[i]);
		if (Modes[i] == 1)
			Key = "{" $ Key $ "}";

		if (i > 0)
			Result $= ",";
		Result $= Key;
	}

	return Result;
}

// Writes into the class defaults (in memory only) the player's value, or the ini's when he has none. Called from OnPreCreateTemplates, i.e. before any template
// is built (so the values baked into the templates are the player's), and again when the page is saved (the values read when used change at once).
static final function ApplyOverrides()
{
	local array<name> Keys;
	local int i, Value;

	CacheIni();

	Keys = GetKeys();
	for (i = 0; i < Keys.Length; ++i)
	{
		if (GetOverride(Keys[i], Value))
			SetCurrent(Keys[i], Value);
		else
			SetCurrent(Keys[i], GetIni(Keys[i]));
	}

	// The fallback classes: read at run time through ClassHighlander_Utils' parsed cache, which is invalidated.
	class'ClassHighlander_Utils'.default.FallbackClass = BuildFallbackString();
	class'ClassHighlander_Utils'.static.InvalidateFallbackCache();
}

// True and the player's value when he changed the setting OverrideKey.
static final function bool GetOverride(name OverrideKey, out int OverrideValue)
{
	local int Index;

	Index = default.Overrides.Find('OverrideKey', OverrideKey);
	if (Index == INDEX_NONE)
		return false;

	OverrideValue = default.Overrides[Index].OverrideValue;

	return true;
}

static final function SetOverride(name OverrideKey, int OverrideValue)
{
	local MCMOverride Entry;
	local int Index;

	Index = default.Overrides.Find('OverrideKey', OverrideKey);
	if (Index != INDEX_NONE)
	{
		default.Overrides[Index].OverrideValue = OverrideValue;
		return;
	}

	Entry.OverrideKey = OverrideKey;
	Entry.OverrideValue = OverrideValue;
	default.Overrides.AddItem(Entry);
}

static final function ClearOverride(name OverrideKey)
{
	local int Index;

	Index = default.Overrides.Find('OverrideKey', OverrideKey);
	if (Index != INDEX_NONE)
		default.Overrides.Remove(Index, 1);
}

// The player saved Value for OverrideKey: kept only if it differs from what the mod's ini gives, else the setting follows the ini again.
// Commit() writes the file once everything is stored.
static final function StoreValue(name OverrideKey, int Value)
{
	if (Value == GetIni(OverrideKey))
		ClearOverride(OverrideKey);
	else
		SetOverride(OverrideKey, Value);
}

static final function Commit()
{
	StaticSaveConfig();
}

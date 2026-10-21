# Class Highlander

## Main Goal

Play a campaign in a true **Highlander environment**.

**Highlander rule:** Each class can only be assigned to one soldier at a time. No two soldiers can share the same class.

Once a class has been assigned to a soldier, it becomes unavailable until that soldier dies or is dismissed.

### Tested Environment

This mod has been tested primarily with the following setups:

- [Ted Jam+](https://steamcommunity.com/sharedfiles/filedetails/?id=3310020642), including extra classes, Requiem mods, The Hive, and several smaller mods.
- [Captain Rock's Mercenary Class](https://steamcommunity.com/sharedfiles/filedetails/?id=2927887132).

The mod should also work in lighter environments without Long War of the Chosen (LWOTC), MECs, and similar additions.

Compatibility with class system overhauls such as RPGO and Amalgamation has **not been tested** and is not guaranteed.

### Important Update: MCM Support

The mod now supports the **Mod Configuration Menu (MCM)**, allowing you to configure its settings directly in-game.

**Use MCM instead of editing INI files.** This ensures your settings are preserved when the mod's INI files are updated.

You can use either:

- [My MCM fork](https://steamcommunity.com/sharedfiles/filedetails/?id=3819112313) — recommended for the fixed version.
- [Original MCM](https://steamcommunity.com/sharedfiles/filedetails/?id=667104300) — works, but some tooltips will be missing.

---

## What the Mod Does

### Class Availability Restrictions

The mod restricts class availability across the following systems:

- **Promotions:** Only available classes can be assigned.
- **GTS training:** Only available classes can be trained.
- **MEC training:** Only available MEC classes can be trained.
- **Black Market:** Only available classes are offered at the beginning of each month.
- **Mission rewards:** Only available classes can be offered as rewards.
- **Psi Soldiers:** Limited to one by default. This limit can be changed in the configuration.

All these restrictions are interconnected. A class reserved by one system cannot be assigned by another.

Examples:

- A soldier currently undergoing GTS training cannot be promoted or offered as a mission reward.
- A soldier whose class is offered on the Black Market cannot be trained in the GTS, promoted, or offered as a mission reward.
- When a soldier is dismissed, their class becomes available again for promotions, GTS training (except for semi-heroic classes), and mission rewards. It can also appear on the Black Market at the next monthly refresh.
- If a mission offers a class as a reward, that class remains reserved until the mission succeeds or expires.

### Fallback Classes

The mod provides fallback classes when the normal class selection pool is exhausted or nearly exhausted.

- **Default fallback:** One fallback class is configured by default: [Captain Rock's Mercenary Class](https://steamcommunity.com/sharedfiles/filedetails/?id=2927887132).
- **Promotions and GTS:** A fallback class is provided when no regular classes remain available.
- **Mission rewards:** A fallback class is offered instead of a regular class when three or fewer regular classes remain available.
- **Hard fallback:** Disabled by default until all unique classes have been exhausted. See the MCM configuration panel.
- **Soft fallback:** Once selected, the fallback class becomes available again after all unique classes have been chosen.

Class restrictions work both with and without **ChooseMyClass**. Each promotion offers a unique class until the available pool is exhausted, after which only fallback classes are offered.

### MEC Training

- MEC training time is halved, allowing base classes to be released and reused sooner.
- The default MEC training fallback (**MEC SUPPORT**) is removed.
- Once all MEC classes have been assigned, no further MEC training is possible until a class becomes available again through a soldier's death or dismissal.

### Psi Lab: Self-Reflection Project

The second Psi Soldier training slot is replaced with a new project called **Self-Reflection**. Since the mod limits the number of Psi Soldiers to one, this replacement keeps the Psi Lab useful.

Self-Reflection allows a soldier to reroll their **XCOM Row**, refunding any Ability Points (AP) already spent.

**Cost:**

- 4 days of training.
- 10 Meld, or 30 Supplies if the *Meld For LWOTC* mod is not active.

The Psi Lab slot replacement can be disabled in the mod's configuration.

> **Warning:** Disable this feature before initializing the mod in a campaign or save. Otherwise, the original slot may not be recoverable.

---

## What the Mod Does Not Do

The following unit types are not subject to the mod's class restrictions:

- **SPARKs:** Robot or player choice.
- **Buildable units:** Robot or player choice.
- **Playable ADVENT:** Remain unique by default for a long time.
- **Playable aliens:** Remain unique by default for a long time.
- **Units obtained through POI or Ring missions:** Such as Viper Bluey, Bounty Hunter, and similar units. These are expected to remain unique.

---

## Requirements

The only hard requirement is:

- **X2WOTCCommunityHighlander** — required for the mod to function correctly.

The following mods are recommended to simplify configuration and provide the default fallback class:

- **MCM (Mod Configuration Menu)** — recommended for in-game configuration.
- **Mercenary Class** — provides the default fallback class.

---

## Compatibility

The following mods are not required, but the mod includes compatibility features for them:

- **LWOTC (Long War of the Chosen)** — most testing has been performed in this environment.
- **ChooseMyClass**
- **MEC Troopers**
- **Meld For Long War of the Chosen**
- **Psi Overhaul v3**
- **Mercenary Class**

### Using the Mod Without Mercenary Class

If you do not use Mercenary Class (and are therefore not using LWOTC), you should change the `FallbackClass` value in `XComClassHighlander.ini` to specify one or more alternative classes.

> **Note:** For normal configuration changes, use MCM rather than editing INI files. The fallback class setting is an exception if you need to define alternative classes and your configuration menu does not expose the relevant option.

---

## Notes

The mod is designed to work in an ongoing campaign, but please read the [Attention](#attention) section before installing it mid-campaign.

### Installing Mid-Campaign

If you enable the mod after starting a campaign, the following limitations may occur:

- The Black Market may continue offering unavailable classes until its next monthly refresh.
- Some missions may still offer restricted classes if they were generated before the mod was activated.
- If the Psi Lab has already been built, it is recommended to rebuild it so that it functions as intended, with a maximum of four slots instead of five.

### ChooseMyClass Behavior

When using ChooseMyClass, displaying the three class choices for multiple soldiers simultaneously can cause an issue: selecting a class for one soldier will reset the choices displayed for the other soldiers.

---

## Configuration

Use **MCM** to configure the mod instead of editing its INI files.

1. Enable the MCM mod.
2. Launch the game.
3. Open **Options → Mod Settings → ClassHighlander**.
4. Adjust the settings as needed.

This is the recommended way to configure the mod and preserve your settings across updates.

---

## Attention

### Risks and Bug Reports

This is my first mod, so bugs and unexpected behavior are possible.

If you encounter a specific issue, please report it in the Steam Workshop comments or on the **LWOTC Discord**, where you can find me under the username `zephyx`.

### Number of Available Classes

To get the most out of this mod, you need a sufficiently large pool of unique classes.

For example, if you play with LWOTC alone, you may only be able to recruit approximately **13 soldiers**:

- 8 regular soldiers.
- 1 Psi Soldier.
- 1 SPARK.
- 3 faction heroes.

This is a significant limitation for a long campaign.

**Recommendation: Aim for at least 40 unique classes** to enjoy the mod comfortably, whether or not you use MEC Troopers, in addition to any playable alien or ADVENT classes.

### Recommended Class Collections

Here are some collections worth exploring to expand your available class pool:

- [Requiem For Tedjam](https://steamcommunity.com/sharedfiles/filedetails/?id=3503978560)
- [Pet Rock Class Collection](https://steamcommunity.com/workshop/filedetails/?id=2727028071)

There are many other collections available, including the Zero collection.
# Loot Rat MVP (Godot 4.5.x)

A deliberately focused loot-game prototype:

**Kill -> loot -> push through rooms -> extract -> equip/sell -> juice the next Claim -> descend for greedier rewards.**

## v0.42 — ARPG Inventory UI
- Reworked the Hideout station menus to be cleaner and more ARPG-like.
- The **Stash is now a real visual grid** instead of a scrolling text list.
- Items appear as compact rarity-bordered cells with slot glyphs and short base names.
- Empty stash cells are visually represented, making the inventory read like a physical container.
- Clicking a grid item opens a dedicated item inspector with comparison, Equip, and Sell actions.
- Equipment is now displayed as three distinct visual slots: Weapon, Armor, and Charm.
- The equipment panel shows only compact build stats instead of repeating full item descriptions.
- The Claim Table was simplified into a compact summary plus a 2×2 modifier grid.
- The Crafting Bench was simplified into a working-item pane and a separate craft-action column.
- This pass uses one grid cell per item; variable-size item footprints and drag/drop packing can be added later if they prove worthwhile.

## v0.41 — Playable Hideout
- Replaced the always-open dashboard hub with an actual top-down **Hideout level**.
- The player now physically moves through the Hideout between Claims.
- Three world stations anchor the loop:
  - **Stash** — opens loadout, stash, sorting, item inspection, equip, and sell.
  - **Crafting Bench** — works on the item currently selected at the Stash.
  - **Claim Table** — handles Claim Tier, Seal investment, modifiers, and starting runs.
- Contextual **[E] interaction prompts** only appear when standing near a station.
- Opening a station pauses player movement and shows only that station's interface.
- **E or Escape** closes the active station and returns control to the Hideout.
- Claim combat UI remains separate and only appears during runs.
- The environment is still systems-first shape art; this pass establishes the physical-space workflow before final hideout art and decoration.

## v0.4 — Crafting Bench
- Added a hub **Crafting Bench** accessible from any selected stash item.
- Crafting materials are real unsecured Claim drops and are only banked on successful extraction.
- **Scrap Orb (T1+)** — rerolls the numerical values of existing normal affixes while preserving their stats and tiers.
- **Mutation Shard (T1+)** — slams a clean Common base into a Magic item with one tier-eligible mechanic and one normal affix.
- **Chaos Token (T2+)** — rerolls all normal affix stats/tiers while preserving the base item and its mechanical affix.
- **Mechanist's Seal (T3+)** — rerolls one mechanical affix within the player's currently unlocked Claim Tier.
- Crafting cannot roll mechanics or affix tiers beyond the player's current Claim Tier.
- Existing saves gain an empty crafting-material stash automatically.
- Crafting materials have modest net-worth values, but there is currently no vendor conversion; their main value is item development.
- The intended loop is now **find a promising base → invest scarce currency → decide whether to keep slamming or stop**.

## v0.32 — Mechanical Affixes
Items now change gameplay, not just numbers. Mechanical affixes are **hard-gated by Claim Tier**, so distinct upgrades do not bypass the slow progression curve.

- **T1:** Point Blank, Heavy Rounds, Quickstep, Adrenaline Lining, Magnet Heart, Field Medic.
- **T2:** Split Chamber, Bore Rounds, Second Wind, Hoarder's Bargain.
- **T3:** Ricochet, Kill Frenzy, Armored Greed, Treasure Scent.
- **T4:** Explosive Rounds, Glass Rat, Elite Tax.
- **T5:** King's Barrage, Dead Man's Insurance, Hoarder's Curse, Double Drop.
- Common items remain simple.
- Magic items get **1 mechanic + 1 stat affix**.
- Rare items get **1 mechanic + 2 stat affixes**.
- Gilded items get **2 mechanics + 3 stat affixes**, with the first mechanic biased toward late-tier effects.
- Existing gear remains compatible and simply has no mechanical affix until replaced.
- Mechanical affixes add only modest vendor value so stronger loot does not instantly explode the Coin economy.

## v0.31 — Claim Tier Progression
- Added persistent **Claim Tiers T1–T5**.
- Claim Tier is now the hard gate for loot progression; descending deeply cannot bypass it.
- **T1:** Common + Magic only. Rare is impossible.
- **T2:** first Rare eligibility, but never on Depth 1.
- **T3/T4:** progressively better Rare odds and higher affix ceilings.
- **T5:** Gilded becomes eligible, but only from Depth 5 onward and at chase-level odds.
- Affix ceilings are tied directly to Claim Tier: T1→T5 affixes, T2→T4, T3→T3, T4→T2, T5→T1.
- Depth improves the chance of rolling the best affix tier currently unlocked, but never unlocks a later tier.
- Successful extraction records your best depth for the active Claim Tier.
- Unlocking the next Claim Tier requires both a successful depth milestone and a substantial Coin investment:
  - T2: extract Depth 4 + ₵1,200
  - T3: extract Depth 5 + ₵6,000
  - T4: extract Depth 6 + ₵25,000
  - T5: extract Depth 8 + ₵100,000
- Higher Claim Tiers are also substantially harder and only modestly more rewarding, preventing immediate wealth runaway.
- Claim Tier progression is saved permanently and reset by Wipe Save.

## v0.3 — Itemization
- Gear now has meaningful **base types** with built-in implicit stats.
- Four weapon bases retain distinct firing behavior and now have different implicit bonuses.
- Armor bases specialize into health, movement, or loot finding.
- Charm bases specialize into currency, item finding, damage, or movement.
- Item rarity now controls affix count:
  - **Common:** base implicit only
  - **Magic:** 1–2 affixes
  - **Rare:** 3 affixes
  - **Gilded:** 4 affixes, including a guaranteed loot-oriented affix
- Affixes now have visible **T5 → T1 tiers**.
- Higher Claim depths unlock stronger affix tiers.
- Items display item level, base type, implicit, affix tiers, and estimated value.
- Gilded drops have gold presentation and a distinct loot-feed callout.
- Existing saves are migrated into the new item format instead of being invalidated.

## v0.25 — Hub Overhaul
- New three-column hub: **Claim Prep / Loadout & Stats / Stash**.
- Coins, Seals, and Net Worth are now persistent top-level readouts.
- Claim juicing clearly shows available Seals, invested Seals, risk, and modifier totals.
- Build stats are grouped into Offense, Survival, and Loot.
- Equipped Weapon, Armor, and Charm have their own readable loadout section.
- Stash filters: All / Weapons / Armor / Charms.
- Stash sorting: Value / Rarity / Newest.
- Clicking an item opens a dedicated inspector.
- Inspector compares the selected item against currently equipped gear with green/red stat deltas.
- Equip and Sell actions now operate from the inspector.
- Bulk selling respects the active stash filter.

## v0.2 — First Real Claim
- Claims are now 5–8 room runs instead of one arena dump.
- Random PACK, SWARM, ELITE, TREASURE, and BOSS rooms.
- Clear a room, collect the pile, then press **E** to push forward.
- Four real weapon bases:
  - **Repeater** — dependable automatic fire.
  - **Scattergun** — slow five-pellet spread.
  - **Piercer** — heavy shot that punches through multiple enemies.
  - **Sprayer** — very fast, lower-damage bullet hose.
- Four enemy archetypes: chaser, skitter, brute, ranged shooter.
- Elite and boss variants.
- Hit flash, knockback, damage numbers, attack telegraphs.
- Ground labels for meaningful loot.
- Very rare **JACKPOT** currency drops.
- Treasure rooms produce a bonus cache after the pack is cleared.
- Existing Claim juicing, stash, equipment, net worth, extraction, death-loss, and save systems remain intact.

## Run
1. Open this folder in Godot 4.5.x.
2. Run the project.
3. At the Claim Table, optionally spend Seals to juice the next run.
4. Click **RUN CLAIM**.

## Controls
- WASD: move
- Hold Left Mouse: fire toward cursor
- Space: dash / brief invulnerability
- E: leave a cleared room and enter the next chamber

## Current goal
This build is still intentionally shape-art and systems-first. The question being tested is whether room pacing + distinct weapons + greed/extraction makes the loot economy compelling enough to build on.

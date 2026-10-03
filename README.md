# Loot Rat MVP (Godot 4.5.x)

A deliberately focused loot-game prototype:

**Kill -> loot -> push through rooms -> extract -> equip/sell -> juice the next Claim -> descend for greedier rewards.**

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

# Loot Rat MVP (Godot 4.5.x)

A deliberately small prototype for testing one loop:

**Kill -> loot -> extract -> equip/sell -> juice the next run -> descend for greedier rewards.**

## Run
1. Open this folder in Godot 4.5.x.
2. Run the project (`F6`/`F5`).
3. At the Claim Table, optionally spend Seals to juice the next run.
4. Click **RUN CLAIM**.

## Controls
- WASD: move
- Hold Left Mouse: fire toward cursor
- Space: dash / brief invulnerability

## MVP systems
- Short arena-based Claims
- Increasing depth and enemy scaling
- Elite enemies
- Loot explosions with coins, Seals, and gear
- Three gear slots: Weapon, Armor, Charm
- Item affixes including combat power and loot-find stats
- Extract vs Descend decision after every floor
- All run loot is unsecured until extraction
- Death deletes the unsecured haul
- Claim juicing: density, item quantity, currency quantity, elite chance
- Stash, equip, sell, net worth
- Persistent save at `user://loot_rat_save.json`

## Intentional omissions
No final art, campaign, skill tree, crafting tree, bosses, vendors, or procedural rooms yet. The purpose of this build is to validate the economic/greed loop before expanding scope.

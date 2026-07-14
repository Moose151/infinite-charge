# Infinite Charge Handover

## Current Status

Infinite Charge is a Godot 4 idle-management game. The repo currently contains the first garage-stage MVP scaffold: one scene, a data-driven starter upgrade list, a separate simulation layer, JSON save/load, offline progress, and a simple desktop UI.

The project has been pushed to GitHub:

`https://github.com/Moose151/infinite-charge`

## Source Of Truth

Read `Scope.docx` for the full game direction. The immediate build target is section 26, "Initial Minimum Viable Product".

The MVP should stay focused on:

- one battery-cell product
- cash
- one raw material
- manual production
- adjustable sale price
- demand that responds to price
- automatic sales
- changing material price
- five to ten upgrades
- basic advertising
- basic production automation
- firewall, backups, and multifactor authentication
- basic security risk and abstract security events
- save/load
- offline progress
- basic statistics
- settings

Avoid starting factories, staff, research trees, contracts, prestige, network maps, or space systems until the garage loop feels good.

## Architecture

- `scenes/Main.tscn` is intentionally minimal and points to `scripts/main.gd`.
- `scripts/main.gd` builds the first UI in code and connects player actions.
- `scripts/game_state.gd` owns serializable state only.
- `scripts/simulation.gd` advances the game and handles player actions like producing, buying materials, and upgrades.
- `scripts/formulas.gd` owns tuning formulas such as demand, risk, and number formatting.
- `scripts/save_manager.gd` writes/reads JSON from `user://save_slot_1.json`.
- `data/upgrades/garage_upgrades.json` defines current upgrades and effects.

Keep simulation behavior out of UI code whenever possible. Future offline progress, tests, automation, and balance tools all depend on `Simulation.advance()` staying independent from the interface.

## Current Gameplay

The player can:

- assemble cells manually
- buy raw materials
- adjust sale price
- sell cells automatically based on demand
- see material prices drift over time
- buy starter upgrades
- experience basic abstract security events
- save manually and autosave
- receive offline progress after reopening

## Known Limitations

- Godot is not installed on PATH in the current shell, so the project has not been editor-run from this environment.
- The UI is functional placeholder work, not final presentation.
- Balance values are first-pass guesses.
- Save migration exists only as a version field, not a real migration pipeline.
- The current event system is embedded in `Simulation`; it should become data-driven after MVP feel is proven.
- There are no automated tests yet.

## Recommended Next Steps

1. Open the project in Godot 4 and fix any parser/runtime issues.
2. Play the first 10 minutes and tune:
   - starting cash/materials
   - demand curve
   - material price drift
   - upgrade costs
   - automation speed
3. Add a small settings screen or panel for interface scale, offline limit, and autosave interval.
4. Add clearer market explanations:
   - why demand changed
   - estimated margin
   - sell-through rate
5. Add basic stats:
   - cells made
   - cells sold
   - revenue
   - materials bought
   - security losses
   - play time
6. Once the loop is readable and satisfying, begin Milestone One: production stages, maintenance, quality, warehouse capacity, and first contracts.

## Tone Notes

The game should keep a dry corporate-comedy voice. Good messages should sound like internal reports written by people who have accepted absurdity as a quarterly deliverable.

Example style:

- "Procurement has updated the spreadsheet."
- "Manual save completed. Accountability has been assigned."
- "The supplier has agreed to send fewer boxes containing smaller boxes."

Use humor as flavor, not as interruption.

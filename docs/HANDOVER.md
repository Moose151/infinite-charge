# Infinite Charge Handover

## Current Status

Infinite Charge is a Godot 4 idle-management game. The repo contains the garage-stage MVP: one scene, a data-driven upgrade list, data-driven security events, a separate simulation layer, JSON save/load, offline progress, a headless balance harness, a headless test suite, and a simple desktop UI.

The MVP loop has been balance-tested via `tools/balance_harness.gd` (a bot that plays the first hour at several price points). At the default $4 price a player reaches first automation around minute 5, clicking becomes optional as automation scales, and most upgrades max out within the hour. The optimal sale price shifts from ~$4 early (demand-limited) toward $6 late (supply-limited), so the pricing decision stays live throughout the session.

Milestone One is underway. Warehouse capacity and maintenance are in (v0.3): storage caps production until Garage Shelving is bought, machines wear down as automation runs (efficiency 100% → 40%), and servicing costs cash scaled to automation size and wear. Production stages and quality are in (v0.4): prep → assembly → testing, where prep hard-limits throughput and under-tested output lowers effective quality, which feeds demand. First contracts are in (v0.5): periodic local offers at 0.95–1.3× fair value with deadlines, trust rewards for completion, and penalties for failure; contracts pause offline. Employees and energy are in (v0.6): staff hired per stage with continuous wages and strikes on missed payroll, and per-cell energy billing at a drifting price. **Milestone One is complete.** Next per the scope: Milestone Two, Market Depth (customer segments, multiple products, advertising channels, competitors, reputation, contract requirements).

The project has been pushed to GitHub:

`https://github.com/Moose151/infinite-charge`

## Versioning

`CHANGELOG.md` at the repo root is the version history. The scheme is `0.x` for larger updates and `0.x.y` for small ones, starting from 0.1. **Every commit/push must update `CHANGELOG.md`** and keep `application/config/version` in `project.godot` in sync (it is displayed in the game title).

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
- `data/events/security_events.json` defines security events: trigger cadence, chance scaling with risk, and per-event type (`cash`, `inventory`, `downtime`), weight, severity range, and message.
- `tools/run_tests.gd` is the headless test suite (125 checks over Formulas, Simulation actions, security events, downtime, warehouse capacity, maintenance, production stages, quality, energy, employees, contracts, chunked offline advance, bankruptcy rescue, save round-trip). Run: `godot --headless --path . --script res://tools/run_tests.gd` (exits non-zero on failure).
- `tools/balance_harness.gd` simulates a bot player for an hour at several fixed prices and prints a progression table. Run: `godot --headless --path . --script res://tools/balance_harness.gd`.

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

## Environment Notes

- The standard (non-mono) Godot 4.7 binary is installed at `~/.local/bin/godot` and is on PATH. Use it for everything.
- The `godot-4` snap on this machine is the mono/C# build; it shows a harmless but annoying ".NET runtime" popup on every launch because no .NET SDK is installed. This project has no C#, so the snap build is best avoided.

## Known Limitations

- The UI is functional placeholder work, not final presentation.
- Balance is harness-tested but not yet human-playtested; the bot cannot judge feel.
- Save migration exists only as a version field, not a real migration pipeline.
- Settings (speed, autosave, offline limit, interface scale) live inline in the middle panel rather than a dedicated settings screen, and are stored in the save file rather than a separate config.
- The interface scale applies via `Window.content_scale_factor`; it has been verified headless only.

## Recommended Next Steps

1. Human-playtest the full loop now that Milestone One is complete — the middle panel is getting dense and may want tabs or collapsible sections before Milestone Two adds more.
2. Begin Milestone Two (Market Depth): customer segments first (different price/quality sensitivities give pricing more texture), then a second product tier.
3. Consider surfacing wear rate and time-to-empty-warehouse estimates now that production stages add complexity.

## Balance Changes (2026-07-15)

Derived from harness runs; previous values stalled progression at ~25 minutes with automation never overtaking clicking.

- Base demand coefficient 0.55 → 0.7 (`formulas.gd`).
- Advertising: awareness +0.18 → +0.25 per level, cost scale 1.65 → 1.6.
- Workbench Automation: +0.15 → +0.35 cells/sec per level, base cost 140 → 110, scale 1.7 → 1.55, risk +0.015 → +0.02 per level.
- Better Hand Tools capped at level 5 (was 8) so clicking does not outscale automation.
- New upgrade: Online Storefront (+0.4 awareness, +0.05 risk per level) — the deliberate growth-vs-risk trade-off.
- Security events moved to JSON and made meaningful: cash losses 6–20% of cash, inventory theft 15–35% of stock, production downtime 20–70 seconds. Backups (recovery) mitigate all three.
- Bankruptcy safety net: a player with under $5, no materials, and no inventory receives a $25 pity investment; materials can also be bought in batches of 1/10/100.

## Tone Notes

The game should keep a dry corporate-comedy voice. Good messages should sound like internal reports written by people who have accepted absurdity as a quarterly deliverable.

Example style:

- "Procurement has updated the spreadsheet."
- "Manual save completed. Accountability has been assigned."
- "The supplier has agreed to send fewer boxes containing smaller boxes."

Use humor as flavor, not as interruption.

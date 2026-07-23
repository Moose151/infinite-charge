# Infinite Charge Handover

## Current Status

Infinite Charge is a Godot 4 idle-management game. The repo contains the garage-stage MVP: one scene, a data-driven upgrade list, data-driven security events, a separate simulation layer, JSON save/load, offline progress, a headless balance harness, a headless test suite, and a tabbed desktop operations-console UI.

The MVP loop has been balance-tested via `tools/balance_harness.gd` (a bot that plays the first hour at several price points). At the default $4 price a player reaches first automation around minute 5, clicking becomes optional as automation scales, and most upgrades max out within the hour. The optimal sale price shifts from ~$4 early (demand-limited) toward $6 late (supply-limited), so the pricing decision stays live throughout the session.

Milestones One through Four are complete. v0.20 adds Corporate Management: satellite factories, departments, managers, automation rules, fixed-term supply contracts, and rolling detailed statistics. The dedicated corporate harness progresses a mature garage through the entire layer and validates the late-game economy.

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
- `tools/run_tests.gd` is the headless test suite (customer segments, multiple products, Formulas, Simulation actions, security events, downtime, warehouse capacity, maintenance, production stages, quality, energy, employees, contracts, chunked offline advance, bankruptcy rescue, save round-trip). Run: `godot --headless --path . --script res://tools/run_tests.gd` (exits non-zero on failure).
- `tools/balance_harness.gd` simulates a bot player for an hour at several fixed prices and prints a progression table. Run: `godot --headless --path . --script res://tools/balance_harness.gd`.
- `docs/MILESTONE_TWO_ACCEPTANCE.md` records the acceptance criteria and evidence for the completed Market Depth milestone.
- `docs/MILESTONE_THREE_ACCEPTANCE.md` records the acceptance criteria and evidence for the completed Industrial Cybersecurity milestone.
- `docs/MILESTONE_FOUR_ACCEPTANCE.md` records the acceptance criteria and evidence for the completed Corporate Management milestone.
- `tools/corporate_harness.gd` validates two hours of corporate expansion from the Milestone Four handoff.

Keep simulation behavior out of UI code whenever possible. Future offline progress, tests, automation, and balance tools all depend on `Simulation.advance()` staying independent from the interface.

## Current Gameplay

The player can:

- assemble cells manually
- buy whole component kits with live purchase prices
- adjust sale price
- sell cells automatically based on demand
- accumulate production and demand smoothly while completing and selling only whole cells
- unlock Long-Life Cells, route the shared line between products, and price each product separately
- see material prices drift over time
- buy starter upgrades
- experience basic abstract security events
- save manually and autosave
- receive offline progress after reopening

## Environment Notes

- The previously documented `~/.local/bin/godot` binary was absent on 2026-07-23. Validation used the official temporary Godot 4.7 standard Linux build; install or restore a local standard build before routine development.
- The `godot-4` snap on this machine is the mono/C# build; it shows a harmless but annoying ".NET runtime" popup on every launch because no .NET SDK is installed. This project has no C#, so the snap build is best avoided.

## Known Limitations

- The code-built UI received a full information-architecture pass in v0.11, a theme system in v0.12, and a state-driven Garage Floor overview in v0.15. The overview establishes visible equipment and staffing progression, but it remains a compact operations schematic rather than an illustrated factory scene. Richer spaces, animation, and optional cosmetics remain future work.
- The v0.13 economy is harness-tested but not yet human-playtested; the bot now tapers manual clicking after automation, but cannot judge feel.
- Save migration exists only as a version field, not a real migration pipeline.
- Settings (speed, autosave, offline limit, interface scale) now live in the Office tab, but are stored in the save file rather than a separate config.
- The interface scale applies via `Window.content_scale_factor`; it has been verified headless only.

## Recommended Next Steps

1. Human-playtest the full Milestones Two–Four progression, especially the handoff from garage upgrades into cybersecurity and corporate management.
2. Tune factory and department costs, manager wages, automation thresholds, and supplier-contract value from human feedback.
3. Review the detailed-statistics presentation and decide whether graphs materially improve decisions over the current trend summary.
4. Begin Milestone Five only after the full corporate handoff has been human-playtested.

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

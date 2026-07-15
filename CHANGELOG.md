# Version History

Versioning scheme: `0.x` for larger updates (new systems, milestones, significant balance passes), `0.x.y` for small updates (fixes, tweaks, minor additions). The version lives in `project.godot` under `application/config/version` and is shown in the game title.

**Rule: every commit/push must update this file** — bump the version appropriately and list what changed.

## 0.2 — 2026-07-15

Balance pass, meaningful security, and test infrastructure.

- Added headless balance harness (`tools/balance_harness.gd`) simulating the first hour at multiple price points.
- Retuned economy from harness findings: base demand 0.55 → 0.7, stronger/cheaper Workbench Automation (+0.35/sec per level), stronger Advertising (+0.25 awareness), Better Hand Tools capped at level 5. Automation now overtakes clicking within the hour; upgrades max out across 50–60 minutes.
- New upgrade: Online Storefront (+0.4 awareness, +0.05 risk per level) — deliberate growth-vs-risk trade-off.
- Security events moved to `data/events/security_events.json` and made meaningful: cash losses (6–20%), inventory theft (15–35% of stock), production downtime (20–70 s, shown in UI). Backups mitigate all three.
- Bankruptcy safety net: $25 pity investment when the player has under $5, no materials, and no inventory.
- Materials purchasable in batches of 1/10/100.
- Interface-scale setting (100–200%).
- Manual clicks no longer spam the event log.
- Headless test suite (`tools/run_tests.gd`), 53 checks, exits non-zero on failure.
- Removed stray `[dotnet]` section from `project.godot` (project is pure GDScript).

## 0.1 — 2026-07-14

Initial garage-stage MVP scaffold.

- One scene, code-built desktop UI.
- Manual production, material buying, adjustable sale price, price-responsive demand, automatic sales, drifting material price.
- Eight data-driven upgrades including Firewall, Backups, and Multifactor Authentication.
- Abstract security events, security risk value.
- JSON save/load, autosave, offline progress with report.
- Basic statistics and inline settings (pause, speed, autosave interval, offline limit).

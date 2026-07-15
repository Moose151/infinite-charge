# Version History

Versioning scheme: `0.x` for larger updates (new systems, milestones, significant balance passes), `0.x.y` for small updates (fixes, tweaks, minor additions). The version lives in `project.godot` under `application/config/version` and is shown in the game title.

**Rule: every commit/push must update this file** — bump the version appropriately and list what changed.

## 0.4 — 2026-07-15

Production stages and product quality (Milestone One continues).

- Automated production now flows through stages: prep → assembly → testing. Prep is a hard bottleneck — automated output = min(prep rate, assembly rate) × machine efficiency. The production readout shows all three rates and names the limiting stage.
- Testing is a quality knob rather than a hard cap: cells shipped faster than the testing stage can check them lower effective quality (scope: "poor-quality products may still sell").
- Effective quality = design quality × machine condition × testing coverage, and feeds demand and fair price — neglected maintenance now hurts sales, not just output.
- New upgrades: Prep Station (+0.45 prep/sec, 8 levels) and Testing Bench (+0.45 testing/sec, 8 levels).
- Harness bot now plays the bottleneck (skips stage upgrades that would overshoot). Informed play earns ~$57k in the first hour at the default price — the stage system adds ~30% friction versus v0.3, with no stalls.
- Test suite extended to 84 checks.

## 0.3 — 2026-07-15

Milestone One begins: warehouse capacity and maintenance, plus MVP readability polish.

- Warehouse capacity (starts at 60 cells): automated and manual production halt when storage is full. New Garage Shelving upgrade (+60 capacity per level, 8 levels).
- Maintenance: automated production wears machines down; efficiency drops from 100% toward 40% as condition falls. A Service Machines button restores condition for a cash cost that scales with automation size and wear. New Preventive Maintenance upgrade reduces wear.
- Offline progress now simulates in 30-second chunks so warehouse capacity doesn't cap an entire night's production at one warehouse-load.
- UI readability: security risk shows its breakdown (base + operations − defenses), inventory shows capacity and cash value at the current price, stats track sales lost to stock-outs.
- Harness bot services machines; test suite extended to 72 checks (capacity, maintenance, lost sales, chunked offline advance).
- Balance check: at the default $4 price the hour now yields ~$80k revenue (v0.2: ~$103k) — the new upkeep friction costs ~23%, progression stays smooth with no stalls.

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

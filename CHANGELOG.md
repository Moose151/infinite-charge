# Version History

Versioning scheme: `0.x` for larger updates (new systems, milestones, significant balance passes), `0.x.y` for small updates (fixes, tweaks, minor additions). The version lives in `project.godot` under `application/config/version` and is shown in the game title.

**Rule: every commit/push must update this file** — bump the version appropriately and list what changed.

## 0.9 — 2026-07-23

Advertising channels — awareness now comes with an invoice and an intended audience.

- Added toggleable Neighbourhood Flyers, Business Directory, and Specialist Newsletter campaigns with continuous running costs.
- Made each channel favour a different customer segment, creating product-and-audience choices instead of a generic demand multiplier.
- Campaigns pause automatically when they can no longer be funded, and advertising spend is tracked and saved.
- Added an Advertising Channels UI card and headless coverage for targeting, costs, automatic pausing, validation, and persistence.

## 0.8 — 2026-07-23

Multiple products — the garage acquires a second thing to put on invoices.

- Added an unlockable Long-Life Cell product with separate inventory, sale price, demand, and automatic sales.
- Added production routing between Standard and Long-Life Cells; the premium design uses 1.5 material units per cell and shares warehouse capacity with standard stock.
- Gave Long-Life Cells a quality/value premium and a market mix weighted toward specialist buyers rather than budget households.
- Extended save/load and the headless suite for product unlocking, production, sales, routing, shared storage, and persistence.

## 0.7 — 2026-07-22

Customer segments — Milestone Two (Market Depth) begins.

- Split spot-market demand across budget households, local businesses, and specialist buyers.
- Gave each segment distinct price and quality sensitivity: households react sharply to price, while specialists tolerate higher prices and reward quality more strongly.
- Added a live customer-mix breakdown with percentage shares and demand rates to the Price Desk so price changes show who remains in the market.
- Extended the headless suite with segment-total, price-sensitivity, and quality-sensitivity coverage.

## 0.6.5 — 2026-07-15

First-screen flow pass.

- Reworked the screen around always-visible Workshop, Company Floor, and Growth & Log columns instead of hidden section navigation.
- Moved manual assembly, material buying, price, stock, production, staff, contracts, upgrades, log, and ledger into visible grouped areas.
- Added small live meters for inventory, security risk, product quality, and machine condition.
- Updated the handover with the future direction for a visible workshop that changes with upgrades and cosmetics.

## 0.6.4 — 2026-07-15

Navigation clarity fix.

- Replaced nested Godot tab containers with explicit section buttons for Operations, Staff, and Settings.
- Added real Upgrades and Event Log buttons in the right panel so the event log is a selectable view instead of a heading that looks clickable.

## 0.6.3 — 2026-07-15

Viewport fit fix.

- Added internal scrolling to the main Company, Production & Market, and Upgrades & Events panels so controls remain reachable in the Godot F5 window.
- Increased the default desktop viewport height from 720 to 800 pixels to better fit the current three-column MVP interface.

## 0.6.2 — 2026-07-15

Interface-scale safety fix.

- Reset oversized saved interface scales to 100% on launch so the game cannot reopen in an unusable zoom state.
- Temporarily limited the interface-scale option to 100% until responsive scaling has a dedicated pass.
- Added `Ctrl+0` as an emergency interface-scale reset shortcut.

## 0.6.1 — 2026-07-15

Garage UI readability pass.

- Added a short garage-operations subtitle to the first screen.
- Grouped the Company panel into Resources, Statistics, and Contracts sections.
- Split the dense Production & Market panel into persistent action controls plus Operations, Staff, and Settings tabs.
- Added section headers and subtle panel styling to improve scanability without changing simulation behavior.

## 0.6 — 2026-07-15

Employees and energy consumption — Milestone One (Factory Expansion) complete.

- Energy: automated production is billed per cell at a drifting energy price ($0.05–0.35, drifts every 25 s). Margin readout now shows price − materials − energy. New Efficient Drives upgrade (−12% energy per level, 4 levels).
- Employees: hire up to 2 workers per stage (prep, assembly, testing) for a $150 fee plus $0.35/s wages. Workers add +0.4/s to their stage — assembly hands can build cells before you own any machines.
- Missed payroll puts staff on strike (boosts stop, wages stop) until cash covers wages again.
- Staff section in the production panel; wages and energy tracked in lifetime stats.
- Test suite extended to 125 checks; harness bot hires toward the bottleneck stage.
- Milestone One systems all present: production stages, maintenance, quality, employees, warehouse capacity, energy consumption, first contracts.

## 0.5 — 2026-07-15

First contracts (Milestone One continues).

- Local contract offers arrive every ~3 minutes while no contract is pending: deliver N cells within a deadline for a fixed price per cell. Offers expire in 60 seconds if ignored.
- Offer prices range 0.95–1.3× current fair value, so some offers are bad deals — reading the margin is the point.
- Deliveries pull from inventory ahead of spot sales; payment lands in full on completion. Completion builds trust (which feeds demand); missing the deadline costs a 10% penalty and trust.
- Contracts pause entirely during offline progress — no waking up to failed deadlines.
- Contracts section in the Company panel with offer details, accept/decline, delivery progress, and lifetime stats.
- Harness bot evaluates feasibility and margin before accepting; at the default price, contracts contribute ~30% of first-hour revenue ($44k of $141k, 19 completed).
- Test suite extended to 104 checks.

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

# Version History

Versioning scheme: `0.x` for larger updates (new systems, milestones, significant balance passes), `0.x.y` for small updates (fixes, tweaks, minor additions). The version lives in `project.godot` under `application/config/version` and is shown in the game title.

**Rule: every commit/push must update this file** — bump the version appropriately and list what changed.

## 0.19 — 2026-07-23

Milestone Three: Industrial Cybersecurity complete.

- Added a dedicated Security workspace with a live network map covering the public edge, office systems, production controllers, and recovery store.
- Added four levels of network topology, from one flat workshop LAN through separated Office and Production zones, an isolated Recovery zone, and a public-edge DMZ.
- Added three-level programmes for segmentation, threat detection, incident response, and recovery planning with escalating investment costs.
- Security incidents now pass through detection and containment; detected but uncontained incidents receive response mitigation, while segmentation limits blast radius and recovery reduces residual damage.
- Added up to three security analysts who improve detection and response, charge continuous wages, and go off duty when payroll is missed.
- Added an Incident Desk with affected zone, outcome, last-event detail, detected/contained/impact totals, and security losses.
- Persisted the complete cybersecurity programme, staffing, payroll, incident history, and lifetime statistics.
- Extended the balance bot to invest in cybersecurity and report programme progression and incident outcomes.
- Added `docs/MILESTONE_THREE_ACCEPTANCE.md` and expanded the headless suite across every Milestone Three system.

## 0.18 — 2026-07-23

Milestone Two: Market Depth complete.

- Completed an acceptance audit covering customer segments, multiple products, advertising channels, competitors, multidimensional reputation, and contract requirements.
- Added Long-Life customer-mix and competitive-position readouts so premium market calculations are fully visible rather than operating behind the interface.
- Made seeded contract-buyer selection deterministic for repeatable tests and balance runs.
- Added integration coverage proving general reputation affects demand, every campaign favours its intended audience, premium demand responds to competition, and qualified contract tiers improve both order size and pricing.
- Added `docs/MILESTONE_TWO_ACCEPTANCE.md` as the milestone acceptance record and validation checklist.

## 0.17 — 2026-07-23

Operations Watch.

- Added a live priority strip to the Garage Floor that turns forecasts into concise operational warnings.
- Detects imminent kit depletion, stockouts, warehouse saturation, maintenance, incident downtime, payroll strikes, and negative active-product margins.
- Separates immediate action from near-term watch items, limits the display to the three most important constraints, and returns to a stable status automatically.
- Uses the active colour scheme's semantic warning and success colours without generating repetitive activity-log messages.

## 0.16 — 2026-07-23

Operational runway estimates.

- Added live component-kit runway based on the active product recipe and current automated throughput.
- Added stockout and warehouse-fill forecasts based on total inventory, unlocked-product demand, output, and free capacity.
- Added machine wear per minute and estimated time until the recommended 70% service threshold.
- Covered material, inventory, capacity, and servicing estimates with headless tests.

## 0.15 — 2026-07-23

Visible garage-floor progression.

- Added a live Garage Floor overview to Operations with assembly, prep, testing, stockroom, crew, and security stations.
- Each station visibly changes its equipment description, levels, staffing, capacity, throughput, coverage, or controls as the corresponding game systems progress.
- Added workshop-stage progression from One-Person Garage through Mechanised Workshop to Compact Production Floor.
- Kept the view derived entirely from existing simulation state so old saves and offline progress update it automatically.

## 0.14 — 2026-07-23

Reputation and contract qualification.

- Split reputation into visible general, delivery, quality, and security scores.
- Contract success now improves delivery, general, and quality reputation; missed deadlines damage delivery and general standing, while security incidents damage security standing.
- Added Approved Supplier and Assured Supply contract tiers with reputation requirements, larger orders, and better pricing.
- Added an always-visible next-tier qualification readout and completion totals for each contract tier.
- Contract acceptance rechecks requirements so a newly reported incident can invalidate a pending offer.
- Security reputation now rises during incident-free audit periods and takes bounded, defense-sensitive damage from incidents.
- Persisted all reputation categories and migrated old saves from the legacy trust score.
- Restored the Unit Economics refresh function so the v0.13 interface starts cleanly and reports lifetime net cash flow.
- Expanded the balance harness and headless suite for reputation pacing, tier history, qualification checks, and save/load.

## 0.13 — 2026-07-23

Core economy and unit-model rebuild.

- Replaced vague raw-material units with whole component kits: Standard Cells require one kit and Long-Life Cells require two.
- Production work and customer demand now accumulate internally but only complete, store, contract, and sell whole cells; old fractional inventory is normalised when loaded.
- Automation now requires enough cash to pay the full energy cost before producing and can no longer receive free energy at zero cash.
- Reframed operational readouts around cells/minute and dollars/minute, with explicit recipe costs, live purchase prices, whole-order sales language, and product margins.
- Added a detailed cash-flow ledger for spot sales, contracts, kits, energy, wages, upgrades, hiring, maintenance, advertising, and security losses.
- Reduced wages and campaign running costs to workshop-scale values, and revised the balance bot so manual clicking tapers as automation takes over.
- Expanded headless coverage for whole-unit accumulation, energy affordability, recipes, margins, spending categories, and persistence.

## 0.12 — 2026-07-23

Colour themes and display modes.

- Added Workshop, Corporate, and Solar colour schemes, each with coordinated light and dark modes.
- Added live appearance controls to the Office tab and persisted both choices through save/load.
- Refactored panels, cards, headings, tabs, buttons, inputs, meters, status text, and the activity feed to consume shared theme palettes instead of fixed colours.
- Added safe fallback handling for theme values from older or manually edited saves.

## 0.11 — 2026-07-23

Operations-console UI overhaul.

- Replaced the three dense scrolling columns with task-focused Operations, Market, Company, and Office tabs plus a persistent activity feed.
- Grouped production, stock, pricing, advertising, crew, contracts, upgrades, settings, and statistics around the decisions players are trying to make.
- Added a persistent cash/material/inventory summary, clearer hierarchy, a larger primary production action, and more readable labels.
- Introduced a cohesive dark workshop-console theme with teal status accents, warm headings, stronger button states, improved spacing, and minimum-window-friendly sizing.

## 0.10 — 2026-07-23

Competitor pressure — another garage has discovered commerce.

- Added Volt & Sons, a lightweight local competitor whose standard-cell price and quality drift every 45 seconds.
- Competitor value now modifies demand by customer sensitivity: budget households react more strongly, while specialists are less easily diverted by price positioning.
- Added a live competitor comparison and plain-language market position to the Price Desk.
- Persisted competitor state and added headless coverage for competitive strength, segment sensitivity, market updates, event messages, and save/load.

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

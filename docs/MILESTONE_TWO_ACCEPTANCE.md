# Milestone Two Acceptance

Milestone Two: Market Depth is complete as of v0.18.

## Customer segments

- Budget households, local businesses, and specialist buyers contribute separately to demand.
- Each segment has distinct price and quality sensitivity.
- Standard and Long-Life customer mixes are visible in the Market tab.
- Covered by headless demand-total, price, quality, and reputation checks.

## Multiple products

- Standard and Long-Life Cells have separate recipes, inventory, pricing, demand, sales progress, and margins.
- The shared production line can be routed between products.
- Both products share warehouse capacity and respond to segment preferences, advertising, reputation, and competition.
- Covered by headless unlock, routing, production, recipe, storage, sales, segment, and competitor checks.

## Advertising channels

- Neighbourhood Flyers, Business Directory, and Specialist Newsletter target different segments.
- Campaigns have continuous costs, pause when unaffordable, and persist through saves.
- Covered by headless targeting, billing, automatic-pause, validation, and persistence checks.

## Competitors

- Volt & Sons has changing price and quality.
- Competitor value affects both products and price-sensitive segments more strongly.
- Standard and Long-Life competitive positions are visible in the Market tab.
- Covered by headless value, sensitivity, market-update, event-log, premium-product, and persistence checks.

## Reputation

- General, delivery, quality, and security reputation are visible and persistent.
- General reputation affects demand; contract outcomes affect general, delivery, and quality standing.
- Clean security periods build security standing, while incidents cause bounded damage.
- Covered by headless demand, contract-outcome, security-event, clean-period, migration, and persistence checks.

## Contract requirements

- Open Market, Approved Supplier, and Assured Supply tiers have escalating multidimensional requirements.
- Higher tiers provide larger orders and better prices.
- The Company tab shows the next qualification, offer requirements, active tier, and completion history.
- Acceptance rechecks requirements in case reputation changes while an offer is pending.
- Covered by headless qualification, economic scaling, acceptance, outcome, history, and persistence checks.

## Release validation

Run:

```sh
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/balance_harness.gd
```

The main scene must also start without parser or runtime errors.

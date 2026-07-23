# Milestone Six Acceptance

Milestone Six: Global Energy is complete as of v0.22.

## Prestige and grid infrastructure

- The first prestige has explicit revenue/project requirements, a previewed Legacy Point award, and a guarded confirmation.
- Legacy Points survive the reset and permanently improve production, demand, research, and grid output.
- Five grid levels require escalating cash and research and add national energy output.

## National markets and recycling

- Domestic, Industrial, and Export allocations always total 100%.
- Each market has an independently drifting spot price; allocation determines the weighted sale price.
- Grid spot revenue progresses online and offline and is tracked separately.
- Five recycling levels recover 5% per level of component kits used by automated production, up to 25%.

## Large-scale contracts and global events

- National dispatch offers quantity, price, duration, and expiry terms.
- Accepted contracts consume grid output before spot dispatch and record completions, failures, and revenue.
- Timed global events temporarily raise or lower targeted market prices and only advance during active play.
- Active offers, contracts, events, timers, prices, allocations, and all lifetime totals survive save/load.

## Release validation

Run:

```sh
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/balance_harness.gd
godot --headless --path . --script res://tools/corporate_harness.gd
godot --headless --path . --script res://tools/research_harness.gd
godot --headless --path . --script res://tools/global_harness.gd
godot --headless --path . --quit-after 3
```

The global harness reaches grid and recycling level five, reallocates national supply, earns spot revenue, recovers materials, completes large-scale contracts, and experiences multiple global events.

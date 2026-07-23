# Milestone Five Acceptance

Milestone Five: Research and Challenges is complete as of v0.21.

## Research branches

- Research points generate continuously and scale with factories, department levels, and active managers.
- Materials Science lowers component-kit cost.
- Manufacturing Systems raises automated throughput.
- Market Intelligence raises demand across segments and products.
- Industrial Cybernetics raises threat detection.
- Each branch has five levels with escalating research costs.

## Equipment

- Precision Assemblers raise output and reduce energy use.
- Smart Warehouse Grids add storage.
- Laboratory Test Rigs add testing capacity.
- Threat Analysis Consoles improve detection.
- Market Analytics Clusters increase demand.
- Each equipment line has three levels, a research-branch prerequisite, and scaling cash/research costs.

## Long-term projects

- Solid-State Prototype permanently improves effective quality.
- Closed-Loop Materials Pilot permanently lowers material costs.
- Predictive Operations Rollout permanently raises garage output and reduces wear.
- Only one project can run at a time.
- Projects consume cash/research upfront, progress online and offline, and cannot be repeated after completion.

## Challenges

- Production Sprint tracks cells made.
- Revenue Drive tracks earned revenue.
- Incident-Free Window fails on security impact.
- Contract Delivery Streak tracks completed customer contracts.
- Challenges are opt-in, timed, mutually exclusive, and reward cash plus research.
- Challenge timers pause during offline progress.
- Completion history and failure totals persist.

## Persistence and balance

- Research currency, lifetime generation, branches, equipment, active/completed projects, active challenge, results, and completion history survive save/load.
- `tools/research_harness.gd` starts at the Milestone Five handoff and validates ten hours of autonomous progression.
- The harness reaches four level-five branches, five level-three equipment lines, all three projects, and all four challenge completions.

## Release validation

Run:

```sh
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/balance_harness.gd
godot --headless --path . --script res://tools/corporate_harness.gd
godot --headless --path . --script res://tools/research_harness.gd
```

The main scene must also start without parser or runtime errors.

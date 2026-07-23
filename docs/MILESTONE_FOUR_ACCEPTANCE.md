# Milestone Four Acceptance

Milestone Four: Corporate Management is complete as of v0.20.

## Multiple factories

- Three named satellite factories can be acquired.
- Each factory has three expansion levels.
- Factories add throughput and storage while increasing operating risk.
- Portfolio costs scale across acquisitions and expansions.

## Departments

- Operations improves satellite-factory output.
- Procurement reduces component-kit prices.
- Sales increases demand across customer segments and products.
- Corporate Security improves threat detection.
- Each department has three escalating investment levels.

## Managers

- Each department can receive one manager after its first investment.
- Managers improve department effectiveness and unlock relevant automation.
- Managers charge continuous wages and stop contributing when payroll is missed.
- Payroll recovery restores their effects and rules.

## Automation rules

- Procurement can automatically reorder kits to a configurable target while preserving a cash reserve.
- Operations can service garage machinery at 72% condition.
- Sales can pause advertising below the cash reserve.
- Sales can accept feasible contracts with positive unit economics.
- Rules require the corresponding manager and can be toggled independently.

## Supply contracts

- Local and Bulk agreements have distinct fees, durations, and discounts.
- Agreements reduce live kit prices, expire automatically, and cannot overlap.
- Contract counts and realized component savings are tracked.

## Detailed statistics

- Cash, revenue, cells made, cells sold, production, demand, and security risk are sampled every minute.
- The latest 120 samples persist through save/load.
- The Corporate workspace shows rolling revenue, output, sales, current posture, investment, and management costs.

## Persistence and balance

- Factories, department levels, managers, payroll state, automation configuration, supplier agreement, savings, costs, and statistics persist.
- `tools/corporate_harness.gd` starts at the Milestone Four handoff and validates two hours of autonomous corporate progression.
- The harness reaches three level-three factories, four level-three departments, four managers, recurring supply agreements, and 120 statistics samples.

## Release validation

Run:

```sh
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/balance_harness.gd
godot --headless --path . --script res://tools/corporate_harness.gd
```

The main scene must also start without parser or runtime errors.

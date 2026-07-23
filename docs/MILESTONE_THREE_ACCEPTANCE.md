# Milestone Three Acceptance

Milestone Three: Industrial Cybersecurity is complete as of v0.19.

## Network map

- The Security tab maps Internet Edge, Office Systems, Production, and Recovery Store assets.
- Public services, firewall, MFA, production controllers, backups, risk, and recovery posture update from live game state.

## Network zones

- The workshop progresses from one flat LAN to four named trust zones.
- Zone assignments are visible on mapped assets.

## Segmentation

- Three segmentation investments successively split Production, Recovery, and the public-edge DMZ.
- Segmentation lowers effective risk and reduces incident blast radius.

## Detection

- Three detection levels and active security analysts contribute to detection strength.
- Detected threats are recorded separately from impact incidents.

## Incident response

- Three response levels and active analysts contribute to response strength.
- Detected threats can be contained without impact.
- Detected but uncontained events receive response mitigation and remain visible in incident history.

## Recovery

- Recovery planning combines with the existing backup capability.
- Effective recovery reduces cash, inventory, and downtime severity.
- The Recovery Store node displays backup and recovery posture.

## Security staff

- Up to three analysts can be hired and released.
- Analysts improve both detection and response.
- Continuous wages are tracked in the ledger; missed payroll takes analysts off duty until payment resumes.

## Persistence and reporting

- Programme levels, staff state, wages, detected threats, containment, impact incidents, and the last incident survive save/load.
- The Incident Desk reports zone, outcome, detail, totals, and losses.
- The headless balance player invests in the programme and reports final cybersecurity posture.

## Release validation

Run:

```sh
godot --headless --path . --script res://tools/run_tests.gd
godot --headless --path . --script res://tools/balance_harness.gd
```

The main scene must also start without parser or runtime errors.

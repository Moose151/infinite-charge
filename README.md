# Infinite Charge

Infinite Charge is a desktop-first Godot idle-management game about growing a battery workshop into an increasingly unreasonable energy company.

## Current Build Target

The project is currently focused on the first garage-stage MVP:

- whole component kits (one per Standard Cell, two per Long-Life Cell)
- two battery-cell products with separate pricing and demand
- manual production
- adjustable sale price
- price-reactive demand
- automatic sales
- changing material price
- starter upgrades
- a garage-floor overview that changes with equipment, staff, storage, and security progression
- an Operations Watch strip for imminent stock, capacity, maintenance, payroll, downtime, and margin issues
- general, delivery, quality, and security reputation with qualified contract tiers
- basic security risk and security upgrades
- JSON save/load
- offline progress

## Project Layout

- `scenes/Main.tscn` - first playable screen
- `scripts/game_state.gd` - serializable game state
- `scripts/simulation.gd` - simulation tick and player actions
- `scripts/formulas.gd` - demand, risk, price, and formatting formulas
- `scripts/save_manager.gd` - JSON save/load
- `data/upgrades/garage_upgrades.json` - starter upgrade definitions
- `docs/MILESTONE_TWO_ACCEPTANCE.md` - completed Market Depth acceptance criteria and validation record
- `docs/MILESTONE_THREE_ACCEPTANCE.md` - completed Industrial Cybersecurity acceptance criteria and validation record

## Next Implementation Step

See `docs/HANDOVER.md` for project context and assistant handoff notes.

Open the project in Godot 4, run `scenes/Main.tscn`, and tune the first 10 minutes of play:

1. material purchase cost
2. manual production rate
3. starting sale price
4. demand curve
5. first automation upgrade cost

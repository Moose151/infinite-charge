# Milestone Six mature-company acceptance harness.
# Run: godot --headless --path . --script res://tools/global_harness.gd
extends SceneTree

var simulation: Simulation = Simulation.new()
var state: GameState = GameState.new()

func _init() -> void:
	simulation.rng.seed = 606
	state.prestige_level = 1
	state.legacy_points = 5
	state.lifetime_prestiges = 1
	state.cash = 10000000.0
	state.research_points = 100000.0
	state.production_per_second = 5.0
	state.raw_materials = 100000.0
	state.warehouse_capacity = 100000.0
	state.sale_price = 3.5
	for _level: int in range(5):
		assert(simulation.buy_grid_upgrade(state))
		assert(simulation.buy_recycling_upgrade(state))
	assert(simulation.adjust_national_market(state, "export", 20.0))

	var elapsed: float = 0.0
	var horizon: float = 4.0 * 60.0 * 60.0
	while elapsed < horizon:
		if not state.global_contract_offer.is_empty() and state.active_global_contract.is_empty():
			simulation.accept_global_contract(state)
		simulation.advance(state, 30.0, true)
		elapsed += 30.0

	assert(state.grid_level == 5)
	assert(state.recycling_level == 5)
	assert(state.lifetime_grid_revenue > 0.0)
	assert(state.lifetime_recycled_materials > 0.0)
	assert(state.lifetime_global_contracts_completed > 0)
	assert(state.lifetime_global_events > 0)
	var allocation_total: float = 0.0
	for value: Variant in state.national_market_allocations.values():
		allocation_total += float(value)
	assert(is_equal_approx(allocation_total, 100.0))
	print("Milestone Six harness passed: grid L%d, recycling L%d, $%s grid revenue, %d contracts, %d events, %s kits recovered." % [
		state.grid_level, state.recycling_level, Formulas.format_number(state.lifetime_grid_revenue),
		state.lifetime_global_contracts_completed, state.lifetime_global_events,
		Formulas.format_number(state.lifetime_recycled_materials)
	])
	quit()

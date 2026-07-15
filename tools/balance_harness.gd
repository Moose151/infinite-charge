# Headless balance harness. Simulates a simple player through the first hour
# and prints a progression timeline. Run from the project root with:
#   godot-4 --headless --path . --script res://tools/balance_harness.gd
extends SceneTree

const UPGRADE_PATH: String = "res://data/upgrades/garage_upgrades.json"
const TICK: float = 0.25
const CLICKS_PER_SECOND: float = 1.5
const REPORT_INTERVAL: float = 300.0
const RUN_SECONDS: float = 3600.0
const RNG_SEED: int = 1337

var upgrades: Array[Dictionary] = []

func _init() -> void:
	upgrades = _load_upgrades()
	for price: float in [2.0, 4.0, 6.0, 9.0]:
		_run_playthrough(price)
	quit()

func _run_playthrough(sale_price: float) -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = Simulation.new()
	simulation.rng.seed = RNG_SEED
	state.sale_price = sale_price

	var click_budget: float = 0.0
	var next_report: float = REPORT_INTERVAL
	var first_automation_at: float = -1.0
	var upgrades_bought: int = 0

	print("\n=== Playthrough at fixed price $%.2f ===" % sale_price)
	print("%6s | %10s | %9s | %9s | %8s | %8s | %s" % [
		"time", "cash", "made", "sold", "prod/s", "dem/s", "upgrades"
	])

	var elapsed: float = 0.0
	while elapsed < RUN_SECONDS:
		elapsed += TICK
		simulation.advance(state, TICK, true)

		# Click to keep a modest sales buffer; overproducing wastes materials.
		var inventory_cap: float = state.demand_per_second * 45.0 + 2.0
		click_budget += CLICKS_PER_SECOND * TICK
		while click_budget >= 1.0:
			click_budget -= 1.0
			if state.battery_cells < inventory_cap and state.raw_materials >= state.manual_output:
				simulation.manual_produce(state)

		# Material buffer sized to roughly a minute of actual throughput.
		var throughput: float = maxf(state.production_per_second, state.demand_per_second)
		var target_buffer: float = maxf(10.0, throughput * 60.0)
		if state.raw_materials < target_buffer * 0.5 and state.battery_cells < inventory_cap:
			var unit_cost: float = Formulas.material_unit_cost(state)
			var affordable: float = maxf(0.0, (state.cash - 10.0) / unit_cost)
			var batch: float = minf(target_buffer - state.raw_materials, affordable)
			if batch >= 1.0:
				simulation.buy_materials(state, batch)

		# Accept contracts the current production rate can plausibly meet.
		if not state.contract_offer.is_empty():
			var rate: float = Formulas.automated_throughput(state) + CLICKS_PER_SECOND * state.manual_output * 0.5
			var needed: float = float(state.contract_offer.get("quantity", 0.0)) - state.battery_cells
			var feasible: bool = needed <= rate * float(state.contract_offer.get("duration", 0.0)) * 0.8
			var worthwhile: bool = float(state.contract_offer.get("price_per_cell", 0.0)) >= state.sale_price
			if feasible and worthwhile:
				simulation.accept_contract(state)
			else:
				simulation.decline_contract(state)

		# Service machines before wear eats too much output.
		if state.machine_condition < 0.7 and state.cash >= Formulas.service_cost(state) + 20.0:
			simulation.service_machines(state)

		# Greedy: buy the cheapest affordable upgrade, keeping a cash reserve.
		var best: Dictionary = {}
		var best_cost: float = INF
		for definition: Dictionary in upgrades:
			var id: String = str(definition.get("id", ""))
			var level: int = int(state.upgrade_levels.get(id, 0))
			if level >= int(definition.get("max_level", 1)):
				continue
			# Play the bottleneck like a player reading the stage readout.
			if id == "workbench_automation" and state.production_per_second >= state.prep_rate:
				continue
			if id == "prep_station" and state.prep_rate >= state.production_per_second + 0.5:
				continue
			if id == "testing_bench" and state.testing_rate >= Formulas.automated_throughput(state):
				continue
			var cost: float = Formulas.upgrade_cost(definition, level)
			if cost < best_cost:
				best_cost = cost
				best = definition
		if not best.is_empty() and state.cash >= best_cost + 25.0:
			if simulation.buy_upgrade(state, best):
				upgrades_bought += 1
				if first_automation_at < 0.0 and state.production_per_second > 0.0:
					first_automation_at = elapsed

		if elapsed >= next_report:
			next_report += REPORT_INTERVAL
			print("%5.0fm | %10s | %9s | %9s | %8.2f | %8.2f | %d" % [
				elapsed / 60.0,
				Formulas.format_number(state.cash),
				Formulas.format_number(state.lifetime_cells_made),
				Formulas.format_number(state.lifetime_cells_sold),
				state.production_per_second,
				state.demand_per_second,
				upgrades_bought
			])

	var maxed: int = 0
	for definition: Dictionary in upgrades:
		var id: String = str(definition.get("id", ""))
		if int(state.upgrade_levels.get(id, 0)) >= int(definition.get("max_level", 1)):
			maxed += 1
	print("Summary: revenue $%s | security losses $%s | first automation at %.0fs | upgrades bought %d | maxed %d/%d | contracts %d done / %d missed ($%s)" % [
		Formulas.format_number(state.lifetime_revenue),
		Formulas.format_number(state.lifetime_security_losses),
		first_automation_at,
		upgrades_bought,
		maxed,
		upgrades.size(),
		state.lifetime_contracts_completed,
		state.lifetime_contracts_failed,
		Formulas.format_number(state.lifetime_contract_revenue)
	])

func _load_upgrades() -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(UPGRADE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load upgrade data.")
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var result: Array[Dictionary] = []
	if typeof(parsed) == TYPE_ARRAY:
		for item: Variant in parsed:
			if typeof(item) == TYPE_DICTIONARY:
				result.append(item)
	return result

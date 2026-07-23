# Headless balance harness. Simulates a simple player through the first hour
# and prints a progression timeline. Run from the project root with:
#   godot-4 --headless --path . --script res://tools/balance_harness.gd
extends SceneTree

const UPGRADE_PATH: String = "res://data/upgrades/garage_upgrades.json"
const TICK: float = 0.25
const EARLY_CLICKS_PER_SECOND: float = 1.5
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
	var first_approved_at: float = -1.0
	var first_assured_at: float = -1.0

	print("\n=== Playthrough at fixed price $%.2f ===" % sale_price)
	print("%6s | %10s | %9s | %9s | %8s | %8s | %s" % [
		"time", "cash", "made", "sold", "prod/min", "dem/min", "upgrades"
	])

	var elapsed: float = 0.0
	while elapsed < RUN_SECONDS:
		elapsed += TICK
		simulation.advance(state, TICK, true)

		# Click to keep a modest sales buffer; overproducing wastes materials.
		var inventory_cap: float = state.demand_per_second * 45.0 + 2.0
		var clicks_per_second: float = EARLY_CLICKS_PER_SECOND if elapsed <= 300.0 else (0.25 if elapsed <= 900.0 else 0.05)
		click_budget += clicks_per_second * TICK
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
			var offered_tier: String = str(state.contract_offer.get("tier", "Open Market"))
			if offered_tier == "Approved Supplier" and first_approved_at < 0.0:
				first_approved_at = elapsed
			if offered_tier == "Assured Supply" and first_assured_at < 0.0:
				first_assured_at = elapsed
			var rate: float = Formulas.automated_throughput(state) + clicks_per_second * state.manual_output * 0.5
			var needed: float = float(state.contract_offer.get("quantity", 0.0)) - state.battery_cells
			var feasible: bool = needed <= rate * float(state.contract_offer.get("duration", 0.0)) * 0.8
			var worthwhile: bool = float(state.contract_offer.get("price_per_cell", 0.0)) >= state.sale_price
			if feasible and worthwhile:
				simulation.accept_contract(state)
			else:
				simulation.decline_contract(state)

		# Hire toward the bottleneck stage once cash is comfortable.
		if state.cash >= 600.0 and not state.staff_striking:
			var staffed_prep: float = Formulas.staffed_prep_rate(state)
			var staffed_assembly: float = Formulas.staffed_assembly_rate(state)
			if staffed_prep < staffed_assembly and int(state.workers["prep"]) < Formulas.MAX_WORKERS_PER_ROLE:
				simulation.hire_worker(state, "prep")
			elif staffed_assembly <= staffed_prep and int(state.workers["assembly"]) < Formulas.MAX_WORKERS_PER_ROLE:
				simulation.hire_worker(state, "assembly")
			elif Formulas.testing_coverage(state) < 0.95 and int(state.workers["testing"]) < Formulas.MAX_WORKERS_PER_ROLE:
				simulation.hire_worker(state, "testing")

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
				state.production_per_second * 60.0,
				state.demand_per_second * 60.0,
				upgrades_bought
			])

	var maxed: int = 0
	for definition: Dictionary in upgrades:
		var id: String = str(definition.get("id", ""))
		if int(state.upgrade_levels.get(id, 0)) >= int(definition.get("max_level", 1)):
			maxed += 1
	var spot_revenue: float = state.lifetime_revenue - state.lifetime_contract_revenue
	var tracked_costs: float = state.lifetime_material_spend + state.lifetime_energy_cost + state.lifetime_wages_paid + state.lifetime_advertising_spend + state.lifetime_maintenance_spend + state.lifetime_hiring_spend + state.lifetime_upgrade_spend + state.lifetime_security_losses
	print("Summary: spot $%s + contracts $%s | costs $%s (kits %s, energy %s, wages %s, upgrades %s) | first automation %.0fs | upgrades %d | maxed %d/%d" % [
		Formulas.format_number(spot_revenue),
		Formulas.format_number(state.lifetime_contract_revenue),
		Formulas.format_number(tracked_costs),
		Formulas.format_number(state.lifetime_material_spend),
		Formulas.format_number(state.lifetime_energy_cost),
		Formulas.format_number(state.lifetime_wages_paid),
		Formulas.format_number(state.lifetime_upgrade_spend),
		first_automation_at,
		upgrades_bought,
		maxed,
		upgrades.size()
	])
	print("Reputation: G %.0f / D %.0f / Q %.0f / S %.0f | contracts O %d / A %d / S %d | first Approved %.0fs | first Assured %.0fs" % [
		float(state.reputation["general"]), float(state.reputation["delivery"]),
		float(state.reputation["quality"]), float(state.reputation["security"]),
		int(state.lifetime_contracts_by_tier["Open Market"]), int(state.lifetime_contracts_by_tier["Approved Supplier"]),
		int(state.lifetime_contracts_by_tier["Assured Supply"]), first_approved_at, first_assured_at
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

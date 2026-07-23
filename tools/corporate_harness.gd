# Headless corporate balance harness. Starts from a mature garage at the
# Milestone Four handoff and validates two hours of corporate expansion.
extends SceneTree

const TICK: float = 1.0
const RUN_SECONDS: float = 7200.0

func _init() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = Simulation.new()
	simulation.rng.seed = 404
	state.cash = 15000.0
	state.raw_materials = 10000.0
	state.sale_price = 6.0
	state.production_per_second = 2.0
	state.prep_rate = 3.0
	state.testing_rate = 3.0
	state.awareness = 3.0
	state.warehouse_capacity = 500.0
	state.network_segmentation_level = 2
	state.detection_level = 2
	state.incident_response_level = 2
	state.recovery_plan_level = 2

	print("=== Corporate management handoff: two-hour validation ===")
	var elapsed: float = 0.0
	var next_report: float = 900.0
	while elapsed < RUN_SECONDS:
		elapsed += TICK
		simulation.advance(state, TICK, true)

		if state.raw_materials < 500.0 and state.cash > 1000.0:
			simulation.buy_materials(state, mini(1000, floori((state.cash - 1000.0) / Formulas.material_unit_cost(state))))

		for department_id: String in ["operations", "procurement", "sales", "security"]:
			if int(state.department_levels[department_id]) < 3:
				var cost: float = simulation.department_cost(state, department_id)
				if state.cash >= cost + 2000.0:
					simulation.invest_department(state, department_id)
					break

		for department_id: String in ["operations", "procurement", "sales", "security"]:
			if int(state.department_levels[department_id]) > 0 and not bool(state.managers[department_id]) and state.cash >= Simulation.MANAGER_HIRING_FEE + 2000.0:
				simulation.hire_manager(state, department_id)
				break

		if bool(state.managers["procurement"]):
			simulation.set_automation_rule(state, "material_reorder", true)
		if bool(state.managers["operations"]):
			simulation.set_automation_rule(state, "preventive_service", true)
		if bool(state.managers["sales"]):
			simulation.set_automation_rule(state, "campaign_guardrail", true)
			simulation.set_automation_rule(state, "contract_review", true)

		if state.active_supply_contract.is_empty() and state.cash >= float(Simulation.SUPPLY_PLANS["bulk"]["fee"]) + 2000.0:
			simulation.sign_supply_contract(state, "bulk")

		if state.factories.size() < Simulation.FACTORY_NAMES.size():
			var factory_cost: float = simulation.next_factory_cost(state)
			if state.cash >= factory_cost + 3000.0:
				simulation.buy_factory(state)
		else:
			for index: int in range(state.factories.size()):
				if int(state.factories[index].get("level", 1)) < 3:
					var cost: float = simulation.factory_upgrade_cost(state, index)
					if state.cash >= cost + 3000.0:
						simulation.upgrade_factory(state, index)
						break

		if elapsed >= next_report:
			next_report += 900.0
			print("%3dm | cash $%s | factories %d | output %s/min | departments %s | managers %d | samples %d" % [
				roundi(elapsed / 60.0),
				Formulas.format_number(state.cash),
				state.factories.size(),
				Formulas.format_number(Formulas.automated_throughput(state) * 60.0),
				_department_summary(state),
				_manager_count(state),
				state.statistics_history.size(),
			])

	print("Summary: factories %d | levels %s | departments %s | managers %d | supply agreements %d | savings $%s | corporate investment $%s | history %d" % [
		state.factories.size(),
		_factory_summary(state),
		_department_summary(state),
		_manager_count(state),
		state.lifetime_supply_contracts,
		Formulas.format_number(state.lifetime_supply_savings),
		Formulas.format_number(state.lifetime_corporate_investment),
		state.statistics_history.size(),
	])
	quit()

func _department_summary(state: GameState) -> String:
	return "O%d/P%d/S%d/C%d" % [
		int(state.department_levels["operations"]),
		int(state.department_levels["procurement"]),
		int(state.department_levels["sales"]),
		int(state.department_levels["security"]),
	]

func _factory_summary(state: GameState) -> String:
	var levels: Array[String] = []
	for factory: Dictionary in state.factories:
		levels.append("L%d" % int(factory.get("level", 1)))
	return "/".join(levels)

func _manager_count(state: GameState) -> int:
	var count: int = 0
	for department_id: String in state.managers:
		if bool(state.managers[department_id]):
			count += 1
	return count

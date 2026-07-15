extends RefCounted
class_name Formulas

static func demand_per_second(state: GameState) -> float:
	var quality: float = effective_quality(state)
	var fair_price: float = maxf(0.25, state.base_value * quality)
	var price_ratio: float = state.sale_price / fair_price
	var price_factor: float = pow(price_ratio, -1.35)
	var trust_factor: float = 1.0 + state.trust * 0.35
	var security_penalty: float = clampf(effective_risk(state) * 0.55, 0.0, 0.45)
	var quality_factor: float = clampf(quality, 0.25, 4.0)
	return maxf(0.0, 0.7 * state.awareness * price_factor * quality_factor * trust_factor * (1.0 - security_penalty))

const WORKER_STAGE_RATE: float = 0.4
const WORKER_WAGE_PER_SECOND: float = 0.35
const WORKER_HIRING_FEE: float = 150.0
const MAX_WORKERS_PER_ROLE: int = 2

static func active_workers(state: GameState, role: String) -> int:
	if state.staff_striking:
		return 0
	return int(state.workers.get(role, 0))

static func staffed_prep_rate(state: GameState) -> float:
	return state.prep_rate + active_workers(state, "prep") * WORKER_STAGE_RATE

static func staffed_assembly_rate(state: GameState) -> float:
	return state.production_per_second * machine_efficiency(state) + active_workers(state, "assembly") * WORKER_STAGE_RATE

static func staffed_testing_rate(state: GameState) -> float:
	return state.testing_rate + active_workers(state, "testing") * WORKER_STAGE_RATE

static func automated_throughput(state: GameState) -> float:
	return minf(staffed_assembly_rate(state), staffed_prep_rate(state))

static func testing_coverage(state: GameState) -> float:
	var throughput: float = automated_throughput(state)
	if throughput <= 0.001:
		return 1.0
	return clampf(staffed_testing_rate(state) / throughput, 0.0, 1.0)

static func energy_cost_per_cell(state: GameState) -> float:
	return maxf(0.0, state.energy_price * (1.0 - clampf(state.energy_discount, 0.0, 0.8)))

static func total_workers(state: GameState) -> int:
	var count: int = 0
	for role: String in state.workers:
		count += int(state.workers[role])
	return count

static func effective_quality(state: GameState) -> float:
	var condition_factor: float = 0.8 + 0.2 * clampf(state.machine_condition, 0.0, 1.0)
	var testing_factor: float = 0.8 + 0.2 * testing_coverage(state)
	return state.quality * condition_factor * testing_factor

static func effective_risk(state: GameState) -> float:
	return clampf(state.risk - state.risk_reduction, 0.0, 1.0)

static func material_unit_cost(state: GameState) -> float:
	return maxf(0.05, state.material_price * (1.0 - clampf(state.material_discount, 0.0, 0.85)))

static func estimated_margin_per_cell(state: GameState) -> float:
	return state.sale_price - material_unit_cost(state)

static func sell_through_per_second(state: GameState) -> float:
	return minf(state.battery_cells, demand_per_second(state))

static func machine_efficiency(state: GameState) -> float:
	return 0.4 + 0.6 * clampf(state.machine_condition, 0.0, 1.0)

static func wear_per_cell(state: GameState) -> float:
	return 0.00025 * (1.0 - clampf(state.wear_reduction, 0.0, 0.8))

static func service_cost(state: GameState) -> float:
	return 25.0 + 60.0 * state.production_per_second * (1.0 - clampf(state.machine_condition, 0.0, 1.0))

static func warehouse_space(state: GameState) -> float:
	return maxf(0.0, state.warehouse_capacity - state.battery_cells)

static func upgrade_cost(definition: Dictionary, level: int) -> float:
	var base_cost: float = float(definition.get("base_cost", 1.0))
	var cost_scale: float = float(definition.get("cost_scale", 1.5))
	return ceilf(base_cost * pow(cost_scale, level))

static func format_number(value: float) -> String:
	if absf(value) >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if absf(value) >= 1000.0:
		return "%.2fk" % (value / 1000.0)
	if absf(value) >= 100.0:
		return "%.0f" % value
	return "%.2f" % value

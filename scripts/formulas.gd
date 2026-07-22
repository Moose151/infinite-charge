extends RefCounted
class_name Formulas

const CUSTOMER_SEGMENTS: Array[Dictionary] = [
	{
		"id": "households",
		"name": "Budget households",
		"share": 0.50,
		"price_sensitivity": 1.80,
		"quality_sensitivity": 0.55,
	},
	{
		"id": "businesses",
		"name": "Local businesses",
		"share": 0.35,
		"price_sensitivity": 1.20,
		"quality_sensitivity": 1.10,
	},
	{
		"id": "specialists",
		"name": "Specialist buyers",
		"share": 0.15,
		"price_sensitivity": 0.70,
		"quality_sensitivity": 1.80,
	},
]

const ADVERTISING_CHANNELS: Array[Dictionary] = [
	{
		"id": "neighbourhood_flyers",
		"name": "Neighbourhood Flyers",
		"cost_per_second": 0.18,
		"description": "Strong household reach; limited value to buyers with procurement departments.",
		"segment_boosts": {"households": 0.9, "businesses": 0.2, "specialists": 0.05},
	},
	{
		"id": "business_directory",
		"name": "Business Directory",
		"cost_per_second": 0.35,
		"description": "Targets local firms and reminds households that directories still exist.",
		"segment_boosts": {"households": 0.1, "businesses": 1.0, "specialists": 0.25},
	},
	{
		"id": "specialist_newsletter",
		"name": "Specialist Newsletter",
		"cost_per_second": 0.55,
		"description": "Expensive technical copy for buyers who read footnotes voluntarily.",
		"segment_boosts": {"households": 0.0, "businesses": 0.25, "specialists": 1.4},
	},
]

static func demand_per_second(state: GameState, product_id: String = "standard") -> float:
	var total: float = 0.0
	for segment: Dictionary in customer_segment_demand(state, product_id):
		total += float(segment["demand"])
	return total

static func customer_segment_demand(state: GameState, product_id: String = "standard") -> Array[Dictionary]:
	var is_premium: bool = product_id == "premium"
	var quality: float = effective_quality(state) * (1.25 if is_premium else 1.0)
	var sale_price: float = state.premium_sale_price if is_premium else state.sale_price
	var base_value: float = state.base_value * (1.75 if is_premium else 1.0)
	var price_ratio: float = maxf(0.05, sale_price / maxf(0.25, base_value))
	var trust_factor: float = 1.0 + state.trust * 0.35
	var security_penalty: float = clampf(effective_risk(state) * 0.55, 0.0, 0.45)
	var results: Array[Dictionary] = []
	for definition: Dictionary in CUSTOMER_SEGMENTS:
		var product_affinity: float = 1.0
		if is_premium:
			product_affinity = {"households": 0.35, "businesses": 0.65, "specialists": 1.8}.get(str(definition["id"]), 1.0)
		var channel_boost: float = advertising_boost_for_segment(state, str(definition["id"]))
		var price_factor: float = pow(price_ratio, -float(definition["price_sensitivity"]))
		var quality_factor: float = pow(clampf(quality, 0.25, 4.0), float(definition["quality_sensitivity"]))
		var demand: float = maxf(0.0, 0.7 * state.awareness * (1.0 + channel_boost) * float(definition["share"]) * product_affinity * price_factor * quality_factor * trust_factor * (1.0 - security_penalty))
		results.append({
			"id": definition["id"],
			"name": definition["name"],
			"demand": demand,
		})
	return results

static func advertising_boost_for_segment(state: GameState, segment_id: String) -> float:
	var boost: float = 0.0
	for channel: Dictionary in ADVERTISING_CHANNELS:
		var channel_id: String = str(channel["id"])
		if bool(state.advertising_channels.get(channel_id, false)):
			var boosts: Dictionary = channel["segment_boosts"]
			boost += float(boosts.get(segment_id, 0.0))
	return boost

static func advertising_cost_per_second(state: GameState) -> float:
	var cost: float = 0.0
	for channel: Dictionary in ADVERTISING_CHANNELS:
		if bool(state.advertising_channels.get(str(channel["id"]), false)):
			cost += float(channel["cost_per_second"])
	return cost

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
	return maxf(0.0, state.warehouse_capacity - state.battery_cells - state.premium_cells)

static func product_material_cost(product_id: String) -> float:
	return 1.5 if product_id == "premium" else 1.0

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

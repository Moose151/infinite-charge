# Headless test suite. Run from the project root with:
#   godot-4 --headless --path . --script res://tools/run_tests.gd
# Exits non-zero if any test fails.
extends SceneTree

var failures: int = 0
var checks: int = 0

func _init() -> void:
	_test_formulas()
	_test_customer_segments()
	_test_multiple_products()
	_test_advertising_channels()
	_test_competitors()
	_test_manual_production()
	_test_material_buying()
	_test_upgrades()
	_test_advance()
	_test_warehouse_capacity()
	_test_production_stages()
	_test_quality()
	_test_maintenance()
	_test_lost_sales()
	_test_chunked_advance()
	_test_downtime()
	_test_energy()
	_test_employees()
	_test_contracts()
	_test_offline_advance_has_no_security_events()
	_test_security_event_effects()
	_test_bankruptcy_rescue()
	_test_save_round_trip()
	print("\n%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: %s" % label)

func _make_sim() -> Simulation:
	var simulation: Simulation = Simulation.new()
	simulation.rng.seed = 42
	return simulation

func _test_formulas() -> void:
	var state: GameState = GameState.new()
	state.sale_price = 2.0
	var cheap_demand: float = Formulas.demand_per_second(state)
	state.sale_price = 8.0
	var pricey_demand: float = Formulas.demand_per_second(state)
	_check(cheap_demand > pricey_demand, "demand falls as price rises")
	_check(pricey_demand > 0.0, "demand stays positive")

	state.risk = 0.1
	state.risk_reduction = 0.5
	_check(is_equal_approx(Formulas.effective_risk(state), 0.0), "effective risk clamps at zero")

	state.material_price = 2.0
	state.material_discount = 0.25
	_check(is_equal_approx(Formulas.material_unit_cost(state), 1.5), "material discount applies")
	state.sale_price = 4.0
	state.energy_price = 0.1
	_check(is_equal_approx(Formulas.estimated_margin_per_cell(state), 2.4), "standard margin includes kit and energy")
	state.premium_sale_price = 8.0
	_check(is_equal_approx(Formulas.estimated_margin_per_cell(state, "premium"), 4.9), "premium margin includes two kits and energy")
	state.material_discount = 10.0
	_check(Formulas.material_unit_cost(state) >= 0.05, "material cost floors above zero")

	var definition: Dictionary = {"base_cost": 100.0, "cost_scale": 2.0}
	_check(is_equal_approx(Formulas.upgrade_cost(definition, 0), 100.0), "upgrade cost level 0")
	_check(is_equal_approx(Formulas.upgrade_cost(definition, 3), 800.0), "upgrade cost scales geometrically")

	_check(Formulas.format_number(1500000.0) == "1.50M", "format millions")
	_check(Formulas.format_number(2500.0) == "2.50k", "format thousands")
	_check(Formulas.format_number(3.14159) == "3.14", "format small numbers")

func _segment_demand(segments: Array[Dictionary], id: String) -> float:
	for segment: Dictionary in segments:
		if str(segment["id"]) == id:
			return float(segment["demand"])
	return 0.0

func _test_customer_segments() -> void:
	var state: GameState = GameState.new()
	state.sale_price = state.base_value
	var baseline: Array[Dictionary] = Formulas.customer_segment_demand(state)
	_check(baseline.size() == 3, "three customer segments contribute to demand")
	var summed: float = 0.0
	for segment: Dictionary in baseline:
		summed += float(segment["demand"])
	_check(is_equal_approx(summed, Formulas.demand_per_second(state)), "segment demand sums to total demand")

	state.sale_price = state.base_value * 2.0
	var expensive: Array[Dictionary] = Formulas.customer_segment_demand(state)
	var household_retention: float = _segment_demand(expensive, "households") / _segment_demand(baseline, "households")
	var specialist_retention: float = _segment_demand(expensive, "specialists") / _segment_demand(baseline, "specialists")
	_check(specialist_retention > household_retention, "specialists tolerate high prices better than households")

	state.sale_price = state.base_value
	state.quality = 1.5
	var high_quality: Array[Dictionary] = Formulas.customer_segment_demand(state)
	var household_quality_gain: float = _segment_demand(high_quality, "households") / _segment_demand(baseline, "households")
	var specialist_quality_gain: float = _segment_demand(high_quality, "specialists") / _segment_demand(baseline, "specialists")
	_check(specialist_quality_gain > household_quality_gain, "specialists respond more strongly to quality")

	state.quality = 1.0
	state.reputation["general"] = 80.0
	var reputable_demand: float = Formulas.demand_per_second(state)
	state.reputation["general"] = 20.0
	_check(reputable_demand > Formulas.demand_per_second(state), "general reputation affects customer demand")

func _test_multiple_products() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = Simulation.PREMIUM_PRODUCT_UNLOCK_COST
	_check(simulation.unlock_premium_product(state), "premium product can be unlocked")
	_check(state.premium_product_unlocked, "premium unlock stored")
	_check(state.active_product == "premium", "new product becomes active")
	_check(is_equal_approx(state.cash, 0.0), "premium design charges unlock cost")

	state.manual_output = 2.0
	state.raw_materials = 4.0
	_check(simulation.manual_produce(state), "premium cells can be produced manually")
	_check(is_equal_approx(state.premium_cells, 2.0), "premium stock is separate")
	_check(is_equal_approx(state.raw_materials, 0.0), "premium cells consume extra material")
	_check(is_equal_approx(Formulas.warehouse_space(state), state.warehouse_capacity - 2.0), "products share warehouse space")

	state.premium_sale_price = 2.0
	state.cash = 0.0
	simulation.advance(state, 1.0, false)
	_check(state.premium_cells < 2.0, "premium inventory sells automatically")
	_check(state.cash > 0.0, "premium sales earn revenue")
	_check(state.sales_per_second > 0.0, "sales rate includes premium sales")

	state.premium_sale_price = 8.0
	var premium_segments: Array[Dictionary] = Formulas.customer_segment_demand(state, "premium")
	_check(_segment_demand(premium_segments, "specialists") > _segment_demand(premium_segments, "households"), "premium cells skew toward specialists")
	state.competitor_price = 2.5
	state.competitor_quality = 1.3
	var premium_under_pressure: float = Formulas.demand_per_second(state, "premium")
	state.competitor_price = 8.0
	state.competitor_quality = 0.8
	_check(Formulas.demand_per_second(state, "premium") > premium_under_pressure, "premium demand responds to competitor value")
	_check(simulation.select_product(state, "standard"), "production can switch back to standard")

func _test_advertising_channels() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	var baseline: Array[Dictionary] = Formulas.customer_segment_demand(state)
	_check(simulation.set_advertising_channel(state, "neighbourhood_flyers", true), "advertising channel can launch")
	var advertised: Array[Dictionary] = Formulas.customer_segment_demand(state)
	var household_gain: float = _segment_demand(advertised, "households") / _segment_demand(baseline, "households")
	var specialist_gain: float = _segment_demand(advertised, "specialists") / _segment_demand(baseline, "specialists")
	_check(household_gain > specialist_gain, "flyers favour household demand")
	_check(is_equal_approx(Formulas.advertising_cost_per_second(state), 0.03), "active channel reports running cost")

	state.cash = 10.0
	var report: Dictionary = simulation.advance(state, 10.0, false)
	_check(is_equal_approx(float(report["advertising_cost"]), 0.3), "advertising spend charged during advance")
	_check(is_equal_approx(state.lifetime_advertising_spend, 0.3), "advertising spend tracked")
	state.cash = 0.0
	simulation.advance(state, 1.0, false)
	_check(not bool(state.advertising_channels["neighbourhood_flyers"]), "unaffordable campaigns pause")
	_check(not simulation.set_advertising_channel(state, "not_a_channel", true), "unknown advertising channel rejected")

	var business_state: GameState = GameState.new()
	var business_baseline: Array[Dictionary] = Formulas.customer_segment_demand(business_state)
	simulation.set_advertising_channel(business_state, "business_directory", true)
	var business_advertised: Array[Dictionary] = Formulas.customer_segment_demand(business_state)
	var business_gain: float = _segment_demand(business_advertised, "businesses") / _segment_demand(business_baseline, "businesses")
	var business_household_gain: float = _segment_demand(business_advertised, "households") / _segment_demand(business_baseline, "households")
	_check(business_gain > business_household_gain, "business directory favours local businesses")

	var specialist_state: GameState = GameState.new()
	var specialist_baseline: Array[Dictionary] = Formulas.customer_segment_demand(specialist_state)
	simulation.set_advertising_channel(specialist_state, "specialist_newsletter", true)
	var specialist_advertised: Array[Dictionary] = Formulas.customer_segment_demand(specialist_state)
	var newsletter_gain: float = _segment_demand(specialist_advertised, "specialists") / _segment_demand(specialist_baseline, "specialists")
	var newsletter_household_gain: float = _segment_demand(specialist_advertised, "households") / _segment_demand(specialist_baseline, "households")
	_check(newsletter_gain > newsletter_household_gain, "specialist newsletter favours specialist buyers")

func _test_competitors() -> void:
	var state: GameState = GameState.new()
	state.competitor_price = 8.0
	state.competitor_quality = 0.8
	var weak_competitor_demand: float = Formulas.demand_per_second(state)
	state.competitor_price = 2.5
	state.competitor_quality = 1.3
	var strong_competitor_demand: float = Formulas.demand_per_second(state)
	_check(weak_competitor_demand > strong_competitor_demand, "strong competitor reduces player demand")
	_check(Formulas.competitor_demand_factor(state, "standard", 1.8) < Formulas.competitor_demand_factor(state, "standard", 0.7), "price-sensitive segments react more to strong competition")

	var simulation: Simulation = _make_sim()
	state.awareness = 0.0
	state.competitor_price = 5.0
	state.competitor_market_timer = Simulation.COMPETITOR_MARKET_PERIOD - 1.0
	var old_price: float = state.competitor_price
	var report: Dictionary = simulation.advance(state, 2.0, true)
	_check(int(report["competitor_events"]) == 1, "competitor market updates on schedule")
	_check(not is_equal_approx(state.competitor_price, old_price), "competitor price drifts")
	_check(not state.event_log.is_empty() and state.event_log[0].contains(state.competitor_name), "competitor move reaches company log")

func _test_manual_production() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 5.0
	state.manual_output = 2.0
	_check(simulation.manual_produce(state), "manual produce succeeds with materials")
	_check(is_equal_approx(state.raw_materials, 3.0), "manual produce consumes materials")
	_check(is_equal_approx(state.battery_cells, 2.0), "manual produce yields cells")
	state.raw_materials = 1.0
	_check(not simulation.manual_produce(state), "manual produce fails without enough materials")

func _test_material_buying() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 100.0
	state.material_price = 2.0
	state.material_discount = 0.0
	state.raw_materials = 0.0
	_check(simulation.buy_materials(state, 10.0), "buying materials succeeds with cash")
	_check(is_equal_approx(state.cash, 80.0), "buying materials deducts cash")
	_check(is_equal_approx(state.raw_materials, 10.0), "buying materials adds stock")
	_check(is_equal_approx(state.lifetime_material_spend, 20.0), "component-kit spend tracked")
	state.cash = 1.0
	_check(not simulation.buy_materials(state, 10.0), "buying materials fails when broke")
	_check(is_equal_approx(state.raw_materials, 10.0), "failed purchase leaves stock unchanged")

func _test_upgrades() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	var definition: Dictionary = {
		"id": "test_upgrade",
		"name": "Test Upgrade",
		"base_cost": 50.0,
		"cost_scale": 2.0,
		"max_level": 2,
		"effects": {"production_per_second_add": 0.5, "risk_add": 0.01}
	}
	state.cash = 200.0
	_check(simulation.buy_upgrade(state, definition), "upgrade purchase succeeds")
	_check(is_equal_approx(state.cash, 150.0), "upgrade deducts cost")
	_check(is_equal_approx(state.lifetime_upgrade_spend, 50.0), "upgrade spend tracked")
	_check(is_equal_approx(state.production_per_second, 0.5), "upgrade applies production effect")
	_check(is_equal_approx(state.risk, 0.07), "upgrade applies risk effect")
	_check(simulation.buy_upgrade(state, definition), "second level purchase succeeds")
	_check(not simulation.buy_upgrade(state, definition), "purchase fails at max level")
	state.cash = 1.0
	var cheap: Dictionary = definition.duplicate()
	cheap["id"] = "other"
	_check(not simulation.buy_upgrade(state, cheap), "purchase fails without cash")

func _test_advance() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 100.0
	state.raw_materials = 100.0
	state.battery_cells = 30.0
	state.warehouse_capacity = 200.0
	state.production_per_second = 2.0
	state.prep_rate = 100.0
	state.sale_price = 4.0
	var report: Dictionary = simulation.advance(state, 2.0, false)
	_check(float(report["cells_made"]) > 0.0, "advance produces automatically")
	_check(is_equal_approx(state.raw_materials, 96.0), "advance consumes whole component kits")
	_check(float(report["cells_sold"]) > 0.0, "advance sells cells")
	_check(state.cash > 0.0, "advance earns revenue")
	_check(is_equal_approx(float(report["revenue"]), float(report["cells_sold"]) * 4.0), "revenue matches sales")

func _test_warehouse_capacity() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 100.0
	state.battery_cells = 59.0
	state.warehouse_capacity = 60.0
	state.production_per_second = 10.0
	state.prep_rate = 100.0
	state.awareness = 0.0
	state.cash = 100.0
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.battery_cells, 60.0), "automation stops at warehouse capacity")
	_check(is_equal_approx(state.raw_materials, 99.0), "materials not consumed past capacity")

	state.manual_output = 2.0
	_check(not simulation.manual_produce(state), "manual production blocked at capacity")

	var upgraded: GameState = GameState.new()
	simulation.buy_upgrade(upgraded, {"id": "shelves", "base_cost": 0.0, "max_level": 1, "effects": {"warehouse_capacity_add": 60.0}})
	_check(is_equal_approx(upgraded.warehouse_capacity, 120.0), "shelving upgrade raises capacity")

func _test_production_stages() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 100.0
	state.warehouse_capacity = 1000.0
	state.production_per_second = 5.0
	state.prep_rate = 1.0
	state.awareness = 0.0
	var report: Dictionary = simulation.advance(state, 1.0, false)
	_check(is_equal_approx(float(report["cells_made"]), 1.0), "prep stage bottlenecks assembly")

	var assembly_limited: GameState = GameState.new()
	assembly_limited.raw_materials = 100.0
	assembly_limited.warehouse_capacity = 1000.0
	assembly_limited.production_per_second = 5.0
	assembly_limited.prep_rate = 10.0
	assembly_limited.awareness = 0.0
	assembly_limited.cash = 100.0
	report = simulation.advance(assembly_limited, 1.0, false)
	_check(is_equal_approx(float(report["cells_made"]), 5.0), "assembly limits when prep is fast")

	var upgraded: GameState = GameState.new()
	simulation.buy_upgrade(upgraded, {"id": "prep", "base_cost": 0.0, "max_level": 1, "effects": {"prep_rate_add": 0.45, "testing_rate_add": 0.45}})
	_check(is_equal_approx(upgraded.prep_rate, 1.25), "prep upgrade raises prep rate")
	_check(is_equal_approx(upgraded.testing_rate, 0.95), "testing upgrade raises testing rate")

func _test_quality() -> void:
	var state: GameState = GameState.new()
	_check(is_equal_approx(Formulas.effective_quality(state), state.quality), "quality unchanged with no automation")

	state.production_per_second = 2.0
	state.prep_rate = 2.0
	state.testing_rate = 1.0
	_check(is_equal_approx(Formulas.testing_coverage(state), 0.5), "testing coverage is testing rate over throughput")
	_check(is_equal_approx(Formulas.effective_quality(state), state.quality * 0.9), "untested output lowers quality")

	state.testing_rate = 5.0
	_check(is_equal_approx(Formulas.testing_coverage(state), 1.0), "coverage caps at 100%")

	state.machine_condition = 0.0
	var worn_quality: float = Formulas.effective_quality(state)
	_check(worn_quality < state.quality, "worn machines lower quality")

	var healthy: GameState = GameState.new()
	healthy.sale_price = 4.0
	var neglected: GameState = GameState.new()
	neglected.sale_price = 4.0
	neglected.production_per_second = 5.0
	neglected.prep_rate = 5.0
	neglected.testing_rate = 0.0
	neglected.machine_condition = 0.0
	_check(Formulas.demand_per_second(neglected) < Formulas.demand_per_second(healthy), "poor quality reduces demand")

func _test_maintenance() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 10000.0
	state.warehouse_capacity = 100000.0
	state.production_per_second = 10.0
	state.prep_rate = 100.0
	state.awareness = 0.0
	state.cash = 1000.0
	simulation.advance(state, 60.0, false)
	_check(state.machine_condition < 1.0, "automated production wears machines")

	state.machine_condition = 0.0
	var worn_report: Dictionary = simulation.advance(state, 1.0, false)
	_check(is_equal_approx(float(worn_report["cells_made"]), 4.0), "worn machines run at 40% efficiency")

	state.cash = 1000.0
	_check(simulation.service_machines(state), "servicing succeeds with cash")
	_check(is_equal_approx(state.machine_condition, 1.0), "servicing restores condition")
	_check(state.cash < 1000.0, "servicing costs cash")
	_check(state.lifetime_maintenance_spend > 0.0, "maintenance spend tracked")
	_check(not simulation.service_machines(state), "servicing refused when not needed")

	state.machine_condition = 0.5
	state.cash = 0.0
	_check(not simulation.service_machines(state), "servicing refused when broke")

	state.wear_reduction = 0.8
	var reduced_wear: float = Formulas.wear_per_cell(state)
	state.wear_reduction = 0.0
	_check(reduced_wear < Formulas.wear_per_cell(state), "wear reduction lowers wear")

	var estimates: GameState = GameState.new()
	estimates.production_per_second = 2.0
	estimates.prep_rate = 2.0
	estimates.raw_materials = 20.0
	estimates.awareness = 0.0
	estimates.machine_condition = 1.0
	_check(is_equal_approx(Formulas.material_runway_seconds(estimates), 10.0), "material runway uses current kit draw")
	_check(is_equal_approx(Formulas.warehouse_fill_seconds(estimates), 30.0), "warehouse fill estimate uses net production")
	_check(is_equal_approx(Formulas.service_due_seconds(estimates), 600.0), "service estimate uses throughput and wear")
	estimates.battery_cells = estimates.warehouse_capacity
	_check(is_equal_approx(Formulas.warehouse_fill_seconds(estimates), 0.0), "full warehouse reports immediate saturation")
	estimates.battery_cells = 10.0
	estimates.production_per_second = 0.0
	estimates.awareness = 1.0
	_check(is_finite(Formulas.inventory_runway_seconds(estimates)), "inventory runway appears when demand exceeds output")
	estimates.battery_cells = 0.0
	_check(is_equal_approx(Formulas.inventory_runway_seconds(estimates), 0.0), "empty inventory reports immediate stockout")

func _test_lost_sales() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.battery_cells = 0.0
	state.raw_materials = 0.0
	state.cash = 100.0
	simulation.advance(state, 10.0, false)
	_check(state.lifetime_sales_lost > 0.0, "stock-outs recorded as lost sales")

func _test_chunked_advance() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 100000.0
	state.warehouse_capacity = 60.0
	state.production_per_second = 5.0
	state.prep_rate = 100.0
	state.sale_price = 1.0
	state.awareness = 5.0
	var report: Dictionary = simulation.advance_chunked(state, 3600.0, false)
	_check(float(report["cells_sold"]) > state.warehouse_capacity * 2.0, "chunked offline sales exceed warehouse capacity")
	_check(is_equal_approx(float(report["seconds"]), 3600.0), "chunked report tracks duration")

func _test_downtime() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 100.0
	state.production_per_second = 2.0
	state.prep_rate = 100.0
	state.production_downtime = 10.0
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.raw_materials, 100.0), "downtime halts automated production")
	_check(is_equal_approx(state.production_downtime, 9.0), "downtime ticks down")
	state.production_downtime = 0.5
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.raw_materials, 99.0), "partial downtime allows partial production")

func _test_energy() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 100.0
	state.raw_materials = 100.0
	state.warehouse_capacity = 1000.0
	state.production_per_second = 2.0
	state.prep_rate = 100.0
	state.energy_price = 0.1
	state.awareness = 0.0
	var report: Dictionary = simulation.advance(state, 1.0, false)
	_check(is_equal_approx(float(report["energy_cost"]), 0.2), "automation is billed for energy per cell")
	_check(is_equal_approx(state.cash, 99.8), "energy cost deducted from cash")
	_check(is_equal_approx(state.lifetime_energy_cost, 0.2), "energy spend recorded")

	state.energy_discount = 0.5
	_check(is_equal_approx(Formulas.energy_cost_per_cell(state), 0.05), "energy discount lowers cost per cell")

	var broke: GameState = GameState.new()
	broke.cash = 0.0
	broke.raw_materials = 100.0
	broke.production_per_second = 2.0
	broke.prep_rate = 100.0
	broke.awareness = 0.0
	report = simulation.advance(broke, 1.0, false)
	_check(is_equal_approx(float(report["cells_made"]), 0.0), "automation cannot produce without energy money")
	_check(is_equal_approx(broke.raw_materials, 100.0), "unfunded automation does not consume kits")

func _test_employees() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 1000.0
	state.raw_materials = 100.0
	state.warehouse_capacity = 1000.0
	state.awareness = 0.0

	_check(simulation.hire_worker(state, "prep"), "hiring succeeds with cash")
	_check(is_equal_approx(state.cash, 850.0), "hiring fee charged")
	_check(is_equal_approx(state.lifetime_hiring_spend, 150.0), "hiring spend tracked")
	simulation.hire_worker(state, "prep")
	_check(not simulation.hire_worker(state, "prep"), "role capped at max workers")
	_check(is_equal_approx(Formulas.staffed_prep_rate(state), 1.6), "prep workers raise prep rate")

	simulation.hire_worker(state, "assembly")
	_check(is_equal_approx(Formulas.staffed_assembly_rate(state), 0.4), "assembly worker produces without machines")
	var report: Dictionary = simulation.advance(state, 1.0, false)
	_check(is_equal_approx(float(report["cells_made"]), 0.0), "partial staff production waits for a complete cell")
	report = simulation.advance(state, 2.0, false)
	_check(is_equal_approx(float(report["cells_made"]), 1.0), "staffed assembly completes whole cells over time")
	_check(is_equal_approx(state.lifetime_wages_paid, 0.54), "wages paid continuously while cells accumulate")

	state.cash = 0.0
	simulation.advance(state, 1.0, false)
	_check(state.staff_striking, "unpaid staff strike")
	_check(is_equal_approx(Formulas.automated_throughput(state), 0.0), "striking staff stop producing")

	state.cash = 100.0
	simulation.advance(state, 1.0, false)
	_check(not state.staff_striking, "payroll recovery ends strike")

	_check(simulation.fire_worker(state, "assembly"), "firing reduces headcount")
	_check(not simulation.fire_worker(state, "assembly"), "cannot fire from empty role")
	_check(not simulation.hire_worker(state, "manager"), "unknown role rejected")

func _test_contracts() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()

	_check(not simulation.accept_contract(state), "accept fails with no offer")

	state.contract_offer = {"buyer": "a test client", "quantity": 10.0, "price_per_cell": 5.0, "duration": 30.0, "expires_in": 60.0}
	_check(simulation.decline_contract(state), "decline clears offer")
	_check(state.contract_offer.is_empty(), "offer removed after decline")

	state.contract_offer = {"buyer": "a test client", "quantity": 10.0, "price_per_cell": 5.0, "duration": 30.0, "expires_in": 60.0}
	_check(simulation.accept_contract(state), "accept converts offer to contract")
	_check(is_equal_approx(float(state.active_contract["value"]), 50.0), "contract value is quantity times price")

	state.battery_cells = 4.0
	state.awareness = 0.0
	state.cash = 0.0
	simulation.advance(state, 1.0, true)
	_check(is_equal_approx(state.battery_cells, 0.0), "contract delivery consumes inventory")
	_check(is_equal_approx(float(state.active_contract["remaining"]), 6.0), "partial delivery tracked")
	_check(is_equal_approx(state.cash, 0.0), "no payment until completion")

	state.battery_cells = 6.0
	var trust_before: float = state.trust
	var delivery_before: float = float(state.reputation["delivery"])
	simulation.advance(state, 1.0, true)
	_check(state.active_contract.is_empty(), "contract completes when fulfilled")
	_check(state.cash >= 50.0, "completion pays full value")
	_check(state.trust > trust_before, "completion builds trust")
	_check(float(state.reputation["delivery"]) > delivery_before, "completion builds delivery reputation")
	_check(state.lifetime_contracts_completed == 1, "completion counted")
	_check(int(state.lifetime_contracts_by_tier["Open Market"]) == 1, "completion counted by contract tier")

	state.contract_offer = {"buyer": "a test client", "quantity": 10.0, "price_per_cell": 5.0, "duration": 5.0, "expires_in": 60.0}
	simulation.accept_contract(state)
	state.battery_cells = 0.0
	state.cash = 100.0
	trust_before = state.trust
	simulation.advance(state, 6.0, true)
	_check(state.active_contract.is_empty(), "contract fails past deadline")
	_check(state.cash < 100.0, "failure charges penalty")
	_check(state.trust < trust_before, "failure costs trust")
	_check(float(state.reputation["delivery"]) < delivery_before, "failure costs delivery reputation")
	_check(state.lifetime_contracts_failed == 1, "failure counted")

	state.reputation = {"general": 54.0, "delivery": 70.0, "quality": 70.0, "security": 70.0}
	_check(str(simulation.next_contract_tier(state).get("name", "")) == "Approved Supplier", "next contract tier identifies first unmet qualification")
	var open_offer: Dictionary = simulation._generate_contract_offer(state)
	_check(str(open_offer.get("tier", "")) == "Open Market", "contract tier respects general reputation requirement")
	state.reputation["general"] = 70.0
	_check(simulation.next_contract_tier(state).is_empty(), "all contract tiers qualify at high reputation")
	var assured_offer: Dictionary = simulation._generate_contract_offer(state)
	_check(str(assured_offer.get("tier", "")) == "Assured Supply", "high reputation unlocks assured contracts")
	var open_state: GameState = GameState.new()
	simulation.rng.seed = 99
	var baseline_offer: Dictionary = simulation._generate_contract_offer(open_state)
	simulation.rng.seed = 99
	var premium_offer: Dictionary = simulation._generate_contract_offer(state)
	_check(float(premium_offer["quantity"]) > float(baseline_offer["quantity"]), "higher contract tiers offer larger orders")
	_check(float(premium_offer["price_per_cell"]) > float(baseline_offer["price_per_cell"]), "higher contract tiers offer better pricing")
	state.contract_offer = assured_offer
	state.reputation["security"] = 0.0
	_check(not simulation.accept_contract(state), "offer acceptance rechecks reputation requirements")
	state.contract_offer = {}

	state.contract_offer = {"buyer": "a test client", "quantity": 10.0, "price_per_cell": 5.0, "duration": 30.0, "expires_in": 2.0}
	simulation.advance(state, 3.0, true)
	_check(state.contract_offer.is_empty(), "unanswered offer expires")

	var paused: GameState = GameState.new()
	paused.contract_offer = {"buyer": "a test client", "quantity": 10.0, "price_per_cell": 5.0, "duration": 30.0, "expires_in": 10.0}
	simulation.advance(paused, 60.0, false)
	_check(not paused.contract_offer.is_empty(), "contracts pause during offline advance")

func _test_offline_advance_has_no_security_events() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 1000.0
	state.raw_materials = 10000.0
	state.risk = 1.0
	var report: Dictionary = simulation.advance(state, 3600.0, false)
	_check(int(report["security_events"]) == 0, "offline advance skips security events")
	_check(is_equal_approx(float(state.reputation["security"]), 50.0), "offline advance does not alter security reputation")

func _test_security_event_effects() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	var report: Dictionary = {"security_losses": 0.0, "security_events": 0}

	state.cash = 100.0
	simulation._trigger_security_event(state, {"type": "cash", "severity_min": 0.1, "severity_max": 0.1}, report)
	_check(float(state.reputation["security"]) < 50.0, "security incidents damage security reputation")
	_check(is_equal_approx(state.cash, 90.0), "cash event takes cash")
	_check(is_equal_approx(state.lifetime_security_losses, 10.0), "cash loss recorded")

	state.battery_cells = 50.0
	simulation._trigger_security_event(state, {"type": "inventory", "severity_min": 0.2, "severity_max": 0.2}, report)
	_check(is_equal_approx(state.battery_cells, 40.0), "inventory event destroys stock")

	simulation._trigger_security_event(state, {"type": "downtime", "severity_min": 30.0, "severity_max": 30.0}, report)
	_check(is_equal_approx(state.production_downtime, 30.0), "downtime event stops automation")

	state.recovery = 0.5
	state.cash = 100.0
	simulation._trigger_security_event(state, {"type": "cash", "severity_min": 0.1, "severity_max": 0.1}, report)
	_check(is_equal_approx(state.cash, 95.0), "recovery halves losses")
	_check(int(report["security_events"]) == 4, "events counted in report")

	var clean_state: GameState = GameState.new()
	var clean_simulation: Simulation = _make_sim()
	clean_simulation.security_event_period = 1.0
	clean_simulation.security_base_chance = 0.0
	clean_simulation.security_risk_chance_scale = 0.0
	var clean_report: Dictionary = {"security_losses": 0.0, "security_events": 0}
	clean_simulation._update_security_events(clean_state, 1.0, true, clean_report)
	_check(float(clean_state.reputation["security"]) > 50.0, "incident-free security periods build reputation")

func _test_bankruptcy_rescue() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 0.5
	state.raw_materials = 0.0
	state.battery_cells = 0.0
	state.production_per_second = 0.0
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.cash, 25.0), "bankruptcy rescue grants cash")
	state.cash = 0.5
	state.raw_materials = 20.0
	simulation.advance(state, 1.0, false)
	_check(state.cash < 5.0, "rescue withheld while materials remain")

func _test_save_round_trip() -> void:
	var state: GameState = GameState.new()
	state.cash = 123.45
	state.raw_materials = 67.0
	state.battery_cells = 8.0
	state.sale_price = 5.5
	state.premium_cells = 12.0
	state.premium_sale_price = 9.5
	state.premium_product_unlocked = true
	state.active_product = "premium"
	state.production_progress = {"standard": 0.25, "premium": 0.75}
	state.sales_progress = {"standard": 0.4, "premium": 0.6}
	state.manual_output = 3.0
	state.production_per_second = 1.25
	state.production_downtime = 4.0
	state.ui_scale = 1.5
	state.ui_theme_id = "solar"
	state.ui_dark_mode = false
	state.warehouse_capacity = 240.0
	state.prep_rate = 1.7
	state.testing_rate = 1.4
	state.machine_condition = 0.75
	state.wear_reduction = 0.2
	state.lifetime_sales_lost = 42.0
	state.active_contract = {"buyer": "a test client", "quantity": 10.0, "remaining": 3.0, "price_per_cell": 5.0, "value": 50.0, "time_remaining": 20.0}
	state.lifetime_contracts_completed = 7
	state.energy_price = 0.22
	state.energy_discount = 0.24
	state.workers = {"prep": 1, "assembly": 2, "testing": 0}
	state.lifetime_energy_cost = 55.0
	state.lifetime_wages_paid = 66.0
	state.lifetime_material_spend = 101.0
	state.lifetime_upgrade_spend = 202.0
	state.lifetime_maintenance_spend = 303.0
	state.lifetime_hiring_spend = 404.0
	state.reputation = {"general": 61.0, "delivery": 72.0, "quality": 83.0, "security": 94.0}
	state.lifetime_contracts_by_tier = {"Open Market": 4, "Approved Supplier": 2, "Assured Supply": 1}
	state.advertising_channels["business_directory"] = true
	state.lifetime_advertising_spend = 77.0
	state.competitor_name = "Test Power Ltd"
	state.competitor_price = 6.25
	state.competitor_quality = 1.2
	state.competitor_market_timer = 12.0
	state.upgrade_levels = {"better_tools": 2}
	state.lifetime_revenue = 999.0
	state.add_event("Round trip initiated.")

	var json_text: String = JSON.stringify(state.to_save_data())
	var parsed: Variant = JSON.parse_string(json_text)
	_check(typeof(parsed) == TYPE_DICTIONARY, "save data survives JSON round trip")

	var loaded: GameState = GameState.new()
	loaded.load_save_data(parsed)
	_check(is_equal_approx(loaded.cash, 123.45), "cash restored")
	_check(is_equal_approx(loaded.raw_materials, 67.0), "materials restored")
	_check(is_equal_approx(loaded.sale_price, 5.5), "price restored")
	_check(is_equal_approx(loaded.premium_cells, 12.0), "premium inventory restored")
	_check(is_equal_approx(loaded.premium_sale_price, 9.5), "premium price restored")
	_check(loaded.premium_product_unlocked and loaded.active_product == "premium", "premium product state restored")
	_check(is_equal_approx(float(loaded.production_progress["premium"]), 0.75), "production progress restored")
	_check(is_equal_approx(float(loaded.sales_progress["standard"]), 0.4), "sales progress restored")
	_check(is_equal_approx(loaded.production_downtime, 4.0), "downtime restored")
	_check(is_equal_approx(loaded.ui_scale, 1.5), "ui scale restored")
	_check(loaded.ui_theme_id == "solar", "colour scheme restored")
	_check(not loaded.ui_dark_mode, "light mode restored")
	_check(is_equal_approx(loaded.warehouse_capacity, 240.0), "warehouse capacity restored")
	_check(is_equal_approx(loaded.prep_rate, 1.7), "prep rate restored")
	_check(is_equal_approx(loaded.testing_rate, 1.4), "testing rate restored")
	_check(is_equal_approx(loaded.machine_condition, 0.75), "machine condition restored")
	_check(is_equal_approx(loaded.wear_reduction, 0.2), "wear reduction restored")
	_check(is_equal_approx(loaded.lifetime_sales_lost, 42.0), "lost sales restored")
	_check(is_equal_approx(float(loaded.active_contract.get("remaining", 0.0)), 3.0), "active contract restored")
	_check(loaded.lifetime_contracts_completed == 7, "contract stats restored")
	_check(is_equal_approx(loaded.energy_price, 0.22), "energy price restored")
	_check(is_equal_approx(loaded.energy_discount, 0.24), "energy discount restored")
	_check(int(loaded.workers.get("assembly", 0)) == 2, "workers restored")
	_check(is_equal_approx(loaded.lifetime_wages_paid, 66.0), "wages stat restored")
	_check(is_equal_approx(loaded.lifetime_material_spend, 101.0), "kit spending restored")
	_check(is_equal_approx(loaded.lifetime_upgrade_spend, 202.0), "upgrade spending restored")
	_check(is_equal_approx(loaded.lifetime_maintenance_spend, 303.0), "maintenance spending restored")
	_check(is_equal_approx(loaded.lifetime_hiring_spend, 404.0), "hiring spending restored")
	_check(is_equal_approx(float(loaded.reputation["general"]), 61.0), "general reputation restored")
	_check(is_equal_approx(float(loaded.reputation["delivery"]), 72.0), "delivery reputation restored")
	_check(is_equal_approx(float(loaded.reputation["quality"]), 83.0), "quality reputation restored")
	_check(is_equal_approx(float(loaded.reputation["security"]), 94.0), "security reputation restored")
	_check(int(loaded.lifetime_contracts_by_tier["Approved Supplier"]) == 2, "contract tier history restored")
	_check(bool(loaded.advertising_channels.get("business_directory", false)), "advertising channel restored")
	_check(is_equal_approx(loaded.lifetime_advertising_spend, 77.0), "advertising spend restored")
	_check(loaded.competitor_name == "Test Power Ltd", "competitor name restored")
	_check(is_equal_approx(loaded.competitor_price, 6.25), "competitor price restored")
	_check(is_equal_approx(loaded.competitor_quality, 1.2), "competitor quality restored")
	_check(is_equal_approx(loaded.competitor_market_timer, 12.0), "competitor timer restored")
	_check(int(loaded.upgrade_levels.get("better_tools", 0)) == 2, "upgrade levels restored")
	_check(is_equal_approx(loaded.lifetime_revenue, 999.0), "stats restored")
	_check(loaded.event_log.size() > 0 and loaded.event_log[0] == "Round trip initiated.", "event log restored")
	_check(loaded.save_version == GameState.SAVE_VERSION, "save version restored")

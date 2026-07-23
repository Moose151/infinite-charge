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
	_test_cybersecurity_programs()
	_test_corporate_management()
	_test_research_and_challenges()
	_test_prestige_and_global_energy()
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

func _test_cybersecurity_programs() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 10000.0
	var starting_risk: float = Formulas.effective_risk(state)
	_check(simulation.upgrade_cyber_program(state, "segmentation"), "segmentation programme can advance")
	_check(state.network_segmentation_level == 1, "segmentation level stored")
	_check(Formulas.network_zone_count(state) == 2, "segmentation creates a second network zone")
	_check(Formulas.effective_risk(state) < starting_risk, "segmentation lowers effective risk")
	_check(simulation.upgrade_cyber_program(state, "detection"), "detection programme can advance")
	_check(Formulas.detection_strength(state) > 0.0, "detection programme creates detection strength")
	var detection_level_two_cost: float = simulation.cyber_program_cost(state, "detection")
	_check(detection_level_two_cost > float(Simulation.CYBER_PROGRAMS["detection"]["base_cost"]), "cybersecurity programme costs escalate")
	simulation.upgrade_cyber_program(state, "detection")
	simulation.upgrade_cyber_program(state, "detection")
	_check(state.detection_level == 3, "cybersecurity programmes cap at level three")
	_check(not simulation.upgrade_cyber_program(state, "detection"), "completed cybersecurity programme rejects extra levels")
	_check(simulation.upgrade_cyber_program(state, "response"), "response programme can advance")
	_check(Formulas.response_strength(state) > 0.0, "response programme creates response strength")
	_check(simulation.upgrade_cyber_program(state, "recovery"), "recovery programme can advance")
	_check(Formulas.recovery_strength(state) > 0.0, "recovery programme creates recovery strength")
	_check(not simulation.upgrade_cyber_program(state, "unknown"), "unknown cybersecurity programme rejected")

	var hire_cash: float = state.cash
	_check(simulation.hire_security_staff(state), "security analyst can be hired")
	_check(state.security_staff == 1 and state.cash < hire_cash, "security hiring fee charged")
	var wages_before: float = state.lifetime_security_wages
	simulation.advance(state, 10.0, false)
	_check(is_equal_approx(state.lifetime_security_wages - wages_before, 1.2), "security analyst wages paid continuously")
	state.cash = 0.0
	simulation.advance(state, 1.0, false)
	_check(not state.security_staff_on_duty, "unpaid security staff go off duty")
	_check(is_equal_approx(Formulas.detection_strength(state), state.detection_level * 0.16), "off-duty analysts stop boosting detection")
	state.cash = 100.0
	simulation.advance(state, 1.0, false)
	_check(state.security_staff_on_duty, "security staff resume after payroll recovers")
	_check(simulation.fire_security_staff(state), "security analyst can be released")

	var exposed: GameState = GameState.new()
	var defended: GameState = GameState.new()
	exposed.cash = 1000.0
	defended.cash = 1000.0
	defended.network_segmentation_level = 3
	defended.incident_response_level = 3
	defended.recovery_plan_level = 3
	var exposed_report: Dictionary = {"security_losses": 0.0, "security_events": 0}
	var defended_report: Dictionary = {"security_losses": 0.0, "security_events": 0}
	var cash_event: Dictionary = {"type": "cash", "severity_min": 0.2, "severity_max": 0.2, "message": "Test incident."}
	simulation.rng.seed = 7
	simulation._trigger_security_event(exposed, cash_event, exposed_report)
	simulation.rng.seed = 7
	simulation._trigger_security_event(defended, cash_event, defended_report, true)
	_check(float(defended_report["security_losses"]) < float(exposed_report["security_losses"]), "segmentation, response and recovery reduce incident impact")
	_check(Formulas.network_zone_count(defended) == 4, "full segmentation creates four network zones")
	_check(str(defended.last_security_incident.get("zone", "")) == "Office Systems", "incident records affected network zone")

	var monitored: GameState = GameState.new()
	monitored.cash = 100000.0
	monitored.detection_level = 3
	monitored.incident_response_level = 3
	monitored.security_staff = 3
	var monitor_simulation: Simulation = _make_sim()
	monitor_simulation.security_event_period = 1.0
	monitor_simulation.security_base_chance = 1.0
	monitor_simulation.security_risk_chance_scale = 0.0
	var monitor_report: Dictionary = monitor_simulation.advance(monitored, 20.0, true)
	_check(int(monitor_report["threats_detected"]) > 0, "detection identifies live threats")
	_check(int(monitor_report["incidents_contained"]) > 0, "incident response contains detected threats")
	_check(monitored.lifetime_incidents_contained == int(monitor_report["incidents_contained"]), "containment lifetime statistic tracked")

func _test_corporate_management() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 100000.0
	var base_capacity: float = Formulas.effective_warehouse_capacity(state)
	_check(simulation.buy_factory(state), "satellite factory can be acquired")
	_check(state.factories.size() == 1, "factory portfolio stores acquisition")
	_check(Formulas.corporate_factory_throughput(state) > 0.0, "satellite factory adds production")
	_check(Formulas.effective_warehouse_capacity(state) == base_capacity + 120.0, "satellite factory adds storage")
	var level_one_rate: float = Formulas.corporate_factory_throughput(state)
	_check(simulation.upgrade_factory(state, 0), "satellite factory can expand")
	_check(int(state.factories[0]["level"]) == 2, "factory level stored")
	_check(Formulas.corporate_factory_throughput(state) > level_one_rate, "factory expansion adds throughput")
	_check(not simulation.upgrade_factory(state, 99), "invalid factory expansion rejected")

	var material_before: float = Formulas.material_unit_cost(state)
	_check(simulation.invest_department(state, "procurement"), "procurement department can advance")
	_check(Formulas.material_unit_cost(state) < material_before, "procurement department lowers component price")
	var demand_before: float = Formulas.demand_per_second(state)
	_check(simulation.invest_department(state, "sales"), "sales department can advance")
	_check(Formulas.demand_per_second(state) > demand_before, "sales department raises demand")
	var factory_before_operations: float = Formulas.corporate_factory_throughput(state)
	_check(simulation.invest_department(state, "operations"), "operations department can advance")
	_check(Formulas.corporate_factory_throughput(state) > factory_before_operations, "operations department raises factory output")
	var detection_before: float = Formulas.detection_strength(state)
	_check(simulation.invest_department(state, "security"), "corporate security department can advance")
	_check(Formulas.detection_strength(state) > detection_before, "security department raises detection")
	_check(not simulation.invest_department(state, "unknown"), "unknown department rejected")

	var effective_procurement_before: float = Formulas.department_effective_level(state, "procurement")
	_check(simulation.hire_manager(state, "procurement"), "department manager can be appointed")
	_check(Formulas.department_effective_level(state, "procurement") > effective_procurement_before, "manager boosts department effectiveness")
	_check(simulation.hire_manager(state, "operations"), "operations manager can be appointed")
	_check(simulation.hire_manager(state, "sales"), "sales manager can be appointed")
	var manager_wages_before: float = state.lifetime_manager_wages
	simulation.advance(state, 10.0, false)
	_check(is_equal_approx(state.lifetime_manager_wages - manager_wages_before, 6.0), "manager wages paid continuously")
	state.cash = 0.0
	simulation.advance(state, 1.0, false)
	_check(not state.manager_payroll_active, "unpaid managers stop working")
	state.cash = 1000.0
	simulation.advance(state, 1.0, false)
	_check(state.manager_payroll_active, "managers resume after payroll recovers")

	_check(simulation.set_automation_rule(state, "material_reorder", true), "procurement manager unlocks reorder rule")
	_check(simulation.set_automation_rule(state, "preventive_service", true), "operations manager unlocks service rule")
	_check(simulation.set_automation_rule(state, "campaign_guardrail", true), "sales manager unlocks campaign guardrail")
	_check(simulation.set_automation_rule(state, "contract_review", true), "sales manager unlocks contract review")
	_check(not simulation.set_automation_rule(state, "unknown", true), "unknown automation rule rejected")
	state.automation_material_target = 100
	state.automation_cash_reserve = 100.0
	state.raw_materials = 0.0
	state.cash = 1000.0
	simulation._run_automation_rules(state)
	_check(state.raw_materials > 0.0, "reorder rule buys component kits")
	state.production_per_second = 1.0
	state.machine_condition = 0.5
	state.cash = 1000.0
	simulation._run_automation_rules(state)
	_check(is_equal_approx(state.machine_condition, 1.0), "service rule restores machine condition")
	state.advertising_channels["neighbourhood_flyers"] = true
	state.cash = 50.0
	simulation._run_automation_rules(state)
	_check(not bool(state.advertising_channels["neighbourhood_flyers"]), "campaign guardrail protects cash reserve")
	state.cash = 1000.0
	state.battery_cells = 100.0
	state.contract_offer = {"buyer": "automation client", "quantity": 10.0, "price_per_cell": 6.0, "duration": 60.0, "expires_in": 60.0}
	simulation._run_automation_rules(state)
	_check(not state.active_contract.is_empty(), "contract review accepts feasible profitable offer")

	var supply_state: GameState = GameState.new()
	supply_state.cash = 5000.0
	var spot_cost: float = Formulas.material_unit_cost(supply_state)
	_check(simulation.sign_supply_contract(supply_state, "local"), "supply contract can be signed")
	_check(Formulas.material_unit_cost(supply_state) < spot_cost, "supply contract lowers component price")
	simulation.buy_materials(supply_state, 10)
	_check(supply_state.lifetime_supply_savings > 0.0, "supply contract savings tracked")
	_check(not simulation.sign_supply_contract(supply_state, "bulk"), "overlapping supply contract rejected")
	simulation._update_supply_contract(supply_state, 901.0, false)
	_check(supply_state.active_supply_contract.is_empty(), "supply contract expires")

	var stats_state: GameState = GameState.new()
	var stats_simulation: Simulation = _make_sim()
	stats_simulation.advance(stats_state, 120.0, false)
	_check(stats_state.statistics_history.size() == 2, "corporate statistics sampled each minute")
	_check(stats_state.statistics_history.back().has("production_per_minute"), "statistics include production rate")
	_check(stats_state.statistics_history.back().has("risk"), "statistics include security risk")

func _test_research_and_challenges() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	var report: Dictionary = simulation.advance(state, 60.0, false)
	_check(state.research_points > 0.0, "company generates research points over time")
	_check(is_equal_approx(float(report["research_points"]), state.research_points), "advance reports generated research")

	state.cash = 100000.0
	state.research_points = 10000.0
	state.production_per_second = 1.0
	state.prep_rate = 2.0
	var material_cost: float = Formulas.material_unit_cost(state)
	_check(simulation.advance_research_branch(state, "materials"), "materials research can advance")
	_check(Formulas.material_unit_cost(state) < material_cost, "materials research lowers component cost")
	var throughput: float = Formulas.automated_throughput(state)
	_check(simulation.advance_research_branch(state, "manufacturing"), "manufacturing research can advance")
	_check(Formulas.automated_throughput(state) > throughput, "manufacturing research raises throughput")
	var demand: float = Formulas.demand_per_second(state)
	_check(simulation.advance_research_branch(state, "markets"), "market research can advance")
	_check(Formulas.demand_per_second(state) > demand, "market research raises demand")
	var detection: float = Formulas.detection_strength(state)
	_check(simulation.advance_research_branch(state, "cybernetics"), "cybernetics research can advance")
	_check(Formulas.detection_strength(state) > detection, "cybernetics research raises detection")
	_check(not simulation.advance_research_branch(state, "unknown"), "unknown research branch rejected")

	var locked_equipment: GameState = GameState.new()
	locked_equipment.cash = 100000.0
	locked_equipment.research_points = 10000.0
	_check(not simulation.buy_research_equipment(locked_equipment, "precision_assembler"), "equipment remains locked without branch requirement")
	var output_before: float = Formulas.automated_throughput(state)
	_check(simulation.buy_research_equipment(state, "precision_assembler"), "precision assembler can be installed")
	_check(Formulas.automated_throughput(state) > output_before, "precision assembler raises output")
	var capacity_before: float = Formulas.effective_warehouse_capacity(state)
	_check(simulation.buy_research_equipment(state, "smart_warehouse"), "smart warehouse can be installed")
	_check(Formulas.effective_warehouse_capacity(state) > capacity_before, "smart warehouse raises capacity")
	simulation.advance_research_branch(state, "manufacturing")
	var testing_before: float = Formulas.staffed_testing_rate(state)
	_check(simulation.buy_research_equipment(state, "laboratory_rig"), "laboratory rig can be installed")
	_check(Formulas.staffed_testing_rate(state) > testing_before, "laboratory rig raises testing rate")
	var detection_equipment_before: float = Formulas.detection_strength(state)
	_check(simulation.buy_research_equipment(state, "threat_console"), "threat console can be installed")
	_check(Formulas.detection_strength(state) > detection_equipment_before, "threat console raises detection")
	var analytics_demand_before: float = Formulas.demand_per_second(state)
	_check(simulation.buy_research_equipment(state, "market_analytics"), "market analytics can be installed")
	_check(Formulas.demand_per_second(state) > analytics_demand_before, "market analytics raises demand")

	var project_state: GameState = GameState.new()
	project_state.cash = 100000.0
	project_state.research_points = 1000.0
	var base_quality: float = Formulas.effective_quality(project_state)
	_check(simulation.start_long_project(project_state, "solid_state_prototype"), "long-term project can start")
	_check(not simulation.start_long_project(project_state, "closed_loop_materials"), "only one long-term project can run")
	var project_remaining: float = float(project_state.active_long_project["time_remaining"])
	simulation.advance(project_state, 60.0, false)
	_check(float(project_state.active_long_project["time_remaining"]) < project_remaining, "long-term projects progress offline")
	simulation._update_long_project(project_state, 1740.0, false)
	_check(project_state.completed_long_projects.has("solid_state_prototype"), "long-term project completes over time")
	_check(Formulas.effective_quality(project_state) > base_quality, "solid-state project improves quality")
	var discount_before: float = project_state.material_discount
	_check(simulation.start_long_project(project_state, "closed_loop_materials"), "second long-term project can start after completion")
	simulation._update_long_project(project_state, 2400.0, false)
	_check(project_state.material_discount > discount_before, "closed-loop project grants permanent discount")
	var production_before: float = project_state.production_per_second
	_check(simulation.start_long_project(project_state, "predictive_operations"), "predictive operations project can start")
	simulation._update_long_project(project_state, 2100.0, false)
	_check(project_state.production_per_second > production_before, "predictive operations grants permanent output")
	_check(project_state.lifetime_projects_completed == 3, "completed projects counted")

	var challenge_state: GameState = GameState.new()
	challenge_state.cash = 0.0
	_check(simulation.start_challenge(challenge_state, "production_sprint"), "challenge can start")
	challenge_state.lifetime_cells_made += 500.0
	simulation._update_challenge(challenge_state, 1.0)
	_check(challenge_state.active_challenge.is_empty(), "challenge completes when target reached")
	_check(challenge_state.lifetime_challenges_completed == 1, "challenge completion counted")
	_check(challenge_state.cash > 0.0 and challenge_state.research_points > 0.0, "challenge rewards cash and research")
	_check(challenge_state.completed_challenge_ids.has("production_sprint"), "completed challenge recorded")
	_check(simulation.start_challenge(challenge_state, "revenue_drive"), "another challenge can start")
	simulation._update_challenge(challenge_state, 901.0)
	_check(challenge_state.lifetime_challenges_failed == 1, "expired challenge fails")
	_check(simulation.start_challenge(challenge_state, "incident_free"), "incident-free challenge can start")
	var challenge_time: float = float(challenge_state.active_challenge["time_remaining"])
	simulation.advance(challenge_state, 60.0, false)
	_check(is_equal_approx(float(challenge_state.active_challenge["time_remaining"]), challenge_time), "challenges pause during offline advance")
	simulation._update_challenge(challenge_state, 900.0)
	_check(challenge_state.lifetime_challenges_completed == 2, "incident-free challenge completes clean window")
	_check(simulation.start_challenge(challenge_state, "incident_free"), "incident-free challenge can be repeated")
	challenge_state.lifetime_incidents_suffered += 1
	simulation._update_challenge(challenge_state, 1.0)
	_check(challenge_state.lifetime_challenges_failed == 2, "security impact fails incident-free challenge")

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

func _test_prestige_and_global_energy() -> void:
	var simulation: Simulation = _make_sim()
	var state: GameState = GameState.new()
	state.lifetime_revenue = 100000.0
	state.completed_long_projects = ["solid_state_prototype", "closed_loop_materials", "predictive_operations"]
	state.research_levels = {"materials": 5, "manufacturing": 5, "markets": 0, "cybernetics": 0}
	state.ui_theme_id = "solar"
	_check(simulation.prestige_eligible(state), "prestige unlocks at revenue and project threshold")
	_check(simulation.prestige_points_awarded(state) == 3, "prestige award scales with revenue and research")
	_check(simulation.perform_prestige(state), "eligible company can prestige")
	_check(state.prestige_level == 1 and state.legacy_points == 3, "prestige and legacy points persist through reset")
	_check(is_equal_approx(state.cash, 25.0) and state.completed_long_projects.is_empty(), "prestige resets company progression")
	_check(state.ui_theme_id == "solar", "prestige preserves interface preferences")
	_check(is_equal_approx(Formulas.legacy_multiplier(state), 1.15), "legacy points provide permanent multiplier")

	state.cash = 1000000.0
	state.research_points = 10000.0
	_check(simulation.buy_grid_upgrade(state), "grid infrastructure can be purchased after prestige")
	_check(state.grid_level == 1 and Formulas.grid_output_per_second(state) > 0.0, "grid upgrade creates energy output")
	var allocation_before: float = 0.0
	_check(simulation.adjust_national_market(state, "export", 10.0), "national allocation can be adjusted")
	for allocation: Variant in state.national_market_allocations.values():
		allocation_before += float(allocation)
	_check(is_equal_approx(allocation_before, 100.0), "national allocations remain normalized")
	var cash_before_grid: float = state.cash
	simulation.advance(state, 10.0, false)
	_check(state.cash > cash_before_grid and state.lifetime_grid_revenue > 0.0, "grid output earns national market revenue offline")

	_check(simulation.buy_recycling_upgrade(state), "recycling infrastructure can be purchased")
	state.production_per_second = 2.0
	state.raw_materials = 100.0
	state.warehouse_capacity = 1000.0
	state.cash = 100000.0
	simulation.advance(state, 40.0, false)
	_check(state.lifetime_recycled_materials > 0.0, "recycling recovers component kits from production")

	state.global_contract_offer = {"quantity": 10.0, "value": 50.0, "duration": 20.0, "expires_in": 10.0}
	_check(simulation.accept_global_contract(state), "large-scale contract offer can be accepted")
	var completed_before: int = state.lifetime_global_contracts_completed
	simulation.advance(state, 10.0, true)
	_check(state.lifetime_global_contracts_completed == completed_before + 1, "grid output completes large-scale contract")
	state.active_global_contract = {"quantity": 1000.0, "remaining": 1000.0, "value": 500.0, "time_remaining": 1.0}
	var failed_before: int = state.lifetime_global_contracts_failed
	simulation.advance(state, 2.0, true)
	_check(state.lifetime_global_contracts_failed == failed_before + 1, "missed large-scale contract records failure")
	state.global_contract_timer = Simulation.GLOBAL_CONTRACT_OFFER_PERIOD
	simulation.advance(state, 0.1, true)
	_check(not state.global_contract_offer.is_empty(), "large-scale contract offers arrive on schedule")

	var old_domestic_price: float = state.national_market_prices["domestic"]
	state.national_market_timer = Simulation.NATIONAL_MARKET_PERIOD
	simulation._update_national_markets(state, 0.1)
	_check(not is_equal_approx(float(state.national_market_prices["domestic"]), old_domestic_price), "national market prices drift independently")

	state.global_event_timer = Simulation.GLOBAL_EVENT_PERIOD
	var event_report: Dictionary = {"global_events": 0}
	simulation._update_global_event(state, 0.1, event_report)
	_check(not state.active_global_event.is_empty() and state.lifetime_global_events == 1, "global event starts on schedule")
	var event_market: String = str((state.active_global_event.get("market_modifiers", {}) as Dictionary).keys()[0])
	_check(not is_equal_approx(Formulas.national_market_price(state, event_market), float(state.national_market_prices[event_market])), "global event modifies its target market")

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
	state.network_segmentation_level = 3
	state.detection_level = 2
	state.incident_response_level = 1
	state.recovery_plan_level = 3
	state.security_staff = 2
	state.security_staff_on_duty = false
	state.lifetime_security_wages = 505.0
	state.lifetime_threats_detected = 12
	state.lifetime_incidents_contained = 8
	state.lifetime_incidents_suffered = 4
	state.last_security_incident = {"status": "contained", "zone": "Production", "type": "downtime", "message": "Test alert."}
	state.factories = [{"name": "Test Works", "level": 2}]
	state.department_levels = {"operations": 3, "procurement": 2, "sales": 1, "security": 3}
	state.managers = {"operations": true, "procurement": true, "sales": false, "security": true}
	state.manager_payroll_active = false
	state.automation_rules = {"material_reorder": true, "preventive_service": true, "campaign_guardrail": false, "contract_review": true}
	state.automation_material_target = 330
	state.automation_cash_reserve = 425.0
	state.active_supply_contract = {"id": "bulk", "name": "Test Supply", "discount": 0.18, "time_remaining": 777.0}
	state.lifetime_supply_contracts = 3
	state.lifetime_supply_savings = 606.0
	state.lifetime_manager_wages = 707.0
	state.lifetime_corporate_investment = 808.0
	state.statistics_timer = 12.0
	state.statistics_history = [{"time": 60.0, "cash": 10.0, "production_per_minute": 2.0, "risk": 0.1}]
	state.research_points = 91.0
	state.lifetime_research_points = 191.0
	state.research_levels = {"materials": 5, "manufacturing": 4, "markets": 3, "cybernetics": 2}
	state.equipment_levels = {"precision_assembler": 3, "smart_warehouse": 2, "laboratory_rig": 1, "threat_console": 2, "market_analytics": 3}
	state.active_long_project = {"id": "predictive_operations", "name": "Test Project", "duration": 2100.0, "time_remaining": 500.0}
	state.completed_long_projects = ["solid_state_prototype", "closed_loop_materials"]
	state.lifetime_projects_completed = 2
	state.active_challenge = {"id": "revenue_drive", "name": "Test Challenge", "metric": "revenue", "target": 5000.0, "start_value": 100.0, "duration": 900.0, "time_remaining": 450.0}
	state.lifetime_challenges_completed = 4
	state.lifetime_challenges_failed = 2
	state.completed_challenge_ids = ["production_sprint", "incident_free"]
	state.prestige_level = 2
	state.legacy_points = 7
	state.grid_level = 4
	state.national_market_allocations = {"domestic": 20.0, "industrial": 30.0, "export": 50.0}
	state.recycling_level = 3
	state.lifetime_recycled_materials = 44.0
	state.active_global_contract = {"quantity": 100.0, "remaining": 25.0, "value": 50.0}
	state.lifetime_grid_revenue = 321.0
	state.active_global_event = {"id": "heatwave", "time_remaining": 30.0, "market_modifiers": {"domestic": 1.45}}
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
	_check(loaded.network_segmentation_level == 3, "network segmentation restored")
	_check(loaded.detection_level == 2, "detection programme restored")
	_check(loaded.incident_response_level == 1, "incident response programme restored")
	_check(loaded.recovery_plan_level == 3, "recovery planning restored")
	_check(loaded.security_staff == 2 and not loaded.security_staff_on_duty, "security staffing restored")
	_check(is_equal_approx(loaded.lifetime_security_wages, 505.0), "security wages restored")
	_check(loaded.lifetime_threats_detected == 12, "detected threat statistic restored")
	_check(loaded.lifetime_incidents_contained == 8, "contained incident statistic restored")
	_check(loaded.lifetime_incidents_suffered == 4, "impact incident statistic restored")
	_check(str(loaded.last_security_incident.get("zone", "")) == "Production", "last incident record restored")
	_check(loaded.factories.size() == 1 and int(loaded.factories[0]["level"]) == 2, "factory portfolio restored")
	_check(int(loaded.department_levels["procurement"]) == 2, "department levels restored")
	_check(bool(loaded.managers["operations"]) and not loaded.manager_payroll_active, "manager state restored")
	_check(bool(loaded.automation_rules["contract_review"]), "automation rules restored")
	_check(loaded.automation_material_target == 330, "automation material target restored")
	_check(is_equal_approx(loaded.automation_cash_reserve, 425.0), "automation cash reserve restored")
	_check(str(loaded.active_supply_contract.get("id", "")) == "bulk", "supply contract restored")
	_check(loaded.lifetime_supply_contracts == 3, "supply contract count restored")
	_check(is_equal_approx(loaded.lifetime_supply_savings, 606.0), "supply savings restored")
	_check(is_equal_approx(loaded.lifetime_manager_wages, 707.0), "manager wages restored")
	_check(is_equal_approx(loaded.lifetime_corporate_investment, 808.0), "corporate investment restored")
	_check(loaded.statistics_history.size() == 1, "detailed statistics history restored")
	_check(is_equal_approx(loaded.research_points, 91.0), "available research points restored")
	_check(is_equal_approx(loaded.lifetime_research_points, 191.0), "lifetime research points restored")
	_check(int(loaded.research_levels["manufacturing"]) == 4, "research branches restored")
	_check(int(loaded.equipment_levels["market_analytics"]) == 3, "research equipment restored")
	_check(str(loaded.active_long_project.get("id", "")) == "predictive_operations", "active long-term project restored")
	_check(loaded.completed_long_projects.has("solid_state_prototype"), "completed long-term projects restored")
	_check(loaded.lifetime_projects_completed == 2, "project completion count restored")
	_check(str(loaded.active_challenge.get("id", "")) == "revenue_drive", "active challenge restored")
	_check(loaded.lifetime_challenges_completed == 4 and loaded.lifetime_challenges_failed == 2, "challenge totals restored")
	_check(loaded.completed_challenge_ids.has("incident_free"), "completed challenge history restored")
	_check(loaded.prestige_level == 2 and loaded.legacy_points == 7, "prestige state restored")
	_check(loaded.grid_level == 4 and is_equal_approx(float(loaded.national_market_allocations["export"]), 50.0), "grid and national markets restored")
	_check(loaded.recycling_level == 3 and is_equal_approx(loaded.lifetime_recycled_materials, 44.0), "recycling state restored")
	_check(is_equal_approx(float(loaded.active_global_contract.get("remaining", 0.0)), 25.0), "large-scale contract restored")
	_check(is_equal_approx(loaded.lifetime_grid_revenue, 321.0) and str(loaded.active_global_event.get("id", "")) == "heatwave", "global revenue and event restored")
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

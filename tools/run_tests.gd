# Headless test suite. Run from the project root with:
#   godot-4 --headless --path . --script res://tools/run_tests.gd
# Exits non-zero if any test fails.
extends SceneTree

var failures: int = 0
var checks: int = 0

func _init() -> void:
	_test_formulas()
	_test_manual_production()
	_test_material_buying()
	_test_upgrades()
	_test_advance()
	_test_downtime()
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
	state.material_discount = 10.0
	_check(Formulas.material_unit_cost(state) >= 0.05, "material cost floors above zero")

	var definition: Dictionary = {"base_cost": 100.0, "cost_scale": 2.0}
	_check(is_equal_approx(Formulas.upgrade_cost(definition, 0), 100.0), "upgrade cost level 0")
	_check(is_equal_approx(Formulas.upgrade_cost(definition, 3), 800.0), "upgrade cost scales geometrically")

	_check(Formulas.format_number(1500000.0) == "1.50M", "format millions")
	_check(Formulas.format_number(2500.0) == "2.50k", "format thousands")
	_check(Formulas.format_number(3.14159) == "3.14", "format small numbers")

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
	state.cash = 0.0
	state.raw_materials = 100.0
	state.battery_cells = 100.0
	state.production_per_second = 2.0
	state.sale_price = 4.0
	var report: Dictionary = simulation.advance(state, 1.0, false)
	_check(float(report["cells_made"]) > 0.0, "advance produces automatically")
	_check(is_equal_approx(state.raw_materials, 98.0), "advance consumes materials")
	_check(float(report["cells_sold"]) > 0.0, "advance sells cells")
	_check(state.cash > 0.0, "advance earns revenue")
	_check(is_equal_approx(float(report["revenue"]), float(report["cells_sold"]) * 4.0), "revenue matches sales")

func _test_downtime() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.raw_materials = 100.0
	state.production_per_second = 2.0
	state.production_downtime = 10.0
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.raw_materials, 100.0), "downtime halts automated production")
	_check(is_equal_approx(state.production_downtime, 9.0), "downtime ticks down")
	state.production_downtime = 0.5
	simulation.advance(state, 1.0, false)
	_check(is_equal_approx(state.raw_materials, 99.0), "partial downtime allows partial production")

func _test_offline_advance_has_no_security_events() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	state.cash = 1000.0
	state.raw_materials = 10000.0
	state.risk = 1.0
	var report: Dictionary = simulation.advance(state, 3600.0, false)
	_check(int(report["security_events"]) == 0, "offline advance skips security events")

func _test_security_event_effects() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = _make_sim()
	var report: Dictionary = {"security_losses": 0.0, "security_events": 0}

	state.cash = 100.0
	simulation._trigger_security_event(state, {"type": "cash", "severity_min": 0.1, "severity_max": 0.1}, report)
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
	state.manual_output = 3.0
	state.production_per_second = 1.25
	state.production_downtime = 4.0
	state.ui_scale = 1.5
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
	_check(is_equal_approx(loaded.production_downtime, 4.0), "downtime restored")
	_check(is_equal_approx(loaded.ui_scale, 1.5), "ui scale restored")
	_check(int(loaded.upgrade_levels.get("better_tools", 0)) == 2, "upgrade levels restored")
	_check(is_equal_approx(loaded.lifetime_revenue, 999.0), "stats restored")
	_check(loaded.event_log.size() > 0 and loaded.event_log[0] == "Round trip initiated.", "event log restored")
	_check(loaded.save_version == GameState.SAVE_VERSION, "save version restored")

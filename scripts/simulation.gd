extends RefCounted
class_name Simulation

const MATERIAL_MARKET_PERIOD: float = 18.0
const SECURITY_EVENTS_PATH: String = "res://data/events/security_events.json"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var security_event_period: float = 40.0
var security_base_chance: float = 0.12
var security_risk_chance_scale: float = 0.85
var security_events: Array[Dictionary] = []

func _init() -> void:
	rng.randomize()
	_load_security_events()

func _load_security_events() -> void:
	var file: FileAccess = FileAccess.open(SECURITY_EVENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load security event data.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Security event data must be a dictionary.")
		return
	var data: Dictionary = parsed
	security_event_period = float(data.get("period_seconds", security_event_period))
	security_base_chance = float(data.get("base_chance", security_base_chance))
	security_risk_chance_scale = float(data.get("risk_chance_scale", security_risk_chance_scale))
	security_events.clear()
	for item: Variant in data.get("events", []):
		if typeof(item) == TYPE_DICTIONARY:
			security_events.append(item)

func advance(state: GameState, delta: float, allow_events: bool = true) -> Dictionary:
	var report: Dictionary = {
		"seconds": delta,
		"cells_made": 0.0,
		"cells_sold": 0.0,
		"revenue": 0.0,
		"materials_consumed": 0.0,
		"security_losses": 0.0,
		"market_events": 0,
		"security_events": 0,
	}

	state.seconds_played += delta
	state.demand_per_second = Formulas.demand_per_second(state)

	var uptime: float = delta
	if state.production_downtime > 0.0:
		uptime = maxf(0.0, delta - state.production_downtime)
		state.production_downtime = maxf(0.0, state.production_downtime - delta)

	var space: float = Formulas.warehouse_space(state)
	var automated_target: float = state.production_per_second * Formulas.machine_efficiency(state) * uptime
	var automated_cells: float = minf(minf(state.raw_materials, space), automated_target)
	if automated_cells > 0.0:
		state.raw_materials -= automated_cells
		state.battery_cells += automated_cells
		state.lifetime_cells_made += automated_cells
		state.machine_condition = maxf(0.0, state.machine_condition - automated_cells * Formulas.wear_per_cell(state))
		report["cells_made"] = automated_cells
		report["materials_consumed"] = automated_cells
	elif allow_events and automated_target > 0.0 and space <= 0.0 and state.raw_materials > 0.0:
		if state.event_log.is_empty() or not state.event_log[0].begins_with("Warehouse full"):
			state.add_event("Warehouse full. Automation is stacking cells vertically and hoping.")

	var demanded_cells: float = state.demand_per_second * delta
	var sellable_cells: float = minf(state.battery_cells, demanded_cells)
	state.lifetime_sales_lost += maxf(0.0, demanded_cells - sellable_cells)
	if sellable_cells > 0.0:
		var revenue: float = sellable_cells * state.sale_price
		state.battery_cells -= sellable_cells
		state.cash += revenue
		state.sales_per_second = sellable_cells / maxf(delta, 0.001)
		state.lifetime_cells_sold += sellable_cells
		state.lifetime_revenue += revenue
		report["cells_sold"] = sellable_cells
		report["revenue"] = revenue
	else:
		state.sales_per_second = 0.0

	_update_material_market(state, delta, allow_events, report)
	_update_security_events(state, delta, allow_events, report)
	_check_bankruptcy_rescue(state, allow_events)
	state.notify_changed()
	return report

func _check_bankruptcy_rescue(state: GameState, allow_events: bool) -> void:
	# Safety net: with no cash, materials, inventory, or automation the player
	# would be permanently stuck. Self-limiting because the grant refills cash.
	if state.cash >= 5.0 or state.raw_materials >= 1.0 or state.battery_cells >= 0.01:
		return
	state.cash = 25.0
	if allow_events:
		state.add_event("A concerned relative has invested $25. The board thanks them and requests they stop attending meetings.")

func advance_chunked(state: GameState, total_seconds: float, allow_events: bool = false, chunk_seconds: float = 30.0) -> Dictionary:
	# Long spans (offline progress) must be stepped so production and sales
	# interleave; a single step would cap output at warehouse capacity.
	var aggregate: Dictionary = {
		"seconds": total_seconds,
		"cells_made": 0.0,
		"cells_sold": 0.0,
		"revenue": 0.0,
		"materials_consumed": 0.0,
		"security_losses": 0.0,
		"market_events": 0,
		"security_events": 0,
	}
	var remaining: float = total_seconds
	while remaining > 0.0:
		var step: float = minf(chunk_seconds, remaining)
		remaining -= step
		var report: Dictionary = advance(state, step, allow_events)
		for key: String in ["cells_made", "cells_sold", "revenue", "materials_consumed", "security_losses"]:
			aggregate[key] = float(aggregate[key]) + float(report[key])
		for key: String in ["market_events", "security_events"]:
			aggregate[key] = int(aggregate[key]) + int(report[key])
	return aggregate

func manual_produce(state: GameState) -> bool:
	if state.raw_materials < state.manual_output:
		if state.event_log.is_empty() or not state.event_log[0].begins_with("Production paused"):
			state.add_event("Production paused: materials are currently represented by an empty shelf.")
		return false
	if state.battery_cells + state.manual_output > state.warehouse_capacity:
		if state.event_log.is_empty() or not state.event_log[0].begins_with("Warehouse full"):
			state.add_event("Warehouse full. The next cell would legally be furniture.")
		return false
	state.raw_materials -= state.manual_output
	state.battery_cells += state.manual_output
	state.lifetime_cells_made += state.manual_output
	state.notify_changed()
	return true

func buy_materials(state: GameState, quantity: float) -> bool:
	var cost: float = quantity * Formulas.material_unit_cost(state)
	if state.cash < cost:
		state.add_event("Purchasing declined: Finance reports that money remains a limiting factor.")
		return false
	state.cash -= cost
	state.raw_materials += quantity
	state.lifetime_materials_bought += quantity
	state.add_event("Purchased %s material units for $%s." % [Formulas.format_number(quantity), Formulas.format_number(cost)])
	return true

func service_machines(state: GameState) -> bool:
	if state.production_per_second <= 0.0 or state.machine_condition >= 0.995:
		return false
	var cost: float = Formulas.service_cost(state)
	if state.cash < cost:
		state.add_event("Servicing postponed: the machines will continue to make that noise.")
		return false
	state.cash -= cost
	state.machine_condition = 1.0
	state.add_event("Machines serviced for $%s. The grinding sound has been reclassified as a memory." % Formulas.format_number(cost))
	return true

func buy_upgrade(state: GameState, definition: Dictionary) -> bool:
	var id: String = str(definition.get("id", ""))
	var level: int = int(state.upgrade_levels.get(id, 0))
	var max_level: int = int(definition.get("max_level", 1))
	if level >= max_level:
		return false
	var cost: float = Formulas.upgrade_cost(definition, level)
	if state.cash < cost:
		state.add_event("Upgrade deferred: insufficient cash for %s." % str(definition.get("name", "upgrade")))
		return false
	state.cash -= cost
	state.upgrade_levels[id] = level + 1
	_apply_upgrade_effects(state, definition)
	state.add_event("Approved upgrade: %s level %d." % [str(definition.get("name", "Upgrade")), level + 1])
	return true

func _apply_upgrade_effects(state: GameState, definition: Dictionary) -> void:
	var effects: Dictionary = definition.get("effects", {})
	state.manual_output += float(effects.get("manual_output_add", 0.0))
	state.production_per_second += float(effects.get("production_per_second_add", 0.0))
	state.awareness += float(effects.get("awareness_add", 0.0))
	state.quality += float(effects.get("quality_add", 0.0))
	state.base_value += float(effects.get("base_price_add", 0.0))
	state.material_discount += float(effects.get("material_discount_add", 0.0))
	state.risk += float(effects.get("risk_add", 0.0))
	state.risk_reduction += float(effects.get("risk_reduction_add", 0.0))
	state.recovery += float(effects.get("recovery_add", 0.0))
	state.trust += float(effects.get("trust_add", 0.0))
	state.warehouse_capacity += float(effects.get("warehouse_capacity_add", 0.0))
	state.wear_reduction += float(effects.get("wear_reduction_add", 0.0))

func _update_material_market(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	state.material_market_timer += delta
	while state.material_market_timer >= MATERIAL_MARKET_PERIOD:
		state.material_market_timer -= MATERIAL_MARKET_PERIOD
		var old_price: float = state.material_price
		var drift: float = rng.randf_range(-0.16, 0.18)
		state.material_price = clampf(state.material_price * (1.0 + drift), 0.45, 3.25)
		report["market_events"] = int(report["market_events"]) + 1
		if allow_events and absf(state.material_price - old_price) >= 0.04:
			var direction: String = "rose" if state.material_price > old_price else "fell"
			state.add_event("Material spot price %s to $%s. Procurement has updated the spreadsheet." % [direction, Formulas.format_number(state.material_price)])

func _update_security_events(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	if not allow_events or security_events.is_empty():
		return
	state.security_event_timer += delta
	while state.security_event_timer >= security_event_period:
		state.security_event_timer -= security_event_period
		var event_chance: float = security_base_chance + Formulas.effective_risk(state) * security_risk_chance_scale
		if rng.randf() > event_chance:
			continue
		_trigger_security_event(state, _pick_security_event(), report)

func _pick_security_event() -> Dictionary:
	var total_weight: float = 0.0
	for event: Dictionary in security_events:
		total_weight += float(event.get("weight", 1.0))
	var roll: float = rng.randf() * total_weight
	for event: Dictionary in security_events:
		roll -= float(event.get("weight", 1.0))
		if roll <= 0.0:
			return event
	return security_events.back()

func _trigger_security_event(state: GameState, event: Dictionary, report: Dictionary) -> void:
	var mitigation: float = 1.0 - clampf(state.recovery, 0.0, 0.8)
	var severity: float = rng.randf_range(float(event.get("severity_min", 0.05)), float(event.get("severity_max", 0.15))) * mitigation
	var message: String = str(event.get("message", "Security has noticed something."))
	var detail: String = ""
	match str(event.get("type", "cash")):
		"cash":
			var loss: float = minf(state.cash * severity, state.cash)
			state.cash -= loss
			state.lifetime_security_losses += loss
			report["security_losses"] = float(report["security_losses"]) + loss
			detail = "Response cost: $%s." % Formulas.format_number(loss)
		"inventory":
			var lost_cells: float = state.battery_cells * severity
			state.battery_cells -= lost_cells
			var value: float = lost_cells * state.sale_price
			state.lifetime_security_losses += value
			report["security_losses"] = float(report["security_losses"]) + value
			detail = "Stock written off: %s cells." % Formulas.format_number(lost_cells)
		"downtime":
			state.production_downtime += severity
			detail = "Automation offline for %ds." % roundi(severity)
	report["security_events"] = int(report["security_events"]) + 1
	state.add_event("%s %s" % [message, detail])

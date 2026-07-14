extends RefCounted
class_name Simulation

const MATERIAL_MARKET_PERIOD: float = 18.0
const SECURITY_EVENT_PERIOD: float = 45.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

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

	var automated_cells: float = minf(state.raw_materials, state.production_per_second * delta)
	if automated_cells > 0.0:
		state.raw_materials -= automated_cells
		state.battery_cells += automated_cells
		state.lifetime_cells_made += automated_cells
		report["cells_made"] = automated_cells
		report["materials_consumed"] = automated_cells

	var sellable_cells: float = minf(state.battery_cells, state.demand_per_second * delta)
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
	state.notify_changed()
	return report

func manual_produce(state: GameState) -> bool:
	if state.raw_materials < state.manual_output:
		state.add_event("Production paused: materials are currently represented by an empty shelf.")
		return false
	state.raw_materials -= state.manual_output
	state.battery_cells += state.manual_output
	state.lifetime_cells_made += state.manual_output
	state.add_event("Assembled %s cell%s by hand." % [Formulas.format_number(state.manual_output), "" if is_equal_approx(state.manual_output, 1.0) else "s"])
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
	if not allow_events:
		return
	state.security_event_timer += delta
	while state.security_event_timer >= SECURITY_EVENT_PERIOD:
		state.security_event_timer -= SECURITY_EVENT_PERIOD
		var event_chance: float = 0.18 + Formulas.effective_risk(state) * 0.75
		if rng.randf() > event_chance:
			continue
		var loss_ratio: float = rng.randf_range(0.015, 0.055) * (1.0 - clampf(state.recovery, 0.0, 0.8))
		var loss: float = minf(state.cash * loss_ratio, state.cash)
		state.cash -= loss
		state.lifetime_security_losses += loss
		report["security_losses"] = float(report["security_losses"]) + loss
		report["security_events"] = int(report["security_events"]) + 1
		var messages: Array[String] = [
			"A suspicious login was contained after requesting a meeting with itself.",
			"An exposed service was found and politely asked to stop being exposed.",
			"A supplier sent a firmware update with the confidence of someone who had not read it.",
			"Security detected unusual activity. Operations detected a production excuse."
		]
		state.add_event("%s Response cost: $%s." % [messages.pick_random(), Formulas.format_number(loss)])

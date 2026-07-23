extends RefCounted
class_name Simulation

const MATERIAL_MARKET_PERIOD: float = 18.0
const SECURITY_EVENTS_PATH: String = "res://data/events/security_events.json"
const CONTRACT_OFFER_PERIOD: float = 170.0
const CONTRACT_OFFER_LIFETIME: float = 60.0
const PREMIUM_PRODUCT_UNLOCK_COST: float = 350.0
const COMPETITOR_MARKET_PERIOD: float = 45.0
const SECURITY_STAFF_HIRING_FEE: float = 250.0
const CYBER_PROGRAMS: Dictionary = {
	"segmentation": {"state_field": "network_segmentation_level", "name": "Network Segmentation", "base_cost": 400.0, "scale": 1.8},
	"detection": {"state_field": "detection_level", "name": "Threat Detection", "base_cost": 320.0, "scale": 1.75},
	"response": {"state_field": "incident_response_level", "name": "Incident Response", "base_cost": 360.0, "scale": 1.8},
	"recovery": {"state_field": "recovery_plan_level", "name": "Recovery Planning", "base_cost": 300.0, "scale": 1.7},
}
const FACTORY_NAMES: Array[String] = ["Northside Assembly", "Riverside Works", "Airport Industrial Unit"]
const FACTORY_BASE_COST: float = 3000.0
const FACTORY_UPGRADE_BASE_COST: float = 1800.0
const MANAGER_HIRING_FEE: float = 1200.0
const DEPARTMENTS: Dictionary = {
	"operations": {"name": "Operations", "base_cost": 650.0, "scale": 1.8},
	"procurement": {"name": "Procurement", "base_cost": 600.0, "scale": 1.75},
	"sales": {"name": "Sales", "base_cost": 700.0, "scale": 1.8},
	"security": {"name": "Corporate Security", "base_cost": 750.0, "scale": 1.85},
}
const SUPPLY_PLANS: Dictionary = {
	"local": {"name": "Local Supplier Schedule", "fee": 500.0, "duration": 900.0, "discount": 0.10},
	"bulk": {"name": "Bulk Components Agreement", "fee": 1500.0, "duration": 1800.0, "discount": 0.18},
}

const CONTRACT_BUYERS: Array[String] = [
	"the Municipal Parks Department",
	"a regional drone hobbyist collective",
	"the neighbourhood watch, recently motorised",
	"a startup that pivoted to flashlights",
	"the community theatre's lighting committee",
	"a very confident camping supply store",
]

const CONTRACT_TIERS: Array[Dictionary] = [
	{"name": "Open Market", "requirements": {}, "quantity_scale": 1.0, "price_scale": 1.0},
	{"name": "Approved Supplier", "requirements": {"general": 55.0, "delivery": 55.0}, "quantity_scale": 1.25, "price_scale": 1.08},
	{"name": "Assured Supply", "requirements": {"general": 65.0, "delivery": 65.0, "quality": 60.0, "security": 55.0}, "quantity_scale": 1.6, "price_scale": 1.18},
]

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
		"energy_cost": 0.0,
		"wages_paid": 0.0,
		"advertising_cost": 0.0,
		"competitor_events": 0,
		"market_events": 0,
		"security_events": 0,
		"security_wages": 0.0,
		"manager_wages": 0.0,
		"threats_detected": 0,
		"incidents_contained": 0,
	}

	_pay_wages(state, delta, allow_events, report)
	_pay_security_staff(state, delta, allow_events, report)
	_pay_managers(state, delta, allow_events, report)
	_update_supply_contract(state, delta, allow_events)
	_run_automation_rules(state)
	_pay_advertising(state, delta, allow_events, report)

	state.seconds_played += delta
	state.demand_per_second = Formulas.demand_per_second(state)

	var uptime: float = delta
	if state.production_downtime > 0.0:
		uptime = maxf(0.0, delta - state.production_downtime)
		state.production_downtime = maxf(0.0, state.production_downtime - delta)

	_produce_automated(state, uptime, allow_events, report)

	if allow_events:
		_update_contracts(state, delta, report)

	var standard_sold: int = _sell_spot_product(state, "standard", delta, report)
	var premium_sold: int = 0
	if state.premium_product_unlocked:
		premium_sold = _sell_spot_product(state, "premium", delta, report)
	var standard_flow: float = state.demand_per_second if state.battery_cells >= 1.0 or standard_sold > 0 else 0.0
	var premium_flow: float = Formulas.demand_per_second(state, "premium") if state.premium_cells >= 1.0 or premium_sold > 0 else 0.0
	state.sales_per_second = standard_flow + premium_flow

	_update_material_market(state, delta, allow_events, report)
	_update_energy_market(state, delta, allow_events)
	_update_competitor_market(state, delta, allow_events, report)
	_update_security_events(state, delta, allow_events, report)
	_update_statistics_history(state, delta)
	_check_bankruptcy_rescue(state, allow_events)
	state.notify_changed()
	return report

func _produce_automated(state: GameState, uptime: float, allow_events: bool, report: Dictionary) -> void:
	var rate: float = Formulas.automated_throughput(state)
	if rate <= 0.0 or uptime <= 0.0:
		return
	var product_id: String = state.active_product
	var accumulated: float = float(state.production_progress.get(product_id, 0.0)) + rate * uptime
	var completed_work: int = floori(accumulated)
	state.production_progress[product_id] = accumulated - completed_work
	if completed_work <= 0:
		return
	var material_per_cell: int = roundi(Formulas.product_material_cost(product_id))
	var material_limit: int = floori(state.raw_materials / material_per_cell)
	var space_limit: int = floori(Formulas.warehouse_space(state))
	var energy_per_cell: float = Formulas.energy_cost_per_cell(state)
	var energy_limit: int = completed_work if energy_per_cell <= 0.0 else floori(state.cash / energy_per_cell)
	var cells_made: int = mini(completed_work, mini(material_limit, mini(space_limit, energy_limit)))
	if cells_made <= 0:
		if allow_events and space_limit <= 0 and state.raw_materials >= material_per_cell:
			if state.event_log.is_empty() or not state.event_log[0].begins_with("Warehouse full"):
				state.add_event("Warehouse full. Automation is stacking cells vertically and hoping.")
		return
	var materials_used: int = cells_made * material_per_cell
	var energy_cost: float = cells_made * energy_per_cell
	state.raw_materials -= materials_used
	if product_id == "premium":
		state.premium_cells += cells_made
	else:
		state.battery_cells += cells_made
	state.cash -= energy_cost
	state.lifetime_cells_made += cells_made
	var total_rate: float = Formulas.automated_throughput(state)
	var garage_share: float = 0.0 if total_rate <= 0.0 else Formulas.garage_throughput(state) / total_rate
	state.machine_condition = maxf(0.0, state.machine_condition - cells_made * garage_share * Formulas.wear_per_cell(state))
	state.lifetime_energy_cost += energy_cost
	report["energy_cost"] = energy_cost
	report["cells_made"] = cells_made
	report["materials_consumed"] = materials_used

func _sell_spot_product(state: GameState, product_id: String, delta: float, report: Dictionary) -> int:
	var demand: float = Formulas.demand_per_second(state, product_id)
	var accumulated: float = float(state.sales_progress.get(product_id, 0.0)) + demand * delta
	var customer_orders: int = floori(accumulated)
	state.sales_progress[product_id] = accumulated - customer_orders
	if customer_orders <= 0:
		return 0
	var inventory: int = floori(state.premium_cells if product_id == "premium" else state.battery_cells)
	var cells_sold: int = mini(inventory, customer_orders)
	state.lifetime_sales_lost += customer_orders - cells_sold
	if cells_sold <= 0:
		return 0
	var price: float = state.premium_sale_price if product_id == "premium" else state.sale_price
	var revenue: float = cells_sold * price
	if product_id == "premium":
		state.premium_cells -= cells_sold
	else:
		state.battery_cells -= cells_sold
	state.cash += revenue
	state.lifetime_cells_sold += cells_sold
	state.lifetime_revenue += revenue
	report["cells_sold"] = float(report["cells_sold"]) + cells_sold
	report["revenue"] = float(report["revenue"]) + revenue
	return cells_sold

func _check_bankruptcy_rescue(state: GameState, allow_events: bool) -> void:
	# Safety net: with no cash, materials, inventory, or automation the player
	# would be permanently stuck. Self-limiting because the grant refills cash.
	if state.cash >= 5.0 or state.raw_materials >= 1.0 or state.battery_cells + state.premium_cells >= 0.01:
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
		"advertising_cost": 0.0,
		"security_wages": 0.0,
		"manager_wages": 0.0,
		"competitor_events": 0,
		"market_events": 0,
		"security_events": 0,
		"threats_detected": 0,
		"incidents_contained": 0,
	}
	var remaining: float = total_seconds
	while remaining > 0.0:
		var step: float = minf(chunk_seconds, remaining)
		remaining -= step
		var report: Dictionary = advance(state, step, allow_events)
		for key: String in ["cells_made", "cells_sold", "revenue", "materials_consumed", "security_losses", "advertising_cost", "security_wages", "manager_wages"]:
			aggregate[key] = float(aggregate[key]) + float(report[key])
		for key: String in ["market_events", "security_events", "competitor_events", "threats_detected", "incidents_contained"]:
			aggregate[key] = int(aggregate[key]) + int(report[key])
	return aggregate

func manual_produce(state: GameState) -> bool:
	var cells_in_batch: int = maxi(1, roundi(state.manual_output))
	var material_needed: int = cells_in_batch * roundi(Formulas.product_material_cost(state.active_product))
	if state.raw_materials < material_needed:
		if state.event_log.is_empty() or not state.event_log[0].begins_with("Production paused"):
			state.add_event("Production paused: materials are currently represented by an empty shelf.")
		return false
	if Formulas.warehouse_space(state) < cells_in_batch:
		if state.event_log.is_empty() or not state.event_log[0].begins_with("Warehouse full"):
			state.add_event("Warehouse full. The next cell would legally be furniture.")
		return false
	state.raw_materials -= material_needed
	if state.active_product == "premium":
		state.premium_cells += cells_in_batch
	else:
		state.battery_cells += cells_in_batch
	state.lifetime_cells_made += cells_in_batch
	state.notify_changed()
	return true

func unlock_premium_product(state: GameState) -> bool:
	if state.premium_product_unlocked or state.cash < PREMIUM_PRODUCT_UNLOCK_COST:
		if not state.premium_product_unlocked:
			state.add_event("Long-Life Cell design deferred: Product Development has encountered the cash balance.")
		return false
	state.cash -= PREMIUM_PRODUCT_UNLOCK_COST
	state.premium_product_unlocked = true
	state.active_product = "premium"
	state.add_event("Long-Life Cell design approved. It requires two component kits and considerably more branding.")
	return true

func select_product(state: GameState, product_id: String) -> bool:
	if product_id != "standard" and product_id != "premium":
		return false
	if product_id == "premium" and not state.premium_product_unlocked:
		return false
	state.active_product = product_id
	state.add_event("Production routing changed to %s cells. The label printer has been informed." % ("Long-Life" if product_id == "premium" else "Standard"))
	return true

func buy_materials(state: GameState, quantity: float) -> bool:
	var kits: int = maxi(1, roundi(quantity))
	var cost: float = kits * Formulas.material_unit_cost(state)
	if state.cash < cost:
		state.add_event("Purchasing declined: Finance reports that money remains a limiting factor.")
		return false
	state.cash -= cost
	state.raw_materials += kits
	state.lifetime_materials_bought += kits
	state.lifetime_material_spend += cost
	if not state.active_supply_contract.is_empty():
		var department_discount: float = Formulas.department_effective_level(state, "procurement") * 0.025
		var without_contract: float = state.material_price * (1.0 - clampf(state.material_discount + department_discount, 0.0, 0.85))
		state.lifetime_supply_savings += maxf(0.0, kits * without_contract - cost)
	state.add_event("Purchased %d component kits for $%s." % [kits, Formulas.format_number(cost)])
	return true

func set_advertising_channel(state: GameState, channel_id: String, enabled: bool) -> bool:
	if not state.advertising_channels.has(channel_id):
		return false
	state.advertising_channels[channel_id] = enabled
	state.add_event("%s campaign %s. Marketing has adjusted the clipboards." % [
		channel_id.replace("_", " ").capitalize(),
		"launched" if enabled else "paused"
	])
	return true

func _pay_advertising(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	var due: float = Formulas.advertising_cost_per_second(state) * delta
	if due <= 0.0:
		return
	if state.cash >= due:
		state.cash -= due
		state.lifetime_advertising_spend += due
		report["advertising_cost"] = due
		return
	for channel_id: String in state.advertising_channels:
		state.advertising_channels[channel_id] = false
	if allow_events:
		state.add_event("Advertising paused after Finance discovered that attention is rented, not owned.")

func _pay_wages(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	var worker_count: int = Formulas.total_workers(state)
	if worker_count == 0:
		state.staff_striking = false
		return
	var due: float = worker_count * Formulas.WORKER_WAGE_PER_SECOND * delta
	if state.cash >= due:
		state.cash -= due
		state.lifetime_wages_paid += due
		report["wages_paid"] = float(report["wages_paid"]) + due
		if state.staff_striking:
			state.staff_striking = false
			if allow_events:
				state.add_event("Payroll restored. Staff have resumed moving with intent.")
	elif not state.staff_striking:
		state.staff_striking = true
		if allow_events:
			state.add_event("Payroll missed. Staff are exploring the concept of standing very still.")

func _pay_security_staff(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	if state.security_staff <= 0:
		state.security_staff_on_duty = true
		return
	var due: float = state.security_staff * Formulas.SECURITY_STAFF_WAGE_PER_SECOND * delta
	if state.cash >= due:
		state.cash -= due
		state.lifetime_security_wages += due
		report["security_wages"] = float(report["security_wages"]) + due
		if not state.security_staff_on_duty:
			state.security_staff_on_duty = true
			if allow_events:
				state.add_event("Security payroll restored. Monitoring has resumed monitoring.")
	elif state.security_staff_on_duty:
		state.security_staff_on_duty = false
		if allow_events:
			state.add_event("Security payroll missed. The analysts have stopped watching the blinking lights.")

func _pay_managers(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	var count: int = 0
	for department_id: String in state.managers:
		if bool(state.managers[department_id]):
			count += 1
	if count == 0:
		state.manager_payroll_active = true
		return
	var due: float = count * Formulas.MANAGER_WAGE_PER_SECOND * delta
	if state.cash >= due:
		state.cash -= due
		state.lifetime_manager_wages += due
		report["manager_wages"] = float(report["manager_wages"]) + due
		if not state.manager_payroll_active:
			state.manager_payroll_active = true
			if allow_events:
				state.add_event("Management payroll restored. Delegation has resumed.")
	elif state.manager_payroll_active:
		state.manager_payroll_active = false
		if allow_events:
			state.add_event("Management payroll missed. All automation rules are awaiting executive review.")

func _update_supply_contract(state: GameState, delta: float, allow_events: bool) -> void:
	if state.active_supply_contract.is_empty():
		return
	state.active_supply_contract["time_remaining"] = maxf(0.0, float(state.active_supply_contract.get("time_remaining", 0.0)) - delta)
	if float(state.active_supply_contract["time_remaining"]) <= 0.0:
		var supplier_name: String = str(state.active_supply_contract.get("name", "Supply agreement"))
		state.active_supply_contract = {}
		if allow_events:
			state.add_event("%s expired. Procurement has returned to the thrilling spot market." % supplier_name)

func _run_automation_rules(state: GameState) -> void:
	if not state.manager_payroll_active:
		return
	if bool(state.automation_rules.get("campaign_guardrail", false)) and bool(state.managers.get("sales", false)) and state.cash < state.automation_cash_reserve:
		for channel_id: String in state.advertising_channels:
			state.advertising_channels[channel_id] = false
	if bool(state.automation_rules.get("material_reorder", false)) and bool(state.managers.get("procurement", false)) and state.raw_materials < state.automation_material_target * 0.5:
		var unit_cost: float = Formulas.material_unit_cost(state)
		var affordable: int = floori(maxf(0.0, state.cash - state.automation_cash_reserve) / unit_cost)
		var quantity: int = mini(state.automation_material_target - floori(state.raw_materials), affordable)
		if quantity > 0:
			buy_materials(state, quantity)
	if bool(state.automation_rules.get("preventive_service", false)) and bool(state.managers.get("operations", false)) and state.machine_condition < 0.72:
		var cost: float = Formulas.service_cost(state)
		if state.cash >= cost + state.automation_cash_reserve:
			service_machines(state)
	if bool(state.automation_rules.get("contract_review", false)) and bool(state.managers.get("sales", false)) and not state.contract_offer.is_empty() and state.active_contract.is_empty():
		var price: float = float(state.contract_offer.get("price_per_cell", 0.0))
		var quantity: float = float(state.contract_offer.get("quantity", 0.0))
		var duration: float = float(state.contract_offer.get("duration", 0.0))
		var feasible: bool = quantity <= (Formulas.automated_throughput(state) + 0.4) * duration * 0.8 + state.battery_cells
		var worthwhile: bool = price > Formulas.material_unit_cost(state) + Formulas.energy_cost_per_cell(state)
		if feasible and worthwhile:
			accept_contract(state)

func _update_statistics_history(state: GameState, delta: float) -> void:
	state.statistics_timer += delta
	while state.statistics_timer >= 60.0:
		state.statistics_timer -= 60.0
		state.statistics_history.append({
			"time": state.seconds_played,
			"cash": state.cash,
			"revenue": state.lifetime_revenue,
			"cells_made": state.lifetime_cells_made,
			"cells_sold": state.lifetime_cells_sold,
			"demand_per_minute": state.demand_per_second * 60.0,
			"production_per_minute": Formulas.automated_throughput(state) * 60.0,
			"risk": Formulas.effective_risk(state),
		})
		if state.statistics_history.size() > 120:
			state.statistics_history.pop_front()

func hire_worker(state: GameState, role: String) -> bool:
	if not state.workers.has(role):
		return false
	if int(state.workers[role]) >= Formulas.MAX_WORKERS_PER_ROLE:
		return false
	if state.cash < Formulas.WORKER_HIRING_FEE:
		state.add_event("Hiring paused: the signing bonus exceeds the available money.")
		return false
	state.cash -= Formulas.WORKER_HIRING_FEE
	state.lifetime_hiring_spend += Formulas.WORKER_HIRING_FEE
	state.workers[role] = int(state.workers[role]) + 1
	state.add_event("Hired a %s hand. Onboarding consisted of pointing at the bench." % role)
	return true

func fire_worker(state: GameState, role: String) -> bool:
	if not state.workers.has(role) or int(state.workers[role]) <= 0:
		return false
	state.workers[role] = int(state.workers[role]) - 1
	state.add_event("A %s hand has been thanked for their service and shown the smaller door." % role)
	return true

func cyber_program_cost(state: GameState, program_id: String) -> float:
	if not CYBER_PROGRAMS.has(program_id):
		return INF
	var definition: Dictionary = CYBER_PROGRAMS[program_id]
	var level: int = int(state.get(str(definition["state_field"])))
	return float(definition["base_cost"]) * pow(float(definition["scale"]), level)

func upgrade_cyber_program(state: GameState, program_id: String) -> bool:
	if not CYBER_PROGRAMS.has(program_id):
		return false
	var definition: Dictionary = CYBER_PROGRAMS[program_id]
	var field: String = str(definition["state_field"])
	var level: int = int(state.get(field))
	if level >= 3:
		return false
	var cost: float = cyber_program_cost(state, program_id)
	if state.cash < cost:
		state.add_event("%s deferred: the security budget remains aspirational." % str(definition["name"]))
		return false
	state.cash -= cost
	state.lifetime_upgrade_spend += cost
	state.set(field, level + 1)
	state.add_event("%s advanced to level %d. A diagram has acquired another box." % [str(definition["name"]), level + 1])
	return true

func hire_security_staff(state: GameState) -> bool:
	if state.security_staff >= Formulas.MAX_SECURITY_STAFF:
		return false
	if state.cash < SECURITY_STAFF_HIRING_FEE:
		state.add_event("Security hiring deferred: vigilance has a signing fee.")
		return false
	state.cash -= SECURITY_STAFF_HIRING_FEE
	state.lifetime_hiring_spend += SECURITY_STAFF_HIRING_FEE
	state.security_staff += 1
	state.security_staff_on_duty = true
	state.add_event("Security analyst hired. They have requested logs, a chair, and fewer surprises.")
	return true

func fire_security_staff(state: GameState) -> bool:
	if state.security_staff <= 0:
		return false
	state.security_staff -= 1
	if state.security_staff == 0:
		state.security_staff_on_duty = true
	state.add_event("Security analyst released. Their access badge has entered a review process.")
	return true

func next_factory_cost(state: GameState) -> float:
	return FACTORY_BASE_COST * pow(1.8, state.factories.size())

func buy_factory(state: GameState) -> bool:
	if state.factories.size() >= FACTORY_NAMES.size():
		return false
	var cost: float = next_factory_cost(state)
	if state.cash < cost:
		state.add_event("Factory acquisition deferred: the property brochure exceeds available cash.")
		return false
	var name: String = FACTORY_NAMES[state.factories.size()]
	state.cash -= cost
	state.lifetime_corporate_investment += cost
	state.factories.append({"name": name, "level": 1})
	state.risk += 0.03
	state.add_event("%s acquired. Facilities describes the roof as 'substantially present'." % name)
	return true

func factory_upgrade_cost(state: GameState, index: int) -> float:
	if index < 0 or index >= state.factories.size():
		return INF
	return FACTORY_UPGRADE_BASE_COST * int(state.factories[index].get("level", 1)) * pow(1.35, index)

func upgrade_factory(state: GameState, index: int) -> bool:
	if index < 0 or index >= state.factories.size():
		return false
	var factory: Dictionary = state.factories[index]
	var level: int = int(factory.get("level", 1))
	if level >= 3:
		return false
	var cost: float = factory_upgrade_cost(state, index)
	if state.cash < cost:
		return false
	state.cash -= cost
	state.lifetime_corporate_investment += cost
	factory["level"] = level + 1
	state.factories[index] = factory
	state.risk += 0.015
	state.add_event("%s expanded to level %d. Another clipboard has been issued." % [str(factory["name"]), level + 1])
	return true

func department_cost(state: GameState, department_id: String) -> float:
	if not DEPARTMENTS.has(department_id):
		return INF
	var definition: Dictionary = DEPARTMENTS[department_id]
	var level: int = int(state.department_levels.get(department_id, 0))
	return float(definition["base_cost"]) * pow(float(definition["scale"]), level)

func invest_department(state: GameState, department_id: String) -> bool:
	if not DEPARTMENTS.has(department_id):
		return false
	var level: int = int(state.department_levels.get(department_id, 0))
	if level >= 3:
		return false
	var cost: float = department_cost(state, department_id)
	if state.cash < cost:
		return false
	state.cash -= cost
	state.lifetime_corporate_investment += cost
	state.department_levels[department_id] = level + 1
	state.add_event("%s department advanced to level %d. Its shared drive now has folders." % [str(DEPARTMENTS[department_id]["name"]), level + 1])
	return true

func hire_manager(state: GameState, department_id: String) -> bool:
	if not state.managers.has(department_id) or bool(state.managers[department_id]):
		return false
	if int(state.department_levels.get(department_id, 0)) <= 0 or state.cash < MANAGER_HIRING_FEE:
		return false
	state.cash -= MANAGER_HIRING_FEE
	state.lifetime_corporate_investment += MANAGER_HIRING_FEE
	state.managers[department_id] = true
	state.manager_payroll_active = true
	state.add_event("%s manager appointed. A recurring meeting has appeared." % department_id.capitalize())
	return true

func fire_manager(state: GameState, department_id: String) -> bool:
	if not state.managers.has(department_id) or not bool(state.managers[department_id]):
		return false
	state.managers[department_id] = false
	state.add_event("%s manager removed. The recurring meeting remains." % department_id.capitalize())
	return true

func set_automation_rule(state: GameState, rule_id: String, enabled: bool) -> bool:
	if not state.automation_rules.has(rule_id):
		return false
	if bool(state.automation_rules[rule_id]) == enabled:
		return true
	var required_manager: String = {
		"material_reorder": "procurement",
		"preventive_service": "operations",
		"campaign_guardrail": "sales",
		"contract_review": "sales",
	}.get(rule_id, "")
	if enabled and (required_manager.is_empty() or not bool(state.managers.get(required_manager, false))):
		state.add_event("Automation rule unavailable: appoint the %s manager first." % required_manager.capitalize())
		return false
	state.automation_rules[rule_id] = enabled
	state.add_event("%s automation rule %s." % [rule_id.replace("_", " ").capitalize(), "enabled" if enabled else "disabled"])
	return true

func sign_supply_contract(state: GameState, plan_id: String) -> bool:
	if not SUPPLY_PLANS.has(plan_id) or not state.active_supply_contract.is_empty():
		return false
	var plan: Dictionary = SUPPLY_PLANS[plan_id]
	var fee: float = float(plan["fee"])
	if state.cash < fee:
		return false
	state.cash -= fee
	state.lifetime_corporate_investment += fee
	state.lifetime_supply_contracts += 1
	state.active_supply_contract = {
		"id": plan_id,
		"name": plan["name"],
		"discount": plan["discount"],
		"time_remaining": plan["duration"],
	}
	state.add_event("%s signed. Procurement has secured a predictable argument." % str(plan["name"]))
	return true

func _update_energy_market(state: GameState, delta: float, allow_events: bool) -> void:
	state.energy_market_timer += delta
	while state.energy_market_timer >= 25.0:
		state.energy_market_timer -= 25.0
		var old_price: float = state.energy_price
		state.energy_price = clampf(state.energy_price * (1.0 + rng.randf_range(-0.12, 0.13)), 0.05, 0.35)
		if allow_events and absf(state.energy_price - old_price) >= 0.05:
			var direction: String = "surged" if state.energy_price > old_price else "eased"
			state.add_event("Energy prices have %s to $%s per cell. The utility has revised its opinion of the garage." % [direction, Formulas.format_number(state.energy_price)])

func _update_contracts(state: GameState, delta: float, report: Dictionary) -> void:
	if not state.contract_offer.is_empty():
		state.contract_offer["expires_in"] = float(state.contract_offer.get("expires_in", 0.0)) - delta
		if float(state.contract_offer["expires_in"]) <= 0.0:
			state.contract_offer = {}
			state.add_event("The contract offer has lapsed. The client has chosen a competitor, or possibly a nap.")

	if not state.active_contract.is_empty():
		var remaining: float = float(state.active_contract.get("remaining", 0.0))
		var delivered: float = minf(state.battery_cells, remaining)
		if delivered > 0.0:
			state.battery_cells -= delivered
			state.lifetime_cells_sold += delivered
			state.active_contract["remaining"] = remaining - delivered
		if float(state.active_contract["remaining"]) <= 0.0001:
			var value: float = float(state.active_contract.get("value", 0.0))
			state.cash += value
			state.lifetime_revenue += value
			state.lifetime_contract_revenue += value
			state.lifetime_contracts_completed += 1
			var completed_tier: String = str(state.active_contract.get("tier", "Open Market"))
			state.lifetime_contracts_by_tier[completed_tier] = int(state.lifetime_contracts_by_tier.get(completed_tier, 0)) + 1
			state.trust = minf(state.trust + 0.01, 1.0)
			_adjust_reputation(state, "general", 1.0)
			_adjust_reputation(state, "delivery", 2.5)
			var delivered_quality: float = Formulas.effective_quality(state)
			_adjust_reputation(state, "quality", clampf((delivered_quality - 0.8) * 3.0, -1.0, 2.0))
			report["revenue"] = float(report["revenue"]) + value
			state.add_event("Contract fulfilled for $%s. The client says the batteries 'arrived', which Legal counts as praise." % Formulas.format_number(value))
			state.active_contract = {}
		else:
			state.active_contract["time_remaining"] = float(state.active_contract.get("time_remaining", 0.0)) - delta
			if float(state.active_contract["time_remaining"]) <= 0.0:
				var value_failed: float = float(state.active_contract.get("value", 0.0))
				var penalty: float = minf(state.cash, value_failed * 0.1)
				state.cash -= penalty
				state.lifetime_contracts_failed += 1
				state.trust = maxf(state.trust - 0.06, -0.4)
				_adjust_reputation(state, "general", -3.0)
				_adjust_reputation(state, "delivery", -7.0)
				state.add_event("Contract missed. Penalty paid: $%s. The client's review contains the word 'nevertheless'." % Formulas.format_number(penalty))
				state.active_contract = {}

	if state.contract_offer.is_empty() and state.active_contract.is_empty():
		state.contract_timer += delta
		if state.contract_timer >= CONTRACT_OFFER_PERIOD:
			state.contract_timer = 0.0
			state.contract_offer = _generate_contract_offer(state)
			state.add_event("Contract offer from %s: %s cells at $%s each. They sound serious." % [
				str(state.contract_offer["buyer"]),
				Formulas.format_number(float(state.contract_offer["quantity"])),
				Formulas.format_number(float(state.contract_offer["price_per_cell"]))
			])

func _generate_contract_offer(state: GameState) -> Dictionary:
	var eligible_tiers: Array[Dictionary] = []
	for tier: Dictionary in CONTRACT_TIERS:
		if _meets_reputation_requirements(state, tier.get("requirements", {})):
			eligible_tiers.append(tier)
	var selected_tier: Dictionary = eligible_tiers.back()
	var rate: float = maxf(0.3, Formulas.automated_throughput(state) + 0.4)
	var quantity: float = ceilf(rate * rng.randf_range(50.0, 120.0) * float(selected_tier["quantity_scale"]))
	var fair: float = maxf(0.25, state.base_value * Formulas.effective_quality(state))
	var price_per_cell: float = snappedf(fair * rng.randf_range(0.95, 1.3) * float(selected_tier["price_scale"]), 0.01)
	var duration: float = ceilf((quantity / rate) * rng.randf_range(1.4, 1.9))
	return {
		"buyer": CONTRACT_BUYERS[rng.randi_range(0, CONTRACT_BUYERS.size() - 1)],
		"quantity": quantity,
		"price_per_cell": price_per_cell,
		"duration": duration,
		"expires_in": CONTRACT_OFFER_LIFETIME,
		"tier": selected_tier["name"],
		"requirements": selected_tier["requirements"].duplicate(),
	}

func next_contract_tier(state: GameState) -> Dictionary:
	for tier: Dictionary in CONTRACT_TIERS:
		if not _meets_reputation_requirements(state, tier.get("requirements", {})):
			return tier
	return {}

func accept_contract(state: GameState) -> bool:
	if state.contract_offer.is_empty() or not state.active_contract.is_empty():
		return false
	if not _meets_reputation_requirements(state, state.contract_offer.get("requirements", {})):
		state.add_event("Contract blocked: Procurement rechecked the reputation spreadsheet.")
		return false
	var quantity: float = float(state.contract_offer.get("quantity", 0.0))
	var price: float = float(state.contract_offer.get("price_per_cell", 0.0))
	state.active_contract = {
		"buyer": state.contract_offer.get("buyer", "an anonymous client"),
		"quantity": quantity,
		"remaining": quantity,
		"price_per_cell": price,
		"value": quantity * price,
		"time_remaining": float(state.contract_offer.get("duration", 60.0)),
		"tier": state.contract_offer.get("tier", "Open Market"),
	}
	state.contract_offer = {}
	state.add_event("Contract signed with %s. Legal has aligned the fonts." % str(state.active_contract["buyer"]))
	return true

func decline_contract(state: GameState) -> bool:
	if state.contract_offer.is_empty():
		return false
	state.contract_offer = {}
	state.add_event("Offer declined. The client has been wished 'all the best' at market rates.")
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
	state.lifetime_maintenance_spend += cost
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
	state.lifetime_upgrade_spend += cost
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
	_adjust_reputation(state, "general", float(effects.get("trust_add", 0.0)) * 50.0)
	state.warehouse_capacity += float(effects.get("warehouse_capacity_add", 0.0))
	state.wear_reduction += float(effects.get("wear_reduction_add", 0.0))
	state.prep_rate += float(effects.get("prep_rate_add", 0.0))
	state.testing_rate += float(effects.get("testing_rate_add", 0.0))
	state.energy_discount += float(effects.get("energy_discount_add", 0.0))

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

func _update_competitor_market(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	state.competitor_market_timer += delta
	while state.competitor_market_timer >= COMPETITOR_MARKET_PERIOD:
		state.competitor_market_timer -= COMPETITOR_MARKET_PERIOD
		state.competitor_price = clampf(state.competitor_price * (1.0 + rng.randf_range(-0.12, 0.12)), 2.5, 9.0)
		state.competitor_quality = clampf(state.competitor_quality + rng.randf_range(-0.04, 0.04), 0.75, 1.35)
		report["competitor_events"] = int(report["competitor_events"]) + 1
		if allow_events:
			state.add_event("%s revised its offer to $%s at %.2f quality. Competitive Intelligence used binoculars." % [
				state.competitor_name,
				Formulas.format_number(state.competitor_price),
				state.competitor_quality
			])

func _update_security_events(state: GameState, delta: float, allow_events: bool, report: Dictionary) -> void:
	if not allow_events or security_events.is_empty():
		return
	state.security_event_timer += delta
	while state.security_event_timer >= security_event_period:
		state.security_event_timer -= security_event_period
		var event_chance: float = security_base_chance + Formulas.effective_risk(state) * security_risk_chance_scale
		if rng.randf() > event_chance:
			_adjust_reputation(state, "security", 0.35)
			continue
		var event: Dictionary = _pick_security_event()
		var detected: bool = rng.randf() < Formulas.detection_strength(state)
		if detected:
			state.lifetime_threats_detected += 1
			report["threats_detected"] = int(report["threats_detected"]) + 1
			if rng.randf() < Formulas.response_strength(state):
				state.lifetime_incidents_contained += 1
				report["incidents_contained"] = int(report["incidents_contained"]) + 1
				state.last_security_incident = {
					"status": "contained",
					"type": str(event.get("type", "cash")),
					"zone": _event_zone(event),
					"message": str(event.get("message", "Threat detected.")),
				}
				_adjust_reputation(state, "security", 0.6)
				state.add_event("Threat detected and contained in %s. Incident Response has opened and immediately closed a ticket." % _event_zone(event))
				continue
		_trigger_security_event(state, event, report, detected)

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

func _trigger_security_event(state: GameState, event: Dictionary, report: Dictionary, detected: bool = false) -> void:
	var recovery_mitigation: float = 1.0 - Formulas.recovery_strength(state)
	var segmentation_mitigation: float = 1.0 - Formulas.segmentation_mitigation(state)
	var response_mitigation: float = 1.0 - Formulas.response_strength(state) * (0.65 if detected else 0.25)
	var mitigation: float = recovery_mitigation * segmentation_mitigation * response_mitigation
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
			var lost_cells: int = 0 if state.battery_cells < 1.0 else mini(roundi(state.battery_cells), maxi(1, roundi(state.battery_cells * severity)))
			var lost_premium_cells: int = 0 if state.premium_cells < 1.0 else mini(roundi(state.premium_cells), maxi(1, roundi(state.premium_cells * severity)))
			state.battery_cells -= lost_cells
			state.premium_cells -= lost_premium_cells
			var value: float = lost_cells * state.sale_price + lost_premium_cells * state.premium_sale_price
			state.lifetime_security_losses += value
			report["security_losses"] = float(report["security_losses"]) + value
			detail = "Stock written off: %s cells." % Formulas.format_number(lost_cells + lost_premium_cells)
		"downtime":
			state.production_downtime += severity
			detail = "Automation offline for %ds." % roundi(severity)
	report["security_events"] = int(report["security_events"]) + 1
	state.lifetime_incidents_suffered += 1
	state.last_security_incident = {
		"status": "mitigated" if detected else "suffered",
		"type": str(event.get("type", "cash")),
		"zone": _event_zone(event),
		"message": message,
	}
	var security_damage: float = clampf(2.5 * (1.0 - Formulas.recovery_strength(state)) + Formulas.effective_risk(state) * 2.0, 1.0, 4.0)
	_adjust_reputation(state, "security", -security_damage)
	_adjust_reputation(state, "general", -0.25)
	state.add_event("%s%s %s" % ["Detected before impact: " if detected else "", message, detail])

func _event_zone(event: Dictionary) -> String:
	match str(event.get("type", "cash")):
		"cash":
			return "Office Systems"
		"inventory", "downtime":
			return "Production"
		_:
			return "Workshop LAN"

func _meets_reputation_requirements(state: GameState, requirements: Dictionary) -> bool:
	for category: String in requirements:
		if float(state.reputation.get(category, 0.0)) < float(requirements[category]):
			return false
	return true

func _adjust_reputation(state: GameState, category: String, amount: float) -> void:
	state.reputation[category] = clampf(float(state.reputation.get(category, 50.0)) + amount, 0.0, 100.0)

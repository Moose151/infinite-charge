extends Control

const UPGRADE_PATH: String = "res://data/upgrades/garage_upgrades.json"

var state: GameState = GameState.new()
var simulation: Simulation = Simulation.new()
var upgrades: Array[Dictionary] = []
var upgrade_buttons: Dictionary = {}
var autosave_timer: float = 0.0

var cash_label: Label
var materials_label: Label
var inventory_label: Label
var price_label: Label
var demand_label: Label
var sales_label: Label
var production_label: Label
var market_label: Label
var material_price_label: Label
var risk_label: Label
var stats_label: Label
var event_log_label: RichTextLabel
var offline_report_label: RichTextLabel
var price_slider: HSlider
var pause_button: CheckButton
var speed_option: OptionButton
var autosave_spin: SpinBox
var offline_limit_spin: SpinBox
var ui_scale_option: OptionButton
var condition_label: Label
var service_button: Button
var quality_label: Label
var contract_label: Label
var accept_contract_button: Button
var decline_contract_button: Button
var staff_labels: Dictionary = {}
var wage_label: Label

const UI_SCALES: Array[float] = [1.0, 1.25, 1.5, 1.75, 2.0]

func _ready() -> void:
	upgrades = _load_upgrade_data()
	_build_ui()
	state.changed.connect(_refresh_ui)
	var load_error: Error = SaveManager.load_game(state)
	if load_error == OK:
		_apply_offline_progress()
		state.add_event("Save loaded. The company denies having missed you, for tax reasons.")
	else:
		state.add_event("Garage operations initiated. Desk count: one. Desk confidence: moderate.")
	_apply_ui_scale()
	_refresh_ui()

func _process(delta: float) -> void:
	if not state.simulation_paused:
		simulation.advance(state, delta * state.simulation_speed)
	autosave_timer += delta
	if autosave_timer >= state.autosave_interval:
		autosave_timer = 0.0
		SaveManager.save_game(state)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game(state)

func _build_ui() -> void:
	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 18)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 18)
	add_child(root)

	var main: VBoxContainer = VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	root.add_child(main)

	var title: Label = Label.new()
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	title.text = "Infinite Charge" if version.is_empty() else "Infinite Charge v%s" % version
	title.add_theme_font_size_override("font_size", 28)
	main.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Garage-stage operations. Cash, cells, risk, and several spreadsheets pretending this is under control."
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.74, 0.78))
	main.add_child(subtitle)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	main.add_child(body)

	var left_panel: PanelContainer = _make_panel("Company")
	var middle_panel: PanelContainer = _make_panel("Production & Market")
	var right_panel: PanelContainer = _make_panel("Upgrades & Events")
	body.add_child(left_panel)
	body.add_child(middle_panel)
	body.add_child(right_panel)

	var left: VBoxContainer = left_panel.get_node("Margin/Content") as VBoxContainer
	var middle: VBoxContainer = middle_panel.get_node("Margin/Content") as VBoxContainer
	var right: VBoxContainer = right_panel.get_node("Margin/Content") as VBoxContainer

	_add_section_heading(left, "Resources")
	cash_label = _add_label(left)
	materials_label = _add_label(left)
	inventory_label = _add_label(left)
	material_price_label = _add_label(left)
	risk_label = _add_label(left)

	_add_section_heading(left, "Statistics")
	stats_label = _add_label(left)

	_add_section_heading(left, "Contracts")

	contract_label = _add_label(left)

	var contract_buttons: HBoxContainer = HBoxContainer.new()
	contract_buttons.add_theme_constant_override("separation", 8)
	left.add_child(contract_buttons)

	accept_contract_button = Button.new()
	accept_contract_button.text = "Accept"
	accept_contract_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept_contract_button.pressed.connect(func() -> void: simulation.accept_contract(state))
	contract_buttons.add_child(accept_contract_button)

	decline_contract_button = Button.new()
	decline_contract_button.text = "Decline"
	decline_contract_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decline_contract_button.pressed.connect(func() -> void: simulation.decline_contract(state))
	contract_buttons.add_child(decline_contract_button)
	offline_report_label = RichTextLabel.new()
	offline_report_label.fit_content = true
	offline_report_label.scroll_active = false
	offline_report_label.bbcode_enabled = true
	left.add_child(offline_report_label)

	_add_section_heading(middle, "Actions")
	var produce_button: Button = Button.new()
	produce_button.text = "Assemble Cell"
	produce_button.pressed.connect(func() -> void: simulation.manual_produce(state))
	middle.add_child(produce_button)

	var buy_row: HBoxContainer = HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 8)
	middle.add_child(buy_row)
	for quantity: float in [1.0, 10.0, 100.0]:
		var buy_button: Button = Button.new()
		buy_button.text = "Buy %d Material%s" % [int(quantity), "" if quantity == 1.0 else "s"]
		buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_button.pressed.connect(func() -> void: simulation.buy_materials(state, quantity))
		buy_row.add_child(buy_button)

	price_label = _add_label(middle)
	price_slider = HSlider.new()
	price_slider.min_value = 1.0
	price_slider.max_value = 20.0
	price_slider.step = 0.1
	price_slider.value_changed.connect(_on_price_changed)
	middle.add_child(price_slider)

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(tabs)

	var operations_tab: VBoxContainer = _add_tab(tabs, "Operations")
	var staff_tab: VBoxContainer = _add_tab(tabs, "Staff")
	var settings_tab: VBoxContainer = _add_tab(tabs, "Settings")

	_add_section_heading(operations_tab, "Market")
	demand_label = _add_label(operations_tab)
	sales_label = _add_label(operations_tab)
	market_label = _add_label(operations_tab)

	_add_section_heading(operations_tab, "Production")
	production_label = _add_label(operations_tab)
	quality_label = _add_label(operations_tab)

	condition_label = _add_label(operations_tab)
	service_button = Button.new()
	service_button.pressed.connect(func() -> void: simulation.service_machines(state))
	operations_tab.add_child(service_button)

	_add_section_heading(staff_tab, "Stage Staff")
	for role: String in ["prep", "assembly", "testing"]:
		var staff_row: HBoxContainer = HBoxContainer.new()
		staff_row.add_theme_constant_override("separation", 8)
		staff_tab.add_child(staff_row)

		var staff_label: Label = Label.new()
		staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff_labels[role] = staff_label
		staff_row.add_child(staff_label)

		var hire_button: Button = Button.new()
		hire_button.text = "Hire"
		hire_button.pressed.connect(func() -> void: simulation.hire_worker(state, role))
		staff_row.add_child(hire_button)

		var fire_button: Button = Button.new()
		fire_button.text = "Let go"
		fire_button.pressed.connect(func() -> void: simulation.fire_worker(state, role))
		staff_row.add_child(fire_button)

	wage_label = _add_label(staff_tab)

	_add_section_heading(settings_tab, "Simulation")
	pause_button = CheckButton.new()
	pause_button.text = "Pause simulation"
	pause_button.toggled.connect(_on_pause_toggled)
	settings_tab.add_child(pause_button)

	var speed_row: HBoxContainer = HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	settings_tab.add_child(speed_row)

	var speed_label: Label = Label.new()
	speed_label.text = "Speed"
	speed_row.add_child(speed_label)

	speed_option = OptionButton.new()
	speed_option.add_item("0.5x")
	speed_option.add_item("1x")
	speed_option.add_item("2x")
	speed_option.add_item("5x")
	speed_option.item_selected.connect(_on_speed_selected)
	speed_row.add_child(speed_option)

	_add_section_heading(settings_tab, "Saving")
	var autosave_row: HBoxContainer = HBoxContainer.new()
	autosave_row.add_theme_constant_override("separation", 8)
	settings_tab.add_child(autosave_row)

	var autosave_label: Label = Label.new()
	autosave_label.text = "Autosave seconds"
	autosave_row.add_child(autosave_label)

	autosave_spin = SpinBox.new()
	autosave_spin.min_value = 5.0
	autosave_spin.max_value = 300.0
	autosave_spin.step = 5.0
	autosave_spin.value_changed.connect(_on_autosave_changed)
	autosave_row.add_child(autosave_spin)

	var scale_row: HBoxContainer = HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 8)
	settings_tab.add_child(scale_row)

	var scale_label: Label = Label.new()
	scale_label.text = "Interface scale"
	scale_row.add_child(scale_label)

	ui_scale_option = OptionButton.new()
	for scale: float in UI_SCALES:
		ui_scale_option.add_item("%d%%" % roundi(scale * 100.0))
	ui_scale_option.item_selected.connect(_on_ui_scale_selected)
	scale_row.add_child(ui_scale_option)

	var offline_row: HBoxContainer = HBoxContainer.new()
	offline_row.add_theme_constant_override("separation", 8)
	settings_tab.add_child(offline_row)

	var offline_label: Label = Label.new()
	offline_label.text = "Offline hours"
	offline_row.add_child(offline_label)

	offline_limit_spin = SpinBox.new()
	offline_limit_spin.min_value = 1.0
	offline_limit_spin.max_value = 72.0
	offline_limit_spin.step = 1.0
	offline_limit_spin.value_changed.connect(_on_offline_limit_changed)
	offline_row.add_child(offline_limit_spin)

	var save_button: Button = Button.new()
	save_button.text = "Manual Save"
	save_button.pressed.connect(_manual_save)
	settings_tab.add_child(save_button)

	_add_section_heading(right, "Upgrades")
	var upgrade_list: VBoxContainer = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 6)
	right.add_child(upgrade_list)
	for definition: Dictionary in upgrades:
		var button: Button = Button.new()
		button.text = str(definition.get("name", "Upgrade"))
		button.tooltip_text = str(definition.get("description", ""))
		button.pressed.connect(_on_upgrade_pressed.bind(definition))
		upgrade_buttons[str(definition.get("id", ""))] = button
		upgrade_list.add_child(button)

	_add_section_heading(right, "Event Log")
	event_log_label = RichTextLabel.new()
	event_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log_label.bbcode_enabled = true
	right.add_child(event_log_label)

func _make_panel(title: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(280.0, 0.0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.085, 0.105, 0.12)
	style.border_color = Color(0.18, 0.24, 0.28)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var heading: Label = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color(0.92, 0.95, 0.96))
	box.add_child(heading)

	return panel

func _add_tab(parent: TabContainer, title: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return box

func _add_section_heading(parent: Control, text: String) -> Label:
	var heading: Label = Label.new()
	heading.text = text.to_upper()
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color(0.45, 0.72, 0.84))
	parent.add_child(heading)
	return heading

func _add_label(parent: Control) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.82, 0.87, 0.89))
	parent.add_child(label)
	return label

func _on_price_changed(value: float) -> void:
	state.sale_price = value
	state.demand_per_second = Formulas.demand_per_second(state)
	state.notify_changed()

func _on_upgrade_pressed(definition: Dictionary) -> void:
	simulation.buy_upgrade(state, definition)

func _on_pause_toggled(toggled_on: bool) -> void:
	state.simulation_paused = toggled_on
	state.add_event("Simulation paused. Productivity has entered a reflective period." if toggled_on else "Simulation resumed. Reflection has been deprioritised.")

func _on_speed_selected(index: int) -> void:
	var speeds: Array[float] = [0.5, 1.0, 2.0, 5.0]
	state.simulation_speed = speeds[clampi(index, 0, speeds.size() - 1)]
	state.add_event("Simulation speed set to %sx." % Formulas.format_number(state.simulation_speed))

func _on_autosave_changed(value: float) -> void:
	state.autosave_interval = value
	autosave_timer = 0.0
	state.notify_changed()

func _on_ui_scale_selected(index: int) -> void:
	state.ui_scale = UI_SCALES[clampi(index, 0, UI_SCALES.size() - 1)]
	_apply_ui_scale()
	state.notify_changed()

func _apply_ui_scale() -> void:
	get_window().content_scale_factor = state.ui_scale

func _on_offline_limit_changed(value: float) -> void:
	state.offline_limit_seconds = value * 60.0 * 60.0
	state.notify_changed()

func _manual_save() -> void:
	var error: Error = SaveManager.save_game(state)
	if error == OK:
		state.add_event("Manual save completed. Accountability has been assigned.")
	else:
		state.add_event("Manual save failed with error code %d." % error)

func _refresh_ui() -> void:
	if cash_label == null:
		return
	state.demand_per_second = Formulas.demand_per_second(state)
	if not is_equal_approx(price_slider.value, state.sale_price):
		price_slider.set_value_no_signal(state.sale_price)
	if pause_button.button_pressed != state.simulation_paused:
		pause_button.set_pressed_no_signal(state.simulation_paused)
	_sync_speed_option()
	if not is_equal_approx(autosave_spin.value, state.autosave_interval):
		autosave_spin.set_value_no_signal(state.autosave_interval)
	var offline_hours: float = state.offline_limit_seconds / 3600.0
	if not is_equal_approx(offline_limit_spin.value, offline_hours):
		offline_limit_spin.set_value_no_signal(offline_hours)
	_sync_ui_scale_option()
	cash_label.text = "Cash: $%s" % Formulas.format_number(state.cash)
	materials_label.text = "Materials: %s units" % Formulas.format_number(state.raw_materials)
	inventory_label.text = "Battery inventory: %s / %s cells (worth $%s at current price)" % [
		Formulas.format_number(state.battery_cells),
		Formulas.format_number(state.warehouse_capacity),
		Formulas.format_number(state.battery_cells * state.sale_price)
	]
	material_price_label.text = "Material price: $%s/unit" % Formulas.format_number(Formulas.material_unit_cost(state))
	var operations_risk: float = maxf(0.0, state.risk - 0.06)
	risk_label.text = "Security risk: %d%% (base 6%% + operations %d%% - defenses %d%%)" % [
		roundi(Formulas.effective_risk(state) * 100.0),
		roundi(operations_risk * 100.0),
		roundi(state.risk_reduction * 100.0)
	]
	stats_label.text = "Lifetime made: %s cells\nLifetime sold: %s cells\nLifetime revenue: $%s\nMaterials bought: %s\nSecurity losses: $%s\nSales lost to stock-outs: %s cells\nEnergy paid: $%s | Wages paid: $%s\nTime operated: %s" % [
		Formulas.format_number(state.lifetime_cells_made),
		Formulas.format_number(state.lifetime_cells_sold),
		Formulas.format_number(state.lifetime_revenue),
		Formulas.format_number(state.lifetime_materials_bought),
		Formulas.format_number(state.lifetime_security_losses),
		Formulas.format_number(state.lifetime_sales_lost),
		Formulas.format_number(state.lifetime_energy_cost),
		Formulas.format_number(state.lifetime_wages_paid),
		_format_duration(state.seconds_played)
	]
	price_label.text = "Sale price: $%s/cell" % Formulas.format_number(state.sale_price)
	demand_label.text = "Potential demand: %s cells/sec" % Formulas.format_number(state.demand_per_second)
	sales_label.text = "Current sales: %s cells/sec" % Formulas.format_number(state.sales_per_second)
	if state.production_downtime > 0.0:
		production_label.text = "Automation: OFFLINE for %ds (incident response) | Manual batch: %s" % [
			ceili(state.production_downtime),
			Formulas.format_number(state.manual_output)
		]
	elif Formulas.automated_throughput(state) > 0.0:
		var staffed_prep: float = Formulas.staffed_prep_rate(state)
		var staffed_assembly: float = Formulas.staffed_assembly_rate(state)
		var bottleneck: String = " (prep-limited)" if staffed_prep < staffed_assembly else " (assembly-limited)"
		production_label.text = "Stages: prep %s/s | assembly %s/s | testing %s/s\nAutomated output: %s cells/sec%s | Manual batch: %s" % [
			Formulas.format_number(staffed_prep),
			Formulas.format_number(staffed_assembly),
			Formulas.format_number(Formulas.staffed_testing_rate(state)),
			Formulas.format_number(Formulas.automated_throughput(state)),
			bottleneck,
			Formulas.format_number(state.manual_output)
		]
	else:
		production_label.text = "Automation: none yet | Manual batch: %s" % Formulas.format_number(state.manual_output)
	quality_label.text = "Product quality: %.2f (design %.2f x condition %d%% x testing coverage %d%%)" % [
		Formulas.effective_quality(state),
		state.quality,
		roundi((0.8 + 0.2 * clampf(state.machine_condition, 0.0, 1.0)) * 100.0),
		roundi(Formulas.testing_coverage(state) * 100.0)
	]
	_update_maintenance_row()
	_update_contracts_section()
	_update_staff_section()
	var estimated_margin: float = Formulas.estimated_margin_per_cell(state) - Formulas.energy_cost_per_cell(state)
	var sell_through: float = Formulas.sell_through_per_second(state)
	market_label.text = "Estimated margin: $%s/cell (after materials and energy at $%s/cell)\nInventory sell-through: %s cells/sec\nDemand note: lower prices sell faster; quality, trust, and risk also move demand." % [
		Formulas.format_number(estimated_margin),
		Formulas.format_number(Formulas.energy_cost_per_cell(state)),
		Formulas.format_number(sell_through)
	]
	_update_upgrade_buttons()
	_update_event_log()
	_update_offline_report()

func _update_maintenance_row() -> void:
	if state.production_per_second <= 0.0:
		condition_label.visible = false
		service_button.visible = false
		return
	condition_label.visible = true
	service_button.visible = true
	condition_label.text = "Machine condition: %d%% (efficiency %d%%)" % [
		roundi(state.machine_condition * 100.0),
		roundi(Formulas.machine_efficiency(state) * 100.0)
	]
	var cost: float = Formulas.service_cost(state)
	if state.machine_condition >= 0.995:
		service_button.text = "Service Machines (not needed)"
		service_button.disabled = true
	else:
		service_button.text = "Service Machines - $%s" % Formulas.format_number(cost)
		service_button.disabled = state.cash < cost

func _update_staff_section() -> void:
	for role: String in staff_labels:
		var count: int = int(state.workers.get(role, 0))
		var label: Label = staff_labels[role] as Label
		label.text = "%s: %d/%d (+%s/s each)" % [
			role.capitalize(),
			count,
			Formulas.MAX_WORKERS_PER_ROLE,
			Formulas.format_number(Formulas.WORKER_STAGE_RATE)
		]
	var total: int = Formulas.total_workers(state)
	if total == 0:
		wage_label.text = "No staff. The org chart is a dot."
	elif state.staff_striking:
		wage_label.text = "Wages: UNPAID - staff are on strike until payroll clears ($%s/s owed)." % Formulas.format_number(total * Formulas.WORKER_WAGE_PER_SECOND)
	else:
		wage_label.text = "Wages: $%s/s | Hiring fee: $%s" % [
			Formulas.format_number(total * Formulas.WORKER_WAGE_PER_SECOND),
			Formulas.format_number(Formulas.WORKER_HIRING_FEE)
		]

func _update_contracts_section() -> void:
	var has_offer: bool = not state.contract_offer.is_empty()
	accept_contract_button.visible = has_offer
	decline_contract_button.visible = has_offer
	if not state.active_contract.is_empty():
		var contract: Dictionary = state.active_contract
		contract_label.text = "Active: %s cells for %s ($%s each)\nDelivered: %s / %s | Time left: %s" % [
			Formulas.format_number(float(contract.get("quantity", 0.0))),
			str(contract.get("buyer", "a client")),
			Formulas.format_number(float(contract.get("price_per_cell", 0.0))),
			Formulas.format_number(float(contract.get("quantity", 0.0)) - float(contract.get("remaining", 0.0))),
			Formulas.format_number(float(contract.get("quantity", 0.0))),
			_format_duration(float(contract.get("time_remaining", 0.0)))
		]
	elif has_offer:
		var offer: Dictionary = state.contract_offer
		contract_label.text = "Offer from %s:\n%s cells at $%s each (total $%s)\nDeadline once signed: %s | Offer expires: %s" % [
			str(offer.get("buyer", "a client")),
			Formulas.format_number(float(offer.get("quantity", 0.0))),
			Formulas.format_number(float(offer.get("price_per_cell", 0.0))),
			Formulas.format_number(float(offer.get("quantity", 0.0)) * float(offer.get("price_per_cell", 0.0))),
			_format_duration(float(offer.get("duration", 0.0))),
			_format_duration(float(offer.get("expires_in", 0.0)))
		]
	else:
		contract_label.text = "No offers right now. Completed: %d | Missed: %d | Contract revenue: $%s" % [
			state.lifetime_contracts_completed,
			state.lifetime_contracts_failed,
			Formulas.format_number(state.lifetime_contract_revenue)
		]

func _sync_ui_scale_option() -> void:
	var selected_index: int = 0
	for index: int in range(UI_SCALES.size()):
		if is_equal_approx(UI_SCALES[index], state.ui_scale):
			selected_index = index
	if ui_scale_option.selected != selected_index:
		ui_scale_option.select(selected_index)

func _sync_speed_option() -> void:
	var speeds: Array[float] = [0.5, 1.0, 2.0, 5.0]
	var selected_index: int = 1
	for index: int in range(speeds.size()):
		if is_equal_approx(speeds[index], state.simulation_speed):
			selected_index = index
	if speed_option.selected != selected_index:
		speed_option.select(selected_index)

func _update_upgrade_buttons() -> void:
	for definition: Dictionary in upgrades:
		var id: String = str(definition.get("id", ""))
		var button: Button = upgrade_buttons.get(id) as Button
		if button == null:
			continue
		var level: int = int(state.upgrade_levels.get(id, 0))
		var max_level: int = int(definition.get("max_level", 1))
		if level >= max_level:
			button.text = "%s: max" % str(definition.get("name", "Upgrade"))
			button.disabled = true
		else:
			var cost: float = Formulas.upgrade_cost(definition, level)
			button.text = "%s %d/%d - $%s" % [
				str(definition.get("name", "Upgrade")),
				level,
				max_level,
				Formulas.format_number(cost)
			]
			button.disabled = state.cash < cost

func _update_event_log() -> void:
	var lines: Array[String] = []
	for message: String in state.event_log.slice(0, 12):
		lines.append("[color=#d6dde3]%s[/color]" % message)
	event_log_label.text = "\n".join(lines)

func _update_offline_report() -> void:
	if state.offline_report.is_empty():
		offline_report_label.text = ""
		return
	var report: Dictionary = state.offline_report
	offline_report_label.text = "[b]Offline report[/b]\nTime away: %s\nMade: %s cells\nSold: %s cells\nRevenue: $%s" % [
		_format_duration(float(report.get("seconds", 0.0))),
		Formulas.format_number(float(report.get("cells_made", 0.0))),
		Formulas.format_number(float(report.get("cells_sold", 0.0))),
		Formulas.format_number(float(report.get("revenue", 0.0)))
	]

func _load_upgrade_data() -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(UPGRADE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load upgrade data.")
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Upgrade data must be an array.")
		return []
	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			result.append(item)
	return result

func _apply_offline_progress() -> void:
	if state.last_saved_unix_time <= 0:
		return
	var now: int = Time.get_unix_time_from_system()
	var seconds_away: float = clampf(float(now - state.last_saved_unix_time), 0.0, state.offline_limit_seconds)
	if seconds_away < 5.0:
		return
	state.offline_report = simulation.advance_chunked(state, seconds_away, false)

func _format_duration(seconds: float) -> String:
	var total: int = roundi(seconds)
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	var secs: int = total % 60
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	if minutes > 0:
		return "%dm %ds" % [minutes, secs]
	return "%ds" % secs

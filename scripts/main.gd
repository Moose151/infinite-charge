extends Control

const UPGRADE_PATH: String = "res://data/upgrades/garage_upgrades.json"
const AUTOSAVE_INTERVAL: float = 10.0
const MAX_OFFLINE_SECONDS: float = 60.0 * 60.0 * 8.0

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
var material_price_label: Label
var risk_label: Label
var stats_label: Label
var event_log_label: RichTextLabel
var offline_report_label: RichTextLabel
var price_slider: HSlider

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
	_refresh_ui()

func _process(delta: float) -> void:
	simulation.advance(state, delta)
	autosave_timer += delta
	if autosave_timer >= AUTOSAVE_INTERVAL:
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
	title.text = "Infinite Charge"
	title.add_theme_font_size_override("font_size", 28)
	main.add_child(title)

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

	cash_label = _add_label(left)
	materials_label = _add_label(left)
	inventory_label = _add_label(left)
	material_price_label = _add_label(left)
	risk_label = _add_label(left)
	stats_label = _add_label(left)
	offline_report_label = RichTextLabel.new()
	offline_report_label.fit_content = true
	offline_report_label.scroll_active = false
	offline_report_label.bbcode_enabled = true
	left.add_child(offline_report_label)

	var produce_button: Button = Button.new()
	produce_button.text = "Assemble Cell"
	produce_button.pressed.connect(func() -> void: simulation.manual_produce(state))
	middle.add_child(produce_button)

	var buy_materials_button: Button = Button.new()
	buy_materials_button.text = "Buy 10 Materials"
	buy_materials_button.pressed.connect(func() -> void: simulation.buy_materials(state, 10.0))
	middle.add_child(buy_materials_button)

	price_label = _add_label(middle)
	price_slider = HSlider.new()
	price_slider.min_value = 1.0
	price_slider.max_value = 20.0
	price_slider.step = 0.1
	price_slider.value_changed.connect(_on_price_changed)
	middle.add_child(price_slider)

	demand_label = _add_label(middle)
	sales_label = _add_label(middle)
	production_label = _add_label(middle)

	var save_button: Button = Button.new()
	save_button.text = "Manual Save"
	save_button.pressed.connect(_manual_save)
	middle.add_child(save_button)

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

	event_log_label = RichTextLabel.new()
	event_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log_label.bbcode_enabled = true
	right.add_child(event_log_label)

func _make_panel(title: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

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
	box.add_child(heading)

	return panel

func _add_label(parent: Control) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _on_price_changed(value: float) -> void:
	state.sale_price = value
	state.demand_per_second = Formulas.demand_per_second(state)
	state.notify_changed()

func _on_upgrade_pressed(definition: Dictionary) -> void:
	simulation.buy_upgrade(state, definition)

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
	cash_label.text = "Cash: $%s" % Formulas.format_number(state.cash)
	materials_label.text = "Materials: %s units" % Formulas.format_number(state.raw_materials)
	inventory_label.text = "Battery inventory: %s cells" % Formulas.format_number(state.battery_cells)
	material_price_label.text = "Material price: $%s/unit" % Formulas.format_number(Formulas.material_unit_cost(state))
	risk_label.text = "Security risk: %d%%" % roundi(Formulas.effective_risk(state) * 100.0)
	stats_label.text = "Lifetime sold: %s cells\nLifetime revenue: $%s\nSecurity losses: $%s" % [
		Formulas.format_number(state.lifetime_cells_sold),
		Formulas.format_number(state.lifetime_revenue),
		Formulas.format_number(state.lifetime_security_losses)
	]
	price_label.text = "Sale price: $%s/cell" % Formulas.format_number(state.sale_price)
	demand_label.text = "Potential demand: %s cells/sec" % Formulas.format_number(state.demand_per_second)
	sales_label.text = "Current sales: %s cells/sec" % Formulas.format_number(state.sales_per_second)
	production_label.text = "Automation: %s cells/sec | Manual batch: %s" % [
		Formulas.format_number(state.production_per_second),
		Formulas.format_number(state.manual_output)
	]
	_update_upgrade_buttons()
	_update_event_log()
	_update_offline_report()

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
	var seconds_away: float = clampf(float(now - state.last_saved_unix_time), 0.0, MAX_OFFLINE_SECONDS)
	if seconds_away < 5.0:
		return
	state.offline_report = simulation.advance(state, seconds_away, false)
	state.offline_report["seconds"] = seconds_away

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

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
var competitor_label: Label
var material_price_label: Label
var risk_label: Label
var stats_label: Label
var event_log_label: RichTextLabel
var offline_report_label: RichTextLabel
var price_slider: HSlider
var premium_price_slider: HSlider
var premium_price_label: Label
var premium_demand_label: Label
var premium_inventory_label: Label
var unlock_product_button: Button
var standard_product_button: Button
var premium_product_button: Button
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
var inventory_bar: ProgressBar
var risk_bar: ProgressBar
var quality_bar: ProgressBar
var condition_bar: ProgressBar
var advertising_buttons: Dictionary = {}
var advertising_label: Label
var status_overview_label: Label
var interface_root: MarginContainer
var interface_background: ColorRect
var theme_option: OptionButton
var mode_option: OptionButton
var produce_button: Button
var material_buy_buttons: Dictionary = {}
var finance_label: Label
var reputation_label: Label
var workshop_stage_label: Label
var workshop_station_labels: Dictionary = {}
var operations_watch_label: Label
var cyber_program_labels: Dictionary = {}
var cyber_program_buttons: Dictionary = {}
var network_map_label: Label
var network_asset_labels: Dictionary = {}
var security_staff_label: Label
var hire_security_button: Button
var fire_security_button: Button
var security_incident_label: Label
var factories_label: Label
var buy_factory_button: Button
var factory_labels: Array[Label] = []
var factory_upgrade_buttons: Array[Button] = []
var department_labels: Dictionary = {}
var department_invest_buttons: Dictionary = {}
var department_manager_buttons: Dictionary = {}
var automation_rule_buttons: Dictionary = {}
var automation_target_spin: SpinBox
var automation_reserve_spin: SpinBox
var supply_contract_label: Label
var supply_contract_buttons: Dictionary = {}
var detailed_stats_label: Label
var research_summary_label: Label
var research_branch_labels: Dictionary = {}
var research_branch_buttons: Dictionary = {}
var research_equipment_labels: Dictionary = {}
var research_equipment_buttons: Dictionary = {}
var long_project_label: Label
var long_project_buttons: Dictionary = {}
var challenge_label: Label
var challenge_buttons: Dictionary = {}

const UI_SCALES: Array[float] = [1.0]
const THEME_IDS: Array[String] = ["workshop", "corporate", "solar"]
const THEME_NAMES: Array[String] = ["Workshop", "Corporate", "Solar"]

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
	_apply_interface_theme()
	_refresh_ui()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_0) and not is_equal_approx(state.ui_scale, 1.0):
		state.ui_scale = 1.0
		_apply_ui_scale()
		state.add_event("Interface scale reset. The zoom committee has been stood down.")
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
	interface_background = ColorRect.new()
	interface_background.color = Color("081116")
	interface_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(interface_background)

	var root: MarginContainer = MarginContainer.new()
	interface_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = _build_interface_theme()
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_right", 16)
	root.add_theme_constant_override("margin_bottom", 14)
	add_child(root)

	var main: VBoxContainer = VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	root.add_child(main)

	var masthead: HBoxContainer = HBoxContainer.new()
	masthead.add_theme_constant_override("separation", 12)
	main.add_child(masthead)

	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(title_stack)

	var title: Label = Label.new()
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	title.text = "Infinite Charge" if version.is_empty() else "Infinite Charge v%s" % version
	title.add_theme_font_size_override("font_size", 30)
	title.theme_type_variation = "TitleLabel"
	title_stack.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "GARAGE OPERATIONS CONSOLE  /  improbable energy, responsibly itemised"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.theme_type_variation = "SubtitleLabel"
	title_stack.add_child(subtitle)

	var status_badge: Label = Label.new()
	status_badge.text = "●  SYSTEM ONLINE"
	status_badge.theme_type_variation = "StatusLabel"
	status_badge.add_theme_font_size_override("font_size", 13)
	status_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	masthead.add_child(status_badge)

	status_overview_label = Label.new()
	status_overview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_overview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_overview_label.theme_type_variation = "OverviewLabel"
	masthead.add_child(status_overview_label)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	main.add_child(body)

	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(560.0, 0.0)
	tabs.add_theme_font_size_override("font_size", 15)
	body.add_child(tabs)

	var operations_panel: PanelContainer = _make_panel("OPERATIONS  ·  Build and keep the line moving")
	operations_panel.name = "Operations"
	tabs.add_child(operations_panel)
	var market_panel: PanelContainer = _make_panel("MARKET  ·  Products, prices and attention")
	market_panel.name = "Market"
	tabs.add_child(market_panel)
	var company_panel: PanelContainer = _make_panel("COMPANY  ·  People, contracts and growth")
	company_panel.name = "Company"
	tabs.add_child(company_panel)
	var corporate_panel: PanelContainer = _make_panel("CORPORATE  ·  Factories, departments and delegation")
	corporate_panel.name = "Corporate"
	tabs.add_child(corporate_panel)
	var research_panel: PanelContainer = _make_panel("RESEARCH  ·  Branches, equipment, projects and challenges")
	research_panel.name = "Research"
	tabs.add_child(research_panel)
	var security_panel: PanelContainer = _make_panel("SECURITY  ·  Map, detect, contain and recover")
	security_panel.name = "Security"
	tabs.add_child(security_panel)
	var office_panel: PanelContainer = _make_panel("OFFICE  ·  Controls and company records")
	office_panel.name = "Office"
	tabs.add_child(office_panel)

	var activity_panel: PanelContainer = _make_panel("LIVE ACTIVITY")
	activity_panel.custom_minimum_size = Vector2(280.0, 0.0)
	activity_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(activity_panel)

	var operations: VBoxContainer = operations_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var market: VBoxContainer = market_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var company: VBoxContainer = company_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var corporate: VBoxContainer = corporate_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var research: VBoxContainer = research_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var security: VBoxContainer = security_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var office: VBoxContainer = office_panel.get_node("Margin/Scroll/Content") as VBoxContainer
	var activity: VBoxContainer = activity_panel.get_node("Margin/Scroll/Content") as VBoxContainer

	var workshop_view_card: VBoxContainer = _make_card(operations, "Garage Floor")
	workshop_stage_label = _add_label(workshop_view_card)
	workshop_stage_label.theme_type_variation = "SubtitleLabel"
	operations_watch_label = _add_label(workshop_view_card)
	operations_watch_label.theme_type_variation = "StatusLabel"
	operations_watch_label.tooltip_text = "Highlights immediate operating constraints from current rates. Forecasts change as production, demand, and inventory change."
	var workshop_grid: GridContainer = GridContainer.new()
	workshop_grid.columns = 3
	workshop_grid.add_theme_constant_override("h_separation", 8)
	workshop_grid.add_theme_constant_override("v_separation", 8)
	workshop_view_card.add_child(workshop_grid)
	for station: Dictionary in [
		{"id": "bench", "title": "ASSEMBLY BENCH"},
		{"id": "prep", "title": "PREP AREA"},
		{"id": "testing", "title": "TEST BAY"},
		{"id": "storage", "title": "STOCKROOM"},
		{"id": "crew", "title": "CREW CORNER"},
		{"id": "security", "title": "SECURITY DESK"},
	]:
		_add_workshop_station(workshop_grid, str(station["id"]), str(station["title"]))

	var workshop_card: VBoxContainer = _make_card(operations, "Quick Actions")
	produce_button = Button.new()
	produce_button.text = "⚡  ASSEMBLE CELL"
	produce_button.custom_minimum_size = Vector2(0.0, 62.0)
	produce_button.add_theme_font_size_override("font_size", 21)
	produce_button.pressed.connect(func() -> void: simulation.manual_produce(state))
	workshop_card.add_child(produce_button)

	var buy_row: HBoxContainer = HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 8)
	workshop_card.add_child(buy_row)
	for quantity: float in [1.0, 10.0, 100.0]:
		var buy_button: Button = Button.new()
		buy_button.text = "Buy %d" % int(quantity)
		buy_button.tooltip_text = "Buy %d component kit%s." % [int(quantity), "" if quantity == 1.0 else "s"]
		buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_button.pressed.connect(func() -> void: simulation.buy_materials(state, quantity))
		material_buy_buttons[int(quantity)] = buy_button
		buy_row.add_child(buy_button)

	var products_card: VBoxContainer = _make_card(market, "Product Line")
	var product_buttons: HBoxContainer = HBoxContainer.new()
	product_buttons.add_theme_constant_override("separation", 8)
	products_card.add_child(product_buttons)
	standard_product_button = Button.new()
	standard_product_button.text = "Make Standard"
	standard_product_button.pressed.connect(func() -> void: simulation.select_product(state, "standard"))
	product_buttons.add_child(standard_product_button)
	premium_product_button = Button.new()
	premium_product_button.text = "Make Long-Life"
	premium_product_button.pressed.connect(func() -> void: simulation.select_product(state, "premium"))
	product_buttons.add_child(premium_product_button)
	unlock_product_button = Button.new()
	unlock_product_button.pressed.connect(func() -> void: simulation.unlock_premium_product(state))
	products_card.add_child(unlock_product_button)
	premium_inventory_label = _add_label(products_card)
	premium_price_label = _add_label(products_card)
	premium_price_slider = HSlider.new()
	premium_price_slider.min_value = 2.0
	premium_price_slider.max_value = 30.0
	premium_price_slider.step = 0.1
	premium_price_slider.value_changed.connect(_on_premium_price_changed)
	products_card.add_child(premium_price_slider)
	premium_demand_label = _add_label(products_card)

	var price_card: VBoxContainer = _make_card(market, "Price Desk")
	price_label = _add_label(price_card)
	price_slider = HSlider.new()
	price_slider.min_value = 1.0
	price_slider.max_value = 20.0
	price_slider.step = 0.1
	price_slider.value_changed.connect(_on_price_changed)
	price_card.add_child(price_slider)
	demand_label = _add_label(price_card)
	sales_label = _add_label(price_card)
	market_label = _add_label(price_card)
	competitor_label = _add_label(price_card)

	var resources_card: VBoxContainer = _make_card(operations, "Stockroom")
	cash_label = _add_label(resources_card)
	materials_label = _add_label(resources_card)
	inventory_label = _add_label(resources_card)
	inventory_bar = _add_meter(resources_card)
	material_price_label = _add_label(resources_card)
	risk_label = _add_label(resources_card)
	risk_bar = _add_meter(resources_card)

	var production_card: VBoxContainer = _make_card(operations, "Production Line")
	production_label = _add_label(production_card)
	quality_label = _add_label(production_card)
	quality_bar = _add_meter(production_card)
	condition_label = _add_label(production_card)
	condition_bar = _add_meter(production_card)
	service_button = Button.new()
	service_button.pressed.connect(func() -> void: simulation.service_machines(state))
	production_card.add_child(service_button)

	var staff_card: VBoxContainer = _make_card(company, "Crew")
	for role: String in ["prep", "assembly", "testing"]:
		var staff_row: HBoxContainer = HBoxContainer.new()
		staff_row.add_theme_constant_override("separation", 8)
		staff_card.add_child(staff_row)

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

	wage_label = _add_label(staff_card)

	var network_card: VBoxContainer = _make_card(security, "Network Map")
	network_map_label = _add_label(network_card)
	network_map_label.theme_type_variation = "SubtitleLabel"
	var network_grid: GridContainer = GridContainer.new()
	network_grid.columns = 2
	network_grid.add_theme_constant_override("h_separation", 8)
	network_grid.add_theme_constant_override("v_separation", 8)
	network_card.add_child(network_grid)
	for node: Dictionary in [
		{"id": "edge", "title": "INTERNET EDGE"},
		{"id": "office", "title": "OFFICE SYSTEMS"},
		{"id": "production", "title": "PRODUCTION"},
		{"id": "recovery", "title": "RECOVERY STORE"},
	]:
		_add_security_node(network_grid, str(node["id"]), str(node["title"]))

	var cyber_controls_card: VBoxContainer = _make_card(security, "Cybersecurity Programme")
	for program: Dictionary in [
		{"id": "segmentation", "title": "Network Zones & Segmentation"},
		{"id": "detection", "title": "Threat Detection"},
		{"id": "response", "title": "Incident Response"},
		{"id": "recovery", "title": "Recovery Planning"},
	]:
		_add_cyber_program_row(cyber_controls_card, str(program["id"]), str(program["title"]))

	var security_staff_card: VBoxContainer = _make_card(security, "Security Staff")
	security_staff_label = _add_label(security_staff_card)
	var security_staff_buttons: HBoxContainer = HBoxContainer.new()
	security_staff_buttons.add_theme_constant_override("separation", 8)
	security_staff_card.add_child(security_staff_buttons)
	hire_security_button = Button.new()
	hire_security_button.text = "Hire analyst"
	hire_security_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hire_security_button.pressed.connect(func() -> void: simulation.hire_security_staff(state))
	security_staff_buttons.add_child(hire_security_button)
	fire_security_button = Button.new()
	fire_security_button.text = "Let go"
	fire_security_button.pressed.connect(func() -> void: simulation.fire_security_staff(state))
	security_staff_buttons.add_child(fire_security_button)

	var incident_card: VBoxContainer = _make_card(security, "Incident Desk")
	security_incident_label = _add_label(incident_card)

	var factories_card: VBoxContainer = _make_card(corporate, "Factory Portfolio")
	factories_label = _add_label(factories_card)
	for factory_index: int in range(Simulation.FACTORY_NAMES.size()):
		var factory_row: HBoxContainer = HBoxContainer.new()
		factory_row.add_theme_constant_override("separation", 8)
		factories_card.add_child(factory_row)
		var factory_label: Label = Label.new()
		factory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		factory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		factory_row.add_child(factory_label)
		factory_labels.append(factory_label)
		var factory_button: Button = Button.new()
		factory_button.pressed.connect(func() -> void: simulation.upgrade_factory(state, factory_index))
		factory_row.add_child(factory_button)
		factory_upgrade_buttons.append(factory_button)
	buy_factory_button = Button.new()
	buy_factory_button.pressed.connect(func() -> void: simulation.buy_factory(state))
	factories_card.add_child(buy_factory_button)

	var departments_card: VBoxContainer = _make_card(corporate, "Departments & Managers")
	for department_id: String in ["operations", "procurement", "sales", "security"]:
		_add_department_row(departments_card, department_id)

	var rules_card: VBoxContainer = _make_card(corporate, "Automation Rules")
	for rule: Dictionary in [
		{"id": "material_reorder", "name": "Procurement: reorder component kits"},
		{"id": "preventive_service", "name": "Operations: service machines at 72%"},
		{"id": "campaign_guardrail", "name": "Sales: pause campaigns at cash reserve"},
		{"id": "contract_review", "name": "Sales: accept feasible profitable contracts"},
	]:
		var rule_id: String = str(rule["id"])
		var toggle: CheckButton = CheckButton.new()
		toggle.text = str(rule["name"])
		toggle.toggled.connect(func(enabled: bool) -> void: _on_automation_rule_toggled(enabled, rule_id))
		rules_card.add_child(toggle)
		automation_rule_buttons[rule_id] = toggle
	var target_row: HBoxContainer = HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 8)
	rules_card.add_child(target_row)
	var target_label: Label = Label.new()
	target_label.text = "Kit target"
	target_row.add_child(target_label)
	automation_target_spin = SpinBox.new()
	automation_target_spin.min_value = 10
	automation_target_spin.max_value = 1000
	automation_target_spin.step = 10
	automation_target_spin.value_changed.connect(_on_automation_target_changed)
	target_row.add_child(automation_target_spin)
	var reserve_label: Label = Label.new()
	reserve_label.text = "Cash reserve"
	target_row.add_child(reserve_label)
	automation_reserve_spin = SpinBox.new()
	automation_reserve_spin.min_value = 0
	automation_reserve_spin.max_value = 10000
	automation_reserve_spin.step = 25
	automation_reserve_spin.prefix = "$"
	automation_reserve_spin.value_changed.connect(_on_automation_reserve_changed)
	target_row.add_child(automation_reserve_spin)

	var supply_card: VBoxContainer = _make_card(corporate, "Supply Contracts")
	supply_contract_label = _add_label(supply_card)
	var supply_buttons_row: HBoxContainer = HBoxContainer.new()
	supply_buttons_row.add_theme_constant_override("separation", 8)
	supply_card.add_child(supply_buttons_row)
	for plan_id: String in ["local", "bulk"]:
		var supply_button: Button = Button.new()
		supply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		supply_button.pressed.connect(func() -> void: simulation.sign_supply_contract(state, plan_id))
		supply_buttons_row.add_child(supply_button)
		supply_contract_buttons[plan_id] = supply_button

	var detailed_stats_card: VBoxContainer = _make_card(corporate, "Detailed Statistics")
	detailed_stats_label = _add_label(detailed_stats_card)

	var research_branches_card: VBoxContainer = _make_card(research, "Research Branches")
	research_summary_label = _add_label(research_branches_card)
	for branch_id: String in ["materials", "manufacturing", "markets", "cybernetics"]:
		_add_research_branch_row(research_branches_card, branch_id)

	var equipment_card: VBoxContainer = _make_card(research, "Research Equipment")
	for equipment_id: String in ["precision_assembler", "smart_warehouse", "laboratory_rig", "threat_console", "market_analytics"]:
		_add_research_equipment_row(equipment_card, equipment_id)

	var projects_card: VBoxContainer = _make_card(research, "Long-Term Projects")
	long_project_label = _add_label(projects_card)
	for project_id: String in ["solid_state_prototype", "closed_loop_materials", "predictive_operations"]:
		var project_button: Button = Button.new()
		project_button.pressed.connect(func() -> void: simulation.start_long_project(state, project_id))
		projects_card.add_child(project_button)
		long_project_buttons[project_id] = project_button

	var challenges_card: VBoxContainer = _make_card(research, "Challenges")
	challenge_label = _add_label(challenges_card)
	var challenge_grid: GridContainer = GridContainer.new()
	challenge_grid.columns = 2
	challenge_grid.add_theme_constant_override("h_separation", 8)
	challenge_grid.add_theme_constant_override("v_separation", 8)
	challenges_card.add_child(challenge_grid)
	for challenge_id: String in ["production_sprint", "revenue_drive", "incident_free", "contract_streak"]:
		var challenge_button: Button = Button.new()
		challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		challenge_button.pressed.connect(func() -> void: simulation.start_challenge(state, challenge_id))
		challenge_grid.add_child(challenge_button)
		challenge_buttons[challenge_id] = challenge_button

	var contracts_card: VBoxContainer = _make_card(company, "Contracts")
	reputation_label = _add_label(contracts_card)
	contract_label = _add_label(contracts_card)

	var contract_buttons: HBoxContainer = HBoxContainer.new()
	contract_buttons.add_theme_constant_override("separation", 8)
	contracts_card.add_child(contract_buttons)

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
	contracts_card.add_child(offline_report_label)

	var controls_card: VBoxContainer = _make_card(office, "Run Controls")
	pause_button = CheckButton.new()
	pause_button.text = "Pause simulation"
	pause_button.toggled.connect(_on_pause_toggled)
	controls_card.add_child(pause_button)

	var speed_row: HBoxContainer = HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	controls_card.add_child(speed_row)

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

	var autosave_row: HBoxContainer = HBoxContainer.new()
	autosave_row.add_theme_constant_override("separation", 8)
	controls_card.add_child(autosave_row)

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
	controls_card.add_child(scale_row)

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
	controls_card.add_child(offline_row)

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
	controls_card.add_child(save_button)

	var appearance_card: VBoxContainer = _make_card(office, "Appearance")
	var theme_row: HBoxContainer = HBoxContainer.new()
	theme_row.add_theme_constant_override("separation", 8)
	appearance_card.add_child(theme_row)
	var theme_label: Label = Label.new()
	theme_label.text = "Colour scheme"
	theme_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_row.add_child(theme_label)
	theme_option = OptionButton.new()
	for theme_name: String in THEME_NAMES:
		theme_option.add_item(theme_name)
	theme_option.item_selected.connect(_on_theme_selected)
	theme_row.add_child(theme_option)

	var mode_row: HBoxContainer = HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	appearance_card.add_child(mode_row)
	var mode_label: Label = Label.new()
	mode_label.text = "Display mode"
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(mode_label)
	mode_option = OptionButton.new()
	mode_option.add_item("Dark")
	mode_option.add_item("Light")
	mode_option.item_selected.connect(_on_mode_selected)
	mode_row.add_child(mode_option)
	var appearance_note: Label = _add_label(appearance_card)
	appearance_note.text = "Changes apply immediately. The chromatic governance committee has been bypassed."

	var finance_card: VBoxContainer = _make_card(office, "Unit Economics")
	finance_label = _add_label(finance_card)

	var upgrade_card: VBoxContainer = _make_card(company, "Upgrades")
	var advertising_card: VBoxContainer = _make_card(market, "Advertising Channels")
	advertising_label = _add_label(advertising_card)
	for channel: Dictionary in Formulas.ADVERTISING_CHANNELS:
		var channel_id: String = str(channel["id"])
		var toggle: CheckButton = CheckButton.new()
		toggle.text = "%s — $%s/min" % [
			str(channel["name"]),
			Formulas.format_number(float(channel["cost_per_second"]) * 60.0)
		]
		toggle.tooltip_text = str(channel["description"])
		toggle.toggled.connect(_on_advertising_toggled.bind(channel_id))
		advertising_buttons[channel_id] = toggle
		advertising_card.add_child(toggle)

	var upgrade_list: VBoxContainer = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 6)
	upgrade_card.add_child(upgrade_list)
	for definition: Dictionary in upgrades:
		var button: Button = Button.new()
		button.text = str(definition.get("name", "Upgrade"))
		button.tooltip_text = str(definition.get("description", ""))
		button.pressed.connect(_on_upgrade_pressed.bind(definition))
		upgrade_buttons[str(definition.get("id", ""))] = button
		upgrade_list.add_child(button)

	var log_card: VBoxContainer = _make_card(activity, "Company Log")
	event_log_label = RichTextLabel.new()
	event_log_label.custom_minimum_size = Vector2(0.0, 420.0)
	event_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log_label.bbcode_enabled = true
	log_card.add_child(event_log_label)

	var stats_card: VBoxContainer = _make_card(office, "Lifetime Ledger")
	stats_label = _add_label(stats_card)

func _build_interface_theme() -> Theme:
	var palette: Dictionary = _theme_palette()
	var interface_theme: Theme = Theme.new()
	interface_theme.default_font_size = 14
	interface_theme.set_type_variation("TitleLabel", "Label")
	interface_theme.set_type_variation("SubtitleLabel", "Label")
	interface_theme.set_type_variation("StatusLabel", "Label")
	interface_theme.set_type_variation("OverviewLabel", "Label")
	interface_theme.set_type_variation("PanelHeading", "Label")
	interface_theme.set_type_variation("CardHeading", "Label")
	interface_theme.set_type_variation("SectionHeading", "Label")
	interface_theme.set_type_variation("CardPanel", "PanelContainer")
	interface_theme.set_color("font_color", "Label", palette["text"])
	interface_theme.set_color("font_color", "TitleLabel", palette["accent"])
	interface_theme.set_color("font_color", "SubtitleLabel", palette["muted"])
	interface_theme.set_color("font_color", "StatusLabel", palette["success"])
	interface_theme.set_color("font_color", "OverviewLabel", palette["text_soft"])
	interface_theme.set_color("font_color", "PanelHeading", palette["primary"])
	interface_theme.set_color("font_color", "CardHeading", palette["accent"])
	interface_theme.set_color("font_color", "SectionHeading", palette["primary"])
	interface_theme.set_color("default_color", "RichTextLabel", palette["text"])
	interface_theme.set_color("font_color", "Button", palette["button_text"])
	interface_theme.set_color("font_hover_color", "Button", palette["button_hover_text"])
	interface_theme.set_color("font_pressed_color", "Button", palette["pressed_text"])
	interface_theme.set_color("font_disabled_color", "Button", palette["disabled_text"])
	interface_theme.set_stylebox("normal", "Button", _flat_style(palette["button"], palette["border"], 1, 7))
	interface_theme.set_stylebox("hover", "Button", _flat_style(palette["button_hover"], palette["primary"], 1, 7))
	interface_theme.set_stylebox("pressed", "Button", _flat_style(palette["accent"], palette["accent"], 1, 7))
	interface_theme.set_stylebox("disabled", "Button", _flat_style(palette["disabled"], palette["border_soft"], 1, 7))
	interface_theme.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	interface_theme.set_color("font_color", "CheckButton", palette["text_soft"])
	interface_theme.set_color("font_hover_color", "CheckButton", palette["text"])
	interface_theme.set_stylebox("panel", "PanelContainer", _flat_style(palette["surface"], palette["border"], 1, 9))
	interface_theme.set_stylebox("panel", "CardPanel", _flat_style(palette["card"], palette["border_soft"], 1, 8))
	interface_theme.set_stylebox("panel", "TabContainer", _flat_style(palette["surface_deep"], palette["border"], 1, 9))
	interface_theme.set_stylebox("tab_selected", "TabBar", _flat_style(palette["tab_selected"], palette["primary"], 1, 6))
	interface_theme.set_stylebox("tab_unselected", "TabBar", _flat_style(palette["tab"], palette["border_soft"], 1, 6))
	interface_theme.set_color("font_selected_color", "TabBar", palette["text"])
	interface_theme.set_color("font_unselected_color", "TabBar", palette["muted"])
	interface_theme.set_stylebox("background", "ProgressBar", _flat_style(palette["meter_background"], palette["border_soft"], 0, 4))
	interface_theme.set_stylebox("fill", "ProgressBar", _flat_style(palette["primary"], palette["primary"], 0, 4))
	interface_theme.set_stylebox("normal", "LineEdit", _flat_style(palette["input"], palette["border"], 1, 6))
	interface_theme.set_color("font_color", "LineEdit", palette["text"])
	return interface_theme

func _theme_palette() -> Dictionary:
	var palettes: Dictionary = {
		"workshop_dark": ["081116", "0f1c21", "0c171c", "13252b", "29474f", "223940", "d7e2e7", "b8c9ce", "91a6ac", "55b7bf", "f2cf73", "70d6a6", "18323a", "214852", "111f24", "708086", "e8f3f5", "ffffff", "081116", "1b3b43", "101f25", "0a1418", "102126"],
		"workshop_light": ["e8f0ef", "f7fbfa", "edf5f3", "ffffff", "91b2b2", "bfd2d0", "182b30", "334d53", "5e777c", "087f8c", "9a6500", "19734d", "d8e9e8", "c1dedd", "dbe4e3", "809092", "17373d", "08282d", "ffffff", "cbe4e3", "e1ecea", "d8e5e3", "f2f8f7"],
		"corporate_dark": ["090d1b", "11182b", "0d1324", "17213a", "33466f", "26385f", "e1e7f5", "c1cbe0", "8795b5", "6fa8ff", "ff9f5a", "65d5cf", "1b2e50", "274673", "141b2b", "71809c", "edf3ff", "ffffff", "0b1020", "203c68", "131d35", "0b1223", "111d35"],
		"corporate_light": ["edf1fa", "ffffff", "f4f6fc", "ffffff", "9caed0", "cbd5e8", "17233d", "344563", "63718c", "286dcc", "b64d00", "087c75", "dce7f8", "c5daf5", "e0e4ec", "7a8495", "17345f", "102b52", "ffffff", "d4e2f6", "e7edf8", "dce4f2", "f6f8fd"],
		"solar_dark": ["15120a", "211d10", "1b170c", "2b2513", "62562a", "493f20", "f2ead0", "d8cda9", "a99d78", "9fd356", "ffd45e", "72d58a", "34451e", "4d6728", "201d13", "8b8267", "f4efd9", "ffffff", "171307", "3d4d22", "26210f", "19160b", "272214"],
		"solar_light": ["f4f0df", "fffdf5", "f8f4e6", "ffffff", "baaa6c", "ded4ad", "302b18", "554d2e", "7e7351", "557d16", "a86000", "31753e", "e7edcf", "d8e6b7", "e7e3d5", "8a826b", "30430d", "253609", "ffffff", "dce8bc", "eee9d4", "e9e3ca", "fbf8ed"],
	}
	var key: String = "%s_%s" % [state.ui_theme_id, "dark" if state.ui_dark_mode else "light"]
	var values: Array = palettes.get(key, palettes["workshop_dark"])
	var names: Array[String] = ["background", "surface", "surface_deep", "card", "border", "border_soft", "text", "text_soft", "muted", "primary", "accent", "success", "button", "button_hover", "disabled", "disabled_text", "button_text", "button_hover_text", "pressed_text", "tab_selected", "tab", "meter_background", "input"]
	var result: Dictionary = {}
	for index: int in range(names.size()):
		result[names[index]] = Color(str(values[index]))
	return result

func _flat_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _make_panel(title: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(300.0, 0.0)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var heading: Label = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 14)
	heading.theme_type_variation = "PanelHeading"
	box.add_child(heading)

	return panel

func _make_card(parent: Control, title: String) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var heading: Label = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 17)
	heading.theme_type_variation = "CardHeading"
	box.add_child(heading)
	return box

func _add_meter(parent: Control) -> ProgressBar:
	var meter: ProgressBar = ProgressBar.new()
	meter.show_percentage = false
	meter.custom_minimum_size = Vector2(0.0, 8.0)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(meter)
	return meter

func _add_section_heading(parent: Control, text: String) -> Label:
	var heading: Label = Label.new()
	heading.text = text.to_upper()
	heading.add_theme_font_size_override("font_size", 13)
	heading.theme_type_variation = "SectionHeading"
	parent.add_child(heading)
	return heading

func _add_label(parent: Control) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _add_workshop_station(parent: Control, id: String, title: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(150.0, 86.0)
	parent.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	var heading: Label = Label.new()
	heading.text = title
	heading.theme_type_variation = "SectionHeading"
	heading.add_theme_font_size_override("font_size", 11)
	stack.add_child(heading)
	var status: Label = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(status)
	workshop_station_labels[id] = status

func _add_security_node(parent: Control, id: String, title: String) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(220.0, 82.0)
	parent.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	var heading: Label = Label.new()
	heading.text = title
	heading.theme_type_variation = "SectionHeading"
	heading.add_theme_font_size_override("font_size", 11)
	stack.add_child(heading)
	var status: Label = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(status)
	network_asset_labels[id] = status

func _add_cyber_program_row(parent: Control, id: String, title: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label: Label = Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	cyber_program_labels[id] = label
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(132.0, 0.0)
	button.pressed.connect(func() -> void: simulation.upgrade_cyber_program(state, id))
	row.add_child(button)
	cyber_program_buttons[id] = button

func _add_department_row(parent: Control, department_id: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label: Label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	department_labels[department_id] = label
	var invest_button: Button = Button.new()
	invest_button.pressed.connect(func() -> void: simulation.invest_department(state, department_id))
	row.add_child(invest_button)
	department_invest_buttons[department_id] = invest_button
	var manager_button: Button = Button.new()
	manager_button.pressed.connect(func() -> void: _on_manager_pressed(department_id))
	row.add_child(manager_button)
	department_manager_buttons[department_id] = manager_button

func _add_research_branch_row(parent: Control, branch_id: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label: Label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	research_branch_labels[branch_id] = label
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(130.0, 0.0)
	button.pressed.connect(func() -> void: simulation.advance_research_branch(state, branch_id))
	row.add_child(button)
	research_branch_buttons[branch_id] = button

func _add_research_equipment_row(parent: Control, equipment_id: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label: Label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	research_equipment_labels[equipment_id] = label
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(165.0, 0.0)
	button.pressed.connect(func() -> void: simulation.buy_research_equipment(state, equipment_id))
	row.add_child(button)
	research_equipment_buttons[equipment_id] = button

func _on_price_changed(value: float) -> void:
	state.sale_price = value
	state.demand_per_second = Formulas.demand_per_second(state)
	state.notify_changed()

func _on_premium_price_changed(value: float) -> void:
	state.premium_sale_price = value
	state.notify_changed()

func _on_upgrade_pressed(definition: Dictionary) -> void:
	simulation.buy_upgrade(state, definition)

func _on_advertising_toggled(enabled: bool, channel_id: String) -> void:
	simulation.set_advertising_channel(state, channel_id, enabled)

func _on_automation_rule_toggled(enabled: bool, rule_id: String) -> void:
	if not simulation.set_automation_rule(state, rule_id, enabled):
		var toggle: CheckButton = automation_rule_buttons.get(rule_id) as CheckButton
		if toggle != null:
			toggle.set_pressed_no_signal(bool(state.automation_rules.get(rule_id, false)))

func _on_automation_target_changed(value: float) -> void:
	state.automation_material_target = roundi(value)
	state.notify_changed()

func _on_automation_reserve_changed(value: float) -> void:
	state.automation_cash_reserve = value
	state.notify_changed()

func _on_manager_pressed(department_id: String) -> void:
	if bool(state.managers.get(department_id, false)):
		simulation.fire_manager(state, department_id)
	else:
		simulation.hire_manager(state, department_id)

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

func _on_theme_selected(index: int) -> void:
	state.ui_theme_id = THEME_IDS[clampi(index, 0, THEME_IDS.size() - 1)]
	_apply_interface_theme()
	state.add_event("Colour scheme changed to %s. Branding has claimed responsibility." % THEME_NAMES[clampi(index, 0, THEME_NAMES.size() - 1)])

func _on_mode_selected(index: int) -> void:
	state.ui_dark_mode = index == 0
	_apply_interface_theme()
	state.add_event("%s mode enabled. Facilities has adjusted the imaginary lighting." % ("Dark" if state.ui_dark_mode else "Light"))

func _apply_interface_theme() -> void:
	if interface_root == null or interface_background == null:
		return
	var palette: Dictionary = _theme_palette()
	interface_background.color = palette["background"]
	interface_root.theme = _build_interface_theme()

func _apply_ui_scale() -> void:
	state.ui_scale = 1.0
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
	if not is_equal_approx(premium_price_slider.value, state.premium_sale_price):
		premium_price_slider.set_value_no_signal(state.premium_sale_price)
	if pause_button.button_pressed != state.simulation_paused:
		pause_button.set_pressed_no_signal(state.simulation_paused)
	_sync_speed_option()
	if not is_equal_approx(autosave_spin.value, state.autosave_interval):
		autosave_spin.set_value_no_signal(state.autosave_interval)
	var offline_hours: float = state.offline_limit_seconds / 3600.0
	if not is_equal_approx(offline_limit_spin.value, offline_hours):
		offline_limit_spin.set_value_no_signal(offline_hours)
	_sync_ui_scale_option()
	_sync_theme_options()
	cash_label.text = "Cash: $%s" % Formulas.format_number(state.cash)
	status_overview_label.text = "$%s CASH   ·   %s KITS   ·   %s CELLS" % [
		Formulas.format_number(state.cash),
		Formulas.format_number(state.raw_materials),
		Formulas.format_number(state.battery_cells + state.premium_cells)
	]
	_update_workshop_view()
	var active_recipe: int = roundi(Formulas.product_material_cost(state.active_product))
	var manual_batch: int = roundi(state.manual_output)
	materials_label.text = "Component kits: %d  ·  enough for %d %s cells" % [
		floori(state.raw_materials),
		floori(state.raw_materials / active_recipe),
		"Long-Life" if state.active_product == "premium" else "Standard"
	]
	produce_button.text = "⚡  ASSEMBLE %d %s CELL%s  ·  %d KIT%s" % [
		manual_batch,
		"LONG-LIFE" if state.active_product == "premium" else "STANDARD",
		"" if manual_batch == 1 else "S",
		manual_batch * active_recipe,
		"" if manual_batch * active_recipe == 1 else "S"
	]
	produce_button.disabled = state.raw_materials < manual_batch * active_recipe or Formulas.warehouse_space(state) < manual_batch
	for quantity: int in material_buy_buttons:
		var buy_button: Button = material_buy_buttons[quantity] as Button
		var kit_cost: float = quantity * Formulas.material_unit_cost(state)
		buy_button.text = "Buy %d · $%s" % [quantity, Formulas.format_number(kit_cost)]
		buy_button.disabled = state.cash < kit_cost
	var inventory_runway: float = Formulas.inventory_runway_seconds(state)
	var warehouse_fill_time: float = Formulas.warehouse_fill_seconds(state)
	var stock_flow_note: String = "balanced at current rates"
	if is_finite(inventory_runway):
		stock_flow_note = "stockout now" if inventory_runway <= 0.0 else "stockout in ~%s" % _format_duration(inventory_runway)
	elif is_finite(warehouse_fill_time):
		stock_flow_note = "warehouse full now" if warehouse_fill_time <= 0.0 else "warehouse full in ~%s" % _format_duration(warehouse_fill_time)
	inventory_label.text = "Standard inventory: %s cells (worth $%s at current price)\nTotal warehouse use: %s / %s cells · %s" % [
		Formulas.format_number(state.battery_cells),
		Formulas.format_number(state.battery_cells * state.sale_price),
		Formulas.format_number(state.battery_cells + state.premium_cells),
		Formulas.format_number(Formulas.effective_warehouse_capacity(state)),
		stock_flow_note
	]
	inventory_bar.max_value = maxf(1.0, Formulas.effective_warehouse_capacity(state))
	inventory_bar.value = clampf(state.battery_cells + state.premium_cells, 0.0, inventory_bar.max_value)
	var material_runway: float = Formulas.material_runway_seconds(state)
	var material_runway_text: String = "no automated draw" if not is_finite(material_runway) else "~%s at current output" % _format_duration(material_runway)
	material_price_label.text = "Kit price: $%s each · runway %s" % [
		Formulas.format_number(Formulas.material_unit_cost(state)),
		material_runway_text
	]
	var operations_risk: float = maxf(0.0, state.risk - 0.06)
	risk_label.text = "Security risk: %d%% (base 6%% + operations %d%% - defenses %d%%)" % [
		roundi(Formulas.effective_risk(state) * 100.0),
		roundi(operations_risk * 100.0),
		roundi(state.risk_reduction * 100.0)
	]
	risk_bar.max_value = 100.0
	risk_bar.value = Formulas.effective_risk(state) * 100.0
	var spot_revenue: float = state.lifetime_revenue - state.lifetime_contract_revenue
	stats_label.text = "OUTPUT\nMade: %s cells | Sold: %s cells | Unfilled orders: %s\n\nINCOME\nSpot sales: $%s | Contracts: $%s | Total: $%s\n\nSPENDING\nComponent kits: $%s | Energy: $%s | Production wages: $%s\nSecurity wages: $%s | Manager wages: $%s | Upgrades: $%s\nCorporate investment: $%s | Hiring: $%s | Maintenance: $%s\nAdvertising: $%s | Security losses: $%s\n\nTime operated: %s" % [
		Formulas.format_number(state.lifetime_cells_made),
		Formulas.format_number(state.lifetime_cells_sold),
		Formulas.format_number(state.lifetime_sales_lost),
		Formulas.format_number(spot_revenue),
		Formulas.format_number(state.lifetime_contract_revenue),
		Formulas.format_number(state.lifetime_revenue),
		Formulas.format_number(state.lifetime_material_spend),
		Formulas.format_number(state.lifetime_energy_cost),
		Formulas.format_number(state.lifetime_wages_paid),
		Formulas.format_number(state.lifetime_security_wages),
		Formulas.format_number(state.lifetime_manager_wages),
		Formulas.format_number(state.lifetime_upgrade_spend),
		Formulas.format_number(state.lifetime_corporate_investment),
		Formulas.format_number(state.lifetime_hiring_spend),
		Formulas.format_number(state.lifetime_maintenance_spend),
		Formulas.format_number(state.lifetime_advertising_spend),
		Formulas.format_number(state.lifetime_security_losses),
		_format_duration(state.seconds_played)
	]
	price_label.text = "Sale price: $%s/cell" % Formulas.format_number(state.sale_price)
	_update_products_section()
	_update_advertising_section()
	var segment_lines: Array[String] = []
	for segment: Dictionary in Formulas.customer_segment_demand(state):
		var segment_rate: float = float(segment["demand"])
		var segment_share: float = 0.0 if state.demand_per_second <= 0.0 else segment_rate / state.demand_per_second
		segment_lines.append("%s %d%% (%s/min)" % [
			str(segment["name"]),
			int(round(segment_share * 100.0)),
			Formulas.format_number(segment_rate * 60.0)
		])
	var standard_order_progress: float = float(state.sales_progress.get("standard", 0.0))
	demand_label.text = "Potential demand: %s cells/min  ·  next whole order %d%%\nCustomer mix: %s" % [
		Formulas.format_number(state.demand_per_second * 60.0),
		roundi(standard_order_progress * 100.0),
		" | ".join(segment_lines)
	]
	sales_label.text = "Fulfilled sales pace: %s cells/min" % Formulas.format_number(state.sales_per_second * 60.0)
	if state.production_downtime > 0.0:
		production_label.text = "Automation: OFFLINE for %ds (incident response) | Manual batch: %s" % [
			ceili(state.production_downtime),
			Formulas.format_number(state.manual_output)
		]
	elif Formulas.automated_throughput(state) > 0.0:
		var staffed_prep: float = Formulas.staffed_prep_rate(state)
		var staffed_assembly: float = Formulas.staffed_assembly_rate(state)
		var bottleneck: String = " (prep-limited)" if staffed_prep < staffed_assembly else " (assembly-limited)"
		var active_progress: float = float(state.production_progress.get(state.active_product, 0.0))
		production_label.text = "Stages: prep %s/min | assembly %s/min | testing %s/min\nAutomated output: %s cells/min%s | Next cell %d%% complete | Manual batch: %d cells" % [
			Formulas.format_number(staffed_prep * 60.0),
			Formulas.format_number(staffed_assembly * 60.0),
			Formulas.format_number(Formulas.staffed_testing_rate(state) * 60.0),
			Formulas.format_number(Formulas.automated_throughput(state) * 60.0),
			bottleneck,
			roundi(active_progress * 100.0),
			roundi(state.manual_output)
		]
	else:
		production_label.text = "Automation: none yet | Manual batch: %d cells" % roundi(state.manual_output)
	quality_label.text = "Product quality: %.2f (design %.2f x condition %d%% x testing coverage %d%%)" % [
		Formulas.effective_quality(state),
		state.quality,
		roundi((0.8 + 0.2 * clampf(state.machine_condition, 0.0, 1.0)) * 100.0),
		roundi(Formulas.testing_coverage(state) * 100.0)
	]
	quality_bar.max_value = 150.0
	quality_bar.value = clampf(Formulas.effective_quality(state) * 100.0, 0.0, quality_bar.max_value)
	_update_maintenance_row()
	_update_contracts_section()
	_update_staff_section()
	_update_cybersecurity_section()
	_update_corporate_section()
	_update_research_section()
	var estimated_margin: float = Formulas.estimated_margin_per_cell(state)
	var sell_through: float = Formulas.sell_through_per_second(state)
	var margin_status: String = "PROFITABLE" if estimated_margin > 0.0 else "LOSS-MAKING"
	market_label.text = "%s at current costs  ·  contribution margin $%s/cell\nOne kit $%s + automation energy $%s | Inventory sell-through: %s cells/min\nDemand note: households chase price; specialists tolerate price for quality." % [
		margin_status,
		Formulas.format_number(estimated_margin),
		Formulas.format_number(Formulas.material_unit_cost(state)),
		Formulas.format_number(Formulas.energy_cost_per_cell(state)),
		Formulas.format_number(sell_through * 60.0)
	]
	_update_finance_section()
	var competitor_factor: float = Formulas.competitor_demand_factor(state, "standard", 1.2)
	var position: String = "advantage" if competitor_factor > 1.05 else ("pressure" if competitor_factor < 0.95 else "roughly even")
	competitor_label.text = "Competitor: %s — $%s/cell, %.2f quality\nMarket position: %s (%d%% demand effect for a typical buyer)" % [
		state.competitor_name,
		Formulas.format_number(state.competitor_price),
		state.competitor_quality,
		position,
		roundi((competitor_factor - 1.0) * 100.0)
	]
	_update_upgrade_buttons()
	_update_event_log()
	_update_offline_report()

func _update_finance_section() -> void:
	var income: float = state.lifetime_revenue
	var spending: float = state.lifetime_material_spend + state.lifetime_energy_cost + state.lifetime_wages_paid + state.lifetime_security_wages + state.lifetime_manager_wages + state.lifetime_upgrade_spend + state.lifetime_corporate_investment + state.lifetime_hiring_spend + state.lifetime_maintenance_spend + state.lifetime_advertising_spend + state.lifetime_security_losses
	finance_label.text = "Standard margin: $%s/cell | Long-Life margin: $%s/cell\nRecorded income: $%s | Recorded spending: $%s | Net cash flow: $%s" % [
		Formulas.format_number(Formulas.estimated_margin_per_cell(state, "standard")),
		Formulas.format_number(Formulas.estimated_margin_per_cell(state, "premium")),
		Formulas.format_number(income),
		Formulas.format_number(spending),
		Formulas.format_number(income - spending)
	]

func _update_workshop_view() -> void:
	var automation_level: int = int(state.upgrade_levels.get("workbench_automation", 0))
	var tool_level: int = int(state.upgrade_levels.get("better_tools", 0))
	var prep_level: int = int(state.upgrade_levels.get("prep_station", 0))
	var testing_level: int = int(state.upgrade_levels.get("testing_bench", 0))
	var shelving_level: int = int(state.upgrade_levels.get("garage_shelving", 0))
	var firewall_level: int = int(state.upgrade_levels.get("firewall", 0))
	var backup_level: int = int(state.upgrade_levels.get("backups", 0))
	var mfa_level: int = int(state.upgrade_levels.get("multifactor_authentication", 0))
	var total_workers: int = Formulas.total_workers(state)
	var stage: String = "ONE-PERSON GARAGE"
	if automation_level >= 6 or total_workers >= 4:
		stage = "COMPACT PRODUCTION FLOOR"
	elif automation_level > 0 or total_workers > 0:
		stage = "MECHANISED WORKSHOP"
	workshop_stage_label.text = "%s  ·  equipment appears here as the company acquires increasingly official rectangles." % stage

	var bench_icon: String = "⚙" if automation_level > 0 else "🔧"
	_set_workshop_station("bench", "%s %s\nTools L%d · Automation L%d\n%s cells/min" % [
		bench_icon,
		"Powered line" if automation_level > 0 else "Hand assembly",
		tool_level,
		automation_level,
		Formulas.format_number(Formulas.staffed_assembly_rate(state) * 60.0)
	])
	_set_workshop_station("prep", "%s\nStation L%d · %d staff\n%s cells/min" % [
		"▣ Sorting station" if prep_level > 0 else "□ Folding table",
		prep_level,
		int(state.workers.get("prep", 0)),
		Formulas.format_number(Formulas.staffed_prep_rate(state) * 60.0)
	])
	_set_workshop_station("testing", "%s\nBench L%d · %d staff\n%d%% coverage" % [
		"✓ Instrumented" if testing_level > 0 else "? Visual checks",
		testing_level,
		int(state.workers.get("testing", 0)),
		roundi(Formulas.testing_coverage(state) * 100.0)
	])
	_set_workshop_station("storage", "%s\nShelving L%d\n%d / %d spaces used" % [
		"▥ Racked storage" if shelving_level > 0 else "▤ Floor boxes",
		shelving_level,
		roundi(state.battery_cells + state.premium_cells),
		roundi(Formulas.effective_warehouse_capacity(state))
	])
	_set_workshop_station("crew", "%s\n%d on payroll\n%s" % [
		"♟ Staffed" if total_workers > 0 else "○ Founder only",
		total_workers,
		"STRIKE IN PROGRESS" if state.staff_striking else "Org chart operational"
	])
	var security_controls: Array[String] = []
	if firewall_level > 0:
		security_controls.append("Firewall L%d" % firewall_level)
	if backup_level > 0:
		security_controls.append("Backups L%d" % backup_level)
	if mfa_level > 0:
		security_controls.append("MFA L%d" % mfa_level)
	if security_controls.is_empty():
		security_controls.append("Unlocked laptop")
	_set_workshop_station("security", "%s\n%s\nRisk %d%%" % [
		"◆ Controls online" if firewall_level + backup_level + mfa_level > 0 else "◇ Informal security",
		" · ".join(security_controls),
		roundi(Formulas.effective_risk(state) * 100.0)
	])
	_update_operations_watch()

func _set_workshop_station(id: String, text: String) -> void:
	var label: Label = workshop_station_labels.get(id) as Label
	if label != null:
		label.text = text

func _update_operations_watch() -> void:
	var critical: Array[String] = []
	var warnings: Array[String] = []
	if state.production_downtime > 0.0:
		critical.append("automation offline %s" % _format_duration(state.production_downtime))
	if state.staff_striking:
		critical.append("payroll strike")
	var material_runway: float = Formulas.material_runway_seconds(state)
	if is_finite(material_runway):
		if material_runway <= 60.0:
			critical.append("kits empty in %s" % _format_duration(material_runway))
		elif material_runway <= 180.0:
			warnings.append("kit runway %s" % _format_duration(material_runway))
	var inventory_runway: float = Formulas.inventory_runway_seconds(state)
	if is_finite(inventory_runway):
		if inventory_runway <= 30.0:
			critical.append("stockout %s" % ("now" if inventory_runway <= 0.0 else "in %s" % _format_duration(inventory_runway)))
		elif inventory_runway <= 120.0:
			warnings.append("stock runway %s" % _format_duration(inventory_runway))
	var fill_time: float = Formulas.warehouse_fill_seconds(state)
	if is_finite(fill_time):
		if fill_time <= 30.0:
			critical.append("warehouse %s" % ("full" if fill_time <= 0.0 else "fills in %s" % _format_duration(fill_time)))
		elif fill_time <= 120.0:
			warnings.append("warehouse fills in %s" % _format_duration(fill_time))
	if state.production_per_second > 0.0:
		var service_due: float = Formulas.service_due_seconds(state)
		if service_due <= 0.0:
			critical.append("service overdue")
		elif service_due <= 120.0:
			warnings.append("service due in %s" % _format_duration(service_due))
	if Formulas.estimated_margin_per_cell(state, state.active_product) <= 0.0:
		critical.append("%s margin negative" % ("Long-Life" if state.active_product == "premium" else "Standard"))

	var palette: Dictionary = _theme_palette()
	if not critical.is_empty():
		operations_watch_label.text = "● ACTION REQUIRED  ·  %s" % "  ·  ".join(critical.slice(0, 3))
		operations_watch_label.add_theme_color_override("font_color", palette["accent"])
	elif not warnings.is_empty():
		operations_watch_label.text = "▲ WATCH  ·  %s" % "  ·  ".join(warnings.slice(0, 3))
		operations_watch_label.add_theme_color_override("font_color", palette["accent"])
	else:
		operations_watch_label.text = "● OPERATIONS STABLE  ·  no immediate constraints at current rates"
		operations_watch_label.add_theme_color_override("font_color", palette["success"])

func _update_advertising_section() -> void:
	for channel_id: String in advertising_buttons:
		var toggle: CheckButton = advertising_buttons[channel_id] as CheckButton
		var enabled: bool = bool(state.advertising_channels.get(channel_id, false))
		if toggle.button_pressed != enabled:
			toggle.set_pressed_no_signal(enabled)
	var cost: float = Formulas.advertising_cost_per_second(state)
	advertising_label.text = "Campaign spend: $%s/min | Lifetime: $%s\nEach channel reaches a different customer mix." % [
		Formulas.format_number(cost * 60.0),
		Formulas.format_number(state.lifetime_advertising_spend)
	]

func _update_products_section() -> void:
	var unlocked: bool = state.premium_product_unlocked
	unlock_product_button.visible = not unlocked
	unlock_product_button.text = "Develop Long-Life Cell - $%s" % Formulas.format_number(Simulation.PREMIUM_PRODUCT_UNLOCK_COST)
	unlock_product_button.disabled = state.cash < Simulation.PREMIUM_PRODUCT_UNLOCK_COST
	premium_product_button.visible = unlocked
	premium_product_button.disabled = state.active_product == "premium"
	standard_product_button.disabled = state.active_product == "standard"
	premium_inventory_label.visible = unlocked
	premium_price_label.visible = unlocked
	premium_price_slider.visible = unlocked
	premium_demand_label.visible = unlocked
	if not unlocked:
		premium_inventory_label.text = "Long-Life Cells use 2 component kits each and appeal strongly to specialist buyers."
		return
	var premium_demand: float = Formulas.demand_per_second(state, "premium")
	premium_inventory_label.text = "Long-Life inventory: %s cells (worth $%s) | Routing: %s" % [
		Formulas.format_number(state.premium_cells),
		Formulas.format_number(state.premium_cells * state.premium_sale_price),
		"Long-Life" if state.active_product == "premium" else "Standard"
	]
	premium_price_label.text = "Long-Life price: $%s/cell" % Formulas.format_number(state.premium_sale_price)
	var premium_segments: Array[String] = []
	for segment: Dictionary in Formulas.customer_segment_demand(state, "premium"):
		var segment_rate: float = float(segment["demand"])
		var segment_share: float = 0.0 if premium_demand <= 0.0 else segment_rate / premium_demand
		premium_segments.append("%s %d%%" % [str(segment["name"]), roundi(segment_share * 100.0)])
	var premium_competitor_factor: float = Formulas.competitor_demand_factor(state, "premium", 1.2)
	var premium_position: String = "advantage" if premium_competitor_factor > 1.05 else ("pressure" if premium_competitor_factor < 0.95 else "roughly even")
	premium_demand_label.text = "Long-Life demand: %s cells/min | Margin $%s/cell | 2 kits/cell | +25%% quality\nCustomer mix: %s\nCompetitor position: %s (%d%% demand effect)" % [
		Formulas.format_number(premium_demand * 60.0),
		Formulas.format_number(Formulas.estimated_margin_per_cell(state, "premium")),
		" | ".join(premium_segments),
		premium_position,
		roundi((premium_competitor_factor - 1.0) * 100.0)
	]

func _update_maintenance_row() -> void:
	if state.production_per_second <= 0.0:
		condition_label.visible = false
		condition_bar.visible = false
		service_button.visible = false
		return
	condition_label.visible = true
	condition_bar.visible = true
	service_button.visible = true
	var wear_per_minute: float = Formulas.garage_throughput(state) * Formulas.wear_per_cell(state) * 100.0 * 60.0
	var service_due: float = Formulas.service_due_seconds(state)
	var service_due_text: String = "service due now" if service_due <= 0.0 else "service threshold in ~%s" % _format_duration(service_due)
	condition_label.text = "Machine condition: %d%% (efficiency %d%%) · wear %.2f%%/min · %s" % [
		roundi(state.machine_condition * 100.0),
		roundi(Formulas.machine_efficiency(state) * 100.0),
		wear_per_minute,
		service_due_text
	]
	condition_bar.max_value = 100.0
	condition_bar.value = state.machine_condition * 100.0
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
		label.text = "%s: %d/%d (+%s cells/min each)" % [
			role.capitalize(),
			count,
			Formulas.MAX_WORKERS_PER_ROLE,
			Formulas.format_number(Formulas.WORKER_STAGE_RATE * 60.0)
		]
	var total: int = Formulas.total_workers(state)
	if total == 0:
		wage_label.text = "No staff. The org chart is a dot."
	elif state.staff_striking:
		wage_label.text = "Wages: UNPAID - staff are on strike until payroll clears ($%s/min owed)." % Formulas.format_number(total * Formulas.WORKER_WAGE_PER_SECOND * 60.0)
	else:
		wage_label.text = "Wages: $%s/min | Hiring fee: $%s" % [
			Formulas.format_number(total * Formulas.WORKER_WAGE_PER_SECOND * 60.0),
			Formulas.format_number(Formulas.WORKER_HIRING_FEE)
		]

func _update_contracts_section() -> void:
	reputation_label.text = "REPUTATION  General %d  ·  Delivery %d  ·  Quality %d  ·  Security %d" % [
		roundi(float(state.reputation.get("general", 50.0))),
		roundi(float(state.reputation.get("delivery", 50.0))),
		roundi(float(state.reputation.get("quality", 50.0))),
		roundi(float(state.reputation.get("security", 50.0)))
	]
	var next_tier: Dictionary = simulation.next_contract_tier(state)
	if next_tier.is_empty():
		reputation_label.text += "\nAll contract tiers qualified. Procurement has run out of velvet ropes."
	else:
		var gaps: Array[String] = []
		for category: String in next_tier.get("requirements", {}):
			var required: int = roundi(float(next_tier["requirements"][category]))
			var current: int = roundi(float(state.reputation.get(category, 0.0)))
			gaps.append("%s %d/%d" % [category.capitalize(), current, required])
		reputation_label.text += "\nNext: %s — %s" % [str(next_tier["name"]), ", ".join(gaps)]
	var has_offer: bool = not state.contract_offer.is_empty()
	accept_contract_button.visible = has_offer
	decline_contract_button.visible = has_offer
	if not state.active_contract.is_empty():
		var contract: Dictionary = state.active_contract
		contract_label.text = "Active %s: %s cells for %s ($%s each)\nDelivered: %s / %s | Time left: %s" % [
			str(contract.get("tier", "Open Market")),
			Formulas.format_number(float(contract.get("quantity", 0.0))),
			str(contract.get("buyer", "a client")),
			Formulas.format_number(float(contract.get("price_per_cell", 0.0))),
			Formulas.format_number(float(contract.get("quantity", 0.0)) - float(contract.get("remaining", 0.0))),
			Formulas.format_number(float(contract.get("quantity", 0.0))),
			_format_duration(float(contract.get("time_remaining", 0.0)))
		]
	elif has_offer:
		var offer: Dictionary = state.contract_offer
		var requirement_parts: Array[String] = []
		for category: String in offer.get("requirements", {}):
			requirement_parts.append("%s %d" % [category.capitalize(), roundi(float(offer["requirements"][category]))])
		var requirement_text: String = "None" if requirement_parts.is_empty() else ", ".join(requirement_parts)
		contract_label.text = "%s offer from %s:\n%s cells at $%s each (total $%s)\nRequired reputation: %s\nDeadline once signed: %s | Offer expires: %s" % [
			str(offer.get("tier", "Open Market")),
			str(offer.get("buyer", "a client")),
			Formulas.format_number(float(offer.get("quantity", 0.0))),
			Formulas.format_number(float(offer.get("price_per_cell", 0.0))),
			Formulas.format_number(float(offer.get("quantity", 0.0)) * float(offer.get("price_per_cell", 0.0))),
			requirement_text,
			_format_duration(float(offer.get("duration", 0.0))),
			_format_duration(float(offer.get("expires_in", 0.0)))
		]
	else:
		contract_label.text = "No offers right now. Completed: %d | Missed: %d | Contract revenue: $%s\nCompleted by tier: Open %d · Approved %d · Assured %d" % [
			state.lifetime_contracts_completed,
			state.lifetime_contracts_failed,
			Formulas.format_number(state.lifetime_contract_revenue),
			int(state.lifetime_contracts_by_tier.get("Open Market", 0)),
			int(state.lifetime_contracts_by_tier.get("Approved Supplier", 0)),
			int(state.lifetime_contracts_by_tier.get("Assured Supply", 0))
		]

func _update_cybersecurity_section() -> void:
	var zones: int = Formulas.network_zone_count(state)
	var topology: String = ["Flat workshop LAN", "Office / Production split", "Recovery zone isolated", "Public edge DMZ"][state.network_segmentation_level]
	network_map_label.text = "%s  ·  %d zone%s  ·  risk %d%%\nInternet Edge → Office Systems → Production; Recovery Store attached to Office." % [
		topology,
		zones,
		"" if zones == 1 else "s",
		roundi(Formulas.effective_risk(state) * 100.0)
	]
	var storefront_level: int = int(state.upgrade_levels.get("online_storefront", 0))
	var firewall_level: int = int(state.upgrade_levels.get("firewall", 0))
	var mfa_level: int = int(state.upgrade_levels.get("multifactor_authentication", 0))
	var backup_level: int = int(state.upgrade_levels.get("backups", 0))
	var controllers: int = int(state.upgrade_levels.get("workbench_automation", 0)) + int(state.upgrade_levels.get("prep_station", 0)) + int(state.upgrade_levels.get("testing_bench", 0))
	_set_security_node("edge", "%s · %s\n%s" % [
		"Public" if storefront_level > 0 else "No public service",
		"DMZ" if state.network_segmentation_level >= 3 else "Shared boundary",
		"Firewall L%d" % firewall_level if firewall_level > 0 else "Unfiltered edge"
	])
	_set_security_node("office", "Operations · supplier records\n%s · Zone %s" % [
		"MFA L%d" % mfa_level if mfa_level > 0 else "Password only",
		"Office" if state.network_segmentation_level >= 1 else "Shared"
	])
	_set_security_node("production", "%d connected controller%s\nZone %s" % [
		controllers,
		"" if controllers == 1 else "s",
		"Production" if state.network_segmentation_level >= 1 else "Shared"
	])
	_set_security_node("recovery", "%s\nZone %s · effective recovery %d%%" % [
		"Backup sets L%d" % backup_level if backup_level > 0 else "No backup sets",
		"Recovery" if state.network_segmentation_level >= 2 else ("Office" if state.network_segmentation_level >= 1 else "Shared"),
		roundi(Formulas.recovery_strength(state) * 100.0)
	])

	var program_fields: Dictionary = {
		"segmentation": "network_segmentation_level",
		"detection": "detection_level",
		"response": "incident_response_level",
		"recovery": "recovery_plan_level",
	}
	var program_effects: Dictionary = {
		"segmentation": "%d zones · %d%% blast-radius reduction" % [zones, roundi(Formulas.segmentation_mitigation(state) * 100.0)],
		"detection": "%d%% detection strength" % roundi(Formulas.detection_strength(state) * 100.0),
		"response": "%d%% response strength" % roundi(Formulas.response_strength(state) * 100.0),
		"recovery": "%d%% effective recovery" % roundi(Formulas.recovery_strength(state) * 100.0),
	}
	var program_names: Dictionary = {
		"segmentation": "Network Zones & Segmentation",
		"detection": "Threat Detection",
		"response": "Incident Response",
		"recovery": "Recovery Planning",
	}
	for program_id: String in cyber_program_labels:
		var level: int = int(state.get(str(program_fields[program_id])))
		var label: Label = cyber_program_labels[program_id] as Label
		label.text = "%s · L%d/3\n%s" % [str(program_names[program_id]), level, str(program_effects[program_id])]
		var button: Button = cyber_program_buttons[program_id] as Button
		if level >= 3:
			button.text = "Complete"
			button.disabled = true
		else:
			var cost: float = simulation.cyber_program_cost(state, program_id)
			button.text = "Advance · $%s" % Formulas.format_number(cost)
			button.disabled = state.cash < cost

	var staff_status: String = "ON DUTY" if state.security_staff_on_duty else "OFF DUTY — PAYROLL"
	security_staff_label.text = "Analysts: %d/%d · %s\nWages $%s/min · each analyst improves detection and response." % [
		state.security_staff,
		Formulas.MAX_SECURITY_STAFF,
		staff_status,
		Formulas.format_number(state.security_staff * Formulas.SECURITY_STAFF_WAGE_PER_SECOND * 60.0)
	]
	hire_security_button.disabled = state.security_staff >= Formulas.MAX_SECURITY_STAFF or state.cash < Simulation.SECURITY_STAFF_HIRING_FEE
	hire_security_button.text = "Hire analyst · $%s" % Formulas.format_number(Simulation.SECURITY_STAFF_HIRING_FEE)
	fire_security_button.disabled = state.security_staff <= 0

	var incident_summary: String = "No recorded cybersecurity incidents."
	if not state.last_security_incident.is_empty():
		incident_summary = "Last: %s · %s · %s\n%s" % [
			str(state.last_security_incident.get("status", "recorded")).capitalize(),
			str(state.last_security_incident.get("zone", "Workshop LAN")),
			str(state.last_security_incident.get("type", "event")).capitalize(),
			str(state.last_security_incident.get("message", "The report contains several rectangles."))
		]
	security_incident_label.text = "%s\nDetected: %d · Contained: %d · Impact incidents: %d\nSecurity losses: $%s" % [
		incident_summary,
		state.lifetime_threats_detected,
		state.lifetime_incidents_contained,
		state.lifetime_incidents_suffered,
		Formulas.format_number(state.lifetime_security_losses)
	]

func _update_corporate_section() -> void:
	factories_label.text = "Garage + %d satellite factor%s · corporate output %s cells/min · total capacity %s" % [
		state.factories.size(),
		"y" if state.factories.size() == 1 else "ies",
		Formulas.format_number(Formulas.corporate_factory_throughput(state) * 60.0),
		Formulas.format_number(Formulas.effective_warehouse_capacity(state))
	]
	for index: int in range(factory_labels.size()):
		var label: Label = factory_labels[index]
		var button: Button = factory_upgrade_buttons[index]
		if index >= state.factories.size():
			label.visible = false
			button.visible = false
			continue
		label.visible = true
		button.visible = true
		var factory: Dictionary = state.factories[index]
		var level: int = int(factory.get("level", 1))
		label.text = "%s · L%d/3\n%s cells/min · %d storage" % [
			str(factory.get("name", "Factory")),
			level,
			Formulas.format_number(level * 0.75 * (1.0 + Formulas.department_effective_level(state, "operations") * 0.10) * 60.0),
			level * 120
		]
		if level >= 3:
			button.text = "Complete"
			button.disabled = true
		else:
			var cost: float = simulation.factory_upgrade_cost(state, index)
			button.text = "Expand · $%s" % Formulas.format_number(cost)
			button.disabled = state.cash < cost
	if state.factories.size() >= Simulation.FACTORY_NAMES.size():
		buy_factory_button.text = "Factory portfolio complete"
		buy_factory_button.disabled = true
	else:
		var factory_cost: float = simulation.next_factory_cost(state)
		buy_factory_button.text = "Acquire %s · $%s" % [Simulation.FACTORY_NAMES[state.factories.size()], Formulas.format_number(factory_cost)]
		buy_factory_button.disabled = state.cash < factory_cost

	var department_effects: Dictionary = {
		"operations": "+10% satellite output per effective level",
		"procurement": "-2.5% component cost per effective level",
		"sales": "+5% demand per effective level",
		"security": "+4% detection per effective level",
	}
	for department_id: String in department_labels:
		var level: int = int(state.department_levels.get(department_id, 0))
		var managed: bool = bool(state.managers.get(department_id, false))
		var label: Label = department_labels[department_id] as Label
		label.text = "%s · L%d/3%s\n%s" % [
			str(Simulation.DEPARTMENTS[department_id]["name"]),
			level,
			" · MANAGED" if managed else "",
			str(department_effects[department_id])
		]
		var invest_button: Button = department_invest_buttons[department_id] as Button
		if level >= 3:
			invest_button.text = "Complete"
			invest_button.disabled = true
		else:
			var cost: float = simulation.department_cost(state, department_id)
			invest_button.text = "Invest · $%s" % Formulas.format_number(cost)
			invest_button.disabled = state.cash < cost
		var manager_button: Button = department_manager_buttons[department_id] as Button
		manager_button.text = "Remove manager" if managed else "Hire manager · $%s" % Formulas.format_number(Simulation.MANAGER_HIRING_FEE)
		manager_button.disabled = (not managed and (level <= 0 or state.cash < Simulation.MANAGER_HIRING_FEE))

	var required_managers: Dictionary = {
		"material_reorder": "procurement",
		"preventive_service": "operations",
		"campaign_guardrail": "sales",
		"contract_review": "sales",
	}
	for rule_id: String in automation_rule_buttons:
		var toggle: CheckButton = automation_rule_buttons[rule_id] as CheckButton
		var enabled: bool = bool(state.automation_rules.get(rule_id, false))
		if toggle.button_pressed != enabled:
			toggle.set_pressed_no_signal(enabled)
		toggle.disabled = not bool(state.managers.get(str(required_managers[rule_id]), false))
	if not is_equal_approx(automation_target_spin.value, state.automation_material_target):
		automation_target_spin.set_value_no_signal(state.automation_material_target)
	if not is_equal_approx(automation_reserve_spin.value, state.automation_cash_reserve):
		automation_reserve_spin.set_value_no_signal(state.automation_cash_reserve)

	if state.active_supply_contract.is_empty():
		supply_contract_label.text = "No active agreement · spot kit price $%s\nSigned: %d · lifetime savings $%s" % [
			Formulas.format_number(Formulas.material_unit_cost(state)),
			state.lifetime_supply_contracts,
			Formulas.format_number(state.lifetime_supply_savings)
		]
	else:
		supply_contract_label.text = "%s · %d%% discount · %s remaining\nKit price $%s · lifetime savings $%s" % [
			str(state.active_supply_contract.get("name", "Supply agreement")),
			roundi(float(state.active_supply_contract.get("discount", 0.0)) * 100.0),
			_format_duration(float(state.active_supply_contract.get("time_remaining", 0.0))),
			Formulas.format_number(Formulas.material_unit_cost(state)),
			Formulas.format_number(state.lifetime_supply_savings)
		]
	for plan_id: String in supply_contract_buttons:
		var button: Button = supply_contract_buttons[plan_id] as Button
		var plan: Dictionary = Simulation.SUPPLY_PLANS[plan_id]
		button.text = "%s · $%s · %d%%" % [str(plan["name"]), Formulas.format_number(float(plan["fee"])), roundi(float(plan["discount"]) * 100.0)]
		button.disabled = not state.active_supply_contract.is_empty() or state.cash < float(plan["fee"])

	var history_note: String = "Collecting the first minute of corporate telemetry."
	if state.statistics_history.size() >= 2:
		var first: Dictionary = state.statistics_history.front()
		var last: Dictionary = state.statistics_history.back()
		var span: float = maxf(1.0, float(last.get("time", 0.0)) - float(first.get("time", 0.0)))
		var revenue_rate: float = (float(last.get("revenue", 0.0)) - float(first.get("revenue", 0.0))) / span * 60.0
		var output_rate: float = (float(last.get("cells_made", 0.0)) - float(first.get("cells_made", 0.0))) / span * 60.0
		var sales_rate: float = (float(last.get("cells_sold", 0.0)) - float(first.get("cells_sold", 0.0))) / span * 60.0
		history_note = "%d-minute trend: revenue $%s/min · output %s/min · sales %s/min" % [
			roundi(span / 60.0),
			Formulas.format_number(revenue_rate),
			Formulas.format_number(output_rate),
			Formulas.format_number(sales_rate)
		]
	detailed_stats_label.text = "%s\nCurrent: cash $%s · production %s/min · demand %s/min · risk %d%%\nCorporate investment $%s · manager wages $%s" % [
		history_note,
		Formulas.format_number(state.cash),
		Formulas.format_number(Formulas.automated_throughput(state) * 60.0),
		Formulas.format_number(state.demand_per_second * 60.0),
		roundi(Formulas.effective_risk(state) * 100.0),
		Formulas.format_number(state.lifetime_corporate_investment),
		Formulas.format_number(state.lifetime_manager_wages)
	]

func _update_research_section() -> void:
	research_summary_label.text = "Available: %s RP · generation %s RP/min · lifetime %s RP\nCompany scale and staffed departments generate research continuously." % [
		Formulas.format_number(state.research_points),
		Formulas.format_number(Formulas.research_points_per_second(state) * 60.0),
		Formulas.format_number(state.lifetime_research_points)
	]
	var branch_effects: Dictionary = {
		"materials": "-2% component cost per level",
		"manufacturing": "+4% automated throughput per level",
		"markets": "+3% demand per level",
		"cybernetics": "+2.5% detection per level",
	}
	for branch_id: String in research_branch_labels:
		var level: int = int(state.research_levels.get(branch_id, 0))
		var label: Label = research_branch_labels[branch_id] as Label
		label.text = "%s · L%d/5\n%s" % [str(Simulation.RESEARCH_BRANCHES[branch_id]["name"]), level, str(branch_effects[branch_id])]
		var button: Button = research_branch_buttons[branch_id] as Button
		if level >= 5:
			button.text = "Complete"
			button.disabled = true
		else:
			var cost: float = simulation.research_branch_cost(state, branch_id)
			button.text = "Research · %s RP" % Formulas.format_number(cost)
			button.disabled = state.research_points < cost

	var equipment_effects: Dictionary = {
		"precision_assembler": "+0.35 cells/s and -2% energy per level",
		"smart_warehouse": "+150 storage per level",
		"laboratory_rig": "+0.30 testing/s per level",
		"threat_console": "+4% detection per level",
		"market_analytics": "+4% demand per level",
	}
	for equipment_id: String in research_equipment_labels:
		var definition: Dictionary = Simulation.RESEARCH_EQUIPMENT[equipment_id]
		var level: int = int(state.equipment_levels.get(equipment_id, 0))
		var branch_id: String = str(definition["branch"])
		var required: int = int(definition["required_level"])
		var unlocked: bool = int(state.research_levels.get(branch_id, 0)) >= required
		var label: Label = research_equipment_labels[equipment_id] as Label
		label.text = "%s · L%d/3\n%s · requires %s L%d" % [
			str(definition["name"]), level, str(equipment_effects[equipment_id]),
			str(Simulation.RESEARCH_BRANCHES[branch_id]["name"]), required
		]
		var button: Button = research_equipment_buttons[equipment_id] as Button
		if level >= 3:
			button.text = "Complete"
			button.disabled = true
		elif not unlocked:
			button.text = "Research locked"
			button.disabled = true
		else:
			var costs: Dictionary = simulation.equipment_costs(state, equipment_id)
			button.text = "$%s + %s RP" % [Formulas.format_number(float(costs["cash"])), Formulas.format_number(float(costs["research"]))]
			button.disabled = state.cash < float(costs["cash"]) or state.research_points < float(costs["research"])

	if state.active_long_project.is_empty():
		long_project_label.text = "No active project · completed %d/%d\nProjects consume cash and research upfront, then progress online and offline." % [
			state.completed_long_projects.size(), Simulation.LONG_PROJECTS.size()
		]
	else:
		var duration: float = float(state.active_long_project.get("duration", 1.0))
		var remaining: float = float(state.active_long_project.get("time_remaining", 0.0))
		long_project_label.text = "ACTIVE: %s · %d%% complete · %s remaining\nCompleted projects: %d/%d" % [
			str(state.active_long_project.get("name", "Long-term project")),
			roundi((1.0 - remaining / maxf(1.0, duration)) * 100.0),
			_format_duration(remaining),
			state.completed_long_projects.size(), Simulation.LONG_PROJECTS.size()
		]
	for project_id: String in long_project_buttons:
		var project: Dictionary = Simulation.LONG_PROJECTS[project_id]
		var button: Button = long_project_buttons[project_id] as Button
		if state.completed_long_projects.has(project_id):
			button.text = "%s · COMPLETE · %s" % [str(project["name"]), str(project["description"])]
			button.disabled = true
		else:
			button.text = "%s · $%s + %s RP · %s · %s" % [
				str(project["name"]), Formulas.format_number(float(project["cash_cost"])),
				Formulas.format_number(float(project["research_cost"])), _format_duration(float(project["duration"])),
				str(project["description"])
			]
			button.disabled = not state.active_long_project.is_empty() or state.cash < float(project["cash_cost"]) or state.research_points < float(project["research_cost"])

	if state.active_challenge.is_empty():
		challenge_label.text = "No active challenge · completed %d · failed %d\nChallenges pause during offline progress." % [
			state.lifetime_challenges_completed, state.lifetime_challenges_failed
		]
	else:
		var progress: float = simulation.challenge_progress(state)
		var target: float = float(state.active_challenge.get("target", 1.0))
		challenge_label.text = "ACTIVE: %s · %s / %s · %s remaining\nCompleted %d · failed %d" % [
			str(state.active_challenge.get("name", "Challenge")),
			Formulas.format_number(progress), Formulas.format_number(target),
			_format_duration(float(state.active_challenge.get("time_remaining", 0.0))),
			state.lifetime_challenges_completed, state.lifetime_challenges_failed
		]
	for challenge_id: String in challenge_buttons:
		var challenge: Dictionary = Simulation.CHALLENGES[challenge_id]
		var button: Button = challenge_buttons[challenge_id] as Button
		var completed_marker: String = " ✓" if state.completed_challenge_ids.has(challenge_id) else ""
		button.text = "%s%s\n%s in %s · $%s + %s RP" % [
			str(challenge["name"]), completed_marker,
			Formulas.format_number(float(challenge["target"])), _format_duration(float(challenge["duration"])),
			Formulas.format_number(float(challenge["reward_cash"])), Formulas.format_number(float(challenge["reward_research"]))
		]
		button.disabled = not state.active_challenge.is_empty()

func _set_security_node(id: String, text: String) -> void:
	var label: Label = network_asset_labels.get(id) as Label
	if label != null:
		label.text = text

func _sync_ui_scale_option() -> void:
	var selected_index: int = 0
	for index: int in range(UI_SCALES.size()):
		if is_equal_approx(UI_SCALES[index], state.ui_scale):
			selected_index = index
	if ui_scale_option.selected != selected_index:
		ui_scale_option.select(selected_index)

func _sync_theme_options() -> void:
	if theme_option == null or mode_option == null:
		return
	var theme_index: int = maxi(0, THEME_IDS.find(state.ui_theme_id))
	if theme_option.selected != theme_index:
		theme_option.select(theme_index)
	var mode_index: int = 0 if state.ui_dark_mode else 1
	if mode_option.selected != mode_index:
		mode_option.select(mode_index)

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
		lines.append(message)
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

# Headless Milestone Five progression harness. Starts from a mature corporate
# handoff and validates ten hours of research, projects, and challenges.
extends SceneTree

const TICK: float = 5.0
const RUN_SECONDS: float = 10.0 * 60.0 * 60.0

func _init() -> void:
	var state: GameState = GameState.new()
	var simulation: Simulation = Simulation.new()
	simulation.rng.seed = 505
	state.cash = 100000.0
	state.raw_materials = 1000000.0
	state.sale_price = 6.0
	state.production_per_second = 3.0
	state.prep_rate = 4.0
	state.testing_rate = 4.0
	state.awareness = 4.0
	state.warehouse_capacity = 1000.0
	state.factories = [
		{"name": "Northside Assembly", "level": 3},
		{"name": "Riverside Works", "level": 3},
		{"name": "Airport Industrial Unit", "level": 3},
	]
	state.department_levels = {"operations": 3, "procurement": 3, "sales": 3, "security": 3}
	state.managers = {"operations": true, "procurement": true, "sales": true, "security": true}
	state.automation_rules = {"material_reorder": true, "preventive_service": true, "campaign_guardrail": true, "contract_review": true}
	state.network_segmentation_level = 3
	state.detection_level = 3
	state.incident_response_level = 3
	state.recovery_plan_level = 3
	state.security_staff = 3
	state.research_points = 400.0
	state.lifetime_research_points = 400.0

	print("=== Research and challenges handoff: ten-hour validation ===")
	var elapsed: float = 0.0
	var next_report: float = 3600.0
	var challenge_queue: Array[String] = ["production_sprint", "revenue_drive", "incident_free", "contract_streak"]
	var attempted_challenges: Dictionary = {}
	while elapsed < RUN_SECONDS:
		elapsed += TICK
		simulation.advance(state, TICK, true)

		if state.active_long_project.is_empty():
			for project_id: String in ["solid_state_prototype", "closed_loop_materials", "predictive_operations"]:
				if not state.completed_long_projects.has(project_id) and simulation.start_long_project(state, project_id):
					break

		var branch_choice: String = ""
		var lowest_level: int = 6
		for branch_id: String in ["materials", "manufacturing", "markets", "cybernetics"]:
			var level: int = int(state.research_levels[branch_id])
			if level < lowest_level and level < 5:
				lowest_level = level
				branch_choice = branch_id
		if not branch_choice.is_empty():
			simulation.advance_research_branch(state, branch_choice)

		for equipment_id: String in ["precision_assembler", "smart_warehouse", "laboratory_rig", "threat_console", "market_analytics"]:
			if int(state.equipment_levels[equipment_id]) < 3 and simulation.buy_research_equipment(state, equipment_id):
				break

		if state.active_challenge.is_empty():
			for challenge_id: String in challenge_queue:
				if not attempted_challenges.has(challenge_id):
					attempted_challenges[challenge_id] = true
					simulation.start_challenge(state, challenge_id)
					break

		if elapsed >= next_report:
			next_report += 3600.0
			print("%2dh | RP %s | branches %s | equipment %s | projects %d/3 | challenges %d complete / %d failed" % [
				roundi(elapsed / 3600.0),
				Formulas.format_number(state.research_points),
				_branch_summary(state),
				_equipment_summary(state),
				state.completed_long_projects.size(),
				state.lifetime_challenges_completed,
				state.lifetime_challenges_failed,
			])

	print("Summary: branches %s | equipment %s | projects %s | challenges %d complete / %d failed | lifetime RP %s | output %s/min" % [
		_branch_summary(state),
		_equipment_summary(state),
		", ".join(state.completed_long_projects),
		state.lifetime_challenges_completed,
		state.lifetime_challenges_failed,
		Formulas.format_number(state.lifetime_research_points),
		Formulas.format_number(Formulas.automated_throughput(state) * 60.0),
	])
	quit()

func _branch_summary(state: GameState) -> String:
	return "M%d/F%d/K%d/C%d" % [
		int(state.research_levels["materials"]),
		int(state.research_levels["manufacturing"]),
		int(state.research_levels["markets"]),
		int(state.research_levels["cybernetics"]),
	]

func _equipment_summary(state: GameState) -> String:
	var levels: Array[String] = []
	for equipment_id: String in ["precision_assembler", "smart_warehouse", "laboratory_rig", "threat_console", "market_analytics"]:
		levels.append("%d" % int(state.equipment_levels[equipment_id]))
	return "/".join(levels)

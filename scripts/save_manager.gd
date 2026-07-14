extends RefCounted
class_name SaveManager

const SAVE_PATH: String = "user://save_slot_1.json"

static func save_game(state: GameState) -> Error:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state.to_save_data(), "\t"))
	return OK

static func load_game(state: GameState) -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return ERR_FILE_NOT_FOUND
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	state.load_save_data(parsed)
	return OK

static func get_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)

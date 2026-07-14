extends RefCounted
class_name GameState

signal changed

const SAVE_VERSION: int = 1

var save_version: int = SAVE_VERSION
var last_saved_unix_time: int = 0

var cash: float = 25.0
var raw_materials: float = 10.0
var battery_cells: float = 0.0
var sale_price: float = 4.0
var material_price: float = 1.0
var material_market_timer: float = 0.0

var manual_output: float = 1.0
var production_per_second: float = 0.0
var awareness: float = 1.0
var quality: float = 1.0
var base_value: float = 4.0
var material_discount: float = 0.0

var risk: float = 0.06
var risk_reduction: float = 0.0
var recovery: float = 0.0
var trust: float = 0.0
var security_event_timer: float = 0.0

var demand_per_second: float = 0.0
var sales_per_second: float = 0.0
var lifetime_cells_made: float = 0.0
var lifetime_cells_sold: float = 0.0
var lifetime_revenue: float = 0.0
var lifetime_materials_bought: float = 0.0
var lifetime_security_losses: float = 0.0
var seconds_played: float = 0.0

var upgrade_levels: Dictionary = {}
var event_log: Array[String] = []
var offline_report: Dictionary = {}

func notify_changed() -> void:
	changed.emit()

func add_event(message: String) -> void:
	event_log.push_front(message)
	if event_log.size() > 80:
		event_log.resize(80)
	notify_changed()

func to_save_data() -> Dictionary:
	return {
		"save_version": save_version,
		"last_saved_unix_time": Time.get_unix_time_from_system(),
		"cash": cash,
		"raw_materials": raw_materials,
		"battery_cells": battery_cells,
		"sale_price": sale_price,
		"material_price": material_price,
		"material_market_timer": material_market_timer,
		"manual_output": manual_output,
		"production_per_second": production_per_second,
		"awareness": awareness,
		"quality": quality,
		"base_value": base_value,
		"material_discount": material_discount,
		"risk": risk,
		"risk_reduction": risk_reduction,
		"recovery": recovery,
		"trust": trust,
		"security_event_timer": security_event_timer,
		"demand_per_second": demand_per_second,
		"sales_per_second": sales_per_second,
		"lifetime_cells_made": lifetime_cells_made,
		"lifetime_cells_sold": lifetime_cells_sold,
		"lifetime_revenue": lifetime_revenue,
		"lifetime_materials_bought": lifetime_materials_bought,
		"lifetime_security_losses": lifetime_security_losses,
		"seconds_played": seconds_played,
		"upgrade_levels": upgrade_levels,
		"event_log": event_log,
	}

func load_save_data(data: Dictionary) -> void:
	save_version = int(data.get("save_version", SAVE_VERSION))
	last_saved_unix_time = int(data.get("last_saved_unix_time", 0))
	cash = float(data.get("cash", cash))
	raw_materials = float(data.get("raw_materials", raw_materials))
	battery_cells = float(data.get("battery_cells", battery_cells))
	sale_price = float(data.get("sale_price", sale_price))
	material_price = float(data.get("material_price", material_price))
	material_market_timer = float(data.get("material_market_timer", material_market_timer))
	manual_output = float(data.get("manual_output", manual_output))
	production_per_second = float(data.get("production_per_second", production_per_second))
	awareness = float(data.get("awareness", awareness))
	quality = float(data.get("quality", quality))
	base_value = float(data.get("base_value", base_value))
	material_discount = float(data.get("material_discount", material_discount))
	risk = float(data.get("risk", risk))
	risk_reduction = float(data.get("risk_reduction", risk_reduction))
	recovery = float(data.get("recovery", recovery))
	trust = float(data.get("trust", trust))
	security_event_timer = float(data.get("security_event_timer", security_event_timer))
	demand_per_second = float(data.get("demand_per_second", demand_per_second))
	sales_per_second = float(data.get("sales_per_second", sales_per_second))
	lifetime_cells_made = float(data.get("lifetime_cells_made", lifetime_cells_made))
	lifetime_cells_sold = float(data.get("lifetime_cells_sold", lifetime_cells_sold))
	lifetime_revenue = float(data.get("lifetime_revenue", lifetime_revenue))
	lifetime_materials_bought = float(data.get("lifetime_materials_bought", lifetime_materials_bought))
	lifetime_security_losses = float(data.get("lifetime_security_losses", lifetime_security_losses))
	seconds_played = float(data.get("seconds_played", seconds_played))
	upgrade_levels = data.get("upgrade_levels", {})
	event_log.clear()
	for message in data.get("event_log", []):
		event_log.append(str(message))
	notify_changed()

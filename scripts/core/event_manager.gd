extends Node

var events: Array = []

var final_indices: Dictionary = {
	"tragic": -1,
	"migration": -1,
	"spiritual": -1,
	"technical": -1
}

var act_event_indices: Dictionary = {
	1: [],
	2: [],
	3: []
}

var used_event_indices: Array[int] = []

var current_act: int = 1
var events_played_in_current_act: int = 0

var max_events_per_act: Dictionary = {
	1: 6,
	2: 7,
	3: 6
}

var in_final: bool = false
var current_event_index: int = -1
var current_final_id: String = ""

var events_path: String = "res://data/events/the_last_river_events.json"


func load_events() -> void:
	if not FileAccess.file_exists(events_path):
		push_error("Events JSON not found at: " + events_path)
		return

	var file := FileAccess.open(events_path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Could not parse JSON.")
		return

	if not parsed.has("events"):
		push_error("JSON has no 'events' array.")
		return

	events = parsed["events"]

	final_indices = {
		"tragic": -1,
		"migration": -1,
		"spiritual": -1,
		"technical": -1
	}

	act_event_indices = {
		1: [],
		2: [],
		3: []
	}
	used_event_indices.clear()

	# Tum eventleri tara ve act havuzlarina ayir
	for i in range(events.size()):
		var ev: Dictionary = events[i]
		var id: String = str(ev.get("id", ""))
		var act: int = int(ev.get("act", 1))

		if id.begins_with("final_"):
			match id:
				"final_tragic":
					final_indices["tragic"] = i
				"final_migration":
					final_indices["migration"] = i
				"final_spiritual":
					final_indices["spiritual"] = i
				"final_technical":
					final_indices["technical"] = i
		else:
			if act_event_indices.has(act):
				act_event_indices[act].append(i)

	randomize()


func start_game(state: Dictionary) -> int:
	current_act = 1
	events_played_in_current_act = 0
	used_event_indices.clear()
	in_final = false
	current_final_id = ""
	
	current_event_index = pick_next_event_index_for_current_act(state)
	if current_event_index >= 0:
		used_event_indices.append(current_event_index)
		events_played_in_current_act = 1
	else:
		events_played_in_current_act = 0

	return current_event_index


func get_current_event() -> Dictionary:
	if current_event_index >= 0 and current_event_index < events.size():
		return events[current_event_index]
	return {}


func get_event(index: int) -> Dictionary:
	if index >= 0 and index < events.size():
		return events[index]
	return {}


func get_critical_stat(state: Dictionary) -> String:
	if state.is_empty():
		return "water"

	var stats := {
		"water": state.get("water", 50),
		"food": state.get("food", 50),
		"population": state.get("population", 50),
		"morale": state.get("morale", 50),
		"river": state.get("river", 50)
	}

	var worst_key := "water"
	var worst_value: int = int(stats[worst_key])

	for key in stats.keys():
		if int(stats[key]) < worst_value:
			worst_key = key
			worst_value = int(stats[key])

	return worst_key


func event_affects_stat(ev: Dictionary, stat: String) -> bool:
	var choices: Array = ev.get("choices", [])
	for choice in choices:
		var eff: Dictionary = choice.get("effects", {})
		if eff.get(stat, 0) != 0:
			return true
	return false


func pick_next_event_index_for_current_act(state: Dictionary) -> int:
	var act_list: Array = act_event_indices.get(current_act, []).duplicate()
	if act_list.is_empty():
		return -1

	var candidates: Array[int] = []
	for idx in act_list:
		if not used_event_indices.has(idx):
			candidates.append(idx)

	if candidates.is_empty():
		return -1

	var critical_stat := get_critical_stat(state)

	var focused: Array[int] = []
	for idx in candidates:
		var ev: Dictionary = events[idx]
		if event_affects_stat(ev, critical_stat):
			focused.append(idx)

	var pool: Array[int] = candidates if focused.is_empty() else focused
	var selected_index: int = pool[randi() % pool.size()]
	return selected_index


func next_event_index(state: Dictionary) -> int:
	if in_final:
		return current_event_index

	var max_events_for_act: int = int(max_events_per_act.get(current_act, 5))

	if events_played_in_current_act >= max_events_for_act:
		if current_act < 3:
			current_act += 1
			events_played_in_current_act = 0
		else:
			return -1  # Artık path finaline gecilecek

	var next_idx := pick_next_event_index_for_current_act(state)
	if next_idx == -1:
		if current_act < 3:
			current_act += 1
			events_played_in_current_act = 0
			next_idx = pick_next_event_index_for_current_act(state)
		else:
			return -1

	if next_idx == -1:
		return -1

	used_event_indices.append(next_idx)
	events_played_in_current_act += 1
	current_event_index = next_idx
	return current_event_index


func final_index_tragic() -> int:
	in_final = true
	current_final_id = "final_tragic"
	current_event_index = final_indices["tragic"]
	return current_event_index


func final_index_for_id(final_id: String) -> int:
	in_final = true
	current_final_id = final_id

	var index := -1
	match final_id:
		"final_tragic":
			index = final_indices["tragic"]
		"final_migration":
			index = final_indices["migration"]
		"final_spiritual":
			index = final_indices["spiritual"]
		"final_technical":
			index = final_indices["technical"]

	current_event_index = index
	return current_event_index

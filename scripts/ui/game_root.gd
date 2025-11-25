extends Control

var burası: int = 0

var content_base_pos: Vector2

var state := {
	"water": 70,
	"food": 70,
	"population": 50,
	"morale": 60,
	"river": 100,
	"tech": 0,
	"spiritual": 0,
	"migration": 0,
	"authority": 0
}

var game_over: bool = false

var card_on_left: bool = true

@onready var event_manager = $EventManager
@onready var title_label: Label = $MainLayout/ContentArea/CardArea/EventCard/CardPadding/CardContent/EventTitleLabel
@onready var text_label: Label = $MainLayout/ContentArea/CardArea/EventCard/CardPadding/CardContent/EventTextLabel
@onready var choice_buttons: Array[BaseButton] = [
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton1,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton2,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton3,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton4,
]
@onready var choice_labels := [
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton1/MarginContainer/ChoiseLabel1,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton2/MarginContainer/ChoiseLabel2,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton3/MarginContainer/ChoiseLabel3,
	$MainLayout/ContentArea/MarginContainer/ChoicesArea/ChoiceButton4/MarginContainer/ChoiseLabel4,
]
@onready var water_bar = $MainLayout/TopBarPadding/TopBars/WaterBar/WaterProgress
@onready var food_bar = $MainLayout/TopBarPadding/TopBars/FoodBar/FoodProgress
@onready var population_bar = $MainLayout/TopBarPadding/TopBars/PopulationBar/PopulationProgress
@onready var morale_bar = $MainLayout/TopBarPadding/TopBars/MoraleBar/MoraleProgress
@onready var river_bar: Range = $MainLayout/TopBarPadding/TopBars/RiverBar/RiverProgress
@onready var game_over_popup: Window = $GameOverPopup
@onready var restart_button: Button = $GameOverPopup/MarginContainer/VBox/ButtonsRow/RestartButton
@onready var main_menu_button: Button = $GameOverPopup/MarginContainer/VBox/ButtonsRow/MainMenuButton
@onready var game_over_label: Label = $GameOverPopup/MarginContainer/VBox/GameOverLabel
@onready var event_card: Control = $MainLayout/ContentArea/CardArea/EventCard
@onready var content_area: Control = $MainLayout/ContentArea
@onready var card_area: Control = $MainLayout/ContentArea/CardArea
@onready var choices_container: Control = $MainLayout/ContentArea/MarginContainer
@onready var act_banner: ColorRect = $ActBanner
@onready var act_label: Label = $ActBanner/ActLabel
@onready var pause_menu = $PauseMenu


func _ready() -> void:
	event_manager.load_events()

	for btn in choice_buttons:
		btn.pressed.connect(_on_choice_pressed.bind(btn))
	
	for lbl in choice_labels:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		# varsa kullan, yoksa sorun değil:
		if lbl.has_method("set"):
			lbl.max_lines_visible = 2
			
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	var first_index : int = event_manager.start_game(state)
	if first_index >= 0:
		show_event(first_index)
	else:
		push_error("No events loaded from JSON.")

	water_bar.min_value = 0
	water_bar.max_value = 100
	food_bar.min_value = 0
	food_bar.max_value = 100
	population_bar.min_value = 0
	population_bar.max_value = 100
	morale_bar.min_value = 0
	morale_bar.max_value = 100
	river_bar.min_value = 0
	river_bar.max_value = 100
	
	update_bars()
	
	content_base_pos = content_area.position
	event_card.scale = Vector2.ONE
			
		
func show_event(index: int) -> void:
	var ev: Dictionary = event_manager.get_event(index)
	if ev.is_empty():
		push_error("Event index out of range: %d" % index)
		return

	title_label.text = ev.get("title", "Untitled Event")
	text_label.text = ev.get("text", "")
	
	call_deferred("_fit_title_text")
	call_deferred("_fit_event_text")

	var choices: Array = ev.get("choices", [])
	for i in range(choice_buttons.size()):
		var btn = choice_buttons[i]
		var lbl = choice_labels[i]

		if i < choices.size():
			var choice: Dictionary = choices[i]
			var txt: String = choice.get("text", "Choice %d" % (i + 1))
			
			btn.visible = true
			lbl.visible = true

			lbl.text = txt       # Asıl metin Label'da

			btn.set_meta("choice_index", i)
		else:
			btn.visible = false
			lbl.visible = false

	call_deferred("_fit_all_choice_labels")
	

			
func _on_choice_pressed(button: BaseButton) -> void:
	if game_over:
		return

	var ev: Dictionary = event_manager.get_current_event()
	var ev_id: String = str(ev.get("id", ""))
	var choices: Array = ev.get("choices", [])

	var choice_index: int = int(button.get_meta("choice_index"))
	if choice_index < 0 or choice_index >= choices.size():
		return

	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})

	# Final event'teysek:
	if ev_id.begins_with("final_"):
		# Istersen finalde de effects uygulayabilirsin:
		# apply_effects(effects)
		game_over = true

		match ev_id:
			"final_tragic":
				game_over_label.text = "The river is gone. Your people could not endure."
			"final_migration":
				game_over_label.text = "You leave the dry valley behind, seeking a new river."
			"final_spiritual":
				game_over_label.text = "In the silence of the dry river, your people found meaning."
			"final_technical":
				game_over_label.text = "The river is gone, but wells and cisterns keep your people alive."

		game_over_popup.popup()
		return

	# Normal event: statleri guncelle
	apply_effects(effects)

	# Erken game over kontrolu
	if check_early_game_over():
		return
	
	var old_act: int = event_manager.current_act
	
	var next_idx : int = event_manager.next_event_index(state)
	if next_idx == -1:
		show_path_ending()
		return

	var new_act: int = event_manager.current_act
	
	show_event(next_idx)
	
	if new_act != old_act:
		show_act_banner(new_act)
	
func apply_effects(effects: Dictionary) -> void:
	var old_water: int = state["water"]
	var old_food: int = state["food"]
	var old_population: int = state["population"]
	var old_morale: int = state["morale"]
	var old_river: int = state["river"]
	
	for key in effects.keys():
		if state.has(key):
			state[key] += int(effects[key])
	
	# Ana barları 0-100 aralığında tut
	state["water"] = clamp(state["water"], 0, 100)
	state["food"] = clamp(state["food"], 0, 100)
	state["population"] = clamp(state["population"], 0, 100)
	state["morale"] = clamp(state["morale"], 0, 100)
	state["river"] = clamp(state["river"], 0, 100)
	
	animate_bar(water_bar, old_water, state["water"])
	animate_bar(food_bar, old_food, state["food"])
	animate_bar(population_bar, old_population, state["population"])
	animate_bar(morale_bar, old_morale, state["morale"])
	animate_bar(river_bar, old_river, state["river"])
	
func update_bars() -> void:
	water_bar.value = state["water"]
	food_bar.value = state["food"]
	population_bar.value = state["population"]
	morale_bar.value = state["morale"]
	river_bar.value = state["river"]
	
func animate_bar(bar: TextureProgressBar, from_value: float, to_value: float, duration: float = 0.4) -> void:
	bar.value = from_value
	var tween := create_tween()
	tween.tween_property(bar, "value", to_value, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	

func check_early_game_over() -> bool:
	if state["water"] <= 0 or state["population"] <= 0 or state["morale"] <= 0:
		var fin_idx : int = event_manager.final_index_tragic()
		if fin_idx >= 0:
			show_event(fin_idx)
		return true

	return false

func show_path_ending() -> void:
	var scores := {
		"tech": state["tech"],
		"spiritual": state["spiritual"],
		"migration": state["migration"],
		"authority": state["authority"]
	}

	var best_key := "tech"
	var best_value: int = int(scores[best_key])

	for key in scores.keys():
		if int(scores[key]) > best_value:
			best_key = key
			best_value = int(scores[key])

	var final_id := "final_tragic"

	match best_key:
		"tech":
			final_id = "final_technical"
		"spiritual":
			final_id = "final_spiritual"
		"migration":
			final_id = "final_migration"
		"authority":
			final_id = "final_tragic"

	var fin_idx : int = event_manager.final_index_for_id(final_id)
	if fin_idx >= 0:
		show_event(fin_idx)
	
	
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func show_act_banner(act_number: int) -> void:
	var title := "ACT I"
	match act_number:
		1:
			title = "ACT I - The Flowing River"
		2:
			title = "ACT II - Cracks in the Riverbed"
		3:
			title = "ACT III - The Last Drops"

	act_label.text = title
	act_banner.visible = true

	var color := act_banner.color
	color.a = 0.0
	act_banner.color = color

	var tween := create_tween()
	tween.tween_property(act_banner, "color:a", 0.8, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_property(act_banner, "color:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(func ():
		act_banner.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not game_over:
		pause_menu.toggle_pause()

const MAX_LABEL_FONT_SIZE := 16
const MIN_LABEL_FONT_SIZE := 10
const MAX_LINES := 2

func _fit_all_choice_labels() -> void:
	for lbl in choice_labels:
		if lbl.visible and lbl.text != "":
			_fit_label_to_two_lines(lbl)


func _fit_label_to_two_lines(label: Label) -> void:
	var font: Font = label.get_theme_font("font")
	if font == null:
		return

	var width := label.size.x
	if width <= 0.0:
		width = label.get_minimum_size().x
	if width <= 0.0:
		return

	var font_size := MAX_LABEL_FONT_SIZE
	while font_size >= MIN_LABEL_FONT_SIZE:
		var text_size := font.get_multiline_string_size(
			label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			width,
			font_size
		)
		var line_height := font.get_height(font_size)
		var max_height := line_height * MAX_LINES

		if text_size.y <= max_height + 1.0:
			label.add_theme_font_size_override("font_size", font_size)
			return

		font_size -= 1

	# Hâlâ sığmıyorsa en küçük fontu kullan
	label.add_theme_font_size_override("font_size", MIN_LABEL_FONT_SIZE)

const TEXT_MAX_FONT := 18
const TEXT_MIN_FONT := 12
const TEXT_MAX_LINES := 6   

func _fit_event_text() -> void:
	var font: Font = text_label.get_theme_font("font")
	if font == null:
		return

	var width := text_label.size.x
	if width <= 0:
		width = text_label.get_minimum_size().x
	if width <= 0:
		return

	var font_size := TEXT_MAX_FONT

	while font_size >= TEXT_MIN_FONT:
		var text_size := font.get_multiline_string_size(
			text_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			width,
			font_size
		)

		var line_height := font.get_height(font_size)
		var max_height := line_height * TEXT_MAX_LINES

		if text_size.y <= max_height:
			text_label.add_theme_font_size_override("font_size", font_size)
			return

		font_size -= 1

	# Sığmazsa en küçük fontu ver
	text_label.add_theme_font_size_override("font_size", TEXT_MIN_FONT)

const TITLE_MAX_FONT := 20
const TITLE_MIN_FONT := 14
const TITLE_MAX_LINES := 2

func _fit_title_text() -> void:
	var font: Font = title_label.get_theme_font("font")
	if font == null:
		return

	var width := title_label.size.x
	if width <= 0:
		width = title_label.get_minimum_size().x
	if width <= 0:
		return

	var font_size := TITLE_MAX_FONT

	while font_size >= TITLE_MIN_FONT:
		var text_size := font.get_multiline_string_size(
			title_label.text,
			HORIZONTAL_ALIGNMENT_CENTER,
			width,
			font_size
		)

		var line_height := font.get_height(font_size)
		var max_height := line_height * TITLE_MAX_LINES

		# Tek satıra sığıyorsa tamam
		if text_size.y <= max_height + 1.0:
			title_label.add_theme_font_size_override("font_size", font_size)
			return

		font_size -= 1

	# Hiç sığmazsa minimum fontu ver
	title_label.add_theme_font_size_override("font_size", TITLE_MIN_FONT)

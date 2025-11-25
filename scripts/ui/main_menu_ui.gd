extends Control

@onready var new_game_button: TextureButton = $MenuContainer/ButtonNewGame
@onready var new_game_label: Label = $MenuContainer/ButtonNewGame/NewGameLabel
@onready var continue_button: TextureButton = $MenuContainer/ButtonContinue
@onready var continue_label: Label = $MenuContainer/ButtonContinue/ContinueLabel
@onready var settings_button: TextureButton = $MenuContainer/ButtonSettings
@onready var settings_label: Label = $MenuContainer/ButtonSettings/SettingsLabel

func _ready() -> void:
	new_game_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)
	continue_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)
	settings_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)
	$MenuContainer/ButtonContinue.disabled = true
	if new_game_button:
		new_game_button.mouse_entered.connect(_on_play_button_hover)
		new_game_button.mouse_exited.connect(_on_play_button_exit)
		new_game_button.pressed.connect(_on_play_button_pressed)
	
	if continue_button:
		continue_button.mouse_entered.connect(_on_continue_button_hover)
		continue_button.mouse_exited.connect(_on_continue_button_exit)
		continue_button.pressed.connect(_on_continue_button_pressed)
	
	if settings_button:
		settings_button.mouse_entered.connect(_on_settings_button_hover)
		settings_button.mouse_exited.connect(_on_settings_button_exit)
		settings_button.pressed.connect(_on_settings_button_pressed)

func _on_button_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game_root.tscn")


func _on_button_continue_pressed() -> void:
	print("Continue pressed.")


func _on_button_settings_pressed() -> void:
	print("Settings pressed.")


func _on_play_button_hover():
	new_game_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_play_button_exit():
	new_game_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)

func _on_play_button_pressed():
	new_game_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_continue_button_hover():
	continue_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_continue_button_exit():
	continue_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)

func _on_continue_button_pressed():
	continue_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_settings_button_hover():
	settings_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_settings_button_exit():
	settings_label.self_modulate = Color(0.0, 0.0, 0.0, 1.0)

func _on_settings_button_pressed():
	settings_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

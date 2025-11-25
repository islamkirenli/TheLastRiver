extends ColorRect

@onready var pause_panel: Panel = $Panel
@onready var pause_continue_button: Button = $Panel/MarginContainer/VBox/ButtonContinue
@onready var pause_main_menu_button: Button = $Panel/MarginContainer/VBox/ButtonMainMenu
@onready var master_volume_slider: HSlider = $Panel/MarginContainer/VBox/VolumeRow/MasterVolumeSlider

func _ready() -> void:
	visible = false

	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	pause_main_menu_button.pressed.connect(_on_pause_main_menu_pressed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)

	_set_master_volume(master_volume_slider.value)


func toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	visible = tree.paused


func _on_pause_continue_pressed() -> void:
	var tree := get_tree()
	tree.paused = false
	visible = false


func _on_pause_main_menu_pressed() -> void:
	var tree := get_tree()
	tree.paused = false
	visible = false
	tree.change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_master_volume_changed(value: float) -> void:
	_set_master_volume(value)


func _set_master_volume(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, value)

extends TextureProgressBar

@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.7)
@export var fill_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var stroke_width: float = 6.0

func _ready() -> void:
	min_value = 0.0
	max_value = 100.0
	value = 100.0
	value_changed.connect(_on_value_changed)
	queue_redraw()  # <-- BUNU EKLE

func _on_value_changed(_new_val: float) -> void:
	queue_redraw()

func _draw() -> void:
	var size_vec: Vector2 = size
	var radius: float = minf(size_vec.x, size_vec.y) * 0.5 - stroke_width
	if radius <= 0.0:
		return

	var center: Vector2 = size_vec * 0.5

	# Arka halka
	draw_arc(
		center,
		radius,
		0.0,
		TAU,
		64,
		background_color,
		stroke_width
	)

	# Doluluk oranı
	var t: float = 0.0
	if max_value > min_value:
		t = (value - min_value) / (max_value - min_value)

	var from_angle: float = deg_to_rad(-90.0)
	var to_angle: float = from_angle + TAU * t

	# Dolan kısım
	draw_arc(
		center,
		radius,
		from_angle,
		to_angle - from_angle,
		64,
		fill_color,
		stroke_width
	)

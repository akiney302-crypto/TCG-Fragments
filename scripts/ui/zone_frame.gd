@tool
extends VBoxContainer

@export var frame_color: Color = Color(0.18, 0.42, 0.58, 0.9)
@export var fill_color: Color = Color(0.06, 0.1, 0.15, 0.45)

func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, fill_color, true)
	draw_rect(rect.grow(-1.0), frame_color, false, 2.0)

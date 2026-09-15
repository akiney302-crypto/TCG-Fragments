class_name CardView
extends Control

signal selected(card_view: CardView)

var card_instance: CardInstance
var is_selected: bool = false
var base_position: Vector2

@onready var artwork: TextureRect = $Artwork
@onready var name_label: Label = $NameLabel
@onready var type_label: Label = $TypeLabel
@onready var cost_label: Label = $CostLabel
@onready var attack_label: Label = $AttackLabel
@onready var life_label: Label = $LifeLabel
@onready var description_label: RichTextLabel = $Description
@onready var face_down_panel: Control = $FaceDown

func setup(instance: CardInstance) -> void:
	card_instance = instance
	if instance == null:
		return
	face_down_panel.visible = instance.face_down
	artwork.visible = not instance.face_down
	name_label.visible = not instance.face_down
	type_label.visible = not instance.face_down
	cost_label.visible = not instance.face_down
	attack_label.visible = not instance.face_down
	life_label.visible = not instance.face_down
	description_label.visible = not instance.face_down

	artwork.texture = instance.data.artwork
	name_label.text = instance.data.card_name
	type_label.text = instance.data.card_type
	cost_label.text = "COSTE %d" % instance.data.cost
	attack_label.text = "ATQ %d" % instance.current_attack
	life_label.text = "VIDA %d" % instance.current_life
	description_label.text = instance.data.description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.fit_content = false
	description_label.clip_contents = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	set_selected(false)
	base_position = position
	modulate.a = 0.0
	var enter_tween: Tween = create_tween()
	enter_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	enter_tween.parallel().tween_property(self, "position:y", position.y - 10.0, 0.18)
	enter_tween.tween_property(self, "position:y", position.y, 0.12)


func set_selected(value: bool) -> void:
	is_selected = value
	$SelectionOutline.visible = true
	$SelectionOutline.modulate = Color(0.2, 0.85, 1.0, 1.0) if value else Color(0.2, 0.85, 1.0, 0.0)
	var target_scale: Vector2 = Vector2(1.04, 1.04) if value else Vector2.ONE
	var target_y: float = -8.0 if value else 0.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.16)
	tween.parallel().tween_property(self, "position:y", target_y, 0.16)


func set_dimmed(value: bool) -> void:
	var target_modulate: Color = Color(0.52, 0.52, 0.58, 1.0) if value else Color.WHITE
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", target_modulate, 0.18)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit(self)
	
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			selected.emit(self)

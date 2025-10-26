extends CanvasLayer

signal on_transition_finishes

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	
func _process(delta: float) -> void:
	pass
	
func _on_animation_finished(anim_name) -> void:
	if anim_name == "fade_to_black":
		on_transition_finishes.emit()
		animation_player.play("fade_to_normal")
	elif anim_name == "fade_to_normal":
		color_rect.visible = false

func transition() -> void:
	color_rect.visible = true
	animation_player.play("fade_to_black")

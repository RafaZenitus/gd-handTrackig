extends Area2D

class_name Hand

var target_position: Vector2

@export var is_left_hand: bool = false

# smoothing_speed > mão mais rápido 
# smoothing_speed < mais suave.
var smoothing_speed := 0.1

func _ready() -> void:
	# Inicializa a posição alvo com a posição inicial do nó.
	target_position = position

func _process(delta: float) -> void:
	position = lerp(position, target_position, smoothing_speed) # suavização lerp() = transição suave.

func update_position(new_pos: Vector2) -> void:
	target_position = new_pos

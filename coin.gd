extends Area2D

class_name Coin

signal on_coin_collected

@export var max_scale: float = 1.0
var growth_speed: float = 0.3
@export var collectible_scale: float = 0.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_collectible: bool = false
var current_scale: float = 0.0

var color_mode: int = 1

func set_growth_speed(speed: float):
	growth_speed = speed
	print("Moeda spawnada com speed: ", "%.1f" % growth_speed)

func _ready() -> void:
	anim.play("spin")
	scale = Vector2.ZERO
	area_entered.connect(_on_area_entered)
	
func set_color_mode(mode: int):
	color_mode = mode
	_update_visual_color()

func _update_visual_color():
	# Determina a animação com base no modo
	var animation_name: String
	
	match color_mode:
		1:
			animation_name = "spin" 
		2:
			animation_name = "spin_red"
		3:
			animation_name = "spin_blue"
		_:
			animation_name = "spin" 

	if anim.animation != animation_name:
		anim.play(animation_name)
		anim.modulate = Color.WHITE
	
func _process(delta: float) -> void:
	_handle_growth(delta)
	_check_collectibility()

func _handle_growth(delta: float) -> void:
	# Crescimento da moeda
	if current_scale < max_scale:
		current_scale = move_toward(current_scale, max_scale, growth_speed * delta)
		scale = Vector2(current_scale, current_scale)

func _check_collectibility() -> void:
	# Verifica se a moeda é coletável
	if not is_collectible and current_scale >= collectible_scale:
		is_collectible = true
		print("Moeda coletavel")

func _on_area_entered(area: Area2D) -> void:
	if not area is Hand:
		return

	if not is_collectible:
		return
		
	var hand_node: Hand = area
	
	var can_be_collected: bool = false
	
	# Lógica de Restrição de Mão
	match color_mode:
		1: can_be_collected = true
		2: can_be_collected = (hand_node.is_left_hand == true)
		3: can_be_collected = (hand_node.is_left_hand == false)
	
	# Execução da Coleta
	if can_be_collected:
		print("Moeda coletada!")
		on_coin_collected.emit()
		queue_free()
	else:
		print("Tentativa inválida! Esta moeda requer a mão ", "Direita" if color_mode == 2 else "Esquerda")

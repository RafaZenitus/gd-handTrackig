extends Area2D

class_name Coin

signal on_coin_collected

@export var max_scale: float = 1.0
@export var growth_speed: float = 0.3
@export var collectible_scale: float = 0.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_collectible: bool = false
var current_scale: float = 0.0

func _ready() -> void:
	anim.play("spin")
	scale = Vector2.ZERO
	area_entered.connect(_on_area_entered)

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
	if is_collectible and area is Hand:
		print("Moeda coletada!")
		on_coin_collected.emit()
		queue_free()

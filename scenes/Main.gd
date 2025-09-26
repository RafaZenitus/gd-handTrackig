extends Node

var server := TCPServer.new()
var client : StreamPeerTCP
var buffer := ""

@onready var viewport_size := get_viewport().get_visible_rect().size

@onready var left_hand: Hand = $Left_
@onready var right_hand: Hand = $Right_

@export var coin_scene: PackedScene 

var coin_patterns: Dictionary = {
	"C_DOWN": {
		"left": [
			Vector2(350, 300), Vector2(300, 550), Vector2(350, 800)
		],
		"right": [
			Vector2(1500, 300), Vector2(1550, 550), Vector2(1500, 800)
		]
	},
	"C_UP": {
		"left": [
			Vector2(350, 800), Vector2(300, 550), Vector2(350, 300)
		],
		"right": [
			Vector2(1500, 800), Vector2(1550, 550), Vector2(1500, 300)
		]
	}
}

func _ready():
	var port = 12345
	var error = server.listen(port)
	if error == OK:
		print("Servidor TCP ouvindo na porta ", port)
	else:
		print("Erro ao iniciar o servidor: ", error)
		
	# Atraso de início
	await get_tree().create_timer(2.0).timeout
	
	
	# C descendo Esquerda
	spawn_pattern("C_DOWN", true)
	await get_tree().create_timer(4.0).timeout
	
	# C descendo Direita
	spawn_pattern("C_DOWN", false)
	await get_tree().create_timer(4.0).timeout
	
	# C subindo Esquerda
	spawn_pattern("C_UP", true)
	await get_tree().create_timer(4.0).timeout
	
	# C subindo Direita
	spawn_pattern("C_UP", false)

func _process(_delta):
	if not client and server.is_connection_available():
		client = server.take_connection()
		print("Cliente conectado!")

	if client and client.get_available_bytes() > 0:
		var raw = client.get_utf8_string(client.get_available_bytes())
		buffer += raw

		while buffer.find("\n") != -1:
			var newline_index = buffer.find("\n")
			var message = buffer.substr(0, newline_index)
			buffer = buffer.substr(newline_index + 1)

			var hands_data = JSON.parse_string(message)
			if typeof(hands_data) == TYPE_DICTIONARY:
				
				# Itera sobre a mão Left
				if hands_data.has("Left"):
					var left_hand_data = hands_data["Left"]
					var is_left_hand_visible = left_hand_data.get("visible", false)
					
					if is_left_hand_visible:
						var left_landmarks = left_hand_data["landmarks"]
						if left_landmarks.size() > 3:
							var hand_point = left_landmarks[3]
							
							var x_norm = hand_point["x"]
							var y_norm = hand_point["y"]
							
							var margin := 50.0
							var x_pos = clamp((x_norm) * viewport_size.x, margin, viewport_size.x - margin)
							var y_pos = clamp(y_norm * viewport_size.y, margin, viewport_size.y - margin)
							
							var new_position = Vector2(x_pos, y_pos)
							left_hand.update_position(new_position)
							
				# Itera sobre a mão Right
				if hands_data.has("Right"):
					var right_hand_data = hands_data["Right"]
					var is_right_hand_visible = right_hand_data.get("visible", false)
					
					if is_right_hand_visible:
						var right_landmarks = right_hand_data["landmarks"]
						if right_landmarks.size() > 3:
							var hand_point = right_landmarks[3]
							
							var x_norm = hand_point["x"]
							var y_norm = hand_point["y"]
							
							var margin := 50.0
							var x_pos = clamp((x_norm) * viewport_size.x, margin, viewport_size.x - margin)
							var y_pos = clamp(y_norm * viewport_size.y, margin, viewport_size.y - margin)
							
							var new_position = Vector2(x_pos, y_pos)
							right_hand.update_position(new_position)
							
			else:
				print("JSON inválido ou inesperado:", message)
				
func spawn_pattern(pattern_name: String, is_left: bool):
	var pattern_data = coin_patterns.get(pattern_name)
	
	if pattern_data == null:
		print("ERRO: Padrão não encontrado: ", pattern_name)
		return

	var hand_key = "left" if is_left else "right"
	var positions: Array = pattern_data.get(hand_key, [])
	
	if positions.is_empty():
		print("AVISO: Nenhuma posição encontrada para a mão ", hand_key, " no padrão ", pattern_name)
		return
	
	var delay = 0.5

	for i in range(positions.size()):
		var pos = positions[i]
		await get_tree().create_timer(i * delay).timeout
		
		var coin_instance = coin_scene.instantiate()
		add_child(coin_instance)
		coin_instance.position = pos

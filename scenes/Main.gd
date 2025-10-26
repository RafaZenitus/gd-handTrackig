extends Node

var server := TCPServer.new()
var client : StreamPeerTCP
var buffer := ""

var venv_dir = "venv_godot/"

@onready var viewport_size := get_viewport().get_visible_rect().size

@onready var left_hand: Hand = $Left_
@onready var right_hand: Hand = $Right_


@export var coin_scene: PackedScene 


var current_selected_pattern: String = ""
var current_coin_mode: int = 1

var coin_patterns: Dictionary = {
	#-----------------------------#
	#       Movimentos em C       #
	#-----------------------------#
	"C_LEFT": {
		"left": [
			Vector2(350, 300), Vector2(300, 550), Vector2(350, 800)
		],
		"right": [
			Vector2(350, 800), Vector2(300, 550), Vector2(350, 300)
			#Vector2(1500, 300), Vector2(1550, 550), Vector2(1500, 800)
		]
	},
	"C_RIGHT": {
		"left": [
			Vector2(1500, 300), Vector2(1550, 550), Vector2(1500, 800)
			#Vector2(350, 800), Vector2(300, 550), Vector2(350, 300)
		],
		"right": [
			Vector2(1500, 800), Vector2(1550, 550), Vector2(1500, 300)
		]
	},
	#-----------------------------#
	#   Movimentos Horizontais    #
	#-----------------------------#
	"H_UP": {
		"left": [
			Vector2(250, 150), Vector2(750, 150), Vector2(1250, 150), Vector2(1700, 150), 
		],
		"right": [
			Vector2(1700, 150), Vector2(1250, 150), Vector2(750, 150), Vector2(250, 150), 
		]
	},
	"H_DOWN": {
		"left": [
			Vector2(250, 850), Vector2(750, 850), Vector2(1250, 850), Vector2(1700, 850), 
		],
		"right": [
			Vector2(1700, 850), Vector2(1250, 850), Vector2(750, 850), Vector2(250, 850), 
		]
	},
	#-----------------------------#
	#     Movimentos Verticais    #
	#-----------------------------#
	"V_LEFT": {
		"left": [
			Vector2(250, 150), Vector2(250, 500), Vector2(250, 850) 
		],
		"right": [
			Vector2(250, 850), Vector2(250, 500), Vector2(250, 150) 
		]
	},
	"V_RIGHT": {
		"left": [
			Vector2(1700, 150), Vector2(1700, 500), Vector2(1700, 850)
		],
		"right": [
			Vector2(1700, 850), Vector2(1700, 500), Vector2(1700, 150)
		]
	},
}

func _ready():
	var port = 12345
	var error = server.listen(port)
	if error == OK:
		print("Servidor TCP ouvindo na porta ", port)
	else:
		print("Erro ao iniciar o servidor: ", error)
	
	#await get_tree().create_timer(5.0).timeout
	#spawn_pattern("V_DOWN", true)
	#await get_tree().create_timer(4.0).timeout
	#spawn_pattern("H_DOWN", true)
	#await get_tree().create_timer(4.0).timeout
	#spawn_pattern("V_UP", false)
	#await get_tree().create_timer(4.0).timeout
	#spawn_pattern("H_UP", false)

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
				
				
func spawn_pattern(pattern_name: String, is_left: bool, coin_mode: int):
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
		
		coin_instance.set_color_mode(coin_mode)
		
func _unhandled_input(event: InputEvent):
	if event.is_pressed():
		
		# --- SELEÇÃO DA MOEDA  --- #
		
		if event.is_action_pressed("KEY_1"):
			current_coin_mode = 1
			print("MODO DE MOEDA: Amarela (Qualquer Mão)")
			
		elif event.is_action_pressed("KEY_2"):
			current_coin_mode = 2
			print("MODO DE MOEDA: Vermelha (Apenas Mão Esquerda)")
			
		elif event.is_action_pressed("KEY_3"):
			current_coin_mode = 3
			print("MODO DE MOEDA: Azul (Apenas Mão Direita)")
		
		# --- SELEÇÃO DO PADRÃO --- #
		
		#-----------------------------#
		#   Movimentos Horizontais    #
		#-----------------------------#
		if event.is_action("select_h_up"):
			current_selected_pattern = "H_UP"
			print("Padrão: H_UP (Horizontal, Cima) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		elif event.is_action("select_h_down"):
			current_selected_pattern = "H_DOWN"
			print("Padrão: H_DOWN (Horizontal, Baixo) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		#-----------------------------#
		#     Movimentos Verticais    #
		#-----------------------------#
		elif event.is_action("select_v_up"):
			current_selected_pattern = "V_LEFT"
			print("Padrão: V_LEFT (Vertical, Esquerda) selecionado. Pressione Seta Esquerda/Direita para iniciar.")

		elif event.is_action("select_v_down"):
			current_selected_pattern = "V_RIGHT"
			print("Padrão: V_RIGHT (Vertical, Direita) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		#-----------------------------#
		#       Movimentos em C       #
		#-----------------------------#
		elif event.is_action("select_c_up"):
			current_selected_pattern = "C_LEFT"
			print("Padrão: C_LEFT (Curva C, Esquerda) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		elif event.is_action("select_c_down"):
			current_selected_pattern = "C_RIGHT"
			print("Padrão: C_RIGHT (Curva C, Direita) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		# --- SELEÇÃO DA DIREÇÃO --- #
		
		# Direção Direita
		elif event.is_action("execute_right"):
			if current_selected_pattern != "":
				print("-> EXECUTANDO " + str(current_selected_pattern) + " na Direção DIREITA")
				spawn_pattern(current_selected_pattern, true, current_coin_mode) 
				current_selected_pattern = ""
				
		# Direção Esquerda
		elif event.is_action("execute_left"):
			if current_selected_pattern != "":
				print("-> EXECUTANDO " + str(current_selected_pattern) + " na Direção ESQUERDA")
				spawn_pattern(current_selected_pattern, false, current_coin_mode)
				current_selected_pattern = ""

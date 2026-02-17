extends Node

var server := TCPServer.new()
var client : StreamPeerTCP
var buffer := ""

var venv_dir = "venv_godot/"

@onready var viewport_size := get_viewport().get_visible_rect().size

@onready var left_hand: Hand = $Left_
@onready var right_hand: Hand = $Right_
@onready var label: Label = $Label


@export var coin_scene: PackedScene 

var current_selected_pattern: String = ""
var current_coin_mode: int = 1

var session_coins_count: int = 0

var loop_active: bool = false
var loop_timer: SceneTreeTimer = null
var loop_pattern_name: String = "LOOP_PATTERN"

var current_growth_speed: float = 0.3
const MIN_GROWTH_SPEED: float = 0.1
const MAX_GROWTH_SPEED: float = 2.0

var coin_patterns: Dictionary = {
	#-----------------------------#
	# 	 	Movimentos em C	 	 #
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
	# 	Movimentos Horizontais 	 #
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
	# 	 Movimentos Verticais     #
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
	# 1. ACEITA NOVA CONEXÃO
	if not client and server.is_connection_available():
		client = server.take_connection()
		print("Cliente conectado!")
		
		# ======================================================================
		# AÇÃO CRÍTICA: Envia os metadados da sessão para o cliente Python.
		# O cliente Python espera este JSON imediatamente após a conexão.
		# ======================================================================
		var metadata = PatientManager.get_current_session_metadata()
		if metadata:
			var json_string = JSON.stringify(metadata) + "\n"
			client.put_data(json_string.to_utf8_buffer())
			print("Metadados da sessão enviados: " + json_string.strip_edges())
		else:
			print("AVISO: Paciente não logado. Metadados básicos não enviados.")

	# 2. PROCESSA DADOS RECEBIDOS
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
	var dynamic_delay = 1.0 / (current_growth_speed + 0.5) 
	if dynamic_delay > 1.0: dynamic_delay = 1.0
	if dynamic_delay < 0.1: dynamic_delay = 0.1
	
	for i in range(positions.size()):
		var pos = positions[i]
		if i > 0:
			await get_tree().create_timer(dynamic_delay).timeout
		
		var coin_instance = spawn_coin_at(pos, is_left, coin_mode)

	#-----------------------------#
	# 	 Limpar Moedas da Tela    #
	#-----------------------------#
		
		
func clear_all_coins():
	var coins_to_remove = []
	for child in get_children():
		if child is Coin:
			coins_to_remove.append(child)
	for coin in coins_to_remove:
		coin.queue_free()

func cancel_and_clear():
	if loop_active:
		loop_active = false
		print("Loop de moedas cancelado.")
	clear_all_coins()
	print("Todas as moedas da tela foram removidas.")
		
	#-----------------------------#
	# 	    Funções de Loops      #
	#-----------------------------#
	
func start_new_loop(loop_function):
	if not loop_active:
		cancel_and_clear() 
		
		loop_active = true
		print("-> INICIANDO NOVO PADRÃO DE LOOP...")
		loop_function.call()
	else:
		print("AVISO: Um loop já está ativo. Pressione Espaço para cancelar.")

func spawn_coin_at(pos: Vector2, is_left: bool, coin_mode: int) -> Coin:
	var coin_instance = coin_scene.instantiate()
	add_child(coin_instance)
	coin_instance.position = pos
	
	coin_instance.on_coin_collected.connect(self._on_coin_collected) 
	
	coin_instance.set_color_mode(coin_mode)
	
	coin_instance.set_growth_speed(current_growth_speed)
	
	return coin_instance
		
	#-----------------------------#
	#  Funções de Loop Vertical   #
	#-----------------------------#
		
func start_loop_pattern_v():
	if loop_active:
		
		print("--- INICIANDO NOVA ITERAÇÃO DO LOOP VERTICAL (V) ---")

		# Padrão: 2 na esquerda (Vermelha - Modo 2)
		var coin1 = spawn_coin_at(Vector2(250, 400), true, 2)
		print("1. Moeda Vermelha no alto. Esperando coleta...")
		await coin1.on_coin_collected
		
		var coin2 = spawn_coin_at(Vector2(250, 700), true, 2)
		print("2. Moeda Vermelha em baixo. Esperando coleta...")
		await coin2.on_coin_collected
		
		# Padrão: 2 na direita (Azul - Modo 3)
		var coin3 = spawn_coin_at(Vector2(1700, 400), false, 3)
		print("3. Moeda Azul no alto. Esperando coleta...")
		await coin3.on_coin_collected
		
		var coin4 = spawn_coin_at(Vector2(1700, 700), false, 3)
		print("4. Moeda Azul em baixo. Esperando coleta...")
		await coin4.on_coin_collected
		
		print("Todas as moedas da iteração coletadas. Aguardando 1.0s para reiniciar...")
		await get_tree().create_timer(1.0).timeout
		
		if loop_active:
			start_loop_pattern_v()
		else:
			print("Loop V desativado.")
			
	#-----------------------------#
	#  Funções de Loop Horizontal #
	#-----------------------------#
func start_loop_pattern_h():
	if loop_active:
		print("--- INICIANDO NOVA ITERAÇÃO DO LOOP HORIZONTAL (H) ---")

		# Padrão Horizontal Esquerda (Mão Esquerda / Vermelha)
		
		# 1. Moeda Esquerda - Posição mais para fora (X=350)
		var coin1 = spawn_coin_at(Vector2(350, 550), true, 2)
		print("1. Moeda Vermelha 1 no local. Esperando coleta...")
		await coin1.on_coin_collected
		
		# 2. Moeda Esquerda - Posição mais para dentro (X=650)
		#var coin2 = spawn_coin_at(Vector2(650, 550), true, 2)
		#print("2. Moeda Vermelha 2 no local. Esperando coleta...")
		#await coin2.on_coin_collected
		
		# Padrão Horizontal Direita (Mão Direita / Azul)
		
		# 3. Moeda Direita - Posição mais para dentro (X=1550)
		var coin3 = spawn_coin_at(Vector2(1550, 550), false, 3)
		print("3. Moeda Azul 1 no local. Esperando coleta...")
		await coin3.on_coin_collected
		
		# 4. Moeda Direita - Posição mais para fora (X=1250)
		#var coin4 = spawn_coin_at(Vector2(1250, 550), false, 3)
		#print("4. Moeda Azul 2 no local. Esperando coleta...")
		#await coin4.on_coin_collected
		
		print("Todas as moedas da iteração coletadas. Aguardando 1.0s para reiniciar...")
		await get_tree().create_timer(1.0).timeout
		
		if loop_active:
			start_loop_pattern_h()
		else:
			print("Loop H desativado.")
			
	#-----------------------------#
	# Funções de Loop Em Meia Lua #
	#-----------------------------#
			
func start_loop_pattern_c():
	if loop_active:
		print("--- INICIANDO NOVA ITERAÇÃO DO LOOP CURVA C (C) ---")
		
		# Padrão Curva C Esquerda (Mão Esquerda / Vermelha) - 3 moedas
		var c_left_positions = [
			Vector2(350, 300), Vector2(300, 550), Vector2(350, 800)
		]
		
		# O loop garante a espera de coleta entre cada moeda
		for pos in c_left_positions:
			var coin = spawn_coin_at(pos, true, 2)
			print("C_LEFT Moeda no local. Esperando coleta...")
			await coin.on_coin_collected
			
		# Padrão Curva C Direita (Mão Direita / Azul) - 3 moedas
		var c_right_positions = [
			Vector2(1500, 300), Vector2(1550, 550), Vector2(1500, 800)
		]

		for pos in c_right_positions:
			var coin = spawn_coin_at(pos, false, 3)
			print("C_RIGHT Moeda no local. Esperando coleta...")
			await coin.on_coin_collected
		
		print("Todas as moedas da iteração coletadas. Aguardando 1.0s para reiniciar...")
		
		await get_tree().create_timer(1.0).timeout
		
		if loop_active:
			start_loop_pattern_c()
		else:
			print("Loop C desativado.")
		
func _unhandled_input(event: InputEvent):
	if event.is_pressed():
		
		# --- LIMPAR MOEDAS ---
		if event.is_action_pressed("clear_coins"):
			cancel_and_clear()
			current_selected_pattern = ""
		
		# --- SELEÇÃO DA MOEDA	--- #
		
		elif event.is_action_pressed("KEY_1"):
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
		# 	Movimentos Horizontais 	 #
		#-----------------------------#
		if event.is_action("select_h_up"):
			current_selected_pattern = "H_UP"
			print("Padrão: H_UP (Horizontal, Cima) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		elif event.is_action("select_h_down"):
			current_selected_pattern = "H_DOWN"
			print("Padrão: H_DOWN (Horizontal, Baixo) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		#-----------------------------#
		# 	 	Movimentos Verticais 	 #
		#-----------------------------#
		elif event.is_action("select_v_up"):
			current_selected_pattern = "V_LEFT"
			print("Padrão: V_LEFT (Vertical, Esquerda) selecionado. Pressione Seta Esquerda/Direita para iniciar.")

		elif event.is_action("select_v_down"):
			current_selected_pattern = "V_RIGHT"
			print("Padrão: V_RIGHT (Vertical, Direita) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		#-----------------------------#
		# 	 	Movimentos em C	 	 #
		#-----------------------------#
		elif event.is_action("select_c_up"):
			current_selected_pattern = "C_LEFT"
			print("Padrão: C_LEFT (Curva C, Esquerda) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
			
		elif event.is_action("select_c_down"):
			current_selected_pattern = "C_RIGHT"
			print("Padrão: C_RIGHT (Curva C, Direita) selecionado. Pressione Seta Esquerda/Direita para iniciar.")
		
		#-----------------------------#
		# 	 Loop Vertical (Q)	 	  #
		#-----------------------------#	

		elif event.is_action_pressed("select_loop_v"):
			start_new_loop(start_loop_pattern_v)
			
		#-----------------------------#
		# 	 Loop Horizontal (W)	 #
		#-----------------------------#	

		elif event.is_action_pressed("select_loop_h"):
			start_new_loop(start_loop_pattern_h)
			
		#-----------------------------#
		# 	 Loop Curva C (E)	      #
		#-----------------------------#		

		elif event.is_action_pressed("select_loop_c"):
			start_new_loop(start_loop_pattern_c)
			
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
				
		if event.is_action_pressed("ui_cancel"):
			PatientManager.update_progress(session_coins_count)
			session_coins_count = 0
			get_tree().change_scene_to_file("res://selection_menu/selection_menu.tscn")
			
		# --- SELEÇÃO DA VELOCIDADE --- #
		
		# Aumentar Velocidade (+)
		elif event.is_action_pressed("increase_speed"):
			current_growth_speed = clamp(current_growth_speed + 0.1, MIN_GROWTH_SPEED, MAX_GROWTH_SPEED)
			print("Velocidade de crescimento AUMENTADA: ", "%.1f" % current_growth_speed)
			
		# Diminuir Velocidade (-)
		elif event.is_action_pressed("decrease_speed"):
			current_growth_speed = clamp(current_growth_speed - 0.1, MIN_GROWTH_SPEED, MAX_GROWTH_SPEED)
			print("Velocidade de crescimento DIMINUIDA: ", "%.1f" % current_growth_speed)
				
func _on_coin_collected():
	session_coins_count += 1
	label.text = "%03d" % session_coins_count

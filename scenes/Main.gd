extends Node

var server := TCPServer.new()
var client : StreamPeerTCP
var buffer := ""

@onready var viewport_size := get_viewport().get_visible_rect().size
@onready var left_hand := $Left
@onready var right_hand := $Right

func _ready():
	var port = 12345
	var error = server.listen(port)
	if error == OK:
		print("Servidor TCP ouvindo na porta ", port)
	else:
		print("Erro ao iniciar o servidor: ", error)

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

			var data = JSON.parse_string(message)
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("landmarks") and data["landmarks"].size() > 0:
					var hand_point = data["landmarks"][3] #pontos_mao = [0, 4, 8, ->|9|<-, 12, 16, 20]
					var x_norm = hand_point["x"]
					var y_norm = hand_point["y"]
					
					var margin := 50.0
					var x_pos = clamp((1.0 - x_norm) * viewport_size.x, margin, viewport_size.x - margin)
					var y_pos = clamp(y_norm * viewport_size.y, margin, viewport_size.y - margin)



					if data["handedness"] == "Left":
						left_hand.position = Vector2(x_pos, y_pos)
					elif data["handedness"] == "Right":
						right_hand.position = Vector2(x_pos, y_pos)
			else:
				print("JSON inválido ou inesperado:", message)

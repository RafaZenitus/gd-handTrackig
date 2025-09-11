# servidor_tcp.gd
extends Node

var server := TCPServer.new()
var client : StreamPeerTCP
var buffer := ""

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

		# Processa mensagens completas (delimitadas por "\n")
		while buffer.find("\n") != -1:
			var newline_index = buffer.find("\n")
			var message = buffer.substr(0, newline_index)
			buffer = buffer.substr(newline_index + 1)

			var data = JSON.parse_string(message)
			if typeof(data) == TYPE_ARRAY:
				print("Landmarks recebidos (", data.size(), " pontos):")
				for i in data.size():
					var point = data[i]
					print("Ponto ", i, ": x=", point["x"], ", y=", point["y"])
			else:
				print("JSON inválido ou inesperado:", message)

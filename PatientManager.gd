extends Node

const FILE_PATH = "user://patients_data.json"

var patients_data: Dictionary = {}
var current_patient_id: String = "" # ID do paciente logado

func _ready():
	load_patients()

# ==============================================================================
# 						PERSISTÊNCIA 						
# ==============================================================================

func load_patients():
	var file = FileAccess.open(FILE_PATH, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var content = file.get_as_text()
		patients_data = JSON.parse_string(content)
		file.close()
		# Garante que seja um dicionário caso o JSON esteja vazio
		if patients_data == null:
			patients_data = {}
		print("Dados de pacientes carregados.")
	else:
		# Se o arquivo não existe, inicializa com um dicionário vazio
		patients_data = {}
		print("Arquivo de pacientes não encontrado. Criando um novo.")

func save_patients():
	var file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		var content = JSON.stringify(patients_data, "\t") # Formatação com tabulação
		file.store_string(content)
		file.close()
		print("Dados de pacientes salvos com sucesso.")
	else:
		print("ERRO ao salvar dados de pacientes.")

# ==============================================================================
# 						 (CRUD) 						
# ==============================================================================

func get_patient_id(name: String) -> String:
	return name.strip_edges().replace(" ", "_")

# 1. CRIAR/ADICIONAR/EDITAR
func create_or_update_patient(name: String) -> bool:
	var id = get_patient_id(name)
	if id == "":
		return false 

	if not patients_data.has(id):
		# Cria novo paciente
		patients_data[id] = {
			"name": name,
			"total_coins_collected": 0,
			"last_session_record": 0,
			"last_session_date": Time.get_date_string_from_system() 
		}
	else:
		# Apenas atualiza o nome se o ID for o mesmo
		patients_data[id].name = name

	save_patients()
	return true

# 2. PESQUISAR
func get_patient_data(name_or_id: String) -> Dictionary:
	var id = get_patient_id(name_or_id)
	if patients_data.has(id):
		return patients_data[id]
	
	# Tenta pesquisar pelo nome exato
	for key in patients_data:
		if patients_data[key].name.to_lower() == name_or_id.to_lower():
			return patients_data[key]

	return {} 

# 3. EXCLUIR
func delete_patient(name_or_id: String) -> bool:
	var id = get_patient_id(name_or_id)
	if patients_data.has(id):
		patients_data.erase(id)
		if current_patient_id == id:
			current_patient_id = ""
		save_patients()
		return true
	return false

# 4. LOGAR
func login_patient(name_or_id: String) -> bool:
	var data = get_patient_data(name_or_id)
	if data:
		current_patient_id = get_patient_id(data.name)
		return true
	current_patient_id = ""
	print("Falha ao logar paciente.")
	return false
	
# ==============================================================================
# 						ATUALIZAÇÃO DO PROGRESSO 						
# ==============================================================================

func update_progress(coins_collected_in_session: int):
	if current_patient_id == "":
		print("AVISO: Nenhum paciente logado para salvar o progresso.")
		return

	var id = current_patient_id
	var data = patients_data[id]

	data.total_coins_collected += coins_collected_in_session
	data.last_session_date = Time.get_date_string_from_system()

	if coins_collected_in_session > data.last_session_record:
		data.last_session_record = coins_collected_in_session
	
	save_patients()

# ==============================================================================
# EXPORTAÇÃO DE METADADOS
# ==============================================================================

func _get_current_patient_data_internal() -> Dictionary:
	if current_patient_id == "":
		return {}
	
	if patients_data.has(current_patient_id):
		return patients_data[current_patient_id]
	
	return {}

func get_current_session_metadata() -> Dictionary:
	var data = _get_current_patient_data_internal()
	
	if data.is_empty():
		return {
			"name": "Anonimo",
			"date": Time.get_date_string_from_system(),
			"time": Time.get_time_string_from_system()
		}

	return {
		"name": data.name,
		"date": Time.get_date_string_from_system(),
		"time": Time.get_time_string_from_system()
	}

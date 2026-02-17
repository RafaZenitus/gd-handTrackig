extends Control # Ou Node

@onready var search_name: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SearchName

func _on_login_create_button_pressed():
	var name = search_name.text.strip_edges()
	
	if name.is_empty():
		print("O nome não pode ser vazio.")
		return
		
	if PatientManager.login_patient(name):
		print("Paciente %s logado com sucesso. Iniciando jogo..." % name)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
		
	var create_success = PatientManager.create_or_update_patient(name)
	if create_success:
		if PatientManager.login_patient(name):
			print("Novo paciente %s criado e logado. Iniciando jogo..." % name)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("Erro ao criar paciente %s." % name)

func _on_delete_button_pressed():
	var name = search_name.text.strip_edges()
	
	if name.is_empty():
		print("O nome não pode ser vazio para exclusão.")
		return
		
	if PatientManager.delete_patient(name):
		print("Paciente %s excluído com sucesso." % name)
		search_name.text = ""
	else:
		print("Paciente %s não encontrado para exclusão." % name)

func _on_name_input_text_changed(new_text):
	var data = PatientManager.get_patient_data(new_text)

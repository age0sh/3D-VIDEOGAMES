extends Control

# --- RANURAS DEL INSPECTOR (PANELES) ---
@export var main_buttons_panel: Control
@export var options_panel: Control

# --- RANURAS DEL INSPECTOR (SLIDERS DE AUDIO) ---
# ¡Arrastra tus sliders aquí desde el panel de escena!
@export var menu_slider: HSlider
@export var game_slider: HSlider

# --- Referencias a los botones ---
# (Usamos @onready para los botones porque sus nombres suelen ser fijos)
@onready var new_game_button: Button = $MainButtons/NewGameButton
@onready var load_game_button: Button = $MainButtons/LoadGameButton
@onready var options_button: Button = $MainButtons/OptionsButton
@onready var exit_button: Button = $MainButtons/ExitButton
# Nota: Como moviste el BackButton dentro de OptionsContainer, revisa esta ruta:
@onready var back_button: Button = $OptionsPanel/OptionsContainer/BackButton

func _ready():
	# Hacemos que el mouse sea visible en el menú
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# --- CONEXIONES DE BOTONES ---
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# --- CONEXIONES DE AUDIO ---
	
	# 1. Configuración del Slider de Menú
	if menu_slider:
		menu_slider.value_changed.connect(_on_menu_music_changed)
		menu_slider.min_value = 0.0
		menu_slider.max_value = 100.0
		
		# LEER VOLUMEN ACTUAL: Preguntamos al bus "Music" cómo está
		var bus_idx = AudioServer.get_bus_index("Music")
		# Convertimos de dB a porcentaje (0-100)
		menu_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0
		
	# 2. Configuración del Slider de Juego
	if game_slider:
		game_slider.value_changed.connect(_on_game_music_changed)
		game_slider.min_value = 0.0
		game_slider.max_value = 100.0
		
		# LEER VOLUMEN ACTUAL: Preguntamos al bus "GameMusic" cómo está
		var bus_idx = AudioServer.get_bus_index("GameMusic")
		game_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) * 100.0
	
	# --- LÓGICA DE CARGAR PARTIDA ---
	if !GameManager.does_save_file_exist():
		load_game_button.disabled = true
		load_game_button.text = "Cargar Partida (Vacío)"
	
	# Iniciar mostrando el menú principal
	options_panel.hide()
	main_buttons_panel.show()


# --- FUNCIONES DE AUDIO ---

func _on_menu_music_changed(value):
	# Controla el Bus "Music" (Menú)
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))

func _on_game_music_changed(value):
	# Controla el Bus "GameMusic" (Juego)
	var bus_index = AudioServer.get_bus_index("GameMusic")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))


# --- FUNCIONES DE BOTONES ---

func _on_new_game_pressed():
	GameManager.load_requested = false
	GameManager.reset_lives() # Volvemos a ponerlas en 3
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://mundo.tscn")
func _on_load_game_pressed():
	GameManager.load_requested = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://mundo.tscn")

func _on_options_pressed():
	options_panel.show()
	main_buttons_panel.hide()

func _on_exit_pressed():
	get_tree().quit()

func _on_back_pressed():
	main_buttons_panel.show()
	options_panel.hide()

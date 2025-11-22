extends Control

# --- BARRAS Y TEXTO ---
@export var health_bar: TextureProgressBar
@export var stamina_bar: TextureProgressBar
@export var coin_label: Label
@export var lives_label: Label # <-- Arrastra tu LabelVidas aquí

# --- PANELES ---
@export var game_over_panel: Control 
@export var victory_panel: Control 
@export var pause_panel: Control
@export var fog_warning_panel: Control # <-- ¡NUEVO! (Arrastra FogWarningPanel)
@export var fog_timer_label: Label     # <-- ¡NUEVO! (Arrastra TimerLabel)

# --- MENÚ DE PAUSA ---
@export var pause_menu_container: VBoxContainer
@export var pause_audio_container: VBoxContainer
@export var pause_menu_slider: HSlider
@export var pause_game_slider: HSlider

# --- BOTONES (Referencias internas) ---
@onready var g_new_game_button = $GameOverPanel/VBoxContainer/NewGameButton
@onready var g_menu_button = $GameOverPanel/VBoxContainer/MenuButton
@onready var v_menu_button = $VictoryPanel/VBoxContainer/MenuButton # (Ajusta la ruta si es necesario)
@onready var pause_button = $PauseButton 
@onready var p_resume_button = $PausePanel/MenuContainer/ResumeButton
@onready var p_save_game_button = $PausePanel/MenuContainer/SaveGameButton
@onready var p_options_button = $PausePanel/MenuContainer/OptionsButton
@onready var p_menu_button = $PausePanel/MenuContainer/MenuButton
@onready var p_back_audio_button = $PausePanel/AudioContainer/BackFromOptionsButton

var player_reference = null

func _ready():
	# Conexiones Botones
	g_new_game_button.pressed.connect(_on_gameover_new_game)
	g_menu_button.pressed.connect(_on_gameover_menu)
	
	# Verifica si v_menu_button existe antes de conectar (por si cambiaste nombres)
	if v_menu_button: v_menu_button.pressed.connect(_on_gameover_menu)
	
	pause_button.pressed.connect(toggle_pause)
	p_resume_button.pressed.connect(toggle_pause)
	p_save_game_button.pressed.connect(_on_save_game_pressed)
	p_menu_button.pressed.connect(_on_gameover_menu)
	p_options_button.pressed.connect(_on_pause_options_pressed)
	p_back_audio_button.pressed.connect(_on_pause_back_pressed)
	
	# Conexiones Sliders
	if pause_menu_slider: pause_menu_slider.value_changed.connect(_on_menu_music_changed)
	if pause_game_slider: pause_game_slider.value_changed.connect(_on_game_music_changed)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_pause"):
		toggle_pause()

# --- CONEXIÓN CON JUGADOR ---
func connect_to_player(player_node):
	player_reference = player_node
	
	# Stats
	player_node.health_updated.connect(update_health_bar)
	player_node.stamina_updated.connect(update_stamina_bar)
	player_node.coins_updated.connect(update_coins_label)
	player_node.lives_updated.connect(update_lives_label)
	
	
	# Estados
	player_node.player_died.connect(_on_player_died)
	player_node.game_won.connect(_on_game_won)
	
	# Niebla (¡RECUPERADO!)
	player_node.fog_warning_changed.connect(_on_fog_warning_changed)
	player_node.fog_timer_updated.connect(_on_fog_timer_updated)
	
	# Inicializar valores
	update_health_bar(player_node.current_health, player_node.max_health)
	update_stamina_bar(player_node.current_stamina, player_node.max_stamina)
	update_coins_label(player_node.current_coins)
	update_lives_label(GameManager.player_lives)
# --- FUNCIONES DE ACTUALIZACIÓN VISUAL ---
func update_health_bar(val, max_v): if health_bar: health_bar.value = val
func update_stamina_bar(val, max_v): if stamina_bar: stamina_bar.value = val
func update_coins_label(amount): if coin_label: coin_label.text = "MONEDAS x %s" % amount

# --- NIEBLA (¡NUEVO!) ---
func _on_fog_warning_changed(visible_status, duration):
	if fog_warning_panel:
		fog_warning_panel.visible = visible_status
	if visible_status and fog_timer_label:
		fog_timer_label.text = "%.1f" % duration

func _on_fog_timer_updated(time_left):
	if fog_timer_label:
		fog_timer_label.text = "%.1f" % time_left

# --- PAUSA Y AUDIO ---
func toggle_pause():
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		pause_panel.show()
		pause_menu_container.show(); pause_audio_container.hide()
		update_sliders_visuals()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		pause_panel.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_sliders_visuals():
	var m_idx = AudioServer.get_bus_index("Music")
	var g_idx = AudioServer.get_bus_index("GameMusic")
	if pause_menu_slider: pause_menu_slider.value = db_to_linear(AudioServer.get_bus_volume_db(m_idx)) * 100
	if pause_game_slider: pause_game_slider.value = db_to_linear(AudioServer.get_bus_volume_db(g_idx)) * 100

func _on_menu_music_changed(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(v/100.0))
func _on_game_music_changed(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), linear_to_db(v/100.0))

func _on_pause_options_pressed(): pause_menu_container.hide(); pause_audio_container.show()
func _on_pause_back_pressed(): pause_audio_container.hide(); pause_menu_container.show()

# --- FINALIZACIÓN DE JUEGO ---
func _on_player_died():
	if game_over_panel: game_over_panel.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_game_won():
	if victory_panel: victory_panel.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_save_game_pressed():
	if player_reference: player_reference.save_game()

func _on_gameover_new_game():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func _on_gameover_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
func update_lives_label(amount):
	if lives_label:
		lives_label.text = "♥ x %s" % amount

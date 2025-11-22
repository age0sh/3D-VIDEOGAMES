extends Node3D # O el tipo que sea tu nodo raíz del Mundo

# (Asegúrate de que estas rutas sean correctas)
@onready var hud = $HUD
@onready var player = $Jugador # (O la ruta a tu jugador instanciado)

func _ready():
	# --- ¡AQUÍ ESTÁ LA LÓGICA QUE TE FALTA! ---
	
	# 1. ¿El "cerebro" (GameManager) nos dijo que cargáramos?
	if GameManager.load_requested:
		
		# 2. Si es así, le decimos al jugador que cargue sus datos
		player.load_game()
		
		# 3. Reseteamos la bandera para la próxima vez
		GameManager.load_requested = false
	
	# --- FIN DE LA LÓGICA DE CARGA ---

	# Esto se ejecuta SIEMPRE, ya sea una partida nueva o cargada.
	# El HUD se conectará y pedirá los valores (que serán los
	# guardados si cargamos, o los por defecto si no).
	hud.connect_to_player(player)

# (Opcional) ¡Mantén tu tecla de guardado rápido aquí!
func _input(_event): # Le ponemos un guion bajo para ignorar el 'event'
	
	# Le preguntamos al 'Input' global, no al 'event'
	if Input.is_action_just_pressed("ui_page_up"): # (Ej: Re Pág)
		player.save_game()

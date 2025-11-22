extends CharacterBody3D

# --- Señales para el HUD --- ### HUD ###
signal health_updated(current_health, max_health)
signal stamina_updated(current_stamina, max_stamina)
signal coins_updated(new_amount)
signal player_died # <-- ¡¡ASEGÚRATE DE AÑADIR ESTA LÍNEA!!
signal game_won
signal fog_warning_changed(visible, duration)
signal fog_timer_updated(time_left)
signal lives_updated(new_amount) # <-- ¡NUEVA!
# -----------------------------

@export var speed = 4.0
@export var sprint_speed_increase = 2.0
@export var crouch_speed = 2.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

# --- Stats del Jugador --- ### HUD ###
@export var max_health: float = 100.0
var current_health: float
@export var max_stamina: float = 100.0
var current_stamina: float
@export var stamina_regen_rate: float = 15.0 # Puntos por segundo
@export var stamina_drain_rate: float = 20.0 # Puntos por segundo
var current_coins: int = 0
# -----------------------------
@onready var footstep_audio = $FootstepAudio
# --- Variables para agacharse ---
@export var crouch_height_scale = 0.6
@export var crouch_transition_speed = 10.0

# --- Variables de Zoom ---
@export var zoom_speed = 0.5
@export var min_zoom = 1.0
@export var max_zoom = 3.0

# --- CONEXIONES ---
@onready var spring_arm = $SpringArm3D
@onready var collision_shape = $CollisionShape3D
@export var anim_player: AnimationPlayer
@onready var raycast = $RayCast3D
# -------------------

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_moving = false
var is_crouching = false

# --- Variables para guardar estado original de la colisión ---
var default_shape_height = 0.0
var default_shape_pos_y = 0.0
var crouch_shape_height = 0.0
var crouch_shape_pos_y = 0.0
# ----------------------------------------------------------------

# --- FUNCIÓN SEGURA DE ANIMACIÓN ---
func play_animation_safe(name: String) -> void:
	if anim_player and anim_player.has_animation(name):
		if anim_player.current_animation != name:
			anim_player.play(name)

# --- INICIO ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Guardamos los valores por defecto al empezar
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		default_shape_height = collision_shape.shape.height
		default_shape_pos_y = collision_shape.position.y
		
		# Pre-calculamos los valores de agachado
		crouch_shape_height = default_shape_height * crouch_height_scale
		crouch_shape_pos_y = default_shape_pos_y - (default_shape_height - crouch_shape_height) / 2.0
	else:
		print("¡Error! No se encontró un nodo 'CollisionShape3D' o no es una CapsuleShape3D.")

	if spring_arm:
		spring_arm.add_excluded_object(self.get_rid())

	# --- Inicializar Stats --- ### HUD ###
	current_health = max_health
	current_stamina = max_stamina
	# Emitimos las señales al inicio para que el HUD sepa los valores
	health_updated.emit(current_health, max_health)
	stamina_updated.emit(current_stamina, max_stamina)
	# -------------------------


# --- CONTROL DE INPUTS (RATÓN/TECLADO) ---
func _unhandled_input(event):
	# --- MOVIMIENTO DEL RATÓN (Cámara) ---
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# --- ZOOM CON RUEDA DEL RATÓN ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_speed, min_zoom, max_zoom)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_speed, min_zoom, max_zoom)

# --- BUCLE DE FÍSICAS (CADA FRAME) ---
func _physics_process(delta):
	# --- GRAVEDAD Y SALTO ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# --- LÓGICA DE INTERACCIÓN ---
	if Input.is_action_just_pressed("interact"):
		if raycast and raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider.is_in_group("interactable"):
				collider.interact()

	# --- INPUT DE MOVIMIENTO (Teclas) ---
	var input_dir = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	var direction = (transform.basis.z * input_dir.y + transform.basis.x * input_dir.x).normalized()
	is_moving = direction.length() > 0.1

	# --- LÓGICA DE ESTADO (Agacharse, Correr, Velocidad) ---
	var is_sprinting_input = Input.is_action_pressed("sprint") and is_moving and not is_crouching # Tu lógica original
	var is_sprinting = false # Esta es la variable final que usaremos
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()

	# --- LÓGICA DE STAMINA (ENERGÍA) --- ### HUD ###
	if is_sprinting_input:
		if current_stamina > 0:
			# Sí podemos correr
			is_sprinting = true
			use_stamina(stamina_drain_rate * delta)
		else:
			# Queremos correr, pero no hay energía
			is_sprinting = false
	else:
		# No estamos intentando correr, regeneramos
		is_sprinting = false
		if current_stamina < max_stamina:
			current_stamina += stamina_regen_rate * delta
			current_stamina = min(current_stamina, max_stamina) # Evita pasarse de 100
			stamina_updated.emit(current_stamina, max_stamina) # ¡Avisa al HUD!
	# --------------------------------------------------

	# Asignamos la velocidad según la prioridad
	var current_speed = 0.0
	if is_crouching:
		current_speed = crouch_speed
	elif is_sprinting: # <-- Esta variable ahora depende de la stamina
		current_speed = speed + sprint_speed_increase
	elif is_moving:
		current_speed = speed
	else:
		current_speed = speed # (Para el 'move_toward' de abajo)

	# --- LÓGICA DE MOVIMIENTO ---
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# --- LÓGICA DE COLISIÓN AL AGACHARSE ---
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var target_height = crouch_shape_height if is_crouching else default_shape_height
		var target_pos_y = crouch_shape_pos_y if is_crouching else default_shape_pos_y
		
		collision_shape.shape.height = lerp(collision_shape.shape.height, target_height, delta * crouch_transition_speed)
		collision_shape.position.y = lerp(collision_shape.position.y, target_pos_y, delta * crouch_transition_speed)

	# --- LÓGICA DE ANIMACIÓN ---
	if anim_player:
		if is_on_floor():
			if is_crouching:
				if is_moving:
					play_animation_safe("crouch_idle") # (Quizás "crouch_walk"?)
				else:
					play_animation_safe("crouch_idle")
			elif is_sprinting:
				play_animation_safe("run")
			elif is_moving:
				play_animation_safe("walk")
			else:
				play_animation_safe("idle")
		else:
			if velocity.y > 0.1: # Subiendo
				play_animation_safe("walk") # (o "jump")
			elif velocity.y < -0.1: # Bajando
				play_animation_safe("walk") # (o "fall")

	# --- APLICAR MOVIMIENTO ---
	move_and_slide()

# ---------------------------------------------------
# --- FUNCIONES DE STATS (VIDA Y ENERGÍA) --- ### HUD ###
# ---------------------------------------------------

func take_damage(amount: float):
	current_health -= amount
	current_health = max(current_health, 0)
	health_updated.emit(current_health, max_health)

	if current_health == 0:
		# --- LÓGICA DE VIDAS ---
		
		# 1. Restamos una vida en el cerebro global
		GameManager.player_lives -= 1
		
		# 2. Avisamos al HUD para que actualice el texto
		lives_updated.emit(GameManager.player_lives)
		
		print("¡Muerte! Vidas restantes: ", GameManager.player_lives)

		if GameManager.player_lives > 0:
			# --- CASO: AÚN QUEDAN VIDAS ---
			print("Reiniciando zona...")
			
			# Opcional: Guardar inventario/monedas antes de reiniciar
			# (Si quieres que conserve las monedas al morir)
			# current_coins se perderá si no lo guardas en GameManager también.
			
			# Recargamos la escena (El jugador revive, los enemigos reviven)
			get_tree().reload_current_scene()
			
		else:
			# --- CASO: GAME OVER REAL (0 VIDAS) ---
			print("¡Game Over definitivo!")
			player_died.emit() # Muestra la pantalla de Game Over
			set_physics_process(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
# Función limpia para gastar energía
func use_stamina(amount:float):
	current_stamina -= amount
	current_stamina = max(current_stamina, 0)
	
	# ¡Avisa al HUD!
	stamina_updated.emit(current_stamina, max_stamina)

func add_coins(amount: int):
	current_coins += amount
	coins_updated.emit(current_coins)
	print("¡Moneda recogida! Total: ", current_coins)

	# --- ¡AQUÍ ESTÁ LA LÓGICA DE VICTORIA! ---
	if current_coins >= 10:
		game_won.emit()
		# Apagamos al jugador y mostramos el mouse
		set_physics_process(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func save_game():
	var save_data = {
		"posicion": global_position,
		"vida": current_health,
		"energia": current_stamina,
		"monedas": current_coins,
		"vidas_restantes": GameManager.player_lives # <-- ¡AQUÍ GUARDAMOS LAS VIDAS!
	}
	GameManager.save_game_data(save_data)
	print("Partida guardada (incluyendo vidas).")

func load_game():
	# 1. Le pedimos los datos al cerebro
	var data = GameManager.load_game_data()
	
	if data.is_empty():
		print("No se encontraron datos de guardado.")
		return
		
	# 2. Aplicamos los datos cargados al JUGADOR
	global_position = data["posicion"]
	current_health = data["vida"]
	current_stamina = data["energia"]
	current_coins = data["monedas"]
	
	# 3. Aplicamos los datos cargados al GAMEMANAGER (Las vidas)
	# Usamos .get() por seguridad: si el archivo es viejo y no tiene "vidas_restantes", usa 3.
	GameManager.player_lives = data.get("vidas_restantes", 3) 
	
	# 4. ¡IMPORTANTE! Avisamos al HUD de los nuevos valores cargados
	health_updated.emit(current_health, max_health)
	stamina_updated.emit(current_stamina, max_stamina)
	coins_updated.emit(current_coins)
	lives_updated.emit(GameManager.player_lives) # <-- ¡Actualizamos el contador de corazones!
	
	print("Partida cargada correctamente.")

# La niebla llamará a esta función
func show_fog_warning(visible, duration):
	# Simplemente retransmite la señal al HUD
	fog_warning_changed.emit(visible, duration)

# La niebla llamará a esta función cada frame
func update_fog_timer(time_left):
	# Retransmite el tiempo restante al HUD
	fog_timer_updated.emit(time_left)
# --- FUNCIÓN PARA REPRODUCIR PASOS ---
# Esta función será llamada AUTOMÁTICAMENTE por la animación
func play_footstep():
	# Variación de tono (Pitch) aleatoria
	# Esto hace que no suene como una ametralladora robótica
	footstep_audio.pitch_scale = randf_range(0.8, 1.2)
	
	# Reproducir el sonido
	footstep_audio.play()

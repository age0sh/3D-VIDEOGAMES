extends CharacterBody3D

# --- Variables del Inspector (¡ARRASTRA TUS NODOS AQUÍ!) ---
# Estas ranuras aparecerán en el Inspector cuando selecciones a Piggy
@export var anim_player: AnimationPlayer
@export var nav_agent: NavigationAgent3D
@export var detection_area: Area3D
@export var attack_cooldown: Timer
@onready var footstep_audio = $FootstepAudio

# --- Configuración de Piggy ---
@export var move_speed: float = 2.5
@export var attack_distance: float = 1.8 # Qué tan cerca debe estar para atacar

# --- Variables Internas ---
var player = null # Para guardar al jugador
# Obtenemos el valor de la gravedad desde los ajustes del proyecto
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# ¡¡ASEGÚRATE DE ARRASTRAR LOS NODOS EN EL INSPECTOR!!
	# Si no, esto crasheará (error 'Nil' como el de antes)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Hacemos que la navegación evite a otros Piggys (si tienes varios)
	nav_agent.set_avoidance_enabled(true)


func _physics_process(delta):
	# --- 1. PROTECCIÓN INICIAL ---
	# Si yo (el enemigo) ya no estoy en el árbol, o el jugador no es válido...
	if not is_inside_tree() or (player != null and not is_instance_valid(player)):
		return # ...me detengo y no hago nada más.

	# --- 2. GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- 3. LÓGICA DE ESTADOS ---
	if player == null:
		# --- ESTADO: IDLE ---
		if anim_player.current_animation != "piggy_idle":
			anim_player.play("piggy_idle")
		velocity.x = 0
		velocity.z = 0
	
	else:
		# --- ESTADO: PERSECUCIÓN ---
		nav_agent.set_target_position(player.global_position)
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player > attack_distance:
			# --- SUB-ESTADO: MOVERSE ---
			if anim_player.current_animation != "piggy_walk":
				anim_player.play("piggy_walk")
			
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		
		else:
			# --- SUB-ESTADO: ATACAR ---
			velocity.x = 0
			velocity.z = 0
			
			if attack_cooldown.is_stopped():
				# Iniciar ataque
				anim_player.play("piggy_attack01")
				attack_cooldown.start()
				
				# Golpeamos al jugador
				if is_instance_valid(player):
					player.take_damage(20)
					
					# --- ¡PROTECCIÓN EXTRA! ---
					# Si el jugador se desconectó (se hizo null) justo al recibir el golpe...
					if player == null: 
						return # ...nos detenemos inmediatamente.
					
					# Si sigue existiendo, revisamos si murió
					if player.current_health <= 0:
						return
				
			else:
				# Esperando cooldown (Idle)
				var current_anim = anim_player.current_animation
				if current_anim != "piggy_attack01" and current_anim != "piggy_attack02":
					anim_player.play("piggy_idle")
	
	# --- 4. MOVIMIENTO ---
	# Si llegamos aquí, es seguro moverse
	move_and_slide()


# --- SEÑALES (Se llaman solas) ---

func _on_detection_area_body_entered(body):
	# Si lo que entró es el "player"...
	if body.is_in_group("player"):
		player = body # ¡Lo guardamos!

func _on_detection_area_body_exited(body):
	# Si el que salió fue el "player" que teníamos guardado...
	if body == player:
		player = null # ¡Lo olvidamos!

# --- FUNCIÓN PARA REPRODUCIR PASOS ---
# Esta función será llamada AUTOMÁTICAMENTE por la animación
func play_footstep():
	# Variación de tono (Pitch) aleatoria
	# Esto hace que no suene como una ametralladora robótica
	footstep_audio.pitch_scale = randf_range(0.8, 1.2)
	
	# Reproducir el sonido
	footstep_audio.play()

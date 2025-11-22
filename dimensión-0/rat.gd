extends CharacterBody3D

# --- Variables del Inspector (¡ARRASTRA TUS NODOS AQUÍ!) ---
@export var anim_player: AnimationPlayer
@export var nav_agent: NavigationAgent3D
@export var detection_area: Area3D
@export var attack_cooldown: Timer

# --- Configuración de la Rata ---
@export var move_speed: float = 4.0   # Las ratas son rápidas
@export var attack_distance: float = 1.5 # Tiene que acercarse más
@export var damage_amount: float = 5.0   # Un mordisco rápido
@onready var footstep_audio = $FootstepAudio
# --- Variables Internas ---
var player = null # Para guardar al jugador
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Nombres de Animaciones (¡Aquí está el cambio!) ---
const ANIM_IDLE = "rat_idle"
const ANIM_WALK = "rat_walk"
const ANIM_ATTACK = "rat_attack01"
# (Ignoramos rat_attack02, rat_guard, etc. por ahora)


func _ready():
	# ¡¡ASEGÚRATE DE ARRASTRAR LOS NODOS EN EL INSPECTOR!!
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Hacemos que la navegación evite a otros enemigos
	nav_agent.set_avoidance_enabled(true)


func _physics_process(delta):
	# --- ¡SEGURIDAD PRIMERO! ---
	if not is_inside_tree() or (player != null and not is_instance_valid(player)):
		return

	# --- 1. APLICAR GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- 2. LÓGICA DE ESTADOS ---
	if player == null:
		# --- ESTADO: IDLE ---
		if anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)
		velocity.x = 0
		velocity.z = 0
	
	else:
		# --- ESTADO: JUGADOR DETECTADO ---
		nav_agent.set_target_position(player.global_position)
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player > attack_distance:
			# --- SUB-ESTADO: CHASE (Perseguir) ---
			if anim_player.current_animation != ANIM_WALK:
				anim_player.play(ANIM_WALK)
				
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		
		else:
			# --- SUB-ESTADO: ATTACK (Atacar) ---
			velocity.x = 0
			velocity.z = 0
			
			if attack_cooldown.is_stopped():
				# ¡Atacamos!
				anim_player.play(ANIM_ATTACK) 
				attack_cooldown.start()
				
				# --- GOLPE Y PROTECCIÓN ---
				if is_instance_valid(player):
					player.take_damage(damage_amount)
					
					# 1. Si el jugador se desconectó (se hizo null) justo al recibir el golpe...
					if player == null: 
						return # ...nos detenemos inmediatamente.
					
					# 2. Si sigue existiendo, revisamos si murió
					if player.current_health <= 0:
						return 
				
			else:
				# --- Corrección para volver a Idle ---
				var current_anim = anim_player.current_animation
				# Revisa si hay otras animaciones de ataque que ignorar
				if current_anim != ANIM_ATTACK and current_anim != "rat_attack02":
					anim_player.play(ANIM_IDLE)
	
	# --- 3. MOVER EL PERSONAJE ---
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

extends CharacterBody3D

# Velocidad de avance (ajusta en el Inspector)
@export var move_speed: float = 8.0

# --- Conexiones a las llantas ---
# (¡Asegúrate de que estas rutas sean correctas!)
@onready var wheel_fr = $compact_classic2/wheel_FR
@onready var wheel_rl = $compact_classic2/wheel_RL
@onready var wheel_rr = $compact_classic2/wheel_RR
@onready var wheel_fl = $compact_classic2/wheel_FL

# Obtenemos la gravedad del proyecto
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	
	# --- 1. Aplicar Gravedad ---
	# Si no está en el suelo, aplica gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- 2. Movimiento ---
	# Solo avanza si está en el suelo
	if is_on_floor():
		# Establece la velocidad para ir "hacia adelante" (eje Z negativo)
		velocity.x = -global_transform.basis.z.x * move_speed
		velocity.z = -global_transform.basis.z.z * move_speed
	
	# Mueve el carro
	move_and_slide()
	

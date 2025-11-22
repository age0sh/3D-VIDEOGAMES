extends CharacterBody3D

# --- Variables de Escena Pre-cargadas ---

# Carga el "molde" de la bala que hicimos.
# Asegúrate de que la ruta "res://laser_bullet.tscn" sea correcta.
const BULLET_SCENE = preload("res://laser_bullet.tscn") 

# --- Variables del Inspector ---

# (Opcional) Velocidad si quieres que persiga al jugador
@export var move_speed: float = 0.0

# ¡¡LA MÁS IMPORTANTE!!
# Aquí debes arrastrar tu nodo "Pivot" desde la escena
@export var rotation_pivot: Node3D 

# --- Variables Internas (Nodos) ---

# El script espera encontrar hijos llamados "DetectionArea" y "ShootTimer"
@onready var detection_area: Area3D = $DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

# Referencia al "cañón" (el Marker3D que creamos)
# ¡Asegúrate de que la ruta "$Pivot/Muzzle" sea correcta!
@onready var muzzle: Marker3D = $Pivot/Muzzle

# Variable para guardar la referencia al jugador
var player = null 

# --- Funciones Base de Godot ---

# Se llama una vez cuando la escena se carga
func _ready():
	# Conectamos las señales de nuestros nodos a nuestras funciones
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

# Se llama en cada frame de física
func _physics_process(delta):
	# --- ¡SEGURIDAD PRIMERO! ---
	# Verificamos que el ojo y el jugador sigan existiendo antes de movernos o rotar
	if not is_inside_tree() or (player != null and not is_instance_valid(player)):
		return

	# Si no hay jugador detectado (o lo perdimos), no hacer nada.
	if player == null:
		return

	# --- LÓGICA DEL ENEMIGO (cuando SÍ ve al jugador) ---
	
	# 1. ROTACIÓN
	# Hacemos que el PIVOT (no el mesh) mire al jugador
	# La protección de arriba asegura que 'player' es válido aquí
	if rotation_pivot != null:
		rotation_pivot.look_at(player.global_position)
	else:
		print("¡ERROR! No has arrastrado el 'rotation_pivot' al Inspector.")

	# 2. MOVIMIENTO (Opcional)
	if move_speed > 0.0:
		var direction = (player.global_position - global_position).normalized()
		set_velocity(direction * move_speed)
		move_and_slide()
	
	# 3. DISPARO
	# Si el timer está detenido (listo para disparar), lo iniciamos.
	# La lógica real de crear la bala ocurre en la señal _on_shoot_timer_timeout
	if shoot_timer.is_stopped():
		shoot_timer.start()
# --- Funciones de Señal (Se llaman solas) ---

# Se llama cuando algo ENTRA en el Area3D (nuestro sensor)
func _on_detection_area_body_entered(body):
	# Si lo que entró está en el grupo "player"...
	if body.is_in_group("player"):
		print("Jugador detectado!")
		player = body # Lo guardamos

# Se llama cuando algo SALE del Area3D (nuestro sensor)
func _on_detection_area_body_exited(body):
	# Si lo que salió fue el jugador que teníamos guardado...
	if body == player:
		print("Jugador perdido.")
		player = null # Lo borramos (lo olvidamos)

# Se llama cuando el Timer "ShootTimer" llega a 0
func _on_shoot_timer_timeout():
	# Solo dispara si el jugador SIGUE estando a la vista
	if player != null:
		
		# 1. Crea una bala nueva usando el "molde"
		var bullet = BULLET_SCENE.instantiate()

		# 2. Añade la bala a la escena principal (al "mundo")
		get_tree().root.add_child(bullet)

		# 3. Mueve la bala a la posición y rotación exactas del "cañón" (Muzzle)
		#    Esto asegura que salga disparada en la dirección correcta.
		if muzzle != null:
			bullet.global_transform = muzzle.global_transform
		else:
			print("¡ERROR! No se encuentra el nodo 'Muzzle' en $Pivot/Muzzle")
			# Si no hay Muzzle, la bala saldrá del centro del ojo
			bullet.global_position = global_position

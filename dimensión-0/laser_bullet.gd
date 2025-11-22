extends Area3D

# Velocidad de la bala
@export var speed: float = 20.0

func _ready():
	# Conectar las señales
	# 1. Cuando la bala GOLPEA algo
	body_entered.connect(_on_body_entered)
	
	# 2. Cuando el timer de "vida" se acaba
	$LifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)

func _physics_process(delta):
	# Mover la bala "hacia adelante" (-Z es adelante en Godot)
	# Usamos global_position para que no le afecte si es "hija" de algo
	global_position += -global_transform.basis.z * speed * delta

# Se llama solo cuando la bala choca con un PhysicsBody
# Se llama solo cuando la bala choca con un PhysicsBody
func _on_body_entered(body):
	# Si choca con el jugador...
	if body.is_in_group("player"):
		
		# --- ¡AQUÍ ESTÁ EL DAÑO! ---
		# "body" es el nodo del jugador que entró en el área.
		# Así que llamamos a su función 'take_damage'.
		body.take_damage(10) # <-- ¡Le hacemos 10 de daño!
		
	# Destruir la bala (sea lo que sea con lo que choque)
	# (Esto evita que la bala atraviese y golpee 5 veces)
	queue_free()

# Se llama solo cuando el Timer "Lifetime" llega a 0
func _on_lifetime_timer_timeout():
	# Destruir la bala si no golpeó nada
	queue_free()

extends SpotLight3D

# --- Variables de Parpadeo ---
# Puedes ajustar estos valores en el Inspector

# Qué tan rápido parpadea (valores más bajos = más rápido)
@export var flicker_speed: float = 0.1 

# Energía mínima (cuando casi se apaga)
@export var min_energy: float = 0.5

# Energía máxima (brillo normal)
@export var max_energy: float = 5

# ------------------------------

# Un temporizador interno
var time_until_flicker: float = 0.0

func _ready():
	# Asegurarnos de que el valor inicial sea el máximo
	light_energy = max_energy
	time_until_flicker = flicker_speed

func _process(delta):
	# Restamos el tiempo que pasó
	time_until_flicker -= delta

	# Si el temporizador llega a cero...
	if time_until_flicker <= 0.0:
		
		# 1. Asignamos una nueva energía aleatoria
		light_energy = randf_range(min_energy, max_energy)
		
		# 2. Reiniciamos el temporizador
		# (Le añadimos un poco de aleatoriedad para que no sea un parpadeo rítmico)
		time_until_flicker = flicker_speed * randf_range(0.5, 1.5)

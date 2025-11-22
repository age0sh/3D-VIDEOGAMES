extends Area3D

# Variable para guardar al jugador mientras está dentro
var player_node = null
var time_in_fog = 0.0

func _ready():
	# Asegúrate de que el temporizador esté listo
	$Timer.wait_time = 5.0
	$Timer.one_shot = true
	
	# Mantenemos el _process apagado hasta que sea necesario
	set_process(false)

# Se llama cuando un cuerpo (como el jugador) ENTRA
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("El jugador ha entrado en la niebla. Iniciando contador...")
		player_node = body
		
		# Inicia el temporizador lógico de 10 segundos
		$Timer.start() 
		
		# Prepara el temporizador VISUAL
		time_in_fog = $Timer.wait_time
		
		# Llama a la nueva función del jugador para MOSTRAR el HUD
		player_node.show_fog_warning(true, time_in_fog)
		
		# Activa el _process para el contador visual
		set_process(true)

# Se llama cada frame MIENTRAS set_process(true)
func _process(delta):
	# Actualiza el timer visual
	time_in_fog -= delta
	
	# Si el jugador sigue ahí, le envía el tiempo restante
	if player_node:
		player_node.update_fog_timer(time_in_fog)

# Se llama cuando un cuerpo (como el jugador) SALE
func _on_body_exited(body):
	if body == player_node:
		print("El jugador salió a salvo. Deteniendo contador.")
		
		# Detiene el temporizador lógico de 10 segundos
		$Timer.stop() 
		
		# Llama a la nueva función del jugador para OCULTAR el HUD
		player_node.show_fog_warning(false, 0)
		
		# Apaga el _process
		set_process(false)
		
		# Olvidamos al jugador
		player_node = null 

# Se llama SOLO SI el temporizador de 10 segundos TERMINA
func _on_timer_timeout():
	# Si el jugador todavía está en la zona cuando el tiempo se acaba
	if player_node != null:
		print("¡Se acabó el tiempo! El jugador muere.")
		
		# ¡Mátalo usando la función que ya teníamos!
		# Le pasamos su vida actual + 1 (para asegurar que muera)
		player_node.take_damage(player_node.current_health + 1)
		
		# Apagamos el _process y ocultamos el warning
		set_process(false)
		player_node.show_fog_warning(false, 0)
		
		player_node = null

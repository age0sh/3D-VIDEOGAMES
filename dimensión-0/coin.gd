extends Area3D

# Esta función se llama cuando un "cuerpo" entra en el área
func _on_body_entered(body):
	# Revisamos si el cuerpo que entró está en el grupo "player"
	if body.is_in_group("player"):

		# Le decimos a ese cuerpo (el jugador) que sume 1 moneda
		body.add_coins(1) 

		# Destruimos la moneda
		queue_free()
		

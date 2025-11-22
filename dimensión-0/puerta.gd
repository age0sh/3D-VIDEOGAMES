extends Node3D

# Esta función se llama cuando algo ENTRA al Area3D
func _on_area_3d_body_entered(body):
	# Primero, revisamos si lo que entró es el jugador.
	# (Para que esto funcione, tu Jugador debe estar en un grupo "player")
	if body.is_in_group("player"):
		# Toca la animación "abrir"
		$AnimationPlayer.play("abrir")


# Esta función se llama cuando algo SALE del Area3D
func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		# Toca la animación "cerrar"
		$AnimationPlayer.play("cerrar")

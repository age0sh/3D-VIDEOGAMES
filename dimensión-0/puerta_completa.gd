# puerta_completa.gd
extends Node3D

@onready var anim_player = $AnimationPlayer # Asegúrate de que el nombre del nodo coincida
var abierta = false

# Esta función será llamada por el JUGADOR
func interact():
	# No hacer nada si la puerta ya se está moviendo
	if anim_player.is_playing():
		return

	if abierta:
		anim_player.play("cerrar")
	else:
		anim_player.play("abrir")
	
	# Invertimos el estado
	abierta = not abierta

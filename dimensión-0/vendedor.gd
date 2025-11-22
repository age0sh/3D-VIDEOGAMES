# Vendedor.gd
extends Area3D

# --- Variables ---
# Referencias a nuestros nodos
@onready var prompt_label = $Label3D
@onready var dialogo_panel = $CanvasLayer/PanelContainer
@onready var dialogo_texto = $CanvasLayer/PanelContainer/RichTextLabel

# El texto que dirá este NPC
@export var mi_dialogo = "¡Hola, forastero! ¿Qué te trae por aquí?"

# --- Control de Estado ---
var jugador_esta_cerca = false
var dialogo_esta_activo = false

func _ready():
	# Conectamos las señales del Area3D a nuestro script
	# body_entered se dispara cuando un cuerpo entra
	# body_exited se dispara cuando un cuerpo sale
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Nos aseguramos de que todo esté oculto al empezar
	prompt_label.visible = false
	dialogo_panel.visible = false


# Esta función se llama sola cuando un cuerpo entra al Area3D
func _on_body_entered(body):
	# Comprobamos si el cuerpo que entró está en el grupo "Player"
	if body.is_in_group("Player"):
		jugador_esta_cerca = true
		prompt_label.visible = true # Mostramos "Presiona E"


# Esta función se llama sola cuando un cuerpo sale del Area3D
func _on_body_exited(body):
	if body.is_in_group("Player"):
		jugador_esta_cerca = false
		prompt_label.visible = false # Ocultamos "Presiona E"
		
		# Si el jugador se va, también cerramos el diálogo
		dialogo_esta_activo = false
		dialogo_panel.visible = false




func iniciar_dialogo():
	dialogo_esta_activo = true
	prompt_label.visible = false # Ocultamos "Presiona E"
	
	# Mostramos el diálogo
	dialogo_texto.text = mi_dialogo
	dialogo_panel.visible = true


# Esta es la nueva función _input que maneja todo
func _input(event):
	# Primero, nos aseguramos de que sea la acción "interact"
	if Input.is_action_just_pressed("interact"):
		
		# CASO 1: El diálogo está activo. Lo cerramos.
		if dialogo_esta_activo:
			cerrar_dialogo()
			
		# CASO 2: El diálogo NO está activo, PERO el jugador está cerca. Lo abrimos.
		elif jugador_esta_cerca:
			iniciar_dialogo()
func cerrar_dialogo():
	dialogo_esta_activo = false
	dialogo_panel.visible = false
	
	# Si el jugador sigue cerca, volvemos a mostrar el prompt
	if jugador_esta_cerca:
		prompt_label.visible = true

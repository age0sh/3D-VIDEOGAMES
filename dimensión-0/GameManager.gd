extends Node
# Este script vivirá globalmente como un "Autoload".
var load_requested: bool = false
const SAVE_PATH = "user://save.dat"

var player_lives: int = 3 # Empezamos con 3
func reset_lives():
	player_lives = 3
	
# El jugador llama a esto para guardar
func save_game_data(data: Dictionary):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	print("¡Partida guardada!")

# El mundo/jugador llama a esto para cargar
func load_game_data() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_var()
		file.close()
		return data
	return {}

# El menú principal usa esto
func does_save_file_exist() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

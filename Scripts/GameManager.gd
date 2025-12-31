# ==============================================================================
# Název: GameManager.gd
# Popis: Globální správce stavu hry (Singleton), který zajišťuje přepínání 
#        mezi scénami (menu, hlavní hra) a zpracovává základní vstupy pro 
#        ukončení nebo návrat do hlavní nabídky.
# Autor: Lubomír Tomandl - Angry Developer Studio
# Verze: 1.0
# ==============================================================================

extends Node

# Cesty ke scénám (upravte podle své struktury)
const MAIN_MENU_PATH = "res://scenes/MainMenu.tscn"
const MAIN_SCENE_PATH = "res://scenes/MainScene.tscn"

# Voláno při prvním vstupu uzlu do stromu scén
func _ready():
	# Volitelné: Načtení uložené pozice při startu aplikace
	# load_game() 
	pass

# Voláno v každém snímku hry. '_delta' je uplynulý čas od předchozího snímku
func _process(_delta):
	# Pokud hráč stiskne Escape a není v menu, vrátíme se do menu
	if Input.is_action_just_pressed("ui_cancel"): 
		var current_scene = get_tree().current_scene.scene_file_path
		if current_scene != MAIN_MENU_PATH:
			go_to_menu()

# --- FUNKCE PRO OVLÁDÁNÍ HRY ---

# Přepne hru do hlavní herní scény
func start_game():
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

# Přepne hru do hlavního menu
func go_to_menu():
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

# Ukončí aplikaci
func quit_game():
	get_tree().quit()

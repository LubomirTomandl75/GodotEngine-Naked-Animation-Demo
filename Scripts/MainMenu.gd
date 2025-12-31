# ==============================================================================
# Název: MainMenu.gd
# Popis: Skript pro obsluhu hlavního menu hry. Zajišťuje reakce na stisk tlačítek
#        pro spuštění nové hry a ukončení aplikace pomocí GameManageru.
# Autor: Lubomír Tomandl - Angry Developer Studio
# Verze: 1.0
# ==============================================================================

extends Control

# Voláno při prvním vstupu uzlu do stromu scén
func _ready():
	# Nastaví režim myši na viditelný, pokud byl v předchozí scéně skrytý
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Propojte signál 'pressed' z ButtonStart
func _on_button_start_pressed():
	GameManager.start_game()

# Propojte signál 'pressed' z ButtonQuit
func _on_button_quit_pressed():
	GameManager.quit_game()

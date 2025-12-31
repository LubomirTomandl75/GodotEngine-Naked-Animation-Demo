# ==============================================================================
# Název: PlayerController.gd
# Popis: Ovládání 3D postavy z pohledu třetí osoby. Zahrnuje pohyb, rotaci
#        kamery, myší, gamepadem, interpolaci pohybu a propojení s AnimationTree.
# Autor: Lubomír Tomandl - Angry Developer Studio
# Verze: 1.0
# ==============================================================================

extends CharacterBody3D

# --- Onready proměnné (Reference na uzly ve scéně) ---
@onready var fps_label = $"../CanvasLayer/FPSLabel"      # Label pro zobrazení FPS
@onready var armature = $FergusonovaNaked                # Model postavy (pro rotaci ve směru pohybu)
@onready var spring_arm_pivot = $SpringArmPivot          # Pivot pro horizontální rotaci kamery (Y)
@onready var spring_arm = $SpringArmPivot/SpringArm3D    # Rameno kamery pro vertikální rotaci (X)
@onready var anim_tree = $FergusonovaNaked/AnimationTree # Správce animací

# --- Konstanty ---
const SPEED = 5.0            # Maximální rychlost pohybu
const LERP_VAL = 0.15        # Koeficient vyhlazení (pohyb, rotace, zastavování)
const JOY_SENSITIVITY = 2.0  # Citlivost páčky gamepadu
const JOY_DEADZONE = 0.2     # Mrtvá zóna páček (filtrace nechtěného pohybu/driftu)

## Inicializace při spuštění
func _ready() -> void:
	# Skryje a uzamkne kurzor myši v okně hry
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Volá se každý vykreslený snímek
func _process(_delta: float) -> void:
	# Aktualizace textu FPS
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

## Zpracování jednorázových vstupů (myš, klávesy)
func _unhandled_input(event: InputEvent) -> void:
	# Rotace kamery pomocí pohybu myši
	if event is InputEventMouseMotion:
		# Horizontální rotace celého pivotu
		spring_arm_pivot.rotate_y(-event.relative.x * .005)
		# Vertikální rotace samotného ramene (nahoru/dolů)
		spring_arm.rotate_x(-event.relative.y * .005)
		# Omezení (clamp) rotace kamery, aby se nepřetočila "vzhůru nohama"
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

## Fyzikální smyčka (pohyb a výpočty)
func _physics_process(delta: float) -> void:
	
	# Rotace kamery pomocí pravé páčky gamepadu s aplikací mrtvé zóny
	var look_dir := Input.get_vector("look_left", "look_right", "look_up", "look_down", JOY_DEADZONE)
	if look_dir.length() > 0:
		# Horizontální rotace pivotu podle vstupu páčky
		spring_arm_pivot.rotate_y(-look_dir.x * JOY_SENSITIVITY * delta)
		# Vertikální rotace ramene podle vstupu páčky
		spring_arm.rotate_x(-look_dir.y * JOY_SENSITIVITY * delta)
		# Omezení vertikálního rozsahu kamery
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
	
	# Aplikace gravitace, pokud postava nestojí na zemi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Získání směru pohybu z kláves nebo levé páčky (včetně mrtvé zóny)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up", JOY_DEADZONE)
	
	# Výpočet směru pohybu relativně k natočení kamery (pivotu)
	var direction := (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	if direction:
		# Plynulý rozjezd na cílovou rychlost
		velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_VAL)
		velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_VAL)
		
		# Otáčení modelu postavy směrem, kterým se pohybuje
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	else:
		# Plynulé zastavení (tření/setrvačnost)
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)

	# Nastavení animace (předpokládá BlendSpace1D: 0.0 = Idle, 1.0 = Run)
	anim_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED)

	# Provedení pohybu s detekcí kolizí
	move_and_slide()

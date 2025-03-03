@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPlayer.svg")
extends CharacterBody3D
class_name CogitoSDPC


#region Signals
## Emits when ESC/Menu input map action is pressed. Can be used to exit out other interfaces, etc.
signal menu_pressed(player_interaction_component: PlayerInteractionComponent)
signal toggle_inventory_interface()
signal player_state_loaded()

## Used to hide UI elements like the crosshair when another interface is active (like a container or readable)
signal toggled_interface(is_showing_ui:bool)
signal mouse_movement(relative_mouse_movement:Vector2)

#endregion

#region Components
## Reference to the Pause menu Node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath
## Ref to the State Machine
@export var state_machine: SDPCStateMachine
#endregion


#region Movement
@export_group("Movement (Basic)")
@export_subgroup("Grounded")
@export_subgroup("Movement")

@export_group("Movement (Advanced)")
@export_subgroup("Headbob")
@export_subgroup("Stairs")
@export_subgroup("Ladders")
#endregion


#region Audio
@export_group("Audio")
## AudioStream that gets played when the player jumps.
@export var jump_sound : AudioStream
## AudioStream that gets played when the player slides (sprint + crouch).
@export var slide_sound : AudioStream

@export_subgroup ("Footstep Audio")
@export var walk_volume_db : float = -38.0
@export var sprint_volume_db : float = -30.0
@export var crouch_volume_db : float = -60.0
## the time between footstep sounds when walking
@export var walk_footstep_interval : float = 0.6
## the time between footstep sounds when sprinting
@export var sprint_footstep_interval : float = 0.3
## the speed at which the player must be moving before the footsteps change from walk to sprint.
@export var footstep_interval_change_velocity : float = 5.2

@export_subgroup ("Landing Audio")
## Threshold for triggering landing sound
@export var landing_threshold = -2.0
## Defines Maximum velocity (in negative) for the hardest landing sound
@export var max_landing_velocity = -8
## Defines Minimum velocity (in negative) for the softest landing sound
@export var min_landing_velocity = -2
## Max volume in dB for the landing sound
@export var max_volume_db = 0
## Min volume in dB for the landing sound
@export var min_volume_db = -40
## Highest pitch for lightest landing sound
@export var max_pitch = 0.8
## Lowest pitch for hardest landing sound
@export var min_pitch = 0.7
#Setup Dynamic Pitch & Volume for Landing Audio, used to store velocity based results
var LandingPitch: float = 1.0
var LandingVolume: float = 0.8
var slide_audio_player: AudioStreamPlayer3D
#endregion


#region Debug
@export_group("Debug")
## Toggle printing debug messages or not. Works with the CogitoSceneManager
@export var is_logging: bool = false
@export var use_local_rng: bool = true

#endregion





#### @onready ####

#region Node Cache
# Components
@onready var player_interaction_component: PlayerInteractionComponent = $PlayerInteractionComponent
@onready var wieldables := %Wieldables


# Body/Animations
@onready var body: Node3D = $Body
@onready var neck: Node3D = $Body/Neck
@onready var head: Node3D = $Body/Neck/Head
@onready var eyes: Node3D = $Body/Neck/Head/Eyes
@onready var camera: Camera3D = $Body/Neck/Head/Eyes/Camera
@onready var animationPlayer: AnimationPlayer = $Body/Neck/Head/Eyes/AnimationPlayer

# Collision Checking
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var crouch_raycast: RayCast3D = $CrouchRayCast

# Timers
@onready var sliding_timer: Timer = $SlidingTimer
@onready var jump_timer: Timer = $JumpCooldownTimer

# Dynamic Footstep
@onready var footstep_player = $FootstepPlayer
@onready var footstep_surface_detector : FootstepSurfaceDetector = $FootstepPlayer
@onready var footstep_interval_change_velocity_square : float = footstep_interval_change_velocity * footstep_interval_change_velocity


# Sitting
@onready var navigation_agent = $NavigationAgent3D #Navigation agent for Player auto seat exit handling

# Debug
# Cache allocation of test motion parameters.
@onready var _params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
@onready var self_rid: RID = self.get_rid()
@onready var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()

#endregion




#### Systems ####

#region Attribute System
var player_currencies: Dictionary

var player_attributes: Dictionary
var stamina_attribute: CogitoAttribute = null
var visibility_attribute: CogitoAttribute

#endregion

#### Player States ####
#region States
# Here lay all "states" the player can exist in
var is_showing_ui: bool
var is_jumping: bool = false
var is_in_air: bool = false
var is_walking: bool = false
var is_sprinting: bool = false
var is_couching: bool = false
var is_free_looking: bool = false
var is_movement_paused: bool = false
var is_dead: bool = false
#endregion




########################################################################################################################
########################################################################################################################

func _ready() -> void:
	CogitoSceneManager._current_player_node = self
	if use_local_rng:
		randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_attribute_system()
	setup_interaction_component()
	setup_currency_system()
	state_machine.initialize(self)
	subscribe_to_sittables()


func _process(delta: float) -> void:
	state_machine.process_frames(delta)

func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

func _input(event: InputEvent) -> void:
	state_machine.process_inputs(event)


#region Setup Functions
func setup_attribute_system() -> void:
	# Grabs all attached player attributes
	for attribute in find_children("","CogitoAttribute",false):
		player_attributes[attribute.attribute_name] = attribute
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Cogito Attribute found: " + attribute.attribute_name)

	# If found, hookup health attribute signal to detect player death
	var health_attribute = player_attributes.get("health")
	if health_attribute:
		health_attribute.death.connect(_on_death)
	# Save reference to stamina attribute for movements that require stamina checks (null if not found)
	stamina_attribute = player_attributes.get("stamina")
	# Save reference to visibilty attribute for that require visibility checks (null if not found)
	visibility_attribute = player_attributes.get("visibility")
	# Hookup sanity attribute to visibility attribute
	var sanity_attribute = player_attributes.get("sanity")
	if sanity_attribute and visibility_attribute:
		visibility_attribute.attribute_changed.connect(sanity_attribute.on_visibility_changed)
		visibility_attribute.check_current_visibility()


func setup_interaction_component() -> void:
	player_interaction_component.interaction_raycast = $Body/Neck/Head/Eyes/Camera/InteractionRaycast
	player_interaction_component.exclude_player(get_rid())


func setup_currency_system() -> void:
	### CURRENCY SETUP
	for currency in find_children("", "CogitoCurrency", false):
		player_currencies[currency.currency_name] = currency
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Cogito Currency found: " + currency.currency_name)


func setup_pause_menu() -> void:
	# Pause Menu setup
	if pause_menu:
		var pause_menu_node = get_node(pause_menu)
		pause_menu_node.resume.connect(_on_pause_menu_resume) # Hookup resume signal from Pause Menu
		pause_menu_node.close_pause_menu() # Making sure pause menu is closed on player scene load
	else:
		printerr("Player has no reference to pause menu.")

func subscribe_to_sittables() -> void:
	#Sittable Signals setup
	CogitoSceneManager.connect("sit_requested", Callable(self, "_on_sit_requested"))
	CogitoSceneManager.connect("stand_requested", Callable(self, "_on_stand_requested"))
	CogitoSceneManager.connect("seat_move_requested", Callable(self, "_on_seat_move_requested"))

	CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Player has no reference to pause menu.")

	call_deferred("slide_audio_init")


func slide_audio_init():
	#setup sound effect for sliding
	slide_audio_player = Audio.play_sound_3d(slide_sound, false)
	slide_audio_player.reparent(self, false)

#endregion


func _on_death():
	pass

func _on_pause_menu_resume():
	pass

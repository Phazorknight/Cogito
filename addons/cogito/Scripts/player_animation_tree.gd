extends AnimationTree

@onready var cogito_player_state_driven : CogitoPlayerStateDriven = get_parent()

@export var rig_node : Node3D
@export var process_animations : bool = true

enum MoveState{
	UPRIGHT, CROUCHING, AIRBORNE,
}
var current_move_state : MoveState = MoveState.UPRIGHT

enum ArmState{
	EMPTY, PISTOL,
}
var current_arm_state : ArmState = ArmState.EMPTY

var relative_velocity
# Relative velocity of player movement on the ground as a vector2, derived from the CharacterBody velocity vector 3.
var rel_velocity_xz : Vector2

func _physics_process(delta: float) -> void:
	rig_node.rotation = cogito_player_state_driven.body.rotation + Vector3(0,deg_to_rad(180),0)
	
	if process_animations:
		update_animations(delta)
	
	
func update_animations(_delta: float):

	match current_move_state:
		MoveState.UPRIGHT:
			relative_velocity = cogito_player_state_driven.global_basis.inverse() * ((cogito_player_state_driven.velocity * Vector3(1,0,1)) / cogito_player_state_driven.SPRINTING_SPEED)
			rel_velocity_xz = Vector2(relative_velocity.x, -relative_velocity.z)
			
			self.set("parameters/LowerBodyState/Upright/blend_position", rel_velocity_xz)
			
		MoveState.CROUCHING:
			relative_velocity = cogito_player_state_driven.global_basis.inverse() * ((cogito_player_state_driven.velocity * Vector3(1,0,1)) / cogito_player_state_driven.CROUCHING_SPEED)
			rel_velocity_xz = Vector2(relative_velocity.x, -relative_velocity.z)
	
			self.set("parameters/LowerBodyState/Crouched/blend_position", rel_velocity_xz)
			

func standing_up() -> void:
	if current_move_state != MoveState.UPRIGHT:
		current_move_state = MoveState.UPRIGHT
		
		var lower_body_state = self.get("parameters/LowerBodyState/playback")
		lower_body_state.travel("Upright")

func crouch_down() -> void:
	if current_move_state != MoveState.CROUCHING:
		current_move_state = MoveState.CROUCHING
		
		var lower_body_state = self.get("parameters/LowerBodyState/playback")
		lower_body_state.travel("Crouched")


func go_airborne() -> void:
	if current_move_state != MoveState.AIRBORNE:
		current_move_state = MoveState.AIRBORNE
		
		var lower_body_state = self.get("parameters/LowerBodyState/playback")
		lower_body_state.travel("Jump")

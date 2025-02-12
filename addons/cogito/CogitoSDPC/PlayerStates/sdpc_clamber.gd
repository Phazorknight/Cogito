class_name SDPCStateClamber
extends SDPCState

# The animation window in which the character is pulling themselves over the ledge

@export_group("State Connections")
@export var idle_state: SDPCStateIdle
@export var fall_state: SDPCStateFall
@export var crouch_state: SDPCStateCrouch

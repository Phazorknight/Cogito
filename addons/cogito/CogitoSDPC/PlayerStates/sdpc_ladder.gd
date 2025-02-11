class_name SDPCStateLadder
extends SDPCState

#NOTE: Ladder Climbing

@export var clamber_state: SDPCStateClamber # when climbing the apex of the ladder
@export var move_state: SDPCStateMove # when exiting the bottom of the ladder
@export var jump_state: SDPCStateJump # if jumping off ladder
@export var fall_state: SDPCStateFall # if knocked off ladder
@export var idle_state: SDPCStateIdle # when standing at the bottom of the ladder, may not be necessary

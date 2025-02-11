class_name SDPCStateBunnyHop
extends SDPCState

# NOTE: This one will take a bit of digging from me on how it works -Vrood

@export_group("State Connections")
@export var slide_state: SDPCStateSlide
@export var sprint_state: SDPCStateSprint
@export var move_state: SDPCStateMove
@export var fall_state: SDPCStateFall
@export var grab_state: SDPCStateGrab

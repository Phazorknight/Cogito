extends AudioStreamPlayer3D

@export var footsteps = []
@export var randomize_pitch : bool
@export_range(0.0,1.0) var pitch_variance : float

func play_sfx(index):
	stream = footsteps[index]
	if randomize_pitch:
		pitch_scale = 1 + randf_range(-pitch_variance, pitch_variance)
	play()

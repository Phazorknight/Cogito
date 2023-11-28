extends Resource
class_name AudioObjectPD

@export var name : String
@export var audio_file : AudioStream
@export_range(0.0,1.0) var volume : float = 1.0
@export var is_music : bool

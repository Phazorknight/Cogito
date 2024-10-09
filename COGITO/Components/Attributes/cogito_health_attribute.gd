extends CogitoAttribute
class_name CogitoHealthAttribute

## Emitted when health is reduced.
signal damage_taken()
## Emitted when health reaches zeor.
signal death()

## Amount of damage received per second if sanity is zero. Usually only used for Players.
@export var no_sanity_damage : float
## Sound that plays when taking damage, also played on death. Useful as Bullet impact sound
@export var sound_on_hit : AudioStream
## Sound that plays when taking damage, not played on death. Useful as Damage NPC reaction sound 
@export var sound_on_damage_taken : AudioStream
## Sound that plays on death.
@export var sound_on_death : AudioStream
## Nodepaths to nodes that get destroyed on death.
@export var destroy_on_death : Array[NodePath]
## Array of Scenes that will get spawned on parent position on death.
@export var spawn_on_death : Array[PackedScene] = []

var parent_position : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value_current = value_start
	attribute_reached_zero.connect(on_death)
	attribute_changed.connect(on_health_change)
	attribute_changed.emit(attribute_name,value_current,value_max,true)


func on_health_change(_health_name:String, _health_current:float, _health_max:float, has_increased:bool):
	if !has_increased:
		damage_taken.emit()
		if sound_on_hit:
			Audio.play_sound_3d(sound_on_hit).global_position = get_parent().global_position
		if sound_on_damage_taken and not _health_current <= 0:
			Audio.play_sound_3d(sound_on_damage_taken).global_position = get_parent().global_position


func on_death(_attribute_name:String, _value_current:float, _value_max:float):
	death.emit()
	parent_position = get_parent().global_position
	
	if sound_on_death:
		Audio.play_sound_3d(sound_on_death).position = parent_position
	
	for scene in spawn_on_death:
		if scene:
			var spawned_object = scene.instantiate()
			spawned_object.position = parent_position
			get_tree().current_scene.add_child(spawned_object)
	
	for nodepath in destroy_on_death:
		if get_node(nodepath):
			get_node(nodepath).queue_free()

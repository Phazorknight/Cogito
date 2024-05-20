extends Node3D
## This class handles systeminc properties. Needs to be attached to a CogitoObject to work properly. For proper processing, said Object needs to have a signal hooked up to call check_for_systemic_interactions(collider).
class_name CogitoProperties

signal has_ignited()
signal has_been_extinguished()
signal has_become_wet()
signal has_become_dry()
signal has_become_electrified()

enum ElementalProperties{
	CONDUCTIVE = 1,
	FLAMMABLE = 2,
	WET = 4,
}

enum MaterialProperties{
	SOFT = 1,
}

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

## Bitflag for elemental properties. Gets handled when a collision calls "check_for_systemic_interactions(collider)".
@export_flags("CONDUCTIVE", "FLAMABLE", "WET") var elemental_properties: int = 0
## Bitflag for material properites. Gets handled when a projectile or similar damage call applies. SOFT materials can get damaged by SOFT projectiles.
@export_flags("SOFT") var material_properties: int = 0

## Sets if the object should ignite itself on ready.
@export var ignite_on_ready : bool
## PackedScene of VFX etc that gets spawned when object ignites.
@export var spawn_on_ignite : PackedScene
## PackedScene of VFX etc that gets spawned when object gets wet.
@export var spawn_on_wet : PackedScene

@export_group("Audio")
@export var audio_igniting : AudioStream
@export var audio_burning : AudioStream
@export var audio_extinguishing : AudioStream


var spawned_effects : Array[Node] # Used to store and clear out spawned effects
var is_on_fire : bool = false
var is_electrified : bool = false


func _ready():
	if ignite_on_ready:
		set_on_fire()
		
	if elemental_properties == ElementalProperties.WET:
		make_wet()


func check_for_systemic_reactions(collider:Node3D):
	if( !collider.cogito_properties):
		# Case where the object has no properties defined.
		print("Collider ", collider.name, " has no properties.")
		return
		
	if( collider.cogito_properties):
		if collider.cogito_properties.is_on_fire:
			if elemental_properties & ElementalProperties.FLAMMABLE:
				print(get_parent().name, ": Touched burning collider ", collider.name, ". I'm flammable, igniting self.")
				set_on_fire()
			else:
				print(get_parent().name, ": Touched collider ", collider.name, " which is on fire, but I'm not flammable, so nothing happens.")
			if elemental_properties & ElementalProperties.WET:
				print(get_parent().name, ": Touched burning collider ", collider.name, ". I'm wet so I'll extinguish the collider.")
				collider.cogito_properties.extinguish()


		print("Collider ", collider.name, " elemental properties: ", collider.cogito_properties.elemental_properties)
		match collider.cogito_properties.elemental_properties:
			ElementalProperties.WET:
				if is_on_fire:
					print(get_parent().name, ": Touched by wet collider ", collider.name, " while on fire. Extinguishing self.")
					extinguish()
					make_wet()
				else:
					print(get_parent().name, ": Touched by wet collider ", collider.name, " but wasn't on fire. Getting wet.")
					make_wet()
			_:
				print(get_parent().name, ": No property match found for ", collider.name)



func make_conductive():
	elemental_properties = elemental_properties ^ ElementalProperties.CONDUCTIVE


func make_flammable():
	elemental_properties = elemental_properties ^ ElementalProperties.FLAMMABLE


func make_wet():
	if( elemental_properties & ElementalProperties.WET):
		pass
	else:
		elemental_properties = elemental_properties ^ ElementalProperties.WET
		
	if is_on_fire:
		extinguish()
	if spawn_on_wet:
		var spawned_object = spawn_on_wet.instantiate()
		get_parent().add_child.call_deferred(spawned_object)
		spawned_effects.append(spawned_object)
		spawned_object.position = Vector3(0,0,0)
	has_become_wet.emit()


func make_dry():
	elemental_properties = elemental_properties ^ ElementalProperties.WET
	clear_spawned_effects()
	has_become_dry.emit()


func set_on_fire():
	if( elemental_properties & ElementalProperties.FLAMMABLE):
		is_on_fire = true
		if spawn_on_ignite:
			var spawned_object = spawn_on_ignite.instantiate()
			get_parent().add_child.call_deferred(spawned_object)
			spawned_effects.append(spawned_object)
			spawned_object.position = Vector3(0,0,0)
			Audio.play_sound_3d(audio_igniting).position = self.position
		has_ignited.emit()
			
		audio_stream_player_3d.stream = audio_burning
		audio_stream_player_3d.play()
	else:
		print(get_parent().name, " is not FLAMMABLE.")
	

func extinguish():
	is_on_fire = false
	audio_stream_player_3d.stop()
	Audio.play_sound_3d(audio_extinguishing).position = self.position
	clear_spawned_effects()
	has_been_extinguished.emit()


func clear_spawned_effects():
	for node in spawned_effects:
		print("CogitoProperties: Clearing out spawned effect ", node)
		node.queue_free()
	spawned_effects.clear()


func electrify():
	match elemental_properties:
		ElementalProperties.CONDUCTIVE:
			is_electrified = true
			has_become_electrified.emit()
		_:
			print(name, " is not CONDUCTIVE.")

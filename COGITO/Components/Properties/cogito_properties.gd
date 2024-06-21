@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoProperties.svg")
extends Node3D
## This class handles systeminc properties. Needs to be attached to a CogitoObject to work properly. For proper processing, said Object needs to have a signal hooked up to call check_for_systemic_interactions(collider).
class_name CogitoProperties

signal has_ignited()
signal has_been_extinguished()
signal deal_burn_damage(burn_damage_amount:int)
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
@onready var damage_timer: Timer = $DamageTimer
@onready var reaction_timer: Timer = $ReactionTimer

## Bitflag for elemental properties. Gets handled when a collision calls "check_for_systemic_interactions(collider)".
@export_flags("CONDUCTIVE", "FLAMABLE", "WET") var elemental_properties: int = 0
## Bitflag for material properites. Gets handled when a projectile or similar damage call applies. SOFT materials can get damaged by SOFT projectiles.
@export_flags("SOFT") var material_properties: int = 0

## Time it takes for a property state change to happen. E.g. an object only ignites if exposed to fire for at least 1 second.
@export var reaction_threshold_time : float = 1.0


@export_group("Burn Parameters")
## Sets if the object should ignite itself on ready. Needs to be flammable for this to work.
@export var ignite_on_ready : bool
## Amount of damage dealt to the health component while object is on fire.
@export var burn_damage_amount : int
## Interval the burn damage is applied in seconds.
@export var burn_damage_interval : float = 1.0


@export_group("Electrified Parameters")
## Sets if the object should become electrified on ready. Needs to be conductive for this to work.
@export var electrify_on_ready : bool


@export_group("VFX PackedScenes")
## PackedScene of VFX etc that gets spawned when object ignites.
@export var spawn_on_ignite : PackedScene
## PackedScene of VFX etc that gets spawned when object gets wet.
@export var spawn_on_wet : PackedScene
## PackedScene of VFX etc that gets spawned when object is electrified
@export var spawn_on_electrified : PackedScene


@export_group("Audio")
@export var audio_igniting : AudioStream
@export var audio_burning : AudioStream
@export var audio_extinguishing : AudioStream

var reaction_collider : Node3D = null
var spawned_effects : Array[Node] # Used to store and clear out spawned effects
var is_on_fire : bool = false
var is_electrified : bool = false
var player_is_touching : bool = false
var player_node : Node3D = null

func _ready():
	reaction_timer.timeout.connect(check_for_systemic_reactions)
	damage_timer.timeout.connect(apply_burn_damage)
	
	if ignite_on_ready:
		set_on_fire()
		
	if electrify_on_ready:
		electrify()
		
	if elemental_properties == ElementalProperties.WET:
		make_wet()


func start_reaction_threshold_timer(passed_collider: Node3D):
	# Quick check to see if the collider has any CogitoProperties.
	if( !passed_collider.cogito_properties):
		print("Collider ", passed_collider.name, " has no properties.")
		return
	
	# Saving passed collider to make sure we're reaction to the right thing.
	reaction_collider = passed_collider
	
	# Starting the reaction timer.
	if reaction_timer.is_stopped():
		reaction_timer.wait_time = reaction_threshold_time
		reaction_timer.start()


func check_for_reaction_timer_interrupt(passed_collider: Node3D):
	#print(get_parent().name , ": check for reaction timer interrupt called. Passed collider: ", passed_collider.name, ". Current reaction collider: ", reaction_collider.name)
	
	# Quick check to see if the collider has any CogitoProperties.
	if( !passed_collider.cogito_properties):
		print("Collider ", passed_collider.name, " has no properties.")
		return
	
	# If the passed_collider is the reaction_collider, then this reaction needs to be stopped.
	if passed_collider == reaction_collider:
		print(get_parent().name , ": Passed collider and current reaction collider match! Reaction timer is stopped is ", reaction_timer.is_stopped())
		if !reaction_timer.is_stopped():
			print(get_parent().name , " has stopped reaction timer as the collider ", passed_collider, " is no longer in contact.")
			reaction_timer.stop()


func check_for_systemic_reactions():
	if !reaction_collider:
		print("Reaction collider was null.")
		return
	if !reaction_collider.cogito_properties:
		# Case where the object has no properties defined.
		print("Collider ", reaction_collider.name, " has no properties.")
		return
		
	if reaction_collider.cogito_properties:
		if reaction_collider.cogito_properties.is_on_fire:
			if elemental_properties & ElementalProperties.FLAMMABLE:
				print(get_parent().name, ": Touched burning collider ", reaction_collider.name, ". I'm flammable, igniting self.")
				set_on_fire()
			else:
				print(get_parent().name, ": Touched collider ", reaction_collider.name, " which is on fire, but I'm not flammable, so nothing happens.")
			if elemental_properties & ElementalProperties.WET:
				print(get_parent().name, ": Touched burning collider ", reaction_collider.name, ". I'm wet so I'll extinguish the collider.")
				reaction_collider.cogito_properties.extinguish()


		print("Collider ", reaction_collider.name, " elemental properties: ", reaction_collider.cogito_properties.elemental_properties)
		match reaction_collider.cogito_properties.elemental_properties:
			ElementalProperties.WET:
				if is_on_fire:
					print(get_parent().name, ": Touched by wet collider ", reaction_collider.name, " while on fire. Extinguishing self.")
					extinguish()
					make_wet()
				else:
					print(get_parent().name, ": Touched by wet collider ", reaction_collider.name, " but wasn't on fire. Getting wet.")
					make_wet()


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
		spawn_elemental_vfx(spawn_on_wet)
	has_become_wet.emit()


func make_dry():
	elemental_properties = elemental_properties ^ ElementalProperties.WET
	clear_spawned_effects()
	has_become_dry.emit()


func set_on_fire():
	if elemental_properties & ElementalProperties.FLAMMABLE:
		is_on_fire = true
		if spawn_on_ignite:
			spawn_elemental_vfx(spawn_on_ignite)
			Audio.play_sound_3d(audio_igniting).position = self.position
		has_ignited.emit()
		
		if burn_damage_amount > 0:
			start_burn_damage_timer()
			
		audio_stream_player_3d.stream = audio_burning
		audio_stream_player_3d.play()
	else:
		print(get_parent().name, " is not FLAMMABLE.")


func start_burn_damage_timer():
	if damage_timer.is_stopped():
		damage_timer.wait_time = burn_damage_interval
		damage_timer.start()


func apply_burn_damage():
	deal_burn_damage.emit(burn_damage_amount)
	if is_on_fire:
		start_burn_damage_timer()


func extinguish():
	is_on_fire = false
	if !damage_timer.is_stopped():
		damage_timer.stop()
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
	if elemental_properties & ElementalProperties.CONDUCTIVE:
		is_electrified = true
		spawn_elemental_vfx(spawn_on_electrified)
		has_become_electrified.emit()
	else:
		print(get_parent().name, " is not CONDUCTIVE.")


func spawn_elemental_vfx(vfx_packed_scene:PackedScene):
	var spawned_object = vfx_packed_scene.instantiate()
	get_parent().add_child.call_deferred(spawned_object)
	spawned_effects.append(spawned_object)
	spawned_object.position = Vector3(0,0,0)

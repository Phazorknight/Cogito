@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoProperties.svg")
extends Node3D
## This class handles systeminc properties. Needs to be attached to a CogitoObject to work properly. For proper processing, said Object needs to have a signal hooked up to call check_for_systemic_interactions(collider).
class_name CogitoProperties

signal has_ignited()
signal has_been_extinguished()
signal deal_burn_damage(burn_damage_amount:float)
signal has_become_wet()
signal has_become_dry()
signal has_become_electric()
signal has_lost_electricity()

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
## The maximum amount of spawned vfx. Lower this to reduce potential performance issues.
@export var max_spawned_vfx : int = 5

@export_group("Burn Parameters")
## Sets if the object should ignite itself on ready. Needs to be flammable for this to work.
@export var ignite_on_ready : bool
## Amount of damage dealt to the health component while object is on fire.
@export var burn_damage_amount : float
## Interval the burn damage is applied in seconds.
@export var burn_damage_interval : float = 1.0


@export_group("Electricity Parameters")
## Sets if the object should become electrified on ready. Needs to be conductive for this to work.
@export var electric_on_ready : bool


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

@export_group("Debuging")
## If turned on, this object will print log messages (only if the global is_logging is turned on as well!)
@export var is_logging : bool = true

var reaction_collider : Node3D = null
var spawned_effects : Array[Node] # Used to store and clear out spawned effects
var is_on_fire : bool = false
var is_electric : bool = false
var player_is_touching : bool = false
var player_node : Node3D = null

var reaction_bodies : Array[Node3D] #Used to keep track of bodies with systemic properties.


func _ready():
	reaction_timer.timeout.connect(check_for_systemic_reactions)
	damage_timer.timeout.connect(apply_burn_damage)
	
	await get_parent().is_node_ready()
	
	if ignite_on_ready:
		set_on_fire.call_deferred()
		
	if electric_on_ready:
		make_electric.call_deferred()
		
	if elemental_properties == ElementalProperties.WET:
		make_wet.call_deferred()


func start_reaction_threshold_timer(passed_collider: Node3D):
	# Quick check to see if the collider has any CogitoProperties.
	if( !passed_collider.cogito_properties):
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", "Collider " + passed_collider.name + " has no properties.")
		return
	
	# Saving passed collider to make sure we're reaction to the right thing.
	reaction_collider = passed_collider
	
	add_systemic_body(passed_collider)
	
	# Starting the reaction timer.
	if reaction_timer.is_stopped():
		reaction_timer.wait_time = reaction_threshold_time
		reaction_timer.start()


func check_for_reaction_timer_interrupt(passed_collider: Node3D):

	# Quick check to see if the collider has any CogitoProperties.
	if( !passed_collider.cogito_properties):
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", "Collider " + passed_collider.name + " has no properties.")
		return
	
	remove_systemic_body(passed_collider)
	
	# If the passed_collider is the reaction_collider, then this reaction needs to be stopped.
	if passed_collider == reaction_collider:
		print(get_parent().name , ": Passed collider and current reaction collider match! Reaction timer is stopped is ", reaction_timer.is_stopped())
		if !reaction_timer.is_stopped():
			print(get_parent().name , " has stopped reaction timer as the collider ", passed_collider, " is no longer in contact.")
			reaction_timer.stop()
	
	if reaction_bodies.size() == 0:
		if !electric_on_ready:
			loose_electricity()


func check_for_systemic_reactions():
	if !reaction_collider:
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd","Reaction collider was null.")
		return
	if !reaction_collider.cogito_properties:
		# Case where the object has no properties defined.
		print("Collider ", reaction_collider.name, " has no properties.")
		return
	
	if reaction_collider.cogito_properties:
		### FIRE REACTIONS
		if reaction_collider.cogito_properties.is_on_fire:
			if elemental_properties & ElementalProperties.FLAMMABLE:
				print(get_parent().name, ": Touched burning collider ", reaction_collider.name, ". I'm flammable, igniting self.")
				set_on_fire()
			else:
				print(get_parent().name, ": Touched collider ", reaction_collider.name, " which is on fire, but I'm not flammable, so nothing happens.")
			if elemental_properties & ElementalProperties.WET:
				print(get_parent().name, ": Touched burning collider ", reaction_collider.name, ". I'm wet so I'll extinguish the collider.")
				reaction_collider.cogito_properties.extinguish()

		if elemental_properties & ElementalProperties.CONDUCTIVE: ### ELECTRICITY REACTIONS
			if is_electric:
				print("Electrified ", get_parent().name, " touched condictive collider ", reaction_collider.name, ". Trying to pass on electricity!")
				reaction_collider.cogito_properties.make_electric()
			if reaction_collider.cogito_properties.is_electric:
				print(get_parent().name, ": Touched by electrified collider ", reaction_collider.name, ". Getting electric.")
				make_electric()

		#print("Collider ", reaction_collider.name, " elemental properties: ", reaction_collider.cogito_properties.elemental_properties)
		match reaction_collider.cogito_properties.elemental_properties:
			ElementalProperties.WET: ### WATER REACTIONS
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
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", get_parent().name + " is not FLAMMABLE.")


func start_burn_damage_timer():
	if damage_timer.is_stopped():
		damage_timer.wait_time = burn_damage_interval
		damage_timer.start()


func apply_burn_damage():
	deal_burn_damage.emit(burn_damage_amount)
	# Calling damage received on Cogito Object or Enemy parent node.
	get_parent().damage_received.emit(burn_damage_amount)
	
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
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", "Clearing out spawned effect " + node.name)
		node.queue_free()
	spawned_effects.clear()


func make_electric():
	if elemental_properties & ElementalProperties.CONDUCTIVE:
		is_electric = true
		spawn_elemental_vfx(spawn_on_electrified)
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", get_parent().name + " has become electric.")
		has_become_electric.emit()
		
		recheck_systemic_reactions()
	else:
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", get_parent().name + " is not CONDUCTIVE.")


func loose_electricity():
	is_electric = false
	clear_spawned_effects()
	has_lost_electricity.emit()


func spawn_elemental_vfx(vfx_packed_scene:PackedScene):
	var spawned_object = vfx_packed_scene.instantiate()
	get_parent().add_child.call_deferred(spawned_object)
	
	# If max spawned vfx is reached, all spawned vfx will be cleared.
	if spawned_effects.size() <= max_spawned_vfx + 1:
		clear_spawned_effects()
		
	spawned_effects.append(spawned_object)
	spawned_object.position = Vector3(0,0,0)


func add_systemic_body(body: Node3D):
	if reaction_bodies.find(body) == -1:
		reaction_bodies.append(body)


func remove_systemic_body(body: Node3D):
	var index_in_reaction_bodies : int = reaction_bodies.find(body)
	if index_in_reaction_bodies != -1:
		reaction_bodies.remove_at(index_in_reaction_bodies)


func recheck_systemic_reactions():
	if reaction_bodies.size() < 1:
		CogitoGlobals.debug_log(is_logging, "cogito_properties.gd", get_parent().name + " systemic properties: Can't recheck reactions as there's no reaction bodies stored.")
		return
		
	for reaction_body in reaction_bodies:
		start_reaction_threshold_timer(reaction_body)

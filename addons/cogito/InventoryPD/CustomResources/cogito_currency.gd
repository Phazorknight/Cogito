@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoCurrency.svg")
extends Node
class_name CogitoCurrency

## Triggered whenever any of the attribute values changes.
signal currency_changed(currency_name:String, value_current:float, value_max:float, has_increased:bool)
## Triggered when this attribute current value reaches 0.
signal currency_reached_zero(currency_name:String, value_current:float, value_max:float)

## Used for scripting / condition checks, so should not include spaces and be all lowercase.
@export var currency_name : String
## Used for UI
@export var currency_display_name : String
## Used for UI / HUD.
@export var currency_color : Color
## Used for UI  /HUD.
@export var currency_icon : Texture2D
## Maximum value of this attribute. Can be changed/saved during runtime.
@export var value_max : float
## Value this attribute starts with per default.
@export var value_start : float
## Use this for when you want an attribute value to be unchangeable but still use signals etc. Can also be turned on/off at runtime.
@export var is_locked : bool = false
## Use this when you don't want an attribute's current value to not be saved.
@export var dont_save_current_value : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value_current = value_start

var value_current : float:
	set(value):
		var prev_value = value_current
		value_current = value
		if prev_value < value_current:
			currency_changed.emit(currency_name,value_current,value_max,true)
		elif prev_value > value_current:
			currency_changed.emit(currency_name,value_current,value_max,false)
		
		if value_current <= 0:
			value_current = 0
		
		if value_current > value_max:
			value_current = value_max


# Used when loading/setting an attribute
func set_attribute(_value_current:float, _value_max:float):
	value_current = _value_current
	value_max = _value_max


# Used when loading/setting a currency
func set_currency(_value_current:float, _value_max:float):
	value_current = _value_current
	value_max = _value_max

func add(amount):
	if is_locked:
		currency_changed.emit(currency_name,value_current,value_max,true)
		return
		
	value_current += amount


func subtract(amount):
	if is_locked:
		currency_changed.emit(currency_name,value_current,value_max,false)
		return
		
	value_current -= amount

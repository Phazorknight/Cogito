extends Control

@export var default_hint_icon : Texture2D

@onready var spacer_x: Panel = $HBoxContainer/SpacerX
@onready var hint_icon: TextureRect = $HBoxContainer/MarginContainer/HBoxContainer/HintIcon
@onready var hint_text: Label = $HBoxContainer/MarginContainer/HBoxContainer/HintText
@onready var hint_timer: Timer = $HintTimer

var tween_time: float = 0.5
var hint_time: float = 4.5
var fade_in_tween : Tween
var fade_out_tween : Tween



func _ready() -> void:
	hint_timer.timeout.connect(on_hint_timeout)
	hint_timer.wait_time = hint_time
	
	fade_in_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	fade_in_tween.tween_property(spacer_x,"custom_minimum_size", Vector2(0,0),tween_time)
	

func set_hint(passed_hint_icon:Texture2D, passed_hint_text:String):
	hint_text.text = passed_hint_text
	if passed_hint_icon != null:
		hint_icon.set_texture(passed_hint_icon)
	else:
		hint_icon.set_texture(default_hint_icon)

	# Starts the timer that sets how long the hint is going to be displayed.
	hint_timer.start()


func on_hint_timeout():
	fade_out_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	fade_out_tween.tween_property(self,"modulate", Color.TRANSPARENT, tween_time*2)
	
	await get_tree().create_timer(tween_time*2).timeout
	queue_free()

extends Button

@export var sfx_pressed : String = "btn_pressed"
@export var sfx_hover : String = "btn_hover"

@onready var pressed_to_call = "button_pressed"
@onready var hover_to_call = "button_hovered"

# Called when the node enters the scene tree for the first time.
func _ready():
	var callable_pressed_method = Callable(self, pressed_to_call)
	connect("pressed", callable_pressed_method)
	
	var callable_hover_method = Callable(self, hover_to_call)
	connect("focus_entered", callable_hover_method)
	connect("mouse_entered", callable_hover_method)


func button_hovered():
	AudioManagerPd.play_audio(sfx_hover)

func button_pressed():
	AudioManagerPd.play_audio(sfx_pressed)
	

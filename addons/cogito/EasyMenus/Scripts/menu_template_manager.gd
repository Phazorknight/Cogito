extends Node

const InputMapUpdater = preload("./input_map_updater.gd")
const OptionsConstants = preload("./options_constants.gd")

@onready var ControllerEchoInputGenerator = $ControllerEchoInputGenerator
@onready var startup_loader = $StartupLoader

# Called when the node enters the scene tree for the first time.
func _ready():
	InputMapUpdater.new()._ready()

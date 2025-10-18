extends Control

var gui_aspect_ratio = -1.0
var gui_margin = 0.0

@onready var panel = $Panel
@onready var arc = $Panel/AspectRatioContainer

func _ready():
	# The `resized` signal will be emitted when the window size changes, as the root Control node
	# is resized whenever the window size changes. This is because the root Control node
	# uses a Full Rect anchor, so its size will always be equal to the window size.
	resized.connect(_on_resized)
	CogitoSceneManager.update_gui.connect(_on_gui_options_changed)
	update_container.call_deferred()


func update_container():
	# The code within this function needs to be run deferred to work around an issue with containers
	# having a 1-frame delay with updates.
	# Otherwise, `panel.size` returns a value of the previous frame, which results in incorrect
	# sizing of the inner AspectRatioContainer when using the Fit to Window setting.
	for _i in 2:
		if is_equal_approx(gui_aspect_ratio, -1.0):
			# Fit to Window. Tell the AspectRatioContainer to use the same aspect ratio as the window,
			# making the AspectRatioContainer not have any visible effect.
			arc.ratio = panel.size.aspect()
			# Apply GUI offset on the AspectRatioContainer's parent (Panel).
			# This also makes the GUI offset apply on controls located outside the AspectRatioContainer
			# (such as the inner side label in this demo).
			panel.offset_top = gui_margin
			panel.offset_bottom = -gui_margin
		else:
			# Constrained aspect ratio.
			arc.ratio = min(panel.size.aspect(), gui_aspect_ratio)
			# Adjust top and bottom offsets relative to the aspect ratio when it's constrained.
			# This ensures that GUI offset settings behave exactly as if the window had the
			# original aspect ratio size.
			panel.offset_top = gui_margin / gui_aspect_ratio
			panel.offset_bottom = -gui_margin / gui_aspect_ratio

		panel.offset_left = gui_margin
		panel.offset_right = -gui_margin


func _on_resized():
	update_container.call_deferred()


func _on_gui_options_changed():
	update_container.call_deferred()

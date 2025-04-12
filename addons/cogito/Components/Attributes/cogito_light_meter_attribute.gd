extends CogitoAttribute
class_name CogitoLightmeter
# NOTE: This is currently quite expensive on performance due to the get_average_color function.

@export_group("Lightmeter Performance")
##Should light be updating constantly or only when player moves? Disable to constantly update at the cost of performance
@export var update_on_move_only : bool = true
## Sets a time interval to update the lightmeter. Can be used in addition to move-only to improve performance. Set to 0 to turn off.
@export var update_frequency: float = 1.0
##Lower for better performance
@export var subviewport_resolution : int = 256
##Interpolation used for get_average_color function. Default for Lightmeter is Lanczos, change for better performance
@export var interpolation_method: Image.Interpolation = Image.INTERPOLATE_LANCZOS

@onready var sub_viewport := $SubViewport
@onready var light_detection := $SubViewport/LightDetection
@onready var texture_rect := $SubViewport/LightDetection/TextureRect
@onready var color_rect := $SubViewport/LightDetection/ColorRect
@onready var timer: Timer = $Timer
@onready var previous_position : Vector3 = get_parent().global_position


func _ready() -> void:
	if update_frequency > 0:
		timer.wait_time = update_frequency
		timer.timeout.connect(on_timeout)
		timer.start()
	
	sub_viewport.size = Vector2(subviewport_resolution, subviewport_resolution)


func get_average_color(texture: ViewportTexture) -> Color:
	var image = texture.get_image() # Get the Image of the input texture
	image.resize(1, 1,interpolation_method) # Resize the image to one pixel
	return image.get_pixel(0, 0) # Read the color of that pixel


func on_timeout():
	update_lightmeter_attribute()
	timer.start()
	
	
func update_lightmeter_attribute():
	light_detection.global_position = get_parent().global_position # Make light detection follow the player
	previous_position = light_detection.global_position
	var texture = sub_viewport.get_texture() # Get the ViewportTexture from the SubViewport
	#texture_rect.texture = texture # Display this texture on the TextureRect
	var color = get_average_color(texture) # Get the average color of the ViewportTexture
	color_rect.color = color # Display the average color on the ColorRect
	set_attribute(color.get_luminance() * 100, 100)


func _process(_delta: float) -> void:
	#Skip updating every frame is update_on_move_only is enabled
	if update_on_move_only:
		# A little check to reduce how many times the light detection is done.
		if previous_position == get_parent().global_position:
			return
		
		update_lightmeter_attribute()

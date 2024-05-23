extends CogitoAttribute
# NOTE: This is currently quite expensive on performance due to the get_average_color function.


@onready var sub_viewport := $SubViewport
@onready var light_detection := $SubViewport/LightDetection
@onready var texture_rect := $SubViewport/LightDetection/TextureRect
@onready var color_rect := $SubViewport/LightDetection/ColorRect

@onready var previous_position : Vector3 = get_parent().global_position

func get_average_color(texture: ViewportTexture) -> Color:
	var image = texture.get_image() # Get the Image of the input texture
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS) # Resize the image to one pixel
	return image.get_pixel(0, 0) # Read the color of that pixel

func _process(_delta: float) -> void:
	# A little check to reduce how many times the light detection is done.
	if previous_position == get_parent().global_position:
		return
	
	light_detection.global_position = get_parent().global_position # Make light detection follow the player
	previous_position = light_detection.global_position
	var texture = sub_viewport.get_texture() # Get the ViewportTexture from the SubViewport
	#texture_rect.texture = texture # Display this texture on the TextureRect
	var color = get_average_color(texture) # Get the average color of the ViewportTexture
	color_rect.color = color # Display the average color on the ColorRect
	set_attribute(color.get_luminance() * 100, 100)

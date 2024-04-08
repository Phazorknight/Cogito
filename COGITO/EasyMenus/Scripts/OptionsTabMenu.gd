extends TabContainer
class_name OptionsTabMenu
signal options_updated

const HSliderWLabel = preload("res://COGITO/EasyMenus/Scripts/slider_w_labels.gd")

@export var nodes_to_focus: Array[Control]

@onready var sfx_volume_slider : HSliderWLabel = $%SFXVolumeSlider
@onready var music_volume_slider: HSliderWLabel = $%MusicVolumeSlider
@onready var render_scale_current_value_label: Label = %RenderScaleCurrentValueLabel
@onready var render_scale_slider: HSlider = %RenderScaleSlider
@onready var gui_scale_current_value_label: Label = %GUIScaleCurrentValueLabel
@onready var gui_scale_slider: HSlider = %GUIScaleSlider
@onready var vsync_check_button: CheckButton = %VSyncCheckButton
@onready var invert_y_check_button: CheckButton = %InvertYAxisCheckButton
@onready var anti_aliasing_2d_option_button: OptionButton = $%AntiAliasing2DOptionButton
@onready var anti_aliasing_3d_option_button: OptionButton = $%AntiAliasing3DOptionButton
@onready var window_mode_option_button: OptionButton = %WindowModeOptionButton
@onready var resolution_option_button: OptionButton = %ResolutionOptionButton

@onready var shadow_size_option_button: OptionButton = %ShadowSizeOptionButton
@onready var shadow_filter_option_button: OptionButton = %ShadowFilterOptionButton
@onready var sdfgi_option_button: OptionButton = %SDFGIOptionButton
@onready var glow_option_button: OptionButton = %GlowOptionButton
@onready var ssao_option_button: OptionButton = %SSAOOptionButton
@onready var ss_reflections_option_button: OptionButton = $%SSReflectionsOptionButton
@onready var ssil_option_button: OptionButton = %SSILOptionButton
@onready var volumetric_fog_option_button: OptionButton = %VolumetricFogOptionButton
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var contrast_slider: HSlider = %ContrastSlider

@onready var world_environment: WorldEnvironment = $WorldEnvironment

var sfx_bus_index
var music_bus_index
var config = ConfigFile.new()
var render_resolution : Vector2i
var render_scale_val : float

# Array to set window modes.
const WINDOW_MODE_ARRAY : Array[String] = [
	"Exclusive Fullscreen",
	"Fullscreen",
	"Windowed",
	"Borderless windowed"
]


const RESOLUTION_DICTIONARY : Dictionary = {
	"1280x720 (16:9)" : Vector2i(1280,720),
	"1280x800 (16:10)" : Vector2i(1280,800),
	"1366x768 (16:9)" : Vector2i(1366,768),
	"1440x900 (16:10)" : Vector2i(1440,900),
	"1600x900 (16:9)" : Vector2i(1600,900),
	"1920x1080 (16:9)" : Vector2i(1920,1080),
	"2560x1440 (16:9)" : Vector2i(2560,1440),
	"3840x2160 (16:9)" : Vector2i(3840,2160)
}


func _ready() -> void:
	add_window_mode_items()
	add_resolution_items()
	window_mode_option_button.item_selected.connect(on_window_mode_selected)
	resolution_option_button.item_selected.connect(on_resolution_selected)
	
	sfx_bus_index = AudioServer.get_bus_index(OptionsConstants.sfx_bus_name)
	music_bus_index = AudioServer.get_bus_index(OptionsConstants.music_bus_name)
	
	#load_options.call_deferred()
	load_options()

# Called from outside initializes the options menu
func on_open():
	pass

func _input(event):
	if !visible:
		return
	
	#Tab navigation
	if (event.is_action_pressed("ui_next_tab")):
		if current_tab + 1 == get_tab_count():
			current_tab = 0
		else:
			current_tab += 1
			
		if nodes_to_focus[current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[current_tab].grab_focus.call_deferred()
		
	if (event.is_action_pressed("ui_prev_tab")):
		if current_tab  == 0:
			current_tab = get_tab_count()-1
		else:
			current_tab -= 1
			
		if nodes_to_focus[current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[current_tab].grab_focus.call_deferred()


# Adding window modes to the window mode button.
func add_window_mode_items() -> void:
	for mode in WINDOW_MODE_ARRAY:
		window_mode_option_button.add_item(mode)
		
# Adding resolutions to the resolution button.
func add_resolution_items() -> void:
	for resolution_text in RESOLUTION_DICTIONARY:
		resolution_option_button.add_item(resolution_text)


# Function to change window modes. Hooked up to the window_mode_option_button.
func on_window_mode_selected(index: int) -> void:
	match index:
		0: #Exclusive full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1: #Full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		3: #Borderless windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


func refresh_render():
	get_window().content_scale_size = render_resolution
	get_window().scaling_3d_scale = render_scale_val

# Function to change resolution. Hooked up to the resolution_option_button.
func on_resolution_selected(index:int) -> void:
	render_resolution = RESOLUTION_DICTIONARY.values()[index]
	refresh_render()
	get_window().size = render_resolution


func _on_sfx_volume_slider_value_changed(value):
	set_volume(sfx_bus_index, value)
	_on_apply_changes_pressed()


func _on_music_volume_slider_value_changed(value):
	set_volume(music_bus_index, value)
	_on_apply_changes_pressed()


# Sets the volume for the given audio bus
func set_volume(bus_index, value):
	print("Setting volume on bus_index ", bus_index, " to ", value)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


# Saves the options
func save_options():
	config.set_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, sfx_volume_slider.hslider.value)
	config.set_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, music_volume_slider.hslider.value)
	config.set_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, window_mode_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, resolution_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, render_scale_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, gui_scale_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.vsync_key, vsync_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, invert_y_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, anti_aliasing_2d_option_button.get_selected_id())
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, anti_aliasing_3d_option_button.get_selected_id())
	
	config.set_value(OptionsConstants.section_name, OptionsConstants.shadow_size_key, shadow_size_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.shadow_filter_key, shadow_filter_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.sdfgi_key, sdfgi_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.glow_key, glow_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.ssao_key, ssao_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.ss_reflections_key, ss_reflections_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.ssil_key, ssil_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.volumetric_fog_key, volumetric_fog_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.brightness_key, brightness_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.contrast_key, contrast_slider.value);
	
	config.save(OptionsConstants.config_file_name)

# Loads options and sets the controls values to loaded values. Uses default values if config file does not exist
func load_options():
	var err = config.load(OptionsConstants.config_file_name)
	if err != 0:
		print("Loading options config failed. Assuming and saving defaults.")
	
	var sfx_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, 1)
	var music_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, 1)
	var window_mode = config.get_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, 0)
	var resolution_index = config.get_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, 0)
	var render_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, 1)
	var gui_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, 1)
	var vsync = config.get_value(OptionsConstants.section_name, OptionsConstants.vsync_key, true)
	var invert_y = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
	var msaa_2d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, 0)
	var msaa_3d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, 0)
	
	var shadow_size = config.get_value(OptionsConstants.section_name, OptionsConstants.shadow_size_key, shadow_size_option_button.selected)
	var shadow_filter = config.get_value(OptionsConstants.section_name, OptionsConstants.shadow_filter_key, shadow_filter_option_button.selected)
	var sdfgi = config.get_value(OptionsConstants.section_name, OptionsConstants.sdfgi_key, sdfgi_option_button.selected)
	var glow = config.get_value(OptionsConstants.section_name, OptionsConstants.glow_key, glow_option_button.selected)
	var ssao = config.get_value(OptionsConstants.section_name, OptionsConstants.ssao_key, ssao_option_button.selected)
	var ss_reflections = config.get_value(OptionsConstants.section_name, OptionsConstants.ss_reflections_key, ss_reflections_option_button.selected)
	var ssil = config.get_value(OptionsConstants.section_name, OptionsConstants.ssil_key, ssil_option_button.selected)
	var volumetric_fog = config.get_value(OptionsConstants.section_name, OptionsConstants.volumetric_fog_key, volumetric_fog_option_button.selected)
	var brightness = config.get_value(OptionsConstants.section_name, OptionsConstants.brightness_key, brightness_slider.value);
	var contrast = config.get_value(OptionsConstants.section_name, OptionsConstants.contrast_key, contrast_slider.value);
	
	world_environment.environment.adjustment_brightness = brightness
	brightness_slider.set_value_no_signal(brightness)
	world_environment.environment.adjustment_contrast = contrast
	contrast_slider.set_value_no_signal(contrast)
	
	_on_volumetric_fog_option_button_item_selected(volumetric_fog)
	volumetric_fog_option_button.selected = volumetric_fog
	_on_ssil_option_button_item_selected(ssil)
	ssil_option_button.selected = ssil
	_on_ss_reflections_option_button_item_selected(ss_reflections)
	ss_reflections_option_button.selected = ss_reflections
	_on_ssao_option_button_item_selected(ssao)
	ssao_option_button.selected = ssao
	_on_glow_option_button_item_selected(glow)
	glow_option_button.selected = glow
	_on_sdfgi_option_button_item_selected(sdfgi)
	sdfgi_option_button.selected = sdfgi
	_on_shadow_filter_option_button_item_selected(shadow_filter)
	shadow_filter_option_button.selected = shadow_filter
	_on_shadow_size_option_button_item_selected(shadow_size)
	shadow_size_option_button.selected = shadow_size
	
	sfx_volume_slider.hslider.value = sfx_volume
	music_volume_slider.hslider.value = music_volume
	render_scale_slider.value = render_scale
	render_scale_val = render_scale
	
	gui_scale_slider.value = gui_scale
	gui_scale_current_value_label.text = str(gui_scale)
	apply_gui_scale_value()
	
	# Need to set it like that to guarantee signal to be triggered
	vsync_check_button.set_pressed_no_signal(vsync)
	vsync_check_button.emit_signal("toggled", vsync)
	
	invert_y_check_button.set_pressed_no_signal(invert_y)
	invert_y_check_button.emit_signal("toggled", invert_y)
	
	anti_aliasing_2d_option_button.selected = msaa_2d
	anti_aliasing_2d_option_button.emit_signal("item_selected", msaa_2d)
	anti_aliasing_3d_option_button.selected = msaa_3d
	anti_aliasing_3d_option_button.emit_signal("item_selected", msaa_3d)
	
	window_mode_option_button.selected = window_mode
	window_mode_option_button.item_selected.emit(window_mode)
	resolution_option_button.selected = resolution_index
	resolution_option_button.item_selected.emit(resolution_index)
	
	refresh_render()
	window_mode_option_button.item_selected.emit(window_mode_option_button.selected)


func _on_render_scale_slider_value_changed(value):
	render_scale_val = value
	render_scale_current_value_label.text = str(value)
	refresh_render()


func _on_gui_scale_slider_value_changed(value):
	gui_scale_current_value_label.text = str(value)

	
func _on_gui_scale_slider_drag_ended(_value_changed):
	apply_gui_scale_value()

# TODO: Apply changes if the slider is clicked but not dragged
func apply_gui_scale_value():
	get_viewport().content_scale_factor = gui_scale_slider.value
	gui_scale_current_value_label.text = str(gui_scale_slider.value)


func _on_v_sync_check_button_toggled(button_pressed):
	# There are multiple V-Sync Methods supported by Godot 
	# For now we just use the simple ones could be worth a consideration to add the others
	# Just sets V-Sync for the first window. So no support for multi window games
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_anti_aliasing_2d_option_button_item_selected(index):
	set_msaa("msaa_2d", index)


func _on_anti_aliasing_3d_option_button_item_selected(index):
	set_msaa("msaa_3d", index)


func set_msaa(mode, index):
	match index:
		0:
			get_viewport().set(mode,Viewport.MSAA_DISABLED)
		1:
			get_viewport().set(mode,Viewport.MSAA_2X)
		2:
			get_viewport().set(mode,Viewport.MSAA_4X)
		3:
			get_viewport().set(mode,Viewport.MSAA_8X)


func _on_apply_changes_pressed() -> void:
	window_mode_option_button.item_selected.emit(window_mode_option_button.selected)
	save_options()
	options_updated.emit()

func _on_tab_menu_resume():
	# reload options
	load_options.call_deferred()


func _on_potato_pressed() -> void:
	set_msaa("msaa_3d",0)
	set_msaa("msaa_2d",0)
	%ShadowSizeOptionButton.selected = 0
	%ShadowFilterOptionButton.selected = 0
	%SDFGIOptionButton.selected = 0
	%GlowOptionButton.selected = 0
	%SSAOOptionButton.selected = 0
	%SSReflectionsOptionButton.selected = 0
	%SSILOptionButton.selected = 0
	%VolumetricFogOptionButton.selected = 0
	update_preset()

func _on_low_pressed() -> void:
	set_msaa("msaa_3d",1)
	set_msaa("msaa_2d",1)
	%ShadowSizeOptionButton.selected = 1
	%ShadowFilterOptionButton.selected = 1
	%SDFGIOptionButton.selected = 0
	%GlowOptionButton.selected = 0
	%SSAOOptionButton.selected = 0
	%SSReflectionsOptionButton.selected = 0
	%SSILOptionButton.selected = 0
	%VolumetricFogOptionButton.selected = 0
	update_preset()

func _on_medium_pressed() -> void:
	set_msaa("msaa_3d",3)
	set_msaa("msaa_2d",2)
	%ShadowSizeOptionButton.selected = 2
	%ShadowFilterOptionButton.selected = 2
	%SDFGIOptionButton.selected = 1
	%GlowOptionButton.selected = 1
	%SSAOOptionButton.selected = 1
	%SSReflectionsOptionButton.selected = 1
	%SSILOptionButton.selected = 0
	%VolumetricFogOptionButton.selected = 1
	update_preset()

func _on_high_pressed() -> void:	
	set_msaa("msaa_3d",3)
	set_msaa("msaa_2d",3)
	%ShadowSizeOptionButton.selected = 3
	%ShadowFilterOptionButton.selected = 3
	%SDFGIOptionButton.selected = 1
	%GlowOptionButton.selected = 2
	%SSAOOptionButton.selected = 2
	%SSReflectionsOptionButton.selected = 2
	%SSILOptionButton.selected = 2
	%VolumetricFogOptionButton.selected = 2 
	update_preset()

func _on_ultra_pressed() -> void:
	set_msaa("msaa_3d",3)
	set_msaa("msaa_2d",3)
	%ShadowSizeOptionButton.selected = 5
	%ShadowFilterOptionButton.selected = 5
	%SDFGIOptionButton.selected = 2
	%GlowOptionButton.selected = 2
	%SSAOOptionButton.selected = 4
	%SSReflectionsOptionButton.selected = 3
	%SSILOptionButton.selected = 4
	%VolumetricFogOptionButton.selected = 2
	update_preset()

func update_preset() -> void:
	# Simulate options being manually selected to run their respective update code.s
	%ShadowSizeOptionButton.item_selected.emit(%ShadowSizeOptionButton.selected)
	%ShadowFilterOptionButton.item_selected.emit(%ShadowFilterOptionButton.selected)
	%SDFGIOptionButton.item_selected.emit(%SDFGIOptionButton.selected)
	%GlowOptionButton.item_selected.emit(%GlowOptionButton.selected)
	%SSAOOptionButton.item_selected.emit(%SSAOOptionButton.selected)
	%SSReflectionsOptionButton.item_selected.emit(%SSReflectionsOptionButton.selected)
	%SSILOptionButton.item_selected.emit(%SSILOptionButton.selected)
	%VolumetricFogOptionButton.item_selected.emit(%VolumetricFogOptionButton.selected)
	%BrightnessSlider.value_changed.emit(%BrightnessSlider.value)


func _on_limit_fps_slider_value_changed(value: float):
	Engine.max_fps = value

func _on_shadow_size_option_button_item_selected(index):
	if index == 0: # Minimum
		RenderingServer.directional_shadow_atlas_set_size(512, true)
		# Adjust shadow bias according to shadow resolution.
		# Higher resultions can use a lower bias without suffering from shadow acne.
		#directional_light.shadow_bias = 0.06
		#FIXME: ADD DIRECTIONAL LIGHT, and world enviroment to main menu
		# Disable positional (omni/spot) light shadows entirely to further improve performance.
		# These often don't contribute as much to a scene compared to directional light shadows.
		get_viewport().positional_shadow_atlas_size = 0
	if index == 1: # Very Low
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
		#directional_light.shadow_bias = 0.04
		get_viewport().positional_shadow_atlas_size = 1024
	if index == 2: # Low
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
		#directional_light.shadow_bias = 0.03
		get_viewport().positional_shadow_atlas_size = 2048
	if index == 3: # Medium (default)
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
		#directional_light.shadow_bias = 0.02
		get_viewport().positional_shadow_atlas_size = 4096
	if index == 4: # High
		RenderingServer.directional_shadow_atlas_set_size(8192, true)
		#directional_light.shadow_bias = 0.01
		get_viewport().positional_shadow_atlas_size = 8192
	if index == 5: # Ultra
		RenderingServer.directional_shadow_atlas_set_size(16384, true)
		#directional_light.shadow_bias = 0.005
		get_viewport().positional_shadow_atlas_size = 16384

func _on_shadow_filter_option_button_item_selected(index):
	if index == 0: # Very Low
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	if index == 1: # Low
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
	if index == 2: # Medium (default)
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	if index == 3: # High
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	if index == 4: # Very High
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	if index == 5: # Ultra
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
		RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)


# The following Region is depending on settings that are attached to the environment.
# If your game requires you to change the environment,
# then be sure to run this function again to make the setting effective.
#region World Environment depending functions


func _on_saturation_slider_value_changed(value: float) -> void:
	# The slider value is clamped between 0.5 and 10.
	world_environment.environment.set_adjustment_saturation(value)


func _on_contrast_slider_value_changed(value: float) -> void:
	# The slider value is clamped between 0.5 and 2.
	world_environment.environment.set_adjustment_contrast(value)


func _on_brightness_slider_value_changed(value: float) -> void:
	# The slider value is clamped between 0.5 and 2.
	world_environment.environment.set_adjustment_brightness(value)


func _on_sdfgi_option_button_item_selected(index):
	if index == 0: # Disabled (default)
		world_environment.environment.sdfgi_enabled = false
	if index == 1: # Low
		world_environment.environment.sdfgi_enabled = true
		RenderingServer.gi_set_use_half_resolution(true)
	if index == 2: # High
		world_environment.environment.sdfgi_enabled = true
		RenderingServer.gi_set_use_half_resolution(false)


func _on_glow_option_button_item_selected(index):
	if index == 0: # Disabled (default)
		world_environment.environment.glow_enabled = false
	if index == 1: # Low
		world_environment.environment.glow_enabled = true
	if index == 2: # High
		world_environment.environment.glow_enabled = true


func _on_ssao_option_button_item_selected(index):
	if index == 0: # Disabled (default)
		world_environment.environment.ssao_enabled = false
	if index == 1: # Very Low
		world_environment.environment.ssao_enabled = true
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_VERY_LOW, true, 0.5, 2, 50, 300)
	if index == 2: # Low
		world_environment.environment.ssao_enabled = true
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_VERY_LOW, true, 0.5, 2, 50, 300)
	if index == 3: # Medium
		world_environment.environment.ssao_enabled = true
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_MEDIUM, true, 0.5, 2, 50, 300)
	if index == 4: # High
		world_environment.environment.ssao_enabled = true
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_HIGH, true, 0.5, 2, 50, 300)


func _on_ss_reflections_option_button_item_selected(index: int) -> void:
	if index == 0: # Disabled (default)
		world_environment.environment.set_ssr_enabled(false)
	elif index == 1: # Low
		world_environment.environment.set_ssr_enabled(true)
		world_environment.environment.set_ssr_max_steps(8)
	elif index == 2: # Medium
		world_environment.environment.set_ssr_enabled(true)
		world_environment.environment.set_ssr_max_steps(32)
	elif index == 3: # High
		world_environment.environment.set_ssr_enabled(true)
		world_environment.environment.set_ssr_max_steps(56)


func _on_ssil_option_button_item_selected(index):
	if index == 0: # Disabled (default)
		world_environment.environment.ssil_enabled = false
	if index == 1: # Very Low
		world_environment.environment.ssil_enabled = true
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_VERY_LOW, true, 0.5, 4, 50, 300)
	if index == 2: # Low
		world_environment.environment.ssil_enabled = true
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_LOW, true, 0.5, 4, 50, 300)
	if index == 3: # Medium
		world_environment.environment.ssil_enabled = true
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM, true, 0.5, 4, 50, 300)
	if index == 4: # High
		world_environment.environment.ssil_enabled = true
		RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_HIGH, true, 0.5, 4, 50, 300)

func _on_volumetric_fog_option_button_item_selected(index):
	if index == 0: # Disabled (default)
		world_environment.environment.volumetric_fog_enabled = false
	if index == 1: # Low
		world_environment.environment.volumetric_fog_enabled = true
		RenderingServer.environment_set_volumetric_fog_filter_active(false)
	if index == 2: # High
		world_environment.environment.volumetric_fog_enabled = true
		RenderingServer.environment_set_volumetric_fog_filter_active(true)

#endregion

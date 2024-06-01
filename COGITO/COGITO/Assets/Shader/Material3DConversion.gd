extends BaseMaterial3D
class_name Material3DConversion

const shader_names = {
	"albedo_color": "albedo",
	"metallic_specular": "specular",
	"roughness": "roughness",
	"metallic": "metallic",
	"emission": "emission",
	"emission_energy": "emission_energy",
	"normal_scale": "normal_scale",
	"rim": "rim",
	"rim_tint": "rim_tint",
	"clearcoat": "clearcoat",
	"clearcoat_roughness": "clearcoat_roughness",
	"anisotropy": "anisotropy_ratio",
	"heightmap_scale": "heightmap_scale",
	"subsurf_scatter_strength": "subsurface_scattering_strength",
	"backlight": "backlight",
	"refraction": "refraction",
	"point_size": "point_size",
	"uv1_scale": "uv1_scale",
	"uv1_offset": "uv1_offset",
	"uv2_scale": "uv2_scale",
	"uv2_offset": "uv2_offset",
	"uv1_blend_sharpness": "uv1_blend_sharpness",
	"uv2_blend_sharpness": "uv2_blend_sharpness",
	"particles_anim_h_frames": "particles_anim_h_frames",
	"particles_anim_v_frames": "particles_anim_v_frames",
	"particles_anim_loop": "particles_anim_loop",
	"heightmap_min_layers": "heightmap_min_layers",
	"heightmap_max_layers": "heightmap_max_layers",
	"heightmap_flip": "heightmap_flip",
	"mat.grow": "mat.grow",
	"ao_light_affect": "ao_light_affect",
	"proximity_fade_distance": "proximity_fade_distance",
	"distance_fade_min": "distance_fade_min",
	"distance_fade_max": "distance_fade_max",
	"msdf_pixel_range": "msdf_pixel_range",
	"msdf_outline_size": "msdf_outline_size",
#	"metallic_texture_channel": "metallic_texture_channel",
#	"ao_texture_channel": "ao_texture_channel",
#	"clearcoat_texture_channel": "clearcoat_texture_channel",
#	"rim_texture_channel": "rim_texture_channel",
#	"heightmap_texture_channel": "heightmap_texture_channel",
#	"refraction_texture_channel": "refraction_texture_channel",
	"transmittance_color": "transmittance_color",
	"transmittance_depth": "transmittance_depth",
	"transmittance_boost": "transmittance_boost",
	"texture_names": {
		TEXTURE_ALBEDO: "texture_albedo",
		TEXTURE_METALLIC: "texture_metallic",
		TEXTURE_ROUGHNESS: "texture_roughness",
		TEXTURE_EMISSION: "texture_emission",
		TEXTURE_NORMAL: "texture_normal",
		TEXTURE_RIM: "texture_rim",
		TEXTURE_CLEARCOAT: "texture_clearcoat",
		TEXTURE_FLOWMAP: "texture_flowmap",
		TEXTURE_AMBIENT_OCCLUSION: "texture_ambient_occlusion",
		TEXTURE_HEIGHTMAP: "texture_heightmap",
		TEXTURE_SUBSURFACE_SCATTERING: "texture_subsurface_scattering",
		TEXTURE_SUBSURFACE_TRANSMITTANCE: "texture_subsurface_transmittance",
		TEXTURE_BACKLIGHT: "texture_backlight",
		TEXTURE_REFRACTION: "texture_refraction",
		TEXTURE_DETAIL_MASK: "texture_detail_mask",
		TEXTURE_DETAIL_ALBEDO: "texture_detail_albedo",
		TEXTURE_DETAIL_NORMAL: "texture_detail_normal",
		TEXTURE_ORM: "texture_orm"
	},
	"alpha_scissor_threshold": "alpha_scissor_threshold",
	"alpha_hash_scale": "alpha_hash_scale",
	"alpha_antialiasing_edge": "alpha_antialiasing_edge",
	"albedo_texture_size": "albedo_texture_size"
}

static func convert_to_shadermat(mat : StandardMaterial3D, injected_vars : String, injected_vertex : String):
	var shader_mat = ConvertedMaterial.new()
	shader_mat.cache(mat)
	shader_mat.shader = Shader.new()
	shader_mat.shader.code = create_shader_code(mat, injected_vars, injected_vertex)
	for property in shader_names:
		if property == "texture_names":
			for texture in shader_names[property]:
				shader_mat.set_shader_parameter(shader_names[property][texture],mat.get_texture(texture))
		else:
			shader_mat.set_shader_parameter(shader_names[property],mat.get(property))
	
	return shader_mat

static func write_texture_channel(var_name : String, texture_channel : TextureChannel, prefix = "uniform"):
	# fun fact: Godot engine (as of right now) does not do these correctly, and implementation varies per feature. Yay. *sigh*
	var code = prefix + " vec4 " + var_name + " = vec4("
	match texture_channel:
		TEXTURE_CHANNEL_RED:
			code += "1.0,0.0,0.0,0.0);\n"
		TEXTURE_CHANNEL_GREEN:
			code += "0.0,1.0,0.0,0.0);\n"
		TEXTURE_CHANNEL_BLUE:
			code += "0.0,0.0,1.0,0.0);\n"
		TEXTURE_CHANNEL_ALPHA:
			code += "0.0,0.0,0.0,1.0);\n"
		TEXTURE_CHANNEL_GRAYSCALE:
			code += "0.333333,0.333333,0.333333,0.0);\n"
	return code

static func create_shader_code(mat : StandardMaterial3D, injected_vars : String, injected_vertex : String):
	var texfilter_str: String
	var texfilter_height_str: String

	match mat.texture_filter:
		TEXTURE_FILTER_NEAREST:
			texfilter_str = "filter_nearest"
			texfilter_height_str = "filter_linear"
		TEXTURE_FILTER_LINEAR:
			texfilter_str = "filter_linear"
			texfilter_height_str = "filter_linear"
		TEXTURE_FILTER_NEAREST_WITH_MIPMAPS:
			texfilter_str = "filter_nearest_mipmap"
			texfilter_height_str = "filter_linear_mipmap"
		TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
			texfilter_str = "filter_linear_mipmap"
			texfilter_height_str = "filter_linear_mipmap"
		TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC:
			texfilter_str = "filter_nearest_mipmap_anisotropic"
			texfilter_height_str = "filter_linear_mipmap_anisotropic"
		TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:
			texfilter_str = "filter_linear_mipmap_anisotropic"
			texfilter_height_str = "filter_linear_mipmap_anisotropic"
		TEXTURE_FILTER_MAX:
			pass # Internal value, skip.

	if mat.get_flag(FLAG_USE_TEXTURE_REPEAT):
		texfilter_str += ",repeat_enable"
		texfilter_height_str += ",repeat_enable"
	else:
		texfilter_str += ",repeat_disable"
		texfilter_height_str += ",repeat_disable"

	var code = "shader_type spatial;\nrender_mode "

	match mat.blend_mode:
		BLEND_MODE_MIX:
			code += "blend_mix"
		BLEND_MODE_ADD:
			code += "blend_add"
		BLEND_MODE_SUB:
			code += "blend_sub"
		BLEND_MODE_MUL:
			code += "blend_mul"

	var ddm = mat.depth_draw_mode
	if mat.get_feature(FEATURE_REFRACTION):
		ddm = DEPTH_DRAW_ALWAYS
	

	match ddm:
		DEPTH_DRAW_OPAQUE_ONLY:
			code += ",depth_draw_opaque"
			
		DEPTH_DRAW_ALWAYS:
			code += ",depth_draw_always"
			
		DEPTH_DRAW_DISABLED:
			code += ",depth_draw_never"
	

	match mat.cull_mode:
		CULL_BACK:
			code += ",cull_back"
			
		CULL_FRONT:
			code += ",cull_front"
			
		CULL_DISABLED:
			code += ",cull_disabled"
	
	match mat.diffuse_mode:
		DIFFUSE_BURLEY:
			code += ",diffuse_burley"
			
		DIFFUSE_LAMBERT:
			code += ",diffuse_lambert"
			
		DIFFUSE_LAMBERT_WRAP:
			code += ",diffuse_lambert_wrap"
			
		DIFFUSE_TOON:
			code += ",diffuse_toon"
	
	match mat.specular_mode:
		SPECULAR_SCHLICK_GGX:
			code += ",specular_schlick_ggx"
			
		SPECULAR_TOON:
			code += ",specular_toon"
			
		SPECULAR_DISABLED:
			code += ",specular_disabled"
	
	if mat.get_feature(FEATURE_SUBSURFACE_SCATTERING) && mat.get_flag(FLAG_SUBSURFACE_MODE_SKIN):
		code += ",sss_mode_skin"

	if mat.shading_mode == SHADING_MODE_UNSHADED:
		code += ",unshaded"
	if mat.get_flag(FLAG_DISABLE_DEPTH_TEST):
		code += ",depth_test_disabled"
	if mat.get_flag(FLAG_PARTICLE_TRAILS_MODE):
		code += ",particle_trails"
	if mat.shading_mode == SHADING_MODE_PER_VERTEX:
		code += ",vertex_lighting"
	if mat.get_flag(FLAG_DONT_RECEIVE_SHADOWS):
		code += ",shadows_disabled"
	if mat.get_flag(FLAG_DISABLE_AMBIENT_LIGHT):
		code += ",ambient_light_disabled"
	if mat.get_flag(FLAG_USE_SHADOW_TO_OPACITY):
		code += ",shadow_to_opacity"
	if mat.get_flag(FLAG_DISABLE_FOG):
		code += ",fog_disabled"

	if mat.transparency == TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
		code += ",depth_prepass_alpha"

	# Alpha antialiasing
	if mat.transparency == TRANSPARENCY_ALPHA_HASH or mat.transparency == TRANSPARENCY_ALPHA_SCISSOR:
		if mat.alpha_antialiasing_mode == ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE:
			code += ",alpha_to_coverage"
		elif mat.alpha_antialiasing_mode == ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE:
			code += ",alpha_to_coverage_and_one"

	code += ";\n"
	
	code += injected_vars

	code += "uniform vec4 albedo : source_color;\n"
	code += "uniform sampler2D texture_albedo : source_color," + texfilter_str + ";\n"
	if mat.grow:
		code += "uniform float mat.grow;\n"

	if mat.proximity_fade_enabled:
		code += "uniform float proximity_fade_distance;\n"
	if mat.distance_fade_mode != DISTANCE_FADE_DISABLED:
		code += "uniform float distance_fade_min;\n"
		code += "uniform float distance_fade_max;\n"

	if mat.get_flag(FLAG_ALBEDO_TEXTURE_MSDF):
		code += "uniform float msdf_pixel_range;\n"
		code += "uniform float msdf_outline_size;\n"

	# Alpha scissor or hash
	if mat.transparency == TRANSPARENCY_ALPHA_SCISSOR:
		code += "uniform float alpha_scissor_threshold;\n"
	elif mat.transparency == TRANSPARENCY_ALPHA_HASH:
		code += "uniform float alpha_hash_scale;\n"

	# Alpha antialiasing edge
	if mat.alpha_antialiasing_mode != ALPHA_ANTIALIASING_OFF and (mat.transparency == TRANSPARENCY_ALPHA_SCISSOR or mat.transparency == TRANSPARENCY_ALPHA_HASH):
		code += "uniform float alpha_antialiasing_edge;\n"
		code += "uniform ivec2 albedo_texture_size;\n"

	code += "uniform float point_size : hint_range(0,128);\n"

	code += "uniform float roughness : hint_range(0,1);\n"
	code += "uniform sampler2D texture_metallic : " + texfilter_str + ";\n"
	
	code += write_texture_channel("metallic_texture_channel", mat.metallic_texture_channel)
	
	code += write_texture_channel("roughness_texture_channel", mat.roughness_texture_channel)
	
	code += "uniform sampler2D texture_roughness : " + texfilter_str + ";\n"

	code += "uniform float specular;\n"
	code += "uniform float metallic;\n"
	
	if mat.billboard_mode == BILLBOARD_PARTICLES:
		code += "uniform int particles_anim_h_frames;\n"
		code += "uniform int particles_anim_v_frames;\n"
		code += "uniform bool particles_anim_loop;\n"

	if mat.get_feature(FEATURE_EMISSION):
		code += "uniform sampler2D texture_emission : source_color, hint_default_black," + texfilter_str + ";\n"
		code += "uniform vec4 emission : source_color;\n"
		code += "uniform float emission_energy;\n"

	if mat.get_feature(FEATURE_REFRACTION):
		code += "uniform sampler2D texture_refraction : " + texfilter_str + ";\n"
		code += "uniform float refraction : hint_range(-16,16);\n"
		code += write_texture_channel("refraction_texture_channel", mat.refraction_texture_channel)

	if mat.get_feature(FEATURE_REFRACTION):
		code += "uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;"

	if mat.proximity_fade_enabled:
		code += "uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;"

	if mat.get_feature(FEATURE_NORMAL_MAPPING):
		code += "uniform sampler2D texture_normal : hint_roughness_normal," + texfilter_str + ";\n"
		code += "uniform float normal_scale : hint_range(-16,16);\n"

	if mat.get_feature(FEATURE_RIM):
		code += "uniform float rim : hint_range(0,1);\n"
		code += "uniform float rim_tint : hint_range(0,1);\n"
		code += "uniform sampler2D texture_rim : hint_default_white," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_CLEARCOAT):
		code += "uniform float clearcoat : hint_range(0,1);\n"
		code += "uniform float clearcoat_roughness : hint_range(0,1);\n"
		code += "uniform sampler2D texture_clearcoat : hint_default_white," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_ANISOTROPY):
		code += "uniform float anisotropy_ratio : hint_range(0,256);\n"
		code += "uniform sampler2D texture_flowmap : hint_anisotropy," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_AMBIENT_OCCLUSION):
		code += "uniform sampler2D texture_ambient_occlusion : hint_default_white, " + texfilter_str + ";\n"
		code += write_texture_channel("ao_texture_channel", mat.ao_texture_channel)
		code += "uniform float ao_light_affect;\n"

	if mat.get_feature(FEATURE_DETAIL):
		code += "uniform sampler2D texture_detail_albedo : source_color," + texfilter_str + ";\n"
		code += "uniform sampler2D texture_detail_normal : hint_normal," + texfilter_str + ";\n"
		code += "uniform sampler2D texture_detail_mask : hint_default_white," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_SUBSURFACE_SCATTERING):
		code += "uniform float subsurface_scattering_strength : hint_range(0,1);\n"
		code += "uniform sampler2D texture_subsurface_scattering : hint_default_white," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_SUBSURFACE_TRANSMITTANCE):
		code += "uniform vec4 transmittance_color : source_color;\n"
		code += "uniform float transmittance_depth;\n"
		code += "uniform sampler2D texture_subsurface_transmittance : hint_default_white," + texfilter_str + ";\n"
		code += "uniform float transmittance_boost;\n"

	if mat.get_feature(FEATURE_BACKLIGHT):
		code += "uniform vec4 backlight : source_color;\n"
		code += "uniform sampler2D texture_backlight : hint_default_black," + texfilter_str + ";\n"

	if mat.get_feature(FEATURE_HEIGHT_MAPPING):
		code += "uniform sampler2D texture_heightmap : hint_default_black," + texfilter_height_str + ";\n"
		code += "uniform float heightmap_scale;\n"
		code += "uniform int heightmap_min_layers;\n"
		code += "uniform int heightmap_max_layers;\n"
		code += "uniform vec2 heightmap_flip;\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "varying vec3 uv1_triplanar_pos;\n"

	if mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		code += "varying vec3 uv2_triplanar_pos;\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "uniform float uv1_blend_sharpness;\n"
		code += "varying vec3 uv1_power_normal;\n"

	if mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		code += "uniform float uv2_blend_sharpness;\n"
		code += "varying vec3 uv2_power_normal;\n"

	code += "uniform vec3 uv1_scale;\n"
	code += "uniform vec3 uv1_offset;\n"
	code += "uniform vec3 uv2_scale;\n"
	code += "uniform vec3 uv2_offset;\n"
	code += "\n\n"
	code += "void vertex() {\n"
	if mat.get_flag(FLAG_SRGB_VERTEX_COLOR):
		code += "	if (!OUTPUT_IS_SRGB) {\n"
		code += "		COLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));\n"
		code += "	}\n"

	if mat.get_flag(FLAG_USE_POINT_SIZE):
		code += "	POINT_SIZE=point_size;\n"

	if mat.shading_mode == SHADING_MODE_PER_VERTEX:
		code += "	ROUGHNESS=roughness;\n"

	if not mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "	UV=UV*uv1_scale.xy+uv1_offset.xy;\n"

	match mat.billboard_mode:
		BILLBOARD_DISABLED:
			pass
		BILLBOARD_ENABLED:
			code += "	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);\n"
			if mat.get_flag(FLAG_BILLBOARD_KEEP_SCALE):
				code += "	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n"
			code += "	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);\n"
		BILLBOARD_FIXED_Y:
			code += "	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);\n"
			if mat.get_flag(FLAG_BILLBOARD_KEEP_SCALE):
				code += "	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n"
			code += "	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);\n"
		BILLBOARD_PARTICLES:
			code += "	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]) ,normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);\n"
			code += "	mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n"
			code += "	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;\n"
			if mat.get_flag(FLAG_BILLBOARD_KEEP_SCALE):
				code += "	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n"
			code += "	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);\n"

			code += "	float h_frames = float(particles_anim_h_frames);\n"
			code += "	float v_frames = float(particles_anim_v_frames);\n"
			code += "	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);\n"
			code += "	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));\n"
			code += "	if (!particles_anim_loop) {\n"
			code += "		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);\n"
			code += "	} else {\n"
			code += "		particle_frame = mod(particle_frame, particle_total_frames);\n"
			code += "	}\n"
			code += "	UV /= vec2(h_frames, v_frames);\n"
			code += "	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames);\n"

	if mat.get_flag(FLAG_FIXED_SIZE):
		code += "	if (PROJECTION_MATRIX[3][3] != 0.0) {\n"
		code += "		float h = abs(1.0 / (2.0 * PROJECTION_MATRIX[1][1]));\n"
		code += "		float sc = (h * 2.0); //consistent with Y-fov\n"
		code += "		MODELVIEW_MATRIX[0]*=sc;\n"
		code += "		MODELVIEW_MATRIX[1]*=sc;\n"
		code += "		MODELVIEW_MATRIX[2]*=sc;\n"
		code += "	} else {\n"
		code += "} else {\n"
		code += "		float sc = -(MODELVIEW_MATRIX)[3].z;\n"
		code += "		MODELVIEW_MATRIX[0]*=sc;\n"
		code += "		MODELVIEW_MATRIX[1]*=sc;\n"
		code += "		MODELVIEW_MATRIX[2]*=sc;\n"
		code += "	}\n"

	if mat.detail_uv_layer == DETAIL_UV_2 and not mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		code += "	UV2=UV2*uv2_scale.xy+uv2_offset.xy;\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR) or mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		if mat.get_flag(FLAG_UV1_USE_WORLD_TRIPLANAR):
			code += "	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;\n"
		else:
			code += "	vec3 normal = NORMAL;\n"
		code += "	TANGENT = vec3(0.0,0.0,-1.0) * abs(normal.x);\n"
		code += "	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.y);\n"
		code += "	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.z);\n"
		if mat.get_flag(FLAG_UV1_USE_WORLD_TRIPLANAR):
			code += "	TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);\n"
		else:
			code += "	TANGENT = normalize(TANGENT);\n"
		
		code += "	BINORMAL = vec3(0.0,1.0,0.0) * abs(normal.x);\n"
		code += "	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(normal.y);\n"
		code += "	BINORMAL+= vec3(0.0,1.0,0.0) * abs(normal.z);\n"
		if mat.get_flag(FLAG_UV1_USE_WORLD_TRIPLANAR):
			code += "	BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);\n"
		else:
			code += "	BINORMAL = normalize(BINORMAL);\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		if mat.get_flag(FLAG_UV1_USE_WORLD_TRIPLANAR):
			code += "	uv1_power_normal=pow(abs(normal),vec3(uv1_blend_sharpness));\n"
			code += "	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz * uv1_scale + uv1_offset;\n"
		else:
			code += "	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));\n"
			code += "	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;\n"
		code += "	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));\n"
		code += "	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);\n"

	if mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		if mat.get_flag(FLAG_UV2_USE_WORLD_TRIPLANAR):
			code += "	uv2_power_normal=pow(abs(mat3(MODEL_MATRIX) * NORMAL), vec3(uv2_blend_sharpness));\n"
			code += "	uv2_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz * uv2_scale + uv2_offset;\n"
		else:
			code += "	uv2_power_normal=pow(abs(NORMAL), vec3(uv2_blend_sharpness));\n"
			code += "	uv2_triplanar_pos = VERTEX * uv2_scale + uv2_offset;\n"
		code += "	uv2_power_normal/=dot(uv2_power_normal,vec3(1.0));\n"
		code += "	uv2_triplanar_pos *= vec3(1.0,-1.0, 1.0);\n"

	if mat.grow:
		code += "	VERTEX += NORMAL * mat.grow;\n"

	code += injected_vertex

	code += "}\n"
	code += "\n\n"

	if mat.get_flag(FLAG_ALBEDO_TEXTURE_MSDF):
		code += "float msdf_median(float r, float g, float b, float a) {\n"
		code += "	return min(max(min(r, g), min(max(r, g), b)), a);\n"
		code += "}\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR) or mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
		code += "vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {\n"
		code += "	vec4 samp=vec4(0.0);\n"
		code += "	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;\n"
		code += "	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;\n"
		code += "	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;\n"
		code += "	return samp;\n"
		code += "}\n"
	
	code += "\n\n"
	code += "void fragment() {\n"

	if not mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "	vec2 base_uv = UV;\n"
		
	if (mat.get_feature(FEATURE_DETAIL) && mat.detail_uv_layer == DETAIL_UV_2) || (mat.get_feature(FEATURE_AMBIENT_OCCLUSION) && mat.get_flag(FLAG_AO_ON_UV2)) || (mat.get_feature(FEATURE_EMISSION) && mat.get_flag(FLAG_EMISSION_ON_UV2)):
		code += "	vec2 base_uv2 = UV2;\n"

	if mat.get_feature(FEATURE_HEIGHT_MAPPING) && !mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "	{\n"
		code += "		vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT * heightmap_flip.x, -BINORMAL * heightmap_flip.y, NORMAL));\n"

		if mat.heightmap_deep_parallax:
			code += "		float num_layers = mix(float(heightmap_max_layers),float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));\n"
			code += "		float layer_depth = 1.0 / num_layers;\n"
			code += "		float current_layer_depth = 0.0;\n"
			code += "		vec2 P = view_dir.xy * heightmap_scale * 0.01;\n"
			code += "		vec2 delta = P / num_layers;\n"
			code += "		vec2 ofs = base_uv;\n"
			if mat.get_flag(FLAG_INVERT_HEIGHTMAP):
				code += "		float depth = texture(texture_heightmap, ofs).r;\n"
			else:
				code += "		float depth = 1.0 - texture(texture_heightmap, ofs).r;\n"
			code += "		float current_depth = 0.0;\n"
			code += "		while(current_depth < depth) {\n"
			code += "			ofs -= delta;\n"
			if mat.get_flag(FLAG_INVERT_HEIGHTMAP):
				code += "			depth = texture(texture_heightmap, ofs).r;\n"
			else:
				code += "			depth = 1.0 - texture(texture_heightmap, ofs).r;\n"
			code += "			current_depth += layer_depth;\n"
			code += "		}\n"
			code += "		vec2 prev_ofs = ofs + delta;\n"
			code += "		float after_depth  = depth - current_depth;\n"
			if mat.get_flag(FLAG_INVERT_HEIGHTMAP):
				code += "		float before_depth = texture(texture_heightmap, prev_ofs).r - current_depth + layer_depth;\n"
			else:
				code += "		float before_depth = (1.0 - texture(texture_heightmap, prev_ofs).r) - current_depth + layer_depth;\n"
			code += "		float weight = after_depth / (after_depth - before_depth);\n"
			code += "		ofs = mix(ofs, prev_ofs, weight);\n"

		else:
			if mat.get_flag(FLAG_INVERT_HEIGHTMAP):
				code += "		float depth = texture(texture_heightmap, base_uv).r;\n"
			else:
				code += "		float depth = 1.0 - texture(texture_heightmap, base_uv).r;\n"
			code += "		vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;\n"

		code += "		base_uv = ofs;\n"
		if mat.get_feature(FEATURE_DETAIL) && mat.detail_uv_layer == DETAIL_UV_2:
			code += "		base_uv2 -= ofs;\n"

		code += "	}\n"

	if mat.get_flag(FLAG_USE_POINT_SIZE):
		code += "	vec4 albedo_tex = texture(texture_albedo, POINT_COORD);\n"
	else:
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);\n"
		else:
			code += "	vec4 albedo_tex = texture(texture_albedo, base_uv);\n"

	if mat.get_flag(FLAG_ALBEDO_TEXTURE_MSDF):
		code += "	{\n"
		code += "		albedo_tex.rgb = mix(vec3(1.0 + 0.055) * pow(albedo_tex.rgb, vec3(1.0 / 2.4)) - vec3(0.055), vec3(12.92) * albedo_tex.rgb.rgb, lessThan(albedo_tex.rgb, vec3(0.0031308)));\n"
		code += "		vec2 msdf_size = vec2(msdf_pixel_range) / vec2(textureSize(texture_albedo, 0));\n"
		if mat.get_flag(FLAG_USE_POINT_SIZE):
			code += "		vec2 dest_size = vec2(1.0) / fwidth(POINT_COORD);\n"
		else:
			if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
				code += "		vec2 dest_size = vec2(1.0) / fwidth(uv1_triplanar_pos);\n"
			else:
				code += "		vec2 dest_size = vec2(1.0) / fwidth(base_uv);\n"
		code += "		float px_size = max(0.5 * dot(msdf_size, dest_size), 1.0);\n"
		code += "		float d = msdf_median(albedo_tex.r, albedo_tex.g, albedo_tex.b, albedo_tex.a) - 0.5;\n"
		code += "		if (msdf_outline_size > 0.0) {\n"
		code += "			float cr = clamp(msdf_outline_size, 0.0, msdf_pixel_range / 2.0) / msdf_pixel_range;\n"
		code += "			albedo_tex.a = clamp((d + cr) * px_size, 0.0, 1.0);\n"
		code += "		} else {\n"
		code += "			albedo_tex.a = clamp(d * px_size + 0.5, 0.0, 1.0);\n"
		code += "		}\n"
		code += "		albedo_tex.rgb = vec3(1.0);\n"
		code += "	}\n"
	elif mat.get_flag(FLAG_ALBEDO_TEXTURE_FORCE_SRGB):
		code += "	albedo_tex.rgb = mix(pow((albedo_tex.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),albedo_tex.rgb.rgb * (1.0 / 12.92),lessThan(albedo_tex.rgb,vec3(0.04045)));\n"

	if mat.get_flag(FLAG_ALBEDO_FROM_VERTEX_COLOR):
		code += "	albedo_tex *= COLOR;\n"
	code += "	ALBEDO = albedo.rgb * albedo_tex.rgb;\n"

	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "	float metallic_tex = dot(triplanar_texture(texture_metallic,uv1_power_normal,uv1_triplanar_pos),metallic_texture_channel);\n"
	else:
		code += "	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);\n"
	code += "	METALLIC = metallic_tex * metallic;\n"


	if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
		code += "	float roughness_tex = dot(triplanar_texture(texture_roughness,uv1_power_normal,uv1_triplanar_pos),roughness_texture_channel);\n"
	else:
		code += "	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);\n"
	code += "	ROUGHNESS = roughness_tex * roughness;\n"
	code += "	SPECULAR = specular;\n"

	if mat.get_feature(FEATURE_NORMAL_MAPPING):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	NORMAL_MAP = triplanar_texture(texture_normal,uv1_power_normal,uv1_triplanar_pos).rgb;\n"
		else:
			code += "	NORMAL_MAP = texture(texture_normal,base_uv).rgb;\n"
		code += "	NORMAL_MAP_DEPTH = normal_scale;\n"

	if mat.get_feature(FEATURE_EMISSION):
		if mat.get_flag(FLAG_EMISSION_ON_UV2):
			if mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
				code += "	vec3 emission_tex = triplanar_texture(texture_emission,uv2_power_normal,uv2_triplanar_pos).rgb;\n"
			else:
				code += "	vec3 emission_tex = texture(texture_emission,base_uv2).rgb;\n"
		else:
			if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
				code += "	vec3 emission_tex = triplanar_texture(texture_emission,uv1_power_normal,uv1_triplanar_pos).rgb;\n"
			else:
				code += "	vec3 emission_tex = texture(texture_emission,base_uv).rgb;\n"

		if mat.emission_operator == EMISSION_OP_ADD:
			code += "	EMISSION = (emission.rgb+emission_tex)*emission_energy;\n"
		else:
			code += "	EMISSION = (emission.rgb*emission_tex)*emission_energy;\n"

	if mat.get_feature(FEATURE_REFRACTION):
		if mat.get_feature(FEATURE_NORMAL_MAPPING):
			code += "	vec3 unpacked_normal = NORMAL_MAP;\n"
			code += "	unpacked_normal.xy = unpacked_normal.xy * 2.0 - 1.0;\n"
			code += "	unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));\n"
			code += "	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * unpacked_normal.x + BINORMAL * unpacked_normal.y + NORMAL * unpacked_normal.z,NORMAL_MAP_DEPTH) );\n"
		else:
			code += "	vec3 ref_normal = NORMAL;\n"

		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(triplanar_texture(texture_refraction,uv1_power_normal,uv1_triplanar_pos),refraction_texture_channel) * refraction;\n"
		else:
			code += "	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(texture(texture_refraction,base_uv),refraction_texture_channel) * refraction;\n"

		code += "	float ref_amount = 1.0 - albedo.a * albedo_tex.a;\n"
		code += "	EMISSION += textureLod(screen_texture,ref_ofs,ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE;\n"
		code += "	ALBEDO *= 1.0 - ref_amount;\n"
		code += "	ALPHA = 1.0;\n"

	elif mat.transparency != TRANSPARENCY_DISABLED || mat.get_flag(FLAG_USE_SHADOW_TO_OPACITY) || (mat.distance_fade_mode == DISTANCE_FADE_PIXEL_ALPHA) || mat.proximity_fade_enabled:
		code += "	ALPHA *= albedo.a * albedo_tex.a;\n"

	if mat.transparency == TRANSPARENCY_ALPHA_HASH:
		code += "	ALPHA_HASH_SCALE = alpha_hash_scale;\n"
	elif mat.transparency == TRANSPARENCY_ALPHA_SCISSOR:
		code += "	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;\n"

	if mat.alpha_antialiasing_mode != ALPHA_ANTIALIASING_OFF and (mat.transparency == TRANSPARENCY_ALPHA_HASH or mat.transparency == TRANSPARENCY_ALPHA_SCISSOR):
		code += "	ALPHA_ANTIALIASING_EDGE = alpha_antialiasing_edge;\n"
		code += "	ALPHA_TEXTURE_COORDINATE = UV * vec2(albedo_texture_size);\n"

	if mat.proximity_fade_enabled:
		code += "	float depth_tex = textureLod(depth_texture,SCREEN_UV,0.0).r;\n"
		code += "	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex,1.0);\n"
		code += "	world_pos.xyz/=world_pos.w;\n"
		code += "	ALPHA*=clamp(1.0-smoothstep(world_pos.z+proximity_fade_distance,world_pos.z,VERTEX.z),0.0,1.0);\n"

	if mat.distance_fade_mode != DISTANCE_FADE_DISABLED:
		if mat.distance_fade_mode == DISTANCE_FADE_OBJECT_DITHER or mat.distance_fade_mode == DISTANCE_FADE_PIXEL_DITHER:
			code += "	{\n"

			if mat.distance_fade_mode == DISTANCE_FADE_OBJECT_DITHER:
				code += "		float fade_distance = length((VIEW_MATRIX * MODEL_MATRIX[3]));\n"
			else:
				code += "		float fade_distance = length(VERTEX);\n"

			code += "		const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);\n"
			code += "		float fade = clamp(smoothstep(distance_fade_min, distance_fade_max, fade_distance), 0.0, 1.0);\n"
			code += "		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {\n"
			code += "			discard;\n"
			code += "		}\n"

			code += "	}\n\n"

	if mat.get_feature(FEATURE_RIM):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec2 rim_tex = triplanar_texture(texture_rim, uv1_power_normal, uv1_triplanar_pos).xy;\n"
		else:
			code += "	vec2 rim_tex = texture(texture_rim, base_uv).xy;\n"
		code += "	RIM = rim * rim_tex.x;\n"
		code += "	RIM_TINT = rim_tint * rim_tex.y;\n"

	if mat.get_feature(FEATURE_CLEARCOAT):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec2 clearcoat_tex = triplanar_texture(texture_clearcoat, uv1_power_normal, uv1_triplanar_pos).xy;\n"
		else:
			code += "	vec2 clearcoat_tex = texture(texture_clearcoat, base_uv).xy;\n"
		code += "	CLEARCOAT = clearcoat * clearcoat_tex.x;\n"
		code += "	CLEARCOAT_ROUGHNESS = clearcoat_roughness * clearcoat_tex.y;\n"

	if mat.get_feature(FEATURE_ANISOTROPY):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec3 anisotropy_tex = triplanar_texture(texture_flowmap, uv1_power_normal, uv1_triplanar_pos).rga;\n"
		else:
			code += "	vec3 anisotropy_tex = texture(texture_flowmap, base_uv).rga;\n"
		code += "	ANISOTROPY = anisotropy_ratio * anisotropy_tex.b;\n"
		code += "	ANISOTROPY_FLOW = anisotropy_tex.rg * 2.0 - 1.0;\n"

	if mat.get_feature(FEATURE_AMBIENT_OCCLUSION):
		if mat.get_flag(FLAG_AO_ON_UV2):
			if mat.get_flag(FLAG_UV2_USE_TRIPLANAR):
				code += "	AO = dot(triplanar_texture(texture_ambient_occlusion, uv2_power_normal, uv2_triplanar_pos), ao_texture_channel);\n"
			else:
				code += "	AO = dot(texture(texture_ambient_occlusion, base_uv2), ao_texture_channel);\n"
		else:
			if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
				code += "	AO = dot(triplanar_texture(texture_ambient_occlusion, uv1_power_normal, uv1_triplanar_pos), ao_texture_channel);\n"
			else:
				code += "	AO = dot(texture(texture_ambient_occlusion, base_uv), ao_texture_channel);\n"
		code += "	AO_LIGHT_AFFECT = ao_light_affect;\n"


	if mat.get_feature(FEATURE_SUBSURFACE_SCATTERING):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	float sss_tex = triplanar_texture(texture_subsurface_scattering, uv1_power_normal, uv1_triplanar_pos).r;\n"
		else:
			code += "	float sss_tex = texture(texture_subsurface_scattering, base_uv).r;\n"
		code += "	SSS_STRENGTH = subsurface_scattering_strength * sss_tex;\n"

	if mat.get_feature(FEATURE_SUBSURFACE_TRANSMITTANCE):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec4 trans_color_tex = triplanar_texture(texture_subsurface_transmittance, uv1_power_normal, uv1_triplanar_pos);\n"
		else:
			code += "	vec4 trans_color_tex = texture(texture_subsurface_transmittance, base_uv);\n"
		code += "	SSS_TRANSMITTANCE_COLOR = transmittance_color * trans_color_tex;\n"
		code += "	SSS_TRANSMITTANCE_DEPTH = transmittance_depth;\n"
		code += "	SSS_TRANSMITTANCE_BOOST = transmittance_boost;\n"

	if mat.get_feature(FEATURE_BACKLIGHT):
		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec3 backlight_tex = triplanar_texture(texture_backlight, uv1_power_normal, uv1_triplanar_pos).rgb;\n"
		else:
			code += "	vec3 backlight_tex = texture(texture_backlight, base_uv).rgb;\n"
		code += "	BACKLIGHT = backlight.rgb + backlight_tex;\n"

	if mat.get_feature(FEATURE_DETAIL):
		var triplanar = (mat.get_flag(FLAG_UV1_USE_TRIPLANAR) && mat.detail_uv_layer == DETAIL_UV_1) || (mat.get_flag(FLAG_UV2_USE_TRIPLANAR) && mat.detail_uv_layer == DETAIL_UV_2)

		if triplanar:
			var tp_uv = "uv1" if mat.detail_uv_layer == DETAIL_UV_1 else "uv2"
			code += "	vec4 detail_tex = triplanar_texture(texture_detail_albedo," + tp_uv + "_power_normal," + tp_uv + "_triplanar_pos);\n"
			code += "	vec4 detail_norm_tex = triplanar_texture(texture_detail_normal," + tp_uv + "_power_normal," + tp_uv + "_triplanar_pos);\n"
		else:
			var det_uv = "base_uv" if mat.detail_uv_layer == DETAIL_UV_1 else "base_uv2"
			code += "	vec4 detail_tex = texture(texture_detail_albedo," + det_uv + ");\n"
			code += "	vec4 detail_norm_tex = texture(texture_detail_normal," + det_uv + ");\n"

		if mat.get_flag(FLAG_UV1_USE_TRIPLANAR):
			code += "	vec4 detail_mask_tex = triplanar_texture(texture_detail_mask,uv1_power_normal,uv1_triplanar_pos);\n"
		else:
			code += "	vec4 detail_mask_tex = texture(texture_detail_mask,base_uv);\n"

		match mat.detail_blend_mode:
			BLEND_MODE_MIX:
				code += "	vec3 detail = mix(ALBEDO.rgb,detail_tex.rgb,detail_tex.a);\n"
			BLEND_MODE_ADD:
				code += "	vec3 detail = mix(ALBEDO.rgb,ALBEDO.rgb+detail_tex.rgb,detail_tex.a);\n"
			BLEND_MODE_SUB:
				code += "	vec3 detail = mix(ALBEDO.rgb,ALBEDO.rgb-detail_tex.rgb,detail_tex.a);\n"
			BLEND_MODE_MUL:
				code += "	vec3 detail = mix(ALBEDO.rgb,ALBEDO.rgb*detail_tex.rgb,detail_tex.a);\n"

		code += "	vec3 detail_norm = mix(NORMAL_MAP,detail_norm_tex.rgb,detail_tex.a);\n"
		code += "	NORMAL_MAP = mix(NORMAL_MAP,detail_norm,detail_mask_tex.r);\n"
		code += "	ALBEDO.rgb = mix(ALBEDO.rgb,detail,detail_mask_tex.r);\n"

	code += "}\n"

	return code

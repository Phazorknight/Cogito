shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

global uniform float viewmodel_fov = 75.0f;
instance uniform bool viewmodel_enabled = true;
uniform vec4 albedo_color : source_color;
uniform sampler2D albedo_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D metallic_texture : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform int metallic_texture_channel : hint_range(0,4);
uniform sampler2D roughness_texture : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform int roughness_texture_channel : hint_range(0,4);
uniform float metallic_specular;
uniform float metallic;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	if(viewmodel_enabled){
		/* begin shader magic*/
		float onetanfov = 1.0f / tan(0.5f * (viewmodel_fov * PI / 180.0f));
		float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
		// modify projection matrix to match FOV
		PROJECTION_MATRIX[1][1] = -onetanfov;
		PROJECTION_MATRIX[0][0] = onetanfov / aspect;
		// this next part draws the viewmodel over everything (disable if you want dof near on viewmodel)
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
		POSITION.z = mix(POSITION.z, 0, 0.999);
		/* end shader magic */
	}
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(albedo_texture,base_uv);
	ALBEDO = albedo_color.rgb * albedo_tex.rgb;
	
	vec4 metallic_tex_channel;
	if(roughness_texture_channel == 4){
		metallic_tex_channel = vec4(1.0);
	} else {
		metallic_tex_channel = vec4(0.0);
		metallic_tex_channel[metallic_texture_channel] = 1.0;
	}
	
	float metallic_tex = dot(texture(metallic_texture,base_uv),metallic_tex_channel);
	METALLIC = metallic_tex * metallic;
	
	vec4 roughness_tex_channel;
	if(roughness_texture_channel == 4){
		roughness_tex_channel = vec4(1.0);
	} else {
		roughness_tex_channel = vec4(0.0);
		roughness_tex_channel[roughness_texture_channel] = 1.0;
	}
	float roughness_tex = dot(texture(roughness_texture,base_uv),roughness_tex_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	SPECULAR = metallic_specular;
}

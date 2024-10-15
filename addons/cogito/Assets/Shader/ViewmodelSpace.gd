@tool
extends ShaderSpace
class_name ViewmodelSpace
## This node will configure all meshes childed inside of it (recursively) to act without clipping through wall, useful for wieldable viewmodels to keep them in-front
## 
## Useful for viewmodels for wieldables. Can toggle the clipping behavior by setting `disable_viewmodel_clipping`

var _viewmodel_clipping_disabled : bool = true

## When this is checked, it will make it so any childed viewmodel will always be rendered in front of everything else
@export var disable_viewmodel_clipping : bool = true:
	get:
		return _viewmodel_clipping_disabled
	set(value):
		_viewmodel_clipping_disabled = value
		set_instance_shader_parameter("viewmodel_enabled", value)

func _init():
	injected_vars = '''
	global uniform float viewmodel_fov = 75.0f;
	instance uniform bool viewmodel_enabled = true;'''

	injected_vertex = '''
		/* begin shader magic*/
		float onetanfov = 1.0f / tan(0.5f * (viewmodel_fov * PI / 180.0f));
		float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
		// modify projection matrix to match FOV
		PROJECTION_MATRIX[1][1] = -onetanfov;
		PROJECTION_MATRIX[0][0] = onetanfov / aspect;
		// this next part draws the viewmodel over everything (disable if you want dof near on viewmodel)
			
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
		
		if(viewmodel_enabled){
			POSITION.z = mix(POSITION.z, 0, 0.999);
		}
		/* end shader magic */
	'''

func convert_surfaces():
	super()
	if not _viewmodel_clipping_disabled:
		set_instance_shader_parameter("viewmodel_enabled",_viewmodel_clipping_disabled)

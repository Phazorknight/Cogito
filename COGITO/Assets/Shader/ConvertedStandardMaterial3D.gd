extends ShaderMaterial
class_name ConvertedMaterial
## See Material3DConversion. Any changes made to this will not stick if you go back to the regular models by unbaking!

@export var original_material : String
@export var original_material_cache : StandardMaterial3D

func cache(mat : StandardMaterial3D):
	if Engine.is_editor_hint():
		if (not mat.resource_path) or '.tscn' in mat.resource_path:
			print("WARNING: Material ",str(mat), " is not saved to disk. Storing in memory. Recommend un-baking, save to disk, then re-bake")
			original_material_cache = mat
		else:
			original_material = mat.resource_path

func get_original_material() -> StandardMaterial3D:
	var mat = original_material_cache
	if not mat:
		mat = load(original_material)
	return mat

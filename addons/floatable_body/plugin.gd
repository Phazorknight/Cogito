@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("FluidArea2D", "RigidBody2D", preload("res://addons/floatable_body/fluid_area_2d.gd"), null)
	add_custom_type("FluidArea3D", "RigidBody3D", preload("res://addons/floatable_body/fluid_area_3d.gd"), null)
	add_custom_type("FloatableBody2D", "RigidBody2D", preload("res://addons/floatable_body/floatable_body_2d.gd"), null)
	add_custom_type("FloatableBody3D", "RigidBody3D", preload("res://addons/floatable_body/floatable_body_3d.gd"), null)


func _exit_tree():
	remove_custom_type("FloatableBody3D")
	remove_custom_type("FloatableBody2D")
	remove_custom_type("FluidArea3D")
	remove_custom_type("FluidArea2D")

@tool
extends EditorPlugin

var import_plugin : EditorScenePostImportPlugin = null

func _enter_tree():
	import_plugin = preload("res://addons/correct_bone_direction/correct_bone_dir.gd").new()
	add_scene_post_import_plugin(import_plugin)


func _exit_tree():
	add_scene_post_import_plugin(import_plugin)
	import_plugin = null

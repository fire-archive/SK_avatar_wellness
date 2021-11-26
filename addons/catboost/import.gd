# MIT License
# 
# Copyright (c) 2020 K. S. Ernest (iFire) Lee & V-Sekai
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorScenePostImport

var catboost : RefCounted 

const settings_catboost_path = "filesystem/import/vrm_catboost/catboost_path"

var catboost_path : String

func _init():
	if not ProjectSettings.has_setting(settings_catboost_path):
		ProjectSettings.set_initial_value(settings_catboost_path, "blender")
		ProjectSettings.set_setting(settings_catboost_path, "blender")

	else:
		catboost_path = ProjectSettings.get_setting(settings_catboost_path)
	var property_info = {
		"name": settings_catboost_path,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": ""
	}
	ProjectSettings.add_property_info(property_info)

func _post_import(scene):
	catboost = load("res://addons/catboost/catboost.gd").new()
	catboost._write_import(scene, false)
#	var node_script = GDScript.new()
#	var code = """
#extends Resource
#
#@export var bones: Dictionary
#"""
#	node_script.source_code = code
#	scene.set_script(node_script)
	
	var stdout = [].duplicate()
	var addon_path : String = catboost_path
	var addon_path_global = ProjectSettings.globalize_path(addon_path)
	var os_script : String = ("catboost")
	var args = [
		"calc -m model.bin --column-description test_description.txt --output-columns \"LogProbability,BONE\" --input-path test.tsv  --output-path stream://stdout --has-header",
		os_script]
	print(args)
	var ret = OS.execute(addon_path_global, args, stdout, true)
	for line in stdout:
		print(line)
	if ret != 0:
		print("Catboost returned " + str(ret))
		return null
	
#	var bones : Dictionary
#	scene.bones = bones
	return scene




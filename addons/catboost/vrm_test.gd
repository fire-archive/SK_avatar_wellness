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

extends Skeleton3D

@export
var catboost_path : String = "catboost"

@export 
var bones : Dictionary
var neighbours : Array 

func _ready():
	var skeleton_neighbours_cache : Dictionary
	var catboost = load("res://addons/catboost/catboost.gd").new()
	neighbours = catboost.skeleton_neighbours(skeleton_neighbours_cache, self)[0]
	var write_path = "catboost/test.tsv"
	catboost._write_import(self, true, write_path)
	var stdout = [].duplicate()
	var ret = OS.execute("CMD.exe", ["/C", "catboost calc -m catboost/model.bin --column-description catboost/test_description.txt --output-columns BONE,LogProbability --input-path %s --output-path stream://stdout --has-header" % [write_path]], stdout)	
	var bones : Dictionary
	for elem_stdout in stdout:
		var line = elem_stdout.split("\n")
		var keys : PackedStringArray
		for i in line.size():
			var columns = line[i].split("\t")
			if i == 0:
				keys.resize(columns.size())
				for c in columns.size():					
					var key_name = columns[c]
					var split = key_name.split("=", true, 1)
					if split.size() == 1:
						keys[c] = split[0]
					else:
						keys[c] = split[1]
				continue
			var bone_name : String
			for c in columns.size():
				if c == 0:
					bone_name = columns[c]
					continue
				var column_name : String = keys[c]
				var bone : Array
				if bones.has(bone_name):
					bone = bones[bone_name]
				var value = columns[c].pad_decimals(1).to_float()
				var probability = value
				bone.push_back([probability, column_name])
				bones[bone_name] = bone
	var seen : PackedStringArray
	for bone in bones.keys():
		var values = bones[bone]
		values.sort_custom(sort_desc)
		values.resize(10)
		for value in values:
			var vrm_name = value[1]
			var improbability = value[0]
			if vrm_name == "VRM_BONE_NONE" and abs(improbability) <= 0.5:
				break
			elif vrm_name == bone:
				break
			elif seen.has(vrm_name):
				break
			elif seen.has(bone):
				break
			elif not catboost.vrm_humanoid_bones.has(vrm_name):
				continue
			print("%s: raw score %s guessed %s" % [bone, improbability, vrm_name])
			seen.push_back(vrm_name)
			seen.push_back(bone)
	if ret != 0:
		print("Catboost returned " + str(ret))
		return null

func sort_desc(a, b):
	if (neighbours.find(a[0]) > neighbours.find(b[0])) or a[0] > b[0]:
		return true
	return false

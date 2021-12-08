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

const vrm_humanoid_bones = ["hips","leftUpperLeg","rightUpperLeg","leftLowerLeg","rightLowerLeg","leftFoot","rightFoot",
 "spine","chest","neck","head","leftUpperArm","rightUpperArm",
 "leftLowerArm","rightLowerArm","leftHand","rightHand"]

const vrm_humanoid_bone_extras = ["leftShoulder","rightShoulder", "leftToes","rightToes","leftEye","rightEye",
 "leftThumbProximal","leftThumbIntermediate","leftThumbDistal",
 "leftIndexProximal","leftIndexIntermediate","leftIndexDistal",
 "leftMiddleProximal","leftMiddleIntermediate","leftMiddleDistal",
 "leftRingProximal","leftRingIntermediate","leftRingDistal",
 "leftLittleProximal","leftLittleIntermediate","leftLittleDistal",
 "rightThumbProximal","rightThumbIntermediate","rightThumbDistal",
 "rightIndexProximal","rightIndexIntermediate","rightIndexDistal",
 "rightMiddleProximal","rightMiddleIntermediate","rightMiddleDistal",
 "rightRingProximal","rightRingIntermediate","rightRingDistal",
 "rightLittleProximal","rightLittleIntermediate","rightLittleDistal", "upperChest", "jaw"]

func _ready():
	var catboost = load("res://addons/catboost/catboost.gd").new()
	var scene_path = owner.scene_file_path
	var write_path_global = ProjectSettings.globalize_path("user://catboost_import" + "-" + scene_path.md5_text() + ".tsv")
	var description_path_global = ProjectSettings.globalize_path("res://addons/catboost/model/train_description.txt")
	var model_global = ProjectSettings.globalize_path("res://addons/catboost/model/vrm_model_2021-11-26.bin")
	var catboost_global =  ProjectSettings.globalize_path("catboost")
	catboost._write_import(self, true, write_path_global)
	var stdout = [].duplicate()
	var args = [catboost_global, model_global, description_path_global, write_path_global]
	var replaced_args = ["/C %s calc --model-file \"%s\" --column-description \"%s\" --output-columns BONE,LogProbability --input-path \"%s\" --output-path stream://stdout --has-header" % args]
	print(replaced_args)
	var ret = OS.execute("CMD.exe", replaced_args, stdout)	
	var bones : Dictionary
	for elem_stdout in stdout:
		var line : PackedStringArray = elem_stdout.split("\n")
		var keys : PackedStringArray
		var columns_first = line[0].split("\t")
		keys.resize(columns_first.size())
		for c in columns_first.size():					
			var key_name = columns_first[c]
			var split = key_name.split("=", true, 1)
			if split.size() == 1:
				keys[c] = split[0]
			else:
				keys[c] = split[1]
		line.remove_at(0)
		line.reverse()
		for i in line.size():
			var columns = line[i].split("\t")
			var bone_name : String
			for c in columns.size():
				if c == 0:
					bone_name = columns[c]
					continue
				var column_name : String = keys[c]
				var bone : Array
				if bones.has(column_name):
					bone = bones[column_name]
				var value = columns[c].pad_decimals(1).to_float()
				var probability = value
				bone.push_back([probability, bone_name])
				bones[column_name] = bone
	var seen : PackedStringArray
	var results : Dictionary
	catboost.find_neighbor_joint
	print("## Results.")
	var count = 0
	var abs_log_probability_of_bone = abs(log(1.0 / catboost.vrm_humanoid_bones.size())) / 2.0
	for tolerance in range(0, 40):
		for vrm_bone in vrm_humanoid_bones:
			for bone_name in bones.keys():
				if not bones.has(bone_name):
					continue
				var values = bones[bone_name]
				for value in values:
					var vrm_name = value[1]
					var probability = value[0]
					var improbability = abs(value[0])
					if vrm_name == bone_name:
						break
					elif seen.has(bone_name) or seen.has(vrm_name):
						continue
					elif bone_name != vrm_bone:
						continue
					elif improbability >= (tolerance * 0.1):
						continue
					elif improbability >= abs_log_probability_of_bone:
						break
					results[bone_name] = [vrm_name, probability]
					print([bone_name, vrm_name, probability])
					seen.push_back(vrm_name)
					seen.push_back(bone_name)
					count += 1
				for s in seen:
					bones.erase(s)
	print("## Improbable results.")
	for tolerance in range(0, 100):
		for vrm_bone in vrm_humanoid_bone_extras:
			for bone_name in bones.keys():
				var values = bones[bone_name]
				for value in values:
					var vrm_name = value[1]
					var probability = value[0]
					var improbability = abs(value[0])
					if vrm_name == bone_name:
						break
					elif seen.has(bone_name) or seen.has(vrm_name):
						continue
					elif vrm_bone != bone_name:
						continue
					elif improbability >= (tolerance * 0.1):
						continue
					if improbability <= abs_log_probability_of_bone:
						results[bone_name] = [vrm_name, probability]
					print([bone_name, vrm_name, probability])
					seen.push_back(vrm_name)
					seen.push_back(bone_name)
					count += 1
				for s in seen:
					bones.erase(s)
	print("Returned results " + str(count))
	if ret != 0:
		print("Catboost returned " + str(ret))
		return null

func sort_desc(a, b):
	if a[0] > b[0]:
		return true
	return false

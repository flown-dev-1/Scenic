@icon("res://addons/scenic/icons/layers.svg")
class_name SceneManager extends Node

#region constants
const SCENE_INSTANTIATED_INFO: String = 		"[Scenic] %s instantiated"
const SCENE_FREED_INFO: String = 				"[Scenic] %s freed"
const FORCE_UNLOAD_NOT_LOADED_WARNING = 		"[Scenic] Attempted to force unload %s when it was not loaded"
const INVALID_TIME_SCALE_ERROR: String = 		"[Scenic] Invalid time scale %s. Setting time scale to 1.0"

#region exports
@export var global: bool = true
@export var _scenes: Dictionary = {} #{<scene_name>: <scene_info>}

#region references
var _scene_parent: Node = null
var _active_scenes: Dictionary = {} #{<scene_name>: <scene>}
var _transitions: Dictionary = {}

#region state
var _force_loaded: Dictionary = {} #{<scene_name>: <async_scene>}
var _loaded_scenes_count: int = 0
var _active_scenes_count: int = 0

#region node_events
func _ready() -> void:
	_create_scene_parent()
	
	if global:
		GlobalSceneManager._register_scene_manager(self)

func _exit_tree() -> void:
	if global:
		GlobalSceneManager._unregister_scene_manager(self)

#region public_functions
func force_load(scene_name: StringName) -> void:
	if _force_loaded.has(scene_name):
		return
	
	var scene_uid = get_scene_info(scene_name).uid
	var async_scene = SceneLoader.subscribe_scene(scene_uid)
	
	_force_loaded.set(scene_name, async_scene)

func force_unload(scene_name: StringName) -> void:
	if !_force_loaded.has(scene_name):
		push_warning(FORCE_UNLOAD_NOT_LOADED_WARNING)
		return
	
	var async_scene = _force_loaded.get(scene_name)
	SceneLoader.unsubscribe_scene(async_scene.uid)
	
	_force_loaded.erase(scene_name)

func register_transition(transition: SceneTransition) -> void:
	_transitions.set(transition.name, transition)

func unregister_transition(transition: SceneTransition) -> void:
	_transitions.erase(transition.name)

func queue() -> SceneQueue:
	var queue = SceneQueue.new(self)
	return queue

func add(scene_name: StringName, data: Variant = null) -> SceneQueue:
	return queue().add(scene_name, data)

func adds(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	return queue().adds(scene_names, datas)

func reload(scene_name: StringName, data: Variant = null) -> SceneQueue:
	return queue().reload(scene_name, data)

func reloads(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	return queue().reloads(scene_names, datas)

func remove(scene_name: StringName) -> SceneQueue:
	return queue().remove(scene_name)

func removes(scene_names: Array[StringName]) -> SceneQueue:
	return queue().removes(scene_names)

func remove_all(exclude_tags: Array[StringName] = []) -> SceneQueue:
	return queue().remove_all(exclude_tags)

func switch(scene_name: StringName, data: Variant = null, exclude_tags: Array[StringName] = []) -> SceneQueue:
	return queue().switch(scene_name, data, exclude_tags)

func switches(scene_names: Array[StringName], datas: Array[Variant] = [], exclude_tags: Array[StringName] = []) -> SceneQueue:
	return queue().switches(scene_names, datas, exclude_tags)

func with_transition(in_transition: StringName, in_time_scale: float = 1.0, out_transition: StringName = &"", out_time_scale: float = -1.0) -> SceneQueue:
	return queue().with_transition(in_transition, in_time_scale, out_transition, out_time_scale)

func with_transition_callback(callback: Callable, in_transition: StringName, in_time_scale: float = 1.0, out_transition: StringName = &"", out_time_scale: float = -1.0) -> SceneQueue:
	return queue().with_transition_callback(callback, in_transition, in_time_scale, out_transition, out_time_scale)

func get_scene_info(scene_name: StringName) -> SceneInfo:
	return _scenes.get(scene_name)

#region internal_functions
func _add_scene(scene_name: StringName, scene_scene: PackedScene, data: Variant) -> void:
	var scene = scene_scene.instantiate()
	scene.name = scene_name
	_scene_parent.add_child(scene)
	scene._start(data)
	
	_active_scenes.set(scene_name, scene)
	_active_scenes_count += 1

func _reload_scene(scene_name: StringName, data: Variant) -> void:
	var old_scene = _active_scenes.get(scene_name)
	_scene_parent.remove_child(old_scene)
	
	var new_scene = old_scene.duplicate()
	_scene_parent.add_child(new_scene)
	new_scene._start(data)
	
	_active_scenes.set(scene_name, new_scene)
	
	old_scene.queue_free()

func _remove_scene(scene_name: StringName) -> void:
	var scene = _active_scenes.get(scene_name)
	_scene_parent.remove_child(scene)
	scene.queue_free()
	
	_active_scenes.erase(scene_name)
	_active_scenes_count -= 1

func _remove_all_scenes(exclude_tags: Array[StringName]) -> void:
	for scene_name in _active_scenes.keys():
		var scene = _active_scenes.get(scene_name)
		
		var has_tag = false
		for exclude_tag in exclude_tags:
			if scene.has_tag(exclude_tag):
				has_tag = true
				break
		
		if has_tag:
			continue
		
		_remove_scene(scene_name)

func _run_transition_for_queue(queue: SceneQueue) -> void:
	var in_transition = _get_transition_by_name(queue.in_transition)
	var out_transition = _get_transition_by_name(queue.out_transition)
	
	await in_transition.transition_in(queue.in_time_scale)
	
	await queue._run_actions()
	
	if in_transition != out_transition:
		out_transition.set_in()
		in_transition.set_out()
	
	await out_transition.transition_out(queue.out_time_scale)

func _get_loaded_scenes_count() -> int:
	return _loaded_scenes_count

func _get_active_scenes_count() -> int:
	return _active_scenes_count

#region private_functions
func _create_scene_parent() -> void:
	_scene_parent = Node.new()
	_scene_parent.name = &"SceneParent"
	add_child(_scene_parent)

func _get_transition_by_name(transition_name: StringName) -> SceneTransition:
	return _transitions.get(transition_name)

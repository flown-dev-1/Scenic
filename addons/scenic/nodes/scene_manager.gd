@icon("res://addons/scenic/icons/layers.svg")
class_name SceneManager extends Node

#region constants
const SETUP_INFO: String = 				"[Scenic] Setting up initial state"
const SCENE_INSTANTIATED_INFO: String = "[Scenic] %s added"
const SCENE_FREED_INFO: String = 		"[Scenic] %s removed"
const FORCE_LOAD_INFO: String = 		"[Scenic] Force loaded %s"
const FORCE_UNLOAD_INFO: String = 		"[Scenic] Force unloaded %s"
const FORCE_UNLOAD_NOT_LOADED_WARNING = "[Scenic] Attempted to force unload %s when it was not loaded"

#region exports
@export var global: bool = true
@export var _scenes: Dictionary[StringName, SceneInfo] = {} #{<scene_name>: <scene_info>}

#region references
var _scene_parent: Node = null
var _active_scenes: Dictionary[StringName, LoadedSceneRefs] = {} #{<scene_name>: <scene>}
var _transitions: Dictionary[StringName, SceneTransition] = {} #{<transition_name>: <transition>}

#region state
var _force_loaded: Dictionary[StringName, AsyncPackedSceneHandle] = {} #{<scene_name>: <async_scene_handle>}

#region node_events
func _ready() -> void:
	_create_scene_parent()
	
	if global:
		GlobalSceneManager._register_scene_manager(self)
	
	print(SETUP_INFO)
	
	_add_global_scenes()
	_add_initial_scenes()

func _exit_tree() -> void:
	if global:
		GlobalSceneManager._unregister_scene_manager(self)

#region public_functions
func force_load(scene_name: StringName) -> void:
	if _force_loaded.has(scene_name):
		return
	
	print_verbose(FORCE_LOAD_INFO % scene_name)
	
	var scene_uid: int = get_scene_info(scene_name).uid
	var async_scene_handle: AsyncPackedSceneHandle = SceneLoader.get_async_scene(scene_uid)
	
	_force_loaded.set(scene_name, async_scene_handle)

func force_unload(scene_name: StringName) -> void:
	if !_force_loaded.has(scene_name):
		push_warning(FORCE_UNLOAD_NOT_LOADED_WARNING)
		return
	
	print_verbose(FORCE_UNLOAD_INFO % scene_name)
	
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

func is_active(scene_name: StringName) -> bool:
	return _active_scenes.has(scene_name)

#region internal_functions
func _add_scene(scene_name: StringName, async_scene_handle: AsyncPackedSceneHandle, data: Variant) -> void:
	var scene_scene = await async_scene_handle.async_scene.get_scene_async()
	var scene = scene_scene.instantiate()
	scene.name = scene_name
	
	print(SCENE_INSTANTIATED_INFO % scene_name)
	
	_scene_parent.add_child(scene)
	scene._start(data)
	
	var loaded_scene_refs = LoadedSceneRefs.new(scene, async_scene_handle)
	
	_active_scenes.set(scene_name, loaded_scene_refs)

func _reload_scene(scene_name: StringName, data: Variant) -> void:
	var loaded_scene_refs: LoadedSceneRefs = _active_scenes.get(scene_name)
	var old_scene := loaded_scene_refs.node
	_scene_parent.remove_child(old_scene)
	old_scene.queue_free()
	
	print(SCENE_FREED_INFO % scene_name)
	
	var scene_scene := await loaded_scene_refs.async_scene_handle.async_scene.get_scene_async()
	var new_scene := scene_scene.instantiate()
	new_scene.name = scene_name
	
	print(SCENE_INSTANTIATED_INFO % scene_name)
	
	_scene_parent.add_child(new_scene)
	new_scene._start(data)
	
	loaded_scene_refs.node = new_scene

func _remove_scene(scene_name: StringName) -> void:
	var loaded_scene_refs: LoadedSceneRefs = _active_scenes.get(scene_name)
	var scene := loaded_scene_refs.node
	_scene_parent.remove_child(scene)
	scene.queue_free()
	
	print(SCENE_FREED_INFO % scene_name)
	
	_active_scenes.erase(scene_name)

func _remove_all_scenes(exclude_tags: Array[StringName]) -> void:
	for scene_name in _active_scenes.keys():
		var loaded_scene_refs: LoadedSceneRefs = _active_scenes.get(scene_name)
		var scene := loaded_scene_refs.node
		
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
	
	if in_transition != null:
		await in_transition.transition_in(queue.in_time_scale)
	
	await queue._run_actions()
	
	if queue.scene_transition_callback.is_valid():
		queue.scene_transition_callback.call()
	
	if in_transition != null && in_transition != out_transition:
		if out_transition != null:
			out_transition.set_in()
		in_transition.set_out()
	
	if out_transition != null:
		await out_transition.transition_out(queue.out_time_scale)

func _get_active_scenes_count() -> int:
	return _active_scenes.size()

#region private_functions
func _create_scene_parent() -> void:
	_scene_parent = Node.new()
	_scene_parent.name = &"SceneParent"
	add_child(_scene_parent)

func _add_global_scenes() -> void:
	for scene_name in _scenes:
		var scene_info = get_scene_info(scene_name)
		
		if scene_info.global:
			force_load(scene_name)

func _add_initial_scenes() -> void:
	var initial_scenes: Dictionary[StringName, AsyncPackedSceneHandle] = {}
	
	for scene_name in _scenes:
		var scene_info := get_scene_info(scene_name)
		
		if scene_info.initial:
			initial_scenes.set(scene_name, SceneLoader.get_async_scene(scene_info.uid))
	
	for scene_name in initial_scenes:
		var async_scene_handle: AsyncPackedSceneHandle = initial_scenes.get(scene_name)
		_add_scene(scene_name, async_scene_handle, null)

func _get_transition_by_name(transition_name: StringName) -> SceneTransition:
	return _transitions.get(transition_name)

#region classes
class LoadedSceneRefs:
	var node: Node = null
	var async_scene_handle: AsyncPackedSceneHandle = null
	
	func _init(_node: Node, _async_scene_handle: AsyncPackedSceneHandle) -> void:
		node = _node
		async_scene_handle = _async_scene_handle

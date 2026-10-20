extends Node

#region constants
const NO_GLOBAL_MANAGER_ERROR: String = "[Scenic] Attempting to perform a global scene operation with no global scene manager"
const RE_REGISTER_SCENE_ERROR: String = "[Scenic] Multiple global scene managers defined. Undefined behaviour."

#region references
var _target_scene_manager: SceneManager = null

#region node_events
func _enter_tree() -> void:
	Performance.add_custom_monitor("global_scene_manager/scenes_active", _get_active_scenes_count)

func _exit_tree() -> void:
	Performance.remove_custom_monitor("global_scene_manager/scenes_active")

#region public_functions
func force_load(scene_name: StringName) -> void:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return
	
	_target_scene_manager.force_load(scene_name)

func force_unload(scene_name: StringName) -> void:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return
	
	_target_scene_manager.force_unload(scene_name)

func queue() -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.queue()

func add(scene_name: StringName, data: Variant = null) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.add(scene_name, data)

func adds(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.adds(scene_names, datas)

func reload(scene_name: StringName, data: Variant = null) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.reload(scene_name, data)

func reloads(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.reloads(scene_names, datas)

func remove(scene_name: StringName) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.remove(scene_name)

func removes(scene_names: Array[StringName]) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.removes(scene_names)

func remove_all(exclude_tags: Array[StringName] = []) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.remove_all(exclude_tags)

func switch(scene_name: StringName, data: Variant = null, exclude_tags: Array[StringName] = []) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.switch(scene_name, data, exclude_tags)

func switches(scene_names: Array[StringName], datas: Array[Variant] = [], exclude_tags: Array[StringName] = []) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return switches(scene_names, datas, exclude_tags)

func with_transition(in_transition: StringName, in_time_scale: float = 1.0, out_transition: StringName = &"", out_time_scale: float = -1.0) -> SceneQueue:
	if _target_scene_manager == null:
		push_error(NO_GLOBAL_MANAGER_ERROR)
		return null
	
	return _target_scene_manager.with_transition(in_transition, in_time_scale, out_transition, out_time_scale)

#region internal_functions
func _register_scene_manager(scene_manager: SceneManager) -> void:
	if _target_scene_manager != null:
		push_warning(RE_REGISTER_SCENE_ERROR)
		return
	
	_target_scene_manager = scene_manager

func _unregister_scene_manager(scene_manager: SceneManager) -> void:
	if _target_scene_manager != scene_manager:
		return
	
	_target_scene_manager = null

#region private_functions
func _get_loaded_scenes_count() -> int:
	return 0 if _target_scene_manager == null else _target_scene_manager._get_loaded_scenes_count()

func _get_active_scenes_count() -> int:
	return 0 if _target_scene_manager == null else _target_scene_manager._get_active_scenes_count()

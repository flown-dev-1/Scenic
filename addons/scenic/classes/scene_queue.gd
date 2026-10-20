class_name SceneQueue extends RefCounted

#region constants
const SCENE_ADD_QUEUED_INFO: String = 						"[Scenic] %s queued for creation"
const SCENE_RELOAD_QUEUED_INFO: String = 					"[Scenic] %s queued for reloading"
const SCENE_REMOVE_QUEUED_INFO: String = 					"[Scenic] %s queued for deletion"
const SCENE_REMOVE_ALL_QUEUED_INFO: String = 				"[Scenic] All scenes queued for deletion"
const SCENE_REMOVE_ALL_QUEUED_EXCLUDE_TAGS_INFO: String = 	"[Scenic] All scenes not tagged with %s queued for deletion"

#region identity
var _scene_manager: SceneManager = null

#region state
var _action_queue: Array[Action] = []
var in_transition: StringName = &""
var in_time_scale: float = 1.0
var out_transition: StringName = &""
var out_time_scale: float = 1.0
var scene_transition_callback: Callable = Callable()

#region node_events
func _init(scene_manager: SceneManager) -> void:
	_scene_manager = scene_manager

#region public_functions
func add(scene_name: StringName, data: Variant = null) -> SceneQueue:
	print_verbose(SCENE_ADD_QUEUED_INFO % scene_name)
	
	var add_action = AddAction.new(_scene_manager, scene_name, data)
	_action_queue.push_back(add_action)
	
	return self

func adds(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	for i in range(scene_names.size()):
		var scene_name = scene_names[i]
		var data = datas[i] if i < datas.size() else null
		
		add(scene_name, data)
	
	return self

func reload(scene_name: StringName, data: Variant = null) -> SceneQueue:
	print_verbose(SCENE_RELOAD_QUEUED_INFO % scene_name)
	
	var reload_action = ReloadAction.new(scene_name, data)
	_action_queue.push_back(reload_action)
	
	return self

func reloads(scene_names: Array[StringName], datas: Array[Variant] = []) -> SceneQueue:
	for i in range(scene_names.size()):
		var scene_name = scene_names[i]
		var data = datas[i] if i < datas.size() else null
		
		reload(scene_name, data)
	
	return self

func remove(scene_name: StringName) -> SceneQueue:
	print_verbose(SCENE_REMOVE_QUEUED_INFO % scene_name)
	
	var remove_action = RemoveAction.new(scene_name)
	_action_queue.push_back(remove_action)
	
	return self

func removes(scene_names: Array[StringName]) -> SceneQueue:
	for i in range(scene_names.size()):
		var scene_name = scene_names[i]
		
		remove(scene_name)
	
	return self

func remove_all(exclude_tags: Array[StringName] = []) -> SceneQueue:
	if exclude_tags.size() == 0:
		print_verbose(SCENE_REMOVE_ALL_QUEUED_INFO)
	else:
		print_verbose(SCENE_REMOVE_ALL_QUEUED_EXCLUDE_TAGS_INFO % exclude_tags)
	
	var remove_all_action = RemoveAllAction.new(exclude_tags)
	_action_queue.push_back(remove_all_action)
	
	return self

func switch(scene_name: StringName, data: Variant = null, exclude_tags: Array[StringName] = []) -> SceneQueue:
	remove_all(exclude_tags)
	add(scene_name, data)
	
	return self

func switches(scene_names: Array[StringName], datas: Array[Variant] = [], exclude_tags: Array[StringName] = []) -> SceneQueue:
	remove_all(exclude_tags)
	adds(scene_names, datas)
	
	return self

func with_transition(_in_transition: StringName, _in_time_scale: float = 1.0, _out_transition: StringName = &"", _out_time_scale: float = -1.0) -> SceneQueue:
	in_transition = _in_transition
	in_time_scale = _in_time_scale
	
	out_transition = _out_transition if _out_transition != &"" else in_transition
	out_time_scale = _out_time_scale if _out_time_scale > 0.0 else in_time_scale
	
	return self

func with_transition_callback(callback: Callable, _in_transition: StringName, _in_time_scale: float = 1.0, _out_transition: StringName = &"", _out_time_scale: float = -1.0) -> SceneQueue:
	with_transition(_in_transition, _in_time_scale, _out_transition, _out_time_scale)
	
	scene_transition_callback = callback
	
	return self

func transition(_in_transition: StringName = &"", _in_time_scale: float = -1.0, _out_transition: StringName = &"", _out_time_scale: float = -1.0) -> void:
	if _in_transition != &"":
		in_transition = _in_transition
	
	if _in_time_scale > 0.0:
		in_time_scale = _in_time_scale
	
	if _out_transition != &"":
		out_transition = _out_transition
	elif _in_transition != &"":
		out_transition = _in_transition
	
	if _out_time_scale > 0.0:
		out_time_scale = _out_time_scale
	elif _in_time_scale > 0.0:
		out_time_scale = _in_time_scale
	
	_scene_manager._run_transition_for_queue(self)

func transition_callback(callback: Callable, _in_transition: StringName = &"", _in_time_scale: float = -1.0, _out_transition: StringName = &"", _out_time_scale: float = -1.0) -> void:
	scene_transition_callback = callback
	
	transition(_in_transition, _in_time_scale, _out_transition, _out_time_scale)

#region internal_functions
func _run_actions() -> void:
	for action in _action_queue:
		await action.run(_scene_manager)

#region classes
@abstract class Action extends RefCounted:
	@abstract func run(scene_manager: SceneManager) -> void

class AddAction extends Action:
	var _scene_name: StringName
	var _async_scene_handle: AsyncPackedSceneHandle
	var _data: Variant
	
	func _init(scene_manager: SceneManager, scene_name: StringName, data: Variant = null) -> void:
		_scene_name = scene_name
		_async_scene_handle = SceneLoader.get_async_scene(scene_manager.get_scene_info(_scene_name).uid)
		_data = data
	
	func run(scene_manager: SceneManager) -> void:
		if scene_manager.is_active(_scene_name):
			return
		
		scene_manager._add_scene(_scene_name, _async_scene_handle, _data)

class ReloadAction extends Action:
	var _scene_name: StringName
	var _data: Variant
	
	func _init(scene_name: StringName, data: Variant = null) -> void:
		_scene_name = scene_name
		_data = data
	
	func run(scene_manager: SceneManager) -> void:
		if !scene_manager.is_active(_scene_name):
			return
		
		scene_manager._reload_scene(_scene_name, _data)

class RemoveAction extends Action:
	var _scene_name: StringName
	
	func _init(scene_name: StringName) -> void:
		_scene_name = scene_name
	
	func run(scene_manager: SceneManager) -> void:
		if !scene_manager.is_active(_scene_name):
			return
		
		scene_manager._remove_scene(_scene_name)

class RemoveAllAction extends Action:
	var _exclude_tags: Array[StringName]
	
	func _init(exclude_tags: Array[StringName]) -> void:
		_exclude_tags = exclude_tags
	
	func run(scene_manager: SceneManager) -> void:
		scene_manager._remove_all_scenes(_exclude_tags)

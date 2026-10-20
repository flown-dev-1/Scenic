extends Node

#region state
var _scenes: Dictionary[int, AsyncPackedSceneRefs] = {} #{<uid>: <async_scene_refs>}

#region node_events
func _enter_tree() -> void:
	Performance.add_custom_monitor("global_scene_manager/scenes_loaded", _get_loaded_scenes_count)

func _exit_tree() -> void:
	Performance.remove_custom_monitor("global_scene_manager/scenes_loaded")
	
	# Must free scenes here otherwise they free when this object is being
	# destructed, causing errors.
	_scenes.clear()

func _process(_delta: float) -> void:
	_poll_loading_progress()

#region public_functions
func get_async_scene(scene_uid: int) -> AsyncPackedSceneHandle:
	if _scenes.has(scene_uid):
		var async_scene_refs: AsyncPackedSceneRefs = _scenes.get(scene_uid)
		
		# Make sure it is not about to unload.
		async_scene_refs.async_scene.queue_load()
		
		return async_scene_refs.get_or_create_handle()
	else:
		var async_scene: AsyncPackedScene = AsyncPackedScene.new(scene_uid)
		async_scene.queue_load()
		
		var async_scene_refs: AsyncPackedSceneRefs = AsyncPackedSceneRefs.new(async_scene)
		
		_scenes.set(scene_uid, async_scene_refs)
		
		return async_scene_refs.get_or_create_handle()

#region internal_functions
func _async_scene_handle_freed(scene_uid: int) -> void:
	if !_scenes.has(scene_uid):
		return
	
	var async_scene_refs: AsyncPackedSceneRefs = _scenes.get(scene_uid)
	async_scene_refs.async_scene.queue_unload()

func _get_loaded_scenes_count() -> int:
	return _scenes.size()

#region private_functions
func _poll_loading_progress() -> void:
	for scene_uid in _scenes.keys():
		var async_scene_refs: AsyncPackedSceneRefs = _scenes.get(scene_uid)
		var async_scene: AsyncPackedScene = async_scene_refs.async_scene
		
		async_scene.poll_loading_progress()
		
		if async_scene.get_state() == AsyncPackedScene.SceneLoadingState.CANCELED:
			_scenes.erase(scene_uid)

#region classes
class AsyncPackedSceneRefs:
	var async_scene: AsyncPackedScene = null
	var _async_scene_handle: WeakRef = null
	
	func _init(_async_scene: AsyncPackedScene) -> void:
		async_scene = _async_scene
	
	func get_or_create_handle() -> AsyncPackedSceneHandle:
		if _async_scene_handle == null || _async_scene_handle.get_ref() == null:
			var new_async_scene_handle: AsyncPackedSceneHandle = AsyncPackedSceneHandle.new(async_scene)
			_async_scene_handle = weakref(new_async_scene_handle)
			return new_async_scene_handle
		else:
			return _async_scene_handle.get_ref()

extends Node

#region constants
const INVALID_UNSUBSCRIBE_SCENE_WARNING: String = "[Scenic] Tried to unsubscribe from a scene that had not been subscribed to"

#region state
var _scenes: Dictionary = {} #{<uid>: <async_scene>}

#region node_events
func _process(_delta: float) -> void:
	_poll_loading_progress()

#region public_functions
func subscribe_scene(scene_uid: int) -> AsyncPackedScene:
	if _scenes.has(scene_uid):
		var async_scene = _scenes.get(scene_uid)
		async_scene.ref_count += 1
		
		return async_scene
	else:
		var async_scene = AsyncPackedScene.new(scene_uid)
		async_scene.ref_count = 1
		async_scene.queue_load()
		
		_scenes.set(scene_uid, async_scene)
		
		return async_scene

func unsubscribe_scene(scene_uid: int) -> void:
	if !_scenes.has(scene_uid):
		push_warning(INVALID_UNSUBSCRIBE_SCENE_WARNING)
		return
	
	var async_scene = _scenes.get(scene_uid)
	async_scene.ref_count -= 1
	
	if async_scene.ref_count <= 0:
		async_scene.queue_unload()

#region private_functions
func _poll_loading_progress() -> void:
	for scene_uid in _scenes.keys():
		var async_scene = _scenes.get(scene_uid)
		
		async_scene.poll_loading_progress()
		
		if async_scene.get_state() == AsyncPackedScene.SceneLoadingState.CANCELED:
			_scenes.erase(scene_uid)

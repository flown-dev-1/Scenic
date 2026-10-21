class_name AsyncPackedSceneHandle extends RefCounted

#region identity
var _async_scene: AsyncPackedScene = null

#region node_events
func _init(async_scene: AsyncPackedScene) -> void:
	_async_scene = async_scene

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		SceneLoader._async_scene_handle_freed(_async_scene.uid)

#region public_functions
func queue_load() -> void:
	_async_scene.queue_load()

func queue_unload() -> void:
	_async_scene.queue_unload()

func poll_loading_progress() -> void:
	_async_scene.poll_loading_progress()

func get_scene_async() -> PackedScene:
	return await _async_scene.get_scene_async()

func get_state() -> AsyncPackedScene.SceneLoadingState:
	return _async_scene.get_state()

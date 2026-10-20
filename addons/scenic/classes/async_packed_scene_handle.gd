class_name AsyncPackedSceneHandle extends RefCounted

#region identity
var async_scene: AsyncPackedScene = null

#region node_events
func _init(_async_scene: AsyncPackedScene) -> void:
	async_scene = _async_scene

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		SceneLoader._async_scene_handle_freed(async_scene.uid)

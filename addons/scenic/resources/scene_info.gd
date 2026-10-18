class_name SceneInfo extends Resource

#region exports
@export var uid: int
@export var initial: bool = false
@export var global: bool = false

#region node_events
func _init(_uid: int) -> void:
	uid = _uid

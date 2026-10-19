@icon("res://addons/scenic/icons/clapperboard.svg")
class_name Scene extends Node

#region exports
# Used to set tags in the inspector, _internal_tags should be used at runtime
@export var _tags: Array[StringName] = []

#region identity
var _internal_tags: Dictionary = {} #{<tag>: null}

#region references
var scene_manager: SceneManager = null

#region node_events
func _start(data: Variant) -> void:
	pass

func _enter_tree() -> void:
	_create_internal_tags()

#region public_functions
func add_tag(tag: StringName) -> void:
	_internal_tags.set(tag, null)

func remove_tag(tag: StringName) -> void:
	_internal_tags.erase(tag)

func has_tag(tag: StringName) -> bool:
	return _internal_tags.has(tag)

func get_tags() -> Array[StringName]:
	return _internal_tags.keys()

#region private_functions
func _create_internal_tags() -> void:
	for tag in _tags:
		_internal_tags.set(tag, null)

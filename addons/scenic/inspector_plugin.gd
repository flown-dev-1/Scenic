@tool
extends EditorInspectorPlugin

#region references
var _scenes_inspector = preload("res://addons/scenic/inspectors/scenes_inspector.gd")

#region node_events
func _can_handle(object: Object) -> bool:
	return object is SceneManager

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	match name:
		"_scenes":
			var scenes: Dictionary[StringName, SceneInfo] = object._scenes
			add_property_editor(name, _scenes_inspector.new(scenes))
			return true
		_:
			return false

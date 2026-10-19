@tool
extends EditorProperty

#region constants
var DUPLICATE_NAME_INDEX_REGEX: RegEx = RegEx.create_from_string("_(\\d+)$")

const NAME_DESYNC_ERROR: String = "[Scenic] Desync between name key and name found (name key: %s, name: %s)"

#region references
var _droppable_tree = preload("res://addons/scenic/inspectors/droppable_tree.gd")
var _editor_theme: Theme = null
var _tree: Tree = null

#region state
var _scenes: Dictionary
var _updating: bool = false
var _previous_selected: TreeItem = null
var _item_just_added: StringName = &""

#region node_events
func _init(scenes: Dictionary) -> void:
	if _editor_theme == null:
		_editor_theme = EditorInterface.get_editor_theme()
	
	_tree = _droppable_tree.new()
	_tree.columns = 2
	_tree.custom_minimum_size = Vector2(0.0, 300.0)
	_tree.hide_root = true
	_tree.hide_folding = true
	_tree.scroll_horizontal_enabled = false
	_tree.scroll_vertical_enabled = false
	_tree.button_clicked.connect(_on_button_clicked)
	_tree.item_edited.connect(_on_item_edited)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	_tree.dropped_file.connect(_on_dropped_file)
	add_child(_tree)
	set_bottom_editor(_tree)
	
	_scenes = scenes
	_update_list()

func _update_property() -> void:
	var new_scenes = get_edited_object()[get_edited_property()]
	
	_updating = true
	_scenes = new_scenes
	_update_list()
	_updating = false

#region callbacks
func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button: int) -> void:
	if _updating:
		return
	
	var new_scenes = _scenes.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
	var clicked_scene_name = item.get_text(0)
	
	for scene_name in new_scenes.keys():
		if scene_name != clicked_scene_name:
			continue
		
		var scene_info = new_scenes.get(scene_name)
		
		match id:
			0:
				scene_info.initial = !scene_info.initial
			1:
				scene_info.global = !scene_info.global
			2:
				new_scenes.erase(scene_name)
		
		break
	
	emit_changed(get_edited_property(), new_scenes)

func _on_item_edited() -> void:
	var item = _tree.get_edited()
	var column = _tree.get_edited_column()
	
	var new_name = item.get_text(0)
	var old_name = item.get_metadata(0)
	
	if _updating:
		item.set_text(0, old_name)
		return
	
	if new_name == old_name:
		return
	
	var new_scenes = _scenes.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
	var scene_info = new_scenes.get(old_name)
	
	match column:
		0:
			new_scenes.erase(old_name)
			new_name = _find_valid_name(new_name, old_name)
			new_scenes.set(new_name, scene_info)
		1:
			scene_info.path = item.get_text(1)
	
	item.set_editable(0, false)
	
	emit_changed(get_edited_property(), new_scenes)

func _on_item_selected() -> void:
	var item = _tree.get_selected()
	var column = _tree.get_selected_column()
	
	match column:
		0:
			if _previous_selected != null:
				item.set_editable(0, false)
			
			await get_tree().process_frame
			item.set_editable(0, true)
	
	_previous_selected = item

func _on_item_activated() -> void:
	var item = _tree.get_selected()
	var column = _tree.get_selected_column()
	
	var scene_info = _scenes.get(item.get_metadata(0))
	
	match column:
		1:
			EditorInterface.select_file(scene_info.get_path())

func _on_dropped_file(path: String) -> void:
	var uid = ResourceLoader.get_resource_uid(path)
	var existing_scene_name = _get_scene_name_from_uid(uid)
	
	if existing_scene_name == &"":
		var name = _find_valid_name(path.get_file().get_basename().capitalize())
		
		var new_scenes = _scenes.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
		var new_scene_info = SceneInfo.new(uid)
		new_scenes.set(name, new_scene_info)
		
		_item_just_added = name
		emit_changed(get_edited_property(), new_scenes)
	else:
		_item_just_added = existing_scene_name
		_update_list()

#region private_functions
func _update_list() -> void:
	_tree.clear()
	
	var new_item = null
	var root = _tree.create_item()
	var scene_names = _scenes.keys()
	scene_names.sort_custom(func (a: StringName, b: StringName):
		return String(a) < String(b)
	)
	for scene_name in scene_names:
		var scene_info = _scenes.get(scene_name)
		
		var item = _tree.create_item(root)
		item.set_metadata(0, scene_name)
		item.set_text(0, scene_name)
		item.set_text(1, ResourceUID.get_id_path(scene_info.uid))
		item.set_icon(1, _editor_theme.get_icon("PackedScene", "EditorIcons"))
		item.add_button(1, _editor_theme.get_icon("AutoPlay", "EditorIcons"), 0, false, "Initial")
		item.set_button_color(1, 0, Color(1.0, 1.0, 1.0, 1.0 if scene_info.initial else 0.5))
		item.add_button(1, _editor_theme.get_icon("Environment", "EditorIcons"), 1, false, "Global")
		item.set_button_color(1, 1, Color(1.0, 1.0, 1.0, 1.0 if scene_info.global else 0.5))
		item.add_button(1, _editor_theme.get_icon("Remove", "EditorIcons"), 2, false, "Remove")
		
		if _item_just_added == scene_name:
			new_item = item
	
	if _item_just_added != &"" && new_item != null:
		new_item.set_editable(0, true)
		_tree.set_selected(new_item, 0)
		await get_tree().process_frame
		_tree.edit_selected(true)
		
		_item_just_added = &""

func _get_scene_name_from_uid(uid: int) -> StringName:
	for scene_name in _scenes:
		var scene_info = _scenes.get(scene_name)
		
		if scene_info.uid != uid:
			continue
		
		return scene_name
	
	return &""

func _find_valid_name(new_name: StringName, old_name: StringName = &"") -> StringName:
	if new_name == &"":
		return old_name
	
	if !_scenes.has(new_name):
		return new_name
	
	var index_match = DUPLICATE_NAME_INDEX_REGEX.search(new_name)
	
	var base_name
	var index
	if index_match == null:
		base_name = new_name
		index = 1
	else:
		base_name = DUPLICATE_NAME_INDEX_REGEX.sub(new_name, "")
		index = int(index_match.strings[1]) + 1
	
	var current_name = "%s_%d" % [base_name, index]
	while current_name != old_name && _scenes.has(current_name):
		current_name = "%s_%d" % [base_name, index]
		index += 1
	
	return current_name

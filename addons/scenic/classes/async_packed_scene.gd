class_name AsyncPackedScene extends Object

#region constants
const START_LOAD_INFO: String = 					"[Scenic] Started loading scene from \"%s\""
const LOAD_INFO: String = 							"[Scenic] Loaded scene from \"%s\""
const UNLOAD_INFO: String = 						"[Scenic] %s unloaded"
const RELOAD_WARNING: String = 						"[Scenic] Attempting to load \"%s\" after it has already been loaded"
const UNLOAD_NOTHING_WARNING: String = 				"[Scenic] Attempting to unload \"%s\" when it is already unloaded"
const LOAD_START_FAILED_ERROR: String = 			"[Scenic] Failed to start loading the scene from \"%s\""
const LOAD_FAILED_ERROR: String = 					"[Scenic] Failed to load the scene from \"%s\""
const LOAD_FAILED_INVALID_RESOURCE_ERROR: String = 	"[Scenic] Failed to load the scene from \"%s\" (Invalid resource)"

#region enums
enum SceneLoadingState {
	LOAD_QUEUED,
	LOADING,
	CANCEL_AFTER_LOAD,
	CANCELED,
	LOADED
}

#region signals
signal loaded_scene

#region identity
var uid: int = 0:
	set(value):
		if value == uid:
			return
		
		uid = value
		
		_path = ResourceUID.get_id_path(uid)
var _path: String = ""

#region references
var _scene: PackedScene = null

#region state
var ref_count: int = 0
var _state: SceneLoadingState = SceneLoadingState.LOAD_QUEUED
var _loading_progress: float = 0.0

#region node_events
func _init(_uid: int) -> void:
	uid = _uid

#region public_functions
func queue_load() -> void:
	if _state == SceneLoadingState.CANCEL_AFTER_LOAD:
		_state = SceneLoadingState.LOADING
	else:
		_state = SceneLoadingState.LOAD_QUEUED

func queue_unload() -> void:
	if _state == SceneLoadingState.LOADING:
		_state = SceneLoadingState.CANCEL_AFTER_LOAD
	else:
		_state = SceneLoadingState.CANCELED

func poll_loading_progress() -> void:
	if _state == SceneLoadingState.LOAD_QUEUED:
		_start_loading()
	
	if _state == SceneLoadingState.LOADING || _state == SceneLoadingState.CANCEL_AFTER_LOAD:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(_path, progress)
		
		match status:
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
				push_error(LOAD_FAILED_ERROR % _path)
				_state = SceneLoadingState.CANCELED
			
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
				push_error(LOAD_FAILED_INVALID_RESOURCE_ERROR % _path)
				_state = SceneLoadingState.CANCELED
			
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				_loading_progress = progress[0]
			
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				print_verbose(LOAD_INFO % _path)
				
				_loading_progress = 1.0
				_scene = ResourceLoader.load_threaded_get(_path)
				
				if _state == SceneLoadingState.CANCEL_AFTER_LOAD:
					_state = SceneLoadingState.CANCELED
				else:
					_state = SceneLoadingState.LOADED
				
				loaded_scene.emit()

func get_scene_async() -> PackedScene:
	if _state != SceneLoadingState.LOADED:
		await loaded_scene
	
	return _scene

func get_state() -> SceneLoadingState:
	return _state

#region private_functions
func _start_loading() -> void:
	var result = ResourceLoader.load_threaded_request(_path, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE)
	if result != OK:
		push_error(LOAD_START_FAILED_ERROR % _path)
		return
	
	_state = SceneLoadingState.LOADING
	
	print_verbose(START_LOAD_INFO % _path)

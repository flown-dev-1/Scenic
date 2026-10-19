class_name Test1 extends Scene

var _test_3_queue: SceneQueue = null

func _start(data: Variant) -> void:
	print("Data: %s" % data)

func _ready() -> void:
	_test_3_queue = GlobalSceneManager.add(&"Test 3").with_transition(&"Fade", 2.0)

func test_1() -> void:
	GlobalSceneManager.reload("Test 1", %HSlider.value).transition()

func test_2() -> void:
	GlobalSceneManager \
		.switch("Test 2", %HSlider.value, [&"Overlay"]) \
		.transition_callback(func ():
			print("Transition callback")
	, &"Fade")

func test_3() -> void:
	_test_3_queue.transition()

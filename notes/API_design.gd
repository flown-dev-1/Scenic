if ...: # Suppresses errors on the rest of this script
	pass



## Basic set scene example
GlobalSceneManager.set(&"Test").transition()

## OR

GlobalSceneManager.queue().set(&"Test").transition()

## OR

var queue = GlobalSceneManager.queue()
queue.set(&"Test")
queue.transition()



## Selective set scene example
GlobalSceneManager.set(&"Test", [&"Overlay"]).transition()



## Set multiple scenes example
GlobalSceneManager.sets([&"Test 1", &"Test 2", &"Test 3"]).transition()



## Basic add scene example
GlobalSceneManager.add(&"Test").transition()



## Add multiple scenes example
GlobalSceneManager.adds([&"Test 1", &"Test 2", &"Test 3"]).transition()



## Basic transition example
GlobalSceneManager.set(&"Test").transition(&"Fade")



## Throws an error and only does first scene operations and transition
GlobalSceneManager.set(&"Test").transition(&"Fade")

GlobalSceneManager.set(&"Test 2").transition(&"Fade")



## Throws an error and only does first scene operations and transition
GlobalSceneManager.set(&"Test").transition(&"Fade")

GlobalSceneManager.set(&"Test").transition(&"Fade")



## Runs sequentially
await GlobalSceneManager.set(&"Test").transition(&"Fade")

GlobalSceneManager.set(&"Test 2").transition(&"Fade")



## Load scene far in advance without blocking other scenes from loading
var scene_transition_queue = GlobalSceneManager.set(&"Test")

# ... (some code)

scene_transition_queue.transition(&"Fade")



## Does nothing, does not block scene loading, and throws a warning
GlobalSceneManager.add(&"Test").remove(&"Test").transition(&"Fade")

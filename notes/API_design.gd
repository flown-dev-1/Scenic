if ...: # Suppresses errors on the rest of this script
	pass



## Basic set scene example
GlobalSceneManager.set(&"Test").transition()

## OR

GlobalSceneManager.create_queue().set(&"Test").transition()

## OR

var queue = GlobalSceneManager.create_queue()
queue.set(&"Test")
queue.transition()

## OR

var queue = GlobalSceneManager.set(&"Test")
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



## Load scene AND SET TRANSITION far in advance without blocking other scenes from loading
var scene_transition_queue = GlobalSceneManager.set(&"Test").set_transition(&"Fade")

# ... (some code)

scene_transition_queue.transition()



## Does nothing, does not block scene loading, and throws a warning
GlobalSceneManager.add(&"Test").remove(&"Test").transition(&"Fade")



## Creating THEN applying multiple queues
var queue_1 = GlobalSceneManager.add(&"Test")
var queue_2 = GlobalSceneManager.add(&"Test")

await queue_1.transition()
# Does not produce any warnings or errors, may not do anything though. This does
# mean that removals will have to be stored with their exclusions rather than
# specific scenes until transition() is called, queues should just store a
# sequence of actions. Will require extra logic to determine if a temove undoes
# an add
queue_1.transition()



## Force loading example
GlobalSceneManager.force_load(&"Test")

# ... (some time later)

# Does not need to wait for Test to load
GlobalSceneManager.add(&"Test").transition()

# Does not unload Test
GlobalSceneManager.remove(&"Test").transition()

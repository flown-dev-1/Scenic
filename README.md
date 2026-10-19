# Scenic
![Logo](https://github.com/super-miner/Scenic/blob/main/banner.png)

A scene manager addon for Godot. Handles changing scenes, managing transitions, and asynchronous loading all with a simple but flexible API.

# Installation
You can install the addon manually or through the asset store.

> [!NOTE]
> If your version of Godot is not supported by the latest version of the addon you may need to download the addon manually so that you can pick an older version.

## Manual Installation
1. Download the addon from the GitHub Releases page.
2. Unzip the addon folder.
3. Create an `res://addons` folder in your Godot project if you do not already have one.
4. Drag the addon folder into your `res://addons` folder.
5. Enable "Scenic" in `Project Settings > Plugins`.

## Asset Store Installation
1. Navigate to the `Asset Store` tab in your Godot project.
2. Locate the "Search" addon and click on it.
3. Click the download button.
4. Enable "Scenic" in `Project Settings > Plugins`.

# Setup
Scenic works by completely circumventing the regular Godot scene system. Projects made with this addon will define one main scene containing the scene manager that will be loaded throughout the whole duration of the program.

It is recommended that the root node of your main scene is a `SceneManager`. The scene manager is responsible for managing things like loading and instantiating scenes as well as things like scene transitions.

## Creating the Main Scene
![Scene Manager Setup](https://github.com/super-miner/Scenic/blob/main/scene_manager_setup.png)

*A basic scene manager set-up with one transition. See [Transitions](https://github.com/super-miner/Scenic#transitions)  for more information about creating transitions.*

Make sure your SceneManager node has `global` set to `true`. Scenic lets you use multiple scene managers but only one is allowed to be "global". The global scene can be accessed through the `GlobalSceneManager` autoload.

Once you have your main scene setup make sure to make it the default scene in `Project Settings > General > Application > Run > Main Scene`.

## Adding Scenes
You can add scenes to your scene manager by dragging them onto the scenes list in the inspector.

> [!WARNING]
> The root node of any scene **must** be of type `Scene`.

![Scenes List](https://github.com/super-miner/Scenic/blob/main/scenes_list.png)

From here you can set the properties of your scenes including:

* **Name:** The name of your scene. Used to reference the scene in code.
* **Initial:** Whether this scene is initial or not. Initial scenes are instantiated on project load.
* **Load on Start:** Whether this scene should load when the project starts. Scenes with this setting are kept in memory throughout the whole runtime of the program.

Set at least one scene to initial to get started.

# Usage
Scenic is designed to be as flexible as possible while keeping the core API simple. Because of this you may not need to read this whole section before you start using the addon. The features are ordered by how important they are to the average user.

## Changing Scenes
This is how you do the very basic scene change that you would expect from any scene manager addon. It will free the previously loaded scene(s) and instantiate the new one.

```gdscript
GlobalSceneManager.switch(&"Scene 2").transition()
```

> [!TIP]
> If you don't like typing `&` in front of all your strings, you don't have to! The `&` is used to mark the string as a `StringName` but it isn't required by Godot.

Technically you could stop here and you would be able to manage your scenes, but you'd be missing out on a lot of the benefits of using Scenic.

Before we go any further it is important to explain a few points about how the scene manager handles scenes.

### Multiple Scenes
Scene managers in Scenic can have multiple scenes loaded at once. Because of this Scenic offers more control than just `switch()` in the form of.

| **Function** | **Single Scene** | **Multiple Scenes** |
| --- | --- | --- |
| Switch scenes | `switch(...)` | `switches(...)` |
| Add scenes | `add(...)` | `adds(...)` |
| Reload scenes | `reload(...)` | `reloads(...)` |
| Remove scenes | `remove(...)` | `remove(...)` |
| Remove all scenes | N/A | `remove_all(...)` |

This allows you to do things like swap out the current level without swapping out the HUD or the pause menu.

```gdscript
func _ready() -> void:
	GlobalSceneManager.remove_all().adds([&"Level 1", &"HUD", &"Pause Menu"]).transition()

func _on_level_1_finished() -> void:
	GlobalSceneManager.remove(&"Level 1").add(&"Level 2").transition()

	# Alternative code using switch's exclude functionality.
	# This code assumes that all scenes we want to keep have the "UI" tag applied in the inspector.
	GlobalSceneManager.switch(&"Level 2", null, [&"UI"]).transition()
```

> [!NOTE]
> If you don't care about having multiple scenes then you can just use `switch` and it will behave as you would expect.
>
> ```gdscript
> GlobalSceneManager.switch(&"Scene 2").transition()
> ```

### Queuing
Now that you are familiar with the basic structure of Scenic it is time to talk about queuing which will help explain why it is structured this way.

All scene transitions in Scenic are done in two steps: Queuing up the scene changes and actually applying them. In our previous examples we have done this all on one line but it can be split up.

```gdscript
# Create the queue
var queue: SceneQueue = GlobalSceneManager.switch(&"Scene 2")

# Apply the transition
queue.transition()
```

> [!NOTE]
>
> `switch()` (and all other queuing functions) will implicitly create a queue when called on a Scene Manager, but you can also create one explicitly by calling `queue()`
>
> ```gdscript
> # Does the same thing as above
> var queue: SceneQueue = GlobalSceneManager.queue().switch(&"Scene 2")
> ```

There are good reasons for splitting up the queuing and applying of scene transitions. For example, Scenic will start loading scenes asynchronously as soon as they are queued up, so we can do something like this to ensure that they are loaded before we need to transition.

```gdscript
var main_menu_queue: SceneQueue
var death_overlay_queue: SceneQueue
var next_level_queue: SceneQueue

func _ready() -> void:
	# These will all start preloading the required scenes right away
	main_menu_queue = GlobalSceneManager.switch(&"Main Menu")
	death_overlay_queue = GlobalSceneManager.add(&"Death Overlay")
	next_level_queue = GlobalSceneManager.switch(&"Level 2", null, [&"UI"])

func main_menu_pressed() -> void:
	main_menu_queue.transition()

func die() -> void:
	death_overlay_queue.transition()

func next_level() -> void:
	next_level_queue.transition()
```

## Transitions
One important feature of Scenic is that it can handle scene transitions for you. To set up a scene transition all you need to do is add it as a child of the scene manager.

To start we will walk through the set up for the built in `FadeTransition` and then after that we will talk about making custom transitions.

### Fade Transition
To create a fade transition add a `FadeTransition` node as a child of your scene manager. It should look something like this.

![Transition Setup](https://github.com/super-miner/Scenic/blob/main/transition_setup.png)

> [!NOTE]
> In this example we rename our `FadeTransition` to "Fade" for easy access later.

Looking at the `FadeTransition` in the inspector we can see that it takes in a curtain reference as well as a few other settings. The curtain is the control node that will fade in when we do the transition. Add a `Panel` node as a child and drag it into the curtain slot.

![Transition Setup](https://github.com/super-miner/Scenic/blob/main/scene_manager_setup.png)

To use the fade transition, reference it in your call to `transition()`.

```gdscript
GlobalSceneManager.switch(&"Scene 2").transition(&"Fade") # The name used to reference the transition here is the name of the SceneTransition node.
```

> [!TIP]
>
> You can also pre-specify a transition for a queue by using `with_transition()`.
>
> ```gdscript
> var queue = GlobalSceneManager.switch(&"Scene 2").with_transition(&"Fade")
>
> # ... do some stuff
>
> queue.transition() # Will use the transition set above
> ```

### Custom Transitions
You can also create your own custom transitions. In Scenic transitions are just a type of node so you can create your own by creating a class that extends `SceneTransition`.

```gdscript
# Include a reference to the icon in all transitions otherwise it will have the wrong icon.
@icon("res://addons/scenic/icons/fast_forward.svg")
class_name MyCustomTransition extends SceneTransition

# Required functions, all transitions must implement these.
func transition_in(time_scale: float = 1.0) -> void:
	# ... do transition in to transition screen

func set_in() -> void:
	# ... instantly set state to transition screen showing

func transition_out(time_scale: float = 1.0) -> void:
	# ... do transition out of transition screen

func set_out() -> void:
	# ... instantly set state to transition screen hidden
```

If you want to use the fade transition as a reference you can find it in `res://assets/scenic/nodes/transitions`.

## Passing Data (to new scenes)
Scenic allows you to pass data along whenever you add, set, or reload a scene using the `data` parameter like this.

```gdscript
var important_data_1 = 42.0

var important_data_2 = {
	"name": "John",
	"health": 100.0
}

GlobalSceneManager \
	.switch(&"Scene 2", important_data_1) \
	.add(&"Scene 3", important_data_2) \
	.transition()
```

This data can then be received by the scene by having it implement the `_start` method.

```gdscript
@icon("res://addons/scenic/icons/clapperboard.svg")
class_name Scene2Class extends Scene

func _start(data: Variant) -> void:
	print("Data received: %d" % data)
```

## Force Loading
> [!WARNING]
> This section of the documentation is under construction.

## Debugging
> [!WARNING]
> This section of the documentation is under construction.

## Multiple Scene Managers
> [!WARNING]
> This section of the documentation is under construction.

# Contributing
> [!WARNING]
> This section will be added later.

# Getting Help
* If you are struggling with using Scenic, feel free to ask for help in my [Discord server](https://flowndev.com/discord).
* If you have found a bug or issue with the addon, please create an [issue](https://github.com/super-miner/Scenic/issues).

# Credits
* **Node icons & logo** from [@icons](https://github.com/Voxybuns/at-icons)
* **Background image** from [ClickerHappy](https://www.pexels.com/photo/photo-of-mountains-during-sunset-777211/)










Getting started
===============

Installation
------------

.. tip::
   It is strongly recommended to use the COGITO Project as your base Godot project, as it comes with a few pre-configured settings like Input Maps and Globals/Autoloads. After installation, you can import your own assets and get started making your game.

Installation steps:

#. Clone this repo or download it and unzip it into its own directory.
#. Open the project with the Godot editor (make sure you use a compatible version, currently 4.3)


Setup
-----

If you've used the COGITO Project as the base for your own project, you shouldn't have to do much else to get it running.

If not, make sure you activate the the Cogito plugin under Project > Project Settings > Plugins
It is recommended to install and activate Quick Audio and Input Helper before activating Cogito to avoid any issues.

To re-iterate, the following plugins should be installed and activated:

* Cogito
* Quick Audio (currently v1.0)
* Input Helper (currently v4.6.0)


Make sure that the Main Scene is set to ``res://addons/cogito/DemoScenes/COGITO_0_MainMenu.tscn``. This is not strictly necessary, but will make sure the Demo project runs as expected.

**Initiatlizing the input map**

If you have NOT made a copy of the whole project, but instead grabbed the addon from the AssetLib, your project might be missing the required input map settings.
To easily get those, Cogito has a function that will reset/overwrite your input map settings to get you started.

1. Find ``CogitoSettings.tres`` under ``addons/cogito/``.
2. If you select this resource, in the inspector, you find a group called **Danger Zone**
3. There you will find a button ``Reset Project Input Map``
4. If you're ready, click it to reset the input map for your project.
5. You need to manually restart your Godot project for the changes to take effect.



Running the Demo scenes
-----------------------

* You can find all included Demo scenes within ``/addons/cogito/DemoScenes/`` but if you've followed the steps above you can also just run the project by pressing ``F5`` and it should start at the Main Menu.
* You can also run the ``Lobby`` or the ``Laboratory`` scenes directly and explore.

Feel free to explore the Demo scenes to discover everything COGITO has to offer!


Known Errors
------------
When running Cogito, depending on the scenes you might get a few errors in the Debugger.
If it's one of the following, they can be ignored for the most part:

* Audio.gd:12 @ _play_sound(): Parent node is busy setting up children, `add_child()` failed. Consider using `add_child.call_deferred(child)` instead.
* cogito_basic_enemy.gd:172 @ move_toward_target(): NavigationServer navigation map query failed because it was made before first map synchronization.
* cogito_basic_enemy.gd:180 @ _look_at_target_interpolated(): The target vector can't be zero.


How COGITO works in 60 seconds
------------------------------

Here's all you need to know in as little words as possible.

Level scenes
~~~~~~~~~~~~

You only need the ``cogito_player.tscn`` in your scene to run. It includes the HUD and pause menu as child scenes.
The root node of your level scene needs to have ``cogito_scene.gd`` attached. If you want to transition between scenes, you need to define connector nodes in the inspector.

Components
~~~~~~~~~~
A lot of parts of COGITO heavily applies the component design pattern. This means that most functions are organized in a way where you will have a root node of an object, and can add or remove several child nodes as *Components* to change the object's behavior.
For example:

* Player scene has Attributes as child nodes.
* Cogito Objects have InteractionComponents as child nodes.

and many more.

Common object types
~~~~~~~~~~~~~~~~~~~
COGITO includes a number of common object scripts which define an objects behavior.
When you create your game, a common workflow would look like this:

#. Create a new scene (usually a Node3D)
#. Create / import an asset (like a door mesh)
#. Add the imported mesh to your new scene. (MeshInstance of the door + collider)
#. Attach the script with the desired behavior to the scene root node (for the door we'd use ``cogito_door.gd``)
#. Set the desired behavior in the Inspector
#. Add any additional nodes or components (the door requires a BasicInteraction component as a child node)
#. Save packed scene.

Voilà, you can now place the door in your level scenes and it should work.
You can read more about this and other objects in the manual under *Cogito Objects*.

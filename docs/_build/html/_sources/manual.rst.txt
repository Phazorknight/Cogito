Manual
======

.. note:: 
   The documentation is still work in progress and will be updated over time.

.. tip::
   This documenation will give you an overview of the most important properties & methods of the different nodes and how to use them. This documentation does not always list each and every function or exposed property, as these are better explored in the editor itself and include tooltips on how to use them. If you want to dive deeper into the code, you can also read the comments in the source code.

Introduction
------------

COGITO is a fully featured template. It is recommended to use this as the starting point of your project BEFORE implementing any of your own features. We strongly recommend playing through the included demo scenes to get a good impression of what functionality is included. While COGITO is designed with modularity and versatility in mind, it is usually easier to modify the included systems than try to make it work with other external systems (like using a different inventory system or player controller). The most common tasks most users will run into is adapting their own assets and levels to work with COGITO. I'm in the process of creating video tutorials for these cases which should help you get started quickly.

Player Controller
-----------------
COGITO includes a first person player controller that has a variety of parameters and settings built-in. We recommend just reading through the descriptions and tweaking the parameters to your liking. Most common adjustments needed are walking, running and sprinting speeds, stair handling, and ladder handling. Be aware that a few of the player controller parameters will be controlled by the game options and are thus user controlled (for example Invert Y Axis).

COGITO Attributes
-----------------
``COGITO Attributes`` are a custom class used to save and manipulate data most commonly used to represent some kind of numerical attribute. Most common examples are values like health points, stamina, magic, etc. These are usually tied to the player but not exclusively. For example you can use the health attribute on any objects that you want to receive damage. The included specific attributes come as component nodes you can simply instantiate as child nodes to any object.

CogitoAttribute base class
~~~~~~~~~~~~~~~~~~~~~~~~~~
The base class used for any attributes is the ``CogitoAttribute`` class.

**Properties:**

* attribute_name (String)
   * String used in scripts to find specific attributes. Make sure this is all lowercase and without spaces.
* attribute_display_name (String)
   * As it would appear in the game.
* attribute_color (Color)
   * Used for UI elements
* attribute_icon (Texture2D)
   * Used for UI elements
* value_max (float)
   * The maximum value of this attribute. Can change over time and is saved in the player state file.
* value_start (float)
   * The start value of this attribute.

**Signals:**

* attribute_changed(attribute_name: String, value_current: float, value_max: float, has_increased: bool)
   * Gets emitted anytime the attribute value changes. If the value change was positive, has_increased will be true, if not it's false)
* attribute_reached_zero(attribute_name: String, value_current: float, value_max: float)
   * Gets emitted when the current value of this attribute is 0.

Health Attribute
~~~~~~~~~~~~~~~~
This attribute is not just for player health. You can attach the component to objects to give them their own "health" and define behaviour when they run out of health (death).

**Properties:**

* no_sanity_damage (float)
   * used in combination with the sanity attribute. Defines how much damage per second the owner takes if their sanity attribute has reached zero.
* sound_on_damage (AudioStream)
   * AudioStream that plays when the owner takes damage.
* sound_on_death (AudioStream)
   * AudioStream that plays when the owner dies (health reaches zero).
* destroy_on_death (Array[NodePath])
   * When the owner dies, all the nodes which nodepaths are in this array will get destroyed (queue_free())
* spawn_on_death (PackedScene)
   * When the owner dies, the packed scene will be instantiated at the owners global position. This is most commonly used for VFX or item drops.

**Signals:**

* damage_taken()
   * Gets emitted when the owner takes damage (attribute value decreases). Can be used for VFX, audio.
* death()
   * Gets emitted when the owner dies. Can be used for VFX, audio, triggering cutscenes, updating quests, etc.

Stamina Attribute
~~~~~~~~~~~~~~~~~

This attribute works in tight connection with the Player controller. When in use, certain actions from the player will consume stamina and player movement will be limited once the stamina is fully depleted. The default actions that are affected by Stamina is sprinting and jumping.

.. tip::
   If you don't want to use the Stamina system, simply remove the StaminaAttribute from your Player scene. 

**Properties:**

* stamina_regen_speed (float)
   * How fast stamina regenerates in points per second.
* run_exhaustion_speed (float)
   * How fast sprinting reduces stamina in points per seconds of sprinting.
* jump_exhaustion (float)
   * How much stamina jumping consumes in points.
* regenerate_after (float)
   * The delay after using the last stamina-consuming action before stamina starts regenerating, in seconds.
* auto_regenerate (float)
   * If turned off, stamina will not auto regenerate.


Visibility Attribute
~~~~~~~~~~~~~~~~~~~~

(This used to be called Brightness component). The ``Visibility Attribute`` represents how "visible" the player is within a scene. It is important to understand that this attribute is not actually tied to Lights within your scene. Instead, it works by counting how many ``Lightzones`` the player is currently in.

``Lightzones`` are a separate component, which gives developers complete control over how visible the player is at any spot inside a level. This attribute can then be checked by other entities, whenever they have a reference to the player. A common example would be that if the player enters the viewcone of a NPC, you might still want the NPC to not detect the player if they're shrouded in complete darkness, or detect the player faster, the higher their visibility is.

.. tip::
   If you don't want to use the Visibility system, simply remove the VisibilityAttribute from your Player scene.

Light Meter Attribute
~~~~~~~~~~~~~~~~~~~~~

This new attribute actually measures how much light the player is exposed to by checking the average luminance of the current player position. As this heavily depends on your scene, you will most likely need to tweak the min/max values within this attribute and it's script. Please note that this calculation is somewhat performance hungry, so use with caution.

Sanity Attribute
~~~~~~~~~~~~~~~~

.. warning:: 
   This attribute is a work in progress

UI Attribute Component
----------------------

This ``packed scene`` is used to reperesent ``CogitoAttributes`` in the ``Player HUD``. In the default COGITO Setup, the ``Player HUD`` checks which attribute nodes are part of the Player scene and instantiates a ``UI Attribute Component`` for each one in the ``Attribute Container``.

The ``UI Attribute Component`` reads all properties and connects to all signals needed directly from the Attribute itself (color, icon, name, values). You can customize the component to fit your own needs. Alterantively, you can also define explicit attribute components for each attribute if you create a direct reference in the ``Player HUD`` script (this involves some coding). To change where the Attribute UIs show, change the location of the ``PlayerAttributes`` ``PanelContainer``.

Player Interaction System
-------------------------

COGITO works with a raycast interaction system. This means that the player camera contains a ``raycast3d`` that constantly checks what the player is looking at. If an interactive object is detected, the raycast checks what kind of interaction components are attached to the object and displays interaction prompts accordingly.

Cogito Objects
--------------
``Cogito Object`` refers to classes specifically created to work with all of COGITO's systems. These are designed to represent the most commonly used interactive objects in games. Below you'll find a brief explanation what each object does so you know which one to choose when you want to turn your own asset into a suitable ``Cogito Object``. 

.. hint:: 
   Interactables consider two major parts: The object itself and the InteractionComponents attached as child nodes to define what kind of interactions can be done.

Here's a quick overview which object to use for what use-case:

=========================    =======================================================================================================
Cogito Object/Script	     Use case
=========================    =======================================================================================================
Cogito_Object	             Item pick-ups, props, crates, "clutter objects"
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_Door	                 Doors, gates, manually controlled platforms, bridges, moveable objects with two positions (open/closed)
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_Button	             Button that unlocks a door (single-use), vending machine buttons (repeated-use)
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_Switch	             Lamps, levers, sockets for key objects, objects with two states (on/off)
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_Keypad	             Keypads, other UI based minigames that should send signals.
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_Turnwheel	         Valves, rotation-based levers, press-and-hold interactions
-------------------------    -------------------------------------------------------------------------------------------------------
Cogito_StaticInteractable	 Static objects who's state won't get saved that still can have interactions attached.
=========================    =======================================================================================================

Cogito_Object
~~~~~~~~~~~~~
This is the basis of most smaller interactive objects. Item pickups, crates, and common "clutter objects" would utilize this. Use a ``Cogito_Object`` if you want to do any of the following:

* You want the object to be moved around within the level scene (``Cogito_Object`` saves position and rotation, works well with RigidBodies)
* You want to use a variety of included interactions (most other objects have bespoke interactions, ``Cogito_Object`` is made to use a mix of interaction components)
* This object might not always exist in the level scene (``Cogito_Object`` are based on PackedScenes and sometimes get instanced on runtime, COGITO also saves if a ``Cogito_Object`` exists in a scene or not)

Cogito_Door
~~~~~~~~~~~
Naturally, this object is perfect for doors, but it can actually be used for anything that is supposed to move based on player interaction or other Cogito Objects. If you have an object that transitions between two positions, then the Cogito_Door object is the one to use. It also includes options to be "locked" and to require a key_item to be unlocked. Cogito_Doors also don't have to be purely triggered by direct player interactions: Cogito_Doors can be controlled by other Cogito Objects or via signals. To learn how to set up a Cogito Door from scratch, check out COGITO - Tutorial: Sliding door.

Cogito_Button
~~~~~~~~~~~~~
The ``Cogito_Button`` is used to trigger other objects via signal or to call interact() on other ``Cogito_Objects``. It can be set to be "one-time-use" and also has "re-use" delay to avoid spamming.

Cogito_Switch
~~~~~~~~~~~~~
Similar to the ``Cogito_Button`` but with a few more functions. This is used to create interactive objects with a clear on/off or A/B state. Most common examples are lamps and lights. 

It uses 3 node arrays that will be switched depending on their state: 

* nodes that will be shown when ON
* nodes that will be hidden when ON 
* and nodes that will have interact() called on switch use. 

You can also set if the switch can be used repeatedly or not, if using the switch requires an item, and of course your custom interaction texts. Included signals can also help triggering additional behaviours, like playing an animation. 

.. tip:: 
    The objects you switch do not have to be part of the switchable object. For example if you want a ceiling lamp that is controlled by a light switch, make the light switch the switchable and add all the ceiling lamps to the objects to switch list.

Cogito_Keypad
~~~~~~~~~~~~~
This classic Keypad works exactly as you expect. The included ``PackedScene`` includes it's own GUI, which can be easily customized. The ``Cogito_Keypad`` includes exposed references to work with ``Cogito_Doors``, but you can also set them to trigger other objects by using the included signals.

Cogito_Turnwheel
~~~~~~~~~~~~~~~~
With this you can create most common "press and hold" interaction that involve turning an object, like a valve. It is made to work with a ``HoldInteraction`` component. This object includes settings for rotation axis and speed as well as an ``AudioStream`` to play while being rotated. It also includes an exposed reference to trigger other nodes (most commonly used for doors).

Cogito_StaticInteractable
~~~~~~~~~~~~~~~~~~~~~~~~~
This object is used for ``Cogito Objects`` that do not need to save any information for persistency or saving/loading. The object itself does not have to be strictly static. This is most commonly used for very generic environment interactables, like a poster on the wall that will have a Readable component, or a pinwheel that can be spun via an interaction.

Cogito Inventory System
-----------------------
The inventory system is largely resource based. The inventory system and the inventory UI are independent form each other. UI elements get updated via signals.

Inventory Overview
~~~~~~~~~~~~~~~~~~
The Inventory System contains of 3 main resources: 

* Item: Resource that contains all the parameters pertaining to a specific item. Has sub-catgeories like ``WieldableItem``, ``ConsumableItem`` etc.
* Slot: The "container" for an item and manages stuff like item stacks, moving items, dropping items, etc.
* Inventory: This resource is a collection of slots. Can vary in size. Per default, the Player has an inventory attached. Also used for containers.

.. important::
   It is helpful to understand what the documentation refers to when using the words ``item`` and ``pick up``

   * ``Item``  always refers to the Resource file, based on the ``Inventory Item`` class.
   * ``Pick up`` is how the item exists in the 3D world, usually as a ``Cogito_Object`` with a ``pick_up component`` attached.
   * Usually the two reference each other: ``Cogito_Object`` with ``Pickup_component`` <-> ``Inventory Item resource``

.. note:: 
    Make sure that the ``Slot Data`` resource on your ``pick up`` is set to "Local to Scene ON", especially on stackable items. If not, instances of this item will share the same slot resource, causing item quantities to be calculated incorrectly.

Inventory Item Class
~~~~~~~~~~~~~~~~~~~~
This is the base class of all ``Inventory Items``. Contains information that is common to all item types, such as name, description, stack size, etc. If you want to create your own item type, it is strongly recommended to inherit from this class.

Game persistence, saving and loading
------------------------------------
This information will help you understand when and what kind of data is loaded and saved. If you run into any issues with scene persistence not behaving as you might expect, this might point you in the right direction.

Save data overview
~~~~~~~~~~~~~~~~~~
COGITO uses custom resources for saving. These resources are called ``states``. The ``state file`` contains all information that COGITO saves, usually tied to a profile or save slot.

There are two types of state files: Player states and Scene states. Separating this has pros and cons. Knowing these can help you to understand any issues you might run into, as well as changing what doesn’t work for you.

**Pros:**

* Player state is completely game scene independent.
* Easier to customize what kind of data is saved.
* Scene states don’t need to “know” of other scene states.
* When the player saves/loads a game, only necessary data is saved or loaded, improving load times.
* Avoids save file bloat.
  
**Cons:**

* File management: As save data is split up between different ``state files``, more file management actions need to be taken for each operation.
* Old/misaligned ``state files`` can create unexpected behavior or reduced compatibility when updating/changing the player or scenes.

Player state
~~~~~~~~~~~~
The ``player state`` contains all data tied to the player:

* Player position in game scene
* Player rotation in game scene
* Game scene the player was in when the state was saved (name as well as path)
* Player attributes (current value and max value)
* Player inventory
* Player quests (active, failed, completed)

**When is the player state saved?**

* A ``player state`` is saved when the game save is triggered manually. The save file created is saved in the user directory and is tied to the currently active save slot.
* A temporary ``player state`` is also saved when the player transitions from one scene to another scene. This state is saved on exit of the first scene, and loaded when entering the new scene, as to maintain player data consistency.

**When is the player state loaded?**

* A ``player state`` is loaded when the player loads a saved game manually. It is tied to the currently active save slot.
* If the player is transitioning from one scene to another, then the temporarily created player state is loaded, with some data like player position and rotation being overwritten by the scene connector.

Scene state
~~~~~~~~~~~
The ``scene state`` contains all data relevant for proper persistence of the game scene. Usually you’d have a ``scene state`` file for each save slot and game scene present (for example, if your game has 10 game scenes, and 3 save slots, you’d potentially have 30 scene states, 10 scene states for each save slot).

The ``scene state`` contains the following data:

* All objects:

   * Position
   * Rotation

* Cogito Object:

   * Position
   * Rotation
   * Parent node path (for instantiation)
   * Packed scene file path (for instantiation)
   * Child interaction nodes (for object data)

* Cogito Door:

   * Is locked/unlocked
   * Is open/closed

* Cogito Switch:

   * Is on/off

* Cogito Button:

   * has been used

* Cogito Turnwheel:

   * has been turned
  
* Cogito Keypad:

   * is locked/unlocked

**When is the scene state saved?**

The ``scene state`` of the currently active game scene is saved when the player manually triggers the game save (usually from the menu). This only saves the state of the currently active scene (TODO: look into this more if the player transitions through multiple scenes)
The ``scene state`` is saved as a temporary state as soon as the player leaves the scene to transition to a different one. This is used to keep scene persistency if the player later returns to this scene.

**When is the scene state loaded?**

When the player loads a saved game, the scene as well as it’s state that is referenced in the ``player state`` is loaded. This works by checking if the player is currently in the scene that the ``player state`` has saved as the players location. If NOT, the game transitions to said scene and only then loads the ``player state`` and ``scene state``.
If it exists, a temporary ``scene state`` is loaded when the player transitions into a scene. This is used to keep scene persistency, if the player is returning to this scene when they were previously in it. If no temporary ``scene state`` is found, the default scene is loaded.
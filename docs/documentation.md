# Documentation
> [!WARNING]  
> The documentation is still work in progress and will be updated over time.

> [!IMPORTANT]  
> This documenation will give you an overview of the most important properties & methods of the different nodes and how to use them. If you want to dive deeper into the code, you can also read the comments in the source code.

**Table of Contents**
- [Documentation](#documentation)
- [Intro to COGITO](#intro-to-cogito)
  - [COGITO Setup](#cogito-setup)
  - [Basic Game Scene Setup](#basic-game-scene-setup)

- [Player Controller](#player-controller)

- [Cogito Attributes](#cogito-attributes)
  - [ CogitoAttribute base class](#cogitoattribute-base-class)
  - [ Health attribute](#health-attribute)
  - [ Stamina attribute](#stamina-attribute)
  - [ Visibility attribute](#visibility-attribute)
  - [ UI Attribute component](#ui-attribute-component)

- [Player Interaction System](#player-interaction-system)

- [Cogito Objects](#cogito_objects)
  - [ Cogito Object](#cogito_object)
  - [ Cogito Door](#cogito_door)
  - [ Cogito Button](#cogito_button)
  - [ Cogito Switch](#cogito_switch)
  - [ Cogito Keypad](#cogito_keypad)
  - [ Cogito Turnwheel](#cogito_turnwheel)

- [Cogito Object Components](#cogito_interactions)
  - [ Basic Interaction](#basic_interaction)
  - [ Hold Interaction](#hold_interaction)
  - [ Carryable Component](#carryable_component)
  - [ Readable Component](#readable_component)
  - [ Pickup Component](#pickup_component)

- [Cogito Inventory System](#cogito_inventory_system)
  - [ Overview]
  - [ Inventory Item Class]
  - [ Consumable Item]
  - [ Combinable Item]
  - [ Ammo Item]
  - [ Key Item]
  - [ Wieldable Item]

- [Wieldables](#behaviour-tree)
  - [ Overview](#wieldable_overview)
  - [ Flashlight (tool)]
  - [ Toy Pistol (projectile weapon)]
  - [ Laser Rifle (raycast weapon)]
  - [ Pickaxe (melee weapon)]

- [ Game persistence, saving and loading](#game-persistence-saving-and-loading)
  - [ Save data overview](#save-data-overview)
  - [ Player state](#player-state)
  - [ Scene state](#scene-state)

- [ Scene Transitions](#scene_transitions)
  - [Overview]
  - [Cogito Scene and Connectors]
  - [Transition Areas]

- [ Cogito Quest System]
  - [ Overview]
  - [ Cogito Quests]
  - [ Quest Updater]

- [FAQ and Troubleshooting](#faq)


# Intro to COGITO
COGITO is a fully featured template. It is recommended to use this as the starting point of your project BEFORE implementing any of your own features.
(TODO expand this section)

## COGITO Setup
1. Clone this repo or download it and unzip it into it's own directory.
2. Open the project with the Godot editor.
3. Make sure the following plug-ins are activated:
  - Quick Audio (currently v1.0)
  - Input Helper (currently v4.2.2)
4. Make sure the following Autoloads are set up in your project:
  - res://COGITO/EsayMenus/Nodes/menu_template_manager.tscn
  - res://COGITO/SceneManagement/cogito_scene_manager.gd
  - res://COGITO/QuestSysteemPD/CogitoQuestManager.gd
5. Open and run **res://COGITO/DemoScenes/COGITO_04_Demo_Lobby.tscn** to see if everything works.


## Basic Game Scene Setup
To fully work, you need 3 Prefab Scenes in your scene + the following references set up in their inspector. These nodes should be in this order in the scene tree:
- player.tscn
  - Reference to Pause Menu node
  - Reference to Player_HUD node
- Player_HUD.tscn
  - Reference to player node
- TabMenu.tscn

All signals needed get hooked up via code, so this should work without any extra signal setup.
To enable transitioning between scenes, your scene root node needs to have cogito_scene.gd attached and connector nodes defined (see demo scene). You can read more about this in [Scene Transitions](#scene_transitions).


# Player Controller
(work in progress)


# Cogito Attributes
Cogito Attributes are a custom class used to save and manipulate  data most commonly used to represent some kind of numerical attribute. Most common examples are values like health points, stamina, magic, etc. These are usually tied to the player but not exclusively. For example you can use the health attribute on any objects that you want to receive damage. The included specific attributes come as component nodes you can simply instantiate as child nodes to any object.

## CogitoAttribute base class
The base class used for any attributes is the CogitoAttribute class.

Properties:
  - **attribute_name** (String)
    - String used in scripts to find specific attributes. Make sure this is all lowercase and without spaces.
  - **attribute_display_name** (String)
    - As it would appear in the game.
  - **attribute_color** (Color)
    - Used for UI elements
  - **attribute_icon** (Texture2D)
    - Used for UI elements
  - **value_max** (float)
    - The maximum value of this attribute. Can change over time and is saved in the player state file.
  - **value_start** (float)
    - The start value of this attribute.
      
Signals:
  - **attribute_changed**(attribute_name: String, value_current: float, value_max: float, has_increased: bool)
    - Gets emitted anytime the attribute value changes. If the value change was positive, has_increased will be true, if not it's false)
  - **attribute_reached_zero**(attribute_name: String, value_current: float, value_max: float)
    - Gets emitted when the current value of this attribute is 0.


## Health Attribute
This attribute is not just for player health. You can attach the component to objects to give them their own "health" and define behaviour when they run out of health (death).

Properties:
  - **no_sanity_damage** (float)
    - used in combination with the sanity attribute. Defines how much damage per second the owner takes if their sanity attribute has reached zero.
  - **sound_on_damage** (AudioStream)
    - AudioStream that plays when the owner takes damage.
  - **sound_on_death** (AudioStream)
    - AudioStream that plays when the owner dies (health reaches zero).
  - **destroy_on_death** (Array[NodePath])
    - When the owner dies, all the nodes which nodepaths are in this array will get destroyed (queue_free())
  - **spawn_on_death** (PackedScene)
    - When the owner dies, the packed scene will be instantiate at the owners global position. This is most commonly used for VFX or item drops.

Signals:
  - **damage_taken**()
    - Gets emitted when the owner takes damage (attribute value decreases). Can be used for VFX, audio.
  - **death**()
    - Gets emitted when the owner dies. Can be used for VFX, audio, triggering cutscenes, updating quests, etc.


## Stamina Attribute
**Tip: If you don't want to use the Stamina system, simply remove the StaminaAttribute from your Player scene.**
This attribute works in tight connection with the Player controller. When in use, certain actions from the player will consume stamina and player movement will be limited once the stamina is fully depleted. The default actions that are affected by Stamina is sprinting and jumping.

Properties:
  - **stamina_regen_speed** (float)
    - How fast stamina regenerates in points per second.
  - **run_exhaustion_speed** (float)
    - How fast sprinting reduces stamina in points per seconds of sprinting.
  - **jump_exhaustion** (float)
    - How much stamina jumping consumes in points.
  - **regenerate_after** (float)
    - The delay after using the last stamina-consuming action before stamina starts regenerating, in seconds.
  - **auto_regenerate** (float)
    - If turned off, stamina will not auto regenerate.


## Visibility Attribute
(work in progress)


## Sanity Attribute
(work in progress)


# Player Interaction System
Cogito works with a raycast interaction system. This means that the player camera contains a raycast3d that constantly checks what the player is looking at. If an interactive object is detected, the raycast checks what kind of interaction components are attached to the object and displays interaction prompts accordingly.

**Help, my object doesn't get detected by the interaction system?**
- Check that the object is a Cogito Object or one of it's variants.
- Check that the object is set to the correct collision layers. The interaction raycast is set to detect on layer 2 by default.
- Check that the object has collision shapes.
- Check that the object contain interaction components. If you use custom interaction components, try to swap to default ones to see if the behaviour changes.
 


# Game persistence, saving and loading

This information will help you understand when and what kind of data is loaded and saved.
If you run into any issues with scene persistence not behaving as you might expect, this video might point you in the right direction.


## Save data overview

Cogito uses custom resources for saving. These resources are called states.
The state file contains all information that Cogito saves, usually tied to a profile or save slot.

There are two types of state files: Player states and Scene states. Separating this has pros and cons. Knowing these can help you to understand any issues you might run into, as well as changing what doesn’t work for you.

Pros:
- Player state is completely game scene independent.
- Easier to customize what kind of data is saved.
- Scene states don’t need to “know” of other scene states.
- When the player saves/loads a game, only necessary data is saved or loaded, improving load times.
- Avoids save file bloat.

Cons:
- File management: As save data is split up between different state files, more file management actions need to be taken for each operation.
- Old/misaligned state files can create unexpected behavior or reduced compatibility when updating/changing the player or scenes.


## Player state
The player state contains all data tied to the player:
- Player position in game scene
- Player rotation in game scene
- Game scene the player was in when the state was saved (name as well as path)
- Player attributes (current value and max value)
- Player inventory
- Player quests (active, failed, completed)

**When is the player state saved?**
- A player state is saved when the game save is triggered manually. The save file created is saved in the user directory and is tied to the currently active save slot.
- A temporary player state is also saved when the player transitions from one scene to another scene. This state is saved on exit of the first scene, and loaded when entering the new scene, as to maintain player data consistency.

**When is the player state loaded?**
- A player state is loaded when the player loads a saved game manually. It is tied to the currently active save slot.
- If the player is transitioning from one scene to another, then the temporarily created player state is loaded, with some data like player position and rotation being overwritten by the scene connector.


## Scene state
The scene state contains all data relevant for proper persistence of the game scene. Usually you’d have a scene state file for each save slot and game scene present (for example, if your game has 10 game scenes, and 3 save slots, you’d potentially have 30 scene states, 10 scene states for each save slot).

The scene state contains the following data:
- All objects:
  - Position
  - Rotation

- Cogito Object:
  - Position
  - Rotation
  - Parent node path (for instantiation)
  - Packed scene file path (for instantiation)
  - Child interaction nodes (for object data)

- Cogito Door:
  - Is locked/unlocked
  - Is open/closed

- Cogito Switch:
  - Is on/off
- Cogito Button:
  - has been used
- Cogito Turnwheel:
  - has been turned
- Cogito Keypad:
  - is locked/unlocked

**When is the scene state saved?**
- The scene state of the currently active game scene is saved when the player manually triggers the game save (usually from the menu). This only saves the state of the currently active scene (TODO: look into this more if the player transitions through multiple scenes)
- The scene state is saved as a temporary state as soon as the player leaves the scene to transition to a different one. This is used to keep scene persistency if the player later returns to this scene.

**When is the scene state loaded?**
- When the player loads a saved game, the scene as well as it’s state that is referenced in the player state is loaded. This works by checking if the player is currently in the scene that the player state has saved as the players location. If NOT, the game transitions to said scene and only then loads the player state and scene state.
- If it exists, a temporary scene state is loaded when the player transitions into a scene. This is used to keep scene persistency, if the player is returning to this scene when they were previously in it. If no temporary scene state is found, the default scene is loaded.




### --- OLD DOCUMENTATION BEYOND THIS POINT ---

## Saving, Loading and Persistence - Scene Management
- Save states are saved per default in dir "user://"
- Player state and scene states are saved separately. That way the player save doesn't bloat with game size and there's some other minor comforts. 
- Currently the following objects are saved:
  - Cogito_Pickup.gd / Cogito_Carriable.gd: Since their existence in the scene can vary, these will be re-instantiated at their saved position if a scene state is loaded. Thus they need to be PackagedScenes to work!
  - Cogito_Door: These will have their state saved (open/closed/locked)
  - Cogito_Switch: These will have their state saved (on/off)
- The following is still WIP or are not being saved:
  - Destructable objects like the target.


## Interactables
Interactables consider of two major parts: The object itself and the InteractionComponents attached as child nodes to define what kind of interactions can be done.
*Object setup:*
- Create a Node or Scene that fits your needs. In general it needs to have a 3D collision shape and be on collision **layer 2** for the raycast to detect it.
- Either create your own script or attach one of the included ones:
  - Cogito_Door: For doors, gates, platforms, bridges.
  - Cogito_Object: For pick ups, props, etc.
  - Cogito_Button: Used for simple triggers. Can be one-time-use or repeated use.
  - Cogito_Switch: For switchable objects like lamps or buttons.
  - Cogito_Turnwheel: More niche, used for objects that rotate, usually combined with a Hold interaction.

*Interaction Component setup:*
COGITO has a handful of basic interaction components that you can simply attach to your object to add interactivity. These need to be child nodes of your object in order to be detected by the interaction system.
You can use these to define what input map actions will be used in addition to more common custom behaviour. COGITO includes input map action for 2 interactions, so usually you don't want more than those attached to your objects.
But as long as you define input map actions for them, you can attach as many interactions to your objects as you want.
- BasicInteraction: This is your "press X to interact" component. All doors and switch objects work with this.
- HoldInteraction: Attach this component to require the player to hold a button for a certain amount of time. Includes a small UI bar.
- CarryableComponent: Attach this to your object to make it carryable. Includes the required AudioStreamPlayer3D.
- PickupComponent: Attach this to your object to make it a pickup. You need to define the inventory item your pick up represents.


### Creating your own interactables
If you want to set up your own, just create a 3D Node that has a Collision Shape on Layer 2. Then use the Cogito_Object.gd script as a basis.
This script contains the minimum required functions and variables to work with the interaction system and the interaction components.
You can also use the *CustomInteraction* component to call specific functions in the script of your object.



### Cogito_Switch.gd
This is used to create interactive objects with a clear on/off state. Most common examples are lamps and lights.
It works by going through a list of nodes and flipping their visible state every time the player switches the object.
PRO-TIP: The objects you switch do not have to be part of the switchable object. For example if you wanna have a ceiling lamp that is controlled by a light switch, make the light switch the switchable and add all the ceiling lamps to the objects to switch list.

**Settings:**
- Is On: Start state of the switchable.
- Interaction Text When On: Self explanatory.
- Interaction Text When On: Self explanatory.
- Switch sound: AudioStream that gets played when switched.
- Needs item to Operate: If this is on, the player can only switch this if the required item is in their inventory.
- Required item: Self explanatory.
- Item hint: Gets displayed if the player does NOT have the required item in their inventory.
- Objects toggle visibility: Array of NodePaths. Add all the nodes of your scene that will get their visibility flipped when switched. Please not that the nodes current status is assumed as the start status.
  For example: If you add a SpotLight node and you want the light to be OFF as its initial state, you need to hide the light. If you want the light to be ON as it's initial state, the Spotlight needs to be visible and is_on should be flagged.
- Objects Call Interact: Array of NodePaths. Add all the nodes you want to call interact on. For example if you add a door here, the door gets opened/closed when you interact with the switchable.


### Cogito_Hold.gd
This is used to create interactive objects on which you need to hold the interact button for a specific amount of time.
Needs to have a CollisionShape3D and AudioStreamPlayer3D. Collision should be set to layer 2 so the Player Interaction system can pick it up. This one also has/needs a Control node for the "Hold UI", displaying whatever
you want while the player interacts with it. The PressAndHold PrefabScene includes a typical progressbar that shows how long the player still needs to hold the button.
If the player lets go of the button before the required time, the timer resets.
If the player succeeds in holding the button the required time, the "interact" function on all the objects specified in the Objects To Trigger nodepath will be called. This way, the object can easily be hooked up to other
interactables like switchables or doors.

**Settings:** 
- Interaction Text: The text displayed for the player interaction.
- Hold time: The duration the interaction button will need to be held in seconds.
- Rotate While Holding: Check this if you want the press_and_hold object to rotate while the player holds the button. For wheels/cranks etc.
- Rotation Axis: Set the axis you want the object to rotate to 1, leave all the others to 0.
- Rotation Speed: Self explanatory.
- Objects to Trigger: Array of nodepaths to all the nodes who will get their "interact" function called once the hold interaction was successful.
- Hold Audio Stream: Audiostream to play while player is holding.


### CarryableComponent.gd
This is used for boxes, crates etc. Note that the carryable is dropped if it touches the player to avoid physics glitches. Adjust your hold distance if you're having trouble.

**Settings:**
- Interaction Text: What appears when the player aims the crosshair at the carryable.
- Pick up Sound: Plays when player picks up the carryable.
- Drop Sound: Plays when player drops up the carryable.
- Hold distance: How close the carryable is being held to the player. Tweak this depending on your carryable size. 1 = raycast interaction length (2.5m by default). 0.75 feels pretty good for most objects. Be aware that objects might collide with the player collider if this is set too close.
- Lock Rotation when carrying: Set if the object should not rotate when being carried. Usually true is preferred.
- Carrying velocity multiplier: Sets how fast the carryable is being pulled towards the carrying position. The lower, the "floatier" it will feel.


### Item pick ups:
See under **Inventory** below on how pick ups are setup.


### Cogito_Door.gd
I recommend just making a copy of the included Door Prefab and modifying it to fit your needs. But you can also set up doors yourself by creating a AnimatableBody3D with your mesh etc in it as well as a Collision shape and an AudioStreamPlayer3D. Make sure it is set to layer 2 so the Player Interaction raycast can pick it up.
Then attach the **Interact_Door.gd** to your AnimatableBody3D.
**Pro Tip:** If you want to make a door that's triggered by a different object (like a remote switch), just DON'T attach any Interaction Components. Instead set a reference to your door at your other object (like a switch or turnwheel). See the draw bridge in the test scene for an example.

**Settings:**
- Audio:
  - Open Sound: Plays when the door opens. Uses the AudioStreamPlayer3D.
  - Close Sound: Plays when the door closes. Uses the AudioStreamPlayer3D.
  - Rattle Sound: Plays when player attempts to interact with locked door. Uses the AudioStreamPlayer3D.
  - Unlock Sound: Plays when the player interacts with the door status changes from locked to unlocked. Uses the AudioStreamPlayer3D.
  
- Door Parameters:
	Interaction text when locked: Sets the text that appears if the player crosshair hovers over the door object when door is locked.
  - Interaction text when closed: Sets the text that appears if the player crosshair hovers over the door object when door is closed.
  - Interaction text when open: Sets the text that appears if the player crosshair hovers over the door object when door is open.
  - Is locked: Set the locked stats of the door.
  - Key: Reference to the item that needs to be in the player's inventory to unlock the door. Hint: This can be any item resource, doesn't need to be of type KEY_ITEM.
  - Key hint: The hint that appears if player tries to open the door but doesn't have the key item. If this is empty, no hint will appear.
  - Doors to sync with: Array of NodePaths who will sync to this door's state (open/close/locked). Useful for double doors, multi-part gates, etc.
  - Tween Parameters - use these if your door animation is tween based.
	- Is Sliding: Set this to true, if your door is sliding instead of rotating (using position parameters instead of rotation parameters)
	- Use Z Axis: Sets which rotation axis to use. True = Use Z axis. False = Use Y axis.
	- Bidirectional Swing: If true, the door will change rotation direction, depending on which side it is opened from.
	- Open Rotation Deg: Sets object rotation for open position. In global degrees, this matches/influences the door object transform.
	- Closed Rotation Deg: Sets object rotation for closed position. In global degrees, this matches/influences the door object transform.
	- Door Speed: Speed of opening/closing.
  - Animation Parameters - use these if your door animation is tween based.
	- Is Animation Based: Set this to true if your door uses an Animation Player with animations (instead of tweens)
	- Animation Player: Assign your Animation Player node.
	- Opening Animation: String name of your opening animation that's present in the animation player.
	- Reverse Opening Animation for close: If set to true, the opening animation will be played in reverse when the door is closed.
	- Closing Animation: String name of your closing animation that's present in the animation player.


## Inventory System
The inventory system is largely resource based. The inventory system and the inventory UI are independent form each other. UI elements get updated via signals.

### Overview
The Inventory System contains of 3 main resources:
Items -> Slots -> Inventories.

- Inventory item: Resource that contains all the parameters pertaining to a specific item.
- Slot: The "container" for an item and manages stuff like item stacks, moving items, dropping items, etc.
- Inventory: This resource is a collection of slots. Can vary in size. Per default, the Player has an inventory attached. Also used for containers.


### InventoryItemPD
- Item Type: Defines how this item is treated for certain interactions.
  - Consumable: This item changes a player attribute on use. Usually used for items like health potions, etc.
  - Wieldable: This item can be "held" by the player. Used for Flashlight but also for stuff like weapons.
  - Combinable: Item that can be combined with another item to create a new one.
  - Key: Used as an item used with interactables like doors or switchers. They will check if said item is in the player inventory and only work if it is. Can be set to be discarded after use.
  - Ammo: Used to reload/recharge wieldables. For examples Batteries are Ammo for the Flashlight.
- Name: What the item is called in the HUD.
- Description: Displayed when selected in the inventory UI. Shouldn't be longer than 2 lines (for now).
- Icon: The icon that is displayed in the Slot UI and on certain hint notifications.
- Power: A value that is used when the item is used. This is very ambiguous and will prob be renamed.
- Is Stackable: Flag if an item can be stacked. Usually you don't want this for wieldables.
- Stack size: How many items can be stacked max. If this is exceeded, the item will need to be put in it's own slot.
- Use sound: String that plays that sound from the AudioManager on use, if it is found.
- Drop Scene: Path to the pick up prefab scene that spawns in the game world when the player drops an item. See also: **Pick Up**
- Hint Icon on Use: Icon that is used for the hint that is displayed when the item is used. If left empty, the default hint icon will be used.
- Hint Text on Use: Text that is displayed for the hint that is displayed when the item is used. If left blank, no hint will be displayed.
- Audio:
  - Sound Use: Plays when an item is used.
  - Sound Pickup: Plays when the player picks up this item.
  - Sound drop: Plays when the player drops this item from their inventory.


- Consumable settings:
  - Attribute Name: String that is sent to Player script to change the according attribute. For example, enter "health", and the player current health will be increased by the power value. "health_max" will increase the maximum health of the player.
	This gets sent to the player.gd script, if you want to edit this.
  - Attribute Change amount: The value the given attribute will be influenced by. Can be positive or negative.

- Wieldable settings:
  - Primary Use Prompt: Text that is displayed in the HUD for primary action (left mouse click, gamepad right trigger). Usually stuff like shoot, toggle on/off.
  - Secondary Use Prompt: Text that is displayed in the HUD for secondary action (right mouse click, gamepad left trigger). Stuff like aim down sight, melee with flashlight, look through binoculars.
  - Wieldable Data Icon: Icon that is displayed in the HUD next to the item's data when item is wielded. Used for showing a battery icon on the Flashlight, or a magazine icon for the ammo display.
  - Charge Max: Charge refers to the highest value this wieldable can contain. Examples: flashlight battery capacity or weapon magazine capacity.
  - Ammo Item Name: Name of the item that can be used to charge this item. String needs to be an exact match. THIS DOESN'T ACTUALLY SET WHICH AMMO ITEM CAN RECHARGE THIS WIELDABLE. This info here is used to scan the player inventory for this item and displays the carried amount in the PlayerHUD.
  - Charge current: The current charge. Examples: Flashlight current battery level. Amount of bullets left in the magazine.
  - Wieldable Range: Used for hitscan weapons for some calculations. Also necessary for melee weapons.
  - Wieldable Damage: Damage value that is applied to HealthComponents of Objects with an HitboxComponent.
  - Animations: Pretty self-explanatory. String-based names of the animations that will be called on the WieldableAnimationPlayer inside the Player Scene.

- Combinable settings:
  - Target Item Combine: Name of the item that can be used to charge this item. String needs to be an exact match.
  - Resulting Item: InventoryItemSlot that contains the item and the quantity that gets added to the player inventory on combining this item with the target item. Warning: If you're creating a stackable item, there might be issues with uniqueness of the resource. Need to do some testing.
	
- Key settings:
  - Discard after use: Bool. If this is checked, the item will be destroyed after it's been used on a door.
  - HINT: If you're looking for where to set up which door this key opens: This reference is set on the door object itself.
  
- Ammo settings:
  - Target Item Ammo: The Item resource this item is ammo for. (Example: If you're editing the Battery item, then you would define the Flashlight here.) Need to update this to an array so one Ammo item can be used as ammo for different kinds of wieldables.
  - Reload amount: How much one item adds to the charge of the target item. For Bullets this is typically 1. But for example a Battery should probably add a higher amount to the charge of the Flashlight.


### PickupComponent
Use this component to create items that are added to the players inventory.
I usually create this _before_ I create the item resource, but it doesn't matter, as long as the references are set.

The basic idea is this:
Pick up = this is how the item exists in the 3D world.
Item = this is how it exists within the inventory system.

The two reference each other: Packed Scene <-> Inventory Item resource
**Note: Make sure that the Slot Data resource on your pick up is set to "Local to Scene ON", especially on stackable items. If not, instances of this item will share the same slot resource, causing wrongly calculated item quantities.**

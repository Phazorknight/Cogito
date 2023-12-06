![COGITO_Card](https://github.com/Phazorknight/Cogito/assets/70389309/c9928f69-9e2e-4446-b93b-9b8c0fd039bf)
# COGITO
Version: **Alpha 202312c**
Runs on Godot **4.1.2 stable**

COGITO is a first Person Immersive Sim Template Project for Godot Engine 4.
In comparison to other first person assets out there, which focus mostly on shooter mechanics, COGITO focuses more on
providing a framework for creating interactable objects and items.

**Credits:**
- Player controller is based on Like475's First Person Controller Advanced: https://github.com/Like475/fpc-godot
- Menus are based on SavoVuksan's EasyMenus (also see this link for documentation): https://github.com/SavoVuksan/EasyMenus
- Inventory system was helped by following DevLogLogan on Youtube: https://www.youtube.com/watch?v=V79YabQZC
- InputHelper by Nathan Hoad (also see this link for documentation): https://github.com/nathanhoad/godot_input_helper

## Overview
### Current working features:
- First person player controller
- Main Menu + Pause Menu
- Basic AudioManager for playing common sounds (needs rework)
- Player attributes (component based)
  - Health
  - Stamina
  - Sanity (drains if not within Safezones)
  - Brightness (aka visibility goes up within Lightzones, cumulative to a limit)
- Raycast Interaction system
- Included Prefabs for:
  - Carryable crate
  - Door (unlockable)
  - Lamp (switchable)
  - Chest (item container)
  - Hazard Zone (Area3D that drains a player attribute)
  - Items:
	- Flashlight (combine with batteries to recharge)
	- Battery (used to recharge Flashlight by combining them)
	- Health Potion
	- Stamina extension potion (increases max stamina)
	- Key to unlock door

### Known bugs:
- The current implementation for the InputHelper broke the Mouse Interaction with Inventory Items. (Items can be used by right click, but no longer picked up and dropped by mouse left click.)
- No collision check for carryables, wieldables or when you drop items. All of these can clip through walls if you stand too close to them.
- Inventory / items:
  - Sometimes stackable item counts gets tripped somehow, resulting in picking up one item, but the stack goes up by 2, etc.
- Wieldables:
  - Gamepad: Primary use trigger needs refining as the analog input causes multiple triggers.

### Still to do:
- Pause/Options Menu:
  - Invert Y toggle doesn't work yet. But can be set in the Player.gd script in the inspector.
- Player Attributes:
  - Action points (low prio)
- Interactables:
  - Door: Improve door rotation inspector settings
  - Door: Create option to make sliding door
- AudioManager is unwieldy. Can probably be redone to work better.
 

## Set-Up
It is recommended to use the whole project as a starting point for your game, though everything needed should be contained within the COGITO folder within the project.

Make sure that two Autoloads are set up in your project:
- //COGITO/AudioManagerPD/Autoload/AudioManagerPD.tscn
- //COGITO/EsayMenus/Nodes/menu_template_manager.tscn

Make sure you have this plug-in set up in your project:
- Input Helper (currently v4.2.2)

**Open and run res://COGITO/DemoScenes/COGITO_Demo_01.tscn to try out everything that comes with COGITO**


### Scene set-up
To fully work, you need 3 Prefab Scenes in your scene + the following references set up in their inspector:
- player.tscn
  - Reference to Pause Menu node
  - Reference to Player_HUD node
- Player_HUD.tscn
  - Reference to player node
- PauseMenu.tscn

All signals needed get hooked up via code, so this should work without any extra signal setup.
PauseMenu and MainMenu Scenes contain SceneSwitchers that need paths to the *.tscn files to work.
Also be aware of node order for Player_HUD and PauseMenu. Player_HUD node should be above PauseMenu node, so PauseMenu is "on top". 

## Interactables
For an interactable to work, it needs to be a 3D collision shape and be on **layer 2** for the raycast to detect it. Then simply attach one of the provided scripts, set some parameters and you're good to go.
Feel free to create new kinds of interactables based on the scripts provided.

### Creating your own interactables
If you want to set up your own, just create a 3D Node that has a Collision Shape on Layer 2. Attach a script that has a function called "interact" and which gets passed the player.
It should also have a string variable called "interaction_text" which contains what the HUD displays when the player interaction raycast hits it.

So the most basic script would look like this:
```
@export var interaction_text : String = "Interact with me"

func interact(playernode):
	# What happens when player interacts.
	pass
```

### switchable.gd
This is used to create interactive objects with a clear on/off state. Most common examples are lamps and lights.
Needs to have a CollisionShape3D and AudioStreamPlayer3D. Collision should be set to layer 2 so the Player Interaction system can pick it up.
It works by going through a list of nodes and flipping their visible state every time the player switches the object.
PRO-TIP: The objects you switch do not have to be part of the switchable object. For example if you wanna have a ceiling lamp thats controlled by a lightswitch, make the lightswitch the switchable and add all the ceiling lamps to the objects to switch list.

**Switchable settings:**
- Is On: Start state of the switchable.
- Interaction Text When On: Self explanatory.
- Interaction Text When On: Self explanatory.
- Switch sound: AudioStream that gets played when switched.
- Objects to Switch: Array of NodePaths. Add all the nodes of your scene that you want to get switched here. Each node added will get their visibility flipped when switched. Please not that the nodes current status is assumed as the start status.
  For example: If you add a SpotLight node and you want the light to be OFF as its initial state, you need to hide the light. If you want the light to be ON as it's initial state, the Spotlight needs to be visible and is_on should be flagged.


### Carryable.gd
This is used for boxes, crates etc.
Needs to have a CollisionShape3D and AudioStreamPlayer3D. Collision should be set to layer 2 so the Player Interaction system can pick it up.

**Carryable Settings:**
- Interaction Text: What appears when the player aims the crosshair at the carryable.
- Pick up Sound: Plays when player picks up the carryable.
- Drop Sound: Plays when player drops up the carryable.

### Item pick ups:
See under **Inventory** below on how pick ups are setup.

### Doors
I recommend just making a copy of the included Door Prefab and modifying it to fit your needs. But you can also set up doors yourself by creating a AnimatableBody3D with your mesh etc in it as well as a Collision shape and an AudioStreamPlayer3D. Make sure it is set to layer 2 so the Player Interaction raycast can pick it up.
Then attach the **Interact_Door.gd** to your AnimatableBody3D.

**Interact_Door Settings:**
- Audio:
  - Open Sound: Plays when the door opens. Uses the AudioStreamPlayer3D.
  - Close Sound: Plays when the door closes. Uses the AudioStreamPlayer3D.
  - Rattle Sound: Plays when player attempts to interact with locked door. Uses the AudioStreamPlayer3D.
  - Unlock Sound: Plays when the player interacts with the door status changes from locked to unlocked. Uses the AudioStreamPlayer3D.
  
- Door Parameters:
  - Interaction text: Sets the text that appears if the player crosshair hovers over the door object.
  - Is locked: Set the locked stats of the door.
  - Key: Reference to the item that needs to be in the player's inventory to unlock the door. Hint: This can be any item resource, doesn't need to be of type KEY_ITEM.
  - Key hint: The hint that appears if player tries to open the door but doesn't have the key item. If this is empty, no hint will appear.
  - Open Rotation: Sets object rotation for open position. In global radians, not great, needs improvement.
  - Closed Rotation: Sets object rotation for closed position. In global radians, not great, needs improvement.
  - Door Speed: Speed of opening/closing.


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
- Name: What the item is called in the HUD.
- Description: Displayed when selected in the inventory UI. Shouldn't be longer than 2 lines (for now).
- Icon: The icon that is displayed in the Slot UI and on certain hint notifications.
- Power: A value that is used when the item is used. This is very ambigious and will prob be removed.
- Is Stackable: Flag if an item can be stacked. Usually you don't want this for wieldables.
- Stack size: How many items can be stacked max. If this is exceeded, the item will need to be put in it's own slot.
- Use sound: String that plays that sound from the AudioManager on use, if it is found.
- Drop Scene: Path to the pick up prefab scene that spawns in the game world when the player drops an item. See also: **Pick Up**
- Hint Icon on Use: Icon that is used for the hint that is displayed when the item is used. If left empty, the default hint icon will be used.
- Hint Text on Use: Text that is displayed for the hint that is displayed when the item is used. If left blank, no hint will be displayed.

- Consumable settings:
  - Attribute Name: String that is sent to Player script to change the according attribute. For example, enter "health", and the player current health will be increased by the power value. "health_max" will increase the maximum health of the player.
	This gets sent to the player.gd script, if you want to edit this.

- Wieldable settings:
  - Primary Use Prompt: Text that is displayed in the HUD for primary action (left mouse click, gamepad right trigger). Usually stuff like shoot, toggle on/off.
  - Secondary Use Prompt: Text that is displayed in the HUD for secondary action (right mouse click, gamepad left trigger). Stuff like aim down sight, melee with flashlight, look through binoculars.
  - Wieldable Data Icon: Icon that is displayed in the HUD next to the item's data when item is wielded. Used for showing a battery icon on the Flashlight, or a magazine icon for the ammo display.
  - Charge Max: Charge refers to the highest value this wieldable can contain. Examples: flashlight battery capacity or weapon magazine capacity.
  - Charge current: The current charge. Examples: Flashlight current battery level. Amount of bullets left in the magazine.
	
- Combinable settings:
  - Target item: Reference to item resource this item can be combined with. If this item is a Battery, then the target item would be the Flashlight for example. If this was pistol ammo, then the target item would be the Pistol.
	
- Key settings:
  - Discard after use: Bool. If this is checked, the item will be destroyed after it's been used on a door.
  - HINT: If you're looking for where to set up which door this key opens: This reference is set on the door object itself.
  
### Pick_up.gd
Use this script to create items that are added to the players inventory.
I usually create this _before_ I create the item resource, but it doesn't matter, aso long as the references are set.

The basic idea is this:
Pick up = this is how the item exists in the 3D world.
Item = this is how it exists within the inventory system.

The two reference each other: Pick Up scene <-> Inventory Item resource

### Pickup_Flashlight.gd
Used for the Cogito_Flashlight item/prefab. Use the one provided or attach this script to your own flashlight model.


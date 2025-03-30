![COGITO_banner](docs/Cogito_capsule_202402_jpg.jpg)
# COGITO
[![GodotEngine](https://img.shields.io/badge/Godot_4.4_stable-blue?logo=godotengine&logoColor=white)](https://godotengine.org/) [![COGITO](https://img.shields.io/badge/version_1.1.0-35A1D7?label=COGITO&labelColor=0E887A)](https://github.com/Phazorknight/Cogito)

## What is it?
COGITO is a first Person Immersive Sim Template Project for Godot Engine 4.
In comparison to other first person assets out there, which focus mostly on shooter mechanics, COGITO focuses on
providing a framework for creating interactable objects and items.

## [Full documentation here!](https://cogito.readthedocs.io/en/latest/index.html)

## Current Features
- First person player controller with:
  - Sprinting, jumping, crouching, sliding, stairs handling, ladder handling, sitting
  - Lots of exposed properties to tweak to your liking (speeds, headbob, fall damage, bunnyhop, etc.)
  - Easy-to-use dynamic footstep sound system
- Player Attribute System
  - Health, Stamina, Visibility for stealth, etc
  - Customize how attributes get displayed in the HUD (or stay hidden)
  - Also useable for RPG-like attributes (Strength, Wisdom, etc)
  - Interactions can check attributes (eg. you can only lift a box if you're strong enough)
- Interaction System
  - Component-based interactions makes it easy to turn your own objects interactive quickly and customize existing ones
  - Examples for interactive objects like doors, drawers, carryables, turn-wheels, elevators, readable objects, keypads
- Inventory System
  - Flexible resource-based inventories
  - Inventory UI separate from inventory logic
  - Examples for multiple item types (consumables, keys, ammo, weapons, combinable Items)
  - Base class to easily add your custom item types
- Basic Enemy
  - NavigationAgent based enemy with a simple state machine
  - Simple player detection system that uses detection areas + basic line-of-sight checks
- Full gamepad support!
- Systemic Properties (wet/dry, flammable/on fire, soft, etc) (very WIP)
- Basic Quest System
- Save and Load System as well as scene persistency

- Fully featured Demo Scene
  - Set up like a game level including a variety of objects, weapons and quests
  - Demo scenes contains hints that explain how objects in the scene were set up

COGITO is made by [Philip Drobar](https://www.philipdrobar.com) with help from [these contributors](https://github.com/Phazorknight/Cogito/graphs/contributors).

## Principles of this template
The structure of this template always tries to adhere to the following principles:
- **Complete**: When you download COGITO and press play, you get a functioning project out of the box. Game menu, save slot select, options and a playable level are all included.
- **Versatile**: Whether your game is set in the future, the past or the present, use melee, projectile or no weapons at all, have low poly, stylized or realistic graphics, the template will have features for you.
- **Modular**: Do not want to use a feature? You will be able to hide it, ignore it or strip it out without breaking COGITO. At the same time, COGITO is designed to be extendable with your own custom features or other add-ons.
- **Approachable**: While there will always be a learning curve, we strive to make COGTIO approachable and intuitive to use, so it doesn't get in your way of making your game.

> [!IMPORTANT]  
> COGITO v1.1 is not 100% bug-free. While most features are set, be aware that this is hobbyist open source software. Use at your own risk and check Issues and Discussion pages for more information.

[Credits, Contributors and License](https://cogito.readthedocs.io/en/latest/about.html)

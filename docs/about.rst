About
============

Welcome to COGITO
-----------------
COGITO is a first Person Immersive Sim Template Project for Godot Engine 4. 
In comparison to other first person assets out there, which focus mostly on shooter mechanics, COGITO focuses on providing a framework for creating interactable objects and environments.

COGITO is a fully featured template. It is recommended to use this as the starting point of your project BEFORE implementing any of your own features. We strongly recommend playing through the included demo scenes to get a good impression of what functionality is included. While COGITO is designed with modularity and versatility in mind, it is usually easier to modify the included systems than try to make it work with other external systems (like using a different inventory system or player controller). The most common tasks most users will run into is adapting their own assets and levels to work with COGITO. I'm in the process of creating video tutorials for these cases, which should help you get started quickly.

Guiding principles
------------------
The structure of this template always tries to adhere to the following principles:

* **Complete:** When you download COGITO and press play, you get a functioning project out of the box. Game menu, save slot select, options and a playable level are all included.
* **Versatile:** Whether your game is set in the future, the past, or the present, uses melee, projectile or no weapons at all, has low poly, stylized or realistic graphics, the template will have features for you.
* **Modular:** Don't want to use a feature? You will be able to hide it, ignore it or strip it out without breaking COGITO. At the same time, COGITO is designed to be extendable with your own custom features or other add-ons.
* **Approachable:** While there will always be a learning curve, we strive to make COGTIO approachable and intuitive to use, so it doesn't get in your way of making your game.


Current Features
----------------
* First person player controller with:
   * Sprinting, jumping, crouching, sliding, stairs handling, ladder handling
   * Fully customizable attributes like Health, Stamina, Visibility (for stealth) - Component-based, so easy to add your own.
   * Lots of exposed properties to tweak to your liking (speeds, head bob, fall damage, bunny hop, etc.)
   * Easy-to-use dynamic footstep sound system
* Inventory System
   * Flexible resource-based inventories
   * Inventory UI separate from inventory logic
   * Examples for multiple item types (consumables, keys, ammo, weapons, combinable Items)
   * Base class to easily add your custom item types
   * Basic currency systems + vendors to buy items from
* Interaction System
   * Component-based interactions makes it easy to turn your own objects interactive quickly and customize existing ones
   * Examples for interactive objects like doors, drawers, carryable boxes, turn-wheels, elevators, readable objects, keypads, etc.
* Wieldable System
   * System for the player holding and using items, traditionally used for weapons.
   * Examples for projectile weapon, raycast weapon, throwable weapon, flashlight and animated consumable.
* Basic Enemy with a simple state machine
* Basic Quest System
* Systemic Properties (WIP)
   * Give objects properties like "FLAMMABLE" or "WET" and they will interact with each other depending on their state and properties.
   * For example FLAMMABLE objects can be ignited by objects that are actively on fire. Can be extinguished by objects that are WET.
   * Straight forward system to add your own properties and behaviors, all handled in one script. Also, easy to just ignore.
* Fully featured Demo Scene
   * Set up like a game level including a variety of objects, weapons, and quests
   * In-game helper documents that explain how objects in the scene were set up
* Options menu + rebindable inputs
* Save slot-based save and load system + level scene persistency
* Full gamepad support!


Contributors
------------
* `AC-Arcana <https://github.com/ac-arcana>`_: added DynamicFootstepSystem
* `pcbeard <https://github.com/pcbeard>`_: Performance tweaks and bug fixes.
* `FailSpy <https://github.com/FailSpy>`_: improved input handling as well as UI and Player Controller quality-of-life fixes.
* `kk1201 <https://github.com/kk1201>`_: improving Lightzone component.
* `aronand <https://github.com/aronand>`_: improvements to Player Interaction system
* `PeterD23 <https://github.com/PeterD23>`_: added Grid Inventory
* `niefia <https://github.com/niefia>`_: added Sitting feature, improvements to enemy behavior, interaction components, audio, physics and more
* `mrezai <https://github.com/mrezai>`_: improvements and bugfixes to scene transitions, wieldables, player physics and raycasts
* `OvercastInteractive <https://github.com/OvercastInteractive>`_: added vendor feature, various improvements and fixes
  

|

* Player controller is based on `Like475's First Person Controller Advanced <https://github.com/Like475/fpc-godot>`_
* Menus are based on `SavoVuksan's EasyMenus (also see this link for documentation) <https://github.com/SavoVuksan/EasyMenus>`_
* Inventory system was helped by following `DevLogLogan on Youtube <https://www.youtube.com/watch?v=V79YabQZC1s>`_
* `InputHelper by Nathan Hoad (also see this link for documentation) <https://github.com/nathanhoad/godot_input_helper>`_
* `QuickAudio by Bryce Dixon <https://github.com/BtheDestroyer/Godot_QuickAudio>`_
* Stairs handling based on `GodotStairs by elvisish <https://github.com/elvisish/GodotStairs>`_
* Cogito Quest System based on `shomykohai's Godot 4 quest system. <https://github.com/shomykohai/quest-system>`_


Credits
-------
* This add-on is published under the MIT license.
* You can use this add-on in your projects, personal or commercial, as long as you credit us (mostly cause we'd love to see what people use it for!)

|

* About the game assets under the COGITO/assets folder:
   * 3D models are by `Kenney <https://www.kenney.nl/>`_ or `Philip Drobar <https://www.philipdrobar.com/>`_.
   * NPC animations are by `Quaternius <https://quaternius.itch.io/universal-animation-library/>`_ under CC0
   * Audio is either by `Kenney <https://www.kenney.nl/>`_ or from `freesound.org <https://freesound.org/>`_ used under CC0 or MIT license
   * `Alarm Siren.wav by mirkosukovic <https://freesound.org/s/435666/>`_ -- License: Attribution 4.0
   * `Match strike by Bertsz <https://freesound.org/s/524306/>`_ -- License: Creative Commons 0
   * `Running Water by Poyekhali <https://freesound.org/s/241842/>`_ -- License: Attribution 3.0
   * `Dirt Sliding.wav by Laughingfish78 <https://freesound.org/s/537275/>`_ -- License: Creative Commons 0
   * `FIREBurn_Fireplace.Artificial.Crackling.Roar by newlocknew <https://freesound.org/s/641848/>`_ -- License: Attribution NonCommercial 4.0
   * `Water steaming on hot surface #1 by Ekrcoaster <https://freesound.org/s/666290/>`_ -- License: Creative Commons 0
   * Cloud HDR (kloofendal_48d_partly_cloudy_puresky)2k.hdr by Greg Zaal, used under CC0.
   * All other included assets either made by `Philip Drobar <https://www.philipdrobar.com/>`_ or one of the contributors, published under MIT.


MIT License
-----------

Copyright © 2024 Phazorknight + Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
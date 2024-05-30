Getting started
===============

Installation
------------

It is strongly recommended to use the COGITO Project as your base Godot project, as it comes
with a few pre-configured settings like Input Maps and Autoloads.
After installation, you can import your own assets and get started making your game.

Installation steps:

#. Clone this repo or download it and unzip it into it's own directory.
#. Open the project with the Godot editor (make sure you use a compatible version, currently 4.2.1)


Setup
-----

Confirm your project is setup as follows

#. Make sure the following plug-ins are activated:
#. Quick Audio (currently v1.0)
#. Input Helper (currently v4.2.2)
#. Also Make sure the following Autoloads are set up in your project:

   * res://COGITO/EsayMenus/Nodes/menu_template_manager.tscn
   * res://COGITO/SceneManagement/cogito_scene_manager.gd
   * res://COGITO/QuestSysteemPD/CogitoQuestManager.gd

#. Make sure that the Main Scene is set to ``res://COGITO/DemoScenes/COGITO_0_MainMenu.tscn``. This is not strictly necessary, but will make sure the Demo project runs as expected.


Running the Demo scenes
-----------------------

#. You can find all included Demo scenes within ``/COGITO/DemoScenes/`` but if you've followed the steps above you can also just run the project by pressing ``F5`` and it should start at the Main Menu.
#. You can also run the ``Lobby`` or the ``Laboratory`` scenes directly and explore.

Feel free to explore the Demo scenes to discover everything COGITO has to offer!
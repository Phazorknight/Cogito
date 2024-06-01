Frequently Asked Questions
==========================

My question isn't answered here?
--------------------------------

* If you have a feature request, please post in the `Discussions <https://github.com/Phazorknight/Cogito/discussions>`_ page on the GitHub repo.
* If you have found a bug, please create an Issue on the GitHub `Issues <https://github.com/Phazorknight/Cogito/issues>`_ page.
* This FAQ is still a work in progress, but I try to add answers to the most common questions as they come up.

How do I set the main menu to start/load my own level scene?
------------------------------------------------------------

Open the ``main_menu.tscn`` and find the ``MainMenu_SaveSlotManager`` node. There you can set a ``path`` to the scene you want to load first when a new game is started.

.. image:: cog_ChangeGameScene.JPG
    :alt: COGITO Change Game Scene

My own objects aren't working!
------------------------------

There are a few reasons for them to not be working, so here's a checklist:

* Make sure your interactive object has a ``CollisionShape3D`` and is set to the right layers.
* Make sure your interactive object is a ``Cogito_Object`` or similar (``Cogito Door``). This is necessary for Cogito's interaction system to pick it up.
* Make sure you have interaciton components attached to the root node of your object. Use a default included component to make sure it works (``CarryableComponent`` is the quickest)
* Make sure your object is saved as it's own scene. It is not strictly necessary for all object-types, but can help with some issues.

How do I get a reference to the player?
---------------------------------------

There are multiple ways to get a reference to the player node.
* Pass the player node directly with your signal/method. For example, if you use a node that has body_entered / body_exited signals, then these signals pass a ``body`` argument which references the node. You can then easily check if it's in the group "Player" to make sure you have the player node.
* Find the node that's in the "Player" group.
* In a pinch you can use the CogitoSceneManager. The CogitoSceneManager autoload saves a reference to the current player and current cogito scene. These get updated whenver a cogito scene loads. To reference the player in a script this way, write ``CogitoSceneManager._current_player_node`` and ``CogitoSceneManager._current_scene_root_node``.
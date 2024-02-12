# Dynamic Footstep System for Cogito
By AC-Arcana

## player.gd
The player was modified to suppor this system. There is an assignable variable in audio for a Footstep Surface Detector. If this is not assigned, the footsteps will fallback to the generic system that was already in the player script.

## Player scene
This example includes its own player scene. There is just one script added to the FootstepPlayer node. The script is a Footstep Surface Detector.

## Footstep Surfcae Detector
It uses a ray query to find the collider below the player. The ray is cast 1 meter from the point of the node the script is assigned to. It is called by the player script. It must be on an AudioStreamPlayer3D
- Generic Fallback Footstep Profile - If detection for a footstep sound fails, this sound profile will be used
- Footstep Material Library - If assigned, the system will look up any material the player is standing on in this library to find a footstep profile for it. If a material is not found in the library, it will fall back to the generic fallback footstep profile

### Footstep Profile
The profiles are not a new class. They are an AudioStreamRandomizer. I recommend saving these as resources.

- To create a new one:
  - Right click in the FileSystem, Create New -> Resource
  - Find AudioStreamRandomizer (I like to type random in the search bar)

- To assign footstep sounds:
  - Select the Footstep Profile Asset
	- You can adjust random pitch and random volume here
  - Expand the "Streams" accordion
	- Here you can add or remove elements. Each of the added elements will be selected from randomly.
	- You also can adjust their weights individually. Higher weights are more likely to be selected

### Footstep Surface
When placed on an object in the scene it will determine what footstep sounds will be played when stepping on that object.
You must assign a footstep profile or you will get a generic footstep sound.

### Footstep Material Library
A resource that contains an array of Footstep Material Profiles. I recommend saving this as a resource.
The Footstep Material Profiles don't necessarily have to be saved as resources, they can be created inside the Footstep Material Library.

### Footstep Material Profile
Contains a material and a Footstep Profile. When the specified material is detected the specified Footstep Profile will be used.

### Sound Attributions
All sounds used in the DynamicFootstepSystem are CC0 and taken from freesound.org
- Dirt: https://freesound.org/people/HenKonen/sounds/682127/
- Grass: https://freesound.org/people/HenKonen/sounds/682128/
- Stone: https://freesound.org/people/xmike80x/sounds/706207/
- Wood: https://freesound.org/people/SpliceSound/sounds/150444/

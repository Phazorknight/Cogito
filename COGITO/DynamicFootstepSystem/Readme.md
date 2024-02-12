# Dynamic Footstep System for Cogito
By AC-Arcana

## Footstep Surface Detector
This is in the default player scene.
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
When this script is attached to an object in the scene it will determine what footstep sounds will be played when stepping on that object.
You must assign a footstep profile or you will still get a generic footstep sound.
These can also be assigned to children in the case of a StaticBody3D or Rigidbody3D

### Footstep Material Library
A resource that contains an array of Footstep Material Profiles. I recommend saving this as a resource. 
You can create them in a similar way to how I described creating Footstep Profiles
The Footstep Material Profiles don't necessarily have to be saved as resources, they can be created inside the Footstep Material Library.
- Click Add Element
- Click the down arrow and click "New Footstep Material Profile"
- Click the footstep material profile
- Assign a material to detect and a footstep profile

### Footstep Material Profile
Contains a material and a Footstep Profile. When the specified material is detected the specified Footstep Profile will be used.

### Sound Attributions
All sounds used in the DynamicFootstepSystem are CC0 and taken from freesound.org
- Dirt: https://freesound.org/people/HenKonen/sounds/682127/
- Grass: https://freesound.org/people/HenKonen/sounds/682128/
- Stone: https://freesound.org/people/xmike80x/sounds/706207/
- Wood: https://freesound.org/people/SpliceSound/sounds/150444/

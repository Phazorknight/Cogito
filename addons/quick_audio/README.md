# ![Icon](https://raw.githubusercontent.com/BtheDestroyer/Godot_QuickAudio/1.0/addons/quick_audio/icon.svg) Godot_QuickAudio

Light-weight and easy-to-use interface for creating sound effects and music systems

## [Overview Video](https://www.youtube.com/watch?v=OEpfdmW6_s0)


## Installation

### From Asset Library

1. Search "QuickAudio" in the "Asset Library" tab (at the top next to 2D, 3D, and Script) of the Godot editor.
1. Add the plugin to your project.

### Manual Download

1. Download the code from this repository.
1. Extract the downloaded archive to your project; resulting files should end up in `res://addons/quick_audio` (Files outside of that folder are not needed)
1. Go to your Project Settings, select the 

## How to Use

See the full demo scripts for [sound effects](https://github.com/BtheDestroyer/Godot_QuickAudio/blob/master/addons/quick_audio/SFXDemo.gd) and [music](https://github.com/BtheDestroyer/Godot_QuickAudio/blob/master/addons/quick_audio/MusicDemo.gd).

### Quick start:

```gdscript
extends Node3D

@export var music: AudioStream
@export var sound: AudioStream

func _ready():
  Audio.play_sound(music)

var time := 0.0
func _process(delta):
  time += delta
  if time > 1.0:
	time -= 1.0
	Audio.play_sound_3d(sound).global_position = global_position
```

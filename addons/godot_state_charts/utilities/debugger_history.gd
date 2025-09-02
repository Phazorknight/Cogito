const RingBuffer = preload("ring_buffer.gd")

var _buffer:RingBuffer = null

var _dirty:bool = false

## Whether the history has changed since the full
## history string was last requested.
var dirty:bool:
	get: return _dirty

func _init(maximum_lines:int = 500):
	_buffer = RingBuffer.new(maximum_lines)
	_dirty = false


## Sets the maximum number of lines to store in the history.
## This will clear the history.
func set_maximum_lines(maximum_lines:int) -> void:
	_buffer.set_maximum_lines(maximum_lines)


## Adds an item to the history list.
func add_history_entry(frame:int, text:String) -> void:
	_buffer.append("[%s]: %s \n" % [frame, text])
	_dirty = true


## Adds a transition to the history list.
func add_transition(frame:int, name:String, from:String, to:String) -> void:
	add_history_entry(frame, "[»] Transition: %s from %s to %s" % [name, from, to])


## Adds an event to the history list.
func add_event(frame:int, event:StringName) -> void:
	add_history_entry(frame, "[!] Event received: %s" % event)


## Adds a state entered event to the history list.
func add_state_entered(frame:int, name:StringName) -> void:
	add_history_entry(frame, "[>] Enter: %s" % name)


## Adds a state exited event to the history list.
func add_state_exited(frame:int, name:StringName) -> void:
	add_history_entry(frame, "[<] Exit: %s" % name)


## Clears the history.
func clear() -> void:
	_buffer.clear()
	_dirty = true


## Returns the full history as a string.
func get_history_text() -> String:
	_dirty = false
	return _buffer.join()



## The content of the ring buffer
var _content:Array[String] = []

## The current index in the ring buffer
var _index = 0

## The size of the ring buffer
var _size = 0 

## Whether the buffer is fully populated
var _filled = false


func _init(size:int = 300):
	_size = size
	_content.resize(size)
	
	
## Sets the maximum number of lines to store. This clears the buffer.	
func set_maximum_lines(lines:int):
	_size = lines
	_content.resize(lines)
	clear()

## Adds an item to the ring buffer
func append(value:String):
	_content[_index] = value
	if _index + 1 < _size:
		_index += 1
	else:
		_index = 0
		_filled = true


## Joins the items of the ring buffer into a big string
func join():
	var result = ""
	if _filled:
		# start by _index + 1, run to the end and then continue from the start
		for i in range(_index, _size):
			result += _content[i] 

	# when not filled, just start at the beginning
	for i in _index:
		result += _content[i]
		
	return result

		
func clear():
	_index = 0
	_filled = false 	

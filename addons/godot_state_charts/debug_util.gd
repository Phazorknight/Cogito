## Returns the path of a node in the scene tree
## Returns the name of the node if the node is not in the tree.
static func path_of(node: Node) -> String:
	if node == null:
		return ""
	if !node.is_inside_tree():
		return node.name + " (not in tree)"
	return str(node.get_path())

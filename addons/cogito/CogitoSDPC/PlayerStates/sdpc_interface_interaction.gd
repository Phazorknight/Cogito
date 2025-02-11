class_name SDPCStateInterfacing
extends SDPCState

#NOTE: Use Case: Vendors, Pause Menus, UI

"""
Note:
	Instead of linking this State to every other, we can have this
	state just remember what the previous state was and then change back into it
	on exit.

	It will also be a self-terminating state, as in one of the few to call its own exit function
	"""

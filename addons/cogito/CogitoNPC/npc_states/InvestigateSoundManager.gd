extends Node

# InvestigateSoundManager
#
# Lightweight static helper that broadcasts an "investigate" request to nearby NPCs.
#
# Usage:
#   InvestigateSoundManager.broadcast_investigate(position, radius)
#
# Behavior:
# - Finds nodes in the scene tree that belong to the group "npc" and are within
#   `radius` meters of `position`.
# - Sets the meta key `investigate_location` on each notified NPC so their
#   investigate state can read the target position.
# - If the NPC exposes a `npc_state_machine` with a `goto` method, it will call
#   `state_machine.goto("investigate")` to transition that NPC into the
#   investigate state.
# - If the NPC implements `set_investigate_target(position)` it will call that
#   as a fallback.
# - Emits debug logs (via `CogitoGlobals.debug_log` if available) to help
#   trace which NPCs were notified.

class_name InvestigateSoundManager

static func broadcast_investigate(position: Vector3, radius: float = 8.0) -> void:
	var tree = Engine.get_main_loop()
	if tree == null:
		return

	var all_npcs: Array = tree.get_nodes_in_group("npc")
	for npc in all_npcs:
		if not (npc is Node3D):
			continue

		var dist: float = npc.global_position.distance_to(position)
		if dist <= radius:
			# Debug: which NPCs are being notified
			if Engine.has_singleton("CogitoGlobals"):
				CogitoGlobals.debug_log(true, "InvestigateSoundManager", "Notifying NPC: " + str(npc.name) + " dist=" + str(dist))
			else:
				print("InvestigateSoundManager: Notifying NPC: ", npc.name, " dist=", dist)

			# Set investigate meta so states can read it
			npc.set_meta("investigate_location", position)

			# Try to call a state machine if present
			var state_machine = null
			if npc.get("npc_state_machine") != null:
				state_machine = npc.get("npc_state_machine")

			if state_machine and state_machine.has_method("goto"):
				state_machine.goto("investigate")
				if Engine.has_singleton("CogitoGlobals"):
					CogitoGlobals.debug_log(true, "InvestigateSoundManager", "Triggered investigate state on: " + str(npc.name))
				else:
					print("InvestigateSoundManager: triggered investigate on", npc.name)
			elif npc.has_method("set_investigate_target"):
				npc.set_investigate_target(position)
				if Engine.has_singleton("CogitoGlobals"):
					CogitoGlobals.debug_log(true, "InvestigateSoundManager", "Called set_investigate_target on: " + str(npc.name))
				else:
					print("InvestigateSoundManager: called set_investigate_target on", npc.name)

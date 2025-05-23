extends Area2D

"""
Triggers NPC2 cutscene when player approaches house exit
Only triggers once - if player already met NPC2, does nothing
"""

var npc2_reference: CharacterBody2D
var cutscene_triggered = false

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Find NPC2 in the scene
	_find_npc2()

func _find_npc2():
	# Look for NPC2 by group
	var npc2_nodes = get_tree().get_nodes_in_group("npc2")
	if npc2_nodes.size() > 0:
		npc2_reference = npc2_nodes[0]
		print("HouseExitTrigger: Found NPC2 reference")
	else:
		print("HouseExitTrigger: No NPC2 found in scene")

func _on_body_entered(body):
	print("TRIGGER: Body entered: ", body.name)
	# Only trigger if:
	# 1. It's the player
	# 2. We haven't triggered before
	# 3. Player hasn't met NPC2 yet
	# 4. We have a valid NPC2 reference
	if (body.is_in_group("player") and 
		not cutscene_triggered and 
		not Globals.npc2_met_in_house and 
		npc2_reference):
		
		cutscene_triggered = true
		print("HouseExitTrigger: Player approached exit - starting NPC2 cutscene")
		npc2_reference.start_cutscene()
	elif body.is_in_group("player") and Globals.npc2_met_in_house:
		print("HouseExitTrigger: Player already met NPC2, no cutscene needed")

extends StaticBody2D

@export var to_scene = "res://scenes/levels/outside2.tscn" # (String, FILE, "*.tscn")
@export var spawnpoint: String = ""

func _ready():
	# Check if player has Advanced Magic Sword in inventory
	if has_advanced_magic_sword():
		$to_inside/CollisionShape2D.disabled = false
		$to_inside.to_scene = to_scene
		$to_inside.spawnpoint = spawnpoint
	else:
		# Disable the portal's collision and interaction if player doesn't have the sword
		$to_inside/CollisionShape2D.disabled = true
		# Optional: Visual indication that portal is inactive
		# $Sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _process(delta: float) -> void:
	# Check if player has Advanced Magic Sword in inventory
	if has_advanced_magic_sword():
		$to_inside/CollisionShape2D.disabled = false
		$to_inside.to_scene = to_scene
		$to_inside.spawnpoint = spawnpoint
	else:
		# Disable the portal's collision and interaction if player doesn't have the sword
		$to_inside/CollisionShape2D.disabled = true
		# Optional: Visual indication that portal is inactive
		# $Sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)

func has_advanced_magic_sword() -> bool:
	# Get the inventory dictionary
	var inventory = Inventory.list()
	print(inventory)
	if inventory.is_empty():
		return false
	else:
		for item in inventory:
			if item == "Advanced Magic Sword":
				return true
		return false
	
	# Check if "Advanced Magic Sword" exists in the inventory keys
	return inventory.has("Advanced Magic Sword") and inventory["Advanced Magic Sword"] > 0

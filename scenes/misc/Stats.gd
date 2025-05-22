extends PanelContainer

var enabled = false

# Crafting recipes
var crafting_recipes = {
	"Wooden Sword": {"Wood": 0, "Iron": 0},
	"Health Potion": {"Herb": 3, "Water": 1},
	"Iron Armor": {"Iron": 5, "Leather": 2},
}

func _ready():
	Globals.save_game()
	get_tree().set_auto_accept_quit(false)
	hide()
	print("Crafting system initialized")  # Debug

func _input(event):
	if event.is_action_pressed("pause"):
		enabled = !enabled
		visible = enabled
		get_tree().paused = enabled
		if enabled:
			grab_focus()
			update_all_displays()
			print("Menu opened")  # Debug
	
	# Explicit check for C key (not just "craft" action)
	if enabled and ((event is InputEventKey and event.keycode == KEY_C)):
		print("C key pressed")  # Debug
		attempt_crafting()

func update_all_displays():
	update_quest_listing()
	update_item_listing()
	update_crafting_listing()

func attempt_crafting():
	print("Attempting to craft...")  # Debug
	var craftable_item = get_first_craftable_item()
	
	if craftable_item:
		print("Found craftable item: ", craftable_item)  # Debug
		craft_item(craftable_item)
	else:
		print("No craftable items found")  # Debug
		# Print inventory for debugging
		print("Current inventory: ", Inventory.list())
		# Print required materials for debugging
		for recipe in crafting_recipes:
			print("Recipe ", recipe, " requires: ", crafting_recipes[recipe])


func update_quest_listing():
	var text = "Started:\n"
	for quest in Quest.list(Quest.STATUS.STARTED):
		text += "  %s\n" % quest
	text += "Failed:\n"
	for quest in Quest.list(Quest.STATUS.FAILED):
		text += "  %s\n" % quest
	$VBoxContainer/HBoxContainer/Quests/Details.text = text

func update_item_listing():
	var text = ""
	var inventory = Inventory.list()
	
	if inventory.is_empty():
		text = "[Empty]"
	else:
		for item in inventory:
			text += "%s x %s\n" % [item, inventory[item]]
	
	$VBoxContainer/HBoxContainer/Inventory/Details.text = text

func update_crafting_listing():
	var text = "Available Recipes:\n\n"
	var inventory = Inventory.list()
	
	for recipe_name in crafting_recipes:
		var recipe = crafting_recipes[recipe_name]
		var can_craft = true
		var recipe_text = recipe_name + ":\n"
		
		# Check materials
		for material in recipe:
			var required = recipe[material]
			var available = inventory.get(material, 0)
			
			if available >= required:
				recipe_text += "  ✓ %s: %d/%d\n" % [material, available, required]
			else:
				recipe_text += "  ✗ %s: %d/%d\n" % [material, available, required]
				can_craft = false
		
		recipe_text += "  [CRAFTABLE]\n" if can_craft else "  [MISSING MATERIALS]\n"
		text += recipe_text + "\n"
	
	$VBoxContainer/HBoxContainer/Crafting/Details.text = text


func craft_item(item_name: String):
	print("Trying to craft: ", item_name)  # Debug
	if not crafting_recipes.has(item_name):
		print("Error: Recipe not found")
		return false
	
	var recipe = crafting_recipes[item_name]
	print("Recipe requirements: ", recipe)  # Debug
	
	# Verify materials
	for material in recipe:
		var available = Inventory.list().get(material, 0)
		print("Checking ", material, ": have ", available, " need ", recipe[material])  # Debug
		if available < recipe[material]:
			print("Craft failed: Not enough ", material)
			return false
	
	# Remove materials
	for material in recipe:
		Inventory.remove_item(material, recipe[material])
		print("Removed ", recipe[material], " ", material)  # Debug
	
	# Add crafted item
	Inventory.add_item(item_name, 1)
	print("Added 1 ", item_name)  # Debug
	
	# Update UI
	update_all_displays()
	return true

func get_first_craftable_item():
	print("Checking for craftable items...")  # Debug
	var inventory = Inventory.list()
	
	for recipe_name in crafting_recipes:
		var can_craft = true
		var recipe = crafting_recipes[recipe_name]
		
		for material in recipe:
			if inventory.get(material, 0) < recipe[material]:
				can_craft = false
				break
		
		if can_craft:
			print("Can craft: ", recipe_name)  # Debug
			return recipe_name
	
	print("No craftable items found")  # Debug
	return null

func on_Exit_pressed():
	quit_game()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game():
	Globals.save_game()
	get_tree().quit()

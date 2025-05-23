extends PanelContainer

var enabled = false

# Crafting recipes
var crafting_recipes = {
	"Wooden Sword": {"Wood": 1, "Iron": 1},
	"Health Potion": {"Herb": 3, "Water": 1},
	"Iron Armor": {"Iron": 5, "Leather": 2},
	"Iron Sword": {"Wood": 2, "Iron": 5},
	"Advanced health Potion": {"Herb": 5, "Water": 2},
	#"Advanced Magic Sword": {"Herb": 0, "Iron":0, "Leather":0, "Ant Skull": 0, "Game Reward":0}
	"Advanced Magic Sword": {"Herb": 4, "Iron":6, "Leather":5, "Ant Skull": 1, "Game Reward":1}
}

var numbered_recipes = {}  # Will store the numbered recipes for reference
var last_displayed_recipes = {}  # To keep track of what was last displayed

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
	
	# Check for number key presses when enabled
	if enabled and event is InputEventKey and event.pressed:
		var key = event.keycode
		# Check if it's a number key (0-9)
		if key >= KEY_0 and key <= KEY_9:
			var number = key - KEY_0  # Convert keycode to actual number
			attempt_crafting_by_number(number)

func update_all_displays():
	update_quest_listing()
	update_item_listing()
	update_crafting_listing()

func attempt_crafting_by_number(number: int):
	print("Attempting to craft item number: ", number)
	
	# Check if this number exists in our numbered recipes
	if numbered_recipes.has(number):
		var item_name = numbered_recipes[number]
		print("Found item to craft: ", item_name)
		craft_item(item_name)
	else:
		print("No item with number ", number)

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
	var text = "Available Recipes (press number to craft):\n\n"
	var inventory = Inventory.list()
	
	# Clear the numbered recipes before rebuilding
	numbered_recipes.clear()
	var current_number = 1  # Start numbering from 1
	
	for recipe_name in crafting_recipes:
		var recipe = crafting_recipes[recipe_name]
		var can_craft = true
		var recipe_text = "%d. %s:\n" % [current_number, recipe_name]
		
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
		
		# Store this recipe with its number if it's craftable
		if can_craft:
			numbered_recipes[current_number] = recipe_name
		
		current_number += 1
	
	$VBoxContainer/HBoxContainer/ScrollContainer/Details.text = text

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

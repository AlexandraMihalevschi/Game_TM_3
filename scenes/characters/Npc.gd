extends Area2D

"""
It just wraps around a sequence of dialogs. If it contains a child node named 'Quest'
which should be an instance of Quest.gd it'll become a quest giver and show whatever
text Quest.process() returns
"""

var active = false
@export var character_name: String = "Brutal Horse"
@export var dialogs = ["..."] # (Array, String, MULTILINE)
var current_dialog = 0

# Reference to the interaction prompt (if you have one)
@onready var interaction_prompt = $InteractionPrompt

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide interaction prompt initially if it exists
	if interaction_prompt:
		interaction_prompt.hide()

func _input(event):
	# Bail if npc not active (player not inside the collider)
	if not active:
		return
	# Bail if Dialogs singleton is showing another dialog
	if Dialogs.active:
		return
	# Bail if the event is not a pressed "interact" action
	if not event.is_action_pressed("interact"):
		return
	
	# If the character is a questgiver delegate getting the text
	# to the Quest node, show it and end the function
	if has_node("Quest"):
		var quest_dialog = get_node("Quest").process()
		if quest_dialog != "":
			Dialogs.show_dialog(quest_dialog, character_name)
			return
	
	# If we reached here and there are generic dialogs to show, rotate among them
	if not dialogs.is_empty():
		Dialogs.show_dialog(dialogs[current_dialog], character_name)
		current_dialog = wrapi(current_dialog + 1, 0, dialogs.size())
		
func _on_body_entered(body):
	if body is Player:
		active = true
		# Show interaction prompt if it exists
		if interaction_prompt:
			interaction_prompt.show()
		
func _on_body_exited(body):
	if body is Player:
		active = false
		# Hide interaction prompt if it exists
		if interaction_prompt:
			interaction_prompt.hide()

extends Area2D

"""
It just wraps around a sequence of dialogs. If it contains a child node named 'Quest'
which should be an instance of Quest.gd it'll become a quest giver and show whatever
text Quest.process() returns
"""

var active = false
@export var character_name: String = "The Fortune TELLER!!!!!"
@export var dialogs = ["..."] # (Array, String, MULTILINE)
var current_dialog = 0
@export var spawn_item_after_dialogue := false # Toggle whether to spawn item after talking
@export var despawn_after_item := false # Toggle whether to despawn after spawning item

@onready var sprite = $sprite # Assuming you have a Sprite2D node for visual representation
@onready var collision_shape = $StaticBody2D/CollisionShape2D # Reference to collision shape

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Connect to the dialog box's signals if they exist
	
	

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

		
func _on_body_exited(body):
	if body is Player:
		active = false

	
@export var despawn_fx : PackedScene # Add this to assign your particle effect scene in the inspector

func _on_dialog_ended():
	# Only spawn if this NPC was the one who initiated the dialog
	if active and spawn_item_after_dialogue:
		if has_node("item_spawner"):
			$item_spawner.spawn()
		spawn_item_after_dialogue = false # Prevent spawning multiple times
		
		if despawn_after_item:
			despawn()

func despawn():
	# Create and add particle effect
	if despawn_fx:
		var despawn_particles = despawn_fx.instantiate()
		get_parent().add_child(despawn_particles)
		despawn_particles.global_position = global_position
	
	# Spawn item if not already spawned above (redundant check for safety)
	if has_node("item_spawner") and spawn_item_after_dialogue:
		$item_spawner.spawn()
	
	# Remove the NPC
	queue_free()

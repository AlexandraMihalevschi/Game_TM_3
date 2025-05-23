# StoryIntro.gd
extends Control

@onready var background_image = get_node("BackgroundImage")    # Check if this exists
@onready var text_box = $TextBox             # Check if this exists  
@onready var story_text = get_node("TextBox/StoryText")        # Check if this exists
@onready var next_button = get_node("TextBox/NextButton")   

var current_scene = 0
var story_data = []

func _ready():
	# Define your 6 scenes here
	story_data = [
		{
			"image": "res://scenes/levels/images/scena1.png",
			"text": "Year: Who Even Knows. Location: Some random wild place. A random cosmic egg floats by, glowing and sparkling like a yummy gellybean.]"
		},
		{
			"image": "res://scenes/levels/images/scena2.png", 
			"text": "In the words of the great Luntik - IA RADILSEA. from an egg… that fell from the Moon. Yeah. Straight outta orbit. No instructions. Just pure confusion and raw bug energy."
		},
		{
			"image": "res://scenes/levels/images/scena3.png",
			"text": "I was hatched with zero life skills. Couldn’t fly. Couldn’t walk. Couldn’t even open TikTok."
		},
		{
			"image": "res://scenes/levels/images/scena4.png",
			"text": "Still, I had one thing: ✨delusion.✨ And that, my friends, is more powerful than wings."
		},
		{
			"image": "res://scenes/levels/images/scena5.png",
			"text": "And so i began my long and hard journey. I followed all the gym influencers. I trained. I studied. I did cardio... once. I drank matcha made by the local ants."
		},
		{
			"image": "res://scenes/levels/images/scena6.png",
			"text": "To become the King of the Ladybugs. Not some NPC in the garden. I’m talking top bug. CEO of crawling. Dictator of drip."
		}
	]
	
	# Connect the button signal
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Show first scene
	show_scene(0)

func show_scene(scene_index):
	if scene_index >= story_data.size():
		# Story finished, transition to main game or menu
		finish_story()
		return
	
	var scene_data = story_data[scene_index]
	
	# Load and display the background image
	var texture = load(scene_data.image)
	background_image.texture = texture
	
	# Set the story text
	story_text.text = scene_data.text
	
	# Update button text for last scene
	if scene_index == story_data.size() - 1:
		next_button.text = "Continue"
	else:
		next_button.text = "Next"

func _on_next_button_pressed():
	current_scene += 1
	show_scene(current_scene)

func finish_story():
	# Set the current level and save game state
	if Globals.current_level != "":
		if Globals.save_game() == false:
			push_error("Error saving game")
		
		# Transition to the actual game level
		var err = get_tree().change_scene_to_file(Globals.current_level)
		if err != OK:
			push_error("Error changing scene: %s" % err)
	else:
		push_error("Error: current_level shouldn't be empty")

# Optional: Allow clicking anywhere to advance
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		_on_next_button_pressed()

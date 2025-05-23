extends Node2D

# Node references
var ball: CharacterBody2D
var score_bottom: Label
var score_top: Label

# Scores
var bottom_score: int = 0
var top_score: int = 0

# Game state
var game_over: bool = false
const WINNING_SCORE: int = 3

func _ready():
	print("=== GAME STARTING ===")
	
	# Find all nodes and print what we find
	print("Looking for nodes...")
	
	# Find ball
	ball = find_child("ball", true, false)
	if ball:
		print("✓ Found ball at: ", ball.get_path())
	else:
		print("✗ Ball not found!")
		# Try alternative names
		var alt_ball = find_child("Ball", true, false)
		if alt_ball:
			ball = alt_ball
			print("✓ Found ball with capital B: ", ball.get_path())
	
	# Find score labels - try multiple possible names/paths
	var possible_bottom_names = ["scorebottom", "ScoreBottom", "score_bottom"]
	var possible_top_names = ["scoretop", "ScoreTop", "score_top"]
	
	for name in possible_bottom_names:
		score_bottom = find_child(name, true, false)
		if score_bottom:
			print("✓ Found bottom score: ", score_bottom.get_path())
			break
	
	for name in possible_top_names:
		score_top = find_child(name, true, false)
		if score_top:
			print("✓ Found top score: ", score_top.get_path())
			break
	
	if not score_bottom:
		print("✗ Bottom score label not found!")
	if not score_top:
		print("✗ Top score label not found!")
	
	# Make labels more visible
	setup_score_labels()
	
	# Initialize scores
	update_scores()
	
	print("=== SETUP COMPLETE ===")

func setup_score_labels():
	if score_bottom:
		score_bottom.add_theme_font_size_override("font_size", 48)
		score_bottom.modulate = Color.WHITE
		score_bottom.position = Vector2(50, get_viewport_rect().size.y - 100)
		print("Bottom score positioned at: ", score_bottom.position)
	
	if score_top:
		score_top.add_theme_font_size_override("font_size", 48)
		score_top.modulate = Color.WHITE
		score_top.position = Vector2(50, 50)
		print("Top score positioned at: ", score_top.position)

func update_scores():
	if score_bottom:
		score_bottom.text = str(bottom_score)
	if score_top:
		score_top.text = str(top_score)
	print("Scores updated - Bottom: ", bottom_score, " Top: ", top_score)

func _physics_process(delta: float) -> void:
	if not ball or game_over:
		return
	
	# Check for scoring
	var screen_h = get_viewport_rect().size.y
	var ball_y = ball.position.y
	
	# Simple scoring - ball goes off screen
	if ball_y > screen_h + 20:  # Ball went off bottom
		print("GOAL! Top player scored!")
		top_score += 1
		update_scores()
		check_game_over()
		if not game_over:
			ball.reset_ball()
		
	elif ball_y < -20:  # Ball went off top
		print("GOAL! Bottom player scored!")
		bottom_score += 1
		update_scores()
		check_game_over()
		if not game_over:
			ball.reset_ball()

func check_game_over():
	if bottom_score >= WINNING_SCORE:
		game_over = true
		on_player_wins()
	elif top_score >= WINNING_SCORE:
		game_over = true
		on_player_loses()

func on_player_wins():
	print("🎉 PLAYER WINS! Final Score - Player: ", bottom_score, " AI: ", top_score)
	Inventory.add_item("Game reward", 1)
	get_tree().change_scene_to_file("res://scenes/levels/HouseInside.tscn")
	# Stop the ball
	if ball:
		ball.velocity = Vector2.ZERO
	
	# Display win message
	show_game_over_message("YOU WIN!", Color.GREEN)
	
	# Add any additional win logic here
	# For example: play victory sound, save high score, etc.

func on_player_loses():
	print("💀 PLAYER LOSES! Final Score - Player: ", bottom_score, " AI: ", top_score)
	
	# Stop the ball
	if ball:
		ball.velocity = Vector2.ZERO
	
	# Display lose message
	show_game_over_message("YOU LOSE!", Color.RED)
	
	# Add any additional lose logic here
	# For example: play defeat sound, show retry option, etc.

func show_game_over_message(message: String, color: Color):
	# Create a temporary label for the game over message
	var game_over_label = Label.new()
	game_over_label.text = message
	game_over_label.add_theme_font_size_override("font_size", 72)
	game_over_label.modulate = color
	
	# Center the message on screen
	var screen_size = get_viewport_rect().size
	game_over_label.position = Vector2(
		screen_size.x / 2 - 150,  # Approximate centering
		screen_size.y / 2 - 36    # Half of font size for vertical centering
	)
	
	add_child(game_over_label)
	
	# Optional: Add restart instruction
	var restart_label = Label.new()
	restart_label.text = "Press R to restart"
	restart_label.add_theme_font_size_override("font_size", 32)
	restart_label.modulate = Color.WHITE
	restart_label.position = Vector2(
		screen_size.x / 2 - 100,
		screen_size.y / 2 + 50
	)
	
	add_child(restart_label)

func _input(event):
	# Allow restarting the game when it's over
	if game_over and event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		restart_game()

func restart_game():
	print("=== RESTARTING GAME ===")
	
	# Reset scores
	bottom_score = 0
	top_score = 0
	game_over = false
	
	# Update score display
	update_scores()
	
	# Reset ball
	if ball:
		ball.reset_ball()
	
	# Remove any game over messages
	for child in get_children():
		if child is Label and child != score_bottom and child != score_top:
			child.queue_free()

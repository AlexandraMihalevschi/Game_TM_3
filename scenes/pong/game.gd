extends Node2D

# Node references
var ball: CharacterBody2D
var score_bottom: Label
var score_top: Label

# Scores
var bottom_score: int = 0
var top_score: int = 0

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
	if not ball:
		return
	
	# Check for scoring
	var screen_h = get_viewport_rect().size.y
	var ball_y = ball.position.y
	
	# Simple scoring - ball goes off screen
	if ball_y > screen_h + 20:  # Ball went off bottom
		print("GOAL! Top player scored!")
		top_score += 1
		update_scores()
		ball.reset_ball()
		
	elif ball_y < -20:  # Ball went off top
		print("GOAL! Bottom player scored!")
		bottom_score += 1
		update_scores()
		ball.reset_ball()

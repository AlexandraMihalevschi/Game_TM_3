extends CharacterBody2D

@export var is_ai: bool = false
@export var speed: float = 400.0
var half_width: float = 50.0  # Default fallback value
@onready var sprite_node: Sprite2D = $Sprite2D
var ball: CharacterBody2D

func _ready() -> void:
	print("Paddle ready! is_ai = ", is_ai)
	# Calculate half the paddle's width for clamping
	if sprite_node and sprite_node.texture:
		half_width = sprite_node.texture.get_size().x * sprite_node.scale.x * 0.5
		print("Paddle half_width: ", half_width)
	
	# Get ball reference safely
	call_deferred("_get_ball_reference")

func _get_ball_reference():
	# Try multiple ways to find the ball
	print("Looking for ball...")
	
	# Method 1: Look in parent
	ball = get_parent().find_child("ball", true, false)
	if ball:
		print("Found ball via parent.find_child!")
		return
	
	# Method 2: Try with capital B
	ball = get_parent().find_child("Ball", true, false)
	if ball:
		print("Found ball with capital B!")
		return
	
	# Method 3: Look in scene tree root
	ball = get_tree().get_first_node_in_group("ball")
	if ball:
		print("Found ball via group!")
		return
		
	# Method 4: Search more broadly
	var root = get_tree().current_scene
	if root:
		ball = root.find_child("ball", true, false)
		if ball:
			print("Found ball via scene root!")
			return
	
	print("Could not find ball anywhere!")

func _physics_process(delta: float) -> void:
	var dir := 0.0
	
	if is_ai:
		# If we don't have ball reference, try to get it again
		if not ball or not is_instance_valid(ball):
			_get_ball_reference()
		
		# AI paddle - use your original working logic
		if ball and is_instance_valid(ball):
			dir = sign(ball.position.x - position.x)
			# Remove the print to reduce spam, but keep for debugging if needed
			# print("AI moving: ", dir, " (ball at ", ball.position.x, ", paddle at ", position.x, ")")
		else:
			print("AI: No ball reference!")
	else:
		# Human player input
		dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Apply movement
	velocity.x = dir * speed
	velocity.y = 0  # Make sure paddle doesn't move vertically
	
	# Use move_and_slide but don't let it affect ball physics
	var old_position = position
	move_and_slide()
	
	# If we collided with something and got pushed, resist the movement
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() == ball:
				# If we hit the ball, don't let it push us around
				position.y = old_position.y  # Keep our Y position fixed
	
	# Keep paddle on screen
	var screen_w := get_viewport_rect().size.x
	position.x = clamp(position.x, half_width, screen_w - half_width)

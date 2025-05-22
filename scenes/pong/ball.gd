# ball.gd
extends CharacterBody2D

@export var speed: float = 550.0

func _ready() -> void:
	reset_ball()

func reset_ball() -> void:
	print("Ball reset!")
	# Center on screen
	position = get_viewport_rect().size * 0.5
	# Pick a random ±45° launch
	var angle: float = randf_range(-PI/4, PI/4)
	if randi() % 2 == 1:
		angle += PI
	velocity = Vector2(cos(angle), sin(angle)) * speed
	print("Ball velocity: ", velocity)

func _physics_process(delta: float) -> void:
	# Try to move; get collision info if we hit something
	var collision = move_and_collide(velocity * delta)
	if collision:
		# Bounce off whatever we hit
		velocity = velocity.bounce(collision.get_normal())
		print("Ball bounced! New velocity: ", velocity)

extends CharacterBody2D

"""
NPC2 - Companion character that:
1. Hides in house initially
2. Appears at house exit for cutscene dialog
3. Follows player outside with chaotic movement
4. Attacks enemies in range
5. Never appears in house again after first meeting
"""

# Movement and physics
const SPEED = 200.0
const CHAOTIC_SPEED = 300.0
const JUMP_VELOCITY = -400.0

# References
var player_reference: CharacterBody2D
var current_target_enemy: CharacterBody2D

# States
enum State { HIDDEN, CUTSCENE, FOLLOWING, ATTACKING, MOVING_ASIDE }
var current_state = State.HIDDEN

# Following behavior
var follow_distance = 60.0
var max_follow_distance = 200.0
var chaotic_movement_timer = 0.0
var chaotic_direction = Vector2.ZERO
var chaotic_change_interval = 2.0

# Combat
var attack_range = 100.0
var attack_cooldown = 2.0
var can_attack = true

# Dialog
var cutscene_dialog = [
	"Bbg, Wait!",
	"It's dangerous out there alone.",
	"Let me help you out."
]
var current_dialog_index = 0

# Random phrases
var follow_phrases = [
	"What's that over there?",
	"I'm right behind you!",
	"Watch out for enemies!"
]
var phrase_timer = 0.0
var phrase_cooldown = 8.0

# Animation
var facing = "down"

func _ready():
	add_to_group("npc2")
	_find_player()
	_setup_initial_state()
	_connect_signals()
	
	# Start timers
	$StateTimer.timeout.connect(_on_state_timer_timeout)
	$AttackCooldown.timeout.connect(_on_attack_cooldown_timeout)

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]
		print("NPC2: Found player reference")

func _setup_initial_state():
	var scene_path = get_tree().current_scene.scene_file_path
	
	if scene_path.contains("house") or scene_path.contains("House"):
		# We're in the house
		if Globals.npc2_met_in_house:
			# Already met, stay hidden forever
			current_state = State.HIDDEN
			visible = false
			print("NPC2: Already met, staying hidden in house")
		else:
			# First time, hide but ready for cutscene
			current_state = State.HIDDEN
			visible = false
			print("NPC2: Hidden in house, waiting for exit trigger")
	else:
		# We're outside
		if Globals.npc2_following:
			current_state = State.FOLLOWING
			visible = true
			_position_near_house_entrance()
			print("NPC2: Following player outside")
		else:
			current_state = State.HIDDEN
			visible = false

func _position_near_house_entrance():
	# Position near house entrance outside (adjust coordinates for your scene)
	# Make sure Y position matches your ground level!
	global_position = Vector2(200, 300)  # CHANGE THIS Y VALUE TO MATCH YOUR GROUND
	print("NPC2: Positioned at house entrance: ", global_position)

func _connect_signals():
	# Connect to attack range area
	if has_node("AttackRange"):
		$AttackRange.body_entered.connect(_on_enemy_entered_range)
		$AttackRange.body_exited.connect(_on_enemy_exited_range)

func _physics_process(delta):
	# Use the same movement system as Player (no gravity, 2D top-down movement)
	match current_state:
		State.HIDDEN:
			# Do nothing, stay invisible
			velocity = Vector2.ZERO
		State.CUTSCENE:
			# Don't move during cutscene
			velocity = Vector2.ZERO
		State.FOLLOWING:
			_handle_following_behavior(delta)
		State.ATTACKING:
			_handle_attack_behavior(delta)
		State.MOVING_ASIDE:
			# Let tween handle movement, don't override
			pass
	
	# Apply movement with collision detection (like player)
	if velocity != Vector2.ZERO:
		move_and_slide()
	
	_update_animation()

func _handle_following_behavior(delta):
	if not player_reference or not visible:
		velocity = Vector2.ZERO
		return
	
	# Update phrase timer
	phrase_timer += delta
	if phrase_timer >= phrase_cooldown:
		_show_random_phrase()
		phrase_timer = 0.0
		phrase_cooldown = randf_range(6.0, 12.0)
	
	# Check distance to player
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	# Calculate base direction to player
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	
	# Update chaotic movement timer
	chaotic_movement_timer += delta
	if chaotic_movement_timer >= chaotic_change_interval:
		_change_chaotic_direction()
		chaotic_movement_timer = 0.0
	
	# Determine movement based on distance
	var target_velocity = Vector2.ZERO
	
	if distance_to_player > max_follow_distance:
		# Too far - move directly toward player at high speed
		target_velocity = direction_to_player * CHAOTIC_SPEED
	elif distance_to_player > follow_distance:
		# In follow range - use chaotic movement
		var chaotic_influence = 0.6  # How much chaos vs direct following
		var final_direction = (direction_to_player * (1.0 - chaotic_influence) + chaotic_direction * chaotic_influence).normalized()
		target_velocity = final_direction * SPEED
	else:
		# Close enough - minimal movement with pure chaos
		target_velocity = chaotic_direction * (SPEED * 0.3)
	
	# Smooth velocity change (like player's lerp)
	velocity = velocity.lerp(target_velocity, 0.8)
	
	# Update facing direction based on movement
	_update_facing(velocity)

func _change_chaotic_direction():
	# Random direction change for chaotic movement (full 360 degrees)
	var random_angle = randf() * 2 * PI
	chaotic_direction = Vector2(cos(random_angle), sin(random_angle))
	chaotic_change_interval = randf_range(0.8, 2.5)  # More frequent changes for chaos

func _handle_attack_behavior(delta):
	if current_target_enemy and is_instance_valid(current_target_enemy):
		# Move toward enemy while attacking
		var direction_to_enemy = (current_target_enemy.global_position - global_position).normalized()
		var distance_to_enemy = global_position.distance_to(current_target_enemy.global_position)
		
		# Get close to enemy but not too close
		if distance_to_enemy > 40:
			velocity = direction_to_enemy * SPEED
		else:
			velocity = Vector2.ZERO
		
		_update_facing(velocity if velocity != Vector2.ZERO else direction_to_enemy * 100)
		
		# Attack if possible
		if can_attack:
			_perform_attack()
	else:
		# No valid target, return to following
		current_state = State.FOLLOWING
		velocity = Vector2.ZERO

func _perform_attack():
	print("NPC2: Attacking enemy!")
	can_attack = false
	$AttackCooldown.start()
	
	# Deal damage to enemy if it has a hurtbox
	if current_target_enemy.has_node("HurtBox"):
		# Simulate sword hit
		var hurtbox = current_target_enemy.get_node("HurtBox")
		if hurtbox.has_signal("area_entered"):
			# Create a temporary attack area to trigger enemy hurt
			_damage_enemy(current_target_enemy)

func _damage_enemy(enemy):
	# Direct damage approach
	if enemy.has_method("take_damage"):
		enemy.take_damage(1)
	elif "hitpoints" in enemy:
		enemy.hitpoints -= 1
		# Trigger hurt state if enemy has it
		if "state" in enemy and enemy.has_method("goto_hurt"):
			enemy.goto_hurt()
		elif "state" in enemy:
			enemy.state = 5  # STATE_HURT typically
		
		print("NPC2: Damaged enemy! HP: ", enemy.hitpoints)

func _update_facing(vel):
	# Use same facing logic as player - prioritize strongest direction
	if abs(vel.x) > abs(vel.y):
		# Horizontal movement is stronger
		if vel.x > 10:
			facing = "right"
		elif vel.x < -10:
			facing = "left"
	else:
		# Vertical movement is stronger  
		if vel.y > 10:
			facing = "down"
		elif vel.y < -10:
			facing = "up"
	
	# Keep current facing if velocity is too small

func _update_animation():
	if not has_node("anims"):
		return
	
	var anim_name = ""
	
	match current_state:
		State.HIDDEN:
			return  # No animation when hidden
		State.CUTSCENE:
			anim_name = "idle_" + facing
		State.ATTACKING:
			anim_name = "slash_" + facing
		State.FOLLOWING, State.MOVING_ASIDE:
			if abs(velocity.x) > 10:
				anim_name = "walk_" + facing
			else:
				anim_name = "idle_" + facing
	
	if $anims.current_animation != anim_name:
		$anims.play(anim_name)

func _show_random_phrase():
	var phrase = follow_phrases[randi() % follow_phrases.size()]
	print("NPC2: " + phrase)
	
	# Use the dialog system for phrases
	if Dialogs and Dialogs.dialog_box:
		Dialogs.show_dialog(phrase, "Pedritto")

# Called by HouseExitTrigger
func start_cutscene():
	if current_state != State.HIDDEN or Globals.npc2_met_in_house:
		return
	
	print("NPC2: Starting cutscene!")
	current_state = State.CUTSCENE
	visible = true
	current_dialog_index = 0
	
	# Position NPC2 in front of player (dramatic entrance)
	if player_reference:
		var player_pos = player_reference.global_position
		global_position = Vector2(player_pos.x + 50, player_pos.y)  # Appear to the right of player
	
	# Block player movement
	if player_reference and player_reference.has_method("set_blocked"):
		player_reference.set_blocked(true)
	
	# Small delay so player sees NPC2 appear
	await get_tree().create_timer(0.5).timeout
	
	# Start dialog
	_show_next_cutscene_dialog()

func _show_next_cutscene_dialog():
	if current_dialog_index < cutscene_dialog.size():
		var dialog_line = cutscene_dialog[current_dialog_index]
		print("NPC2 Dialog: " + dialog_line)
		
		# Use the proper dialog system
		if Dialogs and Dialogs.dialog_box:
			Dialogs.show_dialog(dialog_line, "Pedritto")
			# Connect to dialog ended signal to continue
			if not Dialogs.dialog_box.dialog_ended.is_connected(_on_dialog_ended):
				Dialogs.dialog_box.dialog_ended.connect(_on_dialog_ended)
		else:
			# Fallback if dialog system not available
			await get_tree().create_timer(2.0).timeout
			_on_dialog_ended()
	else:
		_end_cutscene()

func _on_dialog_ended():
	current_dialog_index += 1
	await get_tree().create_timer(0.5).timeout  # Small pause between dialogs
	_show_next_cutscene_dialog()

func _end_cutscene():
	print("NPC2: Ending cutscene")
	current_state = State.MOVING_ASIDE
	
	# Mark as met
	Globals.npc2_met_in_house = true
	
	# Move to the side
	var side_position = global_position + Vector2(80, 0)
	var tween = create_tween()
	tween.tween_property(self, "global_position", side_position, 1.0)
	await tween.finished
	
	# Unblock player
	if player_reference and player_reference.has_method("set_blocked"):
		player_reference.set_blocked(false)
	
	# Set up for following outside
	Globals.npc2_following = true
	
	print("NPC2: You can go now! I'll follow you outside.")

# Enemy detection
func _on_enemy_entered_range(body):
	if body.is_in_group("enemy") and current_state == State.FOLLOWING:
		print("NPC2: Enemy detected in range!")
		current_target_enemy = body
		current_state = State.ATTACKING

func _on_enemy_exited_range(body):
	if body == current_target_enemy:
		current_target_enemy = null
		if current_state == State.ATTACKING:
			current_state = State.FOLLOWING

# Timer callbacks
func _on_state_timer_timeout():
	# Used for various state timing
	pass

func _on_attack_cooldown_timeout():
	can_attack = true

extends CharacterBody2D

var speed = 150.0
const JUMP_VELOCITY = -250.0
var stamina = 0
var staminatext = stamina
var tap_count_jump = 0  # Counts Space presses
var is_dashing = false  # Tracks if the player is currently dashing
var is_boosting = false  # Tracks if the player is currently boosting
var dash_speed = 350  # Speed during dash
var cooldown = false
var facing_right = true


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprint_cooldown_timer: Timer = $SprintCooldownTimer
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var dash_duration_timer: Timer = $DashDurationTimer  # Timer for dash duration
@onready var jump_timer: Timer = $JumpTimer
@onready var boost_timer: Timer = $BoostTimer
@onready var cursor_sprite: AnimatedSprite2D = $Cursor/CursorSprite2D
@onready var RockScene = preload("res://Scenes/rock.tscn")  # Load your Rock scene



func _ready() -> void:
	stamina_bar.get_theme_stylebox("fill").bg_color = Color(0, 1, 0)
	add_to_group("player")

func _process(delta: float) -> void:
	if stamina < 0:
		stamina = 0
	stamina_bar.value = staminatext
	staminatext = 100 - round(stamina * 100)
	var direction_to_mouse = get_global_mouse_position() - global_position

	if facing_right:
		if direction_to_mouse.x < 0.0:
			cursor_sprite.play("red")
		else:
			cursor_sprite.play("white")
	else:
	# Facing left
		if direction_to_mouse.x > 0.0:
			cursor_sprite.play("red")
		else:
			cursor_sprite.play("white")
		

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

# Get the movement direction
	var direction = Vector2(Input.get_axis("move_left", "move_right"), 0)

	# Apply movement
	if is_dashing:
		velocity.x = direction.x * dash_speed  # Dash speed
	elif direction and sprint_cooldown_timer.time_left == 0:
		velocity.x = direction.x * speed
		if sprint_cooldown_timer.time_left == 0:
			stamina -= delta / 16
	elif direction:
		velocity.x = direction.x * speed / 2
		if sprint_cooldown_timer.time_left == 0:
			stamina -= delta / 16
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	 #  Check if the player pressed the throw action
	if Input.is_action_just_pressed("throw_rock"):
		throw_rock()
		

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and sprint_cooldown_timer.time_left == 0 and staminatext >= 5:
	#and not is_boosting:
		stamina += 0.1
		velocity.y = JUMP_VELOCITY
		tap_count_jump += 1
		jump_timer.start()  # Start the timer
	elif not Input.is_action_just_pressed("jump") and not is_on_floor():
		velocity.x = direction.x * speed - delta
		
	# Double jump
	if tap_count_jump == 1 and is_boosting == false and Input.is_action_just_pressed("jump") and sprint_cooldown_timer.time_left == 0 and staminatext >= 5 and not is_on_floor():
		stamina += 0.1
		velocity.y = JUMP_VELOCITY
		print("doublejump")
		tap_count_jump = 0
		
	# Stamina increase while standing still
	if stamina > 0 and velocity == Vector2(0, 0) and sprint_cooldown_timer.time_left == 0:
			stamina -= delta / 2
		
	#Jump falloff after dash
	if is_dashing and not is_on_floor():
			velocity.x = direction.x * dash_speed
	if is_boosting and not is_on_floor() and not is_dashing:
			velocity.x = direction.x * (dash_speed / 1.5)

		# Handle dashing

	if Input.is_action_just_pressed("sprint"): 
		if direction == Vector2.ZERO:
			return
		elif is_on_floor() and sprint_cooldown_timer.time_left == 0 and staminatext >= 30:
			is_dashing = true
			is_boosting = true
			dash_duration_timer.start()  # Dash lasts for a set duration
			boost_timer.start()
			stamina += 0.3
			print("dash")
		elif not is_on_floor() and sprint_cooldown_timer.time_left == 0 and staminatext >= 30:
			is_dashing = true
			is_boosting = true
			dash_duration_timer.start()  # Dash lasts for a set duration
			boost_timer.start()
			stamina += 0.3
			print("airdash")
		else:
			return
		
	if is_dashing:
		velocity.y = 0

	# Change bar color to red when stamina is low
	if stamina >= 1 and cooldown == false:
		cooldown = true
		sprint_cooldown_timer.start()
		stamina_bar.get_theme_stylebox("background").bg_color = Color(1, 0, 0)

	move_and_slide()
	
	# Flip sprite based on movement and set player direction
	if direction.x > 0:
		animated_sprite.flip_h = false
		facing_right = true
	elif direction.x < 0:
		animated_sprite.flip_h = true
		facing_right = false
	
		# Player animations
	if is_on_floor():
		if velocity == Vector2(0, 0):
			animated_sprite.play("idle")
		elif is_boosting:
				animated_sprite.play("sprint")
		else:
			animated_sprite.play("walking")
	elif is_boosting:
			animated_sprite.play("sprint")
	elif tap_count_jump == 1:
		animated_sprite.play("jump2")
	else:
		animated_sprite.play("jump")


# ROCK THROWING FUNCTION
func throw_rock():
	var direction_to_mouse = get_global_mouse_position() - global_position
	var spawn_offset_distance = 16.0  # tweak as needed
	# This normalizes the direction (length = 1) and then multiplies by offset
	var spawn_offset = direction_to_mouse.normalized() * spawn_offset_distance

	# Check if it's valid to throw (i.e., in front of the player)
	if facing_right and direction_to_mouse.x < 0.0:
		return  # do nothing if behind
	if not facing_right and direction_to_mouse.x > 0.0:
		return  # do nothing if behind
	# Otherwise, spawn a rock
	var rock_instance = RockScene.instantiate()
	# Position the rock at the player's hand or center
	rock_instance.global_position = global_position + spawn_offset
	# Give it an initial velocity
	# For a simple approach, we can set the linear_velocity in the direction of the mouse
	# Then, the rock’s own gravity will make it arc.
	var throw_power = 500.0  # tweak as you like
	var throw_dir = direction_to_mouse.normalized()
	rock_instance.throw_velocity = throw_dir * throw_power
	# Finally, add the rock to the scene tree
	get_parent().add_child(rock_instance)



# TIMERS:

# Change bar color back to grey when cooldown ends
func _on_sprint_cooldown_timer_timeout() -> void:
	cooldown = false
	stamina -= 0.1
	stamina_bar.get_theme_stylebox("background").bg_color = Color(153, 153, 153)

# End the dash
func _on_dash_duration_timer_timeout() -> void:
	is_dashing = false  # End dash, return to normal movement


# Reset tap count if second Space press was too slow
func _on_jump_timer_timeout() -> void:
	tap_count_jump = 0
# Resets boosting after dash
func _on_boost_timer_timeout() -> void:
	is_boosting = false

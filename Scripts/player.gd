extends CharacterBody2D

var speed = 150.0
const JUMP_VELOCITY = -250.0
var stamina = 0
var staminatext = stamina
var tap_count_sprint = 0  # Counts Shift presses
var tap_count_jump = 0  # Counts Space presses
var is_dashing = false  # Tracks if the player is currently dashing
var is_boosting = false  # Tracks if the player is currently boosting
var dash_speed = 300  # Speed during dash
var cooldown = false


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprint_cooldown_timer: Timer = $SprintCooldownTimer
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var dash_timer: Timer = $DashTimer  # Timer for double-tap detection
@onready var dash_duration_timer: Timer = $DashDurationTimer  # Timer for dash duration
@onready var jump_timer: Timer = $JumpTimer
@onready var boost_timer: Timer = $BoostTimer



func _ready() -> void:
	stamina_bar.get_theme_stylebox("fill").bg_color = Color(0, 1, 0)

func _process(delta: float) -> void:
	if stamina < 0:
		stamina = 0
	stamina_bar.value = staminatext
	staminatext = 100 - round(stamina * 100)

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
		

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and sprint_cooldown_timer.time_left == 0 and staminatext >= 5:
		stamina += 0.1
		velocity.y = JUMP_VELOCITY
		tap_count_jump += 1
		jump_timer.start()  # Start the timer
		
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
	if is_boosting and not is_on_floor():
			velocity.x = direction.x * (dash_speed / 1.5)

		# Handle double-tap sprint
	if Input.is_action_just_pressed("sprint"): 
		if direction == Vector2.ZERO:  
			return  # Prevent dashing in place
		tap_count_sprint += 1
		if tap_count_sprint == 1:
			dash_timer.start()  # Start the timer on first tap
		elif tap_count_sprint == 2:  # Start the dash
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
				velocity.y = JUMP_VELOCITY / 2
				dash_duration_timer.start()  # Dash lasts for a set duration
				boost_timer.start()
				stamina += 0.3
				print("airdash")
			else:
				return
		

	# Change bar color to red when stamina is low
	if stamina >= 1 and cooldown == false:
		cooldown = true
		sprint_cooldown_timer.start()
		stamina_bar.get_theme_stylebox("background").bg_color = Color(1, 0, 0)

	move_and_slide()
	
	# Flip sprite based on movement
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
	
		# Play animations
	if is_on_floor():
		if velocity == Vector2(0, 0):
			animated_sprite.play("idle")
		elif speed == 150:
			animated_sprite.play("walking")
		elif is_dashing:
			animated_sprite.play("jump")
	elif tap_count_jump == 1:
		animated_sprite.play("jump2")
	else:
		animated_sprite.play("jump")
# Timers:

# Change bar color back to grey when cooldown ends
func _on_sprint_cooldown_timer_timeout() -> void:
	cooldown = false
	stamina -= 0.1
	stamina_bar.get_theme_stylebox("background").bg_color = Color(153, 153, 153)

# End the dash
func _on_dash_duration_timer_timeout() -> void:
	is_dashing = false  # End dash, return to normal movement

# Reset tap count if second Shift press was too slow
func _on_dash_timer_timeout() -> void:
	tap_count_sprint = 0  # Reset tap count if the second tap didn’t happen in time

# Reset tap count if second Space press was too slow
func _on_jump_timer_timeout() -> void:
	tap_count_jump = 0

# Resets boosting after dash
func _on_boost_timer_timeout() -> void:
	is_boosting = false

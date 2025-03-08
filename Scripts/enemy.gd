extends CharacterBody2D  # Use KinematicBody2D in Godot 3.x

# Possible states for the enemy
enum State { ROAMING, CHASING, RETURNING }

var state = State.ROAMING

# --- Movement Settings ---
var speed = 50            # Normal (roaming / returning) speed
var chase_speed = 80      # Faster speed when chasing the player
var roam_distance = 200   # Max distance from spawn for roaming
var detection_range = 150 # Distance within which enemy notices the player
var gravity = 500         # Gravity pulling the enemy down
var jump_force = -200    # Jump force (negative is upward in 2D)

# --- Positions ---
var spawn_position        # Where the enemy starts
var target_position       # Position to move toward in ROAMING state
var chase_start_position  # Where the enemy began chasing

# --- Other ---
var player = null         # A reference to the player (set when detected)

# --- Child Nodes (onready) ---
@onready var move_timer: Timer = $MoveTimer
@onready var obstacle_ray: RayCast2D = $ObstacleRay
@onready var obstacle_ray_2: RayCast2D = $ObstacleRay2
@onready var ground_ray: RayCast2D = $GroundRay
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D



func _ready():
	# Store the original position so we can return here
	spawn_position = global_position
	target_position = global_position  # Initialize to avoid Nil
	
	# Randomize random number generation for each run
	randomize()
	
	# Set up a random move or rest cycle
	set_move_timer()
	
	# Connect the Timer's timeout signal to our function (if not done in the Editor)
	# move_timer.connect("timeout", self, "_on_MoveTimer_timeout")

func _physics_process(delta):
	# Apply gravity each frame
	velocity.y += gravity * delta

	# Act based on the current state
	match state:
		State.ROAMING:
			roam_state(delta)
		State.CHASING:
			chase_state(delta)
		State.RETURNING:
			return_state(delta)

	# Finally, move with collisions
	move_and_slide()
	
	# Flip sprite based on movement
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true
	
		# Play animations
	if is_on_floor():
		if velocity == Vector2(0, 0):
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walking")
	else:
		animated_sprite.play("jump")

# -------------------------------------------------------------------------
#  ROAMING
# -------------------------------------------------------------------------
func roam_state(delta):
	# Move horizontally toward the current target
	move_towards(target_position, speed)
	
	# If we've reached the target (or are close), stop moving
	if global_position.distance_to(target_position) < 5:
		velocity.x = 0
	
	# Check if player is close enough to start chasing
	detect_player()
	
	# Jump if we collide with an obstacle
	check_obstacles()
	
	

func detect_player():
	# If there's a player reference and they are within the detection range, chase
	if player and global_position.distance_to(player.global_position) < detection_range:
		chase_start_position = global_position
		state = State.CHASING

# -------------------------------------------------------------------------
#  CHASING
# -------------------------------------------------------------------------
func chase_state(delta):
	# If for some reason we no longer have a player reference, go back to spawn
	if player == null:
		state = State.RETURNING
		return
	
	# Move toward the player's position
	move_towards(player.global_position, chase_speed)
	
	# Jump if obstacle
	check_obstacles()
	
	# If the player is too far away from us OR from where we started chasing,
	# we return to spawn
	var dist_to_spawn = global_position.distance_to(spawn_position)
	var dist_to_chase_start = global_position.distance_to(chase_start_position)
	var dist_to_player = global_position.distance_to(player.global_position)
	
	if dist_to_player > detection_range * 2 or dist_to_spawn > roam_distance * 2 or dist_to_chase_start > roam_distance * 2:
		state = State.RETURNING

# -------------------------------------------------------------------------
#  RETURNING
# -------------------------------------------------------------------------
func return_state(delta):
	# Move back to the spawn position
	move_towards(spawn_position, speed)
	
	# Jump if obstacle
	check_obstacles()
	# Once we're near the spawn, go back to roaming
	if global_position.distance_to(spawn_position) < 10:
		# After deciding, restart the timer for the next random time
		set_move_timer()
		print ("Im back at spawn")
		state = State.ROAMING

# -------------------------------------------------------------------------
#  TIMER-BASED MOVEMENT / REST
# -------------------------------------------------------------------------
func set_move_timer():
	# Set a random wait time, e.g. 1 to 3 seconds
	move_timer.wait_time = randf_range(1.0, 3.0)
	move_timer.start()

func _on_move_timer_timeout() -> void:
	# Only do random move/rest logic if roaming
	if state == State.ROAMING:
		# 50/50 chance to rest or move
		if randi() % 2 == 0:
			# Calculate a random X offset from the spawn position
			var random_offset_x = randf_range(-roam_distance, roam_distance)
			target_position = spawn_position + Vector2(random_offset_x, 0)
			print("I move.")
		else:
			# Rest: Set the target to our current spot so we remain still
			print("I rest.")
			target_position = global_position
	else:
		print("not roaming")
	# After deciding, restart the timer for the next random time
	set_move_timer()



# -------------------------------------------------------------------------
#  HELPERS
# -------------------------------------------------------------------------
func move_towards(destination: Vector2, spd: float):
	var direction = (destination - global_position).normalized()
	velocity.x = direction.x * spd

func check_obstacles():
	# If on the floor and ObstacleRay sees a collision, attempt to jump
	if is_on_floor() and obstacle_ray.is_colliding() or obstacle_ray_2.is_colliding():
		# Only jump if there's ground in front, so we don't leap into a pit
		if ground_ray.is_colliding():
			velocity.y = jump_force
			print("Watch this!")

# -------------------------------------------------------------------------
#  DETECTING THE PLAYER
# -------------------------------------------------------------------------
func _on_player_detector_body_entered(body: Node2D) -> void:
	# If the body that entered is in the 'player' group, record it
	if body.is_in_group("player"):
		player = body
		print("I see him!")

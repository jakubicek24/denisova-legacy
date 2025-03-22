extends RigidBody2D

var throw_velocity: Vector2 = Vector2.ZERO

func _ready():
	# Give the rock an initial push
	linear_velocity = throw_velocity
	

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		print ("hit " + str(linear_velocity.length()))
		# we found an enemy, let’s do something
		if linear_velocity.length() > 200:
			body.apply_knockback(global_position, 200)
		else:
			body.apply_knockback(global_position, linear_velocity.length())
		

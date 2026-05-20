extends CharacterBody2D
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
# Uses your project's 2D gravity setting
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	# Jump (only when on ground)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	# Left / right
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
	move_and_slide()

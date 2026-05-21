# =============================================================================
# character_1.gd — 2D platformer player controller (Godot 4)
# =============================================================================
#
# Attach this script to a CharacterBody2D node (your player root).
# Expected child nodes in the scene:
#   - AnimatedSprite2D  → shows idle animation (name must match $ path below)
#   - CollisionPolygon2D or CollisionShape2D → so move_and_slide() can detect floors/walls
#
# HOW GODOT RUNS THIS SCRIPT (lifecycle):
#   _physics_process() → runs EVERY physics frame (~60 times/sec by default).
#                        Movement belongs here because physics is frame-rate independent
#                        when you multiply forces/velocity by `delta`.
#
# INPUT (Project → Project Settings → Input Map):
#   - move_left, move_right, jump  → must exist or get_axis / is_action_just_pressed fail silently.
#
# =============================================================================

# "extends" means this script ADDS behavior to a node type.
# CharacterBody2D is Godot's built-in node for kinematic/platformer characters:
# you set velocity, call move_and_slide(), and Godot resolves collisions for you.
extends CharacterBody2D

# -----------------------------------------------------------------------------
# @export — values editable in the Inspector without opening code
# -----------------------------------------------------------------------------
# When you select the player in the editor, speed and jump_velocity appear
# in the Inspector so you can tune feel without recompiling.

# Horizontal speed in pixels per second (higher = faster run).
@export var speed: float = 200.0

# Instant upward speed when jumping, in pixels per second.
# NEGATIVE because in 2D, Y points DOWN on screen (up = smaller Y).
@export var jump_velocity: float = -600.0

# -----------------------------------------------------------------------------
# Node references
# -----------------------------------------------------------------------------
# @onready: variable is assigned when the node is ready (children exist).
# $AnimatedSprite2D is shorthand for get_node("AnimatedSprite2D") — must be a direct child name.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# -----------------------------------------------------------------------------
# Internal state (variables only this script uses)
# -----------------------------------------------------------------------------
# Read default 2D gravity from Project Settings (Physics → 2D → Default Gravity).
# Same value the physics engine uses, so our manual gravity matches the world.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# =============================================================================
# _physics_process — movement, gravity, jump, sprite facing
# =============================================================================
# `delta` = seconds since last physics frame (e.g. ~0.016 at 60 FPS).
# Multiplying velocity changes by delta keeps motion consistent at any framerate.
func _physics_process(delta: float) -> void:
	# -------------------------------------------------------------------------
	# GRAVITY
	# -------------------------------------------------------------------------
	# is_on_floor() is provided by CharacterBody2D after move_and_slide() from the PREVIOUS frame.
	# If we're in the air, add downward acceleration each frame: velocity.y += gravity * delta
	if not is_on_floor():
		velocity.y += gravity * delta

	# -------------------------------------------------------------------------
	# JUMP
	# -------------------------------------------------------------------------
	# is_action_just_pressed: true only on the ONE frame the key was pressed (not while held).
	# Combined with is_on_floor() so you can't double-jump in mid-air (unless you add that later).
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Set vertical velocity once; gravity will pull the character down afterward.
		velocity.y = jump_velocity

	# -------------------------------------------------------------------------
	# HORIZONTAL INPUT
	# -------------------------------------------------------------------------
	# get_axis(negative_action, positive_action):
	#   holding move_left  → -1
	#   holding move_right → +1
	#   both or neither      → 0 (with optional deadzone in Input Map)
	var direction := Input.get_axis("move_left", "move_right")

	# -------------------------------------------------------------------------
	# HORIZONTAL MOVEMENT + SPRITE
	# -------------------------------------------------------------------------
	if direction != 0.0:
		# Moving: set horizontal speed = direction * speed (full speed left or right).
		velocity.x = direction * speed
		_update_facing(direction)
		_play_idle()
	else:
		# No input: slow down horizontally with move_toward (friction / deceleration).
		# Moves velocity.x toward 0 by at most `speed` pixels/sec until it reaches 0.
		velocity.x = move_toward(velocity.x, 0.0, speed)

	# -------------------------------------------------------------------------
	# APPLY MOVEMENT + COLLISIONS
	# -------------------------------------------------------------------------
	# move_and_slide() uses `velocity` to move the body, slide along floors/walls,
	# update is_on_floor(), is_on_wall(), etc., and may modify velocity when hitting things.
	move_and_slide()

# =============================================================================
# Sprite facing (left / right)
# =============================================================================
func _update_facing(direction: float) -> void:
	# flip_h mirrors the sprite horizontally.
	# Our art faces LEFT by default, so when moving RIGHT (direction > 0) we flip.
	# If your art faced right by default, you'd use: sprite.flip_h = direction < 0.0
	sprite.flip_h = direction > 0.0

# =============================================================================
# Idle animation (default while moving until you add "run")
# =============================================================================
func _play_idle() -> void:
	# Avoid restarting idle every frame (would reset animation from frame 0 constantly).
	if sprite.animation != &"idle":
		# play() starts an animation by name from the SpriteFrames resource on AnimatedSprite2D.
		# &"idle" is a StringName (efficient string id); must match animation name in editor.
		sprite.play(&"idle")

class_name PixelAnimator
extends RefCounted
## Manages pixel animation state and strategy.
## Handles timing and delegates frame generation to strategy.

# Animation Data
var source_positions: PackedVector2Array
var target_positions: PackedVector2Array
var colors: PackedColorArray
var image_size: Vector2i

# Animation State
var progress: float = 0.0
var duration: float = 2.0   # Animation duration in seconds
var is_playing: bool = false

# Strategy
var strategy: AnimationStrategy

func _init(
	source_pos: PackedVector2Array,
	target_pos: PackedVector2Array,
	pixel_colors: PackedColorArray,
	image_size_: Vector2i,
	anim_strategy: AnimationStrategy,
	anim_duration: float = 2.0
) -> void:
	source_positions = source_pos
	target_positions = target_pos
	colors = pixel_colors
	image_size = image_size_
	strategy = anim_strategy
	duration = anim_duration

	if strategy.has_method("pre_generate_frames"):
		strategy.pre_generate_frames(
			source_positions,
			target_positions,
			colors,
			image_size
		)

## Start the animation
func start() -> void:
	progress = 0.0
	is_playing = true

## Update animation sate
func update(delta: float) -> void:
	if not is_playing:
		return
	
	progress += delta / duration
	if is_complete():
		progress = 1.0
		is_playing = false

## Generate current animation frame
func get_current_frame() -> Image:
	return strategy.generate_frame(
		source_positions,
		target_positions,
		colors,
		progress,
		image_size
	)

## Check if animation is finished 
func is_complete() -> bool:
	return progress >= 1.0

## Reset to beginning
func reset() -> void:
	progress = 0.0
	is_playing = false

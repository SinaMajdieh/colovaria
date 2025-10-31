class_name AnimationStrategy
extends RefCounted
## Base class for pixel animation strategies.
## Subclasses implement different animation behaviors (linear, eased, waves, etc.)\

## Generate a single animation frame
func generate_frame(
    _source_pos: PackedVector2Array,
    _target_pos: PackedVector2Array,
    _colors: PackedColorArray,
    _progress: float,
    _image_size: Vector2i
) -> Image:
    push_error("generate_frame() must be implemented by subclass")
    return null

# Linearly interpolate between positions
func _interpolate_positions(
    source_pos: PackedVector2Array,
    target_pos: PackedVector2Array,
    progress: float
) -> PackedVector2Array:
    var results: PackedVector2Array = PackedVector2Array()
    results.resize(source_pos.size())

    for i: int in range(source_pos.size()):
        results.set(i, source_pos.get(i).lerp(target_pos.get(i), progress))
    
    return results

func cleanup() -> void:
    pass
class_name PixelRearranger
extends RefCounted

var source_pixels: PixelCollection = null
var target_pixels: PixelCollection = null

# === Public API ===

## Main entry point
## Rearranges source pixels to match target pixels
func rearrange(source: Image, target: Image) -> Image:
	if not are_images_valid(source, target):
		push_error("PixelRearranger: Invalid images provided.")
		return null
	
	# TODO: Implementation goes here
	print("PixelRearranger.rearrange() called")
	print("\tSource size: %v" % source.get_size())
	print("\tTarget size: %v" % target.get_size())

	# Extract pixels
	source_pixels = PixelCollection.extract_pixels(source)
	target_pixels = PixelCollection.extract_pixels(target)

	# Sort by brightness
	sort_by_brightness(source_pixels)
	sort_by_brightness(target_pixels)

	var result: Image = _build_result_image(target.get_size())

	return result

# === Private helpers ===

## Validates that both images exist and contains data
static func are_images_valid(source: Image, target: Image) -> bool:
	if source == null or target == null:
		return false
	if source.is_empty() or target.is_empty():
		return false
	return true

## Sorts pixel collection by brightness using counting sort (O(n) complexity)

func sort_by_brightness(collection: PixelCollection) -> void:
	print_rich("[color=cyan]Sorting %d pixels by brightness ..." % collection.size())
	var start_time: int = Time.get_ticks_msec()

	# Converts brightness to integers (0-255 range for counting sort)
	var brightness_ints: PackedInt32Array = PackedInt32Array()
	brightness_ints.resize(collection.size())
	for i: int in range(collection.size()):
		brightness_ints.set(i, int(collection.brightness.get(i) * 255.0))
	
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(256)  # 0-255 brightness level
	counts.fill(0)

	for value: int in brightness_ints:
		counts.set(value, counts.get(value) + 1)
	
	for i: int in range(1, 256):
		counts.set(i, counts.get(i) + counts.get(i - 1))
	
	var sorted_indices: PackedInt32Array = PackedInt32Array()
	sorted_indices.resize(collection.size())
	for i: int in range(collection.size() - 1, -1, -1):
		var value: int = brightness_ints.get(i)
		counts.set(value, counts.get(value) - 1)
		sorted_indices.set(counts.get(value), i)

	_render_by_indices(collection, sorted_indices)

	var elapsed: int = Time.get_ticks_msec() - start_time
	print_rich("\t[color=green]Sorting took %d ms" % elapsed)

func _render_by_indices(collection: PixelCollection, indices: PackedInt32Array) -> void:
	var new_color: PackedColorArray = PackedColorArray()
	var new_position: PackedVector2Array = PackedVector2Array()
	var new_brightness: PackedFloat32Array = PackedFloat32Array()

	new_color.resize(collection.size())
	new_position.resize(collection.size())
	new_brightness.resize(collection.size())

	for i: int in range(collection.size()):
		var old_index: int = indices[i]
		new_color.set(i, collection.colors.get(old_index))
		new_position.set(i, collection.positions.get(old_index))
		new_brightness.set(i, collection.brightness.get(old_index))
	
	collection.colors = new_color
	collection.positions = new_position
	collection.brightness = new_brightness

func _build_result_image(target_size: Vector2i) -> Image:
	print_rich("[color=cyan]Building result image ...")
	var start_time: int = Time.get_ticks_msec()

	var result: Image = Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)

	var pixel_count: int = min(source_pixels.size(), target_pixels.size())

	for i: int in range(pixel_count):
		var color: Color = source_pixels.colors.get(i)
		var positions: Vector2 = target_pixels.positions.get(i)
		result.set_pixelv(Vector2i(int(positions.x), int(positions.y)), color)
	
	var elapsed: int = Time.get_ticks_msec() - start_time
	print_rich("\t[color=green]Building took %d ms" % elapsed)

	return result

class_name PixelRearranger
extends RefCounted

# === Public API ===

## Main entry point
## Rearranges source pixels to match target pixels
func rearrange(source: Image, target: Image) -> Image:
	if not _are_images_valid(source, target):
		push_error("PixelRearranger: Invalid images provided.")
		return null
	
	# TODO: Implementation goes here
	print("PixelRearranger.rearrange() called")
	print("\tSource size: %v" % source.get_size())
	print("\tTarget size: %v" % target.get_size())

	# Extract pixels
	var source_pixels: PixelCollection = PixelCollection.extract_pixels(source)
	var target_pixels: PixelCollection = PixelCollection.extract_pixels(target)

	# Sort by brightness
	sort_by_brightness(source_pixels)
	sort_by_brightness(target_pixels)

	var result: Image = _build_result_image(source_pixels, target_pixels, target.get_size())

	return result

# === Private helpers ===

## Validates that both images exist and contains data
func _are_images_valid(source: Image, target: Image) -> bool:
	if source == null or target == null:
		return false
	if source.is_empty() or target.is_empty():
		return false
	return true

## Sorts pixel collection by brightness using indices 
func sort_by_brightness(collection: PixelCollection) -> void:
	print_rich("[color=cyan]Sorting %d pixels by brightness ..." % collection.size())
	var start_time: int = Time.get_ticks_msec()

	var sortable: Array[Array] = []
	sortable.resize(collection.size())
	for i: int in range(collection.size()):
		sortable.set(i, [collection.brightness.get(i), i])
	
	sortable.sort_custom(func(a, b): return a[0] < b[0])

	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize(collection.size())
	indices.resize(collection.size())
	for i: int in range(collection.size()):
		indices.set(i, sortable.get(i)[1])

	_render_by_indices(collection, indices)

	var elapsed: int = Time.get_ticks_msec() - start_time
	print_rich("\t[color=green]Sorting took %d ms" % elapsed)

func _swap_indices(indices: PackedInt32Array, i: int, j: int) -> void:
	var temp: int = indices.get(i)
	indices.set(i, indices.get(j))
	indices.set(j, temp)

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

func _build_result_image(source_pixels: PixelCollection, target_pixels: PixelCollection, target_size: Vector2i) -> Image:
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

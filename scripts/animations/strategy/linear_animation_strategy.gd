class_name LinearAnimationStrategy
extends AnimationStrategy
## Simple linear interpolation animation.
## Each pixel moves directly from source to target at constant speed.

var frame_cache: Array[Image] = []
var cached_frame_count: int = 60    # Pre-generated 30 frames

## Returns Nearest cached frame
func generate_frame(
	_source_pos: PackedVector2Array,
	_target_pos: PackedVector2Array,
	_colors: PackedColorArray,
	progress: float,
	_image_size: Vector2i
) -> Image:
	var frame_index: int = int(progress * (cached_frame_count - 1))
	frame_index = clamp(frame_index, 0, frame_cache.size() - 1)

	return frame_cache[frame_index]

## Pre-generate all animation frames.
## Call this once before animation starts.
func pre_generate_frames(
	source_pos: PackedVector2Array,
	target_pos: PackedVector2Array,
	colors: PackedColorArray,
	image_size: Vector2i
) -> void:
	print_rich("[color=cyan]Pre-generating %d frames..." % cached_frame_count)
	var total_start_time: int = Time.get_ticks_msec()

	frame_cache.clear()
	frame_cache.resize(cached_frame_count)

	for frame_index: int in range(cached_frame_count):
		var progress: float = float(frame_index) / float(cached_frame_count - 1)
		
		var frame_start_time: int = Time.get_ticks_msec()
		
		frame_cache[frame_index] = _generate_single_frame(
			source_pos,
			target_pos,
			colors,
			progress,
			image_size
		)
		
		var frame_time_elapsed: int = Time.get_ticks_msec() - frame_start_time

		print_rich("\t\t[color=yellow]Frame %d/%d generated in %d ms" % [frame_index + 1, cached_frame_count, frame_time_elapsed])

	var total_time_elapsed: int = Time.get_ticks_msec() - total_start_time
	print_rich("\t[color=green]All frames pre-generated in %.1f seconds" % (total_time_elapsed / 1000.0))

## Generate a single frame
func _generate_single_frame(
	source_pos: PackedVector2Array,
	target_pos: PackedVector2Array,
	colors: PackedColorArray,
	progress: float,
	image_size: Vector2i
) -> Image:
	var image: Image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)

	var data: PackedByteArray = image.get_data()
	var width: int = image_size.x
	var height: int = image_size.y
	var pixel_count: int = source_pos.size()

	for i: int in range(pixel_count):
		var current_pos: Vector2 = source_pos.get(i).lerp(target_pos.get(i), progress)
		var x: int = int(current_pos.x)
		var y: int = int(current_pos.y)
		
		if x < 0 or x >= width or y < 0 or y >= height:
			continue
		
		var offset: int = (y * width + x) * 3
		var color: Color = colors.get(i)
		data[offset] = int(color.r * 255)
		data[offset + 1] = int(color.g * 255)
		data[offset + 2] = int(color.b * 255)

	image.set_data(width, height, false, Image.FORMAT_RGB8, data)
	return image

## Export all cached frames as PNG files.
func export_frames_to_directory(output_dir: String) -> bool:
	if frame_cache.is_empty():
		push_error("No frame cached. call pre_generate_frames() first!")
		return false
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_absolute(output_dir)
	
	print_rich("[color=cyan]Exporting %d frames to %s" % [frame_cache.size(), output_dir])
	var start_time: int = Time.get_ticks_msec()

	for i: int in range(frame_cache.size()):
		var file_name: String = "%s/frame_%04d.png" % [output_dir, i]
		var err: int = frame_cache[i].save_png(file_name)

		if err != OK:
			push_error("Failed to save frame %d: %s" % [i, error_string(err)])
			return false

	var elapsed_time: int = Time.get_ticks_msec() - start_time
	print_rich("[color=cyan]All frames exported in %.1f seconds" % (elapsed_time * 0.001))
	return true

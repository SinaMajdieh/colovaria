class_name FlowFluidStrategy
extends AnimationStrategy
## Optimized flow fluid using raw byte manipulation

## Tunable parameters
@export var flow_strength: float = 15.0
@export var curl_intensity: float = 2.0
@export var target_pull_strength: float = 0.3
@export var noise_frequency: float = 0.008
@export var time_scale: float = 0.3

var flow_field: PackedVector2Array = PackedVector2Array()
var grid_size: int = 32
var grid_width: int = 0
var grid_height: int = 0
var noise: FastNoiseLite = null
var animation_time: float = 0.0

func _init() -> void:
    noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = noise_frequency
    noise.fractal_octaves = 3

func _setup_flow_fields(image_size: Vector2i) -> void:
    grid_width = ceili(image_size.x / float(grid_size))
    grid_height = ceili(image_size.y / float(grid_size))
    flow_field.resize(grid_width * grid_height)

    for y: int in range(grid_height):
        for x: int in range(grid_width):
            var world_x: float = x * grid_size + grid_size * 0.5
            var world_y: float = y * grid_size + grid_size * 0.5
            var angle: float = noise.get_noise_2d(world_x, world_y) * TAU
            flow_field[y * grid_width + x] = Vector2.from_angle(angle)

func _sample_flow_field(pos: Vector2, time_offset: float) -> Vector2:
    var grid_x: float = pos.x / grid_size
    var grid_y: float = pos.y / grid_size

    var x0: int = clampi(int(grid_x), 0, grid_width - 1)
    var y0: int = clampi(int(grid_y), 0, grid_height - 1)
    var x1: int = mini(x0 + 1, grid_width - 1)
    var y1: int = mini(y0 + 1, grid_height - 1)
    var fx: float = grid_x - x0
    var fy: float = grid_y - y0

    var v00: Vector2 = flow_field.get(y0 * grid_width + x0)
    var v10: Vector2 = flow_field.get(y0 * grid_width + x1)
    var v01: Vector2 = flow_field.get(y1 * grid_width + x0)
    var v11: Vector2 = flow_field.get(y1 * grid_width + x1)

    var flow: Vector2 = v00.lerp(v10, fx).lerp(v01.lerp(v11, fx), fy)
    var time_angle: float = noise.get_noise_3d(pos.x * 0.002, pos.y * 0.002, time_offset) * PI
    return flow.rotated(time_angle * 0.5)

func generate_frame(
    source_pos: PackedVector2Array,
    target_pos: PackedVector2Array,
    colors: PackedColorArray,
    progress: float,
    image_size: Vector2i
) -> Image:
    var frame_start: int = Time.get_ticks_usec()

    if flow_field.is_empty():
        _setup_flow_fields(image_size)
    
    animation_time += 0.016 * time_scale
    var eased_progress: float = _ease_in_out_cubic(progress)

    # Create black image
    var image: Image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.0, 0.0, 0.0, 1.0))   # Black Image

    # Get raw byte access
    var data: PackedByteArray = image.get_data()
    var pixel_count: int = source_pos.size()
    var width: int = image_size.x
    var height: int = image_size.y

    # Pre-calculate animation parameters
    var flow_intensity: float = sin(eased_progress * PI) * flow_strength
    var pull_force: float = pow(eased_progress, 1.5) * target_pull_strength

    # Process all pixels
    for i: int in range(pixel_count):
        var start: Vector2 = source_pos.get(i)
        var end: Vector2 = target_pos.get(i)
        var current_pos: Vector2 = start.lerp(end, eased_progress)

        # Flow field influence
        var flow: Vector2 = _sample_flow_field(current_pos, animation_time)
        current_pos += flow * flow_intensity
        current_pos += Vector2(-flow.y, flow.x) * curl_intensity * flow_intensity
        current_pos += (end - current_pos) * pull_force

        # Clamp and convert to integer coordinates
        var x: int = clampi(int(current_pos.x), 0, width - 1)
        var y: int = clampi(int(current_pos.y), 0, height - 1)

        # Write directly to byte array (RGBA format -> 4 bytes per pixel)
        var byte_index: int = (y * width + x) * 4
        var color: Color = colors.get(i)
        data[byte_index] = int(color.r * 255)       # R
        data[byte_index + 1] = int(color.g * 255)   # G
        data[byte_index + 2] = int(color.b * 255)   # B
        data[byte_index + 3] = 255                  # A

    # Create image from modified bytes
    image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)

    var frame_time: float = (Time.get_ticks_usec() - frame_start) * 0.001
    print_rich("[color=yellow]\tFrame at %.0f%% took %.1f ms" % [progress * 100, frame_time])

    return image


func _ease_in_out_cubic(progress: float) -> float:
    return 4.0 * pow(progress, 3.0) if progress < 0.5 else 0.5 * pow(2.0 * progress - 2.0, 3.0) + 1.0

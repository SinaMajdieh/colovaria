class_name GPUFlowFieldStrategy
extends AnimationStrategy
## GPU-accelerated flow field animation using compute shaders.
## Achieves 60+ FPS with millions of particles.

const shader_path: String = "res://scripts/Shaders/flow_field_particles.glsl"

var rd: RenderingDevice
var shader: RID
var pipeline: RID

# === Buffer RIDs ===
var source_buffer: RID
var target_buffer: RID
var color_buffer: RID
var output_texture: RID

# === Uniform set ===
var uniform_set: RID

var image_size: Vector2i
var particle_count: int 
var is_initialized: bool = false

@export var animation_fps: int = 60
@export var flow_strength: float = 10.0
@export var curl_intensity: float = 1.0
@export var target_pull_strength: float = 0.1
@export var time_scale: float = 0.8

var animation_time: float = 0.0

func _init() -> void:
    # Get rendering device
    rd = RenderingServer.create_local_rendering_device()
    if not rd:
        push_error("rendering Device not available! GPU compute requires Vulkan/OpenGL 4.3+")
        return

func setup(
    source_pos: PackedVector2Array,
	target_pos: PackedVector2Array,
	colors: PackedColorArray,
	image_size_: Vector2i
) -> bool:
    if not rd:
        return false
    
    print_rich("[color=cyan]","Setting up GPU compute Pipeline")
    var setup_start: int = Time.get_ticks_msec()

    image_size = image_size_
    particle_count = source_pos.size()

    _load_shader()
    _create_buffers(source_pos, target_pos, colors)
    _create_uniform_set()

    is_initialized = true
    var setup_time: int = Time.get_ticks_msec() - setup_start
    print_rich("[color=green]","\tGPU setup completed in %d ms" % setup_time)
    print_rich("[color=green]","\tParticle count: %.2fM" % [particle_count * 0.000_001])
    print_rich("[color=green]","\tImage size: %dx%d" % [image_size.x, image_size.y])

    return true

func generate_frame(
    source_pos: PackedVector2Array,
    target_pos: PackedVector2Array,
    colors: PackedColorArray,
    progress: float,
    image_size_: Vector2i
) -> Image:
    if not is_initialized:
        if not setup(source_pos, target_pos, colors, image_size_):
            return Image.create_empty(image_size_.x, image_size_.y, false, Image.FORMAT_RGBA8)
    
    animation_time += 1.0 / float(animation_fps) * time_scale

    # Dispatch
    _dispatch(PackedFloat32Array([
        progress,
        animation_time,
        flow_strength,
        curl_intensity,
        target_pull_strength,
        float(particle_count),
        float(image_size_.x),
        float(image_size_.y),
    ]))

    # Read back texture data
    var byte_data: PackedByteArray = rd.texture_get_data(output_texture, 0)
    return Image.create_from_data(image_size_.x, image_size_.y, false, Image.FORMAT_RGBA8, byte_data)

# === Helper ===

func _load_shader(path: String = shader_path) -> void:
    var shader_file: Resource = load(path) as RDShaderFile
    var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
    shader = rd.shader_create_from_spirv(shader_spirv)
    pipeline = rd.compute_pipeline_create(shader)

func _create_buffers(
    source_pos: PackedVector2Array,
    target_pos: PackedVector2Array,
    colors: PackedColorArray
) -> void:
    source_buffer = _create_vec2_buffer(source_pos)
    target_buffer = _create_vec2_buffer(target_pos)
    color_buffer = _create_color_buffer(colors)
    output_texture = _create_output_texture(image_size)

func _create_uniform_set() -> void:
    var uniforms : Array[RDUniform] = [
        _create_uniform(0, source_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
        _create_uniform(1, target_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
        _create_uniform(2, color_buffer, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
        _create_uniform(3, output_texture, RenderingDevice.UNIFORM_TYPE_IMAGE),
    ]
    uniform_set = rd.uniform_set_create(uniforms, shader, 0)

func _dispatch(push_constant: PackedFloat32Array) -> void:
    # Create compute list
    var compute_list: int = rd.compute_list_begin()
    rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
    rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

    rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)

    # Dispatch Compute (256 threads per groupe)
    var group_count: int = ceili(particle_count / 256.0)
    rd.compute_list_dispatch(compute_list, group_count, 1, 1)
    rd.compute_list_end()

    # Submit and Sync
    rd.submit()
    rd.sync()

func _create_vec2_buffer(data: PackedVector2Array) -> RID:
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(data.size() * 8)  # vec2 = 8 bytes
    for i: int in range(data.size()):
        bytes.encode_float(i * 8, data[i].x)
        bytes.encode_float(i * 8 + 4, data[i].y)
    return rd.storage_buffer_create(bytes.size(), bytes)

func _create_color_buffer(data: PackedColorArray) -> RID:
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(data.size() * 16)  # vec4 = 16 bytes
    for i: int in range(data.size()):
        bytes.encode_float(i * 16, data[i].r)
        bytes.encode_float(i * 16 + 4, data[i].g)
        bytes.encode_float(i * 16 + 8, data[i].b)
        bytes.encode_float(i * 16 + 12, data[i].a)
    return rd.storage_buffer_create(bytes.size(), bytes)

func _create_output_texture(size: Vector2i) -> RID:
    var format: RDTextureFormat = RDTextureFormat.new()
    format.width = size.x
    format.height = size.y
    format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
    format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
                        RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

    var view: RDTextureView = RDTextureView.new()
    return rd.texture_create(format, view)

func _create_uniform(binding: int, rid: RID, type: RenderingDevice.UniformType) -> RDUniform:
    var uniform: RDUniform = RDUniform.new()
    uniform.uniform_type = type
    uniform.binding = binding
    uniform.add_id(rid)
    return uniform

func cleanup() -> void:
    if not rd:
        return

    if uniform_set.is_valid():
        rd.free_rid(uniform_set)
    if source_buffer.is_valid():
        rd.free_rid(source_buffer)
    if target_buffer.is_valid():
        rd.free_rid(target_buffer)
    if color_buffer.is_valid():
        rd.free_rid(color_buffer)
    if output_texture.is_valid():
        rd.free_rid(output_texture)
    if pipeline.is_valid():
        rd.free_rid(pipeline)
    if shader.is_valid():
        rd.free_rid(shader)
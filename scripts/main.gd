extends Control

@export_file() var source_path: String
@export_file() var target_path: String
@export var display: AnimatedPixelDisplay

func _ready() -> void:
    var source: Image = load(source_path).get_image()
    var target: Image = load(target_path).get_image()

    if not PixelRearranger.are_images_valid(source, target):
        push_error("Failed to load images")
        return
    
    var rearranger: PixelRearranger = PixelRearranger.new()
    rearranger.rearrange(source, target)

    var animator: PixelAnimator = PixelAnimator.new(
        rearranger.source_pixels.positions,
        rearranger.target_pixels.positions,
        rearranger.source_pixels.colors,
        source.get_size(),
        GPUFlowFieldStrategy.new(),
        15.0
    )

    #animator.strategy.export_frames_to_directory("user://animation_frames_2")

    display.start_animation(animator)


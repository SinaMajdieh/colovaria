extends Control

@export_file() var source_path: String
@export_file() var target_path: String
@export var display: AnimatedPixelDisplay
@export var flow_field_panel: FlowFieldPanel
@export var morph_button: Button

var rearrange_thread: Thread = null

var rearranger: PixelRearranger = null
var source: Image = null
var target: Image = null

func _connect_signals() -> void:
	flow_field_panel.animate.connect(animate)
	display.started.connect(flow_field_panel.disable_button)
	display.ended.connect(flow_field_panel.enable_button)
	morph_button.pressed.connect(morph)

func _ready() -> void:
	_connect_signals()
	source = load(source_path).get_image()
	target = load(target_path).get_image()

	if not PixelRearranger.are_images_valid(source, target):
		push_error("Failed to load images")
		return

	display.current_texture.set_image(source)

	flow_field_panel.set_from_strategy()

func morph() -> void:
	morph_button.disabled = true
	morph_button.text = "Morphing ..."
	rearrange_thread = Thread.new()
	rearrange_thread.start(_rearrange)

func _rearrange() -> void:
	rearranger = PixelRearranger.new()
	rearranger.rearrange(source, target)
	morph_button.call_deferred("hide")

	
func animate(strategy: GPUFlowFieldStrategy, duration: float) -> void:
	if not rearranger:
		return
	var animator: PixelAnimator = PixelAnimator.new(
		rearranger.source_pixels.positions,
		rearranger.target_pixels.positions,
		rearranger.source_pixels.colors,
		target.get_size(),
		strategy,
		duration
	)

	display.start_animation(animator)

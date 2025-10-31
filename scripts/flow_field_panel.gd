class_name FlowFieldPanel
extends PanelContainer

signal animate(strategy: GPUFlowFieldStrategy, duration: float)

@export var animation_fps_spin: SpinBox
@export var flow_strength_spin: SpinBox
@export var curl_intensity_spin: SpinBox
@export var target_pull_strength_spin: SpinBox
@export var time_scale_spin: SpinBox
@export var animation_duration_spin: SpinBox

@export var animate_button: Button

func _ready() -> void:
	animate_button.pressed.connect(_animate)

func set_from_strategy(strategy: GPUFlowFieldStrategy = GPUFlowFieldStrategy.new()) -> void:
	animation_fps_spin.value = strategy.animation_fps
	flow_strength_spin.value = strategy.flow_strength
	curl_intensity_spin.value = strategy.curl_intensity
	target_pull_strength_spin.value = strategy.target_pull_strength
	time_scale_spin.value = strategy.time_scale

func _animate() -> void:
	var strategy: GPUFlowFieldStrategy = GPUFlowFieldStrategy.new()
	strategy.animation_fps = int(animation_fps_spin.value)
	strategy.flow_strength = flow_strength_spin.value
	strategy.curl_intensity = curl_intensity_spin.value
	strategy.target_pull_strength = target_pull_strength_spin.value
	strategy.time_scale = time_scale_spin.value

	animate.emit(strategy, animation_duration_spin.value)

func enable_button() -> void:
	animate_button.disabled = false

func disable_button() -> void:
	animate_button.disabled = true
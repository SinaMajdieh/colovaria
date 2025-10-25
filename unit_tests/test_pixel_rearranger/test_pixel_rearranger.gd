extends Control

@export_file() var source_path: String
@export_file() var target_path: String

@export var texture_rect: TextureRect

func _ready() -> void:
	var rearranger: PixelRearranger = PixelRearranger.new()

	var source: Image = load(source_path).get_image()
	var target: Image = load(target_path).get_image()

	var result: Image = rearranger.rearrange(source, target)

	var image_texture: ImageTexture = ImageTexture.create_from_image(result)
	texture_rect.texture = image_texture

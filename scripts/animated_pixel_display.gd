extends TextureRect
class_name AnimatedPixelDisplay
## Display node for pixel animation.
## Shows animated frames as they're generated.

var animator: PixelAnimator = null
var current_texture: ImageTexture = null

func _ready() -> void:
    # Setup Texture
    current_texture = ImageTexture.new()
    texture = current_texture

    # Set Reasonable Defaults
    expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

## Start displaying animation.
func start_animation(animator_: PixelAnimator) -> void:
    animator = animator_
    animator.start()
    set_process(true)
    print_rich("[color=cyan]Animation Started (duration: %.1fs)" % animator.duration)

func _process(delta: float) -> void:
    if animator == null or not animator.is_playing:
        if animator != null and animator.is_complete():
            print_rich("[color=cyan]Animation completed!")
            set_process(false)
        return
    
    # Update animation state
    animator.update(delta)

    var frame: Image = animator.get_current_frame()
    current_texture.set_image(frame)

## Stop the animation
func stop_animation() -> void:
    if animator != null:
        animator.is_playing = false
    set_process(false)

## Reset animation to beginning
func reset_animation() -> void:
    if animator != null:
        animator.reset()
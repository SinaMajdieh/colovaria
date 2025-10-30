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
    print("Extracted %d source pixels" % source_pixels.count)
    print("Extracted %d target pixels" % target_pixels.count)

    return target.duplicate()   #? Placeholder

# === Private helpers ===

## Validates that both images exist and contains data
func _are_images_valid(source: Image, target: Image) -> bool:
    if source == null or target == null:
        return false
    if source.is_empty() or target.is_empty():
        return false
    return true
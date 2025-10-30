class_name PixelCollection

var colors: PackedColorArray
var positions: PackedVector2Array
var brightness: PackedFloat32Array
var count: int :
    get = size

func _init(size_: int) -> void:
    count = size_
    colors.resize(size_)
    positions.resize(size_)
    brightness.resize(size_)

static func calculate_brightness(c: Color) -> float:
    # Luminance Formula 0.299R + 0.578G + 0.114B
    return 0.299 * c.r + 0.578 * c.g + 0.114 * c.b

## Extract all pixels from an image into a collection of packed arrays
static func extract_pixels(image: Image) -> PixelCollection:
    var image_size: Vector2i = image.get_size()
    var total_pixels: int = image_size.x * image_size.y

    print_rich("[color=cyan]Extracting %d Pixels ..." % total_pixels)
    var start_time: int = Time.get_ticks_msec()

    var collection: PixelCollection = PixelCollection.new(total_pixels)

    if image.get_format() != Image.FORMAT_RGBA8:
        image.convert(Image.FORMAT_RGBA8)
    
    var data: PackedByteArray = image.get_data()

    var pixel_index: int = 0
    for y: int in range(image_size.y):
        for x: int in range(image_size.x):
            var byte_index: int = (y * image_size.x + x) * 4  # 4 bytes per RGBA pixel
            var r: float = data[byte_index] / 255.0
            var g: float = data[byte_index + 1] / 255.0
            var b: float = data[byte_index + 2] / 255.0
            var a: float = data[byte_index + 3] / 255.0

            collection.colors.set(pixel_index, Color(r, g, b, a)) 
            collection.positions.set(pixel_index, Vector2(x, y))
            collection.brightness.set(pixel_index, 0.299 * r + 0.578 * g + 0.114 * b)

            pixel_index += 1
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    print_rich("\t[color=green]Extraction took %d ms (%.2f Mpixels/sec)" % [elapsed, float(total_pixels) / elapsed * 0.001])
    return collection

func size() -> int:
    return count
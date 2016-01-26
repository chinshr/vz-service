## BEGIN - Image Formats
#
@image_formats = []

## 1:1 (1.00) image formats (icons)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 500, 500, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 250, 250, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 180, 180, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 115, 115, false)

## 2:1 (2.00) image formats (banners - normal)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 1000, 500, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  500, 250, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  350, 175, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  250, 125, false)

## 2.4:1 (2.40) image formats (banners - medium wide)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 1080, 450, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  540, 225, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  360, 150, false)

## 3:1 (3.00) image formats (banners - wide)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 500, 166, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 314, 104, false)

## 6:9 (0.67) image formats (posters -  wide)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 960, 1440, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 600,  900, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 450,  675, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 300,  450, false)

## 3:4 (0.75) image formats (posters - medium wide)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 600, 800, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 450, 600, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 300, 400, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 208, 277, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 177, 236, false)

## 5:8 (0.62) image formats (posters - normal)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 500, 800, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 300, 480, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 150, 240, false)

## 5:3.75 (1.33) image formats (icons - xbox)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 500, 375, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 421, 316, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 314, 236, false)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 208, 156, false)

## Misc image formats (web)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 1280, 534, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg', 1280, 251, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  960, 540, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  630, 361, true)
@image_formats << Image::ImageFormat.find_or_create_by_format_and_width_and_height_and_is_source('jpg',  314, 268, true)

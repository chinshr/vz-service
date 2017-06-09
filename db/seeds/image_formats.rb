## BEGIN - Image Formats
#
@image_formats = []

## 1:1 (1.00) image formats (icons)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 500, height: 500, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 250, height: 250, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 180, height: 180, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 115, height: 115, is_source: false).first_or_create

## 2:1 (2.00) image formats (banners - normal)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 1000, height: 500, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 500, height: 250, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 350, height: 175, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 250, height: 125, is_source: false).first_or_create

## 2.4:1 (2.40) image formats (banners - medium wide)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 1080, height: 450, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 540, height: 225, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 360, height: 150, is_source: false).first_or_create

## 3:1 (3.00) image formats (banners - wide)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 540, height: 166, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 314, height: 104, is_source: false).first_or_create

## 6:9 (0.67) image formats (posters -  wide)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 960, height: 1440, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 600, height: 900, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 450, height: 675, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 300, height: 450, is_source: false).first_or_create

## 3:4 (0.75) image formats (posters - medium wide)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 600, height: 800, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 450, height: 600, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 300, height: 400, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 208, height: 277, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 177, height: 236, is_source: false).first_or_create

## 5:8 (0.62) image formats (posters - normal)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 500, height: 800, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 300, height: 480, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 150, height: 240, is_source: false).first_or_create

## 5:3.75 (1.33) image formats (icons - xbox)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 500, height: 375, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 421, height: 316, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 314, height: 236, is_source: false).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 208, height: 156, is_source: false).first_or_create

## Misc image formats (web)
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 1280, height: 534, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 1280, height: 251, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 960, height: 540, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 630, height: 361, is_source: true).first_or_create
@image_formats << Image::ImageFormat.where(format: 'jpg', width: 314, height: 268, is_source: true).first_or_create

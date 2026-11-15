"""Rasterize the repo's original wallet/receipt icon for native launchers.
Development-only dependency: Pillow. Not used by RPM at runtime.
Geometry matches assets/rpm-mark.svg.
"""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
scale = 2
image = Image.new('RGBA', (1024 * scale, 1024 * scale))
draw = ImageDraw.Draw(image)
def rect(box, radius, color):
    draw.rounded_rectangle(tuple(v * scale for v in box), radius=radius * scale, fill=color)
rect((64, 64, 960, 960), 210, '#111d36')
rect((310, 206, 708, 680), 38, '#f4f6fa')
for y, end in [(292, 634), (354, 562), (416, 608)]:
    draw.line((384 * scale, y * scale, end * scale, y * scale), fill='#c0c9da', width=24 * scale)
    for x in [384, end]:
        draw.ellipse(((x-12)*scale, (y-12)*scale, (x+12)*scale, (y+12)*scale), fill='#c0c9da')
rect((206, 466, 818, 806), 64, '#7467e5')
rect((612, 562, 842, 704), 36, '#16856b')
draw.ellipse((660*scale, 616*scale, 692*scale, 648*scale), fill='white')
for size in [16, 32, 64, 128, 256, 512, 1024]:
    icon = image.resize((size, size), Image.Resampling.LANCZOS)
    icon.save(root / f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png')
image.resize((256, 256), Image.Resampling.LANCZOS).save(
    root / 'windows/runner/resources/app_icon.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])

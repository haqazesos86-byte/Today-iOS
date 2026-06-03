"""
Generate 1024x1024 App Store App Icon for Today
- Dark green background (matching app accent #1F8A4C)
- White "今" character in center (the day character)
- Minimal, no rounded corners (iOS adds them automatically)
"""
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
BG_COLOR = (31, 138, 76, 255)  # #1F8A4C - matches accent color
TEXT_COLOR = (255, 255, 255, 255)

# Create image
img = Image.new('RGBA', (SIZE, SIZE), BG_COLOR)
draw = ImageDraw.Draw(img)

# Try to use a system Chinese font; fall back to default
font = None
font_candidates = [
    'C:/Windows/Fonts/msyh.ttc',  # Microsoft YaHei
    'C:/Windows/Fonts/msyh.ttf',
    'C:/Windows/Fonts/simhei.ttf',  # SimHei
    'C:/Windows/Fonts/simsun.ttc',  # SimSun
    '/System/Library/Fonts/PingFang.ttc',  # macOS
    '/System/Library/Fonts/STHeiti Light.ttc',
    '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc',  # Linux
]

for path in font_candidates:
    if os.path.exists(path):
        try:
            # For ttc files, may need index
            if path.endswith('.ttc'):
                font = ImageFont.truetype(path, 720)
            else:
                font = ImageFont.truetype(path, 720)
            print(f"Using font: {path}")
            break
        except Exception as e:
            print(f"Failed {path}: {e}")
            continue

if font is None:
    print("No Chinese font found, using default")
    font = ImageFont.load_default()

# Draw "今" centered
text = "今"

# Calculate text position (centered)
try:
    # Newer Pillow
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (SIZE - text_width) // 2 - bbox[0]
    text_y = (SIZE - text_height) // 2 - bbox[1] - 30  # slight up shift for visual balance
except AttributeError:
    # Older Pillow
    text_width, text_height = draw.textsize(text, font=font)
    text_x = (SIZE - text_width) // 2
    text_y = (SIZE - text_height) // 2 - 30

draw.text((text_x, text_y), text, font=font, fill=TEXT_COLOR)

# Output
out_path = "D:/claude code文件夹/Today/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
os.makedirs(os.path.dirname(out_path), exist_ok=True)
img.save(out_path, 'PNG')
print(f"✅ Saved: {out_path} ({SIZE}x{SIZE})")

# Verify
import os
size = os.path.getsize(out_path)
print(f"File size: {size:,} bytes")

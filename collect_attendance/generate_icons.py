import sys
try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

input_path = r"C:\Users\Vibhav\.gemini\antigravity-ide\brain\2bc523e6-16d6-4ef4-8424-4c3c8b9fc505\rollcall_flat_1780582735227.png"
fg_path = "assets/icon_foreground.png"
mono_path = "assets/icon_monochrome.png"

img = Image.open(input_path).convert("RGBA")
datas = img.getdata()

# Create Foreground (transparent background)
fg_data = []
for item in datas:
    # If pixel is close to white, make transparent
    if item[0] > 230 and item[1] > 230 and item[2] > 230:
        # Calculate alpha based on how close to white it is to preserve anti-aliasing
        # White is 255. 230 -> alpha 255, 255 -> alpha 0
        alpha = int(255 - ((item[0] - 230) / 25.0) * 255)
        # alpha should not be negative
        alpha = max(0, min(255, alpha))
        fg_data.append((item[0], item[1], item[2], alpha))
    else:
        fg_data.append(item)

fg_img = Image.new("RGBA", img.size)
fg_img.putdata(fg_data)
fg_img.save(fg_path, "PNG")

# Create Monochrome (solid black on transparent)
mono_data = []
for item in fg_data:
    if item[3] > 0: # If not fully transparent
        mono_data.append((0, 0, 0, item[3]))
    else:
        mono_data.append((0, 0, 0, 0))

mono_img = Image.new("RGBA", img.size)
mono_img.putdata(mono_data)
mono_img.save(mono_path, "PNG")

print("Icons generated successfully!")

import os
from PIL import Image

p = r"godot\assets\sprites\character\16x32_elderly\16x32 Idle-Sheet.png"
im = Image.open(p).crop((0, 0, 32, 32))
pixels = im.load()

for y in range(6, 32):
    line = []
    for x in range(6, 26):
        r, g, b, a = pixels[x, y]
        if a == 0:
            line.append(" ")
        elif (r, g, b) in [(242, 245, 248), (205, 212, 220)]:
            line.append("H") # Hair
        elif (r, g, b) in [(250, 222, 198), (225, 195, 170)]:
            line.append("S") # Skin
        elif (r, g, b) in [(93, 127, 100), (68, 96, 74), (118, 152, 125)]:
            line.append("C") # Clothes
        else:
            line.append("X") # Outline/Pants/Shoes
    print(f"{y:2d}: {''.join(line)}")

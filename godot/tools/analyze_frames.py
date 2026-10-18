import os
from PIL import Image

dirpath = r"godot\assets\sprites\character\16x32_elderly"
sheets = [
    "16x32 Idle-Sheet.png",
    "16x32 Walk-Sheet.png",
    "16x32 Attack-Sheet.png",
    "16x32 Interact-Sheet.png",
    "16x32 Run-Sheet.png",
    "16x32 Jump-Sheet.png"
]
rows = ["s", "se", "e", "ne", "n"]

for sheet_name in sheets:
    p = os.path.join(dirpath, sheet_name)
    im = Image.open(p)
    cols = im.size[0] // 32
    print(f"=== {sheet_name} (cols={cols}, size={im.size}) ===")
    for r_idx, r_name in enumerate(rows):
        boxes = []
        for c in range(cols):
            box = im.crop((c * 32, r_idx * 32, (c + 1) * 32, (r_idx + 1) * 32))
            boxes.append(box.getbbox())
        print(f"Row {r_idx} ({r_name:2s}): bboxes={boxes}")


from PIL import Image, ImageDraw
import os

OUTPUT_PATH = "godot/assets/sprites/mobs/pedestrian_rosa_32x32.png"

def create_pedestrian_rosa():
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Cores
    outline = (42, 28, 20, 255)
    shadow = (30, 20, 15, 70)
    skin = (248, 216, 196, 255)
    skin_shadow = (220, 185, 165, 255)
    blush = (240, 165, 165, 255)
    hair = (235, 235, 240, 255)
    hair_shadow = (185, 185, 195, 255)
    hat = (145, 95, 135, 255)
    hat_shadow = (115, 70, 105, 255)
    hat_ribbon = (215, 170, 85, 255)
    shawl = (165, 115, 150, 255)
    shawl_shadow = (130, 85, 118, 255)
    shawl_hi = (185, 135, 170, 255)
    skirt = (52, 48, 68, 255)
    skirt_shadow = (38, 34, 52, 255)
    shoes = (35, 25, 20, 255)
    basket = (195, 145, 85, 255)
    basket_dark = (155, 105, 55, 255)
    greens = (85, 155, 75, 255)

    # 1. Sombra de contato
    draw.ellipse([8, 27, 24, 31], fill=shadow)

    # 2. Sapatos
    draw.rectangle([11, 28, 14, 29], fill=outline)
    draw.rectangle([11, 28, 13, 29], fill=shoes)
    draw.rectangle([17, 28, 20, 29], fill=outline)
    draw.rectangle([17, 28, 19, 29], fill=shoes)

    # 3. Saia longa
    draw.polygon([(11, 21), (20, 21), (22, 28), (9, 28)], fill=outline)
    draw.polygon([(12, 21), (19, 21), (21, 27), (10, 27)], fill=skirt)
    draw.line([(16, 22), (17, 27)], fill=skirt_shadow, width=1)

    # 4. Xale / Casaco
    draw.rectangle([10, 14, 21, 22], fill=outline)
    draw.rectangle([11, 14, 20, 21], fill=shawl)
    draw.line([(11, 15), (11, 21)], fill=shawl_hi, width=1)
    draw.line([(20, 15), (20, 21)], fill=shawl_shadow, width=1)
    draw.rectangle([14, 15, 17, 18], fill=shawl_shadow)

    # Broche dourado
    img.putpixel((15, 16), (245, 210, 80, 255))

    # 5. Cesta de feira na mão esquerda
    draw.rectangle([6, 18, 10, 24], fill=outline)
    draw.rectangle([7, 19, 9, 23], fill=basket)
    img.putpixel((8, 20), basket_dark)
    img.putpixel((8, 22), basket_dark)
    img.putpixel((7, 17), greens)
    img.putpixel((8, 16), greens)
    img.putpixel((9, 17), (215, 160, 95, 255))
    draw.line([(8, 17), (8, 18)], fill=basket_dark, width=1)
    img.putpixel((9, 18), skin)

    # 6. Cabeça e Rosto
    draw.ellipse([11, 7, 20, 15], fill=outline)
    draw.ellipse([12, 8, 19, 14], fill=skin)
    draw.ellipse([9, 7, 13, 12], fill=hair)
    draw.ellipse([18, 7, 22, 12], fill=hair)
    img.putpixel((10, 9), hair_shadow)
    img.putpixel((21, 9), hair_shadow)

    # Olhos sorridentes
    img.putpixel((14, 11), outline)
    img.putpixel((17, 11), outline)
    # Bochechas rosadas
    img.putpixel((13, 12), blush)
    img.putpixel((18, 12), blush)
    # Boca
    img.putpixel((15, 13), skin_shadow)
    img.putpixel((16, 13), skin_shadow)

    # 7. Chapéu / Boina
    draw.polygon([(10, 6), (21, 5), (23, 8), (8, 9)], fill=outline)
    draw.polygon([(11, 6), (20, 5), (22, 8), (9, 8)], fill=hat)
    draw.line([(10, 8), (21, 7)], fill=hat_ribbon, width=1)
    draw.line([(12, 6), (19, 5)], fill=hat_shadow, width=1)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    img.save(OUTPUT_PATH)
    print("Dona Rosa sprite created at:", OUTPUT_PATH)

if __name__ == "__main__":
    create_pedestrian_rosa()

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = "godot/assets/sprites/mobs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

OUTLINE = (38, 24, 16, 255)
SHADOW = (30, 20, 15, 70)

def draw_rosa_frame(draw, img, offset_x, step_frame):
    # Base coordinates shifted by offset_x
    ox = offset_x
    
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

    bob_y = 0
    if step_frame == 1:
        bob_y = -1
    elif step_frame == 3:
        bob_y = -1

    # 1. Sombra de contato
    draw.ellipse([ox + 8, 27, ox + 24, 31], fill=shadow)

    # 2. Sapatos (movimento de passos alternados)
    if step_frame == 0 or step_frame == 2:
        draw.rectangle([ox + 11, 28, ox + 14, 29], fill=outline)
        draw.rectangle([ox + 11, 28, ox + 13, 29], fill=shoes)
        draw.rectangle([ox + 17, 28, ox + 20, 29], fill=outline)
        draw.rectangle([ox + 17, 28, ox + 19, 29], fill=shoes)
    elif step_frame == 1:
        # Pé esquerdo à frente, pé direito atrás
        draw.rectangle([ox + 9, 28, ox + 13, 29], fill=outline)
        draw.rectangle([ox + 9, 28, ox + 12, 29], fill=shoes)
        draw.rectangle([ox + 18, 27, ox + 21, 28], fill=outline)
        draw.rectangle([ox + 18, 27, ox + 20, 28], fill=shoes)
    elif step_frame == 3:
        # Pé direito à frente, pé esquerdo atrás
        draw.rectangle([ox + 12, 27, ox + 15, 28], fill=outline)
        draw.rectangle([ox + 12, 27, ox + 14, 28], fill=shoes)
        draw.rectangle([ox + 18, 28, ox + 22, 29], fill=outline)
        draw.rectangle([ox + 18, 28, ox + 21, 29], fill=shoes)

    # 3. Saia longa
    sway = 0
    if step_frame == 1:
        sway = -1
    elif step_frame == 3:
        sway = 1
        
    draw.polygon([(ox + 11, 21 + bob_y), (ox + 20, 21 + bob_y), (ox + 22 + sway, 28), (ox + 9 + sway, 28)], fill=outline)
    draw.polygon([(ox + 12, 21 + bob_y), (ox + 19, 21 + bob_y), (ox + 21 + sway, 27), (ox + 10 + sway, 27)], fill=skirt)
    draw.line([(ox + 16 + sway, 22 + bob_y), (ox + 17 + sway, 27)], fill=skirt_shadow, width=1)

    # 4. Xale / Casaco
    draw.rectangle([ox + 10, 14 + bob_y, ox + 21, 22 + bob_y], fill=outline)
    draw.rectangle([ox + 11, 14 + bob_y, ox + 20, 21 + bob_y], fill=shawl)
    draw.line([(ox + 11, 15 + bob_y), (ox + 11, 21 + bob_y)], fill=shawl_hi, width=1)
    draw.line([(ox + 20, 15 + bob_y), (ox + 20, 21 + bob_y)], fill=shawl_shadow, width=1)
    draw.rectangle([ox + 14, 15 + bob_y, ox + 17, 18 + bob_y], fill=shawl_shadow)
    img.putpixel((ox + 15, 16 + bob_y), (245, 210, 80, 255)) # Broche dourado

    # 5. Cesta de feira
    basket_sway = 0
    if step_frame == 1:
        basket_sway = 1
    elif step_frame == 3:
        basket_sway = -1

    draw.rectangle([ox + 6 + basket_sway, 18 + bob_y, ox + 10 + basket_sway, 24 + bob_y], fill=outline)
    draw.rectangle([ox + 7 + basket_sway, 19 + bob_y, ox + 9 + basket_sway, 23 + bob_y], fill=basket)
    img.putpixel((ox + 8 + basket_sway, 20 + bob_y), basket_dark)
    img.putpixel((ox + 8 + basket_sway, 22 + bob_y), basket_dark)
    img.putpixel((ox + 7 + basket_sway, 17 + bob_y), greens)
    img.putpixel((ox + 8 + basket_sway, 16 + bob_y), greens)
    img.putpixel((ox + 9 + basket_sway, 17 + bob_y), (215, 160, 95, 255))
    draw.line([(ox + 8 + basket_sway, 17 + bob_y), (ox + 8 + basket_sway, 18 + bob_y)], fill=basket_dark, width=1)
    img.putpixel((ox + 9 + basket_sway, 18 + bob_y), skin)

    # 6. Cabeça e Rosto
    draw.ellipse([ox + 11, 7 + bob_y, ox + 20, 15 + bob_y], fill=outline)
    draw.ellipse([ox + 12, 8 + bob_y, ox + 19, 14 + bob_y], fill=skin)
    draw.ellipse([ox + 9, 7 + bob_y, ox + 13, 12 + bob_y], fill=hair)
    draw.ellipse([ox + 18, 7 + bob_y, ox + 22, 12 + bob_y], fill=hair)
    img.putpixel((ox + 10, 9 + bob_y), hair_shadow)
    img.putpixel((ox + 21, 9 + bob_y), hair_shadow)
    img.putpixel((ox + 14, 11 + bob_y), outline)
    img.putpixel((ox + 17, 11 + bob_y), outline)
    img.putpixel((ox + 13, 12 + bob_y), blush)
    img.putpixel((ox + 18, 12 + bob_y), blush)
    img.putpixel((ox + 15, 13 + bob_y), skin_shadow)
    img.putpixel((ox + 16, 13 + bob_y), skin_shadow)

    # 7. Chapéu / Boina
    draw.polygon([(ox + 10, 6 + bob_y), (ox + 21, 5 + bob_y), (ox + 23, 8 + bob_y), (ox + 8, 9 + bob_y)], fill=outline)
    draw.polygon([(ox + 11, 6 + bob_y), (ox + 20, 5 + bob_y), (ox + 22, 8 + bob_y), (ox + 9, 8 + bob_y)], fill=hat)
    draw.line([(ox + 10, 8 + bob_y), (ox + 21, 7 + bob_y)], fill=hat_ribbon, width=1)
    draw.line([(ox + 12, 6 + bob_y), (ox + 19, 5 + bob_y)], fill=hat_shadow, width=1)

def create_pedestrian_rosa_sheet():
    # 4 frames de 32x32: 128x32
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_rosa_frame(draw, sheet, f * 32, f)
    path = os.path.join(OUTPUT_DIR, "pedestrian_rosa_32x32.png")
    sheet.save(path)
    print("Dona Rosa 4-frame sheet created:", path)

def draw_postman_frame(draw, img, offset_x, pedal_frame):
    ox = offset_x
    
    # Cores
    frame_col = (35, 75, 120, 255)
    frame_hi = (60, 110, 170, 255)
    metal_dark = (50, 50, 55, 255)
    metal_light = (190, 195, 205, 255)
    leather_brown = (135, 80, 45, 255)
    leather_dark = (95, 55, 30, 255)
    skin = (248, 216, 196, 255)
    skin_dark = (215, 180, 160, 255)
    cap_blue = (28, 52, 90, 255)
    gold_badge = (245, 215, 60, 255)
    paper_white = (245, 245, 250, 255)

    bob_y = 0
    if pedal_frame in [1, 3]:
        bob_y = 1

    # 1. Sombra de contato
    draw.ellipse([ox + 6, 31, ox + 42, 38], fill=SHADOW)

    # 2. Roda Traseira
    draw.ellipse([ox + 6, 23, ox + 20, 35], outline=OUTLINE, width=1)
    draw.ellipse([ox + 7, 24, ox + 19, 34], outline=metal_dark, width=1)
    draw.ellipse([ox + 8, 25, ox + 18, 33], outline=metal_light, width=1)
    img.putpixel((ox + 13, 29), metal_dark)
    # Raios giram conforme pedal_frame
    if pedal_frame % 2 == 0:
        draw.line([(ox + 13, 29), (ox + 9, 26)], fill=metal_light, width=1)
        draw.line([(ox + 13, 29), (ox + 17, 32)], fill=metal_light, width=1)
    else:
        draw.line([(ox + 13, 29), (ox + 13, 24)], fill=metal_light, width=1)
        draw.line([(ox + 13, 29), (ox + 13, 34)], fill=metal_light, width=1)

    # 3. Roda Dianteira
    draw.ellipse([ox + 28, 25, ox + 42, 37], outline=OUTLINE, width=1)
    draw.ellipse([ox + 29, 26, ox + 41, 36], outline=metal_dark, width=1)
    draw.ellipse([ox + 30, 27, ox + 40, 35], outline=metal_light, width=1)
    img.putpixel((ox + 35, 31), metal_dark)
    if pedal_frame % 2 == 0:
        draw.line([(ox + 35, 31), (ox + 32, 28)], fill=metal_light, width=1)
        draw.line([(ox + 35, 31), (ox + 38, 34)], fill=metal_light, width=1)
    else:
        draw.line([(ox + 35, 31), (ox + 35, 26)], fill=metal_light, width=1)
        draw.line([(ox + 35, 31), (ox + 35, 36)], fill=metal_light, width=1)

    # 4. Quadro da bicicleta
    draw.line([(ox + 13, 29), (ox + 22, 29)], fill=metal_dark, width=1)
    draw.line([(ox + 13, 29), (ox + 18, 19 + bob_y)], fill=frame_col, width=1)
    draw.line([(ox + 22, 29), (ox + 18, 19 + bob_y)], fill=frame_col, width=1)
    draw.line([(ox + 18, 19 + bob_y), (ox + 32, 17 + bob_y)], fill=frame_hi, width=1)
    draw.line([(ox + 22, 29), (ox + 32, 17 + bob_y)], fill=frame_col, width=1)
    draw.line([(ox + 32, 17 + bob_y), (ox + 35, 31)], fill=metal_light, width=1)
    
    # Guidão com campainha
    draw.line([(ox + 32, 17 + bob_y), (ox + 31, 13 + bob_y)], fill=metal_light, width=1)
    draw.line([(ox + 29, 13 + bob_y), (ox + 33, 13 + bob_y)], fill=metal_dark, width=1)
    img.putpixel((ox + 33, 12 + bob_y), gold_badge)

    # 5. Bagageiro traseiro com bolsa de cartas
    draw.rectangle([ox + 11, 16 + bob_y, ox + 17, 23 + bob_y], fill=OUTLINE)
    draw.rectangle([ox + 12, 17 + bob_y, ox + 16, 22 + bob_y], fill=leather_brown)
    draw.line([(ox + 12, 19 + bob_y), (ox + 16, 19 + bob_y)], fill=leather_dark, width=1)
    img.putpixel((ox + 13, 16 + bob_y), paper_white)
    img.putpixel((ox + 14, 15 + bob_y), paper_white)
    img.putpixel((ox + 15, 16 + bob_y), paper_white)

    # 6. O Carteiro Tiago - Pernas pedalando
    # Eixo do pedal está em (22, 29)
    pedal_angles = [(-2, 0), (0, 2), (2, 0), (0, -2)]
    p_dx, p_dy = pedal_angles[pedal_frame]
    foot_x = ox + 22 + p_dx
    foot_y = 29 + p_dy
    draw.line([(ox + 20, 20 + bob_y), (foot_x, foot_y - 2)], fill=cap_blue, width=1)
    draw.rectangle([foot_x - 1, foot_y - 1, foot_x + 2, foot_y + 1], fill=metal_dark) # pé/pedal

    # Tronco / Casaco
    draw.rectangle([ox + 19, 11 + bob_y, ox + 26, 19 + bob_y], fill=OUTLINE)
    draw.rectangle([ox + 20, 12 + bob_y, ox + 25, 18 + bob_y], fill=cap_blue)
    draw.line([(ox + 22, 12 + bob_y), (ox + 22, 18 + bob_y)], fill=frame_hi, width=1)
    draw.line([(ox + 20, 12 + bob_y), (ox + 25, 18 + bob_y)], fill=leather_dark, width=1)

    # Braço segurando guidão
    draw.line([(ox + 23, 14 + bob_y), (ox + 30, 14 + bob_y)], fill=cap_blue, width=1)
    img.putpixel((ox + 31, 14 + bob_y), skin)

    # Cabeça e Rosto
    draw.ellipse([ox + 20, 5 + bob_y, ox + 27, 12 + bob_y], fill=OUTLINE)
    draw.ellipse([ox + 21, 6 + bob_y, ox + 26, 11 + bob_y], fill=skin)
    img.putpixel((ox + 25, 8 + bob_y), OUTLINE)
    img.putpixel((ox + 24, 9 + bob_y), (235, 160, 160, 255))
    img.putpixel((ox + 25, 10 + bob_y), skin_dark)

    # Boné
    draw.polygon([(ox + 19, 5 + bob_y), (ox + 28, 4 + bob_y), (ox + 29, 6 + bob_y), (ox + 19, 7 + bob_y)], fill=OUTLINE)
    draw.polygon([(ox + 20, 5 + bob_y), (ox + 27, 4 + bob_y), (ox + 28, 6 + bob_y), (ox + 20, 6 + bob_y)], fill=cap_blue)
    draw.line([(ox + 26, 6 + bob_y), (ox + 29, 6 + bob_y)], fill=metal_dark, width=1)
    img.putpixel((ox + 24, 5 + bob_y), gold_badge)

def create_postman_bike_sheet():
    # 4 frames de 48x40: 192x40
    sheet = Image.new("RGBA", (192, 40), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_postman_frame(draw, sheet, f * 48, f)
    path = os.path.join(OUTPUT_DIR, "postman_bike_48x40.png")
    sheet.save(path)
    print("Postman Bike 4-frame sheet created:", path)

def draw_baker_frame(draw, img, offset_x, step_frame):
    ox = offset_x
    
    # Cores
    apron_white = (248, 248, 252, 255)
    apron_shadow = (205, 210, 220, 255)
    shirt_warm = (195, 105, 60, 255)
    shirt_shadow = (150, 75, 40, 255)
    pants_dark = (48, 42, 40, 255)
    shoes_dark = (32, 25, 22, 255)
    skin = (248, 216, 196, 255)
    skin_dark = (215, 180, 160, 255)
    blush = (240, 160, 160, 255)
    hair_gray = (220, 220, 225, 255)
    bread_board = (165, 110, 65, 255)
    bread_crust = (225, 160, 60, 255)
    bread_score = (160, 95, 30, 255)

    bob_y = 0
    if step_frame in [1, 3]:
        bob_y = -1

    # 1. Sombra de contato
    draw.ellipse([ox + 8, 27, ox + 24, 31], fill=SHADOW)

    # 2. Sapatos (passos alternados)
    if step_frame == 0 or step_frame == 2:
        draw.rectangle([ox + 11, 28, ox + 14, 29], fill=shoes_dark)
        draw.rectangle([ox + 17, 28, ox + 20, 29], fill=shoes_dark)
    elif step_frame == 1:
        draw.rectangle([ox + 10, 27, ox + 13, 28], fill=shoes_dark)
        draw.rectangle([ox + 17, 28, ox + 20, 29], fill=shoes_dark)
    elif step_frame == 3:
        draw.rectangle([ox + 11, 28, ox + 14, 29], fill=shoes_dark)
        draw.rectangle([ox + 18, 27, ox + 21, 28], fill=shoes_dark)

    # 3. Calça
    draw.rectangle([ox + 11, 23 + bob_y, ox + 20, 28], fill=OUTLINE)
    draw.rectangle([ox + 12, 23 + bob_y, ox + 19, 27], fill=pants_dark)

    # 4. Tronco / Camisa e Avental
    draw.rectangle([ox + 10, 13 + bob_y, ox + 21, 25 + bob_y], fill=OUTLINE)
    draw.rectangle([ox + 11, 13 + bob_y, ox + 20, 24 + bob_y], fill=shirt_warm)
    draw.rectangle([ox + 12, 14 + bob_y, ox + 19, 24 + bob_y], fill=apron_white)
    draw.line([(ox + 12, 24 + bob_y), (ox + 19, 24 + bob_y)], fill=apron_shadow, width=1)
    draw.line([(ox + 18, 15 + bob_y), (ox + 18, 23 + bob_y)], fill=apron_shadow, width=1)
    draw.rectangle([ox + 14, 18 + bob_y, ox + 17, 21 + bob_y], outline=apron_shadow)

    # 5. Tábua de madeira com pães
    tilt = 0
    if step_frame == 1:
        tilt = -1
    elif step_frame == 3:
        tilt = 1

    draw.rectangle([ox + 5, 17 + bob_y + tilt, ox + 12, 23 + bob_y + tilt], fill=OUTLINE)
    draw.rectangle([ox + 6, 18 + bob_y + tilt, ox + 11, 22 + bob_y + tilt], fill=bread_board)
    draw.line([(ox + 11, 20 + bob_y + tilt), (ox + 13, 20 + bob_y + tilt)], fill=bread_board, width=1)
    img.putpixel((ox + 12, 20 + bob_y + tilt), skin)
    draw.rectangle([ox + 6, 17 + bob_y + tilt, ox + 8, 19 + bob_y + tilt], fill=bread_crust)
    img.putpixel((ox + 7, 18 + bob_y + tilt), bread_score)
    draw.rectangle([ox + 9, 18 + bob_y + tilt, ox + 11, 20 + bob_y + tilt], fill=bread_crust)
    img.putpixel((ox + 10, 19 + bob_y + tilt), bread_score)

    # 6. Cabeça e Rosto
    draw.ellipse([ox + 11, 7 + bob_y, ox + 20, 14 + bob_y], fill=OUTLINE)
    draw.ellipse([ox + 12, 8 + bob_y, ox + 19, 13 + bob_y], fill=skin)
    img.putpixel((ox + 14, 10 + bob_y), OUTLINE)
    img.putpixel((ox + 17, 10 + bob_y), OUTLINE)
    img.putpixel((ox + 13, 11 + bob_y), blush)
    img.putpixel((ox + 18, 11 + bob_y), blush)
    draw.line([(ox + 14, 12 + bob_y), (ox + 17, 12 + bob_y)], fill=hair_gray, width=1)
    img.putpixel((ox + 13, 13 + bob_y), hair_gray)
    img.putpixel((ox + 18, 13 + bob_y), hair_gray)

    # 7. Chapéu de Padeiro
    draw.polygon([(ox + 10, 7 + bob_y), (ox + 21, 7 + bob_y), (ox + 22, 2 + bob_y), (ox + 9, 2 + bob_y)], fill=OUTLINE)
    draw.polygon([(ox + 11, 7 + bob_y), (ox + 20, 7 + bob_y), (ox + 21, 3 + bob_y), (ox + 10, 3 + bob_y)], fill=apron_white)
    draw.line([(ox + 13, 3 + bob_y), (ox + 13, 6 + bob_y)], fill=apron_shadow, width=1)
    draw.line([(ox + 16, 3 + bob_y), (ox + 16, 6 + bob_y)], fill=apron_shadow, width=1)
    draw.line([(ox + 18, 3 + bob_y), (ox + 18, 6 + bob_y)], fill=apron_shadow, width=1)
    draw.line([(ox + 10, 6 + bob_y), (ox + 21, 6 + bob_y)], fill=apron_shadow, width=1)

def create_baker_alberto_sheet():
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_baker_frame(draw, sheet, f * 32, f)
    path = os.path.join(OUTPUT_DIR, "baker_alberto_32x32.png")
    sheet.save(path)
    print("Baker Alberto 4-frame sheet created:", path)

def draw_dog_frame(draw, img, offset_x, step_frame):
    ox = offset_x
    outline = (55, 35, 15, 255)
    body_col = (205, 150, 75, 255)
    shadow_col = (155, 105, 45, 255)
    muzzle_col = (230, 200, 150, 255)
    collar_col = (45, 105, 190, 255)
    tag_col = (255, 215, 0, 255)

    bob_y = 0
    if step_frame in [1, 3]:
        bob_y = -1

    # Sombra
    draw.ellipse([ox + 6, 21, ox + 26, 29], fill=(25, 20, 15, 75))

    # Corpo
    draw.ellipse([ox + 7, 13 + bob_y, ox + 24, 25 + bob_y], fill=outline)
    draw.ellipse([ox + 8, 14 + bob_y, ox + 23, 24 + bob_y], fill=body_col)
    draw.ellipse([ox + 9, 18 + bob_y, ox + 22, 24 + bob_y], fill=shadow_col)

    # Patas
    if step_frame == 0 or step_frame == 2:
        draw.rectangle([ox + 10, 23, ox + 13, 26], fill=muzzle_col)
        draw.rectangle([ox + 18, 23, ox + 21, 26], fill=muzzle_col)
    elif step_frame == 1:
        draw.rectangle([ox + 8, 22, ox + 11, 25], fill=muzzle_col)
        draw.rectangle([ox + 19, 23, ox + 22, 26], fill=muzzle_col)
    elif step_frame == 3:
        draw.rectangle([ox + 11, 23, ox + 14, 26], fill=muzzle_col)
        draw.rectangle([ox + 17, 22, ox + 20, 25], fill=muzzle_col)

    # Cauda abanando
    tail_shift = 0
    if step_frame == 1:
        tail_shift = -2
    elif step_frame == 3:
        tail_shift = 2
    draw.line([(ox + 8, 16 + bob_y), (ox + 5, 14 + bob_y + tail_shift)], fill=outline, width=2)
    draw.line([(ox + 8, 16 + bob_y), (ox + 5, 14 + bob_y + tail_shift)], fill=body_col, width=1)

    # Cabeça
    draw.ellipse([ox + 11, 6 + bob_y, ox + 21, 16 + bob_y], fill=outline)
    draw.ellipse([ox + 12, 7 + bob_y, ox + 20, 15 + bob_y], fill=body_col)

    # Orelhas caídas
    draw.ellipse([ox + 9, 8 + bob_y, ox + 13, 14 + bob_y], fill=shadow_col)
    draw.ellipse([ox + 19, 8 + bob_y, ox + 23, 14 + bob_y], fill=shadow_col)

    # Focinho e coleira
    draw.ellipse([ox + 14, 10 + bob_y, ox + 18, 14 + bob_y], fill=muzzle_col)
    img.putpixel((ox + 16, 11 + bob_y), (30, 25, 20, 255))
    draw.line([(ox + 13, 15 + bob_y), (ox + 19, 15 + bob_y)], fill=collar_col, width=1)
    img.putpixel((ox + 16, 16 + bob_y), tag_col)

def create_dog_thor_sheet():
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_dog_frame(draw, sheet, f * 32, f)
    path = os.path.join(OUTPUT_DIR, "dog_thor_32x32.png")
    sheet.save(path)
    print("Dog Thor 4-frame sheet created:", path)

def draw_cat_frame(draw, img, offset_x, step_frame):
    ox = offset_x
    body_col = (230, 130, 45, 255)
    shadow_col = (180, 85, 25, 255)
    highlight_col = (250, 175, 80, 255)
    white_fur = (250, 245, 235, 255)
    pink_inner = (245, 160, 170, 255)
    collar_col = (220, 40, 40, 255)
    bell_col = (255, 215, 0, 255)
    outline = (70, 35, 15, 255)

    bob_y = 0
    if step_frame == 1:
        bob_y = -1
    elif step_frame == 3:
        bob_y = -1

    # Sombra
    draw.ellipse([ox + 8, 20, ox + 24, 28], fill=(30, 20, 15, 70))

    # Corpo
    draw.ellipse([ox + 7, 12 + bob_y, ox + 23, 24 + bob_y], fill=outline)
    draw.ellipse([ox + 8, 13 + bob_y, ox + 22, 23 + bob_y], fill=body_col)
    draw.ellipse([ox + 9, 16 + bob_y, ox + 21, 23 + bob_y], fill=shadow_col)

    # Cauda
    tail_angle = 0
    if step_frame == 1:
        tail_angle = -2
    elif step_frame == 3:
        tail_angle = 2
    draw.arc([ox + 16, 15 + bob_y + tail_angle, ox + 25, 25 + bob_y + tail_angle], start=270, end=90, fill=outline, width=2)
    draw.arc([ox + 16, 16 + bob_y + tail_angle, ox + 24, 24 + bob_y + tail_angle], start=270, end=90, fill=body_col, width=2)
    img.putpixel((ox + 22, 16 + bob_y + tail_angle), white_fur)

    # Cabeça
    draw.ellipse([ox + 11, 7 + bob_y, ox + 21, 17 + bob_y], fill=outline)
    draw.ellipse([ox + 12, 8 + bob_y, ox + 20, 16 + bob_y], fill=body_col)
    img.putpixel((ox + 13, 13 + bob_y), highlight_col)
    img.putpixel((ox + 19, 13 + bob_y), highlight_col)

    # Orelhas
    draw.polygon([(ox + 12, 9 + bob_y), (ox + 11, 4 + bob_y), (ox + 14, 8 + bob_y)], fill=body_col)
    img.putpixel((ox + 13, 7 + bob_y), pink_inner)
    draw.polygon([(ox + 18, 8 + bob_y), (ox + 21, 4 + bob_y), (ox + 20, 9 + bob_y)], fill=body_col)
    img.putpixel((ox + 19, 7 + bob_y), pink_inner)

    # Olhos (abertos no frame 2)
    if step_frame == 2:
        img.putpixel((ox + 14, 11 + bob_y), (50, 160, 80, 255))
        img.putpixel((ox + 18, 11 + bob_y), (50, 160, 80, 255))
    else:
        draw.line([(ox + 13, 11 + bob_y), (ox + 15, 12 + bob_y)], fill=outline, width=1)
        draw.line([(ox + 17, 12 + bob_y), (ox + 19, 11 + bob_y)], fill=outline, width=1)

    img.putpixel((ox + 16, 12 + bob_y), pink_inner)
    draw.line([(ox + 13, 16 + bob_y), (ox + 19, 16 + bob_y)], fill=collar_col, width=1)
    img.putpixel((ox + 16, 17 + bob_y), bell_col)
    draw.ellipse([ox + 10, 18 + bob_y, ox + 14, 21 + bob_y], fill=white_fur)
    draw.ellipse([ox + 15, 19 + bob_y, ox + 19, 22 + bob_y], fill=white_fur)

def create_cat_mimi_sheet():
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_cat_frame(draw, sheet, f * 32, f)
    path = os.path.join(OUTPUT_DIR, "cat_mimi_32x32.png")
    sheet.save(path)
    print("Cat Mimi 4-frame sheet created:", path)

def draw_pigeon_frame(draw, img, offset_x, step_frame):
    ox = offset_x
    grey = (145, 150, 160, 255)
    grey_dark = (100, 105, 115, 255)
    iridescent = (80, 160, 140, 255)
    beak = (210, 175, 80, 255)
    eye = (230, 80, 30, 255)
    shadow = (25, 20, 15, 75)

    bob_x = 0
    bob_y = 0
    wing_lift = 0
    if step_frame == 1:
        bob_x = 1
        bob_y = 1
    elif step_frame == 3:
        wing_lift = -2

    # Sombra
    draw.ellipse([ox + 5, 16, ox + 19, 22], fill=shadow)

    # Corpo
    draw.ellipse([ox + 6, 10 + bob_y, ox + 18, 19 + bob_y], fill=grey)
    draw.ellipse([ox + 8, 12 + bob_y + wing_lift, ox + 16, 18 + bob_y + wing_lift], fill=grey_dark)

    # Pescoço e Cabeça
    draw.ellipse([ox + 12 + bob_x, 6 + bob_y, ox + 18 + bob_x, 12 + bob_y], fill=iridescent)
    draw.ellipse([ox + 14 + bob_x, 4 + bob_y, ox + 19 + bob_x, 9 + bob_y], fill=grey)
    img.putpixel((ox + 17 + bob_x, 6 + bob_y), eye)
    draw.line([(ox + 19 + bob_x, 7 + bob_y), (ox + 22 + bob_x, 8 + bob_y)], fill=beak, width=1)

def create_pigeon_sheet():
    # 4 frames de 24x24: 96x24
    sheet = Image.new("RGBA", (96, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_pigeon_frame(draw, sheet, f * 24, f)
    path = os.path.join(OUTPUT_DIR, "pigeon_24x24.png")
    sheet.save(path)
    print("Pigeon 4-frame sheet created:", path)

def draw_canary_frame(draw, img, offset_x, step_frame):
    ox = offset_x
    yellow = (255, 225, 45, 255)
    yellow_dark = (220, 180, 20, 255)
    beak = (240, 140, 40, 255)
    eye = (30, 25, 20, 255)
    shadow = (25, 20, 15, 75)

    hop_y = 0
    if step_frame in [1, 2]:
        hop_y = -2

    draw.ellipse([ox + 6, 17, ox + 18, 22], fill=shadow)
    draw.ellipse([ox + 7, 9 + hop_y, ox + 17, 18 + hop_y], fill=yellow)
    draw.ellipse([ox + 8, 11 + hop_y, ox + 15, 17 + hop_y], fill=yellow_dark)
    draw.ellipse([ox + 12, 5 + hop_y, ox + 18, 11 + hop_y], fill=yellow)
    img.putpixel((ox + 16, 7 + hop_y), eye)
    # Bico abrindo para cantar nos frames 1 e 2
    if step_frame in [1, 2]:
        draw.polygon([(ox + 18, 7 + hop_y), (ox + 21, 6 + hop_y), (ox + 21, 9 + hop_y)], fill=beak)
    else:
        draw.line([(ox + 18, 8 + hop_y), (ox + 21, 8 + hop_y)], fill=beak, width=1)

def create_canary_sheet():
    sheet = Image.new("RGBA", (96, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for f in range(4):
        draw_canary_frame(draw, sheet, f * 24, f)
    path = os.path.join(OUTPUT_DIR, "canary_24x24.png")
    sheet.save(path)
    print("Canary 4-frame sheet created:", path)

if __name__ == "__main__":
    create_pedestrian_rosa_sheet()
    create_postman_bike_sheet()
    create_baker_alberto_sheet()
    create_dog_thor_sheet()
    create_cat_mimi_sheet()
    create_pigeon_sheet()
    create_canary_sheet()

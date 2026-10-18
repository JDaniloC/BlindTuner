from PIL import Image, ImageDraw
import os

OUTPUT_DIR = "godot/assets/sprites/mobs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

OUTLINE = (38, 24, 16, 255)
SHADOW = (30, 20, 15, 70)

def create_postman_bike():
    # 48x40 Sprite do Carteiro Tiago com sua Bicicleta
    img = Image.new("RGBA", (48, 40), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Cores
    frame_col = (35, 75, 120, 255)       # Azul postal escuro
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
    
    # 1. Sombra de contato isométrica no solo
    draw.ellipse([6, 31, 42, 38], fill=SHADOW)
    
    # 2. Roda Traseira (elipse inclinada / aro metálico)
    draw.ellipse([6, 23, 20, 35], outline=OUTLINE, width=1)
    draw.ellipse([7, 24, 19, 34], outline=metal_dark, width=1)
    draw.ellipse([8, 25, 18, 33], outline=metal_light, width=1)
    img.putpixel((13, 29), metal_dark) # cubo da roda traseira
    draw.line([(13, 29), (9, 26)], fill=metal_light, width=1)
    draw.line([(13, 29), (17, 32)], fill=metal_light, width=1)
    
    # 3. Roda Dianteira
    draw.ellipse([28, 25, 42, 37], outline=OUTLINE, width=1)
    draw.ellipse([29, 26, 41, 36], outline=metal_dark, width=1)
    draw.ellipse([30, 27, 40, 35], outline=metal_light, width=1)
    img.putpixel((35, 31), metal_dark) # cubo da roda dianteira
    draw.line([(35, 31), (32, 28)], fill=metal_light, width=1)
    draw.line([(35, 31), (38, 34)], fill=metal_light, width=1)
    
    # 4. Quadro da bicicleta e corrente
    # Triângulo traseiro: eixo traseiro (13, 29) até pedivela (22, 29) e selim (18, 19)
    draw.line([(13, 29), (22, 29)], fill=OUTLINE, width=2)
    draw.line([(13, 29), (22, 29)], fill=metal_dark, width=1)
    draw.line([(13, 29), (18, 19)], fill=OUTLINE, width=2)
    draw.line([(13, 29), (18, 19)], fill=frame_col, width=1)
    draw.line([(22, 29), (18, 19)], fill=OUTLINE, width=2)
    draw.line([(22, 29), (18, 19)], fill=frame_col, width=1)
    
    # Tubo superior e inferior até caixa de direção (32, 17)
    draw.line([(18, 19), (32, 17)], fill=OUTLINE, width=2)
    draw.line([(18, 19), (32, 17)], fill=frame_hi, width=1)
    draw.line([(22, 29), (32, 17)], fill=OUTLINE, width=2)
    draw.line([(22, 29), (32, 17)], fill=frame_col, width=1)
    
    # Garfo dianteiro até roda (35, 31)
    draw.line([(32, 17), (35, 31)], fill=OUTLINE, width=2)
    draw.line([(32, 17), (35, 31)], fill=metal_light, width=1)
    
    # Guidão com campainha
    draw.line([(32, 17), (31, 13)], fill=metal_light, width=1)
    draw.line([(29, 13), (33, 13)], fill=metal_dark, width=1)
    img.putpixel((33, 12), gold_badge) # Campainha dourada niquelada!
    
    # 5. Bagageiro traseiro com bolsa de cartas de couro
    draw.rectangle([11, 16, 17, 23], fill=OUTLINE)
    draw.rectangle([12, 17, 16, 22], fill=leather_brown)
    draw.line([(12, 19), (16, 19)], fill=leather_dark, width=1)
    # Cartas brancas saindo do topo da bolsa
    img.putpixel((13, 16), paper_white)
    img.putpixel((14, 15), paper_white)
    img.putpixel((15, 16), paper_white)
    
    # 6. O Carteiro Tiago (montado com postura amigável)
    # Pernas / Calça azul postal
    draw.line([(20, 20), (22, 27)], fill=OUTLINE, width=2)
    draw.line([(20, 20), (22, 27)], fill=cap_blue, width=1)
    draw.rectangle([21, 27, 24, 29], fill=metal_dark) # sapato no pedal
    
    # Tronco / Casaco
    draw.rectangle([19, 11, 26, 19], fill=OUTLINE)
    draw.rectangle([20, 12, 25, 18], fill=cap_blue)
    draw.line([(22, 12), (22, 18)], fill=frame_hi, width=1) # botões / costura
    # Alça transversal da bolsa
    draw.line([(20, 12), (25, 18)], fill=leather_dark, width=1)
    
    # Braço segurando o guidão
    draw.line([(23, 14), (30, 14)], fill=OUTLINE, width=2)
    draw.line([(23, 14), (30, 14)], fill=cap_blue, width=1)
    img.putpixel((31, 14), skin) # mão
    
    # Cabeça e Rosto
    draw.ellipse([20, 5, 27, 12], fill=OUTLINE)
    draw.ellipse([21, 6, 26, 11], fill=skin)
    img.putpixel((25, 8), OUTLINE) # Olho
    img.putpixel((24, 9), (235, 160, 160, 255)) # Bochecha simpática
    img.putpixel((25, 10), skin_dark) # Sorriso
    
    # Boné de carteiro com distintivo dourado
    draw.polygon([(19, 5), (28, 4), (29, 6), (19, 7)], fill=OUTLINE)
    draw.polygon([(20, 5), (27, 4), (28, 6), (20, 6)], fill=cap_blue)
    draw.line([(26, 6), (29, 6)], fill=metal_dark, width=1) # aba do boné
    img.putpixel((24, 5), gold_badge) # Brasão dos correios
    
    path = os.path.join(OUTPUT_DIR, "postman_bike_48x40.png")
    img.save(path)
    print("Postman Bike sprite created at:", path)

def create_baker_alberto():
    # 32x32 Sprite do Padeiro Alberto
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
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
    
    # 1. Sombra de contato
    draw.ellipse([8, 27, 24, 31], fill=SHADOW)
    
    # 2. Sapatos
    draw.rectangle([11, 28, 14, 29], fill=OUTLINE)
    draw.rectangle([11, 28, 13, 29], fill=shoes_dark)
    draw.rectangle([17, 28, 20, 29], fill=OUTLINE)
    draw.rectangle([17, 28, 19, 29], fill=shoes_dark)
    
    # 3. Calça
    draw.rectangle([11, 23, 20, 28], fill=OUTLINE)
    draw.rectangle([12, 23, 19, 27], fill=pants_dark)
    
    # 4. Tronco / Camisa e Avental
    draw.rectangle([10, 13, 21, 25], fill=OUTLINE)
    draw.rectangle([11, 13, 20, 24], fill=shirt_warm)
    # Avental branco por cima
    draw.rectangle([12, 14, 19, 24], fill=apron_white)
    draw.line([(12, 24), (19, 24)], fill=apron_shadow, width=1)
    draw.line([(18, 15), (18, 23)], fill=apron_shadow, width=1)
    # Bolsinho do avental
    draw.rectangle([14, 18, 17, 21], outline=apron_shadow)
    
    # 5. Tábua de madeira com pães franceses quentinhos
    draw.rectangle([5, 17, 12, 23], fill=OUTLINE)
    draw.rectangle([6, 18, 11, 22], fill=bread_board)
    # Cabo da tábua
    draw.line([(11, 20), (13, 20)], fill=bread_board, width=1)
    img.putpixel((12, 20), skin) # mão segurando a tábua
    # Pães dourados na tábua
    draw.rectangle([6, 17, 8, 19], fill=bread_crust)
    img.putpixel((7, 18), bread_score)
    draw.rectangle([9, 18, 11, 20], fill=bread_crust)
    img.putpixel((10, 19), bread_score)
    
    # 6. Cabeça e Rosto
    draw.ellipse([11, 7, 20, 14], fill=OUTLINE)
    draw.ellipse([12, 8, 19, 13], fill=skin)
    # Olhos gentis
    img.putpixel((14, 10), OUTLINE)
    img.putpixel((17, 10), OUTLINE)
    # Bochechas rosadas
    img.putpixel((13, 11), blush)
    img.putpixel((18, 11), blush)
    # Bigode farto branco/grisalho
    draw.line([(14, 12), (17, 12)], fill=hair_gray, width=1)
    img.putpixel((13, 13), hair_gray)
    img.putpixel((18, 13), hair_gray)
    
    # 7. Chapéu de Padeiro tradicional (Toque Blanche)
    draw.polygon([(10, 7), (21, 7), (22, 2), (9, 2)], fill=OUTLINE)
    draw.polygon([(11, 7), (20, 7), (21, 3), (10, 3)], fill=apron_white)
    # Dobras do chapéu de chef
    draw.line([(13, 3), (13, 6)], fill=apron_shadow, width=1)
    draw.line([(16, 3), (16, 6)], fill=apron_shadow, width=1)
    draw.line([(18, 3), (18, 6)], fill=apron_shadow, width=1)
    draw.line([(10, 6), (21, 6)], fill=apron_shadow, width=1) # faixa da base
    
    path = os.path.join(OUTPUT_DIR, "baker_alberto_32x32.png")
    img.save(path)
    print("Baker Alberto sprite created at:", path)

if __name__ == "__main__":
    create_postman_bike()
    create_baker_alberto()

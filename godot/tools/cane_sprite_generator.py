import os
from PIL import Image, ImageDraw

# Cores oficiais da Bengala Longa de Orientação e Mobilidade em Pixel Art
CANE_GRIP = (45, 45, 52, 255)       # Empunhadura de borracha escura antiderrapante
CANE_GRIP_HI = (75, 75, 84, 255)    # Highlight sutil da empunhadura
CANE_SHAFT = (248, 250, 252, 255)   # Alumínio / fibra branca luminosa
CANE_SHADE = (195, 202, 210, 255)   # Sombra sutil da haste metálica
CANE_RED = (220, 38, 38, 255)       # Faixa refletiva vermelha de segurança
CANE_TIP = (255, 255, 255, 255)     # Ponteira roller/esférica de cerâmica/nylon
CANE_OUTLINE = (34, 28, 26, 255)    # Contorno quente escuro para consistência visual

def draw_pixel_cane(img, x0, y0, x1, y1, is_behind=False):
    """
    Desenha uma bengala de mobilidade de 1px com proporção correta:
    - x0, y0: posição da empunhadura / mão
    - x1, y1: ponto de contato no chão
    - Faixa refletiva vermelha no terço inferior (próximo à ponta)
    - Ponteira branca no final
    """
    pixels = img.load()
    w, h = img.size

    # Algoritmo de Bresenham para traçado exato de pixel art
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy

    pts = []
    curr_x, curr_y = x0, y0
    while True:
        pts.append((curr_x, curr_y))
        if curr_x == x1 and curr_y == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            curr_x += sx
        if e2 < dx:
            err += dx
            curr_y += sy

    total_len = len(pts)
    if total_len == 0:
        return

    # Desenha os pixels ao longo do segmento
    for idx, (px, py) in enumerate(pts):
        if not (0 <= px < w and 0 <= py < h):
            continue

        # Não sobrepõe a cabeça/olhos do personagem se estiver atrás
        cur_col = pixels[px, py]
        if is_behind and cur_col[3] > 0 and py < y0:
            continue

        # Proporções da bengala:
        # - Topo (0% a 20%): Empunhadura
        # - Meio (20% a 72%): Haste branca
        # - Pré-ponta (72% a 92%): Faixa refletiva vermelha
        # - Ponta (92% a 100%): Ponteira roller branca
        frac = float(idx) / float(total_len)
        if frac <= 0.20:
            col = CANE_GRIP if idx % 2 == 0 else CANE_GRIP_HI
        elif frac <= 0.72:
            col = CANE_SHAFT
        elif frac <= 0.92:
            col = CANE_RED
        else:
            col = CANE_TIP

        pixels[px, py] = col

    # Adiciona a ponteira esférica (roller tip) de 2x2 ou 1px destacado no chão
    if 0 <= x1 < w and 0 <= y1 < h:
        pixels[x1, y1] = CANE_TIP
        # Leve ponto de sombra de contato no solo
        if y1 + 1 < h and pixels[x1, y1 + 1][3] == 0:
            pixels[x1, y1 + 1] = (40, 30, 25, 90)

def test_idle_sheet():
    src_path = r"godot\assets\sprites\character\16x32_elderly\16x32 Idle-Sheet.png"
    im = Image.open(src_path).convert("RGBA")
    
    # 5 direções: s, se, e, ne, n
    # Para cada direção (linha 0..4) e cada frame (0..3):
    # Definimos as coordenadas da mão (x0, y0) e do solo (x1, y1)
    # em coordenadas relativas ao frame de 32x32:
    for row in range(5):
        for col in range(4):
            fx = col * 32
            fy = row * 32
            
            # Sub-frame
            frame = im.crop((fx, fy, fx + 32, fy + 32))
            
            # Idle breathing cycle: leve respiração de 1px nos frames 1 e 2
            b_offset = 1 if col in (1, 2) else 0
            
            if row == 0: # s (frente)
                x0, y0 = 22, 23 + b_offset
                x1, y1 = 26, 31
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind=False)
            elif row == 1: # se (diagonal sul-leste)
                x0, y0 = 20, 23 + b_offset
                x1, y1 = 26, 31
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind=False)
            elif row == 2: # e (lateral leste)
                x0, y0 = 19, 23 + b_offset
                x1, y1 = 26, 31
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind=False)
            elif row == 3: # ne (diagonal norte-leste)
                x0, y0 = 19, 22 + b_offset
                x1, y1 = 24, 29
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind=False)
            elif row == 4: # n (norte - costas)
                x0, y0 = 21, 22 + b_offset
                x1, y1 = 24, 28
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind=True)
                
            im.paste(frame, (fx, fy))
            
    out_path = r"godot\tools\test_idle_cane.png"
    im.save(out_path)
    print("Test idle sheet saved to:", out_path)
    
    # Preview frame 0
    f0 = im.crop((0, 0, 32, 32))
    px = f0.load()
    print("ASCII Preview of Frame 0 with Cane:")
    for y in range(18, 32):
        row = ''.join([
            ' ' if px[x, y][3] == 0 else (
                'G' if px[x, y][:3] in [(45, 45, 52), (75, 75, 84)] else (
                '|' if px[x, y][:3] == (248, 250, 252) else (
                'R' if px[x, y][:3] == (220, 38, 38) else (
                'O' if px[x, y][:3] == (255, 255, 255) else 'X'
            )))) for x in range(12, 28)
        ])
        print(f"{y:2d}: {row}")

if __name__ == "__main__":
    test_idle_sheet()

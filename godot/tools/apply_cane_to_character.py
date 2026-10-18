import os
from PIL import Image

BASE_DIR = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites\character\16x32_elderly"
BACKUP_DIR = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites\character\16x32_elderly_backup"

# Cores da Bengala Longa de Orientação e Mobilidade em Pixel Art
CANE_GRIP = (45, 45, 52, 255)       # Empunhadura de borracha escura antiderrapante
CANE_GRIP_HI = (75, 75, 84, 255)    # Highlight sutil da empunhadura
CANE_SHAFT = (248, 250, 252, 255)   # Alumínio / fibra branca luminosa
CANE_SHADE = (195, 202, 210, 255)   # Sombra sutil da haste metálica
CANE_RED = (220, 38, 38, 255)       # Faixa refletiva vermelha de segurança
CANE_TIP = (255, 255, 255, 255)     # Ponteira roller/esférica de cerâmica/nylon
CONTACT_SHADOW = (40, 30, 25, 90)   # Sombra de contato no piso

def draw_pixel_cane(img, x0, y0, x1, y1, is_behind=False):
    pixels = img.load()
    w, h = img.size

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

    for idx, (px, py) in enumerate(pts):
        if not (0 <= px < w and 0 <= py < h):
            continue

        cur_col = pixels[px, py]
        # Se is_behind=True, a bengala não desenha sobre a cabeça/olhos
        if is_behind and cur_col[3] > 0 and py < y0:
            continue

        frac = float(idx) / float(total_len)
        if frac <= 0.18:
            col = CANE_GRIP if idx % 2 == 0 else CANE_GRIP_HI
        elif frac <= 0.70:
            col = CANE_SHAFT
        elif frac <= 0.90:
            col = CANE_RED
        else:
            col = CANE_TIP

        pixels[px, py] = col

    # Ponteira no chão
    if 0 <= x1 < w and 0 <= y1 < h:
        pixels[x1, y1] = CANE_TIP
        if y1 + 1 < h and pixels[x1, y1 + 1][3] == 0:
            pixels[x1, y1 + 1] = CONTACT_SHADOW


def process_sheet(filename, frame_configs):
    """
    frame_configs: dict de (row, col) -> (x0, y0, x1, y1, is_behind)
    """
    src_file = os.path.join(BACKUP_DIR, filename)
    if not os.path.exists(src_file):
        src_file = os.path.join(BASE_DIR, filename)
    
    im = Image.open(src_file).convert("RGBA")
    cols = im.size[0] // 32
    rows = im.size[1] // 32

    for r in range(rows):
        for c in range(cols):
            fx = c * 32
            fy = r * 32
            frame = im.crop((fx, fy, fx + 32, fy + 32))
            
            cfg = frame_configs.get((r, c))
            if cfg:
                x0, y0, x1, y1, is_behind = cfg
                draw_pixel_cane(frame, x0, y0, x1, y1, is_behind)
            
            im.paste(frame, (fx, fy))

    dst_file = os.path.join(BASE_DIR, filename)
    im.save(dst_file)
    print(f"Generated cane animation for: {filename}")


def make_idle_configs():
    cfgs = {}
    for r in range(5):
        for c in range(4):
            b = 1 if c in (1, 2) else 0
            if r == 0:   # s
                cfgs[(r, c)] = (22, 23 + b, 26, 31, False)
            elif r == 1: # se
                cfgs[(r, c)] = (20, 23 + b, 26, 31, False)
            elif r == 2: # e
                cfgs[(r, c)] = (19, 23 + b, 26, 31, False)
            elif r == 3: # ne
                cfgs[(r, c)] = (19, 22 + b, 24, 29, False)
            elif r == 4: # n
                cfgs[(r, c)] = (21, 22 + b, 24, 28, True)
    return cfgs


def make_walk_configs():
    # Hoover Two-Point Touch:
    # c=0: toque na direita
    # c=1: varredura no ar subindo e indo para a esquerda
    # c=2: toque na esquerda
    # c=3: varredura no ar subindo e voltando para a direita
    cfgs = {}
    for r in range(5):
        for c in range(4):
            if r == 0: # s (frente)
                if c == 0:
                    cfgs[(r, c)] = (22, 22, 27, 31, False)
                elif c == 1:
                    cfgs[(r, c)] = (21, 21, 22, 29, False)
                elif c == 2:
                    cfgs[(r, c)] = (20, 22, 16, 31, False)
                elif c == 3:
                    cfgs[(r, c)] = (21, 21, 22, 29, False)
            elif r == 1: # se
                if c == 0:
                    cfgs[(r, c)] = (21, 22, 28, 31, False)
                elif c == 1:
                    cfgs[(r, c)] = (20, 21, 24, 29, False)
                elif c == 2:
                    cfgs[(r, c)] = (19, 22, 19, 31, False)
                elif c == 3:
                    cfgs[(r, c)] = (20, 21, 23, 29, False)
            elif r == 2: # e
                if c == 0:
                    cfgs[(r, c)] = (20, 22, 28, 31, False)
                elif c == 1:
                    cfgs[(r, c)] = (19, 21, 24, 29, False)
                elif c == 2:
                    cfgs[(r, c)] = (18, 22, 20, 31, False)
                elif c == 3:
                    cfgs[(r, c)] = (19, 21, 24, 29, False)
            elif r == 3: # ne
                if c == 0:
                    cfgs[(r, c)] = (19, 21, 26, 29, False)
                elif c == 1:
                    cfgs[(r, c)] = (18, 20, 22, 27, False)
                elif c == 2:
                    cfgs[(r, c)] = (18, 21, 18, 29, False)
                elif c == 3:
                    cfgs[(r, c)] = (18, 20, 22, 27, False)
            elif r == 4: # n
                if c == 0:
                    cfgs[(r, c)] = (21, 21, 25, 28, True)
                elif c == 1:
                    cfgs[(r, c)] = (20, 20, 21, 26, True)
                elif c == 2:
                    cfgs[(r, c)] = (19, 21, 17, 28, True)
                elif c == 3:
                    cfgs[(r, c)] = (20, 20, 21, 26, True)
    return cfgs


def make_attack_configs():
    # Tatear / Varredura ampla de 7 frames:
    # 0: recuo e elevação para iniciar varredura
    # 1: batida tátil firme no chão à direita
    # 2: varredura em arco raspando o solo
    # 3: ponto central da varredura
    # 4: batida tátil firme no chão à esquerda
    # 5: varredura frontal estendida
    # 6: retorno suave à posição de prontidão
    cfgs = {}
    for r in range(5):
        for c in range(7):
            if r == 0: # s
                taps = [
                    (21, 21, 24, 27, False),
                    (23, 22, 28, 31, False),
                    (22, 23, 24, 31, False),
                    (20, 23, 19, 31, False),
                    (17, 22, 12, 31, False),
                    (21, 22, 24, 31, False),
                    (22, 23, 26, 31, False)
                ]
                cfgs[(r, c)] = taps[c]
            elif r == 1: # se
                taps = [
                    (20, 21, 23, 27, False),
                    (22, 22, 29, 31, False),
                    (21, 23, 25, 31, False),
                    (19, 23, 20, 31, False),
                    (17, 22, 14, 31, False),
                    (21, 22, 25, 31, False),
                    (21, 23, 27, 31, False)
                ]
                cfgs[(r, c)] = taps[c]
            elif r == 2: # e
                taps = [
                    (19, 21, 23, 27, False),
                    (22, 22, 29, 31, False),
                    (20, 23, 26, 31, False),
                    (19, 23, 21, 31, False),
                    (17, 22, 16, 31, False),
                    (21, 22, 26, 31, False),
                    (20, 23, 27, 31, False)
                ]
                cfgs[(r, c)] = taps[c]
            elif r == 3: # ne
                taps = [
                    (18, 20, 21, 26, False),
                    (21, 21, 27, 29, False),
                    (20, 22, 24, 29, False),
                    (18, 22, 20, 29, False),
                    (16, 21, 15, 29, False),
                    (19, 21, 23, 29, False),
                    (19, 22, 25, 29, False)
                ]
                cfgs[(r, c)] = taps[c]
            elif r == 4: # n
                taps = [
                    (20, 20, 22, 25, True),
                    (22, 21, 26, 28, True),
                    (21, 22, 23, 28, True),
                    (19, 22, 19, 28, True),
                    (17, 21, 14, 28, True),
                    (20, 21, 22, 28, True),
                    (21, 22, 24, 28, True)
                ]
                cfgs[(r, c)] = taps[c]
    return cfgs


def make_interact_configs():
    # Escutar / Apoio vertical e mão ao ouvido:
    cfgs = {}
    for r in range(5):
        for c in range(4):
            if r == 0:   # s
                cfgs[(r, c)] = (21, 23, 23, 31, False)
            elif r == 1: # se
                cfgs[(r, c)] = (20, 23, 23, 31, False)
            elif r == 2: # e
                cfgs[(r, c)] = (19, 23, 23, 31, False)
            elif r == 3: # ne
                cfgs[(r, c)] = (19, 22, 22, 29, False)
            elif r == 4: # n
                cfgs[(r, c)] = (21, 22, 22, 28, True)
    return cfgs


def make_run_configs():
    # Corrida: varredura rápida e firme à frente (6 frames)
    cfgs = {}
    for r in range(5):
        for c in range(6):
            phase = c % 2
            if r == 0:
                cfgs[(r, c)] = (22, 21, 27 if phase == 0 else 18, 30, False)
            elif r == 1:
                cfgs[(r, c)] = (21, 21, 28 if phase == 0 else 20, 30, False)
            elif r == 2:
                cfgs[(r, c)] = (20, 21, 28 if phase == 0 else 21, 30, False)
            elif r == 3:
                cfgs[(r, c)] = (19, 20, 25 if phase == 0 else 19, 29, False)
            elif r == 4:
                cfgs[(r, c)] = (20, 20, 24 if phase == 0 else 18, 28, True)
    return cfgs


def make_jump_configs():
    # Salto / Arco: 5 frames
    # 0: agacha
    # 1: impulso / bengala sobe
    # 2: ápice / bengala elevada
    # 3: descida
    # 4: recepção no solo / bengala apoia
    cfgs = {}
    for r in range(5):
        for c in range(5):
            if c == 0:
                cfgs[(r, c)] = (22, 23, 26, 31, r == 4)
            elif c == 1:
                cfgs[(r, c)] = (21, 18, 25, 26, r == 4)
            elif c == 2:
                cfgs[(r, c)] = (20, 14, 24, 22, r == 4)
            elif c == 3:
                cfgs[(r, c)] = (21, 18, 25, 27, r == 4)
            elif c == 4:
                cfgs[(r, c)] = (22, 23, 26, 31, r == 4)
    return cfgs


if __name__ == "__main__":
    os.makedirs(BACKUP_DIR, exist_ok=True)
    sheets_to_process = [
        ("16x32 Idle-Sheet.png", make_idle_configs()),
        ("16x32 Walk-Sheet.png", make_walk_configs()),
        ("16x32 Attack-Sheet.png", make_attack_configs()),
        ("16x32 Interact-Sheet.png", make_interact_configs()),
        ("16x32 Run-Sheet.png", make_run_configs()),
        ("16x32 Jump-Sheet.png", make_jump_configs()),
    ]

    # Cria backup das sheets originais antes de sobrescrever
    for fname, _ in sheets_to_process:
        src = os.path.join(BASE_DIR, fname)
        bak = os.path.join(BACKUP_DIR, fname)
        if os.path.exists(src) and not os.path.exists(bak):
            import shutil
            shutil.copy2(src, bak)
            print(f"Backed up {fname} to {BACKUP_DIR}")

    # Processa cada sheet
    for fname, cfgs in sheets_to_process:
        process_sheet(fname, cfgs)

    print("\nAll character sprite sheets successfully upgraded with orientation and mobility cane!")

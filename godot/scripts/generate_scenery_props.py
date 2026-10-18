import os
from PIL import Image, ImageDraw

OUTPUT_DIR = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites\props"
os.makedirs(OUTPUT_DIR, exist_ok=True)

OUTLINE = (38, 24, 16, 255)


def _shade(color, factor):
    return (
        max(0, min(255, int(color[0] * factor))),
        max(0, min(255, int(color[1] * factor))),
        max(0, min(255, int(color[2] * factor))),
        color[3] if len(color) > 3 else 255,
    )


def iso_pt(cx, cy, u, v, z=0):
    """Converte coordenadas isométricas 2:1 (u=SE, v=SW, z=altura) para tela."""
    px = int(round(cx + (u - v) * 2.0))
    py = int(round(cy + (u + v) * 1.0 - z))
    return (px, py)


def draw_iso_box(d, cx, cy, u0, v0, u1, v1, z0, z1, top_col, left_col=None, right_col=None, outline_col=OUTLINE):
    """Desenha um prisma isométrico 2:1 com iluminação de topo-esquerda."""
    if left_col is None:
        left_col = _shade(top_col, 0.84)
    if right_col is None:
        right_col = _shade(top_col, 0.66)

    p_top_n = iso_pt(cx, cy, u0, v0, z1)
    p_top_e = iso_pt(cx, cy, u1, v0, z1)
    p_top_s = iso_pt(cx, cy, u1, v1, z1)
    p_top_w = iso_pt(cx, cy, u0, v1, z1)

    p_bot_e = iso_pt(cx, cy, u1, v0, z0)
    p_bot_s = iso_pt(cx, cy, u1, v1, z0)
    p_bot_w = iso_pt(cx, cy, u0, v1, z0)

    # Face esquerda (Sul-Oeste - luz média)
    d.polygon([p_top_w, p_top_s, p_bot_s, p_bot_w], fill=left_col)
    # Face direita (Sul-Leste - sombra)
    d.polygon([p_top_s, p_top_e, p_bot_e, p_bot_s], fill=right_col)
    # Face de topo (mais clara)
    d.polygon([p_top_n, p_top_e, p_top_s, p_top_w], fill=top_col)

    # Highlight interno de 1px na quina superior frontal
    hi_col = _shade(top_col, 1.14)
    d.line([p_top_w, p_top_s], fill=hi_col, width=1)
    d.line([p_top_s, p_top_e], fill=_shade(top_col, 1.06), width=1)
    # Quina vertical central
    d.line([p_top_s, p_bot_s], fill=_shade(right_col, 0.82), width=1)

    if outline_col is not None:
        d.line([p_top_n, p_top_e, p_bot_e, p_bot_s, p_bot_w, p_top_w, p_top_n], fill=outline_col, width=1)


def apply_crisp_outline(img, outline_col=OUTLINE):
    """Garante contorno externo de 1px em marrom-escuro quente sem halo."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 200:
                        dst[x, y] = outline_col
                        break
    return out


def create_iron_gate():
    # 48x64 Portão de ferro forjado isométrico com pilares de pedra e trinco dourado
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 40

    # Pilares de pedra isométricos (esquerdo/SW e direito/NE)
    draw_iso_box(d, cx, cy, -1, 5, 2, 8, 0, 34, (130, 122, 114), (108, 100, 92), (82, 76, 70))
    draw_iso_box(d, cx, cy, -2, 4, 3, 9, 34, 38, (155, 146, 138))  # Capitel SW

    draw_iso_box(d, cx, cy, 5, -7, 8, -4, 0, 34, (130, 122, 114), (108, 100, 92), (82, 76, 70))
    draw_iso_box(d, cx, cy, 4, -8, 9, -3, 34, 38, (155, 146, 138))  # Capitel NE

    # Travessas isométricas do portão de ferro
    p_sw_bot = iso_pt(cx, cy, 1, 5, 4)
    p_ne_bot = iso_pt(cx, cy, 6, -5, 4)
    p_sw_mid = iso_pt(cx, cy, 1, 5, 18)
    p_ne_mid = iso_pt(cx, cy, 6, -5, 18)
    p_sw_top = iso_pt(cx, cy, 1, 5, 30)
    p_ne_top = iso_pt(cx, cy, 6, -5, 30)

    d.line([p_sw_bot, p_ne_bot], fill=(42, 46, 52), width=2)
    d.line([p_sw_mid, p_ne_mid], fill=(42, 46, 52), width=2)
    d.line([p_sw_top, p_ne_top], fill=(55, 60, 68), width=2)

    # Barras verticais em perspectiva 2:1 com lanças douradas
    for i in range(6):
        t = i / 5.0
        bx = int(round(p_sw_bot[0] * (1 - t) + p_ne_bot[0] * t))
        by = int(round(p_sw_bot[1] * (1 - t) + p_ne_bot[1] * t))
        arch = int(4 * (1.0 - (2.0 * t - 1.0) ** 2))
        ty = by - 28 - arch
        d.line([(bx, by), (bx, ty)], fill=(48, 52, 58), width=2)
        d.polygon([(bx - 1, ty), (bx + 1, ty), (bx, ty - 3)], fill=(225, 188, 72))

    # Trinco dourado central (farol sonoro)
    lx, ly = iso_pt(cx, cy, 3.5, 0, 17)
    d.rectangle([lx - 3, ly - 2, lx + 3, ly + 3], fill=(238, 195, 65), outline=OUTLINE)
    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "iron_gate_48x64.png"))


def create_bakery_counter():
    # 64x48 Balcão da padaria em perspectiva isométrica 2:1 com pães e sino dourado
    img = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 32, 26

    # Corpo de madeira do balcão
    draw_iso_box(d, cx, cy, -6, -3, 6, 4, 0, 16, (165, 112, 68), (145, 94, 54), (112, 70, 38))
    # Tampo de mármore creme
    draw_iso_box(d, cx, cy, -6.5, -3.5, 6.5, 4.5, 16, 19, (238, 226, 204), (214, 198, 174), (184, 168, 144))

    # Cesta de vime e pães dourados no lado esquerdo do tampo
    bx, by = iso_pt(cx, cy, -2, 1, 20)
    d.ellipse([bx - 8, by - 4, bx + 8, by + 4], fill=(185, 132, 74), outline=OUTLINE)
    d.ellipse([bx - 6, by - 6, bx + 1, by - 1], fill=(232, 182, 96), outline=(150, 102, 42))
    d.ellipse([bx, by - 6, bx + 6, by - 1], fill=(222, 170, 84), outline=(150, 102, 42))

    # Sino de balcão dourado à direita (farol sonoro)
    sx, sy = iso_pt(cx, cy, 3, -1, 20)
    d.ellipse([sx - 4, sy - 1, sx + 4, sy + 3], fill=(150, 112, 28))
    d.ellipse([sx - 4, sy - 5, sx + 4, sy + 1], fill=(248, 212, 72), outline=(168, 126, 28))
    d.rectangle([sx - 1, sy - 7, sx + 1, sy - 5], fill=(255, 240, 140))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "bakery_counter_64x48.png"))


def create_fountain_stone():
    # 64x64 Chafariz de pedra isométrico 2:1 (elipses em proporção 2:1)
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Base octogonal/elíptica 2:1 de pedra (sombra lateral + borda superior)
    d.ellipse([6, 36, 58, 60], fill=(104, 110, 118), outline=OUTLINE)
    d.ellipse([6, 32, 58, 56], fill=(154, 160, 168), outline=OUTLINE)
    # Água cristalina na bacia inferior (proporção 2:1)
    d.ellipse([11, 35, 53, 53], fill=(64, 152, 212), outline=(46, 116, 172))
    d.ellipse([16, 38, 48, 50], fill=(98, 186, 238))
    d.arc([14, 37, 50, 51], start=190, end=350, fill=(195, 238, 255), width=1)

    # Coluna central esculpida
    draw_iso_box(d, 32, 44, -2, -2, 2, 2, 0, 22, (168, 174, 182), (144, 150, 158), (112, 118, 126))

    # Bacia superior 2:1
    d.ellipse([18, 18, 46, 30], fill=(116, 122, 130), outline=OUTLINE)
    d.ellipse([18, 15, 46, 27], fill=(166, 172, 180), outline=OUTLINE)
    d.ellipse([21, 17, 43, 25], fill=(78, 172, 232))

    # Pináculo central e quedas d'água arqueadas
    draw_iso_box(d, 32, 21, -1, -1, 1, 1, 0, 10, (176, 182, 190))
    d.line([(32, 9), (24, 19)], fill=(190, 236, 255), width=2)
    d.line([(32, 9), (40, 19)], fill=(190, 236, 255), width=2)
    d.line([(21, 23), (16, 41)], fill=(165, 224, 252), width=1)
    d.line([(43, 23), (48, 41)], fill=(165, 224, 252), width=1)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "fountain_stone_64x64.png"))


def create_church_portal():
    # 64x80 Portal da Matriz em perspectiva isométrica 2:1 com torre sineira
    img = Image.new("RGBA", (64, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 32, 56

    # Degrau de pedra colonial na base
    draw_iso_box(d, cx, cy, -7, -4, 7, 5, 0, 4, (172, 166, 156), (148, 142, 132), (118, 112, 104))
    # Corpo principal do portal em cantaria isométrica
    draw_iso_box(d, cx, cy, -6, -3, 6, 3, 4, 38, (224, 214, 196), (206, 196, 178), (168, 158, 142))
    # Cornija/Cimalha colonial
    draw_iso_box(d, cx, cy, -6.5, -3.5, 6.5, 3.5, 38, 42, (164, 148, 128), (146, 130, 112), (116, 102, 86))
    # Campanário superior (torre do sino)
    draw_iso_box(d, cx, cy, -3.5, -2, 3.5, 2, 42, 60, (216, 206, 188), (198, 188, 170), (162, 152, 136))

    # Porta arqueada de jacarandá na face Sul-Oeste (iluminada)
    p1 = iso_pt(cx, cy, -3, 3, 4)
    p2 = iso_pt(cx, cy, 3, 3, 4)
    p3 = iso_pt(cx, cy, 3, 3, 28)
    p4 = iso_pt(cx, cy, 0, 3, 33)
    p5 = iso_pt(cx, cy, -3, 3, 28)
    d.polygon([p1, p2, p3, p4, p5], fill=(78, 48, 28), outline=OUTLINE)
    mid_top = iso_pt(cx, cy, 0, 3, 32)
    mid_bot = iso_pt(cx, cy, 0, 3, 4)
    d.line([mid_top, mid_bot], fill=OUTLINE, width=1)

    # Nicho do sino e sino de bronze dourado
    s1 = iso_pt(cx, cy, -1.8, 2, 44)
    s2 = iso_pt(cx, cy, 1.8, 2, 44)
    s3 = iso_pt(cx, cy, 1.8, 2, 55)
    s4 = iso_pt(cx, cy, -1.8, 2, 55)
    d.polygon([s1, s2, s3, s4], fill=(46, 38, 34), outline=OUTLINE)
    bx, by = iso_pt(cx, cy, 0, 2, 49)
    d.ellipse([bx - 4, by - 3, bx + 4, by + 4], fill=(228, 176, 58), outline=(138, 96, 24))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "church_portal_64x80.png"))


def create_window_breeze():
    # 48x64 Janela veneziana isométrica com brisa e cortina esvoaçante
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 44

    # Parede/peitoril isométrico onde a janela se apoia
    draw_iso_box(d, cx, cy, -5, -2, 5, 2, 0, 36, (158, 106, 64), (138, 90, 52), (104, 66, 36))
    # Vidro celeste em perspectiva na face SW
    w1 = iso_pt(cx, cy, -3.5, 2, 6)
    w2 = iso_pt(cx, cy, 3.5, 2, 6)
    w3 = iso_pt(cx, cy, 3.5, 2, 31)
    w4 = iso_pt(cx, cy, -3.5, 2, 31)
    d.polygon([w1, w2, w3, w4], fill=(92, 146, 186), outline=OUTLINE)
    # Reflexo diagonal no vidro
    d.line([(w4[0] + 3, w4[1] + 4), (w1[0] + 6, w1[1] - 3)], fill=(175, 220, 248), width=2)

    # Cortina de linho creme soprando para fora (isométrica)
    c1 = iso_pt(cx, cy, -2, 2, 30)
    c2 = iso_pt(cx, cy, 3, 2, 30)
    c3 = iso_pt(cx, cy, 4, 5, 14)
    c4 = iso_pt(cx, cy, -1, 4, 10)
    d.polygon([c1, c2, c3, c4], fill=(246, 240, 226), outline=(182, 172, 154))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "window_breeze_48x64.png"))


def create_reading_desk():
    # 56x48 Escrivaninha de leitura isométrica 2:1 com partitura e óculos
    img = Image.new("RGBA", (56, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 28, 28

    # Gaveteiro lateral esquerdo e pernas direitas
    draw_iso_box(d, cx, cy, -5.5, -2.5, -1.5, 3.5, 0, 14, (124, 72, 38), (108, 62, 32), (84, 46, 22))
    draw_iso_box(d, cx, cy, 3.5, -2.5, 5.5, 3.5, 0, 14, (124, 72, 38), (108, 62, 32), (84, 46, 22))
    # Tampo de mogno polido
    draw_iso_box(d, cx, cy, -6, -3, 6, 4, 14, 17, (168, 102, 54), (144, 84, 42), (112, 64, 30))

    # Partitura aberta em losango sobre o tampo
    s_n = iso_pt(cx, cy, -2, -1, 18)
    s_e = iso_pt(cx, cy, 2, -1, 18)
    s_s = iso_pt(cx, cy, 2, 2, 18)
    s_w = iso_pt(cx, cy, -2, 2, 18)
    d.polygon([s_n, s_e, s_s, s_w], fill=(246, 240, 224), outline=(172, 162, 146))

    # Estojo vermelho e relógio dourado (farol sonoro)
    rx, ry = iso_pt(cx, cy, 3.5, 1, 18)
    d.ellipse([rx - 4, ry - 2, rx + 4, ry + 2], fill=(182, 42, 52), outline=OUTLINE)
    wx, wy = iso_pt(cx, cy, -3.5, 1, 18)
    d.ellipse([wx - 3, wy - 2, wx + 3, wy + 2], fill=(242, 206, 78), outline=(152, 116, 28))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "reading_desk_56x48.png"))


def create_hanging_fern():
    # 48x64 Pedestal isométrico com samambaia e regador de latão
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 22, 44

    # Pedestal de madeira isométrico
    draw_iso_box(d, cx, cy, -2.5, -2.5, 2.5, 2.5, 0, 22, (148, 96, 56), (126, 80, 44), (96, 58, 30))
    # Vaso de terracota
    draw_iso_box(d, cx, cy, -3, -3, 3, 3, 22, 32, (204, 102, 64), (182, 86, 52), (144, 64, 38))

    # Folhagem rica da samambaia em camadas
    vx, vy = iso_pt(cx, cy, 0, 0, 32)
    for ox, oy, r, col in [
        (-8, 2, 6, (44, 128, 56)), (8, 2, 6, (38, 114, 48)),
        (-5, -4, 6, (58, 152, 68)), (5, -4, 6, (48, 138, 58)),
        (0, 4, 7, (52, 144, 62)), (0, -2, 7, (78, 182, 84)),
    ]:
        d.ellipse([vx + ox - r, vy + oy - r // 2, vx + ox + r, vy + oy + r // 2 + 3], fill=col, outline=OUTLINE)

    # Regador de latão dourado na base direita
    draw_iso_box(d, cx + 10, cy + 4, -2, -2, 2, 2, 0, 9, (232, 194, 68), (206, 168, 52), (168, 132, 36))
    d.line([(cx + 14, cy), (cx + 21, cy - 6)], fill=(232, 194, 68), width=2)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "hanging_fern_48x64.png"))


def create_porcelain_cupboard():
    # 48x64 Cristaleira isométrica 2:1 com xícaras e bule de porcelana
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 44

    # Base do buffet
    draw_iso_box(d, cx, cy, -4.5, -2.5, 4.5, 3, 0, 18, (162, 108, 66), (140, 90, 52), (108, 66, 36))
    # Cristaleira superior
    draw_iso_box(d, cx, cy, -4, -2.5, 4, 2, 18, 40, (176, 122, 78), (152, 102, 62), (118, 76, 44))

    # Vitrine azul-clara na face SW com porcelanas brancas/douradas
    v1 = iso_pt(cx, cy, -3, 2, 21)
    v2 = iso_pt(cx, cy, 3, 2, 21)
    v3 = iso_pt(cx, cy, 3, 2, 37)
    v4 = iso_pt(cx, cy, -3, 2, 37)
    d.polygon([v1, v2, v3, v4], fill=(186, 218, 228), outline=OUTLINE)

    # Bule e xícara
    tx, ty = iso_pt(cx, cy, 0, 2, 26)
    d.ellipse([tx - 4, ty - 3, tx + 4, ty + 3], fill=(250, 248, 242), outline=(196, 158, 52))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "porcelain_cupboard_48x64.png"))


def create_yarn_basket():
    # 40x36 Cesta de vime isométrica 2:1 com novelos de lã e guizo dourado
    img = Image.new("RGBA", (40, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Cesta elíptica 2:1
    d.ellipse([5, 14, 35, 31], fill=(146, 102, 58), outline=OUTLINE)
    d.ellipse([5, 10, 35, 26], fill=(188, 142, 88), outline=OUTLINE)
    d.ellipse([8, 12, 32, 24], fill=(122, 84, 46))

    # Novelos de lã rubi e creme
    d.ellipse([11, 8, 23, 19], fill=(212, 52, 62), outline=OUTLINE)
    d.arc([13, 10, 21, 17], start=20, end=160, fill=(248, 112, 120), width=1)
    d.ellipse([20, 10, 30, 19], fill=(238, 216, 172), outline=OUTLINE)

    # Guizo dourado na frente
    d.ellipse([26, 23, 32, 29], fill=(242, 202, 64), outline=OUTLINE)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "yarn_basket_40x36.png"))


def create_broom_bucket():
    # 36x48 Balde de zinco isométrico e vassoura de palha
    img = Image.new("RGBA", (36, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Balde cilíndrico isométrico
    d.polygon([(12, 26), (28, 26), (26, 42), (14, 42)], fill=(154, 166, 178), outline=OUTLINE)
    d.ellipse([14, 39, 26, 45], fill=(132, 144, 156), outline=OUTLINE)
    d.ellipse([12, 23, 28, 31], fill=(192, 204, 216), outline=OUTLINE)
    d.ellipse([14, 25, 26, 29], fill=(92, 164, 214))

    # Cabo e palha da vassoura inclinada
    d.line([(8, 5), (22, 41)], fill=(168, 114, 62), width=2)
    d.polygon([(4, 4), (12, 3), (16, 16), (3, 17)], fill=(232, 198, 92), outline=OUTLINE)
    d.line([(4, 12), (15, 11)], fill=(188, 48, 48), width=2)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "broom_bucket_36x48.png"))


def create_hallway_stand():
    # 48x64 Aparador de entrada isométrico 2:1 com espelho e chaves de latão
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 44

    # Aparador inferior
    draw_iso_box(d, cx, cy, -4.5, -2, 4.5, 2.5, 0, 18, (158, 98, 54), (136, 82, 44), (104, 60, 30))
    # Painel alto do cabideiro/espelho
    draw_iso_box(d, cx, cy, -4, -2, 4, -0.5, 18, 42, (138, 82, 44), (120, 70, 36), (92, 52, 26))

    # Espelho na face SW
    m1 = iso_pt(cx, cy, -2.5, -0.5, 22)
    m2 = iso_pt(cx, cy, 2.5, -0.5, 22)
    m3 = iso_pt(cx, cy, 2.5, -0.5, 38)
    m4 = iso_pt(cx, cy, -2.5, -0.5, 38)
    d.polygon([m1, m2, m3, m4], fill=(196, 228, 242), outline=(212, 172, 64))

    # Molho de chaves dourado sobre o tampo
    kx, ky = iso_pt(cx, cy, 1, 1, 19)
    d.ellipse([kx - 3, ky - 2, kx + 3, ky + 2], fill=(242, 202, 64), outline=OUTLINE)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "hallway_stand_48x64.png"))


def create_seaside_bench():
    # 56x40 Banco do mirante em projeção isométrica 2:1
    img = Image.new("RGBA", (56, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 28, 22

    # Pés de ferro fundido
    draw_iso_box(d, cx, cy, -6, -2, -4.5, 3, 0, 8, (68, 78, 86))
    draw_iso_box(d, cx, cy, 4.5, -2, 6, 3, 0, 8, (68, 78, 86))
    # Assento de madeira em perspectiva 2:1
    draw_iso_box(d, cx, cy, -6.5, -2.5, 6.5, 3.5, 8, 11, (186, 158, 126), (162, 136, 106), (128, 106, 82))
    # Encosto isométrico
    draw_iso_box(d, cx, cy, -6.5, -2.5, 6.5, -1.2, 11, 21, (176, 148, 116), (154, 128, 98), (122, 98, 74))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "seaside_bench_56x40.png"))


def create_station_lantern():
    # 40x64 Poste e lanterna de vapor isométricos da plataforma
    img = Image.new("RGBA", (40, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 20, 48

    # Base octogonal/prisma de ferro verde-escuro
    draw_iso_box(d, cx, cy, -3, -3, 3, 3, 0, 6, (62, 84, 74), (48, 68, 58), (34, 50, 42))
    # Coluna central
    draw_iso_box(d, cx, cy, -1.2, -1.2, 1.2, 1.2, 6, 32, (54, 76, 66), (42, 60, 52), (30, 44, 38))
    # Câmara de vidro âmbar iluminada (farol sonoro/visual)
    draw_iso_box(d, cx, cy, -2.8, -2.8, 2.8, 2.8, 32, 42, (255, 232, 132), (255, 212, 88), (228, 172, 54))
    # Cúpula superior de ferro
    draw_iso_box(d, cx, cy, -3.2, -3.2, 3.2, 3.2, 42, 45, (62, 84, 74), (48, 68, 58), (34, 50, 42))

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "station_lantern_40x64.png"))


def create_cello_stand():
    # 48x64 Violoncelo em repouso no suporte isométrico + estante de partitura
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 46

    # Tapete/base acústica circular 2:1 sob o violoncelo
    d.ellipse([6, 38, 42, 56], fill=(116, 48, 44), outline=OUTLINE)
    d.ellipse([9, 40, 39, 54], fill=(142, 62, 56))

    # Caixa acústica do violoncelo em perspectiva 3/4
    d.ellipse([13, 24, 35, 50], fill=(112, 48, 18), outline=OUTLINE)
    d.ellipse([11, 24, 33, 50], fill=(168, 78, 32), outline=OUTLINE)
    # Brilho do verniz e efes (f-holes)
    d.arc([14, 27, 30, 47], start=195, end=330, fill=(212, 118, 58), width=1)
    d.line([(18, 33), (18, 41)], fill=OUTLINE, width=1)
    d.line([(26, 33), (26, 41)], fill=OUTLINE, width=1)

    # Espelho de ébano, cravelhal e voluta
    d.polygon([(20, 10), (24, 10), (24, 32), (20, 32)], fill=(38, 34, 32), outline=OUTLINE)
    d.ellipse([19, 4, 25, 10], fill=(154, 68, 28), outline=OUTLINE)
    # Cordas claras
    d.line([(21, 9), (21, 46)], fill=(238, 232, 214), width=1)
    d.line([(23, 9), (23, 46)], fill=(238, 232, 214), width=1)
    # Espigão metálico
    d.line([(22, 50), (22, 55)], fill=(210, 216, 222), width=2)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "cello_stand_48x64.png"))


def create_wind_chimes_stand():
    # 48x64 Carrilhão de vento de concerto em pedestal isométrico 2:1
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 24, 46

    # Base de madeira e latão em projeção 2:1
    draw_iso_box(d, cx, cy, -4, -3, 4, 3, 0, 5, (142, 92, 48), (122, 76, 38), (94, 56, 26))
    # Coluna lateral e travessa superior dourada
    draw_iso_box(d, cx, cy, -3.5, -0.8, -2, 0.8, 5, 38, (218, 178, 62), (192, 152, 48), (154, 118, 32))
    draw_iso_box(d, cx, cy, -4, -1.2, 4, 1.2, 36, 40, (238, 198, 76), (212, 172, 58), (172, 136, 42))

    # Tubos acústicos cromáticos suspensos em diagonal isométrica
    for i in range(6):
        t = i / 5.0
        top_pt = iso_pt(cx, cy, -2.5 + 5.0 * t, 0, 36)
        length = 22 - i * 2
        col = (242, 208, 92) if i % 2 == 0 else (206, 236, 255)
        d.line([top_pt, (top_pt[0], top_pt[1] + length)], fill=col, width=2)

    img = apply_crisp_outline(img)
    img.save(os.path.join(OUTPUT_DIR, "wind_chimes_stand_48x64.png"))


if __name__ == "__main__":
    create_iron_gate()
    create_bakery_counter()
    create_fountain_stone()
    create_church_portal()
    create_window_breeze()
    create_reading_desk()
    create_hanging_fern()
    create_porcelain_cupboard()
    create_yarn_basket()
    create_broom_bucket()
    create_hallway_stand()
    create_seaside_bench()
    create_station_lantern()
    create_cello_stand()
    create_wind_chimes_stand()
    print("All 15 isometric 2:1 pixel art scenery props generated successfully!")

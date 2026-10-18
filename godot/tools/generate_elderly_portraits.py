#!/usr/bin/env python3
"""
Gerador/Atualizador dos 5 Retratos Reativos de HUD do Sr. Arthur (128x128)
no Novo Estilo de Velhinho Carismático:
- portrait_idle.png
- portrait_listening.png
- portrait_bump.png
- portrait_confused.png
- portrait_happy.png
- portrait_elderly_sheet.png (640x128 tira combinada)

Mantém o alinhamento pixel-locked e a expressividade de cada reação enquanto atualiza:
1. Sobrancelhas brancas/prateadas fofas em todos os 5 estados (corrigindo idle e happy).
2. Óculos redondos com aro dourado/âmbar antigo (#F2CA68 / #D8A03C / #9A6820) e reflexo azul-claro nas lentes.
3. Bigode branco farto (#F8FAFF / #DAE2F2) esculpido sob medida para cada uma das 5 expressões.
4. Gravatinha borboleta bordô (#C43640 / #DF4B56 / #8F222A) na gola creme e acabamento conhaque (#C68B53) no cardigã verde-sálvia.
"""

import os
from PIL import Image

BASE_DIR = "godot/tools/portrait_base"
OUT_DIR = "godot/assets/sprites/ui/portrait"

STATES = ["idle", "listening", "bump", "confused", "happy"]

# Paleta do Novo Estilo do Velhinho
HAIR_WHITE   = (248, 250, 255, 255)
HAIR_LIGHT   = (236, 240, 248, 255)
HAIR_SILVER  = (210, 218, 234, 255)
HAIR_SHADOW  = (166, 174, 192, 255)
HAIR_BORDER  = (124, 118, 134, 255)

GOLD_BRIGHT  = (246, 208, 108, 255)
GOLD_BASE    = (216, 160, 60, 255)
GOLD_DEEP    = (156, 104, 34, 255)
LENS_GLINT   = (216, 238, 255, 255)

BOWTIE_LIGHT = (226, 82, 92, 255)
BOWTIE_BASE  = (196, 54, 64, 255)
BOWTIE_DARK  = (143, 34, 42, 255)
BOWTIE_OUT   = (48, 24, 30, 255)

COGNAC_LIGHT = (206, 148, 92, 255)
COGNAC_BASE  = (172, 114, 64, 255)
COGNAC_DARK  = (122, 76, 40, 255)


def put_2x2(px, x, y, col):
    """Pinta um bloco 2x2 alinhado à resolução artística do retrato."""
    for dy in range(2):
        for dx in range(2):
            if 0 <= x + dx < 128 and 0 <= y + dy < 128:
                px[x + dx, y + dy] = col


def upgrade_eyebrows_to_white(px, state):
    """
    Garante que as sobrancelhas em idle e happy tenham o mesmo branco/prateado
    fofo e expressivo de listening, bump e confused.
    """
    if state not in ("idle", "happy"):
        return

    for y in range(49, 62):
        for x in range(16, 72):
            # Ignora o contorno externo esquerdo da cabeça
            if x <= 16 and y >= 54:
                continue
            # Ignora o topo do olho esquerdo em idle (y>=60, x<=29)
            if state == "idle" and y >= 60 and x <= 30:
                continue
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            # Pixels escuros da sobrancelha antiga
            if r < 150 and g < 125 and b < 125:
                # Verifica se é borda da sobrancelha (vizinho de pele clara)
                is_bottom = (y >= 57) or (x <= 18) or (x >= 67)
                if r > 90:
                    px[x, y] = HAIR_BORDER
                elif is_bottom:
                    px[x, y] = HAIR_SILVER
                elif y <= 53:
                    px[x, y] = HAIR_WHITE
                else:
                    px[x, y] = HAIR_LIGHT


def upgrade_glasses_to_gold(px):
    """
    Converte o aro inferior/lateral/ponte/haste dos óculos redondos para
    ouro/âmbar antigo (#F2CA68 / #D8A03C / #9A6820) e adiciona reflexo azul-claro nas lentes.
    """
    for y in range(66, 87):
        for x in range(15, 86):
            # Protege o contorno preto externo esquerdo do rosto (x <= 15)
            if x <= 15:
                continue
            # Protege a região das pupilas/olhos dentro das lentes:
            # Olho esquerdo: x=19..28, y=60..69
            if 19 <= x <= 28 and y <= 69:
                continue
            # Olho direito: x=48..67, y=60..71
            if 48 <= x <= 67 and y <= 71:
                continue

            r, g, b, a = px[x, y]
            if a < 128:
                continue

            # Detecta pixels pertencentes ao aro/ponte/haste dos óculos
            # (tons cinza-escuro, marrom-escuro ou chumbo na zona dos óculos)
            is_rim_dark = (r < 155 and g < 135 and b < 145 and (abs(r - b) < 38 or (r - g < 38 and g < 105)))
            # Apenas na geometria real dos aros:
            in_bridge = (27 <= x <= 39 and 69 <= y <= 74)
            in_left_rim = (16 <= x <= 29 and 70 <= y <= 82)
            in_right_inner = (39 <= x <= 55 and 71 <= y <= 84)
            in_right_bottom = (44 <= x <= 73 and 73 <= y <= 86)
            in_temple = (72 <= x <= 85 and 67 <= y <= 74)

            if is_rim_dark and (in_bridge or in_left_rim or in_right_inner or in_right_bottom or in_temple):
                lum = (r + g + b) / 3.0
                if y <= 72 or lum > 105:
                    px[x, y] = GOLD_BRIGHT
                elif lum > 68:
                    px[x, y] = GOLD_BASE
                else:
                    px[x, y] = GOLD_DEEP

    # Adiciona um delicado brilho azul-celeste nas lentes (canto inferior-esquerdo de cada lente)
    put_2x2(px, 18, 72, LENS_GLINT)
    put_2x2(px, 44, 72, LENS_GLINT)


def draw_mustache_for_state(px, state):
    """
    Esculpe um bigode branco farto e carismático (#F8FAFF / #DAE2F2) logo abaixo do nariz
    (y=84..94, x=20..58), adaptado para a expressão facial de cada reação!
    """
    # Mapa de blocos 2x2 (em coordenadas pares x, y):
    # 'B' = borda suave (#7C7686), 'S' = sombra prateada (#D2DAEA),
    # 'L' = branco suave (#ECF0F8), 'W' = branco brilhante (#F8FAFF)
    if state == "idle":
        # Bigode clássico acolhedor, deixando o sorriso gentil em y=95..97 visível abaixo
        rows = {
            86: [(26, "B"), (28, "W"), (30, "W"), (32, "B"), (36, "B"), (38, "W"), (40, "W"), (42, "W"), (44, "B")],
            88: [(22, "B"), (24, "W"), (26, "W"), (28, "W"), (30, "W"), (32, "L"), (34, "L"), (36, "W"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "W"), (48, "B")],
            90: [(20, "B"), (22, "W"), (24, "W"), (26, "S"), (28, "S"), (30, "B"), (38, "B"), (40, "S"), (42, "S"), (44, "W"), (46, "W"), (48, "S"), (50, "B")],
            92: [(20, "S"), (22, "S"), (48, "S"), (50, "S")],
        }
    elif state == "listening":
        # Bigode sereno e atento, levemente erguido no lado direito (direção da orelha que escuta)
        rows = {
            86: [(26, "B"), (28, "W"), (30, "W"), (32, "B"), (36, "B"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "B")],
            88: [(22, "B"), (24, "W"), (26, "W"), (28, "W"), (30, "W"), (32, "L"), (34, "L"), (36, "W"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "W"), (48, "W"), (50, "B")],
            90: [(20, "B"), (22, "W"), (24, "S"), (26, "S"), (28, "B"), (40, "B"), (42, "S"), (44, "S"), (46, "S"), (48, "B")],
            92: [(20, "S"), (22, "B")],
        }
    elif state == "bump":
        # Bigode eriçado/assustado mais alto (y=84..90) para revelar 100% os dentes cerrados em y=92..98!
        rows = {
            84: [(26, "B"), (28, "W"), (30, "W"), (32, "B"), (36, "B"), (38, "W"), (40, "W"), (42, "B")],
            86: [(20, "B"), (22, "W"), (24, "W"), (26, "W"), (28, "W"), (30, "L"), (32, "L"), (34, "L"), (36, "W"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "W"), (48, "B")],
            88: [(18, "B"), (20, "W"), (22, "S"), (24, "S"), (26, "B"), (40, "B"), (42, "S"), (44, "S"), (46, "W"), (48, "S"), (50, "B")],
            90: [(18, "S"), (48, "S"), (50, "B")],
        }
    elif state == "confused":
        # Bigode assimétrico inclinado (lado esq mais alto, lado dir caído acompanhando a boca confusa)
        rows = {
            86: [(22, "B"), (24, "W"), (26, "W"), (28, "W"), (30, "W"), (32, "B"), (36, "B"), (38, "W"), (40, "B")],
            88: [(20, "B"), (22, "W"), (24, "S"), (26, "S"), (28, "L"), (30, "L"), (32, "L"), (34, "L"), (36, "W"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "B")],
            90: [(20, "S"), (36, "B"), (38, "S"), (40, "S"), (42, "W"), (44, "W"), (46, "W"), (48, "B")],
            92: [(44, "S"), (46, "S"), (48, "S"), (50, "B")],
        }
    else:  # happy
        # Bigode farto e sorridente (arco elevado e orgânico acompanhando o sorriso largo)
        rows = {
            86: [(24, "B"), (26, "W"), (28, "W"), (30, "W"), (32, "B"), (36, "B"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "B")],
            88: [(20, "B"), (22, "W"), (24, "W"), (26, "W"), (28, "W"), (30, "L"), (32, "L"), (34, "L"), (36, "W"), (38, "W"), (40, "W"), (42, "W"), (44, "W"), (46, "W"), (48, "W"), (50, "B")],
            90: [(18, "B"), (20, "W"), (22, "S"), (24, "S"), (26, "B"), (40, "B"), (42, "S"), (44, "S"), (46, "S"), (48, "W"), (50, "S"), (52, "B")],
        }

    col_map = {
        "B": HAIR_BORDER,
        "S": HAIR_SILVER,
        "L": HAIR_LIGHT,
        "W": HAIR_WHITE,
    }
    for y, items in rows.items():
        for x, code in items:
            put_2x2(px, x, y, col_map[code])

    # Em happy, acentua o sorriso aberto e radiante sob o bigode e o rubor acolhedor nas bochechas
    if state == "happy":
        for x in range(30, 46, 2):
            put_2x2(px, x, 94, (132, 62, 52, 255))
            if 32 <= x <= 42:
                put_2x2(px, x, 96, (218, 112, 98, 255))
                put_2x2(px, x, 98, (142, 74, 62, 255))
        put_2x2(px, 28, 92, (142, 74, 62, 255))
        put_2x2(px, 46, 92, (142, 74, 62, 255))
        # Rubor suave nas bochechas
        for bx, by in ((18, 82), (20, 82), (54, 82), (56, 82)):
            put_2x2(px, bx, by, (242, 152, 132, 255))


def draw_collar_bowtie_and_lapels(px):
    """
    Adiciona a gravatinha borboleta bordô (#C43640) centralizada na gola creme (y=118..126)
    e um discreto debrum conhaque acompanhando a diagonal real da lapela do cardigã.
    """
    # 1. Debrum conhaque suave seguindo a diagonal natural da lapela do cardigã
    lapel_pts = [
        (32, 112, COGNAC_DARK), (32, 114, COGNAC_BASE), (34, 116, COGNAC_BASE),
        (34, 118, COGNAC_LIGHT), (34, 120, COGNAC_BASE), (34, 122, COGNAC_BASE),
        (34, 124, COGNAC_DARK), (34, 126, COGNAC_DARK),
        (68, 110, COGNAC_DARK), (66, 112, COGNAC_BASE), (64, 114, COGNAC_LIGHT),
        (64, 116, COGNAC_BASE), (62, 118, COGNAC_LIGHT), (62, 120, COGNAC_BASE),
        (60, 122, COGNAC_BASE), (60, 124, COGNAC_DARK), (60, 126, COGNAC_DARK),
    ]
    for lx, ly, col in lapel_pts:
        put_2x2(px, lx, ly, col)

    # 2. Gravatinha Borboleta Bordô (#C43640) em x=38..58, y=118..126
    bowtie_rows = {
        118: [(38, "O"), (40, "L"), (42, "L"), (44, "O"), (52, "O"), (54, "L"), (56, "L"), (58, "O")],
        120: [(38, "O"), (40, "L"), (42, "B"), (44, "D"), (46, "O"), (48, "L"), (50, "O"), (52, "D"), (54, "B"), (56, "L"), (58, "O")],
        122: [(38, "O"), (40, "B"), (42, "D"), (44, "B"), (46, "O"), (48, "D"), (50, "O"), (52, "B"), (54, "D"), (56, "B"), (58, "O")],
        124: [(38, "O"), (40, "D"), (42, "D"), (44, "O"), (46, "O"), (48, "O"), (50, "O"), (52, "O"), (54, "D"), (56, "D"), (58, "O")],
    }
    b_map = {
        "O": BOWTIE_OUT,
        "L": BOWTIE_LIGHT,
        "B": BOWTIE_BASE,
        "D": BOWTIE_DARK,
    }
    for y, items in bowtie_rows.items():
        for x, code in items:
            put_2x2(px, x, y, b_map[code])


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    sheet = Image.new("RGBA", (128 * len(STATES), 128), (0, 0, 0, 0))

    for idx, state in enumerate(STATES):
        base_path = os.path.join(BASE_DIR, f"portrait_{state}.png")
        im = Image.open(base_path).convert("RGBA")
        px = im.load()

        upgrade_eyebrows_to_white(px, state)
        upgrade_glasses_to_gold(px)
        draw_mustache_for_state(px, state)
        draw_collar_bowtie_and_lapels(px)

        out_path = os.path.join(OUT_DIR, f"portrait_{state}.png")
        im.save(out_path)
        sheet.paste(im, (idx * 128, 0))
        print(f"Generated {out_path}")

    sheet_path = os.path.join(OUT_DIR, "portrait_elderly_sheet.png")
    sheet.save(sheet_path)
    print(f"Generated {sheet_path}")


if __name__ == "__main__":
    main()

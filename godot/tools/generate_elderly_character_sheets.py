#!/usr/bin/env python3
r"""
Gerador Procedural de Sprite Sheets do Protagonista Idoso (Sr. Arthur) — v2
Estilo: Clean Cozy Pixel Art (32x32 por frame, 5 linhas direcionais: s, se, e, ne, n)

Melhorias desta versão:
1. ZERO FLUTUAÇÃO: Os sapatos tocam firmemente a linha base fy=31 em todos os frames
   apoiados no solo (Idle, Walk, Run, Interact, Attack, Rotate e início/fim do Jump).
2. ANIMAÇÃO DE CAMINHADA E CORRIDA REALISTA:
   - Nas direções diagonais/laterais (se, e, ne): passadas em tesoura (/\ com abertura de 6px),
     joelho dobrado levantando o pé nos frames de passagem enquanto o pé de apoio segue firme em fy=31,
     e balanço alternado de braços e ombros.
   - Nas direções frontal/costas (s, n): alternância nítida de profundidade onde a perna que dá o passo
     desce até fy=31 (sapato completo com brilho) e a outra perna recolhe 3px acima (fy=28, deixando
     fy=29..31 transparente sob o pé erguido!), com torção de ombros e balanço de braços.
3. NOVO VISUAL CARISMÁTICO DO VELHINHO:
   - Cabeça arredondada orgânica (sem cantos quadrados), careca iluminada no topo e coroa de cabelo
     grisalho/branco fofo nas têmporas e nuca (formato ferradura real visto de costas).
   - Sobrancelhas brancas arqueadas, óculos redondos de aro dourado/âmbar com olhinhos vivos e reflexo
     azul-claro nas lentes, e um simpático bigode branco farto!
   - Cardigã verde-sálvia aconchegante com acabamento conhaque, camisa creme, gravatinha borboleta
     bordô (#C43640), botões dourados, cinto de couro, calça grafite e sapatos de couro marrom polido.
"""

import os
from PIL import Image

OUT_DIR = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites\character\16x32_elderly"

# Paleta Clean Cozy Pixel Art — Novo Visual do Sr. Arthur
OUTLINE       = (40, 26, 20, 255)      # Contorno escuro quente (#281A14)
SKIN_LIGHT    = (255, 236, 214, 255)   # Brilho da careca / testa
SKIN_BASE     = (250, 216, 188, 255)   # Pele pêssego acolhedora
SKIN_SHADOW   = (224, 184, 154, 255)   # Sombra suave do rosto/pescoço
SKIN_DEEP     = (196, 150, 120, 255)   # Orelha / nariz
BLUSH         = (236, 154, 150, 255)   # Bochechas coradas

HAIR_WHITE    = (248, 250, 255, 255)   # Cabelo e bigode branco puro
HAIR_SILVER   = (214, 222, 234, 255)   # Grisalho prateado médio
HAIR_SHADOW   = (168, 178, 194, 255)   # Sombra da coroa de cabelo

GLASSES_GOLD  = (188, 128, 58, 255)    # Aro dourado/âmbar quente dos óculos
GLASSES_RIM   = (124, 78, 36, 255)     # Sombra do aro dos óculos
GLASSES_LENS  = (218, 242, 255, 255)   # Reflexo cristalino da lente
EYE_DARK      = (32, 20, 16, 255)      # Pupila viva

SHIRT_CREAM   = (252, 246, 232, 255)   # Camisa social creme
BOWTIE_RED    = (196, 54, 64, 255)     # Gravatinha / lenço bordô (#C43640)
BOWTIE_DARK   = (142, 34, 42, 255)     # Sombra da gravatinha bordô

CARD_LIGHT    = (118, 162, 126, 255)   # Cardigã verde-sálvia iluminado
CARD_BASE     = (86, 130, 96, 255)     # Cardigã verde-sálvia base
CARD_SHADOW   = (62, 98, 70, 255)      # Cardigã verde-sálvia sombra
CARD_TRIM     = (156, 98, 54, 255)     # Lapela / acabamento em lã conhaque
BUTTON_GOLD   = (242, 202, 72, 255)    # Botões dourados

BELT_LEATHER  = (92, 54, 32, 255)      # Cinto de couro marrom
PANTS_LIGHT   = (74, 80, 96, 255)      # Calça grafite iluminada
PANTS_BASE    = (54, 58, 72, 255)      # Calça grafite base
PANTS_SHADOW  = (38, 42, 54, 255)      # Calça grafite sombra (perna de trás)

SHOE_LIGHT    = (138, 84, 48, 255)     # Brilho do bico do sapato marrom
SHOE_BASE     = (98, 58, 32, 255)      # Sapato de couro marrom
SHOE_DARK     = (62, 36, 20, 255)      # Sola / sapato em sombra

CANE_GRIP     = (46, 46, 54, 255)      # Empunhadura preta antiderrapante
CANE_SHAFT    = (252, 254, 255, 255)   # Haste branca brilhante
CANE_EDGE     = (74, 64, 58, 220)      # Contorno sutil para contraste em pisos claros
CANE_RED      = (228, 42, 42, 255)     # Faixa refletiva vermelha
CANE_TIP      = (255, 255, 255, 255)   # Ponteira roller branca
TAP_SPARK     = (120, 215, 255, 240)   # Brilho tátil na ponteira


def put(px, x, y, col):
    if 0 <= x < 32 and 0 <= y < 32 and col is not None:
        px[x, y] = col


def fill_rect(px, x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(px, x, y, col)


def draw_cane(px, x0, y0, x1, y1, behind_body=False, tap_highlight=False):
    """Desenha a bengala longa com Bresenham e borda de contraste lateral."""
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy

    pts = []
    cx, cy = x0, y0
    while True:
        pts.append((cx, cy))
        if cx == x1 and cy == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            cx += sx
        if e2 < dx:
            err += dx
            cy += sy

    n = len(pts)
    if n == 0:
        return

    for i, (x, y) in enumerate(pts):
        if i == 0 or i >= n - 1:
            continue
        sx_edge = x - 1 if x1 >= x0 else x + 1
        if 0 <= sx_edge < 32 and 0 <= y < 32 and px[sx_edge, y][3] == 0:
            put(px, sx_edge, y, CANE_EDGE)

    for i, (x, y) in enumerate(pts):
        if not (0 <= x < 32 and 0 <= y < 32):
            continue
        if behind_body and px[x, y][3] > 0 and px[x, y] != CANE_EDGE and i < n - 2:
            continue
        frac = i / max(1, n - 1)
        if frac <= 0.18:
            col = CANE_GRIP
        elif frac <= 0.66:
            col = CANE_SHAFT
        elif frac <= 0.90:
            col = CANE_RED
        else:
            col = CANE_TIP
        put(px, x, y, col)

    put(px, x1, y1, CANE_TIP)
    if tap_highlight:
        for ox, oy in ((-1, 0), (1, 0), (0, -1)):
            tx, ty = x1 + ox, y1 + oy
            if 0 <= tx < 32 and 0 <= ty < 32 and px[tx, ty][3] == 0:
                put(px, tx, ty, TAP_SPARK)


def draw_head(px, row, cx, top_y, eyes_closed=False, head_tilt=0):
    """
    Desenha a cabeça arredondada e expressiva do Sr. Arthur (altura 10px: y0..y0+9):
    - Careca iluminada no topo com domo arredondado
    - Cabelo branco/prateado fofo nas têmporas e nuca
    - Óculos de aro dourado/âmbar com pupilas nítidas e reflexo azul-claro
    - Bigode branco simpático nas vistas frontais/laterais (s, se, e)
    """
    y0 = top_y
    cx = cx + head_tilt

    # Silhueta arredondada comum (domo suave no topo e queixo arredondado)
    fill_rect(px, cx - 2, y0, cx + 2, y0, OUTLINE)
    fill_rect(px, cx - 4, y0 + 1, cx + 4, y0 + 1, OUTLINE)
    fill_rect(px, cx - 5, y0 + 2, cx + 5, y0 + 7, OUTLINE)
    fill_rect(px, cx - 4, y0 + 8, cx + 4, y0 + 8, OUTLINE)
    fill_rect(px, cx - 2, y0 + 9, cx + 2, y0 + 9, OUTLINE)

    if row == 0:  # SOUTH (Frente ↓)
        # Interior da pele
        fill_rect(px, cx - 3, y0 + 1, cx + 3, y0 + 1, SKIN_LIGHT)
        fill_rect(px, cx - 3, y0 + 2, cx + 3, y0 + 7, SKIN_BASE)
        fill_rect(px, cx - 2, y0 + 8, cx + 2, y0 + 8, SKIN_SHADOW)
        put(px, cx - 1, y0 + 1, SKIN_LIGHT)
        put(px, cx, y0 + 2, SKIN_LIGHT)

        # Cabelo branco fofo nas laterais (têmporas arredondadas)
        for dy in range(2, 7):
            put(px, cx - 4, y0 + dy, HAIR_WHITE if dy < 5 else HAIR_SILVER)
            put(px, cx + 4, y0 + dy, HAIR_WHITE if dy < 4 else HAIR_SILVER)
        put(px, cx - 3, y0 + 2, HAIR_WHITE)
        put(px, cx + 3, y0 + 2, HAIR_SILVER)
        # Tufos auriculares fofos
        put(px, cx - 5, y0 + 3, HAIR_WHITE)
        put(px, cx - 5, y0 + 4, HAIR_SILVER)
        put(px, cx - 6, y0 + 3, OUTLINE)
        put(px, cx - 6, y0 + 4, OUTLINE)
        put(px, cx + 5, y0 + 3, HAIR_SILVER)
        put(px, cx + 5, y0 + 4, HAIR_SHADOW)
        put(px, cx + 6, y0 + 3, OUTLINE)
        put(px, cx + 6, y0 + 4, OUTLINE)

        # Sobrancelhas brancas arqueadas
        put(px, cx - 2, y0 + 3, HAIR_WHITE)
        put(px, cx - 1, y0 + 3, HAIR_WHITE)
        put(px, cx + 1, y0 + 3, HAIR_WHITE)
        put(px, cx + 2, y0 + 3, HAIR_WHITE)

        # Óculos redondos de aro dourado/âmbar + olhinhos vivos (sem barra preta pesada!)
        put(px, cx - 3, y0 + 4, GLASSES_GOLD)
        put(px, cx - 2, y0 + 4, EYE_DARK if not eyes_closed else GLASSES_GOLD)
        put(px, cx - 1, y0 + 4, GLASSES_LENS if not eyes_closed else GLASSES_GOLD)
        put(px, cx, y0 + 4, GLASSES_GOLD)  # Ponte dourada
        put(px, cx + 1, y0 + 4, EYE_DARK if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 2, y0 + 4, GLASSES_LENS if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 3, y0 + 4, GLASSES_GOLD)

        # Parte inferior suave do aro + bochechas
        put(px, cx - 2, y0 + 5, GLASSES_GOLD)
        put(px, cx - 1, y0 + 5, SKIN_BASE)
        put(px, cx, y0 + 5, SKIN_DEEP)      # Narizinho arredondado
        put(px, cx + 1, y0 + 5, SKIN_BASE)
        put(px, cx + 2, y0 + 5, GLASSES_GOLD)
        put(px, cx - 3, y0 + 6, BLUSH)
        put(px, cx + 3, y0 + 6, BLUSH)

        # Bigode branco farto e simpático (#F8FAFF) em y0+6..y0+7!
        put(px, cx - 2, y0 + 6, HAIR_WHITE)
        put(px, cx - 1, y0 + 6, HAIR_WHITE)
        put(px, cx, y0 + 6, HAIR_WHITE)
        put(px, cx + 1, y0 + 6, HAIR_WHITE)
        put(px, cx + 2, y0 + 6, HAIR_SILVER)
        put(px, cx - 2, y0 + 7, HAIR_SILVER)
        put(px, cx + 2, y0 + 7, HAIR_SILVER)
        # Sorriso acolhedor sob o bigode
        put(px, cx - 1, y0 + 7, SKIN_DEEP)
        put(px, cx, y0 + 7, SKIN_DEEP)
        put(px, cx + 1, y0 + 7, SKIN_SHADOW)

    elif row == 1:  # SOUTH-EAST (Diagonal 3/4 Frente-Direita ↘)
        fill_rect(px, cx - 2, y0 + 1, cx + 3, y0 + 2, SKIN_LIGHT)
        fill_rect(px, cx - 2, y0 + 3, cx + 4, y0 + 7, SKIN_BASE)
        fill_rect(px, cx - 2, y0 + 8, cx + 3, y0 + 8, SKIN_SHADOW)

        # Cabelo branco fofo na nuca/esquerda
        put(px, cx - 3, y0 + 1, HAIR_WHITE)
        for dy in range(2, 8):
            put(px, cx - 4, y0 + dy, HAIR_WHITE if dy < 5 else HAIR_SILVER)
            put(px, cx - 3, y0 + dy, HAIR_WHITE if dy < 6 else HAIR_SILVER)
        put(px, cx - 5, y0 + 3, HAIR_WHITE)
        put(px, cx - 5, y0 + 4, HAIR_SILVER)
        put(px, cx - 6, y0 + 3, OUTLINE)
        put(px, cx - 6, y0 + 4, OUTLINE)
        put(px, cx - 2, y0 + 3, HAIR_SILVER)
        # Orelha esquerda
        put(px, cx - 2, y0 + 5, SKIN_DEEP)
        put(px, cx - 2, y0 + 6, SKIN_SHADOW)

        # Sobrancelhas brancas em 3/4
        put(px, cx, y0 + 3, HAIR_WHITE)
        put(px, cx + 1, y0 + 3, HAIR_WHITE)
        put(px, cx + 3, y0 + 3, HAIR_WHITE)
        put(px, cx + 4, y0 + 3, HAIR_WHITE)

        # Óculos dourados e olhos voltados p/ sudeste (↘)
        put(px, cx - 1, y0 + 4, GLASSES_RIM)
        put(px, cx, y0 + 4, EYE_DARK if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 1, y0 + 4, GLASSES_LENS if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 2, y0 + 4, GLASSES_GOLD)
        put(px, cx + 3, y0 + 4, EYE_DARK if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 4, y0 + 4, GLASSES_LENS if not eyes_closed else GLASSES_GOLD)

        put(px, cx, y0 + 5, GLASSES_GOLD)
        put(px, cx + 1, y0 + 5, SKIN_BASE)
        put(px, cx + 2, y0 + 5, SKIN_DEEP)   # Nariz 3/4
        put(px, cx + 3, y0 + 5, GLASSES_GOLD)
        put(px, cx, y0 + 6, BLUSH)

        # Bigode branco em 3/4 (cx..cx+4)
        put(px, cx, y0 + 6, HAIR_WHITE)
        put(px, cx + 1, y0 + 6, HAIR_WHITE)
        put(px, cx + 2, y0 + 6, HAIR_WHITE)
        put(px, cx + 3, y0 + 6, HAIR_WHITE)
        put(px, cx + 4, y0 + 6, HAIR_SILVER)
        put(px, cx, y0 + 7, HAIR_SILVER)
        put(px, cx + 1, y0 + 7, SKIN_DEEP)
        put(px, cx + 2, y0 + 7, SKIN_DEEP)
        put(px, cx + 3, y0 + 7, HAIR_SILVER)

    elif row == 2:  # EAST (Perfil Direito →)
        # Reajusta largura para perfil elegante
        fill_rect(px, cx - 5, y0 + 2, cx - 5, y0 + 7, (0, 0, 0, 0))
        fill_rect(px, cx - 4, y0 + 2, cx + 4, y0 + 7, OUTLINE)
        fill_rect(px, cx - 3, y0 + 8, cx + 3, y0 + 8, OUTLINE)

        fill_rect(px, cx - 2, y0 + 1, cx + 3, y0 + 2, SKIN_LIGHT)
        fill_rect(px, cx - 1, y0 + 3, cx + 3, y0 + 7, SKIN_BASE)
        fill_rect(px, cx - 1, y0 + 8, cx + 2, y0 + 8, SKIN_SHADOW)

        # Coroa de cabelo branco fofo na nuca
        put(px, cx - 3, y0 + 1, HAIR_WHITE)
        for dy in range(2, 8):
            put(px, cx - 3, y0 + dy, HAIR_WHITE if dy < 5 else HAIR_SILVER)
            if dy in (2, 3, 4, 6, 7):
                put(px, cx - 2, y0 + dy, HAIR_WHITE if dy < 5 else HAIR_SHADOW)
        put(px, cx - 4, y0 + 3, HAIR_WHITE)
        put(px, cx - 4, y0 + 4, HAIR_SILVER)
        put(px, cx - 5, y0 + 3, OUTLINE)
        put(px, cx - 5, y0 + 4, OUTLINE)

        # Orelha no centro do perfil
        put(px, cx - 1, y0 + 5, SKIN_DEEP)
        put(px, cx - 1, y0 + 6, SKIN_SHADOW)

        # Sobrancelha branca e óculos em perfil
        put(px, cx + 2, y0 + 3, HAIR_WHITE)
        put(px, cx + 3, y0 + 3, HAIR_WHITE)
        put(px, cx, y0 + 4, GLASSES_RIM)
        put(px, cx + 1, y0 + 4, GLASSES_GOLD)
        put(px, cx + 2, y0 + 4, EYE_DARK if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 3, y0 + 4, GLASSES_LENS if not eyes_closed else GLASSES_GOLD)
        put(px, cx + 2, y0 + 5, GLASSES_GOLD)
        put(px, cx + 3, y0 + 5, SKIN_BASE)

        # Nariz saliente apontando p/ direita (→) + bigode branco de perfil!
        put(px, cx + 4, y0 + 5, SKIN_BASE)
        put(px, cx + 5, y0 + 5, OUTLINE)
        put(px, cx + 1, y0 + 6, BLUSH)
        put(px, cx + 2, y0 + 6, HAIR_WHITE)
        put(px, cx + 3, y0 + 6, HAIR_WHITE)
        put(px, cx + 4, y0 + 6, HAIR_WHITE)
        put(px, cx + 5, y0 + 6, OUTLINE)
        put(px, cx + 2, y0 + 7, HAIR_SILVER)
        put(px, cx + 3, y0 + 7, HAIR_SILVER)

    elif row == 3:  # NORTH-EAST (Diagonal 3/4 Costas-Direita ↗)
        # Ferradura de cabelo branco na nuca e lateral esquerda
        fill_rect(px, cx - 3, y0 + 1, cx + 3, y0 + 8, HAIR_SILVER)
        fill_rect(px, cx - 4, y0 + 2, cx - 1, y0 + 6, HAIR_WHITE)
        fill_rect(px, cx - 3, y0 + 7, cx + 1, y0 + 8, HAIR_SHADOW)
        put(px, cx - 5, y0 + 4, HAIR_WHITE)
        put(px, cx - 6, y0 + 4, OUTLINE)

        # Calvície no topo-direito da coroa
        fill_rect(px, cx - 1, y0 + 1, cx + 2, y0 + 2, SKIN_LIGHT)
        fill_rect(px, cx, y0 + 3, cx + 2, y0 + 3, SKIN_BASE)

        # Borda direita do rosto virada p/ cima-direita (↗): orelha + ponta do óculos dourado + ponta do bigode
        put(px, cx + 2, y0 + 4, SKIN_DEEP)
        put(px, cx + 2, y0 + 5, SKIN_BASE)
        put(px, cx + 3, y0 + 3, GLASSES_GOLD)
        put(px, cx + 3, y0 + 4, GLASSES_LENS)
        put(px, cx + 3, y0 + 5, SKIN_BASE)
        put(px, cx + 4, y0 + 5, HAIR_WHITE)  # Pontinha do bigode branco virado p/ ↗
        put(px, cx + 3, y0 + 6, SKIN_SHADOW)
        put(px, cx + 2, y0 + 6, SKIN_SHADOW)

    elif row == 4:  # NORTH (Costas ↑)
        # Cabelo grisalho/branco em ferradura (U) até a nuca
        fill_rect(px, cx - 3, y0 + 1, cx + 3, y0 + 8, HAIR_SILVER)
        fill_rect(px, cx - 4, y0 + 2, cx - 2, y0 + 7, HAIR_WHITE)
        fill_rect(px, cx + 2, y0 + 2, cx + 4, y0 + 7, HAIR_SILVER)
        fill_rect(px, cx - 3, y0 + 6, cx + 3, y0 + 7, HAIR_SILVER)
        fill_rect(px, cx - 3, y0 + 8, cx + 3, y0 + 8, HAIR_SHADOW)

        # Calvície circular no topo da coroa
        fill_rect(px, cx - 2, y0 + 1, cx + 2, y0 + 2, SKIN_LIGHT)
        fill_rect(px, cx - 2, y0 + 3, cx + 2, y0 + 4, SKIN_BASE)
        fill_rect(px, cx - 1, y0 + 5, cx + 1, y0 + 5, SKIN_SHADOW)

        # Orelhas nas laterais
        put(px, cx - 5, y0 + 4, SKIN_BASE)
        put(px, cx - 6, y0 + 4, OUTLINE)
        put(px, cx + 5, y0 + 4, SKIN_SHADOW)
        put(px, cx + 6, y0 + 4, OUTLINE)


def draw_leg_item(px, x_hip, x_foot, y_top, y_bottom, is_front_leg=True, shoe_dir=0):
    """
    Desenha uma perna articulada diagonalmente desde o quadril (x_hip, y_top)
    até o pé (x_foot, y_bottom), onde y_bottom=31 toca o chão!
    shoe_dir: 0 (frente/costas), +1 (aponta p/ direita), -1 (aponta p/ esquerda).
    """
    if y_bottom < y_top + 2:
        y_bottom = y_top + 2
    p_col = PANTS_BASE if is_front_leg else PANTS_SHADOW
    p_hi  = PANTS_LIGHT if is_front_leg else PANTS_BASE
    s_col = SHOE_BASE if is_front_leg else SHOE_DARK
    s_hi  = SHOE_LIGHT if is_front_leg else SHOE_BASE

    span = max(1, (y_bottom - 1) - y_top)

    # 1. Contorno da calça ao longo da diagonal quadril -> tornozelo
    for y in range(y_top, y_bottom):
        t = (y - y_top) / span
        cx_leg = round(x_hip + (x_foot - x_hip) * t)
        fill_rect(px, cx_leg - 1, y, cx_leg + 2, y, OUTLINE)
    # Contorno da sola em y_bottom
    fill_rect(px, x_foot - 1, y_bottom, x_foot + 2, y_bottom, OUTLINE)

    # 2. Interior da calça ao longo da diagonal
    for y in range(y_top, y_bottom - 1):
        t = (y - y_top) / span
        cx_leg = round(x_hip + (x_foot - x_hip) * t)
        fill_rect(px, cx_leg, y, cx_leg + 1, y, p_col)
        if y == y_top or is_front_leg:
            put(px, cx_leg, y, p_hi)

    # 3. Sapato nos 2 últimos pixels (y_bottom-1 e sola em y_bottom)
    sy = y_bottom - 1
    fill_rect(px, x_foot, sy, x_foot + 1, sy, s_col)
    put(px, x_foot, sy, s_hi)
    if shoe_dir > 0:
        put(px, x_foot + 2, sy, s_hi)
        put(px, x_foot + 3, sy, OUTLINE)
        put(px, x_foot + 2, y_bottom, OUTLINE)
    elif shoe_dir < 0:
        put(px, x_foot - 1, sy, s_hi)
        put(px, x_foot - 2, sy, OUTLINE)
        put(px, x_foot - 1, y_bottom, OUTLINE)


def draw_arm_limb(px, x_shoulder, y_shoulder, dx_hand, dy_hand, is_bright=True):
    """Desenha um braço articulado com manga do cardigã e mãozinha 2x2."""
    x_hand = x_shoulder + dx_hand
    y_hand = y_shoulder + dy_hand
    c_col = CARD_LIGHT if is_bright else CARD_SHADOW

    # Traça segmento do ombro até a mão
    steps = max(abs(dx_hand), abs(dy_hand), 1)
    for s in range(steps + 1):
        ax = round(x_shoulder + dx_hand * (s / steps))
        ay = round(y_shoulder + dy_hand * (s / steps))
        fill_rect(px, ax - 1, ay - 1, ax + 1, ay + 1, OUTLINE)
    for s in range(steps):
        ax = round(x_shoulder + dx_hand * (s / steps))
        ay = round(y_shoulder + dy_hand * (s / steps))
        put(px, ax, ay, c_col)
        put(px, ax, ay - 1, c_col)

    # Punho conhaque e mão 2x2
    put(px, x_hand, y_hand - 1, CARD_TRIM)
    put(px, x_hand, y_hand, SKIN_BASE if is_bright else SKIN_SHADOW)
    put(px, x_hand + (1 if dx_hand >= 0 else -1), y_hand, SKIN_LIGHT if is_bright else SKIN_BASE)
    return (x_hand, y_hand)


def draw_character_frame(
    px,
    row,
    cx=15,
    head_bob=0,
    torso_bob=0,
    head_tilt=0,
    eyes_closed=False,
    # Pose das pernas: (lx_off, ly_bottom, l_front), (rx_off, ry_bottom, r_front)
    left_leg=(0, 31, True),
    right_leg=(0, 31, False),
    # Pose dos braços: (dx, dy) do ombro até a mão
    left_arm=(-1, 5),
    right_arm=(1, 5),
    cane_tip=(24, 31),
    tap_highlight=False,
):
    """
    Renderiza um frame completo de 32x32 do Sr. Arthur ancorado até fy=31.
    """
    ty = 16 + torso_bob
    hy = 7 + head_bob

    # Posição do ombro direito (mão da bengala)
    r_sh_x = cx + (2 if row == 2 else 3)
    r_sh_y = ty + 2
    cane_hand_x = r_sh_x + right_arm[0]
    cane_hand_y = r_sh_y + right_arm[1]

    # 0. Se a bengala está atrás do corpo (row 3 ne, row 4 n), desenha primeiro
    if row in (3, 4) and cane_tip is not None:
        draw_cane(px, cane_hand_x, cane_hand_y, cane_tip[0], cane_tip[1], behind_body=True, tap_highlight=tap_highlight)

    # 1. PERNAS (sempre começando no quadril em ty+8=24 e indo até ly_bottom/ry_bottom, com pé firme em 31!)
    leg_top = ty + 8
    shoe_dir = 1 if row in (1, 2, 3) else 0

    if row in (0, 4):  # South (↓) & North (↑)
        lx, l_bot, l_fr = left_leg
        rx, r_bot, r_fr = right_leg
        hip_lx, hip_rx = cx - 3, cx + 1
        # Desenha primeiro a perna mais ao fundo, depois a da frente
        if l_fr:
            draw_leg_item(px, hip_rx, hip_rx + rx, leg_top, r_bot, is_front_leg=r_fr, shoe_dir=0)
            draw_leg_item(px, hip_lx, hip_lx + lx, leg_top, l_bot, is_front_leg=l_fr, shoe_dir=0)
        else:
            draw_leg_item(px, hip_lx, hip_lx + lx, leg_top, l_bot, is_front_leg=l_fr, shoe_dir=0)
            draw_leg_item(px, hip_rx, hip_rx + rx, leg_top, r_bot, is_front_leg=r_fr, shoe_dir=0)

    elif row in (1, 2, 3):  # South-East (↘), East (→) & North-East (↗)
        lx, l_bot, l_fr = left_leg
        rx, r_bot, r_fr = right_leg
        if lx == 0 and rx == 0:
            hip_lx = (cx - 2) if row != 2 else (cx - 1)
            hip_rx = (cx + 1) if row != 2 else cx
            foot_lx, foot_rx = hip_lx, hip_rx
        else:
            hip_lx, hip_rx = cx - 1, cx
            foot_lx = cx - 1 + lx
            foot_rx = cx + rx
        if l_fr:
            draw_leg_item(px, hip_rx, foot_rx, leg_top, r_bot, is_front_leg=False, shoe_dir=shoe_dir)
            draw_leg_item(px, hip_lx, foot_lx, leg_top, l_bot, is_front_leg=True, shoe_dir=shoe_dir)
        else:
            draw_leg_item(px, hip_lx, foot_lx, leg_top, l_bot, is_front_leg=False, shoe_dir=shoe_dir)
            draw_leg_item(px, hip_rx, foot_rx, leg_top, r_bot, is_front_leg=True, shoe_dir=shoe_dir)

    # 2. BRAÇO DE TRÁS (quando em perfil ou diagonal)
    if row in (1, 2, 3) and left_arm is not None:
        l_sh_x = cx - (2 if row == 2 else 3)
        l_sh_y = ty + 2
        draw_arm_limb(px, l_sh_x, l_sh_y, left_arm[0], left_arm[1], is_bright=True)

    # 3. TRONCO (Cardigã Verde-Sálvia + Gola Creme + Gravatinha Bordô + Lapela Conhaque + Cinto)
    if row == 0:  # South (Frente ↓)
        fill_rect(px, cx - 3, ty, cx + 3, ty, OUTLINE)
        fill_rect(px, cx - 4, ty + 1, cx + 4, ty + 8, OUTLINE)
        fill_rect(px, cx - 3, ty + 1, cx + 3, ty + 7, CARD_BASE)
        fill_rect(px, cx - 3, ty + 1, cx - 2, ty + 7, CARD_LIGHT)
        fill_rect(px, cx + 2, ty + 1, cx + 3, ty + 7, CARD_SHADOW)
        # Cinto de couro na base da abertura
        put(px, cx - 1, ty + 7, BELT_LEATHER)
        put(px, cx, ty + 7, BUTTON_GOLD)
        put(px, cx + 1, ty + 7, BELT_LEATHER)
        # Gola Creme + Gravatinha Borboleta Bordô (#C43640)
        put(px, cx - 1, ty + 1, SHIRT_CREAM)
        put(px, cx, ty + 1, SHIRT_CREAM)
        put(px, cx + 1, ty + 1, SHIRT_CREAM)
        put(px, cx - 1, ty + 2, BOWTIE_RED)
        put(px, cx, ty + 2, BOWTIE_DARK)
        put(px, cx + 1, ty + 2, BOWTIE_RED)
        put(px, cx, ty + 3, SHIRT_CREAM)
        # Lapela conhaque e botões dourados
        put(px, cx - 2, ty + 2, CARD_TRIM)
        put(px, cx + 2, ty + 2, CARD_TRIM)
        put(px, cx - 1, ty + 3, CARD_TRIM)
        put(px, cx + 1, ty + 3, CARD_TRIM)
        put(px, cx, ty + 4, BUTTON_GOLD)
        put(px, cx, ty + 5, CARD_TRIM)
        put(px, cx, ty + 6, BUTTON_GOLD)

    elif row == 1:  # South-East (Diagonal ↘)
        fill_rect(px, cx - 3, ty, cx + 3, ty, OUTLINE)
        fill_rect(px, cx - 4, ty + 1, cx + 4, ty + 8, OUTLINE)
        fill_rect(px, cx - 3, ty + 1, cx + 3, ty + 7, CARD_BASE)
        fill_rect(px, cx - 3, ty + 1, cx - 1, ty + 7, CARD_LIGHT)
        fill_rect(px, cx + 2, ty + 1, cx + 3, ty + 7, CARD_SHADOW)
        # Gola Creme + Gravatinha Bordô deslocadas para a direita (cx+1..cx+2)
        put(px, cx + 1, ty + 1, SHIRT_CREAM)
        put(px, cx + 2, ty + 1, SHIRT_CREAM)
        put(px, cx + 1, ty + 2, BOWTIE_RED)
        put(px, cx + 2, ty + 2, BOWTIE_DARK)
        put(px, cx + 3, ty + 2, BOWTIE_RED)
        put(px, cx, ty + 2, CARD_TRIM)
        put(px, cx + 1, ty + 3, CARD_TRIM)
        put(px, cx + 2, ty + 3, SHIRT_CREAM)
        put(px, cx + 2, ty + 4, BUTTON_GOLD)
        put(px, cx + 2, ty + 5, CARD_TRIM)
        put(px, cx + 2, ty + 6, BUTTON_GOLD)
        put(px, cx + 1, ty + 7, BELT_LEATHER)
        put(px, cx + 2, ty + 7, BUTTON_GOLD)

    elif row == 2:  # East (Perfil Direito →)
        fill_rect(px, cx - 2, ty, cx + 2, ty, OUTLINE)
        fill_rect(px, cx - 3, ty + 1, cx + 3, ty + 8, OUTLINE)
        fill_rect(px, cx - 2, ty + 1, cx + 2, ty + 7, CARD_BASE)
        fill_rect(px, cx - 2, ty + 1, cx - 1, ty + 7, CARD_LIGHT)
        fill_rect(px, cx + 1, ty + 1, cx + 2, ty + 7, CARD_SHADOW)
        # Detalhe da gola, gravatinha bordô e botões na borda frontal direita
        put(px, cx + 2, ty + 1, SHIRT_CREAM)
        put(px, cx + 2, ty + 2, BOWTIE_RED)
        put(px, cx + 1, ty + 2, CARD_TRIM)
        put(px, cx + 2, ty + 4, BUTTON_GOLD)
        put(px, cx + 2, ty + 6, BUTTON_GOLD)
        fill_rect(px, cx - 2, ty + 7, cx + 1, ty + 7, CARD_TRIM)

    elif row == 3:  # North-East (Diagonal Costas-Direita ↗)
        fill_rect(px, cx - 3, ty, cx + 3, ty, OUTLINE)
        fill_rect(px, cx - 4, ty + 1, cx + 4, ty + 8, OUTLINE)
        fill_rect(px, cx - 3, ty + 1, cx + 3, ty + 7, CARD_BASE)
        fill_rect(px, cx - 3, ty + 1, cx - 2, ty + 7, CARD_LIGHT)
        fill_rect(px, cx + 1, ty + 1, cx + 3, ty + 7, CARD_SHADOW)
        # Gola conhaque traseira e costura dorsal
        fill_rect(px, cx - 2, ty + 1, cx + 2, ty + 1, CARD_TRIM)
        for dy in range(2, 7):
            put(px, cx - 1, ty + dy, CARD_SHADOW)
        fill_rect(px, cx - 3, ty + 7, cx + 3, ty + 7, CARD_TRIM)

    elif row == 4:  # North (Costas ↑)
        fill_rect(px, cx - 3, ty, cx + 3, ty, OUTLINE)
        fill_rect(px, cx - 4, ty + 1, cx + 4, ty + 8, OUTLINE)
        fill_rect(px, cx - 3, ty + 1, cx + 3, ty + 7, CARD_BASE)
        fill_rect(px, cx - 3, ty + 1, cx - 2, ty + 7, CARD_LIGHT)
        fill_rect(px, cx + 2, ty + 1, cx + 3, ty + 7, CARD_SHADOW)
        fill_rect(px, cx - 2, ty + 1, cx + 2, ty + 1, CARD_TRIM)
        for dy in range(2, 7):
            put(px, cx, ty + dy, CARD_SHADOW)
        fill_rect(px, cx - 3, ty + 7, cx + 3, ty + 7, CARD_TRIM)

    # 4. BRAÇOS VISÍVEIS À FRENTE DO TRONCO
    if row in (0, 4) and left_arm is not None:
        draw_arm_limb(px, cx - 4, ty + 2, left_arm[0], left_arm[1], is_bright=True)

    # Braço da bengala (direito)
    hx, hy_arm = draw_arm_limb(
        px,
        cx + (1 if row == 2 else 4),
        ty + 2,
        right_arm[0],
        right_arm[1],
        is_bright=(row == 2)
    )

    # 5. CABEÇA (desenhada sobre o colarinho para encaixe natural)
    draw_head(px, row, cx=cx, top_y=hy, eyes_closed=eyes_closed, head_tilt=head_tilt)

    # Se left_arm é a pose de escutar na orelha em perfil Leste, destaca a mão perto da orelha
    if row == 2 and left_arm == (0, -3):
        put(px, cx - 1, hy + 5, SKIN_LIGHT)
        put(px, cx, hy + 5, SKIN_BASE)

    # 6. BENGALA À FRENTE DO CORPO (rows 0, 1, 2)
    if row in (0, 1, 2) and cane_tip is not None:
        draw_cane(px, hx, hy_arm, cane_tip[0], cane_tip[1], behind_body=False, tap_highlight=tap_highlight)


def default_cane_tip(row, phase=0):
    """Ponteira da bengala calibrada para cada direção e fase (-1=esq, 0=neutro, +1=dir)."""
    if row == 0:   # s (↓)
        return (17, 31) if phase == -1 else ((26, 31) if phase == 1 else (23, 31))
    elif row == 1: # se (↘)
        return (20, 31) if phase == -1 else ((28, 31) if phase == 1 else (25, 31))
    elif row == 2: # e (→)
        return (21, 31) if phase == -1 else ((29, 30) if phase == 1 else (26, 31))
    elif row == 3: # ne (↗)
        return (20, 29) if phase == -1 else ((27, 28) if phase == 1 else (24, 29))
    else:          # n (↑)
        return (18, 28) if phase == -1 else ((25, 28) if phase == 1 else (23, 28))


def render_idle_sheet():
    """
    Idle (4 frames):
    Pés 100% plantados em fy=31 em todos os frames (zero flutuação!),
    com suave respiração do tronco e cabeça nos frames 1 e 2.
    """
    cols, rows = 4, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()
            breath = 1 if c in (1, 2) else 0
            # Em NE (r=3), pé de trás em 31 e pé da frente em 30 (perspectiva isométrica firme no chão)
            r_bot = 30 if r == 3 else 31
            draw_character_frame(
                px, r, cx=15,
                head_bob=breath,
                torso_bob=breath,
                left_leg=(0, 31, True),
                right_leg=(0, r_bot, False),
                left_arm=(-1, 4),
                right_arm=(1, 4),
                cane_tip=default_cane_tip(r, 0),
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Idle-Sheet.png"))
    print("Generated 16x32 Idle-Sheet.png")


def render_walk_sheet():
    """
    Walk (4 frames @ 10fps):
    Ciclo de caminhada autêntico, expressivo e 100% ancorado no chão (fy=31):
    - Frame 0 (Passo Esquerdo): Perna esquerda avança e planta em fy=31; perna direita
      impulsiona atrás/levanta (fy=28 em s/n, ou recua dx=-2 em se/e/ne); braço direito avança
      com a bengala tocando à direita; braço esquerdo balança para trás.
    - Frame 1 (Passagem): Pé de apoio firme em fy=31; joelho oposto levanta (fy=28);
      cabeça e tronco sobem 1px (-1); bengala desliza no ar.
    - Frame 2 (Passo Direito): Perna direita avança e planta em fy=31; perna esquerda
      recolhe/levanta (fy=28 em s/n, ou recua dx=-3 em se/e/ne); braço esquerdo balança
      para a frente; bengala toca à esquerda (Hoover 2-point touch).
    - Frame 3 (Passagem): Pé de apoio firme em fy=31; joelho esquerdo passa levantado (fy=28);
      cabeça e tronco sobem 1px (-1).
    """
    cols, rows = 4, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()

            if r in (0, 4):  # South (↓) & North (↑) — Alternância profunda de passo e balanço de braços
                if c == 0:
                    # Perna esquerda planta na frente (31), perna direita recolhe no ar (28)!
                    l_leg = (0, 31, True)
                    r_leg = (0, 28, False)
                    l_arm = (-1, 3)   # braço esq recua
                    r_arm = (1, 5)    # braço dir avança
                    h_bob, t_bob = 0, 0
                    tilt = -1 if r == 0 else 0
                    tip = default_cane_tip(r, 1)
                elif c == 1:
                    # Passagem: pé esquerdo ancorado em 31, direito passando em 29
                    l_leg = (0, 31, True)
                    r_leg = (0, 29, False)
                    l_arm = (-1, 4)
                    r_arm = (1, 4)
                    h_bob, t_bob = -1, -1
                    tilt = 0
                    tx, ty = default_cane_tip(r, 0)
                    tip = (tx, ty - 1)
                elif c == 2:
                    # Perna direita planta na frente (31), perna esquerda recolhe no ar (28)!
                    l_leg = (0, 28, False)
                    r_leg = (0, 31, True)
                    l_arm = (-2, 5)   # braço esq avança
                    r_arm = (0, 3)    # braço dir recua
                    h_bob, t_bob = 0, 0
                    tilt = 1 if r == 0 else 0
                    tip = default_cane_tip(r, -1)
                else:
                    # Passagem: pé direito ancorado em 31, esquerdo passando em 29
                    l_leg = (0, 29, False)
                    r_leg = (0, 31, True)
                    l_arm = (-1, 4)
                    r_arm = (1, 4)
                    h_bob, t_bob = -1, -1
                    tilt = 0
                    tx, ty = default_cane_tip(r, 0)
                    tip = (tx, ty - 1)
            else:  # SE (↘), E (→), NE (↗) — Passada em tesoura ampla (/\ de 6px)
                if c == 0:
                    # Tesoura 1: perna de trás recua (-2, 31), perna da frente avança (+2, 30..31)
                    l_leg = (-2, 31, False)
                    r_leg = (2, 31 if r != 3 else 29, True)
                    l_arm = (-3, 4)   # braço de trás balança p/ trás
                    r_arm = (2, 4)    # braço da frente avança
                    h_bob, t_bob = 0, 0
                    tilt = 0
                    tip = default_cane_tip(r, 1)
                elif c == 1:
                    # Passagem 1: perna de apoio firme em 31, outra perna dobra o joelho (28)
                    l_leg = (1, 28, True)
                    r_leg = (0, 31, False)
                    l_arm = (-1, 4)
                    r_arm = (1, 4)
                    h_bob, t_bob = -1, -1
                    tilt = 0
                    tx, ty = default_cane_tip(r, 0)
                    tip = (tx, ty - 1)
                elif c == 2:
                    # Tesoura 2: perna esquerda avança (+3, 31), perna direita recua (-2, 30..31)
                    l_leg = (3, 31, True)
                    r_leg = (-2, 30 if r != 3 else 29, False)
                    l_arm = (2, 4)
                    r_arm = (-1, 4)
                    h_bob, t_bob = 0, 0
                    tilt = 0
                    tip = default_cane_tip(r, -1)
                else:
                    # Passagem 2: perna esquerda firme em 31, perna direita dobra o joelho (28)
                    l_leg = (0, 31, True)
                    r_leg = (1, 28, False)
                    l_arm = (-1, 4)
                    r_arm = (1, 4)
                    h_bob, t_bob = -1, -1
                    tilt = 0
                    tx, ty = default_cane_tip(r, 0)
                    tip = (tx, ty - 1)

            draw_character_frame(
                px, r, cx=15,
                head_bob=h_bob,
                torso_bob=t_bob,
                head_tilt=tilt,
                left_leg=l_leg,
                right_leg=r_leg,
                left_arm=l_arm,
                right_arm=r_arm,
                cane_tip=tip,
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Walk-Sheet.png"))
    print("Generated 16x32 Walk-Sheet.png")


def render_run_sheet():
    """
    Run (6 frames @ 14fps):
    Corrida / trote dinâmico com passadas amplas, joelhos elevados e braços bombeando,
    mantendo o pé de apoio tocando fy=31 nos frames de contato.
    """
    cols, rows = 6, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        lean = 1 if r in (1, 2, 3) else 0
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()

            if r in (0, 4):
                if c == 0:
                    l_leg, r_leg = (0, 31, True), (0, 27, False)
                    l_arm, r_arm = (-2, 2), (2, 5)
                    bob = 0
                    tip = default_cane_tip(r, 1)
                elif c == 1:
                    l_leg, r_leg = (0, 30, True), (0, 27, False)
                    l_arm, r_arm = (-2, 3), (2, 4)
                    bob = -1
                    tip = default_cane_tip(r, 1)
                elif c == 2:
                    l_leg, r_leg = (0, 31, True), (0, 29, False)
                    l_arm, r_arm = (-1, 4), (1, 4)
                    bob = 0
                    tip = default_cane_tip(r, 0)
                elif c == 3:
                    l_leg, r_leg = (0, 27, False), (0, 31, True)
                    l_arm, r_arm = (-2, 5), (1, 2)
                    bob = 0
                    tip = default_cane_tip(r, -1)
                elif c == 4:
                    l_leg, r_leg = (0, 27, False), (0, 30, True)
                    l_arm, r_arm = (-2, 4), (1, 3)
                    bob = -1
                    tip = default_cane_tip(r, -1)
                else:
                    l_leg, r_leg = (0, 29, False), (0, 31, True)
                    l_arm, r_arm = (-1, 4), (1, 4)
                    bob = 0
                    tip = default_cane_tip(r, 0)
            else:
                if c == 0:
                    l_leg, r_leg = (-3, 31, False), (3, 30, True)
                    l_arm, r_arm = (-3, 3), (3, 4)
                    bob = 0
                    tip = default_cane_tip(r, 1)
                elif c == 1:
                    l_leg, r_leg = (-2, 28, False), (3, 31, True)
                    l_arm, r_arm = (-2, 3), (2, 3)
                    bob = -1
                    tip = default_cane_tip(r, 1)
                elif c == 2:
                    l_leg, r_leg = (1, 28, True), (0, 31, False)
                    l_arm, r_arm = (-1, 4), (1, 4)
                    bob = 0
                    tip = default_cane_tip(r, 0)
                elif c == 3:
                    l_leg, r_leg = (3, 30, True), (-3, 31, False)
                    l_arm, r_arm = (3, 3), (-2, 4)
                    bob = 0
                    tip = default_cane_tip(r, -1)
                elif c == 4:
                    l_leg, r_leg = (3, 31, True), (-2, 28, False)
                    l_arm, r_arm = (2, 3), (-1, 3)
                    bob = -1
                    tip = default_cane_tip(r, -1)
                else:
                    l_leg, r_leg = (0, 31, True), (1, 28, False)
                    l_arm, r_arm = (-1, 4), (1, 4)
                    bob = 0
                    tip = default_cane_tip(r, 0)

            draw_character_frame(
                px, r, cx=15,
                head_bob=bob,
                torso_bob=bob,
                head_tilt=lean,
                left_leg=l_leg,
                right_leg=r_leg,
                left_arm=l_arm,
                right_arm=r_arm,
                cane_tip=tip,
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Run-Sheet.png"))
    print("Generated 16x32 Run-Sheet.png")


def render_jump_sheet():
    """
    Jump (5 frames):
    0: Preparação plantado em 31
    1: Impulso ascendente
    2: Ápice no ar (pernas flexionadas)
    3: Descida
    4: Pouso firme em 31
    """
    cols, rows = 5, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    bobs  = [1, -2, -3, -1, 1]
    l_bots = [31, 29, 28, 29, 31]
    for r in range(rows):
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()
            bob = bobs[c]
            bot = l_bots[c]
            tx, ty = default_cane_tip(r, 0)
            tip = (tx, min(31, bot))
            in_air = c in (1, 2, 3)
            draw_character_frame(
                px, r, cx=15,
                head_bob=bob,
                torso_bob=bob,
                left_leg=(-1 if in_air and r in (1, 2, 3) else 0, bot, True),
                right_leg=(1 if in_air and r in (1, 2, 3) else 0, bot - (1 if r == 3 and not in_air else 0), False),
                left_arm=(-2, 1) if in_air else (-1, 4),
                right_arm=(2, 2) if in_air else (1, 4),
                cane_tip=tip,
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Jump-Sheet.png"))
    print("Generated 16x32 Jump-Sheet.png")


def render_interact_sheet():
    """
    Interact / Escutar / Pegar (4 frames):
    Pés 100% plantados em fy=31; mão esquerda sobe até a orelha em concha nos frames 1 e 2
    com olhinhos fechados em foco musical.
    """
    cols, rows = 4, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()
            active = c in (1, 2)
            r_bot = 30 if r == 3 else 31
            tx, ty = default_cane_tip(r, 0)
            draw_character_frame(
                px, r, cx=15,
                head_bob=0,
                torso_bob=0,
                head_tilt=-1 if (active and r == 0) else 0,
                eyes_closed=active,
                left_leg=(0, 31, True),
                right_leg=(0, r_bot, False),
                left_arm=(-1, -3) if active else (-1, 2),
                right_arm=(0, 4),
                cane_tip=(tx - 1, ty),
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Interact-Sheet.png"))
    print("Generated 16x32 Interact-Sheet.png")


def render_attack_sheet():
    """
    Attack / Tatear com a Bengala (7 frames):
    Pés 100% plantados em fy=31; braço direito executa uma varredura ampla em arco
    tateando o chão com brilhos acústicos nos toques laterais e central.
    """
    cols, rows = 7, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        if r == 0:   # s (↓)
            sweep = [(23, 29), (28, 31), (24, 31), (19, 31), (13, 31), (19, 31), (23, 31)]
            rarms = [(1, 3),   (3, 4),   (2, 4),   (0, 4),   (-2, 4),  (0, 4),   (1, 4)]
        elif r == 1: # se (↘)
            sweep = [(24, 29), (29, 31), (26, 31), (22, 31), (17, 31), (22, 31), (25, 31)]
            rarms = [(1, 3),   (3, 4),   (2, 4),   (1, 4),   (-1, 4),  (1, 4),   (1, 4)]
        elif r == 2: # e (→)
            sweep = [(25, 28), (29, 29), (28, 31), (25, 31), (21, 31), (25, 31), (26, 31)]
            rarms = [(1, 3),   (3, 3),   (3, 4),   (2, 4),   (0, 4),   (2, 4),   (1, 4)]
        elif r == 3: # ne (↗)
            sweep = [(23, 27), (27, 27), (26, 29), (23, 29), (19, 29), (23, 29), (24, 29)]
            rarms = [(1, 3),   (3, 3),   (2, 4),   (1, 4),   (-1, 4),  (1, 4),   (1, 4)]
        else:        # n (↑)
            sweep = [(22, 27), (26, 27), (23, 28), (19, 28), (14, 28), (19, 28), (23, 28)]
            rarms = [(1, 3),   (2, 3),   (1, 4),   (0, 4),   (-2, 4),  (0, 4),   (1, 4)]

        r_bot = 30 if r == 3 else 31
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()
            draw_character_frame(
                px, r, cx=15,
                head_bob=0,
                torso_bob=0,
                head_tilt=1 if c in (1, 2) else (-1 if c == 4 else 0),
                left_leg=(0, 31, True),
                right_leg=(0, r_bot, False),
                left_arm=(-1, 4),
                right_arm=rarms[c],
                cane_tip=sweep[c],
                tap_highlight=c in (1, 3, 4),
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Attack-Sheet.png"))
    print("Generated 16x32 Attack-Sheet.png")


def render_rotate_sheet():
    cols, rows = 4, 5
    sheet = Image.new("RGBA", (cols * 32, rows * 32), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            px = frame.load()
            sub_r = (r + c) % 5
            r_bot = 30 if sub_r == 3 else 31
            draw_character_frame(
                px, sub_r, cx=15,
                left_leg=(0, 31, True),
                right_leg=(0, r_bot, False),
                cane_tip=default_cane_tip(sub_r, 0),
            )
            sheet.paste(frame, (c * 32, r * 32))
    sheet.save(os.path.join(OUT_DIR, "16x32 Rotate-Sheet.png"))
    print("Generated 16x32 Rotate-Sheet.png")


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    render_idle_sheet()
    render_walk_sheet()
    render_run_sheet()
    render_jump_sheet()
    render_interact_sheet()
    render_attack_sheet()
    render_rotate_sheet()
    print("\nAll 7 elderly character v2 sprite sheets generated successfully!")

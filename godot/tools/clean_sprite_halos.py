import os
from PIL import Image, ImageDraw

BASE_SPRITES = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites"
OUTLINE = (38, 24, 16, 255)


def luminance(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def is_neutral_halo(r, g, b, a):
    if a == 0:
        return False
    lum = luminance(r, g, b)
    sat = max(r, g, b) - min(r, g, b)
    return lum >= 170 and sat <= 26


def is_dark(r, g, b, a):
    if a == 0:
        return False
    return luminance(r, g, b) < 115


def clean_sprite_halo(filepath):
    img = Image.open(filepath).convert("RGBA")
    w, h = img.size
    px = img.load()

    # 1. Normaliza alfa binário sem criar dentes na silhueta
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (0, 0, 0, 0) if a < 128 else (r, g, b, 255)

    # 2. Calcula distância Manhattan até o fundo transparente
    dist = [[999] * w for _ in range(h)]
    q = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                dist[y][x] = 0
                q.append((x, y))
    head = 0
    while head < len(q):
        cx, cy = q[head]
        head += 1
        d_next = dist[cy][cx] + 1
        if d_next > 4:
            continue
        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
            if 0 <= nx < w and 0 <= ny < h and dist[ny][nx] > d_next:
                dist[ny][nx] = d_next
                q.append((nx, ny))

    # 3. Qualquer pixel na borda externa (dist == 1) que seja escuro ou halo neutro
    # recebe o contorno marrom-nogueira escuro (#261810), mantendo 100% da silhueta suave.
    snap = img.copy()
    spx = snap.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = spx[x, y]
            if a == 0:
                continue
            if dist[y][x] == 1 and (luminance(r, g, b) < 125 or is_neutral_halo(r, g, b, a)):
                px[x, y] = OUTLINE

    # 4. Qualquer pixel de halo branco/cinza neutro preso na casca externa (dist == 2 ou 3)
    # entre o contorno externo (dist == 1) e um pixel escuro interno é preenchido com
    # a cor interna adjacente (ou OUTLINE), eliminando 100% do anel branco sem serrilhar!
    snap = img.copy()
    spx = snap.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = spx[x, y]
            if a == 0 or dist[y][x] not in (2, 3):
                continue
            if not is_neutral_halo(r, g, b, a):
                continue
            # Verifica se há pixel escuro mais para dentro (dist >= dist[y][x])
            has_inner_dark = False
            fill_candidates = []
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and spx[nx, ny][3] > 0:
                        if dist[ny][nx] >= dist[y][x] and is_dark(*spx[nx, ny]):
                            has_inner_dark = True
                        if dist[ny][nx] > dist[y][x] and not is_neutral_halo(*spx[nx, ny]) and not is_dark(*spx[nx, ny]):
                            fill_candidates.append(spx[nx, ny])
            if has_inner_dark:
                if dist[y][x] == 2 or not fill_candidates:
                    px[x, y] = OUTLINE
                else:
                    avg_r = sum(c[0] for c in fill_candidates) // len(fill_candidates)
                    avg_g = sum(c[1] for c in fill_candidates) // len(fill_candidates)
                    avg_b = sum(c[2] for c in fill_candidates) // len(fill_candidates)
                    px[x, y] = (avg_r, avg_g, avg_b, 255)

    img.save(filepath)
    print(f"Cleaned sprite silhouette: {os.path.basename(filepath)}")


def generate_seamless_quarto_wall():
    """Gera wall_wood_quarto.png (64x72) com lambris e papel de parede contínuos sem linhas de caixote."""
    w, h = 64, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Topo da parede (losango 64x32 em y=0..32) — acabamento de madeira nobre contínuo
    d.polygon([(32, 0), (64, 16), (32, 32), (0, 16)], fill=(92, 62, 42))
    d.polygon([(32, 2), (60, 16), (32, 30), (4, 16)], fill=(108, 74, 50))
    d.line([(0, 16), (32, 32)], fill=(128, 90, 62), width=1)
    d.line([(32, 32), (63, 16)], fill=(76, 50, 34), width=1)
    d.line([(32, 0), (63, 16)], fill=OUTLINE, width=1)
    d.line([(0, 16), (32, 0)], fill=OUTLINE, width=1)

    # Face Esquerda (Sul-Oeste — iluminada)
    d.polygon([(0, 16), (32, 32), (32, 50), (0, 34)], fill=(154, 170, 146))
    for x_off in (6, 14, 22, 28):
        y_top = 16 + x_off // 2
        d.line([(x_off, y_top + 1), (x_off, y_top + 16)], fill=(168, 184, 160), width=1)

    # Moldura divisória (Chair rail)
    d.polygon([(0, 34), (32, 50), (32, 53), (0, 37)], fill=(166, 112, 64))
    d.line([(0, 34), (32, 50)], fill=(196, 138, 84), width=1)

    # Lambris de carvalho
    d.polygon([(0, 37), (32, 53), (32, 72), (0, 56)], fill=(124, 78, 42))
    # Rodapé escuro contínuo
    d.polygon([(0, 52), (32, 68), (32, 72), (0, 56)], fill=(78, 46, 24))
    d.line([(0, 56), (32, 72)], fill=OUTLINE, width=1)

    # Face Direita (Sul-Leste — em sombra suave)
    d.polygon([(32, 32), (64, 16), (64, 34), (32, 50)], fill=(124, 140, 118))
    for x_off in (38, 46, 54, 60):
        y_top = 32 - (x_off - 32) // 2
        d.line([(x_off, y_top + 1), (x_off, y_top + 16)], fill=(136, 152, 130), width=1)

    # Moldura divisória direita
    d.polygon([(32, 50), (64, 34), (64, 37), (32, 53)], fill=(132, 86, 48))
    d.line([(32, 50), (64, 34)], fill=(154, 102, 58), width=1)

    # Lambris em sombra
    d.polygon([(32, 53), (64, 37), (64, 56), (32, 72)], fill=(96, 58, 30))
    # Rodapé direito
    d.polygon([(32, 68), (64, 52), (64, 56), (32, 72)], fill=(58, 34, 18))
    d.line([(32, 72), (63, 56)], fill=OUTLINE, width=1)

    # Quina central suave
    d.line([(32, 32), (32, 71)], fill=(82, 52, 30), width=1)

    out_path = os.path.join(BASE_SPRITES, "tilemap", "wall_wood_quarto.png")
    img.save(out_path)
    print("Generated seamless wall_wood_quarto.png")


if __name__ == "__main__":
    for sub in ("furniture", "obstacles", "mobs"):
        folder = os.path.join(BASE_SPRITES, sub)
        if os.path.exists(folder):
            for fname in sorted(os.listdir(folder)):
                if fname.endswith(".png"):
                    clean_sprite_halo(os.path.join(folder, fname))

    for radio_name in ("radio_vintage_48x48.png", "radio_vintage_32x32.png"):
        rpath = os.path.join(BASE_SPRITES, "props", radio_name)
        if os.path.exists(rpath):
            clean_sprite_halo(rpath)

    generate_seamless_quarto_wall()

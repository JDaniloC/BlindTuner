import os
from PIL import Image, ImageDraw

OUTPUT_DIR = r"c:\Users\danil\Documents\code\BlindTuner\godot\assets\sprites\props"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def create_iron_gate():
    # 48x64 Portão de ferro forjado com trinco dourado
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Pilares de tijolo/pedra laterais
    d.rectangle([2, 16, 8, 62], fill=(70, 65, 60), outline=(40, 35, 30))
    d.rectangle([40, 16, 46, 62], fill=(70, 65, 60), outline=(40, 35, 30))
    # Capitéis dos pilares
    d.rectangle([1, 14, 9, 16], fill=(90, 85, 80), outline=(40, 35, 30))
    d.rectangle([39, 14, 47, 16], fill=(90, 85, 80), outline=(40, 35, 30))
    # Grade de ferro arqueada
    d.arc([8, 10, 40, 40], start=180, end=360, fill=(35, 38, 42), width=2)
    d.rectangle([9, 24, 39, 62], outline=(35, 38, 42), width=2)
    # Barras verticais
    for x in range(13, 37, 4):
        d.line([x, 22, x, 62], fill=(50, 54, 60), width=2)
        # Pontas de lança
        d.polygon([(x-1, 22), (x+1, 22), (x, 18)], fill=(130, 135, 140))
    # Trinco dourado
    d.rectangle([22, 38, 28, 43], fill=(220, 180, 50), outline=(140, 100, 20))
    d.ellipse([23, 40, 25, 42], fill=(60, 40, 10))
    img.save(os.path.join(OUTPUT_DIR, "iron_gate_48x64.png"))

def create_bakery_counter():
    # 64x48 Balcão da padaria com sino dourado e pães
    img = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Estrutura de madeira do balcão
    d.rectangle([6, 18, 58, 46], fill=(145, 95, 55), outline=(90, 55, 30))
    # Tampo de mármore/madeira clara
    d.rectangle([4, 14, 60, 19], fill=(215, 185, 145), outline=(130, 95, 60))
    # Painéis de madeira chanfrados
    d.rectangle([10, 24, 28, 42], fill=(120, 75, 40), outline=(80, 45, 20))
    d.rectangle([36, 24, 54, 42], fill=(120, 75, 40), outline=(80, 45, 20))
    # Cesta de pães à esquerda
    d.ellipse([10, 10, 26, 16], fill=(195, 145, 85), outline=(130, 90, 45))
    d.ellipse([12, 8, 18, 13], fill=(225, 175, 95), outline=(160, 110, 50)) # Pão francês
    d.ellipse([18, 8, 24, 13], fill=(215, 165, 85), outline=(150, 100, 40))
    # Sino de balcão dourado à direita (Farol sonoro)
    d.ellipse([44, 11, 52, 15], fill=(240, 200, 60), outline=(160, 120, 20)) # Campânula
    d.rectangle([47, 9, 49, 11], fill=(255, 225, 100)) # Botão do sino
    d.rectangle([43, 14, 53, 16], fill=(180, 140, 30)) # Base
    img.save(os.path.join(OUTPUT_DIR, "bakery_counter_64x48.png"))

def create_fountain_stone():
    # 64x64 Chafariz de pedra com água
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Bacia inferior de pedra
    d.ellipse([6, 36, 58, 62], fill=(140, 145, 150), outline=(90, 95, 100), width=2)
    # Água azul na bacia
    d.ellipse([10, 40, 54, 58], fill=(70, 160, 220), outline=(50, 130, 190))
    d.ellipse([14, 44, 50, 54], fill=(100, 190, 240)) # Brilho da água
    # Pedestal central
    d.rectangle([28, 20, 36, 44], fill=(160, 165, 170), outline=(100, 105, 110))
    # Bacia superior menor
    d.ellipse([20, 16, 44, 26], fill=(150, 155, 160), outline=(100, 105, 110))
    d.ellipse([22, 18, 42, 24], fill=(80, 175, 235))
    # Bico jorrador e jatos de água
    d.rectangle([30, 8, 34, 17], fill=(170, 175, 180), outline=(110, 115, 120))
    d.line([32, 6, 26, 18], fill=(180, 230, 255), width=2)
    d.line([32, 6, 38, 18], fill=(180, 230, 255), width=2)
    d.line([22, 22, 16, 42], fill=(160, 220, 255), width=1)
    d.line([42, 22, 48, 42], fill=(160, 220, 255), width=1)
    img.save(os.path.join(OUTPUT_DIR, "fountain_stone_64x64.png"))

def create_church_portal():
    # 64x80 Portal da Matriz com sino de bronze
    img = Image.new("RGBA", (64, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Fachada em pedra
    d.rectangle([8, 16, 56, 78], fill=(135, 130, 125), outline=(85, 80, 75))
    # Arco ogival superior
    d.polygon([(8, 16), (32, 2), (56, 16)], fill=(150, 145, 140), outline=(85, 80, 75))
    # Nicho do sino na torre
    d.rectangle([22, 8, 42, 28], fill=(50, 45, 40), outline=(75, 70, 65))
    d.arc([22, 6, 42, 20], start=180, end=360, fill=(75, 70, 65), width=2)
    # Sino de bronze
    d.ellipse([27, 14, 37, 24], fill=(190, 120, 40), outline=(120, 70, 20))
    d.rectangle([29, 10, 35, 14], fill=(130, 75, 20)) # Cabeçote
    d.ellipse([30, 23, 34, 26], fill=(220, 150, 50)) # Badalo
    # Portal de carvalho escuro
    d.rectangle([18, 38, 46, 78], fill=(65, 42, 25), outline=(40, 25, 15))
    d.arc([18, 26, 46, 50], start=180, end=360, fill=(40, 25, 15), width=2)
    # Dobradiças de ferro e ferragens
    d.line([19, 44, 30, 44], fill=(20, 20, 20), width=2)
    d.line([19, 66, 30, 66], fill=(20, 20, 20), width=2)
    d.line([34, 44, 45, 44], fill=(20, 20, 20), width=2)
    d.line([34, 66, 45, 66], fill=(20, 20, 20), width=2)
    img.save(os.path.join(OUTPUT_DIR, "church_portal_64x80.png"))

def create_window_breeze():
    # 48x64 Janela veneziana com vento e cortina
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Moldura de madeira da janela
    d.rectangle([6, 8, 42, 58], fill=(60, 75, 95), outline=(120, 80, 45), width=3) # Vidro azul escuro
    # Veneziana esquerda aberta
    d.rectangle([2, 10, 14, 56], fill=(145, 95, 55), outline=(85, 50, 25))
    for y in range(14, 54, 5):
        d.line([3, y, 13, y], fill=(100, 60, 30), width=1)
    # Veneziana direita entreaberta batendo
    d.rectangle([34, 10, 46, 56], fill=(145, 95, 55), outline=(85, 50, 25))
    for y in range(14, 54, 5):
        d.line([35, y, 45, y], fill=(100, 60, 30), width=1)
    # Cortina de linho ondulando com o vento
    d.polygon([(16, 8), (28, 8), (34, 30), (28, 56), (18, 54), (22, 28)], fill=(245, 245, 240, 220))
    d.line([(18, 54), (28, 56)], fill=(200, 200, 190), width=1)
    # Tranca de metal na janela
    d.rectangle([22, 36, 26, 40], fill=(200, 170, 50), outline=(110, 90, 20))
    img.save(os.path.join(OUTPUT_DIR, "window_breeze_48x64.png"))

def create_reading_desk():
    # 56x48 Escrivaninha de mogno com estojo de óculos e relógio
    img = Image.new("RGBA", (56, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Pernas e gaveteiro
    d.rectangle([6, 18, 50, 46], fill=(110, 60, 30), outline=(65, 35, 15))
    d.rectangle([10, 24, 24, 42], fill=(85, 45, 20), outline=(55, 30, 10)) # Gavetas
    d.rectangle([15, 30, 19, 32], fill=(210, 180, 50)) # Puxador
    d.rectangle([15, 38, 19, 40], fill=(210, 180, 50))
    # Tampo da escrivaninha
    d.rectangle([4, 14, 52, 20], fill=(150, 85, 45), outline=(90, 50, 25))
    # Partitura aberta branca
    d.rectangle([26, 12, 38, 16], fill=(240, 235, 220), outline=(180, 175, 160))
    d.line([28, 13, 36, 13], fill=(80, 80, 80))
    d.line([28, 15, 36, 15], fill=(80, 80, 80))
    # Estojo de óculos vermelho aveludado
    d.ellipse([38, 13, 48, 17], fill=(160, 35, 45), outline=(95, 20, 25))
    # Óculos de aro metálico redondos
    d.ellipse([40, 11, 44, 15], outline=(220, 200, 70), width=1)
    d.ellipse([44, 11, 48, 15], outline=(220, 200, 70), width=1)
    d.line([43, 13, 45, 13], fill=(220, 200, 70))
    # Relógio de pulso de couro
    d.line([12, 14, 18, 14], fill=(80, 50, 20), width=2)
    d.ellipse([14, 12, 17, 16], fill=(230, 230, 230), outline=(180, 150, 40))
    img.save(os.path.join(OUTPUT_DIR, "reading_desk_56x48.png"))

def create_hanging_fern():
    # 48x64 Samambaia suspensa com regador de latão
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Corrente de suspensão
    d.line([24, 2, 24, 18], fill=(160, 160, 160), width=1)
    d.line([24, 18, 16, 26], fill=(130, 130, 130), width=1)
    d.line([24, 18, 32, 26], fill=(130, 130, 130), width=1)
    # Vaso de cerâmica terracota
    d.polygon([(16, 26), (32, 26), (28, 36), (20, 36)], fill=(195, 95, 60), outline=(130, 60, 35))
    # Folhagem da samambaia caindo em cascata
    for dx, dy in [(-8, 4), (-4, 8), (0, 12), (4, 10), (8, 6), (-12, 10), (12, 12), (-6, 16), (6, 18)]:
        d.arc([24+dx-10, 26+dy-6, 24+dx+10, 26+dy+14], start=30, end=150, fill=(45, 140, 55), width=2)
        d.arc([24+dx-8, 26+dy-4, 24+dx+8, 26+dy+12], start=40, end=140, fill=(75, 185, 70), width=1)
    # Regador de latão apoiado embaixo
    d.rectangle([18, 48, 30, 60], fill=(215, 180, 60), outline=(145, 110, 30))
    d.line([30, 54, 38, 46], fill=(215, 180, 60), width=2) # Bico fino
    d.ellipse([36, 44, 40, 48], fill=(235, 200, 80)) # Ponta do regador
    d.arc([12, 48, 20, 60], start=90, end=270, fill=(145, 110, 30), width=2) # Alça
    img.save(os.path.join(OUTPUT_DIR, "hanging_fern_48x64.png"))

def create_porcelain_cupboard():
    # 48x64 Cristaleira de porcelana com xícara e bule
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Estrutura em madeira clara
    d.rectangle([6, 8, 42, 62], fill=(155, 115, 80), outline=(95, 65, 40))
    # Prateleiras envidraçadas
    d.rectangle([10, 12, 38, 38], fill=(225, 240, 245, 180), outline=(85, 55, 35))
    d.line([10, 25, 38, 25], fill=(125, 85, 55), width=2)
    # Xícaras de porcelana branca e dourada
    d.ellipse([14, 20, 22, 24], fill=(250, 250, 250), outline=(210, 175, 60))
    d.ellipse([26, 20, 34, 24], fill=(250, 250, 250), outline=(210, 175, 60))
    # Bule de café/chá na bancada
    d.ellipse([18, 42, 30, 52], fill=(245, 245, 245), outline=(180, 145, 40))
    d.line([30, 45, 36, 41], fill=(220, 180, 60), width=2) # Bico
    # Portas inferiores de madeira
    d.rectangle([10, 40, 23, 58], fill=(130, 90, 60), outline=(80, 50, 30))
    d.rectangle([25, 40, 38, 58], fill=(130, 90, 60), outline=(80, 50, 30))
    img.save(os.path.join(OUTPUT_DIR, "porcelain_cupboard_48x64.png"))

def create_yarn_basket():
    # 40x36 Cesta de novelo de lã com sininho
    img = Image.new("RGBA", (40, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Cesta de vime
    d.ellipse([6, 14, 34, 32], fill=(175, 130, 80), outline=(115, 80, 45), width=2)
    d.ellipse([8, 16, 32, 26], fill=(130, 90, 50))
    # Novelo de lã vermelho-rubi
    d.ellipse([12, 10, 26, 24], fill=(205, 45, 55), outline=(145, 25, 35))
    d.arc([14, 12, 24, 22], start=30, end=150, fill=(245, 95, 105), width=2)
    # Fio desenrolado no chão
    d.line([(24, 22), (28, 28), (34, 26), (36, 30)], fill=(205, 45, 55), width=2)
    # Sininho de bronze na ponta
    d.ellipse([34, 28, 38, 33], fill=(235, 195, 55), outline=(155, 120, 25))
    img.save(os.path.join(OUTPUT_DIR, "yarn_basket_40x36.png"))

def create_broom_bucket():
    # 36x48 Vassoura de palha apoiada no balde
    img = Image.new("RGBA", (36, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Balde de metal galvanizado
    d.polygon([(14, 26), (28, 26), (26, 44), (16, 44)], fill=(165, 175, 185), outline=(105, 115, 125))
    d.ellipse([14, 24, 28, 28], fill=(185, 195, 205), outline=(105, 115, 125))
    # Cabo de madeira da vassoura
    d.line([8, 4, 22, 42], fill=(160, 110, 60), width=3)
    # Cerdas de palha amarela amarradas
    d.polygon([(6, 2), (12, 2), (18, 18), (2, 18)], fill=(225, 195, 95), outline=(165, 135, 55))
    d.line([3, 12, 17, 12], fill=(175, 45, 45), width=2) # Amarração vermelha
    # Folhas secas no chão
    d.ellipse([24, 42, 30, 45], fill=(185, 115, 45))
    d.ellipse([10, 43, 15, 46], fill=(165, 95, 35))
    img.save(os.path.join(OUTPUT_DIR, "broom_bucket_36x48.png"))

def create_hallway_stand():
    # 48x64 Aparador da entrada com cabideiro e chaves
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Moldura alta de mogno
    d.rectangle([8, 6, 40, 60], fill=(125, 75, 40), outline=(75, 40, 20))
    # Espelho oval
    d.ellipse([14, 12, 34, 34], fill=(215, 235, 245), outline=(180, 140, 70), width=2)
    d.line([18, 16, 30, 30], fill=(255, 255, 255, 180), width=2) # Reflexo
    # Bancada do aparador
    d.rectangle([6, 36, 42, 44], fill=(155, 95, 55), outline=(90, 50, 25))
    # Molho de chaves de latão pendurado no gancho
    d.rectangle([21, 46, 27, 48], fill=(180, 140, 40)) # Gancho
    d.ellipse([22, 48, 26, 52], outline=(235, 195, 55), width=2) # Argola
    d.line([23, 52, 23, 58], fill=(235, 195, 55), width=2) # Chave 1
    d.line([25, 52, 25, 60], fill=(215, 175, 45), width=2) # Chave 2
    d.line([27, 52, 27, 56], fill=(245, 205, 65), width=2) # Chave 3
    img.save(os.path.join(OUTPUT_DIR, "hallway_stand_48x64.png"))

def create_seaside_bench():
    # 56x40 Banco do mirante com ripas de madeira e sal
    img = Image.new("RGBA", (56, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Suportes de ferro envelhecido
    d.rectangle([10, 18, 14, 36], fill=(65, 75, 80), outline=(40, 45, 50))
    d.rectangle([42, 18, 46, 36], fill=(65, 75, 80), outline=(40, 45, 50))
    # Encosto de ripas de madeira marítima
    d.rectangle([6, 8, 50, 13], fill=(165, 145, 125), outline=(115, 95, 75))
    d.rectangle([6, 15, 50, 20], fill=(155, 135, 115), outline=(115, 95, 75))
    # Assento do banco
    d.rectangle([4, 22, 52, 28], fill=(180, 160, 135), outline=(125, 105, 85))
    # Manchas de sal e maresia
    d.line([12, 10, 18, 10], fill=(230, 235, 240, 180))
    d.line([34, 24, 42, 24], fill=(230, 235, 240, 180))
    # Concha do mar aos pés do banco
    d.ellipse([30, 33, 36, 37], fill=(245, 220, 200), outline=(190, 165, 145))
    img.save(os.path.join(OUTPUT_DIR, "seaside_bench_56x40.png"))

def create_station_lantern():
    # 40x64 Lanterna de vapor da plataforma ferroviária
    img = Image.new("RGBA", (40, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Coluna de ferro fundido verde-escuro
    d.rectangle([17, 24, 23, 62], fill=(45, 65, 55), outline=(25, 40, 35))
    d.rectangle([13, 58, 27, 63], fill=(55, 75, 65), outline=(25, 40, 35)) # Base pesada
    # Braço ornamental curvado
    d.arc([10, 12, 30, 28], start=180, end=360, fill=(45, 65, 55), width=3)
    # Cúpula da lanterna
    d.polygon([(12, 10), (28, 10), (24, 4), (16, 4)], fill=(45, 65, 55), outline=(25, 40, 35))
    # Vidro com luz âmbar quente de vapor
    d.polygon([(14, 10), (26, 10), (24, 24), (16, 24)], fill=(255, 205, 80, 230), outline=(55, 75, 65))
    d.ellipse([17, 14, 23, 20], fill=(255, 245, 180)) # Filamento brilhante
    img.save(os.path.join(OUTPUT_DIR, "station_lantern_40x64.png"))

def create_cello_stand():
    # 48x64 Violoncelo nobre com estante de partituras
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Suporte tripé de chão
    d.line([16, 50, 10, 62], fill=(40, 40, 40), width=2)
    d.line([32, 50, 38, 62], fill=(40, 40, 40), width=2)
    # Corpo do violoncelo (madeira nobre castanha e envernizada)
    d.ellipse([14, 26, 34, 52], fill=(145, 65, 25), outline=(85, 35, 10), width=2)
    # Cintura em 'C' do cello
    d.ellipse([12, 33, 18, 42], fill=(0, 0, 0, 0)) # Chanfro esquerdo
    d.ellipse([30, 33, 36, 42], fill=(0, 0, 0, 0)) # Chanfro direito
    # Efes (f-holes) clássicos
    d.line([20, 34, 20, 42], fill=(40, 15, 5), width=1)
    d.line([28, 34, 28, 42], fill=(40, 15, 5), width=1)
    # Espelho de ébano e braço
    d.rectangle([22, 10, 26, 32], fill=(30, 28, 26))
    # Cravelhame e voluta esculpida
    d.rectangle([21, 4, 27, 10], fill=(120, 50, 20))
    d.ellipse([21, 2, 27, 6], fill=(145, 65, 25))
    # 4 Cordas de aço
    for x in [22, 23, 24, 25]:
        d.line([x, 6, x, 50], fill=(215, 215, 220), width=1)
    # Espigão de metal tocando o chão
    d.line([24, 52, 24, 62], fill=(180, 185, 190), width=2)
    img.save(os.path.join(OUTPUT_DIR, "cello_stand_48x64.png"))

def create_wind_chimes_stand():
    # 48x64 Pedestal com sinos de vento de cristal e bronze
    img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Haste dourada e base circular
    d.rectangle([22, 12, 26, 58], fill=(195, 160, 60), outline=(130, 100, 30))
    d.ellipse([14, 56, 34, 62], fill=(180, 145, 50), outline=(120, 90, 25))
    # Disco suspensor superior
    d.ellipse([12, 10, 36, 16], fill=(225, 195, 75), outline=(145, 115, 35))
    # Tubos de bronze e cristal suspensos
    tubes = [(16, 28, (215, 180, 70)), (20, 34, (200, 235, 255)), (28, 32, (200, 235, 255)), (32, 26, (215, 180, 70))]
    for tx, th, color in tubes:
        d.line([tx, 14, tx, 14+th], fill=color, width=2)
    # Pêndulo central e pingente de cristal
    d.line([24, 14, 24, 38], fill=(160, 130, 40), width=1)
    d.ellipse([22, 26, 26, 30], fill=(200, 150, 40)) # Batedor
    d.polygon([(24, 38), (27, 43), (24, 48), (21, 43)], fill=(220, 245, 255, 230), outline=(160, 210, 240)) # Prisma
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
    print("All 15 pixel art scenery props generated successfully!")

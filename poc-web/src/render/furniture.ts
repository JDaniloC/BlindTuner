import { Container, Graphics } from "pixi.js";
import { IsoBox } from "./isoBox";
import { IsoMath } from "../core/iso";

export class FurnitureRenderer {
  /**
   * Cama de Casal de Madeira com Tapete Ornamental, Edredom e Travesseiros.
   */
  static createBed(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // 1. Tapete Persa/Acolchoado sob a cama
    const tapW = 108;
    const tapD = 112;
    const t0 = IsoMath.project({ x: x - 12, y: y - 10, z: 0.2 });
    const t1 = IsoMath.project({ x: x + tapW, y: y - 10, z: 0.2 });
    const t2 = IsoMath.project({ x: x + tapW, y: y + tapD, z: 0.2 });
    const t3 = IsoMath.project({ x: x - 12, y: y + tapD, z: 0.2 });

    // Base do tapete em tom terracota / bordô com borda dourada
    g.poly([t0.x, t0.y, t1.x, t1.y, t2.x, t2.y, t3.x, t3.y])
      .fill(0x78281f)
      .stroke({ color: 0xcaa356, width: 2.0 });

    // Franjas do tapete nas extremidades
    g.moveTo(t0.x, t0.y).lineTo(t3.x, t3.y).stroke({ color: 0xe8d8b5, width: 2.2 });
    g.moveTo(t1.x, t1.y).lineTo(t2.x, t2.y).stroke({ color: 0xe8d8b5, width: 2.2 });

    // 2. Estrutura de madeira nobre da cama (com veios)
    IsoBox.draw(g, { x, y, z: 0 }, { x: 88, y: 92, z: 14 }, {
      baseColor: 0x6d4224,
      woodGrain: true,
      highlightCrest: true,
      shadowAlpha: 0.35,
    });

    // Pés torneados da cama
    IsoBox.draw(g, { x: x + 2, y: y + 84, z: 0 }, { x: 8, y: 8, z: 14 }, { baseColor: 0x4a2c16 });
    IsoBox.draw(g, { x: x + 80, y: y + 84, z: 0 }, { x: 8, y: 8, z: 14 }, { baseColor: 0x4a2c16 });

    // Cabeceira alta esculpida
    IsoBox.draw(g, { x: x - 4, y: y - 4, z: 14 }, { x: 96, y: 12, z: 36 }, {
      baseColor: 0x543016,
      woodGrain: true,
      highlightCrest: true,
    });

    // Colchão de molas
    IsoBox.draw(g, { x: x + 6, y: y + 8, z: 14 }, { x: 76, y: 80, z: 12 }, {
      baseColor: 0xf4f1ea,
      highlightCrest: true,
    });

    // Edredom mostarda acolchoado com vincos
    IsoBox.draw(g, { x: x + 6, y: y + 32, z: 15 }, { x: 76, y: 56, z: 13 }, {
      baseColor: 0xdca026,
      highlightCrest: true,
    });

    // Dobra da colcha (lençol branco dobrado)
    IsoBox.draw(g, { x: x + 6, y: y + 26, z: 15.5 }, { x: 76, y: 8, z: 4 }, {
      baseColor: 0xffffff,
      highlightCrest: true,
    });

    // Travesseiros chanfrados confortáveis
    IsoBox.draw(g, { x: x + 10, y: y + 12, z: 26 }, { x: 30, y: 16, z: 7 }, {
      baseColor: 0xfffefa,
      highlightCrest: true,
    });
    IsoBox.draw(g, { x: x + 48, y: y + 12, z: 26 }, { x: 30, y: 16, z: 7 }, {
      baseColor: 0xfffefa,
      highlightCrest: true,
    });

    c.zIndex = IsoMath.depthOf({ x: x + 44, y: y + 46, z: 0 });
    return c;
  }

  /**
   * Criado-mudo de Cerejeira com Abajur que Ilumina de Verdade e Rádio Retrô.
   */
  static createNightstand(gridX: number, gridY: number, step: number = 44): { container: Container; update: (t: number) => void } {
    const container = new Container();
    const gBase = new Graphics();
    const gDynamic = new Graphics();
    container.addChild(gBase);
    container.addChild(gDynamic);

    const x = gridX * step;
    const y = gridY * step;

    // Móvel de cerejeira com 2 gavetas
    IsoBox.draw(gBase, { x, y, z: 0 }, { x: 34, y: 34, z: 26 }, {
      baseColor: 0x7c4322,
      woodGrain: true,
      highlightCrest: true,
      shadowAlpha: 0.3,
    });

    // Divisória e puxadores de latão dourado das gavetas
    IsoBox.draw(gBase, { x: x + 34, y: y + 14, z: 16 }, { x: 2, y: 6, z: 3 }, { baseColor: 0xf9d849 });
    IsoBox.draw(gBase, { x: x + 34, y: y + 14, z: 6 }, { x: 2, y: 6, z: 3 }, { baseColor: 0xf9d849 });

    // Haste de latão polido do abajur
    IsoBox.drawCylinder(gBase, { x: x + 22, y: y + 10, z: 26 }, 3.0, 16, 0xd4af37, 0xf9e076);

    // Rádio retrô de baquelite sobre a mesa
    IsoBox.draw(gBase, { x: x + 5, y: y + 14, z: 26 }, { x: 15, y: 12, z: 10 }, {
      baseColor: 0x422213,
      highlightCrest: true,
    });
    // Mostrador iluminado do rádio
    IsoBox.draw(gBase, { x: x + 20, y: y + 16, z: 28 }, { x: 1, y: 8, z: 5 }, { baseColor: 0xffd54f });

    const update = (t: number) => {
      gDynamic.clear();
      const pulse = 0.92 + Math.sin(t * 3.2) * 0.08;
      const lampCenter = IsoMath.project({ x: x + 22, y: y + 10, z: 42 });

      // Point Light real: Luz quente expansiva que banha o quarto e a parede ao redor
      gDynamic.circle(lampCenter.x, lampCenter.y, 85 * pulse)
        .fill({ color: 0xffe680, alpha: 0.12 * pulse });
      gDynamic.circle(lampCenter.x, lampCenter.y, 45 * pulse)
        .fill({ color: 0xfff1aa, alpha: 0.18 * pulse });

      // Cúpula cônica iluminada do abajur com textura e contorno nítido
      IsoBox.drawCylinder(gDynamic, { x: x + 22, y: y + 10, z: 38 }, 8.5, 12, 0xffebba, 0xfff8e1);

      // Antena do rádio e ondas de rádio sutis
      const antennaTip = IsoMath.project({ x: x + 11, y: y + 17, z: 41 });
      gDynamic.moveTo(antennaTip.x, antennaTip.y + 12).lineTo(antennaTip.x, antennaTip.y)
        .stroke({ color: 0x90a4ae, width: 1.5 });

      const wavePhase = (t * 1.8) % 1.0;
      gDynamic.circle(antennaTip.x, antennaTip.y, 3 + wavePhase * 14)
        .stroke({ color: 0x81d4fa, width: 1.2, alpha: (1.0 - wavePhase) * 0.6 });
    };

    container.zIndex = IsoMath.depthOf({ x: x + 17, y: y + 17, z: 0 });
    return { container, update };
  }

  /**
   * Relógio de Pêndulo Antigo com Pêndulo de Latão Oscilando.
   */
  static createGrandfatherClock(gridX: number, gridY: number, step: number = 44): { container: Container; update: (t: number) => void } {
    const container = new Container();
    const gBase = new Graphics();
    const gPendulum = new Graphics();
    container.addChild(gBase);
    container.addChild(gPendulum);

    const x = gridX * step;
    const y = gridY * step;

    // Caixa clássica de mogno esculpida
    IsoBox.draw(gBase, { x, y, z: 0 }, { x: 28, y: 18, z: 80 }, {
      baseColor: 0x4e2011,
      woodGrain: true,
      highlightCrest: true,
      shadowAlpha: 0.4,
    });

    // Friso decorativo intermediário
    IsoBox.draw(gBase, { x: x - 2, y: y - 2, z: 42 }, { x: 32, y: 22, z: 4 }, { baseColor: 0x3d170a });

    // Mostrador de porcelana branca com aro de latão
    IsoBox.draw(gBase, { x: x + 3, y: y + 18, z: 58 }, { x: 22, y: 1.5, z: 18 }, {
      baseColor: 0xfffded,
      outlineColor: 0xd4af37,
      outlineWidth: 1.5,
    });

    const update = (t: number) => {
      gPendulum.clear();
      const swingAngle = Math.sin(t * 3.14159) * 0.26;
      const pivot = IsoMath.project({ x: x + 14, y: y + 16, z: 52 });
      const bobLen = 28;
      const bobX = pivot.x + Math.sin(swingAngle) * bobLen;
      const bobY = pivot.y + Math.cos(swingAngle) * bobLen;

      // Haste do pêndulo
      gPendulum.moveTo(pivot.x, pivot.y).lineTo(bobX, bobY)
        .stroke({ color: 0xd4af37, width: 2.0 });

      // Lente/disco polido do pêndulo de latão
      gPendulum.circle(bobX, bobY, 6.0)
        .fill(0xfbc02d)
        .stroke({ color: 0x825c05, width: 1.2 });
    };

    container.zIndex = IsoMath.depthOf({ x: x + 14, y: y + 9, z: 0 });
    return { container, update };
  }

  /**
   * Poltrona Estofada Cozy com Manta e Almofada.
   */
  static createArmchair(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // Pés de madeira torneada
    IsoBox.draw(g, { x: x + 2, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3e2723 });
    IsoBox.draw(g, { x: x + 40, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3e2723 });
    IsoBox.draw(g, { x: x + 2, y: y + 40, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3e2723 });
    IsoBox.draw(g, { x: x + 40, y: y + 40, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3e2723 });

    // Assento macio verde-oliva
    IsoBox.draw(g, { x, y, z: 6 }, { x: 48, y: 48, z: 16 }, {
      baseColor: 0x4a632b,
      highlightCrest: true,
      shadowAlpha: 0.35,
    });

    // Encosto alto e acolchoado com capitonê
    IsoBox.draw(g, { x: x - 2, y: y - 2, z: 22 }, { x: 52, y: 12, z: 32 }, {
      baseColor: 0x3b5022,
      highlightCrest: true,
    });

    // Braços arredondados da poltrona
    IsoBox.draw(g, { x: x - 4, y: y + 8, z: 18 }, { x: 10, y: 42, z: 14 }, { baseColor: 0x35471f, highlightCrest: true });
    IsoBox.draw(g, { x: x + 42, y: y + 8, z: 18 }, { x: 10, y: 42, z: 14 }, { baseColor: 0x35471f, highlightCrest: true });

    // Almofada mostarda macia
    IsoBox.draw(g, { x: x + 10, y: y + 10, z: 22 }, { x: 28, y: 28, z: 7 }, {
      baseColor: 0xdeb038,
      highlightCrest: true,
    });

    c.zIndex = IsoMath.depthOf({ x: x + 24, y: y + 24, z: 0 });
    return c;
  }

  /**
   * Mesinha de Centro com Livros e Xícara Fumegante de Chá.
   */
  static createTeaTable(gridX: number, gridY: number, step: number = 44): { container: Container; update: (t: number) => void } {
    const container = new Container();
    const gBase = new Graphics();
    const gSteam = new Graphics();
    container.addChild(gBase);
    container.addChild(gSteam);

    const x = gridX * step;
    const y = gridY * step;

    // Tampo da mesinha de carvalho chanfrada
    IsoBox.draw(gBase, { x, y, z: 0 }, { x: 36, y: 28, z: 14 }, {
      baseColor: 0x754728,
      woodGrain: true,
      highlightCrest: true,
      shadowAlpha: 0.28,
    });

    // Livros antigos empilhados (capa de couro bordô e azul petróleo)
    IsoBox.draw(gBase, { x: x + 4, y: y + 4, z: 14 }, { x: 16, y: 12, z: 4 }, { baseColor: 0x881c1c });
    IsoBox.draw(gBase, { x: x + 6, y: y + 5, z: 18 }, { x: 14, y: 10, z: 3 }, { baseColor: 0x1a4968 });

    // Xícara de porcelana com pires
    IsoBox.drawCylinder(gBase, { x: x + 26, y: y + 14, z: 14 }, 4.5, 5, 0xfffdf6, 0x4a2e12);

    const update = (t: number) => {
      gSteam.clear();
      // Vapor sutil subindo da xícara de chá quente
      const cupCenter = IsoMath.project({ x: x + 26, y: y + 14, z: 20 });
      for (let s = 0; s < 3; s++) {
        const steamPhase = ((t * 0.8) + s * 0.33) % 1.0;
        const steamY = cupCenter.y - steamPhase * 18;
        const steamX = cupCenter.x + Math.sin(t * 3.0 + s * 2.0) * 3.0;
        const alpha = Math.sin(steamPhase * Math.PI) * 0.45;

        gSteam.circle(steamX, steamY, 2.5 + steamPhase * 3.5)
          .fill({ color: 0xffffff, alpha });
      }
    };

    container.zIndex = IsoMath.depthOf({ x: x + 18, y: y + 14, z: 0 });
    return { container, update };
  }

  /**
   * Gabinete de Banheiro com Cuba de Porcelana, Espelho em Latão e Torneira Pingando.
   */
  static createBathroomSink(gridX: number, gridY: number, step: number = 44): { container: Container; update: (t: number) => void } {
    const container = new Container();
    const gBase = new Graphics();
    const gDrip = new Graphics();
    container.addChild(gBase);
    container.addChild(gDrip);

    const x = gridX * step;
    const y = gridY * step;

    // Gabinete de madeira tratada
    IsoBox.draw(gBase, { x, y, z: 0 }, { x: 44, y: 38, z: 24 }, {
      baseColor: 0x5a3e2a,
      woodGrain: true,
      shadowAlpha: 0.32,
    });

    // Cuba de porcelana branca com borda chanfrada
    IsoBox.draw(gBase, { x: x - 2, y: y - 2, z: 24 }, { x: 48, y: 42, z: 8 }, {
      baseColor: 0xf5f8fa,
      highlightCrest: true,
      outlineColor: 0xa0b0be,
    });

    // Espelho vertical na parede com moldura de latão
    IsoBox.draw(gBase, { x: x + 2, y: y - 2, z: 32 }, { x: 40, y: 4, z: 40 }, {
      baseColor: 0xc8e6f5,
      outlineColor: 0xd4af37,
      outlineWidth: 2.0,
    });

    // Torneira cromada curvada
    IsoBox.drawCylinder(gBase, { x: x + 22, y: y + 6, z: 32 }, 2.5, 12, 0xd0d8e0, 0x90a0b0);

    const update = (t: number) => {
      gDrip.clear();
      // Gota d'água caindo ritmicamente da torneira (farol visual do drip)
      const dripCycle = (t * 1.25) % 1.0;
      const tapPos = IsoMath.project({ x: x + 22, y: y + 14, z: 40 });
      const basinPos = IsoMath.project({ x: x + 22, y: y + 14, z: 28 });

      if (dripCycle < 0.45) {
        const fallT = dripCycle / 0.45;
        const curY = tapPos.y + (basinPos.y - tapPos.y) * fallT;
        gDrip.circle(tapPos.x, curY, 2.0)
          .fill({ color: 0x4fc3f7, alpha: 0.9 });
      } else {
        const ripT = (dripCycle - 0.45) / 0.55;
        const radius = 2.0 + ripT * 12.0;
        const alpha = (1.0 - ripT) * 0.75;
        // Ondulação isométrica 2:1 na bacia
        gDrip.ellipse(basinPos.x, basinPos.y, radius, radius * 0.5)
          .stroke({ color: 0x4fc3f7, width: 1.5, alpha });
      }
    };

    container.zIndex = IsoMath.depthOf({ x: x + 22, y: y + 19, z: 0 });
    return { container, update };
  }

  /**
   * Banheira Clássica Vitoriana de Porcelana com Pés em Garra e Água Translúcida.
   */
  static createBathtub(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // 4 Pés em garra de leão em latão dourado
    IsoBox.draw(g, { x: x + 2, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0xd4af37 });
    IsoBox.draw(g, { x: x + 58, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0xd4af37 });
    IsoBox.draw(g, { x: x + 2, y: y + 80, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0xd4af37 });
    IsoBox.draw(g, { x: x + 58, y: y + 80, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0xd4af37 });

    // Corpo externo da banheira de porcelana branca esmaltada
    IsoBox.draw(g, { x, y, z: 6 }, { x: 66, y: 88, z: 24 }, {
      baseColor: 0xf5f8fc,
      highlightCrest: true,
      outlineColor: 0x90a4ae,
      shadowAlpha: 0.35,
    });

    // Interior da banheira com água límpida azul-turquesa
    IsoBox.draw(g, { x: x + 6, y: y + 6, z: 18 }, { x: 54, y: 76, z: 10 }, {
      baseColor: 0x81d4fa,
      outlineColor: 0x4fc3f7,
      topColorMultiplier: 1.15,
    });

    c.zIndex = IsoMath.depthOf({ x: x + 33, y: y + 44, z: 0 });
    return c;
  }

  /**
   * Vaso Sanitário de Porcelana com Caixa Acoplada.
   */
  static createToilet(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // Caixa de descarga acoplada na parede
    IsoBox.draw(g, { x, y, z: 12 }, { x: 30, y: 12, z: 24 }, {
      baseColor: 0xf0f4f8,
      highlightCrest: true,
      shadowAlpha: 0.3,
    });

    // Tampa/assento da bacia
    IsoBox.draw(g, { x: x + 2, y: y + 12, z: 0 }, { x: 26, y: 30, z: 18 }, {
      baseColor: 0xf5f8fc,
      highlightCrest: true,
      outlineColor: 0x90a4ae,
    });

    c.zIndex = IsoMath.depthOf({ x: x + 15, y: y + 21, z: 0 });
    return c;
  }

  /**
   * Sofá Capitonê de 3 Lugares com Veludo Nobre e Almofadas.
   */
  static createSofa(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // Pés de mogno torneados
    IsoBox.draw(g, { x: x + 2, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3d170a });
    IsoBox.draw(g, { x: x + 110, y: y + 2, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3d170a });
    IsoBox.draw(g, { x: x + 2, y: y + 36, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3d170a });
    IsoBox.draw(g, { x: x + 110, y: y + 36, z: 0 }, { x: 6, y: 6, z: 6 }, { baseColor: 0x3d170a });

    // Base e assento triplo em veludo bordô nobre
    IsoBox.draw(g, { x, y, z: 6 }, { x: 118, y: 44, z: 14 }, {
      baseColor: 0x6e1b24,
      highlightCrest: true,
      shadowAlpha: 0.38,
    });

    // Encosto alto com capitonê trabalhado
    IsoBox.draw(g, { x: x - 2, y: y - 2, z: 20 }, { x: 122, y: 12, z: 28 }, {
      baseColor: 0x5a141c,
      highlightCrest: true,
    });

    // Braços arredondados acolchoados
    IsoBox.draw(g, { x: x - 4, y: y + 8, z: 16 }, { x: 10, y: 38, z: 16 }, { baseColor: 0x541219, highlightCrest: true });
    IsoBox.draw(g, { x: x + 112, y: y + 8, z: 16 }, { x: 10, y: 38, z: 16 }, { baseColor: 0x541219, highlightCrest: true });

    // 2 Almofadas bege de seda
    IsoBox.draw(g, { x: x + 14, y: y + 10, z: 20 }, { x: 26, y: 24, z: 8 }, { baseColor: 0xdec69e, highlightCrest: true });
    IsoBox.draw(g, { x: x + 78, y: y + 10, z: 20 }, { x: 26, y: 24, z: 8 }, { baseColor: 0xdec69e, highlightCrest: true });

    c.zIndex = IsoMath.depthOf({ x: x + 59, y: y + 22, z: 0 });
    return c;
  }

  /**
   * Estante Alta de Partituras e Livros Antigos de Luthier.
   */
  static createBookcase(gridX: number, gridY: number, step: number = 44): Container {
    const c = new Container();
    const g = new Graphics();
    c.addChild(g);

    const x = gridX * step;
    const y = gridY * step;

    // Estrutura vertical de carvalho escuro com moldura superior
    IsoBox.draw(g, { x, y, z: 0 }, { x: 38, y: 110, z: 85 }, {
      baseColor: 0x4a2c16,
      woodGrain: true,
      highlightCrest: true,
      shadowAlpha: 0.42,
    });

    // Prateleiras com livros coloridos (vermelho, ocre, azul marinho, verde escuro)
    const bookColors = [0x8b2520, 0x224b6e, 0x2e663d, 0xc49a3a, 0x5c2b66];
    for (let shelf = 1; shelf <= 3; shelf++) {
      const zS = shelf * 22;
      IsoBox.draw(g, { x: x + 2, y: y + 2, z: zS }, { x: 34, y: 106, z: 3 }, { baseColor: 0x3d200e });

      // Fileira de livros
      for (let b = 0; b < 5; b++) {
        const col = bookColors[(shelf + b) % bookColors.length];
        IsoBox.draw(g, { x: x + 4, y: y + 6 + b * 20, z: zS + 3 }, { x: 30, y: 16, z: 16 }, {
          baseColor: col,
          highlightCrest: true,
        });
      }
    }

    c.zIndex = IsoMath.depthOf({ x: x + 19, y: y + 55, z: 0 });
    return c;
  }

  /**
   * Lareira Rústica de Tijolos com Chaminé e Brasas Vivas.
   */
  static createFireplace(gridX: number, gridY: number, step: number = 44): { container: Container; update: (t: number) => void } {
    const container = new Container();
    const gBase = new Graphics();
    const gFire = new Graphics();
    container.addChild(gBase);
    container.addChild(gFire);

    const x = gridX * step;
    const y = gridY * step;

    // Estrutura de tijolos rústicos
    IsoBox.draw(gBase, { x, y, z: 0 }, { x: 32, y: 64, z: 70 }, {
      baseColor: 0x7c3826,
      highlightCrest: true,
      shadowAlpha: 0.35,
    });

    // Vão da fornalha escura
    IsoBox.draw(gBase, { x: x + 8, y: y + 12, z: 4 }, { x: 24, y: 40, z: 32 }, {
      baseColor: 0x16110f,
    });

    // Prateleira de madeira maciça sobre a lareira
    IsoBox.draw(gBase, { x: x - 4, y: y - 4, z: 70 }, { x: 40, y: 72, z: 8 }, {
      baseColor: 0x4a2511,
      woodGrain: true,
      highlightCrest: true,
    });

    const update = (t: number) => {
      gFire.clear();
      // Chamas e brasas vivas pulsando suavemente
      const pulse = 0.88 + Math.sin(t * 7.5) * 0.12;
      const fireCenter = IsoMath.project({ x: x + 18, y: y + 32, z: 12 });

      // Brilho quente alaranjado
      gFire.circle(fireCenter.x, fireCenter.y, 42 * pulse)
        .fill({ color: 0xff6f00, alpha: 0.16 * pulse });
      gFire.circle(fireCenter.x, fireCenter.y, 22 * pulse)
        .fill({ color: 0xffd54f, alpha: 0.28 * pulse });

      // Línguas de fogo com chamas estilizadas
      for (let i = 0; i < 4; i++) {
        const fPhase = (t * 4.0 + i * 0.7) % 1.0;
        const fy = fireCenter.y - fPhase * 16;
        const fx = fireCenter.x + (i - 1.5) * 6 + Math.sin(t * 8.0 + i) * 2.5;
        gFire.circle(fx, fy, 3.5 * (1.0 - fPhase * 0.5))
          .fill({ color: i % 2 === 0 ? 0xff9800 : 0xffea00, alpha: (1.0 - fPhase) * 0.85 });
      }
    };

    container.zIndex = IsoMath.depthOf({ x: x + 16, y: y + 32, z: 0 });
    return { container, update };
  }
}

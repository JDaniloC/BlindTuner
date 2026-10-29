import { Application, Container, RenderTexture, Sprite } from "pixi.js";
import { RoomScene } from "./render/roomScene";
import { Conductor, Phase } from "./core/conductor";
import { AudioEngine } from "./audio/audioEngine";
import { PitchScrollInput } from "./input/pitchScroll";
import { ActionPanel } from "./input/actionPanel";
import { JoystickInput } from "./input/joystickInput";
import { PianoInput } from "./input/pianoInput";
import { CharacterController, TripReason, MoveStep } from "./core/characterController";
import { ColorSchemeManager, ColorSchemeId } from "./core/colorSchemes";
import { CueSettingsManager, CueLevel } from "./core/cueSettings";
import { NotePanel } from "./ui/notePanel";
import { VictoryModal } from "./ui/victoryModal";
import { VisionOverlay, VisionCondition } from "./render/visionOverlay";
import { CampaignManager, LevelMetadata } from "./core/campaign";
import { SaveManager } from "./core/saveManager";
import { NOTES } from "./core/notes";
import { IsoMath, Vector2 } from "./core/iso";

type InputMode = "scroll" | "joystick" | "piano";

async function bootstrap() {
  const wrapper = document.getElementById("canvas-wrapper") as HTMLElement;
  const btnStart = document.getElementById("btn-start") as HTMLButtonElement;
  const modal = document.getElementById("audio-init-modal") as HTMLElement;
  const hudPhase = document.getElementById("hud-phase") as HTMLElement;
  const noteTrack = document.getElementById("note-track") as HTMLElement;
  const btnStyleToggle = document.getElementById("btn-style-toggle") as HTMLButtonElement;
  const announcer = document.getElementById("status-announcer") as HTMLElement;

  const selectCampaignLevel = document.getElementById("select-campaign-level") as HTMLSelectElement;
  const selectCueLevel = document.getElementById("select-cue-level") as HTMLSelectElement;
  const selectColorScheme = document.getElementById("select-color-scheme") as HTMLSelectElement;
  const selectVisionImpairment = document.getElementById("select-vision-impairment") as HTMLSelectElement;
  const btnToggleControlCues = document.getElementById("btn-toggle-control-cues") as HTMLButtonElement;
  const notePanelContainer = document.getElementById("note-panel-container") as HTMLElement;

  const btnModeScroll = document.getElementById("btn-mode-scroll") as HTMLButtonElement;
  const btnModeJoystick = document.getElementById("btn-mode-joystick") as HTMLButtonElement;
  const btnModePiano = document.getElementById("btn-mode-piano") as HTMLButtonElement;

  const announce = (msg: string) => {
    announcer.textContent = msg;
  };

  // 1. Inicializa os Gerenciadores de Acessibilidade, Cores e Persistência
  const colorManager = ColorSchemeManager.getInstance();
  const cueManager = CueSettingsManager.getInstance();
  const saveManager = SaveManager.getInstance();

  let currentLevelMeta: LevelMetadata = CampaignManager.getLevels()[0];
  let levelStartTime = performance.now();

  // 2. Inicializa o PixiJS v8
  const app = new Application();
  await app.init({
    resizeTo: wrapper,
    backgroundColor: 0x080a0e,
    resolution: window.devicePixelRatio || 1,
    autoDensity: true,
    antialias: true,
  });
  wrapper.appendChild(app.canvas);

  // 3. Simulador de Baixa Visão Ótico (VisionOverlay)
  const visionOverlay = new VisionOverlay({ containerElement: wrapper });

  // 4. Cena Isométrica e Farol Sonoro
  const scene = new RoomScene();
  const step = scene.step; // 44px
  scene.buildLevel(currentLevelMeta.levelDef);

  // 5. Pipeline de Pixel Art em Tempo Real (RenderTexture com interpolação Nearest)
  let isPixelArtMode = saveManager.getPreferences().isPixelArtMode ?? true;
  const pixelWidth = 270;
  const pixelHeight = 480;

  const pixelRenderTexture = RenderTexture.create({
    width: pixelWidth,
    height: pixelHeight,
    scaleMode: "nearest",
  });
  pixelRenderTexture.source.scaleMode = "nearest";

  const pixelSprite = new Sprite(pixelRenderTexture);

  const worldRoot = new Container();
  app.stage.addChild(worldRoot);

  const uiLayer = new Container();
  app.stage.addChild(uiLayer);

  const getCameraTarget = () => {
    const viewW = isPixelArtMode ? pixelWidth : app.screen.width;
    const viewH = isPixelArtMode ? pixelHeight : app.screen.height;
    const scale = isPixelArtMode ? 0.68 : 1.15;
    const targetX = viewW * 0.44 - scene.arthur.worldPos.x * scale;
    const targetY = viewH * 0.52 - scene.arthur.worldPos.y * scale;
    return { targetX, targetY, scale };
  };

  const applyRenderMode = () => {
    worldRoot.removeChildren();
    const { targetX, targetY, scale } = getCameraTarget();
    scene.stage.scale.set(scale);
    scene.stage.position.set(targetX, targetY);

    if (isPixelArtMode) {
      worldRoot.addChild(pixelSprite);
      btnStyleToggle.textContent = "🎨 Estilo: Pixel Art 16-bit";
      btnStyleToggle.style.borderColor = "#ffd54f";
    } else {
      worldRoot.addChild(scene.stage);
      btnStyleToggle.textContent = "🎨 Estilo: Vetorial HD";
      btnStyleToggle.style.borderColor = "#8d6e63";
    }
  };

  const resizePixelSprite = () => {
    if (isPixelArtMode) {
      pixelSprite.width = app.screen.width;
      pixelSprite.height = app.screen.height;
    }
    const { targetX, targetY, scale } = getCameraTarget();
    scene.stage.scale.set(scale);
    scene.stage.position.set(targetX, targetY);
  };

  applyRenderMode();
  resizePixelSprite();
  window.addEventListener("resize", () => {
    resizePixelSprite();
    visionOverlay.resize();
  });

  btnStyleToggle.addEventListener("click", () => {
    isPixelArtMode = !isPixelArtMode;
    saveManager.setPreference("isPixelArtMode", isPixelArtMode);
    applyRenderMode();
    resizePixelSprite();
  });

  // 6. Motor de Áudio Acústico com ConvolverNode de Madeira Real e Faróis Espaciais
  const audio = new AudioEngine();

  // Farol Sonoro de Objetivo conectado ao AudioEngine com spatial panning e attenuation
  scene.beacon.onPulsed = (soundType, beaconGrid) => {
    const dx = beaconGrid.x - controller.gridPos.x;
    const dy = beaconGrid.y - controller.gridPos.y;
    const isDucked = (conductor.phase === Phase.PREVIEW || conductor.phase === Phase.CALL);
    audio.playBeaconSound(soundType, { dx, dy }, isDucked);
  };

  // 7. Conductor (Loop Call-and-Response)
  const conductor = new Conductor();
  conductor.loadPreset(currentLevelMeta.levelDef.presetNotes, 0.70);

  // 8. Placa Didática da Nota Alvo (NotePanel)
  const notePanel = new NotePanel({
    containerElement: notePanelContainer,
    onReplayRequested: () => {
      if (conductor.phase === Phase.CALL) {
        conductor.replayCurrentCue();
        announce("Repetindo nota alvo sem penalidade.");
      }
    },
  });

  // 9. Character Controller
  const controller = new CharacterController(currentLevelMeta.levelDef, {
    onMoved: (newGrid) => {
      announce(`Passo executado na posição ${newGrid.x}, ${newGrid.y}`);
      visionOverlay.pulseClarity(0.20);
    },
    onBlocked: (_dir, reason) => {
      if (reason === TripReason.WALL) {
        scene.arthur.triggerTrip("wall");
        scene.triggerWallBounce();
        audio.playWallBumpSfx();
        conductor.recordWallBump();
        hudPhase.textContent = "Colisão com Parede / Móvel!";
        hudPhase.style.background = "#b71c1c";
        announce("Tropeço em obstáculo físico!");
      } else {
        scene.arthur.triggerTrip("miss");
        audio.playNoteMissSfx();
        hudPhase.textContent = "Nota Incorreta! Tente novamente";
        hudPhase.style.background = "#d84315";
      }
    },
    onArmedStateChanged: (running, jumping) => {
      scene.arthur.setArmedState(running, jumping);
      actionPanel.setArmedState(running, jumping);
      pianoInput.setArmedState(running, jumping);
    },
    onTactilePulseRequested: () => {
      scene.arthur.triggerCaneProbe();
      audio.playCaneTapSfx();
      scene.triggerTactileProbe();
      visionOverlay.pulseClarity(0.50);
      announce("Varredura tátil da bengala.");
    },
    onListeningFocusRequested: () => {
      scene.arthur.triggerListenFocus();
      audio.playPiano("A4");
      scene.triggerFocusGuide(currentLevelMeta.levelDef.goalPos);
      scene.beacon.pulseNow();
      visionOverlay.pulseClarity(0.40);
      announce("Escutando farol acústico do objetivo.");
    },
    onStepDust: (pos) => {
      const worldPos = IsoMath.gridToWorld(pos.x, pos.y, 0, step);
      scene.spawnDustPuff(worldPos, 4);
    },
  });

  scene.arthur.snapToGrid(controller.gridPos.x, controller.gridPos.y, step);

  let moveQueue: MoveStep[] = [];
  let currentStep: MoveStep | null = null;
  let stepProgress = 0;
  let stepStartWorld: Vector2 = { ...scene.arthur.worldPos };
  let stepTargetWorld: Vector2 = { ...scene.arthur.worldPos };

  const enqueueSteps = (steps: MoveStep[]) => {
    moveQueue.push(...steps);
  };

  // Submissão unificada de notas de qualquer modo de input
  const handleNoteInput = (noteKey: string) => {
    controller.clearTrip();

    if (conductor.phase === Phase.CALL) {
      audio.playPiano(noteKey);
      scene.triggerAcousticPulse(noteKey);

      const target = conductor.getTargetNote();
      const hit = noteKey === target;

      if (!hit && target) {
        const targetFreq = NOTES[target]?.freq || 300;
        const playedFreq = NOTES[noteKey]?.freq || 300;
        notePanel.displayMissGuidance(playedFreq, targetFreq);
      }

      conductor.submitNote(noteKey);

      if (hit) {
        const steps = controller.handleNote(noteKey);
        if (steps) {
          enqueueSteps(steps);
        }
      }
    } else {
      const steps = controller.handleNote(noteKey);
      if (steps) {
        enqueueSteps(steps);
      }
      audio.playPiano(noteKey);
      scene.triggerAcousticPulse(noteKey);
    }
  };

  // Trilha visual de contas musicais no HUD
  const beads: HTMLElement[] = [];
  const rebuildBeads = (notes: string[]) => {
    beads.length = 0;
    noteTrack.innerHTML = "";
    notes.forEach((_nKey, idx) => {
      const bead = document.createElement("div");
      bead.className = "note-bead";
      bead.textContent = `${idx + 1}`;
      noteTrack.appendChild(bead);
      beads.push(bead);
    });
  };

  rebuildBeads(currentLevelMeta.levelDef.presetNotes);

  let currentActiveBead = -1;
  let currentDoneBeads = 0;

  const updateBeads = (activeIdx: number, doneCount: number) => {
    currentActiveBead = activeIdx;
    currentDoneBeads = doneCount;
    beads.forEach((b, i) => {
      const nKey = currentLevelMeta.levelDef.presetNotes[i];
      const col = colorManager.getColor(nKey, false);

      b.classList.remove("active", "done");
      if (i < doneCount) {
        b.classList.add("done");
        b.style.background = col;
        b.style.color = "#fff";
      } else if (i === activeIdx) {
        b.classList.add("active");
        b.style.background = col;
        b.style.borderColor = "#ffffff";
      } else {
        b.style.background = "#271912";
        b.style.borderColor = "#543926";
        b.style.color = "#888";
      }
    });
  };

  // 10. Modos de Entrada (Fretless Scroll, Joystick de 8 Fatias, Piano Virtual Cromático)
  let activeInputMode: InputMode = saveManager.getPreferences().preferredInputMode || "scroll";

  const pitchScroll = new PitchScrollInput({
    onDragStart: (freq) => {
      audio.startCello(freq);
    },
    onDragMove: (freq, angleRad, noteKey) => {
      audio.setPitch(freq);
      const colorHex = colorManager.getColorHexNumber(noteKey, true);
      scene.arthur.setTuning(true, angleRad, colorHex);
    },
    onDragEnd: (finalNoteKey) => {
      audio.stopCello();
      scene.arthur.setTuning(false, scene.arthur.facingAngle);
      handleNoteInput(finalNoteKey);
    },
  });

  const actionPanel = new ActionPanel({
    onActionTriggered: (noteKey) => {
      handleNoteInput(noteKey);
    },
  });

  const joystickInput = new JoystickInput({
    onNoteTriggered: (noteKey) => {
      handleNoteInput(noteKey);
    },
    onPreviewAngle: (angleRad, noteKey) => {
      const colorHex = colorManager.getColorHexNumber(noteKey, true);
      scene.arthur.setTuning(true, angleRad, colorHex);
    },
  });

  const pianoInput = new PianoInput({
    onNoteTriggered: (noteKey) => {
      handleNoteInput(noteKey);
    },
    onPreviewNote: (noteKey) => {
      const colorHex = colorManager.getColorHexNumber(noteKey, true);
      scene.arthur.setTuning(true, scene.arthur.facingAngle, colorHex);
    },
  });

  uiLayer.addChild(pitchScroll.container);
  uiLayer.addChild(actionPanel.container);
  uiLayer.addChild(joystickInput.container);
  uiLayer.addChild(pianoInput.container);

  const applyInputMode = (mode: InputMode) => {
    activeInputMode = mode;
    saveManager.setPreference("preferredInputMode", mode);
    btnModeScroll.classList.toggle("active", mode === "scroll");
    btnModeJoystick.classList.toggle("active", mode === "joystick");
    btnModePiano.classList.toggle("active", mode === "piano");

    pitchScroll.container.visible = mode === "scroll";
    joystickInput.container.visible = mode === "joystick";
    pianoInput.container.visible = mode === "piano";
    actionPanel.container.visible = mode !== "piano";

    layoutUI();
  };

  const layoutUI = () => {
    const sw = app.screen.width;
    const sh = app.screen.height;

    pitchScroll.container.position.set(sw - 74, sh * 0.5 - 200);

    if (activeInputMode === "scroll") {
      actionPanel.container.position.set(18, sh - 146);
    } else if (activeInputMode === "joystick") {
      actionPanel.container.position.set(sw - 140, sh - 146);
    }

    joystickInput.container.position.set(128, sh - 128);

    const pianoW = 7 * pianoInput.whiteKeyWidth;
    pianoInput.container.position.set((sw - pianoW) * 0.5, sh - pianoInput.whiteKeyHeight - 20);
  };

  applyInputMode(activeInputMode);
  window.addEventListener("resize", layoutUI);

  btnModeScroll.addEventListener("click", () => applyInputMode("scroll"));
  btnModeJoystick.addEventListener("click", () => applyInputMode("joystick"));
  btnModePiano.addEventListener("click", () => applyInputMode("piano"));

  // 11. Modal de Vitória com Sistema de 3 Estrelas
  const victoryModal = new VictoryModal({
    containerElement: wrapper,
    onNextLevelRequested: () => {
      const nextMeta = CampaignManager.getNextLevel(currentLevelMeta.id);
      if (nextMeta) {
        loadCampaignLevel(nextMeta.id);
      }
    },
    onRetryRequested: () => {
      loadCampaignLevel(currentLevelMeta.id);
    },
    onLevelSelectRequested: () => {
      if (selectCampaignLevel) {
        selectCampaignLevel.focus();
      }
    },
  });

  // Função centralizada para carregar qualquer fase da Campanha ou Suzuki
  const loadCampaignLevel = (levelId: string) => {
    const meta = CampaignManager.getLevelById(levelId);
    if (!meta) return;

    currentLevelMeta = meta;
    levelStartTime = performance.now();

    if (selectCampaignLevel) {
      selectCampaignLevel.value = levelId;
    }

    scene.buildLevel(meta.levelDef);
    controller.setLevel(meta.levelDef);
    scene.arthur.snapToGrid(meta.levelDef.startPos.x, meta.levelDef.startPos.y, step);

    conductor.loadPreset(meta.levelDef.presetNotes, 0.70);
    rebuildBeads(meta.levelDef.presetNotes);
    updateBeads(0, 0);
    notePanel.clear();

    scene.beacon.setVisualEnabled(!cueManager.isSoundOnly());
    announce(`Iniciando ${meta.name}. ${meta.chapter}. Peça: ${meta.songTitle}`);

    if (audio.isReady) {
      conductor.start();
    }
    resizePixelSprite();
  };

  // Seletor de Fase da Campanha e Caderno Suzuki
  if (selectCampaignLevel) {
    selectCampaignLevel.addEventListener("change", () => {
      loadCampaignLevel(selectCampaignLevel.value);
    });
  }

  // Seletor de Simulador de Baixa Visão
  if (selectVisionImpairment) {
    selectVisionImpairment.addEventListener("change", () => {
      const condition = selectVisionImpairment.value as VisionCondition;
      visionOverlay.setCondition(condition);
      saveManager.setPreference("visionImpairment", condition);
      announce(`Simulador visual: ${selectVisionImpairment.options[selectVisionImpairment.selectedIndex].text}`);
    });
  }

  // Configurações Pedagógicas e de Acessibilidade
  selectCueLevel.addEventListener("change", () => {
    const level = Number(selectCueLevel.value) as CueLevel;
    cueManager.setLevel(level);
    saveManager.setPreference("cueLevel", level);
    scene.beacon.setVisualEnabled(!cueManager.isSoundOnly());
    announce(`Nível de pista visual alterado para Pista ${level}`);
  });

  selectColorScheme.addEventListener("change", () => {
    const scheme = selectColorScheme.value as ColorSchemeId;
    colorManager.setScheme(scheme);
    saveManager.setPreference("colorScheme", scheme);
    updateBeads(currentActiveBead, currentDoneBeads);
    announce(`Esquema de cores alterado para ${scheme}`);
  });

  const updateControlCuesButton = () => {
    const enabled = colorManager.controlCuesEnabled;
    btnToggleControlCues.classList.toggle("active", enabled);
    btnToggleControlCues.textContent = enabled ? "🎛️ Pistas Controles: ON" : "🎛️ Pistas Controles: OFF";
    btnToggleControlCues.style.borderColor = enabled ? "#ffd54f" : "#666";
  };

  btnToggleControlCues.addEventListener("click", () => {
    colorManager.setControlCuesEnabled(!colorManager.controlCuesEnabled);
    saveManager.setPreference("controlCuesEnabled", colorManager.controlCuesEnabled);
    updateControlCuesButton();
    announce(`Pistas visuais nos controles ${colorManager.controlCuesEnabled ? "ativadas" : "desativadas"}`);
  });

  updateControlCuesButton();

  // Eventos do Conductor
  conductor.onPhaseChanged = (phase) => {
    scene.beacon.setDucking(phase === Phase.PREVIEW || phase === Phase.CALL);

    if (phase === Phase.PREVIEW) {
      hudPhase.textContent = "Ouvindo a Melodia";
      hudPhase.style.background = "#1b5e20";
      notePanel.clear();
      announce("Iniciando prévia da melodia. Escute cada nota.");
    } else if (phase === Phase.CALL) {
      hudPhase.textContent = "Sua Vez de Tocar";
      hudPhase.style.background = "#e65100";
      announce("Sua vez. Afine ou toque cada nota para guiar o Sr. Arthur.");
      updateBeads(0, 0);
    } else if (phase === Phase.REPLAY) {
      hudPhase.textContent = "Melodia Completa!";
      hudPhase.style.background = "#0d47a1";
      notePanel.clear();
      announce("Melodia completa! Travessia realizada com sucesso.");
      updateBeads(-1, beads.length);
    } else if (phase === Phase.DONE) {
      const stats = conductor.stats;
      const elapsedSec = Math.max(0.1, (performance.now() - levelStartTime) / 1000);

      // Avaliação rigorosa das 3 estrelas categóricas (DEC-0005)
      const evaluation = CampaignManager.evaluateStars(currentLevelMeta, {
        firstTryHits: stats.firstTryHits,
        totalNotes: conductor.totalNotes,
        wallBumps: stats.wallBumps,
        pitchMisses: stats.pitchMisses,
        elapsedSec,
      });

      // Salva progresso e recordes no localStorage
      saveManager.recordCompletion(
        currentLevelMeta.id,
        evaluation.stars,
        elapsedSec,
        stats.wallBumps,
        stats.firstTryHits
      );

      // Desbloqueia a próxima fase
      const nextMeta = CampaignManager.getNextLevel(currentLevelMeta.id);
      if (nextMeta) {
        saveManager.unlockLevel(nextMeta.id);
      }

      hudPhase.textContent = `Vitória: ${evaluation.stars} Estrela(s)! (${stats.firstTryHits}/${conductor.totalNotes} acertos)`;
      hudPhase.style.background = "#4a148c";
      notePanel.clear();

      // Fanfarra triunfal de violoncelo e sinos
      audio.playVictoryFanfare();

      // Apresentação do Modal de Vitória com selos e telemetria
      victoryModal.show(currentLevelMeta, evaluation, Boolean(nextMeta));

      announce(`Memória Concluída com ${evaluation.stars} estrelas! 1ª tentativa: ${stats.firstTryHits} de ${conductor.totalNotes}. Tropeços: ${stats.wallBumps}`);
    }
  };

  conductor.onPreviewNote = (noteKey, idx) => {
    audio.playPiano(noteKey);
    scene.triggerAcousticPulse(noteKey);
    updateBeads(idx, idx);
    notePanel.displayTargetNote(noteKey);
  };

  conductor.onCallCue = (noteKey, idx) => {
    audio.playPiano(noteKey);
    scene.triggerAcousticPulse(noteKey);
    updateBeads(idx, idx);
    notePanel.displayTargetNote(noteKey);
  };

  conductor.onNoteResolved = (hit, idx, _noteKey) => {
    if (hit) {
      updateBeads(idx + 1, idx + 1);
    }
  };

  conductor.onReplayNote = (noteKey, idx) => {
    audio.playPiano(noteKey);
    scene.triggerAcousticPulse(noteKey);
    updateBeads(idx, beads.length);
  };

  conductor.onSequenceComplete = () => {
    updateBeads(-1, beads.length);
    notePanel.clear();
  };

  // 12. Botão de Iniciar Áudio
  btnStart.addEventListener("click", async () => {
    btnStart.textContent = "Afinando violoncelo...";
    await audio.init();
    modal.style.display = "none";
    levelStartTime = performance.now();
    conductor.start();
  });

  // 13. Loop de Renderização & Animação
  let lastTime = performance.now();
  let totalTime = 0;

  app.ticker.add(() => {
    const now = performance.now();
    const dt = Math.min((now - lastTime) / 1000, 0.1);
    lastTime = now;
    totalTime += dt;

    // Atualização de passos suaves do personagem
    if (currentStep) {
      stepProgress += dt / currentStep.durationSec;
      if (stepProgress >= 1.0) {
        stepProgress = 1.0;
        scene.arthur.snapToGrid(currentStep.toGrid.x, currentStep.toGrid.y, step);
        scene.arthur.setJumpProgress(0);
        currentStep = null;
      } else {
        const curX = stepStartWorld.x + (stepTargetWorld.x - stepStartWorld.x) * stepProgress;
        const curY = stepStartWorld.y + (stepTargetWorld.y - stepStartWorld.y) * stepProgress;
        scene.arthur.worldPos = { x: curX, y: curY };
        scene.arthur.container.x = curX;
        scene.arthur.container.y = curY;
        scene.arthur.container.zIndex = IsoMath.depthOf({
          x: (currentStep.fromGrid.x + (currentStep.toGrid.x - currentStep.fromGrid.x) * stepProgress) * step,
          y: (currentStep.fromGrid.y + (currentStep.toGrid.y - currentStep.fromGrid.y) * stepProgress) * step,
          z: 0,
        });

        if (currentStep.isJumping) {
          scene.arthur.setJumpProgress(stepProgress, currentStep.jumpArcHeight);
        }
      }
    } else if (moveQueue.length > 0) {
      currentStep = moveQueue.shift()!;
      stepProgress = 0;
      stepStartWorld = { ...scene.arthur.worldPos };
      stepTargetWorld = IsoMath.gridToWorld(currentStep.toGrid.x, currentStep.toGrid.y, 0, step);
    }

    // Atualização da Cena, Partículas e Efeitos
    scene.update(dt, totalTime);

    // Camera follow suave com suporte a Screen Shake de tropeço
    const { targetX, targetY, scale } = getCameraTarget();
    let shakeX = 0;
    let shakeY = 0;
    if (scene.screenShake > 0) {
      shakeX = (Math.random() - 0.5) * scene.screenShake;
      shakeY = (Math.random() - 0.5) * scene.screenShake;
    }

    scene.stage.scale.set(scale);
    scene.stage.position.set(targetX + shakeX, targetY + shakeY);

    // Atualização da posição de tela do Sr. Arthur no Simulador de Baixa Visão
    const viewW = isPixelArtMode ? pixelWidth : app.screen.width;
    const viewH = isPixelArtMode ? pixelHeight : app.screen.height;
    const arthurLocalX = targetX + shakeX + scene.arthur.worldPos.x * scale;
    const arthurLocalY = targetY + shakeY + scene.arthur.worldPos.y * scale;
    const arthurScreenX = (arthurLocalX / viewW) * app.screen.width;
    const arthurScreenY = (arthurLocalY / viewH) * app.screen.height;
    visionOverlay.update(arthurScreenX, arthurScreenY, currentStep !== null, dt);

    // Renderiza a cena no modo ativo (Pixel Art com RenderTexture vs Vetorial HD)
    if (isPixelArtMode) {
      app.renderer.render({
        container: scene.stage,
        target: pixelRenderTexture,
        clear: true,
      });
    }
  });
}

bootstrap().catch((err) => {
  console.error("Falha ao inicializar o BlindTuner Web:", err);
});

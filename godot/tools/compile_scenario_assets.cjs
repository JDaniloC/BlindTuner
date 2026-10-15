const fs = require('fs');
const path = require('path');
const { processPixelAsset } = require('./process_pixel_art.cjs');

const BRAIN_DIR = 'C:/Users/danil/.gemini/antigravity/brain/eb13c739-4486-43dc-a07d-133d19d8e4d6';
const FURNITURE_DIR = path.resolve('godot/assets/sprites/furniture');
const OBSTACLES_DIR = path.resolve('godot/assets/sprites/obstacles');

[FURNITURE_DIR, OBSTACLES_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

const ASSETS_TO_PROCESS = [
  {
    name: 'bed_elderly',
    file: 'raw_bed_elderly_1790606280398.jpg',
    w: 96,
    h: 80,
    outDir: FURNITURE_DIR,
    outName: 'bed_elderly_96x80.png',
    options: { bottomInset: 2, outlineColor: [45, 30, 20] }
  },
  {
    name: 'nightstand_lamp',
    file: 'raw_nightstand_lamp_1790606414742.jpg',
    w: 48,
    h: 64,
    outDir: FURNITURE_DIR,
    outName: 'nightstand_lamp_48x64.png',
    options: { bottomInset: 2, outlineColor: [45, 32, 22] }
  },
  {
    name: 'armchair_cozy',
    file: 'raw_armchair_cozy_1790606449742.jpg',
    w: 64,
    h: 64,
    outDir: FURNITURE_DIR,
    outName: 'armchair_cozy_64x64.png',
    options: { bottomInset: 2, outlineColor: [35, 35, 40] }
  },
  {
    name: 'dresser_wood',
    file: 'raw_dresser_wood_1790606525336.jpg',
    w: 96,
    h: 80,
    outDir: FURNITURE_DIR,
    outName: 'dresser_wood_96x80.png',
    options: { bottomInset: 2, outlineColor: [45, 30, 20] }
  },
  {
    name: 'rug_folded',
    file: 'raw_rug_folded_1790606581586.jpg',
    w: 80,
    h: 44,
    outDir: OBSTACLES_DIR,
    outName: 'rug_folded_80x44.png',
    options: { bottomInset: 1, outlineColor: [40, 25, 25] }
  },
  {
    name: 'slippers_floor',
    file: 'raw_slippers_floor_1790606630126.jpg',
    w: 36,
    h: 32,
    outDir: OBSTACLES_DIR,
    outName: 'slippers_floor_36x32.png',
    options: { bottomInset: 1, outlineColor: [38, 28, 22] }
  },
];

async function main() {
  console.log('--- Compiling Scenario Assets for BlindTuner ---');
  for (const item of ASSETS_TO_PROCESS) {
    const inputPath = path.join(BRAIN_DIR, item.file);
    const outputPath = path.join(item.outDir, item.outName);
    console.log(`Processing ${item.name} (${item.w}x${item.h})...`);
    await processPixelAsset(inputPath, outputPath, item.w, item.h, item.options);
  }
  console.log('--- All Scenario Assets Successfully Compiled! ---');
}

main().catch(err => {
  console.error('Fatal compilation error:', err);
  process.exit(1);
});

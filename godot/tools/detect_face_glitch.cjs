let sharp;
try {
  sharp = require('../../../casarei.online/node_modules/sharp');
} catch (e) {
  try {
    sharp = require('../casarei.online/node_modules/sharp');
  } catch (e2) {
    sharp = require('c:/Users/danil/Documents/code/casarei.online/node_modules/sharp');
  }
}
const fs = require('fs');
const path = require('path');

const elderlyDir = path.resolve('godot/assets/sprites/character/16x32_elderly');
const origDir = path.resolve('godot/assets/sprites/character_backup_original/16x32');
const files = fs.readdirSync(elderlyDir).filter(f => f.endsWith('.png'));

async function findShirtInHead() {
  let checkedFrames = 0;
  let glitches = 0;

  for (const f of files) {
    const origPath = path.join(origDir, f);
    const eldPath = path.join(elderlyDir, f);
    if (!fs.existsSync(origPath)) continue;

    const { data: origData, info } = await sharp(origPath).raw().toBuffer({ resolveWithObject: true });
    const { data: eldData } = await sharp(eldPath).raw().toBuffer({ resolveWithObject: true });

    const cols = Math.floor(info.width / 32);
    const rows = Math.floor(info.height / 32);

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        checkedFrames++;
        for (let fy = 0; fy < 32; fy++) {
          for (let fx = 0; fx < 32; fx++) {
            const idx = ((r * 32 + fy) * info.width + (c * 32 + fx)) * 4;
            // Original color:
            const or = origData[idx], og = origData[idx+1], ob = origData[idx+2];
            // Elderly color:
            const er = eldData[idx], eg = eldData[idx+1], eb = eldData[idx+2];

            // If original was blush (#d19da7) or light skin (#faf3e8) or shadow skin (#e7d5c6):
            const wasHeadOrFace = (or === 0xd1 && og === 0x9d && ob === 0xa7) ||
                                  (or === 0xe7 && og === 0xd5 && ob === 0xc6);

            // But elderly became cardigan (#5d7f64, #44604a, #76987d):
            const isCardigan = (eg > er + 10 && eg > eb + 10 && eg >= 90);

            if (wasHeadOrFace && isCardigan) {
              glitches++;
              console.log(`GLITCH in ${f} -> Row ${r}, Col ${c} at fx=${fx}, fy=${fy}! Was face, became cardigan!`);
            }
          }
        }
      }
    }
  }

  console.log(`Verification Complete: Checked ${checkedFrames} frames across all sheets. Glitches: ${glitches}`);
}

findShirtInHead();

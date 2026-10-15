const sharp = require('../../../casarei.online/node_modules/sharp');
const fs = require('fs');
const path = require('path');

const origDir = path.resolve('godot/assets/sprites/character_backup_original/16x32');
const files = fs.readdirSync(origDir).filter(f => f.endsWith('.png'));

async function testDynamicHead() {
  for (const f of files) {
    const origPath = path.join(origDir, f);
    const { data: origData, info } = await sharp(origPath).raw().toBuffer({ resolveWithObject: true });
    const cols = Math.floor(info.width / 32);
    const rows = Math.floor(info.height / 32);

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        // Find minFy for this frame
        let minFy = 32;
        for (let fy = 0; fy < 32; fy++) {
          for (let fx = 0; fx < 32; fx++) {
            const idx = ((r * 32 + fy) * info.width + (c * 32 + fx)) * 4;
            if (origData[idx + 3] > 0) {
              if (fy < minFy) minFy = fy;
            }
          }
        }
        const headBottom = minFy + 11;

        // Check if any blush or chin shadow in this frame falls below headBottom
        for (let fy = 0; fy < 32; fy++) {
          for (let fx = 0; fx < 32; fx++) {
            const idx = ((r * 32 + fy) * info.width + (c * 32 + fx)) * 4;
            const or = origData[idx], og = origData[idx+1], ob = origData[idx+2];
            const isBlushOrChin = (or === 0xd1 && og === 0x9d && ob === 0xa7) ||
                                  (or === 0xe7 && og === 0xd5 && ob === 0xc6);
            if (isBlushOrChin) {
              if (fy > headBottom) {
                console.log(`MISMATCH in ${f} Row ${r} Col ${c}: blush at fy=${fy} but headBottom=${headBottom}!`);
              }
            }
          }
        }
      }
    }
  }
  console.log('Dynamic head test finished!');
}

testDynamicHead();

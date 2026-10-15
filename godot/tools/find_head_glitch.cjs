const sharp = require('../../../casarei.online/node_modules/sharp');
const fs = require('fs');
const path = require('path');

const dir = path.resolve('godot/assets/sprites/character/16x32_elderly');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.png'));

async function findGreenOnHead() {
  for (const f of files) {
    const filePath = path.join(dir, f);
    const { data, info } = await sharp(filePath).raw().toBuffer({ resolveWithObject: true });
    const cols = Math.floor(info.width / 32);
    const rows = Math.floor(info.height / 32);

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        let greenCount = 0;
        let greenPixels = [];
        for (let fy = 10; fy <= 17; fy++) {
          for (let fx = 8; fx <= 24; fx++) {
            const gx = c * 32 + fx;
            const gy = r * 32 + fy;
            const idx = (gy * info.width + gx) * 4;
            const red = data[idx], green = data[idx+1], blue = data[idx+2], a = data[idx+3];
            // Green cardigan check: r around 93, g around 127, b around 100
            if (a > 200 && green > red + 10 && green > blue + 10) {
              greenCount++;
              greenPixels.push({ fx, fy, r: red, g: green, b: blue });
            }
          }
        }
        if (greenCount > 0) {
          console.log(`[${f}] Row ${r}, Col ${c}: ${greenCount} green pixels on head!`, greenPixels.slice(0, 3));
        }
      }
    }
  }
}

findGreenOnHead();

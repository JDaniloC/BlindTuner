const fs = require('fs');
const path = require('path');

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

const PALETTE = {
  OUTLINE: [47, 37, 34, 255],        // #2f2522
  SKIN_BASE: [250, 222, 198, 255],    // Warm peach skin
  SKIN_SHADOW: [225, 195, 170, 255],  // Warm peach skin shadow
  SKIN_HIGHLIGHT: [255, 238, 220, 255],
  
  // White/Silver Hair
  HAIR_WHITE: [242, 245, 248, 255],   // Pure white/silver hair
  HAIR_MID: [205, 212, 220, 255],     // Silver grey hair shadow
  HAIR_DARK: [155, 165, 175, 255],    // Deep silver contour
  
  // Sage Green Knit Cardigan
  CARDIGAN_BASE: [93, 127, 100, 255], // #5D7F64 Sage green
  CARDIGAN_LIGHT: [118, 152, 125, 255],
  CARDIGAN_SHADOW: [68, 96, 74, 255],
  CARDIGAN_BUTTON: [216, 180, 60, 255], // Brass/gold button
  UNDERSHIRT: [252, 248, 240, 255],     // Cream undershirt collar
  
  // Dark Charcoal Trousers
  PANTS_BASE: [53, 56, 66, 255],      // #353842 Dark charcoal
  PANTS_SHADOW: [38, 41, 49, 255],    // #262931 Deep shadow
  
  // Brown Leather Slippers
  SHOES_BASE: [78, 48, 30, 255],      // #4E301E Brown leather
  SHOES_SHADOW: [54, 30, 16, 255],
  
  // Glasses & Eyebrows
  GLASSES: [88, 62, 48, 255],         // Subtle wireframe glasses
  BLUSH: [214, 162, 172, 255]
};

function isColor(r, g, b, targetHex) {
  const hex = '#' + [r, g, b].map(c => c.toString(16).padStart(2, '0')).join('');
  return hex.toLowerCase() === targetHex.toLowerCase();
}

function isArmPixel(row, fx, fy, minFy, maxFy) {
  const dfy = fy - minFy;
  if (dfy < 12) return false;

  if (row === 0 || row === 4) {
    // South or North: flanks are strictly arms
    return (fx <= 11 || fx >= 20);
  } else if (row === 1) {
    // SE
    return (fx <= 9 || fx >= 19);
  } else if (row === 2) {
    // East profile
    return (fx <= 10 || fx >= 18);
  } else if (row === 3) {
    // NE
    return (fx <= 11 || fx >= 20);
  }
  return false;
}

async function transformSheet(inputSheet, outputSheet) {
  if (!fs.existsSync(inputSheet)) {
    console.warn(`File not found: ${inputSheet}`);
    return false;
  }
  const { data, info } = await sharp(inputSheet).raw().toBuffer({ resolveWithObject: true });
  const w = info.width;
  const h = info.height;
  const cols = Math.floor(w / 32);
  const rows = Math.floor(h / 32);

  const result = Buffer.from(data);

  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const startX = col * 32;
      const startY = row * 32;

      // 1. Compute frame vertical bounding box dynamically
      let minFy = 99;
      let maxFy = -1;
      for (let fy = 0; fy < 32; fy++) {
        for (let fx = 0; fx < 32; fx++) {
          const gx = startX + fx;
          const gy = startY + fy;
          const idx = (gy * w + gx) * 4;
          if (data[idx + 3] > 0) {
            if (fy < minFy) minFy = fy;
            if (fy > maxFy) maxFy = fy;
          }
        }
      }

      if (minFy === 99) continue; // Empty frame
      const totalH = maxFy - minFy + 1;
      const pantsHeight = Math.min(4, Math.max(1, totalH - 17));

      for (let fy = 0; fy < 32; fy++) {
        for (let fx = 0; fx < 32; fx++) {
          const gx = startX + fx;
          const gy = startY + fy;
          const idx = (gy * w + gx) * 4;

          const a = data[idx + 3];
          if (a === 0) continue;

          const r = data[idx], g = data[idx + 1], b = data[idx + 2];
          const isOutline = isColor(r, g, b, '#2f2522');
          const isLightSkin = isColor(r, g, b, '#faf3e8');
          const isShaded = isColor(r, g, b, '#b9b3a1');
          const isShadowSkin = isColor(r, g, b, '#e7d5c6');
          const isBlush = isColor(r, g, b, '#d19da7');

          // Preserve outline intact
          if (isOutline) continue;

          const dfy = fy - minFy;
          const dfMax = maxFy - fy;

          // UNIVERSAL RULE: Blush is ALWAYS blush, shadow skin is ALWAYS shadow skin on face
          if (isBlush) {
            result[idx] = PALETTE.BLUSH[0];
            result[idx + 1] = PALETTE.BLUSH[1];
            result[idx + 2] = PALETTE.BLUSH[2];
            continue;
          }

          if (isShadowSkin && dfy <= 12) {
            result[idx] = PALETTE.SKIN_SHADOW[0];
            result[idx + 1] = PALETTE.SKIN_SHADOW[1];
            result[idx + 2] = PALETTE.SKIN_SHADOW[2];
            continue;
          }

          // 1. HEAD REGION (dfy <= 11 relative to dynamic top of head)
          if (dfy <= 11) {
            if (row === 4) {
              // NORTH (Back of head) - full white silver hair
              result[idx] = isLightSkin ? PALETTE.HAIR_WHITE[0] : PALETTE.HAIR_MID[0];
              result[idx + 1] = isLightSkin ? PALETTE.HAIR_WHITE[1] : PALETTE.HAIR_MID[1];
              result[idx + 2] = isLightSkin ? PALETTE.HAIR_WHITE[2] : PALETTE.HAIR_MID[2];
            } else if (row === 3) {
              // NORTH-EAST (Diagonal back) - predominantly hair across back of skull
              const isBackSkull = (fx <= 20) || (dfy <= 4);
              if (isBackSkull) {
                result[idx] = isLightSkin ? PALETTE.HAIR_WHITE[0] : PALETTE.HAIR_MID[0];
                result[idx + 1] = isLightSkin ? PALETTE.HAIR_WHITE[1] : PALETTE.HAIR_MID[1];
                result[idx + 2] = isLightSkin ? PALETTE.HAIR_WHITE[2] : PALETTE.HAIR_MID[2];
              } else {
                result[idx] = isShaded ? PALETTE.SKIN_SHADOW[0] : PALETTE.SKIN_BASE[0];
                result[idx + 1] = isShaded ? PALETTE.SKIN_SHADOW[1] : PALETTE.SKIN_BASE[1];
                result[idx + 2] = isShaded ? PALETTE.SKIN_SHADOW[2] : PALETTE.SKIN_BASE[2];
              }
            } else if (row === 0) {
              // SOUTH (Front facing)
              const isSideHair = (fx <= 13 || fx >= 18) && (dfy <= 8);
              const isTopCrownHair = (dfy <= 1 && (fx === 12 || fx === 19));

              if (isSideHair || isTopCrownHair) {
                result[idx] = (fx <= 13) ? PALETTE.HAIR_WHITE[0] : PALETTE.HAIR_MID[0];
                result[idx + 1] = (fx <= 13) ? PALETTE.HAIR_WHITE[1] : PALETTE.HAIR_MID[1];
                result[idx + 2] = (fx <= 13) ? PALETTE.HAIR_WHITE[2] : PALETTE.HAIR_MID[2];
              } else {
                const isEyebrow = (dfy === 5) && (fx === 13 || fx === 14 || fx === 17 || fx === 18);
                const isGlassesFrame = (dfy === 6 && (fx >= 13 && fx <= 18)) ||
                                       (dfy === 7 && (fx === 13 || fx === 18));

                if (isEyebrow) {
                  result[idx] = PALETTE.HAIR_WHITE[0];
                  result[idx + 1] = PALETTE.HAIR_WHITE[1];
                  result[idx + 2] = PALETTE.HAIR_WHITE[2];
                } else if (isGlassesFrame) {
                  result[idx] = PALETTE.GLASSES[0];
                  result[idx + 1] = PALETTE.GLASSES[1];
                  result[idx + 2] = PALETTE.GLASSES[2];
                } else {
                  result[idx] = isShaded ? PALETTE.SKIN_SHADOW[0] : PALETTE.SKIN_BASE[0];
                  result[idx + 1] = isShaded ? PALETTE.SKIN_SHADOW[1] : PALETTE.SKIN_BASE[1];
                  result[idx + 2] = isShaded ? PALETTE.SKIN_SHADOW[2] : PALETTE.SKIN_BASE[2];
                }
              }
            } else if (row === 1 || row === 2) {
              // SOUTH-EAST and EAST (Diagonal / Profile)
              const isBackHair = (fx <= 14 && dfy <= 8) || (dfy <= 1 && fx <= 16);
              if (isBackHair) {
                result[idx] = PALETTE.HAIR_MID[0];
                result[idx + 1] = PALETTE.HAIR_MID[1];
                result[idx + 2] = PALETTE.HAIR_MID[2];
              } else {
                const isProfileGlasses = (dfy === 6 && (fx === 17 || fx === 18));
                if (isProfileGlasses) {
                  result[idx] = PALETTE.GLASSES[0];
                  result[idx + 1] = PALETTE.GLASSES[1];
                  result[idx + 2] = PALETTE.GLASSES[2];
                } else {
                  result[idx] = isShaded ? PALETTE.SKIN_SHADOW[0] : PALETTE.SKIN_BASE[0];
                  result[idx + 1] = isShaded ? PALETTE.SKIN_SHADOW[1] : PALETTE.SKIN_BASE[1];
                  result[idx + 2] = isShaded ? PALETTE.SKIN_SHADOW[2] : PALETTE.SKIN_BASE[2];
                }
              }
            }
          }

          // 2. ARMS & HANDS (Flanks of body - NEVER pants or shoes!)
          else if (isArmPixel(row, fx, fy, minFy, maxFy)) {
            // Hand at the very tip of the sleeve (dfy >= 19)
            if (dfy >= 19) {
              result[idx] = isShaded ? PALETTE.SKIN_SHADOW[0] : PALETTE.SKIN_BASE[0];
              result[idx + 1] = isShaded ? PALETTE.SKIN_SHADOW[1] : PALETTE.SKIN_BASE[1];
              result[idx + 2] = isShaded ? PALETTE.SKIN_SHADOW[2] : PALETTE.SKIN_BASE[2];
            } else {
              // Cardigan sleeve
              if (isShaded || fx > 17) {
                result[idx] = PALETTE.CARDIGAN_SHADOW[0];
                result[idx + 1] = PALETTE.CARDIGAN_SHADOW[1];
                result[idx + 2] = PALETTE.CARDIGAN_SHADOW[2];
              } else if (fx < 13) {
                result[idx] = PALETTE.CARDIGAN_LIGHT[0];
                result[idx + 1] = PALETTE.CARDIGAN_LIGHT[1];
                result[idx + 2] = PALETTE.CARDIGAN_LIGHT[2];
              } else {
                result[idx] = PALETTE.CARDIGAN_BASE[0];
                result[idx + 1] = PALETTE.CARDIGAN_BASE[1];
                result[idx + 2] = PALETTE.CARDIGAN_BASE[2];
              }
            }
          }

          // 3. FEET & SHOES (dfMax === 0, bottommost pixel of body)
          else if (dfMax === 0) {
            result[idx] = (fx > 16) ? PALETTE.SHOES_SHADOW[0] : PALETTE.SHOES_BASE[0];
            result[idx + 1] = (fx > 16) ? PALETTE.SHOES_SHADOW[1] : PALETTE.SHOES_BASE[1];
            result[idx + 2] = (fx > 16) ? PALETTE.SHOES_SHADOW[2] : PALETTE.SHOES_BASE[2];
          }

          // 4. LEGS & TROUSERS (dfMax between 1 and pantsHeight on non-arm pixels)
          else if (dfMax <= pantsHeight) {
            if (isShaded || fx > 16) {
              result[idx] = PALETTE.PANTS_SHADOW[0];
              result[idx + 1] = PALETTE.PANTS_SHADOW[1];
              result[idx + 2] = PALETTE.PANTS_SHADOW[2];
            } else {
              result[idx] = PALETTE.PANTS_BASE[0];
              result[idx + 1] = PALETTE.PANTS_BASE[1];
              result[idx + 2] = PALETTE.PANTS_BASE[2];
            }
          }

          // 5. TORSO REGION (Sage Green Knit Cardigan center)
          else {
            const isUndershirt = (row === 0 || row === 1) && (dfy === 11 || dfy === 12) && (fx === 15 || fx === 16);
            const isButton = (row === 0) && (dfy === 14 || dfy === 17) && (fx === 15);

            if (isUndershirt) {
              result[idx] = PALETTE.UNDERSHIRT[0];
              result[idx + 1] = PALETTE.UNDERSHIRT[1];
              result[idx + 2] = PALETTE.UNDERSHIRT[2];
            } else if (isButton) {
              result[idx] = PALETTE.CARDIGAN_BUTTON[0];
              result[idx + 1] = PALETTE.CARDIGAN_BUTTON[1];
              result[idx + 2] = PALETTE.CARDIGAN_BUTTON[2];
            } else {
              if (isShaded || fx > 17) {
                result[idx] = PALETTE.CARDIGAN_SHADOW[0];
                result[idx + 1] = PALETTE.CARDIGAN_SHADOW[1];
                result[idx + 2] = PALETTE.CARDIGAN_SHADOW[2];
              } else if (fx < 13) {
                result[idx] = PALETTE.CARDIGAN_LIGHT[0];
                result[idx + 1] = PALETTE.CARDIGAN_LIGHT[1];
                result[idx + 2] = PALETTE.CARDIGAN_LIGHT[2];
              } else {
                result[idx] = PALETTE.CARDIGAN_BASE[0];
                result[idx + 1] = PALETTE.CARDIGAN_BASE[1];
                result[idx + 2] = PALETTE.CARDIGAN_BASE[2];
              }
            }
          }
        }
      }
    }
  }

  const outDir = path.dirname(outputSheet);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  await sharp(result, { raw: { width: w, height: h, channels: 4 } })
    .png()
    .toFile(outputSheet);

  console.log(`✅ Transformada: ${path.basename(outputSheet)} (${w}x${h})`);
  return true;
}

module.exports = { transformSheet };

if (require.main === module) {
  const srcDir = path.resolve('godot/assets/sprites/character_backup_original/16x32');
  const outDir = path.resolve('godot/assets/sprites/character/16x32_elderly');

  const SHEETS_TO_PROCESS = [
    '16x32 Idle-Sheet.png',
    '16x32 Walk-Sheet.png',
    '16x32 Run-Sheet.png',
    '16x32 Rotate-Sheet.png',
    '16x32 Jump-Sheet.png',
    '16x32 Interact-Sheet.png',
    '16x32 Attack-Sheet.png'
  ];

  (async () => {
    console.log('--- Generating Complete Elderly Character Animated Sprite Sheets ---');
    for (const sheetName of SHEETS_TO_PROCESS) {
      const srcFile = path.join(srcDir, sheetName);
      const outFile = path.join(outDir, sheetName);
      await transformSheet(srcFile, outFile);
    }
    console.log('--- All 7 Character Animation Sheets Completed Successfully! ---');
  })().catch(console.error);
}

import {
  leftFront,
  left,
  leftBack,
  rightBack,
  right,
  rightFront,
  front,
  back
} from '../assets/images/character';
import { avgedFrequencies } from '../constants/Frequencies';

export default function getCharacterImage(frequency: number) {
    const imagesArray = [leftBack, left, leftFront, front, rightFront, right];
    for (let i = 0; i < avgedFrequencies.length; i++) {
        if (frequency < avgedFrequencies[i]) {
            return imagesArray[i];
        }
    }
    return rightBack;
}
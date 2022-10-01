import React, { useEffect, useMemo } from 'react';
import useState from 'react-usestateref'

import debounce from "lodash.debounce";
import throttle from 'lodash.throttle';
import * as Tone from 'tone';

import { StyleSheet } from 'react-native';
import { RootTabScreenProps } from '../types';
import { Text, View } from '../components/Themed';
import Frequencies from '../constants/Frequencies';
import getEstimatedScore from '../utils/score_function';

const baseURL = "https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello"
const notes = {
  60: new Tone.Buffer(`${baseURL}/C4.mp3`),
  61: new Tone.Buffer(`${baseURL}/Cs4.mp3`),
  62: new Tone.Buffer(`${baseURL}/D4.mp3`),
  63: new Tone.Buffer(`${baseURL}/Ds4.mp3`),
  64: new Tone.Buffer(`${baseURL}/E4.mp3`),
  65: new Tone.Buffer(`${baseURL}/F4.mp3`),
  66: new Tone.Buffer(`${baseURL}/Fs4.mp3`),
  67: new Tone.Buffer(`${baseURL}/G4.mp3`),
  68: new Tone.Buffer(`${baseURL}/Gs4.mp3`),
  69: new Tone.Buffer(`${baseURL}/A4.mp3`),
  71: new Tone.Buffer(`${baseURL}/B4.mp3`),
}

const sampler = new Tone.Sampler({
  urls: notes, release: 1
}).toDestination();

// To be rendered only once
let goalNoteInterval: NodeJS.Timeout;
let playingInterval: NodeJS.Timeout;

export default function TabOneScreen(
  { navigation }: RootTabScreenProps<'TabOne'>
) {
  const [frequency, setFrequency, frequencyRef] = useState(0);
  const [goalFreq, setGoalFreq, goalFreqRef] = useState(440);
  const [_, setIsPressing, pressingRef] = useState(false);
  const [goalNote, setGoalNote] = useState("A4");
  const [score, setScore] = useState(0);

  const playDebouncedNote = useMemo(() => {
    return debounce(() =>  {
      clearInterval(playingInterval);
      if (!pressingRef.current) return;

      playingInterval = setInterval(() => {
        const currentFreq = frequencyRef.current;
        sampler.triggerAttackRelease(currentFreq, "1n");
      }, 1000);
    }, 700);
  }, []);

  const playNoteThrottled = useMemo(() => {
    return throttle((freq: number) => {
      sampler.triggerAttackRelease(freq, "2n");
    }, 1000);
  }, []);  

  function startPlaying() {
    setIsPressing(true);
  }
  function releasePlaying() {
    setIsPressing(false);
  } 

  function startChangeNoteInterval() {
    function changeNote() {
      const freqArray = Object.entries(Frequencies);
      const length = freqArray.length;
      const choice = Math.floor(Math.random() * length);
      setGoalNote(freqArray[choice][0]);
      setGoalFreq(freqArray[choice][1]);
    }
    changeNote();

    clearInterval(goalNoteInterval);
    goalNoteInterval = setInterval(() => {
      const currentFreq = frequencyRef.current;
      const currentGoal = goalFreqRef.current;
      const frequencyList = Object.values(Frequencies);
      const estimatedScore = getEstimatedScore(
        currentFreq, currentGoal, frequencyList);
      setScore(prevScore => prevScore + estimatedScore);
      changeNote();
    }, 1000 * 10);
  }

  function handleFrequencyChange(evt: any) {
    const newFreq = evt.target.value;
    playNoteThrottled(parseInt(newFreq));
    setFrequency(parseInt(newFreq));
    playDebouncedNote();
  }

  useEffect(() => {
    if (frequency === goalFreq) {
      setScore(prevScore => prevScore + 100);
      startChangeNoteInterval();
    }
  }, [frequency, goalFreq]);

  useEffect(() => {
   startChangeNoteInterval();
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        Find {goalNote}! You're with {score} points!
      </Text>
      <View style={styles.separator} lightColor="#eee"
            darkColor="rgba(255,255,255,0.4)" />
      <Text>{frequency}</Text>
      <input type="range" value={frequency} 
             onChange={handleFrequencyChange}
             min={262} max={494} step={1}
             onMouseDown={startPlaying}
             onMouseUp={releasePlaying}/>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  separator: {
    marginVertical: 30,
    height: 1,
    width: '80%',
  },
});

import { StyleSheet } from 'react-native';

import React, { useEffect, useState, useMemo } from 'react';
import { Text, View } from '../components/Themed';
import { RootTabScreenProps } from '../types';
import Frequencies from '../constants/Frequencies';

import debounce from "lodash.debounce";
import throttle from 'lodash.throttle';

import * as Tone from 'tone';
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

// To be accessed by interval functions
let goalNoteInterval: NodeJS.Timeout;
let playingInterval: NodeJS.Timeout;
let isPressing: boolean = false;

let frequency = 0;
let goalFreq = 0;

export default function TabOneScreen(
  { navigation }: RootTabScreenProps<'TabOne'>
) {
  const [goalNote, setGoalNote] = useState("A4");
  const [freqState, setFreqState] = useState(0);
  const [score, setScore] = useState(0);

  const playDebouncedNote = useMemo(() => {
    return debounce(() =>  {
      clearInterval(playingInterval);
      if (!isPressing) return;
      playingInterval = setInterval(() => {
        sampler.triggerAttackRelease(frequency, "1n");
      }, 1000);
    }, 700);
  }, []);

  const playNoteThrottled = useMemo(() => {
    return throttle((freq: number) => {
      sampler.triggerAttackRelease(freq, "2n");
    }, 1000);
  }, []);  

  function startPlaying() {
    isPressing = true;
  }
  function releasePlaying() {
    isPressing = false;
    clearInterval(playingInterval);
  } 

  function startChangeNoteInterval() {
    function changeNote() {
      const freqArray = Object.entries(Frequencies);
      const length = freqArray.length;
      const choice = Math.floor(Math.random() * length);
      setGoalNote(freqArray[choice][0]);
      goalFreq = freqArray[choice][1];
    }
    changeNote();

    clearInterval(goalNoteInterval);
    goalNoteInterval = setInterval(() => {
      const estimatedScore = getEstimatedScore(
        frequency, goalFreq, Object.values(Frequencies));
      setScore(prevScore => prevScore + estimatedScore);
      changeNote();
    }, 1000 * 10);
  }

  function setFrequency(newValue: number) {
    frequency = newValue;
    setFreqState(newValue);
  }

  function handleFrequencyChange(evt: any) {
    const newFreq = evt.target.value;
    playNoteThrottled(parseInt(newFreq));
    setFrequency(parseInt(newFreq));
    playDebouncedNote();
  }

  useEffect(() => {
    if (freqState === goalFreq) {
      setScore(prevScore => prevScore + 100);
      startChangeNoteInterval();
    }
  }, [freqState, goalFreq]);

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
      <Text>{freqState}</Text>
      <input type="range" value={freqState} 
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

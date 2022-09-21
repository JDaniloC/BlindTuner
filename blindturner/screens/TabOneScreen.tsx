import { StyleSheet } from 'react-native';

import { Text, View } from '../components/Themed';
import { RootTabScreenProps } from '../types';

import * as Tone from 'tone'
import React, { useEffect, useState } from 'react';

const baseURL = "https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/"
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
const frequencies = {
 "C4":  262, 
 "Cs4": 277,
 "D4":  294,
 "Ds4": 311,
 "E4":  330,
 "F4":  349,
 "Fs4": 370,
 "G4":  392,
 "Gs4": 415,
 "A4":  440,
 "B4":  494 
}
let interval: NodeJS.Timeout;

export default function TabOneScreen({ navigation }: RootTabScreenProps<'TabOne'>) {
  const [frequency, setFrequency] = useState(262);
  const [goalNote, setGoalNote] = useState("A4");
  const [goalFreq, setGoalFreq] = useState(440);
  const [score, setScore] = useState(0);
  
  const sampler = new Tone.Sampler({
    urls: notes,
    release: 2,
  }).toDestination();

  function startChangeNoteInterval() {
    function changeNote() {
      const freqArray = Object.entries(frequencies);
      const length = freqArray.length;
      const choice = Math.floor(Math.random() * length);
      setGoalFreq(freqArray[choice][1]);
      setGoalNote(freqArray[choice][0]);
    }
    changeNote();

    clearInterval(interval);
    interval = setInterval(() => {
      changeNote();
    }, 1000 * 10);
  }

  function handleFrequencyChange(evt: any) {
    const newFreq = evt.target.value;
    setFrequency(parseInt(newFreq))
    sampler.triggerAttackRelease(newFreq, '8n');
    sampler.triggerRelease()
  }
  
  useEffect(() => {
    if (frequency === goalFreq) {
      setScore(prevScore => prevScore + 1);
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
            darkColor="rgba(255,255,255,0.1)" />
      <Text>{frequency}</Text>
      <input type="range" value={frequency} min={262} max={494} step={1}
          onChange={handleFrequencyChange}/>
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

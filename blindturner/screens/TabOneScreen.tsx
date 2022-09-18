import { StyleSheet } from 'react-native';

import { Text, View } from '../components/Themed';
import { RootTabScreenProps } from '../types';

import * as Tone from 'tone'
import React from 'react';

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
  262: "C4.mp3",
  277: "Cs4.mp3",
  294: "D4.mp3",
  311: "Ds4.mp3",
  330: "E4.mp3",
  349: "F4.mp3",
  370: "Fs4.mp3",
  392: "G4.mp3",
  415: "Gs4.mp3",
  440: "A4.mp3",
  494: "B4.mp3",
}

export default function TabOneScreen({ navigation }: RootTabScreenProps<'TabOne'>) {
  const [value, setValue] = React.useState(262);
  
  const sampler = new Tone.Sampler({
          urls: notes,
          release: 2,
      }).toDestination();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        ToneJS testing
      </Text>
      <View style={styles.separator} lightColor="#eee"
            darkColor="rgba(255,255,255,0.1)" />
      <Text>{value}</Text>
      <input type="range" value={value} min={262} max={494} step={1}
          onChange={(evt) => {
            setValue(parseInt(evt.target.value))
            sampler.triggerAttackRelease(evt.target.value, '8n');
          }}/>
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

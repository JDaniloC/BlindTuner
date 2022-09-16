import { StyleSheet } from 'react-native';

import { Text, View } from '../components/Themed';
import { RootTabScreenProps } from '../types';

import * as Tone from 'tone'
import React from 'react';

export default function TabOneScreen({ navigation }: RootTabScreenProps<'TabOne'>) {
  const [value, setValue] = React.useState(110);

  const sampler = new Tone.Sampler({
          urls: {
            C4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/C4.mp3"),
            D4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/D4.mp3"),
            E4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/E4.mp3"),
            F4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/F4.mp3"),
            G4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/G4.mp3"),
            A4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/A4.mp3"),
            B4: new Tone.Buffer("https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/master/samples/cello/B4.mp3"),
          },
          release: 5,
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

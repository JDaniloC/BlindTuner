import { Button, StyleSheet, TouchableOpacity } from 'react-native';

import { Text, View } from '../components/Themed';
import { RootTabScreenProps } from '../types';

import * as Tone from 'tone'
import React from 'react';
import { useEffect } from 'react';

export default function TabOneScreen({ navigation }: RootTabScreenProps<'TabOne'>) {
  const [value, setValue] = React.useState(110);
  const synth = new Tone.Synth().toDestination();

  useEffect(() => {
    const now = Tone.now()
    synth.triggerAttackRelease(value, '8n', now);
  }, [value]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        ToneJS testing
      </Text>
      <View style={styles.separator} lightColor="#eee" darkColor="rgba(255,255,255,0.1)" />
      <Text>{value}</Text>
      <input type="range" value={value} min={110} max={1661.21} step={1}
          onChange={(evt) => {setValue(parseInt(evt.target.value))}}/>
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

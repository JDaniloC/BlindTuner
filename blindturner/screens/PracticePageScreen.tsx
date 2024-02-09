import { Dimensions, Pressable, StyleSheet, Image } from 'react-native';
import React, { useMemo, useState } from 'react';
import throttle from 'lodash.throttle';

import { preset5 } from '../constants/NoteColors';
import { Text, View } from '../components/Themed';

import { frequencyNames } from "../constants/Frequencies";
import { back } from '../assets/images/character';
import sampler from '../utils/tonejsSampler';
import ImageFunction from '../utils/imageFunction';

let playingInterval: NodeJS.Timeout;
const deviceWidth = Dimensions.get('window').width;
const noteArray = Object.entries(frequencyNames).map(
  ([key, value], index) => {
    const colors = Object.entries(preset5)[index]
    const [name, color] = colors;
    return { key, name, color, value };
})

export default function PracticePage() {
  const [imagePath, setImagePath] = useState(back);

  const playNoteThrottled = useMemo(() => {
    return throttle((freq: number) => {
      sampler.triggerAttackRelease(freq, "2n");
    }, 1000);
  }, []);

  function handleOnPress(frequency: number) {
    setImagePath(ImageFunction(frequency));
    playNoteThrottled(frequency);
  }
  function handleLongPress(frequency: number) {
    playNoteThrottled(frequency);
    playingInterval = setInterval(() => {
      sampler.triggerAttackRelease(frequency, "1n");
    }, 900);
  }
  function handleOnRelease() {
    clearInterval(playingInterval);
  } 

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Clique na nota!</Text>
      <Image source={imagePath} style={styles.image}/>
      <View
        style={styles.separator}
        lightColor="#eee"
        darkColor="rgba(255,255,255,0.1)"
      />
      <View style={styles.notesContainer}>
        {noteArray.map((note) => (
          <Pressable
            key={note.key}
            delayLongPress={900}
            style={[ styles.textBox, { backgroundColor: note.color }]}
            onPressOut={handleOnRelease}
            onPressIn={() => handleOnPress(note.value)}
            onLongPress={() => handleLongPress(note.value)}
          >
            <Text style={styles.font}>{note.name}</Text>
            <Text style={styles.subTitle}>{note.value}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
  },
  title: {
    fontSize: 30,
    fontWeight: 'bold',
    fontFamily: 'dosis',
  },
  separator: {
    marginVertical: 30,
    height: 1,
    width: '80%',
  },
  image: {
    width: '110px',
    height: '150px',
    stroke: 'white'
  },
  notesContainer: {
    height: 100,
    display: 'flex',
    flexWrap: 'wrap',
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  font: {
    fontFamily: 'dosis',
    fontWeight: 'bold',
    fontSize: 30,
  },
  textBox: {
    flex: 1,
    flexBasis: 0.2 * deviceWidth,
    padding: "1em",
    margin: ".2em",
    display: 'flex',
    borderRadius: 4,
    alignItems: 'center',
    flexDirection: 'column',
  },
  subTitle: {
    fontSize: 20,
  },
});

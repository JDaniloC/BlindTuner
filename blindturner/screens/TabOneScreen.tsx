import {
  Image,
  Pressable,
  StyleSheet,
  ScrollView,
  NativeScrollEvent
} from 'react-native';
import { NativeSyntheticEvent } from 'react-native';
import React, { useEffect, useMemo } from 'react';
import useState from 'react-usestateref'

import throttle from 'lodash.throttle';

import { RootTabScreenProps } from '../types';
import { Text, View } from '../components/Themed';

import { frequencyNames, frequencyValues } from '../constants/Frequencies';
import getEstimatedScore from '../utils/scoreFunction';
import ImageFunction from '../utils/ImageFunction';
import sampler from '../utils/tonejsSampler';

import { back } from '../assets/images/character';
import Direction from '../components/Direction';

// To be rendered only once
let goalNoteInterval: NodeJS.Timeout;
let playingInterval: NodeJS.Timeout;

export default function TabOneScreen(
  { navigation }: RootTabScreenProps<'TabOne'>
) {
  const [frequency, setFrequency, frequencyRef] = useState(262);
  const [goalFreq, setGoalFreq, goalFreqRef] = useState(440);
  const [goalNote, setGoalNote] = useState("A4");
  const [score, setScore] = useState(0);
  const [imagePath, setImagePath] = useState(back);
  const [direction, setDirection] = useState("up");

  const playNoteThrottled = useMemo(() => {
    return throttle((freq: number) => {
      sampler.triggerAttackRelease(freq, "2n");
    }, 1000);
  }, []);  

  function handleOnPress() {
    playNoteThrottled(frequency);
  }
  function handleLongPress() {
    playNoteThrottled(frequency);
    playingInterval = setInterval(() => {
      sampler.triggerAttackRelease(frequency, "1n");
    }, 900);
  }
  function handleOnRelease() {
    clearInterval(playingInterval);
  } 

  function startChangeNoteInterval() {
    function changeNote() {
      const freqArray = Object.entries(frequencyNames);
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
      const estimatedScore = getEstimatedScore(
        currentFreq, currentGoal, frequencyValues);
      setScore(prevScore => prevScore + estimatedScore);
      changeNote();
    }, 1000 * 10);
  }

  function handleFrequencyChange(newFrequency: number) {
    if (newFrequency > frequency
        && direction !== "up") {
      setDirection("up");
    } else if (newFrequency < frequency
               && direction !== "down") {
      setDirection("down");
    }
    setImagePath(ImageFunction(newFrequency));
    playNoteThrottled(newFrequency);
    setFrequency(newFrequency);
  }

  function handleScroll(event: NativeSyntheticEvent<NativeScrollEvent>) {
    const { y } = event.nativeEvent.contentOffset;
    const maxRange = 494 - 262;
    const percentage = y / 1000;
    const normalized = percentage * maxRange;
    const newFreq = Math.floor(normalized) + 262;
    handleFrequencyChange(newFreq);
  };

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
      <Image source={imagePath} style={styles.image}/>
      <View style={styles.separator} lightColor="#eee"
            darkColor="rgba(255,255,255,0.4)" />
      <Text>{frequency}</Text>
      <View style={{flex: 1, width: "100%"}}>
        <Direction 
          color={"white"}
          style={styles.overlayImage}
          down={direction}
        />
        <ScrollView
          onScroll={handleScroll}
          scrollEventThrottle={1} 
          style={styles.scrollContainer}
          showsVerticalScrollIndicator={false}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.scrollViewContainer}
        >
          <Pressable
            style={styles.scrollItem}
            delayLongPress={900}
            onPressIn={handleOnPress}
            onPressOut={handleOnRelease}
            onLongPress={handleLongPress}
          >
            <Text style={styles.scrollItem}>
            </Text>
          </Pressable>
        </ScrollView>
      </View>
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
  scrollContainer: {
    cursor: "grab",
    width: "100%",
    maxHeight: "100%",
  },
  scrollViewContainer: {
    width: "100%",
    height: "calc(100% + 1000px)",
  },
  scrollItem: {
    width: "100%",
    height: "100%",
  },
  image: {
    width: '110px',
    height: '130px',
    stroke: 'white'
  },
  overlayImage: {
    width: '100%',
    height: '100%',
    position: 'absolute',
    top: 0,
    left: 0,
  }
});

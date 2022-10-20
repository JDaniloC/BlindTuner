import {
  Pressable,
  StyleSheet,
  ScrollView,
  NativeScrollEvent,
  Animated
} from 'react-native';
import { NativeSyntheticEvent } from 'react-native';
import React, { useEffect, useMemo } from 'react';
import useState from 'react-usestateref'

import throttle from 'lodash.throttle';

import { RootTabScreenProps } from '../types';
import { Text, View } from '../components/Themed';

import ImageFunction from '../utils/ImageFunction';
import sampler from '../utils/tonejsSampler';

import { back } from '../assets/images/character';
import Direction from '../components/Direction';
import { InfoHeader } from '../components/InfoHeader';

// To be rendered only once
const timeToScore = 30;
let playingInterval: NodeJS.Timeout;
let countdownTimeout: NodeJS.Timeout;

export default function GamePage(
  { navigation }: RootTabScreenProps<'GamePage'>
) {
  const [animation, _] = useState(new Animated.Value(0))
  const [frequency, setFrequency, freqRef] = useState(262);
  const [imagePath, setImagePath] = useState(back);
  const [direction, setDirection] = useState("up");
  const [time, setTime, timeRef] = useState(0);

  function startAnimation() {
    Animated.loop(
      Animated.sequence([
        Animated.timing(animation, {
          toValue: 100,
          duration: 50,
          useNativeDriver: true
        }),
        Animated.spring(animation, {
          toValue: 0,
          speed: 50,
          useNativeDriver: true
        })
      ])
    ).start();
  }

  useEffect(() => {
    if (time > 0) {
      if (time === 10) {
        startAnimation();
      }
      clearTimeout(countdownTimeout);
      countdownTimeout = setTimeout(() => {
        setTime(time - 1);
      }, 1000)
    }
  }, [time])

  const animatedStyles = {
    jumpCharacter: {
      transform: [
        {
          translateY: animation.interpolate({
            inputRange: [0, 100],
            outputRange: [0, -10]
          })
        }
      ]
    }
  }

  const playNoteThrottled = useMemo(() => {
    return throttle((freq: number) => {
      sampler.triggerAttackRelease(freq, "2n");
    }, 1000);
  }, []);  

  function resetTime() {
    setTime(timeToScore);
    animation.stopAnimation();
  }

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

  return (
    <View style={styles.container}>
      <InfoHeader
        limitTime={timeToScore}
        frequencyRef={freqRef}
        resetTime={resetTime}
        timeRef={timeRef}
      />
      <Animated.Image source={imagePath} style={[
        styles.image, animatedStyles.jumpCharacter]}/>
      <View style={styles.separator} lightColor="#eee"
            darkColor="rgba(255,255,255,0.4)" />
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
  separator: {
    marginVertical: 30,
    height: 1,
    width: '80%',
  },
  scrollContainer: {
    width: "100%",
    cursor: "grab",
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

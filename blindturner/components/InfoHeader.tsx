import { StyleSheet, Animated, DimensionValue } from 'react-native';
import React, { memo, useEffect } from 'react';
import useState from 'react-usestateref'

import { frequencyNames, frequencyValues } from '../constants/Frequencies';
import getEstimatedScore from '../utils/scoreFunction';

import { Text, View } from './Themed';
import { preset5 } from '../constants/NoteColors';

interface InfoHeaderProps {
  frequencyRef: React.MutableRefObject<number>;
  timeRef: React.MutableRefObject<number>;
  resetTime: () => void;
  limitTime: number;
}

let goalNoteInterval: NodeJS.Timeout;

export function InfoHeader({
  frequencyRef, timeRef, limitTime, resetTime
}: InfoHeaderProps) {
  const [animation, _] = useState(new Animated.Value(0))
  const [scoreEarned, setScoreEarned] = useState(0);
  const [score, setScore] = useState(0);

  const [noteName, setNoteName] = useState("A4");
  const [goalColor, setGoalColor] = useState("black");
  const [freqColor, setFreqColor] = useState("black");
  const [goalFreq, setGoalFreq, goalFreqRef] = useState(440); 

  const animatedStyles = {
    upperAndShow: {
      transform: [
        {
          scale: animation.interpolate({
            inputRange: [0, 100],
            outputRange: [1, 1.5]
          })
        }
      ],
      opacity: animation.interpolate({
        inputRange: [0, 100],
        outputRange: [0, 1]
      })
    },
  }

  function startScoreAnimation(newScoredEarned: number) {
    setScoreEarned(newScoredEarned);
    Animated.sequence([
      Animated.timing(animation, {
        toValue: 100,
        duration: 700,
        useNativeDriver: true
      }),
      Animated.spring(animation, {
        toValue: 0,
        useNativeDriver: true
      })
    ]).start()
  }

  function startChangeNoteInterval() {
    function changeNote() {
      const freqArray = Object.entries(frequencyNames);
      const length = freqArray.length;
      let choice = Math.floor(Math.random() * length);
      while (freqArray[choice][1] === goalFreq) {
        choice = Math.floor(Math.random() * length);
      }
      const color = Object.values(preset5)[choice];
      setNoteName(freqArray[choice][0]);
      setGoalFreq(freqArray[choice][1]);
      setGoalColor(color);
      resetTime();
    }
    changeNote();

    clearInterval(goalNoteInterval);
    goalNoteInterval = setInterval(() => {
      const currentFreq = frequencyRef.current;
      const currentGoal = goalFreqRef.current;
      const estimatedScore = getEstimatedScore(
        currentFreq, currentGoal, frequencyValues);
      if (estimatedScore > 0) {
        setScore(prevScore => prevScore + estimatedScore);
        startScoreAnimation(estimatedScore);
      }
      changeNote();
    }, 1000 * limitTime);
  }
  
  function handleFrequencyColor() {
    const length = frequencyValues.length;
    for (let index = 0; index < length; index++) {
      const frequency = frequencyValues[index];
      if (frequencyRef.current <= frequency) {
        const colors = Object.values(preset5);
        setFreqColor(colors[index]);
        break
      }
    }
  }

  

  useEffect(() => {
   startChangeNoteInterval();
  }, []);

  useEffect(() => {
    if (frequencyRef.current === goalFreq) {
      setScore(prevScore => prevScore + 100);
      startChangeNoteInterval();
      startScoreAnimation(100);
    }
    handleFrequencyColor();
  }, [frequencyRef.current, goalFreq]);

  return (
    <View style={styles.container}>
      <View style={[styles.textBox, {
        backgroundColor: freqColor
      }]}>
        <Text style={styles.font}>
          {frequencyRef.current} Hz
        </Text>
        <Text style={styles.subTitle}>
          Frequência atual
        </Text>
      </View>
      <View style={[styles.textBox, {
        backgroundColor: goalColor,
      }]}>
        <Text style={styles.font}>
          {noteName} {goalFreq} Hz
        </Text>
        <Text style={styles.subTitle}>
          Nota alvo
        </Text>
      </View>
      <View style={styles.textBox}>
        <Text style={styles.font}>
          {score}
        </Text>
        <Text style={styles.subTitle}>
          Pontos ganhos
        </Text>
        <Animated.Text style={[
          styles.scoreText,
          animatedStyles.upperAndShow,
        ]}>
          +{scoreEarned}
        </Animated.Text>
      </View>
      <View style={styles.textBox}>
        <Text style={styles.font}>
          {timeRef.current} sec
        </Text>
        <Text style={styles.subTitle}>
          Tempo
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: "100%",
    marginTop: "1em" as DimensionValue,
    marginBottom: "1em" as DimensionValue,
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
  },
  font: {
    fontFamily: 'dosis',
    fontWeight: 'bold',
    fontSize: 30,
  },
  textBox: {
    padding: "1em" as DimensionValue,
    display: 'flex',
    borderRadius: 4,
    alignItems: 'center',
    flexDirection: 'column',
  },
  subTitle: {
    fontSize: 10,
  },
  scoreText: {
    position: 'absolute',
    fontFamily: 'dosis',
    color: '#4ed474',
    fontSize: 30,
    right: "-2em" as DimensionValue
  }
});

export default memo(InfoHeader);
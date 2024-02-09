import React, { memo , useEffect } from 'react';
import { StyleSheet } from 'react-native';
import useColorScheme from '../hooks/useColorScheme';

const amountArray = Array.from({ length: 5 }, (v, i) => i);
const rotateStyle = "scaleY(-1) translateY(-100%)";

interface DirectionProps {
  down: string,
  style?: any
}

function Direction({ down, style }: Readonly<DirectionProps>) {
  const colorScheme = useColorScheme();

  const [transform, setTransform] = React.useState("");
  useEffect(() => {
    setTransform(down === "down" ? rotateStyle : "");
  }, [down]);

  return (
    <div style={{ ...style, ...styles.rowContainer }}>
      {amountArray.map((row) => (
        <div key={row} style={styles.columnContainer}>
          {amountArray.map((column) => (
            <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
              key={column} width="100" height="100"
              style={{ stroke: colorScheme === 'dark' ? 'white' : 'black' }}>
              <polyline
                strokeWidth="20" fill="none"
                points="10 70 50 20 90 70"
                strokeLinecap="butt"
                strokeLinejoin="miter"
                style={{ transform: transform }}
              />
            </svg>
          ))}
        </div>
      ))}
    </div>
  );
}

const styles = StyleSheet.create({
  rowContainer: {
    overflow: "hidden",
    width: "100%",
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-around',
  },
  columnContainer: {
    height: 100,
    display: 'flex',
    justifyContent: 'space-around',
  }
});

export default memo(Direction);
import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { Platform, StyleSheet } from 'react-native';

import { Text, View } from '../components/Themed';
import Tutorial from '../components/Tutorial';

export default function ModalScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}> Como jogar? </Text>
      <View style={styles.separator}
            lightColor="#eee"
            darkColor="rgba(255,255,255,0.1)"
      />
      <Tutorial/>
      <StatusBar style={Platform.OS === 'ios' ? 'light' : 'auto'} />
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
    fontSize: 30,
    fontWeight: 'bold',
  },
  separator: {
    marginVertical: 30,
    height: 1,
    width: '80%',
  },
});

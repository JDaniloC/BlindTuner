import { View, Text } from '../components/Themed';
import { StyleSheet } from 'react-native';
import React from 'react';

export default function Tutorial() {
    return (
        <View style={styles.container}>
            <View style={styles.section}>
                <Text style={styles.title}>
                    Qual a motivação do jogo?
                </Text>
                <Text style={styles.text}>
                    Praticar a audição em relação à notas musicais, evitando a necessidade de utilizar afinadores na afinação dos instrumentos musicais.
                </Text>
            </View>

            <View style={styles.section}>
                <Text style={styles.title}>
                    Qual o objetivo do jogo?
                </Text>
                <Text style={styles.text}>
                    Você precisa sintonizar a frequência correta ou aproximada de cada nota exibida, através da nota emita com ajuda de cores e padrões. 
                </Text>
            </View>

            <View style={styles.section}>
                <Text style={styles.title}>
                    Como controlar?
                </Text>
                <Text style={styles.text}>
                    Você pode "rolar" a tela a partir da parte central do jogo, dessa forma, é possível emitir frequências mais agudas e graves. Lembrando que você tem um tempo para acertar a frequência correta, e quanto mais próximo da frequência correta, mais pontos você irá ganhar.
                </Text>
            </View>
        </View>
    )
}

const styles = StyleSheet.create({
    container: {
        maxWidth: 900,
        textAlign: 'left',
        justifyContent: 'center',
    },
    section: {
        marginBottom: 20,
    },
    title: {
        fontSize: 20,
        fontWeight: 'bold',
    },
    text: {
        fontSize: 15,
        fontWeight: 'normal',
    },
});
        
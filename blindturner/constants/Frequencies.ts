const frequencyNames = {
    "C4":  262, 
    "Cs4": 277,
    "D4":  294,
    "Ds4": 311,
    "E4":  330,
    "F4":  349,
    "Fs4": 370,
    "G4":  392,
    "Gs4": 415,
    "A4":  440,
    "B4":  494 
};

const frequencyValues = Object.values(frequencyNames);

const frequencyTones = [ 262, 294, 330, 349, 392, 440, 494 ];

const avgedFrequencies = frequencyTones.map((frequency, index, array) => {
    if (index === 0) return frequency;
    const prevFrequency = frequencyTones[index - 1];
    return (frequency + prevFrequency) / 2;
}).slice(1);


export { frequencyNames, frequencyValues, frequencyTones, avgedFrequencies };
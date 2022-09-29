export default function getEstimatedScore(
    currentFrequency: number,
    targetFrequency: number,
    frequencyList: number[],
) {
    if (currentFrequency === targetFrequency) return 100;

    const index = frequencyList.indexOf(targetFrequency);
    const prevIndex = Math.max(0, index - 1);
    const lastIndex = frequencyList.length - 1;
    const nextIndex = Math.min(lastIndex, index + 1);

    const prevFrequency = frequencyList[prevIndex];
    const nextFrequency = frequencyList[nextIndex];

    let difference = targetFrequency - currentFrequency;
    let distance = targetFrequency - prevFrequency;
    if (currentFrequency > targetFrequency) {
        difference = currentFrequency - targetFrequency;
        distance = nextFrequency - targetFrequency;
    }

    if (distance <= 0) distance = 5;
    const percentage = 1 - difference / distance;
    return Math.max(0, Math.round(percentage * 100));
}
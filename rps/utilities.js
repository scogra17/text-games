const prompt = function (msg) {
  console.log(`=> ${msg}`);
};

const invalidYesNoAnswer = function(answer) {
  return !['y', 'n'].includes(answer);
};

module.exports = {
  prompt: prompt,
  invalidYesNoAnswer: invalidYesNoAnswer,
};

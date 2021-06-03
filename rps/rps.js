/* eslint-disable max-lines-per-function */

const readline = require('readline-sync');
const CONFIG = require('./rock_paper_scissors.json');
const GAME_RULES = CONFIG.game_rules;
const VALID_MOVES = CONFIG.valid_moves;
const UTILITIES = require('./utilities');
const DISPLAY_ASSETS = require('./display_assets');
const GAMES_NEEDED_TO_WIN_MATCH = 2;


function createPlayer() {
  return {
    move: null,
    score: 0,
    moves: {},
    isGameWinner: false,

    getMove() {return this.move},
    setMove(value) {this.move = value},
    getScore() {return this.score},
    getMoves() {return this.moves},
    getIsGameWinner() {return this.isGameWinner},
    setIsGameWinner(value) {this.isGameWinner = value},
    isMatchWinner() {return this.score === GAMES_NEEDED_TO_WIN_MATCH},
    resetScore() {this.score = 0},

    winGame() {
      this.score += 1;
      this.isGameWinner = true;
    },

    updateMoves(move) {
      if (this.moves[move]) {
        this.moves[move] += 1;
      } else this.moves[move] = 1;
    },
  };
}

function createComputer() {
  let playerObject = createPlayer();

  let computerObject = {
    // calculateWeightedMoves determines which moves the computer should
    // favor based on the player's history
    calculateWeightedMoves(playerMoves, validMoves) {
      let weightedMoves = validMoves.slice();
      for (let move in playerMoves) {
        let moveCount = playerMoves[move];
        let moveDefeatedBy = GAME_RULES[move].defeated_by;
        for (let iterations = 0; iterations < moveCount; iterations += 1) {
          weightedMoves = weightedMoves.concat(moveDefeatedBy);
        }
      }
      return weightedMoves;
    },

    choose(playerMoves, validMoves = VALID_MOVES.rps) {
      let choices = this.calculateWeightedMoves(playerMoves, validMoves);
      let randomIndex = Math.floor(Math.random() * choices.length);
      this.move = choices[randomIndex];
    }
  };
  return Object.assign(playerObject, computerObject);
}

function createHuman() {
  let playerObject = createPlayer();

  let humanObject = {
    choose(_, validMoves = VALID_MOVES.rps) {
      let choice;
      console.clear();
      while (true) {
        console.log(`Please choose ${validMoves.join(', ')}:`);
        choice = readline.question();
        if (validMoves.includes(choice)) break;
        console.log('Sorry, invalid choice.');
      }
      this.move = choice;
    }
  };
  return Object.assign(playerObject, humanObject);
}

function createGameBoard(human, computer) {
  return {
    human: human,
    computer: computer,

    setHuman(value) {this.human = value},
    setComputer(value) {this.computer = value},

    combineAssets(...assets) {
      let assetsCombined = assets.map(elem => {
        return elem.split('\n');
      });

      let combinedDisplay = assetsCombined[0].map((elem, idx) => {
        let line = elem;
        for (let asset = 1; asset < assetsCombined.length; asset += 1) {
          line += assetsCombined[asset][idx];
        }
        return line + '\n';
      }).join('');

      return combinedDisplay;
    },

    displayMoves() {
      console.clear();
      let combinedDisplay = this.combineAssets(
        DISPLAY_ASSETS.yourMove + DISPLAY_ASSETS[this.human.getMove()],
        DISPLAY_ASSETS.computerMove + DISPLAY_ASSETS[this.computer.getMove()]
      );
      console.log(`${combinedDisplay}`);
    },

    displayWelcomeMessage() {
      console.clear();
      let combinedDisplay = this.combineAssets(
        DISPLAY_ASSETS.rock, DISPLAY_ASSETS.paper, DISPLAY_ASSETS.scissors
      );
      console.log(DISPLAY_ASSETS.welcomeRPS + combinedDisplay);
      console.log(`Win the match by being the first to win ${GAMES_NEEDED_TO_WIN_MATCH} games.`);
    },

    displayGoodbyeMessage() {
      console.log('Thanks for playing Rock, Paper, Scissors. Goodbye!');
    },

    displayGameTypes() {
      console.clear();
      let combinedDisplay = this.combineAssets(
        DISPLAY_ASSETS.lizard, DISPLAY_ASSETS.spock
      );
      console.log(DISPLAY_ASSETS.optionLS + combinedDisplay);
    },

    displayGameWinner() {
      if (this.human.getIsGameWinner()) {
        console.log(DISPLAY_ASSETS.youWin);
      } else if (this.computer.getIsGameWinner()) {
        console.log(DISPLAY_ASSETS.computerWins);
      } else {
        console.log(DISPLAY_ASSETS.tie);
      }
    }
  };
}

const RPSGame = {
  human: createHuman(),
  computer: createComputer(),
  gameBoard: createGameBoard(),
  validMoves: null,

  getValidMoves() {return this.validMoves},
  setValidMoves(value) {this.validMoves = value},

  resetGameBoard() {
    this.gameBoard.setHuman(this.human);
    this.gameBoard.setComputer(this.computer);
  },

  updatePlayerMoves() {
    this.human.updateMoves(this.human.move);
    this.computer.updateMoves(this.computer.move);
  },

  determineWinner() {
    let humanMove = this.human.move;
    let computerMove = this.computer.move;

    this.updatePlayerMoves();

    if (GAME_RULES[humanMove].defeats.includes(computerMove)) {
      this.human.winGame();
    } else if (GAME_RULES[computerMove].defeats.includes(humanMove)) {
      this.computer.winGame();
    }
  },

  playAgain() {
    UTILITIES.prompt('Next game? (y/n)');
    let answer = readline.question();
    return answer.toLowerCase()[0] === 'y';
  },

  newMatch() {
    UTILITIES.prompt('New match? (y/n)');
    let answer = readline.question();
    return answer.toLowerCase()[0] === 'y';
  },

  displayMatchSummary() {
    console.log(`Your win count: ${this.human.getScore()}`);
    console.log(`Computer win count: ${this.computer.getScore()}`);
  },

  isMatchOver() {
    return this.human.isMatchWinner() || this.computer.isMatchWinner();
  },

  displayMatchWinner() {
    if (this.human.isMatchWinner()) {
      console.log(DISPLAY_ASSETS.youWinMatch);
    } else if (this.computer.isMatchWinner()) {
      console.log(DISPLAY_ASSETS.computerWinsMatch);
    }
  },

  selectGameType() {
    this.gameBoard.displayGameTypes();
    UTILITIES.prompt('Would you like to include additional moves? (y/n)');
    let answer = readline.question();
    if (answer.toLowerCase()[0] === 'y') {
      this.setValidMoves(VALID_MOVES.rpsls);
    } else {
      this.setValidMoves(VALID_MOVES.rps);
    }
  },

  resetMatch() {
    this.human.resetScore();
    this.computer.resetScore();
    this.selectGameType();
  },

  resetGame() {
    this.human.setIsGameWinner(false);
    this.computer.setIsGameWinner(false);
  },

  continueGame() {
    readline.question('Click any key to continue:');
  },

  play() {
    this.gameBoard.displayWelcomeMessage();
    this.continueGame();
    while (true) {
      this.resetMatch();
      this.resetGameBoard();
      // Individual game loop
      while (true) {
        this.resetGame();
        this.human.choose(null, this.getValidMoves());
        this.computer.choose(this.human.getMoves(), this.getValidMoves());
        this.gameBoard.displayMoves();
        this.determineWinner();
        this.gameBoard.displayGameWinner();
        this.displayMatchSummary();
        if (this.isMatchOver()) break;
        if (!this.playAgain()) break;
      }
      this.displayMatchWinner();
      if (!this.newMatch()) break;
    }
    this.gameBoard.displayGoodbyeMessage();
  }
};

RPSGame.play();

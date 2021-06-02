const readline = require('readline-sync');
const CONFIG = require('./rock_paper_scissors.json');
const GAME_RULES = CONFIG.game_rules;
const GAME_BOARD_ASSETS = CONFIG.game_board_assets;
const VALID_MOVE_CHOICES = Object.keys(GAME_RULES);
const GAMES_NEEDED_TO_WIN_MATCH = 2;


function createPlayer() {
  return {
    move: null,
    score: 0,
    moves: {},

    getMove() {return this.move},

    setMove(value) {this.move = value},

    winGame() {this.score += 1},

    isMatchWinner() {
      return this.score === GAMES_NEEDED_TO_WIN_MATCH;
    },

    getScore() {return this.score},

    resetScore() {this.score = 0},

    updateMoves(move) {
      if (this.moves[move]) {
        this.moves[move] += 1;
      } else this.moves[move] = 1;
    },

    getMoves() {return this.moves},
  };
}

function createComputer() {
  let playerObject = createPlayer();

  let computerObject = {
    // calculateWeightedMoves determines that moves that the computer should 
    // favor
    // input: object with count of moves made by player, e.g. {rock: 2, spock: 1}
    // output: array with weighted moves  
    calculateWeightedMoves(playerMoves) {
      let weightedMoves = VALID_MOVE_CHOICES.slice();
      for (let move in playerMoves) {
        let moveCount = playerMoves[move];
        let moveDefeatedBy = GAME_RULES[move].defeated_by;
        for (let i = 0; i < moveCount; i += 1) {
          weightedMoves = weightedMoves.concat(moveDefeatedBy);
        }
      }
      return weightedMoves;
    },

    choose(playerMoves) {
      let weightedMoveChoices = this.calculateWeightedMoves(playerMoves);
      console.log(weightedMoveChoices);
      let randomIndex = Math.floor(Math.random() * weightedMoveChoices.length);
      this.move = weightedMoveChoices[randomIndex];
    }
  };

  return Object.assign(playerObject, computerObject);
}

function createHuman() {
  let playerObject = createPlayer();

  let humanObject = {
    choose() {
      let choice;
      while (true) {
        console.log(`Please choose ${VALID_MOVE_CHOICES.join(', ')}:`);
        choice = readline.question();
        if (VALID_MOVE_CHOICES.includes(choice)) break;
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

    setHuman(value) {
      this.human = value;
    },

    setComputer(value) {
      this.computer = value;
    },

    displayMoves() {
      let humanMoveDisplay = GAME_BOARD_ASSETS[this.human.getMove()];
      let computerMoveDisplay = GAME_BOARD_ASSETS[this.computer.getMove()];
      console.log(`Your move (${this.human.getMove()}):\n${humanMoveDisplay}\nComputer move (${this.computer.getMove()}):\n${computerMoveDisplay}`);
    },

    display() {
      console.clear();
      this.displayMoves();
    }
  }
}

const RPSGame = {
  human: createHuman(),
  computer: createComputer(),
  gameBoard: createGameBoard(),

  resetGameBoard(human, computer) {
    this.gameBoard.setHuman(human);
    this.gameBoard.setComputer(computer);
  },

  displayWelcomeMessage() {
    console.log(`Welcome to ${VALID_MOVE_CHOICES.join(', ')}!`);
    console.log(`The first player to reach ${GAMES_NEEDED_TO_WIN_MATCH} wins the match.`)
  },

  displayGoodbyeMessage() {
    console.log('Thanks for playing Rock, Paper, Scissors. Goodbye!');
  },

  updatePlayerMoves() {
    this.human.updateMoves(this.human.move);
    this.computer.updateMoves(this.computer.move);
  },

  displayWinner() {
    let humanMove = this.human.move;
    let computerMove = this.computer.move;

    this.updatePlayerMoves();

    if (GAME_RULES[humanMove].defeats.includes(computerMove)) {
      console.log('You win!');
      this.human.winGame();
    } else if (GAME_RULES[computerMove].defeats.includes(humanMove)) {
      console.log('Computer wins!');
      this.computer.winGame();
    } else {
      console.log('It\'s a tie');
    }
  },

  playAgain() {
    console.log('Keep playing? (y/n)');
    let answer = readline.question();
    return answer.toLowerCase()[0] === 'y';
  },

  newMatch() {
    console.log('New match? (y/n)');
    let answer = readline.question();
    return answer.toLowerCase()[0] === 'y';
  },

  displayMatchSummary() {
    console.log(`Player wins: ${this.human.getScore()}`);
    console.log(`Computer wins: ${this.computer.getScore()}`);
  },

  isMatchOver() {
    return this.human.isMatchWinner() || this.computer.isMatchWinner();
  },

  displayMatchWinner() {
    if (this.human.isMatchWinner()) {
      console.log('You won the match!');
    } else if (this.computer.isMatchWinner()) {
      console.log('The computer won the match :(');
    } else {
      console.log(`No match winner yet. First to ${GAMES_NEEDED_TO_WIN_MATCH} wins!`);
    }
  },

  resetMatch() {
    this.human.resetScore();
    this.computer.resetScore();
  },

  displayMoves() {
    // console.log(this.human.getMoves());
    // console.log(this.computer.getMoves());
  },

  play() {
    this.displayWelcomeMessage();
    // Match loop
    while (true) {
      this.resetMatch();
      this.resetGameBoard(this.human, this.computer);
      // Individual game loop
      while (true) {
        this.human.choose();
        this.computer.choose(this.human.getMoves());
        this.gameBoard.display();
        this.displayWinner();
        this.displayMatchSummary();
        if (this.isMatchOver()) break;
        if (!this.playAgain()) break;
      }
      this.displayMatchWinner();
      this.displayMoves();
      if (!this.newMatch()) break;
    }

    this.displayGoodbyeMessage();
  }
};

RPSGame.play();

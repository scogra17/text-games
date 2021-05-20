const readline = require('readline-sync');
const MESSAGES = require('./messages.json');
const MAX_WIN_COUNT = 2;
const MAX_HAND_VALUE = 21;
const DEALER_HIT_LIMIT = 17;
const CARD_SUITS = ['H', 'C', 'S', 'D'];
const CARD_VALUES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const SUIT_UNICODE = {
  S: '\u2664',
  H: '\u2661',
  C: '\u2667',
  D: '\u2662',
};

function invalidHitStayAnswer(answer) {
  return !['h', 's'].includes(answer);
}

function invalidYesNoAnswer(answer) {
  return !['y', 'n'].includes(answer);
}

function prompt(msg) {
  console.log(`=> ${msg}`);
}

function message(key) {
  return MESSAGES[key];
}

function capitalize(msg) {
  return msg[0].toUpperCase() + msg.slice(1);
}

function randomInteger(maxValue) {
  return Math.floor(Math.random() * maxValue);
}

function initializeDeck() {
  let deck = [];
  CARD_VALUES.forEach(val => {
    CARD_SUITS.forEach(suit => {
      deck.push([suit, val]);
    });
  });
  return deck;
}

function generateCardDisplay(suit, value, show = true) {
  // shrink the display gap for double digit numbers
  let gap = value.length === 1 ? '   ' : ' ';
  return {
    top:     `+-----+ `,
    middle1: show ? `|${value}${gap}${value}| ` : `|-----| `,
    middle2: show ? `|  ${SUIT_UNICODE[suit]}  | ` : `|-----| `,
    middle3: show ? `|${value}${gap}${value}| ` : `|-----| `,
    bottom:  `+-----+ `
  };
}

function generateHandDisplay(hand, cardsShown = hand.length) {
  let top = '';
  let middle1 = '';
  let middle2 = '';
  let middle3 = '';
  let bottom = '';

  for (let card = 0; card < hand.length; card += 1) {
    let show = card <= (cardsShown - 1);
    let cardDisplay = generateCardDisplay(hand[card][0], hand[card][1], show);

    top += cardDisplay.top;
    middle1 += cardDisplay.middle1;
    middle2 += cardDisplay.middle2;
    middle3 += cardDisplay.middle3;
    bottom += cardDisplay.bottom;
  }

  return [top, middle1, middle2, middle3, bottom];
}

function displayHand(hand, owner, cardsShown) {
  let handDisplay = generateHandDisplay(hand, cardsShown);
  console.log(`${owner}'s hand:`);
  handDisplay.forEach(str => console.log(str));
}

function displayCards(playerHand, dealerHand, revealDealer = false) {
  displayHand(playerHand, 'Player');
  // Hide all but one of the dealer's cards during gameplay
  if (revealDealer) {
    displayHand(dealerHand, 'Dealer');
  } else {
    displayHand(dealerHand, 'Dealer', 1);
  }
}

function dealCard(deck, hand) {
  let randomCardIndex = randomInteger(deck.length - 1);
  let card = deck.splice(randomCardIndex, 1)[0];
  hand.push(card);
}

function dealHand(deck, playerHand, dealerHand) {
  while (playerHand.length < 2 && dealerHand.length < 2) {
    dealCard(deck, playerHand);
    dealCard(deck, dealerHand);
  }
}

function calculateScore(hand) {
  let score = 0;
  let aces = 0;
  for (let cardIdx = 0; cardIdx < hand.length; cardIdx += 1) {
    let card = hand[cardIdx];
    let value = card[1];
    if (['J', 'Q', 'K'].includes(value)) {
      score += 10;
    } else if (value === 'A') {
      score += 11;
      aces += 1;
    } else {
      score += Number(value);
    }
  }

  if (score > MAX_HAND_VALUE && aces > 0) {
    score -= 10;
  }

  return score;
}

function busted(score) {
  return score > MAX_HAND_VALUE;
}

function determineWinner(playerScore, dealerScore) {
  if (busted(playerScore)) return "dealer";
  if (busted(dealerScore)) return "player";
  if (dealerScore > playerScore) return "dealer";
  if (playerScore > dealerScore) return "player";
  // tie goes to the dealer
  return "dealer";
}

function playerTurn(deck, hand, dealerHand) {
  while (true) {
    prompt(message("hit_message"));
    let answer = readline.question().toLowerCase();
    while (invalidHitStayAnswer(answer)) {
      prompt(message("hit_error"));
      answer = readline.question().toLowerCase();
    }

    if (answer === "s") break;
    dealCard(deck, hand);

    if (busted(calculateScore(hand))) break;
    displayGameState(hand, dealerHand);
  }
}

function dealerTurn(deck, hand) {
  while (true) {
    if (calculateScore(hand) >= DEALER_HIT_LIMIT) break;
    dealCard(deck, hand);
  }
}

function displayGameResult(winner) {
  console.log(capitalize(winner) + message("game_winner_message"));
}

function updateGamesWon(winner, gamesWon) {
  gamesWon[winner] += 1;
}

function displayGamesWon(gamesWon) {
  console.log(`Games won (Target: ${MAX_WIN_COUNT})`);
  console.log(`Player: ${gamesWon.player}`);
  console.log(`Dealer: ${gamesWon.dealer}`);
}

function displayHandScore(owner, hand) {
  let score = calculateScore(hand);
  console.log(`${capitalize(owner)}: ${score}`);
}

function displayGameState(
  playerHand,
  dealerHand,
  winner,
  gamesWon,
  revealDealerHand = false) {
  console.clear();
  displayCards(playerHand, dealerHand, revealDealerHand);
  console.log(message("hand_totals_message"));
  displayHandScore("player", playerHand);
  // only display some information after the hand is over
  if (winner) {
    displayHandScore("dealer", dealerHand);
    displayGameResult(winner);
    console.log('');
    updateGamesWon(winner, gamesWon);
    displayGamesWon(gamesWon);
  }
}

function startNewGame(gamesWon) {
  let playerHand = [];
  let dealerHand = [];
  let playerScore = 0;
  let dealerScore = 0;
  let gameWinner;
  let deck = initializeDeck();

  dealHand(deck, playerHand, dealerHand);
  displayGameState(playerHand, dealerHand, gameWinner, gamesWon);

  // core gameplay
  playerTurn(deck, playerHand, dealerHand);
  playerScore = calculateScore(playerHand);
  if (!busted(playerScore)) dealerTurn(deck, dealerHand);
  dealerScore = calculateScore(dealerHand);

  gameWinner = determineWinner(playerScore, dealerScore);
  displayGameState(playerHand, dealerHand, gameWinner, gamesWon, true);
}

function newGameOrMatch(gameOrMatch) {
  switch (gameOrMatch) {
    case "game":
      prompt(message("new_game_message"));
      break;
    case "match":
      prompt(message("new_match_message"));
      break;
  }

  let newGameOrMatch = readline.question().toLowerCase();
  while (invalidYesNoAnswer(newGameOrMatch)) {
    prompt(message("yes_no_error"));
    newGameOrMatch = readline.question().toLowerCase();
  }
  return newGameOrMatch === 'y';
}

function displayMatchWinner(winner) {
  console.log(capitalize(winner) + message("match_winner_message"));
}

function determineMatchWinner(scores) {
  if (scores.player === MAX_WIN_COUNT) return "player";
  if (scores.dealer === MAX_WIN_COUNT) return "dealer";
  return null;
}

function main() {
  let gamesWon = {
    player: 0,
    dealer: 0,
  };

  while (true) {
    startNewGame(gamesWon);
    let matchWinner = determineMatchWinner(gamesWon);

    if (matchWinner) {
      displayMatchWinner(matchWinner);
      // reset scores for new match
      gamesWon.player = 0;
      gamesWon.dealer = 0;
      if (!newGameOrMatch("match")) break;
    } else if (!newGameOrMatch("game")) break;
  }
}

main();

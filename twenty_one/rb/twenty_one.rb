SCREEN_WIDTH = 50
GAME_NAME = 'Twenty One'
MAX_GAME_SCORE = 21
DEALER_TARGET_SCORE = 17
WINS_FOR_MATCH = 5
FACE_CARDS = ['J', 'Q', 'K']

def repeat(text, n = SCREEN_WIDTH)
  text * n
end

def center(msg, width = SCREEN_WIDTH)
  msg.center(width)
end

def prompt(msg)
  puts "=> #{msg}"
end

def initialize_deck
  suits = ['H', 'D', 'S', 'C']
  values = (2..10).map(&:to_s) + FACE_CARDS + ['A']
  deck = []
  suits.each do |suit|
    values.each do |value|
      deck.push([suit, value])
    end
  end
  deck.shuffle!
end

def card_value(card)
  card_value = card[1]
  if card_value.to_i.to_s == card_value
    card_value.to_i
  elsif FACE_CARDS.include?(card_value)
    10
  elsif card_value == 'A'
    1
  end
end

def hand_value(cards)
  total = 0
  ace = false
  cards.each do |card|
    ace = true if card[1] == 'A'
    total += card_value(card)
  end
  ace && total <= 11 ? total + 10 : total
end

def hit(hand, deck)
  new_card = deal_cards(deck, 1)
  hand.concat(new_card)
end

def busted?(score)
  score > MAX_GAME_SCORE
end

def deal_cards(deck, count)
  cards = []
  count.times { cards.push(deck.pop) }
  cards
end

def outcome(players_score, dealers_score)
  if players_score > MAX_GAME_SCORE
    :player_busted
  elsif dealers_score > MAX_GAME_SCORE
    :dealer_busted
  elsif dealers_score < players_score
    :player_wins
  else
    # tie goes to the dealer
    :dealer_wins
  end
end

def display_outcome(outcome)
  case outcome
  when :player_busted
    prompt "You busted! Dealer wins."
  when :dealer_busted
    prompt "Dealer busted! You win!"
  when :player_wins
    prompt "You win!"
  when :dealer_wins
    prompt "Dealer wins."
  end
end

def play_again?(message)
  answer = ''
  loop do
    prompt("#{message} (yes, no)")
    answer = gets.chomp.downcase
    break if %w(y yes n no).include?(answer)
    prompt("Please provide a valid response (yes, no)")
  end
  answer.start_with?('y')
end

def update_scores(scores, outcome)
  case outcome
  when :player_busted, :dealer_wins
    scores[:dealer] += 1
  when :dealer_busted, :player_wins
    scores[:player] += 1
  end
end

def match_winner(scores)
  if scores[:player] == WINS_FOR_MATCH
    :player
  elsif scores[:dealer] == WINS_FOR_MATCH
    :dealer
  end
end

def display_match_winner(match_winner)
  case match_winner
  when :player
    prompt "You won the match!"
  when :dealer
    prompt "Dealer won the match."
  end
end

def display_welcome
  puts repeat('-')
  puts center(GAME_NAME)
  puts repeat('-')
  puts center("* House rule: tie goes to the dealer!")
  puts center("* Win #{WINS_FOR_MATCH} games to win the match!")
  puts repeat('-')
end

def display_scores(scores)
  puts center("Your score: #{scores[:player]} | " \
              "Dealer score: #{scores[:dealer]}")
  puts repeat('-')
end

def display_table(players_hand, dealers_hand, scores, show_dealers_hand = false)
  system 'clear'
  display_welcome
  display_scores(scores)
  if show_dealers_hand
    prompt "Dealer's hand: #{dealers_hand}"
    prompt "Dealer's score: #{hand_value(dealers_hand)}"
  else
    prompt "Dealer hand: [#{dealers_hand[0]}, ?]"
    prompt "Dealer's score: ?"
  end
  prompt "Your hand: #{players_hand}"
  prompt "Your score: #{hand_value(players_hand)}"
end

def player_response
  response = ''
  loop do
    prompt 'Hit or stay?'
    response = gets.chomp.downcase
    break if %w(hit h stay s).include?(response)
    prompt 'Not a valid response!'
  end
  response
end

def players_turn(hand, dealers_hand, deck, scores)
  loop do
    response = player_response

    if response[0] == 'h'
      hit(hand, deck)
      score = hand_value(hand)
      display_table(hand, dealers_hand, scores, false)
    end

    break if response[0] == 's' || busted?(score)
  end
end

def dealers_turn(hand, deck)
  loop do
    break if hand_value(hand) >= DEALER_TARGET_SCORE
    hit(hand, deck)
  end
end

loop do # match loop
  scores = { 'player': 0, 'dealer': 0 }
  match_winner = nil

  loop do # game loop
    deck = initialize_deck

    # deal two cards to each player
    players_hand = deal_cards(deck, 2)
    dealers_hand = deal_cards(deck, 2)

    display_table(players_hand, dealers_hand, scores, false)

    players_turn(players_hand, dealers_hand, deck, scores)
    players_score = hand_value(players_hand)

    if !busted?(players_score)
      dealers_turn(dealers_hand, deck)
    end
    dealers_score = hand_value(dealers_hand)

    display_table(players_hand, dealers_hand, scores, true)

    outcome = outcome(players_score, dealers_score)
    update_scores(scores, outcome)

    display_table(players_hand, dealers_hand, scores, true)
    display_outcome(outcome)

    match_winner = match_winner(scores)
    break if match_winner || !play_again?('New game?')
  end

  display_match_winner(match_winner)
  break unless play_again?('New match?')
end

prompt "Thank you for playing #{GAME_NAME}!"

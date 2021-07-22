module Affirmable
  def yes?(question, allowed_responses = ['y', 'n'])
    answer = ''
    puts "#{question} (#{allowed_responses.join('/')})"
    loop do
      answer = gets.chomp.strip.downcase
      break unless !%w(y yes n no).include?(answer)
      puts "Invalid input. Please enter #{allowed_responses.join('/')}:"
    end
    answer.chars.first == 'y'
  end
end

module Bannerable
  SCREEN_WIDTH = 50

  def display_banner(message, width = SCREEN_WIDTH)
    puts repeat('-', width)
    puts center(message, width)
    puts repeat('-', width)
  end

  def repeat(text, n = SCREEN_WIDTH)
    text * n
  end

  def center(msg, width = SCREEN_WIDTH)
    msg.center(width)
  end
end

class Hand
  def initialize
    @cards = []
  end

  def reset
    self.cards = []
  end

  def add_card(card)
    cards << card
  end

  def total
    total = 0
    ace = false
    cards.each do |card|
      ace = true if card.value == Deck::ACE
      total += card.number_value
    end
    ace && total <= 11 ? total + 10 : total
  end

  def draw(show_all_cards = true)
    visual_blueprint(show_all_cards).each do |_, row|
      puts row
    end
  end

  def visual_blueprint(show_all_cards = true)
    blueprint = { 'top': '', 'mid1': '', 'mid2': '', 'mid3': '', 'bottom': '' }

    cards.each_with_index do |card, idx|
      card_blueprint = card.visual_blueprint(show_all_cards || idx == 0)

      blueprint[:top]    += card_blueprint[:top]
      blueprint[:mid1]   += card_blueprint[:mid1]
      blueprint[:mid2]   += card_blueprint[:mid2]
      blueprint[:mid3]   += card_blueprint[:mid3]
      blueprint[:bottom] += card_blueprint[:bottom]
    end

    blueprint
  end

  private

  attr_accessor :cards
end

class Participant
  attr_reader :hand

  def initialize
    @hand = Hand.new
  end

  def busted?
    hand_total > Game::TARGET_SCORE
  end

  def hand_total
    hand.total
  end

  def reset_hand
    hand.reset
  end

  def add_card_to_hand(card)
    hand.add_card(card)
  end
end

class Player < Participant
  def initialize
    super
  end

  def display_hand(show_all_cards = true)
    puts "Your hand (total: #{hand.total}):"
    hand.draw(show_all_cards)
  end

  def hit?
    puts "Do you want to 'hit' for another card or 'stay' with what you have?"
    puts "Type your choice:"
    choice = nil
    loop do
      choice = gets.chomp.downcase.strip
      break if %w(h hit s stay).include?(choice)
      puts "Invalid choice. Please enter 'hit' or 'stay':"
    end
    choice[0] == 'h'
  end
end

class Dealer < Participant
  TARGET_SCORE = 17

  def initialize
    super
  end

  def stay?
    hand.total >= TARGET_SCORE
  end

  def display_hand(show_all_cards = false)
    puts "Dealer's hand (total: #{show_all_cards ? hand.total : '?'}):"
    hand.draw(show_all_cards)
  end
end

class Deck
  SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
  FACE_CARDS = ['J', 'Q', 'K']
  ACE = 'A'
  VALUES = (2..10).map(&:to_s) + FACE_CARDS + [ACE]

  def initialize
    @cards = []
    reset
  end

  def deal_card
    cards.pop
  end

  def reset
    SUITS.each do |suit|
      VALUES.each do |value|
        cards << Card.new(suit, value)
      end
    end
    cards.shuffle!
  end

  private

  attr_reader :cards
end

class Card
  SUIT_UNICODE = {
    'Spades' => "\u2664",
    'Hearts' => "\u2661",
    'Clubs' => "\u2667",
    'Diamonds' => "\u2662"
  }
  attr_reader :suit, :value

  def initialize(suit, value)
    @suit = suit
    @value = value
  end

  def number_value
    if value.to_i.to_s == value
      value.to_i
    elsif Deck::FACE_CARDS.include?(value)
      10
    elsif value == Deck::ACE
      1
    end
  end

  def visual_blueprint(show = true)
    gap = value == '10' ? ' ' : '   '
    blueprint = { 'top': '', 'mid1': '', 'mid2': '', 'mid3': '', 'bottom': '' }

    blueprint[:top]    = "+-----+ "
    blueprint[:mid1]   = show ? "|#{value}#{gap}#{value}| " : "|-----| "
    blueprint[:mid2]   = show ? "|  #{SUIT_UNICODE[suit]}  | " : "|-----| "
    blueprint[:mid3]   = show ? "|#{value}#{gap}#{value}| " : "|-----| "
    blueprint[:bottom] = "+-----+ "

    blueprint
  end
end

class Game
  include Bannerable
  include Affirmable

  INITIAL_HAND_SIZE = 2
  TARGET_SCORE = 21

  def initialize
    @deck = Deck.new
    @dealer = Dealer.new
    @player = Player.new
  end

  def start
    display_welcome_message
    play if ready_to_play?
    display_goodbye_message
  end

  private

  def play
    loop do
      deal_cards
      display_hands
      player_turn
      dealer_turn
      display_result
      break unless play_again?
      reset
    end
  end

  def display_welcome_message
    clear
    display_banner("Welcome to #{TARGET_SCORE}!")
    puts "* Closest to #{TARGET_SCORE} without going over wins!"
    puts "* Tie goes to the dealer!"
    puts ""
  end

  def display_goodbye_message
    clear
    display_banner("Thanks for playing. Goodbye!")
  end

  def deal_cards
    INITIAL_HAND_SIZE.times do
      player.add_card_to_hand(deck.deal_card)
      dealer.add_card_to_hand(deck.deal_card)
    end
  end

  def display_hands(show_all_dealer_cards = false)
    clear
    dealer.display_hand(show_all_dealer_cards)
    puts ""
    player.display_hand
    puts ""
  end

  def player_turn
    loop do
      break if player.busted? || !player.hit?
      player.add_card_to_hand(deck.deal_card)
      display_hands
    end
  end

  def dealer_turn
    loop do
      break if player.busted? || dealer.busted? || dealer.stay?
      dealer.add_card_to_hand(deck.deal_card)
    end
    display_hands(true)
  end

  def outcome
    if player.busted?                           then :player_busted
    elsif dealer.busted?                        then :dealer_busted
    elsif dealer.hand_total < player.hand_total then :player_wins
    else :dealer_wins
    end
  end

  def display_result
    display_hands(true)
    case outcome
    when :player_busted then display_banner "You busted! Dealer wins."
    when :dealer_busted then display_banner "Dealer busted! You win!"
    when :player_wins   then display_banner "You win!"
    when :dealer_wins   then display_banner "Dealer wins."
    end
  end

  def reset
    deck.reset
    player.reset_hand
    dealer.reset_hand
  end

  def play_again?
    yes?("Would you like to play another game?")
  end

  def ready_to_play?
    puts "Tap return when you're ready to play..."
    gets
  end

  def clear
    system "clear"
  end

  attr_reader :player, :dealer, :deck
end

Game.new.start

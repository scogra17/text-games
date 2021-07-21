module Affirmable
  def yes?(question, allowed_responses = ['y', 'n'])
    answer = ''
    loop do
      puts "#{question} (#{allowed_responses.join('/')})"
      answer = gets.chomp.downcase
      break unless !%w(y yes n no).include?(answer)
      puts "Please provide a valid response (#{allowed_responses.join('/')})"
    end
    answer.chars.first == 'y'
  end
end

class Move
  def self.valid_moves
    [Rock, Paper, Scissors, Lizard, Spock]
  end

  def self.display_valid_names
    valid_moves.map { |move| "#{move} (#{move.short_name})" }.join(', ')
  end

  def self.valid_names
    valid_moves.map { |move| [move.to_s.downcase, move.short_name] }.flatten
  end

  def self.move(name)
    valid_moves.each do |move|
      return move if move.to_s.downcase == name || move.short_name == name
    end
  end

  attr_reader :move
end

class Rock < Move
  def >(other_move)
    other_move.class == Scissors ||
      other_move.class == Lizard
  end

  def to_s
    'rock'
  end

  def self.short_name
    'r'
  end
end

class Paper < Move
  def >(other_move)
    other_move.class == Rock ||
      other_move.class == Spock
  end

  def to_s
    'paper'
  end

  def self.short_name
    'p'
  end
end

class Scissors < Move
  def >(other_move)
    other_move.class == Paper ||
      other_move.class == Lizard
  end

  def to_s
    'scissors'
  end

  def self.short_name
    'sc'
  end
end

class Lizard < Move
  def >(other_move)
    other_move.class == Spock ||
      other_move.class == Paper
  end

  def to_s
    'lizard'
  end

  def self.short_name
    'l'
  end
end

class Spock < Move
  def >(other_move)
    other_move.class == Scissors ||
      other_move.class == Rock
  end

  def to_s
    'spock'
  end

  def self.short_name
    'sp'
  end
end

class Player
  attr_accessor :move, :name
  attr_reader :score, :moves

  def initialize
    set_name
    @score = 0
    @moves = { Rock => 0, Paper => 0, Scissors => 0, Lizard => 0, Spock => 0 }
  end

  def record_win
    @score = score + 1
  end

  def reset_score
    @score = 0
  end

  def record_move
    @moves[@move.class] += 1
  end

  def display_moves
    moves.map { |move, count| "#{move.name}: #{count}" }.join(', ')
  end
end

class Human < Player
  def set_name
    system "clear"
    n = nil
    loop do
      puts "Type your name and hit return:"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def select_move
    system "clear"
    choice = nil
    loop do
      puts "Please choose #{Move.display_valid_names}:"
      choice = gets.downcase.chomp
      break if Move.valid_names.include? choice
      puts "Sorry, invalid choice."
    end
    Move.move(choice)
  end

  def choose
    self.move = select_move.new
  end
end

class Computer < Player
  def set_name
    @name = [R2D2, WallE, Skynet].sample
  end

  def choose
    choice = name::MOVE_PREFERENCE_WEIGHT.map { |k, v| [k] * v }.flatten.sample
    self.move = choice.new
  end
end

class R2D2 < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 1,
    Paper => 0,
    Scissors => 0,
    Lizard => 0,
    Spock => 0
  }
end

class WallE < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 0,
    Paper => 1,
    Scissors => 1,
    Lizard => 1,
    Spock => 1
  }
end

class Skynet < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 0,
    Paper => 0,
    Scissors => 1,
    Lizard => 0,
    Spock => 2
  }
end

class RPSGame
  attr_reader :human, :computer

  def initialize(human, computer)
    @human = human
    @computer = computer
  end

  def display_moves
    system "clear"
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
    puts ""
  end

  def display_game_winner
    if human.move > computer.move
      puts "#{human.name} won!"
    elsif computer.move > human.move
      puts "#{computer.name} won!"
    else
      puts "It's a tie!"
    end
  end

  def play
    human.choose
    human.record_move
    computer.choose
    computer.record_move
    display_moves
    display_game_winner
  end
end

class RPSMatch
  GAMES_TO_WIN_MATCH = 2
  include Affirmable

  attr_reader :game, :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
    @game = RPSGame.new(human, computer)
  end

  def display_welcome_message
    system "clear"
    puts "*****************************************************"
    puts "Welcome to Rock, Paper, Scissors, Lizard, Spock!"
    puts "*****************************************************"
    puts "You must win #{GAMES_TO_WIN_MATCH} games to win the match!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing. Goodbye!"
  end

  def display_match_score
    human_score = human.score
    computer_score = computer.score
    puts "#{human.name} has won " \
     "#{human_score} game#{human_score == 1 ? '' : 's'}"
    puts "#{computer.name} has won " \
     "#{computer_score} game#{computer_score == 1 ? '' : 's'}"
    puts ""
  end

  def match_winner?
    human.score == GAMES_TO_WIN_MATCH ||
      computer.score == GAMES_TO_WIN_MATCH
  end

  def display_match_winner
    if human.score == GAMES_TO_WIN_MATCH
      puts "#{human.name} won the match!"
    elsif computer.score == GAMES_TO_WIN_MATCH
      puts "#{computer.name} won the match!"
    end
  end

  def display_move_history
    system "clear"
    puts "#{human.name}'s move history:\n #{human.display_moves}"
    puts "#{computer.name}'s move history:\n #{computer.display_moves}"
    puts ""
  end

  def play_another_game?
    yes?("Would you like to play another game?")
  end

  def play_another_match?
    yes?("Would you like to play another match?")
  end

  def see_move_history?
    system "clear"
    yes?("Would you like to see the move history?")
  end

  def continue?
    puts "Tap return when you're ready to play..."
    gets
  end

  def record_game_winner
    if human.move > computer.move
      human.record_win
    elsif computer.move > human.move
      computer.record_win
    end
  end

  def reset_game
    human.reset_score
    computer.reset_score
  end

  def game_loop
    loop do
      game.play
      record_game_winner
      display_match_score
      break if match_winner? || !play_another_game?
    end
  end

  def match_loop
    loop do
      game_loop
      break unless match_winner? # exited before match ended, terminate game
      display_match_winner
      break unless play_another_match?
      reset_game
    end
  end

  def play
    display_welcome_message
    continue?
    match_loop
    display_move_history if see_move_history?
    display_goodbye_message
  end
end

RPSMatch.new.play

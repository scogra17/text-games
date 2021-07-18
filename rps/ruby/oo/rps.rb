module Affirmable
  def yes?(question, example_responses)
    answer = ''
    loop do
      puts "#{question} (#{example_responses.join('/')})"
      answer = gets.chomp.downcase
      break unless !%w(y yes n no).include?(answer)
      prompt("Please provide a valid response (yes/no)")
    end
    answer.chars.first == 'y'
  end
end

class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']
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
end

class Paper < Move
  def >(other_move)
    other_move.class == Rock ||
      other_move.class == Spock
  end

  def to_s
    'paper'
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
end

class Lizard < Move
  def >(other_move)
    other_move.class == Spock ||
      other_move.class == Paper
  end

  def to_s
    'lizard'
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
end

class Human < Player
  def set_name
    n = ''
    loop do
      puts "What's your name"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def select_move
    choice = nil
    loop do
      puts "Please choose rock, paper, scissors, lizard or spock:"
      choice = gets.downcase.chomp
      break if Move::VALUES.include? choice
      puts "Sorry, invalid choice."
    end
    choice
  end

  def choose
    choice = select_move
    self.move = case choice
                when 'rock' then Rock.new
                when 'paper' then Paper.new
                when 'scissors' then Scissors.new
                when 'lizard' then Lizard.new
                when 'spock' then Spock.new
                end
  end
end

class Computer < Player
  def set_name
    @name = [R2D2, WallE, SkyNet].sample
  end

  def choose
    choice = name::MOVE_PREFERENCE_WEIGHT.map { |k, v| [k] * v }.flatten.sample
    self.move = if choice == Rock then Rock.new
                elsif choice == Paper then Paper.new
                elsif choice == Scissors then Scissors.new
                elsif choice == Lizard then Lizard.new
                elsif choice == Spock then Spock.new
                end
  end
end

class R2D2 < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 100,
    Paper => 0,
    Scissors => 0,
    Lizard => 0,
    Spock => 0
  }
end

class WallE < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 0,
    Paper => 25,
    Scissors => 25,
    Lizard => 25,
    Spock => 25
  }
end

class SkyNet < Computer
  MOVE_PREFERENCE_WEIGHT = {
    Rock => 0,
    Paper => 0,
    Scissors => 25,
    Lizard => 0,
    Spock => 50
  }
end

class RPSMatch
end

class RPSGame
  include Affirmable

  GAMES_TO_WIN_MATCH = 2

  attr_accessor :human, :computer

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def reset_game
    human.reset_score
    computer.reset_score
  end

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors, Lizard, Spock!"
    puts "First to #{GAMES_TO_WIN_MATCH} wins, wins the match!"
  end

  def display_goodbye_message
    puts "Thanks for playing. Goodbye!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
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

  def record_game_winner
    if human.move > computer.move
      human.record_win
    elsif computer.move > human.move
      computer.record_win
    end
  end

  def display_match_score
    puts "#{human.name} has won #{human.score} games"
    puts "#{computer.name} has won #{computer.score} games"
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
    puts "#{human.name} move history: #{human.moves}"
    puts "#{computer.name} move history: #{computer.moves}"
  end

  def play_another_game?
    yes?("Would you like to play another game?", ['y', 'n'])
  end

  def play_another_match?
    yes?("Would you like to play another match?", ['y', 'n'])
  end

  def display_game_data
    display_moves
    display_game_winner
  end

  def display_match_data
    display_match_score
    display_move_history
  end

  def game_loop
    loop do # game loop
      human.choose
      human.record_move
      computer.choose
      computer.record_move
      record_game_winner
      display_game_data
      display_match_data

      break if match_winner? || !play_another_game?
    end
  end

  def match_loop
    loop do
      game_loop
      if match_winner?
        display_match_winner
        reset_game
      end
      break if !play_another_match?
    end
  end

  def play
    display_welcome_message
    match_loop
    display_goodbye_message
  end
end

RPSGame.new.play

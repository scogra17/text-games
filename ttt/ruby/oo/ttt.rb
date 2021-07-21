require "pry-byebug"

module Listable
  def joinor(arr, delim = ', ', final_delim = 'or')
    str = ''
    case arr.size
    when 0 then return ''
    when 1 then return arr.first
    when 2 then return arr.join(" #{final_delim} ")
    else
      arr.each_with_index do |item, idx|
        str << case idx
               when 0            then item.to_s
               when arr.size - 1 then "#{delim}#{final_delim} #{item}"
               else                   "#{delim}#{item}"
               end
      end
    end
    str
  end
end

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

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]] # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  # return winning marker or nil
  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----|-----|-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----|-----|-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :games_won

  def initialize(marker)
    @marker = marker
    @games_won = 0
  end

  def record_game_win
    self.games_won = games_won + 1
  end

  def reset_games_won
    self.games_won = 0
  end

  private

  attr_writer :games_won
end

class TTTGame
  include Listable
  include Affirmable

  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  FIRST_TO_MOVE = HUMAN_MARKER
  GAMES_TO_WIN_MATCH = 2
  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    clear
    display_welcome_message
    match_loop
    display_goodbye_message
  end

  private

  def match_loop
    loop do
      game_loop
      break unless someone_won_match?
      display_match_winner
      break unless play_another_match?
      reset_match
    end
  end

  def game_loop
    loop do
      display_board
      play_game
      record_game_winner
      display_game_result
      display_match_score
      break if someone_won_match? || !play_another_game?
      reset_game
      display_play_again_message
    end
  end

  def play_game
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def someone_won_match?
    !!match_winning_marker
  end

  def reset_match
    reset_game
    human.reset_games_won
    computer.reset_games_won
  end

  # return match winning marker or nil
  def match_winning_marker
    if human.games_won == GAMES_TO_WIN_MATCH
      human.marker
    elsif computer.games_won == GAMES_TO_WIN_MATCH
      computer.marker
    end
  end

  def play_another_match?
    yes?("Would you like to play another match?")
  end

  def play_another_game?
    yes?("Would you like to play another game?")
  end

  def display_match_score
    human_score = human.games_won
    computer_score = computer.games_won
    puts "You have won " \
     "#{human_score} game#{human_score == 1 ? '' : 's'}"
    puts "The computer has won " \
     "#{computer_score} game#{computer_score == 1 ? '' : 's'}"
    puts ""
  end

  def display_match_winner
    if human.games_won == GAMES_TO_WIN_MATCH
      puts "You won the match!"
    elsif computer.games_won == GAMES_TO_WIN_MATCH
      puts "The computer won the match!"
    end
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing! Goodbye."
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts "You're a #{HUMAN_MARKER}. Computer is a #{COMPUTER_MARKER}."
    puts ""
    board.draw
    puts ""
  end

  def human_moves
    square = nil
    loop do
      puts "Choose a square (#{joinor(board.unmarked_keys)}): "
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    board[board.unmarked_keys.sample] = computer.marker
  end

  def display_game_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "Computer won."
    else
      puts "It's a tie."
    end
  end

  def record_game_winner
    case board.winning_marker
    when human.marker
      human.record_game_win
    when computer.marker
      computer.record_game_win
    end
  end

  def clear
    system "clear"
  end

  def reset_game
    board.reset
    @current_marker = FIRST_TO_MOVE
    clear
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = COMPUTER_MARKER
    else
      computer_moves
      @current_marker = HUMAN_MARKER
    end
  end

  def human_turn?
    @current_marker == HUMAN_MARKER
  end
end

game = TTTGame.new
game.play

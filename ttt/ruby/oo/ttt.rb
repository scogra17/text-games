module Randomizable
  def random_boolean
    [true, false].sample
  end
end

module Listable
  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength
end

module Affirmable
  def yes?(question, allowed_responses = ['y', 'n'])
    answer = ''
    loop do
      puts "#{question} (#{allowed_responses.join('/')})"
      answer = gets.chomp.strip.downcase
      break unless !%w(y yes n no).include?(answer)
      puts "Please provide a valid response (#{allowed_responses.join('/')})"
    end
    answer.chars.first == 'y'
  end
end

module Bannerable
  def banner(message, padding = 10)
    width = message.size + padding * 2
    horizontal = '*' * width
    puts horizontal
    puts message.center(width)
    puts horizontal
  end
end

module Hashable
  def add_to_hash_value_array!(hsh, k, v)
    if hsh.key?(k)
      hsh[k] << v
    else
      hsh[k] = [v]
    end
  end
end

class Board
  include Hashable

  SIDE_LENGTH = 3
  NUM_SQUARES = SIDE_LENGTH**2
  MIDDLE_SQUARE_KEY = 5
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]] # diagonals

  def initialize
    @squares = {}
    reset
  end

  def middle_square_empty?
    @squares[MIDDLE_SQUARE_KEY].unmarked?
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

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if identical_markers?(squares, 3)
        return squares.first.marker
      end
    end
    nil
  end

  def defensive_key(opponent_marker: human.marker)
    return winning_keys_by_marker[opponent_marker].sample \
    if winning_keys_by_marker.key?(opponent_marker)
  end

  def reset
    (1..NUM_SQUARES).each { |key| @squares[key] = Square.new }
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

  def identical_markers?(squares, num)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != num
    markers.min == markers.max
  end

  def all_marked?(squares)
    squares.select(&:unmarked?).empty?
  end

  def one_mark_from_a_win?(squares)
    identical_markers?(squares, SIDE_LENGTH - 1) && !all_marked?(squares)
  end

  def winning_keys_by_marker
    winning_keys = {}
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if one_mark_from_a_win?(squares)
        marker = squares.select(&:marked?).first.marker
        unmarked_key = line.select { |key| @squares[key].unmarked? }.first
        add_to_hash_value_array!(winning_keys, marker, unmarked_key)
      end
    end
    winning_keys
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
  attr_accessor :marker
  attr_reader :games_won, :name

  def initialize(marker, name)
    @marker = marker
    @name = name
    @games_won = 0
  end

  def record_game_win
    self.games_won = games_won + 1
  end

  def reset_games_won
    self.games_won = 0
  end

  def choose_marker
    marker = nil
    loop do
      puts "Type a single character marker and hit return:"
      marker = gets.chomp.strip
      break unless marker.empty? || marker.size > 1
      puts "Sorry, must enter a single character."
    end
    self.marker = marker
  end

  def set_name
    n = nil
    loop do
      puts "Type name and hit return:"
      n = gets.chomp.strip
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  private

  attr_writer :games_won, :name
end

class TTTGame
  include Listable
  include Affirmable
  include Randomizable
  include Bannerable

  HUMAN_DEFAULT_MARKER = 'X'
  HUMAN_DEFAULT_NAME = 'Player'
  COMPUTER_DEFAULT_MARKER = 'O'
  COMPUTER_DEFAULT_NAME = 'Computer'
  FIRST_TO_MOVE = HUMAN_DEFAULT_MARKER
  GAMES_TO_WIN_MATCH = 5

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_DEFAULT_MARKER, HUMAN_DEFAULT_NAME)
    @computer = Player.new(COMPUTER_DEFAULT_MARKER, COMPUTER_DEFAULT_NAME)
    @current_marker = FIRST_TO_MOVE
  end

  def play
    clear
    choose_names if choose_names?
    choose_marker if choose_marker?
    match_loop
    display_goodbye_message
  end

  private

  def match_loop
    loop do
      make_computer_current_marker if !player_goes_first?
      game_loop
      break unless someone_won_match?
      display_match_winner
      break unless play_another_match?
      reset_match
    end
  end

  def game_loop
    loop do
      clear_screen_and_display_board
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

  def chooose_computer_name?
    clear_screen_and_dispay_welcome_message
    yes?("Do you want to name the computer?")
  end

  def choose_names?
    display_welcome_message
    yes?("Would you like to enter a custom name?")
  end

  def choose_names
    clear_screen_and_dispay_welcome_message
    human.set_name
    return unless chooose_computer_name?
    clear_screen_and_dispay_welcome_message
    computer.set_name
  end

  def choose_marker?
    clear_screen_and_dispay_welcome_message
    puts "Your default marker is '#{HUMAN_DEFAULT_MARKER}'."
    yes?("Would you like to select a new marker?")
  end

  def choose_marker
    clear_screen_and_dispay_welcome_message
    human.choose_marker
    computer.marker = HUMAN_DEFAULT_MARKER \
    if human.marker == COMPUTER_DEFAULT_MARKER
  end

  def player_goes_first?
    clear_screen_and_dispay_welcome_message
    choice = ''
    loop do
      puts "Who goes first? 1-#{human.name}, 2-#{computer.name}, 3-Don't care"
      choice = gets.chomp.strip
      break if %w(1 2 3).include?(choice)
      puts "Not a valid response!"
    end

    return random_boolean if choice == '3'
    choice == '1'
  end

  def make_computer_current_marker
    @current_marker = COMPUTER_DEFAULT_MARKER
  end

  def someone_won_match?
    !!match_winning_marker
  end

  def reset_match
    reset_game
    human.reset_games_won
    computer.reset_games_won
  end

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
    puts "#{human.name} has won " \
     "#{human_score} game#{human_score == 1 ? '' : 's'}"
    puts "#{computer.name} has won " \
     "#{computer_score} game#{computer_score == 1 ? '' : 's'}"
    puts ""
  end

  def display_match_winner
    if human.games_won == GAMES_TO_WIN_MATCH
      banner("#{human.name} won the match!")
    elsif computer.games_won == GAMES_TO_WIN_MATCH
      banner("#{computer.name} won the match!")
    end
  end

  def display_welcome_message
    system "clear"
    banner("Welcome to Tic Tac Toe!", 15)
    puts "* Win #{GAMES_TO_WIN_MATCH} games to win the match!"
    puts "* Win the game by connecting three squares in a row."
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing! Goodbye."
  end

  def clear_screen_and_dispay_welcome_message
    clear
    display_welcome_message
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts "#{human.name} is a '#{human.marker}'." \
    "#{computer.name} is a '#{computer.marker}'."
    puts ""
    board.draw
    puts ""
  end

  def human_moves
    square = nil
    loop do
      puts "Choose a square (#{joinor(board.unmarked_keys)}): "
      square = gets.chomp.strip.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def select_strategic_key
    offensive_key = board.defensive_key(opponent_marker: computer.marker)
    return offensive_key if offensive_key
    defensive_key = board.defensive_key(opponent_marker: human.marker)
    return defensive_key if defensive_key
    return Board::MIDDLE_SQUARE_KEY if board.middle_square_empty?
  end

  def computer_moves
    strategic_key = select_strategic_key
    if strategic_key
      board[strategic_key] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end

  def display_game_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      banner("#{human.name} won!")
    when computer.marker
      banner("#{computer.name} won")
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
      @current_marker = COMPUTER_DEFAULT_MARKER
    else
      computer_moves
      @current_marker = HUMAN_DEFAULT_MARKER
    end
  end

  def human_turn?
    @current_marker == HUMAN_DEFAULT_MARKER
  end
end

game = TTTGame.new
game.play

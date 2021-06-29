require 'pry-byebug'

WINS_FOR_MATCH = 5
INITIAL_MARKER = ' '
PLAYER_MARKER = 'X'
COMPUTER_MARKER = 'O'
WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +  # rows
                [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +  # cols
                [[1, 5, 9], [3, 5, 7]]               # diagonals

def prompt(msg)
  puts "=> #{msg}"
end

def joinor(arr, delim = ', ', final_delim = 'or')
  str = ''
  case arr.size
  when 0 then return ''
  when 1 then return arr.first
  when 2 then return arr.join(" #{final_delim} ")
  else
    arr.each_with_index do |item, idx|
      str << case idx
             when 0            then item
             when arr.size - 1 then "#{delim}#{final_delim} #{item}"
             else                   "#{delim}#{item}"
             end
    end
  end
  str
end

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def display_board(board, scores)
  system 'clear'
  puts "---------------------------------"
  puts "           Tic Tac Toe           "
  puts "---------------------------------"
  prompt "You're #{PLAYER_MARKER}. Computer is #{COMPUTER_MARKER}."
  prompt "Win #{WINS_FOR_MATCH} games to win the match!"
  puts "---------------------------------"
  puts "Wins | you: #{scores['Player']}, computer: #{scores['Computer']}"
  puts ""
  puts "     |     |"
  puts "  #{board[1]}  |  #{board[2]}  |  #{board[3]}"
  puts "     |     |"
  puts "-----+-----+-----"
  puts "     |     |"
  puts "  #{board[4]}  |  #{board[5]}  |  #{board[6]}"
  puts "     |     |"
  puts "-----+-----+-----"
  puts "     |     |"
  puts "  #{board[7]}  |  #{board[8]}  |  #{board[9]}"
  puts "     |     |"
  puts ""
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

def initialize_board
  new_board = {}
  (1..9).each { |num| new_board[num] = INITIAL_MARKER }
  new_board
end

def empty_squares(board)
  board.keys.select { |num| board[num] == INITIAL_MARKER }
end

def alertnate_player(current_player)
  if current_player == 'Player'
    'Computer'
  elsif current_player == 'Computer'
    'Player'
  end
end

def play_piece!(board, current_player)
  if current_player == 'Player'
    player_places_piece!(board)
  elsif current_player == 'Computer'
    computer_places_piece!(board)
  end
end

def player_places_piece!(board)
  square = ''
  loop do
    prompt "Choose a square (#{joinor(empty_squares(board))})"
    square = gets.chomp.to_i
    break if empty_squares(board).include?(square)
    prompt "Sorry, that's not a valid choice!"
  end

  board[square] = PLAYER_MARKER
end

def defensive_square(board, opponent = PLAYER_MARKER)
  defensive_square = nil
  WINNING_LINES.each do |line|
    if board.values_at(*line).count(opponent) == 2
      defensive_square = line.filter do |square|
        board[square] == INITIAL_MARKER
      end.first
      break
    end
  end
  defensive_square
end

def computer_places_piece!(board)
  square = defensive_square(board, COMPUTER_MARKER)
  square = defensive_square(board) if !square
  if !square
    empty_squares = empty_squares(board)
    square = empty_squares.include?(5) ? 5 : empty_squares.sample
  end
  board[square] = COMPUTER_MARKER
end

def board_full?(board)
  empty_squares(board).empty?
end

def someone_won?(board)
  !!detect_winner(board)
end

def detect_winner(board)
  WINNING_LINES.each do |line|
    if board.values_at(*line).count(PLAYER_MARKER) == 3
      return 'Player'
    elsif board.values_at(*line).count(COMPUTER_MARKER) == 3
      return 'Computer'
    end
  end
  nil
end

def someone_won_match?(scores)
  !!detect_match_winner(scores)
end

def detect_match_winner(scores)
  if scores['Player'] == WINS_FOR_MATCH
    'Player'
  elsif scores['Computer'] == WINS_FOR_MATCH
    'Computer'
  end
end

def update_scores(scores, winner)
  scores[winner] += 1 if winner
end

def play_again?(message)
  answer = ''
  loop do
    prompt("#{message} (yes, no)")
    answer = gets.chomp.downcase
    if !%w(y yes n no).include?(answer)
      prompt("Please provide a valid response (yes, no)")
    else
      break
    end
  end
  answer.start_with?('y')
end

def player_goes_first?
  options = ['Player', 'Computer']
  choice = ''
  loop do
    prompt "Who do you want to have the first turn?" \
           " 1-me, 2-computer, 3-don't care"
    choice = gets.chomp.to_i
    break if [1, 2, 3].include?(choice)
    prompt "Not a valid response!"
  end

  if choice == 3
    choice = [1, 2].sample
  end

  options[choice - 1] == 'Player'
end

system 'clear'
prompt "Welcome to Tic Tac Toe!"
loop do # match loop
  scores = { 'Player' => 0, 'Computer' => 0 }
  loop do # game loop
    board = initialize_board
    current_player = player_goes_first? ? 'Player' : 'Computer'

    loop do
      display_board(board, scores)
      play_piece!(board, current_player)
      current_player = alertnate_player(current_player)
      break if someone_won?(board) || board_full?(board)
    end

    winner = detect_winner(board)
    update_scores(scores, winner)
    display_board(board, scores)

    if winner
      prompt "#{winner} won the game! "
    else
      prompt "It's a tie!"
    end

    break if someone_won_match?(scores)
    break unless play_again?("Play another game?")
  end

  match_winner = detect_match_winner(scores)
  if match_winner
    prompt "#{match_winner} won the match!"
    break unless play_again?("Plan another match?")
  else
    break
  end
end

prompt "Thanks for playing Tic Tac Toe!"

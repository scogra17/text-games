require 'yaml'

CONFIG = YAML.load_file('rps.yml')
SHORT_NAMES = CONFIG['short_names']
VALID_CHOICES = SHORT_NAMES.values
DEFEATED_BY = CONFIG['defeated_by']
MAX_WINS = 2

def prompt(message)
  Kernel.puts("=> #{message}")
end

def win?(first, second)
  DEFEATED_BY[first].include?(second)
end

def display_results(winner)
  case winner
  when 'player'   then prompt("You won!")
  when 'computer' then prompt("Computer won!")
  else                 prompt("It's a tie!")
  end
end

def display_scores(scores)
  message = <<-DELIM
Updated scores:
    You: #{scores[:player]}
    Computer: #{scores[:computer]}
  DELIM
  prompt(message)
end

def winner(player, computer)
  winner = nil
  if win?(player, computer)
    winner = 'player'
  elsif win?(computer, player)
    winner = 'computer'
  end
  winner
end

def update_scores(winner, scores)
  if winner
    scores[winner.to_sym] += 1
  end
end

def match_winner(scores)
  winner = nil
  scores.each do |player, score|
    if score == MAX_WINS
      winner = player
    end
  end
  winner
end

def display_match_results(winner)
  case winner
  when 'player' then prompt("You won the match!")
  when 'computer' then prompt("The computer won the match!")
  end
end

def reset_match(scores)
  scores[:player] = 0
  scores[:computer] = 0
end

scores = { player: 0, computer: 0 }
loop do # main loop
  choice = ''
  loop do
    prompt("Choose one: #{VALID_CHOICES.join(', ')}")
    choice = Kernel.gets().chomp()

    if SHORT_NAMES[choice]
      choice = SHORT_NAMES[choice]
    end

    if VALID_CHOICES.include?(choice)
      break
    else
      prompt("Please enter a valid choice.")
    end
  end

  computer_choice = VALID_CHOICES.sample

  prompt("You chose #{choice}; Computer chose #{computer_choice}")

  winner = winner(choice, computer_choice)
  display_results(winner)
  update_scores(winner, scores)
  display_scores(scores)

  match_winner = match_winner(scores)
  if match_winner
    display_match_results(match_winner.to_s)
    reset_match(scores)
  end

  prompt("Do you want to play again?")
  answer = Kernel.gets().chomp()
  break unless answer.downcase().start_with?('y')
end

prompt("Thank you for playing!")

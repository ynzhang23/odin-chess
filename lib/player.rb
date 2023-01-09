# frozen-string-literal: true

require './lib/board'
require './lib/pieces/rook'
require './lib/pieces/knight'

class Player
  # The valid notation for ranks
  RANK = ('a'..'h').to_a.concat(('A'..'H').to_a).freeze
  FILE = %w[1 2 3 4 5 6 7 8].freeze

  attr_reader :name
  attr_accessor :win

  def initialize(color)
    @name = nil
    @player_color = color
    @win = false
    update_white_player_name if color == 'white'
    update_black_player_name if color == 'black'
  end

  def update_white_player_name
    puts "\nWhite, please enter your name: "
    @name = gets.chomp
  end

  def update_black_player_name
    puts "\nBlack, please enter your name: "
    @name = gets.chomp
  end

  # Ask player for new location for selected piece and output resulting new board with updated next moves
  def move_piece(board)
    # Remove current player pawns' en_passant vulnerability
    refresh_pawn(board)

    # Ask player for a piece to move
    old_position = select_piece_to_move(board)
    new_position = ask_for_notation('move')
    selected_piece = board.positions[old_position[0]][old_position[1]]

    # Ask player for a valid move
    until move_allowed?(selected_piece, new_position)
      puts "\n\e[1;31mMove is not allowed. Try again\e[0m"
      # start_position = select_piece_to_move(board)
      new_position = ask_for_notation('move')
      selected_piece = board.positions[old_position[0]][old_position[1]]
    end

    # Move the piece and update itself on the board
    selected_piece.update_position(board, new_position, old_position)

    # Refresh every piece's possible next_moves
    board.update_all_pieces_next_moves
  end

  # Player is in check, ask player to move their king
  def move_king_only(board, player, opponent)
    # Dependant on current round's player
    case @player_color
    when 'white'
      rank = board.king_position[:white][0]
      file = board.king_position[:white][1]
      white_king = board.positions[rank][file]

      # End game if it is a checkmate
      return if checkmate?(white_king, opponent)

      # Prompt player to move the king
      puts "\n\e[1;36mCHECK!"
      puts "\e[1;36m#{@name}, move your King!\e[0m\n"

      old_position = white_king.current_position
      new_position = ask_for_notation('move')
      selected_piece = white_king

      # Ask player for a valid move for the king
      until move_allowed?(selected_piece, new_position)
        puts "\n\e[1;31mMove is not allowed. Try again\e[0m"
        # start_position = select_piece_to_move(board)
        new_position = ask_for_notation('move')
        selected_piece = board.positions[old_position[0]][old_position[1]]
      end

      # Move the piece and update itself on the board
      selected_piece.update_position(board, new_position, old_position)

      # Refresh every piece's possible next_moves
      board.update_all_pieces_next_moves
    when 'black'
      rank = board.king_position[:black][0]
      file = board.king_position[:black][1]
      black_king = board.positions[rank][file]

      # End game if it is a checkmate
      return if checkmate?(black_king, opponent)
      # Prompt player to move the king
      puts "\n\e[1;36mCHECK!"
      puts "\e[1;36m#{@name}, move your King!\e[0m\n"

      old_position = black_king.current_position
      new_position = ask_for_notation('move')
      selected_piece = black_king

      # Ask player for a valid move for the king
      until move_allowed?(selected_piece, new_position)
        puts "\n\e[1;31mMove is not allowed. Try again\e[0m"
        # start_position = select_piece_to_move(board)
        new_position = ask_for_notation('move')
        selected_piece = board.positions[old_position[0]][old_position[1]]
      end

      # Move the piece and update itself on the board
      selected_piece.update_position(board, new_position, old_position)

      # Refresh every piece's possible next_moves
      board.update_all_pieces_next_moves
    end
  end

  # Toggle @win = true if it is a checkmate + Output win message
  def checkmate?(king, opponent)
    return unless king.next_moves == []

    puts "\n\e[1;36mCHECKMATE!\e[0m\n"
    puts "\e[1;36m#{opponent.name} is the winner.\e[0m\n"
    opponent.win = true
  end

  # Remove player's own pawns en_passant vulnerability at the start of his turn
  def refresh_pawn(board)
    board.positions.each do |row|
      row.each do |piece|
        next if piece == '-'
        next unless piece.color == @player_color
        next unless piece.symbol == '♟︎' || piece.symbol == '♙'

        piece.en_passant_vulnerable = false
      end
    end
  end

  # Confirm player's choice of piece to be moved and return position
  def select_piece_to_move(board)
    # Repeatedly ask player until valid notation is entered
    position = ask_for_notation('select')
    notation = position_to_notation(position)

    # Loop until selection is valid and verified by player
    until verified_selection?(board, position, notation)
      # Output error statements
      case selection_error(board, position)
      when 'empty'
        puts "\n\e[1;31m Chosen position is empty. Try again.\e[0m"
      when 'wrong color'
        puts "\n\e[1;31mChosen piece does not belong to you. Try again\e[0m"
      when 'no valid moves'
        puts "\n\e[1;31mChosen piece does not have any possible moves. Try again\e[0m"
      end

      board.print_board

      # Looped Actions
      position = ask_for_notation('select')
      notation = position_to_notation(position)
    end

    position
  end

  # Repeat until player entered notation is correct, returns position array
  def ask_for_notation(action)
    puts "#{@name}, please select a piece to move (eg. A3): " if action == 'select'
    puts "#{@name}, where would you like to move the piece: " if action == 'move'
    # Ask for move until a valid chess notation is selected
    notation = gets.chomp
    until valid_notation?(notation)
      puts 'Invalid notation. Try again.'
      notation = gets.chomp
    end
    # Convert and return notation as position array
    notation = notation.split('')
    file = notation[0].downcase
    rank = notation[1]
    notation_to_position(file, rank)
  end

  # Check if move is allowed
  def move_allowed?(piece, new_position)
    valid_moves = piece.next_moves
    return true if valid_moves.include?(new_position)

    false
  end

  # Verify user selection
  def verified_selection?(board, position, notation)
    selected_piece = board.positions[position[0]][position[1]]
    return false if selected_piece == '-'
    return false unless selected_piece.color == @player_color
    return false if selected_piece.next_moves == []

    puts "\n\e[1;33m#{@name}, you have selected to move #{notation}'s #{selected_piece.symbol}.\e[1;0m"
    puts "\e[1;32mPress any key to continue.\e[1;0m"
    puts "\e[1;31mPress 'C' to reselect.\e[1;0m\n"

    response = $stdin.getch
    return false if %w[C c].include?(response)

    true
  end

  # Check if space selected contains a piece of player's color
  def selection_error(board, position)
    selected_space = board.positions[position[0]][position[1]]

    return 'empty' if selected_space == '-'
    return 'wrong color' unless selected_space.color == @player_color
    return 'no valid moves' if selected_space.next_moves == []

    true
  end

  # Check if entry is a valid chess notation
  def valid_notation?(notation)
    return false unless notation.length == 2

    array = notation.split('')
    return false unless Player::RANK.include?(array[0])
    return false unless Player::FILE.include?(array[1])

    true
  end

  # Convert notation to position array
  def notation_to_position(file, rank)
    position = []
    position.push((rank.to_i - 1))
    position.push((file.ord - 97))
  end

  # Convert position array to notation
  def position_to_notation(position)
    file = position[1]
    rank = position[0]
    (file + 97).chr.upcase + (rank + 1).to_s
  end
end

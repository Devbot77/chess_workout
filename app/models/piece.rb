class Piece < ActiveRecord::Base
  # shared functionality for all pieces goes here
  belongs_to :game
  has_many :moves

  # Check if move is valid for selected piece
  def valid_move?(params)
    set_coords(params)
    return false unless legal_move?
    return false if pinned?
    opponent_in_check?
    update_attributes(x_position: @x0, y_position: @y0)
    true
  end

  def set_coords(params)
    @x0 = self.x_position
    @y0 = self.y_position
    @x1 = params[:x_position].to_i
    @y1 = params[:y_position].to_i
    @sx = @x1 - @x0 # sx = displacement_x
    @sy = @y1 - @y0 # sy = displacement_y
  end

  # Check to see if the movement path is a valid diagonal move
  def diagonal_move?
    @sy.abs == @sx.abs
  end

  def white?
    self.color == 'white'
  end

  def black?
    self.color == 'black'
  end

  # Check to see if the movement pat is a valid straight move
  def straight_move?
    @x1 == @x0 || @y1 == @y0
  end

  # This method can be called by all piece types except the knight, whose moves are not considered below.
  # This will return true if there is no piece along the chosen movement path that has not been captured.
  def path_clear?
    clear = true
    piece_coords = game.piece_map
    if @x0 != @x1 && @y0 == @y1   # Check horizontal path
      @x1 > @x0 ? x = @x0 + 1 : x = @x0 - 1
      until x == @x1 do
        if piece_coords.include?([x, @y0])
          clear = false
          break
        end
        x > @x1 ? x -= 1 : x += 1
      end
    elsif @x0 == @x1 && @y0 != @y1    # Check vertical path
      @y1 > @y0 ? y = @y0 + 1 : y = @y0 - 1
      until y == @y1 do
        if piece_coords.include?([@x0, y])
          clear = false
          break
        end
        y > @y1 ? y -= 1 : y += 1
      end
    elsif @x0 != @x1 && @y0 != @y1    # Check diagonal path
      @x1 > @x0 ? x = @x0 + 1 : x = @x0 - 1
      @y1 > @y0 ? y = @y0 + 1 : y = @y0 - 1
      until x == @x1 && y == @y1 do
        if piece_coords.include?([x, y])
          clear = false
          break
        end
        x > @x1 ? x -= 1 : x += 1
        y > @y1 ? y -= 1 : y += 1
      end
    end
    clear
  end

  # Check the piece currently at the destination square. If there is no piece, return nil.
  def destination_piece
    game.pieces.where(x_position: @x1, y_position: @y1, captured: nil).first
  end

  # Update status of captured piece accordingly and create new move to send to browser to update client side.
  def capture_destination_piece
    if destination_piece && capture_piece?
      Move.create(game_id: game.id, piece_id: destination_piece.id, old_x: @x1, old_y: @y1, captured_piece: true)
      destination_piece.update_attributes(captured: true)
    end
  end

  # Check to see if destination square is occupied by a piece, returning false if it is friendly or true if it is an opponent
  def capture_piece?
    return false if destination_piece && destination_piece.color == color
    true
  end

  # ***********************************************************
  # Check & Checkmate needs specific attention!!
  # => It involves all potentially threatening pieces
  # => Three moves allowed under check
  # => 1) Capture threatening pieces
  # => 2) Block threatening pieces
  # => 3) Move King to unchecking position
  # ***********************************************************

  # Use to determine if opposing king in check.
  def demo_check?(player_color)
    player_color == "white" ? opponent_color = "black" : opponent_color = "white"
    @opponent_king = game.pieces.where(type: "King", color: opponent_color).first
    friendly_pieces = game.pieces.where(color: player_color, captured: nil).to_a
    in_check = false
    @threatening_pieces = []
    friendly_pieces.each do |piece|
      piece.set_coords({x_position: @opponent_king.x_position, y_position: @opponent_king.y_position})
      if piece.legal_move?
        in_check = true
        @threatening_pieces << piece
      end
    end
    in_check
  end

  # Determine if opponent is in check or checkmate. 
  def opponent_in_check?
    if demo_check?(color)
      if demo_checkmate?
        game.status = "checkmate"
        game.winner = color
      else
        game.status = "check"
      end
    else
      game.status = nil
      return false
    end
  end

  # Determine if checkmate on opposing king has occurred.
  def demo_checkmate?
    checkmate = false
    can_escape = false
    can_block = false
    can_capture_threat = false
    escape_moves = @opponent_king.possible_moves
    if color == "white"
      opponent_possible_moves = black_moves_noking
      friendly_possible_moves = white_pieces_moves
    else
      opponent_possible_moves = white_moves_noking
      friendly_possible_moves = black_pieces_moves
    end
    # Determine if king in check can escape
    escape_moves.each do |move|
      can_escape = true if !friendly_possible_moves.include?(move)
    end
    
    # Determine if threating piece can be captured or blocked by opposing player. 
    # Can only be true if a singular piece has opposing king in check. 
    if @threatening_pieces.length == 1
      can_capture_threat = true if opponent_possible_moves.include?([@x1, @y1]) || escape_moves.include?([@x1, @y1])

      threat_path(@threatening_pieces[0], @opponent_king).each do |path_coord|
        can_block = true if opponent_possible_moves.include?(path_coord)
      end
    end

    checkmate = true if !can_escape && !can_block && !can_capture_threat
    return checkmate
  end

  def pinned?
    pinned = false
    color == "white" ? opponent_color = "black" : opponent_color = "white"
    update_attributes(x_position: @x1, y_position: @y1)
    if demo_check?(opponent_color)
      if capture_threat?
        pinned = false
      else
        update_attributes(x_position: @x0, y_position: @y0)
        pinned = true
      end
    end
    pinned
  end

  # Determine if current move will capture the threatening piece
  def capture_threat?
    if @threatening_pieces.length == 1
      return true if @x1 == @threatening_pieces.first.x_position && @y1 == @threatening_pieces.first.y_position
      return false
    elsif @threatening_pieces.length > 1
      return false
    end
  end

  def block_threat?
    if @threatening_pieces.length == 1

    else
      return false
    end
  end

  def threat_path(threat, king)
    path = []
    return path if threat.type == "Knight"
    x0 = threat.x_position
    y0 = threat.y_position
    x1 = king.x_position
    y1 = king.y_position
    if x0 != x1 && y0 == y1
      if x1 > x0
        (x0+1...x1).each {|x| path << [x, y0]}
      else
        (x1+1...x0).each {|x| path << [x, y0]}
      end
    elsif x0 == x1 && y0 != y1
      if y1 > y0
        (y0+1...y1).each {|y| path << [y, x0]}
      else
        (y1+1...y0).each {|y| path << [y, x0]}
      end
    else
      if x1 > x0 && y1 > y0
        (x0+1...x1).each {|x| path << [x, y0+(x - x0)]}
      elsif x1 < x0 && y1 > y0
        (x1+1...x0).each {|x| path << [x, y1-(x - x1)]}
      elsif x1 > x0 && y1 < y0
        (x0+1...x1).each {|x| path << [x, y0-(x - x0)]}
      else
        (x1+1...x0).each {|x| path << [x, y1+(x - x1)]}
      end
    end
    return path
  end

  # Find the diagonal paths for a piece given the starting X and Y coordinates of that piece.
  def diagonal_range(x_coord, y_coord)
    range = []
    x = x_coord - 1
    y = y_coord - 1

    until x == 0 || y == 0 do
      range << [x, y]
      x -= 1
      y -= 1
    end

    x = x_coord + 1
    y = y_coord - 1
    until x == 9 || y == 0 do
      range << [x, y]
      x += 1
      y -= 1
    end

    x = x_coord + 1
    y = y_coord + 1
    until x == 9 || y == 9 do
      range << [x, y]
      x += 1
      y += 1
    end

    x = x_coord - 1
    y = y_coord + 1
    until x == 0 || y == 9 do
      range << [x, y]
      x -= 1
      y += 1
    end

    return range
  end

  def all_possible_moves
    @possible_moves ||= white_pieces_moves + black_pieces_moves
  end

  def white_pieces_moves
    @possible_moves = []
    self.game.white_pieces.where(captured: nil).map do |piece|
      @possible_moves += piece.possible_moves
    end
    return @possible_moves
  end

  def black_pieces_moves
    @possible_moves = []
    self.game.black_pieces.where(captured: nil).map do |piece|
      @possible_moves += piece.possible_moves
    end
    return @possible_moves
  end

  def white_moves_noking
    @possible_moves = []
    self.game.white_pieces.where(captured: nil).map do |piece|
      next if piece.type == "King"
      @possible_moves += piece.possible_moves
    end
    return @possible_moves
  end

  def black_moves_noking
    @possible_moves = []
    self.game.black_pieces.where(captured: nil).map do |piece|
      next if piece.type == "King"
      @possible_moves += piece.possible_moves
    end
    return @possible_moves
  end  

  def update_move
    moves.where(piece_id: id).first.nil? ? inc_move = 1 : inc_move = moves.where(piece_id: id).last.move_count + 1
    Move.create(game_id: game.id, piece_id: id, move_count: inc_move, old_x: @x0, new_x: @x1, old_y: @y0, new_y: @y1)
  end

  # *** Use this for the pawns !!***
  def first_move?
    self.moves.first.nil?
  end

  def self.join_as_black(user)
    self.all.each do |black_piece|
      black_piece.update_attributes(player_id: user.id)
    end
  end

end

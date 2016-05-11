class King < Piece

  def legal_move?
    return false unless (straight_move? || diagonal_move?) && path_clear?
    return false unless move_size || castle_move
    capture_piece?
  end

  def possible_moves
    possible_moves = []
    x = x_position
    y = y_position

    range = [[x,y-1], [x+1,y-1], [x+1,y], [x+1,y+1], [x,y+1], [x-1,y+1], [x-1,y], [x-1,y-1]]

    range.each do |coord|
      next if !(1..8).include?(coord[0]) || !(1..8).include?(coord[1])
      set_coords({x_position: coord[0], y_position: coord[1]})
      possible_moves << [@x1, @y1] if legal_move?
    end

    # need to check if castling possible as well

    return possible_moves
  end

  # ***********************************************************
  # Castling needs specific attention!!
  # => It involves either Rook
  # => It involves checking if King has moved before
  # => It involves checking if King is under check
  # => It involves checking if castling path is under check
  # ***********************************************************

  def castle_move
    return false if @sx.abs != 2
    # If the king is moving two spaces to the left:
    if @x1 < @x0
      @target_rook = game.pieces.where(x_position: 1, y_position: @y0).first
    # If the king is moving two spaces to the right:
    else
      @target_rook = game.pieces.where(x_position: 8, y_position: @y0).first
    end
    return false if @target_rook.nil?
    # Neither the king nor the rook have moved:
    return false if !first_move? || !@target_rook.first_move?
    # Move the rook to the other side of the moved king:
    if @target_rook.x_position == 1
      @target_rook.update_attributes(x_position: 4)
      Move.create(game_id: game.id, piece_id: @target_rook.id, move_count: 1, old_x: 1, new_x: 4, old_y: @y0, new_y: @y0)
    else
      @target_rook.update_attributes(x_position: 6)
      Move.create(game_id: game.id, piece_id: @target_rook.id, move_count: 1, old_x: 8, new_x: 6, old_y: @y0, new_y: @y0)
    end
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

  def under_check
    # Define permitted moves for the king, when under check.
  end

  def move_size
    return false if @sx.abs > 1 || @sy.abs > 1
    @sx.abs <= 1 && @sy.abs <= 1
  end
end


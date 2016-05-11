class Bishop < Piece
  def legal_move?
    return false unless diagonal_move? && path_clear?
    capture_piece?
  end

  def possible_moves
    possible_moves = []
    x = x_position
    y = y_position

    range = diagonal_range(x, y)
    range.each do |coords|
      set_coords({x_position: coords[0], y_position: coords[1]})
      possible_moves << [@x1, @y1] if legal_move?
    end

    return possible_moves
  end
end

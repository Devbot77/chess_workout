class Rook < Piece
  def legal_move?
    return false unless straight_move? && path_clear?
    capture_piece?
  end

  def possible_moves
    possible_moves = []
    x = x_position
    y = y_position

    # check horizontal moves
    (1..8).each do |n|
      next if n == x
      set_coords({x_position: n, y_position: y}) 
      possible_moves << [@x1, @y1] if legal_move?
    end

    # check vertical moves
    (1..8).each do |n|
      next if n == y
      set_coords({x_position: x, y_position: n})
      possible_moves << [@x1, @y1] if legal_move?
    end

    return possible_moves
  end
end

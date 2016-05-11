class Knight < Piece
  def legal_move?
    return false unless rectangle_move?
    capture_piece?
  end

  def rectangle_move?
    sx_abs = @sx.abs
    sy_abs = @sy.abs
    (sx_abs == 1 && sy_abs == 2) || (sx_abs == 2 && sy_abs == 1)
  end

  def possible_moves
    possible_moves = []
    x = x_position
    y = y_position

    range = [[x-2,y-1], [x-1,y-2], [x+1,y-2], [x+2,y-1], [x+2,y+1], [x+1,y+2], [x-1,y+2], [x-2,y+1]]

    range.each do |coord|
      next if !(1..8).include?(coord[0]) || !(1..8).include?(coord[1])
      set_coords({x_position: coord[0], y_position: coord[1]})
      possible_moves << [@x1, @y1] if capture_piece?
    end

    return possible_moves
  end
end

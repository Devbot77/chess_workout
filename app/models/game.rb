class Game < ActiveRecord::Base
	has_many :pieces
	belongs_to :white_player, class_name: 'User', foreign_key: :white_player_id
  belongs_to :black_player, class_name: 'User', foreign_key: :black_player_id
  after_create :initialize_board

  # Directly create pieces and add them to the pieces collection.
  def initialize_board

    # Non-pawns for black player:
    Rook.create(x_position: 0, y_position: 0, game_id: id, color: "black")
    Knight.create(x_position: 1, y_position: 0, game_id: id, color: "black")
    Bishop.create(x_position: 2, y_position: 0, game_id: id, color: "black")    
    Queen.create(x_position: 3, y_position: 0, game_id: id, color: "black")
    King.create(x_position: 4, y_position: 0, game_id: id, color: "black")
    Bishop.create(x_position: 5, y_position: 0, game_id: id, color: "black")
    Knight.create(x_position: 6, y_position: 0, game_id: id, color: "black")
    Rook.create(x_position: 7, y_position: 0, game_id: id, color: "black")

    # Non-pawns for white player:
    Rook.create(x_position: 0, y_position: 7, game_id: id, color: "white")
    Knight.create(x_position: 1, y_position: 7, game_id: id, color: "white")
    Bishop.create(x_position: 2, y_position: 7, game_id: id, color: "white")
    Queen.create(x_position: 3, y_position: 7, game_id: id, color: "white")
    King.create(x_position: 4, y_position: 7, game_id: id, color: "white")
    Bishop.create(x_position: 5, y_position: 7, game_id: id, color: "white")
    Knight.create(x_position: 6, y_position: 7, game_id: id, color: "white")    
    Rook.create(x_position: 7, y_position: 7, game_id: id, color: "white")

    # Pawns for both players:
    for i in 0..7
      Pawn.create(color: "black", x_position: i, y_position: 1, game_id: id)
      Pawn.create(color: "white", x_position: i, y_position: 6, game_id: id)
    end
  end
end

require 'pry'

class PiecesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_authorized_for_current_game
  # before_action :require_authorized_for_current_piece

  def update
    # if move is valid. Call back methods from model.
    current_piece.update_attributes(piece_params)
    render text: 'updated!'
  end

  private

  def current_piece
    @current_piece ||= Piece.find(params[:id])
  end

  def require_authorized_for_current_piece
    if @current_piece.player_id != current_user.id && @current_piece.player_id != current_user.id
      render text: 'Unauthorized', status: :unauthorized
    end
  end

  def piece_params
    params.require(:piece).permit(:x_position, :y_position, :type, :captured)
  end

  def current_game
    @current_game ||= Game.find_by(params[:game_id])
  end

  def require_authorized_for_current_game
    # binding.pry
    if current_game.white_player != current_user && current_game.black_player != current_user
      render text: 'Unauthorized', status: :unauthorized
    end
  end
end
require 'rails_helper'

RSpec.describe PiecesController, type: :controller do
  describe "Action: pieces#update" do
    it "should update a pawn's position and advance the game to the next turn after a valid move" do
      user_sign_in
      game = FactoryGirl.create(:game, :white_player_id => @user.id)
      piece = FactoryGirl.create(:white_pawn, :game => game, :player_id => @user.id)

      # Move a white pawn 2 vertical spaces on its first turn:
      put :update, :id => piece.id, :piece => { :x_position => 1, :y_position => 5 }, :format => :js
      piece.reload

      expect(piece.y_position).to eq 5
      expect(piece.game.turn).to eq 2
    end

    it "should check for invalid pawn moves" do

    end

    it "should check for blocking" do

    end

    it "should update a rook's position and advance the game to the next turn after a valid move" do
      user_sign_in
      game = FactoryGirl.create(:game, :white_player_id => @user.id)
      # The white rook begins at [2, 4]
      white_rook = FactoryGirl.create(:white_rook, :game => game, :player_id => @user.id)
      white_rook.update_attributes(:x_position => 2, :y_position => 4)
      white_rook.reload

      # Move a white rook 3 horizontal spaces to the right on its first turn:
      put :update, :id => white_rook.id, :piece => { :x_position => 5, :y_position => 4 }, :format => :js
      white_rook.reload

      expect(white_rook.x_position).to eq 5
      expect(white_rook.y_position).to eq 4
      expect(white_rook.game.turn).to eq 2
    end

    describe "en passant capture of the black pawn" do
      let(:user) { FactoryGirl.create(:user) }
      let(:user2) { FactoryGirl.create(:user) }
      let(:game) { FactoryGirl.create(:game, :white_player_id => user.id, :black_player_id => user2.id) }
      let!(:white_pawn) do
        p = game.pieces.where(:type => "Pawn", :color => "white").first
        p.update_attributes(:x_position => 2, :y_position => 4)
        p
      end
      let!(:black_pawn) do
        p = game.pieces.where(:type => "Pawn", :color => "black").first
        p.update_attributes(:x_position => 1, :y_position => 4)
        p
      end

      before do
        sign_in user
      end

      it "should recognize a valid en passant move by the white pawn" do
        white_pawn_start_x = white_pawn.x_position
        white_pawn_start_y = white_pawn.y_position

        # The white pawn makes an en passant capture on the black pawn, moving from [2, 4] to [1, 3] (assume en passant is valid prior to confirming below)
        put :update, :id => white_pawn.id, :piece => { :x_position => 1, :y_position => 3 }, :format => :js
        white_pawn.reload

        # Check that the white pawn can execute the en_passant move
        expect(white_pawn.en_passant?(white_pawn_start_x, white_pawn_start_y, white_pawn.x_position, white_pawn.y_position)).to eq true
        expect(white_pawn.x_position).to eq 1
        expect(white_pawn.y_position).to eq 3
        expect(white_pawn.game.turn).to eq 2
      end

      it "should not recognize an invalid en passant move by the white pawn" do
        white_pawn_start_x = white_pawn.x_position
        white_pawn_start_y = white_pawn.y_position

        put :update, :id => white_pawn.id, :piece => { :x_position => 3, :y_position => 3 }, :format => :js
        white_pawn.reload

        expect(white_pawn.en_passant?(white_pawn_start_x, white_pawn_start_y, white_pawn.x_position, white_pawn.y_position)).to eq nil
        expect(white_pawn.x_position).to eq 2
        expect(white_pawn.y_position).to eq 4
        expect(white_pawn.game.turn).to eq 1
      end
    end

    describe "en passant capture of the white pawn" do
      let(:user) { FactoryGirl.create(:user) }
      let(:user2) { FactoryGirl.create(:user) }
      let(:game) { FactoryGirl.create(:game, :white_player_id => user.id, :black_player_id => user2.id, :turn => 2) }
      let!(:white_pawn) do
        p = game.pieces.where(:type => "Pawn", :color => "white").first
        p.update_attributes(:x_position => 2, :y_position => 5)
        p
      end
      let!(:black_pawn) do
        p = game.pieces.where(:type => "Pawn", :color => "black").first
        p.update_attributes(:x_position => 1, :y_position => 5)
        p
      end
      let(:move) { FactoryGirl.create(:move, :game_id => game.id, :piece_id => white_pawn.id, :move_count => 1) }
      let(:move) { FactoryGirl.create(:move, :game_id => game.id, :piece_id => black_pawn.id, :move_count => 0) }

      before do
        sign_in user2
      end

      it "should recognize a valid en passant move by the black pawn" do
        black_pawn_start_x = black_pawn.x_position
        black_pawn_start_y = black_pawn.y_position

        put :update, :id => black_pawn.id, :piece => { :x_position => 2, :y_position => 6 }, :format => :js
        black_pawn.reload

        expect(black_pawn.en_passant?(black_pawn_start_x, black_pawn_start_y, black_pawn.x_position, black_pawn.y_position)).to eq true
        expect(black_pawn.x_position).to eq 2
        expect(black_pawn.y_position).to eq 6
        expect(black_pawn.game.turn).to eq 3
      end

      it "should not recognize an invalid en passant move by the black pawn" do
        black_pawn_start_x = black_pawn.x_position
        black_pawn_start_y = black_pawn.y_position

        put :update, :id => black_pawn.id, :piece => { :x_position => 2, :y_position => 7 }, :format => :js
        black_pawn.reload

        expect(black_pawn.en_passant?(black_pawn_start_x, black_pawn_start_y, black_pawn.x_position, black_pawn.y_position)).to eq nil
        expect(black_pawn.x_position).to eq 1
        expect(black_pawn.y_position).to eq 5
        expect(black_pawn.game.turn).to eq 2
      end
    end


    it "should allow pawn promotion" do
      user_sign_in
    end


    it "should recognize castling as a valid move" do
      user_sign_in
    end


    it "should test for checkmate" do
      user_sign_in
    end
  end

  private
  def user_sign_in
    @user = FactoryGirl.create(:user)
    sign_in @user
  end
end

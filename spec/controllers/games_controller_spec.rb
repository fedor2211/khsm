# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when not logged in' do
      before { get :show, id: game_w_questions.id }

      it 'redirects to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'response status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'creates flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'and try to show owned game' do
        before { get :show, id: game_w_questions.id }

        it 'response status equal 200' do
          expect(response.status).to eq(200)
        end

        it 'loads owned game' do
          game = assigns(:game)
          expect(game.user).to eq(user)
        end

        it 'renders show template' do
          expect(response).to render_template('show')
        end
      end

      context 'and try to show other user game' do
        before do
          new_game = create(:game_with_questions)
          get :show, id: new_game.id
        end

        it 'response status equal 200' do
          expect(response.status).not_to eq(200)
        end

        it 'redirects to root path' do
          expect(response).to redirect_to(root_path)
        end

        it 'creates flash alert' do
          expect(flash[:alert]).to be
        end
      end
    end

  end

  describe '#create' do
    context 'when not logged in' do
      before do
        generate_questions(15)
        post :create
      end

      it 'redirects to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'response status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'creates flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'and has no game in progress' do
        before do
          generate_questions(15)
          post :create
        end

        let(:game) { assigns(:game) }

        it 'creates game belonging to current user' do
          expect(game.user).to eq(user)
        end

        it 'redirects to new game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'creates notice' do
          expect(flash[:notice]).to be
        end
      end

      context 'and has game in progress' do
        let(:game) { assigns(:game) }

        it 'does not create a new game' do
          request.env["HTTP_REFERER"] = 'http://test.host/'
          expect { post :create }.to change(Game, :count).by(0)
        end

        it 'game is nil' do
          expect(game).to be_nil
        end
      end
    end
  end

  describe '#answer' do
    context 'when not logged in' do
      before do
        put :answer, id: game_w_questions.id
      end

      it 'redirects to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'response status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'creates flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before do
        sign_in user
      end

      context 'when answer is correct' do
        before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
        let(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to eq false
        end

        it 'redirects to current_game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'does not create flash messages' do
          expect(flash.empty?).to eq true
        end
      end

      context 'when answer is incorrect' do
        before do
          incorrect_answer_key = (['a', 'b', 'c', 'd'] - [game_w_questions.current_game_question.correct_answer_key]).sample
          put :answer, id: game_w_questions.id, letter: incorrect_answer_key
        end
        let(:game) { assigns(:game) }

        it 'finishes game' do
          expect(game.finished?).to eq true
        end

        it 'fails game' do
          expect(game.status).to eq(:fail)
        end

        it 'redirects to current user profile' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'creates flash alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'when not logged in' do
      before { put :take_money, id: game_w_questions.id }

      it 'redirects to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'response status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'creates flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before(:each) { sign_in user }

      context 'and takes money before win' do
        before do
          game_w_questions.update_attribute(:current_level, 2)
          put :take_money, id: game_w_questions.id
        end
        let(:game) { assigns(:game) }

        it 'finishes game' do
          expect(game.finished?).to eq true
        end

        it 'correctly calculates game prize' do
          expect(game.prize).to eq(200)
        end

        it 'redirects to current user profile' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'creates flash warning' do
          expect(flash[:warning]).to be
        end
      end
    end
  end

  describe '#help' do
    context 'when not logged in' do
      before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

      it 'redirects to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'response status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'creates flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'and uses audience help' do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }
        let(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to eq false
        end

        it 'remembers audience help is used' do
          expect(game.audience_help_used).to eq true
        end

        it 'fills audience help help_hash' do
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'correctly fills audience help help_hash' do
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'redirects to current game' do
          expect(response).to redirect_to(game_path(game))
        end
      end

      context 'and uses fifty_fifty first time' do
        before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }
        let(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to eq false
        end

        it 'remembers fifty_fifty is used' do
          expect(game.fifty_fifty_used).to eq true
        end

        it 'fills fifty_fifty help_hash' do
          expect(game.current_game_question.help_hash[:fifty_fifty]).to be
        end

        it 'correctly fills fifty_fifty help_hash' do
          expect(
            game.current_game_question.help_hash[:fifty_fifty]
          ).to include(game.current_game_question.correct_answer_key)
        end

        it 'redirects to current game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'creates flash info' do
          expect(flash[:info]).to be
        end
      end

      context 'and uses fifty_fifty help second time' do
        before do
          put :help, id: game_w_questions.id, help_type: :fifty_fifty
          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end
        let(:game) { assigns(:game) }

        it 'does not finish game' do
          expect(game.finished?).to eq false
        end

        it 'redirects to current game' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'creates flash info' do
          expect(flash[:alert]).to be
        end
      end
    end
  end
end

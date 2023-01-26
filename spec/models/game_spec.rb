# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '.create_game!' do
    before do
      generate_questions(60)
    end
    let!(:game_count) { Game.count }
    let!(:game_question_count) { GameQuestion.count }
    let!(:question_count) { Question.count }
    let!(:game) { Game.create_game_for_user!(user)}

    it 'changes game count' do
      expect(Game.count).to eq(game_count + 1)
    end

    it 'changes game question count' do
      expect(GameQuestion.count).to eq(game_question_count + 15)
    end

    it 'does not change question count' do
      expect(Question.count).to eq(question_count)
    end

    it 'belongs to current user' do
      expect(game.user).to eq(user)
    end

    it 'status is :in_progress' do
      expect(game.status).to eq(:in_progress)
    end

    it 'game questions size is equal to 15' do
      expect(game.game_questions.size).to eq(15)
    end

    it 'game questions levels are correct' do
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  describe '#take_money!' do
    it 'finishes the game' do
      user_current_money = game_w_questions.user.balance
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!
      expect(game_w_questions.prize).to be > 0
      expect(game_w_questions.user.balance).to eq(user_current_money + game_w_questions.prize)
      expect(game_w_questions.finished?).to eq(true)
    end
  end

  describe '#status' do
    context 'when game failed' do
      it 'returns :fail' do
        q = game_w_questions.current_game_question
        incorrect_answer_key =
          %w[a b c d]
            .grep_v(game_w_questions.current_game_question.correct_answer_key)
            .sample
        game_w_questions.answer_current_question!(incorrect_answer_key)
        expect(game_w_questions.status).to eq :fail
      end
    end

    context 'when timeout reached' do
      it 'returns :timeout' do
        game_w_questions.created_at -= Game::TIME_LIMIT
        game_w_questions.save!
        game_w_questions.time_out!
        expect(game_w_questions.status).to eq :timeout
      end
    end

    context 'when game won' do
      it 'returns :won' do
        15.times do
          q = game_w_questions.current_game_question
          game_w_questions.answer_current_question!(q.correct_answer_key)
        end
        expect(game_w_questions.status).to eq :won
      end
    end

    context 'when money taken before win' do
      it 'returns :money' do
        10.times do
          q = game_w_questions.current_game_question
          game_w_questions.answer_current_question!(q.correct_answer_key)
        end
        game_w_questions.take_money!
        expect(game_w_questions.status).to eq :money
      end
    end

    describe '#current_game_question' do
      it 'returns question with current level' do
        expect(game_w_questions.current_game_question).to eq game_w_questions.game_questions[0]
      end
    end

    describe '#previous_level' do
      context 'when current level 0' do
        it 'returns -1' do
          expect(game_w_questions.previous_level).to eq -1
        end
      end
    end

    describe '#answer_current_question!' do
      context 'when answer correct' do
        context 'and question is not last' do
          let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }
          let!(:level) { game_w_questions.current_level }
          before { game_w_questions.answer_current_question!(answer_key) }

          it 'increases level by 1' do
            expect(game_w_questions.current_level).to eq(level + 1)
          end

          it 'game status remains :in_progress' do
            expect(game_w_questions.status).to eq(:in_progress)
          end

          it 'does not finish game' do
            expect(game_w_questions.finished?).to eq(false)
          end
        end

        context 'and question is last' do
          let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }
          before do
            game_w_questions.current_level = 14
            game_w_questions.answer_current_question!(answer_key)
          end

          it 'changes game status to :won' do
            expect(game_w_questions.status).to eq(:won)
          end

          it 'finishes game' do
            expect(game_w_questions.finished?).to eq(true)
          end
        end
      end

      context 'when answer incorrect' do
        let!(:answer_key) do
          %w[a b c d]
            .grep_v(game_w_questions.current_game_question.correct_answer_key)
            .sample
        end
        before { game_w_questions.answer_current_question!(answer_key) }

        it 'game status changes to :fail' do
          expect(game_w_questions.status).to eq(:fail)
        end

        it 'finishes game' do
          expect(game_w_questions.finished?).to eq(true)
        end
      end

      context 'when timeout reached' do
        let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }
        before do
          game_w_questions.created_at -= Game::TIME_LIMIT
          game_w_questions.save!
          game_w_questions.answer_current_question!(answer_key)
        end

        it 'game status changes to :timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end

        it 'finishes game' do
          expect(game_w_questions.finished?).to eq(true)
        end
      end
    end
  end
end

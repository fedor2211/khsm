# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '#text' do
    it 'returns question text' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe '#level' do
    it 'returns question level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  # тест на правильную генерацию хэша с вариантами
  describe '#variants' do
    it 'returns question variants hash' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3})
    end
  end

  describe '#correct_answer_key' do
    it 'returns key for correct answer' do
      expect(game_question.correct_answer_key).to eq 'b'
    end
  end

  describe '#answer_correct?' do
    context 'when answer is correct' do
      it 'returns true' do
        expect(game_question.answer_correct?('b')).to be_truthy
      end
    end

    context 'when answer is incorrect' do
      it 'returns false' do
        expect(game_question.answer_correct?('a')).to be_falsey
      end
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  describe '#add_audience_help' do
    before { game_question.add_audience_help }

    it 'creates audience_help entry' do
      expect(game_question.help_hash).to include(:audience_help)
    end

    it 'entry is a hash' do
      expect(game_question.help_hash[:audience_help]).to be_a(Hash)
    end

    it 'entry contains all variants keys' do
      expect(
        game_question.help_hash[:audience_help].keys
      ).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  describe '#add_friend_call' do
    before { game_question.add_friend_call }

    it 'creates help_hash_entry' do
      expect(game_question.help_hash).to include(:friend_call)
    end

    it 'entry is a string' do
      expect(game_question.help_hash[:friend_call]).to be_a(String)
    end

    it 'entry string is not empty' do
      expect(game_question.help_hash[:friend_call]).not_to be_empty
    end
  end

  describe '#add_fifty_fifty' do
    before { game_question.add_fifty_fifty }

    it 'creates help_hash entry' do
      expect(game_question.help_hash).to include(:fifty_fifty)
    end

    it 'entry is an array' do
      expect(game_question.help_hash[:fifty_fifty]).to be_a Array
    end

    it 'entry contains half of variants' do
      expect(game_question.help_hash[:fifty_fifty].size).to eq(2)
    end

    it 'entry contains correct answer' do
      expect(
        game_question.help_hash[:fifty_fifty]
      ).to include(game_question.correct_answer_key)
    end
  end

  describe '#help_hash' do
    it 'returns hash' do
      expect(game_question.help_hash).to be_a(Hash)
    end
  end
end

require 'rails_helper'
require 'support/my_spec_helper'

RSpec.feature 'USER views not own profile', type: :feature do
  before do
    generate_questions(30)
  end
  let(:user) { create(:user) }
  let(:games) { create_pair(:game_with_questions, user: user }

  scenario 'successfully' do
    games[0].current_level = 10
    games[0].take_money!

    visit user_path(user)

    expect(page).to have_current_path(user_path(user))
    expect(page).to have_content(user.name)
    expect(page).not_to have_content('Сменить имя и пароль')

    expect(page).to have_content('#')
    expect(page).to have_content('Дата')
    expect(page).to have_content('Вопрос')
    expect(page).to have_content('Выигрыш')
    expect(page).to have_content('Подсказки')

    expect(page).to have_content(/[1-3]?[0-9] \p{Word}{3,4}\., [1-2]?[0-9]:[0-5][0-9]/)
    expect(page).to have_content(/0 ₽/)
    expect(page).to have_content(/32 000 ₽/)
    expect(page).to have_content('деньги')
    expect(page).to have_content('в процессе')
  end
end

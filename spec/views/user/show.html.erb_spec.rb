require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.create(:user, name: "FooUser", balance: 4000) }
  before do
    assign(:user, user)
    assign(:games, [
      FactoryBot.build_stubbed(:game),
      FactoryBot.build_stubbed(:game)
    ])
    stub_template('users/_game.html.erb' => 'User game stub.')
    render
  end

  it 'renders user game partial' do
    expect(rendered).to have_content('User game stub.')
  end

  it 'renders username' do
    expect(rendered).to have_content(user.name)
  end

  context 'when logged in' do
    before do
      sign_in user
      render
    end

    it 'renders change password button' do
      expect(rendered).to match('Сменить имя и пароль')
    end
  end

  context 'when not logged in' do
    it 'does not render change password button' do
      expect(rendered).not_to match('Сменить имя и пароль')
    end
  end
end

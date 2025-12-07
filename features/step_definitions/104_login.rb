# frozen_string_literal: true

require "securerandom"

# Background setup - cria usuário de teste
Given('that I am on the login page') do
  # Garante que existe um usuário válido para testar o login
  unless defined?(@test_user)
    user_attrs = {
      nome: "Usuário Teste",
      email: "usuario@example.com",
      identifier: SecureRandom.uuid,
      matricula: "20231234567",
      curso: "Ciência da Computação",
      password: "senha123"
    }

    # Adiciona pending_activation apenas se o campo existir
    user_attrs[:pending_activation] = false if Dicente.column_names.include?("pending_activation")

    @test_user = Dicente.create!(user_attrs)
  end

  visit login_path
end

When('I fill in the {string} field with {string}') do |field, value|
  case field.downcase
  when "email"
    fill_in "email", with: value
  when "password"
    fill_in "password", with: value
  else
    fill_in field, with: value
  end
end

When('I click on {string}') do |button_text|
  click_button button_text
end

Then('I should be on the evaluations page') do
  expect(page).to have_current_path(avaliacoes_path)
end

Then('I should see {string}') do |message|
  expect(page).to have_content(message)
end

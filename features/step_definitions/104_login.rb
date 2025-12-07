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
  # Aguardar a página carregar completamente
  expect(page).to satisfy do |p|
    p.has_content?("CAMAAR", wait: 5) ||
      p.has_content?("Importação", wait: 5) ||
      p.has_content?("Templates", wait: 5)
  end

  # Tentar encontrar por texto primeiro
  if page.has_button?(button_text, wait: 2)
    click_button button_text
  elsif page.has_link?(button_text, wait: 2)
    click_link button_text
  else
    # Tentar encontrar por data-testid se for um botão conhecido
    case button_text
    when /importar.*database/i, /importar.*dados/i, /update.*database/i
      # Aguardar o botão aparecer
      expect(page).to have_selector("[data-testid='update-database-button']", wait: 10)
      find("[data-testid='update-database-button']", wait: 10).click
    else
      # Tentar encontrar por texto parcial ou data-testid
      begin
        click_button button_text
      rescue Capybara::ElementNotFound
        # Se não encontrar, tentar por data-testid
        testid = button_text.downcase.tr(' ', '-').gsub(/[^a-z0-9-]/, '')
        if page.has_selector?("[data-testid='#{testid}']", wait: 2)
          find("[data-testid='#{testid}']").click
        else
          raise
        end
      end
    end
  end
end

Then('I should be on the evaluations page') do
  # Dicentes são redirecionados para formularios_pendentes_path após login
  expect(page).to have_current_path(formularios_pendentes_path)
end

# Step genérico para mensagens
# IMPORTANTE: Mensagens específicas de base_dados.feature têm steps dedicados em base_dados.rb
# que usam regex e têm prioridade. Este step é usado para outras mensagens.
#
# Para evitar ambiguidade, este step usa um padrão que não captura mensagens específicas:
# - "Database update started"
# - "Database updated successfully"
# - "Database is already up to date"
# - "Partial update completed"
# - "Access denied"
Then(/^I should see "(?!(?:Database update started|Database updated successfully|Database is already up to date|Partial update completed|Access denied)")([^"]+)"$/) do |message|
  expect(page).to have_content(message)
end

# frozen_string_literal: true

require "securerandom"

Given('que estou autenticado como administrador') do
  # Criar admin se não existir
  unless defined?(@admin_docente) && @admin_docente.present?
    generated_identifier = SecureRandom.uuid
    @admin_docente = Docente.create!(
      nome: "Administrador",
      email: "admin-#{generated_identifier}@example.com",
      identifier: generated_identifier,
      departamento: "Coordenação",
      titulacao: "Mestre",
      password: "senha123",
      admin: true
    )

    # Mantém compatibilidade com cenários que esperam @admin
    @admin = @admin_docente
  end

  # Fazer login apenas se não estiver logado
  unless @admin_logged_in
    begin
      # Tentar verificar se já está logado
      current_path = page.current_path rescue nil
      is_logged_in = current_path && current_path != login_path &&
                     (page.has_content?("Templates") rescue false) ||
                     (page.has_content?("Avaliações") rescue false) ||
                     (page.has_content?("Resultados") rescue false)

      unless is_logged_in
        visit login_path
        fill_in "email", with: @admin_docente.email
        fill_in "password", with: "senha123"
        click_button "Entrar"
      end
    rescue Capybara::ElementNotFound, NoMethodError, Capybara::NotSupportedByDriverError
      # Se houver erro, visitar página e fazer login
      visit login_path
      fill_in "email", with: @admin_docente.email
      fill_in "password", with: "senha123"
      click_button "Entrar"
    end
    @admin_logged_in = true
  end
end

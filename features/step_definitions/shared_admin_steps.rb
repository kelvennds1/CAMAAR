# frozen_string_literal: true

require "securerandom"

Given('que estou autenticado como administrador') do
  next if defined?(@admin_docente) && @admin_docente.present?

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

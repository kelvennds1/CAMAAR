# frozen_string_literal: true

require "securerandom"

Given('estou na página {string} do sistema') do |path|
	ensure_admin_present
	case path
	when "gerenciamento/templates"
		visit management_templates_path(admin_id: @admin_docente.id)
	else
		visit("/#{path}")
	end
end

Given('que existem templates cadastrados para o administrador atual:') do |table|
	ensure_admin_present
	table.hashes.each do |row|
		create_template_for(@admin_docente, row['nome'])
	end
	@other_template = create_template_for(other_docente, "Template Externo")
	end

Given('que existem templates cadastrados apenas por outros administradores') do
	ensure_admin_present
	Template.where(docente: @admin_docente).delete_all
	@other_template = create_template_for(other_docente, "Template Restrito")
end

Given('que não existem templates cadastrados para o administrador atual') do
	ensure_admin_present
	Template.where(docente: @admin_docente).delete_all
end

When('eu visualizo a listagem de templates') do
	ensure_admin_present
	visit management_templates_path(admin_id: @admin_docente.id)
end

When('eu tento visualizar a listagem de templates de um administrador inexistente') do
	ensure_admin_present
	invalid_admin_id = (Docente.maximum(:id) || 0) + 10
	visit management_templates_path(admin_id: invalid_admin_id)
end

Then('não devo ver templates criados por outros administradores') do
	expect(page).not_to have_text(@other_template&.name || "Template Externo")
end

Then('a listagem de templates fica vazia') do
	expect(page).to have_no_selector("[data-testid='template-card']")
end

def ensure_admin_present
	step 'que estou autenticado como administrador' unless @admin_docente
end

def create_template_for(docente, nome)
	Template.create!(
		name: nome,
		description: "Template gerado para testes",
		docente: docente,
		status: Template::STATUS[:draft],
		template_questions_attributes: [
			{
				prompt: "Como você avalia este template?",
				question_type: TemplateQuestion::QUESTION_TYPES[:likert],
				position: 1,
				min_value: 1,
				max_value: 5,
				required: true
			}
		]
	)
end

def other_docente
	return @other_docente if defined?(@other_docente) && @other_docente.present?

	@other_docente = Docente.create!(
		nome: "Outro Admin",
		email: "outro-admin-#{SecureRandom.hex(4)}@example.com",
		identifier: SecureRandom.uuid,
		departamento: "Outro",
		titulacao: "Mestre",
		password: "senha123",
		admin: true
	)
end

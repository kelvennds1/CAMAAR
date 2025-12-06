# frozen_string_literal: true

require "securerandom"

Given('que existe o template {string} associado a {int} formulários já criados') do |nome, total|
	ensure_admin_present
	@template_under_edit = Template.find_by(name: nome, docente: @admin_docente)
	@template_under_edit ||= create_template_for(@admin_docente, nome)
	create_forms_for_template(@template_under_edit, total)
	visit management_templates_path(admin_id: @admin_docente.id)
end

When('eu acesso a edição do template {string}') do |nome|
	within_template_card(nome) do
		find("[data-testid='edit-template']").click
	end
end

When('altero o nome do template para {string}') do |novo_nome|
	step %(preencho o nome do template com "#{novo_nome}")
end

When('salvo as alterações do template') do
	click_button "Salvar template"
end

When('eu excluo o template {string}') do |nome|
	@template_pending_delete = nome
end

When('confirmo a exclusão do template') do
	raise "Nenhum template selecionado para exclusão" unless @template_pending_delete

	within_template_card(@template_pending_delete) do
		find("[data-testid='delete-template']").click
	end
	@template_pending_delete = nil
end

Then('o template {string} não aparece mais na listagem de templates') do |nome|
	expect(page).to have_no_selector("[data-testid='template-card'] h3", text: nome)
end

def create_forms_for_template(template, total)
	total.to_i.times do |index|
		turma = create_supporting_turma(template.docente, index)
		Avaliacao.create!(
			title: "#{template.name} - Formulário #{index + 1}",
			description: "Formulário vinculado ao template",
			docente: template.docente,
			turma: turma,
			template: template,
			due_date: 3.weeks.from_now,
			max_score: 10,
			status: :draft
		)
	end
end

def create_supporting_turma(docente, sequence)
	materia = Materia.create!(
		code: "MAT-#{SecureRandom.hex(2)}-#{sequence}",
		name: "Matéria #{sequence}"
	)
	Turma.create!(
		materia: materia,
		docente: docente,
		class_code: "TURMA-#{SecureRandom.hex(2)}-#{sequence}",
		semester: "2025.1"
	)
end

def within_template_card(nome, &block)
	card = find("[data-testid='template-card']", text: nome)
	within(card, &block)
end

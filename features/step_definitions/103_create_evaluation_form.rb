# frozen_string_literal: true

require "securerandom"

Given('I am authenticated as an administrator') do
  @admin ||= Usuario.create!(
    identifier: SecureRandom.uuid,
    nome: "Administrador Sprint",
    email: "admin-#{SecureRandom.hex(4)}@example.com",
    type: "Usuario",
    password: "senha123",
    admin: true
  )
end

Given('there is at least one evaluation template available') do
  ensure_docente!
  @template ||= Template.create!(
    name: "Template #{SecureRandom.hex(2)}",
    description: "Avaliação institucional",
    status: Template::STATUS[:draft],
    docente: @docente,
    template_questions_attributes: [
      {
        prompt: "Como você avalia o curso?",
        question_type: TemplateQuestion::QUESTION_TYPES[:likert],
        min_value: 1,
        max_value: 5,
        position: 1
      }
    ]
  )
end

Given('there are classes available for the current semester') do
  step 'there is at least one evaluation template available' unless @template.present?
  @materia ||= Materia.create!(code: "MAT-#{SecureRandom.hex(2)}", name: "Matemática Aplicada")
  @turmas = Array.new(2) do |index|
    Turma.create!(
      class_code: "T#{index + 1}#{SecureRandom.hex(1)}",
      semester: current_semester_label,
      materia: @materia,
      docente: @docente,
      time_slot: "Seg 10h"
    )
  end
end

When('I select a template and choose one or more classes') do
  visit avaliacoes_path
  select(@template.name, from: "Template")
  @selected_turmas = @turmas.first(2)
  @selected_turmas.each do |turma|
    find("input[type='checkbox'][value='#{turma.id}']", visible: :all).set(true)
  end
end

When('I confirm the creation of forms') do
  find("[data-testid='create-evaluations']").click
end

Then('the system creates one evaluation form per selected class for the current semester') do
  expected_ids = @selected_turmas.map(&:id)
  count = Avaliacao.where(template: @template, turma_id: expected_ids).count
  expect(count).to eq(@selected_turmas.size)
end

Then('I see a success message indicating how many forms were created') do
  expect(page).to have_content('formulário(s) criado(s)')
end

Given('there is already an evaluation form for a class in the current semester') do
  step 'there are classes available for the current semester' unless @turmas.present?
  turma = @turmas.first
  Avaliacao.create!(
    template: @template,
    turma:,
    docente: turma.docente,
    title: "#{@template.name} - #{turma.class_code}/#{turma.semester}",
    due_date: Time.zone.today.end_of_month,
    max_score: 5
  )
  @selected_turmas ||= @turmas
end

When('I try to create forms again using the same template for the same class') do
  visit avaliacoes_path
  select(@template.name, from: "Template")
  find("input[type='checkbox'][value='#{@turmas.first.id}']", visible: :all).set(true)
  find("[data-testid='create-evaluations']").click
end

Then('the system does not create a new form for that class and semester') do
  turma = @turmas.first
  expect(Avaliacao.where(template: @template, turma:).count).to eq(1)
end

Then('I see a message indicating the form already exists') do
  expect(page).to have_content('turma(s) ignoradas')
end

When('I try to create forms without selecting a template') do
  visit avaliacoes_path
  @selected_turmas = @turmas.first(1)
  @selected_turmas.each do |turma|
    find("input[type='checkbox'][value='#{turma.id}']", visible: :all).set(true)
  end
  find("[data-testid='create-evaluations']").click
end

Then('I see a validation error indicating a template is required') do
  expect(page).to have_content('Selecione ao menos um template e uma turma')
end

Then('no forms are created') do
  expect(Avaliacao.where(template: @template).count).to eq(0)
end

def ensure_docente!
  @docente ||= Docente.create!(
    identifier: SecureRandom.uuid,
    nome: "Prof. #{SecureRandom.hex(2)}",
    email: "docente-#{SecureRandom.hex(3)}@example.com",
    departamento: "Engenharia",
    titulacao: "Doutora",
    password: "senha123"
  )
end

def current_semester_label
  date = Time.zone.today
  term = date.month <= 6 ? 1 : 2
  format('%<year>d.%<term>d', year: date.year, term: term)
end
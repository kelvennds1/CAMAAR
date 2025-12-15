# frozen_string_literal: true

require "securerandom"

# ------------------------------------------------------------
# Background / Given
# ------------------------------------------------------------

Given('I am signed in as a participant') do
  next if defined?(@dicente_participante) && @dicente_participante.present?

  generated_identifier = SecureRandom.uuid
  @dicente_participante = Dicente.create!(
    nome: "João Silva",
    email: "joao-#{generated_identifier}@example.com",
    identifier: generated_identifier,
    matricula: "190#{rand(10_000..99_999)}",
    curso: "Engenharia de Software",
    password: "senha123"
  )

  # Simulate login session
  visit login_path
  fill_in "email", with: @dicente_participante.email
  fill_in "password", with: "senha123"
  click_button "Entrar"
end

Given('I am enrolled in one or more classes for the current semester') do
  @current_semester = "#{Time.zone.today.year}.#{Time.zone.today.month <= 6 ? 1 : 2}"

  # Create a docente for the turma
  generated_identifier = SecureRandom.uuid
  @docente = Docente.create!(
    nome: "Prof. Maria Santos",
    email: "maria-#{generated_identifier}@example.com",
    identifier: generated_identifier,
    departamento: "Computação",
    titulacao: "Doutora",
    password: "senha123"
  )

  # Create materia
  @materia = Materia.find_or_create_by!(
    name: "Engenharia de Software",
    code: "CIC0352"
  )

  # Create turma
  @turma = Turma.create!(
    semester: @current_semester,
    class_code: "A",
    docente: @docente,
    materia: @materia,
    time_slot: "TER 14:00-16:00"
  )

  # Enroll dicente in turma
  Matricula.create!(
    dicente: @dicente_participante,
    turma: @turma,
    status: :ativo
  )
end

# ------------------------------------------------------------
# Scenario: List unanswered forms for my classes
# ------------------------------------------------------------

Given('there are evaluation forms assigned to my classes that I have not answered yet') do
  # Create template with questions using nested attributes
  @template = Template.new(
    name: "Avaliação Docente Padrão",
    description: "Template para avaliação de docentes",
    docente: @docente,
    status: :published
  )

  @template.template_questions.build(
    prompt: "Como você avalia o domínio do conteúdo pelo professor?",
    question_type: "likert",
    position: 1,
    required: true,
    min_value: 1,
    max_value: 5
  )

  @template.save!

  # Create published avaliacoes
  @avaliacao1 = Avaliacao.create!(
    title: "Avaliação de Engenharia de Software",
    turma: @turma,
    docente: @docente,
    template: @template,
    due_date: 7.days.from_now,
    max_score: 100,
    status: :published
  )

  # Copy questions from template to avaliacao
  @template.template_questions.each do |tq|
    @avaliacao1.questoes.create!(
      prompt: tq.prompt,
      question_type: tq.question_type,
      position: tq.position,
      mandatory: tq.required,
      min_value: tq.min_value,
      max_value: tq.max_value,
      weight: 1
    )
  end

  @avaliacao2 = Avaliacao.create!(
    title: "Avaliação de Meio de Semestre",
    turma: @turma,
    docente: @docente,
    template: @template,
    due_date: 14.days.from_now,
    max_score: 100,
    status: :published
  )

  # Copy questions from template to avaliacao2
  @template.template_questions.each do |tq|
    @avaliacao2.questoes.create!(
      prompt: tq.prompt,
      question_type: tq.question_type,
      position: tq.position,
      mandatory: tq.required,
      min_value: tq.min_value,
      max_value: tq.max_value,
      weight: 1
    )
  end
end

When('I open the page to view my pending forms') do
  visit formularios_pendentes_path
end

Then('I see a list of the unanswered forms for my classes') do
  expect(page).to have_selector('[data-testid="pending-form"]', count: 2)
end

Then('each item shows the class, semester, and form title') do
  within first('[data-testid="pending-form"]') do
    expect(page).to have_selector('[data-testid="form-title"]')
    expect(page).to have_selector('[data-testid="form-turma"]')
    expect(page).to have_selector('[data-testid="form-semester"]')
  end
end

# ------------------------------------------------------------
# Scenario: Do not show forms I already answered
# ------------------------------------------------------------

Given('I have already answered an evaluation form for one of my classes') do
  # Create template with questions using nested attributes
  @template = Template.new(
    name: "Avaliação Docente Padrão",
    description: "Template para avaliação de docentes",
    docente: @docente,
    status: :published
  )

  @template.template_questions.build(
    prompt: "Como você avalia o domínio do conteúdo pelo professor?",
    question_type: "likert",
    position: 1,
    required: true,
    min_value: 1,
    max_value: 5
  )

  @template.save!

  # Create published avaliacao answered
  @avaliacao_answered = Avaliacao.create!(
    title: "Avaliação Respondida",
    turma: @turma,
    docente: @docente,
    template: @template,
    due_date: 7.days.from_now,
    max_score: 100,
    status: :published
  )

  # Copy questions from template to avaliacao_answered
  @template.template_questions.each do |tq|
    @avaliacao_answered.questoes.create!(
      prompt: tq.prompt,
      question_type: tq.question_type,
      position: tq.position,
      mandatory: tq.required,
      min_value: tq.min_value,
      max_value: tq.max_value,
      weight: 1
    )
  end

  # Create published avaliacao pending
  @avaliacao_pending = Avaliacao.create!(
    title: "Avaliação Pendente",
    turma: @turma,
    docente: @docente,
    template: @template,
    due_date: 14.days.from_now,
    max_score: 100,
    status: :published
  )

  # Copy questions from template to avaliacao_pending
  @template.template_questions.each do |tq|
    @avaliacao_pending.questoes.create!(
      prompt: tq.prompt,
      question_type: tq.question_type,
      position: tq.position,
      mandatory: tq.required,
      min_value: tq.min_value,
      max_value: tq.max_value,
      weight: 1
    )
  end

  # Create resposta for answered avaliacao
  Resposta.create!(
    avaliacao: @avaliacao_answered,
    dicente: @dicente_participante,
    status: :submitted
  )
end

Then('that form is not listed among my pending forms') do
  expect(page).to have_selector('[data-testid="pending-form"]', count: 1)
  expect(page).to have_content("Avaliação Pendente")
  expect(page).not_to have_content("Avaliação Respondida")
end

# ------------------------------------------------------------
# Scenario: Empty state when there are no pending forms
# ------------------------------------------------------------

Given('there are no unanswered forms for my classes') do
  # No action needed - no avaliacoes will be created
end

Then('I see a message indicating there are no pending forms') do
  expect(page).to have_selector('[data-testid="no-pending-forms"]')
  expect(page).to have_content("Nenhum formulário pendente no momento")
end

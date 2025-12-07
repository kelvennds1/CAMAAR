# frozen_string_literal: true

require "securerandom"

Given('que existem resultados de formulários disponíveis') do
  ensure_admin_logged_in
  @avaliacao = build_avaliacao_para_relatorio(responses: 2)
  @expected_question_prompt = @avaliacao.questoes.first.prompt
  @expected_student_name = @avaliacao.respostas.first.dicente.nome
end

Given('que não existem respostas para o formulário') do
  ensure_admin_logged_in
  @avaliacao = build_avaliacao_para_relatorio(responses: 0)
end

When('eu acesso a página de resultados do formulário') do
  ensure_admin_logged_in
  visit resultado_path(@avaliacao)
end

When('aciono o download dos resultados') do
  ensure_admin_logged_in
  find("[data-testid='botao-exportar']").click
  @download_headers = page.response_headers.dup
  @downloaded_content = page.body.dup
end

Then('o arquivo CSV é baixado') do
  expect(@download_headers["Content-Type"]).to include("text/csv")
end

Then('o arquivo baixado se chama {string}') do |filename|
  disposition = @download_headers["Content-Disposition"]
  expect(disposition).to include(%(filename="#{filename}"))
end

Then('o conteúdo do CSV inclui os dados das respostas') do
  expect(@downloaded_content).to include("Questão,Aluno,Resposta,Enviado em")
  expect(@downloaded_content).to include(@expected_question_prompt)
  expect(@downloaded_content).to include(@expected_student_name)
end

Then('nenhum arquivo de resultados é baixado') do
  expect(@download_headers["Content-Type"]).to include("text/html")
end

def build_avaliacao_para_relatorio(responses:)
  docente = Docente.create!(
    nome: "Coordenador Export",
    email: "docente-export-#{SecureRandom.hex(3)}@example.com",
    identifier: SecureRandom.uuid,
    departamento: "Computação",
    titulacao: "Mestre",
    password: "senha123",
    admin: true
  )

  template = Template.create!(
    name: "Template Export",
    description: "Template para exportação",
    docente: docente,
    status: Template::STATUS[:draft],
    template_questions_attributes: [
      {
        prompt: "Como você avalia o professor?",
        question_type: TemplateQuestion::QUESTION_TYPES[:likert],
        position: 1,
        min_value: 1,
        max_value: 5,
        required: true
      }
    ]
  )

  materia = Materia.create!(code: "MAT-#{SecureRandom.hex(2)}", name: "Metodologias Ativas")
  turma = Turma.create!(materia: materia, docente: docente, class_code: "TURMA-#{SecureRandom.hex(2)}", semester: "2025.1")

  avaliacao = Avaliacao.create!(
    title: "Avaliação Desempenho 2025.1",
    description: "Formulário para medir desempenho",
    docente: docente,
    turma: turma,
    template: template,
    due_date: 2.weeks.from_now,
    max_score: 10,
    status: :published
  )

  template_question = template.template_questions.first

  questao = avaliacao.questoes.create!(
    prompt: template_question.prompt,
    question_type: template_question.question_type,
    position: 1,
    weight: 1,
    mandatory: true,
    min_value: 1,
    max_value: 5,
    template_question: template_question
  )

  responses.times do |index|
    dicente = Dicente.create!(
      nome: "Aluno Export #{index + 1}",
      email: "aluno-export-#{SecureRandom.hex(3)}@example.com",
      identifier: SecureRandom.uuid,
      matricula: "2025#{SecureRandom.hex(2)}#{index}",
      curso: "Engenharia",
      password: "senha123"
    )

    Matricula.create!(dicente: dicente, turma: turma, enrollment_date: Date.current)

    resposta = Resposta.create!(
      avaliacao: avaliacao,
      dicente: dicente,
      status: :submitted,
      submitted_at: Time.current,
      score: 8.5,
      feedback: "Ótimo desempenho"
    )

    RespostaItem.create!(
      resposta: resposta,
      questao: questao,
      valor: (index + 4).to_s
    )
  end

  if responses.zero?
    dicente = Dicente.create!(
      nome: "Aluno Export 1",
      email: "aluno-export-sem-resposta-#{SecureRandom.hex(3)}@example.com",
      identifier: SecureRandom.uuid,
      matricula: "2025#{SecureRandom.hex(2)}NR",
      curso: "Engenharia",
      password: "senha123"
    )
    Matricula.create!(dicente: dicente, turma: turma, enrollment_date: Date.current)
  end

  avaliacao
end

def ensure_admin_logged_in
  unless defined?(@admin_logged_in) && @admin_logged_in
    step 'que estou autenticado como administrador'
    @admin_logged_in = true
  end
end

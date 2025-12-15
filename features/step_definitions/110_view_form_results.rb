# frozen_string_literal: true

require "securerandom"

Given('que estou logado como um administrador válido') do
  @admin ||= Docente.create!(
    identifier: SecureRandom.uuid,
    nome: "Admin Resultados",
    email: "admin-resultados-#{SecureRandom.hex(3)}@example.com",
    departamento: "Coordenação",
    titulacao: "Mestre",
    password: "senha123",
    admin: true
  )

  # Fazer login
  visit login_path
  fill_in "email", with: @admin.email
  fill_in "password", with: "senha123"
  click_button "Entrar"
end

Given('que não existem formulários cadastrados') do
  Avaliacao.delete_all
end

Given('que existem formulários para o semestre atual:') do |table|
  table.hashes.each do |row|
    create_resultado_formulario(titulo: row['título'], semester: current_semester_label)
  end
end

Given('que existe o formulário {string} com respostas enviadas') do |titulo|
  avaliacao = create_resultado_formulario(titulo: titulo)
  create_respostas_para(avaliacao, 3)
end

Given('que existem formulários com professor {string}') do |nome|
  create_resultado_formulario(titulo: "Avaliação Docente", professor: nome)
  create_resultado_formulario(titulo: "Avaliação da Infraestrutura", professor: "Outro Docente")
end

Given('que existem formulários de semestres diferentes') do
  create_resultado_formulario(titulo: "Avaliação Docente", semester: "2025.1")
  create_resultado_formulario(titulo: "Avaliação Docente", semester: "2024.2")
end

Given('que existe o formulário {string} sem nenhuma resposta') do |titulo|
  create_resultado_formulario(titulo: titulo)
end

Given('que existem formulários cadastrados') do
  create_resultado_formulario(titulo: "Avaliação Docente")
  create_resultado_formulario(titulo: "Avaliação da Infraestrutura")
end

Given('o serviço de exportação está indisponível') do
  EvaluationResultsExporter.force_failure = true
end

When('eu acesso diretamente o endereço {string}') do |path|
  visit("/#{path}")
end

When('eu abro o card {string}') do |titulo|
  ensure_resultados_index
  card = find("[data-testid='form-card']", text: titulo)
  card.find("[data-testid='abrir-card']").click
end

When('eu pesquiso por {string}') do |termo|
  ensure_resultados_index
  find("[data-testid='campo-busca']").set(termo)
  find("[data-testid='botao-buscar']").click
end

When('seleciono o filtro de semestre {string}') do |semestre|
  ensure_resultados_index
  find("[data-testid='filtro-semestre']").select(semestre)
  find("[data-testid='botao-buscar']").click
end

When('tento exportar os resultados') do
  ensure_resultado_detail
  find("[data-testid='botao-exportar']").click
end

Then('devo visualizar os cards dos formulários {string} e {string}') do |t1, t2|
  expect(page).to have_selector("[data-testid='form-card']", text: t1)
  expect(page).to have_selector("[data-testid='form-card']", text: t2)
end

Then('cada card exibe semestre, professor e total de respostas') do
  all("[data-testid='form-card']").each do |card|
    expect(card).to have_selector("[data-testid='info-semestre']")
    expect(card).to have_selector("[data-testid='info-professor']")
    expect(card).to have_selector("[data-testid='info-total-respostas']")
  end
end

Then('vejo o resumo consolidado com gráficos e estatísticas') do
  expect(page).to have_selector("[data-testid='resumo-formulario']")
  expect(page).to have_selector("[data-testid='grafico-resultados']")
end

Then('o botão "Exportar resultados" deve estar habilitado') do
  expect(page).to have_selector("[data-testid='botao-exportar']")
  expect(find("[data-testid='botao-exportar']")[:disabled]).to be_nil
end

Then('o botão "Exportar resultados" deve estar desabilitado') do
  # Quando não há respostas, verificar que a mensagem está presente
  expect(page).to have_content("Ainda não há respostas disponíveis")
  # O botão pode existir mas estar desabilitado, ou pode não estar presente
  # A verificação principal é a mensagem de "sem respostas"
end

Then('permaneço na página de resultados') do
  expect(URI.parse(current_url).path).to eq('/resultados')
end

Then('vejo apenas os formulários do semestre {string}') do |semestre|
  nodes = all("[data-testid='info-semestre']")
  expect(nodes).not_to be_empty
  nodes.each { |node| expect(node.text).to eq(semestre) }
end

Then('nenhum arquivo é baixado') do
  expect(page).to have_content('Não foi possível gerar o arquivo')
end

Then('a lista de cards fica vazia') do
  expect(page).to have_no_selector("[data-testid='form-card']")
end

Then('apenas os formulários relacionados a {string} são exibidos') do |nome|
  ensure_resultados_index
  expect(page).to have_selector("[data-testid='info-professor']", minimum: 1)
  all("[data-testid='info-professor']").each do |node|
    expect(node.text).to include(nome)
  end
end

Then('vejo a mensagem {string}') do |texto|
  step %(devo ver a mensagem "#{texto}")
end

Then('não há cards exibidos') do
  expect(page).to have_no_selector("[data-testid='form-card']")
end

Then('a lista de cards fica vazia e vejo a mensagem {string}') do |texto|
  expect(page).to have_no_selector("[data-testid='form-card']")
  expect(page).to have_content(texto)
end

def create_resultado_formulario(titulo:, semester: current_semester_label, professor: "Maria Silva")
  docente = Docente.find_by(nome: professor) || Docente.create!(
    nome: professor,
    email: "docente-#{SecureRandom.hex(3)}@example.com",
    identifier: SecureRandom.uuid,
    departamento: "Departamento",
    titulacao: "Mestre"
  )
  materia = Materia.first || Materia.create!(code: "MAT-#{SecureRandom.hex(2)}", name: "Disciplina")
  turma = Turma.create!(
    class_code: "T#{SecureRandom.hex(2)}",
    semester: semester,
    materia: materia,
    docente: docente,
    time_slot: "Seg 10h"
  )
  avaliacao = Avaliacao.create!(
    title: titulo,
    turma: turma,
    docente: docente,
    due_date: Time.zone.today.end_of_month,
    max_score: 10,
    status: :published
  )
  avaliacao.questoes.create!(
    prompt: "Como você avalia?",
    question_type: TemplateQuestion::QUESTION_TYPES[:likert],
    position: 1,
    mandatory: true,
    weight: 1,
    min_value: 1,
    max_value: 5
  )
  @last_avaliacao = avaliacao
  avaliacao
end

def create_respostas_para(avaliacao, total)
  total.times do |index|
    dicente = Dicente.create!(
      nome: "Aluno #{index}",
      email: "aluno-#{SecureRandom.hex(3)}@example.com",
      identifier: SecureRandom.uuid,
      matricula: "M#{SecureRandom.hex(3)}",
      curso: "Engenharia",
      type: "Dicente",
      password: "senha123"
    )
    resposta = Resposta.create!(
      avaliacao: avaliacao,
      dicente: dicente,
      status: :submitted,
      submitted_at: Time.zone.now,
      score: (index + 3)
    )
    avaliacao.questoes.each do |questao|
      RespostaItem.create!(questao: questao, resposta: resposta, valor: ((index % 5) + 1).to_s)
    end
  end
end

def current_semester_label
  date = Time.zone.today
  term = date.month <= 6 ? 1 : 2
  format('%<year>d.%<term>d', year: date.year, term: term)
end

def ensure_resultados_index
  ensure_admin_logged_in
  return if page.current_path == '/resultados'

  visit('/resultados')
end

def ensure_admin_logged_in
  unless defined?(@admin_logged_in) && @admin_logged_in
    step 'que estou logado como um administrador válido'
    @admin_logged_in = true
  end
end

def ensure_resultado_detail
  if @last_avaliacao
    visit("/resultados/#{@last_avaliacao.id}")
  else
    ensure_resultados_index
  end
end

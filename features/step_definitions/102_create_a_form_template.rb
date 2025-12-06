require "securerandom"

QUESTION_TYPE_LABELS = {
  "Escala 1-5" => TemplateQuestion::QUESTION_TYPES[:likert],
  "Múltipla escolha" => TemplateQuestion::QUESTION_TYPES[:multiple_choice],
  "Texto" => TemplateQuestion::QUESTION_TYPES[:text]
}.freeze

Before do
  @template_count_before_submit = Template.count
end

Dado('que existe um docente chamado {string}') do |nome|
  email = "#{nome.parameterize}@example.com"
  @docente = Docente.find_or_create_by!(nome:) do |doc|
    doc.identifier = SecureRandom.uuid
    doc.email = email
    doc.departamento = "Departamento"
    doc.titulacao = "Mestre"
    doc.password = "12345678"
  end
end

Dado('acesso a página de templates') do
  visit templates_path
end

Quando('preencho o nome do template com {string}') do |nome|
  fill_in("Nome", with: nome)
end

Quando('seleciono o docente {string}') do |nome|
  select(nome, from: "Responsável")
end

Quando('adiciono a questão {int} do tipo {string} com o texto {string}') do |ordem, tipo, texto|
  ensure_question_blocks(ordem)
  bloco = question_block(ordem)
  bloco.find("[data-testid='question-prompt']").set(texto)
  selecionar_tipo(bloco, tipo)
end

Quando('adiciono a questão {int} do tipo {string} com o texto {string} e as opções:') do |ordem, tipo, texto, table|
  step %(adiciono a questão #{ordem} do tipo "#{tipo}" com o texto "#{texto}")
  bloco = question_block(ordem)
  bloco.find("[data-testid='question-options']").set(table.raw.flatten.join("\n"))
end

Quando('adiciono a questão {int} do tipo {string} com o texto {string} e nenhuma opção') do |ordem, tipo, texto|
  step %(adiciono a questão #{ordem} do tipo "#{tipo}" com o texto "#{texto}")
end

Quando('adiciono a questão {int} do tipo {string} com o texto {string} e escala inválida') do |ordem, tipo, texto|
  step %(adiciono a questão #{ordem} do tipo "#{tipo}" com o texto "#{texto}")
  bloco = question_block(ordem)
  bloco.find("[data-testid='question-min']").set(0)
  bloco.find("[data-testid='question-max']").set(6)
end

Quando('removo todas as questões') do
  question_blocks.each do |block|
    checkbox = block.find("[data-testid='question-remove-checkbox']", visible: :all)
    checkbox.set(true)
  end
end

Quando('clico em {string}') do |rotulo|
  case rotulo
  when 'Criar template'
    @template_count_before_submit = Template.count
    find("[data-testid='submit-template']").click
  else
    click_button(rotulo)
  end
end

Dado('que já existe um template chamado {string} para o docente {string}') do |nome, docente_nome|
  docente = Docente.find_by(nome: docente_nome)
  unless docente
    step %(que existe um docente chamado "#{docente_nome}")
    docente = Docente.find_by!(nome: docente_nome)
  end
  Template.create!(name: nome, description: "Existente", docente:, status: Template::STATUS[:draft], template_questions_attributes: [
    { prompt: "Questão", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1 }
  ])
end

Então('devo ver o card do template {string} na listagem') do |nome|
  expect(page).to have_selector("[data-testid='template-card'] h3", text: nome)
end

Então('ao visualizar o template {string} devo ver as perguntas na ordem:') do |nome, table|
  card = find("[data-testid='template-card']", text: nome)
  within(card) do
    find('summary').click
    perguntas = all("[data-testid='template-questions-order'] li .question-prompt").map(&:text)
    expect(perguntas).to eq(table.raw.flatten)
  end
end

Então('o template {string} não é criado') do |_nome|
  expect(Template.count).to eq(@template_count_before_submit)
  expect(page).to have_content("Corrija os erros")
end

def ensure_question_blocks(count)
  attempts = 0
  while question_blocks.count < count && attempts < 5
    find("[data-testid='add-question']").click
    attempts += 1
  end
  raise "Não foi possível adicionar novas questões" if question_blocks.count < count
end

def question_blocks
  all("[data-testid='question-block']", visible: :all).reject { |node| node["data-removed"] == "true" }
end

def question_block(position)
  blocks = question_blocks
  raise "Bloco de questão #{position} não encontrado" if blocks.size < position
  blocks[position - 1]
end

def selecionar_tipo(bloco, tipo)
  value = QUESTION_TYPE_LABELS.fetch(tipo)
  select_box = bloco.find("[data-testid='question-type']")
  select_box.find("option[value='#{value}']").select_option
end

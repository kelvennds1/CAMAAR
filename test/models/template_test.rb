require "test_helper"

class TemplateTest < ActiveSupport::TestCase
  test "valid template with nested questions" do
    docente = create_docente(nome: "Prof. Valido")
    template = Template.new(name: "Avaliação", docente:)
    template.template_questions.build(prompt: "Organização", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1)

    assert_predicate template, :valid?
  end

  test "requires at least one question" do
    docente = create_docente(nome: "Prof. Sem Questao")
    template = Template.new(name: "Sem perguntas", docente:)

    assert_not template.valid?
    assert_includes template.errors[:base], "Adicione pelo menos uma questão"
  end

  test "requires name" do
    docente = create_docente(nome: "Prof. Nome")
    template = Template.new(docente:)
    template.template_questions.build(prompt: "Infra", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1)

    assert_not template.valid?
    assert_includes template.errors[:name], "Informe o nome do template"
  end

  test "enforces uniqueness per docente" do
    docente = create_docente(nome: "Prof. Unico")
    Template.create!(name: "Base", docente:, template_questions_attributes: [
      { prompt: "Questao", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1 }
    ])

    duplicated = Template.new(name: "Base", docente:)
    duplicated.template_questions.build(prompt: "Outra", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1)

    assert_not duplicated.valid?
    assert_includes duplicated.errors[:name], "Já existe um template com esse nome para o docente selecionado"
  end
end

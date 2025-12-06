require "test_helper"

class TemplateQuestionTest < ActiveSupport::TestCase
  setup do
    @docente = create_docente(nome: "Prof. Perguntas")
    @template = Template.create!(name: "Base perguntas", docente: @docente, template_questions_attributes: [
      { prompt: "Texto", question_type: TemplateQuestion::QUESTION_TYPES[:text], position: 1 }
    ])
  end

  test "requires at least two options for multiple choice" do
    question = TemplateQuestion.new(
      prompt: "Opções",
      question_type: TemplateQuestion::QUESTION_TYPES[:multiple_choice],
      position: 2,
      template: @template,
      options_text: "Somente uma"
    )

    assert_not question.valid?
    assert_includes question.errors[:options], "Adicione pelo menos duas opções"
  end

  test "stores options from textarea input" do
    question = TemplateQuestion.new(
      prompt: "Infra",
      question_type: TemplateQuestion::QUESTION_TYPES[:multiple_choice],
      position: 2,
      template: @template,
      options_text: "Bom\nRuim\nBom"
    )

    assert question.valid?
    assert_equal %w[Bom Ruim], question.options_array
  end

  test "likert questions enforce 1..5 bounds" do
    question = TemplateQuestion.new(
      prompt: "Satisfação",
      question_type: TemplateQuestion::QUESTION_TYPES[:likert],
      position: 2,
      template: @template,
      min_value: 0,
      max_value: 6
    )

    assert_not question.valid?
    assert_includes question.errors[:base], "A escala numérica deve ser de 1 a 5"
  end
end

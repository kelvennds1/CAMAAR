require "test_helper"

class TemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @docente = create_docente(nome: "Prof. Controller")
  end

  test "should get index" do
    get templates_url
    assert_response :success
    assert_select "h1", text: /Templates de formulário/
  end

  test "creates template with nested questions" do
    assert_difference("Template.count", 1) do
      post templates_url, params: {
        template: {
          name: "Controller Template",
          description: "Fluxo feliz",
          docente_id: @docente.id,
          template_questions_attributes: {
            "0" => {
              prompt: "Organização",
              question_type: TemplateQuestion::QUESTION_TYPES[:text],
              position: 1,
              required: 1
            }
          }
        }
      }
    end

    follow_redirect!
    assert_response :success
    assert_match "Template criado com sucesso", response.body
  end

  test "renders errors when data is invalid" do
    assert_no_difference("Template.count") do
      post templates_url, params: {
        template: {
          name: "",
          docente_id: @docente.id,
          template_questions_attributes: {}
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Corrija os erros", response.body
  end
end

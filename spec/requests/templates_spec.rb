require "rails_helper"

RSpec.describe "Templates", type: :request do
  let(:docente) { create(:docente) }
  let(:current_user) { docente }

  before do
    stub_authentication(current_user)
  end

  describe "GET /templates" do
    it "renders the index successfully" do
      create(:template, name: "Template Principal", docente:)

      get templates_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Template Principal")
    end

    it "filters templates by the provided admin_id" do
      scoped_template = create(:template, name: "Template Filtrado", docente:)
      other_template = create(:template, name: "Template Oculto")

      get management_templates_path(admin_id: docente.id)

      expect(response.body).to include(scoped_template.name)
      expect(response.body).not_to include(other_template.name)
    end
  end

  describe "POST /templates" do
    let(:valid_params) do
      {
        template: {
          name: "Template Novo",
          description: "Descrição",
          docente_id: docente.id,
          template_questions_attributes: {
            "0" => {
              prompt: "Como você avalia o conteúdo?",
              question_type: TemplateQuestion::QUESTION_TYPES[:likert],
              position: 1,
              required: true,
              min_value: 1,
              max_value: 5
            }
          }
        }
      }
    end

    it "creates a template and redirects to the scoped list" do
      expect do
        post templates_path, params: valid_params
      end.to change(Template, :count).by(1)

      expect(response).to redirect_to(management_templates_path(admin_id: docente.id))
      follow_redirect!
      expect(response.body).to include("Template criado com sucesso")
    end

    it "renders errors when the payload is invalid" do
      invalid_params = valid_params.deep_dup
      invalid_params[:template][:name] = ""

      expect do
        post templates_path, params: invalid_params
      end.not_to change(Template, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Não foi possível salvar o template")
    end
  end

  describe "PATCH /templates/:id" do
    it "updates the template and keeps the admin scope" do
      template = create(:template, docente:)
      payload = {
        template: {
          name: "Template Atualizado",
          template_questions_attributes: template.template_questions.each_with_index.to_h do |question, index|
            [ index.to_s, { id: question.id, prompt: question.prompt, question_type: question.question_type, position: question.position, required: question.required, min_value: question.min_value, max_value: question.max_value } ]
          end
        }
      }

      patch template_path(template, admin_id: docente.id), params: payload

      expect(response).to redirect_to(management_templates_path(admin_id: docente.id))
      follow_redirect!
      expect(response.body).to include("Template atualizado com sucesso")
      expect(template.reload.name).to eq("Template Atualizado")
    end
  end

  describe "DELETE /templates/:id" do
    it "removes the template and redirects back to the admin scope" do
      template = create(:template, docente:)

      expect do
        delete template_path(template, admin_id: docente.id)
      end.to change(Template, :count).by(-1)

      expect(response).to redirect_to(management_templates_path(admin_id: docente.id))
      follow_redirect!
      expect(response.body).to include("Template removido com sucesso")
    end
  end
end

require "rails_helper"
require "cgi"

RSpec.describe "Avaliações", type: :request do
  let(:current_user) { create(:docente) }

  before do
    stub_authentication(current_user)
  end
  describe "GET /avaliacoes" do
    it "renders the listing successfully" do
      avaliacao = create(:avaliacao)

      get avaliacoes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(avaliacao.title)
    end
  end

  describe "POST /avaliacoes" do
    let(:template) { create(:template) }
    let(:turmas) { create_list(:turma, 2) }
    let(:due_date) { 1.week.from_now.to_date }

    it "creates evaluation batches and redirects to the index" do
      payload = {
        avaliacao_batch: {
          template_id: template.id,
          due_date: due_date,
          turma_ids: turmas.map(&:id)
        }
      }

      expect do
        post avaliacoes_path, params: payload
      end.to change(Avaliacao, :count).by(2)

      expect(response).to redirect_to(avaliacoes_path)
      follow_redirect!
      expect(response.body).to include("formulário(s) criado(s)")
    end

    it "renders errors when template or turmas are missing" do
      expect do
        post avaliacoes_path, params: { avaliacao_batch: { template_id: nil, turma_ids: [] } }
      end.not_to change(Avaliacao, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Selecione ao menos um template e uma turma")
    end
  end

  describe "GET /formularios/pendentes" do
    context "when the current user is a dicente" do
      let(:current_user) { create(:dicente) }
      let(:turma) { create(:turma) }
      let!(:matricula) { create(:matricula, dicente: current_user, turma:) }
      let!(:avaliacao) { create(:avaliacao, turma:, status: :published, title: "Avaliação da Turma") }

      it "lists the pending evaluations for the enrolled classes" do
        get formularios_pendentes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(avaliacao.title)
      end
    end

    context "when the current user is not a dicente" do
      it "shows the empty message" do
        create(:avaliacao, title: "Avaliação Restrita")

        get formularios_pendentes_path

        expect(response.body).to include("Nenhum formulário pendente no momento.")
        expect(response.body).not_to include("Avaliação Restrita")
      end
    end
  end

  describe "GET /avaliacoes/:id/responder" do
    let(:turma) { create(:turma) }
    let!(:avaliacao) { create(:avaliacao, turma:, status: :published) }
    let!(:questao) { create(:questao, avaliacao:, prompt: "Qualidade do curso") }

    context "when the dicente belongs to the turma" do
      let(:current_user) { create(:dicente) }
      let!(:matricula) { create(:matricula, dicente: current_user, turma:) }

      it "renders the answer form" do
        get responder_avaliacao_path(avaliacao)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Qualidade do curso")
      end
    end

    context "when the user cannot answer the form" do
      it "redirects with an alert" do
        get responder_avaliacao_path(avaliacao)

        expect(response).to redirect_to(formularios_pendentes_path)
        expect(flash[:alert]).to eq("Você não tem permissão para responder este formulário")
      end
    end
  end

  describe "POST /avaliacoes/:id/submeter" do
    let(:turma) { create(:turma) }
    let!(:avaliacao) { create(:avaliacao, turma:, status: :published) }
    let!(:questao) { create(:questao, avaliacao:, prompt: "Qualidade do curso") }

    context "when the payload is valid" do
      let(:current_user) { create(:dicente) }
      let!(:matricula) { create(:matricula, dicente: current_user, turma:) }

      it "persists the resposta and redirects back to the pending list" do
        expect do
          post submeter_avaliacao_path(avaliacao), params: { respostas: { questao.id => "4" } }
        end.to change(Resposta, :count).by(1)
          .and change(RespostaItem, :count).by(1)

        expect(response).to redirect_to(formularios_pendentes_path)
        follow_redirect!
        expect(response.body).to include("Avaliação enviada com sucesso")
      end
    end

    context "when required answers are missing" do
      let(:current_user) { create(:dicente) }
      let!(:matricula) { create(:matricula, dicente: current_user, turma:) }

      it "re-renders the form with validation errors" do
        expect do
          post submeter_avaliacao_path(avaliacao), params: { respostas: { questao.id => "" } }
        end.not_to change(Resposta, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(CGI.escapeHTML("A pergunta 'Qualidade do curso' é obrigatória"))
      end
    end
  end
end

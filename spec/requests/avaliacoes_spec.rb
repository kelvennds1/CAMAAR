require "rails_helper"

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
end

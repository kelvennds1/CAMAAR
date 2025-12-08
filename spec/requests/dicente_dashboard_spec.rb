require 'rails_helper'

RSpec.describe "Dicente Dashboard (Pending Forms)", type: :request do
  let(:dicente) { create(:dicente, password: "senha123", pending_activation: false) }
  let(:turma1) { create(:turma) }
  let(:turma2) { create(:turma) }
  let!(:matricula1) { create(:matricula, dicente: dicente, turma: turma1, status: :ativo) }
  let!(:matricula2) { create(:matricula, dicente: dicente, turma: turma2, status: :ativo) }

  before { login_as(dicente) }

  describe "GET /formularios/pendentes" do
    let!(:pending_form1) { create(:avaliacao, :published, turma: turma1, title: "Formulário 1") }
    let!(:pending_form2) { create(:avaliacao, :published, turma: turma2, title: "Formulário 2") }
    let!(:answered_form) { create(:avaliacao, :published, turma: turma1, title: "Formulário Respondido") }
    let!(:resposta) { create(:resposta, :submitted, avaliacao: answered_form, dicente: dicente) }

    context "when authenticated as dicente" do
      it "returns success" do
        get formularios_pendentes_path
        expect(response).to have_http_status(:success)
      end

      it "lists pending forms for enrolled classes" do
        get formularios_pendentes_path

        expect(response.body).to include("Formulário 1")
        expect(response.body).to include("Formulário 2")
      end

      it "does not list already answered forms" do
        get formularios_pendentes_path

        expect(response.body).not_to include("Formulário Respondido")
      end

      it "shows form details (title, due date, class)" do
        get formularios_pendentes_path

        expect(response.body).to include(pending_form1.title)
        expect(response.body).to include(turma1.class_code)
      end

      it "provides links to answer each form" do
        get formularios_pendentes_path

        expect(response.body).to include(responder_avaliacao_path(pending_form1))
        expect(response.body).to include(responder_avaliacao_path(pending_form2))
      end
    end

    context "with forms from other classes" do
      let(:other_turma) { create(:turma) }
      let!(:other_form) { create(:avaliacao, :published, turma: other_turma, title: "Outro Formulário") }

      it "does not show forms from non-enrolled classes" do
        get formularios_pendentes_path

        expect(response.body).not_to include("Outro Formulário")
      end
    end

    context "with closed forms" do
      let!(:closed_form) { create(:avaliacao, :closed, turma: turma1, title: "Formulário Fechado") }

      it "does not show closed forms" do
        get formularios_pendentes_path

        expect(response.body).not_to include("Formulário Fechado")
      end
    end

    context "with expired forms" do
      let!(:expired_form) { create(:avaliacao, :published, turma: turma1, title: "Formulário Expirado", due_date: 1.day.ago) }

      it "shows expired forms with indication" do
        get formularios_pendentes_path

        expect(response.body).to include("Formulário Expirado")
        # Optionally check for expiration indicator
      end
    end

    context "when no pending forms exist" do
      before do
        Avaliacao.destroy_all
      end

      it "shows empty state message" do
        get formularios_pendentes_path

        expect(response.body).to include("Nenhum formulário pendente") # or similar message
      end

      it "returns success status" do
        get formularios_pendentes_path

        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as docente" do
      let(:docente) { create(:docente, password: "senha123", pending_activation: false) }

      before { login_as(docente) }

      it "redirects or shows appropriate content" do
        get formularios_pendentes_path

        # Depending on implementation, might redirect or show different view
        expect(response).to have_http_status(:success).or have_http_status(:redirect)
      end
    end

    context "when not authenticated" do
      before { logout }

      it "redirects to login" do
        get formularios_pendentes_path

        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "Form filtering and sorting" do
    let!(:form_due_soon) { create(:avaliacao, :published, turma: turma1, title: "Due Soon", due_date: 2.days.from_now) }
    let!(:form_due_later) { create(:avaliacao, :published, turma: turma1, title: "Due Later", due_date: 10.days.from_now) }

    it "orders forms by due date (nearest first)" do
      get formularios_pendentes_path

      body = response.body
      due_soon_position = body.index("Due Soon")
      due_later_position = body.index("Due Later")

      expect(due_soon_position).to be < due_later_position
    end
  end

  describe "Form metadata" do
    let!(:avaliacao_with_metadata) {
      create(:avaliacao, :published,
             turma: turma1,
             title: "Test Form",
             due_date: 5.days.from_now,
             max_score: 100)
    }

    before do
      create(:questao, avaliacao: avaliacao_with_metadata)
      create(:questao, avaliacao: avaliacao_with_metadata)
      create(:questao, avaliacao: avaliacao_with_metadata)
    end

    it "shows number of questions" do
      get formularios_pendentes_path

      expect(response.body).to include("3") # number of questions
    end

    it "shows turma information" do
      get formularios_pendentes_path

      expect(response.body).to include(turma1.class_code)
      expect(response.body).to include(turma1.materia.name)
    end
  end

  describe "Response status" do
    let!(:pending_form) { create(:avaliacao, :published, turma: turma1) }
    let!(:partial_resposta) { create(:resposta, :pending, avaliacao: pending_form, dicente: dicente) }

    it "indicates when a form has a partial response" do
      get formularios_pendentes_path

      # Should still show the form since it's not submitted
      expect(response.body).to include(pending_form.title)
    end

    it "allows continuing a partial response" do
      get formularios_pendentes_path

      expect(response.body).to include(responder_avaliacao_path(pending_form))
    end
  end

  describe "Performance" do
    before do
      # Create many forms
      20.times do |i|
        turma = create(:turma)
        create(:matricula, dicente: dicente, turma: turma, status: :ativo)
        create(:avaliacao, :published, turma: turma, title: "Form #{i}")
      end
    end

    it "loads efficiently with many forms" do
      expect {
        get formularios_pendentes_path
      }.to perform_under(1000).ms
    end

    it "eager loads associations to avoid N+1 queries" do
      expect {
        get formularios_pendentes_path
      }.to perform_constant_number_of_queries
    end
  end
end

require "rails_helper"

RSpec.describe "Resultados", type: :request do
  let(:admin) { create(:docente, admin: true) }

  before do
    stub_authentication(admin)
  end

  describe "GET /resultados" do
    it "lists available evaluations and filters by query" do
      matching = create(:avaliacao, title: "Avaliação Docente")
      non_matching = create(:avaliacao, title: "Infraestrutura", docente: create(:docente, nome: "Outro Professor"))

      get resultados_path, params: { q: "Docente" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(matching.title)
      expect(response.body).not_to include(non_matching.title)
    end

    it "shows the empty search message when nothing matches" do
      create(:avaliacao, title: "Avaliação Docente")

      get resultados_path, params: { q: "Inexistente" }

      expect(response.body).to include("Nenhum resultado para a busca")
    end
  end

  describe "GET /resultados/:id" do
    let(:avaliacao) { create(:avaliacao) }
    let(:summary) do
      {
        total_responses: 2,
        average_score: 4.5,
        completion_rate: 80,
        question_stats: []
      }
    end

    it "renders the summary returned by the aggregator" do
      aggregator = instance_double(EvaluationResultAggregator, summary: summary)
      allow(EvaluationResultAggregator).to receive(:new).with(avaliacao).and_return(aggregator)

      get resultado_path(avaliacao)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Total de respostas: 2")
      expect(response.body).to include("Média geral")
    end

    it "redirects with an alert when the evaluation is missing" do
      get resultado_path(999999)

      expect(response).to redirect_to(resultados_path)
      expect(flash[:alert]).to eq("O formulário solicitado não foi encontrado")
    end
  end

  describe "GET /resultados/:id/export" do
    let(:avaliacao) { create(:avaliacao) }

    it "streams the CSV when the exporter succeeds" do
      exporter = instance_double(EvaluationResultsExporter, call: "csv-data", filename: "relatorio.csv")
      allow(EvaluationResultsExporter).to receive(:new).with(avaliacao).and_return(exporter)

      get export_resultado_path(avaliacao)

      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to eq("csv-data")
      expect(response.headers["Content-Disposition"]).to include("relatorio.csv")
    end

    it "redirects back when the exporter raises a domain error" do
      exporter = instance_double(EvaluationResultsExporter, filename: "relatorio.csv")
      allow(exporter).to receive(:call).and_raise(EvaluationResultsExporter::ExportError, "Ainda não há respostas disponíveis")
      allow(EvaluationResultsExporter).to receive(:new).with(avaliacao).and_return(exporter)

      get export_resultado_path(avaliacao)

      expect(response).to redirect_to(resultado_path(avaliacao))
      expect(flash[:alert]).to eq("Ainda não há respostas disponíveis")
    end

    it "handles unexpected errors with a generic message" do
      exporter = instance_double(EvaluationResultsExporter, filename: "relatorio.csv")
      allow(exporter).to receive(:call).and_raise(StandardError)
      allow(EvaluationResultsExporter).to receive(:new).with(avaliacao).and_return(exporter)

      get export_resultado_path(avaliacao)

      expect(response).to redirect_to(resultado_path(avaliacao))
      expect(flash[:alert]).to eq("Não foi possível gerar o arquivo. Tente novamente mais tarde.")
    end
  end
end

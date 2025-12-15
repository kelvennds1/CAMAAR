require "rails_helper"
require "csv"

RSpec.describe EvaluationResultsExporter do
  let(:avaliacao) { create(:avaliacao, title: "Avaliação de Sistemas") }
  let!(:questao) { create(:questao, avaliacao:, prompt: "Clareza") }
  let(:exporter) { described_class.new(avaliacao) }

  describe "#call" do
    context "when there are respostas" do
      let(:dicente) { create(:dicente, nome: "Aluno QA") }

      before do
        resposta = create(:resposta, avaliacao:, dicente:, submitted_at: Time.zone.parse("2025-12-07 10:00"))
        create(:resposta_item, resposta:, questao:, valor: 5)
      end

      it "returns a CSV with headers and rows" do
        csv_payload = exporter.call
        table = CSV.parse(csv_payload, headers: true)

        expect(table.headers).to eq([ "Questão", "Aluno", "Resposta", "Enviado em" ])
        expect(table.first["Questão"]).to eq("Clareza")
        expect(table.first["Aluno"]).to eq("Aluno QA")
        expect(table.first["Resposta"]).to eq("5")
      end
    end

    it "raises an error when there are no respostas" do
      expect { exporter.call }.to raise_error(EvaluationResultsExporter::ExportError, "Ainda não há respostas disponíveis")
    end

    it "propagates unexpected errors as ExportError" do
      described_class.force_failure = true

      expect { exporter.call }.to raise_error(EvaluationResultsExporter::ExportError, "Serviço de exportação indisponível")
    end
  end

  describe "#filename" do
    it "parameterizes the evaluation title" do
      expect(exporter.filename).to eq("avaliacao-de-sistemas-resultados.csv")
    end
  end
end

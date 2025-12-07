require "rails_helper"

RSpec.describe ReportGenerator do
  describe "#summary" do
    it "returns metadata and metrics for each evaluation" do
      avaliacao = create(:avaliacao, title: "Avaliação Admin")
      questao = create(:questao, avaliacao:, prompt: "Clareza")
      dicente_a = create(:dicente)
      dicente_b = create(:dicente)
      create(:matricula, dicente: dicente_a, turma: avaliacao.turma)
      create(:matricula, dicente: dicente_b, turma: avaliacao.turma)

      resposta = create(:resposta, avaliacao:, dicente: dicente_a, score: 8.5)
      create(:resposta_item, resposta:, questao:, valor: 5)

      generator = described_class.new(Avaliacao.where(id: avaliacao.id))
      summary = generator.summary

      expect(summary.size).to eq(1)
      expect(summary.first).to include(
        avaliacao_id: avaliacao.id,
        title: "Avaliação Admin",
        docente: avaliacao.docente.nome,
        semester: avaliacao.turma.semester,
        total_responses: 1,
        average_score: 8.5,
        completion_rate: 50
      )
    end

    it "respects a custom enumerable scope" do
      avaliacao = create(:avaliacao)
      generator = described_class.new([ avaliacao ])

      expect(generator.summary.first[:avaliacao_id]).to eq(avaliacao.id)
    end
  end

  describe "#totals" do
    it "aggregates totals across the summary" do
      avaliacao_a = create(:avaliacao)
      avaliacao_b = create(:avaliacao)
      questao_a = create(:questao, avaliacao: avaliacao_a)

      dicente_a = create(:dicente)
      dicente_b = create(:dicente)
      create(:matricula, dicente: dicente_a, turma: avaliacao_a.turma)
      create(:matricula, dicente: dicente_b, turma: avaliacao_a.turma)
      create(:matricula, dicente: create(:dicente), turma: avaliacao_b.turma)

      resposta = create(:resposta, avaliacao: avaliacao_a, dicente: dicente_a, score: 9.0)
      create(:resposta_item, resposta:, questao: questao_a, valor: 4)

      totals = described_class.new(Avaliacao.where(id: [ avaliacao_a.id, avaliacao_b.id ])).totals

      expect(totals[:total_forms]).to eq(2)
      expect(totals[:total_responses]).to eq(1)
      expect(totals[:average_completion_rate]).to eq(25)
    end
  end
end

require "rails_helper"

RSpec.describe EvaluationResultAggregator do
  describe "#summary" do
    let(:avaliacao) { create(:avaliacao) }
    let!(:questao_conteudo) { create(:questao, avaliacao:, prompt: "Conteúdo", position: 1) }
    let!(:questao_metodo) { create(:questao, avaliacao:, prompt: "Metodologia", position: 2) }
    let!(:matriculas) { create_list(:matricula, 3, turma: avaliacao.turma) }
    let(:aggregator) { described_class.new(avaliacao) }

    before do
      dicente_a, dicente_b = matriculas.first(2).map(&:dicente)

      resposta_a = create(:resposta, avaliacao:, dicente: dicente_a, score: 8.0)
      create(:resposta_item, resposta: resposta_a, questao: questao_conteudo, valor: 5)
      create(:resposta_item, resposta: resposta_a, questao: questao_metodo, valor: 4)

      resposta_b = create(:resposta, avaliacao:, dicente: dicente_b, score: 6.0)
      create(:resposta_item, resposta: resposta_b, questao: questao_conteudo, valor: 4)
      create(:resposta_item, resposta: resposta_b, questao: questao_metodo, valor: 5)
    end

    it "returns aggregate metrics for the evaluation" do
      summary = aggregator.summary

      expect(summary[:total_responses]).to eq(2)
      expect(summary[:completion_rate]).to eq(67)
      expect(summary[:average_score]).to eq(7.0)
    end

    it "builds distribution stats for each question" do
      stats = aggregator.summary[:question_stats]

      conteudo_stats = stats.find { |data| data[:prompt] == "Conteúdo" }
      metodo_stats = stats.find { |data| data[:prompt] == "Metodologia" }

      expect(conteudo_stats[:total]).to eq(2)
      expect(conteudo_stats[:distribution]).to include("5" => 1, "4" => 1)

      expect(metodo_stats[:total]).to eq(2)
      expect(metodo_stats[:distribution].values.sum).to eq(2)
    end
  end
end

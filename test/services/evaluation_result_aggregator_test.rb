require "test_helper"

class EvaluationResultAggregatorTest < ActiveSupport::TestCase
  test "summary returns zeroed stats when there are no responses" do
    avaliacao = create_avaliacao
    create_questao(avaliacao)

    summary = EvaluationResultAggregator.new(avaliacao).summary

    assert_equal 0, summary[:total_responses]
    assert_equal 0, summary[:completion_rate]
    assert_equal 0.0, summary[:average_score]
    assert_equal 1, summary[:question_stats].size
  end

  test "summary aggregates responses distribution" do
    avaliacao = create_avaliacao
    questao = create_questao(avaliacao)
    dicente = create_dicente
    resposta = Resposta.create!(avaliacao:, dicente:, status: :submitted, submitted_at: Time.zone.now, score: 4)
    RespostaItem.create!(questao:, resposta:, valor: "4")

    summary = EvaluationResultAggregator.new(avaliacao).summary

    assert_equal 1, summary[:total_responses]
    assert_equal 4.0, summary[:average_score]
    assert_equal({ "4" => 1 }, summary[:question_stats].first[:distribution])
  end
end

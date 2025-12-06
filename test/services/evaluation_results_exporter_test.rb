require "test_helper"

class EvaluationResultsExporterTest < ActiveSupport::TestCase
  test "call raises when there are no responses" do
    avaliacao = create_avaliacao
    create_questao(avaliacao)

    exporter = EvaluationResultsExporter.new(avaliacao)

    assert_raises(EvaluationResultsExporter::ExportError) { exporter.call }
  end

  test "call returns csv when responses exist" do
    avaliacao = create_avaliacao(title: "Avaliação Final")
    questao = create_questao(avaliacao)
    dicente = create_dicente
    resposta = Resposta.create!(avaliacao:, dicente:, status: :submitted, submitted_at: Time.zone.now, score: 5)
    RespostaItem.create!(questao:, resposta:, valor: "5")

    exporter = EvaluationResultsExporter.new(avaliacao)
    csv_content = exporter.call

    assert_includes csv_content, "Questão,Aluno,Resposta,Enviado em"
    assert_includes csv_content, "#{questao.prompt},#{dicente.nome},5"
    assert_equal "avaliacao-final-resultados.csv", exporter.filename
  end
end

require "test_helper"

class ResultadosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @avaliacao = create_avaliacao(title: "Avaliação Docente")
    create_questao(@avaliacao)
  end

  test "renders index successfully" do
    get resultados_path
    assert_response :success
  end

  test "filters by search query" do
    get resultados_path, params: { q: "Docente" }
    assert_response :success
    assert_select "[data-testid=\"form-card\"]", count: 1
  end

  test "shows details for an evaluation" do
    get resultado_path(@avaliacao)
    assert_response :success
    assert_select "h1", text: @avaliacao.title
  end

  test "redirects when evaluation not found" do
    get resultado_path(-999)
    assert_redirected_to resultados_path
    follow_redirect!
    assert_match "não foi encontrado", response.body
  end

  test "exports csv when responses exist" do
    dicente = create_dicente
    resposta = Resposta.create!(avaliacao: @avaliacao, dicente:, status: :submitted, submitted_at: Time.zone.now, score: 4)
    questao = @avaliacao.questoes.first || create_questao(@avaliacao)
    RespostaItem.create!(questao:, resposta:, valor: "4")

    get export_resultado_path(@avaliacao)
    assert_response :success
    assert_equal "text/csv", @response.media_type
  end

  test "handles export errors" do
    get export_resultado_path(@avaliacao)
    assert_redirected_to resultado_path(@avaliacao)
    follow_redirect!
    assert_match "Ainda não há respostas", response.body
  end
end

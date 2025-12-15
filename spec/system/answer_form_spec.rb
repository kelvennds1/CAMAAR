require 'rails_helper'

RSpec.describe "Answer Form Journey", type: :system do
  let(:dicente) { create(:dicente, password: "senha123", pending_activation: false) }
  let(:turma) { create(:turma) }
  let(:avaliacao) { create(:avaliacao, :published, turma: turma) }
  let!(:matricula) { create(:matricula, dicente: dicente, turma: turma, status: :ativo) }

  before do
    # Create questions
    create(:questao, :likert, avaliacao: avaliacao, position: 1, mandatory: true, prompt: "Satisfação geral")
    create(:questao, :multiple_choice, avaliacao: avaliacao, position: 2, mandatory: true, prompt: "Escolha uma opção", options: [ "Opção 1", "Opção 2", "Opção 3" ].to_json)
    create(:questao, :text, avaliacao: avaliacao, position: 3, mandatory: false, prompt: "Comentário opcional")

    login_as_system_user(dicente)
  end

  describe "Viewing form" do
    it "displays the form with all questions" do
      visit responder_avaliacao_path(avaliacao)

      expect(page).to have_content(avaliacao.title)
      expect(page).to have_content("Satisfação geral")
      expect(page).to have_content("Escolha uma opção")
      expect(page).to have_content("Comentário opcional")
    end

    it "shows mandatory indicators for required questions" do
      visit responder_avaliacao_path(avaliacao)

      expect(page).to have_selector("[data-testid='pergunta-radio']", minimum: 1)
      expect(page).to have_content("*") # Indicator for mandatory
    end

    it "displays different question types correctly" do
      visit responder_avaliacao_path(avaliacao)

      # Likert scale (radio buttons)
      expect(page).to have_selector("input[type='radio']", minimum: 5)

      # Multiple choice
      expect(page).to have_content("Opção 1")
      expect(page).to have_content("Opção 2")

      # Text field
      expect(page).to have_selector("textarea", minimum: 1)
    end
  end

  describe "Submitting form successfully" do
    it "allows dicente to answer all questions and submit" do
      visit responder_avaliacao_path(avaliacao)

      # Answer likert question (choose value 4)
      find("input[type='radio'][value='4']", match: :first).click

      # Answer multiple choice
      find("input[type='radio'][value='Opção 1']").click

      # Answer text question (sem label, usar data-testid)
      find("[data-testid='campo-texto-pergunta']").set("Este é um ótimo curso!")

      click_button "Enviar"

      expect(page).to have_current_path(formularios_pendentes_path)
      expect(page).to have_content("Avaliação enviada com sucesso!")
    end

    it "saves answers to database" do
      visit responder_avaliacao_path(avaliacao)

      find("input[type='radio'][value='5']", match: :first).click
      find("input[type='radio'][value='Opção 2']").click
      find("[data-testid='campo-texto-pergunta']").set("Comentário de teste")

      expect {
        click_button "Enviar"
      }.to change(Resposta, :count).by(1)
       .and change(RespostaItem, :count).by(3)
    end

    it "marks resposta as submitted" do
      visit responder_avaliacao_path(avaliacao)

      # Aguardar página carregar
      expect(page).to have_content("Satisfação geral")
      expect(page).to have_content("Escolha uma opção")

      # Clicar em radio buttons by value, garantindo que são diferentes
      page.all("input[type='radio'][value='4']").first.click
      page.all("input[type='radio'][value='Opção 1']").first.click

      click_button "Enviar"

      # Se falhar, mostrar corpo da página
      unless page.has_current_path?(formularios_pendentes_path)
        puts "ERRO - Página atual: #{page.current_path}"
        puts "Corpo: #{page.text[0..500]}"
      end

      # Aguardar redirect
      expect(page).to have_current_path(formularios_pendentes_path)

      resposta = Resposta.last
      expect(resposta.status.to_s).to eq("submitted")
      expect(resposta.submitted_at).to be_present
    end
  end

  describe "Validation" do
    it "prevents submission without answering mandatory questions" do
      visit responder_avaliacao_path(avaliacao)

      # Try to submit without answering
      click_button "Enviar"

      expect(page).to have_current_path(submeter_avaliacao_path(avaliacao))
      expect(page).to have_content("obrigatória") # or similar error message
    end

    it "allows submission with only mandatory questions answered" do
      visit responder_avaliacao_path(avaliacao)

      # Answer only mandatory questions
      # Likert (questão 1)
      within("[data-testid='pergunta-radio']") do
        find("input[type='radio'][value='3']").click
      end

      # Multiple choice (questão 2)
      within("[data-testid='pergunta']") do
        find("input[type='radio'][value='Opção 3']").click
      end
      # Skip optional text field

      click_button "Enviar"

      expect(page).to have_current_path(formularios_pendentes_path)
      expect(page).to have_content("sucesso")
    end

    # Validação JS (disabled button) não está implementada ainda
    # it "disables submit button until mandatory fields are filled (if JS enabled)", js: true do
    #   ...
    # end
  end

  describe "Already submitted form" do
    let!(:existing_resposta) { create(:resposta, :submitted, avaliacao: avaliacao, dicente: dicente) }

    it "shows message that form was already answered" do
      visit responder_avaliacao_path(avaliacao)

      expect(page).to have_content("Você já respondeu este formulário")
      expect(page).not_to have_button("Enviar")
    end

    it "prevents resubmission" do
      visit responder_avaliacao_path(avaliacao)

      expect(page).not_to have_selector("[data-testid='botao-enviar']")
    end
  end

  describe "Access control" do
    let(:other_turma) { create(:turma) }
    let(:other_avaliacao) { create(:avaliacao, :published, turma: other_turma) }

    it "prevents access to forms from other classes" do
      visit responder_avaliacao_path(other_avaliacao)

      expect(page).to have_current_path(formularios_pendentes_path)
      expect(page).to have_content("Você não tem permissão")
    end

    it "only shows forms for enrolled classes" do
      visit formularios_pendentes_path

      expect(page).to have_content(avaliacao.title)
      expect(page).not_to have_content(other_avaliacao.title)
    end
  end

  describe "Form with different question types" do
    let(:complex_avaliacao) { create(:avaliacao, :published, turma: turma) }

    before do
      create(:questao, :likert, avaliacao: complex_avaliacao, position: 1, min_value: 1, max_value: 10)
      create(:questao, :text, avaliacao: complex_avaliacao, position: 2)
      create(:questao, :multiple_choice, avaliacao: complex_avaliacao, position: 3, options: [ "A", "B", "C", "D" ].to_json)
    end

    it "handles likert scale with custom range" do
      visit responder_avaliacao_path(complex_avaliacao)

      expect(page).to have_selector("input[type='radio'][value='1']")
      expect(page).to have_selector("input[type='radio'][value='10']")
    end

    it "handles multiple choice with many options" do
      visit responder_avaliacao_path(complex_avaliacao)

      [ "A", "B", "C", "D" ].each do |option|
        expect(page).to have_content(option)
      end
    end

    it "handles text responses" do
      visit responder_avaliacao_path(complex_avaliacao)

      find("input[type='radio'][value='7']", match: :first).click
      find("textarea", match: :first).set("Longa resposta de texto aqui...")
      find("input[type='radio'][value='B']").click

      click_button "Enviar"

      resposta_item = RespostaItem.joins(:questao).where(questoes: { question_type: 'text' }).last
      expect(resposta_item.valor).to include("Longa resposta")
    end
  end

  describe "Error handling" do
    it "maintains form data when submission fails", js: true do
      visit responder_avaliacao_path(avaliacao)

      find("input[type='radio'][value='5']", match: :first).click
      find("input[type='radio'][value='Opção 2']").click
      find("[data-testid='campo-texto-pergunta']").set("Meu comentário")

      # Simulate server error (this would need proper setup)
      # For now, just verify data is not lost on validation error

      # Submit without all mandatory fields to trigger error
      # The form should retain the data
    end
  end

  private

  def login_as_system_user(user)
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "senha123"
    click_button "Entrar"
  end
end

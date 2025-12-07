require "rails_helper"

RSpec.describe "Gerenciamento de Templates", type: :system do
  let(:docente) { create(:docente) }

  before do
    stub_authentication(docente)
  end

  it "permite criar um template com perguntas" do
    visit templates_path

    fill_in "Nome", with: "Template via Sistema"
    fill_in "Descrição", with: "Criado no teste de sistema"
    select docente.nome, from: "Responsável"

    all("input[data-testid='question-prompt']").each_with_index do |field, index|
      field.set("Pergunta #{index + 1}")
    end

    click_button "Criar template"

    expect(page).to have_content("Template criado com sucesso")
    expect(page).to have_selector("[data-testid='template-card']", text: "Template via Sistema")
  end

  it "permite editar um template existente" do
    template = create(:template, name: "Template Original", docente:)

    visit management_templates_path(admin_id: docente.id)

    within first("[data-testid='template-card']") do
      click_link "Editar"
    end

    expect(page).to have_content("Você está editando o template")

    fill_in "Nome", with: "Template Editado"
    click_button "Salvar template"

    expect(page).to have_content("Template atualizado com sucesso")
    expect(page).to have_selector("[data-testid='template-card']", text: "Template Editado")
  end
end

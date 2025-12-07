require "rails_helper"

RSpec.describe "Formulários de Avaliação", type: :system do
  let(:docente) { create(:docente) }
  let(:semester) do
    date = Time.zone.today
    term = date.month <= 6 ? 1 : 2
    format('%<year>d.%<term>d', year: date.year, term: term)
  end
  let!(:turmas) { create_list(:turma, 2, docente:, semester:) }
  let!(:template) { create(:template, docente:) }
  let(:due_date) { 1.month.from_now.to_date }

  before do
    stub_authentication(docente)
  end

  it "cria formulários em lote para turmas do semestre atual" do
    visit avaliacoes_path

    select template.name, from: "Template"
    fill_in "Data limite", with: due_date.strftime("%Y-%m-%d")

    all("input[data-testid='turma-checkbox']").each(&:check)

    click_button "Criar formulários"

    expect(page).to have_content("formulário(s) criado(s)")
    expect(page).to have_selector("[data-testid='evaluation-card']", minimum: 2)
    expect(page).to have_content(template.name)
  end
end

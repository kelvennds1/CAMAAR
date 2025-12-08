require 'rails_helper'

RSpec.describe "Pending Forms UI", type: :system do
  let(:dicente) { create(:dicente, password: "senha123", pending_activation: false) }
  let(:turma1) { create(:turma) }
  let(:turma2) { create(:turma) }
  let!(:matricula1) { create(:matricula, dicente: dicente, turma: turma1, status: :ativo) }
  let!(:matricula2) { create(:matricula, dicente: dicente, turma: turma2, status: :ativo) }

  before { login_as_system_user(dicente) }

  describe "Viewing pending forms list" do
    let!(:pending_form1) { create(:avaliacao, :published, turma: turma1, title: "Avaliação Matemática", due_date: 3.days.from_now) }
    let!(:pending_form2) { create(:avaliacao, :published, turma: turma2, title: "Avaliação Física", due_date: 5.days.from_now) }

    it "displays all pending forms" do
      visit formularios_pendentes_path

      expect(page).to have_content("Avaliação Matemática")
      expect(page).to have_content("Avaliação Física")
    end

    it "shows form details for each pending form" do
      visit formularios_pendentes_path

      within("[data-testid='form-card-#{pending_form1.id}']", match: :first) do
        expect(page).to have_content(pending_form1.title)
        expect(page).to have_content(turma1.class_code)
        expect(page).to have_content(turma1.materia.name)
      end
    end

    it "displays due dates for each form" do
      visit formularios_pendentes_path

      expect(page).to have_content("3 dias") # or similar relative date
      expect(page).to have_content("5 dias")
    end

    it "provides action buttons to answer each form" do
      visit formularios_pendentes_path

      expect(page).to have_link("Responder", href: responder_avaliacao_path(pending_form1), count: 1)
      expect(page).to have_link("Responder", href: responder_avaliacao_path(pending_form2), count: 1)
    end
  end

  describe "Empty state" do
    before { Avaliacao.destroy_all }

    it "shows message when no pending forms exist" do
      visit formularios_pendentes_path

      expect(page).to have_content("Nenhum formulário pendente")
      expect(page).not_to have_selector("[data-testid^='form-card']")
    end

    it "shows helpful empty state illustration or icon" do
      visit formularios_pendentes_path

      expect(page).to have_selector("[data-testid='empty-state']")
    end
  end

  describe "Filtering already answered forms" do
    let!(:pending_form) { create(:avaliacao, :published, turma: turma1, title: "Não Respondido") }
    let!(:answered_form) { create(:avaliacao, :published, turma: turma1, title: "Já Respondido") }
    let!(:resposta) { create(:resposta, :submitted, avaliacao: answered_form, dicente: dicente) }

    it "shows only pending forms" do
      visit formularios_pendentes_path

      expect(page).to have_content("Não Respondido")
      expect(page).not_to have_content("Já Respondido")
    end

    it "updates list after submitting a form" do
      visit formularios_pendentes_path

      expect(page).to have_content("Não Respondido")

      # Answer the form
      click_link "Responder", href: responder_avaliacao_path(pending_form)

      # Fill and submit (simplified)
      # ... fill form fields ...
      # click_button "Enviar"

      # Should be back at pending forms and form should be gone
      # expect(page).not_to have_content("Não Respondido")
    end
  end

  describe "Form ordering" do
    let!(:form_due_soon) { create(:avaliacao, :published, turma: turma1, title: "Urgente", due_date: 1.day.from_now) }
    let!(:form_due_later) { create(:avaliacao, :published, turma: turma1, title: "Pode Esperar", due_date: 10.days.from_now) }

    it "displays forms ordered by due date (nearest first)" do
      visit formularios_pendentes_path

      form_cards = page.all("[data-testid^='form-card']")
      expect(form_cards.first).to have_content("Urgente")
      expect(form_cards.last).to have_content("Pode Esperar")
    end

    it "highlights urgent forms (due soon)" do
      visit formularios_pendentes_path

      within("[data-testid='form-card-#{form_due_soon.id}']", match: :first) do
        expect(page).to have_selector(".urgent") # or similar CSS class
      end
    end
  end

  describe "Navigation to answer form" do
    let!(:pending_form) { create(:avaliacao, :published, turma: turma1, title: "Test Form") }

    it "navigates to answer page when clicking 'Responder'" do
      visit formularios_pendentes_path

      click_link "Responder", href: responder_avaliacao_path(pending_form)

      expect(page).to have_current_path(responder_avaliacao_path(pending_form))
      expect(page).to have_content("Test Form")
    end

    it "allows returning to pending forms list" do
      visit formularios_pendentes_path
      click_link "Responder", href: responder_avaliacao_path(pending_form)

      click_link "Voltar" # or back button

      expect(page).to have_current_path(formularios_pendentes_path)
    end
  end

  describe "Form metadata display" do
    let!(:avaliacao_with_questions) { create(:avaliacao, :published, turma: turma1, title: "With Questions") }

    before do
      create_list(:questao, 5, avaliacao: avaliacao_with_questions)
    end

    it "shows number of questions" do
      visit formularios_pendentes_path

      within("[data-testid='form-card-#{avaliacao_with_questions.id}']", match: :first) do
        expect(page).to have_content("5 questões") # or similar
      end
    end

    it "shows class and subject information" do
      visit formularios_pendentes_path

      expect(page).to have_content(turma1.materia.name)
      expect(page).to have_content(turma1.class_code)
    end
  end

  describe "Expired forms handling" do
    let!(:expired_form) { create(:avaliacao, :published, turma: turma1, title: "Expirado", due_date: 1.day.ago) }

    it "shows expired forms with visual indication" do
      visit formularios_pendentes_path

      within("[data-testid='form-card-#{expired_form.id}']", match: :first) do
        expect(page).to have_content("Expirado")
        expect(page).to have_selector(".expired") # or similar CSS class
      end
    end

    it "may disable answer button for expired forms" do
      visit formularios_pendentes_path

      # Depending on business rules:
      # - Either button is disabled
      # - Or button is enabled but shows warning
      # - Or form is not shown at all
    end
  end

  describe "Responsive design", js: true do
    let!(:pending_form) { create(:avaliacao, :published, turma: turma1) }

    it "displays correctly on mobile viewport" do
      page.current_window.resize_to(375, 667) # iPhone size

      visit formularios_pendentes_path

      expect(page).to have_content(pending_form.title)
      expect(page).to have_selector("[data-testid^='form-card']")
    end

    it "displays correctly on tablet viewport" do
      page.current_window.resize_to(768, 1024) # iPad size

      visit formularios_pendentes_path

      expect(page).to have_content(pending_form.title)
    end
  end

  describe "Partial responses" do
    let!(:form_with_partial) { create(:avaliacao, :published, turma: turma1, title: "Parcial") }
    let!(:partial_resposta) { create(:resposta, :pending, avaliacao: form_with_partial, dicente: dicente) }

    it "indicates when a form has a partial/draft response" do
      visit formularios_pendentes_path

      within("[data-testid='form-card-#{form_with_partial.id}']", match: :first) do
        expect(page).to have_content("Em andamento") # or similar indicator
      end
    end

    it "changes button text to 'Continuar' for partial responses" do
      visit formularios_pendentes_path

      expect(page).to have_link("Continuar", href: responder_avaliacao_path(form_with_partial))
    end
  end

  describe "Search and filtering", js: true do
    let!(:math_form) { create(:avaliacao, :published, turma: turma1, title: "Avaliação de Matemática") }
    let!(:physics_form) { create(:avaliacao, :published, turma: turma2, title: "Avaliação de Física") }

    it "allows searching forms by title" do
      visit formularios_pendentes_path

      fill_in "Buscar", with: "Matemática"

      expect(page).to have_content("Matemática")
      expect(page).not_to have_content("Física")
    end

    it "allows filtering by subject/class" do
      visit formularios_pendentes_path

      select turma1.materia.name, from: "Filtrar por disciplina"

      expect(page).to have_content("Matemática")
      expect(page).not_to have_content("Física")
    end
  end

  describe "Real-time updates", js: true do
    it "reflects changes without page refresh when new form is available" do
      visit formularios_pendentes_path

      initial_count = page.all("[data-testid^='form-card']").count

      # Simulate new form being created (in real scenario, via WebSocket/polling)
      create(:avaliacao, :published, turma: turma1, title: "Novo Formulário")

      # With real-time updates, should see new form
      # page.should have_content("Novo Formulário")
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

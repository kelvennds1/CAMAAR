require 'rails_helper'

RSpec.describe "Authentication Flow", type: :system do
  let(:dicente) { create(:dicente, password: "senha123", pending_activation: false) }
  let(:docente) { create(:docente, password: "senha123", pending_activation: false) }

  describe "Login journey" do
    context "with valid credentials" do
      it "allows dicente to login and access their dashboard" do
        visit login_path

        fill_in "email", with: dicente.email
        fill_in "password", with: "senha123"
        click_button "Entrar"

        expect(page).to have_current_path(avaliacoes_path)
        expect(page).to have_content("Formulários") # ou similar
      end

      it "allows docente to login and access templates" do
        visit login_path

        fill_in "email", with: docente.email
        fill_in "password", with: "senha123"
        click_button "Entrar"

        expect(page).to have_current_path(templates_path)
        expect(page).to have_content("Template") # ou similar
      end

      it "maintains session across page navigation" do
        visit login_path

        fill_in "email", with: dicente.email
        fill_in "password", with: "senha123"
        click_button "Entrar"

        # Navigate to another page
        visit formularios_pendentes_path

        # Should still be logged in
        expect(page).not_to have_current_path(login_path)
        expect(page).not_to have_content("Please log in")
      end
    end

    context "with invalid credentials" do
      it "shows error message for wrong password" do
        visit login_path

        fill_in "email", with: dicente.email
        fill_in "password", with: "wrongpassword"
        click_button "Entrar"

        expect(page).to have_current_path(login_path)
        expect(page).to have_content("Invalid email or password")
      end

      it "shows error message for non-existent email" do
        visit login_path

        fill_in "email", with: "naoexiste@example.com"
        fill_in "password", with: "senha123"
        click_button "Entrar"

        expect(page).to have_current_path(login_path)
        expect(page).to have_content("Invalid email or password")
      end

      it "does not grant access to protected pages" do
        visit login_path

        fill_in "email", with: dicente.email
        fill_in "password", with: "wrongpassword"
        click_button "Entrar"

        visit formularios_pendentes_path
        expect(page).to have_current_path(login_path)
      end
    end

    context "with pending activation" do
      let(:pending_user) { create(:dicente, password: "senha123", pending_activation: true) }

      it "prevents login and shows activation message" do
        visit login_path

        fill_in "email", with: pending_user.email
        fill_in "password", with: "senha123"
        click_button "Entrar"

        expect(page).to have_current_path(login_path)
        expect(page).to have_content("activate your account")
      end
    end
  end

  describe "Logout journey" do
    before do
      login_as_system_user(dicente)
      visit avaliacoes_path
    end

    it "logs out and redirects to login page" do
      click_link "Sair" # ou o texto do botão de logout

      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Logged out successfully")
    end

    it "clears session and prevents access to protected pages" do
      click_link "Sair"

      visit formularios_pendentes_path
      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Please log in")
    end
  end

  describe "Password setup journey" do
    let(:user) { create(:dicente, pending_activation: true, password_reset_token: "validtoken", password_reset_sent_at: 1.hour.ago) }

    it "allows user to set password and activate account" do
      visit password_setup_path(token: "validtoken")

      fill_in "password", with: "newpassword123"
      fill_in "password_confirmation", with: "newpassword123"
      click_button "Definir Senha" # ou texto do botão

      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Password") # success message

      # Verify user can now login
      fill_in "email", with: user.email
      fill_in "password", with: "newpassword123"
      click_button "Entrar"

      expect(page).to have_current_path(avaliacoes_path)
    end

    it "shows error for mismatched passwords" do
      visit password_setup_path(token: "validtoken")

      fill_in "password", with: "newpassword123"
      fill_in "password_confirmation", with: "differentpassword"
      click_button "Definir Senha"

      expect(page).to have_content("password")
      expect(page).to have_current_path(password_setup_path)
    end
  end

  describe "Password reset journey" do
    let(:user) { create(:dicente, password: "oldpassword", pending_activation: false) }

    it "allows user to request password reset" do
      visit request_new_password_path

      fill_in "email", with: user.email
      click_button "Enviar" # ou texto do botão

      expect(page).to have_current_path(login_path)
      expect(page).to have_content("enviado") # ou similar

      user.reload
      expect(user.password_reset_token).to be_present
    end

    it "shows generic message for non-existent email (security)" do
      visit request_new_password_path

      fill_in "email", with: "naoexiste@example.com"
      click_button "Enviar"

      expect(page).to have_current_path(login_path)
      # Should show generic message to prevent email enumeration
      expect(page).to have_content("enviado")
    end
  end

  describe "Protected routes" do
    it "redirects to login when accessing protected pages without authentication" do
      visit avaliacoes_path
      expect(page).to have_current_path(login_path)

      visit templates_path
      expect(page).to have_current_path(login_path)

      visit formularios_pendentes_path
      expect(page).to have_current_path(login_path)
    end

    it "allows access to login page without authentication" do
      visit login_path
      expect(page).to have_current_path(login_path)
      expect(page).to have_field("email")
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

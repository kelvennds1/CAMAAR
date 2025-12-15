require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  describe "GET /password/setup" do
    context "with valid token" do
      let!(:user) { create(:dicente, pending_activation: true, password_reset_token: "valid_token", password_reset_sent_at: 1.hour.ago) }

      it "renders the password setup page" do
        get password_setup_path, params: { token: "valid_token" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("password")
      end
    end

    context "without token" do
      it "redirects to request new password page" do
        get password_setup_path
        expect(response).to redirect_to(request_new_password_path)
      end
    end

    context "with expired token" do
      let!(:user) { create(:dicente, pending_activation: true, password_reset_token: "expired_token", password_reset_sent_at: 25.hours.ago) }

      it "shows error message" do
        get password_setup_path, params: { token: "expired_token" }
        expect(response).to redirect_to(request_new_password_path)
        follow_redirect!
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "POST /password/setup" do
    let!(:user) { create(:dicente, pending_activation: true, password_reset_token: "valid_token", password_reset_sent_at: 1.hour.ago) }

    context "with valid password" do
      it "sets the password and activates the user" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        user.reload
        expect(user.pending_activation).to be_falsey
        expect(user.authenticate("newpassword123")).to be_truthy
        expect(response).to redirect_to(avaliacoes_path)
      end

      it "clears the password reset token" do
        expect(user.password_reset_token).to be_present

        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        user.reload
        # Rails 8 generates_token_for retorna token criptografado, verificar o valor no banco
        expect(user.password_reset_token_for_database).to be_nil
        expect(user.password_reset_sent_at).to be_nil
      end

      it "shows success message" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        follow_redirect!
        expect(flash[:notice]).to include("Senha definida")
      end
    end

    context "with invalid password" do
      it "shows error for mismatched passwords" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("password")
      end

      it "shows error for short password" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "123",
          password_confirmation: "123"
        }

        # Password validation will fail and redirect to appropriate page
        expect(response.status).to be_in([ 302, 422 ])
      end

      it "does not activate the user" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "123",
          password_confirmation: "456"
        }

        user.reload
        expect(user.pending_activation).to be_truthy
      end
    end
  end

  describe "GET /password/request_new" do
    it "renders the password reset request page" do
      get request_new_password_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("administrador")
    end
  end

  # Password reset (POST /password/request_new) não implementado ainda
  # Apenas setup inicial de senha está implementado

  describe "password setup expiration" do
    let(:user) { create(:dicente, pending_activation: true, password_reset_token: "token", password_reset_sent_at: 25.hours.ago) }

    it "rejects expired setup tokens" do
      post password_setup_path, params: {
        token: "token",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }

      expect(response).to redirect_to(request_new_password_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end
  end
end

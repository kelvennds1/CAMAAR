require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:dicente) { create(:dicente, password: "senha123", pending_activation: false) }
  let(:docente) { create(:docente, password: "senha123", pending_activation: false) }

  describe "GET /login" do
    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("email")
      expect(response.body).to include("password")
    end

    it "redirects to appropriate page if already logged in" do
      login_as(dicente)
      get login_path
      expect(response).to redirect_to(avaliacoes_path)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "logs in a dicente and redirects to avaliacoes" do
        post login_path, params: { email: dicente.email, password: "senha123" }
        expect(response).to redirect_to(avaliacoes_path)
        follow_redirect!
        expect(response.body).to_not include("Invalid email or password")
      end

      it "logs in a docente and redirects to templates" do
        post login_path, params: { email: docente.email, password: "senha123" }
        expect(response).to redirect_to(templates_path)
        follow_redirect!
        expect(response.body).to_not include("Invalid email or password")
      end

      it "sets the user_id in session" do
        post login_path, params: { email: dicente.email, password: "senha123" }
        expect(session[:user_id]).to eq(dicente.id)
      end
    end

    context "with invalid credentials" do
      it "renders login page with error for wrong password" do
        post login_path, params: { email: dicente.email, password: "wrong_password" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email or password")
      end

      it "renders login page with error for non-existent email" do
        post login_path, params: { email: "naoexiste@example.com", password: "senha123" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email or password")
      end

      it "does not set user_id in session" do
        post login_path, params: { email: dicente.email, password: "wrong_password" }
        expect(session[:user_id]).to be_nil
      end
    end

    context "with pending activation" do
      let(:pending_user) { create(:dicente, password: "senha123", pending_activation: true) }

      it "does not allow login and shows activation message" do
        post login_path, params: { email: pending_user.email, password: "senha123" }
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("activate your account")
      end
    end
  end

  describe "DELETE /logout" do
    before { login_as(dicente) }

    it "logs out the user" do
      delete logout_path
      expect(session[:user_id]).to be_nil
    end

    it "redirects to login page" do
      delete logout_path
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Logged out successfully")
    end
  end

  describe "session persistence" do
    it "maintains session across requests" do
      post login_path, params: { email: dicente.email, password: "senha123" }
      expect(session[:user_id]).to eq(dicente.id)

      get avaliacoes_path
      expect(response).to have_http_status(:success)
      expect(session[:user_id]).to eq(dicente.id)
    end

    it "requires login for protected pages" do
      get avaliacoes_path
      expect(response).to redirect_to(login_path)
    end
  end
end

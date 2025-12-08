require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  describe "GET /password/setup" do
    context "with valid token" do
      let(:user) { create(:dicente, pending_activation: true, password_reset_token: "valid_token", password_reset_sent_at: 1.hour.ago) }

      it "renders the password setup page" do
        get password_setup_path, params: { token: "valid_token" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("password")
      end
    end

    context "without token" do
      it "redirects to login" do
        get password_setup_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "with expired token" do
      let(:user) { create(:dicente, pending_activation: true, password_reset_token: "expired_token", password_reset_sent_at: 3.hours.ago) }

      it "shows error message" do
        get password_setup_path, params: { token: "expired_token" }
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "POST /password/setup" do
    let(:user) { create(:dicente, pending_activation: true, password_reset_token: "valid_token", password_reset_sent_at: 1.hour.ago) }

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
        expect(response).to redirect_to(login_path)
      end

      it "clears the password reset token" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        user.reload
        expect(user.password_reset_token).to be_nil
      end

      it "shows success message" do
        post password_setup_path, params: {
          token: "valid_token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }

        follow_redirect!
        expect(flash[:notice]).to include("Password")
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

        expect(response).to have_http_status(:unprocessable_entity)
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
      expect(response.body).to include("email")
    end
  end

  describe "POST /password/request_new" do
    let(:user) { create(:dicente, pending_activation: false) }

    context "with valid email" do
      it "generates a password reset token" do
        expect {
          post request_new_password_path, params: { email: user.email }
        }.to change { user.reload.password_reset_token }.from(nil)
      end

      it "sets password_reset_sent_at" do
        post request_new_password_path, params: { email: user.email }
        user.reload
        expect(user.password_reset_sent_at).to be_present
        expect(user.password_reset_sent_at).to be_within(1.minute).of(Time.current)
      end

      it "redirects with success message" do
        post request_new_password_path, params: { email: user.email }
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(flash[:notice]).to be_present
      end
    end

    context "with non-existent email" do
      it "shows generic message for security" do
        post request_new_password_path, params: { email: "naoexiste@example.com" }
        expect(response).to redirect_to(login_path)
        follow_redirect!
        # Should show generic message to prevent email enumeration
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "password reset expiration" do
    let(:user) { create(:dicente, password_reset_token: "token", password_reset_sent_at: 3.hours.ago) }

    it "rejects expired reset tokens" do
      post password_setup_path, params: {
        token: "token",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }

      expect(response).to redirect_to(login_path)
      user.reload
      expect(user.pending_activation).to be_falsey # Assuming it wasn't pending
    end
  end
end

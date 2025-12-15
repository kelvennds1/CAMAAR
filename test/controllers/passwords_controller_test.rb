require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_token = SecureRandom.urlsafe_base64(32)
    @user = Dicente.create!(
      nome: "Test User",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      matricula: "20231234567",
      curso: "Computer Science",
      password_digest: nil,
      pending_activation: true,
      password_reset_token: @valid_token,
      password_reset_sent_at: Time.current
    )
  end

  test "should get new with valid token" do
    get password_setup_url(token: @valid_token)
    assert_response :success
  end

  test "should redirect with invalid token" do
    get password_setup_url(token: "invalid-token")
    assert_redirected_to request_new_password_path
    assert_equal "Link de configuração de senha é inválido ou expirado", flash[:alert]
  end

  test "should redirect with expired token" do
    @user.update(password_reset_sent_at: 25.hours.ago)
    get password_setup_url(token: @valid_token)
    assert_redirected_to request_new_password_path
  end

  test "should set password with valid data" do
    post password_setup_url, params: {
      token: @valid_token,
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }

    assert_redirected_to avaliacoes_path
    @user.reload
    assert_not @user.pending_activation
    assert_not_nil @user.password_digest
    assert @user.authenticate("newpassword123")
  end

  test "should not set password with mismatched confirmation" do
    post password_setup_url, params: {
      token: @valid_token,
      password: "newpassword123",
      password_confirmation: "different123"
    }

    assert_response :unprocessable_entity
    assert_select "div.alert-error", text: /confirmação de senha não corresponde/i
  end

  test "should not set password with invalid token" do
    post password_setup_url, params: {
      token: "invalid",
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }

    assert_redirected_to request_new_password_path
  end

  test "should get request_new page" do
    get request_new_password_url
    assert_response :success
  end
end

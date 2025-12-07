require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = Dicente.create!(
      nome: "Test User",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      matricula: "20231234567",
      curso: "Computer Science",
      password: "password123"
    )
  end

  test "should get new" do
    get login_url
    assert_response :success
  end

  test "should login with valid credentials" do
    post login_url, params: { email: @user.email, password: "password123" }
    assert_redirected_to avaliacoes_path
    assert_equal @user.id, session[:user_id]
  end

  test "should not login with invalid email" do
    post login_url, params: { email: "wrong@example.com", password: "password123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "div.alert-error", text: /Invalid email or password/
  end

  test "should not login with invalid password" do
    post login_url, params: { email: @user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "should redirect docente to templates path" do
    docente = Docente.create!(
      nome: "Test Professor",
      identifier: SecureRandom.uuid,
      email: "prof@example.com",
      departamento: "Computer Science",
      titulacao: "Doutor",
      password: "password123"
    )

    post login_url, params: { email: docente.email, password: "password123" }
    assert_redirected_to templates_path
  end

  test "should logout" do
    # Login first
    post login_url, params: { email: @user.email, password: "password123" }
    assert_equal @user.id, session[:user_id]

    # Then logout
    delete logout_url
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end
end

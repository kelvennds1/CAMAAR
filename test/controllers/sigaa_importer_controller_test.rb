require "test_helper"

class SigaaImportsControllerTest < ActionDispatch::IntegrationTest
  
  def setup
    @admin = Usuario.create!(
      identifier: "admin001",
      nome: "Admin Test",
      email: "admin@test.com",
      type: "Usuario",
      admin: true,
      password: 'password',
      password_confirmation: 'password'
    )
    @classes_file = fixture_file_upload("sigaa/classes.json", "application/json")
  end

  test "should get new when admin" do
    sign_in @admin
    get new_sigaa_import_url
    assert_response :success
  end

  test "should redirect non-admin from new" do
    get new_sigaa_import_url
    assert_redirected_to root_path
    assert_equal "Acesso negado", flash[:alert]
  end

  test "should create import with valid file" do
    sign_in @admin
    
    assert_difference "Materia.count" do
      post sigaa_imports_url, params: { classes_file: @classes_file }
    end
    
    assert_redirected_to sigaa_imports_path
    assert_match /Importação concluída/, flash[:notice]
  end

  test "should show error with no files" do
    sign_in @admin
    
    post sigaa_imports_url, params: {}
    
    assert_response :unprocessable_entity
    assert_match /Selecione ao menos um arquivo/, response.body
  end

  test "should get index when admin" do
    sign_in @admin
    get sigaa_imports_url
    assert_response :success
  end
end
require "test_helper"

class UsuarioTest < ActiveSupport::TestCase
  test "should not save usuario without required fields" do
    usuario = Usuario.new
    assert_not usuario.save
  end

  test "should require valid email format" do
    usuario = Dicente.new(
      nome: "Test",
      identifier: SecureRandom.uuid,
      matricula: "123",
      curso: "CS",
      email: "invalid-email"
    )
    assert_not usuario.save
    assert_includes usuario.errors[:email], "is invalid"
  end

  test "should require unique email" do
    email = "test@example.com"
    Dicente.create!(
      nome: "Test",
      identifier: SecureRandom.uuid,
      matricula: "123",
      curso: "CS",
      email: email,
      password: "password123"
    )

    duplicate = Dicente.new(
      nome: "Test 2",
      identifier: SecureRandom.uuid,
      matricula: "456",
      curso: "CS",
      email: email
    )
    assert_not duplicate.save
  end

  test "should require unique identifier" do
    identifier = SecureRandom.uuid
    Dicente.create!(
      nome: "Test",
      identifier: identifier,
      matricula: "123",
      curso: "CS",
      email: "test1@example.com",
      password: "password123"
    )

    duplicate = Dicente.new(
      nome: "Test 2",
      identifier: identifier,
      matricula: "456",
      curso: "CS",
      email: "test2@example.com"
    )
    assert_not duplicate.save
  end

  test "docente? returns true for Docente" do
    docente = Docente.new
    assert docente.docente?
    assert_not docente.dicente?
  end

  test "dicente? returns true for Dicente" do
    dicente = Dicente.new
    assert dicente.dicente?
    assert_not dicente.docente?
  end
end

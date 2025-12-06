require "test_helper"

class DocenteTest < ActiveSupport::TestCase
  test "should require departamento" do
    docente = Docente.new(
      nome: "Test",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      titulacao: "Doutor"
    )
    assert_not docente.save
    assert_includes docente.errors[:departamento], "can't be blank"
  end

  test "should require titulacao" do
    docente = Docente.new(
      nome: "Test",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      departamento: "Computer Science"
    )
    assert_not docente.save
    assert_includes docente.errors[:titulacao], "can't be blank"
  end

  test "should create valid docente" do
    docente = Docente.new(
      nome: "Test Professor",
      identifier: SecureRandom.uuid,
      email: "professor@example.com",
      departamento: "Computer Science",
      titulacao: "Doutor",
      password: "password123"
    )
    assert docente.save
  end

  test "should have turmas association" do
    assert_respond_to Docente.new, :turmas
  end

  test "should have templates association" do
    assert_respond_to Docente.new, :templates
  end

  test "should have avaliacoes association" do
    assert_respond_to Docente.new, :avaliacoes
  end
end

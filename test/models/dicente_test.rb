require "test_helper"

class DicenteTest < ActiveSupport::TestCase
  test "should require matricula" do
    dicente = Dicente.new(
      nome: "Test",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      curso: "Computer Science"
    )
    assert_not dicente.save
    assert_includes dicente.errors[:matricula], "can't be blank"
  end

  test "should require curso" do
    dicente = Dicente.new(
      nome: "Test",
      identifier: SecureRandom.uuid,
      email: "test@example.com",
      matricula: "20231234567"
    )
    assert_not dicente.save
    assert_includes dicente.errors[:curso], "can't be blank"
  end

  test "should create valid dicente" do
    dicente = Dicente.new(
      nome: "Test Student",
      identifier: SecureRandom.uuid,
      email: "student@example.com",
      matricula: "20231234567",
      curso: "Computer Science",
      password: "password123"
    )
    assert dicente.save
  end

  test "should require unique matricula" do
    matricula = "20231234567"
    Dicente.create!(
      nome: "Test 1",
      identifier: SecureRandom.uuid,
      email: "test1@example.com",
      matricula: matricula,
      curso: "CS",
      password: "password123"
    )

    duplicate = Dicente.new(
      nome: "Test 2",
      identifier: SecureRandom.uuid,
      email: "test2@example.com",
      matricula: matricula,
      curso: "CS"
    )
    assert_not duplicate.save
  end

  test "should have matriculas association" do
    assert_respond_to Dicente.new, :matriculas
  end

  test "should have turmas association" do
    assert_respond_to Dicente.new, :turmas
  end

  test "should have respostas association" do
    assert_respond_to Dicente.new, :respostas
  end
end

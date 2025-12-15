require "test_helper"

class SigaaImporterTest < ActiveSupport::TestCase
  def setup
    @classes_file = file_fixture("sigaa/classes.json")
    @members_file = file_fixture("sigaa/class_members.json")
    @invalid_file = file_fixture("sigaa/invalid.json")
  end

  test "imports materias from classes file" do
    assert_difference "Materia.count", 3 do
      SigaaImporter.call(classes_file: @classes_file)
    end
  end

  test "imports turmas from classes file" do
    assert_difference "Turma.count", 3 do
      SigaaImporter.call(classes_file: @classes_file)
    end
  end

  test "imports docentes and dicentes from members file" do
    # First import classes to create turmas
    SigaaImporter.call(classes_file: @classes_file)

    assert_difference "Docente.count", 1 do
      assert_difference "Dicente.count", 44 do
        SigaaImporter.call(class_members_file: @members_file)
      end
    end
  end

  test "imports matriculas from members file" do
    SigaaImporter.call(classes_file: @classes_file)

    assert_difference "Matricula.count", 44 do
      SigaaImporter.call(class_members_file: @members_file)
    end
  end

  test "returns success result with valid files" do
    result = SigaaImporter.call(classes_file: @classes_file)

    assert result.success?
    assert_empty result.errors
    assert result.total_created > 0
  end

  test "does not duplicate existing records" do
    # Import once
    result1 = SigaaImporter.call(classes_file: @classes_file)
    materias_created = result1.created[:materias]

    # Import again - should skip existing records
    result2 = SigaaImporter.call(classes_file: @classes_file)

    assert result2.success?
    assert_equal 0, result2.created[:materias]
    assert_equal materias_created, result2.skipped[:materias]
  end

  test "handles invalid JSON file" do
    result = SigaaImporter.call(classes_file: @invalid_file)

    assert_not result.success?
    assert_includes result.errors.join, "JSON inválido"
  end

  test "returns error when no file provided" do
    result = SigaaImporter.call(classes_file: nil, class_members_file: nil)

    assert_not result.success?
    assert_includes result.errors.first, "Selecione ao menos um arquivo"
  end

  test "rolls back on error" do
    # Create invalid JSON in memory
    invalid_json = StringIO.new('{"invalid": "json"')

    assert_no_difference [ "Materia.count", "Turma.count" ] do
      SigaaImporter.call(classes_file: invalid_json)
    end
  end

  test "summary message for successful import" do
    result = SigaaImporter.call(classes_file: @classes_file)

    assert_includes result.summary_message, "Importação concluída"
    assert_includes result.summary_message, "novos registros criados"
  end

  test "summary message for failed import" do
    result = SigaaImporter.call(classes_file: @invalid_file)

    assert_includes result.summary_message, "Erros na importação"
  end

  test "imports both files in single call" do
    result = SigaaImporter.call(
      classes_file: @classes_file,
      class_members_file: @members_file
    )

    assert result.success?
    assert result.created[:materias] > 0
    assert result.created[:dicentes] > 0
  end

  # Testes de atualização
  test "updates existing materia when name changes" do
    # Criar matéria inicial
    materia = Materia.create!(code: "CIC0097", name: "BANCOS DE DADOS")

    # Simular JSON com nome atualizado
    updated_json = [ { "code": "CIC0097", "name": "BANCOS DE DADOS AVANÇADOS" } ].to_json
    temp_file = Tempfile.new([ "updated_classes", ".json" ])
    temp_file.write(updated_json)
    temp_file.rewind

    result = SigaaImporter.call(classes_file: temp_file)

    assert result.success?
    assert_equal 0, result.created[:materias]
    assert_equal 1, result.updated[:materias]

    materia.reload
    assert_equal "BANCOS DE DADOS AVANÇADOS", materia.name

    temp_file.close
    temp_file.unlink
  end

  test "updates existing docente when information changes" do
    # Importar dados iniciais
    SigaaImporter.call(classes_file: @classes_file, class_members_file: @members_file)

    docente = Docente.find_by(identifier: "83807519491")
    original_email = docente.email

    # Simular JSON com email atualizado
    updated_json = [ {
      "code": "CIC0097",
      "classCode": "TA",
      "semester": "2021.2",
      "dicente": [],
      "docente": {
        "nome": "MARISTELA TERTO DE HOLANDA",
        "departamento": "DEPTO CIÊNCIAS DA COMPUTAÇÃO",
        "formacao": "DOUTORADO",
        "usuario": "83807519491",
        "email": "novo.email@unb.br",
        "ocupacao": "docente"
      }
    } ].to_json

    temp_file = Tempfile.new([ "updated_members", ".json" ])
    temp_file.write(updated_json)
    temp_file.rewind

    result = SigaaImporter.call(class_members_file: temp_file)

    assert result.success?
    assert result.updated[:docentes] > 0

    docente.reload
    assert_equal "novo.email@unb.br", docente.email
    assert_not_equal original_email, docente.email

    temp_file.close
    temp_file.unlink
  end

  test "updates existing dicente when information changes" do
    # Importar dados iniciais
    SigaaImporter.call(classes_file: @classes_file, class_members_file: @members_file)

    dicente = Dicente.find_by(identifier: "190084006")
    original_email = dicente.email

    # Simular JSON com email atualizado
    updated_json = [ {
      "code": "CIC0097",
      "classCode": "TA",
      "semester": "2021.2",
      "dicente": [ {
        "nome": "Ana Clara Jordao Perna",
        "curso": "CIÊNCIA DA COMPUTAÇÃO/CIC",
        "matricula": "190084006",
        "usuario": "190084006",
        "formacao": "graduando",
        "ocupacao": "dicente",
        "email": "novo.email.dicente@gmail.com"
      } ],
      "docente": {
        "nome": "MARISTELA TERTO DE HOLANDA",
        "departamento": "DEPTO CIÊNCIAS DA COMPUTAÇÃO",
        "formacao": "DOUTORADO",
        "usuario": "83807519491",
        "email": "mholanda@unb.br",
        "ocupacao": "docente"
      }
    } ].to_json

    temp_file = Tempfile.new([ "updated_members", ".json" ])
    temp_file.write(updated_json)
    temp_file.rewind

    result = SigaaImporter.call(class_members_file: temp_file)

    assert result.success?
    assert result.updated[:dicentes] > 0

    dicente.reload
    assert_equal "novo.email.dicente@gmail.com", dicente.email
    assert_not_equal original_email, dicente.email

    temp_file.close
    temp_file.unlink
  end

  test "tracks both created and updated counts" do
    # Primeira importação - deve criar registros
    result1 = SigaaImporter.call(classes_file: @classes_file)

    assert result1.total_created > 0
    assert_equal 0, result1.total_updated

    # Criar JSON com dados modificados
    updated_json = [ { "code": "CIC0097", "name": "BANCOS DE DADOS MODIFICADO" } ].to_json
    temp_file = Tempfile.new([ "updated", ".json" ])
    temp_file.write(updated_json)
    temp_file.rewind

    # Segunda importação - deve atualizar
    result2 = SigaaImporter.call(classes_file: temp_file)

    assert_equal 0, result2.created[:materias]
    assert_equal 1, result2.updated[:materias]
    assert result2.total_updated > 0

    temp_file.close
    temp_file.unlink
  end

  test "skips records that have not changed" do
    # Primeira importação
    result1 = SigaaImporter.call(classes_file: @classes_file)
    created_count = result1.total_created

    # Segunda importação com mesmos dados
    result2 = SigaaImporter.call(classes_file: @classes_file)

    assert_equal 0, result2.total_created
    assert_equal 0, result2.total_updated
    assert result2.total_skipped > 0
  end
end

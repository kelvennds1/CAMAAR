require "rails_helper"
require "stringio"

RSpec.describe SigaaImporter do
  describe ".call" do
    it "returns an error when no files are provided" do
      result = described_class.call

      expect(result).not_to be_success
      expect(result.errors).to include("Selecione ao menos um arquivo JSON para importação")
    end
  end

  describe "#import" do
    let(:classes_payload) do
      [
        {
          "code" => "CIC1000",
          "name" => "Estruturas de Dados",
          "class" => {
            "classCode" => "TA",
            "semester" => "2025.1",
            "time" => "35T12"
          }
        }
      ]
    end

    let(:members_payload) do
      [
        {
          "code" => "CIC1000",
          "classCode" => "TA",
          "semester" => "2025.1",
          "docente" => {
            "usuario" => "prof-001",
            "nome" => "Prof. Teste",
            "email" => "prof.teste@example.com",
            "departamento" => "CIC",
            "formacao" => "Doutor",
            "ocupacao" => "docente"
          },
          "dicente" => [
            {
              "usuario" => "aluno-001",
              "nome" => "Aluno Teste",
              "email" => "aluno.teste@example.com",
              "matricula" => "2023001",
              "curso" => "Ciência da Computação",
              "formacao" => "graduando",
              "ocupacao" => "dicente"
            }
          ]
        }
      ]
    end

    it "imports classes and members, returning a successful summary" do
      expect do
        result = described_class.call(
          classes_file: json_file_for(classes_payload),
          class_members_file: json_file_for(members_payload)
        )

        expect(result).to be_success
        expect(result.summary_message).to include("Importação concluída")
      end.to change(Materia, :count).by(1)
        .and change(Turma, :count).by(1)
        .and change(Dicente, :count).by(1)
        .and change(Matricula, :count).by(1)

      expect(Docente.exists?(email: "prof.teste@example.com")).to be(true)
      expect(Dicente.last).to be_pending_activation
    end

    it "skips records that already exist on subsequent runs" do
      described_class.call(classes_file: json_file_for(classes_payload), class_members_file: json_file_for(members_payload))

      result = described_class.call(
        classes_file: json_file_for(classes_payload),
        class_members_file: json_file_for(members_payload)
      )

      expect(result.total_created).to eq(0)
      expect(result.total_skipped).to be_positive
    end

    it "returns a descriptive error when the JSON payload is invalid" do
      result = described_class.call(classes_file: StringIO.new("{ invalid"), class_members_file: nil)

      expect(result).not_to be_success
      expect(result.errors.join).to include("Arquivo JSON inválido")
    end
  end

  def json_file_for(payload)
    StringIO.new(payload.to_json)
  end
end

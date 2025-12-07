require "rails_helper"

RSpec.describe Template, type: :model do
  let(:docente) { create(:docente) }
  subject(:template) { build(:template, docente:) }

  describe "associations" do
    it { is_expected.to belong_to(:docente) }
    it { is_expected.to have_many(:template_questions).dependent(:destroy) }
    it { is_expected.to have_many(:avaliacoes).dependent(:nullify) }
    it { is_expected.to accept_nested_attributes_for(:template_questions).allow_destroy(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name).with_message("Informe o nome do template") }
    it { is_expected.to validate_presence_of(:docente).with_message("Selecione o responsável pelo template") }
    it "raises an error for invalid statuses" do
      expect { template.status = "invalid" }.to raise_error(ArgumentError)
    end

    it "validates uniqueness of name scoped to docente" do
      create(:template, name: "Template X", docente: template.docente)
      template.name = "Template X"

      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("Já existe um template com esse nome para o docente selecionado")
    end

    it "requires at least one question" do
      template.template_questions.clear

      expect(template).not_to be_valid
      expect(template.errors[:base]).to include("Adicione pelo menos uma questão")
    end
  end

  describe "callbacks" do
    it "normalizes the template name" do
      template.name = "  Template ABC  "
      template.validate

      expect(template.name).to eq("Template ABC")
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(described_class::STATUS).backed_by_column_of_type(:string) }
  end
end

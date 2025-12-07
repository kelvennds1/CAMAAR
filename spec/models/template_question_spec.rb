require "rails_helper"

RSpec.describe TemplateQuestion, type: :model do
  subject(:question) { build(:template_question) }

  describe "associations" do
    it { is_expected.to belong_to(:template).inverse_of(:template_questions) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:prompt) }
    it { is_expected.to validate_presence_of(:question_type) }
    it { is_expected.to validate_inclusion_of(:question_type).in_array(described_class::QUESTION_TYPES.values) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than(0) }
  end

  describe "position handling" do
    it "assigns a sequential position when none is provided" do
      question.position = nil
      question.save!

      expect(question.position).to be > 0
    end
  end

  describe "multiple choice options" do
    it "requires at least two options" do
      question.question_type = described_class::QUESTION_TYPES[:multiple_choice]
      question.options_text = "Opcao unica"

      expect(question).not_to be_valid
      expect(question.errors[:options]).to include("Adicione pelo menos duas opções")
    end

    it "persists normalized options" do
      question.question_type = described_class::QUESTION_TYPES[:multiple_choice]
      question.options_text = "Um\nDois\nDois"

      expect(question).to be_valid
      expect(question.options_array).to eq(%w[Um Dois])
    end
  end

  describe "likert scale" do
    it "enforces a 1-5 numeric range" do
      question.question_type = described_class::QUESTION_TYPES[:likert]
      question.min_value = 2
      question.max_value = 2

      expect(question).not_to be_valid
      expect(question.errors[:base]).to include("A escala numérica deve ser de 1 a 5")
    end
  end

  describe "options_text accessor" do
    it "returns stored options separated by new lines" do
      question.question_type = described_class::QUESTION_TYPES[:multiple_choice]
      question.options_text = "Primeira\nSegunda"
      question.save!

      expect(question.reload.options_text).to eq("Primeira\nSegunda")
    end
  end
end

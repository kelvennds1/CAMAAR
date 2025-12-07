require "rails_helper"

RSpec.describe Questao, type: :model do
  subject(:questao) { build(:questao) }

  describe "associations" do
    it { is_expected.to belong_to(:avaliacao) }
    it { is_expected.to belong_to(:template_question).optional }
    it { is_expected.to have_many(:resposta_items).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:prompt) }
    it { is_expected.to validate_presence_of(:question_type) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:weight) }
    it { is_expected.to validate_inclusion_of(:question_type).in_array(TemplateQuestion::QUESTION_TYPES.values) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than(0) }
  end

  describe "instance methods" do
    it "returns true when the question uses the likert scale" do
      questao.question_type = TemplateQuestion::QUESTION_TYPES[:likert]

      expect(questao).to be_numeric
    end

    it "returns false for other question types" do
      questao.question_type = TemplateQuestion::QUESTION_TYPES[:text]

      expect(questao).not_to be_numeric
    end
  end
end

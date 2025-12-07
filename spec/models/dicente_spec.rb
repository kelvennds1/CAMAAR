require "rails_helper"

RSpec.describe Dicente, type: :model do
  subject(:dicente) { build(:dicente) }

  describe "associations" do
    it { is_expected.to have_many(:matriculas).dependent(:destroy) }
    it { is_expected.to have_many(:turmas).through(:matriculas) }
    it { is_expected.to have_many(:avaliacoes).through(:turmas) }
    it { is_expected.to have_many(:respostas).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:matricula) }
    it { is_expected.to validate_presence_of(:curso) }
  end
end
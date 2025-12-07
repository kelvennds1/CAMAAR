require "rails_helper"

RSpec.describe Docente, type: :model do
  subject(:docente) { build(:docente) }

  describe "associations" do
    it { is_expected.to have_many(:turmas).dependent(:nullify) }
    it { is_expected.to have_many(:templates).dependent(:destroy) }
    it { is_expected.to have_many(:avaliacoes).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:departamento) }
    it { is_expected.to validate_presence_of(:titulacao) }
  end
end

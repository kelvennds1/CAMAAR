require "rails_helper"

RSpec.describe Turma, type: :model do
  subject(:turma) { build(:turma) }

  describe "associations" do
    it { is_expected.to belong_to(:materia) }
    it { is_expected.to belong_to(:docente) }
    it { is_expected.to have_many(:matriculas).dependent(:destroy) }
    it { is_expected.to have_many(:dicentes).through(:matriculas) }
    it { is_expected.to have_many(:avaliacoes).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:class_code) }
    it { is_expected.to validate_presence_of(:semester) }
    it { is_expected.to validate_uniqueness_of(:class_code).scoped_to(%i[materia_id semester]) }
  end
end

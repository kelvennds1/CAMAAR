ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "securerandom"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    def create_docente(attrs = {})
      defaults = {
        nome: "Prof. Teste",
        email: "prof.teste+#{SecureRandom.hex(4)}@example.com",
        identifier: SecureRandom.uuid,
        departamento: "Departamento",
        titulacao: "Mestre",
        password: "password"
      }

      Docente.create!(defaults.merge(attrs))
    end

    def create_materia(attrs = {})
      defaults = {
        code: "MAT-#{SecureRandom.hex(2)}",
        name: "Matéria de Teste"
      }

      Materia.create!(defaults.merge(attrs))
    end

    def create_turma(attrs = {})
      docente = attrs[:docente] || create_docente
      materia = attrs[:materia] || create_materia
      defaults = {
        class_code: "T-#{SecureRandom.hex(2)}",
        semester: "2025.1",
        time_slot: "Seg 10h",
        docente:,
        materia:
      }

      Turma.create!(defaults.merge(attrs))
    end

    def create_avaliacao(attrs = {})
      turma = attrs[:turma] || create_turma
      docente = attrs[:docente] || turma.docente
      defaults = {
        title: "Avaliação #{SecureRandom.hex(2)}",
        due_date: Time.zone.today.end_of_month,
        max_score: 10,
        status: :published,
        turma:,
        docente:
      }

      Avaliacao.create!(defaults.merge(attrs))
    end

    def create_questao(avaliacao, attrs = {})
      defaults = {
        prompt: "Como você avalia?",
        question_type: TemplateQuestion::QUESTION_TYPES[:likert],
        position: (avaliacao.questoes.maximum(:position) || 0) + 1,
        mandatory: true,
        weight: 1,
        min_value: 1,
        max_value: 5
      }

      avaliacao.questoes.create!(defaults.merge(attrs))
    end

    def create_dicente(attrs = {})
      defaults = {
        nome: "Aluno #{SecureRandom.hex(2)}",
        email: "aluno-#{SecureRandom.hex(4)}@example.com",
        identifier: SecureRandom.uuid,
        matricula: "M#{SecureRandom.hex(3)}",
        curso: "Engenharia",
        type: "Dicente",
        password: "password"
      }

      Dicente.create!(defaults.merge(attrs))
    end

    def sign_in(user)
      post login_url, params: { session: { email: user.email, password: "password" } }
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    post "/login", params: { email: user.email, password: "password" }
  end
end

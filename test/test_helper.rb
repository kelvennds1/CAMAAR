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
        titulacao: "Mestre"
      }

      Docente.create!(defaults.merge(attrs))
    end
  end
end

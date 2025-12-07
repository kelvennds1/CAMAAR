require "securerandom"

FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  sequence :identifier do |n|
    "identifier-#{n}"
  end

  sequence :matricula do |n|
    "MAT#{1000 + n}"
  end

  factory :docente, class: "Docente" do
    nome { "Docente #{SecureRandom.hex(2)}" }
    email { generate(:email) }
    identifier { generate(:identifier) }
    departamento { "Departamento de Testes" }
    titulacao { "Mestre" }
    password { "senha123" }
  end

  factory :dicente, class: "Dicente" do
    nome { "Dicente #{SecureRandom.hex(2)}" }
    email { generate(:email) }
    identifier { generate(:identifier) }
    matricula { generate(:matricula) }
    curso { "Engenharia" }
    password { "senha123" }
  end

  factory :materia do
    sequence(:code) { |n| "MAT#{n}" }
    sequence(:name) { |n| "Matéria #{n}" }
  end

  factory :turma do
    association :materia
    association :docente
    sequence(:class_code) { |n| "T-#{n}" }
    semester { "2025.1" }
    time_slot { "Seg 10h" }
  end

  factory :template do
    association :docente
    sequence(:name) { |n| "Template #{n}" }
    description { "Descrição do template" }
    status { Template::STATUS[:draft] }

    after(:build) do |template|
      if template.template_questions.empty?
        template.template_questions << build(:template_question, template: template)
      end
    end
  end

  factory :template_question do
    association :template
    sequence(:prompt) { |n| "Questão #{n}" }
    question_type { TemplateQuestion::QUESTION_TYPES[:likert] }
    sequence(:position) { |n| n + 1 }
    required { true }
    min_value { 1 }
    max_value { 5 }
  end

  factory :avaliacao do
    association :turma
    docente { turma.docente }
    template { association :template, docente: docente }
    sequence(:title) { |n| "Avaliação #{n}" }
    description { "Avaliação gerada a partir do template" }
    due_date { 1.week.from_now }
    max_score { 10 }
    status { :published }
  end

  factory :questao do
    association :avaliacao
    sequence(:prompt) { |n| "Questão #{n}" }
    question_type { TemplateQuestion::QUESTION_TYPES[:likert] }
    sequence(:position) { |n| n + 1 }
    mandatory { true }
    min_value { 1 }
    max_value { 5 }
    weight { 1 }
  end

  factory :resposta do
    association :avaliacao
    association :dicente
    status { :submitted }
    submitted_at { Time.zone.now }
    score { 8.5 }
  end

  factory :resposta_item do
    association :resposta
    association :questao
    valor { 4 }

    after(:build) do |item|
      next unless item.resposta

      item.questao ||= build(:questao, avaliacao: item.resposta.avaliacao)
      item.questao.avaliacao = item.resposta.avaliacao
    end
  end

  factory :matricula do
    association :dicente
    association :turma
    status { :ativo }
  end
end
